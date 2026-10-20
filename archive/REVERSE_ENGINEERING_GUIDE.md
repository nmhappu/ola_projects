# Reverse-engineering Arduino Uno firmware: a hands-on guide

This guide teaches the process I used to turn `backup.hex` back into
`backup_reconstructed/backup_reconstructed.ino`, step by step, so you can do it
yourself on any Uno firmware. Every example comes from `backup.hex`, so you can
run each command and compare your output with what's shown here.

**Files in this folder**

| File | What it is |
|---|---|
| `re_tools\hexinfo.py` | Step 1: survey a .hex (layout, interrupts, `main()`, strings) |
| `re_tools\asm.py` | Step 2: annotated disassembly (register names, strings, your names) |
| `re_tools\fingerprint.py` | Step 4 shortcut: auto-names library functions |
| `re_tools\compare.py` | Step 7: checks a rebuilt sketch against the original |
| `backup.hex.names.txt` | The names I identified. `asm.py` reads it automatically |
| `backup.asm` | The annotated disassembly of `backup.hex` (regenerate with `asm.py`) |

---

## 0. The big idea

```
your .ino  --compiler-->  machine code (.hex)  --you, now-->  equivalent .ino
```

**What survives compilation:** the logic, every constant (pin numbers, CAN IDs,
delays), every string, which hardware registers are touched, and what calls what.

**What is lost:** variable and function names, comments, formatting, and
sometimes the function boundaries themselves (the compiler copies small functions
into their callers, which is called *inlining*).

So reverse engineering is mostly **recognising patterns and naming things**. You
start with 9,000 bytes of anonymous instructions. Each function you identify
makes the rest easier to read.

Encouraging fact: **most of a typical Arduino binary isn't the sketch.** In
`backup.hex`, roughly three quarters is the Arduino core, Wire, SPI, the LCD and
CAN libraries, and floating-point maths. You never need to understand those
line by line. You only need to *recognise* them.

---

## 1. Tools (one-time setup)

Already installed on this PC. On a new machine:

```powershell
winget install ArduinoSA.CLI
arduino-cli core install arduino:avr      # provides avr-objdump, avr-nm, avr-gcc
```

plus Python 3. The scripts in `re_tools` find `avr-objdump` by themselves.

---

## 2. Step 1: survey the file

```powershell
python re_tools\hexinfo.py backup.hex
```

### 2a. What a .hex file is

Open `backup.hex` in Notepad. Each line is a *record*:

```
:20 0000 00 0C9462000C948A00...  B8
 │   │   │  └ data bytes          └ checksum
 │   │   └ type (00 = data, 01 = end of file)
 │   └ address where these bytes go in flash
 └ number of data bytes (0x20 = 32)
```

That's all it is: "put these bytes at this address". The script rebuilds the
32 KB flash image from it.

### 2b. Flash layout (what hexinfo prints)

```
0x0000  interrupt vector table   26 entries, each "jmp handler"
0x0068  constant tables          pin -> port/bit maps used by digitalWrite()
0x00C4  start-up code            sets up the stack, copies .data to RAM,
                                 runs global constructors, calls main()
 ....   functions                Arduino core, libraries, YOUR sketch
0x22B8  .data initial values     strings and initialised globals; copied to RAM 0x0100 at boot
0x7E00  Optiboot bootloader      ignore this; it isn't part of the sketch
```

### 2c. Reading the output

```
reset handler: 0x00C4   main(): 0x1888
.data: 218 bytes copied from flash 0x22B8 to RAM 0x0100-0x01D9 at start-up
global constructor: 0x17BA
```

* **`main()`** is where `setup()` and `loop()` live (see Step 3).
* **.data** matters because **strings live in RAM, not flash**. The text
  `">Trigger done"` sits at flash `0x2321`, but the code refers to it by its
  RAM address `0x0169` (= `0x0100 + (0x2321 - 0x22B8)`). The script does this
  conversion for you.
* **The global constructor** runs before `main()` and creates objects such as
  `LiquidCrystal_I2C lcd(0x27, 16, 2);`. Its constants reveal those arguments.

```
#16 TIMER0_OVF  -> 0x1438   millis()/delay()
#18 USART_RX    -> 0x1518   Serial (receive)
#19 USART_UDRE  -> 0x14CC   Serial (transmit)
#24 TWI         -> 0x157C   Wire / I2C
```

