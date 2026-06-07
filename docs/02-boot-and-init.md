# Boot and Initialization

## Hardware Entry

| Stage | ROM | VRAM | Notes |
|-------|-----|------|-------|
| IPL | `0x40` | — | Loads entry segment |
| Entrypoint | `0x1000` | `0x80000400` | Sets up GP, SP, jumps to main |

Disassembly: [`asm/entrypoint.s`](../asm/entrypoint.s), [`asm/1060.s`](../asm/1060.s).

## Main-Segment Init Order (observed)

1. **libultra** — threads, PI/SI/VI managers, message queues (`osCreateThread`, `osViSetMode`, …).
2. **Heaps** — `MakePermHeap` / `MakeTempHeap` wrap `MakeHeap` (`0x80068460`).
3. **Object system** — `InitObjSys` (`0x800760C0`) allocates `omObjData` pool.
4. **Process system** — `InitProcess` (`0x80076E64`) prepares cooperative thread slots.
5. **First overlay** — `omOvlCallEx` loads title (`ovl_62`) or debug (`ovl_00`).

## Title → Menu Path

`ovl_62_TitleScreenAndIntro` transitions into `ovl_63_MainMenu` via `omOvlGotoEx` / `omOvlCallEx` with overlay ID **`0x63`**.

Matched C for menu bootstrap: [`src/overlays/ovl_63_MainMenu/3E4250.c`](../src/overlays/ovl_63_MainMenu/3E4250.c).

## Global Pointers Initialized Early

| Variable | VRAM | Set by |
|----------|------|--------|
| `permHeapPtr` | `0x800DEFD0` | `MakePermHeap` |
| `tempHeapPtr` | `0x800DEFD4` | `MakeTempHeap` |
| `GwSystem` | `0x800F93A8` | board/menu overlays |

## Known Unknowns

- Exact order of MainFS mount vs first overlay load
- Full `__osInitialize` call tree (standard libultra subset in main segment)
