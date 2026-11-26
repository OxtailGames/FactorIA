// The path traced reference mode (M79-P5a, docs/design/ARCHITECTURE_RT_PATHTRACER.md): one unidirectional path per pixel and sample, an inline ray
// query for every segment, accumulated over the frames in a float image. The fifth effect on the shared ray traced effect pass
// (engine/render/src/rt_effect.h); the renderer draws its image over the raster picture of the main pass (the pixels whose primary ray misses
// the scene keep the raster's sky), and the post stack and the tonemap treat it as the lit colour.
//
// HLSL is the source of the D3D12 (DXIL, cs_6_5) and the Vulkan (SPIR-V) kernels, rt_pathtrace.metal is the Metal twin: the same algorithm, the
// same integer sequences. The bindings are the contract of every effect kernel (rt_shadow.hlsl lists them), the three of rt_hit.hlsli and one more:
//
//   binding 0  g_tlas     acceleration structure                          (Metal: buffer(0))     declared by rt_hit.hlsli
//   binding 1  g_out      storage image, rgba32f, READ AND WRITE          (Metal: texture(0))    the running mean of the samples
//   binding 2  g_params   constant buffer, RtEffectParams                 (Metal: buffer(1))
//   binding 3  g_prepass  Texture2D, the camera's prepass                 (Metal: texture(1))   t1   the raster's depth: what hides a hit
//   binding 4  g_records  StructuredBuffer of RtInstanceRecord            (Metal: buffer(8))   t2   declared by rt_hit.hlsli
//   binding 7  g_hit      constant buffer, RtHitParams                    (Metal: buffer(3))   b1   declared by rt_hit.hlsli
//   binding 8  g_lights   constant buffer, RtLightParams                  (Metal: buffer(4))   b2
//
// The inputs of RtEffectParams this kernel reads:
//   frame.x  the samples already in the image (n0): the sample index of this frame's first sample
//   frame.y  the seed of the settings (never the frame's: the same samples on every run)
//   frame.z  the samples this frame (m)
//   frame.w  the maximum number of indirect (scattering) bounces, maxBounces - 1 (low 8 bits) | 256 when the point and spot lights are used
//   user0.x  the firefly clamp (a sample's luminance is scaled down to it; 0 = off)
// The camera is the unjittered one (uRay*): the sub-pixel position of a sample is a low discrepancy point (the R2 sequence of the sample index,
// shifted by a hash of the pixel), the image converges to the antialiased picture.
//
// A path: at each surface it adds the emission, the sun and one random light of RtLightParams (a shadow ray each, the lit pass's own formula:
// (diffuse + GGX) * colour * N.L, no 1/pi, the point and spot fall-off of the lit pass), ends at depth maxBounces, else scatters: with the
// probability pSpec in the GGX lobe (a visible-normal sample, weighted by the environment BRDF) and else cosine weighted in the Lambert lobe
// (weighted by the diffuse colour). Russian roulette from the third bounce. A refractive instance (a closed volume: thickness > 0) reflects with
// Schlick's Fresnel or refracts with Snell's law (Beer-Lambert inside); a thin sheet is passed through. A ray that leaves the scene sees the
// environment gradient plus the ambient light. Output a is the fraction of the samples whose primary ray ended on a surface the raster does not
// hide (the prepass has a nearer surface than the hit: the surface is not in the scene of the rays, for instance terrain); rgb is premultiplied.
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

// BEGIN RtLightParams
struct RtLightParams {
    uint4 count;       // x: the number of lights (0 .. 8)
    float4 pos[8];     // xyz: the position, w: the range
    float4 color[8];   // rgb: colour * intensity, w: the type (1 point, 2 spot; an area light is a point light at its centre)
    float4 dir[8];     // xyz: the spot's axis, w: cos(outer angle)
    float4 extra[8];   // x: cos(inner angle) (above 1.5: the lit pass's default fade)
};
// END RtLightParams
[[vk::binding(8, 0)]] ConstantBuffer<RtLightParams> g_lights : register(b2);

static const float kInv24 = 1.0 / 16777216.0;
static const float kTwoPi = 6.28318530717958647692;
static const float kFar = 10000.0;
static const uint kMaxSegments = 64u;
static const uint kMaxGlass = 8u;

// PCG (O'Neill): integer only, so the sequence of draws is the same on every GPU and on the CPU.
uint pcg(uint v) {
    const uint s = v * 747796405u + 2891336453u;
    const uint w = ((s >> ((s >> 28u) + 4u)) ^ s) * 277803737u;
    return (w >> 22u) ^ w;
}
float unit(uint h) { return float(h >> 8u) * kInv24; }
float rnd(inout uint state) {
    state = pcg(state);
    return unit(state);
}

float lum(float3 c) { return dot(c, float3(0.2126, 0.7152, 0.0722)); }

