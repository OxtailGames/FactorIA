// "Format scene files..." (File menu): puts every scene and prefab of the project into the canonical compact layout through the
// engine command scene.format. It first runs it with check=true and shows the files a real run would rewrite; only after the
// user confirms does the real run happen. The command changes whitespace only (values and key order stay), reads every file
// back before writing it, and skips files that are not valid JSON (reported with line and column).
#include <cfloat>

#include "editor_internal.h"

namespace fa::editor {

void Editor::open_format_window() {
    formatDlg_ = FormatDialogState{};
    formatDlg_.visible = true;
    do_format_check();
}

void Editor::do_format_check() {
    FormatDialogState& d = formatDlg_;
    d.check = run_scene_format(engine_->commands(), true);
    d.checked = true;
    d.ran = false;
    d.run = FormatOutcome{};
}

void Editor::do_format_run() {
    FormatDialogState& d = formatDlg_;
    d.run = run_scene_format(engine_->commands(), false);
    d.ran = true;
    if (d.run.ok) {
        refresh_asset_lists();
        notify("Formatted " + std::to_string(d.run.files.size()) + " scene/prefab file(s)");
    } else {
        notify("Format failed: " + d.run.message, 2);
    }
}

namespace {
void list_files(const std::vector<std::string>& files, float height) {
    ImGui::BeginChild("##formatfiles", ImVec2(0, height), ImGuiChildFlags_Borders);
    for (const std::string& f : files) ImGui::BulletText("%s", f.c_str());
    ImGui::EndChild();
}

void draw_errors(const std::vector<std::string>& errors) {
    if (errors.empty()) return;
    ImGui::Spacing();
    ImGui::TextColored(ImVec4(1, 0.45f, 0.4f, 1), "%zu file%s cannot be formatted and %s left unchanged:", errors.size(), errors.size() == 1 ? "" : "s",
                       errors.size() == 1 ? "was" : "were");
    ImGui::PushTextWrapPos(0.0f);
    for (const std::string& e : errors) {
        ImGui::Bullet();
        ImGui::TextWrapped("%s", e.c_str());
    }
    ImGui::PopTextWrapPos();
}
}  // namespace

void Editor::draw_format_window() {
    FormatDialogState& d = formatDlg_;
    if (d.visible) {
        ImGui::OpenPopup("Format scene files###formatdlg");
        d.visible = false;
    }
    ImGuiViewport* vp = ImGui::GetMainViewport();
    ImGui::SetNextWindowPos(vp->GetCenter(), ImGuiCond_Appearing, ImVec2(0.5f, 0.5f));
    ImGui::SetNextWindowSizeConstraints(ImVec2(620, 0), ImVec2(620, FLT_MAX));  // fixed width: see draw_prefab_dialog
    if (!ImGui::BeginPopupModal("Format scene files###formatdlg", nullptr, ImGuiWindowFlags_AlwaysAutoResize | ImGuiWindowFlags_NoSavedSettings)) return;

    ImGui::PushTextWrapPos(0.0f);
    ImGui::TextDisabled("Rewrites the project's *.scene.json and *.prefab.json files in the layout the engine writes: short arrays "
                        "on one line, a Tilemap's tiles one row per line. Only whitespace changes; values and key order stay.");
    ImGui::PopTextWrapPos();
    ImGui::Spacing();

    if (d.ran) {
        const FormatOutcome& r = d.run;
        if (!r.ok) {
            ImGui::PushTextWrapPos(0.0f);
            ImGui::TextColored(ImVec4(1, 0.45f, 0.4f, 1), "%s", r.message.c_str());
            if (!r.hint.empty()) ImGui::TextDisabled("%s", r.hint.c_str());
            ImGui::PopTextWrapPos();
        } else {
            ImGui::TextColored(ImVec4(0.5f, 0.9f, 0.55f, 1), "Formatted %zu file%s, %zu already had the canonical layout.", r.files.size(),
                               r.files.size() == 1 ? "" : "s", r.unchanged);
            if (!r.files.empty()) list_files(r.files, std::min(180.0f, 28.0f + 20.0f * float(r.files.size())));
            if (!scene_path().empty() && std::find(r.files.begin(), r.files.end(), scene_path()) != r.files.end())
                ImGui::TextDisabled("The open scene was rewritten on disk too; what is on screen did not change.");
            draw_errors(r.errors);
        }
        ImGui::Spacing();
        if (ImGui::Button("Close")) {
            d = FormatDialogState{};
            ImGui::CloseCurrentPopup();
        }
        at_track("format.close");
    } else {
        const FormatOutcome& c = d.check;
        if (!c.ok) {
            ImGui::PushTextWrapPos(0.0f);
            ImGui::TextColored(ImVec4(1, 0.45f, 0.4f, 1), "%s", c.message.c_str());
            if (!c.hint.empty()) ImGui::TextDisabled("%s", c.hint.c_str());
            ImGui::PopTextWrapPos();
        } else if (c.files.empty()) {
            ImGui::TextColored(ImVec4(0.5f, 0.9f, 0.55f, 1), "All %zu scene/prefab file%s already have the canonical layout.", c.unchanged,
                               c.unchanged == 1 ? "" : "s");
            for (const std::string& n : c.notes) ImGui::TextDisabled("%s", n.c_str());
            draw_errors(c.errors);
        } else {
            ImGui::Text("%zu file%s will be rewritten (%zu already canonical):", c.files.size(), c.files.size() == 1 ? "" : "s", c.unchanged);
            list_files(c.files, std::min(180.0f, 28.0f + 20.0f * float(c.files.size())));
            draw_errors(c.errors);
        }
        ImGui::Spacing();
        ImGui::BeginDisabled(!c.ok || c.files.empty());
        char label[64];
        std::snprintf(label, sizeof label, "Format %zu file%s", c.files.size(), c.files.size() == 1 ? "" : "s");
        if (ImGui::Button(label)) do_format_run();
        at_track("format.run");
        ImGui::EndDisabled();
        ImGui::SameLine();
        if (ImGui::Button("Check again")) do_format_check();
        ImGui::SameLine();
        if (ImGui::Button("Cancel")) {
            d = FormatDialogState{};
            ImGui::CloseCurrentPopup();
        }
    }
    ImGui::EndPopup();
}

}  // namespace fa::editor
