// Metal twin of rt_probe.hlsl (MSL 2.4, inline `intersection_query`): the same algorithm, the bindings of the contract in the
// HLSL file. It is compiled at run time with MTLDevice newLibraryWithSource (languageVersion 2_4), never by the build: the Metal
// toolchain is not needed to build the engine. tools/shaders/compile_rt_shaders.sh embeds this text in the generated header.
#include <metal_stdlib>
#include <metal_raytracing>
using namespace metal;
using namespace metal::raytracing;

struct RtParams {
    float4 origin;
    float4 dims;
};

kernel void rt_probe(instance_acceleration_structure tlas [[buffer(0)]],
                     texture2d<float, access::write> out_img [[texture(0)]],
                     constant RtParams& params [[buffer(1)]],
                     uint2 id [[thread_position_in_grid]]) {
    if (id.x >= uint(params.dims.x) || id.y >= uint(params.dims.y)) return;
    float2 uv = (float2(id) + 0.5) / params.dims.xy * 2.0 - 1.0;
    ray r;
    r.origin = params.origin.xyz;
    r.min_distance = 0.001;
    r.direction = normalize(float3(uv, -1.0));
    r.max_distance = 1000.0;
    intersection_query<instancing, triangle_data> q;
    intersection_params params_q;
    params_q.force_opacity(forced_opacity::opaque);
    q.reset(r, tlas, 0xFF, params_q);
    while (q.next()) {}
    float t = 1000.0;
    if (q.get_committed_intersection_type() == intersection_type::triangle) t = q.get_committed_distance();
    out_img.write(float4(t), id);
}
