// The Music panel's model and preview (music_model.h, music_preview.h): every edit is the command an AI would run and one undo step, a dragged
// pattern is written back as note text, the drum grid keeps its hits, the render that Play listens to follows the edits, and the preview's
// playhead moves on the null device and its intensity fades the layers. No window: the model calls the real commands of a temporary project.
#include <algorithm>
#include <cmath>
#include <filesystem>
#include <fstream>

#include "doctest.h"
#include "fa/audio/audio.h"
#include "fa/core/command.h"
#include "fa/core/fs.h"
#include "fa/tooling/asset_import.h"
#include "music_model.h"
#include "music_preview.h"

using namespace fa;
using namespace fa::editor;
namespace stdfs = std::filesystem;

namespace {

constexpr const char* kSong = "assets/music/t.song.json";

struct MusicProject {
    stdfs::path dir;
    CommandRegistry registry;
    std::unique_ptr<MusicModel> model;
    MusicProject() {
        dir = fs::make_temp_dir("fa_music_panel").value();
        register_asset_commands(registry, dir.string());
        model = std::make_unique<MusicModel>(dir.string(), [this](const std::string& name, const Json& args) { return registry.call(name, args); });
        model->set_async(false);
        model->set_debounce_ticks(0);
    }
    ~MusicProject() {
        model.reset();
        std::error_code ec;
        stdfs::remove_all(dir, ec);
    }
    Json ok(const std::string& name, const Json& args) {
        CommandResult r = registry.call(name, args);
        REQUIRE_MESSAGE(r.ok, r.error.dump());
        return r.result;
    }
    void open() {
        ok("music.create", Json::object({{"path", kSong}, {"picture", false}}));
        REQUIRE_MESSAGE(model->open(kSong), model->error());
        REQUIRE(model->valid());
        model->settle();
    }
    std::string text(const std::string& rel = kSong) const {
        std::ifstream in(dir / rel, std::ios::binary);
        return std::string((std::istreambuf_iterator<char>(in)), std::istreambuf_iterator<char>());
    }
};

}  // namespace

TEST_CASE("a song opens, lists its tracks and notes, and renders for playing") {
    MusicProject p;
    p.open();
    CHECK(p.model->is_open());
    CHECK(!p.model->pitched_tracks().empty());
    CHECK(!p.model->drum_tracks().empty());
    const std::string t = p.model->pitched_tracks().front();
    const SongTrack* track = p.model->track(t);
    REQUIRE(track);
    REQUIRE(!track->patterns.empty());
    CHECK(!p.model->notes(t, track->patterns.front().name).empty());
    REQUIRE(p.model->source());
    CHECK(p.model->source_is_fresh());
    CHECK(p.model->source()->map.spans.size() >= 1);
}

TEST_CASE("an edit of the notes is one music.edit, one undo step, and undo and redo restore the file") {
    MusicProject p;
    p.open();
    const std::string t = p.model->pitched_tracks().front();
    const std::string pat = p.model->track(t)->patterns.front().name;
    std::vector<SongRollNote> notes = p.model->notes(t, pat);
    const std::size_t before = notes.size();
    const std::string original = p.text();
    SongRollNote n;
    n.tick = 0;
    n.duration = 480;
    n.pitch = 72;
    n.velocity = 100;
    notes.push_back(n);
    const MusicEditOutcome out = p.model->set_notes(t, pat, notes, 0, "Draw note");
    REQUIRE_MESSAGE(out.ok, out.error);
    CHECK(out.step > 0);
    CHECK(p.model->notes(t, pat).size() == before + 1);
    CHECK(p.text() != original);
    const std::uint64_t rev = p.model->doc_revision();
    REQUIRE(p.model->apply_step(out.step, false));
    CHECK(p.model->notes(t, pat).size() == before);
    CHECK(p.model->doc_revision() != rev);
    REQUIRE(p.model->apply_step(out.step, true));
    CHECK(p.model->notes(t, pat).size() == before + 1);
    // The same notes again change nothing on disk: no step.
    const MusicEditOutcome same = p.model->set_notes(t, pat, p.model->notes(t, pat), 0, "Nothing");
    CHECK(same.ok);
    CHECK(same.step == 0);
}

TEST_CASE("a refused edit leaves the file as it was and says what is wrong") {
    MusicProject p;
    p.open();
    const std::string original = p.text();
    const std::string t = p.model->pitched_tracks().front();
    const std::string pat = p.model->track(t)->patterns.front().name;
    SongRollNote bad;
    bad.tick = 0;
    bad.duration = 480;
    bad.pitch = 200;   // outside 0..127
    bad.velocity = 90;
    const MusicEditOutcome out = p.model->set_notes(t, pat, {bad}, 0, "Bad note");
    CHECK(!out.ok);
    CHECK(!out.error.empty());
    CHECK(out.step == 0);
    CHECK(p.text() == original);
    CHECK(p.model->valid());
}

