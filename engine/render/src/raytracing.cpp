#include "fa/render/raytracing.h"

#include <algorithm>
#include <string>
#include <vector>

#include "fa/core/strings.h"

namespace fa::render {

Json ray_tracing_to_json(const RayTracingSettings& s) {
    Json j = Json::object();
    j["enabled"] = s.enabled;
    j["shadows"] = std::string(rt_shadows_name(s.shadows));
    j["ao"] = s.ao;
    j["reflections"] = s.reflections;
    j["translucency"] = s.translucency;
    j["gi"] = std::string(rt_gi_name(s.gi));
    j["raysPerPixel"] = s.raysPerPixel;
    j["maxInstances"] = s.maxInstances;
    return j;
}

namespace {

// The index of the name `j` holds in `names`, or the error that names `ptr`, the valid values and the nearest one.
template <std::size_t N>
Result<int> parse_name(const Json& j, const std::string& ptr, const std::array<std::string_view, N>& names,
                       const char* what) {
    std::vector<std::string> list;
    for (const std::string_view n : names) list.emplace_back(n);
    if (!j.is_string()) {
        std::string valid;
        for (const std::string& n : list) valid += (valid.empty() ? "\"" : ", \"") + n + "\"";
        return make_error(ptr + ": expected a name, got " + describe_json_value(j), "Use one of " + valid + ".");
    }
    const std::string v = j.get<std::string>();
    const auto f = std::find(list.begin(), list.end(), v);
    if (f == list.end())
        return make_error(ptr + ": " + describe_json_value(j) + " is not a valid " + what, did_you_mean(v, list));
    return int(f - list.begin());
}

Result<bool> parse_bool(const Json& j, const std::string& ptr, const char* meaning) {
    if (!j.is_boolean()) return make_error(ptr + ": expected true or false, got " + describe_json_value(j), meaning);
    return j.get<bool>();
}

// A whole number clamped to [lo, hi] before it is narrowed (a number past the int range is clamped, never wrapped).
Result<int> parse_clamped_int(const Json& j, const std::string& ptr, int lo, int hi, const char* meaning) {
    if (!j.is_number_integer())
        return make_error(ptr + ": expected a whole number, got " + describe_json_value(j),
                          std::string(meaning) + " A whole number of " + std::to_string(lo) + " to " +
                              std::to_string(hi) + " (a value outside is clamped).");
    const double v = j.get<double>();
    return int(std::clamp(v, double(lo), double(hi)));
}

}  // namespace

Result<RayTracingSettings> parse_ray_tracing_settings(const Json& j, std::string_view where,
                                                      const RayTracingSettings& base) {
    if (!j.is_object())
        return make_error(
            std::string(where) + ": expected an object like {\"enabled\": true, \"shadows\": \"soft\"}, got " +
                describe_json_value(j),
            "Every key is optional: enabled, shadows (off, hard, soft), ao, reflections, translucency, gi (off, "
            "probes, perPixel), raysPerPixel (1 to 16), maxInstances (1 to 1048576).");
    static const std::vector<std::string> keys = {"enabled",      "shadows", "ao",           "reflections",
                                                  "translucency", "gi",      "raysPerPixel", "maxInstances"};
    for (auto e = j.begin(); e != j.end(); ++e)
        if (std::find(keys.begin(), keys.end(), e.key()) == keys.end())
            return make_error(std::string(where) + "/" + e.key() + ": '" + e.key() + "' is not a ray tracing setting",
                              did_you_mean(e.key(), keys));
    RayTracingSettings s = base;
    const std::string w(where);
    if (auto it = j.find("enabled"); it != j.end()) {
        auto v = parse_bool(*it, w + "/enabled",
                            "enabled is the master switch: false (the default) builds and traces nothing.");
        if (!v) return v.error();
        s.enabled = v.value();
    }
    if (auto it = j.find("shadows"); it != j.end()) {
        auto v = parse_name(*it, w + "/shadows", kRtShadowsNames, "shadows mode");
        if (!v) return v.error();
        s.shadows = RtShadows(v.value());
    }
    if (auto it = j.find("ao"); it != j.end()) {
        auto v = parse_bool(*it, w + "/ao", "ao traces ambient occlusion with rays.");
        if (!v) return v.error();
        s.ao = v.value();
    }
    if (auto it = j.find("reflections"); it != j.end()) {
        auto v = parse_bool(*it, w + "/reflections", "reflections traces reflections with rays.");
        if (!v) return v.error();
        s.reflections = v.value();
    }
    if (auto it = j.find("translucency"); it != j.end()) {
        auto v = parse_bool(*it, w + "/translucency",
                            "translucency traces the refraction through glass and liquids with rays.");
        if (!v) return v.error();
        s.translucency = v.value();
    }
    if (auto it = j.find("gi"); it != j.end()) {
        auto v = parse_name(*it, w + "/gi", kRtGiNames, "global illumination mode");
        if (!v) return v.error();
        s.gi = RtGi(v.value());
    }
    if (auto it = j.find("raysPerPixel"); it != j.end()) {
        auto v = parse_clamped_int(*it, w + "/raysPerPixel", kRtMinRaysPerPixel, kRtMaxRaysPerPixel,
                                   "raysPerPixel is the number of rays each effect casts per pixel and frame.");
        if (!v) return v.error();
        s.raysPerPixel = v.value();
    }
    if (auto it = j.find("maxInstances"); it != j.end()) {
        auto v = parse_clamped_int(*it, w + "/maxInstances", kRtMinMaxInstances, kRtMaxMaxInstances,
                                   "maxInstances is the most instances the top-level structure holds.");
        if (!v) return v.error();
        s.maxInstances = v.value();
    }
    return s;
}

}  // namespace fa::render
