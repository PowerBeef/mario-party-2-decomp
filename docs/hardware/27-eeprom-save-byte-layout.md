# EEPROM Save Byte Layout

Reverse-engineered layout of Mario Party 2's 512-byte EEPROM image — staging buffer **`D_800D89F0`**, header, and write blocks.

Save **flow** (load/save state machine, checksum) is in [22-mp2-input-save-engine.md](22-mp2-input-save-engine.md). This doc maps **bytes**.

## Physical EEPROM

| Property | Value |
|----------|-------|
| Capacity | **512 bytes** (4 Kbit) |
| libultra API | `osEepromLongRead` / `osEepromLongWrite` |
| MP2 staging | **`D_800D89F0`** @ `0x800D89F0` (512 B) |

## Load Path (`func_8001ACD0`)

1. **`osEepromLongRead`** — read **0x200** bytes into **`D_800D89F0`**
2. If **`D_800C9B61`** (valid template flag) is set:
   - Compare **`D_800D89F0[0..7]`** vs factory header **`D_800C9B60`**
   - On mismatch: copy **`D_800C9B60` → `D_800D89F0[0..7]`**, zero **`D_800D89F0[8..0x1FF]`**
3. Checksum validation via **`func_8001B114`** before trusting payload

## Staging Buffer Map

| Offset | Size | Name | Notes |
|--------|------|------|-------|
| `0x000`–`0x007` | 8 | **Header / magic** | Compared to **`D_800C9B60`**; written separately on save |
| `0x008`–`0x1FF` | 504 | **Game payload** | Written as one **`osEepromLongWrite`** block (0x1F8 bytes from **`D_800D89F8`**) |
| `0x200` | — | End | Full image = 512 B |

### Header Template

**`D_800C9B60`** @ `0x800C9B60` — 8-byte factory default copied into fresh saves when EEPROM content does not match.

**`D_800C9B61`** @ `0x800C9B61` — `u8` “use template on mismatch” flag (non-zero enables header repair loop).

## Save Path

On commit (after **`func_8001B114`** checksum passes):

1. **`osEepromLongWrite`**, offset **1**, length **0x1F8**, source **`D_800D89F8`** (payload @ byte 8)
2. **`osEepromLongWrite`**, offset **0**, length **8**, source **`D_800D89F0`** (header)

Two-block write ensures header and payload stay consistent if power fails mid-write (header last).

## Checksum

**`func_8001B114`** @ `0x8001B114` — validates payload integrity before load acceptance and before save flush. Exact algorithm (CRC vs sum) — see asm; result gates **`func_8001ACD0`** return codes (`0` = OK, `2` = EEPROM error).

## Known Payload Fields (Partial RE)

High-confidence offsets within **`D_800D89F0[8..]`** (exact field names TBD):

| Region | Suspected content |
|--------|-------------------|
| Early bytes | Unlock flags (boards, minigames, characters) |
| Mid region | Story mode progress, records |
| Late region | Options bits mirrored from **`ovl_68_OptionsMenu`** |

Cross-reference **`ovl_69_SaveLoad`** overlay for UI-facing load/save triggers and which globals are copied into **`D_800D89F0`**.

## Editing Saves

| Rule | Reason |
|------|--------|
| Preserve 8-byte header | Load rejects or resets to template |
| Recompute checksum | **`func_8001B114`** must pass |
| Keep 512-byte size | EEPROM hardware limit |

Community tools (DexDrive, Emulator cheats) should treat **`0x008`–`0x1FF`** as the editable game region until full field RE is complete.

## Related Docs

- [22-mp2-input-save-engine.md](22-mp2-input-save-engine.md) — State machine, globals
- [21-eeprom-save-hardware.md](21-eeprom-save-hardware.md) — SI protocol
- [../10-input-and-save.md](../10-input-and-save.md) — Engine-level save API
