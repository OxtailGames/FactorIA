// M79-P3b: the translucency kernel (shaders/rt/rt_refract.metal, with the hit shading of rt_hit.msli) run for real on a Mac whose GPU traces
// rays, through the SokolDevice. A glass slab (ior 1.5, 2 m thick, tinted, a closed volume) in front of a red box, a green box and a floor
// under a sun; the prepass of the opaque scene made on the CPU from the camera's own rays, the records of the instances in the buffer the
// renderer's scene would hold, the constants by the engine's fill_rt_effect_camera. What the kernel writes is compared with a CPU port of
// the same loop (Snell's law at the entry and the exit, Beer-Lambert inside, the cone of a rough surface from the same PCG sequence, the
// shading of rt_hit, the projection of the ray's end onto the opaque picture). The same frame twice is bit-identical, a new frame seed
// changes only a rough glass, and a pixel whose primary ray meets no refractive surface is written as zero (nothing traced). A machine without ray tracing says so and
// skips. The D3D12 and Vulkan kernels are the same HLSL compiled by DXC; no test in this suite runs them.
#include <doctest.h>

#include <algorithm>
#include <array>
#include <cmath>
#include <cstdint>
#include <cstring>
#include <memory>
#include <string>
#include <vector>

#include "fa/core/math.h"
#include "fa/scene/camera_geometry.h"
#include "fa/scene/components.h"
#include "gpu/accel.h"
#include "gpu/device.h"
#include "gpu/sokol_device.h"
#include "rt_effect.h"
#include "rt_kernels.h"
#include "rt_records.h"
#include "test_util.h"

#if defined(__APPLE__)

using namespace fa;
using namespace fa::gpu;

