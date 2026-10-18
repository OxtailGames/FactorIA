// Running sokol-shdc for a material: the cache, the error mapping back to the author's snippet (with hints for the frequent
// mistakes), and the twin documents (docs/design/CUSTOM_SHADERS.md, "How it is compiled" and "Errors that teach").
#include <algorithm>
#include <cctype>
#include <filesystem>
#include <regex>
#include <set>

#include "fa/core/fs.h"
#include "fa/core/hash.h"
#include "fa/core/strings.h"
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
    if (line > 0) out += ":" + std::to_string(line) + ":" + std::to_string(std::max(column, 1));
    else if (!pointer.empty()) out += "#" + pointer;
    out += ": error: " + message;
    if (!source.empty() && line > 0) {
        const std::string num = std::to_string(line);
        out += "\n  " + num + " | " + source + "\n  " + std::string(num.size(), ' ') + " | " + std::string(std::size_t(std::max(column, 1) - 1), ' ') + "^";
    }
    if (!hint.empty()) out += "\n  hint: " + hint;
    return out;
}

// ---------------------------------------------------------------------------------------------------------------
// The cache
// ---------------------------------------------------------------------------------------------------------------

std::string shader_template_hash() {
    static const std::string hash = [] {
        const auto files = template_files();
        if (files.empty()) return std::string();
        std::string all;
        for (const auto& [name, content] : files) all += name + '\0' + content + '\0';
        return sha256_hex(all);
    }();
    return hash;
}

std::string shader_cache_path(const std::string& projectDir, const GeneratedShader& generated, std::string_view snippet, const std::string& slang) {
    std::string key = generated.top;
    const std::string templateHash = shader_template_hash();
    for (std::string_view part : {snippet, std::string_view(templateHash), std::string_view(slang), std::string_view(kSetupSokolShdcCommit),
                                  std::string_view(FA_ENGINE_VERSION)}) {
        key += '\x01';
        key += part;
    }
    for (const std::string& d : generated.defines) key += '\x01' + d;
    return (stdfs::path(projectDir) / ".factoria" / "shader-cache" / (sha256_hex(key) + "." + slang + ".shader")).string();
}

