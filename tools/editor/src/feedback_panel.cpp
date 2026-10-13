// Engine Feedback panel: view/filter/add/update entries of the project's ENGINE_FEEDBACK.json
// through the fa_tooling feedback API.
#include <algorithm>

#include "editor_internal.h"

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
    // (Re)load when the file changed on disk (AIs append to it while the editor is open).
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
    ImGui::SameLine();
    ImGui::TextDisabled("- what the engine lacked, recorded by you and by AIs");
    if (!feedbackError_.empty()) ImGui::TextColored(ImVec4(1, 0.45f, 0.4f, 1), "%s", feedbackError_.c_str());
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
    ImGui::BeginChild("##fbbody", ImVec2(0, 0), ImGuiChildFlags_None);
    const float tableH = std::min(180.0f, ImGui::GetTextLineHeightWithSpacing() * float(entries.size() + 2) + 8);
    if (ImGui::BeginTable("##fbt", 5, ImGuiTableFlags_RowBg | ImGuiTableFlags_ScrollY | ImGuiTableFlags_Resizable | ImGuiTableFlags_SizingStretchProp | ImGuiTableFlags_BordersInnerV,
                          ImVec2(0, std::max(60.0f, tableH)))) {
        ImGui::TableSetupScrollFreeze(0, 1);
        ImGui::TableSetupColumn("id", ImGuiTableColumnFlags_WidthFixed, 62);
        ImGui::TableSetupColumn("sev", ImGuiTableColumnFlags_WidthFixed, 66);
        ImGui::TableSetupColumn("status", ImGuiTableColumnFlags_WidthFixed, 96);
        ImGui::TableSetupColumn("x", ImGuiTableColumnFlags_WidthFixed, 28);
        ImGui::TableSetupColumn("title", ImGuiTableColumnFlags_WidthStretch);
        ImGui::TableHeadersRow();
        for (const auto& en : entries) {
            const std::string id = en.value("id", "");
            ImGui::TableNextRow();
            ImGui::TableSetColumnIndex(0);
            if (ImGui::Selectable(id.c_str(), id == fbSelected_, ImGuiSelectableFlags_SpanAllColumns)) fbSelected_ = id;
            ImGui::TableSetColumnIndex(1);
            ImGui::TextColored(severity_color(en.value("severity", "")), "%s", en.value("severity", "").c_str());
            ImGui::TableSetColumnIndex(2);
            ImGui::TextUnformatted(en.value("status", "").c_str());
            ImGui::TableSetColumnIndex(3);
            ImGui::Text("%d", en.value("occurrences", 1));
            ImGui::TableSetColumnIndex(4);
            ImGui::TextUnformatted(en.value("title", "").c_str());
        }
        ImGui::EndTable();
    }
    // Detail of the selected entry.
    for (const auto& en : entries) {
        if (en.value("id", "") != fbSelected_) continue;
        ImGui::Separator();
        ImGui::TextColored(ImVec4(0.6f, 0.8f, 1, 1), "%s  [%s]", en.value("title", "").c_str(), en.value("category", "").c_str());
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
        int cur = 0;
        const auto& st = feedback_statuses();
        std::string curStatus = en.value("status", "open");
        for (size_t i = 0; i < st.size(); ++i) if (st[i] == curStatus) cur = int(i);
        ImGui::SetNextItemWidth(160);
        if (combo_strings("status##detail", &cur, st, false) && st[size_t(cur)] != curStatus) {
            if (auto r = update_feedback_entry(feedbackDoc_, fbSelected_, st[size_t(cur)], ""); !r) notify(r.error().to_string(), 2);
            else if (auto s = save_feedback(path, feedbackDoc_); !s) notify(s.error().to_string(), 2);
            feedbackMtime_ = fs::modified_time(engine_->project().feedbackFile);
        }
        ImGui::SetItemTooltip("Change the status of this entry (saved immediately)");
        break;
    }

    ImGui::Separator();
    if (ImGui::CollapsingHeader("Add entry")) {
        const auto& cats = feedback_categories();
        const auto& sevs = feedback_severities();
        ImGui::SetNextItemWidth(w3 * 1.2f);
        combo_strings("category", &fbNewCategory_, cats, false);
        ImGui::SetNextItemWidth(w3 * 1.2f);
        combo_strings("severity", &fbNewSeverity_, sevs, false);
        ImGui::SetNextItemWidth(-FLT_MIN);
        ImGui::InputTextWithHint("##nt", "Title (short, specific)", &fbNewTitle_);
        ImGui::InputTextMultiline("##nm", &fbNewMissing_, ImVec2(-FLT_MIN, ImGui::GetTextLineHeight() * 3 + 8));
        if (fbNewMissing_.empty()) ImGui::GetWindowDrawList()->AddText(ImVec2(ImGui::GetItemRectMin().x + 6, ImGui::GetItemRectMin().y + 4), IM_COL32(120, 125, 140, 255), "What is missing?");
        ImGui::InputTextMultiline("##nw", &fbNewWorkaround_, ImVec2(-FLT_MIN, ImGui::GetTextLineHeight() * 3 + 8));
        if (fbNewWorkaround_.empty()) ImGui::GetWindowDrawList()->AddText(ImVec2(ImGui::GetItemRectMin().x + 6, ImGui::GetItemRectMin().y + 4), IM_COL32(120, 125, 140, 255), "Workaround used");
        ImGui::InputTextMultiline("##ns", &fbNewSuggestion_, ImVec2(-FLT_MIN, ImGui::GetTextLineHeight() * 2 + 8));
        if (fbNewSuggestion_.empty()) ImGui::GetWindowDrawList()->AddText(ImVec2(ImGui::GetItemRectMin().x + 6, ImGui::GetItemRectMin().y + 4), IM_COL32(120, 125, 140, 255), "Suggested engine change (optional)");
        ImGui::BeginDisabled(fbNewTitle_.empty() || fbNewMissing_.empty() || fbNewWorkaround_.empty());
        if (ImGui::Button("Submit")) {
            FeedbackInput in;
            in.category = cats[size_t(std::clamp(fbNewCategory_, 0, int(cats.size()) - 1))];
            in.severity = sevs[size_t(std::clamp(fbNewSeverity_, 0, int(sevs.size()) - 1))];
            in.title = fbNewTitle_;
            in.missing = fbNewMissing_;
            in.workaround = fbNewWorkaround_;
            in.suggestion = fbNewSuggestion_;
            in.reporter = Json::object({{"kind", "human"}, {"agent", "factoria-editor"}});
            auto r = add_feedback_entry_to_file(path, in, projectName_);
            if (r) {
                fbMessage_ = (r->merged ? "Merged into " : "Added ") + r->id + (r->merged ? " (occurrences " + std::to_string(r->occurrences) + ")" : "");
                fbSelected_ = r->id;
                fbNewTitle_.clear();
                fbNewMissing_.clear();
                fbNewWorkaround_.clear();
                fbNewSuggestion_.clear();
                feedbackMtime_ = INT64_MIN;
                feedbackPolled_ = -10;
            } else {
                fbMessage_ = r.error().to_string();
            }
        }
        ImGui::EndDisabled();
        ImGui::SameLine();
        ImGui::TextWrapped("%s", fbMessage_.c_str());
    }
    ImGui::EndChild();
    ImGui::End();
}

}  // namespace fa::editor
