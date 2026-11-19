// The material file: checks with JSON-pointer errors, the platform/dialect table, the list of materials of a project.
#include <algorithm>
#include <filesystem>
#include <set>

#include "fa/core/strings.h"
#include "fa/tooling/material_graph.h"
#include "fa/tooling/shaders.h"
#include "shaders_internal.h"
#include "util.h"

namespace fa {

namespace stdfs = std::filesystem;
using shaders_detail::is_identifier;
using shaders_detail::is_reserved_word;
using shaders_detail::template_globals;
using tooling_detail::escape_token;

int MaterialParam::components() const {
    if (type == "float") return 1;
    if (type == "vec2") return 2;
    if (type == "vec3") return 3;
    return 4;
}

InstanceLayout instance_layout(const std::vector<MaterialParam>& params) {
    InstanceLayout out;
    std::vector<int> used;  // floats taken in each vec4
    for (const MaterialParam& p : params) {
        if (!p.instanced) continue;
        const int n = p.components();
        size_t v = 0;
        while (v < used.size() && used[v] + n > 4) ++v;
        if (v == used.size()) used.push_back(0);
        out.slots.push_back({p.name, int(v), used[v], n});
        used[v] += n;
    }
    out.vec4Count = int(used.size());
    return out;
}

const std::vector<std::string>& material_vertex_attribute_names() {
    static const std::vector<std::string> names = {"color1", "uv1"};
    return names;
}

std::string MaterialIssue::to_string() const {
    std::string out = pointer.empty() ? message : pointer + ": " + message;
    if (!hint.empty()) out += " (hint: " + hint + ")";
    return out;
}

namespace {

const std::vector<std::string> kLightings = {"pbr", "unlit", "custom"};
const std::vector<std::string> kAlphaModes = {"opaque", "clip", "blend"};
const std::vector<std::string> kParamTypes = {"float", "vec2", "vec3", "vec4", "color"};
const std::vector<std::string> kSamplers = {"linear", "linearRepeat", "nearest", "nearestRepeat"};

// "Did you mean 'folder/x.png'?" for a project-relative file that is missing: the closest name in its folder, else `fallback`.
std::string sibling_hint(const std::string& projectDir, const std::string& rel, const std::string& fallback) {
    std::error_code ec;
    const stdfs::path parent = (stdfs::path(projectDir) / rel).parent_path();
    if (!stdfs::is_directory(parent, ec)) return fallback;
    std::vector<std::string> names;
    for (const auto& e : stdfs::directory_iterator(parent, ec))
        if (e.is_regular_file(ec)) names.push_back(e.path().filename().string());
    const std::string match = closest_match(stdfs::path(rel).filename().string(), names);
    return match.empty() ? fallback
                         : "Did you mean '" + (stdfs::path(rel).parent_path() / match).generic_string() + "'?";
}

std::string shorten(std::string s) {
    if (s.size() > 60) s = s.substr(0, 57) + "...";
    return s;
}

struct Checker {
    MaterialParse out;
    const std::string& projectDir;

    void error(std::string pointer, std::string message, std::string hint = {}) {
        out.errors.push_back({std::move(pointer), std::move(message), std::move(hint)});
    }

    // The member `key` of `obj` as a string; error (and false) when it has another type.
    bool read_string(const Json& obj, const std::string& base, const char* key, std::string& value) {
        auto it = obj.find(key);
        if (it == obj.end()) return false;
        if (!it->is_string()) {
            error(base + "/" + key, std::string("expected a string, got ") + describe_json_value(*it),
                  std::string("Write \"") + key + "\": \"...\".");
            return false;
        }
        value = it->get<std::string>();
        return true;
    }

    // An enum member: `value` keeps its default when absent or wrong.
    void read_enum(const Json& obj, const std::string& base, const char* key, const std::vector<std::string>& allowed,
                   std::string& value) {
        auto it = obj.find(key);
        if (it == obj.end()) return;
        if (!it->is_string() || std::find(allowed.begin(), allowed.end(), it->get<std::string>()) == allowed.end()) {
            const std::string got = it->is_string() ? "\"" + it->get<std::string>() + "\"" : describe_json_value(*it);
            error(base + "/" + key, std::string("unknown ") + key + " " + got,
                  it->is_string() ? did_you_mean(it->get<std::string>(), allowed)
                                  : "Use one of: " + join(allowed, ", ") + ".");
            return;
        }
        value = it->get<std::string>();
    }

