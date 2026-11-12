// The Sound panel's model and player (sound_model.h, sound_player.h): every edit is the command an AI would run, a knob drag is a preview until
// it is let go, undo/redo restore the files, A/B level matching, loop points dragged on an audio document, and the player's playhead on the null
// device. No window: the model calls the real commands of a temporary project.
#include <algorithm>
#include <cmath>
#include <filesystem>
#include <chrono>
#include <fstream>
#include <thread>

#include "doctest.h"
#include "fa/audio/audio.h"
#include "fa/core/command.h"
#include "fa/core/fs.h"
#include "fa/tooling/asset_import.h"
#include "sound_model.h"
#include "sound_player.h"

using namespace fa;
using namespace fa::editor;
namespace stdfs = std::filesystem;

namespace {

constexpr const char* kPatch = "assets/audio/coin.sfx.json";
constexpr const char* kDoc = "assets/audio/coin.audio.json";

struct Project {
    stdfs::path dir;
    CommandRegistry registry;
    std::unique_ptr<SoundModel> model;
    Project() {
        dir = fs::make_temp_dir("fa_sound_panel").value();
        register_asset_commands(registry, dir.string());
        model = std::make_unique<SoundModel>(dir.string(), [this](const std::string& name, const Json& args) { return registry.call(name, args); });
        model->set_async(false);
        model->set_debounce_ticks(0);
    }
    ~Project() {
        model.reset();
        std::error_code ec;
        stdfs::remove_all(dir, ec);
    }
    Json ok(const std::string& name, const Json& args) {
        CommandResult r = registry.call(name, args);
        REQUIRE_MESSAGE(r.ok, r.error.dump());
        return r.result;
    }
    stdfs::path file(const std::string& rel) const { return dir / rel; }
    std::string text(const std::string& rel) const {
        std::ifstream in(file(rel), std::ios::binary);
        return std::string((std::istreambuf_iterator<char>(in)), std::istreambuf_iterator<char>());
    }
    void open_patch() {
        ok("sfx.preset", Json::object({{"name", "coin"}, {"path", kPatch}}));
        REQUIRE_MESSAGE(model->open(kPatch), model->error());
        model->settle();
        REQUIRE(model->current());
    }
    // A baked sound and an audio document over it.
    void open_document() {
        ok("sfx.preset", Json::object({{"name", "coin"}, {"path", kPatch}}));
        ok("sfx.render", Json::object({{"path", kPatch}, {"picture", false}}));
        ok("audio.create", Json::object({{"path", kDoc}, {"source", "assets/audio/coin.wav"}, {"bake", false}, {"steps", Json::array({Json::object({{"type", "gain"}, {"db", -3.0}})})}}));
        REQUIRE_MESSAGE(model->open(kDoc), model->error());
        model->settle();
        REQUIRE_MESSAGE(model->current(), model->render_error());
    }
};

}  // namespace

TEST_CASE("a patch opens, renders in the background model and reports its measurements") {
    Project p;
    p.open_patch();
    CHECK(p.model->kind() == SoundKind::Patch);
    CHECK(p.model->valid());
    auto r = p.model->current();
    CHECK(r->frames() > 1000);
    CHECK(r->lufs > -60.0);
    CHECK(r->centroidHz > 100.0);
    CHECK(r->riseSeconds >= 0.0);
    CHECK(!r->peakMax.empty());
    CHECK(r->spectrogram.columns > 0);
    CHECK(p.model->current_is_fresh());
}

