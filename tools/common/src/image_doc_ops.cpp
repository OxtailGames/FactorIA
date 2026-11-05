// Adjustments and effects of an image document: the lists a layer carries (and an adjustment layer applies to what lies
// below it). A new operation is one entry in adjustment_defs() or effect_defs() (name, description for the docs and the errors,
// the keys it takes), its checks in check_op, and one case in apply_adjustments / apply_effects.
//
// Where they run, for one layer (image_doc_render.cpp): content -> ADJUSTMENTS -> masks -> EFFECTS -> clipping -> opacity ->
// blend. Adjustments change colours only, so the layer's footprint is still its content's when the masks are applied. Effects
// come after the masks and may change the footprint (a shadow or an outline grows the raster; the raster keeps its origin, so
// nothing else needs to know).
//
// Adjustments: invert, brightness, levels, curves, hsv, posterize, quantize, dither, gradientMap, colorBalance, threshold.
// Effects: colorOverlay, outline, stroke, dropShadow, outerGlow, innerGlow, blur, sharpen, noise, shade.
//
// Everything is CPU, float and deterministic (no clock, no random numbers: noise is a hash of the seed and the pixel), and works
// on the stored (sRGB-encoded) values like the compositor. Blurs are separable.
#include <algorithm>
#include <array>
#include <cmath>
#include <cstdint>
#include <filesystem>

#include "fa/core/strings.h"
#include "fa/tooling/project_fs.h"
#include "image_doc_internal.h"

namespace fa {

namespace {

struct OpDef {
    const char* name;
    const char* description;
    std::vector<std::string> keys;  // the fields besides "type"
};

const std::vector<OpDef>& adjustment_defs() {
    static const std::vector<OpDef> defs = {
        {"invert", "Inverts the colour (alpha stays): {\"type\": \"invert\"}.", {}},
        {"brightness", "Adds `amount` (-1..1, default 0.2) to red, green and blue, clamped: {\"type\": \"brightness\", \"amount\": 0.2}.", {"amount"}},
        {"levels",
         "Levels: input `inBlack` (0..1, default 0) and `inWhite` (1) are stretched to 0 and 1, `gamma` (0.1..10, default 1; above 1 brightens the "
         "midtones) bends the middle, then 0..1 is mapped to `outBlack` (0) .. `outWhite` (1). `channel`: rgb (default), red, green or blue: "
         "{\"type\": \"levels\", \"inBlack\": 0.1, \"inWhite\": 0.9, \"gamma\": 1.2, \"channel\": \"rgb\"}.",
         {"inBlack", "inWhite", "gamma", "outBlack", "outWhite", "channel"}},
        {"curves",
         "A tone curve through `points` ([[x, y], ...], 2 to 32 points, x strictly increasing, both in 0..1) drawn as a monotone cubic "
         "(it never overshoots between points; left of the first point the curve is flat, right of the last too). `channel`: rgb "
         "(default), red, green or blue: {\"type\": \"curves\", \"points\": [[0, 0], [0.25, 0.15], [0.75, 0.9], [1, 1]]}.",
         {"points", "channel"}},
        {"hsv",
         "Hue, saturation and value. `hue` (degrees, -180..180) turns the hue, `saturation` (-1..1) scales the saturation by 1 + it, "
         "`value` (-1..1) is added to the value. With `colorize: true` every pixel gets the hue `hue` (0..360) and the saturation "
         "`saturation` (0..1, default 0.5) and keeps its own brightness (Rec. 709 luma) plus `value`: "
         "{\"type\": \"hsv\", \"hue\": 30, \"saturation\": -0.2} or {\"type\": \"hsv\", \"colorize\": true, \"hue\": 210}.",
         {"hue", "saturation", "value", "colorize"}},
        {"posterize", "Rounds each channel to `levels` evenly spaced values (2..256, default 4): {\"type\": \"posterize\", \"levels\": 4}.", {"levels"}},
        {"quantize",
         "Maps every pixel to the nearest colour of `palette`: \"style\" (default: the `style.palette` of assets.json) or a list of colours "
         "([\"#1a1c2c\", \"#5d275d\", ...]). Nearest is measured in `space`: oklab (default, perceptual: Euclidean distance in OKLab) or "
         "rgb (in the stored values). `dither` (default none, see the dither operation) and `strength` (0..1, default 1) spread the error: "
         "{\"type\": \"quantize\", \"palette\": \"style\", \"dither\": \"bayer4\"}. Alpha is kept.",
         {"palette", "space", "dither", "strength"}},
        {"dither",
         "Reduces the colours with a dither `method`: none, bayer2, bayer4 (default), bayer8 (ordered, a threshold matrix tiled over the "
         "layer's own pixels) or floydSteinberg, atkinson (error diffusion, left to right and top to bottom, only into visible pixels). "
         "It maps to `palette` (\"style\" or a list of colours, as in quantize; `space` oklab or rgb) when one is given, otherwise to "
         "`levels` evenly spaced values per channel (2..256, default 2). `strength` (0..1, default 1) scales the dither: "
         "{\"type\": \"dither\", \"method\": \"floydSteinberg\", \"palette\": \"style\"}. Alpha is kept.",
         {"method", "levels", "palette", "space", "strength"}},
        {"gradientMap",
         "Replaces the colour by the colour of a gradient at the pixel's brightness (Rec. 709 luma of the stored values, 0 = first stop). "
         "`stops` is [{\"at\": 0..1, \"color\": ...}, ...] (2 to 64, `at` not decreasing); the alpha of a stop is ignored: "
         "{\"type\": \"gradientMap\", \"stops\": [{\"at\": 0, \"color\": \"#000020\"}, {\"at\": 1, \"color\": \"#ffe0a0\"}]}.",
         {"stops"}},
        {"colorBalance",
         "Shifts the colour of the `shadows`, `midtones` and `highlights` ([red, green, blue], each -1..1; 0.2 is a clear tint). A pixel's "
         "weights come from its luma l: shadows (1 - l)^2, highlights l^2, midtones 4 l (1 - l): "
         "{\"type\": \"colorBalance\", \"shadows\": [0, 0, 0.2], \"highlights\": [0.1, 0.05, 0]}.",
         {"shadows", "midtones", "highlights"}},
        {"threshold",
         "Pixels whose luma (Rec. 709) is at least `level` (0..1, default 0.5) become `above` (default white), the others `below` (default "
         "black); alpha is kept: {\"type\": \"threshold\", \"level\": 0.5}.",
         {"level", "above", "below"}},
    };
    return defs;
}

const std::vector<OpDef>& effect_defs() {
    static const std::vector<OpDef> defs = {
        {"colorOverlay", "Mixes the colour of the layer towards `color` by `amount` (0..1, default 1), keeping its alpha: {\"type\": \"colorOverlay\", \"color\": \"#ff0000\", \"amount\": 0.5}.",
         {"color", "amount"}},
        {"outline",
         "A line of `color` (default black) `width` pixels wide (0.5..64, default 1) around the shape of the layer, from its alpha: a pixel "
         "belongs to the shape when its alpha is above 0.5. `position`: outside (default, drawn behind and growing the layer), inside "
         "(over the edge of the shape) or center. The stroke reaches the pixels whose centre is within `width` of the shape (Euclidean), "
         "so width 1 is the exact 4-connected outline of pixel art; `smooth: true` anti-aliases the edge of the stroke instead of "
         "cutting it: {\"type\": \"outline\", \"color\": \"#000000\", \"width\": 1}.",
         {"color", "width", "position", "smooth"}},
        {"stroke", "The same as outline, but `position` defaults to center (half of the width on each side): {\"type\": \"stroke\", \"color\": \"#ffffff\", \"width\": 2}.",
         {"color", "width", "position", "smooth"}},
        {"dropShadow",
         "A shadow of the layer's shape behind it: moved by `offsetX`, `offsetY` pixels (-512..512, default 2, 2; whole pixels), blurred "
         "(`blur` -> Gaussian sigma blur / 2, 0..64, default 2), in `color` (default black) at `opacity` (0..1, default 0.5): "
         "{\"type\": \"dropShadow\", \"offsetX\": 3, \"offsetY\": 3, \"blur\": 4, \"opacity\": 0.6}.",
         {"offsetX", "offsetY", "blur", "color", "opacity"}},
        {"outerGlow",
         "A soft halo behind the layer: its alpha blurred by `size` (Gaussian sigma size / 2, 0..64, default 4), times `strength` (0..8, "
         "default 1; clamped to 1) and `opacity` (0..1, default 1), in `color` (default white): "
         "{\"type\": \"outerGlow\", \"color\": \"#ffee88\", \"size\": 6, \"strength\": 2}.",
         {"color", "size", "strength", "opacity"}},
        {"innerGlow",
         "A glow from the edge of the shape inwards: the transparency around the layer blurred by `size` (sigma size / 2, 0..64, default 4), "
         "times `strength` (0..8, default 1) and `opacity` (0..1, default 1), mixed into the layer's colour in `color` (default white); alpha "
         "stays: {\"type\": \"innerGlow\", \"color\": \"#ffffff\", \"size\": 5}.",
         {"color", "size", "strength", "opacity"}},
        {"blur",
         "Blurs the layer (colour and alpha, weighted by alpha, so it never darkens its edge). `mode`: gaussian (default; `radius` is the "
         "standard deviation in pixels, 0..64, default 2) or box (`radius` is the half-width: a window of 2 radius + 1 pixels, whole "
         "pixels). The layer grows to hold the blur: {\"type\": \"blur\", \"radius\": 3}.",
         {"mode", "radius"}},
        {"sharpen",
         "Unsharp mask: adds `amount` (0..10, default 1) times the difference between the layer and its Gaussian blur of sigma `radius` "
         "(0.1..32, default 1); a difference smaller than `threshold` (0..1, default 0) is left alone. Alpha stays: "
         "{\"type\": \"sharpen\", \"radius\": 1, \"amount\": 1.5}.",
         {"radius", "amount", "threshold"}},
        {"noise",
         "Adds noise to the visible pixels: uniform in -`amount`..`amount` (0..1, default 0.1), from a hash of `seed` (integer, default 0) "
         "and the pixel, so the same seed gives the same noise. `mode`: mono (default, the same value on red, green and blue) or color: "
         "{\"type\": \"noise\", \"amount\": 0.08, \"seed\": 7}.",
         {"amount", "seed", "mode"}},
        {"shade",
         "Lights the layer from a normal map: `normalMap` is a PNG of the project (tangent space, green up like OpenGL; `flipGreen: true` "
         "for green down), read at the layer's own pixels (outside it, or where it is transparent, the surface is flat). Without it the "
         "surface is a height map made of the layer's alpha blurred by `smooth` pixels (sigma, 0..16, default 1) with slopes scaled by "
         "`strength` (0..32, default 3), so the edges of a shape bulge. The light comes from `lightDirection` (degrees, counter-clockwise "
         "from +x, 90 is up; default `style.lightDirection` of assets.json, else 135 = upper left) at `elevation` degrees above the "
         "layer (1..90, default 45). Colour is multiplied by 1 + 2 `intensity` (n.L - L.z) (a flat surface keeps its colour), `intensity` "
         "0..4, default 1; `amount` (0..1, default 1) mixes the result in: {\"type\": \"shade\", \"strength\": 4}.",
         {"normalMap", "flipGreen", "smooth", "strength", "lightDirection", "elevation", "intensity", "amount"}},
    };
    return defs;
}

std::vector<ImageOpInfo> infos(const std::vector<OpDef>& defs) {
    std::vector<ImageOpInfo> out;
    for (const OpDef& d : defs) out.push_back({d.name, d.description});
    return out;
}

}  // namespace

std::vector<ImageOpInfo> image_adjustment_types() { return infos(adjustment_defs()); }
std::vector<ImageOpInfo> image_effect_types() { return infos(effect_defs()); }

}  // namespace fa

