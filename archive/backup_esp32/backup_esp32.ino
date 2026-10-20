// ESP32 DevKit (WROOM-32) port of backup_reconstructed.ino (the Uno firmware in backup.hex).
// Same menu, buttons, CAN IDs, scaling, texts and timings; only the pins changed.
//
// Wiring (see the voltage notes below before connecting):
//   MCP2515 module (8 MHz crystal)    ESP32
//     VCC ............................ 5V (VIN)  - the TJA1050 transceiver needs 5 V
//     GND ............................ GND
//     CS  ............................ GPIO 5
//     SO  (MISO) ..................... GPIO 19
//     SI  (MOSI) ..................... GPIO 23
//     SCK ............................ GPIO 18
//     INT ............................ not used (the original polls)
//   16x2 LCD, I2C backpack at 0x27
//     VCC 5V, GND, SDA -> GPIO 21, SCL -> GPIO 22
//   Buttons (to GND, internal pull-ups)
//     Next -> GPIO 25, Previous -> GPIO 26, Select -> GPIO 27
//
// Voltage: ESP32 pins are 3.3 V only. A 5 V MCP2515 module drives 5 V on SO, and
// the LCD backpack pulls SDA/SCL up to 5 V. Put a bidirectional level shifter
// (BSS138 type) on CS/SO/SI/SCK and on SDA/SCL.
//
// Libraries: arduino-mcp2515 by autowp, LiquidCrystal_I2C by Frank de Brabander.

#include <SPI.h>
#include <mcp2515.h>
#include <Wire.h>
#include <LiquidCrystal_I2C.h>

const int PIN_CAN_CS = 5;
const int BTN_NEXT   = 25;
const int BTN_PREV   = 26;
const int BTN_SELECT = 27;

LiquidCrystal_I2C lcd(0x27, 16, 2);
MCP2515 mcp2515(PIN_CAN_CS);
struct can_frame canMsg;

int menu = 1;                 // 1 = BMS Reset, 2 = System Reset S1X, 3 = live data
uint16_t rawVoltage = 0;      // pack voltage in mV (CAN 0x1A8, bytes 4-5, little-endian)
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

// Waits for a button to be released. delay(1) lets the ESP32's background tasks run.
void waitRelease(int pin) {
  while (digitalRead(pin) == LOW)
    delay(1);
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

  Serial.begin(115200);
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
    waitRelease(BTN_NEXT);
  }
  if (digitalRead(BTN_PREV) == LOW) {
    menu--;
    if (menu < 1) menu = 3;
    updateMenu();
    delay(100);
    waitRelease(BTN_PREV);
  }
  if (digitalRead(BTN_SELECT) == LOW) {
    executeAction();
    updateMenu();
    delay(100);
    waitRelease(BTN_SELECT);
  }
  if (menu == 3) {
    readCAN();
    delay(1);
  }
}
