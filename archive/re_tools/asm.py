"""Step 2 - Disassemble an Arduino Uno .hex with readable annotations.

Runs avr-objdump, then adds comments:
  * hardware register names     (sts 0x00C4  ->  ; UBRR0L)
  * strings                     (ldi r24,0x69 / ldi r25,0x01  ->  ; ">Trigger done")
  * your own function names     (call 0x2ce  ->  call 0x2ce <delay>)

Names come from a text file you grow as you work out what each function does,
one per line:   0x02ce delay
RAM variables use a "ram" prefix:   ram 0x01e0 rawVoltage
By default it is <hexfile>.names.txt (e.g. backup.hex.names.txt).

Usage:
    python re_tools\\asm.py backup.hex                    writes backup.asm (whole program)
    python re_tools\\asm.py backup.hex 0x1888 0x1a00      prints only that address range
"""
import argparse
import glob
import os
import re
import shutil
import subprocess
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import hexinfo  # noqa: E402

# ATmega328P registers by data-space address (lds/sts use these; in/out use address - 0x20)
REGS = {
    0x23: "PINB", 0x24: "DDRB", 0x25: "PORTB", 0x26: "PINC", 0x27: "DDRC", 0x28: "PORTC",
    0x29: "PIND", 0x2A: "DDRD", 0x2B: "PORTD", 0x35: "TIFR0", 0x36: "TIFR1", 0x37: "TIFR2",
    0x3B: "PCIFR", 0x3C: "EIFR", 0x3D: "EIMSK", 0x3E: "GPIOR0", 0x3F: "EECR", 0x40: "EEDR",
    0x41: "EEARL", 0x42: "EEARH", 0x43: "GTCCR", 0x44: "TCCR0A", 0x45: "TCCR0B", 0x46: "TCNT0",
    0x47: "OCR0A", 0x48: "OCR0B", 0x4C: "SPCR", 0x4D: "SPSR", 0x4E: "SPDR", 0x53: "SMCR",
    0x54: "MCUSR", 0x55: "MCUCR", 0x57: "SPMCSR", 0x5D: "SPL", 0x5E: "SPH", 0x5F: "SREG",
    0x60: "WDTCSR", 0x61: "CLKPR", 0x64: "PRR", 0x66: "OSCCAL", 0x68: "PCICR", 0x69: "EICRA",
    0x6B: "PCMSK0", 0x6C: "PCMSK1", 0x6D: "PCMSK2", 0x6E: "TIMSK0", 0x6F: "TIMSK1",
    0x70: "TIMSK2", 0x78: "ADCL", 0x79: "ADCH", 0x7A: "ADCSRA", 0x7B: "ADCSRB", 0x7C: "ADMUX",
    0x7E: "DIDR0", 0x7F: "DIDR1", 0x80: "TCCR1A", 0x81: "TCCR1B", 0x82: "TCCR1C",
    0x84: "TCNT1L", 0x85: "TCNT1H", 0x86: "ICR1L", 0x87: "ICR1H", 0x88: "OCR1AL", 0x89: "OCR1AH",
    0x8A: "OCR1BL", 0x8B: "OCR1BH", 0xB0: "TCCR2A", 0xB1: "TCCR2B", 0xB2: "TCNT2", 0xB3: "OCR2A",
    0xB4: "OCR2B", 0xB6: "ASSR", 0xB8: "TWBR", 0xB9: "TWSR", 0xBA: "TWAR", 0xBB: "TWDR",
    0xBC: "TWCR", 0xBD: "TWAMR", 0xC0: "UCSR0A", 0xC1: "UCSR0B", 0xC2: "UCSR0C",
    0xC4: "UBRR0L", 0xC5: "UBRR0H", 0xC6: "UDR0",
}
IO_INSNS = {"in", "out", "sbi", "cbi", "sbis", "sbic"}
BRANCHES = {"call", "jmp", "rcall", "rjmp", "brne", "breq", "brcs", "brcc", "brlo", "brsh",
            "brge", "brlt", "brmi", "brpl", "brts", "brtc", "brvs", "brvc", "brhs", "brhc", "brie", "brid"}
LINE = re.compile(r"^\s*([0-9a-f]+):\t([0-9a-f ]+)\t(\S+)\s*([^;]*?)\s*(?:;\s*(.*))?$")


def find_objdump():
    exe = shutil.which("avr-objdump")
    if exe:
        return exe
    pattern = os.path.join(os.environ.get("LOCALAPPDATA", ""), "Arduino15", "packages", "arduino",
                           "tools", "avr-gcc", "*", "bin", "avr-objdump.exe")
    found = sorted(glob.glob(pattern))
    if not found:
        sys.exit("avr-objdump not found. Install it with:  arduino-cli core install arduino:avr")
    return found[-1]


