"""Step 7 - Check a rebuilt sketch against the original firmware.

Compile your reconstruction first:
    arduino-cli compile -b arduino:avr:uno --output-dir build backup_reconstructed

then compare:
    python re_tools\\compare.py backup.hex build\\backup_reconstructed.ino.hex

Addresses are replaced with "N" before comparing, because if one function grows
by 2 bytes, every address after it shifts - that is noise, not a real difference.
Two checks are made:
  1. order-independent: are the same instructions present at all?  (the linker
     may place functions in a different order; that's harmless)
  2. in-order diff: shows where the instruction sequences differ.
"""
import argparse
import collections
import difflib
import os
import re
import subprocess
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import asm      # noqa: E402
import hexinfo  # noqa: E402


def code_lines(path):
    mem = hexinfo.load_hex(path)
    info = hexinfo.find_layout(mem)
    end = info.get("data_flash") or max(i for i in range(hexinfo.BOOTLOADER_START) if mem[i] != 0xFF)
    raw = subprocess.run([asm.find_objdump(), "-D", "-m", "avr5", path],
                         capture_output=True, text=True, check=True).stdout
    lines = []
    for line in raw.splitlines():
        m = asm.LINE.match(line)
        if m and int(m.group(1), 16) < end:
            insn = f"{m.group(3)} {m.group(4)}"
            insn = re.sub(r"0x[0-9a-fA-F]+", "N", insn)        # absolute addresses / constants
            insn = re.sub(r"\.[+-]\d+", "R", insn)             # relative jumps
            lines.append(re.sub(r"\s+", " ", insn).strip())
    data = info.get("data_ram_end", 0) - info.get("data_ram_start", 0)
    return lines, end + data


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("original")
    ap.add_argument("rebuilt")
    ap.add_argument("-n", type=int, default=40, help="max diff lines to show (default 40)")
    args = ap.parse_args()

    a, size_a = code_lines(args.original)
    b, size_b = code_lines(args.rebuilt)
    print(f"original: {size_a} bytes, {len(a)} instructions")
    print(f"rebuilt : {size_b} bytes, {len(b)} instructions   (difference {size_b - size_a:+d} bytes)")

    ca, cb = collections.Counter(a), collections.Counter(b)
    only_a, only_b = ca - cb, cb - ca
    print(f"\n1) instructions only in original: {sum(only_a.values())}, only in rebuilt: {sum(only_b.values())}")
    if not only_a and not only_b:
        print("   -> identical instruction set; any differences are just function order. Match!")
    for insn, n in only_a.most_common(15):
        print(f"   - {n}x {insn}")
    for insn, n in only_b.most_common(15):
        print(f"   + {n}x {insn}")

    print("\n2) in-order diff (- original, + rebuilt), with original instruction index:")
    shown = 0
    for tag, i1, i2, j1, j2 in difflib.SequenceMatcher(None, a, b, autojunk=False).get_opcodes():
        if tag == "equal":
            continue
        print(f"   @ instruction {i1}: {tag} {i2 - i1} -> {j2 - j1}")
        for x in a[i1:i2][:6]:
            print(f"     - {x}")
        for x in b[j1:j2][:6]:
            print(f"     + {x}")
        shown += 1
        if shown >= args.n:
            print("   ... (use -n to show more)")
            break
    if shown == 0:
        print("   identical, instruction for instruction")


if __name__ == "__main__":
    main()
