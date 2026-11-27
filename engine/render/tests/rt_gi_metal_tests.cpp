// M79-P4a: the realtime GI probe kernel (shaders/rt/rt_gi.metal, with the hit shading of rt_hit.msli) run for real on a Mac whose GPU
// traces rays, through the SokolDevice. Two probes in a small scene (a floor, a box with an emissive colour; one probe in the open above
// the floor, one inside the box), the records of the instances in the buffer the renderer's scene would hold, the constants by the
// engine's own RtGiParams; the band image the kernel writes (the SH row, the meta texel and the depth map of each probe's block, the blend
// weight in alpha) is compared with a CPU reference over the same rays (rt_gi_direction) and triangles. A second run with the same seed must
// write the same bytes, another seed other bytes, and the back-face fraction of the probe inside the box is 1: it is what calibrates
// rt_gi_front_sense (rt_gi.h) on this backend. A machine without ray tracing says so and skips. The D3D12 and Vulkan kernels are the same HLSL
// compiled by DXC; no test in this suite runs them.
#include <doctest.h>

#include <algorithm>
#include <array>
#include <cmath>
#include <cstdint>
#include <cstring>
#include <memory>
#include <string>
#include <vector>

#if defined(__APPLE__)

// Only a Mac builds what needs Metal and the device headers; every other host compiles the one skipped case below.
#include "fa/core/math.h"
#include "fa/render/gi.h"
#include "gpu/accel.h"
#include "gpu/device.h"
#include "gpu/sokol_device.h"
#include "hdr_encode.h"
#include "rt_effect.h"
#include "rt_gi.h"
#include "rt_kernels.h"
#include "rt_records.h"
#include "rt_gi_test_scene.h"
#include "test_util.h"

using namespace fa;
using namespace fa::gpu;
using fa::test::gi::make_box;
using fa::test::gi::make_quad;
using fa::test::gi::Mesh;
using fa::test::gi::Place;
using fa::test::gi::Rig;

