// The NVIDIA Reflex provider of M78 (render_latency_reflex.h).
#include "render_latency_reflex.h"

#include <algorithm>
#include <atomic>
#include <cmath>
#include <initializer_list>
#include <memory>
#include <type_traits>

#include "fa/core/log.h"

namespace fa::render {

namespace {

namespace abi = sl_abi;

// Whether the Reflex provider has Reflex on (Low Latency or Boost) and sends the markers: DLSS frame generation reads it (reflex_running).
std::atomic<bool> g_reflexRunning{false};

constexpr unsigned bit(gpu::Backend b) { return 1u << unsigned(b); }

double round2(double v) { return std::round(v * 100.0) / 100.0; }

// The reasons the setup is to blame for end with the command that fixes it.
constexpr const char* kSetupHint = "run `factoria setup streamline` to install it";

class ReflexProvider final : public LatencyProvider {
public:
    std::string_view name() const override { return "NVIDIA Reflex"; }
    LatencyDriver driver() const override { return LatencyDriver::Reflex; }
    std::string_view setup_id() const override { return "streamline"; }
    unsigned backends() const override { return bit(gpu::Backend::D3d12) | bit(gpu::Backend::Vulkan); }

    VendorProbe probe(const VendorEnv& env) override;
    std::string start(gpu::Device& device) override;
    void configure(bool enabled, bool boost, std::uint32_t minIntervalUs) override;
    void sleep(std::uint64_t frameId) override;
    void marker(LatencyMarker m, std::uint64_t frameId) override;
    Json vendor_report() override;
    void stop(gpu::Device& device) override;

private:
    // Used from the thread that draws (the engine's main thread) only: nothing here is locked, and slReflexSetOptions and slReflexGetState,
    // which Streamline says are not thread safe, are called from it alone.
    bool live(const StreamlineRuntime& runtime) const { return device_ && runtime.ready_generation() == generation_; }
    void* token_for(StreamlineRuntime& runtime, std::uint64_t frameId);
    void send_options(std::uint32_t mode, std::uint32_t frameLimitUs);
    void forget();