    // The rule for names of params and textures; true when `name` is fine.
    bool check_name(const std::string& pointer, const std::string& name, const char* what, const std::string& kind) {
        if (!is_identifier(name)) {
            error(pointer,
                  std::string(what) + " name \"" + name +
                      "\" is not a GLSL identifier: it becomes a variable of your snippet, so it may use letters, "
                      "digits and _, and not start with a digit",
                  "Rename it, e.g. \"waveHeight\".");
            return false;
        }
        if (name.rfind("fa_", 0) == 0 || name.rfind("FA_", 0) == 0) {
            error(pointer,
                  std::string(what) + " name \"" + name +
                      "\" starts with fa_, which is reserved for the engine's own names",
                  "Rename it without the prefix, e.g. \"" +
                      (name.size() > 3 ? name.substr(3) : std::string("waveHeight")) + "\".");
            return false;
        }
        if (name.rfind("gl_", 0) == 0 || name.find("__") != std::string::npos) {
            error(pointer,
                  std::string(what) + " name \"" + name + "\" is reserved by GLSL (gl_ prefix or a double underscore)",
                  "Rename it, e.g. \"waveHeight\".");
            return false;
        }
        if (name == "noise") {
            error(pointer,
                  std::string(what) +
                      " name \"noise\" breaks sokol-shdc (it reports \"no binding found for texture ''\"), "
                      "so no material can use it",
                  "Name it for what it holds, e.g. \"noiseMap\" or \"mask\".");
            return false;
        }
        if (is_reserved_word(name) || (out.material.lighting == "custom" && (name == "light" || name == "ambient")) ||
            (kind == "sky" && name == "sky") ||    // sky(): the hook of a sky material, an ordinary name elsewhere
            (kind == "post" && name == "post")) {  // post(): the hook of a post material
            error(pointer,
                  std::string(what) + " name \"" + name +
                      "\" is a GLSL keyword or a name of the snippet contract, so it cannot be a variable",
                  "Rename it, e.g. \"" + name + "Value\".");
            return false;
        }
        // The unprefixed names of the kind's own program (sprite, sky: its vertex inputs, varyings, textures, uniform blocks and
        // helpers) share one flat namespace with the snippet and the params: taking one redefines it.
        const auto& globals = template_globals(kind);
        const std::string sampler = std::string(what) == "texture" ? name + "_smp" : std::string();
        const bool takesName = globals.count(name) > 0, takesSampler = !sampler.empty() && globals.count(sampler) > 0;
        if (takesName || takesSampler) {
            const std::string suffix = std::string(what) == "texture" ? "Map" : "Value";
            error(pointer,
                  std::string(what) + " name \"" + name + "\" is " +
                      (takesName ? "a name" : "the base of the name \"" + sampler + "\"") +
                      (kind == "sky"
                           ? " of the engine's sky program (sky_common.glsl: its vertex input, varying, uniform "
                             "blocks and helper functions are not prefixed)"
                           : " of the engine's 2D program (quad_common.glsl: its vertex inputs, varyings, textures, "
                             "uniform blocks and helper functions are not prefixed)") +
                      ", and a " + what + " becomes a global variable next to them, so " + kind +
                      " materials cannot take it",
                  "Rename it, e.g. \"" + name + suffix +
                      (kind == "sky"
                           ? "\". The names of the sky program are listed in "
                             "engine/render/shaders/sky_common.glsl and color_space.glsl."
                           : "\". The names of the 2D program are listed in "
                             "engine/render/shaders/quad_common.glsl and color_space.glsl / light_shadow.glsl."));
            return false;
        }
        return true;
    }

