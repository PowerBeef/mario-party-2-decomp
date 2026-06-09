#include <metal_stdlib>
using namespace metal;

struct VertexOut {
    float4 position [[position]];
    float4 color;
};

vertex VertexOut mesh_vertex(uint vid [[vertex_id]],
                             constant float *verts [[buffer(0)]]) {
    float3 p = float3(verts[vid * 3], verts[vid * 3 + 1], verts[vid * 3 + 2]);
    VertexOut out;
    out.position = float4(p, 1.0);
    out.color = float4(1.0, 0.85, 0.2, 1.0);
    return out;
}

fragment float4 mesh_fragment(VertexOut in [[stage_in]],
                              constant float4 &clearColor [[buffer(0)]]) {
    return mix(clearColor, in.color, 0.85);
}
