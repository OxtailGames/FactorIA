#include "fa/tooling/style_guide.h"

#include <algorithm>
#include <cmath>
#include <format>

#include "fa/core/asset_manifest.h"
#include "fa/core/fs.h"
#include "fa/core/strings.h"
#include "util.h"

namespace fa {

namespace {

// Names a person (or an AI) writes for where the light comes from, with the angle TOWARDS the light: counter-clockwise
// from +x, so "right" is 0, "top" 90, "left" 180 and "bottom" 270 (the y axis of the picture points down, the angle does not).
const std::vector<std::pair<std::string, double>> kLightNames = {
    {"right", 0},       {"upper-right", 45},  {"top", 90},         {"upper-left", 135},
    {"left", 180},      {"lower-left", 225},  {"bottom", 270},     {"lower-right", 315},
};
const std::vector<std::pair<std::string, double>> kLightAliases = {
    {"top-right", 45}, {"top-left", 135}, {"bottom-left", 225}, {"bottom-right", 315}, {"up", 90}, {"down", 270},
};

std::string normalize_light_name(std::string s) {
    s = to_lower(std::string(trim(s)));
    for (char& c : s)
        if (c == ' ' || c == '_') c = '-';
    return s;
}

double wrap_degrees(double d) {
    d = std::fmod(d, 360.0);
    return d < 0 ? d + 360.0 : d;
}

std::string num(double v) {
    std::string s = std::format("{:.4g}", v);
    return s;
}

struct Parser {
    StyleParse out;

    void problem(const std::string& pointer, std::string message, std::string hint) {
        out.problems.push_back({pointer, std::move(message), std::move(hint)});
    }

    void unknown_keys(const Json& obj, const std::string& base, const std::vector<std::string>& known) {
        for (auto it = obj.begin(); it != obj.end(); ++it) {
            if (std::find(known.begin(), known.end(), it.key()) != known.end()) continue;
            std::string hint = did_you_mean(it.key(), known);
            if (hint.empty()) hint = "Remove it.";
            problem(base + "/" + escape_json_token(it.key()), "Unknown key '" + it.key() + "'.", std::move(hint));
        }
    }

    static std::string escape_json_token(const std::string& key) { return tooling_detail::escape_token(key); }

    // `v` as a number in [lo, hi], or a problem and false.
    bool number(const Json& v, const std::string& pointer, double lo, double hi, const char* what, const std::string& example,
                double& out_) {
        if (!v.is_number()) {
            problem(pointer, std::format("{} must be a number, got {}.", what, describe_json_value(v)), "Write it as " + example + ".");
            return false;
        }
        const double x = v.get<double>();
        if (!(x >= lo && x <= hi)) {
            problem(pointer, std::format("{} is {}, outside {} to {}.", what, num(x), num(lo), num(hi)), "Write it as " + example + ".");
            return false;
        }
        out_ = x;
        return true;
    }

