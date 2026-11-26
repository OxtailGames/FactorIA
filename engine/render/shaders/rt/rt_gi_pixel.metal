// Metal twin of rt_gi_pixel.hlsl (MSL 2.4, inline `intersection_query`): the same algorithm, the same integer sequence of rays and the bindings of
// the contract in the HLSL file (the tlas is buffer(0), the output texture(0), the constants buffer(1), the prepass texture(1), the probe atlas
// texture(2), the records buffer(8), the hit constants buffer(3)). It is compiled at run time with MTLDevice newLibraryWithSource
// (languageVersion 2_4), never by the build. tools/shaders/compile_rt_shaders.sh embeds this text in the generated header.
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

// BEGIN RtGiPixelTail
struct RtGiPixelTail {
    uint4 count;
    float4 grid0[4];
    float4 grid1[4];
    float4 grid2[4];
    float4 grid3[4];
};
// END RtGiPixelTail

// BEGIN RtGiPixelParams
struct RtGiPixelParams {
    RtEffectParams e;
    RtGiPixelTail tail;
};
// END RtGiPixelParams

constant float kInv24 = 1.0 / 16777216.0;
constant float kTwoPi = 6.28318530717958647692;

float3 oct_decode(float2 e) {
    float3 n = float3(e, 1.0 - abs(e.x) - abs(e.y));
    if (n.z < 0.0) n.xy = (1.0 - abs(n.yx)) * float2(n.x >= 0.0 ? 1.0 : -1.0, n.y >= 0.0 ? 1.0 : -1.0);
    return normalize(n);
}

uint pcg(uint v) {
    const uint s = v * 747796405u + 2891336453u;
    const uint w = ((s >> ((s >> 28u) + 4u)) ^ s) * 277803737u;
    return (w >> 22u) ^ w;
}

float unit(uint h) { return float(h >> 8u) * kInv24; }

#include "rt_gi_grid.msli"

kernel void rt_gi_pixel(instance_acceleration_structure tlas [[buffer(0)]],
                        texture2d<float, access::write> out_img [[texture(0)]],
                        constant RtGiPixelParams& params [[buffer(1)]],
                        texture2d<float, access::read> prepass [[texture(1)]],
                        texture2d<float, access::read> atlas [[texture(2)]],
                        const device RtInstanceRecord* records [[buffer(8)]],
                        constant RtHitParams& hit [[buffer(3)]],
                        uint2 id [[thread_position_in_grid]]) {
    if (id.x >= uint(params.e.image.x) || id.y >= uint(params.e.image.y)) return;
    const float4 pre = prepass.read(id);
    if (pre.a < 0.5) {  // the sky: no surface to light
        out_img.write(float4(0.0, 0.0, 0.0, 0.0), id);
        return;
    }
    const float depth = pre.r;
    const float2 ndc = float2((float(id.x) + 0.5) * params.e.image.z * 2.0 - 1.0, 1.0 - (float(id.y) + 0.5) * params.e.image.w * 2.0);
    const float3 pos = params.e.rayO0.xyz + ndc.x * params.e.rayOX.xyz + ndc.y * params.e.rayOY.xyz +
                       (params.e.rayD0.xyz + ndc.x * params.e.rayDX.xyz + ndc.y * params.e.rayDY.xyz) * depth;
    const float3 nv = oct_decode(pre.gb);
    const float3 n = normalize(params.e.viewRight.xyz * nv.x + params.e.viewUp.xyz * nv.y + params.e.viewBack.xyz * nv.z);
    const float sg = n.z >= 0.0 ? 1.0 : -1.0;
    const float ba = -1.0 / (sg + n.z);
    const float bb = n.x * n.y * ba;
    const float3 tx = float3(1.0 + sg * n.x * n.x * ba, sg * bb, -sg * n.x);
    const float3 ty = float3(bb, sg + n.y * n.y * ba, -n.y);

    const uint count = clamp(params.e.frame.z, 1u, 64u);
    const float invCount = 1.0 / float(count);
    const uint grids = min(params.tail.count.x, 4u);
    uint state = pcg(id.x + pcg(id.y + pcg(params.e.frame.y)));
    const float3 origin = pos + n * (params.e.user0.y + params.e.user0.z * depth);
    float3 sum = float3(0.0, 0.0, 0.0);
    for (uint i = 0; i < count; ++i) {
        state = pcg(state);
        const float u1 = (float(i) + unit(state)) * invCount;
        state = pcg(state);
        const float u2 = unit(state);
        const float r = sqrt(u1);  // cosine-weighted: the density is cos(theta) / pi
        const float phi = kTwoPi * u2;
        const float3 dir = normalize(tx * (r * cos(phi)) + ty * (r * sin(phi)) + n * sqrt(1.0 - u1));
        RtSurface s;
        float3 color;
        if (rt_trace_surface(tlas, records, hit, origin, dir, params.e.user0.w, params.e.user0.x, s)) {
            color = rt_shade_hit(tlas, hit, s, -dir);
            if (grids > 0 && !s.unlit) {
                float left = 1.0;
                float3 light = float3(0.0, 0.0, 0.0);
                for (uint k = 0; k < grids; ++k) {
                    float cover;
                    const float3 l = gi_grid_light(atlas, params.tail.grid0[k], params.tail.grid1[k], params.tail.grid2[k], params.tail.grid3[k],
                                                   s.position, s.normal, cover);
                    const float share = cover * left;
                    light += l * (params.tail.grid2[k].w * params.tail.grid3[k].x) * share;  // intensity x bounce
                    left -= share;
                    if (left < 0.001) {
                        left = 0.0;
                        break;
                    }
                }
                const float3 diffuse = s.albedo * (1.0 - s.metalness);
                color = max(color + diffuse * (light - hit.ambient.xyz * (1.0 - left)), 0.0);
            }
        } else {
            color = rt_miss_color(hit, dir);
        }
        sum += color;
    }
    out_img.write(float4(sum * invCount, 1.0), id);
}
