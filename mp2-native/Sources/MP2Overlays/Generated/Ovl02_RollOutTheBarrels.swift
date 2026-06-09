import Foundation
import MP2Core
import MP2MinigameKit

/// Auto-generated minigame stub — port gameplay from asm/overlays/RollOutTheBarrels
public final class Ovl02_RollOutTheBarrels: MinigameOverlay, OverlayModule, @unchecked Sendable {
    public static var overlayID: UInt8 { 0x02 }
    public static var name: String { "RollOutTheBarrels" }

    public override func minigameLoop(context: OverlayContext) async throws -> MinigameResult {
        let players = MinigameVariant.playerCount(for: Self.overlayID)
        var session = MinigameSession(
            playerCount: players,
            durationFrames: MinigameCountdown.frames(forSeconds: 30)
        )
        while !session.isFinished(frame: Int(context.frameIndex)) {
            try await Task.sleep(nanoseconds: 16_666_666)
        }
        return session.score(players: context.world.players)
    }
}
