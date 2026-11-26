#include "fa/render/latency.h"

#include <algorithm>
#include <string>
#include <vector>

#include "fa/core/strings.h"

namespace fa::render {

std::string_view latency_marker_name(LatencyMarker m) {
    switch (m) {
        case LatencyMarker::SimulationStart: return "simulationStart";
        case LatencyMarker::InputSample: return "inputSample";
        case LatencyMarker::SimulationEnd: return "simulationEnd";
        case LatencyMarker::RenderSubmitStart: return "renderSubmitStart";
        case LatencyMarker::RenderSubmitEnd: return "renderSubmitEnd";
        case LatencyMarker::PresentStart: return "presentStart";
        case LatencyMarker::PresentEnd: return "presentEnd";
    }
    return "unknown";
}

LatencyDriver effective_latency_driver(const LatencySettings& s, const LatencyCaps& caps) {
    if (s.mode == LatencyMode::Off) return LatencyDriver::None;
    const LatencyDriver fallback = caps.pacing ? LatencyDriver::Pacing : LatencyDriver::None;
    switch (s.mode) {
        case LatencyMode::Reflex: return caps.reflex ? LatencyDriver::Reflex : fallback;
        case LatencyMode::AntiLag2: return caps.antiLag2 ? LatencyDriver::AntiLag2 : fallback;
        case LatencyMode::Xell: return caps.xell ? LatencyDriver::Xell : fallback;
        case LatencyMode::Auto:
            if (caps.gpuVendor == GpuVendor::Nvidia && caps.reflex) return LatencyDriver::Reflex;
            if (caps.gpuVendor == GpuVendor::Amd && caps.antiLag2) return LatencyDriver::AntiLag2;
            if (caps.gpuVendor == GpuVendor::Intel && caps.xell) return LatencyDriver::Xell;
            return fallback;
        case LatencyMode::Off: break;
    }
    return LatencyDriver::None;
}

Json latency_to_json(const LatencySettings& s) {
    Json j = Json::object();
    j["mode"] = std::string(latency_mode_name(s.mode));
    j["boost"] = s.boost;
    return j;
}

Result<LatencySettings> parse_latency_settings(const Json& j, std::string_view where, const LatencySettings& base) {
    if (!j.is_object())
        return make_error(std::string(where) +
                              ": expected an object like {\"mode\": \"auto\", \"boost\": false}, got " +
                              describe_json_value(j),
                          "Every key is optional: mode (off, auto, reflex, antilag2, xell), boost (true or false).");
    static const std::vector<std::string> keys = {"mode", "boost"};
    for (auto e = j.begin(); e != j.end(); ++e)
        if (std::find(keys.begin(), keys.end(), e.key()) == keys.end())
            return make_error(std::string(where) + "/" + e.key() + ": '" + e.key() + "' is not a latency setting",
                              did_you_mean(e.key(), keys));
    LatencySettings s = base;
    if (auto it = j.find("mode"); it != j.end()) {
        const std::string ptr = std::string(where) + "/mode";
        std::vector<std::string> names;
        for (const std::string_view n : kLatencyModeNames) names.emplace_back(n);
        if (!it->is_string()) {
            std::string valid;
            for (const std::string& n : names) valid += (valid.empty() ? "\"" : ", \"") + n + "\"";
            return make_error(ptr + ": expected a name, got " + describe_json_value(*it), "Use one of " + valid + ".");
        }
        const std::string v = it->get<std::string>();
        const auto f = std::find(names.begin(), names.end(), v);
        if (f == names.end())
            return make_error(ptr + ": " + describe_json_value(*it) + " is not a valid mode", did_you_mean(v, names));
        s.mode = LatencyMode(int(f - names.begin()));
    }
    if (auto it = j.find("boost"); it != j.end()) {
        if (!it->is_boolean())
            return make_error(
                std::string(where) + "/boost: expected true or false, got " + describe_json_value(*it),
                "boost keeps the GPU clocks up while the game waits (NVIDIA Reflex and Intel XeLL); it costs power.");
        s.boost = it->get<bool>();
    }
    return s;
}

}  // namespace fa::render
