// The Vulkan backend's ray tracing (M79 P1v; ARCHITECTURE_RENDERING_RAYTRACING.md, "Vulkan"): the feature and limit
// plumbing and the descriptor set move of a ray-query kernel without a device; the refusals of a device without ray
// tracing (MoltenVK, lavapipe before Mesa 24.1); and, on a device with VK_KHR_acceleration_structure and
// VK_KHR_ray_query, BLAS and TLAS builds traced by the engine's rt_probe kernel and compared with a CPU trace: two
// instances, a refit after the vertices moved, a compacted copy, and a TLAS rebuilt on consecutive frames (the trace of
// one frame reads it while the next frame's build writes it). Every device case runs with the validation layer and its
// synchronization validation and checks that the layer reported no error. A device without ray tracing skips the RT
// cases with its reason (MESSAGE), also under FA_VULKAN_REQUIRE=1; FA_VULKAN_REQUIRE_RT=1 turns that skip into a failure
// that names the device, its driver and what it lacks. The Linux CI job sets both: its lavapipe is Mesa 25.2's
// (noble-updates), which traces rays. Lavapipe runs the kernels on the CPU: the scenes stay tiny (one quad, 16x16 rays).
#include <doctest.h>

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <cstdlib>
#include <cstring>
#include <map>
#include <memory>
#include <string>
#include <utility>
#include <vector>

#include "gpu/vulkan_device.h"
#include "rt_kernels.h"

using namespace fa::gpu;

namespace {

bool contains(const std::string& s, const std::string& part) { return s.find(part) != std::string::npos; }

}  // namespace

#if defined(FA_VULKAN_BACKEND)

using fa::gpu::vk::VulkanDevice;

