#!/usr/bin/env python3
"""Discover Mario Party 2 overlay segments from the ROM overlay dispatch table."""

from __future__ import annotations

import argparse
import struct
import sys
from dataclasses import dataclass
from pathlib import Path

OVERLAY_TABLE_ROM = 0xC9474
OVERLAY_ENTRY_SIZE = 0x24
OVERLAY_VRAM = 0x80102800

# Names from public overlay directory conventions (hex id -> slug).
OVERLAY_NAMES: dict[int, str] = {
    0x00: "Debug",
    0x01: "BowserSlots",
    0x02: "RollOutTheBarrels",
    0x03: "CoffinCongestion",
    0x04: "HammerSlammer",
    0x05: "GiveMeABrake",
    0x06: "MalletGoRound",
    0x07: "GrabBag",
    0x08: "LavaTileIsle",
    0x09: "BumperBalloonCars",
    0x0A: "RakinEmIn",
    0x0B: "DayAtTheRaces",
    0x0C: "HotRopeJump",
    0x0D: "HotBobOmb",
    0x0E: "BowlOver",
    0x0F: "RainbowRun",
    0x10: "CraneGame",
    0x11: "MoveToTheMusic",
    0x12: "BobOmbBarrage",
    0x13: "LookAway",
    0x14: "ShockDropRoll",
    0x15: "LightsOut",
    0x16: "FiletRelay",
    0x17: "ArcherAttack",
    0x18: "ToadtressScramble",
    0x19: "BobsledRun",
    0x1A: "HandcarHavoc",
    0x1B: "BalloonBurst",
    0x1C: "SkyPilots",
    0x1D: "SpeedHikers",
    0x1E: "HoneycombTreasureHunt",
    0x1F: "SlotMachine",
    0x20: "MechaMarathon",
    0x21: "RollCall",
    0x22: "AbandonShip",
    0x23: "PlatformPeril",
    0x24: "TotemPolePerturbation",
    0x25: "BumperBallMaze",
    0x26: "KarateChop",
    0x27: "StackingStored",
    0x28: "ShuffleAdventure",
    0x29: "BobsledRun2P",
    0x2A: "HandcarHavoc2P",
    0x2B: "BalloonBurst2P",
    0x2C: "SkyPilots2P",
    0x2D: "SpeedHikers2P",
    0x2E: "CrazyCutter",
    0x2F: "BombsAway",
    0x30: "RainbowRun2P",
    0x31: "ConveyorBeltChase",
    0x32: "TorpedoTargets",
    0x33: "LuckySeven",
    0x34: "LightUpMyNight",
    0x35: "FaceOff",
    0x36: "MagnetCarta",
    0x37: "RollOutTheBarrels2P",
    0x38: "CoffinCongestion2P",
    0x39: "HammerSlammer2P",
    0x3A: "GiveMeABrake2P",
    0x3B: "MalletGoRound2P",
    0x3C: "GrabBag2P",
    0x3D: "LavaTileIsle2P",
    0x3E: "BumperBalloonCars2P",
    0x3F: "RakinEmIn2P",
    0x40: "DayAtTheRaces2P",
    0x41: "HotRopeJump2P",
    0x42: "HotBobOmb2P",
    0x43: "BowlOver2P",
    0x44: "RainbowRun4P",
    0x45: "CraneGame2P",
    0x46: "MoveToTheMusic2P",
    0x47: "BobOmbBarrage2P",
    0x48: "LookAway2P",
    0x49: "ShockDropRoll2P",
    0x4A: "LightsOut2P",
    0x4B: "FiletRelay2P",
    0x4C: "ArcherAttack2P",
    0x4D: "ToadtressScramble2P",
    0x4E: "BobsledRun1P",
    0x4F: "HandcarHavoc1P",
    0x50: "BalloonBurst1P",
    0x51: "SkyPilots1P",
    0x52: "SpeedHikers1P",
    0x53: "HoneycombTreasureHunt1P",
    0x54: "SlotMachine1P",
    0x55: "MechaMarathon1P",
    0x56: "RollCall1P",
    0x57: "AbandonShip1P",
    0x58: "PlatformPeril1P",
    0x59: "TotemPolePerturbation1P",
    0x5A: "BumperBallMaze1P",
    0x5B: "KarateChop1P",
    0x5C: "StackingStored1P",
    0x5D: "ShuffleAdventure1P",
    0x5E: "BoardSelect",
    0x5F: "BoardMain",
    0x60: "BoardEvents",
    0x61: "BoardShop",
    0x62: "TitleScreenAndIntro",
    0x63: "MainMenu",
    0x64: "GameSetup",
    0x65: "MinigameLand",
    0x66: "BattleMinigame",
    0x67: "StoryMode",
    0x68: "OptionsMenu",
    0x69: "SaveLoad",
    0x6A: "BoardIntro",
    0x6B: "MinigameInstructions",
    0x6C: "MinigameSelect",
    0x6D: "FinalMinigameCoaster",
    0x6E: "MinigameCoaster",
    0x6F: "BattleResults",
    0x70: "Results",
    0x71: "MsgTest",
    0x72: "Credits",
}


@dataclass
class OverlayEntry:
    index: int
    rom_start: int
    rom_end: int
    vram_text: int
    vram_data: int
    vram_end: int


