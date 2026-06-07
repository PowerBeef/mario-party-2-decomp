# Mario Party 2 Engine Overview

Mario Party 2 (USA, `NMWE`) is a 32 MB N64 title built on a **Hudson Soft-style engine** running atop libultra. The engine is organized around:

1. **Permanent main segment** — boot, OS glue, heaps, process scheduler, object/overlay manager, board helpers, audio, save I/O.
2. **115 dynamically loaded overlays** — minigames, board modes, menus, and meta screens sharing VRAM `0x80102800`.
3. **Asset tail** — compressed graphics/audio/filesystems from ROM `0x418A50` onward (~87% of cart).

## Boot Flow

```
IPL (0x40) → Entry (0x1000 / VRAM 0x80000400) → Main init → Title overlay (ovl_62) → Main menu (ovl_63) → …
```

## Hardware (N64 Silicon)

For physical CPU, RCP, PI/SI/VI/AI, caches, and TLB — how MP2 uses real N64 hardware:

| Doc | Topic |
|-----|-------|
| [hardware/00-system-architecture.md](hardware/00-system-architecture.md) | Block diagram, per-frame data flow |
| [hardware/01-vr4300-cpu.md](hardware/01-vr4300-cpu.md) | VR4300, caches, TLB, delay slots |
| [hardware/02-memory-map.md](hardware/02-memory-map.md) | KSEG0 RDRAM layout, overlay window |
| [hardware/03-boot-and-cartridge.md](hardware/03-boot-and-cartridge.md) | PIF, IPL, PI DMA |
| [hardware/04-rcp-rsp-rdp.md](hardware/04-rcp-rsp-rdp.md) | RSP/RDP summary |
| [hardware/05-video-and-audio-io.md](hardware/05-video-and-audio-io.md) | VI retrace, AI PCM |
| [hardware/06-serial-save-interrupts.md](hardware/06-serial-save-interrupts.md) | SI, EEPROM, IRQ model |
| [hardware/07-graphics-pipeline-overview.md](hardware/07-graphics-pipeline-overview.md) | Full graphics pipeline |
| [hardware/08-gbi-rsp-microcode.md](hardware/08-gbi-rsp-microcode.md) | GBI, RSP microcode |
| [hardware/09-rdp-framebuffers-pixel-formats.md](hardware/09-rdp-framebuffers-pixel-formats.md) | RDP, pixel formats |
| [hardware/10-vi-display-modes.md](hardware/10-vi-display-modes.md) | Display modes, OSViMode |
| [hardware/11-audio-pipeline-overview.md](hardware/11-audio-pipeline-overview.md) | Full audio pipeline |
| [hardware/12-ai-hardware-and-aspMain.md](hardware/12-ai-hardware-and-aspMain.md) | AI, aspMain microcode |
| [hardware/13-libaudio-library.md](hardware/13-libaudio-library.md) | libaudio library |
| [hardware/14-mp2-audio-engine-and-assets.md](hardware/14-mp2-audio-engine-and-assets.md) | MP2 audio engine |
| [hardware/15-cpu-software-stack-overview.md](hardware/15-cpu-software-stack-overview.md) | CPU software stack |
| [hardware/16-libultra-os-threads-messaging.md](hardware/16-libultra-os-threads-messaging.md) | libultra OS threads |
| [hardware/17-memory-heaps-dma-coherency.md](hardware/17-memory-heaps-dma-coherency.md) | Heaps, DMA, caches |
| [hardware/18-mp2-cpu-engine-scheduling.md](hardware/18-mp2-cpu-engine-scheduling.md) | HuPrc and overlays |
| [hardware/19-input-save-pipeline-overview.md](hardware/19-input-save-pipeline-overview.md) | Input and save pipeline |
| [hardware/20-si-controller-hardware.md](hardware/20-si-controller-hardware.md) | SI, controllers, rumble |
| [hardware/21-eeprom-save-hardware.md](hardware/21-eeprom-save-hardware.md) | EEPROM hardware and protocol |
| [hardware/22-mp2-input-save-engine.md](hardware/22-mp2-input-save-engine.md) | MP2 input/save engine |
| [hardware/call-inventory.md](hardware/call-inventory.md) | libultra call-site counts (auto-generated) |
| [hardware/audio-call-inventory.md](hardware/audio-call-inventory.md) | libaudio call-site counts (auto-generated) |
| [hardware/cpu-call-inventory.md](hardware/cpu-call-inventory.md) | CPU/engine call-site counts (auto-generated) |
| [hardware/input-save-call-inventory.md](hardware/input-save-call-inventory.md) | Input/save call-site counts (auto-generated) |

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
- `tools/hardware_xref.py` — libultra hardware API call inventory from `asm/1060.s`
- `tools/dump_vi_modes.py` — MP2 OSViMode table dump for doc 10
- `tools/audio_xref.py` — libaudio API call inventory from `asm/1060.s`
- `tools/cpu_xref.py` — libultra OS and MP2 CPU engine call inventory
- `tools/input_save_xref.py` — SI/EEPROM and input/save call inventory
- `venv/bin/splat split marioparty2.yaml` — generates `asm/` disassembly
