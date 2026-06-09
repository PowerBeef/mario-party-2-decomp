#!/usr/bin/env python3
"""Extract MainFS asset blobs from Mario Party 2 baserom."""

from __future__ import annotations

import argparse
import hashlib
import json
import struct
from pathlib import Path

ASSET_START = 0x418A50
EXPECTED_SHA1 = "166eda1c05670d337e2c3f15a5db528ae1e5d6e3"


def sha1(path: Path) -> str:
    h = hashlib.sha1()
    with path.open("rb") as f:
        while chunk := f.read(1 << 20):
            h.update(chunk)
    return h.hexdigest()


def scan_asset_chunks(rom: bytes) -> list[dict]:
    """Heuristic scan: 16-byte aligned chunks with size headers in asset tail."""
    entries: list[dict] = []
    offset = ASSET_START
    index = 0
    while offset + 16 < len(rom) and index < 4096:
        size = struct.unpack_from(">I", rom, offset)[0]
        if size < 16 or size > 2_000_000 or offset + size > len(rom):
            offset += 16
            continue
        entries.append(
            {
                "id": {"volume": 0, "index": index},
                "romStart": offset,
                "romEnd": offset + size,
                "compressionType": rom[offset + 4] if size > 4 else 0,
            }
        )
        index += 1
        offset += size
        if index > 512:
            break
    return entries


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--rom", type=Path, required=True)
    ap.add_argument("--out", type=Path, required=True)
    args = ap.parse_args()

    digest = sha1(args.rom)
    if digest != EXPECTED_SHA1:
        print(f"warning: SHA1 {digest} != expected retail hash")

    rom = args.rom.read_bytes()
    args.out.mkdir(parents=True, exist_ok=True)

    entries = scan_asset_chunks(rom)
    for e in entries:
        vol = e["id"]["volume"]
        idx = e["id"]["index"]
        sub = args.out / f"v{vol:02X}"
        sub.mkdir(parents=True, exist_ok=True)
        blob = rom[e["romStart"] : e["romEnd"]]
        (sub / f"f{idx:04X}.bin").write_bytes(blob)

    (args.out / "catalog.json").write_text(json.dumps(entries, indent=2))
    print(f"Wrote {len(entries)} entries to {args.out}")


if __name__ == "__main__":
    main()
