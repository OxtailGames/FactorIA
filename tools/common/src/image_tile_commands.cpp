// image.tile.set, image.tile.check and the image.tileset.* commands (docs/IMAGES.md, "Tiles"):
//
//   image.tile.set       turn tile mode (wrap-around editing) on or off for a document
//   image.tile.check     the seam check: does the picture repeat without a visible line?
//   image.tileset.build  make (or update in place) a document whose `tileset` layer builds the 16 or 47 tiles of an autotile set,
//                        bake the sheet and write the rules file Tilemap.terrains reads
//   image.tileset.info   what the parts are, what the set contains (tile by tile)
//   image.tileset.check  are the parts right, and do the tiles of the set fit together where they touch?
//   image.tileset.rules  write the rules file again (a recipe command: assets.regenerate runs it)
#include <algorithm>
#include <cmath>
#include <format>
#include <map>
#include <set>

#include "fa/core/asset_manifest.h"
#include "fa/core/strings.h"
#include "fa/scene/autotile.h"
#include "fa/tooling/image_tile.h"
#include "fa/tooling/image_tileset.h"
#include "fa/tooling/project_fs.h"
#include "fa/tooling/style_guide.h"
#include "image_edit.h"
#include "util.h"

namespace fa::imgedit {

using assets_detail::arg_error;
using assets_detail::check_arg_keys;
using assets_detail::require_usable_manifest;
using tooling_detail::arg_bool;
using tooling_detail::arg_string;

namespace {

constexpr const char* kRulesCommand = "image.tileset.rules";

int int_arg(const Json& a, const char* command, const char* key, int lo, int hi, int def) {
    auto it = a.find(key);
    if (it == a.end() || it->is_null()) return def;
    if (!it->is_number_integer() || it->get<long long>() < lo || it->get<long long>() > hi)
        arg_error(command, std::string("/") + key, std::string("`") + key + "` must be a whole number from " + std::to_string(lo) + " to " + std::to_string(hi) + ", got " + describe_json_value(*it) + ".", "");
    return int(it->get<long long>());
}

std::optional<Image> read_png(const std::string& projectDir, const std::string& rel) {
    auto path = resolve_project_path(projectDir, rel);
    if (!path.ok()) return std::nullopt;
    auto bytes = tooling_detail::read_file(*path);
    if (!bytes) return std::nullopt;
    auto img = decode_image(reinterpret_cast<const std::uint8_t*>(bytes->data()), bytes->size());
    if (!img.ok()) return std::nullopt;
    return std::move(*img);
}

// Writes a picture under .factoria/previews/ (a disposable cache) and returns its project-relative path.
std::string write_preview(const std::string& projectDir, const std::string& docRel, const char* suffix, const Image& img) {
    const std::string rel = ".factoria/previews/" + docRel + suffix;
    auto path = resolve_project_path(projectDir, rel);
    if (!path.ok()) return {};
    const auto png = encode_png(img);
    if (!tooling_detail::write_file(*path, std::string_view(reinterpret_cast<const char*>(png.data()), png.size()), nullptr)) return {};
    return rel;
}

Json preview_image(const std::string& projectDir, const std::string& rel) {
    auto path = resolve_project_path(projectDir, rel);
    if (!path.ok()) return Json();
    return Json::object({{"path", path->string()}, {"mimeType", "image/png"}});
}

// Pixel art keeps hard colours, so the seam check compares exactly: the style says so, or the document draws on a palette.
bool exact_colours(const std::string& projectDir, const ImageDocument& doc) {
    if (!doc.palette.empty()) return true;
    const StyleParse style = load_style_guide(projectDir);
    return style.guide.pixelArt.value_or(false);
}

ImageDocument parse_or_fail(const std::string& projectDir, const std::string& rel, const Json& json) {
    auto parsed = parse_image_document(json, rel, projectDir);
    if (!parsed.ok()) fail("invalid_argument", parsed.error().message, parsed.error().hint);
    return std::move(*parsed);
}

Image render_or_fail(const std::string& projectDir, const ImageDocument& doc) {
    ImageRenderOptions options;
    options.projectDir = projectDir;
    auto render = composite_image_document(doc, options);
    if (!render.ok()) fail("failed", render.error().message, render.error().hint);
    return std::move(render->image);
}

std::string base_of(const std::string& docRel) { return docRel.substr(0, docRel.size() - std::string(kImageDocSuffix).size()); }

// The names of the neighbours in a mask, "N+NE+E", or "none".
std::string mask_name(int mask) {
    static const char* names[8] = {"N", "NE", "E", "SE", "S", "SW", "W", "NW"};
    std::string s;
    for (int b = 0; b < 8; ++b)
        if (mask & (1 << b)) s += (s.empty() ? "" : "+") + std::string(names[b]);
    return s.empty() ? "none" : s;
}

// ---- tileset layers ----------------------------------------------------------------------------------------------

void collect_tileset_layers(const std::vector<ImageLayer>& layers, std::vector<const ImageLayer*>& out) {
    for (const ImageLayer& l : layers) {
        if (l.kind == ImageLayerKind::Tileset) out.push_back(&l);
        if (l.kind == ImageLayerKind::Group) collect_tileset_layers(l.children, out);
    }
}

// The tileset layer called `name` ("" = the document's only one). A teaching CommandError when there is none, or several and no name.
const ImageLayer& pick_tileset_layer(const ImageDocument& doc, const std::string& name, const char* command) {
    std::vector<const ImageLayer*> all;
    collect_tileset_layers(doc.layers, all);
    std::vector<std::string> names;
    for (const ImageLayer* l : all) names.push_back(l->name);
    if (all.empty())
        fail("invalid_argument", "'" + doc.file + "' has no tileset layer.",
             "Make one with image.tileset.build {\"path\":\"" + doc.file + "\",\"tileWidth\":16,\"tileHeight\":16,\"parts\":{...}}; see image.tileset.info for the parts.");
    if (name.empty()) {
        if (all.size() == 1) return *all[0];
        arg_error(command, "/layer", "'" + doc.file + "' has " + std::to_string(all.size()) + " tileset layers (" + join(names, ", ") + "): say which one.",
                  "Example: {\"layer\":\"" + names[0] + "\"}.");
    }
    for (const ImageLayer* l : all)
        if (l->name == name) return *l;
    arg_error(command, "/layer", "'" + doc.file + "' has no tileset layer called '" + name + "'.", did_you_mean(name, names) + " Tileset layers: " + join(names, ", ") + ".");
}

// Warnings about a tileset layer whose sheet is not the whole picture: Tilemap rules count tiles on the baked PNG.
void sheet_warnings(const ImageDocument& doc, const ImageLayer& layer, const TilesetLayout& lay, std::vector<std::string>& out) {
    if (layer.x != 0 || layer.y != 0)
        out.push_back(std::format("The layer '{}' sits at ({}, {}) in the canvas, so the baked PNG is not the tile sheet: the tile numbers in the rules count the tiles of a PNG that starts with the sheet. Move the layer to (0, 0).",
                                  layer.name, layer.x, layer.y));
    if (doc.layers.size() > 1)
        out.push_back("The document has other layers: the baked PNG shows them too, but the rules number the tiles of the sheet alone. Keep the tileset layer the only visible one, or export the sheet with image.export {\"layer\":\"" + layer.name + "\"}.");
    if (doc.width != lay.width() || doc.height != lay.height())
        out.push_back(std::format("The canvas is {} x {} but the sheet is {} x {}: the tile numbers count rows of {} tiles of the PNG, so make the canvas the size of the sheet.", doc.width, doc.height, lay.width(), lay.height(), lay.columns));
}

// ---- the rules file -----------------------------------------------------------------------------------------------

std::string default_rules_path(const std::string& docRel, const std::string& layerName) {
    const std::string base = base_of(docRel);
    return layerName == "tileset" ? base + ".terrains.json" : base + "." + assets_detail::safe_file_name(layerName, "tileset") + ".terrains.json";
}

struct RulesWritten {
    std::string rel;
    bool changed = false;
    Json terrain;
};

RulesWritten write_rules(const std::string& projectDir, const std::string& docRel, const std::string& layerName, const TilesetSpec& spec, const std::string& rulesArg, bool overwrite,
                         const char* cmd) {
    RulesWritten out;
    if (rulesArg.empty()) {
        out.rel = default_rules_path(docRel, layerName);
    } else {
        auto norm = fs::normalize_checked(rulesArg);
        if (!norm.ok() || norm->empty()) arg_error(cmd, "/rules", "'" + rulesArg + "' is not a path inside the project.", "Example: \"assets/art/ground.terrains.json\".");
        if (!ends_with(*norm, ".json") || ends_with(*norm, kImageDocSuffix))
            arg_error(cmd, "/rules", "'" + *norm + "' is not a rules file name.", "A rules file ends in .json, for example \"assets/art/ground.terrains.json\" (not .image.json).");
        out.rel = *norm;
    }
    auto path = resolve_project_path(projectDir, out.rel);
    if (!path.ok()) fail("invalid_argument", path.error().message, path.error().hint);
    require_usable_manifest(projectDir);
    assets_detail::ProjectRootGuard root(projectDir);
    const Json entry = assets::entry(out.rel);
    const Json recipe = entry.is_object() && entry.contains("provenance") ? assets_detail::recipe_of(entry) : Json();
    const bool ours = recipe.is_object() && recipe.value("command", std::string()) == kRulesCommand && recipe.contains("args") && recipe["args"].is_object() &&
                      recipe["args"].value("path", std::string()) == docRel && recipe["args"].value("layer", std::string()) == layerName;
    std::error_code ec;
    const bool exists = std::filesystem::is_regular_file(*path, ec);
    if (exists && !ours && !overwrite)
        fail("exists", "'" + out.rel + "' already exists and is not the rules file of the tileset layer '" + layerName + "' of '" + docRel + "'.",
             "Pass overwrite: true to replace it, or give another path in `rules`.");

    const Json file = tileset_rules_file_json(spec, layerName);
    out.terrain = file["terrains"][0];
    const std::string text = dump_json(file);
    bool same = false;
    if (exists)
        if (auto old = tooling_detail::read_file(*path)) same = *old == text;
    if (!same) {
        std::string err;
        if (!tooling_detail::write_file(*path, text, &err)) fail("failed", "Cannot write '" + out.rel + "': " + err, "Check that the folder is writable.");
        out.changed = true;
    }
    const Json prov = Json::object({{"origin", "original"},
                                    {"ai", false},
                                    {"provider", "factoria " + std::string(kRulesCommand)},
                                    {"license", "CC0-1.0"},
                                    {"author", "factoria"},
                                    {"source", docRel},
                                    {"notes", "Autotile rules (Tilemap.terrains) of the tileset layer '" + layerName + "' of '" + docRel + "': which tile of the sheet to use for each combination of neighbours."},
                                    {"date", assets::today()}});
    Json withRecipe = prov;
    withRecipe["recipe"] = assets_detail::make_recipe(projectDir, kRulesCommand, Json::object({{"path", docRel}, {"layer", layerName}, {"rules", out.rel}}), {docRel});
    auto updated = assets::update_entry(out.rel, [&](Json& e) { e["provenance"] = withRecipe; });
    if (!updated.ok()) fail("failed", "The rules were written, but assets.json was not updated: " + updated.error().message, updated.error().hint);
    return out;
}

// What to put in a Tilemap to use the set.
Json tilemap_hint(const std::string& pngRel, const TilesetLayout& lay, const std::string& rulesRel, const std::string& terrainName) {
    return Json::object({{"tileset", pngRel},
                         {"tileSize", Json::array({lay.tileWidth, lay.tileHeight})},
                         {"columns", lay.columns},
                         {"terrains", rulesRel},
                         {"terrain", terrainName}});
}

Json layout_json(const TilesetLayout& l) {
    return Json::object({{"tileWidth", l.tileWidth}, {"tileHeight", l.tileHeight}, {"columns", l.columns}, {"rows", l.rows}, {"slots", l.slots},
                         {"variations", l.variations}, {"tiles", l.tiles}, {"width", l.width()}, {"height", l.height()}});
}

// ---- image.tile.set ------------------------------------------------------------------------------------------------

Json tile_set(const std::string& projectDir, const Json& a) {
    const char* cmd = "image.tile.set";
    check_arg_keys(cmd, a, "", {"path", "enabled", "width", "height", "bake"});
    DocFile d = open_doc(projectDir, arg_string(a, "path", true), cmd);
    const bool enabled = arg_bool(a, "enabled", true);
    const int w = int_arg(a, cmd, "width", 1, kImageDocMaxSide, 0), h = int_arg(a, cmd, "height", 1, kImageDocMaxSide, 0);
    if (!enabled && (w || h)) arg_error(cmd, w ? "/width" : "/height", "`enabled` is false, so there is no tile size to set.", "Leave out width and height to turn tile mode off.");
    const auto before = render_document_json(projectDir, d.json);
    if (!enabled) {
        d.json.erase("tile");
    } else if (!w && !h) {
        d.json["tile"] = true;
    } else {
        Json t = Json::object();
        if (w) t["width"] = w;
        if (h) t["height"] = h;
        d.json["tile"] = t;
    }
    const ImageDocument doc = parse_or_fail(projectDir, d.rel, d.json);
    std::vector<std::string> warnings;
    Json extra = Json::object({{"tileMode", doc.tile.enabled}});
    Json steps = Json::array();
    if (doc.tile.enabled) {
        extra["tile"] = Json::object({{"width", doc.tile.width}, {"height", doc.tile.height}, {"columns", doc.width / doc.tile.width}, {"rows", doc.height / doc.tile.height}});
        const bool whole = doc.tile.width == doc.width && doc.tile.height == doc.height;
        steps.push_back(whole ? "The whole canvas is one tile: a stroke, line, shape or fill that leaves one edge comes back in on the opposite edge."
                              : std::format("The canvas is a sheet of {} x {} tiles of {} x {}: a drawing wraps around the edges of the tile it starts in.", doc.width / doc.tile.width, doc.height / doc.tile.height, doc.tile.width, doc.tile.height));
        steps.push_back("Draw with image.pixel / image.draw / image.paint (and the pixel helpers outline, shade, dither, cleanup): they wrap. image.layer.add of a gradient, shape or text layer, rotate / scale and image.edit transform do not.");
        steps.push_back("Check the result: image.tile.check {\"path\":\"" + d.rel + "\"}.");
    } else {
        steps.push_back("Tile mode is off: drawing stops at the canvas edges again.");
    }
    extra["nextSteps"] = steps;
    return commit_document(projectDir, d.rel, d.json, before, arg_bool(a, "bake", true), extra, warnings, cmd);
}

// ---- image.tile.check ----------------------------------------------------------------------------------------------

Json seam_problem(const TileSeam& s, const TileSeamReport& r, bool opposite) {
    const int col = r.columns ? s.a % r.columns : 0, row = r.columns ? s.a / r.columns : 0;
    Json runs = Json::array();
    for (const auto& [from, to] : s.runs) {
        const int base = s.axis == "horizontal" ? row * r.tileHeight : col * r.tileWidth;
        runs.push_back(Json::array({base + from, base + to}));
    }
    Json p = Json::object({{"tile", s.a}, {"column", col}, {"row", row}, {"axis", s.axis}, {"length", s.length}, {"mismatched", s.mismatched}, {"worst", s.worst},
                           {"mean", std::round(s.mean * 100.0) / 100.0}});
    if (opposite) {
        if (s.axis == "horizontal") {
            p["sides"] = "right column against left column";
            p["columns"] = Json::array({col * r.tileWidth + r.tileWidth - 1, col * r.tileWidth});
            p["rows"] = runs;
        } else {
            p["sides"] = "bottom row against top row";
            p["rows"] = Json::array({row * r.tileHeight + r.tileHeight - 1, row * r.tileHeight});
            p["columns"] = runs;
        }
        p["message"] = std::format("{} of tile {} (column {}, row {}): {} of {} pixel pairs differ by more than {} (the worst by {}).", p["sides"].get<std::string>(), s.a, col, row,
                                   s.mismatched, s.length, r.tolerance, s.worst);
    }
    return p;
}

Json tile_check(const std::string& projectDir, const Json& a) {
    const char* cmd = "image.tile.check";
    check_arg_keys(cmd, a, "", {"path", "tileWidth", "tileHeight", "tolerance", "scale", "tile"});
    DocFile d = open_doc(projectDir, arg_string(a, "path", true), cmd);
    const ImageDocument doc = parse_or_fail(projectDir, d.rel, d.json);
    const Image img = render_or_fail(projectDir, doc);
    int tw = int_arg(a, cmd, "tileWidth", 1, kImageDocMaxSide, 0), th = int_arg(a, cmd, "tileHeight", 1, kImageDocMaxSide, 0);
    std::string source = "the arguments";
    if (!tw && !th) {
        if (doc.tile.enabled) {
            tw = doc.tile.width;
            th = doc.tile.height;
            source = "the document's `tile`";
        } else {
            tw = img.width;
            th = img.height;
            source = "the whole canvas";
        }
    } else {
        if (!tw) tw = th;
        if (!th) th = tw;
    }
    if (tw > img.width || th > img.height || img.width % tw || img.height % th)
        arg_error(cmd, tw > img.width || img.width % tw ? "/tileWidth" : "/tileHeight",
                  std::format("A tile of {} x {} does not fit the picture of {} x {} a whole number of times.", tw, th, img.width, img.height),
                  std::format("Use a size that divides the canvas, such as {} x {}; or leave tileWidth and tileHeight out to check the picture as one tile.", img.width % 2 == 0 ? img.width / 2 : img.width, img.height % 2 == 0 ? img.height / 2 : img.height));
    const int tolerance = int_arg(a, cmd, "tolerance", 0, 255, -1);
    const bool exact = exact_colours(projectDir, doc);
    const TileSeamReport r = check_tile_opposites(img, tw, th, tolerance, exact);
    int scale = int_arg(a, cmd, "scale", 1, 16, 0);
    if (!scale) scale = std::clamp(768 / (3 * std::max(tw, th)), 1, 8);
    const int cells = r.columns * r.rows;
    const int tileArg = int_arg(a, cmd, "tile", 0, std::max(0, cells - 1), -1);
    const int shown = tileArg >= 0 ? tileArg : (r.bad.empty() ? 0 : r.bad[0].a);
    const Image preview = tile_check_preview(img, tw, th, shown, r, scale);
    const std::string previewRel = write_preview(projectDir, d.rel, ".tilecheck.png", preview);

    Json problems = Json::array();
    constexpr std::size_t kMax = 40;
    for (std::size_t i = 0; i < r.bad.size() && i < kMax; ++i) problems.push_back(seam_problem(r.bad[i], r, true));
    Json out = Json::object({{"path", d.rel},
                             {"seamless", r.seamless()},
                             {"tile", Json::object({{"width", tw}, {"height", th}, {"columns", r.columns}, {"rows", r.rows}, {"from", source}})},
                             {"tolerance", r.tolerance},
                             {"toleranceAutomatic", r.toleranceAutomatic},
                             {"interior", std::round(r.interior * 100.0) / 100.0},
                             {"tilesChecked", r.tilesChecked},
                             {"seamsChecked", r.seamsChecked},
                             {"pixelPairs", r.pixelPairs},
                             {"badSeams", r.bad.size()},
                             {"problems", problems},
                             {"previewTile", shown}});
    if (r.bad.size() > kMax) out["problemsTruncated"] = true;
    if (!previewRel.empty()) {
        out["preview"] = previewRel;
        out["$image"] = preview_image(projectDir, previewRel);
    }
    Json warnings = Json::array();
    if (r.tilesChecked == 0) warnings.push_back("Every tile of the picture is empty (fully transparent), so there is nothing to compare.");
    if (r.toleranceAutomatic) warnings.push_back(std::format("No tolerance was given: {} (1.5 x the mean difference of neighbouring pixels inside the tiles, {:.1f}). Pass `tolerance` to decide yourself.", r.tolerance, r.interior));
    else if (exact && r.tolerance == 0 && tolerance < 0) warnings.push_back("Pixel art (a palette or style.pixelArt): the colours of facing pixels must be equal.");
    if (source == "the whole canvas" && !doc.tile.enabled)
        warnings.push_back("The picture was checked as one tile. If it is a sheet of tiles, pass tileWidth and tileHeight, or set them in the document with image.tile.set; if it is an autotile set use image.tileset.check.");
    if (!warnings.empty()) out["warnings"] = warnings;
    Json steps = Json::array();
    if (r.seamless()) {
        steps.push_back(r.tilesChecked ? "The tile repeats without a visible seam: its right column matches its left column and its bottom row matches its top row." : "Draw something first.");
    } else {
        steps.push_back("The red lines in the preview (the middle tile of 3 x 3 copies) mark the pixels that do not match across the seam. `problems` lists them with their canvas coordinates.");
        if (!doc.tile.enabled)
            steps.push_back("Turn on wrap-around editing so that changing one edge changes the opposite one: image.tile.set {\"path\":\"" + d.rel + "\"}; then draw with image.pixel / image.draw / image.paint.");
        else
            steps.push_back("Tile mode is on, so a pixel drawn at the right edge wraps to the left edge: redraw the marked pixels with image.pixel (the stroke continues on the other side), or run image.pixel.cleanup on the area.");
        steps.push_back("Run image.tile.check again until `seamless` is true.");
    }
    out["nextSteps"] = steps;
    return out;
}

// ---- image.tileset.build -------------------------------------------------------------------------------------------

Json tileset_build(const std::string& projectDir, const Json& a) {
    const char* cmd = "image.tileset.build";
    check_arg_keys(cmd, a, "", {"path", "layer", "mode", "tileWidth", "tileHeight", "columns", "variations", "seed", "terrain", "parts", "rules", "writeRules", "palette", "ramps",
                                "description", "output", "overwrite", "bake"});
    const std::string rel = doc_path_arg(arg_string(a, "path", true), cmd);
    const std::string layerName = a.contains("layer") && !a["layer"].is_null() ? arg_string(a, "layer", true) : "tileset";
    if (layerName.empty()) arg_error(cmd, "/layer", "`layer` is empty.", "A layer name such as \"tileset\".");
    auto path = resolve_project_path(projectDir, rel);
    if (!path.ok()) fail("invalid_argument", path.error().message, path.error().hint);
    require_usable_manifest(projectDir);
    std::error_code ec;
    const bool exists = std::filesystem::is_regular_file(*path, ec);
    DocFile d;
    std::optional<Image> before;
    if (exists) {
        d = open_doc(projectDir, rel, cmd);
        before = render_document_json(projectDir, d.json);
    } else {
        d.rel = rel;
        d.json = Json::object({{"format", kImageDocFormat}, {"width", 1}, {"height", 1}, {"layers", Json::array()}});
    }
    // the layer: found (and updated in place) or new
    LayerRef ref;
    bool created = false;
    if (try_find_layer(d.json, Json(layerName), cmd, "layer", ref)) {
        const std::string kind = ref.layer->value("kind", std::string());
        if (kind != "tileset")
            arg_error(cmd, "/layer", "The layer '" + layerName + "' of '" + rel + "' is a " + kind + " layer, not a tileset layer.", "Pick another layer name for the tileset, for example {\"layer\":\"" + unique_layer_name(d.json, "tileset") + "\"}.");
    } else {
        d.json["layers"].push_back(Json::object({{"kind", "tileset"}, {"name", layerName}}));
        created = true;
        ref = find_layer(d.json, Json(layerName), cmd, "layer");
    }
    Json& layer = *ref.layer;
    for (const char* k : {"mode", "terrain", "tileWidth", "tileHeight", "columns", "variations", "seed"}) {
        auto it = a.find(k);
        if (it == a.end()) continue;
        if (it->is_null()) layer.erase(k);
        else layer[k] = *it;
    }
    if (a.contains("parts") && !a["parts"].is_null()) {
        if (!a["parts"].is_object())
            arg_error(cmd, "/parts", "`parts` must be an object {partName: picture}, got " + describe_json_value(a["parts"]) + ".", "Example: {\"inside\":{\"source\":\"assets/tiles/grass.png\"},\"edge\":{...},\"corner\":{...},\"innerCorner\":{...}}. See image.tileset.info.");
        if (!layer.contains("parts") || !layer["parts"].is_object()) layer["parts"] = Json::object();
        for (auto it = a["parts"].begin(); it != a["parts"].end(); ++it) {
            if (it.value().is_null()) layer["parts"].erase(it.key());
            else layer["parts"][it.key()] = it.value();
        }
    }
    for (const char* k : {"palette", "ramps"})
        if (a.contains(k) && !a[k].is_null()) d.json[k] = a[k];
    if (a.contains("description") && a["description"].is_string()) d.json["description"] = a["description"];
    if (a.contains("output") && a["output"].is_string()) d.json["output"] = a["output"];

    // the layout, from the document as it will be (a probe: no tile mode, any canvas)
    Json probe = d.json;
    probe.erase("tile");
    const ImageDocument probed = parse_or_fail(projectDir, rel, probe);
    const ImageLayer& probedLayer = pick_tileset_layer(probed, layerName, cmd);
    const TilesetSpec spec = probedLayer.tileset;
    const TilesetLayout lay = tileset_layout(spec);
    if (lay.width() > kImageDocMaxSide || lay.height() > kImageDocMaxSide)
        arg_error(cmd, "/columns", std::format("The sheet would be {} x {} pixels ({} tiles of {} x {} in {} columns); a picture is at most {} on a side.", lay.width(), lay.height(), lay.tiles, lay.tileWidth, lay.tileHeight, lay.columns, kImageDocMaxSide),
                  "Use fewer variations, smaller tiles, or more `columns` for a wide sheet (blob47 has 47 tiles per variation).");
    std::vector<std::string> warnings;
    const bool resized = exists && (d.json.value("width", 0) != lay.width() || d.json.value("height", 0) != lay.height());
    d.json["width"] = lay.width();
    d.json["height"] = lay.height();
    d.json["tile"] = Json::object({{"width", lay.tileWidth}, {"height", lay.tileHeight}});
    if (resized && d.json["layers"].size() > 1) warnings.push_back(std::format("The canvas was resized to the sheet, {} x {}: the other layers of the document were not moved.", lay.width(), lay.height()));

    const ImageDocument finalDoc = parse_or_fail(projectDir, rel, d.json);
    const ImageLayer& finalLayer = pick_tileset_layer(finalDoc, layerName, cmd);
    sheet_warnings(finalDoc, finalLayer, lay, warnings);

    // rules first would write a file for a document that then fails: the document goes first (it is validated whole)
    Json extra = Json::object();
    Json result = commit_document(projectDir, rel, d.json, before, arg_bool(a, "bake", true), extra, warnings, cmd);
    const std::string pngRel = result.value("path", std::string());
    Json tilesetInfo = Json::object({{"layer", layerName}, {"created", created}, {"mode", spec.mode}, {"seed", spec.seed}, {"layout", layout_json(lay)},
                                     {"parts", [&] {
                                          Json p = Json::object();
                                          for (const auto& [name, variants] : spec.parts) p[name] = variants.size();
                                          return p;
                                      }()}});
    result["tileset"] = tilesetInfo;
    if (arg_bool(a, "writeRules", true)) {
        const RulesWritten rules = write_rules(projectDir, rel, layerName, spec, a.contains("rules") && a["rules"].is_string() ? a["rules"].get<std::string>() : std::string(), arg_bool(a, "overwrite", false), cmd);
        result["rules"] = Json::object({{"path", rules.rel}, {"changed", rules.changed}});
        result["terrain"] = rules.terrain;
        result["tilemap"] = tilemap_hint(pngRel, lay, rules.rel, rules.terrain.value("name", std::string()));
        result["nextSteps"] = Json::array({
            "Check that the tiles fit together: image.tileset.check {\"path\":\"" + rel + "\"}.",
            "Use it in a map: set Tilemap.tileset \"" + pngRel + "\", tileSize [" + std::to_string(lay.tileWidth) + ", " + std::to_string(lay.tileHeight) + "], columns " + std::to_string(lay.columns) +
                ", then tilemap.set_terrains {\"id\":\"<map entity>\",\"path\":\"" + rules.rel + "\",\"retile\":true}; paint with tilemap.paint_terrain.",
            "Change a part and run this command again (or assets.regenerate {\"stale\":true}): the sheet and the rules are updated in place.",
            "Run image.tileset.info for the drawing of each part and the tile table."});
    } else {
        result["nextSteps"] = Json::array({"No rules file was written (writeRules false): image.tileset.rules {\"path\":\"" + rel + "\"} writes it."});
    }
    return result;
}

// ---- image.tileset.rules -------------------------------------------------------------------------------------------

Json tileset_rules(const std::string& projectDir, const Json& a) {
    const char* cmd = kRulesCommand;
    check_arg_keys(cmd, a, "", {"path", "layer", "rules", "overwrite"});
    DocFile d = open_doc(projectDir, arg_string(a, "path", true), cmd);
    const ImageDocument doc = parse_or_fail(projectDir, d.rel, d.json);
    const ImageLayer& layer = pick_tileset_layer(doc, a.contains("layer") && a["layer"].is_string() ? a["layer"].get<std::string>() : std::string(), cmd);
    const TilesetLayout lay = tileset_layout(layer.tileset);
    std::vector<std::string> warnings;
    sheet_warnings(doc, layer, lay, warnings);
    const RulesWritten rules = write_rules(projectDir, d.rel, layer.name, layer.tileset, a.contains("rules") && a["rules"].is_string() ? a["rules"].get<std::string>() : std::string(),
                                           arg_bool(a, "overwrite", false), cmd);
    const std::string pngRel = image_bake_status(projectDir, d.rel).output;
    Json out = Json::object({{"path", rules.rel}, {"document", d.rel}, {"layer", layer.name}, {"changed", rules.changed}, {"terrain", rules.terrain}, {"layout", layout_json(lay)},
                             {"tilemap", tilemap_hint(pngRel, lay, rules.rel, rules.terrain.value("name", std::string()))}});
    if (!warnings.empty()) out["warnings"] = warnings;
    out["nextSteps"] = Json::array({"Give the rules to a Tilemap: tilemap.set_terrains {\"id\":\"<map entity>\",\"path\":\"" + rules.rel + "\",\"retile\":true}.",
                                    "The rules number the tiles of '" + pngRel + "': bake the document (image.bake) after changing the tileset layer."});
    return out;
}

// ---- image.tileset.info --------------------------------------------------------------------------------------------

struct PartDoc {
    const char* name;
    const char* what;
    std::vector<const char*> diagram;
};

const std::vector<PartDoc>& part_docs() {
    static const std::vector<PartDoc> docs = {
        {"inside", "A flat tile of the terrain: what a tile shows when all its neighbours are the same terrain.", {"####", "####", "####", "####"}},
        {"edge", "The terrain's TOP edge: terrain below, nothing above. Used (flipped) for the sides with no neighbour.", {"....", "....", "####", "####"}},
        {"corner", "The terrain's TOP-LEFT outer corner: terrain to the right and below, nothing above or to the left. Used (flipped) for the other three corners.", {"....", ".###", ".###", ".###"}},
        {"innerCorner", "blob47 only. An inside tile with its TOP-LEFT corner cut out: the neighbours above and to the left are terrain, the one diagonally between them is not.", {".###", "####", "####", "####"}},
        {"edgeBottom", "Optional. The bottom edge, when flipping `edge` would put the light on the wrong side.", {"####", "####", "....", "...."}},
        {"edgeLeft", "Optional (required when the tile is not square). The terrain's LEFT edge: terrain to the right, nothing to the left.", {"..##", "..##", "..##", "..##"}},
        {"edgeRight", "Optional. The right edge, instead of `edgeLeft` flipped.", {"##..", "##..", "##..", "##.."}},
        {"cornerNE", "Optional. The top-right outer corner, instead of `corner` flipped.", {"....", "###.", "###.", "###."}},
        {"cornerSW", "Optional. The bottom-left outer corner, instead of `corner` flipped.", {".###", ".###", ".###", "...."}},
        {"cornerSE", "Optional. The bottom-right outer corner, instead of `corner` flipped.", {"###.", "###.", "###.", "...."}},
        {"innerCornerNE", "Optional (blob47). The inner corner at the top right, instead of `innerCorner` flipped.", {"###.", "####", "####", "####"}},
        {"innerCornerSW", "Optional (blob47). The inner corner at the bottom left.", {"####", "####", "####", ".###"}},
        {"innerCornerSE", "Optional (blob47). The inner corner at the bottom right.", {"####", "####", "####", "###."}},
    };
    return docs;
}

Json tileset_info(const std::string& projectDir, const Json& a) {
    const char* cmd = "image.tileset.info";
    check_arg_keys(cmd, a, "", {"path", "layer", "mode", "squareTile"});
    std::string mode = a.contains("mode") && a["mode"].is_string() ? a["mode"].get<std::string>() : std::string();
    bool square = arg_bool(a, "squareTile", true);
    std::optional<TilesetSpec> spec;
    std::string docRel, layerName;
    std::vector<std::string> warnings;
    if (a.contains("path") && !a["path"].is_null()) {
        DocFile d = open_doc(projectDir, arg_string(a, "path", true), cmd);
        auto parsed = parse_image_document(d.json, d.rel, projectDir);
        if (!parsed.ok()) fail("invalid_argument", parsed.error().message, parsed.error().hint);
        const ImageLayer& layer = pick_tileset_layer(*parsed, a.contains("layer") && a["layer"].is_string() ? a["layer"].get<std::string>() : std::string(), cmd);
        spec = layer.tileset;
        docRel = d.rel;
        layerName = layer.name;
        if (!mode.empty() && mode != spec->mode) warnings.push_back("`mode` is ignored: the layer's mode is " + spec->mode + ".");
        mode = spec->mode;
        square = spec->tileWidth == spec->tileHeight;
    }
    if (mode.empty()) mode = "blob47";
    AutotileMode am = AutotileMode::Blob47;
    if (!autotile_mode_from_name(mode, am)) arg_error(cmd, "/mode", "Unknown tileset mode '" + mode + "'.", did_you_mean(mode, std::vector<std::string>{"basic16", "blob47"}));
    const std::vector<std::string> required = tileset_required_parts(mode, square);
    Json parts = Json::array();
    for (const PartDoc& p : part_docs()) {
        const bool blobOnly = std::string(p.name).rfind("innerCorner", 0) == 0;
        if (blobOnly && mode != "blob47") continue;
        Json diagram = Json::array();
        for (const char* row : p.diagram) diagram.push_back(row);
        Json item = Json::object({{"name", p.name}, {"required", std::find(required.begin(), required.end(), p.name) != required.end()}, {"what", p.what}, {"diagram", diagram}});
        if (spec) {
            const auto* have = spec->part(p.name);
            item["given"] = have ? Json(have->size()) : Json(0);
        }
        parts.push_back(item);
    }
    Json out = Json::object({{"mode", mode},
                             {"requiredParts", Json(required)},
                             {"parts", parts},
                             {"legend", "In the diagrams # is the terrain and . is what is outside it (transparent, or the ground below). Each part is a whole tile picture; the set is built from its four quadrants."}});
    out["howItWorks"] = Json::array({
        "A tile is made of four quadrants (top-left, top-right, bottom-left, bottom-right). Each takes the matching quarter of one part, picked by the neighbours next to it.",
        "No orthogonal neighbour next to the quadrant: the outer `corner`. One neighbour: the `edge` (top or bottom when the vertical neighbour is missing, else left or right). Both neighbours but not the diagonal one (blob47): the `innerCorner`. All present: `inside`.",
        "The parts are drawn for one orientation and flipped for the others (a tile that is not square cannot be turned, so it needs `edgeLeft` too). Optional parts replace a flipped orientation.",
        "A part can be a list of variants: with `variations` above 1, variation 0 of every tile uses the first variant and the other variations pick variants by `seed`, so the same seed always makes the same sheet.",
        "A part is {\"source\": \"x.png\"} (one tile), {\"rows\": [...]} (text rows of the document's palette) or {\"color\": \"#rrggbb\"}."});
    out["tileNumbers"] = "Tile number = slot * variations + variation. The sheet holds the tiles in that order, row by row, `columns` per row (default " + std::string(mode == "basic16" ? "4" : "8") + ").";
    // the table
    const auto& masks = autotile_masks(am);
    Json table = Json::array();
    for (std::size_t slot = 0; slot < masks.size(); ++slot)
        table.push_back(Json::object({{"slot", slot}, {"mask", masks[slot]}, {"neighbours", mask_name(masks[slot])}}));
    out["slots"] = table;
    out["maskBits"] = "N=1 NE=2 E=4 SE=8 S=16 SW=32 W=64 NW=128 (a diagonal counts only when both orthogonal neighbours next to it are present; basic16 has no diagonals).";
    if (spec) {
        const TilesetLayout lay = tileset_layout(*spec);
        out["document"] = docRel;
        out["layer"] = layerName;
        out["layout"] = layout_json(lay);
        Json tiles = Json::array();
        const std::vector<int> tm = tileset_tile_masks(*spec);
        for (int i = 0; i < lay.tiles && i < 400; ++i)
            tiles.push_back(Json::object({{"tile", i}, {"slot", i / lay.variations}, {"variation", i % lay.variations}, {"column", i % lay.columns}, {"row", i / lay.columns},
                                          {"x", (i % lay.columns) * lay.tileWidth}, {"y", (i / lay.columns) * lay.tileHeight}, {"neighbours", mask_name(tm[std::size_t(i)])}}));
        out["tiles"] = tiles;
    }
    if (!warnings.empty()) out["warnings"] = warnings;
    out["nextSteps"] = Json::array({"Make a set: image.tileset.build {\"path\":\"assets/art/ground.image.json\",\"mode\":\"" + mode + "\",\"tileWidth\":16,\"tileHeight\":16,\"parts\":{\"inside\":{\"source\":\"assets/art/ground-inside.png\"}, ...}}.",
                                    "Draw the parts as tiles of the size you ask for, as PNGs or as text rows; docs.read IMAGES, section Tiles, has a complete example."});
    return out;
}

// ---- image.tileset.check -------------------------------------------------------------------------------------------

Json tileset_check(const std::string& projectDir, const Json& a) {
    const char* cmd = "image.tileset.check";
    check_arg_keys(cmd, a, "", {"path", "layer", "tolerance", "scale"});
    DocFile d = open_doc(projectDir, arg_string(a, "path", true), cmd);
    std::vector<ImageIssue> issues;
    auto parsed = parse_image_document(d.json, d.rel, projectDir, &issues);
    if (!parsed.ok()) {
        Json list = Json::array();
        for (const ImageIssue& i : issues) list.push_back(Json::object({{"pointer", i.pointer}, {"message", i.message}, {"hint", i.hint}}));
        return Json::object({{"path", d.rel}, {"ok", false}, {"issues", list},
                             {"nextSteps", Json::array({"Fix the problems above (each names its JSON pointer), then run image.tileset.check again. image.tileset.info shows the parts a set needs."})}});
    }
    const ImageLayer& layer = pick_tileset_layer(*parsed, a.contains("layer") && a["layer"].is_string() ? a["layer"].get<std::string>() : std::string(), cmd);
    const TilesetSpec& spec = layer.tileset;
    const TilesetLayout lay = tileset_layout(spec);

    // the parts, one by one: every problem, not only the first
    Json problems = Json::array();
    std::map<std::string, Image> loaded;
    auto load = [&](const std::string& pointer, const std::string& relPng) -> const Image& {
        auto it = loaded.find(relPng);
        if (it == loaded.end()) {
            auto img = read_png(projectDir, relPng);
            if (!img) throw std::runtime_error(pointer + ": cannot read '" + relPng + "'");
            it = loaded.emplace(relPng, std::move(*img)).first;
        }
        return it->second;
    };
    for (const auto& [name, variants] : spec.parts)
        for (const TilesetPart& v : variants) {
            Json issue;
            if (!v.source.empty()) {
                auto img = read_png(projectDir, v.source);
                if (!img) issue = Json::object({{"pointer", v.pointer + "/source"}, {"message", "'" + v.source + "' cannot be read as a PNG."}, {"hint", "Check the file; it must be a PNG of the project."}});
                else if (img->width != lay.tileWidth || img->height != lay.tileHeight)
                    issue = Json::object({{"pointer", v.pointer + "/source"},
                                          {"message", std::format("'{}' is {} x {} pixels but the tiles of this set are {} x {}.", v.source, img->width, img->height, lay.tileWidth, lay.tileHeight)},
                                          {"hint", "Every picture of a part is exactly one tile. Resize it, or change tileWidth / tileHeight of the layer."}});
            } else if (!v.rows.empty()) {
                const int rowsH = int(v.rows.size());
                int rowsW = 0;
                bool ragged = false;
                for (const std::string& r : v.rows) {
                    if (rowsW && int(r.size()) != rowsW) ragged = true;
                    rowsW = std::max<int>(rowsW, int(r.size()));
                }
                if (ragged) issue = Json::object({{"pointer", v.pointer + "/rows"}, {"message", "The rows have different lengths."}, {"hint", "Every row has one character per pixel of the tile."}});
                else if (rowsW != lay.tileWidth || rowsH != lay.tileHeight)
                    issue = Json::object({{"pointer", v.pointer + "/rows"}, {"message", std::format("The rows are {} x {} pixels but the tiles of this set are {} x {}.", rowsW, rowsH, lay.tileWidth, lay.tileHeight)},
                                          {"hint", "Every part is exactly one tile: tileHeight rows of tileWidth characters."}});
            }
            if (!issue.is_null()) problems.push_back(issue);
        }
    if (!problems.empty())
        return Json::object({{"path", d.rel}, {"layer", layer.name}, {"ok", false}, {"issues", problems},
                             {"nextSteps", Json::array({"Fix the parts named above, then run image.tileset.check again (or image.tileset.build to rebuild the sheet)."})}});

    auto built = [&]() -> Result<TilesetBuild> {
        try {
            return build_tileset(spec, parsed->palette, load);
        } catch (const std::exception& e) {
            return make_error(e.what(), "Check the part's file.");
        }
    }();
    if (!built.ok()) fail("invalid_argument", built.error().message, built.error().hint);

    const bool blob = spec.mode == "blob47";
    const bool exact = exact_colours(projectDir, *parsed);
    const int tolerance = int_arg(a, cmd, "tolerance", 0, 255, -1);
    const std::vector<int> masks = tileset_tile_masks(spec);
    const TileSeamReport r = check_tile_set(built->sheet, lay.tileWidth, lay.tileHeight, lay.columns, masks, blob, tolerance, exact);
    int scale = int_arg(a, cmd, "scale", 1, 16, 0);
    if (!scale) scale = std::clamp(768 / std::max(lay.width(), lay.height()), 1, 8);
    const Image preview = tile_set_preview(built->sheet, lay.tileWidth, lay.tileHeight, r, scale);
    const std::string previewRel = write_preview(projectDir, d.rel, ".tilesetcheck.png", preview);

    auto describe_tile = [&](int t) {
        const int slot = t / lay.variations;
        return Json::object({{"tile", t}, {"slot", slot}, {"variation", t % lay.variations}, {"neighbours", mask_name(t < int(masks.size()) ? masks[std::size_t(t)] : 0)},
                             {"column", t % lay.columns}, {"row", t / lay.columns}});
    };
    Json seams = Json::array();
    constexpr std::size_t kMax = 40;
    for (std::size_t i = 0; i < r.bad.size() && i < kMax; ++i) {
        const TileSeam& s = r.bad[i];
        const bool horizontal = s.axis == "horizontal";
        Json item = Json::object({{"axis", s.axis}, {"a", describe_tile(s.a)}, {"b", describe_tile(s.b)}, {"length", s.length}, {"mismatched", s.mismatched}, {"worst", s.worst},
                                  {"mean", std::round(s.mean * 100.0) / 100.0}});
        item["message"] = std::format("The {} of tile {} ({}) does not match the {} of tile {} ({}) where they touch: {} of {} pixel pairs differ by more than {}, the worst by {}.",
                                      horizontal ? "right column" : "bottom row", s.a, mask_name(masks[std::size_t(s.a)]), horizontal ? "left column" : "top row", s.b,
                                      mask_name(masks[std::size_t(s.b)]), s.mismatched, s.length, r.tolerance, s.worst);
        seams.push_back(item);
    }
    Json out = Json::object({{"path", d.rel}, {"layer", layer.name}, {"ok", true}, {"seamless", r.seamless()}, {"mode", spec.mode}, {"layout", layout_json(lay)},
                             {"tolerance", r.tolerance}, {"toleranceAutomatic", r.toleranceAutomatic}, {"interior", std::round(r.interior * 100.0) / 100.0},
                             {"seamsChecked", r.seamsChecked}, {"pixelPairs", r.pixelPairs}, {"badSeams", r.bad.size()}, {"problems", seams}});
    if (r.bad.size() > kMax) out["problemsTruncated"] = true;
    if (!previewRel.empty()) {
        out["preview"] = previewRel;
        out["$image"] = preview_image(projectDir, previewRel);
    }
    Json warnings = Json::array();
    for (const std::string& w : built->warnings) warnings.push_back(w);
    if (r.toleranceAutomatic) warnings.push_back(std::format("No tolerance was given: {} (1.5 x the mean difference of neighbouring pixels inside the tiles). Pass `tolerance` to decide yourself.", r.tolerance));
    if (!warnings.empty()) out["warnings"] = warnings;
    Json steps = Json::array();
    if (r.seamless()) {
        steps.push_back("Every pair of tiles that can stand side by side in a map fits (" + std::to_string(r.seamsChecked) + " seams compared).");
        steps.push_back("Write the rules and use the set: image.tileset.rules {\"path\":\"" + d.rel + "\"}, then tilemap.set_terrains.");
    } else {
        steps.push_back("The red marks in the preview sit on the sides of tiles that do not fit the tile next to them. Most often a part's edge does not meet the `inside` tile: the pixels of the `inside` border and of the `edge` / `corner` rows must continue into each other.");
        steps.push_back("Fix the part (the pointer of a part is /layers/<n>/parts/<name>) and run image.tileset.build again; or raise `tolerance` when a small difference is fine.");
    }
    out["nextSteps"] = steps;
    return out;
}

}  // namespace

// ---- registration ---------------------------------------------------------------------------------------------------

void register_tile_commands(CommandRegistry& registry, const std::string& projectDir) {
    const std::string pathDoc = "The image document, project-relative, ending in .image.json, e.g. 'assets/art/ground.image.json'.";
    auto add = [&](const char* name, const char* summary, const std::string& description, const std::string& schema, Json (*fn)(const std::string&, const Json&), bool readOnly) {
        CommandInfo info;
        info.name = name;
        info.category = "assets";
        info.readOnly = readOnly;
        info.summary = summary;
        info.description = description;
        info.inputSchema = Json::parse(schema);
        registry.add(info, [projectDir, fn](const Json& args) { return fn(projectDir, args); });
    };

    add("image.tile.set", "Turn tile mode (wrap-around editing) on or off for an image document.",
        "Sets the `tile` key of the document at `path`. With tile mode on, the drawing commands (image.pixel, image.draw, image.paint, the pixel helpers outline / shade / dither / cleanup, "
        "image.edit move) wrap around the edges of a tile: what leaves the right edge comes back in on the left, so the edges keep matching while you draw. A shape wraps inside the tile "
        "that holds its first point (a pixel, the start of a line or run, the corner of a rectangle, the `at` of a fill, the first point of a stroke). Without `width` and `height` the whole canvas "
        "is one tile; with them the canvas is a sheet of tiles of that size (they must divide the canvas). `enabled` false turns it off. image.edit transform and the helpers rotate and "
        "scale do not wrap (they warn). Returns the tile grid and the picture. Example: {\"path\":\"assets/art/ground.image.json\"} or {\"path\":\"assets/art/sheet.image.json\",\"width\":16,\"height\":16}",
        "{\"type\":\"object\",\"required\":[\"path\"],\"properties\":{\"path\":{\"type\":\"string\",\"description\":\"" + pathDoc + "\"},"
        "\"enabled\":{\"type\":\"boolean\",\"default\":true,\"description\":\"False turns tile mode off (removes `tile` from the document).\"},"
        "\"width\":{\"type\":\"integer\",\"minimum\":1,\"description\":\"One tile's width in pixels; must divide the canvas width. Default: the canvas width.\"},"
        "\"height\":{\"type\":\"integer\",\"minimum\":1,\"description\":\"One tile's height in pixels; must divide the canvas height. Default: the canvas height.\"},"
        "\"bake\":{\"type\":\"boolean\",\"default\":true,\"description\":\"Also draw the PNG (default true).\"}}}",
        tile_set, false);

    add("image.tile.check", "Check that a picture (or each tile of a sheet) repeats without a visible seam, with a preview of 3 x 3 copies.",
        "Compares the pixels that touch when a tile repeats: its right column against its own left column and its bottom row against its top row, for every tile that is not empty. "
        "The tile is `tileWidth` x `tileHeight`, else the document's `tile`, else the whole canvas. `tolerance` (0 to 255) is how far apart two touching pixels may look: by default 0 for pixel art "
        "(a palette or style.pixelArt) and else 1.5 x the mean difference of neighbouring pixels inside the tiles, so a soft texture is not failed for its own gradient. "
        "Returns {seamless, tolerance, problems: [{tile, column, row, axis, sides, columns, rows (canvas coordinates, with the runs of mismatching pixels), mismatched, worst, mean, message}]} "
        "(the first 40), and the preview as `$image` and in `preview` (.factoria/previews/<document>.tilecheck.png): the tile 3 x 3 with red lines on the mismatching seam pixels. "
        "Reads the document as it is; for an autotile set use image.tileset.check. Example: {\"path\":\"assets/art/ground.image.json\"}",
        "{\"type\":\"object\",\"required\":[\"path\"],\"properties\":{\"path\":{\"type\":\"string\",\"description\":\"" + pathDoc + "\"},"
        "\"tileWidth\":{\"type\":\"integer\",\"minimum\":1,\"description\":\"One tile's width; must divide the picture. Default: the document's tile, else the whole canvas.\"},"
        "\"tileHeight\":{\"type\":\"integer\",\"minimum\":1,\"description\":\"One tile's height. Default as tileWidth.\"},"
        "\"tolerance\":{\"type\":\"integer\",\"minimum\":0,\"maximum\":255,\"description\":\"The largest difference between two touching pixels that still counts as matching. Default: automatic (0 for pixel art).\"},"
        "\"scale\":{\"type\":\"integer\",\"minimum\":1,\"maximum\":16,\"description\":\"Magnification of the preview. Default: fits about 768 pixels.\"},"
        "\"tile\":{\"type\":\"integer\",\"minimum\":0,\"description\":\"Which tile of a sheet the preview shows (row-major, 0-based). Default: the first with a problem.\"}}}",
        tile_check, true);

    add("image.tileset.build", "Make an autotile tileset (16 or 47 tiles) from a few parts (inside, edge, corner), bake the sheet and write the Tilemap rules.",
        "Makes the image document `path` (or adds the layer to an existing one) with a `tileset` layer that builds the whole set from parts: each part is one tile picture, "
        "a PNG (`source`), text `rows` of the document's palette, or one flat `color`; a list gives variants. Minimal parts: inside, edge, corner (+ innerCorner for blob47, + edgeLeft for tiles that are not square); "
        "image.tileset.info draws each one. Modes: basic16 (4 neighbours) and blob47 (8 neighbours, the common 47-tile set). `variations` 1 to 8 makes several pictures of every tile (the other variations pick variants of the parts by `seed`, "
        "the same seed always gives the same sheet). The canvas becomes the sheet (columns x rows of tiles), `tile` is set to the tile size, the PNG is baked, and the rules file (default <document>.terrains.json: the Tilemap.terrains entry with "
        "the exact tile of every neighbour combination) is written and recorded in assets.json. Run it again to update: keys you give override, `parts` merge by name (null removes one), nothing else changes, and the files are rewritten in place; "
        "assets.regenerate {\"stale\":true} does the same after a part PNG changed. Returns the bake result plus tileset {layer, mode, layout}, rules {path}, terrain (the rule) and tilemap {tileset, tileSize, columns, terrains} (what to put in the Tilemap). "
        "Example: {\"path\":\"assets/art/ground.image.json\",\"mode\":\"blob47\",\"tileWidth\":16,\"tileHeight\":16,\"palette\":[\"#1e4a14\",\"#2d5a1e\",\"#4a8a2c\"],\"parts\":{\"inside\":{\"rows\":[...16 rows...]},\"edge\":{\"rows\":[...]},\"corner\":{\"rows\":[...]},\"innerCorner\":{\"rows\":[...]}}}",
        "{\"type\":\"object\",\"required\":[\"path\"],\"properties\":{\"path\":{\"type\":\"string\",\"description\":\"" + pathDoc + " Created when it does not exist.\"},"
        "\"layer\":{\"type\":\"string\",\"default\":\"tileset\",\"description\":\"The tileset layer's name. Found and updated, or added.\"},"
        "\"mode\":{\"type\":\"string\",\"enum\":[\"basic16\",\"blob47\"],\"default\":\"blob47\",\"description\":\"basic16: 4 neighbours, 16 tiles. blob47: 8 neighbours, 47 tiles.\"},"
        "\"tileWidth\":{\"type\":\"integer\",\"minimum\":2,\"maximum\":512,\"description\":\"One tile's width in pixels (even). Required for a new layer; with only one of the sizes the tile is square.\"},"
        "\"tileHeight\":{\"type\":\"integer\",\"minimum\":2,\"maximum\":512,\"description\":\"One tile's height in pixels (even).\"},"
        "\"parts\":{\"type\":\"object\",\"description\":\"{partName: picture | [pictures]}; a picture is {source}, {rows} or {color}, or a PNG path. Merged into the layer's parts by name; null removes a part. Names: inside, edge, corner, innerCorner, edgeBottom, edgeLeft, edgeRight, cornerNE, cornerSW, cornerSE, innerCornerNE, innerCornerSW, innerCornerSE.\"},"
        "\"columns\":{\"type\":\"integer\",\"minimum\":1,\"maximum\":64,\"description\":\"Tiles per row of the sheet. Default 4 for basic16, 8 for blob47.\"},"
        "\"variations\":{\"type\":\"integer\",\"minimum\":1,\"maximum\":8,\"default\":1,\"description\":\"Pictures per tile; the others pick variants of the parts by seed.\"},"
        "\"seed\":{\"type\":\"integer\",\"default\":0,\"description\":\"Picks the variants of the tiles (and is stored in the rules, so painting picks the same variations).\"},"
        "\"terrain\":{\"type\":\"string\",\"description\":\"The terrain's name in the rules (paint with tilemap.paint_terrain {terrain}). Default: the layer name.\"},"
        "\"rules\":{\"type\":\"string\",\"description\":\"Where the rules file goes. Default: <document>.terrains.json.\"},"
        "\"writeRules\":{\"type\":\"boolean\",\"default\":true,\"description\":\"False writes no rules file.\"},"
        "\"palette\":{\"type\":\"array\",\"description\":\"The document's palette (colours) when parts use `rows`.\"},"
        "\"ramps\":{\"type\":\"array\",\"description\":\"The document's colour ramps.\"},"
        "\"description\":{\"type\":\"string\",\"description\":\"The document's description.\"},"
        "\"output\":{\"type\":\"string\",\"description\":\"The PNG the document bakes to. Default: next to the document.\"},"
        "\"overwrite\":{\"type\":\"boolean\",\"default\":false,\"description\":\"Replace the rules file when it exists and is not this layer's.\"},"
        "\"bake\":{\"type\":\"boolean\",\"default\":true,\"description\":\"Also draw the PNG (default true).\"}}}",
        tileset_build, false);

    add("image.tileset.info", "Explain the parts of an autotile tileset and list its tiles (slot, neighbours, position in the sheet).",
        "Describes what image.tileset.build is made of: for the mode (basic16 or blob47), each part with a small drawing, which are required for the tile shape, how the quadrants and flips make the set, "
        "and the table of slots with their neighbour masks. With `path` (and `layer`) also the layout of that tileset layer and every tile with its sheet position and neighbours. "
        "Example: {\"mode\":\"blob47\"} or {\"path\":\"assets/art/ground.image.json\"}",
        "{\"type\":\"object\",\"properties\":{\"path\":{\"type\":\"string\",\"description\":\"" + pathDoc + " Optional: describe its tileset layer.\"},"
        "\"layer\":{\"type\":\"string\",\"description\":\"The tileset layer. Default: the only one.\"},"
        "\"mode\":{\"type\":\"string\",\"enum\":[\"basic16\",\"blob47\"],\"description\":\"Without `path`: which set to describe. Default blob47.\"},"
        "\"squareTile\":{\"type\":\"boolean\",\"default\":true,\"description\":\"Without `path`: false for a tile that is not square (it also needs edgeLeft).\"}}}",
        tileset_info, true);

    add("image.tileset.check", "Check an autotile tileset: every part is one tile big, and every pair of tiles that can touch in a map fits.",
        "Reads the tileset layer of the document at `path`, reports every part that is missing, unreadable or the wrong size (with its JSON pointer), then builds the sheet and compares the sides of the tiles "
        "that stand side by side in a map: tile A east of tile B needs A to have an east neighbour and B a west one (and for blob47 the cells around the pair to agree), and likewise north-south. "
        "`tolerance` as in image.tile.check (automatic by default: 0 for pixel art). Returns {seamless, problems: [{axis, a, b (tile, slot, neighbours, sheet position), mismatched, worst, message}]} and the sheet "
        "magnified with red marks on the failing sides as `$image` (.factoria/previews/<document>.tilesetcheck.png). Example: {\"path\":\"assets/art/ground.image.json\"}",
        "{\"type\":\"object\",\"required\":[\"path\"],\"properties\":{\"path\":{\"type\":\"string\",\"description\":\"" + pathDoc + "\"},"
        "\"layer\":{\"type\":\"string\",\"description\":\"The tileset layer. Default: the only one.\"},"
        "\"tolerance\":{\"type\":\"integer\",\"minimum\":0,\"maximum\":255,\"description\":\"The largest difference between two touching pixels that still counts as matching. Default: automatic (0 for pixel art).\"},"
        "\"scale\":{\"type\":\"integer\",\"minimum\":1,\"maximum\":16,\"description\":\"Magnification of the preview. Default: fits about 768 pixels.\"}}}",
        tileset_check, true);

    add(kRulesCommand, "Write the Tilemap autotile rules file of a tileset layer (the recipe command that keeps it current).",
        "Writes the rules file of the tileset layer: {\"format\":\"factoria.terrains/1\",\"terrains\":[{name, mode, seed, tiles}]}, with the tile of every neighbour combination (variations as lists). "
        "image.tileset.build already does this; this command is what assets.json records as the recipe of the rules file, so assets.regenerate keeps it current when the document changes. "
        "Read by tilemap.set_terrains {id, path}. Refuses to replace a file that is not this layer's unless `overwrite`. Example: {\"path\":\"assets/art/ground.image.json\"}",
        "{\"type\":\"object\",\"required\":[\"path\"],\"properties\":{\"path\":{\"type\":\"string\",\"description\":\"" + pathDoc + "\"},"
        "\"layer\":{\"type\":\"string\",\"description\":\"The tileset layer. Default: the only one.\"},"
        "\"rules\":{\"type\":\"string\",\"description\":\"The rules file. Default: <document>.terrains.json.\"},"
        "\"overwrite\":{\"type\":\"boolean\",\"default\":false,\"description\":\"Replace a file that is not this layer's rules.\"}}}",
        tileset_rules, false);
}

}  // namespace fa::imgedit
