// M78-P6a: the low-latency seam (src/render_latency.{h,cpp}, include/fa/render/latency.h) and its AMD Anti-Lag 2 and Intel XeLL providers
// (src/render_latency_antilag2.*, src/render_latency_xell.*). No vendor library is involved: the functions of each SDK are fakes behind a
// fake VendorLoader, the clock is a fake, and the device is a RecordingDevice that answers a backend and a GPU maker. What is tested is what
// the engine asks of each SDK and when (init, mode, sleep, markers, frame ids), what a missing or failing SDK does (an "unavailable" with a
// reason, the engine's own pacing, never a device failure), the choice of the path per GPU maker, and that an off setting calls nothing.
// That the real driver shortens the latency is for a machine with an AMD or Intel GPU.
#include <doctest.h>

#include <algorithm>
#include <array>
#include <cstdint>
#include <cstring>
#include <filesystem>
#include <map>
#include <memory>
#include <string>
#include <vector>

#include "fa/core/json.h"
#include "gpu/recording_device.h"
#include "render_latency.h"
#include "render_latency_antilag2.h"
#include "render_latency_xell.h"
#include "render_features.h"

using namespace fa;
using render::GpuVendor;
using render::LatencyDriver;
using render::LatencyMarker;
using render::LatencyMode;
using render::LatencySettings;

namespace {

// ---- the device ---------------------------------------------------------------------------------------------------------------------

class LDevice : public gpu::RecordingDevice {
public:
    LDevice(gpu::Backend deviceBackend, std::uint32_t pciVendor) : backend_(deviceBackend) {
        info_ = gpu::RecordingDevice::info();
        info_.backend = deviceBackend;
        info_.gpu.vendorId = pciVendor;
        info_.gpu.vendor = gpu::gpu_vendor_from_pci(pciVendor);
    }
    gpu::Backend backend() const override { return backend_; }
    const gpu::DeviceInfo& info() const override { return info_; }
    gpu::NativeDevice native() const override {
        gpu::NativeDevice n;
        n.device = reinterpret_cast<const void*>(std::uintptr_t(0x1000));
        return n;
    }

private:
    gpu::Backend backend_;
    gpu::DeviceInfo info_;
};

render::VendorEnv env_of(const LDevice& d, GpuVendor vendor, bool windows = true) {
    render::VendorEnv e;
    e.backend = d.backend();
    e.vendor = vendor;
    e.device = &d;
    e.windows = windows;
    return e;
}

// ---- the clock ----------------------------------------------------------------------------------------------------------------------

class FakeClock final : public render::LatencyClock {
public:
    double t = 1000.0;
    std::vector<double> sleptUntil;
    double now_ms() override { return t; }
    void sleep_until_ms(double target) override {
        sleptUntil.push_back(target);
        t = std::max(t, target);
    }
};

struct ClockGuard {
    explicit ClockGuard(render::LatencyClock* c) { render::set_latency_clock_for_test(c); }
    ~ClockGuard() { render::set_latency_clock_for_test(nullptr); }
    ClockGuard(const ClockGuard&) = delete;
    ClockGuard& operator=(const ClockGuard&) = delete;
};

// ---- a fake provider ----------------------------------------------------------------------------------------------------------------

class FakeProvider final : public render::LatencyProvider {
public:
    explicit FakeProvider(LatencyDriver d) : driver_(d) {}
    bool available = true;
    std::string probeReason = "fake reason";
    std::string startFails;  // non-empty: start() answers this
    int probes = 0, starts = 0, stops = 0;
    std::vector<std::string> calls;  // "configure on boost", "sleep 3", "marker presentStart 3", ...
    Json report;

    std::string_view name() const override { return "Fake SDK"; }
    LatencyDriver driver() const override { return driver_; }
    std::string_view setup_id() const override { return ""; }
    unsigned backends() const override { return ~0u; }
    render::VendorProbe probe(const render::VendorEnv&) override {
        ++probes;
        render::VendorProbe p;
        p.available = available;
        if (!available) p.reason = probeReason;
        return p;
    }
    std::string start(gpu::Device&) override {
        ++starts;
        calls.push_back("start");
        return startFails;
    }
    void configure(bool enabled, bool boost, std::uint32_t) override {
        calls.push_back(std::string("configure ") + (enabled ? "on" : "off") + (boost ? " boost" : ""));
    }
    void sleep(std::uint64_t id) override { calls.push_back("sleep " + std::to_string(id)); }
    void marker(LatencyMarker m, std::uint64_t id) override {
        calls.push_back("marker " + std::string(render::latency_marker_name(m)) + " " + std::to_string(id));
    }
    Json vendor_report() override { return report; }
    void stop(gpu::Device&) override {
        ++stops;
        calls.push_back("stop");
    }

private:
    LatencyDriver driver_;
};

struct ProviderGuard {
    ProviderGuard(LatencyDriver d, render::LatencyProvider* p) : d_(d) { render::set_latency_provider_for_test(d, p); }
    ~ProviderGuard() { render::set_latency_provider_for_test(d_, nullptr); }
    ProviderGuard(const ProviderGuard&) = delete;
    ProviderGuard& operator=(const ProviderGuard&) = delete;
    LatencyDriver d_;
};

// One frame as the engine and the renderer report it.
void run_frame(render::LatencyController& c, FakeClock& clock, double workMs, double presentMs, double hz = 0.0) {
    c.frame_begin(hz);
    c.mark(LatencyMarker::InputSample);
    clock.t += workMs * 0.5;
    c.mark(LatencyMarker::SimulationEnd);
    c.mark(LatencyMarker::RenderSubmitStart);
    clock.t += workMs * 0.5;
    c.mark(LatencyMarker::RenderSubmitEnd);
    c.mark(LatencyMarker::PresentStart);
    clock.t += presentMs;
    c.mark(LatencyMarker::PresentEnd);
}

LatencySettings settings(LatencyMode m, bool boost = false) {
    LatencySettings s;
    s.mode = m;
    s.boost = boost;
    return s;
}

}  // namespace

