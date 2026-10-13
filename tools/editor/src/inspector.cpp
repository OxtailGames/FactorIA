// Inspector panel: reflection-driven component editing (TypeRegistry FieldInfo -> ImGui widgets).
// Every edit goes through fa::patch_component (or field_from_json for SceneSettings), records an
// undo snapshot (coalesced per field) and marks the scene dirty.
#include <algorithm>
#include <cfloat>
#include <cmath>

#include "editor_internal.h"

namespace fa::editor {

const std::vector<std::string>& Editor::project_files() {
    if (time_ - filesScanned_ > 2.0 || projectFiles_.empty()) {
        filesScanned_ = time_;
        projectFiles_.clear();
        for (auto& f : fs::list("", true)) {
            if (f.empty() || f[0] == '.' || f.find("/.") != std::string::npos) continue;
            projectFiles_.push_back(f);
        }
    }
    return projectFiles_;
}

static bool ends_with(const std::string& s, const char* suffix) {
    const size_t n = std::strlen(suffix);
    return s.size() >= n && lower_str(s.substr(s.size() - n)) == suffix;
}

bool asset_matches(const std::string& type, const std::string& path) {
    if (type == "texture") return ends_with(path, ".png") || ends_with(path, ".jpg") || ends_with(path, ".jpeg") || ends_with(path, ".bmp") || ends_with(path, ".tga");
    if (type == "mesh") return ends_with(path, ".gltf") || ends_with(path, ".glb");
    if (type == "audio") return ends_with(path, ".wav") || ends_with(path, ".ogg") || ends_with(path, ".mp3");
    if (type == "font") return ends_with(path, ".ttf") || ends_with(path, ".otf");
    if (type == "script") return ends_with(path, ".js") || ends_with(path, ".mjs");
    if (type == "scene") return ends_with(path, ".scene.json");
    if (type == "prefab") return ends_with(path, ".prefab.json");
    return true;
}

namespace {
std::string tooltip_text(const FieldInfo& f) {
    std::string t = f.doc;
    t += "\n\ntype: ";
    t += field_kind_name(f.kind);
    if (f.kind == FieldKind::Asset) t += " (" + f.assetType + ")";
    if (f.minValue != f.maxValue) t += "   range: " + std::to_string(f.minValue).substr(0, std::to_string(f.minValue).find('.') + 3) + " .. " + std::to_string(f.maxValue).substr(0, std::to_string(f.maxValue).find('.') + 3);
    if (f.readOnly) t += "   (read-only)";
    if (!f.serialized) t += "   (runtime state, not saved)";
    return t;
}

void doc_tooltip(const std::string& text) {
    if (text.empty() || !ImGui::IsItemHovered(ImGuiHoveredFlags_DelayShort)) return;
    ImGui::BeginTooltip();
    ImGui::PushTextWrapPos(ImGui::GetFontSize() * 28.0f);
    ImGui::TextUnformatted(text.c_str());
    ImGui::PopTextWrapPos();
    ImGui::EndTooltip();
}
}  // namespace

bool Editor::draw_field(Entity e, const TypeInfo& t, const FieldInfo& f, void* comp) {
    void* p = f.ptr(comp);
    const std::string eid = e.is_null() ? std::string("scene") : world().id_of(e);
    const std::string key = eid + "/" + t.name + "/" + f.name;
    bool changed = false;
    auto commit = [&](const Json& v) {
        changed = true;
        if (e.is_null()) {
            begin_edit(key);
            if (auto r = field_from_json(f, comp, v); !r) notify(r.error().to_string(), 2);
        } else {
            apply_field(e, t, f.name, v, key);
        }
    };
    const bool bounded = f.minValue != f.maxValue;
    ImGui::SetNextItemWidth(-FLT_MIN);
    switch (f.kind) {
        case FieldKind::Bool: {
            bool v = *static_cast<bool*>(p);
            if (ImGui::Checkbox("##v", &v)) commit(v);
            break;
        }
        case FieldKind::Int: {
            int v = *static_cast<std::int32_t*>(p);
            bool ok = bounded ? ImGui::DragInt("##v", &v, 1.0f, int(f.minValue), int(f.maxValue)) : ImGui::DragInt("##v", &v, 1.0f);
            if (ok) commit(v);
            break;
        }
        case FieldKind::Float: {
            float v = *static_cast<float*>(p);
            const float speed = bounded ? std::max(0.0005f, (f.maxValue - f.minValue) / 250.0f) : std::max(0.01f, std::fabs(v) * 0.01f);
            bool ok = bounded ? ImGui::DragFloat("##v", &v, speed, f.minValue, f.maxValue, "%.3f") : ImGui::DragFloat("##v", &v, speed, 0, 0, "%.3f");
            if (ok) commit(to_json(v));
            break;
        }
        case FieldKind::String: {
            std::string tmp = *static_cast<std::string*>(p);
            bool enter = ImGui::InputText("##v", &tmp, ImGuiInputTextFlags_EnterReturnsTrue);
            if (enter || ImGui::IsItemDeactivatedAfterEdit()) {
                if (tmp != *static_cast<std::string*>(p)) commit(tmp);
            }
            break;
        }
        case FieldKind::Vec2: {
            Vec2 v = *static_cast<Vec2*>(p);
            if (ImGui::DragFloat2("##v", &v.x, bounded ? (f.maxValue - f.minValue) / 250.0f : 0.1f, f.minValue, f.maxValue, "%.2f")) commit(to_json(v));
            break;
        }
        case FieldKind::Vec3: {
            Vec3 v = *static_cast<Vec3*>(p);
            if (ImGui::DragFloat3("##v", &v.x, bounded ? (f.maxValue - f.minValue) / 250.0f : 0.1f, f.minValue, f.maxValue, "%.2f")) commit(to_json(v));
            break;
        }
        case FieldKind::Vec4: {
            Vec4 v = *static_cast<Vec4*>(p);
            if (ImGui::DragFloat4("##v", &v.x, bounded ? (f.maxValue - f.minValue) / 250.0f : 0.1f, f.minValue, f.maxValue, "%.2f")) commit(to_json(v));
            break;
        }
        case FieldKind::Rect: {
            Rect v = *static_cast<Rect*>(p);
            if (ImGui::DragFloat4("##v", &v.x, 0.5f, 0, 0, "%.1f")) commit(to_json(v));
            break;
        }
        case FieldKind::Color: {
            Color v = *static_cast<Color*>(p);
            if (ImGui::ColorEdit4("##v", &v.r, ImGuiColorEditFlags_Float | ImGuiColorEditFlags_AlphaPreviewHalf | ImGuiColorEditFlags_AlphaBar)) commit(to_json(v));
            break;
        }
        case FieldKind::Enum: {
            int v = *static_cast<std::int32_t*>(p);
            const char* cur = (v >= 0 && v < int(f.enumNames.size())) ? f.enumNames[size_t(v)].c_str() : "?";
            if (ImGui::BeginCombo("##v", cur)) {
                for (int i = 0; i < int(f.enumNames.size()); ++i)
                    if (ImGui::Selectable(f.enumNames[size_t(i)].c_str(), i == v)) commit(f.enumNames[size_t(i)]);
                ImGui::EndCombo();
            }
            break;
        }
        case FieldKind::Entity: {
            Entity cur = *static_cast<Entity*>(p);
            std::string preview = "(none)";
            if (!cur.is_null() && world().alive(cur)) preview = world().info(cur).name + "  [" + world().id_of(cur) + "]";
            if (ImGui::BeginCombo("##v", preview.c_str())) {
                if (ImGui::Selectable("(none)", cur.is_null())) commit(Json(nullptr));
                for (Entity o : world().entities()) {
                    ImGui::PushID(int(o.index));
                    std::string label = world().info(o).name + "  [" + world().id_of(o) + "]";
                    if (ImGui::Selectable(label.c_str(), o == cur)) commit(world().id_of(o));
                    ImGui::PopID();
                }
                ImGui::EndCombo();
            }
            break;
        }
        case FieldKind::Asset: {
            std::string cur = *static_cast<std::string*>(p);
            const float btn = ImGui::GetFrameHeight() + 2;
            ImGui::SetNextItemWidth(-btn - ImGui::GetStyle().ItemSpacing.x);
            std::string tmp = cur;
            bool enter = ImGui::InputText("##v", &tmp, ImGuiInputTextFlags_EnterReturnsTrue);
            if (enter || ImGui::IsItemDeactivatedAfterEdit()) {
                if (tmp != cur) commit(tmp);
            }
            if (ImGui::BeginDragDropTarget()) {
                if (const ImGuiPayload* pl = ImGui::AcceptDragDropPayload("FA_ASSET")) {
                    std::string path(static_cast<const char*>(pl->Data), pl->DataSize > 0 ? size_t(pl->DataSize) - 1 : 0);
                    if (asset_matches(f.assetType, path)) commit(path);
                    else notify("'" + path + "' is not a " + f.assetType + " asset", 1);
                }
                ImGui::EndDragDropTarget();
            }
            ImGui::SameLine();
            if (ImGui::Button("...", ImVec2(btn, 0))) {
                assetPickFilter_.clear();
                ImGui::OpenPopup("##asset_pick");
            }
            ImGui::SetItemTooltip("Pick a %s asset from the project", f.assetType.c_str());
            if (ImGui::BeginPopup("##asset_pick")) {
                ImGui::SetNextItemWidth(260);
                if (ImGui::IsWindowAppearing()) ImGui::SetKeyboardFocusHere();
                ImGui::InputTextWithHint("##pf", "Filter...", &assetPickFilter_);
                ImGui::BeginChild("##pl", ImVec2(360, 220), ImGuiChildFlags_Borders);
                if (ImGui::Selectable("(none)", cur.empty())) { commit(std::string()); ImGui::CloseCurrentPopup(); }
                if (f.assetType == "mesh") {
                    for (const char* prim : {"cube", "sphere", "plane", "cylinder", "capsule", "cone", "quad"})
                        if (contains_ci(prim, assetPickFilter_) && ImGui::Selectable(prim, cur == prim)) { commit(std::string(prim)); ImGui::CloseCurrentPopup(); }
                }
                for (const auto& file : project_files()) {
                    if (!asset_matches(f.assetType, file) || !contains_ci(file, assetPickFilter_)) continue;
                    if (ImGui::Selectable(file.c_str(), file == cur)) { commit(file); ImGui::CloseCurrentPopup(); }
                }
                ImGui::EndChild();
                ImGui::EndPopup();
            }
            break;
        }
        case FieldKind::Json: {
            Json& jv = *static_cast<Json*>(p);
            JsonEditState& st = jsonEdits_[key];
            if (!st.editing) st.text = jv.dump(2);
            const float h = std::clamp(ImGui::GetTextLineHeight() * float(std::count(st.text.begin(), st.text.end(), '\n') + 1) + 10.0f, 44.0f, 180.0f);
            ImGui::InputTextMultiline("##v", &st.text, ImVec2(-FLT_MIN, h));
            if (ImGui::IsItemActive() || ImGui::IsItemEdited()) st.editing = true;
            Json parsed;
            st.error.clear();
            if (st.editing) {
                auto r = parse_json(st.text, key);
                if (r) parsed = *r;
                else st.error = r.error().message;
            }
            if (ImGui::IsItemDeactivated()) {
                if (st.editing && st.error.empty() && parsed != jv) commit(parsed);
                else if (st.editing && !st.error.empty()) { /* keep the text visible with the error */ }
                if (st.error.empty()) st.editing = false;
            }
            if (!st.error.empty()) ImGui::TextColored(ImVec4(1, 0.45f, 0.4f, 1), "JSON error: %s", st.error.c_str());
            break;
        }
    }
    return changed;
}

void Editor::draw_inspector_component(Entity e, const TypeInfo& t) {
    void* comp = world().get(e, t);
    if (!comp) return;
    const bool removable = t.name != "Transform";
    bool visible = true;
    ImGui::PushID(t.name.c_str());
    bool open = removable ? ImGui::CollapsingHeader(t.name.c_str(), &visible, ImGuiTreeNodeFlags_DefaultOpen)
                          : ImGui::CollapsingHeader(t.name.c_str(), ImGuiTreeNodeFlags_DefaultOpen);
    if (ImGui::IsItemHovered(ImGuiHoveredFlags_DelayShort)) {
        ImGui::BeginTooltip();
        ImGui::PushTextWrapPos(ImGui::GetFontSize() * 28.0f);
        ImGui::TextColored(ImVec4(0.6f, 0.75f, 1, 1), "%s  (%s)", t.name.c_str(), t.category.c_str());
        ImGui::TextUnformatted(t.doc.c_str());
        ImGui::PopTextWrapPos();
        ImGui::EndTooltip();
    }
    if (!visible) {
        begin_edit("remove:" + world().id_of(e) + "/" + t.name + ":" + std::to_string(uiFrame_));
        world().remove(e, t);
        ImGui::PopID();
        return;
    }
    if (open) {
        if (ImGui::BeginTable("##fields", 2, ImGuiTableFlags_SizingStretchProp | ImGuiTableFlags_NoSavedSettings | ImGuiTableFlags_PadOuterX)) {
            ImGui::TableSetupColumn("name", ImGuiTableColumnFlags_WidthStretch, 0.40f);
            ImGui::TableSetupColumn("value", ImGuiTableColumnFlags_WidthStretch, 0.60f);
            for (const FieldInfo& f : t.fields) {
                if (!f.serialized && play_ == PlayState::Edit) continue;
                ImGui::TableNextRow();
                ImGui::TableSetColumnIndex(0);
                ImGui::AlignTextToFramePadding();
                if (!f.serialized) ImGui::TextDisabled("%s", f.name.c_str());
                else ImGui::TextUnformatted(f.name.c_str());
                doc_tooltip(tooltip_text(f));
                ImGui::TableSetColumnIndex(1);
                ImGui::PushID(f.name.c_str());
                ImGui::BeginDisabled(f.readOnly);
                draw_field(e, t, f, comp);
                ImGui::EndDisabled();
                doc_tooltip(tooltip_text(f));
                ImGui::PopID();
            }
            ImGui::EndTable();
        }
    }
    ImGui::PopID();
}

void Editor::draw_inspector() {
    if (!ImGui::Begin("Inspector", &showInspector_)) { ImGui::End(); return; }
    World& w = world();
    Entity e = selected();
    if (play_ != PlayState::Edit)
        ImGui::TextColored(ImVec4(1, 0.8f, 0.3f, 1), "Play mode: edits are temporary and are discarded on Stop.");

    if (e.is_null()) {
        ImGui::TextDisabled("No entity selected. Click one in the Hierarchy or Viewport.");
        ImGui::Spacing();
        if (const TypeInfo* ss = TypeRegistry::global().find("SceneSettings")) {
            if (ImGui::CollapsingHeader("Scene Settings", ImGuiTreeNodeFlags_DefaultOpen)) {
                if (ImGui::BeginTable("##scene", 2, ImGuiTableFlags_SizingStretchProp | ImGuiTableFlags_NoSavedSettings)) {
                    ImGui::TableSetupColumn("n", ImGuiTableColumnFlags_WidthStretch, 0.40f);
                    ImGui::TableSetupColumn("v", ImGuiTableColumnFlags_WidthStretch, 0.60f);
                    for (const FieldInfo& f : ss->fields) {
                        ImGui::TableNextRow();
                        ImGui::TableSetColumnIndex(0);
                        ImGui::AlignTextToFramePadding();
                        ImGui::TextUnformatted(f.name.c_str());
                        doc_tooltip(tooltip_text(f));
                        ImGui::TableSetColumnIndex(1);
                        ImGui::PushID(f.name.c_str());
                        draw_field(kNullEntity, *ss, f, &w.settings());
                        doc_tooltip(tooltip_text(f));
                        ImGui::PopID();
                    }
                    ImGui::EndTable();
                }
            }
        }
        ImGui::End();
        return;
    }

    const std::string eid = w.id_of(e);
    const TypeInfo* infoType = TypeRegistry::global().find("EntityInfo");
    auto patch_info = [&](const char* field, const Json& v) {
        begin_edit(eid + "/info/" + field);
        if (infoType) {
            if (auto r = patch_component(w, e, *infoType, Json::object({{field, v}})); !r) notify(r.error().to_string(), 2);
            else if (std::string(field) == "id") selectedId_ = v.get<std::string>();
        }
    };
    ImGui::PushID("entity");
    {
        EntityInfo& inf = w.info(e);
        bool active = inf.active;
        if (ImGui::Checkbox("##active", &active)) patch_info("active", active);
        ImGui::SetItemTooltip("Inactive entities (and their children) are skipped by all systems");
        ImGui::SameLine();
        std::string name = inf.name;
        ImGui::SetNextItemWidth(-FLT_MIN);
        if (ImGui::InputText("##name", &name, ImGuiInputTextFlags_EnterReturnsTrue) || ImGui::IsItemDeactivatedAfterEdit()) {
            if (name != w.info(e).name) patch_info("name", name);
        }
        ImGui::SetItemTooltip("Display name (not unique)");
        if (ImGui::BeginTable("##info", 2, ImGuiTableFlags_SizingStretchProp | ImGuiTableFlags_NoSavedSettings)) {
            ImGui::TableSetupColumn("n", ImGuiTableColumnFlags_WidthStretch, 0.40f);
            ImGui::TableSetupColumn("v", ImGuiTableColumnFlags_WidthStretch, 0.60f);
            ImGui::TableNextRow();
            ImGui::TableSetColumnIndex(0);
            ImGui::AlignTextToFramePadding();
            ImGui::TextUnformatted("id");
            ImGui::SetItemTooltip("Stable unique id used in scene JSON, scripts and entity references");
            ImGui::TableSetColumnIndex(1);
            std::string id = eid;
            ImGui::SetNextItemWidth(-FLT_MIN);
            if (ImGui::InputText("##id", &id, ImGuiInputTextFlags_EnterReturnsTrue)) {
                if (id != eid && !id.empty()) patch_info("id", id);
            }
            ImGui::TableNextRow();
            ImGui::TableSetColumnIndex(0);
            ImGui::AlignTextToFramePadding();
            ImGui::TextUnformatted("tags");
            ImGui::SetItemTooltip("Comma-separated free-form labels (enemy, pickup, ...)");
            ImGui::TableSetColumnIndex(1);
            std::string tags;
            for (auto& tg : w.info(e).tags) tags += (tags.empty() ? "" : ", ") + tg;
            std::string tmp = tags;
            ImGui::SetNextItemWidth(-FLT_MIN);
            if (ImGui::InputText("##tags", &tmp, ImGuiInputTextFlags_EnterReturnsTrue) || ImGui::IsItemDeactivatedAfterEdit()) {
                if (tmp != tags) {
                    Json arr = Json::array();
                    std::string cur;
                    for (char c : tmp + ",") {
                        if (c == ',') {
                            size_t a = cur.find_first_not_of(" \t"), b = cur.find_last_not_of(" \t");
                            if (a != std::string::npos) arr.push_back(cur.substr(a, b - a + 1));
                            cur.clear();
                        } else cur += c;
                    }
                    patch_info("tags", arr);
                }
            }
            ImGui::EndTable();
        }
    }
    ImGui::PopID();
    ImGui::Separator();

    std::vector<const TypeInfo*> comps = w.components_of(e);
    for (const TypeInfo* t : comps) {
        if (t->name == "EntityInfo") continue;
        if (!w.alive(e) || !w.get(e, *t)) continue;
        draw_inspector_component(e, *t);
    }
    if (!w.alive(e)) { ImGui::End(); return; }

    ImGui::Spacing();
    const float bw = ImGui::GetContentRegionAvail().x;
    if (ImGui::Button("Add Component", ImVec2(bw, 0))) {
        componentFilter_.clear();
        ImGui::OpenPopup("##add_component");
    }
    if (ImGui::BeginPopup("##add_component")) {
        if (ImGui::IsWindowAppearing()) ImGui::SetKeyboardFocusHere();
        ImGui::SetNextItemWidth(280);
        ImGui::InputTextWithHint("##cf", "Search components...", &componentFilter_);
        ImGui::BeginChild("##cl", ImVec2(320, 300), ImGuiChildFlags_Borders);
        std::string lastCat;
        for (const TypeInfo* t : TypeRegistry::global().all()) {
            if (t->name == "EntityInfo" || t->name == "Transform" || t->name == "SceneSettings") continue;
            if (w.get(e, *t)) continue;
            if (!contains_ci(t->name, componentFilter_) && !contains_ci(t->category, componentFilter_)) continue;
            if (t->category != lastCat) {
                lastCat = t->category;
                ImGui::TextColored(ImVec4(0.55f, 0.7f, 1.0f, 1), "%s", lastCat.c_str());
            }
            if (ImGui::Selectable(("  " + t->name).c_str())) {
                begin_edit("add:" + eid + "/" + t->name + ":" + std::to_string(uiFrame_));
                if (auto r = patch_component(w, e, *t, Json::object()); !r) notify(r.error().to_string(), 2);
                ImGui::CloseCurrentPopup();
            }
            doc_tooltip(t->doc);
        }
        ImGui::EndChild();
        ImGui::EndPopup();
    }
    ImGui::End();
}

}  // namespace fa::editor
