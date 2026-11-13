#include "assets_animate_prefab.h"

#include <algorithm>
#include <cctype>
#include <cmath>

#include "assets_internal.h"
#include "fa/core/fs.h"
#include "fa/core/strings.h"

namespace fa::assets_detail {

namespace {

const std::vector<std::string>& layer_keys() {
    static const std::vector<std::string> names = {"back", "front", "light"};
    return names;
}

// "prefabs/coin_sparkle.prefab.json" -> "Coin Sparkle".
std::string title_of(const std::string& rel) {
    std::string stem = fs::stem(rel);  // "coin_sparkle.prefab"
    if (ends_with(to_lower(stem), ".prefab")) stem.resize(stem.size() - 7);
    std::string out;
    bool start = true;
    for (char c : stem) {
        if (c == '_' || c == '-' || c == ' ' || c == '.') {
            if (!out.empty() && out.back() != ' ') out += ' ';
            start = true;
            continue;
        }
        out += start ? char(std::toupper(static_cast<unsigned char>(c))) : c;
        start = false;
    }
    while (!out.empty() && out.back() == ' ') out.pop_back();
    return out.empty() ? std::string("Effect") : out;
}

// 72 rather than 72.0 for a whole number: the file reads like one written by hand.
Json number_json(double v) {
    return std::floor(v) == v && std::abs(v) < 1e9 ? Json(static_cast<long long>(v)) : Json(v);
}

const char* kPrefabHint =
    "Example: \"prefab\": \"prefabs/coin_sparkle.prefab.json\", or an object "
    "{\"path\":\"prefabs/"
    "coin_sparkle.prefab.json\",\"size\":[72,72],\"layers\":{\"back\":2,\"front\":20,\"light\":21},\"tags\":[\"fx\"]}.";

}  // namespace

AnimatePrefabSpec parse_animate_prefab(const char* command, const Json& prefab,
                                       const std::vector<std::string>& bakedLayers, int frameW, int frameH,
                                       std::vector<std::string>& warnings) {
    AnimatePrefabSpec spec;
    spec.width = frameW;
    spec.height = frameH;
    Json obj;
    if (prefab.is_string())
        obj = Json::object({{"path", prefab}});
    else if (prefab.is_object())
        obj = prefab;
    else
        arg_error(command, "/prefab",
                  "expected the path of the prefab to write, or an object {path, name, tags, size, layers, pixelArt, "
                  "overwrite}, got " +
                      describe_json_value(prefab) + ".",
                  kPrefabHint);
    check_arg_keys(command, obj, "/prefab", {"path", "name", "tags", "size", "layers", "pixelArt", "overwrite"});

    if (bakedLayers.empty() || bakedLayers.front().empty())
        arg_error(command, "/prefab", "a prefab plays the layers of an effect, and this call bakes none.",
                  "Add \"layers\": [\"back\", \"front\", \"light\"] (a module that reads `layer` draws each), or place "
                  "the single sheet yourself with a Sprite and a SpriteAnimator {\"clip\": ...}.");

    if (!obj.contains("path") || !obj["path"].is_string())
        arg_error(command, "/prefab/path", "required: where to write the prefab, a string.", kPrefabHint);
    auto norm = fs::normalize_checked(obj["path"].get<std::string>());
    if (!norm.ok() || norm->empty())
        arg_error(command, "/prefab/path", "'" + obj["path"].get<std::string>() + "' is not a project path.",
                  "Use a project-relative path such as \"prefabs/coin_sparkle.prefab.json\".");
    if (!ends_with(to_lower(*norm), ".prefab.json"))
        arg_error(command, "/prefab/path", "'" + *norm + "' does not end in .prefab.json.",
                  "Name it like a prefab: \"prefabs/" + fs::stem(*norm) + ".prefab.json\".");
    spec.rel = *norm;

    spec.name = title_of(spec.rel);
    if (obj.contains("name") && !obj["name"].is_null()) {
        if (!obj["name"].is_string() || obj["name"].get<std::string>().empty())
            arg_error(command, "/prefab/name", "expected a non-empty string.",
                      "The name of the parent entity: \"Coin Sparkle\" (the default is made from the file name).");
        spec.name = obj["name"].get<std::string>();
    }
    if (obj.contains("tags") && !obj["tags"].is_null()) {
        const Json& tags = obj["tags"];
        if (!tags.is_array())
            arg_error(command, "/prefab/tags", "expected an array of strings.", "Example: \"tags\": [\"fx\"]");
        for (std::size_t i = 0; i < tags.size(); ++i) {
            if (!tags[i].is_string() || tags[i].get<std::string>().empty())
                arg_error(command, "/prefab/tags/" + std::to_string(i), "expected a non-empty string.",
                          "Example: \"tags\": [\"fx\"]");
            spec.tags.push_back(tags[i].get<std::string>());
        }
    }
    if (obj.contains("size") && !obj["size"].is_null()) {
        const Json& s = obj["size"];
        if (!s.is_array() || s.size() != 2 || !s[0].is_number() || !s[1].is_number() || !(s[0].get<double>() > 0) ||
            !(s[1].get<double>() > 0))
            arg_error(command, "/prefab/size", "expected [width, height], two numbers above 0 (world units).",
                      "How big the effect shows in the game, e.g. [72, 72]. The default is the size of one frame in "
                      "pixels, [" +
                          std::to_string(frameW) + ", " + std::to_string(frameH) + "].");
        spec.width = s[0].get<double>();
        spec.height = s[1].get<double>();
    }
    if (obj.contains("layers") && !obj["layers"].is_null()) {
        const Json& l = obj["layers"];
        if (!l.is_object())
            arg_error(command, "/prefab/layers", "expected an object {back, front, light} of Sprite.layer numbers.",
                      "Example: \"layers\": {\"back\": 2, \"front\": 20, \"light\": 21}");
        for (auto it = l.begin(); it != l.end(); ++it) {
            const std::string ptr = "/prefab/layers/" + it.key();
            if (std::find(layer_keys().begin(), layer_keys().end(), it.key()) == layer_keys().end())
                arg_error(command, ptr, "unknown layer '" + it.key() + "'.",
                          did_you_mean(it.key(), layer_keys()) + " Layers: " + join(layer_keys(), ", ") + ".");
            if (!it->is_number_integer() || it->get<long long>() < -10000 || it->get<long long>() > 10000)
                arg_error(command, ptr,
                          "expected a whole number from -10000 to 10000 (a Sprite.layer: higher draws on top).",
                          "Put back below the character's layer, front above it, light above that: {\"back\": 2, "
                          "\"front\": 20, \"light\": 21}.");
            if (std::find(bakedLayers.begin(), bakedLayers.end(), it.key()) == bakedLayers.end())
                arg_error(command, ptr,
                          "this call does not bake the layer '" + it.key() + "' (its `layers` are " +
                              join(bakedLayers, ", ") + ").",
                          "Remove it, or add it to `layers`.");
            const int value = int(it->get<long long>());
            if (it.key() == "back")
                spec.layerBack = value;
            else if (it.key() == "front")
                spec.layerFront = value;
            else
                spec.layerLight = value;
        }
    }
    const auto baked = [&](const char* name) {
        return std::find(bakedLayers.begin(), bakedLayers.end(), name) != bakedLayers.end();
    };
    if (baked("back") && baked("front") && spec.layerBack >= spec.layerFront)
        warnings.push_back("prefab: the layer of `back` (" + std::to_string(spec.layerBack) +
                           ") is not below the one of `front` (" + std::to_string(spec.layerFront) +
                           "), so the back sheet is not drawn behind the character. Give back a lower Sprite.layer "
                           "than the character's and front a higher one.");
    if (obj.contains("pixelArt") && !obj["pixelArt"].is_null()) {
        if (!obj["pixelArt"].is_boolean())
            arg_error(command, "/prefab/pixelArt", "expected true or false.",
                      "true samples the sheet with nearest-neighbour filtering (pixel art); the default false filters "
                      "smoothly.");
        spec.pixelArt = obj["pixelArt"].get<bool>();
    }
    if (obj.contains("overwrite") && !obj["overwrite"].is_null()) {
        if (!obj["overwrite"].is_boolean())
            arg_error(command, "/prefab/overwrite", "expected true or false.",
                      "true replaces a prefab that already exists (and the changes made to it by hand).");
        spec.overwrite = obj["overwrite"].get<bool>();
    }
    return spec;
}

Json build_animate_prefab(const AnimatePrefabSpec& spec, const std::vector<std::string>& bakedLayers,
                          const std::vector<std::string>& sheets, const std::string& clip) {
    Json children = Json::array();
    for (std::size_t i = 0; i < bakedLayers.size(); ++i) {
        const std::string& layer = bakedLayers[i];
        const int order = layer == "back" ? spec.layerBack : layer == "front" ? spec.layerFront : spec.layerLight;
        std::string name = layer;
        if (!name.empty()) name[0] = char(std::toupper(static_cast<unsigned char>(name[0])));
        Json sprite = Json::object({{"texture", sheets[i]},
                                    {"size", Json::array({number_json(spec.width), number_json(spec.height)})},
                                    {"layer", order},
                                    {"pixelArt", spec.pixelArt}});
        if (layer == "light") sprite["blend"] = "additive";
        children.push_back(Json::object(
            {{"name", name},
             {"components", Json::object({{"Transform", Json::object({{"position", Json::array({0, 0, 0})}})},
                                          {"Sprite", sprite},
                                          {"SpriteAnimator", Json::object({{"clip", clip}})}})}}));
    }
    Json entity = Json::object({{"name", spec.name}});
    if (!spec.tags.empty()) entity["tags"] = Json(spec.tags);
    entity["components"] = Json::object({{"Transform", Json::object({{"position", Json::array({0, 0, 0})}})}});
    entity["children"] = children;
    return Json::object({{"format", "factoria.prefab/1"}, {"entity", entity}});
}

}  // namespace fa::assets_detail
