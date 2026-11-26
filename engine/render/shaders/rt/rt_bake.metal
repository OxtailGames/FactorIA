// Metal twin of rt_bake.hlsl (MSL 2.4, inline `intersection_query`): the same algorithm and the same integer hash, with the bindings of the
// contract in the HLSL file (the tlas is buffer(0), the output texture(0), the constants buffer(1), and sokol numbers the storage buffers
// from 8: the scene buffer(8), the texels buffer(9), the sky buffer(10)). It is compiled at run time with MTLDevice newLibraryWithSource
// (languageVersion 2_4), never by the build. tools/shaders/compile_rt_shaders.sh embeds this text in the generated header.
#include <metal_stdlib>
#include <metal_raytracing>
using namespace metal;
using namespace metal::raytracing;

// BEGIN BakeParams
struct BakeParams {
    uint4 a;
    uint4 b;
    uint4 c;
    float4 d;
    float4 zenith;
    float4 horizon;
    float4 ground;
};
// END BakeParams

constant float kFar = 1.0e30;
constant float kPi = 3.14159265358979;
constant float kTwoPi = 6.28318530717958647692;
constant uint kLightStride = 8;
constant uint kCasterStride = 3;

// The resources every helper needs, as one macro (MSL has no global resources).
#define RES_DECL \
    instance_acceleration_structure tlas, constant BakeParams& params, device const float4* scene, device const float4* sky
#define RES_ARGS tlas, params, scene, sky

typedef uint2 u64;

u64 u64_make(uint lo) { return uint2(lo, 0u); }
u64 u64_add(u64 a, u64 b) {
    const uint lo = a.x + b.x;
    return uint2(lo, a.y + b.y + (lo < a.x ? 1u : 0u));
}
u64 u64_xor(u64 a, u64 b) { return uint2(a.x ^ b.x, a.y ^ b.y); }
u64 u64_shr(u64 a, uint n) { return uint2((a.x >> n) | (a.y << (32u - n)), a.y >> n); }

uint mulhi32(uint a, uint b) {
    const uint a0 = a & 0xFFFFu, a1 = a >> 16u, b0 = b & 0xFFFFu, b1 = b >> 16u;
    const uint p00 = a0 * b0, p01 = a0 * b1, p10 = a1 * b0, p11 = a1 * b1;
    const uint mid = (p00 >> 16u) + (p01 & 0xFFFFu) + (p10 & 0xFFFFu);
    return p11 + (p01 >> 16u) + (p10 >> 16u) + (mid >> 16u);
}
u64 u64_mul(u64 a, u64 b) { return uint2(a.x * b.x, mulhi32(a.x, b.x) + a.x * b.y + a.y * b.x); }

u64 mix64(u64 x) {
    x = u64_add(x, uint2(0x7f4a7c15u, 0x9e3779b9u));
    x = u64_mul(u64_xor(x, u64_shr(x, 30u)), uint2(0x1ce4e5b9u, 0xbf58476du));
    x = u64_mul(u64_xor(x, u64_shr(x, 27u)), uint2(0x133111ebu, 0x94d049bbu));
    return u64_xor(x, u64_shr(x, 31u));
}
u64 combine(u64 key, uint v) { return mix64(u64_xor(key, mix64(u64_add(u64_make(v), uint2(0xd9b4e019u, 0x632be59bu))))); }
float to_unit(u64 h) { return float(h.y >> 8u) * (1.0 / 16777216.0); }
float rnd(u64 key, uint dim) { return to_unit(combine(key, dim)); }
float fract1(float x) { return x - floor(x); }

float radical2(uint i) {
    i = (i << 16u) | (i >> 16u);
    i = ((i & 0x55555555u) << 1u) | ((i & 0xAAAAAAAAu) >> 1u);
    i = ((i & 0x33333333u) << 2u) | ((i & 0xCCCCCCCCu) >> 2u);
    i = ((i & 0x0F0F0F0Fu) << 4u) | ((i & 0xF0F0F0F0u) >> 4u);
    i = ((i & 0x00FF00FFu) << 8u) | ((i & 0xFF00FF00u) >> 8u);
    return float(i) * 2.3283064365386963e-10;
}

float2 sample2d(float r1, float r2, uint s, uint count) {
    if (count <= 1u) return float2(r1, r2);
    return float2(fract1((float(s) + 0.5) / float(count) + r1), fract1(radical2(s) + r2));
}

struct Basis {
    float3 t, b, n;
};
Basis basis_of(float3 n) {
    const float3 ref = abs(n.x) < 0.9 ? float3(1.0, 0.0, 0.0) : float3(0.0, 1.0, 0.0);
    Basis bs;
    bs.t = normalize(cross(ref, n));
    bs.b = cross(n, bs.t);
    bs.n = n;
    return bs;
}
float3 to_world(Basis bs, float3 l) { return bs.t * l.x + bs.b * l.y + bs.n * l.z; }
float3 cosine_hemisphere(Basis bs, float u1, float u2) {
    const float r = sqrt(u1);
    const float s = sin(kTwoPi * u2), c = cos(kTwoPi * u2);
    return normalize(to_world(bs, float3(r * c, r * s, sqrt(max(0.0, 1.0 - u1)))));
}

