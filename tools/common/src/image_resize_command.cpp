// image.resize: change the canvas of an image document (docs/IMAGES.md, "Resizing the canvas"). Every layer, cel and frame moves
// with the anchor; the document's palette, ramps, tags, frames and sheet settings are not touched (the bake rewrites the sheet
// entry for the new cell size). It edits the JSON like the other image.* commands and goes through commit_document.
#include <algorithm>
#include <cmath>
#include <format>

#include "fa/core/strings.h"
#include "image_edit.h"
#include "util.h"

namespace fa::imgedit {

using assets_detail::arg_error;
using assets_detail::check_arg_keys;
using tooling_detail::arg_bool;
using tooling_detail::arg_string;

namespace {

constexpr const char* kCmd = "image.resize";

struct Anchor {
    const char* name;
    double fx, fy;  // 0 = left/top, 0.5 = centre, 1 = right/bottom
};
constexpr Anchor kAnchors[] = {{"top-left", 0, 0}, {"top", 0.5, 0},       {"top-right", 1, 0}, {"left", 0, 0.5},   {"center", 0.5, 0.5},
                               {"right", 1, 0.5},  {"bottom-left", 0, 1}, {"bottom", 0.5, 1},  {"bottom-right", 1, 1}};

int whole(const Json& a, const char* key) {
    auto it = a.find(key);
    if (it == a.end() || it->is_null())
        arg_error(kCmd, std::string("/") + key, std::string("`") + key + "` is required: the new canvas size in pixels.",
                  "Example: {\"path\":\"assets/art/hero.image.json\",\"width\":16,\"height\":16}.");
    if (!it->is_number_integer() || it->get<long long>() < 1 || it->get<long long>() > kImageDocMaxSide)
        arg_error(kCmd, std::string("/") + key,
                  std::string("`") + key + "` must be a whole number from 1 to " + std::to_string(kImageDocMaxSide) + ", got " + describe_json_value(*it) + ".",
                  "A canvas side is 1 to 4096 pixels.");
    return int(it->get<long long>());
}

struct Ctx {
    int oldW = 0, oldH = 0;
    int newW = 0, newH = 0;
    int dx = 0, dy = 0;
    long long rowBytes = 0;  // characters of `rows` written so far, against kMaxRowBytes
    std::vector<std::string> warnings;
};

// A document keeps x and y within +-100000 (image_doc_parse.cpp); a value read from a hand-edited file may be anything.
constexpr long long kMaxCoord = 100000;
// The text rows an indexed layer or cel keeps are cut to the canvas, never padded: this caps what a resize may write in all.
constexpr long long kMaxRowBytes = 64LL * 1024 * 1024;

int clamp_coord(long long v) { return int(std::clamp(v, -kMaxCoord, kMaxCoord)); }

long long coord(const Json& obj, const char* key) {
    auto it = obj.find(key);
    if (it == obj.end()) return 0;
    if (it->is_number_integer()) return std::clamp(it->get<long long>(), -(1LL << 40), 1LL << 40);
    if (it->is_number_float()) {
        const double v = it->get<double>();
        return std::isfinite(v) ? (long long)std::clamp(v, -1e12, 1e12) : 0;
    }
    return 0;
}

bool has_masks(const Json& layer) { return layer.contains("masks") && layer["masks"].is_array() && !layer["masks"].empty(); }

// A layer with no size of its own at (0, 0) covers the canvas whatever its size: it needs no move.
bool follows_canvas(const Json& layer) {
    const std::string kind = layer.value("kind", std::string());
    // An indexed layer has art of its own when it, or any of its cels, has `rows` (frame 0 may be empty with the art only in the cels).
    bool indexedArt = layer.contains("rows");
    if (kind == "indexed" && layer.contains("cels") && layer["cels"].is_array())
        for (const Json& cel : layer["cels"]) indexedArt = indexedArt || (cel.is_object() && cel.contains("rows"));
    const bool sizedByCanvas = kind == "fill" || kind == "gradient" || kind == "procedural" || kind == "svg" || (kind == "indexed" && !indexedArt);
    return sizedByCanvas && coord(layer, "width") == 0 && coord(layer, "height") == 0 && coord(layer, "x") == 0 && coord(layer, "y") == 0;
}

// A canvas-following layer with masks keeps them only if it moves with them (masks are in the layer's own pixels), so it becomes a
// box of the old canvas size and moves like any other layer. It stops covering the area a bigger canvas adds.
void make_box_of_old_canvas(Json& layer, const Ctx& c) {
    if (layer.value("kind", std::string()) == "procedural") {
        if (!layer.contains("texture") || !layer["texture"].is_object()) layer["texture"] = Json::object();
        Json& t = layer["texture"];
        if (!t.contains("width")) t["width"] = c.oldW;
        if (!t.contains("height")) t["height"] = c.oldH;
    } else {
        layer["width"] = c.oldW;
        layer["height"] = c.oldH;
    }
}

void move_layer(Json& layer, const Ctx& c) {
    layer["x"] = clamp_coord(coord(layer, "x") + c.dx);
    layer["y"] = clamp_coord(coord(layer, "y") + c.dy);
    if (layer.contains("cels") && layer["cels"].is_array())
        for (Json& cel : layer["cels"]) {
            if (!cel.is_object()) continue;
            if (cel.contains("x")) cel["x"] = clamp_coord(coord(cel, "x") + c.dx);
            if (cel.contains("y")) cel["y"] = clamp_coord(coord(cel, "y") + c.dy);
        }
}

struct Cut {
    std::vector<std::string> rows;
    long long x = 0, y = 0;  // where the first pixel of `rows` lies on the canvas
};

// `rows` (their top-left pixel at canvas (cx, cy)) cut to the part inside the new canvas, '.' where a short row does not reach. Nothing
// outside the canvas is kept, so a big canvas costs nothing; a picture wholly outside becomes one transparent pixel.
Cut recut(const std::vector<std::string>& rows, long long cx, long long cy, int w, int h, Ctx& c, const std::string& where) {
    std::size_t widest = 0;
    for (const std::string& r : rows) widest = std::max(widest, r.size());
    const long long x0 = std::max(cx, 0LL), x1 = std::min(cx + (long long)widest, (long long)w);
    const long long y0 = std::max(cy, 0LL), y1 = std::min(cy + (long long)rows.size(), (long long)h);
    Cut out;
    if (x0 >= x1 || y0 >= y1) {
        out.rows = {"."};
        return out;
    }
    c.rowBytes += (x1 - x0) * (y1 - y0);
    if (c.rowBytes > kMaxRowBytes)
        fail("too_large", std::format("Resizing to {}x{} would keep more than {} MB of pixel rows ({}).", c.newW, c.newH, kMaxRowBytes >> 20, where),
             "Pixel-art rows are stored as text, one character per pixel of each layer and frame. Resize to a smaller canvas, remove frames or layers first, or "
             "keep big art in a `pixels` layer (a PNG). Nothing was changed.");
    out.x = x0;
    out.y = y0;
    out.rows.reserve(std::size_t(y1 - y0));
    for (long long y = y0; y < y1; ++y) {
        const std::string& row = rows[std::size_t(y - cy)];
        const std::size_t from = std::size_t(x0 - cx), len = std::size_t(x1 - x0);
        std::string piece = from < row.size() ? row.substr(from, len) : std::string();
        piece.resize(len, '.');
        out.rows.push_back(std::move(piece));
    }
    return out;
}

std::vector<std::string> rows_of(const Json& v) {
    std::vector<std::string> rows;
    if (v.is_array())
        for (const Json& r : v) rows.push_back(r.is_string() ? r.get<std::string>() : std::string());
    return rows;
}

// `list` is a layer list whose origin lies at canvas (px, py) once moved; only the top level (`top`) is moved by the anchor.
void walk(Json& list, bool top, long long px, long long py, Ctx& c) {
    if (!list.is_array()) return;
    for (Json& layer : list) {
        if (!layer.is_object()) continue;
        const std::string kind = layer.value("kind", std::string());
        if (kind == "adjustment") {
            // It covers the whole canvas unless it has masks, which are in its own pixels: then it moves, and they go with it.
            if (top && has_masks(layer) && (c.dx != 0 || c.dy != 0)) move_layer(layer, c);
            continue;
        }
        if (top) {
            bool follows = follows_canvas(layer);
            if (follows && has_masks(layer) && (c.dx != 0 || c.dy != 0)) {
                make_box_of_old_canvas(layer, c);
                follows = false;
            }
            if (!follows) move_layer(layer, c);
        }
        if (kind == "group") {
            if (layer.contains("layers")) walk(layer["layers"], false, px + coord(layer, "x"), py + coord(layer, "y"), c);
            continue;
        }
        if (kind != "indexed") continue;
        const long long lx = coord(layer, "x"), ly = coord(layer, "y");
        const bool ownRows = layer.contains("rows") && layer["rows"].is_array();
        bool anyCelRows = false;
        if (layer.contains("cels") && layer["cels"].is_array())
            for (const Json& cel : layer["cels"]) anyCelRows = anyCelRows || cel.contains("rows");
        if (!ownRows && !anyCelRows) continue;
        const std::string name = layer.value("name", std::string("?"));
        // Every picture is cut to the new canvas and keeps its place there (its layer or cel x / y says where).
        long long layerX = -px, layerY = -py;
        if (ownRows) {
            Cut cut = recut(rows_of(layer["rows"]), px + lx, py + ly, c.newW, c.newH, c, "layer '" + name + "'");
            layer["rows"] = cut.rows;
            layerX = cut.x - px;
            layerY = cut.y - py;
        }
        if (layer.contains("cels") && layer["cels"].is_array())
            for (Json& cel : layer["cels"]) {
                if (!cel.is_object()) continue;
                if (cel.contains("rows")) {
                    const long long cx = cel.contains("x") ? coord(cel, "x") : lx, cy = cel.contains("y") ? coord(cel, "y") : ly;
                    Cut cut = recut(rows_of(cel["rows"]), px + cx, py + cy, c.newW, c.newH, c, "a cel of layer '" + name + "'");
                    cel["rows"] = cut.rows;
                    cel["x"] = clamp_coord(cut.x - px);
                    cel["y"] = clamp_coord(cut.y - py);
                } else if (cel.contains("x") || cel.contains("y")) {
                    c.warnings.push_back(std::format("The cel of '{}' at frame {} has its own position and no pixels (a linked or empty cel): check where it lands now.",
                                                     name, cel.value("frame", 0)));
                }
            }
        layer["x"] = clamp_coord(layerX);
        layer["y"] = clamp_coord(layerY);
    }
}

Json image_resize(const std::string& projectDir, const Json& a) {
    check_arg_keys(kCmd, a, "", {"path", "width", "height", "anchor", "fill", "bake"});
    DocFile d = open_doc(projectDir, arg_string(a, "path", true), kCmd);
    Json& doc = d.json;
    const int oldW = doc.value("width", 0), oldH = doc.value("height", 0);
    Ctx c;
    c.oldW = oldW;
    c.oldH = oldH;
    c.newW = whole(a, "width");
    c.newH = whole(a, "height");
    std::string anchorName = "center";
    if (a.contains("anchor") && !a["anchor"].is_null()) {
        if (!a["anchor"].is_string())
            arg_error(kCmd, "/anchor", "`anchor` must be a name such as \"top-left\", got " + describe_json_value(a["anchor"]) + ".",
                      "One of: top-left, top, top-right, left, center, right, bottom-left, bottom, bottom-right.");
        anchorName = a["anchor"].get<std::string>();
    }
    const Anchor* anchor = nullptr;
    for (const Anchor& an : kAnchors)
        if (anchorName == an.name) anchor = &an;
    if (!anchor) {
        std::vector<std::string> names;
        for (const Anchor& an : kAnchors) names.push_back(an.name);
        arg_error(kCmd, "/anchor", "unknown anchor '" + anchorName + "'. " + did_you_mean(anchorName, names, 9),
                  "The anchor is the part of the old canvas that stays put: \"top-left\" grows or crops at the right and bottom, \"center\" on every side.");
    }
    if (c.newW == oldW && c.newH == oldH)
        arg_error(kCmd, "/width", std::format("the canvas is already {}x{}.", oldW, oldH), "Give a different width or height; nothing was changed.");
    c.dx = int(std::floor((c.newW - oldW) * anchor->fx));
    c.dy = int(std::floor((c.newH - oldH) * anchor->fy));
    bool filled = false;
    if (a.contains("fill") && !a["fill"].is_null()) {
        const Color fill = assets_detail::colour_arg(kCmd, a["fill"], "/fill");
        filled = fill.a > 0 && (c.newW > oldW || c.newH > oldH);
    }

    const std::optional<Image> before = render_document_json(projectDir, doc);
    walk(doc["layers"], true, 0, 0, c);
    doc["width"] = c.newW;
    doc["height"] = c.newH;
    if (filled) {
        // The new area is whatever lies outside the old canvas: a canvas-sized fill under everything, masked to that area.
        Json mask = Json::object({{"type", "rect"}, {"x", c.dx}, {"y", c.dy}, {"width", oldW}, {"height", oldH}, {"invert", true}});
        Json layer = Json::object({{"kind", "fill"}, {"name", unique_layer_name(doc, "resize fill")}, {"color", a["fill"]}, {"masks", Json::array({mask})}});
        if (!doc.contains("layers") || !doc["layers"].is_array()) doc["layers"] = Json::array();
        doc["layers"].insert(doc["layers"].begin(), layer);
    }
    if (doc.contains("tile") && doc["tile"].is_object() && (doc["tile"].contains("width") || doc["tile"].contains("height")))
        c.warnings.push_back("The document declares its own tile size; it was not changed.");
    const std::vector<std::string> selections = list_selections(projectDir, d.rel);
    if (!selections.empty())
        c.warnings.push_back(std::format("{} stored selection(s) were made for the old canvas size and cannot be used now: select again.", selections.size()));

    Json extra = Json::object({{"resized", Json::object({{"from", Json::object({{"width", oldW}, {"height", oldH}})},
                                                          {"to", Json::object({{"width", c.newW}, {"height", c.newH}})},
                                                          {"anchor", anchorName},
                                                          {"offset", Json::object({{"x", c.dx}, {"y", c.dy}})},
                                                          {"filled", filled}})}});
    return commit_document(projectDir, d.rel, doc, before, arg_bool(a, "bake", true), extra, c.warnings, kCmd);
}

}  // namespace

void register_resize_command(CommandRegistry& registry, const std::string& projectDir) {
    CommandInfo info;
    info.name = kCmd;
    info.category = "assets";
    info.readOnly = false;
    info.summary = "Change the canvas size of an image document, moving or cropping every layer, frame and cel by an anchor, and bake.";
    info.description =
        "Sets the canvas to `width` x `height` (1..4096). `anchor` is the part of the old canvas that stays put (top-left, top, top-right, left, center, "
        "right, bottom-left, bottom, bottom-right; default center): with \"top-left\" a bigger canvas grows at the right and bottom, a smaller one is cropped there. An odd "
        "difference rounds down. Every top-level layer moves by the anchor's offset (groups take their children along). A fill, gradient or procedural layer with no size "
        "just covers the new size, unless it has `masks` (they are in the layer's own pixels): then it becomes a box of the old canvas size and moves, so its masks stay on the "
        "same pixels and it no longer covers the added area. Adjustment layers with masks move too. Pixels and picture layers keep their PNG; the text rows of indexed layers and "
        "cels are CUT to the new canvas (never padded: a big canvas costs nothing; over 64 MB of rows fails). Palette, ramps, frames, tags and sheet settings are kept; the bake "
        "takes the new cell size. `fill` (default transparent) paints the area a bigger canvas adds as a masked fill layer 'resize fill' at the bottom. Stored selections must be "
        "made again (a warning). One undo step. Example: {\"path\":\"assets/art/heart.image.json\",\"width\":12,\"height\":12,\"anchor\":\"top-left\"}";
    info.inputSchema = Json::parse(R"({"type":"object","required":["path","width","height"],"properties":{
      "path":{"type":"string","description":"The image document, project-relative, ending in .image.json."},
      "width":{"type":"integer","minimum":1,"maximum":4096,"description":"New canvas width in pixels."},
      "height":{"type":"integer","minimum":1,"maximum":4096,"description":"New canvas height in pixels."},
      "anchor":{"type":"string","enum":["top-left","top","top-right","left","center","right","bottom-left","bottom","bottom-right"],"default":"center","description":"The part of the old canvas that stays put; the canvas grows or is cropped on the opposite sides."},
      "fill":{"description":"Colour of the area a bigger canvas adds: \"#rrggbb\", \"#rrggbbaa\", a CSS name or [r,g,b,a]. Default transparent."},
      "bake":{"type":"boolean","default":true,"description":"Also draw the PNG (default true). False only writes the document."}}})");
    registry.add(info, [projectDir](const Json& args) { return image_resize(projectDir, args); });
}

}  // namespace fa::imgedit