    void check_param(const std::string& name, const Json& p, MaterialParam& param) {
        const std::string base = "/params/" + escape_token(name);
        param.name = name;
        if (!p.is_object()) {
            error(base, "expected an object, got " + describe_json_value(p),
                  "Write \"" + name + "\": {\"type\": \"float\", \"default\": 0.5, \"doc\": \"What it does.\"}.");
            return;
        }
        for (auto it = p.begin(); it != p.end(); ++it) {
            static const std::vector<std::string> known = {"type", "default", "min", "max", "doc", "instanced"};
            if (std::find(known.begin(), known.end(), it.key()) == known.end())
                error(base + "/" + escape_token(it.key()), "unknown key \"" + it.key() + "\"",
                      did_you_mean(it.key(), known));
        }
        if (auto in = p.find("instanced"); in != p.end()) {
            if (!in->is_boolean())
                error(base + "/instanced", "expected true or false, got " + describe_json_value(*in),
                      "Write \"instanced\": true to give every entity its own value inside one instanced draw, or "
                      "leave the key out.");
            else
                param.instanced = in->get<bool>();
        }
        // doc
        if (auto d = p.find("doc"); d == p.end())
            error(base + "/doc", "missing \"doc\"",
                  "Every parameter needs a doc string saying what it does and its unit: AIs read it through "
                  "material.info.");
        else if (!d->is_string() || trim(d->get<std::string>()).empty())
            error(base + "/doc", "\"doc\" must be a non-empty string, got " + describe_json_value(*d),
                  "Say what the parameter does and its unit.");
        else
            param.doc = d->get<std::string>();
        // type
        bool typeOk = false;
        if (auto t = p.find("type"); t == p.end())
            error(base + "/type", "missing \"type\"", "Use one of: " + join(kParamTypes, ", ") + ".");
        else if (!t->is_string() ||
                 std::find(kParamTypes.begin(), kParamTypes.end(), t->get<std::string>()) == kParamTypes.end())
            error(base + "/type",
                  "unknown param type " +
                      (t->is_string() ? "\"" + t->get<std::string>() + "\"" : describe_json_value(*t)),
                  t->is_string() ? did_you_mean(t->get<std::string>(), kParamTypes)
                                 : "Use one of: " + join(kParamTypes, ", ") + ".");
        else {
            param.type = t->get<std::string>();
            typeOk = true;
        }
        // min / max
        for (const char* key : {"min", "max"}) {
            auto m = p.find(key);
            if (m == p.end()) continue;
            if (!m->is_number()) {
                error(base + "/" + key, std::string("expected a number, got ") + describe_json_value(*m),
                      std::string("Write \"") + key + "\": 0.0.");
                continue;
            }
            (std::string(key) == "min" ? param.min : param.max) = m->get<double>();
        }
        if (param.min && param.max && *param.min > *param.max)
            error(base + "/min", "min " + dump_number(*param.min) + " is greater than max " + dump_number(*param.max),
                  "Swap them, or fix the range.");
        // default
        auto d = p.find("default");
        if (d == p.end()) {
            error(base + "/default", "missing \"default\"",
                  typeOk ? "Write a default of type " + param.type + ", e.g. " + example_default(param.type) + "."
                         : "Give the param a default value.");
            return;
        }
        param.defaultValue = *d;
        if (!typeOk) return;
        const int n = param.components();
        std::vector<double> values;
        bool shapeOk = true;
        if (n == 1) {
            if (!d->is_number()) {
                error(base + "/default",
                      "expected a number, got " +
                          shorten(d->is_string() ? "\"" + d->get<std::string>() + "\"" : describe_json_value(*d)),
                      "A float param's default is a plain number, e.g. 0.5.");
                shapeOk = false;
            } else
                values.push_back(d->get<double>());
        } else {
            if (!d->is_array()) {
                error(base + "/default",
                      "expected an array of " + std::to_string(n) + " numbers for type " + param.type + ", got " +
                          shorten(describe_json_value(*d)),
                      "Write it like " + example_default(param.type) + ".");
                shapeOk = false;
            } else if (int(d->size()) != n) {
                error(base + "/default",
                      "type " + param.type + " needs " + std::to_string(n) + " numbers, the default has " +
                          std::to_string(d->size()),
                      "Write it like " + example_default(param.type) + ", or change \"type\".");
                shapeOk = false;
            } else {
                for (std::size_t i = 0; i < d->size(); ++i) {
                    if (!(*d)[i].is_number()) {
                        error(base + "/default/" + std::to_string(i),
                              "expected a number, got " + describe_json_value((*d)[i]),
                              "Every component is a plain number.");
                        shapeOk = false;
                    } else
                        values.push_back((*d)[i].get<double>());
                }
            }
        }
        if (!shapeOk) return;
        for (std::size_t i = 0; i < values.size(); ++i) {
            const std::string where = n == 1 ? base + "/default" : base + "/default/" + std::to_string(i);
            if (param.min && values[i] < *param.min)
                error(where, "default " + dump_number(values[i]) + " is below min " + dump_number(*param.min),
                      "Raise the default or lower \"min\".");
            else if (param.max && values[i] > *param.max)
                error(where, "default " + dump_number(values[i]) + " is above max " + dump_number(*param.max),
                      "Lower the default or raise \"max\".");
        }
    }

