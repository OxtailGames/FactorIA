// Metal twin of rt_shadow_local.hlsl (MSL 2.4, inline `intersection_query`): the same algorithm, the bindings of the contract in the HLSL file
// (the tlas is buffer(0), the output texture(0), the constants buffer(1), the prepass texture(1), the lights buffer(3)). It is compiled at run time
// with MTLDevice newLibraryWithSource (languageVersion 2_4), never by the build. tools/shaders/compile_rt_shaders.sh embeds this text in the
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

// BEGIN RtLocalLight
struct RtLocalLight {
    float4 posReach;
    float4 axisCos;
    float4 kind;
    float4 right;
    float4 up;
};
// END RtLocalLight
struct RtLocalParams {
    float4 header;
    RtLocalLight lights[3];
};

constant uint kRtMaskCastsShadow = 0x08;

float3 oct_decode(float2 e) {
    float3 n = float3(e, 1.0 - abs(e.x) - abs(e.y));
    if (n.z < 0.0) n.xy = (1.0 - abs(n.yx)) * float2(n.x >= 0.0 ? 1.0 : -1.0, n.y >= 0.0 ? 1.0 : -1.0);
    return normalize(n);
}

float ign(float2 p, uint seed) {
    p += 5.588238 * float(seed & 63u);
    return fract(52.9829189 * fract(dot(p, float2(0.06711056, 0.00583715))));
}

float2 sample_2d(uint2 id, uint seed, uint k) {
    const float2 shift = float2(ign(float2(id), seed), ign(float2(id) + float2(37.0, 17.0), seed ^ 0x9E3779B9u));
    return fract(shift + float(k + 1u) * float2(0.7548776662466927, 0.5698402909980532));
}

kernel void rt_shadow_local(instance_acceleration_structure tlas [[buffer(0)]],
                            texture2d<float, access::write> out_img [[texture(0)]],
                            constant RtEffectParams& params [[buffer(1)]],
                            texture2d<float, access::read> prepass [[texture(1)]],
                            constant RtLocalParams& local [[buffer(3)]],
                            uint2 id [[thread_position_in_grid]]) {
    if (id.x >= uint(params.image.x) || id.y >= uint(params.image.y)) return;
    const bool soft = params.user1.y > 0.5;
    const float4 pre = prepass.read(id);
    if (pre.a < 0.5) {  // the sky: no surface, nothing to shadow
        out_img.write(float4(1.0, 1.0, 1.0, 0.0), id);
        return;
    }
    const float depth = pre.r;
    const float2 ndc = float2((float(id.x) + 0.5) * params.image.z * 2.0 - 1.0, 1.0 - (float(id.y) + 0.5) * params.image.w * 2.0);
    const float3 pos = params.rayO0.xyz + ndc.x * params.rayOX.xyz + ndc.y * params.rayOY.xyz +
                       (params.rayD0.xyz + ndc.x * params.rayDX.xyz + ndc.y * params.rayDY.xyz) * depth;
    const float3 nv = oct_decode(pre.gb);
    const float3 n = normalize(params.viewRight.xyz * nv.x + params.viewUp.xyz * nv.y + params.viewBack.xyz * nv.z);
    const float3 origin = pos + n * (params.user0.x + params.user0.y * depth);
    const uint count = min(uint(local.header.x), 3u);
    const float shorter = 1.0 - clamp(local.header.y, 0.0, 0.5);
    float vis[3] = {1.0, 1.0, 1.0};
    for (uint li = 0u; li < count; ++li) {
        const RtLocalLight L = local.lights[li];
        const float3 toLight = L.posReach.xyz - pos;
        const float dist = length(toLight);
        if (dist > L.posReach.w || dist < 1.0e-4) continue;
        const float3 l = toLight / dist;
        const uint kind = uint(L.kind.x + 0.5);
        if (kind == 2u && dot(-l, L.axisCos.xyz) < L.axisCos.w - 0.02) continue;
        if ((kind == 3u || kind == 4u) && dot(-toLight, L.axisCos.xyz) < -0.01) continue;  // a tube shines all around
        const bool area = kind >= 3u;
        const bool softLight = soft && (area ? L.kind.z > 0.0 : L.kind.y > 0.0);
        const uint rays = softLight ? clamp(params.frame.z, 1u, 16u) : 1u;
        const float3 t = normalize(abs(l.y) < 0.99 ? cross(l, float3(0.0, 1.0, 0.0)) : cross(l, float3(1.0, 0.0, 0.0)));
        const float3 b = cross(l, t);
        const uint seed = params.frame.y + 23u * li;
        float lit = 0.0;
        for (uint k = 0u; k < rays; ++k) {
            float3 target = L.posReach.xyz;
            if (softLight) {
                const float2 u = sample_2d(id, seed, k);
                if (!area) {
                    const float r = sqrt(u.x) * L.kind.y * dist, a = 6.283185307179586 * u.y;
                    target += (t * cos(a) + b * sin(a)) * r;
                } else if (kind == 3u) {
                    target += L.right.xyz * ((2.0 * u.x - 1.0) * L.kind.z) + L.up.xyz * ((2.0 * u.y - 1.0) * L.kind.z);
                } else if (kind == 4u) {
                    const float r = sqrt(u.x) * L.kind.z, a = 6.283185307179586 * u.y;
                    target += (L.right.xyz * cos(a) + L.up.xyz * sin(a)) * r;
                } else {
                    float3 across = cross(L.right.xyz, toLight);
                    const float cl = length(across);
                    across = cl > 1.0e-6 ? across / cl : t;
                    target += L.right.xyz * ((2.0 * u.x - 1.0) * L.kind.z) + across * (length(L.up.xyz) * (2.0 * u.y - 1.0) * L.kind.z);
                }
            }
            const float3 v = target - origin;
            const float len = max(length(v), 1.0e-4);
            ray r;
            r.origin = origin;
            r.min_distance = params.user0.z;
            r.direction = v / len;
            r.max_distance = len * shorter;
            intersection_query<instancing, triangle_data> q;
            intersection_params ip;
            ip.accept_any_intersection(true);
            q.reset(r, tlas, kRtMaskCastsShadow, ip);
            while (q.next()) {}  // a non-opaque candidate (a cutout) is never committed here
            lit += q.get_committed_intersection_type() == intersection_type::triangle ? 0.0 : 1.0;
        }
        vis[li] = lit / float(rays);
    }
    out_img.write(float4(vis[0], vis[1], vis[2], 1.0), id);
}
