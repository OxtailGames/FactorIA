// Custom materials (MeshRenderer.material): the factoria.shader/1 twin -> sg_shader_desc (docs/design/CUSTOM_SHADERS.md),
// and the packing of a material's params.
#include "fa/core/engine_version.h"
#include <algorithm>
#include <cmath>
#include <cstring>

#include "fa/core/fs.h"
#include "fa/core/log.h"
#include "fa/core/strings.h"
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

}  // namespace fa

namespace fa::render {

std::string backend_dialect(sg_backend backend) {
    switch (backend) {
        case SG_BACKEND_D3D11: return "hlsl5";
        case SG_BACKEND_GLCORE: return "glsl430";
        case SG_BACKEND_GLES3: return "glsl300es";
        case SG_BACKEND_METAL_MACOS: return "metal_macos";
        case SG_BACKEND_METAL_IOS: return "metal_ios";
        case SG_BACKEND_METAL_SIMULATOR: return "metal_sim";
        default: return {};
    }
}

const std::vector<const char*>& material_program_names(MaterialKind kind) {
    // The order of MaterialProgramId. The other kinds list theirs when their package makes them buildable.
    static const std::vector<const char*> mesh = {"mesh",        "mesh_skin", "shadow",
                                                  "shadow_skin", "prepass",   "prepass_skin"};
    // Sprite: quad (every mode of quad_common.glsl) and quad_plain (a batch of plain textured quads); a material has both.
    static const std::vector<const char*> sprite = {"quad", "quad_plain"};
    // Sky: the one program of sky_common.glsl.
    static const std::vector<const char*> sky = {"sky"};
    static const std::vector<const char*> compute = {"compute"};
    static const std::vector<const char*> none;
    switch (kind) {
        case MaterialKind::Mesh: return mesh;
        case MaterialKind::Sprite: return sprite;
        case MaterialKind::Sky: return sky;
        case MaterialKind::Compute: return compute;
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

}  // namespace

Result<sg_shader_desc> material_shader_desc(const std::string& label, const Json& program, MaterialProgram& out,
                                            const int* workgroup) {
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
        if (auto sb = v.find("storage_buffer"); cs && sb != v.end() && sb->is_object()) {
            const int slot = int_or(*sb, "slot", -1);
            if (slot < 0 || slot >= SG_MAX_VIEW_BINDSLOTS)
                return bad("a storage buffer slot outside 0.." + std::to_string(SG_MAX_VIEW_BINDSLOTS - 1));
            sg_shader_storage_buffer_view& bv = desc.views[slot].storage_buffer;
            bv.stage = SG_SHADERSTAGE_COMPUTE;
            bv.readonly = sb->find("readonly") != sb->end() && sb->at("readonly") == true;
            bv.hlsl_register_t_n = std::uint8_t(int_or(*sb, "hlsl_register_t_n"));
            bv.hlsl_register_u_n = std::uint8_t(int_or(*sb, "hlsl_register_u_n"));
            bv.msl_buffer_n = std::uint8_t(int_or(*sb, "msl_buffer_n"));
            bv.glsl_binding_n = std::uint8_t(int_or(*sb, "glsl_binding_n"));
            out.viewMask |= 1u << slot;
            continue;
        }
        auto t = v.find("texture");
        if (t == v.end() || !t->is_object())
            return bad("a view that is not a texture (storage images are not supported" +
                       std::string(cs ? ")" : ", and storage buffers only in a compute program)"));
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
    for (const Json& p : list_of(*refl, "texture_sampler_pairs")) {
        if (pairs >= SG_MAX_TEXTURE_SAMPLER_PAIRS) return bad("too many texture-sampler pairs");
        desc.texture_sampler_pairs[pairs++] = {stage_of(p), std::uint8_t(int_or(p, "view_slot")),
                                               std::uint8_t(int_or(p, "sampler_slot")), cstr_or_null(p, "glsl_name")};
    }

    return desc;
}

Result<MaterialProgram> make_material_program(const std::string& label, const Json& program, const int* workgroup) {
    MaterialProgram out;
    auto made = material_shader_desc(label, program, out, workgroup);
    if (!made.ok()) return made.error();
    const std::string where = "the program '" + label + "'";
    out.shader = make_shader(&*made, label.c_str());
    if (sg_query_shader_state(out.shader) != SG_RESOURCESTATE_VALID) {
        sg_destroy_shader(out.shader);
        return make_error("the graphics driver rejected " + where + " (backend " + backend_dialect(sg_query_backend()) +
                              "; the sokol log lines above have the driver message)",
                          "The shaders were compiled for this backend by sokol-shdc and passed `factoria validate`, so "
                          "this is a driver problem: update the graphics driver, "
                          "and report it with the log lines above.");
    }
    return out;
}

namespace {
// The value of param `p` for an entity: the default overlaid by `overrides[p.name]`; a value of the wrong shape is warned about
// once per material and keeps the default. `field` and `holder` name where `overrides` came from, for the warning.
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

// The compute part of a twin: "workgroupSize" [x, y, z] and "buffers" (tools/common/src/shaders_compute.cpp compute_twin_fields).
// Every number is range-checked before it is narrowed: the file may come from an export made by another version.
Result<void> read_compute_twin(const std::string& path, const Json& twin, std::size_t textureCount, int workgroup[3],
                               std::vector<MaterialBufferDef>& buffers) {
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
    auto wg = twin.find("workgroupSize");
    if (wg == twin.end() || !wg->is_array() || wg->size() != 3) return bad("it has no \"workgroupSize\" [x, y, z]");
    std::int64_t product = 1;
    for (std::size_t i = 0; i < 3; ++i) {
        if (!whole((*wg)[i], 1, 256, n)) return bad("\"workgroupSize\" holds a number outside 1..256");
        workgroup[i] = int(n);
        product *= n;
    }
    if (product > 256) return bad("\"workgroupSize\" asks for more than 256 threads in a group");

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
    const std::string lighting = str_of(*doc, "lighting") ? text_of(*doc, "lighting") : "pbr";
    const std::string alphaMode = str_of(*doc, "alphaMode") ? text_of(*doc, "alphaMode") : "opaque";
    const bool doubleSided = doc->find("doubleSided") != doc->end() && doc->at("doubleSided") == true;
    if (!m.ok) {  // never built: the error material still needs to be sorted into the right draw list
        m.kind = kind;
        m.lighting = lighting;
        m.alphaMode = alphaMode;
        m.doubleSided = doubleSided;
    }
    if (material_program_names(kind).empty()) {
        // The package of each kind is the one the tooling names (shaders_generate.cpp kind_refusal).
        const char* package = "M72.2";  // only post is left: compute has its program, sky and sprite are drawn
        return make_error(
            "material '" + m.path + "' has kind \"" + material_kind_name(kind) +
                "\", which this factoria version cannot draw yet: " + material_kind_name(kind) +
                " materials arrive with " + package,
            "\"mesh\", \"sprite\" and \"sky\" materials are drawn, \"compute\" ones run with the compute.* commands "
            "(docs/design/CUSTOM_SHADERS.md, "
            "\"Kinds (M72)\").");
    }

    // The twin: from the compiler of the editor / `factoria`, else from the file an export wrote.
    const std::string dialect = backend_dialect(sg_query_backend());
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
    if (text_of(twin, "engine") != FA_ENGINE_VERSION || text_of(twin, "template") != material_template_hash(kind))
        return make_error("the shader of material '" + m.path + "' was made by factoria " + text_of(twin, "engine") +
                              (text_of(twin, "engine") == FA_ENGINE_VERSION
                                   ? std::string(" with another ") + material_kind_name(kind) + " template"
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
    int workgroup[3] = {64, 1, 1};
    if (kind == MaterialKind::Compute) {
        auto compute = read_compute_twin(m.path, twin, textures.size(), workgroup, buffers);
        if (!compute.ok()) return compute.error();
    }

    // The shaders. Nothing of `m` changes unless all of them are made.
    const std::vector<const char*>& names = material_program_names(kind);
    MaterialProgram programs[kMaxMaterialPrograms];
    auto programsJson = twin.find("programs");
    for (int i = 0; i < int(names.size()); ++i) {
        const Json* prog = programsJson != twin.end() && programsJson->is_object() && programsJson->contains(names[i])
                               ? &programsJson->at(names[i])
                               : nullptr;
        Result<MaterialProgram> made =
            prog ? make_material_program(m.path + " " + names[i], *prog,
                                         kind == MaterialKind::Compute ? workgroup : nullptr)
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
    m.params = std::move(params);
    m.instanced = std::move(instanced);
    m.instanceVec4 = instanceVec4;
    m.uv1 = uv1;
    m.color1 = color1;
    m.missingNoted.clear();  // the "material-mesh" failures of the old build went too (build_material erases them)
    m.instancedNames.clear();
    for (const MaterialParamDef& p : m.instanced) m.instancedNames.push_back(p.name);
    std::sort(m.instancedNames.begin(), m.instancedNames.end());
    m.instancedKey = 0;
    for (const std::string& n : m.instancedNames)
        m.instancedKey = m.instancedKey * 1000003u + std::hash<std::string>{}(n);
    m.textures = std::move(textures);
    m.buffers = std::move(buffers);
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
        ++m.generation;
        return;
    }
    m.error = r.error().message;
    note_failure("material", m.path,
                 r.error().message + (m.ok ? "\nThe previous version of the material stays in use."
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
}  // namespace

MaterialRef Assets::sprite_material(const std::string& path, const Json& overrides) {
    if (path.empty()) return {};
    // The answers of this frame by path, then by values: a second ask about the same component, or about another one with equal
    // values (the usual case: a thousand sprites with one material), costs one hash-map find and a comparison of the values in
    // place (nothing is copied).
    std::vector<MaterialVariant>& variants = materialVariants_[path];
    for (const MaterialVariant& v : variants)
        if (v.params == &overrides || (v.params->empty() && overrides.empty()) || *v.params == overrides) return v.ref;
    // A set of values not seen this frame: the whole lookup (path normalized, params packed, hashed, interned).
    const MaterialRef ref = resolve_sprite_material(path, overrides);
    ++materialResolves_;
    if (variants.size() < kMaxMaterialVariants) variants.push_back({&overrides, ref});
    return ref;
}

MaterialRef Assets::resolve_sprite_material(const std::string& path, const Json& overrides) {
    MaterialAsset* m = material(path);
    const std::uint64_t tick = useTick_;
    const bool wrongKind = m->ok && m->kind != MaterialKind::Sprite;
    if (wrongKind && m->warned.insert("<kind>").second)
        FA_WARN(
            "render",
            "the material '{}' has kind \"{}\", but a 2D item (Sprite, Shape2D, Tilemap, Text, ParticleEmitter, UiBox) "
            "needs a \"sprite\" material: the item is drawn magenta",
            m->path, material_kind_name(m->kind));
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
    }
    MaterialRef ref;
    auto [first, last] = m->uses.equal_range(hash);
    for (auto it = first; it != last; ++it) {
        MaterialUse& u = *it->second;
        if (u.error == error && std::memcmp(u.params, key.params, nParams * sizeof(key.params[0])) == 0 &&
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
