// M79 P1m: ray tracing on Metal (docs/design/ARCHITECTURE_RENDERING_RAYTRACING.md, "Metal"). These cases run on a Mac or an iOS
// device whose GPU traces rays (MTLDevice.supportsRaytracing): they build a BLAS and a TLAS, dispatch the shipped rt_probe kernel
// through the SokolDevice and read the distances back against a CPU ray caster over the same triangles. A machine without ray
// tracing (an older OS, the iOS simulator, a CI runner's virtualised GPU) says so and skips the cases that need it; the refusal
// case checks the reasons there instead. Nothing here fails a runner for lacking the hardware.
#include <doctest.h>

#include <algorithm>
#include <array>
#include <cmath>
#include <cstdint>
#include <cstring>
#include <memory>
#include <string>
#include <vector>

#include "gpu/accel.h"
#include "gpu/device.h"
#include "gpu/sokol_device.h"
#include "rt_kernels.h"
#include "test_util.h"

#if defined(__APPLE__)

using namespace fa;
using namespace fa::gpu;

namespace {

constexpr int kDim = 32;  // the probe image is kDim x kDim: four 8x8 thread groups each way
constexpr float kMiss = 1000.0f;

bool contains(const std::string& s, const std::string& part) { return s.find(part) != std::string::npos; }

struct P3 {
    float x, y, z;
};

P3 sub(P3 a, P3 b) { return {a.x - b.x, a.y - b.y, a.z - b.z}; }
P3 cross(P3 a, P3 b) { return {a.y * b.z - a.z * b.y, a.z * b.x - a.x * b.z, a.x * b.y - a.y * b.x}; }
float dot(P3 a, P3 b) { return a.x * b.x + a.y * b.y + a.z * b.z; }

// One instance of the CPU scene: the triangles of the mesh and the row-major 3x4 transform.
struct CpuInstance {
    float m[12];
};

P3 apply(const float* m, P3 p) {
    return {m[0] * p.x + m[1] * p.y + m[2] * p.z + m[3], m[4] * p.x + m[5] * p.y + m[6] * p.z + m[7],
            m[8] * p.x + m[9] * p.y + m[10] * p.z + m[11]};
}

// Moller-Trumbore with a margin: `grow` > 0 makes a triangle a little bigger, < 0 a little smaller (the pixels whose answer
// depends on it lie on an edge and are not compared).
bool hit_triangle(P3 o, P3 d, P3 a, P3 b, P3 c, float grow, float& t) {
    const P3 e1 = sub(b, a), e2 = sub(c, a);
    const P3 p = cross(d, e2);
    const float det = dot(e1, p);
    if (std::fabs(det) < 1e-12f) return false;
    const float inv = 1.0f / det;
    const P3 s = sub(o, a);
    const float u = dot(s, p) * inv;
    const P3 q = cross(s, e1);
    const float v = dot(d, q) * inv;
    if (u < -grow || v < -grow || u + v > 1.0f + grow) return false;
    t = dot(e2, q) * inv;
    return t >= 0.001f && t <= 1000.0f;
}

// The nearest hit of the ray of pixel (px, py) as rt_probe casts it: origin `origin`, direction normalize(uv, -1).
float cpu_trace(const std::vector<P3>& vertices, const std::vector<std::uint16_t>& indices,
                const std::vector<CpuInstance>& instances, const float origin[3], int px, int py, float grow) {
    const float u = (float(px) + 0.5f) / float(kDim) * 2.0f - 1.0f;
    const float v = (float(py) + 0.5f) / float(kDim) * 2.0f - 1.0f;
    const float len = std::sqrt(u * u + v * v + 1.0f);
    const P3 d{u / len, v / len, -1.0f / len};
    const P3 o{origin[0], origin[1], origin[2]};
    float best = kMiss;
    for (const CpuInstance& inst : instances) {
        for (std::size_t i = 0; i + 2 < indices.size(); i += 3) {
            float t = 0;
            if (hit_triangle(o, d, apply(inst.m, vertices[indices[i]]), apply(inst.m, vertices[indices[i + 1]]),
                             apply(inst.m, vertices[indices[i + 2]]), grow, t))
                best = std::min(best, t);
        }
    }
    return best;
}

struct ProbeParams {
    float origin[4];
    float dims[4];
};

// The device, the mesh (a quad of two triangles), the scene and the probe pipeline of every case.
struct Rig {
    std::unique_ptr<Device> owner;
    Device* dev = nullptr;
    bool rt = false;
    std::string why;

