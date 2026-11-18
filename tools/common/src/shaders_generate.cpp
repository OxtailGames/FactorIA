// The top file around a material's snippet (docs/design/CUSTOM_SHADERS.md, "The generator"), and the text helpers the
// scanning of snippets needs.
#include <algorithm>
#include <cctype>
#include <map>
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
        "main", "surface", "vertex", "Surface", "SurfaceInput", "VertexData", "QuadInput", "QuadSurface", "QuadVertex",
        "fragment", "SkyInput", "SkySurface", "PostInput", "PostSurface"};
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
    // list is the one file the template hash was made of before kinds existed; the sprite template also @includes the colour-space
    // and 2D shadow helpers, so a change to them changes the sprite hash.
    static const std::map<std::string, std::vector<std::string>> names = {
        {"mesh", {"mesh_common.glsl"}},
        {"sprite", {"color_space.glsl", "light_shadow.glsl", "quad_common.glsl"}},
        {"sky", {"sky_common.glsl"}},
        {"post", {"post_common.glsl"}},
        {"compute", {}}};
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
        {"mesh", {"SurfaceInput", "Surface", "VertexData"}},
        {"sprite", {"QuadInput", "QuadSurface", "QuadVertex"}},
        {"sky", {"SkyInput", "SkySurface"}},
        {"post", {"PostInput", "PostSurface"}},
        {"compute", {}}};
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

bool kind_is_compiled(const std::string& kind) { return kind == "mesh" || kind == "sprite"; }

std::string kind_refusal(const std::string& kind) {
    // Sprite is compiled (M72.1); sky is the other half of M72.1.
    const char* package = kind == "post" ? "M72.2" : kind == "compute" ? "M72.4" : "M72.1";
    return "kind \"" + kind + "\" is not compiled yet: " + kind + " materials arrive with " + package;
}

}  // namespace shaders_detail

namespace {

using shaders_detail::blank_comments;
using shaders_detail::ident_char;
using shaders_detail::line_of;
using shaders_detail::normalize_snippet;

struct Function {
    std::size_t begin = 0, end = 0;  // [begin, end) of `void name(...) { ... }` in the snippet
    bool isVertex = false;           // else the fragment-stage entry point (surface() or fragment())
};

// The definitions of void <fragmentName>(...) (surface or fragment) and void vertex(...) at the top level of the
// (comment-blanked) snippet.
std::vector<Function> find_entry_points(const std::string& s, const std::string& fragmentName) {
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
        if (depth == 0 && (i == 0 || !ident_char(s[i - 1])) && s.compare(i, 4, "void") == 0 &&
            !(i + 4 < s.size() && ident_char(s[i + 4]))) {
            std::size_t p = skip_ws(i + 4);
            std::size_t nameStart = p;
            while (p < s.size() && ident_char(s[p])) ++p;
            const std::string name = s.substr(nameStart, p - nameStart);
            if (name == fragmentName || name == "vertex") {
                p = skip_ws(p);
                if (p < s.size() && s[p] == '(') {
                    int paren = 0;
                    while (p < s.size()) {
                        if (s[p] == '(')
                            ++paren;
                        else if (s[p] == ')' && --paren == 0)
                            break;
                        ++p;
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
                            out.push_back({i, p + 1, name == "vertex"});
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

GeneratedShader generate_material_shader(const MaterialDef& material, std::string_view snippetText) {
    GeneratedShader g;
    g.kind = material.kind;
    const bool sprite = material.kind == "sprite";
    const bool clip = material.alphaMode == "clip";
    const std::string src = normalize_snippet(snippetText);
    const std::vector<Function> fns = find_entry_points(blank_comments(src), sprite ? "fragment" : "surface");
    for (const Function& f : fns) (f.isVertex ? g.hasVertex : g.hasSurface) = true;

    TopFile t{g};
    t.generated("@module fa_mat\n@block fa_user\n");
    // The material block lives in one stage: a sokol uniform block slot belongs to one stage, so the vertex stage gets its own
    // block (binding 4) and the fragment stage (binding 5). Unused blocks and textures are not part of a program. The textures
    // take the slots after the engine's own (mesh: views 6.., samplers 2..; sprite: views 4.., samplers 3..; kMaterial* of
    // engine/render/src/render_internal.h).
    t.generated("#ifdef GL_VERTEX_SHADER\n");
    if (!material.params.empty())
        t.generated("layout(binding=4) uniform fa_material_vs {\n" + block_members(material.params) + "};\n");
    // Helpers that sample a texture or discard still compile in the vertex stage.
    t.generated("#define texture(s, uv) textureLod(s, uv, 0.0)\n#define discard\n");
    t.generated("#else\n");
    if (!material.params.empty())
        t.generated("layout(binding=5) uniform fa_material {\n" + block_members(material.params) + "};\n");
    t.generated("#endif\n");
    int view = sprite ? 4 : 6, sampler = sprite ? 3 : 2;
    for (const MaterialTexture& tex : material.textures)
        t.generated("layout(binding=" + std::to_string(view++) + ") uniform texture2D " + tex.name +
                    ";\nlayout(binding=" + std::to_string(sampler++) + ") uniform sampler " + tex.name + "_smp;\n");

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
    t.generated("#ifdef GL_VERTEX_SHADER\n#undef texture\n#undef discard\n#endif\n");
    t.generated(sprite ? "@end\n@include quad_common.glsl\n" : "@end\n@include mesh_common.glsl\n");

    if (sprite) {
        // quad: every mode; quad_plain: the lean program of a batch of plain textured quads (the renderer picks one per batch).
        g.programs = {"quad", "quad_plain"};
        t.generated("@program quad vs fs\n@program quad_plain vs fs_plain\n");
        g.defines.push_back("FA_MATERIAL");
    } else {
        g.programs = {"mesh", "mesh_skin"};
        t.generated("@program mesh vs fs\n@program mesh_skin vs_skin fs\n");
        if (g.hasVertex || clip) {
            g.programs.push_back("shadow");
            g.programs.push_back("shadow_skin");
            t.generated("@program shadow shadow_vs shadow_fs\n@program shadow_skin shadow_vs_skin shadow_fs\n");
        }
        // The depth and normal prepass (M71) draws every opaque material: vertex() and surface() run in it as in the main pass.
        g.programs.push_back("prepass");
        g.programs.push_back("prepass_skin");
        t.generated("@program prepass prepass_vs prepass_fs\n@program prepass_skin prepass_vs_skin prepass_fs\n");
    }
    if (g.hasVertex) g.defines.push_back("FA_HAS_VERTEX");
    // A sprite is blended by the engine: alphaMode "clip" (the mesh template's alpha test) adds nothing to it.
    if (clip && !sprite) g.defines.push_back("FA_ALPHA_CLIP");
    return g;
}

}  // namespace fa
