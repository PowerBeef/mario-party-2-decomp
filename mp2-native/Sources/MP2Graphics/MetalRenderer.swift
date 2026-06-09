import Foundation
import Metal
import MetalKit
import MP2Assets

public struct RenderGraph: Sendable {
    public var clearColor: SIMD4<Float> = SIMD4(0.1, 0.1, 0.15, 1)
    public var meshes: [BakedMesh] = []
    public var sprites: [SpriteDraw] = []
    public var fadeAlpha: Float = 1.0
    public var text: String = ""

    public init() {}
}

/// Metal renderer — F3DEX2/GS2DEX2 semantic replacement.
@MainActor
public final class MetalRenderer: ObservableObject {
    public let device: MTLDevice?
    private var commandQueue: MTLCommandQueue?
    private var pipeline: MTLRenderPipelineState?
    private var currentGraph = RenderGraph()
    public private(set) var lastDrawableSize: CGSize = .zero

    public init(device: MTLDevice?) {
        self.device = device ?? MTLCreateSystemDefaultDevice()
        if let dev = self.device {
            commandQueue = dev.makeCommandQueue()
            buildPipeline(device: dev)
        }
    }

    private func buildPipeline(device: MTLDevice) {
        let source = """
        #include <metal_stdlib>
        using namespace metal;
        struct VertexOut { float4 position [[position]]; float4 color; };
        vertex VertexOut mesh_vertex(uint vid [[vertex_id]], constant float *verts [[buffer(0)]]) {
            float3 p = float3(verts[vid * 3], verts[vid * 3 + 1], verts[vid * 3 + 2]);
            VertexOut out;
            out.position = float4(p, 1.0);
            out.color = float4(1.0, 0.85, 0.2, 1.0);
            return out;
        }
        fragment float4 mesh_fragment(VertexOut in [[stage_in]], constant float4 &clearColor [[buffer(0)]]) {
            return mix(clearColor, in.color, 0.85);
        }
        """
        let lib = try? device.makeLibrary(source: source, options: nil)
        let desc = MTLRenderPipelineDescriptor()
        desc.vertexFunction = lib?.makeFunction(name: "mesh_vertex")
        desc.fragmentFunction = lib?.makeFunction(name: "mesh_fragment")
        desc.colorAttachments[0].pixelFormat = .bgra8Unorm
        pipeline = try? device.makeRenderPipelineState(descriptor: desc)
    }

    public func buildFrame(graph: RenderGraph) {
        currentGraph = graph
    }

    public func draw(in view: MTKView) {
        guard let drawable = view.currentDrawable,
              let pass = view.currentRenderPassDescriptor,
              let queue = commandQueue,
              let pipeline,
              let cmd = queue.makeCommandBuffer(),
              let enc = cmd.makeRenderCommandEncoder(descriptor: pass) else { return }

        lastDrawableSize = view.drawableSize
        enc.setRenderPipelineState(pipeline)
        var color = currentGraph.clearColor
        color.w *= currentGraph.fadeAlpha
        enc.setFragmentBytes(&color, length: MemoryLayout<SIMD4<Float>>.size, index: 0)

        if let mesh = currentGraph.meshes.first, let device {
            drawMesh(mesh, encoder: enc, device: device)
        }

        enc.endEncoding()
        cmd.present(drawable)
        cmd.commit()
    }

    private func drawMesh(_ mesh: BakedMesh, encoder: MTLRenderCommandEncoder, device: MTLDevice) {
        let vertData = mesh.vertices.flatMap { [$0.x, $0.y, $0.z] }
        guard !vertData.isEmpty,
              let vertBuffer = device.makeBuffer(
                bytes: vertData,
                length: vertData.count * MemoryLayout<Float>.size,
                options: .storageModeShared
              ) else { return }
        encoder.setVertexBuffer(vertBuffer, offset: 0, index: 0)
        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: mesh.vertices.count)
    }
}

#if canImport(SwiftUI)
import SwiftUI

public struct MetalGameView: View {
    @ObservedObject var renderer: MetalRenderer

    public init(renderer: MetalRenderer) {
        self.renderer = renderer
    }

    public var body: some View {
        #if os(macOS)
        MetalViewRepresentable(renderer: renderer)
        #elseif os(iOS)
        MetalViewRepresentable(renderer: renderer)
        #else
        Color.black
        #endif
    }
}

#if os(macOS)
import AppKit

private struct MetalViewRepresentable: NSViewRepresentable {
    @ObservedObject var renderer: MetalRenderer

    func makeNSView(context: Context) -> MTKView {
        let view = MTKView()
        view.device = renderer.device
        view.colorPixelFormat = .bgra8Unorm
        view.preferredFramesPerSecond = 60
        view.enableSetNeedsDisplay = false
        view.isPaused = false
        view.delegate = context.coordinator
        return view
    }

    func updateNSView(_ nsView: MTKView, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(renderer: renderer) }

    final class Coordinator: NSObject, MTKViewDelegate {
        let renderer: MetalRenderer
        init(renderer: MetalRenderer) { self.renderer = renderer }
        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}
        func draw(in view: MTKView) { renderer.draw(in: view) }
    }
}
#endif

#if os(iOS)
import UIKit

private struct MetalViewRepresentable: UIViewRepresentable {
    @ObservedObject var renderer: MetalRenderer

    func makeUIView(context: Context) -> MTKView {
        let view = MTKView()
        view.device = renderer.device
        view.colorPixelFormat = .bgra8Unorm
        view.preferredFramesPerSecond = 60
        view.enableSetNeedsDisplay = false
        view.isPaused = false
        view.delegate = context.coordinator
        return view
    }

    func updateUIView(_ uiView: MTKView, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(renderer: renderer) }

    final class Coordinator: NSObject, MTKViewDelegate {
        let renderer: MetalRenderer
        init(renderer: MetalRenderer) { self.renderer = renderer }
        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}
        func draw(in view: MTKView) { renderer.draw(in: view) }
    }
}
#endif
#endif

import CoreGraphics
