# RNG and Game Randomness

Mario Party 2's global PRNG — **`GetRandomByte`**, LCG state, and gameplay consumers.

## Core PRNG

**`GetRandomByte`** @ `0x80018AFC` — **25** `jal` sites in main segment; many more in overlays.

### Algorithm

Linear congruential generator on 32-bit state **`D_800C99B4`** @ `0x800C99B4`:

```text
state = state * 0x41C64E6D + 0x3039   // stored back to D_800C99B4
return (state + 0x303A) >> 16) & 0xFF
```

| Property | Value |
|----------|-------|
| Multiplier | `0x41C64E6D` (glibc-style LCG constant) |
| Increment | `0x3039` / `0x303A` (split across update and output) |
| Output | **8 bits** per call (`0`–`255`) |

This is a **single global stream** — no per-player or per-minigame seeds in the API.

### Seeding

State is initialized during boot / new game setup (write to **`D_800C99B4`** before first gameplay **`GetRandomByte`**). Exact seed source (frame counter, EEPROM, fixed constant) — trace boot path and **`ovl_64_GameSetup`**.

## Usage Patterns

Callers typically:

```text
roll = GetRandomByte()
if (roll < threshold) { ... }   // probability = threshold/256
index = GetRandomByte() % count
```

| System | Randomness use |
|--------|----------------|
| Board | Star spawn space, happening outcomes, item roulette |
| Minigames | Start positions, AI decisions, prize tables |
| Shop | Item stock (overlay-dependent) |
| Battle | Turn order ties |

Because output is only 8 bits, multi-byte ranges use **multiple calls** or modulo (introduces slight bias when range ∤ 256).

## Fairness Notes

| Topic | Detail |
|-------|--------|
| Single stream | Long board sessions consume shared state — order matters |
| CPU players | Same PRNG as human events (no separate cheat stream) |
| Reproducibility | Fixed seed + deterministic input → replayable (TAS-friendly) |

No hardware RNG (N64 has none). All randomness is software LCG.

## Related Functions

| Symbol | Role |
|--------|------|
| **`GetRandomByte`** | Public 8-bit draw |
| Board decision tree | Uses stats, not direct RNG (see [26-board-decision-tree-vm.md](26-board-decision-tree-vm.md)) |

## Tooling

```bash
grep -c 'jal.*GetRandomByte' asm/1060.s
python3 tools/overlay_xref.py   # per-overlay GetRandomByte counts
```

## Related Docs

- [26-board-decision-tree-vm.md](26-board-decision-tree-vm.md) — Deterministic board branches
- [18-mp2-cpu-engine-scheduling.md](18-mp2-cpu-engine-scheduling.md) — When game logic runs
- [overlay-call-inventory.md](overlay-call-inventory.md) — Overlay RNG usage
