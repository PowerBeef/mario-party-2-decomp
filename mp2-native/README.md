# MP2 Native Engine

Swift + Metal reimplementation of the Mario Party 2 Hudson engine for macOS and iOS (Apple Silicon).

## Requirements

- macOS 14+ / iOS 17+
- Xcode 15+ or Swift 5.9+
- User-owned baserom (SHA1 `166eda1c05670d337e2c3f15a5db528ae1e5d6e3`)

## Build (macOS)

```bash
cd mp2-native
swift build
swift run MP2App
```

Open `Package.swift` in Xcode for iOS Simulator/device builds.

## Asset pipeline

Extract assets from baserom (path via `MP2_BASEROM` env or `--rom` flag):

```bash
export MP2_BASEROM=/path/to/marioparty2.z64
python3 ../tools/extract_mainfs.py --rom "$MP2_BASEROM" --out mp2-native/Resources/.mp2cache/raw
python3 ../tools/decompress_assets.py --in mp2-native/Resources/.mp2cache/raw --out mp2-native/Resources/.mp2cache/decompressed
python3 ../tools/parse_form_mtnx.py --in mp2-native/Resources/.mp2cache/decompressed --out mp2-native/Resources/.mp2cache/meshes
python3 ../tools/decode_audio.py --rom "$MP2_BASEROM" --out mp2-native/Resources/.mp2cache/audio
python3 ../tools/bake_metal_assets.py --in mp2-native/Resources/.mp2cache --out mp2-native/Resources/.mp2cache/baked
```

## Architecture

| Module | Role |
|--------|------|
| MP2Core | GwSystem, heaps, overlay protocol, board VM |
| MP2Runtime | HuPrc scheduler, overlay host, main loop |
| MP2Assets | MainFS catalog, FORM/MTNX, baked cache loader |
| MP2Graphics | Metal renderer (sprite, mesh, fade) |
| MP2Audio | AVAudioEngine SFX/music |
| MP2Platform | Frame clock, GameController, save I/O |
| MP2Overlays | 115 overlay modules |
| MP2MinigameKit | Shared minigame patterns |

## Overlay factory

Regenerate overlay stubs from catalog:

```bash
python3 ../tools/generate_overlay_stubs.py
python3 ../tools/overlay_regression.py --checklist
```