    std::vector<P3> vertices;
    std::vector<std::uint16_t> indices;
    Buffer vertexBuffer{}, indexBuffer{};
    std::array<AccelTriangles, 1> geometry{};
    std::vector<CpuInstance> cpuInstances;
    std::vector<AccelInstance> instances;

    gpu::Image outImage{};
    View outView{};
    Pipeline pipeline{};
    float origin[3] = {0.0f, 0.0f, 0.0f};

    // False when the case must skip (no GPU, not Metal, no ray tracing); `skip` says why.
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
        rt = dev->ray_tracing_status(&why);
        if (!rt) {
            skip = "this GPU or OS cannot trace rays: " + why;
            return false;
        }
        return true;
    }

    // Four vertices z = 0 (a quad with an odd outline, so no pixel centre lies on an edge by luck), two triangles.
    void make_mesh(bool writableVertices) {
        vertices = {{-0.93f, -0.81f, 0.0f}, {0.71f, -0.83f, 0.0f}, {0.73f, 0.89f, 0.0f}, {-0.91f, 0.87f, 0.0f}};
        indices = {0, 1, 2, 0, 2, 3};
        BufferDesc vb;
        vb.size = vertices.size() * sizeof(P3);
        vb.usage.accelBuildInput = true;
        if (writableVertices) {
            vb.usage.writeTransient = true;  // rewritten with write_buffer: the refit moves vertices
        } else {
            vb.data = Range{vertices.data(), vertices.size() * sizeof(P3)};
        }
        vb.label = "rt mesh vertices";
        vertexBuffer = dev->make_buffer(vb);
        BufferDesc ib;
        ib.size = indices.size() * sizeof(std::uint16_t);
        ib.usage.accelBuildInput = true;
        ib.data = Range{indices.data(), indices.size() * sizeof(std::uint16_t)};
        ib.label = "rt mesh indices";
        indexBuffer = dev->make_buffer(ib);
        geometry[0] = AccelTriangles{};
        geometry[0].vertexBuffer = vertexBuffer;
        geometry[0].vertexStride = sizeof(P3);
        geometry[0].vertexCount = std::uint32_t(vertices.size());
        geometry[0].indexBuffer = indexBuffer;
        geometry[0].indexType = IndexType::Uint16;
        geometry[0].indexCount = std::uint32_t(indices.size());
    }

