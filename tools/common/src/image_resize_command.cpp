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
    int newW = 0, newH = 0;
    int dx = 0, dy = 0;
    std::vector<std::string> warnings;
};

// A layer with no size of its own at (0, 0) covers the canvas whatever its size: it needs no move.
bool follows_canvas(const Json& layer) {
    const std::string kind = layer.value("kind", std::string());
    const bool sizedByCanvas = kind == "fill" || kind == "gradient" || kind == "procedural" || kind == "svg" || (kind == "indexed" && !layer.contains("rows"));
    return sizedByCanvas && layer.value("width", 0) == 0 && layer.value("height", 0) == 0 && layer.value("x", 0) == 0 && layer.value("y", 0) == 0;
}

// `rows` (their top-left pixel at canvas (cx, cy)) cut to the new canvas; '.' where they do not reach.
std::vector<std::string> recut(const std::vector<std::string>& rows, int cx, int cy, int w, int h) {
    std::vector<std::string> out(std::size_t(h), std::string(std::size_t(w), '.'));
    for (std::size_t r = 0; r < rows.size(); ++r) {
        const long long y = (long long)cy + (long long)r;
        if (y < 0 || y >= h) continue;
        const std::string& row = rows[r];
        for (std::size_t c = 0; c < row.size(); ++c) {
            const long long x = (long long)cx + (long long)c;
            if (x >= 0 && x < w) out[std::size_t(y)][std::size_t(x)] = row[c];
        }
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
void walk(Json& list, bool top, int px, int py, Ctx& c) {
    if (!list.is_array()) return;
    for (Json& layer : list) {
        if (!layer.is_object()) continue;
        const std::string kind = layer.value("kind", std::string());
        if (kind == "adjustment") continue;
        if (top && !follows_canvas(layer)) {
            layer["x"] = layer.value("x", 0) + c.dx;
            layer["y"] = layer.value("y", 0) + c.dy;
            if (layer.contains("cels") && layer["cels"].is_array())
                for (Json& cel : layer["cels"]) {
                    if (cel.contains("x")) cel["x"] = cel.value("x", 0) + c.dx;
                    if (cel.contains("y")) cel["y"] = cel.value("y", 0) + c.dy;
                }
        }
        if (kind == "group") {
            if (layer.contains("layers")) walk(layer["layers"], false, px + layer.value("x", 0), py + layer.value("y", 0), c);
            continue;
        }
        if (kind != "indexed") continue;
        const int lx = layer.value("x", 0), ly = layer.value("y", 0);
        const bool ownRows = layer.contains("rows") && layer["rows"].is_array();
        bool anyCelRows = false;
        if (layer.contains("cels") && layer["cels"].is_array())
            for (const Json& cel : layer["cels"]) anyCelRows = anyCelRows || cel.contains("rows");
        if (!ownRows && !anyCelRows) continue;
        // The layer's origin goes to the canvas origin and every picture is cut to the new canvas.
        if (ownRows) layer["rows"] = recut(rows_of(layer["rows"]), px + lx, py + ly, c.newW, c.newH);
        if (layer.contains("cels") && layer["cels"].is_array())
            for (Json& cel : layer["cels"]) {
                if (cel.contains("rows")) {
                    const int cx = cel.contains("x") ? cel.value("x", 0) : lx, cy = cel.contains("y") ? cel.value("y", 0) : ly;
                    cel["rows"] = recut(rows_of(cel["rows"]), px + cx, py + cy, c.newW, c.newH);
                    cel.erase("x");
                    cel.erase("y");
                } else if (cel.contains("x") || cel.contains("y")) {
                    c.warnings.push_back(std::format("The cel of '{}' at frame {} has its own position and no pixels (a linked or empty cel): check where it lands now.",
                                                     layer.value("name", std::string("?")), cel.value("frame", 0)));
                }
            }
        layer["x"] = -px;
        layer["y"] = -py;
    }
}

Json image_resize(const std::string& projectDir, const Json& a) {
    check_arg_keys(kCmd, a, "", {"path", "width", "height", "anchor", "fill", "bake"});
    DocFile d = open_doc(projectDir, arg_string(a, "path", true), kCmd);
    Json& doc = d.json;
    const int oldW = doc.value("width", 0), oldH = doc.value("height", 0);
    Ctx c;
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
        "Sets the document's canvas to `width` x `height` (1..4096). `anchor` is the part of the old canvas that stays where it is (top-left, top, top-right, left, center, "
        "right, bottom-left, bottom, bottom-right; default center): with \"top-left\" a bigger canvas grows at the right and bottom, a smaller one is cropped there. An odd "
        "difference rounds down (the extra pixel goes to the right/bottom side). Every layer of the top level moves by the offset the anchor gives (groups take their children along); "
        "a layer that follows the canvas (a fill, gradient or procedural layer with no size, an empty indexed layer) just covers the new size. Pixels and picture layers keep their "
        "PNG and are cropped only by the canvas; the text rows of an indexed (pixel-art) layer, and of its cels, are cut or padded to the new canvas. Palette, ramps, frames, tags "
        "and the sheet settings are kept; the baked sheet takes the new cell size. `fill` (a colour, default transparent) paints the area a bigger canvas adds, as a masked fill layer "
        "named 'resize fill' at the bottom; with no fill the new area shows the document's background, or is transparent. Stored selections were made for the old size and must be "
        "made again (a warning says so). One edit: the editor undoes it with Ctrl+Z. Example: {\"path\":\"assets/art/heart.image.json\",\"width\":12,\"height\":12,\"anchor\":\"top-left\"}";
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
