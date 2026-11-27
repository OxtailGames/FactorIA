// Realtime GI probes updated by rays (M79-P4a, docs/design/ARCHITECTURE_RT_GI.md): the `gi probes` mode of render.rayTracing. One thread group
// updates ONE probe of a RealtimeGI grid: its 64 threads trace the probe's rays (a spherical Fibonacci set, rotated at random per update by a
// seed of the frame), shade what they hit with rt_hit.hlsli (the sun with a shadow ray, the ambient, the emission) plus the light the grid's
// own probes give at the hit (the multi-bounce: the atlas holds the values of the last updates), and project the result onto what a probe's
// block of the probe atlas holds (gi.h): the nine SH coefficients of the light that reaches the probe, the octahedral depth map (the mean
// and the mean square of d / maxDistance, Chebyshev) and the meta texel (the share of back faces hit, 1 = captured).
//
// The kernel does not write the atlas (a render target): it writes the new estimates into an RGBA16F image the size of the atlas's band
// (1024 x 132, the block layout of gi.h, one band row for each 11 atlas rows below row 1024), with the weight of the temporal hysteresis in
// alpha; the renderer then blends each updated block into the atlas with a draw (SrcAlpha, OneMinusSrcAlpha), as the raster captures do.
//
// HLSL is the source of the D3D12 (DXIL, cs_6_5) and the Vulkan (SPIR-V) kernels, rt_gi.metal is the Metal twin: the same algorithm. The bindings
// are the contract of the effect kernels (rt_effect.h, RtEffectBindings) with the constants block and the second texture of this kernel:
//
//   binding 0  g_tlas     acceleration structure                          (Metal: buffer(0))     declared by rt_hit.hlsli
//   binding 1  g_out      storage image, rgba16f, the band               (Metal: texture(0))
//   binding 2  g_params   constant buffer, RtGiParams                     (Metal: buffer(1))
//   binding 3  g_atlas    Texture2D, the probe atlas (RGBA16F)            (Metal: texture(1))   t1: read for the bounces
//   binding 4  g_records  StructuredBuffer of RtInstanceRecord            (Metal: buffer(8))   t2   declared by rt_hit.hlsli
//   binding 7  g_hit      constant buffer, RtHitParams                    (Metal: buffer(3))   b1   declared by rt_hit.hlsli
//
// The probe's rays leave from its centre at `nearExclusion` (the near plane of the raster captures) and end at `maxDistance`; a ray that ends
// on nothing sees the sky (rt_miss_color) at the distance maxDistance, as the raster capture's sky.
#include "rt_hit.hlsli"

[[vk::binding(1, 0)]] [[vk::image_format("rgba16f")]] RWTexture2D<float4> g_out : register(u0);

// BEGIN RtGiParams
struct RtGiParams {
    float4 grid0;  // xyz: the origin of probe (0, 0, 0); w: the spacing
    float4 grid1;  // x, y, z: the probe counts per axis; w: their product
    float4 grid2;  // x: the grid's first block; y: the blocks per band row (102); z: maxDistance; w: intensity
    float4 grid3;  // x: bounce; y: backfaceTolerance (unused here); z: 1 when the atlas holds the values to bounce from; w: nearExclusion
    uint4 frame;   // x: the gi frame; y: the seed of the frame; z: rays per probe; w: probes in this dispatch
    float4 flags;  // x: +1 when the hardware's front face is the mesh's front face, -1 when it is the back face, 0 when unknown (no back faces counted); yzw: 0
    float4 probe[64];  // per probe: x: its index in the grid; y: the blend weight (1 = replaces the block); z, w: its block's texel in the band image
};
// END RtGiParams
[[vk::binding(2, 0)]] ConstantBuffer<RtGiParams> g_params : register(b0);
[[vk::binding(3, 0)]] Texture2D<float4> g_atlas : register(t1);

static const float kInv24 = 1.0 / 16777216.0;
static const float kTwoPi = 6.28318530717958647692;
static const float kGoldenAngle = 2.39996322972865332;
static const uint kThreads = 64;
static const uint kMaxRays = 256;
static const uint kDepthTexels = 10;

// PCG (O'Neill): integer only, the same draws as the Metal kernel and the CPU reference of the test.
uint pcg(uint v) {
    const uint s = v * 747796405u + 2891336453u;
    const uint w = ((s >> ((s >> 28u) + 4u)) ^ s) * 277803737u;
    return (w >> 22u) ^ w;
}
float unit(uint h) { return float(h >> 8u) * kInv24; }

