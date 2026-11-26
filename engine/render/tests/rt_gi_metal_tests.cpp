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
#include "test_util.h"

#if defined(__APPLE__)

using namespace fa;
using namespace fa::gpu;

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

Mesh make_box() {  // [-1, 1] x [0, 2] x [-1, 1]
    Mesh m;
    m.vertices = {{-1, 0, -1}, {1, 0, -1}, {1, 2, -1}, {-1, 2, -1}, {-1, 0, 1}, {1, 0, 1}, {1, 2, 1}, {-1, 2, 1}};
    m.indices = {0, 2, 1, 0, 3, 2, 4, 5, 6, 4, 6, 7, 0, 4, 7, 0, 7, 3,
                 1, 2, 6, 1, 6, 5, 3, 7, 6, 3, 6, 2, 0, 1, 5, 0, 5, 4};
    return m;
}

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
        vb.label = "rt gi mesh vertices";
        m.vb = dev->make_buffer(vb);
        BufferDesc ib;
        ib.size = m.indices.size() * sizeof(std::uint16_t);
        ib.usage.accelBuildInput = true;
        ib.data = Range{m.indices.data(), ib.size};
        ib.label = "rt gi mesh indices";
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

    void make_pipeline() {
        const fa::rt_kernels::RtKernel* k = fa::rt_kernels::find_rt_kernel("rt_gi");
        REQUIRE(k != nullptr);
        const fa::render::RtEffectKernelSpec* spec = fa::render::find_rt_effect_spec("rt_gi");
        REQUIRE(spec != nullptr);
        SamplerDesc sd;
        sd.label = "rt gi nearest";
        nearestSampler = dev->make_sampler(sd);
        PipelineDesc pd;
        pd.compute = true;
        pd.shader = dev->make_shader(fa::render::rt_effect_shader_desc(*k, *spec, Backend::Metal));
        pd.label = "rt_gi";
        pipeline = dev->make_pipeline(pd);
        REQUIRE(dev->state(pd.shader) == ResourceState::Valid);
        REQUIRE(dev->state(pipeline) == ResourceState::Valid);
    }
};


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
    const float* at(int x, int y) const { return &px[(std::size_t(y) * fa::render::kProbeAtlasSize + std::size_t(x)) * 4]; }
};

}  // namespace

