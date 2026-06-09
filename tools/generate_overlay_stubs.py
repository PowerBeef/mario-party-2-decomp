#!/usr/bin/env python3
"""Generate Swift overlay modules from docs/12-overlay-catalog.md."""

from __future__ import annotations

import re
import textwrap
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CATALOG = ROOT / "docs" / "12-overlay-catalog.md"
OUT_DIR = ROOT / "mp2-native" / "Sources" / "MP2Overlays" / "Generated"
TIER1_DIR = ROOT / "mp2-native" / "Sources" / "MP2Overlays" / "Tier1"
BOOTSTRAP = ROOT / "mp2-native" / "Sources" / "MP2Overlays" / "OverlayBootstrap.swift"

ROW = re.compile(r"^\| `(?P<id>[0-9A-Fa-f]+)` \| (?P<name>\w+) \|")
TIER1_IDS = {
    0x5E, 0x5F, 0x60, 0x61, 0x62, 0x63, 0x64, 0x65, 0x66, 0x67, 0x68, 0x6A, 0x3D, 0x5A,
}
MINIGAME_MAX = 0x5D


def swift_name(name: str) -> str:
    return re.sub(r"[^A-Za-z0-9]", "", name)


def overlay_class(id_hex: str, name: str) -> str:
    oid = int(id_hex, 16)
    cls = f"Ovl{id_hex.upper()}_{swift_name(name)}"
    if oid <= MINIGAME_MAX and oid not in TIER1_IDS:
        return minigame_class(id_hex, name, cls)
    return stub_class(id_hex, name, cls)


def stub_class(id_hex: str, name: str, cls: str) -> str:
    return textwrap.dedent(
        f"""
        import Foundation
        import MP2Core
        import MP2Assets

        public final class {cls}: StubOverlay, OverlayModule, @unchecked Sendable {{
            public static var overlayID: UInt8 {{ 0x{id_hex.upper()} }}
            public static var name: String {{ "{name}" }}

            public override func enter(context: OverlayContext, event: Int32, stat: Int32) async throws {{
                context.world.currentOverlayID = Self.overlayID
            }}
        }}
        """
    ).strip() + "\n"


def minigame_class(id_hex: str, name: str, cls: str) -> str:
    return textwrap.dedent(
        f"""
        import Foundation
        import MP2Core
        import MP2MinigameKit

        /// Auto-generated minigame stub — port gameplay from asm/overlays/{name}
        public final class {cls}: MinigameOverlay, OverlayModule, @unchecked Sendable {{
            public static var overlayID: UInt8 {{ 0x{id_hex.upper()} }}
            public static var name: String {{ "{name}" }}

            public override func minigameLoop(context: OverlayContext) async throws -> MinigameResult {{
                let players = MinigameVariant.playerCount(for: Self.overlayID)
                var session = MinigameSession(
                    playerCount: players,
                    durationFrames: MinigameCountdown.frames(forSeconds: 30)
                )
                while !session.isFinished(frame: Int(context.frameIndex)) {{
                    try await Task.sleep(nanoseconds: 16_666_666)
                }}
                return session.score(players: context.world.players)
            }}
        }}
        """
    ).strip() + "\n"


def collect_tier1_classes() -> list[str]:
    regs: list[str] = []
    if not TIER1_DIR.is_dir():
        return regs
    for f in sorted(TIER1_DIR.glob("*.swift")):
        text = f.read_text()
        for m in re.finditer(r"public final class (Ovl[0-9A-F]+_\w+)", text):
            cls = m.group(1)
            regs.append(f"        register({cls}.overlayID, name: {cls}.name) {{ {cls}() }}")
    return regs


def main() -> None:
    rows: list[tuple[str, str]] = []
    for line in CATALOG.read_text().splitlines():
        m = ROW.match(line)
        if m:
            rows.append((m.group("id"), m.group("name")))

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    for old in OUT_DIR.glob("Ovl*.swift"):
        old.unlink()

    registrations = collect_tier1_classes()
    tier1_class_names = {r.split("(")[1].split(".")[0] for r in registrations}

    generated = 0
    for id_hex, name in rows:
        cls = f"Ovl{id_hex.upper()}_{swift_name(name)}"
        if cls in tier1_class_names:
            continue
        path = OUT_DIR / f"{cls}.swift"
        path.write_text(overlay_class(id_hex, name))
        registrations.append(
            f"        register({cls}.overlayID, name: {cls}.name) {{ {cls}() }}"
        )
        generated += 1

    registrations = sorted(set(registrations), key=lambda s: s)
    bootstrap = textwrap.dedent(
        f"""
        import Foundation
        import MP2Core

        public enum OverlayBootstrap {{
            public static func registerAll() {{
        {chr(10).join(registrations)}
            }}

            private static func register(_ id: UInt8, name: String, factory: @escaping OverlayFactory) {{
                OverlayRegistry.register(id, name: name, factory: factory)
            }}
        }}
        """
    ).strip() + "\n"
    BOOTSTRAP.write_text(bootstrap)
    print(f"Registered {len(registrations)} overlays ({generated} generated stubs)")


if __name__ == "__main__":
    main()
