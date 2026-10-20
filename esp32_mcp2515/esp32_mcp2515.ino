// ESP32 DevKit (WROOM-32) BLE version of the Ola S1 X BMS tool from backup.hex,
// for the MCP2515 CAN module (the one the original Uno tool used).
// Works with the same Android app ("BMS Remote") as esp32_sn65hvd230: the
// Bluetooth protocol is identical, only the CAN hardware differs.
//
// CAN: MCP2515 module (8 MHz crystal) at 500 kbps over SPI:
//   BMS Reset         -> sends 8-byte frame, ID 0x7C1
//   System Reset S1X  -> sends 8-byte frame, ID 0x7C2
//   Fetch data        -> sends 0x7C1, then streams pack voltage / SOC
//   pack voltage: ID 0x1A8, bytes 4-5, little-endian, millivolts
//   SOC:          ID 0x352, byte 0, percent
//
// Wiring (see WIRING.md, which also maps the old Uno pins):
//   CS -> GPIO 5, SO (MISO) -> GPIO 19, SI (MOSI) -> GPIO 23, SCK -> GPIO 18,
//   VCC -> 5V (VIN), GND -> GND, INT not used.
//   The module runs at 5 V; a level shifter on CS/SO/SI/SCK keeps the ESP32
//   within spec. For a no-shifter build use esp32_sn65hvd230 instead.
//
// BLE security: the app must pair with PASSKEY below (Android asks for it once).
// Change it before use. Unpaired phones cannot send commands or read data.
//
// Each board advertises a unique name, "OLA BMS Tool XXXX", where XXXX is the
// last 4 hex digits of its Bluetooth address, so several tools can be told apart.
//
// CAN monitor: on request the board also forwards every CAN frame it sees (and
// the frames it sends itself, flagged TX) to the app, which shows, records and
// exports them for can_tools/analyze_cells.py. The MCP2515 only buffers 2
// frames, so on a busy bus some may be lost; the app shows how many.
//
// Libraries: arduino-mcp2515 by autowp. BLE comes with the ESP32 core (3.x).

#include <SPI.h>
#include <mcp2515.h>
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLESecurity.h>
#include <BLE2902.h>
#include <esp_mac.h>

// ---- settings ----
const uint32_t PASSKEY   = 246810;      // 6 digits, entered on the phone when pairing
const char *NAME_PREFIX  = "OLA BMS Tool";
const int PIN_CAN_CS     = 5;
const uint32_t NOTIFY_INTERVAL_MS = 250;
const uint32_t DATA_TIMEOUT_MS    = 2000;  // no 0x1A8/0x352 frame for this long -> "No CAN data"
const uint32_t RAW_NOTIFY_MS      = 8;     // at most one CAN monitor packet this often
const uint32_t TX_CHECK_MS        = 50;    // how long to watch for "nobody acknowledged" after a send

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

// Result of sending a CAN frame (status byte [5]); same codes as esp32_sn65hvd230.
enum SendResult : uint8_t {
  SEND_OK        = 0,
  SEND_FAILED    = 1,   // MCP2515 error
  SEND_BUSY      = 2,   // all 3 transmit buffers busy
  SEND_BUS_OFF   = 3,   // too many bus errors: controller stopped transmitting
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
// can_frame.can_id already uses that layout (CAN_EFF_FLAG / CAN_RTR_FLAG).
const uint8_t RAW_RECORD_SIZE = 17;
const uint8_t RAW_MAX_PER_PACKET = 14;   // 238 bytes, fits a 247-byte MTU
const uint8_t RAW_TX_FLAG = 0x80;

MCP2515 mcp2515(PIN_CAN_CS);
struct can_frame rxFrame;

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
  struct can_frame frame;
  bool tx;
};
const uint16_t RAW_BUFFER = 1024;
RawRecord rawBuffer[RAW_BUFFER];
uint16_t rawHead = 0, rawTail = 0;     // head = next write, tail = next send
bool rawStreaming = false;
uint8_t rawPerPacket = 1;
uint16_t rawDropped = 0;
uint32_t lastRawNotifyMs = 0;

// ---------------------------------------------------------------- CAN monitor

void countDropped() {
  if (rawDropped < 0xFFFF) rawDropped++;
}

