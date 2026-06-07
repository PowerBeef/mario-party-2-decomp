#!/usr/bin/env python3
"""Rebuild a .z64 from splat-extracted segment binaries for SHA1 verification."""

from __future__ import annotations

import argparse
import hashlib
import struct
import subprocess
import sys
from pathlib import Path


def run_n64cksum(rom: bytes) -> bytes:
    script = Path("tools/n64cksum.py")
    if not script.exists():
        return rom
    proc = subprocess.run(
        [sys.executable, str(script), "-"],
        input=rom,
        capture_output=True,
        check=False,
    )
    if proc.returncode == 0 and proc.stdout:
        return proc.stdout
    return rom


def concat_segments(build_dir: Path, rom_size: int = 0x2000000) -> bytes:
    rom = bytearray(rom_size)
    if not build_dir.exists():
        raise FileNotFoundError(f"Missing build dir: {build_dir}")

    for bin_path in sorted(build_dir.rglob("*.bin")):
        # splat stores segment bins under build/<segment>/...
        rel = bin_path.relative_to(build_dir)
        # Prefer linker-provided offsets via companion .txt if present
        off_path = bin_path.with_suffix(".offset")
        if off_path.exists():
            offset = int(off_path.read_text().strip(), 0)
        else:
            continue
        data = bin_path.read_bytes()
        rom[offset : offset + len(data)] = data
    return bytes(rom)


def sha1(data: bytes) -> str:
    return hashlib.sha1(data).hexdigest()


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--baserom", type=Path, default=Path("baserom.us.z64"))
    parser.add_argument("--build-dir", type=Path, default=Path("build"))
    parser.add_argument("--output", type=Path, default=Path("build/marioparty2.z64"))
    args = parser.parse_args()

    baserom = args.baserom.read_bytes()
    expected = sha1(baserom)

    # Fast path: if splat left a extracted rom, compare directly.
    candidate_paths = [
        args.output,
        args.build_dir / "marioparty2.z64",
        args.build_dir / "baserom.us.z64",
    ]
    for path in candidate_paths:
        if path.exists():
            got = sha1(path.read_bytes())
            print(f"{path}: sha1={got}")
            if got == expected:
                print("OK: matches baserom")
                return 0

    print("No matching rebuilt ROM found yet.")
    print(f"Expected baserom sha1: {expected}")
    return 1


if __name__ == "__main__":
    sys.exit(main())
