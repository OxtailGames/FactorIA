// *.image.json -> ImageDocument, with the checks and the teaching errors (docs/IMAGES.md, schemas/image.schema.json).
// Every problem found is collected with its JSON pointer; the first one becomes the error.
#include <algorithm>
#include <cmath>
#include <filesystem>
#include <format>

#include "assets_internal.h"
#include "fa/core/strings.h"
#include "fa/render/builtin_fonts.h"
#include "fa/tooling/image_tileset.h"
#include "fa/tooling/project_fs.h"
#include "fa/tooling/style_guide.h"
#include "image_doc_internal.h"
#include "util.h"

namespace fa {

namespace {

namespace stdfs = std::filesystem;
using imgdoc::Polyline;

struct Parser {
    const std::string& file;
    const std::string& projectDir;
    std::vector<ImageIssue>& issues;
    int canvasW = 0, canvasH = 0;
    PixelPalette palette;  // the document's palette, parsed before the layers
    bool paletteDeferred =
        false;  // the style palette is wanted but there is no project to read it from: indices are not range-checked
    int frameCount = 1;  // frames of the document, known before the layers are read

    void add(const std::string& pointer, std::string message, std::string hint) {
        issues.push_back({pointer, std::move(message), std::move(hint)});
    }

    static std::string tok(const std::string& key) { return tooling_detail::escape_token(key); }

    void unknown_keys(const Json& obj, const std::string& pointer, const std::vector<std::string>& allowed,
                      const std::string& what) {
        for (auto it = obj.begin(); it != obj.end(); ++it) {
            if (std::find(allowed.begin(), allowed.end(), it.key()) != allowed.end()) continue;
            add(pointer + "/" + tok(it.key()), "Unknown key '" + it.key() + "' in " + what + ".",
                did_you_mean(it.key(), allowed) + " Keys: " + join(allowed, ", ") + ".");
        }
    }

    // Typed members. Each returns false (and records the problem) when present but wrong; `out` is left alone when absent.
    bool get_int(const Json& obj, const std::string& pointer, const char* key, int& out, int lo, int hi,
                 const std::string& hint) {
        auto it = obj.find(key);
        if (it == obj.end()) return true;
        const bool ok = it->is_number_integer() && it->get<long long>() >= lo && it->get<long long>() <= hi;
        if (!ok) {
            add(pointer + "/" + key,
                std::format("`{}` must be a whole number from {} to {}, got {}.", key, lo, hi,
                            describe_json_value(*it)),
                hint);
            return false;
        }
        out = int(it->get<long long>());
        return true;
    }
    bool get_number(const Json& obj, const std::string& pointer, const char* key, float& out, double lo, double hi,
                    const std::string& hint) {
        auto it = obj.find(key);
        if (it == obj.end()) return true;
        const bool ok = it->is_number() && it->get<double>() >= lo && it->get<double>() <= hi;
        if (!ok) {
            add(pointer + "/" + key,
                std::format("`{}` must be a number from {} to {}, got {}.", key, lo, hi, describe_json_value(*it)),
                hint);
            return false;
        }
        out = it->get<float>();
        return true;
    }
    bool get_bool(const Json& obj, const std::string& pointer, const char* key, bool& out) {
        auto it = obj.find(key);
        if (it == obj.end()) return true;
        if (!it->is_boolean()) {
            add(pointer + "/" + key, std::format("`{}` must be true or false, got {}.", key, describe_json_value(*it)),
                "Write " + std::string(key) + ": true.");
            return false;
        }
        out = it->get<bool>();
        return true;
    }
    bool get_string(const Json& obj, const std::string& pointer, const char* key, std::string& out,
                    bool allowEmpty = false) {
        auto it = obj.find(key);
        if (it == obj.end()) return true;
        if (!it->is_string() || (!allowEmpty && it->get<std::string>().empty())) {
            add(pointer + "/" + key,
                std::format("`{}` must be {}string, got {}.", key, allowEmpty ? "a " : "a non-empty ",
                            describe_json_value(*it)),
                "Write it as text, for example \"assets/art/hero.png\".");
            return false;
        }
        out = it->get<std::string>();
        return true;
    }
    bool get_color(const Json& obj, const std::string& pointer, const char* key, Color& out) {
        auto it = obj.find(key);
        if (it == obj.end()) return true;
        std::string err;
        if (!json_to(*it, out, &err)) {
            add(pointer + "/" + key, std::format("`{}`: {}", key, err),
                "Colours are \"#rrggbb\", \"#rrggbbaa\", a name like \"white\" or [r, g, b(, a)] in 0..1.");
            return false;
        }
        return true;
    }

    // A project file named by a layer: normalized, must exist when the project is known.
    bool project_file(const std::string& pointer, const std::string& key, std::string& value,
                      const std::vector<std::string>& extensions, const char* what) {
        auto norm = fs::normalize_checked(value);
        if (!norm.ok() || norm->empty()) {
            add(pointer + "/" + key,
                std::format("'{}' is not a project path: {}", value, norm.ok() ? "it is empty" : norm.error().message),
                "Use a project-relative path with forward slashes, such as \"assets/art/hero.png\".");
            return false;
        }
        const std::string ext = to_lower(fs::extension(*norm));
        if (std::find(extensions.begin(), extensions.end(), ext) == extensions.end()) {
            add(pointer + "/" + key,
                std::format("'{}' is not {} (it must end in {}).", *norm, what, join(extensions, " or ")),
                "Name " + std::string(what) + " of the project.");
            return false;
        }
        value = *norm;
        if (projectDir.empty()) return true;
        std::error_code ec;
        auto path = resolve_project_path(projectDir, value);
        if (!path.ok() || !stdfs::is_regular_file(*path, ec)) {
            add(pointer + "/" + key, std::format("The file '{}' does not exist in the project.", value),
                "Check the path (it is relative to the project folder), or make the file first: draw it with "
                "assets.rasterize_svg or assets.generate_texture, or bring it in with assets.import.");
            return false;
        }
        return true;
    }

