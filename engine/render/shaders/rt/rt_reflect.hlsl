// Sharp ray traced reflections (M79-P3a-1, docs/RAY_TRACING.md "Reflections"): one mirror ray per pixel for the surfaces that are
// smooth enough, from the surface the camera sees along the reflection of the view ray; where it ends on a surface of the scene the kernel
// shades the hit (rt_hit.hlsli: the sun with a shadow ray, the ambient, the emission). The screen-space reflection pass composites the
// image this kernel writes where it feeds the lit picture (renderer_ssr.h); the pixels that are rougher than the cutoff keep the
// screen-space reflections and the probes. The second effect on the shared ray traced effect pass (engine/render/src/rt_effect.h).
//
// HLSL is the source of the D3D12 (DXIL, cs_6_5) and the Vulkan (SPIR-V) kernels, rt_reflect.metal is the Metal twin: the same algorithm.
// The bindings are the contract of every effect kernel (rt_shadow.hlsl lists them) plus the three of rt_hit.hlsli:
//
//   binding 0  g_tlas     acceleration structure                          (Metal: buffer(0))     declared by rt_hit.hlsli
//   binding 1  g_out      storage image, rgba32f                          (Metal: texture(0))
//   binding 2  g_params   constant buffer, RtEffectParams                 (Metal: buffer(1))
//   binding 3  g_prepass  Texture2D, the camera's prepass                 (Metal: texture(1))   t1
//   binding 4  g_records  StructuredBuffer of RtInstanceRecord            (Metal: buffer(8))   t2   declared by rt_hit.hlsli
//   binding 5  g_albedo   Texture2D, the G-buffer's albedo                (Metal: texture(2))   t3
//   binding 6  g_material Texture2D, the G-buffer's roughness and metal   (Metal: texture(3))   t4
//   binding 7  g_hit      constant buffer, RtHitParams                    (Metal: buffer(3))   b1   declared by rt_hit.hlsli
//
// user0 (RtEffectParams): x = the ray's offset from the surface along the normal in metres, y = more of it per metre of view depth,
// z = the sharp cutoff (a pixel with a roughness under it gets ONE mirror ray, as in P3a-1), w = the ray's TMax.
// user1: x = the glossy limit (M79-P3a-2): a pixel with a roughness from the sharp cutoff up to it gets `frame.z` rays (1 to 16) whose
// directions are sampled from the GGX distribution of the visible normals (Heitz 2018) with alpha = roughness^2; a pixel at or above it is not
// traced. A limit at or under the cutoff leaves only the mirror rays.
//
// Output (Rgba32F, the size of the prepass): the rays that ended on a surface are averaged. rgb = the mean radiance of those rays, tinted by
// the albedo of a metal; a = 0 where nothing was traced (the sky, a surface above the limit, no G-buffer texel), the mean hit distance in
// metres (> 0, at least 0.0001) where at least one ray ended on a surface, -1 where every ray left the scene (rgb is 0 then: the pixel falls
// back to the screen-space reflections and the probes). The hit distance is the denoiser's: the virtual-motion reprojection and the width of
// the filter; the coverage (a > 0) is a signal of its own.
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
[[vk::binding(2, 0)]] ConstantBuffer<RtEffectParams> g_params : register(b0);
[[vk::binding(3, 0)]] Texture2D<float4> g_prepass : register(t1);
[[vk::binding(5, 0)]] Texture2D<float4> g_albedo : register(t3);
[[vk::binding(6, 0)]] Texture2D<float4> g_material : register(t4);

static const float kInv24 = 1.0 / 16777216.0;
static const float kTwoPi = 6.28318530717958647692;

// PCG (O'Neill): integer only, so the sequence of draws is the same on every GPU and on the CPU (rt_ao.hlsl).
uint pcg(uint v) {
    const uint s = v * 747796405u + 2891336453u;
    const uint w = ((s >> ((s >> 28u) + 4u)) ^ s) * 277803737u;
    return (w >> 22u) ^ w;
}
float unit(uint h) { return float(h >> 8u) * kInv24; }

// A direction sampled from the GGX distribution of the normals visible from `ve` (tangent space, ve.z > 0): Heitz, "Sampling the GGX
// Distribution of Visible Normals" (JCGT 2018). Returns the reflected direction (tangent space).
float3 ggx_vndf_reflect(float3 ve, float alpha, float u1, float u2) {
    const float3 vh = normalize(float3(alpha * ve.x, alpha * ve.y, ve.z));
    const float lensq = vh.x * vh.x + vh.y * vh.y;
    const float3 t1 = lensq > 1.0e-7 ? float3(-vh.y, vh.x, 0.0) * rsqrt(lensq) : float3(1.0, 0.0, 0.0);
    const float3 t2 = cross(vh, t1);
    const float r = sqrt(u1);
    const float phi = kTwoPi * u2;
    const float a = r * cos(phi);
    float b = r * sin(phi);
    const float sh = 0.5 * (1.0 + vh.z);
    b = (1.0 - sh) * sqrt(max(1.0 - a * a, 0.0)) + sh * b;
    const float3 nh = a * t1 + b * t2 + sqrt(max(1.0 - a * a - b * b, 0.0)) * vh;
    const float3 ne = normalize(float3(alpha * nh.x, alpha * nh.y, max(nh.z, 0.0)));
    return reflect(-ve, ne);
}