float max3(float3 v) { return max(v.x, max(v.y, v.z)); }
float smoothstep2(float e0, float e1, float x) {
    if (e1 == e0) return x >= e1 ? 1.0 : 0.0;
    const float t = saturate((x - e0) / (e1 - e0));
    return t * t * (3.0 - 2.0 * t);
}

// The one ray query of the kernel (Apple's GPU compiler crashes on two sites with different parameters: the shadow rays go through here too).
bool bake_trace(RES_DECL, float3 origin, float3 dir, float tmax, bool anyHit, thread float& t, thread uint& prim) {
    ray r;
    r.origin = origin;
    r.min_distance = 0.0;
    r.direction = dir;
    r.max_distance = tmax;
    intersection_params ip;
    ip.accept_any_intersection(anyHit);
    intersection_query<instancing, triangle_data> q;
    q.reset(r, tlas, 0xFFu, ip);
    while (q.next()) {}
    t = 0.0;
    prim = 0u;
    if (q.get_committed_intersection_type() != intersection_type::triangle) return false;
    t = q.get_committed_distance();
    prim = q.get_committed_primitive_id();
    return true;
}

float3 sky_pixel(RES_DECL, int x, int y) {
    const int w = int(params.c.z), h = int(params.c.w);
    x = ((x % w) + w) % w;
    y = min(max(y, 0), h - 1);
    return sky[uint(y) * uint(w) + uint(x)].xyz;
}
float3 sky_radiance(RES_DECL, float3 d) {
    if (params.c.z > 0u && params.c.w > 0u) {
        const float w = float(params.c.z), h = float(params.c.w);
        const float u = fract1(0.5 + atan2(d.z, d.x) / kTwoPi + params.d.y);
        const float v = acos(clamp(d.y, -1.0, 1.0)) / kPi;
        const float fx = u * w - 0.5, fy = clamp(v * h - 0.5, 0.0, h - 1.0);
        const int x0 = int(floor(fx)), y0 = int(floor(fy));
        const float tx = fx - float(x0), ty = fy - float(y0);
        const float3 top = mix(sky_pixel(RES_ARGS, x0, y0), sky_pixel(RES_ARGS, x0 + 1, y0), tx);
        const float3 bot = mix(sky_pixel(RES_ARGS, x0, y0 + 1), sky_pixel(RES_ARGS, x0 + 1, y0 + 1), tx);
        return mix(top, bot, ty) * params.d.z;
    }
    return d.y >= 0.0 ? mix(params.horizon.xyz, params.zenith.xyz, saturate(d.y))
                      : mix(params.horizon.xyz, params.ground.xyz, saturate(-d.y));
}

bool sample_light(RES_DECL, uint li, float3 P, float u1, float u2, thread float3& dir, thread float& dist,
                  thread float3& weight) {
    const uint base = li * kLightStride;
    const float4 h = scene[base], c = scene[base + 1], p = scene[base + 2], dr = scene[base + 3],
                 r = scene[base + 4], up = scene[base + 5], wh = scene[base + 6];
    const uint kind = uint(h.x + 0.5);
    dir = float3(0.0, 1.0, 0.0);
    dist = kFar;
    weight = float3(0.0, 0.0, 0.0);
    if (kind == 0u) {
        dir = -dr.xyz;
        if (up.w > 0.0) {
            Basis bs = basis_of(dir);
            const float rr = sqrt(u1) * up.w;
            const float s = sin(kTwoPi * u2), cc = cos(kTwoPi * u2);
            dir = normalize(dir + bs.t * (rr * cc) + bs.b * (rr * s));
        }
        dist = kFar;
        weight = c.xyz;
        return true;
    }
    float3 target = p.xyz;
    const float3 centre = p.xyz - P;
    const float centreLen = length(centre);
    if (centreLen < 1e-5) return false;
    const float3 centreDir = centre / centreLen;
    if (kind == 3u) {
        target = p.xyz + r.xyz * ((u1 - 0.5) * wh.x) + up.xyz * ((u2 - 0.5) * wh.y);
    } else if (r.w > 0.0) {
        Basis bs = basis_of(centreDir);
        const float rr = sqrt(u1) * r.w;
        const float s = sin(kTwoPi * u2), cc = cos(kTwoPi * u2);
        target = p.xyz + bs.t * (rr * cc) + bs.b * (rr * s);
    }
    const float3 to = target - P;
    const float d2 = max(dot(to, to), 1e-4);
    dist = sqrt(d2);
    dir = to / dist;
    if (kind == 3u) {
        const float cosl = dot(dr.xyz, -dir);
        if (cosl <= 0.0) return false;
        weight = c.xyz * (cosl * wh.x * wh.y / (kPi * d2));
        return true;
    }
    float atten;
    if (h.w < 0.5) {
        const float x = saturate(1.0 - (dist / c.w) * (dist / c.w));
        atten = x * x;
    } else {
        atten = 1.0 / d2;
        if (c.w > 0.0) {
            const float q = dist / c.w;
            const float x = saturate(1.0 - q * q * q * q);
            atten *= x * x;
        }
    }
    if (kind == 2u) {
        const float cosA = dot(-centreDir, dr.xyz);
        atten *= smoothstep2(p.w, dr.w > 0.0 ? dr.w : p.w + (1.0 - p.w) * 0.25, cosA);
    }
    if (atten <= 0.0) return false;
    weight = c.xyz * atten;
    return true;
}

