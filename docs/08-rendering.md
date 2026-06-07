# Rendering

Mario Party 2 renders with **F3DEX microcode** (GBI 2) plus **GS2DEX** for 2D sprites and backgrounds.

## Pipeline Overview

```mermaid
flowchart LR
    gameObj[omObj update] --> dlGen[Display list build]
    dlGen --> rsp[RSP F3DEX/GS2DEX]
    rsp --> rdp[RDP rasterize]
    rdp --> vi[VI framebuffer swap]
```

## Key Functions

| Function | Role |
|----------|------|
| `ScissorSet` | Clip rectangle |
| `ViewportSet` | Camera viewport |
| `func_80018E30` | Matrix / camera setup |
| `func_80050A30` | RCP task submission |

## Fade System

| Function | Role |
|----------|------|
| `InitFadeIn` | Screen fade from black |
| `InitFadeOut` | Fade to black |

Used heavily during overlay transitions.

## 2D Board Backgrounds

Board backgrounds use **HVQ-compressed tiles** in MainFS. Animated tiles swap via the **animation filesystem** (compression type 3 tiles, 0x1800 bytes decompressed).

## Character Models

Player pieces are 3D models driven by board/minigame overlays. `SetBoardPlayerAnimation` selects animation index per player.

## Display Lists

Assembly `.data` sections in overlays contain `gsSP*` commands. splat marks these as `.data` rodata in full yaml configs; current asm-only split embeds them in `.s` files.

## Known Microcodes

Build defines `-DF3DEX_GBI_2`. Standard Nintendo RSP tasks (`osSpTaskLoad`, `osSpTaskStartGo`) in main segment.
