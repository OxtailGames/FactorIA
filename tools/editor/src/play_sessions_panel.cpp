// Play sessions window and Play > Let the AI Play (docs/EDITOR.md, "Play sessions"). The bot runs in a child process on a worker
// thread (auto_play_job.h): the UI thread only starts it, polls it and draws. The sessions are the folders under
// .factoria/sessions/, the ones a person recorded with Play .. Stop and the ones play.auto wrote (marked "AI").
#include <algorithm>
#include <format>

#include "editor_internal.h"
#include "ui_backend.h"

namespace fa::editor {

namespace {

const ImVec4 kAutoColor(0.55f, 0.75f, 1.0f, 1);

}  // namespace

void Editor::open_play_sessions(const std::string& select) {
    showPlaySessions_ = true;
    playSessionsFocus_ = true;
    playSessionsDirty_ = true;
    if (!select.empty()) playSessionsPick_ = select;
}

void Editor::refresh_play_sessions() {
    playSessionRows_ = read_play_sessions();
    playSessionsDirty_ = false;
    playSessionsGen_++;
    if (!playSessionsPick_.empty() &&
        std::none_of(playSessionRows_.begin(), playSessionRows_.end(),
                     [&](const PlaySessionRow& r) { return r.name == playSessionsPick_; }))
        playSessionsPick_.clear();
    if (playSessionsPick_.empty() && !playSessionRows_.empty()) playSessionsPick_ = playSessionRows_.front().name;
}

void Editor::start_auto_play() {
    if (!engine_) {
        notify("Open a project first: the AI plays the open project.", 1);
        return;
    }
    if (autoPlay_.running()) {
        open_play_sessions();
        return;
    }
    if (play_ != PlayState::Edit) {
        notify("Stop the game first: the AI plays it from the start, on its own.", 1);
        return;
    }
    AutoPlayRequest req;
    req.projectDir = std::filesystem::path(
        projectDir_);  // the editor keeps the folder as a native string: back to the path it names
    req.seconds = autoPlaySeconds_;
    req.screenshots = autoPlayPictures_;
    if (!autoPlay_.start(req)) return;
    autoPlayLast_.reset();
    open_play_sessions();
    if (dirty_) notify("The scene has unsaved changes: the AI plays the project as saved on disk.", 1);
}

void Editor::poll_auto_play() {
    if (playSessionsOutside_.exchange(false)) playSessionsDirty_ = true;
    std::optional<AutoPlayOutcome> done = autoPlay_.take_result();
    if (!done) return;
    notify(auto_play_summary(*done), done->ok ? (done->problems > 0 ? 1 : 0) : (done->cancelled ? 0 : 2));
    if (done->ok) {
        const std::string name = done->session;
        notify_action(
            "Report of the AI's play", "Open report", [this, name] { open_play_sessions(name); }, "autoplay:report");
        open_play_sessions(name);
    }
    autoPlayLast_ = std::move(done);
}

void Editor::reset_auto_play_state() {
    autoPlay_.cancel();  // the child is killed; nothing is written for a run that did not end
    autoPlay_.wait();
    (void)autoPlay_.take_result();
    autoPlayLast_.reset();
    playSessionRows_.clear();
    playSessionsPick_.clear();
    playSessionDoc_ = Json();
    playSessionDocName_.clear();
    playSessionsDirty_ = true;
    showPlaySessions_ = false;
}

void Editor::ai_attach_session(const std::string& name, const std::string& note) {
    ai_sync_chats();
    const std::string dir = std::string(kPlaySessionsDir) + "/" + name;
    auto r = load_json_file(dir + "/session.json");
    if (!r.ok()) {
        notify(r.error().to_string(), 2);
        return;
    }
    std::string& input = chat_.current().input;
    if (!input.empty() && input.back() != '\n') input += "\n";
    input += note + play_session_summary(r.value()) + " (Details: play.report; replay: " + dir + "/input.json)\n";
    if (r.value().is_object() && r.value().contains("marks") && r.value()["marks"].is_array())
        for (const Json& m : r.value()["marks"]) {
            const std::string shot = session_text(m, "screenshot");
            if (!shot.empty()) ai_attach_path(fs::path_to_utf8(fs::resolve(dir + "/" + shot)));
        }
    playNotice_.clear();
}

void Editor::ai_attach_last_session() {
    const std::vector<PlaySessionRow> rows = read_play_sessions(kPlaySessionRows);
    bool fellBack = false;
    const PlaySessionRow* row = session_to_attach(rows, fellBack);
    if (!row) {
        notify("No play session yet: press Play, then Stop.", 1);
        return;
    }
    // The button means the session the person played. Only when there is none is the newest automatic one attached, and the
    // message says whose play it was, so the AI does not take the bot's session for the person's.
    if (fellBack) notify("You have no play session of your own yet: attached the latest session of the AI's bot.", 1);
    ai_attach_session(
        row->name, fellBack ? "(This is a session the AI's bot played with play.auto, not one the user played.) " : "");
}

void Editor::draw_play_sessions_window() {
    if (!showPlaySessions_ || !engine_) return;
    const ImGuiViewport* vp = ImGui::GetMainViewport();
    ImGui::SetNextWindowSize(fit_work_area(ImVec2(860, 560)), ImGuiCond_FirstUseEver);  // a small screen scrolls it
    ImGui::SetNextWindowPos(ImVec2(vp->WorkPos.x + vp->WorkSize.x * 0.5f, vp->WorkPos.y + vp->WorkSize.y * 0.5f),
                            ImGuiCond_Appearing, ImVec2(0.5f, 0.5f));
    if (playSessionsFocus_) {
        ImGui::SetNextWindowFocus();
        playSessionsFocus_ = false;
    }
    if (!ImGui::Begin("Play sessions###PlaySessions", &showPlaySessions_, ImGuiWindowFlags_NoDocking)) {
        ImGui::End();
        return;
    }
    // A listing of a few small files, only when something changed (a run ended, Stop wrote a session, Refresh), never per frame.
    if (playSessionsDirty_) refresh_play_sessions();

    // ---- the bot
    const bool running = autoPlay_.running();
    ImGui::BeginDisabled(running || play_ != PlayState::Edit);
    if (ImGui::Button("Let the AI play")) start_auto_play();
    at_track("playsessions:run", !running && play_ == PlayState::Edit);
    ImGui::EndDisabled();
    // The widgets below can be disabled (a run is going, or Play is on): their tooltips still show, and the first says why.
    const auto tip = [](const std::string& text) {
        if (ImGui::IsItemHovered(ImGuiHoveredFlags_AllowWhenDisabled | ImGuiHoveredFlags_ForTooltip))
            ImGui::SetTooltip("%s", text.c_str());
    };
    {
        std::string text = "play.auto: a bot plays the project from its start for this many seconds of game time, "
                           "faster than real time, "
                           "and\nfinds what is stuck or broken. It plays the project as saved on disk, in a separate "
                           "process: the editor "
                           "stays free.";
        if (play_ != PlayState::Edit)
            text += "\n\nStop Play first: the bot plays the project from the start, as saved on disk.";
        else if (running)
            text += "\n\nA run is going: wait for it or press Cancel.";
        tip(text);  // one tooltip per frame
    }
    ImGui::SameLine();
    ImGui::SetNextItemWidth(90);
    ImGui::BeginDisabled(running);
    float secs = float(autoPlaySeconds_);
    if (ImGui::DragFloat("##aisecs", &secs, 1.0f, float(kAutoPlayMinSeconds), float(kAutoPlayMaxSeconds), "%.0f s"))
        autoPlaySeconds_ = double(secs);
    if (ImGui::IsItemDeactivatedAfterEdit() || autoPlaySeconds_ < kAutoPlayMinSeconds ||
        autoPlaySeconds_ > kAutoPlayMaxSeconds)
        autoPlaySeconds_ = std::clamp(autoPlaySeconds_, kAutoPlayMinSeconds, kAutoPlayMaxSeconds);
    at_track("playsessions:seconds", !running);
    tip(std::format("Seconds of GAME time the bot plays ({:.0f} to {:.0f}). A run ends sooner when the bot wins, loses "
                    "or gets stuck.",
                    kAutoPlayMinSeconds, kAutoPlayMaxSeconds));
    ImGui::SameLine();
    ImGui::Checkbox("Take pictures", &autoPlayPictures_);
    at_track("playsessions:pictures", !running);
    tip("A picture per stage, per problem and at the end. Off is faster and needs no graphics device.");
    ImGui::EndDisabled();
    if (running) {
        ImGui::SameLine();
        if (autoPlay_.cancelling()) {
            ImGui::TextDisabled("Cancelling...");
        } else if (ImGui::Button("Cancel")) {
            autoPlay_.cancel();
        }
        at_track("playsessions:cancel");
        ImGui::SetItemTooltip("Stops the bot. A run that did not end writes no session.");
        const std::string line = autoPlay_.progress_line();
        ImGui::TextColored(kAutoColor, "The AI is playing%.*s  %.0f s",
                           int(1 + int(autoPlay_.elapsed_seconds() * 2) % 3), "...", autoPlay_.elapsed_seconds());
        at_track("playsessions:running");
        if (!line.empty()) {
            ImGui::SameLine();
            ImGui::TextDisabled("%s", line.c_str());
        }
    } else if (autoPlayLast_ && !autoPlayLast_->ok && !autoPlayLast_->cancelled) {
        ImGui::PushTextWrapPos(0);
        ImGui::TextColored(kStatusFailed, "The AI could not play: %s", autoPlayLast_->error.c_str());
        if (!autoPlayLast_->hint.empty()) ImGui::TextDisabled("%s", autoPlayLast_->hint.c_str());
        ImGui::PopTextWrapPos();
        at_track("playsessions:error");
    } else if (play_ != PlayState::Edit) {
        ImGui::TextDisabled("Stop the game to let the AI play.");
    }
    ImGui::Separator();

    // ---- list | report
    const float listW = std::min(360.0f, ImGui::GetContentRegionAvail().x * 0.45f);
    ImGui::BeginChild("##sessionlist", ImVec2(listW, 0), ImGuiChildFlags_Borders);
    if (ImGui::SmallButton("Refresh")) playSessionsDirty_ = true;
    ImGui::SameLine();
    ImGui::TextDisabled("%zu session%s", playSessionRows_.size(), playSessionRows_.size() == 1 ? "" : "s");
    if (playSessionRows_.empty()) {
        ImGui::PushTextWrapPos(0);
        ImGui::TextDisabled("None yet. Press Play, then Stop, or let the AI play.");
        ImGui::PopTextWrapPos();
    }
    for (const PlaySessionRow& r : playSessionRows_) {
        ImGui::PushID(r.name.c_str());
        if (r.isAuto) ImGui::PushStyleColor(ImGuiCol_Text, kAutoColor);
        const bool picked = r.name == playSessionsPick_;
        if (ImGui::Selectable(play_session_label(r).c_str(), picked)) playSessionsPick_ = r.name;
        if (r.isAuto) ImGui::PopStyleColor();
        at_track("playsessions:row:" + r.name);
        if (ImGui::IsItemHovered())
            ImGui::SetTooltip("%s\n%s",
                              r.isAuto ? "Played by the AI's bot (play.auto)" : "Played by you (Play .. Stop)",
                              r.scene.c_str());
        ImGui::PopID();
    }
    ImGui::EndChild();
    ImGui::SameLine();
    ImGui::BeginChild("##sessionreport", ImVec2(0, 0), ImGuiChildFlags_Borders);
    draw_play_session_report();
    ImGui::EndChild();
    ImGui::End();
}

void Editor::draw_play_session_report() {
    const auto it = std::find_if(playSessionRows_.begin(), playSessionRows_.end(),
                                 [&](const PlaySessionRow& r) { return r.name == playSessionsPick_; });
    if (it == playSessionRows_.end()) {
        ImGui::TextDisabled("Pick a session to read its report.");
        return;
    }
    const PlaySessionRow& row = *it;
    if (playSessionDocName_ != row.name ||
        playSessionDocGen_ != playSessionsGen_) {  // read once per pick and per refresh
        auto r = load_json_file(std::string(kPlaySessionsDir) + "/" + row.name + "/session.json");
        playSessionDoc_ = r.ok() ? r.value() : Json();
        playSessionDocError_ = r.ok() ? std::string() : r.error().to_string();
        playSessionDocName_ = row.name;
        playSessionDocGen_ = playSessionsGen_;
    }
    ImGui::PushTextWrapPos(0);
    ImGui::TextColored(row.isAuto ? kAutoColor : ImVec4(1, 1, 1, 1), "%s",
                       row.isAuto ? "Played by the AI's bot (play.auto)" : "Played by you (Play .. Stop)");
    ImGui::TextDisabled("%s", row.name.c_str());
    if (!playSessionDocError_.empty() || !playSessionDoc_.is_object()) {
        ImGui::TextColored(kStatusFailed, "Cannot read this session: %s", playSessionDocError_.c_str());
        ImGui::PopTextWrapPos();
        return;
    }
    const Json& j = playSessionDoc_;
    const std::string folder = std::string(kPlaySessionsDir) + "/" + row.name;
    if (ImGui::Button("Attach to the AI chat"))
        ai_attach_session(row.name, row.isAuto ? "(This session was played by the AI's bot with play.auto.) " : "");
    at_track("playsessions:attach");
    ImGui::SetItemTooltip(
        "Puts the summary and the pictures of the problems into the message you are writing to the AI");
    const std::string replay = j.contains("auto") ? session_text(j["auto"], "replay") : std::string();
    if (!replay.empty()) {
        ImGui::SameLine();
        if (ImGui::Button("Copy replay command")) {
            ImGui::SetClipboardText(replay.c_str());
            notify("Replay command copied.");
        }
        ImGui::SetItemTooltip("The command that plays the bot's input again, headless: for a bug the bot found");
    }
    ImGui::Spacing();
    if (row.isAuto) {
        ImGui::Text("Ended: %s", play_session_ended_words(row.ended).c_str());
        at_track("playsessions:ended");
        const std::string why = session_text(j, "endedWhy");
        if (!why.empty()) ImGui::TextDisabled("%s", why.c_str());
        if (j.contains("score") && j["score"].is_number()) ImGui::Text("Score: %s", j["score"].dump().c_str());
        if (j.contains("notes") && j["notes"].is_array())
            for (const Json& n : j["notes"])
                if (n.is_string()) ImGui::TextColored(kStatusWarn, "%s", n.get<std::string>().c_str());
    }
    ImGui::TextWrapped("%s", play_session_summary(j).c_str());

    // ---- stages the bot reached
    if (row.isAuto && j.contains("phases") && j["phases"].is_array() && !j["phases"].empty()) {
        ImGui::Spacing();
        ImGui::SeparatorText("Stages");
        int n = 0;
        for (const Json& p : j["phases"]) {
            ++n;
            if (n > 60) break;
            ImGui::BulletText("%d. %s  at %.1f s", n, session_text(p, "name").c_str(), session_number(p, "time"));
        }
    }
    // ---- problems (the bot's) or marks (yours), each with its picture
    if (j.contains("marks") && j["marks"].is_array() && !j["marks"].empty()) {
        ImGui::Spacing();
        ImGui::SeparatorText(row.isAuto ? "Problems the bot found" : "Your marks");
        int n = 0;
        for (const Json& m : j["marks"]) {
            if (++n > 40) break;
            const std::string kind = session_text(m, "kind");
            ImGui::Text("#%d%s%s  at %.1f s", int(std::clamp(session_number(m, "n", n), -1e6, 1e6)),
                        kind.empty() ? "" : "  ", kind.c_str(), session_number(m, "time"));
            ImGui::TextWrapped("%s", session_text(m, "note").c_str());
            const std::string shot = session_text(m, "screenshot");
            if (!shot.empty()) {
                const TextureEntry* t = texture_for(folder + "/" + shot);
                if (t && t->w > 0 && t->h > 0) {
                    const float scale = std::min(240.0f / float(t->w), 160.0f / float(t->h));
                    ImGui::Image(ImTextureRef(ImTextureID(ui::texture_from_view(t->view, true))),
                                 ImVec2(float(t->w) * scale, float(t->h) * scale));
                }
            }
        }
    }
    if (const std::string end = session_text(j, "endScreenshot"); !end.empty()) {
        if (const TextureEntry* t = texture_for(folder + "/" + end); t && t->w > 0 && t->h > 0) {
            ImGui::Spacing();
            ImGui::SeparatorText("The last frame");
            const float scale = std::min(240.0f / float(t->w), 160.0f / float(t->h));
            ImGui::Image(ImTextureRef(ImTextureID(ui::texture_from_view(t->view, true))),
                         ImVec2(float(t->w) * scale, float(t->h) * scale));
        }
    }
    ImGui::PopTextWrapPos();
}

}  // namespace fa::editor