    void parse_masks(const Json& layer, const std::string& pointer, ImageLayer& out) {
        auto it = layer.find("masks");
        if (it == layer.end()) return;
        if (!it->is_array()) {
            add(pointer + "/masks", "`masks` must be a list, got " + describe_json_value(*it) + ".",
                "Write masks: [{\"type\": \"ellipse\", \"x\": 0, \"y\": 0, \"width\": 64, \"height\": 64}].");
            return;
        }
        static const std::vector<std::string> types = {"pixels", "rect", "ellipse", "polygon", "path"};
        for (std::size_t i = 0; i < it->size(); ++i) {
            const Json& m = (*it)[i];
            ImageMask mask;
            mask.pointer = pointer + "/masks/" + std::to_string(i);
            if (!m.is_object()) {
                add(mask.pointer, "A mask must be an object, got " + describe_json_value(m) + ".",
                    "Write {\"type\": \"rect\", \"x\": 0, \"y\": 0, \"width\": 32, \"height\": 32}. Types: " +
                        join(types, ", ") + ".");
                continue;
            }
            std::string type;
            if (!m.contains("type") || !m["type"].is_string()) {
                add(mask.pointer + "/type", "A mask needs a string `type`.", "Types: " + join(types, ", ") + ".");
                continue;
            }
            type = m["type"].get<std::string>();
            const auto found = std::find(types.begin(), types.end(), type);
            if (found == types.end()) {
                add(mask.pointer + "/type", "Unknown mask type '" + type + "'.",
                    did_you_mean(type, types) + " Types: " + join(types, ", ") + ".");
                continue;
            }
            mask.type = ImageMask::Type(found - types.begin());
            std::vector<std::string> allowed = {"type", "invert", "feather"};
            auto extend = [&](std::initializer_list<const char*> more) {
                allowed.insert(allowed.end(), more.begin(), more.end());
            };
            switch (mask.type) {
                case ImageMask::Type::Pixels: extend({"source", "x", "y"}); break;
                case ImageMask::Type::Rect:
                case ImageMask::Type::Ellipse: extend({"x", "y", "width", "height"}); break;
                case ImageMask::Type::Polygon: extend({"points"}); break;
                case ImageMask::Type::Path: extend({"path"}); break;
            }
            unknown_keys(m, mask.pointer, allowed, type + " mask");
            get_bool(m, mask.pointer, "invert", mask.invert);
            get_number(m, mask.pointer, "feather", mask.feather, 0, 512,
                       "Feather is the width of the soft edge in pixels; 0 is a hard edge.");
            const std::string intHint = "Positions and sizes are whole pixels, in the layer's own coordinates.";
            switch (mask.type) {
                case ImageMask::Type::Pixels:
                    if (!m.contains("source"))
                        add(mask.pointer, "A pixels mask needs `source`, a PNG: white shows the layer, black hides it.",
                            "Example: {\"type\": \"pixels\", \"source\": \"assets/art/hero_mask.png\"}.");
                    else if (get_string(m, mask.pointer, "source", mask.source))
                        project_file(mask.pointer, "source", mask.source, {".png"}, "a PNG");
                    get_int(m, mask.pointer, "x", mask.x, -100000, 100000, intHint);
                    get_int(m, mask.pointer, "y", mask.y, -100000, 100000, intHint);
                    break;
                case ImageMask::Type::Rect:
                case ImageMask::Type::Ellipse:
                    get_int(m, mask.pointer, "x", mask.x, -100000, 100000, intHint);
                    get_int(m, mask.pointer, "y", mask.y, -100000, 100000, intHint);
                    for (const char* key : {"width", "height"}) {
                        if (!m.contains(key))
                            add(mask.pointer, std::string("A ") + type + " mask needs `" + key + "` (pixels).",
                                "Example: {\"type\": \"" + type +
                                    "\", \"x\": 8, \"y\": 8, \"width\": 48, \"height\": 48}.");
                    }
                    get_int(m, mask.pointer, "width", mask.width, 1, kImageDocMaxSide * 4,
                            "Width and height are whole pixels, at least 1.");
                    get_int(m, mask.pointer, "height", mask.height, 1, kImageDocMaxSide * 4,
                            "Width and height are whole pixels, at least 1.");
                    break;
                case ImageMask::Type::Polygon: {
                    auto pts = m.find("points");
                    if (pts == m.end() || !pts->is_array() || pts->size() < 3) {
                        add(mask.pointer + "/points",
                            "A polygon mask needs `points`: a list of at least three [x, y] corners.",
                            "Example: \"points\": [[0, 0], [64, 0], [32, 48]].");
                        break;
                    }
                    for (std::size_t k = 0; k < pts->size(); ++k) {
                        Vec2 v;
                        std::string err;
                        if (!(*pts)[k].is_array() || !json_to((*pts)[k], v, &err))
                            add(mask.pointer + "/points/" + std::to_string(k),
                                "A corner must be [x, y], got " + describe_json_value((*pts)[k]) + ".",
                                "Example: [32, 48].");
                        else
                            mask.points.push_back(v);
                    }
                    break;
                }
                case ImageMask::Type::Path: {
                    if (!m.contains("path")) {
                        add(mask.pointer, "A path mask needs `path`: SVG path data.",
                            "Example: {\"type\": \"path\", \"path\": \"M10 10 L90 10 L50 80 Z\"}.");
                        break;
                    }
                    if (!get_string(m, mask.pointer, "path", mask.path)) break;
                    std::vector<Polyline> shapes;
                    std::string err;
                    if (!imgdoc::parse_svg_path(mask.path, shapes, err))
                        add(mask.pointer + "/path", "The path data is not valid: " + err + ".",
                            "Write SVG path data such as \"M10 10 L90 10 L50 80 Z\" (M, L, H, V, C, S, Q, T, A, Z, "
                            "absolute or relative).");
                    break;
                }
            }
            out.masks.push_back(std::move(mask));
        }
    }

    void parse_ops(const Json& layer, const std::string& pointer, const char* key, bool effect,
                   std::vector<Json>& out) {
        auto it = layer.find(key);
        if (it == layer.end()) return;
        if (!it->is_array()) {
            add(pointer + "/" + key, std::string("`") + key + "` must be a list, got " + describe_json_value(*it) + ".",
                std::string("Write ") + key + ": [{\"type\": \"" + (effect ? "colorOverlay" : "invert") + "\"}].");
            return;
        }
        for (std::size_t i = 0; i < it->size(); ++i) {
            imgdoc::check_op(effect, (*it)[i], pointer + "/" + key + "/" + std::to_string(i), issues, projectDir);
            out.push_back((*it)[i]);
        }
    }

    void parse_gradient(const Json& layer, const std::string& pointer, ImageLayer& out) {
        auto it = layer.find("gradient");
        const std::string gp = pointer + "/gradient";
        if (it == layer.end() || !it->is_object()) {
            add(it == layer.end() ? pointer : gp, "A gradient layer needs a `gradient` object.",
                "Example: \"gradient\": {\"type\": \"linear\", \"angle\": 90, \"stops\": [{\"at\": 0, \"color\": "
                "\"#000000\"}, {\"at\": 1, \"color\": \"#ffffff\"}]}.");
            return;
        }
        const Json& g = *it;
        unknown_keys(g, gp, {"type", "angle", "center", "radius", "stops"}, "a gradient");
        std::string type = "linear";
        get_string(g, gp, "type", type);
        if (type != "linear" && type != "radial")
            add(gp + "/type", "Unknown gradient type '" + type + "'.",
                did_you_mean(type, std::vector<std::string>{"linear", "radial"}) + " Types: linear, radial.");
        out.gradient.radial = type == "radial";
        get_number(g, gp, "angle", out.gradient.angle, -3600, 3600,
                   "Degrees: 0 runs from the top to the bottom, 90 from the left to the right.");
        get_number(g, gp, "radius", out.gradient.radius, 0.001, 100,
                   "1 reaches the corners of the layer's box; 0.5 reaches the middle of its sides.");
        if (g.contains("center")) {
            std::string err;
            if (!g["center"].is_array() || !json_to(g["center"], out.gradient.center, &err))
                add(gp + "/center",
                    "`center` must be [x, y] as fractions of the layer's box, got " + describe_json_value(g["center"]) +
                        ".",
                    "Example: \"center\": [0.5, 0.5].");
        }
        auto stops = g.find("stops");
        if (stops == g.end() || !stops->is_array() || stops->size() < 2) {
            add(gp + "/stops", "A gradient needs `stops`: a list of at least two {\"at\", \"color\"} entries.",
                "Example: \"stops\": [{\"at\": 0, \"color\": \"#ff8800\"}, {\"at\": 1, \"color\": \"#220044\"}].");
            return;
        }
        float prev = 0;
        for (std::size_t i = 0; i < stops->size(); ++i) {
            const Json& s = (*stops)[i];
            const std::string sp = gp + "/stops/" + std::to_string(i);
            if (!s.is_object()) {
                add(sp, "A stop must be an object {\"at\", \"color\"}, got " + describe_json_value(s) + ".",
                    "Example: {\"at\": 0.5, \"color\": \"#ffffff\"}.");
                continue;
            }
            unknown_keys(s, sp, {"at", "color"}, "a gradient stop");
            ImageGradientStop stop;
            if (!s.contains("at") || !s.contains("color")) {
                add(sp, "A stop needs both `at` (0..1) and `color`.",
                    "Example: {\"at\": 0.5, \"color\": \"#ffffff\"}.");
                continue;
            }
            if (!get_number(s, sp, "at", stop.at, 0, 1,
                            "`at` is the place along the gradient, from 0 (start) to 1 (end).") ||
                !get_color(s, sp, "color", stop.color))
                continue;
            if (stop.at < prev)
                add(sp + "/at",
                    std::format("The stops must go from small to large `at`, and {} comes after {}.", stop.at, prev),
                    "Put the stops in order of `at`.");
            prev = std::max(prev, stop.at);
            out.gradient.stops.push_back(stop);
        }
    }

    void parse_font(const Json& layer, const std::string& pointer, ImageLayer& out) {
        if (!get_string(layer, pointer, "font", out.font, true) || out.font.empty()) return;
        if (starts_with(out.font, "builtin")) {
            if (!find_builtin_font(out.font))
                add(pointer + "/font", "Unknown built-in font '" + out.font + "'.",
                    "Fonts: " + builtin_font_list() + ".");
            return;
        }
        std::string value = out.font;
        if (project_file(pointer, "font", value, {".ttf", ".otf", ".ttc"}, "a font file")) out.font = value;
    }