namespace {

constexpr int kW = 64, kH = 48;
constexpr float kNoMesh = 1.0e30f;

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

struct Mesh {
    std::vector<Vec3> vertices;
    std::vector<std::uint16_t> indices;
    Buffer vb{}, ib{};
    AccelStructure blas{};
    Buffer scratch{};
};

Mesh make_quad() {
    Mesh m;
    m.vertices = {{-20, 0, -20}, {20, 0, -20}, {20, 0, 20}, {-20, 0, 20}};
    m.indices = {0, 2, 1, 0, 3, 2};
    return m;
}

Mesh make_box(Vec3 lo, Vec3 hi) {
    Mesh m;
    m.vertices = {{lo.x, lo.y, lo.z}, {hi.x, lo.y, lo.z}, {hi.x, hi.y, lo.z}, {lo.x, hi.y, lo.z},
                  {lo.x, lo.y, hi.z}, {hi.x, lo.y, hi.z}, {hi.x, hi.y, hi.z}, {lo.x, hi.y, hi.z}};
    m.indices = {0, 2, 1, 0, 3, 2, 4, 5, 6, 4, 6, 7, 0, 4, 7, 0, 7, 3,
                 1, 2, 6, 1, 6, 5, 3, 7, 6, 3, 6, 2, 0, 1, 5, 0, 5, 4};
    return m;
}

// ---- the CPU port of rt_hit.hlsli (the same as the reflection test's) -------------------------------------------------------------------

struct Scene {
    Vec3 sunDir, sunColor, ambient, sky, horizon;
    float shadowOffset = 0.02f, shadowOffsetPerMetre = 0.002f;
};

struct Material {
    Vec3 albedo;
    float roughness = 0.5f, metalness = 0.0f;
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
    return color;
}

// ---- the CPU port of rt_refract.metal ---------------------------------------------------------------------------------------------------

std::uint32_t pcg(std::uint32_t v) {
    const std::uint32_t s = v * 747796405u + 2891336453u;
    const std::uint32_t w = ((s >> ((s >> 28u) + 4u)) ^ s) * 277803737u;
    return (w >> 22u) ^ w;
}

float unit(std::uint32_t h) { return float(h >> 8u) * (1.0f / 16777216.0f); }

// MSL's refract(I, N, eta): zero when the ray cannot pass.
Vec3 refract_dir(Vec3 i, Vec3 n, float eta) {
    const float ni = dot(n, i);
    const float k = 1.0f - eta * eta * (1.0f - ni * ni);
    if (k < 0.0f) return {0, 0, 0};
    return i * eta - n * (eta * ni + std::sqrt(k));
}

struct GlassVolume {
    float ior = 1.5f, thickness = 2.0f, attenuationDistance = 1.0f, roughness = 0.0f;
    Vec3 attenuation{0.5f, 0.9f, 0.6f};
};

struct Expect {
    int kind = 0;  // 0 nothing traced, 1 a radiance, 2 the texel of the opaque picture and the light that survived
    Vec3 rgb{0, 0, 0};
    int u = 0, v = 0;  // kind 2: the texel's position in 4096ths of the image
    bool ended = false;
};

struct CpuInputs {
    const std::vector<Tri>* tris = nullptr;
    const std::vector<Material>* materials = nullptr;  // by instance
    int glassInstance = 3;
    GlassVolume glass;
    Scene sc;
    const fa::render::RtEffectParams* params = nullptr;
    const std::vector<float>* prepass = nullptr;
    Vec3 camPos, camBack;
};

Expect cpu_refract(const CpuInputs& in, int px, int py, Vec3 o0, Vec3 dir0, float tmax, float grow,
                   std::uint32_t seed) {
    const std::vector<Tri>& tris = *in.tris;
    const fa::render::RtEffectParams& P = *in.params;
    Expect e;
    Nearest cur = nearest(tris, o0, dir0, grow, 0.0f, tmax, 0x40);
    if (cur.tri < 0) return e;
    Vec3 dir = dir0, origin = o0;
    std::uint32_t state = pcg(std::uint32_t(px) + pcg(std::uint32_t(py) + pcg(seed)));
    Vec3 throughput{1, 1, 1}, coef{0, 0, 0}, endPos{0, 0, 0}, radiance{0, 0, 0};
    bool inside = false, spread = false, onSurface = false;
    e.ended = false;
    for (int seg = 0; seg < 6 && !e.ended; ++seg) {
        const bool first = seg == 0;
        const Tri& t = tris[std::size_t(cur.tri)];
        const Vec3 hitPos = origin + dir * cur.t;
        if (inside)
            throughput = {throughput.x * std::exp(-coef.x * cur.t), throughput.y * std::exp(-coef.y * cur.t),
                          throughput.z * std::exp(-coef.z * cur.t)};
        // rt_hit's normal: from the hit and two neighbours of the ray (a step of `eps` along two axes across it); where they do not hit the same
        // triangle (an edge, a silhouette) the surface is taken as facing the ray, which lets the ray through unbent.
        Vec3 n = dir * -1.0f;
        {
            const Vec3 up = std::fabs(dir.y) < 0.9f ? Vec3{0, 1, 0} : Vec3{1, 0, 0};
            const Vec3 u = normalize(cross(up, dir));
            const Vec3 vv = cross(dir, u);
            const float eps = std::max(0.002f * cur.t, 0.001f);
            const float reach = first ? tmax : P.user0[3];
            const int mask = first ? 0x40 : 0x07;
            const Nearest h1 = nearest(tris, origin + u * eps, dir, grow, 0.0f, reach, mask);
            const Nearest h2 = nearest(tris, origin + vv * eps, dir, grow, 0.0f, reach, mask);
            if (h1.tri == cur.tri && h2.tri == cur.tri) {
                Vec3 f = normalize(cross(t.b - t.a, t.c - t.a));
                n = dot(f, dir) > 0.0f ? f * -1.0f : f;
            }
        }
        if (t.instance != in.glassInstance) {
            radiance = shade_hit(in.sc, tris, (*in.materials)[std::size_t(t.instance)], hitPos, n, dir * -1.0f, cur.t);
            endPos = hitPos;
            onSurface = true;
            e.ended = true;
            break;
        }
        const GlassVolume& g = in.glass;
        const float ior = clamp(g.ior, 1.0f, 3.0f);
        Vec3 next = dir;
        if (g.thickness > 0.0f) {
            if (!inside) {
                const Vec3 rd = refract_dir(dir, n, 1.0f / ior);
                if (dot(rd, rd) > 0.5f) next = normalize(rd);
                inside = true;
                const Vec3 att{clamp(g.attenuation.x, 0.0001f, 1.0f), clamp(g.attenuation.y, 0.0001f, 1.0f),
                               clamp(g.attenuation.z, 0.0001f, 1.0f)};
                if (g.attenuationDistance > 0.0f)
                    coef = {-std::log(att.x) / g.attenuationDistance, -std::log(att.y) / g.attenuationDistance,
                            -std::log(att.z) / g.attenuationDistance};
            } else {
                const Vec3 rd = refract_dir(dir, n, ior);
                if (dot(rd, rd) > 0.5f) {
                    next = normalize(rd);
                    inside = false;
                } else {
                    next = reflect_dir(dir, n);
                }
            }
        }
        if (!spread) {
            spread = true;
            const float rough = saturate(g.roughness);
            if (rough > 0.0f) {
                const Vec3 up = std::fabs(next.y) < 0.9f ? Vec3{0, 1, 0} : Vec3{1, 0, 0};
                const Vec3 t1 = normalize(cross(up, next));
                const Vec3 t2 = cross(next, t1);
                state = pcg(state);
                const float u1 = unit(state);
                state = pcg(state);
                const float u2 = unit(state);
                const float tanSpread = rough * P.user0[2] * saturate(2.0f * ior - 2.0f);
                const float rr = std::sqrt(u1) * tanSpread;
                const float phi = 6.28318530717958647692f * u2;
                next = normalize(next + (t1 * std::cos(phi) + t2 * std::sin(phi)) * rr);
            }
        }
        origin = hitPos + next * (P.user0[0] + P.user0[1] * cur.t);
        dir = next;
        cur = nearest(tris, origin, dir, grow, 0.0f, P.user0[3], 0x07);
        if (cur.tri < 0) {
            radiance = environment(in.sc, dir, 0.0f);
            e.ended = true;
        }
    }
    if (!e.ended) radiance = environment(in.sc, dir, 0.0f);
    e.kind = 1;
    e.rgb = {radiance.x * throughput.x, radiance.y * throughput.y, radiance.z * throughput.z};
    if (onSurface) {
        const float row[4][4] = {{P.viewProj0[0], P.viewProj0[1], P.viewProj0[2], P.viewProj0[3]},
                                 {P.viewProj1[0], P.viewProj1[1], P.viewProj1[2], P.viewProj1[3]},
                                 {P.viewProj2[0], P.viewProj2[1], P.viewProj2[2], P.viewProj2[3]},
                                 {P.viewProj3[0], P.viewProj3[1], P.viewProj3[2], P.viewProj3[3]}};
        auto d4 = [&](int r) { return row[r][0] * endPos.x + row[r][1] * endPos.y + row[r][2] * endPos.z + row[r][3]; };
        const float w = d4(3);
        if (w > 1.0e-4f) {
            const float qx = d4(0) / w, qy = d4(1) / w;
            const float uvx = qx * 0.5f + 0.5f, uvy = 0.5f - qy * 0.5f;
            if (uvx >= 0.0f && uvx < 1.0f && uvy >= 0.0f && uvy < 1.0f) {
                const int tx = int(uvx * float(kW)), ty = int(uvy * float(kH));
                const float* there = &(*in.prepass)[(std::size_t(ty) * kW + std::size_t(tx)) * 4];
                const float depth = dot(endPos - in.camPos, in.camBack * -1.0f);
                if (there[3] > 0.5f && std::fabs(there[0] - depth) <= 0.02f * depth + 0.05f) {
                    e.kind = 2;
                    e.u = int(std::min(std::floor(uvx * 4096.0f), 4095.0f));
                    e.v = int(std::min(std::floor(uvy * 4096.0f), 4095.0f));
                    e.rgb = throughput;
                }
            }
        }
    }
    return e;
}

struct Rig {
    std::unique_ptr<Device> owner;
    Device* dev = nullptr;
    Pipeline pipeline{};
    Sampler nearestSampler{};

