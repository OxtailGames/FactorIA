#include "fa/runtime/postprocess_presets.h"

#include "embedded_runtime_data.h"
#include "fa/core/log.h"
#include "fa/core/reflect.h"
#include "fa/scene/components.h"
#include "fa/scene/postprocess.h"

namespace fa {

namespace {

std::vector<PostPreset> load_presets() {
    std::vector<PostPreset> out;
    for (const auto& file : fa_runtime_data::files()) {
        if (file.path != "postprocess_presets.json") continue;
        auto parsed = parse_json(file.data, "postprocess_presets.json");
        FA_ASSERT(parsed.ok(), "engine/runtime/data/postprocess_presets.json is not valid JSON");
        const Json& root = parsed.value();
        FA_ASSERT(root.is_object() && root.contains("presets") && root["presets"].is_array(),
                  "postprocess_presets.json needs a \"presets\" array");
        for (const Json& p : root["presets"]) {
            PostPreset preset;
            preset.name = p.value("name", std::string());
            preset.doc = p.value("doc", std::string());
            preset.fields = p.contains("fields") && p["fields"].is_object() ? p["fields"] : Json::object();
            FA_ASSERT(!preset.name.empty(), "a post-processing preset has no name");
            out.push_back(std::move(preset));
        }
    }
    return out;
}

}  // namespace

const std::vector<PostPreset>& postprocess_presets() {
    static const std::vector<PostPreset> presets = load_presets();
    return presets;
}

const PostPreset* find_postprocess_preset(std::string_view name) {
    for (const PostPreset& p : postprocess_presets())
        if (p.name == name) return &p;
    return nullptr;
}

Json postprocess_preset_fields(const PostPreset& preset, bool keep) {
    ensure_builtin_components();
    const TypeInfo* type = TypeRegistry::global().of<PostProcess>();
    FA_ASSERT(type, "PostProcess is not registered");
    Json fields = Json::object();
    if (!keep) {
        DefaultObject defaults(*type);
        for (const FieldInfo& f : type->fields)
            if (post_field_effect(f.name) >= 0 && !f.readOnly && f.kind != FieldKind::Entity)
                fields[f.name] = field_to_json(f, defaults.get());
    }
    for (auto it = preset.fields.begin(); it != preset.fields.end(); ++it) fields[it.key()] = *it;
    return fields;
}

}  // namespace fa