def load_names(path, mem, info):
    """Returns (code_names, ram_names)."""
    names, ram = {}, {}
    if "main" in info:
        names[info["main"]] = "main"
    for c in info.get("ctors", []):
        names[c] = "global_constructors"
    for i, (vname, _) in enumerate(hexinfo.VECTORS):
        t = hexinfo.decode_jmp_call(mem, i * 4)
        if t:
            names.setdefault(t[1], "RESET_startup" if i == 0 else f"ISR_{vname}")
    # the most common vector target is the unused-interrupt handler
    targets = [hexinfo.decode_jmp_call(mem, i * 4) for i in range(1, len(hexinfo.VECTORS))]
    targets = [t[1] for t in targets if t]
    if targets:
        names[max(set(targets), key=targets.count)] = "__bad_interrupt"
    if path and os.path.exists(path):
        for line in open(path):
            line = line.split("#")[0].strip()
            if not line:
                continue
            parts = line.split()
            if parts[0] == "ram":
                ram[int(parts[1], 16)] = parts[2]
            else:
                names[int(parts[0], 16)] = parts[1]
    return names, ram


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("hexfile")
    ap.add_argument("start", nargs="?", help="first address to show (hex)")
    ap.add_argument("end", nargs="?", help="stop before this address (hex)")
    ap.add_argument("--names", help="names file (default: <hexfile>.names.txt)")
    ap.add_argument("-o", "--out", help="output file for the full listing (default: <hexfile minus .hex>.asm)")
    args = ap.parse_args()

    mem = hexinfo.load_hex(args.hexfile)
    info = hexinfo.find_layout(mem)
    app_end = max(i for i in range(hexinfo.BOOTLOADER_START) if mem[i] != 0xFF)
    names, ram_names = load_names(args.names or args.hexfile + ".names.txt", mem, info)

    strings = {}
    for _, ram, text in hexinfo.find_strings(mem, info, app_end, min_len=1):
        if ram is not None:
            for off in range(len(text)):
                strings.setdefault(ram + off, text[off:])

    raw = subprocess.run([find_objdump(), "-D", "-m", "avr5", args.hexfile],
                         capture_output=True, text=True, check=True).stdout
    lo = int(args.start, 16) if args.start else 0
    hi = int(args.end, 16) if args.end else (info.get("data_flash", app_end + 1))

    out, prev_ldi = [], None
    for line in raw.splitlines():
        m = LINE.match(line)
        if not m:
            continue
        addr = int(m.group(1), 16)
        if not lo <= addr < hi:
            continue
        op, operands = m.group(3), m.group(4)
        notes = []

        if addr in names:
            out.append(f"\n; ===================== {names[addr]} =====================")

        if op in BRANCHES:
            t = re.search(r"0x([0-9a-f]+)", m.group(5) or operands)
            if t:
                target = int(t.group(1), 16)
                operands = f"0x{target:x}" + (f" <{names[target]}>" if target in names else "")
        elif op in ("lds", "sts"):
            t = re.search(r"0x([0-9a-fA-F]+)", operands)
            if t:
                a = int(t.group(1), 16)
                # multi-byte variables: also match the bytes after a named address
                base = max((b for b in ram_names if 0 <= a - b < 8), default=None)
                if a in REGS:
                    notes.append(REGS[a])
                elif base is not None:
                    notes.append(ram_names[base] + (f" +{a - base}" if a != base else ""))
        elif op in IO_INSNS:
            t = re.search(r"0x([0-9a-fA-F]+)", operands)
            if t and int(t.group(1), 16) + 0x20 in REGS:
                notes.append(REGS[int(t.group(1), 16) + 0x20])
        elif op == "ldi":
            reg, val = re.match(r"r(\d+), 0x([0-9A-Fa-f]+)", operands).groups()
            reg, val = int(reg), int(val, 16)
            notes.append(f"{val}" + (f" '{chr(val)}'" if 32 <= val < 127 else ""))
            if prev_ldi and prev_ldi[0] == reg - 1 and reg % 2 == 1:
                ptr = prev_ldi[1] | (val << 8)
                notes.append(f"pair r{reg - 1}:r{reg} = 0x{ptr:04X} = {ptr}")
                if ptr in strings:
                    notes.append(f'"{strings[ptr]}"')
            prev_ldi = (reg, val)
        if op != "ldi":
            prev_ldi = None

        text = f"{addr:6x}:  {m.group(2).strip():<12} {op:<6} {operands}"
        out.append(text + (f"   ; {'  '.join(notes)}" if notes else ""))

    if args.start:
        print("\n".join(out))
    else:
        dest = args.out or os.path.splitext(args.hexfile)[0] + ".asm"
        open(dest, "w").write("\n".join(out) + "\n")
        print(f"wrote {dest} ({len(out)} lines, {len(names)} named addresses)")


if __name__ == "__main__":
    main()
