// Engine Feedback panel: view/filter/add/update entries of the project's ENGINE_FEEDBACK.json
// through the fa_tooling feedback API.
#include <algorithm>

#include "editor_internal.h"
#include "fa/core/strings.h"

namespace fa::editor {

namespace {
bool combo_strings(const char* label, int* cur, const std::vector<std::string>& items, bool withAny) {
    // index 0 = "any" when withAny
    const int total = int(items.size()) + (withAny ? 1 : 0);
    *cur = std::clamp(*cur, 0, std::max(0, total - 1));
    std::string preview = withAny ? (*cur == 0 ? "any" : items[size_t(*cur - 1)]) : items[size_t(*cur)];
    bool changed = false;
    if (ImGui::BeginCombo(label, preview.c_str())) {
        for (int i = 0; i < total; ++i) {
            std::string name = withAny ? (i == 0 ? "any" : items[size_t(i - 1)]) : items[size_t(i)];
            if (ImGui::Selectable(name.c_str(), i == *cur)) { *cur = i; changed = true; }
        }
        ImGui::EndCombo();
    }
    return changed;
}

ImVec4 severity_color(const std::string& s) {
    if (s == "blocker") return ImVec4(1, 0.4f, 0.38f, 1);
    if (s == "major") return ImVec4(1, 0.7f, 0.3f, 1);
    if (s == "minor") return ImVec4(0.9f, 0.9f, 0.5f, 1);
    return ImVec4(0.65f, 0.7f, 0.8f, 1);
}
}  // namespace

void Editor::draw_feedback_panel() {
    if (!ImGui::Begin("Engine Feedback")) { ImGui::End(); return; }
    const std::string path = fs::join(projectDir_, engine_->project().feedbackFile);
    // (Re)load when the file changed on disk (AIs append to it while the editor is open). Entries that are not open are moved to
    // the archive file by feedback_share_tick as soon as it sees them, so what is listed here is what is still open.
    if (time_ - feedbackPolled_ > 1.0) {
        feedbackPolled_ = time_;
        const bool exists = fs::exists(engine_->project().feedbackFile);
        const std::int64_t mt = exists ? fs::modified_time(engine_->project().feedbackFile) : 0;
        if (mt != feedbackMtime_) {
            feedbackMtime_ = mt;
            if (!exists) {
                feedbackDoc_ = Json();
                feedbackError_.clear();
            } else if (auto r = load_feedback(path)) {
                feedbackDoc_ = *r;
                feedbackError_.clear();
            } else {
                feedbackError_ = r.error().to_string();
            }
        }
    }
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
    ImGui::SameLine();
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
    if (!fbMessage_.empty() && !fbAddOpen_) {
        ImGui::SameLine();
        ImGui::TextDisabled("%s", fbMessage_.c_str());
        at_track("feedback:message");
    }
    draw_feedback_add_window();

    if (feedbackDoc_.is_null()) {
        ImGui::TextWrapped("No feedback file yet.");
        if (ImGui::Button("Create ENGINE_FEEDBACK.json")) {
            Json doc = create_empty_feedback(projectName_);
            if (auto r = save_feedback(path, doc); !r) notify(r.error().to_string(), 2);
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
    // The panel keeps its size whatever an entry says: this area never scrolls or grows. Only the entries table and the
    // detail of the selected entry (their own children) scroll.
    ImGui::BeginChild("##fbbody", ImVec2(0, 0), ImGuiChildFlags_None, ImGuiWindowFlags_NoScrollbar | ImGuiWindowFlags_NoScrollWithMouse);
    // The table takes the room its rows need (header and one line per entry) up to two thirds of the panel and scrolls inside when
    // there are more; the detail below gets the rest, at least a few lines.
    const float bodyH = ImGui::GetContentRegionAvail().y;
    const float lineH = ImGui::GetTextLineHeightWithSpacing();
    const float gap = ImGui::GetStyle().ItemSpacing.y;
    const float detailMin = std::min(bodyH * 0.45f, lineH * 8.0f);
    const float tableMax = std::max(lineH * 3.0f + 8.0f, bodyH - detailMin - gap);
    const float tableH = std::clamp(lineH * float(entries.size() + 1) + 10.0f, lineH * 3.0f + 8.0f, tableMax);
    if (ImGui::BeginTable("##fbt", 5, ImGuiTableFlags_RowBg | ImGuiTableFlags_ScrollY | ImGuiTableFlags_SizingStretchProp | ImGuiTableFlags_BordersInnerV,
                          ImVec2(0, tableH))) {
        ImGui::TableSetupScrollFreeze(0, 1);
        ImGui::TableSetupColumn("id", ImGuiTableColumnFlags_WidthFixed, 66);
        ImGui::TableSetupColumn("severity", ImGuiTableColumnFlags_WidthFixed, 66);
        ImGui::TableSetupColumn("status", ImGuiTableColumnFlags_WidthFixed, 56);
        ImGui::TableSetupColumn("share", ImGuiTableColumnFlags_WidthFixed, 68);
        ImGui::TableSetupColumn("title", ImGuiTableColumnFlags_WidthStretch);
        ImGui::TableHeadersRow();
        for (const auto& en : entries) {
            const std::string id = en.value("id", "");
            ImGui::TableNextRow();
            ImGui::TableSetColumnIndex(0);
            if (ImGui::Selectable(id.c_str(), id == fbSelected_, ImGuiSelectableFlags_SpanAllColumns)) fbSelected_ = id;
            at_track("feedback:row:" + id);
            ImGui::TableSetColumnIndex(1);
            ImGui::TextColored(severity_color(en.value("severity", "")), "%s", en.value("severity", "").c_str());
            ImGui::TableSetColumnIndex(2);
            ImGui::TextUnformatted(en.value("status", "").c_str());
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
        ImGui::PushTextWrapPos(0);
        ImGui::TextColored(ImVec4(0.6f, 0.8f, 1, 1), "%s  [%s]  x%d", en.value("title", "").c_str(), en.value("category", "").c_str(), en.value("occurrences", 1));
        ImGui::PopTextWrapPos();
        auto field = [&](const char* label, const char* key) {
            std::string v = en.value(key, "");
            if (v.empty()) return;
            ImGui::TextDisabled("%s", label);
            ImGui::TextWrapped("%s", v.c_str());
        };
        field("missing", "missing");
        field("workaround", "workaround");
        field("suggestion", "suggestion");
        field("engine issue", "engineIssue");
        {
            const ShareColumn c = share_column(en);
            ImGui::TextDisabled("share:");
            ImGui::SameLine();
            draw_feedback_share_cell(en, "feedback:share:state");
            ImGui::PushTextWrapPos(0);
            ImGui::TextDisabled("%s", c.tooltip.c_str());
            ImGui::PopTextWrapPos();
        }
        int cur = 0;
        const auto& st = feedback_statuses();
        std::string curStatus = en.value("status", "open");
        for (size_t i = 0; i < st.size(); ++i) if (st[i] == curStatus) cur = int(i);
        ImGui::SetNextItemWidth(160);
        if (combo_strings("status##detail", &cur, st, false) && st[size_t(cur)] != curStatus) {
            if (auto r = update_feedback_file(path, fbSelected_, st[size_t(cur)], ""); !r) {
                notify(r.error().to_string(), 2);
            } else if (st[size_t(cur)] != "open") {
                notify(fbSelected_ + " is " + st[size_t(cur)] + ": it moves to the archive next to " + engine_->project().feedbackFile + ".", 0);
            }
            feedbackMtime_ = INT64_MIN;  // reload both files next poll
            feedbackPolled_ = -10;
            share_.tickAt = -10;         // ...and the archive is made at once
            share_.docStamp = INT64_MIN;
        }
        at_track("feedback:status");
        ImGui::SetItemTooltip("Change the status of this entry (saved immediately). An entry that is not open moves to the archive file.");
        break;
    }
    ImGui::EndChild();
    ImGui::EndChild();
    ImGui::End();
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
            auto r = add_feedback_entry_to_file(path, in, projectName_);
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
