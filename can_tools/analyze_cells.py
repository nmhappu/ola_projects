"""Look for individual cell voltages in a CAN log from the Ola S1 X.

Reads logs from the BMS Remote app's CAN monitor export, or from the older
archive/can_sniffer/can_sniffer.ino (Serial Monitor output). Both use one line per frame, tab or space separated:

    time_ms  id  dlc  data bytes (hex)  [TX]

Lines starting with '#' are comments; "# mark <time_ms> <label>" lines are
markers added while recording. "TX" marks a frame the BMS Tool itself sent.

What it reports:
  1. Every CAN ID: frame count, rate, length and which bytes change.
  2. 16-bit fields that look like cell voltages (2.0-4.4 V, in mV or 0.1 mV,
     either byte order), including multiplexed frames where byte 0 is an index.
  3. Whether those fields add up to the pack voltage (CAN 0x1A8, bytes 4-5).
  4. IDs that first appear right after a marker or a TX frame (replies).

Usage:
    python analyze_cells.py capture.tsv
    python analyze_cells.py capture.tsv --csv cells.csv   # values over time, for plotting
"""

import argparse
import collections
import csv
import statistics
import sys
from dataclasses import dataclass, field

PACK_ID = 0x1A8         # pack voltage frame found in the original firmware
PACK_OFFSET = 4         # bytes 4-5, little-endian, millivolts
EXPECTED_CELLS = 14     # 14 series groups in the S1 X / S1 Pro pack

SCALES = {              # name: (factor to volts, min raw, max raw)
    "mV": (0.001, 2000, 4400),
    "0.1mV": (0.0001, 20000, 44000),
}
IN_RANGE_SHARE = 0.98   # share of samples that must look like a cell voltage
REPLY_WINDOW_MS = 2000  # "reply" = ID first seen within this long after an event


@dataclass
class Frame:
    t: int
    can_id: int
    extended: bool
    data: bytes
    tx: bool = False


@dataclass
class Event:
    t: int
    label: str


def is_time(text):
    """Times are whole milliseconds (older logs) or milliseconds with decimals (newer app)."""
    whole, _, frac = text.partition(".")
    return whole.isdigit() and (frac == "" or frac.isdigit())


def parse_log(path):
    frames, events = [], []
    with open(path, encoding="utf-8", errors="replace") as f:
        for line_no, raw in enumerate(f, 1):
            line = raw.strip()
            if not line:
                continue
            if line.startswith("#"):
                parts = line[1:].split(None, 2)
                if len(parts) >= 2 and parts[0] == "mark" and is_time(parts[1]):
                    events.append(Event(float(parts[1]), parts[2] if len(parts) > 2 else "mark"))
                continue
            tokens = line.split()
            if len(tokens) < 3 or not is_time(tokens[0]):
                continue  # anything else the Serial Monitor printed
            tx = tokens[-1] == "TX"
            if tx:
                tokens = tokens[:-1]
            if tokens[-1] == "RTR":
                continue
            try:
                t = float(tokens[0])
                id_text = tokens[1]
                extended = id_text.startswith("x")
                can_id = int(id_text.lstrip("x"), 16)
                dlc = int(tokens[2])
                data = bytes(int(b, 16) for b in tokens[3:3 + dlc])
            except ValueError:
                print(f"line {line_no}: could not read, skipped: {line[:60]}", file=sys.stderr)
                continue
            frame = Frame(t, can_id, extended, data, tx)
            frames.append(frame)
            if tx:
                events.append(Event(t, f"TX {id_label(frame)}"))
    frames.sort(key=lambda fr: fr.t)
    events.sort(key=lambda e: e.t)
    return frames, events


def id_label(frame_or_id, extended=False):
    if isinstance(frame_or_id, Frame):
        frame_or_id, extended = frame_or_id.can_id, frame_or_id.extended
    return f"x{frame_or_id:08X}" if extended else f"{frame_or_id:03X}"


