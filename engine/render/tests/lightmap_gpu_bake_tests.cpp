// M79-P5b: the GPU lightmap bake (fa/render/lightmap_gpu_bake.h). On a Mac whose GPU traces rays the kernel rt_bake.metal runs for real through the
// SokolDevice: a Cornell box room (one point light, the same scene as the CPU baker's own tests) is baked by the CPU baker and by the GPU tracer,
// and the two images are compared texel by texel (the GPU draws the same random numbers, so what differs is float rounding and the few paths it
// flips); the GPU image is the same bytes twice; a cancel ends it. A machine without a tracing GPU says so and skips. The RecordingDevice tests
// run everywhere: a device without ray tracing is refused with a teaching message, one with it takes the whole call sequence. The D3D12 and Vulkan
// kernels are the same HLSL compiled by DXC; no test of this suite runs them.
#include <doctest.h>

#include <algorithm>
#include <atomic>
#include <chrono>
#include <cmath>
#include <cstdint>
#include <cstring>
#include <memory>
#include <string>
#include <vector>

#include "fa/core/command.h"
#include "fa/render/lightmap_gpu_bake.h"
#include "fa/scene/lightmap_bake.h"
#include "gpu/device.h"
#include "gpu/sokol_device.h"
#include "lightmap_gpu_bake.h"
#include "rt_kernels.h"
#include "test_util.h"

using namespace fa;

namespace {

BakeMesh quad(const char* name, Vec3 o, Vec3 eu, Vec3 ev, Vec3 n, int atlas, float u0, float v0, float u1, float v1,
              std::uint32_t material = 0) {
    BakeMesh m;
    m.name = name;
    m.positions = {o, o + eu, o + eu + ev, o + ev};
    m.normals = {n, n, n, n};
    m.indices = {0, 1, 2, 0, 2, 3};
    m.materials = {material, material};
    m.atlas = atlas;
    if (atlas >= 0) m.lightmapUv = {{u0, v0}, {u1, v0}, {u1, v1}, {u0, v1}};
    return m;
}

// A closed 1 m room, red wall at x = 0, green at x = 1, white elsewhere, a point light near the ceiling; the atlas is 64 x 32, eight tiles of 16 x 16.
BakeScene cornell(int scale = 1) {
    BakeScene sc;
    sc.materials = {{{0.8f, 0.8f, 0.8f}, {}}, {{0.8f, 0.05f, 0.05f}, {}}, {{0.05f, 0.8f, 0.05f}, {}}};
    sc.atlases = {{64 * scale, 32 * scale}};
    auto tile = [](int t, float& u0, float& v0, float& u1, float& v1) {
        u0 = float(t % 4) / 4.0f;
        v0 = float(t / 4) / 2.0f;
        u1 = u0 + 0.25f;
        v1 = v0 + 0.5f;
    };
    float u0, v0, u1, v1;
    tile(0, u0, v0, u1, v1);
    sc.meshes.push_back(quad("back", {0, 0, 0}, {1, 0, 0}, {0, 1, 0}, {0, 0, 1}, 0, u0, v0, u1, v1));
    tile(1, u0, v0, u1, v1);
    sc.meshes.push_back(quad("front", {0, 0, 1}, {1, 0, 0}, {0, 1, 0}, {0, 0, -1}, 0, u0, v0, u1, v1));
    tile(2, u0, v0, u1, v1);
    sc.meshes.push_back(quad("floor", {0, 0, 0}, {1, 0, 0}, {0, 0, 1}, {0, 1, 0}, 0, u0, v0, u1, v1));
    tile(3, u0, v0, u1, v1);
    sc.meshes.push_back(quad("ceiling", {0, 1, 0}, {1, 0, 0}, {0, 0, 1}, {0, -1, 0}, 0, u0, v0, u1, v1));
    tile(4, u0, v0, u1, v1);
    sc.meshes.push_back(quad("left", {0, 0, 0}, {0, 1, 0}, {0, 0, 1}, {1, 0, 0}, 0, u0, v0, u1, v1, 1));
    tile(5, u0, v0, u1, v1);
    sc.meshes.push_back(quad("right", {1, 0, 0}, {0, 1, 0}, {0, 0, 1}, {-1, 0, 0}, 0, u0, v0, u1, v1, 2));
    BakeLight light;
    light.kind = BakeLightKind::Point;
    light.position = {0.5f, 0.9f, 0.5f};
    light.range = 5;
    light.intensity = 4;
    sc.lights = {light};
    return sc;
}

BakeSettings room_settings() {
    BakeSettings s;
    s.samples = 64;
    s.bounces = 2;
    s.shadowSamples = 4;
    s.dilatePasses = 0;
    s.denoiseRadius = 0;
    return s;
}

struct Diff {
    double mean = 0;     // mean over baked texels of |gpu - cpu| per channel
    double meanCpu = 0;  // mean CPU value
    double maxAbs = 0;
    std::size_t texels = 0;
};

Diff compare(const BakeResult& cpu, const BakeResult& gpu) {
    Diff d;
    REQUIRE(cpu.atlases.size() == gpu.atlases.size());
    double sum = 0, sumCpu = 0;
    for (std::size_t a = 0; a < cpu.atlases.size(); ++a) {
        const BakedAtlas& c = cpu.atlases[a];
        const BakedAtlas& g = gpu.atlases[a];
        REQUIRE(c.rgb.size() == g.rgb.size());
        REQUIRE(c.mask == g.mask);
        for (std::size_t i = 0; i < c.mask.size(); ++i) {
            if (c.mask[i] != kBakeBaked) continue;
            ++d.texels;
            for (int ch = 0; ch < 3; ++ch) {
                const double e = std::fabs(double(g.rgb[i * 3 + ch]) - double(c.rgb[i * 3 + ch]));
                sum += e;
                sumCpu += c.rgb[i * 3 + ch];
                d.maxAbs = std::max(d.maxAbs, e);
            }
        }
    }
    if (d.texels > 0) {
        d.mean = sum / double(d.texels * 3);
        d.meanCpu = sumCpu / double(d.texels * 3);
    }
    return d;
}

bool same_bits(const BakeResult& a, const BakeResult& b) {
    if (a.atlases.size() != b.atlases.size()) return false;
    for (std::size_t i = 0; i < a.atlases.size(); ++i)
        if (a.atlases[i].rgb.size() != b.atlases[i].rgb.size() ||
            std::memcmp(a.atlases[i].rgb.data(), b.atlases[i].rgb.data(), a.atlases[i].rgb.size() * sizeof(float)) != 0)
            return false;
    return true;
}

}  // namespace

