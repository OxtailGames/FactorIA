// The `texturing` and `vertexColors` sections of a model document and the texturing fields of a material: reading them (every problem with
// its JSON pointer and the fix), writing them back with their defaults, and their JSON schemas.
#include <algorithm>
#include <cmath>
#include <format>

#include "fa/core/strings.h"
#include "fa/scene/model_select.h"
#include "fa/scene/model_texture.h"

namespace fa {

namespace {

std::string quoted(const std::vector<std::string>& v) {
    std::string out;
    for (std::size_t i = 0; i < v.size(); ++i) out += (i ? ", \"" : "\"") + v[i] + "\"";
    return out;
}

std::string hex_color(Vec4 c) {
    auto byte = [](float v) { return int(std::lround(std::clamp(v, 0.0f, 1.0f) * 255.0f)); };
    std::string s = std::format("#{:02x}{:02x}{:02x}", byte(c.x), byte(c.y), byte(c.z));
    if (byte(c.w) != 255) s += std::format("{:02x}", byte(c.w));
    return s;
}

// A float as the number a person wrote (0.1, not 0.10000000149011612).
Json jf(float v) { return Json(std::round(double(v) * 1e6) / 1e6); }
Json vec_json(Vec3 v) { return Json::array({jf(v.x), jf(v.y), jf(v.z)}); }

struct Reader {
    std::vector<ModelIssue>& issues;
    void err(std::string pointer, std::string message, std::string hint) {
        issues.push_back({std::move(pointer), std::move(message), std::move(hint)});
    }

