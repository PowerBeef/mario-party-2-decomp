# Audio

Audio combines **sequenced music** (libultra audio driver) with **sample SFX** and **character voice** layers.

## Key Functions

| Function | VRAM | Role |
|----------|------|------|
| `PlaySound` | `0x80014B14` | Generic SFX by index |
| `PlayMusic` | — | Background music track |
| `PlayCharacterSound` | `0x8007975C` | Character voice (non-overlapping) |

## Character Voice Rule

`PlayCharacterSound` prevents the same character's voice lines from overlapping — important during board dialog and minigame callouts.

## Audio Assets

Sample banks and sequences stored in ROM asset region (`0x418A50+`), referenced by index tables in main segment.

## Hardware Path

Standard N64 path:

1. `osAiSetFrequency` — set DAC rate
2. `osAiSetNextBuffer` — queue PCM buffer
3. Main audio thread in libultra subset

Symbols in `symbol_addrs.txt` under libultra audio (`osAi*`, `aspMain` microcode blob at ROM `0xBF560`).

## Minigame Audio

Each overlay embeds sound index tables for round-specific SFX. Cross-minigame music selection handled by main segment `PlayMusic` before overlay load.
