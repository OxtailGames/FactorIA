// Adjustments and effects of an image document: the lists a layer carries (and an adjustment layer applies to what lies
// below it). This file is the hook M52.2 fills: a new operation is one entry in kAdjustments or kEffects (name, description for
// the docs and the errors, the keys it takes) plus one case in apply_adjustment / apply_effect.
//
// Where they run, for one layer (image_doc_render.cpp): content -> ADJUSTMENTS -> masks -> EFFECTS -> clipping -> opacity ->
// blend. Adjustments change colours only, so the layer's footprint is still its content's when the masks are applied. Effects
// come after the masks and may change the footprint (a shadow or an outline grows the raster; the raster keeps its origin, so
// nothing else needs to know).
//
// Implemented so far, as the proof that the lists are walked:
//   adjustments: invert, brightness     effects: colorOverlay
#include <algorithm>
#include <cmath>

#include "fa/core/strings.h"
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
    };
    return defs;
}

const std::vector<OpDef>& effect_defs() {
    static const std::vector<OpDef> defs = {
        {"colorOverlay", "Mixes the colour of the layer towards `color` by `amount` (0..1, default 1), keeping its alpha: {\"type\": \"colorOverlay\", \"color\": \"#ff0000\", \"amount\": 0.5}.",
         {"color", "amount"}},
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

const std::vector<OpDef>& defs_of(bool effect) { return effect ? effect_defs() : adjustment_defs(); }

float number_or(const Json& op, const char* key, float fallback) {
    auto it = op.find(key);
    return it != op.end() && it->is_number() ? it->get<float>() : fallback;
}

}  // namespace

void check_op(bool effect, const Json& op, const std::string& pointer, std::vector<ImageIssue>& issues) {
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
    auto range = [&](const char* key, float lo, float hi) {
        auto it = op.find(key);
        if (it == op.end()) return;
        if (!it->is_number() || it->get<float>() < lo || it->get<float>() > hi)
            issues.push_back({pointer + "/" + key, std::string("`") + key + "` of " + kind + " must be a number from " + std::to_string(int(lo)) + " to " + std::to_string(int(hi)) + ", got " + describe_json_value(*it) + ".", def->description});
    };
    if (kind == "brightness") range("amount", -1, 1);
    if (kind == "colorOverlay") {
        range("amount", 0, 1);
        auto it = op.find("color");
        Color c;
        std::string err;
        if (it == op.end()) issues.push_back({pointer, "colorOverlay needs a `color`.", def->description});
        else if (!json_to(*it, c, &err)) issues.push_back({pointer + "/color", "colorOverlay `color`: " + err, "Colours are \"#rrggbb\", \"#rrggbbaa\", a name like \"white\" or [r, g, b] in 0..1."});
    }
}

void apply_adjustments(const std::vector<Json>& list, Raster& r) {
    for (const Json& op : list) {
        const std::string type = op.value("type", std::string());
        if (type == "invert") {
            for (std::size_t i = 0; i < r.px.size(); i += 4)
                for (int c = 0; c < 3; ++c) r.px[i + c] = 1.0f - r.px[i + c];
        } else if (type == "brightness") {
            const float amount = number_or(op, "amount", 0.2f);
            for (std::size_t i = 0; i < r.px.size(); i += 4)
                for (int c = 0; c < 3; ++c) r.px[i + c] = std::clamp(r.px[i + c] + amount, 0.0f, 1.0f);
        }
    }
}

void apply_effects(const std::vector<Json>& list, Raster& r) {
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
        }
    }
}

}  // namespace fa::imgdoc
