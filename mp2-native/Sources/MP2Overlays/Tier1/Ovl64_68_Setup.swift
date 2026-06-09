import Foundation
import MP2Core

public final class Ovl64_GameSetup: StubOverlay, OverlayModule, @unchecked Sendable {
    public static var overlayID: UInt8 { 0x64 }
    public static var name: String { "GameSetup" }

    public override func update(context: OverlayContext) async throws {
        for i in 0..<4 {
            context.world.players[i].port = UInt8(i)
            context.world.players[i].coins = 10
        }
        context.world.gwSystem.currentBoardIndex = 0
        await context.host.gotoOverlay(0x5E, 0, 0)
    }
}

public final class Ovl65_MinigameLand: StubOverlay, OverlayModule, @unchecked Sendable {
    public static var overlayID: UInt8 { 0x65 }
    public static var name: String { "MinigameLand" }
    public override func update(context: OverlayContext) async throws {
        await context.host.returnOverlay()
    }
}

public final class Ovl66_BattleMinigame: StubOverlay, OverlayModule, @unchecked Sendable {
    public static var overlayID: UInt8 { 0x66 }
    public static var name: String { "BattleMinigame" }
    public override func update(context: OverlayContext) async throws {
        await context.host.gotoOverlay(0x3D, 0, 0)
    }
}

public final class Ovl67_StoryMode: StubOverlay, OverlayModule, @unchecked Sendable {
    public static var overlayID: UInt8 { 0x67 }
    public static var name: String { "StoryMode" }
    public override func update(context: OverlayContext) async throws {
        await context.host.gotoOverlay(0x5E, 0, 0)
    }
}

public final class Ovl68_OptionsMenu: StubOverlay, OverlayModule, @unchecked Sendable {
    public static var overlayID: UInt8 { 0x68 }
    public static var name: String { "OptionsMenu" }
    public override func update(context: OverlayContext) async throws {
        await context.host.returnOverlay()
    }
}

public final class Ovl70_Results: StubOverlay, OverlayModule, @unchecked Sendable {
    public static var overlayID: UInt8 { 0x70 }
    public static var name: String { "Results" }
    public override func update(context: OverlayContext) async throws {
        await context.host.gotoOverlay(0x63, 0, 0)
    }
}