// ---- the setting -----------------------------------------------------------------------------------------------------------------------

TEST_CASE("latency settings: names, parse, errors that teach") {
    CHECK(render::latency_mode_name(LatencyMode::AntiLag2) == "antilag2");
    CHECK(render::latency_driver_name(LatencyDriver::Pacing) == "pacing");
    CHECK(render::latency_to_json(LatencySettings{}) == Json::parse(R"({"mode":"off","boost":false})"));

    const LatencySettings base = settings(LatencyMode::Auto, true);
    auto ok = render::parse_latency_settings(Json::parse(R"({"mode":"xell"})"), "t", base);
    REQUIRE(ok.ok());
    CHECK(ok.value().mode == LatencyMode::Xell);
    CHECK(ok.value().boost);  // the keys that are absent keep the base

    auto both = render::parse_latency_settings(Json::parse(R"({"mode":"off","boost":false})"), "t", base);
    REQUIRE(both.ok());
    CHECK(both.value() == LatencySettings{});

    auto badMode =
        render::parse_latency_settings(Json::parse(R"({"mode":"antilag"})"), "factoria.json#/render/latency", base);
    REQUIRE_FALSE(badMode.ok());
    const std::string text = badMode.error().to_string();
    CHECK(text.find("factoria.json#/render/latency/mode") != std::string::npos);
    CHECK(text.find("antilag2") != std::string::npos);  // the did-you-mean

    auto badKey = render::parse_latency_settings(Json::parse(R"({"boots":true})"), "t", base);
    REQUIRE_FALSE(badKey.ok());
    CHECK(badKey.error().to_string().find("boost") != std::string::npos);

    CHECK_FALSE(render::parse_latency_settings(Json::parse(R"({"boost":"yes"})"), "t", base).ok());
    CHECK_FALSE(render::parse_latency_settings(Json::parse(R"({"mode":3})"), "t", base).ok());
    CHECK_FALSE(render::parse_latency_settings(Json::parse(R"("auto")"), "t", base).ok());
}

TEST_CASE("latency settings: the driver that runs") {
    render::LatencyCaps c;
    c.pacing = true;
    CHECK(render::effective_latency_driver(settings(LatencyMode::Off), c) == LatencyDriver::None);
    // An explicit mode whose SDK is not usable runs the engine's own pacing.
    CHECK(render::effective_latency_driver(settings(LatencyMode::Reflex), c) == LatencyDriver::Pacing);
    c.antiLag2 = true;
    CHECK(render::effective_latency_driver(settings(LatencyMode::AntiLag2), c) == LatencyDriver::AntiLag2);
    // auto: the SDK of the GPU's maker only.
    c.xell = true;
    c.gpuVendor = GpuVendor::Amd;
    CHECK(render::effective_latency_driver(settings(LatencyMode::Auto), c) == LatencyDriver::AntiLag2);
    c.gpuVendor = GpuVendor::Intel;
    CHECK(render::effective_latency_driver(settings(LatencyMode::Auto), c) == LatencyDriver::Xell);
    c.gpuVendor = GpuVendor::Nvidia;  // reflex is not usable
    CHECK(render::effective_latency_driver(settings(LatencyMode::Auto), c) == LatencyDriver::Pacing);
    c.reflex = true;
    CHECK(render::effective_latency_driver(settings(LatencyMode::Auto), c) == LatencyDriver::Reflex);
    c.gpuVendor = GpuVendor::Apple;
    CHECK(render::effective_latency_driver(settings(LatencyMode::Auto), c) == LatencyDriver::Pacing);
    // No window to pace: nothing runs.
    c.pacing = false;
    CHECK(render::effective_latency_driver(settings(LatencyMode::Auto), c) == LatencyDriver::None);
    CHECK(render::effective_latency_driver(settings(LatencyMode::Xell), c) == LatencyDriver::Xell);
}

// ---- the controller -------------------------------------------------------------------------------------------------------------------

TEST_CASE("latency controller: an SDK gets the sleep, the markers and the frame ids of the present") {
    LDevice dev(gpu::Backend::D3d12, 0x1002);
    FakeClock clock;
    ClockGuard cg(&clock);
    FakeProvider amd(LatencyDriver::AntiLag2);
    ProviderGuard pg(LatencyDriver::AntiLag2, &amd);
    render::LatencyController c;
    c.attach(&dev, env_of(dev, GpuVendor::Amd), true);
    CHECK(c.driver() == LatencyDriver::None);  // off by default: the SDK is not even asked
    CHECK(amd.probes == 0);
    CHECK(amd.calls.empty());

    c.set_settings(settings(LatencyMode::Auto, true));
    CHECK(c.driver() == LatencyDriver::AntiLag2);
    CHECK(amd.starts == 1);
    REQUIRE(amd.calls.size() == 2);
    CHECK(amd.calls[1] == "configure on boost");
    amd.calls.clear();

    run_frame(c, clock, 4.0, 1.0);
    const std::vector<std::string> first = {"sleep 1",
                                            "marker simulationStart 1",
                                            "marker inputSample 1",
                                            "marker simulationEnd 1",
                                            "marker renderSubmitStart 1",
                                            "marker renderSubmitEnd 1",
                                            "marker presentStart 1",
                                            "marker presentEnd 1"};
    CHECK(amd.calls == first);
    amd.calls.clear();
    run_frame(c, clock, 4.0, 1.0);  // the next frame is the next present
    REQUIRE(amd.calls.size() == 8);
    CHECK(amd.calls.front() == "sleep 2");
    CHECK(amd.calls.back() == "marker presentEnd 2");

    // A mode that needs no SDK stops it: the engine's own pacing takes over.
    amd.calls.clear();
    c.set_settings(settings(LatencyMode::Off));
    CHECK(c.driver() == LatencyDriver::None);
    CHECK(amd.calls == std::vector<std::string>{"configure off", "stop"});
    amd.calls.clear();
    run_frame(c, clock, 4.0, 1.0);
    CHECK(amd.calls.empty());  // off: no call at all
    c.detach();
}

