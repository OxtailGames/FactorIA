// Reviews in the AI Assistant panel: "Art critique" and "Game review" buttons, the list of past reviews with their scores,
// and "Send to orchestrator". docs/EDITOR.md ("Reviews"), docs/AI_PROVIDERS.md ("Reviews").
//
// A review runs ONLY when the user presses a button here (the orchestrator cannot start one). It opens a chat tab of its own
// and runs the N reviewers one after another through the same run machinery as a message (ai_launch), with the role
// artCritic or reviewer: those roles can look and play but not change anything (ai/session.h, is_read_only_tool). When a
// reviewer finishes, ai_review_tick takes its last message, splits off the score, saves it in
// <project>/.factoria/ai/reviews/ and starts the next one. Nothing is sent to the orchestrator until the user presses
// "Send to orchestrator".
#include <algorithm>
#include <cmath>
#include <cstdio>
#include <ctime>

#include "editor_internal.h"
#include "imgui_internal.h"

namespace fa::editor {

namespace {

std::string score_text(double score) {
    if (score < 0) return "-";
    char buf[24];
    std::snprintf(buf, sizeof buf, "%.1f", score);
    return buf;
}

ImVec4 score_color(double score) {
    if (score < 0) return ImGui::GetStyleColorVec4(ImGuiCol_TextDisabled);
    if (score >= 7) return ImVec4(0.55f, 0.9f, 0.55f, 1);
    if (score >= 5) return ImVec4(1, 0.85f, 0.4f, 1);
    return ImVec4(1, 0.55f, 0.45f, 1);
}

const char* kind_label(const std::string& role) { return role == ai::kRoleArtCritic ? "art" : "game"; }

}  // namespace

void Editor::ai_review_request(const std::string& kind, int count, const std::string& focus) {
    if (!engine_ || aiReview_.active) return;
    const std::string role = ai::review_role_for_kind(kind);
    if (role.empty()) return;
    if (play_ != PlayState::Edit) {
        notify("Stop the game first (F5): the reviewers start the game themselves.", 1);
        return;
    }
    ai_sync_chats();
    ai_drain_events();
    if (ai_busy()) {
        notify("The assistant is busy: wait for it to finish, or press Stop, then ask for the review.", 1);
        return;
    }
    ai::AiConfig cfg;
    {
        std::lock_guard<std::mutex> lock(aiMu_);
        cfg = aiConfig_;
        if (cfg.providers.empty()) cfg = ai::default_config();
    }
    const ai::RoleConfig rc = cfg.role(role);
    AiChat& chat = chat_.add(static_cast<i64>(std::time(nullptr)));  // its own tab: the orchestrator's chat is not touched
    chat.title = kind == "art" ? "Art critique" : "Game review";
    aiTabForce_ = 2;
    aiReview_ = AiReviewJob{};
    aiReview_.active = true;
    aiReview_.kind = kind;
    aiReview_.role = role;
    aiReview_.focus = focus;
    aiReview_.chatId = chat.id;
    aiReview_.count = std::clamp(count, 1, ai::kMaxReviewers);
    aiReview_.provider = rc.provider;
    aiReview_.model = rc.model;
    ai_review_next();
}

void Editor::ai_review_abort(const std::string& why) {
    if (!why.empty()) notify(why, 2);
    aiReview_.active = false;
}

void Editor::ai_review_next() {
    AiChat* chat = chat_.find(aiReview_.chatId);
    if (!chat) {
        ai_review_abort("The review stopped: its chat tab is gone.");
        return;
    }
    if (aiThread_.joinable()) aiThread_.join();
    if (!ai_ensure_mcp()) {
        aiReview_.active = false;
        return;
    }
    const auto& personas = ai::review_personas(aiReview_.role);
    const int index = std::clamp(aiReview_.next, 0, static_cast<int>(personas.size()) - 1);
    const ai::ReviewPersona& persona = personas[static_cast<std::size_t>(index)];

    chat->conversation = {};  // every reviewer starts from nothing: no memory of the one before, nor of any other chat
    ChatItem user;
    user.kind = ChatItem::Kind::User;
    user.role = "review";  // marks the tab as a review's (ai_review_send does not post into it)
    user.text = std::string(aiReview_.kind == "art" ? "Art critique" : "Game review") + " " + std::to_string(index + 1) + " of " +
                std::to_string(aiReview_.count) + ": " + persona.name +
                (aiReview_.focus.empty() ? std::string() : "\nFocus: " + aiReview_.focus);
    chat->items.push_back(std::move(user));
    aiReview_.itemStart = chat->items.size();
    aiReview_.costBefore = chat->costUsd;
    chat->updated = static_cast<i64>(std::time(nullptr));
    chat->scrollDown = true;
    chat->runUsage = {};
    chat->runCostUsd = 0;

    aiRunChat_ = chat->id;
    aiRunRole_ = aiReview_.role;
    aiRunExtra_ = ai::persona_prompt(persona, index, aiReview_.count);
    ai_reset_run_state();
    ai_launch(ai::review_task(aiReview_.role, aiReview_.focus), {});
}

void Editor::ai_review_tick() {
    if (!aiReview_.active) return;
    if (aiRunning_.load() || aiDetached_.load() || !aiRunChat_.empty()) return;  // the reviewer is still working
    AiChat* chat = chat_.find(aiReview_.chatId);
    if (!chat) {
        ai_review_abort("The review stopped: its chat tab is gone.");
        return;
    }
    // The run is over (ai_drain_events ended it). Its last message at the top level is the report.
    std::string finalText;
    bool failed = false;
    for (std::size_t i = aiReview_.itemStart; i < chat->items.size(); ++i) {
        const ChatItem& it = chat->items[i];
        if (it.depth != 0) continue;
        if (it.kind == ChatItem::Kind::Error) failed = true;
        if (it.kind == ChatItem::Kind::Assistant) finalText = it.text;
    }
    const bool stopped = aiCancel_.load();
    chat->conversation = {};  // the next message in this tab is a normal one, not a continuation of a reviewer's session
    if (stopped || failed || finalText.empty()) {
        const std::string why = stopped ? "The review was stopped." : failed ? "The reviewer failed: see its chat for the reason."
                                                                           : "The reviewer ended without a report.";
        ChatItem note;
        note.kind = ChatItem::Kind::Info;
        note.text = why + (aiReview_.next + 1 < aiReview_.count ? " The remaining reviewers were not started." : "");
        chat->items.push_back(std::move(note));
        chat_.save(*chat);
        ai_review_abort(why);
        aiReviewDirty_ = true;
        return;
    }

    const auto& personas = ai::review_personas(aiReview_.role);
    const int index = std::clamp(aiReview_.next, 0, static_cast<int>(personas.size()) - 1);
    const ai::ParsedReport parsed = ai::parse_review_report(finalText);
    ai::Review review;
    review.role = aiReview_.role;
    review.persona = personas[static_cast<std::size_t>(index)].name;
    review.provider = aiReview_.provider;
    review.model = aiReview_.model;
    review.focus = aiReview_.focus;
    review.text = parsed.text;
    review.summary = parsed.summary;
    review.score = parsed.score;
    review.subScores = parsed.subScores;
    review.costUsd = std::max(0.0, chat->costUsd - aiReview_.costBefore);
    auto saved = ai::save_review(projectDir_, review);
    if (saved) {
        review = *saved;
        aiReview_.savedIds.push_back(review.id);
        aiReviewSelected_ = review.id;
    } else {
        notify("The review could not be saved: " + saved.error().to_string(), 2);
    }
    aiReviewDirty_ = true;
    ChatItem done;
    done.kind = ChatItem::Kind::Info;
    done.text = "review saved" + (saved ? ": " + review.id : std::string()) +
                (review.score >= 0 ? ", score " + score_text(review.score) + "/10" : ", no score given");
    chat->items.push_back(std::move(done));
    chat_.save(*chat);

    if (++aiReview_.next < aiReview_.count) {
        ai_review_next();
        return;
    }
    aiReview_.active = false;
    aiReviewsShown_ = true;  // the report, with its "Send to orchestrator" button
    notify(std::string(aiReview_.kind == "art" ? "Art critique" : "Game review") + " ready.", 0);
}

void Editor::draw_ai_review_row(bool gameRuns) {
    const bool busy = ai_busy() || aiReview_.active;
    ImGui::AlignTextToFramePadding();
    ImGui::TextDisabled("Review:");
    ImGui::SameLine();
    ImGui::BeginDisabled(busy || gameRuns);
    if (ImGui::Button("Art critique")) ai_review_request("art", aiReviewCount_, aiReviewFocus_);
    at_track("ai:review:art", !(busy || gameRuns));
    ImGui::SetItemTooltip("Read-only art critics look at the game (screenshots of every scene) and score its art from 0 to 10.\n"
                          "They cannot change anything. It runs only when you press this, and costs tokens.");
    ImGui::SameLine();
    if (ImGui::Button("Game review")) ai_review_request("game", aiReviewCount_, aiReviewFocus_);
    at_track("ai:review:game", !(busy || gameRuns));
    ImGui::SetItemTooltip("Read-only reviewers play the game and score it from 0 to 10, with the problems they found.\n"
                          "They cannot change anything. It runs only when you press this, and costs tokens.");
    ImGui::EndDisabled();
    ImGui::SameLine();
    if (ImGui::Button("Reviews...")) {
        aiReviewsShown_ = true;
        aiReviewDirty_ = true;
    }
    at_track("ai:review:list");
    ImGui::SetItemTooltip("The saved reviews with their scores. Reviews read REVIEW.md in the project first.");
    if (aiReview_.active) {
        ImGui::SameLine();
        ImGui::TextColored(ImVec4(1, 0.85f, 0.4f, 1), "%s %d of %d...", aiReview_.kind == "art" ? "art critique" : "game review",
                           std::min(aiReview_.next + 1, aiReview_.count), aiReview_.count);
    }
    // Second line: how many reviewers and what to look at. The focus box takes the rest of the width.
    ImGui::AlignTextToFramePadding();
    ImGui::TextDisabled("Reviewers:");
    ImGui::SameLine();
    ImGui::SetNextItemWidth(80);
    if (ImGui::InputInt("##reviewcount", &aiReviewCount_, 1, 1)) aiReviewCount_ = std::clamp(aiReviewCount_, 1, ai::kMaxReviewers);
    ImGui::SetItemTooltip("How many reviewers (1 to %d). Each has a different point of view; they run one after another.",
                          ai::kMaxReviewers);
    ImGui::SameLine();
    ImGui::SetNextItemWidth(-FLT_MIN);
    ImGui::InputTextWithHint("##reviewfocus", "focus (optional): what to look at", &aiReviewFocus_);
    ImGui::SetItemTooltip("What to look at, e.g. \"the shop screen\". Empty: the whole game.");
}

void Editor::ai_review_send(const ai::Review& review) {
    ai_sync_chats();
    ai_drain_events();
    if (ai_busy() || aiReview_.active) {
        notify("The assistant is busy: send the review when it has finished.", 1);
        return;
    }
    if (play_ != PlayState::Edit) {
        notify("Stop the game first (F5).", 1);
        return;
    }
    // The active chat when it is a conversation with the orchestrator (not a review's own tab), else a new one.
    const AiChat& cur = chat_.current();
    const bool isReviewTab = std::ranges::any_of(
        cur.items, [](const ChatItem& it) { return it.kind == ChatItem::Kind::User && it.role == "review"; });
    if (isReviewTab || cur.id == aiReview_.chatId) {
        chat_.add(static_cast<i64>(std::time(nullptr)));
        aiTabForce_ = 2;
    }
    ai_start(ai::review_as_message(review));
}

void Editor::draw_ai_reviews_window() {
    if (!aiReviewsShown_) return;
    if (aiReviewDirty_) {
        aiReviewList_ = ai::list_reviews(projectDir_, {}, 50);
        aiReviewDirty_ = false;
    }
    ImGui::SetNextWindowSize(ImVec2(620, 460), ImGuiCond_FirstUseEver);
    if (!ImGui::Begin("AI reviews", &aiReviewsShown_)) {
        ImGui::End();
        return;
    }
    if (aiReviewList_.empty()) {
        ImGui::TextWrapped("No reviews yet. Press Art critique or Game review in the AI Assistant: read-only agents look at and play "
                           "the game and give an opinion with a score from 0 to 10. Every review is saved in .factoria/ai/reviews/.");
        ImGui::End();
        return;
    }
    const ai::Review* selected = nullptr;
    for (const ai::Review& r : aiReviewList_) {
        if (r.id == aiReviewSelected_) selected = &r;
    }
    if (!selected) selected = &aiReviewList_.front();

    ImGui::BeginChild("##reviewlist", ImVec2(0, 150), ImGuiChildFlags_Borders);
    if (ImGui::BeginTable("##reviews", 5, ImGuiTableFlags_SizingFixedFit | ImGuiTableFlags_RowBg)) {
        ImGui::TableSetupColumn("When");
        ImGui::TableSetupColumn("Kind");
        ImGui::TableSetupColumn("Score");
        ImGui::TableSetupColumn("Reviewer");
        ImGui::TableSetupColumn("Version");
        ImGui::TableHeadersRow();
        for (const ai::Review& r : aiReviewList_) {
            ImGui::TableNextRow();
            ImGui::TableNextColumn();
            if (ImGui::Selectable((r.time + "##" + r.id).c_str(), r.id == selected->id, ImGuiSelectableFlags_SpanAllColumns))
                aiReviewSelected_ = r.id;
            ImGui::TableNextColumn();
            ImGui::TextUnformatted(kind_label(r.role));
            ImGui::TableNextColumn();
            ImGui::TextColored(score_color(r.score), "%s", score_text(r.score).c_str());
            ImGui::TableNextColumn();
            ImGui::TextUnformatted(r.persona.c_str());
            ImGui::TableNextColumn();
            ImGui::TextUnformatted(r.gameVersion.c_str());
        }
        ImGui::EndTable();
    }
    ImGui::EndChild();

    const ai::Review& r = *selected;
    ImGui::TextColored(score_color(r.score), "%s / 10", score_text(r.score).c_str());
    ImGui::SameLine();
    ImGui::TextDisabled("%s, %s%s%s", r.persona.c_str(), r.time.c_str(), r.model.empty() ? "" : ", ", r.model.c_str());
    if (!r.subScores.empty()) {
        std::string subs;
        for (const auto& [name, value] : r.subScores) subs += (subs.empty() ? "" : "   ") + name + " " + score_text(value);
        ImGui::TextDisabled("%s", subs.c_str());
    }
    const float footer = ImGui::GetFrameHeightWithSpacing() + ImGui::GetStyle().ItemSpacing.y;
    ImGui::BeginChild("##reviewtext", ImVec2(0, -footer), ImGuiChildFlags_Borders);
    ImGui::TextWrapped("%s", r.text.c_str());
    ImGui::EndChild();

    const bool busy = ai_busy() || aiReview_.active;
    const bool gameRuns = play_ != PlayState::Edit;
    ImGui::BeginDisabled(busy || gameRuns);
    if (ImGui::Button("Send to orchestrator")) {
        const ai::Review copy = r;  // ai_review_send may change the lists
        ai_review_send(copy);
    }
    at_track("ai:review:send", !(busy || gameRuns));
    ImGui::EndDisabled();
    ImGui::SetItemTooltip("Posts this report as your message to the orchestrator (the active chat, or a new one) so it can\n"
                          "decide what to fix and delegate it. Nothing is sent unless you press this.");
    ImGui::SameLine();
    if (ImGui::Button("Copy")) ImGui::SetClipboardText(r.text.c_str());
    ImGui::SameLine();
    ImGui::TextDisabled("%s", r.path.c_str());
    ImGui::End();
}

}  // namespace fa::editor
