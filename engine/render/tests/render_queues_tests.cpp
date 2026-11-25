// M77-P10d: the renderer on the queues and threads of D3D12 and Vulkan (docs/design/ARCHITECTURE_RENDERING_QUEUES.md).
// The shadow views are recorded on job threads into up to four lists submitted in a fixed order (RendererDesc::
// multiThreadRecording), the depth-pyramid reduce of GPU occlusion runs on the compute queue (RendererDesc::asyncCompute),
// and neither changes what is drawn:
// - a CommandCapture replays every call into another list exactly as a direct recording makes them;
// - on a RecordingDevice, the Gpu's async compute hands the resources to the compute queue and back in the order the
//   device contract asks, and the graphics queue waits for that work before the first pass that reads it;
// - on a RecordingDevice, the renderer's shadow lists hold the commands of the single list, whatever the job pool;
// - on Vulkan (MoltenVK with a compute queue of another family here, Mesa's lavapipe on the Linux CI job, which has no
//   compute queue: there only the recording on threads runs) and on D3D12 (WARP, Windows only), the picture with both on
//   is the picture with both off, pixel for pixel, and the validation layer reports nothing.
//
// A machine without a Vulkan loader or device says so (MESSAGE) and passes, unless FA_VULKAN_REQUIRE=1 (the Linux CI job).
// The same for D3D12 WARP with FA_D3D12_REQUIRE=1 (the Windows CI job).
#include "test_util.h"

#include <algorithm>
#include <cstdlib>
#include <cstring>
#include <memory>
#include <string>
#include <vector>

#include "command_capture.h"
#include "fa/core/jobs.h"
#include "gpu/recording_device.h"
#include "gpu/sokol_context.h"
#include "render_internal.h"
#include "renderer_test_access.h"
#if defined(FA_RENDER_VULKAN)
#include "gpu/vulkan_device.h"
#endif
#if defined(_WIN32)
#include <stdlib.h>  // _putenv_s

#include "gpu/d3d12_device.h"
#endif

using namespace fa;
using namespace fa::test;

