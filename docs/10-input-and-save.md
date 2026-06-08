# Input and Save

> **Hardware deep-dive (input/save sub-series):**
> - [hardware/19-input-save-pipeline-overview.md](hardware/19-input-save-pipeline-overview.md) — Full pipeline (SI + EEPROM)
> - [hardware/20-si-controller-hardware.md](hardware/20-si-controller-hardware.md) — PIF, `OSContPad`, rumble
> - [hardware/21-eeprom-save-hardware.md](hardware/21-eeprom-save-hardware.md) — 4K EEPROM blocks and libultra API
> - [hardware/22-mp2-input-save-engine.md](hardware/22-mp2-input-save-engine.md) — Input manager, EEPROM module, checksum
> - [hardware/27-eeprom-save-byte-layout.md](hardware/27-eeprom-save-byte-layout.md) — Staging buffer byte map
> - **Integration deep-dive:** [hardware/38-input-save-engine-integration.md](hardware/38-input-save-engine-integration.md)
> - Summary: [hardware/06-serial-save-interrupts.md](hardware/06-serial-save-interrupts.md)

## Controller Input

Standard libultra controller API:

| Function | VRAM | Role |
|----------|------|------|
| `func_800A2100` | `0x800A2100` | Controller init (detect ports) |
| `osContStartReadData` | `0x800A1FBC` | Begin poll |
| `osContGetReadData` | `0x800A1F20` | Read `OSContPad[4]` @ `D_800FA5E0` |

MP2 wraps polling in the input manager @ **`0x80016BD0`** — processed buttons land in **`D_800D8040`**. Input is sampled each frame by board/minigame processes. CPU players bypass hardware via **`PlayerIsCPU`** @ `0x8005DCA0`.

## Rumble / Accessories

| Function | VRAM | Role |
|----------|------|------|
| `osMotorInit` | `0x800A7420` | Detect rumble pak |
| `osMotorAccess` | `0x800A7668` | Drive motor |
| `func_80016BBC` | `0x80016BBC` | Engine rumble request |

## EEPROM Save

Mario Party 2 uses **4K EEPROM** (`osEeprom*` APIs in main segment).

| Function | VRAM | Role |
|----------|------|------|
| `osEepromProbe` | `0x8009CAD0` | Detect save type |
| `osEepromRead` / `osEepromWrite` | `0x800A8030` / `0x8009C720` | 8-byte block I/O |
| `osEepromLongRead` / `LongWrite` | `0x8009CC40` / `0x8009CB50` | Up to 256 bytes |
| `func_8001ACD0` | `0x8001ACD0` | Load + checksum verify |
| `func_8001B114` | `0x8001B114` | Byte-sum checksum |

Staging buffer: **`D_800D89F0`** (512 bytes).

## Save Contents (partial)

- Party settings (board, turns, characters)
- Records / unlock flags
- `GW_PLAYER` aggregates for story mode progress

Header (8 B) + payload (504 B) layout: [hardware/27-eeprom-save-byte-layout.md](hardware/27-eeprom-save-byte-layout.md). Per-field unlock/record offsets remain partial RE.

## Checksum

**`func_8001B114`** sums EEPROM payload bytes and compares against header table **`D_800C9B60`** — prevents corrupted cartridge writes from loading invalid party state.

## Symbol Sources

PartyPlanner64 `MarioParty2U.sym` documents many board helper VRAM addresses used during save/load UI (`ovl_69_SaveLoad`).
