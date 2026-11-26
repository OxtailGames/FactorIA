// M79-P2a-1: the hard shadow kernel (shaders/rt/rt_shadow.metal) run for real on a Mac whose GPU traces rays, through the SokolDevice. A
// ground plane, a box that casts and a box that does not (its instance lacks the CastsShadow bit) under the sun; the prepass image is made
// on the CPU from the camera's own rays, the constants block by the engine's fill_rt_effect_camera, and the visibility the kernel writes is
// compared with a CPU ray caster over the same triangles. A machine without ray tracing (an older OS, the iOS simulator, a virtualised
// GPU) says so and skips; nothing here fails a runner for lacking the hardware. The D3D12 and Vulkan kernels are the same HLSL, compiled
// by DXC; they have no test that runs them in this suite.
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
};

// Moller-Trumbore; `grow` > 0 makes a triangle a little bigger, < 0 a little smaller (the pixels whose answer depends on it lie on an edge).
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

// A mesh: its vertices and indices in one place for the GPU and the CPU.
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
    m.indices = {0, 2, 1, 0, 3, 2, 4, 5, 6, 4, 6, 7, 0, 4, 7, 0, 7, 3, 1, 2, 6, 1, 6, 5, 3, 7, 6, 3, 6, 2, 0, 1, 5, 0, 5, 4};
    return m;
}

struct Rig {
    std::unique_ptr<Device> owner;
    Device* dev = nullptr;
    gpu::Image prepass{};
    View prepassView{};
    gpu::Image out{};
    View outView{};
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
        vb.label = "rt shadow mesh vertices";
        m.vb = dev->make_buffer(vb);
        BufferDesc ib;
        ib.size = m.indices.size() * sizeof(std::uint16_t);
        ib.usage.accelBuildInput = true;
        ib.data = Range{m.indices.data(), ib.size};
        ib.label = "rt shadow mesh indices";
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

    void make_images(const std::vector<float>& prepassData) {
        ImageDesc pd;
        pd.width = kW;
        pd.height = kH;
        pd.pixelFormat = PixelFormat::Rgba32F;
        pd.data.mipLevels[0] = Range{prepassData.data(), prepassData.size() * sizeof(float)};
        pd.label = "rt shadow prepass";
        prepass = dev->make_image(pd);
        ViewDesc pv;
        pv.texture.image = prepass;
        pv.label = "rt shadow prepass view";
        prepassView = dev->make_view(pv);
        ImageDesc od;
        od.width = kW;
        od.height = kH;
        od.pixelFormat = PixelFormat::Rgba32F;
        od.usage.storageImage = true;
        od.label = "rt shadow out";
        out = dev->make_image(od);
        ViewDesc ov;
        ov.storageImage.image = out;
        ov.label = "rt shadow out view";
        outView = dev->make_view(ov);
    }

    void make_pipeline() {
        const fa::rt_kernels::RtKernel* k = fa::rt_kernels::find_rt_kernel("rt_shadow");
        REQUIRE(k != nullptr);
        const fa::render::RtEffectKernelSpec* spec = fa::render::find_rt_effect_spec("rt_shadow");
        REQUIRE(spec != nullptr);
        SamplerDesc sd;
        sd.label = "rt shadow nearest";
        nearestSampler = dev->make_sampler(sd);
        PipelineDesc pd;
        pd.compute = true;
        pd.shader = dev->make_shader(fa::render::rt_effect_shader_desc(*k, *spec, Backend::Metal));
        pd.label = "rt_shadow";
        pipeline = dev->make_pipeline(pd);
        REQUIRE(dev->state(pd.shader) == ResourceState::Valid);
        REQUIRE(dev->state(pipeline) == ResourceState::Valid);
    }