// The rotation of the probe's ray set for this update: a unit quaternion (Shoemake) drawn from the frame's seed and the probe's index.
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
// Ray `i` of `n` on the sphere (spherical Fibonacci: equal areas, the golden angle between two), before the rotation.
float3 gi_fibonacci(uint i, uint n) {
    const float y = 1.0 - (2.0 * float(i) + 1.0) / float(n);
    const float r = sqrt(max(1.0 - y * y, 0.0));
    const float phi = float(i) * kGoldenAngle;
    return float3(r * cos(phi), y, r * sin(phi));
}

// The nine real SH basis functions (probe.h's order), k = 0 .. 8.
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

#include "rt_gi_grid.hlsli"

groupshared float3 s_radiance[kMaxRays];
groupshared float s_dist[kMaxRays];  // d / maxDistance, 1 for a ray that left the scene
groupshared float s_back[kMaxRays];  // 1 for a ray whose first hit is the back of a surface
groupshared float3 s_dir[kMaxRays];  // the ray's direction, computed once by the thread that traces it (the SH and depth loops read it)

[numthreads(8, 8, 1)]
void main(uint3 group : SV_GroupID, uint t : SV_GroupIndex) {
    const uint job = group.x;
    if (job >= g_params.frame.w) return;
    const float4 pj = g_params.probe[job];
    const uint index = uint(pj.x + 0.5);
    const float weight = pj.y;
    const int2 block = int2(int(pj.z + 0.5), int(pj.w + 0.5));
    const uint nx = uint(g_params.grid1.x + 0.5), ny = uint(g_params.grid1.y + 0.5);
    const float3 position = g_params.grid0.xyz + float3(float(index % nx), float((index / nx) % ny), float(index / (nx * ny))) * g_params.grid0.w;
    const uint n = clamp(g_params.frame.z, 1u, kMaxRays);
    const float maxDistance = g_params.grid2.z;
    const float nearD = g_params.grid3.w;
    const float4 rot = gi_rotation(g_params.frame.y, index);
    const float gain = g_params.grid2.w * g_params.grid3.x;  // intensity x bounce: what a surface gets from the grid's own light

    for (uint r = t; r < n; r += kThreads) {
        const float3 dir = gi_rotate(rot, gi_fibonacci(r, n));
        RtSurface s;
        float3 color;
        float dist = 1.0, back = 0.0;
        if (rt_trace_surface(position, dir, nearD, maxDistance, s)) {
            color = rt_shade_hit(s, -dir);
            if (g_params.grid3.z > 0.5) {
                // The light of the grid at the hit replaces the ambient there (the lit pass does the same where a ready grid covers).
                float cover;
                const float3 light = gi_grid_light(g_atlas, g_params.grid0, g_params.grid1, g_params.grid2, g_params.grid3, s.position, s.normal, cover);
                const float3 diffuse = s.albedo * (1.0 - s.metalness);
                if (!s.unlit) color = max(color + diffuse * cover * (light * gain - g_hit.ambient.xyz), 0.0);
            }
            dist = saturate(s.t / maxDistance);
            // flags.x == 0: the sense of the front flag is not measured on this backend, nothing counts as a back face. A two-sided
            // instance (a leaf, a curtain) has no back face a probe could be inside of.
            if (g_params.flags.x != 0.0 && (g_records[s.record].flags & kRtFlagTwoSided) == 0u)
                back = (s.front == (g_params.flags.x > 0.0)) ? 0.0 : 1.0;
        } else {
            color = rt_miss_color(dir);
        }
        s_dir[r] = dir;
        s_radiance[r] = color;
        s_dist[r] = dist;
        s_back[r] = back;
    }
    GroupMemoryBarrierWithGroupSync();

    // The SH row of the block: texel k holds the coefficient k of the light that reaches the probe (sum of L Y_k over the rays, 4 pi / n each).
    if (t < 9) {
        float3 sum = float3(0.0, 0.0, 0.0);
        for (uint r = 0; r < n; ++r) sum += s_radiance[r] * gi_sh_basis(t, s_dir[r]);
        g_out[uint2(block.x + t, block.y + 10)] = float4(sum * (4.0 * kRtHitPi / float(n)), weight);
    }
    // The meta texel: the share of rays that hit a back face first, 1 = captured.
    if (t == 9) {
        float b = 0.0;
        for (uint r = 0; r < n; ++r) b += s_back[r];
        g_out[uint2(block.x + 9, block.y + 10)] = float4(b / float(n), 1.0, 0.0, weight);
    }
    // The depth map with its border (10 x 10 texels, the border folded): the mean of d / maxDistance and of its square over the rays whose
    // direction is near the texel's, weighted by a cosine lobe whose width follows the number of rays.
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
        float2 mom = float2(1.0, 1.0);  // no ray near this direction: unobstructed
        if (wsum > 1.0e-6) mom = float2(m1, m2) / wsum;
        g_out[uint2(block.x + tx, block.y + ty)] = float4(mom, 0.0, weight);
    }
}
