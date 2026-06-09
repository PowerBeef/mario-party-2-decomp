import Foundation
import MP2Core
import MP2Assets

/// Main menu — ovl_63, pattern from src/overlays/ovl_63_MainMenu/3E4250.c
public final class Ovl63_MainMenu: StubOverlay, OverlayModule, @unchecked Sendable {
    public static var overlayID: UInt8 { 0x63 }
    public static var name: String { "MainMenu" }
    private var initialized = false

    public override func enter(context: OverlayContext, event: Int32, stat: Int32) async throws {
        if !initialized {
            context.world.gwSystem.unk0A = 7
            initialized = true
        }
    }

    public override func update(context: OverlayContext) async throws {
        if context.frameIndex % 120 == 0 {
            await context.host.gotoOverlay(0x64, 1, 0x192)
        }
    }
}
