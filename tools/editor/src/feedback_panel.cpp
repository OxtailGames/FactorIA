// Engine Feedback panel: view/filter/add/update entries of the project's ENGINE_FEEDBACK.json
// through the fa_tooling feedback API.
#include <algorithm>
#include <functional>

#include "editor_internal.h"
#include "fa/ai/commands.h"
#include "fa/core/strings.h"
#include "fa/tooling/feedback_check.h"

namespace fa::editor {

namespace {
// The text for an error of a change to the feedback file. A lock another program holds is waited for 0.3 s at most (the UI thread
// does not stall), so the text says to try again.
std::string feedback_busy_text(const Error& e) {
    std::string text = e.to_string();
    if (e.message.find("Another FactorIA process") != std::string::npos) text += " Nothing was changed: try again in a moment.";
    return text;
}

// `onItem` (optional) is told each entry of the open list after it is drawn (the autotest finds them by it).
bool combo_strings(const char* label, int* cur, const std::vector<std::string>& items, bool withAny,
                   const std::function<void(const std::string&)>& onItem = {}) {
    // index 0 = "any" when withAny
    const int total = int(items.size()) + (withAny ? 1 : 0);
    *cur = std::clamp(*cur, 0, std::max(0, total - 1));
    std::string preview = withAny ? (*cur == 0 ? "any" : items[size_t(*cur - 1)]) : items[size_t(*cur)];
    bool changed = false;
    if (ImGui::BeginCombo(label, preview.c_str())) {
        for (int i = 0; i < total; ++i) {
            std::string name = withAny ? (i == 0 ? "any" : items[size_t(i - 1)]) : items[size_t(i)];
            if (ImGui::Selectable(name.c_str(), i == *cur)) { *cur = i; changed = true; }
            if (onItem) onItem(name);
        }
        ImGui::EndCombo();
    }
    return changed;
}

// The colour of a status word in the table and the detail: rejected stands out (somebody decided the gap is not one).
ImVec4 status_color(const std::string& s) {
    if (s == "rejected") return ImVec4(1, 0.55f, 0.4f, 1);
    if (s == "fixed-in-engine") return ImVec4(0.5f, 0.85f, 0.5f, 1);
    if (s == "open") return ImVec4(0.85f, 0.85f, 0.85f, 1);
    return ImVec4(0.65f, 0.7f, 0.8f, 1);
}

// Who decided the status, in words: "the engine" (the check before filing found the gap exists), "the engine developers" (they
// rejected the shared report), "you" (a person or an AI through the commands).
std::string status_author_text(const Json& en) {
    const std::string by = en.value("statusBy", std::string());
    if (by == "engine") return "the engine";
    if (by == "developer") return "the engine developers";
    return "you";
}

// What the table row and the detail say about a closed entry's reason: "rejected by the engine: <reason>".
std::string status_reason_text(const Json& en) {
    const std::string status = en.value("status", std::string("open")), reason = en.value("statusReason", std::string());
    if (reason.empty()) return {};
    return status + " by " + status_author_text(en) + ": " + reason;
}

ImVec4 severity_color(const std::string& s) {
    if (s == "blocker") return ImVec4(1, 0.4f, 0.38f, 1);
    if (s == "major") return ImVec4(1, 0.7f, 0.3f, 1);
    if (s == "minor") return ImVec4(0.9f, 0.9f, 0.5f, 1);
    return ImVec4(0.65f, 0.7f, 0.8f, 1);
}
}  // namespace

void Editor::draw_feedback_panel() {
    const std::string path = fs::join(projectDir_, engine_->project().feedbackFile);
    // (Re)load when the file changed on disk (AIs append to it while the editor is open). Entries that are not open are moved to
    // the archive file by feedback_share_tick as soon as it sees them, so what is listed here is what is still open.
    // A file's time moves in steps (about 15 ms on Windows): a write right after a read can keep the time the read saw, so
    // after a change the file is read once more on the next poll, whatever its time says.
    const std::string archivePath = feedback_archive_path(path);
    if (time_ - feedbackPolled_ > 1.0) {
        feedbackPolled_ = time_;
        const bool exists = fs::exists(engine_->project().feedbackFile);
        const std::int64_t mt = exists ? fs::modified_time(engine_->project().feedbackFile) : 0;
        const bool archiveExists = fs::exists(archivePath);
        const std::int64_t amt = archiveExists ? fs::modified_time(archivePath) : 0;
        if (mt != feedbackMtime_ || amt != fbArchiveMtime_ || feedbackRecheck_) {
            feedbackRecheck_ = mt != feedbackMtime_ || amt != fbArchiveMtime_;
            feedbackMtime_ = mt;
            fbArchiveMtime_ = amt;
            if (!exists) {
                feedbackDoc_ = Json();
                feedbackError_.clear();
            } else if (auto r = load_feedback(path)) {
                feedbackDoc_ = *r;
                feedbackError_.clear();
            } else {
                feedbackError_ = r.error().to_string();
            }
            fbArchive_ = Json();
            if (archiveExists)
                if (auto a = load_feedback(archivePath)) fbArchive_ = *a;
        }
    }
    // (Read above, before Begin, so the detail windows stay current while the panel's tab is hidden.)
    if (!ImGui::Begin("Engine Feedback")) { ImGui::End(); return; }
    ImGui::TextDisabled("%s", engine_->project().feedbackFile.c_str());
    ImGui::SetItemTooltip("What the engine lacked, recorded by you and by AIs");
    ImGui::SameLine();
    ImGui::TextDisabled("sharing: %s", share_.mode == ShareMode::Always ? "always" : share_.mode == ShareMode::Ask ? "ask me each time"
                                                                                 : share_.mode == ShareMode::Never ? "never" : "not chosen yet");
    ImGui::SetItemTooltip("Change it in File > Feedback Settings");
    if (!feedbackError_.empty()) ImGui::TextColored(ImVec4(1, 0.45f, 0.4f, 1), "%s", feedbackError_.c_str());

    // The two things a person does here: write down a gap, and send the open ones to the engine developers.
    if (ImGui::Button("Add feedback")) {
        fbAddOpen_ = true;
        fbMessage_.clear();
    }
    at_track("feedback:add");
    ImGui::SetItemTooltip("Write down something the engine lacked");
    fit_same_line("Send feedback");  // the row wraps in a narrow window instead of running out of it
    {
        const bool never = share_.mode == ShareMode::Never;
        const bool unavailable = !share_.sharingAvailable;
        ImGui::BeginDisabled(never || unavailable || feedbackDoc_.is_null());
        if (ImGui::Button("Send feedback")) open_send_window();
        at_track("feedback:send", !never && !unavailable && !feedbackDoc_.is_null());
        ImGui::EndDisabled();
        ImGui::SetItemTooltip("%s", unavailable ? "Sharing is not available in this build (File > Feedback Settings says why)."
                                      : never   ? "Sharing is off. Turn it on in File > Feedback Settings."
                                                : "Choose which open entries go to the engine developers, and read exactly what is sent");
    }
    fit_same_line("Looking back...");  // the wider of the two labels the button has
    {
        bool running;
        {
            std::lock_guard<std::mutex> lock(fbRetro_->mu);
            running = fbRetro_->running;
        }
        ImGui::BeginDisabled(running || feedbackDoc_.is_null() || projectDir_.empty());
        if (ImGui::Button(running ? "Looking back..." : "Retrospective")) feedback_start_retrospective();
        at_track("feedback:retrospective", !running && !feedbackDoc_.is_null() && !projectDir_.empty());
        ImGui::EndDisabled();
        ImGui::SetItemTooltip("Look back at this project's recorded AI runs: where they wasted steps, minutes or tokens. One short call of the fast role "
                              "files at most three efficiency entries here (nothing is sent anywhere). It costs a model call.");
    }
    fit_same_line("[] closed");  // a checkbox: its box counts as one more character
    ImGui::Checkbox("closed", &fbShowClosed_);
    at_track("feedback:closed");
    ImGui::SetItemTooltip("Also list the closed entries: fixed in the engine, won't fix, duplicate and rejected. They live in %s.",
                          fs::filename(archivePath).c_str());
    if (!fbMessage_.empty() && !fbAddOpen_) {
        // On its own line and wrapped: a retrospective's answer is a sentence or two, longer than the room left beside the buttons.
        ImGui::PushStyleColor(ImGuiCol_Text, ImGui::GetStyleColorVec4(ImGuiCol_TextDisabled));
        ImGui::TextWrapped("%s", fbMessage_.c_str());
        ImGui::PopStyleColor();
        at_track("feedback:message");
    }
    draw_feedback_add_window();
    feedback_apply_retrospective();
    {  // what the open efficiency entries say a fix would save, per game (measured from the transcripts, never guessed)
        int n = 0;
        double minutes = 0;
        double tokens = 0;
        if (feedbackDoc_.is_object() && feedbackDoc_.contains("entries") && feedbackDoc_["entries"].is_array())
            for (const Json& e : feedbackDoc_["entries"]) {
                if (e.value("kind", std::string()) != "efficiency" || e.value("status", std::string("open")) != "open") continue;
                const Json* sv = e.contains("saving") && e["saving"].is_object() ? &e["saving"] : nullptr;
                if (!sv) continue;
                ++n;
                minutes += sv->value("minutes", 0.0);
                tokens += sv->value("tokens", 0.0);
            }
        if (n > 0) {
            ImGui::PushStyleColor(ImGuiCol_Text, ImGui::GetStyleColorVec4(ImGuiCol_TextDisabled));
            ImGui::TextWrapped("Efficiency: %d open entr%s, fixes would save about %.0f min and %.0fk tokens per game", n, n == 1 ? "y" : "ies", minutes,
                               tokens / 1000.0);
            ImGui::PopStyleColor();
            ImGui::SetItemTooltip("Added up over the open efficiency entries: what each fix would save, measured from the AI sessions' transcripts.");
            at_track("feedback:saving");
        }
    }

    if (feedbackDoc_.is_null()) {
        ImGui::TextWrapped("No feedback file yet.");
        if (ImGui::Button("Create ENGINE_FEEDBACK.json")) {
            const ShareWaitCap shortWait(0.3);  // the UI thread never waits seconds for another program's lock
            if (auto r = create_feedback_file(path, projectName_); !r) notify(feedback_busy_text(r.error()), 2);
            feedbackMtime_ = INT64_MIN;
            feedbackPolled_ = -10;
        }
        ImGui::End();
        return;
    }

    // Filters.
    FeedbackFilter filter;
    const float w3 = (ImGui::GetContentRegionAvail().x - 2 * ImGui::GetStyle().ItemSpacing.x) / 3.0f;
    ImGui::SetNextItemWidth(w3);
    combo_strings("##fs", &fbStatus_, feedback_statuses(), true);
    ImGui::SetItemTooltip("Filter by status");
    ImGui::SameLine();
    ImGui::SetNextItemWidth(w3);
    combo_strings("##fc", &fbCategory_, feedback_categories(), true);
    ImGui::SetItemTooltip("Filter by category");
    ImGui::SameLine();
    ImGui::SetNextItemWidth(-FLT_MIN);
    combo_strings("##fv", &fbSeverity_, feedback_severities(), true);
    ImGui::SetItemTooltip("Filter by severity");
    if (fbStatus_ > 0) filter.status = feedback_statuses()[size_t(fbStatus_ - 1)];
    if (fbCategory_ > 0) filter.category = feedback_categories()[size_t(fbCategory_ - 1)];
    if (fbSeverity_ > 0) filter.severity = feedback_severities()[size_t(fbSeverity_ - 1)];

    Json entries = list_feedback(feedbackDoc_, filter);
    // Closed entries are in the archive: listed when "closed" is ticked, or when the status filter asks for one of them.
    if (fbShowClosed_ || (!filter.status.empty() && filter.status != "open"))
        for (const Json& e : list_feedback(fbArchive_, filter)) entries.push_back(e);
    // The panel keeps its size whatever an entry says: this area never scrolls or grows. Only the entries table and the
    // detail of the selected entry (their own children) scroll.
    ImGui::BeginChild("##fbbody", ImVec2(0, 0), ImGuiChildFlags_None, ImGuiWindowFlags_NoScrollbar | ImGuiWindowFlags_NoScrollWithMouse);
    // The table takes the room its rows need (header and one line per entry) up to two thirds of the panel and scrolls inside when
    // there are more; the detail below gets the rest, at least a few lines.
    const float bodyH = ImGui::GetContentRegionAvail().y;
    const float lineH = ImGui::GetTextLineHeightWithSpacing();
    const float gap = ImGui::GetStyle().ItemSpacing.y;
    // In a short panel (a small display) both give way so the body never overflows: the table keeps at least half of it.
    const float tableMin = std::min(lineH * 3.0f + 8.0f, bodyH * 0.5f);
    const float detailMin = std::min(bodyH * 0.45f, lineH * 8.0f);
    const float tableMax = std::max(tableMin, bodyH - detailMin - gap);
    const float tableH = std::clamp(lineH * float(entries.size() + 1) + 10.0f, tableMin, tableMax);
    if (ImGui::BeginTable("##fbt", 5, ImGuiTableFlags_RowBg | ImGuiTableFlags_ScrollY | ImGuiTableFlags_SizingStretchProp | ImGuiTableFlags_BordersInnerV,
                          ImVec2(0, tableH))) {
        ImGui::TableSetupScrollFreeze(0, 1);
        ImGui::TableSetupColumn("id", ImGuiTableColumnFlags_WidthFixed, 66);
        ImGui::TableSetupColumn("severity", ImGuiTableColumnFlags_WidthFixed, 66);
        ImGui::TableSetupColumn("status", ImGuiTableColumnFlags_WidthFixed, 96);
        ImGui::TableSetupColumn("share", ImGuiTableColumnFlags_WidthFixed, 68);
        ImGui::TableSetupColumn("title", ImGuiTableColumnFlags_WidthStretch);
        ImGui::TableHeadersRow();
        for (const auto& en : entries) {
            const std::string id = en.value("id", "");
            ImGui::TableNextRow();
            ImGui::TableSetColumnIndex(0);
            if (ImGui::Selectable(id.c_str(), id == fbSelected_, ImGuiSelectableFlags_SpanAllColumns)) fbSelected_ = id;
            // A double click opens the entry in a window of its own (every field, resizable, with its actions).
            if (ImGui::IsItemHovered() && ImGui::IsMouseDoubleClicked(ImGuiMouseButton_Left)) {
                if (std::find(fbWindows_.begin(), fbWindows_.end(), id) == fbWindows_.end()) fbWindows_.push_back(id);
                else ImGui::SetWindowFocus(("Feedback " + id + "###fbwin-" + id).c_str());
            }
            {  // the row spans every column: the autotest clicks it where the id is (the centre may lie in another column's clip)
                const ImVec2 a = ImGui::GetItemRectMin(), b = ImGui::GetItemRectMax();
                at_track_at("feedback:row:" + id, Vec2{a.x + 24.0f, (a.y + b.y) * 0.5f});
            }
            ImGui::TableSetColumnIndex(1);
            ImGui::TextColored(severity_color(en.value("severity", "")), "%s", en.value("severity", "").c_str());
            ImGui::TableSetColumnIndex(2);
            {
                const std::string status = en.value("status", "");
                const std::string why = status_reason_text(en);
                // A closed entry that carries a reason is marked with "*": hover for who closed it and why.
                ImGui::TextColored(status_color(status), "%s%s", status.c_str(), why.empty() ? "" : " *");
                if (!why.empty() && ImGui::IsItemHovered()) {
                    ImGui::PushTextWrapPos(ImGui::GetFontSize() * 28);
                    ImGui::SetTooltip("%s", why.c_str());
                    ImGui::PopTextWrapPos();
                }
                at_track("feedback:status:" + id);
            }
            ImGui::TableSetColumnIndex(3);
            draw_feedback_share_cell(en);
            ImGui::TableSetColumnIndex(4);
            ImGui::TextUnformatted(en.value("title", "").c_str());
            if (ImGui::IsItemHovered()) ImGui::SetTooltip("%s\noccurrences: %d", en.value("title", "").c_str(), en.value("occurrences", 1));
        }
        ImGui::EndTable();
    }
    at_track_at("feedback:table", Vec2{ImGui::GetItemRectMin().x + 20.0f, ImGui::GetItemRectMin().y + ImGui::GetItemRectSize().y * 0.5f});
    // Detail of the selected entry: a child that takes what the table leaves, and scrolls by itself. It only reads; the status is
    // the one thing it changes.
    ImGui::BeginChild("##fbdetail", ImVec2(0, 0), ImGuiChildFlags_Borders);
    {  // over the detail's scrollbar, not over a text box: where the autotest turns the wheel
        const ImVec2 p = ImGui::GetWindowPos(), z = ImGui::GetWindowSize();
        at_track_at("feedback:detail", Vec2{p.x + z.x - 4.0f, p.y + z.y * 0.5f});
    }
    for (const auto& en : entries) {
        if (en.value("id", "") != fbSelected_) continue;
        draw_feedback_detail(en, path, false);
        break;
    }
    ImGui::EndChild();
    ImGui::EndChild();
    ImGui::End();
}

void Editor::feedback_start_retrospective() {
    auto job = fbRetro_;
    {
        std::lock_guard<std::mutex> lock(job->mu);
        if (job->running || projectDir_.empty()) return;
        job->running = true;
        job->finished = false;
        job->cancel = false;
        job->dir = projectDir_;
    }
    fbMessage_ = "Looking back at the AI runs of this project...";
    if (fbRetroThread_.joinable()) fbRetroThread_.join();
    auto reg = std::make_shared<CommandRegistry>();
    ai::AiCommandOptions ao;
    ao.loadConfig = [this]() -> Result<ai::AiConfig> { return ai_project_config(true); };
    ao.projectDir = [dir = projectDir_] { return dir; };
    ao.providerFactory = aiFactory_;
    ao.cancel = &job->cancel;
    ai::register_ai_commands(*reg, ao);
    fbRetroThread_ = std::thread([job, reg] {
        const CommandResult res = reg->call("ai.retrospective", Json::object());
        std::lock_guard<std::mutex> lock(job->mu);
        job->ok = res.ok;
        job->result = res.ok ? res.result : Json();
        job->message = res.ok ? std::string() : res.error.value("message", std::string("The retrospective failed.")) + " " + res.error.value("hint", std::string());
        job->running = false;
        job->finished = true;
    });
}

void Editor::feedback_apply_retrospective() {
    auto job = fbRetro_;
    bool ok;
    Json result;
    std::string message, dir;
    {
        std::lock_guard<std::mutex> lock(job->mu);
        if (!job->finished) return;
        job->finished = false;
        dir = job->dir;
        ok = job->ok;
        result = job->result;
        message = job->message;
    }
    if (dir != projectDir_) return;  // another project is open now: this answer is about the one that was closed
    if (!ok) {
        fbMessage_ = message.rfind("cancelled", 0) == 0 ? "Retrospective stopped: nothing was filed." : "Retrospective failed: " + message;
        return;
    }
    std::string text = result.value("note", std::string());
    const double cost = result.value("costUsd", 0.0);
    if (cost > 0) {
        char buf[48];
        std::snprintf(buf, sizeof buf, " (the model call cost $%.4f)", cost);
        text += buf;
    }
    fbMessage_ = text;
    if (!result.value("filed", Json::array()).empty()) feedback_reload_soon();
}

const Json* Editor::feedback_entry(const std::string& id) const {
    for (const Json* doc : {&feedbackDoc_, &fbArchive_}) {
        if (!doc->is_object() || !doc->contains("entries") || !(*doc)["entries"].is_array()) continue;
        for (const Json& e : (*doc)["entries"])
            if (e.value("id", std::string()) == id) return &e;
    }
    return nullptr;
}

// After this editor wrote the file: both files are read at the next poll, and the share tick runs at once (the archive move).
void Editor::feedback_reload_soon() {
    feedbackMtime_ = INT64_MIN;
    fbArchiveMtime_ = INT64_MIN;
    feedbackPolled_ = -10;
    share_.tickAt = -10;
    share_.docStamp = INT64_MIN;
}

// The status of the entry (a combo; rejected asks for the reason first), Copy (the whole entry as JSON on the clipboard) and Delete
// (a closed or developer-refused entry, after a confirmation).
void Editor::draw_feedback_actions(const Json& en, const std::string& path) {
    const std::string id = en.value("id", std::string());
    const auto& st = feedback_statuses();
    const std::string curStatus = en.value("status", "open");
    int cur = 0;
    for (size_t i = 0; i < st.size(); ++i)
        if (st[i] == curStatus) cur = int(i);
    ImGui::SetNextItemWidth(160);
    if (combo_strings("status##detail", &cur, st, false, [this](const std::string& name) { at_track("feedback:status:item:" + name); }) &&
        st[size_t(cur)] != curStatus) {
        if (st[size_t(cur)] == "rejected") {
            // A rejection says why: the reason is what the person (or the AI that filed it) reads in the table later.
            fbAsk_ = FbAsk{id, "rejected", en.value("statusReason", std::string()), {}, true};
            ImGui::OpenPopup("Reject this entry?###fb-reject");
        } else {
            const ShareWaitCap shortWait(0.3);  // the UI thread never waits seconds for another program's lock
            if (auto r = update_feedback_file(path, id, st[size_t(cur)], ""); !r) {
                notify(feedback_busy_text(r.error()), 2);
            } else if (st[size_t(cur)] != "open") {
                notify(id + " is " + st[size_t(cur)] + ": it moves to the archive next to " + engine_->project().feedbackFile + ".", 0);
            }
            feedback_reload_soon();
        }
    }
    at_track("feedback:status");
    ImGui::SetItemTooltip("Change the status of this entry (saved immediately). An entry that is not open moves to the archive file. "
                          "Rejected asks why first.");
    ImGui::SameLine();
    if (ImGui::Button("Copy")) {
        ImGui::SetClipboardText(en.dump(2).c_str());
        notify("Copied " + id + " to the clipboard.", 0);
    }
    at_track("feedback:copy");
    ImGui::SetItemTooltip("Copy the whole entry (every field, as JSON) to the clipboard");
    ImGui::SameLine();
    std::string whyNot;
    const bool deletable = feedback_entry_deletable(en, &whyNot);
    ImGui::BeginDisabled(!deletable);
    if (ImGui::Button("Delete")) {
        fbAsk_ = FbAsk{id, "delete", {}, {}, true};
        ImGui::OpenPopup("Delete this entry?###fb-delete");
    }
    at_track("feedback:delete", deletable);
    ImGui::EndDisabled();
    ImGui::SetItemTooltip("%s", deletable ? "Delete this entry for good (asks first)" : whyNot.c_str());

    // The reason of a rejection.
    if (fbAsk_.open && fbAsk_.id == id && fbAsk_.status == "rejected") {
        ImGui::SetNextWindowPos(ImGui::GetMainViewport()->GetCenter(), ImGuiCond_Appearing, ImVec2(0.5f, 0.5f));
        if (ImGui::BeginPopupModal("Reject this entry?###fb-reject", nullptr, ImGuiWindowFlags_AlwaysAutoResize | ImGuiWindowFlags_NoSavedSettings)) {
            ImGui::PushTextWrapPos(ImGui::GetFontSize() * 30);
            ImGui::TextWrapped("%s: why is this not a gap in the engine? The reason stays with the entry and shows in the table.", id.c_str());
            ImGui::PopTextWrapPos();
            ImGui::InputTextMultiline("##fbreason", &fbAsk_.reason, ImVec2(ImGui::GetFontSize() * 30, ImGui::GetTextLineHeight() * 4 + 8));
            at_track("feedback:reason");
            const int chars = text_chars(fbAsk_.reason);
            ImGui::TextColored(chars > kFeedbackReasonMax ? ImVec4(1, 0.45f, 0.4f, 1) : ImVec4(0.6f, 0.6f, 0.6f, 1), "%d / %d characters", chars,
                               kFeedbackReasonMax);
            if (!fbAsk_.error.empty()) ImGui::TextColored(ImVec4(1, 0.45f, 0.4f, 1), "%s", fbAsk_.error.c_str());
            const bool ready = !sanitize_status_reason(fbAsk_.reason).empty() && chars <= kFeedbackReasonMax;
            ImGui::BeginDisabled(!ready);
            if (ImGui::Button("Reject", ImVec2(110, 0))) {
                const ShareWaitCap shortWait(0.3);  // the UI thread never waits seconds for another program's lock
                if (auto r = update_feedback_file(path, id, "rejected", "", "", fbAsk_.reason, "user"); !r) {
                    fbAsk_.error = feedback_busy_text(r.error());
                } else {
                    fbAsk_.open = false;
                    notify(id + " is rejected: it moves to the archive next to " + engine_->project().feedbackFile + ".", 0);
                    feedback_reload_soon();
                    ImGui::CloseCurrentPopup();
                }
            }
            at_track("feedback:reason:ok", ready);
            ImGui::EndDisabled();
            ImGui::SameLine();
            if (ImGui::Button("Cancel", ImVec2(110, 0))) {
                fbAsk_.open = false;
                ImGui::CloseCurrentPopup();
            }
            at_track("feedback:reason:cancel");
            ImGui::EndPopup();
        } else if (!ImGui::IsPopupOpen("Reject this entry?###fb-reject")) {
            fbAsk_.open = false;  // closed with Escape or by clicking away
        }
    }
    // The confirmation of a delete.
    if (fbAsk_.open && fbAsk_.id == id && fbAsk_.status == "delete") {
        ImGui::SetNextWindowPos(ImGui::GetMainViewport()->GetCenter(), ImGuiCond_Appearing, ImVec2(0.5f, 0.5f));
        if (ImGui::BeginPopupModal("Delete this entry?###fb-delete", nullptr, ImGuiWindowFlags_AlwaysAutoResize | ImGuiWindowFlags_NoSavedSettings)) {
            ImGui::PushTextWrapPos(ImGui::GetFontSize() * 30);
            ImGui::TextWrapped("Delete %s \"%s\" for good? It is removed from %s and its archive; that cannot be undone. Its id is not used "
                               "again, and what was already sent to the engine developers stays with them.",
                               id.c_str(), en.value("title", "").c_str(), engine_->project().feedbackFile.c_str());
            ImGui::PopTextWrapPos();
            if (!fbAsk_.error.empty()) ImGui::TextColored(ImVec4(1, 0.45f, 0.4f, 1), "%s", fbAsk_.error.c_str());
            if (ImGui::Button("Delete", ImVec2(110, 0))) {
                const ShareWaitCap shortWait(0.3);  // the command takes the sharing lock; the UI thread never waits seconds for it
                const CommandResult r = engine_->commands().call("feedback.delete", Json::object({{"id", id}}));
                if (!r.ok) {
                    fbAsk_.error = command_error_text(r.error);
                } else {
                    fbAsk_.open = false;
                    fbWindows_.erase(std::remove(fbWindows_.begin(), fbWindows_.end(), id), fbWindows_.end());
                    if (fbSelected_ == id) fbSelected_.clear();
                    notify("Deleted " + id + ".", 0);
                    feedback_reload_soon();
                    ImGui::CloseCurrentPopup();
                }
            }
            at_track("feedback:delete:ok");
            ImGui::SameLine();
            if (ImGui::Button("Cancel", ImVec2(110, 0))) {
                fbAsk_.open = false;
                ImGui::CloseCurrentPopup();
            }
            at_track("feedback:delete:cancel");
            ImGui::EndPopup();
        } else if (!ImGui::IsPopupOpen("Delete this entry?###fb-delete")) {
            fbAsk_.open = false;
        }
    }
}

// One entry: what the panel's detail area and an entry's window both show. The window shows every field; the inline one the
// ones a table row does not already tell.
void Editor::draw_feedback_detail(const Json& en, const std::string& path, bool inWindow) {
    ImGui::PushTextWrapPos(0);
    ImGui::TextColored(ImVec4(0.6f, 0.8f, 1, 1), "%s  [%s]  x%d", en.value("title", "").c_str(), en.value("category", "").c_str(), en.value("occurrences", 1));
    ImGui::PopTextWrapPos();
    auto field = [&](const char* label, const std::string& v, const char* track = nullptr) {
        if (v.empty()) return;
        ImGui::TextDisabled("%s", label);
        ImGui::TextWrapped("%s", v.c_str());
        if (track) at_track(track);
    };
    auto list_field = [&](const char* label, const Json& arr) {
        if (!arr.is_array() || arr.empty()) return;
        std::string text;
        for (const Json& v : arr) text += std::string(text.empty() ? "" : "\n") + (v.is_string() ? v.get<std::string>() : v.dump());
        field(label, text);
    };
    const std::string status = en.value("status", "open");
    if (status != "open") {
        ImGui::TextDisabled("status");
        ImGui::SameLine();
        ImGui::TextColored(status_color(status), "%s", status.c_str());
        const std::string reason = en.value("statusReason", std::string());
        if (!reason.empty()) {
            ImGui::TextDisabled("%s by %s:", status.c_str(), status_author_text(en).c_str());
            ImGui::TextWrapped("%s", reason.c_str());
            at_track(inWindow ? "feedback:win:reason" : "feedback:reason:text");
        }
    }
    field("missing", en.value("missing", ""));
    field("workaround", en.value("workaround", ""));
    if (inWindow) list_field("workaround files", en.value("workaroundFiles", Json::array()));
    field("suggestion", en.value("suggestion", ""));
    field("engine issue", en.value("engineIssue", ""));
    if (inWindow) {
        std::string line = en.value("severity", "") + " severity";
        if (en.contains("effort")) line += ", " + en["effort"].dump() + " effort";
        line += ", " + std::to_string(en.value("occurrences", 1)) + (en.value("occurrences", 1) == 1 ? " occurrence" : " occurrences");
        if (en.contains("date")) line += ", filed " + en.value("date", "");
        if (en.contains("reviewed")) line += en.value("reviewed", false) ? ", reviewed" : ", not reviewed";
        field("details", line);
        if (en.contains("reporter") && en["reporter"].is_object()) field("reported by", en["reporter"].dump());
        if (en.contains("notes") && en["notes"].is_array()) list_field("notes", en["notes"]);
        if (en.contains("distinctFrom")) list_field("not the same as", en["distinctFrom"]);
        if (en.contains("claimCheck")) field("claim check", en.value("claimCheck", ""));
        if (en.contains("share") && en["share"].is_object()) {
            const ShareFields sf = ShareFields::from_entry(en);
            field("share text: title", sf.title);
            field("share text: missing", sf.missing);
            field("share text: suggestion", sf.suggestion);
            field("share text: workaround", sf.workaround);
        }
        if (en.contains("remote") && en["remote"].is_object()) field("remote", en["remote"].dump());
    }
    {
        const ShareColumn c = share_column(en);
        ImGui::TextDisabled("share:");
        ImGui::SameLine();
        draw_feedback_share_cell(en, inWindow ? "feedback:win:share" : "feedback:share:state");
        ImGui::PushTextWrapPos(0);
        ImGui::TextDisabled("%s", c.tooltip.c_str());
        ImGui::PopTextWrapPos();
    }
    // The window has them at its top, where a short window still shows them; an entry that has a window does not show them twice
    // (a popup belongs to the window that opened it).
    if (!inWindow) {
        const std::string id = en.value("id", std::string());
        if (std::find(fbWindows_.begin(), fbWindows_.end(), id) == fbWindows_.end()) draw_feedback_actions(en, path);
        else ImGui::TextDisabled("This entry is open in its own window.");
    }
}

// The detail windows: one per entry the person opened with a double click. Each is an ordinary floating window (move, resize,
// scroll); the text wraps to its width. A window whose entry is gone (deleted, or the file replaced) closes by itself.
void Editor::draw_feedback_windows() {
    if (!engine_) return;
    const std::string path = fs::join(projectDir_, engine_->project().feedbackFile);
    const ImVec2 display = ImGui::GetIO().DisplaySize;
    for (size_t i = 0; i < fbWindows_.size();) {
        const std::string id = fbWindows_[i];
        const Json* entry = feedback_entry(id);
        if (!entry) {
            fbWindows_.erase(fbWindows_.begin() + std::ptrdiff_t(i));
            continue;
        }
        const Json en = *entry;  // a copy: a button below may rewrite the files and reload the documents
        bool open = true;
        const std::string title = "Feedback " + id + "###fbwin-" + id;
        const float step = 28.0f * float(i % 6);
        ImGui::SetNextWindowSize(ImVec2(std::min(560.0f, display.x - 40.0f), std::min(440.0f, display.y - 80.0f)), ImGuiCond_Appearing);
        ImGui::SetNextWindowPos(ImVec2(display.x * 0.5f - 280.0f + step, display.y * 0.3f + step), ImGuiCond_Appearing);
        ImGui::SetNextWindowSizeConstraints(ImVec2(300, 200), ImVec2(FLT_MAX, FLT_MAX));
        if (ImGui::Begin(title.c_str(), &open, ImGuiWindowFlags_NoDocking | ImGuiWindowFlags_NoSavedSettings)) {
            at_track("feedback:win:" + id);
            draw_feedback_actions(en, path);
            ImGui::SameLine();
            if (ImGui::Button("Close")) open = false;
            at_track("feedback:win:close");
            ImGui::SetItemTooltip("Close this window");
            ImGui::Separator();
            draw_feedback_detail(en, path, true);
        }
        ImGui::End();
        if (!open) {
            fbWindows_.erase(fbWindows_.begin() + std::ptrdiff_t(i));
            if (fbAsk_.open && fbAsk_.id == id) fbAsk_.open = false;
            continue;
        }
        ++i;
    }
}

// The Add feedback window: the gap in the person's own words. Nothing about sharing is asked here: Send feedback makes the text that
// leaves (or an AI that reports already wrote one), and shows it before it goes.
void Editor::draw_feedback_add_window() {
    const char* id = "Add feedback###fb-add";
    if (!fbAddOpen_) return;
    if (!ImGui::IsPopupOpen(id)) ImGui::OpenPopup(id);
    const ImVec2 display = ImGui::GetIO().DisplaySize;
    ImGui::SetNextWindowPos(ImGui::GetMainViewport()->GetCenter(), ImGuiCond_Appearing, ImVec2(0.5f, 0.5f));
    ImGui::SetNextWindowSize(ImVec2(std::min(560.0f, display.x - 40.0f), 0), ImGuiCond_Appearing);
    bool open = true;
    if (!ImGui::BeginPopupModal(id, &open, ImGuiWindowFlags_AlwaysAutoResize | ImGuiWindowFlags_NoSavedSettings)) {
        if (!ImGui::IsPopupOpen(id)) fbAddOpen_ = false;
        return;
    }
    const std::string path = fs::join(projectDir_, engine_->project().feedbackFile);
    const auto& cats = feedback_categories();
    const auto& sevs = feedback_severities();
    const float comboW = 200.0f;
    ImGui::SetNextItemWidth(comboW);
    combo_strings("category", &fbNewCategory_, cats, false);
    at_track("add:category");
    ImGui::SetNextItemWidth(comboW);
    combo_strings("severity", &fbNewSeverity_, sevs, false);
    at_track("add:severity");
    const float w = 520.0f;
    ImGui::TextUnformatted("Title (short, specific)");
    ImGui::SetNextItemWidth(w);
    ImGui::InputText("##nt", &fbNewTitle_);
    at_track("add:title");
    ImGui::TextUnformatted("What is missing?");
    ImGui::InputTextMultiline("##nm", &fbNewMissing_, ImVec2(w, ImGui::GetTextLineHeight() * 4 + 8));
    at_track("add:missing");
    ImGui::TextUnformatted("Workaround you used");
    ImGui::InputTextMultiline("##nw", &fbNewWorkaround_, ImVec2(w, ImGui::GetTextLineHeight() * 3 + 8));
    at_track("add:workaround");
    ImGui::TextUnformatted("Suggested engine change (optional)");
    ImGui::InputTextMultiline("##ns", &fbNewSuggestion_, ImVec2(w, ImGui::GetTextLineHeight() * 3 + 8));
    at_track("add:suggestion");
    if (!fbMessage_.empty()) {
        ImGui::PushTextWrapPos(w);
        ImGui::TextColored(ImVec4(1, 0.7f, 0.4f, 1), "%s", fbMessage_.c_str());
        ImGui::PopTextWrapPos();
        at_track("add:message");
    }
    bool added = false;
    auto close_form = [&] {
        fbNewTitle_.clear();
        fbNewMissing_.clear();
        fbNewWorkaround_.clear();
        fbNewSuggestion_.clear();
    };
    if (ImGui::Button("Add", ImVec2(110, 0))) {
        std::string lacking;
        auto need = [&](const std::string& text, const char* name) {
            if (!trim(text).empty()) return;
            lacking += (lacking.empty() ? "" : ", ") + std::string(name);
        };
        need(fbNewTitle_, "the title");
        need(fbNewMissing_, "what is missing");
        need(fbNewWorkaround_, "the workaround");
        if (!lacking.empty()) {
            fbMessage_ = "Fill in " + lacking + " first.";
        } else {
            FeedbackInput in;
            in.category = cats[size_t(std::clamp(fbNewCategory_, 0, int(cats.size()) - 1))];
            in.severity = sevs[size_t(std::clamp(fbNewSeverity_, 0, int(sevs.size()) - 1))];
            in.title = std::string(trim(fbNewTitle_));
            in.missing = std::string(trim(fbNewMissing_));
            in.workaround = std::string(trim(fbNewWorkaround_));
            in.suggestion = std::string(trim(fbNewSuggestion_));
            in.reporter = Json::object({{"kind", "human"}, {"agent", "factoria-editor"}});
            // The same check as feedback.report and `factoria feedback add`: a gap the engine already covers is not filed.
            const ClaimResult claim = check_feedback_claim(ClaimInput{in.title, in.missing, in.suggestion}, &engine_->commands());
            Result<FeedbackAddResult> r = make_error(claim.message(), claim.hint());
            if (!claim.refused()) {
                // Under the lock the other writers take; this is the UI thread, so a busy lock is waited for 0.3 s at most.
                const ShareWaitCap shortWait(0.3);
                FeedbackFileLock lock(ui_share_env(), path);
                r = lock.held() ? add_feedback_entry_to_file(path, in, projectName_) : Result<FeedbackAddResult>(make_error(lock.error(), "Try again in a moment."));
            }
            if (r) {
                fbMessage_ = (r->merged ? "Merged into " : "Added ") + r->id + (r->merged ? " (occurrences " + std::to_string(r->occurrences) + ")" : "");
                fbSelected_ = r->id;
                close_form();
                share_.tickAt = -10;
                feedbackMtime_ = INT64_MIN;
                feedbackPolled_ = -10;
                open = false;
                added = true;
            } else {
                fbMessage_ = r.error().to_string();
            }
        }
    }
    at_track("add:ok");
    ImGui::SetItemTooltip("Save this entry in %s", engine_->project().feedbackFile.c_str());
    ImGui::SameLine();
    if (ImGui::Button("Cancel", ImVec2(110, 0))) {
        close_form();
        fbMessage_.clear();
        open = false;
    }
    at_track("add:cancel");
    ImGui::SetItemTooltip("Close this window without saving anything");
    if (!open) {
        if (!added) {  // Cancel or the window's X: nothing is saved
            close_form();
            fbMessage_.clear();
        }
        fbAddOpen_ = false;
        ImGui::CloseCurrentPopup();
    }
    ImGui::EndPopup();
}

}  // namespace fa::editor