    // Two instances of the mesh: one left and near (scaled), one right and far.
    void make_instances(const AccelBuildFlags& /*flags*/) {
        cpuInstances = {CpuInstance{{1.3f, 0, 0, -1.7f, 0, 1.3f, 0, 0.2f, 0, 0, 1.0f, -5.0f}},
                        CpuInstance{{1, 0, 0, 1.9f, 0, 1, 0, -0.3f, 0, 0, 1, -8.0f}}};
        instances.assign(2, AccelInstance{});
        for (std::size_t i = 0; i < 2; ++i) {
            std::memcpy(instances[i].transform, cpuInstances[i].m, sizeof(float) * 12);
            instances[i].customIndex = std::uint32_t(i + 1);
        }
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

    // The probe image, its storage view and the compute pipeline of the shipped rt_probe kernel.
    void make_probe() {
        ImageDesc id;
        id.width = kDim;
        id.height = kDim;
        id.pixelFormat = PixelFormat::R32F;
        id.usage.storageImage = true;
        id.label = "rt probe out";
        outImage = dev->make_image(id);
        ViewDesc vd;
        vd.storageImage.image = outImage;
        vd.label = "rt probe out view";
        outView = dev->make_view(vd);

        const fa::rt_kernels::RtKernel* kernel = fa::rt_kernels::find_rt_kernel("rt_probe");
        REQUIRE(kernel != nullptr);
        ShaderDesc sd;
        sd.computeFunc.source = kernel->msl.data();
        sd.computeFunc.entry = "rt_probe";
        sd.mtlThreadsPerThreadgroup[0] = 8;
        sd.mtlThreadsPerThreadgroup[1] = 8;
        sd.mtlThreadsPerThreadgroup[2] = 1;
        sd.usesRayQuery = true;
        sd.accelStructures[0].stage = ShaderStage::Compute;
        sd.accelStructures[0].binding.mslIndex = 0;
        sd.views[0].storageImage.stage = ShaderStage::Compute;
        sd.views[0].storageImage.accessFormat = PixelFormat::R32F;
        sd.views[0].storageImage.writeonly = true;
        sd.views[0].storageImage.binding.mslIndex = 0;
        sd.uniformBlocks[0].stage = ShaderStage::Compute;
        sd.uniformBlocks[0].size = sizeof(ProbeParams);
        sd.uniformBlocks[0].binding.mslIndex = 1;
        sd.label = "rt_probe";
        PipelineDesc pd;
        pd.compute = true;
        pd.shader = dev->make_shader(sd);
        pd.label = "rt_probe";
        pipeline = dev->make_pipeline(pd);
        REQUIRE(dev->state(pd.shader) == ResourceState::Valid);
        REQUIRE(dev->state(pipeline) == ResourceState::Valid);
    }

    // Records the probe dispatch against `tlas` in `cl`.
    void record_trace(CommandList& cl, AccelStructure tlas) {
        ProbeParams p{{origin[0], origin[1], origin[2], 0.0f}, {float(kDim), float(kDim), 0.0f, 0.0f}};
        cl.begin_compute_pass("rt probe");
        cl.set_pipeline(pipeline);
        Bindings b;
        b.views[0] = outView;
        b.accelStructures[0] = tlas;
        cl.set_bindings(b);
        cl.set_uniforms(0, Range{&p, sizeof p});
        cl.dispatch(kDim / 8, kDim / 8, 1);
        cl.end_pass();
    }

    std::vector<float> read_out() {
        std::vector<std::uint8_t> bytes;
        auto r = dev->read_storage_image(outImage, PixelFormat::R32F, 0, 0, kDim, kDim, bytes);
        REQUIRE_MESSAGE(r.ok(), r.error().message);
        REQUIRE(bytes.size() == std::size_t(kDim) * kDim * sizeof(float));
        std::vector<float> out(std::size_t(kDim) * kDim);
        std::memcpy(out.data(), bytes.data(), bytes.size());
        return out;
    }

    // Builds the BLAS and the TLAS and traces once in one command list (the case of a frame that builds and traces).
    struct Built {
        AccelStructure blas{}, tlas{};
        Buffer blasScratch{}, tlasScratch{};
    };

    Built build_scene(const AccelBuildFlags& flags) {
        Built s;
        auto bs = dev->blas_sizes(geometry, flags);
        REQUIRE_MESSAGE(bs.ok(), bs.error().message);
        s.blas = make_as(AccelKind::Blas, bs->structure, "rt blas");
        s.blasScratch = make_scratch(std::max(bs->buildScratch, bs->updateScratch), "rt blas scratch");
        auto ts = dev->tlas_sizes(std::uint32_t(instances.size()), flags);
        REQUIRE_MESSAGE(ts.ok(), ts.error().message);
        s.tlas = make_as(AccelKind::Tlas, ts->structure, "rt tlas");
        s.tlasScratch = make_scratch(std::max(ts->buildScratch, ts->updateScratch), "rt tlas scratch");
        for (AccelInstance& i : instances) i.blas = s.blas;
        return s;
    }

    Result<void> record_builds(CommandList& cl, const Built& s, const AccelBuildFlags& flags, bool update) {
        BlasBuild bb;
        bb.dst = s.blas;
        bb.geometries = geometry;
        bb.flags = flags;
        bb.update = update;
        bb.scratch = s.blasScratch;
        auto r = cl.build_blas(bb);
        if (!r.ok()) return r;
        TlasBuild tb;
        tb.dst = s.tlas;
        tb.instances = instances;
        tb.flags = flags;
        tb.update = update;
        tb.scratch = s.tlasScratch;
        return cl.build_tlas(tb);
    }

    // Compares `got` with the CPU ray caster over the current vertices; returns the pixels that hit and the number compared.
    void compare(const std::vector<float>& got, int& hits, int& compared) {
        hits = 0;
        compared = 0;
        for (int y = 0; y < kDim; ++y) {
            for (int x = 0; x < kDim; ++x) {
                const float big = cpu_trace(vertices, indices, cpuInstances, origin, x, y, 1e-3f);
                const float small = cpu_trace(vertices, indices, cpuInstances, origin, x, y, -1e-3f);
                const float g = got[std::size_t(y) * kDim + x];
                if ((big < kMiss) != (small < kMiss)) continue;  // on an edge: either answer is right
                ++compared;
                const bool cpuHit = small < kMiss;
                if (g < kMiss) ++hits;
                CAPTURE(x);
                CAPTURE(y);
                CAPTURE(g);
                CAPTURE(small);
                CHECK((g < kMiss) == cpuHit);
                if (cpuHit && g < kMiss) CHECK(std::fabs(g - small) <= 1e-3f * small + 1e-4f);
            }
        }
    }
};

}  // namespace

