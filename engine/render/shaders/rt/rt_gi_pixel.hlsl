// Ray traced global illumination per pixel (M79-P4b-1, docs/design/ARCHITECTURE_RT_GI.md "Per pixel"): the `gi perPixel` mode of
// render.rayTracing. From the surface the camera sees, `frame.z` rays leave in a cosine-weighted hemisphere around its normal, each an inline ray
// query that ends on the closest surface of the scene (rt_hit.hlsli). What the ray sees there is shaded as the reflections shade a hit (the sun
// with a shadow ray, the ambient, the emission), plus, for the bounces after that one, the light the realtime GI grids give at the hit (the
// probes' atlas: one traced bounce and a cached tail, no recursion); a ray that leaves the scene sees the sky (rt_miss_color).
//
// The output is the indirect diffuse light as the lit shader reads it: the irradiance divided by pi, which for cosine-weighted rays is the mean of
// the radiance the rays carry. The surface's own albedo is NOT in it (the lit pass multiplies the denoised result by the diffuse colour), so the
// signal is demodulated by construction and the denoiser (DenoiseKind::Diffuse, rt_denoise.h) keeps the textures sharp. Noisy: one to a few rays a
// pixel.
//
// HLSL is the source of the D3D12 (DXIL, cs_6_5) and the Vulkan (SPIR-V) kernels, rt_gi_pixel.metal is the Metal twin: the same algorithm, down to
// the integer sequence of the rays. The bindings are the contract of the effect kernels (rt_effect.h, RtEffectBindings) with the constants block
// and the atlas of this kernel:
//
//   binding 0  g_tlas     acceleration structure                          (Metal: buffer(0))     declared by rt_hit.hlsli
//   binding 1  g_out      storage image, rgba32f                          (Metal: texture(0))
//   binding 2  g_params   constant buffer, RtGiPixelParams                (Metal: buffer(1))
//   binding 3  g_prepass  Texture2D, the camera's prepass                 (Metal: texture(1))   t1
//   binding 4  g_records  StructuredBuffer of RtInstanceRecord            (Metal: buffer(8))   t2   declared by rt_hit.hlsli
//   binding 5  g_atlas    Texture2D, the probe atlas (RGBA16F)            (Metal: texture(2))   t3   (the albedo's slot: no G-buffer here)
//   binding 7  g_hit      constant buffer, RtHitParams                    (Metal: buffer(3))   b1   declared by rt_hit.hlsli
//
// user0: x = the longest ray in metres, y = the normal offset of the ray's origin in metres, z = more of it per metre of view depth (a pixel covers
// more world far away), w = TMin. Output (Rgba32F, the size of the prepass): rgb = the indirect diffuse light, a = 1 where a mesh was drawn, 0 on the sky.
#include "rt_hit.hlsli"

[[vk::binding(1, 0)]] [[vk::image_format("rgba32f")]] RWTexture2D<float4> g_out : register(u0);

// BEGIN RtEffectParams
struct RtEffectParams {
    float4 camera;    // xyz: the camera's position (the renderer's space); w: 1 for an orthographic camera
    float4 lightDir;  // xyz: the unit vector from a surface toward the light; w: 0
    float4 image;     // xy: the size of the image in pixels; zw: 1 / size
    uint4 frame;      // x: the frame serial; y: the seed of the frame; z: rays per pixel; w: 0
    // The camera the prepass was drawn with (jittered). The world position of pixel (x, y), with ndc = (2 (x + 0.5) / w - 1, 1 - 2 (y + 0.5) / h)
    // and d the linear view depth: rayO0 + ndc.x rayOX + ndc.y rayOY + (rayD0 + ndc.x rayDX + ndc.y rayDY) d.
    float4 rayO0, rayOX, rayOY, rayD0, rayDX, rayDY;
    // The same for the unjittered camera (what history and reprojection use).
    float4 uRayO0, uRayOX, uRayOY, uRayD0, uRayDX, uRayDY;
    float4 viewRight, viewUp, viewBack;  // xyz: the camera's axes in the renderer's space; a view-space normal (x, y, z) is right x + up y + back z
    float4 viewProj0, viewProj1, viewProj2, viewProj3;  // the rows of the unjittered view-projection matrix
    float4 user0, user1;                                // the effect's own numbers
};
// END RtEffectParams

// BEGIN RtGiPixelTail
struct RtGiPixelTail {
    uint4 count;       // x: the grids of the tail (0 .. 4, 0 = the hit's further bounces see the ambient light only)
    float4 grid0[4];   // per grid: xyz: the origin of probe (0, 0, 0); w: the spacing
    float4 grid1[4];   // x, y, z: the probe counts per axis; w: their product
    float4 grid2[4];   // x: the grid's first block; y: the blocks per band row; z: maxDistance; w: intensity
    float4 grid3[4];   // x: bounce; y: backfaceTolerance; zw: 0
};
// END RtGiPixelTail

