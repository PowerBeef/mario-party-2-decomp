# Minigame Framework

Minigames are **self-contained overlays** loaded into VRAM **`0x80102800`** for the duration of a round.

## Lifecycle

1. **Selection** — `ovl_6C_MinigameSelect` or board flow sets `GwSystem.chosenMinigameIndex`.
2. **Load** — `omOvlCallEx(minigameId, event, stat)` DMAs ROM range from overlay table.
3. **Init** — Standard pattern in overlay entry:
   - `InitObjSys(maxObjects, 0)`
   - `InitProcess()` or `HuPrcCreate` for main minigame loop
4. **Run** — Processes + object updates until win condition.
5. **Teardown** — Award coins (`ShowPlayerCoinChange`), `omOvlReturnEx`.

## Entrypoint Pattern

Most overlays begin with a triplet of functions at VRAM `0x80102800+`:

```c
void overlay_init(void);   /* DMA globals, spawn objects */
void overlay_main(void);   /* Process entry */
void overlay_teardown(void);
```

Example matched menu overlay: [`src/overlays/ovl_63_MainMenu/3E4250.c`](../src/overlays/ovl_63_MainMenu/3E4250.c).

## Minigame Categories (by overlay ID)

| IDs | Category |
|-----|----------|
| `0x01`–`0x1F` | 4-player minigames |
| `0x20`–`0x2D` | 1v3 / asymmetric |
| `0x2E`–`0x3D` | 2v2 variants |
| `0x3E`–`0x4D` | 1v1 / duel variants |
| `0x4E`–`0x5D` | 1-player / solo practice |

Full list: [12-overlay-catalog.md](12-overlay-catalog.md).

## Coin Awards

`ShowPlayerCoinChange` (`0x8004CA34`) displays +/- coin UI and updates `GW_PLAYER.coins_mg`.

## Coaster Transitions

`ovl_6E_MinigameCoaster` and `ovl_6D_FinalMinigameCoaster` handle animated transitions between minigame selection and gameplay.

## Matching Status

All minigame overlays disassembled to [`asm/overlays/`](../asm/overlays/). C matching in progress — smallest targets: `ovl_63` (208 B), `ovl_5A` (544 B), `ovl_3D` (576 B).
