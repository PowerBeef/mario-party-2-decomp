# Fade and Transitions

Screen transition engine — 15 wipe styles, frame timing, and overlay handoff.

## API

| Function | VRAM | Mode byte |
|----------|------|-----------|
| **`InitFadeIn`** | `0x8008F544` | Sets **`D_800F8C56 = 1`** |
| **`InitFadeOut`** | `0x8008F5AC` | Sets **`D_800F8C56 = 2`** |
| **`func_8008F618`** | `0x8008F618` | Query fade active (`D_800F92DC`) |

Arguments (both init functions):

| Reg | Meaning |
|-----|---------|
| `$a0` | Fade type (`0x00`–`0x0E`, or `0xFF` = duration-only) |
| `$a1` | Duration in **frames** (stored as float @ **`D_800FCE88`**) |
| `$a2` | Subtype / color index → **`D_800CDC50`** when type ≠ `0xFF` |

If a fade is already active (`D_800F92DC != 0`), new init calls are **ignored** (early return).

## Fade Types

From `symbol_addrs.txt` comments on **`InitFadeIn`**:

| ID | Name | Typical use |
|----|------|-------------|
| `0x00` | Simple fade | Generic black/white |
| `0x01` | Circle | Iris in/out |
| `0x02` | Star | Star wipe |
| `0x03` | Bowser | Bowser emblem |
| `0x04` | Happening space | Blue happening |
| `0x05` | Chance time | Chance Time |
| `0x06` | Square | Rectangular wipe |
| `0x07` | Explosion | Burst pattern |
| `0x08` | Bob-omb | Bob-omb icon |
| `0x09` | Toad | Toad head |
| `0x0A` | Koopa | Koopa shell |
| `0x0B` | Goomba | Goomba |
| `0x0C` | Shy Guy | Shy Guy |
| `0x0D` | Sun | Day board motif |
| `0x0E` | Moon | Night board motif |

Each type selects a **preauthored mask texture** and RDP fill shader path (rect + alpha blend).

## Runtime State

| Global | VRAM | Role |
|--------|------|------|
| **`D_800F92DC`** | `0x800F92DC` | Fade active (`1` while running) |
| **`D_800F8C56`** | `0x800F8C56` | Direction: `1` = in, `2` = out |
| **`D_800CDC50`** | `0x800CDC50` | Active fade type |
| **`D_800FCE88`** | `0x800FCE88` | Duration (float, frames) |
| **`D_80101054`** | `0x80101054` | Progress counter (reset on init) |
| **`D_800F9D20`** | `0x800F9D20` | Sub-state for mask animation |

## Per-Frame Update

Fade logic runs in the main graphics thread (HuPrc process tied to board/menu overlays):

1. Increment progress @ **`D_80101054`**
2. Scale mask alpha by `progress / duration`
3. Issue RDP **`FillRectangle`** or textured tris over framebuffer
4. On completion: clear **`D_800F92DC`**, optionally swap overlay

Board → minigame transitions pair **`InitFadeOut`** (board) with overlay load + **`InitFadeIn`** (minigame).

## RDP Interaction

Wipes use **copy/fill modes** on the current VI framebuffer — see [09-rdp-framebuffers-pixel-formats.md](09-rdp-framebuffers-pixel-formats.md). Z-buffer is usually disabled for full-screen overlays.

Mask textures are loaded from MainFS (small CI blobs); CPU decompress may use type 2/3 before upload.

## Related Docs

- [../08-rendering.md](../08-rendering.md) — Engine rendering index
- [28-text-and-messaging.md](28-text-and-messaging.md) — Message box timing
- [07-graphics-pipeline-overview.md](07-graphics-pipeline-overview.md) — Frame timeline
