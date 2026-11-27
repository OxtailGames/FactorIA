// Metal twin of rt_gi.hlsl (MSL 2.4, inline `intersection_query`): the same algorithm, the same integer draws and the bindings of the
// contract in the HLSL file (the tlas is buffer(0), the band image texture(0), the constants buffer(1), the probe atlas texture(1), the
// records buffer(8), the hit constants buffer(3)). One threadgroup of 8 x 8 threads updates one probe (threadgroup x = the job). It is compiled
// at run time with MTLDevice newLibraryWithSource (languageVersion 2_4), never by the build. tools/shaders/compile_rt_shaders.sh embeds this
// text in the generated header.
#include <metal_stdlib>
#include <metal_raytracing>
using namespace metal;
using namespace metal::raytracing;

#include "rt_hit.msli"

// BEGIN RtGiParams
struct RtGiParams {
    float4 grid0;
    float4 grid1;
    float4 grid2;
    float4 grid3;
    uint4 frame;
    float4 flags;
    float4 probe[64];
};
// END RtGiParams

constant float kInv24 = 1.0 / 16777216.0;
constant float kTwoPi = 6.28318530717958647692;
constant float kGoldenAngle = 2.39996322972865332;
constant uint kThreads = 64;
constant uint kMaxRays = 256;
constant uint kDepthTexels = 10;

uint pcg(uint v) {
    const uint s = v * 747796405u + 2891336453u;
    const uint w = ((s >> ((s >> 28u) + 4u)) ^ s) * 277803737u;
    return (w >> 22u) ^ w;
}
float unit(uint h) { return float(h >> 8u) * kInv24; }

float4 gi_rotation(uint seed, uint probe) {
    uint h = pcg(seed ^ pcg(probe + 0x9E3779B9u));
    const float u1 = unit(h);
    h = pcg(h);
    const float u2 = unit(h);
    h = pcg(h);
    const float u3 = unit(h);
    const float a = sqrt(1.0 - u1), b = sqrt(u1);
    return float4(a * sin(kTwoPi * u2), a * cos(kTwoPi * u2), b * sin(kTwoPi * u3), b * cos(kTwoPi * u3));
}
float3 gi_rotate(float4 q, float3 v) {
    const float3 t = 2.0 * cross(q.xyz, v);
    return v + q.w * t + cross(q.xyz, t);
}
float3 gi_fibonacci(uint i, uint n) {
    const float y = 1.0 - (2.0 * float(i) + 1.0) / float(n);
    const float r = sqrt(max(1.0 - y * y, 0.0));
    const float phi = float(i) * kGoldenAngle;
    return float3(r * cos(phi), y, r * sin(phi));
}

float gi_sh_basis(uint k, float3 d) {
    if (k == 0) return 0.282094792;
    if (k == 1) return 0.488602512 * d.y;
    if (k == 2) return 0.488602512 * d.z;
    if (k == 3) return 0.488602512 * d.x;
    if (k == 4) return 1.092548431 * d.x * d.y;
    if (k == 5) return 1.092548431 * d.y * d.z;
    if (k == 6) return 0.315391565 * (3.0 * d.z * d.z - 1.0);
    if (k == 7) return 1.092548431 * d.x * d.z;
    return 0.546274215 * (d.x * d.x - d.y * d.y);
}

#include "rt_gi_grid.msli"

