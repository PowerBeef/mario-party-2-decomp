import Foundation

/// EEPROM replacement — 512-byte staging buffer @ D_800D89F0 layout compatible.
public final class SaveManager: @unchecked Sendable {
    public static let stagingSize = 512
    public static let payloadSize = 504

    private let fileURL: URL
    public private(set) var staging = Data(count: stagingSize)

    public init(appName: String = "MP2Native") {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = base.appendingPathComponent(appName, isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        fileURL = dir.appendingPathComponent("save.dat")
        load()
    }

    public func load() {
        guard let data = try? Data(contentsOf: fileURL), data.count >= Self.stagingSize else {
            staging = Data(count: Self.stagingSize)
            staging[0] = 0x4D // 'M'
            staging[1] = 0x50 // 'P'
            staging[2] = 0x32 // '2'
            return
        }
        staging = data
    }

    public func save() {
        var copy = staging
        copy[3] = checksum(payload: copy.subdata(in: 8..<Self.stagingSize))
        staging = copy
        try? copy.write(to: fileURL, options: .atomic)
    }

    public func checksum(payload: Data) -> UInt8 {
        var sum: UInt32 = 0
        for b in payload { sum &+= UInt32(b) }
        return UInt8(truncatingIfNeeded: sum)
    }

    public var isValid: Bool {
        staging.count >= Self.stagingSize && staging[3] == checksum(payload: staging.subdata(in: 8..<Self.stagingSize))
    }
}
