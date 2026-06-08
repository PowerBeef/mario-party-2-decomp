# Asset-to-GPU Bridge

Runtime path from **`ReadMainFS`** through decompression to RSP/RDP texture upload.

## End-to-End

```text
ReadMainFS(volume<<16 | index)
  → func_800175D4 / func_80017748 (table lookup)
  → MallocPerm(size)
  → func_80018990(compression_type)
       type 0: memcpy
       type 2/4: HVQ func_80027884
       type 3: anim tile 0x1800 B
  → interpretFORM / interpretMTNX (3D)
  → CPU builds gDPLoadBlock / GS2DEX2 DL
  → osWritebackDCache
  → RSP task → TMEM → RDP
```

Depth: [23-asset-pipeline-overview.md](23-asset-pipeline-overview.md)–[25-mainfs-form-mtnx.md](25-mainfs-form-mtnx.md).

## MainFS Mount

During boot **`func_80017530(D_0041DD30)`** @ `0x80017530` initializes filesystem tables:

| Global | VRAM | Role |
|--------|------|------|
| `D_800D81C4` | `0x800D81C4` | Volume count |
| `D_800D81D0` | `0x800D81D0` | Files per volume |
| `D_800D81C0` | `0x800D81C0` | ROM offset table |

Assets live ROM **`0x418A50`**+. PI DMA via **`func_8007C3C8`** → **`osEPiStartDma`**.

## Heap Choice

| API | When | Freed |
|-----|------|-------|
| **`MallocPerm`** | Board packs, long-lived models | `FreeMainFS` / overlay end |
| **`MallocTemp`** | DL scratch, single-frame decompress | Temp heap reset @ overlay teardown |

Temp reset: **`func_8001A4C0`** in **`func_80077574`**.

## Compression Hot Path

**`func_80018990`** @ `0x80018990` — see [24-hvq-and-compression.md](24-hvq-and-compression.md).

Board anim tiles (type **3**, **0x1800** B) swapped in **`ovl_5F_BoardMain`** loop — CPU-bound; see [18-mp2-cpu-engine-scheduling.md](18-mp2-cpu-engine-scheduling.md).

## 3D Path

```text
ReadMainFS(model_id)
  → interpretFORM → VTX1/FAC1/OBJ1 chunks
  → interpretMTNX → transform matrices
  → F3DEX2 DL in RDRAM
  → GfxTaskThread submit
```

Parsers: **`interpretFORM`** @ `0x8001D190`, **`interpretMTNX`** @ `0x80038F0C`.

## GPU Upload (2D Board Tiles)

GS2DEX2 path:

1. Decompressed CI/RGBA in RDRAM
2. **`gDPLoadBlock`** / **`gSPTextureRectangle`** in DL
3. **`osWritebackDCacheAll`** before RSP
4. TMEM load → RDP draw

TMEM limits: [09-rdp-framebuffers-pixel-formats.md](09-rdp-framebuffers-pixel-formats.md).

## CPU vs RCP Bound Phases

| Phase | Bottleneck | Typical overlay |
|-------|------------|-----------------|
| First board load | CPU (HVQ × N tiles) | `ovl_5F` |
| Steady board frame | RCP (GS2DEX fill) | `ovl_5F` |
| Minigame intro | CPU (ReadMainFS burst) | various |
| 3D minigame play | RCP (F3DEX triangles) | `ovl_45` etc. |

## Top Consumers (Overlay Inventory)

| API | Top overlay | Count |
|-----|-------------|-------|
| `ReadMainFS` | `ovl_5F_BoardMain` | 77 |
| `ReadMainFS` | `ovl_60_BoardEvents` | 57 |
| `FreeMainFS` | minigame overlays | paired with load |
| `GetRandomByte` | all overlays | 1059 total |

Source: [overlay-call-inventory.md](overlay-call-inventory.md).

## Related Docs

- [../11-asset-formats.md](../11-asset-formats.md) — Format index
- [36-graphics-engine-integration.md](36-graphics-engine-integration.md) — DL submit
- [35-overlay-load-lifecycle.md](35-overlay-load-lifecycle.md) — Temp heap reset
- [17-memory-heaps-dma-coherency.md](17-memory-heaps-dma-coherency.md) — DMA + cache
