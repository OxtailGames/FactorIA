// M79-P5a: the path tracing kernel (shaders/rt/rt_pathtrace.metal, with the hit shading of rt_hit.msli) run for real on a Mac whose GPU traces rays,
// through the SokolDevice. Three scenes against numbers a CPU computes:
//   * a closed room whose walls emit and reflect uniformly: one bounce is exactly the emission, more bounces add the geometric series of the albedo
//     (the mean of the converged picture is inside the bounds of that series), and a firefly clamp caps the luminance;
//   * a lit floor and two boxes at one bounce (the sun, a point light and a spot light, each with a shadow ray): every smooth pixel against a CPU ray
//     caster with the same formulas; a pixel the prepass says the raster hides in front of the traced surface stays empty;
//   * the sequence: the same samples twice are the same bits, the accumulation of two frames equals one frame of the same samples, a seed
//     changes the noise.
// A machine without ray tracing says so and skips. The D3D12 and Vulkan kernels are the same HLSL compiled by DXC; no test in this suite runs them.
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
#include "rt_pathtrace.h"
#include "rt_records.h"
#include "test_util.h"

#if defined(__APPLE__)

using namespace fa;
using namespace fa::gpu;

namespace {

constexpr int kW = 64, kH = 48;

struct Tri {
    Vec3 a, b, c;
    int instance = 0;
};

bool hit_tri(Vec3 o, Vec3 d, const Tri& t, float grow, float& out) {
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
    return out >= 0.0f && out <= 10000.0f;
}

struct Nearest {
    float t = 1.0e30f;
    int tri = -1;
};

Nearest nearest(const std::vector<Tri>& tris, Vec3 o, Vec3 d, float grow) {
    Nearest n;
    for (std::size_t i = 0; i < tris.size(); ++i) {
        float t = 0;
        if (hit_tri(o, d, tris[i], grow, t) && t < n.t) {
            n.t = t;
            n.tri = int(i);
        }
    }
    return n;
}

Vec2 oct_encode(Vec3 n) {
    const float s = std::fabs(n.x) + std::fabs(n.y) + std::fabs(n.z);
    float x = n.x / s, y = n.y / s;
    if (n.z < 0.0f) {
        const float ox = (1.0f - std::fabs(y)) * (x >= 0.0f ? 1.0f : -1.0f);
        const float oy = (1.0f - std::fabs(x)) * (y >= 0.0f ? 1.0f : -1.0f);
        x = ox;
        y = oy;
    }
    return {x, y};
}

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

struct Material {
    Vec3 albedo;
    float roughness = 0.5f, metalness = 0.0f;
    Vec3 emissive{0, 0, 0};
};

float comp(Vec3 v, int c) { return c == 0 ? v.x : (c == 1 ? v.y : v.z); }

// rt_hit's lit terms of one light (the raster's Lambert + GGX, without the 1/pi on the diffuse): the weight of `l` on a surface, no colour.
Vec3 direct_term(Vec3 l, Vec3 n, Vec3 v, const Material& m) {
    const float roughness = clamp(m.roughness, 0.05f, 1.0f);
    const Vec3 diffuse = m.albedo * (1.0f - m.metalness);
    const Vec3 f0 = lerp(Vec3{0.04f, 0.04f, 0.04f}, m.albedo, m.metalness);
    const float ndv = std::max(dot(n, v), 1.0e-4f);
    const float ndl = dot(n, l);
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
    return (diffuse + f * (d * vis)) * ndl;
}

struct Place {
    Mesh* mesh;
    Vec3 at;
    float scale;
    Material material;
};

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
        vb.label = "rt pathtrace mesh vertices";
        m.vb = dev->make_buffer(vb);
        BufferDesc ib;
        ib.size = m.indices.size() * sizeof(std::uint16_t);
        ib.usage.accelBuildInput = true;
        ib.data = Range{m.indices.data(), ib.size};
        ib.label = "rt pathtrace mesh indices";
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
        const fa::rt_kernels::RtKernel* k = fa::rt_kernels::find_rt_kernel("rt_pathtrace");
        REQUIRE(k != nullptr);
        const fa::render::RtEffectKernelSpec* spec = fa::render::find_rt_effect_spec("rt_pathtrace");
        REQUIRE(spec != nullptr);
        SamplerDesc sd;
        sd.label = "rt pathtrace nearest";
        nearestSampler = dev->make_sampler(sd);
        PipelineDesc pd;
        pd.compute = true;
        pd.shader = dev->make_shader(fa::render::rt_effect_shader_desc(*k, *spec, Backend::Metal));
        pd.label = "rt_pathtrace";
        pipeline = dev->make_pipeline(pd);
        REQUIRE(dev->state(pd.shader) == ResourceState::Valid);
        REQUIRE(dev->state(pipeline) == ResourceState::Valid);
    }
};