    const gpu::Device* device_ = nullptr;
    std::uint64_t generation_ = 0;  // the Streamline set-up the functions below belong to
    ReflexApi api_{};
    bool haveOptions_ = false;
    std::uint32_t mode_ = abi::kReflexOff, frameLimitUs_ = 0;  // the last options sent
    void* token_ = nullptr;                                    // the token of tokenFrame_
    std::uint64_t tokenFrame_ = 0;
    bool warnedSleep_ = false, warnedMarker_ = false, warnedOptions_ = false, warnedToken_ = false;
    std::unique_ptr<abi::ReflexState> state_;  // 12.8 KB: kept for the report
};

VendorProbe ReflexProvider::probe(const VendorEnv& env) {
    VendorProbe p;
    p.reason = vendor_environment_problem(name(), backends(), env);
    if (p.reason.empty() && env.vendor != GpuVendor::Nvidia)
        p.reason = "NVIDIA Reflex needs an NVIDIA GPU; this GPU is " + vendor_describe_gpu(env.vendor) +
                   ". Choose \"auto\", which uses the SDK of the GPU's maker, or another mode.";
    if (!p.reason.empty()) {
        if (env.backend == gpu::Backend::D3d11)
            p.reason +=
                " FactorIA starts Streamline on Direct3D 12 and Vulkan devices only: run the game on one of them, or "
                "choose another latency mode.";
        return p;
    }

    StreamlineRuntime& runtime = streamline_runtime();
    const StreamlineStatus status = runtime.status();
    if (!status.ready) {
        if (status.tried) {
            p.reason =
                status.reason.empty() ? "NVIDIA Streamline did not start with the graphics device." : status.reason;
            return p;
        }
        // Streamline never saw this device: say whether the library is there, which is what the user can do something about.
        std::string why;
        const VendorLibrarySpec spec{"streamline", "FA_STREAMLINE_DIR", "sl.interposer.dll"};
        if (vendor_loader().find(spec, &why).empty())
            p.reason = std::string("NVIDIA Streamline (Reflex) is not installed: ") + kSetupHint + " (" + why + ").";
        else
            p.reason = "NVIDIA Streamline is installed, but it was not started when the graphics device was made (the "
                       "renderer starts it "
                       "before it makes a Direct3D 12 or Vulkan device): restart the game.";
        return p;
    }
    if (status.backend != env.backend) {
        p.reason = std::string("NVIDIA Streamline was started for ") + vendor_backend_label(status.backend) +
                   " and this device is " + vendor_backend_label(env.backend) + ".";
        return p;
    }
    if (const std::string why = runtime.feature_reason(abi::kFeatureReflex); !why.empty()) {
        p.reason = "NVIDIA Reflex is not available on this machine: " + why;
        return p;
    }
    // The driver's own answer: Reflex Low Latency needs a GeForce 900 series or newer and a driver from late 2020.
    ReflexApi api;
    const StreamlineApi* sl = runtime.api();
    if (!sl) {
        p.reason = "NVIDIA Streamline is not running on this device.";
        return p;
    }
    if (const std::string missing = reflex_load_api(*sl, false, api); !missing.empty()) {
        p.reason = missing;
        return p;
    }
    auto state = std::make_unique<abi::ReflexState>();
    abi::init_reflex_state(*state);
    if (const abi::Result r = api.getState(state.get()); r != abi::kOk) {
        p.reason = streamline_refusal("slReflexGetState", r);
        return p;
    }
    if (!state->lowLatencyAvailable) {
        p.reason = "the NVIDIA driver says Reflex Low Latency is not available on this GPU (it needs a GeForce GTX 900 "
                   "series or newer and "
                   "driver 456.38 or newer). Update the NVIDIA graphics driver, or choose another latency mode.";
        return p;
    }
    p.available = true;
    return p;
}

std::string ReflexProvider::start(gpu::Device& device) {
    forget();  // what an earlier device left (its Streamline is gone with it)
    StreamlineRuntime& runtime = streamline_runtime();
    const std::uint64_t generation = runtime.ready_generation();
    const StreamlineStatus status = runtime.status();
    if (generation == 0)
        return status.reason.empty()
                   ? std::string("NVIDIA Streamline is not running on this device (") + kSetupHint + ")"
                   : status.reason;
    if (device.backend() != gpu::Backend::D3d12 && device.backend() != gpu::Backend::Vulkan)
        return "NVIDIA Reflex runs on Direct3D 12 and Vulkan";
    if (status.backend != device.backend())
        return std::string("NVIDIA Streamline was started for ") + vendor_backend_label(status.backend) +
               ", not for this device";
    if (const std::string why = runtime.feature_reason(abi::kFeatureReflex); !why.empty())
        return "NVIDIA Reflex is not available: " + why;
    const StreamlineApi* sl = runtime.api();
    if (!sl) return "NVIDIA Streamline is not running on this device";
    ReflexApi api;
    // The PC latency markers ride on the PCL plugin; without it Reflex still sleeps, only the driver gets no markers.
    const bool withPcl = runtime.feature_reason(abi::kFeaturePcl).empty();
    if (std::string why = reflex_load_api(*sl, withPcl, api); !why.empty()) return why;

    auto state = std::make_unique<abi::ReflexState>();
    abi::init_reflex_state(*state);
    if (const abi::Result r = api.getState(state.get()); r != abi::kOk)
        return streamline_refusal("slReflexGetState", r);
    if (!state->lowLatencyAvailable)
        return "the NVIDIA driver says Reflex Low Latency is not available on this GPU (update the NVIDIA graphics "
               "driver)";

    api_ = api;
    state_ = std::move(state);
    device_ = &device;
    generation_ = generation;
    // slReflexSetOptions has to be called once even when Reflex is off: the options start at off.
    send_options(abi::kReflexOff, 0);
    return {};
}

void ReflexProvider::send_options(std::uint32_t mode, std::uint32_t frameLimitUs) {
    if (haveOptions_ && mode == mode_ && frameLimitUs == frameLimitUs_) return;
    abi::ReflexOptions options;
    abi::init_reflex_options(options);
    options.mode = mode;
    options.frameLimitUs = frameLimitUs;
    options.useMarkersToOptimize = false;  // Streamline: for specific scenarios only
    const abi::Result r = api_.setOptions(&options);
    if (r != abi::kOk) {
        if (!warnedOptions_) FA_WARN("render", "Reflex: {}", streamline_refusal("slReflexSetOptions", r));
        warnedOptions_ = true;
        return;
    }
    haveOptions_ = true;
    mode_ = mode;
    frameLimitUs_ = frameLimitUs;
    g_reflexRunning.store(mode != abi::kReflexOff);
}

void ReflexProvider::configure(bool enabled, bool boost, std::uint32_t minIntervalUs) {
    if (!live(streamline_runtime())) return;
    const std::uint32_t mode = !enabled ? abi::kReflexOff
                               : boost  ? abi::kReflexLowLatencyBoost
                                        : abi::kReflexLowLatency;
    send_options(mode, enabled ? minIntervalUs : 0);
}

// One token for all the calls of a frame, the runtime's (DLSS asks the same one): taken once per frame id.
void* ReflexProvider::token_for(StreamlineRuntime& runtime, std::uint64_t frameId) {
    if (token_ && tokenFrame_ == frameId) return token_;
    std::string why;
    void* token = runtime.frame_token(nullptr, &why);
    if (!token) {
        if (!warnedToken_) FA_WARN("render", "Reflex: no frame token: {}", why);
        warnedToken_ = true;
        return nullptr;
    }
    token_ = token;
    tokenFrame_ = frameId;
    return token;
}

void ReflexProvider::sleep(std::uint64_t frameId) {
    StreamlineRuntime& runtime = streamline_runtime();
    if (!live(runtime) || !api_.sleep) return;
    void* token = token_for(runtime, frameId);
    if (!token) return;
    // Streamline wants the call every frame, even with Reflex off (the options say what it does).
    if (const abi::Result r = api_.sleep(token); r != abi::kOk && !warnedSleep_) {
        warnedSleep_ = true;
        FA_WARN("render", "Reflex: {}", streamline_refusal("slReflexSleep", r));
    }
}

void ReflexProvider::marker(LatencyMarker m, std::uint64_t frameId) {
    const std::int32_t pcl = reflex_pcl_marker(m);
    StreamlineRuntime& runtime = streamline_runtime();
    if (pcl < 0 || !live(runtime) || !api_.setMarker) return;
    void* token = token_for(runtime, frameId);
    if (!token) return;
    if (const abi::Result r = api_.setMarker(std::uint32_t(pcl), token); r != abi::kOk && !warnedMarker_) {
        warnedMarker_ = true;
        FA_WARN("render", "Reflex: {}", streamline_refusal("slPCLSetMarker", r));
    }
}

// Reflex's own timestamps of the last frames (microseconds): the span from the start of the simulation to the end of the present per frame,
// the same fields XeLL gives, and the GPU's frame time.
Json ReflexProvider::vendor_report() {
    if (!live(streamline_runtime()) || !api_.getState || !state_ || mode_ == abi::kReflexOff) return Json();
    abi::init_reflex_state(*state_);
    if (api_.getState(state_.get()) != abi::kOk || !state_->latencyReportAvailable) return Json();
    double sum = 0, newestMs = 0, gpuSum = 0;
    std::uint64_t newestId = 0;
    int n = 0, gpuN = 0;
    for (const abi::ReflexReport& r : state_->frameReport) {
        if (r.frameId == 0 || r.simStartTime == 0 || r.presentEndTime <= r.simStartTime) continue;
        const double ms = double(r.presentEndTime - r.simStartTime) / 1000.0;
        sum += ms;
        ++n;
        if (r.frameId >= newestId) {
            newestId = r.frameId;
            newestMs = ms;
        }
        if (r.gpuFrameTimeUs > 0) {
            gpuSum += double(r.gpuFrameTimeUs) / 1000.0;
            ++gpuN;
        }
    }
    if (n == 0) return Json();
    Json j = Json::object();
    j["source"] = "Reflex";
    j["frames"] = n;
    j["lastFrameId"] = newestId;
    j["lastSimulationToPresentMs"] = round2(newestMs);
    j["avgSimulationToPresentMs"] = round2(sum / n);
    if (gpuN > 0) j["avgGpuFrameMs"] = round2(gpuSum / gpuN);
    return j;
}

void ReflexProvider::forget() {
    g_reflexRunning.store(false);
    device_ = nullptr;
    generation_ = 0;
    api_ = ReflexApi{};
    haveOptions_ = false;
    mode_ = abi::kReflexOff;
    frameLimitUs_ = 0;
    token_ = nullptr;
    tokenFrame_ = 0;
    warnedSleep_ = warnedMarker_ = warnedOptions_ = warnedToken_ = false;
    state_.reset();
}

void ReflexProvider::stop(gpu::Device& device) {
    if (device_ != &device) return;
    // Reflex off, only while the set-up that made the functions is still there (after the device went, the library has shut down).
    if (live(streamline_runtime())) send_options(abi::kReflexOff, 0);
    forget();
}

}  // namespace

bool reflex_running() { return g_reflexRunning.load(); }

void reset_reflex_running_for_test() { g_reflexRunning.store(false); }

std::string reflex_load_api(const StreamlineApi& sl, bool withPcl, ReflexApi& api) {
    if (!sl.getFeatureFunction)
        return "NVIDIA Streamline has no slGetFeatureFunction (it is not Streamline 2.x): " + std::string(kSetupHint) +
               ".";
    ReflexApi a;
    const auto get = [&](std::uint32_t feature, const char* name, auto& fn) -> std::string {
        void* address = nullptr;
        const abi::Result r = sl.getFeatureFunction(feature, name, &address);
        if (r != abi::kOk || !address)
            return streamline_refusal((std::string("slGetFeatureFunction(") + name + ")").c_str(),
                                      r == abi::kOk ? abi::kErrorFeatureMissing : r);
        fn = reinterpret_cast<std::remove_reference_t<decltype(fn)>>(address);  // NOLINT: the function's address
        return {};
    };
    for (const std::string& why :
         {get(abi::kFeatureReflex, "slReflexSetOptions", a.setOptions),
          get(abi::kFeatureReflex, "slReflexGetState", a.getState), get(abi::kFeatureReflex, "slReflexSleep", a.sleep)})
        if (!why.empty()) return why;
    // Without the PCL plugin Reflex still sleeps; the markers are then not sent.
    if (withPcl && !get(abi::kFeaturePcl, "slPCLSetMarker", a.setMarker).empty()) a.setMarker = nullptr;
    api = a;
    return {};
}

std::int32_t reflex_pcl_marker(LatencyMarker marker) {
    switch (marker) {
        case LatencyMarker::SimulationStart: return std::int32_t(abi::kPclSimulationStart);
        case LatencyMarker::SimulationEnd: return std::int32_t(abi::kPclSimulationEnd);
        case LatencyMarker::RenderSubmitStart: return std::int32_t(abi::kPclRenderSubmitStart);
        case LatencyMarker::RenderSubmitEnd: return std::int32_t(abi::kPclRenderSubmitEnd);
        case LatencyMarker::PresentStart: return std::int32_t(abi::kPclPresentStart);
        case LatencyMarker::PresentEnd: return std::int32_t(abi::kPclPresentEnd);
        case LatencyMarker::InputSample: break;
    }
    return -1;
}

std::unique_ptr<LatencyProvider> make_reflex_provider() { return std::make_unique<ReflexProvider>(); }

}  // namespace fa::render
