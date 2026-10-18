// The Export window (File > Export Game..., toolbar Export): the output folder, one button per platform with what an
// export there would do or why it cannot run, and the last export's report (output folder, warnings, next steps).
// The logic is export_job.h (fa::plan_export, fa::export_project on a worker thread); this file only draws it.
#include <algorithm>
#include <cmath>
#include <cstdio>
#include <filesystem>

#include "editor_internal.h"

namespace fa::editor {

namespace {

const ImVec4& kReady = kStatusReady;
const ImVec4& kFailed = kStatusFailed;
const ImVec4& kWarn = kStatusWarn;

const char* label_of(const std::string& platform) {
    const ExportTarget* t = find_export_target(platform);
    return t ? t->label : platform.c_str();
}

std::string show_folder_label() { return std::string("Show in ") + file_manager_name(); }

std::string seconds_text(double s) {
    char buf[32];
    if (s < 1.0) std::snprintf(buf, sizeof buf, "%.0f ms", s * 1000.0);
    else if (s < 60.0) std::snprintf(buf, sizeof buf, "%.1f s", s);
    else std::snprintf(buf, sizeof buf, "%dm %02ds", int(s / 60.0), int(std::fmod(s, 60.0)));
    return buf;
}

}  // namespace

void Editor::open_export_window() {
    showExport_ = true;
    exportFocus_ = true;
    exportChecked_ = -100;  // check every platform again now: a player may have been built meanwhile
}

void Editor::reset_export_state() {
    exportJob_.wait();
    (void)exportJob_.take_result();
    exportSettings_ = ExportSettings{};
    exportStatus_.clear();
    exportSaved_ = {};
    exportSavedError_.clear();
    exportLast_.reset();
    exportChecked_ = -100;
    showExport_ = false;
}

void Editor::refresh_export_status() {
    exportStatus_.clear();
    for (const ExportTarget& t : export_targets())
        exportStatus_.push_back(check_export(export_options(projectDir_, t.platform, exportSettings_)));
    // What factoria.json says (the Android row's format), read like the export reads it.
    if (auto saved = load_export_settings(projectDir_); saved.ok()) {
        exportSaved_ = std::move(*saved);
        exportSavedError_.clear();
    } else {
        exportSaved_ = ProjectExportSettings{};
        exportSavedError_ = saved.error().message + " " + saved.error().hint;
    }
    exportChecked_ = time_;
}

void Editor::poll_export() {
    std::optional<ExportOutcome> done = exportJob_.take_result();
    if (!done) return;
    notify(export_summary(*done), done->ok ? (done->report.warnings.empty() ? 0 : 1) : 2);
    exportLast_ = std::move(done);
    exportChecked_ = -100;  // the output folder exists now
    exportScroll_ = true;
}

void Editor::draw_export_window() {
    if (!showExport_ || !engine_) return;
    const ImGuiViewport* vp = ImGui::GetMainViewport();
    ImGui::SetNextWindowSize(ImVec2(900, 720), ImGuiCond_FirstUseEver);
    ImGui::SetNextWindowPos(ImVec2(vp->WorkPos.x + vp->WorkSize.x * 0.5f, vp->WorkPos.y + vp->WorkSize.y * 0.5f), ImGuiCond_Appearing,
                            ImVec2(0.5f, 0.5f));
    if (exportFocus_) {
        ImGui::SetNextWindowFocus();
        exportFocus_ = false;
    }
    const bool open = ImGui::Begin("Export game###Export", &showExport_, ImGuiWindowFlags_NoDocking);
    if (!open) {
        ImGui::End();
        return;
    }
    // A few file checks per platform: cheap enough to repeat while the window is open (a player built meanwhile shows up).
    if (time_ - exportChecked_ > 2.0) refresh_export_status();
    const bool busy = exportJob_.running();
    ImGui::PushTextWrapPos(0);

    ImGui::TextDisabled("Packages \"%s\" with the same export as `factoria export` and the project.export command. "
                        "It reads the project's files on disk.", projectName_.c_str());
    if (ImGui::Button("Platform settings...")) open_platform_settings(SettingsTab::General);
    at_track("export:settings");
    ImGui::SetItemTooltip("The game icon and what each platform needs: Android version and signing key, macOS category, iOS team... (File > Platform Settings...)");
    if (platformSettings_.loaded() && platformSettings_.dirty()) {
        ImGui::SameLine();
        ImGui::TextColored(kWarn, "Platform settings have unsaved changes: an export uses the saved ones.");
    }
    if (dirty_) {
        ImGui::TextColored(kWarn, "The scene has unsaved changes: the export packages the version on disk.");
        ImGui::SameLine();
        ImGui::BeginDisabled(play_ != PlayState::Edit);
        if (ImGui::SmallButton("Save scene")) save_scene_now();
        ImGui::EndDisabled();
    }
    ImGui::Spacing();

    // ---- output folder
    const std::string parent = export_parent_dir(projectDir_, exportSettings_);
    std::error_code ec;
    const bool parentExists = std::filesystem::is_directory(utf8_path(parent), ec);
    ImGui::AlignTextToFramePadding();
    ImGui::TextUnformatted("Output folder");
    ImGui::SameLine();
    const std::string showLabel = show_folder_label();
    const ImGuiStyle& style = ImGui::GetStyle();
    const float buttonsW = ImGui::CalcTextSize("Choose...").x + ImGui::CalcTextSize("Default").x +
                           ImGui::CalcTextSize(showLabel.c_str()).x + style.FramePadding.x * 6 + style.ItemSpacing.x * 3;
    ImGui::SetNextItemWidth(std::max(160.0f, ImGui::GetContentRegionAvail().x - buttonsW));
    if (ImGui::InputTextWithHint("##exportout", parent.c_str(), &exportSettings_.outDir)) exportChecked_ = -100;
    ImGui::SetItemTooltip("Parent folder of the exports (relative paths are relative to the project). Empty: %s", parent.c_str());
    ImGui::SameLine();
    if (ImGui::Button("Choose...")) {
        const std::string picked = pick_folder("Export the game into", parentExists ? parent : projectDir_);
        if (!picked.empty()) {
            exportSettings_.outDir = picked;
            exportChecked_ = -100;
        }
    }
    ImGui::SameLine();
    ImGui::BeginDisabled(exportSettings_.outDir.empty());
    if (ImGui::Button("Default")) {
        exportSettings_.outDir.clear();
        exportChecked_ = -100;
    }
    ImGui::EndDisabled();
    ImGui::SetItemTooltip("Back to <project>/build/export");
    ImGui::SameLine();
    ImGui::BeginDisabled(!parentExists);
    if (ImGui::Button(showLabel.c_str()))
        if (std::string why = open_in_file_manager(parent); !why.empty()) notify(why, 1);
    ImGui::EndDisabled();
    if (!parentExists) ImGui::SetItemTooltip("The first export creates it");
    ImGui::TextDisabled("Each export replaces the folder <output folder>/<game>-<platform> it writes, and nothing else.");
    ImGui::SetItemTooltip("Only a folder an earlier export wrote (it holds %s) or an empty one is replaced: if a folder of "
                          "that name with other files is there, the rows say so and nothing is deleted.",
                          kExportMarkerFile);
    ImGui::Checkbox("Release", &exportSettings_.release);
    ImGui::SetItemTooltip("Android: builds a release APK or AAB, signed with the keystore of Platform settings > Android (without one the export fails with a "
                          "message that says how to create a keystore). Windows, macOS and Linux: the whole game goes into one file, "
                          "game.pak, next to the executable (no game folder, no loose scripts: they are compiled to bytecode unless "
                          "export.scriptBytecode is false in factoria.json). iOS: only the build commands of the build script change.");
    ImGui::Separator();

    // ---- one row per platform
    const auto& targets = export_targets();
    if (ImGui::BeginTable("##exporttargets", 2, ImGuiTableFlags_RowBg | ImGuiTableFlags_BordersInnerH | ImGuiTableFlags_PadOuterX)) {
        ImGui::TableSetupColumn("platform", ImGuiTableColumnFlags_WidthFixed, ImGui::CalcTextSize("Export Android").x + 24);
        ImGui::TableSetupColumn("status", ImGuiTableColumnFlags_WidthStretch);
        for (size_t i = 0; i < targets.size(); ++i) {
            const ExportTarget& t = targets[i];
            const ExportStatus* st = i < exportStatus_.size() ? &exportStatus_[i] : nullptr;
            ImGui::PushID(t.platform);
            ImGui::TableNextRow();
            ImGui::TableSetColumnIndex(0);
            ImGui::BeginDisabled(busy || !st || !st->ready);
            if (ImGui::Button((std::string("Export ") + t.label).c_str(), ImVec2(-FLT_MIN, 0)) && st && st->ready &&
                exportJob_.start(export_options(projectDir_, t.platform, exportSettings_))) {
                exportLast_.reset();
                exportScroll_ = true;
                FA_INFO("editor", "exporting for {} into {}", t.platform, st->plan.outputDir);
            }
            ImGui::EndDisabled();
            at_track(std::string("export:") + t.platform);
            ImGui::TableSetColumnIndex(1);
            const bool android = std::string(t.platform) == "android";
            const std::string format = android ? exportSaved_.android.format : std::string();
            if (!st) {
                ImGui::TextDisabled("Checking...");
            } else if (st->ready) {
                ImGui::TextColored(kReady, "Ready");
                std::string where = "Writes " + st->plan.outputDir;
                if (!st->plan.artifact.empty()) where += "\nBuilds " + st->plan.artifact;
                if (!st->plan.player.empty()) where += "\nPlayer: " + st->plan.player;
                ImGui::SetItemTooltip("%s", where.c_str());
                ImGui::SameLine();
                ImGui::TextUnformatted(export_target_note(t, format).c_str());
                if (st->plan.mode == "prebuilt")
                    ImGui::TextDisabled("Mode prebuilt: the ready-made player of the FactorIA download (no engine source%s).",
                                        std::string(t.platform) == "android" ? ", NDK or CMake" : "");
                else if (st->plan.mode == "source")
                    ImGui::TextDisabled("Mode source: the build compiles the engine from the FactorIA checkout.");
                for (const std::string& w : st->plan.warnings) ImGui::TextColored(kWarn, "%s", w.c_str());
            } else {
                ImGui::TextColored(kFailed, "Not available here: %s", export_error_text(st->error).c_str());
                if (!st->hint.empty()) ImGui::TextDisabled("How to fix it: %s", st->hint.c_str());
            }
            if (st) draw_setup_buttons(t.platform, "export");  // what setup can install to fix the row (or the iOS tools)
            if (android) {  // what the Android export produces: the project's export.android.format, saved when changed here
                ImGui::AlignTextToFramePadding();
                ImGui::TextUnformatted("Format");
                ImGui::SameLine();
                ImGui::BeginDisabled(busy || !exportSavedError_.empty());
                const SettingsChoice* cur = find_choice(android_formats(), exportSaved_.android.format);
                ImGui::SetNextItemWidth(ImGui::GetFontSize() * 14.0f);
                if (ImGui::BeginCombo("##androidformat", cur ? cur->label : exportSaved_.android.format.c_str())) {
                    for (const SettingsChoice& c : android_formats()) {
                        if (ImGui::Selectable(c.label, exportSaved_.android.format == c.value)) set_android_format(c.value);
                        ImGui::SetItemTooltip("%s", c.note);
                    }
                    ImGui::EndCombo();
                }
                ImGui::EndDisabled();
                at_track("export:android-format");
                ImGui::SetItemTooltip("What the Android export produces: an APK, an AAB for Google Play, or only the Gradle project. This is the project's "
                                      "export.android.format: changing it saves it in factoria.json (the same setting as Platform settings > Android).");
                if (!exportSavedError_.empty()) ImGui::TextColored(kFailed, "factoria.json: %s", export_error_text(exportSavedError_).c_str());
            }
            const std::optional<SettingsTab> settingsTab = settings_tab_for_platform(t.platform);  // the web has none
            if (settingsTab) {
                if (ImGui::SmallButton("Settings...")) open_platform_settings(*settingsTab);
                at_track(std::string("export:settings:") + t.platform);
                ImGui::SetItemTooltip("Platform settings for %s: icon and what this export needs.", t.label);
            }
            if (export_needs_player(t.platform)) {
                ImGui::SameLine();
                const auto it = exportSettings_.players.find(t.platform);
                const bool win = std::string(t.platform) == "windows";
                if (ImGui::SmallButton("Choose player...")) {
                    const std::string picked =
                        pick_file(std::string("factoria_player built for ") + t.label, home_dir(), "factoria_player",
                                  win ? std::vector<std::string>{"exe"} : std::vector<std::string>{});
                    if (!picked.empty()) {
                        exportSettings_.players[t.platform] = picked;
                        exportChecked_ = -100;
                    }
                }
                ImGui::SetItemTooltip("The factoria_player%s built for %s that this export copies, e.g. the one next to factoria%s "
                                      "in the FactorIA download for %s.",
                                      win ? ".exe" : "", t.label, win ? ".exe" : "", t.label);
                if (it != exportSettings_.players.end()) {
                    ImGui::SameLine();
                    if (ImGui::SmallButton("Clear player")) {
                        exportSettings_.players.erase(it);
                        exportChecked_ = -100;
                    }
                }
            }
            ImGui::PopID();
        }
        ImGui::EndTable();
    }
    ImGui::Separator();

    // ---- the last export (scrolled into view when an export starts or ends)
    if (exportScroll_) {
        ImGui::SetScrollHereY(0.0f);
        exportScroll_ = false;
    }
    if (busy) {
        const int dots = int(std::fmod(time_ * 3.0, 4.0));
        if (exportJob_.cancelling()) {
            ImGui::Text("Cancelling the %s export%.*s", label_of(exportJob_.platform()), dots, "...");
        } else {
            const std::string line = exportJob_.progress_line();  // the Gradle build of an Android APK reports its lines
            ImGui::TextWrapped("Exporting for %s%.*s%s%s", label_of(exportJob_.platform()), dots, "...", line.empty() ? "" : "  ", line.c_str());
        }
        ImGui::BeginDisabled(exportJob_.cancelling());
        if (ImGui::Button("Cancel")) exportJob_.cancel();
        ImGui::EndDisabled();
        at_track("export:cancel");
        ImGui::SetItemTooltip("Stops the export; an Android build (Gradle) is stopped too.");
        const std::vector<std::string> lines = exportJob_.recent_lines();
        if (!lines.empty() && ImGui::TreeNodeEx("Build output", ImGuiTreeNodeFlags_DefaultOpen)) {
            const float h = ImGui::GetTextLineHeightWithSpacing() * 10.0f;
            if (ImGui::BeginChild("##exportlog", ImVec2(0, h), ImGuiChildFlags_Borders)) {
                const bool atBottom = ImGui::GetScrollY() >= ImGui::GetScrollMaxY() - 4.0f;
                for (const std::string& l : lines) ImGui::TextUnformatted(l.c_str());
                if (atBottom) ImGui::SetScrollHereY(1.0f);
            }
            ImGui::EndChild();
            ImGui::TreePop();
        }
    } else if (!exportLast_) {
        ImGui::TextDisabled("Press a platform's button. Its report (output folder, warnings, next steps) shows here.");
    } else {
        const ExportOutcome& o = *exportLast_;
        if (o.ok) {
            const ExportReport& r = o.report;
            ImGui::TextColored(kReady, "Exported for %s in %s", label_of(o.platform), seconds_text(o.seconds).c_str());
            if (!r.artifact.empty()) {  // the APK / AAB that was built
                const std::string label = export_format_label(r.format);
                ImGui::Text("%s: %s", label.empty() ? "Built" : label.c_str(), r.artifact.c_str());
                if (ImGui::Button((showLabel + "##artifact").c_str()))
                    if (std::string why = reveal_in_file_manager(r.artifact); !why.empty()) notify(why, 1);
                at_track("export:reveal-artifact");
                ImGui::SameLine();
                if (ImGui::Button("Copy file path")) ImGui::SetClipboardText(r.artifact.c_str());
                at_track("export:copy-artifact");
                ImGui::Spacing();
            }
            ImGui::Text("Output folder: %s", r.outputDir.c_str());
            if (ImGui::Button(showLabel.c_str()))
                if (std::string why = open_in_file_manager(r.outputDir); !why.empty()) notify(why, 1);
            at_track("export:reveal");
            ImGui::SameLine();
            if (ImGui::Button("Copy path")) ImGui::SetClipboardText(r.outputDir.c_str());
            ImGui::SameLine();
            if (ImGui::Button("Copy report")) ImGui::SetClipboardText(export_report_text(o).c_str());
            if (!r.format.empty()) ImGui::TextDisabled("Format: %s", export_format_label(r.format).c_str());
            if (!r.mode.empty()) ImGui::TextDisabled("Mode: %s", r.mode.c_str());
            ImGui::TextDisabled("%zu files. %s holds the licenses of the engine inside the game: keep it in what you ship.",
                                r.files.size(), r.notices.c_str());
            if (!r.warnings.empty()) {
                ImGui::Spacing();
                ImGui::TextColored(kWarn, "Warnings");
                for (const std::string& w : r.warnings) ImGui::TextColored(kWarn, "- %s", w.c_str());
            }
            if (!r.nextSteps.empty()) {
                ImGui::Spacing();
                ImGui::TextUnformatted("Next steps");
                for (size_t i = 0; i < r.nextSteps.size(); ++i) ImGui::Text("%zu. %s", i + 1, r.nextSteps[i].c_str());
            }
        } else if (o.cancelled) {
            ImGui::TextColored(kWarn, "Export for %s cancelled after %s.", label_of(o.platform), seconds_text(o.seconds).c_str());
            ImGui::TextDisabled("The export was stopped before it finished: press the platform's button to try again.");
        } else {
            ImGui::TextColored(kFailed, "Export for %s failed: %s", label_of(o.platform), export_error_text(o.error).c_str());
            if (!o.hint.empty()) ImGui::Text("How to fix it: %s", o.hint.c_str());
            if (ImGui::Button("Copy report")) ImGui::SetClipboardText(export_report_text(o).c_str());
        }
    }
    ImGui::PopTextWrapPos();
    ImGui::End();
}

}  // namespace fa::editor
