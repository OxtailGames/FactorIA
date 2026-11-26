// Metal twin of rt_pathtrace.hlsl (MSL 2.4, inline `intersection_query`): the same algorithm and the same integer sequences, the bindings of the
// contract in the HLSL file (the tlas is buffer(0), the output texture(0) read and write, the constants buffer(1), the prepass texture(1), the
// records buffer(8), the hit constants buffer(3), the lights buffer(4)). The hit shading is rt_hit.msli, whose text
// tools/shaders/compile_rt_shaders.sh puts at the `#include` below. It is compiled at run time with MTLDevice newLibraryWithSource
// (languageVersion 2_4), never by the build.
#include <metal_stdlib>
#include <metal_raytracing>
using namespace metal;
using namespace metal::raytracing;

#include "rt_hit.msli"

// BEGIN RtEffectParams
struct RtEffectParams {
    float4 camera;
    float4 lightDir;
    float4 image;
    uint4 frame;
    float4 rayO0, rayOX, rayOY, rayD0, rayDX, rayDY;
    float4 uRayO0, uRayOX, uRayOY, uRayD0, uRayDX, uRayDY;
    float4 viewRight, viewUp, viewBack;
    float4 viewProj0, viewProj1, viewProj2, viewProj3;
    float4 user0, user1;
};
// END RtEffectParams

// BEGIN RtLightParams
struct RtLightParams {
    uint4 count;
    float4 pos[8];
    float4 color[8];
    float4 dir[8];
    float4 extra[8];
};
// END RtLightParams

constant float kInv24 = 1.0 / 16777216.0;
constant float kTwoPi = 6.28318530717958647692;
constant float kFar = 10000.0;
constant uint kMaxSegments = 64u;
constant uint kMaxGlass = 8u;

uint pcg(uint v) {
    const uint s = v * 747796405u + 2891336453u;
    const uint w = ((s >> ((s >> 28u) + 4u)) ^ s) * 277803737u;
    return (w >> 22u) ^ w;
}
float unit(uint h) { return float(h >> 8u) * kInv24; }
float rnd(thread uint& state) {
    state = pcg(state);
    return unit(state);
}

float lum(float3 c) { return dot(c, float3(0.2126, 0.7152, 0.0722)); }

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

bool pt_blocked(instance_acceleration_structure tlas, float3 origin, float3 dir, float tmax) {
    float t;
    uint record, prim;
    return rt_closest_hit(tlas, origin, dir, 0.0, tmax, kRtMaskCastsShadow, true, t, record, prim);
}

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