TEST_CASE("latency controller: a failing SDK is unavailable with a reason and the engine's own pacing runs") {
    LDevice dev(gpu::Backend::D3d12, 0x8086);
    FakeClock clock;
    ClockGuard cg(&clock);
    FakeProvider xell(LatencyDriver::Xell);
    ProviderGuard pg(LatencyDriver::Xell, &xell);
    SUBCASE("probe says no") {
        xell.available = false;
        xell.probeReason = "XeLL is not installed: run `factoria setup xess`";
        render::LatencyController c;
        c.attach(&dev, env_of(dev, GpuVendor::Intel), true);
        c.set_settings(settings(LatencyMode::Xell));
        CHECK(c.driver() == LatencyDriver::Pacing);
        CHECK(c.provider_reason(LatencyDriver::Xell) == xell.probeReason);
        CHECK(xell.starts == 0);
    }
    SUBCASE("start says no, once") {
        xell.startFails = "XeLL could not make its context";
        render::LatencyController c;
        c.attach(&dev, env_of(dev, GpuVendor::Intel), true);
        c.set_settings(settings(LatencyMode::Auto));
        CHECK(c.driver() == LatencyDriver::Pacing);
        CHECK(c.provider_reason(LatencyDriver::Xell) == "XeLL could not make its context");
        c.set_settings(settings(LatencyMode::Xell));  // not asked again
        CHECK(xell.starts == 1);
        CHECK(c.driver() == LatencyDriver::Pacing);
    }
    SUBCASE("no window to pace") {
        xell.available = false;
        render::LatencyController c;
        c.attach(&dev, env_of(dev, GpuVendor::Intel), false);  // a headless run
        c.set_settings(settings(LatencyMode::Auto));
        CHECK(c.driver() == LatencyDriver::None);
    }
}

TEST_CASE("latency controller: auto picks the SDK of the GPU's maker; reflex has no provider yet") {
    FakeClock clock;
    ClockGuard cg(&clock);
    FakeProvider amd(LatencyDriver::AntiLag2), intel(LatencyDriver::Xell);
    ProviderGuard pa(LatencyDriver::AntiLag2, &amd), pi(LatencyDriver::Xell, &intel);
    const struct {
        std::uint32_t pci;
        GpuVendor vendor;
        LatencyDriver expect;
    } rows[] = {{0x1002, GpuVendor::Amd, LatencyDriver::AntiLag2},
                {0x8086, GpuVendor::Intel, LatencyDriver::Xell},
                {0x10de, GpuVendor::Nvidia, LatencyDriver::Pacing},  // Reflex arrives with the Streamline provider
                {0x106b, GpuVendor::Apple, LatencyDriver::Pacing}};
    for (const auto& r : rows) {
        CAPTURE(render::gpu_vendor_name(r.vendor));
        LDevice dev(gpu::Backend::D3d12, r.pci);
        render::LatencyController c;
        c.attach(&dev, env_of(dev, r.vendor), true);
        c.set_settings(settings(LatencyMode::Auto));
        CHECK(c.driver() == r.expect);
    }
    LDevice dev(gpu::Backend::D3d12, 0x10de);
    render::LatencyController c;
    c.attach(&dev, env_of(dev, GpuVendor::Nvidia), true);
    const std::string why = c.provider_reason(LatencyDriver::Reflex);
    CHECK(why.find("arrives with the Streamline provider") != std::string::npos);
    c.set_settings(settings(LatencyMode::Reflex));
    CHECK(c.driver() == LatencyDriver::Pacing);  // the explicit mode falls back to the engine's own pacing
}

TEST_CASE("latency controller: a registered provider fills a slot with one call") {
    LDevice dev(gpu::Backend::D3d12, 0x10de);
    FakeClock clock;
    ClockGuard cg(&clock);
    auto reflex = std::make_shared<FakeProvider>(LatencyDriver::Reflex);
    render::LatencyController c;
    c.attach(&dev, env_of(dev, GpuVendor::Nvidia), true);
    c.set_settings(settings(LatencyMode::Auto));
    REQUIRE(c.driver() == LatencyDriver::Pacing);
    render::register_latency_provider(reflex);
    c.reset_probes();
    CHECK(c.driver() == LatencyDriver::Reflex);
    CHECK(reflex->starts == 1);
    c.detach();
    // Puts the empty slot back for the other tests.
    render::register_latency_provider(nullptr);  // ignored
    render::clear_registered_latency_provider_for_test(LatencyDriver::Reflex);
    CHECK(render::latency_provider(LatencyDriver::Reflex) == nullptr);
}

