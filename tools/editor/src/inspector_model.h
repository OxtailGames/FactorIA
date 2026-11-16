// The logic behind the Hierarchy and Inspector panels, with no ImGui and no window: which widget a reflected field gets, the
// arguments of the command an edit calls, the typing of a material's params, asset file lists, the entity tree's filter and
// the copy a Duplicate spawns. GPU-free, so fa_test_editor covers it (inspector_tests.cpp); the panels (hierarchy_panel.cpp,
// inspector_panel.cpp) only draw and call these.
#pragma once

#include <optional>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

#include "fa/core/json.h"
#include "fa/core/reflect.h"

namespace fa::editor {

// ---------------------------------------------------------------------------------------------- field -> widget
enum class FieldWidget {
    Checkbox,
    DragInt,
    DragFloat,
    Text,
    Vec2,
    Vec3,
    Vec4,
    Color,
    Rect,
    EntityCombo,
    EnumCombo,
    AssetPicker,
    JsonText
};

// Runtime-only fields (serialized == false) are not shown: they are the engine's state, not the scene's.
inline bool inspector_shows(const FieldInfo& f) { return f.serialized; }
inline bool field_has_range(const FieldInfo& f) { return f.minValue != f.maxValue; }
// The array kinds (ArrayI32, ArrayF32, ArrayU8) show as a JSON box holding the array on one line, up to this many
// elements; a longer array shows its length only (the box is rebuilt from the JSON every frame).
inline constexpr std::size_t kInspectorArrayEditMax = 512;
inline bool is_array_kind(FieldKind k) {
    return k == FieldKind::ArrayI32 || k == FieldKind::ArrayF32 || k == FieldKind::ArrayU8;
}
// The element count of an array the Inspector does not show: the panel builds its component JSON with
// component_to_json(..., kInspectorArrayEditMax), which writes a longer array as {"$elements": n}; a plain JSON array
// longer than kInspectorArrayEditMax (a field value from elsewhere) counts too. nullopt for a value that is shown.
inline std::optional<std::size_t> inspector_array_length(const Json& v) {
    if (v.is_object() && v.size() == 1 && v.contains("$elements") && v["$elements"].is_number_unsigned())
        return v["$elements"].get<std::size_t>();
    if (v.is_array() && v.size() > kInspectorArrayEditMax) return v.size();
    return std::nullopt;
}
FieldWidget widget_for(const FieldInfo& f);
const char* widget_name(FieldWidget w);
// How many numbers a vector-like widget edits (Vec2 2, Vec3 3, Vec4/Color/Rect 4, a scalar 1, the rest 0).
int widget_arity(FieldWidget w);
// The speed of a drag over the field: a ranged field crosses its range in about 200 pixels, an unbounded one moves 1% of its
// current magnitude per pixel (at least 0.01; whole numbers at least 1).
float drag_speed_for(const FieldInfo& f, double current);

// The arguments of `scene.set_component` that set ONE field. `merge` is for materialParams (RFC 7386, see the command).
Json field_edit_args(const std::string& entityId, const std::string& component, const std::string& field,
                     const Json& value, bool merge = false);
// The text of a Json field's box, parsed: the error names the line and column and says how to fix it.
Result<Json> parse_json_box(const std::string& text);
// A short message of a failed command's `error` object ("message" and, when there is one, " " + "hint").
std::string command_error_text(const Json& error);

// ---------------------------------------------------------------------------------------------- several entities
// The Inspector with several entities selected (docs/EDITOR.md, "Selecting things"). `perEntity[i]` is the component names of
// the i-th selected entity; entity 0 is the primary.
struct SharedComponents {
    std::vector<std::string> shared;                   // on every entity, in the primary's order
    std::vector<std::pair<std::string, int>> partial;  // on some but not all: the name and how many entities have it
};
SharedComponents shared_components(const std::vector<std::vector<std::string>>& perEntity);
// How one field reads across the selected entities: `values[0]` is the primary's. A number array (a vector, a colour) is
// compared per number, so `parts[i]` says whether number i differs; `mixed` is true when anything differs.
struct FieldMix {
    bool mixed = false;
    std::vector<bool> parts;  // only for number arrays: one per number of the primary's value
};
FieldMix field_mix(const std::vector<Json>& values);
// What to write to one entity when the user edited a field that showed `shown` (the primary's value) and now holds `edited`.
// A number array is merged per number: only the numbers the user changed (edited[i] != shown[i]) replace the entity's own, so
// editing x of a position leaves the y and z that differ between the entities alone. Anything else is `edited` as it is.
Json multi_edit_value(const Json& entityCurrent, const Json& shown, const Json& edited);
// "3 entities".
std::string multi_selection_title(size_t count);

// ---------------------------------------------------------------------------------------------- asset fields
// Whether a project-relative file is of an asset type of FieldInfo::assetType ("texture", "mesh", "audio", "font", "script",
// "scene", "prefab", "material", "vfx", "any").
bool asset_file_matches(std::string_view assetType, std::string_view relPath);
// Folders the project listings never enter: hidden ones (.factoria, .git), build, node_modules, dist, export.
bool skip_project_dir(std::string_view name);
// The project's files of that type, sorted, with forward slashes (the build and hidden folders are skipped).
std::vector<std::string> list_asset_files(const std::string& projectDir, std::string_view assetType,
                                          std::size_t limit = 2000);

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

// ---------------------------------------------------------------------------------------------- prefab overrides
// Questions about the `overrides` array of a `prefab.overrides` result (what the Inspector marks). The where-it-stands entry
// of the instance root (`placement`) is not an override: it is never marked.
// The entry of a field of `component` on `entity` that differs from the prefab (a pointer "/name" or deeper, e.g.
// "/position/0", counts for the field "position"), or null.
const Json* prefab_field_override(const Json& overrides, std::string_view entity, std::string_view component,
                                  std::string_view field);
// True when `component` of `entity` is one the prefab does not have.
bool prefab_component_added(const Json& overrides, std::string_view entity, std::string_view component);
// How many entries concern `component` of `entity` (the added component itself or its fields).
int prefab_component_override_count(const Json& overrides, std::string_view entity, std::string_view component);
// How many entries are real overrides: the placement entry is left out.
int prefab_override_count(const Json& overrides);
// The arguments of prefab.revert / prefab.apply; `component` and `field` ("name" or "/name") may be empty.
Json prefab_edit_args(const std::string& entityId, const std::string& component, const std::string& field);

}  // namespace fa::editor