    bool open(std::string& skip) {
        auto& g = fa::test::gfx();
        if (!g.ok) {
            skip = "no GPU here (" + g.error + ")";
            return false;
        }
        if (built_sokol_backend() != Backend::Metal) {
            skip = std::string("the sokol backend of this build is ") + backend_name(built_sokol_backend());
            return false;
        }
        auto made = make_device(built_sokol_backend());
        REQUIRE_MESSAGE(made, (made ? "" : made.error().message));
        owner = std::move(made.value());
        dev = owner.get();
        std::string why;
        if (!dev->ray_tracing_status(&why)) {
            skip = "this GPU or OS cannot trace rays: " + why;
            return false;
        }
        return true;
    }

    void upload(Mesh& m) {
        BufferDesc vb;
        vb.size = m.vertices.size() * sizeof(Vec3);
        vb.usage.accelBuildInput = true;
        vb.data = Range{m.vertices.data(), vb.size};
        vb.label = "rt refract mesh vertices";
        m.vb = dev->make_buffer(vb);
        BufferDesc ib;
        ib.size = m.indices.size() * sizeof(std::uint16_t);
        ib.usage.accelBuildInput = true;
        ib.data = Range{m.indices.data(), ib.size};
        ib.label = "rt refract mesh indices";
        m.ib = dev->make_buffer(ib);
    }

    AccelStructure make_as(AccelKind kind, std::uint64_t size, const char* label) {
        AccelStructureDesc d;
        d.kind = kind;
        d.size = size;
        d.label = label;
        auto r = dev->make_accel_structure(d);
        REQUIRE_MESSAGE(r.ok(), r.error().message);
        return r.value();
    }

    Buffer make_scratch(std::uint64_t size, const char* label) {
        BufferDesc d;
        d.size = std::size_t(std::max<std::uint64_t>(size, 256));
        d.usage.accelScratch = true;
        d.label = label;
        return dev->make_buffer(d);
    }

