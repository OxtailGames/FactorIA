// The AI settings of the open project, as the editor handles them: the resolution the AI settings window shows (where each value
// comes from), the cache invalidation that keeps the UI and the runs from showing stale values, and the top of the window: what
// is being edited, a file that waits for Accept, its problems. The pure parts (what to write) are in ai_project_edit.h.
// docs/EDITOR.md ("AI settings"), docs/AI_PROVIDERS.md ("Per project", "The AI settings window").
#include <algorithm>
#include <cfloat>
#include <chrono>
#include <filesystem>
#include <mutex>
#include <string>
#include <vector>

#include "ai_project_edit.h"
#include "fa/ai/extensions.h"
#include "editor_internal.h"
#include "fa/core/strings.h"

namespace fa::editor {

namespace {

long long steady_ms() {
    return std::chrono::duration_cast<std::chrono::milliseconds>(std::chrono::steady_clock::now().time_since_epoch()).count();
}

}  // namespace

void Editor::ai_project_invalidate() {
    aiProjStale_ = true;
    std::lock_guard<std::mutex> lock(aiProjMu_);
    ++aiProjGen_;  // a resolution that is in flight (ai_with_project_config) must not store its answer after this
    aiProjFileDir_.clear();
    aiProjFileAtMs_ = 0;
    aiProjHasFile_ = false;
    aiProjKey_.clear();
    aiProjAtMs_ = 0;
    aiProjConfig_.reset();
    aiProjError_ = Error{};
}

ai::AiConfig Editor::ai_user_config() {
    std::lock_guard<std::mutex> lock(aiMu_);
    return aiConfig_.providers.empty() ? ai::default_config() : aiConfig_;
}

const Editor::AiProjectUi& Editor::ai_project_refresh() {
    if (projectDir_.empty()) {
        aiProj_ = AiProjectUi{};
        return aiProj_;
    }
    const long long now = steady_ms();
    const bool fresh = aiProj_.dir == projectDir_ && aiProj_.atMs != 0 && !aiProjStale_.load() && now - aiProj_.atMs < 1000;
    if (fresh) return aiProj_;
    aiProjStale_ = false;  // before resolving: an invalidation that comes during it wins
    if (aiProj_.dir != projectDir_) aiProj_ = AiProjectUi{};  // another project: nothing of the last one stays (the ignored file, an error)
    const ai::AiConfig inherited = ai_user_config();
    auto resolved = ai::resolve_ai_config_over(projectDir_, inherited);
    aiProj_.dir = projectDir_;
    aiProj_.atMs = now;
    if (resolved) {
        aiProj_.have = true;
        aiProj_.error.reset();
        aiProj_.resolved = std::move(*resolved);
    } else {
        aiProj_.have = false;
        aiProj_.error = resolved.error();
    }
    return aiProj_;
}

ai::AiConfig Editor::ai_window_config() {
    if (ai_project_open()) {
        const AiProjectUi& p = ai_project_refresh();
        if (p.have) return p.resolved.config;
    }
    return ai_user_config();
}

bool Editor::ai_project_locked() {
    if (!ai_project_open()) return false;
    const AiProjectUi& p = ai_project_refresh();
    if (!p.have) return true;  // the project's file was accepted and cannot be used now: fix or delete it first
    return p.resolved.pendingTrust && p.resolved.fileHash != p.ignoredHash;
}

std::string Editor::ai_project_settings_path() const {
    return projectDir_.empty() ? std::string() : utf8_string(utf8_path(projectDir_) / ".factoria" / "ai" / "settings.json");
}

bool Editor::ai_project_replace_allowed(const char* from) {
    if (!ai_project_open()) return true;
    const AiProjectUi& p = ai_project_refresh();
    if (!p.have || !p.resolved.pendingTrust || p.resolved.fileHash != p.ignoredHash) return true;  // nothing of the project's is replaced
    if (aiProj_.replaceOk) return true;
    aiProj_.replaceAsk = true;
    aiProj_.askFrom = from;
    return false;
}

bool Editor::ai_project_save_retry(const char* from) {
    if (aiProj_.retryFrom.empty() || aiProj_.retryFrom != from) return false;
    aiProj_.retryFrom.clear();
    return true;
}

Result<void> Editor::ai_project_keep_replaced_copy() {
    const AiProjectUi& p = ai_project_refresh();
    if (!p.have || !p.resolved.pendingTrust || p.resolved.fileHash != p.ignoredHash) return {};  // nothing of the project's is replaced
    // The file that came with the project is kept next to it: the user ignored it, never accepted it, and Save now replaces it.
    if (!aiProj_.replaceOk) {
        return Error{"Saving here replaces the AI settings file that came with this project.",
                     "Press Save again and confirm, or Accept the file first."};
    }
    const std::string file = ai_project_settings_path();
    const std::string copy = utf8_string(utf8_path(file).parent_path() / "settings.replaced.json");
    auto bytes = fs::read_bytes(file);
    Result<void> kept = bytes ? fs::write_bytes(copy, bytes->data(), bytes->size()) : Result<void>(bytes.error());
    if (!kept) {
        aiProj_.replaceOk = false;
        return Error{"Cannot keep a copy of the file that Save would replace: " + kept.error().message,
                     "Nothing was changed. Free the folder " + utf8_string(utf8_path(file).parent_path()) + " or Delete the file instead."};
    }
    return {};
}

Result<void> Editor::ai_project_save(const Json& overrides) {
    const ai::AiConfig user = ai_user_config();
    const AiProjectUi& p = ai_project_refresh();
    const bool replacing = p.have && p.resolved.pendingTrust && p.resolved.fileHash == p.ignoredHash;
    if (auto kept = ai_project_keep_replaced_copy(); !kept) return kept;
    auto saved = ai::save_project_settings(projectDir_, overrides, user.sourcePath, ai::system_env(), true);
    aiProj_.replaceOk = false;
    if (saved && replacing) aiProj_.ignoredHash.clear();
    ai_project_invalidate();
    return saved;
}

void Editor::ai_project_delete_file() {
    const std::string file = ai_project_settings_path();
    const ai::AiConfig user = ai_user_config();
    std::error_code ec;
    std::filesystem::remove(utf8_path(file), ec);
    aiProj_.ignoredHash.clear();
    aiProj_.actionError.clear();
    if (ec) {
        aiProj_.actionError = "Cannot delete " + file + ": " + ec.message();
    } else if (auto forgot = ai::forget_project_ai_settings_trust(ai::extensions_trust_path(
                   user.sourcePath.empty() ? ai::default_config_path() : user.sourcePath), projectDir_); !forgot) {
        aiProj_.actionError = "Deleted the file, but its acceptance could not be forgotten: " + forgot.error().to_string();
    }
    ai_project_invalidate();
    aiRolesOpen_ = true;
    aiRolesKeepEdits_ = false;  // deleting the file is a way back to the defaults: the roles start from them again
    if (!ec && aiSettings_.loaded) ai_settings_load(ai_user_config(), false, true);
}

Result<void> Editor::ai_project_reset(const std::string& pointer) {
    const ai::AiConfig user = ai_user_config();
    auto done = ai::reset_project_setting(projectDir_, pointer, user.sourcePath);
    ai_project_invalidate();
    return done;
}

Result<void> Editor::ai_project_after_defaults(const ai::AiConfig& wanted) {
    if (!ai_project_open()) return {};
    ai_project_invalidate();
    const AiProjectUi& p = ai_project_refresh();
    if (!p.have || !p.resolved.fileExists || !p.resolved.applied) return {};  // nothing of this project's to keep in step
    return ai_project_save(ai::project_overrides_from(wanted, p.resolved.inherited));
}

Result<void> Editor::ai_user_config_reload() {
    std::string path;
    {
        std::lock_guard<std::mutex> lock(aiMu_);
        path = aiConfig_.sourcePath;
    }
    if (path.empty()) path = ai::default_config_path();
    auto loaded = ai::load_config(path);
    {
        std::lock_guard<std::mutex> lock(aiMu_);
        if (loaded) aiConfig_ = *loaded;
        aiConfigError_ = loaded ? std::string() : loaded.error().to_string();
    }
    ai_project_invalidate();
    if (!loaded) return loaded.error();
    return {};
}

void Editor::ai_settings_changed_elsewhere() {
    const bool project = aiProjectFileChanged_.exchange(false);
    bool user = false;
    if (aiUserFileChanged_.load() && !aiDetecting_.load()) {  // a detection that is running reads the file as it was: ask again next frame
        aiUserFileChanged_ = false;
        user = true;
    }
    if (!project && !user) return;
    if (user) {
        (void)ai_user_config_reload();
        ai_refresh_providers();
    }
    ai_project_invalidate();
    // The window shows what the files say now; what the person had typed and not saved stays, on top of it.
    if (ai_settings_reload_keeping_edits(user)) {
        notify("The AI settings changed on disk (an AI agent, an MCP client or another program). The AI settings window shows the new values "
               "and keeps the rows you had changed: Save writes them over the new ones.");
    }
}

void Editor::ai_project_accept() {
    const AiProjectUi& p = ai_project_refresh();
    if (!p.have || !p.resolved.pendingTrust) return;
    const std::string hash = p.resolved.fileHash;  // what was shown: a file that changed since is refused
    const ai::AiConfig user = ai_user_config();
    auto accepted = ai::accept_project_settings(projectDir_, hash, user.sourcePath);
    ai_project_invalidate();
    if (!accepted) {
        aiProj_.actionError = accepted.error().to_string();
        return;
    }
    aiProj_.actionError.clear();
    aiProj_.ignoredHash.clear();
    // The window shows the values the file now sets; a row the person had changed before accepting stays as they typed it.
    const bool kept = ai_settings_reload_keeping_edits(false);
    notify(kept ? "This project's AI settings accepted. The next message uses them. The rows you had changed in the window stay as you set "
                  "them: Save writes them over the file's values."
                : "This project's AI settings accepted. The next message uses them.");
}

void Editor::draw_ai_project_banner() {
    const std::string userPath = [&] {
        const std::string p = ai_user_config().sourcePath;
        return p.empty() ? ai::default_config_path() : p;
    }();
    if (!ai_project_open()) {
        ImGui::TextDisabled("No project is open: this window edits your defaults (%s). Every project starts from them.", userPath.c_str());
        return;
    }
    // Copy what is needed: Accept / Ignore / Delete below invalidate the resolution (aiProj_ itself stays valid).
    const AiProjectUi& p = ai_project_refresh();
    const std::string file = ai_project_settings_path();
    const float line = ImGui::GetTextLineHeightWithSpacing();
    auto delete_file = [&] { aiProj_.deleteAsk = true; };  // the popup asks (draw_ai_project_popups)

    if (!p.have) {  // the file was accepted before and no longer resolves (for example ai.json changed under it)
        ImGui::PushStyleColor(ImGuiCol_Text, kStatusFailed);
        ImGui::TextWrapped("This project's AI settings file cannot be used: %s", ai::escape_control_chars(p.error ? p.error->message : "").c_str());
        ImGui::PopStyleColor();
        if (p.error && !p.error->hint.empty()) ImGui::TextWrapped("%s", ai::escape_control_chars(p.error->hint).c_str());
        ImGui::TextDisabled("Until it is fixed the project runs, and this window shows, your defaults. %s", file.c_str());
        if (ImGui::Button("Delete the project's AI settings file")) delete_file();
        at_track("aiset:project:delete");
        ImGui::SetItemTooltip("Removes %s. Your defaults (ai.json) are not touched.", file.c_str());
    } else {
        const ai::ResolvedAiConfig& r = p.resolved;
        ImGui::TextWrapped("Editing the AI settings of this project. A row says whether its value is set by this project or comes from your defaults (%s).",
                           userPath.c_str());
        const bool ignored = r.pendingTrust && r.fileHash == p.ignoredHash;
        if (r.pendingTrust && !ignored) {
            ImGui::PushStyleColor(ImGuiCol_ChildBg, ImVec4(0.30f, 0.22f, 0.08f, 1));
            const float listH = line * static_cast<float>(std::clamp<int>(static_cast<int>(r.pending.size()), 1, 6)) + 6.0f;
            // As tall as its text needs, but never more than about half of what is left of the window: on a small display (1024x642) the
            // Roles and Assets tabs below stay reachable, and the box scrolls to the file's changes and the buttons.
            const float maxH = std::max(line * 6.0f, ImGui::GetContentRegionAvail().y * 0.5f);
            ImGui::SetNextWindowSizeConstraints(ImVec2(0, 0), ImVec2(FLT_MAX, maxH));
            ImGui::BeginChild("##aiprojpending", ImVec2(0, 0), ImGuiChildFlags_Borders | ImGuiChildFlags_AutoResizeY);
            ImGui::TextColored(kStatusWarn, "This project's AI settings file is waiting for your approval");
            ImGui::TextWrapped("%s came with the project (or changed since you last accepted it). Until you accept it the project uses your own "
                               "settings; it changes nothing.", file.c_str());
            if (r.invalidError) {
                ImGui::PushStyleColor(ImGuiCol_Text, kStatusFailed);
                ImGui::TextWrapped("It cannot be accepted: %s", ai::escape_control_chars(r.invalidError->message).c_str());
                ImGui::PopStyleColor();
                if (!r.invalidError->hint.empty()) ImGui::TextWrapped("%s", ai::escape_control_chars(r.invalidError->hint).c_str());
            } else if (r.pending.empty()) {
                ImGui::TextDisabled("It sets nothing that differs from your defaults.");
            } else {
                ImGui::TextWrapped("Accepting lets it change:");
                ImGui::BeginChild("##aiprojpendinglist", ImVec2(0, listH), ImGuiChildFlags_None);
                for (const ai::SettingChange& c : r.pending) ImGui::TextWrapped("%s", ai::escape_control_chars(c.text()).c_str());
                ImGui::EndChild();
            }
            if (!r.invalidError) {
                if (ImGui::Button("Accept")) ai_project_accept();
                at_track("aiset:project:accept");
                ImGui::SetItemTooltip("Trust this file as it is: its values apply from the next message. It is checked against the file's hash, so a\n"
                                      "file that changes afterwards waits for you again.");
                fit_same_line("Ignore");
            }
            if (ImGui::Button("Ignore")) aiProj_.ignoredHash = r.fileHash;
            at_track("aiset:project:ignore");
            ImGui::SetItemTooltip("Leave the file as it is and keep working with your own settings. Saving here replaces it with what you choose.");
            fit_same_line("Delete the file");
            if (ImGui::Button("Delete the file")) delete_file();
            at_track("aiset:project:delete");
            ImGui::SetItemTooltip("Removes %s. Your defaults (ai.json) are not touched.", file.c_str());
            ImGui::EndChild();
            ImGui::PopStyleColor();
        } else if (ignored) {
            ImGui::TextColored(kStatusWarn, "This project's AI settings file is not accepted and has no effect (ignored).");
            ImGui::SameLine();
            if (ImGui::SmallButton("Review it")) aiProj_.ignoredHash.clear();
            at_track("aiset:project:review");
            ImGui::SetItemTooltip("Show what the file would change, with Accept.");
        } else if (r.applied) {
            const std::size_t n = std::ranges::count_if(r.sources, [](const auto& kv) { return kv.second == ai::SettingSource::Project; });
            ImGui::TextDisabled("%zu value%s set by this project (%s).", n, n == 1 ? "" : "s", file.c_str());
        } else if (!r.fileExists) {
            ImGui::TextDisabled("This project has no AI settings file yet: everything comes from your defaults. Save writes it (%s).", file.c_str());
        }
        // The warnings of the resolution (M61.1). The pending box above already shows the error of a file that cannot be accepted.
        std::vector<std::string> warnings;
        for (const std::string& w : r.config.warnings) {
            const bool shownAbove = r.pendingTrust && !ignored && r.invalidError && w.find(r.invalidError->message) != std::string::npos;
            if (!shownAbove) warnings.push_back(w);
        }
        for (std::size_t i = 0; i < warnings.size() && i < 5; ++i) {
            ImGui::PushStyleColor(ImGuiCol_Text, kStatusWarn);
            ImGui::TextWrapped("%s", ai::escape_control_chars(warnings[i]).c_str());
            ImGui::PopStyleColor();
        }
        if (warnings.size() > 5) ImGui::TextDisabled("... and %zu more warning(s): factoria ai doctor lists them.", warnings.size() - 5);
    }
    if (!aiProj_.actionError.empty()) {
        ImGui::PushStyleColor(ImGuiCol_Text, kStatusFailed);
        ImGui::TextWrapped("%s", aiProj_.actionError.c_str());
        ImGui::PopStyleColor();
    }
    draw_ai_project_popups();
}

// The two confirmations of the project's file. Both are opened here, at the ID level of the window that draws the banner, from the flags
// the buttons in the tabs (child windows) raised. The text names the file relative to the project so it wraps at any window size.
void Editor::draw_ai_project_popups() {
    if (uiFrame_ != aiProj_.okFrame) {  // the confirmation is for the Save pressed again in the same frame (tabs draw after the banner)
        aiProj_.replaceOk = false;
        aiProj_.retryFrom.clear();
    }
    if (aiProj_.replaceAsk) {
        ImGui::OpenPopup("Replace the project's AI settings file?##aiprojreplace");
        aiProj_.replaceAsk = false;
    }
    if (aiProj_.deleteAsk) {
        ImGui::OpenPopup("Delete the project's AI settings file?##aiprojdelete");
        aiProj_.deleteAsk = false;
    }
    const float wrap = std::min(ImGui::GetFontSize() * 30, ImGui::GetMainViewport()->WorkSize.x - 80.0f);
    if (ImGui::BeginPopupModal("Replace the project's AI settings file?##aiprojreplace", nullptr, ImGuiWindowFlags_AlwaysAutoResize)) {
        ImGui::PushTextWrapPos(wrap);
        ImGui::TextWrapped("Save replaces the AI settings file that came with this project (.factoria/ai/settings.json). You did not accept it, "
                           "so it has had no effect here.");
        ImGui::TextWrapped("A copy is kept as .factoria/ai/settings.replaced.json. Your defaults (ai.json) are not touched.");
        ImGui::PopTextWrapPos();
        ImGui::Spacing();
        if (ImGui::Button("Replace it")) {
            aiProj_.replaceOk = true;
            aiProj_.okFrame = uiFrame_;
            aiProj_.retryFrom = aiProj_.askFrom;  // the Save that asked runs again and now goes through
            ImGui::CloseCurrentPopup();
        }
        at_track("aiset:project:replace-ok");
        ImGui::SameLine();
        if (ImGui::Button("Cancel") || ImGui::IsKeyPressed(ImGuiKey_Escape, false)) ImGui::CloseCurrentPopup();
        at_track("aiset:project:replace-cancel");
        ImGui::EndPopup();
    }
    if (ImGui::BeginPopupModal("Delete the project's AI settings file?##aiprojdelete", nullptr, ImGuiWindowFlags_AlwaysAutoResize)) {
        ImGui::PushTextWrapPos(wrap);
        ImGui::TextWrapped("This removes .factoria/ai/settings.json from the project and forgets that you accepted it. Your defaults "
                           "(ai.json) are not touched. There is no copy of the file.");
        ImGui::PopTextWrapPos();
        ImGui::Spacing();
        if (ImGui::Button("Delete the file")) {
            ai_project_delete_file();
            ImGui::CloseCurrentPopup();
        }
        at_track("aiset:project:delete-ok");
        ImGui::SameLine();
        if (ImGui::Button("Cancel") || ImGui::IsKeyPressed(ImGuiKey_Escape, false)) ImGui::CloseCurrentPopup();
        at_track("aiset:project:delete-cancel");
        ImGui::EndPopup();
    }
}

}  // namespace fa::editor
