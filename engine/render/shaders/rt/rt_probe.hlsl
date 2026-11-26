// Probe kernel of the ray query path (M79): one primary ray per pixel against a TLAS, writes the committed hit distance
// (1000 = a miss). It is the smallest kernel that uses everything an engine RT kernel needs: a TLAS binding, a storage image,
// a constant buffer and an inline `RayQuery` (docs/design/ARCHITECTURE_RENDERING_RAYTRACING_SHADERS.md).
//
// HLSL is the source of the D3D12 (DXIL, cs_6_5) and the Vulkan (SPIR-V, SPV_KHR_ray_query) kernels, both compiled with DXC by
// tools/shaders/compile_rt_shaders.sh; engine/render/shaders/rt/rt_probe.metal is the Metal twin (MSL 2.4, compiled at run
// time). Keep the two the same algorithm: the binding numbers below are the contract of the renderer's bindings.
//
//   binding 0  g_tlas    acceleration structure          (Metal: buffer(0))
//   binding 1  g_out     storage image, r32f             (Metal: texture(0))
//   binding 2  g_params  constant buffer, RtParams       (Metal: buffer(1))
[[vk::binding(0, 0)]] RaytracingAccelerationStructure g_tlas : register(t0);
[[vk::binding(1, 0)]] [[vk::image_format("r32f")]] RWTexture2D<float> g_out : register(u0);
struct RtParams {
    float4 origin;  // xyz: ray origin
    float4 dims;    // xy: image size in pixels
};
[[vk::binding(2, 0)]] ConstantBuffer<RtParams> g_params : register(b0);

[numthreads(8, 8, 1)]
void main(uint3 id : SV_DispatchThreadID) {
    if (id.x >= (uint)g_params.dims.x || id.y >= (uint)g_params.dims.y) return;
    float2 uv = (float2(id.xy) + 0.5) / g_params.dims.xy * 2.0 - 1.0;
    RayDesc ray;
    ray.Origin = g_params.origin.xyz;
    ray.TMin = 0.001;
    ray.Direction = normalize(float3(uv, -1.0));
    ray.TMax = 1000.0;
    RayQuery<RAY_FLAG_FORCE_OPAQUE> q;
    q.TraceRayInline(g_tlas, RAY_FLAG_NONE, 0xFF, ray);
    while (q.Proceed()) {}
    float t = 1000.0;
    if (q.CommittedStatus() == COMMITTED_TRIANGLE_HIT) t = q.CommittedRayT();
    g_out[id.xy] = t;
}