namespace {

bool has(const std::string& s, const std::string& part) { return s.find(part) != std::string::npos; }

std::string joined(const std::vector<std::string>& lines) {
    std::string out;
    for (const std::string& l : lines) out += l + "\n";
    return out;
}

constexpr int kW = 160;
constexpr int kH = 96;

// The occlusion scene of hiz_render_tests.cpp (a wall hides a cube) under a sun of four shadow cascades, a spot light
// with a shadow of its own, and GPU occlusion: five shadow views and a depth pyramid every frame.
struct QueueScene {
    World world;
    QueueScene() {
        Entity cam = make(world, "cam", {0, 2, 12});
        auto& c = world.add<Camera>(cam);
        c.projection = Projection::Perspective;
        c.fov = 60;
        world.settings().ambientLight = Color{0.2f, 0.2f, 0.25f, 1};
        world.settings().occlusionMode = OcclusionMode::Gpu;
        world.settings().shadowCascades = 4;
        auto mesh = [&](const char* name, Vec3 pos, Vec3 scale, Color color) {
            Entity e = make(world, name, pos);
            world.get<Transform>(e)->scale = scale;
            auto& m = world.add<MeshRenderer>(e);
            m.mesh = "cube";
            m.color = color;
        };
        mesh("floor", {0, -0.5f, 0}, {30, 1, 30}, Color::hex(0x808080));
        mesh("wall", {0, 2, 0}, {10, 6, 1}, Color::hex(0xb0a898));
        mesh("hidden", {0, 2, -10}, {2, 2, 2}, Color::hex(0xe03020));
        mesh("side", {6, 1, 4}, {2, 2, 2}, Color::hex(0x2060e0));
        mesh("front", {-2, 0.5f, 7}, {1, 1, 1}, Color::hex(0x20e060));
        Entity sun = make(world, "sun", {0, 5, 0});
        world.get<Transform>(sun)->rotation = {-50, 25, 0};
        auto& l = world.add<Light>(sun);
        l.type = LightType::Directional;
        l.intensity = 1.0f;
        l.castShadows = true;
        Entity spot = make(world, "spot", {-3, 4, 6});
        world.get<Transform>(spot)->rotation = {-60, 0, 0};
        auto& s = world.add<Light>(spot);
        s.type = LightType::Spot;
        s.castShadows = true;
    }
};

// A headless renderer of kW x kH on `backend` with the two switches.
struct QueueRenderer {
    Renderer renderer;
    bool ok = false;
    std::string error;
    QueueRenderer(GpuBackend backend, bool asyncCompute, bool multiThreadRecording) {
        RendererDesc d;
        d.designWidth = kW;
        d.designHeight = kH;
        d.headless = true;
        d.backend = backend;
        d.asyncCompute = asyncCompute;
        d.multiThreadRecording = multiThreadRecording;
        ok = renderer.init(d, gfx().gpu.environment(), &error);
    }
    ~QueueRenderer() { renderer.shutdown(); }
    QueueRenderer(const QueueRenderer&) = delete;
    QueueRenderer& operator=(const QueueRenderer&) = delete;
    gpu::Device* device() { return RendererDeviceAccess::device(renderer); }
};

void draw_frame(Renderer& r, World& world) {
    r.update(world);
    r.begin_frame();
    r.render_world(world, 0.0f);
    r.end_frame();
}

// The last of `frames` frames, read back (the depth pyramid of a frame serves the next one: three frames use it).
[[maybe_unused]] fa::Image draw_frames(Renderer& r, World& world, int frames) {  // unused where neither device exists
    for (int i = 1; i < frames; ++i) draw_frame(r, world);
    draw_frame(r, world);
    fa::Image img;
    std::string err;
    const bool captured = r.capture(img, &err);
    INFO("capture error: " << err);
    REQUIRE(captured);
    return img;
}

// The commands that draw the shadow views, in order, without the passes around them (one pass on one list, or one
// pass per list of the parallel recording) and without the frame index.
std::vector<std::string> shadow_commands(const gpu::RecordingDevice& dev) {
    std::vector<std::string> out;
    bool inShadowPass = false;
    for (const gpu::RecordedCommand& c : dev.commands()) {
        if (c.kind == gpu::CommandKind::BeginPass) {
            inShadowPass = has(c.text, "'shadow'");
            continue;
        }
        if (c.kind == gpu::CommandKind::EndPass) {
            inShadowPass = false;
            continue;
        }
        if (inShadowPass) out.push_back(c.text);
    }
    return out;
}

// A Gpu on a RecordingDevice (gpu_pass_order_tests.cpp's RecordedGpu).
struct RecordedGpu {
    render::Gpu gpu;
    gpu::RecordingDevice* dev = nullptr;
    bool ok = false;
    std::string error;
    RecordedGpu() {
        auto rec = std::make_unique<gpu::RecordingDevice>();
        dev = rec.get();
        ok = gpu.init(1, &error, std::move(rec));
    }
    ~RecordedGpu() { gpu.shutdown(); }
};

#if defined(FA_RENDER_VULKAN)
bool vulkan_required() {
    const char* v = std::getenv("FA_VULKAN_REQUIRE");
    return v && std::strcmp(v, "1") == 0;
}

bool cannot_run_vulkan_here(const std::string& e) {
    return has(e, "no Vulkan loader") || has(e, "no Vulkan device") || has(e, "needs 1.2") ||
           has(e, "VK_ERROR_INITIALIZATION_FAILED");
}

// A Vulkan device with validation (synchronization validation too: a missing barrier or queue transfer is an error)
// and a compute queue wherever the machine has a second queue family (MoltenVK), for the next Renderer::init on Vulkan.
Result<std::unique_ptr<gpu::Device>> make_queue_vulkan_device() {
    gpu::VulkanOptions o;
    o.validation = true;
    o.synchronizationValidation = true;
    o.queues = gpu::VulkanOptions::Queues::OtherFamilies;
    o.init.environment.defaults = gpu::environment_defaults_of(gfx().gpu.environment());
    return gpu::make_vulkan_device(o);
}
#endif

#if defined(_WIN32)
bool d3d12_required() {
    const char* v = std::getenv("FA_D3D12_REQUIRE");
    return v && std::strcmp(v, "1") == 0;
}

struct ScopedEnv {
    const char* name;
    ScopedEnv(const char* n, const char* value) : name(n) { _putenv_s(name, value); }
    ~ScopedEnv() { _putenv_s(name, ""); }
    ScopedEnv(const ScopedEnv&) = delete;
    ScopedEnv& operator=(const ScopedEnv&) = delete;
};
#endif

}  // namespace

