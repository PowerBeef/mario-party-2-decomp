# Board Decision-Tree VM

How Mario Party 2 evaluates board event scripts — `RunDecisionTree`, 12-byte nodes, and opcode dispatch.

## Entry Point

**`RunDecisionTree`** @ `0x80044800` walks a bytecode stream starting at **`$a0`** until a terminal opcode or failed condition.

| Global | VRAM | Role |
|--------|------|------|
| `D_800F8CE4` | `0x800F8CE4` | Player stat array (halfword per index) |
| `D_800CBC80` | `0x800CBC80` | Board feature ID table |
| `D_80100028` | overlay BSS | Turn counter (decremented by opcode) |

Related board APIs: [../06-board-engine.md](../06-board-engine.md).

## Node Layout

Each instruction is **12 bytes** (`0xC`). The walker advances with **`addiu $s1, $s1, 0xC`** on success paths.

| Offset | Size | Field |
|--------|------|-------|
| `+0` | 1 | Opcode (`0x00`–`0x11`; `>= 0x12` terminates) |
| `+1`–`+3` | 3 | Padding / reserved |
| `+4` | 4 | Primary operand (u32) |
| `+8` | 2 | Secondary operand (u16) |
| `+10` | 2 | Padding |

Termination label **`.L80044CD8`** — fall-through when a branch fails or opcode is out of range.

## Opcode Dispatch

Primary jump table **`jtbl_800D2390`** — **18 handlers** (opcodes `0x00`–`0x11`):

| Opcode | Handler @ | Behavior (from asm) |
|--------|-----------|---------------------|
| `0x01` | `0x80044858` | `PlayerHasCoins` on word @ +4; exit tree if true |
| `0x02` | `0x80044874` | Loop board features 0–6; `IsBoardFeatureDisabled` bitmask test |
| `0x03` | `0x800448C0` | Decrement turn counter @ `D_80100028` |
| `0x04` | `0x800448D0` | Compare player stat (sub-dispatch via **`jtbl_800D23D8`**) |
| `0x05`–`0x11` | `0x800449F0`… | Additional stat / space / item checks |

### Stat Compare Sub-Ops (opcode 4)

**`jtbl_800D23D8`** @ `0x800D23D8` — 6 compare modes on halfword from `D_800F8CE4[player_index]`:

| Sub-op | Condition to continue tree |
|--------|---------------------------|
| 0 | `stat == operand` → **exit** (fail) |
| 1 | `stat != operand` → **exit** |
| 2 | `stat < operand` → **exit** |
| 3 | `stat >= operand` → **exit** |
| 4 | `stat > operand` → **exit** |
| 5 | `stat <= operand` → **exit** |

Operand encoding @ +4: high nibble = sub-op (`0`–`5`), next byte = player index, low 16 bits from +6.

## Event Hydration

**`EventTableHydrate`** loads decision-tree roots from board event tables before spaces fire. Board overlay **`ovl_60_BoardEvents`** and main segment **`ovl_5F_BoardMain`** call **`RunDecisionTree`** (6 combined `jal`s in main).

Typical flow:

```text
Space landing → lookup event ID → EventTableHydrate → RunDecisionTree(script_ptr)
  → branch to minigame / item / coin / warp handler
```

## Script Storage

Decision trees live in **board asset packs** (MainFS volume for active board). They are not interpreted at the C level — only this VM and board overlay glue touch them.

## Debugging Tips

| Technique | Target |
|-----------|--------|
| Break @ `0x80044834` | Every opcode fetch |
| Log `$s1` pointer | Raw 12-byte nodes |
| Watch `D_800F8CE4` | Live player stats during branch |

Full opcode semantics for `0x05`–`0x11` remain partial RE — names follow handler addresses in `1060.s`.

## Related Docs

- [../06-board-engine.md](../06-board-engine.md) — Space graph, items
- [25-mainfs-form-mtnx.md](25-mainfs-form-mtnx.md) — Board pack loading
- [overlay-call-inventory.md](overlay-call-inventory.md) — `RunDecisionTree` in overlays
