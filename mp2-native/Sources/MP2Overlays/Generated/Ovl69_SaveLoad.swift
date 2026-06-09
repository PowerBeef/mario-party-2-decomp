import Foundation
import MP2Core
import MP2Assets

public final class Ovl69_SaveLoad: StubOverlay, OverlayModule, @unchecked Sendable {
    public static var overlayID: UInt8 { 0x69 }
    public static var name: String { "SaveLoad" }

    public override func enter(context: OverlayContext, event: Int32, stat: Int32) async throws {
        context.world.currentOverlayID = Self.overlayID
    }
}