    std::vector<float> trace(AccelStructure tlas, const fa::render::RtEffectParams& params, CommandList* builds = nullptr) {
        CommandList& cl = builds ? *builds : dev->begin_commands("rt shadow frame");
        cl.begin_compute_pass("rt shadow");
        cl.set_pipeline(pipeline);
        Bindings b;
        b.views[fa::render::RtEffectBindings::kViewOut] = outView;
        b.views[fa::render::RtEffectBindings::kViewPrepass] = prepassView;
        b.samplers[fa::render::RtEffectBindings::kSampler] = nearestSampler;
        b.accelStructures[0] = tlas;
        cl.set_bindings(b);
        cl.set_uniforms(0, Range{&params, sizeof params});
        cl.dispatch(kW / 8, kH / 8, 1);
        cl.end_pass();
        dev->submit(cl);
        dev->commit();
        std::vector<std::uint8_t> bytes;
        auto r = dev->read_storage_image(out, PixelFormat::Rgba32F, 0, 0, kW, kH, bytes);
        REQUIRE_MESSAGE(r.ok(), r.error().message);
        REQUIRE(bytes.size() == std::size_t(kW) * kH * 4 * sizeof(float));
        std::vector<float> v(std::size_t(kW) * kH * 4);
        std::memcpy(v.data(), bytes.data(), bytes.size());
        return v;
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

TEST_CASE("rt shadow on Metal: the hard shadow of the sun matches a CPU ray caster, casters only, and is the same every frame") {
    Rig rig;
    std::string skip;
    if (!rig.open(skip)) {
        MESSAGE("skipped: " << skip);
        return;
    }
    Device& dev = *rig.dev;
    MESSAGE("Metal ray tracing: vendor " << std::string(gpu_vendor_name(dev.info().gpu.vendor)));

    // The scene: the ground and a box that casts (mask 0xFF), a second box that does not (mask 0x01: no CastsShadow bit).
    Mesh ground = make_quad(), box = make_box();
    rig.upload(ground);
    rig.upload(box);
    struct Place {
        Mesh* mesh;
        Vec3 at;
        std::uint8_t mask;
    };
    const std::array<Place, 4> places = {Place{&ground, {0, 0, 0}, 0xFF}, Place{&box, {-1.0f, 0, 0.5f}, 0xFF},
                                         Place{&box, {4.0f, 0, -1.0f}, 0x01}, Place{&box, {-5.0f, 0, -2.0f}, 0xFF}};
    std::vector<Tri> tris;
    for (const Place& p : places) {
        for (std::size_t i = 0; i + 2 < p.mesh->indices.size(); i += 3)
            tris.push_back({p.mesh->vertices[p.mesh->indices[i]] + p.at, p.mesh->vertices[p.mesh->indices[i + 1]] + p.at,
                            p.mesh->vertices[p.mesh->indices[i + 2]] + p.at, p.mask});
    }

    AccelBuildFlags flags;
    for (Mesh* m : {&ground, &box}) {
        const AccelTriangles g = rig.geometry_of(*m);
        auto bs = dev.blas_sizes(std::span<const AccelTriangles>(&g, 1), flags);
        REQUIRE_MESSAGE(bs.ok(), bs.error().message);
        m->blas = rig.make_as(AccelKind::Blas, bs->structure, "rt shadow blas");
        m->scratch = rig.make_scratch(std::max(bs->buildScratch, bs->updateScratch), "rt shadow blas scratch");
    }
    std::vector<AccelInstance> instances(places.size());
    for (std::size_t i = 0; i < places.size(); ++i) {
        AccelInstance& in = instances[i];
        in.transform[3] = places[i].at.x;
        in.transform[7] = places[i].at.y;
        in.transform[11] = places[i].at.z;
        in.blas = places[i].mesh->blas;
        in.mask = places[i].mask;
        in.customIndex = std::uint32_t(i);
    }
    auto ts = dev.tlas_sizes(std::uint32_t(instances.size()), flags);
    REQUIRE_MESSAGE(ts.ok(), ts.error().message);
    const AccelStructure tlas = rig.make_as(AccelKind::Tlas, ts->structure, "rt shadow tlas");
    const Buffer tlasScratch = rig.make_scratch(std::max(ts->buildScratch, ts->updateScratch), "rt shadow tlas scratch");

    // The camera, the prepass the kernel reads (made from the camera's own rays on the CPU) and the constants.
    const CameraGeometry cam = make_camera();
    const Vec3 sun = normalize(Vec3{-0.5f, 0.7f, -0.45f});
    const Vec2 targetSize{float(kW), float(kH)};
    std::vector<float> prepass(std::size_t(kW) * kH * 4, 0.0f);
    std::vector<int> primary(std::size_t(kW) * kH, -2);  // the triangle of each pixel, -1 the sky, -2 an edge (not compared)
    std::vector<float> depths(std::size_t(kW) * kH, 0.0f);
    std::vector<Vec3> positions(std::size_t(kW) * kH);
    std::vector<Vec3> normals(std::size_t(kW) * kH);
    for (int y = 0; y < kH; ++y) {
        for (int x = 0; x < kW; ++x) {
            const std::size_t i = std::size_t(y) * kW + x;
            Vec3 o, d;
            cam.screen_ray({float(x) + 0.5f, float(y) + 0.5f}, targetSize, o, d);
            d = normalize(d);
            const Nearest big = nearest(tris, o, d, 1e-3f, 0.001f, 1000.0f, 0xFF);
            const Nearest small = nearest(tris, o, d, -1e-3f, 0.001f, 1000.0f, 0xFF);
            if (big.tri != small.tri) continue;  // on an edge: either triangle is right
            primary[i] = small.tri;
            float* px = &prepass[i * 4];
            if (small.tri < 0) {
                px[0] = kNoMesh;
                continue;
            }
            const Tri& t = tris[std::size_t(small.tri)];
            Vec3 n = normalize(cross(t.b - t.a, t.c - t.a));
            if (dot(n, d) > 0.0f) n = n * -1.0f;  // the face the camera sees
            const Vec3 hit = o + d * small.t;
            const float depth = dot(cam.forward, hit - cam.position);
            const Vec3 nv{dot(n, cam.right), dot(n, cam.up), -dot(n, cam.forward)};
            const Vec2 e = oct_encode(nv);
            px[0] = depth;
            px[1] = e.x;
            px[2] = e.y;
            px[3] = 1.0f;
            depths[i] = depth;
            positions[i] = hit;
            normals[i] = n;
        }
    }
    rig.make_images(prepass);
    rig.make_pipeline();

    fa::render::RtEffectParams params{};
    fa::render::fill_rt_effect_camera(params, cam, kW, kH, true);
    params.lightDir[0] = sun.x;
    params.lightDir[1] = sun.y;
    params.lightDir[2] = sun.z;
    params.frame[0] = 12;
    params.frame[1] = fa::render::rt_effect_seed(12);
    params.frame[2] = 1;
    params.user0[0] = 0.02f;   // normal offset (metres)
    params.user0[1] = 0.004f;  // more of it per metre of view depth
    params.user0[2] = 0.0005f;  // TMin
    params.user0[3] = 1000.0f;  // TMax

    // One frame builds the BLASes and the TLAS and traces, like the renderer's.
    CommandList& cl = dev.begin_commands("rt shadow frame");
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
    const std::vector<float> first = rig.trace(tlas, params, &cl);

    int compared = 0, shadowed = 0, litGround = 0, sky = 0, castersOnlyMatters = 0;
    for (int y = 0; y < kH; ++y) {
        for (int x = 0; x < kW; ++x) {
            const std::size_t i = std::size_t(y) * kW + x;
            const float* g = &first[i * 4];
            CAPTURE(x);
            CAPTURE(y);
            if (primary[i] == -2) continue;
            if (primary[i] == -1) {  // the sky: nothing to shadow
                ++sky;
                CHECK(g[0] == kNoMesh);
                CHECK(g[1] == 1.0f);
                CHECK(g[3] == 0.0f);
                continue;
            }
            CHECK(g[3] == 1.0f);
            CHECK(g[0] == doctest::Approx(depths[i]).epsilon(1e-5));
            const float offset = params.user0[0] + params.user0[1] * depths[i];
            const Vec3 o = positions[i] + normals[i] * offset;
            const bool bigHit = nearest(tris, o, sun, 1e-3f, params.user0[2], 1000.0f, 0x08).tri >= 0;
            const bool smallHit = nearest(tris, o, sun, -1e-3f, params.user0[2], 1000.0f, 0x08).tri >= 0;
            if (bigHit != smallHit) continue;  // on the edge of a shadow
            ++compared;
            if (smallHit) ++shadowed;
            CHECK(g[1] == (smallHit ? 0.0f : 1.0f));
            const bool anyHit = nearest(tris, o, sun, -1e-3f, params.user0[2], 1000.0f, 0xFF).tri >= 0;
            if (anyHit != smallHit) {  // the box without the CastsShadow bit would have shadowed this pixel
                ++castersOnlyMatters;
            }
            if (primary[i] == 0 && !smallHit) ++litGround;
        }
    }
    MESSAGE("compared " << compared << ", shadowed " << shadowed << ", lit ground " << litGround << ", sky " << sky
                        << ", pixels the non-casting box would have shadowed " << castersOnlyMatters);
    CHECK(compared > kW * kH / 2);
    CHECK(shadowed > 100);        // the boxes' shadows and their own dark sides
    CHECK(litGround > 300);       // and the open ground
    CHECK(sky > 50);
    CHECK(castersOnlyMatters > 10);  // the mask is exercised: the instance with mask 0x01 sits in the sun's way to some pixels

    // The same frame twice gives the same mask, bit for bit; a new frame serial (a new seed) does not change a hard shadow.
    CHECK(rig.trace(tlas, params) == first);
    fa::render::RtEffectParams later = params;
    later.frame[0] = 13;
    later.frame[1] = fa::render::rt_effect_seed(13);
    CHECK(rig.trace(tlas, later) == first);

    dev.destroy_accel_structure(tlas);
    dev.destroy_accel_structure(ground.blas);
    dev.destroy_accel_structure(box.blas);
}

#else

TEST_CASE("rt shadow on Metal: only on a Mac") { MESSAGE("skipped: this host has no Metal"); }

#endif
