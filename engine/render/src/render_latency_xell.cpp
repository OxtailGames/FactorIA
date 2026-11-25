// The Intel XeLL provider of M78 (render_latency_xell.h).
#include "render_latency_xell.h"

#include <algorithm>
#include <cmath>
#include <mutex>

#include "fa/core/fs.h"
#include "fa/core/log.h"

namespace fa::render {

namespace {

namespace abi = xell_abi;

#if UINTPTR_MAX == 0xFFFFFFFFFFFFFFFFu
static_assert(sizeof(abi::Version) == 8, "xell_version_t");
static_assert(sizeof(abi::SleepParams) == 8, "xell_sleep_params_t");
static_assert(sizeof(abi::FrameReport) == 96, "xell_frame_report_t");
#endif

constexpr unsigned bit(gpu::Backend b) { return 1u << unsigned(b); }

template <class Fn>
void bind(VendorLibrary& lib, const char* name, Fn& fn, std::string& missing, bool optional = false) {
    void* address = lib.symbol(name);
    if (!address) {
        if (!optional && missing.empty()) missing = name;
        return;
    }
    fn = reinterpret_cast<Fn>(address);  // NOLINT: the export's address
}

std::string version_text(const abi::Version& v) {
    return std::to_string(v.major) + "." + std::to_string(v.minor) + "." + std::to_string(v.patch);
}

std::string call_failed(const char* function, std::int32_t result) {
    std::string text =
        std::string(function) + " answered \"" + xell_result_text(result) + "\" (" + std::to_string(result) + ")";
    if (result == -1)
        text += ": this GPU cannot run XeLL";
    else if (result == -2)
        text += ": the installed GPU driver is too old for XeLL; update it";
    return text;
}

double round2(double v) { return std::round(v * 100.0) / 100.0; }

class XellProvider final : public LatencyProvider {
public:
    std::string_view name() const override { return "Intel XeLL"; }
    LatencyDriver driver() const override { return LatencyDriver::Xell; }
    std::string_view setup_id() const override { return "xess"; }
    unsigned backends() const override { return bit(gpu::Backend::D3d12); }

