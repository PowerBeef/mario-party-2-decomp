import Foundation
import MP2Core
import MP2MinigameKit

/// Auto-generated minigame stub — port gameplay from asm/overlays/HandcarHavoc1P
public final class Ovl4F_HandcarHavoc1P: MinigameOverlay, OverlayModule, @unchecked Sendable {
    public static var overlayID: UInt8 { 0x4F }
    public static var name: String { "HandcarHavoc1P" }

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
