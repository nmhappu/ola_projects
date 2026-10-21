// ESP32 DevKit (WROOM-32) BLE version of the Ola S1 X BMS tool from backup.hex.
// No LCD and no physical buttons: the Android app ("BMS Remote") shows the
// actions and the live pack data over Bluetooth Low Energy.
//
// CAN uses the ESP32's built-in controller (TWAI) at 500 kbps, with a 3.3 V
// SN65HVD230 transceiver board, so no MCP2515 and no level shifter:
//   BMS Reset         -> sends 8-byte frame, ID 0x7C1
//   System Reset S1X  -> sends 8-byte frame, ID 0x7C2
//   Fetch data        -> sends 0x7C1, then streams pack voltage / SOC
//   pack voltage: ID 0x1A8, bytes 4-5, little-endian, millivolts
//   SOC:          ID 0x352, byte 0, percent
//
// Wiring (SN65HVD230 board, e.g. "CJMCU-230" / "VP230"):
//   3V3 -> 3V3, GND -> GND, CTX (TX/D) -> GPIO 5, CRX (RX/R) -> GPIO 4,
//   CANH / CANL -> scooter CAN-H / CAN-L. Leave the board's 120 ohm
//   terminator in only if the tool is at the end of the bus.
//
// BLE security: the app must pair with PASSKEY below (Android asks for it once).
// Change it before use. Unpaired phones cannot send commands or read data.
//
// Each board advertises a unique name, "OLA BMS Tool XXXX", where XXXX is the
// last 4 hex digits of its Bluetooth address, so several tools can be told apart.
//
// CAN monitor: on request the board also forwards every CAN frame it sees (and
// the frames it sends itself, flagged TX) to the app, which shows, records and
// exports them for can_tools/analyze_cells.py.
//
// No extra libraries: BLE and the TWAI driver come with the ESP32 core (3.x).

#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLESecurity.h>
#include <BLE2902.h>
#include <esp_mac.h>
#include "driver/twai.h"

// ---- settings ----
const uint32_t PASSKEY   = 246810;      // 6 digits, entered on the phone when pairing
const char *NAME_PREFIX  = "OLA BMS Tool";
const gpio_num_t PIN_CAN_TX = GPIO_NUM_5;   // to transceiver CTX / TXD
const gpio_num_t PIN_CAN_RX = GPIO_NUM_4;   // to transceiver CRX / RXD
const uint32_t NOTIFY_INTERVAL_MS = 250;
const uint32_t DATA_TIMEOUT_MS    = 2000;  // no 0x1A8/0x352 frame for this long -> "No CAN data"
const uint32_t RAW_NOTIFY_MS      = 5;     // at most one CAN monitor packet this often
const uint8_t  TX_ATTEMPTS        = 3;     // single-shot sends, retried if one is not acknowledged

// ---- BLE protocol (keep in sync with the Android app, BmsProtocol.kt) ----
#define SERVICE_UUID "8d3a0001-6c2b-4f6e-9b6a-2f1c5e7a4b10"
#define COMMAND_UUID "8d3a0002-6c2b-4f6e-9b6a-2f1c5e7a4b10"  // write, 1-3 bytes
#define STATUS_UUID  "8d3a0003-6c2b-4f6e-9b6a-2f1c5e7a4b10"  // read + notify, 12 bytes
#define RAW_UUID     "8d3a0004-6c2b-4f6e-9b6a-2f1c5e7a4b10"  // notify, CAN monitor packets

enum Command : uint8_t {
  CMD_BMS_RESET    = 0x01,
  CMD_SYSTEM_RESET = 0x02,
  CMD_FETCH_DATA   = 0x03,
  CMD_STOP_LIVE    = 0x04,
  CMD_START_RAW    = 0x05,  // + u16 LE: largest notification payload the phone accepts (MTU - 3)
  CMD_STOP_RAW     = 0x06,
};

// Result of sending a CAN frame (status byte [5]).
enum SendResult : uint8_t {
  SEND_OK        = 0,
  SEND_FAILED    = 1,   // driver error
  SEND_BUSY      = 2,   // transmit queue full
  SEND_BUS_OFF   = 3,   // controller is recovering from too many bus errors
  SEND_NO_ACK    = 4,   // nobody acknowledged it: scooter off or CAN-H/L not connected
};

