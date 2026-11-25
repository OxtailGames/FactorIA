// M78-P5a: the frame-generation seam (include/fa/render/framegen.h, src/render_framegen.{h,cpp}, src/renderer_framegen.cpp). No vendor SDK is
// involved: the providers are fakes put into the slot table, the clock is the frame times the test feeds, and the device is a RecordingDevice
// that answers a backend and a GPU maker. What is tested is the setting (keys, errors), the choice of the provider, every refusal and its
// sentence, the minimum base frame rate with its hysteresis, the order of the output passes around the HUD, the start and stop of a provider
// across mode changes and a lost device, and (with the real headless GPU) that a frame reaches the provider with the pictures it needs.
// That a real SDK generates frames is for the packages that add one, on a machine with the GPU.
#include "test_util.h"

#include <algorithm>
#include <array>
#include <cstdint>
#include <memory>
#include <string>
#include <vector>

#include "fa/core/json.h"
#include "gpu/recording_device.h"
#include "render_features.h"
#include "render_framegen.h"
#include "renderer_test_access.h"

using namespace fa;
using namespace fa::test;
using render::FrameGenController;
using render::FrameGenMode;
using render::FrameGenSettings;
using render::FrameGenSlot;
using render::FrameGenState;
using render::GpuVendor;

namespace {

// ---- the device ---------------------------------------------------------------------------------------------------------------------

class FDevice : public gpu::RecordingDevice {
public:
    FDevice(gpu::Backend deviceBackend, std::uint32_t pciVendor) : backend_(deviceBackend) {
        info_ = gpu::RecordingDevice::info();
        info_.backend = deviceBackend;
        info_.gpu.vendorId = pciVendor;
        info_.gpu.vendor = gpu::gpu_vendor_from_pci(pciVendor);
    }
    gpu::Backend backend() const override { return backend_; }
    const gpu::DeviceInfo& info() const override { return info_; }

private:
    gpu::Backend backend_;
    gpu::DeviceInfo info_;
};

render::VendorEnv env_of(const FDevice& d, GpuVendor vendor, bool windows = true) {
    render::VendorEnv e;
    e.backend = d.backend();
    e.vendor = vendor;
    e.device = &d;
    e.windows = windows;
    return e;
}

render::FrameGenSwapchain swapchain_of(const FDevice& d) {
    render::FrameGenSwapchain s;
    s.backend = d.backend();
    s.width = 1920;
    s.height = 1080;
    return s;
}

// ---- a fake provider ----------------------------------------------------------------------------------------------------------------

class FakeProvider final : public render::FrameGenProvider {
public:
    explicit FakeProvider(FrameGenSlot s) : slot_(s) {}
    bool available = true;
    std::string probeReason = "fake reason";
    std::string startFails;  // non-empty: start() answers this
    bool dispatchOk = true;
    int probes = 0, starts = 0, stops = 0, dispatches = 0;
    std::uint64_t generated = 0;     // what generated_frames() answers
    std::vector<std::string> calls;  // "start", "configure on", "configure off", "dispatch", "stop"
    render::FrameGenFrame last;  // a copy of the last frame handed over (the pointers are only valid during the call)
    bool lastReset = false;
    bool reversedDepth = false;
    int swapchainChanges = 0;
    render::FrameGenSwapchain startedWith, lastSwapchain;
    std::shared_ptr<gpu::DeviceHook> hook;  // what device_hook() answers

    std::string_view name() const override { return "Fake frame generation"; }
    FrameGenSlot slot() const override { return slot_; }
    std::string_view setup_id() const override { return "fake"; }
    unsigned backends() const override { return ~0u; }
    render::VendorProbe probe(const render::VendorEnv&) override {
        ++probes;
        render::VendorProbe p;
        p.available = available;
        if (!available) p.reason = probeReason;
        return p;
    }
    bool wants_reversed_depth() const override { return reversedDepth; }
    std::shared_ptr<gpu::DeviceHook> device_hook() override { return hook; }
    void swapchain_changed(gpu::Device&, const render::FrameGenSwapchain& sc) override {
        ++swapchainChanges;
        lastSwapchain = sc;
    }
    std::string start(gpu::Device&, const render::FrameGenSwapchain& sc) override {
        ++starts;
        startedWith = sc;
        calls.push_back("start");
        generated = 0;  // a new SDK context counts from 0
        return startFails;
    }
    void configure(bool enabled) override { calls.push_back(enabled ? "configure on" : "configure off"); }
    bool dispatch(render::FrameGenFrame& frame) override {
        ++dispatches;
        calls.push_back("dispatch");
        last = frame;
        lastReset = frame.reset;
        if (!dispatchOk) frame.error = "the fake SDK refused this frame";
        return dispatchOk;
    }
    std::uint64_t generated_frames() override { return generated; }
    void stop(gpu::Device&) override {
        ++stops;
        calls.push_back("stop");
    }

private:
    FrameGenSlot slot_;
};

struct ProviderGuard {
    ProviderGuard(FrameGenSlot s, render::FrameGenProvider* p) : slot_(s) {
        render::set_framegen_provider_for_test(s, p);
    }
    ~ProviderGuard() { render::set_framegen_provider_for_test(slot_, nullptr); }
    ProviderGuard(const ProviderGuard&) = delete;
    ProviderGuard& operator=(const ProviderGuard&) = delete;
    FrameGenSlot slot_;
};

FrameGenSettings settings(FrameGenMode m, int minBaseFps = render::kFrameGenDefaultMinBaseFps) {
    FrameGenSettings s;
    s.mode = m;
    s.minBaseFps = minBaseFps;
    return s;
}

// `n` rendered frames, `intervalMs` apart, on a clock the test owns. A generating provider's counter grows by one per frame, as a real SDK's
// would (one generated frame between two rendered ones).
struct Frames {
    FrameGenController& c;
    FakeProvider& p;
    double t = 1000.0;
    void run(int n, double intervalMs) {
        for (int i = 0; i < n; ++i) {
            t += intervalMs;
            c.begin_frame(t);
            if (c.wants_dispatch()) ++p.generated;
        }
    }
};

}  // namespace