TEST_CASE("rt gi on Metal: the probes' SH, depth and back-face texels are what a CPU ray caster computes over the same rays") {
    Rig rig;
    std::string skip;
    if (!rig.open(skip)) {
        MESSAGE("skipped: " << skip);
        return;
    }
    Device& dev = *rig.dev;
    MESSAGE("Metal ray tracing: vendor " << std::string(gpu_vendor_name(dev.info().gpu.vendor)));

    Mesh ground = make_quad(), box = make_box();
    rig.upload(ground);
    rig.upload(box);
    struct Place {
        Mesh* mesh;
        Vec3 at;
        Material material;
    };
    const std::array<Place, 2> places = {
        Place{&ground, {0, 0, 0}, Material{{0.5f, 0.5f, 0.5f}, 0.0f, 0.5f, {0, 0, 0}}},
        Place{&box, {3.0f, 0.5f, 0}, Material{{0.2f, 0.2f, 0.2f}, 0.0f, 0.8f, {0.6f, 0.15f, 0.05f}}}};
    constexpr std::uint8_t kMask = fa::render::kRtMaskOpaque | fa::render::kRtMaskCastsShadow;
    std::vector<Tri> tris;
    for (std::size_t pi = 0; pi < places.size(); ++pi) {
        const Place& p = places[pi];
        for (std::size_t i = 0; i + 2 < p.mesh->indices.size(); i += 3)
            tris.push_back({p.mesh->vertices[p.mesh->indices[i]] + p.at, p.mesh->vertices[p.mesh->indices[i + 1]] + p.at,
                            p.mesh->vertices[p.mesh->indices[i + 2]] + p.at, kMask, int(pi)});
    }

    AccelBuildFlags flags;
    for (Mesh* m : {&ground, &box}) {
        const AccelTriangles g = rig.geometry_of(*m);
        auto bs = dev.blas_sizes(std::span<const AccelTriangles>(&g, 1), flags);
        REQUIRE_MESSAGE(bs.ok(), bs.error().message);
        m->blas = rig.make_as(AccelKind::Blas, bs->structure, "rt gi blas");
        m->scratch = rig.make_scratch(std::max(bs->buildScratch, bs->updateScratch), "rt gi blas scratch");
    }
    std::vector<AccelInstance> instances(places.size());
    std::vector<fa::render::RtInstanceRecord> records(places.size());
    for (std::size_t i = 0; i < places.size(); ++i) {
        AccelInstance& in = instances[i];
        in.transform[3] = places[i].at.x;
        in.transform[7] = places[i].at.y;
        in.transform[11] = places[i].at.z;
        in.blas = places[i].mesh->blas;
        in.mask = kMask;
        in.customIndex = std::uint32_t(i);
        fa::render::RtInstanceRecord& r = records[i];
        std::memset(&r, 0, sizeof r);
        r.objectToWorld[0] = r.objectToWorld[5] = r.objectToWorld[10] = 1.0f;
        r.objectToWorld[3] = places[i].at.x;
        r.objectToWorld[7] = places[i].at.y;
        r.objectToWorld[11] = places[i].at.z;
        for (int c = 0; c < 3; ++c) {
            r.albedo[c] = comp(places[i].material.albedo, c);
            r.emissive[c] = comp(places[i].material.emissive, c);
        }
        r.albedo[3] = 1.0f;
        r.roughness = places[i].material.roughness;
        r.metalness = places[i].material.metalness;
        r.flags = fa::render::kRtFlagOpaque | fa::render::kRtFlagCastsShadow;
    }
    auto ts = dev.tlas_sizes(std::uint32_t(instances.size()), flags);
    REQUIRE_MESSAGE(ts.ok(), ts.error().message);
    const AccelStructure tlas = rig.make_as(AccelKind::Tlas, ts->structure, "rt gi tlas");
    const Buffer tlasScratch = rig.make_scratch(std::max(ts->buildScratch, ts->updateScratch), "rt gi tlas scratch");
    BufferDesc rbd;
    rbd.size = records.size() * sizeof(fa::render::RtInstanceRecord);
    rbd.usage.storageBuffer = true;
    rbd.data = Range{records.data(), rbd.size};
    rbd.label = "rt gi records";
    const Buffer recordBuffer = dev.make_buffer(rbd);
    ViewDesc rvd;
    rvd.storageBuffer.buffer = recordBuffer;
    rvd.label = "rt gi records view";
    const View recordsView = dev.make_view(rvd);

    // The atlas the kernel reads at a hit (the multi-bounce): nothing captured in it (meta.g = 0), so no probe lends light.
    const int atlasW = fa::render::kProbeAtlasSize, atlasH = fa::render::kProbeAtlasSize + 11 * 2;
    std::vector<std::uint16_t> atlasData(std::size_t(atlasW) * atlasH * 4, 0);
    ImageDesc ad;
    ad.width = atlasW;
    ad.height = atlasH;
    ad.pixelFormat = PixelFormat::Rgba16F;
    ad.data.mipLevels[0] = Range{atlasData.data(), atlasData.size() * sizeof(std::uint16_t)};
    ad.label = "rt gi atlas";
    const gpu::Image atlasImg = dev.make_image(ad);
    ViewDesc atv;
    atv.texture.image = atlasImg;
    atv.label = "rt gi atlas view";
    const View atlasView = dev.make_view(atv);
    REQUIRE(dev.state(atlasView) == ResourceState::Valid);

    ImageDesc od;
    od.width = fa::render::kProbeAtlasSize;
    od.height = fa::render::kGiBandHeight;
    od.pixelFormat = PixelFormat::Rgba16F;
    od.usage.storageImage = true;
    od.label = "rt gi band";
    const gpu::Image outImg = dev.make_image(od);
    ViewDesc ov;
    ov.storageImage.image = outImg;
    ov.label = "rt gi band view";
    const View outView = dev.make_view(ov);
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

    auto trace = [&](const fa::render::RtGiParams& params, CommandList* builds) {
        CommandList& cl = builds ? *builds : dev.begin_commands("rt gi frame");
        cl.begin_compute_pass("rt gi");
        cl.set_pipeline(rig.pipeline);
        Bindings b;
        b.views[fa::render::RtEffectBindings::kViewOut] = outView;
        b.views[fa::render::RtEffectBindings::kViewPrepass] = atlasView;
        b.views[fa::render::RtEffectBindings::kViewRecords] = recordsView;
        b.samplers[fa::render::RtEffectBindings::kSampler] = rig.nearestSampler;
        b.accelStructures[0] = tlas;
        cl.set_bindings(b);
        cl.set_uniforms(fa::render::RtEffectBindings::kUniformParams, Range{&params, sizeof params});
        cl.set_uniforms(fa::render::RtEffectBindings::kUniformHit, Range{&hit, sizeof hit});
        cl.dispatch(kProbes, 1, 1);
        cl.end_pass();
        dev.submit(cl);
        dev.commit();
        std::vector<std::uint8_t> bytes;
        auto r = dev.read_storage_image(outImg, PixelFormat::Rgba16F, 0, 0, fa::render::kProbeAtlasSize,
                                        fa::render::kGiBandHeight, bytes);
        REQUIRE_MESSAGE(r.ok(), r.error().message);
        const std::size_t count = std::size_t(fa::render::kProbeAtlasSize) * fa::render::kGiBandHeight * 4;
        REQUIRE(bytes.size() == count * sizeof(std::uint16_t));
        std::vector<std::uint16_t> halves(count);
        std::memcpy(halves.data(), bytes.data(), bytes.size());
        Band band;
        band.px.resize(count);
        for (std::size_t i = 0; i < count; ++i) band.px[i] = fa::render::half_to_float(halves[i]);
        return band;
    };

    CommandList& cl = dev.begin_commands("rt gi frame");
    for (Mesh* m : {&ground, &box}) {
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
            radiance[std::size_t(r)] = shade_hit(sc, tris, places[std::size_t(t.instance)].material, p, nn, d * -1.0f, n.t);
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
                CHECK(std::fabs(g[c] - comp(sum, c)) <= 0.06f + 0.05f * std::fabs(comp(sum, c)));  // an edge ray may differ
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
        if (j == 1) CHECK(meta[0] > 0.9f);  // inside the box every ray sees the back of a wall: rt_gi_front_sense(Metal) is right
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
}

#else

TEST_CASE("rt gi on Metal: skipped off Apple platforms") { MESSAGE("this test runs on a Mac with a GPU that traces rays"); }

#endif