    AccelTriangles geometry_of(const Mesh& m) {
        AccelTriangles g{};
        g.vertexBuffer = m.vb;
        g.vertexStride = sizeof(Vec3);
        g.vertexCount = std::uint32_t(m.vertices.size());
        g.indexBuffer = m.ib;
        g.indexType = IndexType::Uint16;
        g.indexCount = std::uint32_t(m.indices.size());
        return g;
    }

    gpu::Image make_texture(const std::vector<float>& data, const char* label, View& view) {
        ImageDesc d;
        d.width = kW;
        d.height = kH;
        d.pixelFormat = PixelFormat::Rgba32F;
        d.data.mipLevels[0] = Range{data.data(), data.size() * sizeof(float)};
        d.label = label;
        const gpu::Image img = dev->make_image(d);
        ViewDesc v;
        v.texture.image = img;
        v.label = label;
        view = dev->make_view(v);
        return img;
    }

    void make_pipeline() {
        const fa::rt_kernels::RtKernel* k = fa::rt_kernels::find_rt_kernel("rt_refract");
        REQUIRE(k != nullptr);
        const fa::render::RtEffectKernelSpec* spec = fa::render::find_rt_effect_spec("rt_refract");
        REQUIRE(spec != nullptr);
        SamplerDesc sd;
        sd.label = "rt refract nearest";
        nearestSampler = dev->make_sampler(sd);
        PipelineDesc pd;
        pd.compute = true;
        pd.shader = dev->make_shader(fa::render::rt_effect_shader_desc(*k, *spec, Backend::Metal));
        pd.label = "rt_refract";
        pipeline = dev->make_pipeline(pd);
        REQUIRE(dev->state(pd.shader) == ResourceState::Valid);
        REQUIRE(dev->state(pipeline) == ResourceState::Valid);
    }
};

CameraGeometry make_camera() {
    World w;
    Entity cam = w.create("cam");
    w.get<Transform>(cam)->position = {1.0f, 5.0f, 11.0f};
    w.get<Transform>(cam)->rotation = {-22.0f, 8.0f, 0.0f};
    auto& c = w.add<Camera>(cam);
    c.projection = Projection::Perspective;
    c.fov = 60.0f;
    c.nearPlane = 0.1f;
    c.farPlane = 200.0f;
    CameraTarget target;
    target.width = target.designWidth = kW;
    target.height = target.designHeight = kH;
    target.zeroToOne = true;  // Metal
    std::string warned;
    CameraGeometry g = camera_geometry(w, cam, target, warned);
    REQUIRE(g.entity == cam);
    return g;
}

}  // namespace

