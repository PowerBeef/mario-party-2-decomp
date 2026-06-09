import Foundation
import MP2Core
import MP2MinigameKit

/// Smallest minigame overlay — ovl_3D LavaTileIsle2P (ROM 0x240 bytes)
public final class Ovl3D_LavaTileIsle2P: MinigameOverlay, OverlayModule, @unchecked Sendable {
    public static var overlayID: UInt8 { 0x3D }
    public static var name: String { "LavaTileIsle2P" }

    public override func minigameLoop(context: OverlayContext) async throws -> MinigameResult {
        var kit = MinigameSession(playerCount: 2, durationFrames: 300)
        while !kit.isFinished(frame: Int(context.frameIndex)) {
            try await Task.sleep(nanoseconds: 16_666_666)
        }
        return kit.score(players: context.world.players)
    }

    public override func onMinigameFinished(context: OverlayContext) async throws {
        awardCoins(context: context, winnerPort: 0, amount: 10)
        await context.host.gotoOverlay(0x70, 0, 0)
    }
}
