// M79-P2a-3: the kernels of the ray traced shadows of point, spot and area lights (shaders/rt/rt_shadow_local.metal, rt_shadow_local_pack.metal) run for
// real on a Mac whose GPU traces rays, through the SokolDevice. A ground plane and a box under a spot light and an area light; the prepass image is
// made on the CPU from the camera's own rays, the constants blocks by the engine's own functions (fill_rt_effect_camera, make_rt_local_params), and the
// visibilities the kernel writes are compared with a CPU ray caster over the same triangles. A machine without ray tracing says so and skips. The D3D12
// and Vulkan kernels are the same HLSL, compiled by DXC; no test of this suite runs them.
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
#include "rt_local_shadows.h"
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

bool any_hit(const std::vector<Tri>& tris, Vec3 o, Vec3 d, float grow, float tMin, float tMax, int mask) {
    for (const Tri& t : tris) {
        float h = 0;
        if ((t.mask & mask) != 0 && hit_tri(o, d, t, grow, tMin, tMax, h)) return true;
    }
    return false;
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

struct Rig {
    std::unique_ptr<Device> owner;
    Device* dev = nullptr;
    gpu::Image prepass{}, out{}, srcImage{}, packOut{};
    View prepassView{}, outView{}, outTexture{}, srcView{}, packOutView{};
    Pipeline traceP{}, packP{};
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
        vb.label = "rt local mesh vertices";
        m.vb = dev->make_buffer(vb);
        BufferDesc ib;
        ib.size = m.indices.size() * sizeof(std::uint16_t);
        ib.usage.accelBuildInput = true;
        ib.data = Range{m.indices.data(), ib.size};
        ib.label = "rt local mesh indices";
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

    gpu::Image make_rgba32f(const std::vector<float>* data, bool storage, const char* label) {
        ImageDesc d;
        d.width = kW;
        d.height = kH;
        d.pixelFormat = PixelFormat::Rgba32F;
        d.usage.storageImage = storage;
        if (data) d.data.mipLevels[0] = Range{data->data(), data->size() * sizeof(float)};
        d.label = label;
        return dev->make_image(d);
    }

    View texture_view(gpu::Image image, const char* label) {
        ViewDesc v;
        v.texture.image = image;
        v.label = label;
        return dev->make_view(v);
    }

    View storage_view(gpu::Image image, const char* label) {
        ViewDesc v;
        v.storageImage.image = image;
        v.label = label;
        return dev->make_view(v);
    }

    Pipeline make_pipeline(const char* kernel) {
        const fa::rt_kernels::RtKernel* k = fa::rt_kernels::find_rt_kernel(kernel);
        REQUIRE(k != nullptr);
        const fa::render::RtEffectKernelSpec* spec = fa::render::find_rt_effect_spec(kernel);
        REQUIRE(spec != nullptr);
        PipelineDesc pd;
        pd.compute = true;
        pd.shader = dev->make_shader(fa::render::rt_effect_shader_desc(*k, *spec, Backend::Metal));
        pd.label = kernel;
        Pipeline p = dev->make_pipeline(pd);
        REQUIRE(dev->state(pd.shader) == ResourceState::Valid);
        REQUIRE(dev->state(p) == ResourceState::Valid);
        return p;
    }

    void make_images(const std::vector<float>& prepassData, const std::vector<float>& sunData) {
        prepass = make_rgba32f(&prepassData, false, "rt local prepass");
        prepassView = texture_view(prepass, "rt local prepass view");
        out = make_rgba32f(nullptr, true, "rt local out");
        outView = storage_view(out, "rt local out view");
        outTexture = texture_view(out, "rt local out texture view");
        srcImage = make_rgba32f(&sunData, false, "rt local sun image");
        srcView = texture_view(srcImage, "rt local sun image view");
        packOut = make_rgba32f(nullptr, true, "rt local pack out");
        packOutView = storage_view(packOut, "rt local pack out view");
        SamplerDesc sd;
        sd.label = "rt local nearest";
        nearestSampler = dev->make_sampler(sd);
        traceP = make_pipeline("rt_shadow_local");
        packP = make_pipeline("rt_shadow_local_pack");
    }

    std::vector<float> read(gpu::Image image) {
        std::vector<std::uint8_t> bytes;
        auto r = dev->read_storage_image(image, PixelFormat::Rgba32F, 0, 0, kW, kH, bytes);
        REQUIRE_MESSAGE(r.ok(), r.error().message);
        REQUIRE(bytes.size() == std::size_t(kW) * kH * 4 * sizeof(float));
        std::vector<float> v(std::size_t(kW) * kH * 4);
        std::memcpy(v.data(), bytes.data(), bytes.size());
        return v;
    }

    std::vector<float> trace(AccelStructure tlas, const fa::render::RtEffectParams& params,
                             const fa::render::RtLocalParams& local, CommandList* builds = nullptr) {
        CommandList& cl = builds ? *builds : dev->begin_commands("rt local frame");
        cl.begin_compute_pass("rt local");
        cl.set_pipeline(traceP);
        Bindings b;
        b.views[fa::render::RtEffectBindings::kViewOut] = outView;
        b.views[fa::render::RtEffectBindings::kViewPrepass] = prepassView;
        b.samplers[fa::render::RtEffectBindings::kSampler] = nearestSampler;
        b.accelStructures[0] = tlas;
        cl.set_bindings(b);
        cl.set_uniforms(fa::render::RtEffectBindings::kUniformParams, Range{&params, sizeof params});
        cl.set_uniforms(fa::render::RtEffectBindings::kUniformHit, Range{&local, sizeof local});
        cl.dispatch(kW / 8, kH / 8, 1);
        cl.end_pass();
        dev->submit(cl);
        dev->commit();
        return read(out);
    }

    // The pack pass: `src` = the sun's image or the prepass (params.user1.x), and the trace image as the visibilities.
    std::vector<float> pack(const fa::render::RtEffectParams& params, bool sunSource) {
        CommandList& cl = dev->begin_commands("rt local pack");
        cl.begin_compute_pass("rt local pack");
        cl.set_pipeline(packP);
        Bindings b;
        b.views[fa::render::RtEffectBindings::kViewOut] = packOutView;
        b.views[fa::render::RtEffectBindings::kViewPrepass] = sunSource ? srcView : prepassView;
        b.views[fa::render::RtEffectBindings::kViewAux] = outTexture;
        b.samplers[fa::render::RtEffectBindings::kSampler] = nearestSampler;
        cl.set_bindings(b);
        cl.set_uniforms(fa::render::RtEffectBindings::kUniformParams, Range{&params, sizeof params});
        cl.dispatch(kW / 8, kH / 8, 1);
        cl.end_pass();
        dev->submit(cl);
        dev->commit();
        return read(packOut);
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

// A spot light and a disc area light, as the renderer's light table would have them.
render::LightData make_spot(Vec3 pos, Vec3 target, float softness, bool hard) {
    render::LightData l{};
    const Vec3 axis = normalize(target - pos);
    l.pos = {pos.x, pos.y, pos.z, 40.0f};
    l.color = {1, 1, 1, 2.0f};
    l.dir = {axis.x, axis.y, axis.z, std::cos(35.0f * 3.14159265f / 180.0f)};
    l.shadow.casts = true;
    l.shadow.softness = softness;
    l.shadow.filter = hard ? 1 : 0;
    return l;
}

render::LightData make_disc(Vec3 pos, float halfSize, float softness, bool hard) {
    render::LightData l{};
    l.pos = {pos.x, pos.y, pos.z, 40.0f};
    l.color = {1, 1, 1, 3.0f};
    l.dir = {0, -1, 0, 0};
    l.hasExt = true;
    l.extent = halfSize;
    l.ext[0] = {1, 0, 0, halfSize};
    l.ext[1] = {0, 0, 1, halfSize};
    l.ext[2] = {0, 0, 0, 1.0f};  // 1 = disc
    l.shadow.casts = true;
    l.shadow.softness = softness;
    l.shadow.filter = hard ? 1 : 0;
    return l;
}

}  // namespace

TEST_CASE("rt shadow local on Metal: the visibility of a spot and an area light matches a CPU ray caster, hard and "
          "soft, is the same every frame, "
          "and the pack keeps the sun's image") {
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
    const std::array<Place, 3> places = {Place{&ground, {0, 0, 0}, 0xFF}, Place{&box, {0.0f, 0, 0.0f}, 0xFF},
                                         Place{&box, {-5.0f, 0, -1.0f}, 0x01}};
    std::vector<Tri> tris;
    for (const Place& p : places)
        for (std::size_t i = 0; i + 2 < p.mesh->indices.size(); i += 3)
            tris.push_back({p.mesh->vertices[p.mesh->indices[i]] + p.at,
                            p.mesh->vertices[p.mesh->indices[i + 1]] + p.at,
                            p.mesh->vertices[p.mesh->indices[i + 2]] + p.at, p.mask});

    AccelBuildFlags flags;
    for (Mesh* m : {&ground, &box}) {
        const AccelTriangles g = rig.geometry_of(*m);
        auto bs = dev.blas_sizes(std::span<const AccelTriangles>(&g, 1), flags);
        REQUIRE_MESSAGE(bs.ok(), bs.error().message);
        m->blas = rig.make_as(AccelKind::Blas, bs->structure, "rt local blas");
        m->scratch = rig.make_scratch(std::max(bs->buildScratch, bs->updateScratch), "rt local blas scratch");
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
    const AccelStructure tlas = rig.make_as(AccelKind::Tlas, ts->structure, "rt local tlas");
    const Buffer tlasScratch = rig.make_scratch(std::max(ts->buildScratch, ts->updateScratch), "rt local tlas scratch");

    // The camera and the prepass the kernel reads, made from the camera's own rays on the CPU.
    const CameraGeometry cam = make_camera();
    const Vec2 targetSize{float(kW), float(kH)};
    std::vector<float> prepass(std::size_t(kW) * kH * 4, 0.0f);
    std::vector<int> primary(std::size_t(kW) * kH,
                             -2);  // the triangle of each pixel, -1 the sky, -2 an edge (not compared)
    std::vector<float> depths(std::size_t(kW) * kH, 0.0f);
    std::vector<Vec3> positions(std::size_t(kW) * kH), normals(std::size_t(kW) * kH);
    for (int y = 0; y < kH; ++y)
        for (int x = 0; x < kW; ++x) {
            const std::size_t i = std::size_t(y) * kW + x;
            Vec3 o, d;
            cam.screen_ray({float(x) + 0.5f, float(y) + 0.5f}, targetSize, o, d);
            d = normalize(d);
            const Nearest big = nearest(tris, o, d, 1e-3f, 0.001f, 1000.0f, 0xFF);
            const Nearest small = nearest(tris, o, d, -1e-3f, 0.001f, 1000.0f, 0xFF);
            if (big.tri != small.tri) continue;
            primary[i] = small.tri;
            float* px = &prepass[i * 4];
            if (small.tri < 0) {
                px[0] = kNoMesh;
                continue;
            }
            const Tri& t = tris[std::size_t(small.tri)];
            Vec3 n = normalize(cross(t.b - t.a, t.c - t.a));
            if (dot(n, d) > 0.0f) n = n * -1.0f;
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
    // The sun's final image the pack pass can keep: (depth, visibility, 0, mesh flag), the visibility a ramp.
    std::vector<float> sunImage(std::size_t(kW) * kH * 4, 0.0f);
    for (int i = 0; i < kW * kH; ++i) {
        sunImage[std::size_t(i) * 4 + 0] = prepass[std::size_t(i) * 4 + 0];
        sunImage[std::size_t(i) * 4 + 1] = float(i % kW) / float(kW - 1);
        sunImage[std::size_t(i) * 4 + 3] = prepass[std::size_t(i) * 4 + 3];
    }
    rig.make_images(prepass, sunImage);

    fa::render::RtEffectParams params{};
    fa::render::fill_rt_effect_camera(params, cam, kW, kH, true);
    params.frame[0] = 12;
    params.frame[1] = fa::render::rt_effect_seed(12);
    params.frame[2] = 16;
    for (int i = 0; i < 4; ++i) params.user0[i] = fa::render::kRtShadowUser0[i];
    const auto frame_params = [&](bool soft, std::uint64_t serial, std::uint32_t rays) {
        fa::render::RtEffectParams p = params;
        p.frame[0] = std::uint32_t(serial);
        p.frame[1] = fa::render::rt_effect_seed(serial);
        p.frame[2] = rays;
        p.user1[1] = soft ? 1.0f : 0.0f;
        return p;
    };
    // The two lights in slots 0 and 1; slot 2 is empty.
    const Vec3 spotAt{-5.0f, 7.0f, 3.0f}, discAt{4.0f, 6.0f, -1.5f};
    const auto lights_of = [&](float softness, bool hard) {
        std::vector<render::LightData> table = {make_spot(spotAt, {0, 0.5f, 0}, softness, hard),
                                                make_disc(discAt, 1.0f, softness, hard)};
        render::RtLocalPick pick;
        pick.light = {0, 1, -1};
        pick.count = 2;
        pick.traced = 2;
        return render::make_rt_local_params(table, pick);
    };

    // One frame builds the BLASes and the TLAS and traces, like the renderer's.
    CommandList& cl = dev.begin_commands("rt local frame");
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

    // ---- hard: one ray to each light's centre, whatever the lights' softness -------------------------------------------------------------------
    const render::RtLocalParams hardLights = lights_of(1.0f, false);
    const std::vector<float> first = rig.trace(tlas, frame_params(false, 12, 1), hardLights, &cl);
    const auto centre_blocked = [&](std::size_t i, const render::RtLocalLight& L, float grow, bool& outOfReach) {
        outOfReach = false;
        const Vec3 pos = positions[i];
        const Vec3 toLight = Vec3{L.posReach[0], L.posReach[1], L.posReach[2]} - pos;
        const float dist = length(toLight);
        const Vec3 l = toLight / dist;
        const Vec3 axis{L.axisCos[0], L.axisCos[1], L.axisCos[2]};
        const int kind = int(L.kind[0] + 0.5f);
        if (dist > L.posReach[3] || (kind == 2 && dot(l * -1.0f, axis) < L.axisCos[3] - 0.02f) ||
            (kind >= 3 && dot(toLight * -1.0f, axis) < -0.01f)) {
            outOfReach = true;  // the kernel does not trace: lit
            return false;
        }
        const float offset = params.user0[0] + params.user0[1] * depths[i];
        const Vec3 o = pos + normals[i] * offset;
        const Vec3 v = Vec3{L.posReach[0], L.posReach[1], L.posReach[2]} - o;
        const float len = length(v);
        return any_hit(tris, o, v / len, grow, params.user0[2], len * (1.0f - hardLights.header[1]), 0x08);
    };
    int compared[2] = {0, 0}, shadowed[2] = {0, 0}, lit[2] = {0, 0}, outside[2] = {0, 0};
    int sky = 0;
    for (int y = 0; y < kH; ++y)
        for (int x = 0; x < kW; ++x) {
            const std::size_t i = std::size_t(y) * kW + x;
            const float* g = &first[i * 4];
            CAPTURE(x);
            CAPTURE(y);
            if (primary[i] == -2) continue;
            if (primary[i] == -1) {  // the sky: nothing to shadow, no mesh
                ++sky;
                CHECK(g[0] == 1.0f);
                CHECK(g[1] == 1.0f);
                CHECK(g[2] == 1.0f);
                CHECK(g[3] == 0.0f);
                continue;
            }
            CHECK(g[3] == 1.0f);
            CHECK(g[2] == 1.0f);  // the empty slot never shadows
            for (int s = 0; s < 2; ++s) {
                bool outA = false, outB = false;
                const bool bigHit = centre_blocked(i, hardLights.lights[s], 1e-3f, outA);
                const bool smallHit = centre_blocked(i, hardLights.lights[s], -1e-3f, outB);
                if (bigHit != smallHit) continue;  // on the edge of a shadow
                ++compared[s];
                if (outA) ++outside[s];
                if (smallHit)
                    ++shadowed[s];
                else
                    ++lit[s];
                CHECK(g[s] == (smallHit ? 0.0f : 1.0f));
            }
        }
    MESSAGE("spot: compared " << compared[0] << ", shadowed " << shadowed[0] << ", lit " << lit[0]
                              << ", outside the cone " << outside[0] << "; area: compared " << compared[1]
                              << ", shadowed " << shadowed[1] << ", lit " << lit[1] << "; sky " << sky);
    for (int s = 0; s < 2; ++s) {
        CHECK(compared[s] > kW * kH / 3);
        CHECK(shadowed[s] > 20);  // the box's shadow and its dark sides
        CHECK(lit[s] > 300);
    }
    CHECK(outside[0] > 20);  // the spot's cone does not reach the whole ground: the pixels outside are lit
    CHECK(sky > 50);
    // The hard image does not depend on the seed, and the same frame is the same, bit for bit.
    CHECK(rig.trace(tlas, frame_params(false, 12, 1), hardLights) == first);
    CHECK(rig.trace(tlas, frame_params(false, 13, 1), hardLights) == first);
    // The soft flag with lights of no size is the same image.
    CHECK(rig.trace(tlas, frame_params(true, 14, 8), lights_of(0.0f, true)) == first);

    // ---- soft: rays over the spot's cone and the disc, against the mean of a dense sampling of the same shapes -------------------------------------
    struct SoftStats {
        int umbra = 0, full = 0, partial = 0;
        double meanError = 0.0, meanPenumbraError = 0.0, maxError = 0.0;
        std::vector<float> vis;  // the kernel's, slot 0 and 1 interleaved
    };
    const auto measure = [&](float softness, std::uint32_t rays, std::uint64_t serial) {
        const render::RtLocalParams L = lights_of(softness, false);
        const std::vector<float> img = rig.trace(tlas, frame_params(true, serial, rays), L);
        SoftStats st;
        constexpr int kSamples = 160;
        double sumErr = 0, sumPen = 0;
        int n = 0, nPen = 0;
        for (int y = 0; y < kH; ++y)
            for (int x = 0; x < kW; ++x) {
                const std::size_t i = std::size_t(y) * kW + x;
                if (primary[i] < 0) continue;
                for (int s = 0; s < 2; ++s) {
                    const render::RtLocalLight& l = L.lights[s];
                    const Vec3 centre{l.posReach[0], l.posReach[1], l.posReach[2]};
                    const Vec3 toLight = centre - positions[i];
                    const float dist = length(toLight);
                    const Vec3 dirToLight = toLight / dist;
                    const Vec3 axis{l.axisCos[0], l.axisCos[1], l.axisCos[2]};
                    const int kind = int(l.kind[0] + 0.5f);
                    float f = 1.0f;
                    const bool traced =
                        !(dist > l.posReach[3] || (kind == 2 && dot(dirToLight * -1.0f, axis) < l.axisCos[3] - 0.02f));
                    if (traced) {
                        const Vec3 t = normalize(std::fabs(dirToLight.y) < 0.99f ? cross(dirToLight, Vec3{0, 1, 0})
                                                                                 : cross(dirToLight, Vec3{1, 0, 0}));
                        const Vec3 b = cross(dirToLight, t);
                        const float offset = params.user0[0] + params.user0[1] * depths[i];
                        const Vec3 o = positions[i] + normals[i] * offset;
                        int free = 0;
                        for (int k = 0; k < kSamples; ++k) {
                            const float r = std::sqrt((float(k) + 0.5f) / float(kSamples)), a = float(k) * 2.39996323f;
                            Vec3 target = centre;
                            if (kind == 2 || kind == 1) {
                                target = target + (t * std::cos(a) + b * std::sin(a)) * (r * l.kind[1] * dist);
                            } else {
                                const Vec3 right{l.right[0], l.right[1], l.right[2]}, up{l.up[0], l.up[1], l.up[2]};
                                target = target + (right * std::cos(a) + up * std::sin(a)) * (r * l.kind[2]);
                            }
                            const Vec3 v = target - o;
                            const float len = length(v);
                            if (!any_hit(tris, o, v / len, -1e-3f, params.user0[2], len * (1.0f - L.header[1]), 0x08))
                                ++free;
                        }
                        f = float(free) / float(kSamples);
                    }
                    const float k = img[i * 4 + std::size_t(s)];
                    CAPTURE(x);
                    CAPTURE(y);
                    CAPTURE(s);
                    CHECK(k >= 0.0f);
                    CHECK(k <= 1.0f);
                    CHECK(std::fabs(k * float(rays) - std::round(k * float(rays))) <
                          1e-3f);  // a visibility of N rays is a multiple of 1 / N
                    const double err = std::fabs(double(k) - double(f));
                    sumErr += err;
                    ++n;
                    st.maxError = std::max(st.maxError, err);
                    if (f == 0.0f) {
                        ++st.umbra;
                    } else if (f == 1.0f) {
                        ++st.full;
                    } else {
                        ++st.partial;
                        sumPen += err;
                        ++nPen;
                    }
                }
            }
        st.meanError = n ? sumErr / n : 0.0;
        st.meanPenumbraError = nPen ? sumPen / nPen : 0.0;
        st.vis = img;
        return st;
    };
    const SoftStats narrow = measure(1.0f, 16, 31);
    const SoftStats wide = measure(4.0f, 16, 31);
    MESSAGE("soft: softness 1: umbra " << narrow.umbra << ", full " << narrow.full << ", penumbra " << narrow.partial
                                       << ", mean error " << narrow.meanError << " (penumbra "
                                       << narrow.meanPenumbraError << ", max " << narrow.maxError
                                       << "); softness 4: umbra " << wide.umbra << ", full " << wide.full
                                       << ", penumbra " << wide.partial << ", mean error " << wide.meanError
                                       << " (penumbra " << wide.meanPenumbraError << ", max " << wide.maxError << ")");
    for (const SoftStats* st : {&narrow, &wide}) {
        CHECK(st->umbra > 10);
        CHECK(st->full > 300);
        CHECK(st->meanError < 0.05);
        CHECK(st->meanPenumbraError < 0.13);  // 16 rays: the standard deviation of a visibility is at most 0.125
        CHECK(st->maxError < 0.65);
    }
    // The penumbra widens with the lights' size, and the umbra shrinks.
    CHECK(wide.partial > narrow.partial);
    CHECK(wide.umbra < narrow.umbra);
    // The same serial gives the same image, bit for bit; another one changes the penumbra, not the umbra and the full light.
    const render::RtLocalParams L1 = lights_of(4.0f, false);
    const std::vector<float> a = rig.trace(tlas, frame_params(true, 40, 8), L1);
    CHECK(rig.trace(tlas, frame_params(true, 40, 8), L1) == a);
    const std::vector<float> b = rig.trace(tlas, frame_params(true, 41, 8), L1);
    CHECK(b != a);
    for (int i = 0; i < kW * kH; ++i)
        for (int s = 0; s < 2; ++s) {
            const float va = a[std::size_t(i) * 4 + std::size_t(s)], vb = b[std::size_t(i) * 4 + std::size_t(s)];
            if (va == 0.0f || va == 1.0f)
                CHECK(std::fabs(va - vb) <= 0.5f);  // a pixel in the umbra is not in the full light the next frame
        }
    // More than the 16 rays the kernel allows is 16: the same image.
    CHECK(rig.trace(tlas, frame_params(true, 42, 16), L1) == rig.trace(tlas, frame_params(true, 42, 160), L1));
    // A light that reaches nowhere (the empty slot) and a count of 0 shadow nothing.
    {
        render::RtLocalPick none;
        const render::RtLocalParams empty = render::make_rt_local_params({}, none);
        const std::vector<float> lit_all = rig.trace(tlas, frame_params(true, 43, 8), empty);
        for (int i = 0; i < kW * kH; ++i) {
            if (primary[std::size_t(i)] == -2) continue;
            CHECK(lit_all[std::size_t(i) * 4 + 0] == 1.0f);
            CHECK(lit_all[std::size_t(i) * 4 + 1] == 1.0f);
            CHECK(lit_all[std::size_t(i) * 4 + 2] == 1.0f);
        }
    }

    // ---- the pack pass: the three visibilities in the three bytes of one float, with the sun's depth and visibility kept -----------------------------
    const std::vector<float> trace = rig.trace(tlas, frame_params(false, 50, 1), hardLights);
    for (bool sun : {false, true}) {
        INFO("sun image " << sun);
        fa::render::RtEffectParams pp = frame_params(false, 50, 1);
        pp.user1[0] = sun ? 1.0f : 0.0f;
        pp.user1[1] = 2.0f;  // two lights: the third byte is 255 (an empty slot: lit)
        const std::vector<float> packed = rig.pack(pp, sun);
        int checked = 0;
        for (int y = 0; y < kH; ++y)
            for (int x = 0; x < kW; ++x) {
                const std::size_t i = std::size_t(y) * kW + x;
                if (primary[i] == -2) continue;
                const float* p = &packed[i * 4];
                CAPTURE(x);
                CAPTURE(y);
                if (primary[i] == -1) {  // the sky: no mesh, every light lit, in the layout the lit pass reads
                    CHECK(p[0] == kNoMesh);
                    CHECK(p[1] == 1.0f);
                    CHECK(p[2] == 16777215.0f);
                    CHECK(p[3] == 0.0f);
                    continue;
                }
                CHECK(p[0] == doctest::Approx(depths[i]).epsilon(1e-6));
                CHECK(p[1] == (sun ? sunImage[i * 4 + 1] : 1.0f));  // the sun's visibility is kept, or no sun: lit
                CHECK(p[3] == 1.0f);
                const std::uint32_t bits = std::uint32_t(p[2]);
                CHECK(float(bits) == p[2]);  // an integer a float holds exactly
                CHECK(bits <= 16777215u);
                CHECK(int(bits & 255u) == int(std::lround(trace[i * 4 + 0] * 255.0f)));
                CHECK(int((bits >> 8) & 255u) == int(std::lround(trace[i * 4 + 1] * 255.0f)));
                CHECK(int((bits >> 16) & 255u) == 255);
                ++checked;
            }
        CHECK(checked > kW * kH / 2);
    }

    dev.destroy_accel_structure(tlas);
    dev.destroy_accel_structure(ground.blas);
    dev.destroy_accel_structure(box.blas);
}

#else

TEST_CASE("rt shadow local on Metal: only on a Mac") { MESSAGE("skipped: this host has no Metal"); }

#endif