namespace {

bool vulkan_required() {
    const char* v = std::getenv("FA_VULKAN_REQUIRE");
    return v && std::strcmp(v, "1") == 0;
}

bool cannot_run_here(const std::string& e) {
    return contains(e, "no Vulkan loader") || contains(e, "no Vulkan device") || contains(e, "needs 1.2") ||
           contains(e, "VK_ERROR_INITIALIZATION_FAILED");
}

// A device with the validation layer and its synchronization validation (vulkan_device_tests.cpp's make_vk), or null
// with a MESSAGE when this machine runs no Vulkan; under FA_VULKAN_REQUIRE=1 that skip fails.
std::unique_ptr<VulkanDevice> make_vk() {
    VulkanOptions o;
    o.validation = true;
    o.synchronizationValidation = true;
    auto d = make_vulkan_device(o);
    if (!d) {
        const std::string e = d.error().to_string();
        if (cannot_run_here(e) && !vulkan_required()) {
            MESSAGE("vulkan: skipped, " << e);
            return nullptr;
        }
        FAIL("vulkan: make_vulkan_device failed: " << e);
        return nullptr;
    }
    return std::unique_ptr<VulkanDevice>(static_cast<VulkanDevice*>(d.value().release()));
}

// FA_VULKAN_REQUIRE_RT=1: a device without ray tracing fails the RT cases instead of skipping them (FA_VULKAN_REQUIRE
// asks for Vulkan, not for ray tracing).
bool ray_tracing_required() {
    const char* v = std::getenv("FA_VULKAN_REQUIRE_RT");
    return v && std::strcmp(v, "1") == 0;
}

// A device that traces rays, or null with the reason this one does not: a skip, or a failure under
// FA_VULKAN_REQUIRE_RT=1.
std::unique_ptr<VulkanDevice> make_rt() {
    auto dev = make_vk();
    if (!dev) {
        if (ray_tracing_required())
            FAIL("vulkan ray tracing: FA_VULKAN_REQUIRE_RT=1, but this machine runs no Vulkan device (see the line "
                 "above; install the GPU driver, or Mesa's lavapipe 24.1 or later, and the Vulkan loader)");
        return nullptr;
    }
    std::string why;
    if (!dev->ray_tracing_status(&why)) {
        if (ray_tracing_required())
            FAIL("vulkan ray tracing: FA_VULKAN_REQUIRE_RT=1, but " << why);
        else
            MESSAGE("vulkan ray tracing: skipped, " << why);
        return nullptr;
    }
    return dev;
}

std::string layer_errors(VulkanDevice& dev) {
    std::string s;
    for (const std::string& e : dev.errors())
        if (contains(e, "gpu vulkan validation:")) s += e + "\n";
    return s;
}

std::string all_errors(VulkanDevice& dev) {
    std::string s;
    for (const std::string& e : dev.errors()) s += e + "\n";
    return s;
}

// A refusal that teaches: the message names the problem with its key phrase (never its whole sentence, so a change of
// wording does not break the test) and the hint says what to do (any text).
void check_refusal(const fa::Result<void>& r, const char* keyPhrase) {
    REQUIRE_FALSE(r);
    CHECK_MESSAGE(contains(r.error().message, keyPhrase), "message: " << r.error().message);
    CHECK_MESSAGE(!r.error().hint.empty(), "no hint after: " << r.error().message);
}

void submit_and_finish(VulkanDevice& dev, CommandList& list) {
    dev.submit(list);
    dev.commit();
    auto r = dev.wait_idle();
    REQUIRE_MESSAGE(r, r.error().to_string());
}

std::vector<std::uint32_t> probe_words() {
    const fa::rt_kernels::RtKernel* k = fa::rt_kernels::find_rt_kernel("rt_probe");
    REQUIRE(k != nullptr);
    REQUIRE(k->spirv.size() % 4 == 0);
    std::vector<std::uint32_t> words(k->spirv.size() / 4);
    std::memcpy(words.data(), k->spirv.data(), k->spirv.size());
    return words;
}

// The (set, binding) pairs a SPIR-V module decorates, as set << 8 | binding.
std::vector<std::uint32_t> decorated_pairs(const std::vector<std::uint32_t>& words) {
    std::map<std::uint32_t, std::uint32_t> set, binding;
    for (std::size_t i = 5; i < words.size();) {
        const std::uint32_t count = words[i] >> 16, op = words[i] & 0xFFFFu;
        if (count == 0 || count > words.size() - i) break;
        if (op == 71 && count >= 4) {  // OpDecorate
            if (words[i + 2] == 34) set[words[i + 1]] = words[i + 3];
            if (words[i + 2] == 33) binding[words[i + 1]] = words[i + 3];
        }
        i += count;
    }
    std::vector<std::uint32_t> out;
    for (const auto& [id, s] : set)
        if (binding.count(id)) out.push_back(s << 8 | binding[id]);
    std::sort(out.begin(), out.end());
    return out;
}

// ---- the scene: a quad BLAS placed twice, traced by rt_probe from the origin towards -z -----------------------------

constexpr int kSize = 16;  // the probe image (two 8x8 groups each way); no pixel centre's ray meets a quad's edge

// A quad of the BLAS where an instance put it: x in [x0, x1], y in [y0, y1], on the plane z = -depth.
struct Quad {
    float x0, x1, y0, y1, depth;
};

// The two instances' transforms (row-major 3x4) of the local quad [-1, 1]^2 at z = zLocal, and where they put it.
struct Placement {
    float sx, tx, sy, ty, tz;
};
constexpr Placement kLeft{1.5f, -1.5f, 2.0f, 0.0f, -4.0f};   // x in [-3, 0], y in [-2, 2]
constexpr Placement kRight{3.0f, 3.0f, 4.0f, -2.0f, -8.0f};  // x in [0, 6], y in [-6, 2]

AccelInstance instance_of(const Placement& p, AccelStructure blas, std::uint32_t customIndex) {
    AccelInstance in;
    const float m[12] = {p.sx, 0, 0, p.tx, 0, p.sy, 0, p.ty, 0, 0, 1, p.tz};
    std::memcpy(in.transform, m, sizeof m);
    in.customIndex = customIndex;
    in.blas = blas;
    return in;
}

Quad quad_of(const Placement& p, float zLocal) {
    return {p.tx - p.sx, p.tx + p.sx, p.ty - p.sy, p.ty + p.sy, -(zLocal + p.tz)};
}

// rt_probe's answer for every pixel on the CPU: the distance to the nearest quad, 1000 for a miss.
std::vector<float> cpu_trace(const std::vector<Quad>& quads) {
    std::vector<float> t(std::size_t(kSize) * kSize, 1000.0f);
    for (int y = 0; y < kSize; ++y)
        for (int x = 0; x < kSize; ++x) {
            const double u = (x + 0.5) / kSize * 2.0 - 1.0, v = (y + 0.5) / kSize * 2.0 - 1.0;
            const double len = std::sqrt(u * u + v * v + 1.0);
            for (const Quad& q : quads) {
                const double px = u * q.depth, py = v * q.depth;
                if (px < q.x0 || px > q.x1 || py < q.y0 || py > q.y1) continue;
                float& out = t[std::size_t(y) * kSize + std::size_t(x)];
                out = std::min(out, float(q.depth * len));
            }
        }
    return t;
}

std::string first_difference(const std::vector<float>& got, const std::vector<float>& want) {
    if (got.size() != want.size()) return "got " + std::to_string(got.size()) + " texels";
    int bad = 0;
    std::string first;
    for (std::size_t i = 0; i < got.size(); ++i) {
        if (std::fabs(got[i] - want[i]) <= 1e-3f * std::max(1.0f, want[i])) continue;
        if (bad++ == 0)
            first = "pixel (" + std::to_string(i % kSize) + ", " + std::to_string(i / kSize) + "): t " +
                    std::to_string(got[i]) + ", expected " + std::to_string(want[i]);
    }
    return bad ? std::to_string(bad) + " pixels differ, the first " + first : std::string();
}

struct Rt {
    std::unique_ptr<VulkanDevice> dev;
    Shader shader{};
    Pipeline pipeline{};
    Image image{};
    View view{};
    Buffer vertices{}, indices{}, scratch{};
    std::size_t scratchBytes = 0;
};

std::vector<float> quad_vertices(float z) { return {-1, -1, z, 1, -1, z, 1, 1, z, -1, 1, z}; }

AccelTriangles quad_geometry(const Rt& rt) {
    AccelTriangles g;
    g.vertexBuffer = rt.vertices;
    g.vertexStride = 12;
    g.vertexCount = 4;
    g.indexBuffer = rt.indices;
    g.indexType = IndexType::Uint16;
    g.indexCount = 6;
    return g;
}

ShaderDesc probe_desc() {
    const fa::rt_kernels::RtKernel* k = fa::rt_kernels::find_rt_kernel("rt_probe");
    REQUIRE(k != nullptr);
    ShaderDesc d;
    d.computeFunc.bytecode = Range{k->spirv.data(), k->spirv.size()};
    d.computeFunc.entry = "main";
    d.uniformBlocks[0].stage = ShaderStage::Compute;
    d.uniformBlocks[0].size = 32;
    d.uniformBlocks[0].binding.spirvSet = 0;
    d.uniformBlocks[0].binding.spirvBinding = 2;
    d.views[0].storageImage.stage = ShaderStage::Compute;
    d.views[0].storageImage.accessFormat = PixelFormat::R32F;
    d.views[0].storageImage.writeonly = true;
    d.views[0].storageImage.binding.spirvSet = 0;
    d.views[0].storageImage.binding.spirvBinding = 1;
    d.accelStructures[0].stage = ShaderStage::Compute;
    d.accelStructures[0].binding.spirvSet = 0;
    d.accelStructures[0].binding.spirvBinding = 0;
    d.usesRayQuery = true;
    d.label = "rt_probe";
    return d;
}

// The probe kernel, its target and the quad's buffers on a device that traces rays (null `dev` = skipped).
Rt make_scene(AccelBuildFlags flags = {}) {
    Rt rt;
    rt.dev = make_rt();
    if (!rt.dev) return rt;
    VulkanDevice& dev = *rt.dev;
    rt.shader = dev.make_shader(probe_desc());
    REQUIRE_MESSAGE(dev.state(rt.shader) == ResourceState::Valid, all_errors(dev));
    PipelineDesc pd;
    pd.compute = true;
    pd.shader = rt.shader;
    pd.label = "rt_probe";
    rt.pipeline = dev.make_pipeline(pd);
    REQUIRE_MESSAGE(dev.state(rt.pipeline) == ResourceState::Valid, all_errors(dev));
    ImageDesc id;
    id.width = kSize;
    id.height = kSize;
    id.pixelFormat = PixelFormat::R32F;
    id.usage.storageImage = true;
    id.label = "rt-probe-out";
    rt.image = dev.make_image(id);
    ViewDesc vd;
    vd.storageImage.image = rt.image;
    rt.view = dev.make_view(vd);
    REQUIRE_MESSAGE(dev.state(rt.view) == ResourceState::Valid, all_errors(dev));

    const std::vector<float> v = quad_vertices(0.0f);
    BufferDesc vb;
    vb.size = v.size() * sizeof(float);
    vb.usage.accelBuildInput = true;
    vb.data = Range{v.data(), vb.size};
    vb.label = "rt-quad-vertices";
    rt.vertices = dev.make_buffer(vb);
    const std::uint16_t idx[6] = {0, 1, 2, 0, 2, 3};
    BufferDesc ib;
    ib.size = sizeof idx;
    ib.usage.accelBuildInput = true;
    ib.data = Range{idx, sizeof idx};
    ib.label = "rt-quad-indices";
    rt.indices = dev.make_buffer(ib);
    REQUIRE_MESSAGE(dev.state(rt.vertices) == ResourceState::Valid, all_errors(dev));
    REQUIRE_MESSAGE(dev.state(rt.indices) == ResourceState::Valid, all_errors(dev));

    const AccelTriangles g = quad_geometry(rt);
    auto bs = dev.blas_sizes({&g, 1}, flags);
    REQUIRE_MESSAGE(bs, bs.error().to_string());
    auto ts = dev.tlas_sizes(2, flags);
    REQUIRE_MESSAGE(ts, ts.error().to_string());
    rt.scratchBytes = std::size_t(std::max(
        {bs.value().buildScratch, bs.value().updateScratch, ts.value().buildScratch, ts.value().updateScratch}));
    BufferDesc sd;
    sd.size = rt.scratchBytes;
    sd.usage.accelScratch = true;
    sd.label = "rt-scratch";
    rt.scratch = dev.make_buffer(sd);
    REQUIRE_MESSAGE(dev.state(rt.scratch) == ResourceState::Valid, all_errors(dev));
    return rt;
}

AccelStructure make_accel(VulkanDevice& dev, AccelKind kind, std::uint64_t size, const char* label) {
    AccelStructureDesc d;
    d.kind = kind;
    d.size = size;
    d.label = label;
    auto a = dev.make_accel_structure(d);
    REQUIRE_MESSAGE(a, a.error().to_string());
    CHECK(dev.accel_structure_state(a.value()) == ResourceState::Valid);
    return a.value();
}

AccelStructure make_blas(Rt& rt, const AccelBuildFlags& flags, const char* label) {
    const AccelTriangles g = quad_geometry(rt);
    auto s = rt.dev->blas_sizes({&g, 1}, flags);
    REQUIRE_MESSAGE(s, s.error().to_string());
    return make_accel(*rt.dev, AccelKind::Blas, s.value().structure, label);
}

AccelStructure make_tlas(Rt& rt, std::uint32_t instances, const AccelBuildFlags& flags) {
    auto s = rt.dev->tlas_sizes(instances, flags);
    REQUIRE_MESSAGE(s, s.error().to_string());
    return make_accel(*rt.dev, AccelKind::Tlas, s.value().structure, "rt-tlas");
}

fa::Result<void> build_blas(Rt& rt, CommandList& list, AccelStructure blas, const AccelBuildFlags& flags,
                            bool update = false) {
    const AccelTriangles g = quad_geometry(rt);
    BlasBuild b;
    b.dst = blas;
    b.geometries = {&g, 1};
    b.flags = flags;
    b.update = update;
    b.scratch = rt.scratch;
    return list.build_blas(b);
}

fa::Result<void> build_tlas(Rt& rt, CommandList& list, AccelStructure tlas, const std::vector<AccelInstance>& instances,
                            const AccelBuildFlags& flags = {}, bool update = false) {
    TlasBuild b;
    b.dst = tlas;
    b.instances = instances;
    b.flags = flags;
    b.update = update;
    b.scratch = rt.scratch;
    return list.build_tlas(b);
}

void trace(Rt& rt, CommandList& list, AccelStructure tlas) {
    const float params[8] = {0, 0, 0, 0, float(kSize), float(kSize), 0, 0};
    Bindings b;
    b.views[0] = rt.view;
    b.accelStructures[0] = tlas;
    list.begin_compute_pass("rt-probe");
    list.set_pipeline(rt.pipeline);
    list.set_bindings(b);
    list.set_uniforms(0, Range{params, sizeof params});
    list.dispatch(kSize / 8, kSize / 8, 1);
    list.end_pass();
}

std::vector<float> read_t(Rt& rt) {
    std::vector<std::uint8_t> raw;
    auto r = rt.dev->read_image_region(rt.image, 0, 0, 0, 0, kSize, kSize, raw);
    REQUIRE_MESSAGE(r, r.error().to_string());
    std::vector<float> t(raw.size() / 4);
    std::memcpy(t.data(), raw.data(), t.size() * 4);
    return t;
}

}  // namespace