// Status packet (protocol 3):
//   [0..1]   pack voltage, mV, little-endian
//   [2]      SOC, %
//   [3]      flags: bit0 = live streaming on, bit1 = CAN data is fresh, bit2 = CAN monitor on
//   [4]      last command id (0 = none yet)
//   [5]      last command result (SendResult)
//   [6]      command counter (increments for every command handled)
//   [7]      protocol version
//   [8..9]   CAN monitor: frames lost by the CAN driver (u16 LE, stops at 65535)
//   [10..11] CAN monitor: frames lost on the Bluetooth link (u16 LE, stops at 65535)
const uint8_t PROTOCOL_VERSION = 3;
const uint8_t FLAG_LIVE  = 0x01;
const uint8_t FLAG_FRESH = 0x02;
const uint8_t FLAG_RAW   = 0x04;

// CAN monitor packet (protocol 3):
//   [0]      format = 0x03
//   [1..4]   base time, microseconds since boot (u32 LE, wraps every ~71 minutes)
//   then records, each:
//     [0]    flags: bits0-3 = dlc, bit5 = remote frame, bit6 = 29-bit id, bit7 = sent by this tool
//     [1..2] time after the base, in 10 us steps (u16 LE)
//     [..]   id: 2 bytes (11-bit) or 4 bytes (29-bit), LE
//     [..]   data: dlc bytes (none for remote frames)
// An 8-byte standard frame takes 13 bytes, so 18 fit a 247-byte MTU.
const uint8_t RAW_FORMAT = 0x03;
const uint8_t REC_RTR = 0x20, REC_EXT = 0x40, REC_TX = 0x80;
const uint16_t RAW_MAX_PAYLOAD = 244;

BLEServer *server;
BLECharacteristic *statusChar;
BLECharacteristic *rawChar;

volatile uint8_t pendingCommand = 0;   // set by the BLE task, handled in loop()
volatile uint8_t pendingArg[2] = {0, 0};
volatile bool clientConnected = false;

volatile uint16_t rawVoltage = 0;   // mV
volatile uint8_t soc = 0;           // %
volatile uint32_t lastDataMs = 0;
volatile bool haveData = false;
bool live = false;
uint8_t lastCommand = 0;
uint8_t lastResult = 0;
uint8_t commandCounter = 0;
uint32_t lastNotifyMs = 0;

// Frames waiting to go to the phone. Written by the receive task and by sendCAN(),
// read by loop(); the write side is guarded by a spinlock.
struct RawRecord {
  uint32_t us;
  uint32_t id;
  uint8_t flags;        // dlc | REC_* bits
  uint8_t data[8];
};
const uint16_t RAW_BUFFER = 1024;
RawRecord rawBuffer[RAW_BUFFER];
volatile uint16_t rawHead = 0, rawTail = 0;   // head = next write, tail = next send
portMUX_TYPE rawLock = portMUX_INITIALIZER_UNLOCKED;
volatile bool rawStreaming = false;
uint16_t rawMaxPayload = 20;
volatile uint16_t lostOnLink = 0;
uint32_t lostAtStart = 0;              // driver's lost-frame counters when the monitor started
uint32_t lastRawNotifyMs = 0;

// ---------------------------------------------------------------- CAN monitor

void pushRaw(uint32_t us, const twai_message_t &msg, bool tx) {
  if (!rawStreaming) return;
  uint8_t dlc = msg.data_length_code > 8 ? 8 : msg.data_length_code;
  portENTER_CRITICAL(&rawLock);
  uint16_t next = (rawHead + 1) % RAW_BUFFER;
  if (next == rawTail) {
    if (lostOnLink < 0xFFFF) lostOnLink = lostOnLink + 1;   // the phone is not keeping up
  } else {
    RawRecord &r = rawBuffer[rawHead];
    r.us = us;
    r.id = msg.identifier;
    r.flags = dlc | (msg.rtr ? REC_RTR : 0) | (msg.extd ? REC_EXT : 0) | (tx ? REC_TX : 0);
    memcpy(r.data, msg.data, 8);
    rawHead = next;
  }
  portEXIT_CRITICAL(&rawLock);
}