// A direction sampled from the GGX distribution of the visible normals (Heitz 2018); the reflected direction in tangent space.
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

// Is there something that casts a shadow along the ray (any hit ends the search)?
bool pt_blocked(float3 origin, float3 dir, float tmax) {
    RayDesc ray;
    ray.Origin = origin;
    ray.TMin = 0.0;
    ray.Direction = dir;
    ray.TMax = tmax;
    RayQuery<RAY_FLAG_ACCEPT_FIRST_HIT_AND_END_SEARCH> q;  // like rt_sun_visibility: the first hit answers
    q.TraceRayInline(g_tlas, RAY_FLAG_NONE, kRtMaskCastsShadow, ray);
    while (q.Proceed()) {}
    return q.CommittedStatus() == COMMITTED_TRIANGLE_HIT;
}

// (diffuse + GGX specular) * N.L of the lit pass for light direction `l`: multiply by the light's colour.
float3 pt_direct(float3 l, float3 n, float3 v, float ndv, float roughness, float3 diffuseColor, float3 f0) {
    const float ndl = dot(n, l);
    const float alpha = roughness * roughness;
    const float a2 = alpha * alpha;
    const float3 h = normalize(l + v);
    const float ndh = saturate(dot(n, h));
    const float vdh = saturate(dot(v, h));
    const float dd = ndh * ndh * (a2 - 1.0) + 1.0;
    const float d = a2 / (kRtHitPi * dd * dd);
    const float vis = 0.5 / (ndl * sqrt(ndv * ndv * (1.0 - a2) + a2) + ndv * sqrt(ndl * ndl * (1.0 - a2) + a2));
    const float3 f = f0 + (1.0 - f0) * pow(1.0 - vdh, 5.0);
    return (diffuseColor + d * vis * f) * ndl;
}

// rt_hit's face normal falls back to the view direction when one of its two parallel rays lands on another triangle (a hit within a few
// thousandths of the distance from a mesh edge): a dark or bright line along every edge. A path tracer shades millions of such hits, so it asks
// again with smaller offsets (an eighth, then a sixty-fourth), which shrinks the band the edge leaves to a pixel's hundredth.
float3 pt_refine_normal(float3 origin, float3 dir, float t0, uint rec0, float3 normal) {
    if (any(normal != -dir)) return normal;
    float tc;
    uint recc, primc;
    if (!rt_closest_hit(origin, dir, 0.0, kFar, kRtMaskSurfaces, tc, recc, primc)) return normal;
    const float3 up = abs(dir.y) < 0.9 ? float3(0.0, 1.0, 0.0) : float3(1.0, 0.0, 0.0);
    const float3 u = normalize(cross(up, dir));
    const float3 v = cross(dir, u);
    float eps = max(g_hit.limits.w * t0, 0.001);
    for (uint k = 0u; k < 2u; ++k) {
        eps = max(eps * 0.125, 2.0e-4);
        float t1, t2;
        uint rec1, rec2, prim1, prim2;
        const bool h1 = rt_closest_hit(origin + u * eps, dir, 0.0, kFar, kRtMaskSurfaces, t1, rec1, prim1);
        const bool h2 = rt_closest_hit(origin + v * eps, dir, 0.0, kFar, kRtMaskSurfaces, t2, rec2, prim2);
        if (h1 && h2 && rec1 == rec0 && rec2 == rec0 && prim1 == primc && prim2 == primc) {
            const float3 n = cross(u * eps + dir * (t1 - tc), v * eps + dir * (t2 - tc));
            const float len = length(n);
            if (len > 1.0e-12) return dot(n, dir) > 0.0 ? -n / len : n / len;
        }
    }
    return normal;
}

