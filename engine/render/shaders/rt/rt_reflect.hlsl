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
// z = the roughness cutoff (a pixel with a roughness at or above it is not traced), w = the ray's TMax.
//
// Output (Rgba32F, the size of the prepass): rgb = the radiance the mirror ray sees, tinted by the albedo of a metal (a miss: the
// environment in the ray's direction), a = 0 where nothing was traced (the sky, a surface above the cutoff, no G-buffer texel), the hit's
// distance in metres (> 0, at least 0.0001) where the ray ended on a surface, -1 where it left the scene. The hit distance is the denoiser's
// hook (P3a-2); the composite takes a > 0 as a reflection and a < 0 as "the lit picture already holds the environment's reflection".
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
    if (pre.a < 0.5 || mat.a < 0.5 || mat.r >= g_params.user0.z) {  // the sky, no G-buffer texel, a surface too rough for a mirror
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
    RtSurface s;
    if (rt_trace_surface(pos + n * offset, r, 0.0, g_params.user0.w, s)) {
        g_out[id.xy] = float4(rt_shade_hit(s, -r) * tint, max(s.t, 0.0001));
    } else {
        g_out[id.xy] = float4(rt_miss_color(r) * tint, -1.0);
    }
}