    // ---- palette and indexed layers --------------------------------------------------------------------------------------------

    static bool has_indexed_layer(const Json& layers) {
        if (!layers.is_array()) return false;
        for (const Json& l : layers) {
            if (!l.is_object()) continue;
            if (l.value("kind", std::string()) == "indexed") return true;
            if (l.value("kind", std::string()) == "tileset" && l.contains("parts") &&
                l["parts"].dump().find("\"rows\"") != std::string::npos)
                return true;
            if (l.contains("layers") && has_indexed_layer(l["layers"])) return true;
        }
        return false;
    }

    void parse_palette(const Json& json) {
        const bool wanted = has_indexed_layer(json.contains("layers") ? json["layers"] : Json());
        const std::string paletteHint =
            "Example: \"palette\": [\"#1a1c2c\", {\"name\": \"skin\", \"color\": \"#e0a070\"}, \"#ffffff\"], or "
            "\"palette\": \"style\" for the style palette of assets.json.";
        auto from_style = [&](const std::string& pointer) {
            if (projectDir.empty()) {
                paletteDeferred = true;
                return;
            }
            auto style = load_style_guide(projectDir);
            if (!style.guide.palette || style.guide.palette->empty()) {
                add(pointer, "The document uses the style palette, but assets.json has no `style.palette`.",
                    "Write the colours in the document (\"palette\": [\"#000000\", \"#ffffff\", ...]) or set "
                    "style.palette in assets.json (docs/ASSETS.md, \"House style\").");
                return;
            }
            if (int(style.guide.palette->size()) > kMaxIndexedColours) {
                add(pointer,
                    std::format("The style palette has {} colours; an indexed picture holds at most {}.",
                                style.guide.palette->size(), kMaxIndexedColours),
                    "List the colours the picture uses in the document's `palette` instead.");
                return;
            }
            for (const auto& c : *style.guide.palette) palette.entries.push_back({"", c});
        };
        auto it = json.find("palette");
        if (it == json.end()) {
            if (wanted) from_style("/palette");
        } else if (it->is_string()) {
            if (it->get<std::string>() != "style")
                add("/palette", "Unknown palette '" + it->get<std::string>() + "'.",
                    did_you_mean(it->get<std::string>(), std::vector<std::string>{"style"}) + " " + paletteHint);
            else
                from_style("/palette");
        } else if (!it->is_array() || it->empty()) {
            add("/palette",
                "`palette` must be \"style\" or a non-empty list of colours, got " + describe_json_value(*it) + ".",
                paletteHint);
        } else if (int(it->size()) > kMaxIndexedColours) {
            add("/palette",
                std::format("A palette holds at most {} colours (one character each), got {}.", kMaxIndexedColours,
                            it->size()),
                "Keep the colours the picture needs.");
        } else {
            for (std::size_t i = 0; i < it->size(); ++i) {
                const Json& e = (*it)[i];
                const std::string ep = "/palette/" + std::to_string(i);
                PixelPalette::Entry entry;
                const Json* colour = &e;
                if (e.is_object()) {
                    unknown_keys(e, ep, {"name", "color"}, "a palette entry");
                    if (!e.contains("color")) {
                        add(ep, "A palette entry needs a `color`.", paletteHint);
                        continue;
                    }
                    colour = &e["color"];
                    if (e.contains("name")) {
                        if (!e["name"].is_string() || e["name"].get<std::string>().empty() ||
                            e["name"].get<std::string>() == "." || e["name"].get<std::string>() == "transparent" ||
                            e["name"].get<std::string>() == "none") {
                            add(ep + "/name",
                                "A colour name is a non-empty string (not \".\", \"transparent\" or \"none\", which "
                                "mean transparent), got " +
                                    describe_json_value(e["name"]) + ".",
                                paletteHint);
                            continue;
                        }
                        entry.name = e["name"].get<std::string>();
                        if (palette.find_name(entry.name)) {
                            add(ep + "/name",
                                "The name '" + entry.name +
                                    "' is used by an earlier colour (names are compared ignoring case).",
                                "Give every colour its own name.");
                            continue;
                        }
                    }
                }
                Color c;
                std::string err;
                if (!json_to(*colour, c, &err)) {
                    add(e.is_object() ? ep + "/color" : ep, "Palette colour: " + err,
                        "Colours are \"#rrggbb\", a CSS name or [r, g, b] in 0..1.");
                    continue;
                }
                if (c.a < 0.999f) {
                    add(e.is_object() ? ep + "/color" : ep,
                        "A palette colour must be opaque; transparency is the character '.' (null in commands).",
                        "Remove the alpha of the colour.");
                    continue;
                }
                auto b = [](float v) { return std::uint8_t(std::lround(std::clamp(v, 0.0f, 1.0f) * 255.0f)); };
                entry.rgb = {b(c.r), b(c.g), b(c.b)};
                if (auto same = palette.find_rgb(entry.rgb[0], entry.rgb[1], entry.rgb[2])) {
                    add(e.is_object() ? ep + "/color" : ep,
                        std::format("This colour is already palette entry {}.", *same),
                        "Remove the duplicate: every palette colour must be different, so a colour maps to one index.");
                    continue;
                }
                palette.entries.push_back(std::move(entry));
            }
            if (issues_at("/palette"))
                palette.entries.clear(),
                    paletteDeferred = true;  // the layers' indices cannot be judged against a broken palette
        }
        // ramps
        if (auto rit = json.find("ramps"); rit != json.end()) {
            const std::string rampHint =
                "Example: \"ramps\": [[\"#1a1c2c\", \"#5d275d\", \"#b13e53\"], [\"skin-dark\", \"skin\", "
                "\"skin-light\"]]: each ramp lists palette colours from the darkest to the lightest.";
            if (!rit->is_array()) {
                add("/ramps", "`ramps` must be a list of ramps, got " + describe_json_value(*rit) + ".", rampHint);
            } else if (palette.empty()) {
                if (!paletteDeferred)
                    add("/ramps", "`ramps` need a palette to refer to.",
                        "Add `palette` first (a list of colours, or \"style\").");
            } else {
                std::vector<char> used(std::size_t(palette.size()), 0);
                for (std::size_t r = 0; r < rit->size(); ++r) {
                    const Json& ramp = (*rit)[r];
                    const std::string rp = "/ramps/" + std::to_string(r);
                    if (!ramp.is_array() || ramp.size() < 2) {
                        add(rp,
                            "A ramp is a list of at least two palette colours, darkest first, got " +
                                describe_json_value(ramp) + ".",
                            rampHint);
                        continue;
                    }
                    std::vector<int> indices;
                    for (std::size_t k = 0; k < ramp.size(); ++k) {
                        auto found = pixel_palette_find(palette, ramp[k], false);
                        if (!found.ok()) {
                            add(rp + "/" + std::to_string(k), found.error().message, found.error().hint);
                            continue;
                        }
                        if (used[std::size_t(*found)]) {
                            add(rp + "/" + std::to_string(k),
                                "The colour " + palette.label(*found) + " is already in a ramp.",
                                "A colour belongs to one ramp; list it once.");
                            continue;
                        }
                        used[std::size_t(*found)] = 1;
                        indices.push_back(*found);
                    }
                    if (indices.size() == ramp.size()) palette.ramps.push_back(std::move(indices));
                }
            }
        }
    }

    void parse_indexed(const Json& j, const std::string& pointer, ImageLayer& layer) {
        const std::string rowsHint = "Rows are strings with one character per pixel: '.' is transparent, 0-9a-zA-Z... "
                                     "are palette indices. Example: \"rows\": [\"..11..\", \".1221.\", \"..11..\"].";
        for (const char* k : {"masks", "adjustments", "effects"})
            if (j.contains(k))
                add(pointer + "/" + k,
                    std::string("An indexed layer cannot have `") + k +
                        "`: they would blend colours that are not in the palette.",
                    "Keep the layer palette-exact; use opacity and blend if you must (they leave the lock), or convert "
                    "it to pixels with image.layer.convert first.");
        get_bool(j, pointer, "ai", layer.ai);
        const bool hasSize = j.contains("width") || j.contains("height");
        auto it = j.find("rows");
        if (it == j.end()) {
            get_int(j, pointer, "width", layer.width, 1, kImageDocMaxSide,
                    "width and height are the size of the blank layer in pixels; leave them out for the canvas size.");
            get_int(j, pointer, "height", layer.height, 1, kImageDocMaxSide,
                    "width and height are the size of the blank layer in pixels; leave them out for the canvas size.");
            return;
        }
        if (hasSize)
            add(pointer + (j.contains("width") ? "/width" : "/height"),
                "An indexed layer with `rows` gets its size from them.",
                "Remove width and height, or remove rows for a blank layer.");
        parse_rows(*it, pointer + "/rows", layer.rows, layer.width, layer.height);
    }