TEST_CASE("metal ray tracing: a TLAS of two instances traced by rt_probe matches the CPU ray caster") {
    Rig rig;
    std::string skip;
    if (!rig.open(skip)) {
        MESSAGE("skipped: " << skip);
        return;
    }
    Device& dev = *rig.dev;
    CHECK(dev.features().rayQuery);
    CHECK(dev.features().accelerationStructure);
    CHECK_FALSE(dev.features().rayTracingPipeline);
    CHECK(dev.limits().maxAccelInstances > 0);
    MESSAGE("Metal ray tracing: vendor " << std::string(gpu_vendor_name(dev.info().gpu.vendor)));

    rig.make_mesh(false);
    AccelBuildFlags flags;
    rig.make_instances(flags);
    rig.make_probe();
    auto s = rig.build_scene(flags);
    CHECK(dev.accel_structure_state(s.blas) == ResourceState::Valid);
    CHECK(dev.accel_structure_state(s.tlas) == ResourceState::Valid);

    CommandList& cl = dev.begin_commands("rt frame");
    auto built = rig.record_builds(cl, s, flags, false);
    REQUIRE_MESSAGE(built.ok(), built.error().message);
    rig.record_trace(cl, s.tlas);
    dev.submit(cl);
    dev.commit();

    int hits = 0, compared = 0;
    rig.compare(rig.read_out(), hits, compared);
    CHECK(hits > 40);  // the scene covers part of the image
    CHECK(hits < compared - 100);  // and leaves misses
    CHECK(compared > kDim * kDim * 9 / 10);  // few pixels lie on an edge

    dev.destroy_accel_structure(s.tlas);
    dev.destroy_accel_structure(s.blas);
    CHECK(dev.accel_structure_state(s.tlas) == ResourceState::Invalid);
}

