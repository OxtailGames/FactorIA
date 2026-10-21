// The logic behind the Hierarchy and Inspector panels, with no ImGui and no window: which widget a reflected field gets, the
// arguments of the command an edit calls, the typing of a material's params, asset file lists, the entity tree's filter and
// the copy a Duplicate spawns. GPU-free, so fa_test_editor covers it (inspector_tests.cpp); the panels (hierarchy_panel.cpp,
// inspector_panel.cpp) only draw and call these.
#pragma once

#include <optional>
#include <string>
#include <string_view>
#include <vector>

#include "fa/core/json.h"
#include "fa/core/reflect.h"

namespace fa::editor {

// ---------------------------------------------------------------------------------------------- field -> widget
enum class FieldWidget { Checkbox, DragInt, DragFloat, Text, Vec2, Vec3, Vec4, Color, Rect, EntityCombo, EnumCombo, AssetPicker, JsonText };

// Runtime-only fields (serialized == false) are not shown: they are the engine's state, not the scene's.
inline bool inspector_shows(const FieldInfo& f) { return f.serialized; }
inline bool field_has_range(const FieldInfo& f) { return f.minValue != f.maxValue; }
FieldWidget widget_for(const FieldInfo& f);
const char* widget_name(FieldWidget w);
// How many numbers a vector-like widget edits (Vec2 2, Vec3 3, Vec4/Color/Rect 4, a scalar 1, the rest 0).
int widget_arity(FieldWidget w);
// The speed of a drag over the field: a ranged field crosses its range in about 200 pixels, an unbounded one moves 1% of its
// current magnitude per pixel (at least 0.01; whole numbers at least 1).
float drag_speed_for(const FieldInfo& f, double current);

// The arguments of `scene.set_component` that set ONE field. `merge` is for materialParams (RFC 7386, see the command).
Json field_edit_args(const std::string& entityId, const std::string& component, const std::string& field, const Json& value,
                     bool merge = false);
// The text of a Json field's box, parsed: the error names the line and column and says how to fix it.
Result<Json> parse_json_box(const std::string& text);
// A short message of a failed command's `error` object ("message" and, when there is one, " " + "hint").
std::string command_error_text(const Json& error);

// ---------------------------------------------------------------------------------------------- asset fields
// Whether a project-relative file is of an asset type of FieldInfo::assetType ("texture", "mesh", "audio", "font", "script",
// "scene", "prefab", "material", "any").
bool asset_file_matches(std::string_view assetType, std::string_view relPath);
// Folders the project listings never enter: hidden ones (.factoria, .git), build, node_modules, dist, export.
bool skip_project_dir(std::string_view name);
// The project's files of that type, sorted, with forward slashes (the build and hidden folders are skipped).
std::vector<std::string> list_asset_files(const std::string& projectDir, std::string_view assetType, std::size_t limit = 2000);

// ---------------------------------------------------------------------------------------------- material params
// One entry of material.info's `params`.
struct MaterialParamSpec {
    std::string name;
    std::string type;  // float, vec2, vec3, vec4, color
    Json defaultValue;
    std::optional<double> min, max;
    std::string doc;
};
// The numbers a param type holds: float 1, vec2 2, vec3 3, vec4 and color 4; 0 for a type the inspector cannot edit.
int material_param_arity(std::string_view type);
// The params of a `material.info` result (an error when the JSON is not that).
Result<std::vector<MaterialParamSpec>> material_params_from_info(const Json& info);
// The value to show: the entity's override in MeshRenderer.materialParams, else the material's default.
Json material_param_value(const MaterialParamSpec& p, const Json& overrides);
bool material_param_overridden(const MaterialParamSpec& p, const Json& overrides);
// scene.set_component arguments that set / reset (null = back to the default) one param, with merge: true.
Json material_param_edit_args(const std::string& entityId, const MaterialParamSpec& p, const Json& value);
Json material_param_reset_args(const std::string& entityId, const MaterialParamSpec& p);
// The build error of `materialPath` in Renderer::asset_report() ("" when it builds or is not loaded yet).
std::string material_build_error(const Json& assetReport, const std::string& materialPath);

// ---------------------------------------------------------------------------------------------- entity tree
// The tree's search box: every word of `filter` must be in the name or the id (case-insensitive). Empty filter matches.
bool tree_matches(std::string_view filter, std::string_view name, std::string_view id);
// "Name  (id)", or just the id when the entity has no name.
std::string tree_label(std::string_view name, std::string_view id);
// The entity JSON a Duplicate spawns: `entityJson` (entity_to_json) without the ids of the entity and its children, so
// the engine gives the copies new ones, and the name followed by " copy".
Json duplicate_spec(Json entityJson);

}  // namespace fa::editor
