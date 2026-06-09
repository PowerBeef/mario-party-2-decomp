import Foundation

/// Permanent heap — survives overlay transitions (party state, MainFS buffers).
public final class PermAllocator: @unchecked Sendable {
    private var blocks: [ObjectIdentifier: Any] = [:]
    private var nextID = 0

    public init() {}

    public func allocate<T>(_ value: T) -> T {
        blocks[ObjectIdentifier(value as AnyObject)] = value
        return value
    }

    public func allocateData(count: Int) -> Data {
        let data = Data(count: count)
        nextID += 1
        return data
    }
}

/// Temp heap — reset on every overlay load (matches OverlayTeardown).
public final class TempAllocator: @unchecked Sendable {
    private var storage: [Data] = []

    public init() {}

    public func allocate(size: Int) -> Data {
        let aligned = (size + 15) & ~15
        var data = Data(count: aligned)
        storage.append(data)
        return data
    }

    public func reset() {
        storage.removeAll(keepingCapacity: true)
    }
}

public struct HeapPair: Sendable {
    public let perm: PermAllocator
    public let temp: TempAllocator

    public init() {
        perm = PermAllocator()
        temp = TempAllocator()
    }
}
