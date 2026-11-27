// The GPU lightmap bake (M79-P5b, docs/design/ARCHITECTURE_BAKING.md "The GPU bake"): the path tracer of the CPU baker
// (engine/scene/src/lightmap_bake.cpp) as a compute kernel, one thread per texel. A texel's direct light (a shadow ray per sample of every
// Baked light) and its gather (cosine-weighted rays that bounce `bounces` times, a shadow ray to every light at each bounce, Russian
// roulette from the third hit on) are the same algorithm with the same integer hash: the SAME random numbers, so the GPU image is the CPU
// image up to float rounding (sin, cos, the ray-triangle test) and the few paths a rounding flips. It is a fast preview, never the
// reference: the CPU baker stays bit-exact (docs/design/ARCHITECTURE_BAKING.md, "Determinism").
//
// HLSL is the source of the D3D12 (DXIL, cs_6_5) and Vulkan (SPIR-V, SPV_KHR_ray_query) kernels, compiled with DXC by
// tools/shaders/compile_rt_shaders.sh; engine/render/shaders/rt/rt_bake.metal is the Metal twin (MSL 2.4, compiled at run time). Keep the two
// the same algorithm, line by line. The scene is the bake's own (a TLAS of one instance holding every triangle that casts a shadow, built by
// engine/render/src/lightmap_gpu_bake.cpp), not the renderer's.
//
//   binding 0  g_tlas    acceleration structure                       t0   (Metal: buffer(0))
//   binding 1  g_out     storage image, rgba32f                       u0   (Metal: texture(0))
//   binding 2  g_params  constant buffer, BakeParams                  b0   (Metal: buffer(1))
//   binding 4  g_scene   StructuredBuffer<float4>: the lights, then the casters   t2   (Metal: buffer(8))
//   binding 5  g_texels  StructuredBuffer<uint4>: the texels of the dispatch      t3   (Metal: buffer(9))
//   binding 6  g_sky     StructuredBuffer<float4>: the pixels of the sky image    t4   (Metal: buffer(10))
//
// Output (the image is 2048 pixels wide, texel k of the dispatch writes the pixels (2 (k % 1024), k / 1024) and the one to its right): the
// first holds the direct light of the texel (zero unless this dispatch starts at sample 0), the second the SUM of the gather over the
// samples [sampleBegin, sampleEnd) of this dispatch. The CPU adds the sums of the dispatches in order and divides by the sample count, so the
// result does not depend on how the work was cut (the cuts depend on the counts only).

// BEGIN BakeParams
struct BakeParams {
    uint4 a;  // x: texels in this dispatch, y: sampleBegin, z: sampleEnd, w: samples (all of them)
    uint4 b;  // x, y: the atlas key (low, high word), z: bounces, w: shadow samples per light
    uint4 c;  // x: light count, y: the first caster (index in float4 units of g_scene), z: sky width, w: sky height
    float4 d;       // x: the ray offset (eps), y: the sky's rotation in turns, z: the sky's intensity, w: 0
    float4 zenith;  // xyz: the gradient sky (intensity applied), w: 0
    float4 horizon;
    float4 ground;
};
// END BakeParams
[[vk::binding(0, 0)]] RaytracingAccelerationStructure g_tlas : register(t0);
[[vk::binding(1, 0)]] [[vk::image_format("rgba32f")]] RWTexture2D<float4> g_out : register(u0);
[[vk::binding(2, 0)]] ConstantBuffer<BakeParams> g_params : register(b0);
[[vk::binding(4, 0)]] StructuredBuffer<float4> g_scene : register(t2);
[[vk::binding(5, 0)]] StructuredBuffer<uint4> g_texels : register(t3);
[[vk::binding(6, 0)]] StructuredBuffer<float4> g_sky : register(t4);

static const float kFar = 1.0e30;
static const float kPi = 3.14159265358979;
static const float kTwoPi = 6.28318530717958647692;
static const uint kLightStride = 8;  // float4 per light in g_scene
static const uint kCasterStride = 3;  // float4 per caster: the unit face normal, the albedo, the emissive

// ---- 64-bit integers as (low, high) pairs of 32-bit ones: the same hash as the CPU baker (mix64, combine), on every GPU ----------------------

typedef uint2 u64;

u64 u64_make(uint lo) { return uint2(lo, 0u); }
u64 u64_add(u64 a, u64 b) {
    const uint lo = a.x + b.x;
    return uint2(lo, a.y + b.y + (lo < a.x ? 1u : 0u));
}
u64 u64_xor(u64 a, u64 b) { return uint2(a.x ^ b.x, a.y ^ b.y); }
u64 u64_shr(u64 a, uint n) { return uint2((a.x >> n) | (a.y << (32u - n)), a.y >> n); }  // 0 < n < 32

