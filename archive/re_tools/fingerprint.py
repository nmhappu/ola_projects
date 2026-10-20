"""Step 4 shortcut - Name library functions automatically ("signature matching").

When you compile a sketch, arduino-cli also writes a .elf file that still
contains every function name. Compile ANY sketch that uses the same libraries
as the mystery firmware (a library's example sketch is fine), then let this
script find those functions inside the mystery .hex by their instruction pattern.

Usage (target first, then one or more .elf files):
    arduino-cli compile -b arduino:avr:uno --output-dir build\\ex_can  <library example folder>
    python re_tools\\fingerprint.py backup.hex build\\ex_can\\CAN_read.ino.elf build\\ex_lcd\\HelloWorld.pde.elf
    python re_tools\\fingerprint.py backup.hex build\\ex_can\\CAN_read.ino.elf >> backup.hex.names.txt

Note: matching ignores constants, so one result line per address is kept
(first .elf wins). Sketch-specific functions won't match - those are yours to name.

Only functions that match exactly once (after ignoring constants/addresses)
and are at least --min instructions long are printed, so a match is reliable.
"""
import argparse
import os
import re
import subprocess
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import asm      # noqa: E402
import hexinfo  # noqa: E402


def norm(op, operands):
    s = f"{op} {operands}"
    s = re.sub(r"0x[0-9a-fA-F]+", "N", s)
    s = re.sub(r"\.[+-]\d+", "R", s)
    return re.sub(r"\s+", " ", s).strip()


def disasm(args):
    raw = subprocess.run([asm.find_objdump()] + args, capture_output=True, text=True, check=True).stdout
    out = []
    for line in raw.splitlines():
        m = asm.LINE.match(line)
        if m:
            out.append((int(m.group(1), 16), norm(m.group(3), m.group(4))))
    return out


def symbols(elf):
    nm = os.path.join(os.path.dirname(asm.find_objdump()), "avr-nm")
    raw = subprocess.run([nm, "-S", "-C", "--defined-only", elf], capture_output=True, text=True, check=True).stdout
    for line in raw.splitlines():
        parts = line.split(None, 3)
        if len(parts) == 4 and parts[2].lower() in ("t", "w"):
            yield int(parts[0], 16), int(parts[1], 16), parts[3]


def clean(name):
    """'LiquidCrystal_I2C::setCursor(unsigned char, ...) [clone .constprop.4]' -> 'LiquidCrystal_I2C_setCursor'"""
    return re.sub(r"\W+", "_", name.split("(")[0].split(" [")[0].replace("::", "_")).strip("_")


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("target_hex", help="the mystery firmware")
    ap.add_argument("known_elf", nargs="+", help=".elf file(s) compiled from sketches with the same libraries")
    ap.add_argument("--min", type=int, default=8, help="minimum function length in instructions (default 8)")
    args = ap.parse_args()

    target = disasm(["-D", "-m", "avr5", args.target_hex])
    # one long string of instructions, so a function can be found with str.find
    t_text = "".join(i + "\n" for _, i in target)
    t_offsets, pos = [], 0
    for _, i in target:
        t_offsets.append(pos)
        pos += len(i) + 1
    offset_to_addr = {o: a for o, (a, _) in zip(t_offsets, target)}

    names = {}
    for elf in args.known_elf:
        if not os.path.exists(elf):
            sys.exit(f"not found: {elf}")
        known = disasm(["-d", elf])
        for addr, size, name in sorted(symbols(elf)):
            body = [i for a, i in known if addr <= a < addr + size]
            if len(body) < args.min:
                continue
            needle = "".join(i + "\n" for i in body)
            first = t_text.find(needle)
            if first < 0 or t_text.find(needle, first + 1) >= 0 or first not in offset_to_addr:
                continue                    # not found, or ambiguous
            names.setdefault(offset_to_addr[first], (clean(name), len(body), os.path.basename(elf)))

    print("# --- matched by fingerprint.py ---")
    for addr, (name, n, src) in sorted(names.items()):
        print(f"0x{addr:04x}  {name:<40} # {n} insns, from {src}")
    print(f"# {len(names)} functions matched", file=sys.stderr)


if __name__ == "__main__":
    main()
