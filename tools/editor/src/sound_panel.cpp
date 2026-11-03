// The Sound panel (View > Sound): a sound patch (*.sfx.json), an audio document (*.audio.json) or a plain sound file as a zoomable waveform
// with a selection, a spectrogram and the measurements; macros as knobs, an inspector built from the patch schema (its descriptions are the
// tooltips), the chain of a document with draggable loop points, the variants of a patch, and an A/B of any two sounds at the same loudness.
// Everything it keeps is a command call made by SoundModel (sfx.tweak, sfx.edit, sfx.preset, audio.edit, ...), so the Console and an AI make
// the same edit, and each edit is ONE entry of the editor's undo stack. The rules are in sound_model.h; the playback in sound_player.h.
#include <algorithm>
#include <cmath>
#include <cstdio>
#include <format>

#include "editor_internal.h"
#include "fa/audio/audio_doc.h"
#include "fa/audio/sfx.h"
#include "fa/core/strings.h"
#include "imgui_internal.h"
#include "sound_schema.h"
#include "ui_backend.h"

namespace fa::editor {

namespace {

constexpr float kWaveH = 150.0f;
constexpr float kSpecH = 110.0f;
constexpr float kRulerH = 14.0f;
constexpr float kGrab = 6.0f;   // pixels around a loop marker that grab it

const ImVec4 kBad(1.0f, 0.55f, 0.45f, 1);
const ImVec4 kWarn(1.0f, 0.8f, 0.4f, 1);

bool toggle_button(const char* label, bool on, ImVec2 size = ImVec2(0, 0)) {
    if (on) ImGui::PushStyleColor(ImGuiCol_Button, ImGui::GetStyleColorVec4(ImGuiCol_ButtonActive));
    const bool clicked = ImGui::Button(label, size);
    if (on) ImGui::PopStyleColor();
    return clicked;
}

std::string seconds_text(double s) {
    if (s < 1.0) return std::format("{:.0f} ms", s * 1000.0);
    if (s < 60.0) return std::format("{:.2f} s", s);
    return std::format("{}:{:04.1f}", int(s / 60), std::fmod(s, 60.0));
}

// A rotary knob: drag up and down (hold Shift for fine steps), double click for 0. Returns true while the value changes.
bool knob(const char* id, double& value, double lo, double hi, float size) {
    const ImVec2 p = ImGui::GetCursorScreenPos();
    ImGui::InvisibleButton(id, ImVec2(size, size));
    bool changed = false;
    if (ImGui::IsItemActive() && ImGui::IsMouseDragging(ImGuiMouseButton_Left, 0.0f)) {
        const double delta = -double(ImGui::GetIO().MouseDelta.y) * (hi - lo) / (ImGui::GetIO().KeyShift ? 1200.0 : 150.0);
        const double v = std::clamp(value + delta, lo, hi);
        changed = v != value;
        value = v;
    }
    if (ImGui::IsItemHovered() && ImGui::IsMouseDoubleClicked(ImGuiMouseButton_Left)) {
        changed = value != 0.0;
        value = 0.0;
    }
    ImDrawList* dl = ImGui::GetWindowDrawList();
    const ImVec2 c(p.x + size * 0.5f, p.y + size * 0.5f);
    const float r = size * 0.5f - 2.0f;
    const bool hot = ImGui::IsItemHovered() || ImGui::IsItemActive();
    dl->AddCircleFilled(c, r, IM_COL32(48, 50, 58, 255), 32);
    dl->AddCircle(c, r, hot ? IM_COL32(190, 200, 230, 255) : IM_COL32(95, 100, 118, 255), 32, 1.6f);
    const float a0 = 0.75f * 3.14159265f, span = 1.5f * 3.14159265f;
    const float t = float((value - lo) / (hi - lo));
    const float mid = a0 + span * float((0.0 - lo) / (hi - lo));
    const float a = a0 + span * t;
    dl->PathArcTo(c, r - 3.0f, std::min(mid, a), std::max(mid, a), 24);
    dl->PathStroke(IM_COL32(110, 170, 255, 255), 0, 3.0f);
    dl->AddLine(ImVec2(c.x + std::cos(a) * (r * 0.35f), c.y + std::sin(a) * (r * 0.35f)),
                ImVec2(c.x + std::cos(a) * (r - 2.0f), c.y + std::sin(a) * (r - 2.0f)), IM_COL32(240, 240, 245, 255), 2.0f);
    return changed;
}

}  // namespace

// ----------------------------------------------------------------------------------------------------------- document --
SoundModel& Editor::sound_ensure_model() {
    if (!sound_.model) {
        sound_.model = std::make_unique<SoundModel>(projectDir_, [this](const std::string& name, const Json& args) {
            CommandResult r = engine_->commands().call(name, args);
            if (!args.is_object() || !args.value("dryRun", false)) after_command(name, args, r);
            return r;
        });
    }
    if (!sound_.player) sound_.player = std::make_unique<SoundPlayer>(&engine_->audio(), [this] { return play_ == PlayState::Playing; });
    return *sound_.model;
}

bool Editor::open_sound_document(const std::string& rel) {
    if (!engine_) return false;
    SoundModel& m = sound_ensure_model();
    SoundUi& u = sound_;
    if (u.player) u.player->stop();
    u.heard = 0;
    u.hasSelection = false;
    u.cursor = 0.0;
    u.fitNext = true;
    u.openStep = -1;
    u.textKey.clear();
    const bool ok = m.open(rel);
    u.openError = ok ? std::string() : m.error();
    showSound_ = true;
    focus_window("Sound");
    if (!ok) notify("Cannot open " + rel + " in the Sound panel: " + m.error(), 2);
    return ok;
}

void Editor::sound_close_document() {
    if (sound_.player) sound_.player->stop();
    if (sound_.model) sound_.model->close();
    sound_.heard = 0;
}

void Editor::sound_release_textures() {
    SoundUi& u = sound_;
    if (u.specImage || u.specView) ui::destroy_texture(u.specImage, u.specView);
    for (const SoundUi::Dead& d : u.graveyard) ui::destroy_texture(d.image, d.view);
    u.specImage = u.specView = 0;
    u.specRender = 0;
    u.graveyard.clear();
}

void Editor::sound_save() {
    SoundUi& u = sound_;
    if (!u.model || !u.model->is_open() || !u.model->editable()) return;
    if (play_ != PlayState::Edit) {
        notify("Stop the game before baking the sound.", 1);
        return;
    }
    u.model->set_overwrite_on_save(u.overwriteBaked);
    const SoundEditOutcome out = u.model->save();
    if (!out.ok) notify(out.error, 2);
    else {
        u.model->set_status("Baked " + u.model->baked_path());
        project_files_changed();
    }
}

void Editor::sound_edited(const SoundEditOutcome& out) {
    SoundUi& u = sound_;
    if (!out.ok) {
        notify(out.error, 1);
        return;
    }
    if (out.step <= 0 || !u.model) return;
    undo_.push_back(Json::object({{"$sound", Json::object({{"step", out.step}})}}));
    if (undo_.size() > 100) undo_.erase(undo_.begin());
    redo_.clear();
    lastEditKey_.clear();
    sound_collect_steps();
}

void Editor::sound_collect_steps() {
    if (!sound_.model) return;
    std::set<int> keep;
    for (const auto* stack : {&undo_, &redo_})
        for (const Json& e : *stack)
            if (e.is_object() && e.contains("$sound") && e["$sound"].is_object() && e["$sound"].value("step", 0) > 0)
                keep.insert(e["$sound"]["step"].get<int>());
    sound_.model->retain_steps(keep);
}

void Editor::sound_apply_undo(const Json& entry, bool forward) {
    SoundUi& u = sound_;
    const int id = entry["$sound"].value("step", 0);
    if (!u.model || !u.model->step(id)) {
        notify("That sound edit is no longer remembered.", 1);
        return;
    }
    const std::string doc = u.model->step_document(id);
    if (!doc.empty() && doc != u.model->path()) open_sound_document(doc);
    if (!u.model->apply_step(id, forward)) {
        notify("Could not " + std::string(forward ? "redo" : "undo") + " the sound edit: " + u.model->status(), 2);
        return;
    }
    (forward ? undo_ : redo_).push_back(entry);
    project_files_changed();
}

Vec2 Editor::sound_screen_pos(double seconds, double yFraction) const {
    const SoundUi& u = sound_;
    const double len = std::max(1e-6, u.viewLen);
    return Vec2{float(u.waveX + (seconds - u.viewStart) / len * u.waveW), float(u.waveY + yFraction * u.waveH)};
}

// -------------------------------------------------------------------------------------------------------------- panel --
void Editor::draw_sound_panel() {
    SoundUi& u = sound_;
    SoundModel& m = sound_ensure_model();
    // One tick per frame: collects a finished render, starts the next one, tops the player's queue up.
    if (m.is_open()) m.tick();
    u.player->update(double(ImGui::GetIO().DeltaTime));
    if (!u.player->playing() && u.heard != 0) u.heard = 0;

    ImGui::SetNextWindowPos(ImVec2(200, 90), ImGuiCond_FirstUseEver);
    ImGui::SetNextWindowSize(ImVec2(1080, 760), ImGuiCond_FirstUseEver);
    if (!ImGui::Begin("Sound", &showSound_)) {
        u.focused = false;
        ImGui::End();
        return;
    }
    u.focused = ImGui::IsWindowFocused(ImGuiFocusedFlags_RootAndChildWindows);
    for (std::size_t i = 0; i < u.graveyard.size();) {
        if (u.graveyard[i].frame + 4 < uiFrame_) {
            ui::destroy_texture(u.graveyard[i].image, u.graveyard[i].view);
            u.graveyard.erase(u.graveyard.begin() + long(i));
        } else {
            ++i;
        }
    }
    draw_sound_toolbar(m);
    if (!m.is_open()) {
        ImGui::Spacing();
        ImGui::TextDisabled("Open a sound patch (*.sfx.json), an audio document (*.audio.json) or a sound file (.wav, .ogg) from the list above,");
        ImGui::TextDisabled("or double click one in the Project panel.");
        if (!u.openError.empty()) ImGui::TextColored(kBad, "%s", u.openError.c_str());
        ImGui::End();
        return;
    }
    if (uiFrame_ - u.lastPoll >= 20 && !m.macro_previewing() && !m.field_previewing() && !m.loop_previewing() && u.drag == SoundUi::Drag::None) {
        u.lastPoll = uiFrame_;
        if (m.poll_external()) m.set_status("The file changed on disk and was read again.");
    }
    if (!m.valid()) {
        ImGui::Spacing();
        ImGui::TextColored(kBad, "This sound does not load:");
        ImGui::TextWrapped("%s", m.error().c_str());
        ImGui::TextDisabled("Fix it with the Console (sfx.edit, audio.edit, fs.edit) or an editor, then Reload.");
        ImGui::End();
        return;
    }
    if (play_ != PlayState::Edit) ImGui::TextColored(kWarn, "The game is running: stop it to edit the sound.");
    if (u.focused && !ImGui::GetIO().WantTextInput && ImGui::IsKeyPressed(ImGuiKey_Space, false)) sound_toggle_play();

    draw_sound_transport(m);
    draw_sound_wave(m);
    draw_sound_measures(m);
    const ImVec2 avail = ImGui::GetContentRegionAvail();
    const float leftW = std::max(260.0f, avail.x * 0.55f);
    ImGui::BeginChild("##sndedit", ImVec2(leftW, avail.y), false);
    if (m.kind() == SoundKind::Patch) {
        draw_sound_macros(m);
        ImGui::SeparatorText("Patch");
        draw_sound_fields(m, "", true);
    } else if (m.kind() == SoundKind::Document) {
        draw_sound_chain(m);
    } else {
        ImGui::TextWrapped("This is a plain sound file: it can be played and measured here, not edited.");
        ImGui::TextDisabled("An audio document keeps the original and lists the steps (trim, normalize, loop, ...) that make the sound the game plays.");
        ImGui::BeginDisabled(play_ != PlayState::Edit);
        if (ImGui::Button("Make an audio document from this")) {
            const SoundEditOutcome out = m.make_document();
            sound_edited(out);
            if (out.ok) {
                u.fitNext = true;
                notify("Created " + m.path() + "; it bakes to " + m.baked_path() + ".", 0);
            }
        }
        at_track("snd:make_doc");
        ImGui::EndDisabled();
        if (ImGui::IsItemHovered(ImGuiHoveredFlags_AllowWhenDisabled))
            ImGui::SetTooltip("audio.create: writes <name>.audio.json with this file as its source. The document's sound goes to <name>_edit.wav, so the original is never overwritten.");
    }
    ImGui::EndChild();
    ImGui::SameLine();
    ImGui::BeginChild("##sndlisten", ImVec2(0, avail.y), false);
    draw_sound_ab(m);
    if (m.kind() == SoundKind::Patch) {
        draw_sound_variants(m);
        draw_sound_presets(m);
    }
    ImGui::EndChild();
    ImGui::End();
}

void Editor::draw_sound_toolbar(SoundModel& m) {
    SoundUi& u = sound_;
    const bool editable = play_ == PlayState::Edit;
    std::vector<std::string> files;
    for (const BrowserFile& f : projBrowser_.listing.files)
        if (ends_with(f.path, ".sfx.json") || ends_with(f.path, ".audio.json") || ends_with(f.path, ".wav") || ends_with(f.path, ".ogg")) files.push_back(f.path);
    std::sort(files.begin(), files.end());
    ImGui::SetNextItemWidth(320);
    if (ImGui::BeginCombo("##sndfile", m.is_open() ? m.title().c_str() : "Open a sound...")) {
        for (const std::string& f : files) {
            if (ImGui::Selectable(f.c_str(), f == m.path())) open_sound_document(f);
            at_track("snd:file:" + f);
        }
        if (files.empty()) ImGui::TextDisabled("No sound patches or sound files in the project yet.");
        ImGui::EndCombo();
    }
    at_track("snd:open");
    if (ImGui::IsItemHovered()) ImGui::SetTooltip("The sound patches (*.sfx.json), audio documents (*.audio.json) and sound files of the project. A double click in the Project panel opens one too.");
    if (!m.is_open()) return;
    ImGui::SameLine();
    ImGui::BeginDisabled(!editable || !m.editable() || !m.valid());
    if (ImGui::Button("Save + bake")) sound_save();
    at_track("snd:save");
    ImGui::EndDisabled();
    if (ImGui::IsItemHovered(ImGuiHoveredFlags_AllowWhenDisabled))
        ImGui::SetTooltip("Writes the sound next to the patch (sfx.render, with the variants when it declares some) or the document's output (audio.bake). Ctrl+S while this panel has the keyboard.\n"
                          "Every edit is already written to the file; baking is what changes the sound the game plays.");
    ImGui::SameLine();
    ImGui::Checkbox("Replace foreign file", &u.overwriteBaked);
    at_track("snd:overwrite");
    if (ImGui::IsItemHovered()) ImGui::SetTooltip("Bake over a sound file that nothing of ours made (no recipe in assets.json). Off: the bake stops with a message instead.");
    ImGui::SameLine();
    if (ImGui::Button("Reload")) m.reload();
    at_track("snd:reload");
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

// ----------------------------------------------------------------------------------------------------------- playing --
void Editor::sound_play_clip(SoundRenderPtr clip, double gainDb, int heard, const std::string& name) {
    SoundUi& u = sound_;
    SoundModel& m = *u.model;
    if (!clip) return;
    SoundPlayRequest req;
    req.clip = clip;
    req.name = name;
    req.gainDb = gainDb;
    req.loop = u.loopPlay;
    if (u.hasSelection && u.playSelection && u.sel1 > u.sel0) {
        req.from = u.sel0;
        req.to = u.sel1;
    } else {
        req.from = std::clamp(u.cursor, 0.0, std::max(0.0, clip->seconds));
        if (u.loopPlay) {
            if (auto lp = m.loop_seconds()) {
                req.to = lp->second;
                req.loopFrom = lp->first;
            }
        }
    }
    if (u.player->playing() && u.heard != 0 && heard != 3 && u.heard != heard) {
        u.player->switch_to(clip, gainDb, name);   // A/B: the same place of the other sound
    } else if (!u.player->play(req)) {
        notify("The sound could not be played.", 1);
        return;
    }
    u.heard = heard;
    u.playingName = name;
}

void Editor::sound_toggle_play() {
    SoundUi& u = sound_;
    if (!u.model || !u.model->is_open()) return;
    if (u.player->playing()) {
        u.player->stop();
        u.heard = 0;
        return;
    }
    sound_play_clip(u.model->current(), 0.0, 3, u.model->path());
}

void Editor::sound_play_slot(int which) {
    SoundUi& u = sound_;
    if (!u.model) return;
    const SoundSlot& s = which == 1 ? u.slotA : u.slotB;
    const SoundSlot& o = which == 1 ? u.slotB : u.slotA;
    SoundRenderPtr clip = u.model->slot(s);
    if (!clip) {
        notify("That sound is not ready: " + sound_slot_label(s) + " (rendering, or there is nothing to play).", 0);
        return;
    }
    double gain = 0.0;
    if (u.levelMatch) {
        SoundRenderPtr other = u.model->slot(o);
        if (other) {
            const auto g = which == 1 ? sound_level_match(clip->lufs, other->lufs) : sound_level_match(other->lufs, clip->lufs);
            gain = which == 1 ? g.first : g.second;
        }
    }
    sound_play_clip(clip, gain, which, u.model->path() + " [" + sound_slot_label(s) + "]");
}

void Editor::draw_sound_transport(SoundModel& m) {
    SoundUi& u = sound_;
    const bool playing = u.player->playing();
    if (ImGui::Button(playing ? "Stop" : "Play", ImVec2(60, 0))) sound_toggle_play();
    at_track("snd:play");
    if (ImGui::IsItemHovered()) ImGui::SetTooltip("Plays the sound (the selection when there is one). Space while this panel has the keyboard.");
    ImGui::SameLine();
    ImGui::Checkbox("Loop", &u.loopPlay);
    at_track("snd:loop");
    if (ImGui::IsItemHovered()) ImGui::SetTooltip("Wraps at the end of the region. A sound with loop points plays its intro once and then wraps between the loop points.");
    ImGui::SameLine();
    ImGui::BeginDisabled(!u.hasSelection);
    ImGui::Checkbox("Selection", &u.playSelection);
    at_track("snd:play_selection");
    ImGui::EndDisabled();
    if (ImGui::IsItemHovered(ImGuiHoveredFlags_AllowWhenDisabled)) ImGui::SetTooltip("Play only the selected part (drag on the waveform to select).");
    ImGui::SameLine(0, 18);
    SoundRenderPtr r = m.current();
    const double pos = playing ? u.player->position() : u.cursor;
    // The readout keeps a fixed width so the buttons after it stay put while the playhead's digits change.
    const float readoutX = ImGui::GetCursorPosX();
    ImGui::TextDisabled("%s / %s", seconds_text(pos).c_str(), r ? seconds_text(r->seconds).c_str() : "-");
    ImGui::SameLine(readoutX + ImGui::CalcTextSize("00:00.0 / 00:00.0").x);
    ImGui::Dummy(ImVec2(0, 0));
    if (u.hasSelection) {
        ImGui::SameLine();
        ImGui::TextDisabled("  selection %s - %s", seconds_text(std::min(u.sel0, u.sel1)).c_str(), seconds_text(std::max(u.sel0, u.sel1)).c_str());
    }
    ImGui::SameLine(0, 18);
    if (ImGui::Button("-")) {
        const double c = u.viewStart + u.viewLen * 0.5;
        u.viewLen = std::min(u.viewLen * 1.5, std::max(1e-3, u.shownSeconds));
        u.viewStart = c - u.viewLen * 0.5;
    }
    at_track("snd:zoom_out");
    ImGui::SameLine();
    if (ImGui::Button("+")) {
        const double c = u.viewStart + u.viewLen * 0.5;
        u.viewLen = std::max(0.002, u.viewLen / 1.5);
        u.viewStart = c - u.viewLen * 0.5;
    }
    at_track("snd:zoom_in");
    ImGui::SameLine();
    if (ImGui::Button("Fit")) u.fitNext = true;
    at_track("snd:fit");
    ImGui::SameLine();
    ImGui::BeginDisabled(!u.hasSelection);
    if (ImGui::Button("To selection") && u.sel1 > u.sel0) {
        u.viewStart = u.sel0;
        u.viewLen = std::max(0.002, u.sel1 - u.sel0);
    }
    at_track("snd:zoom_selection");
    ImGui::EndDisabled();
    ImGui::SameLine();
    ImGui::Checkbox("Spectrogram", &u.showSpectrogram);
    at_track("snd:spectrogram");
}

// ----------------------------------------------------------------------------------------------------------- waveform --
void Editor::draw_sound_wave(SoundModel& m) {
    SoundUi& u = sound_;
    SoundRenderPtr r = m.current();
    const bool dragLoop = u.drag == SoundUi::Drag::LoopStart || u.drag == SoundUi::Drag::LoopEnd;
    const float w = std::max(60.0f, ImGui::GetContentRegionAvail().x);
    if (!r) {
        ImGui::Dummy(ImVec2(w, kWaveH));
        if (!m.render_error().empty()) ImGui::TextColored(kBad, "%s", m.render_error().c_str());
        else ImGui::TextDisabled("Rendering the sound...");
        return;
    }
    const double dur = std::max(1e-3, r->seconds);
    if (u.fitNext || std::abs(u.shownSeconds - dur) > 1e-9) {
        if (u.fitNext || u.viewLen <= 0.0 || u.viewLen >= u.shownSeconds - 1e-9) {
            u.viewStart = 0.0;
            u.viewLen = dur;
        }
        u.shownSeconds = dur;
        u.fitNext = false;
    }
    u.viewLen = std::clamp(u.viewLen, std::min(0.002, dur), dur);
    u.viewStart = std::clamp(u.viewStart, 0.0, std::max(0.0, dur - u.viewLen));

    if (!m.render_error().empty()) ImGui::TextColored(kBad, "%s (the picture shows the last good render)", m.render_error().c_str());
    const ImVec2 p0 = ImGui::GetCursorScreenPos();
    ImGui::InvisibleButton("##wave", ImVec2(w, kWaveH), ImGuiButtonFlags_MouseButtonLeft | ImGuiButtonFlags_MouseButtonMiddle);
    at_track("snd:wave");
    const bool hovered = ImGui::IsItemHovered();
    u.waveX = p0.x;
    u.waveY = p0.y;
    u.waveW = w;
    u.waveH = kWaveH;
    const double secPerPx = u.viewLen / double(w);
    auto time_at = [&](float x) { return u.viewStart + double(x - p0.x) * secPerPx; };
    auto x_at = [&](double t) { return p0.x + float((t - u.viewStart) / secPerPx); };

    const bool editLoop = m.kind() == SoundKind::Document && m.loop_step() >= 0 && play_ == PlayState::Edit;
    std::optional<std::pair<double, double>> loop = m.loop_seconds();

    // ---- input
    const ImGuiIO& io = ImGui::GetIO();
    if (hovered && io.MouseWheel != 0.0f) {
        if (io.KeyShift) {
            u.viewStart -= double(io.MouseWheel) * u.viewLen * 0.1;
        } else {
            const double at = time_at(io.MousePos.x);
            const double f = std::pow(1.2, -double(io.MouseWheel));
            const double nl = std::clamp(u.viewLen * f, std::min(0.002, dur), dur);
            u.viewStart = at - (at - u.viewStart) * nl / u.viewLen;
            u.viewLen = nl;
        }
    }
    if (ImGui::IsItemActivated()) {
        const double t = std::clamp(time_at(io.MousePos.x), 0.0, dur);
        if (ImGui::IsMouseDown(ImGuiMouseButton_Middle) || io.KeyShift) {
            u.drag = SoundUi::Drag::Pan;
            u.panAnchor = time_at(io.MousePos.x);
        } else if (editLoop && loop && std::abs(io.MousePos.x - x_at(loop->first)) <= kGrab) {
            u.drag = SoundUi::Drag::LoopStart;
        } else if (editLoop && loop && std::abs(io.MousePos.x - x_at(loop->second)) <= kGrab) {
            u.drag = SoundUi::Drag::LoopEnd;
        } else {
            u.drag = SoundUi::Drag::Select;
            u.dragAnchor = t;
            u.sel0 = u.sel1 = t;
        }
    }
    if (ImGui::IsItemActive()) {
        const double t = std::clamp(time_at(io.MousePos.x), 0.0, dur);
        switch (u.drag) {
        case SoundUi::Drag::Pan:
            u.viewStart += u.panAnchor - time_at(io.MousePos.x);
            break;
        case SoundUi::Drag::Select:
            u.sel0 = std::min(u.dragAnchor, t);
            u.sel1 = std::max(u.dragAnchor, t);
            u.hasSelection = (u.sel1 - u.sel0) > 3.0 * secPerPx;
            break;
        case SoundUi::Drag::LoopStart:
            m.preview_loop(std::min(t, loop->second - 0.001), loop->second);
            break;
        case SoundUi::Drag::LoopEnd:
            m.preview_loop(loop->first, std::max(t, loop->first + 0.001));
            break;
        case SoundUi::Drag::None: break;
        }
        if (dragLoop && u.player->playing()) {
            if (auto lp = m.loop_seconds()) u.player->set_loop(lp->first, lp->second);
        }
    }
    if (ImGui::IsItemDeactivated()) {
        if (u.drag == SoundUi::Drag::Select) {
            if (!u.hasSelection) u.cursor = std::clamp(u.dragAnchor, 0.0, dur);
        } else if (dragLoop) {
            const SoundEditOutcome out = m.commit_loop();
            sound_edited(out);
        }
        u.drag = SoundUi::Drag::None;
    }

    // ---- drawing
    ImDrawList* dl = ImGui::GetWindowDrawList();
    const ImVec2 p1(p0.x + w, p0.y + kWaveH);
    dl->AddRectFilled(p0, p1, IM_COL32(20, 22, 27, 255));
    dl->PushClipRect(p0, p1, true);
    const float mid = (p0.y + kRulerH + p1.y) * 0.5f;
    const float half = (p1.y - p0.y - kRulerH) * 0.5f - 2.0f;
    dl->AddLine(ImVec2(p0.x, mid), ImVec2(p1.x, mid), IM_COL32(60, 64, 74, 255));
    // ruler
    {
        const double want = secPerPx * 90.0;
        double step = std::pow(10.0, std::floor(std::log10(std::max(1e-6, want))));
        for (double mult : {1.0, 2.0, 5.0, 10.0})
            if (step * mult >= want) {
                step *= mult;
                break;
            }
        for (double t = std::ceil(u.viewStart / step) * step; t < u.viewStart + u.viewLen; t += step) {
            const float x = x_at(t);
            dl->AddLine(ImVec2(x, p0.y), ImVec2(x, p0.y + 5), IM_COL32(110, 114, 126, 255));
            const std::string label = seconds_text(t);
            dl->AddText(ImVec2(x + 3, p0.y), IM_COL32(130, 134, 146, 255), label.c_str());
        }
    }
    if (u.hasSelection || (u.drag == SoundUi::Drag::Select && u.sel1 > u.sel0))
        dl->AddRectFilled(ImVec2(x_at(u.sel0), p0.y + kRulerH), ImVec2(x_at(u.sel1), p1.y), IM_COL32(80, 130, 220, 55));
    auto draw_wave = [&](const SoundRender& s, ImU32 col) {
        const double rate = double(s.rate);
        for (int px = 0; px < int(w); ++px) {
            const double t0 = u.viewStart + double(px) * secPerPx, t1 = t0 + secPerPx;
            double f0 = t0 * rate, f1 = t1 * rate;
            if (f1 < 0 || f0 >= double(s.frames())) continue;
            f0 = std::max(0.0, f0);
            f1 = std::min(double(s.frames()), std::max(f1, f0 + 1.0));
            float lo = 1.0f, hi = -1.0f;
            if (f1 - f0 > double(s.peakBlock) * 2 && !s.peakMin.empty()) {
                const std::size_t b0 = std::size_t(f0) / std::size_t(s.peakBlock);
                const std::size_t b1 = std::min(s.peakMin.size(), std::size_t(f1) / std::size_t(s.peakBlock) + 1);
                for (std::size_t b = b0; b < b1; ++b) {
                    lo = std::min(lo, s.peakMin[b]);
                    hi = std::max(hi, s.peakMax[b]);
                }
            } else {
                for (std::size_t i = std::size_t(f0); i < std::size_t(f1) + 1 && i < s.frames(); ++i) {
                    const float v = s.mid(i);
                    lo = std::min(lo, v);
                    hi = std::max(hi, v);
                }
            }
            if (lo > hi) continue;
            const float x = p0.x + float(px);
            const float yl = mid - std::clamp(hi, -1.0f, 1.0f) * half, yh = mid - std::clamp(lo, -1.0f, 1.0f) * half;
            dl->AddLine(ImVec2(x + 0.5f, yl), ImVec2(x + 0.5f, std::max(yh, yl + 1.0f)), col);
        }
    };
    if (SoundRenderPtr ghost = m.loop_ghost()) draw_wave(*ghost, IM_COL32(90, 96, 112, 160));
    draw_wave(*r, (m.macro_previewing() || m.field_previewing()) ? IM_COL32(150, 200, 255, 255) : IM_COL32(110, 200, 150, 255));
    if (loop) {
        const float xs = x_at(loop->first), xe = x_at(loop->second);
        const ImU32 col = editLoop ? IM_COL32(255, 190, 70, 255) : IM_COL32(190, 150, 80, 200);
        dl->AddRectFilled(ImVec2(xs, p0.y + kRulerH), ImVec2(xe, p1.y), IM_COL32(255, 190, 70, 22));
        for (float x : {xs, xe}) {
            dl->AddLine(ImVec2(x, p0.y + kRulerH), ImVec2(x, p1.y), col, 2.0f);
            dl->AddTriangleFilled(ImVec2(x - 5, p0.y + kRulerH), ImVec2(x + 5, p0.y + kRulerH), ImVec2(x, p0.y + kRulerH + 8), col);
        }
        if (editLoop) {
            // the autotest finds the markers by these two points
            at_track_at("snd:loop_start", Vec2{std::clamp(xs, p0.x + 3, p1.x - 3), p0.y + kRulerH + 6});
            at_track_at("snd:loop_end", Vec2{std::clamp(xe, p0.x + 3, p1.x - 3), p0.y + kRulerH + 6});
        }
        if (hovered && editLoop && (std::abs(io.MousePos.x - xs) <= kGrab || std::abs(io.MousePos.x - xe) <= kGrab)) ImGui::SetMouseCursor(ImGuiMouseCursor_ResizeEW);
    }
    if (u.heard != 0 || u.player->playing()) {
        const float x = x_at(u.player->position());
        dl->AddLine(ImVec2(x, p0.y), ImVec2(x, p1.y), IM_COL32(255, 255, 255, 230), 1.5f);
    } else {
        const float x = x_at(u.cursor);
        dl->AddLine(ImVec2(x, p0.y + kRulerH), ImVec2(x, p1.y), IM_COL32(255, 255, 255, 90));
    }
    dl->PopClipRect();
    if (hovered) ImGui::SetTooltip("Drag: select. Click: place the play cursor. Wheel: zoom. Shift+drag or middle drag: pan.%s",
                                   editLoop ? "\nDrag the orange loop markers to move the loop points." : "");
    if (u.showSpectrogram) draw_sound_spectrogram(*r);
}

void Editor::draw_sound_spectrogram(const SoundRender& r) {
    SoundUi& u = sound_;
    const AudioSpectrogram& s = r.spectrogram;
    const float w = u.waveW;
    if (s.columns <= 0 || s.rows <= 0) {
        ImGui::TextDisabled("(no spectrogram: the sound is empty)");
        return;
    }
    if (u.specRender != r.id) {
        if (u.specImage || u.specView) u.graveyard.push_back({u.specImage, u.specView, uiFrame_});
        u.specImage = u.specView = 0;
        const std::vector<unsigned char> px = audio_spectrogram_pixels(s);
        ui::make_texture(s.columns, s.rows, px.data(), u.specImage, u.specView);
        u.specRender = r.id;
    }
    const ImVec2 p0 = ImGui::GetCursorScreenPos();
    ImGui::InvisibleButton("##spec", ImVec2(w, kSpecH));
    at_track("snd:spec");
    const ImVec2 p1(p0.x + w, p0.y + kSpecH);
    ImDrawList* dl = ImGui::GetWindowDrawList();
    dl->AddRectFilled(p0, p1, IM_COL32(0, 0, 0, 255));
    const double dur = std::max(1e-3, r.seconds);
    const float u0 = float(u.viewStart / dur), u1 = float((u.viewStart + u.viewLen) / dur);
    if (u.specView) dl->AddImage(ImTextureRef(ImTextureID(ui::texture_from_view(u.specView, true))), p0, p1, ImVec2(u0, 0), ImVec2(u1, 1));
    for (double hz : {100.0, 1000.0, 10000.0}) {
        if (hz <= s.minHz || hz >= s.maxHz) continue;
        const float y = p0.y + float(std::log(s.maxHz / hz) / std::log(s.maxHz / s.minHz)) * kSpecH;
        dl->AddLine(ImVec2(p0.x, y), ImVec2(p0.x + 6, y), IM_COL32(255, 255, 255, 140));
        const std::string label = hz >= 1000 ? std::format("{:.0f}k", hz / 1000) : std::format("{:.0f}", hz);
        dl->AddText(ImVec2(p0.x + 8, y - 7), IM_COL32(255, 255, 255, 170), label.c_str());
    }
    if (u.hasSelection) {
        const double secPerPx = u.viewLen / double(w);
        dl->AddRectFilled(ImVec2(p0.x + float((u.sel0 - u.viewStart) / secPerPx), p0.y), ImVec2(p0.x + float((u.sel1 - u.viewStart) / secPerPx), p1.y),
                          IM_COL32(80, 130, 220, 50));
    }
    if (u.player->playing()) {
        const float x = p0.x + float((u.player->position() - u.viewStart) / (u.viewLen / double(w)));
        dl->AddLine(ImVec2(x, p0.y), ImVec2(x, p1.y), IM_COL32(255, 255, 255, 230), 1.5f);
    }
    if (ImGui::IsItemHovered()) ImGui::SetTooltip("Spectrogram of the whole sound at the same time axis (frequency on a log scale, 20 Hz at the bottom, 20 kHz at the top; brighter is louder).");
}

void Editor::draw_sound_measures(SoundModel& m) {
    SoundRenderPtr r = m.current();
    if (!r) return;
    ImGui::TextDisabled("LUFS");
    ImGui::SameLine();
    ImGui::Text("%.1f", r->lufs);
    ImGui::SameLine(0, 14);
    ImGui::TextDisabled("peak");
    ImGui::SameLine();
    ImGui::Text("%.1f dB", r->peakDb);
    ImGui::SameLine(0, 14);
    ImGui::TextDisabled("true peak");
    ImGui::SameLine();
    if (r->view.truePeakDb > -1.0) ImGui::TextColored(kWarn, "%.1f dB", r->view.truePeakDb);
    else ImGui::Text("%.1f dB", r->view.truePeakDb);
    ImGui::SameLine(0, 14);
    ImGui::TextDisabled("length");
    ImGui::SameLine();
    ImGui::Text("%s", seconds_text(r->seconds).c_str());
    ImGui::SameLine(0, 14);
    ImGui::TextDisabled("centroid");
    ImGui::SameLine();
    ImGui::Text("%.0f Hz", r->centroidHz);
    ImGui::SameLine(0, 14);
    ImGui::TextDisabled("rise");
    ImGui::SameLine();
    ImGui::Text("%s", seconds_text(r->riseSeconds).c_str());
    if (r->view.clippedSamples > 0) {
        ImGui::SameLine(0, 14);
        ImGui::TextColored(kBad, "clipping: %zu samples", r->view.clippedSamples);
    }
    if (r->loop) {
        ImGui::SameLine(0, 14);
        ImGui::TextDisabled("loop seam");
        ImGui::SameLine();
        if (r->view.seamJumpRatio > 8.0) ImGui::TextColored(kWarn, "%.1fx (click)", r->view.seamJumpRatio);
        else ImGui::Text("%.1fx", r->view.seamJumpRatio);
    }
    if (r->truncated) {
        ImGui::SameLine(0, 14);
        ImGui::TextColored(kWarn, "(only the start of a long file is shown)");
    }
    if (auto il = m.import_loop()) {
        ImGui::SameLine(0, 14);
        ImGui::TextDisabled("import loop %.3f - %.3f s", il->first, il->second);
    }
}

// ---------------------------------------------------------------------------------------------------------- macros ----
void Editor::draw_sound_macros(SoundModel& m) {
    const bool editable = play_ == PlayState::Edit;
    ImGui::SeparatorText("Macros");
    ImGui::BeginDisabled(!editable);
    int n = 0;
    for (const SoundMacro& k : m.macros()) {
        if (n++ > 0 && (n - 1) % 6 != 0) ImGui::SameLine(0, 10);
        ImGui::BeginGroup();
        ImGui::PushID(k.name.c_str());
        double v = k.shown;
        if (knob("##k", v, -1.0, 1.0, 44.0f)) m.preview_macro(k.name, v);
        at_track("snd:knob:" + k.name, editable);
        if (ImGui::IsItemDeactivated() && m.macro_previewing()) sound_edited(m.commit_macros("Turn " + k.name));
        if (ImGui::IsItemHovered(ImGuiHoveredFlags_AllowWhenDisabled))
            ImGui::SetTooltip("%s\nDrag up and down (Shift: fine), double click for 0. -1 to 1; 0 leaves the patch as written.%s", k.what.c_str(),
                              k.builtin ? "" : "\n(a macro of this patch)");
        ImGui::Text("%s", k.name.c_str());
        ImGui::TextDisabled("%+.2f", k.shown);
        ImGui::PopID();
        ImGui::EndGroup();
    }
    ImGui::EndDisabled();
}

// -------------------------------------------------------------------------------------------------------- inspector ----
namespace {

std::string item_label(const Json& item, std::size_t i) {
    std::string out = "#" + std::to_string(i + 1);
    if (item.is_object()) {
        if (item.contains("name") && item["name"].is_string()) out += " " + item["name"].get<std::string>();
        else if (item.contains("type") && item["type"].is_string()) out += " " + item["type"].get<std::string>();
        else if (item.contains("wave") && item["wave"].is_string()) out += " " + item["wave"].get<std::string>();
    }
    return out;
}

}  // namespace

void Editor::draw_sound_fields(SoundModel& m, const std::string& pointer, bool top) {
    SoundUi& u = sound_;
    const bool editable = play_ == PlayState::Edit;
    const Json& patch = m.shown_json();
    const std::vector<SoundField> fields = sfx_fields(patch, pointer);
    ImGui::BeginDisabled(!editable);
    for (const SoundField& f : fields) {
        ImGui::PushID(f.key.c_str());
        const std::string tag = "snd:field:" + f.pointer;
        const float width = std::max(120.0f, ImGui::GetContentRegionAvail().x * 0.55f);
        auto tip = [&] {
            if (!ImGui::IsItemHovered(ImGuiHoveredFlags_AllowWhenDisabled)) return;
            std::string t = f.doc;
            if (f.min && f.max) t += std::format("\n({} to {}{})", *f.min, *f.max, f.def ? ", default " + f.def->dump() : "");
            else if (f.def) t += "\n(default " + f.def->dump() + ")";
            if (!t.empty()) ImGui::SetTooltip("%s", t.c_str());
        };
        if (f.kind == "number" || f.kind == "integer") {
            const bool integer = f.kind == "integer";
            double v = f.value.is_number() ? f.value.get<double>() : (f.def && f.def->is_number() ? f.def->get<double>() : f.min.value_or(0.0));
            bool changed = false;
            ImGui::SetNextItemWidth(width);
            if (f.min && f.max) {
                ImGuiSliderFlags flags = ImGuiSliderFlags_AlwaysClamp;
                if (*f.min > 0 && *f.max / *f.min >= 100.0) flags |= ImGuiSliderFlags_Logarithmic;
                if (integer) {
                    int iv = int(std::lround(v));
                    const int lo = int(*f.min), hi = int(*f.max);
                    changed = ImGui::SliderInt(f.key.c_str(), &iv, lo, hi, "%d", flags);
                    v = iv;
                } else {
                    double lo = *f.min, hi = *f.max;
                    changed = ImGui::SliderScalar(f.key.c_str(), ImGuiDataType_Double, &v, &lo, &hi, "%.4g", flags);
                }
            } else {
                double lo = f.min.value_or(-1e9), hi = f.max.value_or(1e9);
                changed = ImGui::DragScalar(f.key.c_str(), ImGuiDataType_Double, &v, integer ? 1.0f : std::max(0.001f, float(std::abs(v)) * 0.01f), &lo, &hi, integer ? "%.0f" : "%.4g");
            }
            at_track(tag, editable);
            tip();
            if (changed) {
                if (integer) m.preview_field(f.pointer, Json(static_cast<long long>(std::llround(v))));
                else m.preview_field(f.pointer, Json(f.min && f.max ? sound_round_to_step(v, *f.min, *f.max) : v));
            }
            if (ImGui::IsItemDeactivated() && m.field_previewing()) sound_edited(m.commit_field("Set " + f.key));
        } else if (f.kind == "boolean") {
            bool b = f.value.is_boolean() ? f.value.get<bool>() : (f.def && f.def->is_boolean() ? f.def->get<bool>() : false);
            if (ImGui::Checkbox(f.key.c_str(), &b)) sound_edited(m.set_field(f.pointer, Json(b), "Set " + f.key));
            at_track(tag, editable);
            tip();
        } else if (f.kind == "enum") {
            std::string cur = f.value.is_string() ? f.value.get<std::string>() : (f.def && f.def->is_string() ? f.def->get<std::string>() : std::string());
            ImGui::SetNextItemWidth(width);
            if (ImGui::BeginCombo(f.key.c_str(), cur.empty() ? "(unset)" : cur.c_str())) {
                for (const std::string& c : f.choices) {
                    if (ImGui::Selectable(c.c_str(), c == cur)) sound_edited(m.set_field(f.pointer, Json(c), "Set " + f.key));
                    at_track(tag + ":" + c, editable);
                }
                ImGui::EndCombo();
            }
            at_track(tag, editable);
            tip();
        } else if (f.kind == "object") {
            ImGui::SetNextItemOpen(top || f.present, ImGuiCond_Appearing);
            if (!f.present) {
                if (ImGui::SmallButton("+")) sound_edited(m.set_field(f.pointer, sfx_new_value(patch, f.pointer), "Add " + f.key));
                at_track(tag + ":add", editable);
                ImGui::SameLine();
                ImGui::TextDisabled("%s", f.key.c_str());
                tip();
            } else {
                const bool open = ImGui::TreeNodeEx(f.key.c_str(), ImGuiTreeNodeFlags_DefaultOpen | ImGuiTreeNodeFlags_SpanAvailWidth);
                at_track(tag, editable);
                tip();
                if (!f.required) {
                    ImGui::SameLine();
                    if (ImGui::SmallButton("x")) {
                        sound_edited(m.remove_field(f.pointer, "Remove " + f.key));
                        if (open) ImGui::TreePop();
                        ImGui::PopID();
                        continue;
                    }
                    at_track(tag + ":remove", editable);
                }
                if (open) {
                    draw_sound_fields(m, f.pointer, false);
                    ImGui::TreePop();
                }
            }
        } else if (f.kind == "array" && f.present && f.value.is_array()) {
            const SoundArrayInfo info = sfx_array_info(patch, f.pointer);
            const bool objects = info.known && info.itemKind == "object";
            if (objects) {
                const bool open = ImGui::TreeNodeEx(f.key.c_str(), ImGuiTreeNodeFlags_DefaultOpen | ImGuiTreeNodeFlags_SpanAvailWidth, "%s (%zu)", f.key.c_str(), f.value.size());
                at_track(tag, editable);
                tip();
                if (open) {
                    const int count = int(f.value.size());
                    for (int i = 0; i < count; ++i) {
                        const std::string ip = f.pointer + "/" + std::to_string(i);
                        ImGui::PushID(i);
                        const bool itemOpen = ImGui::TreeNodeEx("##item", ImGuiTreeNodeFlags_DefaultOpen | ImGuiTreeNodeFlags_SpanAvailWidth, "%s",
                                                                item_label(f.value[std::size_t(i)], std::size_t(i)).c_str());
                        at_track(tag + "/" + std::to_string(i), editable);
                        ImGui::SameLine();
                        ImGui::BeginDisabled(i == 0);
                        if (ImGui::SmallButton("^")) {
                            sound_edited(m.move_item(f.pointer, i, i - 1, "Move " + f.key));
                            ImGui::EndDisabled();
                            if (itemOpen) ImGui::TreePop();
                            ImGui::PopID();
                            break;
                        }
                        at_track(ip + ":up", editable && i > 0);
                        ImGui::EndDisabled();
                        ImGui::SameLine();
                        ImGui::BeginDisabled(i == count - 1);
                        if (ImGui::SmallButton("v")) {
                            sound_edited(m.move_item(f.pointer, i, i + 1, "Move " + f.key));
                            ImGui::EndDisabled();
                            if (itemOpen) ImGui::TreePop();
                            ImGui::PopID();
                            break;
                        }
                        at_track(ip + ":down", editable && i < count - 1);
                        ImGui::EndDisabled();
                        ImGui::SameLine();
                        ImGui::BeginDisabled(count <= info.minItems);
                        if (ImGui::SmallButton("x")) {
                            sound_edited(m.remove_field(ip, "Remove " + f.key));
                            ImGui::EndDisabled();
                            if (itemOpen) ImGui::TreePop();
                            ImGui::PopID();
                            break;
                        }
                        at_track(ip + ":remove", editable && count > info.minItems);
                        ImGui::EndDisabled();
                        if (itemOpen) {
                            draw_sound_fields(m, ip, false);
                            ImGui::TreePop();
                        }
                        ImGui::PopID();
                    }
                    ImGui::BeginDisabled(count >= info.maxItems);
                    if (f.key == "effects") {
                        ImGui::SetNextItemWidth(110);
                        if (ImGui::BeginCombo("##addfx", "Add effect...")) {
                            for (const std::string& t : sfx_effect_types()) {
                                if (ImGui::Selectable(t.c_str()))
                                    sound_edited(m.add_item(f.pointer, sfx_new_value(patch, f.pointer + "/" + std::to_string(count), t), -1, "Add " + t));
                                at_track(tag + ":add:" + t, editable);
                            }
                            ImGui::EndCombo();
                        }
                        at_track(tag + ":add", editable);
                    } else if (ImGui::SmallButton(("+ " + f.key.substr(0, f.key.size() > 1 && f.key.back() == 's' ? f.key.size() - 1 : f.key.size())).c_str())) {
                        sound_edited(m.add_item(f.pointer, sfx_new_value(patch, f.pointer + "/" + std::to_string(count)), -1, "Add " + f.key));
                    }
                    if (f.key != "effects") at_track(tag + ":add", editable);
                    ImGui::EndDisabled();
                    ImGui::TreePop();
                }
            } else {
                draw_sound_json_field(m, f, width);
            }
        } else {
            draw_sound_json_field(m, f, width);
        }
        ImGui::PopID();
    }
    ImGui::EndDisabled();
    (void)u;
}

// A field edited as text: a string as it is, anything else as JSON. The value shows in the sound while typing; Enter or leaving the field keeps it.
void Editor::draw_sound_json_field(SoundModel& m, const SoundField& f, float width) {
    SoundUi& u = sound_;
    const bool isString = f.kind == "string";
    const std::string shown = f.present ? (isString && f.value.is_string() ? f.value.get<std::string>() : f.value.dump()) : (f.def ? (isString && f.def->is_string() ? f.def->get<std::string>() : f.def->dump()) : std::string());
    std::string buf = u.textKey == f.pointer ? u.text : shown;
    ImGui::SetNextItemWidth(width);
    const bool changed = ImGui::InputText(f.key.c_str(), &buf);
    at_track("snd:field:" + f.pointer, play_ == PlayState::Edit);
    if (ImGui::IsItemHovered(ImGuiHoveredFlags_AllowWhenDisabled) && !f.doc.empty()) ImGui::SetTooltip("%s", f.doc.c_str());
    auto parsed = [&](const std::string& text, Json& out) {
        if (isString) {
            out = text;
            return true;
        }
        auto j = parse_json(text, f.key);
        if (!j.ok()) return false;
        out = *j;
        return true;
    };
    if (changed) {
        u.textKey = f.pointer;
        u.text = buf;
        Json v;
        if (parsed(buf, v)) m.preview_field(f.pointer, v);
    }
    if (ImGui::IsItemDeactivated()) {
        if (u.textKey == f.pointer) {
            Json v;
            if (m.field_previewing() && parsed(u.text, v)) sound_edited(m.commit_field("Set " + f.key));
            else {
                m.cancel_field_preview();
                if (!isString) notify(f.key + ": that is not valid JSON.", 1);
            }
            u.textKey.clear();
        }
    }
}

// ------------------------------------------------------------------------------------------------------------- chain ----
void Editor::draw_sound_chain(SoundModel& m) {
    SoundUi& u = sound_;
    const bool editable = play_ == PlayState::Edit;
    const Json& doc = m.shown_json();
    ImGui::SeparatorText("Document");
    ImGui::BeginDisabled(!editable);
    {
        const std::string source = doc.value("source", Json("")).is_string() ? doc.value("source", std::string()) : std::string("(see the file)");
        std::string buf = u.textKey == "doc:source" ? u.text : source;
        ImGui::SetNextItemWidth(std::max(160.0f, ImGui::GetContentRegionAvail().x * 0.6f));
        if (ImGui::InputText("source", &buf)) {
            u.textKey = "doc:source";
            u.text = buf;
        }
        at_track("snd:doc:source", editable);
        if (ImGui::IsItemHovered(ImGuiHoveredFlags_AllowWhenDisabled)) ImGui::SetTooltip("The sound the chain starts from: a sound file, a sound patch (*.sfx.json) or another audio document.");
        if (ImGui::IsItemDeactivatedAfterEdit() && u.textKey == "doc:source") {
            sound_edited(m.set_document(Json::object({{"source", u.text}})));
            u.textKey.clear();
        }
        const std::string fmt = doc.contains("output") && doc["output"].is_object() ? doc["output"].value("format", std::string("wav")) : std::string("wav");
        ImGui::SetNextItemWidth(90);
        if (ImGui::BeginCombo("format", fmt.c_str())) {
            for (const char* f : {"wav", "ogg"})
                if (ImGui::Selectable(f, fmt == f)) sound_edited(m.set_document(Json::object({{"output", Json::object({{"format", f}})}})));
            ImGui::EndCombo();
        }
        at_track("snd:doc:format", editable);
        ImGui::SameLine();
        const std::string chans = doc.contains("output") && doc["output"].is_object() ? doc["output"].value("channels", std::string("source")) : std::string("source");
        ImGui::SetNextItemWidth(90);
        if (ImGui::BeginCombo("channels", chans.c_str())) {
            for (const char* f : {"source", "mono"})
                if (ImGui::Selectable(f, chans == f)) sound_edited(m.set_document(Json::object({{"output", Json::object({{"channels", f}})}})));
            ImGui::EndCombo();
        }
        at_track("snd:doc:channels", editable);
    }
    ImGui::SeparatorText("Steps");
    const std::vector<SoundChainStep> chain = m.chain();
    const int count = int(chain.size());
    for (const SoundChainStep& s : chain) {
        const int i = s.index;
        ImGui::PushID(i);
        bool en = s.enabled;
        if (ImGui::Checkbox("##en", &en)) sound_edited(m.set_step_enabled(i, en));
        at_track("snd:step:" + std::to_string(i) + ":enable", editable);
        if (ImGui::IsItemHovered(ImGuiHoveredFlags_AllowWhenDisabled)) ImGui::SetTooltip("Skip this step without deleting it.");
        ImGui::SameLine();
        const bool open = u.openStep == i;
        std::string label = std::format("{}. {}", i + 1, s.type);
        if (s.reported) label += std::format("   {:.2f} s, peak {:.1f} dB", s.seconds, s.peakDb);
        if (ImGui::Selectable(label.c_str(), open, 0, ImVec2(std::max(60.0f, ImGui::GetContentRegionAvail().x - 120.0f), 0))) u.openStep = open ? -1 : i;
        at_track("snd:step:" + std::to_string(i), true);
        if (ImGui::IsItemHovered(ImGuiHoveredFlags_AllowWhenDisabled))
            for (const AudioStepInfo& info : audio_step_types())
                if (info.type == s.type) ImGui::SetTooltip("%s", info.doc.c_str());
        ImGui::SameLine();
        ImGui::BeginDisabled(i == 0);
        const bool up = ImGui::SmallButton("^");
        at_track("snd:step:" + std::to_string(i) + ":up", editable && i > 0);
        ImGui::EndDisabled();
        ImGui::SameLine();
        ImGui::BeginDisabled(i == count - 1);
        const bool down = ImGui::SmallButton("v");
        at_track("snd:step:" + std::to_string(i) + ":down", editable && i < count - 1);
        ImGui::EndDisabled();
        ImGui::SameLine();
        const bool hear = ImGui::SmallButton("Hear");
        at_track("snd:step:" + std::to_string(i) + ":hear", true);
        if (ImGui::IsItemHovered()) ImGui::SetTooltip("Render and play the chain only up to this step (click again on the last step to hear it all).");
        ImGui::SameLine();
        const bool remove = ImGui::SmallButton("x");
        at_track("snd:step:" + std::to_string(i) + ":remove", editable);
        if (hear) m.set_stop_after(m.stop_after() == i ? -1 : (i == count - 1 ? -1 : i));
        if (open && !(up || down || remove)) draw_sound_step_fields(m, s);
        ImGui::PopID();
        if (up) {
            sound_edited(m.move_step(i, i - 1));
            if (u.openStep == i) u.openStep = i - 1;
            break;
        }
        if (down) {
            sound_edited(m.move_step(i, i + 1));
            if (u.openStep == i) u.openStep = i + 1;
            break;
        }
        if (remove) {
            sound_edited(m.remove_step(i));
            u.openStep = -1;
            break;
        }
    }
    if (m.stop_after() >= 0) ImGui::TextColored(kWarn, "Hearing the chain up to step %d only.", m.stop_after() + 1);
    ImGui::SetNextItemWidth(130);
    if (ImGui::BeginCombo("##newstep", u.newStepType.c_str())) {
        for (const AudioStepInfo& info : audio_step_types()) {
            if (ImGui::Selectable(info.type.c_str(), info.type == u.newStepType)) u.newStepType = info.type;
            at_track("snd:step:type:" + info.type);
            if (ImGui::IsItemHovered()) ImGui::SetTooltip("%s", info.doc.c_str());
        }
        ImGui::EndCombo();
    }
    at_track("snd:step:type");
    ImGui::SameLine();
    if (ImGui::Button("Add step")) {
        const SoundEditOutcome out = m.add_step(u.newStepType);
        sound_edited(out);
        if (out.ok) u.openStep = int(m.chain().size()) - 1;
    }
    at_track("snd:step:add", editable);
    if (ImGui::IsItemHovered(ImGuiHoveredFlags_AllowWhenDisabled)) ImGui::SetTooltip("Adds a step of that type at the end (before a loop step); its fields show when you click it.");
    ImGui::EndDisabled();
    if (m.loop_step() >= 0) {
        const auto lp = m.loop_seconds();
        ImGui::TextDisabled("Loop points: drag the orange markers on the waveform%s.",
                            lp ? std::format(" ({:.3f} - {:.3f} s)", lp->first, lp->second).c_str() : "");
    }
}

void Editor::draw_sound_step_fields(SoundModel& m, const SoundChainStep& s) {
    SoundUi& u = sound_;
    const bool editable = play_ == PlayState::Edit;
    const AudioStepInfo* info = nullptr;
    for (const AudioStepInfo& i : audio_step_types())
        if (i.type == s.type) info = &i;
    if (!info) return;
    const Json& shownDoc = m.shown_json();
    const Json step = shownDoc.contains("steps") && shownDoc["steps"].is_array() && std::size_t(s.index) < shownDoc["steps"].size() ? shownDoc["steps"][std::size_t(s.index)] : s.params;
    ImGui::Indent();
    ImGui::BeginDisabled(!editable);
    for (const AudioFieldInfo& f : info->fields) {
        ImGui::PushID(f.key.c_str());
        const std::string tag = "snd:step:" + std::to_string(s.index) + ":" + f.key;
        const Json* cur = step.is_object() && step.contains(f.key) ? &step[f.key] : nullptr;
        auto tip = [&] {
            if (!ImGui::IsItemHovered(ImGuiHoveredFlags_AllowWhenDisabled)) return;
            std::string t = f.doc;
            if (f.min && f.max) t += std::format("\n({} to {}{})", *f.min, *f.max, f.def ? ", default " + f.def->dump() : "");
            else if (f.def) t += "\n(default " + f.def->dump() + ")";
            ImGui::SetTooltip("%s", t.c_str());
        };
        const float width = std::max(110.0f, ImGui::GetContentRegionAvail().x * 0.5f);
        ImGui::SetNextItemWidth(width);
        if (f.type == "number" || f.type == "integer") {
            const bool integer = f.type == "integer";
            double v = cur && cur->is_number() ? cur->get<double>() : (f.def && f.def->is_number() ? f.def->get<double>() : f.min.value_or(0.0));
            bool changed;
            if (f.min && f.max) {
                ImGuiSliderFlags flags = ImGuiSliderFlags_AlwaysClamp;
                if (*f.min > 0 && *f.max / *f.min >= 100.0) flags |= ImGuiSliderFlags_Logarithmic;
                double lo = *f.min, hi = *f.max;
                if (integer) {
                    int iv = int(std::lround(v));
                    changed = ImGui::SliderInt(f.key.c_str(), &iv, int(lo), int(hi), "%d", flags);
                    v = iv;
                } else {
                    changed = ImGui::SliderScalar(f.key.c_str(), ImGuiDataType_Double, &v, &lo, &hi, "%.4g", flags);
                }
            } else {
                double lo = f.min.value_or(-1e9), hi = f.max.value_or(1e9);
                changed = ImGui::DragScalar(f.key.c_str(), ImGuiDataType_Double, &v, integer ? 1.0f : std::max(0.001f, float(std::abs(v)) * 0.01f), &lo, &hi, integer ? "%.0f" : "%.4g");
            }
            at_track(tag, editable);
            tip();
            if (changed) m.preview_step(s.index, Json::object({{f.key, integer ? Json(static_cast<long long>(std::llround(v))) : Json(v)}}));
            if (ImGui::IsItemDeactivated() && m.field_previewing()) sound_edited(m.commit_step("Set " + s.type + " " + f.key));
        } else if (f.type == "boolean") {
            bool b = cur && cur->is_boolean() ? cur->get<bool>() : (f.def && f.def->is_boolean() ? f.def->get<bool>() : false);
            if (ImGui::Checkbox(f.key.c_str(), &b)) sound_edited(m.set_step(s.index, Json::object({{f.key, b}}), "Set " + s.type + " " + f.key));
            at_track(tag, editable);
            tip();
        } else if (f.type == "string" && !f.choices.empty()) {
            const std::string c = cur && cur->is_string() ? cur->get<std::string>() : (f.def && f.def->is_string() ? f.def->get<std::string>() : std::string());
            if (ImGui::BeginCombo(f.key.c_str(), c.empty() ? "(unset)" : c.c_str())) {
                for (const std::string& ch : f.choices) {
                    if (ImGui::Selectable(ch.c_str(), ch == c)) sound_edited(m.set_step(s.index, Json::object({{f.key, ch}}), "Set " + s.type + " " + f.key));
                    at_track(tag + ":" + ch, editable);
                }
                ImGui::EndCombo();
            }
            at_track(tag, editable);
            tip();
        } else {
            const bool isText = f.type == "string" || f.type == "path";
            const std::string key = "step:" + std::to_string(s.index) + ":" + f.key;
            const std::string shown = cur ? (isText && cur->is_string() ? cur->get<std::string>() : cur->dump()) : (f.def ? (isText && f.def->is_string() ? f.def->get<std::string>() : f.def->dump()) : std::string());
            std::string buf = u.textKey == key ? u.text : shown;
            if (ImGui::InputText(f.key.c_str(), &buf)) {
                u.textKey = key;
                u.text = buf;
            }
            at_track(tag, editable);
            tip();
            if (ImGui::IsItemDeactivatedAfterEdit() && u.textKey == key) {
                Json v;
                bool ok = true;
                if (isText) {
                    v = u.text;
                } else {
                    auto j = parse_json(u.text, f.key);
                    ok = j.ok();
                    if (ok) v = *j;
                }
                if (u.text.empty() && !f.required) v = nullptr;
                if (ok) sound_edited(m.set_step(s.index, Json::object({{f.key, v}}), "Set " + s.type + " " + f.key));
                else notify(f.key + ": that is not valid JSON.", 1);
                u.textKey.clear();
            } else if (ImGui::IsItemDeactivated() && u.textKey == key) {
                u.textKey.clear();
            }
        }
        ImGui::PopID();
    }
    ImGui::EndDisabled();
    ImGui::Unindent();
}

// ------------------------------------------------------------------------------------------------------- listen / A-B ----
void Editor::draw_sound_ab(SoundModel& m) {
    SoundUi& u = sound_;
    ImGui::SeparatorText("A / B");
    const SoundVariantInfo vi = m.kind() == SoundKind::Patch ? m.variations() : SoundVariantInfo{};
    auto slot_combo = [&](const char* id, SoundSlot& slot, const char* tag) {
        ImGui::SetNextItemWidth(130);
        if (ImGui::BeginCombo(id, sound_slot_label(slot).c_str())) {
            auto item = [&](const SoundSlot& s, bool enabled) {
                ImGui::BeginDisabled(!enabled);
                if (ImGui::Selectable(sound_slot_label(s).c_str(), s == slot)) slot = s;
                at_track(std::string(tag) + ":" + sound_slot_label(s), enabled);
                ImGui::EndDisabled();
            };
            item({SoundSlotKind::Current, 0}, true);
            item({SoundSlotKind::Before, 0}, m.before() != nullptr);
            item({SoundSlotKind::Baked, 0}, m.kind() != SoundKind::File && !m.baked_path().empty());
            for (int v = 1; v <= vi.count; ++v) item({SoundSlotKind::Variant, v}, true);
            ImGui::EndCombo();
        }
        at_track(tag);
    };
    ImGui::TextUnformatted("A");
    ImGui::SameLine();
    slot_combo("##slota", u.slotA, "snd:slot_a");
    ImGui::SameLine();
    if (toggle_button("Play A", u.heard == 1, ImVec2(64, 0))) sound_play_slot(1);
    at_track("snd:ab_a");
    ImGui::TextUnformatted("B");
    ImGui::SameLine();
    slot_combo("##slotb", u.slotB, "snd:slot_b");
    ImGui::SameLine();
    if (toggle_button("Play B", u.heard == 2, ImVec2(64, 0))) sound_play_slot(2);
    at_track("snd:ab_b");
    ImGui::SameLine();
    if (ImGui::Button("Swap")) std::swap(u.slotA, u.slotB);
    at_track("snd:ab_swap");
    ImGui::Checkbox("Same loudness", &u.levelMatch);
    at_track("snd:level");
    if (ImGui::IsItemHovered()) ImGui::SetTooltip("Plays the louder of A and B quieter, by the difference of their LUFS, so a louder sound does not win just for being louder. Nothing is boosted, so nothing clips.");
    SoundRenderPtr a = m.slot(u.slotA), b = m.slot(u.slotB);
    if (a && b) {
        const auto g = sound_level_match(a->lufs, b->lufs);
        ImGui::TextDisabled("A %.1f LUFS, peak %.1f dB   |   B %.1f LUFS, peak %.1f dB%s", a->lufs, a->peakDb, b->lufs, b->peakDb,
                            u.levelMatch ? std::format("   |   A {:+.1f} dB, B {:+.1f} dB", g.first, g.second).c_str() : "");
    } else {
        ImGui::TextDisabled("%s", (!a || !b) ? "Rendering, or there is nothing to compare yet. Edit the sound, then compare it with Before." : "");
    }
}

void Editor::draw_sound_variants(SoundModel& m) {
    SoundUi& u = sound_;
    const SoundVariantInfo vi = m.variations();
    ImGui::SeparatorText("Variants");
    if (vi.count <= 0) {
        ImGui::TextDisabled("This patch declares no variations. Add a \"variations\" object (count, seed, spread) in the inspector to make takes of it.");
        return;
    }
    ImGui::TextDisabled("%d variants, seed %llu: pitch +-%.0f cents, length +-%.0f%%, gain +-%.1f dB, filter +-%.2f oct", vi.count, (unsigned long long)vi.seed, vi.pitchCents,
                        vi.lengthFraction * 100.0, vi.gainDb, vi.filterOctaves);
    for (int n = 1; n <= vi.count; ++n) {
        ImGui::PushID(n);
        if (ImGui::SmallButton("Play")) {
            u.slotA = SoundSlot{SoundSlotKind::Variant, n};
            sound_play_slot(1);
        }
        at_track("snd:variant:" + std::to_string(n));
        ImGui::SameLine();
        if (ImGui::SmallButton("A")) u.slotA = SoundSlot{SoundSlotKind::Variant, n};
        at_track("snd:variant:" + std::to_string(n) + ":a");
        ImGui::SameLine();
        if (ImGui::SmallButton("B")) u.slotB = SoundSlot{SoundSlotKind::Variant, n};
        at_track("snd:variant:" + std::to_string(n) + ":b");
        ImGui::SameLine();
        ImGui::Text("Variant %d", n);
        ImGui::PopID();
        if (n >= 32 && vi.count > 32) {
            ImGui::TextDisabled("... and %d more (pick them in the A / B lists)", vi.count - 32);
            break;
        }
    }
}

void Editor::draw_sound_presets(SoundModel& m) {
    SoundUi& u = sound_;
    const bool editable = play_ == PlayState::Edit;
    ImGui::SeparatorText("Presets and family");
    ImGui::BeginDisabled(!editable);
    ImGui::SetNextItemWidth(160);
    if (ImGui::BeginCombo("##preset", u.presetPick.empty() ? "Start from a preset..." : u.presetPick.c_str())) {
        for (const SfxPresetInfo& p : sfx_presets()) {
            if (ImGui::Selectable(p.name.c_str(), p.name == u.presetPick)) u.presetPick = p.name;
            at_track("snd:preset:" + p.name);
            if (ImGui::IsItemHovered()) ImGui::SetTooltip("%s", p.what.c_str());
        }
        ImGui::EndCombo();
    }
    at_track("snd:preset");
    ImGui::SameLine();
    ImGui::BeginDisabled(u.presetPick.empty());
    if (ImGui::Button("Replace patch")) sound_edited(m.apply_preset(u.presetPick));
    at_track("snd:preset:apply", editable && !u.presetPick.empty());
    ImGui::EndDisabled();
    if (ImGui::IsItemHovered(ImGuiHoveredFlags_AllowWhenDisabled)) ImGui::SetTooltip("sfx.preset over this file: the patch becomes the preset (a starting point). Ctrl+Z brings the old one back.");
    if (ImGui::Button("Make a UI family")) {
        const SoundEditOutcome out = m.make_family("ui");
        sound_edited(out);
        if (out.ok) notify("A family of sounds is in " + m.family_dir() + ".", 0);
    }
    at_track("snd:family", editable);
    if (ImGui::IsItemHovered(ImGuiHoveredFlags_AllowWhenDisabled))
        ImGui::SetTooltip("sfx.family {preset: \"ui\"}: writes the interface sounds of a game (click, hover, confirm, cancel, error, ...) as patches that share this one's character, into %s. Ctrl+Z removes them.", m.family_dir().c_str());
    ImGui::EndDisabled();
}

}  // namespace fa::editor