@dataclass
class Field:
    """A 16-bit value inside a frame. mux = required value of byte 0, or None."""
    can_id: int
    extended: bool
    mux: object
    offset: int
    big_endian: bool
    scale: str
    samples: list = field(default_factory=list)  # (t, volts)

    @property
    def name(self):
        mux = f"[b0={self.mux:02X}]" if self.mux is not None else ""
        order = "BE" if self.big_endian else "LE"
        return f"{id_label(self.can_id, self.extended)}{mux} b{self.offset}-{self.offset + 1} {order} {self.scale}"

    @property
    def constant(self):
        return len({v for _, v in self.samples}) == 1


def read16(data, offset, big_endian):
    hi, lo = (data[offset], data[offset + 1]) if big_endian else (data[offset + 1], data[offset])
    return (hi << 8) | lo


def find_cell_fields(frames):
    by_id = collections.defaultdict(list)
    for fr in frames:
        if not fr.tx:
            by_id[(fr.can_id, fr.extended)].append(fr)

    found = []
    for (can_id, extended), group in by_id.items():
        if can_id == PACK_ID and not extended:
            continue
        # A frame whose byte 0 is a small index (0-15) taking a few values is probably
        # multiplexed: e.g. byte 0 = 0,1,2,3 and each carries 3 cells in bytes 1-6.
        # (A data byte that merely toggles, like the low byte of a cell voltage, is not.)
        first_bytes = {fr.data[0] for fr in group if fr.data}
        looks_like_index = 2 <= len(first_bytes) <= 8 and max(first_bytes) < 16
        mux_values = sorted(first_bytes) if looks_like_index and len(group) >= 4 * len(first_bytes) else []
        layouts = [(None, group, 0)] + [
            (m, [fr for fr in group if fr.data and fr.data[0] == m], 1) for m in mux_values
        ]
        for mux, frames_in, first_offset in layouts:
            if len(frames_in) < 3:
                continue
            length = min(len(fr.data) for fr in frames_in)
            for offset in range(first_offset, length - 1):
                for big_endian in (False, True):
                    raws = [read16(fr.data, offset, big_endian) for fr in frames_in]
                    for scale, (factor, lo, hi) in SCALES.items():
                        share = sum(lo <= r <= hi for r in raws) / len(raws)
                        if share >= IN_RANGE_SHARE:
                            f = Field(can_id, extended, mux, offset, big_endian, scale)
                            f.samples = [(fr.t, r * factor) for fr, r in zip(frames_in, raws) if lo <= r <= hi]
                            found.append(f)
    return pick_non_overlapping(found)


def pick_non_overlapping(fields):
    """Bytes can only belong to one field: prefer aligned, little-endian, varying fields."""
    def preference(f):
        return (f.constant, f.offset % 2 != (1 if f.mux is not None else 0), f.big_endian, f.scale != "mV")

    # An ID that decodes as multiplexed is read only that way.
    multiplexed = {(f.can_id, f.extended) for f in fields if f.mux is not None}
    taken, chosen = set(), []
    for f in sorted(fields, key=preference):
        if f.mux is None and (f.can_id, f.extended) in multiplexed:
            continue
        key = (f.can_id, f.extended, f.mux)
        span = {(key, f.offset), (key, f.offset + 1)}
        if span & taken:
            continue
        taken |= span
        chosen.append(f)
    chosen.sort(key=lambda f: (f.can_id, f.mux if f.mux is not None else -1, f.offset))
    return chosen


def pack_samples(frames):
    out = []
    for fr in frames:
        if fr.can_id == PACK_ID and not fr.extended and len(fr.data) >= PACK_OFFSET + 2 and not fr.tx:
            out.append((fr.t, read16(fr.data, PACK_OFFSET, False) / 1000))
    return out


def value_at(samples, t):
    """Latest sample at or before t (samples are sorted by time)."""
    lo, hi, best = 0, len(samples) - 1, None
    while lo <= hi:
        mid = (lo + hi) // 2
        if samples[mid][0] <= t:
            best = samples[mid][1]
            lo = mid + 1
        else:
            hi = mid - 1
    return best


