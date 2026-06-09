import Foundation

/// Party session state — mirrors `GW_SYSTEM` @ 0x800F93A8 (0x28 bytes documented).
public struct GwSystem: Codable, Sendable {
    public var unk00: Int16 = 0
    public var currentBoardIndex: Int16 = 0
    public var currentGameLength: Int16 = 0
    public var totalTurns: Int16 = 0
    public var currentTurn: Int16 = 0
    public var unk0A: Int16 = 0
    public var starSpawnIndices: [Int16] = Array(repeating: 0, count: 7)
    public var unk1A: Int16 = 0
    public var unk1C: Int16 = 0
    public var currentPlayerIndex: Int16 = 0
    public var chosenMinigameIndex: Int16 = -1
    public var curPlayerAbsSpaceIndex: Int16 = 0
    public var unk25: Int8 = 0

    public init() {}
}

/// Player state — mirrors `GW_PLAYER` (stride 0x34 on N64).
public struct GwPlayer: Codable, Sendable {
    public var group: UInt8 = 0
    public var cpuDifficulty: UInt8 = 0
    public var cpuDifficulty2: UInt8 = 0
    public var port: UInt8 = 0
    public var character: UInt8 = 0
    public var flags: Int16 = 0
    public var coins: Int16 = 10
    public var coinsMg: Int16 = 0
    public var coinsMgBonus: Int16 = 0
    public var stars: Int16 = 0
    public var curChainIndex: Int16 = 0
    public var curSpaceIndex: Int16 = 0
    public var nextChainIndex: Int16 = 0
    public var nextSpaceIndex: Int16 = 0
    public var item: Int8 = -1
    public var turnStatus: Int8 = 0
    public var playerSpaceColor: UInt8 = 0
    public var coinsTotal: Int16 = 0
    public var coinsMax: Int16 = 0

    public init() {}

    public var isCPU: Bool { (flags & 0x0001) != 0 }
}

/// Overlay history entry — `omOvlHisData`.
public struct OverlayTransition: Codable, Sendable, Equatable {
    public var overlayID: Int32
    public var event: Int16
    public var stat: UInt16

    public init(overlayID: Int32, event: Int16, stat: UInt16) {
        self.overlayID = overlayID
        self.event = event
        self.stat = stat
    }
}

/// Global game world owned by the main thread.
public final class GameWorld: @unchecked Sendable {
    public var gwSystem = GwSystem()
    public var players: [GwPlayer] = Array(repeating: GwPlayer(), count: 4)
    public var currentOverlayID: UInt8 = 0x62
    public var overlayHistory: [OverlayTransition] = []
    public let maxOverlayHistory = 12

    public init() {}

    public func pushHistory(overlayID: UInt8, event: Int32, stat: UInt16) {
        overlayHistory.append(
            OverlayTransition(overlayID: Int32(overlayID), event: Int16(event), stat: stat)
        )
        if overlayHistory.count > maxOverlayHistory {
            overlayHistory.removeFirst()
        }
    }

    public func popHistory() -> OverlayTransition? {
        guard !overlayHistory.isEmpty else { return nil }
        return overlayHistory.removeLast()
    }
}
