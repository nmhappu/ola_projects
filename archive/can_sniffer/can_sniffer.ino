// Raw CAN sniffer for the same hardware as backup.hex:
//   MCP2515 (8 MHz crystal, CS on D10) + 16x2 I2C LCD at 0x27.
//
// Prints every received frame to Serial at 1,000,000 baud (set the Serial
// Monitor to 1000000), one line per frame, tab-separated:
//   time_ms   ID   DLC   data bytes (hex)
// e.g.  12345	1A8	8	00 00 00 00 E8 FD 00 00
// Extended (29-bit) IDs are prefixed with "x", remote frames end with "RTR".
//
// The LCD shows frames received, distinct IDs seen and RX overflows
// (frames lost because the Uno could not keep up).

#include <SPI.h>
#include <mcp2515.h>
#include <Wire.h>
#include <LiquidCrystal_I2C.h>

// ---- settings ----
const bool LISTEN_ONLY  = true;   // never transmits or ACKs: safe on a live vehicle bus
const bool CHANGES_ONLY = false;  // only print a frame when its data differs from the previous frame with that ID
const uint32_t ONLY_ID  = 0;      // 0 = print all IDs, otherwise just this one, e.g. 0x1A8
const CAN_SPEED BITRATE = CAN_500KBPS;  // what the original firmware used; try CAN_250KBPS if nothing shows

LiquidCrystal_I2C lcd(0x27, 16, 2);
MCP2515 mcp2515(10);
struct can_frame frame;

// Last data seen per ID, for CHANGES_ONLY and for counting distinct IDs
const uint8_t MAX_IDS = 40;
uint32_t seenId[MAX_IDS];
uint8_t seenDlc[MAX_IDS];
uint8_t seenData[MAX_IDS][8];
uint8_t idCount = 0;

unsigned long frameCount = 0;
unsigned long overflowCount = 0;
unsigned long lastLcdUpdate = 0;

// Returns true if this ID is new or its data changed since last time.
bool rememberFrame(const can_frame &f) {
  for (uint8_t i = 0; i < idCount; i++) {
    if (seenId[i] == f.can_id) {
      if (seenDlc[i] == f.can_dlc && memcmp(seenData[i], f.data, f.can_dlc) == 0)
        return false;
      seenDlc[i] = f.can_dlc;
      memcpy(seenData[i], f.data, 8);
      return true;
    }
  }
  if (idCount < MAX_IDS) {
    seenId[idCount] = f.can_id;
    seenDlc[idCount] = f.can_dlc;
    memcpy(seenData[idCount], f.data, 8);
    idCount++;
  }
  return true;
}

void printFrame(const can_frame &f) {
  char line[64];
  bool ext = f.can_id & CAN_EFF_FLAG;
  uint32_t id = f.can_id & (ext ? CAN_EFF_MASK : CAN_SFF_MASK);
  int n = snprintf(line, sizeof(line), "%lu\t%s%lX\t%u\t", millis(), ext ? "x" : "", id, f.can_dlc);
  if (f.can_id & CAN_RTR_FLAG) {
    snprintf(line + n, sizeof(line) - n, "RTR");
  } else {
    for (uint8_t i = 0; i < f.can_dlc && i < 8; i++)
      n += snprintf(line + n, sizeof(line) - n, "%02X ", f.data[i]);
  }
  Serial.println(line);
}

void updateLcd() {
  lcd.setCursor(0, 0);
  lcd.print("Frames:");
  lcd.print(frameCount);
  lcd.print("   ");
  lcd.setCursor(0, 1);
  lcd.print("IDs:");
  lcd.print(idCount);
  lcd.print(" Ovf:");
  lcd.print(overflowCount);
  lcd.print("   ");
}

void setup() {
  Serial.begin(1000000);
  lcd.init();
  lcd.backlight();
  lcd.print("CAN sniffer");

  SPI.begin();
  mcp2515.reset();
  mcp2515.setBitrate(BITRATE, MCP_8MHZ);
  if (LISTEN_ONLY)
    mcp2515.setListenOnlyMode();
  else
    mcp2515.setNormalMode();

  Serial.println(F("# time_ms\tid\tdlc\tdata"));
  delay(500);
  lcd.clear();
}

void loop() {
  if (mcp2515.readMessage(&frame) == MCP2515::ERROR_OK) {
    frameCount++;
    bool changed = rememberFrame(frame);
    bool idMatches = ONLY_ID == 0 || (frame.can_id & CAN_EFF_MASK) == ONLY_ID;
    if (idMatches && (!CHANGES_ONLY || changed))
      printFrame(frame);
  }

  uint8_t eflg = mcp2515.getErrorFlags();
  if (eflg & (MCP2515::EFLG_RX0OVR | MCP2515::EFLG_RX1OVR)) {
    overflowCount++;
    mcp2515.clearRXnOVR();
  }

  if (millis() - lastLcdUpdate > 1000) {
    lastLcdUpdate = millis();
    updateLcd();
  }
}