TEST_CASE("render queues: a CommandCapture replays every call as the direct recording makes it") {
    gpu::RecordingDevice dev;
    gpu::ImageDesc id;
    id.width = id.height = 16;
    id.usage.colorAttachment = true;
    id.pixelFormat = gpu::PixelFormat::Rgba8;
    id.label = "capture target";
    const gpu::Image image = dev.make_image(id);
    gpu::ViewDesc vd;
    vd.colorAttachment.image = image;
    vd.label = "capture target";
    const gpu::View view = dev.make_view(vd);
    gpu::BufferDesc bd;
    bd.size = 64;
    bd.usage.storageBuffer = true;
    bd.usage.writeTransient = true;
    bd.label = "capture buffer";
    const gpu::Buffer buffer = dev.make_buffer(bd);

    auto record = [&](gpu::CommandList& cl) {
        std::uint8_t bytes[16];
        for (int i = 0; i < 16; ++i) bytes[i] = std::uint8_t(i * 7);
        gpu::BufferWrite w;
        w.data = {bytes, sizeof bytes};
        w.buffer = buffer;
        w.dstOffset = 16;
        w.size = sizeof bytes;
        cl.write_buffer(w);
        std::memset(bytes, 0, sizeof bytes);  // the capture keeps its own copy
        cl.push_debug_group("group");
        gpu::PassDesc p;
        p.label = "captured";
        p.color = view;
        p.colorLoad = gpu::LoadAction::Clear;
        p.clearColor = {0.25f, 0.5f, 0.75f, 1};
        p.format.color = gpu::PixelFormat::Rgba8;
        cl.begin_pass(p);
        cl.set_viewport(1, 2, 8, 9, true);
        cl.set_viewport_f(0.5f, 1.5f, 7.25f, 3.0f, false);
        cl.set_scissor(3, 4, 5, 6, false);
        cl.end_pass();
        cl.pop_debug_group();
    };
    gpu::CommandList& direct = dev.begin_commands("direct");
    record(direct);
    dev.submit(direct);
    const std::size_t half = dev.commands().size();

    render::CommandCapture capture;
    record(capture);
    CHECK(capture.size() > 0);
    CHECK(capture.pass_state() == gpu::PassState::None);
    gpu::CommandList& replayed = dev.begin_commands("direct");
    capture.replay(replayed);
    dev.submit(replayed);
    dev.commit();
    INFO(joined(dev.errors()));
    CHECK(dev.errors().empty());

    REQUIRE(dev.commands().size() > half);
    std::vector<std::string> a, b;
    for (std::size_t i = 0; i < half; ++i) a.push_back(dev.commands()[i].text);
    for (std::size_t i = half; i < dev.commands().size(); ++i)
        if (dev.commands()[i].kind != gpu::CommandKind::Commit) b.push_back(dev.commands()[i].text);
    CHECK(a == b);
    capture.clear();
    CHECK(capture.size() == 0);
}

