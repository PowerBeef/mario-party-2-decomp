# Mario Party 2 Engine Overview

Mario Party 2 (USA, `NMWE`) is a 32 MB N64 title built on a **Hudson Soft-style engine** running atop libultra. The engine is organized around:

1. **Permanent main segment** — boot, OS glue, heaps, process scheduler, object/overlay manager, board helpers, audio, save I/O.
2. **115 dynamically loaded overlays** — minigames, board modes, menus, and meta screens sharing VRAM `0x80102800`.
3. **Asset tail** — compressed graphics/audio/filesystems from ROM `0x418A50` onward (~87% of cart).

## Boot Flow

```
IPL (0x40) → Entry (0x1000 / VRAM 0x80000400) → Main init → Title overlay (ovl_62) → Main menu (ovl_63) → …
```

## Subsystem Index

| Doc | Topic |
|-----|-------|
| [01-memory-map.md](01-memory-map.md) | ROM/RAM layout |
| [02-boot-and-init.md](02-boot-and-init.md) | Startup sequence |
| [03-process-system.md](03-process-system.md) | Cooperative processes |
| [04-object-manager.md](04-object-manager.md) | Overlay loader |
| [05-game-state.md](05-game-state.md) | `GW_SYSTEM` / players |
| [06-board-engine.md](06-board-engine.md) | Spaces, events, items |
| [07-minigame-framework.md](07-minigame-framework.md) | Overlay lifecycle |
| [08-rendering.md](08-rendering.md) | Graphics pipeline |
| [09-audio.md](09-audio.md) | Music and SFX |
| [10-input-and-save.md](10-input-and-save.md) | Controllers, EEPROM |
| [11-asset-formats.md](11-asset-formats.md) | MainFS, HVQ, animations |
| [12-overlay-catalog.md](12-overlay-catalog.md) | All 115 overlays |
| [13-data-structures.md](13-data-structures.md) | Struct reference |
| [14-decomp-progress.md](14-decomp-progress.md) | Matching status |

## Key VRAM Anchors

| Symbol / struct | VRAM | Purpose |
|-----------------|------|---------|
| `GwSystem` | `0x800F93A8` | Active board/turn state |
| `gPlayers[4]` | `0x800FD2C0` | Per-player runtime data |
| `overlayTable` | `0x800CAD90` | ROM↔VRAM overlay descriptors |
| `permHeapPtr` | `0x800DEFD0` | Permanent allocator root |
| Minigame code window | `0x80102800` | Shared overlay load address |

## Tooling in This Repo

- `tools/scan_overlays.py` — rebuilds `marioparty2.yaml` from ROM table at `0xC9474`
- `tools/sym_converter.py` — imports PartyPlanner64 `.sym` names into `symbol_addrs.txt`
- `tools/verify_rom.py` — validates segment coverage and baserom SHA1
- `venv/bin/splat split marioparty2.yaml` — generates `asm/` disassembly
