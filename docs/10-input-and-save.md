# Input and Save

## Controller Input

Standard libultra controller API:

| Function | Role |
|----------|------|
| `osContInit` | Detect controllers |
| `osContStartReadData` | Begin poll |
| `osContGetReadData` | Read `OSContPad[4]` |

Input is sampled each frame by board/minigame processes. CPU players bypass hardware via `PlayerIsCPU`.

## Rumble / Accessories

`osMotorStart` / `osMotorStop` (if present in symbols) drive Pak rumble for minigame feedback.

## EEPROM Save

Mario Party 2 uses **4K EEPROM** (`osEeprom*` APIs in main segment).

| Function | Role |
|----------|------|
| `osEepromProbe` | Detect save type |
| `osEepromRead` / `osEepromWrite` | Block I/O |
| `osEepromLongRead` / `LongWrite` | Multi-block |
| `GetSaveFileChecksum` | Validate save |

## Save Contents (partial)

- Party settings (board, turns, characters)
- Records / unlock flags
- `GW_PLAYER` aggregates for story mode progress

Exact layout requires further RE of `func_8001B8D0` eeprom module region.

## Checksum

`GetSaveFileChecksum` compares CRC over save blocks before accepting loaded data — prevents corrupted cartridge writes from crashing boot.

## Symbol Sources

PartyPlanner64 `MarioParty2U.sym` documents many board helper VRAM addresses used during save/load UI (`ovl_69_SaveLoad`).
