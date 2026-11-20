// The top file around a material's snippet (docs/design/CUSTOM_SHADERS.md, "The generator"), and the text helpers the
// scanning of snippets needs.
#include <algorithm>
#include <cctype>
#include <map>
#include <regex>
#include <set>

#include "fa/tooling/bundle.h"
#include "fa/tooling/shaders.h"
#include "shaders_internal.h"

namespace fa {

namespace shaders_detail {

bool ident_char(char c) { return std::isalnum(static_cast<unsigned char>(c)) || c == '_'; }

std::string blank_comments(std::string_view text) {
    std::string out(text);
    for (std::size_t i = 0; i < out.size();) {
        if (out[i] == '/' && i + 1 < out.size() && out[i + 1] == '/') {
            while (i < out.size() && out[i] != '\n') out[i++] = ' ';
        } else if (out[i] == '/' && i + 1 < out.size() && out[i + 1] == '*') {
            out[i++] = ' ';
            out[i++] = ' ';
            while (i < out.size() && !(out[i] == '*' && i + 1 < out.size() && out[i + 1] == '/')) {
                if (out[i] != '\n') out[i] = ' ';
                ++i;
            }
            if (i < out.size()) {
                out[i++] = ' ';
                out[i++] = ' ';
            }
        } else {
            ++i;
        }
    }
    return out;
}

bool is_identifier(std::string_view s) {
    if (s.empty() || std::isdigit(static_cast<unsigned char>(s[0]))) return false;
    return std::all_of(s.begin(), s.end(), ident_char);
}

bool is_reserved_word(std::string_view s) {
    static const std::set<std::string, std::less<>> words = {
        // keywords of GLSL 4.50 and the words it reserves
        "attribute", "const", "uniform", "varying", "buffer", "shared", "coherent", "volatile", "restrict", "readonly",
        "writeonly", "atomic_uint", "layout", "centroid", "flat", "smooth", "noperspective", "patch", "sample", "break",
        "continue", "do", "for", "while", "switch", "case", "default", "if", "else", "subroutine", "in", "out", "inout",
        "int", "void", "bool", "true", "false", "float", "double", "discard", "return", "vec2", "vec3", "vec4", "ivec2",
        "ivec3", "ivec4", "bvec2", "bvec3", "bvec4", "uint", "uvec2", "uvec3", "uvec4", "dvec2", "dvec3", "dvec4",
        "mat2", "mat3", "mat4", "mat2x2", "mat2x3", "mat2x4", "mat3x2", "mat3x3", "mat3x4", "mat4x2", "mat4x3",
        "mat4x4", "dmat2", "dmat3", "dmat4", "lowp", "mediump", "highp", "precision", "sampler", "sampler2D",
        "sampler3D", "samplerCube", "sampler2DShadow", "sampler2DArray", "texture2D", "texture3D", "textureCube",
        "image2D", "struct", "invariant", "precise", "common", "partition", "active", "asm", "class", "union", "enum",
        "typedef", "template", "this", "resource", "goto", "inline", "noinline", "public", "static", "extern",
        "external", "interface", "long", "short", "half", "fixed", "unsigned", "superp", "input", "output", "filter",
        "sizeof", "cast", "namespace", "using",
        // names of the snippet contract
        "main", "surface", "vertex", "Surface", "SurfaceInput", "VertexData", "LightSample", "QuadInput", "QuadSurface",
        "QuadVertex", "fragment", "SkyInput", "SkySurface", "PostInput", "PostSurface", "compute", "ComputeInput",
        "vertex_uv1", "vertex_color1",
        // a name sokol-shdc cannot take for a texture ("no binding found for texture ''")
        "noise"};
    return words.count(s) > 0;
}

int line_of(std::string_view text, std::size_t offset) {
    return 1 + int(std::count(text.begin(), text.begin() + std::min(offset, text.size()), '\n'));
}

int column_of(std::string_view text, std::size_t offset) {
    offset = std::min(offset, text.size());
    const std::size_t nl = text.rfind('\n', offset == 0 ? 0 : offset - 1);
    if (offset == 0 || nl == std::string_view::npos) return int(offset);
    return int(offset - nl - 1);
}

std::string line_text(std::string_view text, int line) {
    std::size_t start = 0;
    for (int l = 1; l < line; ++l) {
        start = text.find('\n', start);
        if (start == std::string_view::npos) return {};
        ++start;
    }
    std::size_t end = text.find('\n', start);
    std::string out(text.substr(start, end == std::string_view::npos ? std::string_view::npos : end - start));
    while (!out.empty() && (out.back() == '\r' || out.back() == ' ' || out.back() == '\t')) out.pop_back();
    return out;
}

std::string normalize_snippet(std::string_view snippet) {
    std::string out;
    out.reserve(snippet.size());
    for (char c : snippet)
        if (c != '\r') out += c;
    return out;
}

const std::vector<std::string>& template_file_names(const std::string& kind) {
    // One list per kind, equal to FA_TEMPLATE_FILES_<KIND> of engine/render/CMakeLists.txt (a test compares the hashes). The mesh
    // list holds mesh_common.glsl and the lighting files it @includes; the sprite template also @includes the colour-space
    // and 2D shadow helpers, so a change to them changes the sprite hash.
    static const std::map<std::string, std::vector<std::string>> names = {
        {"mesh", {"mesh_common.glsl", "light_data.glsl", "light_loop.glsl", "shadow_common.glsl", "brdf_layers.glsl"}},
        // A mesh material in "full" mode: not a MaterialKind, a second template of the mesh kind (engine/render/CMakeLists.txt,
        // FA_TEMPLATE_FILES_MESH_FULL); the mesh template's files are in both lists, so a change to one makes both hashes change.
        {"mesh-full",
         {"mesh_common.glsl", "light_data.glsl", "light_loop.glsl", "shadow_common.glsl", "brdf_layers.glsl",
          "mesh_full_common.glsl"}},
        {"sprite", {"color_space.glsl", "light_shadow.glsl", "quad_common.glsl"}},
        {"sky", {"color_space.glsl", "sky_common.glsl"}},
        {"post", {"post_common.glsl"}},
        {"compute", {"compute_common.glsl"}}};
    static const std::vector<std::string> none;
    auto it = names.find(kind);
    return it == names.end() ? none : it->second;
}

std::vector<std::pair<std::string, std::string>> template_files(const std::string& kind) {
    std::vector<std::pair<std::string, std::string>> out;
    for (const std::string& name : template_file_names(kind)) {
        auto content = bundled_read("engine/render/shaders/" + name);
        if (!content) continue;
        out.emplace_back(name, *content);
    }
    std::sort(out.begin(), out.end());
    return out;
}

const std::vector<std::pair<std::string, std::vector<std::string>>>& contract_structs(const std::string& kind) {
    using Structs = std::vector<std::pair<std::string, std::vector<std::string>>>;
    // The structs each kind's snippet contract is made of (the template's @block of types).
    static const std::map<std::string, std::vector<std::string>> wantedByKind = {
        {"mesh", {"SurfaceInput", "Surface", "VertexData", "LightSample"}},
        {"sprite", {"QuadInput", "QuadSurface", "QuadVertex"}},
        {"sky", {"SkyInput", "SkySurface"}},
        {"post", {"PostInput", "PostSurface"}},
        {"compute", {"ComputeInput"}}};
    static const std::map<std::string, Structs> byKind = [] {
        std::map<std::string, Structs> result;
        for (const auto& [kindName, wantedList] : wantedByKind) {
            Structs out;
            std::string all;
            for (auto& [name, content] : template_files(kindName)) all += blank_comments(content) + "\n";
            for (const std::string& wanted : wantedList) {
                std::size_t pos = 0;
                while ((pos = all.find("struct " + wanted + " ", pos)) != std::string::npos) {
                    const std::size_t open = all.find('{', pos), close = all.find('}', pos);
                    if (open == std::string::npos || close == std::string::npos || close < open) break;
                    std::vector<std::string> fields;
                    std::string body = all.substr(open + 1, close - open - 1);
                    std::size_t from = 0;
                    while (from < body.size()) {
                        std::size_t semi = body.find(';', from);
                        if (semi == std::string::npos) break;
                        std::string decl = body.substr(from, semi - from);
                        from = semi + 1;
                        while (!decl.empty() && std::isspace(static_cast<unsigned char>(decl.back()))) decl.pop_back();
                        std::size_t b = decl.size();
                        while (b > 0 && ident_char(decl[b - 1])) --b;
                        if (b < decl.size()) fields.push_back(decl.substr(b));
                    }
                    out.emplace_back(wanted, std::move(fields));
                    break;
                }
            }
            result[kindName] = std::move(out);
        }
        return result;
    }();
    static const Structs none;
    auto it = byKind.find(kind);
    return it == byKind.end() ? none : it->second;
}

namespace {

using NameSet = std::set<std::string, std::less<>>;

// The last identifier of `text` (after dropping a trailing `[...]`), "" when there is none.
std::string last_identifier(std::string text) {
    while (!text.empty() && (std::isspace(static_cast<unsigned char>(text.back())) || text.back() == ']')) {
        if (text.back() == ']') {
            const std::size_t open = text.rfind('[');
            if (open == std::string::npos) break;
            text.resize(open);
        } else {
            text.pop_back();
        }
    }
    std::size_t b = text.size();
    while (b > 0 && ident_char(text[b - 1])) --b;
    return text.substr(b);
}

// The identifier that precedes the first '(' of `text` (a function's name), "" when there is none.
std::string name_before_paren(const std::string& text) {
    const std::size_t paren = text.find('(');
    return paren == std::string::npos ? std::string() : last_identifier(text.substr(0, paren));
}

// `stmt` without its `layout(...)` qualifier.
void strip_layout(std::string& stmt) {
    const std::size_t layout = stmt.find("layout");
    if (layout == std::string::npos) return;
    const std::size_t open = stmt.find('(', layout);
    int depth = 0;
    for (std::size_t i = open; open != std::string::npos && i < stmt.size(); ++i) {
        depth += stmt[i] == '(' ? 1 : stmt[i] == ')' ? -1 : 0;
        if (depth == 0) {
            stmt.erase(layout, i + 1 - layout);
            return;
        }
    }
}

// The names a declaration statement (without its ';') declares: `layout(...) uniform texture2D tex`, `vec4 a, b[16]`,
// `const float k = 1.0`, `float f(float x)` (a prototype).
void declared_names(std::string stmt, NameSet& out) {
    strip_layout(stmt);
    const std::size_t paren = stmt.find('('), eq = stmt.find('=');
    if (paren != std::string::npos && (eq == std::string::npos || paren < eq)) {  // a function prototype
        const std::string name = name_before_paren(stmt);
        if (!name.empty()) out.insert(name);
        return;
    }
    int depth = 0;
    std::size_t from = 0;
    for (std::size_t i = 0; i <= stmt.size(); ++i) {
        if (i < stmt.size()) {
            depth += (stmt[i] == '(' || stmt[i] == '[') ? 1 : (stmt[i] == ')' || stmt[i] == ']') ? -1 : 0;
            if (stmt[i] != ',' || depth != 0) continue;
        }
        std::string piece = stmt.substr(from, i - from);
        from = i + 1;
        if (const std::size_t e = piece.find('='); e != std::string::npos) piece.resize(e);
        const std::string name = last_identifier(piece);
        if (!name.empty() && name != "uniform" && name != "struct") out.insert(name);
    }
}

// Every name the top level of a GLSL text declares (variables, in/out, textures, samplers, functions, structs, uniform
// blocks and their members, #define names). Locals of function bodies are not globals.
void scan_globals(const std::string& text, NameSet& out) {
    std::string stmt;
    bool lineStart = true;
    for (std::size_t i = 0; i < text.size(); ++i) {
        const char c = text[i];
        if (c == '\n') {
            lineStart = true;
            stmt += ' ';
            continue;
        }
        if (lineStart && std::isspace(static_cast<unsigned char>(c))) {
            stmt += c;
            continue;
        }
        if (lineStart && (c == '#' || c == '@')) {  // a preprocessor line or a sokol-shdc tag: not part of a statement
            std::size_t end = text.find('\n', i);
            if (end == std::string::npos) end = text.size();
            const std::string line = text.substr(i, end - i);
            if (line.rfind("#define", 0) == 0) {
                std::size_t b = 7;
                while (b < line.size() && std::isspace(static_cast<unsigned char>(line[b]))) ++b;
                std::size_t e = b;
                while (e < line.size() && ident_char(line[e])) ++e;
                if (e > b) out.insert(line.substr(b, e - b));
            }
            i = end - 1;
            continue;
        }
        lineStart = false;
        if (c == ';') {
            declared_names(stmt, out);
            stmt.clear();
        } else if (c == '{') {
            std::size_t close = i;
            for (int depth = 0; close < text.size(); ++close) {
                depth += text[close] == '{' ? 1 : text[close] == '}' ? -1 : 0;
                if (depth == 0) break;
            }
            if (close >= text.size()) return;
            const std::string body = text.substr(i + 1, close - i - 1);
            strip_layout(stmt);
            const bool isFunction = stmt.find('(') != std::string::npos;
            if (isFunction) {
                const std::string name = name_before_paren(stmt);
                if (!name.empty()) out.insert(name);
            } else {
                const std::string name = last_identifier(stmt);
                if (!name.empty()) out.insert(name);              // a struct or a uniform block
                if (stmt.find("uniform") != std::string::npos) {  // the members of a block are globals too
                    std::size_t from = 0;
                    while (from < body.size()) {
                        const std::size_t semi = body.find(';', from);
                        if (semi == std::string::npos) break;
                        declared_names(body.substr(from, semi - from), out);
                        from = semi + 1;
                    }
                }
                std::size_t semi = text.find(';', close);  // an instance name between '}' and ';'
                if (semi == std::string::npos) semi = text.size();
                declared_names(text.substr(close + 1, semi - close - 1), out);
                close = std::min(semi, text.size() - 1);
            }
            stmt.clear();
            i = close;
        } else {
            stmt += c;
        }
    }
}

}  // namespace

const std::set<std::string, std::less<>>& template_globals(const std::string& kind) {
    // The names the template of a kind declares at the top level of its program, unprefixed (the prefixed ones are covered
    // by the fa_ rule): a param or texture with one of them would redefine it. Derived from the bundled template so the
    // list cannot drift. Only the sprite, sky and post templates have any: their snippet is spliced into a program whose inputs, varyings and
    // helpers are not prefixed (the mesh template keeps its own names out of the snippet's way by other means).
    static const std::map<std::string, NameSet> byKind = [] {
        std::map<std::string, NameSet> result;
        for (const char* kind : {"sprite", "sky", "post"}) {
            NameSet names;
            for (const auto& [name, content] : template_files(kind)) scan_globals(blank_comments(content), names);
            result[kind] = std::move(names);
        }
        return result;
    }();
    static const NameSet none;
    auto it = byKind.find(kind);
    return it == byKind.end() ? none : it->second;
}

}  // namespace shaders_detail

namespace {

using shaders_detail::blank_comments;
using shaders_detail::ident_char;
using shaders_detail::line_of;
using shaders_detail::normalize_snippet;

struct Function {
    std::size_t begin = 0, end = 0;  // [begin, end) of `name(...) { ... }` in the snippet
    bool isVertex = false;           // vertex stage; else the fragment stage
    bool isSurface = false, isLight = false, isAmbient = false,
         isLighting = false;  // isSurface: surface() or, in a sprite material, fragment()
};

// The definitions of void <fragmentName>(...) (surface, or fragment in a sprite material), void vertex(...) and, with lighting
// "custom", vec3 light(...) and vec3 ambient(...) at the top level of the (comment-blanked) snippet. In a pbr or unlit
// material `light` and `ambient` are ordinary names (a helper may be called that and run in both stages). vec3 lighting(in
// SurfaceInput i, ...) (the whole light loop) is an entry point in a mesh material of any lighting (a pbr one is refused by the
// compiler, with the reason); a function called lighting with other parameters is an ordinary name.
std::vector<Function> find_entry_points(const std::string& s, const std::string& fragmentName, bool customLighting,
                                        bool mesh) {
    std::vector<Function> out;
    int depth = 0;
    std::size_t i = 0;
    auto skip_ws = [&](std::size_t p) {
        while (p < s.size() && std::isspace(static_cast<unsigned char>(s[p]))) ++p;
        return p;
    };
    while (i < s.size()) {
        const char c = s[i];
        if (c == '{') {
            ++depth;
            ++i;
            continue;
        }
        if (c == '}') {
            depth = std::max(0, depth - 1);
            ++i;
            continue;
        }
        const bool isVoid = s.compare(i, 4, "void") == 0 && !(i + 4 < s.size() && ident_char(s[i + 4]));
        const bool isVec3 =
            (customLighting || mesh) && s.compare(i, 4, "vec3") == 0 && !(i + 4 < s.size() && ident_char(s[i + 4]));
        if (depth == 0 && (i == 0 || !ident_char(s[i - 1])) && (isVoid || isVec3)) {
            std::size_t p = skip_ws(i + 4);
            std::size_t nameStart = p;
            while (p < s.size() && ident_char(s[p])) ++p;
            const std::string name = s.substr(nameStart, p - nameStart);
            if ((isVoid && (name == fragmentName || name == "vertex")) ||
                (isVec3 && customLighting && (name == "light" || name == "ambient")) ||
                (isVec3 && name == "lighting")) {
                p = skip_ws(p);
                if (p < s.size() && s[p] == '(') {
                    const std::size_t paramsBegin = p;
                    int paren = 0;
                    while (p < s.size()) {
                        if (s[p] == '(')
                            ++paren;
                        else if (s[p] == ')' && --paren == 0)
                            break;
                        ++p;
                    }
                    // lighting() is the hook only with the contract's parameters, (in SurfaceInput i, in Surface s): another
                    // `lighting` (other types, another order, another count) is a helper.
                    static const std::regex lightingParams(
                        R"(^\(\s*(?:in\s+)?SurfaceInput\s+\w+\s*,\s*(?:in\s+)?Surface\s+\w+\s*$)");
                    if (name == "lighting" &&
                        !std::regex_match(s.substr(paramsBegin, p - paramsBegin), lightingParams)) {
                        ++i;
                        continue;
                    }
                    p = skip_ws(p + 1);
                    if (p < s.size() && s[p] == '{') {
                        int brace = 0;
                        while (p < s.size()) {
                            if (s[p] == '{')
                                ++brace;
                            else if (s[p] == '}' && --brace == 0)
                                break;
                            ++p;
                        }
                        if (p < s.size()) {
                            Function f;
                            f.begin = i;
                            f.end = p + 1;
                            f.isVertex = name == "vertex";
                            f.isSurface = name == fragmentName;
                            f.isLight = name == "light";
                            f.isAmbient = name == "ambient";
                            f.isLighting = name == "lighting";
                            out.push_back(f);
                            i = p + 1;
                            continue;
                        }
                    }
                }
            }
        }
        ++i;
    }
    return out;
}

// Builds the top file line by line, remembering which lines hold the snippet.
struct TopFile {
    GeneratedShader& g;

