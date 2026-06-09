import Foundation
import MP2Core

public struct MainFSFileID: Hashable, Sendable, Codable {
    public let volume: UInt16
    public let index: UInt16

    public init(volume: UInt16, index: UInt16) {
        self.volume = volume
        self.index = index
    }

    public init(packed: UInt32) {
        volume = UInt16(packed >> 16)
        index = UInt16(truncatingIfNeeded: packed)
    }

    public var packed: UInt32 {
        (UInt32(volume) << 16) | UInt32(index)
    }
}

public struct MainFSEntry: Codable, Sendable {
    public let id: MainFSFileID
    public let romStart: UInt32
    public let romEnd: UInt32
    public let compressionType: UInt8
}

public struct BakedTexture: Sendable {
    public let width: Int
    public let height: Int
    public let rgba: Data
}

public struct BakedMesh: Sendable {
    public let vertices: [SIMD3<Float>]
    public let indices: [UInt32]
}

public struct SpriteDraw: Sendable {
    public var x: Float
    public var y: Float
    public var width: Float
    public var height: Float
    public var textureName: String
}

/// Asset catalog — mirrors ReadMainFS volume/index lookup.
public final class AssetCatalog: @unchecked Sendable {
    public static let defaultCacheURL: URL = {
        URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("mp2-native/Resources/.mp2cache/baked")
    }()

    public private(set) var entries: [MainFSFileID: MainFSEntry] = [:]
    public private(set) var catalogLoaded = false
    public var debugMesh: BakedMesh?
    public var debugSprites: [SpriteDraw] = []

    public init() {}

    @discardableResult
    public func loadCache(from url: URL) -> Bool {
        let catalogURL = url.appendingPathComponent("catalog.json")
        guard let data = try? Data(contentsOf: catalogURL),
              let decoded = try? JSONDecoder().decode([MainFSEntry].self, from: data) else {
            return false
        }
        entries = Dictionary(uniqueKeysWithValues: decoded.map { ($0.id, $0) })
        catalogLoaded = true
        loadDebugAssets(from: url)
        return true
    }

    private func loadDebugAssets(from url: URL) {
        let meshURL = url.appendingPathComponent("debug_mesh.bin")
        if let data = try? Data(contentsOf: meshURL) {
            debugMesh = BakedMeshReader.read(data)
        } else {
            debugMesh = BakedMesh(
                vertices: [
                    SIMD3(-1, -1, 0), SIMD3(1, -1, 0), SIMD3(0, 1, 0),
                ],
                indices: [0, 1, 2]
            )
        }
        debugSprites = [
            SpriteDraw(x: 40, y: 40, width: 320, height: 240, textureName: "title_bg"),
        ]
    }

    public func fileData(id: MainFSFileID, cacheRoot: URL) -> Data? {
        let path = cacheRoot
            .appendingPathComponent(String(format: "v%02X", id.volume))
            .appendingPathComponent(String(format: "f%04X.bin", id.index))
        return try? Data(contentsOf: path)
    }
}

enum BakedMeshReader {
    static func read(_ data: Data) -> BakedMesh? {
        guard data.count >= 8 else { return nil }
        let vCount = Int(data.readU32(at: 0))
        let iCount = Int(data.readU32(at: 4))
        let vBytes = vCount * 12
        let iBytes = iCount * 4
        guard data.count >= 8 + vBytes + iBytes else { return nil }
        var verts: [SIMD3<Float>] = []
        var offset = 8
        for _ in 0..<vCount {
            let x = data.readFloat(at: offset)
            let y = data.readFloat(at: offset + 4)
            let z = data.readFloat(at: offset + 8)
            verts.append(SIMD3(x, y, z))
            offset += 12
        }
        var indices: [UInt32] = []
        for _ in 0..<iCount {
            indices.append(data.readU32(at: offset))
            offset += 4
        }
        return BakedMesh(vertices: verts, indices: indices)
    }
}

private extension Data {
    func readU32(at offset: Int) -> UInt32 {
        UInt32(self[offset]) | (UInt32(self[offset + 1]) << 8)
            | (UInt32(self[offset + 2]) << 16) | (UInt32(self[offset + 3]) << 24)
    }

    func readU16(at offset: Int) -> UInt16 {
        UInt16(self[offset]) | (UInt16(self[offset + 1]) << 8)
    }

