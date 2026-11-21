// image.normal.generate: a tangent-space normal map as a new, hidden pixels layer of an image document (docs/images/IMAGES_EFFECTS_COMMANDS.md, "Normal maps").
// The layer is a plain PNG, so image.paint (with `normal`), image.edit and the normal* operations edit it like any other picture, and
// image.export writes it as the PNG a Sprite.normalMap points at. The maths is fa/tooling/image_normal.h, on the engine's kernel.
#include <algorithm>
#include <cmath>

#include "fa/core/strings.h"
#include "fa/tooling/image_normal.h"
#include "image_edit.h"
#include "util.h"

namespace fa::imgedit {

using assets_detail::arg_error;
using assets_detail::check_arg_keys;
using tooling_detail::arg_bool;
using tooling_detail::arg_string;

namespace {

constexpr const char* kCmd = "image.normal.generate";

Json image_normal_generate(const std::string& projectDir, const Json& a) {
    check_arg_keys(kCmd, a, "", {"path", "layer", "from", "strength", "tile", "name", "bake"});
    std::string from = "sprite";
    if (a.contains("from") && !a["from"].is_null()) {
        const std::vector<std::string> kinds = {"sprite", "height"};
        if (!a["from"].is_string() ||
            std::find(kinds.begin(), kinds.end(), a["from"].get<std::string>()) == kinds.end())
            arg_error(kCmd, "/from",
                      "`from` must be \"sprite\" or \"height\", got " + describe_json_value(a["from"]) + ". " +
                          (a["from"].is_string() ? did_you_mean(a["from"].get<std::string>(), kinds) : std::string()),
                      "\"sprite\" makes a bevel from the picture's own outline and brightness (Sprite.normalFrom = sprite); "
                      "\"height\" reads a grey picture as a height map, white = high (Sprite.normalFrom = height).");
        from = a["from"].get<std::string>();
    }
    double strength = 1;
    if (a.contains("strength") && !a["strength"].is_null()) {
        if (!a["strength"].is_number() || !(a["strength"].get<double>() >= 0.0) || a["strength"].get<double>() > 32.0)
            arg_error(kCmd, "/strength", "`strength` must be a number from 0 to 32, got " + describe_json_value(a["strength"]) + ".",
                      "0 is flat, 1 the default relief (the Sprite.normalStrength default), 4 a deep one.");
        strength = a["strength"].get<double>();
    }
    const bool tile = arg_bool(a, "tile", false);
    std::string name = "normal";
    if (a.contains("name") && !a["name"].is_null()) {
        if (!a["name"].is_string() || a["name"].get<std::string>().empty() || a["name"].get<std::string>().size() > 80)
            arg_error(kCmd, "/name", "`name` must be a text of 1 to 80 characters, got " + describe_json_value(a["name"]) + ".",
                      "It names the new layer; the default is \"normal\".");
        name = a["name"].get<std::string>();
    }

    DocFile d = open_doc(projectDir, arg_string(a, "path", true), kCmd);
    const int W = d.json.value("width", 0), H = d.json.value("height", 0);
    LayerRef ref;
    const bool haveLayer = a.contains("layer") && !a["layer"].is_null();
    if (haveLayer) {
        ref = find_layer(d.json, a["layer"], kCmd);
        if (ref.layer->value("kind", std::string()) == "adjustment")
            arg_error(kCmd, "/layer", "an adjustment layer has no pixels of its own to make a normal map from.",
                      "Name a layer below it, or leave `layer` out to use the whole picture.");
    }
    const std::optional<Image> before = render_document_json(projectDir, d.json);
    assets_detail::require_usable_manifest(projectDir);
    std::vector<std::string> warnings;

    // The source: the layer alone (masks, adjustments and effects applied) or the picture as it is now, on the canvas.
    Image source;
    if (haveLayer) {
        source = render_layer_alone(projectDir, *ref.layer, W, H, ref.parentX, ref.parentY, &warnings, &d.json);
    } else if (before) {
        source = *before;
    }
    if (source.empty() || source.width != W || source.height != H)
        fail("invalid_argument", "the picture of the document could not be drawn, so there is nothing to make a normal map from.",
             "Run image.bake on it to see the error, then fix the document.");
    bool any = false;
    for (std::size_t i = 3; i < source.rgba.size() && !any; i += 4) any = source.rgba[i] != 0;
    if (!any && from == "sprite")
        warnings.push_back("The source is fully transparent, so the normal map is flat: draw the sprite first, or pass \"from\":\"height\".");

    Image map = make_normal_map(source, from, strength, tile);
    if (map.empty()) fail("internal", "the normal map could not be made.", "Report this with the document.");

    const std::string layerName = unique_layer_name(d.json, name);
    const std::string idx = add_pixels_layer(projectDir, d.rel, d.json, haveLayer ? &ref : nullptr, layerName, map, 0, 0, kCmd);
    LayerRef made = find_layer(d.json, Json(idx), kCmd);
    // A normal map is data, not colour: shown in the picture it would cover the sprite, so the layer starts hidden.
    (*made.layer)["visible"] = false;
    const std::string png = made.layer->value("source", std::string());

    Json info = Json::object({{"layer", layerName}, {"index", idx}, {"png", png}, {"from", from}, {"strength", std::round(strength * 1000.0) / 1000.0}, {"tile", tile}});
    info["use"] = "image.export {path, layer: \"" + layerName + "\", out: \"assets/art/<name>-n.png\"}, then set Sprite.normalMap to that PNG; "
                  "or keep editing it with image.paint {layer, strokes:[{normal:{azimuth,tilt}}]} and the normalSmooth / normalFlip / normalStrength / normalize operations.";
    Json extra = Json::object({{"normalMap", info}});
    return commit_document(projectDir, d.rel, d.json, before, arg_bool(a, "bake", true), extra, warnings, kCmd);
}

}  // namespace

void register_normal_command(CommandRegistry& registry, const std::string& projectDir) {
    CommandInfo info;
    info.name = kCmd;
    info.category = "assets";
    info.readOnly = false;
    info.summary = "Make a tangent-space normal map from a layer or the whole picture as a new hidden pixels layer, ready to paint, smooth, "
                   "flip and export.";
    info.description =
        "Adds a pixels layer (hidden: a normal map is data, shown it would cover the sprite) the size of the canvas that holds a normal "
        "map of `layer` (by name or index path; without it, of the picture as it is now). `from` \"sprite\" (default) bevels the "
        "outline and the brightness of the picture, as Sprite.normalFrom = sprite does at run time; \"height\" reads the picture as a grey "
        "height map, white = high, as normalFrom = height. `strength` 0..32 (default 1) is the relief, Sprite.normalStrength; `tile` wraps "
        "the border for a seamless texture (the renderer clamps it, so leave it off for a sprite). With the same picture and strength the "
        "bytes are the ones the renderer makes. The layer is an ordinary PNG layer: image.paint with a `normal` {azimuth, tilt} stroke "
        "paints slopes, the normalSmooth, normalFlip, normalStrength and normalize operations (added to the layer, or to an adjustment "
        "layer above it) keep it a valid map, image.export with `layer` writes the PNG a Sprite.normalMap uses. Red = +X right, green = +Y UP the "
        "picture, blue = +Z towards the viewer; flat = (128,128,255). One undo step. Example: "
        "{\"path\":\"assets/art/hero.image.json\",\"layer\":\"hero\",\"strength\":2}";
    info.inputSchema = Json::parse(R"({"type":"object","required":["path"],"properties":{
      "path":{"type":"string","description":"The image document, project-relative, ending in .image.json."},
      "layer":{"description":"The layer to make the normal map from, by name or index path (\"1/0\"). Its masks, adjustments and effects count. Default: the whole picture as it is now (hidden layers do not count)."},
      "from":{"type":"string","enum":["sprite","height"],"default":"sprite","description":"sprite: a bevel from the distance to the transparent edge plus brightness times alpha (Sprite.normalFrom = sprite). height: the picture is a grey height map, white = high, alpha ignored (Sprite.normalFrom = height)."},
      "strength":{"type":"number","minimum":0,"maximum":32,"default":1,"description":"Relief: 0 is flat, 1 the default, larger is steeper (Sprite.normalStrength)."},
      "tile":{"type":"boolean","default":false,"description":"Wrap the border so a tiling texture has no seam. Off matches the renderer, which clamps the border."},
      "name":{"type":"string","default":"normal","description":"Name of the new layer; a number is added when the name is taken."},
      "bake":{"type":"boolean","default":true,"description":"Also draw the PNG (default true). The picture does not change: the new layer is hidden."}}})");
    add_image_command(registry, info, [projectDir](const Json& args) { return image_normal_generate(projectDir, args); });
}

}  // namespace fa::imgedit