namespace {

struct Tri {
    Vec3 a, b, c;
    std::uint8_t mask = 0xFF;
    int instance = 0;
};

bool hit_tri(Vec3 o, Vec3 d, const Tri& t, float grow, float tMin, float tMax, float& out) {
    const Vec3 e1 = t.b - t.a, e2 = t.c - t.a;
    const Vec3 p = cross(d, e2);
    const float det = dot(e1, p);
    if (std::fabs(det) < 1e-12f) return false;
    const float inv = 1.0f / det;
    const Vec3 s = o - t.a;
    const float u = dot(s, p) * inv;
    const Vec3 q = cross(s, e1);
    const float v = dot(d, q) * inv;
    if (u < -grow || v < -grow || u + v > 1.0f + grow) return false;
    out = dot(e2, q) * inv;
    return out >= tMin && out <= tMax;
}

struct Nearest {
    float t = 1.0e30f;
    int tri = -1;
};

Nearest nearest(const std::vector<Tri>& tris, Vec3 o, Vec3 d, float grow, float tMin, float tMax, int mask) {
    Nearest n;
    for (std::size_t i = 0; i < tris.size(); ++i) {
        if ((tris[i].mask & mask) == 0) continue;
        float t = 0;
        if (hit_tri(o, d, tris[i], grow, tMin, tMax, t) && t < n.t) {
            n.t = t;
            n.tri = int(i);
        }
    }
    return n;
}

float comp(Vec3 v, int c) { return c == 0 ? v.x : (c == 1 ? v.y : v.z); }

// ---- the CPU port of rt_hit.hlsli ------------------------------------------------------------------------------------------------------

struct Scene {
    Vec3 sunDir, sunColor, ambient, sky, horizon;
    float shadowOffset = 0.02f, shadowOffsetPerMetre = 0.002f;
};

struct Material {
    Vec3 albedo;
    float roughness = 0.5f, metalness = 0.0f;
    Vec3 emissive{0, 0, 0};
};

float smoothstep(float a, float b, float x) {
    const float t = clamp((x - a) / (b - a), 0.0f, 1.0f);
    return t * t * (3.0f - 2.0f * t);
}

Vec3 environment(const Scene& sc, Vec3 d, float rough) {
    const float blur = rough * rough;
    const float h = clamp(d.y * (1.0f - 0.7f * blur), 0.0f, 1.0f);
    const Vec3 up = lerp(sc.horizon, sc.sky, std::pow(h, 0.55f));
    const Vec3 down = sc.horizon * 0.55f;
    const float k = smoothstep(-0.05f - 0.6f * blur, 0.05f + 0.6f * blur, d.y);
    const Vec3 e = lerp(down, up, k);
    return lerp(e, (sc.sky + sc.horizon) * 0.5f * 0.8f, blur * 0.6f);
}

Vec2 env_brdf(float rough, float ndv) {
    const float c0[4] = {-1.0f, -0.0275f, -0.572f, 0.022f};
    const float c1[4] = {1.0f, 0.0425f, 1.04f, -0.04f};
    float r[4];
    for (int i = 0; i < 4; ++i) r[i] = rough * c0[i] + c1[i];
    const float a004 = std::min(r[0] * r[0], std::exp2(-9.28f * ndv)) * r[0] + r[1];
    return {-1.04f * a004 + r[2], 1.04f * a004 + r[3]};
}

Vec3 reflect_dir(Vec3 i, Vec3 n) { return i - n * (2.0f * dot(n, i)); }

// rt_shade_hit: `p` the hit, `n` the unit normal toward the ray, `toViewer` the unit vector back along the ray, `t` the hit distance.
Vec3 shade_hit(const Scene& sc, const std::vector<Tri>& tris, const Material& m, Vec3 p, Vec3 n, Vec3 toViewer,
               float t) {
    const Vec3 v = toViewer;
    const float roughness = clamp(m.roughness, 0.05f, 1.0f);
    const Vec3 diffuse = m.albedo * (1.0f - m.metalness);
    const Vec3 f0 = lerp(Vec3{0.04f, 0.04f, 0.04f}, m.albedo, m.metalness);
    const float ndv = std::max(dot(n, v), 1.0e-4f);
    Vec3 color = sc.ambient * diffuse;
    const Vec2 ab = env_brdf(roughness, ndv);
    color += environment(sc, reflect_dir(v * -1.0f, n), roughness) * (f0 * ab.x + Vec3{ab.y, ab.y, ab.y});
    const Vec3 l = sc.sunDir;
    const float ndl = dot(n, l);
    if (ndl > 0.0f) {
        const float off = sc.shadowOffset + sc.shadowOffsetPerMetre * t;
        const bool shadowed = nearest(tris, p + n * off, l, -1e-3f, 0.0f, 10000.0f, 0x08).tri >= 0;
        if (!shadowed) {
            const float alpha = roughness * roughness;
            const float a2 = alpha * alpha;
            const Vec3 h = normalize(l + v);
            const float ndh = saturate(dot(n, h));
            const float vdh = saturate(dot(v, h));
            const float dd = ndh * ndh * (a2 - 1.0f) + 1.0f;
            const float d = a2 / (3.14159265358979f * dd * dd);
            const float vis =
                0.5f / (ndl * std::sqrt(ndv * ndv * (1.0f - a2) + a2) + ndv * std::sqrt(ndl * ndl * (1.0f - a2) + a2));
            const float fw = std::pow(1.0f - vdh, 5.0f);
            const Vec3 f = f0 + (Vec3{1, 1, 1} - f0) * fw;
            color += (diffuse + f * (d * vis)) * sc.sunColor * ndl;
        }
    }
    return color + m.emissive;
}

float sh_basis(int k, Vec3 d) {
    switch (k) {
        case 0: return 0.282094792f;
        case 1: return 0.488602512f * d.y;
        case 2: return 0.488602512f * d.z;
        case 3: return 0.488602512f * d.x;
        case 4: return 1.092548431f * d.x * d.y;
        case 5: return 1.092548431f * d.y * d.z;
        case 6: return 0.315391565f * (3.0f * d.z * d.z - 1.0f);
        case 7: return 1.092548431f * d.x * d.z;
        default: return 0.546274215f * (d.x * d.x - d.y * d.y);
    }
}

float fold(float v, float& other) {
    if (v > 1.0f) {
        other = -other;
        return 2.0f - v;
    }
    if (v < -1.0f) {
        other = -other;
        return -2.0f - v;
    }
    return v;
}

Vec3 oct_decode(Vec2 e) {
    e.x = fold(e.x, e.y);
    e.y = fold(e.y, e.x);
    float x = e.x, z = e.y;
    const float y = 1.0f - std::fabs(x) - std::fabs(z);
    if (y < 0.0f) {
        const float nx = (1.0f - std::fabs(z)) * (x >= 0.0f ? 1.0f : -1.0f);
        const float nz = (1.0f - std::fabs(x)) * (z >= 0.0f ? 1.0f : -1.0f);
        x = nx;
        z = nz;
    }
    const float len = std::sqrt(x * x + y * y + z * z);
    return len > 0.0f ? Vec3{x, y, z} / len : Vec3{0, 1, 0};
}

constexpr int kProbes = 2;
constexpr int kRays = 128;
constexpr float kMaxDistance = 20.0f;

struct Band {
    std::vector<float> px;  // RGBA, kProbeAtlasSize x fa::render::kGiBandHeight
    const float* at(int x, int y) const {
        return &px[(std::size_t(y) * fa::render::kProbeAtlasSize + std::size_t(x)) * 4];
    }
};

}  // namespace

