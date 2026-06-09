import Foundation
import MP2Core
import MP2MinigameKit

open class MinigameOverlay: StubOverlay, @unchecked Sendable {
    public private(set) var finished = false

    public override required init() {}

    open func minigameLoop(context: OverlayContext) async throws -> MinigameResult {
        MinigameResult(winnerPorts: [0], coinAwards: [10])
    }

    public override func enter(context: OverlayContext, event: Int32, stat: Int32) async throws {
        finished = false
        Task { [weak self] in
            guard let self else { return }
            _ = try await self.minigameLoop(context: context)
            await MainActor.run { self.finished = true }
        }
    }

    public override func update(context: OverlayContext) async throws {
        if finished {
            try await onMinigameFinished(context: context)
            finished = false
        }
    }

    open func onMinigameFinished(context: OverlayContext) async throws {
        awardCoins(context: context, winnerPort: 0, amount: 10)
        await context.host.returnOverlay()
    }

    public func awardCoins(context: OverlayContext, winnerPort: Int, amount: Int16) {
        guard winnerPort >= 0, winnerPort < context.world.players.count else { return }
        context.world.players[winnerPort].coins += amount
        context.world.players[winnerPort].coinsMg = amount
    }
}
