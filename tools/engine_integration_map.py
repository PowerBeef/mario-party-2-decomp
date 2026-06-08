#!/usr/bin/env python3
"""Generate engine→libultra integration map with hardware doc tags."""

from __future__ import annotations

import argparse
import re
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

SYM_LINE = re.compile(r"^(\w+)\s*=\s*(0x[0-9A-Fa-f]+)")
GLABEL = re.compile(r"^glabel\s+(\w+)")
ENDLABEL = re.compile(r"^endlabel\s+(\w+)")
JAL = re.compile(r"\bjal\s+(\w+)")

# libultra / libaudio APIs → (hardware buses, doc id)
LIBULTRA_TAGS: dict[str, tuple[list[str], str]] = {
    "osEPiStartDma": (["PI"], "03"),
    "osPiRawStartDma": (["PI"], "03"),
    "osCreatePiManager": (["PI"], "03"),
    "osCartRomInit": (["PI"], "03"),
    "osPiGetAccess": (["PI"], "03"),
    "osPiRelAccess": (["PI"], "03"),
    "osContStartReadData": (["SI"], "20"),
    "osContGetReadData": (["SI"], "20"),
    "osContInit": (["SI"], "20"),
    "osMotorInit": (["SI"], "20"),
    "osMotorAccess": (["SI"], "20"),
    "osEepromProbe": (["SI"], "21"),
    "osEepromRead": (["SI"], "21"),
    "osEepromWrite": (["SI"], "21"),
    "osEepromLongRead": (["SI"], "21"),
    "osEepromLongWrite": (["SI"], "21"),
    "osViSetMode": (["VI"], "10"),
    "osViSwapBuffer": (["VI"], "10"),
    "osViSetEvent": (["VI"], "10"),
    "osViBlack": (["VI"], "10"),
    "osViSetYScale": (["VI"], "10"),
    "osViSetSpecialFeatures": (["VI"], "10"),
    "osSpTaskLoad": (["RSP"], "08"),
    "osSpTaskStartGo": (["RSP"], "08"),
    "osSpRawStartDma": (["RSP"], "08"),
    "osAiSetNextBuffer": (["AI"], "12"),
    "osAiSetFrequency": (["AI"], "12"),
    "osWritebackDCache": (["CPU"], "17"),
    "osWritebackDCacheAll": (["CPU"], "17"),
    "osInvalDCache": (["CPU"], "17"),
    "osInvalICache": (["CPU"], "17"),
    "osCreateThread": (["CPU"], "16"),
    "osStartThread": (["CPU"], "16"),
    "osCreateMesgQueue": (["CPU"], "16"),
    "osRecvMesg": (["CPU"], "16"),
    "osSendMesg": (["CPU"], "16"),
    "osSetIntMask": (["CPU"], "16"),
    "alSynStartVoice": (["AI", "RSP"], "14"),
    "alSynStartVoiceParams": (["AI", "RSP"], "14"),
    "alSynAllocVoice": (["AI", "RSP"], "14"),
    "alSeqpPlay": (["AI", "RSP"], "14"),
    "alSeqpStop": (["AI", "RSP"], "14"),
    "alSeqpSetSeq": (["AI", "RSP"], "14"),
    "alSeqpSetBank": (["AI", "RSP"], "14"),
    "alSndpPlay": (["AI", "RSP"], "14"),
    "alSndpStop": (["AI", "RSP"], "14"),
    "alSndpAllocate": (["AI", "RSP"], "14"),
    "alSndpSetSound": (["AI", "RSP"], "14"),
    "alAudioFrame": (["AI", "RSP"], "14"),
    "alBnkfNew": (["AI"], "14"),
}

# Integration-critical engine symbols (include asm-only names)
INTEGRATION_ENGINE: list[str] = [
    "MainThreadEntry",
    "VideoInit",
    "GfxTaskThread",
    "omOvlCallEx",
    "omOvlGotoEx",
    "omOvlReturnEx",
    "OverlayDmaLoad",
    "OverlayTeardown",
    "ReadMainFS",
    "PlaySound",
    "InitProcess",
    "SleepVProcess",
    "InitObjSys",
    "MakePermHeap",
    "MallocPerm",
    "interpretFORM",
    "ShowMessage",
    "InitFadeIn",
    "GetRandomByte",
    "RunDecisionTree",
]

# VRAM aliases for symbols not yet in symbol_addrs
VRAM_ALIASES: dict[str, int] = {
    "MainThreadEntry": 0x800409E0,
    "VideoInit": 0x8007E2A0,
    "GfxTaskThread": 0x8007E754,
    "omOvlCallEx": 0x800771EC,
    "omOvlGotoEx": 0x800770EC,
    "omOvlReturnEx": 0x80077160,
    "OverlayDmaLoad": 0x8007C4E4,
    "OverlayTeardown": 0x80077574,
}


def canonical(name: str) -> str:
    return re.sub(r"_\d+$", "", name)