namespace fa::imgdoc {

namespace {

namespace stdfs = std::filesystem;

const std::vector<OpDef>& defs_of(bool effect) { return effect ? effect_defs() : adjustment_defs(); }

float number_or(const Json& op, const char* key, float fallback) {
    auto it = op.find(key);
    return it != op.end() && it->is_number() ? it->get<float>() : fallback;
}
std::string string_or(const Json& op, const char* key, const char* fallback) {
    auto it = op.find(key);
    return it != op.end() && it->is_string() ? it->get<std::string>() : fallback;
}
bool bool_or(const Json& op, const char* key, bool fallback) {
    auto it = op.find(key);
    return it != op.end() && it->is_boolean() ? it->get<bool>() : fallback;
}
Color color_or(const Json& op, const char* key, Color fallback) {
    auto it = op.find(key);
    Color c;
    std::string err;
    return it != op.end() && json_to(*it, c, &err) ? c : fallback;
}

std::string num(float v) {
    char buf[32];
    std::snprintf(buf, sizeof buf, "%g", v);
    return buf;
}

const std::vector<std::string>& channels() {
    static const std::vector<std::string> v = {"rgb", "red", "green", "blue"};
    return v;
}
const std::vector<std::string>& dither_methods() {
    static const std::vector<std::string> v = {"none", "bayer2", "bayer4", "bayer8", "floydSteinberg", "atkinson"};
    return v;
}

bool is_array_of_numbers(const Json& j, std::size_t n) {
    if (!j.is_array() || j.size() != n) return false;
    for (const Json& v : j)
        if (!v.is_number()) return false;
    return true;
}

}  // namespace

// ---- validation ------------------------------------------------------------------------------------------------------

void check_op(bool effect, const Json& op, const std::string& pointer, std::vector<ImageIssue>& issues, const std::string& projectDir) {
    const char* list = effect ? "effects" : "adjustments";
    const auto& defs = defs_of(effect);
    std::vector<std::string> names;
    for (const OpDef& d : defs) names.push_back(d.name);
    if (!op.is_object()) {
        issues.push_back({pointer, std::string("An entry of `") + list + "` must be an object, got " + describe_json_value(op) + ".",
                          "Write {\"type\": \"" + names.front() + "\"}. Types: " + join(names, ", ") + "."});
        return;
    }
    auto type = op.find("type");
    if (type == op.end() || !type->is_string()) {
        issues.push_back({pointer + "/type", "Every entry of `" + std::string(list) + "` needs a string `type`.", "Types: " + join(names, ", ") + "."});
        return;
    }
    const OpDef* def = nullptr;
    for (const OpDef& d : defs)
        if (type->get<std::string>() == d.name) def = &d;
    if (!def) {
        issues.push_back({pointer + "/type", "Unknown " + std::string(effect ? "effect" : "adjustment") + " type '" + type->get<std::string>() + "'.",
                          did_you_mean(type->get<std::string>(), names) + " Types: " + join(names, ", ") + "."});
        return;
    }
    std::vector<std::string> allowed = def->keys;
    allowed.push_back("type");
    for (auto it = op.begin(); it != op.end(); ++it) {
        if (std::find(allowed.begin(), allowed.end(), it.key()) != allowed.end()) continue;
        std::string escaped;
        for (char c : it.key()) escaped += c == '~' ? "~0" : c == '/' ? "~1" : std::string(1, c);
        issues.push_back({pointer + "/" + escaped, "Unknown key '" + it.key() + "' for " + def->name + ".", did_you_mean(it.key(), allowed) + " " + def->description});
    }
    const std::string kind = def->name;
    auto bad = [&](const std::string& key, const std::string& message) { issues.push_back({pointer + "/" + key, message, def->description}); };
    auto range = [&](const char* key, float lo, float hi) {
        auto it = op.find(key);
        if (it == op.end()) return;
        if (!it->is_number() || it->get<float>() < lo || it->get<float>() > hi)
            bad(key, std::string("`") + key + "` of " + kind + " must be a number from " + num(lo) + " to " + num(hi) + ", got " + describe_json_value(*it) + ".");
    };
    auto integer = [&](const char* key, int lo, int hi) {
        auto it = op.find(key);
        if (it == op.end()) return;
        if (!it->is_number_integer() || it->get<long long>() < lo || it->get<long long>() > hi)
            bad(key, std::string("`") + key + "` of " + kind + " must be a whole number from " + std::to_string(lo) + " to " + std::to_string(hi) + ", got " + describe_json_value(*it) + ".");
    };
    auto choice = [&](const char* key, const std::vector<std::string>& values) {
        auto it = op.find(key);
        if (it == op.end()) return;
        if (!it->is_string() || std::find(values.begin(), values.end(), it->get<std::string>()) == values.end()) {
            std::string hint = it->is_string() ? did_you_mean(it->get<std::string>(), values) + " " : std::string();
            issues.push_back({pointer + "/" + key, std::string("`") + key + "` of " + kind + " must be one of " + join(values, ", ") + ", got " + describe_json_value(*it) + ".", hint + def->description});
        }
    };
    auto boolean = [&](const char* key) {
        auto it = op.find(key);
        if (it != op.end() && !it->is_boolean()) bad(key, std::string("`") + key + "` of " + kind + " must be true or false, got " + describe_json_value(*it) + ".");
    };
    auto colour = [&](const char* key, bool required) {
        auto it = op.find(key);
        Color c;
        std::string err;
        if (it == op.end()) {
            if (required) issues.push_back({pointer, kind + " needs a `" + key + "`.", def->description});
        } else if (!json_to(*it, c, &err)) {
            bad(key, kind + " `" + key + "`: " + err + " Colours are \"#rrggbb\", \"#rrggbbaa\", a name like \"white\" or [r, g, b] in 0..1.");
        }
    };
    auto palette = [&]() {
        auto it = op.find("palette");
        if (it == op.end()) return;
        if (it->is_string()) {
            if (it->get<std::string>() != "style") bad("palette", "`palette` of " + kind + " must be \"style\" or a list of colours, got " + describe_json_value(*it) + ".");
            return;
        }
        if (!it->is_array() || it->empty() || it->size() > 256) {
            bad("palette", "`palette` of " + kind + " must be \"style\" or a list of 1 to 256 colours, got " + describe_json_value(*it) + ".");
            return;
        }
        for (std::size_t i = 0; i < it->size(); ++i) {
            Color c;
            std::string err;
            if (!json_to((*it)[i], c, &err)) issues.push_back({pointer + "/palette/" + std::to_string(i), kind + " palette colour: " + err, "Colours are \"#rrggbb\", a name like \"white\" or [r, g, b] in 0..1."});
        }
    };
    auto triple = [&](const char* key) {
        auto it = op.find(key);
        if (it == op.end()) return;
        bool ok = is_array_of_numbers(*it, 3);
        if (ok)
            for (const Json& v : *it) ok = ok && v.get<float>() >= -1 && v.get<float>() <= 1;
        if (!ok) bad(key, std::string("`") + key + "` of " + kind + " must be [red, green, blue], three numbers from -1 to 1, got " + describe_json_value(*it) + ".");
    };

    if (kind == "brightness") range("amount", -1, 1);
    if (kind == "colorOverlay") {
        range("amount", 0, 1);
        colour("color", true);
    }
    if (kind == "levels") {
        range("inBlack", 0, 1);
        range("inWhite", 0, 1);
        range("outBlack", 0, 1);
        range("outWhite", 0, 1);
        range("gamma", 0.1f, 10);
        choice("channel", channels());
        const auto ib = op.find("inBlack"), iw = op.find("inWhite");
        const float lo = number_or(op, "inBlack", 0), hi = number_or(op, "inWhite", 1);
        if ((ib != op.end() || iw != op.end()) && lo >= hi)
            bad(iw != op.end() ? "inWhite" : "inBlack", "levels needs `inBlack` below `inWhite`, got " + num(lo) + " and " + num(hi) + ".");
    }
    if (kind == "curves") {
        choice("channel", channels());
        auto it = op.find("points");
        if (it == op.end()) {
            issues.push_back({pointer, "curves needs `points`.", def->description});
        } else if (!it->is_array() || it->size() < 2 || it->size() > 32) {
            bad("points", "`points` of curves must be a list of 2 to 32 [x, y] pairs, got " + describe_json_value(*it) + ".");
        } else {
            float last = -1;
            for (std::size_t i = 0; i < it->size(); ++i) {
                const Json& p = (*it)[i];
                const std::string at = "points/" + std::to_string(i);
                if (!is_array_of_numbers(p, 2) || p[0].get<float>() < 0 || p[0].get<float>() > 1 || p[1].get<float>() < 0 || p[1].get<float>() > 1) {
                    bad(at, "A point of curves must be [x, y] with both in 0..1, got " + describe_json_value(p) + ".");
                    break;
                }
                if (p[0].get<float>() <= last) {
                    bad(at, "The x of the points of curves must increase; " + describe_json_value(p[0]) + " is not above " + num(last) + ".");
                    break;
                }
                last = p[0].get<float>();
            }
        }
    }
    if (kind == "hsv") {
        boolean("colorize");
        const bool colorize = bool_or(op, "colorize", false);
        range("hue", colorize ? 0.0f : -180.0f, colorize ? 360.0f : 180.0f);
        range("saturation", colorize ? 0.0f : -1.0f, 1);
        range("value", -1, 1);
    }
    if (kind == "posterize") integer("levels", 2, 256);
    if (kind == "quantize" || kind == "dither") {
        palette();
        choice("space", {"oklab", "rgb"});
        range("strength", 0, 1);
    }
    if (kind == "quantize") choice("dither", dither_methods());
    if (kind == "dither") {
        choice("method", dither_methods());
        integer("levels", 2, 256);
    }
    if (kind == "gradientMap") {
        auto it = op.find("stops");
        if (it == op.end()) {
            issues.push_back({pointer, "gradientMap needs `stops`.", def->description});
        } else if (!it->is_array() || it->size() < 2 || it->size() > 64) {
            bad("stops", "`stops` of gradientMap must be a list of 2 to 64 {\"at\", \"color\"} objects, got " + describe_json_value(*it) + ".");
        } else {
            float last = -1;
            for (std::size_t i = 0; i < it->size(); ++i) {
                const Json& st = (*it)[i];
                const std::string at = "stops/" + std::to_string(i);
                Color c;
                std::string err;
                if (!st.is_object() || !st.contains("at") || !st["at"].is_number() || st["at"].get<float>() < 0 || st["at"].get<float>() > 1) {
                    bad(at, "A stop of gradientMap must be {\"at\": 0..1, \"color\": ...}, got " + describe_json_value(st) + ".");
                    break;
                }
                if (!st.contains("color") || !json_to(st["color"], c, &err)) {
                    bad(at + "/color", "A stop of gradientMap needs a valid `color`" + (err.empty() ? std::string(".") : ": " + err));
                    break;
                }
                if (st["at"].get<float>() < last) {
                    bad(at + "/at", "The `at` of the stops of gradientMap must not decrease; " + num(st["at"].get<float>()) + " follows " + num(last) + ".");
                    break;
                }
                last = st["at"].get<float>();
            }
        }
    }
    if (kind == "colorBalance") {
        triple("shadows");
        triple("midtones");
        triple("highlights");
    }
    if (kind == "threshold") {
        range("level", 0, 1);
        colour("above", false);
        colour("below", false);
    }
    if (kind == "outline" || kind == "stroke") {
        colour("color", false);
        range("width", 0.5f, 64);
        choice("position", {"outside", "inside", "center"});
        boolean("smooth");
    }
    if (kind == "dropShadow") {
        range("offsetX", -512, 512);
        range("offsetY", -512, 512);
        range("blur", 0, 64);
        colour("color", false);
        range("opacity", 0, 1);
    }
    if (kind == "outerGlow" || kind == "innerGlow") {
        colour("color", false);
        range("size", 0, 64);
        range("strength", 0, 8);
        range("opacity", 0, 1);
    }
    if (kind == "blur") {
        choice("mode", {"gaussian", "box"});
        range("radius", 0, 64);
    }
    if (kind == "sharpen") {
        range("radius", 0.1f, 32);
        range("amount", 0, 10);
        range("threshold", 0, 1);
    }
    if (kind == "noise") {
        range("amount", 0, 1);
        integer("seed", 0, 2147483647);
        choice("mode", {"mono", "color"});
    }
    if (kind == "shade") {
        boolean("flipGreen");
        range("smooth", 0, 16);
        range("strength", 0, 32);
        range("lightDirection", -360, 360);
        range("elevation", 1, 90);
        range("intensity", 0, 4);
        range("amount", 0, 1);
        auto it = op.find("normalMap");
        if (it != op.end()) {
            const std::string file = it->is_string() ? it->get<std::string>() : std::string();
            if (!it->is_string() || to_lower(file).size() < 5 || to_lower(file).substr(file.size() - 4) != ".png") {
                bad("normalMap", "`normalMap` of shade must be the project path of a PNG, got " + describe_json_value(*it) + ".");
            } else if (!projectDir.empty()) {
                std::error_code ec;
                auto path = resolve_project_path(projectDir, file);
                if (!path.ok() || !stdfs::is_regular_file(*path, ec)) bad("normalMap", "The normal map '" + file + "' does not exist in the project.");
            }
        }
    }
}

namespace {

// ---- colour helpers --------------------------------------------------------------------------------------------------

float luma(const float* p) { return 0.2126f * p[0] + 0.7152f * p[1] + 0.0722f * p[2]; }
float clamp01(float v) { return std::clamp(v, 0.0f, 1.0f); }

void rgb_to_hsv(float r, float g, float b, float& h, float& s, float& v) {
    const float mx = std::max({r, g, b}), mn = std::min({r, g, b}), d = mx - mn;
    v = mx;
    s = mx <= 0 ? 0 : d / mx;
    if (d <= 0) {
        h = 0;
    } else if (mx == r) {
        h = 60.0f * std::fmod((g - b) / d, 6.0f);
    } else if (mx == g) {
        h = 60.0f * ((b - r) / d + 2.0f);
    } else {
        h = 60.0f * ((r - g) / d + 4.0f);
    }
    if (h < 0) h += 360.0f;
}
void hsv_to_rgb(float h, float s, float v, float& r, float& g, float& b) {
    h = std::fmod(h, 360.0f);
    if (h < 0) h += 360.0f;
    const float c = v * s, x = c * (1.0f - std::fabs(std::fmod(h / 60.0f, 2.0f) - 1.0f)), m = v - c;
    float rr = 0, gg = 0, bb = 0;
    switch (int(h / 60.0f)) {
        case 0: rr = c; gg = x; break;
        case 1: rr = x; gg = c; break;
        case 2: gg = c; bb = x; break;
        case 3: gg = x; bb = c; break;
        case 4: rr = x; bb = c; break;
        default: rr = c; bb = x; break;
    }
    r = rr + m; g = gg + m; b = bb + m;
}

float srgb_to_linear(float c) { return c <= 0.04045f ? c / 12.92f : std::pow((c + 0.055f) / 1.055f, 2.4f); }

std::array<float, 3> to_oklab(const float* rgb) {
    const float r = srgb_to_linear(clamp01(rgb[0])), g = srgb_to_linear(clamp01(rgb[1])), b = srgb_to_linear(clamp01(rgb[2]));
    const float l = std::cbrt(0.4122214708f * r + 0.5363325363f * g + 0.0514459929f * b);
    const float m = std::cbrt(0.2119034982f * r + 0.6806995451f * g + 0.1073969566f * b);
    const float s = std::cbrt(0.0883024619f * r + 0.2817188376f * g + 0.6299787005f * b);
    return {0.2104542553f * l + 0.7936177850f * m - 0.0040720468f * s, 1.9779984951f * l - 2.4285922050f * m + 0.4505937099f * s,
            0.0259040371f * l + 0.7827717662f * m - 0.8086757660f * s};
}

// ---- rasters ---------------------------------------------------------------------------------------------------------

// The raster with `pad` transparent pixels added on every side; the pixels keep their place (the origin moves).
Raster grown(const Raster& r, int pad) {
    if (pad <= 0) return r;
    Raster out(r.w + 2 * pad, r.h + 2 * pad, r.ox - pad, r.oy - pad);
    for (int y = 0; y < r.h; ++y) std::copy_n(r.at(0, y), std::size_t(r.w) * 4, out.at(pad, y + pad));
    return out;
}

Plane alpha_plane(const Raster& r) {
    Plane p(r.w, r.h, r.ox, r.oy);
    for (std::size_t i = 0; i < p.v.size(); ++i) p.v[i] = r.px[i * 4 + 3];
    return p;
}

// `front` over `back` (straight alpha), into `out` (may alias either).
void over(const float* back, const float* front, float* out) {
    const float b[4] = {back[0], back[1], back[2], back[3]}, f[4] = {front[0], front[1], front[2], front[3]};
    composite_pixel(ImageBlend::Normal, b, f, out);
}

// A box blur of a plane, window 2 * radius + 1, zero outside.
void box_plane(Plane& p, int radius) {
    if (radius <= 0 || p.w <= 0 || p.h <= 0) return;
    const float inv = 1.0f / float(2 * radius + 1);
    std::vector<float> tmp(p.v.size(), 0.0f);
    for (int y = 0; y < p.h; ++y) {
        double acc = 0;
        for (int x = 0; x <= std::min(radius, p.w - 1); ++x) acc += p.at(x, y);
        for (int x = 0; x < p.w; ++x) {
            tmp[std::size_t(y) * p.w + x] = float(acc) * inv;
            const int add = x + radius + 1, sub = x - radius;
            if (add < p.w) acc += p.at(add, y);
            if (sub >= 0) acc -= p.at(sub, y);
        }
    }
    for (int x = 0; x < p.w; ++x) {
        double acc = 0;
        for (int y = 0; y <= std::min(radius, p.h - 1); ++y) acc += tmp[std::size_t(y) * p.w + x];
        for (int y = 0; y < p.h; ++y) {
            p.at(x, y) = float(acc) * inv;
            const int add = y + radius + 1, sub = y - radius;
            if (add < p.h) acc += tmp[std::size_t(add) * p.w + x];
            if (sub >= 0) acc -= tmp[std::size_t(sub) * p.w + x];
        }
    }
}

// Blurs premultiplied colour and alpha, back to straight alpha.
void blur_raster(Raster& r, float sigma, bool box) {
    Plane planes[4];
    for (int c = 0; c < 4; ++c) planes[c] = Plane(r.w, r.h, r.ox, r.oy);
    for (std::size_t i = 0; i < planes[0].v.size(); ++i) {
        const float a = r.px[i * 4 + 3];
        for (int c = 0; c < 3; ++c) planes[c].v[i] = r.px[i * 4 + std::size_t(c)] * a;
        planes[3].v[i] = a;
    }
    for (Plane& p : planes) {
        if (box) box_plane(p, int(std::lround(sigma)));
        else blur_plane(p, sigma);
    }
    for (std::size_t i = 0; i < planes[0].v.size(); ++i) {
        const float a = planes[3].v[i];
        if (a > 1e-6f) {
            for (int c = 0; c < 3; ++c) r.px[i * 4 + std::size_t(c)] = clamp01(planes[c].v[i] / a);
            r.px[i * 4 + 3] = clamp01(a);
        } else {
            r.px[i * 4] = r.px[i * 4 + 1] = r.px[i * 4 + 2] = r.px[i * 4 + 3] = 0;
        }
    }
}

// Squared Euclidean distance from every pixel to the nearest pixel with feature[i] set (Felzenszwalb-Huttenlocher).
std::vector<float> distance_squared(const std::vector<char>& feature, int w, int h) {
    constexpr float kInf = 1e20f;
    std::vector<float> d(feature.size());
    for (std::size_t i = 0; i < d.size(); ++i) d[i] = feature[i] ? 0.0f : kInf;
    const int n = std::max(w, h);
    const std::size_t len0 = std::size_t(n);
    std::vector<float> f(len0, 0.0f), out(len0, 0.0f), z(len0 + 1, 0.0f);
    std::vector<int> v(len0, 0);
    auto pass = [&](int len, auto get, auto put) {
        for (int i = 0; i < len; ++i) f[std::size_t(i)] = get(i);
        int k = 0;
        v[0] = 0;
        z[0] = -kInf;
        z[1] = kInf;
        for (int q = 1; q < len; ++q) {
            float s;
            while (true) {
                const int p = v[std::size_t(k)];
                s = ((f[std::size_t(q)] + float(q) * float(q)) - (f[std::size_t(p)] + float(p) * float(p))) / float(2 * q - 2 * p);
                if (s <= z[std::size_t(k)] && k > 0) --k;
                else break;
            }
            ++k;
            v[std::size_t(k)] = q;
            z[std::size_t(k)] = s;
            z[std::size_t(k) + 1] = kInf;
        }
        k = 0;
        for (int q = 0; q < len; ++q) {
            while (z[std::size_t(k) + 1] < float(q)) ++k;
            const int p = v[std::size_t(k)];
            out[std::size_t(q)] = float(q - p) * float(q - p) + f[std::size_t(p)];
        }
        for (int i = 0; i < len; ++i) put(i, out[std::size_t(i)]);
    };
    for (int x = 0; x < w; ++x)
        pass(h, [&](int y) { return d[std::size_t(y) * w + x]; }, [&](int y, float val) { d[std::size_t(y) * w + x] = val; });
    for (int y = 0; y < h; ++y)
        pass(w, [&](int x) { return d[std::size_t(y) * w + x]; }, [&](int x, float val) { d[std::size_t(y) * w + x] = val; });
    return d;
}

// ---- adjustments -----------------------------------------------------------------------------------------------------

struct ChannelMask {
    bool on[3] = {true, true, true};
};
ChannelMask channel_mask(const Json& op) {
    const std::string c = string_or(op, "channel", "rgb");
    ChannelMask m;
    if (c != "rgb") m.on[0] = c == "red", m.on[1] = c == "green", m.on[2] = c == "blue";
    return m;
}

// A monotone cubic Hermite curve through points (Fritsch-Carlson), as a lookup table of 4097 entries.
std::vector<float> curve_lut(const Json& points) {
    std::vector<float> xs, ys;
    for (const Json& p : points) xs.push_back(p[0].get<float>()), ys.push_back(p[1].get<float>());
    const std::size_t n = xs.size();
    std::vector<float> d(n - 1), m(n);
    for (std::size_t k = 0; k + 1 < n; ++k) d[k] = (ys[k + 1] - ys[k]) / (xs[k + 1] - xs[k]);
    m[0] = d[0];
    m[n - 1] = d[n - 2];
    for (std::size_t k = 1; k + 1 < n; ++k) m[k] = d[k - 1] * d[k] <= 0 ? 0.0f : (d[k - 1] + d[k]) * 0.5f;
    for (std::size_t k = 0; k + 1 < n; ++k) {
        if (d[k] == 0) {
            m[k] = m[k + 1] = 0;
            continue;
        }
        const float a = m[k] / d[k], b = m[k + 1] / d[k], s = a * a + b * b;
        if (s > 9.0f) {
            const float t = 3.0f / std::sqrt(s);
            m[k] = t * a * d[k];
            m[k + 1] = t * b * d[k];
        }
    }
    constexpr int kLut = 4096;
    std::vector<float> lut(kLut + 1);
    std::size_t seg = 0;
    for (int i = 0; i <= kLut; ++i) {
        const float x = float(i) / kLut;
        if (x <= xs.front()) {
            lut[std::size_t(i)] = ys.front();
            continue;
        }
        if (x >= xs.back()) {
            lut[std::size_t(i)] = ys.back();
            continue;
        }
        while (seg + 2 < n && x > xs[seg + 1]) ++seg;
        const float h = xs[seg + 1] - xs[seg], t = (x - xs[seg]) / h, t2 = t * t, t3 = t2 * t;
        lut[std::size_t(i)] = clamp01((2 * t3 - 3 * t2 + 1) * ys[seg] + (t3 - 2 * t2 + t) * h * m[seg] + (-2 * t3 + 3 * t2) * ys[seg + 1] + (t3 - t2) * h * m[seg + 1]);
    }
    return lut;
}

// Maps a colour to a palette entry (or to the nearest of `levels` values per channel).
struct Quantizer {
    std::vector<std::array<float, 3>> rgb, lab;
    bool useLab = true;
    int levels = 0;  // > 0: evenly spaced values per channel, no palette
    float spread = 1.0f;

