// Running sokol-shdc for a material: the cache, the error mapping back to the author's snippet (with hints for the frequent
// mistakes), and the twin documents (docs/design/CUSTOM_SHADERS.md, "How it is compiled" and "Errors that teach").
#include "fa/core/engine_version.h"
#include <algorithm>
#include <cctype>
#include <filesystem>
#include <regex>
#include <set>

#include "fa/core/fs.h"
#include "fa/core/hash.h"
#include "fa/core/strings.h"
#include "fa/render/renderer.h"
#include "fa/tooling/shaders.h"
#include "shaders_internal.h"
#include "util.h"

namespace fa {

namespace stdfs = std::filesystem;
using namespace shaders_detail;

// ---------------------------------------------------------------------------------------------------------------
// Issues
// ---------------------------------------------------------------------------------------------------------------

Json ShaderIssue::to_json() const {
    Json j = Json::object({{"file", file}, {"line", line}, {"column", column}, {"message", message}, {"hint", hint}});
    if (!pointer.empty()) j["pointer"] = pointer;
    if (!source.empty()) j["source"] = source;
    return j;
}

std::string ShaderIssue::to_string() const {
    std::string out = file;
    if (line > 0)
        out += ":" + std::to_string(line) + ":" + std::to_string(std::max(column, 1));
    else if (!pointer.empty())
        out += "#" + pointer;
    out += ": error: " + message;
    if (!source.empty() && line > 0) {
        const std::string num = std::to_string(line);
        out += "\n  " + num + " | " + source + "\n  " + std::string(num.size(), ' ') + " | " +
               std::string(std::size_t(std::max(column, 1) - 1), ' ') + "^";
    }
    if (!hint.empty()) out += "\n  hint: " + hint;
    return out;
}

// ---------------------------------------------------------------------------------------------------------------
// The cache
// ---------------------------------------------------------------------------------------------------------------

std::string shader_template_hash(const std::string& kind) {
    if (kind == "mesh-full") return template_files(kind).empty() ? std::string() : mesh_full_template_hash();
    // The renderer's own value (computed by CMake from the template files of the kind, embedded here), so a twin's "template"
    // is what the player that loads it checks.
    const auto parsed = material_kind_from_name(kind);
    return !parsed || template_files(kind).empty() ? std::string() : material_template_hash(*parsed);
}

std::string shader_cache_path(const std::string& projectDir, const GeneratedShader& generated, std::string_view snippet,
                              const std::string& slang) {
    std::string key = generated.top;
    const std::string templateHash = shader_template_hash(generated.kind);
    for (std::string_view part : {snippet, std::string_view(templateHash), std::string_view(slang),
                                  std::string_view(kSetupSokolShdcCommit), std::string_view(FA_ENGINE_VERSION)}) {
        key += '\x01';
        key += part;
    }
    for (const std::string& d : generated.defines) key += '\x01' + d;
    key += '\x01' + generated.stateKey;  // the twin fields that are not in the top file (a full material's passes)
    return (stdfs::path(projectDir) / ".factoria" / "shader-cache" / (sha256_hex(key) + "." + slang + ".shader"))
        .string();
}

namespace {

std::optional<Json> read_cached_twin(const std::string& path, const std::string& slang) {
    auto text = tooling_detail::read_file(path);
    if (!text) return std::nullopt;
    auto parsed = parse_json(*text, path);
    if (!parsed.ok() || !parsed->is_object() || parsed->value("format", std::string()) != kShaderTwinFormat ||
        parsed->value("slang", std::string()) != slang)
        return std::nullopt;
    return std::move(parsed.value());
}

void write_cached_twin(const std::string& path, const Json& twin) {
    const std::string tmp = path + ".tmp";
    if (!tooling_detail::write_file(tmp, twin.dump() + "\n")) return;  // a cache that cannot be written only costs time
    std::error_code ec;
    fs::replace_file(tmp, path, ec);
    if (ec) stdfs::remove(tmp, ec);
}

// ---------------------------------------------------------------------------------------------------------------
// Errors
// ---------------------------------------------------------------------------------------------------------------

struct Diagnostic {
    std::string file;
    int line = 0;
    std::string message;  // without "error: "
};

// "file:line:col: error: message" lines (gcc format; the column glslang writes is always 0).
std::vector<Diagnostic> parse_diagnostics(const std::string& text) {
    static const std::regex re(R"(^(.*?):(\d+):(\d+): (error|warning): (.*)$)");
    std::vector<Diagnostic> out;
    std::size_t start = 0;
    while (start < text.size()) {
        std::size_t nl = text.find('\n', start);
        std::string line = text.substr(start, nl == std::string::npos ? std::string::npos : nl - start);
        start = nl == std::string::npos ? text.size() : nl + 1;
        while (!line.empty() && (line.back() == '\r' || line.back() == ' ')) line.pop_back();
        std::smatch m;
        if (std::regex_match(line, m, re)) {
            if (m[4] == "error") out.push_back({m[1], std::stoi(m[2]), m[5]});
        } else if (line.find("error") != std::string::npos && !line.empty()) {
            out.push_back({"", 0, line});
        }
    }
    return out;
}

// The quoted token a glslang message starts with: `'colour' : no such field in structure 's'` -> colour.
std::string message_token(const std::string& message) {
    if (message.size() < 2 || message[0] != '\'') return {};
    const std::size_t end = message.find('\'', 1);
    return end == std::string::npos ? std::string() : message.substr(1, end - 1);
}

struct MapContext {
    const MaterialDef& material;
    const GeneratedShader& generated;
    const std::string& snippet;   // normalized
    const std::string& stripped;  // comment-blanked snippet
    const std::string& projectDir;
};

bool word_at(const std::string& s, std::size_t pos, const std::string& word) {
    if (s.compare(pos, word.size(), word) != 0) return false;
    return (pos == 0 || !ident_char(s[pos - 1])) && !(pos + word.size() < s.size() && ident_char(s[pos + word.size()]));
}

std::size_t find_word(const std::string& s, const std::string& word, bool afterDot = false) {
    if (word.empty()) return std::string::npos;
    for (std::size_t p = s.find(word); p != std::string::npos; p = s.find(word, p + 1))
        if (word_at(s, p, word) && (!afterDot || (p > 0 && s[p - 1] == '.'))) return p;
    return std::string::npos;
}

// The variable the signature of the kind names its struct by: SurfaceInput/QuadInput i, Surface/QuadSurface s, the vertex one v.
std::string struct_var(const std::string& typeName) {
    if (typeName == "LightSample") return "l";
    if (typeName.ends_with("Input")) return "i";
    if (typeName.ends_with("Surface")) return "s";
    return "v";
}

bool is_sprite(const MaterialDef& material) { return material.kind == "sprite"; }
bool is_sky(const MaterialDef& material) { return material.kind == "sky"; }
bool is_post(const MaterialDef& material) { return material.kind == "post"; }

// The structs of the contract this material uses: LightSample only with lighting "custom" (a pbr material has no light()).
std::vector<std::pair<std::string, std::vector<std::string>>> contract_of(const MaterialDef& material) {
    auto out = contract_structs(material.kind);
    // A full shader has no surface contract: the one struct it meets is the LightSample fa_light() returns.
    if (material.full)
        out.erase(std::remove_if(out.begin(), out.end(), [](const auto& e) { return e.first != "LightSample"; }),
                  out.end());
    else if (material.lighting != "custom")
        out.erase(std::remove_if(out.begin(), out.end(), [](const auto& e) { return e.first == "LightSample"; }),
                  out.end());
    return out;
}

const std::vector<std::string>*
struct_fields(const std::string& name, const std::vector<std::pair<std::string, std::vector<std::string>>>& structs) {
    for (const auto& [n, fields] : structs)
        if (n == name) return &fields;
    return nullptr;
}

std::string field_hint(const std::string& token, const std::string& source, const MapContext& ctx) {
    // Which struct? The variable before the dot, declared in the snippet as `Surface s`...
    std::string typeName;
    if (std::size_t dot = find_word(source, token, true); dot != std::string::npos) {
        std::size_t e = dot - 1;  // the dot
        while (e > 0 && std::isspace(static_cast<unsigned char>(source[e - 1]))) --e;
        std::size_t b = e;
        while (b > 0 && ident_char(source[b - 1])) --b;
        const std::string var = source.substr(b, e - b);
        if (!var.empty()) {
            // `Surface s`, `QuadInput i`, `LightSample l`...: the struct types of the kind's contract.
            std::string types;
            for (const auto& [n, f] : contract_structs(ctx.material.kind)) types += (types.empty() ? "" : "|") + n;
            const std::regex decl("\\b(" + types + ")\\s+(\\w+)");
            for (auto it = std::sregex_iterator(ctx.stripped.begin(), ctx.stripped.end(), decl);
                 it != std::sregex_iterator(); ++it)
                if ((*it)[2] == var) typeName = (*it)[1];
        }
    }
    if (is_post(ctx.material)) {
        // The depth and the normals are not fields of PostInput: reading them is what asks the renderer for the prepass.
        std::string flat;
        for (char c : to_lower(token))
            if (c != '_') flat += c;
        if (flat == "depth" || flat == "lineardepth" || flat == "zdepth" || flat == "viewdepth")
            return "PostInput has no depth: read it with fa_depth(i.uv), the linear view depth in world units (the "
                   "renderer then draws the depth and normal prepass for the camera).";
        if (flat == "normal" || flat == "normals" || flat == "viewnormal" || flat == "worldnormal")
            return "PostInput has no normal: read it with fa_normal(i.uv), the view-space normal (the renderer then "
                   "draws the depth and normal prepass for the camera).";
        if (flat == "color" || flat == "colour" || flat == "scene" || flat == "rgba")
            return "PostInput has no colour: the picture at this pixel arrives in s.color (inout PostSurface s), and "
                   "fa_scene_color(uv) reads it at any other uv.";
    }
    std::vector<std::string> fields;
    const auto structs = contract_of(ctx.material);
    std::string where = ctx.material.full                   ? "LightSample"
                        : is_post(ctx.material)             ? "PostSurface and PostInput"
                        : is_sprite(ctx.material)           ? "QuadSurface, QuadInput and QuadVertex"
                        : is_sky(ctx.material)              ? "SkySurface and SkyInput"
                        : ctx.material.lighting == "custom" ? "Surface, SurfaceInput, VertexData and LightSample"
                                                            : "Surface, SurfaceInput and VertexData";
    if (const auto* f = struct_fields(typeName, structs)) {
        fields = *f;
        where = typeName;
    } else {
        for (const auto& [n, f2] : structs)
            for (const std::string& name : f2)
                if (std::find(fields.begin(), fields.end(), name) == fields.end()) fields.push_back(name);
    }
    static const std::vector<std::pair<std::string, std::string>> aliases = {{"colour", "albedo"},
                                                                             {"color", "albedo"},
                                                                             {"diffuse", "albedo"},
                                                                             {"basecolor", "albedo"},
                                                                             {"base", "albedo"},
                                                                             {"opacity", "alpha"},
                                                                             {"transparency", "alpha"},
                                                                             {"emissive", "emission"},
                                                                             {"glow", "emission"},
                                                                             {"emit", "emission"},
                                                                             {"ao", "occlusion"},
                                                                             {"ambientocclusion", "occlusion"},
                                                                             {"rough", "roughness"},
                                                                             {"metal", "metallic"},
                                                                             {"metalness", "metallic"},
                                                                             {"normals", "normal"},
                                                                             {"normal", "world_normal"},
                                                                             {"position", "world_pos"},
                                                                             {"pos", "world_pos"},
                                                                             {"worldpos", "world_pos"},
                                                                             {"worldposition", "world_pos"},
                                                                             {"world_position", "world_pos"},
                                                                             {"texcoord", "uv"},
                                                                             {"texcoords", "uv"},
                                                                             {"uv0", "uv"},
                                                                             {"viewdir", "view_dir"},
                                                                             {"view", "view_dir"},
                                                                             {"tangent", "world_tangent"},
                                                                             {"worldnormal", "world_normal"},
                                                                             {"frontfacing", "front_facing"},
                                                                             {"isfrontface", "front_facing"},
                                                                             {"colour", "color"},
                                                                             {"rgba", "color"},
                                                                             {"tint", "color"},
                                                                             {"screenuv", "screen_uv"},
                                                                             {"screenuv", "uv"},
                                                                             {"coord", "uv"},
                                                                             {"fragcoord", "uv"},
                                                                             {"resolution", "size"},
                                                                             {"res", "size"},
                                                                             {"screensize", "size"},
                                                                             {"pixelsize", "texel"},
                                                                             {"texelsize", "texel"},
                                                                             {"invsize", "texel"},
                                                                             {"screenpos", "screen_uv"},
                                                                             {"screenposition", "screen_uv"},
                                                                             {"seconds", "time"},
                                                                             {"direction", "dir"},
                                                                             {"raydir", "dir"},
                                                                             {"viewdir", "dir"},
                                                                             {"viewdirection", "dir"},
                                                                             {"sun", "sun_dir"},
                                                                             {"sundir", "sun_dir"},
                                                                             {"sundirection", "sun_dir"},
                                                                             {"sunlight", "sun_dir"},
                                                                             {"lightdir", "sun_dir"}};
    std::string lower = to_lower(token), flat;
    for (char c : lower)
        if (c != '_') flat += c;
    std::string best;
    for (const auto& [alias, canonical] : aliases)
        if ((alias == lower || alias == flat) && std::find(fields.begin(), fields.end(), canonical) != fields.end()) {
            best = canonical;
            break;
        }
    if (best.empty()) best = closest_match(token, fields);
    return (best.empty() ? std::string() : "did you mean " + best + "? ") + where +
           " has the fields: " + join(fields, ", ") + ".";
}

// Names that other materials of the project declare (param or texture) -> the first material that does.
std::string declared_by_other_material(const std::string& name, const MapContext& ctx) {
    for (const std::string& rel : find_material_files(ctx.projectDir)) {
        if (rel == ctx.material.path) continue;
        auto text = tooling_detail::read_file(stdfs::path(ctx.projectDir) / rel);
        if (!text) continue;
        auto j = parse_json(*text, rel);
        if (!j.ok() || !j->is_object()) continue;
        for (const char* section : {"params", "textures"})
            if (j->contains(section) && (*j)[section].is_object() && (*j)[section].contains(name)) return rel;
    }
    return {};
}

// Every fa_ name the template files of the kind mention.
std::vector<std::string> engine_names_of(const std::string& kind) {
    std::set<std::string> found;
    static const std::regex re(R"(\bfa_\w+)");
    for (const auto& [file, content] : template_files(kind)) {
        const std::string text = blank_comments(content);
        for (auto it = std::sregex_iterator(text.begin(), text.end(), re); it != std::sregex_iterator(); ++it)
            found.insert(it->str());
    }
    return std::vector<std::string>(found.begin(), found.end());
}

const std::vector<std::string>& engine_names(const MaterialDef& material) {
    static const std::vector<std::string> mesh = engine_names_of("mesh"), sprite = engine_names_of("sprite"),
                                          sky = engine_names_of("sky"), post = engine_names_of("post"),
                                          full = engine_names_of("mesh-full");
    return material.full         ? full
           : is_post(material)   ? post
           : is_sprite(material) ? sprite
           : is_sky(material)    ? sky
                                 : mesh;
}

std::string prefix_rule(const MaterialDef& material) {
    if (material.full)
        return "Names starting with fa_ or FA_ belong to the engine: a full shader may use the ones "
               "docs/shaders/SHADERS_FULL.md lists "
               "(fa_view_proj, fa_world_position(), fa_light(), FA_TIME...) but not declare any. Rename it without the "
               "prefix.";
    if (is_post(material))
        return "Names starting with fa_ belong to the engine: the snippet may use the ones the contract lists "
               "(fa_scene_color(), fa_depth(), fa_normal(), fa_time) but not declare any. Rename it without the "
               "prefix.";
    if (is_sky(material))
        return "Names starting with fa_ belong to the engine: the snippet may use the ones the contract lists "
               "(fa_time, fa_scene_rgb()) but not declare any. Rename it without the prefix.";
    return is_sprite(material)
               ? "Names starting with fa_ belong to the engine: the snippet may use the ones the contract lists "
                 "(fa_time, fa_sample_main(), fa_scene_rgb()) but not declare any. Rename it without the prefix."
               : "Names starting with fa_ belong to the engine: the snippet may read the ones the contract lists "
                 "(fa_time, fa_camera_pos, fa_tangent_normal) but not declare any. Rename it without the prefix.";
}

constexpr const char* kLightSignatures =
    "void surface(in SurfaceInput i, inout Surface s) { ... }  (required),  void vertex(inout VertexData v) { ... }  "
    "(optional),  vec3 light(in SurfaceInput i, in Surface s, in LightSample l) { ... }  (required with \"lighting\": "
    "\"custom\")  and  vec3 ambient(in SurfaceInput i, in Surface s, vec3 ambientColor) { ... }  (optional)";

std::string signatures(const MaterialDef& material) {
    if (is_post(material))
        return "void post(in PostInput i, inout PostSurface s) { ... }  (required; a post material has no vertex())";
    if (is_sky(material))
        return "void sky(in SkyInput i, inout SkySurface s) { ... }  (required; a sky has no vertex())";
    if (is_sprite(material))
        return "void fragment(in QuadInput i, inout QuadSurface s) { ... }  (required)  and  void "
               "vertex(inout QuadVertex v) { ... }  (optional)";
    if (material.lighting == "custom") return kLightSignatures;
    return "void surface(in SurfaceInput i, inout Surface s) { ... }  (required)  and  void "
           "vertex(inout VertexData v) { ... }  (optional)";
}

// The entry point of the fragment stage the kind's contract names.
const char* fragment_entry(const MaterialDef& material) {
    return is_post(material) ? "post" : is_sprite(material) ? "fragment" : is_sky(material) ? "sky" : "surface";
}

std::string undeclared_hint(const std::string& token, const MapContext& ctx) {
    // A field written without its struct (a full shader has no snippet functions to put it in).
    const auto contract = ctx.material.full ? decltype(contract_of(ctx.material)){} : contract_of(ctx.material);
    for (const auto& [n, fields] : contract)
        if (std::find(fields.begin(), fields.end(), token) != fields.end())
            return "`" + token + "` is a field of " + n + ": write " + struct_var(n) + "." + token + " inside " +
                   (n == "VertexData" || n == "QuadVertex" ? "vertex"
                    : n == "LightSample"                   ? "light"
                                                           : fragment_entry(ctx.material)) +
                   "().";
    if (token.rfind("fa_", 0) == 0) {
        const std::string best = closest_match(token, engine_names(ctx.material));
        return best.empty()
                   ? std::string("No engine value is called ") + token +
                         (ctx.material.full
                              ? "; docs/shaders/SHADERS_FULL.md lists the ones a full shader may use (fa_view_proj, "
                                "fa_world_position(), fa_light(), fa_frag_color, FA_TIME...)."
                          : is_post(ctx.material)
                              ? "; the ones a snippet may use are fa_scene_color(uv), fa_depth(uv), fa_normal(uv) and "
                                "fa_time."
                          : is_sprite(ctx.material)
                              ? "; the ones a snippet may use are fa_time, fa_sample_main() and fa_scene_rgb()."
                          : is_sky(ctx.material)
                              ? "; the ones a snippet may use are fa_time and fa_scene_rgb()."
                              : "; the ones a snippet may read are fa_time, fa_camera_pos and fa_tangent_normal().")
                   : "did you mean " + best + "?";
    }
    if (is_post(ctx.material)) {
        // What authors bring from other engines' post-process shaders.
        std::string flat;
        for (char c : to_lower(token))
            if (c != '_') flat += c;
        auto is_one = [&](std::initializer_list<const char*> names) {
            return std::any_of(names.begin(), names.end(), [&](const char* n) { return flat == n; });
        };
        if (is_one({"scenecolor", "screentexture", "scenetexture", "maintex", "source", "inputtexture", "rendertexture",
                    "colortexture", "screencolor", "framebuffer", "scene", "sceneimage", "image", "ichannel0"}))
            return "`" + token +
                   "` is not declared: the picture is not a texture of the snippet. Read it with fa_scene_color(uv) "
                   "(linear colour, uv 0..1 with the origin top left); at the pixel being drawn it already is s.color.";
        if (is_one({"depthtexture", "depthmap", "zbuffer", "depthbuffer", "scenedepth", "cameradepthtexture",
                    "depthsample"}))
            return "`" + token +
                   "` is not declared: read the linear view depth in world units with fa_depth(uv); using it makes the "
                   "renderer draw the depth and normal prepass for the camera.";
        if (is_one({"normaltexture", "normalmap", "gbuffer", "scenenormal", "viewnormal", "normalbuffer"}))
            return "`" + token +
                   "` is not declared: read the view-space normal with fa_normal(uv); using it makes the renderer draw "
                   "the depth and normal prepass for the camera.";
        if (is_one(
                {"resolution", "screensize", "iresolution", "viewportsize", "texturesize", "screenres", "uresolution"}))
            return "`" + token +
                   "` is not declared: the size of the picture in pixels is i.size (and i.texel is one pixel in uv "
                   "units).";
        if (is_one({"itime", "utime", "time", "gametime", "globaltime", "elapsed"}))
            return "`" + token + "` is not declared: the seconds of game time are i.time (inside post()) or fa_time.x.";
        if (is_one({"fragcoord", "glfragcoord", "screenuv", "screenpos", "uv", "texcoord", "vuv"}))
            return "`" + token +
                   "` is not declared: the pixel is i.uv (0..1 over the picture, origin top left, y down on every "
                   "backend); in pixels it is i.uv * i.size.";
        if (is_one({"fragcolor", "glfragcolor", "outcolor", "outputcolor", "result", "fragment"}))
            return "`" + token +
                   "` is not declared: write the result into s.color (inout PostSurface s); the pass outputs it.";
    }
    std::vector<std::string> names;
    for (const MaterialParam& p : ctx.material.params) names.push_back(p.name);
    for (const MaterialTexture& t : ctx.material.textures) names.push_back(t.name);
    const std::string best = closest_match(token, names);
    if (!best.empty()) return "did you mean " + best + "? This material declares: " + join(names, ", ") + ".";
    if (const std::string other = declared_by_other_material(token, ctx); !other.empty())
        return "`" + token + "` is declared by " + other +
               ", not by this material. Add it to \"params\" or \"textures\" in " + ctx.material.path +
               " (each material declares its own).";
    return "Declare `" + token + "` in \"params\" (or \"textures\") of " + ctx.material.path +
           ", or declare it in the snippet." +
           (names.empty() ? std::string(" This material declares no params or textures.")
                          : " This material declares: " + join(names, ", ") + ".");
}

std::string hint_for(const std::string& message, const std::string& token, const std::string& source,
                     const MapContext& ctx) {
    if (message.find("no such field in structure") != std::string::npos) return field_hint(token, source, ctx);
    if (message.find("undeclared identifier") != std::string::npos) return undeclared_hint(token, ctx);
    if (message.find("no matching overloaded function found") != std::string::npos && token.rfind("texture", 0) == 0) {
        // texture(waves, uv) on a separate texture.
        for (const MaterialTexture& t : ctx.material.textures) {
            std::regex use(token + R"(\s*\(\s*)" + t.name + R"(\s*,)");
            if (std::regex_search(source, use))
                return "textures and samplers are separate: write " + token + "(sampler2D(" + t.name + ", " + t.name +
                       "_smp), uv) instead of " + token + "(" + t.name + ", uv).";
        }
        return "Texture lookups take a combined sampler built from the texture and its sampler: " + token +
               "(sampler2D(name, name_smp), uv), with a vec2 uv.";
    }
    if (message.find("redefinition") != std::string::npos && token.rfind("fa_", 0) == 0)
        return prefix_rule(ctx.material);
    if (message.find("redefinition") != std::string::npos) {
        for (const MaterialParam& p : ctx.material.params)
            if (p.name == token)
                return "`" + token + "` is already a global: it is a param of this material (declared in " +
                       ctx.material.path + "). Use it directly, or rename the local variable.";
        for (const MaterialTexture& t : ctx.material.textures)
            if (t.name == token || t.name + "_smp" == token)
                return "`" + token + "` is already declared by the texture \"" + t.name +
                       "\" of this material. Rename the local variable.";
        if (template_globals(ctx.material.kind).count(token) > 0)
            return "`" + token +
                   (is_sky(ctx.material)
                        ? "` is a name taken by the engine's sky program (sky_common.glsl and the files it includes: "
                          "its vertex input, varying, uniform blocks and helper functions are not prefixed). "
                        : "` is a name taken by the engine's 2D program (quad_common.glsl and the files it includes: "
                          "its vertex inputs, varyings, textures, uniform blocks and helper functions are not "
                          "prefixed). ") +
                   "Rename your variable or function.";
    }
    if (message.find("syntax error") != std::string::npos)
        return "A syntax error is often reported on the line after the real mistake: look for a missing ';', ')' or "
               "'}' just above.";
    if (message.find("cannot convert from") != std::string::npos)
        return "GLSL does not convert types by itself: write vec3(x) to widen a float, use .rgb or .xyz to narrow a "
               "vec4, and write float literals with a dot (1.0, not 1).";
    return {};
}

// What the author reads when the error is not in their snippet: the rule.
void outside_snippet(ShaderIssue& issue, const std::string& where, const std::string& token, const MapContext& ctx) {
    issue.message += " (" + where + ", which is the engine's code, not the snippet's)";
    issue.line = 0;
    issue.source.clear();
    issue.file = ctx.material.shader.empty() ? ctx.material.path : ctx.material.shader;
    if (ctx.material.full)
        issue.hint =
            "The engine builds the programs from the sections of the file (`@common`, `@vertex`, `@fragment`), each "
            "stage "
            "with its own `void main()`: the problem is in how the stages fit together, such as varyings that differ "
            "between "
            "the stages, a name starting with fa_ or FA_, or a resource the template does not declare in that stage. "
            "docs/shaders/SHADERS_FULL.md lists what a full shader may use.";
    else if (token == "surface" || token == "fragment" || token == "vertex" ||
             (token == "sky" && is_sky(ctx.material)) || (token == "post" && is_post(ctx.material)) ||
             (ctx.material.lighting == "custom" && (token == "light" || token == "ambient")))
        issue.hint = std::string("The engine calls ") + token +
                     "() from its template, so the snippet must define it with exactly this signature: " +
                     signatures(ctx.material) + ".";
    else if (ctx.material.kind == "compute")
        issue.hint =
            "A compute snippet defines `void compute(in ComputeInput i)` and reads its buffers as "
            "<buffer>.data[i]; do not declare names starting with fa_ or main(). A workgroupSize whose product "
            "is not a multiple of 32 is refused by the compiler: use [64], [32, 2] or [8, 8]. "
            "docs/SHADERS.md, \"Compute materials\".";
    else if (token == "main")
        issue.hint = std::string("The engine owns main(): the snippet defines ") + fragment_entry(ctx.material) +
                     "() (and vertex()) and must not define main. Remove it.";
    else
        issue.hint =
            std::string(
                "The engine template could not be built from the snippet, so the snippet broke the contract: define ") +
            signatures(ctx.material) +
            ", and do not declare names starting with fa_ or main(). Run `factoria call docs.read "
            "'{\"path\":\"docs/SHADERS.md\"}'` for the contract once it is documented.";
}

std::vector<ShaderIssue> map_diagnostics(const std::vector<Diagnostic>& diags, const MapContext& ctx) {
    std::vector<ShaderIssue> out;
    const bool hasOther = std::any_of(diags.begin(), diags.end(), [](const Diagnostic& d) {
        return d.message.find("missing #endif") == std::string::npos;
    });
    for (const Diagnostic& d : diags) {
        if (hasOther && d.message.find("missing #endif") != std::string::npos) continue;  // follows the real error
        ShaderIssue issue;
        const std::string token = message_token(d.message);
        issue.message = d.message;
        const std::string base = stdfs::path(d.file).filename().string();
        if (base == "top.glsl" && d.line >= 1 && d.line <= int(ctx.generated.snippetLine.size()) &&
            ctx.generated.snippetLine[d.line - 1] > 0) {
            const int sl = ctx.generated.snippetLine[d.line - 1];
            issue.file = ctx.material.shader;
            issue.line = sl;
            issue.source = line_text(ctx.snippet, sl);
            std::size_t p = token.empty()
                                ? std::string::npos
                                : find_word(issue.source, token, d.message.find("no such field") != std::string::npos);
            if (p == std::string::npos) {
                p = issue.source.find_first_not_of(" \t");
                if (p == std::string::npos) p = 0;
            }
            issue.column = int(p) + 1;
            issue.hint = hint_for(d.message, token, issue.source, ctx);
        } else if (base == "top.glsl") {
            outside_snippet(issue, "in the generated declarations of the material", token, ctx);
        } else if (!d.file.empty()) {
            outside_snippet(issue, "in the engine template " + base + ":" + std::to_string(d.line), token, ctx);
        } else {
            issue.file = ctx.material.shader;
        }
        out.push_back(std::move(issue));
    }
    // The same mistake found by both stages is reported once; the follow-ups of an unknown name on its line are noise.
    std::vector<ShaderIssue> unique;
    for (ShaderIssue& i : out) {
        const bool dup = std::any_of(unique.begin(), unique.end(), [&](const ShaderIssue& u) {
            return u.file == i.file && u.line == i.line && u.message == i.message;
        });
        if (!dup) unique.push_back(std::move(i));
    }
    std::vector<ShaderIssue> result;
    for (const ShaderIssue& i : unique) {
        const bool root = i.message.find("undeclared identifier") != std::string::npos ||
                          i.message.find("no such field") != std::string::npos;
        const bool shadowed =
            !root && i.line > 0 && std::any_of(unique.begin(), unique.end(), [&](const ShaderIssue& u) {
                return u.line == i.line && (u.message.find("undeclared identifier") != std::string::npos ||
                                            u.message.find("no such field") != std::string::npos);
            });
        if (!shadowed) result.push_back(i);
    }
    return result;
}

// Problems the author can be told about without starting a compiler.
std::vector<ShaderIssue> precheck_snippet(const MaterialDef& material, const GeneratedShader& g,
                                          const std::string& snippet, const std::string& stripped) {
    std::vector<ShaderIssue> out;
    if (material.kind == "compute" && !g.hasCompute) {
        ShaderIssue i;
        i.file = material.shader;
        i.message = "the snippet defines no compute() function";
        i.hint =
            "Define it as `void compute(in ComputeInput i) { ... }`: it runs once per thread, i.global_id.x is the "
            "thread's index over the whole dispatch. The buffers are <name>.data[i], the params are globals. The "
            "snippet must not define main.";
        out.push_back(std::move(i));
    } else if (material.kind != "compute" && !g.hasSurface) {
        ShaderIssue i;
        i.file = material.shader;
        i.message = std::string("the snippet defines no ") + fragment_entry(material) + "() function";
        if (is_post(material))
            i.hint =
                "Define it as `void post(in PostInput i, inout PostSurface s) { s.color.rgb = 1.0 - s.color.rgb; }`. "
                "s.color arrives holding the picture at this pixel (linear, as the passes before this one left it), so "
                "change only what you need; fa_scene_color(uv), fa_depth(uv) and fa_normal(uv) read other pixels. "
                "Signatures: " +
                signatures(material) + ".";
        else if (is_sky(material))
            i.hint = "Define it as `void sky(in SkyInput i, inout SkySurface s) { s.color = mix(s.color, vec3(1.0, "
                     "0.5, 0.2), "
                     "pow(max(dot(i.dir, i.sun_dir), 0.0), 8.0)); }`. s.color arrives holding the engine's sky (the "
                     "gradient of "
                     "SceneSettings.skyColor and horizonColor), so change only what you need. Signatures: " +
                     signatures(material) + ".";
        else if (is_sprite(material))
            i.hint =
                "Define it as `void fragment(in QuadInput i, inout QuadSurface s) { s.color.rgb *= vec3(1.0, 0.5, "
                "0.5); }`. s.color arrives holding what the engine would draw for the sprite, shape, tile, glyph or "
                "particle, so change only what you need. Signatures: " +
                signatures(material) + ".";
        else
            i.hint =
                "Define it as `void surface(in SurfaceInput i, inout Surface s) { s.albedo = vec3(1.0, 0.0, 0.0); }`. "
                "s arrives filled with the standard MeshRenderer result, so change only what you need. Signatures: " +
                signatures(material) + ".";
        out.push_back(std::move(i));
    }
    // A post pass is one full-screen triangle drawn by the engine: there is no vertex stage to hook.
    if (is_post(material)) {
        static const std::regex entry(R"(\bvoid\s+vertex\s*\()");
        std::smatch m;
        if (std::regex_search(stripped, m, entry)) {
            const std::size_t at = std::size_t(m.position(0));
            ShaderIssue i;
            i.file = material.shader;
            i.line = line_of(stripped, at);
            i.source = line_text(snippet, i.line);
            i.column = column_of(stripped, at) + 1;
            i.message = "a post material has no vertex() hook";
            i.hint =
                "The pass draws one full-screen triangle, so there is no geometry to move. Remove vertex() and do the "
                "work in post(), per pixel (i.uv is the pixel, fa_scene_color(uv) reads the picture anywhere); "
                "a mesh material (kind \"mesh\") has vertex().";
            out.push_back(std::move(i));
        }
    }
    if (is_sky(material) && g.hasVertex) {
        static const std::regex entry(R"(\bvoid\s+vertex\s*\()");
        std::smatch m;
        ShaderIssue i;
        i.file = material.shader;
        if (std::regex_search(stripped, m, entry)) {
            i.line = line_of(stripped, std::size_t(m.position(0)));
            i.source = line_text(snippet, i.line);
            i.column = column_of(stripped, std::size_t(m.position(0))) + 1;
        }
        i.message = "a sky material has no vertex(): the sky is one full-screen triangle";
        i.hint =
            "Remove vertex() and compute the colour of each pixel in sky() from i.dir (the view direction), i.sun_dir "
            "and i.time. Signatures: " +
            signatures(material) + ".";
        out.push_back(std::move(i));
    }
    if (material.kind == "mesh" && material.lighting == "custom" && !g.hasLight) {
        ShaderIssue i;
        i.file = material.shader;
        i.message = "the material " + (material.path.empty() ? std::string("file") : material.path) +
                    " has \"lighting\": \"custom\" but the snippet defines no light() function";
        i.hint = "Define `vec3 light(in SurfaceInput i, in Surface s, in LightSample l) { return s.albedo * l.color * "
                 "max(dot(s.normal, l.direction), 0.0); }`: the engine calls it once per light and adds the results; "
                 "l.color "
                 "already has the light's attenuation and shadow in it. (Optional: `vec3 ambient(in SurfaceInput i, in "
                 "Surface s, "
                 "vec3 ambientColor)` for the ambient term.) Or set \"lighting\" to \"pbr\" (the engine's lighting) or "
                 "\"unlit\" in " +
                 (material.path.empty() ? std::string("the material file") : material.path) +
                 " (pointer /lighting). Signatures: " + kLightSignatures + ".";
        out.push_back(std::move(i));
    }
    // A declaration with an fa_ name: `<type> fa_x ;|=|[|(|,|)` or #define fa_x.
    static const std::regex decl(R"(\b([A-Za-z_]\w*)\s+(fa_\w*)\s*(?=[;=\[(,)]))");
    static const std::set<std::string> notTypes = {"return", "else", "case",  "discard", "break",  "continue",
                                                   "do",     "if",   "while", "for",     "switch", "default"};
    for (auto it = std::sregex_iterator(stripped.begin(), stripped.end(), decl); it != std::sregex_iterator(); ++it) {
        const std::smatch& m = *it;
        if (notTypes.count(m[1])) continue;
        const std::size_t offset = std::size_t(m.position(2));
        ShaderIssue i;
        i.file = material.shader;
        i.line = line_of(stripped, offset);
        i.source = line_text(snippet, i.line);
        i.column = column_of(stripped, offset) + 1;
        i.message = "'" + m[2].str() + "' : the snippet declares a name starting with fa_";
        i.hint = prefix_rule(material);
        out.push_back(std::move(i));
    }
    return out;
}

// ---------------------------------------------------------------------------------------------------------------
// The twin
// ---------------------------------------------------------------------------------------------------------------

Json func_reflection(const Json& f) {
    Json out = Json::object();
    for (const char* key : {"entry_point", "d3d11_target"})
        if (f.is_object() && f.contains(key)) out[key] = f[key];
    return out;
}

std::string read_output_file(const stdfs::path& work, const std::string& rel) {
    const stdfs::path p = stdfs::path(rel).is_absolute() ? stdfs::path(rel) : work / rel;
    return tooling_detail::read_file(p).value_or(std::string());
}

// The twins of the requested slangs from sokol-shdc's reflection YAML and the source files it points to.
Result<std::map<std::string, Json>> build_twins(const stdfs::path& work, const std::string& yamlText,
                                                const MaterialDef& material, const std::vector<std::string>& slangs,
                                                std::vector<ShaderIssue>& issues) {
    auto yaml = parse_shdc_yaml(yamlText);
    if (!yaml.ok()) return yaml.error();
    if (!yaml->is_object() || !yaml->contains("shaders") || !(*yaml)["shaders"].is_array())
        return make_error("the reflection file of sokol-shdc has no \"shaders\" list",
                          "Install the pinned sokol-shdc (`factoria setup shaders`).");
    Json paramNames = Json::array(), textureNames = Json::array();
    // The uniform block holds the params that are not instanced; the instanced ones travel in the instance buffer, laid out as
    // "instanced" says (a twin without these keys has none: older twins stay valid).
    for (const MaterialParam& p : material.params)
        if (!p.instanced) paramNames.push_back(p.name);
    for (const MaterialTexture& t : material.textures) textureNames.push_back(t.name);
    const InstanceLayout instLayout = instance_layout(material.params);
    Json instancedSlots = Json::array(), vertexAttributes = Json::array();
    for (const InstanceSlot& s : instLayout.slots)
        instancedSlots.push_back(
            Json::object({{"name", s.name}, {"vec4", s.vec4}, {"offset", s.offset}, {"components", s.components}}));
    for (const std::string& a : material.vertexAttributes) vertexAttributes.push_back(a);

    std::map<std::string, Json> twins;
    bool vertexTextureReported = false;
    for (const Json& shader : (*yaml)["shaders"]) {
        const std::string slang = shader.value("slang", std::string());
        if (std::find(slangs.begin(), slangs.end(), slang) == slangs.end()) continue;
        Json twin = Json::object({{"format", kShaderTwinFormat},
                                  {"engine", FA_ENGINE_VERSION},
                                  {"template", shader_template_hash(material.full ? "mesh-full" : material.kind)},
                                  {"slang", slang},
                                  {"params", paramNames},
                                  {"textures", textureNames}});
        // A twin without "kind" is a mesh twin: mesh twins stay as they were before M72, so no committed or exported one is
        // made stale by the kinds.
        if (material.kind != "mesh") twin["kind"] = material.kind;
        if (instLayout.vec4Count > 0) {
            twin["instanced"] = instancedSlots;
            twin["instanceVec4"] = instLayout.vec4Count;
        }
        if (!vertexAttributes.empty()) twin["vertexAttributes"] = vertexAttributes;
        if (material.full) {
            const Json fullFields = full_twin_fields(material);  // a named value: items() of a temporary dangles
            for (const auto& [key, value] : fullFields.items()) twin[key] = value;
        }
        if (material.kind == "compute") {
            const Json computeFields = shaders_detail::compute_twin_fields(material);
            twin["workgroupSize"] = computeFields["workgroupSize"];
            twin["buffers"] = computeFields["buffers"];
            if (computeFields.contains("images")) twin["images"] = computeFields["images"];
        }
        Json programs = Json::object();
        for (const Json& prog : shader.value("programs", Json::array())) {
            const std::string name = prog.value("name", std::string());
            Json reflection = prog;
            reflection.erase("name");
            if (material.kind == "compute") {  // one compute function ("cs") instead of a vertex and a fragment one
                const Json cf = prog.value("compute_func", Json::object());
                reflection["compute_func"] = func_reflection(cf);
                const std::string csText = read_output_file(work, cf.value("path", std::string()));
                if (csText.empty())
                    return make_error(
                        "sokol-shdc did not write the " + slang + " source of program '" + name + "'",
                        "Run sokol-shdc by hand on the generated top file (`factoria call shader.compile` "
                        "prints its errors).");
                programs[name] = Json::object({{"cs", csText}, {"reflection", std::move(reflection)}});
                continue;
            }
            const Json vf = prog.value("vertex_func", Json::object()), ff = prog.value("fragment_func", Json::object());
            reflection["vertex_func"] = func_reflection(vf);
            reflection["fragment_func"] = func_reflection(ff);
            const std::string vsText = read_output_file(work, vf.value("path", std::string())),
                              fsText = read_output_file(work, ff.value("path", std::string()));
            if (vsText.empty() || fsText.empty())
                return make_error("sokol-shdc did not write the " + slang + " source of program '" + name + "'",
                                  "Run sokol-shdc by hand on the generated top file (`factoria call shader.compile` "
                                  "prints its errors).");
            if (!vertexTextureReported)
                for (const Json& view : prog.value("views", Json::array())) {
                    const Json tex = view.value("texture", Json::object());
                    const std::string tname = tex.value("name", std::string());
                    if (tex.value("stage", std::string()) == "vertex" &&
                        std::any_of(material.textures.begin(), material.textures.end(),
                                    [&](const MaterialTexture& t) { return t.name == tname; })) {
                        ShaderIssue i;
                        i.file = material.shader;
                        i.message = "the texture '" + tname +
                                    "' is sampled in vertex(), but textures can only be read in the fragment stage";
                        i.hint = std::string("Read textures in ") + fragment_entry(material) +
                                 "(), or compute the displacement from fa_time and params in vertex(). Vertex-stage "
                                 "textures are not supported yet.";
                        issues.push_back(std::move(i));
                        vertexTextureReported = true;
                    }
                }
            programs[name] = Json::object({{"vs", vsText}, {"fs", fsText}, {"reflection", std::move(reflection)}});
        }
        twin["programs"] = std::move(programs);
        twins[slang] = std::move(twin);
    }
    for (const std::string& s : slangs)
        if (!twins.count(s))
            return make_error("sokol-shdc wrote no reflection for the dialect " + s,
                              "Run `factoria setup shaders` to install the pinned sokol-shdc.");
    return twins;
}

struct TempWork {
    stdfs::path path;
    std::optional<Error>
        error;  // set when no scratch folder could be made (then `path` is empty and nothing is deleted)
    TempWork() {
        auto dir = fs::make_temp_dir("fa_shader");
        if (dir.ok())
            path = *dir;
        else
            error = dir.error();
    }
    ~TempWork() {
        if (path.empty()) return;
        std::error_code ec;
        stdfs::remove_all(path, ec);
    }
};

}  // namespace

std::string sokol_shdc_missing_hint(const SetupContext& context) {
    std::string hint = "Run `factoria setup shaders` to install it (a pinned sokol-tools-bin commit, " +
                       std::string(kSetupSokolShdcCommit).substr(0, 7) +
                       "), or set the environment variable SOKOL_SHDC to the path of sokol-shdc.";
    if (context.host_os() == "windows")
        hint += " Windows Defender may have quarantined sokol-shdc.exe as a false positive: restore it from Windows "
                "Security > Protection history, or point SOKOL_SHDC at a copy you trust.";
    return hint;
}

Result<ShaderCompileResult> compile_material(const std::string& projectDir, const std::string& materialPath,
                                             const ShaderCompileOptions& options) {
    ShaderCompileResult res;
    if (options.dialects.empty())
        res.dialects = shader_dialects();
    else
        for (const std::string& d : options.dialects) {
            if (std::find(shader_dialects().begin(), shader_dialects().end(), d) == shader_dialects().end())
                return make_error("unknown shader dialect '" + d + "'", did_you_mean(d, shader_dialects()));
            res.dialects.push_back(d);
        }

    MaterialParse mp = read_material(projectDir, materialPath);
    res.material = mp.material;
    for (const MaterialIssue& e : mp.errors) {
        ShaderIssue i;
        i.file = materialPath;
        i.pointer = e.pointer;
        i.message = e.message;
        i.hint = e.hint;
        res.errors.push_back(std::move(i));
    }
    if (!mp.ok()) return res;
    if (res.material.kind == "compute") {  // no glsl300es twin: GLES3 and WebGL2 have no compute shaders
        const std::vector<std::string> has = shader_dialects_of_kind("compute");
        if (options.dialects.empty()) {  // "every dialect" means every dialect the kind has
            res.dialects = has;
        } else {
            std::vector<std::string> kept;
            for (const std::string& d : res.dialects)
                (std::find(has.begin(), has.end(), d) != has.end() ? kept : res.skippedDialects).push_back(d);
            res.dialects = std::move(kept);
        }
    }
    auto raw = tooling_detail::read_file(stdfs::path(projectDir) / res.material.shader);
    if (!raw)
        return make_error("cannot read the snippet '" + res.material.shader + "' of " + materialPath,
                          "Check the \"shader\" path of the material.");
    const std::string snippet = normalize_snippet(*raw);
    const std::string stripped = blank_comments(snippet);
    res.generated = generate_material_shader(res.material, snippet);
    res.errors = res.material.full ? precheck_full(res.material, snippet, stripped)
                                   : precheck_snippet(res.material, res.generated, snippet, stripped);
    if (!res.errors.empty()) return res;
    if (shader_template_hash(res.generated.kind).empty())
        return make_error("this factoria build has no " + res.generated.kind +
                              " shader template (engine/render/shaders/*_common.glsl)",
                          "Rebuild factoria from the full source tree so the template is embedded.");

    // What the cache already has.
    std::vector<std::string> missing;
    for (const std::string& slang : res.dialects) {
        if (options.useCache)
            if (auto twin = read_cached_twin(shader_cache_path(projectDir, res.generated, snippet, slang), slang)) {
                res.twins[slang] = std::move(*twin);
                ++res.cacheHits;
                continue;
            }
        missing.push_back(slang);
    }
    if (missing.empty()) {
        res.ok = true;
        return res;
    }

    const std::string tool = find_sokol_shdc(options.setup);
    if (tool.empty())
        return make_error("sokol-shdc, the shader compiler, was not found, so the snippet '" + res.material.shader +
                              "' cannot be compiled",
                          sokol_shdc_missing_hint(options.setup) +
                              " A material whose twin is in .factoria/shader-cache needs no compiler.");

    TempWork work;
    if (work.error) return *work.error;
    bool written = tooling_detail::write_file(work.path / "top.glsl", res.generated.top) &&
                   tooling_detail::write_file(work.path / "out" / ".keep", "");
    for (const auto& [name, content] : template_files(res.generated.kind))
        written = written && tooling_detail::write_file(work.path / name, content);
    if (!written)
        return make_error("cannot write to the temporary folder " + work.path.string(), "Check the free disk space.");

    ProcessOptions po;
    po.argv = {tool,       "--input", "top.glsl", "--output",         "out/m",           "--format", "bare_yaml",
               "--errfmt", "gcc",     "--slang",  join(missing, ":"), "--no-log-cmdline"};
    if (!res.generated.defines.empty()) {
        po.argv.push_back("--defines");
        po.argv.push_back(join(res.generated.defines, ":"));
    }
    po.workingDir = work.path.string();
    po.timeoutSeconds = 120;
    po.cancel = options.setup.cancel;
    auto ran = options.setup.run_process_with(po);
    if (!ran.ok())
        return make_error(
            "could not start sokol-shdc (" + tool + "): " + ran.error().message,
            (ran.error().hint.empty() ? "Check that the file exists and is executable." : ran.error().hint) + " " +
                sokol_shdc_missing_hint(options.setup));
    if (ran->timedOut)
        return make_error("sokol-shdc did not finish in 120 seconds",
                          "Run it by hand on the generated top file to see where it hangs.");

    if (ran->exitCode != 0) {
        MapContext ctx{res.material, res.generated, snippet, stripped, projectDir};
        res.errors = map_diagnostics(parse_diagnostics(ran->stderrText + "\n" + ran->stdoutText), ctx);
        if (res.errors.empty()) {
            ShaderIssue i;
            i.file = res.material.shader;
            i.message = "sokol-shdc failed (exit code " + std::to_string(ran->exitCode) +
                        ") without a message it can be mapped to the snippet from: " +
                        std::string(trim(ran->stderrText.empty() ? ran->stdoutText : ran->stderrText));
            i.hint = "Run `factoria setup shaders` to be sure the pinned sokol-shdc is used, and report the message if "
                     "it persists.";
            res.errors.push_back(std::move(i));
        }
        return res;
    }

    std::string yamlText;
    std::error_code ec;
    for (const auto& e : stdfs::directory_iterator(work.path / "out", ec))
        if (e.path().filename().string().ends_with("_reflection.yaml"))
            yamlText = tooling_detail::read_file(e.path()).value_or(std::string());
    if (yamlText.empty())
        return make_error(
            "sokol-shdc succeeded but wrote no reflection file",
            "The pinned sokol-shdc writes it with --format bare_yaml; reinstall it with `factoria setup shaders`.");
    auto twins = build_twins(work.path, yamlText, res.material, missing, res.errors);
    if (!twins.ok()) return twins.error();
    if (!res.errors.empty()) return res;
    for (auto& [slang, twin] : *twins) {
        write_cached_twin(shader_cache_path(projectDir, res.generated, snippet, slang), twin);
        res.twins[slang] = std::move(twin);
    }
    res.ok = true;
    return res;
}

}  // namespace fa
