// "Save as prefab..." (hierarchy context menu and Edit menu): saves an entity of the running world, with its children, as a
// prefab file through the engine command prefab.save. The dialog only builds the arguments and shows the result: an existing
// file is replaced only after the user confirms (the command answers already_exists first), and the notes the command returns
// (what the file does NOT carry, e.g. the root position) are shown so nothing is dropped silently.
#include <cfloat>

#include "editor_internal.h"

namespace fa::editor {

void Editor::refresh_asset_lists() {
    // The Assets panel and the asset pickers rescan the project folder on their next frame.
    assetsScanned_ = -10;
    filesScanned_ = -10;
    projectFiles_.clear();
}

void Editor::open_prefab_dialog(Entity e) {
    if (!engine_ || e.is_null() || !world().alive(e)) return;
    prefabDlg_ = PrefabDialogState{};
    prefabDlg_.open = true;
    prefabDlg_.entityId = world().id_of(e);
    prefabDlg_.entityName = world().info(e).name;
    prefabDlg_.path = suggest_prefab_path(prefabDlg_.entityId);
}

PrefabSaveOutcome Editor::do_prefab_save(bool overwrite) {
    PrefabSaveOutcome out = save_prefab(engine_->commands(), prefabDlg_.entityId, prefabDlg_.path, overwrite);
    prefabDlg_.result = out;
    prefabDlg_.askOverwrite = !out.ok && out.alreadyExists;
    prefabDlg_.done = out.ok;
    if (out.ok) {
        refresh_asset_lists();
        assetSelected_ = out.path;
        std::string msg = std::string(out.overwritten ? "Replaced prefab " : "Saved prefab ") + out.path;
        if (out.children > 0) msg += " (with " + std::to_string(out.children) + (out.children == 1 ? " child)" : " children)");
        notify(msg);
        for (const std::string& n : out.notes) FA_INFO("editor", "prefab.save: {}", n);
    } else if (!out.alreadyExists) {
        FA_WARN("editor", "prefab.save failed: {} {}", out.message, out.hint);
    }
    return out;
}

void Editor::draw_prefab_dialog() {
    PrefabDialogState& d = prefabDlg_;
    if (d.open) {
        ImGui::OpenPopup("Save as prefab###prefabdlg");
        d.open = false;
    }
    ImGuiViewport* vp = ImGui::GetMainViewport();
    ImGui::SetNextWindowPos(vp->GetCenter(), ImGuiCond_Appearing, ImVec2(0.5f, 0.5f));
    // A fixed width: an auto-resizing window whose text wraps at its own edge would grow with its longest line.
    ImGui::SetNextWindowSizeConstraints(ImVec2(600, 0), ImVec2(600, FLT_MAX));
    if (!ImGui::BeginPopupModal("Save as prefab###prefabdlg", nullptr, ImGuiWindowFlags_AlwaysAutoResize | ImGuiWindowFlags_NoSavedSettings)) return;
    const PrefabSaveOutcome& r = d.result;
    auto close = [&] {
        d = PrefabDialogState{};
        ImGui::CloseCurrentPopup();
    };

    ImGui::PushTextWrapPos(0.0f);
    ImGui::TextWrapped("Save '%s' [%s] and its children as a prefab file. Scenes and scripts can then spawn it again "
                       "(scene.spawn {\"prefab\": path}, a scene entity, or a scene.import_ascii legend).",
                       d.entityName.c_str(), d.entityId.c_str());
    ImGui::PopTextWrapPos();
    ImGui::Spacing();
    ImGui::TextUnformatted("File");
    ImGui::SameLine();
    ImGui::SetNextItemWidth(-FLT_MIN);
    ImGui::BeginDisabled(d.done);
    if (ImGui::InputText("##prefabpath", &d.path, ImGuiInputTextFlags_EnterReturnsTrue) && !d.askOverwrite && !d.path.empty()) do_prefab_save(false);
    ImGui::EndDisabled();
    ImGui::SetItemTooltip("Project-relative path ending in .prefab.json. Prefabs normally live in prefabs/, where project.info and project.validate look.");
    if (ImGui::IsWindowAppearing()) ImGui::SetKeyboardFocusHere(-1);

    if (d.askOverwrite) {
        ImGui::Spacing();
        ImGui::PushStyleColor(ImGuiCol_Text, ImVec4(1, 0.8f, 0.35f, 1));
        ImGui::TextWrapped("'%s' already exists. Replace it?", d.path.c_str());
        ImGui::PopStyleColor();
        ImGui::TextDisabled("Every scene that instantiates this prefab will get the new version.");
        ImGui::Spacing();
        if (ImGui::Button("Overwrite")) do_prefab_save(true);
        at_track("prefab.overwrite");
        ImGui::SameLine();
        if (ImGui::Button("Choose another name")) {
            d.askOverwrite = false;
            d.result = PrefabSaveOutcome{};
        }
        ImGui::SameLine();
        if (ImGui::Button("Cancel")) close();
    } else if (d.done) {
        ImGui::Spacing();
        ImGui::PushStyleColor(ImGuiCol_Text, ImVec4(0.5f, 0.9f, 0.55f, 1));
        ImGui::TextWrapped("%s %s (%zu %s).", r.overwritten ? "Replaced" : "Saved", r.path.c_str(), r.children,
                           r.children == 1 ? "child" : "children");
        ImGui::PopStyleColor();
        if (!r.notes.empty()) {
            ImGui::Spacing();
            ImGui::TextUnformatted("What the file does not carry:");
            ImGui::PushTextWrapPos(0.0f);
            for (const std::string& n : r.notes) {
                ImGui::Bullet();
                ImGui::TextWrapped("%s", n.c_str());
            }
            ImGui::PopTextWrapPos();
        }
        ImGui::Spacing();
        if (ImGui::Button("Close")) close();
        at_track("prefab.close");
    } else {
        if (!r.message.empty()) {
            ImGui::Spacing();
            ImGui::PushTextWrapPos(0.0f);
            ImGui::TextColored(ImVec4(1, 0.45f, 0.4f, 1), "%s", r.message.c_str());
            if (!r.hint.empty()) ImGui::TextDisabled("%s", r.hint.c_str());
            ImGui::PopTextWrapPos();
        }
        ImGui::Spacing();
        ImGui::BeginDisabled(d.path.empty());
        if (ImGui::Button("Save")) do_prefab_save(false);
        at_track("prefab.save");
        ImGui::EndDisabled();
        ImGui::SameLine();
        if (ImGui::Button("Cancel")) close();
    }
    ImGui::EndPopup();
}

}  // namespace fa::editor
