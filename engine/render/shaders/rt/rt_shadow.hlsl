// Hard shadows of the directional light (M79-P2a-1, docs/RAY_TRACING.md "Shadows"): one shadow ray per pixel from the surface the
// camera sees toward the sun, an inline ray query that ends at the first opaque hit. The first effect of the shared ray traced effect
// pass (engine/render/src/rt_effect.h, docs/design/ARCHITECTURE_RT_EFFECTS.md).
//
// HLSL is the source of the D3D12 (DXIL, cs_6_5) and the Vulkan (SPIR-V, SPV_KHR_ray_query) kernels, both compiled with DXC by
// tools/shaders/compile_rt_shaders.sh; engine/render/shaders/rt/rt_shadow.metal is the Metal twin (MSL 2.4, compiled at run time). Keep
// the two the same algorithm: the binding numbers below are the contract of every effect kernel (RtEffect, rt_effect.h); a kernel
// declares only the resources it reads, the numbers never change.
//
//   binding 0  g_tlas     acceleration structure                          (Metal: buffer(0))
//   binding 1  g_out      storage image, rgba32f                          (Metal: texture(0))
//   binding 2  g_params   constant buffer, RtEffectParams                 (Metal: buffer(1))
//   binding 3  g_prepass  Texture2D, the camera's prepass                 (Metal: texture(1))   t1
//   binding 4  g_records  StructuredBuffer of RtInstanceRecord            (Metal: buffer(8))   t2   (not used here)
//   binding 5  g_albedo   Texture2D, the G-buffer's albedo                (Metal: texture(2))   t3   (not used here)
//   binding 6  g_material Texture2D, the G-buffer's roughness and metal   (Metal: texture(3))   t4   (not used here)
//   binding 9  g_aux      Texture2D, a kernel's second input image        (Metal: texture(4))   t5   (not used here)
//
// Output (Rgba32F, the size of the prepass), two layouts, chosen by user1.y:
//   hard (0, one ray at the sun's centre): r = the linear view depth of the surface (kRtNoMesh where no mesh was drawn; the contact shadows of
//     the lit pass read it from the same image), g = the visibility of the sun, 1 lit and 0 in shadow, b = 0, a = 1 where a mesh was drawn
//     (0 for the sky), the prepass's own convention. The lit pass reads this image as it is.
//   soft (1, frame.z rays at points of the sun's disc, user1.x = the tangent of its angular radius): r = the visibility (the fraction of the
//     rays that reached the sun), g = the depth, b = 0, a as above. The denoiser (DenoiseKind::Visibility) reads r; rt_shadow_pack then puts
//     the denoised visibility in the hard layout for the lit pass.
//
// What casts: the instances with the CastsShadow bit (MeshRenderer.castShadows). The instances of a cutout (alpha-tested) material are
// not forced opaque, so their triangles are only candidates, and the loop below never commits one: a cutout casts no ray traced shadow. The
// kernels see no UVs and no texture of a mesh (the record has neither, docs/design/ARCHITECTURE_RT_EFFECTS.md "Alpha-tested casters"), so the
// alpha cannot be tested here; the renderer keeps the cascade shadow of those casters instead (it counts them: RtSceneStats::untracedCasters).
// A blended mesh is opaque to the ray and casts the shadow of its whole surface, as it does in the shadow map.
[[vk::binding(0, 0)]] RaytracingAccelerationStructure g_tlas : register(t0);
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

static const float kRtNoMesh = 1.0e30;
static const uint kRtMaskCastsShadow = 0x08;

// The normal the prepass stores (octahedral, -1 .. 1) in view space.
float3 oct_decode(float2 e) {
    float3 n = float3(e, 1.0 - abs(e.x) - abs(e.y));
    if (n.z < 0.0) n.xy = (1.0 - abs(n.yx)) * float2(n.x >= 0.0 ? 1.0 : -1.0, n.y >= 0.0 ? 1.0 : -1.0);
    return normalize(n);
}

