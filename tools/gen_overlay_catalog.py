#!/usr/bin/env python3
"""Generate docs/12-overlay-catalog.md from ROM overlay table."""

from __future__ import annotations

from pathlib import Path
import struct
import sys

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from tools.scan_overlays import OVERLAY_NAMES, read_overlay_table, slug_for

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "docs" / "12-overlay-catalog.md"


def main() -> None:
    rom = (ROOT / "baserom.us.z64").read_bytes()
    overlays = read_overlay_table(rom)
    lines = [
        "# Overlay Catalog",
        "",
        "All dynamically loaded code modules discovered from the overlay dispatch table at ROM `0xC9474`.",
        "",
        "| ID | Name | ROM Start | ROM End | Size | VRAM Load |",
        "|----|------|-----------|---------|------|-----------|",
    ]
    for ovl in overlays:
        if ovl.index > 0x72:
            continue
        slug = slug_for(ovl.index)
        size = ovl.rom_end - ovl.rom_start
        lines.append(
            f"| `{ovl.index:02X}` | {slug} | `0x{ovl.rom_start:06X}` | `0x{ovl.rom_end:06X}` | `{size:X}` | `0x{ovl.vram_text:08X}` |"
        )
    lines.extend(["", f"Total overlays: **{min(len(overlays), 0x73)}**", ""])
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text("\n".join(lines))
    print(f"Wrote {OUT}")


if __name__ == "__main__":
    main()