TEST_CASE("a knob drag is a preview; letting go is one sfx.tweak undo step") {
    Project p;
    p.open_patch();
    SoundModel& m = *p.model;
    const std::string before = p.text(kPatch);
    const double centroid0 = m.current()->centroidHz;
    m.preview_macro("brightness", 0.9);
    m.settle();
    CHECK(m.macro_previewing());
    CHECK(m.current()->centroidHz > centroid0);
    CHECK(p.text(kPatch) == before);  // nothing written while dragging
    const SoundEditOutcome out = m.commit_macros("Turn brightness");
    REQUIRE_MESSAGE(out.ok, out.error);
    CHECK(out.step > 0);
    CHECK(!m.macro_previewing());
    CHECK(p.text(kPatch) != before);
    m.settle();
    bool seen = false;
    for (const SoundMacro& k : m.macros())
        if (k.name == "brightness") seen = std::abs(k.value - 0.9) < 1e-6;
    CHECK(seen);
    CHECK(m.before());  // the sound before the edit, for A/B
    CHECK(m.apply_step(out.step, false));
    CHECK(p.text(kPatch) == before);
    m.settle();
    CHECK(std::abs(m.current()->centroidHz - centroid0) < 1.0);
    CHECK(m.apply_step(out.step, true));
    CHECK(p.text(kPatch) != before);
}

TEST_CASE("a cancelled drag leaves the file and the sound as they were") {
    Project p;
    p.open_patch();
    SoundModel& m = *p.model;
    const double c0 = m.current()->centroidHz;
    m.preview_macro("brightness", -0.9);
    m.settle();
    CHECK(m.current()->centroidHz < c0);
    m.cancel_macro_preview();
    m.settle();
    CHECK(std::abs(m.current()->centroidHz - c0) < 1.0);
    CHECK(m.step_count() == 0);
}

TEST_CASE("fields are edited by pointer through sfx.edit; an invalid value is refused and writes nothing") {
    Project p;
    p.open_patch();
    SoundModel& m = *p.model;
    const std::string before = p.text(kPatch);
    const SoundEditOutcome bad = m.set_field("/length", -5.0);
    CHECK(!bad.ok);
    CHECK(bad.error.find("length") != std::string::npos);
    CHECK(p.text(kPatch) == before);
    CHECK(m.step_count() == 0);
    const SoundEditOutcome good = m.set_field("/length", 0.3);
    REQUIRE_MESSAGE(good.ok, good.error);
    CHECK(m.json()["length"].get<double>() == doctest::Approx(0.3));
    Json second = m.json()["layers"][0];
    second["gain"] = 0.5;
    const SoundEditOutcome add = m.add_item("/layers", second);
    REQUIRE_MESSAGE(add.ok, add.error);
    CHECK(m.json()["layers"].size() == 2);
    const SoundEditOutcome mv = m.move_item("/layers", 0, 1);
    REQUIRE_MESSAGE(mv.ok, mv.error);
    const SoundEditOutcome rm = m.remove_field("/layers/1");
    REQUIRE_MESSAGE(rm.ok, rm.error);
    CHECK(m.json()["layers"].size() == 1);
    // Undo all the way back.
    CHECK(m.apply_step(rm.step, false));
    CHECK(m.apply_step(mv.step, false));
    CHECK(m.apply_step(add.step, false));
    CHECK(m.apply_step(good.step, false));
    CHECK(p.text(kPatch) == before);
}

TEST_CASE("a slider drag on a field previews in memory and commits one edit") {
    Project p;
    p.open_patch();
    SoundModel& m = *p.model;
    const std::string before = p.text(kPatch);
    const double secs = m.current()->seconds;
    m.preview_field("/length", 1.2);
    m.settle();
    CHECK(m.current()->seconds > secs);
    CHECK(p.text(kPatch) == before);
    const SoundEditOutcome out = m.commit_field("Length");
    REQUIRE_MESSAGE(out.ok, out.error);
    CHECK(p.text(kPatch) != before);
    CHECK(!m.field_previewing());
    m.settle();
    CHECK(m.current()->seconds > secs);
}

