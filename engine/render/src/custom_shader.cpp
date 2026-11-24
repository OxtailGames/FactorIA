// Custom materials (MeshRenderer.material): the factoria.shader/1 twin -> sg_shader_desc (docs/design/CUSTOM_SHADERS.md),
// and the packing of a material's params.
#include "fa/core/engine_version.h"
#include <algorithm>
#include <cmath>
#include <cstring>
#include <optional>

#include "fa/core/fs.h"
#include "fa/core/log.h"
#include "fa/core/strings.h"
#include "render_features.h"
#include "render_internal.h"
#include "shader_cache.h"

namespace fa {

const std::vector<std::string>& material_kind_names() {
    static const std::vector<std::string> names = {"mesh", "sprite", "sky", "post", "compute"};
    return names;
}

const char* material_kind_name(MaterialKind kind) { return material_kind_names()[std::size_t(kind)].c_str(); }

std::optional<MaterialKind> material_kind_from_name(std::string_view name) {
    const auto& names = material_kind_names();
    for (std::size_t i = 0; i < names.size(); ++i)
        if (names[i] == name) return MaterialKind(i);
    return std::nullopt;
}

std::string material_template_hash(MaterialKind kind) {
    switch (kind) {
        case MaterialKind::Mesh: return FA_TEMPLATE_HASH_MESH;
        case MaterialKind::Sprite: return FA_TEMPLATE_HASH_SPRITE;
        case MaterialKind::Sky: return FA_TEMPLATE_HASH_SKY;
        case MaterialKind::Post: return FA_TEMPLATE_HASH_POST;
        case MaterialKind::Compute: return FA_TEMPLATE_HASH_COMPUTE;
    }
    return {};
}

std::string mesh_template_hash() { return material_template_hash(MaterialKind::Mesh); }

std::string mesh_full_template_hash() { return FA_TEMPLATE_HASH_MESH_FULL; }

}  // namespace fa