    void unknown_keys(const Json& obj, const std::string& at, const std::vector<std::string>& keys,
                      const std::string& what) {
        for (auto it = obj.begin(); it != obj.end(); ++it)
            if (std::find(keys.begin(), keys.end(), it.key()) == keys.end())
                err(at + "/" + it.key(), "\"" + it.key() + "\" is not a field of " + what,
                    did_you_mean(it.key(), keys));
    }
    // A number in [lo, hi] under `key`; false when the key is absent or wrong (wrong adds an issue).
    bool number(const Json& obj, const char* key, const std::string& at, double lo, double hi, float& out,
                const char* hint) {
        auto it = obj.find(key);
        if (it == obj.end()) return false;
        if (!it->is_number() || !std::isfinite(it->get<double>()) || it->get<double>() < lo || it->get<double>() > hi) {
            err(at + "/" + key,
                std::format("{} must be a number from {} to {}, got {}", key, lo, hi, describe_json_value(*it)), hint);
            return false;
        }
        out = float(it->get<double>());
        return true;
    }
    bool integer(const Json& obj, const char* key, const std::string& at, long long lo, long long hi, int& out,
                 const char* hint) {
        auto it = obj.find(key);
        if (it == obj.end()) return false;
        if (!it->is_number_integer() || it->get<long long>() < lo || it->get<long long>() > hi) {
            err(at + "/" + key,
                std::format("{} must be an integer from {} to {}, got {}", key, lo, hi, describe_json_value(*it)),
                hint);
            return false;
        }
        out = int(it->get<long long>());
        return true;
    }
    bool boolean(const Json& obj, const char* key, const std::string& at, bool& out, const char* hint) {
        auto it = obj.find(key);
        if (it == obj.end()) return false;
        if (!it->is_boolean()) {
            err(at + "/" + key, std::string(key) + " must be true or false, got " + describe_json_value(*it), hint);
            return false;
        }
        out = it->get<bool>();
        return true;
    }
    bool text(const Json& obj, const char* key, const std::string& at, std::string& out, const char* hint) {
        auto it = obj.find(key);
        if (it == obj.end()) return false;
        if (!it->is_string() || it->get<std::string>().empty()) {
            err(at + "/" + key, std::string(key) + " must be a non-empty text, got " + describe_json_value(*it), hint);
            return false;
        }
        out = it->get<std::string>();
        return true;
    }
    std::optional<Vec4> color(const Json& obj, const char* key, const std::string& at) {
        auto it = obj.find(key);
        if (it == obj.end()) return std::nullopt;
        auto c = model_parse_color(*it);
        if (!c) {
            err(at + "/" + key,
                std::string(key) +
                    " must be a colour: \"#rrggbb\" (or \"#rrggbbaa\"), or [r, g, b] / [r, g, b, a] with each number "
                    "from 0 to 1, got " +
                    describe_json_value(*it),
                "Example: \"#c8a064\" or [0.78, 0.63, 0.39].");
            return std::nullopt;
        }
        return c;
    }
    std::optional<std::vector<std::string>> strings(const Json& obj, const char* key, const std::string& at,
                                                    const char* hint) {
        auto it = obj.find(key);
        if (it == obj.end()) return std::nullopt;
        if (!it->is_array()) {
            err(at + "/" + key, std::string(key) + " must be a list of text, got " + describe_json_value(*it), hint);
            return std::nullopt;
        }
        std::vector<std::string> out;
        for (std::size_t i = 0; i < it->size(); ++i) {
            if (!(*it)[i].is_string()) {
                err(at + "/" + key + "/" + std::to_string(i),
                    "entries of " + std::string(key) + " must be text, got " + describe_json_value((*it)[i]), hint);
                continue;
            }
            out.push_back((*it)[i].get<std::string>());
        }
        return out;
    }
    std::optional<Vec3> vec3(const Json& obj, const char* key, const std::string& at, const char* hint) {
        auto it = obj.find(key);
        if (it == obj.end()) return std::nullopt;
        if (!it->is_array() || it->size() != 3 || !(*it)[0].is_number() || !(*it)[1].is_number() ||
            !(*it)[2].is_number()) {
            err(at + "/" + key, std::string(key) + " must be [x, y, z], got " + describe_json_value(*it), hint);
            return std::nullopt;
        }
        return Vec3{float((*it)[0].get<double>()), float((*it)[1].get<double>()), float((*it)[2].get<double>())};
    }
};

// ---- vertexColors -------------------------------------------------------------------------------------------------------------

const std::vector<std::string>& vc_keys() {
    static const std::vector<std::string> v = {"palette", "snap", "flat", "variation", "seed", "color", "parts"};
    return v;
}
const std::vector<std::string>& vc_part_keys() {
    static const std::vector<std::string> v = {"color", "gradient", "variation"};
    return v;
}
const std::vector<std::string>& gradient_keys() {
    static const std::vector<std::string> v = {"axis", "from", "to", "via", "range"};
    return v;
}

std::optional<ModelColorRef> read_color_ref(Reader& r, const Json& obj, const char* key, const std::string& at,
                                            long long paletteSize, bool hasPalette) {
    auto it = obj.find(key);
    if (it == obj.end()) return std::nullopt;
    ModelColorRef ref;
    if (it->is_number_integer()) {
        const long long i = it->get<long long>();
        if (!hasPalette) {
            r.err(
                at + "/" + key, "a palette index needs a palette, and the section has none",
                "Set \"palette\": \"style\" (the project's palette) or a list of colours, or give the colour itself.");
            return std::nullopt;
        }
        if (i < 0 || (paletteSize > 0 && i >= paletteSize)) {
            r.err(at + "/" + key,
                  std::format("palette index {} is outside the palette ({} colours, 0 to {})", i, paletteSize,
                              paletteSize - 1),
                  "Use an index in range, or give the colour itself.");
            return std::nullopt;
        }
        ref.isIndex = true;
        ref.index = int(i);
        return ref;
    }
    auto c = model_parse_color(*it);
    if (!c) {
        r.err(at + "/" + key,
              std::string(key) +
                  " must be a colour (\"#rrggbb\", or [r, g, b] from 0 to 1) or a palette index (an integer), got " +
                  describe_json_value(*it),
              "Example: \"#7a9e3b\" or 2.");
        return std::nullopt;
    }
    ref.rgba = *c;
    return ref;
}

Json color_ref_json(const ModelColorRef& c) { return c.isIndex ? Json(c.index) : Json(hex_color(c.rgba)); }

}  // namespace

std::optional<ModelVertexColors> parse_model_vertex_colors(const Json& json, std::vector<ModelIssue>& issues) {
    Reader r{issues};
    const std::size_t before = issues.size();
    if (!json.is_object()) {
        r.err("/vertexColors",
              "vertexColors must be an object like {\"palette\": \"style\", \"flat\": true}, got " +
                  describe_json_value(json),
              "Leave it out to keep the nodes' own colours. docs/MODELING.md, \"Texturing\", lists the fields.");
        return std::nullopt;
    }
    ModelVertexColors s;
    r.unknown_keys(json, "/vertexColors", vc_keys(), "vertexColors");
    bool hasPalette = false;
    if (auto it = json.find("palette"); it != json.end()) {
        if (it->is_string()) {
            if (it->get<std::string>() != "style")
                r.err("/vertexColors/palette",
                      "palette must be \"style\" or a list of colours, got \"" + it->get<std::string>() + "\"",
                      "\"style\" is the palette of the project's style guide (assets.json style.palette).");
            else
                s.style = hasPalette = true;
        } else if (it->is_array()) {
            for (std::size_t i = 0; i < it->size(); ++i) {
                auto c = model_parse_color((*it)[i]);
                if (!c)
                    r.err("/vertexColors/palette/" + std::to_string(i),
                          "palette entries must be colours (\"#rrggbb\" or [r, g, b]), got " +
                              describe_json_value((*it)[i]),
                          "Example: [\"#2d3a1f\", \"#7a9e3b\", \"#e8d9a0\"].");
                else
                    s.palette.push_back(*c);
            }
            if (it->empty())
                r.err("/vertexColors/palette", "palette is empty", "List at least one colour, or use \"style\".");
            hasPalette = !s.palette.empty();
        } else
            r.err("/vertexColors/palette",
                  "palette must be \"style\" or a list of colours, got " + describe_json_value(*it),
                  "Example: \"palette\": \"style\".");
    }
    const long long paletteSize =
        s.style ? 0 : (long long)s.palette.size();  // a style palette's size is only known with the project
    r.boolean(json, "snap", "/vertexColors", s.snap,
              "true (default) moves every colour to the nearest palette colour; false uses the colours as written.");
    r.boolean(json, "flat", "/vertexColors", s.flat,
              "true gives each triangle one colour (vertices are split): the faceted low-poly look.");
    r.number(json, "variation", "/vertexColors", 0, 0.5, s.variation,
             "0.05 changes the brightness of each triangle (or vertex) by up to 5% either way; 0 (default) none.");
    r.integer(json, "seed", "/vertexColors", 0, 2147483647, s.seed,
              "Any whole number: it changes which triangles are lighter or darker.");
    s.color = read_color_ref(r, json, "color", "/vertexColors", paletteSize, hasPalette);
    if (auto it = json.find("parts"); it != json.end()) {
        if (!it->is_object())
            r.err("/vertexColors/parts",
                  "parts must be an object of part name to colours, got " + describe_json_value(*it),
                  "Example: {\"roof\": {\"color\": \"#8a3b2b\"}, \"wall\": {\"gradient\": {\"from\": \"#d8c8a0\", "
                  "\"to\": \"#a08c64\"}}}.");
        else
            for (auto p = it->begin(); p != it->end(); ++p) {
                const std::string at = "/vertexColors/parts/" + p.key();
                if (!p->is_object()) {
                    r.err(at,
                          "a part's colours must be an object like {\"color\": \"#8a3b2b\"}, got " +
                              describe_json_value(*p),
                          "Fields: color, gradient, variation.");
                    continue;
                }
                r.unknown_keys(*p, at, vc_part_keys(), "a vertexColors part");
                ModelPartColors pc;
                pc.color = read_color_ref(r, *p, "color", at, paletteSize, hasPalette);
                float var = 0;
                if (r.number(*p, "variation", at, 0, 0.5, var, "0 to 0.5.")) pc.variation = var;
                if (auto g = p->find("gradient"); g != p->end()) {
                    const std::string gat = at + "/gradient";
                    if (!g->is_object())
                        r.err(gat,
                              "gradient must be an object like {\"axis\": \"y\", \"from\": \"#3a2a1a\", \"to\": "
                              "\"#c8a064\"}, got " +
                                  describe_json_value(*g),
                              "Fields: axis, from, to, via, range.");
                    else {
                        r.unknown_keys(*g, gat, gradient_keys(), "a gradient");
                        ModelColorGradient gr;
                        if (auto a = g->find("axis"); a != g->end()) {
                            if (!a->is_string() || (a->get<std::string>() != "x" && a->get<std::string>() != "y" &&
                                                    a->get<std::string>() != "z"))
                                r.err(gat + "/axis",
                                      "axis must be \"x\", \"y\" or \"z\", got " + describe_json_value(*a),
                                      "The model axis the colour changes along; y is up.");
                            else
                                gr.axis = a->get<std::string>()[0];
                        }
                        auto from = read_color_ref(r, *g, "from", gat, paletteSize, hasPalette);
                        auto to = read_color_ref(r, *g, "to", gat, paletteSize, hasPalette);
                        if (!g->contains("from"))
                            r.err(gat + "/from", "a gradient needs \"from\" (the colour at the low end)",
                                  "Add \"from\" and \"to\".");
                        if (!g->contains("to"))
                            r.err(gat + "/to", "a gradient needs \"to\" (the colour at the high end)",
                                  "Add \"from\" and \"to\".");
                        if (from) gr.from = *from;
                        if (to) gr.to = *to;
                        gr.via = read_color_ref(r, *g, "via", gat, paletteSize, hasPalette);
                        if (auto rg = g->find("range"); rg != g->end()) {
                            if (!rg->is_array() || rg->size() != 2 || !(*rg)[0].is_number() || !(*rg)[1].is_number() ||
                                (*rg)[0].get<double>() >= (*rg)[1].get<double>())
                                r.err(gat + "/range",
                                      "range must be [low, high] in metres along the axis with low < high, got " +
                                          describe_json_value(*rg),
                                      "Leave it out to use the part's own extent.");
                            else
                                gr.range = std::pair<float, float>{float((*rg)[0].get<double>()),
                                                                   float((*rg)[1].get<double>())};
                        }
                        pc.gradient = gr;
                    }
                }
                if (pc.color && pc.gradient)
                    r.err(at, "a part has both \"color\" and \"gradient\"",
                          "Keep one: the gradient colours the part from one end to the other, the colour is flat.");
                s.parts.emplace_back(p.key(), pc);
            }
    }
    if (issues.size() != before) return std::nullopt;
    return s;
}

Json model_vertex_colors_json(const ModelVertexColors& s) {
    Json j = Json::object();
    if (s.style)
        j["palette"] = "style";
    else if (!s.palette.empty()) {
        Json p = Json::array();
        for (Vec4 c : s.palette) p.push_back(hex_color(c));
        j["palette"] = p;
    }
    j["snap"] = s.snap;
    j["flat"] = s.flat;
    j["variation"] = jf(s.variation);
    j["seed"] = s.seed;
    if (s.color) j["color"] = color_ref_json(*s.color);
    if (!s.parts.empty()) {
        Json parts = Json::object();
        for (const auto& [name, pc] : s.parts) {
            Json p = Json::object();
            if (pc.color) p["color"] = color_ref_json(*pc.color);
            if (pc.gradient) {
                Json g = Json::object({{"axis", std::string(1, pc.gradient->axis)},
                                       {"from", color_ref_json(pc.gradient->from)},
                                       {"to", color_ref_json(pc.gradient->to)}});
                if (pc.gradient->via) g["via"] = color_ref_json(*pc.gradient->via);
                if (pc.gradient->range)
                    g["range"] = Json::array({jf(pc.gradient->range->first), jf(pc.gradient->range->second)});
                p["gradient"] = g;
            }
            if (pc.variation) p["variation"] = jf(*pc.variation);
            parts[name] = p;
        }
        j["parts"] = parts;
    }
    return j;
}

Json model_vertex_colors_schema() {
    Json colorRef = Json::object({{"description", "A colour (\"#rrggbb\", \"#rrggbbaa\", or [r, g, b] from 0 to 1) or "
                                                  "an integer: the position of a colour in the palette."},
                                  {"oneOf", Json::array({Json::object({{"type", "string"}}),
                                                         Json::object({{"type", "array"},
                                                                       {"minItems", 3},
                                                                       {"maxItems", 4},
                                                                       {"items", Json::object({{"type", "number"}})}}),
                                                         Json::object({{"type", "integer"}, {"minimum", 0}})})}});
    Json gradient = Json::object(
        {{"type", "object"},
         {"additionalProperties", false},
         {"required", Json::array({"from", "to"})},
         {"description",
          "A colour that changes along a model axis, from the low end to the high end (through `via` if given)."},
         {"properties",
          Json::object(
              {{"axis", Json::object({{"type", "string"},
                                      {"enum", Json::array({"x", "y", "z"})},
                                      {"default", "y"},
                                      {"description", "The model axis the colour changes along."}})},
               {"from", colorRef},
               {"to", colorRef},
               {"via", colorRef},
               {"range",
                Json::object({{"type", "array"},
                              {"minItems", 2},
                              {"maxItems", 2},
                              {"items", Json::object({{"type", "number"}})},
                              {"description",
                               "[low, high] in metres along the axis. Default: the extent of the part itself."}})}})}});
    Json part = Json::object(
        {{"type", "object"},
         {"additionalProperties", false},
         {"description", "The colours of one part: a flat colour or a gradient, and its own variation."},
         {"properties",
          Json::object(
              {{"color", colorRef},
               {"gradient", gradient},
               {"variation", Json::object({{"type", "number"},
                                           {"minimum", 0},
                                           {"maximum", 0.5},
                                           {"description", "Overrides the section's variation for this part."}})}})}});
    return Json::object(
        {{"type", "object"},
         {"additionalProperties", false},
         {"description", "Colours written into the mesh's vertices: a low-poly look with no texture at all. The "
                         "colours multiply the node colours and the material colour. "
                         "docs/MODELING.md, \"Texturing\"; `model.palette` edits and measures it."},
         {"properties",
          Json::object(
              {{"palette",
                Json::object(
                    {{"description", "\"style\": the palette of the project's style guide. Or a list of colours. With "
                                     "a palette, colours snap to it."},
                     {"oneOf",
                      Json::array({Json::object({{"type", "string"}, {"enum", Json::array({"style"})}}),
                                   Json::object({{"type", "array"}, {"minItems", 1}, {"items", colorRef}})})}})},
               {"snap",
                Json::object({{"type", "boolean"},
                              {"default", true},
                              {"description",
                               "Move every colour to the nearest colour of the palette. Ignored without a palette."}})},
               {"flat", Json::object({{"type", "boolean"},
                                      {"default", false},
                                      {"description", "One colour per triangle (vertices are split so the colours do "
                                                      "not blend): the faceted low-poly look."}})},
               {"variation",
                Json::object({{"type", "number"},
                              {"minimum", 0},
                              {"maximum", 0.5},
                              {"default", 0},
                              {"description", "Brightness change per triangle (flat) or vertex, up to this much either "
                                              "way, chosen by a hash (deterministic)."}})},
               {"seed",
                Json::object({{"type", "integer"},
                              {"minimum", 0},
                              {"default", 0},
                              {"description", "Changes which triangles the variation makes lighter or darker."}})},
               {"color", colorRef},
               {"parts",
                Json::object({{"type", "object"},
                              {"additionalProperties", part},
                              {"description", "By part name (\"\" for the nodes that name no part): the colours of "
                                              "that part. A part with no entry gets `color`."}})}})}});
}

// ---- material fields ----------------------------------------------------------------------------------------------------------

const std::vector<std::string>& model_material_texturing_keys() {
    static const std::vector<std::string> v = {"mapping", "textureScale", "textureOffset", "sharpness", "tint"};
    return v;
}

ModelMaterialTexturing parse_model_material_texturing(const Json& material, const std::string& at,
                                                      std::vector<ModelIssue>& issues) {
    Reader r{issues};
    ModelMaterialTexturing m;
    if (auto it = material.find("mapping"); it != material.end()) {
        if (!it->is_string() || (it->get<std::string>() != "uv" && it->get<std::string>() != "triplanar"))
            r.err(at + "/mapping", "mapping must be \"uv\" or \"triplanar\", got " + describe_json_value(*it),
                  "\"triplanar\" projects the texture along the three axes and bakes it into the model's atlas (needs "
                  "a `texturing` section); \"uv\" draws it through the model's uvs.");
        else {
            m.mapping = it->get<std::string>();
            m.mappingGiven = true;
        }
    }
    r.number(material, "textureScale", at, 0.001, 1000, m.scale,
             "Metres one repeat of the texture covers: 1 repeats it every metre.");
    if (auto o = r.vec3(material, "textureOffset", at, "Metres the texture is shifted by, [x, y, z].")) m.offset = *o;
    r.integer(material, "sharpness", at, 1, 16, m.sharpness,
              "How fast the three projections hand over to each other where the surface turns: 1 is soft, 16 almost a "
              "hard edge. Default 4.");
    if (auto c = r.color(material, "tint", at)) m.tint = *c;
    return m;
}

Json model_material_texturing_schema_properties() {
    return Json::object(
        {{"mapping",
          Json::object(
              {{"type", "string"},
               {"enum", Json::array({"uv", "triplanar"})},
               {"description",
                "How `texture` is put on the model. \"uv\": through the model's uvs (the baked .glb references the "
                "image). \"triplanar\": projected along the three axes at `textureScale` and BAKED into the "
                "model's atlas by the `texturing` section (default for a material with a texture when the document has "
                "`texturing`)."}})},
         {"textureScale", Json::object({{"type", "number"},
                                        {"minimum", 0.001},
                                        {"maximum", 1000},
                                        {"default", 1},
                                        {"description", "triplanar: metres one repeat of the texture covers."}})},
         {"textureOffset", Json::object({{"type", "array"},
                                         {"minItems", 3},
                                         {"maxItems", 3},
                                         {"items", Json::object({{"type", "number"}})},
                                         {"description", "triplanar: metres the texture is shifted by, [x, y, z]."}})},
         {"sharpness",
          Json::object(
              {{"type", "integer"},
               {"minimum", 1},
               {"maximum", 16},
               {"default", 4},
               {"description",
                "triplanar: how hard the three projections hand over to each other (1 soft .. 16 almost hard)."}})},
         {"tint",
          Json::object(
              {{"description", "A colour that multiplies the texture (and the material colour) in the bake."},
               {"oneOf", Json::array({Json::object({{"type", "string"}}), Json::object({{"type", "array"}})})}})}});
}

// ---- texturing ----------------------------------------------------------------------------------------------------------------

namespace {

const std::vector<std::string>& tex_keys() {
    static const std::vector<std::string> v = {"size", "bleed", "vertexColors", "background", "document",
                                               "ao",   "maps",  "wear",         "decals"};
    return v;
}
const std::vector<std::string>& map_names() {
    static const std::vector<std::string> v = {"ao", "curvature", "thickness"};
    return v;
}
const std::vector<std::string>& wear_masks() {
    static const std::vector<std::string> v = {"edges", "cavity", "ao", "thickness"};
    return v;
}
const std::vector<std::string>& map_keys() {
    static const std::vector<std::string> v = {"samples",   "distance",  "thicknessDistance",
                                               "edgeAngle", "edgeWidth", "write"};
    return v;
}
const std::vector<std::string>& wear_keys() {
    static const std::vector<std::string> v = {"name",  "mask",       "color", "amount", "width", "threshold",
                                               "noise", "noiseScale", "seed",  "upBias", "parts"};
    return v;
}
const std::vector<std::string>& decal_keys() {
    static const std::vector<std::string> v = {"name", "image", "parts",    "faces",   "position", "normal",
                                               "size", "depth", "rotation", "opacity", "tint",     "maxAngle"};
    return v;
}

bool is_image_path(const std::string& p) {
    const std::string l = to_lower(p);
    return ends_with(l, ".png") || ends_with(l, ".jpg") || ends_with(l, ".jpeg") || ends_with(l, ".tga") ||
           ends_with(l, ".bmp");
}

}  // namespace

std::optional<ModelTexturing> parse_model_texturing(const Json& json, std::vector<ModelIssue>& issues) {
    Reader r{issues};
    const std::size_t before = issues.size();
    const std::string at0 = "/texturing";
    if (!json.is_object()) {
        r.err(at0,
              "texturing must be an object like {\"ao\": true, \"wear\": [{\"mask\": \"edges\"}]}, got " +
                  describe_json_value(json),
              "Leave it out for a model with no baked texture. docs/MODELING.md, \"Texturing\", lists the fields.");
        return std::nullopt;
    }
    ModelTexturing t;
    r.unknown_keys(json, at0, tex_keys(), "texturing");
    if (auto it = json.find("size"); it != json.end()) {
        if (!it->is_number_integer() || (it->get<long long>() != 0 && (it->get<long long>() < kModelTextureMinSize ||
                                                                       it->get<long long>() > kModelTextureMaxSize)))
            r.err(at0 + "/size",
                  std::format("size must be 0 (the uv section's texture size) or an integer from {} to {}, got {}",
                              kModelTextureMinSize, kModelTextureMaxSize, describe_json_value(*it)),
                  "Use a power of two: 512, 1024, 2048.");
        else
            t.size = int(it->get<long long>());
    }
    if (auto it = json.find("bleed"); it != json.end()) {
        if (!it->is_number_integer() || it->get<long long>() < 0 || it->get<long long>() > kModelTextureMaxBleed)
            r.err(at0 + "/bleed",
                  std::format(
                      "bleed must be an integer from 0 to {} (texels the colours are spread beyond each piece), got {}",
                      kModelTextureMaxBleed, describe_json_value(*it)),
                  "Leave it out to use the uv padding; 2 to 4 keeps mipmaps from showing the background.");
        else
            t.bleed = int(it->get<long long>());
    }
    if (auto it = json.find("vertexColors"); it != json.end()) {
        if (!it->is_string() || (it->get<std::string>() != "bake" && it->get<std::string>() != "keep"))
            r.err(at0 + "/vertexColors", "vertexColors must be \"bake\" or \"keep\", got " + describe_json_value(*it),
                  "\"bake\" (default) paints the vertex colours into the texture and leaves them out of the .glb; "
                  "\"keep\" leaves them on the mesh (they multiply the texture).");
        else
            t.vertexColors = it->get<std::string>();
    }
    if (auto c = r.color(json, "background", at0)) t.background = *c;
    if (auto it = json.find("document"); it != json.end()) {
        if (!it->is_string() || !ends_with(to_lower(it->get<std::string>()), ".image.json"))
            r.err(at0 + "/document",
                  "document must be a project path ending in .image.json, got " + describe_json_value(*it),
                  "Example: \"assets/models/door.texture.image.json\". Leave it out for <model>.texture.image.json "
                  "next to the model.");
        else
            t.document = it->get<std::string>();
    }
    if (auto it = json.find("ao"); it != json.end()) {
        if (it->is_boolean()) {
            if (it->get<bool>()) t.aoStrength = 0.7f;
        } else if (it->is_object()) {
            r.unknown_keys(*it, at0 + "/ao", {"strength", "parts"}, "texturing.ao");
            float strength = 0.7f;
            r.number(*it, "strength", at0 + "/ao", 0, 1, strength,
                     "0 is no darkening, 1 black in the deepest corner. Default 0.7.");
            t.aoStrength = strength;
            if (auto p =
                    r.strings(*it, "parts", at0 + "/ao", "Part names the occlusion darkens; leave it out for all."))
                t.aoParts = *p;
        } else
            r.err(at0 + "/ao", "ao must be true or an object like {\"strength\": 0.6}, got " + describe_json_value(*it),
                  "true bakes ambient occlusion and multiplies it into the texture.");
    }
    if (auto it = json.find("maps"); it != json.end()) {
        const std::string at = at0 + "/maps";
        if (!it->is_object())
            r.err(at,
                  "maps must be an object like {\"samples\": 32, \"write\": [\"curvature\"]}, got " +
                      describe_json_value(*it),
                  "Fields: samples, distance, thicknessDistance, edgeAngle, edgeWidth, write.");
        else {
            r.unknown_keys(*it, at, map_keys(), "texturing.maps");
            r.integer(*it, "samples", at, 4, kModelTextureMaxSamples, t.maps.samples,
                      "Rays per texel for occlusion and thickness: 16 (default) is fast, 64 smooth.");
            r.number(*it, "distance", at, 0, 10000, t.maps.distance,
                     "Metres an occluder may be away and still darken (0, default: 15% of the model's diagonal).");
            r.number(*it, "thicknessDistance", at, 0, 10000, t.maps.thicknessDistance,
                     "Metres the thickness is measured up to (0, default: 50% of the diagonal).");
            r.number(*it, "edgeAngle", at, 1, 179, t.maps.edgeAngle,
                     "An edge counts as sharp when the surface turns at least this many degrees there. Default 20.");
            r.number(*it, "edgeWidth", at, 0, 10000, t.maps.edgeWidth,
                     "Metres wide the band along a sharp edge is (0, default: 3% of the diagonal).");
            if (auto w = r.strings(*it, "write", at,
                                   "Maps also written as pictures: \"ao\", \"curvature\", \"thickness\".")) {
                for (std::size_t i = 0; i < w->size(); ++i) {
                    if (std::find(map_names().begin(), map_names().end(), (*w)[i]) == map_names().end())
                        r.err(at + "/write/" + std::to_string(i),
                              "\"" + (*w)[i] + "\" is not a map (" + quoted(map_names()) + ")",
                              did_you_mean((*w)[i], map_names()));
                    else if (std::find(t.maps.write.begin(), t.maps.write.end(), (*w)[i]) == t.maps.write.end())
                        t.maps.write.push_back((*w)[i]);
                }
            }
        }
    }
    if (auto it = json.find("wear"); it != json.end()) {
        if (!it->is_array())
            r.err(at0 + "/wear",
                  "wear must be a list like [{\"mask\": \"edges\", \"color\": \"#d8d0c0\"}], got " +
                      describe_json_value(*it),
                  "Each entry is one kind of wear: worn edges, dirt in cavities...");
        else
            for (std::size_t i = 0; i < it->size(); ++i) {
                const Json& w = (*it)[i];
                const std::string at = at0 + "/wear/" + std::to_string(i);
                if (!w.is_object()) {
                    r.err(at,
                          "a wear entry must be an object like {\"mask\": \"cavity\", \"color\": \"#2a2018\"}, got " +
                              describe_json_value(w),
                          "Fields: " + quoted(wear_keys()) + ".");
                    continue;
                }
                r.unknown_keys(w, at, wear_keys(), "a wear entry");
                ModelWearSpec s;
                s.name = "wear" + std::to_string(i + 1);
                r.text(w, "name", at, s.name, "A label for the report.");
                if (auto m = w.find("mask"); m != w.end()) {
                    if (!m->is_string() || std::find(wear_masks().begin(), wear_masks().end(), m->get<std::string>()) ==
                                               wear_masks().end())
                        r.err(
                            at + "/mask",
                            "mask must be one of " + quoted(wear_masks()) + ", got " + describe_json_value(*m),
                            (m->is_string() ? did_you_mean(m->get<std::string>(), wear_masks()) + " " : std::string()) +
                                "edges: paint along convex edges; cavity: in concave corners and occluded places; ao: "
                                "wherever occlusion is; thickness: where the shell is thin.");
                    else
                        s.mask = m->get<std::string>();
                }
                s.color = r.color(w, "color", at);
                r.number(w, "amount", at, 0, 1, s.amount, "Opacity at the strongest, 0 to 1. Default 0.8.");
                float width = 0;
                if (r.number(w, "width", at, 0.0001, 10000, width,
                             "Metres of the band along an edge or in a corner (default maps.edgeWidth)."))
                    s.width = width;
                r.number(
                    w, "threshold", at, 0, 0.99, s.threshold,
                    "The mask below this value is nothing; raise it to keep only the strongest places. Default 0.1.");
                r.number(w, "noise", at, 0, 1, s.noise,
                         "How much noise breaks the wear up: 0 a clean band, 1 mostly broken. Default 0.4.");
                r.number(w, "noiseScale", at, 0.001, 1000, s.noiseScale, "Metres per noise feature. Default 0.15.");
                r.integer(w, "seed", at, 0, 2147483647, s.seed, "Changes the noise pattern.");
                r.number(w, "upBias", at, -1, 1, s.upBias,
                         "More wear on surfaces that face up (positive: dust, snow, moss) or down (negative).");
                if (auto p = r.strings(w, "parts", at, "Only these parts get this wear; leave it out for all."))
                    s.parts = *p;
                for (const ModelWearSpec& o : t.wear)
                    if (o.name == s.name)
                        r.err(at + "/name", "two wear entries are named \"" + s.name + "\"",
                              "Give each a different name.");
                t.wear.push_back(std::move(s));
            }
    }
    if (auto it = json.find("decals"); it != json.end()) {
        if (!it->is_array())
            r.err(at0 + "/decals",
                  "decals must be a list like [{\"image\": \"assets/decals/logo.png\", \"position\": [0, 1, 0.5], "
                  "\"size\": [0.4, 0.4]}], got " +
                      describe_json_value(*it),
                  "Each entry is one projected picture.");
        else
            for (std::size_t i = 0; i < it->size(); ++i) {
                const Json& d = (*it)[i];
                const std::string at = at0 + "/decals/" + std::to_string(i);
                if (!d.is_object()) {
                    r.err(at,
                          "a decal must be an object like {\"image\": \"assets/decals/logo.png\", \"position\": [0, 1, "
                          "0.5]}, got " +
                              describe_json_value(d),
                          "Fields: " + quoted(decal_keys()) + ".");
                    continue;
                }
                r.unknown_keys(d, at, decal_keys(), "a decal");
                ModelDecalSpec s;
                s.name = "decal" + std::to_string(i + 1);
                r.text(d, "name", at, s.name, "A label for the report.");
                if (!d.contains("image"))
                    r.err(at + "/image", "a decal needs an \"image\" (a project picture)",
                          "Example: \"image\": \"assets/decals/logo.png\"; assets.generate_texture or an image "
                          "document's baked png both work.");
                else if (r.text(d, "image", at, s.image, "A project path to a png/jpg.") && !is_image_path(s.image))
                    r.err(at + "/image", "image must be a png, jpg, tga or bmp file, got \"" + s.image + "\"",
                          "Bake an image document first and name its .png.");
                if (auto p = r.strings(d, "parts", at, "Only these parts get the decal; leave it out for any."))
                    s.parts = *p;
                if (auto f = d.find("faces"); f != d.end()) {
                    check_model_selection(*f, ModelSelectKind::Faces, at + "/faces", issues);
                    s.faces = *f;
                }
                if (!d.contains("position"))
                    r.err(at + "/position", "a decal needs a \"position\" (where it is projected from, in model space)",
                          "Example: [0, 1.2, 0.5]; model.info lists each part's bounds.");
                if (auto p = r.vec3(d, "position", at, "Metres in the model's space: the centre of the decal."))
                    s.position = *p;
                if (auto n = d.find("normal"); n != d.end()) {
                    if (n->is_string()) {
                        bool found = false;
                        std::vector<std::string> names;
                        for (const auto& [nm, v] : model_named_directions()) {
                            names.push_back(nm);
                            if (nm == n->get<std::string>()) {
                                s.normal = v;
                                found = true;
                            }
                        }
                        if (!found)
                            r.err(at + "/normal",
                                  "normal \"" + n->get<std::string>() + "\" is not a direction (" + quoted(names) + ")",
                                  did_you_mean(n->get<std::string>(), names) + " Or give [x, y, z].");
                    } else if (auto v = r.vec3(d, "normal", at,
                                               "The way the surface it sits on faces: [x, y, z] or a direction name "
                                               "(top, front...).")) {
                        if (length(*v) < 1e-6f)
                            r.err(at + "/normal", "normal is the zero vector",
                                  "Give a direction such as [0, 0, 1] or \"front\".");
                        else
                            s.normal = normalize(*v);
                    }
                } else
                    s.normal = Vec3{0, 0, 1};
                if (auto sz = d.find("size"); sz != d.end()) {
                    if (sz->is_number() && sz->get<double>() > 0 && sz->get<double>() <= 1000)
                        s.size = Vec2{float(sz->get<double>()), float(sz->get<double>())};
                    else if (sz->is_array() && sz->size() == 2 && (*sz)[0].is_number() && (*sz)[1].is_number() &&
                             (*sz)[0].get<double>() > 0 && (*sz)[1].get<double>() > 0 &&
                             (*sz)[0].get<double>() <= 1000 && (*sz)[1].get<double>() <= 1000)
                        s.size = Vec2{float((*sz)[0].get<double>()), float((*sz)[1].get<double>())};
                    else
                        r.err(at + "/size",
                              "size must be a positive number or [width, height] in metres, got " +
                                  describe_json_value(*sz),
                              "Example: [0.4, 0.3].");
                } else
                    r.err(at + "/size", "a decal needs a \"size\" (metres, [width, height] or one number)",
                          "Example: \"size\": [0.4, 0.3].");
                r.number(d, "depth", at, 0, 1000, s.depth,
                         "Metres the projection reaches from the plane through `position`, each way along the normal "
                         "(0, default: the smaller side of the decal).");
                r.number(d, "rotation", at, -360, 360, s.rotation, "Degrees around the normal.");
                r.number(d, "opacity", at, 0, 1, s.opacity, "0 to 1. Default 1.");
                if (auto c = r.color(d, "tint", at)) s.tint = *c;
                r.number(d, "maxAngle", at, 1, 179, s.maxAngle,
                         "Degrees: surfaces turned more than this away from `normal` are left alone. Default 75.");
                for (const ModelDecalSpec& o : t.decals)
                    if (o.name == s.name)
                        r.err(at + "/name", "two decals are named \"" + s.name + "\"", "Give each a different name.");
                t.decals.push_back(std::move(s));
            }
    }
    if (issues.size() != before) return std::nullopt;
    return t;
}

Json model_texturing_json(const ModelTexturing& t) {
    Json j = Json::object();
    j["size"] = t.size;
    if (t.bleed >= 0) j["bleed"] = t.bleed;
    j["vertexColors"] = t.vertexColors;
    j["background"] = hex_color(t.background);
    if (!t.document.empty()) j["document"] = t.document;
    if (t.aoStrength) {
        Json ao = Json::object({{"strength", jf(*t.aoStrength)}});
        if (!t.aoParts.empty()) ao["parts"] = t.aoParts;
        j["ao"] = ao;
    }
    Json maps = Json::object({{"samples", t.maps.samples},
                              {"distance", jf(t.maps.distance)},
                              {"thicknessDistance", jf(t.maps.thicknessDistance)},
                              {"edgeAngle", jf(t.maps.edgeAngle)},
                              {"edgeWidth", jf(t.maps.edgeWidth)}});
    if (!t.maps.write.empty()) maps["write"] = t.maps.write;
    j["maps"] = maps;
    if (!t.wear.empty()) {
        Json arr = Json::array();
        for (const ModelWearSpec& w : t.wear) {
            Json o = Json::object({{"name", w.name},
                                   {"mask", w.mask},
                                   {"amount", jf(w.amount)},
                                   {"threshold", jf(w.threshold)},
                                   {"noise", jf(w.noise)},
                                   {"noiseScale", jf(w.noiseScale)},
                                   {"seed", w.seed},
                                   {"upBias", jf(w.upBias)}});
            if (w.color) o["color"] = hex_color(*w.color);
            if (w.width) o["width"] = jf(*w.width);
            if (!w.parts.empty()) o["parts"] = w.parts;
            arr.push_back(o);
        }
        j["wear"] = arr;
    }
    if (!t.decals.empty()) {
        Json arr = Json::array();
        for (const ModelDecalSpec& d : t.decals) {
            Json o = Json::object({{"name", d.name},
                                   {"image", d.image},
                                   {"position", vec_json(d.position)},
                                   {"normal", vec_json(d.normal)},
                                   {"size", Json::array({jf(d.size.x), jf(d.size.y)})},
                                   {"depth", jf(d.depth)},
                                   {"rotation", jf(d.rotation)},
                                   {"opacity", jf(d.opacity)},
                                   {"maxAngle", jf(d.maxAngle)}});
            if (d.tint.x != 1 || d.tint.y != 1 || d.tint.z != 1 || d.tint.w != 1) o["tint"] = hex_color(d.tint);
            if (!d.parts.empty()) o["parts"] = d.parts;
            if (!d.faces.is_null()) o["faces"] = d.faces;
            arr.push_back(o);
        }
        j["decals"] = arr;
    }
    return j;
}

Json model_texturing_schema() {
    auto num = [](const char* type, const char* doc) { return Json::object({{"type", type}, {"description", doc}}); };
    auto bounded = [](const char* type, double lo, double hi, const char* doc) {
        return Json::object({{"type", type}, {"minimum", lo}, {"maximum", hi}, {"description", doc}});
    };
    Json colorProp =
        Json::object({{"description", "\"#rrggbb\" (or \"#rrggbbaa\"), or [r, g, b] / [r, g, b, a] from 0 to 1."},
                      {"oneOf", Json::array({Json::object({{"type", "string"}}), Json::object({{"type", "array"}})})}});
    Json strs = Json::object({{"type", "array"}, {"items", Json::object({{"type", "string"}})}});
    auto withDoc = [](Json base, const char* doc) {
        base["description"] = doc;
        return base;
    };
    Json wear = Json::object(
        {{"type", "object"},
         {"additionalProperties", false},
         {"description", "One kind of wear painted over the base colour from a baked map: worn edges, dirt in "
                         "cavities, dust on top. All entries are composited into one transparent layer."},
         {"properties",
          Json::object(
              {{"name", num("string", "A label for the report.")},
               {"mask",
                Json::object(
                    {{"type", "string"},
                     {"enum", Json::array({"edges", "cavity", "ao", "thickness"})},
                     {"default", "edges"},
                     {"description",
                      "Where the wear goes. edges: along convex edges (paint chipped); cavity: concave corners and "
                      "occluded places (dirt); ao: wherever occlusion is; thickness: where the shell is thin."}})},
               {"color",
                withDoc(colorProp, "The wear colour. Default: light for edges and thickness, dark for cavity and ao.")},
               {"amount", bounded("number", 0, 1, "Opacity at the strongest. Default 0.8.")},
               {"width",
                bounded("number", 0.0001, 10000, "edges, cavity: metres of the band. Default maps.edgeWidth.")},
               {"threshold", bounded("number", 0, 0.99, "The mask below this value is nothing. Default 0.1.")},
               {"noise", bounded("number", 0, 1, "How much noise breaks the wear up. Default 0.4.")},
               {"noiseScale", bounded("number", 0.001, 1000, "Metres per noise feature. Default 0.15.")},
               {"seed", bounded("integer", 0, 2147483647, "Changes the noise pattern.")},
               {"upBias",
                bounded("number", -1, 1,
                        "Positive: more on surfaces that face up. Negative: more on surfaces that face down.")},
               {"parts", withDoc(strs, "Only these parts get this wear; leave it out for all.")}})}});
    Json decal = Json::object(
        {{"type", "object"},
         {"additionalProperties", false},
         {"required", Json::array({"image", "position", "size"})},
         {"description",
          "A picture projected on the model along the opposite of `normal`, painted into the texture where it lands. "
          "Transparent pixels of the image stay transparent. All decals are composited into one layer."},
         {"properties",
          Json::object(
              {{"name", num("string", "A label for the report.")},
               {"image",
                num("string",
                    "A project png/jpg: assets.generate_texture output, or the baked png of an image document.")},
               {"parts", withDoc(strs, "Only these parts get the decal; leave it out for any.")},
               {"faces",
                Json::object({{"$ref", "#/$defs/face_selection"},
                              {"description", "Only the faces this selection query chooses (the model as built)."}})},
               {"position", num("array", "[x, y, z] in model space: the centre of the decal.")},
               {"normal", Json::object({{"description", "The way the surface it sits on faces: [x, y, z] or top, "
                                                        "bottom, front, back, left, right. Default front (+Z)."},
                                        {"oneOf", Json::array({Json::object({{"type", "string"}}),
                                                               Json::object({{"type", "array"}})})}})},
               {"size", Json::object({{"description", "Metres: [width, height], or one number for a square."},
                                      {"oneOf", Json::array({Json::object({{"type", "number"}}),
                                                             Json::object({{"type", "array"}})})}})},
               {"depth", bounded("number", 0, 1000,
                                 "Metres the projection reaches from the plane through `position`, each way along the "
                                 "normal. 0 (default): the smaller side of the decal.")},
               {"rotation", bounded("number", -360, 360, "Degrees around the normal.")},
               {"opacity", bounded("number", 0, 1, "Default 1.")},
               {"tint", withDoc(colorProp, "Multiplies the image.")},
               {"maxAngle",
                bounded("number", 1, 179,
                        "Degrees: surfaces turned more than this away from `normal` are left alone. Default 75.")}})}});
    Json maps = Json::object(
        {{"type", "object"},
         {"additionalProperties", false},
         {"description", "How the occlusion, curvature and thickness maps are measured."},
         {"properties",
          Json::object(
              {{"samples", bounded("integer", 4, kModelTextureMaxSamples,
                                   "Rays per texel for occlusion and thickness. Default 16.")},
               {"distance", bounded("number", 0, 10000,
                                    "Metres an occluder may be away. Default (0): 15% of the model's diagonal.")},
               {"thicknessDistance",
                bounded("number", 0, 10000,
                        "Metres the thickness is measured up to. Default (0): 50% of the diagonal.")},
               {"edgeAngle",
                bounded("number", 1, 179, "Degrees an edge must turn the surface to count as sharp. Default 20.")},
               {"edgeWidth", bounded("number", 0, 10000,
                                     "Metres wide the band along a sharp edge is. Default (0): 3% of the diagonal.")},
               {"write",
                Json::object({{"type", "array"},
                              {"items", Json::object({{"type", "string"},
                                                      {"enum", Json::array({"ao", "curvature", "thickness"})}})},
                              {"description",
                               "Maps also written as grey pictures next to the model (<name>.ao.png ...)."}})}})}});
    return Json::object(
        {{"type", "object"},
         {"additionalProperties", false},
         {"description",
          "Bakes the model's texture into its uv atlas (needs a `uv` section with layout \"atlas\"): materials with a "
          "`texture` projected triplanar, vertex colours, ambient occlusion, wear from baked maps, decals. "
          "The layers are written as an image document (`*.image.json`) you can paint on; a re-bake renews its own "
          "layers and keeps yours. docs/MODELING.md, \"Texturing\"; `model.texture` edits and bakes it."},
         {"properties",
          Json::object(
              {{"size",
                Json::object({{"type", "integer"},
                              {"minimum", 0},
                              {"maximum", kModelTextureMaxSize},
                              {"default", 0},
                              {"description", "Side of the texture in texels. 0: the size the uvs were made for."}})},
               {"bleed", bounded("integer", 0, kModelTextureMaxBleed,
                                 "Texels the colours are spread beyond each piece, against seams in mipmaps. Default: "
                                 "the uv padding.")},
               {"vertexColors",
                Json::object({{"type", "string"},
                              {"enum", Json::array({"bake", "keep"})},
                              {"default", "bake"},
                              {"description", "\"bake\": vertex colours are painted into the texture and left out of "
                                              "the .glb. \"keep\": they stay on the mesh and multiply the texture."}})},
               {"background", withDoc(colorProp, "The colour of the texels no triangle covers. Default mid grey.")},
               {"document",
                num("string",
                    "The layered image document the layers are written to (project path ending .image.json). Default "
                    "<model>.texture.image.json next to the model. Its baked png is the model's texture.")},
               {"ao",
                Json::object(
                    {{"description",
                      "true, or {strength, parts}: bake ambient occlusion and multiply it into the texture."},
                     {"oneOf",
                      Json::array(
                          {Json::object({{"type", "boolean"}}),
                           Json::object(
                               {{"type", "object"},
                                {"additionalProperties", false},
                                {"properties",
                                 Json::object(
                                     {{"strength", bounded("number", 0, 1,
                                                           "0 none .. 1 black in the deepest corner. Default 0.7.")},
                                      {"parts",
                                       withDoc(strs, "Only these parts are darkened; default all.")}})}})})}})},
               {"maps", maps},
               {"wear",
                Json::object(
                    {{"type", "array"}, {"items", wear}, {"description", "Wear painted from the baked maps."}})},
               {"decals",
                Json::object({{"type", "array"}, {"items", decal}, {"description", "Projected pictures."}})}})}});
}

}  // namespace fa