// One path. Returns (radiance, 1) when the primary ray ends on a surface of the scene that the raster does not hide, else (0, 0, 0, 0).
float4 pt_sample(float3 origin, float3 dir, float primaryLimit, uint maxBounces, bool useLights, inout uint rng) {
    float3 throughput = float3(1.0, 1.0, 1.0);
    float3 radiance = float3(0.0, 0.0, 0.0);
    float3 coefInside = float3(0.0, 0.0, 0.0);
    bool inside = false;
    uint depth = 0u;
    uint glass = 0u;
    const bool hasSun = max(g_hit.sunColor.x, max(g_hit.sunColor.y, g_hit.sunColor.z)) > 0.0;
    for (uint seg = 0u; seg < kMaxSegments; ++seg) {
        RtSurface s;
        if (!rt_trace_surface_mask(origin, dir, 0.0, kFar, kRtMaskSurfaces, s)) {
            if (seg == 0u) return float4(0.0, 0.0, 0.0, 0.0);  // the raster's sky
            radiance += throughput * (rt_environment(dir, 0.0) + g_hit.ambient.xyz);
            break;
        }
        if (seg == 0u && s.t > primaryLimit) return float4(0.0, 0.0, 0.0, 0.0);  // the raster draws something nearer
        if (inside) throughput *= exp(-coefInside * s.t);
        const RtInstanceRecord r = g_records[s.record];
        const float off = g_hit.limits.x + g_hit.limits.y * s.t;
        if ((r.flags & kRtFlagRefractive) != 0u) {
            ++glass;
            if (glass > kMaxGlass) break;
            float3 next = dir;
            if (r.volume.y > 0.0) {  // a closed volume
                const float ior = clamp(r.volume.x, 1.0, 3.0);
                const float eta = inside ? ior : 1.0 / ior;
                const float cosi = saturate(dot(-dir, s.normal));
                const float3 rd = refract(dir, s.normal, eta);
                const bool tir = dot(rd, rd) < 0.5;
                const float f0g = (ior - 1.0) / (ior + 1.0);
                const float cost = sqrt(max(1.0 - eta * eta * (1.0 - cosi * cosi), 0.0));
                const float cosx = inside ? cost : cosi;
                const float fres = tir ? 1.0 : f0g * f0g + (1.0 - f0g * f0g) * pow(1.0 - cosx, 5.0);
                if (rnd(rng) < fres) {
                    next = reflect(dir, s.normal);
                } else {
                    next = normalize(rd);
                    if (!inside) {
                        const float3 att = clamp(r.attenuation.rgb, float3(0.0001, 0.0001, 0.0001), float3(1.0, 1.0, 1.0));
                        coefInside = r.volume.z > 0.0 ? -log(att) / r.volume.z : float3(0.0, 0.0, 0.0);
                    }
                    inside = !inside;
                }
            }
            origin = s.position + next * off;
            dir = next;
            continue;
        }
        radiance += throughput * s.emissive;
        if (s.unlit) {
            radiance += throughput * s.albedo;
            break;
        }
        const float3 n = pt_refine_normal(origin, dir, s.t, s.record, s.normal);
        const float3 v = -dir;
        const float roughness = clamp(s.roughness, 0.05, 1.0);
        const float3 diffuseColor = s.albedo * (1.0 - s.metalness);
        const float3 f0 = lerp(float3(0.04, 0.04, 0.04), s.albedo, s.metalness);
        const float ndv = max(dot(n, v), 1.0e-4);
        const float3 shadowOrigin = s.position + n * off;
        if (hasSun && dot(n, g_hit.sunDir.xyz) > 0.0) {
            if (!pt_blocked(shadowOrigin, g_hit.sunDir.xyz, g_hit.limits.z))
                radiance += throughput * pt_direct(g_hit.sunDir.xyz, n, v, ndv, roughness, diffuseColor, f0) * g_hit.sunColor.xyz;
        }
        const uint lightCount = useLights ? min(g_lights.count.x, 8u) : 0u;
        if (lightCount > 0u) {
            const uint li = min(uint(rnd(rng) * float(lightCount)), lightCount - 1u);
            const float3 toLight = g_lights.pos[li].xyz - s.position;
            const float dist = max(length(toLight), 1.0e-4);
            const float3 l = toLight / dist;
            const float range = max(g_lights.pos[li].w, 1.0e-3);
            const float x = clamp(1.0 - (dist / range) * (dist / range), 0.0, 1.0);
            float atten = x * x;
            if (g_lights.color[li].w > 1.5 && g_lights.color[li].w < 2.5) {  // a spot
                const float cosOuter = g_lights.dir[li].w;
                float cosInner = g_lights.extra[li].x;
                if (cosInner > 1.5) cosInner = lerp(cosOuter, 1.0, 0.25);
                const float cosAngle = dot(-l, normalize(g_lights.dir[li].xyz));
                atten *= smoothstep(cosOuter, cosInner, cosAngle);
            }
            if (atten > 0.0 && dot(n, l) > 0.0 && !pt_blocked(shadowOrigin, l, max(dist - off, 0.0)))
                radiance += throughput * pt_direct(l, n, v, ndv, roughness, diffuseColor, f0) * g_lights.color[li].xyz * (atten * float(lightCount));
        }
        if (depth >= maxBounces) break;
        ++depth;
        // The next direction: the GGX lobe with the probability pSpec, else the Lambert one.
        const float2 ab = rt_env_brdf(roughness, ndv);
        const float3 specW = f0 * ab.x + ab.y;
        const float sLum = max(lum(specW), 0.0);
        const float dLum = lum(diffuseColor);
        const float pSpec = dLum <= 1.0e-5 ? 1.0 : clamp(sLum / max(sLum + dLum, 1.0e-6), 0.05, 0.95);
        const float3 up = abs(n.y) < 0.9 ? float3(0.0, 1.0, 0.0) : float3(1.0, 0.0, 0.0);
        const float3 tx = normalize(cross(up, n));
        const float3 ty = cross(n, tx);
        const float u1 = rnd(rng);
        const float u2 = rnd(rng);
        float3 next;
        if (rnd(rng) < pSpec) {
            const float3 lt = ggx_vndf_reflect(float3(dot(v, tx), dot(v, ty), ndv), roughness * roughness, u1, u2);
            if (lt.z <= 0.0) break;  // below the surface: the path is lost
            next = tx * lt.x + ty * lt.y + n * lt.z;
            throughput *= specW / pSpec;
        } else {
            const float rr = sqrt(u1);
            const float phi = kTwoPi * u2;
            next = tx * (rr * cos(phi)) + ty * (rr * sin(phi)) + n * sqrt(max(1.0 - u1, 0.0));
            throughput *= diffuseColor / (1.0 - pSpec);
        }
        if (depth >= 3u) {  // Russian roulette
            const float p = clamp(max(throughput.x, max(throughput.y, throughput.z)), 0.05, 0.95);
            if (rnd(rng) > p) break;
            throughput /= p;
        }
        origin = shadowOrigin;
        dir = normalize(next);
    }
    return float4(radiance, 1.0);
}

