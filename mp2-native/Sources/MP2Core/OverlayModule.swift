import Foundation

/// Overlay module contract — replaces PI DMA + jal 0x80102800.
public protocol OverlayModule: AnyObject, Sendable {
    static var overlayID: UInt8 { get }
    static var name: String { get }
    init()
    func enter(context: OverlayContext, event: Int32, stat: Int32) async throws
    func update(context: OverlayContext) async throws
    func exit(context: OverlayContext) async throws
}

public struct OverlayContext: Sendable {
    public var world: GameWorld
    public var heaps: HeapPair
    public var frameIndex: UInt64
    public var host: OverlayHostActions

    public init(
        world: GameWorld,
        heaps: HeapPair,
        frameIndex: UInt64,
        host: OverlayHostActions
    ) {
        self.world = world
        self.heaps = heaps
        self.frameIndex = frameIndex
        self.host = host
    }
}

/// Callbacks overlays use instead of direct om calls.
public struct OverlayHostActions: Sendable {
    public var callOverlay: @Sendable (UInt8, Int32, Int32) async -> Void
    public var gotoOverlay: @Sendable (UInt8, Int32, Int32) async -> Void
    public var returnOverlay: @Sendable () async -> Void

    public init(
        callOverlay: @escaping @Sendable (UInt8, Int32, Int32) async -> Void,
        gotoOverlay: @escaping @Sendable (UInt8, Int32, Int32) async -> Void,
        returnOverlay: @escaping @Sendable () async -> Void
    ) {
        self.callOverlay = callOverlay
        self.gotoOverlay = gotoOverlay
        self.returnOverlay = returnOverlay
    }
}

public typealias OverlayFactory = @Sendable () -> any OverlayModule

public enum OverlayRegistry {
    private static let lock = NSLock()
    private static var factories: [UInt8: OverlayFactory] = [:]
    private static var names: [UInt8: String] = [:]

    public static func register(_ id: UInt8, name: String, factory: @escaping OverlayFactory) {
        lock.lock()
        defer { lock.unlock() }
        factories[id] = factory
        names[id] = name
    }

    public static func create(id: UInt8) -> (any OverlayModule)? {
        lock.lock()
        defer { lock.unlock() }
        return factories[id]?()
    }

    public static func allIDs() -> [UInt8] {
        lock.lock()
        defer { lock.unlock() }
        return factories.keys.sorted()
    }

    public static func name(for id: UInt8) -> String {
        lock.lock()
        defer { lock.unlock() }
        return names[id] ?? "Unknown"
    }

    public static var count: Int {
        lock.lock()
        defer { lock.unlock() }
        return factories.count
    }
}

/// Base stub overlay — provides default empty lifecycle; subclasses conform to OverlayModule.
open class StubOverlay: @unchecked Sendable {
    public required init() {}

    open func enter(context: OverlayContext, event: Int32, stat: Int32) async throws {}
    open func update(context: OverlayContext) async throws {}
    open func exit(context: OverlayContext) async throws {}
}
