# Decompilation Progress

Last updated: automated first-pass bootstrap.

## ROM Baseline

| Metric | Value |
|--------|-------|
| Baserom SHA1 | `166eda1c05670d337e2c3f15a5db528ae1e5d6e3` |
| Segment coverage | **120** splat segments |
| Named symbols | **474** in `symbol_addrs.txt` |
| Overlays cataloged | **115** (`0x00`–`0x72`) |

## Split Statistics (splat 0.41.0)

| Type | Coverage |
|------|----------|
| asm disassembly | ~4 MB (12.8% of ROM) |
| asset bin tail | ~29 MB (87.2%) |
| C matched | In progress |

Integration reference (asm-based): [hardware/32-engine-integration-overview.md](hardware/32-engine-integration-overview.md) — engine ↔ libultra ↔ hardware atlas docs **32–39**.

## Matched / In-Progress C

| Module | File | Status |
|--------|------|--------|
| Perm/temp heap wrappers | [`src/41980.c`](../src/41980.c) | C written, pending GCC match |
| `MakeHeap`/`Malloc`/`Free` | [`src/68460.c`](../src/68460.c) | C written, pending GCC match |
| Globals | [`src/engine/globals.c`](../src/engine/globals.c) | Data definitions |
| Object manager | [`src/engine/om.c`](../src/engine/om.c) | ASM stubs |
| Main menu overlay | [`src/overlays/ovl_63_MainMenu/3E4250.c`](../src/overlays/ovl_63_MainMenu/3E4250.c) | C written |

## Priority Queue

1. Byte-match `MakeHeap` family with GCC 2.7.2
2. `InitProcess` / `SleepProcess` scheduler core
3. `InitObjSys` / `omOvlCallEx` overlay loader
4. Smallest overlays: `ovl_63`, `ovl_5A`, `ovl_3D`
5. Board helpers: `GetSpaceData`, `RunDecisionTree`

## Toolchain Blockers (macOS ARM)

- Bundled `tools/gcc_2.7.2/` is Linux x86 ELF — requires Linux, QEMU, or Docker for matching builds
- `mips-linux-gnu-as` not installed on host — install binutils for asm rebuild

## Verification

```bash
make verify   # segment coverage + baserom SHA1
```

Full byte match requires Linux cross environment — see [`install.sh`](../install.sh).
