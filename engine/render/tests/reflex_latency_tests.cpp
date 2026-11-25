// M78-P6b: the NVIDIA Reflex latency provider (src/render_latency_reflex.{h,cpp}) on the Streamline runtime (src/streamline_runtime.{h,cpp}).
// No NVIDIA library is involved: Streamline's functions are fakes in a table the runtime takes from a fake VendorLibrary (the way it takes
// the real ones), the adapter and the COM releases are injected, and the device is a RecordingDevice that answers a backend and a GPU maker.
// What is tested is what the engine asks of Streamline and when: the refusals with their reasons (not installed, not started, another GPU
// maker, Direct3D 11, a driver without Reflex), the options sent once and again only when the mode, the boost or the frame limit changes, the
// sleep once per frame before the input is read, the PCL marker of each engine marker, the one token DLSS and Reflex share, the report parsed
// from the state, and that nothing is called after the device went. That the real driver shortens the latency is for a machine with an NVIDIA GPU.
#include <doctest.h>

#include <algorithm>
#include <cstdint>
#include <cstring>
#include <filesystem>
#include <map>
#include <memory>
#include <string>
#include <vector>

#include "fa/core/json.h"
#include "gpu/device_hooks.h"
#include "gpu/recording_device.h"
#include "render_latency.h"
#include "render_latency_reflex.h"
#include "streamline_runtime.h"

using namespace fa;
using render::GpuVendor;
using render::LatencyDriver;
using render::LatencyMarker;
using render::LatencyMode;
using render::LatencySettings;
namespace sl = fa::render::sl_abi;
using SlR = sl::Result;

