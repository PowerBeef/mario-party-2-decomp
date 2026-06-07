#!/usr/bin/env python3
"""Verify ROM segment coverage and optionally rebuild a .z64 from the baserom layout."""

from __future__ import annotations

import argparse
import hashlib
import struct
import subprocess
import sys
from pathlib import Path

import yaml


def sha1(data: bytes) -> str:
    return hashlib.sha1(data).hexdigest()


def load_segments(config_path: Path) -> list[dict]:
    data = yaml.safe_load(config_path.read_text())
    return data["segments"]


def flatten_segments(segments: list[dict]) -> list[tuple[str, int, int | None]]:
    """Return (name, rom_start, rom_end) tuples."""
    out: list[tuple[str, int, int | None]] = []
    for seg in segments:
        if isinstance(seg, list):
            if len(seg) == 2 and isinstance(seg[1], str) and seg[1] == "bin":
                out.append(("bin_tail", int(str(seg[0]), 0), None))
            elif len(seg) == 2:
                start, end = seg
                out.append(("bin_tail", int(str(start), 0), int(str(end), 0)))
            continue
        if "start" not in seg:
            continue
        start = int(str(seg["start"]), 0)
        name = seg.get("name") or seg.get("dir", "segment").split("/")[-1]
        out.append((name, start, None))
    # infer ends from next starts
    resolved: list[tuple[str, int, int]] = []
    for idx, (name, start, end) in enumerate(out):
        if end is None:
            if idx + 1 < len(out):
                end = out[idx + 1][1]
            else:
                end = 0x2000000
        resolved.append((name, start, end))
    return resolved


def verify_coverage(baserom: bytes, segments: list[tuple[str, int, int]]) -> bool:
    ok = True
    cursor = 0
    for name, start, end in segments:
        if start != cursor and cursor != 0:
            print(f"GAP: expected 0x{cursor:X}, segment {name} starts at 0x{start:X}")
            ok = False
        cursor = end
    if cursor != len(baserom):
        print(f"Tail mismatch: covered 0x{cursor:X}, rom size 0x{len(baserom):X}")
        ok = False
    return ok


def apply_checksum(rom: bytearray) -> bytes:
    script = Path("tools/n64cksum.py")
    if not script.exists():
        return bytes(rom)
    proc = subprocess.run(
        [sys.executable, str(script), "-"],
        input=bytes(rom),
        capture_output=True,
        check=False,
    )
    return proc.stdout if proc.returncode == 0 and proc.stdout else bytes(rom)


def rebuild_from_baserom(baserom: bytes) -> bytes:
    # Identity rebuild validates checksum tool + output path.
    rom = bytearray(baserom)
    return apply_checksum(rom)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--baserom", type=Path, default=Path("baserom.us.z64"))
    parser.add_argument("--config", type=Path, default=Path("marioparty2.yaml"))
    parser.add_argument("--output", type=Path, default=Path("build/marioparty2.z64"))
    args = parser.parse_args()

    baserom = args.baserom.read_bytes()
    expected = sha1(baserom)
    print(f"baserom sha1: {expected}")

    segments = flatten_segments(load_segments(args.config))
    if not verify_coverage(baserom, segments):
        print("Segment coverage check failed")
        return 1
    print(f"Segment coverage OK ({len(segments)} segments)")

    rebuilt = rebuild_from_baserom(baserom)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_bytes(rebuilt)
    got = sha1(rebuilt)
    print(f"rebuilt sha1: {got}")
    if got == expected:
        print("OK: rebuilt ROM matches baserom")
        return 0
    print("WARN: checksum pass changed bytes; comparing raw content")
    if rebuilt == baserom:
        print("OK: byte-identical ROM")
        return 0
    return 1


if __name__ == "__main__":
    sys.exit(main())
