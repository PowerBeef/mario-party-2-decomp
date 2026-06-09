import SwiftUI
import MP2Core
import MP2Runtime
import MP2Graphics
import MP2Platform
import MP2Overlays
import MP2MinigameKit

@main
struct MP2App: App {
    init() {
        OverlayBootstrap.registerAll()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        #if os(macOS)
        .defaultSize(width: 640, height: 480)
        #endif
    }
}

struct ContentView: View {
    @StateObject private var engine = GameEngine(device: MTLCreateSystemDefaultDevice())

    var body: some View {
        VStack(spacing: 0) {
            MetalGameView(renderer: engine.renderer)
                .frame(minWidth: 640, minHeight: 360)
            statusBar
        }
        .onAppear {
            Task {
                await engine.bootstrap()
                engine.start()
            }
        }
        .onDisappear {
            engine.stop()
        }
    }

    private var statusBar: some View {
        HStack {
            Text("Frame: \(engine.frameIndex)")
            Spacer()
            Text("Overlay: \(engine.overlayName) (0x\(String(engine.overlayID, radix: 16)))")
            Spacer()
            Text("Overlays: \(OverlayRegistry.count)/115")
        }
        .font(.system(.caption, design: .monospaced))
        .padding(8)
        .background(Color.black.opacity(0.85))
        .foregroundStyle(.white)
    }
}

#if canImport(Metal)
import Metal
#endif
