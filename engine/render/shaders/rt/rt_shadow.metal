// Metal twin of rt_shadow.hlsl (MSL 2.4, inline `intersection_query`): the same algorithm, the bindings of the contract in the HLSL file
// (the tlas is buffer(0), the output texture(0), the constants buffer(1), the prepass texture(1)). It is compiled at run time with
// MTLDevice newLibraryWithSource (languageVersion 2_4), never by the build. tools/shaders/compile_rt_shaders.sh embeds this text in the
// generated header.
#include <metal_stdlib>
#include <metal_raytracing>
using namespace metal;
using namespace metal::raytracing;

// BEGIN RtEffectParams
struct RtEffectParams {
    float4 camera;
    float4 lightDir;
    float4 image;
    uint4 frame;
    float4 rayO0, rayOX, rayOY, rayD0, rayDX, rayDY;
    float4 uRayO0, uRayOX, uRayOY, uRayD0, uRayDX, uRayDY;
    float4 viewRight, viewUp, viewBack;
    float4 viewProj0, viewProj1, viewProj2, viewProj3;
    float4 user0, user1;
};
// END RtEffectParams

constant float kRtNoMesh = 1.0e30;
constant uint kRtMaskCastsShadow = 0x08;

float3 oct_decode(float2 e) {
    float3 n = float3(e, 1.0 - abs(e.x) - abs(e.y));
    if (n.z < 0.0) n.xy = (1.0 - abs(n.yx)) * float2(n.x >= 0.0 ? 1.0 : -1.0, n.y >= 0.0 ? 1.0 : -1.0);
    return normalize(n);
}

kernel void rt_shadow(instance_acceleration_structure tlas [[buffer(0)]],
                      texture2d<float, access::write> out_img [[texture(0)]],
                      constant RtEffectParams& params [[buffer(1)]],
                      texture2d<float, access::read> prepass [[texture(1)]],
                      uint2 id [[thread_position_in_grid]]) {
    if (id.x >= uint(params.image.x) || id.y >= uint(params.image.y)) return;
    const float4 pre = prepass.read(id);
    if (pre.a < 0.5) {  // the sky: no surface, nothing to shadow
        out_img.write(float4(kRtNoMesh, 1.0, 0.0, 0.0), id);
        return;
    }
    const float depth = pre.r;
    const float2 ndc = float2((float(id.x) + 0.5) * params.image.z * 2.0 - 1.0, 1.0 - (float(id.y) + 0.5) * params.image.w * 2.0);
    const float3 pos = params.rayO0.xyz + ndc.x * params.rayOX.xyz + ndc.y * params.rayOY.xyz +
                       (params.rayD0.xyz + ndc.x * params.rayDX.xyz + ndc.y * params.rayDY.xyz) * depth;
    const float3 nv = oct_decode(pre.gb);
    const float3 n = normalize(params.viewRight.xyz * nv.x + params.viewUp.xyz * nv.y + params.viewBack.xyz * nv.z);
    const float3 l = params.lightDir.xyz;
    const float offset = params.user0.x + params.user0.y * depth;
    ray r;
    r.origin = pos + n * offset;
    r.min_distance = params.user0.z;
    r.direction = l;
    r.max_distance = params.user0.w;
    intersection_query<instancing, triangle_data> q;
    intersection_params ip;
    ip.accept_any_intersection(true);
    q.reset(r, tlas, kRtMaskCastsShadow, ip);
    while (q.next()) {}  // a non-opaque candidate (a cutout) is never committed here
    const float visible = q.get_committed_intersection_type() == intersection_type::triangle ? 0.0 : 1.0;
    out_img.write(float4(depth, visible, 0.0, 1.0), id);
}
