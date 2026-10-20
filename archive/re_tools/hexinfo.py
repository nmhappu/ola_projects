"""Step 1 - Survey an Arduino Uno (ATmega328P) .hex file.

Prints: memory layout, which interrupts are used (and what Arduino feature
that usually means), where main() is, and every readable string together
with the code addresses that load it.

Usage:
    python re_tools\\hexinfo.py backup.hex
    python re_tools\\hexinfo.py backup.hex --bin backup.bin   (also save raw binary)
"""
import argparse
import re
import sys

FLASH_SIZE = 0x8000          # 32 KB on the ATmega328P
BOOTLOADER_START = 0x7E00    # Optiboot (Uno) lives in the last 512 bytes

# ATmega328P interrupt vector table: index -> (name, what it usually means in Arduino code)
VECTORS = [
    ("RESET", "program start"),
    ("INT0", "attachInterrupt() on D2"),
    ("INT1", "attachInterrupt() on D3"),
    ("PCINT0", "pin-change interrupt D8-D13 (SoftwareSerial, PinChangeInterrupt...)"),
    ("PCINT1", "pin-change interrupt A0-A5"),
    ("PCINT2", "pin-change interrupt D0-D7 (SoftwareSerial...)"),
    ("WDT", "watchdog interrupt"),
    ("TIMER2_COMPA", "Timer2 (tone(), some IR libraries)"),
    ("TIMER2_COMPB", "Timer2"),
    ("TIMER2_OVF", "Timer2 (MsTimer2...)"),
    ("TIMER1_CAPT", "Timer1 input capture"),
    ("TIMER1_COMPA", "Timer1 (Servo, TimerOne...)"),
    ("TIMER1_COMPB", "Timer1"),
    ("TIMER1_OVF", "Timer1 (TimerOne...)"),
    ("TIMER0_COMPA", "Timer0"),
    ("TIMER0_COMPB", "Timer0"),
    ("TIMER0_OVF", "millis()/delay() - always present in Arduino code"),
    ("SPI_STC", "SPI interrupt (rare; SPI library normally polls)"),
    ("USART_RX", "Serial (receive)"),
    ("USART_UDRE", "Serial (transmit)"),
    ("USART_TX", "Serial TX complete (rare)"),
    ("ADC", "ADC interrupt (rare; analogRead() polls)"),
    ("EE_READY", "EEPROM ready"),
    ("ANALOG_COMP", "analog comparator"),
    ("TWI", "Wire / I2C"),
    ("SPM_READY", "self-programming"),
]


def load_hex(path):
    """Parse Intel HEX into a 32 KB bytearray (unused bytes stay 0xFF, like erased flash)."""
    mem = bytearray(b"\xff" * FLASH_SIZE)
    base = 0
    with open(path) as f:
        for n, line in enumerate(f, 1):
            line = line.strip()
            if not line:
                continue
            if not line.startswith(":"):
                sys.exit(f"{path} line {n}: not an Intel HEX record")
            rec = bytes.fromhex(line[1:])
            if sum(rec) & 0xFF:
                sys.exit(f"{path} line {n}: bad checksum")
            count, addr, rtype, data = rec[0], (rec[1] << 8) | rec[2], rec[3], rec[4:4 + rec[0]]
            if rtype == 0:                       # data record
                start = base + addr
                if start + count > len(mem):
                    mem.extend(b"\xff" * (start + count - len(mem)))
                mem[start:start + count] = data
            elif rtype == 1:                     # end of file
                break
            elif rtype == 2:                     # extended segment address
                base = ((data[0] << 8) | data[1]) << 4
            elif rtype == 4:                     # extended linear address
                base = ((data[0] << 8) | data[1]) << 16
    return mem


def word(mem, a):
    return mem[a] | (mem[a + 1] << 8)


def decode_jmp_call(mem, a):
    """Return (kind, byte_target) if the 4 bytes at a are JMP/CALL, else None."""
    w = word(mem, a)
    if w & 0xFE0E == 0x940C:
        kind = "jmp"
    elif w & 0xFE0E == 0x940E:
        kind = "call"
    else:
        return None
    hi = ((w >> 4) & 0x1F) << 1 | (w & 1)
    return kind, ((hi << 16) | word(mem, a + 2)) * 2


def decode_ldi(w):
    """LDI Rd,K is 1110 KKKK dddd KKKK. Returns (reg, K) or None."""
    if w & 0xF000 != 0xE000:
        return None
    return 16 + ((w >> 4) & 0xF), ((w >> 4) & 0xF0) | (w & 0xF)


def decode_cpi(w):
    """CPI Rd,K is 0011 KKKK dddd KKKK."""
    if w & 0xF000 != 0x3000:
        return None
    return 16 + ((w >> 4) & 0xF), ((w >> 4) & 0xF0) | (w & 0xF)


