import Foundation
import MP2Core
import MP2Audio

/// om overlay host — replaces omOvlCallEx / GotoEx / ReturnEx + OverlayTeardown.
public final class OverlayHost: @unchecked Sendable {
    public private(set) var currentModule: (any OverlayModule)?
    public private(set) var currentID: UInt8 = 0x62
    public let heaps = HeapPair()
    public var world: GameWorld
    public var frameIndex: UInt64 = 0

    public var onTeardown: (@Sendable () -> Void)?
    public var onOverlayChanged: (@Sendable (UInt8) -> Void)?

    public init(world: GameWorld) {
        self.world = world
    }

    private func teardown() {
        onTeardown?()
        heaps.temp.reset()
    }

    private func hostActions() -> OverlayHostActions {
        OverlayHostActions(
            callOverlay: { [weak self] id, event, stat in
                await self?.call(id, event: event, stat: stat)
            },
            gotoOverlay: { [weak self] id, event, stat in
                await self?.goto(id, event: event, stat: stat)
            },
            returnOverlay: { [weak self] in
                await self?.returnEx()
            }
        )
    }

    private func context() -> OverlayContext {
        OverlayContext(
            world: world,
            heaps: heaps,
            frameIndex: frameIndex,
            host: hostActions()
        )
    }

    public func call(_ id: UInt8, event: Int32, stat: Int32) async {
        if currentModule != nil {
            try? await currentModule?.exit(context: context())
        }
        teardown()
        guard let module = OverlayRegistry.create(id: id) else { return }
        currentModule = module
        currentID = id
        world.currentOverlayID = id
        try? await module.enter(context: context(), event: event, stat: stat)
        onOverlayChanged?(id)
    }

    public func goto(_ id: UInt8, event: Int32, stat: Int32) async {
        world.pushHistory(overlayID: currentID, event: event, stat: UInt16(truncatingIfNeeded: stat))
        await call(id, event: event, stat: stat)
    }

    public func returnEx() async {
        guard let prev = world.popHistory() else { return }
        await call(UInt8(truncatingIfNeeded: prev.overlayID), event: Int32(prev.event), stat: Int32(prev.stat))
    }

    public func update() async {
        guard let module = currentModule else { return }
        try? await module.update(context: context())
    }
}
