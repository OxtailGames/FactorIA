// The low-latency seam of M78 (render_latency.h): the clock, the provider table and the controller (markers, the engine's own pacing and the
// input-to-present readout).
#include "render_latency.h"

#include <algorithm>
#include <chrono>
#include <cmath>
#include <mutex>
#include <thread>
#include <vector>

#include "fa/core/log.h"
#include "fa/core/sleep.h"

namespace fa::render {

namespace {

// ---- the clock --------------------------------------------------------------------------------------------------------------------

class SteadyLatencyClock final : public LatencyClock {
public:
    double now_ms() override {
        using namespace std::chrono;
        return duration<double, std::milli>(steady_clock::now().time_since_epoch()).count();
    }
    void sleep_until_ms(double target) override {
        // Most of the wait is a sleep (fa::sleep_precise: a high-resolution timer on Windows, whose plain sleep ends a whole 15 ms tick
        // late; elsewhere it ends up to a millisecond or two late, and on a loaded machine more), the last two milliseconds are spent
        // yielding so the frame starts on time. A wait never takes more than a quarter of a second: the targets are within one frame (a
        // safety net far above any refresh interval).
        const double start = now_ms();
        const double end = std::min(target, start + 250.0);
        for (double left = end - now_ms(); left > 2.0; left = end - now_ms())
            sleep_precise(std::chrono::duration_cast<std::chrono::nanoseconds>(
                std::chrono::duration<double, std::milli>(left - 2.0)));
        while (now_ms() < end) std::this_thread::yield();
    }
};

LatencyClock* g_clock_override = nullptr;

// ---- the provider table -----------------------------------------------------------------------------------------------------------

int slot_index(LatencyDriver d) {
    switch (d) {
        case LatencyDriver::Reflex: return 0;
        case LatencyDriver::AntiLag2: return 1;
        case LatencyDriver::Xell: return 2;
        case LatencyDriver::None:
        case LatencyDriver::Pacing: break;
    }
    return -1;
}

struct ProviderTable {
    std::mutex mutex;
    std::shared_ptr<LatencyProvider> registered[3];
    LatencyProvider* fake[3] = {};
    ProviderTable() {
        registered[0] = make_reflex_provider();
        registered[1] = make_antilag2_provider();
        registered[2] = make_xell_provider();
    }
};

// Never destroyed (the reason the vendor table gives, render_upscale_vendor.cpp): a renderer shut down during the static destruction of the
// process may be the first to ask.
ProviderTable& table() {
    static auto* const t = new ProviderTable();
    return *t;
}

}  // namespace

LatencyClock& latency_clock() {
    static SteadyLatencyClock steady;
    return g_clock_override ? *g_clock_override : steady;
}
void set_latency_clock_for_test(LatencyClock* fake) { g_clock_override = fake; }

LatencyProvider* latency_provider(LatencyDriver driver) {
    const int i = slot_index(driver);
    if (i < 0) return nullptr;
    ProviderTable& t = table();
    std::lock_guard<std::mutex> lock(t.mutex);
    return t.fake[i] ? t.fake[i] : t.registered[i].get();
}
void set_latency_provider_for_test(LatencyDriver driver, LatencyProvider* fake) {
    const int i = slot_index(driver);
    if (i < 0) return;
    ProviderTable& t = table();
    std::lock_guard<std::mutex> lock(t.mutex);
    t.fake[i] = fake;
}
void register_latency_provider(std::shared_ptr<LatencyProvider> provider) {
    if (!provider) return;
    const int i = slot_index(provider->driver());
    if (i < 0) return;
    ProviderTable& t = table();
    std::lock_guard<std::mutex> lock(t.mutex);
    t.registered[i] = std::move(provider);
}

void restore_latency_provider_for_test(LatencyDriver driver) {
    const int i = slot_index(driver);
    if (i < 0) return;
    ProviderTable& t = table();
    std::lock_guard<std::mutex> lock(t.mutex);
    t.registered[i] = i == 0 ? make_reflex_provider() : i == 1 ? make_antilag2_provider() : make_xell_provider();
}

// ---- the controller ---------------------------------------------------------------------------------------------------------------

namespace {

// The engine's own pacing: the frame starts so that its work (the busy time measured, with a margin) ends one refresh interval after the last
// present returned.
constexpr double kPacingMargin = 1.15;  // of the busy time
constexpr double kPacingSlackMs = 1.0;  // a fixed margin on top: the sleep ends a little late

}  // namespace

void LatencyController::attach(gpu::Device* device, const VendorEnv& env, bool pacing) {
    detach();
    device_ = device;
    env_ = env;
    pacingAllowed_ = pacing;
    for (Slot& s : slots_) s = Slot{};
    reset_stats();
    apply();
}

void LatencyController::detach() {
    stop_provider();
    device_ = nullptr;
    driver_ = LatencyDriver::None;
}

void LatencyController::reset_probes() {
    for (Slot& s : slots_) s = Slot{};
    apply();
}

LatencyController::Slot& LatencyController::slot(LatencyDriver d) {
    const int i = std::max(0, slot_index(d));
    Slot& s = slots_[i];
    if (!s.probed) {
        s.probed = true;
        LatencyProvider* p = latency_provider(d);
        if (!p) {
            s.probe.reason = "no provider for this mode.";
        } else {
            s.probe = p->probe(env_);
        }
    }
    return s;
}

std::string LatencyController::provider_reason(LatencyDriver d) {
    if (slot_index(d) < 0) return {};
    Slot& s = slot(d);
    if (s.failed) return s.failure;
    return s.probe.available ? std::string() : (s.probe.reason.empty() ? std::string("unavailable") : s.probe.reason);
}

LatencyCaps LatencyController::caps() {
    LatencyCaps c;
    c.gpuVendor = env_.vendor;
    c.pacing = pacingAllowed_ && device_ != nullptr;
    c.reflex = provider_reason(LatencyDriver::Reflex).empty();
    c.antiLag2 = provider_reason(LatencyDriver::AntiLag2).empty();
    c.xell = provider_reason(LatencyDriver::Xell).empty();
    return c;
}

void LatencyController::set_settings(const LatencySettings& s) {
    settings_ = s;
    apply();
}

void LatencyController::stop_provider() {
    if (running_ && device_) {
        running_->configure(false, false, 0);
        running_->stop(*device_);
    }
    running_ = nullptr;
}

void LatencyController::apply() {
    if (!device_ || settings_.mode == LatencyMode::Off) {
        stop_provider();
        driver_ = LatencyDriver::None;
        return;
    }
    // Only what the mode can choose is asked: a game that never turns the setting on never loads an SDK.
    LatencyCaps c;
    c.gpuVendor = env_.vendor;
    c.pacing = pacingAllowed_;
    const auto usable = [&](LatencyDriver d) { return provider_reason(d).empty(); };
    LatencyDriver want = LatencyDriver::None;
    for (int round = 0; round < 3; ++round) {
        c.reflex = c.antiLag2 = c.xell = false;
        switch (settings_.mode) {
            case LatencyMode::Reflex: c.reflex = usable(LatencyDriver::Reflex); break;
            case LatencyMode::AntiLag2: c.antiLag2 = usable(LatencyDriver::AntiLag2); break;
            case LatencyMode::Xell: c.xell = usable(LatencyDriver::Xell); break;
            case LatencyMode::Auto:
                if (env_.vendor == GpuVendor::Nvidia) c.reflex = usable(LatencyDriver::Reflex);
                if (env_.vendor == GpuVendor::Amd) c.antiLag2 = usable(LatencyDriver::AntiLag2);
                if (env_.vendor == GpuVendor::Intel) c.xell = usable(LatencyDriver::Xell);
                break;
            case LatencyMode::Off: break;
        }
        want = effective_latency_driver(settings_, c);
        LatencyProvider* p = latency_provider(want);
        if (!p) break;  // none, or the engine's pacing
        if (running_ == p) break;
        stop_provider();
        const std::string why = p->start(*device_);
        if (why.empty()) {
            running_ = p;
            break;
        }
        // "Fail once, stay off": the SDK that could not start is not asked again; the next round decides without it.
        Slot& s = slot(want);
        s.failed = true;
        s.failure = why;
        FA_WARN("render", "low latency: {} could not start: {}", p->name(), why);
    }
    if (running_ && running_ != latency_provider(want))
        stop_provider();  // the engine's own pacing (or none) runs: no SDK
    driver_ = want;
    if (running_) running_->configure(true, settings_.boost, 0);
}

double LatencyController::pacing_sleep_ms(double refreshHz) const {
    if (driver_ != LatencyDriver::Pacing || !(refreshHz > 0.0) || presentEndMs_ < 0.0 || !haveBusy_) return 0.0;
    const double interval = 1000.0 / refreshHz;
    const double now = latency_clock().now_ms();
    const double start = presentEndMs_ + interval - busyMs_ * kPacingMargin - kPacingSlackMs;
    return std::clamp(start - now, 0.0, interval);
}

void LatencyController::frame_begin(double refreshHz) {
    if (driver_ == LatencyDriver::None || !device_) return;
    LatencyClock& clock = latency_clock();
    const std::uint64_t id = presented_ + 1;
    if (running_) {
        running_->sleep(id);
    } else if (const double wait = pacing_sleep_ms(refreshHz); wait > 0.0) {
        clock.sleep_until_ms(clock.now_ms() + wait);
    }
    frameStartMs_ = clock.now_ms();
    frameStarted_ = true;
    haveInput_ = false;
    if (running_) running_->marker(LatencyMarker::SimulationStart, id);
}

void LatencyController::mark(LatencyMarker m) {
    if (driver_ == LatencyDriver::None || !device_) return;
    const double now = latency_clock().now_ms();
    if (running_) running_->marker(m, presented_ + 1);
    switch (m) {
        case LatencyMarker::InputSample:
            inputMs_ = now;
            haveInput_ = true;
            break;
        case LatencyMarker::PresentStart:
            if (frameStarted_) {
                const double sample = std::max(0.0, now - frameStartMs_);
                // A longer frame is believed at once, a shorter one slowly: the sleep never starts the next frame too late for one slow frame.
                busyMs_ = haveBusy_ ? std::max(sample, busyMs_ * 0.9 + sample * 0.1) : sample;
                haveBusy_ = true;
            }
            break;
        case LatencyMarker::PresentEnd:
            presentEndMs_ = now;
            if (haveInput_) {
                lastFrameMs_ = std::max(0.0, now - inputMs_);
                lastShownMs_ = lastFrameMs_;
                ring_[ringHead_] = lastFrameMs_;
                ringHead_ = (ringHead_ + 1) % kWindow;
                ringCount_ = std::min(ringCount_ + 1, kWindow);
                maxMs_ = std::max(maxMs_, lastFrameMs_);
                ++samples_;
                haveInput_ = false;
            }
            frameStarted_ = false;
            ++presented_;
            break;
        case LatencyMarker::SimulationStart:
        case LatencyMarker::SimulationEnd:
        case LatencyMarker::RenderSubmitStart:
        case LatencyMarker::RenderSubmitEnd: break;
    }
}

double LatencyController::take_last_frame_ms() {
    const double v = lastFrameMs_;
    lastFrameMs_ = -1.0;
    return v;
}

void LatencyController::reset_stats() {
    haveInput_ = false;
    lastFrameMs_ = -1.0;
    lastShownMs_ = 0;
    ringCount_ = ringHead_ = 0;
    maxMs_ = 0;
    samples_ = 0;
    haveBusy_ = false;
    busyMs_ = 0;
    presentEndMs_ = -1.0;
    frameStartMs_ = 0;
    frameStarted_ = false;
}

LatencyReport LatencyController::report() {
    LatencyReport r;
    r.driver = driver_;
    r.samples = samples_;
    r.lastMs = lastShownMs_;
    r.maxMs = maxMs_;
    if (ringCount_ > 0) {
        std::vector<double> v(ring_, ring_ + ringCount_);
        double sum = 0;
        for (double x : v) sum += x;
        r.avgMs = sum / double(v.size());
        std::sort(v.begin(), v.end());
        r.p95Ms = v[std::min(v.size() - 1, std::size_t(std::ceil(double(v.size()) * 0.95)) - 1)];
    }
    if (running_) r.vendor = running_->vendor_report();
    return r;
}

}  // namespace fa::render