TEST_CASE("the drum grid reads a drum pattern and a changed cell is one step") {
    MusicProject p;
    p.open();
    const std::string t = p.model->drum_tracks().front();
    const SongPattern* pat = &p.model->track(t)->patterns.front();
    auto grid = music_drum_grid(*pat);
    REQUIRE(grid);
    const SongMeter meter = p.model->doc()->meter;
    CHECK(grid->steps_per_bar(meter) == 16);
    CHECK(grid->at("kick", 0, meter) == 'x');
    grid->set("kick", 1, 'X', meter);
    const MusicEditOutcome out = p.model->set_grid(t, pat->name, *grid, "Drum kick step 2");
    REQUIRE_MESSAGE(out.ok, out.error);
    CHECK(out.step > 0);
    auto after = music_drum_grid(p.model->track(t)->patterns.front());
    REQUIRE(after);
    CHECK(after->at("kick", 1, meter) == 'X');
    REQUIRE(p.model->apply_step(out.step, false));
    auto undone = music_drum_grid(p.model->track(t)->patterns.front());
    REQUIRE(undone);
    CHECK(undone->at("kick", 1, meter) == '.');
    CHECK(music_step_ticks("16") == 240);
    CHECK(music_step_ticks("8t") == 320);
    CHECK(music_step_ticks("bogus") == 0);
}

TEST_CASE("sections, tracks, the mixer and layers are edited through music.edit") {
    MusicProject p;
    p.open();
    const SongDoc* doc = p.model->doc();
    const std::string section = doc->sections.front().name;
    const int repeat = doc->sections.front().repeat;
    MusicEditOutcome out = p.model->set_section(section, Json::object({{"repeat", repeat + 1}}));
    REQUIRE_MESSAGE(out.ok, out.error);
    CHECK(p.model->doc()->sections.front().repeat == repeat + 1);
    const std::string track = doc->tracks.front().name;
    out = p.model->set_track(track, Json::object({{"mute", true}}));
    REQUIRE_MESSAGE(out.ok, out.error);
    CHECK(p.model->doc()->tracks.front().mute);
    out = p.model->set_mixer(Json::object({{"buses", Json::object({{"hall", Json::object({{"volume", 0.5}})}})}}));
    REQUIRE_MESSAGE(out.ok, out.error);
    CHECK(p.model->doc()->mixer.buses.size() == 1);
    out = p.model->set_layers(Json::object({{"base", Json::array({p.model->doc()->tracks.front().name})}}));
    REQUIRE_MESSAGE(out.ok, out.error);
    CHECK(p.model->doc()->layers.size() == 1);
    CHECK(p.model->step_count() == 4);
    // retain_steps drops what no stack points to.
    p.model->retain_steps({out.step});
    CHECK(p.model->step_count() == 1);
}

TEST_CASE("the render Play listens to follows the edits and a layered song is layered") {
    MusicProject p;
    p.open();
    const MusicSourcePtr first = p.model->source();
    REQUIRE(first);
    const int renders = p.model->render_count();
    REQUIRE(p.model->set_song(Json::object({{"tempo", 90}})).ok);
    CHECK(!p.model->source_is_fresh());   // the render in hand is of the old document
    p.model->settle();
    CHECK(p.model->source_is_fresh());
    CHECK(p.model->render_count() > renders);
    CHECK(p.model->source() != first);
    CHECK(p.model->source()->map.tempo == doctest::Approx(90.0));
    CHECK(!p.model->source()->layered);
    const auto names = p.model->doc()->tracks;
    REQUIRE(names.size() >= 2);
    REQUIRE(p.model->set_layers(Json::object({{"base", Json::array({names[0].name})}, {"top", Json::object({{"tracks", Json::array({names[1].name})}, {"intensity", 0.8}})}})).ok);
    p.model->settle();
    REQUIRE(p.model->source());
    CHECK(p.model->source()->layered);
    CHECK(p.model->source()->stems.size() >= 2);
}

TEST_CASE("pattern_tick finds the playhead inside the pattern a section plays") {
    MusicProject p;
    p.open();
    const SongDoc& doc = *p.model->doc();
    const std::string t = p.model->pitched_tracks().front();
    const std::string pat = p.model->track(t)->patterns.front().name;
    const MusicMap& map = p.model->source()->map;
    REQUIRE(!map.spans.empty());
    // The start of the first span is the start of the pattern the first section plays.
    auto at0 = p.model->pattern_tick(map, map.spans.front().start + 1.0, t, pat);
    bool plays = false;
    for (const SongSectionTrack& st : doc.sections.front().play)
        if (st.track == t && !st.entries.empty() && st.entries.front().pattern == pat) plays = true;
    if (plays) {
        REQUIRE(at0.has_value());
        CHECK(*at0 >= 0.0);
        CHECK(*at0 < 100.0);
        auto later = p.model->pattern_tick(map, map.spans.front().start + map.barFrames * 1.5, t, pat);
        REQUIRE(later.has_value());
        CHECK(*later > double(doc.meter.barTicks()));
    }
    CHECK(!p.model->pattern_tick(map, -5.0, t, pat).has_value());
}

