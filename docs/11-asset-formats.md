# Asset Formats

Most game content lives in the ROM **asset tail** (`0x418A50`–`0x1FFFFFF`, ~27 MB).

## MainFS

| Function | VRAM | Role |
|----------|------|------|
| `ReadMainFS` | `0x80017680` | Load file by ID, allocate buffer |
| `FreeMainFS` | `0x80017800` | Release buffer |

MainFS is the primary filesystem for boards, models, textures, and minigame assets. File IDs are referenced from overlay code as immediate constants.

## HVQ Compression

Board backgrounds and UI tiles use **HVQ** (Hudson vector quantization) compression. Decompression routines live in main segment; compressed blobs stored contiguously in ROM.

## Animation Tile Filesystem (MP2-specific)

Board backgrounds support **animated tiles** — sparse replacements for static HVQ tiles.

Per [PartyPlanner64 wiki](https://github.com/PartyPlanner64/PartyPlanner64/wiki/Animation-Filesystem):

| Offset | Field |
|--------|-------|
| `0x0` | `u32 tile_index` — which background tile to replace |
| `0x4` | `u32 compression_type` — always **3** for anim tiles |
| `0x8` | `u32 decompressed_size` — always **0x1800** |
| `0xC` | `u8 compressed_data[]` |

Animation sets are per-board; timer-driven tile swap in board overlay main loop.

## FORM / MTNX Chunks

Symbols `interpretFORM` (`0x8001D190`) and `interpretMTNX` (`0x80038F0C`) parse structured asset containers (model/scene data) — Hudson format predecessors to MainFS entries.

## Compression Type 3

Used for high-frequency tile swaps (animation FS) where decode speed matters more than HVQ ratio.

## Asset ↔ Overlay Binding

Each overlay's `.data` section contains pointers (ROM offsets) into MainFS files loaded at init. splat `asm` output exposes these as `.word` directives.

## Tools

External editors: [PartyPlanner64](https://github.com/PartyPlanner64/PartyPlanner64) reads/writes board FS using documented formats above.
