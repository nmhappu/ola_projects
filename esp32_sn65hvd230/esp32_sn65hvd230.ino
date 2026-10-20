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
const uint32_t RAW_NOTIFY_MS      = 8;     // at most one CAN monitor packet this often
const uint8_t  TX_ATTEMPTS        = 3;     // single-shot sends, retried if one is not acknowledged

// ---- BLE protocol (keep in sync with the Android app, BmsProtocol.kt) ----
#define SERVICE_UUID "8d3a0001-6c2b-4f6e-9b6a-2f1c5e7a4b10"
#define COMMAND_UUID "8d3a0002-6c2b-4f6e-9b6a-2f1c5e7a4b10"  // write, 1-3 bytes
#define STATUS_UUID  "8d3a0003-6c2b-4f6e-9b6a-2f1c5e7a4b10"  // read + notify, 10 bytes
#define RAW_UUID     "8d3a0004-6c2b-4f6e-9b6a-2f1c5e7a4b10"  // notify, CAN monitor records

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

// Status packet:
//   [0..1] pack voltage, mV, little-endian
//   [2]    SOC, %
//   [3]    flags: bit0 = live streaming on, bit1 = CAN data is fresh, bit2 = CAN monitor on
//   [4]    last command id (0 = none yet)
//   [5]    last command result (SendResult)
//   [6]    command counter (increments for every command handled)
//   [7]    protocol version
//   [8..9] CAN monitor frames lost since it started (u16 LE, stops at 65535)
const uint8_t PROTOCOL_VERSION = 2;
const uint8_t FLAG_LIVE  = 0x01;
const uint8_t FLAG_FRESH = 0x02;
const uint8_t FLAG_RAW   = 0x04;

// CAN monitor record, 17 bytes, several per notification:
//   [0..3] time, ms since boot (u32 LE)
//   [4..7] id (u32 LE), bit31 = extended (29-bit), bit30 = remote frame
//   [8]    dlc, bit7 set = sent by this tool   [9..16] data (unused bytes 0)
const uint8_t RAW_RECORD_SIZE = 17;
const uint8_t RAW_MAX_PER_PACKET = 14;   // 238 bytes, fits a 247-byte MTU
const uint8_t RAW_TX_FLAG = 0x80;
const uint32_t ID_EXTENDED = 0x80000000;
const uint32_t ID_REMOTE   = 0x40000000;

BLEServer *server;
BLECharacteristic *statusChar;
BLECharacteristic *rawChar;

volatile uint8_t pendingCommand = 0;   // set by the BLE task, handled in loop()
volatile uint8_t pendingArg[2] = {0, 0};
volatile bool clientConnected = false;

uint16_t rawVoltage = 0;   // mV
uint8_t soc = 0;           // %
bool live = false;
uint32_t lastDataMs = 0;
bool haveData = false;
uint8_t lastCommand = 0;
uint8_t lastResult = 0;
uint8_t commandCounter = 0;
uint32_t lastNotifyMs = 0;

// Frames waiting to go to the phone (ring buffer, loop() only).
struct RawRecord {
  uint32_t t;
  twai_message_t msg;
  bool tx;
};
const uint16_t RAW_BUFFER = 1024;
RawRecord rawBuffer[RAW_BUFFER];
uint16_t rawHead = 0, rawTail = 0;     // head = next write, tail = next send
bool rawStreaming = false;
uint8_t rawPerPacket = 1;
uint16_t rawDropped = 0;
uint32_t lastRawNotifyMs = 0;
uint32_t lostAtStart = 0;              // driver's lost-frame counters when the monitor started

// ---------------------------------------------------------------- CAN monitor

void pushRaw(const twai_message_t &msg, bool tx) {
  if (!rawStreaming) return;
  uint16_t next = (rawHead + 1) % RAW_BUFFER;
  if (next == rawTail) {   // phone is not keeping up
    if (rawDropped < 0xFFFF) rawDropped++;
    return;
  }
  rawBuffer[rawHead] = {millis(), msg, tx};
  rawHead = next;
}

