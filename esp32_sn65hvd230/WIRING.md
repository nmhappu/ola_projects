# Wiring: from the Arduino Uno tool to the ESP32 BMS Tool

The new tool uses the ESP32's built-in CAN controller and an **SN65HVD230**
3.3 V CAN transceiver board (sold as "CJMCU-230", "VP230" or
"SN65HVD230 CAN board"). The MCP2515 module, the LCD and the three buttons
are no longer used; the phone app replaces the screen and buttons.

Don't have an SN65HVD230 yet? `../esp32_mcp2515` builds the same tool with
the MCP2515 module from the Uno, and works with the same app.

## Parts

- ESP32 DevKit (WROOM-32, 30 or 38 pin)
- SN65HVD230 CAN transceiver board
- Female-female jumper wires
- 5 V supply for the ESP32 (USB, or a 5 V buck converter, see Power below)

## New wiring

```
   ESP32 DevKit                SN65HVD230 board            Scooter CAN
  +-------------+             +----------------+
  |         3V3 |-------------| 3V3            |
  |         GND |-------------| GND            |
  |      GPIO 5 |-------------| CTX  (TX / D)  |
  |      GPIO 4 |-------------| CRX  (RX / R)  |
  |             |             |           CANH |------------  CAN-H
  |             |             |           CANL |------------  CAN-L
  +-------------+             +----------------+
```

| From (ESP32) | To (SN65HVD230) |
|---|---|
| 3V3 | 3V3 (not 5V) |
| GND | GND |
| GPIO 5 | CTX (may be labelled TX or D) |
| GPIO 4 | CRX (may be labelled RX or R) |

| SN65HVD230 | Scooter |
|---|---|
| CANH | CAN-H (the wire that was on the MCP2515 module's **H** terminal) |
| CANL | CAN-L (the wire that was on the MCP2515 module's **L** terminal) |

## Where each old wire goes

The wires aren't labelled, so trace each one back to where it plugs into the
**Uno** or the **MCP2515 module**, then move it as below.

### MCP2515 CAN module (being replaced)

| Old: Uno pin | Old: MCP2515 pin | New |
|---|---|---|
| D10 | CS | **Not used**, remove |
| D11 | SI (MOSI) | **Not used**, remove |
| D12 | SO (MISO) | **Not used**, remove |
| D13 | SCK | **Not used**, remove |
| (none) | INT | **Not used**, remove |
| 5V | VCC | **Not used**, remove |
| GND | GND | **Not used**, remove |
| (scooter) | **H** screw terminal | SN65HVD230 **CANH** |
| (scooter) | **L** screw terminal | SN65HVD230 **CANL** |

Only the two scooter CAN wires are reused. Keep them the same way round: the
one on **H** goes to **CANH**, the one on **L** goes to **CANL**.

### 16x2 LCD with I2C backpack (no longer needed)

| Old: Uno pin | Old: LCD backpack pin | New |
|---|---|---|
| A4 | SDA | Not used |
| A5 | SCL | Not used |
| 5V | VCC | Not used |
| GND | GND | Not used |

### Buttons (no longer needed; the app has them)

| Old: Uno pin | Button | Now in the app |
|---|---|---|
| D7 | Next | (not needed, actions are separate buttons) |
| D5 | Previous | (not needed) |
| D6 | Select | Fetch data / BMS reset / System reset buttons |
| GND | other side of all three | Not used |

### Power

| Old | New |
|---|---|
| Whatever fed the Uno (USB, barrel jack, or VIN) | ESP32 **USB**, or **5V/VIN** pin from a 5 V supply |

**If the Uno was powered from the scooter's 12 V through its barrel jack or
VIN pin, don't connect that to the ESP32.** The DevKit's VIN pin expects
5 V. Put a 12 V to 5 V buck converter in between, or power the ESP32 from a
USB power bank.

## Checks before connecting to the scooter

1. **Terminator.** Most SN65HVD230 boards have a 120 ohm resistor between
   CANH and CANL (often marked R2 or "120"). The scooter's bus is already
   terminated, so a third terminator in the middle is usually harmless for a
   short tap but not ideal. If the MCP2515 module worked with its jumper
   (J1) removed, remove or cut this resistor too; if J1 was fitted, leave it.
2. **3V3, not 5V.** The SN65HVD230 is a 3.3 V part. Feeding it 5 V can damage
   the ESP32's GPIO 4.
3. **First power-up.** Open the Serial Monitor at 115200 baud. You should see
   the chip revision, then `OLA BMS Tool XXXX ready`. If it says
   `CAN driver failed to start`, check GPIO 4 and 5.
4. **If the app reports "CAN bus errors"**, CAN-H and CAN-L are probably
   swapped. If it reports "No reply on the CAN bus", the scooter is off or the
   CAN wires aren't connected.
