// Project dialog (open / new from template), validation report, docs viewer, toasts and the update popup.
#include <algorithm>
#include <cstdlib>
#include <filesystem>

#include "editor_internal.h"
#include "fa/core/fs.h"
#include "sokol_app.h"

namespace fa::editor {

namespace stdfs = std::filesystem;

static void scan_projects(std::vector<std::string>& out) {
    out.clear();
    std::error_code ec;
    std::vector<stdfs::path> roots = {stdfs::current_path(ec)};
    if (std::string h = home_dir(); !h.empty()) roots.push_back(stdfs::path(h) / "FactorIA" / "examples");
    for (const auto& root : roots) {
        if (!stdfs::exists(root / kProjectFileName, ec)) {
            // examples/* one level down
            for (auto sub : {root, root / "examples"}) {
                if (!stdfs::is_directory(sub, ec)) continue;
                int n = 0;
                for (auto& d : stdfs::directory_iterator(sub, ec)) {
                    if (++n > 200) break;
                    if (d.is_directory(ec) && stdfs::exists(d.path() / kProjectFileName, ec)) out.push_back(d.path().string());
                }
            }
        } else {
            out.push_back(root.string());
        }
    }
    std::sort(out.begin(), out.end());
    out.erase(std::unique(out.begin(), out.end()), out.end());
}

// Deletes a project folder from disk. Only a folder with factoria.json: a typed path cannot wipe anything else. Returns
// "" or what went wrong.
static std::string delete_project_folder(const std::string& dir) {
    std::error_code ec;
    if (!stdfs::exists(stdfs::path(dir) / kProjectFileName, ec)) return "'" + dir + "' is not a FactorIA project (no " + std::string(kProjectFileName) + "); nothing was deleted.";
    if (fs::remove_tree(dir, ec) == static_cast<std::uintmax_t>(-1) || ec) {
        // Read-only files (a .git folder's objects) stop remove_all on Windows: make them writable and try again.
        std::error_code ec2;
        for (auto it = stdfs::recursive_directory_iterator(dir, ec2); !ec2 && it != stdfs::recursive_directory_iterator(); it.increment(ec2))
            stdfs::permissions(it->path(), stdfs::perms::owner_write, stdfs::perm_options::add, ec2);
        ec.clear();
        fs::remove_tree(dir, ec);
    }
    if (ec) return "Could not delete everything in '" + dir + "': " + ec.message() + ". Close the programs using files in it (a terminal, an editor, the game) and delete it again.";
    return {};
}

void Editor::draw_project_dialog() {
    const bool forced = !engine_;
    if (!showProjectDialog_ && !forced) return;
    if (forced) showProjectDialog_ = true;
    if (!dlgScanned_) {
        dlgScanned_ = true;
        scan_projects(detectedProjects_);
        std::error_code ec;
        // New projects go to Documents by default, not to the working directory (factoria's own folder when the
        // editor was started from Explorer).
        if (std::string h = home_dir(); dlgNewParent_.empty()) {
            stdfs::path docs = stdfs::path(h) / "Documents";
            dlgNewParent_ = !h.empty() && stdfs::is_directory(docs, ec) ? docs.string() : stdfs::current_path(ec).string();
        }
        if (dlgOpenPath_.empty() && !recentProjects_.empty()) dlgOpenPath_ = recentProjects_.front();
        if (recentProjects_.empty()) {
            if (std::string h = home_dir(); !h.empty()) {
                auto j = load_json_file((stdfs::path(h) / ".factoria" / "editor_recent.json").string());
                if (j && j->is_array())
                    for (auto& v : *j)
                        if (v.is_string() && stdfs::exists(stdfs::path(v.get<std::string>()) / kProjectFileName, ec)) recentProjects_.push_back(v.get<std::string>());
                if (dlgOpenPath_.empty() && !recentProjects_.empty()) dlgOpenPath_ = recentProjects_.front();
            }
        }
    }
    ImGuiViewport* vp = ImGui::GetMainViewport();
    ImGui::SetNextWindowPos(vp->GetCenter(), ImGuiCond_Appearing, ImVec2(0.5f, 0.5f));
    ImGui::SetNextWindowSize(ImVec2(620, 0), ImGuiCond_Appearing);
    bool open = true;
    ImGuiWindowFlags flags = ImGuiWindowFlags_AlwaysAutoResize | ImGuiWindowFlags_NoCollapse | ImGuiWindowFlags_NoSavedSettings;
    if (!ImGui::Begin(forced ? "Welcome to FactorIA###projectdlg" : "Open or create a project###projectdlg", forced ? nullptr : &open, flags)) {
        ImGui::End();
        if (!open) showProjectDialog_ = false;
        return;
    }
    if (forced) ImGui::TextWrapped("No project is open. Open an existing FactorIA project folder (it contains factoria.json) or create a new one from a template.");
    if (!dlgError_.empty()) ImGui::TextColored(ImVec4(1, 0.45f, 0.4f, 1), "%s", dlgError_.c_str());
    ImGui::SeparatorText("Open project");
    ImGui::SetNextItemWidth(-264);
    ImGui::InputTextWithHint("##openpath", "/path/to/project", &dlgOpenPath_);
    ImGui::SameLine();
    bool openNow = false;
    if (ImGui::Button("Browse...##open", ImVec2(80, 0))) {
        std::string p = pick_folder("Open a FactorIA project (the folder with factoria.json)", dlgOpenPath_);
        if (!p.empty()) { dlgOpenPath_ = p; openNow = true; }
    }
    ImGui::SameLine();
    if (ImGui::Button("Open", ImVec2(80, 0)) || openNow) {
        std::string dir = dlgOpenPath_;
        std::error_code ec;
        if (!stdfs::exists(stdfs::path(dir) / kProjectFileName, ec)) {
            std::string root = find_project_root(dir);
            if (!root.empty()) dir = root;
        }
        if (!stdfs::exists(stdfs::path(dir) / kProjectFileName, ec)) dlgError_ = "No " + std::string(kProjectFileName) + " in '" + dir + "'. Pick the project's root folder, or create a new project below.";
        else { dlgError_.clear(); open_project(dir); }
    }
    ImGui::SameLine();
    {
        std::error_code ec;
        const bool isOpen = engine_ && stdfs::equivalent(dlgOpenPath_, projectDir_, ec);
        ImGui::BeginDisabled(isOpen || !stdfs::exists(stdfs::path(dlgOpenPath_) / kProjectFileName, ec));
        if (ImGui::Button("Delete...", ImVec2(80, 0))) dlgDelete_ = dlgOpenPath_;
        at_track("project:delete");
        ImGui::EndDisabled();
        ImGui::SetItemTooltip(isOpen ? "This project is open: open another one first to delete it." : "Delete the selected project from disk (asks first).");
    }
    if (!recentProjects_.empty() || !detectedProjects_.empty()) {
        ImGui::BeginChild("##proj_list", ImVec2(0, 96), ImGuiChildFlags_Borders);
        // The folder name; the full path in the tooltip.
        auto project_row = [&](const std::string& r) {
            ImGui::PushID(r.c_str());
            if (ImGui::Selectable(stdfs::path(r).filename().string().c_str(), dlgOpenPath_ == r, ImGuiSelectableFlags_AllowDoubleClick)) {
                dlgOpenPath_ = r;
                if (ImGui::IsMouseDoubleClicked(0)) open_project(r);
            }
            ImGui::SetItemTooltip("%s", r.c_str());
            ImGui::PopID();
        };
        for (const auto& r : recentProjects_) project_row(r);
        for (const auto& r : detectedProjects_)
            if (std::find(recentProjects_.begin(), recentProjects_.end(), r) == recentProjects_.end()) project_row(r);
        ImGui::EndChild();
    }
    ImGui::SeparatorText("New project from template");
    static std::vector<TemplateInfo> templates = list_templates();
    if (templates.empty()) ImGui::TextDisabled("No templates found.");
    else {
        dlgTemplate_ = std::clamp(dlgTemplate_, 0, int(templates.size()) - 1);
        ImGui::SetNextItemWidth(220);
        if (ImGui::BeginCombo("Template", templates[size_t(dlgTemplate_)].name.c_str())) {
            for (int i = 0; i < int(templates.size()); ++i)
                if (ImGui::Selectable(templates[size_t(i)].name.c_str(), i == dlgTemplate_)) dlgTemplate_ = i;
            ImGui::EndCombo();
        }
        ImGui::SameLine();
        ImGui::TextDisabled("%s", templates[size_t(dlgTemplate_)].description.c_str());
    }
    ImGui::SetNextItemWidth(220);
    ImGui::InputText("Name", &dlgNewName_);
    ImGui::SetNextItemWidth(-150);
    ImGui::InputText("Folder", &dlgNewParent_);
    ImGui::SetItemTooltip("The project is created in <folder>/<name>");
    ImGui::SameLine();
    if (ImGui::Button("Browse...##new", ImVec2(80, 0))) {
        std::string p = pick_folder("Folder for the new project", dlgNewParent_);
        if (!p.empty()) dlgNewParent_ = p;
    }
    ImGui::BeginDisabled(templates.empty() || dlgNewName_.empty());
    if (ImGui::Button("Create project")) {
        stdfs::path target = stdfs::path(dlgNewParent_) / dlgNewName_;
        ScaffoldOptions so;
        so.name = dlgNewName_;
        auto r = create_project(target.string(), templates[size_t(dlgTemplate_)].name, so);
        if (!r) dlgError_ = r.error().to_string();
        else { dlgError_.clear(); open_project(r->dir); }
    }
    ImGui::EndDisabled();
    if (!forced && ImGui::Button("Close")) open = false;

    if (!dlgDelete_.empty() && !ImGui::IsPopupOpen("Delete project?")) ImGui::OpenPopup("Delete project?");
    if (ImGui::BeginPopupModal("Delete project?", nullptr, ImGuiWindowFlags_AlwaysAutoResize)) {
        ImGui::Text("Delete the project '%s'?", stdfs::path(dlgDelete_).filename().string().c_str());
        ImGui::TextDisabled("%s", dlgDelete_.c_str());
        ImGui::TextColored(ImVec4(1, 0.45f, 0.4f, 1), "The folder and everything in it are deleted from disk. This cannot be undone.");
        const bool cancel = ImGui::Button("Cancel", ImVec2(120, 0)) || ImGui::IsKeyPressed(ImGuiKey_Escape);
        ImGui::SetItemDefaultFocus();
        ImGui::SameLine();
        const bool confirmed = ImGui::Button("Delete", ImVec2(120, 0));
        at_track("project:delete-confirm");
        if (confirmed) {
            dlgError_ = delete_project_folder(dlgDelete_);
            std::erase(recentProjects_, dlgDelete_);
            std::erase(detectedProjects_, dlgDelete_);
            save_recent_projects();
            if (dlgOpenPath_ == dlgDelete_) dlgOpenPath_.clear();
            if (dlgError_.empty()) notify("Deleted project " + dlgDelete_, 0);
            dlgDelete_.clear();
            ImGui::CloseCurrentPopup();
        } else if (cancel) {
            dlgDelete_.clear();
            ImGui::CloseCurrentPopup();
        }
        ImGui::EndPopup();
    }
    ImGui::End();
    if (!open) showProjectDialog_ = false;
    if (engine_ && pendingOpen_.empty() && !open) dlgScanned_ = false;
}

void Editor::draw_validation_window() {
    if (!showValidation_) return;
    ImGui::SetNextWindowSize(ImVec2(640, 360), ImGuiCond_FirstUseEver);
    if (ImGui::Begin("Validation report", &showValidation_)) {
        const auto& v = validation_;
        ImGui::TextColored(v.ok ? ImVec4(0.5f, 0.9f, 0.55f, 1) : ImVec4(1, 0.45f, 0.4f, 1), v.ok ? "Project is valid" : "Project has errors");
        ImGui::SameLine();
        ImGui::TextDisabled("%zu error(s), %zu warning(s)%s, %d scene(s), %d script(s) checked", v.errors.size(), v.warnings.size(),
                            v.notes.empty() ? "" : (", " + std::to_string(v.notes.size()) + " note(s)").c_str(), v.scenesChecked, v.scriptsChecked);
        if (ImGui::Button("Re-run")) validation_ = validate_project(projectDir_);
        ImGui::Separator();
        ImGui::BeginChild("##vr");
        ImGui::PushTextWrapPos(0);
        for (const auto& i : v.errors) ImGui::TextColored(ImVec4(1, 0.45f, 0.4f, 1), "error  %s", i.to_string().c_str());
        for (const auto& i : v.warnings) ImGui::TextColored(ImVec4(1, 0.8f, 0.35f, 1), "warn   %s", i.to_string().c_str());
        for (const auto& i : v.notes) ImGui::TextColored(ImVec4(0.6f, 0.75f, 0.95f, 1), "note   %s", i.to_string().c_str());
        if (v.errors.empty() && v.warnings.empty() && v.notes.empty()) ImGui::TextDisabled("Nothing to report.");
        ImGui::PopTextWrapPos();
        ImGui::EndChild();
    }
    ImGui::End();
}

// Markdown, simply: headings coloured, code blocks indented, the rest as wrapped text (docs and release notes).
static void draw_markdown(const std::string& text) {
    ImGui::PushTextWrapPos(0);
    bool code = false;
    size_t pos = 0;
    while (pos <= text.size()) {
        size_t nl = text.find('\n', pos);
        std::string line = text.substr(pos, nl == std::string::npos ? std::string::npos : nl - pos);
        pos = nl == std::string::npos ? text.size() + 1 : nl + 1;
        if (!line.empty() && line.back() == '\r') line.pop_back();  // GitHub release notes use CRLF
        if (line.rfind("```", 0) == 0) { code = !code; continue; }
        if (code) ImGui::TextColored(ImVec4(0.7f, 0.85f, 0.7f, 1), "  %s", line.c_str());
        else if (line.rfind("#", 0) == 0) {
            size_t k = line.find_first_not_of('#');
            ImGui::Spacing();
            ImGui::TextColored(ImVec4(0.55f, 0.75f, 1.0f, 1), "%s", line.substr(k == std::string::npos ? 0 : k).c_str());
        } else if (line.empty()) ImGui::Spacing();
        else ImGui::TextUnformatted(line.c_str());
    }
    ImGui::PopTextWrapPos();
}

void Editor::draw_docs_window() {
    if (!showDocs_) return;
    ImGui::SetNextWindowSize(ImVec2(760, 560), ImGuiCond_FirstUseEver);
    if (ImGui::Begin((docsTitle_ + "###docs").c_str(), &showDocs_)) {
        ImGui::BeginChild("##docbody");
        draw_markdown(docsText_);
        ImGui::EndChild();
    }
    ImGui::End();
}

void Editor::draw_update_popup() {
    const UpdateStage stage = updateStage_;
    if (stage == UpdateStage::Idle) return;
    const char* id = "FactorIA update###update";
    if (!ImGui::IsPopupOpen(id)) ImGui::OpenPopup(id);
    ImGuiViewport* vp = ImGui::GetMainViewport();
    ImGui::SetNextWindowPos(vp->GetCenter(), ImGuiCond_Appearing, ImVec2(0.5f, 0.5f));
    if (!ImGui::BeginPopupModal(id, nullptr, ImGuiWindowFlags_AlwaysAutoResize | ImGuiWindowFlags_NoSavedSettings)) return;
    auto close = [&] {
        updateStage_ = UpdateStage::Idle;
        ImGui::CloseCurrentPopup();
    };
    ImGui::Text("FactorIA %s is available. You have %s.", update_.latest.c_str(), update_.current.c_str());
    ImGui::BeginChild("##notes", ImVec2(640, 340), ImGuiChildFlags_Borders);
    draw_markdown(update_.notes);
    ImGui::EndChild();
    if (stage == UpdateStage::Offer) {
        ImGui::PushTextWrapPos(640);
        ImGui::TextDisabled("Update downloads it, replaces this version and reopens the editor (and the open project). "
                            "Not now keeps this version; the editor asks again the next time it opens.");
        ImGui::PopTextWrapPos();
        if (ImGui::Button("Update", ImVec2(120, 0))) {
            updateProgress_ = 0;
            updateStage_ = UpdateStage::Installing;
            if (updateThread_.joinable()) updateThread_.join();  // the check: already done
            updateThread_ = std::thread([this] {
                auto r = install_update(update_, executable_dir(), [this](double p) { updateProgress_ = float(p); });
                if (!r) updateError_ = r.error().to_string();
                updateStage_ = r ? UpdateStage::Installed : UpdateStage::Failed;
            });
        }
        ImGui::SameLine();
        if (ImGui::Button("Not now", ImVec2(120, 0))) close();
        at_track("update:notnow");
    } else if (stage == UpdateStage::Installing) {
        std::string label = "Downloading FactorIA " + update_.latest + "...";
        ImGui::ProgressBar(updateProgress_, ImVec2(640, 0), label.c_str());
    } else if (stage == UpdateStage::Failed) {
        ImGui::PushTextWrapPos(640);
        ImGui::TextColored(ImVec4(1, 0.45f, 0.4f, 1), "%s", updateError_.c_str());
        ImGui::PopTextWrapPos();
        if (ImGui::Button("Close", ImVec2(120, 0))) close();
    } else {  // Installed: quit (the unsaved-changes dialog still asks), on_cleanup starts the new editor
        restartAfterQuit_ = true;
        sapp_request_quit();
        close();
    }
    ImGui::EndPopup();
}

void Editor::draw_toasts() {
    for (Toast& t : toasts_)  // a toast with a button stays while the mouse is over it
        if (!t.actionLabel.empty() && t.expires < time_ && toastHover_) t.expires = time_ + 1.0;
    toasts_.erase(std::remove_if(toasts_.begin(), toasts_.end(), [&](const Toast& t) { return t.expires < time_; }), toasts_.end());
    toastHover_ = false;
    if (toasts_.empty()) return;
    ImGuiViewport* vp = ImGui::GetMainViewport();
    float y = vp->WorkPos.y + ImGui::GetFrameHeight() * 2 + 18;
    int i = 0;
    std::function<void()> fired;
    for (auto it = toasts_.rbegin(); it != toasts_.rend(); ++it, ++i) {
        ImGui::SetNextWindowPos(ImVec2(vp->WorkPos.x + vp->WorkSize.x * 0.5f, y), ImGuiCond_Always, ImVec2(0.5f, 0));
        ImGui::SetNextWindowBgAlpha(0.92f);
        ImGui::PushStyleColor(ImGuiCol_Border, it->level >= 2 ? ImVec4(1, 0.4f, 0.38f, 1) : it->level == 1 ? ImVec4(1, 0.75f, 0.3f, 1) : ImVec4(0.3f, 0.55f, 0.95f, 1));
        ImGui::PushStyleVar(ImGuiStyleVar_WindowBorderSize, 1.0f);
        ImGui::PushStyleVar(ImGuiStyleVar_WindowPadding, ImVec2(10, 6));
        std::string name = "##toast" + std::to_string(i);
        ImGui::Begin(name.c_str(), nullptr,
                     ImGuiWindowFlags_NoDecoration | ImGuiWindowFlags_AlwaysAutoResize | ImGuiWindowFlags_NoSavedSettings |
                         ImGuiWindowFlags_NoFocusOnAppearing | ImGuiWindowFlags_NoNav | (it->actionLabel.empty() ? ImGuiWindowFlags_NoInputs : 0) | ImGuiWindowFlags_NoDocking);
        ImGui::PushTextWrapPos(460);
        ImGui::TextUnformatted(it->text.c_str());
        ImGui::PopTextWrapPos();
        if (!it->actionLabel.empty()) {
            if (ImGui::SmallButton((it->actionLabel + "##toastAction").c_str())) {
                fired = std::move(it->action);
                it->actionLabel.clear();
                it->expires = 0;
            }
            at_track(it->actionId);
            if (ImGui::IsWindowHovered(ImGuiHoveredFlags_RootAndChildWindows)) toastHover_ = true;
        }
        y += ImGui::GetWindowHeight() + 6;
        ImGui::End();
        ImGui::PopStyleVar(2);
        ImGui::PopStyleColor();
    }
    if (fired) fired();  // after the loop: the action may notify(), which grows toasts_
}

// ------------------------------------------------------------------------------------------------ updated on disk
void Editor::poll_disk_update() {
    // The in-app updater is replacing the files itself (and quits and reopens when it is done): no second notice.
    if (updateStage_ != UpdateStage::Idle || restartAfterQuit_) return;
    UpdateWatch& watch = disk_watch();
    const double every = diskSettling_ ? 1.0 : 5.0;
    if (!diskPollNow_ && time_ - diskPolled_ < every) return;
    diskPollNow_ = false;
    diskPolled_ = time_;
    diskSettling_ = watch.check() == UpdateCheck::Settling;  // a copy that is still going on is looked at again soon
}

bool Editor::disk_update_due() {
    UpdateWatch& watch = disk_watch();
    if (!watch.updated() || updateStage_ != UpdateStage::Idle || restartAfterQuit_) return false;
    return !diskDismissedSet_ || watch.examined_stamp() != diskDismissed_;
}

std::string Editor::disk_restart_blocker() {
    // Nothing is stopped silently: what cannot be picked up again on the other side keeps the button off, with the reason.
    if (ai_busy() || ai_running())
        return "An AI run is in progress. Restarting would stop it: wait for it to finish, or stop it from the AI Assistant.";
    if (play_ != PlayState::Edit) return "A play session is running. Stop it first.";
    if (exportJob_.running()) return "An export is running. Wait for it to finish or cancel it from the Export window.";
    if (setupJob_.running()) return "An installation of Set Up This Computer is running. Wait for it to finish.";
    if (keystoreJob_.running()) return "A keystore is being created. Wait for it to finish.";
    return {};
}

void Editor::request_disk_restart() {
    if (autotest_) {  // the autotest must not quit and reopen itself
        diskRestartRequested_ = true;
        return;
    }
    restartAfterQuit_ = true;  // on_cleanup reopens the editor on this project (open chats are saved by ai_stop)
    sapp_request_quit();
}

void Editor::draw_disk_update_notice() {
    if (!disk_update_due()) return;
    UpdateWatch& watch = disk_watch();
    const std::string blocker = disk_restart_blocker();
    ImGuiViewport* vp = ImGui::GetMainViewport();
    ImGui::SetNextWindowPos(ImVec2(vp->WorkPos.x + vp->WorkSize.x * 0.5f, vp->WorkPos.y + vp->WorkSize.y - 34), ImGuiCond_Always,
                            ImVec2(0.5f, 1.0f));
    ImGui::SetNextWindowBgAlpha(0.96f);
    ImGui::PushStyleColor(ImGuiCol_Border, ImVec4(0.3f, 0.55f, 0.95f, 1));
    ImGui::PushStyleVar(ImGuiStyleVar_WindowBorderSize, 1.0f);
    ImGui::PushStyleVar(ImGuiStyleVar_WindowPadding, ImVec2(12, 8));
    ImGui::Begin("##diskupdate", nullptr,
                 ImGuiWindowFlags_NoDecoration | ImGuiWindowFlags_AlwaysAutoResize | ImGuiWindowFlags_NoSavedSettings |
                     ImGuiWindowFlags_NoFocusOnAppearing | ImGuiWindowFlags_NoNav | ImGuiWindowFlags_NoDocking);
    ImGui::PushTextWrapPos(560);
    ImGui::Text("FactorIA was updated on disk (%s -> %s). Restart the editor to use it.", watch.running().label().c_str(),
                watch.on_disk().label().c_str());
    ImGui::PopTextWrapPos();
    at_track("update:disk");
    ImGui::BeginDisabled(!blocker.empty());
    if (ImGui::Button("Restart", ImVec2(110, 0))) request_disk_restart();
    ImGui::EndDisabled();
    at_track("update:restart", blocker.empty());
    if (!blocker.empty() && ImGui::IsItemHovered(ImGuiHoveredFlags_AllowWhenDisabled)) {
        ImGui::BeginTooltip();
        ImGui::PushTextWrapPos(420);
        ImGui::TextUnformatted(blocker.c_str());
        ImGui::PopTextWrapPos();
        ImGui::EndTooltip();
    }
    ImGui::SameLine();
    if (ImGui::Button("Not now", ImVec2(110, 0))) {  // quiet until the file changes again
        diskDismissed_ = watch.examined_stamp();
        diskDismissedSet_ = true;
    }
    at_track("update:disknotnow");
    if (!blocker.empty()) {
        ImGui::SameLine();
        ImGui::TextDisabled("(Restart is off: hover it)");
    }
    ImGui::End();
    ImGui::PopStyleVar(2);
    ImGui::PopStyleColor();
}

}  // namespace fa::editor