[numthreads(8, 8, 1)]
void main(uint3 id : SV_DispatchThreadID) {
    if (id.x >= (uint)g_params.image.x || id.y >= (uint)g_params.image.y) return;
    const uint n0 = g_params.frame.x;
    const uint m = max(g_params.frame.z, 1u);
    const uint maxBounces = g_params.frame.w & 255u;
    const bool useLights = (g_params.frame.w & 256u) != 0u;
    const float4 pre = g_prepass.Load(int3(id.xy, 0));
    // How much the surface's depth changes across one pixel (a floor at a grazing angle changes fast): the largest step to a neighbour that is the same
    // surface (within a quarter of the depth). A hit may lie that far behind the prepass's depth, besides the 2 percent: a sub-pixel jitter that lands on
    // the far side of the pixel is still the surface the raster drew.
    float slope = 0.0;
    if (pre.a > 0.5) {
        const int2 size = int2(g_params.image.xy);
        const int2 steps[4] = {int2(1, 0), int2(-1, 0), int2(0, 1), int2(0, -1)};
        for (int k = 0; k < 4; ++k) {
            const int2 q = int2(id.xy) + steps[k];
            if (q.x < 0 || q.y < 0 || q.x >= size.x || q.y >= size.y) continue;
            const float4 nb = g_prepass.Load(int3(q, 0));
            if (nb.a > 0.5 && abs(nb.r - pre.r) <= 0.25 * pre.r) slope = max(slope, abs(nb.r - pre.r));
        }
    }
    const uint pixelHash = pcg(id.x + pcg(id.y + pcg(g_params.frame.y ^ 0x68E31DA4u)));
    const uint shiftY = pcg(pixelHash);
    float4 sum = float4(0.0, 0.0, 0.0, 0.0);
    for (uint k = 0u; k < m; ++k) {
        const uint si = n0 + k;
        uint rng = pcg(pixelHash + pcg(si));
        // The R2 sequence (Roberts): the golden-ratio-like constants as 32-bit fractions, so the point of sample i is exact.
        const float jx = unit(si * 3242174889u + pixelHash);
        const float jy = unit(si * 2447445414u + shiftY);
        const float2 ndc = float2((float(id.x) + jx) * g_params.image.z * 2.0 - 1.0, 1.0 - (float(id.y) + jy) * g_params.image.w * 2.0);
        const float3 origin = g_params.uRayO0.xyz + ndc.x * g_params.uRayOX.xyz + ndc.y * g_params.uRayOY.xyz;
        const float3 dirPerDepth = g_params.uRayD0.xyz + ndc.x * g_params.uRayDX.xyz + ndc.y * g_params.uRayDY.xyz;
        const float dirLength = max(length(dirPerDepth), 1.0e-6);
        const float primaryLimit = pre.a > 0.5 ? (pre.r * 1.02 + 0.05 + slope) * dirLength : kFar;
        float4 c = pt_sample(origin, dirPerDepth / dirLength, primaryLimit, maxBounces, useLights, rng);
        // A NaN or an infinity never enters the running mean (a bit test, the same as the Metal twin, which cannot rely on isnan under fast-math).
        if (any((asuint(c) & 0x7F800000u) == 0x7F800000u)) c = float4(0.0, 0.0, 0.0, 0.0);
        const float l = lum(c.rgb);
        if (g_params.user0.x > 0.0 && l > g_params.user0.x) c.rgb *= g_params.user0.x / l;
        sum += c;
    }
    const float4 mean = sum / float(m);
    float4 result = mean;
    if (n0 > 0u) result = lerp(g_out[id.xy], mean, float(m) / float(n0 + m));
    g_out[id.xy] = result;
}