TEST_CASE("latency controller: the engine's own pacing sleeps before the input is read") {
    LDevice dev(gpu::Backend::Vulkan, 0x106b);
    FakeClock clock;
    ClockGuard cg(&clock);
    render::LatencyController c;
    c.attach(&dev, env_of(dev, GpuVendor::Apple), true);
    c.set_settings(settings(LatencyMode::Auto));
    REQUIRE(c.driver() == LatencyDriver::Pacing);

    // No history: no sleep.
    run_frame(c, clock, 4.0, 1.0, 60.0);
    CHECK(clock.sleptUntil.empty());
    // The frame took 4 ms of work; the present ended at t. The next frame starts so that its work ends one interval after the last present.
    const double presentEnd = clock.t;
    const double interval = 1000.0 / 60.0;
    CHECK(c.pacing_sleep_ms(60.0) == doctest::Approx(interval - 4.0 * 1.15 - 1.0 - 0.0).epsilon(0.01));
    run_frame(c, clock, 4.0, 1.0, 60.0);
    REQUIRE(clock.sleptUntil.size() == 1);
    CHECK(clock.sleptUntil[0] == doctest::Approx(presentEnd + interval - 4.0 * 1.15 - 1.0).epsilon(0.001));

    // Without a refresh rate (vsync off, a frame cap) no sleep is added.
    const std::size_t before = clock.sleptUntil.size();
    run_frame(c, clock, 4.0, 1.0, 0.0);
    CHECK(clock.sleptUntil.size() == before);
    CHECK(c.pacing_sleep_ms(0.0) == 0.0);
    // A frame as long as the interval gets no sleep.
    run_frame(c, clock, 30.0, 1.0, 60.0);
    run_frame(c, clock, 30.0, 1.0, 60.0);
    CHECK(c.pacing_sleep_ms(60.0) == 0.0);
}

TEST_CASE("latency controller: the readout is input to present, once per frame") {
    LDevice dev(gpu::Backend::Vulkan, 0x106b);
    FakeClock clock;
    ClockGuard cg(&clock);
    render::LatencyController c;
    c.attach(&dev, env_of(dev, GpuVendor::Apple), true);
    CHECK(c.take_last_frame_ms() < 0.0);  // off: nothing measured
    c.set_settings(settings(LatencyMode::Auto));
    run_frame(c, clock, 6.0, 2.0);  // input .. present end = 6 + 2
    CHECK(c.take_last_frame_ms() == doctest::Approx(8.0));
    CHECK(c.take_last_frame_ms() < 0.0);  // taken once
    run_frame(c, clock, 10.0, 2.0);
    for (int i = 0; i < 18; ++i) run_frame(c, clock, 6.0, 2.0);
    const render::LatencyReport r = c.report();
    CHECK(r.driver == LatencyDriver::Pacing);
    CHECK(r.samples == 20);
    CHECK(r.maxMs == doctest::Approx(12.0));
    CHECK(r.lastMs == doctest::Approx(8.0));
    CHECK(r.avgMs == doctest::Approx((12.0 + 19 * 8.0) / 20.0));
    CHECK(r.p95Ms == doctest::Approx(8.0));  // the 19th of 20 sorted values; the 12 is the 20th
    CHECK(r.vendor.is_null());
    // A frame that never presented has no sample: the input mark waits for its present.
    CHECK(c.take_last_frame_ms() >= 0.0);
    c.frame_begin(0.0);
    c.mark(LatencyMarker::InputSample);
    CHECK(c.take_last_frame_ms() < 0.0);
    c.set_settings(settings(LatencyMode::Off));
    run_frame(c, clock, 6.0, 2.0);
    CHECK(c.take_last_frame_ms() < 0.0);
}

TEST_CASE("latency controller: the vendor's own report comes with the readout") {
    LDevice dev(gpu::Backend::D3d12, 0x8086);
    FakeClock clock;
    ClockGuard cg(&clock);
    FakeProvider xell(LatencyDriver::Xell);
    ProviderGuard pg(LatencyDriver::Xell, &xell);
    xell.report = Json::parse(R"({"source":"XeLL","avgSimulationToPresentMs":7.5})");
    render::LatencyController c;
    c.attach(&dev, env_of(dev, GpuVendor::Intel), true);
    c.set_settings(settings(LatencyMode::Xell));
    CHECK(c.report().vendor["source"] == "XeLL");
}

TEST_CASE("latency: render.supports rows") {
    render::FeatureEnv env = render::feature_env_from_device(LDevice(gpu::Backend::D3d12, 0x1002));
    const int idx = render::find_feature("antilag2");
    REQUIRE(idx >= 0);
    CHECK(render::find_feature("reflex") >= 0);
    CHECK(render::find_feature("xell") >= 0);
    std::string why;
    CHECK_FALSE(render::feature_supported(env, idx, &why));  // not asked
    std::array<render::VendorProbe, 3> answers;
    answers[1].available = true;
    answers[2].reason = "XeLL has a Direct3D 12 entry point only";
    render::set_latency_env(env, answers);
    CHECK(render::feature_supported(env, idx, &why));
    CHECK_FALSE(render::feature_supported(env, render::find_feature("xell"), &why));
    CHECK(why.find("Direct3D 12") != std::string::npos);
}

// ---- AMD Anti-Lag 2 ------------------------------------------------------------------------------------------------------------------