TEST_CASE("lightmap gpu bake: a device without ray tracing is refused with what to do") {
    auto made = gpu::make_device(gpu::Backend::Recording);
    REQUIRE(made);
    auto tracer = render::make_lightmap_gpu_tracer_on(**made);
    REQUIRE_FALSE(tracer);
    CHECK(tracer.error().message.find("cannot trace rays") != std::string::npos);
    CHECK(tracer.error().hint.find("cpu") != std::string::npos);
}

TEST_CASE("lightmap gpu bake: the kernel is in the table and its description binds what the kernel declares") {
    const rt_kernels::RtKernel* k = rt_kernels::find_rt_kernel("rt_bake");
    REQUIRE(k != nullptr);
    CHECK_FALSE(k->dxil.empty());
    CHECK_FALSE(k->spirv.empty());
    CHECK_FALSE(k->msl.empty());
    for (gpu::Backend b : {gpu::Backend::D3d12, gpu::Backend::Vulkan, gpu::Backend::Metal}) {
        const gpu::ShaderDesc d = render::lightmap_bake_shader_desc(b);
        CHECK(d.compute());
        CHECK(d.usesRayQuery);
        CHECK(d.accelStructures[0].stage == gpu::ShaderStage::Compute);
        CHECK(d.uniformBlocks[0].size == 112);
        CHECK(d.views[render::LightmapBakeBindings::kViewScene].storageBuffer.binding.mslIndex == 8);
        CHECK(d.views[render::LightmapBakeBindings::kViewTexels].storageBuffer.binding.mslIndex == 9);
        CHECK(d.views[render::LightmapBakeBindings::kViewSky].storageBuffer.binding.mslIndex == 10);
    }
    CHECK_FALSE(render::lightmap_bake_shader_desc(gpu::Backend::Gl).compute());
}

TEST_CASE("lightmap gpu bake: a RecordingDevice with ray tracing takes the whole call sequence") {
    gpu::DeviceInit init;
    init.recordingRayTracing = true;
    auto made = gpu::make_device(gpu::Backend::Recording, init);
    REQUIRE(made);
    auto tracer = render::make_lightmap_gpu_tracer_on(**made);
    REQUIRE_MESSAGE(tracer, (tracer ? "" : tracer.error().message));
    BakeScene sc = cornell();
    BakeSettings st = room_settings();
    st.samples = 4;
    // The recording device runs nothing: the atlas comes back from the tracer as zeros, and every call it made was valid (the device checks).
    auto baked = bake_lightmap(sc, st, {}, tracer->get());
    REQUIRE_MESSAGE(baked, (baked ? "" : baked.error().message));
    CHECK(baked->stats.texels > 0);
    CHECK((*tracer)->dispatches() >= 1);
}