namespace fa::render {

bool Assets::storage_buffers_available(std::string* backend, std::string* reason) const {
    if (bufferGate_) return bufferGate_(backend, reason);
    const FeatureEnv env = feature_env_from_device(gpu_.device());
    if (backend) *backend = feature_backend_label(env.backend);
    return feature_supported(env, find_feature("computeShaders"), reason);
}

int Assets::storage_binding_limit(bool* limited) const {
    if (storageBindingLimit_ >= 0) {
        *limited = true;
        return storageBindingLimit_;
    }
    *limited = gpu_.device().backend() == gpu::Backend::Gl;
    return gpu_.device().limits().maxStorageBufferBindingsPerStage;
}

std::string backend_dialect(const gpu::DeviceInfo& info) {
    switch (info.backend) {
        case gpu::Backend::D3d11: return "hlsl5";
        case gpu::Backend::Gl: return "glsl430";
        case gpu::Backend::Gles3:
        case gpu::Backend::WebGl2: return "glsl300es";
        case gpu::Backend::Metal:
            switch (info.metalTarget) {
                case gpu::MetalTarget::MacOs: return "metal_macos";
                case gpu::MetalTarget::Ios: return "metal_ios";
                case gpu::MetalTarget::Simulator: return "metal_sim";
                case gpu::MetalTarget::None: break;
            }
            return {};
        default: return {};
    }
}

std::string backend_dialect(sg_backend backend) {
    gpu::DeviceInfo info;
    info.backend = gpu::backend_from_sg(backend);
    info.metalTarget = gpu::metal_target_from_sg(backend);
    return backend_dialect(info);
}

const std::vector<const char*>& material_program_names(MaterialKind kind) {
    // The order of MaterialProgramId. Every kind has its programs.
    static const std::vector<const char*> mesh = {"mesh",        "mesh_skin", "shadow",
                                                  "shadow_skin", "prepass",   "prepass_skin"};
    // Sprite: quad (every mode of quad_common.glsl) and quad_plain (a batch of plain textured quads); a material has
    // both.
    static const std::vector<const char*> sprite = {"quad", "quad_plain"};
    // Sky: the one program of sky_common.glsl.
    static const std::vector<const char*> sky = {"sky"};
    static const std::vector<const char*> compute = {"compute"};
    // Post: one full-screen program (post_common.glsl).
    static const std::vector<const char*> post = {"post"};
    static const std::vector<const char*> none;
    switch (kind) {
        case MaterialKind::Mesh: return mesh;
        case MaterialKind::Sprite: return sprite;
        case MaterialKind::Sky: return sky;
        case MaterialKind::Compute: return compute;
        case MaterialKind::Post: return post;
        default: return none;
    }
}

namespace {

// Reads of sokol-shdc's reflection (bare_yaml as JSON). Missing keys give the default: the reflection of one dialect only
// has the keys of that dialect (hlsl_register_*, msl_*, glsl_*).
int int_or(const Json& j, const char* key, int fallback = 0) {
    auto it = j.find(key);
    return it != j.end() && it->is_number() ? it->get<int>() : fallback;
}
const std::string* str_of(const Json& j, const char* key) {
    auto it = j.find(key);
    return it != j.end() && it->is_string() ? it->get_ptr<const std::string*>() : nullptr;
}
const char* cstr_or_null(const Json& j, const char* key) {
    const std::string* s = str_of(j, key);
    return s ? s->c_str() : nullptr;
}
std::string text_of(const Json& j, const char* key) {
    const std::string* s = str_of(j, key);
    return s ? *s : std::string();
}

// The array `key` of `j` (by reference: the desc points at the strings inside), or an empty one.
const Json& list_of(const Json& j, const char* key) {
    static const Json none = Json::array();
    auto it = j.find(key);
    return it != j.end() && it->is_array() ? *it : none;
}

template <class E>
bool pick(const std::string& name, std::initializer_list<std::pair<const char*, E>> table, E& out) {
    for (const auto& [n, v] : table)
        if (name == n) {
            out = v;
            return true;
        }
    return false;
}

sg_shader_stage stage_of(const Json& j) {
    const std::string stage = text_of(j, "stage");
    return stage == "vertex"    ? SG_SHADERSTAGE_VERTEX
           : stage == "compute" ? SG_SHADERSTAGE_COMPUTE
                                : SG_SHADERSTAGE_FRAGMENT;
}

// GLES3 and WebGL2 guarantee 16 texture units per stage (render_internal.h, kMeshMaxFragmentUnits); sokol's own cap is
// SG_MAX_TEXTURE_SAMPLER_PAIRS (32) over both stages. The engine refuses a program past either on every backend (D3D11
// and Metal could bind more: a game that loads on one must load on all). The error for it: counts the pairs of each
// stage over its limit (both when both are), says which ones the engine's own bindings take and which are the
// material's textures (or the vertex copies of them), and what to drop. A pair is the material's own when its view is
// one of `materialTextures` (fragment stage) or `fa_vs_<name>` of one (vertex stage): classified by what the material
// declares, never by a name the engine's views might share. Without `materialTextures` (a caller that has no material)
// the engine's own view names (and every other `fa_` one that is not a vertex copy) are the engine's and the rest the
// material's. Empty when the program is within both limits.
std::optional<Error> too_many_pairs(const std::string& where, const Json& pairList,
                                    const std::vector<std::string>* materialTextures) {
    static const char* const engineViews[] = {"tex",       "normal_tex",    "light_tex",       "shadow_tex",
                                              "fx_gi_tex", "fx_cookie_tex", "fx_emissive_tex", "fa_scene_tex"};
    constexpr int kUnitsPerStage = 16;
    struct Stage {
        int count = 0, nEngine = 0, nOwn = 0;
        std::string engine, own;
    } stages[2];  // fragment, vertex
    auto add = [](std::string& list, int& n, const std::string& name) { list += (n++ ? ", " : "") + name; };
    auto is_own = [&](const std::string& name, bool vertex) {
        if (materialTextures) {
            for (const std::string& t : *materialTextures)
                if (name == (vertex ? "fa_vs_" + t : t)) return true;
            return false;
        }
        bool isEngine = name.rfind("fa_", 0) == 0 && name.rfind("fa_vs_", 0) != 0;
        for (const char* e : engineViews) isEngine = isEngine || name == e;
        return !isEngine;
    };
    bool readsSceneColor = false;
    for (const Json& p : pairList) {
        const bool vertex = text_of(p, "stage") == "vertex";
        Stage& st = stages[vertex ? 1 : 0];
        const std::string name = text_of(p, "view_name");
        ++st.count;
        if (is_own(name, vertex))
            add(st.own, st.nOwn, name);
        else
            add(st.engine, st.nEngine, name);
        readsSceneColor = readsSceneColor || name == "fa_scene_tex";
    }
    const bool over[2] = {stages[0].count > kUnitsPerStage, stages[1].count > kUnitsPerStage};
    const int total = int(pairList.size());
    if (!over[0] && !over[1] && total <= SG_MAX_TEXTURE_SAMPLER_PAIRS) return std::nullopt;

    // One clause per stage over its limit (both are reported), or one for the two stages together.
    auto clause = [&](const Stage& st, const char* name) {
        return std::to_string(st.count) + " in its " + name + " stage (the engine's own bindings take " +
               std::to_string(st.nEngine) + " (" + (st.nEngine ? st.engine : "none") + "), the " +
               (name[0] == 'v' ? "vertex copies of the material's textures " : "material's own textures ") +
               std::to_string(st.nOwn) + " (" + (st.nOwn ? st.own : "none") + "))";
    };
    std::string message = where + " reads ";
    int excess = 0;
    bool vertexCopies = false, manyOwn = false;
    if (over[0] || over[1]) {
        message +=
            "too many image-sampler pairs for one stage (every texture a stage reads counts once, with the "
            "sampler it is read through, and at most " +
            std::to_string(kUnitsPerStage) +
            " can be bound per stage: the texture units GLES3 and WebGL2 guarantee, which the engine holds every "
            "backend to, D3D11 and Metal too, so a game that loads on one loads on all): ";
        bool first = true;
        for (int s = 0; s < 2; ++s) {
            if (!over[s]) continue;
            message += (first ? "" : "; and ") + clause(stages[s], s ? "vertex" : "fragment");
            first = false;
            excess = std::max(excess, stages[s].count - kUnitsPerStage);
            vertexCopies = vertexCopies || (s == 1 && stages[s].nOwn > 0);
            manyOwn = manyOwn || stages[s].nOwn > 1;
        }
    } else {
        message += std::to_string(total) +
                   " image-sampler pairs over both stages (every texture a stage reads counts once, "
                   "with the sampler it is read through), and at most " +
                   std::to_string(SG_MAX_TEXTURE_SAMPLER_PAIRS) +
                   " fit in one shader (sokol's cap, the same on every backend): " + "fragment " +
                   clause(stages[0], "fragment") + "; vertex " + clause(stages[1], "vertex");
        excess = total - SG_MAX_TEXTURE_SAMPLER_PAIRS;
        vertexCopies = stages[1].nOwn > 0;
        manyOwn = stages[0].nOwn + stages[1].nOwn > 1;
    }
    // Only what could help this shader: a vertex copy exists when vertex() samples a texture, fa_scene_tex when the
    // snippet calls fa_scene_color().
    std::string hint = "Drop " + std::to_string(excess) + " or more";
    std::vector<std::string> ways;
    if (vertexCopies) ways.push_back("do not sample a texture in vertex() (that removes its vertex copy)");
    if (readsSceneColor && (over[0] || !over[1]))
        ways.push_back("do not call fa_scene_color() unless the material needs the picture behind it");
    if (manyOwn)
        ways.push_back(
            "merge maps into the channels of one texture (a mask, a roughness and an occlusion map fit the four "
            "channels of one image) instead of declaring one texture per map");
    else
        ways.push_back("declare fewer textures: the engine's own bindings cannot be dropped");
    hint += ": ";
    for (std::size_t i = 0; i < ways.size(); ++i)
        hint += (i == 0 ? "" : i + 1 == ways.size() ? ", and " : ", ") + ways[i];
    return make_error(message, hint + ".");
}

}  // namespace

Result<sg_shader_desc> material_shader_desc(const std::string& label, const Json& program, MaterialProgram& out,
                                            const int* workgroup, const std::vector<std::string>* materialTextures) {
    const std::string where = "the program '" + label + "'";
    auto bad = [&](const std::string& what) {
        return make_error(where + " of the shader twin is malformed: " + what,
                          "Re-export the game, or run it with `factoria` so the shaders are compiled again, with the "
                          "same factoria version.");
    };
    const std::string* vs = str_of(program, "vs");
    const std::string* fsText = str_of(program, "fs");
    const std::string* cs = str_of(program, "cs");  // a compute program has this one instead of "vs" and "fs"
    auto refl = program.find("reflection");
    if (refl == program.end() || !refl->is_object() || (cs ? (vs || fsText) : (!vs || !fsText)))
        return bad("it needs \"reflection\" and either \"vs\" and \"fs\" or \"cs\"");
    if (cs && (!workgroup || workgroup[0] < 1 || workgroup[1] < 1 || workgroup[2] < 1))
        return bad("a compute program needs the material's workgroup size");

    // The strings the desc points to live in `program` (the Json) for the whole call.
    sg_shader_desc desc{};
    desc.label = label.c_str();
    const Json noFunc = Json::object();
    auto function_of = [&](sg_shader_function& fn, const char* key, const std::string& source) {
        fn.source = source.c_str();
        auto f = refl->find(key);
        const Json& fj = f != refl->end() && f->is_object() ? *f : noFunc;
        fn.entry = cstr_or_null(fj, "entry_point");
        if (!fn.entry) fn.entry = "main";
        fn.d3d11_target = cstr_or_null(fj, "d3d11_target");
    };
    if (cs) {
        function_of(desc.compute_func, "compute_func", *cs);
        desc.mtl_threads_per_threadgroup = {workgroup[0], workgroup[1], workgroup[2]};
    } else {
        function_of(desc.vertex_func, "vertex_func", *vs);
        function_of(desc.fragment_func, "fragment_func", *fsText);
    }

    for (const Json& a : list_of(*refl, "attrs")) {
        const int slot = int_or(a, "slot", -1);
        if (slot < 0 || slot >= SG_MAX_VERTEX_ATTRIBUTES)
            return bad("an attribute slot outside 0.." + std::to_string(SG_MAX_VERTEX_ATTRIBUTES - 1));
        sg_shader_vertex_attr& at = desc.attrs[slot];
        const std::string base = text_of(a, "base_type");
        at.base_type = base == "Sint"   ? SG_SHADERATTRBASETYPE_SINT
                       : base == "Uint" ? SG_SHADERATTRBASETYPE_UINT
                                        : SG_SHADERATTRBASETYPE_FLOAT;
        at.glsl_name = cstr_or_null(a, "glsl_name");
        at.hlsl_sem_name = cstr_or_null(a, "hlsl_sem_name");
        at.hlsl_sem_index = std::uint8_t(int_or(a, "hlsl_sem_index"));
    }
    for (const Json& u : list_of(*refl, "uniform_blocks")) {
        const int slot = int_or(u, "slot", -1);
        if (slot < 0 || slot >= SG_MAX_UNIFORMBLOCK_BINDSLOTS)
            return bad("a uniform block slot outside 0.." + std::to_string(SG_MAX_UNIFORMBLOCK_BINDSLOTS - 1));
        sg_shader_uniform_block& ub = desc.uniform_blocks[slot];
        ub.stage = stage_of(u);
        ub.layout = SG_UNIFORMLAYOUT_STD140;
        ub.size = std::uint32_t(int_or(u, "size"));
        ub.hlsl_register_b_n = std::uint8_t(int_or(u, "hlsl_register_b_n"));
        ub.msl_buffer_n = std::uint8_t(int_or(u, "msl_buffer_n"));
        int n = 0;
        for (const Json& g : list_of(u, "glsl_uniforms")) {
            if (n >= SG_MAX_UNIFORMBLOCK_MEMBERS) return bad("a uniform block with too many members");
            sg_uniform_type type = SG_UNIFORMTYPE_FLOAT4;
            if (!pick<sg_uniform_type>(text_of(g, "type"),
                                       {{"float", SG_UNIFORMTYPE_FLOAT},
                                        {"vec2", SG_UNIFORMTYPE_FLOAT2},
                                        {"vec3", SG_UNIFORMTYPE_FLOAT3},
                                        {"vec4", SG_UNIFORMTYPE_FLOAT4},
                                        {"int", SG_UNIFORMTYPE_INT},
                                        {"ivec2", SG_UNIFORMTYPE_INT2},
                                        {"ivec3", SG_UNIFORMTYPE_INT3},
                                        {"ivec4", SG_UNIFORMTYPE_INT4},
                                        {"mat4", SG_UNIFORMTYPE_MAT4}},
                                       type))
                return bad("the uniform type '" + text_of(g, "type") + "'");
            desc.uniform_blocks[slot].glsl_uniforms[n++] = {type, std::uint16_t(int_or(g, "array_count")),
                                                            cstr_or_null(g, "glsl_name")};
        }
        out.ubMask |= 1u << slot;
        out.ubSize[slot] = ub.size;
    }
    for (const Json& v : list_of(*refl, "views")) {
        if (auto sb = v.find("storage_buffer"); sb != v.end() && sb->is_object()) {
            const int slot = int_or(*sb, "slot", -1);
            if (slot < 0 || slot >= SG_MAX_VIEW_BINDSLOTS)
                return bad("a storage buffer slot outside 0.." + std::to_string(SG_MAX_VIEW_BINDSLOTS - 1));
            sg_shader_storage_buffer_view& bv = desc.views[slot].storage_buffer;
            bv.stage = cs ? SG_SHADERSTAGE_COMPUTE : stage_of(*sb);  // a mesh material reads them in both stages
            bv.readonly = sb->find("readonly") != sb->end() && sb->at("readonly") == true;
            if (!cs && !bv.readonly) return bad("a storage buffer of a drawing program must be readonly");
            bv.hlsl_register_t_n = std::uint8_t(int_or(*sb, "hlsl_register_t_n"));
            bv.hlsl_register_u_n = std::uint8_t(int_or(*sb, "hlsl_register_u_n"));
            bv.msl_buffer_n = std::uint8_t(int_or(*sb, "msl_buffer_n"));
            bv.glsl_binding_n = std::uint8_t(int_or(*sb, "glsl_binding_n"));
            out.viewMask |= 1u << slot;
            continue;
        }
        if (auto si = v.find("storage_image"); cs && si != v.end() && si->is_object()) {
            const int slot = int_or(*si, "slot", -1);
            if (slot < 0 || slot >= SG_MAX_VIEW_BINDSLOTS)
                return bad("a storage image slot outside 0.." + std::to_string(SG_MAX_VIEW_BINDSLOTS - 1));
            sg_shader_storage_image_view& iv = desc.views[slot].storage_image;
            iv.stage = SG_SHADERSTAGE_COMPUTE;
            iv.image_type = SG_IMAGETYPE_2D;
            if (!pick<sg_pixel_format>(text_of(*si, "access_format"),
                                       {{"RGBA8", SG_PIXELFORMAT_RGBA8},
                                        {"RGBA16F", SG_PIXELFORMAT_RGBA16F},
                                        {"R32F", SG_PIXELFORMAT_R32F},
                                        {"RGBA32F", SG_PIXELFORMAT_RGBA32F}},
                                       iv.access_format))
                return bad("the storage image format '" + text_of(*si, "access_format") + "'");
            iv.writeonly = si->find("writeonly") != si->end() && si->at("writeonly") == true;
            iv.hlsl_register_u_n = std::uint8_t(int_or(*si, "hlsl_register_u_n"));
            iv.msl_texture_n = std::uint8_t(int_or(*si, "msl_texture_n"));
            iv.glsl_binding_n = std::uint8_t(int_or(*si, "glsl_binding_n"));
            out.viewMask |= 1u << slot;
            continue;
        }
        auto t = v.find("texture");
        if (t == v.end() || !t->is_object())
            return bad("a view that is neither a texture nor a storage buffer or image" +
                       std::string(cs ? "" : " (storage images only in a compute program)"));
        const int slot = int_or(*t, "slot", -1);
        if (slot < 0 || slot >= SG_MAX_VIEW_BINDSLOTS)
            return bad("a texture slot outside 0.." + std::to_string(SG_MAX_VIEW_BINDSLOTS - 1));
        sg_shader_texture_view& tv = desc.views[slot].texture;
        tv.stage = stage_of(*t);
        tv.multisampled = t->find("multisampled") != t->end() && t->at("multisampled") == true;
        tv.hlsl_register_t_n = std::uint8_t(int_or(*t, "hlsl_register_t_n"));
        tv.msl_texture_n = std::uint8_t(int_or(*t, "msl_texture_n"));
        if (!pick<sg_image_type>(text_of(*t, "type"),
                                 {{"2d", SG_IMAGETYPE_2D},
                                  {"cube", SG_IMAGETYPE_CUBE},
                                  {"3d", SG_IMAGETYPE_3D},
                                  {"array", SG_IMAGETYPE_ARRAY}},
                                 tv.image_type))
            return bad("the texture type '" + text_of(*t, "type") + "'");
        if (!pick<sg_image_sample_type>(text_of(*t, "sample_type"),
                                        {{"float", SG_IMAGESAMPLETYPE_FLOAT},
                                         {"depth", SG_IMAGESAMPLETYPE_DEPTH},
                                         {"sint", SG_IMAGESAMPLETYPE_SINT},
                                         {"uint", SG_IMAGESAMPLETYPE_UINT},
                                         {"unfilterable_float", SG_IMAGESAMPLETYPE_UNFILTERABLE_FLOAT}},
                                        tv.sample_type))
            return bad("the texture sample type '" + text_of(*t, "sample_type") + "'");
        out.viewMask |= 1u << slot;
    }
    for (const Json& s : list_of(*refl, "samplers")) {
        const int slot = int_or(s, "slot", -1);
        if (slot < 0 || slot >= SG_MAX_SAMPLER_BINDSLOTS)
            return bad("a sampler slot outside 0.." + std::to_string(SG_MAX_SAMPLER_BINDSLOTS - 1));
        sg_shader_sampler& sm = desc.samplers[slot];
        sm.stage = stage_of(s);
        sm.hlsl_register_s_n = std::uint8_t(int_or(s, "hlsl_register_s_n"));
        sm.msl_sampler_n = std::uint8_t(int_or(s, "msl_sampler_n"));
        if (!pick<sg_sampler_type>(text_of(s, "sampler_type"),
                                   {{"filtering", SG_SAMPLERTYPE_FILTERING},
                                    {"nonfiltering", SG_SAMPLERTYPE_NONFILTERING},
                                    {"comparison", SG_SAMPLERTYPE_COMPARISON}},
                                   sm.sampler_type))
            return bad("the sampler type '" + text_of(s, "sampler_type") + "'");
        out.samplerMask |= 1u << slot;
    }
    int pairs = 0;
    const Json& pairList = list_of(*refl, "texture_sampler_pairs");
    if (auto tooMany = too_many_pairs(where, pairList, materialTextures)) return *tooMany;
    for (const Json& p : pairList) {
        desc.texture_sampler_pairs[pairs++] = {stage_of(p), std::uint8_t(int_or(p, "view_slot")),
                                               std::uint8_t(int_or(p, "sampler_slot")), cstr_or_null(p, "glsl_name")};
    }

    return desc;
}

Result<MaterialProgram> make_material_program(gpu::Device& device, const std::string& label, const Json& program,
                                              const int* workgroup, const std::vector<std::string>* materialTextures) {
    MaterialProgram out;
    auto made = material_shader_desc(label, program, out, workgroup, materialTextures);
    if (!made.ok()) return made.error();
    const std::string where = "the program '" + label + "'";
    const gpu::Shader shader = make_shader(device, gpu::from_sg(*made), label.c_str());
    out.shader = gpu::to_sg(shader);
    if (device.state(shader) != gpu::ResourceState::Valid) {
        device.destroy_shader(shader);
        return make_error("the graphics driver rejected " + where + " (backend " + backend_dialect(device.info()) +
                              "; the sokol log lines above have the driver message)",
                          "The shaders were compiled for this backend by sokol-shdc and passed `factoria validate`, so "
                          "this is a driver problem: update the graphics driver, "
                          "and report it with the log lines above.");
    }
    return out;
}

namespace {
// The value of param `p` for an entity: the default overlaid by `overrides[p.name]`; a value of the wrong shape is
// warned about once per material and keeps the default. `field` and `holder` name where `overrides` came from, for the
// warning.
void param_value(MaterialAsset& m, const MaterialParamDef& p, const Json& overrides, float out[4], const char* field,
                 const char* holder) {
    std::memcpy(out, p.def, sizeof(p.def));
    auto it = overrides.is_object() ? overrides.find(p.name) : overrides.end();
    if (it == overrides.end()) return;
    bool good = p.components == 1 ? it->is_number() : (it->is_array() && int(it->size()) == p.components);
    if (good && it->is_array())
        for (const Json& c : *it) good = good && c.is_number();
    if (!good) {
        if (m.warned.insert(p.name).second)
            FA_WARN("render", "{}.{} of {} using '{}' must be {} (the default is kept)", field, p.name, holder, m.path,
                    p.components == 1 ? std::string("a number")
                                      : "an array of " + std::to_string(p.components) + " numbers, like " +
                                            (p.components == 2   ? "[0.5, 1]"
                                             : p.components == 3 ? "[1, 0.5, 0]"
                                                                 : "[1, 0.5, 0, 1]"));
        return;
    }
    if (p.components == 1)
        out[0] = it->get<float>();
    else
        for (int c = 0; c < p.components; ++c) out[c] = (*it)[std::size_t(c)].get<float>();
}
}  // namespace

void pack_material_params(MaterialAsset& m, const Json& overrides, float out[kMaxMaterialParams][4], const char* field,
                          const char* holder) {
    const int n = std::min<int>(int(m.params.size()), kMaxMaterialParams);
    for (int i = 0; i < n; ++i) param_value(m, m.params[std::size_t(i)], overrides, out[i], field, holder);
    if (overrides.is_object() && !overrides.empty()) {
        std::vector<std::string> names;
        for (const auto& p : m.params) names.push_back(p.name);
        for (const auto& p : m.instanced) names.push_back(p.name);
        for (const auto& t : m.textures) names.push_back(t.name);
        for (const auto& b : m.buffers)
            names.push_back(b.name);  // a mesh or sprite material's buffer: the compute buffer id
        for (auto it = overrides.begin(); it != overrides.end(); ++it)
            if (std::find(names.begin(), names.end(), it.key()) == names.end() && m.warned.insert(it.key()).second)
                FA_WARN("render", "{}.{} of {} using '{}' is not a param or texture of that material. {}", field,
                        it.key(), holder, m.path, did_you_mean(it.key(), names));
    }
}

void pack_instance_params(MaterialAsset& m, const Json& overrides, float* out) {
    const int floats = m.instanceVec4 * 4;
    for (int i = 0; i < floats; ++i) out[i] = 0.0f;
    for (const MaterialParamDef& p : m.instanced) {
        float v[4];
        param_value(m, p, overrides, v, "materialParams", "a component");
        for (int c = 0; c < p.components; ++c) out[p.vec4 * 4 + p.offset + c] = v[c];
    }
}

TextureAsset* material_texture(MaterialAsset& m, int i, const Json& overrides, Assets& assets, const char* field,
                               const char* holder) {
    const MaterialTextureDef& t = m.textures[std::size_t(i)];
    auto it = overrides.is_object() ? overrides.find(t.name) : overrides.end();
    if (it == overrides.end()) return t.defaultTex;
    if (it->is_string()) return assets.texture(it->get<std::string>());
    if (m.warned.insert(t.name).second)
        FA_WARN("render",
                "{}.{} of {} using '{}' must be a texture path like \"assets/wood.png\" (the default texture is "
                "kept)",
                field, t.name, holder, m.path);
    return t.defaultTex;
}

// ---------------------------------------------------------------------------
// Assets: the material cache
// ---------------------------------------------------------------------------
namespace {

SamplerKind sampler_kind(const std::string& name) {
    if (name == "linearRepeat") return SamplerKind::LinearRepeat;
    if (name == "nearest") return SamplerKind::Nearest;
    if (name == "nearestRepeat") return SamplerKind::NearestRepeat;
    return SamplerKind::Linear;
}

const char* kReexportHint = "Export the game again with this factoria version (or run it with `factoria run`, which "
                            "compiles the shaders itself).";

// The compute part of a twin: "workgroupSize" [x, y, z] and "buffers" (tools/common/src/shaders_compute.cpp
// compute_twin_fields). Every number is range-checked before it is narrowed: the file may come from an export made by
// another version.
Result<void> read_compute_twin(const std::string& path, const Json& twin, std::size_t textureCount, int workgroup[3],
                               std::vector<MaterialBufferDef>& buffers, std::vector<MaterialImageDef>& images) {
    auto bad = [&](const std::string& what) {
        return make_error("the shader of material '" + path + "' is malformed: " + what, kReexportHint);
    };
    auto whole = [](const Json& j, std::int64_t lo, std::int64_t hi, std::int64_t& out) {
        if (!j.is_number_integer()) return false;
        const std::int64_t v = j.get<std::int64_t>();
        if (v < lo || v > hi) return false;
        out = v;
        return true;
    };
    std::int64_t n = 0;
    if (workgroup) {  // a mesh material has buffers but no threads
        auto wg = twin.find("workgroupSize");
        if (wg == twin.end() || !wg->is_array() || wg->size() != 3) return bad("it has no \"workgroupSize\" [x, y, z]");
        std::int64_t product = 1;
        for (std::size_t i = 0; i < 3; ++i) {
            if (!whole((*wg)[i], 1, 256, n)) return bad("\"workgroupSize\" holds a number outside 1..256");
            workgroup[i] = int(n);
            product *= n;
        }
        if (product > 256) return bad("\"workgroupSize\" asks for more than 256 threads in a group");
    }

    auto list = twin.find("buffers");
    if (list == twin.end() || !list->is_array()) return bad("it has no \"buffers\" list");
    if (list->size() > std::size_t(SG_MAX_VIEW_BINDSLOTS) ||
        list->size() + textureCount > std::size_t(SG_MAX_VIEW_BINDSLOTS))
        return bad("too many buffers and textures for one program");
    for (const Json& b : *list) {
        MaterialBufferDef def;
        def.name = text_of(b, "name");
        def.readOnly = text_of(b, "access") == "read";
        if (def.name.empty() || !b.contains("binding") || !whole(b["binding"], 0, SG_MAX_VIEW_BINDSLOTS - 1, n))
            return bad("a buffer without a name or a binding");
        def.binding = int(n);
        if (!b.contains("stride") || !whole(b["stride"], 4, 1 << 16, n))
            return bad("the buffer '" + def.name + "' has no stride");
        if (n % 4 != 0)
            return bad("the buffer '" + def.name + "' has a stride of " + std::to_string(n) +
                       " bytes, which is not a multiple of 4 (a field is made of 4-byte values)");
        def.stride = std::uint32_t(n);
        auto fields = b.find("fields");
        if (fields == b.end() || !fields->is_array() || fields->empty())
            return bad("the buffer '" + def.name + "' has no fields");
        for (const Json& f : *fields) {
            MaterialBufferFieldDef fd;
            fd.name = text_of(f, "name");
            fd.type = text_of(f, "type");
            if (!f.contains("offset") || !whole(f["offset"], 0, 1 << 16, n)) return bad("a field without an offset");
            fd.offset = std::uint32_t(n);
            if (fd.type == "float" || fd.type == "int" || fd.type == "uint")
                fd.components = 1;
            else if (fd.type == "vec2")
                fd.components = 2;
            else if (fd.type == "vec3")
                fd.components = 3;
            else if (fd.type == "vec4")
                fd.components = 4;
            else
                return bad("the field '" + def.name + "." + fd.name + "' has the type '" + fd.type + "'");
            fd.isInt = fd.type == "int";
            fd.isUint = fd.type == "uint";
            if (fd.name.empty() || std::uint64_t(fd.offset) + std::uint64_t(fd.components) * 4 > def.stride)
                return bad("the field '" + def.name + "." + fd.name + "' does not fit in " +
                           std::to_string(def.stride) + " bytes");
            def.fields.push_back(std::move(fd));
        }
        buffers.push_back(std::move(def));
    }

    // The storage images (absent in a twin of a material that declares none).
    if (auto imgs = twin.find("images"); imgs != twin.end()) {
        if (!imgs->is_array()) return bad("\"images\" is not a list");
        if (list->size() + imgs->size() + textureCount > std::size_t(SG_MAX_VIEW_BINDSLOTS))
            return bad("too many buffers, images and textures for one program");
        for (const Json& im : *imgs) {
            MaterialImageDef def;
            def.name = text_of(im, "name");
            if (def.name.empty() || !im.contains("binding") || !whole(im["binding"], 0, SG_MAX_VIEW_BINDSLOTS - 1, n))
                return bad("an image without a name or a binding");
            def.binding = int(n);
            const std::string format = text_of(im, "format");
            if (format == "rgba8")
                def.format = SG_PIXELFORMAT_RGBA8;
            else if (format == "rgba16f")
                def.format = SG_PIXELFORMAT_RGBA16F;
            else if (format == "r32f")
                def.format = SG_PIXELFORMAT_R32F;
            else if (format == "rgba32f")
                def.format = SG_PIXELFORMAT_RGBA32F;
            else
                return bad("the image '" + def.name + "' has the format '" + format + "'");
            def.readWrite = text_of(im, "access") == "readWrite";
            if (!im.contains("width") || !whole(im["width"], 1, 16384, n))
                return bad("the image '" + def.name + "' has no width");
            def.width = int(n);
            if (!im.contains("height") || !whole(im["height"], 1, 16384, n))
                return bad("the image '" + def.name + "' has no height");
            def.height = int(n);
            images.push_back(std::move(def));
        }
    }
    return {};
}

}  // namespace

Result<void> Assets::build_material_checked(MaterialAsset& m) {
    auto doc = load_json_file(m.path);
    if (!doc.ok())
        return make_error("material '" + m.path + "' could not be read: " + doc.error().message, doc.error().hint);
    if (!doc->is_object())
        return make_error("material '" + m.path + "' must be a JSON object",
                          "Start from the example in docs/SHADERS.md.");
    if (const std::string* s = str_of(*doc, "shader")) m.snippet = fs::normalize(*s);
    // "kind": absent = mesh. The tooling checks the file with a JSON pointer; a player reads it from an export.
    MaterialKind kind = MaterialKind::Mesh;
    if (auto k = doc->find("kind"); k != doc->end()) {
        const auto parsed = k->is_string() ? material_kind_from_name(k->get<std::string>()) : std::nullopt;
        if (!parsed)
            return make_error("material '" + m.path + "' has an unknown kind " +
                                  (k->is_string() ? "\"" + k->get<std::string>() + "\"" : describe_json_value(*k)),
                              k->is_string() ? did_you_mean(k->get<std::string>(), material_kind_names())
                                             : "Use one of: " + join(material_kind_names(), ", ") + ".");
        kind = *parsed;
    }
    // "mode": "full" = the file is the whole vertex and fragment shader of a mesh material
    // (docs/shaders/SHADERS_FULL.md).
    const bool full = str_of(*doc, "mode") && text_of(*doc, "mode") == "full";
    if (full && kind != MaterialKind::Mesh)
        return make_error("material '" + m.path + "' has mode \"full\" with kind \"" + material_kind_name(kind) +
                              "\": only mesh materials can be full shaders",
                          "Remove \"mode\", or remove \"kind\" (a mesh material is the default).");
    const std::string lighting = str_of(*doc, "lighting") ? text_of(*doc, "lighting") : "pbr";
    std::string alphaMode = str_of(*doc, "alphaMode") ? text_of(*doc, "alphaMode") : "opaque";
    const bool doubleSided = doc->find("doubleSided") != doc->end() && doc->at("doubleSided") == true;
    if (full) {  // the passes decide: a material with a blending pass is drawn far to near with the blended meshes
        alphaMode = "opaque";
        if (auto ps = doc->find("passes"); ps != doc->end() && ps->is_array())
            for (const Json& p : *ps)
                if (p.is_object() && str_of(p, "blend") && text_of(p, "blend") != "none") alphaMode = "blend";
    }
    if (!m.ok) {  // never built: the error material still needs to be sorted into the right draw list
        m.kind = kind;
        m.lighting = lighting;
        m.alphaMode = alphaMode;
        m.doubleSided = doubleSided;
    }
    if ((kind == MaterialKind::Mesh || kind == MaterialKind::Sprite) && doc->contains("buffers") &&
        !(*doc)["buffers"].empty()) {
        // A mesh or sprite material that reads storage buffers (M72.4): refused at load on a backend that cannot, with
        // the name of the backend and the CPU path, like a compute material.
        const bool spriteKind = kind == MaterialKind::Sprite;
        std::string backend, reason;
        if (!storage_buffers_available(&backend, &reason))
            return make_error(
                "the material '" + m.path +
                    "' reads storage buffers (\"buffers\", /buffers in the material), but the " + backend +
                    " graphics backend cannot read them in a vertex shader: " + reason,
                std::string("Storage buffers in a ") + (spriteKind ? "sprite" : "mesh") +
                    " material run on Windows (D3D11), macOS and iOS (Metal) and Linux (OpenGL 4.3 or newer), not on "
                    "Android (GLES3), the web (WebGL2) or macOS OpenGL (4.1). Ask `render.supports` "
                    "{\"feature\":\"computeShaders\"} first, and on this backend use the CPU path: write the instances "
                    "as "
                    "entities (or as \"instanced\" params of a material without buffers) from a script "
                    "(docs/shaders/SHADERS_COMPUTE.md, \"Drawing from a compute buffer\").");
        // OpenGL counts the bindings of a program from 0 (the glsl430 twin does): each buffer is declared in the vertex
        // and in the fragment stage, so the program needs two bindings per buffer. GL 4.3 guarantees only 8 and many
        // drivers give 16.
        const std::size_t buffers = std::min<std::size_t>((*doc)["buffers"].size(), kMaxMeshBuffers);
        bool limited = false;
        const int limit = storage_binding_limit(&limited);
        if (limited && int(buffers) * 2 > limit)
            return make_error(
                "the material '" + m.path + "' reads " + std::to_string(buffers) + " storage buffer" +
                    (buffers == 1 ? "" : "s") + " (\"buffers\", /buffers in the material), which takes " +
                    std::to_string(buffers * 2) + " storage buffer bindings (one per stage for each buffer), but the " +
                    backend + " graphics driver offers " + std::to_string(limit) +
                    " (GL_MAX_SHADER_STORAGE_BUFFER_BINDINGS)",
                "Declare at most " + std::to_string(limit / 2) +
                    " buffers in this material (pack several arrays into one buffer's fields), or use the CPU path on "
                    "this computer: write the instances as entities (or as \"instanced\" params of a material without "
                    "buffers) from a script (docs/shaders/SHADERS_COMPUTE.md, \"Drawing from a compute buffer\").");
    }
    // The twin: from the compiler of the editor / `factoria`, else from the file an export wrote.
    const std::string dialect = backend_dialect(gpu_.device().info());
    Json twin;
    if (shaderCompiler_) {
        auto r = shaderCompiler_(m.path, dialect);
        if (!r.ok()) return make_error(r.error().message, r.error().hint);
        twin = std::move(*r);
    } else {
        const std::string file = m.path + "." + dialect + ".shader";
        if (!fs::exists(file))
            return make_error("material '" + m.path + "' has no compiled shader: '" + file + "' does not exist",
                              kReexportHint);
        auto r = load_json_file(file);
        if (!r.ok()) return make_error("shader '" + file + "' could not be read: " + r.error().message, kReexportHint);
        twin = std::move(*r);
    }
    if (text_of(twin, "format") != "factoria.shader/1")
        return make_error("the shader of material '" + m.path + "' has format '" + text_of(twin, "format") +
                              "', expected 'factoria.shader/1'",
                          kReexportHint);
    // A twin without "kind" is a mesh twin (the format before M72).
    const std::string twinKind = str_of(twin, "kind") ? text_of(twin, "kind") : "mesh";
    if (twinKind != material_kind_name(kind))
        return make_error("the shader of material '" + m.path + "' is a \"" + twinKind +
                              "\" shader, but the material has kind \"" + material_kind_name(kind) + "\"",
                          "The material's \"kind\" changed after its shader was made. " + std::string(kReexportHint));
    if (full != (twin.contains("full") && twin["full"] == true))
        return make_error("the shader of material '" + m.path + "' was made " +
                              (full ? "without mode \"full\"" : "with mode \"full\"") +
                              ", but the material says the opposite",
                          "The material's \"mode\" changed after its shader was made. " + std::string(kReexportHint));
    if (text_of(twin, "engine") != FA_ENGINE_VERSION ||
        text_of(twin, "template") != (full ? mesh_full_template_hash() : material_template_hash(kind)))
        return make_error(
            "the shader of material '" + m.path + "' was made by factoria " + text_of(twin, "engine") +
                (text_of(twin, "engine") == FA_ENGINE_VERSION
                     ? std::string(" with another ") + (full ? "full-shader" : material_kind_name(kind)) + " template"
                     : ", but this is " + std::string(FA_ENGINE_VERSION)),
            kReexportHint);
    if (text_of(twin, "slang") != dialect)
        return make_error("the shader of material '" + m.path + "' is for '" + text_of(twin, "slang") +
                              "', this graphics backend needs '" + dialect + "'",
                          kReexportHint);

    // Params and textures, in the order of the twin (the order of the packed block and of the texture bindings).
    auto section = [&](const char* key) {
        auto it = doc->find(key);
        return it != doc->end() && it->is_object() ? &*it : nullptr;
    };
    const Json* paramDefs = section("params");
    const Json* textureDefs = section("textures");
    std::vector<MaterialParamDef> params, instanced;
    std::vector<MaterialTextureDef> textures;
    // The definition of param `name` as the material file declares it (the twin only names it).
    auto param_def = [&](const std::string& name) -> Result<MaterialParamDef> {
        MaterialParamDef d;
        d.name = name;
        auto it = paramDefs ? paramDefs->find(d.name) : Json::const_iterator();
        if (paramDefs && it != paramDefs->end() && it->is_object()) {
            const std::string type = text_of(*it, "type");
            d.components = type == "vec2" ? 2 : type == "vec3" ? 3 : (type == "vec4" || type == "color") ? 4 : 1;
            auto def = it->find("default");
            if (def != it->end() && def->is_number())
                d.def[0] = def->get<float>();
            else if (def != it->end() && def->is_array())
                for (std::size_t c = 0; c < def->size() && c < 4; ++c)
                    if ((*def)[c].is_number()) d.def[c] = (*def)[c].get<float>();
        } else if (d.name == "alphaCutoff") {
            d.def[0] = 0.5f;
        } else {
            return make_error("the shader of material '" + m.path + "' lists the param '" + d.name +
                                  "', which /params of the material does not declare",
                              "The material changed after its shader was made. " + std::string(kReexportHint));
        }
        return d;
    };
    for (const Json& n : twin.value("params", Json::array())) {
        auto d = param_def(n.is_string() ? n.get<std::string>() : std::string());
        if (!d.ok()) return d.error();
        params.push_back(std::move(*d));
    }
    // The per-instance params: where each sits in the instance buffer (fa/tooling/shaders.h instance_layout).
    const int instanceVec4 = int_or(twin, "instanceVec4", 0);
    for (const Json& n : twin.value("instanced", Json::array())) {
        auto d = param_def(text_of(n, "name"));
        if (!d.ok()) return d.error();
        d->vec4 = int_or(n, "vec4", -1);
        d->offset = int_or(n, "offset", -1);
        if (int_or(n, "components", 0) != d->components || d->vec4 < 0 || d->vec4 >= instanceVec4 || d->offset < 0 ||
            d->offset + d->components > 4)
            return make_error("the shader of material '" + m.path + "' places the instanced param '" + d->name +
                                  "' where the material does not (vec4 " + std::to_string(d->vec4) + ", float " +
                                  std::to_string(d->offset) + " of " + std::to_string(instanceVec4) + " vec4)",
                              "The material changed after its shader was made. " + std::string(kReexportHint));
        instanced.push_back(std::move(*d));
    }
    if (instanceVec4 < 0 || instanceVec4 > kMaxInstanceVec4 || (instanceVec4 > 0) != !instanced.empty())
        return make_error("the shader of material '" + m.path + "' has " + std::to_string(instanceVec4) +
                              " vec4 of per-instance data, at most " + std::to_string(kMaxInstanceVec4),
                          kReexportHint);
    bool uv1 = false, color1 = false;
    for (const Json& n : twin.value("vertexAttributes", Json::array())) {
        const std::string name = n.is_string() ? n.get<std::string>() : std::string();
        if (name == "uv1")
            uv1 = true;
        else if (name == "color1")
            color1 = true;
        else
            return make_error("the shader of material '" + m.path + "' declares the vertex attribute '" + name +
                                  "', which this engine version does not know",
                              kReexportHint);
    }
    if (params.size() > std::size_t(kMaxMaterialParams))
        return make_error("the shader of material '" + m.path + "' has " + std::to_string(params.size()) +
                              " params, at most " + std::to_string(kMaxMaterialParams),
                          kReexportHint);
    if (twin.value("textures", Json::array()).size() > std::size_t(kMaxMaterialTextures))
        return make_error("the shader of material '" + m.path + "' has more than " +
                              std::to_string(kMaxMaterialTextures) + " textures",
                          kReexportHint);
    for (const Json& n : twin.value("textures", Json::array())) {
        MaterialTextureDef d;
        d.name = n.is_string() ? n.get<std::string>() : std::string();
        auto it = textureDefs ? textureDefs->find(d.name) : Json::const_iterator();
        if (!textureDefs || it == textureDefs->end() || !it->is_object())
            return make_error("the shader of material '" + m.path + "' lists the texture '" + d.name +
                                  "', which /textures of the material does not declare",
                              "The material changed after its shader was made. " + std::string(kReexportHint));
        d.sampler = sampler_kind(text_of(*it, "sampler"));
        d.defaultTex = texture(text_of(*it, "default"));
        textures.push_back(std::move(d));
    }

    // A compute material: the threads of a group and the storage buffers (the tooling made the std430 layout).
    std::vector<MaterialBufferDef> buffers;
    std::vector<MaterialImageDef> images;
    int workgroup[3] = {64, 1, 1};
    if ((kind == MaterialKind::Mesh || kind == MaterialKind::Sprite) && twin.contains("buffers")) {
        auto read = read_compute_twin(m.path, twin, textures.size(), nullptr, buffers, images);
        if (!read.ok()) return read.error();
        if (buffers.size() > std::size_t(kMaxMeshBuffers))
            return make_error("the shader of material '" + m.path + "' has " + std::to_string(buffers.size()) +
                                  " buffers, at most " + std::to_string(kMaxMeshBuffers) + " are read by a " +
                                  material_kind_name(kind) + " material",
                              kReexportHint);
        images.clear();
    }
    if (kind == MaterialKind::Compute) {
        auto compute = read_compute_twin(m.path, twin, textures.size(), workgroup, buffers, images);
        if (!compute.ok()) return compute.error();
        // The per-material cap of this GPU: the tooling allows the portable minimum (4); a GPU may allow fewer.
        const int imageLimit = gpu_.has_device() ? gpu_.device().limits().maxStorageImageBindingsPerStage : 0;
        if (gpu_.has_device() && int(images.size()) > imageLimit)
            return make_error("the compute material '" + m.path + "' declares " + std::to_string(images.size()) +
                                  " storage images, but this graphics driver binds at most " +
                                  std::to_string(imageLimit) + " to one shader",
                              "Pack the channels written together into one rgba image, or split the work in two "
                              "materials.");
    }

    // The shaders. Nothing of `m` changes unless all of them are made.
    std::vector<std::string> textureNames;  // what the pair-limit error counts as the material's own
    for (const MaterialTextureDef& t : textures) textureNames.push_back(t.name);
    const std::vector<const char*>& names = material_program_names(kind);
    MaterialProgram programs[kMaxMaterialPrograms];
    auto programsJson = twin.find("programs");
    std::vector<MaterialPassState> passes;
    FullShadow shadowMode = FullShadow::Depth;
    bool prepassOn = true;
    if (full) {
        // The passes in drawing order with their state; each names its programs in the twin. Every program is required
        // (the tooling made them together), the shadow and prepass ones only when the twin says the material has them.
        const std::string shadowName = text_of(twin, "shadow");
        shadowMode = shadowName == "custom" ? FullShadow::Custom
                     : shadowName == "none" ? FullShadow::None
                                            : FullShadow::Depth;
        prepassOn = !(twin.contains("prepass") && twin["prepass"] == false);
        const Json& list = list_of(twin, "passes");
        if (list.empty() || list.size() > std::size_t(kMaxMaterialPasses))
            return make_error("the shader of material '" + m.path + "' has " + std::to_string(list.size()) +
                                  " passes, between 1 and " + std::to_string(kMaxMaterialPasses) + " are drawn",
                              kReexportHint);
        std::vector<std::pair<std::string, int>> wanted;  // twin program name, MaterialAsset::programs slot
        for (std::size_t p = 0; p < list.size(); ++p) {
            const Json& e = list[p];
            MaterialPassState st;
            st.name = text_of(e, "name");
            const std::string cull = text_of(e, "cull"), blend = text_of(e, "blend");
            st.cull = cull == "none" ? 0 : cull == "front" ? 2 : 1;
            st.depthTest = !(e.contains("depthTest") && e["depthTest"] == false);
            st.depthWrite = !(e.contains("depthWrite") && e["depthWrite"] == false);
            st.blend = blend == "alpha" ? 1 : blend == "additive" ? 2 : blend == "multiply" ? 3 : 0;
            passes.push_back(std::move(st));
            wanted.push_back({text_of(e, "program"), pass_program_slot(int(p), false)});
            wanted.push_back({text_of(e, "programSkin"), pass_program_slot(int(p), true)});
        }
        if (shadowMode == FullShadow::Custom) {
            wanted.push_back({"shadow", kProgShadow});
            wanted.push_back({"shadow_skin", kProgShadowSkin});
        }
        if (prepassOn) {
            wanted.push_back({"prepass", kProgPrepass});
            wanted.push_back({"prepass_skin", kProgPrepassSkin});
        }
        for (const auto& [name, slot] : wanted) {
            const Json* prog = programsJson != twin.end() && programsJson->is_object() && programsJson->contains(name)
                                   ? &programsJson->at(name)
                                   : nullptr;
            Result<MaterialProgram> made =
                prog ? make_material_program(gpu_.device(), m.path + " " + name, *prog, nullptr, &textureNames)
                     : make_error("the shader of material '" + m.path + "' has no program '" + name + "'",
                                  kReexportHint);
            if (!made.ok()) {
                for (MaterialProgram& p : programs)
                    if (p.shader.id) gpu_.destroy_shader(p.shader);
                return made.error();
            }
            programs[slot] = *made;
        }
    }
    for (int i = 0; !full && i < int(names.size()); ++i) {
        const Json* prog = programsJson != twin.end() && programsJson->is_object() && programsJson->contains(names[i])
                               ? &programsJson->at(names[i])
                               : nullptr;
        Result<MaterialProgram> made =
            prog ? make_material_program(gpu_.device(), m.path + " " + names[i], *prog,
                                         kind == MaterialKind::Compute ? workgroup : nullptr, &textureNames)
                 : make_error("the shader of material '" + m.path + "' has no program '" + names[i] + "'",
                              kReexportHint);
        if (made.ok()) {
            programs[i] = *made;
        } else if (!prog && i >= kProgPrepass) {
            FA_WARN(
                "render",
                "the shader of material '{}' has no program '{}' (made before the depth and normal prepass): the post "
                "effects that read the depth do not see this material until the shader is made again ({})",
                m.path, names[i], kReexportHint);
        } else if (prog || i < kProgShadow) {  // the shadow and prepass programs are optional, a broken one is not
            for (MaterialProgram& p : programs)
                if (p.shader.id) gpu_.destroy_shader(p.shader);
            return made.error();
        }
    }
    for (MaterialProgram& old : m.programs)
        if (old.shader.id) gpu_.destroy_shader(old.shader);
    std::copy(std::begin(programs), std::end(programs), std::begin(m.programs));
    m.kind = kind;
    m.lighting = lighting;
    m.alphaMode = alphaMode;
    m.doubleSided = doubleSided;
    m.full = full;
    m.passes = std::move(passes);
    m.shadow = shadowMode;
    m.prepass = prepassOn;
    m.params = std::move(params);
    m.instanced = std::move(instanced);
    m.instanceVec4 = instanceVec4;
    m.uv1 = uv1;
    m.color1 = color1;
    m.animated = kind == MaterialKind::Sky && twin.value("animated", false);
    m.usesSun = kind == MaterialKind::Sky && twin.value("usesSun", false);
    m.missingNoted.clear();  // the "material-mesh" failures of the old build went too (build_material erases them)
    m.instancedNames.clear();
    for (const MaterialParamDef& p : m.instanced) m.instancedNames.push_back(p.name);
    std::sort(m.instancedNames.begin(), m.instancedNames.end());
    m.instancedKey = 0;
    for (const std::string& n : m.instancedNames)
        m.instancedKey = m.instancedKey * 1000003u + std::hash<std::string>{}(n);
    m.textures = std::move(textures);
    m.buffers = std::move(buffers);
    m.images = std::move(images);
    std::copy(std::begin(workgroup), std::end(workgroup), std::begin(m.workgroup));
    return {};
}

void Assets::build_material(MaterialAsset& m) {
    auto r = build_material_checked(m);
    failures_.erase(std::remove_if(failures_.begin(), failures_.end(),
                                   [&](const Failure& f) {
                                       return (f.kind == "material" && f.path == m.path) ||
                                              (f.kind == "material-mesh" && f.path.rfind(m.path + " on ", 0) == 0);
                                   }),
                    failures_.end());
    if (r.ok()) {
        m.ok = true;
        m.error.clear();
        m.warned.erase("<kind>");  // a material of the wrong kind that was fixed warns again if it is broken again
        ++m.generation;
        return;
    }
    m.error = r.error().message;
    note_failure("material", m.path,
                 r.error().message +
                     (m.ok                              ? "\nThe previous version of the material stays in use."
                      : m.kind == MaterialKind::Post    ? "\nThe custom post passes using it are skipped."
                      : m.kind == MaterialKind::Sky     ? "\nThe sky using it is drawn as the built-in gradient."
                      : m.kind == MaterialKind::Compute ? "\nThe compute.* commands that name it fail with this error."
                                                        : "\nThe meshes and sprites using it are drawn magenta."),
                 r.error().hint);
}

MaterialAsset* Assets::material(const std::string& path) {
    std::string key = fs::normalize(path);
    if (key.empty()) key = path;
    auto& slot = materials_[key];
    if (!slot) {
        slot = std::make_unique<MaterialAsset>();
        slot->path = key;
        build_material(*slot);
    }
    return slot.get();
}

}  // namespace fa::render