TEST_CASE("render queues: async compute hands its resources to the compute queue and back, and graphics waits") {
    if (!gfx().ok) {
        MESSAGE("no GPU here (" << gfx().error
                                << "): skipped (the built-in shaders follow the open context's dialect)");
        return;
    }
    RecordedGpu rg;
    REQUIRE_MESSAGE(rg.ok, rg.error);
    rg.gpu.set_queue_options(true, true);
    REQUIRE(rg.gpu.async_compute());
    CHECK(rg.gpu.parallel_recording());
    gpu::Device& device = rg.gpu.device();

    gpu::ImageDesc id;
    id.width = id.height = 16;
    id.usage.colorAttachment = true;
    id.pixelFormat = gpu::PixelFormat::Rgba16F;
    id.label = "prepass";
    const gpu::Image image = device.make_image(id);
    gpu::BufferDesc bd;
    bd.size = 256;
    bd.usage.storageBuffer = true;
    bd.label = "cells";
    const gpu::Buffer cells = device.make_buffer(bd);
    rg.dev->clear_commands();

    gpu::QueueHandoff uses[2];
    uses[0].image = image;
    uses[1].buffer = cells;
    gpu::CommandList& compute = rg.gpu.begin_async_compute("hiz-reduce", uses);
    CHECK(compute.queue() == gpu::QueueKind::Compute);
    compute.push_debug_group("reduce");
    compute.pop_debug_group();
    rg.gpu.end_async_compute(compute, uses, 42);
    CHECK(rg.gpu.compute_pending());
    rg.gpu.wait_compute_for({7});  // another target: nothing to wait for
    CHECK(rg.gpu.compute_pending());
    rg.gpu.wait_compute_for({0, 42});
    CHECK_FALSE(rg.gpu.compute_pending());
    rg.gpu.commit_frame();
    INFO(joined(rg.dev->errors()));
    CHECK(rg.dev->errors().empty());

    // The graphics list hands both over and signals, the compute list waits, runs and hands both back, and the graphics
    // queue waits for the compute queue's token before its next list.
    std::vector<std::string> order;
    for (const gpu::RecordedCommand& c : rg.dev->commands()) {
        const char* q = c.queue == gpu::QueueKind::Compute ? "compute " : "graphics ";
        switch (c.kind) {
            case gpu::CommandKind::Handoff: order.push_back(std::string(q) + "handoff"); break;
            case gpu::CommandKind::Signal: order.push_back(std::string(q) + "signal"); break;
            case gpu::CommandKind::WaitList: order.push_back(std::string(q) + "wait_list"); break;
            case gpu::CommandKind::WaitQueue: order.push_back(std::string(q) + "wait_queue"); break;
            case gpu::CommandKind::PushDebugGroup: order.push_back(std::string(q) + "work"); break;
            default: break;
        }
    }
    const std::vector<std::string> want = {"graphics handoff",  "graphics handoff", "graphics signal",
                                           "compute wait_list", "compute work",     "compute handoff",
                                           "compute handoff",   "compute signal",   "graphics wait_queue"};
    CHECK(order == want);

    // Work nothing waited for: commit_frame makes the graphics queue wait for it.
    rg.dev->clear_commands();
    gpu::CommandList& again = rg.gpu.begin_async_compute("hiz-reduce", uses);
    rg.gpu.end_async_compute(again, uses, 42);
    rg.gpu.commit_frame();
    CHECK_FALSE(rg.gpu.compute_pending());
    int waits = 0;
    for (const gpu::RecordedCommand& c : rg.dev->commands())
        if (c.kind == gpu::CommandKind::WaitQueue && c.queue == gpu::QueueKind::Graphics) ++waits;
    CHECK(waits == 1);
    INFO(joined(rg.dev->errors()));
    CHECK(rg.dev->errors().empty());

    // Turned off, or on a device without a compute queue, there is no async compute.
    rg.gpu.set_queue_options(false, false);
    CHECK_FALSE(rg.gpu.async_compute());
    CHECK_FALSE(rg.gpu.parallel_recording());
    device.destroy_buffer(cells);
    device.destroy_image(image);
}

