import Foundation
import MP2Core
import MP2Assets

public final class Ovl71_MsgTest: StubOverlay, OverlayModule, @unchecked Sendable {
    public static var overlayID: UInt8 { 0x71 }
    public static var name: String { "MsgTest" }

    public override func enter(context: OverlayContext, event: Int32, stat: Int32) async throws {
        context.world.currentOverlayID = Self.overlayID
    }
}