// ---- without a device -----------------------------------------------------------------------------------------------

TEST_CASE("vulkan rt: the features and limits come from the device's acceleration structure properties") {
    VkPhysicalDeviceAccelerationStructurePropertiesKHR props{};
    props.maxGeometryCount = std::uint64_t(1) << 24;
    props.maxInstanceCount = std::uint64_t(1) << 40;  // more than 32 bits: clamped
    props.maxPrimitiveCount = std::uint64_t(1) << 29;
    props.minAccelerationStructureScratchOffsetAlignment = 128;
    Features f;
    Limits l;
    CHECK(vk::fill_ray_tracing_caps(true, false, props, f, l) == 256);  // never below Device::accel_alignment()
    CHECK(f.rayQuery);
    CHECK(f.accelerationStructure);
    CHECK(f.bufferDeviceAddress);
    CHECK_FALSE(f.rayTracingPipeline);
    CHECK(l.maxAccelInstances == 0xFFFFFFFFu);
    CHECK(l.maxAccelGeometries == (1u << 24));
    CHECK(l.maxAccelPrimitives == (std::uint64_t(1) << 29));
    props.minAccelerationStructureScratchOffsetAlignment = 1024;
    CHECK(vk::fill_ray_tracing_caps(true, true, props, f, l) == 1024);
    CHECK(f.rayTracingPipeline);  // reported when the extension exists, never enabled

    // Without ray tracing everything is off, whatever the properties say (a device that lacks one piece).
    CHECK(vk::fill_ray_tracing_caps(false, true, props, f, l) == 256);
    CHECK_FALSE(f.rayQuery);
    CHECK_FALSE(f.accelerationStructure);
    CHECK_FALSE(f.bufferDeviceAddress);
    CHECK(f.rayTracingPipeline);
    CHECK(l.maxAccelInstances == 0);
    CHECK(l.maxAccelGeometries == 0);
    CHECK(l.maxAccelPrimitives == 0);
}