def load_symbols(path: Path) -> dict[str, int]:
    symbols: dict[str, int] = {}
    for line in path.read_text().splitlines():
        match = SYM_LINE.match(line.strip())
        if match:
            symbols[match.group(1)] = int(match.group(2), 16)
    symbols.update(VRAM_ALIASES)
    return symbols


def vram_to_name(symbols: dict[str, int]) -> dict[int, str]:
    by_vram: dict[int, str] = {}
    for name, addr in symbols.items():
        if addr not in by_vram or len(name) < len(by_vram[addr]):
            by_vram[addr] = name
    for name, addr in VRAM_ALIASES.items():
        by_vram[addr] = name
    return by_vram


def parse_functions(asm_path: Path) -> dict[str, list[str]]:
    """Map glabel name → lines in function body."""
    lines = asm_path.read_text().splitlines()
    functions: dict[str, list[str]] = {}
    current: str | None = None
    for line in lines:
        gm = GLABEL.match(line.strip())
        if gm:
            current = canonical(gm.group(1))
            functions[current] = []
            continue
        em = ENDLABEL.match(line.strip())
        if em and current:
            current = None
            continue
        if current is not None:
            functions[current].append(line)
    return functions


def jals_in_body(body: list[str]) -> dict[str, int]:
    counts: dict[str, int] = defaultdict(int)
    for line in body:
        match = JAL.search(line)
        if match:
            counts[canonical(match.group(1))] += 1
    return dict(counts)


def resolve_engine_func(name: str, vram: int, by_vram: dict[int, str], functions: dict[str, list[str]]) -> str | None:
    if name in functions:
        return name
    # try func_800409E0 style from vram
    for fn, _ in functions.items():
        if fn.startswith("func_") and fn in functions:
            pass
    # match by canonical glabel containing vram hex
    suffix = f"{vram:08X}"[-5:].upper()
    for fn in functions:
        if suffix in fn.upper() or fn == name:
            if fn == name:
                return fn
    # fallback: func_800409E0 from address
    key = f"func_{vram:08X}"
    for fn in functions:
        if canonical(fn).startswith(key[:12]):
            return fn
    for fn in functions:
        c = canonical(fn)
        if c == name:
            return fn
    return None


def find_func_by_vram(vram: int, functions: dict[str, list[str]]) -> str | None:
    """Find glabel whose address comment matches vram (func_800409E0 or D_800409E0 label)."""
    target = f"{vram:08X}"
    for fn in functions:
        if target[4:] in fn.upper() or fn.replace("_", "").endswith(target[4:]):
            return fn
    # scan first line address in body - expensive; use known map
    known: dict[int, str] = {
        0x800409E0: "D_800409E0_415E0",
        0x8007E2A0: "func_8007E2A0_7EEA0",
        0x8007E754: "D_8007E754_7F354",
        0x800771EC: "func_800771EC_77DEC",
        0x800770EC: "func_800770EC_77CEC",
        0x80077160: "func_80077160_77D60",
        0x8007C4E4: "func_8007C4E4_7D0E4",
        0x80077574: "func_80077574_78174",
    }
    return known.get(vram)


def tag_for_callee(callee: str) -> tuple[list[str], str] | None:
    if callee in LIBULTRA_TAGS:
        return LIBULTRA_TAGS[callee]
    if callee.startswith("os"):
        if "Vi" in callee or callee.startswith("osVi"):
            return (["VI"], "10-vi-display-modes")
        if "Cont" in callee or "Motor" in callee or "Eeprom" in callee or "Pfs" in callee:
            return (["SI"], "21-eeprom-save-hardware")
        if "Ai" in callee:
            return (["AI"], "12-ai-hardware-and-aspMain")
        if "Sp" in callee or "Dp" in callee:
            return (["RSP"], "08-gbi-rsp-microcode")
        if "Pi" in callee or "EPi" in callee or "Cart" in callee:
            return (["PI"], "03-boot-and-cartridge")
        if "Writeback" in callee or "Inval" in callee:
            return (["CPU"], "17-memory-heaps-dma-coherency")
        return (["CPU"], "16-libultra-os-threads-messaging")
    if callee.startswith("al"):
        return (["AI", "RSP"], "14-mp2-audio-engine-and-assets")
    return None


def body_for_symbol(name: str, vram: int, functions: dict[str, list[str]]) -> list[str] | None:
    if name in functions:
        return functions[name]
    fn_key = find_func_by_vram(vram, functions)
    if fn_key and fn_key in functions:
        return functions[fn_key]
    for fn, body in functions.items():
        if canonical(fn) == name:
            return body
    return None


def is_engine_symbol(name: str) -> bool:
    lower = name.lower()
    if name.startswith(("os", "al", "__")):
        return False
    if lower.startswith("leo") or name.startswith("LEO"):
        return False
    return True


