import Foundation
import MP2Core
import MP2Platform
import MP2Assets
import MP2Graphics
import MP2Audio

/// Main thread loop — doc 34 frame tick order.
@MainActor
public final class GameEngine: ObservableObject {
    @Published public private(set) var frameIndex: UInt64 = 0
    @Published public private(set) var overlayName: String = "TitleScreenAndIntro"
    @Published public private(set) var overlayID: UInt8 = 0x62

    public let world = GameWorld()
    public let clock: FrameClock
    public let scheduler = ProcessScheduler()
    public let overlayHost: OverlayHost
    public let input = InputManager()
    public let save = SaveManager()
    public let assets: AssetCatalog
    public let renderer: MetalRenderer
    public let audio: AudioEngine

    private var running = false
    private var bootstrapped = false

    public init(device: MTLDevice?) {
        #if os(iOS)
        clock = IOSFrameClock()
        #else
        clock = FrameClock()
        #endif
        overlayHost = OverlayHost(world: world)
        assets = AssetCatalog()
        renderer = MetalRenderer(device: device)
        audio = AudioEngine()

        overlayHost.onTeardown = { [weak self] in
            self?.audio.stopAll()
            self?.scheduler.killAll()
        }
        overlayHost.onOverlayChanged = { [weak self] id in
            Task { @MainActor in
                self?.overlayID = id
                self?.overlayName = OverlayRegistry.name(for: id)
            }
        }
    }

    public func bootstrap() async {
        guard !bootstrapped else { return }
        bootstrapped = true
        save.load()
        _ = assets.loadCache(from: AssetCatalog.defaultCacheURL)
        await overlayHost.call(0x62, event: 0, stat: 0)
    }

    public func start() {
        guard !running else { return }
        running = true
        clock.start()
        Task { await runLoop() }
    }

    public func stop() {
        running = false
        clock.stop()
    }

    private func runLoop() async {
        while running {
            await clock.nextFrame()
            frameIndex = clock.frameIndex
            overlayHost.frameIndex = frameIndex

            input.poll()
            await scheduler.tick(world: world, frameIndex: frameIndex, clock: clock)
            await overlayHost.update()
            renderer.buildFrame(graph: makeRenderGraph())
            audio.mixFrame()
        }
    }

    private func makeRenderGraph() -> RenderGraph {
        var graph = RenderGraph()
        graph.clearColor = SIMD4<Float>(0.08, 0.12, 0.35, 1)
        graph.fadeAlpha = 1.0
        if let mesh = assets.debugMesh {
            graph.meshes.append(mesh)
        }
        for sprite in assets.debugSprites {
            graph.sprites.append(sprite)
        }
        return graph
    }
}

#if canImport(Metal)
import Metal
#endif