TEST_CASE("vulkan rt: a ray-query kernel's bindings move into the backend's sets, the binding numbers kept") {
    std::vector<std::uint32_t> words = probe_words();
    // rt_probe (DXC) declares the TLAS on binding 0, the image on 1 and the parameters on 2, all in set 0.
    REQUIRE(decorated_pairs(words) == std::vector<std::uint32_t>{0x000, 0x001, 0x002});
    const std::vector<std::uint32_t> before = words;
    vk::move_descriptor_sets(words, {});
    CHECK(words == before);  // nothing to move: the module is untouched
    vk::move_descriptor_sets(words, {{0x000, 1}, {0x001, 1}, {0x002, 0}, {0x105, 0}});
    CHECK(decorated_pairs(words) == std::vector<std::uint32_t>{0x002, 0x100, 0x101});
    CHECK(words.size() == before.size());  // literals change in place
}

// ---- a device without ray tracing -----------------------------------------------------------------------------------

TEST_CASE("vulkan rt: a device without ray tracing says why and refuses every call with that reason") {
    auto dev = make_vk();
    if (!dev) return;
    std::string why;
    if (dev->ray_tracing_status(&why)) {
        MESSAGE("vulkan rt: this device traces rays; the refusals of one that does not are not run here");
        return;
    }
    CHECK(contains(why, "has no ray tracing: "));  // what it lacks, or the failed vkCreateDevice that turned it off
    CHECK(contains(why, "the vulkan device '"));
    CHECK_FALSE(dev->features().rayQuery);
    CHECK_FALSE(dev->features().accelerationStructure);
    CHECK_FALSE(dev->features().bufferDeviceAddress);
    CHECK(dev->limits().maxAccelInstances == 0);
    CHECK(dev->accel_scratch_alignment() == 256);

    AccelTriangles g;
    g.vertexCount = 3;
    g.vertexStride = 12;
    auto sizes = dev->blas_sizes({&g, 1}, {});
    REQUIRE_FALSE(sizes);
    CHECK(contains(sizes.error().message, "Device::blas_sizes"));
    CHECK(contains(sizes.error().message, why));
    CHECK_FALSE(sizes.error().hint.empty());  // says what to check first
    CHECK_FALSE(dev->tlas_sizes(1, {}));
    AccelStructureDesc ad;
    ad.size = 4096;
    CHECK_FALSE(dev->make_accel_structure(ad));

    BufferDesc bd;
    bd.size = 256;
    bd.usage.accelScratch = true;
    bd.label = "no-rt-scratch";
    CHECK(dev->state(dev->make_buffer(bd)) == ResourceState::Failed);
    CHECK(contains(all_errors(*dev), "usage accelScratch"));

    const Shader s = dev->make_shader(probe_desc());
    CHECK(dev->state(s) == ResourceState::Failed);
    CHECK(contains(all_errors(*dev), "usesRayQuery"));

    CommandList& list = dev->begin_commands("no-rt");
    BlasBuild b;
    auto r = list.build_blas(b);
    check_refusal(r, "CommandList::build_blas");
    check_refusal(list.build_tlas(TlasBuild{}), "CommandList::build_tlas");
    check_refusal(list.query_compacted_size(AccelStructure{}, Buffer{}, 0), "CommandList::query_compacted_size");
    check_refusal(list.copy_accel_structure(AccelStructure{}, AccelStructure{}, AccelCopyMode::Clone),
                  "CommandList::copy_accel_structure");
    submit_and_finish(*dev, list);
    CHECK_MESSAGE(layer_errors(*dev).empty(), layer_errors(*dev));
}

