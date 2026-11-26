// M79-P3a-1: the sharp reflection kernel (shaders/rt/rt_reflect.metal, with the hit shading of rt_hit.msli) run for real on a Mac whose GPU
// traces rays, through the SokolDevice. A mirror floor in front of a red box and a green box under a sun, the prepass and the thin G-buffer
// made on the CPU from the camera's own rays, the records of the instances in the buffer the renderer's scene would hold, the constants by
// the engine's fill_rt_effect_camera; what the kernel writes is compared with a CPU port of the same functions (a ray caster over the same
// triangles: the closest hit, its flat normal, the sun's shadow ray, the Lambert and GGX terms, the environment's gradient). The same frame
// with a rough floor must write nothing (the screen-space reflections and the probes keep it). A machine without ray tracing says so and skips.
// The D3D12 and Vulkan kernels are the same HLSL compiled by DXC; no test in this suite runs them.
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
Vec3 shade_hit(const Scene& sc, const std::vector<Tri>& tris, const Material& m, Vec3 p, Vec3 n, Vec3 toViewer, float t) {
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
            const float vis = 0.5f / (ndl * std::sqrt(ndv * ndv * (1.0f - a2) + a2) +
                                      ndv * std::sqrt(ndl * ndl * (1.0f - a2) + a2));
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
        vb.label = "rt reflect mesh vertices";
        m.vb = dev->make_buffer(vb);
        BufferDesc ib;
        ib.size = m.indices.size() * sizeof(std::uint16_t);
        ib.usage.accelBuildInput = true;
        ib.data = Range{m.indices.data(), ib.size};
        ib.label = "rt reflect mesh indices";
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
        const fa::rt_kernels::RtKernel* k = fa::rt_kernels::find_rt_kernel("rt_reflect");
        REQUIRE(k != nullptr);
        const fa::render::RtEffectKernelSpec* spec = fa::render::find_rt_effect_spec("rt_reflect");
        REQUIRE(spec != nullptr);
        SamplerDesc sd;
        sd.label = "rt reflect nearest";
        nearestSampler = dev->make_sampler(sd);
        PipelineDesc pd;
        pd.compute = true;
        pd.shader = dev->make_shader(fa::render::rt_effect_shader_desc(*k, *spec, Backend::Metal));
        pd.label = "rt_reflect";
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

TEST_CASE("rt reflect on Metal: the mirror floor shows the boxes and the sky as a CPU ray caster computes them, and a rough floor is left "
          "to the old path") {
    Rig rig;
    std::string skip;
    if (!rig.open(skip)) {
        MESSAGE("skipped: " << skip);
        return;
    }
    Device& dev = *rig.dev;
    MESSAGE("Metal ray tracing: vendor " << std::string(gpu_vendor_name(dev.info().gpu.vendor)));

    // The scene: a floor (the instance 0, a mirror), a red box and a green box (a rough and a smooth one); the three cast shadows.
    Mesh ground = make_quad(), box = make_box();
    rig.upload(ground);
    rig.upload(box);
    struct Place {
        Mesh* mesh;
        Vec3 at;
        Material material;
    };
    const std::array<Place, 3> places = {
        Place{&ground, {0, 0, 0}, Material{{0.5f, 0.5f, 0.5f}, 0.0f, 0.5f, {0, 0, 0}}},
        Place{&box, {-1.0f, 0, 0.5f}, Material{{0.8f, 0.05f, 0.05f}, 0.8f, 0.0f, {0, 0, 0}}},
        Place{&box, {4.0f, 0, -1.0f}, Material{{0.1f, 0.7f, 0.1f}, 0.3f, 0.0f, {0, 0, 0}}}};
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
        m->blas = rig.make_as(AccelKind::Blas, bs->structure, "rt reflect blas");
        m->scratch = rig.make_scratch(std::max(bs->buildScratch, bs->updateScratch), "rt reflect blas scratch");
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
        in.customIndex = std::uint32_t(i);  // the record's index
        fa::render::RtInstanceRecord& r = records[i];
        std::memset(&r, 0, sizeof r);
        r.objectToWorld[0] = r.objectToWorld[5] = r.objectToWorld[10] = 1.0f;
        r.objectToWorld[3] = places[i].at.x;
        r.objectToWorld[7] = places[i].at.y;
        r.objectToWorld[11] = places[i].at.z;
        r.albedo[0] = places[i].material.albedo.x;
        r.albedo[1] = places[i].material.albedo.y;
        r.albedo[2] = places[i].material.albedo.z;
        r.albedo[3] = 1.0f;
        r.roughness = places[i].material.roughness;
        r.metalness = places[i].material.metalness;
        r.flags = fa::render::kRtFlagOpaque | fa::render::kRtFlagCastsShadow;
    }
    auto ts = dev.tlas_sizes(std::uint32_t(instances.size()), flags);
    REQUIRE_MESSAGE(ts.ok(), ts.error().message);
    const AccelStructure tlas = rig.make_as(AccelKind::Tlas, ts->structure, "rt reflect tlas");
    const Buffer tlasScratch = rig.make_scratch(std::max(ts->buildScratch, ts->updateScratch), "rt reflect tlas scratch");
    BufferDesc rbd;
    rbd.size = records.size() * sizeof(fa::render::RtInstanceRecord);
    rbd.usage.storageBuffer = true;
    rbd.data = Range{records.data(), rbd.size};
    rbd.label = "rt reflect records";
    const Buffer recordBuffer = dev.make_buffer(rbd);
    ViewDesc rvd;
    rvd.storageBuffer.buffer = recordBuffer;
    rvd.label = "rt reflect records view";
    const View recordsView = dev.make_view(rvd);

    // The camera, the prepass and the thin G-buffer the kernel reads (made from the camera's own rays on the CPU) and the constants.
    const CameraGeometry cam = make_camera();
    Scene sc;
    sc.sunDir = normalize(Vec3{-0.5f, 0.7f, -0.45f});
    sc.sunColor = {3.0f, 2.8f, 2.5f};
    sc.ambient = {0.10f, 0.10f, 0.12f};
    sc.sky = {0.35f, 0.55f, 0.90f};
    sc.horizon = {0.80f, 0.80f, 0.75f};
    const Vec2 targetSize{float(kW), float(kH)};
    const std::size_t pixels = std::size_t(kW) * kH;
    std::vector<float> prepass(pixels * 4, 0.0f), albedoData(pixels * 4, 0.0f), materialData(pixels * 4, 0.0f);
    std::vector<float> roughData(pixels * 4, 0.0f);
    std::vector<int> primary(pixels, -2);  // the triangle of each pixel, -1 the sky, -2 an edge (not compared)
    std::vector<Vec3> positions(pixels), normals(pixels), views(pixels);
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
            positions[i] = hit;
            normals[i] = n;
            views[i] = d;
            const Material& m = places[std::size_t(t.instance)].material;
            for (int c = 0; c < 3; ++c) albedoData[i * 4 + c] = comp(m.albedo, c);
            albedoData[i * 4 + 3] = 1.0f;
            materialData[i * 4 + 0] = m.roughness;
            materialData[i * 4 + 1] = m.metalness;
            materialData[i * 4 + 3] = 1.0f;
            roughData[i * 4 + 0] = std::max(m.roughness, 0.9f);  // the same frame with every surface rough
            roughData[i * 4 + 1] = m.metalness;
            roughData[i * 4 + 3] = 1.0f;
        }
    }
    View prepassView, albedoView, materialView, roughView;
    const gpu::Image prepassImg = rig.make_texture(prepass, "rt reflect prepass", prepassView);
    const gpu::Image albedoImg = rig.make_texture(albedoData, "rt reflect albedo", albedoView);
    const gpu::Image materialImg = rig.make_texture(materialData, "rt reflect material", materialView);
    const gpu::Image roughImg = rig.make_texture(roughData, "rt reflect rough material", roughView);
    ImageDesc od;
    od.width = kW;
    od.height = kH;
    od.pixelFormat = PixelFormat::Rgba32F;
    od.usage.storageImage = true;
    od.label = "rt reflect out";
    const gpu::Image outImg = dev.make_image(od);
    ViewDesc ov;
    ov.storageImage.image = outImg;
    ov.label = "rt reflect out view";
    const View outView = dev.make_view(ov);
    rig.make_pipeline();

    fa::render::RtEffectParams params{};
    fa::render::fill_rt_effect_camera(params, cam, kW, kH, true);
    params.lightDir[0] = sc.sunDir.x;
    params.lightDir[1] = sc.sunDir.y;
    params.lightDir[2] = sc.sunDir.z;
    params.frame[0] = 12;
    params.frame[1] = fa::render::rt_effect_seed(12);
    params.frame[2] = 1;
    params.user0[0] = 0.02f;    // the mirror ray's offset along the normal (metres)
    params.user0[1] = 0.002f;   // more of it per metre of view depth
    params.user0[2] = 0.25f;    // the roughness cutoff
    params.user0[3] = 10000.0f;  // TMax
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

    auto trace = [&](View material, CommandList* builds) {
        CommandList& cl = builds ? *builds : dev.begin_commands("rt reflect frame");
        cl.begin_compute_pass("rt reflect");
        cl.set_pipeline(rig.pipeline);
        Bindings b;
        b.views[fa::render::RtEffectBindings::kViewOut] = outView;
        b.views[fa::render::RtEffectBindings::kViewPrepass] = prepassView;
        b.views[fa::render::RtEffectBindings::kViewRecords] = recordsView;
        b.views[fa::render::RtEffectBindings::kViewAlbedo] = albedoView;
        b.views[fa::render::RtEffectBindings::kViewMaterial] = material;
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
    CommandList& cl = dev.begin_commands("rt reflect frame");
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
    const std::vector<float> first = trace(materialView, &cl);

    int compared = 0, hitsRed = 0, hitsGreen = 0, hitsFloor = 0, misses = 0, notTraced = 0, shaded = 0;
    float worst = 0.0f;
    for (int y = 0; y < kH; ++y) {
        for (int x = 0; x < kW; ++x) {
            const std::size_t i = std::size_t(y) * kW + x;
            const float* g = &first[i * 4];
            CAPTURE(x);
            CAPTURE(y);
            if (primary[i] == -2) continue;
            const bool floorPixel = primary[i] >= 0 && tris[std::size_t(primary[i])].instance == 0;
            if (!floorPixel) {  // the sky, a box (rougher than the cutoff): not traced
                ++notTraced;
                CHECK(g[0] == 0.0f);
                CHECK(g[1] == 0.0f);
                CHECK(g[2] == 0.0f);
                CHECK(g[3] == 0.0f);
                continue;
            }
            // The mirror ray, as the kernel makes it: from the surface, offset along the normal, in the reflection of the view.
            const float depth = prepass[i * 4];
            const Vec3 n = normals[i];
            const Vec3 r = normalize(reflect_dir(views[i], n));
            const float offset = params.user0[0] + params.user0[1] * depth;
            const Vec3 o = positions[i] + n * offset;
            const Nearest big = nearest(tris, o, r, 1e-3f, 0.0f, 10000.0f, 0x07);
            const Nearest small = nearest(tris, o, r, -1e-3f, 0.0f, 10000.0f, 0x07);
            if (big.tri != small.tri) continue;  // on an edge of the box
            const Vec3 tint = lerp(Vec3{1, 1, 1}, Vec3{0.5f, 0.5f, 0.5f}, 0.5f);  // the floor: albedo 0.5, metalness 0.5
            if (small.tri < 0) {
                ++compared;
                ++misses;
                const Vec3 expect = environment(sc, r, 0.0f) * tint;
                CHECK(g[3] == -1.0f);
                CHECK(g[0] == doctest::Approx(expect.x).epsilon(2e-3).scale(1.0));
                CHECK(g[1] == doctest::Approx(expect.y).epsilon(2e-3).scale(1.0));
                CHECK(g[2] == doctest::Approx(expect.z).epsilon(2e-3).scale(1.0));
                continue;
            }
            // A hit: its distance, then the colour where the hit is well inside its triangle (the normal comes from a differential there).
            ++compared;
            CHECK(g[3] > 0.0f);
            CHECK(g[3] == doctest::Approx(small.t).epsilon(1e-3));
            const Tri& ht = tris[std::size_t(small.tri)];
            if (ht.instance == 1) ++hitsRed;
            if (ht.instance == 2) ++hitsGreen;
            if (ht.instance == 0) ++hitsFloor;
            if (nearest(tris, o, r, -0.05f, 0.0f, 10000.0f, 0x07).tri != small.tri) continue;
            Vec3 hn = normalize(cross(ht.b - ht.a, ht.c - ht.a));
            if (dot(hn, r) > 0.0f) hn = hn * -1.0f;
            const Vec3 p = o + r * small.t;
            const Vec3 expect = shade_hit(sc, tris, places[std::size_t(ht.instance)].material, p, hn, r * -1.0f, small.t) * tint;
            // A pixel whose sun shadow ray grazes an edge may differ: skip when a slightly bigger and smaller triangle disagree.
            const float off = sc.shadowOffset + sc.shadowOffsetPerMetre * small.t;
            const bool sb = nearest(tris, p + hn * off, sc.sunDir, 1e-3f, 0.0f, 10000.0f, 0x08).tri >= 0;
            const bool ss = nearest(tris, p + hn * off, sc.sunDir, -1e-3f, 0.0f, 10000.0f, 0x08).tri >= 0;
            if (sb != ss) continue;
            ++shaded;
            for (int c = 0; c < 3; ++c) {
                const float want = comp(expect, c);
                CHECK(g[c] == doctest::Approx(want).epsilon(5e-3).scale(1.0));
                worst = std::max(worst, std::fabs(g[c] - want));
            }
        }
    }
    MESSAGE("compared " << compared << ", shaded " << shaded << ", hit the red box " << hitsRed << ", the green box " << hitsGreen
                        << ", the floor " << hitsFloor << ", missed " << misses << ", not traced " << notTraced
                        << ", worst colour error " << worst);
    CHECK(compared > 400);
    CHECK(hitsRed > 40);   // the mirror floor shows the red box
    CHECK(misses > 40);    // and the sky
    CHECK(shaded > 40);
    CHECK(notTraced > 200);

    // A red box in a mirror is red.
    int redPixels = 0;
    for (int y = 0; y < kH; ++y)
        for (int x = 0; x < kW; ++x) {
            const std::size_t i = std::size_t(y) * kW + x;
            const float* g = &first[i * 4];
            if (g[3] > 0.0f && g[0] > 3.0f * std::max(g[1], g[2]) && g[0] > 0.05f) ++redPixels;
        }
    CHECK(redPixels > 20);

    // The same frame twice gives the same image, bit for bit; a new frame serial (a new seed) does not change a mirror.
    CHECK(trace(materialView, nullptr) == first);
    const fa::render::RtEffectParams saved = params;
    params.frame[0] = 13;
    params.frame[1] = fa::render::rt_effect_seed(13);
    CHECK(trace(materialView, nullptr) == first);
    params = saved;

    // Every surface rough: the kernel traces nothing and writes zeros (the screen-space reflections and the probes keep the picture).
    const std::vector<float> rough = trace(roughView, nullptr);
    int nonZero = 0;
    for (std::size_t i = 0; i < rough.size(); ++i) nonZero += rough[i] != 0.0f ? 1 : 0;
    CHECK(nonZero == 0);

    for (const View v : {outView, prepassView, albedoView, materialView, roughView, recordsView}) dev.destroy_view(v);
    for (const gpu::Image im : {outImg, prepassImg, albedoImg, materialImg, roughImg}) dev.destroy_image(im);
    dev.destroy_buffer(recordBuffer);
    dev.destroy_accel_structure(tlas);
    dev.destroy_accel_structure(ground.blas);
    dev.destroy_accel_structure(box.blas);
}

#else

TEST_CASE("rt reflect on Metal: only on a Mac") { MESSAGE("skipped: this host has no Metal"); }

#endif
