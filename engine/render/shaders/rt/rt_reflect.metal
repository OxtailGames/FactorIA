// Metal twin of rt_reflect.hlsl (MSL 2.4, inline `intersection_query`): the same algorithm, the bindings of the contract in the HLSL file
// (the tlas is buffer(0), the output texture(0), the constants buffer(1), the prepass texture(1), the records buffer(8), the G-buffer's
// albedo texture(2) and material texture(3), the hit constants buffer(3)). The hit shading is rt_hit.msli, whose text
// tools/shaders/compile_rt_shaders.sh puts at the `#include` below. It is compiled at run time with MTLDevice newLibraryWithSource
// (languageVersion 2_4), never by the build.
#include <metal_stdlib>
#include <metal_raytracing>
using namespace metal;
using namespace metal::raytracing;

#include "rt_hit.msli"

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

float3 oct_decode(float2 e) {
    float3 n = float3(e, 1.0 - abs(e.x) - abs(e.y));
    if (n.z < 0.0) n.xy = (1.0 - abs(n.yx)) * float2(n.x >= 0.0 ? 1.0 : -1.0, n.y >= 0.0 ? 1.0 : -1.0);
    return normalize(n);
}

kernel void rt_reflect(instance_acceleration_structure tlas [[buffer(0)]],
                       texture2d<float, access::write> out_img [[texture(0)]],
                       constant RtEffectParams& params [[buffer(1)]],
                       texture2d<float, access::read> prepass [[texture(1)]],
                       const device RtInstanceRecord* records [[buffer(8)]],
                       texture2d<float, access::read> albedo_img [[texture(2)]],
                       texture2d<float, access::read> material_img [[texture(3)]],
                       constant RtHitParams& hit [[buffer(3)]],
                       uint2 id [[thread_position_in_grid]]) {
    if (id.x >= uint(params.image.x) || id.y >= uint(params.image.y)) return;
    const float4 pre = prepass.read(id);
    const float4 mat = material_img.read(id);
    if (pre.a < 0.5 || mat.a < 0.5 || mat.r >= params.user0.z) {  // the sky, no G-buffer texel, a surface too rough for a mirror
        out_img.write(float4(0.0, 0.0, 0.0, 0.0), id);
        return;
    }
    const float depth = pre.r;
    const float2 ndc = float2((float(id.x) + 0.5) * params.image.z * 2.0 - 1.0, 1.0 - (float(id.y) + 0.5) * params.image.w * 2.0);
    const float3 pos = params.rayO0.xyz + ndc.x * params.rayOX.xyz + ndc.y * params.rayOY.xyz +
                       (params.rayD0.xyz + ndc.x * params.rayDX.xyz + ndc.y * params.rayDY.xyz) * depth;
    const float3 nv = oct_decode(pre.gb);
    const float3 n = normalize(params.viewRight.xyz * nv.x + params.viewUp.xyz * nv.y + params.viewBack.xyz * nv.z);
    const float3 view = params.camera.w > 0.5 ? -params.viewBack.xyz : normalize(pos - params.camera.xyz);
    const float3 r = reflect(view, n);
    const float3 tint = mix(float3(1.0, 1.0, 1.0), albedo_img.read(id).rgb, saturate(mat.g));
    const float offset = params.user0.x + params.user0.y * depth;
    RtSurface s;
    if (rt_trace_surface(tlas, records, hit, pos + n * offset, r, 0.0, params.user0.w, s)) {
        out_img.write(float4(rt_shade_hit(tlas, hit, s, -r) * tint, max(s.t, 0.0001)), id);
    } else {
        out_img.write(float4(rt_miss_color(hit, r) * tint, -1.0), id);
    }
}
