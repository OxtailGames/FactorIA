// The pixel helpers of image documents: image.pixel.outline / shade / dither / cleanup / rotate / scale and image.to_pixel_art
// (docs/IMAGES.md, "Pixel helpers"). They work on INDEXED layers by palette index only, so the result stays palette-exact, and the
// algorithms themselves are in fa/tooling/pixel_art.h (they know nothing of documents). Here: the arguments, the stored selection, the
// frames, the result.
//
// Every helper takes `frame` (default 0) or `frames` ("all", a list, or {from, to}) and `selection` (a stored selection of image.select:
// only its pixels change, 128 or more of coverage), and answers like image.pixel: the baked document, `region`, `changed`, and `$image`
// magnified with hard pixels, plus the helper's own counts.
#include <algorithm>
#include <cmath>
#include <format>
#include <functional>
#include <set>

#include "assets_internal.h"
#include "fa/core/strings.h"
#include "fa/tooling/pixel_art.h"
#include "fa/tooling/project_fs.h"
#include "fa/tooling/style_guide.h"
#include "image_doc_internal.h"
#include "image_edit.h"
#include "image_frames.h"
#include "image_indexed.h"
#include "util.h"

namespace fa::imgedit {

using assets_detail::arg_error;
using assets_detail::check_arg_keys;
using tooling_detail::arg_bool;
using tooling_detail::arg_string;
using namespace indexed;

namespace {

// ---- arguments ---------------------------------------------------------------------------------------------------------------------

std::string choice_arg(const char* cmd, const Json& a, const char* key, const std::vector<std::string>& options, const std::string& fallback) {
    auto it = a.find(key);
    if (it == a.end() || it->is_null()) return fallback;
    const std::string ptr = std::string("/") + key;
    if (!it->is_string() || std::find(options.begin(), options.end(), it->get<std::string>()) == options.end())
        arg_error(cmd, ptr, "unknown " + std::string(key) + " " + describe_json_value(*it) + ".",
                  (it->is_string() ? did_you_mean(it->get<std::string>(), options) + " " : std::string()) + "Choices: " + join(options, ", ") + ".");
    return it->get<std::string>();
}

int int_arg(const char* cmd, const Json& a, const char* key, int fallback, int lo, int hi, const std::string& what, const std::string& base = "") {
    auto it = a.find(key);
    if (it == a.end() || it->is_null()) return fallback;
    if (!it->is_number_integer() || it->get<long long>() < lo || it->get<long long>() > hi)
        arg_error(cmd, base + "/" + key, std::format("`{}` must be a whole number from {} to {}, got {}.", key, lo, hi, describe_json_value(*it)), what);
    return it->get<int>();
}

double number_arg(const char* cmd, const Json& a, const char* key, double fallback, double lo, double hi, const std::string& what) {
    auto it = a.find(key);
    if (it == a.end() || it->is_null()) return fallback;
    if (!it->is_number() || it->get<double>() < lo || it->get<double>() > hi)
        arg_error(cmd, std::string("/") + key, std::format("`{}` must be a number from {} to {}, got {}.", key, lo, hi, describe_json_value(*it)), what);
    return it->get<double>();
}

int colour_arg(const char* cmd, const PixelPalette& pal, const Json& ref, const std::string& ptr) {
    auto found = pixel_palette_find(pal, ref, false);
    if (!found.ok()) arg_error(cmd, ptr, found.error().message, found.error().hint);
    return *found;
}

// The direction of the light: `light` (degrees, a name such as "upper-left", or "style"), else the style guide's `lightDirection`.
// nullopt when neither says (the caller decides whether that is an error).
std::optional<double> light_arg(const std::string& projectDir, const Json& a, const char* cmd, std::string* source = nullptr) {
    auto it = a.find("light");
    if (it != a.end() && !it->is_null()) {
        if (it->is_number()) {
            if (source) *source = "light";
            double d = std::fmod(it->get<double>(), 360.0);
            return d < 0 ? d + 360.0 : d;
        }
        if (it->is_string() && it->get<std::string>() != "style") {
            std::vector<std::string> names;
            for (const auto& [name, deg] : light_direction_names()) {
                names.push_back(name);
                if (name == it->get<std::string>()) {
                    if (source) *source = "light";
                    return deg;
                }
            }
            arg_error(cmd, "/light", "unknown light direction '" + it->get<std::string>() + "'.",
                      did_you_mean(it->get<std::string>(), names) + " Use degrees counter-clockwise from the right (135 = upper-left) or one of: " + join(names, ", ") + ", or \"style\".");
        }
        if (!it->is_string()) arg_error(cmd, "/light", "`light` is degrees or a direction name, got " + describe_json_value(*it) + ".", "Example: 135 or \"upper-left\" (the light comes from the upper left).");
    }
    const StyleParse style = load_style_guide(projectDir);
    if (style.guide.lightDirection) {
        if (source) *source = "style.lightDirection";
        return *style.guide.lightDirection;
    }
    return std::nullopt;
}

std::vector<std::string> light_names() {
    std::vector<std::string> v;
    for (const auto& n : light_direction_names()) v.push_back(n.first);
    return v;
}

// The frames a helper works on: `frame`, or `frames` ("all", a list, {from, to}); default frame 0.
std::vector<int> frames_arg(const Json& a, int count, const char* cmd) {
    const bool hasFrame = a.contains("frame") && !a["frame"].is_null(), hasFrames = a.contains("frames") && !a["frames"].is_null();
    if (hasFrame && hasFrames) arg_error(cmd, "/frames", "give `frame` (one frame) or `frames` (several), not both.", "Example: \"frames\":\"all\", or \"frame\":2.");
    std::vector<int> out;
    if (hasFrames) {
        const Json& f = a["frames"];
        if (f.is_string()) {
            if (f.get<std::string>() != "all") arg_error(cmd, "/frames", "`frames` as a string is \"all\", got " + describe_json_value(f) + ".", "Or a list [0, 2, 3], or {\"from\":0,\"to\":3}.");
            for (int i = 0; i < count; ++i) out.push_back(i);
        } else if (f.is_array()) {
            if (f.empty()) arg_error(cmd, "/frames", "`frames` is an empty list.", "Name at least one frame, or use \"all\".");
            for (std::size_t i = 0; i < f.size(); ++i) {
                const int n = frame_number(cmd, f[i], "/frames/" + std::to_string(i), count);
                if (std::find(out.begin(), out.end(), n) == out.end()) out.push_back(n);
            }
        } else if (f.is_object()) {
            check_arg_keys(cmd, f, "/frames", {"from", "to"});
            const int from = f.contains("from") ? frame_number(cmd, f["from"], "/frames/from", count) : 0;
            const int to = f.contains("to") ? frame_number(cmd, f["to"], "/frames/to", count) : count - 1;
            if (to < from) arg_error(cmd, "/frames/to", std::format("`to` ({}) comes before `from` ({}).", to, from), "A range runs forward: {\"from\":1,\"to\":3}.");
            for (int i = from; i <= to; ++i) out.push_back(i);
        } else {
            arg_error(cmd, "/frames", "`frames` is \"all\", a list of frame numbers or {from, to}, got " + describe_json_value(f) + ".", "Example: \"all\".");
        }
    } else {
        out.push_back(hasFrame ? frame_number(cmd, a["frame"], "/frame", count) : 0);
    }
    return out;
}

// ---- the common frame ---------------------------------------------------------------------------------------------------------------

struct FrameWork {
    int frame = 0;
    Target& t;
    const PixelMask& mask;       // in the grid's own coordinates; empty = everywhere
    Json& detail;                // the helper's own counts for this frame
};

PixelMask grid_mask(const Mask* sel, const Target& t) {
    PixelMask m;
    if (!sel) return m;
    m.assign(t.grid.v.size(), 0);
    for (int y = 0; y < t.grid.h; ++y)
        for (int x = 0; x < t.grid.w; ++x) m[std::size_t(y) * t.grid.w + x] = sel->at(x + t.ox, y + t.oy) >= 128 ? 1 : 0;
    return m;
}

// The number of canvas pixels that differ between two placements of a grid.
int placed_diff(const IndexGrid& a, int ax, int ay, const IndexGrid& b, int bx, int by) {
    const int x0 = std::min(ax, bx), y0 = std::min(ay, by), x1 = std::max(ax + a.w, bx + b.w), y1 = std::max(ay + b.h > 0 ? ay + a.h : by, by + b.h);
    int n = 0;
    for (int y = y0; y < y1; ++y)
        for (int x = x0; x < x1; ++x) {
            const int va = a.at(x - ax, y - ay), vb = b.at(x - bx, y - by);
            if ((va < 0 ? -1 : va) != (vb < 0 ? -1 : vb)) ++n;
        }
    return n;
}

// Merges the counts a helper wrote for one tile cell into the totals of the frame: whole numbers add, lists join, the rest is kept.
void merge_detail(Json& total, const Json& part) {
    for (auto it = part.begin(); it != part.end(); ++it) {
        const std::string& k = it.key();
        if (k == "changedPixelsNote") continue;
        if (!total.contains(k)) total[k] = it.value();
        else if (it.value().is_number_integer() && total[k].is_number_integer()) total[k] = total[k].get<long long>() + it.value().get<long long>();
        else if (it.value().is_array() && total[k].is_array()) {
            for (const Json& e : it.value())
                if (total[k].size() < 100) total[k].push_back(e);
        } else total[k] = it.value();
    }
}

// Tile mode: runs `body` once per tile cell, on a 3 x 3 block of that cell's own pixels (the neighbours of an edge pixel are the pixels
// on the opposite side of the cell), and keeps only the middle block. The helper therefore sees a shape that crosses an edge whole.
void run_tiled(FrameWork& w, const std::function<void(FrameWork&, const std::vector<std::string>&)>& body) {
    Target& t = w.t;
    const TileGrid& g = t.tile;
    Json total = Json::object();
    std::set<std::string> warned(t.warnings.begin(), t.warnings.end());
    const IndexGrid source = t.grid;
    for (int cy = t.oy; cy < t.oy + source.h; cy += g.th)
        for (int cx = t.ox; cx < t.ox + source.w; cx += g.tw) {
            Target pt = t;
            pt.tile = TileGrid();
            pt.warnings.clear();
            pt.ox = cx - g.tw;
            pt.oy = cy - g.th;
            pt.grid = IndexGrid(g.tw * 3, g.th * 3);
            PixelMask mask(pt.grid.v.size(), 0);
            for (int y = 0; y < g.th * 3; ++y)
                for (int x = 0; x < g.tw * 3; ++x) {
                    const int sx = cx - t.ox + x % g.tw, sy = cy - t.oy + y % g.th;
                    pt.grid.v[std::size_t(y) * pt.grid.w + x] = source.at(sx, sy) == -2 ? -1 : source.at(sx, sy);
                    const bool middle = x >= g.tw && x < g.tw * 2 && y >= g.th && y < g.th * 2;
                    mask[std::size_t(y) * pt.grid.w + x] = middle && (w.mask.empty() || w.mask[std::size_t(sy) * source.w + sx]) ? 1 : 0;
                }
            Json detail = Json::object();
            FrameWork inner{w.frame, pt, mask, detail};
            body(inner, {});
            for (int y = 0; y < g.th; ++y)
                for (int x = 0; x < g.tw; ++x)
                    t.grid.v[std::size_t(cy - t.oy + y) * source.w + (cx - t.ox + x)] = pt.grid.v[std::size_t(y + g.th) * pt.grid.w + (x + g.tw)];
            for (const std::string& m : pt.warnings)
                if (warned.insert(m).second) t.warnings.push_back(m);
            merge_detail(total, detail);
        }
    if (total.contains("changedPixels") && total.value("pixelsChanged", 0) > int(total["changedPixels"].size()))
        total["changedPixelsNote"] = std::format("the first {} of {} changed pixels (canvas [x, y])", total["changedPixels"].size(), total.value("pixelsChanged", 0));
    for (auto it = total.begin(); it != total.end(); ++it) w.detail[it.key()] = it.value();
}

// Runs `body` on every requested frame of the layer `a.layer` of the document, then saves once and builds the result.
// `keys` are the arguments the command takes besides the common ones.
Json run_helper(const std::string& projectDir, const Json& a, const char* cmd, std::vector<std::string> keys, bool needsLayer,
                const std::function<void(FrameWork&, const std::vector<std::string>& selectionNames)>& body, const std::function<void(Json&)>& finishExtra = {}, bool tileAware = true) {
    keys.insert(keys.end(), {"path", "layer", "selection", "scale", "bake", "frame", "frames", "onion"});
    check_arg_keys(cmd, a, "", keys);
    (void)needsLayer;
    DocFile d = open_doc(projectDir, arg_string(a, "path", true), cmd);
    const int W = d.json.value("width", 0), H = d.json.value("height", 0);
    const std::vector<int> frames = frames_arg(a, json_frame_count(d.json), cmd);
    std::optional<Mask> sel;
    if (a.contains("selection") && !a["selection"].is_null()) {
        if (!a["selection"].is_string())
            arg_error(cmd, "/selection", "`selection` is the name of a stored selection, got " + describe_json_value(a["selection"]) + ".",
                      "Example: \"selection\":\"cape\" (image.select makes them; \"all\" is the whole canvas). Stored: " +
                          (list_selections(projectDir, d.rel).empty() ? std::string("none yet") : join(list_selections(projectDir, d.rel), ", ")) + ".");
        sel = load_selection(projectDir, d.rel, a["selection"].get<std::string>(), W, H, cmd);
    }
    assets_detail::require_usable_manifest(projectDir);
    const int previewFrame = frames.front();
    Json previewArgs = Json::object({{"frame", previewFrame}});
    if (a.contains("onion")) previewArgs["onion"] = a["onion"];
    std::optional<Image> before;
    {
        FrameScope scope(projectDir, d.rel, d.json, previewArgs, cmd);
        before = render_document_json(projectDir, d.json);
    }
    Json perFrame = Json::array();
    Json extra = Json::object();
    std::vector<std::string> warnings;
    std::size_t total = 0;
    for (int f : frames) {
        FrameScope scope(projectDir, d.rel, d.json, Json::object({{"frame", f}}), cmd);
        Target t = open_target(projectDir, d, a, cmd);
        for (auto it = t.extra.begin(); it != t.extra.end(); ++it) extra[it.key()] = it.value();
        const PixelMask mask = grid_mask(sel ? &*sel : nullptr, t);
        Json detail = Json::object();
        FrameWork work{f, t, mask, detail};
        if (t.tile.on && tileAware) run_tiled(work, body);
        else {
            if (t.tile.on)
                t.warnings.push_back("Tile mode is on but this helper does not wrap around the tile edges: check the seams with image.tile.check afterwards, or draw the result with image.pixel / image.draw.");
            body(work, {});
        }
        for (const std::string& w : t.warnings) warnings.push_back(frames.size() > 1 ? std::format("frame {}: {}", f, w) : w);
        store_grid(t);
        extra["layer"] = layer_summary(t.ref);
        total += std::size_t(detail.value("pixelsChanged", 0));
        detail["frame"] = f;
        perFrame.push_back(detail);
        if (scope.active()) d.json = scope.folded(d.json);
    }
    extra["pixelsChanged"] = total;
    if (frames.size() > 1) {
        extra["processedFrames"] = frames;
        extra["perFrame"] = perFrame;
    } else {
        for (auto it = perFrame[0].begin(); it != perFrame[0].end(); ++it)
            if (it.key() != "frame") extra[it.key()] = it.value();
    }
    if (finishExtra) finishExtra(extra);
    if (sel && a["selection"].get<std::string>() != "all") extra["selection"] = a["selection"];
    if (total == 0) warnings.push_back("No pixel changed: the layer may have nothing this helper acts on, or the selection covers none of it.");
    Json commitArgs = Json::object({{"frame", previewFrame}});
    if (a.contains("onion")) commitArgs["onion"] = a["onion"];
    FrameScope scope(projectDir, d.rel, d.json, commitArgs, cmd);
    const bool bake = arg_bool(a, "bake", true);
    Json out = commit_document(projectDir, d.rel, d.json, before, bake, extra, warnings, cmd);
    if (bake) attach_preview(projectDir, d.rel, d.json, out, scale_arg(a, cmd));
    return out;
}

// ---- lifting content to rotate or scale ----------------------------------------------------------------------------------------------

struct Lifted {
    IndexGrid pic;
    int x = 0, y = 0;   // canvas position of its top-left pixel
    bool empty = true;
};

// Takes the visible pixels of the layer (those in `mask`, all of them when it is empty) out of the grid and returns their box.
Lifted lift_content(Target& t, const PixelMask& mask) {
    Lifted l;
    int x0 = t.grid.w, y0 = t.grid.h, x1 = -1, y1 = -1;
    for (int y = 0; y < t.grid.h; ++y)
        for (int x = 0; x < t.grid.w; ++x)
            if (t.grid.at(x, y) >= 0 && (mask.empty() || mask[std::size_t(y) * t.grid.w + x])) x0 = std::min(x0, x), x1 = std::max(x1, x), y0 = std::min(y0, y), y1 = std::max(y1, y);
    if (x1 < 0) return l;
    l.empty = false;
    l.pic = IndexGrid(x1 - x0 + 1, y1 - y0 + 1);
    l.x = x0 + t.ox;
    l.y = y0 + t.oy;
    for (int y = y0; y <= y1; ++y)
        for (int x = x0; x <= x1; ++x)
            if (t.grid.at(x, y) >= 0 && (mask.empty() || mask[std::size_t(y) * t.grid.w + x])) {
                l.pic.set(x - x0, y - y0, t.grid.at(x, y));
                t.grid.set(x, y, -1);
            }
    return l;
}

// Draws `pic` (opaque pixels only) with its top-left at canvas (cx, cy). The layer's box grows to hold it.
void paste_content(Target& t, const IndexGrid& pic, int cx, int cy) {
    const int nx0 = std::min(t.ox, cx), ny0 = std::min(t.oy, cy);
    const int nx1 = std::max(t.ox + t.grid.w, cx + pic.w), ny1 = std::max(t.oy + t.grid.h, cy + pic.h);
    if (nx0 != t.ox || ny0 != t.oy || nx1 - nx0 != t.grid.w || ny1 - ny0 != t.grid.h) {
        IndexGrid grown(nx1 - nx0, ny1 - ny0);
        for (int y = 0; y < t.grid.h; ++y)
            for (int x = 0; x < t.grid.w; ++x) grown.set(x + t.ox - nx0, y + t.oy - ny0, t.grid.at(x, y));
        t.grid = std::move(grown);
        t.ox = nx0;
        t.oy = ny0;
        Json& L = *t.ref.layer;
        const int own = t.ox - t.ref.parentX;
        if (own) L["x"] = own;
        else L.erase("x");
        const int ownY = t.oy - t.ref.parentY;
        if (ownY) L["y"] = ownY;
        else L.erase("y");
    }
    for (int y = 0; y < pic.h; ++y)
        for (int x = 0; x < pic.w; ++x)
            if (pic.at(x, y) >= 0) t.grid.set(cx + x - t.ox, cy + y - t.oy, pic.at(x, y));
}

std::optional<std::pair<double, double>> pivot_arg(const char* cmd, const Json& a) {
    auto it = a.find("pivot");
    if (it == a.end() || it->is_null()) return std::nullopt;
    if (!it->is_array() || it->size() != 2 || !(*it)[0].is_number() || !(*it)[1].is_number())
        arg_error(cmd, "/pivot", "`pivot` is [x, y] in canvas pixels, got " + describe_json_value(*it) + ".", "Example: [16, 31] (the feet of a sprite). The pixel (x, y) spans x to x + 1: use 16.5 for its centre. Default: the centre of the pixels.");
    return std::make_pair((*it)[0].get<double>(), (*it)[1].get<double>());
}

}  // namespace

// ===================================================================================================================================
// image.pixel.outline
// ===================================================================================================================================

namespace {

Json image_pixel_outline(const std::string& projectDir, const Json& a) {
    const char* cmd = "image.pixel.outline";
    const std::string side = choice_arg(cmd, a, "side", {"outer", "inner"}, "outer");
    const std::string mode = choice_arg(cmd, a, "mode", {"flat", "darkest", "selective"}, a.contains("color") ? "flat" : "darkest");
    int connectivity = int_arg(cmd, a, "connectivity", 4, 4, 8, "4: pixels touching by an edge (a thin outline); 8: corners too.");
    if (connectivity != 4 && connectivity != 8) arg_error(cmd, "/connectivity", "`connectivity` is 4 or 8, got " + std::to_string(connectivity) + ".", "4 leaves the corners open (thin); 8 closes them.");
    const int shade = int_arg(cmd, a, "shade", 2, 1, 8, "Steps darker than the fill colour (mode selective).");
    const int litShade = int_arg(cmd, a, "litShade", std::max(1, shade - 1), 1, 8, "Steps darker on the side facing the light (mode selective).");
    if (a.contains("color") && mode != "flat") arg_error(cmd, "/color", "`color` is only used by mode \"flat\", and the mode is \"" + mode + "\".", "Leave `color` out, or set \"mode\":\"flat\".");
    if (mode == "flat" && !a.contains("color")) arg_error(cmd, "/color", "mode \"flat\" needs `color`: the palette colour of the outline.", "Example: \"color\":\"outline\". Or use \"mode\":\"darkest\" / \"selective\" to take it from the fill.");
    const std::optional<double> light = light_arg(projectDir, a, cmd);
    std::string note;
    return run_helper(
        projectDir, a, cmd, {"side", "mode", "connectivity", "color", "shade", "litShade", "light"}, true,
        [&](FrameWork& w, const std::vector<std::string>&) {
            PixelOutline o;
            o.inner = side == "inner";
            o.eightConnected = connectivity == 8;
            o.colour = mode == "flat" ? PixelOutline::Colour::Flat : mode == "darkest" ? PixelOutline::Colour::RampDarkest : PixelOutline::Colour::Selective;
            if (mode == "flat") o.color = colour_arg(cmd, w.t.pal, a["color"], "/color");
            o.shade = shade;
            o.litShade = litShade;
            if (light) o.hasLight = true, o.lightDegrees = *light;
            const int n = pixel_outline(w.t.grid, w.t.pal, o, w.mask);
            w.detail["pixelsChanged"] = n;
        },
        [&](Json& extra) {
            extra["side"] = side;
            extra["mode"] = mode;
            if (mode == "selective") {
                extra["light"] = light ? Json(light_direction_label(*light)) : Json();
                if (!light) extra["note"] = "No light direction (the `light` argument and style.lightDirection are both missing), so every outline pixel is " + std::to_string(shade) + " steps darker. Give `light` to make the lit side lighter.";
            }
        });
}

// ===================================================================================================================================
// image.pixel.shade
// ===================================================================================================================================

Json image_pixel_shade(const std::string& projectDir, const Json& a) {
    const char* cmd = "image.pixel.shade";
    std::string source;
    const std::optional<double> light = light_arg(projectDir, a, cmd, &source);
    if (!light)
        arg_error(cmd, "/light", "no light direction: `light` is missing and the project style has no `lightDirection`.",
                  "Pass `light`: degrees counter-clockwise from the right (135 = upper-left) or a name (" + join(light_names(), ", ") + "); or set style.lightDirection in assets.json so every asset agrees.");
    PixelShade o;
    o.lightDegrees = *light;
    o.shadowWidth = int_arg(cmd, a, "shadowWidth", 2, 1, 64, "Pixels per shadow band, measured along the light's direction from the edge facing away from the light.");
    o.shadowLevels = int_arg(cmd, a, "shadowLevels", 1, 0, 8, "How many shadow bands (steps darker at the edge); 0 = no shadow.");
    o.highlightWidth = int_arg(cmd, a, "highlightWidth", 1, 1, 64, "Pixels per highlight band, from the edge facing the light.");
    o.highlightLevels = int_arg(cmd, a, "highlightLevels", 1, 0, 8, "How many highlight bands (steps lighter at the edge); 0 = no highlight.");
    if (a.contains("dither") && a["dither"].is_boolean()) o.dither = a["dither"].get<bool>() ? 1 : 0;
    else o.dither = int_arg(cmd, a, "dither", 0, 0, 64, "Pixels of dithered transition at the inner edge of each band; 0 = hard bands.");
    if (o.dither > std::max(o.shadowWidth, o.highlightWidth))
        arg_error(cmd, "/dither", std::format("`dither` ({}) is wider than the bands ({} and {}).", o.dither, o.shadowWidth, o.highlightWidth), "The dithered transition must fit inside a band: lower `dither` or widen the bands.");
    return run_helper(
        projectDir, a, cmd, {"light", "shadowWidth", "shadowLevels", "highlightWidth", "highlightLevels", "dither"}, true,
        [&](FrameWork& w, const std::vector<std::string>&) {
            PixelShade s = o;
            s.origin = {w.t.ox, w.t.oy};
            w.detail["pixelsChanged"] = pixel_shade(w.t.grid, w.t.pal, s, w.mask);
        },
        [&](Json& extra) { extra["light"] = Json::object({{"degrees", *light}, {"name", light_direction_label(*light)}, {"from", source}}); });
}

// ===================================================================================================================================
// image.pixel.dither
// ===================================================================================================================================

Json image_pixel_dither(const std::string& projectDir, const Json& a) {
    const char* cmd = "image.pixel.dither";
    const std::string pattern = choice_arg(cmd, a, "pattern", {"checker", "bayer2", "bayer4", "bayer8"}, "bayer4");
    const DitherPattern pat = pattern == "checker" ? DitherPattern::Checker : pattern == "bayer2" ? DitherPattern::Bayer2 : pattern == "bayer4" ? DitherPattern::Bayer4 : DitherPattern::Bayer8;
    const bool hasLevel = a.contains("level") && !a["level"].is_null(), hasGradient = a.contains("gradient") && !a["gradient"].is_null();
    if (hasLevel == hasGradient)
        arg_error(cmd, hasLevel ? "/gradient" : "/level", "give `level` (a constant blend) or `gradient` (a blend along a direction), not both and not neither.",
                  "Example: {\"colors\":[\"skin\",\"skin-dark\"],\"level\":0.5} or {\"colors\":[\"sky\",\"sky-dark\"],\"gradient\":{\"from\":[0,0],\"to\":[0,15]}}.");
    if (!a.contains("colors") && !a.contains("ramp"))
        arg_error(cmd, "/colors", "`colors` is required: two or more palette colours, or `ramp`: any colour of a declared ramp to use the whole ramp.", "Example: \"colors\":[\"skin\",\"skin-dark\"]. image.palette lists the ramps.");
    if (a.contains("colors") && a.contains("ramp")) arg_error(cmd, "/ramp", "give `colors` or `ramp`, not both.", "`ramp` uses a declared ramp from its lightest to its darkest colour... pick one of the two.");
    const double level = hasLevel ? number_arg(cmd, a, "level", 0.5, 0, 1, "The share of the second colour: 0 = only the first, 1 = only the second, 0.5 = half.") : 0.5;
    const bool onlyFilled = arg_bool(a, "onlyFilled", false);
    std::optional<Region> rect;
    if (a.contains("rect") && !a["rect"].is_null()) {
        const Json& r = a["rect"];
        if (!r.is_object()) arg_error(cmd, "/rect", "`rect` is {x, y, width, height} in canvas pixels, got " + describe_json_value(r) + ".", "Example: {\"x\":2,\"y\":2,\"width\":10,\"height\":8}.");
        check_arg_keys(cmd, r, "/rect", {"x", "y", "width", "height"});
        Region g;
        g.x = int_arg(cmd, r, "x", 0, -100000, 100000, "Left column (canvas pixels).", "/rect");
        g.y = int_arg(cmd, r, "y", 0, -100000, 100000, "Top row (canvas pixels).", "/rect");
        g.width = int_arg(cmd, r, "width", 1, 1, 100000, "Width in pixels.", "/rect");
        g.height = int_arg(cmd, r, "height", 1, 1, 100000, "Height in pixels.", "/rect");
        rect = g;
    }
    PixelPoint from{0, 0}, to{0, 0};
    if (hasGradient) {
        const Json& g = a["gradient"];
        auto pt = [&](const char* key) {
            if (!g.is_object() || !g.contains(key) || !g[key].is_array() || g[key].size() != 2 || !g[key][0].is_number_integer() || !g[key][1].is_number_integer())
                arg_error(cmd, std::string("/gradient/") + key, std::string("`gradient` needs `") + key + "`: [x, y] in canvas pixels.", "Example: {\"from\":[0,0],\"to\":[0,15]} blends the first colour at the top row into the last at row 15.");
            return PixelPoint{g[key][0].get<int>(), g[key][1].get<int>()};
        };
        check_arg_keys(cmd, g, "/gradient", {"from", "to"});
        from = pt("from");
        to = pt("to");
        if (from == to) arg_error(cmd, "/gradient/to", "`from` and `to` are the same pixel, so there is no direction.", "Give two different pixels: the first colour is at `from`, the last at `to`.");
    }
    return run_helper(
        projectDir, a, cmd, {"colors", "ramp", "pattern", "level", "gradient", "onlyFilled", "rect"}, true,
        [&](FrameWork& w, const std::vector<std::string>&) {
            std::vector<int> colors;
            if (a.contains("ramp")) {
                const int any = colour_arg(cmd, w.t.pal, a["ramp"], "/ramp");
                auto r = w.t.pal.ramp_of(any);
                if (!r) arg_error(cmd, "/ramp", "'" + w.t.pal.label(any) + "' is in no declared ramp.", "Declare ramps with image.palette {\"ramps\":[[\"dark\",\"mid\",\"light\"]]}, or list the colours in `colors`.");
                colors = w.t.pal.ramps[std::size_t(r->first)];
            } else {
                if (!a["colors"].is_array() || a["colors"].size() < 2 || a["colors"].size() > 16)
                    arg_error(cmd, "/colors", "`colors` is a list of 2 to 16 palette colours, got " + describe_json_value(a["colors"]) + ".", "Example: [\"skin\",\"skin-dark\"]; with `level` only the first two are used.");
                for (std::size_t i = 0; i < a["colors"].size(); ++i) colors.push_back(colour_arg(cmd, w.t.pal, a["colors"][i], "/colors/" + std::to_string(i)));
            }
            PixelMask mask = w.mask;
            if (rect) {
                if (mask.empty()) mask.assign(w.t.grid.v.size(), 1);
                for (int y = 0; y < w.t.grid.h; ++y)
                    for (int x = 0; x < w.t.grid.w; ++x) {
                        const int cx = x + w.t.ox, cy = y + w.t.oy;
                        if (cx < rect->x || cy < rect->y || cx >= rect->x + rect->width || cy >= rect->y + rect->height) mask[std::size_t(y) * w.t.grid.w + x] = 0;
                    }
            }
            const PixelPoint origin{w.t.ox, w.t.oy};
            if (hasGradient) {
                if (a.contains("ramp")) std::reverse(colors.begin(), colors.end());   // from the lightest, the way a gradient reads at `from`
                w.detail["pixelsChanged"] = pixel_dither_gradient(w.t.grid, colors, {from.x - w.t.ox, from.y - w.t.oy}, {to.x - w.t.ox, to.y - w.t.oy}, pat, mask, onlyFilled, origin);
            } else {
                w.detail["pixelsChanged"] = pixel_dither_blend(w.t.grid, colors[0], colors[1], level, pat, mask, onlyFilled, origin);
            }
        },
        [&](Json& extra) { extra["pattern"] = pattern; });
}

// ===================================================================================================================================
// image.pixel.cleanup
// ===================================================================================================================================

Json image_pixel_cleanup(const std::string& projectDir, const Json& a) {
    const char* cmd = "image.pixel.cleanup";
    PixelCleanup o;
    o.orphans = o.doubles = o.jaggies = false;
    if (a.contains("passes") && !a["passes"].is_null()) {
        const std::vector<std::string> names = {"orphans", "doubles", "jaggies"};
        if (!a["passes"].is_array() || a["passes"].empty()) arg_error(cmd, "/passes", "`passes` is a list of passes, got " + describe_json_value(a["passes"]) + ".", "Passes: " + join(names, ", ") + ". Leave it out to run all three.");
        for (std::size_t i = 0; i < a["passes"].size(); ++i) {
            const std::string p = a["passes"][i].is_string() ? a["passes"][i].get<std::string>() : "";
            if (std::find(names.begin(), names.end(), p) == names.end())
                arg_error(cmd, "/passes/" + std::to_string(i), "unknown pass " + describe_json_value(a["passes"][i]) + ".", did_you_mean(p, names) + " Passes: " + join(names, ", ") + ".");
            (p == "orphans" ? o.orphans : p == "doubles" ? o.doubles : o.jaggies) = true;
        }
    } else {
        o.orphans = o.doubles = o.jaggies = true;
    }
    o.holes = arg_bool(a, "holes", false);
    o.eightConnected = int_arg(cmd, a, "connectivity", 8, 4, 8, "8: a diagonal neighbour of the same colour keeps a pixel; 4: only edge neighbours do.") != 4;
    if (a.contains("connectivity") && a["connectivity"].get<int>() != 4 && a["connectivity"].get<int>() != 8) arg_error(cmd, "/connectivity", "`connectivity` is 4 or 8.", "8 counts diagonal neighbours.");
    o.tolerance = number_arg(cmd, a, "tolerance", 1.0, 0.0, 4.0, "The most (in pixels) a line may stray from the straight line between its ends to be redrawn evenly (jaggies pass).");
    return run_helper(
        projectDir, a, cmd, {"passes", "holes", "connectivity", "tolerance", "keep"}, true,
        [&](FrameWork& w, const std::vector<std::string>&) {
            PixelCleanup c = o;
            if (a.contains("keep") && !a["keep"].is_null()) {
                if (!a["keep"].is_array()) arg_error(cmd, "/keep", "`keep` is a list of palette colours the clean-up never touches, got " + describe_json_value(a["keep"]) + ".", "Example: [\"shine\"] keeps a one-pixel highlight on purpose.");
                for (std::size_t i = 0; i < a["keep"].size(); ++i) c.keep.push_back(colour_arg(cmd, w.t.pal, a["keep"][i], "/keep/" + std::to_string(i)));
            }
            const PixelCleanupReport r = pixel_cleanup(w.t.grid, c, w.mask);
            w.detail["pixelsChanged"] = int(r.changed.size());
            w.detail["orphans"] = r.orphans;
            w.detail["doubles"] = r.doubles;
            w.detail["jaggies"] = r.jaggies;
            Json list = Json::array();
            for (std::size_t i = 0; i < r.changed.size() && i < 100; ++i) list.push_back(Json::array({r.changed[i].x + w.t.ox, r.changed[i].y + w.t.oy}));
            w.detail["changedPixels"] = list;
            if (r.changed.size() > 100) w.detail["changedPixelsNote"] = std::format("the first 100 of {} changed pixels (canvas [x, y])", r.changed.size());
        });
}

// ===================================================================================================================================
// image.pixel.rotate and image.pixel.scale
// ===================================================================================================================================

Json image_pixel_rotate(const std::string& projectDir, const Json& a) {
    const char* cmd = "image.pixel.rotate";
    if (!a.contains("angle") || !a["angle"].is_number())
        arg_error(cmd, "/angle", "`angle` is required: degrees, clockwise (negative = counter-clockwise).", "Example: \"angle\":45. A multiple of 90 is an exact turn of the pixels.");
    const double angle = a["angle"].get<double>();
    if (std::abs(angle) > 100000) arg_error(cmd, "/angle", "`angle` is out of range: " + describe_json_value(a["angle"]) + ".", "Degrees, for example 45 or -30.");
    const std::string method = choice_arg(cmd, a, "method", {"rotsprite", "nearest"}, "rotsprite");
    const auto pivot = pivot_arg(cmd, a);
    return run_helper(
        projectDir, a, cmd, {"angle", "method", "pivot"}, true,
        [&](FrameWork& w, const std::vector<std::string>&) {
            const IndexGrid original = w.t.grid;
            const int ox0 = w.t.ox, oy0 = w.t.oy;
            Lifted l = lift_content(w.t, w.mask);
            if (l.empty) {
                w.detail["pixelsChanged"] = 0;
                return;
            }
            if (method == "rotsprite" && (l.pic.w > 256 || l.pic.h > 256) && std::fmod(std::abs(angle), 90.0) > 1e-9)
                arg_error(cmd, "/method", std::format("the pixels to rotate are {} x {}: RotSprite works at 8 times that size and is limited to 256 x 256.", l.pic.w, l.pic.h),
                          "Select a part (image.select), or use \"method\":\"nearest\" for a larger picture.");
            const IndexGrid turned = pixel_rotate(l.pic, angle, method == "nearest" ? PixelRotateMethod::Nearest : PixelRotateMethod::RotSprite);
            const double cx = l.x + l.pic.w / 2.0, cy = l.y + l.pic.h / 2.0;
            const double px = pivot ? pivot->first : cx, py = pivot ? pivot->second : cy;
            const double r = angle * 3.14159265358979323846 / 180.0;
            const double ncx = px + (cx - px) * std::cos(r) - (cy - py) * std::sin(r), ncy = py + (cx - px) * std::sin(r) + (cy - py) * std::cos(r);
            const int nx = int(std::floor(ncx - turned.w / 2.0 + 0.5)), ny = int(std::floor(ncy - turned.h / 2.0 + 0.5));
            paste_content(w.t, turned, nx, ny);
            w.detail["pixelsChanged"] = placed_diff(original, ox0, oy0, w.t.grid, w.t.ox, w.t.oy);
            w.detail["size"] = Json::object({{"width", turned.w}, {"height", turned.h}});
            w.detail["at"] = Json::object({{"x", nx}, {"y", ny}});
        },
        [&](Json& extra) {
            extra["angle"] = angle;
            extra["method"] = method;
        }, false);
}

Json image_pixel_scale(const std::string& projectDir, const Json& a) {
    const char* cmd = "image.pixel.scale";
    const bool hasFactor = a.contains("factor") && !a["factor"].is_null(), hasSize = a.contains("size") && !a["size"].is_null();
    if (hasFactor == hasSize) arg_error(cmd, hasFactor ? "/size" : "/factor", "give `factor` (a multiplier) or `size` (the new size in pixels), not both and not neither.", "Example: \"factor\":2, \"factor\":[2,1], or \"size\":{\"width\":24,\"height\":24}.");
    double fx = 1, fy = 1;
    int sw = 0, sh = 0;
    if (hasFactor) {
        const Json& f = a["factor"];
        auto num = [&](const Json& v, const std::string& ptr) {
            if (!v.is_number() || v.get<double>() <= 0.0 || v.get<double>() > 64)
                arg_error(cmd, ptr, "a factor is a number above 0 up to 64, got " + describe_json_value(v) + ".", "Example: 2 doubles, 0.5 halves, [2, 1] doubles the width only.");
            return v.get<double>();
        };
        if (f.is_array()) {
            if (f.size() != 2) arg_error(cmd, "/factor", "`factor` as a list is [horizontal, vertical].", "Example: [2, 1].");
            fx = num(f[0], "/factor/0");
            fy = num(f[1], "/factor/1");
        } else {
            fx = fy = num(f, "/factor");
        }
    } else {
        const Json& s = a["size"];
        if (!s.is_object()) arg_error(cmd, "/size", "`size` is {width, height}, got " + describe_json_value(s) + ".", "Example: {\"width\":24,\"height\":24}; give one to keep the proportions.");
        check_arg_keys(cmd, s, "/size", {"width", "height"});
        if (!s.contains("width") && !s.contains("height")) arg_error(cmd, "/size", "`size` needs `width`, `height` or both.", "Example: {\"width\":24}.");
        sw = int_arg(cmd, s, "width", 0, 1, 4096, "The new width in pixels.", "/size");
        sh = int_arg(cmd, s, "height", 0, 1, 4096, "The new height in pixels.", "/size");
    }
    const std::string method = choice_arg(cmd, a, "method", {"auto", "nearest", "mode", "scale2x", "scale3x"}, "auto");
    const auto pivot = pivot_arg(cmd, a);
    std::vector<std::string> noteList;
    return run_helper(
        projectDir, a, cmd, {"factor", "size", "method", "pivot"}, true,
        [&](FrameWork& w, const std::vector<std::string>&) {
            const IndexGrid original = w.t.grid;
            const int ox0 = w.t.ox, oy0 = w.t.oy;
            Lifted l = lift_content(w.t, w.mask);
            if (l.empty) {
                w.detail["pixelsChanged"] = 0;
                return;
            }
            double dx = fx, dy = fy;
            int nw, nh;
            if (hasSize) {
                nw = sw ? sw : std::max(1, int(std::lround(double(l.pic.w) * sh / l.pic.h)));
                nh = sh ? sh : std::max(1, int(std::lround(double(l.pic.h) * sw / l.pic.w)));
                dx = double(nw) / l.pic.w;
                dy = double(nh) / l.pic.h;
            } else {
                nw = std::max(1, int(std::lround(l.pic.w * dx)));
                nh = std::max(1, int(std::lround(l.pic.h * dy)));
            }
            if (std::int64_t(nw) * nh > 16000000) arg_error(cmd, hasSize ? "/size" : "/factor", std::format("the result would be {} x {} pixels.", nw, nh), "Scale by a smaller factor.");
            std::string used = method;
            IndexGrid out;
            if (method == "scale2x" || method == "scale3x") {
                const int k = method == "scale2x" ? 2 : 3;
                if (nw != l.pic.w * k || nh != l.pic.h * k)
                    arg_error(cmd, "/method", std::format("{} makes the picture exactly {} times as large, and this asks for {} x {} from {} x {}.", method, k, nw, nh, l.pic.w, l.pic.h),
                              std::format("Use \"factor\":{} with {}, or \"method\":\"nearest\" / \"mode\" for another size.", k, method));
                out = k == 2 ? pixel_scale2x(l.pic) : pixel_scale3x(l.pic);
            } else {
                if (method == "auto") used = (nw >= l.pic.w && nh >= l.pic.h) ? "nearest" : "mode";
                out = pixel_resample(l.pic, nw, nh, used == "nearest" ? PixelResample::Nearest : PixelResample::Mode);
                if (used == "nearest" && (nw % l.pic.w || nh % l.pic.h))
                    w.t.warnings.push_back("A non-integer enlargement repeats some columns or rows and not others, so strokes get uneven widths; prefer a whole factor (2, 3) or the `scale2x` method.");
            }
            const double cx = l.x + l.pic.w / 2.0, cy = l.y + l.pic.h / 2.0;
            const double px = pivot ? pivot->first : cx, py = pivot ? pivot->second : cy;
            // the pivot stays where it is: the box's corner moves by the factor around it
            const int nx = int(std::floor(px + (l.x - px) * dx + 0.5)), ny = int(std::floor(py + (l.y - py) * dy + 0.5));
            paste_content(w.t, out, nx, ny);
            w.detail["pixelsChanged"] = placed_diff(original, ox0, oy0, w.t.grid, w.t.ox, w.t.oy);
            w.detail["size"] = Json::object({{"width", out.w}, {"height", out.h}});
            w.detail["from"] = Json::object({{"width", l.pic.w}, {"height", l.pic.h}});
            w.detail["method"] = used;
        }, {}, false);
}

// ===================================================================================================================================
// image.to_pixel_art
// ===================================================================================================================================

Json image_to_pixel_art(const std::string& projectDir, const Json& a) {
    const char* cmd = "image.to_pixel_art";
    check_arg_keys(cmd, a, "", {"path", "source", "png", "into", "width", "height", "pixelSize", "method", "palette", "dither", "strength", "space", "alphaThreshold", "orphans", "outline", "x", "y", "scale", "bake", "frame", "onion"});
    DocFile d = open_doc(projectDir, arg_string(a, "path", true), cmd);
    const bool hasLayer = a.contains("source") && !a["source"].is_null(), hasPng = a.contains("png") && !a["png"].is_null();
    if (hasLayer == hasPng)
        arg_error(cmd, hasLayer ? "/png" : "/source", "give `source` (a layer of the document: a pixels layer, a painted or generated one) or `png` (a PNG of the project), not both and not neither.",
                  "Example: {\"source\":\"painting\",\"into\":\"sprite\",\"width\":32} or {\"png\":\"assets/art/render.png\",\"into\":\"sprite\",\"pixelSize\":4}. " + describe_layers(d.json, 12));
    if (!a.contains("into") || !a["into"].is_string() || a["into"].get<std::string>().empty())
        arg_error(cmd, "/into", "`into` is required: the name of the indexed layer that receives the pixel art (created when it does not exist, replaced when it does).", "Example: \"into\":\"sprite\".");
    const int W = d.json.value("width", 0), H = d.json.value("height", 0);
    FrameScope frameScope(projectDir, d.rel, d.json, a, cmd);
    const std::optional<Image> before = render_document_json(projectDir, d.json);
    assets_detail::require_usable_manifest(projectDir);
    std::vector<std::string> warnings;
    Json extra = Json::object();

    // the picture to convert, and where its top-left pixel lies on the canvas
    Image src;
    int srcX = 0, srcY = 0;
    if (hasLayer) {
        LayerRef ref = find_layer(d.json, a["source"], cmd, "source");
        const std::string kind = ref.layer->value("kind", std::string());
        if (kind == "indexed" && ref.layer->value("name", std::string()) == a["into"].get<std::string>())
            arg_error(cmd, "/into", "`into` is the same layer as `source`.", "Name another layer: the converted picture is written there.");
        Image whole = render_layer_alone(projectDir, *ref.layer, W, H, ref.parentX, ref.parentY, &warnings, &d.json);
        int x0 = whole.width, y0 = whole.height, x1 = -1, y1 = -1;
        for (int y = 0; y < whole.height; ++y)
            for (int x = 0; x < whole.width; ++x)
                if (whole.rgba[(std::size_t(y) * whole.width + x) * 4 + 3]) x0 = std::min(x0, x), x1 = std::max(x1, x), y0 = std::min(y0, y), y1 = std::max(y1, y);
        if (x1 < 0) arg_error(cmd, "/source", "layer '" + a["source"].dump() + "' shows nothing, so there is nothing to convert.", "Pick a layer with pixels.");
        src.width = x1 - x0 + 1;
        src.height = y1 - y0 + 1;
        src.rgba.resize(std::size_t(src.width) * src.height * 4);
        for (int y = 0; y < src.height; ++y) std::copy_n(&whole.rgba[(std::size_t(y + y0) * whole.width + x0) * 4], std::size_t(src.width) * 4, &src.rgba[std::size_t(y) * src.width * 4]);
        srcX = x0;
        srcY = y0;
    } else {
        if (!a["png"].is_string()) arg_error(cmd, "/png", "`png` is a project path, got " + describe_json_value(a["png"]) + ".", "Example: \"assets/art/render.png\".");
        auto path = resolve_project_path(projectDir, a["png"].get<std::string>());
        if (!path.ok()) arg_error(cmd, "/png", path.error().message, path.error().hint);
        auto bytes = tooling_detail::read_file(*path);
        if (!bytes) arg_error(cmd, "/png", "cannot read '" + a["png"].get<std::string>() + "'.", "Give the project-relative path of an existing PNG (or JPG/BMP/TGA).");
        auto img = decode_image(reinterpret_cast<const std::uint8_t*>(bytes->data()), bytes->size());
        if (!img.ok()) arg_error(cmd, "/png", "'" + a["png"].get<std::string>() + "' is not a readable picture: " + img.error().message, img.error().hint);
        src = std::move(*img);
    }

    // the size of the pixel art
    int tw = 0, th = 0;
    const bool hasW = a.contains("width") && !a["width"].is_null(), hasH = a.contains("height") && !a["height"].is_null(), hasPs = a.contains("pixelSize") && !a["pixelSize"].is_null();
    if (hasPs && (hasW || hasH)) arg_error(cmd, "/pixelSize", "give `pixelSize` or `width` / `height`, not both.", "pixelSize: how many pixels of the source make one pixel of art (4 turns 128 x 128 into 32 x 32).");
    if (!hasPs && !hasW && !hasH) arg_error(cmd, "/width", "give the size of the pixel art: `width` and/or `height` (one keeps the proportions), or `pixelSize`.", "Example: \"width\":32, or \"pixelSize\":4.");
    if (hasPs) {
        const int ps = int_arg(cmd, a, "pixelSize", 1, 1, 4096, "How many source pixels make one art pixel.");
        tw = (src.width + ps - 1) / ps;
        th = (src.height + ps - 1) / ps;
    } else {
        tw = hasW ? int_arg(cmd, a, "width", 1, 1, 2048, "The width of the pixel art in pixels.") : 0;
        th = hasH ? int_arg(cmd, a, "height", 1, 1, 2048, "The height of the pixel art in pixels.") : 0;
        if (!tw) tw = std::max(1, int(std::lround(double(src.width) * th / src.height)));
        if (!th) th = std::max(1, int(std::lround(double(src.height) * tw / src.width)));
    }
    if (tw > src.width || th > src.height) warnings.push_back(std::format("The pixel art ({} x {}) is larger than the source ({} x {}): nothing is downscaled, pixels are repeated.", tw, th, src.width, src.height));

    const std::string method = choice_arg(cmd, a, "method", {"dominant", "average"}, "dominant");
    const std::vector<std::string> dithers = {"none", "bayer2", "bayer4", "bayer8", "floydSteinberg", "atkinson"};
    const std::string dither = choice_arg(cmd, a, "dither", dithers, "none");
    if (method == "dominant" && dither != "none")
        arg_error(cmd, "/dither", "`dither` needs \"method\":\"average\": the dominant method gives every pixel one palette colour of the source, with nothing to spread.", "Use \"method\":\"average\" with a dither, or drop `dither`.");
    const std::string space = choice_arg(cmd, a, "space", {"oklab", "rgb"}, "oklab");
    const double strength = number_arg(cmd, a, "strength", 1.0, 0.0, 1.0, "How strong the dither is.");
    const double threshold = number_arg(cmd, a, "alphaThreshold", 0.5, 1e-6, 1.0, "Pixels at least this opaque become palette colours, the rest transparent.");

    // the palette
    if (a.contains("palette") && !a["palette"].is_null() && !d.json.contains("palette")) d.json["palette"] = a["palette"];
    PixelPalette pal = load_doc_palette(projectDir, d.rel, d.json, true, cmd);
    if (pal.empty()) fail("invalid_argument", "There is no palette to quantize to.", "Pass \"palette\":[\"#000000\",\"#ffffff\",...] or set style.palette in assets.json.");
    if (pin_palette(d.json, pal)) extra["palettePinned"] = "The palette was copied into the document's `palette`; edit it with image.palette.";

    // colours
    IndexGrid grid;
    if (method == "dominant") {
        grid = pixel_dominant_downscale(src, pal, tw, th, threshold);
    } else {
        const Image small = pixel_area_downscale(src, tw, th);
        imgdoc::Raster r(tw, th, srcX, srcY);
        std::vector<int> exact(std::size_t(tw) * th, -1);
        for (int y = 0; y < th; ++y)
            for (int x = 0; x < tw; ++x) {
                const std::uint8_t* s = &small.rgba[(std::size_t(y) * tw + x) * 4];
                if (s[3] == 0 || double(s[3]) / 255.0 < threshold) continue;
                if (auto same = pal.find_rgb(s[0], s[1], s[2])) exact[std::size_t(y) * tw + x] = *same;
                float* p = r.at(x, y);
                p[0] = s[0] / 255.0f;
                p[1] = s[1] / 255.0f;
                p[2] = s[2] / 255.0f;
                p[3] = 1.0f;
            }
        Json op = Json::object({{"type", "quantize"}, {"palette", Json::array()}, {"space", space}, {"dither", dither}, {"strength", strength}});
        for (int i = 0; i < pal.size(); ++i) op["palette"].push_back(pal.hex(i));
        static const StyleGuide noStyle;
        imgdoc::OpEnv env;
        env.image = [](const std::string&) -> const Image& { throw CommandError("failed", "No picture is read by this operation.", ""); };
        env.style = []() -> const StyleGuide& { return noStyle; };
        env.fail = [](const std::string& m, const std::string& h) { throw CommandError("failed", m, h); };
        imgdoc::apply_adjustments({op}, r, env);
        grid = IndexGrid(tw, th);
        for (int y = 0; y < th; ++y)
            for (int x = 0; x < tw; ++x) {
                const float* p = r.at(x, y);
                if (p[3] <= 0) continue;
                auto b = [](float v) { return std::uint8_t(std::lround(std::clamp(v, 0.0f, 1.0f) * 255.0f)); };
                const int keep = exact[std::size_t(y) * tw + x];
                grid.set(x, y, keep >= 0 ? keep : pal.nearest(b(p[0]), b(p[1]), b(p[2])));
            }
    }

    // the clean-up
    int orphans = 0, outlinePixels = 0;
    if (arg_bool(a, "orphans", dither == "none")) {
        PixelCleanup c;
        c.doubles = c.jaggies = false;
        orphans = pixel_cleanup(grid, c).orphans;
    }
    if (a.contains("outline") && !a["outline"].is_null()) {
        PixelOutline o;
        if (a["outline"].is_string() && a["outline"].get<std::string>() == "darkest") o.colour = PixelOutline::Colour::RampDarkest;
        else o.color = colour_arg(cmd, pal, a["outline"], "/outline");
        // the outline needs room around the picture: one transparent ring
        IndexGrid padded(grid.w + 2, grid.h + 2);
        for (int y = 0; y < grid.h; ++y)
            for (int x = 0; x < grid.w; ++x) padded.set(x + 1, y + 1, grid.at(x, y));
        outlinePixels = pixel_outline(padded, pal, o);
        grid = padded;
        srcX -= 1;
        srcY -= 1;
    }

    // where it lands: the same place as the source, unless x / y say otherwise; the layer is created or replaced
    int px = srcX, py = srcY;
    if (hasPng) px = py = 0;
    px = int_arg(cmd, a, "x", px, -100000, 100000, "Canvas column of the left edge of the pixel art (default: where the source's pixels start).");
    py = int_arg(cmd, a, "y", py, -100000, 100000, "Canvas row of the top edge of the pixel art (default: where the source's pixels start).");
    Json args2 = Json::object({{"layer", a["into"]}, {"create", true}});
    Target t = open_target(projectDir, d, args2, cmd);
    for (auto it = t.extra.begin(); it != t.extra.end(); ++it) extra[it.key()] = it.value();
    const bool replaced = !t.extra.contains("createdLayer");
    t.grid = grid;
    t.ox = px;
    t.oy = py;
    {
        Json& L = *t.ref.layer;
        const int ownX = px - t.ref.parentX, ownY = py - t.ref.parentY;
        if (ownX) L["x"] = ownX;
        else L.erase("x");
        if (ownY) L["y"] = ownY;
        else L.erase("y");
    }
    store_grid(t);
    extra["layer"] = layer_summary(t.ref);
    extra["replacedLayer"] = replaced;
    extra["sourceSize"] = Json::object({{"width", src.width}, {"height", src.height}});
    extra["size"] = Json::object({{"width", grid.w}, {"height", grid.h}});
    extra["at"] = Json::object({{"x", px}, {"y", py}});
    extra["method"] = method;
    extra["orphansFixed"] = orphans;
    if (outlinePixels) extra["outlinePixels"] = outlinePixels;
    std::set<int> used(grid.v.begin(), grid.v.end());
    used.erase(-1);
    extra["colorsUsed"] = used.size();
    for (const std::string& w : t.warnings) warnings.push_back(w);
    const bool bake = arg_bool(a, "bake", true);
    Json out = commit_document(projectDir, d.rel, d.json, before, bake, extra, warnings, cmd);
    if (bake) attach_preview(projectDir, d.rel, d.json, out, scale_arg(a, cmd));
    return out;
}

}  // namespace

// ===================================================================================================================================
// registration
// ===================================================================================================================================

void register_pixel_helper_commands(CommandRegistry& registry, const std::string& projectDir) {
    const std::string pathDoc = "The image document, project-relative, ending in .image.json.";
    const std::string layerDoc = "The indexed layer to change: its name or an index path like \\\"1/0\\\". (A pixels layer: image.layer.convert it first, or image.to_pixel_art.)";
    const std::string selDoc = "A stored selection (image.select): only its pixels (coverage 128 or more) may change. Default: the whole layer.";
    const std::string framesDoc = "Several frames at once: \\\"all\\\", a list [0, 2, 3] or {\\\"from\\\": 0, \\\"to\\\": 3}. The same change is made on each frame's cel; the result lists the pixels changed per frame (`perFrame`) and the picture shown is the first of them. Not with `frame`.";
    const std::string commonProps =
        "\"path\":{\"type\":\"string\",\"description\":\"" + pathDoc + "\"},"
        "\"layer\":{\"description\":\"" + layerDoc + "\"},"
        "\"selection\":{\"type\":\"string\",\"description\":\"" + selDoc + "\"},"
        "\"frames\":{\"description\":\"" + framesDoc + "\"},"
        "\"scale\":{\"type\":\"integer\",\"minimum\":1,\"maximum\":32,\"description\":\"Magnification of the preview picture (default: automatic).\"},"
        "\"bake\":{\"type\":\"boolean\",\"default\":true,\"description\":\"Also draw the PNG (default true). False only writes the document.\"}";
    const std::string lightDoc = "The direction TOWARDS the light: degrees counter-clockwise from the right (135 = upper-left, 90 = above), a name (upper-left, top, ...) or \\\"style\\\". Default: style.lightDirection of assets.json.";
    const std::string resultDoc =
        " Result as image.pixel: the baked document, `region` {x,y,width,height} of the changed pixels (of the first frame), `changed`, `pixelsChanged`, `layer` and `$image` = the picture magnified with hard pixels (`previewScale`). "
        "Every pixel stays a palette colour: nothing is blended and there is no anti-aliasing.";
    auto add = [&](const char* name, const char* summary, const std::string& description, const std::string& schema, Json (*fn)(const std::string&, const Json&), bool frames = true) {
        CommandInfo info;
        info.name = name;
        info.category = "assets";
        info.readOnly = false;
        info.summary = summary;
        info.description = description;
        info.inputSchema = Json::parse(schema);
        add_frame_support(info, frames ? "to change" : "whose cel receives the pixel art");
        add_image_command(registry, info, [projectDir, fn](const Json& args) { return fn(projectDir, args); });
    };

    add("image.pixel.outline", "Outline an indexed pixel-art layer by palette colour: inside or outside, 4- or 8-connected, flat, darkest of the ramp, or selective (sel-out).",
        "Outlines the shape of an INDEXED layer (everything that is not transparent). `side`: \"outer\" "
        "(default) puts the outline on the transparent pixels next to the shape, \"inner\" on the shape's "
        "own edge pixels. `connectivity` 4 (default) is a thin outline whose corners stay open, 8 closes the "
        "corners. `mode`: \"flat\" paints `color` (the default when `color` is given); \"darkest\" (default "
        "without `color`) uses, for each outline pixel, the darkest colour of the ramp of the fill colour it "
        "touches (a colour in no declared ramp: the darkest palette colour derived from it, see "
        "image.palette); \"selective\" is sel-out: the outline pixel takes its fill colour `shade` steps "
        "darker (default 2) along the ramp, and on the side that faces the light `litShade` steps (default "
        "shade - 1), so the outline is lighter where the light hits. The light is `light` or "
        "style.lightDirection; without one every pixel is `shade` steps darker. With `selection` only "
        "outline pixels inside it are written (the shape is still read from the whole layer). Frames: "
        "`frame` or `frames`. Only indexed layers: pixel art is palette-exact; a pixels layer must be "
        "converted first. "
        FA_COMMAND_DETAILS
        + resultDoc + " Example: {\"path\":\"assets/art/hero.image.json\",\"layer\":\"sprite\",\"mode\":\"selective\",\"light\":\"upper-left\"}",
        "{\"type\":\"object\",\"required\":[\"path\",\"layer\"],\"properties\":{" + commonProps + ","
        "\"side\":{\"type\":\"string\",\"enum\":[\"outer\",\"inner\"],\"default\":\"outer\",\"description\":\"outer: on the transparent pixels around the shape. inner: on the shape's own edge pixels.\"},"
        "\"mode\":{\"type\":\"string\",\"enum\":[\"flat\",\"darkest\",\"selective\"],\"description\":\"flat: one palette colour (`color`). darkest: the darkest of the ramp of the fill colour it touches. selective: sel-out, the fill colour a few steps darker, lighter on the lit side. Default flat with `color`, else darkest.\"},"
        "\"color\":{\"description\":\"mode flat: the palette colour of the outline (index, name, single character or #rrggbb that is in the palette).\"},"
        "\"connectivity\":{\"type\":\"integer\",\"enum\":[4,8],\"default\":4,\"description\":\"4: pixels touching by an edge count as next to the shape; 8: corners too (a thicker outline with closed corners).\"},"
        "\"shade\":{\"type\":\"integer\",\"minimum\":1,\"maximum\":8,\"default\":2,\"description\":\"mode selective: steps darker than the fill colour (on the shadow side).\"},"
        "\"litShade\":{\"type\":\"integer\",\"minimum\":1,\"maximum\":8,\"description\":\"mode selective: steps darker on the side facing the light (default shade - 1, at least 1).\"},"
        "\"light\":{\"description\":\"" + lightDoc + "\"}}}",
        image_pixel_outline);

    add("image.pixel.shade", "Shade an indexed pixel-art shape from a light direction: shadow and highlight bands stepping along the colour ramps, optional dithered transition.",
        "Shades the shape (the non-transparent pixels of the layer, or of the `selection`) as if lit from "
        "`light`: along the light's axis, `shadowLevels` bands of `shadowWidth` pixels at the edge facing "
        "away from the light step the colour darker (the outermost the most, the inner bands one step less), "
        "and `highlightLevels` bands of `highlightWidth` pixels at the edge facing the light step it "
        "lighter. A step follows the colour's declared ramp, or the nearest darker / lighter palette colour "
        "(image.palette). Shadow wins where both reach a pixel. `dither` N makes the first N pixels of each "
        "band after the first a Bayer-ordered mix with the stronger band before it, so the transition is not "
        "a hard line. The light is `light` or style.lightDirection (an error teaches both when neither "
        "exists). Run it on a flat-coloured shape (a body, a ball, a hat): shading is relative to what is in "
        "the pixel, so shading twice shades twice. Frames: `frame` or `frames`. "
        FA_COMMAND_DETAILS + resultDoc + " Example: {\"path\":\"assets/art/hero.image.json\",\"layer\":\"sprite\",\"selection\":\"body\",\"light\":\"upper-left\",\"shadowWidth\":2,\"dither\":1}",
        "{\"type\":\"object\",\"required\":[\"path\",\"layer\"],\"properties\":{" + commonProps + ","
        "\"light\":{\"description\":\"" + lightDoc + "\"},"
        "\"shadowWidth\":{\"type\":\"integer\",\"minimum\":1,\"maximum\":64,\"default\":2,\"description\":\"Pixels per shadow band, measured along the light's direction.\"},"
        "\"shadowLevels\":{\"type\":\"integer\",\"minimum\":0,\"maximum\":8,\"default\":1,\"description\":\"Shadow bands (steps darker at the edge). 0 = no shadow.\"},"
        "\"highlightWidth\":{\"type\":\"integer\",\"minimum\":1,\"maximum\":64,\"default\":1,\"description\":\"Pixels per highlight band.\"},"
        "\"highlightLevels\":{\"type\":\"integer\",\"minimum\":0,\"maximum\":8,\"default\":1,\"description\":\"Highlight bands (steps lighter at the edge). 0 = no highlight.\"},"
        "\"dither\":{\"type\":\"integer\",\"minimum\":0,\"maximum\":64,\"default\":0,\"description\":\"Pixels of Bayer-dithered transition at the inner edge of each band (at most the band width). 0 or false = hard bands; true = 1.\"}}}",
        image_pixel_shade);

    add("image.pixel.dither", "Fill a region of an indexed layer with a dithered blend of palette colours (Bayer or checker), constant or as a gradient along a direction.",
        "Writes into the region (`selection`, and/or `rect`, else the whole layer box; transparent pixels "
        "too unless `onlyFilled`) a blend of palette colours made of pixels of exactly those colours, "
        "arranged by an ordered pattern. `colors` are 2 or more palette colours (or `ramp`: any colour of a "
        "declared ramp uses the whole ramp). Either `level` 0..1, the share of the second colour (bayer2 has "
        "5 steps, bayer4 17, bayer8 65; checker alternates the two between a quarter and three quarters), or "
        "`gradient` {from [x,y], to [x,y]} in canvas pixels: the first colour at `from`, the last at `to`, "
        "the colours between spaced evenly and dithered into each other (with `ramp` the gradient runs from "
        "the lightest colour to the darkest). The patterns line up with the canvas, not with the layer, so "
        "two layers dithered alike match. Frames: `frame` or `frames`. "
        FA_COMMAND_DETAILS + resultDoc +
        " Example: {\"path\":\"assets/art/sky.image.json\",\"layer\":\"sky\",\"colors\":[\"sky-light\",\"sky\",\"sky-dark\"],\"gradient\":{\"from\":[0,0],\"to\":[0,31]},\"pattern\":\"bayer4\"}",
        "{\"type\":\"object\",\"required\":[\"path\",\"layer\"],\"properties\":{" + commonProps + ","
        "\"colors\":{\"type\":\"array\",\"minItems\":2,\"maxItems\":16,\"description\":\"Two or more palette colours (index, name, single character or #rrggbb in the palette). With `level` the first two are blended.\"},"
        "\"ramp\":{\"description\":\"Any palette colour of a declared ramp: use that whole ramp as the colours (dark to light; a gradient runs light to dark).\"},"
        "\"pattern\":{\"type\":\"string\",\"enum\":[\"checker\",\"bayer2\",\"bayer4\",\"bayer8\"],\"default\":\"bayer4\",\"description\":\"The ordered pattern that decides which pixels take the second colour.\"},"
        "\"level\":{\"type\":\"number\",\"minimum\":0,\"maximum\":1,\"description\":\"A constant blend: the share of the second colour. Give this or `gradient`.\"},"
        "\"gradient\":{\"type\":\"object\",\"description\":\"A blend along a direction: {from: [x, y], to: [x, y]} canvas pixels. Give this or `level`.\"},"
        "\"onlyFilled\":{\"type\":\"boolean\",\"default\":false,\"description\":\"Only change pixels that already have a colour (leave transparent ones transparent).\"},"
        "\"rect\":{\"type\":\"object\",\"description\":\"Limit the region to a box {x, y, width, height} in canvas pixels (with `selection`, the part in both).\"}}}",
        image_pixel_dither);

    add("image.pixel.cleanup", "Clean an indexed layer: orphan pixels, doubles at line bends and uneven steps on nearly straight lines; reports what changed.",
        "Three passes (`passes`, default all, in this order). orphans: a pixel with no neighbour of its own "
        "colour takes the commonest opaque colour around it, or disappears when only transparency is around "
        "(`connectivity` 8 default counts diagonal neighbours, `holes` also fills single transparent holes "
        "inside colour). doubles: the corner pixel of a one-pixel line where it bends in an L (two pixels "
        "thick at the bend) is removed so the line is one pixel wide everywhere; the right-angled corners of "
        "shapes are left alone. jaggies: a one-pixel line that is nearly straight (never more than "
        "`tolerance` pixels, default 1, from the straight line between its ends) but has uneven steps "
        "(3,3,1,3) is redrawn evenly between its ends, when the pixels it needs are free. `keep` lists "
        "palette colours never touched (a one-pixel highlight on purpose). A single-pixel highlight or eye "
        "dot is an orphan to this command: name its colour in `keep`. Frames: `frame` or `frames`. Result: "
        "as image.pixel, plus per frame `orphans`, `doubles`, `jaggies` (pixels changed by each pass) and "
        "`changedPixels` ([x, y] on the canvas, the first 100). "
        FA_COMMAND_DETAILS +
            std::string(" Example: {\"path\":\"assets/art/hero.image.json\",\"layer\":\"sprite\",\"frames\":\"all\",\"keep\":[\"shine\"]}"),
        "{\"type\":\"object\",\"required\":[\"path\",\"layer\"],\"properties\":{" + commonProps + ","
        "\"passes\":{\"type\":\"array\",\"items\":{\"type\":\"string\",\"enum\":[\"orphans\",\"doubles\",\"jaggies\"]},\"description\":\"Which passes to run (default all three).\"},"
        "\"holes\":{\"type\":\"boolean\",\"default\":false,\"description\":\"orphans: also fill a single transparent pixel enclosed by colour.\"},"
        "\"connectivity\":{\"type\":\"integer\",\"enum\":[4,8],\"default\":8,\"description\":\"orphans: 8 counts a diagonal neighbour of the same colour as connected, 4 only edge neighbours.\"},"
        "\"tolerance\":{\"type\":\"number\",\"minimum\":0,\"maximum\":4,\"default\":1,\"description\":\"jaggies: the most a line may stray from the straight line between its ends to be redrawn evenly.\"},"
        "\"keep\":{\"type\":\"array\",\"description\":\"Palette colours the clean-up never changes.\"}}}",
        image_pixel_cleanup);

    add("image.pixel.rotate", "Rotate the pixels of an indexed layer (or a selection) by any angle, RotSprite-style: no new colours, no blur.",
        "Rotates the visible pixels of the layer (or of the `selection`) `angle` degrees clockwise about "
        "`pivot` (canvas pixels; default the centre of those pixels) and draws them back; the layer's box "
        "grows to hold the result. A multiple of 90 degrees is an exact turn of the pixels. Otherwise "
        "`method` \"rotsprite\" (default) enlarges the picture 8 times with Scale2x (EPX) three times, "
        "rotates by nearest sample and takes the commonest colour of each 8x8 block back down, which keeps "
        "edges and thin lines far better than a plain nearest rotation (\"nearest\", fast and blocky); the "
        "pixels to rotate are at most 256 x 256 for rotsprite. Only palette colours appear. Frames: `frame` "
        "or `frames`. "
        FA_COMMAND_DETAILS + resultDoc +
        " Example: {\"path\":\"assets/art/hero.image.json\",\"layer\":\"sword\",\"angle\":30,\"pivot\":[12,20]}",
        "{\"type\":\"object\",\"required\":[\"path\",\"layer\",\"angle\"],\"properties\":{" + commonProps + ","
        "\"angle\":{\"type\":\"number\",\"description\":\"Degrees, clockwise (negative: counter-clockwise).\"},"
        "\"method\":{\"type\":\"string\",\"enum\":[\"rotsprite\",\"nearest\"],\"default\":\"rotsprite\",\"description\":\"rotsprite: x8 with Scale2x, rotate, most-common-colour downscale. nearest: plain nearest-neighbour rotation.\"},"
        "\"pivot\":{\"type\":\"array\",\"items\":{\"type\":\"number\"},\"minItems\":2,\"maxItems\":2,\"description\":\"[x, y] canvas pixels the rotation turns about (the pixel (x, y) spans x to x + 1). Default: the centre of the pixels.\"}}}",
        image_pixel_rotate);

    add("image.pixel.scale", "Scale the pixels of an indexed layer (or a selection) cleanly: whole factors repeat pixels, reductions take the commonest colour, scale2x/scale3x round corners; no blending.",
        "Scales the visible pixels of the layer (or of the `selection`) by `factor` (a number, or "
        "[horizontal, vertical]) or to `size` {width, height} (one of them keeps the proportions), around "
        "`pivot` (canvas pixels, default the centre of the pixels); the layer's box grows to hold the "
        "result. `method`: \"nearest\" repeats the pixel under each new pixel's centre (a whole factor makes "
        "exact blocks); \"mode\" gives each new pixel the commonest colour of the old pixels it covers (the "
        "clean way to shrink; opaque wins a tie); \"scale2x\" / \"scale3x\" are the EPX-style enlargers by "
        "exactly 2 / 3 that round off corners instead of copying them; \"auto\" (default) is nearest when "
        "enlarging and mode when shrinking. A non-integer enlargement works but repeats some rows and "
        "columns and not others, and a warning says so. Only palette colours appear. Frames: `frame` or "
        "`frames`. "
        FA_COMMAND_DETAILS + resultDoc + " Example: {\"path\":\"assets/art/hero.image.json\",\"layer\":\"sprite\",\"factor\":2,\"method\":\"scale2x\"}",
        "{\"type\":\"object\",\"required\":[\"path\",\"layer\"],\"properties\":{" + commonProps + ","
        "\"factor\":{\"description\":\"A multiplier (2 doubles, 0.5 halves) or [horizontal, vertical]. Give this or `size`.\"},"
        "\"size\":{\"type\":\"object\",\"description\":\"The new size {width, height} in pixels of the scaled pixels; give one to keep the proportions. Give this or `factor`.\"},"
        "\"method\":{\"type\":\"string\",\"enum\":[\"auto\",\"nearest\",\"mode\",\"scale2x\",\"scale3x\"],\"default\":\"auto\",\"description\":\"auto: nearest to enlarge, mode to shrink. scale2x / scale3x: exactly x2 / x3 with rounded corners.\"},"
        "\"pivot\":{\"type\":\"array\",\"items\":{\"type\":\"number\"},\"minItems\":2,\"maxItems\":2,\"description\":\"[x, y] canvas pixels that stay in place. Default: the centre of the pixels.\"}}}",
        image_pixel_scale);

    add("image.to_pixel_art", "Turn a painted, generated or imported picture (a layer or a PNG) into palette-exact pixel art: area-aware downscale, quantize, clean up, into an indexed layer.",
        "Takes `source` (a layer of the document of any kind: a pixels layer, a painted, generated or vector "
        "one, drawn alone with its masks and effects) or `png` (a PNG of the project), makes it `width` x "
        "`height` pixels (one keeps the proportions) or `pixelSize` source pixels per art pixel, and writes "
        "the result into the indexed layer `into` (created at the top, or replaced). `method`: \"dominant\" "
        "(default) turns every source pixel into its nearest palette colour (OKLab) first and gives each art "
        "pixel the commonest colour of the source pixels it covers, so edges stay crisp and no colour is a "
        "blend; \"average\" averages the covered area (a box filter with exact fractional edges, not "
        "bilinear) and then quantizes to the palette with the dither of image.layer.convert (`dither` none, "
        "bayer2/4/8, floydSteinberg, atkinson; `strength`; `space` oklab or rgb). Art pixels under "
        "`alphaThreshold` opaque (default 0.5) are transparent."
        FA_COMMAND_DETAILS
        "Then `orphans` (default true, but false with a `dither`, whose pixels would look stray) removes "
        "stray single pixels (image.pixel.cleanup) and `outline` (a palette colour, or \"darkest\" for the "
        "darkest of each fill colour's ramp) adds a 4-connected outer outline. The palette is the "
        "document's, else `palette` (written into the document), else the style palette. The art lands where "
        "the source's pixels were (a PNG: at 0, 0) unless `x` / `y` say otherwise. `frame` chooses the frame "
        "whose cel receives it. Result: as image.pixel plus `sourceSize`, `size`, `at`, `colorsUsed`, "
        "`orphansFixed`, `outlinePixels`. Example: "
        "{\"path\":\"assets/art/hero.image.json\",\"source\":\"painting\",\"into\":\"sprite\",\"width\":32,\"outline\":\"darkest\"}",
        "{\"type\":\"object\",\"required\":[\"path\",\"into\"],\"properties\":{"
        "\"path\":{\"type\":\"string\",\"description\":\"" + pathDoc + "\"},"
        "\"source\":{\"description\":\"The layer to convert: its name or an index path. Give this or `png`.\"},"
        "\"png\":{\"type\":\"string\",\"description\":\"A PNG (or JPG, BMP, TGA) of the project to convert. Give this or `source`.\"},"
        "\"into\":{\"type\":\"string\",\"description\":\"The name of the indexed layer that receives the pixel art: created at the top when it does not exist, replaced when it does.\"},"
        "\"width\":{\"type\":\"integer\",\"minimum\":1,\"maximum\":2048,\"description\":\"Width of the pixel art in pixels (alone: the height follows the proportions).\"},"
        "\"height\":{\"type\":\"integer\",\"minimum\":1,\"maximum\":2048,\"description\":\"Height of the pixel art in pixels.\"},"
        "\"pixelSize\":{\"type\":\"integer\",\"minimum\":1,\"description\":\"Source pixels per art pixel (4 turns 128 x 128 into 32 x 32). Instead of width / height.\"},"
        "\"method\":{\"type\":\"string\",\"enum\":[\"dominant\",\"average\"],\"default\":\"dominant\",\"description\":\"dominant: palette colour first, then the commonest in each area. average: area average, then quantize (with an optional dither).\"},"
        "\"palette\":{\"description\":\"The palette when the document has none (a list of colours or \\\"style\\\"); it is written into the document.\"},"
        "\"dither\":{\"type\":\"string\",\"enum\":[\"none\",\"bayer2\",\"bayer4\",\"bayer8\",\"floydSteinberg\",\"atkinson\"],\"default\":\"none\",\"description\":\"method average: how colours between palette colours are mixed.\"},"
        "\"strength\":{\"type\":\"number\",\"minimum\":0,\"maximum\":1,\"default\":1,\"description\":\"method average: how strong the dither is.\"},"
        "\"space\":{\"type\":\"string\",\"enum\":[\"oklab\",\"rgb\"],\"default\":\"oklab\",\"description\":\"method average: how colour distance is measured.\"},"
        "\"alphaThreshold\":{\"type\":\"number\",\"exclusiveMinimum\":0,\"maximum\":1,\"default\":0.5,\"description\":\"Art pixels at least this opaque become palette colours, the rest transparent.\"},"
        "\"orphans\":{\"type\":\"boolean\",\"description\":\"Remove single stray pixels afterwards. Default true, false when `dither` is set (a dither is made of single pixels).\"},"
        "\"outline\":{\"description\":\"Add an outer outline: a palette colour, or \\\"darkest\\\" (the darkest of the ramp of the colour it touches).\"},"
        "\"x\":{\"type\":\"integer\",\"description\":\"Canvas column of the left edge of the result (default: where the source's pixels start; a PNG: 0).\"},"
        "\"y\":{\"type\":\"integer\",\"description\":\"Canvas row of the top edge of the result.\"},"
        "\"scale\":{\"type\":\"integer\",\"minimum\":1,\"maximum\":32,\"description\":\"Magnification of the preview picture (default: automatic).\"},"
        "\"bake\":{\"type\":\"boolean\",\"default\":true,\"description\":\"Also draw the PNG (default true). False only writes the document.\"}}}",
        image_to_pixel_art, false);
}

}  // namespace fa::imgedit