// ---- the setting -------------------------------------------------------------------------------------------------------------------------

TEST_CASE("frame generation settings: names, defaults, parse, errors that teach") {
    CHECK(render::frame_gen_mode_name(FrameGenMode::Dlss) == "dlss");
    CHECK(render::frame_gen_slot_name(FrameGenSlot::Xess) == "xess");
    CHECK(render::frame_gen_to_json(FrameGenSettings{}) == Json::parse(R"({"mode":"off","minBaseFps":60})"));

    const FrameGenSettings base = settings(FrameGenMode::Auto, 45);
    auto ok = render::parse_frame_gen_settings(Json::parse(R"({"mode":"fsr"})"), "t", base);
    REQUIRE(ok.ok());
    CHECK(ok.value().mode == FrameGenMode::Fsr);
    CHECK(ok.value().minBaseFps == 45);  // the keys that are absent keep the base

    auto both = render::parse_frame_gen_settings(Json::parse(R"({"mode":"off","minBaseFps":60})"), "t", base);
    REQUIRE(both.ok());
    CHECK(both.value() == FrameGenSettings{});
    CHECK(render::parse_frame_gen_settings(Json::parse(R"({"minBaseFps":0})"), "t", base).value().minBaseFps == 0);
    CHECK(render::parse_frame_gen_settings(Json::parse(R"({"minBaseFps":1000})"), "t", base).ok());

    auto badMode = render::parse_frame_gen_settings(Json::parse(R"({"mode":"dlls"})"),
                                                    "factoria.json#/render/frameGeneration", base);
    REQUIRE_FALSE(badMode.ok());
    const std::string text = badMode.error().to_string();
    CHECK(text.find("factoria.json#/render/frameGeneration/mode") != std::string::npos);
    CHECK(text.find("dlss") != std::string::npos);  // the did-you-mean

    auto badKey = render::parse_frame_gen_settings(Json::parse(R"({"minBaseFp":30})"), "t", base);
    REQUIRE_FALSE(badKey.ok());
    CHECK(badKey.error().to_string().find("minBaseFps") != std::string::npos);

    // minBaseFps: a whole number in range; a number that does not fit an int is an error, never a wrapped value.
    for (const char* bad :
         {R"({"minBaseFps":-1})", R"({"minBaseFps":1001})", R"({"minBaseFps":59.5})", R"({"minBaseFps":"60"})",
          R"({"minBaseFps":99999999999999})", R"({"minBaseFps":1e30})", R"({"mode":3})", R"("auto")"}) {
        CAPTURE(bad);
        auto r = render::parse_frame_gen_settings(Json::parse(bad), "t", base);
        CHECK_FALSE(r.ok());
    }
    auto range = render::parse_frame_gen_settings(Json::parse(R"({"minBaseFps":5000})"),
                                                  "factoria.json#/render/frameGeneration", base);
    REQUIRE_FALSE(range.ok());
    CHECK(range.error().to_string().find("factoria.json#/render/frameGeneration/minBaseFps") != std::string::npos);
}

TEST_CASE("frame generation settings: the provider a mode names on what the machine can run") {
    render::FrameGenCaps c;
    CHECK(render::effective_frame_generation(settings(FrameGenMode::Off), c) == FrameGenSlot::None);
    CHECK(render::effective_frame_generation(settings(FrameGenMode::Dlss), c) == FrameGenSlot::None);  // not usable
    c.dlss = true;
    CHECK(render::effective_frame_generation(settings(FrameGenMode::Dlss), c) == FrameGenSlot::Dlss);
    CHECK(render::effective_frame_generation(settings(FrameGenMode::Fsr), c) == FrameGenSlot::None);
    // auto: the provider of the GPU's maker only.
    c.fsr = c.xess = true;
    c.gpuVendor = GpuVendor::Nvidia;
    CHECK(render::effective_frame_generation(settings(FrameGenMode::Auto), c) == FrameGenSlot::Dlss);
    c.gpuVendor = GpuVendor::Amd;
    CHECK(render::effective_frame_generation(settings(FrameGenMode::Auto), c) == FrameGenSlot::Fsr);
    c.gpuVendor = GpuVendor::Intel;
    CHECK(render::effective_frame_generation(settings(FrameGenMode::Auto), c) == FrameGenSlot::Xess);
    c.gpuVendor = GpuVendor::Apple;
    CHECK(render::effective_frame_generation(settings(FrameGenMode::Auto), c) == FrameGenSlot::None);
    c.gpuVendor = GpuVendor::Amd;
    c.fsr = false;  // the maker's SDK is not usable: nothing, never another maker's
    CHECK(render::effective_frame_generation(settings(FrameGenMode::Auto), c) == FrameGenSlot::None);
}

// ---- the slot table ----------------------------------------------------------------------------------------------------------------------

TEST_CASE("frame generation providers: the DLSS and XeSS slots have their providers, the FSR slot says which package fills it") {
    // M78-P5b: the DLSS frame generation provider is in its slot (render_framegen_dlss.h); P5d: XeSS (render_framegen_xess.h,
    // framegen_xess_tests.cpp); FSR 3 arrives with its package.
    const render::FrameGenProvider* dlss = render::framegen_provider(FrameGenSlot::Dlss);
    REQUIRE(dlss != nullptr);
    CHECK(dlss->slot() == FrameGenSlot::Dlss);
    CHECK(dlss->setup_id() == "streamline");
    CHECK(render::framegen_provider(FrameGenSlot::Xess) != nullptr);
    for (FrameGenSlot s : {FrameGenSlot::Fsr}) {
        CAPTURE(render::frame_gen_slot_name(s));
        CHECK(render::framegen_provider(s) == nullptr);
        const std::string why = render::framegen_absent_reason(s);
        CHECK(why.find("provider") != std::string::npos);
        CHECK(why.find("yet") != std::string::npos);
    }
    CHECK(std::string(render::framegen_absent_reason(FrameGenSlot::Fsr)).find("FidelityFX") != std::string::npos);
    CHECK(std::string(render::framegen_absent_reason(FrameGenSlot::Xess)).find("XeSS") != std::string::npos);
    CHECK(std::string(render::framegen_slot_setup_id(FrameGenSlot::Dlss)) == "streamline");
    CHECK(std::string(render::framegen_slot_setup_id(FrameGenSlot::Fsr)) == "fidelityfx");
    CHECK(std::string(render::framegen_slot_setup_id(FrameGenSlot::Xess)) == "xess");
    const unsigned d3d12 = 1u << unsigned(gpu::Backend::D3d12), vulkan = 1u << unsigned(gpu::Backend::Vulkan);
    CHECK(render::framegen_slot_backends(FrameGenSlot::Dlss) == (d3d12 | vulkan));
    CHECK(render::framegen_slot_backends(FrameGenSlot::Fsr) == (d3d12 | vulkan));
    CHECK(render::framegen_slot_backends(FrameGenSlot::Xess) == d3d12);
}