// The high word of a * b (both 32 bits), with 16-bit limbs.
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
// 0 <= result < 1, from the high 24 bits (exact in a float)
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

// Sample s of count of a 2D point set, shifted by the key's two numbers r1, r2 (rnd(key, 0x51), rnd(key, 0x52); the caller keeps them).
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
    float s, c;
    sincos(kTwoPi * u2, s, c);
    return normalize(to_world(bs, float3(r * c, r * s, sqrt(max(0.0, 1.0 - u1)))));
}

float max3(float3 v) { return max(v.x, max(v.y, v.z)); }
float smoothstep2(float e0, float e1, float x) {
    if (e1 == e0) return x >= e1 ? 1.0 : 0.0;
    const float t = saturate((x - e0) / (e1 - e0));
    return t * t * (3.0 - 2.0 * t);
}

// ---- the one ray query of the kernel (Metal accepts one call site per kernel: the shadow rays go through here with anyHit set) -------------

bool trace(float3 origin, float3 dir, float tmax, bool anyHit, out float t, out uint prim) {
    RayDesc ray;
    ray.Origin = origin;
    ray.TMin = 0.0;
    ray.Direction = dir;
    ray.TMax = tmax;
    RayQuery<RAY_FLAG_NONE> q;
    q.TraceRayInline(g_tlas, anyHit ? RAY_FLAG_ACCEPT_FIRST_HIT_AND_END_SEARCH : RAY_FLAG_NONE, 0xFFu, ray);
    while (q.Proceed()) {}
    t = 0.0;
    prim = 0u;
    if (q.CommittedStatus() != COMMITTED_TRIANGLE_HIT) return false;
    t = q.CommittedRayT();
    prim = q.CommittedPrimitiveIndex();
    return true;
}

// ---- the sky ----------------------------------------------------------------------------------------------------------------------------

float3 sky_pixel(int x, int y) {
    const int w = int(g_params.c.z), h = int(g_params.c.w);
    x = ((x % w) + w) % w;
    y = min(max(y, 0), h - 1);
    return g_sky[uint(y) * uint(w) + uint(x)].xyz;
}
float3 sky_radiance(float3 d) {
    if (g_params.c.z > 0u && g_params.c.w > 0u) {
        const float w = float(g_params.c.z), h = float(g_params.c.w);
        const float u = fract1(0.5 + atan2(d.z, d.x) / kTwoPi + g_params.d.y);
        const float v = acos(clamp(d.y, -1.0, 1.0)) / kPi;
        const float fx = u * w - 0.5, fy = clamp(v * h - 0.5, 0.0, h - 1.0);
        const int x0 = int(floor(fx)), y0 = int(floor(fy));
        const float tx = fx - float(x0), ty = fy - float(y0);
        const float3 top = lerp(sky_pixel(x0, y0), sky_pixel(x0 + 1, y0), tx);
        const float3 bot = lerp(sky_pixel(x0, y0 + 1), sky_pixel(x0 + 1, y0 + 1), tx);
        return lerp(top, bot, ty) * g_params.d.z;
    }
    return d.y >= 0.0 ? lerp(g_params.horizon.xyz, g_params.zenith.xyz, saturate(d.y))
                      : lerp(g_params.horizon.xyz, g_params.ground.xyz, saturate(-d.y));
}

// ---- the lights ---------------------------------------------------------------------------------------------------------------------------
// A light is 8 float4 in g_scene: [0] kind, direct (0/1), bounce (0/1), falloff; [1] colour * intensity, range; [2] position, cosOuter;
// [3] unit direction, cosInner; [4] right, softRadius; [5] up, tanSoft; [6] width, height.