// ---- a device that traces rays --------------------------------------------------------------------------------------

TEST_CASE("vulkan rt: two instances of BLASes built with one scratch buffer trace as the CPU does") {
    Rt rt = make_scene();
    if (!rt.dev) return;
    VulkanDevice& dev = *rt.dev;
    const AccelBuildFlags flags;
    const AccelStructure left = make_blas(rt, flags, "rt-left");
    const AccelStructure right = make_blas(rt, flags, "rt-right");
    const AccelStructure tlas = make_tlas(rt, 2, flags);
    CommandList& list = dev.begin_commands("rt-probe");
    // Both BLASes use the same scratch: the backend puts a barrier between the two builds.
    REQUIRE(build_blas(rt, list, left, flags));
    REQUIRE(build_blas(rt, list, right, flags));
    REQUIRE(build_tlas(rt, list, tlas, {instance_of(kLeft, left, 1), instance_of(kRight, right, 2)}));
    trace(rt, list, tlas);
    submit_and_finish(dev, list);
    const std::string bad = first_difference(read_t(rt), cpu_trace({quad_of(kLeft, 0), quad_of(kRight, 0)}));
    CHECK_MESSAGE(bad.empty(), bad);
    CHECK_MESSAGE(all_errors(dev).empty(), all_errors(dev));
}