TEST_CASE(
    "frame generation providers: a registered provider fills a slot with one call, and a test fake wins over it") {
    CHECK(render::framegen_provider(FrameGenSlot::Fsr) == nullptr);
    auto registered = std::make_shared<FakeProvider>(FrameGenSlot::Fsr);
    render::register_framegen_provider(registered);
    CHECK(render::framegen_provider(FrameGenSlot::Fsr) == registered.get());
    FakeProvider fake(FrameGenSlot::Fsr);
    {
        ProviderGuard guard(FrameGenSlot::Fsr, &fake);
        CHECK(render::framegen_provider(FrameGenSlot::Fsr) == &fake);
    }
    CHECK(render::framegen_provider(FrameGenSlot::Fsr) == registered.get());
    render::clear_registered_framegen_provider_for_test(FrameGenSlot::Fsr);
    CHECK(render::framegen_provider(FrameGenSlot::Fsr) == nullptr);
}

// ---- the controller: the choice and the refusals -------------------------------------------------------------------------------------

TEST_CASE("frame generation controller: off asks nothing; auto starts the provider of the GPU's maker") {
    FakeProvider dlss(FrameGenSlot::Dlss), fsr(FrameGenSlot::Fsr), xess(FrameGenSlot::Xess);
    ProviderGuard g1(FrameGenSlot::Dlss, &dlss), g2(FrameGenSlot::Fsr, &fsr), g3(FrameGenSlot::Xess, &xess);
    const struct {
        std::uint32_t pci;
        GpuVendor vendor;
        FrameGenSlot expect;
    } rows[] = {{0x10de, GpuVendor::Nvidia, FrameGenSlot::Dlss},
                {0x1002, GpuVendor::Amd, FrameGenSlot::Fsr},
                {0x8086, GpuVendor::Intel, FrameGenSlot::Xess}};
    for (const auto& r : rows) {
        CAPTURE(render::gpu_vendor_name(r.vendor));
        FDevice dev(gpu::Backend::D3d12, r.pci);
        FrameGenController c;
        c.attach(&dev, env_of(dev, r.vendor), swapchain_of(dev), true);
        CHECK(c.state() == FrameGenState::Off);
        CHECK(c.provider() == FrameGenSlot::None);
        CHECK(dlss.probes + fsr.probes + xess.probes == 0);  // a game that never turns it on never loads an SDK
        c.set_settings(settings(FrameGenMode::Auto));
        CHECK(c.provider() == r.expect);
        CHECK(c.state() == FrameGenState::Measuring);
        c.detach();
        dlss.probes = fsr.probes = xess.probes = 0;
    }
    CHECK(dlss.starts == 1);
    CHECK(fsr.starts == 1);
    CHECK(xess.starts == 1);
    CHECK(dlss.stops == 1);  // detach gives the SDK its context back
}

TEST_CASE("frame generation controller: every refusal says what is wrong and how to fix it") {
    FDevice nv(gpu::Backend::D3d12, 0x10de);
    SUBCASE("a GPU maker without an SDK (auto)") {
        FDevice apple(gpu::Backend::Metal, 0x106b);
        FrameGenController c;
        c.attach(&apple, env_of(apple, GpuVendor::Apple, false), swapchain_of(apple), true);
        c.set_settings(settings(FrameGenMode::Auto));
        CHECK(c.state() == FrameGenState::Refused);
        CHECK(c.provider() == FrameGenSlot::None);
        CHECK(c.reason().find("Apple") != std::string::npos);
        CHECK(c.reason().find("\"off\"") != std::string::npos);
    }
    SUBCASE("an empty slot names the package that fills it") {
        FrameGenController c;
        c.attach(&nv, env_of(nv, GpuVendor::Nvidia), swapchain_of(nv), true);
        c.set_settings(settings(FrameGenMode::Xess));
        CHECK(c.state() == FrameGenState::Refused);
        CHECK(c.reason().find("XeSS") != std::string::npos);
        CHECK(c.provider_reason(FrameGenSlot::Fsr).find("FidelityFX") != std::string::npos);
    }
    SUBCASE("the provider's probe says no: its sentence is the reason, once") {
        FakeProvider dlss(FrameGenSlot::Dlss);
        dlss.available = false;
        dlss.probeReason = "Streamline is not installed: run `factoria setup streamline`";
        ProviderGuard guard(FrameGenSlot::Dlss, &dlss);
        FrameGenController c;
        c.attach(&nv, env_of(nv, GpuVendor::Nvidia), swapchain_of(nv), true);
        c.set_settings(settings(FrameGenMode::Dlss));
        c.set_settings(settings(FrameGenMode::Auto));
        c.set_settings(settings(FrameGenMode::Dlss));
        CHECK(c.state() == FrameGenState::Refused);
        CHECK(c.reason() == dlss.probeReason);
        CHECK(dlss.starts == 0);
        CHECK(dlss.probes == 1);  // asked once per controller, never per frame or per change
        c.reset_probes();         // the device changed: asked again
        CHECK(dlss.probes == 2);
    }
    SUBCASE("a provider that makes the swapchain needs the start of the run") {
        FakeProvider fsr(FrameGenSlot::Fsr);
        ProviderGuard guard(FrameGenSlot::Fsr, &fsr);
        FrameGenController c;
        c.attach(&nv, env_of(nv, GpuVendor::Nvidia), swapchain_of(nv), false);  // the device was made without the hooks
        c.set_settings(settings(FrameGenMode::Fsr));
        CHECK(c.state() == FrameGenState::Refused);
        CHECK(c.reason().find("restart") != std::string::npos);
        CHECK(c.reason().find("render.frameGeneration.mode") != std::string::npos);
        CHECK(fsr.starts == 0);
    }
    SUBCASE("a provider that cannot start is not asked again") {
        FakeProvider fsr(FrameGenSlot::Fsr);
        fsr.startFails = "the FSR 3 swapchain could not be made";
        ProviderGuard guard(FrameGenSlot::Fsr, &fsr);
        FrameGenController c;
        c.attach(&nv, env_of(nv, GpuVendor::Amd), swapchain_of(nv), true);
        c.set_settings(settings(FrameGenMode::Fsr));
        CHECK(c.state() == FrameGenState::Refused);
        CHECK(c.reason() == fsr.startFails);
        c.set_settings(settings(FrameGenMode::Off));
        c.set_settings(settings(FrameGenMode::Fsr));
        CHECK(fsr.starts == 1);  // fail once, stay off
        CHECK(c.provider_reason(FrameGenSlot::Fsr) == fsr.startFails);
    }
    SUBCASE("the frame has no upscale stage, or no temporal frame") {
        FakeProvider fsr(FrameGenSlot::Fsr);
        ProviderGuard guard(FrameGenSlot::Fsr, &fsr);
        FrameGenController c;
        c.attach(&nv, env_of(nv, GpuVendor::Amd), swapchain_of(nv), true);
        c.set_settings(settings(FrameGenMode::Fsr, 0));
        Frames f{c, fsr};
        f.run(3, 10.0);
        CHECK(c.wants_dispatch());
        c.set_inputs(false, false);
        CHECK(c.state() == FrameGenState::Refused);
        CHECK(c.reason().find("upscale stage") != std::string::npos);
        CHECK(c.reason().find("render scale") != std::string::npos);
        CHECK(fsr.starts == 1);  // the provider stays started: the swapchain is there either way
        f.run(2, 10.0);
        CHECK_FALSE(c.wants_dispatch());
        c.set_inputs(true, false);
        CHECK(c.state() == FrameGenState::Refused);
        CHECK(c.reason().find("temporal") != std::string::npos);
        c.set_inputs(true, true);
        f.run(1, 10.0);
        CHECK(c.wants_dispatch());
        CHECK(c.state() == FrameGenState::Active);
        CHECK(fsr.starts == 1);
    }
}

