import Foundation
import MP2Core
import MP2Assets

public final class Ovl72_Credits: StubOverlay, OverlayModule, @unchecked Sendable {
    public static var overlayID: UInt8 { 0x72 }
    public static var name: String { "Credits" }

    public override func enter(context: OverlayContext, event: Int32, stat: Int32) async throws {
        context.world.currentOverlayID = Self.overlayID
    }
}
