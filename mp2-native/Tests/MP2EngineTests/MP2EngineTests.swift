import XCTest
@testable import MP2Core
@testable import MP2Overlays
@testable import MP2Assets
@testable import MP2MinigameKit

final class MP2EngineTests: XCTestCase {
    func testOverlayRegistryCount() {
        OverlayBootstrap.registerAll()
        XCTAssertEqual(OverlayRegistry.count, 115)
    }

    func testGwSystemRoundTrip() throws {
        var world = GameWorld()
        world.gwSystem.currentBoardIndex = 2
        world.players[0].coins = 42
        let data = try JSONEncoder().encode(world.gwSystem)
        let decoded = try JSONDecoder().decode(GwSystem.self, from: data)
        XCTAssertEqual(decoded.currentBoardIndex, 2)
    }

    func testTempHeapReset() {
        let heaps = HeapPair()
        _ = heaps.temp.allocate(size: 256)
        XCTAssertFalse(heaps.temp.allocate(size: 1).isEmpty)
        heaps.temp.reset()
        _ = heaps.temp.allocate(size: 128)
    }

    func testDecisionTreeMinigameRequest() {
        var d = Data(count: 36)
        d[24] = DecisionOpcode.minigame.rawValue
        d[26] = 0x3D
        var vm = DecisionTreeVM(data: d)
        var world = GameWorld()
        // step through nop and award
        _ = vm.step(world: world)
        _ = vm.step(world: world)
        let result = vm.step(world: world)
        if case .requestMinigame(let id) = result {
            XCTAssertEqual(id, 0x3D)
        } else {
            XCTFail("expected minigame request")
        }
    }

    func testFormParserRejectsGarbage() {
        XCTAssertNil(FormParser.parse(Data([0, 1, 2, 3])))
    }

    func testMinigameVariantPlayerCount() {
        XCTAssertEqual(MinigameVariant.playerCount(for: 0x4E), 1)
        XCTAssertEqual(MinigameVariant.playerCount(for: 0x29), 2)
        XCTAssertEqual(MinigameVariant.playerCount(for: 0x01), 4)
    }
}
