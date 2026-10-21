# Wiring: ESP32 with the MCP2515 CAN module

This variant reuses the **MCP2515 module from the Arduino Uno tool**, so you
can build it with what you already have. The LCD and the three buttons are no
longer used; the BMS Remote app replaces them. When you get an SN65HVD230
board, `../esp32_sn65hvd230` is the simpler build (no level shifter).

## New wiring

```
   ESP32 DevKit             (level shifter)          MCP2515 module        Scooter CAN
  +-------------+          LV          HV          +---------------+
  |         3V3 |--------- LV          HV ---------| VCC  <- 5V    |
  |     5V(VIN) |----------------------------------| VCC           |
  |         GND |------- GND          GND ---------| GND           |
  |      GPIO 5 |------- LV1          HV1 ---------| CS            |
  |     GPIO 19 |------- LV2          HV2 ---------| SO            |
  |     GPIO 23 |------- LV3          HV3 ---------| SI            |
  |     GPIO 18 |------- LV4          HV4 ---------| SCK           |
  |      GPIO 4 |----+---[ 10 kΩ ]-----------------| INT           |
  +-------------+    |                             |          H    |---------- CAN-H
                  [ 20 kΩ ]                        |          L    |---------- CAN-L
                     |                             +---------------+
                    GND
```

| MCP2515 pin | ESP32 pin | Through the level shifter? |
|---|---|---|
| VCC | 5V (VIN) | No |
| GND | GND | No (also to the shifter's GND) |
| CS | GPIO 5 | Yes |
| SO | GPIO 19 | Yes (this one matters most: it outputs 5 V) |
| SI | GPIO 23 | Yes |
| SCK | GPIO 18 | Yes |
| INT | GPIO 4 | No: through a resistor divider instead (below) |

Level shifter (a 4-channel BSS138 board): **LV** to ESP32 3V3, **HV** to 5V,
**GND** to GND.

### INT wire (divider)

INT tells the ESP32 the moment a frame arrives, so it can empty the MCP2515's
2-frame buffer before the next frame overwrites it. INT is a 5 V output, so it
goes through two resistors instead of the shifter (all 4 shifter channels are
already used):

- **10 kΩ** from MCP2515 **INT** to ESP32 **GPIO 4**
- **20 kΩ** from ESP32 **GPIO 4** to **GND**

That brings 5 V down to about 3.3 V. Any pair in the same 1 : 2 ratio works
(e.g. 4.7 kΩ + 10 kΩ). Without the INT wire the firmware still works, but
falls back to checking the chip every 1 ms and loses more frames on a busy bus.

The scooter's CAN wires stay on the module's **H** and **L** screw terminals,
exactly as before.

## Where each old wire goes

The wires aren't labelled, so trace each one back to its **Uno** pin and move
its Uno end as below. The module end stays where it is.

### Finding the pins on the Uno

Hold the Uno with the USB socket and power jack on the **left**:

- **Top edge** (digital header), left to right:
  `SCL SDA AREF GND D13 D12 D11 D10 D9 D8 | D7 D6 D5 D4 D3 D2 D1 D0`
- **Bottom edge** (power and analog), left to right:
  `(blank) IOREF RESET 3.3V 5V GND GND Vin | A0 A1 A2 A3 A4 A5`
- **ICSP header**: the 6-pin block on the right edge.

Two things to watch for:
- **LCD wires** may be on the `SDA`/`SCL` pins at the top left instead of
  `A4`/`A5`. They are the same signals, and both are being removed anyway.
- **MCP2515 wires** may be on the **ICSP header** instead of D11–D13. On ICSP,
  MISO = D12 (to SO), SCK = D13 (to SCK), MOSI = D11 (to SI). CS is always on
  a normal pin (D10 in the original firmware).
- Several wires may share one **5V** or **GND** pin, or come from a breadboard
  rail. They all go to the matching ESP32 pin.

### MCP2515 module (reused)

| Old: Uno pin | MCP2515 pin | New: ESP32 pin |
|---|---|---|
| **D10** | CS | **GPIO 5** (via shifter) |
| **D12** | SO | **GPIO 19** (via shifter) |
| **D11** | SI | **GPIO 23** (via shifter) |
| **D13** | SCK | **GPIO 18** (via shifter) |
| **5V** | VCC | **5V / VIN** |
| **GND** | GND | **GND** |
| (none) | INT | **new wire:** **GPIO 4** via the 10 kΩ / 20 kΩ divider |
| (scooter) | H, L terminals | unchanged |

### 16x2 LCD with I2C backpack (no longer needed)

| Old: Uno pin | LCD backpack pin | New |
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
VIN pin, don't connect that to the ESP32.** The DevKit's VIN pin expects 5 V.
Put a 12 V to 5 V buck converter in between, or power the ESP32 from a USB
power bank. The MCP2515 module takes its 5 V from the ESP32's VIN pin.

## Finding the scooter's CAN wires

The Uno tool already taps the scooter's CAN bus: it's the two wires on the
MCP2515 module's **H** and **L** screw terminal. Reuse that tap; there's no
need to look for a new one. (I couldn't find a published pinout for the
Ola S1 X's diagnostic connector, so the existing tap is the reliable route.)

1. **Label them before unscrewing anything.** Put a strip of tape on the wire
   in **H** and write "H", and do the same for **L**. Also check whether a
   third wire (ground) runs from the tool to the scooter.
2. **Leave the scooter end alone.** Only the module end moves, and with the
   MCP2515 version it doesn't move at all.
3. **If the labels got lost, check with a multimeter:**
   - **Scooter off:** resistance between the two wires. About **60 Ω** means
     it's the CAN pair (two 120 Ω terminators in parallel); about 120 Ω is
     also CAN (one terminator on that branch).
   - **Scooter on:** DC voltage from each wire to scooter ground. Both sit
     near **2.5 V**; **CAN-H** reads slightly higher (about 2.6–3.0 V) and
     **CAN-L** slightly lower (about 2.0–2.4 V).
4. **Ground.** If the old tool had a ground wire to the scooter, connect it to
   the ESP32's GND too.
5. **Swapped?** If the app reports "CAN bus errors", swap H and L.

**Safety:** move wires with the scooter off. The CAN wires only carry a few
volts. Stay away from the thick battery cables and the motor controller's
power terminals: the pack is up to about 58 V and can deliver very high
current. Don't pierce wires to find the CAN pair; use the existing tap.

## Without a level shifter

It usually works for a quick bench test, but it is outside both chips' specs:
the module's SO pin sends 5 V into GPIO 19, and at 5 V the MCP2515 may misread
the ESP32's 3.3 V signals. Use the shifter for anything connected to the
scooter, or switch to the SN65HVD230 build.

## Checks before connecting to the scooter

1. **Crystal.** The firmware assumes the module's crystal is **8 MHz** (marked
   8.000 on the silver can), as the original Uno firmware did. A 16 MHz module
   needs `MCP_16MHZ` in `setupCAN()`.
2. **Terminator jumper (J1).** Leave it as it was on the Uno tool.
3. **First power-up.** Open the Serial Monitor at 115200 baud. You should see
   `OLA BMS Tool XXXX (MCP2515) ready`.
4. **If the app reports "No reply on the CAN bus"**, the scooter is off or the
   CAN wires aren't connected. "CAN bus errors" usually means CAN-H and CAN-L
   are swapped or the crystal setting is wrong.
