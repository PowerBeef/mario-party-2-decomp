import Foundation

/// PRNG — native stand-in for GetRandomByte @ 0x80018AFC.
public struct MP2Random: Sendable {
    private var state: UInt32

    public init(seed: UInt32 = 0x1234_5678) {
        state = seed == 0 ? 0x1234_5678 : seed
    }

    public mutating func nextByte() -> UInt8 {
        state = state &* 1_103_515_245 &+ 12_345
        return UInt8(truncatingIfNeeded: state >> 16)
    }

    public mutating func nextInt(upperBound: Int) -> Int {
        guard upperBound > 0 else { return 0 }
        return Int(nextByte()) % upperBound
    }
}