float4 pt_sample(instance_acceleration_structure tlas, const device RtInstanceRecord* records, constant RtHitParams& hit,
                 constant RtLightParams& lights, float3 origin, float3 dir, float primaryLimit, uint maxBounces, bool useLights,
                 thread uint& rng) {
    float3 throughput = float3(1.0, 1.0, 1.0);
    float3 radiance = float3(0.0, 0.0, 0.0);
    float3 coefInside = float3(0.0, 0.0, 0.0);
    bool inside = false;
    uint depth = 0u;
    uint glass = 0u;
    const bool hasSun = max(hit.sunColor.x, max(hit.sunColor.y, hit.sunColor.z)) > 0.0;
    for (uint seg = 0u; seg < kMaxSegments; ++seg) {
        RtSurface s;
        if (!rt_trace_surface_mask(tlas, records, hit, origin, dir, 0.0, kFar, kRtMaskSurfaces, s)) {
            if (seg == 0u) return float4(0.0, 0.0, 0.0, 0.0);
            radiance += throughput * (rt_environment(hit, dir, 0.0) + hit.ambient.xyz);
            break;
        }
        if (seg == 0u && s.t > primaryLimit) return float4(0.0, 0.0, 0.0, 0.0);
        if (inside) throughput *= exp(-coefInside * s.t);
        const device RtInstanceRecord& r = records[s.record];
        const float off = hit.limits.x + hit.limits.y * s.t;
        if ((r.flags & kRtFlagRefractive) != 0u) {
            ++glass;
            if (glass > kMaxGlass) break;
            float3 next = dir;
            if (r.volume.y > 0.0) {
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
        const float3 n = s.normal;
        const float3 v = -dir;
        const float roughness = clamp(s.roughness, 0.05, 1.0);
        const float3 diffuseColor = s.albedo * (1.0 - s.metalness);
        const float3 f0 = mix(float3(0.04, 0.04, 0.04), s.albedo, s.metalness);
        const float ndv = max(dot(n, v), 1.0e-4);
        const float3 shadowOrigin = s.position + n * off;
        if (hasSun && dot(n, hit.sunDir.xyz) > 0.0) {
            if (!pt_blocked(tlas, shadowOrigin, hit.sunDir.xyz, hit.limits.z))
                radiance += throughput * pt_direct(hit.sunDir.xyz, n, v, ndv, roughness, diffuseColor, f0) * hit.sunColor.xyz;
        }
        const uint lightCount = useLights ? min(lights.count.x, 8u) : 0u;
        if (lightCount > 0u) {
            const uint li = min(uint(rnd(rng) * float(lightCount)), lightCount - 1u);
            const float3 toLight = lights.pos[li].xyz - s.position;
            const float dist = max(length(toLight), 1.0e-4);
            const float3 l = toLight / dist;
            const float range = max(lights.pos[li].w, 1.0e-3);
            const float x = clamp(1.0 - (dist / range) * (dist / range), 0.0, 1.0);
            float atten = x * x;
            if (lights.color[li].w > 1.5 && lights.color[li].w < 2.5) {
                const float cosOuter = lights.dir[li].w;
                float cosInner = lights.extra[li].x;
                if (cosInner > 1.5) cosInner = mix(cosOuter, 1.0, 0.25);
                const float cosAngle = dot(-l, normalize(lights.dir[li].xyz));
                atten *= smoothstep(cosOuter, cosInner, cosAngle);
            }
            if (atten > 0.0 && dot(n, l) > 0.0 && !pt_blocked(tlas, shadowOrigin, l, max(dist - off, 0.0)))
                radiance += throughput * pt_direct(l, n, v, ndv, roughness, diffuseColor, f0) * lights.color[li].xyz * (atten * float(lightCount));
        }
        if (depth >= maxBounces) break;
        ++depth;
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
            if (lt.z <= 0.0) break;
            next = tx * lt.x + ty * lt.y + n * lt.z;
            throughput *= specW / pSpec;
        } else {
            const float rr = sqrt(u1);
            const float phi = kTwoPi * u2;
            next = tx * (rr * cos(phi)) + ty * (rr * sin(phi)) + n * sqrt(max(1.0 - u1, 0.0));
            throughput *= diffuseColor / (1.0 - pSpec);
        }
        if (depth >= 3u) {
            const float p = clamp(max(throughput.x, max(throughput.y, throughput.z)), 0.05, 0.95);
            if (rnd(rng) > p) break;
            throughput /= p;
        }
        origin = shadowOrigin;
        dir = normalize(next);
    }
    return float4(radiance, 1.0);
}

kernel void rt_pathtrace(instance_acceleration_structure tlas [[buffer(0)]],
                         texture2d<float, access::read_write> out_img [[texture(0)]],
                         constant RtEffectParams& params [[buffer(1)]],
                         texture2d<float, access::read> prepass [[texture(1)]],
                         const device RtInstanceRecord* records [[buffer(8)]],
                         constant RtHitParams& hit [[buffer(3)]],
                         constant RtLightParams& lights [[buffer(4)]],
                         uint2 id [[thread_position_in_grid]]) {
    if (id.x >= uint(params.image.x) || id.y >= uint(params.image.y)) return;
    const uint n0 = params.frame.x;
    const uint m = max(params.frame.z, 1u);
    const uint maxBounces = params.frame.w & 255u;
    const bool useLights = (params.frame.w & 256u) != 0u;
    const float4 pre = prepass.read(id);
    const uint pixelHash = pcg(id.x + pcg(id.y + pcg(params.frame.y ^ 0x68E31DA4u)));
    const uint shiftY = pcg(pixelHash);
    float4 sum = float4(0.0, 0.0, 0.0, 0.0);
    for (uint k = 0u; k < m; ++k) {
        const uint si = n0 + k;
        uint rng = pcg(pixelHash + pcg(si));
        const float jx = unit(si * 3242174889u + pixelHash);
        const float jy = unit(si * 2447445414u + shiftY);
        const float2 ndc = float2((float(id.x) + jx) * params.image.z * 2.0 - 1.0, 1.0 - (float(id.y) + jy) * params.image.w * 2.0);
        const float3 origin = params.uRayO0.xyz + ndc.x * params.uRayOX.xyz + ndc.y * params.uRayOY.xyz;
        const float3 dirPerDepth = params.uRayD0.xyz + ndc.x * params.uRayDX.xyz + ndc.y * params.uRayDY.xyz;
        const float dirLength = max(length(dirPerDepth), 1.0e-6);
        const float primaryLimit = pre.a > 0.5 ? (pre.r * 1.02 + 0.05) * dirLength : kFar;
        float4 c = pt_sample(tlas, records, hit, lights, origin, dirPerDepth / dirLength, primaryLimit, maxBounces, useLights, rng);
        if (any(isnan(c)) || any(isinf(c))) c = float4(0.0, 0.0, 0.0, 0.0);
        const float l = lum(c.rgb);
        if (params.user0.x > 0.0 && l > params.user0.x) c.rgb *= params.user0.x / l;
        sum += c;
    }
    const float4 mean = sum / float(m);
    float4 result = mean;
    if (n0 > 0u) result = mix(out_img.read(id), mean, float(m) / float(n0 + m));
    out_img.write(result, id);
}