    void generated(std::string_view text) {
        g.top += text;
        for (char c : text)
            if (c == '\n') g.snippetLine.push_back(0);
    }
    // The snippet text [begin, end), starting on a new line of the top file.
    void snippet(const std::string& src, std::size_t begin, std::size_t end) {
        if (begin >= end) return;
        int line = line_of(src, begin);
        for (std::size_t i = begin; i < end;) {
            std::size_t nl = src.find('\n', i);
            const std::size_t stop = (nl == std::string::npos || nl >= end) ? end : nl;
            g.top.append(src, i, stop - i);
            g.top += '\n';
            g.snippetLine.push_back(line);
            ++line;
            i = stop + 1;
        }
    }
};

std::string block_members(const std::vector<MaterialParam>& params) {
    std::string out;
    int pad = 0;
    auto padding = [&](int count) {
        std::string p;
        for (int i = 0; i < count; ++i) p += " float fa_pad" + std::to_string(pad++) + ";";
        return p;
    };
    for (const MaterialParam& p : params) {
        const int n = p.components();
        const std::string type = n == 1 ? "float" : "vec" + std::to_string(n);
        out += "    " + type + " " + p.name + ";" + padding(4 - n) + "\n";
    }
    return out;
}

}  // namespace

namespace shaders_detail {

std::string material_prologue(const MaterialDef& material, std::string& vsUndefs) {
    const bool sprite = material.kind == "sprite", sky = material.kind == "sky", post = material.kind == "post";
    std::string text;
    auto gen = [&text](const std::string& piece) { text += piece; };
    // The params of the uniform block (one value per draw) and the instanced ones (a value per instance, read from the instance
    // buffer into plain globals before vertex() and surface() run, so the snippet reads them by the same name).
    std::vector<MaterialParam> blockParams;
    for (const MaterialParam& p : material.params)
        if (!p.instanced) blockParams.push_back(p);
    const InstanceLayout instLayout = instance_layout(material.params);
    // The material block lives in one stage: a sokol uniform block slot belongs to one stage, so the vertex stage gets its own
    // block (binding 4) and the fragment stage (binding 5). Unused blocks and textures are not part of a program. The textures
    // take the slots after the engine's own (mesh: views 6.., samplers 2..; sprite: views 4.., samplers 3..; kMaterial* of
    // engine/render/src/render_internal.h).
    gen("#ifdef GL_VERTEX_SHADER\n");
    if (!blockParams.empty()) gen("layout(binding=4) uniform fa_material_vs {\n" + block_members(blockParams) + "};\n");
    // Helpers that sample a texture or discard still compile in the vertex stage.
    gen("#define texture(s, uv) textureLod(s, uv, 0.0)\n#define discard\n");
    gen("#else\n");
    if (!blockParams.empty()) gen("layout(binding=5) uniform fa_material {\n" + block_members(blockParams) + "};\n");
    gen("#endif\n");
    if (instLayout.vec4Count > 0) {
        static const char* kLetters = "xyzw";
        std::string globals, unpack;
        for (const InstanceSlot& s : instLayout.slots) {
            const std::string type = s.components == 1 ? "float" : "vec" + std::to_string(s.components);
            globals += type + " " + s.name + ";\n";
            const std::string from = "fa_d" + std::to_string(s.vec4);
            unpack += "    " + s.name + " = " + from +
                      (s.components == 4 ? "" : "." + std::string(kLetters + s.offset, std::size_t(s.components))) +
                      ";\n";
        }
        gen("// Instanced params: set from the instance buffer before vertex() and surface() run.\n" + globals +
            "void fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2) {\n" + unpack + "}\n");
    }
    if (std::find(material.vertexAttributes.begin(), material.vertexAttributes.end(), "uv1") !=
        material.vertexAttributes.end())
        gen("#ifdef GL_VERTEX_SHADER\nvec2 vertex_uv1;\n#endif\n");
    if (std::find(material.vertexAttributes.begin(), material.vertexAttributes.end(), "color1") !=
        material.vertexAttributes.end())
        gen("#ifdef GL_VERTEX_SHADER\nvec4 vertex_color1;\n#endif\n");
    std::string vsDefines, vsDecls, fsDecls;
    if (sky || post) {
        // A sky material has no vertex() and no engine texture: its textures are declared once, in the fragment stage, at views 0..
        // and samplers 0... A post material's are views 2.. and samplers 2..: its pass is a full-screen triangle whose vertex stage has
        // no material.
        int view = sky ? kMaterialSkyFirstView : kMaterialPostFirstView;
        int sampler = sky ? kMaterialSkyFirstSampler : kMaterialPostFirstSampler;
        for (const MaterialTexture& tex : material.textures)
            gen("layout(binding=" + std::to_string(view++) + ") uniform texture2D " + tex.name +
                ";\nlayout(binding=" + std::to_string(sampler++) + ") uniform sampler " + tex.name + "_smp;\n");
    } else {
        // A mesh or sprite material's texture is declared once per stage: a sokol view or sampler slot belongs to one stage, and sokol-shdc
        // refuses one name in both. A mesh's fragment stage reads it at view 6.. and sampler 2.., a sprite's at view 4.. and sampler 3..
        // (after the engine's own); the vertex stage (where the #define renames it for the snippet, so the author writes `height` in both)
        // reads it at the slots after those (mesh: view 10.., sampler 6..; sprite: view 8.., sampler 7..). A declaration the stage does
        // not use is not part of its program, so the runtime binds both slots (renderer_draw.cpp bind_textures, draw_group) and each
        // program takes what it declares.
        int view = sprite ? kMaterialSpriteFirstView : kMaterialFsFirstView;
        int sampler = sprite ? kMaterialSpriteFirstSampler : kMaterialFsFirstSampler;
        int vsView = sprite ? kMaterialSpriteVsFirstView : kMaterialVsFirstView;
        int vsSampler = sprite ? kMaterialSpriteVsFirstSampler : kMaterialVsFirstSampler;
        for (const MaterialTexture& tex : material.textures) {
            vsDefines += "#define " + tex.name + " fa_vs_" + tex.name + "\n#define " + tex.name + "_smp fa_vs_" +
                         tex.name + "_smp\n";
            vsUndefs += "#undef " + tex.name + "\n#undef " + tex.name + "_smp\n";
            vsDecls += "layout(binding=" + std::to_string(vsView++) + ") uniform texture2D " + tex.name +
                       ";\nlayout(binding=" + std::to_string(vsSampler++) + ") uniform sampler " + tex.name + "_smp;\n";
            fsDecls += "layout(binding=" + std::to_string(view++) + ") uniform texture2D " + tex.name +
                       ";\nlayout(binding=" + std::to_string(sampler++) + ") uniform sampler " + tex.name + "_smp;\n";
        }
        // The read-only storage buffers of a mesh material (M72.4), declared like the textures once per stage: the element struct
        // `<name>_item` once, the vertex stage's copy as fa_vs_<name> (renamed for the snippet) at view 16.., the fragment stage's
        // after those. The snippet reads `<name>.data[i].<field>`, as a compute material does.
        if (!material.buffers.empty()) {
            const int count = int(material.buffers.size());
            std::string structs;
            for (const MaterialBuffer& b : material.buffers) {
                structs += "struct " + b.name + "_item {";
                for (const MaterialBufferField& f : b.fields) structs += " " + f.type + " " + f.name + ";";
                structs += " };\n";
                vsDefines += "#define " + b.name + " fa_vs_" + b.name + "\n";
                vsUndefs += "#undef " + b.name + "\n";
                vsDecls += "layout(binding=" + std::to_string(kMeshBufferFirstView + b.binding) +
                           ") readonly buffer fa_vs_" + b.name + "_buf { " + b.name + "_item data[]; } " + b.name +
                           ";\n";
                fsDecls += "layout(binding=" + std::to_string(kMeshBufferFirstView + count + b.binding) +
                           ") readonly buffer fa_" + b.name + "_buf { " + b.name + "_item data[]; } " + b.name + ";\n";
            }
            gen(structs);
        }
        if (!vsDecls.empty()) gen("#ifdef GL_VERTEX_SHADER\n" + vsDefines + vsDecls + "#else\n" + fsDecls + "#endif\n");
    }
    return text;
}

}  // namespace shaders_detail

GeneratedShader generate_material_shader(const MaterialDef& material, std::string_view snippetText) {
    if (material.kind == "compute") return generate_compute_shader(material, snippetText);
    if (material.full) return generate_full_shader(material, snippetText);
    GeneratedShader g;
    g.kind = material.kind;
    const bool sprite = material.kind == "sprite", sky = material.kind == "sky", post = material.kind == "post";
    // A post material has no alpha test and no light(): parse_material refuses the keys that ask for them.
    const bool clip = material.alphaMode == "clip" && !post;
    const std::string src = normalize_snippet(snippetText);
    // Only a mesh has light(): a sprite is lit by the 2D pipeline, a sky and a post pass are not lit.
    const bool custom = material.kind == "mesh" && material.lighting == "custom";
    const std::vector<Function> fns = find_entry_points(blank_comments(src),
                                                        sprite ? "fragment"
                                                        : sky  ? "sky"
                                                        : post ? "post"
                                                               : "surface",
                                                        custom, material.kind == "mesh");
    for (const Function& f : fns) {
        g.hasVertex = g.hasVertex || f.isVertex;
        g.hasSurface = g.hasSurface || f.isSurface;
        g.hasLight = g.hasLight || f.isLight;
        g.hasAmbient = g.hasAmbient || f.isAmbient;
        g.hasLighting = g.hasLighting || (f.isLighting && custom);
        g.lightingWithoutCustom = g.lightingWithoutCustom || (f.isLighting && !custom);
    }

    const InstanceLayout instLayout = instance_layout(material.params);

    TopFile t{g};
    t.generated("@module fa_mat\n@block fa_user\n");
    std::string vsUndefs;
    t.generated(shaders_detail::material_prologue(material, vsUndefs));

    std::size_t pos = 0;
    for (const Function& f : fns) {
        t.snippet(src, pos, f.begin);
        t.generated(f.isVertex ? "#ifdef GL_VERTEX_SHADER\n" : "#ifdef GL_FRAGMENT_SHADER\n");
        t.snippet(src, f.begin, f.end);
        t.generated("#endif\n");
        pos = f.end;
    }
    t.snippet(src, pos, src.size());
    // The shims stop at the snippet: the engine's own vertex code below sees the real texture() and discard.
    t.generated("#ifdef GL_VERTEX_SHADER\n#undef texture\n#undef discard\n" + vsUndefs + "#endif\n");
    t.generated(post     ? "@end\n@include post_common.glsl\n"
                : sky    ? "@end\n@include sky_common.glsl\n"
                : sprite ? "@end\n@include quad_common.glsl\n"
                         : "@end\n@include mesh_common.glsl\n");

    if (post) {
        g.programs = {"post"};
        t.generated("@program post vs fs\n");
    } else if (sky) {
        g.programs = {"sky"};
        t.generated("@program sky vs fs\n");
    } else if (sprite) {
        // quad: every mode; quad_plain: the lean program of a batch of plain textured quads (the renderer picks one per batch).
        g.programs = {"quad", "quad_plain"};
        t.generated("@program quad vs fs\n@program quad_plain vs fs_plain\n");
        g.defines.push_back("FA_MATERIAL");
    } else {
        g.programs = {"mesh", "mesh_skin"};
        t.generated("@program mesh vs fs\n@program mesh_skin vs_skin fs\n");
        // A material with buffers always has its own shadow program: the engine's would draw the one base mesh, not the instances.
        if (g.hasVertex || clip || !material.buffers.empty()) {
            g.programs.push_back("shadow");
            g.programs.push_back("shadow_skin");
            t.generated("@program shadow shadow_vs shadow_fs\n@program shadow_skin shadow_vs_skin shadow_fs\n");
        }
        // The depth and normal prepass (M71) draws every opaque material: vertex() and surface() run in it as in the main pass.
        g.programs.push_back("prepass");
        g.programs.push_back("prepass_skin");
        t.generated("@program prepass prepass_vs prepass_fs\n@program prepass_skin prepass_vs_skin prepass_fs\n");
    }
    if (g.hasVertex && !sky && !post)
        g.defines.push_back("FA_HAS_VERTEX");  // a sky and a post pass have no vertex(): the precheck refuses one
    if (custom) g.defines.push_back("FA_CUSTOM_LIGHT");
    if (custom && g.hasAmbient) g.defines.push_back("FA_HAS_AMBIENT");
    if (custom && g.hasLighting) g.defines.push_back("FA_HAS_LIGHTING");
    // A sprite is blended by the engine: alphaMode "clip" (the mesh template's alpha test) adds nothing to it.
    if (clip && material.kind == "mesh") g.defines.push_back("FA_ALPHA_CLIP");
    // The instance data and the declared mesh channels (the template declares the matching vertex attributes after the
    // instance matrix, see mesh_common.glsl): flags, since a #define inside fa_user would come after the declarations.
    if (instLayout.vec4Count > 0) g.defines.push_back("FA_INST_" + std::to_string(std::min(instLayout.vec4Count, 3)));
    for (const std::string& a : material.vertexAttributes)
        g.defines.push_back(a == "uv1" ? "FA_CH_UV1" : "FA_CH_COLOR1");
    // The model matrix comes from a uniform block (one entity, MeshRenderer.instances GPU instances), see mesh_common.glsl.
    if (!material.buffers.empty()) g.defines.push_back("FA_BUFFER_INST");
    return g;
}

}  // namespace fa
