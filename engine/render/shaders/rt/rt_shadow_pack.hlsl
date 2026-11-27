// Packs the denoised soft sun shadow for the lit pass (M79-P2a-2, docs/design/ARCHITECTURE_RT_EFFECTS.md "Soft shadows"). The soft kernel
// (rt_shadow.hlsl) writes (visibility, depth, 0, mesh); the denoiser makes the visibility clean in a separate image; this kernel writes the
// image the lit pass reads, the hard layout: r = the linear view depth, g = the denoised visibility, b = 0, a = 1 where a mesh was drawn.
//
//   binding 0  g_tlas     (not used here and not declared: this kernel needs no TLAS; the other numbers are the contract's)
//   binding 1  g_out      storage image, rgba32f                          (Metal: texture(0))
//   binding 2  g_params   constant buffer, RtEffectParams                 (Metal: buffer(1))
//   binding 3  g_src      Texture2D, the soft kernel's image              (Metal: texture(1))   t1   (the slot of the prepass)
//   binding 9  g_aux      Texture2D, the denoiser's output, r = signal    (Metal: texture(4))   t5
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
[[vk::binding(3, 0)]] Texture2D<float4> g_src : register(t1);
[[vk::binding(9, 0)]] Texture2D<float4> g_aux : register(t5);

[numthreads(8, 8, 1)]
void main(uint3 id : SV_DispatchThreadID) {
    if (id.x >= (uint)g_params.image.x || id.y >= (uint)g_params.image.y) return;
    const float4 s = g_src.Load(int3(id.xy, 0));
    if (s.a < 0.5) {  // the sky: the hard layout's sentinel
        g_out[id.xy] = float4(s.g, 1.0, 0.0, 0.0);
        return;
    }
    const float vis = saturate(g_aux.Load(int3(id.xy, 0)).r);
    g_out[id.xy] = float4(s.g, vis, 0.0, 1.0);
}
