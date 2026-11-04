// The `uv` section of a model document: reading it (every problem with its JSON pointer and the fix) and its JSON schema.
#include <algorithm>
#include <cmath>
#include <format>

#include "fa/core/strings.h"
#include "fa/scene/model_doc.h"

namespace fa {

namespace {

const std::vector<std::string>& layout_names() {
    static const std::vector<std::string> v = {"atlas", "tile"};
    return v;
}
const std::vector<std::string>& seam_names() {
    static const std::vector<std::string> v = {"few", "balanced", "many"};
    return v;
}
const std::vector<std::string>& axis_names() {
    static const std::vector<std::string> v = {"x", "y", "z"};
    return v;
}
const std::vector<std::string>& top_keys() {
    static const std::vector<std::string> v = {"layout", "method", "axis", "texelsPerUnit", "textureSize", "padding", "seams", "rotate", "parts"};
    return v;
}
const std::vector<std::string>& part_keys() {
    static const std::vector<std::string> v = {"method", "axis", "texelsPerUnit"};
    return v;
}

std::string quoted(const std::vector<std::string>& v) {
    std::string out;
    for (std::size_t i = 0; i < v.size(); ++i) out += (i ? ", \"" : "\"") + v[i] + "\"";
    return out;
}

struct UvReader {
    std::vector<ModelIssue>& issues;
    void err(std::string pointer, std::string message, std::string hint) { issues.push_back({std::move(pointer), std::move(message), std::move(hint)}); }

