// image.pixel, image.draw, image.palette and image.layer.convert: indexed pixel-art layers (docs/IMAGES.md, "Pixel art").
// An indexed layer stores palette indices as text rows; these commands edit the rows by exact pixels and shapes (no anti-aliasing),
// then hand the document to save_image_document like every image.* command. The algorithms are in fa/tooling/pixel_art.h.
#include <algorithm>
#include <cmath>
#include <format>
#include <set>

#include "assets_internal.h"
#include "fa/core/asset_manifest.h"
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

namespace indexed {

bool looks_like_index_path(const std::string& s) {
    return !s.empty() && std::all_of(s.begin(), s.end(), [](char c) { return std::isdigit((unsigned char)c) || c == '/'; });
}

Json layer_summary(const LayerRef& r) {
    return Json::object({{"index", r.indexPath}, {"pointer", r.pointer}, {"name", r.layer->value("name", std::string())}, {"kind", r.layer->value("kind", std::string())}});
}

std::string layer_label(const LayerRef& r) {
    const std::string name = r.layer->value("name", std::string());
    return "layer '" + (name.empty() ? r.indexPath : name) + "' (" + r.indexPath + ")";
}

// ---- the palette of a document ------------------------------------------------------------------------------------------------

// The palette the document's indexed layers use. `force` resolves the palette even when no layer is indexed yet (the style palette is
// otherwise only looked up for a document that has an indexed layer).
PixelPalette load_doc_palette(const std::string& projectDir, const std::string& rel, const Json& docJson, bool force, const char* cmd) {
    Json probe = docJson;
    if (force && !probe.contains("palette") && probe.contains("layers") && probe["layers"].is_array())
        probe["layers"].push_back(Json::object({{"kind", "indexed"}, {"width", 1}, {"height", 1}}));
    auto parsed = parse_image_document(probe, rel, projectDir);
    if (!parsed.ok()) fail("invalid_argument", parsed.error().message, parsed.error().hint);
    (void)cmd;
    return parsed->palette;
}

Json palette_entries_json(const PixelPalette& pal) {
    Json list = Json::array();
    for (const auto& e : pal.entries) {
        const std::string hex = std::format("#{:02x}{:02x}{:02x}", e.rgb[0], e.rgb[1], e.rgb[2]);
        list.push_back(e.name.empty() ? Json(hex) : Json::object({{"name", e.name}, {"color", hex}}));
    }
    return list;
}

// Writes the palette into the document when it has none (so the indices keep their meaning when the style palette changes later).
bool pin_palette(Json& docJson, const PixelPalette& pal) {
    if (docJson.contains("palette")) return false;
    docJson["palette"] = palette_entries_json(pal);
    return true;
}

Json ramps_json(const PixelPalette& pal) {
    Json out = Json::array();
    for (const auto& ramp : pal.ramps) {
        Json r = Json::array();
        for (int i : ramp) r.push_back(pal.label(i));
        out.push_back(std::move(r));
    }
    return out;
}

// ---- the preview: the picture magnified with hard pixels ----------------------------------------------------------------------

Image upscale_nearest(const Image& src, int scale) {
    Image out;
    out.width = src.width * scale;
    out.height = src.height * scale;
    out.rgba.resize(std::size_t(out.width) * out.height * 4);
    for (int y = 0; y < out.height; ++y)
        for (int x = 0; x < out.width; ++x)
            std::copy_n(&src.rgba[(std::size_t(y / scale) * src.width + x / scale) * 4], 4, &out.rgba[(std::size_t(y) * out.width + x) * 4]);
    return out;
}

// Replaces the result's `$image` with the picture magnified by whole pixels (so an AI sees each pixel), written to
// .factoria/previews/<document>.png. `scale` 0 = automatic: as large as fits 512 pixels, at most 32x.
void attach_preview(const std::string& projectDir, const std::string& rel, const Json& docJson, Json& out, int scale) {
    if (!out.contains("$image")) return;
    auto picture = render_preview_json(projectDir, docJson);   // the frame the command works on, with its onion skin
    if (!picture) return;
    if (scale <= 0) scale = std::clamp(512 / std::max(1, std::max(picture->width, picture->height)), 1, 32);
    if (std::size_t(picture->width) * scale > 4096 || std::size_t(picture->height) * scale > 4096) scale = std::max(1, 4096 / std::max(picture->width, picture->height));
    out["previewScale"] = scale;
    if (scale == 1) return;
    const Image big = upscale_nearest(*picture, scale);
    const std::string previewRel = ".factoria/previews/" + rel + ".png";
    auto path = resolve_project_path(projectDir, previewRel);
    if (!path.ok()) return;
    const auto png = encode_png(big);
    if (!tooling_detail::write_file(*path, std::string_view(reinterpret_cast<const char*>(png.data()), png.size()), nullptr)) return;
    out["$image"] = Json::object({{"path", path->string()}, {"mimeType", "image/png"}});
    out["preview"] = previewRel;
}

int scale_arg(const Json& a, const char* cmd) {
    auto it = a.find("scale");
    if (it == a.end() || it->is_null()) return 0;
    if (!it->is_number_integer() || it->get<int>() < 1 || it->get<int>() > 32)
        arg_error(cmd, "/scale", "`scale` must be a whole number from 1 to 32, got " + describe_json_value(*it) + ".", "It magnifies the preview picture by whole pixels; leave it out for an automatic size.");
    return it->get<int>();
}

// ---- the layer to draw on -----------------------------------------------------------------------------------------------------


Target open_target(const std::string& projectDir, DocFile& d, const Json& a, const char* cmd) {
    Target t;
    const int W = d.json.value("width", 0), H = d.json.value("height", 0);
    if (!a.contains("layer") || a["layer"].is_null())
        arg_error(cmd, "/layer", "`layer` is required: the indexed layer to draw on (a name or index path).",
                  "Example: \"layer\":\"sprite\" with \"create\":true to make it. " + describe_layers(d.json, 12));
    const bool create = arg_bool(a, "create", false);
    if (!try_find_layer(d.json, a["layer"], cmd, "layer", t.ref)) {
        const bool nameLike = a["layer"].is_string() && !a["layer"].get<std::string>().empty() && !looks_like_index_path(a["layer"].get<std::string>());
        if (create && nameLike) {
            const std::string name = a["layer"].get<std::string>();
            d.json["layers"].push_back(Json::object({{"kind", "indexed"}, {"name", name}}));
            const std::string idx = std::to_string(d.json["layers"].size() - 1);
            if (FrameScope* fs = FrameScope::current()) fs->confine_new_layer(d.json, idx);
            t.ref = find_layer(d.json, Json(idx), cmd);
            t.extra["createdLayer"] = Json::object({{"index", idx}, {"name", name}});
        } else {
            try {
                find_layer(d.json, a["layer"], cmd);
            } catch (const CommandError& e) {
                throw CommandError(e.code, e.what(), e.hint + " To draw on a new indexed layer, pass \"create\":true with a layer name.");
            }
        }
    }
    const std::string kind = t.ref.layer->value("kind", std::string());
    if (kind != "indexed")
        arg_error(cmd, "/layer", layer_label(t.ref) + " is a " + kind + " layer, not an indexed one: this command writes palette indices.",
                  "Draw on an indexed layer (create one: \"create\":true with a new name, or image.layer.add {\"layer\":{\"kind\":\"indexed\"}}), or turn this layer into one: image.layer.convert {\"layer\":\"" +
                      t.ref.layer->value("name", t.ref.indexPath) + "\",\"to\":\"indexed\"}.");
    t.pal = load_doc_palette(projectDir, d.rel, d.json, false, cmd);
    if (t.pal.empty()) fail("invalid_argument", "The document has no palette to draw with.", "Add one with image.palette {\"palette\":[\"#000000\",\"#ffffff\"]} or set style.palette in assets.json.");
    if (pin_palette(d.json, t.pal))
        t.extra["palettePinned"] = "The style palette was copied into the document's `palette`, so the indices keep their colours if assets.json changes. Edit it with image.palette.";
    t.ref = find_layer(d.json, Json(t.ref.indexPath), cmd);   // adding a key to the document may have moved the layer
    const Json& L = *t.ref.layer;
    if (L.contains("rows") && L["rows"].is_array() && !L["rows"].empty()) {
        std::vector<std::string> rows;
        for (const Json& r : L["rows"]) rows.push_back(r.get<std::string>());
        auto g = index_grid_from_rows(rows, t.pal.size());
        if (!g.ok()) fail("invalid_argument", layer_label(t.ref) + ": " + g.error().message, g.error().hint);
        t.grid = std::move(*g);
    } else {
        t.grid = IndexGrid(L.value("width", W), L.value("height", H));
    }
    t.ox = t.ref.parentX + L.value("x", 0);
    t.oy = t.ref.parentY + L.value("y", 0);
    return t;
}

void store_grid(Target& t) {
    Json& L = *t.ref.layer;
    L["rows"] = index_grid_rows(t.grid);
    L.erase("width");
    L.erase("height");
}

// ---- colours of a command --------------------------------------------------------------------------------------------------------

// What to write: a palette index (or transparent), or a step along the ramp of what is there / of an index.
struct Paint {
    int index = -1;
    int step = 0;
    bool relative = false;   // {"step": n} alone: n steps from the colour already in the pixel
    bool transparent() const { return !relative && index < 0; }
};

Paint parse_paint(const char* cmd, const Json& ref, const std::string& ptr, const PixelPalette& pal, bool allowTransparent = true) {
    Paint p;
    if (ref.is_object()) {
        check_arg_keys(cmd, ref, ptr, {"color", "step"});
        if (ref.contains("step")) {
            if (!ref["step"].is_number_integer() || std::abs(ref["step"].get<int>()) > 16)
                arg_error(cmd, ptr + "/step", "`step` must be a whole number from -16 to 16 (negative = darker, positive = lighter), got " + describe_json_value(ref["step"]) + ".", "Example: {\"step\": -1} shades one step darker; {\"color\": \"skin\", \"step\": 1} is the colour one step lighter than skin.");
            p.step = ref["step"].get<int>();
        }
        if (!ref.contains("color")) {
            if (!ref.contains("step")) arg_error(cmd, ptr, "a colour object needs `color`, `step` or both.", "Example: {\"color\":\"skin\",\"step\":-1}.");
            p.relative = true;
            return p;
        }
        auto found = pixel_palette_find(pal, ref["color"], allowTransparent);
        if (!found.ok()) arg_error(cmd, ptr + "/color", found.error().message, found.error().hint);
        p.index = *found;
        return p;
    }
    auto found = pixel_palette_find(pal, ref, allowTransparent);
    if (!found.ok()) arg_error(cmd, ptr, found.error().message, found.error().hint);
    p.index = *found;
    return p;
}

struct Painter {
    Target& t;
    std::size_t set = 0, outside = 0;
    std::size_t skipped = 0;    // relative steps on transparent pixels

