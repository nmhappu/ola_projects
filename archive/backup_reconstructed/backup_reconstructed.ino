// Reconstructed from backup.hex (Arduino Uno / ATmega328P) by disassembly.
// Pins, CAN IDs, strings, timings and program flow match the binary;
// variable and function names are guesses (the originals are not stored in a .hex).
//
// Hardware implied by the firmware:
//   - MCP2515 CAN module, CS on D10, 8 MHz crystal, CAN bus at 500 kbps
//   - 16x2 HD44780 LCD on an I2C backpack at address 0x27
//   - 3 push buttons to GND: D7 = next, D5 = previous, D6 = select
//
// Libraries the binary was built with:
//   - arduino-mcp2515 by autowp   (<mcp2515.h>)
//   - LiquidCrystal_I2C by Frank de Brabander (uses lcd.init())
//
// Verified: compiled with arduino:avr 1.8.8, every instruction matches backup.hex
// except 8 inside LiquidCrystal_I2C itself (the original used a slightly newer
// build of that library with a "charsize" constructor argument). 9084 vs 9106 bytes.

#include <SPI.h>
#include <mcp2515.h>
#include <Wire.h>
#include <LiquidCrystal_I2C.h>

LiquidCrystal_I2C lcd(0x27, 16, 2);
MCP2515 mcp2515(10);
struct can_frame canMsg;

const int BTN_NEXT   = 7;
const int BTN_PREV   = 5;
const int BTN_SELECT = 6;

int menu = 1;                 // 1 = BMS Reset, 2 = System Reset S1X, 3 = live data
unsigned int rawVoltage = 0;  // pack voltage in mV (CAN 0x1A8, bytes 4-5, little-endian)
int soc = 0;                  // state of charge in % (CAN 0x352, byte 0)
float packVoltage = 0;

void triggerDone() {
  lcd.clear();
  lcd.print(">Trigger done");
  delay(100);
}

void updateMenu() {
  lcd.clear();
  switch (menu) {
    case 1:
      lcd.print(">BMS Reset");
      lcd.setCursor(0, 1);
      lcd.print("System Reset S1X");
      break;
    case 2:
      lcd.print("BMS Reset ");
      lcd.setCursor(0, 1);
      lcd.print(">System Reset S1X");  // 17 chars: the final "X" falls off a 16-col LCD
      break;
    case 3:
      lcd.clear();
      lcd.print(">Pack_V: ");
      lcd.print(packVoltage, 2);
      lcd.print("V");
      lcd.setCursor(0, 1);
      lcd.print("SOC: ");
      lcd.print(soc);
      lcd.print("%");
      delay(100);
      break;
  }
  rawVoltage = 0;
  soc = 0;
  packVoltage = 0;
}

// Sends an 8-byte frame. Only data[0] is set; data[1..7] keep whatever the
// last received frame left in canMsg (the original shares one buffer for TX and RX).
void sendCAN(uint32_t id) {
  canMsg.can_id  = id;
  canMsg.can_dlc = 8;
  canMsg.data[0] = 0x00;
  mcp2515.sendMessage(&canMsg);
}

void readCAN() {
  if (mcp2515.readMessage(&canMsg) == MCP2515::ERROR_OK) {
    if (canMsg.can_id == 0x1A8) {
      if (canMsg.can_dlc >= 2)
        rawVoltage = canMsg.data[4] | (canMsg.data[5] << 8);
    } else if (canMsg.can_id == 0x352) {
      if (canMsg.can_dlc >= 2)
        soc = canMsg.data[0];
    }
    packVoltage = rawVoltage / 1000.0;
  } else {
    lcd.clear();
    lcd.print("No_CAN Data");
    delay(250);
  }
  lcd.clear();
  lcd.print(">Pack_V: ");
  lcd.print(packVoltage, 2);
  lcd.print("V");
  lcd.setCursor(0, 1);
  lcd.print("SOC: ");
  lcd.print(soc);
  lcd.print("%");
  delay(10);
}

void executeAction() {
  switch (menu) {
    case 1:
      triggerDone();
      sendCAN(0x7C1);
      break;
    case 2:
      triggerDone();
      sendCAN(0x7C2);
      break;
    case 3:
      lcd.clear();
      lcd.print(">FetchingData.. ");
      sendCAN(0x7C1);
      readCAN();
      break;
  }
}

void setup() {
  lcd.init();
  lcd.backlight();
  lcd.setCursor(2, 0);
  lcd.print("  OLA...");
  delay(2000);

  pinMode(BTN_NEXT, INPUT_PULLUP);
  pinMode(BTN_PREV, INPUT_PULLUP);
  pinMode(BTN_SELECT, INPUT_PULLUP);
  updateMenu();

  Serial.begin(9600);
  SPI.begin();
  mcp2515.reset();
  mcp2515.setBitrate(CAN_500KBPS, MCP_8MHZ);
  mcp2515.setNormalMode();
}

void loop() {
  if (digitalRead(BTN_NEXT) == LOW) {
    menu++;
    if (menu > 3) menu = 1;
    updateMenu();
    delay(100);
    while (digitalRead(BTN_NEXT) == LOW);
  }
  if (digitalRead(BTN_PREV) == LOW) {
    menu--;
    if (menu < 1) menu = 3;
    updateMenu();
    delay(100);
    while (digitalRead(BTN_PREV) == LOW);
  }
  if (digitalRead(BTN_SELECT) == LOW) {
    executeAction();
    updateMenu();
    delay(100);
    while (digitalRead(BTN_SELECT) == LOW);
  }
  if (menu == 3) {
    readCAN();
    delay(1);
  }
}