TEST_CASE("lightmap gpu bake on Metal: the Cornell room matches the CPU baker, repeats, and cancels") {
#if defined(__APPLE__)
    auto& g = fa::test::gfx();
    if (!g.ok) {
        MESSAGE("skipped: no GPU here (" << g.error << ")");
        return;
    }
    if (gpu::built_sokol_backend() != gpu::Backend::Metal) {
        MESSAGE("skipped: the sokol backend of this build is " << gpu::backend_name(gpu::built_sokol_backend()));
        return;
    }
    auto made = gpu::make_device(gpu::built_sokol_backend());
    REQUIRE(made);
    std::string why;
    if (!(*made)->ray_tracing_status(&why)) {
        MESSAGE("skipped: this GPU or OS cannot trace rays: " << why);
        return;
    }
    auto opened = render::make_lightmap_gpu_tracer_on(**made);
    REQUIRE_MESSAGE(opened, (opened ? "" : opened.error().message));
    render::LightmapGpuTracer& tracer = **opened;
    MESSAGE("GPU bake on " << tracer.device_name());

    const BakeScene sc = cornell();
    const BakeSettings st = room_settings();
    using Clock = std::chrono::steady_clock;
    const auto t0 = Clock::now();
    auto cpu = bake_lightmap(sc, st);
    const auto t1 = Clock::now();
    auto gpuOne = bake_lightmap(sc, st, {}, &tracer);
    const auto t2 = Clock::now();
    auto gpuTwo = bake_lightmap(sc, st, {}, &tracer);
    REQUIRE(cpu);
    REQUIRE_MESSAGE(gpuOne, (gpuOne ? "" : gpuOne.error().message));
    REQUIRE_MESSAGE(gpuTwo, (gpuTwo ? "" : gpuTwo.error().message));
    MESSAGE("CPU " << std::chrono::duration<double, std::milli>(t1 - t0).count() << " ms, GPU "
                   << std::chrono::duration<double, std::milli>(t2 - t1).count() << " ms (first run, kernel compile included)");

    const Diff d = compare(*cpu, *gpuOne);
    MESSAGE("texels " << d.texels << ", mean CPU value " << d.meanCpu << ", mean |error| " << d.mean << ", max |error| " << d.maxAbs);
    REQUIRE(d.texels > 1000);
    CHECK(d.meanCpu > 0.05);  // the room is lit
    // The same random numbers: only float rounding and the rare flipped path differ.
    CHECK(d.mean < 0.005 * d.meanCpu);
    CHECK(d.maxAbs < 0.25 * d.meanCpu);
    CHECK(tracer.dispatches() >= 2);  // the GPU did the work: the CPU path never calls the tracer
    CHECK(same_bits(*gpuOne, *gpuTwo));  // repeats on one GPU and driver

    // A bigger room (eight times the texels in each direction), for the timing and the same bounds.
    {
        const BakeScene bigRoom = cornell(8);
        const auto c0 = Clock::now();
        auto cpuBig = bake_lightmap(bigRoom, st);
        const auto c1 = Clock::now();
        auto gpuBig = bake_lightmap(bigRoom, st, {}, &tracer);
        const auto c2 = Clock::now();
        REQUIRE(cpuBig);
        REQUIRE_MESSAGE(gpuBig, (gpuBig ? "" : gpuBig.error().message));
        const Diff bd = compare(*cpuBig, *gpuBig);
        MESSAGE("big room: " << bd.texels << " texels, CPU " << std::chrono::duration<double, std::milli>(c1 - c0).count() << " ms, GPU "
                             << std::chrono::duration<double, std::milli>(c2 - c1).count() << " ms; mean |error| " << bd.mean
                             << ", max |error| " << bd.maxAbs << " (mean value " << bd.meanCpu << ")");
        CHECK(bd.mean < 0.005 * bd.meanCpu);
        CHECK(bd.maxAbs < 0.25 * bd.meanCpu);
    }

    // A cancel ends the bake with "cancelled", between two dispatches.
    std::atomic<bool> stop{false};
    const CommandCancelScope scope(&stop);
    BakeSettings big = st;
    big.samples = 4096;  // many dispatches
    auto cancelled = bake_lightmap(sc, big, [&](const BakeProgress& p) {
        if (p.phase == BakePhase::Trace && p.done > 0) stop = true;
    }, &tracer);
    CHECK_FALSE(cancelled);
    if (!cancelled) CHECK(cancelled.error().message == "cancelled");
#else
    MESSAGE("skipped: the real GPU test runs on Metal (Apple); D3D12 and Vulkan run the same HLSL, compiled by DXC, and are not run by this suite");
#endif
}