def print_id_summary(frames):
    print("\n== CAN IDs ==")
    if not frames:
        print("No frames in the log.")
        return
    duration = max((frames[-1].t - frames[0].t) / 1000, 0.001)
    groups = collections.defaultdict(list)
    for fr in frames:
        groups[(fr.can_id, fr.extended, fr.tx)].append(fr)
    print(f"{len(frames)} frames over {duration:.1f} s, {len(groups)} distinct IDs\n")
    print(f"{'ID':>9}  {'frames':>7}  {'Hz':>6}  {'len':>3}  bytes that change   last data")
    for (can_id, extended, tx), group in sorted(groups.items()):
        length = max(len(fr.data) for fr in group)
        changing = [i for i in range(length) if len({fr.data[i] for fr in group if len(fr.data) > i}) > 1]
        label = id_label(can_id, extended) + (" TX" if tx else "")
        last = " ".join(f"{b:02X}" for b in group[-1].data)
        print(f"{label:>9}  {len(group):>7}  {len(group) / duration:>6.1f}  {length:>3}  "
              f"{','.join(map(str, changing)) or '-':<18} {last}")


def print_cells(cells, pack):
    print("\n== Fields that look like cell voltages ==")
    if not cells:
        print("None found. No 16-bit field stays within 2.0-4.4 V across the log.")
        print("The BMS may only send cell voltages when asked (a diagnostic request), or")
        print("use an encoding this script does not try (8-bit offsets, 12-bit packing).")
        return
    for i, f in enumerate(cells, 1):
        volts = [v for _, v in f.samples]
        note = "  (constant, could be a setting rather than a cell)" if f.constant else ""
        print(f"{i:>3}. {f.name:<34} {min(volts):.3f}-{max(volts):.3f} V, "
              f"{len(volts)} samples{note}")

    varying = [f for f in cells if not f.constant]
    print(f"\n{len(cells)} candidate fields ({len(varying)} changing). "
          f"The S1 pack has {EXPECTED_CELLS} cell groups in series.")

    if not pack:
        print(f"No pack voltage frames (ID {PACK_ID:03X}) in the log, so the sum cannot be checked.")
        return
    # Constant fields are often settings or reply codes, so also try without them.
    options = [("all candidates", cells)]
    if varying and len(varying) < len(cells):
        options.append(("changing candidates only", varying))
    results = [(label, chosen, *sum_vs_pack(chosen, pack)) for label, chosen in options]
    results = [r for r in results if r[2] is not None]
    if not results:
        print("Pack voltage and candidate fields never overlap in time; sum not checked.")
        return
    label, chosen, diff, avg_sum, avg_pack, n = min(results, key=lambda r: abs(r[2]))
    print(f"Sum of {label} ({len(chosen)}): {avg_sum:.2f} V vs pack {avg_pack:.2f} V "
          f"(difference {diff:+.2f} V, {n} comparisons).")
    if abs(diff) <= 0.5 and len(chosen) == EXPECTED_CELLS:
        print("=> Strong match: these look like the 14 cell-group voltages.")
    elif abs(diff) <= 0.5:
        print("=> The sum matches the pack voltage, but the field count is not 14; check the list above.")
    else:
        avg_cell = avg_pack / EXPECTED_CELLS
        print(f"=> No match. Average cell would be {avg_cell:.3f} V; some candidates may be other data.")


def sum_vs_pack(fields, pack):
    """Average (sum of fields - pack voltage) over the times both are known."""
    checks = []
    for t, pack_v in pack:
        values = [value_at(f.samples, t) for f in fields]
        if all(v is not None for v in values):
            checks.append((pack_v, sum(values)))
    if not checks:
        return None, None, None, 0
    avg_pack = sum(p for p, _ in checks) / len(checks)
    avg_sum = sum(s for _, s in checks) / len(checks)
    return avg_sum - avg_pack, avg_sum, avg_pack, len(checks)


