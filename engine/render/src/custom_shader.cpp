// Custom materials (MeshRenderer.material): the factoria.shader/1 twin -> sg_shader_desc (docs/design/CUSTOM_SHADERS.md),
// and the packing of a material's params.
#include <cmath>
#include <cstring>

#include "fa/core/fs.h"
#include "fa/core/log.h"
#include "fa/core/strings.h"
#include "render_internal.h"

namespace fa {

std::string mesh_template_hash() { return FA_MESH_TEMPLATE_HASH; }

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

template <class E>
bool pick(const std::string& name, std::initializer_list<std::pair<const char*, E>> table, E& out) {
    for (const auto& [n, v] : table)
        if (name == n) { out = v; return true; }
    return false;
}

sg_shader_stage stage_of(const Json& j) { return text_of(j, "stage") == "vertex" ? SG_SHADERSTAGE_VERTEX : SG_SHADERSTAGE_FRAGMENT; }

}  // namespace

Result<MaterialProgram> make_material_program(const std::string& label, const Json& program) {
    const std::string where = "the program '" + label + "'";
    auto bad = [&](const std::string& what) {
        return make_error(where + " of the shader twin is malformed: " + what,
                          "Re-export the game, or run it with `factoria` so the shaders are compiled again, with the same factoria version.");
    };
    const std::string* vs = str_of(program, "vs");
    const std::string* fsText = str_of(program, "fs");
    auto refl = program.find("reflection");
    if (!vs || !fsText || refl == program.end() || !refl->is_object()) return bad("it needs \"vs\", \"fs\" and \"reflection\"");

    // The strings the desc points to live in `program` (the Json) for the whole call.
    sg_shader_desc desc{};
    desc.label = label.c_str();
    desc.vertex_func.source = vs->c_str();
    desc.fragment_func.source = fsText->c_str();
    for (auto [fn, key] : {std::pair{&desc.vertex_func, "vertex_func"}, std::pair{&desc.fragment_func, "fragment_func"}}) {
        auto f = refl->find(key);
        const Json none = Json::object();
        const Json& fj = f != refl->end() && f->is_object() ? *f : none;
        fn->entry = cstr_or_null(fj, "entry_point");
        if (!fn->entry) fn->entry = "main";
        fn->d3d11_target = cstr_or_null(fj, "d3d11_target");
    }

    MaterialProgram out;
    for (const Json& a : refl->value("attrs", Json::array())) {
        const int slot = int_or(a, "slot", -1);
        if (slot < 0 || slot >= SG_MAX_VERTEX_ATTRIBUTES) return bad("an attribute slot outside 0.." + std::to_string(SG_MAX_VERTEX_ATTRIBUTES - 1));
        sg_shader_vertex_attr& at = desc.attrs[slot];
        const std::string base = text_of(a, "base_type");
        at.base_type = base == "Sint" ? SG_SHADERATTRBASETYPE_SINT : base == "Uint" ? SG_SHADERATTRBASETYPE_UINT : SG_SHADERATTRBASETYPE_FLOAT;
        at.glsl_name = cstr_or_null(a, "glsl_name");
        at.hlsl_sem_name = cstr_or_null(a, "hlsl_sem_name");
        at.hlsl_sem_index = std::uint8_t(int_or(a, "hlsl_sem_index"));
    }
    for (const Json& u : refl->value("uniform_blocks", Json::array())) {
        const int slot = int_or(u, "slot", -1);
        if (slot < 0 || slot >= SG_MAX_UNIFORMBLOCK_BINDSLOTS) return bad("a uniform block slot outside 0.." + std::to_string(SG_MAX_UNIFORMBLOCK_BINDSLOTS - 1));
        sg_shader_uniform_block& ub = desc.uniform_blocks[slot];
        ub.stage = stage_of(u);
        ub.layout = SG_UNIFORMLAYOUT_STD140;
        ub.size = std::uint32_t(int_or(u, "size"));
        ub.hlsl_register_b_n = std::uint8_t(int_or(u, "hlsl_register_b_n"));
        ub.msl_buffer_n = std::uint8_t(int_or(u, "msl_buffer_n"));
        int n = 0;
        for (const Json& g : u.value("glsl_uniforms", Json::array())) {
            if (n >= SG_MAX_UNIFORMBLOCK_MEMBERS) return bad("a uniform block with too many members");
            sg_uniform_type type = SG_UNIFORMTYPE_FLOAT4;
            if (!pick<sg_uniform_type>(text_of(g, "type"),
                                       {{"float", SG_UNIFORMTYPE_FLOAT}, {"vec2", SG_UNIFORMTYPE_FLOAT2}, {"vec3", SG_UNIFORMTYPE_FLOAT3},
                                        {"vec4", SG_UNIFORMTYPE_FLOAT4}, {"int", SG_UNIFORMTYPE_INT}, {"ivec2", SG_UNIFORMTYPE_INT2},
                                        {"ivec3", SG_UNIFORMTYPE_INT3}, {"ivec4", SG_UNIFORMTYPE_INT4}, {"mat4", SG_UNIFORMTYPE_MAT4}},
                                       type))
                return bad("the uniform type '" + text_of(g, "type") + "'");
            desc.uniform_blocks[slot].glsl_uniforms[n++] = {type, std::uint16_t(int_or(g, "array_count")), cstr_or_null(g, "glsl_name")};
        }
        out.ubMask |= 1u << slot;
        out.ubSize[slot] = ub.size;
    }
    for (const Json& v : refl->value("views", Json::array())) {
        auto t = v.find("texture");
        if (t == v.end() || !t->is_object()) return bad("a view that is not a texture (storage buffers and images are not supported)");
        const int slot = int_or(*t, "slot", -1);
        if (slot < 0 || slot >= SG_MAX_VIEW_BINDSLOTS) return bad("a texture slot outside 0.." + std::to_string(SG_MAX_VIEW_BINDSLOTS - 1));
        sg_shader_texture_view& tv = desc.views[slot].texture;
        tv.stage = stage_of(*t);
        tv.multisampled = t->find("multisampled") != t->end() && t->at("multisampled") == true;
        tv.hlsl_register_t_n = std::uint8_t(int_or(*t, "hlsl_register_t_n"));
        tv.msl_texture_n = std::uint8_t(int_or(*t, "msl_texture_n"));
        if (!pick<sg_image_type>(text_of(*t, "type"), {{"2d", SG_IMAGETYPE_2D}, {"cube", SG_IMAGETYPE_CUBE}, {"3d", SG_IMAGETYPE_3D}, {"array", SG_IMAGETYPE_ARRAY}}, tv.image_type))
            return bad("the texture type '" + text_of(*t, "type") + "'");
        if (!pick<sg_image_sample_type>(text_of(*t, "sample_type"),
                                        {{"float", SG_IMAGESAMPLETYPE_FLOAT}, {"depth", SG_IMAGESAMPLETYPE_DEPTH}, {"sint", SG_IMAGESAMPLETYPE_SINT},
                                         {"uint", SG_IMAGESAMPLETYPE_UINT}, {"unfilterable_float", SG_IMAGESAMPLETYPE_UNFILTERABLE_FLOAT}},
                                        tv.sample_type))
            return bad("the texture sample type '" + text_of(*t, "sample_type") + "'");
        if (slot < 32) out.viewMask |= 1u << slot;
    }
    for (const Json& s : refl->value("samplers", Json::array())) {
        const int slot = int_or(s, "slot", -1);
        if (slot < 0 || slot >= SG_MAX_SAMPLER_BINDSLOTS) return bad("a sampler slot outside 0.." + std::to_string(SG_MAX_SAMPLER_BINDSLOTS - 1));
        sg_shader_sampler& sm = desc.samplers[slot];
        sm.stage = stage_of(s);
        sm.hlsl_register_s_n = std::uint8_t(int_or(s, "hlsl_register_s_n"));
        sm.msl_sampler_n = std::uint8_t(int_or(s, "msl_sampler_n"));
        if (!pick<sg_sampler_type>(text_of(s, "sampler_type"),
                                   {{"filtering", SG_SAMPLERTYPE_FILTERING}, {"nonfiltering", SG_SAMPLERTYPE_NONFILTERING}, {"comparison", SG_SAMPLERTYPE_COMPARISON}},
                                   sm.sampler_type))
            return bad("the sampler type '" + text_of(s, "sampler_type") + "'");
        out.samplerMask |= 1u << slot;
    }
    int pairs = 0;
    for (const Json& p : refl->value("texture_sampler_pairs", Json::array())) {
        if (pairs >= SG_MAX_TEXTURE_SAMPLER_PAIRS) return bad("too many texture-sampler pairs");
        desc.texture_sampler_pairs[pairs++] = {stage_of(p), std::uint8_t(int_or(p, "view_slot")), std::uint8_t(int_or(p, "sampler_slot")),
                                               cstr_or_null(p, "glsl_name")};
    }

    out.shader = sg_make_shader(&desc);
    if (sg_query_shader_state(out.shader) != SG_RESOURCESTATE_VALID) {
        sg_destroy_shader(out.shader);
        return make_error("the graphics driver rejected " + where + " (backend " + backend_dialect(sg_query_backend()) + "; the sokol log lines above have the driver message)",
                          "The shaders were compiled for this backend by sokol-shdc and passed `factoria validate`, so this is a driver problem: update the graphics driver, "
                          "and report it with the log lines above.");
    }
    return out;
}