namespace {

namespace al = fa::render::antilag2_abi;

struct AlFx {
    std::vector<std::string> events;  // "create", "state on", "state off", "delay", "release"
    std::vector<al::ApiDataV1> states;
    std::int32_t createRc = 0, stateRc = 0;
    al::Interface iface{};
    void reset() { *this = AlFx{}; }
};
AlFx alfx;

std::int32_t al_query(al::Interface*, const al::Guid*, void**) { return 0; }
std::uint32_t al_add_ref(al::Interface*) { return 2; }
std::uint32_t al_release(al::Interface*) {
    alfx.events.push_back("release");
    return 0;
}
std::int32_t al_update(al::Interface*, void* data) {
    if (!data) {
        alfx.events.push_back("delay");
        return 0;
    }
    const al::ApiDataV1 d = *static_cast<al::ApiDataV1*>(data);
    alfx.states.push_back(d);
    alfx.events.push_back(d.mode == al::kModeOn ? "state on" : "state off");
    return alfx.stateRc;
}
const al::InterfaceVtbl kAlVtbl = {&al_query, &al_add_ref, &al_release, &al_update};

std::int32_t al_create(void* device, const al::Guid* iid, void** out) {
    alfx.events.push_back("create");
    CHECK(device != nullptr);
    CHECK(iid->data1 == 0x44085fbe);
    if (alfx.createRc < 0) return alfx.createRc;
    alfx.iface.vtbl = &kAlVtbl;
    *out = &alfx.iface;
    return 0;
}

class AlModule final : public render::VendorLibrary {
public:
    bool hasCreate = true;
    void* symbol(const char* name) override {
        if (hasCreate && std::string(name) == "AmdExtD3DCreateInterface") return reinterpret_cast<void*>(&al_create);
        return nullptr;
    }
    const std::string& path() const override { return path_; }

private:
    std::string path_ = "C:/Windows/System32/amdxc64.dll";
};

class AlLoader final : public render::VendorLoader {
public:
    bool moduleLoaded = true, hasCreate = true;
    std::vector<std::string> asked;
    std::filesystem::path find(const render::VendorLibrarySpec&, std::string* why) override {
        if (why) *why = "not used";
        return {};
    }
    std::unique_ptr<render::VendorLibrary> load(const std::filesystem::path&, std::string*) override { return nullptr; }
    std::unique_ptr<render::VendorLibrary> open_loaded(const char* module, std::string* why) override {
        asked.push_back(module);
        if (!moduleLoaded) {
            if (why) *why = "the module is not in this process";
            return nullptr;
        }
        auto m = std::make_unique<AlModule>();
        m->hasCreate = hasCreate;
        return m;
    }
};

struct LoaderGuard {
    explicit LoaderGuard(render::VendorLoader* l) { render::set_vendor_loader_for_test(l); }
    ~LoaderGuard() { render::set_vendor_loader_for_test(nullptr); }
    LoaderGuard(const LoaderGuard&) = delete;
    LoaderGuard& operator=(const LoaderGuard&) = delete;
};

}  // namespace

TEST_CASE("antilag2: unavailable with a reason") {
    AlLoader loader;
    LoaderGuard lg(&loader);
    auto p = render::make_antilag2_provider();
    LDevice d12(gpu::Backend::D3d12, 0x1002);
    {
        const auto r = p->probe(env_of(d12, GpuVendor::Amd, /*windows=*/false));
        CHECK_FALSE(r.available);
        CHECK(r.reason.find("Windows only") != std::string::npos);
    }
    {
        const auto r = p->probe(env_of(d12, GpuVendor::Nvidia));
        CHECK_FALSE(r.available);
        CHECK(r.reason.find("AMD Radeon") != std::string::npos);
    }
    {
        LDevice d11(gpu::Backend::D3d11, 0x1002);
        const auto r = p->probe(env_of(d11, GpuVendor::Amd));
        CHECK_FALSE(r.available);
        CHECK(r.reason.find("D3D12") != std::string::npos);
        CHECK(r.reason.find("not supported") != std::string::npos);
    }
    {
        loader.moduleLoaded = false;
        const auto r = p->probe(env_of(d12, GpuVendor::Amd));
        CHECK_FALSE(r.available);
        CHECK(r.reason.find("amdxc64.dll") != std::string::npos);
        CHECK(r.reason.find("Adrenalin") != std::string::npos);
    }
    {
        loader.moduleLoaded = true;
        loader.hasCreate = false;
        const auto r = p->probe(env_of(d12, GpuVendor::Amd));
        CHECK_FALSE(r.available);
        CHECK(r.reason.find("AmdExtD3DCreateInterface") != std::string::npos);
    }
    {
        loader.hasCreate = true;
        alfx.reset();
        alfx.createRc = -2147467259;
        const auto r = p->probe(env_of(d12, GpuVendor::Amd));
        CHECK_FALSE(r.available);
        CHECK(r.reason.find("RX 7000") != std::string::npos);
    }
}

