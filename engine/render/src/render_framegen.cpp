// The frame-generation seam of M78 (render_framegen.h): the provider table, the hook registration, the plan of the output passes and the
// controller (provider choice, refusals, the minimum base frame rate).
#include "render_framegen.h"
#include "render_framegen_xess.h"

#include <algorithm>
#include <cmath>
#include <mutex>
#include <vector>

#include "fa/core/log.h"

namespace fa::render {

namespace {

int slot_index(FrameGenSlot s) {
    switch (s) {
        case FrameGenSlot::Dlss: return 0;
        case FrameGenSlot::Fsr: return 1;
        case FrameGenSlot::Xess: return 2;
        case FrameGenSlot::None: break;
    }
    return -1;
}

struct ProviderTable {
    std::mutex mutex;
    // Each slot is empty until its package registers a provider (the Xess slot's is made here: render_framegen_xess.h).
    std::shared_ptr<FrameGenProvider> registered[3];
    FrameGenProvider* fake[3] = {};
    ProviderTable() { registered[2] = make_xess_framegen_provider(); }
};

// Never destroyed (the reason the vendor table gives, render_upscale_vendor.cpp): a renderer shut down during the static destruction of the
// process may be the first to ask.
ProviderTable& table() {
    static auto* const t = new ProviderTable();
    return *t;
}

unsigned bit_of(gpu::Backend b) { return 1u << unsigned(b); }

}  // namespace

FrameGenProvider* framegen_provider(FrameGenSlot slot) {
    const int i = slot_index(slot);
    if (i < 0) return nullptr;
    ProviderTable& t = table();
    std::lock_guard<std::mutex> lock(t.mutex);
    return t.fake[i] ? t.fake[i] : t.registered[i].get();
}

void set_framegen_provider_for_test(FrameGenSlot slot, FrameGenProvider* fake) {
    const int i = slot_index(slot);
    if (i < 0) return;
    ProviderTable& t = table();
    std::lock_guard<std::mutex> lock(t.mutex);
    t.fake[i] = fake;
}

void register_framegen_provider(std::shared_ptr<FrameGenProvider> provider) {
    if (!provider) return;
    const int i = slot_index(provider->slot());
    if (i < 0) return;
    ProviderTable& t = table();
    std::lock_guard<std::mutex> lock(t.mutex);
    t.registered[i] = std::move(provider);
}

void clear_registered_framegen_provider_for_test(FrameGenSlot slot) {
    const int i = slot_index(slot);
    if (i < 0) return;
    ProviderTable& t = table();
    std::lock_guard<std::mutex> lock(t.mutex);
    t.registered[i].reset();
}

const char* framegen_absent_reason(FrameGenSlot slot) {
    switch (slot) {
        case FrameGenSlot::Dlss:
            return "DLSS frame generation arrives with the Streamline DLSS-G provider; this build has no provider for "
                   "it yet.";
        case FrameGenSlot::Fsr:
            return "FSR 3 frame generation arrives with the FidelityFX frame generation provider; this build has no "
                   "provider for it yet.";
        case FrameGenSlot::Xess: return "XeSS frame generation has no provider in this build.";
        case FrameGenSlot::None: break;
    }
    return "no provider for this mode.";
}

unsigned framegen_slot_backends(FrameGenSlot slot) {
    switch (slot) {
        case FrameGenSlot::Dlss:
        case FrameGenSlot::Fsr: return bit_of(gpu::Backend::D3d12) | bit_of(gpu::Backend::Vulkan);
        case FrameGenSlot::Xess: return bit_of(gpu::Backend::D3d12);
        case FrameGenSlot::None: break;
    }
    return 0;
}

const char* framegen_slot_setup_id(FrameGenSlot slot) {
    switch (slot) {
        case FrameGenSlot::Dlss: return "streamline";
        case FrameGenSlot::Fsr: return "fidelityfx";
        case FrameGenSlot::Xess: return "xess";
        case FrameGenSlot::None: break;
    }
    return "";
}

std::string framegen_environment_problem(const FrameGenProvider& provider, const VendorEnv& env) {
    return vendor_environment_problem(provider.name(), provider.backends(), env);
}

std::vector<std::shared_ptr<gpu::DeviceHook>> framegen_device_hooks() {
    ProviderTable& t = table();
    std::vector<std::shared_ptr<gpu::DeviceHook>> hooks;
    std::lock_guard<std::mutex> lock(t.mutex);
    for (int i = 0; i < 3; ++i) {
        FrameGenProvider* p = t.fake[i] ? t.fake[i] : t.registered[i].get();
        if (!p) continue;
        std::shared_ptr<gpu::DeviceHook> hook = p->device_hook();
        if (!hook) continue;
        const bool twice =
            std::any_of(hooks.begin(), hooks.end(), [&](const auto& h) { return h.get() == hook.get(); });
        if (!twice) hooks.push_back(std::move(hook));
    }
    return hooks;
}

// ---- the passes of the output -----------------------------------------------------------------------------------------------------

FrameGenPassPlan plan_framegen_passes(bool dispatchWanted, bool hudOverUpscale) {
    FrameGenPassPlan p;
    p.dispatch = dispatchWanted;
    p.copyHudless = dispatchWanted && hudOverUpscale;
    return p;
}

std::string_view frame_gen_state_name(FrameGenState s) {
    switch (s) {
        case FrameGenState::Off: return "off";
        case FrameGenState::Refused: return "refused";
        case FrameGenState::Measuring: return "measuring";
        case FrameGenState::Paused: return "paused";
        case FrameGenState::Active: return "active";
    }
    return "off";
}

// ---- the controller ---------------------------------------------------------------------------------------------------------------

void FrameGenController::attach(gpu::Device* device, const VendorEnv& env, const FrameGenSwapchain& swapchain,
                                bool hooked) {
    detach();
    device_ = device;
    env_ = env;
    swapchain_ = swapchain;
    hooked_ = hooked;
    for (Slot& s : slots_) s = Slot{};
    reset_stats();
    apply();
}

void FrameGenController::detach() {
    stop_provider();
    device_ = nullptr;
    refusal_.clear();
    generating_ = false;
    pausedByRate_ = false;
}

void FrameGenController::reset_probes() {
    for (Slot& s : slots_) s = Slot{};
    apply();
}

void FrameGenController::stop_provider() {
    if (running_ && device_) {
        running_->configure(false);
        running_->stop(*device_);
    }
    running_ = nullptr;
    runningSlot_ = FrameGenSlot::None;
    generating_ = false;
    lastProviderCount_ = 0;
}

FrameGenController::Slot& FrameGenController::slot(FrameGenSlot s) {
    Slot& sl = slots_[std::max(0, slot_index(s))];
    if (!sl.probed) {
        sl.probed = true;
        FrameGenProvider* p = framegen_provider(s);
        if (!p) {
            sl.probe.reason = framegen_absent_reason(s);
        } else {
            sl.probe = p->probe(env_);
        }
    }
    return sl;
}

std::string FrameGenController::provider_reason(FrameGenSlot s) {
    if (slot_index(s) < 0) return {};
    Slot& sl = slot(s);
    if (sl.failed) return sl.failure;
    if (FrameGenProvider* p = framegen_provider(s)) {
        if (std::string failure = p->failure(); !failure.empty())
            return failure;  // failed while it ran: off for the run
    }
    return sl.probe.available ? std::string()
                              : (sl.probe.reason.empty() ? std::string("unavailable") : sl.probe.reason);
}

FrameGenCaps FrameGenController::caps() {
    FrameGenCaps c;
    c.gpuVendor = env_.vendor;
    c.dlss = provider_reason(FrameGenSlot::Dlss).empty();
    c.fsr = provider_reason(FrameGenSlot::Fsr).empty();
    c.xess = provider_reason(FrameGenSlot::Xess).empty();
    return c;
}

void FrameGenController::set_settings(const FrameGenSettings& s) {
    const bool modeChanged = s.mode != settings_.mode;
    settings_ = s;
    if (modeChanged) {
        sinceSwitch_ = kMinDwellFrames;
        pausedByRate_ = false;
    }
    apply();
}

void FrameGenController::set_inputs(bool upscaleStage, bool temporal) {
    if (upscaleStage == upscaleStage_ && temporal == temporal_) return;
    upscaleStage_ = upscaleStage;
    temporal_ = temporal;
    apply();
}

void FrameGenController::set_generating(bool on) {
    if (on == generating_) return;
    generating_ = on;
    if (running_) running_->configure(on);
    if (on) resetNext_ = true;  // the provider has seen no frame for a while
}

void FrameGenController::apply() {
    refusal_.clear();
    if (!device_ || settings_.mode == FrameGenMode::Off) {
        stop_provider();
        return;
    }
    // Only what the mode can choose is asked: a game that never turns the setting on never loads an SDK.
    FrameGenCaps c;
    c.gpuVendor = env_.vendor;
    const FrameGenSlot named = settings_.mode == FrameGenMode::Auto ? frame_gen_slot_for_vendor(env_.vendor)
                                                                    : frame_gen_slot_of_mode(settings_.mode);
    if (named == FrameGenSlot::None) {
        stop_provider();
        refusal_ =
            "this GPU's maker (" + std::string(gpu_vendor_name(env_.vendor)) +
            ") has no frame generation SDK in FactorIA. Name a mode that suits the GPU (dlss on NVIDIA, fsr on AMD, "
            "xess on Intel) or set render.frameGeneration.mode to \"off\".";
        return;
    }
    const std::string why = provider_reason(named);
    if (!why.empty()) {
        stop_provider();
        refusal_ = why;
        return;
    }
    switch (named) {
        case FrameGenSlot::Dlss: c.dlss = true; break;
        case FrameGenSlot::Fsr: c.fsr = true; break;
        case FrameGenSlot::Xess: c.xess = true; break;
        case FrameGenSlot::None: break;
    }
    const FrameGenSlot want = effective_frame_generation(settings_, c);
    FrameGenProvider* p = framegen_provider(want);
    if (!p) {
        stop_provider();
        refusal_ = framegen_absent_reason(named);
        return;
    }
    if (!hooked_) {
        stop_provider();
        refusal_ =
            std::string(p->name()) +
            " makes the window's swapchain, which is made when the game starts: set render.frameGeneration.mode in "
            "factoria.json (or turn it on in the settings) and restart the game; it cannot be switched on from \"off\" "
            "while the game runs.";
        return;
    }
    if (running_ != p) {
        stop_provider();
        const std::string failure = p->start(*device_, swapchain_);
        if (!failure.empty()) {
            // "Fail once, stay off": the SDK that could not start is not asked again.
            Slot& sl = slot(want);
            sl.failed = true;
            sl.failure = failure;
            refusal_ = failure;
            FA_WARN("render", "frame generation: {} could not start: {}", p->name(), failure);
            return;
        }
        running_ = p;
        runningSlot_ = want;
        resetNext_ = true;
    }
    // What the frame must have: the stage and a temporal frame. The provider stays started (its swapchain is there either way).
    if (!upscaleStage_) {
        refusal_ = "frame generation needs the upscale stage (the player's render scale below 1) and the temporal "
                   "upscaler: it reads "
                   "the depth and the motion of the jittered frame. Set render.upscaler.mode to \"temporal\" (or a "
                   "vendor upscaler) "
                   "and the render scale below 1.";
    } else if (!temporal_) {
        refusal_ = "frame generation needs the temporal upscaler's frame (one full-viewport camera, jittered, with a "
                   "depth and a "
                   "motion image); this frame is drawn without. Set render.upscaler.mode to \"temporal\" (or a vendor "
                   "upscaler), and "
                   "draw with one camera.";
    }
    if (!refusal_.empty()) set_generating(false);
}

void FrameGenController::set_swapchain(const FrameGenSwapchain& swapchain) {
    if (swapchain.width == swapchain_.width && swapchain.height == swapchain_.height &&
        swapchain.vsync == swapchain_.vsync && swapchain.backend == swapchain_.backend)
        return;
    swapchain_ = swapchain;  // a provider started later is told the size as it is now
    resetNext_ = true;
    if (running_ && device_) running_->swapchain_changed(*device_, swapchain_);
}

void FrameGenController::begin_frame(double nowMs) {
    if (!device_ || settings_.mode == FrameGenMode::Off) return;
    constexpr int kStamps = kWindowFrames + 1;
    ++rendered_;
    if (running_) {  // the SDK's own counter restarts at 0 with each start(): the controller adds up what it grew by
        const std::uint64_t seen = running_->generated_frames();
        generatedNow_ += seen >= lastProviderCount_ ? seen - lastProviderCount_ : seen;
        lastProviderCount_ = seen;
    }
    stamps_[head_] = nowMs;
    generated_[head_] = generatedNow_;
    head_ = (head_ + 1) % kStamps;
    count_ = std::min(count_ + 1, kStamps);
    if (sinceSwitch_ < 1000000) ++sinceSwitch_;
    if (count_ == kStamps) {
        const int oldest = head_;  // the next slot to write holds the oldest stamp once the window is full
        const int newest = (head_ + kStamps - 1) % kStamps;
        const double span = stamps_[newest] - stamps_[oldest];
        baseFps_ = span > 0.0 ? 1000.0 * double(kWindowFrames) / span : 0.0;
        const double made = double(generated_[newest] - generated_[oldest]);
        presentedFps_ = baseFps_ * (double(kWindowFrames) + made) / double(kWindowFrames);
    }
    if (!running_ || !refusal_.empty()) {
        set_generating(false);
        pausedByRate_ = false;
        return;
    }
    const int minFps = settings_.minBaseFps;
    if (minFps <= 0) {  // no rate rule: generation runs whenever nothing refuses it
        set_generating(true);
        return;
    }
    if (count_ < kStamps) return;  // measuring
    // A game that starts (or comes back from a refusal) below the limit is paused at once, not "measuring" for ever: the window is full and
    // its answer is known. The dwell does not apply (generation never ran).
    if (!generating_ && baseFps_ < double(minFps)) pausedByRate_ = true;
    if (sinceSwitch_ < kMinDwellFrames) return;
    if (!generating_) {
        const double need = pausedByRate_ ? double(minFps) * kResumeMargin : double(minFps);
        if (baseFps_ >= need) {
            set_generating(true);
            pausedByRate_ = false;
            sinceSwitch_ = 0;
        }
    } else if (baseFps_ < double(minFps)) {
        set_generating(false);
        pausedByRate_ = true;
        sinceSwitch_ = 0;
    }
}

bool FrameGenController::dispatch(FrameGenFrame& frame) {
    if (!wants_dispatch()) return false;
    if (frame.outW != lastOutW_ || frame.outH != lastOutH_)
        resetNext_ = true;  // a resized output: the provider's history is of another size
    lastOutW_ = frame.outW;
    lastOutH_ = frame.outH;
    frame.reset = frame.reset || resetNext_;
    if (running_->dispatch(frame)) {
        resetNext_ = false;
        dispatchError_.clear();
        return true;
    }
    resetNext_ = true;
    dispatchError_ = frame.error.empty() ? std::string("the provider refused the frame") : frame.error;
    // A provider that failed for good (FrameGenProvider::failure) is left: apply() stops it and the reason is the refusal.
    if (!running_->failure().empty()) apply();
    return false;
}

void FrameGenController::note_skipped(const std::string& why) {
    resetNext_ = true;
    dispatchError_ = why;
}

FrameGenState FrameGenController::state() const {
    if (!device_ || settings_.mode == FrameGenMode::Off) return FrameGenState::Off;
    if (!refusal_.empty() || !running_) return FrameGenState::Refused;
    if (generating_) return FrameGenState::Active;
    return pausedByRate_ ? FrameGenState::Paused : FrameGenState::Measuring;
}

std::string FrameGenController::reason() const {
    switch (state()) {
        case FrameGenState::Off: return {};
        case FrameGenState::Refused: return refusal_.empty() ? std::string("no provider runs") : refusal_;
        case FrameGenState::Measuring:
            return "measuring the base frame rate over " + std::to_string(kWindowFrames) + " frames.";
        case FrameGenState::Paused:
            return "the game renders at " + std::to_string(int(std::lround(baseFps_))) + " fps, below minBaseFps (" +
                   std::to_string(settings_.minBaseFps) + "): generation resumes at " +
                   std::to_string(int(std::ceil(double(settings_.minBaseFps) * kResumeMargin - 1e-6))) + " fps.";
        case FrameGenState::Active: return dispatchError_;  // "" unless the provider refused the last frame
    }
    return {};
}

void FrameGenController::reset_stats() {
    count_ = head_ = 0;
    baseFps_ = presentedFps_ = 0;
    rendered_ = 0;
    generatedBase_ = generatedNow_;
    dispatchError_.clear();
    sinceSwitch_ = kMinDwellFrames;
}

FrameGenReport FrameGenController::report() {
    FrameGenReport r;
    r.provider = provider();
    r.state = state();
    r.generating = generating_;
    r.baseFps = baseFps_;
    r.presentedFps = presentedFps_;
    r.renderedFrames = rendered_;
    r.generatedFrames = generatedNow_ - generatedBase_;
    r.reason = reason();
    return r;
}

}  // namespace fa::render
