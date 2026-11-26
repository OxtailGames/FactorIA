// Hit shading shared by the ray traced effects (M79-P3a-1, docs/design/ARCHITECTURE_RT_EFFECTS.md "Hit shading"): what a ray that ends on a
// surface of the scene sees there. The reflections use it first; the translucency (P3b), the global illumination (P4a, P4b) and the path
// tracer (P5a) are the next readers. The Metal twin is rt_hit.msli (the same functions, the same numbers; MSL has no global resources, so
// there the three resources below are arguments of each function).
//
// A kernel includes this file and gets, in ONE place, the bindings of the part of the contract (rt_effect.h, RtEffectBindings) that hit
// shading reads; it declares the rest of the contract itself (the output, the RtEffectParams block, the prepass, the G-buffer):
//
//   binding 0  g_tlas     acceleration structure                       t0   (Metal: buffer(0))
//   binding 4  g_records  StructuredBuffer of RtInstanceRecord         t2   (Metal: buffer(8))
//   binding 7  g_hit      constant buffer, RtHitParams                 b1   (Metal: buffer(3))
//
// Inputs (what the renderer puts in RtHitParams each frame): the sun (direction toward it, radiance = colour * intensity), the scene's
// ambient light, and the two colours of the environment's gradient (SceneSettings.skyColor and horizonColor), all in the scene's colour
// space, as the lit pass uses them.
//
// Outputs:
//   rt_trace_surface(origin, dir, tmin, tmax, s)  the closest surface of the scene (instance masks Opaque | Cutout | Blended) along the ray,
//       as an RtSurface: position, normal, albedo, roughness, metalness, emissive, the unlit flag, the distance and the record's index.
//       A cutout (alpha-tested) material is never hit: its triangles are only candidates and the kernels never commit one. A blended mesh
//       is a solid surface to the ray.
//   rt_shade_hit(s, toViewer)   the colour of that surface seen from `toViewer` (the unit vector from the surface toward whoever looks: the
//       negative ray direction): the sun (Lambert + GGX) when the surface is not in the shadow of an opaque or blended surface (a shadow
//       ray with the mask 0x08, the instances that cast a shadow), the ambient light times the diffuse colour, the environment's
//       reflection weighted by the environment BRDF, and the emission; an unlit surface (MeshRenderer.unlit) is its albedo plus its emission.
//   rt_miss_color(dir)   what a ray that leaves the scene sees: the environment's gradient in that direction.
//
// Limits (what this version does not have, so a kernel does not rely on it):
//   * No textures. A hit has the constants of the instance's record (the material's base colour, roughness, metalness and emission
//     multiplied into it), never a texel: a textured mesh shows its flat colour in a reflection.
//   * No interpolated normal: the engine gives a kernel no vertex buffers. The normal is the face's, found with two more rays parallel to the
//     first (a differential); where they land on another triangle or instance (an edge, a thin mesh) the surface faces the ray. A curved
//     mesh is faceted.
//   * One shadow ray, for the sun only: the point and spot lights add no light to a hit, the sun's shadow is hard (any softness is the
//     denoiser's).
//   * The ambient is the scene's constant ambient light, and the environment the sky and horizon gradient: a scene whose sky is a material, a
//     physical sky or an HDRI has no texture for the kernel, so its rays see the gradient (RtHitParams.sky.w is 1 then).
//   * No fog, no decals, no occlusion, no light probes, no second bounce.
#ifndef FA_RT_HIT_HLSLI
#define FA_RT_HIT_HLSLI

#include "rt_records.hlsli"

[[vk::binding(0, 0)]] RaytracingAccelerationStructure g_tlas : register(t0);
[[vk::binding(4, 0)]] StructuredBuffer<RtInstanceRecord> g_records : register(t2);