TEST_CASE("antilag2 on Direct3D 12: init, mode, delay") {
    AlLoader loader;
    LoaderGuard lg(&loader);
    alfx.reset();
    auto p = render::make_antilag2_provider();
    LDevice dev(gpu::Backend::D3d12, 0x1002);
    const auto probe = p->probe(env_of(dev, GpuVendor::Amd));
    REQUIRE(probe.available);
    CHECK(alfx.events == std::vector<std::string>{"create", "release"});  // the probe gives its interface back
    alfx.reset();

    REQUIRE(p->start(dev).empty());
    // The SDK's Initialize: the state is off, before the first frame.
    REQUIRE(alfx.states.size() == 1);
    CHECK(alfx.states[0].size == 32);
    CHECK(alfx.states[0].version == 1);
    CHECK(alfx.states[0].mode == al::kModeOff);
    p->sleep(1);  // not configured on: nothing
    p->marker(LatencyMarker::PresentStart, 1);
    CHECK(alfx.events == std::vector<std::string>{"create", "state off"});

    p->configure(true, /*boost, which Anti-Lag 2 ignores*/ true, 0);
    p->sleep(5);
    p->marker(LatencyMarker::PresentStart, 5);  // Direct3D 12 has no markers
    p->configure(false, false, 0);
    p->sleep(6);
    CHECK(alfx.events == std::vector<std::string>{"create", "state off", "state on", "delay", "state off"});
    CHECK(alfx.states.back().mode == al::kModeOff);
    p->configure(true, false, 0);
    p->stop(dev);
    CHECK(alfx.events.back() == "release");  // turned off first, then released
    CHECK(alfx.events[alfx.events.size() - 2] == "state off");
    alfx.events.clear();
    p->sleep(7);
    CHECK(alfx.events.empty());
}

TEST_CASE("antilag2 on Direct3D 12: a driver that refuses the first state is unavailable, not a device failure") {
    AlLoader loader;
    LoaderGuard lg(&loader);
    alfx.reset();
    alfx.stateRc = -1;
    auto p = render::make_antilag2_provider();
    LDevice dev(gpu::Backend::D3d12, 0x1002);
    const std::string why = p->start(dev);
    CHECK(why.find("refused") != std::string::npos);
    CHECK(alfx.events.back() == "release");
}

namespace {

struct VkFx {
    std::vector<al::VkData> data;
    std::vector<al::VkPresentationInfo> infos;
    std::vector<const void*> devices;
    std::vector<std::string> askedNames;
    bool hasFunction = true;
};
VkFx vkfx;

void fake_vk_update(const void* device, const al::VkData* d) {
    vkfx.devices.push_back(device);
    vkfx.data.push_back(*d);
    al::VkPresentationInfo info{};
    if (d->presentationInfo) info = *d->presentationInfo;
    vkfx.infos.push_back(info);
}

gpu::HookProcAddr fake_get_device_proc_addr(const void*, const char* name) {
    vkfx.askedNames.emplace_back(name);
    if (!vkfx.hasFunction || std::string(name) != "vkAntiLagUpdateAMD") return nullptr;
    return reinterpret_cast<gpu::HookProcAddr>(&fake_vk_update);
}

}  // namespace

TEST_CASE("antilag2 on Vulkan: the extension is asked of an AMD GPU only, the stages carry the frame index") {
    vkfx = VkFx{};
    AlLoader loader;
    LoaderGuard lg(&loader);
    const std::shared_ptr<render::AntiLag2Hook> hook = render::antilag2_hook();

    // Another maker's GPU: nothing is asked.
    {
        gpu::VulkanPhysicalDevice gpuInfo;
        gpuInfo.vendorId = 0x10de;
        gpu::VulkanDeviceRequest request;
        hook->vulkan_device_request(gpuInfo, request);
        CHECK(request.extensions.empty());
        CHECK(request.features.empty());
        CHECK_FALSE(hook->requested());
    }
    // An AMD GPU: the extension and its feature (VkPhysicalDeviceAntiLagFeaturesAMD, antiLag = VK_TRUE).
    gpu::VulkanPhysicalDevice amdGpu;
    amdGpu.vendorId = 0x1002;
    gpu::VulkanDeviceRequest request;
    hook->vulkan_device_request(amdGpu, request);
    REQUIRE(request.extensions.size() == 1);
    CHECK(request.extensions[0] == "VK_AMD_anti_lag");
    REQUIRE(request.features.size() == 1);
    REQUIRE(request.features[0].size() == sizeof(al::VkFeatures));
    al::VkFeatures asked{};
    std::memcpy(&asked, request.features[0].data(), sizeof(asked));
    CHECK(asked.sType == 1000476000);
    CHECK(asked.antiLag == 1);
    CHECK(hook->requested());
    CHECK_FALSE(hook->granted());

    auto p = render::make_antilag2_provider();
    LDevice dev(gpu::Backend::Vulkan, 0x1002);
    {
        // The device was not made with the extension: the probe says what to do.
        const auto r = p->probe(env_of(dev, GpuVendor::Amd));
        CHECK_FALSE(r.available);
        CHECK(r.reason.find("VK_AMD_anti_lag") != std::string::npos);
    }
    gpu::VulkanDeviceCreated created;
    created.native = dev.native();
    created.native.getDeviceProcAddr = reinterpret_cast<gpu::NativeDevice::ProcAddr>(&fake_get_device_proc_addr);
    hook->vulkan_device_created(created);
    CHECK(hook->granted());
    REQUIRE(vkfx.askedNames.size() == 1);
    CHECK(vkfx.askedNames[0] == "vkAntiLagUpdateAMD");

    REQUIRE(p->probe(env_of(dev, GpuVendor::Amd)).available);
    REQUIRE(p->start(dev).empty());
    CHECK(vkfx.data.empty());  // nothing is sent until the mode is on
    p->configure(true, false, 0);
    REQUIRE(vkfx.data.size() == 1);
    CHECK(vkfx.data[0].sType == 1000476001);
    CHECK(vkfx.data[0].mode == al::kVkModeOn);
    CHECK(vkfx.data[0].presentationInfo == nullptr);
    CHECK(vkfx.devices[0] == dev.native().device);

    p->sleep(41);  // the input stage, with the frame index
    p->marker(LatencyMarker::InputSample, 41);
    p->marker(LatencyMarker::RenderSubmitEnd, 41);
    p->marker(LatencyMarker::PresentStart, 41);  // the present stage, the same index
    p->marker(LatencyMarker::PresentEnd, 41);
    REQUIRE(vkfx.data.size() == 3);
    CHECK(vkfx.infos[1].stage == al::kStageInput);
    CHECK(vkfx.infos[1].frameIndex == 41);
    CHECK(vkfx.infos[1].sType == 1000476002);
    CHECK(vkfx.infos[2].stage == al::kStagePresent);
    CHECK(vkfx.infos[2].frameIndex == 41);

    p->configure(false, false, 0);
    REQUIRE(vkfx.data.size() == 4);
    CHECK(vkfx.data[3].mode == al::kVkModeOff);
    p->stop(dev);
    hook->device_destroying();
    CHECK_FALSE(hook->granted());
    // The device was made but the driver has no vkAntiLagUpdateAMD: not granted.
    vkfx.hasFunction = false;
    hook->vulkan_device_request(amdGpu, request);
    hook->vulkan_device_created(created);
    CHECK_FALSE(hook->granted());
    hook->device_destroying();
}

