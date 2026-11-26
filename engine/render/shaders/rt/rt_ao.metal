// Metal twin of rt_ao.hlsl (MSL 2.4, inline `intersection_query`): the same algorithm and the same integer sequence of rays, the bindings of
// the contract in the HLSL file (the tlas is buffer(0), the output texture(0), the constants buffer(1), the prepass texture(1)). It is
// compiled at run time with MTLDevice newLibraryWithSource (languageVersion 2_4), never by the build. tools/shaders/compile_rt_shaders.sh
// embeds this text in the generated header.
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

constant uint kRtMaskOccluders = 0x03;  // kRtMaskOpaque | kRtMaskCutout (rt_records.h)
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

kernel void rt_ao(instance_acceleration_structure tlas [[buffer(0)]],
                  texture2d<float, access::write> out_img [[texture(0)]],
                  constant RtEffectParams& params [[buffer(1)]],
                  texture2d<float, access::read> prepass [[texture(1)]],
                  uint2 id [[thread_position_in_grid]]) {
    if (id.x >= uint(params.image.x) || id.y >= uint(params.image.y)) return;
    const float4 pre = prepass.read(id);
    if (pre.a < 0.5) {  // the sky: nothing to occlude
        out_img.write(float4(1.0, 0.0, 0.0, 0.0), id);
        return;
    }
    const float depth = pre.r;
    const float2 ndc = float2((float(id.x) + 0.5) * params.image.z * 2.0 - 1.0, 1.0 - (float(id.y) + 0.5) * params.image.w * 2.0);
    const float3 pos = params.rayO0.xyz + ndc.x * params.rayOX.xyz + ndc.y * params.rayOY.xyz +
                       (params.rayD0.xyz + ndc.x * params.rayDX.xyz + ndc.y * params.rayDY.xyz) * depth;
    const float3 nv = oct_decode(pre.gb);
    const float3 n = normalize(params.viewRight.xyz * nv.x + params.viewUp.xyz * nv.y + params.viewBack.xyz * nv.z);
    const float sg = n.z >= 0.0 ? 1.0 : -1.0;
    const float ba = -1.0 / (sg + n.z);
    const float bb = n.x * n.y * ba;
    const float3 tx = float3(1.0 + sg * n.x * n.x * ba, sg * bb, -sg * n.x);
    const float3 ty = float3(bb, sg + n.y * n.y * ba, -n.y);

    const uint count = clamp(params.frame.z, 1u, 64u);
    const float invCount = 1.0 / float(count);
    uint state = pcg(id.x + pcg(id.y + pcg(params.frame.y)));
    const float3 origin = pos + n * (params.user0.y + params.user0.z * depth);
    intersection_params ip;
    ip.accept_any_intersection(true);
    ip.force_opacity(forced_opacity::opaque);  // a cutout is not alpha tested here: it occludes as a solid surface
    uint open = 0;
    for (uint i = 0; i < count; ++i) {
        state = pcg(state);
        const float u1 = (float(i) + unit(state)) * invCount;
        state = pcg(state);
        const float u2 = unit(state);
        const float r = sqrt(u1);  // cosine-weighted: the density is cos(theta) / pi
        const float phi = kTwoPi * u2;
        const float3 dir = normalize(tx * (r * cos(phi)) + ty * (r * sin(phi)) + n * sqrt(1.0 - u1));
        ray rr;
        rr.origin = origin;
        rr.min_distance = params.user0.w;
        rr.direction = dir;
        rr.max_distance = params.user0.x;
        intersection_query<instancing, triangle_data> q;
        q.reset(rr, tlas, kRtMaskOccluders, ip);
        while (q.next()) {}
        if (q.get_committed_intersection_type() != intersection_type::triangle) ++open;
    }
    out_img.write(float4(float(open) * invCount, 0.0, 0.0, 1.0), id);
}
