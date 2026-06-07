# Text and Messaging

String tables, message windows, and the CPU draw path for board dialogue and UI text.

## Public API

| Function | VRAM | Arguments |
|----------|------|-----------|
| **`ShowMessage`** | `0x80056368` | `$a0` = character portrait index, `$a1` = string ID, stack = printf-style args |
| **`CloseMessage`** | `0x80056144` | Closes active window with animation |
| **`func_80056188`** | `0x80056188` | Internal formatter / layout (called from ShowMessage) |
| **`func_80055A38`** | `0x80055A38` | String lookup by ID |

Documented in `symbol_addrs.txt`; board glue in [../06-board-engine.md](../06-board-engine.md).

## Message Window State

Globals in main segment:

| Symbol | VRAM | Role |
|--------|------|------|
| **`D_800CC592`** | `0x800CC592` | Message-open flag (set when ShowMessage runs) |
| **`D_800F9052`** | `0x800F9052` | Active window slot index (halfword) |
| **`D_800F920C`** | `0x800F920C` | Pointer to message window array |
| **`D_800F93C6`** | `0x800F93C6` | Current string table index |

### Window Record Stride

From **`ShowMessage`** @ `0x80056368` — per-window struct size **636 bytes** (`0x27C`):

```text
offset = window_index * ((index*5)<<5 - index) << 2
       = window_index * 636
```

Byte **`+0x20`** in each record is a “pending draw” flag set before **`SleepVProcess`**.

## String IDs

Strings are indexed by **16-bit ID** passed in `$a1`. Tables live in MainFS text archives (board-specific packs). **`func_80055A38`** resolves ID → UTF-8/Shift-JIS-style byte string (NTSC ROM uses Latin glyphs).

Format specifiers on the stack mirror C `printf` (%d, %s, etc.) for dynamic coin counts and player names.

## Rendering Path

Text is **not** a simple VI bitmap blit — it goes through the same RCP path as UI:

1. CPU loads glyph metrics from font MainFS (CI or I4 texture atlas)
2. Build GS2DEX2 or sprite display lists per character
3. **`osWritebackDCache`** → RSP task → RDP fill into framebuffer
4. Message box backdrop is a separate DL layer (9-slice or pre-rendered panel)

Exact font file IDs vary by overlay; **`ovl_71_MsgTest`** is a dedicated test harness for message layout.

## Character Portraits

`$a0` indexes the speaking character for portrait art beside the text box (Mario, Luigi, Toad, etc.). `-1` or sentinel values may suppress portrait — verify per call site in board events.

## Overlay Usage

| Overlay | Role |
|---------|------|
| `ovl_5F_BoardMain` | Board space dialogue |
| `ovl_60_BoardEvents` | Event script messages |
| `ovl_71_MsgTest` | Debug message UI |
| Minigame overlays | Instructions via shared API |

See [overlay-call-inventory.md](overlay-call-inventory.md) for per-overlay **`ShowMessage`** counts.

## Related Docs

- [29-fade-and-transitions.md](29-fade-and-transitions.md) — Transitions around message open/close
- [23-asset-pipeline-overview.md](23-asset-pipeline-overview.md) — Font asset load
- [07-graphics-pipeline-overview.md](07-graphics-pipeline-overview.md) — GS2DEX2 UI draw