namespace {

std::optional<Json> read_cached_twin(const std::string& path, const std::string& slang) {
    auto text = tooling_detail::read_file(path);
    if (!text) return std::nullopt;
    auto parsed = parse_json(*text, path);
    if (!parsed.ok() || !parsed->is_object() || parsed->value("format", std::string()) != kShaderTwinFormat || parsed->value("slang", std::string()) != slang)
        return std::nullopt;
    return std::move(parsed.value());
}

void write_cached_twin(const std::string& path, const Json& twin) {
    const std::string tmp = path + ".tmp";
    if (!tooling_detail::write_file(tmp, twin.dump() + "\n")) return;  // a cache that cannot be written only costs time
    std::error_code ec;
    stdfs::rename(tmp, path, ec);
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
    const std::string& snippet;       // normalized
    const std::string& stripped;      // comment-blanked snippet
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

std::string struct_var(const std::string& typeName) {
    return typeName == "SurfaceInput" ? "i" : typeName == "Surface" ? "s" : "v";
}

const std::vector<std::string>* struct_fields(const std::string& name) {
    for (const auto& [n, fields] : contract_structs())
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
            static const std::regex decl(R"(\b(SurfaceInput|Surface|VertexData)\s+(\w+))");
            for (auto it = std::sregex_iterator(ctx.stripped.begin(), ctx.stripped.end(), decl); it != std::sregex_iterator(); ++it)
                if ((*it)[2] == var) typeName = (*it)[1];
        }
    }
    std::vector<std::string> fields;
    std::string where = "Surface, SurfaceInput and VertexData";
    if (const auto* f = struct_fields(typeName)) {
        fields = *f;
        where = typeName;
    } else {
        for (const auto& [n, f2] : contract_structs())
            for (const std::string& name : f2)
                if (std::find(fields.begin(), fields.end(), name) == fields.end()) fields.push_back(name);
    }
    static const std::vector<std::pair<std::string, std::string>> aliases = {
        {"colour", "albedo"}, {"color", "albedo"}, {"diffuse", "albedo"}, {"basecolor", "albedo"}, {"base", "albedo"}, {"opacity", "alpha"},
        {"transparency", "alpha"}, {"emissive", "emission"}, {"glow", "emission"}, {"emit", "emission"}, {"ao", "occlusion"},
        {"ambientocclusion", "occlusion"}, {"rough", "roughness"}, {"metal", "metallic"}, {"metalness", "metallic"}, {"normals", "normal"},
        {"normal", "world_normal"}, {"position", "world_pos"}, {"pos", "world_pos"}, {"worldpos", "world_pos"}, {"worldposition", "world_pos"},
        {"world_position", "world_pos"}, {"texcoord", "uv"}, {"texcoords", "uv"}, {"uv0", "uv"}, {"viewdir", "view_dir"},
        {"view", "view_dir"}, {"tangent", "world_tangent"}, {"worldnormal", "world_normal"}, {"frontfacing", "front_facing"}, {"isfrontface", "front_facing"}};
    std::string lower = to_lower(token), flat;
    for (char c : lower)
        if (c != '_') flat += c;
    std::string best;
    for (const auto& [alias, canonical] : aliases)
        if ((alias == lower || alias == flat) && std::find(fields.begin(), fields.end(), canonical) != fields.end()) { best = canonical; break; }
    if (best.empty()) best = closest_match(token, fields);
    return (best.empty() ? std::string() : "did you mean " + best + "? ") + where + " has the fields: " + join(fields, ", ") + ".";
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

std::vector<std::string> engine_names() {
    static const std::vector<std::string> names = [] {
        std::set<std::string> found;
        static const std::regex re(R"(\bfa_\w+)");
        for (const auto& [file, content] : template_files()) {
            const std::string text = blank_comments(content);
            for (auto it = std::sregex_iterator(text.begin(), text.end(), re); it != std::sregex_iterator(); ++it) found.insert(it->str());
        }
        return std::vector<std::string>(found.begin(), found.end());
    }();
    return names;
}

constexpr const char* kPrefixRule = "Names starting with fa_ belong to the engine: the snippet may read the ones the contract lists (fa_time, fa_camera_pos, fa_tangent_normal) but not declare any. Rename it without the prefix.";
constexpr const char* kSignatures = "void surface(in SurfaceInput i, inout Surface s) { ... }  (required)  and  void vertex(inout VertexData v) { ... }  (optional)";

std::string undeclared_hint(const std::string& token, const MapContext& ctx) {
    // A field written without its struct.
    for (const auto& [n, fields] : contract_structs())
        if (std::find(fields.begin(), fields.end(), token) != fields.end())
            return "`" + token + "` is a field of " + n + ": write " + struct_var(n) + "." + token + " inside " + (n == "VertexData" ? "vertex" : "surface") + "().";
    if (token.rfind("fa_", 0) == 0) {
        const std::string best = closest_match(token, engine_names());
        return best.empty() ? std::string("No engine value is called ") + token + "; the ones a snippet may read are fa_time, fa_camera_pos and fa_tangent_normal()."
                            : "did you mean " + best + "?";
    }
    std::vector<std::string> names;
    for (const MaterialParam& p : ctx.material.params) names.push_back(p.name);
    for (const MaterialTexture& t : ctx.material.textures) names.push_back(t.name);
    const std::string best = closest_match(token, names);
    if (!best.empty()) return "did you mean " + best + "? This material declares: " + join(names, ", ") + ".";
    if (const std::string other = declared_by_other_material(token, ctx); !other.empty())
        return "`" + token + "` is declared by " + other + ", not by this material. Add it to \"params\" or \"textures\" in " + ctx.material.path + " (each material declares its own).";
    return "Declare `" + token + "` in \"params\" (or \"textures\") of " + ctx.material.path + ", or declare it in the snippet." +
           (names.empty() ? std::string(" This material declares no params or textures.") : " This material declares: " + join(names, ", ") + ".");
}

std::string hint_for(const std::string& message, const std::string& token, const std::string& source, const MapContext& ctx) {
    if (message.find("no such field in structure") != std::string::npos) return field_hint(token, source, ctx);
    if (message.find("undeclared identifier") != std::string::npos) return undeclared_hint(token, ctx);
    if (message.find("no matching overloaded function found") != std::string::npos && token.rfind("texture", 0) == 0) {
        // texture(waves, uv) on a separate texture.
        for (const MaterialTexture& t : ctx.material.textures) {
            std::regex use(token + R"(\s*\(\s*)" + t.name + R"(\s*,)");
            if (std::regex_search(source, use))
                return "textures and samplers are separate: write " + token + "(sampler2D(" + t.name + ", " + t.name + "_smp), uv) instead of " + token + "(" + t.name + ", uv).";
        }
        return "Texture lookups take a combined sampler built from the texture and its sampler: " + token + "(sampler2D(name, name_smp), uv), with a vec2 uv.";
    }
    if (message.find("redefinition") != std::string::npos && token.rfind("fa_", 0) == 0) return kPrefixRule;
    if (message.find("redefinition") != std::string::npos) {
        for (const MaterialParam& p : ctx.material.params)
            if (p.name == token) return "`" + token + "` is already a global: it is a param of this material (declared in " + ctx.material.path + "). Use it directly, or rename the local variable.";
        for (const MaterialTexture& t : ctx.material.textures)
            if (t.name == token || t.name + "_smp" == token) return "`" + token + "` is already declared by the texture \"" + t.name + "\" of this material. Rename the local variable.";
    }
    if (message.find("syntax error") != std::string::npos)
        return "A syntax error is often reported on the line after the real mistake: look for a missing ';', ')' or '}' just above.";
    if (message.find("cannot convert from") != std::string::npos)
        return "GLSL does not convert types by itself: write vec3(x) to widen a float, use .rgb or .xyz to narrow a vec4, and write float literals with a dot (1.0, not 1).";
    return {};
}

// What the author reads when the error is not in their snippet: the rule.
void outside_snippet(ShaderIssue& issue, const std::string& where, const std::string& token, const MapContext& ctx) {
    issue.message += " (" + where + ", which is the engine's code, not the snippet's)";
    issue.line = 0;
    issue.source.clear();
    issue.file = ctx.material.shader.empty() ? ctx.material.path : ctx.material.shader;
    if (token == "surface" || token == "vertex")
        issue.hint = std::string("The engine calls ") + token + "() from its template, so the snippet must define it with exactly this signature: " + kSignatures + ".";
    else if (token == "main")
        issue.hint = "The engine owns main(): the snippet defines surface() (and vertex()) and must not define main. Remove it.";
    else
        issue.hint = std::string("The engine template could not be built from the snippet, so the snippet broke the contract: define ") + kSignatures +
                     ", and do not declare names starting with fa_ or main(). Run `factoria call docs.read '{\"path\":\"docs/SHADERS.md\"}'` for the contract once it is documented.";
}

std::vector<ShaderIssue> map_diagnostics(const std::vector<Diagnostic>& diags, const MapContext& ctx) {
    std::vector<ShaderIssue> out;
    const bool hasOther = std::any_of(diags.begin(), diags.end(), [](const Diagnostic& d) { return d.message.find("missing #endif") == std::string::npos; });
    for (const Diagnostic& d : diags) {
        if (hasOther && d.message.find("missing #endif") != std::string::npos) continue;  // follows the real error
        ShaderIssue issue;
        const std::string token = message_token(d.message);
        issue.message = d.message;
        const std::string base = stdfs::path(d.file).filename().string();
        if (base == "top.glsl" && d.line >= 1 && d.line <= int(ctx.generated.snippetLine.size()) && ctx.generated.snippetLine[d.line - 1] > 0) {
            const int sl = ctx.generated.snippetLine[d.line - 1];
            issue.file = ctx.material.shader;
            issue.line = sl;
            issue.source = line_text(ctx.snippet, sl);
            std::size_t p = token.empty() ? std::string::npos : find_word(issue.source, token, d.message.find("no such field") != std::string::npos);
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
        const bool dup = std::any_of(unique.begin(), unique.end(), [&](const ShaderIssue& u) { return u.file == i.file && u.line == i.line && u.message == i.message; });
        if (!dup) unique.push_back(std::move(i));
    }
    std::vector<ShaderIssue> result;
    for (const ShaderIssue& i : unique) {
        const bool root = i.message.find("undeclared identifier") != std::string::npos || i.message.find("no such field") != std::string::npos;
        const bool shadowed = !root && i.line > 0 &&
                              std::any_of(unique.begin(), unique.end(), [&](const ShaderIssue& u) {
                                  return u.line == i.line && (u.message.find("undeclared identifier") != std::string::npos || u.message.find("no such field") != std::string::npos);
                              });
        if (!shadowed) result.push_back(i);
    }
    return result;
}

// Problems the author can be told about without starting a compiler.
std::vector<ShaderIssue> precheck_snippet(const MaterialDef& material, const GeneratedShader& g, const std::string& snippet, const std::string& stripped) {
    std::vector<ShaderIssue> out;
    if (!g.hasSurface) {
        ShaderIssue i;
        i.file = material.shader;
        i.message = "the snippet defines no surface() function";
        i.hint = std::string("Define it as `void surface(in SurfaceInput i, inout Surface s) { s.albedo = vec3(1.0, 0.0, 0.0); }`. s arrives filled with the standard MeshRenderer result, so change only what you need. Signatures: ") + kSignatures + ".";
        out.push_back(std::move(i));
    }
    // A declaration with an fa_ name: `<type> fa_x ;|=|[|(|,|)` or #define fa_x.
    static const std::regex decl(R"(\b([A-Za-z_]\w*)\s+(fa_\w*)\s*(?=[;=\[(,)]))");
    static const std::set<std::string> notTypes = {"return", "else", "case", "discard", "break", "continue", "do", "if", "while", "for", "switch", "default"};
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
        i.hint = kPrefixRule;
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
Result<std::map<std::string, Json>> build_twins(const stdfs::path& work, const std::string& yamlText, const MaterialDef& material,
                                                const std::vector<std::string>& slangs, std::vector<ShaderIssue>& issues) {
    auto yaml = parse_shdc_yaml(yamlText);
    if (!yaml.ok()) return yaml.error();
    if (!yaml->is_object() || !yaml->contains("shaders") || !(*yaml)["shaders"].is_array())
        return make_error("the reflection file of sokol-shdc has no \"shaders\" list", "Install the pinned sokol-shdc (`factoria setup shaders`).");
    Json paramNames = Json::array(), textureNames = Json::array();
    for (const MaterialParam& p : material.params) paramNames.push_back(p.name);
    for (const MaterialTexture& t : material.textures) textureNames.push_back(t.name);

    std::map<std::string, Json> twins;
    bool vertexTextureReported = false;
    for (const Json& shader : (*yaml)["shaders"]) {
        const std::string slang = shader.value("slang", std::string());
        if (std::find(slangs.begin(), slangs.end(), slang) == slangs.end()) continue;
        Json twin = Json::object({{"format", kShaderTwinFormat}, {"engine", FA_ENGINE_VERSION}, {"template", shader_template_hash()},
                                  {"slang", slang}, {"params", paramNames}, {"textures", textureNames}});
        Json programs = Json::object();
        for (const Json& prog : shader.value("programs", Json::array())) {
            const std::string name = prog.value("name", std::string());
            Json reflection = prog;
            reflection.erase("name");
            const Json vf = prog.value("vertex_func", Json::object()), ff = prog.value("fragment_func", Json::object());
            reflection["vertex_func"] = func_reflection(vf);
            reflection["fragment_func"] = func_reflection(ff);
            const std::string vsText = read_output_file(work, vf.value("path", std::string())), fsText = read_output_file(work, ff.value("path", std::string()));
            if (vsText.empty() || fsText.empty())
                return make_error("sokol-shdc did not write the " + slang + " source of program '" + name + "'",
                                  "Run sokol-shdc by hand on the generated top file (`factoria call shader.compile` prints its errors).");
            if (!vertexTextureReported)
                for (const Json& view : prog.value("views", Json::array())) {
                    const Json tex = view.value("texture", Json::object());
                    const std::string tname = tex.value("name", std::string());
                    if (tex.value("stage", std::string()) == "vertex" &&
                        std::any_of(material.textures.begin(), material.textures.end(), [&](const MaterialTexture& t) { return t.name == tname; })) {
                        ShaderIssue i;
                        i.file = material.shader;
                        i.message = "the texture '" + tname + "' is sampled in vertex(), but textures can only be read in the fragment stage";
                        i.hint = "Read textures in surface(), or compute the displacement from fa_time and params in vertex(). Vertex-stage textures are not supported yet.";
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
        if (!twins.count(s)) return make_error("sokol-shdc wrote no reflection for the dialect " + s, "Run `factoria setup shaders` to install the pinned sokol-shdc.");
    return twins;
}

struct TempWork {
    stdfs::path path;
    TempWork() : path(fs::make_temp_dir("fa_shader")) {}
    ~TempWork() {
        std::error_code ec;
        stdfs::remove_all(path, ec);
    }
};

}  // namespace

std::string sokol_shdc_missing_hint(const SetupContext& context) {
    std::string hint = "Run `factoria setup shaders` to install it (a pinned sokol-tools-bin commit, " + std::string(kSetupSokolShdcCommit).substr(0, 7) +
                       "), or set the environment variable SOKOL_SHDC to the path of sokol-shdc.";
    if (context.host_os() == "windows")
        hint += " Windows Defender may have quarantined sokol-shdc.exe as a false positive: restore it from Windows Security > Protection history, or point SOKOL_SHDC at a copy you trust.";
    return hint;
}

Result<ShaderCompileResult> compile_material(const std::string& projectDir, const std::string& materialPath, const ShaderCompileOptions& options) {
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

    auto raw = tooling_detail::read_file(stdfs::path(projectDir) / res.material.shader);
    if (!raw) return make_error("cannot read the snippet '" + res.material.shader + "' of " + materialPath, "Check the \"shader\" path of the material.");
    const std::string snippet = normalize_snippet(*raw);
    const std::string stripped = blank_comments(snippet);
    res.generated = generate_material_shader(res.material, snippet);
    res.errors = precheck_snippet(res.material, res.generated, snippet, stripped);
    if (!res.errors.empty()) return res;
    if (shader_template_hash().empty())
        return make_error("this factoria build has no mesh shader template (engine/render/shaders/*_common.glsl)", "Rebuild factoria from the full source tree so the template is embedded.");

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
        return make_error("sokol-shdc, the shader compiler, was not found, so the snippet '" + res.material.shader + "' cannot be compiled",
                          sokol_shdc_missing_hint(options.setup) + " A material whose twin is in .factoria/shader-cache needs no compiler.");

    TempWork work;
    bool written = tooling_detail::write_file(work.path / "top.glsl", res.generated.top) && tooling_detail::write_file(work.path / "out" / ".keep", "");
    for (const auto& [name, content] : template_files()) written = written && tooling_detail::write_file(work.path / name, content);
    if (!written) return make_error("cannot write to the temporary folder " + work.path.string(), "Check the free disk space.");

    ProcessOptions po;
    po.argv = {tool, "--input", "top.glsl", "--output", "out/m", "--format", "bare_yaml", "--errfmt", "gcc", "--slang", join(missing, ":"), "--no-log-cmdline"};
    if (!res.generated.defines.empty()) {
        po.argv.push_back("--defines");
        po.argv.push_back(join(res.generated.defines, ":"));
    }
    po.workingDir = work.path.string();
    po.timeoutSeconds = 120;
    po.cancel = options.setup.cancel;
    auto ran = options.setup.run_process_with(po);
    if (!ran.ok())
        return make_error("could not start sokol-shdc (" + tool + "): " + ran.error().message,
                          (ran.error().hint.empty() ? "Check that the file exists and is executable." : ran.error().hint) + " " + sokol_shdc_missing_hint(options.setup));
    if (ran->timedOut) return make_error("sokol-shdc did not finish in 120 seconds", "Run it by hand on the generated top file to see where it hangs.");

    if (ran->exitCode != 0) {
        MapContext ctx{res.material, res.generated, snippet, stripped, projectDir};
        res.errors = map_diagnostics(parse_diagnostics(ran->stderrText + "\n" + ran->stdoutText), ctx);
        if (res.errors.empty()) {
            ShaderIssue i;
            i.file = res.material.shader;
            i.message = "sokol-shdc failed (exit code " + std::to_string(ran->exitCode) + ") without a message it can be mapped to the snippet from: " +
                        std::string(trim(ran->stderrText.empty() ? ran->stdoutText : ran->stderrText));
            i.hint = "Run `factoria setup shaders` to be sure the pinned sokol-shdc is used, and report the message if it persists.";
            res.errors.push_back(std::move(i));
        }
        return res;
    }

    std::string yamlText;
    std::error_code ec;
    for (const auto& e : stdfs::directory_iterator(work.path / "out", ec))
        if (e.path().filename().string().ends_with("_reflection.yaml")) yamlText = tooling_detail::read_file(e.path()).value_or(std::string());
    if (yamlText.empty())
        return make_error("sokol-shdc succeeded but wrote no reflection file", "The pinned sokol-shdc writes it with --format bare_yaml; reinstall it with `factoria setup shaders`.");
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