void pack_material_params(MaterialAsset& m, const Json& overrides, float out[kMaxMaterialParams][4]) {
    const int n = std::min<int>(int(m.params.size()), kMaxMaterialParams);
    for (int i = 0; i < n; ++i) {
        std::memset(out[i], 0, sizeof(out[i]));
        const MaterialParamDef& p = m.params[std::size_t(i)];
        std::memcpy(out[i], p.def, sizeof(p.def));
        auto it = overrides.is_object() ? overrides.find(p.name) : overrides.end();
        if (it == overrides.end()) continue;
        bool good = p.components == 1 ? it->is_number() : (it->is_array() && int(it->size()) == p.components);
        if (good && it->is_array())
            for (const Json& c : *it) good = good && c.is_number();
        if (!good) {
            if (m.warned.insert(p.name).second)
                FA_WARN("render", "materialParams.{} of a MeshRenderer using '{}' must be {} (the default is kept)", p.name, m.path,
                        p.components == 1 ? std::string("a number") : "an array of " + std::to_string(p.components) + " numbers, like " + (p.components == 2 ? "[0.5, 1]" : p.components == 3 ? "[1, 0.5, 0]" : "[1, 0.5, 0, 1]"));
            continue;
        }
        if (p.components == 1) out[i][0] = it->get<float>();
        else
            for (int c = 0; c < p.components; ++c) out[i][c] = (*it)[std::size_t(c)].get<float>();
    }
    if (overrides.is_object() && !overrides.empty()) {
        std::vector<std::string> names;
        for (const auto& p : m.params) names.push_back(p.name);
        for (const auto& t : m.textures) names.push_back(t.name);
        for (auto it = overrides.begin(); it != overrides.end(); ++it)
            if (std::find(names.begin(), names.end(), it.key()) == names.end() && m.warned.insert(it.key()).second)
                FA_WARN("render", "materialParams.{} of a MeshRenderer using '{}' is not a param or texture of that material. {}", it.key(), m.path,
                        did_you_mean(it.key(), names));
    }
}

