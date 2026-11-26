// Ray traced shadows of point, spot and area lights (M79-P2a-3, docs/RAY_TRACING.md "Shadows", docs/design/ARCHITECTURE_RT_SHADOWS.md): for each
// of up to three lights the renderer picked, one ray per pixel (hard) or `frame.z` rays (soft) from the surface the camera sees toward the light,
// an inline ray query that ends at the first opaque hit. The three visibilities go in the three channels of one image.
//
// HLSL is the source of the D3D12 (DXIL, cs_6_5) and the Vulkan (SPIR-V, SPV_KHR_ray_query) kernels, both compiled with DXC by
// tools/shaders/compile_rt_shaders.sh; engine/render/shaders/rt/rt_shadow_local.metal is the Metal twin (MSL 2.4, compiled at run time). Keep the
// two the same algorithm: the binding numbers below are the contract of every effect kernel (rt_effect.h).
//
//   binding 0  g_tlas     acceleration structure                          (Metal: buffer(0))
//   binding 1  g_out      storage image, rgba32f                          (Metal: texture(0))
//   binding 2  g_params   constant buffer, RtEffectParams                 (Metal: buffer(1))
//   binding 3  g_prepass  Texture2D, the camera's prepass                 (Metal: texture(1))   t1
//   binding 7  g_local    constant buffer, RtLocalParams                  (Metal: buffer(3))   b1
//
// Output (Rgba32F, the size of the prepass): r, g, b = the visibility of light 0, 1, 2 of g_local (1 lit, 0 in shadow; a light the pixel is out of
// reach of, outside the cone of, behind, or a slot with no light, gives 1), a = 1 where a mesh was drawn (0 for the sky, whose visibilities are 1).
// user1.y = 0: hard (one ray to the light's centre), 1: soft (frame.z rays). The soft rays of a point or spot light go inside a cone of tangent
// kind.y around the direction to its centre (the same angular size as the PCSS of its shadow map: tan(0.05 shadowSoftness)); those of an area light
// to points of its emitter (a rectangle, a disc, a tube), its half sizes scaled by kind.z (Light.shadowSoftness). Both are the R2 sequence shifted by
// the pixel's interleaved gradient noise and the frame's seed, never the clock.
//
// What casts: the instances with the CastsShadow bit, as in rt_shadow.hlsl (a cutout casts none: the renderer keeps those casters' maps).
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

// BEGIN RtLocalLight
struct RtLocalLight {
    float4 posReach;  // xyz: the light's position; w: how far it reaches (the pixels past it are lit)
    float4 axisCos;   // xyz: a spot's axis / an area light's front (unit); w: a spot's cos(half angle) (-2 = no cone)
    float4 kind;      // x: 1 point, 2 spot, 3 rectangle, 4 disc, 5 tube; y: the tangent of the cone of a point or spot light (0 = hard); z: the factor on an area light's half sizes (0 = hard)
    float4 right;     // xyz: an area light's first axis times its half size; w: 0
    float4 up;        // xyz: the second axis times its half size (a tube: its half thickness); w: 0
};
// END RtLocalLight
struct RtLocalParams {
    float4 header;  // x: how many lights are traced (0 .. 3); y: how much shorter than its length a ray is (a fraction): it stops short of the light
    RtLocalLight lights[3];
};
[[vk::binding(7, 0)]] ConstantBuffer<RtLocalParams> g_local : register(b1);

static const uint kRtMaskCastsShadow = 0x08;

// The normal the prepass stores (octahedral, -1 .. 1) in view space.
float3 oct_decode(float2 e) {
    float3 n = float3(e, 1.0 - abs(e.x) - abs(e.y));
    if (n.z < 0.0) n.xy = (1.0 - abs(n.yx)) * float2(n.x >= 0.0 ? 1.0 : -1.0, n.y >= 0.0 ? 1.0 : -1.0);
    return normalize(n);
}

// The interleaved gradient noise and the R2 sequence of rt_shadow.hlsl: the same samples for the same pixel, frame serial and light.
float ign(float2 p, uint seed) {
    p += 5.588238 * float(seed & 63u);
    return frac(52.9829189 * frac(dot(p, float2(0.06711056, 0.00583715))));
}

float2 sample_2d(uint2 id, uint seed, uint k) {
    const float2 shift = float2(ign(float2(id), seed), ign(float2(id) + float2(37.0, 17.0), seed ^ 0x9E3779B9u));
    return frac(shift + float(k + 1u) * float2(0.7548776662466927, 0.5698402909980532));
}