    // Writes one pixel (canvas coordinates). `before` is the grid the shape started from (relative steps read it).
    void put(int x, int y, const Paint& paint, const IndexGrid* before) {
        const int gx = x - t.ox, gy = y - t.oy;
        if (!t.grid.inside(gx, gy)) {
            ++outside;
            return;
        }
        int base = paint.index;
        if (paint.relative) {
            base = (before ? *before : t.grid).at(gx, gy);
            if (base < 0) {
                ++skipped;
                return;
            }
        }
        const int value = paint.step != 0 && base >= 0 ? t.pal.step(base, paint.step) : base;
        t.grid.set(gx, gy, value);
        ++set;
    }
    void put_all(const std::vector<PixelPoint>& pts, const Paint& paint) {
        if (paint.relative) {
            const IndexGrid before = t.grid;
            std::set<PixelPoint> done;
            for (const PixelPoint& p : pts)
                if (done.insert(p).second) put(p.x, p.y, paint, &before);
        } else {
            for (const PixelPoint& p : pts) put(p.x, p.y, paint, nullptr);
        }
    }
};

int whole(const char* cmd, const Json& v, const std::string& ptr) {
    if (!v.is_number_integer() || std::llabs(v.get<long long>()) > 1000000)
        arg_error(cmd, ptr, "pixel coordinates are whole numbers, got " + describe_json_value(v) + ".", "Example: 12. There is no anti-aliasing or sub-pixel position: every pixel is exact.");
    return int(v.get<long long>());
}

PixelPoint point_arg(const char* cmd, const Json& v, const std::string& ptr) {
    if (!v.is_array() || v.size() != 2) arg_error(cmd, ptr, "a point is [x, y], got " + describe_json_value(v) + ".", "Example: [12, 30].");
    return {whole(cmd, v[0], ptr + "/0"), whole(cmd, v[1], ptr + "/1")};
}

std::vector<PixelPoint> points_arg(const char* cmd, const Json& v, const std::string& ptr, std::size_t minCount) {
    if (!v.is_array() || v.size() < minCount || v.size() > 20000)
        arg_error(cmd, ptr, std::format("`points` must be a list of at least {} points [[x, y], ...] (at most 20000), got {}.", minCount, describe_json_value(v)), "Example: [[2,2],[12,2],[7,10]].");
    std::vector<PixelPoint> pts;
    for (std::size_t i = 0; i < v.size(); ++i) pts.push_back(point_arg(cmd, v[i], ptr + "/" + std::to_string(i)));
    return pts;
}

Json finish(const std::string& projectDir, DocFile& d, Target& t, const std::optional<Image>& before, const Json& a, const char* cmd, Json extra, const Painter& painter) {
    store_grid(t);
    for (auto it = t.extra.begin(); it != t.extra.end(); ++it) extra[it.key()] = it.value();
    extra["layer"] = layer_summary(t.ref);
    extra["pixelsSet"] = painter.set;
    std::vector<std::string> warnings = t.warnings;
    if (painter.outside)
        warnings.push_back(std::format("{} pixel{} lay outside the layer's box ({} x {} at {}, {}) and {} dropped.", painter.outside, painter.outside == 1 ? "" : "s", t.grid.w, t.grid.h, t.ox, t.oy,
                                       painter.outside == 1 ? "was" : "were"));
    if (painter.skipped) warnings.push_back(std::format("{} transparent pixel{} had no colour to step from and stayed transparent.", painter.skipped, painter.skipped == 1 ? "" : "s"));
    const bool bake = arg_bool(a, "bake", true);
    Json out = commit_document(projectDir, d.rel, d.json, before, bake, extra, warnings, cmd);
    if (bake) attach_preview(projectDir, d.rel, d.json, out, scale_arg(a, cmd));
    if (!out["changed"].get<bool>()) {
        Json wr = out.contains("warnings") ? out["warnings"] : Json::array();
        wr.push_back("The picture did not change: the pixels already had these colours, lay outside the canvas, or a layer above hides them.");
        out["warnings"] = wr;
    }
    return out;
}

// ---- image.pixel -------------------------------------------------------------------------------------------------------------------

Json image_pixel(const std::string& projectDir, const Json& a) {
    const char* cmd = "image.pixel";
    check_arg_keys(cmd, a, "", {"path", "layer", "pixels", "runs", "stamp", "create", "scale", "bake", "frame", "onion"});
    DocFile d = open_doc(projectDir, arg_string(a, "path", true), cmd);
    FrameScope frameScope(projectDir, d.rel, d.json, a, cmd);
    if (!a.contains("pixels") && !a.contains("runs") && !a.contains("stamp"))
        arg_error(cmd, "", "give at least one of `pixels` [[x, y, colour], ...], `runs` [[x, y, length, colour], ...] or `stamp` {x, y, rows}.",
                  "Example: {\"layer\":\"sprite\",\"create\":true,\"pixels\":[[3,4,\"skin\"],[4,4,2]],\"runs\":[[2,6,5,\"outline\"]]}.");
    const std::optional<Image> before = render_document_json(projectDir, d.json);
    assets_detail::require_usable_manifest(projectDir);
    Target t = open_target(projectDir, d, a, cmd);
    Painter painter{t};
    if (a.contains("pixels")) {
        const Json& list = a["pixels"];
        if (!list.is_array() || list.size() > 200000)
            arg_error(cmd, "/pixels", "`pixels` must be a list of [x, y, colour] (at most 200000), got " + describe_json_value(list) + ".", "Example: [[3,4,\"skin\"],[4,4,2],[5,4,null]] (null is transparent).");
        for (std::size_t i = 0; i < list.size(); ++i) {
            const std::string ptr = "/pixels/" + std::to_string(i);
            const Json& e = list[i];
            if (!e.is_array() || e.size() != 3) arg_error(cmd, ptr, "a pixel is [x, y, colour], got " + describe_json_value(e) + ".", "Example: [3, 4, \"skin\"]; the colour is a palette index, name or colour, null = transparent.");
            const Paint paint = parse_paint(cmd, e[2], ptr + "/2", t.pal);
            painter.put_all({{whole(cmd, e[0], ptr + "/0"), whole(cmd, e[1], ptr + "/1")}}, paint);
        }
    }
    if (a.contains("runs")) {
        const Json& list = a["runs"];
        if (!list.is_array() || list.size() > 100000)
            arg_error(cmd, "/runs", "`runs` must be a list of [x, y, length, colour] (at most 100000), got " + describe_json_value(list) + ".", "Example: [[2,6,5,\"outline\"]] draws 5 pixels to the right from (2, 6).");
        for (std::size_t i = 0; i < list.size(); ++i) {
            const std::string ptr = "/runs/" + std::to_string(i);
            const Json& e = list[i];
            if (!e.is_array() || e.size() != 4) arg_error(cmd, ptr, "a run is [x, y, length, colour], got " + describe_json_value(e) + ".", "Example: [2, 6, 5, \"outline\"].");
            const int len = whole(cmd, e[2], ptr + "/2");
            if (len < 1 || len > kImageDocMaxSide) arg_error(cmd, ptr + "/2", "a run's length is 1 to 4096 pixels, got " + std::to_string(len) + ".", "Runs go to the right; use several runs for several rows.");
            const Paint paint = parse_paint(cmd, e[3], ptr + "/3", t.pal);
            std::vector<PixelPoint> pts;
            const int x0 = whole(cmd, e[0], ptr + "/0"), y0 = whole(cmd, e[1], ptr + "/1");
            for (int k = 0; k < len; ++k) pts.push_back({x0 + k, y0});
            painter.put_all(pts, paint);
        }
    }
    if (a.contains("stamp")) {
        const Json& st = a["stamp"];
        if (!st.is_object()) arg_error(cmd, "/stamp", "`stamp` must be {x, y, rows, clear?}, got " + describe_json_value(st) + ".", "Example: {\"x\":4,\"y\":2,\"rows\":[\".11.\",\"1221\",\".11.\"]}.");
        check_arg_keys(cmd, st, "/stamp", {"x", "y", "rows", "clear"});
        if (!st.contains("rows") || !st["rows"].is_array() || st["rows"].empty())
            arg_error(cmd, "/stamp/rows", "`rows` is required: a list of equally long strings, one character per pixel.", "'.' is transparent, 0-9a-zA-Z... are palette indices. Example: [\".11.\",\"1221\",\".11.\"].");
        std::vector<std::string> rows;
        for (std::size_t i = 0; i < st["rows"].size(); ++i) {
            if (!st["rows"][i].is_string()) arg_error(cmd, "/stamp/rows/" + std::to_string(i), "a row is a string, got " + describe_json_value(st["rows"][i]) + ".", "Example: \"..11..\".");
            rows.push_back(st["rows"][i].get<std::string>());
        }
        auto g = index_grid_from_rows(rows, t.pal.size());
        if (!g.ok()) arg_error(cmd, "/stamp/rows", g.error().message, g.error().hint);
        const bool clear = arg_bool(st, "clear", false);
        const int sx = st.contains("x") ? whole(cmd, st["x"], "/stamp/x") : 0, sy = st.contains("y") ? whole(cmd, st["y"], "/stamp/y") : 0;
        for (int y = 0; y < g->h; ++y)
            for (int x = 0; x < g->w; ++x) {
                const int v = g->at(x, y);
                if (v < 0 && !clear) continue;
                Paint p;
                p.index = v;
                painter.put(sx + x, sy + y, p, nullptr);
            }
    }
    return finish(projectDir, d, t, before, a, cmd, Json::object(), painter);
}

// ---- image.draw ----------------------------------------------------------------------------------------------------------------------

const std::vector<std::string> kShapeTypes = {"line", "rect", "ellipse", "polygon", "fill"};

Json image_draw(const std::string& projectDir, const Json& a) {
    const char* cmd = "image.draw";
    check_arg_keys(cmd, a, "", {"path", "layer", "shapes", "create", "scale", "bake", "frame", "onion"});
    DocFile d = open_doc(projectDir, arg_string(a, "path", true), cmd);
    FrameScope frameScope(projectDir, d.rel, d.json, a, cmd);
    if (!a.contains("shapes") || !a["shapes"].is_array() || a["shapes"].empty() || a["shapes"].size() > 1000)
        arg_error(cmd, "/shapes", "`shapes` is required: a list of 1 to 1000 shapes, drawn in order.",
                  "Example: [{\"type\":\"ellipse\",\"x\":2,\"y\":2,\"width\":12,\"height\":12,\"fill\":\"skin\",\"color\":\"outline\"},{\"type\":\"line\",\"points\":[[2,14],[8,10],[14,14]],\"color\":\"outline\",\"perfect\":true}]. Types: " +
                      join(kShapeTypes, ", ") + ".");
    const std::optional<Image> before = render_document_json(projectDir, d.json);
    assets_detail::require_usable_manifest(projectDir);
    Target t = open_target(projectDir, d, a, cmd);
    Painter painter{t};
    for (std::size_t si = 0; si < a["shapes"].size(); ++si) {
        const Json& sh = a["shapes"][si];
        const std::string base = "/shapes/" + std::to_string(si);
        if (!sh.is_object() || !sh.contains("type") || !sh["type"].is_string())
            arg_error(cmd, base, "a shape is an object with a `type`, got " + describe_json_value(sh) + ".", "Types: " + join(kShapeTypes, ", ") + ". Example: {\"type\":\"rect\",\"x\":1,\"y\":1,\"width\":6,\"height\":4,\"fill\":\"skin\"}.");
        const std::string type = sh["type"].get<std::string>();
        if (std::find(kShapeTypes.begin(), kShapeTypes.end(), type) == kShapeTypes.end())
            arg_error(cmd, base + "/type", "unknown shape type '" + type + "'.", did_you_mean(type, kShapeTypes) + " Types: " + join(kShapeTypes, ", ") + ".");
        auto need = [&](const char* key, const char* what) -> const Json& {
            if (!sh.contains(key)) arg_error(cmd, base + "/" + key, std::string("a ") + type + " needs `" + key + "`: " + what + ".", "See the command description for the fields of each shape.");
            return sh[key];
        };
        auto box = [&](int& x, int& y, int& w, int& h) {
            x = whole(cmd, need("x", "the left column"), base + "/x");
            y = whole(cmd, need("y", "the top row"), base + "/y");
            w = whole(cmd, need("width", "the width in pixels"), base + "/width");
            h = whole(cmd, need("height", "the height in pixels"), base + "/height");
            if (w < 1 || h < 1 || w > 8192 || h > 8192) arg_error(cmd, base + (w < 1 || w > 8192 ? "/width" : "/height"), "width and height are 1 to 8192 pixels.", "The box includes its last row and column: x 2, width 5 covers columns 2 to 6.");
        };
        if (type == "line") {
            check_arg_keys(cmd, sh, base, {"type", "points", "color", "perfect", "closed"});
            const auto pts = points_arg(cmd, need("points", "[[x, y], ...] corners of the line, at least two"), base + "/points", 2);
            const Paint paint = parse_paint(cmd, need("color", "a palette colour (null erases)"), base + "/color", t.pal);
            painter.put_all(pixel_polyline(pts, arg_bool(sh, "perfect", false), arg_bool(sh, "closed", false)), paint);
        } else if (type == "rect" || type == "ellipse" || type == "polygon") {
            check_arg_keys(cmd, sh, base, type == "polygon" ? std::vector<std::string>{"type", "points", "color", "fill"} : std::vector<std::string>{"type", "x", "y", "width", "height", "color", "fill"});
            std::vector<PixelPoint> outline, inside;
            if (type == "polygon") {
                const auto pts = points_arg(cmd, need("points", "[[x, y], ...] corners, at least three"), base + "/points", 3);
                outline = pixel_polygon(pts, false);
                inside = pixel_polygon(pts, true);
            } else {
                int x, y, w, h;
                box(x, y, w, h);
                if (type == "rect") outline = pixel_rect(x, y, w, h, false), inside = pixel_rect(x, y, w, h, true);
                else outline = pixel_ellipse(x, y, w, h, false), inside = pixel_ellipse(x, y, w, h, true);
            }
            const bool hasColor = sh.contains("color"), hasFill = sh.contains("fill") && !(sh["fill"].is_boolean() && !sh["fill"].get<bool>());
            if (!hasColor && !hasFill) arg_error(cmd, base, "a " + type + " needs `color` (its outline) or `fill` (its inside), or both.", "Example: \"color\":\"outline\",\"fill\":\"skin\"; \"fill\":true fills with `color`.");
            if (hasFill) {
                Paint fillPaint;
                if (sh["fill"].is_boolean()) {
                    if (!hasColor) arg_error(cmd, base + "/fill", "`fill: true` fills with `color`, and there is no `color`.", "Give `color`, or name the fill colour: \"fill\":\"skin\".");
                    fillPaint = parse_paint(cmd, sh["color"], base + "/color", t.pal);
                } else {
                    fillPaint = parse_paint(cmd, sh["fill"], base + "/fill", t.pal);
                }
                painter.put_all(inside, fillPaint);
            }
            if (hasColor && !(hasFill && sh["fill"].is_boolean())) painter.put_all(outline, parse_paint(cmd, sh["color"], base + "/color", t.pal));
        } else {  // fill
            check_arg_keys(cmd, sh, base, {"type", "at", "color", "connectivity"});
            const PixelPoint at = point_arg(cmd, need("at", "[x, y], a pixel of the area to fill"), base + "/at");
            const Paint paint = parse_paint(cmd, need("color", "a palette colour (null erases)"), base + "/color", t.pal);
            int connectivity = 4;
            if (sh.contains("connectivity")) {
                if (!sh["connectivity"].is_number_integer() || (sh["connectivity"].get<int>() != 4 && sh["connectivity"].get<int>() != 8))
                    arg_error(cmd, base + "/connectivity", "`connectivity` is 4 (edges) or 8 (edges and corners), got " + describe_json_value(sh["connectivity"]) + ".", "4 keeps the fill from leaking through diagonal gaps in an outline.");
                connectivity = sh["connectivity"].get<int>();
            }
            const int gx = at.x - t.ox, gy = at.y - t.oy;
            if (!t.grid.inside(gx, gy))
                arg_error(cmd, base + "/at", std::format("({}, {}) is outside the layer's box ({} x {} at {}, {}).", at.x, at.y, t.grid.w, t.grid.h, t.ox, t.oy), "Pick a pixel inside the layer; coordinates are canvas pixels.");
            auto region = pixel_flood(t.grid, gx, gy, connectivity == 8);
            for (PixelPoint& p : region) p = {p.x + t.ox, p.y + t.oy};
            painter.put_all(region, paint);
        }
    }
    return finish(projectDir, d, t, before, a, cmd, Json::object({{"shapes", a["shapes"].size()}}), painter);
}

// ---- image.palette ---------------------------------------------------------------------------------------------------------------------

void count_use(const Json& layers, const PixelPalette& pal, std::vector<std::size_t>& use) {
    if (!layers.is_array()) return;
    for (const Json& l : layers) {
        if (!l.is_object()) continue;
        if (l.value("kind", std::string()) == "indexed" && l.contains("rows") && l["rows"].is_array())
            for (const Json& r : l["rows"])
                if (r.is_string())
                    for (char c : r.get<std::string>()) {
                        const int i = pixel_char_index(c);
                        if (i >= 0 && i < pal.size()) ++use[std::size_t(i)];
                    }
        if (l.contains("layers")) count_use(l["layers"], pal, use);
    }
}

Json palette_report(const Json& docJson, const PixelPalette& pal, bool fromStyle) {
    std::vector<std::size_t> use(std::size_t(pal.size()), 0);
    count_use(docJson["layers"], pal, use);
    Json list = Json::array();
    for (int i = 0; i < pal.size(); ++i) {
        Json e = Json::object({{"index", i}, {"char", std::string(1, pixel_index_char(i))}, {"color", pal.hex(i)}, {"used", use[std::size_t(i)]}});
        if (!pal.entries[std::size_t(i)].name.empty()) e["name"] = pal.entries[std::size_t(i)].name;
        if (auto at = pal.ramp_of(i)) e["ramp"] = Json::object({{"ramp", at->first}, {"position", at->second}});
        const int shade = pal.step(i, -1), light = pal.step(i, 1);
        e["shade"] = shade == i ? Json(nullptr) : Json(pal.label(shade));
        e["light"] = light == i ? Json(nullptr) : Json(pal.label(light));
        list.push_back(std::move(e));
    }
    return Json::object({{"colors", list}, {"ramps", ramps_json(pal)}, {"source", fromStyle ? "style" : "document"}});
}

Json image_palette(const std::string& projectDir, const Json& a) {
    const char* cmd = "image.palette";
    check_arg_keys(cmd, a, "", {"path", "palette", "ramps", "bake"});
    DocFile d = open_doc(projectDir, arg_string(a, "path", true), cmd);
    const bool write = a.contains("palette") || a.contains("ramps");
    const std::optional<Image> before = render_document_json(projectDir, d.json);
    std::vector<std::string> warnings;
    if (write) {
        assets_detail::require_usable_manifest(projectDir);
        if (a.contains("palette")) {
            if (a["palette"].is_null()) d.json.erase("palette");
            else d.json["palette"] = a["palette"];
        }
        if (a.contains("ramps")) {
            if (a["ramps"].is_null()) d.json.erase("ramps");
            else d.json["ramps"] = a["ramps"];
        }
    }
    const PixelPalette pal = load_doc_palette(projectDir, d.rel, d.json, true, cmd);
    const bool fromStyle = !d.json.contains("palette");
    if (!write) {
        Json out = Json::object({{"document", d.rel}});
        out["palette"] = palette_report(d.json, pal, fromStyle);
        out["nextSteps"] = Json::array({"Draw with image.pixel / image.draw using these names, indices or colours.",
                                        "Change the palette or the ramps: image.palette {\"palette\":[...],\"ramps\":[[...]]}."});
        return out;
    }
    if (a.contains("palette") && !a["palette"].is_null() && d.json.contains("layers")) {
        std::vector<std::size_t> use(std::size_t(pal.size()), 0);
        count_use(d.json["layers"], pal, use);
        warnings.push_back("The palette was replaced: pixels keep their INDEX, so each now has the colour at that index in the new palette.");
    }
    Json extra = Json::object({{"palette", palette_report(d.json, pal, fromStyle)}});
    Json out = commit_document(projectDir, d.rel, d.json, before, arg_bool(a, "bake", true), extra, warnings, cmd);
    if (arg_bool(a, "bake", true)) attach_preview(projectDir, d.rel, d.json, out, 0);
    return out;
}

// ---- image.layer.convert -------------------------------------------------------------------------------------------------------

const std::vector<std::string> kDithers = {"none", "bayer2", "bayer4", "bayer8", "floydSteinberg", "atkinson"};

bool layer_is_ai(const std::string& projectDir, const Json& layer) {
    if (layer.value("kind", std::string()) == "provider") return true;
    if (layer.value("ai", false)) return true;
    if (layer.contains("source") && layer["source"].is_string()) {
        assets_detail::ProjectRootGuard root(projectDir);
        const Json entry = assets::entry(layer["source"].get<std::string>());
        const Json prov = entry.is_object() ? entry.value("provenance", Json()) : Json();
        return prov.is_object() && prov.value("ai", false);
    }
    return false;
}

Json image_layer_convert(const std::string& projectDir, const Json& a) {
    const char* cmd = "image.layer.convert";
    check_arg_keys(cmd, a, "", {"path", "layer", "to", "palette", "dither", "space", "strength", "alphaThreshold", "scale", "bake"});
    DocFile d = open_doc(projectDir, arg_string(a, "path", true), cmd);
    if (!a.contains("layer") || a["layer"].is_null()) arg_error(cmd, "/layer", "`layer` is required: the layer to convert.", "Example: \"layer\":\"hero\". " + describe_layers(d.json, 12));
    LayerRef ref = find_layer(d.json, a["layer"], cmd);
    const std::string to = a.contains("to") && a["to"].is_string() ? a["to"].get<std::string>() : "";
    if (to != "indexed" && to != "pixels")
        arg_error(cmd, "/to", "`to` must be \"indexed\" (palette-locked pixel art) or \"pixels\" (a PNG layer), got " + describe_json_value(a.contains("to") ? a["to"] : Json()) + ".",
                  "Example: {\"layer\":\"hero\",\"to\":\"indexed\",\"dither\":\"bayer4\"}.");
    const std::string kind = ref.layer->value("kind", std::string());
    if (kind == to)
        arg_error(cmd, "/to", layer_label(ref) + " is already a" + (to == "indexed" ? "n indexed" : " pixels") + " layer.", "Nothing to convert.");
    if (kind == "group" || kind == "adjustment")
        arg_error(cmd, "/layer", layer_label(ref) + " is a " + kind + " layer: it has no pixels of its own to convert.", "Convert a layer inside the group, or add an indexed layer with image.layer.add.");
    if (ref.layer->contains("cels") && ref.layer->at("cels").is_array() && !ref.layer->at("cels").empty())
        arg_error(cmd, "/layer", layer_label(ref) + " shows different pictures in different frames (it has cels), and a conversion makes one picture.",
                  "Convert the layer before animating it, or draw the frames on a layer of the kind you want (image.pixel / image.draw with `frame`).");
    const int W = d.json.value("width", 0), H = d.json.value("height", 0);
    const std::optional<Image> before = render_document_json(projectDir, d.json);
    assets_detail::require_usable_manifest(projectDir);
    std::vector<std::string> warnings;
    Json extra = Json::object();
    const std::string name = ref.layer->value("name", std::string());

    // the layer as the picture it makes alone, in canvas coordinates
    Image img = render_layer_alone(projectDir, *ref.layer, W, H, ref.parentX, ref.parentY, &warnings, &d.json);
    int bx0 = W, by0 = H, bx1 = -1, by1 = -1;
    for (int y = 0; y < img.height; ++y)
        for (int x = 0; x < img.width; ++x)
            if (img.rgba[(std::size_t(y) * img.width + x) * 4 + 3]) bx0 = std::min(bx0, x), bx1 = std::max(bx1, x), by0 = std::min(by0, y), by1 = std::max(by1, y);
    const bool empty = bx1 < 0;
    if (empty) bx0 = by0 = bx1 = by1 = 0;
    const int bw = bx1 - bx0 + 1, bh = by1 - by0 + 1;
    if (empty) warnings.push_back("The layer shows nothing, so the converted layer is empty (1 x 1).");

    Json fresh = Json::object({{"kind", to}});
    for (const char* k : {"name", "visible", "opacity", "blend", "clip"})
        if (ref.layer->contains(k)) fresh[k] = (*ref.layer)[k];
    if (bx0 - ref.parentX) fresh["x"] = bx0 - ref.parentX;
    if (by0 - ref.parentY) fresh["y"] = by0 - ref.parentY;
    const bool hadOps = ref.layer->contains("masks") || ref.layer->contains("adjustments") || ref.layer->contains("effects");

    if (to == "pixels") {
        PixelPalette pal = load_doc_palette(projectDir, d.rel, d.json, false, cmd);
        (void)pal;
        Image crop;
        crop.width = bw;
        crop.height = bh;
        crop.rgba.assign(std::size_t(bw) * bh * 4, 0);
        if (!empty)
            for (int y = 0; y < bh; ++y) std::copy_n(&img.rgba[(std::size_t(y + by0) * img.width + bx0) * 4], std::size_t(bw) * 4, &crop.rgba[std::size_t(y) * bw * 4]);
        const bool ai = ref.layer->value("ai", false);
        const std::string png = layer_png_path(projectDir, d.rel, name.empty() ? "pixels" : name, d.json);
        write_layer_png(projectDir, png, d.rel, crop, cmd, ai);
        fresh["source"] = png;
        *ref.layer = std::move(fresh);
        if (ai) warnings.push_back("The pixels came from an AI-made picture and stay recorded as AI-made in assets.json ('" + png + "').");
    } else {
        // the palette: the document's, else the one given, else the style's
        if (a.contains("palette") && !a["palette"].is_null()) d.json["palette"] = a["palette"];
        const PixelPalette pal = load_doc_palette(projectDir, d.rel, d.json, true, cmd);
        const std::string refPath = ref.indexPath;
        if (pal.empty()) fail("invalid_argument", "There is no palette to convert to.", "Pass \"palette\":[\"#000000\",\"#ffffff\",...] or set style.palette in assets.json.");
        if (pin_palette(d.json, pal)) extra["palettePinned"] = "The palette was copied into the document's `palette`; edit it with image.palette.";
        ref = find_layer(d.json, Json(refPath), cmd);   // adding a key to the document may have moved the layer
        std::string dither = "none", space = "oklab";
        if (a.contains("dither")) {
            if (!a["dither"].is_string() || std::find(kDithers.begin(), kDithers.end(), a["dither"].get<std::string>()) == kDithers.end())
                arg_error(cmd, "/dither", "unknown dither " + describe_json_value(a["dither"]) + ".", did_you_mean(a["dither"].is_string() ? a["dither"].get<std::string>() : "", kDithers) + " Dithers: " + join(kDithers, ", ") + ".");
            dither = a["dither"].get<std::string>();
        }
        if (a.contains("space")) {
            if (!a["space"].is_string() || (a["space"] != "oklab" && a["space"] != "rgb")) arg_error(cmd, "/space", "`space` is \"oklab\" or \"rgb\", got " + describe_json_value(a["space"]) + ".", "oklab measures colour distance the way the eye does (default).");
            space = a["space"].get<std::string>();
        }
        double strength = 1, threshold = 0.5;
        if (a.contains("strength")) {
            if (!a["strength"].is_number() || a["strength"].get<double>() < 0 || a["strength"].get<double>() > 1) arg_error(cmd, "/strength", "`strength` is 0..1, got " + describe_json_value(a["strength"]) + ".", "How hard the dither pushes colours; default 1.");
            strength = a["strength"].get<double>();
        }
        if (a.contains("alphaThreshold")) {
            if (!a["alphaThreshold"].is_number() || a["alphaThreshold"].get<double>() <= 0 || a["alphaThreshold"].get<double>() > 1)
                arg_error(cmd, "/alphaThreshold", "`alphaThreshold` is a number above 0 up to 1, got " + describe_json_value(a["alphaThreshold"]) + ".", "Pixels at least this opaque become palette colours, the others transparent (default 0.5).");
            threshold = a["alphaThreshold"].get<double>();
        }
        imgdoc::Raster r(bw, bh, bx0, by0);
        std::size_t partial = 0;
        std::vector<int> exact(std::size_t(bw) * bh, -1);   // pixels that already are a palette colour keep it, dithered or not
        for (int y = 0; y < bh; ++y)
            for (int x = 0; x < bw; ++x) {
                const std::uint8_t* s = &img.rgba[(std::size_t(y + by0) * img.width + x + bx0) * 4];
                float* p = r.at(x, y);
                if (s[3] == 0) continue;
                if (s[3] < 255) ++partial;
                if (double(s[3]) / 255.0 < threshold) continue;
                if (auto same = pal.find_rgb(s[0], s[1], s[2])) exact[std::size_t(y) * bw + x] = *same;
                p[0] = s[0] / 255.0f; p[1] = s[1] / 255.0f; p[2] = s[2] / 255.0f; p[3] = 1.0f;
            }
        if (partial) warnings.push_back(std::format("{} semi-transparent pixel{} became fully opaque or fully transparent (alphaThreshold {}): indexed pixels have no partial alpha.", partial, partial == 1 ? "" : "s", threshold));
        Json op = Json::object({{"type", "quantize"}, {"palette", Json::array()}, {"space", space}, {"dither", dither}, {"strength", strength}});
        for (int i = 0; i < pal.size(); ++i) op["palette"].push_back(pal.hex(i));
        static const StyleGuide noStyle;
        imgdoc::OpEnv env;
        env.image = [](const std::string&) -> const Image& { throw CommandError("failed", "No picture is read by this operation.", ""); };
        env.style = []() -> const StyleGuide& { return noStyle; };
        env.fail = [](const std::string& m, const std::string& h) { throw CommandError("failed", m, h); };
        imgdoc::apply_adjustments({op}, r, env);
        IndexGrid grid(bw, bh);
        for (int y = 0; y < bh; ++y)
            for (int x = 0; x < bw; ++x) {
                const float* p = r.at(x, y);
                if (p[3] <= 0) continue;
                auto b = [](float v) { return std::uint8_t(std::lround(std::clamp(v, 0.0f, 1.0f) * 255.0f)); };
                const int keep = exact[std::size_t(y) * bw + x];
                grid.set(x, y, keep >= 0 ? keep : pal.nearest(b(p[0]), b(p[1]), b(p[2])));
            }
        fresh["rows"] = index_grid_rows(grid);
        if (layer_is_ai(projectDir, *ref.layer)) {
            fresh["ai"] = true;
            warnings.push_back("The layer was made from an AI-made picture, so the layer is marked `ai: true` and the baked PNG stays recorded as AI-made.");
        }
        *ref.layer = std::move(fresh);
        extra["colorsUsed"] = [&] {
            std::set<int> used(grid.v.begin(), grid.v.end());
            used.erase(-1);
            return used.size();
        }();
    }
    if (hadOps) warnings.push_back("The layer's masks, adjustments and effects were drawn into its pixels and are no longer separate settings.");
    LayerRef now = find_layer(d.json, Json(ref.indexPath), cmd);
    extra["layer"] = layer_summary(now);
    Json out = commit_document(projectDir, d.rel, d.json, before, arg_bool(a, "bake", true), extra, warnings, cmd);
    if (arg_bool(a, "bake", true)) attach_preview(projectDir, d.rel, d.json, out, scale_arg(a, cmd));
    return out;
}

}  // namespace indexed

