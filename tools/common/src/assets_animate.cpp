// assets.animate_svg: an animation drawn with code, baked into a sprite sheet in one call. A project JS module (a `frame()`
// function that returns the SVG of each frame) or one SVG with SMIL animation is sampled frame by frame; every frame is
// rasterized with the path of assets.rasterize_svg (rasterize_svg_text: same pixels, same painterly styles), snapped to an
// optional palette, and laid out in a grid with gutters. The PNG and its `sheet` entry of assets.json are written together,
// and provenance.recipe records how to make the sheet again. The sandbox of the module is assets_anim_js.cpp, the sampling of
// SMIL is svg_smil.cpp.
#include <algorithm>
#include <array>
#include <cmath>
#include <filesystem>
#include <format>
#include <set>

#include "assets_anim_js.h"
#include "assets_animate_prefab.h"
#include "assets_internal.h"
#include "sheet_checks.h"
#include "fa/core/asset_manifest.h"
#include "fa/core/strings.h"
#include "fa/scene/serialize.h"
#include "assets_shots.h"
#include "fa/tooling/asset_import.h"
#include "fa/tooling/image_doc.h"
#include "fa/tooling/palette.h"
#include "fa/tooling/svg_smil.h"
#include "util.h"

namespace fa::assets_detail {

namespace {

constexpr const char* kCommand = "assets.animate_svg";
constexpr int kMaxCell = 1024;       // a frame side
constexpr int kMaxSheetSide = 8192;  // the PNG's side
constexpr int kMaxFrames = 2048;
constexpr std::size_t kMaxRampColours = 32;
constexpr double kMaxBakeBytes = 1024.0 * 1024.0 * 1024.0;  // the pictures of all layers and their sheets, held at once

// The layers of a baked effect, in the order they are stacked: behind the character, in front of it, and an additive light pass.
const std::vector<std::string>& layer_names() {
    static const std::vector<std::string> names = {"back", "front", "light"};
    return names;
}

// "assets/art/hit.png" + "back" -> "assets/art/hit_back.png".
std::string layer_path(const std::string& rel, const std::string& layer) {
    const std::string dir = fs::parent(rel);
    return (dir.empty() ? std::string() : dir + "/") + fs::stem(rel) + "_" + layer + fs::extension(rel);
}

// The colour a brightness (0 dark .. 1 bright) has on a ramp: the ramp's colours blended between neighbours.
std::array<double, 3> ramp_colour(const Palette& ramp, double u) {
    const double x = std::clamp(u, 0.0, 1.0) * double(ramp.size() - 1);
    const std::size_t i = std::min(ramp.size() - 2, std::size_t(x));
    const double f = x - double(i);
    std::array<double, 3> out{};
    for (int c = 0; c < 3; ++c)
        out[std::size_t(c)] =
            ramp[i][std::size_t(c)] + (double(ramp[i + 1][std::size_t(c)]) - ramp[i][std::size_t(c)]) * f;
    return out;
}

// Recolours a picture by brightness: the darkest pixel takes the first colour of the ramp, the brightest the last. The brightness is
// absolute (not scaled to the picture), so a pulse that gets brighter over the frames still does on the sheet; alpha is kept.
Image map_to_ramp(const Image& src, const Palette& ramp) {
    Image out = src;
    for (std::size_t i = 0; i + 3 < out.rgba.size(); i += 4) {
        if (out.rgba[i + 3] == 0) continue;
        const double luma = (0.2126 * out.rgba[i] + 0.7152 * out.rgba[i + 1] + 0.0722 * out.rgba[i + 2]) / 255.0;
        const std::array<double, 3> c = ramp_colour(ramp, luma);
        for (std::size_t k = 0; k < 3; ++k) out.rgba[i + k] = std::uint8_t(std::lround(std::clamp(c[k], 0.0, 255.0)));
    }
    return out;
}

std::string hex_of(const std::array<std::uint8_t, 3>& c) {
    return std::format("#{:02x}{:02x}{:02x}", c[0], c[1], c[2]);
}

struct ClipSpec {
    std::string name;
    int frames = 1;
    double fps = 12;
    bool loop = true;
    Json params = Json::object();
    std::optional<std::array<double, 2>> pivot;
};

struct FrameJob {
    int clip = 0;   // index in the clips
    int frame = 0;  // inside the clip
    int sheetFrame = 0;
};

// True when factoria.json lists android or ios in `platforms` (the same test as project.validate's texture checks).
bool project_targets_mobile(const std::string& projectDir) {
    auto text = tooling_detail::read_file(project_file(projectDir, "factoria.json"));
    if (!text) return false;
    auto parsed = parse_json(*text, "factoria.json");
    if (!parsed.ok() || !parsed->is_object() || !parsed->contains("platforms") || !(*parsed)["platforms"].is_array())
        return false;
    for (const Json& p : (*parsed)["platforms"])
        if (p.is_string() && (to_lower(p.get<std::string>()) == "android" || to_lower(p.get<std::string>()) == "ios"))
            return true;
    return false;
}

std::string checked_png_path(const std::string& path) {
    auto norm = fs::normalize_checked(path);
    if (!norm.ok() || norm->empty() || !starts_with(*norm, "assets/"))
        fail("invalid_argument", "The sheet goes under assets/, and '" + path + "' is not there.",
             "Use a path such as \"assets/art/coin_spin.png\".");
    if (to_lower(fs::extension(*norm)) != ".png")
        fail("invalid_argument", std::string(kCommand) + " writes PNG files, and '" + *norm + "' does not end in .png.",
             "Use a path such as \"assets/art/coin_spin.png\".");
    return *norm;
}

int int_arg(const Json& obj, const char* key, const std::string& pointer, int lo, int hi, int fallback,
            const char* hint) {
    auto it = obj.find(key);
    if (it == obj.end() || it->is_null()) return fallback;
    if (!it->is_number_integer() || it->get<long long>() < lo || it->get<long long>() > hi)
        arg_error(kCommand, pointer + "/" + key, std::format("expected a whole number from {} to {}.", lo, hi), hint);
    return int(it->get<long long>());
}

double fps_arg(const Json& obj, const std::string& pointer, double fallback) {
    auto it = obj.find("fps");
    if (it == obj.end() || it->is_null()) return fallback;
    if (!it->is_number() || !(it->get<double>() > 0.0 && it->get<double>() <= 240.0))
        arg_error(kCommand, pointer + "/fps", "expected a number above 0 and up to 240 (frames per second).",
                  "12 is a good rate for hand-drawn motion, 24 for smooth motion.");
    return it->get<double>();
}

bool loop_arg(const Json& obj, const std::string& pointer, bool fallback) {
    auto it = obj.find("loop");
    if (it == obj.end() || it->is_null()) return fallback;
    if (!it->is_boolean())
        arg_error(kCommand, pointer + "/loop", "expected true or false.",
                  "true repeats the clip (the default); false plays it once.");
    return it->get<bool>();
}

Json params_arg(const Json& obj, const std::string& pointer) {
    auto it = obj.find("params");
    if (it == obj.end() || it->is_null()) return Json::object();
    if (!it->is_object())
        arg_error(kCommand, pointer + "/params", "expected an object.",
                  "params is the object the module receives as `params`: {\"color\": \"#e8c66a\"}.");
    return *it;
}

std::optional<std::array<double, 2>> pivot_arg(const Json& obj, const std::string& pointer) {
    auto it = obj.find("pivot");
    if (it == obj.end() || it->is_null()) return std::nullopt;
    if (!it->is_array() || it->size() != 2 || !(*it)[0].is_number() || !(*it)[1].is_number() ||
        (*it)[0].get<double>() < 0 || (*it)[0].get<double>() > 1 || (*it)[1].get<double>() < 0 ||
        (*it)[1].get<double>() > 1)
        arg_error(kCommand, pointer + "/pivot",
                  "expected [x, y], two numbers from 0 to 1 measured from the top-left of the frame.",
                  "[0.5, 0.5] is the centre (the default); [0.5, 1] is the middle of the bottom edge, where a "
                  "character stands.");
    return std::array<double, 2>{(*it)[0].get<double>(), (*it)[1].get<double>()};
}

Json animate(const std::string& projectDir, const Json& a) {
    if (!a.is_object())
        fail("invalid_argument", "assets.animate_svg expects an object.",
             "See the description of the command for the fields.");
    check_arg_keys(kCommand, a, "",
                   {"path",       "source",      "svg",     "frames", "fps",     "loop",       "columns",
                    "frameWidth", "frameHeight", "params",  "seed",   "clips",   "pivot",      "palette",
                    "ramp",       "rampIndex",   "rampMap", "layers", "prefab",  "style",      "styleStrength",
                    "padding",    "overwrite",   "ai",      "author", "license", "timeLimitMs"});
    const std::string rel = checked_png_path(tooling_detail::arg_string(a, "path", true));
    const bool hasSvg = a.contains("svg"), hasSource = a.contains("source");
    if (hasSvg == hasSource)
        fail("invalid_argument",
             hasSvg ? "Give either `source` (a module or an SVG file of the project) or `svg` (SVG text with SMIL "
                      "animation), not both."
                    : "Give `source` (a project module such as \"art/coin_spin.anim.js\") or `svg` (one SVG with SMIL "
                      "animation).",
             "Example: "
             "{\"path\":\"assets/art/coin_spin.png\",\"source\":\"art/"
             "coin_spin.anim.js\",\"frames\":8,\"fps\":10,\"frameWidth\":64,\"frameHeight\":64}");

    // ---- the source ----
    std::string sourceRel, svgText;
    bool isModule = false;
    if (hasSvg) {
        svgText = tooling_detail::arg_string(a, "svg", true);
        if (svgText.find("<svg") == std::string::npos)
            arg_error(kCommand, "/svg", "the text has no <svg> element.",
                      "Start with <svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 100 100\"> and put <animate> "
                      "elements inside the shapes.");
    } else {
        auto norm = fs::normalize_checked(tooling_detail::arg_string(a, "source", true));
        if (!norm.ok() || norm->empty())
            arg_error(kCommand, "/source", "not a project path.",
                      "Use a project-relative path such as \"art/coin_spin.anim.js\".");
        sourceRel = *norm;
        const std::string ext = to_lower(fs::extension(sourceRel));
        if (ext == ".js" || ext == ".mjs") {
            isModule = true;
        } else if (ext == ".svg") {
            auto data = tooling_detail::read_file(project_file(projectDir, sourceRel));
            if (!data)
                fail("not_found", "Cannot read '" + sourceRel + "'.",
                     "Check the path; it is relative to the project folder.");
            svgText = std::move(*data);
        } else {
            arg_error(
                kCommand, "/source", "'" + sourceRel + "' is neither a JavaScript module (.js) nor an .svg file.",
                "Name the module that draws the frames (\"art/coin_spin.anim.js\"), or an .svg with SMIL animation.");
        }
    }

    // ---- the frames ----
    const double fps = fps_arg(a, "", 12);
    const bool loop = loop_arg(a, "", true);
    const int frameW =
        int_arg(a, "frameWidth", "", 1, kMaxCell, 64,
                "The size of one frame in pixels, 1 to 1024; the SVG is fitted inside, aspect kept, centred.");
    const int frameH =
        int_arg(a, "frameHeight", "", 1, kMaxCell, frameW,
                "The size of one frame in pixels, 1 to 1024; the SVG is fitted inside, aspect kept, centred.");
    const int padding = int_arg(
        a, "padding", "", 0, 64, 0,
        "Transparent pixels around every cell (0 to 64): 1 or 2 keeps filtered frames from bleeding into each other.");
    const std::uint32_t seed = std::uint32_t(tooling_detail::arg_int(a, "seed", 0));
    const Json params = params_arg(a, "");
    const auto pivot = pivot_arg(a, "");
    const int timeLimitMs = int_arg(a, "timeLimitMs", "", 10, 60000, 2000,
                                    "Milliseconds a module may take to load, and for each frame (default 2000).");
    std::vector<std::string> warnings;
    auto warn = [&](const std::string& w) {
        if (std::find(warnings.begin(), warnings.end(), w) == warnings.end()) warnings.push_back(w);
    };

    std::optional<SmilSvg> smil;
    double cycle = 0;
    if (!isModule) {
        auto parsed = SmilSvg::parse(svgText);
        if (!parsed.ok())
            fail("invalid_svg",
                 (sourceRel.empty() ? std::string("`svg`: ") : sourceRel + ": ") + parsed.error().message,
                 parsed.error().hint);
        smil = std::move(*parsed);
        cycle = smil->cycle_seconds();
        if (smil->animation_count() == 0)
            warn("The SVG has no <animate>, <set>, <animateTransform> or <animateMotion> element: every frame is the "
                 "same. Animate it, or give `source` a module that draws each frame.");
        if (a.contains("params") && !params.empty())
            warn("`params` only reaches a module (`source`); an SVG with SMIL ignores it.");
    }

    std::vector<ClipSpec> clips;
    const bool hasClips = a.contains("clips") && !a["clips"].is_null();
    if (hasClips) {
        if (!isModule)
            arg_error(kCommand, "/clips", "clips need a module (`source`): one SMIL SVG has a single timeline.",
                      "Draw the clips in a module that reads `clip` from its argument, or call assets.animate_svg once "
                      "per animation.");
        if (a.contains("frames"))
            arg_error(kCommand, "/frames",
                      "give `frames` per clip when there are `clips`; the sheet holds all of them one after another.",
                      "Remove /frames and set /clips/0/frames.");
        const Json& list = a["clips"];
        if (!list.is_array() || list.empty())
            arg_error(
                kCommand, "/clips", "expected a non-empty array of clips.",
                "Example: [{\"name\":\"idle\",\"frames\":4,\"fps\":6},{\"name\":\"spin\",\"frames\":8,\"fps\":12}]");
        std::set<std::string> seen;
        for (std::size_t i = 0; i < list.size(); ++i) {
            const std::string ptr = "/clips/" + std::to_string(i);
            const Json& c = list[i];
            if (!c.is_object())
                arg_error(kCommand, ptr, "expected an object {name, frames, fps, loop, params, pivot}.",
                          "Example: {\"name\":\"idle\",\"frames\":4,\"fps\":6}");
            check_arg_keys(kCommand, c, ptr, {"name", "frames", "fps", "loop", "params", "pivot"});
            ClipSpec spec;
            if (!c.contains("name") || !c["name"].is_string() || c["name"].get<std::string>().empty())
                arg_error(kCommand, ptr + "/name", "expected a non-empty string.",
                          "The name the module reads as `clip` and the SpriteAnimator plays: \"idle\", \"spin\".");
            spec.name = c["name"].get<std::string>();
            if (!seen.insert(spec.name).second)
                arg_error(kCommand, ptr + "/name", "the name '" + spec.name + "' is used by two clips.",
                          "Give every clip its own name.");
            spec.frames = int_arg(c, "frames", ptr, 1, kMaxFrames, 0, "The number of frames of this clip.");
            if (spec.frames == 0)
                arg_error(kCommand, ptr + "/frames", "required: how many frames the clip has.",
                          "For example \"frames\": 8.");
            spec.fps = fps_arg(c, ptr, fps);
            spec.loop = loop_arg(c, ptr, loop);
            spec.params = params_arg(c, ptr);
            spec.pivot = pivot_arg(c, ptr);
            clips.push_back(std::move(spec));
        }
    } else {
        ClipSpec spec;
        spec.name = stdfs::path(rel).stem().string();
        if (spec.name.empty()) spec.name = "clip";
        int frames = int_arg(a, "frames", "", 1, kMaxFrames, 0, "The number of frames of the animation.");
        if (frames == 0) {
            if (isModule)
                arg_error(kCommand, "/frames", "required with a module: how many frames to draw.",
                          "For example \"frames\": 8 (with fps 10 that is 0.8 s).");
            frames = cycle > 0 ? std::max(1, int(std::lround(cycle * fps))) : 1;
            if (frames > kMaxFrames)
                arg_error(kCommand, "/frames",
                          std::format("the animation lasts {} s, which is {} frames at {} fps.", cycle, frames, fps),
                          "Pass `frames` and a lower `fps`.");
        }
        spec.frames = frames;
        spec.fps = fps;
        spec.loop = loop;
        clips.push_back(std::move(spec));
    }
    int total = 0;
    for (const ClipSpec& c : clips) total += c.frames;
    if (total > kMaxFrames)
        arg_error(kCommand, hasClips ? "/clips" : "/frames",
                  std::format("{} frames in all; the most a sheet takes is {}.", total, kMaxFrames),
                  "Draw fewer frames, or split the animation into two sheets.");

    int columns = int_arg(a, "columns", "", 1, kMaxFrames, 0, "How many frames per row of the sheet.");
    if (columns == 0) columns = int(std::ceil(std::sqrt(double(total))));
    if (columns > total) {
        warn(std::format("columns {} is more than the {} frames; it was lowered to {}.", columns, total, total));
        columns = total;
    }
    const int rows = (total + columns - 1) / columns;
    const int cellW = frameW + 2 * padding, cellH = frameH + 2 * padding;
    const long long sheetW = (long long)columns * cellW, sheetH = (long long)rows * cellH;
    if (sheetW > kMaxSheetSide || sheetH > kMaxSheetSide)
        fail("invalid_argument",
             std::format("The sheet would be {}x{} px ({} columns x {} rows of {}x{} cells); the most is {}.", sheetW,
                         sheetH, columns, rows, cellW, cellH, kMaxSheetSide),
             "Make the frames smaller, or set `columns` so the sheet is closer to a square (" +
                 std::to_string(int(std::ceil(std::sqrt(double(total))))) + " columns for " + std::to_string(total) +
                 " frames).");

    // ---- the look ----
    std::string style = "none";
    if (a.contains("style") && !a["style"].is_null()) {
        if (!a["style"].is_string())
            arg_error(kCommand, "/style", "expected a string.", "One of: " + join(image_style_names(), ", ") + ".");
        style = to_lower(a["style"].get<std::string>());
        const auto& names = image_style_names();
        if (std::find(names.begin(), names.end(), style) == names.end())
            arg_error(kCommand, "/style", "unknown style '" + a["style"].get<std::string>() + "'.",
                      did_you_mean(style, names) + " Styles: " + join(names, ", ") + ".");
    }
    double styleStrength = 1.0;
    if (a.contains("styleStrength") && !a["styleStrength"].is_null()) {
        if (!a["styleStrength"].is_number() ||
            !(a["styleStrength"].get<double>() >= 0.0 && a["styleStrength"].get<double>() <= 1.0))
            arg_error(kCommand, "/styleStrength", "expected a number from 0 to 1.",
                      "0 leaves the picture as drawn, 1 is the full effect (the default); 0.5 is subtle.");
        styleStrength = a["styleStrength"].get<double>();
    }
    if (style == "none" && a.contains("styleStrength"))
        warn("styleStrength only matters with a `style`; it was ignored.");
    std::optional<Palette> palette;
    std::vector<std::string> inputs;
    if (a.contains("palette") && !a["palette"].is_null()) {
        ProjectRootGuard root(projectDir);
        auto loaded = load_palette(a["palette"]);
        if (!loaded.ok()) arg_error(kCommand, "/palette", loaded.error().message, loaded.error().hint);
        palette = std::move(*loaded);
        if (a["palette"].is_string()) {
            auto norm = fs::normalize_checked(a["palette"].get<std::string>());
            if (norm.ok() && !norm->empty()) inputs.push_back(*norm);
        }
    }

    // ---- the ramp: the effect's colours from dark to bright ----
    Palette ramp;
    if (a.contains("ramp") && !a["ramp"].is_null()) {
        const Json& spec = a["ramp"];
        const std::string rampHint =
            "Example: \"ramp\": [\"#1b1034\", \"#c4382a\", \"#ffd36b\"] (darkest first), or the path of an image "
            "document with `ramps` (\"assets/art/hero.image.json\") and `rampIndex`.";
        if (spec.is_array()) {
            if (a.contains("rampIndex"))
                warn("`rampIndex` only matters when `ramp` is the path of an image document; it was ignored.");
            auto loaded = load_palette(spec);
            if (!loaded.ok()) arg_error(kCommand, "/ramp", loaded.error().message, rampHint);
            ramp = std::move(*loaded);
        } else if (spec.is_string()) {
            auto norm = fs::normalize_checked(spec.get<std::string>());
            if (!norm.ok() || norm->empty() || !ends_with(to_lower(*norm), ".image.json"))
                arg_error(kCommand, "/ramp",
                          "'" + spec.get<std::string>() +
                              "' is not a list of colours or the path of an image document (*.image.json).",
                          rampHint);
            auto doc = load_image_document(projectDir, *norm);
            if (!doc.ok()) arg_error(kCommand, "/ramp", doc.error().message, doc.error().hint);
            const PixelPalette& pal = doc->palette;
            const int index = int_arg(a, "rampIndex", "", 0, 1000, 0,
                                      "Which ramp of the document: 0 is the first one image.palette lists.");
            if (pal.ramps.empty())
                arg_error(kCommand, "/ramp", "the document '" + *norm + "' declares no colour ramps.",
                          "Declare one with image.palette {\"path\":\"" + *norm +
                              "\",\"ramps\":[[\"#1b1034\",\"#c4382a\",\"#ffd36b\"]]}, or list the colours here.");
            if (std::size_t(index) >= pal.ramps.size())
                arg_error(kCommand, "/rampIndex",
                          std::format("the document has {} ramp(s), numbered from 0; {} is not one of them.",
                                      pal.ramps.size(), index),
                          "image.palette {\"path\":\"" + *norm + "\"} lists the ramps.");
            for (int colour : pal.ramps[std::size_t(index)]) ramp.push_back(pal.entries[std::size_t(colour)].rgb);
            inputs.push_back(*norm);
        } else {
            arg_error(kCommand, "/ramp",
                      "expected a list of \"#rrggbb\" colours or the path of an image document, got " +
                          describe_json_value(spec) + ".",
                      rampHint);
        }
        if (ramp.size() < 2 || ramp.size() > kMaxRampColours)
            arg_error(kCommand, "/ramp",
                      std::format("a ramp has 2 to {} colours, this one has {}.", kMaxRampColours, ramp.size()),
                      rampHint);
    } else if (a.contains("rampIndex")) {
        arg_error(kCommand, "/rampIndex", "there is no `ramp` to pick from.",
                  "Give `ramp` as the path of an image document, or remove `rampIndex`.");
    }
    bool rampMap = false;
    if (a.contains("rampMap") && !a["rampMap"].is_null()) {
        if (!a["rampMap"].is_boolean())
            arg_error(kCommand, "/rampMap", "expected true or false.",
                      "true recolours the finished frames by brightness with the `ramp`.");
        rampMap = a["rampMap"].get<bool>();
        if (rampMap && ramp.empty())
            arg_error(kCommand, "/rampMap", "there is no `ramp` to recolour with.",
                      "Give `ramp`, a list of colours from dark to bright.");
    }
    if (!ramp.empty() && !isModule && !rampMap)
        arg_error(kCommand, "/ramp", "an SVG with SMIL cannot read the ramp: its colours are written in the SVG.",
                  "Add \"rampMap\": true to recolour the frames by brightness (draw the effect in greys, dark to "
                  "bright), or draw the frames with a module that reads `ramp` and `rampAt(u)`.");
    std::vector<std::string> rampHex;
    for (const auto& c : ramp) rampHex.push_back(hex_of(c));

    // ---- the layers: one sheet per layer, the same grid, frames, pivot and timing ----
    std::vector<std::string> layerList;  // {""} = one sheet, no layers
    if (a.contains("layers") && !a["layers"].is_null()) {
        const std::string layerHint = "Example: \"layers\": [\"back\", \"front\", \"light\"]: `back` is drawn behind "
                                      "the character, `front` in front of it and `light` is an additive glow.";
        if (!isModule)
            arg_error(
                kCommand, "/layers",
                "layers need a module (`source`): the module draws each layer, a SMIL SVG has one picture.",
                "Write a module that reads `layer` and returns the SVG of that layer, or bake the SVG without layers.");
        const Json& list = a["layers"];
        if (!list.is_array() || list.empty())
            arg_error(kCommand, "/layers", "expected a non-empty array of layer names.", layerHint);
        for (std::size_t i = 0; i < list.size(); ++i) {
            const std::string ptr = "/layers/" + std::to_string(i);
            if (!list[i].is_string())
                arg_error(kCommand, ptr, "expected a layer name, got " + describe_json_value(list[i]) + ".", layerHint);
            const std::string name = to_lower(list[i].get<std::string>());
            if (std::find(layer_names().begin(), layer_names().end(), name) == layer_names().end())
                arg_error(kCommand, ptr, "unknown layer '" + list[i].get<std::string>() + "'.",
                          did_you_mean(name, layer_names()) + " Layers: " + join(layer_names(), ", ") + ".");
            if (std::find(layerList.begin(), layerList.end(), name) != layerList.end())
                arg_error(kCommand, ptr, "the layer '" + name + "' is listed twice.", "List each layer once.");
            layerList.push_back(name);
        }
        // always stacked back, front, light, whatever the order given
        std::sort(layerList.begin(), layerList.end(), [](const std::string& x, const std::string& y) {
            const auto& n = layer_names();
            return std::find(n.begin(), n.end(), x) < std::find(n.begin(), n.end(), y);
        });
    }
    const bool layered = !layerList.empty();
    if (!layered) layerList.push_back("");
    std::vector<std::string> layerRels;
    for (const std::string& layer : layerList) layerRels.push_back(layer.empty() ? rel : layer_path(rel, layer));

    std::optional<AnimatePrefabSpec> prefabSpec;
    if (a.contains("prefab") && !a["prefab"].is_null())
        prefabSpec = parse_animate_prefab(kCommand, a["prefab"], layered ? layerList : std::vector<std::string>(),
                                          frameW, frameH, warnings);

    const bool overwrite = tooling_detail::arg_bool(a, "overwrite", false);
    std::error_code ec;
    // every file this call writes is checked before the SVG is rasterized: managed folders (.git, .factoria), links out of the project
    for (const std::string& lr : layerRels) (void)project_write_file(projectDir, lr);
    if (prefabSpec) (void)project_write_file(projectDir, prefabSpec->rel);
    if (prefabSpec && !prefabSpec->overwrite && stdfs::exists(project_file(projectDir, prefabSpec->rel), ec))
        fail("exists",
             "The prefab '" + prefabSpec->rel +
                 "' already exists, and may hold changes made by hand (`overwrite` is about the sheets, not the "
                 "prefab).",
             "Pass \"prefab\": {\"path\": \"" + prefabSpec->rel +
                 "\", \"overwrite\": true} to write it again, or choose another prefab path. Nothing was baked.");
    for (const std::string& lr : layerRels)
        if (!overwrite && stdfs::exists(project_file(projectDir, lr), ec))
            fail("exists", "'" + lr + "' already exists.",
                 "Pass overwrite: true to replace it, or choose another `path`.");
    require_usable_manifest(projectDir);
    {
        // every layer holds its frames until its sheet is built, and a layered bake keeps the sheets for the picture of the result
        const double perLayer = double(total) * frameW * frameH * 4.0 + double(sheetW) * double(sheetH) * 4.0;
        if (perLayer * double(layerList.size()) > kMaxBakeBytes)
            fail("invalid_argument",
                 std::format("Baking {} layer(s) of {} frames of {}x{} px into {}x{} px sheets would need about {} MB "
                             "of memory; the most is {} MB.",
                             layerList.size(), total, frameW, frameH, sheetW, sheetH,
                             std::llround(perLayer * double(layerList.size()) / (1024.0 * 1024.0)),
                             std::llround(kMaxBakeBytes / (1024.0 * 1024.0))),
                 "Bake fewer layers in one call (a layer can be baked on its own with the same `path`), draw fewer or "
                 "smaller frames, or lower frameWidth/frameHeight.");
    }

    // ---- draw every frame of every layer ----
    std::unique_ptr<AnimModule> module;
    if (isModule) {
        AnimModule::Limits limits;
        limits.seconds = timeLimitMs / 1000.0;
        module = AnimModule::load(projectDir, sourceRel, limits);
    }
    std::vector<FrameJob> jobs;
    for (std::size_t c = 0; c < clips.size(); ++c)
        for (int f = 0; f < clips[c].frames; ++f) jobs.push_back({int(c), f, int(jobs.size())});

    std::set<std::string> unsupportedSaid;
    std::vector<std::vector<Image>> layerPictures(layerList.size());
    std::vector<std::vector<bool>> layerEmpty(layerList.size(), std::vector<bool>(jobs.size(), false));
    for (std::size_t li = 0; li < layerList.size(); ++li) {
        const std::string& layer = layerList[li];
        const std::string layerLabel = layer.empty() ? std::string() : "Layer \"" + layer + "\": ";
        std::vector<Image>& pictures = layerPictures[li];
        pictures.resize(jobs.size());
        std::vector<std::string> edgeFrames;
        for (const FrameJob& job : jobs) {
            const ClipSpec& clip = clips[std::size_t(job.clip)];
            const double t = job.frame / clip.fps;
            std::string where = hasClips ? std::format("frame {} of clip \"{}\"", job.frame, clip.name)
                                         : std::format("frame {}", job.frame);
            if (!layer.empty()) where += std::format(", layer \"{}\"", layer);
            std::string text;
            if (isModule) {
                AnimFrame f;
                f.clip = hasClips ? clip.name : "";
                f.layer = layer;
                f.ramp = rampHex;
                f.frame = job.frame;
                f.frames = clip.frames;
                f.sheetFrame = job.sheetFrame;
                f.fps = clip.fps;
                f.t = t;
                f.progress = clip.loop ? double(job.frame) / clip.frames
                                       : (clip.frames > 1 ? double(job.frame) / (clip.frames - 1) : 0.0);
                f.width = frameW;
                f.height = frameH;
                f.params = params;
                if (hasClips)
                    for (auto it = clip.params.begin(); it != clip.params.end(); ++it) f.params[it.key()] = it.value();
                f.baseSeed = seed;
                // the stream of a frame depends on the seed and the frame (its place in the sheet), nothing else: every layer of a frame
                // draws from the same stream, so a spark in `back` and its glow in `light` can agree
                f.seed = (seed * 2654435761u) ^ (std::uint32_t(job.sheetFrame + 1) * 40503u) ^ 0x9e3779b9u;
                text = module->draw(f);
            } else {
                text = smil->sample(t);
            }
            std::vector<std::string> local;
            Image picture;
            try {
                picture = rasterize_svg_text(text, frameW, frameH, style, styleStrength, seed, local).image;
            } catch (const CommandError& e) {
                if (e.code != "no_shapes") {
                    fail(e.code.c_str(),
                         (isModule ? sourceRel + ": " : std::string()) + where + " is not a drawable SVG: " + e.what(),
                         e.hint);
                }
                picture.width = frameW;
                picture.height = frameH;
                picture.rgba.assign(std::size_t(frameW) * frameH * 4, 0);
                // the same complaint comes back for every frame and every layer: say it once, where it first happened
                const std::string what = e.what();
                if (what.find("not supported") != std::string::npos && unsupportedSaid.insert(what).second)
                    warn(where + ": " + what);
            }
            for (const std::string& w : local) warn(w);
            if (rampMap) picture = map_to_ramp(picture, ramp);
            if (palette) picture = quantize_to_palette(picture, *palette);
            if (picture_is_empty(picture)) {
                layerEmpty[li][std::size_t(job.sheetFrame)] = true;
            } else if (touches_edge(picture)) {
                edgeFrames.push_back(std::to_string(job.sheetFrame));
            }
            pictures[std::size_t(job.sheetFrame)] = std::move(picture);
        }
        if (!edgeFrames.empty())
            warn(std::format("{}Shapes touch the edge of the cell in {} frame(s) (frame {}): they may be cut off. Draw "
                             "smaller inside the viewBox, or make frameWidth/frameHeight larger, or set `padding` (a "
                             "transparent gutter around each frame).",
                             layerLabel, edgeFrames.size(), list_frames(edgeFrames)));
        if (layered && std::all_of(layerEmpty[li].begin(), layerEmpty[li].end(), [](bool e) { return e; }))
            warn(std::format("{}draws nothing in any frame: the module returned an empty drawing for it (or its shapes "
                             "sit outside the viewBox). Draw it, or leave it out of `layers`.",
                             layerLabel));
    }
    if (smil)
        for (const std::string& w : smil->warnings()) warn(w);
    {
        // a frame is empty when every layer draws nothing in it (one layer may well be idle in some frames)
        std::vector<std::string> emptyFrames;
        for (std::size_t f = 0; f < jobs.size(); ++f) {
            bool all = true;
            for (const auto& e : layerEmpty) all = all && e[f];
            if (all) emptyFrames.push_back(std::to_string(f));
        }
        if (!emptyFrames.empty())
            warn(std::format("{} of the {} frames draw nothing (frame {}): the shapes may sit outside the viewBox, or "
                             "the module returned an empty drawing.",
                             emptyFrames.size(), total, list_frames(emptyFrames)));
    }
    for (std::size_t li = 0; li < layerList.size(); ++li) {
        int first = 0;
        for (const ClipSpec& clip : clips) {
            if (clip.loop && clip.frames >= 3) {
                std::vector<const Image*> clipFrames;
                for (int f = 0; f < clip.frames; ++f) clipFrames.push_back(&layerPictures[li][std::size_t(first + f)]);
                const std::string label =
                    (hasClips ? " of clip \"" + clip.name + "\"" : std::string()) +
                    (layerList[li].empty() ? std::string() : " in layer \"" + layerList[li] + "\"");
                if (auto w = loop_seam_warning(clipFrames, label)) warn(*w);
            }
            first += clip.frames;
        }
    }
    if (std::max(sheetW, sheetH) > 4096)
        warn(std::format("The sheet is {}x{} px; many mobile GPUs cannot sample a texture over 4096 px.", sheetW,
                         sheetH));
    if (auto w = block_size_warning(columns, rows, frameW, frameH, padding); w && project_targets_mobile(projectDir)) {
        // a sheet whose import settings turn compression off (or put it in an atlas) ships as it is: nothing to say about it
        ProjectRootGuard root(projectDir);
        const auto compressed = [](const Json& s) {
            const auto setting = [&](const char* key) {
                return s.is_object() && s.contains(key) && s[key].is_string() ? s[key].get<std::string>()
                                                                              : std::string();
            };
            return setting("compression") != "none" && setting("atlas").empty();
        };
        for (const std::string& lr : layerRels)
            if (compressed(assets::import_settings(lr))) {
                warn(*w);
                break;
            }
    }
    if (module && ((!ramp.empty() && !rampMap) || layered)) {
        // a module that never names `ramp` (or `layer`) ignores it: say so
        const auto module_names = [&](const char* word) {
            for (const std::string& f : module->files())
                if (auto text = tooling_detail::read_file(project_file(projectDir, f));
                    text && text->find(word) != std::string::npos)
                    return true;
            return false;
        };
        if (!ramp.empty() && !rampMap && !module_names("ramp"))
            warn("`ramp` is given but the module never reads `ramp` or `rampAt`, so the colours did not change. Use "
                 "rampAt(u) in the module (u from 0 dark to 1 bright), or pass \"rampMap\": true to recolour the "
                 "frames by brightness.");
        if (layered && layerList.size() > 1 && !module_names("layer"))
            warn("`layers` is given but the module never reads `layer`, so every layer is the same drawing. Return a "
                 "different SVG for each layer: frame({layer}) { if (layer === 'back') ... } (the argument of frame() "
                 "has `layer`).");
    }

    // ---- the sheets ----
    std::vector<SheetClip> sheetClips;
    {
        int first = 0;
        for (const ClipSpec& c : clips) {
            SheetClip sc;
            sc.name = c.name;
            sc.firstFrame = first;
            sc.lastFrame = first + c.frames - 1;
            sc.fps = c.fps;
            sc.loop = c.loop;
            sc.pivot = c.pivot;
            sheetClips.push_back(sc);
            first += c.frames;
        }
    }
    const Json sheet = sheet_entry(columns, rows, frameW, frameH, total, sheetClips, padding, pivot);
    // Every sheet is composed and encoded before the first file is written, so a picture that cannot be encoded leaves the project as it was,
    // and the frames of a layer are freed as soon as its sheet exists. Only a layered bake keeps the sheets (for the picture of the result).
    std::vector<Image> sheetImages;
    std::vector<std::vector<std::uint8_t>> pngs;
    for (std::size_t li = 0; li < layerList.size(); ++li) {
        Image sheetImage;
        sheetImage.width = int(sheetW);
        sheetImage.height = int(sheetH);
        sheetImage.rgba.assign(std::size_t(sheetW) * std::size_t(sheetH) * 4, 0);
        std::vector<Image>& pictures = layerPictures[li];
        for (std::size_t i = 0; i < pictures.size(); ++i) {
            const int col = int(i) % columns, row = int(i) / columns;
            const int x0 = padding + col * cellW, y0 = padding + row * cellH;
            for (int y = 0; y < frameH; ++y)
                std::copy_n(&pictures[i].rgba[std::size_t(y) * frameW * 4], std::size_t(frameW) * 4,
                            &sheetImage.rgba[((std::size_t(y0 + y) * sheetImage.width) + x0) * 4]);
        }
        std::vector<Image>().swap(pictures);
        pngs.push_back(encode_png(sheetImage));
        if (layered) sheetImages.push_back(std::move(sheetImage));
    }
    const int imageW = int(sheetW), imageH = int(sheetH);
    std::vector<bool>
        existed;  // whether a layer's file was already there: a file this call made is taken back if a later one fails
    for (const std::string& lr : layerRels) existed.push_back(stdfs::exists(project_file(projectDir, lr), ec));
    std::vector<std::string> written;
    for (std::size_t li = 0; li < layerList.size(); ++li) {
        std::string err;
        if (tooling_detail::write_file(
                project_write_file(projectDir, layerRels[li]),
                std::string_view(reinterpret_cast<const char*>(pngs[li].data()), pngs[li].size()), &err)) {
            written.push_back(layerRels[li]);
            continue;
        }
        std::vector<std::string> replaced;  // written over an earlier file: that one is gone
        for (std::size_t k = 0; k < written.size(); ++k) {
            if (existed[k]) {
                replaced.push_back(written[k]);
                continue;
            }
            std::error_code rm;
            if (!fs::remove_file(project_write_file(projectDir, written[k]), rm))
                replaced.push_back(written[k]);  // could not be taken back either
        }
        fail("failed",
             err +
                 (replaced.empty()
                      ? " Nothing else was changed: the sheets written before it were removed again, and assets.json "
                        "was not touched."
                      : " assets.json was not touched, but these sheets were already written over the earlier ones: " +
                            join(replaced, ", ") + "."),
             "Check that the folder is writable and the files are not open in another program, then call again with "
             "overwrite: true.");
    }

    // ---- the record: provenance and recipe ----
    const bool ai = tooling_detail::arg_bool(a, "ai", true);
    const std::string author = tooling_detail::arg_string(a, "author", false, ai ? "" : "factoria");
    const std::string license = tooling_detail::arg_string(a, "license", false, "CC0-1.0");
    Json recipeArgs = Json::object({{"path", rel},
                                    {"fps", fps},
                                    {"loop", loop},
                                    {"columns", columns},
                                    {"frameWidth", frameW},
                                    {"frameHeight", frameH},
                                    {"padding", padding},
                                    {"seed", seed},
                                    {"overwrite", true}});
    if (hasSvg)
        recipeArgs["svg"] = svgText;
    else
        recipeArgs["source"] = sourceRel;
    if (hasClips)
        recipeArgs["clips"] = a["clips"];
    else
        recipeArgs["frames"] = total;
    if (a.contains("params") && !a["params"].is_null()) recipeArgs["params"] = params;
    if (pivot) recipeArgs["pivot"] = Json::array({(*pivot)[0], (*pivot)[1]});
    if (a.contains("palette") && !a["palette"].is_null()) recipeArgs["palette"] = a["palette"];
    if (!ramp.empty()) {
        recipeArgs["ramp"] = a["ramp"];
        if (a.contains("rampIndex") && a["ramp"].is_string()) recipeArgs["rampIndex"] = a["rampIndex"];
        if (rampMap) recipeArgs["rampMap"] = true;
    }
    if (layered) recipeArgs["layers"] = Json(layerList);
    if (style != "none") {
        recipeArgs["style"] = style;
        recipeArgs["styleStrength"] = styleStrength;
    }
    if (a.contains("timeLimitMs")) recipeArgs["timeLimitMs"] = timeLimitMs;
    if (!ai) recipeArgs["ai"] = false;
    if (a.contains("author")) recipeArgs["author"] = author;
    if (a.contains("license")) recipeArgs["license"] = license;
    {
        std::vector<std::string>
            read;  // the source first (a module, then what it imported), then the palette image and the ramp's document
        if (module)
            read = module->files();
        else if (!sourceRel.empty())
            read.push_back(sourceRel);
        inputs.insert(inputs.begin(), read.begin(), read.end());
    }
    const Json recipe = make_recipe(projectDir, kCommand, recipeArgs, inputs);

    const std::string what =
        isModule ? "module '" + sourceRel + "'"
                 : (sourceRel.empty() ? std::string("SVG text given to the command") : "SVG '" + sourceRel + "'");
    Json layerInfo = Json::array();
    Json firstProvenance;
    for (std::size_t li = 0; li < layerList.size(); ++li) {
        const std::string& layer = layerList[li];
        Json provenance = Json::object(
            {{"origin", ai ? "generated" : "original"},
             {"ai", ai},
             {"kind", "image"},
             {"provider", "factoria assets.animate_svg"},
             {"license", license},
             {"notes", std::format("{} frames of {}x{} baked from {}{}{}{}{}.", total, frameW, frameH, what,
                                   layer.empty() ? std::string() : ", layer " + layer,
                                   style == "none" ? std::string()
                                                   : std::format(", style {} (strength {})", style, styleStrength),
                                   palette ? ", snapped to a palette" : "",
                                   ramp.empty() ? std::string()
                                                : std::format(", {} colour ramp{}", ramp.size(),
                                                              rampMap ? " mapped by brightness" : ""))},
             {"date", assets::today()},
             {"recipe", recipe}});
        if (!author.empty()) provenance["author"] = author;
        if (!sourceRel.empty()) provenance["source"] = sourceRel;
        if (li == 0) firstProvenance = provenance;
        ProjectRootGuard root(projectDir);
        auto r = assets::update_entry(layerRels[li], [&](Json& e) {
            e.erase("analysis");
            e["sheet"] = sheet;
            e["provenance"] = provenance;
        });
        if (!r.ok()) {
            const std::vector<std::string> recorded(layerRels.begin(), layerRels.begin() + std::ptrdiff_t(li));
            fail("failed",
                 "The sheet" + std::string(layered ? "s were" : " was") +
                     " written, but assets.json was not updated for " + layerRels[li] +
                     (recorded.empty() ? "" : " (it has the entries of " + join(recorded, ", ") + ")") + ": " +
                     r.error().message,
                 r.error().hint);
        }
        if (layered) {
            const char* use =
                layer == "back" ? "a Sprite behind the character: a Sprite.layer lower than the character's"
                : layer == "front"
                    ? "a Sprite in front of the character: a Sprite.layer higher than the character's"
                    : "a Sprite above everything with \"blend\": \"additive\": its colours add to what is under it";
            layerInfo.push_back(Json::object({{"layer", layer}, {"path", layerRels[li]}, {"use", use}}));
        }
    }

    // ---- sheets of an earlier bake of this same effect with other layers ----
    // hit_light.png of a bake with three layers is stale once the effect is baked with two (or none): its recipe would remake the old effect.
    // Only a sheet that this command made for this `path` goes (its recipe says so); a file of the same name made by anything else stays.
    for (const std::string& name : layer_names()) {
        if (std::find(layerList.begin(), layerList.end(), name) != layerList.end()) continue;
        const std::string stale = layer_path(rel, name);
        ProjectRootGuard root(projectDir);
        const Json entry = assets::entry(stale);
        const auto member = [](const Json& obj, const char* key) {
            return obj.is_object() && obj.contains(key) ? obj[key] : Json();
        };
        const Json oldRecipe = member(member(entry, "provenance"), "recipe");
        if (member(oldRecipe, "command") != Json(kCommand) || member(member(oldRecipe, "args"), "path") != Json(rel))
            continue;
        std::error_code rm;
        const std::filesystem::path file = project_write_file(projectDir, stale);
        if (stdfs::exists(file, rm) && !fs::remove_file(file, rm)) {
            warn("The sheet '" + stale + "' is left over from an earlier bake of this effect with the layer \"" + name +
                 "\", and it could not be deleted: " + rm.message() + ". Delete it, or it keeps its recipe.");
            continue;
        }
        if (auto r = assets::update_entry(stale, [](Json& e) { e = Json::object(); }); !r.ok()) {
            warn("The sheet '" + stale + "' (the layer \"" + name +
                 "\" of an earlier bake) was deleted, but its assets.json entry could not be removed: " +
                 r.error().message);
            continue;
        }
        warn("Removed '" + stale + "': the layer \"" + name +
             "\" of an earlier bake of this effect, which this bake does not make.");
    }

    // ---- the prefab that plays the layers together ----
    // Written last: the sheets are encoded, written and recorded by now, and a prefab that cannot be written is the only thing missing.
    std::optional<Json> prefabInfo;
    if (prefabSpec) {
        const std::string clipName = clips[0].name;
        const Json doc = build_animate_prefab(*prefabSpec, layerList, layerRels, clipName);
        std::string err;
        if (!tooling_detail::write_file(project_write_file(projectDir, prefabSpec->rel), dump_scene_json(doc), &err))
            fail("failed",
                 "The sheets were baked and recorded, but the prefab '" + prefabSpec->rel +
                     "' could not be written: " + err,
                 "Check that the folder is writable and the file is not open in another program, then call again with "
                 "overwrite: true and the prefab's overwrite: true (the sheets above are already in place).");
        Json children = Json::array();
        for (const Json& child : doc["entity"]["children"])
            children.push_back(Json::object({{"name", child["name"]},
                                             {"texture", child["components"]["Sprite"]["texture"]},
                                             {"layer", child["components"]["Sprite"]["layer"]},
                                             {"blend", child["components"]["Sprite"].value("blend", "alpha")}}));
        prefabInfo = Json::object({{"path", prefabSpec->rel},
                                   {"name", prefabSpec->name},
                                   {"clip", clipName},
                                   {"size", doc["entity"]["children"][0]["components"]["Sprite"]["size"]},
                                   {"children", children}});
        if (clips.size() > 1)
            warn("The sheet has " + std::to_string(clips.size()) + " clips and the prefab plays the first one, \"" +
                 clipName + "\". Set SpriteAnimator.clip on the children (or call play on each) for another.");
    }

    Json layout = Json::object({{"columns", columns},
                                {"rows", rows},
                                {"frameWidth", frameW},
                                {"frameHeight", frameH},
                                {"padding", padding},
                                {"cellWidth", cellW},
                                {"cellHeight", cellH},
                                {"imageWidth", imageW},
                                {"imageHeight", imageH},
                                {"frames", total},
                                {"clips", sheet.value("clips", Json::array())}});
    if (pivot) layout["pivot"] = sheet["pivot"];
    Json result = Json::object({{"path", layerRels[0]},
                                {"width", imageW},
                                {"height", imageH},
                                {"layout", layout},
                                {"sheet", sheet},
                                {"provenance", firstProvenance}});
    if (layered) result["layers"] = layerInfo;
    if (prefabInfo) result["prefab"] = *prefabInfo;
    if (!ramp.empty()) result["ramp"] = Json(rampHex);
    if (smil && cycle > 0) result["cycleSeconds"] = cycle;
    if (module && !module->logs().empty()) result["console"] = module->logs();
    if (!warnings.empty()) result["warnings"] = warnings;
    if (!layered) {
        result["$image"] = Json::object({{"path", project_file(projectDir, rel).string()}, {"mimeType", "image/png"}});
    } else {
        // the layers stacked as they play: back, front, then the light added, on a dark ground so a glow shows
        Image preview;
        preview.width = sheetImages[0].width;
        preview.height = sheetImages[0].height;
        preview.rgba.assign(sheetImages[0].rgba.size(), 255);
        fill_rect_rgb(preview, 0, 0, preview.width, preview.height, {32, 34, 40});
        for (std::size_t li = 0; li < layerList.size(); ++li) {
            if (layerList[li] != "light") {
                draw_over(preview, sheetImages[li], 0, 0);
                continue;
            }
            for (std::size_t i = 0; i + 3 < preview.rgba.size(); i += 4)
                for (std::size_t k = 0; k < 3; ++k)
                    preview.rgba[i + k] = std::uint8_t(
                        std::min(255, int(preview.rgba[i + k]) +
                                          int(sheetImages[li].rgba[i + k]) * int(sheetImages[li].rgba[i + 3]) / 255));
        }
        result["$image"] = image_member(write_temporary_picture(projectDir, preview, "layers"), true);
    }
    std::vector<std::string> steps = sheet_next_steps(layerRels[0], sheet, hasClips ? clips[0].fps : fps);
    if (prefabInfo) {
        std::vector<std::string> names;
        for (const Json& c : (*prefabInfo)["children"])
            names.push_back(c["name"].get<std::string>() + " at Sprite.layer " + std::to_string(c["layer"].get<int>()));
        steps.push_back("The prefab '" + (*prefabInfo)["path"].get<std::string>() +
                        "' plays the layers together: a parent \"" + (*prefabInfo)["name"].get<std::string>() +
                        "\" with one child per layer (" + join(names, ", ") +
                        "), each a SpriteAnimator on the clip \"" + (*prefabInfo)["clip"].get<std::string>() +
                        "\". Spawn it where the effect happens: feel.do({action: \"spawn\", prefab: \"" +
                        (*prefabInfo)["path"].get<std::string>() +
                        "\", offset: [x, y, 0], lifetime: seconds}) from a script, or scene.spawn {\"prefab\": ...}. "
                        "The character's own Sprite.layer goes between the back and the front one "
                        "(`prefab.layers` sets them). The picture in this result stacks the layers on a dark ground "
                        "(the light added).");
    } else if (layered) {
        steps.push_back(
            "The sheets are one effect: make an entity per layer (children of the same parent, so they move together) "
            "with the SAME SpriteAnimator settings, and "
            "call play on each at the same moment: the grid, the frames, the fps and the pivot are the same, so they "
            "stay in step. The picture in this result stacks the layers on a dark ground (the light added).");
    }
    if (layered && !prefabInfo) {
        for (const Json& l : layerInfo)
            steps.push_back(l["layer"].get<std::string>() + " (" + l["path"].get<std::string>() +
                            "): " + l["use"].get<std::string>() + ".");
        steps.push_back(
            "To get these entities as a prefab in one call, bake again with \"prefab\": \"prefabs/<name>.prefab.json\" "
            "(a parent with one child per layer, the clip and the blend written for you).");
    }
    steps.push_back(
        "Look at the sheet in this result. To change the animation, edit " +
        (isModule ? sourceRel : std::string("the SVG")) +
        " and call again with overwrite: true, "
        "or run assets.regenerate {\"path\":\"" +
        layerRels[0] +
        "\"} (the recipe is in the provenance; {\"stale\":true} makes again every asset whose source changed). "
        "To recolour it without touching the code, change `ramp` and call again.");
    result["nextSteps"] = steps;
    return result;
}

}  // namespace

void register_animate_svg_command(CommandRegistry& registry, const std::string& projectDir) {
    CommandInfo info;
    info.name = kCommand;
    info.category = "assets";
    info.readOnly = false;
    info.summary = "Draw an animation with code (a JS module that returns the SVG of each frame, or an SVG with SMIL) "
                   "and bake it into a sprite sheet PNG plus its `sheet` entry, offline: no provider, no key.";
    info.description =
        "Writes a sprite sheet at `path` (under assets/, ending in .png) and its `sheet` entry in "
        "assets.json in one call, from an animation you write as code. Two ways to draw it. (1) `source`: a "
        "project JavaScript module, e.g. \"art/coin_spin.anim.js\", whose default export is `frame({t, "
        "frame, frames, fps, progress, params, rng, seed, rngFor, clip, sheetFrame, width, height, ramp, "
        "rampAt, layer}) => string`, the SVG of that frame. t is the time in seconds (frame / fps); frame "
        "counts from 0 inside the clip and frames is the clip's length; progress runs 0..1 through the clip "
        "(frame / frames for a looping clip, so the last frame leads into the first; frame / (frames - 1) "
        "for loop false, so the last frame is the end pose); params is the `params` argument (a clip's own "
        "params are merged over it); rng() is a seeded random number in 0..1 for this frame (also "
        "rng.range(a, b), rng.int(n), rng.pick(list), rng.chance(p), rng.gauss()), different on every frame; "
        "rngFor(key) is a random stream that is the SAME on every frame for one key (a sparkle that stays "
        "where it is); clip is the clip name with `clips`." FA_COMMAND_DETAILS
        "The module runs in a sandboxed QuickJS context: the language only (Math, JSON, Array...), no engine "
        "bindings, no DOM, no timers, no files; it may `import` other project files with a relative path "
        "(\"./shapes.js\"). Math.random is a seeded stream and Date a fixed day moved to the frame's time, "
        "so the same module always draws the same frames. Loading and each frame have a time limit "
        "(`timeLimitMs`, 2000 by default) and the context a memory limit. A mistake is reported with the "
        "module's file, line and column, the source line, and the frame being drawn; console.log output "
        "comes back in `console`. (2) `svg` (text) or `source` ending in .svg: one SVG with SMIL animation "
        "(<animate>, <set>, <animateTransform>, <animateMotion> with values, keyTimes, keySplines, begin, "
        "dur, repeatCount, fill=\"freeze\", additive, accumulate and `id.begin` sync-bases), sampled at t = "
        "frame / fps. Without `frames` the sheet takes one pass of the animation (cycle seconds * fps "
        "frames). What is not sampled (event begins such as click, CSS animations, the rest of SMIL) is a "
        "warning that names the element. Every frame is rasterized exactly as assets.rasterize_svg does "
        "(nanosvg: paths, shapes, gradients, strokes, clipPath, mask, pattern; no text or filters) into a "
        "transparent `frameWidth` x `frameHeight` cell (default 64 x 64; the SVG is fitted inside, aspect "
        "kept, centred), then the painterly `style` / `styleStrength` is applied (the style's seed is "
        "`seed`, the same for every frame, so the paper texture stays put while the drawing moves) and the "
        "pixels are snapped to `palette` (a list of \"#rrggbb\" or an image of the project). The frames go "
        "row by row in a grid of `columns` (default ceil(sqrt(frames))) with a transparent gutter of "
        "`padding` pixels around every cell (cell i starts at x = padding + column * (frameWidth + 2 * "
        "padding)). `pivot` ([x, y] in 0..1 from the top-left, default the centre) is recorded in the sheet "
        "entry. `clips` makes several named clips from one module: [{name, frames, fps, loop, params, "
        "pivot}], laid out one after another in the sheet (do not also give `frames`); the module receives "
        "`clip` and draws that animation; each clip becomes a clip of the sheet entry with its fps and loop. "
        "Without `clips` the sheet entry has one clip named like the file, so fps and loop are kept. "
        "RECOLOUR WITHOUT TOUCHING THE CODE: `ramp` is the effect's colours from dark to bright (a list of 2 "
        "to 32 \"#rrggbb\", or the path of an image document with `ramps` and `rampIndex`, the ramps of "
        "image.palette). A module receives them as `ramp` (the list) and `rampAt(u)`, the colour at u from 0 "
        "(dark) to 1 (bright), blended between neighbours, so `fill='${rampAt(0.8)}'` is recoloured by "
        "changing the `ramp` argument; a module that never names `ramp` gets a warning. `rampMap: true` "
        "instead recolours the finished frames by brightness (the darkest pixel takes the first colour, the "
        "brightest the last, alpha kept), which also works for a SMIL SVG and for a module that draws in "
        "greys. LAYERS: `layers` is a list from back, front and light (module only). Each layer is baked as "
        "its own sheet next to `path` (assets/art/hit.png gives hit_back.png, hit_front.png, hit_light.png), "
        "from one module that receives `layer` and returns the SVG of that layer (an empty <svg/> is a layer "
        "idle in that frame). The sheets have the same grid, frames, fps, clips, pivot and padding, so they "
        "stay in step when each plays on its own entity: `back` goes behind the character (a lower "
        "Sprite.layer), `front` in front of it (a higher one) and `light` is an additive pass (a Sprite with "
        "blend additive, its colours add to what is under it: draw soft bright glows). Every layer of a "
        "frame draws from the same random stream. The result lists the layers and returns them stacked on a "
        "dark ground. `prefab` (with `layers`) also writes the entities that play them together: a parent "
        "with one child per layer, each a Sprite on its sheet (back below, front above, light additive) and "
        "a SpriteAnimator on the sheet's first clip, so the effect is one call; see its description for the "
        "options, and it is never written over an existing prefab unless `prefab.overwrite` is true. A "
        "module that never reads `layer` gets a warning (every layer would be the same drawing). The layers "
        "of a call are held in memory together (their frames and sheets, at most 1024 MB): a bake over that "
        "is refused before drawing, so bake fewer layers per call. All sheets are encoded before the first "
        "is written; if a write fails, the sheets this call made are removed again. Sheets of an earlier "
        "bake of the same `path` with other layers (hit_light.png after baking only back and front) are "
        "deleted with their entries when this command made them. The result returns the sheet as an image, "
        "the layout (columns, rows, cell size, clips) and warnings: frames that draw nothing, shapes "
        "touching the edge of the cell, a loop whose last frame jumps from the first (or repeats it), SMIL "
        "not sampled, a sheet over 4096 px, and, when factoria.json lists android or ios, a sheet whose "
        "width or height is not a multiple of 4 (GPU compression needs it; the warning names the `padding` "
        "or the frame size that gives one). Provenance (origin generated, ai true: the calling agent wrote "
        "the code; pass ai: false with author and license for art a person drew) carries a recipe (this "
        "command, its arguments, the module and the files it imported with their SHA-256), so the sheet can "
        "be made again, byte for byte. Use this for motion that follows rules (spin, bob, pulse, sparkle, "
        "flame, waves, loaders); for an engine-drawn entity use assets.bake_sheet, for painted "
        "frame-by-frame art ask an image provider. Example: "
        "{\"path\":\"assets/art/coin_spin.png\",\"source\":\"art/"
        "coin_spin.anim.js\",\"frames\":8,\"fps\":10,\"frameWidth\":64,\"frameHeight\":64,\"padding\":1} "
        "with art/coin_spin.anim.js = \"export default function frame({progress}) { const w = "
        "Math.abs(Math.cos(progress * Math.PI * 2)) * 40; return `<svg xmlns='http://www.w3.org/2000/svg' "
        "viewBox='0 0 100 100'><ellipse cx='50' cy='50' rx='${w + 4}' ry='42' fill='#e8c66a' "
        "stroke='#8b6a1e' stroke-width='4'/></svg>`; }\"";
    const Json pivotSchema =
        Json::object({{"type", "array"},
                      {"items", Json::object({{"type", "number"}, {"minimum", 0}, {"maximum", 1}})},
                      {"minItems", 2},
                      {"maxItems", 2}});
    info.inputSchema = Json::object(
        {{"type", "object"},
         {"required", Json::array({"path"})},
         {"additionalProperties", false},
         {"properties",
          Json::object(
              {{"path",
                Json::object(
                    {{"type", "string"},
                     {"description",
                      "Where to write the sheet, project-relative, under assets/ and ending in .png. With `layers` it "
                      "is the base name: hit.png gives hit_back.png, hit_front.png and hit_light.png."}})},
               {"source",
                Json::object(
                    {{"type", "string"},
                     {"description",
                      "A project-relative JavaScript module whose default export draws one frame "
                      "(\"art/coin_spin.anim.js\"), or an .svg file with SMIL animation. Give this or `svg`."}})},
               {"svg", Json::object(
                           {{"type", "string"},
                            {"description",
                             "One SVG with SMIL animation as text, sampled at every frame. Give this or `source`."}})},
               {"frames",
                Json::object({{"type", "integer"},
                              {"minimum", 1},
                              {"maximum", kMaxFrames},
                              {"description", "Number of frames. Required with a module; with SMIL the default is one "
                                              "pass of the animation. Not with `clips` (they give their own)."}})},
               {"fps", Json::object(
                           {{"type", "number"},
                            {"exclusiveMinimum", 0},
                            {"maximum", 240},
                            {"default", 12},
                            {"description", "Frames per second: t = frame / fps, and the fps of the sheet's clip."}})},
               {"loop",
                Json::object({{"type", "boolean"},
                              {"default", true},
                              {"description", "Whether the clip repeats. Decides `progress` (frame / frames when true, "
                                              "frame / (frames - 1) when false) and the loop-jump warning."}})},
               {"columns", Json::object({{"type", "integer"},
                                         {"minimum", 1},
                                         {"description", "Frames per row of the sheet. Default ceil(sqrt(frames))."}})},
               {"frameWidth",
                Json::object({{"type", "integer"},
                              {"minimum", 1},
                              {"maximum", kMaxCell},
                              {"default", 64},
                              {"description",
                               "Width of one frame in pixels; the SVG is fitted inside, aspect kept, centred."}})},
               {"frameHeight", Json::object({{"type", "integer"},
                                             {"minimum", 1},
                                             {"maximum", kMaxCell},
                                             {"description", "Height of one frame in pixels. Default: frameWidth."}})},
               {"params", Json::object({{"type", "object"},
                                        {"description", "Passed to the module as `params` (colours, counts, "
                                                        "amplitudes), so one module serves several sheets."}})},
               {"seed", Json::object({{"type", "integer"},
                                      {"default", 0},
                                      {"description", "Seeds rng, Math.random and rngFor of the module, and the "
                                                      "painterly style. The same seed always gives the same sheet."}})},
               {"clips",
                Json::object(
                    {{"type", "array"},
                     {"description", "Several named clips from one module, laid out one after another: [{name, frames, "
                                     "fps, loop, params, pivot}]. Module only."},
                     {"items",
                      Json::object(
                          {{"type", "object"},
                           {"additionalProperties", false},
                           {"required", Json::array({"name", "frames"})},
                           {"properties",
                            Json::object(
                                {{"name",
                                  Json::object({{"type", "string"},
                                                {"description", "The clip's name; the module reads it as `clip`."}})},
                                 {"frames", Json::object({{"type", "integer"},
                                                          {"minimum", 1},
                                                          {"maximum", kMaxFrames},
                                                          {"description", "Frames of this clip."}})},
                                 {"fps",
                                  Json::object({{"type", "number"},
                                                {"description",
                                                 "Frames per second of this clip. Default: the top-level fps."}})},
                                 {"loop", Json::object({{"type", "boolean"},
                                                        {"description",
                                                         "Whether this clip repeats. Default: the top-level loop."}})},
                                 {"params",
                                  Json::object({{"type", "object"},
                                                {"description", "Merged over the top-level params for this clip."}})},
                                 {"pivot", pivotSchema}})}})}})},
               {"pivot",
                Json::object({{"type", "array"},
                              {"items", Json::object({{"type", "number"}, {"minimum", 0}, {"maximum", 1}})},
                              {"minItems", 2},
                              {"maxItems", 2},
                              {"description", "[x, y] in 0..1 from the top-left of the frame: the point that stays "
                                              "still. Recorded in the sheet entry. Default [0.5, 0.5]."}})},
               {"palette",
                Json::object(
                    {{"description",
                      "Snap every pixel to these colours: a list of \"#rrggbb\" strings, or the project-relative path "
                      "of an image whose distinct opaque colours are the palette (at most 256). Alpha is kept."}})},
               {"ramp", Json::object(
                            {{"description",
                              "The effect's colours from dark to bright: a list of 2 to 32 \"#rrggbb\" strings, or the "
                              "project path of an image document (*.image.json) that declares `ramps` (pick one with "
                              "rampIndex). A module reads them as `ramp` and `rampAt(u)`; with rampMap the frames are "
                              "recoloured by brightness. Change it and bake again to recolour the effect."}})},
               {"rampIndex", Json::object({{"type", "integer"},
                                           {"minimum", 0},
                                           {"description", "Which ramp of the image document named by `ramp` (0 is the "
                                                           "first one image.palette lists). Only with a document."}})},
               {"rampMap",
                Json::object(
                    {{"type", "boolean"},
                     {"default", false},
                     {"description",
                      "Recolour the finished frames by brightness with `ramp` (dark pixels take its first colour, "
                      "bright ones its last; alpha kept). Needed for a SMIL SVG; a module may use rampAt instead."}})},
               {"layers",
                Json::object(
                    {{"type", "array"},
                     {"items", Json::object({{"type", "string"}, {"enum", layer_names()}})},
                     {"minItems", 1},
                     {"maxItems", 3},
                     {"description",
                      "Bake one sheet per layer (back, front, light), module only: the module receives `layer`. The "
                      "files are <path>_<layer>.png with the same grid, fps, clips and pivot. back is drawn behind the "
                      "character, front in front of it, light is an additive glow."}})},
               {"prefab",
                Json::object({{"description",
                               "Needs `layers`. Also write the prefab that plays the layers together: the path of a "
                               ".prefab.json (\"prefabs/coin_sparkle.prefab.json\"), or an object {path, name, tags, "
                               "size, layers, pixelArt, overwrite}. "
                               "It is a parent entity (name: `name`, default made from the file name; `tags`) with one "
                               "child per layer (Back, Front, Light), each a Sprite on that layer's sheet "
                               "(`size` [w, h] in world units, default one frame in pixels; `layers` {back, front, "
                               "light} are the Sprite.layer numbers, default -1, 1 and 2, so put the character's layer "
                               "between back and front; "
                               "`pixelArt` default false) with a SpriteAnimator on the sheet's first clip; the light "
                               "child is blend additive. The prefab is written after the sheets. "
                               "An existing prefab is never replaced unless the object has overwrite: true (the call "
                               "fails before baking anything): it may hold changes made by hand, and the command's "
                               "`overwrite` is about the sheets. "
                               "The prefab is not part of the recipe: assets.regenerate remakes the sheets and leaves "
                               "the prefab as it is."}})},
               {"style",
                Json::object(
                    {{"type", "string"},
                     {"enum", image_style_names()},
                     {"description",
                      "Default none. The painterly look of assets.rasterize_svg applied to every frame (watercolor, "
                      "ink, inkwash, paper). The same seed for all frames, so the texture does not boil."}})},
               {"styleStrength",
                Json::object(
                    {{"type", "number"},
                     {"minimum", 0},
                     {"maximum", 1},
                     {"description", "How strong the `style` is, 0 to 1 (default 1). Ignored without a `style`."}})},
               {"padding",
                Json::object({{"type", "integer"},
                              {"minimum", 0},
                              {"maximum", 64},
                              {"default", 0},
                              {"description", "Transparent pixels around every cell: 1 or 2 keeps filtered frames from "
                                              "bleeding into each other. Recorded in the sheet entry."}})},
               {"timeLimitMs",
                Json::object({{"type", "integer"},
                              {"minimum", 10},
                              {"maximum", 60000},
                              {"default", 2000},
                              {"description", "Milliseconds the module may take to load and, separately, to draw each "
                                              "frame; over it the call fails naming the frame."}})},
               {"overwrite", Json::object({{"type", "boolean"},
                                           {"default", false},
                                           {"description", "Replace the sheet (every layer's sheet) when it already "
                                                           "exists. It does not cover the prefab: see `prefab`."}})},
               {"ai",
                Json::object({{"type", "boolean"},
                              {"default", true},
                              {"description",
                               "Whether the code was written by an AI (the default, since the caller is an agent). Set "
                               "false for art a person made; it then counts as original work in the AI disclosure."}})},
               {"author",
                Json::object({{"type", "string"}, {"description", "Who gets the credit in the provenance record."}})},
               {"license", Json::object({{"type", "string"},
                                         {"default", "CC0-1.0"},
                                         {"description", "License of the sheet for the provenance record."}})}})}});
    mark_paths(info.inputSchema, "write", {"path"});
    mark_paths(info.inputSchema, "read", {"source"});
    registry.add(info, [projectDir](const Json& args) { return animate(projectDir, args); });
    // Capabilities (capability.h): the sheets (and the prefab) are written in the project; the game is not touched.
    declare_command_capabilities(registry, {{kCommand, capability_sets::writes_project()}});
}

}  // namespace fa::assets_detail