TEST_CASE("presets replace the patch in one undo step; a family is one step that undo removes") {
    Project p;
    p.open_patch();
    SoundModel& m = *p.model;
    const std::string before = p.text(kPatch);
    const SoundEditOutcome pre = m.apply_preset("explosion");
    REQUIRE_MESSAGE(pre.ok, pre.error);
    CHECK(p.text(kPatch) != before);
    CHECK(m.apply_step(pre.step, false));
    CHECK(p.text(kPatch) == before);
    const SoundEditOutcome fam = m.make_family("");
    REQUIRE_MESSAGE(fam.ok, fam.error);
    CHECK(fam.step > 0);
    CHECK(stdfs::exists(p.file(m.family_dir())));
    CHECK(m.apply_step(fam.step, false));
    bool anyLeft = false;
    std::error_code ec;
    if (stdfs::exists(p.file(m.family_dir()), ec))
        for (const auto& e : stdfs::recursive_directory_iterator(p.file(m.family_dir()))) anyLeft = anyLeft || e.is_regular_file();
    CHECK(!anyLeft);
    CHECK(m.apply_step(fam.step, true));
    CHECK(stdfs::exists(p.file(m.family_dir())));
}

TEST_CASE("variants render apart, in memory, and A/B picks them") {
    Project p;
    p.open_patch();
    SoundModel& m = *p.model;
    const SoundEditOutcome v = m.set_field("/variations", Json::object({{"count", 3}, {"spread", Json::object({{"pitch", 120}})}}));
    REQUIRE_MESSAGE(v.ok, v.error);
    m.settle();
    CHECK(m.variations().count == 3);
    for (int n = 1; n <= 3; ++n) CHECK(m.variant(n) == nullptr);  // asking starts the render
    m.settle();
    SoundRenderPtr a = m.variant(1), b = m.variant(3);
    REQUIRE(a);
    REQUIRE(b);
    CHECK(a->id != b->id);
    CHECK(a->samples != b->samples);
    CHECK(m.slot(SoundSlot{SoundSlotKind::Variant, 2}));
    CHECK(m.variant(4) == nullptr);  // there are 3
    CHECK(m.slot(SoundSlot{SoundSlotKind::Current, 0}) == m.current());
}

TEST_CASE("level match brings the louder one down to the quieter, never up") {
    auto [a, b] = sound_level_match(-12.0, -18.0);
    CHECK(a == doctest::Approx(-6.0));
    CHECK(b == doctest::Approx(0.0));
    auto [c, d] = sound_level_match(-20.0, -14.0);
    CHECK(c == doctest::Approx(0.0));
    CHECK(d == doctest::Approx(-6.0));
    auto [e, f] = sound_level_match(-70.0, -14.0);  // silence: nothing to match
    CHECK(e == 0.0);
    CHECK(f == 0.0);
}

TEST_CASE("an audio document: the chain is edited by audio.edit, one undo step each, and not baked") {
    Project p;
    p.open_document();
    SoundModel& m = *p.model;
    const std::string before = p.text(kDoc);
    REQUIRE(m.chain().size() == 1);
    CHECK(m.chain()[0].type == "gain");
    CHECK(m.chain()[0].reported);
    const SoundEditOutcome add = m.add_step("fade", -1, Json::object({{"out", 0.05}}));
    REQUIRE_MESSAGE(add.ok, add.error);
    REQUIRE(m.chain().size() == 2);
    const SoundEditOutcome mv = m.move_step(1, 0);
    REQUIRE_MESSAGE(mv.ok, mv.error);
    CHECK(m.chain()[0].type == "fade");
    const SoundEditOutcome off = m.set_step_enabled(0, false);
    REQUIRE_MESSAGE(off.ok, off.error);
    CHECK(!m.chain()[0].enabled);
    const SoundEditOutcome on = m.set_step_enabled(0, true);
    REQUIRE_MESSAGE(on.ok, on.error);
    CHECK(m.chain()[0].enabled);
    const SoundEditOutcome set = m.set_step(1, Json::object({{"db", -9.0}}));
    REQUIRE_MESSAGE(set.ok, set.error);
    const SoundEditOutcome bad = m.set_step(1, Json::object({{"db", 900.0}}));
    CHECK(!bad.ok);
    const SoundEditOutcome rm = m.remove_step(0);
    REQUIRE_MESSAGE(rm.ok, rm.error);
    CHECK(m.chain().size() == 1);
    CHECK(!stdfs::exists(p.file("assets/audio/coin_edit.wav")));  // editing does not bake
    for (int id : {rm.step, set.step, on.step, off.step, mv.step, add.step}) CHECK(m.apply_step(id, false));
    CHECK(p.text(kDoc) == before);
}

