import Foundation
import MP2Core
import MP2Assets

public final class Ovl6C_MinigameSelect: StubOverlay, OverlayModule, @unchecked Sendable {
    public static var overlayID: UInt8 { 0x6C }
    public static var name: String { "MinigameSelect" }

    public override func enter(context: OverlayContext, event: Int32, stat: Int32) async throws {
        context.world.currentOverlayID = Self.overlayID
    }
}
