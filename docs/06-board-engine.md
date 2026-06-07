# Board Engine

Board gameplay is implemented across **board overlays** (`ovl_5E`–`ovl_61`) plus main-segment helpers for space graphs, events, and items.

## Space Graph

Boards are defined as **chains** of spaces. Each space has:

- Chain index + index within chain
- Absolute space index (unique across board)
- Event script pointer
- Space type (blue, red, happening, star, bowser, …)

| Function | VRAM | Role |
|----------|------|------|
| `GetSpaceData` | `0x80054B8C` | Pointer to space record |
| `GetAbsSpaceIndexFromChainSpaceIndex` | `0x80054BB0` | Chain+index → absolute |
| `SetPlayerOntoChain` | `0x800572E0` | Place player on space |
| `SetNextChainAndSpace` | `0x8005734C` | Queue movement target |
| `RunDecisionTree` | `0x80044800` | Branching event scripts |

> **Bytecode VM detail:** [hardware/26-board-decision-tree-vm.md](hardware/26-board-decision-tree-vm.md) — 12-byte nodes, 18 opcodes.

## Event Hydration

`EventTableHydrate` (`0x8005568C`) copies event table rows into active space data before executing board scripts.

## Items

Item use functions (main segment):

| Item | Function @ VRAM |
|------|-----------------|
| Mushroom | `UseMushroom` `0x8004D6A0` |
| Golden Mushroom | `UseGoldenMushroom` `0x8004D8B0` |
| Skeleton Key | `UseSkeleton_key` `0x8004D734` |
| Plunder Chest | `UsePlunder_chest` `0x8004D758` |
| Bowser Bomb | `UseBowserBomb` `0x8004D780` |
| Dueling Glove | `UseDuelingGlove` `0x8004D7A0` |
| Warp Block | `UseWarpBlock` `0x8004D858` |
| Boo Bell | `UseBooBell` `0x8004D944` |
| Bowser Suit | `UseBowserSuit` `0x8004DA2C` |
| Magic Lamp | `UseMagicLamp` `0x8004DAC4` |

## Messaging

| Function | Role |
|----------|------|
| `ShowMessage` | Character dialog with format args |
| `CloseMessage` | Animated close |
| `RotateCharacterModel` | Turn player toward space |

## Board Assets

Background tiles, 3D models, and animation sets live in the asset ROM region — see [11-asset-formats.md](11-asset-formats.md). PartyPlanner64 documents **animation tile filesystem** replacement for board backgrounds.

## Overlay Mapping

| Overlay | ID | Purpose |
|---------|-----|---------|
| BoardSelect | `0x5E` | Choose board |
| BoardMain | `0x5F` | Primary turn loop |
| BoardEvents | `0x60` | Happening / special events |
| BoardShop | `0x61` | Items / stores |
| BoardIntro | `0x6A` | Pre-game intro |