// BEGIN RtGiPixelParams
struct RtGiPixelParams {
    RtEffectParams e;
    RtGiPixelTail tail;
};
// END RtGiPixelParams
[[vk::binding(2, 0)]] ConstantBuffer<RtGiPixelParams> g_params : register(b0);
[[vk::binding(3, 0)]] Texture2D<float4> g_prepass : register(t1);
[[vk::binding(5, 0)]] Texture2D<float4> g_atlas : register(t3);

static const float kInv24 = 1.0 / 16777216.0;
static const float kTwoPi = 6.28318530717958647692;

// The normal the prepass stores (octahedral, -1 .. 1) in view space.
float3 oct_decode(float2 e) {
    float3 n = float3(e, 1.0 - abs(e.x) - abs(e.y));
    if (n.z < 0.0) n.xy = (1.0 - abs(n.yx)) * float2(n.x >= 0.0 ? 1.0 : -1.0, n.y >= 0.0 ? 1.0 : -1.0);
    return normalize(n);
}

// PCG (O'Neill): integer only, so the sequence of draws is the same on every GPU and on the CPU.
uint pcg(uint v) {
    const uint s = v * 747796405u + 2891336453u;
    const uint w = ((s >> ((s >> 28u) + 4u)) ^ s) * 277803737u;
    return (w >> 22u) ^ w;
}

// A number in [0, 1) from the top 24 bits of a hash: exact in a float.
float unit(uint h) { return float(h >> 8u) * kInv24; }

#include "rt_gi_grid.hlsli"

[numthreads(8, 8, 1)]
void main(uint3 id : SV_DispatchThreadID) {
    if (id.x >= (uint)g_params.e.image.x || id.y >= (uint)g_params.e.image.y) return;
    const float4 pre = g_prepass.Load(int3(id.xy, 0));
    if (pre.a < 0.5) {  // the sky: no surface to light
        g_out[id.xy] = float4(0.0, 0.0, 0.0, 0.0);
        return;
    }
    const float depth = pre.r;
    const float2 ndc = float2((float(id.x) + 0.5) * g_params.e.image.z * 2.0 - 1.0, 1.0 - (float(id.y) + 0.5) * g_params.e.image.w * 2.0);
    const float3 pos = g_params.e.rayO0.xyz + ndc.x * g_params.e.rayOX.xyz + ndc.y * g_params.e.rayOY.xyz +
                       (g_params.e.rayD0.xyz + ndc.x * g_params.e.rayDX.xyz + ndc.y * g_params.e.rayDY.xyz) * depth;
    const float3 nv = oct_decode(pre.gb);
    const float3 n = normalize(g_params.e.viewRight.xyz * nv.x + g_params.e.viewUp.xyz * nv.y + g_params.e.viewBack.xyz * nv.z);
    // An orthonormal basis around the normal (Duff et al., branchless).
    const float sg = n.z >= 0.0 ? 1.0 : -1.0;
    const float ba = -1.0 / (sg + n.z);
    const float bb = n.x * n.y * ba;
    const float3 tx = float3(1.0 + sg * n.x * n.x * ba, sg * bb, -sg * n.x);
    const float3 ty = float3(bb, sg + n.y * n.y * ba, -n.y);

    const uint count = clamp(g_params.e.frame.z, 1u, 64u);
    const float invCount = 1.0 / float(count);
    const uint grids = min(g_params.tail.count.x, 4u);
    uint state = pcg(id.x + pcg(id.y + pcg(g_params.e.frame.y)));
    const float3 origin = pos + n * (g_params.e.user0.y + g_params.e.user0.z * depth);
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
        if (rt_trace_surface(origin, dir, g_params.e.user0.w, g_params.e.user0.x, s)) {
            color = rt_shade_hit(s, -dir);
            if (grids > 0 && !s.unlit) {
                // The light of the ready grids at the hit replaces the ambient there, as the lit pass does where a grid covers: the first grid that reaches
                // the point takes its cover, the next ones what is left (fa_gi_light).
                float left = 1.0;
                float3 light = float3(0.0, 0.0, 0.0);
                for (uint k = 0; k < grids; ++k) {
                    float cover;
                    const float3 l = gi_grid_light(g_atlas, g_params.tail.grid0[k], g_params.tail.grid1[k], g_params.tail.grid2[k], g_params.tail.grid3[k],
                                                   s.position, s.normal, cover);
                    const float share = cover * left;
                    light += l * (g_params.tail.grid2[k].w * g_params.tail.grid3[k].x) * share;  // intensity x bounce
                    left -= share;
                    if (left < 0.001) {
                        left = 0.0;
                        break;
                    }
                }
                const float3 diffuse = s.albedo * (1.0 - s.metalness);
                color = max(color + diffuse * (light - g_hit.ambient.xyz * (1.0 - left)), 0.0);
            }
        } else {
            color = rt_miss_color(dir);
        }
        sum += color;
    }
    g_out[id.xy] = float4(sum * invCount, 1.0);
}
