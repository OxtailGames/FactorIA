#include "fa/scene/curve.h"

#include <algorithm>
#include <cmath>
#include <format>

#include "fa/core/strings.h"

namespace fa {

namespace {

constexpr const char* kCurveForm = "Write keys as [position, value] pairs: [[0, 1], [0.5, 2], [1, 0]], or {\"keys\": "
                                   "[[0, 0], [1, 1]], \"interp\": \"smooth\"}, "
                                   "or one number for a constant.";
constexpr const char* kGradientForm =
    "Write keys as [position, colour] pairs: [[0, \"#ffffff\"], [0.5, \"#ffcc00\"], [1, [1, 0, 0, 0]]]; the "
    "colour is \"#rrggbb\", \"#rrggbbaa\", a colour name or [r, g, b, a] (0..1).";

float smooth01(float s) { return s * s * (3.0f - 2.0f * s); }

Error bad(std::string_view what, const std::string& message, const char* hint) {
    return Error{std::format("{}: {}", what, message), hint};
}

bool read_key_t(const Json& v, float& out) {
    if (!v.is_number()) return false;
    const double d = v.get<double>();
    if (!std::isfinite(d)) return false;
    out = float(d);
    return true;
}

}  // namespace

float Curve::eval(float t) const {
    if (keys.empty()) return 0.0f;
    if (!(t == t)) t = 0.0f;
    if (t <= keys.front().t) return keys.front().value;
    if (t >= keys.back().t) return keys.back().value;
    // Few keys (at most 16): a linear scan is the fastest search.
    std::size_t i = 1;
    while (i < keys.size() && keys[i].t < t) ++i;
    const CurveKey& a = keys[i - 1];
    const CurveKey& b = keys[i];
    if (interp == CurveInterp::Step) return t >= b.t ? b.value : a.value;  // jumps at the key
    const float span = b.t - a.t;
    if (!(span > 0.0f)) return b.value;
    float s = (t - a.t) / span;
    if (interp == CurveInterp::Smooth) s = smooth01(s);
    return a.value + (b.value - a.value) * s;
}

Curve Curve::constant(float v) {
    Curve c;
    c.keys.push_back({0.0f, v});
    return c;
}

bool Curve::operator==(const Curve& o) const {
    if (interp != o.interp || keys.size() != o.keys.size()) return false;
    for (std::size_t i = 0; i < keys.size(); ++i)
        if (keys[i].t != o.keys[i].t || keys[i].value != o.keys[i].value) return false;
    return true;
}

Result<Curve> Curve::parse(const Json& j, std::string_view what) {
    Curve out;
    if (j.is_null()) return out;
    if (j.is_number()) {
        const double d = j.get<double>();
        if (!std::isfinite(d)) return bad(what, "a curve value must be a finite number", kCurveForm);
        return Curve::constant(float(d));
    }
    const Json* list = &j;
    if (j.is_object()) {
        static const std::vector<std::string> known = {"keys", "interp"};
        for (auto it = j.begin(); it != j.end(); ++it)
            if (std::find(known.begin(), known.end(), it.key()) == known.end())
                return bad(what, std::format("unknown key '{}' in a curve", it.key()),
                           (did_you_mean(it.key(), known) + " A curve object has \"keys\" and \"interp\".").c_str());
        if (!j.contains("keys")) return bad(what, "a curve object needs \"keys\"", kCurveForm);
        list = &j["keys"];
        if (j.contains("interp")) {
            const Json& ip = j["interp"];
            const std::string name = ip.is_string() ? ip.get<std::string>() : std::string();
            if (name == "linear")
                out.interp = CurveInterp::Linear;
            else if (name == "smooth")
                out.interp = CurveInterp::Smooth;
            else if (name == "step")
                out.interp = CurveInterp::Step;
            else
                return bad(what, std::format("interp is {}, not one of linear, smooth, step", describe_json_value(ip)),
                           kCurveForm);
        }
    }
    if (!list->is_array())
        return bad(what, std::format("expected an array of keys, got {}", describe_json_value(*list)), kCurveForm);
    if (int(list->size()) > kMaxCurveKeys)
        return bad(what, std::format("{} keys, at most {} are allowed", list->size(), kMaxCurveKeys),
                   "Drop the keys that hardly change the shape.");
    for (std::size_t i = 0; i < list->size(); ++i) {
        const Json& k = (*list)[i];
        CurveKey key;
        if (!k.is_array() || k.size() != 2 || !read_key_t(k[0], key.t) || !read_key_t(k[1], key.value))
            return bad(what,
                       std::format("key {} is {}, not [position, value] with two numbers", i, describe_json_value(k)),
                       kCurveForm);
        out.keys.push_back(key);
    }
    std::stable_sort(out.keys.begin(), out.keys.end(), [](const CurveKey& a, const CurveKey& b) { return a.t < b.t; });
    return out;
}

Json Curve::to_json() const {
    Json arr = Json::array();
    for (const CurveKey& k : keys) arr.push_back(Json::array({fa::to_json(k.t), fa::to_json(k.value)}));
    if (interp == CurveInterp::Linear) return arr;
    return Json::object({{"keys", arr}, {"interp", interp == CurveInterp::Smooth ? "smooth" : "step"}});
}

Color Gradient::eval(float t) const {
    if (keys.empty()) return Color{1, 1, 1, 0};
    if (!(t == t)) t = 0.0f;
    if (t <= keys.front().t) return keys.front().color;
    if (t >= keys.back().t) return keys.back().color;
    std::size_t i = 1;
    while (i < keys.size() && keys[i].t < t) ++i;
    const GradientKey& a = keys[i - 1];
    const GradientKey& b = keys[i];
    const float span = b.t - a.t;
    if (!(span > 0.0f)) return b.color;
    return lerp(a.color, b.color, (t - a.t) / span);
}

bool Gradient::operator==(const Gradient& o) const {
    if (keys.size() != o.keys.size()) return false;
    for (std::size_t i = 0; i < keys.size(); ++i)
        if (keys[i].t != o.keys[i].t || !(keys[i].color == o.keys[i].color)) return false;
    return true;
}

Result<Gradient> Gradient::parse(const Json& j, std::string_view what) {
    Gradient out;
    if (j.is_null()) return out;
    if (!j.is_array())
        return bad(what, std::format("expected an array of keys, got {}", describe_json_value(j)), kGradientForm);
    if (int(j.size()) > kMaxCurveKeys)
        return bad(what, std::format("{} keys, at most {} are allowed", j.size(), kMaxCurveKeys),
                   "Drop the keys that hardly change the colour.");
    for (std::size_t i = 0; i < j.size(); ++i) {
        const Json& k = j[i];
        GradientKey key;
        std::string err;
        if (!k.is_array() || k.size() != 2 || !read_key_t(k[0], key.t))
            return bad(what, std::format("key {} is {}, not [position, colour]", i, describe_json_value(k)),
                       kGradientForm);
        if (!json_to(k[1], key.color, &err))
            return bad(what, std::format("key {} has a colour that does not read: {}", i, err), kGradientForm);
        out.keys.push_back(key);
    }
    std::stable_sort(out.keys.begin(), out.keys.end(),
                     [](const GradientKey& a, const GradientKey& b) { return a.t < b.t; });
    return out;
}

Json Gradient::to_json() const {
    Json arr = Json::array();
    for (const GradientKey& k : keys) arr.push_back(Json::array({fa::to_json(k.t), fa::to_json(k.color)}));
    return arr;
}

}  // namespace fa
