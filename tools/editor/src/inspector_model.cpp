#include "inspector_model.h"

#include <algorithm>
#include <cmath>
#include <filesystem>
#include <set>

#include "fa/core/fs.h"
#include "fa/core/strings.h"
#include "fa/runtime/project.h"

namespace fa::editor {

namespace stdfs = std::filesystem;

// ---------------------------------------------------------------------------------------------- field -> widget
FieldWidget widget_for(const FieldInfo& f) {
    switch (f.kind) {
        case FieldKind::Bool: return FieldWidget::Checkbox;
        case FieldKind::Int: return FieldWidget::DragInt;
        case FieldKind::Float: return FieldWidget::DragFloat;
        case FieldKind::String: return FieldWidget::Text;
        case FieldKind::Vec2: return FieldWidget::Vec2;
        case FieldKind::Vec3: return FieldWidget::Vec3;
        case FieldKind::Vec4: return FieldWidget::Vec4;
        case FieldKind::Color: return FieldWidget::Color;
        case FieldKind::Rect: return FieldWidget::Rect;
        case FieldKind::Entity: return FieldWidget::EntityCombo;
        case FieldKind::Enum: return FieldWidget::EnumCombo;
        case FieldKind::Asset: return FieldWidget::AssetPicker;
        case FieldKind::Json:
        case FieldKind::ArrayI32:
        case FieldKind::ArrayF32:
        case FieldKind::ArrayU8: return FieldWidget::JsonText;
    }
    return FieldWidget::JsonText;
}

const char* widget_name(FieldWidget w) {
    switch (w) {
        case FieldWidget::Checkbox: return "checkbox";
        case FieldWidget::DragInt: return "drag_int";
        case FieldWidget::DragFloat: return "drag_float";
        case FieldWidget::Text: return "text";
        case FieldWidget::Vec2: return "vec2";
        case FieldWidget::Vec3: return "vec3";
        case FieldWidget::Vec4: return "vec4";
        case FieldWidget::Color: return "color";
        case FieldWidget::Rect: return "rect";
        case FieldWidget::EntityCombo: return "entity_combo";
        case FieldWidget::EnumCombo: return "enum_combo";
        case FieldWidget::AssetPicker: return "asset_picker";
        case FieldWidget::JsonText: return "json_text";
    }
    return "?";
}

int widget_arity(FieldWidget w) {
    switch (w) {
        case FieldWidget::DragInt:
        case FieldWidget::DragFloat: return 1;
        case FieldWidget::Vec2: return 2;
        case FieldWidget::Vec3: return 3;
        case FieldWidget::Vec4:
        case FieldWidget::Color:
        case FieldWidget::Rect: return 4;
        default: return 0;
    }
}

float drag_speed_for(const FieldInfo& f, double current) {
    const bool whole = f.kind == FieldKind::Int;
    if (field_has_range(f)) {
        const float s = (f.maxValue - f.minValue) / 200.0f;
        return whole ? std::max(1.0f, s) : std::max(s, 1e-4f);
    }
    const float s = float(std::fabs(current)) * 0.01f;
    return whole ? std::max(1.0f, s) : std::max(0.01f, s);
}

Json field_edit_args(const std::string& entityId, const std::string& component, const std::string& field,
                     const Json& value, bool merge) {
    Json a = Json::object({{"id", entityId}, {"component", component}, {"fields", Json::object({{field, value}})}});
    if (merge) a["merge"] = true;
    return a;
}

SharedComponents shared_components(const std::vector<std::vector<std::string>>& perEntity) {
    SharedComponents out;
    if (perEntity.empty()) return out;
    // First-seen order: the primary's components, then the ones only others have.
    std::vector<std::string> names;
    for (const auto& list : perEntity)
        for (const std::string& n : list)
            if (std::find(names.begin(), names.end(), n) == names.end()) names.push_back(n);
    for (const std::string& n : names) {
        int have = 0;
        for (const auto& list : perEntity) have += std::find(list.begin(), list.end(), n) != list.end() ? 1 : 0;
        if (have == int(perEntity.size()))
            out.shared.push_back(n);
        else
            out.partial.emplace_back(n, have);
    }
    return out;
}

FieldMix field_mix(const std::vector<Json>& values) {
    FieldMix m;
    if (values.size() < 2) return m;
    const Json& first = values[0];
    const bool numbers =
        first.is_array() && std::all_of(first.begin(), first.end(), [](const Json& v) { return v.is_number(); });
    if (numbers) m.parts.assign(first.size(), false);
    for (size_t i = 1; i < values.size(); ++i) {
        const Json& v = values[i];
        if (v == first) continue;
        m.mixed = true;
        if (!numbers) continue;
        if (!v.is_array() || v.size() != first.size()) {
            m.parts.assign(first.size(), true);  // not comparable number by number: every number is mixed
            continue;
        }
        for (size_t k = 0; k < first.size(); ++k)
            if (v[k] != first[k]) m.parts[k] = true;
    }
    return m;
}

Json multi_edit_value(const Json& entityCurrent, const Json& shown, const Json& edited) {
    const bool arrays = edited.is_array() && shown.is_array() && entityCurrent.is_array() &&
                        edited.size() == shown.size() && entityCurrent.size() == shown.size();
    if (!arrays) return edited;
    Json out = entityCurrent;
    for (size_t i = 0; i < edited.size(); ++i)
        if (edited[i] != shown[i]) out[i] = edited[i];
    return out;
}

std::string multi_selection_title(size_t count) { return std::to_string(count) + " entities"; }

Result<Json> parse_json_box(const std::string& text) {
    std::string trimmed = text;
    while (!trimmed.empty() && std::isspace(static_cast<unsigned char>(trimmed.back()))) trimmed.pop_back();
    if (trimmed.empty())
        return make_error("The box is empty.", "Write a JSON value, e.g. {} for an empty object, or null.");
    auto r = parse_json(trimmed, "this field");
    if (!r.ok())
        return make_error(r.error().message, r.error().hint.empty()
                                                 ? "Fix the JSON (quotes around keys and strings, commas between "
                                                   "items); nothing is applied until it parses."
                                                 : r.error().hint);
    return r;
}

std::string command_error_text(const Json& error) {
    if (!error.is_object()) return error.dump();
    std::string text = error.value("message", std::string());
    const std::string hint = error.value("hint", std::string());
    if (!hint.empty()) text += " " + hint;
    return text.empty() ? error.dump() : text;
}

// ---------------------------------------------------------------------------------------------- asset fields
bool asset_file_matches(std::string_view assetType, std::string_view relPath) {
    if (assetType == "any") return true;
    const std::string type = asset_type_of(relPath);
    if (type != "other") return type == assetType;
    return assetType != "texture" && assetType != "audio" && assetType != "font" && assetType != "mesh" &&
           assetType != "script" && assetType != "scene" && assetType != "prefab" && assetType != "material" &&
           assetType != "video" && assetType != "vfx";  // unknown type: anything
}

bool skip_project_dir(std::string_view name) {
    return (!name.empty() && name[0] == '.') || name == "build" || name == "node_modules" || name == "dist" ||
           name == "export";
}

std::vector<std::string> list_asset_files(const std::string& projectDir, std::string_view assetType,
                                          std::size_t limit) {
    std::vector<std::string> out;
    if (projectDir.empty()) return out;
    std::error_code ec;
    const stdfs::path root = stdfs::path(projectDir);
    stdfs::recursive_directory_iterator it(root, stdfs::directory_options::skip_permission_denied, ec), end;
    for (; !ec && it != end; it.increment(ec)) {
        const std::string name = it->path().filename().string();
        if (it->is_directory(ec)) {
            if (skip_project_dir(name)) it.disable_recursion_pending();
            continue;
        }
        if (!it->is_regular_file(ec)) continue;
        const std::string rel = stdfs::relative(it->path(), root, ec).generic_string();
        if (ec) {
            ec.clear();
            continue;
        }
        if (rel.empty() || !asset_file_matches(assetType, rel)) continue;
        out.push_back(rel);
        if (out.size() >= limit) break;
    }
    std::sort(out.begin(), out.end());
    return out;
}

// ---------------------------------------------------------------------------------------------- material params
int material_param_arity(std::string_view type) {
    if (type == "float") return 1;
    if (type == "vec2") return 2;
    if (type == "vec3") return 3;
    if (type == "vec4" || type == "color") return 4;
    return 0;
}

Result<std::vector<MaterialParamSpec>> material_params_from_info(const Json& info) {
    if (!info.is_object() || !info.contains("params") || !info["params"].is_array())
        return make_error("material.info did not return a params list.",
                          "Run material.info on the material and fix its errors first.");
    std::vector<MaterialParamSpec> out;
    for (const Json& p : info["params"]) {
        if (!p.is_object() || !p.contains("name") || !p["name"].is_string()) continue;
        MaterialParamSpec s;
        s.name = p["name"].get<std::string>();
        s.type = p.value("type", std::string("float"));
        s.defaultValue = p.contains("default") ? p["default"] : Json(nullptr);
        if (p.contains("min") && p["min"].is_number()) s.min = p["min"].get<double>();
        if (p.contains("max") && p["max"].is_number()) s.max = p["max"].get<double>();
        s.doc = p.value("doc", std::string());
        out.push_back(std::move(s));
    }
    return out;
}

Json material_param_value(const MaterialParamSpec& p, const Json& overrides) {
    if (overrides.is_object() && overrides.contains(p.name) && !overrides[p.name].is_null()) return overrides[p.name];
    return p.defaultValue;
}

bool material_param_overridden(const MaterialParamSpec& p, const Json& overrides) {
    return overrides.is_object() && overrides.contains(p.name) && !overrides[p.name].is_null();
}

Json material_param_edit_args(const std::string& entityId, const MaterialParamSpec& p, const Json& value) {
    return field_edit_args(entityId, "MeshRenderer", "materialParams", Json::object({{p.name, value}}), true);
}

Json material_param_reset_args(const std::string& entityId, const MaterialParamSpec& p) {
    return material_param_edit_args(entityId, p, Json(nullptr));
}

std::string material_build_error(const Json& assetReport, const std::string& materialPath) {
    if (materialPath.empty() || !assetReport.is_object() || !assetReport.contains("materials") ||
        !assetReport["materials"].is_array())
        return {};
    std::string key = fs::normalize(materialPath);
    if (key.empty()) key = materialPath;
    for (const Json& m : assetReport["materials"])
        if (m.is_object() && m.value("material", std::string()) == key) return m.value("error", std::string());
    return {};
}

// ---------------------------------------------------------------------------------------------- entity tree
bool tree_matches(std::string_view filter, std::string_view name, std::string_view id) {
    const std::string hay = to_lower(name) + "\n" + to_lower(id);
    for (const std::string& word : split(to_lower(filter), ' '))
        if (hay.find(word) == std::string::npos) return false;
    return true;
}

std::string tree_label(std::string_view name, std::string_view id) {
    if (name.empty() || name == id) return std::string(id);
    return std::string(name) + "  (" + std::string(id) + ")";
}

static void strip_ids(Json& entity) {
    if (!entity.is_object()) return;
    entity.erase("id");
    if (entity.contains("children") && entity["children"].is_array())
        for (Json& c : entity["children"]) strip_ids(c);
}

Json duplicate_spec(Json entityJson) {
    const std::string name = entityJson.value("name", std::string());
    strip_ids(entityJson);
    entityJson["name"] = (name.empty() ? std::string("Entity") : name) + " copy";
    return entityJson;
}

// ---------------------------------------------------------------------------------------------- prefab overrides
namespace {
std::string json_text(const Json& j, const char* key) {
    return j.is_object() && j.contains(key) && j[key].is_string() ? j[key].get<std::string>() : std::string();
}
bool is_real(const Json& item) { return !(item.is_object() && item.value("placement", false)); }
}  // namespace

const Json* prefab_field_override(const Json& overrides, std::string_view entity, std::string_view component,
                                  std::string_view field) {
    if (!overrides.is_array()) return nullptr;
    const std::string whole = "/" + std::string(field);
    for (const Json& item : overrides) {
        if (!is_real(item) || json_text(item, "kind") != "field" || json_text(item, "entity") != entity ||
            json_text(item, "component") != component)
            continue;
        const std::string pointer = json_text(item, "field");
        if (pointer == whole || pointer.compare(0, whole.size() + 1, whole + "/") == 0) return &item;
    }
    return nullptr;
}

bool prefab_component_added(const Json& overrides, std::string_view entity, std::string_view component) {
    if (!overrides.is_array()) return false;
    for (const Json& item : overrides)
        if (json_text(item, "kind") == "component" && json_text(item, "entity") == entity &&
            json_text(item, "component") == component)
            return true;
    return false;
}

std::vector<std::string> prefab_removed_components(const Json& overrides, std::string_view entity) {
    std::vector<std::string> names;
    if (!overrides.is_array()) return names;
    for (const Json& item : overrides)
        if (json_text(item, "kind") == "removedComponent" && json_text(item, "entity") == entity)
            names.push_back(json_text(item, "component"));
    return names;
}

int prefab_component_override_count(const Json& overrides, std::string_view entity, std::string_view component) {
    int n = 0;
    if (!overrides.is_array()) return 0;
    for (const Json& item : overrides)
        if (is_real(item) && json_text(item, "kind") != "child" && json_text(item, "entity") == entity &&
            json_text(item, "component") == component)
            ++n;
    return n;
}

int prefab_override_count(const Json& overrides) {
    int n = 0;
    if (!overrides.is_array()) return 0;
    for (const Json& item : overrides) n += is_real(item) ? 1 : 0;
    return n;
}

Json prefab_edit_args(const std::string& entityId, const std::string& component, const std::string& field) {
    Json a = Json::object({{"id", entityId}});
    if (!component.empty()) a["component"] = component;
    if (!field.empty()) a["field"] = field[0] == '/' ? field : "/" + field;
    return a;
}

}  // namespace fa::editor
