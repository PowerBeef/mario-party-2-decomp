import Foundation
import MP2Core
import MP2Platform

/// HuPrc cooperative scheduler — frame-synced, non-preemptive.
public final class ProcessScheduler: @unchecked Sendable {
    private var processes: [GameProcess] = []
    private var runningTasks: [UUID: Task<Void, Never>] = [:]
    private let lock = NSLock()

    public init() {}

    public func spawn(priority: Int16 = 100, stat: UInt16 = 0, body: @escaping @Sendable (ProcessContext) async throws -> Void) {
        let process = GameProcess(priority: priority, stat: stat, body: body)
        lock.lock()
        processes.append(process)
        processes.sort { $0.priority > $1.priority }
        lock.unlock()
    }

    public func killAll() {
        lock.lock()
        for (_, task) in runningTasks { task.cancel() }
        runningTasks.removeAll()
        processes.removeAll()
        lock.unlock()
    }

    public func tick(world: GameWorld, frameIndex: UInt64, clock: FrameClockProvider) async {
        lock.lock()
        let snapshot = processes
        lock.unlock()

        for process in snapshot {
            if process.sleepFramesRemaining > 0 {
                process.sleepFramesRemaining -= 1
                continue
            }
            let ctx = ProcessContext(
                world: world,
                frameIndex: frameIndex,
                waitFrames: { [weak process] frames in
                    process?.sleepFramesRemaining = frames
                },
                waitVerticalBlank: {
                    await clock.nextFrame()
                }
            )
            if runningTasks[process.id] == nil {
                let task = Task {
                    do {
                        try await process.body(ctx)
                    } catch {
                        // Process completed or cancelled
                    }
                }
                lock.lock()
                runningTasks[process.id] = task
                lock.unlock()
            }
        }
    }
}

public protocol FrameClockProvider: Sendable {
    func nextFrame() async
}

extension FrameClock: FrameClockProvider {}