    // The `rows` of an indexed layer or cel: text rows of one character per pixel, all the same width, indices inside the palette.
    void parse_rows(const Json& list, const std::string& rowsPointer, std::vector<std::string>& out, int& outWidth,
                    int& outHeight) {
        const std::string rowsHint = "Rows are strings with one character per pixel: '.' is transparent, 0-9a-zA-Z... "
                                     "are palette indices. Example: \"rows\": [\"..11..\", \".1221.\", \"..11..\"].";
        const Json* it = &list;
        const std::string pointer = rowsPointer.substr(0, rowsPointer.rfind('/'));
        if (!it->is_array() || it->empty()) {
            add(pointer + "/rows", "`rows` must be a non-empty list of strings, got " + describe_json_value(*it) + ".",
                rowsHint);
            return;
        }
        if (it->size() > std::size_t(kImageDocMaxSide)) {
            add(pointer + "/rows",
                std::format("{} rows is more than the {} pixels a canvas side may have.", it->size(), kImageDocMaxSide),
                "Split the picture.");
            return;
        }
        std::size_t width = 0;
        bool widthKnown = false;
        int reported = 0;
        for (std::size_t y = 0; y < it->size(); ++y) {
            const Json& row = (*it)[y];
            const std::string rp = pointer + "/rows/" + std::to_string(y);
            if (!row.is_string()) {
                add(rp, "A row is a string, got " + describe_json_value(row) + ".", rowsHint);
                return;
            }
            const std::string& text = row.get<std::string>();
            if (!widthKnown) {
                width = text.size();
                widthKnown = true;
                if (width == 0 || width > std::size_t(kImageDocMaxSide)) {
                    add(rp,
                        std::format("Row 0 has {} characters; a layer is 1 to {} pixels wide.", width,
                                    kImageDocMaxSide),
                        rowsHint);
                    return;
                }
            } else if (text.size() != width) {
                add(rp, std::format("Row {} has {} characters but row 0 has {}.", y, text.size(), width),
                    "Every row has one character per pixel and the same width. " + rowsHint);
                if (++reported >= 8) return;
                continue;
            }
            for (std::size_t x = 0; x < text.size() && reported < 8; ++x) {
                const int idx = pixel_char_index(text[x]);
                if (idx == -2) {
                    add(rp, std::format("Column {}: '{}' is not a palette character.", x, text[x]),
                        "Use '.' for transparent and the palette characters " +
                            std::string(kPixelIndexChars.substr(0, 12)) + "... " + rowsHint);
                    ++reported;
                } else if (idx >= 0 && !paletteDeferred && idx >= palette.size()) {
                    add(rp,
                        std::format("Column {}: '{}' is palette index {}, which is outside the palette of {} colours.",
                                    x, text[x], idx, palette.size()),
                        palette.size() > 0
                            ? std::format("The palette characters are {} (index 0 to {}). Add the colour to `palette` "
                                          "or draw with a colour that exists.",
                                          std::string(kPixelIndexChars.substr(0, std::size_t(palette.size()))),
                                          palette.size() - 1)
                            : "The document has no palette.");
                    ++reported;
                }
            }
            out.push_back(text);
        }
        outWidth = int(width);
        outHeight = int(it->size());
    }

    // `tile`: tile mode (docs/IMAGES.md, "Tiles"). true, or {"width", "height"} of one tile (default: the canvas, so the whole picture is one tile).
    void parse_tile(const Json& json, ImageDocument& doc) {
        auto it = json.find("tile");
        if (it == json.end()) return;
        const std::string hint =
            "Example: \"tile\": true (the canvas is one tile that repeats) or \"tile\": {\"width\": 16, \"height\": "
            "16} (the canvas is a sheet of 16 x 16 tiles). Remove the key for a picture that does not repeat.";
        if (it->is_boolean()) {
            doc.tile.enabled = it->get<bool>();
        } else if (it->is_object()) {
            doc.tile.enabled = true;
            unknown_keys(*it, "/tile", {"width", "height"}, "the tile settings");
            get_int(*it, "/tile", "width", doc.tile.width, 1, kImageDocMaxSide,
                    "`width` is one tile's width in pixels; it must divide the canvas width.");
            get_int(*it, "/tile", "height", doc.tile.height, 1, kImageDocMaxSide,
                    "`height` is one tile's height in pixels; it must divide the canvas height.");
        } else {
            add("/tile", "`tile` must be true or {width, height}, got " + describe_json_value(*it) + ".", hint);
            return;
        }
        if (!doc.tile.enabled) {
            doc.tile = {};
            return;
        }
        if (doc.tile.width == 0) doc.tile.width = canvasW;
        if (doc.tile.height == 0) doc.tile.height = canvasH;
        if (doc.tile.width > 0 && canvasW > 0 && (doc.tile.width > canvasW || canvasW % doc.tile.width))
            add("/tile/width",
                std::format(
                    "The tile is {} pixels wide but the canvas is {}: the tile width must divide the canvas width.",
                    doc.tile.width, canvasW),
                std::format(
                    "Use a width that fits a whole number of times, such as {}. A canvas of 128 holds 8 tiles of 16.",
                    canvasW % 2 == 0 ? canvasW / 2 : canvasW));
        if (doc.tile.height > 0 && canvasH > 0 && (doc.tile.height > canvasH || canvasH % doc.tile.height))
            add("/tile/height",
                std::format(
                    "The tile is {} pixels high but the canvas is {}: the tile height must divide the canvas height.",
                    doc.tile.height, canvasH),
                std::format("Use a height that fits a whole number of times, such as {}.",
                            canvasH % 2 == 0 ? canvasH / 2 : canvasH));
    }

    // One picture of a tileset part: a PNG path, {"source"}, {"rows"} or {"color"}.
    void parse_tileset_part(const Json& v, const std::string& pointer, TilesetPart& out) {
        out.pointer = pointer;
        const std::string hint =
            "A part picture is one tile: {\"source\": \"assets/tiles/grass.png\"}, {\"rows\": [\"1111\", ...]} (text "
            "rows of the document's palette) or {\"color\": \"#3a7a2a\"}. A list of them gives variants.";
        if (v.is_string()) {
            out.source = v.get<std::string>();
            const std::size_t slash = pointer.rfind('/');
            project_file(pointer.substr(0, slash), pointer.substr(slash + 1), out.source, {".png"}, "a PNG");
            return;
        }
        if (!v.is_object()) {
            add(pointer,
                "A tileset part must be a PNG path, an object {source | rows | color} or a list of those, got " +
                    describe_json_value(v) + ".",
                hint);
            return;
        }
        unknown_keys(v, pointer, {"source", "rows", "color"}, "a tileset part");
        const int kinds = int(v.contains("source")) + int(v.contains("rows")) + int(v.contains("color"));
        if (kinds != 1) {
            add(pointer,
                kinds == 0 ? "A tileset part needs `source`, `rows` or `color`."
                           : "A tileset part has exactly one of `source`, `rows` and `color`.",
                hint);
            return;
        }
        if (v.contains("source")) {
            if (get_string(v, pointer, "source", out.source))
                project_file(pointer, "source", out.source, {".png"}, "a PNG");
        } else if (v.contains("rows")) {
            int w = 0, h = 0;
            parse_rows(v["rows"], pointer + "/rows", out.rows, w, h);
        } else {
            Color c;
            if (get_color(v, pointer, "color", c)) out.color = c;
        }
    }

