import Foundation
import MP2Core

public final class Ovl5E_BoardSelect: StubOverlay, OverlayModule, @unchecked Sendable {
    public static var overlayID: UInt8 { 0x5E }
    public static var name: String { "BoardSelect" }

    public override func update(context: OverlayContext) async throws {
        context.world.gwSystem.currentBoardIndex = 0
        await context.host.gotoOverlay(0x6A, 0, 0)
    }
}

public final class Ovl6A_BoardIntro: StubOverlay, OverlayModule, @unchecked Sendable {
    public static var overlayID: UInt8 { 0x6A }
    public static var name: String { "BoardIntro" }
    private var frames: Int32 = 0

    public override func enter(context: OverlayContext, event: Int32, stat: Int32) async throws {
        frames = 0
        context.world.gwSystem.currentTurn = 0
    }

    public override func update(context: OverlayContext) async throws {
        frames += 1
        if frames > 90 {
            await context.host.gotoOverlay(0x5F, 0, 0)
        }
    }
}

public final class Ovl5F_BoardMain: StubOverlay, OverlayModule, @unchecked Sendable {
    public static var overlayID: UInt8 { 0x5F }
    public static var name: String { "BoardMain" }
    private var turns = 0
    private var vm: DecisionTreeVM?

    public override func enter(context: OverlayContext, event: Int32, stat: Int32) async throws {
        turns = 0
        vm = DecisionTreeVM(data: BoardMainScript.defaultTree)
    }

    public override func update(context: OverlayContext) async throws {
        guard var machine = vm else { return }
        switch machine.step(world: context.world) {
        case .continueRunning:
            vm = machine
        case .finished:
            turns += 1
            context.world.gwSystem.currentTurn = Int16(turns)
            if turns >= 5 {
                await context.host.gotoOverlay(0x3D, 0, 0)
            } else {
                vm = DecisionTreeVM(data: BoardMainScript.defaultTree)
            }
        case .requestMinigame(let id):
            context.world.gwSystem.chosenMinigameIndex = Int16(id)
            await context.host.gotoOverlay(id, 0, 0)
        }
    }
}

public final class Ovl60_BoardEvents: StubOverlay, OverlayModule, @unchecked Sendable {
    public static var overlayID: UInt8 { 0x60 }
    public static var name: String { "BoardEvents" }
    public override func update(context: OverlayContext) async throws {
        await context.host.returnOverlay()
    }
}

public final class Ovl61_BoardShop: StubOverlay, OverlayModule, @unchecked Sendable {
    public static var overlayID: UInt8 { 0x61 }
    public static var name: String { "BoardShop" }
    public override func update(context: OverlayContext) async throws {
        await context.host.returnOverlay()
    }
}

enum BoardMainScript {
    static var defaultTree: Data {
        var d = Data(count: 36)
        d[0] = DecisionOpcode.nop.rawValue
        d[12] = DecisionOpcode.awardCoins.rawValue
        d[14] = 5
        d[24] = DecisionOpcode.minigame.rawValue
        d[26] = 0x3D
        return d
    }
}
