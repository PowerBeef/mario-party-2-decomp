#!/usr/bin/env python3
"""Convert PartyPlanner64 Project64 .sym files to splat symbol_addrs.txt format."""

from __future__ import annotations

import argparse
import re
import sys
import urllib.request
from pathlib import Path

DEFAULT_SYM_URL = (
    "https://raw.githubusercontent.com/PartyPlanner64/symbols/master/MarioParty2U.sym"
)

SYM_LINE = re.compile(
    r"^(?P<addr>[0-9A-Fa-f]{8}),(?P<kind>[^,]+),(?P<name>[^,]+)(?:,(?P<comment>.*))?$"
)


def parse_sym(text: str) -> list[tuple[int, str, str, str]]:
    entries: list[tuple[int, str, str, str]] = []
    for raw in text.splitlines():
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        match = SYM_LINE.match(line)
        if not match:
            continue
        addr = int(match.group("addr"), 16)
        kind = match.group("kind").strip()
        name = match.group("name").strip()
        comment = (match.group("comment") or "").strip()
        if kind not in {"code", "data"}:
            continue
        if not name or name.startswith("?"):
            continue
        entries.append((addr, kind, name, comment))
    entries.sort(key=lambda item: item[0])
    return entries


INVALID_CHARS = re.compile(r'[<>:"/\\|?*]')

def sanitize_name(name: str) -> str:
    cleaned = INVALID_CHARS.sub("_", name)
    cleaned = cleaned.strip("._ ")
    if not cleaned:
        cleaned = "unnamed_symbol"
    return cleaned[:253]


def sanitize_comment(comment: str) -> str:
    if not comment:
        return ""
    # splat treats ':' as attribute syntax in comments
    return comment.replace(":", " -")


def to_symbol_addrs(entries: list[tuple[int, str, str, str]]) -> str:
    lines: list[str] = []
    used_names: set[str] = set()
    for addr, kind, name, comment in entries:
        base_name = sanitize_name(name)
        safe_name = base_name
        suffix_idx = 1
        while safe_name in used_names:
            safe_name = f"{base_name}_{suffix_idx:X}"
            suffix_idx += 1
        used_names.add(safe_name)
        rom = addr - 0x80000400 + 0x1000 if addr >= 0x80000000 else None
        comment = sanitize_comment(comment)
        suffix = f" // {comment}" if comment else ""
        if base_name != name:
            suffix = f" // was {name}" + suffix
        if rom is not None and rom > 0:
            lines.append(f"{safe_name} = 0x{addr:08X}; // rom:0x{rom:X}{suffix}")
        else:
            lines.append(f"{safe_name} = 0x{addr:08X};{suffix}")
    return "\n".join(lines) + "\n"


def merge_symbol_files(*paths: Path) -> str:
    merged: dict[int, tuple[str, str, str]] = {}
    for path in paths:
        if not path.exists():
            continue
        for addr, kind, name, comment in parse_sym(path.read_text()):
            merged[addr] = (kind, name, comment)
    entries = [(addr, kind, name, comment) for addr, (kind, name, comment) in sorted(merged.items())]
    return to_symbol_addrs(entries)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input", type=Path, help="Local .sym file")
    parser.add_argument("--output", type=Path, default=Path("symbol_addrs.txt"))
    parser.add_argument("--download", action="store_true", help="Fetch MarioParty2U.sym")
    parser.add_argument("--merge", type=Path, nargs="*", help="Additional symbol files to merge")
    args = parser.parse_args()

    texts: list[str] = []
    if args.download or args.input is None:
        with urllib.request.urlopen(DEFAULT_SYM_URL) as resp:
            texts.append(resp.read().decode("utf-8", errors="replace"))
    if args.input:
        texts.append(args.input.read_text())

    entries: list[tuple[int, str, str, str]] = []
    for text in texts:
        entries.extend(parse_sym(text))

    # De-duplicate by address, prefer first name.
    dedup: dict[int, tuple[int, str, str, str]] = {}
    for entry in entries:
        dedup[entry[0]] = entry
    body = to_symbol_addrs(sorted(dedup.values(), key=lambda item: item[0]))

    if args.merge:
        auto_path = Path("undefined_syms_auto.txt")
        if auto_path.exists():
            body = merge_symbol_files(Path(args.output), auto_path, *args.merge)
        else:
            merged_entries = sorted(dedup.values(), key=lambda item: item[0])
            for path in args.merge:
                merged_entries.extend(parse_sym(path.read_text()))
            body = to_symbol_addrs(merged_entries)

    args.output.write_text(body)
    print(f"Wrote {len(dedup)} symbols to {args.output}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
