// ESP32 DevKit (WROOM-32) BLE version of the Ola S1 X / S1 Air BMS tool from
// backup.hex, for the MCP2515 CAN module (the one the original Uno tool used).
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
//   INT -> GPIO 4 through a divider (10 kOhm in series, 20 kOhm to GND),
//   VCC -> 5V (VIN), GND -> GND.
//   The module runs at 5 V; a level shifter on CS/SO/SI/SCK keeps the ESP32
//   within spec. For a no-shifter build use esp32_sn65hvd230 instead.
//
// Receiving: the MCP2515 holds only 2 frames, and on a busy bus a third can
// arrive within ~0.5 ms. Its INT pin wakes a dedicated high-priority task that
// empties the chip at once with the fast "read RX buffer" command. Without the
// INT wire the task falls back to polling every 1 ms (more frames lost).
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
const int PIN_CAN_INT    = 4;           // MCP2515 INT (5 V) through a 10k/20k divider
const uint32_t SPI_CLOCK = 10000000;    // the MCP2515's maximum
const uint32_t NOTIFY_INTERVAL_MS = 250;
const uint32_t DATA_TIMEOUT_MS    = 2000;  // no 0x1A8/0x352 frame for this long -> "No CAN data"
const uint32_t RAW_NOTIFY_MS      = 5;     // at most one CAN monitor packet this often
const uint32_t ERROR_CHECK_MS     = 20;    // how often to check the chip's overflow flags
const uint32_t TX_CHECK_MS        = 50;    // how long to watch for "nobody acknowledged" after a send

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

