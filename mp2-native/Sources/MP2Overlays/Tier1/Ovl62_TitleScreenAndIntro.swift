import Foundation
import MP2Core
import MP2Assets

/// Title screen — ovl_62 @ ROM 0x3D4D20
public final class Ovl62_TitleScreenAndIntro: StubOverlay, OverlayModule, @unchecked Sendable {
    public static var overlayID: UInt8 { 0x62 }
    public static var name: String { "TitleScreenAndIntro" }
    private var frames: Int32 = 0

    public override func enter(context: OverlayContext, event: Int32, stat: Int32) async throws {
        frames = 0
        context.world.gwSystem.unk0A = 0
    }

    public override func update(context: OverlayContext) async throws {
        frames += 1
        if frames == 180 {
            await context.host.gotoOverlay(0x63, 1, 0x192)
        }
    }
}