// ---- Intel XeLL ----------------------------------------------------------------------------------------------------------------------

namespace {

namespace xl = fa::render::xell_abi;

struct XlFx {
    xl::Version version{1, 2, 0, 0};
    std::int32_t versionRc = 0, createRc = 0, setModeRc = 0;
    std::vector<std::string> events;
    std::vector<xl::SleepParams> modes;
    std::vector<std::pair<std::uint32_t, std::int32_t>> markers;
    std::vector<std::uint32_t> sleeps;
    void* createdFor = nullptr;
    int token = 0;
    std::vector<xl::FrameReport> reports;
    void reset() { *this = XlFx{}; }
};
XlFx xlfx;

xl::Context xl_ctx() { return reinterpret_cast<xl::Context>(&xlfx.token); }
std::int32_t xl_get_version(xl::Version* v) {
    *v = xlfx.version;
    return xlfx.versionRc;
}
std::int32_t xl_create(void* device, xl::Context* out) {
    xlfx.events.push_back("create");
    xlfx.createdFor = device;
    if (xlfx.createRc != 0) return xlfx.createRc;
    *out = xl_ctx();
    return 0;
}
std::int32_t xl_destroy(xl::Context) {
    xlfx.events.push_back("destroy");
    return 0;
}
std::int32_t xl_set_mode(xl::Context, const xl::SleepParams* p) {
    xlfx.modes.push_back(*p);
    return xlfx.setModeRc;
}
std::int32_t xl_sleep(xl::Context, std::uint32_t id) {
    xlfx.sleeps.push_back(id);
    return 0;
}
std::int32_t xl_marker(xl::Context, std::uint32_t id, std::int32_t marker) {
    xlfx.markers.emplace_back(id, marker);
    return 0;
}
std::int32_t xl_reports(xl::Context, xl::FrameReport* out) {
    for (std::size_t i = 0; i < xlfx.reports.size() && i < std::size_t(xl::kReportCount); ++i) out[i] = xlfx.reports[i];
    return 0;
}

class XlLib final : public render::VendorLibrary {
public:
    std::vector<std::string> hidden;
    void* symbol(const char* name) override {
        const std::string n = name;
        if (std::find(hidden.begin(), hidden.end(), n) != hidden.end()) return nullptr;
        if (n == "xellGetVersion") return reinterpret_cast<void*>(&xl_get_version);
        if (n == "xellD3D12CreateContext") return reinterpret_cast<void*>(&xl_create);
        if (n == "xellDestroyContext") return reinterpret_cast<void*>(&xl_destroy);
        if (n == "xellSetSleepMode") return reinterpret_cast<void*>(&xl_set_mode);
        if (n == "xellSleep") return reinterpret_cast<void*>(&xl_sleep);
        if (n == "xellAddMarkerData") return reinterpret_cast<void*>(&xl_marker);
        if (n == "xellGetFramesReports") return reinterpret_cast<void*>(&xl_reports);
        return nullptr;
    }
    const std::string& path() const override { return path_; }

private:
    std::string path_ = "fake/libxell.dll";
};

class XlLoader final : public render::VendorLoader {
public:
    bool installed = true, loads = true;
    std::vector<std::string> hidden;
    std::filesystem::path find(const render::VendorLibrarySpec& spec, std::string* why) override {
        if (!installed) {
            if (why) *why = "the fake loader has no library";
            return {};
        }
        CHECK(std::string(spec.fileName) == "libxell.dll");
        CHECK(std::string(spec.setupId) == "xess");
        return std::filesystem::path("fake") / spec.fileName;
    }
    std::unique_ptr<render::VendorLibrary> load(const std::filesystem::path&, std::string* why) override {
        if (!loads) {
            if (why) *why = "the fake loader cannot load it";
            return nullptr;
        }
        auto l = std::make_unique<XlLib>();
        l->hidden = hidden;
        return l;
    }
};

}  // namespace

