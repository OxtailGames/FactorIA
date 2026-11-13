// Autotest sections K3 and M3: the Sound and Music panels.
// Split from autotest_tools.cpp: each section is an Editor::at_section_<id>(AtScript&) that adds its steps to the script,
// called by at_build_tools_script in the order of the full run (autotest_sections.h).
#include <algorithm>
#include <cmath>
#include <cstdlib>
#include <filesystem>
#include <fstream>
#include <iterator>
#include <memory>

#include "auto_play_job.h"
#include "autotest_common.h"
#include "editor_internal.h"
#include "fa/ai/command_hooks.h"
#include "fa/ai/extension_plan.h"
#include "fa/ai/savers.h"
#include "fa/core/jobs.h"
#include "fa/tooling/feedback_share.h"
#include "fa/tooling/net.h"
#include "fa/tooling/qr.h"
#include "sokol_app.h"
#include "imgui_internal.h"
#include "ui_backend.h"

namespace fa::editor {

using namespace at_support;

namespace {

namespace stdfs = std::filesystem;

}  // namespace

void Editor::at_section_K3(AtScript& at) {
    AT_SCRIPT_LOCALS(at)
    // The Sound panel (docs/EDITOR.md, "Sound panel"): a coin patch opens; the brightness knob is dragged (ONE sfx.tweak, one undo step);
    // Play moves the playhead on the null device; a drag on the waveform selects and zooms; the patch gets variations, two variants are
    // compared A/B at the same loudness; an audio document over the baked coin gets a step, a reorder and a loop step whose end marker is
    // dragged on the waveform; Undo/Redo walk the steps through the editor's own stack and Save bakes both sounds. Every wait counts frames.
    {
        struct Ks {
            size_t undo = 0;
            double centroid = 0;
            double loopEnd = 0;
            int steps = 0;
            double position = 0;
            std::string patchBefore;
        };
        auto ks = std::make_shared<Ks>();
        const std::string dir = "assets/at-sound";
        const std::string patch = dir + "/coin.sfx.json";
        const std::string wav = dir + "/coin.wav";
        const std::string doc = dir + "/coin.audio.json";
        auto wait_until = [this, &step](std::function<bool()> cond) {
            step(1, [this, cond] {
                atWaitCount_ = 0;
                atWaitUntil_ = cond;
            });
        };
        auto click_widget = [this, &step](const std::string& name) {
            step(2, [this, name] { inject_mouse(SAPP_EVENTTYPE_MOUSE_MOVE, at_widget(name)); });
            step(2, [this, name] { inject_mouse(SAPP_EVENTTYPE_MOUSE_DOWN, at_widget(name)); });
            step(4, [this, name] { inject_mouse(SAPP_EVENTTYPE_MOUSE_UP, at_widget(name)); });
        };
        auto settled = [this] { return sound_.model && sound_.model->is_open() && !sound_.model->busy() && sound_.model->current() && sound_.model->current_is_fresh(); };
        auto read_text = [this](const std::string& rel) {
            std::ifstream in(projectDir_ + "/" + rel, std::ios::binary);
            return std::string((std::istreambuf_iterator<char>(in)), std::istreambuf_iterator<char>());
        };
        auto run = [this](const std::string& name, const Json& args) {
            const CommandResult r = engine_->commands().call(name, args);
            after_command(name, args, r);
            at_check(r.ok, name + " worked: " + (r.ok ? std::string() : command_error_text(r.error)));
        };
        step(2, [this, ks, dir, patch, wav, doc, run] {
            std::error_code ec;
            stdfs::remove_all(projectDir_ + "/" + dir, ec);   // a leftover of an earlier run
            run("sfx.preset", Json::object({{"name", "coin"}, {"path", patch}}));
            run("sfx.render", Json::object({{"path", patch}, {"out", wav}, {"picture", false}, {"overwrite", true}}));
            run("audio.create", Json::object({{"path", doc}, {"source", wav}, {"bake", false}, {"output", Json::object({{"format", "wav"}, {"path", dir + "/coin_loop.wav"}})}, {"steps", Json::array({Json::object({{"type", "gain"}, {"db", -3}})})}}));
            ks->undo = undo_depth();
            open_sound_document(patch);
        });
        wait_until([this, settled] { return at_visible("snd:wave") && at_visible("snd:play") && settled(); });
        step(3, [this, ks] {
            SoundModel& m = *sound_.model;
            at_check(m.kind() == SoundKind::Patch && m.valid(), "the panel opened the coin patch");
            at_check(m.current() && m.current()->lufs > -60 && m.current()->seconds > 0.05, "...rendered it and measured it");
            at_check(sound_.waveW > 100 && sound_.waveH > 40, "...and the waveform is on screen");
            at_check(at_visible("snd:knob:brightness") && at_visible("snd:save") && at_visible("snd:ab_a") && at_visible("snd:spectrogram"), "...with its knobs, A/B, Save and spectrogram");
            at_check(at_visible("snd:field:/length"), "...and the inspector lists the patch's fields");
            at_check(m.current() && m.current()->spectrogram.columns > 0 && sound_.specView != 0, "...the spectrogram has its texture");
            ks->centroid = m.current() ? m.current()->centroidHz : 0.0;
        });
        snap("editor_sound_panel.png");

        // ---- a knob: dragged up, let go: one sfx.tweak
        step(2, [this] { inject_mouse(SAPP_EVENTTYPE_MOUSE_MOVE, at_widget("snd:knob:brightness")); });
        step(2, [this] { inject_mouse(SAPP_EVENTTYPE_MOUSE_DOWN, at_widget("snd:knob:brightness")); });
        step(2, [this] {
            Vec2 p = at_widget("snd:knob:brightness");
            inject_mouse(SAPP_EVENTTYPE_MOUSE_MOVE, Vec2{p.x, p.y - 12});
        });
        step(2, [this] {
            Vec2 p = at_widget("snd:knob:brightness");
            inject_mouse(SAPP_EVENTTYPE_MOUSE_MOVE, Vec2{p.x, p.y - 30});
        });
        step(2, [this] { at_check(sound_.model->macro_previewing(), "dragging the brightness knob previews it (nothing written yet)"); });
        step(3, [this] { inject_mouse(SAPP_EVENTTYPE_MOUSE_UP, Vec2{at_widget("snd:knob:brightness").x, at_widget("snd:knob:brightness").y}); });
        wait_until(settled);
        step(3, [this, ks, patch, read_text] {
            SoundModel& m = *sound_.model;
            double v = 0;
            for (const SoundMacro& k : m.macros())
                if (k.name == "brightness") v = k.value;
            at_check(v > 0.1, "letting go of the knob made brightness " + std::to_string(v));
            at_check(read_text(patch).find("brightness") != std::string::npos, "...and wrote it into the patch file");
            at_check(undo_depth() == ks->undo + 1, "...as ONE undo step of the editor's stack");
            at_check(m.before() != nullptr, "...and the sound before the turn is kept for the A/B");
            at_check(m.current() && m.current()->centroidHz > ks->centroid, "...the sound got brighter (centroid went up)");
        });

        // ---- play on the null device: the playhead moves; stop. Looped: a slow frame (MSVC Debug) can play a short sound
        // to its end before the Stop click, which would then start it again.
        step(2, [this] { sound_.loopPlay = true; });
        click_widget("snd:play");
        wait_until([this] { return sound_.player && sound_.player->playing() && sound_.player->position() > 0.005; });
        step(2, [this, ks] {
            at_check(sound_.player->playing() && sound_.heard == 3, "Play started the sound and the playhead is moving");
            ks->position = sound_.player->position();
        });
        click_widget("snd:play");
        step(3, [this] {
            at_check(!sound_.player->playing(), "Stop stopped it");
            sound_.loopPlay = false;
        });

        // ---- a drag on the waveform selects, To selection zooms
        step(2, [this] { inject_mouse(SAPP_EVENTTYPE_MOUSE_MOVE, sound_screen_pos(sound_.shownSeconds * 0.2, 0.5)); });
        step(2, [this] { inject_mouse(SAPP_EVENTTYPE_MOUSE_DOWN, sound_screen_pos(sound_.shownSeconds * 0.2, 0.5)); });
        step(2, [this] { inject_mouse(SAPP_EVENTTYPE_MOUSE_MOVE, sound_screen_pos(sound_.shownSeconds * 0.4, 0.5)); });
        step(2, [this] { inject_mouse(SAPP_EVENTTYPE_MOUSE_MOVE, sound_screen_pos(sound_.shownSeconds * 0.6, 0.5)); });
        step(3, [this] { inject_mouse(SAPP_EVENTTYPE_MOUSE_UP, sound_screen_pos(sound_.shownSeconds * 0.6, 0.5)); });
        step(3, [this] {
            at_check(sound_.hasSelection && std::abs(sound_.sel0 - sound_.shownSeconds * 0.2) < sound_.shownSeconds * 0.03 &&
                         std::abs(sound_.sel1 - sound_.shownSeconds * 0.6) < sound_.shownSeconds * 0.03,
                     "a drag on the waveform selected 20% to 60% of the sound");
        });
        click_widget("snd:zoom_selection");
        step(3, [this] { at_check(sound_.viewLen < sound_.shownSeconds * 0.5 && std::abs(sound_.viewStart - sound_.sel0) < 0.01, "To selection zoomed to it"); });
        click_widget("snd:play");
        wait_until([this] { return sound_.player->playing() && sound_.player->position() > sound_.sel0 + 0.003; });
        step(2, [this] { at_check(sound_.player->position() >= sound_.sel0 - 0.01 && sound_.player->position() <= sound_.sel1 + 0.05, "Play with a selection starts at its start"); });
        click_widget("snd:play");
        // On a loaded machine the selection may have played out before that click, which then starts it again: let it end.
        wait_until([this] { return !sound_.player->playing(); });
        click_widget("snd:fit");
        step(2, [this] { at_check(std::abs(sound_.viewLen - sound_.shownSeconds) < 1e-6, "Fit shows the whole sound again"); });

        // ---- variations: added from the inspector, two variants compared A/B
        step(2, [this] {
            sound_edited(sound_.model->set_field("/variations", Json::object({{"count", 3}, {"seed", 7}, {"spread", Json::object({{"pitch", 60}, {"gain", 2}})}}), "Add variations"));
        });
        wait_until([this, settled] { return settled() && at_visible("snd:variant:2"); });
        step(3, [this, ks] {
            SoundModel& m = *sound_.model;
            at_check(m.variations().count >= 2, "Adding variations wrote the variations object (" + std::to_string(m.variations().count) + " variants)");
            at_check(undo_depth() == ks->undo + 2, "...as one undo step");
        });
        click_widget("snd:variant:1:a");
        click_widget("snd:variant:2:b");
        step(2, [this] {
            at_check(sound_.slotA == SoundSlot{SoundSlotKind::Variant, 1} && sound_.slotB == SoundSlot{SoundSlotKind::Variant, 2}, "the variant rows set the A and B slots");
        });
        wait_until([this] { return sound_.model->slot(sound_.slotA) && sound_.model->slot(sound_.slotB); });
        step(2, [this] { sound_.loopPlay = true; });   // a coin is short: loop it so the A/B has something to switch
        click_widget("snd:ab_a");
        wait_until([this] { return sound_.player->playing() && sound_.player->position() > 0.003; });
        step(2, [this, ks] {
            at_check(sound_.heard == 1, "Play A plays variant 1");
            ks->position = sound_.player->position();
        });
        click_widget("snd:ab_b");
        step(3, [this, ks] {
            at_check(sound_.heard == 2 && sound_.player->playing(), "Play B switched to variant 2 without stopping");
            at_check(sound_.player->position() + 0.2 >= ks->position, "...at the same place of the sound");
            SoundRenderPtr a = sound_.model->slot(sound_.slotA), b = sound_.model->slot(sound_.slotB);
            at_check(a && b, "...both variants are rendered");
            if (a && b) {
                const auto g = sound_level_match(a->lufs, b->lufs);
                at_check(std::min(g.first, g.second) <= 0.0 && std::max(g.first, g.second) == 0.0, "...the louder one is played quieter and nothing is boosted");
                at_check(std::abs((a->lufs + g.first) - (b->lufs + g.second)) < 0.05 || (a->lufs <= -69 || b->lufs <= -69), "...so A and B come out equally loud");
            }
        });
        click_widget("snd:play");
        step(2, [this] { at_check(!sound_.player->playing(), "Stop stopped the A/B"); });

        // ---- undo / redo through the editor's stack
        step(2, [this] { undo(); });
        wait_until(settled);
        step(3, [this, ks] {
            at_check(undo_depth() == ks->undo + 1 && sound_.model->variations().count == 0, "Undo took the variations out of the patch");
        });
        step(2, [this] { redo(); });
        wait_until(settled);
        step(3, [this, ks] {
            at_check(undo_depth() == ks->undo + 2 && sound_.model->variations().count >= 2, "Redo put them back");
        });
        click_widget("snd:save");
        step(10, [this, patch, read_text] {
            at_check(!read_text("assets/at-sound/coin.wav").empty(), "Save baked the coin next to the patch");
            at_check(stdfs::exists(projectDir_ + "/assets/at-sound/coin_01.wav") && stdfs::exists(projectDir_ + "/assets/at-sound/coin_03.wav"), "...and its three variants (coin_01.wav ...)");
            (void)patch;
        });

        // ---- an audio document: the chain
        step(2, [this, ks, doc] {
            ks->undo = undo_depth();
            open_sound_document(doc);
        });
        wait_until([this, settled] { return settled() && at_visible("snd:step:0") && at_visible("snd:step:add"); });
        step(3, [this, ks] {
            SoundModel& m = *sound_.model;
            at_check(m.kind() == SoundKind::Document && m.chain().size() == 1 && m.chain()[0].type == "gain", "the audio document opened with its one step");
            ks->steps = int(m.chain().size());
            ks->loopEnd = m.current() ? m.current()->seconds : 0.0;
        });
        click_widget("snd:step:add");
        wait_until([this, settled, ks] { return settled() && int(sound_.model->chain().size()) == ks->steps + 1; });
        step(3, [this, ks] {
            at_check(sound_.model->chain().back().type == "gain" && undo_depth() == ks->undo + 1, "Add step appended a gain step as one undo step");
        });
        click_widget("snd:step:1:up");
        step(4, [this, ks] {
            at_check(sound_.model->chain().size() == 2 && undo_depth() == ks->undo + 2, "the up button reordered the chain as one undo step");
        });
        click_widget("snd:step:0:enable");
        wait_until(settled);
        step(3, [this, ks] {
            at_check(!sound_.model->chain()[0].enabled && undo_depth() == ks->undo + 3, "the checkbox skips a step");
        });
        // a loop step, then its end marker is dragged
        step(2, [this] { sound_.newStepType = "loop"; });
        click_widget("snd:step:add");
        wait_until([this, settled] { return settled() && sound_.model->loop_step() >= 0 && sound_.model->loop_seconds() && at_visible("snd:loop_end"); });
        step(3, [this, ks] {
            const auto lp = sound_.model->loop_seconds();
            at_check(lp.has_value(), "a loop step makes loop points that show on the waveform");
            ks->loopEnd = lp ? lp->second : 0.0;
        });
        step(2, [this] { inject_mouse(SAPP_EVENTTYPE_MOUSE_MOVE, at_widget("snd:loop_end")); });
        step(2, [this] { inject_mouse(SAPP_EVENTTYPE_MOUSE_DOWN, at_widget("snd:loop_end")); });
        step(2, [this, ks] { inject_mouse(SAPP_EVENTTYPE_MOUSE_MOVE, sound_screen_pos(ks->loopEnd * 0.8, 0.5)); });
        step(2, [this, ks] { inject_mouse(SAPP_EVENTTYPE_MOUSE_MOVE, sound_screen_pos(ks->loopEnd * 0.6, 0.5)); });
        step(2, [this, ks] {
            auto lp = sound_.model->loop_seconds();
            at_check(sound_.model->loop_previewing() && lp && std::abs(lp->second - ks->loopEnd * 0.6) < ks->loopEnd * 0.04, "dragging the loop end marker moves it on the waveform at once");
        });
        step(3, [this, ks] { inject_mouse(SAPP_EVENTTYPE_MOUSE_UP, sound_screen_pos(ks->loopEnd * 0.6, 0.5)); });
        wait_until(settled);
        step(3, [this, ks, doc, read_text] {
            auto lp = sound_.model->loop_seconds();
            at_check(lp && std::abs(lp->second - ks->loopEnd * 0.6) < ks->loopEnd * 0.05, "letting go wrote the new loop end");
            at_check(undo_depth() == ks->undo + 5, "...as one undo step");
            at_check(read_text(doc).find("\"loop\"") != std::string::npos, "...into the document's loop step");
        });
        snap("editor_sound_loop.png");
        step(2, [this] { undo(); });
        wait_until(settled);
        step(3, [this, ks] {
            auto lp = sound_.model->loop_seconds();
            at_check(lp && std::abs(lp->second - ks->loopEnd) < ks->loopEnd * 0.03, "Undo put the loop end back");
        });
        step(2, [this] { redo(); });
        wait_until(settled);
        click_widget("snd:save");
        step(10, [this, doc] {
            const std::string out = sound_.model->baked_path();
            at_check(!out.empty() && stdfs::exists(projectDir_ + "/" + out), "Save baked the document's sound: " + out);
            const std::string assets = [&] {
                std::ifstream in(projectDir_ + "/assets.json", std::ios::binary);
                return std::string((std::istreambuf_iterator<char>(in)), std::istreambuf_iterator<char>());
            }();
            at_check(assets.find("loopEnd") != std::string::npos, "...and wrote the loop points into assets.json");
            (void)doc;
        });
        step(2, [this, dir] {
            FA_INFO("autotest", "sound panel: last render {:.1f} ms", sound_.model->last_render_ms());
            showSound_ = false;
            sound_close_document();
            std::error_code ec;
            stdfs::remove_all(projectDir_ + "/" + dir, ec);
            project_files_changed();
        });
    }
}

void Editor::at_section_M3(AtScript& at) {
    AT_SCRIPT_LOCALS(at)
    // The Music panel (docs/EDITOR.md, "Music panel"): a layered song opens; a note is drawn on the piano roll, moved and deleted with the
    // mouse (each ONE music.edit, one undo step) and Undo/Redo walk them through the editor's stack; a drum hit is a click on the grid; a
    // section's repeat is raised and a track muted in the Mixer; Play moves the playhead on the null device, the intensity buttons fade
    // the top layer in and out, Play section loops a section; Save bakes the mix and the layers' stems. Every wait counts frames or state.
    {
        struct Ms {
            size_t undo = 0;
            size_t notes = 0;
            int pitch = 0;
            double position = 0;
            int renders = 0;
        };
        auto ms = std::make_shared<Ms>();
        const std::string dir = "assets/at-music";
        const std::string song = dir + "/t.song.json";
        auto wait_until = [this, &step](std::function<bool()> cond) {
            step(1, [this, cond] {
                atWaitCount_ = 0;
                atWaitUntil_ = cond;
            });
        };
        auto click_widget = [this, &step](const std::string& name) {
            step(2, [this, name] { inject_mouse(SAPP_EVENTTYPE_MOUSE_MOVE, at_widget(name)); });
            step(2, [this, name] { inject_mouse(SAPP_EVENTTYPE_MOUSE_DOWN, at_widget(name)); });
            step(4, [this, name] { inject_mouse(SAPP_EVENTTYPE_MOUSE_UP, at_widget(name)); });
        };
        auto settled = [this] { return music_.model && music_.model->is_open() && music_.model->valid() && !music_.model->busy() && music_.model->source_is_fresh(); };
        auto run = [this](const std::string& name, const Json& args) {
            const CommandResult r = engine_->commands().call(name, args);
            after_command(name, args, r);
            at_check(r.ok, name + " worked: " + (r.ok ? std::string() : command_error_text(r.error)));
        };
        // The note of the roll's track/pattern that starts near `tick` at `pitch`, or null.
        auto note_at = [this](std::int64_t tick, int pitch) -> std::optional<SongRollNote> {
            for (const SongRollNote& n : music_.model->notes(music_.track, music_.pattern))
                if (n.pitch == pitch && std::llabs(n.tick - tick) <= 40) return n;
            return std::nullopt;
        };
        auto section_repeat = [this](const std::string& name) {
            for (const SongSection& sec : music_.model->doc()->sections)
                if (sec.name == name) return sec.repeat;
            return -1;
        };
        step(2, [this, song, run] {
            std::error_code ec;
            stdfs::remove_all(projectDir_ + "/assets/at-music", ec);   // a leftover of an earlier run
            run("music.create", Json::object({{"path", song}, {"picture", false}}));
            Json layers = Json::object();
            layers["base"] = Json::array({"drums", "bass"});
            layers["lift"] = Json::object({{"tracks", Json::array({"pad"})}, {"intensity", 0.5}});
            layers["top"] = Json::object({{"tracks", Json::array({"arp"})}, {"intensity", 0.9}});
            Json op = Json::object({{"op", "set_layers"}, {"layers", layers}});
            run("music.edit", Json::object({{"path", song}, {"ops", Json::array({op})}}));
            open_music_document(song);
        });
        wait_until([this, settled] { return at_visible("mus:roll") && at_visible("mus:play") && settled(); });
        step(3, [this, ms] {
            MusicModel& m = *music_.model;
            at_check(m.valid() && !m.pitched_tracks().empty() && !m.drum_tracks().empty(), "the panel opened the song with its pitched and drum tracks");
            at_check(m.source() && m.source()->layered && m.source()->stems.size() == 3, "...rendered it for playing, as three layers");
            at_check(!music_.track.empty() && !music_.pattern.empty() && !music_.model->notes(music_.track, music_.pattern).empty(), "...and the roll shows the notes of " + music_.track + "/" + music_.pattern);
            at_check(at_visible("mus:save") && at_visible("mus:intensity") && at_visible("mus:tab_mixer") && at_visible("mus:velocity_lane"), "...with its transport, tabs and Save");
            ms->undo = undo_depth();
            ms->notes = music_.model->notes(music_.track, music_.pattern).size();
            ms->pitch = music_.pitchTop - 3;   // a row above the chords
        });
        snap("editor_music_panel.png");

        // ---- a note: drawn with a drag, moved, deleted
        step(2, [this, ms] { inject_mouse(SAPP_EVENTTYPE_MOUSE_MOVE, music_screen_pos(1200, ms->pitch)); });
        step(2, [this, ms] { inject_mouse(SAPP_EVENTTYPE_MOUSE_DOWN, music_screen_pos(1200, ms->pitch)); });
        step(2, [this, ms] { inject_mouse(SAPP_EVENTTYPE_MOUSE_MOVE, music_screen_pos(1500, ms->pitch)); });
        step(2, [this, ms] { inject_mouse(SAPP_EVENTTYPE_MOUSE_MOVE, music_screen_pos(1700, ms->pitch)); });
        step(3, [this, ms] { inject_mouse(SAPP_EVENTTYPE_MOUSE_UP, music_screen_pos(1700, ms->pitch)); });
        wait_until(settled);
        step(3, [this, ms, note_at] {
            const auto n = note_at(960, ms->pitch);
            at_check(n.has_value() && n->duration == 960, "a drag on the empty roll drew a note one beat long");
            at_check(music_.model->notes(music_.track, music_.pattern).size() == ms->notes + 1 && undo_depth() == ms->undo + 1, "...as one undo step");
        });
        step(2, [this, ms] { inject_mouse(SAPP_EVENTTYPE_MOUSE_MOVE, music_screen_pos(1440, ms->pitch)); });
        step(2, [this, ms] { inject_mouse(SAPP_EVENTTYPE_MOUSE_DOWN, music_screen_pos(1440, ms->pitch)); });
        step(2, [this, ms] { inject_mouse(SAPP_EVENTTYPE_MOUSE_MOVE, music_screen_pos(1900, ms->pitch + 1)); });
        step(2, [this, ms] { inject_mouse(SAPP_EVENTTYPE_MOUSE_MOVE, music_screen_pos(2400, ms->pitch + 2)); });
        step(3, [this, ms] { inject_mouse(SAPP_EVENTTYPE_MOUSE_UP, music_screen_pos(2400, ms->pitch + 2)); });
        wait_until(settled);
        step(3, [this, ms, note_at] {
            const auto n = note_at(1920, ms->pitch + 2);
            at_check(n.has_value() && n->duration == 960 && !note_at(960, ms->pitch), "dragging the note moved it a beat later and two semitones up");
            at_check(music_.model->notes(music_.track, music_.pattern).size() == ms->notes + 1 && undo_depth() == ms->undo + 2, "...as one undo step");
        });
        step(2, [this, ms] { inject_mouse(SAPP_EVENTTYPE_MOUSE_MOVE, music_screen_pos(2200, ms->pitch + 2)); });
        step(2, [this, ms] { inject_mouse(SAPP_EVENTTYPE_MOUSE_DOWN, music_screen_pos(2200, ms->pitch + 2), 1); });
        step(3, [this, ms] { inject_mouse(SAPP_EVENTTYPE_MOUSE_UP, music_screen_pos(2200, ms->pitch + 2), 1); });
        wait_until(settled);
        step(3, [this, ms, note_at] {
            at_check(!note_at(1920, ms->pitch + 2) && music_.model->notes(music_.track, music_.pattern).size() == ms->notes, "a right click deleted the note");
            at_check(undo_depth() == ms->undo + 3, "...as one undo step");
        });
        step(2, [this] { undo(); });
        wait_until(settled);
        step(3, [this, ms, note_at] { at_check(note_at(1920, ms->pitch + 2).has_value() && undo_depth() == ms->undo + 2, "Undo brought the note back"); });
        step(2, [this] { undo(); });
        step(2, [this] { undo(); });
        wait_until(settled);
        step(3, [this, ms] {
            at_check(music_.model->notes(music_.track, music_.pattern).size() == ms->notes && undo_depth() == ms->undo, "two more Undos took the drawn note out again");
        });
        step(2, [this] { redo(); });
        wait_until(settled);
        step(3, [this, ms, note_at] { at_check(note_at(960, ms->pitch).has_value() && undo_depth() == ms->undo + 1, "Redo drew it again"); });
        step(2, [this] { undo(); });
        wait_until(settled);

        // ---- the drum grid
        click_widget("mus:tab_drums");
        wait_until([this] { return at_visible("mus:drumgrid") && !music_.gridLanes.empty(); });
        step(2, [this, ms] {
            ms->undo = undo_depth();
            const auto g = music_drum_grid(*music_.model->pattern(music_.drumTrack, music_.drumPattern));
            at_check(g.has_value() && g->at("snare", 1, music_.model->doc()->meter) == '.', "the drum grid shows the groove with an empty snare cell");
        });
        step(2, [this] { inject_mouse(SAPP_EVENTTYPE_MOUSE_MOVE, music_drum_cell_pos("snare", 1)); });
        step(2, [this] { inject_mouse(SAPP_EVENTTYPE_MOUSE_DOWN, music_drum_cell_pos("snare", 1)); });
        step(4, [this] { inject_mouse(SAPP_EVENTTYPE_MOUSE_UP, music_drum_cell_pos("snare", 1)); });
        wait_until(settled);
        step(3, [this, ms] {
            const auto g = music_drum_grid(*music_.model->pattern(music_.drumTrack, music_.drumPattern));
            at_check(g.has_value() && g->at("snare", 1, music_.model->doc()->meter) == 'x', "a click on the grid put a snare hit on step 2");
            at_check(undo_depth() == ms->undo + 1, "...as one undo step");
        });

        // ---- the arrangement: a section repeats once more
        click_widget("mus:tab_arrangement");
        wait_until([this] { return at_visible("mus:repeat_plus:loop"); });
        step(2, [this, ms, section_repeat] {
            ms->undo = undo_depth();
            ms->renders = section_repeat("loop");
        });
        click_widget("mus:repeat_plus:loop");
        wait_until(settled);
        step(3, [this, ms, section_repeat] {
            at_check(section_repeat("loop") == ms->renders + 1, "the + button raised the loop section's repeat");
            at_check(undo_depth() == ms->undo + 1, "...as one undo step");
            const SongTimeline* tl = music_.model->timeline();
            at_check(tl && tl->spans.size() >= 4, "...and the timeline has one more pass");
        });

        // ---- the mixer: a track muted
        click_widget("mus:tab_mixer");
        wait_until([this] { return at_visible("mus:mute:arp"); });
        step(2, [this, ms] { ms->undo = undo_depth(); });
        click_widget("mus:mute:arp");
        wait_until(settled);
        step(3, [this, ms] {
            const SongTrack* t = music_.model->track("arp");
            at_check(t && t->mute && undo_depth() == ms->undo + 1, "the M button muted the arp track as one undo step");
        });
        step(2, [this] { undo(); });
        wait_until(settled);
        step(3, [this] {
            const SongTrack* t = music_.model->track("arp");
            at_check(t && !t->mute, "Undo unmuted it");
        });

        // ---- play: the playhead moves; the intensity fades the top layer
        click_widget("mus:play");
        wait_until([this] { return music_.preview && music_.preview->playing() && music_.preview->position_frames() > 0.25 * kMusicRate; });
        step(2, [this, ms] {
            ms->position = music_.preview->position_frames();
            at_check(music_.preview->where().section >= 0 && music_.preview->where().bar >= 1, "Play started the song and the playhead is in a section");
        });
        wait_until([this, ms] { return music_.preview->position_frames() > ms->position + 0.25 * kMusicRate; });
        step(2, [this] {
            const std::vector<float> g = music_.preview->stem_gains();
            at_check(g.size() == 3 && g[0] > 0.95f && g[2] < 0.05f, "...the playhead went on, with the base layer in and the top layer out at intensity 0");
        });
        click_widget("mus:int_1");
        wait_until([this] { const auto g = music_.preview->stem_gains(); return g.size() == 3 && g[2] > 0.95f; });
        step(2, [this] { at_check(music_.preview->intensity() > 0.99f, "the Intense button faded the top layer in"); });
        snap("editor_music_playing.png");
        click_widget("mus:int_0");
        wait_until([this] { const auto g = music_.preview->stem_gains(); return g.size() == 3 && g[2] < 0.05f && g[1] < 0.05f; });
        step(2, [this] { at_check(music_.preview->intensity() < 0.01f, "the Calm button faded the layers out again"); });
        click_widget("mus:play");
        step(3, [this] { at_check(!music_.preview->playing(), "Stop stopped it"); });
        // a section, looped
        step(2, [this] {
            music_.section = 1;
            music_.loopSection = true;
        });
        click_widget("mus:play_section");
        wait_until([this] { return music_.preview->playing() && music_.preview->position_frames() > 0.1 * kMusicRate; });
        step(2, [this] {
            at_check(music_.preview->where().section == 1, "Play section started at the selected section");
            at_check(music_.preview->loop_section() == 1, "...and Loop keeps it looping");
        });
        click_widget("mus:play");
        step(3, [this] {
            at_check(!music_.preview->playing(), "Stop stopped the section");
            music_.loopSection = false;
        });

        // ---- Save bakes the mix and the layers
        click_widget("mus:save");
        step(10, [this] {
            const std::string out = music_.model->baked_path();
            at_check(!out.empty() && stdfs::exists(projectDir_ + "/" + out), "Save baked the song's mix: " + out);
            int wavs = 0;
            std::error_code ec;
            for (const auto& e : stdfs::directory_iterator(projectDir_ + "/assets/at-music", ec))
                if (e.path().extension() == ".wav") ++wavs;
            at_check(wavs >= 4, "...and one stem per layer (" + std::to_string(wavs) + " wav files)");
        });
        step(2, [this, dir] {
            FA_INFO("autotest", "music panel: last render {:.1f} ms", music_.model->last_render_ms());
            showMusic_ = false;
            music_close_document();
            std::error_code ec;
            stdfs::remove_all(projectDir_ + "/" + dir, ec);
            project_files_changed();
        });
    }
}

}  // namespace fa::editor