kernel void rt_gi(instance_acceleration_structure tlas [[buffer(0)]],
                  texture2d<float, access::write> out_img [[texture(0)]],
                  constant RtGiParams& params [[buffer(1)]],
                  texture2d<float, access::read> atlas [[texture(1)]],
                  const device RtInstanceRecord* records [[buffer(8)]],
                  constant RtHitParams& hit [[buffer(3)]],
                  uint2 group [[threadgroup_position_in_grid]],
                  uint t [[thread_index_in_threadgroup]]) {
    threadgroup float3 s_radiance[kMaxRays];
    threadgroup float s_dist[kMaxRays];
    threadgroup float s_back[kMaxRays];
    threadgroup float3 s_dir[kMaxRays];  // the ray's direction, computed once by the thread that traces it

    const uint job = group.x;
    if (job >= params.frame.w) return;
    const float4 pj = params.probe[job];
    const uint index = uint(pj.x + 0.5);
    const float weight = pj.y;
    const int2 block = int2(int(pj.z + 0.5), int(pj.w + 0.5));
    const uint nx = uint(params.grid1.x + 0.5), ny = uint(params.grid1.y + 0.5);
    const float3 position = params.grid0.xyz + float3(float(index % nx), float((index / nx) % ny), float(index / (nx * ny))) * params.grid0.w;
    const uint n = clamp(params.frame.z, 1u, kMaxRays);
    const float maxDistance = params.grid2.z;
    const float nearD = params.grid3.w;
    const float4 rot = gi_rotation(params.frame.y, index);
    const float gain = params.grid2.w * params.grid3.x;

    for (uint r = t; r < n; r += kThreads) {
        const float3 dir = gi_rotate(rot, gi_fibonacci(r, n));
        RtSurface s;
        float3 color;
        float dist = 1.0, back = 0.0;
        if (rt_trace_surface(tlas, records, hit, position, dir, nearD, maxDistance, s)) {
            color = rt_shade_hit(tlas, hit, s, -dir);
            if (params.grid3.z > 0.5) {
                float cover;
                const float3 light = gi_grid_light(atlas, params.grid0, params.grid1, params.grid2, params.grid3, s.position, s.normal, cover);
                const float3 diffuse = s.albedo * (1.0 - s.metalness);
                if (!s.unlit) color = max(color + diffuse * cover * (light * gain - hit.ambient.xyz), 0.0);
            }
            dist = saturate(s.t / maxDistance);
            // flags.x == 0: the sense of the front flag is not measured on this backend, nothing counts as a back face. A two-sided
            // instance (a leaf, a curtain) has no back face a probe could be inside of.
            if (params.flags.x != 0.0 && (records[s.record].flags & kRtFlagTwoSided) == 0u)
                back = (s.front == (params.flags.x > 0.0)) ? 0.0 : 1.0;
        } else {
            color = rt_miss_color(hit, dir);
        }
        s_dir[r] = dir;
        s_radiance[r] = color;
        s_dist[r] = dist;
        s_back[r] = back;
    }
    threadgroup_barrier(mem_flags::mem_threadgroup);

    if (t < 9) {
        float3 sum = float3(0.0, 0.0, 0.0);
        for (uint r = 0; r < n; ++r) sum += s_radiance[r] * gi_sh_basis(t, s_dir[r]);
        out_img.write(float4(sum * (4.0 * kRtHitPi / float(n)), weight), uint2(uint(block.x) + t, uint(block.y) + 10));
    }
    if (t == 9) {
        float b = 0.0;
        for (uint r = 0; r < n; ++r) b += s_back[r];
        out_img.write(float4(b / float(n), 1.0, 0.0, weight), uint2(uint(block.x) + 9, uint(block.y) + 10));
    }
    const float lobe = 4.0 + float(n) / 16.0;
    for (uint k = t; k < kDepthTexels * kDepthTexels; k += kThreads) {
        const uint tx = k % kDepthTexels, ty = k / kDepthTexels;
        const float2 e = (float2(float(tx) - 0.5, float(ty) - 0.5)) / 8.0 * 2.0 - 1.0;
        const float3 td = gi_oct_decode(e);
        float wsum = 0.0, m1 = 0.0, m2 = 0.0;
        for (uint r = 0; r < n; ++r) {
            const float c = dot(td, s_dir[r]);
            if (c <= 0.0) continue;
            const float w = pow(c, lobe);
            wsum += w;
            m1 += w * s_dist[r];
            m2 += w * s_dist[r] * s_dist[r];
        }
        float2 mom = float2(1.0, 1.0);
        if (wsum > 1.0e-6) mom = float2(m1, m2) / wsum;
        out_img.write(float4(mom, 0.0, weight), uint2(uint(block.x) + tx, uint(block.y) + ty));
    }
}
