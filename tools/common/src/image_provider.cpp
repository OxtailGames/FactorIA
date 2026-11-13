// The document side of the pictures an image provider makes: image_edit_input (what to send) and image.layer.add_provider (what to do
// with the answer). The provider call is in fa_ai. Docs: docs/IMAGES.md, "Pictures from a provider".
#include "fa/tooling/image_provider.h"

#include <algorithm>
#include <format>

#include "fa/core/strings.h"
#include "image_edit.h"
#include "image_frames.h"
#include "image_indexed.h"
#include "util.h"

namespace fa {

namespace imgedit {
namespace {

using assets_detail::arg_error;
using assets_detail::check_arg_keys;
using tooling_detail::arg_bool;
using tooling_detail::arg_string;

int int_member(const Json& a, const char* command, const char* key, int lo, int hi, int def) {
    auto it = a.find(key);
    if (it == a.end() || it->is_null()) return def;
    if (!it->is_number_integer() || it->get<long long>() < lo || it->get<long long>() > hi)
        arg_error(command, std::string("/") + key,
                  std::string("`") + key + "` must be a whole number from " + std::to_string(lo) + " to " +
                      std::to_string(hi) + ", got " + describe_json_value(*it) + ".",
                  "");
    return int(it->get<long long>());
}

// The stored selection `a.selection` names, or the one an inline description makes (stored under selectionName).
std::string selection_name_of(const std::string& projectDir, const Json& a, const std::string& rel, const char* command,
                              std::string& made) {
    const Json& s = a["selection"];
    if (s.is_string()) return s.get<std::string>();
    if (!s.is_object())
        arg_error(command, "/selection",
                  "expected the name of a stored selection or an object that describes one, got " +
                      describe_json_value(s) + ".",
                  "Example: \"selection\":\"sky\", or "
                  "\"selection\":{\"by\":\"rect\",\"x\":10,\"y\":10,\"width\":32,\"height\":32}. Make a stored one "
                  "with image.select.");
    const std::string name = arg_string(a, "selectionName", false, "inpaint");
    if (!valid_selection_name(name) || name == "all")
        arg_error(command, "/selectionName", "'" + name + "' is not a usable selection name.",
                  "Use 1 to 40 letters, digits, '-' or '_' (\"all\" is reserved).");
    Json sel = s;
    sel["path"] = rel;
    sel["name"] = name;
    if (a.contains("frame") && !sel.contains("frame")) sel["frame"] = a["frame"];
    try {
        image_select(projectDir, sel);
    } catch (const CommandError& e) {
        arg_error(command, "/selection", std::string("the inline selection cannot be made: ") + e.what(),
                  "Fields are those of image.select: `by` (rect, ellipse, polygon, color, alpha, layer, all) with its "
                  "geometry.");
    }
    made = name;
    return name;
}

}  // namespace
}  // namespace imgedit

ImageEditInput image_edit_input(const std::string& projectDir, const Json& a, bool needSelection, bool needPicture,
                                const char* command) {
    using namespace imgedit;
    ImageEditInput in;
    DocFile d = open_doc(projectDir, arg_string(a, "path", true), command);
    in.doc = d.rel;
    in.width = d.json.value("width", 0);
    in.height = d.json.value("height", 0);
    FrameScope frameScope(projectDir, d.rel, d.json, a, command);
    in.frame = frameScope.frame();
    in.animated = frameScope.frames() > 1;

    const bool hasSel = a.contains("selection") && !a["selection"].is_null();
    if (!hasSel && needSelection) {
        const auto names = list_selections(projectDir, d.rel);
        arg_error(command, "/selection", "`selection` is required: the part of the picture to repaint.",
                  "Give the name of a stored selection (" +
                      (names.empty() ? std::string("none stored yet: make one with image.select") : join(names, ", ")) +
                      "), \"all\" for the whole canvas, or an object such as "
                      "{\"by\":\"rect\",\"x\":10,\"y\":10,\"width\":32,\"height\":32}.");
    }
    if (hasSel) {
        std::string made;
        in.selection = selection_name_of(projectDir, a, d.rel, command, made);
        const Mask m = load_selection(projectDir, d.rel, in.selection, in.width, in.height, command);
        in.mask = m.v;
        in.selectedPixels = m.count(128);
        if (in.selectedPixels == 0 && needSelection)
            arg_error(command, "/selection",
                      "the selection '" + in.selection + "' covers no pixel, so there is nothing to repaint.",
                      "Select something with image.select (by rect, ellipse, color, layer...) and try again.");
        if (!made.empty())
            in.warnings.push_back("The inline selection was stored as '" + made +
                                  "' (image.select shows or clears it).");
    }
    // a palette: the document's own, or the style's when it says "style"
    {
        const PixelPalette pal = indexed::load_doc_palette(projectDir, d.rel, d.json, false, command);
        if (!pal.empty()) {
            in.palette = true;
            for (const auto& e : pal.entries) in.colours.push_back(e.rgb);
        }
    }
    if (a.contains("layer") && !a["layer"].is_null()) {
        LayerRef ref = find_layer(d.json, a["layer"], command);
        in.layer = ref.layer->value("name", ref.indexPath);
        if (needPicture)
            in.picture = render_layer_alone(projectDir, *ref.layer, in.width, in.height, ref.parentX, ref.parentY,
                                            &in.warnings, &d.json);
    } else if (needPicture) {
        if (auto img = render_document_json(projectDir, d.json))
            in.picture = std::move(*img);
        else
            arg_error(command, "/path", "the document does not render.",
                      "Fix it first: image.info lists its problems.");
    }
    if (needPicture && (in.picture.width != in.width || in.picture.height != in.height) && !in.picture.empty())
        in.picture = resize_image(in.picture, in.width, in.height);
    return in;
}

std::string image_provider_source_path(const std::string& projectDir, const std::string& doc,
                                       const std::string& layerName) {
    Json d = Json::object({{"layers", Json::array()}});
    if (auto p = imgedit::open_doc(projectDir, doc, "image.layer.add_provider"); p.json.is_object()) d = p.json;
    return imgedit::layer_png_path(projectDir, doc, layerName, d);
}

std::string image_unique_layer_name(const std::string& projectDir, const std::string& doc, const std::string& base) {
    auto p = imgedit::open_doc(projectDir, doc, "image.layer.add_provider");
    return imgedit::unique_layer_name(p.json, base);
}

Json image_layer_add_provider(const std::string& projectDir, const Json& a) {
    using namespace imgedit;
    const char* cmd = "image.layer.add_provider";
    check_arg_keys(
        cmd, a, "",
        {"path", "source", "name", "provenance", "selection", "x", "y", "parent", "index", "opacity", "blend", "bake"});
    DocFile d = open_doc(projectDir, arg_string(a, "path", true), cmd);
    const std::string source = arg_string(a, "source", true);
    if (!ends_with(source, ".png"))
        arg_error(cmd, "/source", "'" + source + "' is not a PNG.",
                  "`source` is a PNG of the project that the provider made, e.g. 'assets/art/hero.layers/sky.png'.");
    auto png = read_png_file(projectDir, source);
    if (!png)
        arg_error(cmd, "/source", "'" + source + "' cannot be read as a PNG.",
                  "Write the provider's picture there first (image.inpaint and image.generate_layer do).");
    Json prov = a.contains("provenance") ? a["provenance"] : Json::object();
    if (!prov.is_object())
        arg_error(
            cmd, "/provenance", "expected an object, got " + describe_json_value(prov) + ".",
            "Example: {\"provider\":\"openai\",\"model\":\"gpt-image-1\",\"prompt\":\"a brass key\",\"seed\":7}.");
    if (!prov.contains("provider") || !prov["provider"].is_string() || prov["provider"].get<std::string>().empty())
        arg_error(cmd, "/provenance/provider",
                  "the provenance needs `provider`, the name of the provider that made the picture.",
                  "Example: {\"provider\":\"openai\",\"prompt\":\"a brass key\"}.");
    const std::optional<Image> before = render_document_json(projectDir, d.json);

    std::string name = arg_string(a, "name", false);
    if (name.empty())
        name = unique_layer_name(d.json, "provider");
    else if (const auto names = layer_names(d.json); std::find(names.begin(), names.end(), name) != names.end())
        arg_error(cmd, "/name", "a layer named '" + name + "' exists already.",
                  "Layer names address layers, so they are distinct: " + describe_layers(d.json, 12));
    const int x = int_member(a, cmd, "x", -100000, 100000, 0), y = int_member(a, cmd, "y", -100000, 100000, 0);
    Json layer = Json::object({{"kind", "provider"}, {"name", name}});
    if (x) layer["x"] = x;
    if (y) layer["y"] = y;
    if (a.contains("opacity") && a["opacity"].is_number()) layer["opacity"] = a["opacity"];
    if (a.contains("blend") && a["blend"].is_string()) layer["blend"] = a["blend"];
    layer["source"] = source;
    if (a.contains("selection") && a["selection"].is_string()) {
        const std::string sel = a["selection"].get<std::string>();
        const Mask m = load_selection(projectDir, d.rel, sel, d.json.value("width", 0), d.json.value("height", 0), cmd);
        Image grey;
        grey.width = m.w;
        grey.height = m.h;
        grey.rgba.resize(std::size_t(m.w) * m.h * 4);
        for (std::size_t i = 0; i < m.v.size(); ++i) {
            grey.rgba[i * 4] = grey.rgba[i * 4 + 1] = grey.rgba[i * 4 + 2] = m.v[i];
            grey.rgba[i * 4 + 3] = 255;
        }
        const std::string maskPng = layer_png_path(projectDir, d.rel, name + " mask", d.json);
        write_layer_png(projectDir, maskPng, d.rel, grey, cmd, false);
        // the mask is in the layer's own pixels: the selection is in canvas pixels, so it sits at minus the layer's place
        layer["masks"] = Json::array({Json::object({{"type", "pixels"}, {"source", maskPng}, {"x", -x}, {"y", -y}})});
    }
    layer["provenance"] = prov;

    LayerRef parentRef;
    Json* list = &d.json["layers"];
    std::vector<int> path;
    if (a.contains("parent") && !a["parent"].is_null() &&
        !(a["parent"].is_string() && a["parent"].get<std::string>().empty())) {
        parentRef = find_layer(d.json, a["parent"], cmd, "parent");
        if (parentRef.layer->value("kind", std::string()) != "group")
            arg_error(cmd, "/parent", "'" + parentRef.layer->value("name", parentRef.indexPath) + "' is not a group.",
                      describe_layers(d.json, 12));
        list = &(*parentRef.layer)["layers"];
        path = parentRef.path;
    }
    const int n = int(list->size());
    const int index = int_member(a, cmd, "index", 0, n, n);
    list->insert(list->begin() + index, layer);
    path.push_back(index);
    LayerRef added = find_layer(d.json, index_path_string(path), cmd);
    Json extra = Json::object(
        {{"layer",
          Json::object(
              {{"index", added.indexPath}, {"pointer", added.pointer}, {"name", name}, {"kind", "provider"}})}});
    return commit_document(projectDir, d.rel, d.json, before, arg_bool(a, "bake", true), extra, {}, cmd);
}

namespace imgedit {

void register_provider_commands(CommandRegistry& registry, const std::string& projectDir) {
    CommandInfo info;
    info.name = "image.layer.add_provider";
    info.category = "assets";
    info.readOnly = false;
    info.summary = "Add a PNG an image provider made to an image document as a `provider` layer, with its provenance "
                   "and an optional mask from a stored selection.";
    info.description =
        "The second half of image.inpaint and image.generate_layer, and the way to put any provider picture into a "
        "document: `source` is a PNG of the project "
        "(already written, with its provenance in assets.json), `provenance` the record the layer carries (provider, "
        "model, prompt, seed, references, license, author, notes). "
        "`selection` (a stored selection, or \"all\") becomes a `pixels` mask of the layer, copied next to the PNG so "
        "later changes of the selection do not move it; the "
        "selection's feather is part of its coverage. The layer goes on top (or at `index` / inside the group "
        "`parent`) at (`x`, `y`). It never calls a provider. "
        "The document is checked completely and baked; the picture is AI-made from then on (docs.read IMAGES, "
        "\"Baking\"). "
        "Example: "
        "{\"path\":\"assets/art/hero.image.json\",\"source\":\"assets/art/hero.layers/"
        "sky.png\",\"selection\":\"sky\",\"provenance\":{\"provider\":\"openai\",\"prompt\":\"a stormy sky\"}}";
    info.inputSchema = Json::parse(R"({"type":"object","required":["path","source","provenance"],"properties":{
      "path":{"type":"string","description":"The image document, project-relative, ending in .image.json."},
      "source":{"type":"string","description":"The PNG the provider made, project-relative."},
      "provenance":{"type":"object","description":"How it was made: provider (required), model, prompt, seed, references, license, author, notes."},
      "name":{"type":"string","description":"Layer name (distinct). Default: provider, provider 2, ..."},
      "selection":{"type":"string","description":"A stored selection (image.select) or \"all\": the layer shows only there."},
      "x":{"type":"integer","description":"Canvas column of the layer's left edge (default 0)."},
      "y":{"type":"integer","description":"Canvas row of the layer's top edge (default 0)."},
      "opacity":{"type":"number","minimum":0,"maximum":1,"description":"Layer opacity (default 1)."},
      "blend":{"type":"string","description":"Blend mode (default normal)."},
      "parent":{"description":"Group to put it in (name or index path). Default: the top level."},
      "index":{"type":"integer","minimum":0,"description":"Position in the list, 0 = the bottom. Default: the top."},
      "bake":{"type":"boolean","default":true,"description":"Also draw the PNG (default true). False only writes the document."}}})");
    info.inputSchema["properties"]["source"]["x-fa-path"] = "read";
    add_image_command(registry, info,
                      [projectDir](const Json& args) { return image_layer_add_provider(projectDir, args); });
}

}  // namespace imgedit

}  // namespace fa