def read_overlay_table(rom: bytes, table_rom: int = OVERLAY_TABLE_ROM) -> list[OverlayEntry]:
    entries: list[OverlayEntry] = []
    offset = table_rom
    index = 0
    while offset + OVERLAY_ENTRY_SIZE <= len(rom):
        words = struct.unpack_from(">9I", rom, offset)
        rom_start, rom_end = words[0], words[1]
        if rom_start < 0xD0000 or rom_start >= len(rom):
            break
        if rom_end <= rom_start or rom_end > len(rom):
            break
        entries.append(
            OverlayEntry(
                index=index,
                rom_start=rom_start,
                rom_end=rom_end,
                vram_text=words[2],
                vram_data=words[3],
                vram_end=words[4],
            )
        )
        offset += OVERLAY_ENTRY_SIZE
        index += 1
    return entries


def slug_for(index: int) -> str:
    return OVERLAY_NAMES.get(index, f"Overlay{index:02X}")


def emit_yaml(rom_path: Path, main_end: int, overlays: list[OverlayEntry], include_main_c: bool) -> str:
    sha1 = __import__("hashlib").sha1(rom_path.read_bytes()).hexdigest()
    lines: list[str] = [
        "name: Marioparty2 (North America)",
        f"sha1: {sha1}",
        "options:",
        "  basename: marioparty2",
        "  target_path: baserom.us.z64",
        "  base_path: .",
        "  compiler: GCC",
        "  find_file_boundaries: True",
        "  header_encoding: ASCII",
        "  platform: n64",
        "  symbol_name_format: $VRAM_$ROM",
        "  symbol_name_format_no_rom: $VRAM",
        "  undefined_funcs_auto_path: undefined_funcs_auto.txt",
        "  undefined_syms_auto_path: undefined_syms_auto.txt",
        "  symbol_addrs_path: symbol_addrs.txt",
        "  asm_path: asm",
        "  src_path: src",
        "  build_path: build",
        "  asm_function_macro: glabel",
        "  asm_jtbl_label_macro: jlabel",
        "  asm_data_macro: dlabel",
        "  migrate_rodata_to_functions: True",
        "  subalign: 8",
        "  use_legacy_include_asm: False",
        '  asm_inc_header: "\\t.set noat\\n\\t.set noreorder\\n"',
        "segments:",
        "  - name: header",
        "    type: header",
        "    start: 0x0",
        "  - name: boot",
        "    type: bin",
        "    start: 0x40",
        "  - name: entry",
        "    type: code",
        "    start: 0x1000",
        "    vram: 0x80000400",
        "    subsegments:",
        "      - [0x1000, hasm, entrypoint]",
        "  - name: main",
        "    type: code",
        "    start: 0x1060",
        "    vram: 0x80000460",
        "    follows_vram: entry",
        "    bss_size: 0x2DC10",
        "    subsegments:",
    ]
    if include_main_c:
        lines.append("      - [0x1060, asm]")
        lines.append(f"      - {{0x{main_end:X}, type: bss, vram: 0x800D4BF0, name: globalBSS }}")
    else:
        lines.append("      - [0x1060, asm]")
        lines.append(f"      - {{0x{main_end:X}, type: bss, vram: 0x800D4BF0, name: globalBSS }}")

    code_overlays = [o for o in overlays if o.index <= 0x72]
    for ovl in code_overlays:
        slug = slug_for(ovl.index)
        dir_name = f"ovl_{ovl.index:02X}_{slug}"
        bss_size = max(0, ovl.vram_end - ovl.vram_data) if ovl.vram_end > ovl.vram_data else 0
        lines.extend(
            [
                "  - type: code",
                f"    start: 0x{ovl.rom_start:X}",
                f"    vram: 0x{OVERLAY_VRAM:X}",
                f"    dir: overlays/{dir_name}",
                f"    name: {slug}",
                "    overlay: True",
                "    exclusive_ram_id: minigame",
                "    symbol_name_format: $VRAM_$ROM_$SEG",
            ]
        )
        if bss_size:
            lines.append(f"    bss_size: 0x{bss_size:X}")
        lines.append("    subsegments:")
        lines.append(f"      - [0x{ovl.rom_start:X}, asm]")
        if bss_size:
            lines.append(
                f"      - {{0x{ovl.rom_end:X}, type: bss, vram: 0x{ovl.vram_end:X}, name: ovl_{ovl.index:02X}_bss}}"
            )

    tail = overlays[-1] if overlays else None
    if tail and tail.index > 0x72:
        lines.append(f"  - [0x{tail.rom_start:X}, bin]")
    elif code_overlays:
        last_end = code_overlays[-1].rom_end
        if last_end < len(rom_path.read_bytes()):
            lines.append(f"  - [0x{last_end:X}, bin]")
    lines.append("  - [0x2000000]")
    return "\n".join(lines) + "\n"


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--rom", type=Path, default=Path("baserom.us.z64"))
    parser.add_argument("--output", type=Path, default=Path("marioparty2.yaml"))
    parser.add_argument("--table-rom", type=lambda x: int(x, 0), default=OVERLAY_TABLE_ROM)
    parser.add_argument("--main-end", type=lambda x: int(x, 0), default=0xD57F0)
    args = parser.parse_args()

    rom = args.rom.read_bytes()
    overlays = read_overlay_table(rom, args.table_rom)
    if not overlays:
        print("No overlays discovered", file=sys.stderr)
        return 1

    yaml_text = emit_yaml(args.rom, args.main_end, overlays, include_main_c=False)
    args.output.write_text(yaml_text)
    print(f"Discovered {len(overlays)} overlay table entries")
    print(f"Wrote {args.output}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
