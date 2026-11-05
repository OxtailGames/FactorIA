// image.edit (fill, recolor, move, transform, delete, copy, cut on a selection) and image.paint (strokes). Both change the PNG of one
// layer (a pixels layer in place; another kind is turned into a pixels layer first, see image_edit.h) and bake the document.
#include <algorithm>
#include <cmath>
#include <format>

#include "fa/core/strings.h"
#include "fa/tooling/style_guide.h"
#include "fa/tooling/image_tile.h"
#include "image_edit.h"
#include "image_frames.h"
#include "util.h"

namespace fa::imgedit {

using assets_detail::arg_error;
using assets_detail::check_arg_keys;
using assets_detail::colour_arg;
using tooling_detail::arg_bool;
using tooling_detail::arg_string;

namespace {

std::uint8_t to_byte(double v) { return std::uint8_t(std::lround(std::clamp(v, 0.0, 255.0))); }

double num(const Json& o, const char* cmd, const std::string& base, const char* key, double lo, double hi, double def) {
    auto it = o.find(key);
    if (it == o.end() || it->is_null()) return def;
    if (!it->is_number() || it->get<double>() < lo || it->get<double>() > hi)
        arg_error(cmd, base + "/" + key, std::format("`{}` must be a number from {} to {}, got {}.", key, lo, hi, describe_json_value(*it)), "");
    return it->get<double>();
}

struct Hsv {
    double h, s, v;
};
Hsv rgb_to_hsv(double r, double g, double b) {  // 0..1
    const double mx = std::max({r, g, b}), mn = std::min({r, g, b}), d = mx - mn;
    double h = 0;
    if (d > 0) {
        if (mx == r) h = std::fmod((g - b) / d, 6.0);
        else if (mx == g) h = (b - r) / d + 2;
        else h = (r - g) / d + 4;
        h *= 60;
        if (h < 0) h += 360;
    }
    return {h, mx > 0 ? d / mx : 0, mx};
}
void hsv_to_rgb(const Hsv& c, double& r, double& g, double& b) {
    const double ch = c.v * c.s, hp = std::fmod(c.h, 360.0) / 60.0, x = ch * (1 - std::fabs(std::fmod(hp, 2.0) - 1)), m = c.v - ch;
    double r1 = 0, g1 = 0, b1 = 0;
    if (hp < 1) { r1 = ch; g1 = x; }
    else if (hp < 2) { r1 = x; g1 = ch; }
    else if (hp < 3) { g1 = ch; b1 = x; }
    else if (hp < 4) { g1 = x; b1 = ch; }
    else if (hp < 5) { r1 = x; b1 = ch; }
    else { r1 = ch; b1 = x; }
    r = r1 + m;
    g = g1 + m;
    b = b1 + m;
}

float sel_at(const Mask& sel, int cx, int cy) { return sel.at(cx, cy) / 255.0f; }

bool looks_like_index_path(const std::string& s) {
    return !s.empty() && std::all_of(s.begin(), s.end(), [](char c) { return std::isdigit((unsigned char)c) || c == '/'; });
}

bool project_pixel_art(const std::string& projectDir) { return load_style_guide(projectDir).guide.pixelArt.value_or(false); }

// ---- image.edit ------------------------------------------------------------------------------------------------------------

const std::vector<std::string> kActions = {"fill", "recolor", "move", "transform", "delete", "copy", "cut"};

Json layer_summary(const LayerRef& r) {
    return Json::object({{"index", r.indexPath}, {"pointer", r.pointer}, {"name", r.layer->value("name", std::string())}, {"kind", r.layer->value("kind", std::string())}});
}

Json image_edit(const std::string& projectDir, const Json& a) {
    const char* cmd = "image.edit";
    check_arg_keys(cmd, a, "", {"path", "selection", "layer", "action", "name", "bake", "frame", "onion"});
    DocFile d = open_doc(projectDir, arg_string(a, "path", true), cmd);
    FrameScope frameScope(projectDir, d.rel, d.json, a, cmd);
    const int W = d.json.value("width", 0), H = d.json.value("height", 0);
    if (!a.contains("selection") || !a["selection"].is_string())
        arg_error(cmd, "/selection", "`selection` is required: the name of a selection made with image.select (or \"all\").",
                  "Example: {\"selection\":\"sky\"}. Stored: " + (list_selections(projectDir, d.rel).empty() ? std::string("none yet") : join(list_selections(projectDir, d.rel), ", ")) + ".");
    const Mask sel = load_selection(projectDir, d.rel, a["selection"].get<std::string>(), W, H, cmd);
    if (!a.contains("layer") || a["layer"].is_null())
        arg_error(cmd, "/layer", "`layer` is required: the layer whose pixels change.", "Example: \"layer\":\"hero\". " + describe_layers(d.json, 12));
    LayerRef ref = find_layer(d.json, a["layer"], cmd);
    if (!a.contains("action") || !a["action"].is_object() || !a["action"].contains("type"))
        arg_error(cmd, "/action", "`action` is required: an object with `type`.",
                  "Types: " + join(kActions, ", ") + ". Example: {\"type\":\"fill\",\"color\":\"#ff0000\"}.");
    const Json& act = a["action"];
    std::string type = act["type"].is_string() ? act["type"].get<std::string>() : "";
    if (type == "recolour") type = "recolor";
    if (std::find(kActions.begin(), kActions.end(), type) == kActions.end())
        arg_error(cmd, "/action/type", "unknown action '" + type + "'.", did_you_mean(type, kActions) + " Types: " + join(kActions, ", ") + ".");
    const std::optional<Image> before = render_document_json(projectDir, d.json);
    assets_detail::require_usable_manifest(projectDir);
    std::vector<std::string> warnings;
    Json extra = Json::object({{"action", type}, {"layer", layer_summary(ref)}});
    const std::string nameArg = arg_string(a, "name", false);

    auto allowed = [&](std::vector<std::string> keys) {
        keys.push_back("type");
        check_arg_keys(cmd, act, "/action", keys);
    };

    if (type == "copy") {
        allowed({});
        Work w = open_work(projectDir, d.json, ref, cmd, false, true);
        ImagePatch p = image_patch_extract(w.img, w.ox, w.oy, sel);
        if (p.img.empty()) arg_error(cmd, "/selection", "the selection covers no visible pixel of the layer, so there is nothing to copy.", "Select where the layer has pixels (image.select by \"layer\" selects its shape).");
        for (const std::string& s : w.warnings) if (s.find("was a ") == std::string::npos) warnings.push_back(s);
        const std::string name = nameArg.empty() ? unique_layer_name(d.json, ref.layer->value("name", std::string("layer")) + " copy") : nameArg;
        if (const auto taken = layer_names(d.json); !nameArg.empty() && std::find(taken.begin(), taken.end(), name) != taken.end())
            arg_error(cmd, "/name", "a layer named '" + name + "' already exists.", "Pick another name.");
        const std::string path = add_pixels_layer(projectDir, d.rel, d.json, &ref, name, p.img, p.x, p.y, cmd, w.kind == "provider");
        if (FrameScope* fs = FrameScope::current()) fs->confine_new_layer(d.json, path);
        extra["newLayer"] = Json::object({{"index", path}, {"name", name}});
    } else if (type == "cut") {
        allowed({});
        Work w = open_work(projectDir, d.json, ref, cmd, false, true);
        ImagePatch p = image_patch_extract(w.img, w.ox, w.oy, sel);
        if (p.img.empty()) arg_error(cmd, "/selection", "the selection covers no visible pixel of the layer, so there is nothing to cut.", "Select where the layer has pixels (image.select by \"layer\" selects its shape).");
        image_patch_erase(w.img, w.ox, w.oy, sel);
        const std::string name = nameArg.empty() ? unique_layer_name(d.json, ref.layer->value("name", std::string("layer")) + " cut") : nameArg;
        if (const auto taken = layer_names(d.json); !nameArg.empty() && std::find(taken.begin(), taken.end(), name) != taken.end())
            arg_error(cmd, "/name", "a layer named '" + name + "' already exists.", "Pick another name.");
        commit_work(projectDir, d.rel, d.json, ref, w, cmd);
        for (const std::string& s : w.warnings) warnings.push_back(s);
        const bool ai = w.kind == "provider";
        const std::string path = add_pixels_layer(projectDir, d.rel, d.json, &ref, name, p.img, p.x, p.y, cmd, ai);
        if (FrameScope* fs = FrameScope::current()) fs->confine_new_layer(d.json, path);
        extra["newLayer"] = Json::object({{"index", path}, {"name", name}});
    } else if (type == "fill") {
        allowed({"color", "opacity"});
        if (!act.contains("color")) arg_error(cmd, "/action/color", "a fill needs `color`.", "Example: {\"type\":\"fill\",\"color\":\"#ff0000\"}.");
        const Color col = colour_arg(cmd, act["color"], "/action/color");
        const double opacity = num(act, cmd, "/action", "opacity", 0, 1, 1) * col.a;
        Work w = open_work(projectDir, d.json, ref, cmd, true, true);
        for (int y = 0; y < w.img.height; ++y)
            for (int x = 0; x < w.img.width; ++x) {
                const float s = sel_at(sel, w.ox + x, w.oy + y);
                if (s > 0) image_over_pixel(&w.img.rgba[(std::size_t(y) * w.img.width + x) * 4], col.r * 255.0, col.g * 255.0, col.b * 255.0, s * opacity);
            }
        commit_work(projectDir, d.rel, d.json, ref, w, cmd);
        for (const std::string& s : w.warnings) warnings.push_back(s);
    } else if (type == "delete") {
        allowed({});
        Work w = open_work(projectDir, d.json, ref, cmd, false, true);
        image_patch_erase(w.img, w.ox, w.oy, sel);
        commit_work(projectDir, d.rel, d.json, ref, w, cmd);
        for (const std::string& s : w.warnings) warnings.push_back(s);
    } else if (type == "recolor") {
        allowed({"hueShift", "saturation", "value", "from", "to", "tolerance", "keepShading"});
        const bool replace = act.contains("from") || act.contains("to");
        const bool hsv = act.contains("hueShift") || act.contains("saturation") || act.contains("value");
        if (replace && hsv) arg_error(cmd, "/action", "use either hueShift / saturation / value, or from + to, not both.", "Two calls do both.");
        if (!replace && !hsv) arg_error(cmd, "/action", "a recolor needs `hueShift` (degrees), `saturation` / `value` (-1..1), or `from` and `to` colours.",
                                         "Examples: {\"type\":\"recolor\",\"hueShift\":120} or {\"type\":\"recolor\",\"from\":\"#ff0000\",\"to\":\"#0000ff\",\"tolerance\":20}.");
        const double hue = num(act, cmd, "/action", "hueShift", -360, 360, 0), sat = num(act, cmd, "/action", "saturation", -1, 1, 0), val = num(act, cmd, "/action", "value", -1, 1, 0);
        const int tol = int(num(act, cmd, "/action", "tolerance", 0, 255, 16));
        const bool keep = act.contains("keepShading") && act["keepShading"] == true;
        Color from{}, to{};
        if (replace) {
            if (!act.contains("from") || !act.contains("to")) arg_error(cmd, "/action", "a colour replace needs both `from` and `to`.", "Example: {\"type\":\"recolor\",\"from\":\"#ff0000\",\"to\":\"#0000ff\"}.");
            from = colour_arg(cmd, act["from"], "/action/from");
            to = colour_arg(cmd, act["to"], "/action/to");
        }
        Work w = open_work(projectDir, d.json, ref, cmd, false, true);
        for (int y = 0; y < w.img.height; ++y)
            for (int x = 0; x < w.img.width; ++x) {
                std::uint8_t* p = &w.img.rgba[(std::size_t(y) * w.img.width + x) * 4];
                const float s = sel_at(sel, w.ox + x, w.oy + y);
                if (s <= 0 || !p[3]) continue;
                double r = p[0], g = p[1], b = p[2];
                double nr = r, ng = g, nb = b;
                if (replace) {
                    const int dist = std::max({std::abs(p[0] - int(std::lround(from.r * 255))), std::abs(p[1] - int(std::lround(from.g * 255))), std::abs(p[2] - int(std::lround(from.b * 255)))});
                    if (dist > tol) continue;
                    nr = to.r * 255;
                    ng = to.g * 255;
                    nb = to.b * 255;
                    if (keep) {
                        nr = std::clamp(nr + (r - from.r * 255), 0.0, 255.0);
                        ng = std::clamp(ng + (g - from.g * 255), 0.0, 255.0);
                        nb = std::clamp(nb + (b - from.b * 255), 0.0, 255.0);
                    }
                } else {
                    Hsv c = rgb_to_hsv(r / 255, g / 255, b / 255);
                    c.h = std::fmod(c.h + hue + 720.0, 360.0);
                    c.s = sat >= 0 ? c.s + (1 - c.s) * sat : c.s * (1 + sat);
                    c.v = val >= 0 ? c.v + (1 - c.v) * val : c.v * (1 + val);
                    hsv_to_rgb(c, nr, ng, nb);
                    nr *= 255;
                    ng *= 255;
                    nb *= 255;
                }
                p[0] = to_byte(r + (nr - r) * s);
                p[1] = to_byte(g + (ng - g) * s);
                p[2] = to_byte(b + (nb - b) * s);
            }
        commit_work(projectDir, d.rel, d.json, ref, w, cmd);
        for (const std::string& s : w.warnings) warnings.push_back(s);
    } else if (type == "move") {
        allowed({"dx", "dy", "copy", "moveSelection"});
        const double dx = num(act, cmd, "/action", "dx", -4096, 4096, 0), dy = num(act, cmd, "/action", "dy", -4096, 4096, 0);
        if (dx != std::floor(dx) || dy != std::floor(dy)) arg_error(cmd, "/action", "`dx` and `dy` are whole pixels.", "Use transform for a fractional move... or round them.");
        if (dx == 0 && dy == 0) arg_error(cmd, "/action", "a move needs `dx` and/or `dy` (pixels; positive is right and down).", "Example: {\"type\":\"move\",\"dx\":8,\"dy\":-4}.");
        Work w = open_work(projectDir, d.json, ref, cmd, true, true);
        ImagePatch p = image_patch_extract(w.img, w.ox, w.oy, sel);
        if (!act.contains("copy") || act["copy"] != true) image_patch_erase(w.img, w.ox, w.oy, sel);
        const int fromX = p.x, fromY = p.y;
        p.x += int(dx);
        p.y += int(dy);
        const TileGrid tiles = tile_grid_of(d.json);
        const std::size_t dropped = tiles.on ? image_patch_draw_wrapped(w.img, w.ox, w.oy, p, fromX, fromY, tiles) : image_patch_draw(w.img, w.ox, w.oy, p);
        if (dropped) warnings.push_back(std::format("{} moved pixels fell outside the {} and were dropped.", dropped, w.fixedRect ? "layer's box (a layer with masks keeps its box)" : "canvas"));
        commit_work(projectDir, d.rel, d.json, ref, w, cmd);
        for (const std::string& s : w.warnings) warnings.push_back(s);
        if (!act.contains("moveSelection") || act["moveSelection"] != false) {
            Mask moved(W, H);
            for (int y = 0; y < H; ++y)
                for (int x = 0; x < W; ++x)
                    moved.ref(x, y) = tiles.on ? sel.at(tiles.wrap_x(x - int(dx), tiles.cell_x(x)), tiles.wrap_y(y - int(dy), tiles.cell_y(y))) : sel.at(x - int(dx), y - int(dy));
            if (a["selection"].get<std::string>() != "all") {
                save_selection(projectDir, d.rel, a["selection"].get<std::string>(), moved);
                extra["selectionMoved"] = true;
            }
        }
    } else {  // transform
        allowed({"scale", "rotate", "flipH", "flipV", "filter", "pivot"});
        double sx = 1, sy = 1;
        if (act.contains("scale")) {
            const Json& sc = act["scale"];
            auto ok = [](const Json& v) { return v.is_number() && v.get<double>() >= 0.01 && v.get<double>() <= 32; };
            if (ok(sc)) sx = sy = sc.get<double>();
            else if (sc.is_array() && sc.size() == 2 && ok(sc[0]) && ok(sc[1])) { sx = sc[0].get<double>(); sy = sc[1].get<double>(); }
            else arg_error(cmd, "/action/scale", "`scale` is a number from 0.01 to 32, or [sx, sy], got " + describe_json_value(sc) + ".", "Example: \"scale\":2.");
        }
        const double rot = num(act, cmd, "/action", "rotate", -3600, 3600, 0);
        const bool fh = act.contains("flipH") && act["flipH"] == true, fv = act.contains("flipV") && act["flipV"] == true;
        if (sx == 1 && sy == 1 && rot == 0 && !fh && !fv)
            arg_error(cmd, "/action", "a transform needs `scale`, `rotate` (degrees, clockwise), `flipH` or `flipV`.", "Example: {\"type\":\"transform\",\"scale\":2,\"filter\":\"nearest\"}.");
        std::string filter = act.contains("filter") && act["filter"].is_string() ? act["filter"].get<std::string>() : "";
        if (filter.empty()) filter = project_pixel_art(projectDir) ? "nearest" : "bilinear";
        if (filter != "nearest" && filter != "bilinear") arg_error(cmd, "/action/filter", "unknown filter '" + filter + "'.", did_you_mean(filter, std::vector<std::string>{"nearest", "bilinear"}) + " nearest keeps hard pixels (pixel art), bilinear smooths.");
        Work w = open_work(projectDir, d.json, ref, cmd, true, true);
        ImagePatch p = image_patch_extract(w.img, w.ox, w.oy, sel);
        if (p.img.empty()) arg_error(cmd, "/selection", "the selection covers no visible pixel of the layer, so there is nothing to transform.", "Select where the layer has pixels.");
        double pvx = p.x + p.img.width / 2.0, pvy = p.y + p.img.height / 2.0;
        if (act.contains("pivot")) {
            const Json& pv = act["pivot"];
            if (!pv.is_array() || pv.size() != 2 || !pv[0].is_number() || !pv[1].is_number())
                arg_error(cmd, "/action/pivot", "expected [x, y] in canvas pixels, got " + describe_json_value(pv) + ".", "Example: \"pivot\":[16, 16]. Default: the middle of the selected pixels.");
            pvx = pv[0].get<double>();
            pvy = pv[1].get<double>();
        }
        image_patch_erase(w.img, w.ox, w.oy, sel);
        ImageTransform tf;
        tf.scaleX = sx;
        tf.scaleY = sy;
        tf.rotate = rot;
        tf.flipH = fh;
        tf.flipV = fv;
        tf.pivotX = pvx;
        tf.pivotY = pvy;
        tf.nearest = filter == "nearest";
        Result<ImagePatch> tr = image_patch_transform(p, tf);
        if (!tr.ok()) fail("invalid_argument", "image.edit /action: " + tr.error().message, tr.error().hint);
        const ImagePatch& t = *tr;
        const std::size_t dropped = image_patch_draw(w.img, w.ox, w.oy, t);
        if (tile_grid_of(d.json).on)
            warnings.push_back("Tile mode is on but a transform does not wrap around the tile edges: check the seams with image.tile.check afterwards.");
        if (dropped) warnings.push_back(std::format("{} transformed pixels fell outside the {} and were dropped.", dropped, w.fixedRect ? "layer's box (a layer with masks keeps its box)" : "canvas"));
        commit_work(projectDir, d.rel, d.json, ref, w, cmd);
        for (const std::string& s : w.warnings) warnings.push_back(s);
        extra["filter"] = filter;
        extra["pivot"] = Json::array({pvx, pvy});
    }
    Json out = commit_document(projectDir, d.rel, d.json, before, arg_bool(a, "bake", true), extra, warnings, cmd);
    if (!out["changed"].get<bool>()) {
        Json w = out.contains("warnings") ? out["warnings"] : Json::array();
        w.push_back("The picture did not change: the selection may be empty, or lie where the layer has no pixels or is hidden.");
        out["warnings"] = w;
    }
    out["nextSteps"] = Json::array({"Look at the picture in this result; undo is the document's history in your VCS: the PNG of a pixels layer was edited in place."});
    return out;
}

// ---- image.paint -----------------------------------------------------------------------------------------------------------

Json image_paint(const std::string& projectDir, const Json& a) {
    const char* cmd = "image.paint";
    check_arg_keys(cmd, a, "", {"path", "layer", "strokes", "create", "selection", "bake", "frame", "onion"});
    DocFile d = open_doc(projectDir, arg_string(a, "path", true), cmd);
    FrameScope frameScope(projectDir, d.rel, d.json, a, cmd);
    const int W = d.json.value("width", 0), H = d.json.value("height", 0);
    if (!a.contains("layer") || a["layer"].is_null())
        arg_error(cmd, "/layer", "`layer` is required: the layer to paint on (a name or index path).", "Example: \"layer\":\"paint\" with \"create\":true to make it. " + describe_layers(d.json, 12));
    if (!a.contains("strokes") || !a["strokes"].is_array() || a["strokes"].empty())
        arg_error(cmd, "/strokes", "`strokes` is required: a list of strokes {points, size, color, hardness?, opacity?, erase?}.",
                  "Example: [{\"points\":[[4,4],[40,4]],\"size\":3,\"color\":\"#ff0000\"}].");
    if (a["strokes"].size() > 1000) arg_error(cmd, "/strokes", "at most 1000 strokes per call.", "Split them over several calls.");
    Mask sel;
    const bool hasSel = a.contains("selection") && a["selection"].is_string();
    if (hasSel) sel = load_selection(projectDir, d.rel, a["selection"].get<std::string>(), W, H, cmd);
    const std::optional<Image> before = render_document_json(projectDir, d.json);
    assets_detail::require_usable_manifest(projectDir);
    std::vector<std::string> warnings;
    Json extra = Json::object();

    LayerRef ref;
    const bool create = arg_bool(a, "create", false);
    if (!try_find_layer(d.json, a["layer"], cmd, "layer", ref)) {
        if (create && a["layer"].is_string() && !a["layer"].get<std::string>().empty() && !looks_like_index_path(a["layer"].get<std::string>())) {
            const std::string name = a["layer"].get<std::string>();
            Image empty;
            empty.width = W;
            empty.height = H;
            empty.rgba.assign(std::size_t(W) * H * 4, 0);
            const std::string idx = add_pixels_layer(projectDir, d.rel, d.json, nullptr, name, empty, 0, 0, cmd, false);
            if (FrameScope* fs = FrameScope::current()) fs->confine_new_layer(d.json, idx);
            ref = find_layer(d.json, Json(idx), cmd);
            extra["createdLayer"] = Json::object({{"index", idx}, {"name", name}});
        } else {
            try {
                find_layer(d.json, a["layer"], cmd);
            } catch (const CommandError& e) {
                throw CommandError(e.code, e.what(), e.hint + " To paint on a new layer, pass \"create\":true with a layer name.");
            }
        }
    }
    extra["layer"] = layer_summary(ref);
    Work w = open_work(projectDir, d.json, ref, cmd, true, true);
    const TileGrid tiles = tile_grid_of(d.json);

    std::size_t stamped = 0;
    for (std::size_t si = 0; si < a["strokes"].size(); ++si) {
        const Json& st = a["strokes"][si];
        const std::string base = "/strokes/" + std::to_string(si);
        if (!st.is_object()) arg_error(cmd, base, "a stroke is an object {points, size, color, ...}.", "Example: {\"points\":[[4,4],[40,4]],\"size\":3,\"color\":\"#ff0000\"}.");
        check_arg_keys(cmd, st, base, {"points", "size", "hardness", "color", "opacity", "erase", "spacing"});
        if (!st.contains("points") || !st["points"].is_array() || st["points"].empty())
            arg_error(cmd, base + "/points", "`points` is required: [[x, y], ...] in canvas pixels (one point is a dab).", "Example: \"points\":[[4,4],[40,4]].");
        if (st["points"].size() > 20000) arg_error(cmd, base + "/points", "at most 20000 points per stroke.", "Split the stroke.");
        std::vector<std::pair<double, double>> pts;
        for (std::size_t k = 0; k < st["points"].size(); ++k) {
            const Json& pt = st["points"][k];
            if (!pt.is_array() || pt.size() != 2 || !pt[0].is_number() || !pt[1].is_number())
                arg_error(cmd, base + "/points/" + std::to_string(k), "a point is [x, y], got " + describe_json_value(pt) + ".", "Example: [12, 30].");
            pts.emplace_back(pt[0].get<double>(), pt[1].get<double>());
        }
        const double size = num(st, cmd, base, "size", 0.5, 512, 4);
        const double hardness = num(st, cmd, base, "hardness", 0, 1, 1);
        const double opacity = num(st, cmd, base, "opacity", 0, 1, 1);
        const double spacing = std::max(0.25, num(st, cmd, base, "spacing", 0.01, 512, std::max(1.0, size * 0.2)));
        const bool erase = st.contains("erase") && st["erase"] == true;
        Color col{0, 0, 0, 1};
        if (!erase) {
            if (!st.contains("color")) arg_error(cmd, base + "/color", "a stroke needs `color` (or `erase: true`).", "Example: \"color\":\"#ff0000\".");
            col = colour_arg(cmd, st["color"], base + "/color");
        }
        ImageBrush brush;
        brush.size = size;
        brush.hardness = hardness;
        brush.opacity = opacity;
        brush.spacing = spacing;
        brush.color = col;
        brush.erase = erase;
        stamped += paint_image_stroke(w.img, w.ox, w.oy, pts, brush, hasSel ? &sel : nullptr, &tiles);
    }
    commit_work(projectDir, d.rel, d.json, ref, w, cmd);
    for (const std::string& s : w.warnings) warnings.push_back(s);
    extra["strokes"] = a["strokes"].size();
    extra["stamps"] = stamped;
    Json out = commit_document(projectDir, d.rel, d.json, before, arg_bool(a, "bake", true), extra, warnings, cmd);
    if (!out["changed"].get<bool>()) {
        Json wr = out.contains("warnings") ? out["warnings"] : Json::array();
        wr.push_back("The picture did not change: the strokes may lie outside the canvas, outside the selection, or under an opaque layer above.");
        out["warnings"] = wr;
    }
    return out;
}

}  // namespace

void register_pixel_commands(CommandRegistry& registry, const std::string& projectDir) {
    {
        CommandInfo info;
        info.name = "image.edit";
        info.category = "assets";
        info.readOnly = false;
        info.summary = "Change the selected pixels of one layer of an image document: fill, recolor, move, transform (scale, rotate, flip), delete, copy or cut to a new layer.";
        info.description =
            "Applies `action` to the pixels of `layer` inside the stored `selection` (made with image.select; \"all\" is the whole canvas). Actions: "
            "fill {color, opacity?}; recolor {hueShift degrees, saturation -1..1, value -1..1} or {from, to, tolerance?, keepShading?}; "
            "move {dx, dy, copy?} (whole pixels; the selection moves along unless moveSelection is false); "
            "transform {scale number or [sx,sy], rotate degrees clockwise, flipH, flipV, filter nearest|bilinear, pivot [x,y]} (the selected pixels are lifted, transformed around the pivot "
            "- default their middle - and put back; the default filter is nearest when the project's style guide says pixelArt, else bilinear); "
            "delete (the selected pixels become transparent); copy and cut {name?} (the selected pixels become a new pixels layer above `layer`; cut also clears them). "
            "POLICY FOR OTHER LAYER KINDS: a pixels layer's PNG is edited in place (an AI-generated image keeps that mark, the edit is added to its provenance). A shape, gradient, text or "
            "other non-pixel layer is first rasterized: it becomes a pixels layer (its masks, adjustments and effects are baked into the pixels, its blend, opacity and visibility stay) with a new PNG "
            "in <document>.layers/ and a warning says so. Groups and adjustment layers cannot be edited this way. A layer with masks keeps its box (the masks are in its own pixels), so pixels moved outside it are dropped "
            "(a warning counts them); other layers grow to hold what you move into the canvas. Result: the baked document plus `region` {x,y,width,height} of the changed pixels, `changed` and the picture as `$image`. "
            "Example: {\"path\":\"assets/art/hero.image.json\",\"selection\":\"cape\",\"layer\":\"hero\",\"action\":{\"type\":\"recolor\",\"hueShift\":120}}";
        info.inputSchema = Json::parse(R"({"type":"object","required":["path","selection","layer","action"],"properties":{
          "path":{"type":"string","description":"The image document, project-relative, ending in .image.json."},
          "selection":{"type":"string","description":"The stored selection to act on (image.select), or \"all\"."},
          "layer":{"description":"The layer to change: its name or an index path like \"1/0\"."},
          "action":{"type":"object","required":["type"],"description":"What to do. type: fill, recolor, move, transform, delete, copy, cut. See the command description for each action's fields.","properties":{
            "type":{"type":"string","enum":["fill","recolor","move","transform","delete","copy","cut"],"description":"The action."},
            "color":{"description":"fill: the colour."},
            "opacity":{"type":"number","minimum":0,"maximum":1,"description":"fill: strength 0..1."},
            "hueShift":{"type":"number","description":"recolor: degrees added to the hue."},
            "saturation":{"type":"number","minimum":-1,"maximum":1,"description":"recolor: -1 removes colour, 1 saturates fully."},
            "value":{"type":"number","minimum":-1,"maximum":1,"description":"recolor: -1 black, 1 white-ish brightness."},
            "from":{"description":"recolor: the colour to replace."},
            "to":{"description":"recolor: the colour that replaces it."},
            "tolerance":{"type":"number","minimum":0,"maximum":255,"description":"recolor from/to: the largest channel difference that matches (default 16)."},
            "keepShading":{"type":"boolean","description":"recolor from/to: keep each pixel's difference from `from` so shading survives."},
            "dx":{"type":"integer","description":"move: pixels to the right (negative = left)."},
            "dy":{"type":"integer","description":"move: pixels down (negative = up)."},
            "copy":{"type":"boolean","description":"move: leave the original pixels in place."},
            "moveSelection":{"type":"boolean","description":"move: move the stored selection along (default true)."},
            "scale":{"description":"transform: a number 0.01..32, or [sx, sy]."},
            "rotate":{"type":"number","description":"transform: degrees, clockwise."},
            "flipH":{"type":"boolean","description":"transform: mirror left-right."},
            "flipV":{"type":"boolean","description":"transform: mirror top-bottom."},
            "filter":{"type":"string","enum":["nearest","bilinear"],"description":"transform: nearest keeps hard pixels; bilinear smooths. Default: nearest for a pixelArt project."},
            "pivot":{"type":"array","items":{"type":"number"},"description":"transform: [x, y] canvas point the transform turns around."}}},
          "name":{"type":"string","description":"copy / cut: the new layer's name (default: '<layer> copy' / '<layer> cut')."},
          "bake":{"type":"boolean","default":true,"description":"Bake the document to its PNG after the edit."}}})");
        add_frame_support(info, "to edit");
        registry.add(info, [projectDir](const Json& args) { return image_edit(projectDir, args); });
    }
    {
        CommandInfo info;
        info.name = "image.paint";
        info.category = "assets";
        info.readOnly = false;
        info.summary = "Paint round-brush strokes onto a pixels layer of an image document (deterministic stamping), creating the layer's PNG when asked.";
        info.description =
            "Each stroke {points [[x,y],...], size, color, hardness?, opacity?, erase?, spacing?} stamps a round brush of diameter `size` along the polyline: one stamp at the first point, then one every `spacing` "
            "pixels (default a fifth of the size, at least 1) of arc length, and one at the last point. A pixel gets the largest coverage any stamp of the stroke gives it, so a stroke does not darken "
            "where it crosses itself; `opacity` then scales the whole stroke, `hardness` 1 is a hard edge (half a pixel anti-aliased) and lower values fade from hardness*radius to the edge. "
            "`erase: true` lowers the alpha instead of painting. Strokes apply in order and the same input always gives the same pixels (no randomness, no pressure). "
            "`layer` is a name or an index path; an unknown name with `create: true` makes a new empty pixels layer at the top of the document. A non-pixel layer is rasterized first, as in image.edit "
            "(a warning says so). `selection` limits the painting to a stored selection. Coordinates are canvas pixels; the layer grows to hold what is painted (a layer with masks keeps its box). "
            "Result: the baked document, `region`, `changed`, `stamps` and the picture as `$image`. "
            "Example: {\"path\":\"assets/art/hero.image.json\",\"layer\":\"paint\",\"create\":true,\"strokes\":[{\"points\":[[4,4],[40,20]],\"size\":3,\"color\":\"#ff0000\"}]}";
        info.inputSchema = Json::parse(R"({"type":"object","required":["path","layer","strokes"],"properties":{
          "path":{"type":"string","description":"The image document, project-relative, ending in .image.json."},
          "layer":{"description":"The layer to paint on: its name or an index path like \"1/0\"."},
          "create":{"type":"boolean","default":false,"description":"When no layer has that name, create an empty pixels layer with it at the top."},
          "selection":{"type":"string","description":"A stored selection (image.select) that limits where the strokes paint."},
          "strokes":{"type":"array","minItems":1,"maxItems":1000,"description":"The strokes, painted in order.","items":{"type":"object","required":["points"],"properties":{
            "points":{"type":"array","items":{"type":"array","items":{"type":"number"}},"description":"[[x, y], ...] canvas pixels along the stroke; one point is a dab."},
            "size":{"type":"number","minimum":0.5,"maximum":512,"default":4,"description":"Brush diameter in pixels."},
            "hardness":{"type":"number","minimum":0,"maximum":1,"default":1,"description":"1 = hard edge; lower fades from hardness*radius to the edge."},
            "color":{"description":"The paint colour (\"#rrggbb\", a CSS name or [r,g,b,a]). Not needed when erase is true."},
            "opacity":{"type":"number","minimum":0,"maximum":1,"default":1,"description":"Strength of the whole stroke."},
            "erase":{"type":"boolean","default":false,"description":"Lower the alpha instead of painting."},
            "spacing":{"type":"number","minimum":0.01,"maximum":512,"description":"Pixels of arc length between stamps (default size/5, at least 1)."}}}},
          "bake":{"type":"boolean","default":true,"description":"Bake the document to its PNG after painting."}}})");
        add_frame_support(info, "to paint on");
        registry.add(info, [projectDir](const Json& args) { return image_paint(projectDir, args); });
    }
}

}  // namespace fa::imgedit