TEST_CASE("xell: unavailable with a reason") {
    XlLoader loader;
    LoaderGuard lg(&loader);
    xlfx.reset();
    auto p = render::make_xell_provider();
    LDevice d12(gpu::Backend::D3d12, 0x8086);
    {
        const auto r = p->probe(env_of(d12, GpuVendor::Intel, /*windows=*/false));
        CHECK_FALSE(r.available);
        CHECK(r.reason.find("Windows only") != std::string::npos);
    }
    {
        LDevice vk(gpu::Backend::Vulkan, 0x8086);
        const auto r = p->probe(env_of(vk, GpuVendor::Intel));
        CHECK_FALSE(r.available);
        CHECK(r.reason.find("Direct3D 12") != std::string::npos);
    }
    loader.installed = false;
    {
        const auto r = p->probe(env_of(d12, GpuVendor::Intel));
        CHECK_FALSE(r.available);
        CHECK(r.reason.find("factoria setup xess") != std::string::npos);
    }
    loader.installed = true;
    loader.loads = false;
    CHECK(p->probe(env_of(d12, GpuVendor::Intel)).reason.find("could not be loaded") != std::string::npos);
    loader.loads = true;
    loader.hidden = {"xellSleep"};
    CHECK(p->probe(env_of(d12, GpuVendor::Intel)).reason.find("xellSleep") != std::string::npos);
    loader.hidden.clear();
    xlfx.version = {0, 9, 0, 0};
    CHECK(p->probe(env_of(d12, GpuVendor::Intel)).reason.find("too old") != std::string::npos);
    xlfx.version = {1, 2, 0, 0};
    xlfx.versionRc = -2;
    {
        const auto r = p->probe(env_of(d12, GpuVendor::Intel));
        CHECK_FALSE(r.available);
        CHECK(r.reason.find("driver is too old") != std::string::npos);
    }
    xlfx.versionRc = 0;
    // A library without the optional report function still works.
    loader.hidden = {"xellGetFramesReports"};
    CHECK(p->probe(env_of(d12, GpuVendor::Intel)).available);
}

TEST_CASE("xell: context, sleep mode, sleep, markers, report") {
    XlLoader loader;
    LoaderGuard lg(&loader);
    xlfx.reset();
    auto p = render::make_xell_provider();
    LDevice dev(gpu::Backend::D3d12, 0x8086);
    REQUIRE(p->probe(env_of(dev, GpuVendor::Intel)).available);
    CHECK(p->start(dev).empty());
    CHECK(xlfx.createdFor == dev.native().device);  // the ID3D12Device of the engine's device
    CHECK(xlfx.events == std::vector<std::string>{"create"});

    p->configure(true, false, 0);
    p->configure(true, true, 4000);
    p->configure(false, true, 0);
    REQUIRE(xlfx.modes.size() == 3);
    CHECK(xlfx.modes[0].flags == 1);  // low latency
    CHECK(xlfx.modes[1].flags == 3);  // low latency and boost
    CHECK(xlfx.modes[1].minimumIntervalUs == 4000);
    CHECK(xlfx.modes[2].flags == 0);  // asleep
    p->sleep(3);
    p->marker(LatencyMarker::SimulationStart, 3);
    CHECK(xlfx.sleeps.empty());  // the SDK is asleep: nothing is called
    CHECK(xlfx.markers.empty());

    p->configure(true, false, 0);
    p->sleep(7);
    CHECK(xlfx.sleeps == std::vector<std::uint32_t>{7});
    const std::pair<LatencyMarker, std::int32_t> order[] = {
        {LatencyMarker::SimulationStart, 0},   {LatencyMarker::InputSample, 6},     {LatencyMarker::SimulationEnd, 1},
        {LatencyMarker::RenderSubmitStart, 2}, {LatencyMarker::RenderSubmitEnd, 3}, {LatencyMarker::PresentStart, 4},
        {LatencyMarker::PresentEnd, 5}};
    for (const auto& o : order) p->marker(o.first, 7);
    REQUIRE(xlfx.markers.size() == 7);
    for (std::size_t i = 0; i < 7; ++i) {
        CHECK(xlfx.markers[i].first == 7);
        CHECK(xlfx.markers[i].second == order[i].second);
    }

    xlfx.reports.assign(3, xl::FrameReport{});
    xlfx.reports[0].frameId = 6;
    xlfx.reports[0].simStart = 1'000'000;
    xlfx.reports[0].presentEnd = 7'000'000;  // 6 ms
    xlfx.reports[1].frameId = 7;
    xlfx.reports[1].simStart = 20'000'000;
    xlfx.reports[1].presentEnd = 28'000'000;  // 8 ms
    const Json report = p->vendor_report();
    CHECK(report["source"] == "XeLL");
    CHECK(report["frames"] == 2);
    CHECK(report["lastFrameId"] == 7);
    CHECK(report["lastSimulationToPresentMs"] == doctest::Approx(8.0));
    CHECK(report["avgSimulationToPresentMs"] == doctest::Approx(7.0));

    p->stop(dev);
    CHECK(xlfx.events.back() == "destroy");
    p->sleep(8);
    CHECK(xlfx.sleeps.size() == 1);
}

TEST_CASE("xell: a context the SDK refuses is a reason, not a device failure") {
    XlLoader loader;
    LoaderGuard lg(&loader);
    xlfx.reset();
    auto p = render::make_xell_provider();
    LDevice dev(gpu::Backend::D3d12, 0x8086);
    REQUIRE(p->probe(env_of(dev, GpuVendor::Intel)).available);
    xlfx.createRc = -1;
    const std::string why = p->start(dev);
    CHECK(why.find("cannot run XeLL") != std::string::npos);
    p->configure(true, false, 0);  // no context: nothing happens
    CHECK(xlfx.modes.empty());
}