// The normal the prepass stores (octahedral, -1 .. 1) in view space.
float3 oct_decode(float2 e) {
    float3 n = float3(e, 1.0 - abs(e.x) - abs(e.y));
    if (n.z < 0.0) n.xy = (1.0 - abs(n.yx)) * float2(n.x >= 0.0 ? 1.0 : -1.0, n.y >= 0.0 ? 1.0 : -1.0);
    return normalize(n);
}

[numthreads(8, 8, 1)]
void main(uint3 id : SV_DispatchThreadID) {
    if (id.x >= (uint)g_params.image.x || id.y >= (uint)g_params.image.y) return;
    const float4 pre = g_prepass.Load(int3(id.xy, 0));
    const float4 mat = g_material.Load(int3(id.xy, 0));
    const float limit = max(g_params.user1.x, g_params.user0.z);
    if (pre.a < 0.5 || mat.a < 0.5 || mat.r >= limit) {  // the sky, no G-buffer texel, a surface too rough to trace
        g_out[id.xy] = float4(0.0, 0.0, 0.0, 0.0);
        return;
    }
    const float depth = pre.r;
    const float2 ndc = float2((float(id.x) + 0.5) * g_params.image.z * 2.0 - 1.0, 1.0 - (float(id.y) + 0.5) * g_params.image.w * 2.0);
    const float3 pos = g_params.rayO0.xyz + ndc.x * g_params.rayOX.xyz + ndc.y * g_params.rayOY.xyz +
                       (g_params.rayD0.xyz + ndc.x * g_params.rayDX.xyz + ndc.y * g_params.rayDY.xyz) * depth;
    const float3 nv = oct_decode(pre.gb);
    const float3 n = normalize(g_params.viewRight.xyz * nv.x + g_params.viewUp.xyz * nv.y + g_params.viewBack.xyz * nv.z);
    // The view ray: from the camera into the scene (an orthographic camera looks along its own axis).
    const float3 view = g_params.camera.w > 0.5 ? -g_params.viewBack.xyz : normalize(pos - g_params.camera.xyz);
    const float3 r = reflect(view, n);
    const float3 tint = lerp(float3(1.0, 1.0, 1.0), g_albedo.Load(int3(id.xy, 0)).rgb, saturate(mat.g));
    const float offset = g_params.user0.x + g_params.user0.y * depth;
    const float3 origin = pos + n * offset;
    const bool glossy = mat.r >= g_params.user0.z;
    const uint count = glossy ? clamp(g_params.frame.z, 1u, 16u) : 1u;
    // An orthonormal basis around the normal (Duff et al., branchless), and the view vector in it.
    const float sg = n.z >= 0.0 ? 1.0 : -1.0;
    const float ba = -1.0 / (sg + n.z);
    const float bb = n.x * n.y * ba;
    const float3 tx = float3(1.0 + sg * n.x * n.x * ba, sg * bb, -sg * n.x);
    const float3 ty = float3(bb, sg + n.y * n.y * ba, -n.y);
    const float3 toViewer = -view;
    const float3 ve = normalize(float3(dot(tx, toViewer), dot(ty, toViewer), max(dot(n, toViewer), 1.0e-3)));
    const float alpha = mat.r * mat.r;
    const float invCount = 1.0 / float(count);
    uint state = pcg(id.x + pcg(id.y + pcg(g_params.frame.y)));
    float3 sum = float3(0.0, 0.0, 0.0);
    float distSum = 0.0;
    uint hits = 0;
    for (uint i = 0; i < count; ++i) {
        float3 dir = r;
        if (glossy) {
            state = pcg(state);
            const float u1 = (float(i) + unit(state)) * invCount;  // stratified over the rays of the pixel
            state = pcg(state);
            const float u2 = unit(state);
            const float3 l = ggx_vndf_reflect(ve, alpha, u1, u2);
            const float3 w = normalize(tx * l.x + ty * l.y + n * l.z);
            if (l.z > 1.0e-3) dir = w;  // a sample under the surface is the mirror direction instead
        }
        RtSurface s;
        if (rt_trace_surface(origin, dir, 0.0, g_params.user0.w, s)) {
            sum += rt_shade_hit(s, -dir) * tint;
            distSum += s.t;
            ++hits;
        }
    }
    if (hits > 0) {
        g_out[id.xy] = float4(sum / float(hits), max(distSum / float(hits), 0.0001));
    } else {
        g_out[id.xy] = float4(0.0, 0.0, 0.0, -1.0);
    }
}
