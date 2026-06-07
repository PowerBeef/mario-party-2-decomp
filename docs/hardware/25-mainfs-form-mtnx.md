# MainFS, FORM, and MTNX

On-disk asset layout and Hudson container parsers — how `ReadMainFS` resolves IDs and how 3D scenes enter RDRAM.

## MainFS File ID

**`ReadMainFS`** @ `0x80017680` expects **`$a0 = (volume << 16) | file_index`**:

| Check | Global | Role |
|-------|--------|------|
| `volume < D_800D81C4` | `0x800D81C4` | Volume count |
| `file_index < D_800D81D0` | `0x800D81D0` | Files in active volume |

### Lookup Chain

**`func_800175D4`** @ `0x800175D4` — core directory resolver:

| `$a0` | Meaning |
|-------|---------|
| `0x2E` | Resolve by file index → ROM offset table **`D_800D81C0`** |
| `0x2F` | Volume-level init via **`func_80017840`** |
| other | Error path |

Returns `{ rom_start, rom_end, ... }` on stack for DMA.

**`func_80017748`**: size = end − start; **`MallocPerm(size & ~1)`**; **`func_80018990`** copies from cart.

### Globals

| Symbol | VRAM | Role |
|--------|------|------|
| `D_800D81C0` | `0x800D81C0` | File offset table base |
| `D_800D81C8` | `0x800D81C8` | Secondary table pointer |
| `D_800D81CC` | `0x800D81CC` | Alt table for type 0x2E |
| `D_800D81D4` | `0x800D81D4` | End pointer table |
| `D_800D81E0` | `0x800D81E0` | Directory root |

PartyPlanner64 documents board FS externally; in-repo RE of full 27 MB table is ongoing.

## FORM Container

**`interpretFORM`** @ `0x8001D190` parses **`"FORM"`** (bytes `0x46, 0x4F` at +0/+1):

```text
struct FormFile {
    char magic[4];      // "FORM"
    u8   version[4];
    u8   chunk_count;   // +5
    // chunk directory at +0xC
};
```

Output **`FormContext`** in `$a0` (caller buffer):

| Offset | Field |
|--------|-------|
| `0x2C` | Pointer to FORM header in RDRAM |
| `0x30` | Current chunk cursor |
| `0x34` | Next chunk ptr |

### Inner Chunk Tags

**`func_8001EA88`** locates sub-chunks by FourCC:

| FourCC | Value | Content |
|--------|-------|---------|
| `VTX1` | `0x56545831` | Vertex buffer |
| `FAC1` | `0x46414331` | Face indices |
| `OBJ1` | `0x4F424A31` | Object nodes |

Parsed pointers stored in **`D_800DEF74`**, **`D_800DEF78`**, etc.

## MTNX — Scene Matrices

**`interpretMTNX`** @ `0x80038F0C` — matrix/scene chunk parser called after FORM load (5 `jal`s in main). Supplies transform data for board pieces and minigame props.

Typical call site pattern in main @ `0x80027A14`:

```text
interpretMTNX(mtnx_ptr)  // after ReadMainFS + FORM
interpretFORM(ctx, form_ptr, ...)
```

## Binding to Overlays

Each overlay `.data` section embeds **MainFS file ID immediates** passed to `ReadMainFS`. splat asm shows these as `lui`/`addiu` + `jal ReadMainFS`.

Overlay-heavy consumers: `ovl_5F_BoardMain`, minigame overlays, `ovl_62_TitleScreenAndIntro`.

## Free Path

**`FreeMainFS`** @ `0x80017800` — mirrors ReadMainFS ID split; calls **`FreePerm`** on pointer. **64** calls in main segment.

## Tools and External References

| Resource | Use |
|----------|-----|
| [PartyPlanner64 wiki](https://github.com/PartyPlanner64/PartyPlanner64/wiki) | Board FS, anim tiles |
| [../11-asset-formats.md](../11-asset-formats.md) | Animation FS layout |
| [overlay-call-inventory.md](overlay-call-inventory.md) | Per-overlay ReadMainFS counts |

## Related Docs

- [23-asset-pipeline-overview.md](23-asset-pipeline-overview.md) — Pipeline summary
- [24-hvq-and-compression.md](24-hvq-and-compression.md) — Post-read decompress
- [14-mp2-audio-engine-and-assets.md](14-mp2-audio-engine-and-assets.md) — Audio banks in same ROM region