TEST_CASE("vulkan rt: a BLAS refit after its vertices moved traces where they went") {
    AccelBuildFlags flags;
    flags.allowUpdate = true;
    Rt rt = make_scene(flags);
    if (!rt.dev) return;
    VulkanDevice& dev = *rt.dev;
    const AccelStructure blas = make_blas(rt, flags, "rt-refit");
    const AccelStructure tlas = make_tlas(rt, 2, {});
    const std::vector<AccelInstance> instances = {instance_of(kLeft, blas, 0), instance_of(kRight, blas, 1)};
    CommandList& first = dev.begin_commands("rt-build");
    REQUIRE(build_blas(rt, first, blas, flags));
    REQUIRE(build_tlas(rt, first, tlas, instances));
    trace(rt, first, tlas);
    submit_and_finish(dev, first);
    std::string bad = first_difference(read_t(rt), cpu_trace({quad_of(kLeft, 0), quad_of(kRight, 0)}));
    CHECK_MESSAGE(bad.empty(), bad);

    // The quad moves one unit away (z = -1): refit the BLAS, rebuild the TLAS that names it, trace again.
    const std::vector<float> moved = quad_vertices(-1.0f);
    CommandList& second = dev.begin_commands("rt-refit");
    BufferWrite w;
    w.buffer = rt.vertices;
    w.data = Range{moved.data(), moved.size() * sizeof(float)};
    second.write_buffer(w);
    auto refit = build_blas(rt, second, blas, flags, true);
    REQUIRE_MESSAGE(refit, refit.error().to_string());
    REQUIRE(build_tlas(rt, second, tlas, instances));
    trace(rt, second, tlas);
    submit_and_finish(dev, second);
    bad = first_difference(read_t(rt), cpu_trace({quad_of(kLeft, -1), quad_of(kRight, -1)}));
    CHECK_MESSAGE(bad.empty(), bad);
    CHECK_MESSAGE(all_errors(dev).empty(), all_errors(dev));
}

TEST_CASE("vulkan rt: a compacted BLAS is no larger and traces as the one it was copied from") {
    AccelBuildFlags flags;
    flags.allowCompaction = true;
    Rt rt = make_scene(flags);
    if (!rt.dev) return;
    VulkanDevice& dev = *rt.dev;
    const AccelTriangles g = quad_geometry(rt);
    auto sizes = dev.blas_sizes({&g, 1}, flags);
    REQUIRE(sizes);
    const AccelStructure blas = make_accel(dev, AccelKind::Blas, sizes.value().structure, "rt-uncompacted");
    BufferDesc qd;
    qd.size = 16;
    qd.usage.storageBuffer = true;
    qd.label = "rt-compacted-size";
    const Buffer sizeBuffer = dev.make_buffer(qd);
    CommandList& first = dev.begin_commands("rt-compaction-query");
    REQUIRE(build_blas(rt, first, blas, flags));
    auto q = first.query_compacted_size(blas, sizeBuffer, 8);
    REQUIRE_MESSAGE(q, q.error().to_string());
    submit_and_finish(dev, first);
    std::vector<std::uint8_t> raw;
    auto r = dev.read_buffer(sizeBuffer, 8, 8, raw);
    REQUIRE_MESSAGE(r, r.error().to_string());
    REQUIRE(raw.size() == 8);
    std::uint64_t compacted = 0;
    std::memcpy(&compacted, raw.data(), 8);
    INFO("compacted " << compacted << " of " << sizes.value().structure << " bytes");
    CHECK(compacted > 0);
    CHECK(compacted <= sizes.value().structure);

    const AccelStructure small = make_accel(dev, AccelKind::Blas, compacted, "rt-compacted");
    const AccelStructure tlas = make_tlas(rt, 2, {});
    CommandList& second = dev.begin_commands("rt-compact");
    auto c = second.copy_accel_structure(blas, small, AccelCopyMode::Compact);
    REQUIRE_MESSAGE(c, c.error().to_string());
    REQUIRE(build_tlas(rt, second, tlas, {instance_of(kLeft, small, 0), instance_of(kRight, small, 1)}));
    dev.destroy_accel_structure(blas);  // the copy holds no reference to it once it ran
    trace(rt, second, tlas);
    submit_and_finish(dev, second);
    const std::string bad = first_difference(read_t(rt), cpu_trace({quad_of(kLeft, 0), quad_of(kRight, 0)}));
    CHECK_MESSAGE(bad.empty(), bad);
    // A compacted structure is not compacted again.
    CommandList& third = dev.begin_commands("rt-compact-again");
    auto again = third.query_compacted_size(small, sizeBuffer, 0);
    check_refusal(again, "allowCompaction");
    submit_and_finish(dev, third);
    CHECK_MESSAGE(layer_errors(dev).empty(), layer_errors(dev));
}