// ---- the controller: the minimum base frame rate -------------------------------------------------------------------------------------

TEST_CASE("frame generation controller: below minBaseFps generation is off, and it resumes 10% above") {
    FDevice dev(gpu::Backend::D3d12, 0x1002);
    FakeProvider fsr(FrameGenSlot::Fsr);
    ProviderGuard guard(FrameGenSlot::Fsr, &fsr);
    FrameGenController c;
    c.attach(&dev, env_of(dev, GpuVendor::Amd), swapchain_of(dev), true);
    c.set_settings(settings(FrameGenMode::Auto, 50));
    Frames f{c, fsr};
    constexpr int kWindow = FrameGenController::kWindowFrames, kDwell = FrameGenController::kMinDwellFrames;

    // The first frames only measure.
    f.run(kWindow - 1, 10.0);
    CHECK(c.state() == FrameGenState::Measuring);
    CHECK_FALSE(c.wants_dispatch());
    CHECK(c.report().baseFps == 0.0);
    f.run(2, 10.0);  // 100 fps, a full window
    CHECK(c.state() == FrameGenState::Active);
    CHECK(c.wants_dispatch());
    CHECK(c.report().baseFps == doctest::Approx(100.0));
    CHECK(fsr.calls.back() == "configure on");

    // The rate drops to 40 fps: not at once (a minimum dwell between two switches), then off.
    f.run(kWindow + 5, 25.0);
    CHECK(c.state() == FrameGenState::Active);
    f.run(kDwell, 25.0);
    CHECK(c.state() == FrameGenState::Paused);
    CHECK_FALSE(c.wants_dispatch());
    CHECK(c.report().baseFps == doctest::Approx(40.0));
    CHECK(c.reason().find("minBaseFps (50)") != std::string::npos);
    CHECK(c.reason().find("55 fps") != std::string::npos);  // where it resumes
    CHECK(fsr.calls.back() == "configure off");

    // 52 fps is above the limit but not above the margin: still off. 60 fps resumes.
    f.run(kWindow + kDwell, 1000.0 / 52.0);
    CHECK(c.state() == FrameGenState::Paused);
    f.run(kWindow + 2, 1000.0 / 60.0);
    CHECK(c.state() == FrameGenState::Active);
    CHECK(fsr.calls.back() == "configure on");

    // A rate that hovers at the limit does not flap: no more than one switch per dwell.
    const std::size_t before = fsr.calls.size();
    for (int i = 0; i < 4 * kDwell; ++i) f.run(1, (i / 7) % 2 == 0 ? 19.0 : 21.0);  // about 48 to 52 fps
    int switches = 0;
    for (std::size_t i = before; i < fsr.calls.size(); ++i) switches += fsr.calls[i].rfind("configure", 0) == 0 ? 1 : 0;
    CHECK(switches <= 4);
}

TEST_CASE("frame generation controller: minBaseFps 0 never switches off, and the report counts rendered and generated "
          "frames") {
    FDevice dev(gpu::Backend::Vulkan, 0x1002);
    FakeProvider fsr(FrameGenSlot::Fsr);
    ProviderGuard guard(FrameGenSlot::Fsr, &fsr);
    FrameGenController c;
    c.attach(&dev, env_of(dev, GpuVendor::Amd), swapchain_of(dev), true);
    c.set_settings(settings(FrameGenMode::Fsr, 0));
    Frames f{c, fsr};
    f.run(1, 200.0);
    CHECK(c.state() == FrameGenState::Active);  // from the first frame, even at 5 fps
    f.run(100, 200.0);
    CHECK(c.state() == FrameGenState::Active);
    const render::FrameGenReport r = c.report();
    CHECK(r.provider == FrameGenSlot::Fsr);
    CHECK(r.generating);
    CHECK(r.renderedFrames == 101);
    CHECK(r.generatedFrames >= 99);
    CHECK(r.baseFps == doctest::Approx(5.0));
    CHECK(r.presentedFps == doctest::Approx(10.0).epsilon(0.05));  // one generated frame per rendered one
    CHECK(r.reason.empty());
    c.reset_stats();
    CHECK(c.report().renderedFrames == 0);
    CHECK(c.report().generatedFrames == 0);
}