TextureAsset* material_texture(MaterialAsset& m, int i, const Json& overrides, Assets& assets) {
    const MaterialTextureDef& t = m.textures[std::size_t(i)];
    auto it = overrides.is_object() ? overrides.find(t.name) : overrides.end();
    if (it == overrides.end()) return t.defaultTex;
    if (it->is_string()) return assets.texture(it->get<std::string>());
    if (m.warned.insert(t.name).second)
        FA_WARN("render", "materialParams.{} of a MeshRenderer using '{}' must be a texture path like \"assets/wood.png\" (the default texture is kept)", t.name, m.path);
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

const char* kReexportHint = "Export the game again with this factoria version (or run it with `factoria run`, which compiles the shaders itself).";

}  // namespace

Result<void> Assets::build_material_checked(MaterialAsset& m) {
    auto doc = load_json_file(m.path);
    if (!doc.ok()) return make_error("material '" + m.path + "' could not be read: " + doc.error().message, doc.error().hint);
    if (!doc->is_object()) return make_error("material '" + m.path + "' must be a JSON object", "Start from the example in docs/SHADERS.md.");
    if (const std::string* s = str_of(*doc, "shader")) m.snippet = fs::normalize(*s);
    const std::string lighting = str_of(*doc, "lighting") ? text_of(*doc, "lighting") : "pbr";
    const std::string alphaMode = str_of(*doc, "alphaMode") ? text_of(*doc, "alphaMode") : "opaque";
    const bool doubleSided = doc->find("doubleSided") != doc->end() && doc->at("doubleSided") == true;
    if (!m.ok) {  // never built: the error material still needs to be sorted into the right draw list
        m.lighting = lighting;
        m.alphaMode = alphaMode;
        m.doubleSided = doubleSided;
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
            return make_error("material '" + m.path + "' has no compiled shader: '" + file + "' does not exist", kReexportHint);
        auto r = load_json_file(file);
        if (!r.ok()) return make_error("shader '" + file + "' could not be read: " + r.error().message, kReexportHint);
        twin = std::move(*r);
    }
    if (text_of(twin, "format") != "factoria.shader/1")
        return make_error("the shader of material '" + m.path + "' has format '" + text_of(twin, "format") + "', expected 'factoria.shader/1'", kReexportHint);
    if (text_of(twin, "engine") != FA_ENGINE_VERSION || text_of(twin, "template") != mesh_template_hash())
        return make_error("the shader of material '" + m.path + "' was made by factoria " + text_of(twin, "engine") +
                              (text_of(twin, "engine") == FA_ENGINE_VERSION ? " with another mesh template" : ", but this is " + std::string(FA_ENGINE_VERSION)),
                          kReexportHint);
    if (text_of(twin, "slang") != dialect)
        return make_error("the shader of material '" + m.path + "' is for '" + text_of(twin, "slang") + "', this graphics backend needs '" + dialect + "'", kReexportHint);

    // Params and textures, in the order of the twin (the order of the packed block and of the texture bindings).
    auto section = [&](const char* key) {
        auto it = doc->find(key);
        return it != doc->end() && it->is_object() ? &*it : nullptr;
    };
    const Json* paramDefs = section("params");
    const Json* textureDefs = section("textures");
    std::vector<MaterialParamDef> params;
    std::vector<MaterialTextureDef> textures;
    for (const Json& n : twin.value("params", Json::array())) {
        MaterialParamDef d;
        d.name = n.is_string() ? n.get<std::string>() : std::string();
        auto it = paramDefs ? paramDefs->find(d.name) : Json::const_iterator();
        if (paramDefs && it != paramDefs->end() && it->is_object()) {
            const std::string type = text_of(*it, "type");
            d.components = type == "vec2" ? 2 : type == "vec3" ? 3 : (type == "vec4" || type == "color") ? 4 : 1;
            auto def = it->find("default");
            if (def != it->end() && def->is_number()) d.def[0] = def->get<float>();
            else if (def != it->end() && def->is_array())
                for (std::size_t c = 0; c < def->size() && c < 4; ++c)
                    if ((*def)[c].is_number()) d.def[c] = (*def)[c].get<float>();
        } else if (d.name == "alphaCutoff") {
            d.def[0] = 0.5f;
        } else {
            return make_error("the shader of material '" + m.path + "' lists the param '" + d.name + "', which /params of the material does not declare",
                              "The material changed after its shader was made. " + std::string(kReexportHint));
        }
        params.push_back(std::move(d));
    }
    if (params.size() > std::size_t(kMaxMaterialParams))
        return make_error("the shader of material '" + m.path + "' has " + std::to_string(params.size()) + " params, at most " + std::to_string(kMaxMaterialParams), kReexportHint);
    if (twin.value("textures", Json::array()).size() > std::size_t(kMaxMaterialTextures))
        return make_error("the shader of material '" + m.path + "' has more than " + std::to_string(kMaxMaterialTextures) + " textures", kReexportHint);
    for (const Json& n : twin.value("textures", Json::array())) {
        MaterialTextureDef d;
        d.name = n.is_string() ? n.get<std::string>() : std::string();
        auto it = textureDefs ? textureDefs->find(d.name) : Json::const_iterator();
        if (!textureDefs || it == textureDefs->end() || !it->is_object())
            return make_error("the shader of material '" + m.path + "' lists the texture '" + d.name + "', which /textures of the material does not declare",
                              "The material changed after its shader was made. " + std::string(kReexportHint));
        d.sampler = sampler_kind(text_of(*it, "sampler"));
        d.defaultTex = texture(text_of(*it, "default"));
        textures.push_back(std::move(d));
    }

    // The shaders. Nothing of `m` changes unless all of them are made.
    static const char* const names[kProgCount] = {"mesh", "mesh_skin", "shadow", "shadow_skin"};
    MaterialProgram programs[kProgCount];
    auto programsJson = twin.find("programs");
    for (int i = 0; i < kProgCount; ++i) {
        const Json* prog = programsJson != twin.end() && programsJson->is_object() && programsJson->contains(names[i]) ? &programsJson->at(names[i]) : nullptr;
        Result<MaterialProgram> made = prog ? make_material_program(m.path + " " + names[i], *prog)
                                            : make_error("the shader of material '" + m.path + "' has no program '" + names[i] + "'", kReexportHint);
        if (made.ok()) {
            programs[i] = *made;
        } else if (prog || i < kProgShadow) {  // the shadow programs are optional, a broken one is not
            for (MaterialProgram& p : programs)
                if (p.shader.id) gpu_.destroy_shader(p.shader);
            return made.error();
        }
    }
    for (MaterialProgram& old : m.programs)
        if (old.shader.id) gpu_.destroy_shader(old.shader);
    std::copy(std::begin(programs), std::end(programs), std::begin(m.programs));
    m.lighting = lighting;
    m.alphaMode = alphaMode;
    m.doubleSided = doubleSided;
    m.params = std::move(params);
    m.textures = std::move(textures);
    return {};
}

void Assets::build_material(MaterialAsset& m) {
    auto r = build_material_checked(m);
    failures_.erase(std::remove_if(failures_.begin(), failures_.end(), [&](const Failure& f) { return f.kind == "material" && f.path == m.path; }),
                    failures_.end());
    if (r.ok()) {
        m.ok = true;
        m.error.clear();
        ++m.generation;
        return;
    }
    m.error = r.error().message;
    note_failure("material", m.path, r.error().message + (m.ok ? " The previous version of the material stays in use." : " The meshes using it are drawn magenta."), r.error().hint);
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
