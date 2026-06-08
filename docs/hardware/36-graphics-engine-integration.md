# Graphics Engine Integration

How MP2 builds display lists on the CPU and submits them through libultra to RSP/RDP/VI.

## Pipeline Summary

```text
HuPrc / omObj update
  → func_80050A30 (DL builder, MallocTemp scratch)
  → osWritebackDCache / osWritebackDCacheAll
  → mesg to GfxTaskThread (0x8007E754)
  → osSpTaskLoad + osSpTaskStartGo
  → RSP F3DEX2/GS2DEX2 ucode
  → RDP fill → framebuffer @ D_800EB910
  → osViSwapBuffer (VI retrace)
```

Hardware depth: [07-graphics-pipeline-overview.md](07-graphics-pipeline-overview.md) through [10-vi-display-modes.md](10-vi-display-modes.md).

## Init: VideoInit @ `0x8007E2A0`

Called from **`MainThreadEntry`** with mode index + NTSC flag.

| Step | libultra API | Globals cleared/set |
|------|--------------|---------------------|
| Mode select | **`osViSetMode`** | Index into **`D_800CDF10`** (OSViMode table) |
| Scale | `osViSetYScale(1.0f)` | — |
| Black screen | `osViBlack(1)` | — |
| SP queues | `osCreateMesgQueue` ×4 | `D_800EB950`, `D_800EB988`, `D_800F8F40`, `D_800ECB08` |
| VI event | **`osViSetEvent`** | Queue `D_800EB918`, retrace msg `0x29A` |
| Framebuffers | internal alloc | **`D_800EB910`**, **`D_800FA65C`**, **`D_800FDC6C`** |
| RSP task | — | **`D_800ECAD0`**, **`D_800ECAD4`**, **`D_800ECAD8`**, **`D_800ECB00`** |

Mode table dump: [mp2-vi-mode-table.md](mp2-vi-mode-table.md).

## Gfx Task Thread @ `0x8007E754`

Spawned via **`func_8007D5D4`** during init. Thread loop:

```text
osCreateMesgQueue(local)
osRecvMesg(D_800F8F40 or partner queue, BLOCK)
osWritebackDCacheAll()
osSpTaskStartGo(D_800ECAD0)    // 3 call sites in func body region
```

Also handles **`osViSetYScale`**, **`osViBlack`** on mode transitions @ `0x8007E70C`.

| libultra | Hardware | Doc |
|----------|----------|-----|
| `osSpTaskLoad` | RSP IMEM/DMEM load | [08](08-gbi-rsp-microcode.md) |
| `osSpTaskStartGo` | RSP run ucode | [04](04-rcp-rsp-rdp.md) |
| `osWritebackDCacheAll` | CPU→RSP coherency | [17](17-memory-heaps-dma-coherency.md) |

## Display List Construction

| Function | VRAM | Role |
|----------|------|------|
| **`func_80050A30`** | `0x80050A30` | Primary DL builder; uses **`MallocTemp`** |
| `ScissorSet` | symbol | Clip rect |
| `ViewportSet` | symbol | Camera viewport |
| Board GS2DEX | various | 2D tile backgrounds |

Microcode: **F3DEX2** + **GS2DEX2** (`-DF3DEX_GBI_2`). GBI commands in overlay `.data` sections.

Before RSP read, CPU calls **`osWritebackDCache`** on DL and vertex buffers.

## Framebuffer Double-Buffer

| Global | VRAM | Role |
|--------|------|------|
| **`D_800EB910`** | `0x800EB910` | Current draw buffer ptr |
| **`D_800FA65C`** | `0x800FA65C` | Back buffer / swap state |
| **`D_800FDC6C`** | `0x800FDC6C` | Swap generation (main loop skip guard) |
| **`D_800F9290`** | `0x800F9290` | VI swap pending flag |

Pixel formats: [09-rdp-framebuffers-pixel-formats.md](09-rdp-framebuffers-pixel-formats.md).

## Engine UX Overlays (RDP on CPU path)

| Feature | API | Integration |
|---------|-----|-------------|
| Screen fades | `InitFadeIn` / `InitFadeOut` | RDP rect fills; [29-fade-and-transitions.md](29-fade-and-transitions.md) |
| Message boxes | `ShowMessage` | GS2DEX2 text DL; [28-text-and-messaging.md](28-text-and-messaging.md) |
| Board tiles | HVQ → DL | [39-asset-to-gpu-bridge.md](39-asset-to-gpu-bridge.md) |

## RSP Save/Restore Across Overlays

Overlay transitions call:

- **`func_8007C184`** — snapshot RSP PC/registers to `D_800E2228`
- **`func_8007C1D0`** — restore via `bcopy` + `osSetIntMask`

Prevents RSP state corruption when swapping overlays mid-frame.

## Related Docs

- [36 from 08-rendering](../08-rendering.md) — Engine rendering index
- [34-main-thread-frame-loop.md](34-main-thread-frame-loop.md) — Mesg type 1 gfx tick
- [call-inventory.md](call-inventory.md) — `osSpTaskStartGo` count in main