TEST_CASE("render queues: the shadow lists recorded on job threads hold the commands of the single list") {
    if (!gfx().ok) {
        MESSAGE("no GPU here (" << gfx().error
                                << "): skipped (the built-in shaders follow the open context's dialect)");
        return;
    }
    QueueScene s;
    auto frame_of = [&](bool parallel, std::vector<std::string>& lists) {
        QueueRenderer rec(GpuBackend::Recording, true, parallel);
        REQUIRE_MESSAGE(rec.ok, rec.error);
        auto* dev = dynamic_cast<gpu::RecordingDevice*>(rec.device());
        REQUIRE(dev != nullptr);
        CHECK(rec.renderer.startup_report()["multiThreadRecording"] == parallel);
        draw_frame(rec.renderer, s.world);
        dev->clear_commands();
        draw_frame(rec.renderer, s.world);
        lists.clear();  // the list of each shadow pass
        for (const gpu::RecordedCommand& c : dev->commands())
            if (c.kind == gpu::CommandKind::BeginPass && has(c.text, "'shadow'")) lists.push_back(c.list);
        INFO(joined(dev->errors()));
        CHECK(dev->errors().empty());
        return shadow_commands(*dev);
    };
    std::vector<std::string> singleLists, parallelLists;
    const std::vector<std::string> single = frame_of(false, singleLists);
    REQUIRE(single.size() > 10);
    CHECK(singleLists == std::vector<std::string>{"frame"});  // one pass on the frame's list

    struct Mode {
        const char* name;
        bool start;
        jobs::Settings settings;
    };
    std::vector<Mode> modes{{"stopped", false, {}}, {"inline", true, jobs::Settings::inline_jobs()}};
    if (jobs::threads_supported()) {
        modes.push_back({"2 workers", true, jobs::Settings::threads(2)});
        modes.push_back({"8 workers", true, jobs::Settings::threads(8)});
    }
    for (const Mode& m : modes) {
        CAPTURE(m.name);
        if (m.start) {
            auto r = jobs::start(m.settings);
            REQUIRE_MESSAGE(r.ok(), (r.ok() ? std::string() : r.error().to_string()));
        }
        const std::vector<std::string> parallel = frame_of(true, parallelLists);
        if (m.start) jobs::stop();
        CHECK(parallel == single);
        // Five views in four groups: one pass on each of four lists of their own.
        CHECK(parallelLists == std::vector<std::string>(4, "shadow"));
    }
}

TEST_CASE("render queues: the startup report says whether async compute and multi-thread recording are in use") {
    Gfx& g = gfx();
    if (!g.ok) {
        MESSAGE("no GPU here (" << g.error << "): skipped");
        return;
    }
    // The sokol backend has neither.
    const Json sokol = g.renderer.startup_report();
    CHECK(sokol["asyncCompute"] == false);
    CHECK(sokol["multiThreadRecording"] == false);
    // A RecordingDevice has both; each switch turns its own off.
    {
        QueueRenderer on(GpuBackend::Recording, true, true);
        REQUIRE_MESSAGE(on.ok, on.error);
        CHECK(on.renderer.startup_report()["asyncCompute"] == true);
        CHECK(on.renderer.startup_report()["multiThreadRecording"] == true);
    }
    {
        QueueRenderer off(GpuBackend::Recording, false, true);
        REQUIRE_MESSAGE(off.ok, off.error);
        CHECK(off.renderer.startup_report()["asyncCompute"] == false);
        CHECK(off.renderer.startup_report()["multiThreadRecording"] == true);
    }
}