TEST_CASE("vulkan rt: a TLAS rebuilt every frame while the frame before traces it is ordered by the backend") {
    Rt rt = make_scene();
    if (!rt.dev) return;
    VulkanDevice& dev = *rt.dev;
    const AccelStructure blas = make_blas(rt, {}, "rt-frames");
    const AccelStructure tlas = make_tlas(rt, 2, {});
    CommandList& setup = dev.begin_commands("rt-frames-blas");
    REQUIRE(build_blas(rt, setup, blas, {}));
    submit_and_finish(dev, setup);
    // Frames in flight, no wait between them: frame n + 1's build writes the TLAS (and the scratch) frame n's trace
    // and build read (AS_READ in the compute shader, then AS_WRITE in the build: the write-after-read barrier).
    Placement left = kLeft;
    for (int frame = 0; frame < 4; ++frame) {
        left.tz = frame % 2 ? -6.0f : -4.0f;
        CommandList& list = dev.begin_commands("rt-frame");
        auto b = build_tlas(rt, list, tlas, {instance_of(left, blas, 0), instance_of(kRight, blas, 1)});
        REQUIRE_MESSAGE(b, b.error().to_string());
        trace(rt, list, tlas);
        dev.submit(list);
        dev.commit();
    }
    auto idle = dev.wait_idle();
    REQUIRE_MESSAGE(idle, idle.error().to_string());
    const std::string bad = first_difference(read_t(rt), cpu_trace({quad_of(left, 0), quad_of(kRight, 0)}));
    CHECK_MESSAGE(bad.empty(), bad);
    CHECK_MESSAGE(all_errors(dev).empty(), all_errors(dev));
}

TEST_CASE("vulkan rt: a TLAS refit after an instance moved traces the new position") {
    AccelBuildFlags flags;
    flags.allowUpdate = true;
    Rt rt = make_scene(flags);
    if (!rt.dev) return;
    VulkanDevice& dev = *rt.dev;
    const AccelStructure blas = make_blas(rt, {}, "rt-tlas-refit-blas");
    const AccelStructure tlas = make_tlas(rt, 2, flags);
    CommandList& first = dev.begin_commands("rt-tlas-build");
    REQUIRE(build_blas(rt, first, blas, {}));
    REQUIRE(build_tlas(rt, first, tlas, {instance_of(kLeft, blas, 0), instance_of(kRight, blas, 1)}, flags));
    trace(rt, first, tlas);
    submit_and_finish(dev, first);
    std::string bad = first_difference(read_t(rt), cpu_trace({quad_of(kLeft, 0), quad_of(kRight, 0)}));
    CHECK_MESSAGE(bad.empty(), bad);

    // The left instance moves two units away: the TLAS is refitted in place (same count, same flags), no rebuild.
    Placement moved = kLeft;
    moved.tz = -6.0f;
    REQUIRE(quad_of(moved, 0).depth != quad_of(kLeft, 0).depth);  // the trace must differ from the first one
    CommandList& second = dev.begin_commands("rt-tlas-refit");
    auto refit = build_tlas(rt, second, tlas, {instance_of(moved, blas, 0), instance_of(kRight, blas, 1)}, flags, true);
    REQUIRE_MESSAGE(refit, refit.error().to_string());
    trace(rt, second, tlas);
    submit_and_finish(dev, second);
    bad = first_difference(read_t(rt), cpu_trace({quad_of(moved, 0), quad_of(kRight, 0)}));
    CHECK_MESSAGE(bad.empty(), bad);

    // A refit keeps the instance count and needs the flags the TLAS was built with.
    CommandList& refused = dev.begin_commands("rt-tlas-refit-refused");
    check_refusal(build_tlas(rt, refused, tlas, {instance_of(moved, blas, 0)}, flags, true), "keeps the count");
    const AccelStructure fixed = make_tlas(rt, 2, {});
    const std::vector<AccelInstance> two = {instance_of(kLeft, blas, 0), instance_of(kRight, blas, 1)};
    REQUIRE(build_tlas(rt, refused, fixed, two));
    check_refusal(build_tlas(rt, refused, fixed, two, flags, true), "allowUpdate");  // built without it
    submit_and_finish(dev, refused);
    CHECK_MESSAGE(layer_errors(dev).empty(), layer_errors(dev));  // the refusals above are the device's own errors
}

