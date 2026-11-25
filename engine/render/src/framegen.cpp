#include "fa/render/framegen.h"

#include <algorithm>
#include <string>
#include <vector>

#include "fa/core/strings.h"

namespace fa::render {

FrameGenSlot frame_gen_slot_of_mode(FrameGenMode m) {
    switch (m) {
        case FrameGenMode::Dlss: return FrameGenSlot::Dlss;
        case FrameGenMode::Fsr: return FrameGenSlot::Fsr;
        case FrameGenMode::Xess: return FrameGenSlot::Xess;
        case FrameGenMode::Off:
        case FrameGenMode::Auto: break;
    }
    return FrameGenSlot::None;
}

FrameGenSlot frame_gen_slot_for_vendor(GpuVendor v) {
    switch (v) {
        case GpuVendor::Nvidia: return FrameGenSlot::Dlss;
        case GpuVendor::Amd: return FrameGenSlot::Fsr;
        case GpuVendor::Intel: return FrameGenSlot::Xess;
        case GpuVendor::None:
        case GpuVendor::Apple:
        case GpuVendor::Other: break;
    }
    return FrameGenSlot::None;
}

FrameGenSlot effective_frame_generation(const FrameGenSettings& s, const FrameGenCaps& caps) {
    const auto usable = [&](FrameGenSlot slot) {
        return slot == FrameGenSlot::Dlss   ? caps.dlss
               : slot == FrameGenSlot::Fsr  ? caps.fsr
               : slot == FrameGenSlot::Xess ? caps.xess
                                            : false;
    };
    if (s.mode == FrameGenMode::Off) return FrameGenSlot::None;
    const FrameGenSlot named =
        s.mode == FrameGenMode::Auto ? frame_gen_slot_for_vendor(caps.gpuVendor) : frame_gen_slot_of_mode(s.mode);
    return usable(named) ? named : FrameGenSlot::None;
}

Json frame_gen_to_json(const FrameGenSettings& s) {
    Json j = Json::object();
    j["mode"] = std::string(frame_gen_mode_name(s.mode));
    j["minBaseFps"] = s.minBaseFps;
    return j;
}

Result<FrameGenSettings> parse_frame_gen_settings(const Json& j, std::string_view where, const FrameGenSettings& base) {
    if (!j.is_object())
        return make_error(
            std::string(where) + ": expected an object like {\"mode\": \"auto\", \"minBaseFps\": 60}, got " +
                describe_json_value(j),
            "Every key is optional: mode (off, auto, dlss, fsr, xess), minBaseFps (a whole number of 0 to " +
                std::to_string(kFrameGenMaxMinBaseFps) + ").");
    static const std::vector<std::string> keys = {"mode", "minBaseFps"};
    for (auto e = j.begin(); e != j.end(); ++e)
        if (std::find(keys.begin(), keys.end(), e.key()) == keys.end())
            return make_error(std::string(where) + "/" + e.key() + ": '" + e.key() +
                                  "' is not a frame generation setting",
                              did_you_mean(e.key(), keys));
    FrameGenSettings s = base;
    if (auto it = j.find("mode"); it != j.end()) {
        const std::string ptr = std::string(where) + "/mode";
        std::vector<std::string> names;
        for (const std::string_view n : kFrameGenModeNames) names.emplace_back(n);
        if (!it->is_string()) {
            std::string valid;
            for (const std::string& n : names) valid += (valid.empty() ? "\"" : ", \"") + n + "\"";
            return make_error(ptr + ": expected a name, got " + describe_json_value(*it), "Use one of " + valid + ".");
        }
        const std::string v = it->get<std::string>();
        const auto f = std::find(names.begin(), names.end(), v);
        if (f == names.end())
            return make_error(ptr + ": " + describe_json_value(*it) + " is not a valid mode", did_you_mean(v, names));
        s.mode = FrameGenMode(int(f - names.begin()));
    }
    if (auto it = j.find("minBaseFps"); it != j.end()) {
        const std::string ptr = std::string(where) + "/minBaseFps";
        const std::string hint =
            "minBaseFps is the frame rate the game renders at (generated frames not counted) below which "
            "generation is switched off: a whole number of 0 (never switch off) to " +
            std::to_string(kFrameGenMaxMinBaseFps) + ", usually 30 to 60.";
        if (!it->is_number_integer())
            return make_error(ptr + ": expected a whole number, got " + describe_json_value(*it), hint);
        // Clamped before it is narrowed: a number past the int range is an error, never a wrapped value.
        const double v = it->get<double>();
        if (!(v >= 0.0) || v > double(kFrameGenMaxMinBaseFps))
            return make_error(ptr + ": " + describe_json_value(*it) + " is out of range", hint);
        s.minBaseFps = int(v);
    }
    return s;
}

}  // namespace fa::render