namespace {

// ---- the fake library ---------------------------------------------------------------------------------------------------------------

struct Rx {
    // what each function answers
    SlR initRc = 0, supportedRc = 0, tokenRc = 0, optionsRc = 0, stateRc = 0, sleepRc = 0, markerRc = 0;
    std::uint32_t refusedFeature = 0xFFFFFFFFu;  // the feature slIsFeatureSupported refuses (with supportedRc)
    bool lowLatencyAvailable = true, reportAvailable = true;
    std::vector<sl::ReflexReport> reports;  // what slReflexGetState hands over
    // what happened
    std::vector<std::string> events;  // "init", "token", "options", "sleep", "marker"
    std::vector<sl::ReflexOptions> options;
    std::vector<void*> sleepTokens;
    std::vector<std::pair<std::uint32_t, void*>> markers;
    int tokenCalls = 0, getStateCalls = 0, shutdowns = 0;
    int tokenMarker = 0, deviceMarker = 0, proxyDevice = 0, factoryMarker = 0, proxyFactory = 0, adapterMarker = 0;
    void reset() { *this = Rx{}; }
};
Rx rx;

SlR f_init(const sl::Preferences*, std::uint64_t) {
    rx.events.push_back("init");
    return rx.initRc;
}
SlR f_shutdown() {
    ++rx.shutdowns;
    return 0;
}
SlR f_supported(std::uint32_t feature, const sl::AdapterInfo*) {
    return feature == rx.refusedFeature ? rx.supportedRc : 0;
}
SlR f_free(std::uint32_t, const sl::ViewportHandle*) { return 0; }
SlR f_upgrade(void** p) {
    if (*p == &rx.deviceMarker) *p = &rx.proxyDevice;
    if (*p == &rx.factoryMarker) *p = &rx.proxyFactory;
    return 0;
}
SlR f_set_d3d(void*) { return 0; }
SlR f_token(void** token, const std::uint32_t*) {
    ++rx.tokenCalls;
    rx.events.push_back("token");
    if (rx.tokenRc != 0) return rx.tokenRc;
    *token = &rx.tokenMarker;
    return 0;
}
SlR f_reflex_options(const sl::ReflexOptions* o) {
    rx.events.push_back("options");
    rx.options.push_back(*o);
    return rx.optionsRc;
}
SlR f_reflex_state(sl::ReflexState* s) {
    ++rx.getStateCalls;
    if (rx.stateRc != 0) return rx.stateRc;
    s->lowLatencyAvailable = rx.lowLatencyAvailable;
    s->latencyReportAvailable = rx.reportAvailable;
    for (std::size_t i = 0; i < rx.reports.size() && i < std::size_t(sl::kReflexFrameReportCount); ++i)
        s->frameReport[i] = rx.reports[i];
    return 0;
}
SlR f_reflex_sleep(void* frame) {
    rx.events.push_back("sleep");
    rx.sleepTokens.push_back(frame);
    return rx.sleepRc;
}
SlR f_pcl_marker(std::uint32_t marker, void* frame) {
    rx.events.push_back("marker");
    rx.markers.emplace_back(marker, frame);
    return rx.markerRc;
}
std::vector<std::string> g_hiddenFunctions;
SlR f_function(std::uint32_t feature, const char* name, void** fn) {
    const std::string n = name;
    if (std::find(g_hiddenFunctions.begin(), g_hiddenFunctions.end(), n) != g_hiddenFunctions.end())
        return sl::kErrorFeatureMissing;
    if (n == "slReflexSetOptions" && feature == sl::kFeatureReflex)
        *fn = reinterpret_cast<void*>(&f_reflex_options);
    else if (n == "slReflexGetState" && feature == sl::kFeatureReflex)
        *fn = reinterpret_cast<void*>(&f_reflex_state);
    else if (n == "slReflexSleep" && feature == sl::kFeatureReflex)
        *fn = reinterpret_cast<void*>(&f_reflex_sleep);
    else if (n == "slPCLSetMarker" && feature == sl::kFeaturePcl)
        *fn = reinterpret_cast<void*>(&f_pcl_marker);
    else
        return sl::kErrorFeatureMissing;
    return 0;
}

class FakeLibrary final : public render::VendorLibrary {
public:
    FakeLibrary() {
        table_["slInit"] = reinterpret_cast<void*>(&f_init);
        table_["slShutdown"] = reinterpret_cast<void*>(&f_shutdown);
        table_["slIsFeatureSupported"] = reinterpret_cast<void*>(&f_supported);
        table_["slFreeResources"] = reinterpret_cast<void*>(&f_free);
        table_["slUpgradeInterface"] = reinterpret_cast<void*>(&f_upgrade);
        table_["slGetFeatureFunction"] = reinterpret_cast<void*>(&f_function);
        table_["slGetNewFrameToken"] = reinterpret_cast<void*>(&f_token);
        table_["slSetD3DDevice"] = reinterpret_cast<void*>(&f_set_d3d);
        // The functions the runtime asks of a library that DLSS alone uses; Reflex never calls them.
        table_["slSetTagForFrame"] = reinterpret_cast<void*>(&f_free);
        table_["slSetConstants"] = reinterpret_cast<void*>(&f_free);
        table_["slGetFeatureRequirements"] = reinterpret_cast<void*>(&f_free);
        table_["slAllocateResources"] = reinterpret_cast<void*>(&f_free);
        table_["slEvaluateFeature"] = reinterpret_cast<void*>(&f_free);
        table_["slSetVulkanInfo"] = reinterpret_cast<void*>(&f_free);
        table_["vkGetInstanceProcAddr"] = reinterpret_cast<void*>(&f_free);
        table_["vkGetDeviceProcAddr"] = reinterpret_cast<void*>(&f_free);
    }
    void* symbol(const char* name) override {
        const auto it = table_.find(name);
        return it == table_.end() ? nullptr : it->second;
    }
    const std::string& path() const override { return path_; }

private:
    std::map<std::string, void*> table_;
    std::string path_ = "fake/sl.interposer.dll";
};

class FakeLoader final : public render::VendorLoader {
public:
    bool installed = true;
    std::filesystem::path find(const render::VendorLibrarySpec& spec, std::string* why) override {
        if (!installed) {
            if (why) *why = "the fake loader has no library";
            return {};
        }
        return std::filesystem::path("fake") / spec.fileName;
    }
    std::unique_ptr<render::VendorLibrary> load(const std::filesystem::path&, std::string*) override {
        return std::make_unique<FakeLibrary>();
    }
};

struct LoaderGuard {
    explicit LoaderGuard(render::VendorLoader* l) { render::set_vendor_loader_for_test(l); }
    ~LoaderGuard() { render::set_vendor_loader_for_test(nullptr); }
    LoaderGuard(const LoaderGuard&) = delete;
    LoaderGuard& operator=(const LoaderGuard&) = delete;
};

struct AdapterFx {
    std::vector<void*> released;
};
render::StreamlineHost make_host(AdapterFx& a) {
    render::StreamlineHost h;
    h.readAdapter = [](const void*, render::StreamlineAdapter& out) {
        out.vendorId = 0x10DE;
        out.hasLuid = true;
        for (int i = 0; i < 8; ++i) out.luid[i] = std::uint8_t(i + 1);
        out.name = "Fake RTX";
        return true;
    };
    h.releaseCom = [&a](void* o) { a.released.push_back(o); };
    return h;
}

// The features the process's runtime asks for.
std::vector<std::uint32_t> all_features() { return {sl::kFeatureDlss, sl::kFeatureReflex, sl::kFeaturePcl}; }

void run_d3d12(render::StreamlineRuntime& rt) {
    gpu::D3d12BeforeDevice before;
    before.factory = &rx.factoryMarker;
    before.adapter = &rx.adapterMarker;
    rt.d3d12_before_device(before);
    gpu::D3d12DeviceCreated c;
    c.factory = &rx.factoryMarker;
    c.device = &rx.deviceMarker;
    c.adapter = &rx.adapterMarker;
    rt.d3d12_device_created(c);
}

// A device of the backend and the maker asked for.
class RDevice : public gpu::RecordingDevice {
public:
    RDevice(gpu::Backend deviceBackend, std::uint32_t pciVendor) : backend_(deviceBackend) {
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

render::VendorEnv env_of(const RDevice& d, GpuVendor vendor, bool windows = true) {
    render::VendorEnv e;
    e.backend = d.backend();
    e.vendor = vendor;
    e.device = &d;
    e.windows = windows;
    return e;
}

// The runtime of a test, made ready on a D3D12 device, and put in place of the process's.
struct Rig {
    FakeLoader loader;
    LoaderGuard guard{&loader};
    AdapterFx adapter;
    render::StreamlineRuntime runtime{all_features(), make_host(adapter)};
    RDevice dev{gpu::Backend::D3d12, 0x10DE};
    std::unique_ptr<render::LatencyProvider> reflex = render::make_reflex_provider();

    explicit Rig(bool ready = true) {
        rx.reset();
        g_hiddenFunctions.clear();
        render::reset_reflex_running_for_test();  // reflex_running() is the process's: no case reads what another left
        render::set_streamline_runtime_for_test(&runtime);
        if (ready) run_d3d12(runtime);
    }
    ~Rig() {
        render::reset_reflex_running_for_test();
        render::set_streamline_runtime_for_test(nullptr);
        g_hiddenFunctions.clear();
    }
    Rig(const Rig&) = delete;
    Rig& operator=(const Rig&) = delete;

    render::VendorEnv env() const { return env_of(dev, GpuVendor::Nvidia); }
};

struct ClockGuard {
    // A clock that never moves: the controller reads it for the readout and for its own pacing (which Reflex replaces).
    class FixedClock final : public render::LatencyClock {
    public:
        double t = 1000.0;
        double now_ms() override { return t; }
        void sleep_until_ms(double target) override { t = std::max(t, target); }
    };
    FixedClock clock;
    ClockGuard() { render::set_latency_clock_for_test(&clock); }
    ~ClockGuard() { render::set_latency_clock_for_test(nullptr); }
    ClockGuard(const ClockGuard&) = delete;
    ClockGuard& operator=(const ClockGuard&) = delete;
};

LatencySettings settings(LatencyMode m, bool boost = false) {
    LatencySettings s;
    s.mode = m;
    s.boost = boost;
    return s;
}

bool has(const std::string& text, const char* part) { return text.find(part) != std::string::npos; }

sl::ReflexReport report_of(std::uint64_t frameId, std::uint64_t simStart, std::uint64_t presentEnd,
                           std::uint32_t gpuFrameUs = 0) {
    sl::ReflexReport r{};
    r.frameId = frameId;
    r.simStartTime = simStart;
    r.presentEndTime = presentEnd;
    r.gpuFrameTimeUs = gpuFrameUs;
    return r;
}

}  // namespace

// ---- the slot --------------------------------------------------------------------------------------------------------------------------

TEST_CASE("reflex: the build's provider fills the Reflex slot, and the ABI is the size Streamline 2.14.16 has") {
    render::LatencyProvider* p = render::latency_provider(LatencyDriver::Reflex);
    REQUIRE(p != nullptr);
    CHECK(p->name() == "NVIDIA Reflex");
    CHECK(p->driver() == LatencyDriver::Reflex);
    CHECK(p->setup_id() == "streamline");
    CHECK((p->backends() & (1u << unsigned(gpu::Backend::D3d12))) != 0);
    CHECK((p->backends() & (1u << unsigned(gpu::Backend::Vulkan))) != 0);
    CHECK((p->backends() & (1u << unsigned(gpu::Backend::D3d11))) == 0);
    CHECK(sizeof(sl::ReflexOptions) == 48);
    CHECK(sizeof(sl::ReflexState) == 12848);
}

TEST_CASE("reflex: the engine's markers become the PCL markers; the input sample is Reflex's own to find") {
    CHECK(render::reflex_pcl_marker(LatencyMarker::SimulationStart) == 0);
    CHECK(render::reflex_pcl_marker(LatencyMarker::SimulationEnd) == 1);
    CHECK(render::reflex_pcl_marker(LatencyMarker::RenderSubmitStart) == 2);
    CHECK(render::reflex_pcl_marker(LatencyMarker::RenderSubmitEnd) == 3);
    CHECK(render::reflex_pcl_marker(LatencyMarker::PresentStart) == 4);
    CHECK(render::reflex_pcl_marker(LatencyMarker::PresentEnd) == 5);
    CHECK(render::reflex_pcl_marker(LatencyMarker::InputSample) == -1);
}

// ---- probe -----------------------------------------------------------------------------------------------------------------------------

TEST_CASE("reflex probe: usable on an NVIDIA GPU with Streamline started on the same backend") {
    Rig r;
    const render::VendorProbe p = r.reflex->probe(r.env());
    CHECK(p.available);
    CHECK(p.reason.empty());
}

TEST_CASE("reflex probe: every refusal says what to do") {
    SUBCASE("another GPU maker") {
        Rig r;
        const render::VendorProbe p = r.reflex->probe(env_of(r.dev, GpuVendor::Amd));
        CHECK_FALSE(p.available);
        CHECK(has(p.reason, "needs an NVIDIA GPU"));
        CHECK(has(p.reason, "auto"));
    }
    SUBCASE("not Windows") {
        Rig r;
        const render::VendorProbe p = r.reflex->probe(env_of(r.dev, GpuVendor::Nvidia, false));
        CHECK_FALSE(p.available);
        CHECK(has(p.reason, "Windows only"));
    }
    SUBCASE("Direct3D 11 is not a device Streamline hooks") {
        Rig r;
        RDevice d11(gpu::Backend::D3d11, 0x10DE);
        const render::VendorProbe p = r.reflex->probe(env_of(d11, GpuVendor::Nvidia));
        CHECK_FALSE(p.available);
        CHECK(has(p.reason, "Direct3D 12"));
        CHECK(has(p.reason, "Vulkan"));
    }
    SUBCASE("Streamline is not installed") {
        Rig r(false);
        r.loader.installed = false;
        const render::VendorProbe p = r.reflex->probe(r.env());
        CHECK_FALSE(p.available);
        CHECK(has(p.reason, "factoria setup streamline"));
        CHECK_FALSE(has(p.reason, "arrives with"));
    }
    SUBCASE("Streamline is installed but did not see the device") {
        Rig r(false);
        const render::VendorProbe p = r.reflex->probe(r.env());
        CHECK_FALSE(p.available);
        CHECK(has(p.reason, "restart"));
    }
    SUBCASE("Streamline did not start") {
        Rig r(false);
        rx.initRc = sl::kErrorDriverOutOfDate;
        run_d3d12(r.runtime);
        const render::VendorProbe p = r.reflex->probe(r.env());
        CHECK_FALSE(p.available);
        CHECK(has(p.reason, "slInit"));
    }
    SUBCASE("Streamline started for another backend") {
        Rig r;
        RDevice vk(gpu::Backend::Vulkan, 0x10DE);
        const render::VendorProbe p = r.reflex->probe(env_of(vk, GpuVendor::Nvidia));
        CHECK_FALSE(p.available);
        CHECK(has(p.reason, "started for D3D12"));
    }
    SUBCASE("Streamline says the Reflex plugin is not supported here") {
        Rig r(false);
        rx.refusedFeature = sl::kFeatureReflex;
        rx.supportedRc = sl::kErrorFeatureNotSupported;
        run_d3d12(r.runtime);
        REQUIRE(r.runtime.status().ready);  // DLSS still runs
        const render::VendorProbe p = r.reflex->probe(r.env());
        CHECK_FALSE(p.available);
        CHECK(has(p.reason, "NVIDIA Reflex is not available on this machine"));
    }
    SUBCASE("a plugin Streamline has no function of") {
        Rig r;
        g_hiddenFunctions = {"slReflexSleep"};
        const render::VendorProbe p = r.reflex->probe(r.env());
        CHECK_FALSE(p.available);
        CHECK(has(p.reason, "slGetFeatureFunction(slReflexSleep)"));
    }
    SUBCASE("a driver without Reflex Low Latency") {
        Rig r;
        rx.lowLatencyAvailable = false;
        const render::VendorProbe p = r.reflex->probe(r.env());
        CHECK_FALSE(p.available);
        CHECK(has(p.reason, "Reflex Low Latency is not available"));
        CHECK(has(p.reason, "driver"));
    }
    SUBCASE("slReflexGetState refuses") {
        Rig r;
        rx.stateRc = sl::kErrorInvalidState;
        const render::VendorProbe p = r.reflex->probe(r.env());
        CHECK_FALSE(p.available);
        CHECK(has(p.reason, "slReflexGetState"));
    }
}

// ---- start and configure ---------------------------------------------------------------------------------------------------------------

TEST_CASE("reflex: start sets the options off once; configure sends the mode, the boost and the frame limit only when "
          "they change") {
    Rig r;
    REQUIRE(r.reflex->start(r.dev).empty());
    REQUIRE(rx.options.size() == 1);
    CHECK(rx.options[0].mode == sl::kReflexOff);
    CHECK(rx.options[0].frameLimitUs == 0);
    CHECK(rx.options[0].base.version == 1);

    r.reflex->configure(true, false, 0);
    REQUIRE(rx.options.size() == 2);
    CHECK(rx.options[1].mode == sl::kReflexLowLatency);
    r.reflex->configure(true, false, 0);  // the same: nothing
    CHECK(rx.options.size() == 2);
    r.reflex->configure(true, true, 0);
    REQUIRE(rx.options.size() == 3);
    CHECK(rx.options[2].mode == sl::kReflexLowLatencyBoost);
    r.reflex->configure(true, true, 8333);
    REQUIRE(rx.options.size() == 4);
    CHECK(rx.options[3].frameLimitUs == 8333);
    CHECK_FALSE(rx.options[3].useMarkersToOptimize);
    r.reflex->configure(false, true, 8333);  // asleep: off, and no frame limit
    REQUIRE(rx.options.size() == 5);
    CHECK(rx.options[4].mode == sl::kReflexOff);
    CHECK(rx.options[4].frameLimitUs == 0);
    r.reflex->configure(false, false, 0);
    CHECK(rx.options.size() == 5);

    r.reflex->configure(true, false, 0);
    REQUIRE(rx.options.size() == 6);
    r.reflex->stop(r.dev);  // Reflex back to off
    REQUIRE(rx.options.size() == 7);
    CHECK(rx.options[6].mode == sl::kReflexOff);
    r.reflex->configure(true, false, 0);  // after stop: nothing is called
    r.reflex->sleep(1);
    CHECK(rx.options.size() == 7);
    CHECK(rx.sleepTokens.empty());
}

TEST_CASE("reflex: start says why it cannot") {
    SUBCASE("Streamline never started") {
        Rig r(false);
        CHECK(has(r.reflex->start(r.dev), "factoria setup streamline"));
        CHECK(rx.options.empty());
    }
    SUBCASE("a device of another backend") {
        Rig r;
        RDevice d11(gpu::Backend::D3d11, 0x10DE);
        CHECK(has(r.reflex->start(d11), "Direct3D 12 and Vulkan"));
    }
    SUBCASE("the driver has no Reflex") {
        Rig r;
        rx.lowLatencyAvailable = false;
        CHECK(has(r.reflex->start(r.dev), "Reflex Low Latency is not available"));
        CHECK(rx.options.empty());
    }
    SUBCASE("slReflexSetOptions refuses: Reflex stays off, the game goes on") {
        Rig r;
        rx.optionsRc = sl::kErrorInvalidState;
        CHECK(r.reflex->start(r.dev).empty());
        r.reflex->configure(true, false, 0);  // asked again at each change, never an abort
        CHECK(rx.options.size() == 2);
    }
}

// ---- sleep and markers -----------------------------------------------------------------------------------------------------------------

TEST_CASE("reflex: sleep and markers carry the frame's token, taken once") {
    Rig r;
    REQUIRE(r.reflex->start(r.dev).empty());
    r.reflex->configure(true, false, 0);
    rx.events.clear();
    r.reflex->sleep(1);
    r.reflex->marker(LatencyMarker::SimulationStart, 1);
    r.reflex->marker(LatencyMarker::InputSample, 1);  // Reflex finds the input itself
    r.reflex->marker(LatencyMarker::SimulationEnd, 1);
    r.reflex->marker(LatencyMarker::RenderSubmitStart, 1);
    r.reflex->marker(LatencyMarker::RenderSubmitEnd, 1);
    r.reflex->marker(LatencyMarker::PresentStart, 1);
    r.reflex->marker(LatencyMarker::PresentEnd, 1);
    CHECK(rx.tokenCalls == 1);
    REQUIRE(rx.sleepTokens.size() == 1);
    CHECK(rx.sleepTokens[0] == &rx.tokenMarker);
    REQUIRE(rx.markers.size() == 6);
    for (std::size_t i = 0; i < rx.markers.size(); ++i) {
        CAPTURE(i);
        CHECK(rx.markers[i].first == std::uint32_t(i));
        CHECK(rx.markers[i].second == &rx.tokenMarker);
    }
    CHECK(rx.events.front() == "token");
    CHECK(rx.events[1] == "sleep");

    // The next frame: a new id, a new token ask (the runtime hands the same token while no present went by).
    r.reflex->sleep(2);
    CHECK(rx.sleepTokens.size() == 2);
}

TEST_CASE("reflex: a PCL plugin that is missing leaves Reflex sleeping without markers") {
    Rig r;
    g_hiddenFunctions = {"slPCLSetMarker"};
    REQUIRE(r.reflex->start(r.dev).empty());
    r.reflex->configure(true, false, 0);
    r.reflex->sleep(1);
    r.reflex->marker(LatencyMarker::SimulationStart, 1);
    r.reflex->marker(LatencyMarker::PresentEnd, 1);
    CHECK(rx.sleepTokens.size() == 1);
    CHECK(rx.markers.empty());
}

TEST_CASE("reflex: a refused token or sleep warns once and never stops the frame") {
    Rig r;
    REQUIRE(r.reflex->start(r.dev).empty());
    rx.tokenRc = sl::kErrorInvalidState;
    r.reflex->sleep(1);
    r.reflex->marker(LatencyMarker::SimulationStart, 1);
    CHECK(rx.sleepTokens.empty());
    CHECK(rx.markers.empty());
    rx.tokenRc = 0;
    rx.sleepRc = sl::kErrorInvalidState;
    r.reflex->sleep(2);
    r.reflex->sleep(3);
    CHECK(rx.sleepTokens.size() == 2);
}

TEST_CASE("reflex: DLSS and Reflex get the same token for a frame") {
    Rig r;
    REQUIRE(r.reflex->start(r.dev).empty());
    std::uint32_t index = 99;
    std::string why;
    void* dlss = r.runtime.frame_token(&index, &why);  // what the DLSS provider asks
    r.reflex->sleep(1);
    CHECK(rx.tokenCalls == 1);
    REQUIRE(rx.sleepTokens.size() == 1);
    CHECK(rx.sleepTokens[0] == dlss);
    gpu::PresentEvent e;
    e.backend = gpu::Backend::D3d12;
    e.frame = 1;
    r.runtime.present_end(e);  // the next frame asks Streamline again
    r.reflex->sleep(2);
    CHECK(rx.tokenCalls == 2);
}

// ---- the controller --------------------------------------------------------------------------------------------------------------------

TEST_CASE("reflex through the controller: auto on NVIDIA picks Reflex, which sleeps once per frame before the input") {
    ClockGuard clock;
    Rig r;
    render::LatencyController c;
    c.attach(&r.dev, r.env(), true);
    CHECK(c.provider_reason(LatencyDriver::Reflex).empty());
    c.set_settings(settings(LatencyMode::Auto, true));
    REQUIRE(c.driver() == LatencyDriver::Reflex);
    REQUIRE_FALSE(rx.options.empty());
    CHECK(rx.options.back().mode == sl::kReflexLowLatencyBoost);
    rx.events.clear();
    rx.sleepTokens.clear();
    rx.markers.clear();

    for (int frame = 0; frame < 3; ++frame) {
        c.frame_begin(0.0);
        c.mark(LatencyMarker::InputSample);
        c.mark(LatencyMarker::SimulationEnd);
        c.mark(LatencyMarker::RenderSubmitStart);
        c.mark(LatencyMarker::RenderSubmitEnd);
        c.mark(LatencyMarker::PresentStart);
        c.mark(LatencyMarker::PresentEnd);
        gpu::PresentEvent e;
        e.backend = gpu::Backend::D3d12;
        e.frame = std::uint64_t(frame + 1);
        r.runtime.present_end(e);
    }
    CHECK(rx.sleepTokens.size() == 3);  // once per frame
    CHECK(rx.markers.size() == 3 * 6);  // the input sample has no PCL marker
    CHECK(rx.tokenCalls == 3);          // one token per frame, shared by the sleep and the markers
    // Within each frame the sleep is the first call after the token, then the simulation start.
    std::size_t sleeps = 0;
    for (std::size_t i = 0; i + 1 < rx.events.size(); ++i)
        if (rx.events[i] == "sleep") {
            ++sleeps;
            CHECK(rx.events[i + 1] == "marker");
            CHECK(rx.markers.at(sleeps == 1 ? 0 : 6 * (sleeps - 1)).first == sl::kPclSimulationStart);
        }
    CHECK(sleeps == 3);

    // A change of the setting reconfigures; off puts Reflex to sleep and stops asking it for anything.
    const std::size_t optionsBefore = rx.options.size();
    c.set_settings(settings(LatencyMode::Auto, false));
    REQUIRE(rx.options.size() > optionsBefore);
    CHECK(rx.options.back().mode == sl::kReflexLowLatency);
    c.set_settings(settings(LatencyMode::Off));
    CHECK(rx.options.back().mode == sl::kReflexOff);
    const std::size_t sleepsBefore = rx.sleepTokens.size();
    c.frame_begin(0.0);
    CHECK(rx.sleepTokens.size() == sleepsBefore);
    c.detach();
}

TEST_CASE(
    "reflex through the controller: auto on NVIDIA without Streamline is the engine's own pacing, with the reason") {
    ClockGuard clock;
    Rig r(false);
    r.loader.installed = false;
    render::LatencyController c;
    c.attach(&r.dev, r.env(), true);
    c.set_settings(settings(LatencyMode::Auto));
    CHECK(c.driver() == LatencyDriver::Pacing);
    const std::string why = c.provider_reason(LatencyDriver::Reflex);
    CHECK(has(why, "factoria setup streamline"));
    CHECK_FALSE(has(why, "arrives with"));
    c.detach();
}

TEST_CASE("reflex through the controller: a device that goes stops every call into Streamline") {
    ClockGuard clock;
    Rig r;
    render::LatencyController c;
    c.attach(&r.dev, r.env(), true);
    c.set_settings(settings(LatencyMode::Reflex));
    REQUIRE(c.driver() == LatencyDriver::Reflex);
    c.frame_begin(0.0);
    const std::size_t sleeps = rx.sleepTokens.size();
    const std::size_t markers = rx.markers.size();
    const std::size_t options = rx.options.size();
    const int tokens = rx.tokenCalls;

    r.runtime.device_destroying();  // Streamline shuts down with the device
    CHECK(rx.shutdowns == 1);
    c.frame_begin(0.0);
    c.mark(LatencyMarker::PresentEnd);
    c.set_settings(settings(LatencyMode::Auto, true));
    c.set_settings(settings(LatencyMode::Off));
    c.detach();
    CHECK(rx.sleepTokens.size() == sleeps);
    CHECK(rx.markers.size() == markers);
    CHECK(rx.options.size() == options);  // not even the "off" of stop(): the library is gone
    CHECK(rx.tokenCalls == tokens);
}

// ---- the report ------------------------------------------------------------------------------------------------------------------------

TEST_CASE("reflex: the vendor report is the span from simulation start to present end, in milliseconds") {
    Rig r;
    REQUIRE(r.reflex->start(r.dev).empty());
    CHECK(r.reflex->vendor_report().is_null());  // Reflex off: nothing to report
    r.reflex->configure(true, false, 0);
    CHECK(r.reflex->vendor_report().is_null());  // no frame measured yet

    rx.reports = {report_of(10, 1000, 9000, 4000),   // 8 ms
                  report_of(11, 2000, 12000, 6000),  // 10 ms
                  report_of(0, 0, 0),                // an empty slot
                  report_of(12, 5000, 5000),         // never presented
                  report_of(13, 0, 9000)};           // no simulation start
    const Json j = r.reflex->vendor_report();
    REQUIRE(j.is_object());
    CHECK(j["source"].get<std::string>() == "Reflex");
    CHECK(j["frames"].get<int>() == 2);
    CHECK(j["lastFrameId"].get<int>() == 11);
    CHECK(j["lastSimulationToPresentMs"].get<double>() == doctest::Approx(10.0));
    CHECK(j["avgSimulationToPresentMs"].get<double>() == doctest::Approx(9.0));
    CHECK(j["avgGpuFrameMs"].get<double>() == doctest::Approx(5.0));

    rx.reportAvailable = false;
    CHECK(r.reflex->vendor_report().is_null());
    rx.reportAvailable = true;
    rx.stateRc = sl::kErrorInvalidState;
    CHECK(r.reflex->vendor_report().is_null());
}