    // A `tileset` layer: the 16 or 47 tiles of an autotile set, built from a few parts (fa/tooling/image_tileset.h).
    void parse_tileset(const Json& j, const std::string& pointer, ImageLayer& layer) {
        TilesetSpec& t = layer.tileset;
        const std::string example =
            "Example: {\"kind\": \"tileset\", \"mode\": \"blob47\", \"tileWidth\": 16, \"tileHeight\": 16, \"parts\": "
            "{\"inside\": {\"source\": \"assets/tiles/grass.png\"}, \"edge\": {...}, \"corner\": {...}, "
            "\"innerCorner\": {...}}}.";
        if (get_string(j, pointer, "mode", t.mode) && t.mode != "basic16" && t.mode != "blob47")
            add(pointer + "/mode", "Unknown tileset mode '" + t.mode + "'.",
                did_you_mean(t.mode, std::vector<std::string>{"basic16", "blob47"}) +
                    " basic16 is the 16-tile set (4 neighbours), blob47 the 47-tile set (8 neighbours).");
        get_string(j, pointer, "terrain", t.terrain);
        const std::string sizeHint = "The size of one tile in pixels, an even number from 2 to 512 (it is split into "
                                     "four quadrants). Example: \"tileWidth\": 16, \"tileHeight\": 16.";
        if (!j.contains("tileWidth") && !j.contains("tileHeight"))
            add(pointer, "A tileset needs `tileWidth` and `tileHeight`: the size of one tile.",
                sizeHint + " " + example);
        get_int(j, pointer, "tileWidth", t.tileWidth, 2, 512, sizeHint);
        get_int(j, pointer, "tileHeight", t.tileHeight, 2, 512, sizeHint);
        if (t.tileWidth == 0) t.tileWidth = t.tileHeight;  // only one given: square tiles
        if (t.tileHeight == 0) t.tileHeight = t.tileWidth;
        if (t.tileWidth % 2)
            add(pointer + "/tileWidth",
                std::format("`tileWidth` is {}: a tile is cut into four quadrants, so its sides must be even.",
                            t.tileWidth),
                sizeHint);
        if (t.tileHeight % 2)
            add(pointer + "/tileHeight",
                std::format("`tileHeight` is {}: a tile is cut into four quadrants, so its sides must be even.",
                            t.tileHeight),
                sizeHint);
        get_int(j, pointer, "columns", t.columns, 1, 64,
                "`columns` is how many tiles a row of the baked sheet holds (default 4 for basic16, 8 for blob47).");
        get_int(j, pointer, "variations", t.variations, 1, 8,
                "`variations` is how many pictures each of the tiles gets (1 to 8); the others pick other variants of "
                "the parts by `seed`.");
        if (auto it = j.find("seed"); it != j.end()) {
            if (!it->is_number_integer())
                add(pointer + "/seed", "`seed` must be a whole number, got " + describe_json_value(*it) + ".",
                    "Example: \"seed\": 7. The same seed always picks the same variants.");
            else
                t.seed = it->get<long long>();
        }
        auto parts = j.find("parts");
        if (parts == j.end() || !parts->is_object()) {
            add(parts == j.end() ? pointer : pointer + "/parts",
                "A tileset needs `parts`: an object with the pictures it is built from.", example);
            return;
        }
        const auto& names = tileset_part_names();
        for (const std::string& name : names) {
            auto it = parts->find(name);
            if (it == parts->end()) continue;
            std::vector<TilesetPart> variants;
            const std::string pp = pointer + "/parts/" + name;
            if (it->is_array()) {
                if (it->empty())
                    add(pp, "A list of variants is empty.",
                        "List at least one picture, or give the part as one picture.");
                for (std::size_t i = 0; i < it->size(); ++i) {
                    TilesetPart part;
                    parse_tileset_part((*it)[i], pp + "/" + std::to_string(i), part);
                    variants.push_back(std::move(part));
                }
            } else {
                TilesetPart part;
                parse_tileset_part(*it, pp, part);
                variants.push_back(std::move(part));
            }
            t.parts.emplace_back(name, std::move(variants));
        }
        unknown_keys(*parts, pointer + "/parts", names, "the parts of a tileset");
        if (t.mode == "basic16" || t.mode == "blob47") {
            std::vector<std::string> missing;
            for (const std::string& need : tileset_required_parts(t.mode, t.tileWidth == t.tileHeight))
                if (!parts->contains(need)) missing.push_back(need);
            if (!missing.empty())
                add(pointer + "/parts",
                    "A " + t.mode + " tileset needs the part" + std::string(missing.size() == 1 ? " " : "s ") +
                        join(missing, ", ") + ".",
                    "The minimal set: inside (a flat tile of the terrain), edge (its top edge), corner (its top-left "
                    "outer corner)" +
                        std::string(t.mode == "blob47"
                                        ? ", innerCorner (an inside tile with the top-left corner cut out)"
                                        : "") +
                        (t.tileWidth != t.tileHeight
                             ? ", edgeLeft (its left edge: a tile that is not square cannot be turned)"
                             : "") +
                        ". The other orientations are made by flipping. Run image.tileset.info for the drawing of each "
                        "part.");
        }
    }

    // The `cels` of a pixels or indexed layer: what it shows from each frame after the first on (docs/IMAGES.md, "Frames and tags").
    void parse_cels(const Json& j, const std::string& pointer, ImageLayer& layer) {
        auto it = j.find("cels");
        if (it == j.end()) return;
        layer.hasCels = true;
        const bool indexed = layer.kind == ImageLayerKind::Indexed;
        const std::string celHint = indexed
                                        ? "Example: \"cels\": [{\"frame\": 1, \"rows\": [\"..11..\", \".1221.\"]}, "
                                          "{\"frame\": 2, \"link\": 0}, {\"frame\": 3, \"empty\": true}]."
                                        : "Example: \"cels\": [{\"frame\": 1, \"source\": \"assets/art/hero-1.png\"}, "
                                          "{\"frame\": 2, \"link\": 0}, {\"frame\": 3, \"empty\": true}].";
        if (!it->is_array()) {
            add(pointer + "/cels", "`cels` must be a list, got " + describe_json_value(*it) + ".", celHint);
            return;
        }
        int previous = 0;
        for (std::size_t i = 0; i < it->size(); ++i) {
            const Json& c = (*it)[i];
            ImageCel cel;
            cel.pointer = pointer + "/cels/" + std::to_string(i);
            if (!c.is_object()) {
                add(cel.pointer, "A cel must be an object, got " + describe_json_value(c) + ".", celHint);
                continue;
            }
            unknown_keys(c, cel.pointer,
                         indexed ? std::vector<std::string>{"frame", "empty", "link", "rows", "x", "y", "opacity"}
                                 : std::vector<std::string>{"frame", "empty", "link", "source", "x", "y", "opacity"},
                         "a cel");
            if (!c.contains("frame")) {
                add(cel.pointer, "A cel needs `frame`: the frame it starts at.", celHint);
                continue;
            }
            const bool frameOk =
                get_int(c, cel.pointer, "frame", cel.frame, 1, std::max(1, frameCount - 1),
                        frameCount > 1 ? std::format("The cels are of frames 1 to {} (frame 0 is the layer itself).",
                                                     frameCount - 1)
                                       : "The document has one frame, so there are no cels: add `frames` to the "
                                         "document first (image.frame.add).");
            if (frameOk && frameCount <= 1)
                add(cel.pointer + "/frame", "The document has one frame, so a layer has no cels.",
                    "Add `frames` to the document first (image.frame.add), or remove `cels`.");
            else if (frameOk && cel.frame <= previous)
                add(cel.pointer + "/frame",
                    std::format("Frame {} comes after frame {} in the list: cels are listed in increasing frame order, "
                                "one per frame.",
                                cel.frame, previous),
                    "Sort the cels by `frame` and give each frame one cel.");
            if (frameOk) previous = std::max(previous, cel.frame);
            const int contents =
                int(c.contains("empty")) + int(c.contains("link")) + int(c.contains(indexed ? "rows" : "source"));
            if (contents != 1) {
                add(cel.pointer,
                    contents == 0
                        ? "A cel needs what the layer shows from its frame on."
                        : "A cel has only one of `empty`, `link` and " + std::string(indexed ? "`rows`." : "`source`."),
                    celHint + " `empty` shows nothing, `link` shows the picture of an earlier frame.");
                continue;
            }
            if ((c.contains("empty") || c.contains("link")) &&
                (c.contains("x") || c.contains("y") || c.contains("opacity"))) {
                add(cel.pointer,
                    std::string("A cel with `") + (c.contains("empty") ? "empty" : "link") +
                        "` has no placement of its own: it shows nothing, or the other cel exactly as it is.",
                    "Remove x, y and opacity, or give the cel its own " +
                        std::string(indexed ? "`rows`." : "`source`."));
                continue;
            }
            if (c.contains("empty")) {
                bool e = false;
                if (get_bool(c, cel.pointer, "empty", e) && !e)
                    add(cel.pointer + "/empty", "`empty` is true or left out.",
                        "To show a picture, give `" + std::string(indexed ? "rows" : "source") + "` or `link`.");
                cel.empty = e;
            } else if (c.contains("link")) {
                get_int(c, cel.pointer, "link", cel.link, 0, std::max(0, frameCount - 2),
                        "`link` is the number of an EARLIER frame: this cel shows the picture that layer shows there.");
                if (cel.link >= cel.frame && cel.frame > 0)
                    add(cel.pointer + "/link",
                        std::format("`link` {} is not before the cel's frame {}.", cel.link, cel.frame),
                        "Link to an earlier frame; to show a later picture, link the later cel back instead.");
            } else if (indexed) {
                int w = 0, h = 0;
                parse_rows(c["rows"], cel.pointer + "/rows", cel.rows, w, h);
            } else if (get_string(c, cel.pointer, "source", cel.source)) {
                project_file(cel.pointer, "source", cel.source, {".png"}, "a PNG");
            }
            int xv = 0, yv = 0;
            if (c.contains("x") && get_int(c, cel.pointer, "x", xv, -100000, 100000,
                                           "x and y place the cel's top-left corner like the layer's x and y do."))
                cel.x = xv;
            if (c.contains("y") && get_int(c, cel.pointer, "y", yv, -100000, 100000,
                                           "x and y place the cel's top-left corner like the layer's x and y do."))
                cel.y = yv;
            get_number(c, cel.pointer, "opacity", cel.opacity, 0, 1,
                       "A cel's opacity (0 to 1) multiplies the layer's.");
            layer.cels.push_back(std::move(cel));
        }
    }