// BEGIN RtHitParams
struct RtHitParams {
    float4 sunDir;    // xyz: the unit vector from a surface toward the sun; w: 0
    float4 sunColor;  // xyz: the sun's radiance (colour * intensity; 0 = no sun that lights); w: 0
    float4 ambient;   // xyz: SceneSettings.ambientLight; w: 0
    float4 sky;       // xyz: SceneSettings.skyColor; w: 1 when the scene's environment is a texture this kernel cannot read
    float4 horizon;   // xyz: SceneSettings.horizonColor; w: 0
    // x: the shadow ray's offset along the normal in metres, y: more of it per metre of the ray's length, z: the shadow ray's TMax,
    // w: the differential rays' offset as a fraction of the hit distance.
    float4 limits;
};
// END RtHitParams
[[vk::binding(7, 0)]] ConstantBuffer<RtHitParams> g_hit : register(b1);

static const float kRtHitPi = 3.14159265358979;

struct RtSurface {
    float3 position;  // the hit point, world space
    float3 normal;    // unit, on the side the ray came from
    float3 albedo;    // the base colour (scene colour space)
    float roughness;  // 0 .. 1
    float metalness;  // 0 .. 1
    float3 emissive;
    bool unlit;
    float t;      // the distance from the ray's origin
    uint record;  // the instance's index in g_records
};

// The closest committed triangle of `mask` along the ray: its distance, the instance's custom index (the record) and the triangle.
bool rt_closest_hit(float3 origin, float3 dir, float tmin, float tmax, uint mask, out float t, out uint record, out uint prim) {
    RayDesc ray;
    ray.Origin = origin;
    ray.TMin = tmin;
    ray.Direction = dir;
    ray.TMax = tmax;
    RayQuery<RAY_FLAG_NONE> q;
    q.TraceRayInline(g_tlas, RAY_FLAG_NONE, mask, ray);
    while (q.Proceed()) {}  // a non-opaque candidate (a cutout) is never committed
    t = 0.0;
    record = 0;
    prim = 0;
    if (q.CommittedStatus() != COMMITTED_TRIANGLE_HIT) return false;
    t = q.CommittedRayT();
    record = q.CommittedInstanceID();
    prim = q.CommittedPrimitiveIndex();
    return true;
}

// Is there something that casts a shadow between `p` and the sun? (any hit ends the search)
float rt_sun_visibility(float3 p, float3 n, float rayLength) {
    const float offset = g_hit.limits.x + g_hit.limits.y * rayLength;
    RayDesc ray;
    ray.Origin = p + n * offset;
    ray.TMin = 0.0;
    ray.Direction = g_hit.sunDir.xyz;
    ray.TMax = g_hit.limits.z;
    RayQuery<RAY_FLAG_ACCEPT_FIRST_HIT_AND_END_SEARCH> q;
    q.TraceRayInline(g_tlas, RAY_FLAG_NONE, kRtMaskCastsShadow, ray);
    while (q.Proceed()) {}
    return q.CommittedStatus() == COMMITTED_TRIANGLE_HIT ? 0.0 : 1.0;
}

bool rt_trace_surface(float3 origin, float3 dir, float tmin, float tmax, out RtSurface s) {
    s = (RtSurface)0;
    float t0;
    uint rec0, prim0;
    if (!rt_closest_hit(origin, dir, tmin, tmax, kRtMaskSurfaces, t0, rec0, prim0)) return false;
    const RtInstanceRecord r = g_records[rec0];
    s.position = origin + dir * t0;
    s.t = t0;
    s.record = rec0;
    s.albedo = r.albedo.rgb;
    s.roughness = saturate(r.roughness);
    s.metalness = saturate(r.metalness);
    s.emissive = r.emissive.rgb;
    s.unlit = (r.flags & kRtFlagUnlit) != 0;
    // The face's normal: two more rays parallel to this one, a little to each side, meet the same plane at two more points; the cross
    // product of the two edges (the offsets are exact, the distances differ by the slope) is the normal. They must land on the same triangle.
    s.normal = -dir;
    const float3 up = abs(dir.y) < 0.9 ? float3(0.0, 1.0, 0.0) : float3(1.0, 0.0, 0.0);
    const float3 u = normalize(cross(up, dir));
    const float3 v = cross(dir, u);
    const float eps = max(g_hit.limits.w * t0, 0.001);
    float t1, t2;
    uint rec1, rec2, prim1, prim2;
    const bool h1 = rt_closest_hit(origin + u * eps, dir, tmin, tmax, kRtMaskSurfaces, t1, rec1, prim1);
    const bool h2 = rt_closest_hit(origin + v * eps, dir, tmin, tmax, kRtMaskSurfaces, t2, rec2, prim2);
    if (h1 && h2 && rec1 == rec0 && rec2 == rec0 && prim1 == prim0 && prim2 == prim0) {
        const float3 e1 = u * eps + dir * (t1 - t0);
        const float3 e2 = v * eps + dir * (t2 - t0);
        float3 n = cross(e1, e2);
        const float len = length(n);
        if (len > 1.0e-12) {
            n /= len;
            s.normal = dot(n, dir) > 0.0 ? -n : n;
        }
    }
    return true;
}

