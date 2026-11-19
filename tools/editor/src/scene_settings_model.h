// The rules of the Scene settings panel (View > Scene settings): which SceneSettings fields it shows and in which groups, the
// scene.set_component arguments of an edit, and what it says about the sky material. No ImGui here, so the tests of the editor
// (tools/editor/tests/scene_settings_tests.cpp) run these without a window; the panel (scene_settings_panel.cpp) only draws them.
#pragma once

#include <string>
#include <vector>

#include "fa/core/json.h"
#include "fa/core/reflect.h"

namespace fa::editor {

// A titled group of SceneSettings fields, in the order the panel draws them.
struct SettingsGroup {
    std::string title;
    std::string hint;                      // what the group is for, the tooltip of its header
    std::vector<const FieldInfo*> fields;  // reflection order inside the group
};

// The fields of `type` (SceneSettings) the panel shows, put in groups: Sky, Fog, Lighting, Physics, Music, Output. A field no
// group names goes to a last group "Other", so a field added to SceneSettings later is never hidden from the panel. Fields
// that are not serialized (runtime state) are left out, like the Inspector. A group with no field is not returned.
std::vector<SettingsGroup> settings_groups(const TypeInfo& type);

// The values the panel shows: every serialized field of the settings object `settings`, as JSON.
Json settings_values(const TypeInfo& type, const void* settings);
// ...and the same for a default-constructed SceneSettings (what Reset goes back to).
Json settings_defaults(const TypeInfo& type);

// scene.set_component arguments that set ONE SceneSettings field. The settings belong to the scene, so there is no `id`.
// `merge` is for skyMaterialParams (RFC 7386, see the command).
Json settings_edit_args(const std::string& field, const Json& value, bool merge = false);
// ...and that put one field back to its default (a null with merge, which is how the command reads a reset).
Json settings_reset_args(const std::string& field);

// What the panel says under the skyMaterial field. `materialInfo` is the answer of material.info for that path ("" when it
// could not be read: `infoError` says why), `buildError` what the renderer reported for the material's build ("" = none).
struct SkyMaterialNote {
    enum class Level { None, Info, Warning, Error } level = Level::None;
    std::string text;
};
SkyMaterialNote sky_material_note(const std::string& path, const Json& materialInfo, const std::string& infoError,
                                  const std::string& buildError);

}  // namespace fa::editor
