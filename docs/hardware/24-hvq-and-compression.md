# HVQ and Compression Types

CPU-side decompression in Mario Party 2 — Hudson HVQ tiles, animation type 3, and the dispatch table in main segment.

## Central Dispatch

**`func_80018990`** @ `0x80018990` branches on compression type in **`$a3`**:

```text
switch (type) {
  case 0: func_80017BC0; break;  // raw
  case 1: func_80017C5C; break;
  case 2: func_80017ECC; break;  // HVQ
  case 3: func_80018378; break;  // anim tile
  case 4: func_800187F4; break;
}
```

Stack scratch at `sp+0x10` holds a **0x400**-byte header/control block passed to each backend.

## Type 3 — Animation Tiles

Used by the **animation filesystem** for board background tile swaps ([../11-asset-formats.md](../11-asset-formats.md)):

| Field | Value |
|-------|-------|
| `compression_type` | **3** |
| `decompressed_size` | **0x1800** (6144 bytes) |
| Typical tile | 32×32 or equivalent CI/RGBA strip |

**`func_80018378`** decodes quickly — optimized for per-frame swaps in board overlay main loop, not maximum ratio.

## HVQ (Types 2 and 4)

**HVQ** (Hudson vector quantization) compresses board backgrounds and UI tiles:

- VQ codebook + indices in ROM
- Decompressed output sized for GS2DEX2 **`gDPLoadBlock`** upload
- Small tile granularity (~32×32 regions) limits TMEM pressure — see [09-rdp-framebuffers-pixel-formats.md](09-rdp-framebuffers-pixel-formats.md)

**`func_80027884`** @ `0x80027884` is the shared outer wrapper:

```text
func_80018A30(file_id, dest, ...):
    buf = ReadMainFS(file_id)
    return func_80027884(buf, dest)
```

## Type 0 — Uncompressed

**`func_80017BC0`** — memcpy-style path when assets are stored raw in MainFS (rare for large tiles, common for small structs).

## Pipeline After Decompress

1. Decompressed buffer in RDRAM (temp or perm heap)
2. CPU builds GS2DEX2 object or F3DEX2 texture state
3. **`osWritebackDCache`** on CPU-written buffers before RSP read
4. RSP ucode samples via TMEM

## File Metadata

MainFS entries carry compression type in the directory table — resolved before **`func_80018990`** is called. Exact table layout: [25-mainfs-form-mtnx.md](25-mainfs-form-mtnx.md).

## Performance Notes

| Pattern | Cost |
|---------|------|
| Full board background first load | Many HVQ tiles × decode + upload |
| Anim tile swap (type 3) | Single 0x1800 decode per changed cell |
| Minigame 3D models | FORM path, often less HVQ |

Profiling hotspot: board overlay init calling **`ReadMainFS`** in loops — grep overlay asm for file ID immediates.

## Related Docs

- [23-asset-pipeline-overview.md](23-asset-pipeline-overview.md) — Full pipeline
- [25-mainfs-form-mtnx.md](25-mainfs-form-mtnx.md) — MainFS layout
- [07-graphics-pipeline-overview.md](07-graphics-pipeline-overview.md) — GS2DEX2 board draw
