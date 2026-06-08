# Audio

Audio combines **sequenced music** (libaudio sequence player) with **sample SFX** and **character voice** layers.

> **Hardware deep-dive (audio sub-series):**
> - [hardware/11-audio-pipeline-overview.md](hardware/11-audio-pipeline-overview.md) — Full pipeline and MP2 layers
> - [hardware/12-ai-hardware-and-aspMain.md](hardware/12-ai-hardware-and-aspMain.md) — AI DMA, aspMain RSP ucode
> - [hardware/13-libaudio-library.md](hardware/13-libaudio-library.md) — alSyn, alSeqp, alSndp, processing graph
> - [hardware/14-mp2-audio-engine-and-assets.md](hardware/14-mp2-audio-engine-and-assets.md) — PlaySound path, music, ROM banks
> - Summary: [hardware/05-video-and-audio-io.md](hardware/05-video-and-audio-io.md)
> - **Integration deep-dive:** [hardware/37-audio-engine-integration.md](hardware/37-audio-engine-integration.md)

## Key Functions

| Function | VRAM | Role |
|----------|------|------|
| `PlaySound` | `0x80014B14` | Generic SFX by index |
| `func_8000F744` | `0x8000F744` | Background music track (PlayMusic candidate) |
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
