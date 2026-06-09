import Foundation

/// Board decision-tree VM — RunDecisionTree @ 0x80044800 (18 opcodes, 12-byte nodes).
public enum DecisionOpcode: UInt8, CaseIterable, Sendable {
    case nop = 0
    case branchIf = 1
    case setFlag = 2
    case showMessage = 3
    case awardCoins = 4
    case movePlayer = 5
    case playSound = 6
    case randomBranch = 7
    case callOverlay = 8
    case waitFrames = 9
    case setSpace = 10
    case end = 11
    case branch = 12
    case itemCheck = 13
    case starCheck = 14
    case cpuBranch = 15
    case minigame = 16
    case boardEvent = 17
}

public struct DecisionNode: Sendable {
    public var opcode: DecisionOpcode
    public var arg0: Int16
    public var arg1: Int16
    public var arg2: Int16
    public var nextOffset: Int32

    public init(data: Data, offset: Int) {
        guard data.count >= offset + 12 else {
            opcode = .end
            arg0 = 0; arg1 = 0; arg2 = 0; nextOffset = 0
            return
        }
        opcode = DecisionOpcode(rawValue: data[offset]) ?? .nop
        arg0 = data.readInt16LE(at: offset + 2)
        arg1 = data.readInt16LE(at: offset + 4)
        arg2 = data.readInt16LE(at: offset + 6)
        nextOffset = data.readInt32LE(at: offset + 8)
    }
}

public struct DecisionTreeVM: Sendable {
    public var nodes: [DecisionNode]
    public var pc: Int = 0
    public var flags: UInt32 = 0

    public init(data: Data) {
        var list: [DecisionNode] = []
        var offset = 0
        while offset + 12 <= data.count {
            list.append(DecisionNode(data: data, offset: offset))
            offset += 12
            if list.count > 4096 { break }
        }
        nodes = list
    }

    public mutating func step(world: GameWorld) -> DecisionStepResult {
        guard pc >= 0, pc < nodes.count else { return .finished }
        let node = nodes[pc]
        switch node.opcode {
        case .nop:
            pc += 1
        case .branchIf:
            pc = node.arg0 != 0 ? Int(node.nextOffset) : pc + 1
        case .setFlag:
            flags |= UInt32(node.arg0)
            pc += 1
        case .awardCoins:
            let idx = Int(world.gwSystem.currentPlayerIndex)
            if idx >= 0, idx < world.players.count {
                world.players[idx].coins += node.arg0
            }
            pc += 1
        case .minigame:
            world.gwSystem.chosenMinigameIndex = node.arg0
            return .requestMinigame(id: UInt8(truncatingIfNeeded: node.arg0))
        case .end:
            return .finished
        default:
            pc += 1
        }
        return .continueRunning
    }
}

public enum DecisionStepResult: Sendable, Equatable {
    case continueRunning
    case finished
    case requestMinigame(id: UInt8)
}

private extension Data {
    func readInt16LE(at offset: Int) -> Int16 {
        let lo = UInt16(self[offset])
        let hi = UInt16(self[offset + 1])
        return Int16(bitPattern: lo | (hi << 8))
    }

    func readInt32LE(at offset: Int) -> Int32 {
        let b0 = UInt32(self[offset])
        let b1 = UInt32(self[offset + 1]) << 8
        let b2 = UInt32(self[offset + 2]) << 16
        let b3 = UInt32(self[offset + 3]) << 24
        return Int32(bitPattern: b0 | b1 | b2 | b3)
    }
}