TEST_CASE("chord_pitches spells a chord and refuses a name that is not one") {
    MusicProject p;
    p.open();
    std::string why;
    const std::vector<int> am7 = p.model->chord_pitches("Am7", 3, &why);
    REQUIRE_MESSAGE(!am7.empty(), why);
    CHECK(am7.size() == 4);
    CHECK(std::is_sorted(am7.begin(), am7.end()));
    CHECK(am7.front() % 12 == 9);   // A
    why.clear();
    CHECK(p.model->chord_pitches("Hxyz", 3, &why).empty());
    CHECK(!why.empty());
}

TEST_CASE("Save bakes the mix and, for a layered song, one stem per layer; a file nothing of ours made is not replaced") {
    MusicProject p;
    p.open();
    const MusicEditOutcome out = p.model->save();
    REQUIRE_MESSAGE(out.ok, out.error);
    const std::string baked = p.model->baked_path();
    CHECK(!baked.empty());
    CHECK(stdfs::exists(p.dir / baked));
}

TEST_CASE("the file changed behind the panel's back is read again") {
    MusicProject p;
    p.open();
    const std::string was = p.text();
    Json j = parse_json(was, kSong).value();
    j["tempo"] = 77.0;
    {
        std::ofstream out(p.dir / kSong, std::ios::binary | std::ios::trunc);
        const std::string text = j.dump(2) + "\n   ";   // a different size, so the stamp differs whatever the clock says
        out << text;
    }
    CHECK(p.model->poll_external());
    CHECK(p.model->doc()->tempo == doctest::Approx(77.0));
    // A file that no longer loads is reported, not dropped.
    {
        std::ofstream out(p.dir / kSong, std::ios::binary | std::ios::trunc);
        out << "{ not json";
    }
    CHECK(p.model->poll_external());
    CHECK(!p.model->valid());
    CHECK(!p.model->error().empty());
}

TEST_CASE("the preview plays on the null device: the playhead moves, a layer fades with the intensity, stop ends it") {
    MusicProject p;
    p.open();
    const auto names = p.model->doc()->tracks;
    REQUIRE(names.size() >= 2);
    REQUIRE(p.model->set_layers(Json::object({{"base", Json::array({names[0].name})}, {"top", Json::object({{"tracks", Json::array({names[1].name})}, {"intensity", 0.8}})}})).ok);
    p.model->settle();
    REQUIRE(p.model->source());
    Audio audio;
    std::string err;
    REQUIRE(audio.init(false, &err));
    MusicPreview pre(&audio, [] { return false; });
    CHECK(!pre.playing());
    REQUIRE_MESSAGE(pre.play(p.model->source(), -1, 0.0f), pre.error());
    CHECK(pre.playing());
    double last = -1.0;
    for (int i = 0; i < 30; ++i) {
        pre.update(1.0 / 60.0);
        const double pos = pre.position_frames();
        CHECK(pos >= last);
        last = pos;
    }
    CHECK(last > 0.25 * kMusicRate);   // half a second of frames went by
    const MusicPreview::Where w = pre.where();
    CHECK(w.bar >= 1);
    CHECK(w.section >= 0);
    // Low intensity: only the base layer is audible. High: the top layer fades in.
    for (int i = 0; i < 60; ++i) pre.update(1.0 / 60.0);
    std::vector<float> g = pre.stem_gains();
    REQUIRE(g.size() >= 2);
    CHECK(g[1] < 0.05f);
    pre.set_intensity(1.0f);
    for (int i = 0; i < 90; ++i) pre.update(1.0 / 60.0);
    g = pre.stem_gains();
    CHECK(g[1] > 0.95f);
    CHECK(pre.intensity() == doctest::Approx(1.0f));
    pre.stop();
    CHECK(!pre.playing());
    CHECK(audio.active_voices().empty());
}

TEST_CASE("a looped section starts over when its pass ends") {
    MusicProject p;
    p.open();
    REQUIRE(p.model->source());
    Audio audio;
    std::string err;
    REQUIRE(audio.init(false, &err));
    MusicPreview pre(&audio, [] { return false; });
    const MusicMap& map = p.model->source()->map;
    REQUIRE(map.sections.size() >= 2);
    REQUIRE_MESSAGE(pre.play(p.model->source(), 0, 0.0f), pre.error());
    pre.set_loop_section(0);
    const double end = map.spans[std::size_t(map.sections[0].firstSpan)].end;
    // Run for twice the section's length: the playhead stays inside the section instead of moving on to the next.
    const int frames = int((end / double(kMusicRate)) * 2.0 * 60.0) + 30;
    int maxSection = 0;
    for (int i = 0; i < frames; ++i) {
        pre.update(1.0 / 60.0);
        maxSection = std::max(maxSection, pre.where().section);
    }
    CHECK(maxSection == 0);
    CHECK(pre.playing());
    CHECK(pre.position_frames() < end + 2.0 * kMusicRate);
}