    std::optional<std::string> choice(const Json& obj, const char* key, const std::string& at, const std::vector<std::string>& names, const char* hint) {
        auto it = obj.find(key);
        if (it == obj.end()) return std::nullopt;
        if (!it->is_string()) {
            err(at + "/" + key, std::string(key) + " must be one of " + quoted(names) + ", got " + describe_json_value(*it), hint);
            return std::nullopt;
        }
        const std::string s = it->get<std::string>();
        if (std::find(names.begin(), names.end(), s) == names.end()) {
            err(at + "/" + key, std::string(key) + " must be one of " + quoted(names) + ", got \"" + s + "\"", did_you_mean(s, names) + " " + hint);
            return std::nullopt;
        }
        return s;
    }
    std::optional<ModelUvMethod> method(const Json& obj, const std::string& at) {
        auto s = choice(obj, "method", at, model_uv_method_names(),
                        "unwrap cuts the surface into flat pieces; box, cylinder, sphere and planar project it.");
        if (!s) return std::nullopt;
        for (ModelUvMethod m : {ModelUvMethod::Unwrap, ModelUvMethod::Box, ModelUvMethod::Cylinder, ModelUvMethod::Sphere, ModelUvMethod::Planar})
            if (*s == model_uv_method_name(m)) return m;
        return std::nullopt;
    }
    std::optional<char> axis(const Json& obj, const std::string& at) {
        auto s = choice(obj, "axis", at, axis_names(), "The axis of a cylinder or sphere, or the direction a planar projection looks along; y is up.");
        return s ? std::optional<char>((*s)[0]) : std::nullopt;
    }
    std::optional<float> density(const Json& obj, const std::string& at) {
        auto it = obj.find("texelsPerUnit");
        if (it == obj.end()) return std::nullopt;
        if (!it->is_number() || it->get<double>() < 1 || it->get<double>() > 16384) {
            err(at + "/texelsPerUnit", "texelsPerUnit must be a number from 1 to 16384 (texels of texture per metre of surface), got " + describe_json_value(*it),
                "Leave it out to use the style guide's texelsPerUnit (128 when there is none).");
            return std::nullopt;
        }
        return float(it->get<double>());
    }
    void unknown_keys(const Json& obj, const std::string& at, const std::vector<std::string>& keys) {
        for (auto it = obj.begin(); it != obj.end(); ++it)
            if (std::find(keys.begin(), keys.end(), it.key()) == keys.end())
                err(at + "/" + it.key(), "\"" + it.key() + "\" is not a field of " + (at == "/uv" ? "uv" : "a uv part"), did_you_mean(it.key(), keys));
    }
};

}  // namespace

std::optional<ModelUvSettings> parse_model_uv(const Json& json, std::vector<ModelIssue>& issues) {
    UvReader r{issues};
    const std::size_t before = issues.size();
    if (!json.is_object()) {
        r.err("/uv", "uv must be an object like {\"layout\": \"atlas\", \"method\": \"unwrap\"}, got " + describe_json_value(json),
              "Leave it out for the primitives' own uvs. docs/MODELING.md, \"UVs\", lists the fields.");
        return std::nullopt;
    }
    ModelUvSettings s;
    r.unknown_keys(json, "/uv", top_keys());
    if (auto v = r.choice(json, "layout", "/uv", layout_names(), "\"atlas\" packs every piece into one texture; \"tile\" continues a repeating texture across the model.")) s.layout = *v;
    s.method = r.method(json, "/uv");
    if (auto a = r.axis(json, "/uv")) s.axis = *a;
    s.texelsPerUnit = r.density(json, "/uv");
    if (auto it = json.find("textureSize"); it != json.end()) {
        const bool ok = it->is_number_integer() && (it->get<long long>() == 0 || (it->get<long long>() >= kModelUvMinTextureSize && it->get<long long>() <= kModelUvMaxTextureSize));
        if (!ok)
            r.err("/uv/textureSize", std::format("textureSize must be 0 (the smallest power of two that fits) or an integer from {} to {}, got {}", kModelUvMinTextureSize, kModelUvMaxTextureSize, describe_json_value(*it)),
                  "Use a power of two: 512, 1024, 2048.");
        else s.textureSize = int(it->get<long long>());
    }
    if (auto it = json.find("padding"); it != json.end()) {
        if (!it->is_number_integer() || it->get<long long>() < 0 || it->get<long long>() > kModelUvMaxPadding)
            r.err("/uv/padding", std::format("padding must be an integer from 0 to {} (empty texels around each piece), got {}", kModelUvMaxPadding, describe_json_value(*it)), "2 to 4 is usual; more keeps mipmaps from bleeding.");
        else s.padding = int(it->get<long long>());
    }
    if (auto v = r.choice(json, "seams", "/uv", seam_names(), "\"few\" cuts the least (fewer, bigger pieces, shorter seams), \"many\" the most (more, smaller pieces).")) s.seams = *v;
    if (auto it = json.find("rotate"); it != json.end()) {
        if (!it->is_boolean()) r.err("/uv/rotate", "rotate must be true or false, got " + describe_json_value(*it), "true lets the packer turn pieces to fit more; false keeps every piece upright.");
        else s.rotate = it->get<bool>();
    }
    if (auto it = json.find("parts"); it != json.end()) {
        if (!it->is_object()) r.err("/uv/parts", "parts must be an object of part name to settings, got " + describe_json_value(*it), "Example: {\"wheel\": {\"method\": \"cylinder\"}}.");
        else
            for (auto p = it->begin(); p != it->end(); ++p) {
                const std::string at = "/uv/parts/" + p.key();
                if (!p->is_object()) {
                    r.err(at, "a part's uv settings must be an object like {\"method\": \"box\"}, got " + describe_json_value(*p), "Fields: method, axis, texelsPerUnit.");
                    continue;
                }
                r.unknown_keys(*p, at, part_keys());
                ModelUvPartSettings ps;
                ps.method = r.method(*p, at);
                ps.axis = r.axis(*p, at);
                ps.texelsPerUnit = r.density(*p, at);
                s.parts.emplace_back(p.key(), ps);
            }
    }
    // a tile layout cannot unwrap
    if (s.layout == "tile" && s.method && *s.method == ModelUvMethod::Unwrap)
        r.err("/uv/method", "a \"tile\" layout cannot use \"unwrap\": a texture that repeats across the model needs a projection",
              "Use \"box\" (the default for tile), \"cylinder\", \"sphere\" or \"planar\", or set layout to \"atlas\".");
    if (s.layout == "tile")
        for (const auto& [name, ps] : s.parts)
            if (ps.method && *ps.method == ModelUvMethod::Unwrap)
                r.err("/uv/parts/" + name + "/method", "a \"tile\" layout cannot use \"unwrap\" for a part", "Use a projection for this part, or set layout to \"atlas\".");
    if (issues.size() != before) return std::nullopt;
    return s;
}

Json model_uv_schema() {
    auto num = [](const char* type, const char* doc) { return Json::object({{"type", type}, {"description", doc}}); };
    auto methods = [](const char* doc) {
        Json e = Json::array();
        for (const std::string& m : model_uv_method_names()) e.push_back(m);
        return Json::object({{"type", "string"}, {"enum", e}, {"description", doc}});
    };
    auto axis = [](const char* doc) { return Json::object({{"type", "string"}, {"enum", Json::array({"x", "y", "z"})}, {"description", doc}}); };
    Json density = Json::object({{"type", "number"}, {"minimum", 1}, {"maximum", 16384},
                                 {"description", "Texels of texture per metre of surface. Left out: the project's style guide texelsPerUnit, else 128."}});
    Json part = Json::object(
        {{"type", "object"},
         {"additionalProperties", false},
         {"description", "What one part overrides; a field left out inherits the `uv` section's."},
         {"properties", Json::object({{"method", methods("How this part gets its uvs.")},
                                      {"axis", axis("cylinder, sphere: the axis of the shape; planar: the direction looked along.")},
                                      {"texelsPerUnit", density}})}});
    Json textureSize = Json::object({{"type", "integer"}, {"minimum", 0}, {"maximum", kModelUvMaxTextureSize},
                                     {"description", std::format("Side in texels of the square texture the uvs are made for. 0 (default): the smallest power of two the pieces fit in at the density, at most {}. "
                                                                 "A fixed size the pieces do not fit lowers the density (a warning says so).", kModelUvMaxTextureSize)}});
    return Json::object(
        {{"type", "object"},
         {"additionalProperties", false},
         {"description", "UV coordinates for the whole model: automatic unwrapping or box / cylinder / sphere / planar projections per part, packing of the pieces into one texture at the style's texel density. "
                         "Without it every primitive keeps its own uvs. docs/MODELING.md, \"UVs\"; `model.uv` edits and measures it."},
         {"properties",
          Json::object({{"layout", Json::object({{"type", "string"}, {"enum", Json::array({"atlas", "tile"})}, {"default", "atlas"},
                                                 {"description", "\"atlas\": every piece packed into one texture painted for this model. \"tile\": world-scale uvs (texels per metre / textureSize) that continue across the model and repeat; needs a projection."}})},
                        {"method", methods("How the parts get their uvs. Default \"unwrap\" for an atlas (xatlas cuts the surface into pieces and flattens each), \"box\" for tile.")},
                        {"axis", axis("cylinder, sphere: the axis of the shape; planar: the direction looked along. Default y.")},
                        {"texelsPerUnit", density},
                        {"textureSize", textureSize},
                        {"padding", Json::object({{"type", "integer"}, {"minimum", 0}, {"maximum", kModelUvMaxPadding}, {"default", 2}, {"description", "Empty texels around each piece (atlas)."}})},
                        {"seams", Json::object({{"type", "string"}, {"enum", Json::array({"few", "balanced", "many"})}, {"default", "balanced"},
                                                {"description", "unwrap: how freely the surface is cut. \"few\": fewer, bigger pieces and shorter seams; \"many\": more, smaller pieces."}})},
                        {"rotate", num("boolean", "atlas: let the packer turn pieces to fit more. Default true when every part is unwrapped, false when a part is projected (so projected pieces stay upright).")},
                        {"parts", Json::object({{"type", "object"}, {"additionalProperties", part}, {"description", "By part name (\"\" for the nodes that name no part): the method, axis and density of that part."}})}})}});
}

}  // namespace fa
