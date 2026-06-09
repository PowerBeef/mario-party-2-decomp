import Foundation

/// Cooperative process — mirrors N64 Process struct (0x90 bytes).
public final class GameProcess: @unchecked Sendable, Identifiable {
    public let id: UUID
    public var priority: Int16
    public var stat: UInt16
    public var sleepFramesRemaining: Int32
    public weak var parent: GameProcess?
    public var children: [GameProcess] = []
    public let body: @Sendable (ProcessContext) async throws -> Void

    public init(
        priority: Int16 = 100,
        stat: UInt16 = 0,
        body: @escaping @Sendable (ProcessContext) async throws -> Void
    ) {
        self.id = UUID()
        self.priority = priority
        self.stat = stat
        self.sleepFramesRemaining = 0
        self.body = body
    }
}

/// Services exposed to overlay/process code during a frame.
public struct ProcessContext: Sendable {
    public var world: GameWorld
    public var frameIndex: UInt64
    public var waitFrames: (@Sendable (Int32) async -> Void)?
    public var waitVerticalBlank: (@Sendable () async -> Void)?

    public init(
        world: GameWorld,
        frameIndex: UInt64,
        waitFrames: (@Sendable (Int32) async -> Void)? = nil,
        waitVerticalBlank: (@Sendable () async -> Void)? = nil
    ) {
        self.world = world
        self.frameIndex = frameIndex
        self.waitFrames = waitFrames
        self.waitVerticalBlank = waitVerticalBlank
    }
}

public enum ProcessSchedulerError: Error {
    case processFinished
}
