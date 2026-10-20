# Ola projects

A Bluetooth BMS tool for the Ola S1 X scooter, rebuilt from the firmware of an
Arduino Uno CAN tool (`backup.hex`).

An ESP32 sits on the scooter's CAN bus and talks to an Android app over
Bluetooth Low Energy. The app reads pack voltage and state of charge, sends
the original tool's BMS reset (CAN ID 0x7C1) and system reset (0x7C2)
commands, and has a CAN monitor that records raw CAN traffic for analysis.

## Folders

| Folder | What it is |
|---|---|
| [`android_app/`](android_app) | **BMS Remote**, the Android app (Kotlin, Jetpack Compose, Material 3 Expressive). Works with both firmware variants below |
| [`esp32_sn65hvd230/`](esp32_sn65hvd230) | ESP32 firmware using its built-in CAN controller + an SN65HVD230 transceiver. Recommended: no level shifter. [Wiring](esp32_sn65hvd230/WIRING.md) |
| [`esp32_mcp2515/`](esp32_mcp2515) | Same firmware for the MCP2515 CAN module from the Uno tool. [Wiring](esp32_mcp2515/WIRING.md) |
| [`can_tools/`](can_tools) | `analyze_cells.py`: looks for individual cell voltages in CAN logs exported from the app |
| [`archive/`](archive) | Earlier stages: the Uno sketch reconstructed from `backup.hex`, the first ESP32 port, a CAN sniffer, and a reverse-engineering guide |
| `backup.hex` | The original firmware dump from the Arduino Uno tool |

## Quick start

1. Wire the ESP32 using the `WIRING.md` for your CAN board.
2. Change `PASSKEY` at the top of the firmware, then flash it (board:
   "ESP32 Dev Module"; the MCP2515 variant also needs the `autowp-mcp2515`
   library).
3. Build and install the app from `android_app/` (Android Studio, or
   `./gradlew installDebug`).
4. Switch the scooter on, open the app, tap **Connect** and enter the passkey
   when Android asks.

## Safety

The reset commands act on the scooter's battery management system. Use them
only with the scooter parked. The CAN monitor only listens, apart from the
frames the tool itself sends.
