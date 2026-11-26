// Metal twin of rt_reflect.hlsl (MSL 2.4, inline `intersection_query`): the same algorithm, the bindings of the contract in the HLSL file
// (the tlas is buffer(0), the output texture(0), the constants buffer(1), the prepass texture(1), the records buffer(8), the G-buffer's
// albedo texture(2) and material texture(3), the hit constants buffer(3)). The hit shading is rt_hit.msli, whose text
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

constant float kInv24 = 1.0 / 16777216.0;
constant float kTwoPi = 6.28318530717958647692;

// PCG (O'Neill): integer only, the same draws as the HLSL and the CPU reference of the test.
uint pcg(uint v) {
    const uint s = v * 747796405u + 2891336453u;
    const uint w = ((s >> ((s >> 28u) + 4u)) ^ s) * 277803737u;
    return (w >> 22u) ^ w;
}
float unit(uint h) { return float(h >> 8u) * kInv24; }

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

float3 oct_decode(float2 e) {
    float3 n = float3(e, 1.0 - abs(e.x) - abs(e.y));
    if (n.z < 0.0) n.xy = (1.0 - abs(n.yx)) * float2(n.x >= 0.0 ? 1.0 : -1.0, n.y >= 0.0 ? 1.0 : -1.0);
    return normalize(n);
}

kernel void rt_reflect(instance_acceleration_structure tlas [[buffer(0)]],
                       texture2d<float, access::write> out_img [[texture(0)]],
                       constant RtEffectParams& params [[buffer(1)]],
                       texture2d<float, access::read> prepass [[texture(1)]],
                       const device RtInstanceRecord* records [[buffer(8)]],
                       texture2d<float, access::read> albedo_img [[texture(2)]],
                       texture2d<float, access::read> material_img [[texture(3)]],
                       constant RtHitParams& hit [[buffer(3)]],
                       uint2 id [[thread_position_in_grid]]) {
    if (id.x >= uint(params.image.x) || id.y >= uint(params.image.y)) return;
    const float4 pre = prepass.read(id);
    const float4 mat = material_img.read(id);
    const float limit = max(params.user1.x, params.user0.z);
    if (pre.a < 0.5 || mat.a < 0.5 || mat.r >= limit) {  // the sky, no G-buffer texel, a surface too rough to trace
        out_img.write(float4(0.0, 0.0, 0.0, 0.0), id);
        return;
    }
    const float depth = pre.r;
    const float2 ndc = float2((float(id.x) + 0.5) * params.image.z * 2.0 - 1.0, 1.0 - (float(id.y) + 0.5) * params.image.w * 2.0);
    const float3 pos = params.rayO0.xyz + ndc.x * params.rayOX.xyz + ndc.y * params.rayOY.xyz +
                       (params.rayD0.xyz + ndc.x * params.rayDX.xyz + ndc.y * params.rayDY.xyz) * depth;
    const float3 nv = oct_decode(pre.gb);
    const float3 n = normalize(params.viewRight.xyz * nv.x + params.viewUp.xyz * nv.y + params.viewBack.xyz * nv.z);
    const float3 view = params.camera.w > 0.5 ? -params.viewBack.xyz : normalize(pos - params.camera.xyz);
    const float3 r = reflect(view, n);
    const float3 tint = mix(float3(1.0, 1.0, 1.0), albedo_img.read(id).rgb, saturate(mat.g));
    const float offset = params.user0.x + params.user0.y * depth;
    const float3 origin = pos + n * offset;
    const bool glossy = mat.r >= params.user0.z;
    const uint count = glossy ? clamp(params.frame.z, 1u, 16u) : 1u;
    const float sg = n.z >= 0.0 ? 1.0 : -1.0;
    const float ba = -1.0 / (sg + n.z);
    const float bb = n.x * n.y * ba;
    const float3 tx = float3(1.0 + sg * n.x * n.x * ba, sg * bb, -sg * n.x);
    const float3 ty = float3(bb, sg + n.y * n.y * ba, -n.y);
    const float3 toViewer = -view;
    const float3 ve = normalize(float3(dot(tx, toViewer), dot(ty, toViewer), max(dot(n, toViewer), 1.0e-3)));
    const float alpha = mat.r * mat.r;
    const float invCount = 1.0 / float(count);
    uint state = pcg(id.x + pcg(id.y + pcg(params.frame.y)));
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
        if (rt_trace_surface(tlas, records, hit, origin, dir, 0.0, params.user0.w, s)) {
            sum += rt_shade_hit(tlas, hit, s, -dir) * tint;
            distSum += s.t;
            ++hits;
        }
    }
    if (hits > 0) {
        out_img.write(float4(sum / float(hits), max(distSum / float(hits), 0.0001)), id);
    } else {
        out_img.write(float4(0.0, 0.0, 0.0, -1.0), id);
    }
}
