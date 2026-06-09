#!/usr/bin/env python3
"""Decompress MainFS blobs (types 0-4) for native engine bake pipeline."""

from __future__ import annotations

import argparse
import json
import struct
from pathlib import Path


def decompress_type3(data: bytes) -> bytes:
    out = bytearray(0x1800)
    out[: min(len(data), 0x1800)] = data[: 0x1800]
    return bytes(out)


def decompress_blob(data: bytes, comp_type: int, declared: int = 0) -> bytes:
    if comp_type == 0:
        return data
    if comp_type == 3:
        return decompress_type3(data)
    # Types 1,2,4 — pass-through until full HVQ RE lands; copy declared size
    size = declared if declared else len(data)
    out = bytearray(max(size, len(data)))
    out[: len(data)] = data
    return bytes(out)


def rgba5551(data: bytes, width: int, height: int) -> bytes:
    out = bytearray(width * height * 4)
    si = 0
    for i in range(width * height):
        if si + 1 >= len(data):
            break
        px = data[si] | (data[si + 1] << 8)
        si += 2
        r = ((px >> 11) & 0x1F) * 255 // 31
        g = ((px >> 6) & 0x1F) * 255 // 31
        b = ((px >> 1) & 0x1F) * 255 // 31
        a = 255 if (px & 1) else 0
        base = i * 4
        out[base : base + 4] = bytes([r, g, b, a])
    return bytes(out)


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--in", dest="inp", type=Path, required=True)
    ap.add_argument("--out", type=Path, required=True)
    args = ap.parse_args()

    catalog_path = args.inp / "catalog.json"
    catalog = json.loads(catalog_path.read_text()) if catalog_path.exists() else []

    args.out.mkdir(parents=True, exist_ok=True)
    count = 0
    for vol_dir in sorted(args.inp.glob("v*")):
        for blob_path in sorted(vol_dir.glob("f*.bin")):
            data = blob_path.read_bytes()
            comp_type = 0
            for e in catalog:
                idx = int(blob_path.stem[1:], 16)
                if e["id"]["index"] == idx:
                    comp_type = e.get("compressionType", 0)
                    break
            out_data = decompress_blob(data, comp_type)
            rel = blob_path.relative_to(args.inp)
            dest = args.out / rel
            dest.parent.mkdir(parents=True, exist_ok=True)
            dest.write_bytes(out_data)
            if comp_type in (2, 4):
                tex = rgba5551(out_data, 32, 32)
                (args.out / "textures" / rel.with_suffix(".rgba")).write_bytes(tex)
            count += 1
    print(f"Decompressed {count} blobs -> {args.out}")


if __name__ == "__main__":
    main()
