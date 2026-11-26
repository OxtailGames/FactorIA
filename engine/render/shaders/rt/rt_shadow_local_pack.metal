// Metal twin of rt_shadow_local_pack.hlsl (MSL 2.4): packs the ray traced local shadows for the lit pass. Bindings: the output texture(0), the
// constants buffer(1), the sun's image or the prepass texture(1), the visibilities texture(4). Compiled at run time like every rt kernel.
#include <metal_stdlib>
using namespace metal;

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

kernel void rt_shadow_local_pack(texture2d<float, access::write> out_img [[texture(0)]],
                                 constant RtEffectParams& params [[buffer(1)]],
                                 texture2d<float, access::read> src [[texture(1)]],
                                 texture2d<float, access::read> aux [[texture(4)]],
                                 uint2 id [[thread_position_in_grid]]) {
    if (id.x >= uint(params.image.x) || id.y >= uint(params.image.y)) return;
    const float4 s = src.read(id);
    const bool sun = params.user1.x > 0.5;
    if (s.a < 0.5) {
        out_img.write(float4(s.r, 1.0, 16777215.0, 0.0), id);
        return;
    }
    const float3 v = saturate(aux.read(id).rgb);
    const uint count = min(uint(params.user1.y), 3u);
    const float vis[3] = {v.r, v.g, v.b};
    uint bits = 0u;
    for (uint i = 0u; i < 3u; ++i) bits |= (i < count ? uint(vis[i] * 255.0 + 0.5) : 255u) << (8u * i);
    out_img.write(float4(s.r, sun ? s.g : 1.0, float(bits), 1.0), id);
}
