# Unused libultra: Leo / 64DD

Mario Party 2 is a **cartridge-only** release. The ROM still links a large **Leo (64DD disk drive)** symbol table from the Nintendo 64 SDK — dead code for this build.

## Why It Is in the ROM

Late-1990s Hudson/Nintendo builds often linked **full libultra** objects. Leo drive routines (`LeoBootGame`, `osLeoDiskInit`, `leoSeek`, …) occupy ROM space but are never exercised on a standard cart boot.

## Call Sites in Main Segment

Only **6** `jal`s reach Leo helpers in **`asm/1060.s`**:

| Target | Calls | Likely role |
|--------|-------|-------------|
| **`LeoBootGame2`** | 1 | Drive init stub |
| **`LeoBootGame3`** | 1 | Drive init stub |
| **`LeoDriveExist`** | 2 | Probe for 64DD hardware |
| **`LeoDiskHandle`** | 2 | Disk handle setup |

No overlay references Leo symbols in typical minigame code — gameplay never branches on disk presence.

## Symbol Block

Sample entries in **`symbol_addrs.txt`**:

| Symbol | VRAM |
|--------|------|
| `LeoBootGame` | `0x80099018` |
| `LeoBootGame2` | `0x80098E0C` |
| `LeoBootGame3` | `0x80099150` |
| `osLeoDiskInit` | `0x8009C524` |

Full Leo API spans tens of KB — treat as **SDK ballast**, not MP2 design.

## Expansion Pak (8 MB)

Separate from 64DD: MP2 targets **4 MB RDRAM**.

| Evidence | Detail |
|----------|--------|
| **`osGetMemSize`** | **0** direct `jal`s in main |
| [02-memory-map.md](02-memory-map.md) | Documents 4 MB layout |
| Heap sizing | No alternate paths for 8 MB detected |

MP2 does **not** require Expansion Pak; no extra framebuffer or heap tier is allocated.

## Decompilation Guidance

| Priority | Action |
|----------|--------|
| Low | Leave Leo objects unmatched |
| Medium | `#ifdef` or omit from future slim links |
| N/A | Do not trace Leo for gameplay bugs |

## Related Docs

- [03-boot-and-cartridge.md](03-boot-and-cartridge.md) — Cart boot path
- [02-memory-map.md](02-memory-map.md) — 4 MB RDRAM
- [call-inventory.md](call-inventory.md) — Main-segment API usage
