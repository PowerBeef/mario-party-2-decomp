import Foundation
import MP2Core
import MP2MinigameKit

public final class Ovl5A_BumperBallMaze1P: MinigameOverlay, OverlayModule, @unchecked Sendable {
    public static var overlayID: UInt8 { 0x5A }
    public static var name: String { "BumperBallMaze1P" }

    public override func minigameLoop(context: OverlayContext) async throws -> MinigameResult {
        var kit = MinigameSession(playerCount: 1, durationFrames: 360)
        while !kit.isFinished(frame: Int(context.frameIndex)) {
            try await Task.sleep(nanoseconds: 16_666_666)
        }
        return kit.score(players: context.world.players)
    }

    public override func onMinigameFinished(context: OverlayContext) async throws {
        awardCoins(context: context, winnerPort: 0, amount: 15)
        await context.host.returnOverlay()
    }
}