TEST_CASE("a loop step: the points are dragged on the waveform and written as the step's start and end") {
    Project p;
    p.open_document();
    SoundModel& m = *p.model;
    CHECK(!m.loop_seconds());
    CHECK(m.loop_step() < 0);
    const double dur = m.current()->seconds;
    REQUIRE(dur > 0.2);
    m.preview_loop(dur * 0.2, dur * 0.8);  // no loop step yet: committing adds one
    CHECK(m.loop_previewing());
    SoundEditOutcome out = m.commit_loop();
    REQUIRE_MESSAGE(out.ok, out.error);
    m.settle();
    REQUIRE(m.loop_step() >= 0);
    REQUIRE(m.loop_seconds());
    CHECK(m.loop_seconds()->first == doctest::Approx(dur * 0.2).epsilon(0.01));
    CHECK(m.loop_seconds()->second == doctest::Approx(dur * 0.8).epsilon(0.02));
    // Drag the end marker.
    const double xf = m.loop_crossfade();
    m.preview_loop(m.loop_seconds()->first, dur * 0.6);
    CHECK(m.loop_seconds()->second == doctest::Approx(dur * 0.6));  // the marker follows the drag at once
    SoundEditOutcome drag = m.commit_loop();
    REQUIRE_MESSAGE(drag.ok, drag.error);
    const Json& step = m.json()["steps"][std::size_t(m.loop_step())];
    CHECK(step["end"].get<double>() == doctest::Approx(dur * 0.6 + xf).epsilon(0.01));
    m.settle();
    CHECK(m.loop_seconds()->second == doctest::Approx(dur * 0.6).epsilon(0.02));
    // The sound before the loop step lets the end be dragged back out.
    SoundRenderPtr ghost;
    for (int i = 0; i < 4 && !ghost; ++i) {
        ghost = m.loop_ghost();
        m.settle();
    }
    REQUIRE(ghost);
    CHECK(ghost->seconds > m.current()->seconds);
    // Undo the drag: the earlier points come back.
    CHECK(m.apply_step(drag.step, false));
    m.settle();
    CHECK(m.loop_seconds()->second == doctest::Approx(dur * 0.8).epsilon(0.02));
}

TEST_CASE("a plain sound is read-only; Make audio document writes a document that never overwrites the original") {
    Project p;
    p.ok("sfx.preset", Json::object({{"name", "coin"}, {"path", kPatch}}));
    p.ok("sfx.render", Json::object({{"path", kPatch}, {"picture", false}}));
    SoundModel& m = *p.model;
    REQUIRE_MESSAGE(m.open("assets/audio/coin.wav"), m.error());
    m.settle();
    CHECK(m.kind() == SoundKind::File);
    CHECK(!m.editable());
    REQUIRE(m.current());
    CHECK(!m.set_field("/length", 1.0).ok);
    const std::string wav = p.text("assets/audio/coin.wav");
    const SoundEditOutcome out = m.make_document();
    REQUIRE_MESSAGE(out.ok, out.error);
    CHECK(stdfs::exists(p.file(kDoc)));
    CHECK(p.text("assets/audio/coin.wav") == wav);
    REQUIRE(m.open(kDoc));
    CHECK(m.kind() == SoundKind::Document);
    CHECK(m.baked_path() != "assets/audio/coin.wav");
}