// The environment's gradient in direction `d` for a surface of `rough` (the lit pass's own, fa_environment, without a texture): blurrier and
// flatter for rougher surfaces.
float3 rt_environment(float3 d, float rough) {
    const float blur = rough * rough;
    const float h = clamp(d.y * (1.0 - 0.7 * blur), 0.0, 1.0);
    const float3 up = lerp(g_hit.horizon.xyz, g_hit.sky.xyz, pow(h, 0.55));
    const float3 down = g_hit.horizon.xyz * 0.55;
    const float k = smoothstep(-0.05 - 0.6 * blur, 0.05 + 0.6 * blur, d.y);
    const float3 e = lerp(down, up, k);
    return lerp(e, 0.5 * (g_hit.sky.xyz + g_hit.horizon.xyz) * 0.8, blur * 0.6);
}

float3 rt_miss_color(float3 dir) { return rt_environment(dir, 0.0); }

// Karis' analytic environment BRDF: scale and bias of F0 (mesh_common.glsl fa_env_brdf).
float2 rt_env_brdf(float rough, float ndv) {
    const float4 c0 = float4(-1.0, -0.0275, -0.572, 0.022);
    const float4 c1 = float4(1.0, 0.0425, 1.04, -0.04);
    const float4 r = rough * c0 + c1;
    const float a004 = min(r.x * r.x, exp2(-9.28 * ndv)) * r.x + r.y;
    return float2(-1.04, 1.04) * a004 + r.zw;
}

float3 rt_shade_hit(RtSurface s, float3 toViewer) {
    if (s.unlit) return s.albedo + s.emissive;
    const float3 n = s.normal;
    const float3 v = toViewer;
    const float roughness = clamp(s.roughness, 0.05, 1.0);
    const float3 diffuseColor = s.albedo * (1.0 - s.metalness);
    const float3 f0 = lerp(float3(0.04, 0.04, 0.04), s.albedo, s.metalness);
    const float ndv = max(dot(n, v), 1.0e-4);
    float3 color = g_hit.ambient.xyz * diffuseColor;
    const float2 ab = rt_env_brdf(roughness, ndv);
    color += rt_environment(reflect(-v, n), roughness) * (f0 * ab.x + ab.y);
    const float3 l = g_hit.sunDir.xyz;
    const float ndl = dot(n, l);
    if (ndl > 0.0 && max(g_hit.sunColor.x, max(g_hit.sunColor.y, g_hit.sunColor.z)) > 0.0) {
        if (rt_sun_visibility(s.position, n, s.t) > 0.5) {
            const float alpha = roughness * roughness;
            const float a2 = alpha * alpha;
            const float3 h = normalize(l + v);
            const float ndh = saturate(dot(n, h));
            const float vdh = saturate(dot(v, h));
            const float dd = ndh * ndh * (a2 - 1.0) + 1.0;
            const float d = a2 / (kRtHitPi * dd * dd);
            const float vis = 0.5 / (ndl * sqrt(ndv * ndv * (1.0 - a2) + a2) + ndv * sqrt(ndl * ndl * (1.0 - a2) + a2));
            const float3 f = f0 + (1.0 - f0) * pow(1.0 - vdh, 5.0);
            color += (diffuseColor + d * vis * f) * g_hit.sunColor.xyz * ndl;
        }
    }
    return color + s.emissive;
}

#endif