    VendorProbe probe(const VendorEnv& env) override;
    std::string start(gpu::Device& device) override;
    void configure(bool enabled, bool boost, std::uint32_t minIntervalUs) override;
    void sleep(std::uint64_t frameId) override;
    void marker(LatencyMarker marker, std::uint64_t frameId) override;
    Json vendor_report() override;
    void stop(gpu::Device& device) override;

private:
    // Used from the thread that draws (the engine's main thread) only; the probe may come from another, so the library is under the mutex.
    std::mutex mutex_;
    std::unique_ptr<VendorLibrary> lib_;
    XellApi api_{};
    const gpu::Device* device_ = nullptr;
    abi::Context ctx_ = nullptr;
    bool enabled_ = false;
};

VendorProbe XellProvider::probe(const VendorEnv& env) {
    VendorProbe p;
    p.reason = vendor_environment_problem(name(), backends(), env);
    if (p.reason.empty() && sizeof(void*) != 8) p.reason = "XeLL's library is 64-bit; this build is not.";
    if (!p.reason.empty()) {
        if (env.backend == gpu::Backend::Vulkan || env.backend == gpu::Backend::D3d11)
            p.reason += " XeLL has a Direct3D 12 entry point only: run the game on Direct3D 12, or choose another latency mode.";
        return p;
    }
    std::string why;
    const std::filesystem::path found = vendor_loader().find(xell_library_spec(), &why);
    if (found.empty()) {
        p.reason = "XeLL is not installed: run `factoria setup xess` (" + why + ").";
        return p;
    }
    std::unique_ptr<VendorLibrary> lib = vendor_loader().load(found, &why);
    if (!lib) {
        p.reason = "XeLL's library " + fa::fs::path_to_utf8(found) + " could not be loaded: " + why +
                   ". Run `factoria setup xess` to install it again.";
        return p;
    }
    XellApi api;
    if (const std::string missing = xell_load_api(*lib, api); !missing.empty()) {
        p.reason = "XeLL's library " + lib->path() + " has no export " + missing +
                   " (it is not XeLL 1.x): run `factoria setup xess` to install the version FactorIA was tested with.";
        return p;
    }
    abi::Version version{};
    if (const std::int32_t rc = api.getVersion(&version); rc != abi::kResultSuccess) {
        p.reason = "XeLL's library " + lib->path() + " did not answer its version: " + call_failed("xellGetVersion", rc) +
                   ". Run `factoria setup xess` to install it again.";
        return p;
    }
    if (version.major < 1) {
        p.reason = "XeLL " + version_text(version) + " (" + lib->path() +
                   ") is too old: FactorIA needs XeLL 1.0 or newer. Run `factoria setup xess`.";
        return p;
    }
    {
        // The library is kept for the context; one that a live context uses stays (its functions are the ones the context was made with).
        std::lock_guard<std::mutex> lock(mutex_);
        if (!ctx_) {
            lib_ = std::move(lib);
            api_ = api;
        }
    }
    p.available = true;
    return p;
}

std::string XellProvider::start(gpu::Device& device) {
    std::lock_guard<std::mutex> lock(mutex_);
    if (ctx_ && device_ != &device) {
        api_.destroyContext(ctx_);  // the context of a device that went without stop(): it went with the device
        ctx_ = nullptr;
    }
    if (ctx_) return {};
    if (!lib_ || !api_.d3d12Create) return "XeLL's library is not loaded (the probe did not run, or failed)";
    if (device.backend() != gpu::Backend::D3d12) return "XeLL runs on Direct3D 12 only";
    const gpu::NativeDevice nd = device.native();
    abi::Context handle = nullptr;
    const std::int32_t rc = api_.d3d12Create(const_cast<void*>(nd.device), &handle);  // NOLINT: the SDK takes a non-const device
    if (rc != abi::kResultSuccess || !handle) return "XeLL could not make its context: " + call_failed("xellD3D12CreateContext", rc);
    ctx_ = handle;
    device_ = &device;
    enabled_ = false;
    return {};
}

void XellProvider::configure(bool enabled, bool boost, std::uint32_t minIntervalUs) {
    if (!ctx_) return;
    abi::SleepParams params{};
    params.minimumIntervalUs = minIntervalUs;
    params.flags = enabled ? (abi::kFlagLowLatency | (boost ? abi::kFlagBoost : 0u)) : 0u;
    if (const std::int32_t rc = api_.setSleepMode(ctx_, &params); rc != abi::kResultSuccess)
        FA_WARN("render", "XeLL: {}", call_failed("xellSetSleepMode", rc));
    enabled_ = enabled;
}

void XellProvider::sleep(std::uint64_t frameId) {
    if (!ctx_ || !enabled_) return;
    api_.sleep(ctx_, std::uint32_t(frameId));
}

void XellProvider::marker(LatencyMarker m, std::uint64_t frameId) {
    if (!ctx_ || !enabled_) return;
    std::int32_t id = 0;
    switch (m) {
        case LatencyMarker::SimulationStart: id = abi::kMarkerSimulationStart; break;
        case LatencyMarker::SimulationEnd: id = abi::kMarkerSimulationEnd; break;
        case LatencyMarker::InputSample: id = abi::kMarkerInputSample; break;
        case LatencyMarker::RenderSubmitStart: id = abi::kMarkerRenderSubmitStart; break;
        case LatencyMarker::RenderSubmitEnd: id = abi::kMarkerRenderSubmitEnd; break;
        case LatencyMarker::PresentStart: id = abi::kMarkerPresentStart; break;
        case LatencyMarker::PresentEnd: id = abi::kMarkerPresentEnd; break;
    }
    api_.addMarker(ctx_, std::uint32_t(frameId), id);
}

// XeLL's own timestamps of the last frames: the span from the start of the simulation to the end of the present, per frame.
Json XellProvider::vendor_report() {
    if (!ctx_ || !enabled_ || !api_.getFramesReports) return Json();
    abi::FrameReport reports[abi::kReportCount] = {};
    if (api_.getFramesReports(ctx_, reports) != abi::kResultSuccess) return Json();
    double sum = 0, newestMs = 0;
    std::uint32_t newestId = 0;
    int n = 0;
    for (const abi::FrameReport& r : reports) {
        if (r.frameId == 0 || r.simStart == 0 || r.presentEnd <= r.simStart) continue;
        const double ms = double(r.presentEnd - r.simStart) / 1.0e6;
        sum += ms;
        ++n;
        if (r.frameId >= newestId) {
            newestId = r.frameId;
            newestMs = ms;
        }
    }
    if (n == 0) return Json();
    Json j = Json::object();
    j["source"] = "XeLL";
    j["frames"] = n;
    j["lastFrameId"] = newestId;
    j["lastSimulationToPresentMs"] = round2(newestMs);
    j["avgSimulationToPresentMs"] = round2(sum / n);
    return j;
}

void XellProvider::stop(gpu::Device& device) {
    std::lock_guard<std::mutex> lock(mutex_);
    if (!ctx_ || device_ != &device) return;
    api_.destroyContext(ctx_);
    ctx_ = nullptr;
    device_ = nullptr;
    enabled_ = false;
}

}  // namespace

VendorLibrarySpec xell_library_spec() { return {"xess", "FA_XESS_DIR", "libxell.dll"}; }

std::string xell_load_api(VendorLibrary& lib, XellApi& api) {
    XellApi a;
    std::string missing;
    bind(lib, "xellGetVersion", a.getVersion, missing);
    bind(lib, "xellD3D12CreateContext", a.d3d12Create, missing);
    bind(lib, "xellDestroyContext", a.destroyContext, missing);
    bind(lib, "xellSetSleepMode", a.setSleepMode, missing);
    bind(lib, "xellSleep", a.sleep, missing);
    bind(lib, "xellAddMarkerData", a.addMarker, missing);
    bind(lib, "xellGetFramesReports", a.getFramesReports, missing, true);
    if (!missing.empty()) return missing;
    api = a;
    return {};
}

std::string xell_result_text(std::int32_t result) {
    switch (result) {
        case 0: return "success";
        case -1: return "unsupported device";
        case -2: return "unsupported driver";
        case -3: return "uninitialized";
        case -4: return "invalid argument";
        case -6: return "device error";
        case -7: return "not implemented";
        case -8: return "invalid context";
        case -10: return "unsupported";
        case -1000: return "unknown error";
        default: break;
    }
    return "result " + std::to_string(result);
}

std::unique_ptr<LatencyProvider> make_xell_provider() { return std::make_unique<XellProvider>(); }

}  // namespace fa::render
