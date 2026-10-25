// Play sessions in the editor: records Play .. Stop (input, frame times, warnings/errors), F9 problem marks, and writes
// .factoria/sessions/<name>/ at Stop. File format and the play.sessions / play.report commands: fa/runtime/play_session.h.
#include <ctime>
#include <filesystem>

#include "editor_internal.h"

namespace fa::editor {

void Editor::session_begin() {
    if (!engine_) return;
    run_ = PlayRun{};
    run_.active = true;
    run_.startFrame = engine_->frame_index();
    run_.logSeq = log_last_seq();  // wall clock: only for the folder name
    run_.rec.start(run_.startFrame);
    const CalendarDate today = engine_->scripts().today();
    run_.rec.set_date(today.iso(), today.utcOffsetMinutes);
    engine_->log_clipboard_reads(true);  // what clipboard.read() / Ctrl+V returned goes into the replay
    PlaySession& s = run_.session;
    s.name = play_session_name(std::time(nullptr));
    s.scene = scenePath_;
    s.fixedHz = engine_->fixed_dt() > 0 ? 1.0 / engine_->fixed_dt() : 60.0;
    playNotice_.clear();
    profView_.reset();
    Profiler::get().set_enabled(true);  // the session records where the time goes; profile_tick() keeps it on until Stop
    run_.profile.add_memory(engine_->profile_memory());
}

void Editor::session_frame(double dt, std::uint64_t frameBefore) {
    if (!run_.active) return;
    if (run_.skipNext) {
        run_.skipNext = false;
        return;
    }
    if (Profiler::on() && engine_->frame_index() > frameBefore) run_.profile.add_frame(Profiler::get().last());
    const double ms = dt * 1000.0;
    run_.frameMs.push_back(ms);
    run_.session.durationSec += dt;
    const std::vector<PlaySpike>& sp = run_.session.spikes;
    if (ms > 20.0 && (sp.size() < 10 || ms > sp.back().ms)) {  // only the slow ones pay for the stats
        PlaySpike k;
        k.frame = frameBefore - run_.startFrame;
        k.ms = ms;
        k.entities = int(world().entity_count());
        if (engine_->renderer()) k.renderStats = engine_->renderer()->stats().to_json();
        keep_worst_spike(run_.session.spikes, std::move(k));
    }
}

void Editor::session_end() {
    if (!run_.active) return;
    run_.active = false;
    if (engine_) engine_->log_clipboard_reads(false);
    PlaySession s = std::move(run_.session);
    s.frames = engine_->frame_index() - run_.startFrame;
    if (s.frames == 0 && s.marks.empty()) return;  // nothing was played
    s.perf = compute_frame_stats(run_.frameMs);
    if (run_.profile.frames() > 0) {
        run_.profile.add_memory(engine_->profile_memory());
        s.profile = run_.profile.to_json();
    }
    for (const LogEntry& l : recent_logs(200, LogLevel::Warn, run_.logSeq))
        s.logs.push_back(Json::object({{"seq", l.seq}, {"frame", l.frame >= run_.startFrame ? l.frame - run_.startFrame : 0},
                                       {"level", log_level_name(l.level)}, {"category", l.category}, {"message", l.message}}));
    s.input = run_.rec.input();
    auto w = write_play_session(std::string(kPlaySessionsDir) + "/" + s.name, s);
    if (!w.ok()) {
        notify("Could not save the play session: " + w.error().to_string(), 2);
        return;
    }
    if (!s.marks.empty() || !s.logs.empty()) {
        playNotice_ = "Last play: " + std::to_string(s.marks.size()) + " mark(s), " + std::to_string(s.logs.size()) + " warning(s)/error(s).";
    }
    FA_INFO("editor", "play session saved: {}/{}", kPlaySessionsDir, s.name);
}

void Editor::mark_problem() {
    if (!engine_ || !run_.active || play_ != PlayState::Playing || markOpen_) return;
    pause();  // the game stops exactly here; Resume happens when the note is saved
    const std::uint64_t frame = engine_->frame_index() - run_.startFrame;
    PlayMark m;
    m.frame = frame;
    m.time = double(frame) * engine_->fixed_dt();
    m.screenshot = "mark-" + std::to_string(run_.session.marks.size() + 1) + ".png";
    std::string err;
    if (!engine_->screenshot(std::string(kPlaySessionsDir) + "/" + run_.session.name + "/" + m.screenshot, &err)) {
        notify("Mark without picture: " + err, 1);
        m.screenshot.clear();
    }
    markPending_ = m;
    markNote_.clear();
    markOpen_ = markFocus_ = true;
}

void Editor::mark_finish(bool save) {
    if (!markOpen_) return;
    markOpen_ = false;
    if (save) {
        markPending_.note = markNote_.empty() ? "(no note)" : markNote_;
        run_.session.marks.push_back(markPending_);
        notify("Marked frame " + std::to_string(markPending_.frame) + ": " + markPending_.note);
    } else if (!markPending_.screenshot.empty()) {
        std::error_code ec;
        std::filesystem::remove(fs::resolve(std::string(kPlaySessionsDir) + "/" + run_.session.name + "/" + markPending_.screenshot), ec);
    }
    if (engine_ && play_ == PlayState::Paused) {  // back to the game
        engine_->set_paused(false);
        play_ = PlayState::Playing;
        run_.skipNext = true;
    }
}

void Editor::draw_mark_popup() {
    if (markOpen_) ImGui::OpenPopup("Mark a problem##mark");
    if (!ImGui::BeginPopupModal("Mark a problem##mark", nullptr, ImGuiWindowFlags_AlwaysAutoResize)) return;
    if (!markOpen_) ImGui::CloseCurrentPopup();  // closed from elsewhere (Stop)
    ImGui::Text("Frame %llu. What is wrong? (one line; the AI sees it with the screenshot)", static_cast<unsigned long long>(markPending_.frame));
    if (markFocus_) {
        ImGui::SetKeyboardFocusHere();
        markFocus_ = false;
    }
    ImGui::SetNextItemWidth(480);
    const bool enter = ImGui::InputText("##marknote", &markNote_, ImGuiInputTextFlags_EnterReturnsTrue);
    if (enter || ImGui::Button("Save mark")) {
        mark_finish(true);
        ImGui::CloseCurrentPopup();
    } else {
        ImGui::SameLine();
        if (ImGui::Button("Cancel") || ImGui::IsKeyPressed(ImGuiKey_Escape, false)) {
            mark_finish(false);
            ImGui::CloseCurrentPopup();
        }
    }
    ImGui::EndPopup();
}

void Editor::ai_attach_last_session() {
    const std::vector<std::string> names = play_session_names();
    if (names.empty()) {
        notify("No play session yet: press Play, then Stop.", 1);
        return;
    }
    ai_sync_chats();
    const std::string dir = std::string(kPlaySessionsDir) + "/" + names.front();
    auto r = load_json_file(dir + "/session.json");
    if (!r.ok()) {
        notify(r.error().to_string(), 2);
        return;
    }
    std::string& input = chat_.current().input;
    if (!input.empty() && input.back() != '\n') input += "\n";
    input += play_session_summary(r.value()) + " (Details: play.report; replay: " + dir + "/input.json)\n";
    if (r.value().contains("marks"))
        for (const Json& m : r.value()["marks"]) {
            const std::string shot = m.value("screenshot", std::string());
            if (!shot.empty()) ai_attach_path(fs::resolve(dir + "/" + shot).string());
        }
    playNotice_.clear();
}

}  // namespace fa::editor