TEST_CASE(
    "rt refract on Metal: a glass slab in front of coloured boxes shows what a CPU port of the same loop computes, "
    "deterministically") {
    Rig rig;
    std::string skip;
    if (!rig.open(skip)) {
        MESSAGE("skipped: " << skip);
        return;
    }
    Device& dev = *rig.dev;
    MESSAGE("Metal ray tracing: vendor " << std::string(gpu_vendor_name(dev.info().gpu.vendor)));

    // The scene: a floor (0), a red box (1), a green box (2) behind a glass slab (3): ior 1.5, 2 m thick in z, a green-blue tint.
    Mesh ground = make_quad(), box = make_box({-1, 0, -1}, {1, 2, 1}),
         slab = make_box({-2.5f, 0.1f, -1.0f}, {2.5f, 2.5f, 1.0f});
    rig.upload(ground);
    rig.upload(box);
    rig.upload(slab);
    struct Place {
        Mesh* mesh;
        Vec3 at;
        std::uint8_t mask;
    };
    constexpr std::uint8_t kOpaqueMask = fa::render::kRtMaskOpaque | fa::render::kRtMaskCastsShadow;
    constexpr std::uint8_t kGlassMask =
        fa::render::kRtMaskBlended | fa::render::kRtMaskCastsShadow | fa::render::kRtMaskRefractive;
    const std::array<Place, 4> places = {
        Place{&ground, {0, 0, 0}, kOpaqueMask}, Place{&box, {-1.5f, 0, -3.0f}, kOpaqueMask},
        Place{&box, {3.0f, 0, -4.0f}, kOpaqueMask}, Place{&slab, {0.5f, 0, 4.0f}, kGlassMask}};
    const std::vector<Material> materials = {
        Material{{0.5f, 0.5f, 0.5f}, 0.5f, 0.0f}, Material{{0.8f, 0.05f, 0.05f}, 0.8f, 0.0f},
        Material{{0.1f, 0.7f, 0.1f}, 0.3f, 0.0f}, Material{{1.0f, 1.0f, 1.0f}, 0.1f, 0.0f}};
    GlassVolume glass;
    std::vector<Tri> tris;
    for (std::size_t pi = 0; pi < places.size(); ++pi) {
        const Place& p = places[pi];
        for (std::size_t i = 0; i + 2 < p.mesh->indices.size(); i += 3)
            tris.push_back({p.mesh->vertices[p.mesh->indices[i]] + p.at,
                            p.mesh->vertices[p.mesh->indices[i + 1]] + p.at,
                            p.mesh->vertices[p.mesh->indices[i + 2]] + p.at, p.mask, int(pi)});
    }

    AccelBuildFlags flags;
    for (Mesh* m : {&ground, &box, &slab}) {
        const AccelTriangles g = rig.geometry_of(*m);
        auto bs = dev.blas_sizes(std::span<const AccelTriangles>(&g, 1), flags);
        REQUIRE_MESSAGE(bs.ok(), bs.error().message);
        m->blas = rig.make_as(AccelKind::Blas, bs->structure, "rt refract blas");
        m->scratch = rig.make_scratch(std::max(bs->buildScratch, bs->updateScratch), "rt refract blas scratch");
    }
    auto make_records = [&](bool refractiveFlag, float roughness, std::vector<AccelInstance>& instances) {
        instances.assign(places.size(), AccelInstance{});
        std::vector<fa::render::RtInstanceRecord> records(places.size());
        for (std::size_t i = 0; i < places.size(); ++i) {
            AccelInstance& in = instances[i];
            in.transform[3] = places[i].at.x;
            in.transform[7] = places[i].at.y;
            in.transform[11] = places[i].at.z;
            in.blas = places[i].mesh->blas;
            in.mask = refractiveFlag || i != 3 ? places[i].mask
                                               : std::uint8_t(places[i].mask & ~fa::render::kRtMaskRefractive);
            in.customIndex = std::uint32_t(i);
            in.opaque = true;
            in.cullDisable = i == 3;
            fa::render::RtInstanceRecord& r = records[i];
            std::memset(&r, 0, sizeof r);
            r.objectToWorld[0] = r.objectToWorld[5] = r.objectToWorld[10] = 1.0f;
            r.objectToWorld[3] = places[i].at.x;
            r.objectToWorld[7] = places[i].at.y;
            r.objectToWorld[11] = places[i].at.z;
            r.albedo[0] = materials[i].albedo.x;
            r.albedo[1] = materials[i].albedo.y;
            r.albedo[2] = materials[i].albedo.z;
            r.albedo[3] = 1.0f;
            r.roughness = materials[i].roughness;
            r.metalness = materials[i].metalness;
            r.flags = fa::render::kRtFlagOpaque | fa::render::kRtFlagCastsShadow;
            r.volume[0] = 1.5f;
            r.attenuation[0] = r.attenuation[1] = r.attenuation[2] = 1.0f;
            if (i == 3) {
                r.flags = fa::render::kRtFlagBlended | fa::render::kRtFlagCastsShadow | fa::render::kRtFlagTwoSided |
                          fa::render::kRtFlagRefractive;
                r.roughness = roughness;
                r.volume[0] = glass.ior;
                r.volume[1] = glass.thickness;
                r.volume[2] = glass.attenuationDistance;
                r.volume[3] = 1.0f;
                r.attenuation[0] = glass.attenuation.x;
                r.attenuation[1] = glass.attenuation.y;
                r.attenuation[2] = glass.attenuation.z;
            }
        }
        return records;
    };
    std::vector<AccelInstance> instances;
    std::vector<fa::render::RtInstanceRecord> records = make_records(true, 0.0f, instances);
    auto ts = dev.tlas_sizes(std::uint32_t(instances.size()), flags);
    REQUIRE_MESSAGE(ts.ok(), ts.error().message);
    const AccelStructure tlas = rig.make_as(AccelKind::Tlas, ts->structure, "rt refract tlas");
    const Buffer tlasScratch =
        rig.make_scratch(std::max(ts->buildScratch, ts->updateScratch), "rt refract tlas scratch");
    BufferDesc rbd;
    rbd.size = records.size() * sizeof(fa::render::RtInstanceRecord);
    rbd.usage.storageBuffer = true;
    rbd.data = Range{records.data(), rbd.size};
    rbd.label = "rt refract records";
    const Buffer recordBuffer = dev.make_buffer(rbd);
    ViewDesc rvd;
    rvd.storageBuffer.buffer = recordBuffer;
    rvd.label = "rt refract records view";
    const View recordsView = dev.make_view(rvd);

    // The camera, the prepass of the OPAQUE scene (the glass is not in it) and the constants.
    const CameraGeometry cam = make_camera();
    CpuInputs in;
    in.tris = &tris;
    in.materials = &materials;
    in.glass = glass;
    in.sc.sunDir = normalize(Vec3{-0.5f, 0.7f, -0.45f});
    in.sc.sunColor = {3.0f, 2.8f, 2.5f};
    in.sc.ambient = {0.10f, 0.10f, 0.12f};
    in.sc.sky = {0.35f, 0.55f, 0.90f};
    in.sc.horizon = {0.80f, 0.80f, 0.75f};
    in.camPos = cam.position;
    in.camBack = cam.forward * -1.0f;
    const Vec2 targetSize{float(kW), float(kH)};
    const std::size_t pixels = std::size_t(kW) * kH;
    std::vector<float> prepass(pixels * 4, 0.0f);
    std::vector<float> opaqueT(pixels, -1.0f);  // the distance of the opaque hit along the pixel's unit ray, -1 the sky
    std::vector<Vec3> rayO(pixels), rayD(pixels);
    for (int y = 0; y < kH; ++y) {
        for (int x = 0; x < kW; ++x) {
            const std::size_t i = std::size_t(y) * kW + x;
            Vec3 o, d;
            cam.screen_ray({float(x) + 0.5f, float(y) + 0.5f}, targetSize, o, d);
            d = normalize(d);
            rayO[i] = o;
            rayD[i] = d;
            float* px = &prepass[i * 4];
            const Nearest h = nearest(tris, o, d, -1e-3f, 0.001f, 1000.0f, 0x01);
            if (h.tri < 0) {
                px[0] = kNoMesh;
                continue;
            }
            px[0] = dot(cam.forward, o + d * h.t - cam.position);
            px[3] = 1.0f;
            opaqueT[i] = h.t;
        }
    }
    View prepassView;
    const gpu::Image prepassImg = rig.make_texture(prepass, "rt refract prepass", prepassView);
    ImageDesc od;
    od.width = kW;
    od.height = kH;
    od.pixelFormat = PixelFormat::Rgba32F;
    od.usage.storageImage = true;
    od.label = "rt refract out";
    const gpu::Image outImg = dev.make_image(od);
    ViewDesc ov;
    ov.storageImage.image = outImg;
    ov.label = "rt refract out view";
    const View outView = dev.make_view(ov);
    rig.make_pipeline();

    fa::render::RtEffectParams params{};
    fa::render::fill_rt_effect_camera(params, cam, kW, kH, true);
    params.lightDir[0] = in.sc.sunDir.x;
    params.lightDir[1] = in.sc.sunDir.y;
    params.lightDir[2] = in.sc.sunDir.z;
    params.frame[0] = 12;
    params.frame[1] = fa::render::rt_effect_seed(12);
    params.frame[2] = 1;
    params.user0[0] = 0.02f;     // the offset after an interface (metres)
    params.user0[1] = 0.002f;    // more of it per metre of the segment
    params.user0[2] = 0.35f;     // the widest cone
    params.user0[3] = 10000.0f;  // TMax
    in.params = &params;
    in.prepass = &prepass;
    fa::render::RtHitParams hit{};
    hit.sunDir[0] = in.sc.sunDir.x;
    hit.sunDir[1] = in.sc.sunDir.y;
    hit.sunDir[2] = in.sc.sunDir.z;
    for (int c = 0; c < 3; ++c) {
        hit.sunColor[c] = comp(in.sc.sunColor, c);
        hit.ambient[c] = comp(in.sc.ambient, c);
        hit.sky[c] = comp(in.sc.sky, c);
        hit.horizon[c] = comp(in.sc.horizon, c);
    }
    hit.limits[0] = in.sc.shadowOffset;
    hit.limits[1] = in.sc.shadowOffsetPerMetre;
    hit.limits[2] = 10000.0f;
    hit.limits[3] = 0.002f;

    auto trace = [&](CommandList* builds) {
        CommandList& cl = builds ? *builds : dev.begin_commands("rt refract frame");
        cl.begin_compute_pass("rt refract");
        cl.set_pipeline(rig.pipeline);
        Bindings b;
        b.views[fa::render::RtEffectBindings::kViewOut] = outView;
        b.views[fa::render::RtEffectBindings::kViewPrepass] = prepassView;
        b.views[fa::render::RtEffectBindings::kViewRecords] = recordsView;
        b.samplers[fa::render::RtEffectBindings::kSampler] = rig.nearestSampler;
        b.accelStructures[0] = tlas;
        cl.set_bindings(b);
        cl.set_uniforms(fa::render::RtEffectBindings::kUniformParams, Range{&params, sizeof params});
        cl.set_uniforms(fa::render::RtEffectBindings::kUniformHit, Range{&hit, sizeof hit});
        cl.dispatch(kW / 8, kH / 8, 1);
        cl.end_pass();
        dev.submit(cl);
        dev.commit();
        std::vector<std::uint8_t> bytes;
        auto r = dev.read_storage_image(outImg, PixelFormat::Rgba32F, 0, 0, kW, kH, bytes);
        REQUIRE_MESSAGE(r.ok(), r.error().message);
        REQUIRE(bytes.size() == pixels * 4 * sizeof(float));
        std::vector<float> v(pixels * 4);
        std::memcpy(v.data(), bytes.data(), bytes.size());
        return v;
    };

    // One frame builds the BLASes and the TLAS and traces, like the renderer's.
    CommandList& cl = dev.begin_commands("rt refract frame");
    for (Mesh* m : {&ground, &box, &slab}) {
        BlasBuild bb;
        const AccelTriangles g = rig.geometry_of(*m);
        bb.dst = m->blas;
        bb.geometries = std::span<const AccelTriangles>(&g, 1);
        bb.flags = flags;
        bb.scratch = m->scratch;
        auto r = cl.build_blas(bb);
        REQUIRE_MESSAGE(r.ok(), r.error().message);
    }
    TlasBuild tb;
    tb.dst = tlas;
    tb.instances = instances;
    tb.flags = flags;
    tb.scratch = tlasScratch;
    auto built = cl.build_tlas(tb);
    REQUIRE_MESSAGE(built.ok(), built.error().message);
    const std::vector<float> first = trace(&cl);

    // The kernel against the CPU port, pixel by pixel. A pixel whose result changes with the triangles' edge tolerance is on an edge (either is
    // right) and is left out; the ray that ends at an edge of the picture's texel can pick the next texel: a few such pixels are allowed.
    auto compare = [&](const std::vector<float>& got, float roughness, const char* what) {
        in.glass.roughness = roughness;
        // The cone's sin, cos and sqrt differ in the last bits between the GPU and the CPU, and a ray that ends far away moves a texel by them:
        // a texel's position may differ by a few thousandths of the image in a rough glass (a smooth glass has none of it).
        const int slack = roughness > 0.0f ? 24 : 1;
        int compared = 0, radiance = 0, encoded = 0, zero = 0, kindMismatch = 0, bent = 0, edge = 0;
        float worst = 0.0f;
        for (int y = 0; y < kH; ++y) {
            for (int x = 0; x < kW; ++x) {
                const std::size_t i = std::size_t(y) * kW + x;
                const float* g = &got[i * 4];
                const float tmax = opaqueT[i] >= 0.0f ? opaqueT[i] : params.user0[3];
                const Expect a = cpu_refract(in, x, y, rayO[i], rayD[i], tmax, 1e-3f, params.frame[1]);
                const Expect b = cpu_refract(in, x, y, rayO[i], rayD[i], tmax, -1e-3f, params.frame[1]);
                if (a.kind != b.kind || a.u != b.u || a.v != b.v ||
                    std::fabs(a.rgb.x - b.rgb.x) + std::fabs(a.rgb.y - b.rgb.y) + std::fabs(a.rgb.z - b.rgb.z) >
                        1e-3f) {
                    ++edge;
                    continue;
                }
                CAPTURE(what);
                CAPTURE(x);
                CAPTURE(y);
                if (b.kind == 0) {
                    ++zero;
                    CHECK(g[0] == 0.0f);
                    CHECK(g[1] == 0.0f);
                    CHECK(g[2] == 0.0f);
                    CHECK(g[3] == 0.0f);
                    continue;
                }
                ++compared;
                const int gotKind = g[3] > 0.5f ? 1 : (g[3] < -0.5f ? 2 : 0);
                if (gotKind != b.kind) {
                    ++kindMismatch;
                    continue;
                }
                float worstHere = 0.0f;
                for (int c = 0; c < 3; ++c) worstHere = std::max(worstHere, std::fabs(g[c] - comp(b.rgb, c)));
                worst = std::max(worst, worstHere);
                if (gotKind == 1) {
                    ++radiance;
                    CHECK(g[3] == 1.0f);
                    for (int c = 0; c < 3; ++c) CHECK(g[c] == doctest::Approx(comp(b.rgb, c)).epsilon(1e-2).scale(1.0));
                } else {
                    ++encoded;
                    const int code = int(-g[3]) - 1;
                    const int gv = code / 4096, gu = code - gv * 4096;
                    CHECK(std::abs(gu - b.u) <= slack);
                    CHECK(std::abs(gv - b.v) <= slack);
                    for (int c = 0; c < 3; ++c) CHECK(g[c] == doctest::Approx(comp(b.rgb, c)).epsilon(1e-2).scale(1.0));
                    // The slab bends the ray: where the picture is read is not where the pixel is.
                    const float dx = float(gu) / 4096.0f * float(kW) - (float(x) + 0.5f);
                    const float dy = float(gv) / 4096.0f * float(kH) - (float(y) + 0.5f);
                    if (std::sqrt(dx * dx + dy * dy) > 1.5f) ++bent;
                }
            }
        }
        MESSAGE(what << ": compared " << compared << ", radiance " << radiance << ", picture texels " << encoded
                     << " (bent more than 1.5 px: " << bent << "), nothing traced " << zero << ", edges left out "
                     << edge << ", kind mismatches " << kindMismatch << ", worst colour error " << worst);
        CHECK(compared > 300);
        CHECK(kindMismatch * 50 <= compared);  // at most 2 %
        return std::array<int, 3>{radiance, encoded, bent};
    };
    const std::array<int, 3> smooth = compare(first, 0.0f, "smooth glass");
    CHECK(smooth[0] > 30);  // rays that end on the sky or off the screen: shaded in the kernel
    CHECK(smooth[1] > 30);  // rays that end on what the picture shows
    CHECK(smooth[2] > 10);  // and the glass moves them

    // The same frame twice gives the same image, bit for bit; a new frame seed does not change a smooth glass.
    CHECK(trace(nullptr) == first);
    const fa::render::RtEffectParams saved = params;
    params.frame[0] = 13;
    params.frame[1] = fa::render::rt_effect_seed(13);
    CHECK(trace(nullptr) == first);
    params = saved;

    // A rough glass: the record's roughness is read from the buffer, the cone's sample comes from the frame's seed. Same seed, same bits; the
    // CPU port draws the same sequence; another seed gives another picture.
    {
        std::vector<AccelInstance> unused;
        records = make_records(true, 0.5f, unused);
        std::vector<std::uint8_t> raw(records.size() * sizeof(fa::render::RtInstanceRecord));
        std::memcpy(raw.data(), records.data(), raw.size());
        BufferDesc nd = rbd;
        nd.data = Range{raw.data(), raw.size()};
        nd.label = "rt refract rough records";
        const Buffer roughBuffer = dev.make_buffer(nd);
        ViewDesc nv;
        nv.storageBuffer.buffer = roughBuffer;
        nv.label = "rt refract rough records view";
        const View roughView = dev.make_view(nv);
        const View smoothView = recordsView;
        auto trace_with = [&](View v) {
            // rebind: the kernel reads the records through the view of the bindings
            CommandList& list = dev.begin_commands("rt refract rough frame");
            list.begin_compute_pass("rt refract rough");
            list.set_pipeline(rig.pipeline);
            Bindings b;
            b.views[fa::render::RtEffectBindings::kViewOut] = outView;
            b.views[fa::render::RtEffectBindings::kViewPrepass] = prepassView;
            b.views[fa::render::RtEffectBindings::kViewRecords] = v;
            b.samplers[fa::render::RtEffectBindings::kSampler] = rig.nearestSampler;
            b.accelStructures[0] = tlas;
            list.set_bindings(b);
            list.set_uniforms(fa::render::RtEffectBindings::kUniformParams, Range{&params, sizeof params});
            list.set_uniforms(fa::render::RtEffectBindings::kUniformHit, Range{&hit, sizeof hit});
            list.dispatch(kW / 8, kH / 8, 1);
            list.end_pass();
            dev.submit(list);
            dev.commit();
            std::vector<std::uint8_t> bytes;
            auto r = dev.read_storage_image(outImg, PixelFormat::Rgba32F, 0, 0, kW, kH, bytes);
            REQUIRE_MESSAGE(r.ok(), r.error().message);
            std::vector<float> out(pixels * 4);
            std::memcpy(out.data(), bytes.data(), bytes.size());
            return out;
        };
        const std::vector<float> rough = trace_with(roughView);
        compare(rough, 0.5f, "rough glass");
        CHECK(trace_with(roughView) == rough);
        CHECK(rough != first);
        params.frame[0] = 13;
        params.frame[1] = fa::render::rt_effect_seed(13);
        CHECK(trace_with(roughView) != rough);
        params = saved;
        CHECK(trace_with(smoothView) == first);
        dev.destroy_view(roughView);
        dev.destroy_buffer(roughBuffer);
    }

    for (const View v : {outView, prepassView, recordsView}) dev.destroy_view(v);
    for (const gpu::Image im : {outImg, prepassImg}) dev.destroy_image(im);
    dev.destroy_buffer(recordBuffer);
    dev.destroy_accel_structure(tlas);
    dev.destroy_accel_structure(ground.blas);
    dev.destroy_accel_structure(box.blas);
    dev.destroy_accel_structure(slab.blas);
}

#else

TEST_CASE("rt refract on Metal: only on a Mac") { MESSAGE("skipped: this host has no Metal"); }

#endif
