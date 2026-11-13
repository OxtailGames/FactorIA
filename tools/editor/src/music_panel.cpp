// The Music panel (View > Music): a song document (*.song.json) as a piano roll, a drum grid, an arrangement and a mixer, with a transport that
// plays it the way a game's entity.music does (an intensity slider fades the layers, a section can be looped). Everything it keeps is a command
// call made by MusicModel (music.edit, music.arpeggio, music.bassline, music.drums, music.render), so the Console and an AI make the same edit,
// and each edit is ONE entry of the editor's undo stack. The rules are in music_model.h; the playback in music_preview.h. This file holds the
// document, the toolbar, the transport, the piano roll and the drum grid; the arrangement and the mixer are in music_mixer_panel.cpp.
#include <algorithm>
#include <cmath>
#include <cstdio>
#include <format>

#include "editor_internal.h"
#include "fa/audio/song_helpers.h"
#include "fa/audio/song_theory.h"
#include "fa/core/strings.h"
#include "imgui_internal.h"
#include "music_panel_util.h"
#include "ui_backend.h"

namespace fa::editor {

// ----------------------------------------------------------------------------------------------------------- document --
MusicModel& Editor::music_ensure_model() {
    if (!music_.model) {
        music_.model = std::make_unique<MusicModel>(projectDir_, [this](const std::string& name, const Json& args) {
            CommandResult r = engine_->commands().call(name, args);
            if (!args.is_object() || !args.value("dryRun", false)) after_command(name, args, r);
            return r;
        });
        if (autotest_) {
            music_.model->set_async(
                false);  // the autotest renders inline: what it waits for is state, not a worker thread
            music_.model->set_debounce_ticks(1);
        }
    }
    if (!music_.preview)
        music_.preview =
            std::make_unique<MusicPreview>(&engine_->audio(), [this] { return play_ == PlayState::Playing; });
    return *music_.model;
}

bool Editor::open_music_document(const std::string& rel) {
    if (!engine_) return false;
    MusicModel& m = music_ensure_model();
    MusicUi& u = music_;
    if (u.preview) u.preview->stop();
    u.pendingSection = -2;
    u.drag = MusicUi::Drag::None;
    u.sel.clear();
    u.selKeys.clear();
    u.notesKey.clear();
    u.pitchTop = 0;
    u.track.clear();
    u.pattern.clear();
    u.drumTrack.clear();
    u.drumPattern.clear();
    u.section = 0;
    u.cursorTick = 0;
    u.textKey.clear();
    u.measured = Json();
    const bool ok = m.open(rel);
    u.openError = ok ? std::string() : m.error();
    showMusic_ = true;
    focus_window("Music");
    if (!ok) notify("Cannot open " + rel + " in the Music panel: " + m.error(), 2);
    return ok;
}

void Editor::music_close_document() {
    if (music_.preview) music_.preview->stop();
    if (music_.model) music_.model->close();
    music_.drag = MusicUi::Drag::None;
}

void Editor::music_save() {
    MusicUi& u = music_;
    if (!u.model || !u.model->is_open() || !u.model->valid()) return;
    if (play_ != PlayState::Edit) {
        notify("Stop the game before baking the song.", 1);
        return;
    }
    u.model->set_overwrite_on_save(u.overwriteBaked);
    const MusicEditOutcome out = u.model->save();
    if (!out.ok)
        notify(out.error, 2);
    else
        project_files_changed();
}

void Editor::music_edited(const MusicEditOutcome& out) {
    MusicUi& u = music_;
    if (!out.ok) {
        notify(out.error, 1);
        return;
    }
    if (out.step <= 0 || !u.model) return;
    undo_.push_back(Json::object({{"$music", Json::object({{"step", out.step}})}}));
    if (undo_.size() > 100) undo_.erase(undo_.begin());
    redo_.clear();
    lastEditKey_.clear();
    music_collect_steps();
}

void Editor::music_collect_steps() {
    if (!music_.model) return;
    std::set<int> keep;
    for (const auto* stack : {&undo_, &redo_})
        for (const Json& e : *stack)
            if (e.is_object() && e.contains("$music") && e["$music"].is_object() && e["$music"].value("step", 0) > 0)
                keep.insert(e["$music"]["step"].get<int>());
    music_.model->retain_steps(keep);
}

void Editor::music_apply_undo(const Json& entry, bool forward) {
    MusicUi& u = music_;
    const int id = entry["$music"].value("step", 0);
    if (!u.model || !u.model->step(id)) {
        notify("That music edit is no longer remembered.", 1);
        return;
    }
    const std::string doc = u.model->step_document(id);
    if (!doc.empty() && doc != u.model->path()) open_music_document(doc);
    u.drag = MusicUi::Drag::None;
    if (!u.model->apply_step(id, forward)) {
        notify("Could not " + std::string(forward ? "redo" : "undo") + " the music edit: " + u.model->status(), 2);
        return;
    }
    (forward ? undo_ : redo_).push_back(entry);
    project_files_changed();
}

Vec2 Editor::music_screen_pos(std::int64_t tick, int pitch) const {
    const MusicUi& u = music_;
    const float px = u.pxPerBeat / float(kSongPpq);
    return Vec2{u.rollX0 + music_ui::kGutter + float(tick) * px,
                u.rollY0 + float(u.pitchTop - pitch) * music_ui::kRowH + music_ui::kRowH * 0.5f};
}

Vec2 Editor::music_drum_cell_pos(const std::string& lane, int step) const {
    const MusicUi& u = music_;
    const auto it = std::find(u.gridLanes.begin(), u.gridLanes.end(), lane);
    const int row = it == u.gridLanes.end() ? 0 : int(it - u.gridLanes.begin());
    return Vec2{u.gridX0 + (float(step) + 0.5f) * u.cellW, u.gridY0 + (float(row) + 0.5f) * u.cellH};
}

// -------------------------------------------------------------------------------------------------------------- panel --
void Editor::draw_music_panel() {
    MusicUi& u = music_;
    MusicModel& m = music_ensure_model();
    // One tick per frame: collects a finished render, starts the next one, tops the preview's queue up.
    if (m.is_open()) m.tick();
    u.preview->update(double(ImGui::GetIO().DeltaTime));
    if (m.is_open() && m.source() && u.preview->playing() && u.preview->source() != m.source().get() &&
        m.source_is_fresh())
        u.preview->replace_source(m.source());  // an edit was rendered again: cross over at the next bar line
    if (u.pendingSection != -2) {
        if (m.source()) {
            music_play(u.pendingSection, u.pendingLoop);
            u.pendingSection = -2;
        } else if (!m.busy()) {
            u.pendingSection = -2;
            notify("The song could not be rendered: " + (m.render_error().empty() ? m.error() : m.render_error()), 1);
        }
    }
    u.preview->set_loop_section(u.loopSection && u.preview->playing() ? u.preview->loop_section() : -1);

    first_floating_window(ImVec2(220, 100), ImVec2(1100, 780));
    if (!ImGui::Begin("Music", &showMusic_)) {
        u.focused = false;
        ImGui::End();
        return;
    }
    u.focused = ImGui::IsWindowFocused(ImGuiFocusedFlags_RootAndChildWindows);
    draw_music_toolbar(m);
    if (!m.is_open()) {
        ImGui::Spacing();
        ImGui::TextDisabled("Open a song (*.song.json) from the list above, or double click one in the Project panel.");
        ImGui::TextDisabled(
            "music.create makes one: a drum groove, a bass line and a chord pattern in a key, ready to play.");
        if (!u.openError.empty()) ImGui::TextColored(music_ui::kBad, "%s", u.openError.c_str());
        ImGui::End();
        return;
    }
    if (uiFrame_ - u.lastPoll >= 20 && u.drag == MusicUi::Drag::None) {
        u.lastPoll = uiFrame_;
        if (m.poll_external()) m.set_status("The file changed on disk and was read again.");
    }
    if (!m.valid()) {
        ImGui::Spacing();
        ImGui::TextColored(music_ui::kBad, "This song does not load:");
        ImGui::TextWrapped("%s", m.error().c_str());
        ImGui::TextDisabled(
            "Fix it with the Console (music.edit, fs.edit) or an editor, then Reload. music.check says what is wrong.");
        ImGui::End();
        return;
    }
    if (play_ != PlayState::Edit) ImGui::TextColored(music_ui::kWarn, "The game is running: stop it to edit the song.");
    if (!m.render_error().empty())
        ImGui::TextColored(music_ui::kBad, "The song cannot be rendered to play: %s", m.render_error().c_str());
    if (u.focused && !ImGui::GetIO().WantTextInput && ImGui::IsKeyPressed(ImGuiKey_Space, false)) music_toggle_play();

    draw_music_transport(m);
    ImGui::Separator();
    struct TabInfo {
        MusicUi::Tab tab;
        const char* label;
        const char* id;
    };
    static const TabInfo tabs[] = {{MusicUi::Tab::Roll, "Piano roll", "mus:tab_roll"},
                                   {MusicUi::Tab::Drums, "Drums", "mus:tab_drums"},
                                   {MusicUi::Tab::Arrangement, "Arrangement", "mus:tab_arrangement"},
                                   {MusicUi::Tab::Mixer, "Mixer", "mus:tab_mixer"}};
    for (const TabInfo& t : tabs) {
        if (music_ui::toggle_button(t.label, u.tab == t.tab)) u.tab = t.tab;
        at_track(t.id);
        ImGui::SameLine();
    }
    ImGui::NewLine();
    switch (u.tab) {
        case MusicUi::Tab::Roll: draw_music_roll(m); break;
        case MusicUi::Tab::Drums: draw_music_drums(m); break;
        case MusicUi::Tab::Arrangement: draw_music_arrangement(m); break;
        case MusicUi::Tab::Mixer: draw_music_mixer(m); break;
    }
    ImGui::End();
}

void Editor::draw_music_toolbar(MusicModel& m) {
    MusicUi& u = music_;
    const bool editable = play_ == PlayState::Edit;
    std::vector<std::string> files;
    for (const BrowserFile& f : projBrowser_.listing.files)
        if (ends_with(f.path, ".song.json")) files.push_back(f.path);
    std::sort(files.begin(), files.end());
    ImGui::SetNextItemWidth(320);
    if (ImGui::BeginCombo("##musfile", m.is_open() ? m.title().c_str() : "Open a song...")) {
        for (const std::string& f : files) {
            if (ImGui::Selectable(f.c_str(), f == m.path())) open_music_document(f);
            at_track("mus:file:" + f);
        }
        if (files.empty()) ImGui::TextDisabled("No songs (*.song.json) in the project yet.");
        ImGui::EndCombo();
    }
    at_track("mus:open");
    if (ImGui::IsItemHovered())
        ImGui::SetTooltip("The songs of the project (*.song.json). A double click in the Project panel opens one too. "
                          "music.create makes a new one.");
    if (!m.is_open()) return;
    ImGui::SameLine();
    ImGui::BeginDisabled(!editable || !m.valid());
    if (ImGui::Button("Save + bake")) music_save();
    at_track("mus:save");
    ImGui::EndDisabled();
    if (ImGui::IsItemHovered(ImGuiHoveredFlags_AllowWhenDisabled))
        ImGui::SetTooltip("Bakes the song next to its file (music.render: the mix and, when the song declares layers, "
                          "one stem per layer). Ctrl+S while this panel has the keyboard.\n"
                          "Every edit is already written to the song file; baking is what changes the audio the game "
                          "plays when it plays stems.");
    ImGui::SameLine();
    ImGui::Checkbox("Replace foreign file", &u.overwriteBaked);
    at_track("mus:overwrite");
    if (ImGui::IsItemHovered())
        ImGui::SetTooltip("Bake over a sound file that nothing of ours made (no recipe in assets.json). Off: the bake "
                          "stops with a message instead.");
    ImGui::SameLine();
    if (ImGui::Button("Reload")) m.reload();
    at_track("mus:reload");
    if (ImGui::IsItemHovered()) ImGui::SetTooltip("Reads the file again; the undo steps stay.");
    if (m.busy()) {
        ImGui::SameLine();
        ImGui::TextDisabled("rendering...");
    }
    if (!m.status().empty()) {
        ImGui::SameLine();
        ImGui::TextDisabled("%s", m.status().c_str());
    }
}

// ----------------------------------------------------------------------------------------------------------- transport --
void Editor::music_play(int section, bool loop) {
    MusicUi& u = music_;
    if (!u.model || !u.model->is_open() || !u.model->valid()) return;
    MusicSourcePtr src = u.model->source();
    if (!src) {
        u.pendingSection = section;  // the first render is not ready: play when it is
        u.pendingLoop = loop;
        u.model->request_render();
        return;
    }
    if (section >= int(src->map.sections.size())) section = -1;
    if (!u.preview->play(src, section, u.intensity)) {
        notify("The song could not be played: " + u.preview->error(), 1);
        return;
    }
    u.preview->set_loop_section(loop && section >= 0 ? section : -1);
}

void Editor::music_toggle_play() {
    MusicUi& u = music_;
    if (!u.model || !u.model->is_open()) return;
    if (u.preview->playing() || u.pendingSection != -2) {
        u.preview->stop();
        u.pendingSection = -2;
        return;
    }
    music_play(-1, false);
}

void Editor::draw_music_transport(MusicModel& m) {
    MusicUi& u = music_;
    const SongDoc* doc = m.doc();
    const bool playing = u.preview->playing();
    if (ImGui::Button(playing ? "Stop" : "Play", ImVec2(60, 0))) music_toggle_play();
    at_track("mus:play");
    if (ImGui::IsItemHovered())
        ImGui::SetTooltip("Plays the song from the start with the layers at the intensity below (the same player a "
                          "game's entity.music uses). Space while this panel has the keyboard.");
    ImGui::SameLine();
    const int nsec = doc ? int(doc->sections.size()) : 0;
    u.section = std::clamp(u.section, 0, std::max(0, nsec - 1));
    ImGui::SetNextItemWidth(130);
    if (ImGui::BeginCombo("##mussection",
                          nsec > 0 ? doc->sections[std::size_t(u.section)].name.c_str() : "(no sections)")) {
        for (int i = 0; i < nsec; ++i) {
            if (ImGui::Selectable(doc->sections[std::size_t(i)].name.c_str(), i == u.section)) u.section = i;
            at_track("mus:section:" + doc->sections[std::size_t(i)].name);
        }
        ImGui::EndCombo();
    }
    at_track("mus:section");
    if (ImGui::IsItemHovered())
        ImGui::SetTooltip("The section Play section and Loop mean. The Arrangement tab selects one too.");
    ImGui::SameLine();
    ImGui::BeginDisabled(nsec == 0);
    if (ImGui::Button("Play section")) music_play(u.section, u.loopSection);
    at_track("mus:play_section");
    ImGui::EndDisabled();
    if (ImGui::IsItemHovered(ImGuiHoveredFlags_AllowWhenDisabled))
        ImGui::SetTooltip("Starts at the first pass of the section (a section is the granularity of play-from-here).");
    ImGui::SameLine();
    if (ImGui::Checkbox("Loop", &u.loopSection) && playing) {
        const MusicPreview::Where w = u.preview->where();
        u.preview->set_loop_section(u.loopSection ? (w.section >= 0 ? w.section : u.section) : -1);
    }
    at_track("mus:loop");
    if (ImGui::IsItemHovered())
        ImGui::SetTooltip("Plays the section again and again: when a pass of it ends it starts over.");
    ImGui::SameLine(0, 18);

    // The readout keeps a fixed width so the widgets after it stay put while the playhead's digits change.
    const float readoutX = ImGui::GetCursorPosX();
    std::string where = "stopped";
    if (playing || u.preview->position_frames() > 0.0) {
        const MusicPreview::Where w = u.preview->where();
        const std::string sec =
            (w.section >= 0 && u.preview->source() && std::size_t(w.section) < u.preview->source()->map.sections.size())
                ? u.preview->source()->map.sections[std::size_t(w.section)].name
                : "-";
        where = std::format("bar {} beat {}  {}  {}", w.bar, w.beat,
                            music_ui::seconds_text(u.preview->position_seconds()), sec);
    }
    ImGui::TextDisabled("%s", where.c_str());
    ImGui::SameLine(readoutX + ImGui::CalcTextSize("bar 000 beat 0  00:00.0  mmmmmmmmmm").x);
    ImGui::Dummy(ImVec2(0, 0));

    // Intensity: the layers of the song fade in and out with it, as they do in the game.
    const MusicSourcePtr src = m.source();
    const bool layered = src && src->layered;
    ImGui::BeginDisabled(!layered);
    // The intensity group stays on the transport's line when it fits, and starts the next line in a narrow panel (a small
    // screen), where it would run past the panel's right edge.
    const ImGuiStyle& style = ImGui::GetStyle();
    float groupW = 18.0f + 170.0f;
    for (const char* label : {"Calm", "Tense", "Intense"})
        groupW += style.ItemSpacing.x + ImGui::CalcTextSize(label).x + style.FramePadding.x * 2.0f;
    if (ImGui::GetItemRectMax().x + groupW <= ImGui::GetWindowPos().x + ImGui::GetWindowContentRegionMax().x)
        ImGui::SameLine(0, 18);
    ImGui::SetNextItemWidth(170);
    if (ImGui::SliderFloat("##musintensity", &u.intensity, 0.0f, 1.0f, "intensity %.2f") && playing)
        u.preview->set_intensity(u.intensity);
    at_track("mus:intensity", layered);
    for (const auto& [label, v, id] : {std::tuple<const char*, float, const char*>{"Calm", 0.0f, "mus:int_0"},
                                       {"Tense", 0.5f, "mus:int_half"},
                                       {"Intense", 1.0f, "mus:int_1"}}) {
        ImGui::SameLine();
        if (ImGui::SmallButton(label)) {
            u.intensity = v;
            if (playing) u.preview->set_intensity(v);
        }
        at_track(id, layered);
    }
    ImGui::EndDisabled();
    if (ImGui::IsItemHovered(ImGuiHoveredFlags_AllowWhenDisabled))
        ImGui::SetTooltip(
            layered
                ? "0 plays the base layer only; each layer fades in from its own intensity (the Arrangement tab sets "
                  "them). The game sets this with entity.music.setIntensity."
                : "This song has no layers, so the intensity changes nothing. Declare layers in the Arrangement tab.");
    if (layered && playing) {
        const std::vector<float> gains = u.preview->stem_gains();
        const MusicSource* ps = u.preview->source();
        if (ps) {
            for (std::size_t i = 0; i < ps->stems.size() && i < gains.size(); ++i) {
                ImGui::SameLine();
                ImGui::ProgressBar(gains[i], ImVec2(46, ImGui::GetFrameHeight() * 0.6f), "");
                if (ImGui::IsItemHovered())
                    ImGui::SetTooltip("layer %s: %.0f%%", ps->stems[i].name.c_str(), double(gains[i]) * 100.0);
            }
        }
    }
}

// ----------------------------------------------------------------------------------------------------------- piano roll --
namespace {

using music_ui::kGutter;
using music_ui::kRowH;

const music_ui::SnapChoice kSnaps[] = {{"1/1", 4 * kSongPpq},  {"1/2", 2 * kSongPpq},  {"1/4", kSongPpq},
                                       {"1/8", kSongPpq / 2},  {"1/16", kSongPpq / 4}, {"1/32", kSongPpq / 8},
                                       {"1/8t", kSongPpq / 3}, {"1/16t", kSongPpq / 6}};

std::int64_t floor_to(double v, std::int64_t unit) { return std::int64_t(std::floor(v / double(unit))) * unit; }
std::int64_t round_to(double v, std::int64_t unit) { return std::int64_t(std::llround(v / double(unit))) * unit; }
std::int64_t ceil_to(double v, std::int64_t unit) { return std::int64_t(std::ceil(v / double(unit) - 1e-9)) * unit; }

// Notes cut to a pattern of `lengthTicks`: the ones that start past the end are dropped, the ones that run past it end there.
std::vector<SongRollNote> clipped(const std::vector<SongRollNote>& notes, std::int64_t lengthTicks) {
    std::vector<SongRollNote> out;
    for (SongRollNote n : notes) {
        if (n.tick >= lengthTicks) continue;
        n.duration = std::min(n.duration, lengthTicks - n.tick);
        if (n.duration > 0) out.push_back(n);
    }
    return out;
}

const char* kDirections[] = {"up", "down", "updown", "downup", "random"};
const int kRates[] = {4, 8, 16, 32};

}  // namespace

void Editor::draw_music_roll(MusicModel& m) {
    MusicUi& u = music_;
    if (!m.doc()) return;
    // This frame's song, copied: an edit below replaces the model's (sections, patterns), and a reference into that
    // would dangle for the rest of the frame.
    const SongDoc docNow = *m.doc();
    const SongDoc* doc = &docNow;
    const bool canEdit = play_ == PlayState::Edit;
    const std::vector<std::string> tracks = m.pitched_tracks();
    if (tracks.empty()) {
        ImGui::TextWrapped(
            "This song has no pitched track. The Mixer tab adds one; the Drums tab edits the drum tracks.");
        return;
    }
    if (std::find(tracks.begin(), tracks.end(), u.track) == tracks.end()) {
        u.track = tracks.front();
        u.pattern.clear();
        u.pitchTop = 0;
    }
    const SongTrack* track = m.track(u.track);
    if (!track || track->patterns.empty()) return;
    if (!track->find_pattern(u.pattern)) {
        u.pattern = track->patterns.front().name;
        u.pitchTop = 0;
    }
    const SongPattern* pat = track->find_pattern(u.pattern);

    // ---- the row of controls
    ImGui::SetNextItemWidth(110);
    if (ImGui::BeginCombo("##rolltrack", u.track.c_str())) {
        for (const std::string& t : tracks) {
            if (ImGui::Selectable(t.c_str(), t == u.track)) {
                u.track = t;
                u.pattern.clear();
                u.pitchTop = 0;
                u.sel.clear();
            }
            at_track("mus:track:" + t);
        }
        ImGui::EndCombo();
    }
    at_track("mus:track");
    ImGui::SameLine();
    ImGui::SetNextItemWidth(110);
    if (ImGui::BeginCombo("##rollpattern", u.pattern.c_str())) {
        for (const SongPattern& p : track->patterns) {
            if (ImGui::Selectable(p.name.c_str(), p.name == u.pattern)) {
                u.pattern = p.name;
                u.pitchTop = 0;
                u.sel.clear();
            }
            at_track("mus:pattern:" + p.name);
        }
        ImGui::EndCombo();
    }
    at_track("mus:pattern");
    if (ImGui::IsItemHovered())
        ImGui::SetTooltip("The patterns of the track. A section plays them in order (the Arrangement tab).");
    ImGui::SameLine();
    ImGui::BeginDisabled(!canEdit);
    if (ImGui::SmallButton("New pattern")) {
        std::vector<std::string> names;
        for (const SongPattern& p : track->patterns) names.push_back(p.name);
        const std::string name = m.free_name("pattern", names);
        const MusicEditOutcome out = m.add_pattern(u.track, name, pat ? pat->bars : 1, false);
        music_edited(out);
        if (out.ok) {
            u.pattern = name;
            u.pitchTop = 0;
        }
    }
    at_track("mus:new_pattern");
    ImGui::SameLine();
    if (ImGui::SmallButton("Remove pattern")) {
        const std::string gone = u.pattern;
        const MusicEditOutcome out = m.remove_pattern(u.track, gone);
        music_edited(out);
        if (out.ok) u.pattern.clear();
    }
    at_track("mus:remove_pattern");
    ImGui::SameLine();
    ImGui::TextDisabled("bars");
    ImGui::SameLine();
    const std::int64_t length = pat ? pat->lengthTicks : 0;
    if (ImGui::SmallButton("-##bars") && pat && pat->bars > 1) {
        const std::int64_t newLen = std::int64_t(pat->bars - 1) * doc->meter.barTicks();
        music_edited(m.set_notes(u.track, u.pattern, clipped(m.notes(u.track, u.pattern), newLen), pat->bars - 1,
                                 "Shorten pattern"));
    }
    at_track("mus:bars_minus");
    ImGui::SameLine();
    ImGui::Text("%d", pat ? pat->bars : 0);
    ImGui::SameLine();
    if (ImGui::SmallButton("+##bars") && pat && pat->bars < kSongMaxBars)
        music_edited(m.set_notes(u.track, u.pattern, m.notes(u.track, u.pattern), pat->bars + 1, "Lengthen pattern"));
    at_track("mus:bars_plus");
    ImGui::EndDisabled();
    ImGui::SameLine(0, 18);
    ImGui::SetNextItemWidth(70);
    u.snap = std::clamp(u.snap, 0, int(std::size(kSnaps)) - 1);
    if (ImGui::BeginCombo("##rollsnap", kSnaps[u.snap].label)) {
        for (int i = 0; i < int(std::size(kSnaps)); ++i) {
            if (ImGui::Selectable(kSnaps[i].label, i == u.snap)) u.snap = i;
            at_track(std::string("mus:snap:") + kSnaps[i].label);
        }
        ImGui::EndCombo();
    }
    at_track("mus:snap");
    if (ImGui::IsItemHovered())
        ImGui::SetTooltip("The grid notes snap to when they are drawn, moved and resized. Written notes are rounded to "
                          "40 ticks (a 1/24 of a quarter note).");
    ImGui::SameLine();
    ImGui::SetNextItemWidth(70);
    const bool velEdited = ImGui::DragInt("##rollvel", &u.velocity, 0.5f, 1, 127, "vel %d");
    at_track("mus:velocity");
    if (ImGui::IsItemHovered())
        ImGui::SetTooltip("The velocity a new note gets. With notes selected, letting go of the drag sets theirs too.");
    if (ImGui::IsItemDeactivatedAfterEdit() && velEdited && canEdit && !u.sel.empty() &&
        u.drag == MusicUi::Drag::None) {
        std::vector<SongRollNote> next = u.notes;
        for (int i : u.sel)
            if (i >= 0 && std::size_t(i) < next.size()) next[std::size_t(i)].velocity = u.velocity;
        std::vector<std::pair<std::int64_t, int>> keys;
        for (int i : u.sel)
            if (i >= 0 && std::size_t(i) < next.size())
                keys.emplace_back(next[std::size_t(i)].tick, next[std::size_t(i)].pitch);
        u.selKeys = keys;
        music_edited(m.set_notes(u.track, u.pattern, next, 0, "Set velocity"));
    }
    ImGui::SameLine();
    ImGui::Checkbox("Scale", &u.scaleHighlight);
    at_track("mus:scale");
    if (ImGui::IsItemHovered())
        ImGui::SetTooltip("Shades the rows that are not in the song's key (%s %s).", doc->key.c_str(),
                          doc->mode.c_str());
    ImGui::SameLine();
    if (ImGui::SmallButton("-##zoom")) u.pxPerBeat = std::max(16.0f, u.pxPerBeat / 1.25f);
    at_track("mus:zoom_out");
    ImGui::SameLine();
    if (ImGui::SmallButton("+##zoom")) u.pxPerBeat = std::min(240.0f, u.pxPerBeat * 1.25f);
    at_track("mus:zoom_in");
    ImGui::SameLine();
    if (ImGui::SmallButton("Up")) u.pitchTop = std::min(127, u.pitchTop + 12);
    at_track("mus:octave_up");
    ImGui::SameLine();
    if (ImGui::SmallButton("Down")) u.pitchTop = std::max(music_ui::kRows, u.pitchTop - 12);
    at_track("mus:octave_down");

    if (!pat || pat->lengthTicks <= 0) return;

    // ---- the notes: the model's, or the working copy while one is being dragged
    const std::string key = u.track + "/" + u.pattern;
    if (u.drag == MusicUi::Drag::None && (key != u.notesKey || m.doc_revision() != u.notesRev)) {
        u.notes = m.notes(u.track, u.pattern);
        u.notesKey = key;
        u.notesRev = m.doc_revision();
        std::set<int> found;
        for (const auto& [tick, pitch] : u.selKeys)
            for (std::size_t i = 0; i < u.notes.size(); ++i)
                if (u.notes[i].pitch == pitch && std::llabs(u.notes[i].tick - tick) <= 40) found.insert(int(i));
        u.sel = found;
        u.selKeys.clear();
    }
    if (u.pitchTop <= 0) {
        int lo = 127, hi = 0;
        for (const SongRollNote& n : u.notes) {
            lo = std::min(lo, n.pitch);
            hi = std::max(hi, n.pitch);
        }
        const int centre = u.notes.empty() ? 60 : (lo + hi) / 2;
        u.pitchTop = std::clamp(centre + music_ui::kRows / 2, music_ui::kRows, 127);
    }
    std::vector<SongRollNote>& shown = u.drag == MusicUi::Drag::None ? u.notes : u.work;

    // ---- the canvas
    const float px = u.pxPerBeat / float(kSongPpq);
    const float lenPx = float(length) * px;
    const float rulerH = music_ui::kRulerH, rollH = float(music_ui::kRows) * kRowH, velH = music_ui::kVelH;
    ImGui::BeginChild("##musicroll", ImVec2(0, rulerH + rollH + velH + 28), false,
                      ImGuiWindowFlags_HorizontalScrollbar);
    const ImVec2 origin = ImGui::GetCursorScreenPos();
    ImDrawList* dl = ImGui::GetWindowDrawList();
    const float x0 = origin.x, y0 = origin.y + rulerH;
    u.rollX0 = x0;
    u.rollY0 = y0;
    u.rollW = kGutter + lenPx;
    u.rollH = rollH;
    ImGui::InvisibleButton("##rollhit", ImVec2(kGutter + lenPx + 24, rulerH + rollH),
                           ImGuiButtonFlags_MouseButtonLeft | ImGuiButtonFlags_MouseButtonRight);
    const bool rollHot = ImGui::IsItemHovered();
    const bool rollActive = ImGui::IsItemActive();
    const bool rollPressed = rollHot && ImGui::IsMouseClicked(ImGuiMouseButton_Left);
    const bool rollRightClick = rollHot && ImGui::IsMouseClicked(ImGuiMouseButton_Right);
    const bool rollReleased = ImGui::IsItemDeactivated();
    at_track("mus:roll");
    const ImVec2 velOrigin = ImGui::GetCursorScreenPos();
    ImGui::InvisibleButton("##velhit", ImVec2(kGutter + lenPx + 24, velH), ImGuiButtonFlags_MouseButtonLeft);
    const bool velHot = ImGui::IsItemHovered();
    const bool velActive = ImGui::IsItemActive();
    const bool velPressed = velHot && ImGui::IsMouseClicked(ImGuiMouseButton_Left);
    const bool velReleased = ImGui::IsItemDeactivated();
    at_track("mus:velocity_lane");

    const ImVec2 mp = ImGui::GetMousePos();
    auto mouse_tick = [&] { return double(mp.x - x0 - kGutter) / double(px); };
    auto mouse_pitch = [&] { return u.pitchTop - int(std::floor((mp.y - y0) / kRowH)); };
    auto tick_x = [&](double t) { return x0 + kGutter + float(t) * px; };
    auto pitch_y = [&](int p) { return y0 + float(u.pitchTop - p) * kRowH; };
    const std::int64_t snapT = kSnaps[u.snap].ticks;
    const ImGuiIO& io = ImGui::GetIO();

    // ---- press
    if (canEdit && rollPressed && u.drag == MusicUi::Drag::None && mp.x >= x0 + kGutter) {
        const double mt = mouse_tick();
        const int pitch = mouse_pitch();
        u.work = u.notes;
        u.orig = u.notes;
        u.dragChanged = false;
        int hit = -1;
        for (std::size_t i = 0; i < u.notes.size(); ++i) {
            const SongRollNote& n = u.notes[i];
            if (n.pitch == pitch && mt >= double(n.tick) && mt < double(n.tick + n.duration)) hit = int(i);
        }
        u.cursorTick = std::max<std::int64_t>(0, floor_to(mt, snapT));
        if (hit >= 0) {
            const SongRollNote& n = u.notes[std::size_t(hit)];
            const bool edge =
                double(n.tick + n.duration - mt) * double(px) < 7.0 && double(n.duration) * double(px) > 16.0;
            if (io.KeyShift) {
                if (u.sel.count(hit))
                    u.sel.erase(hit);
                else
                    u.sel.insert(hit);
            } else if (!u.sel.count(hit)) {
                u.sel = {hit};
            }
            u.dragNote = hit;
            u.anchorTick = std::int64_t(mt);
            u.anchorPitch = pitch;
            u.drag = edge ? MusicUi::Drag::Resize : MusicUi::Drag::Move;
        } else if (pitch >= 0 && pitch <= 127 && mt >= 0.0 && mt < double(length)) {
            SongRollNote nn;
            nn.tick = std::clamp<std::int64_t>(floor_to(mt, snapT), 0, length - snapT);
            nn.duration = std::min<std::int64_t>(snapT, length - nn.tick);
            nn.pitch = pitch;
            nn.velocity = u.velocity;
            u.work.push_back(nn);
            u.dragNote = int(u.work.size()) - 1;
            u.sel = {u.dragNote};
            u.anchorTick = nn.tick;
            u.anchorPitch = pitch;
            u.dragChanged = true;
            u.drag = MusicUi::Drag::Draw;
        } else {
            u.sel.clear();
        }
        shown = u.drag == MusicUi::Drag::None ? u.notes : u.work;
    } else if (canEdit && velPressed && u.drag == MusicUi::Drag::None) {
        int best = -1;
        float bestD = 6.0f;
        for (std::size_t i = 0; i < u.notes.size(); ++i) {
            const float d = std::fabs(mp.x - tick_x(double(u.notes[i].tick)) - 2.0f);
            if (d < bestD) {
                bestD = d;
                best = int(i);
            }
        }
        if (best >= 0) {
            u.work = u.notes;
            u.orig = u.notes;
            u.dragChanged = false;
            u.dragNote = best;
            if (!u.sel.count(best)) u.sel = {best};
            u.drag = MusicUi::Drag::Velocity;
        }
    }

    // ---- drag
    if (u.drag != MusicUi::Drag::None && (rollActive || velActive) && ImGui::IsMouseDown(ImGuiMouseButton_Left)) {
        const double mt = mouse_tick();
        const int pitch = mouse_pitch();
        std::vector<SongRollNote>& w = u.work;
        switch (u.drag) {
            case MusicUi::Drag::Move: {
                const std::int64_t dt = round_to(mt - double(u.anchorTick), snapT);
                const int dp = pitch - u.anchorPitch;
                for (int i : u.sel) {
                    if (i < 0 || std::size_t(i) >= w.size() || std::size_t(i) >= u.orig.size()) continue;
                    w[std::size_t(i)].tick =
                        std::clamp<std::int64_t>(u.orig[std::size_t(i)].tick + dt, 0,
                                                 std::max<std::int64_t>(0, length - u.orig[std::size_t(i)].duration));
                    w[std::size_t(i)].pitch = std::clamp(u.orig[std::size_t(i)].pitch + dp, 0, 127);
                }
                break;
            }
            case MusicUi::Drag::Resize: {
                if (u.dragNote < 0 || std::size_t(u.dragNote) >= u.orig.size()) break;
                const SongRollNote& o = u.orig[std::size_t(u.dragNote)];
                const std::int64_t delta = round_to(mt, snapT) - (o.tick + o.duration);
                for (int i : u.sel) {
                    if (i < 0 || std::size_t(i) >= w.size() || std::size_t(i) >= u.orig.size()) continue;
                    const SongRollNote& oi = u.orig[std::size_t(i)];
                    w[std::size_t(i)].duration =
                        std::clamp<std::int64_t>(oi.duration + delta, snapT, std::max(snapT, length - oi.tick));
                }
                break;
            }
            case MusicUi::Drag::Draw: {
                if (u.dragNote < 0 || std::size_t(u.dragNote) >= w.size()) break;
                SongRollNote& n = w[std::size_t(u.dragNote)];
                n.duration =
                    std::clamp<std::int64_t>(ceil_to(mt, snapT) - n.tick, snapT, std::max(snapT, length - n.tick));
                break;
            }
            case MusicUi::Drag::Velocity: {
                if (u.dragNote < 0 || std::size_t(u.dragNote) >= w.size()) break;
                const int v = std::clamp(int(std::lround((1.0f - (mp.y - velOrigin.y) / velH) * 127.0f)), 1, 127);
                if (u.sel.count(u.dragNote)) {
                    for (int i : u.sel)
                        if (i >= 0 && std::size_t(i) < w.size()) w[std::size_t(i)].velocity = v;
                } else {
                    w[std::size_t(u.dragNote)].velocity = v;
                }
                break;
            }
            case MusicUi::Drag::None: break;
        }
        bool changed = w.size() != u.orig.size();
        for (std::size_t i = 0; !changed && i < w.size(); ++i)
            changed = w[i].tick != u.orig[i].tick || w[i].pitch != u.orig[i].pitch ||
                      w[i].duration != u.orig[i].duration || w[i].velocity != u.orig[i].velocity;
        u.dragChanged = changed;
    }

    // ---- release: ONE edit for the whole drag
    if (u.drag != MusicUi::Drag::None && (rollReleased || velReleased || !ImGui::IsMouseDown(ImGuiMouseButton_Left))) {
        const MusicUi::Drag kind = u.drag;
        u.drag = MusicUi::Drag::None;
        if (u.dragChanged) {
            std::vector<std::pair<std::int64_t, int>> keys;
            for (int i : u.sel)
                if (i >= 0 && std::size_t(i) < u.work.size())
                    keys.emplace_back(u.work[std::size_t(i)].tick, u.work[std::size_t(i)].pitch);
            const char* label = kind == MusicUi::Drag::Draw     ? "Draw note"
                                : kind == MusicUi::Drag::Move   ? "Move notes"
                                : kind == MusicUi::Drag::Resize ? "Resize notes"
                                                                : "Set velocity";
            const MusicEditOutcome out = m.set_notes(u.track, u.pattern, u.work, 0, label);
            music_edited(out);
            if (out.ok)
                u.selKeys = keys;
            else
                u.notesKey.clear();
        }
        u.dragChanged = false;
        shown = u.notes;
    }

    // ---- delete: right click on a note, or the Delete key
    if (canEdit && u.drag == MusicUi::Drag::None) {
        std::set<int> doomed;
        if (rollRightClick && mp.x >= x0 + kGutter) {
            const double mt = mouse_tick();
            const int pitch = mouse_pitch();
            for (std::size_t i = 0; i < u.notes.size(); ++i)
                if (u.notes[i].pitch == pitch && mt >= double(u.notes[i].tick) &&
                    mt < double(u.notes[i].tick + u.notes[i].duration))
                    doomed.insert(int(i));
        } else if (u.focused && !io.WantTextInput && !u.sel.empty() &&
                   (ImGui::IsKeyPressed(ImGuiKey_Delete, false) || ImGui::IsKeyPressed(ImGuiKey_Backspace, false))) {
            doomed = u.sel;
        }
        if (!doomed.empty()) {
            std::vector<SongRollNote> next;
            for (std::size_t i = 0; i < u.notes.size(); ++i)
                if (!doomed.count(int(i))) next.push_back(u.notes[i]);
            u.sel.clear();
            const MusicEditOutcome out =
                m.set_notes(u.track, u.pattern, next, 0, doomed.size() > 1 ? "Delete notes" : "Delete note");
            music_edited(out);
            u.notesKey.clear();
        }
    }

    // ---- draw: rows
    const std::vector<int> scale = doc->scale_pitch_classes();
    for (int r = 0; r < music_ui::kRows; ++r) {
        const int pitch = u.pitchTop - r;
        if (pitch < 0 || pitch > 127) continue;
        const int pc = pitch % 12;
        const bool black = pc == 1 || pc == 3 || pc == 6 || pc == 8 || pc == 10;
        const bool inKey = !u.scaleHighlight || music_in_scale(*doc, pitch);
        ImU32 col = black ? IM_COL32(30, 32, 38, 255) : IM_COL32(40, 43, 51, 255);
        if (!inKey)
            col = black ? IM_COL32(22, 23, 27, 255) : IM_COL32(29, 30, 35, 255);
        else if (u.scaleHighlight && pc == doc->keyRoot)
            col = IM_COL32(48, 58, 84, 255);
        const float y = y0 + float(r) * kRowH;
        dl->AddRectFilled(ImVec2(x0 + kGutter, y), ImVec2(x0 + kGutter + lenPx, y + kRowH), col);
        if (pc == 0)
            dl->AddLine(ImVec2(x0 + kGutter, y + kRowH), ImVec2(x0 + kGutter + lenPx, y + kRowH),
                        IM_COL32(70, 74, 88, 255));
    }
    (void)scale;
    // grid lines: snap (faint), beats, bars
    const std::int64_t beatT = doc->meter.beatTicks(), barT = doc->meter.barTicks();
    for (std::int64_t t = 0; t <= length; t += snapT) {
        const bool bar = t % barT == 0, beat = t % beatT == 0;
        const ImU32 c = bar    ? IM_COL32(150, 156, 176, 255)
                        : beat ? IM_COL32(86, 90, 106, 255)
                               : IM_COL32(56, 59, 70, 255);
        dl->AddLine(ImVec2(tick_x(double(t)), y0), ImVec2(tick_x(double(t)), y0 + rollH), c);
    }
    for (std::int64_t t = 0; t < length; t += barT) {
        dl->AddText(ImVec2(tick_x(double(t)) + 3, origin.y), IM_COL32(190, 195, 210, 255),
                    std::to_string(t / barT + 1).c_str());
        dl->AddLine(ImVec2(tick_x(double(t)), origin.y), ImVec2(tick_x(double(t)), y0), IM_COL32(150, 156, 176, 255));
    }
    // notes
    for (std::size_t i = 0; i < shown.size(); ++i) {
        const SongRollNote& n = shown[i];
        if (n.pitch > u.pitchTop || n.pitch <= u.pitchTop - music_ui::kRows) continue;
        const float xa = tick_x(double(n.tick)), xb = std::max(xa + 3.0f, tick_x(double(n.tick + n.duration)) - 1.0f);
        const float ya = pitch_y(n.pitch);
        const float v = float(n.velocity) / 127.0f;
        const ImU32 fill = IM_COL32(int(70 + 120 * v), int(150 + 70 * v), int(200 - 40 * v), 255);
        dl->AddRectFilled(ImVec2(xa, ya + 1), ImVec2(xb, ya + kRowH - 1), fill, 2.0f);
        if (n.staccato) dl->AddRectFilled(ImVec2(xa + 1, ya + 4), ImVec2(xa + 4, ya + 7), IM_COL32(20, 20, 30, 255));
        if (n.accent) dl->AddText(ImVec2(xa + 2, ya - 2), IM_COL32(255, 255, 255, 255), "!");
        dl->AddRect(ImVec2(xa, ya + 1), ImVec2(xb, ya + kRowH - 1),
                    u.sel.count(int(i)) ? IM_COL32(255, 255, 255, 255) : IM_COL32(20, 30, 50, 255), 2.0f);
    }
    // the cursor and the playhead
    dl->AddLine(ImVec2(tick_x(double(u.cursorTick)), y0), ImVec2(tick_x(double(u.cursorTick)), y0 + rollH),
                IM_COL32(255, 210, 90, 160), 1.0f);
    if (u.preview->playing() && u.preview->source()) {
        if (auto t = m.pattern_tick(u.preview->source()->map, u.preview->position_frames(), u.track, u.pattern)) {
            const float x = tick_x(*t);
            dl->AddLine(ImVec2(x, origin.y), ImVec2(x, y0 + rollH + velH), IM_COL32(255, 90, 90, 255), 2.0f);
        }
    }
    // the velocity lane
    dl->AddRectFilled(ImVec2(x0 + kGutter, velOrigin.y), ImVec2(x0 + kGutter + lenPx, velOrigin.y + velH),
                      IM_COL32(26, 28, 34, 255));
    for (std::size_t i = 0; i < shown.size(); ++i) {
        const SongRollNote& n = shown[i];
        const float xa = tick_x(double(n.tick));
        const float h = velH * float(n.velocity) / 127.0f;
        dl->AddRectFilled(ImVec2(xa, velOrigin.y + velH - h), ImVec2(xa + 4, velOrigin.y + velH),
                          u.sel.count(int(i)) ? IM_COL32(255, 255, 255, 255) : IM_COL32(110, 190, 240, 255));
    }
    // the pitch names on the left: they stay put while the roll scrolls sideways
    const float labelX = ImGui::GetWindowPos().x;
    dl->AddRectFilled(ImVec2(labelX, y0), ImVec2(labelX + kGutter - 2, y0 + rollH), IM_COL32(24, 26, 32, 255));
    for (int r = 0; r < music_ui::kRows; ++r) {
        const int pitch = u.pitchTop - r;
        if (pitch < 0 || pitch > 127) continue;
        const bool root = pitch % 12 == doc->keyRoot;
        if (pitch % 12 == 0 || root)
            dl->AddText(ImVec2(labelX + 3, y0 + float(r) * kRowH - 1),
                        root ? IM_COL32(150, 190, 255, 255) : IM_COL32(170, 175, 190, 255),
                        song_pitch_name(pitch).c_str());
    }
    ImGui::EndChild();

    // ---- helpers: a chord at the cursor, an arpeggio, a bass line
    ImGui::BeginDisabled(!canEdit);
    ImGui::SetNextItemWidth(90);
    music_ui::text_field("##chordname", u.chordName, 24);
    at_track("mus:chord_name");
    if (ImGui::IsItemHovered())
        ImGui::SetTooltip("A chord by name: Am7, Cmaj7/G, F#dim, Dsus4 (music.chord lists the spellings).");
    ImGui::SameLine();
    ImGui::SetNextItemWidth(50);
    ImGui::DragInt("##chordoct", &u.chordOctave, 0.1f, 0, 7, "oct %d");
    ImGui::SameLine();
    if (ImGui::Button("Insert chord")) {
        std::string why;
        const std::vector<int> pitches = m.chord_pitches(u.chordName, u.chordOctave, &why);
        if (pitches.empty()) {
            notify("Chord '" + u.chordName + "': " + why, 1);
        } else {
            std::vector<SongRollNote> next = m.notes(u.track, u.pattern);
            const std::int64_t at =
                std::clamp<std::int64_t>(u.cursorTick, 0, std::max<std::int64_t>(0, length - snapT));
            const std::int64_t dur = std::min<std::int64_t>(std::max(snapT, doc->meter.beatTicks()), length - at);
            for (int p : pitches) {
                SongRollNote n;
                n.tick = at;
                n.duration = dur;
                n.pitch = p;
                n.velocity = u.velocity;
                next.push_back(n);
            }
            music_edited(m.set_notes(u.track, u.pattern, next, 0, "Insert chord " + u.chordName));
        }
    }
    at_track("mus:insert_chord");
    if (ImGui::IsItemHovered(ImGuiHoveredFlags_AllowWhenDisabled))
        ImGui::SetTooltip("music.chord: the chord's notes are added at the yellow cursor (click in the roll to move "
                          "it), one beat long.");
    ImGui::SameLine(0, 18);
    if (u.progression.empty()) {
        const std::string& md = doc->mode;
        u.progression = (md == "minor" || md == "aeolian" || md == "dorian" || md == "phrygian" || md == "locrian")
                            ? "i VI III VII"
                            : "I V vi IV";
    }
    ImGui::SetNextItemWidth(140);
    music_ui::text_field("##progression", u.progression, 120);
    at_track("mus:progression");
    if (ImGui::IsItemHovered())
        ImGui::SetTooltip(
            "Chord names (Am F C G) or Roman numerals in the song's key (i VI III VII); *N holds a chord N bars.");
    ImGui::SameLine();
    ImGui::SetNextItemWidth(80);
    if (ImGui::BeginCombo("##arpdir", kDirections[u.arpDirection])) {
        for (int i = 0; i < int(std::size(kDirections)); ++i)
            if (ImGui::Selectable(kDirections[i], i == u.arpDirection)) u.arpDirection = i;
        ImGui::EndCombo();
    }
    ImGui::SameLine();
    ImGui::SetNextItemWidth(46);
    if (ImGui::BeginCombo("##arprate", std::to_string(kRates[u.arpRate]).c_str())) {
        for (int i = 0; i < int(std::size(kRates)); ++i)
            if (ImGui::Selectable(std::to_string(kRates[i]).c_str(), i == u.arpRate)) u.arpRate = i;
        ImGui::EndCombo();
    }
    ImGui::SameLine();
    if (ImGui::Button("Arpeggio")) {
        music_edited(m.generate("music.arpeggio", Json::object({{"progression", u.progression},
                                                                {"track", u.track},
                                                                {"pattern", u.pattern},
                                                                {"direction", kDirections[u.arpDirection]},
                                                                {"octaves", u.arpOctaves},
                                                                {"rate", kRates[u.arpRate]}})));
        u.notesKey.clear();
    }
    at_track("mus:arpeggio");
    if (ImGui::IsItemHovered(ImGuiHoveredFlags_AllowWhenDisabled))
        ImGui::SetTooltip("music.arpeggio: replaces this pattern with an arpeggio over the progression (direction and "
                          "note value as set).");
    ImGui::SameLine();
    const auto& bassStyles = song_bass_styles();
    u.bassStyle = std::clamp(u.bassStyle, 0, int(bassStyles.size()) - 1);
    ImGui::SetNextItemWidth(100);
    if (ImGui::BeginCombo("##bassstyle", bassStyles[std::size_t(u.bassStyle)].first.c_str())) {
        for (int i = 0; i < int(bassStyles.size()); ++i)
            if (ImGui::Selectable(bassStyles[std::size_t(i)].first.c_str(), i == u.bassStyle)) u.bassStyle = i;
        ImGui::EndCombo();
    }
    ImGui::SameLine();
    if (ImGui::Button("Bass line")) {
        music_edited(
            m.generate("music.bassline", Json::object({{"progression", u.progression},
                                                       {"track", u.track},
                                                       {"pattern", u.pattern},
                                                       {"style", bassStyles[std::size_t(u.bassStyle)].first}})));
        u.notesKey.clear();
    }
    at_track("mus:bassline");
    if (ImGui::IsItemHovered(ImGuiHoveredFlags_AllowWhenDisabled))
        ImGui::SetTooltip(
            "music.bassline: replaces this pattern with a bass part over the progression, in the style chosen.");
    ImGui::EndDisabled();
    ImGui::TextDisabled("Click to draw a note, drag to size it; drag a note to move it, its right edge to resize; "
                        "right click or Delete removes. Shift adds to the selection.");
}

// ----------------------------------------------------------------------------------------------------------- drum grid --
void Editor::draw_music_drums(MusicModel& m) {
    MusicUi& u = music_;
    if (!m.doc()) return;
    // This frame's song, copied: an edit below replaces the model's (sections, patterns), and a reference into that
    // would dangle for the rest of the frame.
    const SongDoc docNow = *m.doc();
    const SongDoc* doc = &docNow;
    const bool canEdit = play_ == PlayState::Edit;
    const std::vector<std::string> tracks = m.drum_tracks();
    if (tracks.empty()) {
        ImGui::TextWrapped("This song has no drum track (a track whose instrument is \"kit\"). music.drums with a path "
                           "adds one; the Mixer tab adds a track too.");
        return;
    }
    if (std::find(tracks.begin(), tracks.end(), u.drumTrack) == tracks.end()) {
        u.drumTrack = tracks.front();
        u.drumPattern.clear();
    }
    const SongTrack* track = m.track(u.drumTrack);
    if (!track || track->patterns.empty()) return;
    if (!track->find_pattern(u.drumPattern)) u.drumPattern = track->patterns.front().name;
    const SongPattern* pat = track->find_pattern(u.drumPattern);

    ImGui::SetNextItemWidth(110);
    if (ImGui::BeginCombo("##drumtrack", u.drumTrack.c_str())) {
        for (const std::string& t : tracks) {
            if (ImGui::Selectable(t.c_str(), t == u.drumTrack)) {
                u.drumTrack = t;
                u.drumPattern.clear();
            }
            at_track("mus:drumtrack:" + t);
        }
        ImGui::EndCombo();
    }
    at_track("mus:drumtrack");
    ImGui::SameLine();
    ImGui::SetNextItemWidth(110);
    if (ImGui::BeginCombo("##drumpattern", u.drumPattern.c_str())) {
        for (const SongPattern& p : track->patterns) {
            if (ImGui::Selectable(p.name.c_str(), p.name == u.drumPattern)) u.drumPattern = p.name;
            at_track("mus:drumpattern:" + p.name);
        }
        ImGui::EndCombo();
    }
    at_track("mus:drumpattern");
    ImGui::SameLine();
    ImGui::BeginDisabled(!canEdit);
    if (ImGui::SmallButton("New pattern##drum")) {
        std::vector<std::string> names;
        for (const SongPattern& p : track->patterns) names.push_back(p.name);
        const std::string name = m.free_name("groove", names);
        const MusicEditOutcome out = m.add_pattern(u.drumTrack, name, pat ? pat->bars : 1, true);
        music_edited(out);
        if (out.ok) u.drumPattern = name;
    }
    at_track("mus:new_drum_pattern");
    ImGui::SameLine();
    if (ImGui::SmallButton("Remove pattern##drum")) {
        const MusicEditOutcome out = m.remove_pattern(u.drumTrack, u.drumPattern);
        music_edited(out);
        if (out.ok) u.drumPattern.clear();
    }
    at_track("mus:remove_drum_pattern");
    ImGui::EndDisabled();

    std::optional<MusicDrumGrid> grid = pat ? music_drum_grid(*pat) : std::nullopt;
    if (!grid) {
        ImGui::TextWrapped("This pattern is written as note text, not as a drum grid, so the grid cannot show it. Edit "
                           "it with music.edit set_pattern, or replace it here with a grid.");
        ImGui::BeginDisabled(!canEdit);
        if (ImGui::Button("Replace with an empty grid")) {
            MusicDrumGrid g;
            g.bars = std::max(1, pat ? pat->bars : 1);
            g.lanes.emplace_back("kick", "");
            music_edited(m.set_grid(u.drumTrack, u.drumPattern, g, "Replace with a drum grid"));
        }
        at_track("mus:empty_grid");
        ImGui::EndDisabled();
        return;
    }
    const SongMeter& meter = doc->meter;
    ImGui::SameLine(0, 18);
    ImGui::TextDisabled("step");
    ImGui::SameLine();
    ImGui::SetNextItemWidth(60);
    ImGui::BeginDisabled(!canEdit);
    if (ImGui::BeginCombo("##drumstep", grid->step.c_str())) {
        for (const char* s : {"8", "16", "32", "8t", "16t"}) {
            if (ImGui::Selectable(s, grid->step == s) && grid->step != s) {
                // The same hits on a finer or coarser grid: a hit that falls between two steps of the new grid is dropped.
                MusicDrumGrid next = *grid;
                next.step = s;
                const std::int64_t oldT = music_step_ticks(grid->step), newT = music_step_ticks(s);
                next.lanes.clear();
                for (const auto& [lane, text] : grid->lanes) {
                    std::string row(std::size_t(next.total_steps(meter)), '.');
                    const std::string src = grid->row(lane, meter);
                    for (std::size_t i = 0; i < src.size(); ++i) {
                        if (src[i] == '.') continue;
                        const std::int64_t tick = std::int64_t(i) * oldT;
                        if (newT > 0 && tick % newT == 0 && std::size_t(tick / newT) < row.size())
                            row[std::size_t(tick / newT)] = src[i];
                    }
                    next.lanes.emplace_back(lane, row);
                }
                music_edited(m.set_grid(u.drumTrack, u.drumPattern, next, "Change drum step"));
            }
            at_track(std::string("mus:drumstep:") + s);
        }
        ImGui::EndCombo();
    }
    at_track("mus:drumstep");
    if (ImGui::IsItemHovered(ImGuiHoveredFlags_AllowWhenDisabled))
        ImGui::SetTooltip("The note value of one cell. Changing it keeps the hits that fall on a cell of the new grid "
                          "and drops the others.");
    ImGui::SameLine();
    ImGui::TextDisabled("bars");
    ImGui::SameLine();
    if (ImGui::SmallButton("-##drumbars") && grid->bars > 1) {
        MusicDrumGrid next = *grid;
        next.bars = grid->bars - 1;
        for (auto& [lane, text] : next.lanes)
            text = grid->row(lane, meter).substr(0, std::size_t(next.total_steps(meter)));
        music_edited(m.set_grid(u.drumTrack, u.drumPattern, next, "Shorten drum pattern"));
    }
    at_track("mus:drumbars_minus");
    ImGui::SameLine();
    ImGui::Text("%d", grid->bars);
    ImGui::SameLine();
    if (ImGui::SmallButton("+##drumbars") && grid->bars < kSongMaxBars) {
        MusicDrumGrid next = *grid;
        next.bars = grid->bars + 1;
        for (auto& [lane, text] : next.lanes) text = grid->row(lane, meter);
        music_edited(m.set_grid(u.drumTrack, u.drumPattern, next, "Lengthen drum pattern"));
    }
    at_track("mus:drumbars_plus");
    ImGui::SameLine();
    if (ImGui::SmallButton("Clear##grid")) {
        MusicDrumGrid next = *grid;
        for (auto& [lane, text] : next.lanes) text.assign(std::size_t(next.total_steps(meter)), '.');
        music_edited(m.set_grid(u.drumTrack, u.drumPattern, next, "Clear drum pattern"));
    }
    at_track("mus:drum_clear");
    ImGui::EndDisabled();

    // ---- the grid
    const int steps = grid->total_steps(meter);
    if (steps <= 0) {
        ImGui::TextColored(music_ui::kBad, "This pattern's step \"%s\" is not one the grid knows.", grid->step.c_str());
        return;
    }
    const float labelW = 78.0f, cellH = 22.0f;
    const float cellW = std::clamp((ImGui::GetContentRegionAvail().x - labelW - 24.0f) / float(steps), 10.0f, 34.0f);
    const int perBeat = std::max(1, int(meter.beatTicks() / std::max<std::int64_t>(1, music_step_ticks(grid->step))));
    const int perBar = grid->steps_per_bar(meter);
    u.gridLanes.clear();
    for (const auto& [lane, text] : grid->lanes) u.gridLanes.push_back(lane);
    const float gridH = cellH * float(std::max<std::size_t>(1, u.gridLanes.size()));
    const ImVec2 origin = ImGui::GetCursorScreenPos();
    u.gridX0 = origin.x + labelW;
    u.gridY0 = origin.y;
    u.cellW = cellW;
    u.cellH = cellH;
    ImGui::SetCursorScreenPos(ImVec2(origin.x + labelW, origin.y));
    ImGui::InvisibleButton("##drumgrid", ImVec2(cellW * float(steps), gridH),
                           ImGuiButtonFlags_MouseButtonLeft | ImGuiButtonFlags_MouseButtonRight);
    at_track("mus:drumgrid");
    const bool left = ImGui::IsItemHovered() && ImGui::IsMouseClicked(ImGuiMouseButton_Left);
    const bool right = ImGui::IsItemHovered() && ImGui::IsMouseClicked(ImGuiMouseButton_Right);
    ImDrawList* dl = ImGui::GetWindowDrawList();
    const ImVec2 mp = ImGui::GetMousePos();
    if (canEdit && (left || right) && !u.gridLanes.empty()) {
        const int col = int(std::floor((mp.x - u.gridX0) / cellW)), row = int(std::floor((mp.y - u.gridY0) / cellH));
        if (col >= 0 && col < steps && row >= 0 && row < int(u.gridLanes.size())) {
            const std::string& lane = u.gridLanes[std::size_t(row)];
            const char now = grid->at(lane, col, meter);
            const char next = right ? '.' : now == '.' ? 'x' : now == 'x' ? 'X' : now == 'X' ? 'o' : '.';
            MusicDrumGrid g = *grid;
            g.set(lane, col, next, meter);
            music_edited(m.set_grid(u.drumTrack, u.drumPattern, g,
                                    std::string("Drum ") + lane + " step " + std::to_string(col + 1)));
        }
    }
    for (std::size_t r = 0; r < u.gridLanes.size(); ++r) {
        const std::string& lane = u.gridLanes[r];
        const float y = u.gridY0 + float(r) * cellH;
        dl->AddText(ImVec2(origin.x + 2, y + 3), IM_COL32(200, 205, 220, 255), lane.c_str());
        for (int s = 0; s < steps; ++s) {
            const float x = u.gridX0 + float(s) * cellW;
            const bool onBeat = s % perBeat == 0;
            dl->AddRectFilled(ImVec2(x + 1, y + 1), ImVec2(x + cellW - 1, y + cellH - 1),
                              onBeat ? IM_COL32(52, 56, 68, 255) : IM_COL32(40, 43, 52, 255), 2.0f);
            const char c = grid->at(lane, s, meter);
            if (c == 'x')
                dl->AddRectFilled(ImVec2(x + 2, y + 2), ImVec2(x + cellW - 2, y + cellH - 2),
                                  IM_COL32(110, 190, 240, 255), 2.0f);
            else if (c == 'X')
                dl->AddRectFilled(ImVec2(x + 2, y + 2), ImVec2(x + cellW - 2, y + cellH - 2),
                                  IM_COL32(255, 200, 90, 255), 2.0f);
            else if (c == 'o')
                dl->AddCircleFilled(ImVec2(x + cellW * 0.5f, y + cellH * 0.5f), 3.0f, IM_COL32(150, 160, 190, 255));
        }
    }
    for (int s = 0; s <= steps; s += perBar)
        dl->AddLine(ImVec2(u.gridX0 + float(s) * cellW, u.gridY0),
                    ImVec2(u.gridX0 + float(s) * cellW, u.gridY0 + gridH), IM_COL32(170, 176, 196, 255), 2.0f);
    if (u.preview->playing() && u.preview->source()) {
        if (auto t =
                m.pattern_tick(u.preview->source()->map, u.preview->position_frames(), u.drumTrack, u.drumPattern)) {
            const float x = u.gridX0 + float(*t / double(music_step_ticks(grid->step))) * cellW;
            dl->AddLine(ImVec2(x, u.gridY0 - 4), ImVec2(x, u.gridY0 + gridH + 4), IM_COL32(255, 90, 90, 255), 2.0f);
        }
    }
    ImGui::SetCursorScreenPos(ImVec2(origin.x, origin.y + gridH + 8));
    ImGui::TextDisabled("Click a cell: hit, accent, ghost note, empty. Right click clears it. Lines mark bars.");

    // ---- lanes and styles
    ImGui::BeginDisabled(!canEdit);
    std::vector<std::string> free;
    for (const SongDrumLane& l : song_drum_lanes())
        if (std::find(u.gridLanes.begin(), u.gridLanes.end(), l.name) == u.gridLanes.end()) free.push_back(l.name);
    if (!free.empty() && std::find(free.begin(), free.end(), u.newLane) == free.end()) u.newLane = free.front();
    ImGui::SetNextItemWidth(110);
    if (ImGui::BeginCombo("##newlane", u.newLane.c_str())) {
        for (const std::string& l : free) {
            if (ImGui::Selectable(l.c_str(), l == u.newLane)) u.newLane = l;
            at_track("mus:lane:" + l);
        }
        ImGui::EndCombo();
    }
    ImGui::SameLine();
    if (ImGui::Button("Add lane") && !free.empty()) {
        MusicDrumGrid g = *grid;
        g.lanes.emplace_back(u.newLane, std::string(std::size_t(steps), '.'));
        music_edited(m.set_grid(u.drumTrack, u.drumPattern, g, "Add drum lane " + u.newLane));
    }
    at_track("mus:add_lane");
    ImGui::SameLine();
    if (ImGui::Button("Remove last lane") && !grid->lanes.empty()) {
        MusicDrumGrid g = *grid;
        const std::string gone = g.lanes.back().first;
        g.lanes.pop_back();
        music_edited(m.set_grid(u.drumTrack, u.drumPattern, g, "Remove drum lane " + gone));
    }
    at_track("mus:remove_lane");
    ImGui::SameLine(0, 18);
    const auto& styles = song_drum_styles();
    u.drumStyle = std::clamp(u.drumStyle, 0, int(styles.size()) - 1);
    ImGui::SetNextItemWidth(110);
    if (ImGui::BeginCombo("##drumstyle", styles[std::size_t(u.drumStyle)].name.c_str())) {
        for (int i = 0; i < int(styles.size()); ++i) {
            if (ImGui::Selectable(styles[std::size_t(i)].name.c_str(), i == u.drumStyle)) u.drumStyle = i;
            if (ImGui::IsItemHovered()) ImGui::SetTooltip("%s", styles[std::size_t(i)].what.c_str());
        }
        ImGui::EndCombo();
    }
    ImGui::SameLine();
    ImGui::Checkbox("Fill", &u.drumFill);
    ImGui::SameLine();
    if (ImGui::Button("Generate")) {
        music_edited(m.generate("music.drums", Json::object({{"style", styles[std::size_t(u.drumStyle)].name},
                                                             {"bars", grid->bars},
                                                             {"fill", u.drumFill},
                                                             {"track", u.drumTrack},
                                                             {"pattern", u.drumPattern}})));
    }
    at_track("mus:drum_generate");
    if (ImGui::IsItemHovered(ImGuiHoveredFlags_AllowWhenDisabled))
        ImGui::SetTooltip("music.drums: replaces this pattern with a groove in the style chosen (a tom fill on the "
                          "last beat with Fill).");
    ImGui::EndDisabled();
}

}  // namespace fa::editor