using namespace indexed;

void register_indexed_commands(CommandRegistry& registry, const std::string& projectDir) {
    const std::string pathDoc = "The image document, project-relative, ending in .image.json.";
    const std::string bakeDoc = "Also draw the PNG (default true). False only writes the document.";
    const std::string colourDoc =
        "A palette colour: its index (3), its name (\\\"skin\\\"), its single index character (\\\"3\\\"), or a colour that IS in the palette (\\\"#e0a070\\\"). null, \\\".\\\" or \\\"transparent\\\" erases. "
        "{\\\"step\\\": -1} is one shade darker than what is in the pixel (+1 lighter); {\\\"color\\\": \\\"skin\\\", \\\"step\\\": 1} is the colour one step lighter than skin. "
        "A colour outside the palette is an error that names the nearest palette colour.";
    auto add = [&](const char* name, const char* summary, const std::string& description, const std::string& schema, Json (*fn)(const std::string&, const Json&), bool readOnly = false) {
        CommandInfo info;
        info.name = name;
        info.category = "assets";
        info.readOnly = readOnly;
        info.summary = summary;
        info.description = description;
        info.inputSchema = Json::parse(schema);
        if (std::string(name) == "image.pixel" || std::string(name) == "image.draw") add_frame_support(info, "to draw on");
        registry.add(info, [projectDir, fn](const Json& args) { return fn(projectDir, args); });
    };

    add("image.pixel", "Write exact pixels (a list, runs or a text stamp) onto an indexed pixel-art layer by palette colour; no anti-aliasing.",
        "Draws on an INDEXED layer (kind \"indexed\": the pixels are palette indices; docs.read IMAGES, \"Pixel art\"). `layer` is its name or index path; an unknown name with `create: true` makes a new blank "
        "indexed layer (canvas-sized, on top). Coordinates are canvas pixels (the layer's own offset and its groups' are accounted for); pixels outside the layer are dropped and counted in a warning. "
        "Three forms, applied in this order: `pixels` [[x, y, colour], ...]; `runs` [[x, y, length, colour], ...] (horizontal, to the right); `stamp` {x, y, rows: [\"..11..\", \".1221.\"], clear?} "
        "(text rows in the document's own characters: '.' is transparent and leaves the pixel alone unless `clear` is true). A colour is a palette index, name or colour; a colour not in the palette is an error with the nearest "
        "one. {\"step\": -1} shades the pixel one step along its colour ramp (see image.palette). When the document has no `palette` yet, the style palette is copied into it. "
        "Result: the baked document, `region` {x,y,width,height} of the changed pixels, `pixelsSet`, `changed`, and `$image` = the picture magnified with hard pixels (`previewScale`, default as large as fits 512 pixels). "
        "Example: {\"path\":\"assets/art/hero.image.json\",\"layer\":\"sprite\",\"create\":true,\"pixels\":[[3,4,\"skin\"],[4,4,2]],\"runs\":[[2,6,5,\"outline\"]]}",
        "{\"type\":\"object\",\"required\":[\"path\",\"layer\"],\"properties\":{"
        "\"path\":{\"type\":\"string\",\"description\":\"" + pathDoc + "\"},"
        "\"layer\":{\"description\":\"The indexed layer to draw on: its name or an index path like \\\"1/0\\\".\"},"
        "\"create\":{\"type\":\"boolean\",\"default\":false,\"description\":\"When no layer has that name, create a blank indexed layer with it at the top.\"},"
        "\"pixels\":{\"type\":\"array\",\"maxItems\":200000,\"description\":\"[[x, y, colour], ...]: single pixels. " + colourDoc + "\",\"items\":{\"type\":\"array\",\"minItems\":3,\"maxItems\":3}},"
        "\"runs\":{\"type\":\"array\",\"maxItems\":100000,\"description\":\"[[x, y, length, colour], ...]: horizontal runs of one colour starting at (x, y) going right.\",\"items\":{\"type\":\"array\",\"minItems\":4,\"maxItems\":4}},"
        "\"stamp\":{\"type\":\"object\",\"required\":[\"rows\"],\"description\":\"A little picture in text rows placed at (x, y).\",\"properties\":{"
        "\"x\":{\"type\":\"integer\",\"description\":\"Canvas column of the stamp's left edge (default 0).\"},"
        "\"y\":{\"type\":\"integer\",\"description\":\"Canvas row of the stamp's top edge (default 0).\"},"
        "\"rows\":{\"type\":\"array\",\"items\":{\"type\":\"string\"},\"description\":\"Equally long strings: '.' transparent, 0-9a-zA-Z!#$%&*+-/:;<=>?@^_~ = palette index 0, 1, 2, ...\"},"
        "\"clear\":{\"type\":\"boolean\",\"default\":false,\"description\":\"true: '.' erases the pixel; false: '.' leaves it alone.\"}}},"
        "\"scale\":{\"type\":\"integer\",\"minimum\":1,\"maximum\":32,\"description\":\"Magnification of the preview picture (default: automatic).\"},"
        "\"bake\":{\"type\":\"boolean\",\"default\":true,\"description\":\"" + bakeDoc + "\"}}}",
        image_pixel);

    add("image.draw", "Draw pixel-exact shapes (lines, rectangles, ellipses, polygons, flood fills) onto an indexed pixel-art layer by palette colour.",
        "Each shape of `shapes` is drawn in order on the indexed layer `layer` (see image.pixel for `layer`, `create`, coordinates and colours); no anti-aliasing: a pixel is either set or not. Shapes: "
        "line {points [[x,y],...] (a polyline), color, perfect?, closed?} (Bresenham; `perfect: true` removes the L-corners of a bending line so it is one pixel thick everywhere); "
        "rect {x, y, width, height, color?, fill?}; ellipse {x, y, width, height, color?, fill?} (inscribed in the box, midpoint algorithm, any odd or even size); polygon {points (>= 3), color?, fill?}; "
        "fill {at [x,y], color, connectivity? 4|8} (flood fill of the layer's pixels connected to `at` that hold the same colour or transparency; 4 does not leak through diagonal gaps). "
        "For rect, ellipse and polygon `color` is the outline and `fill` the inside: a colour, or true for `color`; give either or both (the fill is drawn first, so the outline stays). "
        "Result as image.pixel (`region`, `pixelsSet`, `$image` magnified with hard pixels). "
        "Example: {\"path\":\"assets/art/hero.image.json\",\"layer\":\"sprite\",\"create\":true,\"shapes\":[{\"type\":\"ellipse\",\"x\":2,\"y\":2,\"width\":12,\"height\":12,\"fill\":\"skin\",\"color\":\"outline\"},"
        "{\"type\":\"line\",\"points\":[[2,14],[8,10],[14,14]],\"color\":\"outline\",\"perfect\":true},{\"type\":\"fill\",\"at\":[8,8],\"color\":\"skin-light\"}]}",
        "{\"type\":\"object\",\"required\":[\"path\",\"layer\",\"shapes\"],\"properties\":{"
        "\"path\":{\"type\":\"string\",\"description\":\"" + pathDoc + "\"},"
        "\"layer\":{\"description\":\"The indexed layer to draw on: its name or an index path like \\\"1/0\\\".\"},"
        "\"create\":{\"type\":\"boolean\",\"default\":false,\"description\":\"When no layer has that name, create a blank indexed layer with it at the top.\"},"
        "\"shapes\":{\"type\":\"array\",\"minItems\":1,\"maxItems\":1000,\"description\":\"The shapes, drawn in order.\",\"items\":{\"type\":\"object\",\"required\":[\"type\"],\"properties\":{"
        "\"type\":{\"type\":\"string\",\"enum\":[\"line\",\"rect\",\"ellipse\",\"polygon\",\"fill\"],\"description\":\"The shape.\"},"
        "\"points\":{\"type\":\"array\",\"items\":{\"type\":\"array\",\"items\":{\"type\":\"integer\"}},\"description\":\"line, polygon: [[x, y], ...] corners (line: at least 2, polygon: at least 3).\"},"
        "\"x\":{\"type\":\"integer\",\"description\":\"rect, ellipse: left column of the box.\"},"
        "\"y\":{\"type\":\"integer\",\"description\":\"rect, ellipse: top row of the box.\"},"
        "\"width\":{\"type\":\"integer\",\"minimum\":1,\"description\":\"rect, ellipse: width of the box in pixels (its last column is x + width - 1).\"},"
        "\"height\":{\"type\":\"integer\",\"minimum\":1,\"description\":\"rect, ellipse: height of the box in pixels.\"},"
        "\"color\":{\"description\":\"line, fill: the colour; rect, ellipse, polygon: the outline colour. " + colourDoc + "\"},"
        "\"fill\":{\"description\":\"rect, ellipse, polygon: a colour for the inside, or true to fill with `color`.\"},"
        "\"perfect\":{\"type\":\"boolean\",\"description\":\"line (default false): remove the L-corners so the line is one pixel thick at every bend.\"},"
        "\"closed\":{\"type\":\"boolean\",\"description\":\"line (default false): join the last point to the first.\"},"
        "\"at\":{\"type\":\"array\",\"items\":{\"type\":\"integer\"},\"description\":\"fill: [x, y] of a pixel in the area to fill.\"},"
        "\"connectivity\":{\"type\":\"integer\",\"enum\":[4,8],\"description\":\"fill (default 4): 4 neighbours (edges) or 8 (edges and corners).\"}}}},"
        "\"scale\":{\"type\":\"integer\",\"minimum\":1,\"maximum\":32,\"description\":\"Magnification of the preview picture (default: automatic).\"},"
        "\"bake\":{\"type\":\"boolean\",\"default\":true,\"description\":\"" + bakeDoc + "\"}}}",
        image_draw);

    add("image.palette", "Show or change the palette and the colour ramps that indexed pixel-art layers of an image document are locked to.",
        "Without `palette` and `ramps` it only reads: every colour with its index, the character that stands for it in the layers' rows, name, #rrggbb, how many pixels use it, its ramp, and the colour one step "
        "darker (`shade`) and lighter (`light`); the palette is the document's `palette`, or the style palette of assets.json when the document has none. With `palette` (a list of colours, each \"#rrggbb\" or {name, color}, "
        "at most 81, all different; or \"style\") and/or `ramps` (lists of palette colours from the darkest to the lightest, each colour in one ramp; null removes) it rewrites them and bakes. "
        "Pixels keep their INDEX, so replacing the palette recolours the layers: append colours to keep the old ones. Without a declared ramp a colour's shade is the palette colour with lower lightness nearest to it in OKLab. "
        "Example: {\"path\":\"assets/art/hero.image.json\",\"palette\":[\"#1a1c2c\",{\"name\":\"skin\",\"color\":\"#e0a070\"},{\"name\":\"skin-dark\",\"color\":\"#b06a40\"}],\"ramps\":[[\"skin-dark\",\"skin\"]]}",
        "{\"type\":\"object\",\"required\":[\"path\"],\"properties\":{"
        "\"path\":{\"type\":\"string\",\"description\":\"" + pathDoc + "\"},"
        "\"palette\":{\"description\":\"New palette: \\\"style\\\" or a list of colours, each \\\"#rrggbb\\\" or {\\\"name\\\", \\\"color\\\"}; null removes the document's palette (the style palette applies). Omit to only read.\"},"
        "\"ramps\":{\"description\":\"New ramps: [[colour, colour, ...], ...] darkest first, colours by index, name or \\\"#rrggbb\\\"; null removes them.\"},"
        "\"bake\":{\"type\":\"boolean\",\"default\":true,\"description\":\"" + bakeDoc + "\"}}}",
        image_palette);

    add("image.layer.convert", "Turn a layer into an indexed pixel-art layer (quantized to the palette, optional dither) or an indexed layer back into a pixels layer.",
        "`to: \"indexed\"`: the layer, drawn alone with its masks, adjustments and effects, is cropped to what it shows and each visible pixel takes its nearest palette colour (OKLab by default, `space: \"rgb\"` for stored values) "
        "with an optional `dither` (none, bayer2, bayer4, bayer8, floydSteinberg, atkinson; ordered patterns line up with the canvas) at `strength` 0..1; pixels at least `alphaThreshold` (default 0.5) opaque are kept, the others become transparent; a pixel that already has a palette colour keeps it, so pixels -> indexed -> pixels loses nothing. "
        "The palette is the document's, else `palette` (written into the document), else the style palette. A layer made from an AI-made picture marks the new layer `ai: true`. Masks, adjustments and effects are drawn into the pixels. "
        "`to: \"pixels\"`: the indexed layer is written as a PNG (in <document>.layers/) and becomes a pixels layer, so blur, edit and paint work on it. Both directions keep the layer's name, visibility, opacity, blend and clip, and place it where it was. "
        "Result: the baked document, `layer`, `colorsUsed`, `region`, warnings and `$image` magnified with hard pixels. "
        "Example: {\"path\":\"assets/art/hero.image.json\",\"layer\":\"painted\",\"to\":\"indexed\",\"dither\":\"bayer4\"}",
        "{\"type\":\"object\",\"required\":[\"path\",\"layer\",\"to\"],\"properties\":{"
        "\"path\":{\"type\":\"string\",\"description\":\"" + pathDoc + "\"},"
        "\"layer\":{\"description\":\"The layer to convert: its name or an index path like \\\"1/0\\\".\"},"
        "\"to\":{\"type\":\"string\",\"enum\":[\"indexed\",\"pixels\"],\"description\":\"indexed: palette-locked pixel art. pixels: a PNG layer.\"},"
        "\"palette\":{\"description\":\"to indexed: the palette to use when the document has none (a list of colours or \\\"style\\\"); it is written into the document.\"},"
        "\"dither\":{\"type\":\"string\",\"enum\":[\"none\",\"bayer2\",\"bayer4\",\"bayer8\",\"floydSteinberg\",\"atkinson\"],\"default\":\"none\",\"description\":\"to indexed: how colours between palette colours are mixed.\"},"
        "\"space\":{\"type\":\"string\",\"enum\":[\"oklab\",\"rgb\"],\"default\":\"oklab\",\"description\":\"to indexed: how colour distance is measured.\"},"
        "\"strength\":{\"type\":\"number\",\"minimum\":0,\"maximum\":1,\"default\":1,\"description\":\"to indexed: how strong the dither is.\"},"
        "\"alphaThreshold\":{\"type\":\"number\",\"exclusiveMinimum\":0,\"maximum\":1,\"default\":0.5,\"description\":\"to indexed: pixels at least this opaque become palette colours, the rest transparent.\"},"
        "\"scale\":{\"type\":\"integer\",\"minimum\":1,\"maximum\":32,\"description\":\"Magnification of the preview picture (default: automatic).\"},"
        "\"bake\":{\"type\":\"boolean\",\"default\":true,\"description\":\"" + bakeDoc + "\"}}}",
        image_layer_convert);
}

}  // namespace fa::imgedit