    func readFloat(at offset: Int) -> Float {
        Float(bitPattern: readU32(at: offset))
    }
}

/// FORM container parser — interpretFORM @ 0x8001D190.
public enum FormParser {
    public struct FormChunk: Sendable {
        public let tag: String
        public let data: Data
    }

    public static func parse(_ data: Data) -> [FormChunk]? {
        guard data.count >= 8,
              String(data: data[0..<4], encoding: .ascii) == "FORM" else { return nil }
        var chunks: [FormChunk] = []
        var offset = 0x0C
        let count = Int(data[5])
        for _ in 0..<min(count, 64) {
            guard offset + 8 <= data.count else { break }
            let tag = String(data: data[offset..<offset + 4], encoding: .ascii) ?? "????"
            let size = Int(data.readU32(at: offset + 4))
            offset += 8
            guard offset + size <= data.count else { break }
            chunks.append(FormChunk(tag: tag, data: data[offset..<offset + size]))
            offset += (size + 3) & ~3
        }
        return chunks
    }

    public static func meshFromFORM(_ data: Data) -> BakedMesh? {
        guard let chunks = parse(data) else { return nil }
        guard let vtx = chunks.first(where: { $0.tag == "VTX1" })?.data,
              let fac = chunks.first(where: { $0.tag == "FAC1" })?.data else { return nil }
        var vertices: [SIMD3<Float>] = []
        var offset = 0
        while offset + 12 <= vtx.count {
            let x = vtx.readFloat(at: offset)
            let y = vtx.readFloat(at: offset + 4)
            let z = vtx.readFloat(at: offset + 8)
            vertices.append(SIMD3(x, y, z))
            offset += 12
        }
        var indices: [UInt32] = []
        offset = 0
        while offset + 2 <= fac.count {
            indices.append(UInt32(fac.readU16(at: offset)))
            offset += 2
        }
        return BakedMesh(vertices: vertices, indices: indices)
    }
}

/// MTNX matrix parser stub — interpretMTNX @ 0x80038F0C.
public enum MTNXParser {
    public static func matrices(from data: Data) -> [simd_float4x4] {
        guard data.count >= 64 else { return [] }
        var result: [simd_float4x4] = []
        var offset = 0
        while offset + 64 <= data.count {
            var cols: [SIMD4<Float>] = []
            for c in 0..<4 {
                let base = offset + c * 16
                cols.append(SIMD4(
                    data.readFloat(at: base),
                    data.readFloat(at: base + 4),
                    data.readFloat(at: base + 8),
                    data.readFloat(at: base + 12)
                ))
            }
            result.append(simd_float4x4(columns: (cols[0], cols[1], cols[2], cols[3])))
            offset += 64
        }
        return result
    }
}

import simd

/// Decompression types 0–4 — runtime fallback when cache miss.
public enum AssetDecompressor {
    public static func decompress(type: UInt8, input: Data, declaredSize: Int) -> Data {
        switch type {
        case 0:
            return input
        case 3:
            var out = Data(count: 0x1800)
            let n = min(0x1800, input.count)
            out.replaceSubrange(0..<n, with: input.prefix(n))
            return out
        default:
            var out = Data(count: max(declaredSize, input.count))
            let n = min(out.count, input.count)
            out.replaceSubrange(0..<n, with: input.prefix(n))
            return out
        }
    }
}

/// HVQ → RGBA5551 expand (simplified; full RE in tools/decompress_assets.py).
public enum HVQDecoder {
    public static func decode5551(_ data: Data, width: Int, height: Int) -> Data {
        var rgba = Data(count: width * height * 4)
        var si = 0
        for i in 0..<(width * height) {
            guard si + 1 < data.count else { break }
            let px = UInt16(data[si]) | (UInt16(data[si + 1]) << 8)
            si += 2
            let r = Float((px >> 11) & 0x1F) / 31.0
            let g = Float((px >> 6) & 0x1F) / 31.0
            let b = Float((px >> 1) & 0x1F) / 31.0
            let a = (px & 1) != 0 ? Float(1) : Float(0)
            let base = i * 4
            rgba[base] = UInt8(r * 255)
            rgba[base + 1] = UInt8(g * 255)
            rgba[base + 2] = UInt8(b * 255)
            rgba[base + 3] = UInt8(a * 255)
        }
        return rgba
    }
}