def collect_edges(
    symbols: dict[str, int], functions: dict[str, list[str]]
) -> list[tuple[str, int, str, list[str], str]]:
    edges: list[tuple[str, int, str, list[str], str]] = []
    seen: set[tuple[str, str]] = set()

    targets = set(INTEGRATION_ENGINE) | {n for n in symbols if is_engine_symbol(n)}

    for name in sorted(targets):
        vram = symbols.get(name) or VRAM_ALIASES.get(name)
        if vram is None:
            continue
        body = body_for_symbol(name, vram, functions)
        if not body:
            continue
        for callee in jals_in_body(body):
            tag = tag_for_callee(callee)
            if tag is None:
                continue
            key = (name, callee)
            if key in seen:
                continue
            seen.add(key)
            buses, doc = tag
            edges.append((name, vram, callee, buses, doc))

    return edges


def render_markdown(
    edges: list[tuple[str, int, str, list[str], str]],
    symbols: dict[str, int],
) -> str:
    lines = [
        "<!-- Auto-generated by tools/engine_integration_map.py -->",
        "",
        "## Engine → libultra Integration Map",
        "",
        "Direct `jal` edges from named engine functions in [`asm/1060.s`](../asm/1060.s) "
        "to libultra/libaudio APIs, tagged by hardware bus.",
        "",
        f"**{len(edges)}** edges documented.",
        "",
        "| Engine function | VRAM | libultra callee | HW | Doc |",
        "|-----------------|------|-----------------|-----|-----|",
    ]
    for name, vram, callee, buses, doc in sorted(edges, key=lambda e: (e[0], e[2])):
        hw = ", ".join(buses)
        doc_file = doc if doc.endswith(".md") else f"{doc}-boot-and-cartridge.md" if doc == "03" else f"{doc}.md"
        if doc == "10":
            doc_file = "10-vi-display-modes.md"
        elif doc == "16":
            doc_file = "16-libultra-os-threads-messaging.md"
        elif doc == "17":
            doc_file = "17-memory-heaps-dma-coherency.md"
        elif doc == "08":
            doc_file = "08-gbi-rsp-microcode.md"
        elif doc == "14":
            doc_file = "14-mp2-audio-engine-and-assets.md"
        elif doc == "21":
            doc_file = "21-eeprom-save-hardware.md"
        elif doc == "03":
            doc_file = "03-boot-and-cartridge.md"
        elif doc == "12":
            doc_file = "12-ai-hardware-and-aspMain.md"
        lines.append(f"| `{name}` | `0x{vram:08X}` | `{callee}` | {hw} | [{doc_file[:2]}]({doc_file}) |")

    # Top callees
    callee_totals: dict[str, int] = defaultdict(int)
    for _, _, callee, _, _ in edges:
        callee_totals[callee] += 1
    lines.extend(["", "### Top libultra APIs by engine fan-in", ""])
    lines.append("| libultra API | Engine functions calling | HW |")
    lines.append("|--------------|--------------------------|-----|")
    for callee, n in sorted(callee_totals.items(), key=lambda x: (-x[1], x[0]))[:30]:
        tag = tag_for_callee(callee)
        buses = tag[0] if tag else ["CPU"]
        lines.append(f"| `{callee}` | {n} | {', '.join(buses)} |")

    lines.extend(
        [
            "",
            "See [32-engine-integration-overview.md](32-engine-integration-overview.md) for the full atlas.",
            "",
        ]
    )
    return "\n".join(lines)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--symbols", type=Path, default=ROOT / "symbol_addrs.txt")
    parser.add_argument("--asm", type=Path, default=ROOT / "asm" / "1060.s")
    parser.add_argument(
        "--output",
        type=Path,
        default=ROOT / "docs" / "hardware" / "engine-integration-map.md",
    )
    args = parser.parse_args()

    symbols = load_symbols(args.symbols)
    functions = parse_functions(args.asm)
    # Register D_800409E0 and D_8007E754 as pseudo functions
    all_lines = args.asm.read_text().splitlines()
    in_main = False
    main_body: list[str] = []
    in_gfx = False
    gfx_body: list[str] = []
    for line in all_lines:
        if "alabel D_800409E0" in line or "glabel MainThreadEntry" in line:
            in_main = True
            continue
        if in_main and "endlabel func_8004075C" in line:
            in_main = False
        if in_main:
            main_body.append(line)
        if "alabel D_8007E754" in line or "glabel GfxTaskThread" in line:
            in_gfx = True
            continue
        if in_gfx and "alabel D_" in line and "7E754" not in line and len(gfx_body) > 5:
            in_gfx = False
        if in_gfx:
            gfx_body.append(line)

    functions["MainThreadEntry"] = main_body
    functions["D_800409E0_415E0"] = main_body
    functions["GfxTaskThread"] = gfx_body
    functions["D_8007E754_7F354"] = gfx_body

    edges = collect_edges(symbols, functions)
    body = render_markdown(edges, symbols)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(body)
    print(f"Wrote {args.output} ({len(edges)} edges)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