TEST_CASE("metal ray tracing: a TLAS rebuilt on consecutive frames follows the instances") {
    Rig rig;
    std::string skip;
    if (!rig.open(skip)) {
        MESSAGE("skipped: " << skip);
        return;
    }
    Device& dev = *rig.dev;
    rig.make_mesh(false);
    AccelBuildFlags flags;
    flags.preferFastBuild = true;
    rig.make_instances(flags);
    rig.make_probe();
    auto s = rig.build_scene(flags);

    for (int frame = 0; frame < 5; ++frame) {
        CAPTURE(frame);
        // The near instance slides to the right each frame; the BLAS is built once (frame 0).
        rig.cpuInstances[0].m[3] = -1.7f + 0.6f * float(frame);
        std::memcpy(rig.instances[0].transform, rig.cpuInstances[0].m, sizeof(float) * 12);
        CommandList& cl = dev.begin_commands("rt frame");
        if (frame == 0) {
            BlasBuild bb;
            bb.dst = s.blas;
            bb.geometries = rig.geometry;
            bb.flags = flags;
            bb.scratch = s.blasScratch;
            auto r = cl.build_blas(bb);
            REQUIRE_MESSAGE(r.ok(), r.error().message);
        }
        TlasBuild tb;
        tb.dst = s.tlas;
        tb.instances = rig.instances;
        tb.flags = flags;
        tb.scratch = s.tlasScratch;
        auto r = cl.build_tlas(tb);
        REQUIRE_MESSAGE(r.ok(), r.error().message);
        rig.record_trace(cl, s.tlas);
        dev.submit(cl);
        dev.commit();
        int hits = 0, compared = 0;
        rig.compare(rig.read_out(), hits, compared);
        CHECK(hits > 30);
    }
}

TEST_CASE("metal ray tracing: a refit after moving vertices traces the moved mesh, in place") {
    Rig rig;
    std::string skip;
    if (!rig.open(skip)) {
        MESSAGE("skipped: " << skip);
        return;
    }
    Device& dev = *rig.dev;
    rig.make_mesh(true);
    AccelBuildFlags flags;
    flags.allowUpdate = true;
    rig.make_instances(flags);
    rig.make_probe();
    auto s = rig.build_scene(flags);
    {
        auto sizes = dev.blas_sizes(rig.geometry, flags);
        REQUIRE(sizes.ok());
        CHECK(sizes->updateScratch <= sizes->buildScratch);  // Metal may need none to refit
    }

    for (int frame = 0; frame < 3; ++frame) {
        CAPTURE(frame);
        if (frame > 0) {
            // Stretch the quad to the right and up by a different amount each frame.
            for (P3& v : rig.vertices) {
                if (v.x > 0) v.x += 0.35f;
                if (v.y > 0) v.y += 0.25f;
            }
        }
        CommandList& cl = dev.begin_commands("rt frame");
        BufferWrite w;
        w.data = Range{rig.vertices.data(), rig.vertices.size() * sizeof(P3)};
        w.buffer = rig.vertexBuffer;
        w.size = rig.vertices.size() * sizeof(P3);
        cl.write_buffer(w);
        auto r = rig.record_builds(cl, s, flags, frame > 0);
        REQUIRE_MESSAGE(r.ok(), r.error().message);
        rig.record_trace(cl, s.tlas);
        dev.submit(cl);
        dev.commit();
        int hits = 0, compared = 0;
        rig.compare(rig.read_out(), hits, compared);
        CHECK(hits > 30);
    }
}