// The cone sampling of the soft shadow (user1.y = 1). The sun is a disc of angular diameter D; the rays go to points of that disc, seen from the
// surface: direction = normalize(l + tanHalf * (x t + y b)) with (x, y) a point of the unit disc and t, b a basis of the plane across l.
// The points are the R2 low-discrepancy sequence (the plastic number's two reciprocals), shifted for each pixel by the interleaved gradient noise
// of the pixel and the frame's seed (a Cranley-Patterson rotation: the pixels' offsets are blue-noise-like, so the denoiser's blur removes them),
// and the same inputs always give the same rays (the seed is a hash of the frame serial, never the clock).
float ign(float2 p, uint seed) {
    p += 5.588238 * float(seed & 63u);
    return frac(52.9829189 * frac(dot(p, float2(0.06711056, 0.00583715))));
}

float2 sun_disc_point(uint2 id, uint seed, uint k) {
    const float2 shift = float2(ign(float2(id), seed), ign(float2(id) + float2(37.0, 17.0), seed ^ 0x9E3779B9u));
    const float2 u = frac(shift + float(k + 1u) * float2(0.7548776662466927, 0.5698402909980532));
    const float r = sqrt(u.x), a = 6.283185307179586 * u.y;
    return r * float2(cos(a), sin(a));
}

[numthreads(8, 8, 1)]
void main(uint3 id : SV_DispatchThreadID) {
    if (id.x >= (uint)g_params.image.x || id.y >= (uint)g_params.image.y) return;
    // user1: x = tan of the sun's angular radius (the cone's half angle), y = 0 for the hard layout, 1 for the soft one (see the header).
    const bool soft = g_params.user1.y > 0.5;
    const float4 pre = g_prepass.Load(int3(id.xy, 0));
    if (pre.a < 0.5) {  // the sky: no surface, nothing to shadow
        g_out[id.xy] = soft ? float4(1.0, kRtNoMesh, 0.0, 0.0) : float4(kRtNoMesh, 1.0, 0.0, 0.0);
        return;
    }
    const float depth = pre.r;
    const float2 ndc = float2((float(id.x) + 0.5) * g_params.image.z * 2.0 - 1.0, 1.0 - (float(id.y) + 0.5) * g_params.image.w * 2.0);
    const float3 pos = g_params.rayO0.xyz + ndc.x * g_params.rayOX.xyz + ndc.y * g_params.rayOY.xyz +
                       (g_params.rayD0.xyz + ndc.x * g_params.rayDX.xyz + ndc.y * g_params.rayDY.xyz) * depth;
    const float3 nv = oct_decode(pre.gb);
    const float3 n = normalize(g_params.viewRight.xyz * nv.x + g_params.viewUp.xyz * nv.y + g_params.viewBack.xyz * nv.z);
    // user0: x = the normal offset in metres, y = more of it per metre of view depth (a pixel covers more world far away), z = TMin, w = TMax.
    const float3 l = g_params.lightDir.xyz;
    const float offset = g_params.user0.x + g_params.user0.y * depth;
    const uint rays = soft ? clamp(g_params.frame.z, 1u, 64u) : 1u;
    float3 t = normalize(abs(l.y) < 0.99 ? cross(l, float3(0.0, 1.0, 0.0)) : cross(l, float3(1.0, 0.0, 0.0)));
    const float3 b = cross(l, t);
    float lit = 0.0;
    for (uint k = 0u; k < rays; ++k) {
        float3 dir = l;
        if (soft) {
            const float2 d = sun_disc_point(id.xy, g_params.frame.y, k) * g_params.user1.x;
            dir = normalize(l + t * d.x + b * d.y);
        }
        RayDesc ray;
        ray.Origin = pos + n * offset;
        ray.TMin = g_params.user0.z;
        ray.Direction = dir;
        ray.TMax = g_params.user0.w;
        RayQuery<RAY_FLAG_ACCEPT_FIRST_HIT_AND_END_SEARCH> q;
        q.TraceRayInline(g_tlas, RAY_FLAG_NONE, kRtMaskCastsShadow, ray);
        while (q.Proceed()) {}  // a non-opaque candidate (a cutout) is never committed here
        lit += q.CommittedStatus() == COMMITTED_TRIANGLE_HIT ? 0.0 : 1.0;
    }
    const float visible = lit / float(rays);
    g_out[id.xy] = soft ? float4(visible, depth, 0.0, 1.0) : float4(depth, visible, 0.0, 1.0);
}
