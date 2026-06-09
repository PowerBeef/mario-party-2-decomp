import Foundation
import MP2Core
import MP2Assets

public final class Ovl6B_MinigameInstructions: StubOverlay, OverlayModule, @unchecked Sendable {
    public static var overlayID: UInt8 { 0x6B }
    public static var name: String { "MinigameInstructions" }

    public override func enter(context: OverlayContext, event: Int32, stat: Int32) async throws {
        context.world.currentOverlayID = Self.overlayID
    }
}
