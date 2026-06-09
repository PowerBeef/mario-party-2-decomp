#!/usr/bin/env python3
"""Overlay port checklist from overlay_xref.py output + registry coverage."""

from __future__ import annotations

import argparse
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CATALOG = ROOT / "docs" / "12-overlay-catalog.md"
BOOTSTRAP = ROOT / "mp2-native" / "Sources" / "MP2Overlays" / "OverlayBootstrap.swift"
XREF = ROOT / "docs" / "hardware" / "overlay-call-inventory.md"


def catalog_ids() -> list[tuple[str, str]]:
    rows = []
    for line in CATALOG.read_text().splitlines():
        m = re.match(r"^\| `(?P<id>[0-9A-Fa-f]+)` \| (?P<name>\w+) \|", line)
        if m:
            rows.append((m.group("id"), m.group("name")))
    return rows


def registered_ids() -> set[int]:
    ids: set[int] = set()
    for swift in (ROOT / "mp2-native" / "Sources" / "MP2Overlays").rglob("Ovl*.swift"):
        text = swift.read_text()
        m = re.search(r"overlayID: UInt8 \{ (0x[0-9A-Fa-f]+) \}", text)
        if m:
            ids.add(int(m.group(1), 16))
    return ids


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--checklist", action="store_true")
    ap.add_argument("--markdown", type=Path)
    args = ap.parse_args()

    cat = catalog_ids()
    reg = registered_ids()
    missing = [c for c in cat if int(c[0], 16) not in reg]

    lines = [
        "# Overlay port checklist",
        "",
        f"| Metric | Value |",
        f"|--------|-------|",
        f"| Catalog | {len(cat)} |",
        f"| Registered | {len(reg)} |",
        f"| Missing | {len(missing)} |",
        "",
        "## Missing IDs",
        "",
    ]
    for id_hex, name in missing:
        lines.append(f"- `{id_hex}` {name}")

    if XREF.exists():
        lines.extend(["", "## Top ReadMainFS overlays (RE priority)", ""])
        for line in XREF.read_text().splitlines():
            if "ReadMainFS" in line and "ovl_" in line:
                lines.append(f"- {line.strip()}")

    report = "\n".join(lines) + "\n"
    if args.markdown:
        args.markdown.write_text(report)
    if args.checklist or not args.markdown:
        print(report)


if __name__ == "__main__":
    main()