def find_layout(mem):
    """Find main(), the .data initializer and RAM range by reading the C start-up code."""
    info = {}
    v = decode_jmp_call(mem, 0)
    if not v:
        return info
    reset = v[1]
    info["reset"] = reset
    # The start-up code ends with:  call main ; jmp exit
    for a in range(reset, reset + 0x100, 2):
        c, j = decode_jmp_call(mem, a), decode_jmp_call(mem, a + 4)
        if c and j and c[0] == "call" and j[0] == "jmp":
            info["main"] = c[1]
            info["main_call"] = a
            break
    # .data copy loop:  ldi r17,hi(end) ; ldi r26,lo(start) ; ldi r27,hi(start) ; ldi r30,lo(src) ; ldi r31,hi(src) ... cpi r26,lo(end)
    # Global constructors (C++ objects like `LiquidCrystal_I2C lcd(0x27,16,2);`) run before main:
    #   ldi r28,lo(end) ; ldi r29,hi(end) ; ... cpi r28,lo(start)   over a table of word addresses
    regs, a = {}, reset
    while a < info.get("main_call", reset + 0x80):
        w = word(mem, a)
        ldi, cpi = decode_ldi(w), decode_cpi(w)
        if ldi:
            regs[ldi[0]] = ldi[1]
        if cpi and cpi[0] == 26 and "data_flash" not in info and {17, 27, 30, 31} <= regs.keys():
            info["data_ram_start"] = regs[26] | (regs[27] << 8)
            info["data_ram_end"] = cpi[1] | (regs[17] << 8)
            info["data_flash"] = regs[30] | (regs[31] << 8)
        if cpi and cpi[0] == 28 and {17, 28, 29} <= regs.keys():
            start, end = cpi[1] | (regs[17] << 8), regs[28] | (regs[29] << 8)
            info["ctors"] = [word(mem, i * 2) * 2 for i in range(start, end)]
        a += 2
    return info


def find_pointer_loads(mem, end):
    """Find 'ldi rN,lo ; ldi rN+1,hi' pairs - how code passes a 16-bit address (e.g. a string)."""
    refs = {}
    for a in range(0, end - 2, 2):
        x, y = decode_ldi(word(mem, a)), decode_ldi(word(mem, a + 2))
        if x and y and x[0] % 2 == 0 and y[0] == x[0] + 1:
            refs.setdefault(x[1] | (y[1] << 8), []).append(a)
    return refs


def find_strings(mem, info, app_end, min_len=3):
    """Strings in the .data initializer get a RAM address; others (PROGMEM / F()) stay in flash."""
    out = []
    df = info.get("data_flash")
    size = info.get("data_ram_end", 0) - info.get("data_ram_start", 0)
    for m in re.finditer(rb"[\x20-\x7e]{%d,}\x00" % min_len, bytes(mem[:app_end + 1])):
        text, flash = m.group()[:-1].decode(), m.start()
        if df is not None and df <= flash < df + size:
            out.append((flash, info["data_ram_start"] + (flash - df), text))
        else:
            out.append((flash, None, text))
    return out


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("hexfile")
    ap.add_argument("--bin", help="also write the raw flash image to this file")
    args = ap.parse_args()

    mem = load_hex(args.hexfile)
    if args.bin:
        open(args.bin, "wb").write(mem)
        print(f"wrote {args.bin}")

    app_end = max((i for i in range(min(BOOTLOADER_START, len(mem))) if mem[i] != 0xFF), default=0)
    has_boot = any(b != 0xFF for b in mem[BOOTLOADER_START:FLASH_SIZE])
    info = find_layout(mem)

    print("== Layout ==")
    print(f"sketch occupies 0x0000-0x{app_end:04X} ({app_end + 1} bytes)")
    print("bootloader at 0x7E00: " + ("present (ignore that region)" if has_boot else "not included"))
    if "main" in info:
        print(f"reset handler: 0x{info['reset']:04X}   main(): 0x{info['main']:04X}")
    if "data_flash" in info:
        print(f".data: {info['data_ram_end'] - info['data_ram_start']} bytes copied from flash 0x{info['data_flash']:04X}"
              f" to RAM 0x{info['data_ram_start']:04X}-0x{info['data_ram_end'] - 1:04X} at start-up")
    for c in info.get("ctors", []):
        print(f"global constructor: 0x{c:04X}  (creates the sketch's global objects - read it for their arguments)")

    print("\n== Interrupt vectors in use ==")
    targets = [decode_jmp_call(mem, i * 4) for i in range(len(VECTORS))]
    unused = max(set(t[1] for t in targets[1:] if t), key=[t[1] for t in targets[1:] if t].count)
    for i, t in enumerate(targets):
        if t and (i == 0 or t[1] != unused):
            name, hint = VECTORS[i]
            print(f"  #{i:<2} {name:<13} -> 0x{t[1]:04X}   {hint}")
    print(f"  (all other vectors jump to 0x{unused:04X} = 'bad interrupt' -> unused)")

    refs = find_pointer_loads(mem, app_end)
    print("\n== Strings ==   (where = code addresses that load this string's address)")
    for flash, ram, text in find_strings(mem, info, app_end):
        addr = ram if ram is not None else flash
        # include loads of an address inside the string (code can print a string minus its first chars)
        hits = [(a, off) for off in range(len(text)) for a in refs.get(addr + off, [])]
        where = ", ".join(f"0x{a:04X}" + (f"(+{off})" if off else "") for a, off in sorted(hits)) or "-"
        loc = f"RAM 0x{ram:04X}" if ram is not None else "flash   "
        print(f"  flash 0x{flash:04X}  {loc:<9} {text!r:<24} used at: {where}")


if __name__ == "__main__":
    main()