namespace fa::render {

namespace {
constexpr std::uint64_t kUseKeepFrames = 2;  // a use survives this many frames without an item asking for it

// Params with no entries are the same set whether they are null or {}.
bool params_empty(const Json& j) { return j.is_null() || ((j.is_object() || j.is_array()) && j.empty()); }
bool values_equal(const Json& a, const Json& b) {
    if (&a == &b) return true;
    if (params_empty(a) && params_empty(b)) return true;
    return a == b;
}
std::uint64_t hash_json(const Json& j, std::uint64_t h) {
    auto mix = [&](std::uint64_t x) { h = (h ^ x) * 1099511628211ull; };
    if (j.is_object()) {
        mix(1);
        for (auto it = j.begin(); it != j.end(); ++it) {
            for (unsigned char c : it.key()) mix(c);
            h = hash_json(it.value(), h);
        }
    } else if (j.is_array()) {
        mix(2);
        for (const Json& e : j) h = hash_json(e, h);
    } else if (j.is_string()) {
        mix(3);
        for (unsigned char c : j.get_ref<const std::string&>()) mix(c);
    } else if (j.is_number()) {
        mix(4);  // 1 and 1.0 compare equal, so numbers hash as doubles
        double d = j.get<double>();
        if (d == 0.0) d = 0.0;  // -0 == 0
        std::uint64_t bits = 0;
        std::memcpy(&bits, &d, sizeof bits);
        mix(bits);
    } else if (j.is_boolean()) {
        mix(j.get<bool>() ? 5 : 6);
    } else {
        mix(7);
    }
    return h;
}
std::uint64_t hash_params(const Json& j) { return params_empty(j) ? 0 : hash_json(j, 1469598103934665603ull); }
}  // namespace

MaterialRef Assets::sprite_material(const std::string& path, const Json& overrides) {
    return kind_material(path, overrides, MaterialKind::Sprite);
}

MaterialRef Assets::sprite_material_once(const std::string& path, const Json& overrides) {
    if (path.empty()) return {};
    return resolve_kind_material(path, overrides, MaterialKind::Sprite);
}

MaterialRef Assets::post_material(const std::string& path, const Json& overrides) {
    return kind_material(path, overrides, MaterialKind::Post);
}

MaterialRef Assets::kind_material(const std::string& path, const Json& overrides, MaterialKind want) {
    if (path.empty()) return {};
    // The answers of this frame by path, then by values: a second ask about the same component, or about another one
    // with equal values (the usual case: a thousand sprites with one material), costs one hash-map find and a
    // comparison of the values in place (nothing is copied).
    // The "sprite" and the "post" lookups of one path keep apart: the answer holds the kind's own check (a material of
    // another kind is answered with its error), so one cannot serve the other.
    PathVariants& perPath = materialVariants_[path];
    KindVariants& variants = want == MaterialKind::Post ? perPath.post : perPath.sprite;
    // No params at all (the usual case: a thousand sprites with one material): one answer, nothing hashed, nothing
    // inserted.
    const bool noParams = params_empty(overrides);
    if (noParams && variants.hasEmpty) return variants.empty;
    // The same component asked again: its address is the answer, while its values still hash as they did when it was
    // resolved (comparing it with itself would prove nothing: the entry holds the component's address, not a copy). A
    // component written to after that, in the same frame, is answered by its values below.
    const std::uint64_t h = noParams ? 0 : hash_params(overrides);
    if (!noParams) {
        if (auto it = variants.byPointer.find(&overrides); it != variants.byPointer.end()) {
            if (it->second.hash == h) return it->second.ref;
            if (!variantsChangedNoted_) {
                variantsChangedNoted_ = true;
                FA_WARN(
                    "render",
                    "the materialParams of a 2D item changed while the frame was being drawn (material '{}'): the item "
                    "is drawn with the material of its current values. Write materialParams in update(), never while "
                    "rendering. (Said once.)",
                    path);
            }
            variants.byPointer.erase(it);
        }
    }
    // Another component: found by the hash of its values (compared in place only on a hash match, so any number of
    // distinct sets costs one hash, not a walk over the others). A hit is not entered by address: that would allocate a
    // map node for every sprite of every frame, and the hash of a small set costs less.
    if (!noParams) {
        auto [first, last] = variants.byValue.equal_range(h);
        for (auto it = first; it != last; ++it)
            if (values_equal(*it->second.params, overrides)) return it->second.ref;
    }
    // A set of values not seen this frame: the whole lookup (path normalized, params packed, hashed, interned).
    const MaterialRef ref = resolve_kind_material(path, overrides, want);
    ++materialResolves_;
    if (noParams) {
        variants.empty = ref;
        variants.hasEmpty = true;
        return ref;
    }
    const MaterialVariant v{&overrides, h, ref};
    variants.byValue.emplace(h, v);
    variants.byPointer.emplace(&overrides, v);
    return ref;
}

MaterialRef Assets::resolve_kind_material(const std::string& path, const Json& overrides, MaterialKind want) {
    MaterialAsset* m = material(path);
    const std::uint64_t tick = useTick_;
    const bool wrongKind = m->ok && m->kind != want;
    if (wrongKind && m->warned.insert("<kind>").second) {
        if (want == MaterialKind::Post)
            FA_WARN("render",
                    "the material '{}' has kind \"{}\", but a custom post pass (PostProcess.customPasses) needs a "
                    "\"post\" material: the pass is skipped",
                    m->path, material_kind_name(m->kind));
        else
            FA_WARN("render",
                    "the material '{}' has kind \"{}\", but a 2D item (Sprite, Shape2D, Tilemap, Text, "
                    "ParticleEmitter, UiBox) needs a \"sprite\" material: the item is drawn magenta",
                    m->path, material_kind_name(m->kind));
    }
    const bool error = !m->ok || wrongKind;

    MaterialUse key;
    key.material = m;
    key.error = error;
    std::uint64_t hash = 1469598103934665603ull;
    auto mix = [&](const void* data, std::size_t n) {
        const unsigned char* p = static_cast<const unsigned char*>(data);
        for (std::size_t i = 0; i < n; ++i) hash = (hash ^ p[i]) * 1099511628211ull;
    };
    const std::uint64_t head[2] = {std::uint64_t(m->generation), error ? 1u : 0u};
    mix(head, sizeof(head));
    const std::size_t nParams = std::min<std::size_t>(m->params.size(), kMaxMaterialParams);
    const std::size_t nTextures = std::min<std::size_t>(m->textures.size(), kMaxMaterialTextures);
    if (!error) {
        pack_material_params(*m, overrides, key.params);
        for (std::size_t i = 0; i < nTextures; ++i) key.textures[i] = material_texture(*m, int(i), overrides, *this);
        mix(key.params, nParams * sizeof(key.params[0]));
        mix(key.textures, nTextures * sizeof(key.textures[0]));
        // The compute buffers of a material with "buffers" are part of what a batch draws from: the id of each, -1 when
        // the value is not an integer (the Sprite is refused when it is gathered, sprite_buffer_draw.cpp, which says
        // why).
        const std::size_t nBuffers = std::min<std::size_t>(m->buffers.size(), std::size_t(kMaxMeshBuffers));
        for (std::size_t i = 0; i < nBuffers; ++i) {
            const Json::const_iterator it =
                overrides.is_object() ? overrides.find(m->buffers[i].name) : Json::const_iterator();
            if (overrides.is_object() && it != overrides.end() && it->is_number_integer())
                key.bufferIds[i] = it->get<std::int64_t>();
        }
        mix(key.bufferIds, nBuffers * sizeof(key.bufferIds[0]));
    }
    MaterialRef ref;
    auto [first, last] = m->uses.equal_range(hash);
    for (auto it = first; it != last; ++it) {
        MaterialUse& u = *it->second;
        if (u.error == error && std::memcmp(u.params, key.params, nParams * sizeof(key.params[0])) == 0 &&
            std::equal(std::begin(u.bufferIds), std::end(u.bufferIds), std::begin(key.bufferIds)) &&
            std::memcmp(u.textures, key.textures, nTextures * sizeof(key.textures[0])) == 0) {
            u.tick = tick;
            ref.use = &u;
            break;
        }
    }
    if (!ref.use) {
        key.tick = tick;
        // The instanced params are not part of the key: sprites that differ only in them share the use (and the batch).
        key.instVec4 = error ? 0 : m->instanceVec4;
        auto made = std::make_unique<MaterialUse>(key);
        ref.use = made.get();
        m->uses.emplace(hash, std::move(made));
    }
    // This item's own values of the instanced params travel with its quads (QuadList::set_material).
    if (ref.use->instVec4 > 0) pack_instance_params(*m, overrides, ref.inst);
    return ref;
}

void Assets::begin_material_frame() {
    ++useTick_;
    drop_material_cache();
    materialResolves_ = 0;
    for (auto& [k, m] : materials_)
        for (auto it = m->uses.begin(); it != m->uses.end();) {
            if (useTick_ - it->second->tick > kUseKeepFrames)
                it = m->uses.erase(it);
            else
                ++it;
        }
}

}  // namespace fa::render