TEST_CASE("frame generation controller: a frame the provider refuses is reported and the next one resets") {
    FDevice dev(gpu::Backend::D3d12, 0x10de);
    FakeProvider dlss(FrameGenSlot::Dlss);
    ProviderGuard guard(FrameGenSlot::Dlss, &dlss);
    FrameGenController c;
    c.attach(&dev, env_of(dev, GpuVendor::Nvidia), swapchain_of(dev), true);
    c.set_settings(settings(FrameGenMode::Dlss, 0));
    Frames f{c, dlss};
    f.run(2, 10.0);
    const auto dispatch = [&c] {  // a frame of its own each time: the controller sets its `reset`
        render::FrameGenFrame frame;
        return c.dispatch(frame);
    };
    CHECK(dispatch());
    CHECK(dlss.lastReset);  // the first frame has no history
    CHECK(dispatch());
    CHECK_FALSE(dlss.lastReset);
    dlss.dispatchOk = false;
    CHECK_FALSE(dispatch());
    CHECK(c.reason() == "the fake SDK refused this frame");
    dlss.dispatchOk = true;
    CHECK(dispatch());
    CHECK(dlss.lastReset);
    CHECK(c.reason().empty());
    c.note_skipped("the depth image could not be made");
    CHECK(c.reason().find("depth image") != std::string::npos);
    CHECK(dispatch());
    CHECK(dlss.lastReset);
    // A camera cut is the frame's own (FrameGenFrame::reset, the temporal upscaler's history); a change of the output size resets too.
    const auto sized = [&c](int w, int h, bool cut = false) {
        render::FrameGenFrame frame;
        frame.outW = w;
        frame.outH = h;
        frame.reset = cut;
        return c.dispatch(frame);
    };
    CHECK(sized(1280, 720));
    CHECK(dlss.lastReset);  // the first size the provider is given
    CHECK(sized(1280, 720));
    CHECK_FALSE(dlss.lastReset);
    CHECK(sized(1920, 1080));
    CHECK(dlss.lastReset);
    CHECK(sized(1920, 1080));
    CHECK_FALSE(dlss.lastReset);
    CHECK(sized(1920, 1080, true));
    CHECK(dlss.lastReset);
}

TEST_CASE("frame generation controller: a game that starts below minBaseFps is paused, not measuring for ever") {
    FDevice dev(gpu::Backend::D3d12, 0x10de);
    FakeProvider dlss(FrameGenSlot::Dlss);
    ProviderGuard guard(FrameGenSlot::Dlss, &dlss);
    FrameGenController c;
    c.attach(&dev, env_of(dev, GpuVendor::Nvidia), swapchain_of(dev), true);
    c.set_settings(settings(FrameGenMode::Dlss, 60));
    Frames f{c, dlss};
    f.run(FrameGenController::kWindowFrames - 5, 25.0);  // 40 fps, the window is not full yet
    CHECK(c.state() == FrameGenState::Measuring);
    f.run(10, 25.0);
    CHECK(c.state() == FrameGenState::Paused);
    CHECK_FALSE(c.wants_dispatch());
    CHECK(c.reason().find("minBaseFps (60)") != std::string::npos);
    CHECK(c.reason().find("66 fps") != std::string::npos);  // with the margin, as after a pause
    // 62 fps is above the limit and below the margin: still paused; 70 fps resumes.
    f.run(FrameGenController::kWindowFrames + FrameGenController::kMinDwellFrames, 1000.0 / 62.0);
    CHECK(c.state() == FrameGenState::Paused);
    f.run(FrameGenController::kWindowFrames + 2, 1000.0 / 70.0);
    CHECK(c.state() == FrameGenState::Active);

    // The same after a refusal: a rate that was never measured under the limit while nothing could run.
    FrameGenController c2;
    c2.attach(&dev, env_of(dev, GpuVendor::Nvidia), swapchain_of(dev), true);
    c2.set_settings(settings(FrameGenMode::Dlss, 60));
    c2.set_inputs(false, false);  // the upscale stage went off: refused
    Frames f2{c2, dlss};
    f2.run(FrameGenController::kWindowFrames + 5, 25.0);
    CHECK(c2.state() == FrameGenState::Refused);
    c2.set_inputs(true, true);
    f2.run(2, 25.0);
    CHECK(c2.state() == FrameGenState::Paused);
}

TEST_CASE("frame generation controller: a new swapchain is told to the provider and resets the next frame") {
    FDevice dev(gpu::Backend::D3d12, 0x10de);
    FakeProvider dlss(FrameGenSlot::Dlss);
    ProviderGuard guard(FrameGenSlot::Dlss, &dlss);
    FrameGenController c;
    c.attach(&dev, env_of(dev, GpuVendor::Nvidia), swapchain_of(dev), true);
    c.set_swapchain(swapchain_of(dev));  // nothing runs, the same size: nothing is told
    c.set_settings(settings(FrameGenMode::Dlss, 0));
    CHECK(dlss.swapchainChanges == 0);
    CHECK(dlss.startedWith.width == 1920);
    Frames f{c, dlss};
    f.run(2, 10.0);
    render::FrameGenFrame frame;
    CHECK(c.dispatch(frame));
    frame = render::FrameGenFrame{};
    CHECK(c.dispatch(frame));
    CHECK_FALSE(dlss.lastReset);

    render::FrameGenSwapchain sc = swapchain_of(dev);
    c.set_swapchain(sc);  // the same: nothing
    CHECK(dlss.swapchainChanges == 0);
    sc.width = 2560;
    sc.height = 1440;
    c.set_swapchain(sc);
    CHECK(dlss.swapchainChanges == 1);
    CHECK(dlss.lastSwapchain.width == 2560);
    frame = render::FrameGenFrame{};
    CHECK(c.dispatch(frame));
    CHECK(dlss.lastReset);
    sc.width = sc.height = 0;  // the window went
    c.set_swapchain(sc);
    CHECK(dlss.swapchainChanges == 2);
    CHECK(dlss.lastSwapchain.width == 0);
}

