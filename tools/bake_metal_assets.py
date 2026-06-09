#!/usr/bin/env python3
"""Bake decompressed assets into MP2 native .mp2cache/baked format."""

from __future__ import annotations

import argparse
import json
import struct
from pathlib import Path


def pack_mesh(vertices: list, indices: list) -> bytes:
    buf = bytearray()
    buf += struct.pack("<II", len(vertices), len(indices))
    for x, y, z in vertices:
        buf += struct.pack("<fff", float(x), float(y), float(z))
    for idx in indices:
        buf += struct.pack("<I", int(idx))
    return bytes(buf)


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--in", dest="inp", type=Path, required=True)
    ap.add_argument("--out", type=Path, required=True)
    args = ap.parse_args()
    args.out.mkdir(parents=True, exist_ok=True)

    catalog_src = args.inp / "catalog.json"
    if catalog_src.exists():
        (args.out / "catalog.json").write_bytes(catalog_src.read_bytes())

    mesh_dir = args.inp / "meshes"
    if mesh_dir.is_dir():
        for mesh_json in mesh_dir.rglob("*.mesh.json"):
            mesh = json.loads(mesh_json.read_text())
            packed = pack_mesh(mesh.get("vertices", []), mesh.get("indices", []))
            (args.out / "debug_mesh.bin").write_bytes(packed)
            break

    # Default debug triangle if no mesh
    if not (args.out / "debug_mesh.bin").exists():
        packed = pack_mesh(
            [[-1, -1, 0], [1, -1, 0], [0, 1, 0]],
            [0, 1, 2],
        )
        (args.out / "debug_mesh.bin").write_bytes(packed)

    tex_dir = args.inp / "textures"
    if tex_dir.is_dir():
        for rgba in tex_dir.rglob("*.rgba"):
            (args.out / "title_bg.rgba").write_bytes(rgba.read_bytes())
            break

    print(f"Baked cache -> {args.out}")


if __name__ == "__main__":
    main()