void pushRaw(const struct can_frame &frame, bool tx) {
  if (!rawStreaming) return;
  uint16_t next = (rawHead + 1) % RAW_BUFFER;
  if (next == rawTail) {   // phone is not keeping up
    countDropped();
    return;
  }
  rawBuffer[rawHead] = {millis(), frame, tx};
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
    uint8_t *p = packet + count * RAW_RECORD_SIZE;
    memset(p, 0, RAW_RECORD_SIZE);
    for (int i = 0; i < 4; i++) {
      p[i] = (r.t >> (8 * i)) & 0xFF;
      p[4 + i] = (r.frame.can_id >> (8 * i)) & 0xFF;
    }
    uint8_t dlc = r.frame.can_dlc > 8 ? 8 : r.frame.can_dlc;
    p[8] = dlc | (r.tx ? RAW_TX_FLAG : 0);
    if (!(r.frame.can_id & CAN_RTR_FLAG)) memcpy(p + 9, r.frame.data, dlc);
    rawTail = (rawTail + 1) % RAW_BUFFER;
    count++;
  }
  rawChar->setValue(packet, count * RAW_RECORD_SIZE);
  rawChar->notify();
}

void startRaw(uint16_t maxPayload) {
  uint16_t fits = maxPayload / RAW_RECORD_SIZE;
  rawPerPacket = fits < 1 ? 1 : (fits > RAW_MAX_PER_PACKET ? RAW_MAX_PER_PACKET : fits);
  rawHead = rawTail = 0;
  rawDropped = 0;
  rawStreaming = true;
}

// ---------------------------------------------------------------- CAN (MCP2515)

void setupCAN() {
  SPI.begin();
  mcp2515.reset();
  mcp2515.setBitrate(CAN_500KBPS, MCP_8MHZ);
  mcp2515.setNormalMode();
}

// Sends an 8-byte frame with all data bytes 0x00.
// (The Uno firmware reused leftover bytes from its receive buffer; on a fresh
// boot those were zeros, which is what this always sends.)
uint8_t sendCAN(uint32_t id) {
  struct can_frame tx = {};
  tx.can_id = id;
  tx.can_dlc = 8;
  MCP2515::ERROR err = mcp2515.sendMessage(&tx);
  if (err == MCP2515::ERROR_ALLTXBUSY) return SEND_BUSY;
  if (err != MCP2515::ERROR_OK) return SEND_FAILED;

  // The MCP2515 retries until someone acknowledges the frame. With nobody
  // listening its error counter climbs to "error passive" within a few ms.
  uint32_t start = millis();
  while (millis() - start < TX_CHECK_MS) {
    uint8_t flags = mcp2515.getErrorFlags();
    if (flags & (MCP2515::EFLG_TXBO | MCP2515::EFLG_TXEP)) {
      // Restarting the chip cancels the endless retries and clears the counters.
      setupCAN();
      return (flags & MCP2515::EFLG_TXBO) ? SEND_BUS_OFF : SEND_NO_ACK;
    }
    delay(2);
  }
  pushRaw(tx, true);   // so the monitor log shows when the tool sent it
  return SEND_OK;
}

// Drains every waiting frame and keeps the latest voltage / SOC.
void pollCAN() {
  // The MCP2515 holds only 2 frames; if both were full when a third arrived, it was lost.
  uint8_t errors = mcp2515.getErrorFlags();
  if (errors & (MCP2515::EFLG_RX0OVR | MCP2515::EFLG_RX1OVR)) {
    if (rawStreaming) countDropped();
    mcp2515.clearRXnOVR();
  }
  while (mcp2515.readMessage(&rxFrame) == MCP2515::ERROR_OK) {
    pushRaw(rxFrame, false);
    if (rxFrame.can_id == 0x1A8 && rxFrame.can_dlc >= 6) {
      rawVoltage = rxFrame.data[4] | (rxFrame.data[5] << 8);
      lastDataMs = millis();
      haveData = true;
    } else if (rxFrame.can_id == 0x352 && rxFrame.can_dlc >= 1) {
      soc = rxFrame.data[0];
      lastDataMs = millis();
      haveData = true;
    }
  }
}

// ---------------------------------------------------------------- BLE

void publishStatus(bool notify) {
  bool fresh = haveData && millis() - lastDataMs < DATA_TIMEOUT_MS;
  uint16_t lost = rawStreaming ? rawDropped : 0;
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
  setupCAN();
  setupBLE();
  Serial.printf("%s (MCP2515) ready, advertising over BLE (address %s)\n",
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

  delay(rawStreaming ? 1 : 2);   // poll faster while monitoring: the MCP2515 only buffers 2 frames
}
