// Metal twin of rt_shadow_pack.hlsl (MSL 2.4): packs the denoised soft sun shadow for the lit pass. Bindings: the output texture(0), the
// constants buffer(1), the soft kernel's image texture(1), the denoiser's output texture(4). Compiled at run time like every rt kernel.
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

kernel void rt_shadow_pack(texture2d<float, access::write> out_img [[texture(0)]],
                           constant RtEffectParams& params [[buffer(1)]],
                           texture2d<float, access::read> src [[texture(1)]],
                           texture2d<float, access::read> aux [[texture(4)]],
                           uint2 id [[thread_position_in_grid]]) {
    if (id.x >= uint(params.image.x) || id.y >= uint(params.image.y)) return;
    const float4 s = src.read(id);
    if (s.a < 0.5) {  // the sky: the hard layout's sentinel
        out_img.write(float4(s.g, 1.0, 0.0, 0.0), id);
        return;
    }
    const float vis = saturate(aux.read(id).r);
    out_img.write(float4(s.g, vis, 0.0, 1.0), id);
}
