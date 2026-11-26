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
//   binding 4  g_records  StructuredBuffer of RtInstanceRecord            (Metal: buffer(2))   t2   (not used here)
//   binding 5  g_albedo   Texture2D, the G-buffer's albedo                (Metal: texture(2))   t3   (not used here)
//   binding 6  g_material Texture2D, the G-buffer's roughness and metal   (Metal: texture(3))   t4   (not used here)
//
// Output (Rgba32F, the size of the prepass): r = the linear view depth of the surface (kRtNoMesh where no mesh was drawn; the contact
// shadows of the lit pass read it from the same image), g = the visibility of the sun, 1 lit and 0 in shadow, b = 0, a = 1 where a mesh
// was drawn (0 for the sky), the prepass's own convention.
//
// What casts: the instances with the CastsShadow bit (MeshRenderer.castShadows). The instances of a cutout (alpha-tested) material are
// not forced opaque, so their triangles are only candidates, and the loop below never commits one: a cutout casts no ray traced shadow
// yet (TODO P2a-2: test the alpha of the candidate with the record and the texture). A blended mesh is opaque to the ray and casts the
// shadow of its whole surface, as it does in the shadow map.
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

[numthreads(8, 8, 1)]
void main(uint3 id : SV_DispatchThreadID) {
    if (id.x >= (uint)g_params.image.x || id.y >= (uint)g_params.image.y) return;
    const float4 pre = g_prepass.Load(int3(id.xy, 0));
    if (pre.a < 0.5) {  // the sky: no surface, nothing to shadow
        g_out[id.xy] = float4(kRtNoMesh, 1.0, 0.0, 0.0);
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
    RayDesc ray;
    ray.Origin = pos + n * offset;
    ray.TMin = g_params.user0.z;
    ray.Direction = l;
    ray.TMax = g_params.user0.w;
    RayQuery<RAY_FLAG_ACCEPT_FIRST_HIT_AND_END_SEARCH> q;
    q.TraceRayInline(g_tlas, RAY_FLAG_NONE, kRtMaskCastsShadow, ray);
    while (q.Proceed()) {}  // a non-opaque candidate (a cutout) is never committed here
    const float visible = q.CommittedStatus() == COMMITTED_TRIANGLE_HIT ? 0.0 : 1.0;
    g_out[id.xy] = float4(depth, visible, 0.0, 1.0);
}