float3 direct_light(RES_DECL, float3 P, float3 Ns, float3 Ng, u64 key, uint count, bool atBounce) {
    float3 sum = float3(0.0, 0.0, 0.0);
    const float eps = params.d.x;
    const float3 o = P + Ng * eps;
    for (uint li = 0u; li < params.c.x; ++li) {
        const float4 h = scene[li * kLightStride];
        if ((atBounce ? h.z : h.y) < 0.5) continue;
        const u64 lkey = combine(key, 0x1000u + li);
        const float r1 = rnd(lkey, 0x51u), r2 = rnd(lkey, 0x52u);
        float3 acc = float3(0.0, 0.0, 0.0);
        for (uint s = 0u; s < count; ++s) {
            const float2 u = sample2d(r1, r2, s, count);
            float3 dir, w;
            float dist;
            if (!sample_light(RES_ARGS, li, o, u.x, u.y, dir, dist, w)) continue;
            const float ndl = dot(Ns, dir);
            if (ndl <= 1e-4 || dot(Ng, dir) <= 1e-4) continue;
            float t;
            uint prim;
            if (bake_trace(RES_ARGS, o, dir, dist - 2.0 * eps, true, t, prim)) continue;
            acc += w * ndl;
        }
        sum += acc / float(count);
    }
    return sum;
}

float3 path_trace(RES_DECL, float3 o, float3 d, u64 key) {
    float3 result = float3(0.0, 0.0, 0.0), T = float3(1.0, 1.0, 1.0);
    const float eps = params.d.x;
    const uint bounces = params.b.z;
    for (uint depth = 1u;; ++depth) {
        float t;
        uint prim;
        if (!bake_trace(RES_ARGS, o, d, kFar, false, t, prim)) {
            result += T * sky_radiance(RES_ARGS, d);
            break;
        }
        const uint cb = params.c.y + prim * kCasterStride;
        const float3 P = o + d * t;
        float3 Ng = scene[cb].xyz;
        if (dot(Ng, d) > 0.0) Ng = -Ng;
        result += T * scene[cb + 2u].xyz;
        if (depth > bounces) break;
        const float3 alb = scene[cb + 1u].xyz;
        if (max3(alb) <= 0.0) break;
        const u64 dkey = combine(key, 0x2000u + depth);
        result += T * alb * direct_light(RES_ARGS, P, Ng, Ng, dkey, 1u, true);
        T = T * alb;
        if (depth >= 2u) {
            const float pk = clamp(max3(T), 0.05, 1.0);
            if (rnd(dkey, 0x77u) >= pk) break;
            T = T / pk;
        }
        d = cosine_hemisphere(basis_of(Ng), rnd(dkey, 0x78u), rnd(dkey, 0x79u));
        o = P + Ng * eps;
    }
    return result;
}

kernel void rt_bake(instance_acceleration_structure tlas [[buffer(0)]],
                    texture2d<float, access::write> out_img [[texture(0)]],
                    constant BakeParams& params [[buffer(1)]],
                    device const float4* scene [[buffer(8)]],
                    device const uint4* texels [[buffer(9)]],
                    device const float4* sky [[buffer(10)]],
                    uint3 id [[thread_position_in_grid]]) {
    const uint k = id.x;
    if (k >= params.a.x) return;
    const uint4 ta = texels[3u * k], tb = texels[3u * k + 1u], tc = texels[3u * k + 2u];
    const float3 P = as_type<float3>(ta.xyz), Ns = as_type<float3>(tb.xyz), Ng = as_type<float3>(tc.xyz);
    const u64 key = combine(uint2(params.b.x, params.b.y), ta.w);
    const float eps = params.d.x;
    float3 direct = float3(0.0, 0.0, 0.0);
    if (params.a.y == 0u) direct = direct_light(RES_ARGS, P, Ns, Ng, combine(key, 0xD1u), params.b.w, false);
    const Basis bs = basis_of(Ns);
    const float3 o = P + Ng * eps;
    const float r1 = rnd(key, 0x51u), r2 = rnd(key, 0x52u);
    float3 gather = float3(0.0, 0.0, 0.0);
    for (uint s = params.a.y; s < params.a.z; ++s) {
        const u64 skey = combine(key, 0x10000u + s);
        const float2 u = sample2d(r1, r2, s, params.a.w);
        const float3 d = cosine_hemisphere(bs, u.x, u.y);
        if (dot(d, Ng) <= 1e-4) continue;
        gather += path_trace(RES_ARGS, o, d, skey);
    }
    const uint2 px = uint2(2u * (k % 1024u), k / 1024u);
    out_img.write(float4(direct, 0.0), px);
    out_img.write(float4(gather, 0.0), px + uint2(1u, 0u));
}