    // `frames`, `tags` and `sheet`: the animation of the document.
    void parse_animation(const Json& json, ImageDocument& doc) {
        if (auto it = json.find("frames"); it != json.end()) {
            const std::string hint = "Example: \"frames\": [{\"duration\": 100}, {\"duration\": 100}, {\"duration\": "
                                     "250}]: one object per frame, `duration` in milliseconds.";
            if (!it->is_array() || it->empty()) {
                add("/frames", "`frames` must be a non-empty list, got " + describe_json_value(*it) + ".", hint);
            } else if (it->size() > std::size_t(kImageMaxFrames)) {
                add("/frames",
                    std::format("{} frames is more than the {} a document may have.", it->size(), kImageMaxFrames),
                    "Split the animation into several documents.");
            } else {
                for (std::size_t i = 0; i < it->size(); ++i) {
                    const Json& f = (*it)[i];
                    const std::string fp = "/frames/" + std::to_string(i);
                    ImageFrame frame;
                    if (!f.is_object()) {
                        add(fp, "A frame must be an object, got " + describe_json_value(f) + ".", hint);
                        doc.frames.push_back(frame);
                        continue;
                    }
                    unknown_keys(f, fp, {"duration"}, "a frame");
                    get_int(
                        f, fp, "duration", frame.duration, 1, 60000,
                        "`duration` is how long the frame shows, in milliseconds (1 to 60000); 100 is the default.");
                    doc.frames.push_back(frame);
                }
                frameCount = int(doc.frames.size());
            }
            doc.animated = true;
        }
        if (auto it = json.find("tags"); it != json.end()) {
            const std::string hint = "Example: \"tags\": [{\"name\": \"walk\", \"from\": 0, \"to\": 3, \"direction\": "
                                     "\"forward\"}]. Directions: forward, reverse, pingpong.";
            if (!it->is_array()) {
                add("/tags", "`tags` must be a list, got " + describe_json_value(*it) + ".", hint);
            } else {
                if (!it->empty()) doc.animated = true;
                std::vector<std::string> names;
                for (std::size_t i = 0; i < it->size(); ++i) {
                    const Json& t = (*it)[i];
                    ImageTag tag;
                    tag.pointer = "/tags/" + std::to_string(i);
                    if (!t.is_object()) {
                        add(tag.pointer, "A tag must be an object, got " + describe_json_value(t) + ".", hint);
                        continue;
                    }
                    unknown_keys(t, tag.pointer, {"name", "from", "to", "direction", "repeat"}, "a tag");
                    bool ok = true;
                    if (!t.contains("name")) {
                        add(tag.pointer, "A tag needs a `name`: the clip name a SpriteAnimator plays.", hint);
                        ok = false;
                    } else
                        ok = get_string(t, tag.pointer, "name", tag.name) && ok;
                    if (ok && std::find(names.begin(), names.end(), tag.name) != names.end())
                        add(tag.pointer + "/name", "Another tag is called '" + tag.name + "'.",
                            "Give every tag its own name: it is the clip name.");
                    names.push_back(tag.name);
                    const std::string range = std::format("Frames run from 0 to {}.", frameCount - 1);
                    if (!t.contains("from")) add(tag.pointer, "A tag needs `from`: its first frame.", hint);
                    if (!t.contains("to")) add(tag.pointer, "A tag needs `to`: its last frame.", hint);
                    const bool f1 = get_int(t, tag.pointer, "from", tag.from, 0, frameCount - 1, range);
                    const bool f2 = get_int(t, tag.pointer, "to", tag.to, 0, frameCount - 1, range);
                    if (f1 && f2 && t.contains("from") && t.contains("to") && tag.from > tag.to)
                        add(tag.pointer + "/to", std::format("`to` {} is before `from` {}.", tag.to, tag.from),
                            "A tag runs from the lower frame to the higher one; the direction field plays it "
                            "backwards.");
                    if (t.contains("direction")) {
                        const auto dirs = image_tag_direction_names();
                        if (!t["direction"].is_string())
                            add(tag.pointer + "/direction",
                                "`direction` must be a string, got " + describe_json_value(t["direction"]) + ".",
                                "Directions: " + join(dirs, ", ") + ".");
                        else {
                            const std::string d = t["direction"].get<std::string>();
                            const auto f = std::find(dirs.begin(), dirs.end(), d);
                            if (f == dirs.end())
                                add(tag.pointer + "/direction", "Unknown direction '" + d + "'.",
                                    did_you_mean(d, dirs) + " Directions: " + join(dirs, ", ") + ".");
                            else
                                tag.direction = ImageTagDirection(f - dirs.begin());
                        }
                    }
                    get_int(t, tag.pointer, "repeat", tag.repeat, 0, 1000,
                            "`repeat` is how many times the tag plays; 0 (the default) loops for ever, 1 plays once.");
                    doc.tags.push_back(std::move(tag));
                }
            }
        }
        if (auto it = json.find("sheet"); it != json.end()) {
            const std::string hint = "Example: \"sheet\": {\"columns\": 4}: frames per row of the baked sprite sheet.";
            if (!it->is_object())
                add("/sheet", "`sheet` must be an object, got " + describe_json_value(*it) + ".", hint);
            else {
                unknown_keys(*it, "/sheet", {"columns"}, "the sheet settings");
                get_int(*it, "/sheet", "columns", doc.sheetColumns, 1, 1024,
                        "`columns` is how many frames the sheet has per row (default ceil(sqrt(cells))).");
                doc.animated = true;
            }
        }
    }