// Sends as many buffered frames as fit one notification.
void flushRaw() {
  if (!rawStreaming || !clientConnected || rawHead == rawTail) return;
  if (millis() - lastRawNotifyMs < RAW_NOTIFY_MS) return;
  lastRawNotifyMs = millis();

  uint8_t packet[RAW_MAX_PAYLOAD];
  uint16_t len = 5;
  uint32_t base = rawBuffer[rawTail].us;
  packet[0] = RAW_FORMAT;
  for (int i = 0; i < 4; i++) packet[1 + i] = (base >> (8 * i)) & 0xFF;

  while (rawTail != rawHead) {
    const RawRecord &r = rawBuffer[rawTail];
    uint8_t dlc = r.flags & 0x0F;
    bool ext = r.flags & REC_EXT;
    uint8_t dataLen = (r.flags & REC_RTR) ? 0 : dlc;
    uint16_t size = 3 + (ext ? 4 : 2) + dataLen;
    uint32_t dt = (r.us - base) / 10;
    if (len + size > rawMaxPayload || dt > 0xFFFF) break;   // next packet gets a new base
    uint8_t *p = packet + len;
    p[0] = r.flags;
    p[1] = dt & 0xFF;
    p[2] = dt >> 8;
    p += 3;
    for (int i = 0; i < (ext ? 4 : 2); i++) *p++ = (r.id >> (8 * i)) & 0xFF;
    memcpy(p, r.data, dataLen);
    len += size;
    rawTail = (rawTail + 1) % RAW_BUFFER;
  }
  rawChar->setValue(packet, len);
  rawChar->notify();
}

uint32_t driverLostCount() {
  twai_status_info_t s;
  if (twai_get_status_info(&s) != ESP_OK) return 0;
  return s.rx_missed_count + s.rx_overrun_count;
}

void startRaw(uint16_t maxPayload) {
  rawMaxPayload = maxPayload < 20 ? 20 : (maxPayload > RAW_MAX_PAYLOAD ? RAW_MAX_PAYLOAD : maxPayload);
  portENTER_CRITICAL(&rawLock);
  rawHead = 0;
  rawTail = 0;
  portEXIT_CRITICAL(&rawLock);
  lostOnLink = 0;
  lostAtStart = driverLostCount();
  rawStreaming = true;
}

// Frames the CAN driver dropped since the monitor started (its queue was full).
uint16_t lostAtChip() {
  uint32_t lost = driverLostCount() - lostAtStart;
  return lost > 0xFFFF ? 0xFFFF : lost;
}

// ---------------------------------------------------------------- CAN (TWAI)

bool setupCAN() {
  twai_general_config_t g = TWAI_GENERAL_CONFIG_DEFAULT(PIN_CAN_TX, PIN_CAN_RX, TWAI_MODE_NORMAL);
  g.rx_queue_len = 64;   // the MCP2515 held 2 frames; this holds 64
  g.tx_queue_len = 4;
  g.alerts_enabled = TWAI_ALERT_TX_SUCCESS | TWAI_ALERT_TX_FAILED | TWAI_ALERT_BUS_OFF | TWAI_ALERT_BUS_RECOVERED;
  twai_timing_config_t t = TWAI_TIMING_CONFIG_500KBITS();
  twai_filter_config_t f = TWAI_FILTER_CONFIG_ACCEPT_ALL();
  if (twai_driver_install(&g, &t, &f) != ESP_OK) return false;
  return twai_start() == ESP_OK;
}

// Bus-off happens after many errors (wrong bit rate, wiring fault). Recover and restart.
void handleBusAlerts(uint32_t alerts) {
  if (alerts & TWAI_ALERT_BUS_OFF) {
    Serial.println("CAN bus-off, recovering");
    twai_initiate_recovery();
  }
  if (alerts & TWAI_ALERT_BUS_RECOVERED) {
    Serial.println("CAN recovered");
    twai_start();
  }
}