// Result of sending a CAN frame (status byte [5]); same codes as esp32_sn65hvd230.
enum SendResult : uint8_t {
  SEND_OK        = 0,
  SEND_FAILED    = 1,   // MCP2515 error
  SEND_BUSY      = 2,   // all 3 transmit buffers busy
  SEND_BUS_OFF   = 3,   // too many bus errors: controller stopped transmitting
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
//   [8..9]   CAN monitor: frames lost at the CAN chip (u16 LE, stops at 65535; each
//            MCP2515 overflow counts once, so this is "at least")
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

// MCP2515 SPI commands (datasheet; the library keeps its copies private)
const uint8_t SPI_READ_STATUS = 0xA0;   // returns RX0IF in bit 0, RX1IF in bit 1
const uint8_t SPI_READ_RX0    = 0x90;   // read receive buffer 0 from its first id byte
const uint8_t SPI_READ_RX1    = 0x94;   // read receive buffer 1 from its first id byte
const uint8_t STATUS_RX0      = 0x01;
const uint8_t STATUS_RX1      = 0x02;
const uint8_t SPI_READ        = 0x03;   // read register: instruction, address, then data
const uint8_t REG_CNF2        = 0x29;   // bit timing register setupCAN() writes
const int MAX_RX_ROUNDS       = 32;     // a real chip is empty long before this

MCP2515 mcp2515(PIN_CAN_CS, SPI_CLOCK);
SPISettings spiSettings(SPI_CLOCK, MSBFIRST, SPI_MODE0);
SemaphoreHandle_t spiMutex;              // the receive task and loop() both talk to the chip
TaskHandle_t canTaskHandle;

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
volatile uint16_t lostAtChip = 0;
volatile uint16_t lostOnLink = 0;
uint32_t lastRawNotifyMs = 0;

// ---------------------------------------------------------------- CAN monitor

void bump(volatile uint16_t &counter) {
  if (counter < 0xFFFF) counter = counter + 1;
}

void pushRaw(uint32_t us, uint32_t id, uint8_t flags, const uint8_t *data) {
  if (!rawStreaming) return;
  portENTER_CRITICAL(&rawLock);
  uint16_t next = (rawHead + 1) % RAW_BUFFER;
  if (next == rawTail) {
    bump(lostOnLink);   // the phone is not keeping up
  } else {
    RawRecord &r = rawBuffer[rawHead];
    r.us = us;
    r.id = id;
    r.flags = flags;
    memcpy(r.data, data, 8);
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

void startRaw(uint16_t maxPayload) {
  rawMaxPayload = maxPayload < 20 ? 20 : (maxPayload > RAW_MAX_PAYLOAD ? RAW_MAX_PAYLOAD : maxPayload);
  portENTER_CRITICAL(&rawLock);
  rawHead = 0;
  rawTail = 0;
  portEXIT_CRITICAL(&rawLock);
  lostAtChip = 0;
  lostOnLink = 0;
  rawStreaming = true;
}

// ---------------------------------------------------------------- CAN (MCP2515)

void setupCAN() {
  mcp2515.reset();   // also enables the RX0/RX1/error interrupts on INT
  mcp2515.setBitrate(CAN_500KBPS, MCP_8MHZ);
  mcp2515.setNormalMode();
}

uint8_t readStatus() {
  SPI.beginTransaction(spiSettings);
  digitalWrite(PIN_CAN_CS, LOW);
  SPI.transfer(SPI_READ_STATUS);
  uint8_t status = SPI.transfer(0x00);
  digitalWrite(PIN_CAN_CS, HIGH);
  SPI.endTransaction();
  return status;
}

// True if the MCP2515 answers: CNF2 reads back what setupCAN() wrote. With the
// module unpowered or SO not connected the reads are all 0x00 or 0xFF instead.
bool chipResponds() {
  SPI.beginTransaction(spiSettings);
  digitalWrite(PIN_CAN_CS, LOW);
  SPI.transfer(SPI_READ);
  SPI.transfer(REG_CNF2);
  uint8_t cnf2 = SPI.transfer(0x00);
  digitalWrite(PIN_CAN_CS, HIGH);
  SPI.endTransaction();
  return cnf2 == MCP_8MHz_500kBPS_CFG2;
}

// Reads a receive buffer's 13 bytes (id, dlc, data). The chip clears that
// buffer's "full" flag by itself when CS goes high, so no extra command is needed.
void readRxBuffer(uint8_t instruction, uint8_t *out) {
  SPI.beginTransaction(spiSettings);
  digitalWrite(PIN_CAN_CS, LOW);
  SPI.transfer(instruction);
  for (int i = 0; i < 13; i++) out[i] = SPI.transfer(0x00);
  digitalWrite(PIN_CAN_CS, HIGH);
  SPI.endTransaction();
}

void handleFrame(const uint8_t *b, uint32_t us) {
  bool ext = b[1] & 0x08;
  uint32_t id = ((uint32_t)b[0] << 3) | (b[1] >> 5);
  bool rtr;
  if (ext) {
    id = (id << 18) | ((uint32_t)(b[1] & 0x03) << 16) | ((uint32_t)b[2] << 8) | b[3];
    rtr = b[4] & 0x40;
  } else {
    rtr = b[1] & 0x10;
  }
  uint8_t dlc = b[4] & 0x0F;
  if (dlc > 8) dlc = 8;
  const uint8_t *data = b + 5;
  pushRaw(us, id, dlc | (rtr ? REC_RTR : 0) | (ext ? REC_EXT : 0), data);

  if (ext || rtr) return;
  if (id == 0x1A8 && dlc >= 6) {
    rawVoltage = data[4] | (data[5] << 8);
    lastDataMs = millis();
    haveData = true;
  } else if (id == 0x352 && dlc >= 1) {
    soc = data[0];
    lastDataMs = millis();
    haveData = true;
  }
}

// Counts receive overflows and clears the error interrupt so INT can signal again.
// (Not clearRXnOVR(): that also wipes the "frame waiting" flags and drops frames.)
void checkErrors() {
  xSemaphoreTake(spiMutex, portMAX_DELAY);
  uint8_t eflg = mcp2515.getErrorFlags();
  uint8_t intf = mcp2515.getInterrupts();
  if (eflg & (MCP2515::EFLG_RX0OVR | MCP2515::EFLG_RX1OVR)) {
    if (rawStreaming) bump(lostAtChip);
    mcp2515.clearRXnOVRFlags();
  }
  if (intf & MCP2515::CANINTF_ERRIF) mcp2515.clearERRIF();
  if (intf & MCP2515::CANINTF_MERRF) mcp2515.clearMERR();
  xSemaphoreGive(spiMutex);
}

void IRAM_ATTR onCanInterrupt() {
  BaseType_t woken = pdFALSE;
  vTaskNotifyGiveFromISR(canTaskHandle, &woken);
  if (woken) portYIELD_FROM_ISR();
}

// Empties the chip whenever INT fires (or every 1 ms if INT is not wired).
void canTask(void *) {
  uint32_t lastErrorCheck = 0;
  uint8_t b0[13], b1[13];
  for (;;) {
    ulTaskNotifyTake(pdTRUE, 1);
    // Bounded: if the SPI reads are garbage (module missing or unpowered) the
    // "frame waiting" bits never clear, and an endless loop here would starve
    // everything else on this core.
    int rounds = 0;
    for (; rounds < MAX_RX_ROUNDS; rounds++) {
      xSemaphoreTake(spiMutex, portMAX_DELAY);
      uint32_t us = micros();
      uint8_t status = readStatus();
      bool has0 = status & STATUS_RX0;
      bool has1 = status & STATUS_RX1;
      if (has0) readRxBuffer(SPI_READ_RX0, b0);
      if (has1) readRxBuffer(SPI_READ_RX1, b1);
      xSemaphoreGive(spiMutex);
      if (!has0 && !has1) break;
      if (has0) handleFrame(b0, us);
      if (has1) handleFrame(b1, us);
    }
    if (rounds == MAX_RX_ROUNDS) {
      vTaskDelay(pdMS_TO_TICKS(10));   // not a real chip: back off, let the rest run
      continue;
    }
    // INT still low with both buffers empty means an error flag is holding it down.
    if (digitalRead(PIN_CAN_INT) == LOW || millis() - lastErrorCheck >= ERROR_CHECK_MS) {
      lastErrorCheck = millis();
      checkErrors();
    }
  }
}

// Sends an 8-byte frame with all data bytes 0x00.
// (The Uno firmware reused leftover bytes from its receive buffer; on a fresh
// boot those were zeros, which is what this always sends.)
uint8_t sendCAN(uint32_t id) {
  struct can_frame tx = {};
  tx.can_id = id;
  tx.can_dlc = 8;
  uint32_t sentAt = micros();
  xSemaphoreTake(spiMutex, portMAX_DELAY);
  MCP2515::ERROR err = mcp2515.sendMessage(&tx);
  xSemaphoreGive(spiMutex);
  if (err == MCP2515::ERROR_ALLTXBUSY) return SEND_BUSY;
  if (err != MCP2515::ERROR_OK) return SEND_FAILED;

  // The MCP2515 retries until someone acknowledges the frame. With nobody
  // listening its error counter climbs to "error passive" within a few ms.
  uint32_t start = millis();
  while (millis() - start < TX_CHECK_MS) {
    xSemaphoreTake(spiMutex, portMAX_DELAY);
    uint8_t flags = mcp2515.getErrorFlags();
    if (flags & (MCP2515::EFLG_TXBO | MCP2515::EFLG_TXEP)) {
      setupCAN();   // restarting the chip cancels the endless retries and clears the counters
      xSemaphoreGive(spiMutex);
      return (flags & MCP2515::EFLG_TXBO) ? SEND_BUS_OFF : SEND_NO_ACK;
    }
    xSemaphoreGive(spiMutex);
    delay(2);
  }
  pushRaw(sentAt, id, 8 | REC_TX, tx.data);   // so the monitor log shows when the tool sent it
  return SEND_OK;
}

// ---------------------------------------------------------------- BLE

void publishStatus(bool notify) {
  bool fresh = haveData && millis() - lastDataMs < DATA_TIMEOUT_MS;
  uint16_t v = rawVoltage;
  uint8_t packet[12] = {
    (uint8_t)(v & 0xFF),
    (uint8_t)(v >> 8),
    soc,
    (uint8_t)((live ? FLAG_LIVE : 0) | (fresh ? FLAG_FRESH : 0) | (rawStreaming ? FLAG_RAW : 0)),
    lastCommand,
    lastResult,
    commandCounter,
    PROTOCOL_VERSION,
    (uint8_t)(lostAtChip & 0xFF),
    (uint8_t)(lostAtChip >> 8),
    (uint8_t)(lostOnLink & 0xFF),
    (uint8_t)(lostOnLink >> 8),
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
  Serial.printf("\nOLA BMS Tool (MCP2515), protocol %d, starting\n", PROTOCOL_VERSION);

  // Bluetooth first, so the phone can always find the board, whatever the CAN side does.
  setupBLE();
  Serial.printf("%s (MCP2515) advertising over BLE (address %s)\n",
                deviceName, BLEDevice::getAddress().toString().c_str());

  spiMutex = xSemaphoreCreateMutex();
  pinMode(PIN_CAN_CS, OUTPUT);
  digitalWrite(PIN_CAN_CS, HIGH);
  SPI.begin();
  setupCAN();
  if (chipResponds())
    Serial.println("MCP2515 found, CAN at 500 kbps");
  else
    Serial.println("MCP2515 not responding: check its 5 V supply and the CS/SO/SI/SCK wires");

  // Receive task on core 1 (Bluetooth runs on core 0), above loop()'s priority.
  xTaskCreatePinnedToCore(canTask, "can_rx", 4096, nullptr, 5, &canTaskHandle, 1);
  pinMode(PIN_CAN_INT, INPUT_PULLUP);   // pull-up keeps it idle if INT isn't wired
  attachInterrupt(digitalPinToInterrupt(PIN_CAN_INT), onCanInterrupt, FALLING);
}

void loop() {
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