    ImageLayer parse_layer(const Json& j, const std::string& pointer, bool hasBelow, int depth) {
        ImageLayer layer;
        layer.pointer = pointer;
        const auto kinds = image_layer_kind_names();
        if (!j.is_object()) {
            add(pointer, "A layer must be an object, got " + describe_json_value(j) + ".",
                "Write {\"kind\": \"fill\", \"color\": \"#ffffff\"}. Kinds: " + join(kinds, ", ") + ".");
            return layer;
        }
        auto kindIt = j.find("kind");
        if (kindIt == j.end() || !kindIt->is_string()) {
            add(pointer + "/kind", "Every layer needs a string `kind`.", "Kinds: " + join(kinds, ", ") + ".");
            return layer;
        }
        const std::string kind = kindIt->get<std::string>();
        const auto kindFound = std::find(kinds.begin(), kinds.end(), kind);
        if (kindFound == kinds.end()) {
            add(pointer + "/kind", "Unknown layer kind '" + kind + "'.",
                did_you_mean(kind, kinds) + " Kinds: " + join(kinds, ", ") + ".");
            return layer;
        }
        layer.kind = ImageLayerKind(kindFound - kinds.begin());

        std::vector<std::string> allowed = {"kind", "name", "visible", "opacity",    "x",
                                            "y",    "clip", "masks",   "adjustments"};
        auto extend = [&](std::initializer_list<const char*> more) {
            allowed.insert(allowed.end(), more.begin(), more.end());
        };
        if (layer.kind != ImageLayerKind::Adjustment) extend({"blend", "effects"});
        switch (layer.kind) {
            case ImageLayerKind::Pixels: extend({"source", "cels"}); break;
            case ImageLayerKind::Provider: extend({"source", "provenance"}); break;
            case ImageLayerKind::Fill: extend({"color", "width", "height"}); break;
            case ImageLayerKind::Gradient: extend({"gradient", "width", "height"}); break;
            case ImageLayerKind::Procedural: extend({"texture"}); break;
            case ImageLayerKind::Svg: extend({"source", "svg", "width", "height"}); break;
            case ImageLayerKind::Text: extend({"text", "font", "size", "color", "align", "lineHeight"}); break;
            case ImageLayerKind::Group: extend({"layers"}); break;
            case ImageLayerKind::Adjustment: break;
            case ImageLayerKind::Indexed: extend({"rows", "width", "height", "ai", "cels"}); break;
            case ImageLayerKind::Tileset:
                extend({"mode", "terrain", "tileWidth", "tileHeight", "columns", "variations", "seed", "parts"});
                break;
        }
        unknown_keys(j, pointer, allowed, "a " + kind + " layer");

        get_string(j, pointer, "name", layer.name, true);
        get_bool(j, pointer, "visible", layer.visible);
        get_number(j, pointer, "opacity", layer.opacity, 0, 1,
                   "Opacity runs from 0 (invisible) to 1 (opaque); the default is 1.");
        get_int(j, pointer, "x", layer.x, -100000, 100000,
                "x and y move the layer by whole pixels from the top-left of the canvas (or of its group).");
        get_int(j, pointer, "y", layer.y, -100000, 100000,
                "x and y move the layer by whole pixels from the top-left of the canvas (or of its group).");
        if (get_bool(j, pointer, "clip", layer.clip) && layer.clip && !hasBelow)
            add(pointer + "/clip", "`clip` clips a layer to the layer below it, and there is no layer below.",
                "Remove `clip`, or put the layer that gives the shape before this one in the list (the list runs "
                "bottom first).");
        if (auto it = j.find("blend"); it != j.end()) {
            const auto names = image_blend_names();
            if (!it->is_string())
                add(pointer + "/blend", "`blend` must be a string, got " + describe_json_value(*it) + ".",
                    "Blend modes: " + join(names, ", ") + ".");
            else if (auto mode = parse_image_blend(it->get<std::string>()))
                layer.blend = *mode;
            else
                add(pointer + "/blend", "Unknown blend mode '" + it->get<std::string>() + "'.",
                    did_you_mean(it->get<std::string>(), names) + " Blend modes: " + join(names, ", ") + ".");
        }
        parse_masks(j, pointer, layer);
        parse_ops(j, pointer, "adjustments", false, layer.adjustments);
        if (layer.kind != ImageLayerKind::Adjustment) parse_ops(j, pointer, "effects", true, layer.effects);

        const std::string boxHint = "width and height are the size of the layer's own box in pixels; leave them out "
                                    "for the size of the canvas.";
        switch (layer.kind) {
            case ImageLayerKind::Pixels:
            case ImageLayerKind::Provider:
                if (!j.contains("source")) {
                    if (layer.kind != ImageLayerKind::Pixels || !j.contains("cels"))
                        add(pointer, "A " + kind + " layer needs `source`, a PNG of the project.",
                            "Example: {\"kind\": \"" + kind +
                                "\", \"source\": \"assets/art/hero.png\"}. (A pixels layer with `cels` may leave it "
                                "out: it is empty in frame 0.)");
                } else if (get_string(j, pointer, "source", layer.source))
                    project_file(pointer, "source", layer.source, {".png"}, "a PNG");
                if (layer.kind == ImageLayerKind::Pixels) parse_cels(j, pointer, layer);
                if (layer.kind == ImageLayerKind::Provider) {
                    if (auto it = j.find("provenance"); it != j.end()) {
                        const std::string pp = pointer + "/provenance";
                        if (!it->is_object())
                            add(pp, "`provenance` must be an object, got " + describe_json_value(*it) + ".",
                                "Example: {\"provider\": \"openai\", \"model\": \"gpt-image-1\", \"prompt\": \"a brass "
                                "key\"}.");
                        else {
                            unknown_keys(
                                *it, pp,
                                {"provider", "model", "prompt", "seed", "references", "license", "author", "notes"},
                                "a provider record");
                            layer.provenance = *it;
                        }
                    }
                }
                break;
            case ImageLayerKind::Fill:
                get_color(j, pointer, "color", layer.color);
                if (!j.contains("color"))
                    add(pointer, "A fill layer needs a `color`.",
                        "Example: {\"kind\": \"fill\", \"color\": \"#203040\"}.");
                get_int(j, pointer, "width", layer.width, 1, kImageDocMaxSide, boxHint);
                get_int(j, pointer, "height", layer.height, 1, kImageDocMaxSide, boxHint);
                break;
            case ImageLayerKind::Gradient:
                parse_gradient(j, pointer, layer);
                get_int(j, pointer, "width", layer.width, 1, kImageDocMaxSide, boxHint);
                get_int(j, pointer, "height", layer.height, 1, kImageDocMaxSide, boxHint);
                break;
            case ImageLayerKind::Procedural: {
                auto it = j.find("texture");
                if (it == j.end() || !it->is_object()) {
                    add(it == j.end() ? pointer : pointer + "/texture",
                        "A procedural layer needs `texture`: the picture arguments of assets.generate_texture.",
                        "Example: {\"kind\": \"procedural\", \"texture\": {\"preset\": \"parchment\", \"seed\": 3}}. "
                        "Run docs.commands on assets.generate_texture for the presets.");
                    break;
                }
                layer.texture = *it;
                Json args = *it;
                if (!args.contains("width")) args["width"] = std::max(1, canvasW);
                if (!args.contains("height")) args["height"] = std::max(1, canvasH);
                try {
                    assets_detail::check_procedural_texture_args(args, "image.bake", pointer + "/texture");
                } catch (const CommandError& e) {
                    // "image.bake /layers/0/texture/preset: unknown preset ..." -> pointer and message
                    const std::string text = e.what();
                    std::string ptr = pointer + "/texture", msg = text;
                    const std::string prefix = "image.bake ";
                    if (starts_with(text, prefix)) {
                        const auto colon = text.find(": ");
                        if (colon != std::string::npos) {
                            ptr = text.substr(prefix.size(), colon - prefix.size());
                            msg = text.substr(colon + 2);
                        }
                    }
                    add(ptr, msg, e.hint);
                }
                break;
            }
            case ImageLayerKind::Svg: {
                const bool hasSvg = j.contains("svg"), hasSource = j.contains("source");
                if (hasSvg == hasSource) {
                    add(pointer,
                        hasSvg ? "Give either `svg` (the SVG text) or `source` (a file), not both."
                               : "An svg layer needs `svg` (the SVG text) or `source` (an .svg file of the project).",
                        "Example: {\"kind\": \"svg\", \"source\": \"assets/art/crest.svg\", \"width\": 128, "
                        "\"height\": 128}.");
                } else if (hasSvg) {
                    if (get_string(j, pointer, "svg", layer.svg) && layer.svg.find("<svg") == std::string::npos)
                        add(pointer + "/svg", "The text has no <svg> element.",
                            "Start with <svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 100 100\"> and put the "
                            "shapes inside.");
                } else if (get_string(j, pointer, "source", layer.source)) {
                    project_file(pointer, "source", layer.source, {".svg"}, "an SVG file");
                }
                get_int(j, pointer, "width", layer.width, 1, kImageDocMaxSide,
                        "The SVG is fitted inside width x height, aspect kept and centred; leave them out to fit it in "
                        "the canvas.");
                get_int(j, pointer, "height", layer.height, 1, kImageDocMaxSide,
                        "The SVG is fitted inside width x height, aspect kept and centred; leave them out to fit it in "
                        "the canvas.");
                break;
            }
            case ImageLayerKind::Text:
                if (!j.contains("text"))
                    add(pointer, "A text layer needs `text`.",
                        "Example: {\"kind\": \"text\", \"text\": \"Hello\", \"size\": 24, \"color\": \"#ffffff\"}.");
                else
                    get_string(j, pointer, "text", layer.text);  // a non-empty string
                parse_font(j, pointer, layer);
                get_number(j, pointer, "size", layer.size, 1, 1024,
                           "`size` is the height of the em in pixels, 1 to 1024.");
                get_color(j, pointer, "color", layer.color);
                if (get_string(j, pointer, "align", layer.align) && layer.align != "left" && layer.align != "center" &&
                    layer.align != "right")
                    add(pointer + "/align", "Unknown alignment '" + layer.align + "'.",
                        did_you_mean(layer.align, std::vector<std::string>{"left", "center", "right"}) +
                            " Alignments: left, center, right (of the layer's x).");
                get_number(j, pointer, "lineHeight", layer.lineHeight, 0.1, 10,
                           "`lineHeight` is the distance between baselines in ems; 1.2 is the default.");
                break;
            case ImageLayerKind::Group: {
                auto it = j.find("layers");
                if (it == j.end() || !it->is_array()) {
                    add(it == j.end() ? pointer : pointer + "/layers",
                        "A group needs `layers`: a list of layers, bottom first.",
                        "Example: {\"kind\": \"group\", \"layers\": [{\"kind\": \"fill\", \"color\": \"#ffffff\"}]}.");
                    break;
                }
                if (depth >= 16) {
                    add(pointer + "/layers", "Groups are nested more than 16 deep.",
                        "Flatten the groups: nest at most a few levels.");
                    break;
                }
                parse_layers(*it, pointer + "/layers", layer.children, depth + 1);
                break;
            }
            case ImageLayerKind::Indexed:
                parse_indexed(j, pointer, layer);
                parse_cels(j, pointer, layer);
                break;
            case ImageLayerKind::Tileset: parse_tileset(j, pointer, layer); break;
            case ImageLayerKind::Adjustment:
                if (layer.adjustments.empty() && !issues_at(pointer + "/adjustments"))
                    add(pointer + "/adjustments",
                        "An adjustment layer needs `adjustments`: the colour operations it applies to everything below "
                        "it.",
                        "Example: {\"kind\": \"adjustment\", \"adjustments\": [{\"type\": \"invert\"}]}.");
                break;
        }
        return layer;
    }

