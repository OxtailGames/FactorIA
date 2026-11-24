#include "fa/render/upscaler.h"

#include <algorithm>
#include <cctype>
#include <cmath>
#include <string>
#include <vector>

#include "fa/core/strings.h"

#include "metalfx.h"

namespace fa::render {

UpscalerMode effective_upscaler_mode(const UpscalerSettings& s, const UpscalerCaps& caps) {
    if (caps.pixelArt) return UpscalerMode::Stretch;
    // The best the GPU can draw from here down: a mode that cannot be drawn falls to the next. Temporal needs a frame of one camera too
    // (caps.multiCamera), and so does the temporal scaler of MetalFX (one history); the spatial scaler of MetalFX needs none.
    const bool temporal_ok = caps.temporal && !caps.multiCamera;
    const bool metalfx_ok = caps.metalfx && (!caps.multiCamera || !caps.metalfxTemporal);
    const auto best_from_metalfx = [&]() {
        if (metalfx_ok) return UpscalerMode::MetalFx;
        if (temporal_ok) return UpscalerMode::Temporal;
        return caps.spatial ? UpscalerMode::Spatial : UpscalerMode::Stretch;
    };
    switch (s.mode) {
        case UpscalerMode::Stretch: return UpscalerMode::Stretch;
        case UpscalerMode::Spatial: return caps.spatial ? UpscalerMode::Spatial : UpscalerMode::Stretch;
        case UpscalerMode::Temporal:
            if (temporal_ok) return UpscalerMode::Temporal;
            return caps.spatial ? UpscalerMode::Spatial : UpscalerMode::Stretch;
        case UpscalerMode::MetalFx:
        case UpscalerMode::Auto: return best_from_metalfx();
    }
    return UpscalerMode::Stretch;
}

MetalFxHere metalfx_available_here() {
    const metalfx::Support s = metalfx::support_default_device();
    MetalFxHere h;
    h.available = s.spatial || s.temporal;
    h.temporal = s.temporal;
    h.reason = s.reason;
    return h;
}

Json upscaler_to_json(const UpscalerSettings& s) {
    Json j = Json::object();
    j["mode"] = std::string(upscaler_mode_name(s.mode));
    j["quality"] = std::string(upscaler_quality_name(s.quality));
    j["sharpness"] = std::round(double(s.sharpness) * 1000.0) / 1000.0;
    return j;
}

namespace {

std::vector<std::string> names_of(const auto& arr) {
    std::vector<std::string> out;
    for (const std::string_view n : arr) out.emplace_back(n);
    return out;
}

// One name out of `names`: its index, or an error that lists the valid ones and the closest.
Result<int> read_name(const Json& j, std::string_view where, const char* key, const auto& names) {
    const std::string ptr = std::string(where) + "/" + key;
    const std::vector<std::string> list = names_of(names);
    if (!j.is_string()) {
        std::string valid;
        for (const std::string& n : list) valid += (valid.empty() ? "\"" : ", \"") + n + "\"";
        return make_error(ptr + ": expected a name, got " + describe_json_value(j), "Use one of " + valid + ".");
    }
    const std::string v = j.get<std::string>();
    for (std::size_t i = 0; i < list.size(); ++i)
        if (list[i] == v) return int(i);
    return make_error(ptr + ": " + describe_json_value(j) + " is not a valid " + key, did_you_mean(v, list));
}

}  // namespace

Result<UpscalerSettings> parse_upscaler_settings(const Json& j, std::string_view where, const UpscalerSettings& base) {
    if (!j.is_object())
        return make_error(std::string(where) +
                              ": expected an object like {\"mode\": \"spatial\", \"quality\": \"balanced\", "
                              "\"sharpness\": 0.5}, got " +
                              describe_json_value(j),
                          "Every key is optional: mode, quality, sharpness.");
    static const std::vector<std::string> keys = {"mode", "quality", "sharpness"};
    for (auto e = j.begin(); e != j.end(); ++e)
        if (std::find(keys.begin(), keys.end(), e.key()) == keys.end())
            return make_error(std::string(where) + "/" + e.key() + ": '" + e.key() + "' is not an upscaler setting",
                              did_you_mean(e.key(), keys));
    UpscalerSettings s = base;
    if (auto it = j.find("mode"); it != j.end()) {
        auto r = read_name(*it, where, "mode", kUpscalerModeNames);
        if (!r.ok()) return r.error();
        s.mode = UpscalerMode(*r);
    }
    if (auto it = j.find("quality"); it != j.end()) {
        auto r = read_name(*it, where, "quality", kUpscalerQualityNames);
        if (!r.ok()) return r.error();
        s.quality = UpscalerQuality(*r);
    }
    if (auto it = j.find("sharpness"); it != j.end()) {
        const std::string ptr = std::string(where) + "/sharpness";
        if (!it->is_number())
            return make_error(ptr + ": expected a number from 0 to 1, got " + describe_json_value(*it),
                              "0 = no sharpening, 1 = the strongest; 0.5 is the default.");
        const double d = it->get<double>();
        if (!(d >= 0.0 && d <= 1.0))
            return make_error(ptr + ": " + describe_json_value(*it) + " is outside 0..1",
                              "Use a number from 0 (no sharpening) to 1 (the strongest); 0.5 is the default.");
        s.sharpness = float(d);
    }
    return s;
}

}  // namespace fa::render