// Sends an 8-byte frame with all data bytes 0x00.
// (The Uno firmware reused leftover bytes from its receive buffer; on a fresh
// boot those were zeros, which is what this always sends.)
uint8_t sendCAN(uint32_t id) {
  twai_message_t msg = {};
  msg.identifier = id;
  msg.data_length_code = 8;
  msg.ss = 1;   // single shot: report "no ACK" instead of retrying forever
  uint32_t sentAt = micros();

  uint32_t alerts;
  while (twai_read_alerts(&alerts, 0) == ESP_OK) handleBusAlerts(alerts);   // clear stale alerts

  for (uint8_t attempt = 0; attempt < TX_ATTEMPTS; attempt++) {
    esp_err_t err = twai_transmit(&msg, pdMS_TO_TICKS(50));
    if (err == ESP_ERR_TIMEOUT) return SEND_BUSY;
    if (err == ESP_ERR_INVALID_STATE) return SEND_BUS_OFF;
    if (err != ESP_OK) return SEND_FAILED;

    uint32_t deadline = millis() + 100;
    while ((int32_t)(deadline - millis()) > 0) {
      if (twai_read_alerts(&alerts, pdMS_TO_TICKS(10)) != ESP_OK) continue;
      handleBusAlerts(alerts);
      if (alerts & TWAI_ALERT_TX_SUCCESS) {
        pushRaw(sentAt, msg, true);   // so the monitor log shows when the tool sent it
        return SEND_OK;
      }
      if (alerts & TWAI_ALERT_TX_FAILED) break;   // not acknowledged: try again
      if (alerts & TWAI_ALERT_BUS_OFF) return SEND_BUS_OFF;
    }
  }
  return SEND_NO_ACK;
}

// Receives frames as they arrive (the driver queues up to 64) and keeps the
// latest voltage / SOC. Runs in its own task so each frame is timestamped at once.
void canTask(void *) {
  twai_message_t msg;
  for (;;) {
    if (twai_receive(&msg, portMAX_DELAY) != ESP_OK) {
      delay(10);   // driver stopped (bus-off recovery); try again shortly
      continue;
    }
    pushRaw(micros(), msg, false);
    if (msg.extd || msg.rtr) continue;
    if (msg.identifier == 0x1A8 && msg.data_length_code >= 6) {
      rawVoltage = msg.data[4] | (msg.data[5] << 8);
      lastDataMs = millis();
      haveData = true;
    } else if (msg.identifier == 0x352 && msg.data_length_code >= 1) {
      soc = msg.data[0];
      lastDataMs = millis();
      haveData = true;
    }
  }
}

// ---------------------------------------------------------------- BLE

void publishStatus(bool notify) {
  bool fresh = haveData && millis() - lastDataMs < DATA_TIMEOUT_MS;
  uint16_t v = rawVoltage;
  uint16_t chip = rawStreaming ? lostAtChip() : 0;
  uint16_t link = rawStreaming ? lostOnLink : 0;
  uint8_t packet[12] = {
    (uint8_t)(v & 0xFF),
    (uint8_t)(v >> 8),
    soc,
    (uint8_t)((live ? FLAG_LIVE : 0) | (fresh ? FLAG_FRESH : 0) | (rawStreaming ? FLAG_RAW : 0)),
    lastCommand,
    lastResult,
    commandCounter,
    PROTOCOL_VERSION,
    (uint8_t)(chip & 0xFF),
    (uint8_t)(chip >> 8),
    (uint8_t)(link & 0xFF),
    (uint8_t)(link >> 8),
  };
  statusChar->setValue(packet, sizeof(packet));
  if (notify && clientConnected)
    statusChar->notify();
}

void handleCommand(uint8_t cmd) {
  switch (cmd) {
    case CMD_BMS_RESET:
      lastResult = sendCAN(0x7C1);
      break;
    case CMD_SYSTEM_RESET:
      lastResult = sendCAN(0x7C2);
      break;
    case CMD_FETCH_DATA:
      lastResult = sendCAN(0x7C1);
      live = true;
      break;
    case CMD_STOP_LIVE:
      lastResult = SEND_OK;
      live = false;
      break;
    case CMD_START_RAW:
      startRaw(pendingArg[0] | (pendingArg[1] << 8));
      lastResult = SEND_OK;
      break;
    case CMD_STOP_RAW:
      rawStreaming = false;
      lastResult = SEND_OK;
      break;
    default:
      return;  // unknown command: ignore
  }
  lastCommand = cmd;
  commandCounter++;
  Serial.printf("Command 0x%02X -> result %u\n", cmd, lastResult);
  publishStatus(true);
}

class ServerCallbacks : public BLEServerCallbacks {
  void onConnect(BLEServer *s) override {
    clientConnected = true;
    Serial.println("Phone connected");
  }
  void onDisconnect(BLEServer *s) override {
    clientConnected = false;
    live = false;
    rawStreaming = false;
    Serial.println("Phone disconnected");
  }
};