    bool issues_at(const std::string& pointerPrefix) const {
        for (const ImageIssue& i : issues)
            if (starts_with(i.pointer, pointerPrefix)) return true;
        return false;
    }

    void parse_layers(const Json& list, const std::string& pointer, std::vector<ImageLayer>& out, int depth) {
        for (std::size_t i = 0; i < list.size(); ++i)
            out.push_back(parse_layer(list[i], pointer + "/" + std::to_string(i), i > 0, depth));
    }
};

std::string describe_first(const std::string& file, const ImageIssue& issue, std::size_t total) {
    std::string where = file.empty() ? std::string("image document") : file;
    std::string message =
        where + " " + (issue.pointer.empty() ? std::string("/") : issue.pointer) + ": " + issue.message;
    if (total > 1) message += std::format(" (and {} more problem{})", total - 1, total == 2 ? "" : "s");
    return message;
}

}  // namespace

Result<ImageDocument> parse_image_document(const Json& json, const std::string& file, const std::string& projectDir,
                                           std::vector<ImageIssue>* outIssues) {
    std::vector<ImageIssue> issues;
    ImageDocument doc;
    doc.file = file;
    doc.json = json;
    Parser p{file, projectDir, issues};
    const std::string exampleDoc = "{\"format\": \"factoria.image/1\", \"width\": 256, \"height\": 256, \"layers\": "
                                   "[{\"kind\": \"fill\", \"color\": \"#203040\"}]}";
    if (!json.is_object()) {
        p.add("", "An image document must be a JSON object, got " + describe_json_value(json) + ".",
              "Start from " + exampleDoc);
    } else {
        p.unknown_keys(json, "",
                       {"$schema", "format", "width", "height", "background", "output", "description", "palette",
                        "ramps", "tile", "frames", "tags", "sheet", "layers"},
                       "an image document");
        if (auto it = json.find("format");
            it != json.end() && (!it->is_string() || it->get<std::string>() != kImageDocFormat))
            p.add("/format", "Unknown format " + describe_json_value(*it) + ".",
                  std::string("Write \"format\": \"") + kImageDocFormat + "\" (or leave it out).");
        for (const char* key : {"width", "height"}) {
            if (!json.contains(key))
                p.add("", std::string("The canvas needs a `") + key + "` (whole pixels).", "Start from " + exampleDoc);
        }
        const std::string sizeHint =
            std::format("The canvas is width x height whole pixels, 1 to {} on each side.", kImageDocMaxSide);
        p.get_int(json, "", "width", doc.width, 1, kImageDocMaxSide, sizeHint);
        p.get_int(json, "", "height", doc.height, 1, kImageDocMaxSide, sizeHint);
        p.canvasW = doc.width;
        p.canvasH = doc.height;
        if (json.contains("background")) {
            Color c;
            if (p.get_color(json, "", "background", c)) doc.background = c;
        }
        p.get_string(json, "", "description", doc.description, true);
        if (p.get_string(json, "", "output", doc.output)) {
            if (!doc.output.empty()) {
                auto norm = fs::normalize_checked(doc.output);
                if (!norm.ok() || norm->empty() || to_lower(fs::extension(*norm)) != ".png")
                    p.add("/output", "`output` must be a project path ending in .png, got '" + doc.output + "'.",
                          "Example: \"output\": \"assets/art/hero.png\". Leave it out to bake next to the document.");
                else
                    doc.output = *norm;
            }
        }
        p.parse_palette(json);
        doc.palette = p.palette;
        p.parse_tile(json, doc);
        p.parse_animation(json, doc);
        auto layers = json.find("layers");
        if (layers == json.end() || !layers->is_array())
            p.add(layers == json.end() ? "" : "/layers", "The document needs `layers`: a list of layers, bottom first.",
                  "Start from " + exampleDoc);
        else
            p.parse_layers(*layers, "/layers", doc.layers, 0);
    }
    if (outIssues) *outIssues = issues;
    if (!issues.empty()) return make_error(describe_first(file, issues.front(), issues.size()), issues.front().hint);
    return doc;
}

Result<ImageDocument> load_image_document(const std::string& projectDir, const std::string& rel,
                                          std::vector<ImageIssue>* issues) {
    auto path = resolve_project_path(projectDir, rel);
    if (!path.ok()) return make_error(path.error().message, path.error().hint);
    auto text = tooling_detail::read_file(*path);
    if (!text)
        return make_error("Cannot read the image document '" + rel + "'.",
                          "Check the path; it is relative to the project folder. A document is a small JSON file: "
                          "{\"width\": 64, \"height\": 64, \"layers\": []}.");
    auto json = parse_json(*text, rel);
    if (!json.ok()) {
        if (issues) *issues = {{"", json.error().message, json.error().hint}};
        return make_error(json.error().message,
                          json.error().hint.empty()
                              ? "Fix the JSON syntax (a missing comma or quote is the usual cause)."
                              : json.error().hint);
    }
    return parse_image_document(*json, rel, projectDir, issues);
}

}  // namespace fa
