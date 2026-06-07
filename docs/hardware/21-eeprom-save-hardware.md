# EEPROM Save Hardware and libultra Protocol

Cartridge **4 Kbit EEPROM** — silicon placement, block addressing, and the libultra APIs Mario Party 2 uses for persistent save data.

## EEPROM in the Cartridge

| Property | Value |
|----------|-------|
| Capacity | **512 bytes** (4096 bits) |
| Access | Same SI/PIF bus as controllers |
| libultra type | `EEPROM_TYPE_4K` — probe returns `0x0080` in upper 16 bits |
| Block size | **8 bytes** per `osEepromRead`/`Write` call |
| Long transfer | Up to **256 bytes** per `osEepromLongRead`/`Write` |

The EEPROM chip is **inside the game cartridge**, not a separate accessory. Only one SI transaction runs at a time — controller polls and EEPROM reads are serialized by libultra.

## libultra EEPROM API

| Function | VRAM | Calls (main) | Role |
|----------|------|--------------|------|
| `osEepromProbe` | `0x8009CAD0` | 2 | Detect save type; retry loop in MP2 |
| `osEepromRead` | `0x800A8030` | 1 | Read one 8-byte block by index |
| `osEepromWrite` | `0x8009C720` | 2 | Write one 8-byte block |
| `osEepromLongRead` | `0x8009CC40` | 2 | Read contiguous bytes (max 256) |
| `osEepromLongWrite` | `0x8009CB50` | 3 | Write contiguous bytes |

### Probe Retry Pattern (MP2 @ `0x8001ACD0`)

MP2 retries **`osEepromProbe`** up to **4 times** before declaring failure — EEPROM can be busy after power-on:

```text
for (i = 0; i < 4; i++)
    if (osEepromProbe(&sCont) == EEPROM_TYPE_4K) break;
if (failed) return error;
```

Return codes used by engine save module:

| Return | Meaning |
|--------|---------|
| `0` | Success |
| `1` | EEPROM detected but data invalid / repair needed |
| `2` | I/O error |

### Long Read/Write Parameters

```c
s32 osEepromLongRead(OSMesgQueue *mq, u8 *buf, s32 offset, s32 size);
s32 osEepromLongWrite(OSMesgQueue *mq, u8 *buf, s32 offset, s32 size);
```

MP2 typical sizes from [`asm/1060.s`](../../asm/1060.s):

| Operation | Offset | Size | Purpose |
|-----------|--------|------|---------|
| Full load | `0` | `0x200` (512) | Entire EEPROM → **`D_800D89F0`** |
| Header write | `0` | `0x8` | Magic + checksum bytes |
| Body write | `0x1F8` | `0x1F8` (504) | Main save payload |

## Physical Block Map (512 Bytes)

```text
+0x000  [  8 B ]  Header block — magic, version, checksum seeds
+0x008  [504 B ]  Game save payload (packed structs)
+0x200  (end)
```

Exact field layout is engine-defined — see [22-mp2-input-save-engine.md](22-mp2-input-save-engine.md). libultra only sees opaque bytes.

## Checksum (Software Layer)

MP2 validates EEPROM with a **simple byte sum**, not CRC32:

| Function | VRAM | Role |
|----------|------|------|
| `func_8001B114` | `0x8001B114` | Sum bytes `[start, start+len)` in staging buffer |
| `D_800C9B60` | `0x800C9B60` | Expected header/checksum reference table |
| `D_800C9B61` | `0x800C9B61` | Valid-save flag byte |

Load path @ **`0x8001ACD0`**: after **`osEepromLongRead`**, compare first **8 bytes** against reference table byte-by-byte; mismatch triggers repair write of defaults.

## Write Endurance and Timing

EEPROM writes are **slow** (~10 ms per block) and **limited** (~100k cycles per cell). MP2:

- Batches writes through **`osEepromLongWrite`** instead of per-field updates
- Runs save from dedicated overlay / HuPrc async worker (**`func_8007EE0C`**) so gameplay does not freeze on SI
- Writes header block separately when updating checksum metadata

## EEPROM vs Flash Pak / Controller Pak

| Storage | MP2 |
|---------|-----|
| 4 Kbit EEPROM | **Primary** — party settings, records |
| Controller Pak (256 Kbit) | Not used for main save |
| Flash Pak | Not supported on N64 retail |

## Error Paths

| Condition | Engine response |
|-----------|-----------------|
| Probe fails 4× | Infinite loop @ `0x8001AD6C` (no EEPROM — dev/piracy trap) or error return |
| LongRead non-zero | Return error code `2` to caller |
| Checksum mismatch | Rewrite defaults via **`osEepromLongWrite`** |
| Write failure | Return `2`; UI overlay shows failure |

## Related Docs

- [19-input-save-pipeline-overview.md](19-input-save-pipeline-overview.md) — Pipeline diagram
- [22-mp2-input-save-engine.md](22-mp2-input-save-engine.md) — Pack/unpack functions
- [06-serial-save-interrupts.md](06-serial-save-interrupts.md) — SI bus shared with controllers
- [../05-game-state.md](../05-game-state.md) — `GW_SYSTEM` fields that serialize
- [input-save-call-inventory.md](input-save-call-inventory.md) — API call counts
