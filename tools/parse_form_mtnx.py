#!/usr/bin/env python3
"""Parse FORM/MTNX containers into mesh JSON for Metal bake."""

from __future__ import annotations

import argparse
import json
import struct
from pathlib import Path


def parse_form(data: bytes) -> dict | None:
    if len(data) < 12 or data[:4] != b"FORM":
        return None
    chunks = []
    offset = 0x0C
    count = data[5]
    for _ in range(min(count, 64)):
        if offset + 8 > len(data):
            break
        tag = data[offset : offset + 4].decode("ascii", errors="replace")
        size = struct.unpack_from(">I", data, offset + 4)[0]
        offset += 8
        payload = data[offset : offset + size]
        offset += (size + 3) & ~3
        chunks.append({"tag": tag, "size": size, "data": payload.hex()})
    return {"magic": "FORM", "chunks": chunks}


def mesh_from_form(data: bytes) -> dict | None:
    if data[:4] != b"FORM":
        return None
    vtx = fac = None
    offset = 0x0C
    count = data[5]
    for _ in range(min(count, 64)):
        if offset + 8 > len(data):
            break
        tag = data[offset : offset + 4]
        size = struct.unpack_from(">I", data, offset + 4)[0]
        offset += 8
        payload = data[offset : offset + size]
        offset += (size + 3) & ~3
        if tag == b"VTX1":
            vtx = payload
        elif tag == b"FAC1":
            fac = payload
    if not vtx or not fac:
        return None
    vertices = []
    for i in range(0, len(vtx) - 11, 12):
        x, y, z = struct.unpack_from(">fff", vtx, i)
        vertices.append([x, y, z])
    indices = list(struct.unpack_from(f">{len(fac)//2}H", fac)) if len(fac) >= 2 else []
    return {"vertices": vertices, "indices": indices}


def parse_mtnx(data: bytes) -> list[list[list[float]]]:
    matrices = []
    for off in range(0, len(data) - 63, 64):
        m = []
        for row in range(4):
            m.append(list(struct.unpack_from(">4f", data, off + row * 16)))
        matrices.append(m)
    return matrices


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--in", dest="inp", type=Path, required=True)
    ap.add_argument("--out", type=Path, required=True)
    args = ap.parse_args()
    args.out.mkdir(parents=True, exist_ok=True)
    n = 0
    for blob in args.inp.rglob("f*.bin"):
        data = blob.read_bytes()
        if data[:4] == b"FORM":
            mesh = mesh_from_form(data)
            if mesh:
                rel = blob.relative_to(args.inp)
                (args.out / rel.with_suffix(".mesh.json")).write_text(json.dumps(mesh, indent=2))
                n += 1
        elif data[:4] == b"MTNX":
            mats = parse_mtnx(data[8:])
            rel = blob.relative_to(args.inp)
            (args.out / rel.with_suffix(".mtnx.json")).write_text(json.dumps(mats, indent=2))
            n += 1
    print(f"Parsed {n} FORM/MTNX files -> {args.out}")


if __name__ == "__main__":
    main()