TEST_CASE("metal ray tracing: a compacted BLAS is smaller or equal and traces like the original") {
    Rig rig;
    std::string skip;
    if (!rig.open(skip)) {
        MESSAGE("skipped: " << skip);
        return;
    }
    Device& dev = *rig.dev;
    rig.make_mesh(false);
    AccelBuildFlags flags;
    flags.allowCompaction = true;
    rig.make_instances(flags);
    rig.make_probe();
    auto s = rig.build_scene(flags);

    BufferDesc qd;
    qd.size = 256;
    qd.usage.storageBuffer = true;
    qd.label = "rt compacted size";
    const Buffer sizeBuffer = dev.make_buffer(qd);

    CommandList& build = dev.begin_commands("rt build");
    BlasBuild bb;
    bb.dst = s.blas;
    bb.geometries = rig.geometry;
    bb.flags = flags;
    bb.scratch = s.blasScratch;
    REQUIRE(build.build_blas(bb).ok());
    auto q = build.query_compacted_size(s.blas, sizeBuffer, 0);
    REQUIRE_MESSAGE(q.ok(), q.error().message);
    dev.submit(build);
    dev.commit();

    std::vector<std::uint8_t> bytes;
    REQUIRE(dev.read_buffer(sizeBuffer, 0, 8, bytes).ok());
    std::uint64_t compacted = 0;
    REQUIRE(bytes.size() == 8);
    std::memcpy(&compacted, bytes.data(), 8);
    auto sizes = dev.blas_sizes(rig.geometry, flags);
    REQUIRE(sizes.ok());
    MESSAGE("BLAS " << sizes->structure << " bytes, compacted " << compacted << " bytes");
    CHECK(compacted > 0);
    CHECK(compacted <= sizes->structure);

    const AccelStructure small = rig.make_as(AccelKind::Blas, compacted, "rt blas compacted");
    for (AccelInstance& i : rig.instances) i.blas = small;
    CommandList& frame = dev.begin_commands("rt compact");
    auto c = frame.copy_accel_structure(s.blas, small, AccelCopyMode::Compact);
    REQUIRE_MESSAGE(c.ok(), c.error().message);
    TlasBuild tb;
    tb.dst = s.tlas;
    tb.instances = rig.instances;
    tb.flags = flags;
    tb.scratch = s.tlasScratch;
    REQUIRE(frame.build_tlas(tb).ok());
    rig.record_trace(frame, s.tlas);
    dev.submit(frame);
    dev.commit();
    int hits = 0, compared = 0;
    rig.compare(rig.read_out(), hits, compared);
    CHECK(hits > 40);  // the scene covers part of the image

    // A clone is the same size and traces the same.
    const AccelStructure clone = rig.make_as(AccelKind::Blas, compacted, "rt blas clone");
    for (AccelInstance& i : rig.instances) i.blas = clone;
    CommandList& again = dev.begin_commands("rt clone");
    REQUIRE(again.copy_accel_structure(small, clone, AccelCopyMode::Clone).ok());
    tb.instances = rig.instances;
    REQUIRE(again.build_tlas(tb).ok());
    rig.record_trace(again, s.tlas);
    dev.submit(again);
    dev.commit();
    rig.compare(rig.read_out(), hits, compared);
}