TEST_CASE("Save bakes the patch next to itself; the knob edit alone does not") {
    Project p;
    p.open_patch();
    SoundModel& m = *p.model;
    CHECK(!stdfs::exists(p.file("assets/audio/coin.wav")));
    REQUIRE(m.set_field("/length", 0.2).ok);
    m.settle();
    CHECK(!stdfs::exists(p.file("assets/audio/coin.wav")));
    const SoundEditOutcome s = m.save();
    REQUIRE_MESSAGE(s.ok, s.error);
    CHECK(stdfs::exists(p.file("assets/audio/coin.wav")));
    SoundRenderPtr baked = m.baked();
    REQUIRE(baked);
    CHECK(baked->seconds == doctest::Approx(m.current()->seconds).epsilon(0.02));
}

TEST_CASE("a file changed behind the panel's back is read again") {
    Project p;
    p.open_patch();
    SoundModel& m = *p.model;
    const double secs = m.current()->seconds;
    p.ok("sfx.edit", Json::object({{"path", kPatch}, {"op", "set"}, {"pointer", "/length"}, {"value", 1.5}}));
    // mtime resolution: make sure the stamp can differ
    std::this_thread::sleep_for(std::chrono::milliseconds(20));
    CHECK(m.poll_external());
    m.settle();
    CHECK(m.current()->seconds > secs);
}

TEST_CASE("the player: a playhead that moves with the null device, a selection, a loop that wraps, stop") {
    Audio audio;
    std::string err;
    REQUIRE(audio.init(false, &err));
    RenderedSound s;
    s.sampleRate = 44100;
    s.channels = 1;
    s.samples.resize(44100);  // one second
    for (std::size_t i = 0; i < s.samples.size(); ++i) s.samples[i] = 0.3f * std::sin(float(i) * 0.05f);
    SoundRenderPtr clip = make_sound_render(s);
    SoundPlayer player(&audio, [] { return false; });
    SoundPlayRequest req;
    req.clip = clip;
    req.name = "test";
    CHECK(player.play(req));
    CHECK(player.playing());
    CHECK(audio.active_voices().size() == 1);
    double last = -1.0;
    for (int i = 0; i < 12; ++i) {
        player.update(1.0 / 60.0);
        const double pos = player.position();
        CHECK(pos >= last);
        last = pos;
    }
    CHECK(last == doctest::Approx(12.0 / 60.0).epsilon(0.08));
    for (int i = 0; i < 80; ++i) player.update(1.0 / 60.0);
    CHECK(!player.playing());  // one second long: finished
    CHECK(audio.active_voices().empty());

    // A selection plays only that part.
    req.from = 0.25;
    req.to = 0.5;
    CHECK(player.play(req));
    for (int i = 0; i < 6; ++i) player.update(1.0 / 60.0);
    CHECK(player.position() >= 0.25);
    CHECK(player.position() <= 0.5);
    for (int i = 0; i < 40; ++i) player.update(1.0 / 60.0);
    CHECK(!player.playing());

    // A loop wraps and goes on; an intro before loopFrom plays once.
    req.from = 0.0;
    req.to = 0.4;
    req.loop = true;
    req.loopFrom = 0.2;
    CHECK(player.play(req));
    for (int i = 0; i < 120; ++i) player.update(1.0 / 60.0);
    CHECK(player.playing());
    CHECK(player.wraps() >= 2);
    CHECK(player.position() >= 0.2);
    CHECK(player.position() <= 0.4);
    // A/B: switching keeps the position.
    const double pos = player.position();
    CHECK(player.switch_to(clip, -6.0, "B"));
    CHECK(player.position() == doctest::Approx(pos).epsilon(0.2).scale(0.1));
    player.stop();
    CHECK(!player.playing());
    audio.shutdown();
}