TEST_CASE("frame generation controller: the depth the provider asks for") {
    FDevice dev(gpu::Backend::Vulkan, 0x1002);
    FakeProvider fsr(FrameGenSlot::Fsr);
    ProviderGuard guard(FrameGenSlot::Fsr, &fsr);
    FrameGenController c;
    c.attach(&dev, env_of(dev, GpuVendor::Amd), swapchain_of(dev), true);
    CHECK_FALSE(c.wants_reversed_depth());  // nothing runs
    c.set_settings(settings(FrameGenMode::Fsr, 0));
    CHECK_FALSE(c.wants_reversed_depth());
    fsr.reversedDepth = true;
    CHECK(c.wants_reversed_depth());
}

// ---- the controller: start and stop ------------------------------------------------------------------------------------------------

TEST_CASE("frame generation controller: the provider starts and stops with the mode, and with a lost device") {
    FDevice dev(gpu::Backend::D3d12, 0x10de);
    FakeProvider dlss(FrameGenSlot::Dlss), fsr(FrameGenSlot::Fsr);
    ProviderGuard g1(FrameGenSlot::Dlss, &dlss), g2(FrameGenSlot::Fsr, &fsr);
    FrameGenController c;
    c.attach(&dev, env_of(dev, GpuVendor::Nvidia), swapchain_of(dev), true);
    CHECK(dlss.calls.empty());

    c.set_settings(settings(FrameGenMode::Dlss));
    CHECK(dlss.calls == std::vector<std::string>{"start"});
    c.set_settings(settings(FrameGenMode::Auto));  // the same provider: not restarted
    CHECK(dlss.starts == 1);
    c.set_settings(settings(FrameGenMode::Auto, 30));  // minBaseFps only: not restarted
    CHECK(dlss.starts == 1);

    c.set_settings(settings(FrameGenMode::Fsr, 30));  // another provider: the first is given its context back first
    CHECK(dlss.stops == 1);
    CHECK(fsr.starts == 1);
    CHECK(c.provider() == FrameGenSlot::Fsr);

    c.set_settings(settings(FrameGenMode::Off, 30));
    CHECK(fsr.stops == 1);
    CHECK(fsr.calls.back() == "stop");
    CHECK(c.state() == FrameGenState::Off);
    CHECK(c.provider() == FrameGenSlot::None);

    c.set_settings(settings(FrameGenMode::Fsr, 30));  // on again: a new start
    CHECK(fsr.starts == 2);

    // The device is lost (or the renderer shuts down): the SDK is told once, and nothing is left running.
    c.detach();
    CHECK(fsr.stops == 2);
    CHECK_FALSE(c.attached());
    CHECK(c.state() == FrameGenState::Off);
    c.begin_frame(1.0);  // harmless
    c.set_settings(settings(FrameGenMode::Fsr, 30));
    CHECK(fsr.starts == 2);  // no device: nothing starts

    // A new device (a recreated renderer) starts the provider again, and asks the SDK again.
    FDevice dev2(gpu::Backend::Vulkan, 0x10de);
    const int probesBefore = fsr.probes;
    c.attach(&dev2, env_of(dev2, GpuVendor::Nvidia), swapchain_of(dev2), true);
    CHECK(c.provider() == FrameGenSlot::Fsr);  // the setting is kept across the device
    CHECK(fsr.starts == 3);
    CHECK(fsr.probes == probesBefore + 1);
}

// ---- the output passes -------------------------------------------------------------------------------------------------------------------

TEST_CASE("frame generation: the plan of the output passes (the order a frame runs is checked on the renderer)") {
    const render::FrameGenPassPlan hud = render::plan_framegen_passes(true, true);
    CHECK(hud.dispatch);
    CHECK(hud.copyHudless);
    const render::FrameGenPassPlan bare = render::plan_framegen_passes(true, false);
    CHECK(bare.dispatch);
    CHECK_FALSE(bare.copyHudless);
    const render::FrameGenPassPlan off = render::plan_framegen_passes(false, true);
    CHECK_FALSE(off.dispatch);
    CHECK_FALSE(off.copyHudless);
}

// ---- render.supports -----------------------------------------------------------------------------------------------------------------------

TEST_CASE("frame generation: render.supports rows") {
    FDevice dev(gpu::Backend::D3d12, 0x10de);
    render::FeatureEnv env = render::feature_env_from_device(dev);
    const int dlss = render::find_feature("dlssFrameGen");
    const int fsr = render::find_feature("fsrFrameGen");
    const int xess = render::find_feature("xessFrameGen");
    REQUIRE(dlss >= 0);
    REQUIRE(fsr >= 0);
    REQUIRE(xess >= 0);
    std::string why;
    CHECK_FALSE(render::feature_supported(env, dlss, &why));  // not asked
    std::array<render::VendorProbe, 3> answers;
    answers[1].available = true;
    answers[2].reason = "XeSS frame generation needs an Intel Arc GPU";
    render::set_framegen_env(env, answers);
    CHECK(render::feature_supported(env, fsr, &why));
    CHECK_FALSE(render::feature_supported(env, xess, &why));
    CHECK(why.find("Intel Arc") != std::string::npos);
    CHECK_FALSE(render::feature_supported(env, dlss, &why));
    CHECK_FALSE(why.empty());

    const Json report = render::feature_report(env, "D3D12");
    bool found = false;
    for (const Json& f : report["features"]) {
        if (f["name"] != "dlssFrameGen") continue;
        found = true;
        CHECK(f["backends"]["D3D12"] == true);
        CHECK(f["backends"]["Vulkan"] == true);
        CHECK(f["backends"]["Metal"] == false);
    }
    CHECK(found);
}

// ---- the renderer ----------------------------------------------------------------------------------------------------------------------

