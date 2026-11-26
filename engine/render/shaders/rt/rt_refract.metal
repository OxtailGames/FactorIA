// Metal twin of rt_refract.hlsl (MSL 2.4, inline `intersection_query`): the same algorithm and the same integer sequence for a rough surface's
// cone, the bindings of the contract in the HLSL file (the tlas is buffer(0), the output texture(0), the constants buffer(1), the prepass
// texture(1), the records buffer(8), the hit constants buffer(3)). The hit shading is rt_hit.msli, whose text
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

constant uint kMaxSegments = 6u;
constant float kInv24 = 1.0 / 16777216.0;
constant float kTwoPi = 6.28318530717958647692;

uint pcg(uint v) {
    const uint s = v * 747796405u + 2891336453u;
    const uint w = ((s >> ((s >> 28u) + 4u)) ^ s) * 277803737u;
    return (w >> 22u) ^ w;
}

float unit(uint h) { return float(h >> 8u) * kInv24; }

kernel void rt_refract(instance_acceleration_structure tlas [[buffer(0)]],
                       texture2d<float, access::write> out_img [[texture(0)]],
                       constant RtEffectParams& params [[buffer(1)]],
                       texture2d<float, access::read> prepass [[texture(1)]],
                       const device RtInstanceRecord* records [[buffer(8)]],
                       constant RtHitParams& hit [[buffer(3)]],
                       uint2 id [[thread_position_in_grid]]) {
    if (id.x >= uint(params.image.x) || id.y >= uint(params.image.y)) return;
    const float4 pre = prepass.read(id);
    const float2 ndc = float2((float(id.x) + 0.5) * params.image.z * 2.0 - 1.0, 1.0 - (float(id.y) + 0.5) * params.image.w * 2.0);
    const float3 origin0 = params.rayO0.xyz + ndc.x * params.rayOX.xyz + ndc.y * params.rayOY.xyz;
    const float3 dirPerDepth = params.rayD0.xyz + ndc.x * params.rayDX.xyz + ndc.y * params.rayDY.xyz;
    const float dirLength = max(length(dirPerDepth), 1.0e-6);
    float3 dir = dirPerDepth / dirLength;
    const float tmax = pre.a > 0.5 ? pre.r * dirLength : params.user0.w;
    RtSurface cur;
    if (!rt_trace_surface_mask(tlas, records, hit, origin0, dir, 0.0, tmax, kRtMaskRefractive, cur)) {
        out_img.write(float4(0.0, 0.0, 0.0, 0.0), id);
        return;
    }
    uint state = pcg(id.x + pcg(id.y + pcg(params.frame.y)));
    float3 throughput = float3(1.0, 1.0, 1.0);
    float3 coefInside = float3(0.0, 0.0, 0.0);
    bool inside = false;
    bool spread = false;
    float3 radiance = float3(0.0, 0.0, 0.0);
    bool ended = false;
    bool onSurface = false;
    float3 endPosition = float3(0.0, 0.0, 0.0);
    for (uint seg = 0; seg < kMaxSegments && !ended; ++seg) {
        if (inside) throughput *= exp(-coefInside * cur.t);
        const device RtInstanceRecord& r = records[cur.record];
        if ((r.flags & kRtFlagRefractive) == 0) {
            radiance = rt_shade_hit(tlas, hit, cur, -dir);
            endPosition = cur.position;
            onSurface = true;
            ended = true;
        } else {
            const float ior = clamp(r.volume.x, 1.0, 3.0);
            float3 next = dir;
            if (r.volume.y > 0.0) {
                if (!inside) {
                    const float3 rd = refract(dir, cur.normal, 1.0 / ior);
                    if (dot(rd, rd) > 0.5) next = normalize(rd);
                    inside = true;
                    const float3 att = clamp(r.attenuation.rgb, float3(0.0001, 0.0001, 0.0001), float3(1.0, 1.0, 1.0));
                    coefInside = r.volume.z > 0.0 ? -log(att) / r.volume.z : float3(0.0, 0.0, 0.0);
                } else {
                    const float3 rd = refract(dir, cur.normal, ior);
                    if (dot(rd, rd) > 0.5) {
                        next = normalize(rd);
                        inside = false;
                    } else {
                        next = reflect(dir, cur.normal);
                    }
                }
            }
            if (!spread) {
                spread = true;
                const float rough = saturate(r.roughness);
                if (rough > 0.0) {
                    const float3 up = abs(next.y) < 0.9 ? float3(0.0, 1.0, 0.0) : float3(1.0, 0.0, 0.0);
                    const float3 t1 = normalize(cross(up, next));
                    const float3 t2 = cross(next, t1);
                    state = pcg(state);
                    const float u1 = unit(state);
                    state = pcg(state);
                    const float u2 = unit(state);
                    const float tanSpread = rough * params.user0.z * saturate(2.0 * ior - 2.0);
                    const float rr = sqrt(u1) * tanSpread;
                    const float phi = kTwoPi * u2;
                    next = normalize(next + (t1 * cos(phi) + t2 * sin(phi)) * rr);
                }
            }
            const float3 start = cur.position + next * (params.user0.x + params.user0.y * cur.t);
            dir = next;
            if (!rt_trace_surface_mask(tlas, records, hit, start, dir, 0.0, params.user0.w, kRtMaskSurfaces, cur)) {
                radiance = rt_miss_color(hit, dir);
                ended = true;
            }
        }
    }
    if (!ended) radiance = rt_miss_color(hit, dir);
    if (onSurface) {
        const float4 p4 = float4(endPosition, 1.0);
        const float w = dot(params.viewProj3, p4);
        if (w > 1.0e-4) {
            const float2 q = float2(dot(params.viewProj0, p4), dot(params.viewProj1, p4)) / w;
            const float2 uv = float2(q.x * 0.5 + 0.5, 0.5 - q.y * 0.5);
            if (uv.x >= 0.0 && uv.x < 1.0 && uv.y >= 0.0 && uv.y < 1.0) {
                const uint2 texel = uint2(uv * params.image.xy);
                const float4 there = prepass.read(texel);
                const float depth = dot(endPosition - params.rayO0.xyz, -params.viewBack.xyz);
                if (there.a > 0.5 && abs(there.r - depth) <= 0.02 * depth + 0.05) {
                    const float u = min(floor(uv.x * 4096.0), 4095.0);
                    const float v = min(floor(uv.y * 4096.0), 4095.0);
                    out_img.write(float4(throughput, -(1.0 + u + 4096.0 * v)), id);
                    return;
                }
            }
        }
    }
    out_img.write(float4(radiance * throughput, 1.0), id);
}