class CommandCallbacks : public BLECharacteristicCallbacks {
  void onWrite(BLECharacteristic *c) override {
    String value = c->getValue();
    if (value.length() >= 1) {
      pendingArg[0] = value.length() >= 2 ? (uint8_t)value[1] : 0;
      pendingArg[1] = value.length() >= 3 ? (uint8_t)value[2] : 0;
      pendingCommand = (uint8_t)value[0];   // last, so loop() sees the arguments with it
    }
  }
};

char deviceName[32];

// "OLA BMS Tool 3F2A": prefix + last two bytes of this board's Bluetooth address.
void buildDeviceName() {
  uint8_t mac[6];
  esp_read_mac(mac, ESP_MAC_BT);
  snprintf(deviceName, sizeof(deviceName), "%s %02X%02X", NAME_PREFIX, mac[4], mac[5]);
}

void addNotifyDescriptor(BLECharacteristic *c) {
#if defined(CONFIG_BLUEDROID_ENABLED)
  // Bluedroid needs the notification descriptor added by hand (NimBLE adds it itself).
  BLE2902 *cccd = new BLE2902();
  cccd->setAccessPermissions(ESP_GATT_PERM_READ_ENC_MITM | ESP_GATT_PERM_WRITE_ENC_MITM);
  c->addDescriptor(cccd);
#endif
}

void setupBLE() {
  buildDeviceName();
  BLEDevice::init(deviceName);

  BLESecurity *security = new BLESecurity();
  security->setPassKey(true, PASSKEY);
  security->setCapability(ESP_IO_CAP_OUT);              // "display only": the phone types the passkey
  security->setAuthenticationMode(true, true, true);    // bonding, MITM, secure connections

  server = BLEDevice::createServer();
  server->setCallbacks(new ServerCallbacks());
  server->advertiseOnDisconnect(true);

  BLEService *service = server->createService(SERVICE_UUID);

  BLECharacteristic *commandChar = service->createCharacteristic(
      COMMAND_UUID,
      BLECharacteristic::PROPERTY_WRITE | BLECharacteristic::PROPERTY_WRITE_AUTHEN);
  commandChar->setAccessPermissions(ESP_GATT_PERM_WRITE_ENC_MITM);
  commandChar->setCallbacks(new CommandCallbacks());

  statusChar = service->createCharacteristic(
      STATUS_UUID,
      BLECharacteristic::PROPERTY_READ | BLECharacteristic::PROPERTY_NOTIFY |
          BLECharacteristic::PROPERTY_READ_AUTHEN);
  statusChar->setAccessPermissions(ESP_GATT_PERM_READ_ENC_MITM);
  addNotifyDescriptor(statusChar);

  rawChar = service->createCharacteristic(RAW_UUID, BLECharacteristic::PROPERTY_NOTIFY);
  rawChar->setAccessPermissions(ESP_GATT_PERM_READ_ENC_MITM);
  addNotifyDescriptor(rawChar);

  publishStatus(false);
  service->start();

  BLEAdvertising *advertising = BLEDevice::getAdvertising();
  advertising->addServiceUUID(SERVICE_UUID);
  advertising->setScanResponse(true);
  BLEDevice::startAdvertising();
}

// ---------------------------------------------------------------- main

void setup() {
  Serial.begin(115200);
  Serial.printf("ESP32 chip revision %d\n", ESP.getChipRevision());

  if (!setupCAN())
    Serial.println("CAN driver failed to start; check the TX/RX pins");
  // Receive task on core 1 (Bluetooth runs on core 0), above the priority of loop().
  xTaskCreatePinnedToCore(canTask, "can_rx", 4096, nullptr, 5, nullptr, 1);

  setupBLE();
  Serial.printf("%s ready, advertising over BLE (address %s)\n",
                deviceName, BLEDevice::getAddress().toString().c_str());
}

void loop() {
  uint32_t alerts;
  if (twai_read_alerts(&alerts, 0) == ESP_OK) handleBusAlerts(alerts);

  uint8_t cmd = pendingCommand;
  if (cmd != 0) {
    pendingCommand = 0;
    handleCommand(cmd);
  }

  flushRaw();

  if (millis() - lastNotifyMs >= NOTIFY_INTERVAL_MS) {
    lastNotifyMs = millis();
    // The value is always readable; notifications only while live data or the monitor is on.
    publishStatus(live || rawStreaming);
  }

  delay(1);   // receiving runs in its own task; this loop only sends to the phone
}