TEST_CASE("rt gi on Metal: the probes' SH, depth and back-face texels are what a CPU ray caster computes over the same "
          "rays") {
    Rig rig;
    std::string skip;
    const Backend metal = Backend::Metal;
    if (!rig.open(skip, &metal)) {
        MESSAGE("skipped: " << skip);
        return;
    }
    Device& dev = *rig.dev;
    MESSAGE("Metal ray tracing: vendor " << std::string(gpu_vendor_name(dev.info().gpu.vendor)));

    Mesh ground = make_quad(), box = make_box();
    // What the CPU port shades with: the same numbers the records get.
    const std::array<Material, 2> materials = {Material{{0.5f, 0.5f, 0.5f}, 0.0f, 0.5f, {0, 0, 0}},
                                               Material{{0.2f, 0.2f, 0.2f}, 0.0f, 0.8f, {0.6f, 0.15f, 0.05f}}};
    const std::vector<Place> places = {Place{&ground,
                                             {0, 0, 0},
                                             materials[0].albedo,
                                             materials[0].roughness,
                                             materials[0].metalness,
                                             materials[0].emissive},
                                       Place{&box,
                                             {3.0f, 0.5f, 0},
                                             materials[1].albedo,
                                             materials[1].roughness,
                                             materials[1].metalness,
                                             materials[1].emissive}};
    std::vector<Tri> tris;
    for (std::size_t pi = 0; pi < places.size(); ++pi) {
        const Place& p = places[pi];
        for (std::size_t i = 0; i + 2 < p.mesh->indices.size(); i += 3)
            tris.push_back({p.mesh->vertices[p.mesh->indices[i]] + p.at,
                            p.mesh->vertices[p.mesh->indices[i + 1]] + p.at,
                            p.mesh->vertices[p.mesh->indices[i + 2]] + p.at, fa::test::gi::kMask, int(pi)});
    }
    rig.build_scene(places);
    rig.make_pipeline();

    Scene sc;
    sc.sunDir = normalize(Vec3{-0.5f, 0.7f, -0.45f});
    sc.sunColor = {3.0f, 2.8f, 2.5f};
    sc.ambient = {0.10f, 0.10f, 0.12f};
    sc.sky = {0.35f, 0.55f, 0.90f};
    sc.horizon = {0.80f, 0.80f, 0.75f};
    fa::render::RtHitParams hit{};
    hit.sunDir[0] = sc.sunDir.x;
    hit.sunDir[1] = sc.sunDir.y;
    hit.sunDir[2] = sc.sunDir.z;
    for (int c = 0; c < 3; ++c) {
        hit.sunColor[c] = comp(sc.sunColor, c);
        hit.ambient[c] = comp(sc.ambient, c);
        hit.sky[c] = comp(sc.sky, c);
        hit.horizon[c] = comp(sc.horizon, c);
    }
    hit.limits[0] = sc.shadowOffset;
    hit.limits[1] = sc.shadowOffsetPerMetre;
    hit.limits[2] = 10000.0f;
    hit.limits[3] = 0.002f;

    // Two probes of a 2 x 1 x 1 grid, 3 m apart: the first in the open above the floor, the second inside the box.
    const Vec3 origin{0.0f, 1.0f, 0.0f};
    const float spacing = 3.0f;
    auto make_params = [&](std::uint32_t seed, float bounce) {
        fa::render::RtGiParams p{};
        p.grid0[0] = origin.x;
        p.grid0[1] = origin.y;
        p.grid0[2] = origin.z;
        p.grid0[3] = spacing;
        p.grid1[0] = 2.0f;
        p.grid1[1] = 1.0f;
        p.grid1[2] = 1.0f;
        p.grid1[3] = 2.0f;
        p.grid2[0] = 0.0f;
        p.grid2[1] = float(fa::render::kGiBlocksPerRow);
        p.grid2[2] = kMaxDistance;
        p.grid2[3] = 1.0f;
        p.grid3[0] = 1.0f;
        p.grid3[1] = 0.5f;
        p.grid3[2] = bounce;
        p.grid3[3] = 0.02f;
        p.frame[0] = 7;
        p.frame[1] = seed;
        p.frame[2] = kRays;
        p.frame[3] = kProbes;
        p.flags[0] = fa::render::rt_gi_front_sense(Backend::Metal);
        for (int j = 0; j < kProbes; ++j) {
            p.probe[j][0] = float(j);
            p.probe[j][1] = j == 0 ? 1.0f : 0.25f;
            p.probe[j][2] = float(j * 10);
            p.probe[j][3] = 0.0f;
        }
        return p;
    };

    // `builds`: the command list that already holds the builds of the structures; the pass is appended to it (else a list of its own).
    auto trace = [&](const fa::render::RtGiParams& params, CommandList* builds) {
        CommandList& cl = builds ? *builds : dev.begin_commands("rt gi frame");
        rig.record_trace(cl, params, hit, rig.recordsView, kProbes);
        const std::vector<std::uint16_t> halves = rig.submit_and_read(cl);
        Band band;
        band.px.resize(halves.size());
        for (std::size_t i = 0; i < halves.size(); ++i) band.px[i] = fa::render::half_to_float(halves[i]);
        return band;
    };

    CommandList& cl = dev.begin_commands("rt gi frame");
    rig.record_builds(cl);
    const fa::render::RtGiParams params = make_params(0x1234u, 0.0f);
    const Band first = trace(params, &cl);

    // The CPU reference: the same rays (the kernel's rotation and Fibonacci set), the closest triangle, the same shading.
    for (int j = 0; j < kProbes; ++j) {
        CAPTURE(j);
        const Vec3 pos = origin + Vec3{spacing * float(j), 0, 0};
        float q[4];
        fa::render::rt_gi_rotation(params.frame[1], std::uint32_t(j), q);
        std::vector<Vec3> dirs(kRays), radiance(kRays);
        std::vector<float> dist(kRays), back(kRays);
        for (int r = 0; r < kRays; ++r) {
            const Vec3 d = fa::render::rt_gi_direction(q, std::uint32_t(r), kRays);
            dirs[std::size_t(r)] = d;
            const Nearest n = nearest(tris, pos, d, -1e-3f, params.grid3[3], kMaxDistance, 0x07);
            if (n.tri < 0) {
                radiance[std::size_t(r)] = environment(sc, d, 0.0f);
                dist[std::size_t(r)] = 1.0f;
                back[std::size_t(r)] = 0.0f;
                continue;
            }
            const Tri& t = tris[std::size_t(n.tri)];
            Vec3 nn = normalize(cross(t.b - t.a, t.c - t.a));
            const bool facesRay = dot(nn, d) < 0.0f;  // the mesh's front face (counter-clockwise) turned to the ray
            if (!facesRay) nn = nn * -1.0f;
            const Vec3 p = pos + d * n.t;
            radiance[std::size_t(r)] = shade_hit(sc, tris, materials[std::size_t(t.instance)], p, nn, d * -1.0f, n.t);
            dist[std::size_t(r)] = std::min(n.t / kMaxDistance, 1.0f);
            back[std::size_t(r)] = facesRay ? 0.0f : 1.0f;
        }
        const int bx = j * 10;
        // The SH row.
        for (int k = 0; k < 9; ++k) {
            Vec3 sum{0, 0, 0};
            for (int r = 0; r < kRays; ++r) sum += radiance[std::size_t(r)] * sh_basis(k, dirs[std::size_t(r)]);
            sum = sum * (4.0f * 3.14159265358979f / float(kRays));
            const float* g = first.at(bx + k, 10);
            CAPTURE(k);
            for (int c = 0; c < 3; ++c) {
                CAPTURE(c);
                CHECK(std::fabs(g[c] - comp(sum, c)) <=
                      0.06f + 0.05f * std::fabs(comp(sum, c)));  // an edge ray may differ
            }
            CHECK(g[3] == doctest::Approx(params.probe[j][1]).epsilon(0.002));
        }
        // The meta texel: the back-face fraction, captured = 1.
        float backSum = 0.0f;
        for (float b : back) backSum += b;
        const float* meta = first.at(bx + 9, 10);
        CHECK(meta[0] == doctest::Approx(backSum / float(kRays)).epsilon(0.03).scale(0.05));
        CHECK(meta[1] == doctest::Approx(1.0f));
        CHECK(meta[3] == doctest::Approx(params.probe[j][1]).epsilon(0.002));
        MESSAGE("probe " << j << ": back-face fraction " << meta[0] << " (CPU " << backSum / float(kRays) << ")");
        if (j == 1)
            CHECK(meta[0] >
                  0.9f);  // inside the box every ray sees the back of a wall: rt_gi_front_sense(Metal) is right
        if (j == 0) CHECK(meta[0] < 0.1f);
        // The depth map: the Chebyshev moments of the hit distances, weighted by a lobe around each texel's direction.
        const float lobe = 4.0f + float(kRays) / 16.0f;
        int compared = 0;
        float worst = 0.0f;
        for (int ty = 0; ty < 10; ++ty) {
            for (int tx = 0; tx < 10; ++tx) {
                const Vec2 e{(float(tx) - 0.5f) / 8.0f * 2.0f - 1.0f, (float(ty) - 0.5f) / 8.0f * 2.0f - 1.0f};
                const Vec3 td = oct_decode(e);
                float ws = 0.0f, m1 = 0.0f, m2 = 0.0f;
                for (int r = 0; r < kRays; ++r) {
                    const float c = dot(td, dirs[std::size_t(r)]);
                    if (c <= 0.0f) continue;
                    const float w = std::pow(c, lobe);
                    ws += w;
                    m1 += w * dist[std::size_t(r)];
                    m2 += w * dist[std::size_t(r)] * dist[std::size_t(r)];
                }
                Vec2 mom{1.0f, 1.0f};
                if (ws > 1.0e-6f) mom = {m1 / ws, m2 / ws};
                const float* g = first.at(bx + tx, ty);
                worst = std::max(worst, std::max(std::fabs(g[0] - mom.x), std::fabs(g[1] - mom.y)));
                CHECK(g[3] == doctest::Approx(params.probe[j][1]).epsilon(0.002));
                ++compared;
            }
        }
        CHECK(compared == 100);
        CHECK(worst < 0.08f);
        MESSAGE("probe " << j << ": the worst depth moment differs by " << worst);
    }

    // Determinism: the same constants write the same bytes; another seed another ray set; the bounce with an empty atlas changes nothing.
    const Band again = trace(params, nullptr);
    CHECK(again.px == first.px);
    const Band other = trace(make_params(0x9999u, 0.0f), nullptr);
    CHECK(other.px != first.px);
    const Band bounced = trace(make_params(0x1234u, 1.0f), nullptr);
    CHECK(bounced.px == first.px);
    rig.release();
}

#else

TEST_CASE("rt gi on Metal: skipped off Apple platforms") {
    MESSAGE("this test runs on a Mac with a GPU that traces rays");
}

#endif
