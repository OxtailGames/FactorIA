// A mesh material in "full" mode (docs/shaders/SHADERS_FULL.md, docs/design/CUSTOM_SHADERS_FULL.md): the shader file holds the vertex and the
// fragment stage, each with its own main(), instead of a surface() snippet. This file builds its top file (the same prologue as a
// snippet material, then one vertex and one fragment program per pass) and checks the file without a compiler.
#include <algorithm>
#include <cctype>
#include <regex>
#include <set>

#include "fa/core/strings.h"
#include "fa/tooling/shaders.h"
#include "shaders_internal.h"

namespace fa {

using namespace shaders_detail;

namespace {

// ---- the sections of the file -------------------------------------------------------------------------------------------

struct Section {
    bool present = false;
    std::size_t begin = 0;  // the first byte after the directive line
    std::size_t end = 0;    // the first byte of the next directive line (or the end of the file)
    int line = 0;           // the line of the directive
};

struct Sections {
    Section common, vertex, fragment;
};

const std::vector<std::string>& section_names() {
    static const std::vector<std::string> names = {"common", "vertex", "fragment"};
    return names;
}

std::string upper(std::string s) {
    for (char& c : s) c = char(std::toupper(static_cast<unsigned char>(c)));
    return s;
}

ShaderIssue issue_at(const MaterialDef& m, const std::string& src, int line, std::string message, std::string hint,
                     int column = 0) {
    ShaderIssue i;
    i.file = m.shader;
    i.line = line;
    i.source = line > 0 ? line_text(src, line) : std::string();
    if (line > 0 && column == 0) {
        const std::size_t p = i.source.find_first_not_of(" \t");
        column = int(p == std::string::npos ? 0 : p) + 1;
    }
    i.column = line > 0 ? column : 0;
    i.message = std::move(message);
    i.hint = std::move(hint);
    return i;
}

// Splits the file at its `@common`, `@vertex` and `@fragment` lines. A directive is looked for in the comment-free text, so a
// commented-out one does not count. The problems found go to `issues` when it is given.
Sections split_sections(const MaterialDef& m, const std::string& src, const std::string& stripped,
                        std::vector<ShaderIssue>* issues) {
    Sections out;
    Section* open = nullptr;
    bool seen = false;  // a directive was read
    int line = 0;
    for (std::size_t pos = 0; pos <= src.size();) {
        ++line;
        std::size_t nl = src.find('\n', pos);
        if (nl == std::string::npos) nl = src.size();
        const std::string text = stripped.substr(pos, nl - pos);
        const std::size_t first = text.find_first_not_of(" \t");
        if (first != std::string::npos && text[first] == '@') {
            std::size_t e = first + 1;
            while (e < text.size() && ident_char(text[e])) ++e;
            const std::string name = text.substr(first + 1, e - first - 1);
            seen = true;
            const bool tail = text.find_first_not_of(" \t", e) != std::string::npos;
            Section* s = name == "common"     ? &out.common
                         : name == "vertex"   ? &out.vertex
                         : name == "fragment" ? &out.fragment
                                              : nullptr;
            if (!s) {
                if (issues)
                    issues->push_back(issue_at(
                        m, src, line, "unknown section `@" + name + "`",
                        name.empty() ? "A section starts with a line `@common`, `@vertex` or `@fragment`."
                                     : "A section starts with a line `@common`, `@vertex` or `@fragment`." +
                                           [&] {
                                               const std::string best = closest_match(name, section_names());
                                               return best.empty() ? std::string() : " Did you mean `@" + best + "`?";
                                           }(),
                        int(first) + 1));
            } else {
                if (tail && issues)
                    issues->push_back(issue_at(m, src, line, "`@" + name + "` must be alone on its line",
                                               "Put the code of the section on the lines after it.", int(first) + 1));
                if (s->present && issues)
                    issues->push_back(
                        issue_at(m, src, line, "the section `@" + name + "` appears twice",
                                 "Merge the two into one: a section is the whole code of its stage (line " +
                                     std::to_string(s->line) + " is the first).",
                                 int(first) + 1));
                if (open) open->end = pos;
                if (!s->present) {
                    s->present = true;
                    s->line = line;
                    s->begin = std::min(nl + 1, src.size());
                    s->end = src.size();
                    open = s;
                } else {
                    open = nullptr;
                }
            }
        } else if (first != std::string::npos && !open && !seen) {
            seen = true;
            if (issues)
                issues->push_back(
                    issue_at(m, src, line, "code before the first section",
                             "Everything of a full shader lives in a section: write `@common` (shared by both "
                             "stages), `@vertex` and `@fragment` on their own lines first.",
                             int(first) + 1));
        }
        pos = nl + 1;
    }
    return out;
}

// ---- varyings -----------------------------------------------------------------------------------------------------------

struct Varying {
    std::string decl;  // "flat vec3 v_n" (the text that must match in both stages)
    std::string type, name;
    int slots = 1;  // vec4 slots
    std::size_t offset = 0;
};

int type_slots(const std::string& type) {
    if (type == "mat2" || type == "mat2x2") return 2;
    if (type == "mat3" || type == "mat3x3") return 3;
    if (type == "mat4" || type == "mat4x4") return 4;
    return 1;
}

// The `varying` declarations of a piece of the file (comments already blanked), in order. `base` is the offset of the piece in
// the file, for the line of a report.
void collect_varyings(const std::string& text, std::size_t base, std::vector<Varying>& out) {
    static const std::regex re(
        R"(\b((?:flat|smooth|noperspective)\s+)?varying\s+(\w+)\s+(\w+)\s*(?:\[\s*(\d+)\s*\])?\s*;)");
    for (auto it = std::sregex_iterator(text.begin(), text.end(), re); it != std::sregex_iterator(); ++it) {
        Varying v;
        std::string qualifier = (*it)[1].str();
        while (!qualifier.empty() && std::isspace(static_cast<unsigned char>(qualifier.back()))) qualifier.pop_back();
        v.type = (*it)[2].str();
        v.name = (*it)[3].str();
        v.decl = (qualifier.empty() ? "" : qualifier + " ") + v.type + " " + v.name;
        int count = 1;
        if ((*it)[4].matched) count = std::max(1, std::min(std::atoi((*it)[4].str().c_str()), 64));
        if ((*it)[4].matched) v.decl += "[" + (*it)[4].str() + "]";
        v.slots = type_slots(v.type) * count;
        v.offset = base + std::size_t(it->position(0));
        out.push_back(std::move(v));
    }
}

std::string piece(const std::string& text, const Section& s) {
    return s.present ? text.substr(s.begin, s.end - s.begin) : std::string();
}

// The names a full shader may use that start with fa_ or FA_: what mesh_full_common.glsl documents (the rest of the template
// belongs to the engine and may change).
const std::vector<std::string>& provided_names() {
    static const std::vector<std::string> names = {
        // vertex stage
        "fa_position", "fa_normal", "fa_texcoord0", "fa_tangent", "fa_color", "fa_model", "fa_view_proj", "fa_light_vp",
        "fa_uv_scale", "fa_world_position", "fa_world_direction", "fa_shadow_coord", "fa_instance_index",
        // fragment stage
        "fa_frag_color", "fa_tex", "fa_smp", "fa_base_sample", "fa_base_color", "fa_camera_pos", "fa_ambient",
        "fa_emissive", "fa_env_sky", "fa_env_horizon", "fa_shadow", "fa_light_count", "fa_light",
        "fa_cluster_light_count", "fa_cluster_light_index", "fa_apply_decals", "fa_apply_fog", "fa_environment",
        "fa_env_brdf", "fa_sky_reflection", "fa_ambient_light", "fa_srgb_to_linear",
        "fa_linear_to_srgb"
        "fa_mip_bias",
        // macros
        "FA_TIME", "FA_CAMERA", "FA_PASS", "FA_SKIN", "FA_SHADOW_PASS"};
    return names;
}

}  // namespace

namespace shaders_detail {

std::string full_program_name(int pass, bool skinned) {
    const std::string base = pass == 0 ? "mesh" : "pass" + std::to_string(pass);
    return skinned ? base + "_skin" : base;
}

Json full_twin_fields(const MaterialDef& m) {
    Json passes = Json::array();
    for (std::size_t i = 0; i < m.passes.size(); ++i) {
        const MaterialPass& p = m.passes[i];
        passes.push_back(Json::object({{"name", p.name},
                                       {"cull", p.cull},
                                       {"depthTest", p.depthTest},
                                       {"depthWrite", p.depthWrite},
                                       {"blend", p.blend},
                                       {"program", full_program_name(int(i), false)},
                                       {"programSkin", full_program_name(int(i), true)}}));
    }
    return Json::object({{"full", true}, {"shadow", m.shadow}, {"prepass", m.prepass}, {"passes", std::move(passes)}});
}

std::vector<ShaderIssue> precheck_full(const MaterialDef& m, const std::string& source, const std::string& stripped) {
    std::vector<ShaderIssue> out;
    const Sections sec = split_sections(m, source, stripped, &out);
    auto add = [&](ShaderIssue i) { out.push_back(std::move(i)); };
    if (!sec.vertex.present)
        add(issue_at(
            m, source, 0, "the file has no `@vertex` section",
            "Add a line `@vertex` followed by the code of the vertex stage: `void main() { gl_Position = fa_view_proj "
            "* "
            "vec4(fa_world_position(fa_position), 1.0); }`. Both stages are needed, docs/shaders/SHADERS_FULL.md."));
    if (!sec.fragment.present)
        add(issue_at(
            m, source, 0, "the file has no `@fragment` section",
            "Add a line `@fragment` followed by the code of the fragment stage: `void main() { fa_frag_color = "
            "vec4(1.0); }`."));
    static const std::regex mainRe(R"(\bvoid\s+main\s*\()");
    auto check_main = [&](const Section& s, const char* what, const char* example) {
        if (!s.present) return;
        const std::string text = piece(stripped, s);
        if (!std::regex_search(text, mainRe))
            add(issue_at(m, source, s.line, std::string("the `@") + what + "` section defines no `void main()`",
                         std::string("Define the entry of the stage in it: `void main() { ") + example +
                             " }`. The engine calls it after setting up the model matrix, the instanced params and the "
                             "declared channels."));
    };
    check_main(sec.vertex, "vertex", "gl_Position = fa_view_proj * vec4(fa_world_position(fa_position), 1.0);");
    check_main(sec.fragment, "fragment", "fa_frag_color = vec4(1.0);");
    // A main() in @common would be defined twice, once per stage, and the engine's own main would clash with it.
    if (sec.common.present && std::regex_search(piece(stripped, sec.common), mainRe))
        add(issue_at(
            m, source, sec.common.line, "the `@common` section defines `main()`",
            "Each stage has its own main(): move it to `@vertex` or `@fragment`. `@common` holds what both share "
            "(constants, structs, helper functions, `varying` declarations)."));
    if (sec.vertex.present && stripped.find("gl_Position") == std::string::npos)
        add(issue_at(m, source, sec.vertex.line, "the vertex stage never writes gl_Position",
                     "Write the clip-space position: `gl_Position = fa_view_proj * "
                     "vec4(fa_world_position(fa_position), 1.0);`."));
    if (sec.fragment.present && stripped.find("fa_frag_color") == std::string::npos)
        add(issue_at(m, source, sec.fragment.line, "the fragment stage never writes fa_frag_color",
                     "Write the colour of the fragment (linear, premultiplied by nothing): `fa_frag_color = "
                     "vec4(color, 1.0);`."));

    // The varyings: sokol-shdc links the stages by position, so both must declare the same list.
    std::vector<Varying> vs, fs;
    collect_varyings(piece(stripped, sec.common), sec.common.begin, vs);
    fs = vs;
    collect_varyings(piece(stripped, sec.vertex), sec.vertex.begin, vs);
    collect_varyings(piece(stripped, sec.fragment), sec.fragment.begin, fs);
    const std::size_t common = std::min(vs.size(), fs.size());
    bool mismatch = false;
    for (std::size_t i = 0; i < common && !mismatch; ++i) {
        if (vs[i].decl == fs[i].decl) continue;
        mismatch = true;
        add(issue_at(
            m, source, line_of(source, fs[i].offset),
            "the fragment stage declares `varying " + fs[i].decl + "` as varying " + std::to_string(i + 1) +
                ", but the vertex stage declares `varying " + vs[i].decl + "` there (line " +
                std::to_string(line_of(source, vs[i].offset)) + ")",
            "A varying links the stages by its position in the list: declare the same varyings, with the same types, "
            "in the same order in `@vertex` and `@fragment`, or declare each once in `@common` (both stages include "
            "it)."));
    }
    if (!mismatch && vs.size() != fs.size()) {
        const bool fragMore = fs.size() > vs.size();
        const Varying& extra = fragMore ? fs[vs.size()] : vs[fs.size()];
        add(issue_at(
            m, source, line_of(source, extra.offset),
            std::string("the ") + (fragMore ? "fragment" : "vertex") + " stage declares `varying " + extra.decl +
                "`, which the " + (fragMore ? "vertex" : "fragment") + " stage does not (" + std::to_string(vs.size()) +
                " varyings in the vertex stage, " + std::to_string(fs.size()) + " in the fragment stage)",
            "Both stages must declare the same varyings in the same order, even one the fragment stage does not read: "
            "declare each once in `@common` and both agree."));
    }
    int slots = 0;
    for (const Varying& v : vs) slots += v.slots;
    if (slots > kMaterialMaxVaryings)
        add(issue_at(
            m, source, vs.empty() ? 0 : line_of(source, vs.back().offset),
            "the stages declare " + std::to_string(slots) + " varying vec4 slots, at most " +
                std::to_string(kMaterialMaxVaryings) + " fit",
            "OpenGL ES 3 and WebGL 2 guarantee 15 vec4 varyings and the engine's three flat instance varyings take "
            "the other three. Pack values into fewer varyings (two vec2 into one vec4), or compute them in the "
            "fragment stage. A matrix takes one slot per column."));

    // Reserved names: anything starting with fa_ or FA_ that the template does not document is the engine's.
    {
        static const std::regex nameRe(R"(\b(fa_\w+|FA_\w+))");
        std::set<std::string> passMacros;
        for (std::size_t i = 0; i < m.passes.size(); ++i) passMacros.insert("FA_PASS_" + upper(m.passes[i].name));
        std::set<std::string> reported;
        for (auto it = std::sregex_iterator(stripped.begin(), stripped.end(), nameRe); it != std::sregex_iterator();
             ++it) {
            const std::string name = it->str();
            if (reported.count(name) || passMacros.count(name)) continue;
            if (std::find(provided_names().begin(), provided_names().end(), name) != provided_names().end()) continue;
            reported.insert(name);
            const int line = line_of(source, std::size_t(it->position(0)));
            const std::string best = closest_match(name, provided_names());
            add(issue_at(m, source, line, "`" + name + "` is not a name a full shader may use",
                         "Names starting with fa_ or FA_ belong to the engine: a full shader may use only the ones "
                         "docs/shaders/SHADERS_FULL.md lists" +
                             (best.empty() ? std::string(". Rename it without the prefix.")
                                           : std::string(" (did you mean `") + best +
                                                 "`?). Rename your own names without the prefix."),
                         column_of(source, std::size_t(it->position(0))) + 1));
        }
    }
    return out;
}

}  // namespace shaders_detail

// ---- the top file -------------------------------------------------------------------------------------------------------

namespace {

struct Top {
    GeneratedShader& g;
    void generated(std::string_view text) {
        g.top += text;
        for (char c : text)
            if (c == '\n') g.snippetLine.push_back(0);
    }
    void user(const std::string& src, const Section& s) {
        if (!s.present || s.begin >= s.end) return;
        int line = line_of(src, s.begin);
        for (std::size_t i = s.begin; i < s.end;) {
            std::size_t nl = src.find('\n', i);
            const std::size_t stop = (nl == std::string::npos || nl >= s.end) ? s.end : nl;
            g.top.append(src, i, stop - i);
            g.top += '\n';
            g.snippetLine.push_back(line++);
            i = stop + 1;
        }
    }
};

}  // namespace

GeneratedShader generate_full_shader(const MaterialDef& material, std::string_view snippetText) {
    GeneratedShader g;
    g.kind = "mesh-full";
    const std::string src = normalize_snippet(snippetText);
    const std::string stripped = blank_comments(src);
    const Sections sec = split_sections(material, src, stripped, nullptr);
    Top t{g};
    t.generated("@module fa_mat\n@block fa_user\n");
    std::string vsUndefs;
    t.generated(material_prologue(material, vsUndefs));
    // mesh_common.glsl's own programs still compile (sokol-shdc builds every block it includes) and call surface(): an empty one.
    t.generated("#ifdef GL_FRAGMENT_SHADER\nvoid surface(in SurfaceInput i, inout Surface s) {}\n#endif\n@end\n");
    t.generated("@include mesh_common.glsl\n@include mesh_full_common.glsl\n");

    std::string programs;
    auto stage_head = [&](int pass, bool skinned, bool shadow) {
        std::string d = "#define FA_PASS " + std::to_string(pass) + "\n";
        if (pass < int(material.passes.size()))
            d += "#define FA_PASS_" + upper(material.passes[std::size_t(pass)].name) + " 1\n";
        if (skinned) d += "#define FA_SKIN\n";
        if (shadow) d += "#define FA_SHADOW_PASS\n";
        return d;
    };
    auto vertex_program = [&](const std::string& name, int pass, bool skinned, bool shadow) {
        t.generated("@vs " + name + "\n" + stage_head(pass, skinned, shadow) +
                    "@include_block fa_full_vs_head\n#define main fa_user_main\n#define varying out\n");
        t.user(src, sec.common);
        t.user(src, sec.vertex);
        // The shims stop at the author's code: the engine's own vertex code below sees the real texture() and discard.
        t.generated("#undef main\n#undef varying\n#undef texture\n#undef discard\n" + vsUndefs +
                    "@include_block fa_full_vs_tail\n@end\n");
    };
    auto fragment_program = [&](const std::string& name, int pass, bool shadow) {
        t.generated("@fs " + name + "\n" + stage_head(pass, false, shadow) +
                    "@include_block fa_full_fs_head\n#define main fa_user_main\n#define varying in\n");
        t.user(src, sec.common);
        t.user(src, sec.fragment);
        t.generated("#undef main\n#undef varying\n@include_block fa_full_fs_tail\n@end\n");
    };
    const int passCount = std::max<int>(1, int(material.passes.size()));
    for (int p = 0; p < passCount; ++p) {
        const std::string plain = full_program_name(p, false), skin = full_program_name(p, true);
        vertex_program("fvs_" + plain, p, false, false);
        vertex_program("fvs_" + skin, p, true, false);
        fragment_program("ffs_" + plain, p, false);
        programs += "@program " + plain + " fvs_" + plain + " ffs_" + plain + "\n@program " + skin + " fvs_" + skin +
                    " ffs_" + plain + "\n";
        g.programs.push_back(plain);
        g.programs.push_back(skin);
    }
    if (material.shadow == "custom") {
        // The first pass again with FA_SHADOW_PASS: the author's own depth program for the shadow map.
        vertex_program("fvs_shadow", 0, false, true);
        vertex_program("fvs_shadow_skin", 0, true, true);
        fragment_program("ffs_shadow", 0, true);
        programs += "@program shadow fvs_shadow ffs_shadow\n@program shadow_skin fvs_shadow_skin ffs_shadow\n";
        g.programs.push_back("shadow");
        g.programs.push_back("shadow_skin");
    }
    if (material.prepass) {
        // The engine's own depth and normal prepass (mesh_common.glsl): the mesh as the MeshRenderer draws it.
        programs += "@program prepass prepass_vs prepass_fs\n@program prepass_skin prepass_vs_skin prepass_fs\n";
        g.programs.push_back("prepass");
        g.programs.push_back("prepass_skin");
    }
    t.generated(programs);
    g.stateKey = full_twin_fields(material).dump();
    const InstanceLayout instLayout = instance_layout(material.params);
    if (instLayout.vec4Count > 0) g.defines.push_back("FA_INST_" + std::to_string(std::min(instLayout.vec4Count, 3)));
    for (const std::string& a : material.vertexAttributes)
        g.defines.push_back(a == "uv1" ? "FA_CH_UV1" : "FA_CH_COLOR1");
    if (!material.buffers.empty()) g.defines.push_back("FA_BUFFER_INST");  // see generate_material_shader
    return g;
}

}  // namespace fa