namespace {

constexpr int kOutW = 320, kOutH = 180;

struct Own {
    Gfx& g;
    Renderer r;
    bool ok = false;
    std::string error;
    explicit Own(Gfx& gx) : g(gx) {
        RendererDesc d;
        d.designWidth = kOutW;
        d.designHeight = kOutH;
        d.sampleCount = 1;
        d.headless = true;
        d.adoptContext = true;
        ok = r.init(d, g.gpu.environment(), &error);
    }
    ~Own() { r.shutdown(); }
    Own(const Own&) = delete;
    Own& operator=(const Own&) = delete;
    void frame(World& w, int n = 1) {
        for (int i = 0; i < n; ++i) {
            w.advance_clock(1.0 / 60.0);
            r.begin_frame();
            r.render_world(w, 1.0f / 60.0f);
            r.end_frame();
            g.gpu.end_frame();
        }
    }
    void temporal(float scale = 0.5f) {
        r.set_render_scale(scale);
        r.set_upscale_stage(true);
        render::UpscalerSettings u;
        u.mode = render::UpscalerMode::Temporal;
        u.quality = render::UpscalerQuality::Performance;
        r.set_upscaler(u);
    }
};

Entity box_scene(World& w, bool hud, Color boxColor = Color::white()) {
    const Entity cam = make(w, "cam", {0, 0, 10});
    auto& c = w.add<Camera>(cam);
    c.projection = Projection::Perspective;
    c.fov = 60.0f;
    c.clearColor = Color{0, 0, 0, 1};
    w.settings().skyColor = w.settings().horizonColor = Color{0, 0, 0, 1};
    const Entity box = make(w, "box", {0, 0, 0});
    w.get<Transform>(box)->scale = {3.0f, 3.0f, 3.0f};
    auto& m = w.add<MeshRenderer>(box);
    m.mesh = "cube";
    m.color = boxColor;
    m.unlit = true;
    if (hud) {
        Entity e = make(w, "hud", {10, 10, 0});
        auto& t = w.add<Text>(e);
        t.text = "HHHH";
        t.fontSize = 20;
        t.space = RenderSpace::Screen;
        t.pivot = {0, 1};
    }
    return cam;
}

}  // namespace

TEST_CASE(
    "frame generation renderer: a temporal frame with a HUD reaches the provider with the picture before the HUD") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    FakeProvider fsr(FrameGenSlot::Fsr);
    ProviderGuard guard(FrameGenSlot::Fsr, &fsr);
    Own own(g);
    REQUIRE_MESSAGE(own.ok, own.error);
    RendererTestAccess::framegen_assume_hooked(own.r);  // a headless renderer has no window swapchain for a hook
    World w;
    box_scene(w, true);
    own.temporal();
    own.r.set_frame_generation(settings(FrameGenMode::Fsr, 0));
    CHECK(own.r.effective_frame_generation() == FrameGenSlot::Fsr);
    CHECK(fsr.starts == 1);
    own.frame(w, 6);

    REQUIRE(fsr.dispatches >= 3);
    const render::FrameGenFrame& f = fsr.last;
    CHECK(f.hudDrawn);
    CHECK(f.hudless.valid());
    CHECK(f.presented.valid());
    CHECK(f.hudless != f.presented);  // the copy before the items, and the picture with them
    CHECK(f.depth.valid());
    CHECK(f.motion.valid());
    CHECK(f.renderW == kOutW / 2);
    CHECK(f.renderH == kOutH / 2);
    CHECK(f.outW == kOutW);
    CHECK(f.outH == kOutH);
    CHECK(f.frameId > 0);
    CHECK(f.proj[0] > 0.0f);
    CHECK(f.cameraFovY == doctest::Approx(1.0472f).epsilon(0.02));  // 60 degrees
    CHECK(RendererTestAccess::hudless_target_alive(own.r));
    const std::vector<std::string> order = RendererTestAccess::output_passes(own.r);
    CHECK(order == std::vector<std::string>{"upscale", "framegen-hudless", "hud-over-upscale", "framegen"});

    const Json report = own.r.frame_generation_report();
    CHECK(report["provider"] == "fsr");
    CHECK(report["renderedFrames"].get<int>() >= 6);
    const Json status = own.r.frame_generation_status();
    CHECK(status["mode"] == "fsr");
    CHECK(status["provider"] == "fsr");
    CHECK(status["modes"]["fsr"]["available"] == true);
    CHECK(status["modes"]["dlss"]["available"] == false);

    // Off: the provider is given its context back and no frame reaches it.
    const int before = fsr.dispatches;
    own.r.set_frame_generation(settings(FrameGenMode::Off));
    CHECK(fsr.stops == 1);
    own.frame(w, 3);
    CHECK(fsr.dispatches == before);
    CHECK(RendererTestAccess::output_passes(own.r) == std::vector<std::string>{"upscale", "hud-over-upscale"});
}

TEST_CASE("frame generation renderer: without a HUD the picture is its own hudless one, and without the temporal "
          "upscaler nothing is dispatched") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    FakeProvider xess(FrameGenSlot::Xess);
    ProviderGuard guard(FrameGenSlot::Xess, &xess);
    Own own(g);
    REQUIRE_MESSAGE(own.ok, own.error);
    RendererTestAccess::framegen_assume_hooked(own.r);
    World w;
    box_scene(w, false);
    own.r.set_frame_generation(settings(FrameGenMode::Xess, 0));
    own.frame(w, 3);  // render scale 1: no upscale stage
    CHECK(xess.dispatches == 0);
    const Json status = own.r.frame_generation_status();
    CHECK(status["state"] == "refused");
    CHECK(status["reason"].get<std::string>().find("upscale stage") != std::string::npos);

    own.temporal();
    own.frame(w, 6);
    REQUIRE(xess.dispatches >= 3);
    CHECK_FALSE(xess.last.hudDrawn);
    CHECK(xess.last.hudless == xess.last.presented);
    CHECK(RendererTestAccess::output_passes(own.r) == std::vector<std::string>{"upscale", "framegen"});
    CHECK_FALSE(RendererTestAccess::hudless_target_alive(own.r));
    CHECK(own.r.frame_generation_status()["state"] == "active");
}