    void nearest(const float* in, float* out) const {
        if (levels > 0) {
            for (int c = 0; c < 3; ++c) out[c] = std::round(clamp01(in[c]) * float(levels - 1)) / float(levels - 1);
            return;
        }
        std::size_t best = 0;
        float bestD = 1e30f;
        if (useLab) {
            const auto p = to_oklab(in);
            for (std::size_t i = 0; i < lab.size(); ++i) {
                const float dl = p[0] - lab[i][0], da = p[1] - lab[i][1], db = p[2] - lab[i][2], dd = dl * dl + da * da + db * db;
                if (dd < bestD) bestD = dd, best = i;
            }
        } else {
            for (std::size_t i = 0; i < rgb.size(); ++i) {
                const float dr = clamp01(in[0]) - rgb[i][0], dg = clamp01(in[1]) - rgb[i][1], db = clamp01(in[2]) - rgb[i][2], dd = dr * dr + dg * dg + db * db;
                if (dd < bestD) bestD = dd, best = i;
            }
        }
        for (int c = 0; c < 3; ++c) out[c] = rgb[best][std::size_t(c)];
    }
};

void bayer_matrix(int n, std::vector<int>& m) {
    m = {0, 2, 3, 1};
    for (int size = 2; size < n; size *= 2) {
        std::vector<int> next(std::size_t(size) * size * 4);
        const int s2 = size * 2;
        for (int y = 0; y < size; ++y)
            for (int x = 0; x < size; ++x) {
                const int v = m[std::size_t(y) * size + x] * 4;
                next[std::size_t(y) * s2 + x] = v;
                next[std::size_t(y) * s2 + x + size] = v + 2;
                next[std::size_t(y + size) * s2 + x] = v + 3;
                next[std::size_t(y + size) * s2 + x + size] = v + 1;
            }
        m = std::move(next);
    }
}

bool make_quantizer(const Json& op, bool allowLevels, const OpEnv& env, Quantizer& q) {
    q.useLab = string_or(op, "space", "oklab") == "oklab";
    auto it = op.find("palette");
    if (it == op.end() && allowLevels) {
        q.levels = op.value("levels", 2);
        q.spread = 1.0f / float(q.levels - 1);
        return true;
    }
    if (it != op.end() && it->is_array()) {
        for (const Json& c : *it) {
            Color col;
            std::string err;
            if (!json_to(c, col, &err)) return false;
            q.rgb.push_back({col.r, col.g, col.b});
        }
    } else {
        const StyleGuide& style = env.style();
        if (!style.palette || style.palette->empty()) {
            env.fail("This operation maps to the style palette, but assets.json has no `style.palette`.",
                     "Set a palette in the style (\"style\": {\"palette\": [\"#1a1c2c\", \"#5d275d\", ...]}), or give the colours here: \"palette\": [\"#000000\", \"#ffffff\"].");
            return false;
        }
        for (const auto& c : *style.palette) q.rgb.push_back({c[0] / 255.0f, c[1] / 255.0f, c[2] / 255.0f});
    }
    for (const auto& c : q.rgb) q.lab.push_back(to_oklab(c.data()));
    q.spread = std::min(1.0f, 1.26f / std::cbrt(float(q.rgb.size())));
    return true;
}

void apply_quantize(const Json& op, const std::string& method, bool allowLevels, Raster& r, const OpEnv& env) {
    Quantizer q;
    if (!make_quantizer(op, allowLevels, env, q)) return;
    const float strength = number_or(op, "strength", 1.0f);
    const std::size_t count = std::size_t(r.w) * r.h;
    if (method == "none") {
        for (std::size_t i = 0; i < count; ++i) {
            float* p = &r.px[i * 4];
            if (p[3] > 0) q.nearest(p, p);
        }
    } else if (method.rfind("bayer", 0) == 0) {
        const int n = method == "bayer2" ? 2 : method == "bayer4" ? 4 : 8;
        std::vector<int> m;
        bayer_matrix(n, m);
        for (int y = 0; y < r.h; ++y)
            for (int x = 0; x < r.w; ++x) {
                float* p = r.at(x, y);
                if (p[3] <= 0) continue;
                const int mx = ((x + r.ox) % n + n) % n, my = ((y + r.oy) % n + n) % n;
                const float t = (float(m[std::size_t(my) * n + mx]) + 0.5f) / float(n * n) - 0.5f;
                float in[3];
                for (int c = 0; c < 3; ++c) in[c] = p[c] + t * q.spread * strength;
                q.nearest(in, p);
            }
    } else {
        struct Tap {
            int dx, dy;
            float w;
        };
        static const std::vector<Tap> fs = {{1, 0, 7 / 16.0f}, {-1, 1, 3 / 16.0f}, {0, 1, 5 / 16.0f}, {1, 1, 1 / 16.0f}};
        static const std::vector<Tap> atkinson = {{1, 0, 1 / 8.0f}, {2, 0, 1 / 8.0f}, {-1, 1, 1 / 8.0f}, {0, 1, 1 / 8.0f}, {1, 1, 1 / 8.0f}, {0, 2, 1 / 8.0f}};
        const auto& taps = method == "atkinson" ? atkinson : fs;
        std::vector<float> buf = r.px;
        for (int y = 0; y < r.h; ++y)
            for (int x = 0; x < r.w; ++x) {
                float* p = &buf[(std::size_t(y) * r.w + x) * 4];
                if (r.at(x, y)[3] <= 0) continue;
                float out[3];
                q.nearest(p, out);
                for (int c = 0; c < 3; ++c) {
                    const float err = (p[c] - out[c]) * strength;
                    for (const Tap& t : taps) {
                        const int nx = x + t.dx, ny = y + t.dy;
                        if (nx < 0 || ny < 0 || nx >= r.w || ny >= r.h || r.at(nx, ny)[3] <= 0) continue;
                        buf[(std::size_t(ny) * r.w + nx) * 4 + std::size_t(c)] += err * t.w;
                    }
                    p[c] = out[c];
                }
            }
        for (std::size_t i = 0; i < count; ++i)
            if (r.px[i * 4 + 3] > 0)
                for (int c = 0; c < 3; ++c) r.px[i * 4 + std::size_t(c)] = buf[i * 4 + std::size_t(c)];
    }
}

}  // namespace

void apply_adjustments(const std::vector<Json>& list, Raster& r, const OpEnv& env) {
    for (const Json& op : list) {
        const std::string type = op.value("type", std::string());
        const std::size_t count = std::size_t(r.w) * r.h;
        if (type == "invert") {
            for (std::size_t i = 0; i < r.px.size(); i += 4)
                for (int c = 0; c < 3; ++c) r.px[i + c] = 1.0f - r.px[i + c];
        } else if (type == "brightness") {
            const float amount = number_or(op, "amount", 0.2f);
            for (std::size_t i = 0; i < r.px.size(); i += 4)
                for (int c = 0; c < 3; ++c) r.px[i + c] = std::clamp(r.px[i + c] + amount, 0.0f, 1.0f);
        } else if (type == "levels") {
            const float inB = number_or(op, "inBlack", 0), inW = number_or(op, "inWhite", 1), gamma = number_or(op, "gamma", 1);
            const float outB = number_or(op, "outBlack", 0), outW = number_or(op, "outWhite", 1);
            const ChannelMask mask = channel_mask(op);
            for (std::size_t i = 0; i < count; ++i)
                for (int c = 0; c < 3; ++c) {
                    if (!mask.on[c]) continue;
                    float& v = r.px[i * 4 + std::size_t(c)];
                    v = outB + std::pow(clamp01((v - inB) / (inW - inB)), 1.0f / gamma) * (outW - outB);
                }
        } else if (type == "curves") {
            const std::vector<float> lut = curve_lut(op["points"]);
            const ChannelMask mask = channel_mask(op);
            const float scale = float(lut.size() - 1);
            for (std::size_t i = 0; i < count; ++i)
                for (int c = 0; c < 3; ++c) {
                    if (!mask.on[c]) continue;
                    float& v = r.px[i * 4 + std::size_t(c)];
                    const float f = clamp01(v) * scale;
                    const std::size_t k = std::min<std::size_t>(std::size_t(f), lut.size() - 2);
                    v = lut[k] + (lut[k + 1] - lut[k]) * (f - float(k));
                }
        } else if (type == "hsv") {
            const bool colorize = bool_or(op, "colorize", false);
            const float hue = number_or(op, "hue", 0), value = number_or(op, "value", 0);
            const float sat = number_or(op, "saturation", colorize ? 0.5f : 0.0f);
            for (std::size_t i = 0; i < count; ++i) {
                float* p = &r.px[i * 4];
                float h, s, v;
                if (colorize) {
                    h = hue;
                    s = sat;
                    v = clamp01(luma(p) + value);
                } else {
                    rgb_to_hsv(p[0], p[1], p[2], h, s, v);
                    h += hue;
                    s = clamp01(s * (1.0f + sat));
                    v = clamp01(v + value);
                }
                hsv_to_rgb(h, s, v, p[0], p[1], p[2]);
                for (int c = 0; c < 3; ++c) p[c] = clamp01(p[c]);
            }
        } else if (type == "posterize") {
            const float n = float(op.value("levels", 4) - 1);
            for (std::size_t i = 0; i < count; ++i)
                for (int c = 0; c < 3; ++c) {
                    float& v = r.px[i * 4 + std::size_t(c)];
                    v = std::round(clamp01(v) * n) / n;
                }
        } else if (type == "quantize") {
            apply_quantize(op, string_or(op, "dither", "none"), false, r, env);
        } else if (type == "dither") {
            apply_quantize(op, string_or(op, "method", "bayer4"), true, r, env);
        } else if (type == "gradientMap") {
            struct Stop {
                float at;
                float c[3];
            };
            std::vector<Stop> stops;
            for (const Json& st : op["stops"]) {
                Color c;
                std::string err;
                json_to(st["color"], c, &err);
                stops.push_back({st["at"].get<float>(), {c.r, c.g, c.b}});
            }
            for (std::size_t i = 0; i < count; ++i) {
                float* p = &r.px[i * 4];
                const float l = clamp01(luma(p));
                std::size_t k = 0;
                while (k + 1 < stops.size() && l > stops[k + 1].at) ++k;
                if (l <= stops.front().at || k + 1 >= stops.size()) {
                    const Stop& s = l <= stops.front().at ? stops.front() : stops.back();
                    for (int c = 0; c < 3; ++c) p[c] = s.c[c];
                    continue;
                }
                const float span = stops[k + 1].at - stops[k].at, t = span > 0 ? (l - stops[k].at) / span : 1.0f;
                for (int c = 0; c < 3; ++c) p[c] = stops[k].c[c] + (stops[k + 1].c[c] - stops[k].c[c]) * t;
            }
        } else if (type == "colorBalance") {
            float s[3] = {0, 0, 0}, m[3] = {0, 0, 0}, h[3] = {0, 0, 0};
            auto read = [&](const char* key, float* out) {
                auto it = op.find(key);
                if (it != op.end() && it->is_array())
                    for (int c = 0; c < 3; ++c) out[c] = (*it)[std::size_t(c)].get<float>();
            };
            read("shadows", s);
            read("midtones", m);
            read("highlights", h);
            for (std::size_t i = 0; i < count; ++i) {
                float* p = &r.px[i * 4];
                const float l = clamp01(luma(p)), ws = (1 - l) * (1 - l), wh = l * l, wm = 4 * l * (1 - l);
                for (int c = 0; c < 3; ++c) p[c] = clamp01(p[c] + 0.5f * (ws * s[c] + wm * m[c] + wh * h[c]));
            }
        } else if (type == "threshold") {
            const float level = number_or(op, "level", 0.5f);
            const Color above = color_or(op, "above", Color(1, 1, 1)), below = color_or(op, "below", Color(0, 0, 0));
            for (std::size_t i = 0; i < count; ++i) {
                float* p = &r.px[i * 4];
                const Color& c = luma(p) >= level ? above : below;
                p[0] = c.r;
                p[1] = c.g;
                p[2] = c.b;
            }
        }
    }
}

// ---- effects ---------------------------------------------------------------------------------------------------------

namespace {

std::uint32_t hash_u32(std::uint32_t seed, std::int32_t x, std::int32_t y, std::uint32_t channel) {
    std::uint32_t h = seed * 0x9E3779B1u ^ std::uint32_t(x) * 0x85EBCA6Bu ^ std::uint32_t(y) * 0xC2B2AE35u ^ channel * 0x27D4EB2Fu;
    h ^= h >> 16;
    h *= 0x85EBCA6Bu;
    h ^= h >> 13;
    h *= 0xC2B2AE35u;
    h ^= h >> 16;
    return h;
}

void apply_outline(const Json& op, bool isStroke, Raster& r) {
    const Color c = color_or(op, "color", Color(0, 0, 0, 1));
    const float w = number_or(op, "width", 1.0f);
    const std::string pos = string_or(op, "position", isStroke ? "center" : "outside");
    const bool smooth = bool_or(op, "smooth", false);
    float wo = 0, wi = 0;
    if (pos == "outside") wo = w;
    else if (pos == "inside") wi = w;
    else wo = std::ceil(w / 2.0f), wi = w - wo;
    // room for the stroke; an inside stroke gets one transparent row so the edge of the raster counts as the edge of the shape
    r = grown(r, wo > 0 ? int(std::ceil(wo)) + 1 : 1);
    const std::size_t count = std::size_t(r.w) * r.h;
    std::vector<char> inside(count), outside(count);
    for (std::size_t i = 0; i < count; ++i) inside[i] = r.px[i * 4 + 3] > 0.5f, outside[i] = !inside[i];
    auto coverage = [&](float d2, float width) {
        const float d = std::sqrt(d2);
        return smooth ? clamp01(width + 1.0f - d) : (d <= width + 1e-4f ? 1.0f : 0.0f);
    };
    const std::vector<float> dOut = wo > 0 ? distance_squared(inside, r.w, r.h) : std::vector<float>();
    const std::vector<float> dIn = wi > 0 ? distance_squared(outside, r.w, r.h) : std::vector<float>();
    for (std::size_t i = 0; i < count; ++i) {
        float* p = &r.px[i * 4];
        if (!inside[i]) {
            if (wo <= 0) continue;
            const float cov = coverage(dOut[i], wo) * c.a;
            if (cov <= 0) continue;
            const float stroke[4] = {c.r, c.g, c.b, cov};
            over(stroke, p, p);
        } else if (wi > 0) {
            const float cov = coverage(dIn[i], wi) * c.a;
            p[0] += (c.r - p[0]) * cov;
            p[1] += (c.g - p[1]) * cov;
            p[2] += (c.b - p[2]) * cov;
        }
    }
}

void apply_drop_shadow(const Json& op, Raster& r) {
    const int dx = int(std::lround(number_or(op, "offsetX", 2))), dy = int(std::lround(number_or(op, "offsetY", 2)));
    const float sigma = number_or(op, "blur", 2) / 2.0f;
    const Color c = color_or(op, "color", Color(0, 0, 0, 1));
    const float opacity = number_or(op, "opacity", 0.5f) * c.a;
    r = grown(r, int(std::ceil(sigma * 3.0f)) + std::max(std::abs(dx), std::abs(dy)) + 1);
    Plane shadow(r.w, r.h, r.ox, r.oy);
    for (int y = 0; y < r.h; ++y)
        for (int x = 0; x < r.w; ++x) {
            const int sx = x - dx, sy = y - dy;
            if (sx >= 0 && sy >= 0 && sx < r.w && sy < r.h) shadow.at(x, y) = r.at(sx, sy)[3];
        }
    blur_plane(shadow, sigma);
    for (int y = 0; y < r.h; ++y)
        for (int x = 0; x < r.w; ++x) {
            float* p = r.at(x, y);
            const float back[4] = {c.r, c.g, c.b, clamp01(shadow.at(x, y) * opacity)};
            over(back, p, p);
        }
}

void apply_outer_glow(const Json& op, Raster& r) {
    const float sigma = number_or(op, "size", 4) / 2.0f, strength = number_or(op, "strength", 1), opacity = number_or(op, "opacity", 1);
    const Color c = color_or(op, "color", Color(1, 1, 1, 1));
    r = grown(r, int(std::ceil(sigma * 3.0f)) + 1);
    Plane glow = alpha_plane(r);
    blur_plane(glow, sigma);
    for (int y = 0; y < r.h; ++y)
        for (int x = 0; x < r.w; ++x) {
            float* p = r.at(x, y);
            const float back[4] = {c.r, c.g, c.b, clamp01(glow.at(x, y) * strength) * opacity * c.a};
            over(back, p, p);
        }
}

void apply_inner_glow(const Json& op, Raster& r) {
    const float sigma = number_or(op, "size", 4) / 2.0f, strength = number_or(op, "strength", 1), opacity = number_or(op, "opacity", 1);
    const Color c = color_or(op, "color", Color(1, 1, 1, 1));
    const int pad = int(std::ceil(sigma * 3.0f)) + 1;
    // the transparency around the layer, on a bigger plane so that the edge of the raster does not glow
    Plane inv(r.w + 2 * pad, r.h + 2 * pad, r.ox - pad, r.oy - pad, 1.0f);
    for (int y = 0; y < r.h; ++y)
        for (int x = 0; x < r.w; ++x) inv.at(x + pad, y + pad) = 1.0f - r.at(x, y)[3];
    blur_plane(inv, sigma);
    for (int y = 0; y < r.h; ++y)
        for (int x = 0; x < r.w; ++x) {
            float* p = r.at(x, y);
            if (p[3] <= 0) continue;
            const float cov = clamp01(inv.at(x + pad, y + pad) * strength) * opacity * c.a;
            p[0] += (c.r - p[0]) * cov;
            p[1] += (c.g - p[1]) * cov;
            p[2] += (c.b - p[2]) * cov;
        }
}

void apply_sharpen(const Json& op, Raster& r) {
    const float sigma = number_or(op, "radius", 1), amount = number_or(op, "amount", 1), threshold = number_or(op, "threshold", 0);
    Raster blurred = r;
    blur_raster(blurred, sigma, false);
    for (std::size_t i = 0; i < std::size_t(r.w) * r.h; ++i) {
        float* p = &r.px[i * 4];
        const float* b = &blurred.px[i * 4];
        if (p[3] <= 0 || b[3] <= 0) continue;
        for (int c = 0; c < 3; ++c) {
            const float diff = p[c] - b[c];
            if (std::fabs(diff) >= threshold) p[c] = clamp01(p[c] + amount * diff);
        }
    }
}

void apply_noise(const Json& op, Raster& r) {
    const float amount = number_or(op, "amount", 0.1f);
    const std::uint32_t seed = std::uint32_t(op.value("seed", 0));
    const bool mono = string_or(op, "mode", "mono") == "mono";
    auto unit = [](std::uint32_t h) { return float(h >> 8) / 8388608.0f - 1.0f; };  // [-1, 1)
    for (int y = 0; y < r.h; ++y)
        for (int x = 0; x < r.w; ++x) {
            float* p = r.at(x, y);
            if (p[3] <= 0) continue;
            for (int c = 0; c < 3; ++c) p[c] = clamp01(p[c] + amount * unit(hash_u32(seed, x + r.ox, y + r.oy, mono ? 0u : std::uint32_t(c))));
        }
}

void apply_shade(const Json& op, Raster& r, const OpEnv& env) {
    const float strength = number_or(op, "strength", 3), intensity = number_or(op, "intensity", 1), amount = number_or(op, "amount", 1);
    const bool flipGreen = bool_or(op, "flipGreen", false);
    float degrees = 135.0f;
    if (op.contains("lightDirection")) degrees = op["lightDirection"].get<float>();
    else if (env.style().lightDirection) degrees = float(*env.style().lightDirection);
    const float theta = degrees * 3.14159265f / 180.0f, elev = number_or(op, "elevation", 45) * 3.14159265f / 180.0f;
    const float lx = std::cos(theta) * std::cos(elev), ly = std::sin(theta) * std::cos(elev), lz = std::sin(elev);
    const Image* map = op.contains("normalMap") ? &env.image(op["normalMap"].get<std::string>()) : nullptr;
    Plane height;
    if (!map) {
        height = alpha_plane(r);
        blur_plane(height, number_or(op, "smooth", 1));
    }
    for (int y = 0; y < r.h; ++y)
        for (int x = 0; x < r.w; ++x) {
            float* p = r.at(x, y);
            if (p[3] <= 0) continue;
            float nx = 0, ny = 0, nz = 1;
            if (map) {
                const int mx = x + r.ox, my = y + r.oy;
                if (mx >= 0 && my >= 0 && mx < map->width && my < map->height) {
                    const std::uint8_t* t = &map->rgba[(std::size_t(my) * map->width + mx) * 4];
                    if (t[3] > 0) {
                        nx = t[0] / 127.5f - 1.0f;
                        ny = (t[1] / 127.5f - 1.0f) * (flipGreen ? -1.0f : 1.0f);
                        nz = t[2] / 127.5f - 1.0f;
                    }
                }
            } else {
                auto h = [&](int hx, int hy) { return height.at(std::clamp(hx, 0, r.w - 1), std::clamp(hy, 0, r.h - 1)); };
                nx = -strength * (h(x + 1, y) - h(x - 1, y)) * 0.5f;
                ny = strength * (h(x, y + 1) - h(x, y - 1)) * 0.5f;  // image rows run down, the light's y runs up
            }
            const float len = std::sqrt(nx * nx + ny * ny + nz * nz);
            if (len <= 1e-6f) continue;
            const float lit = (nx * lx + ny * ly + nz * lz) / len;
            const float f = std::max(0.0f, 1.0f + 2.0f * intensity * (lit - lz));
            for (int c = 0; c < 3; ++c) p[c] += (clamp01(p[c] * f) - p[c]) * amount;
        }
}

}  // namespace

void apply_effects(const std::vector<Json>& list, Raster& r, const OpEnv& env) {
    for (const Json& op : list) {
        const std::string type = op.value("type", std::string());
        if (type == "colorOverlay") {
            Color c;
            std::string err;
            if (!json_to(op["color"], c, &err)) continue;
            const float amount = number_or(op, "amount", 1.0f) * c.a;
            for (std::size_t i = 0; i < r.px.size(); i += 4) {
                r.px[i] += (c.r - r.px[i]) * amount;
                r.px[i + 1] += (c.g - r.px[i + 1]) * amount;
                r.px[i + 2] += (c.b - r.px[i + 2]) * amount;
            }
        } else if (r.empty()) {
            continue;
        } else if (type == "outline" || type == "stroke") {
            apply_outline(op, type == "stroke", r);
        } else if (type == "dropShadow") {
            apply_drop_shadow(op, r);
        } else if (type == "outerGlow") {
            apply_outer_glow(op, r);
        } else if (type == "innerGlow") {
            apply_inner_glow(op, r);
        } else if (type == "blur") {
            const bool box = string_or(op, "mode", "gaussian") == "box";
            const float radius = number_or(op, "radius", 2);
            const int pad = box ? int(std::lround(radius)) : int(std::ceil(radius * 3.0f));
            if (pad <= 0) continue;
            r = grown(r, pad + 1);
            blur_raster(r, radius, box);
        } else if (type == "sharpen") {
            apply_sharpen(op, r);
        } else if (type == "noise") {
            apply_noise(op, r);
        } else if (type == "shade") {
            apply_shade(op, r, env);
        }
    }
}

}  // namespace fa::imgdoc