**The interrupt vectors show which hardware the sketch uses.** Here: timing,
Serial and I2C. The absence of entries is informative too: no `attachInterrupt`,
no Servo, no `tone()`. (SPI usually doesn't show up here, because the SPI
library doesn't use interrupts. You find it in Step 4 instead.)

```
flash 0x2321  RAM 0x0169 '>Trigger done'     used at: 0x0D18
flash 0x2357  RAM 0x019F '>Pack_V: '         used at: 0x0D9C, 0x1186
flash 0x236B  RAM 0x01B3 'No_CAN Data'       used at: 0x1208
```

**Strings are the single best clue.** In about 10 seconds you know this is a
battery tool that reads data over CAN. "used at" gives the exact code addresses
that print each string, which become your first targets in Step 6. (One-character
strings like `"V"` are skipped, and an occasional "used at" hit is a coincidence:
the same number used for something else.)

---

## 3. Step 2: disassemble and learn to read AVR assembly

```powershell
python re_tools\asm.py backup.hex                  # whole program -> backup.asm
python re_tools\asm.py backup.hex 0x10ee 0x1204    # just one range, printed
```

Each output line is: `address: raw bytes  instruction operands  ; notes`.
The notes (register names, strings, your names) are added by the script.

### 3a. The registers

The ATmega328P has 32 working registers, `r0` to `r31`, each 8 bits. A 16-bit
value uses a pair (`r24:r25`, low byte first). A 32-bit value uses four
(`r22..r25`). Two rules cover most of what you'll see:

| Rule | Meaning |
|---|---|
| **`r1` is always 0** | so `sts 0x0100, r1` means "store 0" |
| **Arguments go in r24, r22, r20, r18...** | 1st arg in `r24:r25`, 2nd in `r22:r23`, 3rd in `r20:r21` |
| **The return value comes back in r24 (r24:r25, or r22..r25 if 32-bit)** | |
| A 32-bit argument (`long`, `float`) uses 4 registers | `delay(ms)` takes ms in `r22..r25` |
| `X`=`r26:r27`, `Y`=`r28:r29`, `Z`=`r30:r31` | pointer registers |

So this:

```
1a46:  ldi r22, 0xD0      ; pair r22:r23 = 0x07D0 = 2000
1a48:  ldi r23, 0x07
1a4a:  ldi r24, 0x00
1a4c:  ldi r25, 0x00
1a4e:  call 0x2ce <delay>
```

is `delay(2000);`.

### 3b. The ~20 instructions you need

| Instruction | Meaning | C equivalent |
|---|---|---|
| `ldi r24, 5` | load constant | `r24 = 5` |
| `mov` / `movw` | copy 1 / 2 registers | `a = b` |
| `lds r24, 0x0100` | load from RAM address (a **global variable**) | `r24 = menu` |
| `sts 0x0100, r24` | store to RAM address | `menu = r24` |
| `ld`/`st`/`ldd`/`std` `Z+3` | load/store through a pointer, with offset | `p->field`, `array[i]` |
| `in` / `out` | read/write a hardware register (short form) | `SPDR = x` |
| `add adc sub sbc subi sbci adiw sbiw` | arithmetic (`c` = with carry, for multi-byte) | `+  -` |
| `and or eor andi ori com` | bitwise | `&  \|  ^  ~` |
| `lsl lsr ror asr` | shifts | `<<  >>` |
| `cp cpc cpi` | compare (sets flags, stores nothing) | the condition in `if (a == b)` |
| `breq brne` | branch if equal / not equal | |
| `brcs/brlo brcc/brsh` | branch if lower / same-or-higher (**unsigned**) | `<`  `>=` |
| `brlt brge` | branch if less / greater-or-equal (**signed**) | `<`  `>=` on `int` |
| `sbrc sbrs` | skip next instruction if register bit clear / set | `if (x & bit)` |
| `rjmp jmp` | jump (`goto`) | loops, `else`, `break` |
| `call rcall` / `ret` | call a function / return | `f()` |
| `push pop` | save/restore registers (function entry/exit; ignore) | |

Signed vs unsigned branches tell you the variable's type: `brlt` means `int`,
`brcs` means `unsigned`. That's how I knew `rawVoltage` is `unsigned int`.

### 3c. Recognising C constructs

**`if (x == 0x1A8)` on a 32-bit value:** compare byte by byte, chaining the carry:

```
1130:  cpi r24, 0xA8          ; low byte  == 0xA8 ?
1132:  ldi r18, 0x01
1134:  cpc r25, r18           ; next byte == 0x01 ?
1136:  cpc r26, r1            ; next byte == 0 ?   (r1 is always 0)
1138:  cpc r27, r1            ; top byte  == 0 ?
113a:  breq 0x113e            ; equal -> continue into the if-body
113c:  rjmp 0x11de            ; not equal -> jump to the else-part
```

**`while (digitalRead(7) == LOW);`:** a tiny backward loop:

```
1c0a:  ldi r24, 0x07
1c0c:  call 0x16a <digitalRead>
1c10:  or  r24, r25           ; is the 16-bit result zero?
1c12:  breq 0x1c0a            ; yes (LOW) -> go round again
```

**`switch (menu)`:** a chain of `cpi` + `breq` going to different blocks.

**Loops:** any branch that jumps *backwards* to an earlier address.

---

## 4. Step 3: find `setup()` and `loop()`

Every Arduino program has this `main()` (from the Arduino core):

```c
int main(void) {
    init();                  // set up timers for millis()/PWM, and the ADC
    setup();
    for (;;) {
        loop();
        if (serialEventRun) serialEventRun();
    }
}
```

The compiler normally **inlines `setup()` and `loop()` into `main()`**, so
there are no separate functions for them. You find their boundaries by pattern:

1. **`init()`**: the first ~40 instructions of `main` (0x189C to 0x1922) just
   set timer registers. The script labels them `TCCR0A`, `TIMSK0`, `TCCR1B`,
   `ADCSRA`... Skip past them.
2. **`setup()`** starts right after (0x1922). Here the first call is
   `Wire_begin`, which is `lcd.init()` starting up.
3. **`loop()`** is where the backward jumps go. At the end of `main` you'll see
   `rjmp 0x1bd6` three times, so `loop()` starts at **0x1BD6**:

```
1bd6:  ldi r24, 0x07
1bd8:  call 0x16a <digitalRead>       ; if (digitalRead(7) ... 
1bdc:  or   r24, r25
1bde:  brne 0x1c14                    ;     ... == LOW) {
1be0:  lds  r24, 0x0100   ; menu      ;   menu++
...
1cc4:  rjmp 0x1bd6                    ; end of loop() -> start again
```

The `call 0x0` at 0x1CD0 is the `serialEventRun` line. It's never actually
reached, because no `serialEvent()` was defined.

**Global constructors** (0x17BA) are worth reading early. They're short and
full of constants:

```
183e:  ldi r24, 0x27   -> std Z+4    ; lcd address 0x27
1842:  ldi r24, 0x10   -> std Z+8    ; 16 columns
1846:  ldi r24, 0x02   -> std Z+9    ; 2 rows
1860:  ldi r24, 0x0A   -> st  Y      ; MCP2515 chip-select pin = 10
```

That gives `LiquidCrystal_I2C lcd(0x27, 16, 2);` and `MCP2515 mcp2515(10);`.

---

## 5. Step 4: identify the library functions

This is where most of the time goes. In rough order of payoff:

### 5a. Signature matching (do this first; it's automatic)

When **you** compile a sketch, arduino-cli also writes an **`.elf` file that
keeps every function name**. If the mystery firmware used the same libraries,
its library functions are the same instructions, so they can be matched.

1. Guess the libraries from Step 1 (strings, vectors) and Step 4b.
2. Install them and compile one of their **example sketches**:

```powershell
arduino-cli lib install "LiquidCrystal I2C" autowp-mcp2515
arduino-cli compile -b arduino:avr:uno --output-dir build\ex_lcd "$HOME\Documents\Arduino\libraries\LiquidCrystal_I2C\examples\HelloWorld"
arduino-cli compile -b arduino:avr:uno --output-dir build\ex_can "$HOME\Documents\Arduino\libraries\autowp-mcp2515\examples\CAN_read"
```

3. Match:

```powershell
python re_tools\fingerprint.py backup.hex build\ex_can\CAN_read.ino.elf build\ex_lcd\HelloWorld.pde.elf
```

On `backup.hex` this names **37 functions** (delay, Serial, Wire, LCD, MCP2515
internals...) without reading a single instruction. Append the output to your
names file with `>> backup.hex.names.txt`, then re-run `asm.py`.

It can't name functions the examples don't use, or ones the compiler
specialised differently for each sketch (`lcd.setCursor` is one: the
compiler bakes in the `lcd` object). It never names the sketch's own functions. For those,
use the next techniques.

### 5b. Hardware-register fingerprints

A function's job is obvious from the hardware it touches. `asm.py` labels these:

| You see | It is |
|---|---|
| `SPDR`, `SPSR` (`out 0x2e`, `in 0x2d`) | SPI transfer, so an SPI device (CAN, SD card, display...) |
| `TWCR`, `TWDR`, `TWBR` | Wire / I2C |
| `UDR0`, `UCSR0A/B`, `UBRR0L/H` | Serial |
| `ADMUX`, `ADCSRA`, `ADCL/H` | `analogRead()` |
| `PORTx`/`DDRx` via the tables at 0x0068 | `digitalWrite()` / `pinMode()` |
| `OCR0A/B`, `OCR1A/B`, `OCR2A/B` | `analogWrite()` (PWM) |

### 5c. Constant fingerprints

Distinctive numbers identify chips and settings:

| Constant pattern | Meaning |
|---|---|
| sends `0x30, 0x30, 0x30, 0x20` with delays | HD44780 character LCD initialisation |
| SPI sends `0xC0` | MCP2515 RESET instruction |
| SPI sends `0xA0` | MCP2515 READ STATUS |
| SPI `0x02` / `0x03` / `0x05` | MCP2515 WRITE / READ / BIT MODIFY |
| registers `0x2A,0x29,0x28` = `00 90 82` | MCP2515 CNF1-3: 500 kbps @ 8 MHz crystal (look up in the library's `mcp2515.h`) |
| `UBRR0 = 207` with `UCSR0A = 2` | Serial at 9600 baud (16 MHz, U2X: baud = 2,000,000 / (UBRR+1)) |
| `UBRR0 = 16` with `UCSR0A = 2` | 115200 baud |
| four `ldi` bytes like `00 00 7A 44` | a **float** constant: here 1000.0 (see below) |

To decode a float constant, take the four bytes in register order r18..r21 (or
r22..r25) and run:

```powershell
python -c "import struct; print(struct.unpack('<f', bytes([0x00,0x00,0x7A,0x44])))"
```

### 5d. Call counts and argument patterns

* The **most-called functions** are usually `delay`, `digitalRead`/`Write`,
  and `print`.
* A function called with `r24` = a small number (0 to 19) and `r22` = 0, 1 or 2
  is almost certainly `pinMode(pin, mode)` (0 = INPUT, 1 = OUTPUT,
  2 = INPUT_PULLUP) or `digitalWrite(pin, value)`.
* A function that receives a **string address** in `r24:r25` is `print`.

### 5e. Float maths

Floating-point maths calls helper functions: `__addsf3` (+), `__subsf3` (-),
`__mulsf3` (*), `__divsf3` (/), `__floatunsisf` (unsigned to float),
`__fixsfsi` (float to int). `fingerprint.py` names most of them. To tell `*`
from `/` by hand: division contains a shift-and-subtract loop, while
multiplication uses `mul` instructions.

Add each discovery to your names file as you go:

```
0x02ce  delay
0x0d2c  updateMenu
ram 0x0100 menu
ram 0x01e0 rawVoltage
```

Re-run `asm.py` and the listing gets more readable every time.

---

## 6. Step 5: translate the sketch functions into C

Start from the strings' "used at" addresses: those are inside the sketch's own
functions. Work through each function top to bottom, writing C as you go. Here is
`readCAN` (0x10EE) from `backup.hex`, with the C beside it:

```
10f0: call mcp_startSPI         ┐
10f4: ldi  r24, 0xA0            │ status = MCP2515 READ STATUS (0xA0)
10f6: call SPI_transfer         │   -> this is the start of
10fc: call SPI_transfer         │      mcp2515.readMessage(&canMsg)
1102: call mcp_endSPI           ┘      (library code, inlined)
110a: sbrc r28, 0 / sbrs r28,1  ; message in RX buffer 0 or 1? if neither -> 0x1204
1116: call mcp_readMessage_rxb
111a: or r24,r25 / breq         ; if (... == MCP2515::ERROR_OK) {

1120: lds r24..r27, canMsg.can_id
1130: cpi/cpc ... 0x000001A8    ;   if (canMsg.can_id == 0x1A8) {
113e: lds r24, canMsg.can_dlc
1142: cpi r24, 2 / brcs         ;     if (canMsg.can_dlc >= 2)
1146: lds r24, canMsg.data +4   ;       rawVoltage = canMsg.data[4]
114a: lds r25, canMsg.data +5   ;                  | (canMsg.data[5] << 8);
114e: sts rawVoltage            ;
                                ;   } else if (canMsg.can_id == 0x352) { ... }  (at 0x11DE)
1156: lds r22:r23, rawVoltage
115e: ldi r24,0 / ldi r25,0     ;   zero-extend to 32 bits: it's unsigned
1162: call __floatunsisf        ;   (float)rawVoltage
1166: ldi r18..r21 = 00 00 7A 44;   1000.0
116e: call __divsf3             ;   packVoltage = rawVoltage / 1000.0;
1172: sts packVoltage           ; }
```

Tips:

* **Ignore the boilerplate** (`push`/`pop` at the start and end, the
  `in r28,SPL ... out SPH` stack setup). It's not your logic.
* **Two bytes loaded and stored together** (`data+4` into r24, `data+5` into r25)
  form one 16-bit little-endian value: `data[4] | data[5] << 8`.
* **If something looks duplicated**, it probably was written twice in the
  source. The display code in `updateMenu` and `readCAN` was copied, not shared.
* **Write the C in the same order as the assembly first.** Tidy it afterwards.

---

## 7. Step 6: rebuild and compare (how you know you got it right)

```powershell
arduino-cli compile -b arduino:avr:uno --output-dir build backup_reconstructed
python re_tools\compare.py backup.hex build\backup_reconstructed.ino.hex
```

`compare.py` replaces addresses with `N`, then reports (1) which instructions
exist in only one of the two programs, and (2) where the sequences differ. Then
you iterate. Here's how it went for this firmware:

| Attempt | Size vs original 9106 | What the diff showed | Fix |
|---|---|---|---|
| 1 | 8874 (-232) | display code missing in two places; string order different | the original repeated the display code instead of using a helper function |
| 2 | 9084 (-22) | only 8 instructions differ, all inside the LCD library constructor | none needed: the original used a slightly newer LiquidCrystal_I2C version |

Two more clues that help:

* **RAM usage** printed by the compiler should match. Both were 640 bytes,
  meaning same globals, same sizes.
* **String order in .data** roughly follows the order they appear in the
  source, a hint about the order the functions were written in.

You don't need a perfect match. Same logic is the goal. Remaining
differences usually come from library versions or compiler settings.

---

## 8. Practice exercises (easiest first)

1. **Blink.** Write the Blink sketch, compile it, then run `hexinfo.py` and
   `asm.py` on the `.hex` (not the .elf). Find `pinMode(13, OUTPUT)`,
   `digitalWrite(13, HIGH)` and `delay(1000)` (look for `0x03E8` = 1000).
   Check yourself with `avr-objdump -d -C build\Blink.ino.elf`, which shows the
   real names.
2. **Serial.** `Serial.begin(115200); Serial.println("hello");`. Find the
   `UBRR0L` write (should be 16) and the string.
3. **Back to backup.hex.** Without looking at the reconstruction: find where SOC
   is read (CAN ID `0x352`) and which byte it uses; find the CAN bitrate
   registers; find the three `pinMode` calls and their pins.
4. **Swap with a friend.** Each of you compiles a small sketch (a sensor, a few
   ifs, a string or two), shares only the `.hex`, and reconstructs the other's.
   Compare at the end. This is the best practice there is.
5. **Do the full workflow on another firmware**, starting with `fingerprint.py`.

---

## 9. Cheat sheets

### Uno pins to ports

| Arduino pin | Port / bit |
|---|---|
| D0-D7 | PORTD bit 0-7 |
| D8-D13 | PORTB bit 0-5 (D13 = PB5 = built-in LED) |
| A0-A5 | PORTC bit 0-5 |

So `sbi 0x05, 5` (`PORTB |= 1<<5`) is a direct-port-access `digitalWrite(13, HIGH)`.

### Interrupt vectors to Arduino features

| Vector | Usually means |
|---|---|
| INT0 / INT1 | `attachInterrupt()` on D2 / D3 |
| PCINT0-2 | SoftwareSerial, PinChangeInterrupt |
| TIMER0_OVF | `millis()` / `delay()` (always) |
| TIMER1_COMPA | Servo, TimerOne |
| TIMER2_COMPA | `tone()` |
| USART_RX / UDRE | Serial |
| TWI | Wire (I2C) |

### Calling convention

```
f(a, b, c)            a -> r24(:r25), b -> r22(:r23), c -> r20(:r21)
f(long or float x)    x -> r22..r25 (r22 is the lowest byte)
return value          r24 (8-bit), r24:r25 (16-bit), r22..r25 (32-bit)
r1 = 0 always.  Registers r2-r17, r28, r29 survive across calls.
```

### Where to look things up

* **ATmega328P datasheet**: every register and its bits.
* **AVR Instruction Set Manual**: what each instruction does.
* **The libraries' source code**: once you suspect a library, its `.cpp`
  shows exactly what the assembly should look like (e.g. `mcp2515.cpp`
  `reset()` matches the sequence starting at 0x1ADA: send `0xC0`, `delay(10)`, then
  zero the TX buffers, step by step).

---

## 10. Notes on legality

Reverse engineering your own firmware, or a device you own for
interoperability/repair, is generally fine. Firmware from a commercial product may
be covered by a licence or copyright. Check before redistributing what you
recover. Sending commands to a vehicle's battery system can be risky, so test on a
bench setup first.
