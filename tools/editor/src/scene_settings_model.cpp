#include "scene_settings_model.h"

#include <algorithm>
#include <cstddef>

namespace fa::editor {

namespace {

struct GroupSpec {
    const char* title;
    const char* hint;
    std::vector<const char*> fields;
};

// The order of the panel: what a 3D scene is most often tuned by first. A field is in one group only.
const std::vector<GroupSpec>& group_specs() {
    static const std::vector<GroupSpec> specs = {
        {"Sky",
         "What a 3D camera paints behind the scene: a two-colour gradient, or a sky material (a *.material.json of "
         "kind "
         "\"sky\") with its own params. Reflections and the ambient light always follow the two colours.",
         {"skyColor", "horizonColor", "skyMaterial", "skyMaterialParams"}},
        {"Fog", "Distance fog: its colour and how fast it thickens (0 = no fog).", {"fogColor", "fogDensity"}},
        {"Lighting",
         "The light every lit visual gets before any light entity adds to it.",
         {"ambientLight", "lightScale"}},
        {"Physics", "Gravity of the 2D and the 3D simulation.", {"gravity2D", "gravity3D"}},
        {"Music", "The looped background music of the scene.", {"music", "musicVolume"}},
        {"Output",
         "How colour is computed and shown: gamma or linear lighting, and the HDR display.",
         {"colorSpace", "hdrOutput", "paperWhiteNits"}},
    };
    return specs;
}

}  // namespace

std::vector<SettingsGroup> settings_groups(const TypeInfo& type) {
    std::vector<SettingsGroup> out;
    std::vector<const FieldInfo*> placed;
    for (const GroupSpec& spec : group_specs()) {
        SettingsGroup g;
        g.title = spec.title;
        g.hint = spec.hint;
        for (const FieldInfo& f : type.fields) {
            if (!f.serialized) continue;
            const bool named = std::find_if(spec.fields.begin(), spec.fields.end(),
                                            [&](const char* name) { return f.name == name; }) != spec.fields.end();
            if (!named) continue;
            g.fields.push_back(&f);
            placed.push_back(&f);
        }
        if (!g.fields.empty()) out.push_back(std::move(g));
    }
    SettingsGroup other;
    other.title = "Other";
    other.hint = "Settings no other group names.";
    for (const FieldInfo& f : type.fields)
        if (f.serialized && std::find(placed.begin(), placed.end(), &f) == placed.end()) other.fields.push_back(&f);
    if (!other.fields.empty()) out.push_back(std::move(other));
    return out;
}

Json settings_values(const TypeInfo& type, const void* settings) {
    Json out = Json::object();
    for (const FieldInfo& f : type.fields)
        if (f.serialized) out[f.name] = field_to_json(f, settings);
    return out;
}

Json settings_defaults(const TypeInfo& type) {
    DefaultObject defaults(type);
    return settings_values(type, defaults.get());
}

Json settings_edit_args(const std::string& field, const Json& value, bool merge) {
    Json a = Json::object({{"component", "SceneSettings"}, {"fields", Json::object({{field, value}})}});
    if (merge) a["merge"] = true;
    return a;
}

Json settings_reset_args(const std::string& field) { return settings_edit_args(field, Json(nullptr), true); }

SkyMaterialNote sky_material_note(const std::string& path, const Json& materialInfo, const std::string& infoError,
                                  const std::string& buildError) {
    using Level = SkyMaterialNote::Level;
    SkyMaterialNote n;
    if (path.empty()) return n;
    if (!infoError.empty()) {
        n.level = Level::Error;
        n.text = "Cannot read the material: " + infoError + " The built-in sky is drawn instead.";
        return n;
    }
    const std::string kind = materialInfo.is_object() ? materialInfo.value("kind", std::string()) : std::string();
    if (!kind.empty() && kind != "sky") {
        n.level = Level::Warning;
        n.text = "This is a \"" + kind +
                 "\" material, not a \"sky\" one, so the built-in sky is drawn. Pick a material with \"kind\": \"sky\" "
                 "(factoria call material.info shows it).";
        return n;
    }
    if (!buildError.empty()) {
        n.level = Level::Error;
        n.text = "The material did not build, so the built-in sky is drawn: " + buildError;
        return n;
    }
    if (kind == "sky") {
        n.level = Level::Info;
        n.text = "A sky material: it is drawn instead of the gradient. Reflections and the ambient light still follow "
                 "skyColor and horizonColor.";
    }
    return n;
}

}  // namespace fa::editor
