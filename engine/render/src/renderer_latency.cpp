// Renderer's low-latency API (renderer.h, "latency"; render_latency.h): the setting, its status and the frame's markers.
#include <array>
#include <cmath>

#include "renderer_impl.h"

namespace fa {

namespace {

double round3(double v) { return std::round(v * 1000.0) / 1000.0; }

const render::LatencySettings& no_latency() {
    static const render::LatencySettings off;
    return off;
}

}  // namespace

void Renderer::Impl::set_latency_env(render::FeatureEnv& env) {
    std::array<render::VendorProbe, 3> answers;
    std::size_t i = 0;
    for (const render::LatencyDriver d :
         {render::LatencyDriver::Reflex, render::LatencyDriver::AntiLag2, render::LatencyDriver::Xell}) {
        const std::string why = latency.provider_reason(d);
        answers[i].available = why.empty();
        answers[i].reason = why;
        ++i;
    }
    render::set_latency_env(env, answers);
}

void Renderer::set_latency(const render::LatencySettings& settings) {
    if (!initialized()) return;
    impl_->latency.set_settings(settings);
}

const render::LatencySettings& Renderer::latency() const {
    return initialized() ? impl_->latency.settings() : no_latency();
}

render::LatencyDriver Renderer::effective_latency() const {
    return initialized() ? impl_->latency.driver() : render::LatencyDriver::None;
}

Json Renderer::latency_status() {
    Json j = Json::object();
    const render::LatencySettings s = latency();
    j["mode"] = std::string(render::latency_mode_name(s.mode));
    j["boost"] = s.boost;
    const render::LatencyDriver driver = effective_latency();
    j["driver"] = std::string(render::latency_driver_name(driver));
    std::string reason;
    Json modes = Json::object();
    if (initialized()) {
        render::LatencyController& lc = impl_->latency;
        for (const render::LatencyDriver d :
             {render::LatencyDriver::Reflex, render::LatencyDriver::AntiLag2, render::LatencyDriver::Xell}) {
            const std::string why = lc.provider_reason(d);
            Json m = Json::object();
            m["available"] = why.empty();
            m["reason"] = why;
            modes[std::string(render::latency_driver_name(d))] = std::move(m);
        }
        // Why the mode runs another path than the one it names.
        if (s.mode != render::LatencyMode::Off) {
            render::LatencyDriver named = render::LatencyDriver::None;
            switch (s.mode) {
                case render::LatencyMode::Reflex: named = render::LatencyDriver::Reflex; break;
                case render::LatencyMode::AntiLag2: named = render::LatencyDriver::AntiLag2; break;
                case render::LatencyMode::Xell: named = render::LatencyDriver::Xell; break;
                case render::LatencyMode::Auto: {
                    const render::GpuVendor v = lc.caps().gpuVendor;
                    named = v == render::GpuVendor::Nvidia  ? render::LatencyDriver::Reflex
                            : v == render::GpuVendor::Amd   ? render::LatencyDriver::AntiLag2
                            : v == render::GpuVendor::Intel ? render::LatencyDriver::Xell
                                                            : render::LatencyDriver::None;
                    if (named == render::LatencyDriver::None)
                        reason = "this GPU's maker (" + std::string(render::gpu_vendor_name(v)) +
                                 ") has no low-latency SDK in FactorIA.";
                    break;
                }
                case render::LatencyMode::Off: break;
            }
            if (named != render::LatencyDriver::None && driver != named) reason = lc.provider_reason(named);
            if (driver == render::LatencyDriver::Pacing)
                reason += (reason.empty() ? "" : " ") + std::string("The engine's own pacing runs instead.");
            else if (driver == render::LatencyDriver::None)
                reason +=
                    (reason.empty() ? "" : " ") +
                    std::string("Nothing paces the loop: the engine's own pacing needs a window that is presented to "
                                "(not a headless run, not the editor).");
        }
        if (lc.reflex_forced())
            reason += (reason.empty() ? "" : " ") +
                      std::string("NVIDIA Reflex is on because DLSS frame generation needs it.");
    }
    // XeSS frame generation cannot run without XeLL: it runs whatever render.latency says (the controller's require_driver).
    if (initialized() && impl_->latency.required_driver() == render::LatencyDriver::Xell &&
        driver == render::LatencyDriver::Xell && s.mode != render::LatencyMode::Xell)
        reason += (reason.empty() ? "" : " ") +
                  std::string("XeLL runs because XeSS frame generation needs it (render.latency is \"") +
                  std::string(render::latency_mode_name(s.mode)) + "\").";
    j["reason"] = reason;
    j["modes"] = std::move(modes);
    return j;
}

void Renderer::latency_frame_begin(double refreshHz) {
    if (impl_ && impl_->initialized) impl_->latency.frame_begin(refreshHz);
}

void Renderer::latency_mark(render::LatencyMarker marker) {
    if (impl_ && impl_->initialized) impl_->latency.mark(marker);
}

double Renderer::take_latency_ms() { return impl_ && impl_->initialized ? impl_->latency.take_last_frame_ms() : -1.0; }

Json Renderer::latency_report() {
    Json j = Json::object();
    if (!initialized()) return j;
    const render::LatencyReport r = impl_->latency.report();
    j["driver"] = std::string(render::latency_driver_name(r.driver));
    j["lastMs"] = round3(r.lastMs);
    j["avgMs"] = round3(r.avgMs);
    j["p95Ms"] = round3(r.p95Ms);
    j["maxMs"] = round3(r.maxMs);
    j["samples"] = r.samples;
    j["vendor"] = r.vendor;
    return j;
}

}  // namespace fa
