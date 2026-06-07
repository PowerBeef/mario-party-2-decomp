# Data Structures Reference

Central headers: [`include/common_structs.h`](../include/common_structs.h), [`include/process.h`](../include/process.h).

## `Process` (0x90 bytes)

Cooperative thread context. See [03-process-system.md](03-process-system.md).

## `GW_SYSTEM` @ `0x800F93A8`

Party/session state — board index, turn counters, star spawn table, active player. Size ~`0x28` bytes (partially documented).

## `GW_PLAYER` @ `0x800FD2C0 + i*0x34`

Per-player runtime record: character, coins, stars, board position, held item, space visit counters.

## `omObjData`

Variable-size object header for the object manager:

| Offset | Field |
|--------|-------|
| `0x00` | `stat` — object flags |
| `0x04` | `prio` — update priority |
| `0x14` | `func` — update callback |
| `0x1C` | `data[]` — trailing payload |

## `omOvlHisData` (8 bytes)

Overlay return stack entry: `overlayID`, `event`, `stat`.

## `OverlayTableEntry` (36 bytes)

ROM overlay dispatch row — see [01-memory-map.md](01-memory-map.md).

## `Vec` (12 bytes)

Standard `f32 x,y,z` triple.

## `HeapBlock` (0x10+ bytes)

Doubly-linked heap allocator node — marker `0xA5`, used by `MakeHeap`/`Malloc`/`Free`. See [`include/game/malloc.h`](../include/game/malloc.h).

## Global Symbols

[`include/variables.h`](../include/variables.h) — `GwSystem`, `gPlayers`, heap pointers, overlay history.

## Enum Sets

[`include/enums.h`](../include/enums.h) — character images, item IDs, board IDs.

## Verification Notes

Field offsets derived from:

1. PartyPlanner64 symbol comments
2. Assembly load/store offsets in [`asm/1060.s`](../asm/1060.s)
3. Overlay code referencing `D_800F93AA` etc.

Unverified fields marked in headers with `unk_*` naming convention.