TEST_CASE("frame generation renderer: a mode with no provider in this build is refused with the reason, and the frames "
          "draw") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    Own own(g);
    REQUIRE_MESSAGE(own.ok, own.error);
    World w;
    box_scene(w, true);
    own.temporal();
    own.r.set_frame_generation(settings(FrameGenMode::Xess));
    own.frame(w, 3);
    CHECK(own.r.effective_frame_generation() == FrameGenSlot::None);
    const Json status = own.r.frame_generation_status();
    CHECK(status["state"] == "refused");
    CHECK(status["reason"].get<std::string>().find("XeSS") != std::string::npos);
    CHECK(status["modes"]["xess"]["setupId"] == "xess");
    CHECK(RendererTestAccess::output_passes(own.r) == std::vector<std::string>{"upscale", "hud-over-upscale"});
    Image img;
    std::string err;
    REQUIRE_MESSAGE(own.r.capture(img, &err), err);
    CHECK(img.width == kOutW);
    CHECK(own.r.supports("fsrFrameGen") == false);
}

TEST_CASE(
    "frame generation renderer: with a colour filter both images the provider gets are graded like the picture shown") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    FakeProvider fsr(FrameGenSlot::Fsr);
    ProviderGuard guard(FrameGenSlot::Fsr, &fsr);
    Own own(g);
    REQUIRE_MESSAGE(own.ok, own.error);
    RendererTestAccess::framegen_assume_hooked(own.r);
    World w;
    const Entity cam = box_scene(w, true, Color{1, 0, 0, 1});  // a red box: a greyscale filter shows in every channel
    set_color_filter(w, cam, ColorFilter::Greyscale);
    own.temporal();
    own.r.set_frame_generation(settings(FrameGenMode::Fsr, 0));
    own.frame(w, 6);

    REQUIRE(fsr.dispatches >= 3);
    // The real order of the frame: the copy before the items, the filter after them, the dispatch after the filter.
    CHECK(RendererTestAccess::output_passes(own.r) == std::vector<std::string>{"upscale", "framegen-hudless",
                                                                               "hud-over-upscale",
                                                                               "output-color-filter", "framegen"});
    const render::FrameGenFrame& f = fsr.last;
    CHECK(f.hudDrawn);
    // `presented` is exactly the image the swapchain shows (the filter's output), `hudless` the graded copy.
    CHECK(f.presented == RendererTestAccess::filtered_output_image(own.r));
    CHECK(f.hudless == RendererTestAccess::hudless_image(own.r));
    CHECK(f.hudless.valid());
    CHECK(f.hudless != f.presented);

    // What those images hold: no red left in the copy (it is grey), and the same grey as the picture shown.
    std::vector<std::uint8_t> copy;
    int cw = 0, ch = 0;
    REQUIRE(RendererTestAccess::read_hudless(own.r, copy, cw, ch));
    REQUIRE(cw == kOutW);
    REQUIRE(ch == kOutH);
    Image shown;
    std::string err;
    REQUIRE_MESSAGE(own.r.capture(shown, &err), err);
    const std::size_t at = (std::size_t(kOutH / 2) * kOutW + kOutW / 2) * 4;
    const int r = copy[at], gr = copy[at + 1], b = copy[at + 2];
    CHECK(r > 20);  // the box is there
    CHECK(std::abs(r - gr) <= 4);
    CHECK(std::abs(gr - b) <= 4);
    const Color px = shown.pixel(kOutW / 2, kOutH / 2);
    CHECK(std::abs(px.r * 255.0f - float(r)) <= 6.0f);
    CHECK(std::abs(px.g * 255.0f - float(gr)) <= 6.0f);
    CHECK(std::abs(px.b * 255.0f - float(b)) <= 6.0f);

    // No filter: the old order, and the picture shown is the output image itself.
    set_color_filter(w, cam, ColorFilter::None);
    own.frame(w, 4);
    CHECK(RendererTestAccess::output_passes(own.r) ==
          std::vector<std::string>{"upscale", "framegen-hudless", "hud-over-upscale", "framegen"});
    CHECK(fsr.last.presented != fsr.last.hudless);
    CHECK(fsr.last.presented != RendererTestAccess::filtered_output_image(own.r));
}

// ---- the device hook ------------------------------------------------------------------------------------------------------------------

namespace {
struct FakeSwapchainHook : gpu::DeviceHook {
    std::string_view name() const override { return "fake frame generation hook"; }
};
}  // namespace

TEST_CASE("frame generation: a provider's device hook goes to the devices of renderers that asked, and to no other") {
    auto hook = std::make_shared<FakeSwapchainHook>();
    FakeProvider dlss(FrameGenSlot::Dlss);
    dlss.hook = hook;
    FakeProvider noHook(FrameGenSlot::Fsr);   // a provider with no hook adds none
    FakeProvider noXess(FrameGenSlot::Xess);  // (the Xess slot's own provider has a hook)
    ProviderGuard g1(FrameGenSlot::Dlss, &dlss), g2(FrameGenSlot::Fsr, &noHook), g3(FrameGenSlot::Xess, &noXess);

    const auto hooks = render::framegen_device_hooks();
    REQUIRE(hooks.size() == 1);
    CHECK(hooks[0] == hook);
    CHECK(render::framegen_device_hooks().size() == 1);  // asked again: the same one, never added up

    // Never registered for the process: a device made without them (a second renderer with frame generation off) does not see it.
    for (const auto& registered : gpu::registered_device_hooks()) CHECK(registered != hook);
    for (const auto& h : gpu::with_registered_hooks({})) CHECK(h != hook);
    auto other = gpu::make_device(gpu::Backend::Recording, gpu::DeviceInit{});
    REQUIRE(other);
    CHECK(hook->available());
    CHECK(hook->unavailable_reason().empty());

    // The device that is given it sees it (the recording backend calls no hook and says so).
    gpu::DeviceInit init;
    init.hooks = hooks;
    auto own = gpu::make_device(gpu::Backend::Recording, init);
    REQUIRE(own);
    CHECK_FALSE(hook->available());
}
