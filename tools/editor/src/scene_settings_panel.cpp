// The Scene settings panel (View > Scene settings): the SceneSettings of the open scene (the scene file's "settings": sky, fog, ambient
// light, gravity, music, colour space) drawn from the reflection, the way the Inspector draws a component, but for the scene itself. A
// sky material (skyMaterial) shows its params typed by material.info, through the Inspector's own draw_material_params. Nothing here
// writes the world directly: every edit is a scene.set_component call with component "SceneSettings" and no id, through
// Editor::edit_command, so it is one undo step, marks the scene dirty and reaches the scene file like any other edit. The rules (the
// groups, the arguments of an edit, what is said about the sky material) are in scene_settings_model.h and tested without a window.
#include <algorithm>
#include <cstdio>

#include "editor_internal.h"
#include "fa/core/reflect.h"
#include "fa/core/strings.h"
#include "imgui_internal.h"
#include "scene_settings_model.h"

namespace fa::editor {

namespace {

// The tooltip of the widget just drawn.
void settings_tip(const std::string& text) {
    if (text.empty() || !ImGui::BeginItemTooltip()) return;
    ImGui::PushTextWrapPos(ImGui::GetFontSize() * 28.0f);
    ImGui::TextUnformatted(text.c_str());
    ImGui::PopTextWrapPos();
    ImGui::EndTooltip();
}

std::string settings_field_tip(const FieldInfo& f) {
    std::string tip = f.doc;
    if (field_has_range(f)) {
        char buf[96];
        std::snprintf(buf, sizeof buf, "\nRange: %g to %g", double(f.minValue), double(f.maxValue));
        tip += buf;
    }
    return tip;
}

}  // namespace

bool Editor::scene_settings_edit(const std::string& field, const Json& value, bool merge, std::string* error) {
    if (!engine_) return false;
    std::string err;
    CommandResult r = edit_command("insp:" + inspEntity_ + ":SceneSettings." + field, "scene.set_component",
                                   settings_edit_args(field, value, merge), &err);
    if (r.ok)
        inspErrors_.erase("SceneSettings." + field);
    else
        inspErrors_["SceneSettings." + field] = err;
    if (error) *error = err;
    return r.ok;
}

bool Editor::scene_settings_reset(const std::string& field, std::string* error) {
    if (!engine_) return false;
    std::string err;
    CommandResult r = edit_command("sset:reset:" + field + ":" + std::to_string(uiFrame_), "scene.set_component",
                                   settings_reset_args(field), &err);
    if (r.ok)
        inspErrors_.erase("SceneSettings." + field);
    else
        inspErrors_["SceneSettings." + field] = err;
    if (error) *error = err;
    return r.ok;
}

void Editor::draw_scene_settings_panel() {
    first_floating_window(ImVec2(180, 60), ImVec2(430, 540));
    if (!ImGui::Begin("Scene settings", &showSceneSettings_)) {
        ImGui::End();
        return;
    }
    const TypeInfo* type = TypeRegistry::global().find("SceneSettings");
    if (!engine_ || !type) {
        ImGui::TextDisabled("Open a project to edit the settings of its scene.");
        ImGui::End();
        return;
    }
    ImGui::TextDisabled("The settings of the whole scene. Every change is one undo step.");
    draw_play_banner(*this);
    static const Json defaults = settings_defaults(*type);
    const Json cur = settings_values(*type, &world().settings());

    for (const SettingsGroup& g : settings_groups(*type)) {
        ImGui::PushID(g.title.c_str());
        const bool open = ImGui::CollapsingHeader(g.title.c_str(), ImGuiTreeNodeFlags_DefaultOpen);
        settings_tip(g.hint);
        if (open && ImGui::BeginTable("##fields", 2, ImGuiTableFlags_SizingStretchProp)) {
            ImGui::TableSetupColumn("name", ImGuiTableColumnFlags_WidthStretch, 0.34f);
            ImGui::TableSetupColumn("value", ImGuiTableColumnFlags_WidthStretch, 0.66f);
            for (const FieldInfo* fp : g.fields) {
                const FieldInfo& f = *fp;
                const std::string key = "SceneSettings." + f.name;
                const Json value = cur.contains(f.name) ? cur[f.name] : Json(nullptr);
                const bool changed = cur.contains(f.name) && defaults.contains(f.name) && value != defaults[f.name];
                ImGui::TableNextRow();
                ImGui::TableSetColumnIndex(0);
                ImGui::AlignTextToFramePadding();
                ImGui::PushID(f.name.c_str());
                ImGui::TextUnformatted((f.name + (changed ? " *" : "")).c_str());
                at_track("sset:label:" + f.name);
                settings_tip(settings_field_tip(f) + (changed ? "\nChanged from the default." : "\nThe default."));
                ImGui::PopID();
                ImGui::TableSetColumnIndex(1);
                if (!material_field_of_params(f.name).empty()) {
                    draw_material_params(kNullEntity, cur, "SceneSettings", f.name);
                } else {
                    Json out;
                    if (draw_field_widget(key, f, value, f.readOnly, out)) scene_settings_edit(f.name, out);
                }
                if (f.name == "skyMaterial" && value.is_string() && !value.get<std::string>().empty()) {
                    const std::string path = value.get<std::string>();
                    if (assetReportAt_ + 0.5 < time_ || assetReport_.is_null()) {
                        assetReportAt_ = time_;
                        assetReport_ =
                            engine_ && engine_->renderer() ? engine_->renderer()->asset_report() : Json::object();
                    }
                    const MaterialInfoEntry& info = material_info_for(path);
                    const SkyMaterialNote note =
                        sky_material_note(path, info.info, info.error, material_build_error(assetReport_, path));
                    if (note.level != SkyMaterialNote::Level::None) {
                        const ImVec4 colour = note.level == SkyMaterialNote::Level::Error     ? kStatusFailed
                                              : note.level == SkyMaterialNote::Level::Warning ? kStatusWarn
                                                                                              : kStatusReady;
                        ImGui::PushStyleColor(ImGuiCol_Text, colour);
                        ImGui::TextWrapped("%s", note.text.c_str());
                        ImGui::PopStyleColor();
                        at_track("sset:note");
                    }
                }
                if (auto it = inspErrors_.find(key); it != inspErrors_.end()) {
                    ImGui::PushStyleColor(ImGuiCol_Text, kStatusFailed);
                    ImGui::TextWrapped("%s", it->second.c_str());
                    ImGui::PopStyleColor();
                }
                if (changed) {
                    ImGui::PushID(f.name.c_str());
                    if (ImGui::SmallButton("Reset")) scene_settings_reset(f.name);
                    at_track("sset:reset:" + f.name);
                    settings_tip("Back to the default (an undo step: Undo brings the value back).");
                    ImGui::PopID();
                }
            }
            ImGui::EndTable();
        }
        ImGui::PopID();
    }
    ImGui::End();
}

}  // namespace fa::editor