def find_cell_frames(cells):
    """Frames carrying 2+ millivolt fields within 100 mV of each other: cells sit close
    together even when nothing changes, unlike unrelated data that merely falls in range."""
    by_frame = collections.defaultdict(list)
    for f in cells:
        if f.scale == "mV":
            by_frame[(f.can_id, f.extended, f.mux)].append(f)
    groups = []
    for key, fields in by_frame.items():
        medians = [statistics.median(v for _, v in f.samples) for f in fields]
        if len(fields) >= 2 and max(medians) - min(medians) <= 0.1:
            groups.append((key, sorted(fields, key=lambda f: f.offset), medians))
    if not groups:
        return []
    # Keep frames whose values sit near the common level (a pack's cells are within ~0.2 V).
    level = statistics.median(m for _, _, ms in groups for m in ms)
    groups = [g for g in groups if all(abs(m - level) <= 0.2 for m in g[2])]
    # A 2-value frame equal to the lowest and highest of the other cells is a min/max summary.
    def is_summary(g):
        others = [m for h in groups if h is not g for m in h[2]]
        return (len(g[2]) == 2 and others
                and abs(min(g[2]) - min(others)) <= 0.002 and abs(max(g[2]) - max(others)) <= 0.002)
    return sorted((g for g in groups if not is_summary(g)), key=lambda g: g[0][0])


def print_cell_frames(groups, pack):
    print("\n== Frames that each carry several near-identical voltages (likely cells) ==")
    if not groups:
        print("None found.")
        return
    values = []
    for (can_id, extended, mux), fields, medians in groups:
        label = id_label(can_id, extended) + (f"[b0={mux:02X}]" if mux is not None else "")
        order = "BE" if fields[0].big_endian else "LE"
        print(f"  {label:<12} {order} mV  " + "  ".join(f"{m * 1000:.0f}" for m in medians))
        values += medians
    total, avg = sum(values), sum(values) / len(values)
    print(f"\n{len(values)} cell-like values from {len(groups)} frames, "
          f"{min(values):.3f}-{max(values):.3f} V, sum {total:.2f} V, average {avg:.3f} V.")
    if pack:
        pack_v = statistics.median(v for _, v in pack)
        series = pack_v / avg
        print(f"Pack {pack_v:.2f} V / average cell = {series:.2f}, so the pack looks like "
              f"{round(series)} cells in series.")
        if round(series) != len(values):
            print(f"=> {len(values)} values but ~{round(series)} cells: one or more of these values "
                  f"may be something else (a min/max/average), or the pack frame may measure elsewhere.")
        else:
            print("=> Count matches: these look like the individual cell-group voltages.")


def print_replies(frames, events):
    if not events:
        return
    print("\n== IDs that first appear right after a marker or TX ==")
    first_seen = {}
    for fr in frames:
        key = (fr.can_id, fr.extended)
        if not fr.tx and key not in first_seen:
            first_seen[key] = fr.t
    for ev in events:
        new = [id_label(cid, ext) for (cid, ext), t in sorted(first_seen.items(), key=lambda kv: kv[1])
               if ev.t <= t <= ev.t + REPLY_WINDOW_MS]
        print(f"{ev.t:>10} ms  {ev.label:<28} new IDs: {', '.join(new) if new else 'none'}")


def write_csv(path, cells, pack):
    times = sorted({t for f in cells for t, _ in f.samples} | {t for t, _ in pack})
    with open(path, "w", newline="") as out:
        w = csv.writer(out)
        w.writerow(["time_ms", "pack_V"] + [f.name for f in cells])
        for t in times:
            pv = value_at(pack, t)
            w.writerow([t, "" if pv is None else f"{pv:.3f}"] +
                       [("" if (v := value_at(f.samples, t)) is None else f"{v:.4f}") for f in cells])
    print(f"\nWrote {len(times)} rows to {path}")


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("log", help="CAN log from can_sniffer.ino or the BMS Remote app")
    ap.add_argument("--csv", help="also write candidate cell values over time to this CSV file")
    args = ap.parse_args()

    frames, events = parse_log(args.log)
    print(f"Read {len(frames)} frames and {len(events)} markers/TX events from {args.log}")
    print_id_summary(frames)
    pack = pack_samples(frames)
    if pack:
        print(f"\nPack voltage (ID {PACK_ID:03X}): {min(v for _, v in pack):.2f}-{max(v for _, v in pack):.2f} V")
    cells = find_cell_fields(frames)
    print_cells(cells, pack)
    print_cell_frames(find_cell_frames(cells), pack)
    print_replies(frames, events)
    if args.csv and cells:
        write_csv(args.csv, cells, pack)


if __name__ == "__main__":
    main()
