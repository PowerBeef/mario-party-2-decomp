#!/usr/bin/env python3
"""Decode N64 ADPCM audio banks from baserom asset region (stub WAV export)."""

from __future__ import annotations

import argparse
import struct
import wave
from pathlib import Path

ASSET_START = 0x418A50


def write_silent_wav(path: Path, seconds: float = 0.25, rate: int = 22050) -> None:
    n = int(rate * seconds)
    path.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(path), "w") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(rate)
        w.writeframes(b"\x00\x00" * n)


def scan_banks(rom: bytes) -> list[tuple[int, int]]:
    banks: list[tuple[int, int]] = []
    for off in range(ASSET_START, min(len(rom) - 4, ASSET_START + 0x200000), 4):
        if rom[off : off + 4] in (b"IMPC", b"IMPT", b"SEQ "):
            size = struct.unpack_from(">I", rom, off + 4)[0] if off + 8 < len(rom) else 4096
            size = min(max(size, 256), 512_000)
            banks.append((off, size))
            if len(banks) >= 128:
                break
    return banks


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--rom", type=Path, required=True)
    ap.add_argument("--out", type=Path, required=True)
    args = ap.parse_args()
    rom = args.rom.read_bytes()
    args.out.mkdir(parents=True, exist_ok=True)
    banks = scan_banks(rom)
    for i, (off, size) in enumerate(banks):
        raw = rom[off : off + size]
        (args.out / f"bank_{i:03d}.bin").write_bytes(raw)
        write_silent_wav(args.out / f"sfx_{i:03d}.wav")
    print(f"Exported {len(banks)} audio bank slices -> {args.out}")


if __name__ == "__main__":
    main()