// Sends up to rawPerPacket buffered frames in one notification.
void flushRaw() {
  if (!rawStreaming || !clientConnected || rawHead == rawTail) return;
  if (millis() - lastRawNotifyMs < RAW_NOTIFY_MS) return;
  lastRawNotifyMs = millis();

  uint8_t packet[RAW_RECORD_SIZE * RAW_MAX_PER_PACKET];
  uint8_t count = 0;
  while (count < rawPerPacket && rawTail != rawHead) {
    const RawRecord &r = rawBuffer[rawTail];
    uint32_t id = r.msg.identifier | (r.msg.extd ? ID_EXTENDED : 0) | (r.msg.rtr ? ID_REMOTE : 0);
    uint8_t dlc = r.msg.data_length_code > 8 ? 8 : r.msg.data_length_code;
    uint8_t *p = packet + count * RAW_RECORD_SIZE;
    memset(p, 0, RAW_RECORD_SIZE);
    for (int i = 0; i < 4; i++) {
      p[i] = (r.t >> (8 * i)) & 0xFF;
      p[4 + i] = (id >> (8 * i)) & 0xFF;
    }
    p[8] = dlc | (r.tx ? RAW_TX_FLAG : 0);
    if (!r.msg.rtr) memcpy(p + 9, r.msg.data, dlc);
    rawTail = (rawTail + 1) % RAW_BUFFER;
    count++;
  }
  rawChar->setValue(packet, count * RAW_RECORD_SIZE);
  rawChar->notify();
}

uint32_t driverLostCount() {
  twai_status_info_t s;
  if (twai_get_status_info(&s) != ESP_OK) return 0;
  return s.rx_missed_count + s.rx_overrun_count;
}

void startRaw(uint16_t maxPayload) {
  uint16_t fits = maxPayload / RAW_RECORD_SIZE;
  rawPerPacket = fits < 1 ? 1 : (fits > RAW_MAX_PER_PACKET ? RAW_MAX_PER_PACKET : fits);
  rawHead = rawTail = 0;
  rawDropped = 0;
  lostAtStart = driverLostCount();
  rawStreaming = true;
}

// Frames lost anywhere: the phone link (ring buffer) plus the CAN driver's own queue.
uint16_t lostFrames() {
  uint32_t lost = rawDropped + (driverLostCount() - lostAtStart);
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
        pushRaw(msg, true);   // so the monitor log shows exactly when the tool sent it
        return SEND_OK;
      }
      if (alerts & TWAI_ALERT_TX_FAILED) break;   // not acknowledged: try again
      if (alerts & TWAI_ALERT_BUS_OFF) return SEND_BUS_OFF;
    }
  }
  return SEND_NO_ACK;
}

// Drains every waiting frame and keeps the latest voltage / SOC.
void pollCAN() {
  uint32_t alerts;
  if (twai_read_alerts(&alerts, 0) == ESP_OK) handleBusAlerts(alerts);

  twai_message_t msg;
  while (twai_receive(&msg, 0) == ESP_OK) {
    pushRaw(msg, false);
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
  uint16_t lost = rawStreaming ? lostFrames() : 0;
  uint8_t packet[10] = {
    (uint8_t)(rawVoltage & 0xFF),
    (uint8_t)(rawVoltage >> 8),
    soc,
    (uint8_t)((live ? FLAG_LIVE : 0) | (fresh ? FLAG_FRESH : 0) | (rawStreaming ? FLAG_RAW : 0)),
    lastCommand,
    lastResult,
    commandCounter,
    PROTOCOL_VERSION,
    (uint8_t)(lost & 0xFF),
    (uint8_t)(lost >> 8),
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

  setupBLE();
  Serial.printf("%s ready, advertising over BLE (address %s)\n",
                deviceName, BLEDevice::getAddress().toString().c_str());
}

void loop() {
  pollCAN();

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

  delay(rawStreaming ? 1 : 2);   // the driver queues 64 frames, so short pauses lose nothing
}