TEST_CASE("vulkan rt: two builds into one TLAS in one list are ordered, and the later one is what traces") {
    // Both builds write the TLAS and its one instance buffer: the second copy of instances waits for the first build's
    // read of that buffer and the second build for the first's write (the synchronization validation reports a missing
    // barrier). Builds into one TLAS from lists recorded on several threads are ordered by the caller's submission.
    Rt rt = make_scene();
    if (!rt.dev) return;
    VulkanDevice& dev = *rt.dev;
    const AccelStructure blas = make_blas(rt, {}, "rt-twice");
    const AccelStructure tlas = make_tlas(rt, 2, {});
    CommandList& setup = dev.begin_commands("rt-twice-blas");
    REQUIRE(build_blas(rt, setup, blas, {}));
    submit_and_finish(dev, setup);
    Placement moved = kLeft;
    moved.tz = -6.0f;
    CommandList& list = dev.begin_commands("rt-twice");
    REQUIRE(build_tlas(rt, list, tlas, {instance_of(kLeft, blas, 0), instance_of(kRight, blas, 1)}));
    REQUIRE(build_tlas(rt, list, tlas, {instance_of(moved, blas, 0), instance_of(kRight, blas, 1)}));
    trace(rt, list, tlas);
    submit_and_finish(dev, list);
    const std::string bad = first_difference(read_t(rt), cpu_trace({quad_of(moved, 0), quad_of(kRight, 0)}));
    CHECK_MESSAGE(bad.empty(), bad);
    CHECK_MESSAGE(layer_errors(dev).empty(), layer_errors(dev));
    CHECK_MESSAGE(all_errors(dev).empty(), all_errors(dev));
}

TEST_CASE("vulkan rt: builds the backend cannot run are refused with teaching errors, and the list goes on") {
    Rt rt = make_scene();
    if (!rt.dev) return;
    VulkanDevice& dev = *rt.dev;
    const AccelStructure blas = make_blas(rt, {}, "rt-errors");
    const AccelStructure tlas = make_tlas(rt, 1, {});
    BufferDesc plain;
    plain.size = 256;
    plain.usage.storageBuffer = true;
    plain.label = "rt-plain";
    const Buffer notInput = dev.make_buffer(plain);
    CommandList& list = dev.begin_commands("rt-errors");

    std::string step = "a TLAS naming a BLAS that was never built";
    INFO("step: " << step);
    auto r = build_tlas(rt, list, tlas, {instance_of(kLeft, blas, 0)});
    check_refusal(r, "was never built");

    step = "a vertex buffer without usage.accelBuildInput";
    AccelTriangles g = quad_geometry(rt);
    g.vertexBuffer = notInput;
    BlasBuild b;
    b.dst = blas;
    b.geometries = {&g, 1};
    b.scratch = rt.scratch;
    r = list.build_blas(b);
    check_refusal(r, "usage.accelBuildInput");

    step = "a refit of a BLAS that was never built";
    r = build_blas(rt, list, blas, {}, true);
    check_refusal(r, "never built");

    step = "a refit of a BLAS built without allowUpdate";
    REQUIRE(build_blas(rt, list, blas, {}));
    AccelBuildFlags update;
    update.allowUpdate = true;
    r = build_blas(rt, list, blas, update, true);
    check_refusal(r, "allowUpdate");

    step = "a scratch offset off the alignment";
    BlasBuild off;
    const AccelTriangles good = quad_geometry(rt);
    off.dst = blas;
    off.geometries = {&good, 1};
    off.scratch = rt.scratch;
    off.scratchOffset = 4;
    r = list.build_blas(off);
    check_refusal(r, "accel_scratch_alignment");

    step = "a build inside a compute pass";
    list.begin_compute_pass("rt-errors-pass");
    r = build_blas(rt, list, blas, {});
    check_refusal(r, "inside a compute pass");
    list.end_pass();

    step = "the list still builds and traces";
    REQUIRE(build_tlas(rt, list, tlas, {instance_of(kLeft, blas, 0)}));
    trace(rt, list, tlas);
    submit_and_finish(dev, list);
    const std::string bad = first_difference(read_t(rt), cpu_trace({quad_of(kLeft, 0)}));
    CHECK_MESSAGE(bad.empty(), bad);
    CHECK_MESSAGE(layer_errors(dev).empty(), layer_errors(dev));
}

#endif  // FA_VULKAN_BACKEND