CameraGeometry make_camera(Vec3 position, Vec3 rotation) {
    World w;
    Entity cam = w.create("cam");
    w.get<Transform>(cam)->position = position;
    w.get<Transform>(cam)->rotation = rotation;
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

// One scene on the device: the BLASes, the TLAS, the records, the pipeline and the images, and `trace` that runs a dispatch and reads the image.
struct Scene {
    Rig& rig;
    std::vector<Place> places;
    std::vector<Tri> tris;
    Mesh* meshes[2] = {nullptr, nullptr};
    AccelStructure tlas{};
    Buffer recordBuffer{};
    View recordsView{}, outView{}, prepassView{};
    gpu::Image outImg{}, prepassImg{};
    std::vector<AccelInstance> instances;
    std::vector<Buffer> owned;
    std::vector<float> prepass;

    explicit Scene(Rig& r) : rig(r) {}

    void build(Mesh* a, Mesh* b, std::vector<Place> p, std::uint8_t mask, std::vector<float> pre) {
        Device& dev = *rig.dev;
        places = std::move(p);
        meshes[0] = a;
        meshes[1] = b;
        prepass = std::move(pre);
        for (std::size_t pi = 0; pi < places.size(); ++pi) {
            const Place& pl = places[pi];
            for (std::size_t i = 0; i + 2 < pl.mesh->indices.size(); i += 3)
                tris.push_back({pl.mesh->vertices[pl.mesh->indices[i]] * pl.scale + pl.at,
                                pl.mesh->vertices[pl.mesh->indices[i + 1]] * pl.scale + pl.at,
                                pl.mesh->vertices[pl.mesh->indices[i + 2]] * pl.scale + pl.at, int(pi)});
        }
        AccelBuildFlags flags;
        for (Mesh* m : {a, b}) {
            if (!m) continue;
            const AccelTriangles g = rig.geometry_of(*m);
            auto bs = dev.blas_sizes(std::span<const AccelTriangles>(&g, 1), flags);
            REQUIRE_MESSAGE(bs.ok(), bs.error().message);
            m->blas = rig.make_as(AccelKind::Blas, bs->structure, "rt pathtrace blas");
            m->scratch = rig.make_scratch(std::max(bs->buildScratch, bs->updateScratch), "rt pathtrace blas scratch");
        }
        instances.assign(places.size(), AccelInstance{});
        std::vector<fa::render::RtInstanceRecord> records(places.size());
        for (std::size_t i = 0; i < places.size(); ++i) {
            const Place& pl = places[i];
            AccelInstance& in = instances[i];
            in.transform[0] = in.transform[5] = in.transform[10] = pl.scale;
            in.transform[3] = pl.at.x;
            in.transform[7] = pl.at.y;
            in.transform[11] = pl.at.z;
            in.blas = pl.mesh->blas;
            in.mask = mask;
            in.customIndex = std::uint32_t(i);
            fa::render::RtInstanceRecord& r = records[i];
            std::memset(&r, 0, sizeof r);
            r.objectToWorld[0] = r.objectToWorld[5] = r.objectToWorld[10] = pl.scale;
            r.objectToWorld[3] = pl.at.x;
            r.objectToWorld[7] = pl.at.y;
            r.objectToWorld[11] = pl.at.z;
            for (int c = 0; c < 3; ++c) {
                r.albedo[c] = comp(pl.material.albedo, c);
                r.emissive[c] = comp(pl.material.emissive, c);
            }
            r.albedo[3] = 1.0f;
            r.roughness = pl.material.roughness;
            r.metalness = pl.material.metalness;
            r.flags = fa::render::kRtFlagOpaque | fa::render::kRtFlagCastsShadow;
            r.volume[0] = 1.5f;
        }
        auto ts = dev.tlas_sizes(std::uint32_t(instances.size()), flags);
        REQUIRE_MESSAGE(ts.ok(), ts.error().message);
        tlas = rig.make_as(AccelKind::Tlas, ts->structure, "rt pathtrace tlas");
        const Buffer tlasScratch =
            rig.make_scratch(std::max(ts->buildScratch, ts->updateScratch), "rt pathtrace tlas scratch");
        BufferDesc rbd;
        rbd.size = records.size() * sizeof(fa::render::RtInstanceRecord);
        rbd.usage.storageBuffer = true;
        rbd.data = Range{records.data(), rbd.size};
        rbd.label = "rt pathtrace records";
        recordBuffer = dev.make_buffer(rbd);
        ViewDesc rvd;
        rvd.storageBuffer.buffer = recordBuffer;
        rvd.label = "rt pathtrace records view";
        recordsView = dev.make_view(rvd);
        prepassImg = rig.make_texture(prepass, "rt pathtrace prepass", prepassView);
        ImageDesc od;
        od.width = kW;
        od.height = kH;
        od.pixelFormat = PixelFormat::Rgba32F;
        od.usage.storageImage = true;
        od.label = "rt pathtrace out";
        outImg = dev.make_image(od);
        ViewDesc ov;
        ov.storageImage.image = outImg;
        ov.label = "rt pathtrace out view";
        outView = dev.make_view(ov);
        rig.make_pipeline();
        // One frame builds the BLASes and the TLAS, like the renderer's.
        CommandList& cl = dev.begin_commands("rt pathtrace build");
        for (Mesh* m : {a, b}) {
            if (!m) continue;
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
        dev.submit(cl);
        dev.commit();
        owned.push_back(tlasScratch);
    }

    std::vector<float> trace(const fa::render::RtEffectParams& params, const fa::render::RtHitParams& hit,
                             const fa::render::RtLightParams& lights) {
        Device& dev = *rig.dev;
        CommandList& cl = dev.begin_commands("rt pathtrace frame");
        cl.begin_compute_pass("rt pathtrace");
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
        cl.set_uniforms(fa::render::RtEffectBindings::kUniformLights, Range{&lights, sizeof lights});
        cl.dispatch(kW / 8, kH / 8, 1);
        cl.end_pass();
        dev.submit(cl);
        dev.commit();
        std::vector<std::uint8_t> bytes;
        auto r = dev.read_storage_image(outImg, PixelFormat::Rgba32F, 0, 0, kW, kH, bytes);
        REQUIRE_MESSAGE(r.ok(), r.error().message);
        REQUIRE(bytes.size() == std::size_t(kW) * kH * 4 * sizeof(float));
        std::vector<float> v(std::size_t(kW) * kH * 4);
        std::memcpy(v.data(), bytes.data(), bytes.size());
        return v;
    }

    ~Scene() {
        Device& dev = *rig.dev;
        for (const View v : {outView, prepassView, recordsView}) dev.destroy_view(v);
        for (const gpu::Image im : {outImg, prepassImg}) dev.destroy_image(im);
        dev.destroy_buffer(recordBuffer);
        for (const Buffer bf : owned) dev.destroy_buffer(bf);
        dev.destroy_accel_structure(tlas);
        for (Mesh* m : meshes)
            if (m) dev.destroy_accel_structure(m->blas);
    }
};

void zero_hit(fa::render::RtHitParams& hit) {
    hit = fa::render::RtHitParams{};
    hit.sunDir[1] = 1.0f;
    hit.limits[0] = 0.02f;
    hit.limits[1] = 0.002f;
    hit.limits[2] = 10000.0f;
    hit.limits[3] = 0.002f;
}

// frame.x = the first sample, frame.y = the seed, frame.z = the samples of the dispatch, frame.w = the indirect bounces | 256 with lights.
void set_frame(fa::render::RtEffectParams& p, std::uint32_t first, std::uint32_t seed, std::uint32_t count,
               int maxBounces, bool lights, float clamp = 0.0f) {
    fa::render::PathTracerSettings s;
    s.maxBounces = maxBounces;
    s.seed = int(seed);
    s.fireflyClamp = clamp;
    s.lights = lights;
    fa::render::PathTraceStep step;
    step.firstSample = first;
    step.count = count;
    fa::render::path_trace_fill_params(p, s, step, lights);
}

}  // namespace

TEST_CASE("rt pathtrace on Metal: a closed room of emitting walls gives the emission at one bounce and the geometric "
          "series of the albedo "
          "at more, the same bits twice, and a firefly clamp caps the luminance") {
    Rig rig;
    std::string skip;
    if (!rig.open(skip)) {
        MESSAGE("skipped: " << skip);
        return;
    }
    Device& dev = *rig.dev;
    MESSAGE("Metal ray tracing: vendor " << std::string(gpu_vendor_name(dev.info().gpu.vendor)));

    // The room: the box [-5, 5] x [0, 10] x [-5, 5] seen from inside. Its walls emit E and reflect 0.5, rough, with no light in it: every ray ends on a wall.
    Mesh box = make_box();
    rig.upload(box);
    const Vec3 emission{1.0f, 0.5f, 0.25f};
    constexpr float kAlbedo = 0.5f;
    constexpr std::uint8_t kMask = fa::render::kRtMaskOpaque | fa::render::kRtMaskCastsShadow;
    Scene scene(rig);
    // No prepass (a = 0): the primary limit is the far plane.
    scene.build(&box, nullptr,
                {Place{&box, {0, 0, 0}, 5.0f, Material{{kAlbedo, kAlbedo, kAlbedo}, 1.0f, 0.0f, emission}}}, kMask,
                std::vector<float>(std::size_t(kW) * kH * 4, 0.0f));
    const CameraGeometry cam = make_camera({0.5f, 5.0f, 0.5f}, {-10.0f, 30.0f, 0.0f});
    fa::render::RtEffectParams params{};
    fa::render::fill_rt_effect_camera(params, cam, kW, kH, true);
    fa::render::RtHitParams hit{};
    zero_hit(hit);
    hit.sunColor[0] = hit.sunColor[1] = hit.sunColor[2] =
        0.0f;  // no sun, no ambient, no sky: the walls are the only light
    const fa::render::RtLightParams noLights{};

    const auto mean_of = [&](const std::vector<float>& img, int c) {
        double s = 0.0;
        for (std::size_t i = 0; i < std::size_t(kW) * kH; ++i) s += img[i * 4 + std::size_t(c)];
        return s / double(kW * kH);
    };

    // One bounce setting: the emission of the first wall, to the last bit, in every pixel, with full coverage.
    set_frame(params, 0, 7, 4, 1, false);
    const std::vector<float> direct = scene.trace(params, hit, noLights);
    int wrong = 0;
    for (std::size_t i = 0; i < std::size_t(kW) * kH; ++i) {
        const bool ok = direct[i * 4 + 0] == doctest::Approx(emission.x).epsilon(1e-5) &&
                        direct[i * 4 + 1] == doctest::Approx(emission.y).epsilon(1e-5) &&
                        direct[i * 4 + 2] == doctest::Approx(emission.z).epsilon(1e-5) &&
                        direct[i * 4 + 3] == doctest::Approx(1.0f);
        wrong += ok ? 0 : 1;
    }
    CHECK(wrong == 0);

    // Two bounces: E (1 + rho'), with rho' the albedo plus what the rough specular lobe (about 0.016 at roughness 1) returns.
    // Eight: the series to the seventh power. The mean of 256 samples over 3072 pixels is inside the bounds (the noise of the mean is ~0.2 percent).
    struct Case {
        int bounces;
        double lo, hi;
    };
    const Case cases[] = {{2, 1.49, 1.53}, {8, 1.97, 2.09}};
    for (const Case& cs : cases) {
        std::vector<float> img;
        for (std::uint32_t first = 0; first < 256; first += 64) {
            set_frame(params, first, 11, 64, cs.bounces, false);
            img = scene.trace(params, hit, noLights);
        }
        for (int c = 0; c < 3; ++c) {
            const double e = comp(emission, c);
            const double mean = mean_of(img, c) / e;
            CAPTURE(cs.bounces);
            CAPTURE(c);
            CHECK(mean >= cs.lo);
            CHECK(mean <= cs.hi);
        }
        // The alpha is the primary coverage, always 1 here.
        CHECK(mean_of(img, 3) == doctest::Approx(1.0).epsilon(1e-6));
    }

    // The same samples twice are the same bits; a different seed is a different picture; the samples of two frames are the mean of one frame
    // that takes them all (the running mean: the floats differ in the last bits only).
    set_frame(params, 0, 5, 16, 6, false);
    const std::vector<float> a = scene.trace(params, hit, noLights);
    const std::vector<float> a2 = scene.trace(params, hit, noLights);
    CHECK(a == a2);
    set_frame(params, 0, 6, 16, 6, false);
    CHECK(scene.trace(params, hit, noLights) != a);
    set_frame(params, 0, 5, 8, 6, false);
    (void)scene.trace(params, hit, noLights);
    set_frame(params, 8, 5, 8, 6, false);
    const std::vector<float> twoFrames = scene.trace(params, hit, noLights);
    double worst = 0.0;
    for (std::size_t i = 0; i < a.size(); ++i) worst = std::max(worst, double(std::fabs(a[i] - twoFrames[i])));
    MESSAGE("two frames of 8 samples against one of 16: the largest difference is " << worst);
    CHECK(worst < 1e-4);

    // A firefly clamp: the luminance of one path never passes it (one bounce: the emission, whose luminance is 0.62).
    set_frame(params, 0, 7, 4, 1, false, 0.31f);
    const std::vector<float> clamped = scene.trace(params, hit, noLights);
    for (std::size_t i = 0; i < std::size_t(kW) * kH; i += 37) {
        const float l = 0.2126f * clamped[i * 4] + 0.7152f * clamped[i * 4 + 1] + 0.0722f * clamped[i * 4 + 2];
        CHECK(l == doctest::Approx(0.31f).epsilon(1e-4));
    }
}

TEST_CASE("rt pathtrace on Metal: the sun, a point light and a spot light on a floor and two boxes match a CPU ray "
          "caster at one bounce, "
          "and a surface the raster draws nearer stays empty") {
    Rig rig;
    std::string skip;
    if (!rig.open(skip)) {
        MESSAGE("skipped: " << skip);
        return;
    }
    Device& dev = *rig.dev;
    (void)dev;
    Mesh ground = make_quad(), box = make_box();
    rig.upload(ground);
    rig.upload(box);
    const std::array<Place, 3> places = {
        Place{&ground, {0, 0, 0}, 1.0f, Material{{0.6f, 0.6f, 0.6f}, 0.7f, 0.0f, {0, 0, 0}}},
        Place{&box, {-1.0f, 0, 0.5f}, 1.0f, Material{{0.8f, 0.2f, 0.1f}, 0.5f, 0.0f, {0.05f, 0, 0}}},
        Place{&box, {4.0f, 0, -1.0f}, 1.0f, Material{{0.1f, 0.7f, 0.2f}, 0.3f, 0.0f, {0, 0, 0}}}};
    constexpr std::uint8_t kMask = fa::render::kRtMaskOpaque | fa::render::kRtMaskCastsShadow;
    const CameraGeometry cam = make_camera({1.0f, 5.0f, 11.0f}, {-22.0f, 8.0f, 0.0f});
    const Vec2 targetSize{float(kW), float(kH)};
    const std::size_t pixels = std::size_t(kW) * kH;

    // The CPU's scene (the same triangles) for the prepass, then the device's.
    std::vector<Tri> cpu;
    for (std::size_t pi = 0; pi < places.size(); ++pi)
        for (std::size_t i = 0; i + 2 < places[pi].mesh->indices.size(); i += 3)
            cpu.push_back({places[pi].mesh->vertices[places[pi].mesh->indices[i]] + places[pi].at,
                           places[pi].mesh->vertices[places[pi].mesh->indices[i + 1]] + places[pi].at,
                           places[pi].mesh->vertices[places[pi].mesh->indices[i + 2]] + places[pi].at, int(pi)});
    std::vector<float> prepass(pixels * 4, 0.0f);
    std::vector<int> primary(pixels, -1);
    for (int y = 0; y < kH; ++y)
        for (int x = 0; x < kW; ++x) {
            const std::size_t i = std::size_t(y) * kW + x;
            Vec3 o, d;
            cam.screen_ray({float(x) + 0.5f, float(y) + 0.5f}, targetSize, o, d);
            d = normalize(d);
            const Nearest n = nearest(cpu, o, d, 0.0f);
            float* px = &prepass[i * 4];
            if (n.tri < 0) {
                px[0] = 1.0e30f;
                continue;
            }
            primary[i] = n.tri;
            Vec3 nn = normalize(cross(cpu[std::size_t(n.tri)].b - cpu[std::size_t(n.tri)].a,
                                      cpu[std::size_t(n.tri)].c - cpu[std::size_t(n.tri)].a));
            if (dot(nn, d) > 0.0f) nn = nn * -1.0f;
            const Vec3 hitp = o + d * n.t;
            const float depth = dot(cam.forward, hitp - cam.position);
            const Vec2 e = oct_encode({dot(nn, cam.right), dot(nn, cam.up), -dot(nn, cam.forward)});
            px[0] = depth;
            px[1] = e.x;
            px[2] = e.y;
            px[3] = 1.0f;
            // A raster surface nearer than the traced one (a terrain, say) on the left sixth of the picture: the kernel must leave it to the raster.
            if (x < kW / 6) px[0] = depth * 0.5f;
        }
    Scene scene(rig);
    scene.build(&ground, &box, std::vector<Place>(places.begin(), places.end()), kMask, prepass);

    fa::render::RtEffectParams params{};
    fa::render::fill_rt_effect_camera(params, cam, kW, kH, true);
    fa::render::RtHitParams hit{};
    zero_hit(hit);
    const Vec3 sunDir = normalize(Vec3{-0.5f, 0.7f, -0.45f});
    const Vec3 sunColor{3.0f, 2.8f, 2.5f};
    hit.sunDir[0] = sunDir.x;
    hit.sunDir[1] = sunDir.y;
    hit.sunDir[2] = sunDir.z;
    for (int c = 0; c < 3; ++c) hit.sunColor[c] = comp(sunColor, c);
    // The sky and the ambient are what a ray that leaves sees; at one bounce they are never read.
    hit.sky[0] = 0.4f;
    hit.sky[1] = 0.5f;
    hit.sky[2] = 0.9f;
    hit.horizon[0] = hit.horizon[1] = hit.horizon[2] = 0.7f;
    hit.ambient[0] = hit.ambient[1] = hit.ambient[2] = 0.2f;

    // The lights: a point light and a spot light, one at a time (the kernel picks one of the lights by chance, so one light is exact).
    fa::render::RtLightParams point{};
    point.count[0] = 1;
    const Vec3 pointPos{1.5f, 3.0f, 2.5f};
    const Vec3 pointColor{6.0f, 5.0f, 4.0f};
    const float pointRange = 12.0f;
    point.pos[0][0] = pointPos.x;
    point.pos[0][1] = pointPos.y;
    point.pos[0][2] = pointPos.z;
    point.pos[0][3] = pointRange;
    for (int c = 0; c < 3; ++c) point.color[0][c] = comp(pointColor, c);
    point.color[0][3] = 1.0f;
    fa::render::RtLightParams spot{};
    spot.count[0] = 1;
    const Vec3 spotPos{3.0f, 4.0f, 3.0f};
    const Vec3 spotColor{4.0f, 4.0f, 6.0f};
    const float spotRange = 10.0f, cosOuter = 0.9f, cosInner = 0.97f;
    spot.pos[0][0] = spotPos.x;
    spot.pos[0][1] = spotPos.y;
    spot.pos[0][2] = spotPos.z;
    spot.pos[0][3] = spotRange;
    for (int c = 0; c < 3; ++c) spot.color[0][c] = comp(spotColor, c);
    spot.color[0][3] = 2.0f;
    spot.dir[0][1] = -1.0f;
    spot.dir[0][3] = cosOuter;
    spot.extra[0][0] = cosInner;

    // The radiance at a point of the CPU scene, at one bounce: the emission, the sun and the one light (all with their shadow rays).
    const auto expect_at = [&](float px, float py, int& triOut, float& distOut,
                               const fa::render::RtLightParams* lightOpt, bool sun, bool isSpot) {
        Vec3 o, d;
        cam.screen_ray({px, py}, targetSize, o, d);
        d = normalize(d);
        const Nearest n = nearest(cpu, o, d, 0.0f);
        triOut = n.tri;
        distOut = n.t;
        if (n.tri < 0) return Vec3{0, 0, 0};
        const Tri& t = cpu[std::size_t(n.tri)];
        const Material& m = places[std::size_t(t.instance)].material;
        Vec3 nn = normalize(cross(t.b - t.a, t.c - t.a));
        if (dot(nn, d) > 0.0f) nn = nn * -1.0f;
        const Vec3 p = o + d * n.t;
        const Vec3 v = d * -1.0f;
        const float off = hit.limits[0] + hit.limits[1] * n.t;
        const Vec3 so = p + nn * off;
        Vec3 color = m.emissive;
        if (sun && dot(nn, sunDir) > 0.0f && nearest(cpu, so, sunDir, -1e-3f).tri < 0)
            color += direct_term(sunDir, nn, v, m) * sunColor;
        if (lightOpt) {
            const Vec3 lp = isSpot ? spotPos : pointPos;
            const Vec3 lc = isSpot ? spotColor : pointColor;
            const float range = isSpot ? spotRange : pointRange;
            const Vec3 to = lp - p;
            const float dist = std::max(length(to), 1e-4f);
            const Vec3 l = to * (1.0f / dist);
            const float x = clamp(1.0f - (dist / range) * (dist / range), 0.0f, 1.0f);
            float atten = x * x;
            if (isSpot) {
                const float ca = dot(l * -1.0f, Vec3{0, -1, 0});
                const float tt = clamp((ca - cosOuter) / (cosInner - cosOuter), 0.0f, 1.0f);
                atten *= tt * tt * (3.0f - 2.0f * tt);
            }
            if (atten > 0.0f && dot(nn, l) > 0.0f) {
                // The shadow ray stops at the light: a hit past it does not shadow.
                const Nearest b = nearest(cpu, so, l, -1e-3f);
                if (b.tri < 0 || b.t > dist - off) color += direct_term(l, nn, v, m) * lc * atten;
            }
        }
        return color;
    };

    struct Mode {
        const char* name;
        bool sun;
        const fa::render::RtLightParams* lights;
        bool isSpot;
    };
    const Mode modes[] = {{"the sun", true, nullptr, false},
                          {"the sun and a point light", true, &point, false},
                          {"a spot light", false, &spot, true}};
    for (const Mode& mode : modes) {
        fa::render::RtHitParams h = hit;
        if (!mode.sun) h.sunColor[0] = h.sunColor[1] = h.sunColor[2] = 0.0f;
        set_frame(params, 0, 3, 16, 1, mode.lights != nullptr);
        const std::vector<float> g = scene.trace(params, h, mode.lights ? *mode.lights : fa::render::RtLightParams{});
        int compared = 0, lit = 0, dark = 0, empty = 0, skipped = 0;
        double errSum = 0.0, magSum = 0.0;
        for (int y = 0; y < kH; ++y)
            for (int x = 0; x < kW; ++x) {
                const std::size_t i = std::size_t(y) * kW + x;
                const float* px = &g[i * 4];
                CAPTURE(mode.name);
                CAPTURE(x);
                CAPTURE(y);
                // The pixel's value is the mean over its area: the centre and eight points on its border must agree on what they see (the sky or a surface,
                // the same instance) and on the colour, else an edge or a shadow's edge is in it and the pixel is not compared.
                const float fx = float(x) + 0.5f, fy = float(y) + 0.5f;
                constexpr int kN = 9;
                const float offs[kN][2] = {{0, 0},          {0.65f, 0.65f},   {-0.65f, 0.65f},
                                           {0.65f, -0.65f}, {-0.65f, -0.65f}, {0.65f, 0},
                                           {-0.65f, 0},     {0, 0.65f},       {0, -0.65f}};
                Vec3 v[kN];
                int tris[kN];
                float dist[kN];
                for (int k = 0; k < kN; ++k)
                    v[k] = expect_at(fx + offs[k][0], fy + offs[k][1], tris[k], dist[k], mode.lights, mode.sun,
                                     mode.isSpot);
                // A silhouette (a neighbour pixel sees the other side) has partial coverage that depends on the jitter: not compared.
                bool silhouette = false;
                for (int dy = -1; dy <= 1; ++dy)
                    for (int dx = -1; dx <= 1; ++dx) {
                        const int nx = x + dx, ny = y + dy;
                        if (nx < 0 || ny < 0 || nx >= kW || ny >= kH) continue;
                        silhouette = silhouette || (primary[std::size_t(ny) * kW + nx] < 0) != (primary[i] < 0);
                    }
                if (silhouette) {
                    ++skipped;
                    continue;
                }
                int skies = 0;
                for (int k = 0; k < kN; ++k) skies += tris[k] < 0 ? 1 : 0;
                if (skies != 0 && skies != kN) {
                    ++skipped;
                    continue;
                }
                if (skies == kN || x < kW / 6) {  // the sky, or what the raster hides: nothing is written
                    ++empty;
                    CHECK(px[0] == 0.0f);
                    CHECK(px[1] == 0.0f);
                    CHECK(px[2] == 0.0f);
                    CHECK(px[3] == 0.0f);
                    continue;
                }
                // A floor at a grazing angle (the far end of this small picture) changes its depth by several percent across one pixel: the kernel keeps
                // the hits within the step to the next pixel of the prepass's depth, and a jitter past that is left to the raster. Those pixels are not compared.
                bool smooth = true;
                for (int k = 1; k < kN; ++k) smooth = smooth && std::fabs(dist[k] - dist[0]) <= 0.03f * dist[0];
                for (int k = 1; k < kN; ++k) {
                    smooth = smooth && cpu[std::size_t(tris[k])].instance == cpu[std::size_t(tris[0])].instance;
                    for (int c = 0; c < 3; ++c)
                        smooth = smooth &&
                                 std::fabs(comp(v[k], c) - comp(v[0], c)) <= 0.02f * std::fabs(comp(v[0], c)) + 0.005f;
                }
                if (!smooth) {
                    ++skipped;
                    continue;
                }
                ++compared;
                const bool isLit = comp(v[0], 0) + comp(v[0], 1) + comp(v[0], 2) > 0.3f;
                (isLit ? lit : dark)++;
                for (int c = 0; c < 3; ++c) {
                    CHECK(px[c] == doctest::Approx(comp(v[0], c)).epsilon(0.03).scale(1.0));
                    errSum += std::fabs(px[c] - comp(v[0], c));
                    magSum += std::fabs(comp(v[0], c));
                }
                CHECK(px[3] == doctest::Approx(1.0f));
            }
        MESSAGE(mode.name << ": compared " << compared << " pixels (" << lit << " lit, " << dark << " dark, " << skipped
                          << " on an edge, " << empty << " empty), mean error "
                          << (magSum > 0 ? errSum / magSum : 0.0));
        CHECK(compared > 300);
        CHECK(lit > (mode.isSpot ? 10 : 100));  // the spot's cone is narrow
        CHECK(errSum <= 0.01 * magSum + 1e-3);
    }
}

TEST_CASE("rt pathtrace on Metal: the one-bounce picture of the sky: a ray that leaves sees the sky and the ambient") {
    Rig rig;
    std::string skip;
    if (!rig.open(skip)) {
        MESSAGE("skipped: " << skip);
        return;
    }
    // A floor only, white and rough; the camera looks at it. One bounce is the direct light; two add the sky and the ambient reflected by the
    // floor: the converged mean is the floor's albedo times what the hemisphere shows (the sky colour and the ambient), within the bounds.
    Mesh ground = make_quad();
    rig.upload(ground);
    constexpr std::uint8_t kMask = fa::render::kRtMaskOpaque | fa::render::kRtMaskCastsShadow;
    Scene scene(rig);
    std::vector<float> prepass(std::size_t(kW) * kH * 4, 0.0f);
    scene.build(&ground, nullptr,
                {Place{&ground, {0, 0, 0}, 1.0f, Material{{0.8f, 0.8f, 0.8f}, 1.0f, 0.0f, {0, 0, 0}}}}, kMask, prepass);
    const CameraGeometry cam = make_camera({0.0f, 3.0f, 6.0f}, {-60.0f, 0.0f, 0.0f});
    fa::render::RtEffectParams params{};
    fa::render::fill_rt_effect_camera(params, cam, kW, kH, true);
    fa::render::RtHitParams hit{};
    zero_hit(hit);
    hit.sunColor[0] = hit.sunColor[1] = hit.sunColor[2] = 0.0f;
    // A uniform sky: sky = horizon = (0.5, 0.5, 0.5) gives 0.5 above the horizon (and 0.275 under it, never seen from a floor), and an ambient of 0.1.
    for (int c = 0; c < 3; ++c) {
        hit.sky[c] = 0.5f;
        hit.horizon[c] = 0.5f;
        hit.ambient[c] = 0.1f;
    }
    const fa::render::RtLightParams none{};
    set_frame(params, 0, 1, 64, 1, false);
    std::vector<float> one = scene.trace(params, hit, none);
    for (std::size_t i = 0; i < std::size_t(kW) * kH; i += 11) {
        CHECK(one[i * 4] == 0.0f);  // no light, no emission: black (the sky is seen only by the paths that leave)
        CHECK(one[i * 4 + 3] == doctest::Approx(1.0f));
    }
    std::vector<float> two;
    for (std::uint32_t first = 0; first < 128; first += 64) {
        set_frame(params, first, 1, 64, 2, false);
        two = scene.trace(params, hit, none);
    }
    // A diffuse bounce off the floor: the throughput is albedo * (1 - small), the environment 0.6 (sky 0.5 + ambient 0.1): about 0.8 * 0.6 = 0.48, plus
    // the rough specular lobe (0.04 * 0.45 of the same): between 0.46 and 0.52 on the pixels that look at the floor.
    double sum = 0.0;
    int n = 0;
    for (std::size_t i = 0; i < std::size_t(kW) * kH; ++i) {
        if (two[i * 4 + 3] < 0.5f) continue;
        sum += two[i * 4];
        ++n;
    }
    REQUIRE(n > 500);
    const double mean = sum / double(n);
    MESSAGE("the floor under a uniform sky of 0.5 and an ambient of 0.1: the mean at two bounces is " << mean);
    CHECK(mean > 0.45);
    CHECK(mean < 0.53);
}

#else

TEST_CASE("rt pathtrace on Metal: only on a Mac") { MESSAGE("skipped: this host has no Metal"); }

#endif
