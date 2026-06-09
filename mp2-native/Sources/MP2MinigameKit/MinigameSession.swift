import Foundation
import MP2Core

public struct MinigameResult: Sendable {
    public var winnerPorts: [Int]
    public var coinAwards: [Int16]

    public init(winnerPorts: [Int], coinAwards: [Int16]) {
        self.winnerPorts = winnerPorts
        self.coinAwards = coinAwards
    }
}

public struct MinigameSession: Sendable {
    public let playerCount: Int
    public let durationFrames: Int
    private var startFrame: Int?

    public init(playerCount: Int, durationFrames: Int) {
        self.playerCount = playerCount
        self.durationFrames = durationFrames
    }

    public mutating func isFinished(frame: Int) -> Bool {
        if startFrame == nil { startFrame = frame }
        guard let start = startFrame else { return false }
        return frame - start >= durationFrames
    }

    public func score(players: [GwPlayer]) -> MinigameResult {
        var winner = 0
        var best: Int16 = Int16.min
        for i in 0..<min(playerCount, players.count) {
            if players[i].coinsMg > best {
                best = players[i].coinsMg
                winner = i
            }
        }
        return MinigameResult(winnerPorts: [winner], coinAwards: [10])
    }
}

public enum MinigameCountdown {
    public static func frames(forSeconds seconds: Int) -> Int { seconds * 60 }
}

/// Base class for 1P/2P/4P variant sharing — maps overlay ID to player count.
public enum MinigameVariant {
    public static func playerCount(for overlayID: UInt8) -> Int {
        if overlayID >= 0x4E && overlayID <= 0x5D { return 1 }
        if overlayID >= 0x29 && overlayID <= 0x4D { return 2 }
        return 4
    }

    public static func baseID(for overlayID: UInt8) -> UInt8 {
        if overlayID >= 0x4E { return overlayID - 0x4E + 0x01 }
        if overlayID >= 0x29 { return overlayID - 0x29 + 0x01 }
        return overlayID
    }
}