bool sample_light(uint li, float3 P, float u1, float u2, out float3 dir, out float dist, out float3 weight) {
    const uint base = li * kLightStride;
    const float4 h = g_scene[base], c = g_scene[base + 1], p = g_scene[base + 2], dr = g_scene[base + 3], r = g_scene[base + 4],
                 up = g_scene[base + 5], wh = g_scene[base + 6];
    const uint kind = uint(h.x + 0.5);  // 0 directional, 1 point, 2 spot, 3 area
    dir = float3(0.0, 1.0, 0.0);
    dist = kFar;
    weight = float3(0.0, 0.0, 0.0);
    if (kind == 0u) {
        dir = -dr.xyz;
        if (up.w > 0.0) {
            Basis bs = basis_of(dir);
            const float rr = sqrt(u1) * up.w;
            float s, cc;
            sincos(kTwoPi * u2, s, cc);
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
        float s, cc;
        sincos(kTwoPi * u2, s, cc);
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
    if (h.w < 0.5) {  // BakeFalloff::Engine
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

// The direct light at a surface point: every light that lights the texels (atBounce false) or the paths (true), `count` shadow rays each.
float3 direct_light(float3 P, float3 Ns, float3 Ng, u64 key, uint count, bool atBounce) {
    float3 sum = float3(0.0, 0.0, 0.0);
    const float eps = g_params.d.x;
    const float3 o = P + Ng * eps;
    for (uint li = 0u; li < g_params.c.x; ++li) {
        const float4 h = g_scene[li * kLightStride];
        if ((atBounce ? h.z : h.y) < 0.5) continue;
        const u64 lkey = combine(key, 0x1000u + li);
        const float r1 = rnd(lkey, 0x51u), r2 = rnd(lkey, 0x52u);
        float3 acc = float3(0.0, 0.0, 0.0);
        for (uint s = 0u; s < count; ++s) {
            const float2 u = sample2d(r1, r2, s, count);
            float3 dir, w;
            float dist;
            if (!sample_light(li, o, u.x, u.y, dir, dist, w)) continue;
            const float ndl = dot(Ns, dir);
            if (ndl <= 1e-4 || dot(Ng, dir) <= 1e-4) continue;
            float t;
            uint prim;
            if (trace(o, dir, dist - 2.0 * eps, true, t, prim)) continue;
            acc += w * ndl;
        }
        sum += acc / float(count);
    }
    return sum;
}

// The radiance that comes back along the ray (o, d): what it sees, plus the bounces of light after the first hit.
float3 path_trace(float3 o, float3 d, u64 key) {
    float3 result = float3(0.0, 0.0, 0.0), T = float3(1.0, 1.0, 1.0);
    const float eps = g_params.d.x;
    const uint bounces = g_params.b.z;
    for (uint depth = 1u;; ++depth) {
        float t;
        uint prim;
        if (!trace(o, d, kFar, false, t, prim)) {
            result += T * sky_radiance(d);
            break;
        }
        const uint cb = g_params.c.y + prim * kCasterStride;
        const float3 P = o + d * t;
        float3 Ng = g_scene[cb].xyz;
        if (dot(Ng, d) > 0.0) Ng = -Ng;
        result += T * g_scene[cb + 2u].xyz;
        if (depth > bounces) break;
        const float3 alb = g_scene[cb + 1u].xyz;
        if (max3(alb) <= 0.0) break;
        const u64 dkey = combine(key, 0x2000u + depth);
        result += T * alb * direct_light(P, Ng, Ng, dkey, 1u, true);
        T = T * alb;
        if (depth >= 2u) {  // Russian roulette: continue with probability p and weigh the survivors 1/p (unbiased)
            const float pk = clamp(max3(T), 0.05, 1.0);
            if (rnd(dkey, 0x77u) >= pk) break;
            T = T / pk;
        }
        d = cosine_hemisphere(basis_of(Ng), rnd(dkey, 0x78u), rnd(dkey, 0x79u));
        o = P + Ng * eps;
    }
    return result;
}

[numthreads(64, 1, 1)]
void main(uint3 id : SV_DispatchThreadID) {
    const uint k = id.x;
    if (k >= g_params.a.x) return;
    const uint4 ta = g_texels[3u * k], tb = g_texels[3u * k + 1u], tc = g_texels[3u * k + 2u];
    const float3 P = asfloat(ta.xyz), Ns = asfloat(tb.xyz), Ng = asfloat(tc.xyz);
    const u64 key = combine(uint2(g_params.b.x, g_params.b.y), ta.w);
    const float eps = g_params.d.x;
    float3 direct = float3(0.0, 0.0, 0.0);
    if (g_params.a.y == 0u) direct = direct_light(P, Ns, Ng, combine(key, 0xD1u), g_params.b.w, false);
    const Basis bs = basis_of(Ns);
    const float3 o = P + Ng * eps;
    const float r1 = rnd(key, 0x51u), r2 = rnd(key, 0x52u);
    float3 gather = float3(0.0, 0.0, 0.0);
    for (uint s = g_params.a.y; s < g_params.a.z; ++s) {
        const u64 skey = combine(key, 0x10000u + s);
        const float2 u = sample2d(r1, r2, s, g_params.a.w);
        const float3 d = cosine_hemisphere(bs, u.x, u.y);
        if (dot(d, Ng) <= 1e-4) continue;  // a shading normal that leans over the edge of the face
        gather += path_trace(o, d, skey);
    }
    const uint2 px = uint2(2u * (k % 1024u), k / 1024u);
    g_out[px] = float4(direct, 0.0);
    g_out[px + uint2(1u, 0u)] = float4(gather, 0.0);
}