TEST_CASE("render queues: on Vulkan the picture with async compute and threads is the single-queue picture") {
    Gfx& g = gfx();
    if (!g.ok) {
        MESSAGE("no GPU here (" << g.error << "): skipped");
        return;
    }
#if !defined(FA_RENDER_VULKAN)
    MESSAGE("this build's renderer has no Vulkan (FA_RENDER_VULKAN off): skipped");
#else
    struct Run {
        fa::Image image;
        Json report;
        int reduces = 0;
        std::vector<std::string> errors;
        bool computeQueue = false;
    };
    auto run = [&](bool on, Run& out) -> bool {
        auto made = make_queue_vulkan_device();
        if (!made) {
            if (cannot_run_vulkan_here(made.error().message) && !vulkan_required()) {
                MESSAGE("vulkan: skipped, " << made.error().message);
                return false;
            }
            FAIL("no Vulkan device: " << made.error().to_string());
            return false;
        }
        out.computeQueue = made.value()->features().asyncCompute;
        RendererDeviceAccess::set_next_device(std::move(made.value()));
        QueueRenderer vk(GpuBackend::Vulkan, on, on);
        RendererDeviceAccess::set_next_device(nullptr);
        REQUIRE_MESSAGE(vk.ok, vk.error);
        auto* vulkan = dynamic_cast<gpu::vk::VulkanDevice*>(vk.device());
        REQUIRE(vulkan != nullptr);
        QueueScene s;
        out.image = draw_frames(vk.renderer, s.world, 4);
        out.report = vk.renderer.startup_report();
        out.reduces = RendererTestAccess::hiz_reduces(vk.renderer);
        out.errors = vulkan->errors();
        return true;
    };
    Run off, on;
    if (!run(false, off)) return;
    if (!run(true, on)) return;
    CHECK(off.report["asyncCompute"] == false);
    CHECK(off.report["multiThreadRecording"] == false);
    CHECK(on.report["asyncCompute"] == on.computeQueue);
    CHECK(on.report["multiThreadRecording"] == true);
    if (!on.computeQueue) MESSAGE("this Vulkan device has no compute queue: only the recording on threads ran");
    CHECK(off.reduces >= 1);
    CHECK(on.reduces == off.reduces);
    REQUIRE(on.image.width == off.image.width);
    REQUIRE(on.image.height == off.image.height);
    const ImageDiff d = diff_images(off.image, on.image, 0.0f);
    INFO("differing pixels " << d.differingPixels << ", max " << d.maxError);
    CHECK(d.differingPixels == 0);
    INFO(joined(off.errors) << joined(on.errors));
    CHECK(off.errors.empty());
    CHECK(on.errors.empty());
#endif
}

TEST_CASE("render queues: on D3D12 (WARP) the picture with async compute and threads is the single-queue picture") {
    Gfx& g = gfx();
    if (!g.ok) {
        MESSAGE("no GPU here (" << g.error << "): skipped");
        return;
    }
#if !defined(_WIN32)
    MESSAGE("D3D12 runs on Windows only: skipped");
#else
    const ScopedEnv warp("FA_D3D12_WARP", "1");
    const ScopedEnv debug("FA_D3D12_DEBUG", "1");
    struct Run {
        fa::Image image;
        Json report;
        int reduces = 0;
        std::vector<std::string> errors;
        bool computeQueue = false;
    };
    auto run = [&](bool on, Run& out) -> bool {
        QueueRenderer dx(GpuBackend::D3d12, on, on);
        if (!dx.ok) {
            if (!d3d12_required()) {
                MESSAGE("d3d12: skipped, " << dx.error);
                return false;
            }
            FAIL("the renderer did not start on D3D12 (WARP): " << dx.error);
            return false;
        }
        auto* d3d12 = dynamic_cast<gpu::d3d12::D3d12Device*>(dx.device());
        REQUIRE(d3d12 != nullptr);
        out.computeQueue = d3d12->features().asyncCompute;
        QueueScene s;
        out.image = draw_frames(dx.renderer, s.world, 4);
        out.report = dx.renderer.startup_report();
        out.reduces = RendererTestAccess::hiz_reduces(dx.renderer);
        out.errors = d3d12->errors();
        return true;
    };
    Run off, on;
    if (!run(false, off)) return;
    if (!run(true, on)) return;
    CHECK(off.report["asyncCompute"] == false);
    CHECK(off.report["multiThreadRecording"] == false);
    CHECK(on.report["asyncCompute"] == on.computeQueue);
    CHECK(on.report["multiThreadRecording"] == true);
    CHECK(off.reduces >= 1);
    CHECK(on.reduces == off.reduces);
    REQUIRE(on.image.width == off.image.width);
    REQUIRE(on.image.height == off.image.height);
    const ImageDiff d = diff_images(off.image, on.image, 0.0f);
    INFO("differing pixels " << d.differingPixels << ", max " << d.maxError);
    CHECK(d.differingPixels == 0);
    INFO(joined(off.errors) << joined(on.errors));
    CHECK(off.errors.empty());
    CHECK(on.errors.empty());
#endif
}