TEST_CASE("metal ray tracing: the refusals teach (caller storage, a call inside a pass, a bad binding)") {
    Rig rig;
    std::string skip;
    if (!rig.open(skip)) {
        MESSAGE("skipped: " << skip);
        return;
    }
    Device& dev = *rig.dev;
    rig.make_mesh(false);
    AccelBuildFlags flags;
    rig.make_instances(flags);
    rig.make_probe();
    auto s = rig.build_scene(flags);

    // The structure's memory is the device's: caller storage is refused with the way out.
    BufferDesc sd;
    sd.size = 4096;
    sd.usage.accelStorage = true;
    sd.label = "rt storage";
    AccelStructureDesc ad;
    ad.kind = AccelKind::Blas;
    ad.size = 4096;
    ad.storage = dev.make_buffer(sd);
    ad.label = "rt aliased";
    auto aliased = dev.make_accel_structure(ad);
    REQUIRE_FALSE(aliased.ok());
    CHECK(contains(aliased.error().message, "storage"));
    CHECK_FALSE(aliased.error().hint.empty());

    // A size that does not come from the sizes query.
    ad.storage = Buffer{};
    ad.size = 0;
    CHECK_FALSE(dev.make_accel_structure(ad).ok());

    // A build inside a pass.
    CommandList& cl = dev.begin_commands("rt refusals");
    cl.begin_compute_pass("pass");
    BlasBuild bb;
    bb.dst = s.blas;
    bb.geometries = rig.geometry;
    bb.flags = flags;
    bb.scratch = s.blasScratch;
    auto inPass = cl.build_blas(bb);
    REQUIRE_FALSE(inPass.ok());
    CHECK(contains(inPass.error().message, "build_blas"));
    cl.end_pass();

    // A TLAS that was never built cannot be traced; a build over a BLAS that was never built is refused.
    auto notBuilt = cl.build_tlas([&] {
        TlasBuild tb;
        tb.dst = s.tlas;
        tb.instances = rig.instances;
        tb.flags = flags;
        tb.scratch = s.tlasScratch;
        return tb;
    }());
    REQUIRE_FALSE(notBuilt.ok());
    CHECK(contains(notBuilt.error().message, "build_tlas"));
    CHECK_FALSE(notBuilt.error().hint.empty());

    // Too small a scratch buffer.
    BlasBuild tiny = bb;
    tiny.scratch = rig.make_scratch(0, "rt tiny");  // make_scratch rounds up to 256; the BLAS needs more or is borderline
    auto sizes = dev.blas_sizes(rig.geometry, flags);
    REQUIRE(sizes.ok());
    if (sizes->buildScratch > 256) {
        auto small = cl.build_blas(tiny);
        REQUIRE_FALSE(small.ok());
        CHECK(contains(small.error().message, "scratch"));
    }
    dev.submit(cl);
    dev.commit();
    CHECK(dev.accel_structure_state(s.blas) == ResourceState::Valid);
}

TEST_CASE("metal ray tracing: a device without it refuses every call with the device and the OS named") {
    auto& g = fa::test::gfx();
    if (!g.ok) {
        MESSAGE("skipped: no GPU here (" << g.error << ")");
        return;
    }
    if (built_sokol_backend() != Backend::Metal) {
        MESSAGE("skipped: the sokol backend of this build is " << backend_name(built_sokol_backend()));
        return;
    }
    auto made = make_device(built_sokol_backend());
    REQUIRE_MESSAGE(made, (made ? "" : made.error().message));
    Device& dev = *made.value();
    std::string why;
    const bool rt = dev.ray_tracing_status(&why);
    CHECK(rt == dev.features().accelerationStructure);
    CHECK(rt == dev.features().rayQuery);
    CHECK_FALSE(dev.features().rayTracingPipeline);
    if (rt) {
        CHECK(why.empty());
        MESSAGE("this GPU traces rays: vendor " << std::string(gpu_vendor_name(dev.info().gpu.vendor)));
        return;
    }
    MESSAGE("this GPU or OS cannot trace rays (" << why << "): the refusals are checked here");
    CHECK(contains(why, "ray tracing"));
    const auto sizes = dev.tlas_sizes(4, {});
    REQUIRE_FALSE(sizes.ok());
    CHECK(contains(sizes.error().message, "gpu: Device::tlas_sizes: "));
    CHECK_FALSE(sizes.error().hint.empty());
    AccelStructureDesc d;
    d.size = 4096;
    CHECK_FALSE(dev.make_accel_structure(d).ok());
    CommandList& cl = dev.begin_commands("refusals");
    CHECK_FALSE(cl.build_tlas({}).ok());
    CHECK_FALSE(cl.build_blas({}).ok());
    dev.submit(cl);
    dev.commit();
    BufferDesc b;
    b.size = 256;
    b.usage.accelScratch = true;
    b.label = "scratch";
    CHECK(dev.state(dev.make_buffer(b)) == ResourceState::Failed);
}

#endif  // __APPLE__
