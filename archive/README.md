# Archive

Earlier stages of the project, kept for reference. Nothing here is needed for
the current tool: `../android_app` (the phone app), `../esp32_sn65hvd230` and
`../esp32_mcp2515` (firmware + wiring for each CAN board)
and `../can_tools` (cell-voltage analyzer).

| Item | What it is |
|---|---|
| `backup_reconstructed/` | The Arduino Uno sketch rebuilt from `backup.hex` (MCP2515 + LCD + 3 buttons) |
| `backup_esp32/` | First ESP32 port of that sketch (MCP2515 + LCD + buttons). Replaced by `esp32_mcp2515` / `esp32_sn65hvd230` |
| `can_sniffer/` | Uno/MCP2515 sniffer that prints CAN frames to the Serial Monitor. Replaced by the app's CAN monitor |
| `REVERSE_ENGINEERING_GUIDE.md` | Step-by-step guide to reverse engineering an Arduino `.hex` |
| `re_tools/` | Helper scripts used by the guide |
| `build/` | Example builds the guide compares against |
| `backup.asm`, `backup.hex.names.txt` | Disassembly of `backup.hex` and its function names |
| `backup.hex` | A copy of the original dump, so the guide's commands work when run from this folder. The original is `../backup.hex` |