    static std::string dump_number(double v) {
        Json j = v;
        return j.dump();
    }

    static std::string example_default(const std::string& type) {
        if (type == "float") return "0.5";
        if (type == "vec2") return "[0.0, 1.0]";
        if (type == "vec3") return "[0.0, 1.0, 0.0]";
        return "[1.0, 1.0, 1.0, 1.0]";
    }

    void check_texture(const std::string& name, const Json& t, MaterialTexture& tex) {
        const std::string base = "/textures/" + escape_token(name);
        tex.name = name;
        tex.sampler = "linear";
        if (!t.is_object()) {
            error(base, "expected an object, got " + describe_json_value(t),
                  "Write \"" + name +
                      "\": {\"default\": \"textures/x.png\", \"sampler\": \"linear\", \"doc\": \"What it holds.\"}.");
            return;
        }
        static const std::vector<std::string> known = {"default", "sampler", "doc"};
        for (auto it = t.begin(); it != t.end(); ++it)
            if (std::find(known.begin(), known.end(), it.key()) == known.end())
                error(base + "/" + escape_token(it.key()), "unknown key \"" + it.key() + "\"",
                      did_you_mean(it.key(), known));
        if (auto d = t.find("doc"); d == t.end())
            error(base + "/doc", "missing \"doc\"",
                  "Every texture needs a doc string saying what it holds (channels, color space): AIs read it through "
                  "material.info.");
        else if (!d->is_string() || trim(d->get<std::string>()).empty())
            error(base + "/doc", "\"doc\" must be a non-empty string, got " + describe_json_value(*d),
                  "Say what the texture holds.");
        else
            tex.doc = d->get<std::string>();
        read_enum(t, base, "sampler", kSamplers, tex.sampler);
        if (auto d = t.find("default"); d != t.end()) {
            if (!d->is_string()) {
                error(base + "/default", "expected a texture path, got " + describe_json_value(*d),
                      "Write a project-relative path such as \"textures/water_normal.png\".");
            } else {
                tex.defaultPath = d->get<std::string>();
                if (!tex.defaultPath.empty() && !projectDir.empty() &&
                    !stdfs::exists(stdfs::path(projectDir) / tex.defaultPath)) {
                    error(base + "/default", "texture '" + tex.defaultPath + "' does not exist",
                          sibling_hint(projectDir, tex.defaultPath,
                                       "Create the file or fix the path (project-relative, forward slashes)."));
                }
            }
        }
    }

    // "graph" (the node graph the snippet is generated from, fa/tooling/material_graph.h) and "graphHash" (SHA-256 of the
    // snippet that was generated). The graph is checked after the params and textures it names are known.
    void read_graph(const Json& doc, MaterialDef& m) {
        if (auto h = doc.find("graphHash"); h != doc.end()) {
            if (!h->is_string() || h->get<std::string>().size() != 64)
                error("/graphHash",
                      "expected the 64 hex digits material.graph.generate wrote, got " + describe_json_value(*h),
                      "Do not write graphHash by hand: run material.graph.generate (or delete the key).");
            else
                m.graphHash = h->get<std::string>();
            if (!doc.contains("graph"))
                error("/graphHash", "\"graphHash\" without a \"graph\"",
                      "graphHash belongs to a generated snippet: delete it, or add the graph back.");
        }
        auto g = doc.find("graph");
        if (g == doc.end()) return;
        m.graph = *g;
        std::string kind = "mesh";
        if (auto k = doc.find("kind"); k != doc.end() && k->is_string()) kind = k->get<std::string>();
        for (MaterialIssue& e : check_material_graph(*g, m, kind).errors) out.errors.push_back(std::move(e));
    }