    void parse_outline(const Json& v) {
        const std::string base = "/style/outline";
        const std::string example = R"({"color": "#1a1c2c", "width": 1})";
        if (!v.is_object()) {
            problem(base, "style.outline must be an object, got " + describe_json_value(v), "Write it as " + example + ".");
            return;
        }
        unknown_keys(v, base, {"color", "width"});
        StyleOutline o;
        bool ok = true;
        if (!v.contains("color")) {
            problem(base, "style.outline needs a `color`.", "Write it as " + example + ".");
            ok = false;
        } else if (!v["color"].is_string()) {
            problem(base + "/color", "style.outline.color must be a colour string, got " + describe_json_value(v["color"]),
                    "Write \"#rrggbb\" or a colour name.");
            ok = false;
        } else {
            o.colorText = v["color"].get<std::string>();
            if (!parse_color(o.colorText, o.color)) {
                problem(base + "/color", "style.outline.color '" + o.colorText + "' is not a colour.", "Write \"#rrggbb\" or a colour name.");
                ok = false;
            }
        }
        if (v.contains("width")) {
            if (!number(v["width"], base + "/width", 0.5, 64, "style.outline.width", R"({"color": "#000000", "width": 1})", o.width)) ok = false;
        }
        if (ok) out.guide.outline = o;
    }

    void parse_light(const Json& v) {
        const std::string base = "/style/lightDirection";
        if (v.is_number()) {
            out.guide.lightDirection = wrap_degrees(v.get<double>());
            return;
        }
        if (v.is_string()) {
            const std::string name = normalize_light_name(v.get<std::string>());
            for (const auto* table : {&kLightNames, &kLightAliases})
                for (const auto& [n, deg] : *table)
                    if (n == name) {
                        out.guide.lightDirection = deg;
                        out.guide.lightDirectionName = name;
                        return;
                    }
            std::vector<std::string> names;
            for (const auto& [n, deg] : kLightNames) names.push_back(n);
            problem(base, "style.lightDirection '" + v.get<std::string>() + "' is not a direction.",
                    did_you_mean(name, names) + " Or write degrees (0 = right, 90 = top, 180 = left, 270 = bottom).");
            return;
        }
        problem(base, "style.lightDirection must be a name such as \"upper-left\" or degrees, got " + describe_json_value(v),
                "Write \"upper-left\" or 135 (degrees towards the light, counter-clockwise from the right).");
    }

    void parse_range(const Json& v, const char* key) {
        const std::string base = std::string("/style/") + key;
        const std::string example = std::string("{\"min\": 0.1, \"max\": 0.9}");
        if (!v.is_object()) {
            problem(base, std::string("style.") + key + " must be an object, got " + describe_json_value(v), "Write it as " + example + ".");
            return;
        }
        unknown_keys(v, base, {"min", "max"});
        StyleRange r;
        bool ok = true;
        for (const char* end : {"min", "max"}) {
            if (!v.contains(end)) continue;
            double x = 0;
            if (!number(v[end], base + "/" + end, 0, 1, (std::string("style.") + key + "." + end).c_str(), example, x)) ok = false;
            else (std::string(end) == "min" ? r.min : r.max) = x;
        }
        if (ok && !r.min && !r.max) {
            problem(base, std::string("style.") + key + " needs `min`, `max` or both.", "Write it as " + example + ".");
            ok = false;
        }
        if (ok && r.min && r.max && *r.min > *r.max) {
            problem(base, std::format("style.{}.min ({}) is above max ({}).", key, num(*r.min), num(*r.max)), "Swap them, or write min below max.");
            ok = false;
        }
        if (ok) (std::string(key) == "value" ? out.guide.value : out.guide.saturation) = r;
    }

    void parse_audio(const Json& v) {
        const std::string base = "/style/audio";
        const std::string example = R"({"loudnessLufs": {"music": -18, "sfx": -14, "ui": -20}, "toleranceLu": 3})";
        if (!v.is_object()) {
            problem(base, "style.audio must be an object, got " + describe_json_value(v), "Write it as " + example + ".");
            return;
        }
        unknown_keys(v, base, {"loudnessLufs", "toleranceLu"});
        StyleAudio a;
        bool ok = true;
        if (v.contains("loudnessLufs")) {
            const Json& l = v["loudnessLufs"];
            if (!l.is_object()) {
                problem(base + "/loudnessLufs", "style.audio.loudnessLufs must be an object of bus name to LUFS, got " + describe_json_value(l),
                        "Write it as " + example + ".");
                ok = false;
            } else {
                for (auto it = l.begin(); it != l.end(); ++it) {
                    double lufs = 0;
                    const std::string pointer = base + "/loudnessLufs/" + escape_json_token(it.key());
                    if (it.key().empty()) {
                        problem(pointer, "A bus name is empty.", "Name the mixer bus: sfx, music, ui, master or a bus of factoria.json audio.buses.");
                        ok = false;
                    } else if (number(it.value(), pointer, -70, 0, ("style.audio.loudnessLufs." + it.key()).c_str(), example, lufs)) {
                        a.loudnessLufs[it.key()] = lufs;
                    } else {
                        ok = false;
                    }
                }
            }
        }
        if (v.contains("toleranceLu") && !number(v["toleranceLu"], base + "/toleranceLu", 0.5, 24, "style.audio.toleranceLu", example, a.toleranceLu)) ok = false;
        if (ok) out.guide.audio = a;
    }

    void parse(const Json& style) {
        static const std::vector<std::string> known = {"prompt",      "references", "palette",  "outline", "lightDirection", "texelsPerUnit",
                                                       "pixelArt",    "value",      "saturation", "audio",  "ignore"};
        if (!style.is_object()) {
            problem("/style", "style must be an object, got " + describe_json_value(style), "See docs/ASSETS.md, \"House style\".");
            return;
        }
        unknown_keys(style, "/style", known);
        StyleGuide& g = out.guide;
        if (style.contains("prompt")) {
            if (style["prompt"].is_string()) g.prompt = style["prompt"].get<std::string>();
            else problem("/style/prompt", "style.prompt must be a string, got " + describe_json_value(style["prompt"]), "Write the text that is appended to every image prompt.");
        }
        if (style.contains("references")) {
            const Json& r = style["references"];
            if (!r.is_array()) {
                problem("/style/references", "style.references must be a list of image paths, got " + describe_json_value(r),
                        "Write [\"assets/style/hero.png\"].");
            } else {
                for (std::size_t i = 0; i < r.size(); ++i) {
                    if (r[i].is_string()) g.references.push_back(r[i].get<std::string>());
                    else problem("/style/references/" + std::to_string(i), "A reference must be a path string, got " + describe_json_value(r[i]), "Write [\"assets/style/hero.png\"].");
                }
            }
        }
        if (style.contains("palette")) {
            auto palette = load_palette(style["palette"]);
            if (palette) g.palette = std::move(*palette);
            else problem("/style/palette", "style.palette: " + palette.error().message, palette.error().hint);
        }
        if (style.contains("outline")) parse_outline(style["outline"]);
        if (style.contains("lightDirection")) parse_light(style["lightDirection"]);
        if (style.contains("texelsPerUnit")) {
            double x = 0;
            if (number(style["texelsPerUnit"], "/style/texelsPerUnit", 0.01, 4096, "style.texelsPerUnit", "16 (texture pixels per world unit)", x)) g.texelsPerUnit = x;
        }
        if (style.contains("pixelArt")) {
            if (style["pixelArt"].is_boolean()) g.pixelArt = style["pixelArt"].get<bool>();
            else problem("/style/pixelArt", "style.pixelArt must be true or false, got " + describe_json_value(style["pixelArt"]), "Write \"pixelArt\": true.");
        }
        if (style.contains("value")) parse_range(style["value"], "value");
        if (style.contains("saturation")) parse_range(style["saturation"], "saturation");
        if (style.contains("audio")) parse_audio(style["audio"]);
        if (style.contains("ignore")) {
            const Json& r = style["ignore"];
            if (!r.is_array()) {
                problem("/style/ignore", "style.ignore must be a list of paths, got " + describe_json_value(r),
                        "Write [\"assets/ui/\", \"assets/fx/spark.png\"] (a folder ends in a slash).");
            } else {
                for (std::size_t i = 0; i < r.size(); ++i) {
                    if (r[i].is_string()) g.ignore.push_back(fs::normalize(r[i].get<std::string>()) + (ends_with(r[i].get<std::string>(), "/") ? "/" : ""));
                    else problem("/style/ignore/" + std::to_string(i), "An ignored path must be a string, got " + describe_json_value(r[i]), "Write \"assets/ui/\".");
                }
            }
        }
    }
};

}  // namespace

const std::vector<std::pair<std::string, double>>& light_direction_names() { return kLightNames; }

std::string light_direction_label(double degrees) {
    const double d = wrap_degrees(degrees);
    const auto* best = &kLightNames[0];
    double bestDiff = 1e9;
    for (const auto& n : kLightNames) {
        const double diff = std::min(std::fabs(d - n.second), 360.0 - std::fabs(d - n.second));
        if (diff < bestDiff) {
            bestDiff = diff;
            best = &n;
        }
    }
    return best->first;
}

bool StyleGuide::has_art_rules() const {
    return outline || lightDirection || texelsPerUnit || pixelArt || value || saturation || palette;
}

bool StyleGuide::ignores(const std::string& path) const {
    for (const std::string& p : ignore) {
        if (p.empty()) continue;
        if (p.back() == '/' ? path.rfind(p, 0) == 0 : path == p) return true;
    }
    return false;
}

StyleParse parse_style(const Json& style) {
    Parser p;
    p.parse(style);
    return std::move(p.out);
}

StyleParse load_style_guide() {
    const Json manifest = assets::manifest();
    if (!manifest.is_object() || !manifest.contains("style")) return {};
    return parse_style(manifest["style"]);
}

StyleParse load_style_guide(const std::string& projectDir) {
    tooling_detail::ProjectRootScope root(projectDir);
    return load_style_guide();
}

}  // namespace fa
