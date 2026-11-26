// Ray traced ambient occlusion (M79-P2b, docs/RAY_TRACING.md "Ambient occlusion"): from the surface the camera sees, `frame.z` rays
// leave in a cosine-weighted hemisphere around its normal, each an inline ray query that ends at the first hit within a maximum
// distance. The result is the fraction of the rays that got out (1 = open, 0 = closed in): noisy, one to a few samples a pixel; the
// renderer's own denoiser (rt_denoise.h, DenoiseKind::Occlusion) makes it a clean visibility that the screen-space occlusion's apply
// multiplies into the picture. The second effect of the shared ray traced effect pass (engine/render/src/rt_effect.h,
// docs/design/ARCHITECTURE_RT_EFFECTS.md).
//
// HLSL is the source of the D3D12 (DXIL, cs_6_5) and the Vulkan (SPIR-V, SPV_KHR_ray_query) kernels, both compiled with DXC by
// tools/shaders/compile_rt_shaders.sh; engine/render/shaders/rt/rt_ao.metal is the Metal twin (MSL 2.4, compiled at run time). Keep the
// two the same algorithm, down to the integer sequence of the rays (the Metal test reproduces it on the CPU).
//
//   binding 0  g_tlas     acceleration structure                          (Metal: buffer(0))
//   binding 1  g_out      storage image, rgba32f                          (Metal: texture(0))
//   binding 2  g_params   constant buffer, RtEffectParams                 (Metal: buffer(1))
//   binding 3  g_prepass  Texture2D, the camera's prepass                 (Metal: texture(1))   t1
//   binding 4  g_records  StructuredBuffer of RtInstanceRecord            (Metal: buffer(2))   t2   (not used here)
//   binding 5  g_albedo   Texture2D, the G-buffer's albedo                (Metal: texture(2))   t3   (not used here)
//   binding 6  g_material Texture2D, the G-buffer's roughness and metal   (Metal: texture(3))   t4   (not used here)
//
// user0: x = the maximum distance of a ray in metres (the occlusion radius), y = the normal offset of the ray's origin in metres, z = more
// of it per metre of view depth (a pixel covers more world far away), w = TMin.
//
// Output (Rgba32F, the size of the prepass): r = the visibility, the share of the rays that did not hit (1 open, 0 closed in; 1 on the sky),
// g and b = 0, a = 1 where a mesh was drawn (0 for the sky), the prepass's own convention.
//
// What occludes: the opaque and the alpha-tested instances (mask 0x03). A blended surface (glass, water) lets the ambient light through. A
// cutout (alpha-tested) instance is NOT alpha tested here (the kernel binds no texture): the ray is forced opaque, so a cutout occludes as a
// solid surface of its whole triangle.
//
// The sequence: a PCG hash of (pixel, the frame's seed) gives the pixel's state, and every ray takes two draws of it (u1, u2 in [0, 1), 24
// bits each); the rays are stratified (ray i of n takes u1 in [i / n, (i + 1) / n)). No clock, no rand(): the frame's seed is a hash of the
// frame serial, so the same frame is the same picture on one machine and one GPU (the integer draws are the same everywhere, but the
// directions made from them use float sin, cos and sqrt, and the Metal compile uses fast math: another GPU can differ in the last bits). The
// next frame's noise differs, which the temporal accumulation averages.
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
static const uint kRtMaskOccluders = 0x03;  // kRtMaskOpaque | kRtMaskCutout (rt_records.h)
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

[numthreads(8, 8, 1)]
void main(uint3 id : SV_DispatchThreadID) {
    if (id.x >= (uint)g_params.image.x || id.y >= (uint)g_params.image.y) return;
    const float4 pre = g_prepass.Load(int3(id.xy, 0));
    if (pre.a < 0.5) {  // the sky: nothing to occlude
        g_out[id.xy] = float4(1.0, 0.0, 0.0, 0.0);
        return;
    }
    const float depth = pre.r;
    const float2 ndc = float2((float(id.x) + 0.5) * g_params.image.z * 2.0 - 1.0, 1.0 - (float(id.y) + 0.5) * g_params.image.w * 2.0);
    const float3 pos = g_params.rayO0.xyz + ndc.x * g_params.rayOX.xyz + ndc.y * g_params.rayOY.xyz +
                       (g_params.rayD0.xyz + ndc.x * g_params.rayDX.xyz + ndc.y * g_params.rayDY.xyz) * depth;
    const float3 nv = oct_decode(pre.gb);
    const float3 n = normalize(g_params.viewRight.xyz * nv.x + g_params.viewUp.xyz * nv.y + g_params.viewBack.xyz * nv.z);
    // An orthonormal basis around the normal (Duff et al., branchless).
    const float sg = n.z >= 0.0 ? 1.0 : -1.0;
    const float ba = -1.0 / (sg + n.z);
    const float bb = n.x * n.y * ba;
    const float3 tx = float3(1.0 + sg * n.x * n.x * ba, sg * bb, -sg * n.x);
    const float3 ty = float3(bb, sg + n.y * n.y * ba, -n.y);

    const uint count = clamp(g_params.frame.z, 1u, 64u);
    const float invCount = 1.0 / float(count);
    uint state = pcg(id.x + pcg(id.y + pcg(g_params.frame.y)));
    const float3 origin = pos + n * (g_params.user0.y + g_params.user0.z * depth);
    uint open = 0;
    for (uint i = 0; i < count; ++i) {
        state = pcg(state);
        const float u1 = (float(i) + unit(state)) * invCount;
        state = pcg(state);
        const float u2 = unit(state);
        const float r = sqrt(u1);  // cosine-weighted: the density is cos(theta) / pi
        const float phi = kTwoPi * u2;
        const float3 dir = normalize(tx * (r * cos(phi)) + ty * (r * sin(phi)) + n * sqrt(1.0 - u1));
        RayDesc ray;
        ray.Origin = origin;
        ray.TMin = g_params.user0.w;
        ray.Direction = dir;
        ray.TMax = g_params.user0.x;
        RayQuery<RAY_FLAG_ACCEPT_FIRST_HIT_AND_END_SEARCH> q;
        // FORCE_OPAQUE: a cutout is not alpha tested here, it occludes as a solid surface (no candidate is ever left to decide).
        q.TraceRayInline(g_tlas, RAY_FLAG_FORCE_OPAQUE, kRtMaskOccluders, ray);
        while (q.Proceed()) {}
        if (q.CommittedStatus() != COMMITTED_TRIANGLE_HIT) ++open;
    }
    g_out[id.xy] = float4(float(open) * invCount, 0.0, 0.0, 1.0);
}