    void check_shader_path(const Json& doc, MaterialDef& m) {
        auto it = doc.find("shader");
        if (it == doc.end()) {
            error("/shader", "missing \"shader\"",
                  "Name the GLSL snippet that defines surface(), e.g. \"shaders/water.surface.glsl\".");
            return;
        }
        if (!it->is_string() || it->get<std::string>().empty()) {
            error("/shader", "expected a file path, got " + describe_json_value(*it),
                  "Write a project-relative path such as \"shaders/water.surface.glsl\".");
            return;
        }
        m.shader = it->get<std::string>();
        const stdfs::path rel(m.shader);
        if (rel.is_absolute() || m.shader[0] == '/' || m.shader.find('\\') != std::string::npos ||
            m.shader.rfind("../", 0) == 0 || m.shader.find("/../") != std::string::npos ||
            m.shader.rfind("./", 0) == 0) {
            error("/shader", "\"" + m.shader + "\" is not a path relative to the project root with forward slashes",
                  "Write it from the project root, e.g. \"shaders/water.surface.glsl\".");
            return;
        }
        // A material with a node graph has its snippet generated (material.graph.generate): it may not exist yet.
        if (projectDir.empty() || doc.contains("graph")) return;
        std::error_code ec;
        if (!stdfs::is_regular_file(stdfs::path(projectDir) / m.shader, ec)) {
            error("/shader", "snippet '" + m.shader + "' does not exist",
                  sibling_hint(
                      projectDir, m.shader,
                      m.kind == "compute"
                          ? "Create the file (a snippet defining void compute(in ComputeInput i)) or fix the path."
                          : "Create the file (a snippet defining void surface(in SurfaceInput i, inout Surface "
                            "s)) or fix the path."));
        }
    }
};

}  // namespace

MaterialParse parse_material(const Json& doc, const std::string& projectDir, const std::string& path) {
    Checker c{{}, projectDir};
    MaterialDef& m = c.out.material;
    m.path = path;
    if (!doc.is_object()) {
        c.error("", "expected an object, got " + describe_json_value(doc),
                "A material file is a JSON object: {\"format\": \"factoria.material/1\", \"shader\": "
                "\"shaders/x.surface.glsl\", ...}.");
        return std::move(c.out);
    }
    static const std::vector<std::string> topKeys = {
        "$schema", "format",   "doc",   "kind",      "shader",        "lighting", "alphaMode",       "doubleSided",
        "params",  "textures", "graph", "graphHash", "workgroupSize", "buffers",  "vertexAttributes"};
    for (auto it = doc.begin(); it != doc.end(); ++it)
        if (std::find(topKeys.begin(), topKeys.end(), it.key()) == topKeys.end())
            c.error("/" + escape_token(it.key()), "unknown key \"" + it.key() + "\"", did_you_mean(it.key(), topKeys));

    if (auto f = doc.find("format"); f == doc.end())
        c.error("/format", "missing \"format\"", std::string("Write \"format\": \"") + kMaterialFormat + "\".");
    else if (!f->is_string() || f->get<std::string>() != kMaterialFormat)
        c.error("/format",
                "unsupported format " +
                    (f->is_string() ? "\"" + f->get<std::string>() + "\"" : describe_json_value(*f)),
                std::string("Use \"") + kMaterialFormat + "\".");

    c.read_string(doc, "", "doc", m.doc);
    c.read_enum(doc, "", "kind", material_kind_names(), m.kind);
    c.check_shader_path(doc, m);
    c.read_enum(doc, "", "lighting", kLightings, m.lighting);
    c.read_enum(doc, "", "alphaMode", kAlphaModes, m.alphaMode);
    if (auto d = doc.find("doubleSided"); d != doc.end()) {
        if (!d->is_boolean())
            c.error("/doubleSided", "expected true or false, got " + describe_json_value(*d),
                    "Write \"doubleSided\": true.");
        else
            m.doubleSided = d->get<bool>();
    }

    std::set<std::string> taken;  // names of params and textures, and the _smp samplers
    if (auto p = doc.find("params"); p != doc.end()) {
        if (!p->is_object()) {
            c.error("/params", "expected an object, got " + describe_json_value(*p),
                    "Write \"params\": {\"name\": {\"type\": \"float\", \"default\": 1.0, \"doc\": \"...\"}}.");
        } else {
            for (auto it = p->begin(); it != p->end(); ++it) {
                MaterialParam param;
                const std::string ptr = "/params/" + escape_token(it.key());
                const bool nameOk = c.check_name(ptr, it.key(), "param", m.kind);
                c.check_param(it.key(), it.value(), param);
                if (nameOk) {
                    if (!taken.insert(it.key()).second)
                        c.error(ptr, "name \"" + it.key() + "\" is used twice",
                                "Param and texture names share one namespace.");
                    m.params.push_back(std::move(param));
                }
            }
        }
    }
    if (auto t = doc.find("textures"); t != doc.end()) {
        if (!t->is_object()) {
            c.error("/textures", "expected an object, got " + describe_json_value(*t),
                    "Write \"textures\": {\"name\": {\"default\": \"textures/x.png\", \"doc\": \"...\"}}.");
        } else {
            if (int(t->size()) > kMaterialMaxTextures)
                c.error("/textures",
                        std::to_string(t->size()) + " textures, at most " + std::to_string(kMaterialMaxTextures) +
                            " (the engine already binds " +
                            (m.kind == "sprite" ? "4"
                             : m.kind == "sky"  ? "0"
                             : m.kind == "post" ? "2"
                                                : "6") +
                            " texture units of the 16 that GLES3 and WebGL2 guarantee, and materials get the next 4)",
                        "Pack masks into the channels of one texture (r = foam, g = height...) or remove a texture.");
            for (auto it = t->begin(); it != t->end(); ++it) {
                MaterialTexture tex;
                const std::string ptr = "/textures/" + escape_token(it.key());
                const bool nameOk = c.check_name(ptr, it.key(), "texture", m.kind);
                c.check_texture(it.key(), it.value(), tex);
                if (nameOk) {
                    if (!taken.insert(it.key()).second)
                        c.error(ptr, "name \"" + it.key() + "\" is used twice",
                                "Param and texture names share one namespace.");
                    if (!taken.insert(it.key() + "_smp").second)
                        c.error(ptr, "the sampler \"" + it.key() + "_smp\" of this texture collides with another name",
                                "Rename the texture.");
                    m.textures.push_back(std::move(tex));
                }
            }
        }
    }

    // Kind "compute": workgroupSize and buffers (shaders_compute.cpp); on another kind they are errors.
    shaders_detail::parse_compute_fields(
        doc, m, c.out.errors, taken, [&c, &m](const std::string& pointer, const std::string& name, const char* what) {
            return c.check_name(pointer, name, what, m.kind);
        });

    // A post pass reads the picture and writes a picture: none of the keys of a surface that is drawn into the scene applies.
    if (m.kind == "post") {
        auto refuse = [&](const char* key, const std::string& why) {
            if (doc.contains(key))
                c.error(std::string("/") + key,
                        std::string("\"") + key + "\" does not apply to a post material: " + why,
                        std::string("Remove \"") + key +
                            "\" from the material. A post material is one full-screen pass of the post-processing "
                            "stack (PostProcess.customPasses); write post(in PostInput i, inout PostSurface s) and "
                            "read the picture with s.color or fa_scene_color(uv).");
        };
        refuse("lighting", "the pass is not lit, it reads the finished picture (use a mesh material for light())");
        refuse("alphaMode", "the pass replaces the colour of the pixels it covers, it has no alpha test or blending");
        refuse("doubleSided", "there is no geometry: the pass draws one full-screen triangle");
    }
    // alphaMode "clip": the cutoff is a param of the material, implicit unless declared (see the header).
    if (m.lighting == "custom" && m.kind == "sprite")
        c.error("/lighting",
                "lighting \"custom\" (the light() hook) is for mesh materials; the 2D pipeline lights sprites itself",
                "Remove \"lighting\" (a sprite ignores \"pbr\" and \"unlit\") and change what the lights give in "
                "fragment(), "
                "or use a mesh material (kind \"mesh\") for a custom light loop.");
    if (m.lighting == "custom" && m.kind == "sky")
        c.error(
            "/lighting", "lighting \"custom\" (the light() hook) is for mesh materials; a sky is not lit",
            "Remove \"lighting\" (a sky ignores \"pbr\" and \"unlit\"): sky() computes the colour of the background "
            "itself, from the view direction.");
    if ((m.alphaMode == "clip" || m.alphaMode == "blend") && m.kind == "sky")
        c.error(
            "/alphaMode",
            "alphaMode \"" + m.alphaMode + "\" means nothing for a sky material: the sky is the opaque background",
            "Remove \"alphaMode\" (a sky is always opaque; its sky() returns an RGB colour). doubleSided is ignored.");
    else if (m.alphaMode == "clip" && m.kind == "sprite") {
        c.error("/alphaMode", "alphaMode \"clip\" is the mesh template's alpha test; a sprite material has none",
                "Use \"blend\" (the default look of a sprite) and write `if (s.color.a < 0.5) discard;` in fragment() "
                "where "
                "you want a cut-out.");
    } else if (m.alphaMode == "clip" && m.kind != "post") {
        auto declared = std::find_if(m.params.begin(), m.params.end(),
                                     [](const MaterialParam& p) { return p.name == kMaterialAlphaCutoff; });
        if (declared == m.params.end()) {
            MaterialParam cutoff;
            cutoff.name = kMaterialAlphaCutoff;
            cutoff.type = "float";
            cutoff.defaultValue = 0.5;
            cutoff.min = 0.0;
            cutoff.max = 1.0;
            cutoff.doc =
                "Fragments whose alpha is below this are discarded (alphaMode \"clip\"; also in the shadow pass).";
            cutoff.implicit = true;
            m.params.push_back(std::move(cutoff));
        } else if (declared->type != "float") {
            c.error("/params/" + std::string(kMaterialAlphaCutoff) + "/type",
                    "alphaMode \"clip\" reads the float param alphaCutoff, but it is declared as " + declared->type,
                    "Declare it as \"type\": \"float\", or remove it to get the default (0.5, range 0..1).");
        }
    }
    const int blockParams =
        int(std::count_if(m.params.begin(), m.params.end(), [](const MaterialParam& p) { return !p.instanced; }));
    if (blockParams > kMaterialMaxParams) {
        bool implicit =
            std::any_of(m.params.begin(), m.params.end(), [](const MaterialParam& p) { return p.implicit; });
        c.error("/params",
                std::to_string(blockParams) + " params" +
                    (implicit ? " (including the implicit alphaCutoff of alphaMode \"clip\")" : "") + ", at most " +
                    std::to_string(kMaterialMaxParams) + " (each is padded to a vec4 of the 256-byte uniform block)",
                "Merge related floats into vec2, vec3 or vec4 params, or drop the ones the snippet does not need.");
    }
    std::sort(m.params.begin(), m.params.end(),
              [](const MaterialParam& a, const MaterialParam& b) { return a.name < b.name; });
    std::sort(m.textures.begin(), m.textures.end(),
              [](const MaterialTexture& a, const MaterialTexture& b) { return a.name < b.name; });
    // The instance buffer exists in the mesh pipeline (a value per entity) and the 2D quad pipeline (a value per quad); the extra
    // mesh channels only in the mesh pipeline. In any other kind the snippet would silently read 0, so the file is refused.
    const bool instancing = m.kind == "mesh" || m.kind == "sprite";
    if (!instancing) {
        for (const MaterialParam& p : m.params)
            if (p.instanced)
                c.error("/params/" + escape_token(p.name) + "/instanced",
                        "only mesh and sprite materials support instanced params, and this material is kind \"" +
                            m.kind + "\"",
                        "Remove \"instanced\" from this param (a " + m.kind +
                            " material gets one value per draw from its params), or change \"kind\" to \"mesh\" or "
                            "\"sprite\".");
    }
    if (m.kind != "mesh" && doc.contains("vertexAttributes"))
        c.error("/vertexAttributes",
                "only mesh materials support vertexAttributes, and this material is kind \"" + m.kind + "\"",
                "Remove \"vertexAttributes\": only a mesh has the uv1 and color1 channels a material can read.");
    if (const InstanceLayout layout = instance_layout(m.params);
        instancing && layout.vec4Count > kMaterialMaxInstanceVec4) {
        std::string names;
        for (const MaterialParam& p : m.params)
            if (p.instanced) names += (names.empty() ? "" : ", ") + p.name + " (" + p.type + ")";
        c.error("/params",
                "the instanced params need " + std::to_string(layout.vec4Count) + " vec4 per instance, at most " +
                    std::to_string(kMaterialMaxInstanceVec4) + " (12 floats): " + names,
                std::string("Make some of them not instanced (") + (m.kind == "sprite" ? "sprites" : "entities") +
                    " with different values then split the batch), or use fewer components: floats and small vectors "
                    "share a vec4 (a vec3 and a float fit in one), a vec4 takes a whole one.");
    }
    if (auto v = doc.find("vertexAttributes"); v != doc.end() && m.kind == "mesh") {
        const auto& names = material_vertex_attribute_names();
        if (!v->is_array()) {
            c.error("/vertexAttributes", "expected an array of names, got " + describe_json_value(*v),
                    "Write \"vertexAttributes\": [\"uv1\"]; the names are " + join(names, ", ") + ".");
        } else {
            for (size_t i = 0; i < v->size(); ++i) {
                const std::string ptr = "/vertexAttributes/" + std::to_string(i);
                const Json& e = (*v)[i];
                if (!e.is_string()) {
                    c.error(ptr, "expected a name, got " + describe_json_value(e),
                            "Use one of: " + join(names, ", ") + ".");
                    continue;
                }
                const std::string name = e.get<std::string>();
                if (std::find(names.begin(), names.end(), name) == names.end())
                    c.error(ptr, "unknown vertex attribute \"" + name + "\"",
                            did_you_mean(name, names) +
                                " The mesh channels beyond position, normal, uv, tangent and color a material can read "
                                "are uv1 (glTF TEXCOORD_1) and color1 (glTF COLOR_1).");
                else if (std::find(m.vertexAttributes.begin(), m.vertexAttributes.end(), name) !=
                         m.vertexAttributes.end())
                    c.error(ptr, "\"" + name + "\" is listed twice", "Remove the duplicate.");
                else
                    m.vertexAttributes.push_back(name);
            }
        }
        std::sort(m.vertexAttributes.begin(), m.vertexAttributes.end());
    }
    c.read_graph(doc, m);
    return std::move(c.out);
}

MaterialParse read_material(const std::string& projectDir, const std::string& path) {
    const stdfs::path full = stdfs::path(projectDir) / path;
    auto text = tooling_detail::read_file(full);
    if (!text) {
        MaterialParse out;
        out.material.path = path;
        out.errors.push_back(
            {"", "cannot read material '" + path + "'",
             sibling_hint(projectDir, path, "Check the path (project-relative); `fs.search` finds *.material.json.")});
        return out;
    }
    auto parsed = parse_json(*text, path);
    if (!parsed.ok()) {
        MaterialParse out;
        out.material.path = path;
        out.errors.push_back(
            {"", parsed.error().message, parsed.error().hint.empty() ? "Fix the JSON syntax." : parsed.error().hint});
        return out;
    }
    return parse_material(parsed.value(), projectDir, path);
}

std::vector<std::string> find_material_files(const std::string& projectDir) {
    std::vector<std::string> out;
    std::error_code ec;
    const stdfs::path root(projectDir);
    if (!stdfs::is_directory(root, ec)) return out;
    for (stdfs::recursive_directory_iterator it(root, ec), end; !ec && it != end; it.increment(ec)) {
        const std::string name = it->path().filename().string();
        if (it->is_directory(ec)) {
            if ((!name.empty() && name[0] == '.') || name == "node_modules" ||
                (name == "build" && it->path().parent_path() == root))
                it.disable_recursion_pending();
            continue;
        }
        if (it->is_regular_file(ec) && ends_with(name, ".material.json"))
            out.push_back(stdfs::relative(it->path(), root, ec).generic_string());
    }
    std::sort(out.begin(), out.end());
    return out;
}

// ---------------------------------------------------------------------------------------------------------------
// Platforms and dialects
// ---------------------------------------------------------------------------------------------------------------

const std::vector<std::string>& shader_platforms() {
    static const std::vector<std::string> v = {"windows", "linux", "macos", "ios", "android", "web"};
    return v;
}

const std::vector<std::string>& shader_dialects() {
    static const std::vector<std::string> v = {"hlsl5",       "glsl430",   "glsl300es",
                                               "metal_macos", "metal_ios", "metal_sim"};
    return v;
}

Result<std::vector<std::string>> shader_dialects_for(const std::vector<std::string>& platforms) {
    if (platforms.empty()) return shader_dialects();
    std::set<std::string> wanted;
    for (const std::string& p : platforms) {
        if (p == "windows")
            wanted.insert("hlsl5");
        else if (p == "linux")
            wanted.insert("glsl430");
        else if (p == "macos")
            wanted.insert("metal_macos");
        else if (p == "ios") {
            wanted.insert("metal_ios");
            wanted.insert("metal_sim");
        } else if (p == "android" || p == "web")
            wanted.insert("glsl300es");
        else
            return make_error("unknown platform '" + p + "'", did_you_mean(p, shader_platforms()));
    }
    std::vector<std::string> out;
    for (const std::string& d : shader_dialects())
        if (wanted.count(d)) out.push_back(d);
    return out;
}

std::string host_shader_dialect(const SetupContext& context) {
    const std::string os = context.host_os();
    if (os == "windows") return "hlsl5";
    if (os == "macos") return "metal_macos";
    return "glsl430";
}

}  // namespace fa
