// The top file around a material's snippet (docs/design/CUSTOM_SHADERS.md, "The generator"), and the text helpers the
// scanning of snippets needs.
#include <algorithm>
#include <cctype>
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
        "attribute", "const", "uniform", "varying", "buffer", "shared", "coherent", "volatile", "restrict", "readonly", "writeonly",
        "atomic_uint", "layout", "centroid", "flat", "smooth", "noperspective", "patch", "sample", "break", "continue", "do", "for",
        "while", "switch", "case", "default", "if", "else", "subroutine", "in", "out", "inout", "int", "void", "bool", "true", "false",
        "float", "double", "discard", "return", "vec2", "vec3", "vec4", "ivec2", "ivec3", "ivec4", "bvec2", "bvec3", "bvec4", "uint",
        "uvec2", "uvec3", "uvec4", "dvec2", "dvec3", "dvec4", "mat2", "mat3", "mat4", "mat2x2", "mat2x3", "mat2x4", "mat3x2", "mat3x3",
        "mat3x4", "mat4x2", "mat4x3", "mat4x4", "dmat2", "dmat3", "dmat4", "lowp", "mediump", "highp", "precision", "sampler", "sampler2D",
        "sampler3D", "samplerCube", "sampler2DShadow", "sampler2DArray", "texture2D", "texture3D", "textureCube", "image2D", "struct",
        "invariant", "precise", "common", "partition", "active", "asm", "class", "union", "enum", "typedef", "template", "this", "resource",
        "goto", "inline", "noinline", "public", "static", "extern", "external", "interface", "long", "short", "half", "fixed", "unsigned",
        "superp", "input", "output", "filter", "sizeof", "cast", "namespace", "using",
        // names of the snippet contract
        "main", "surface", "vertex", "Surface", "SurfaceInput", "VertexData"};
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

std::vector<std::pair<std::string, std::string>> template_files() {
    std::vector<std::pair<std::string, std::string>> out;
    for (const std::string& path : bundled_list("engine/render/shaders/")) {
        if (!path.ends_with("_common.glsl")) continue;
        auto content = bundled_read(path);
        if (!content) continue;
        out.emplace_back(path.substr(path.rfind('/') + 1), *content);
    }
    std::sort(out.begin(), out.end());
    return out;
}

const std::vector<std::pair<std::string, std::vector<std::string>>>& contract_structs() {
    static const std::vector<std::pair<std::string, std::vector<std::string>>> structs = [] {
        std::vector<std::pair<std::string, std::vector<std::string>>> out;
        std::string all;
        for (auto& [name, content] : template_files()) all += blank_comments(content) + "\n";
        for (const std::string wanted : {"SurfaceInput", "Surface", "VertexData"}) {
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
        return out;
    }();
    return structs;
}

}  // namespace shaders_detail

namespace {

using shaders_detail::blank_comments;
using shaders_detail::ident_char;
using shaders_detail::line_of;
using shaders_detail::normalize_snippet;

struct Function {
    std::size_t begin = 0, end = 0;  // [begin, end) of `void name(...) { ... }` in the snippet
    bool isVertex = false;           // else surface()
};

// The definitions of void surface(...) and void vertex(...) at the top level of the (comment-blanked) snippet.
std::vector<Function> find_entry_points(const std::string& s) {
    std::vector<Function> out;
    int depth = 0;
    std::size_t i = 0;
    auto skip_ws = [&](std::size_t p) {
        while (p < s.size() && std::isspace(static_cast<unsigned char>(s[p]))) ++p;
        return p;
    };
    while (i < s.size()) {
        const char c = s[i];
        if (c == '{') { ++depth; ++i; continue; }
        if (c == '}') { depth = std::max(0, depth - 1); ++i; continue; }
        if (depth == 0 && (i == 0 || !ident_char(s[i - 1])) && s.compare(i, 4, "void") == 0 && !(i + 4 < s.size() && ident_char(s[i + 4]))) {
            std::size_t p = skip_ws(i + 4);
            std::size_t nameStart = p;
            while (p < s.size() && ident_char(s[p])) ++p;
            const std::string name = s.substr(nameStart, p - nameStart);
            if (name == "surface" || name == "vertex") {
                p = skip_ws(p);
                if (p < s.size() && s[p] == '(') {
                    int paren = 0;
                    while (p < s.size()) {
                        if (s[p] == '(') ++paren;
                        else if (s[p] == ')' && --paren == 0) break;
                        ++p;
                    }
                    p = skip_ws(p + 1);
                    if (p < s.size() && s[p] == '{') {
                        int brace = 0;
                        while (p < s.size()) {
                            if (s[p] == '{') ++brace;
                            else if (s[p] == '}' && --brace == 0) break;
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
    const bool clip = material.alphaMode == "clip";
    const std::string src = normalize_snippet(snippetText);
    const std::vector<Function> fns = find_entry_points(blank_comments(src));
    for (const Function& f : fns) (f.isVertex ? g.hasVertex : g.hasSurface) = true;

    TopFile t{g};
    t.generated("@module fa_mat\n@block fa_user\n");
    // The material block lives in one stage: a sokol uniform block slot belongs to one stage, so the vertex stage gets its own
    // block (binding 4) and the fragment stage (binding 5). Unused blocks and textures are not part of a program.
    t.generated("#ifdef GL_VERTEX_SHADER\n");
    if (!material.params.empty()) t.generated("layout(binding=4) uniform fa_material_vs {\n" + block_members(material.params) + "};\n");
    // Helpers that sample a texture or discard still compile in the vertex stage.
    t.generated("#define texture(s, uv) textureLod(s, uv, 0.0)\n#define discard\n");
    t.generated("#else\n");
    if (!material.params.empty()) t.generated("layout(binding=5) uniform fa_material {\n" + block_members(material.params) + "};\n");
    t.generated("#endif\n");
    int view = 6, sampler = 2;
    for (const MaterialTexture& tex : material.textures)
        t.generated("layout(binding=" + std::to_string(view++) + ") uniform texture2D " + tex.name + ";\nlayout(binding=" +
                    std::to_string(sampler++) + ") uniform sampler " + tex.name + "_smp;\n");

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
    t.generated("@end\n@include mesh_common.glsl\n");

    g.programs = {"mesh", "mesh_skin"};
    t.generated("@program mesh vs fs\n@program mesh_skin vs_skin fs\n");
    if (g.hasVertex || clip) {
        g.programs.push_back("shadow");
        g.programs.push_back("shadow_skin");
        t.generated("@program shadow shadow_vs shadow_fs\n@program shadow_skin shadow_vs_skin shadow_fs\n");
    }
    if (g.hasVertex) g.defines.push_back("FA_HAS_VERTEX");
    if (clip) g.defines.push_back("FA_ALPHA_CLIP");
    return g;
}

}  // namespace fa