[numthreads(8, 8, 1)]
void main(uint3 id : SV_DispatchThreadID) {
    if (id.x >= (uint)g_params.image.x || id.y >= (uint)g_params.image.y) return;
    const bool soft = g_params.user1.y > 0.5;
    const float4 pre = g_prepass.Load(int3(id.xy, 0));
    if (pre.a < 0.5) {  // the sky: no surface, nothing to shadow
        g_out[id.xy] = float4(1.0, 1.0, 1.0, 0.0);
        return;
    }
    const float depth = pre.r;
    const float2 ndc = float2((float(id.x) + 0.5) * g_params.image.z * 2.0 - 1.0, 1.0 - (float(id.y) + 0.5) * g_params.image.w * 2.0);
    const float3 pos = g_params.rayO0.xyz + ndc.x * g_params.rayOX.xyz + ndc.y * g_params.rayOY.xyz +
                       (g_params.rayD0.xyz + ndc.x * g_params.rayDX.xyz + ndc.y * g_params.rayDY.xyz) * depth;
    const float3 nv = oct_decode(pre.gb);
    const float3 n = normalize(g_params.viewRight.xyz * nv.x + g_params.viewUp.xyz * nv.y + g_params.viewBack.xyz * nv.z);
    // user0: x = the normal offset in metres, y = more of it per metre of view depth, z = TMin, w = TMax (unused: a ray ends at its light).
    const float3 origin = pos + n * (g_params.user0.x + g_params.user0.y * depth);
    const uint count = min((uint)g_local.header.x, 3u);
    const float shorter = 1.0 - clamp(g_local.header.y, 0.0, 0.5);
    float vis[3] = {1.0, 1.0, 1.0};
    for (uint li = 0u; li < count; ++li) {
        const RtLocalLight L = g_local.lights[li];
        const float3 toLight = L.posReach.xyz - pos;
        const float dist = length(toLight);
        if (dist > L.posReach.w || dist < 1.0e-4) continue;  // out of reach: no light, the shadow is whatever
        const float3 l = toLight / dist;
        const uint kind = (uint)(L.kind.x + 0.5);
        if (kind == 2u && dot(-l, L.axisCos.xyz) < L.axisCos.w - 0.02) continue;      // outside the spot's cone
        if ((kind == 3u || kind == 4u) && dot(-toLight, L.axisCos.xyz) < -0.01) continue;  // behind a rectangle or a disc (a tube shines all around)
        const bool area = kind >= 3u;
        const bool softLight = soft && (area ? L.kind.z > 0.0 : L.kind.y > 0.0);
        const uint rays = softLight ? clamp(g_params.frame.z, 1u, 16u) : 1u;
        const float3 t = normalize(abs(l.y) < 0.99 ? cross(l, float3(0.0, 1.0, 0.0)) : cross(l, float3(1.0, 0.0, 0.0)));
        const float3 b = cross(l, t);
        const uint seed = g_params.frame.y + 23u * li;
        float lit = 0.0;
        for (uint k = 0u; k < rays; ++k) {
            float3 target = L.posReach.xyz;
            if (softLight) {
                const float2 u = sample_2d(id.xy, seed, k);
                if (!area) {  // a point in the disc of the cone's base at the light's distance
                    const float r = sqrt(u.x) * L.kind.y * dist, a = 6.283185307179586 * u.y;
                    target += (t * cos(a) + b * sin(a)) * r;
                } else if (kind == 3u) {  // a rectangle
                    target += L.right.xyz * ((2.0 * u.x - 1.0) * L.kind.z) + L.up.xyz * ((2.0 * u.y - 1.0) * L.kind.z);
                } else if (kind == 4u) {  // a disc (right and up are the same radius)
                    const float r = sqrt(u.x) * L.kind.z, a = 6.283185307179586 * u.y;
                    target += (L.right.xyz * cos(a) + L.up.xyz * sin(a)) * r;
                } else {  // a tube: along its axis, and across it the half thickness turned toward the surface
                    float3 across = cross(L.right.xyz, toLight);
                    const float cl = length(across);
                    across = cl > 1.0e-6 ? across / cl : t;
                    target += L.right.xyz * ((2.0 * u.x - 1.0) * L.kind.z) + across * (length(L.up.xyz) * (2.0 * u.y - 1.0) * L.kind.z);
                }
            }
            const float3 v = target - origin;
            const float len = max(length(v), 1.0e-4);
            RayDesc ray;
            ray.Origin = origin;
            ray.TMin = g_params.user0.z;
            ray.Direction = v / len;
            ray.TMax = len * shorter;
            RayQuery<RAY_FLAG_ACCEPT_FIRST_HIT_AND_END_SEARCH> q;
            q.TraceRayInline(g_tlas, RAY_FLAG_NONE, kRtMaskCastsShadow, ray);
            while (q.Proceed()) {}  // a non-opaque candidate (a cutout) is never committed here
            lit += q.CommittedStatus() == COMMITTED_TRIANGLE_HIT ? 0.0 : 1.0;
        }
        vis[li] = lit / float(rays);
    }
    g_out[id.xy] = float4(vis[0], vis[1], vis[2], 1.0);
}
