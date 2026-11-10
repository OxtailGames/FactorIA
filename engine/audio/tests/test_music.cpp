// Adaptive music at runtime (M56.4): the quantization math, the layers, the mode choice, the transport (section jumps, stingers,
// crossfades, events, determinism) on synthetic stems, and the player inside the mixer against the song's own render.
#include <doctest.h>

#include <algorithm>
#include <chrono>
#include <cmath>
#include <string>
#include <vector>

#include "../src/audio_testing.h"
#include "alloc_counter.h"
#include "audio_test_helpers.h"
#include "fa/audio/audio.h"
#include "fa/audio/music_player.h"
#include "fa/audio/music_transport.h"
#include "fa/audio/song.h"
#include "fa/audio/song_preview.h"
#include "fa/core/fs.h"
#include "fa/core/jobs.h"
#include "fa/scene/components.h"
#include "fa/scene/world.h"

using namespace fa;
using audio_test::Recording;

namespace {

// 120 BPM in 4/4: a beat is 22050 frames, a bar 88200. intro (1 bar), main (loop, 2 bars), outro (1 bar); a rhythm layer and a harmony layer
// that comes in at 0.5.
Json demo_json() {
    return Json::parse(R"({
      "format": "factoria.song/1", "tempo": 120, "volume": 1.0,
      "mixer": {"master": {"loudness": "off", "limiter": false}},
      "tracks": {
        "pad": {"instrument": "pad", "patterns": {"a": "(Am@3):1 | (F@3):1", "i": "(Am@3):1", "o": "(F@3):1"}},
        "drums": {"instrument": "kit", "patterns": {"g": {"step": "8", "grid": {"kick": "x...x...", "hat": "x.x.x.x."}}}}
      },
      "layers": {"rhythm": ["drums"], "harmony": {"tracks": ["pad"], "intensity": 0.5}},
      "sections": [
        {"name": "intro", "kind": "intro", "play": {"pad": "i"}},
        {"name": "main", "kind": "loop", "play": {"pad": "a", "drums": "g*2"}},
        {"name": "outro", "kind": "outro", "play": {"pad": "o"}}]})");
}

SongDoc parsed(const Json& j) {
    auto r = parse_song(j, "test.song.json");
    INFO(std::string(r ? "" : r.error().message));
    REQUIRE(bool(r));
    return *r;
}

SongTimeline timeline_of(const SongDoc& song) {
    auto tl = expand_song(song);
    REQUIRE(bool(tl));
    return *tl;
}

// A source with stems of constant level (so the output says which stems play and how loud), on the map of `song`.
std::shared_ptr<MusicSource> fake_source(const SongDoc& song, const std::vector<std::pair<float, int>>& stems, const std::string& path = "music/test.song.json") {
    SongTimeline tl = timeline_of(song);
    auto probe = music_map_build(song, tl, 0);
    REQUIRE(bool(probe));
    const std::int64_t frames = std::int64_t(probe->musicEnd) + 66150;
    auto map = music_map_build(song, tl, frames);
    REQUIRE(bool(map));
    auto src = std::make_shared<MusicSource>();
    src->path = path;
    src->mode = "live";
    src->map = *map;
    src->layered = stems.size() > 1;
    int n = 0;
    for (auto [threshold, level] : stems) {
        MusicStem st;
        st.name = "s" + std::to_string(n++);
        st.threshold = threshold;
        st.scale = 1.0f / 32768.0f;
        st.pcm.assign(std::size_t(frames) * 2, std::int16_t(level));
        src->stems.push_back(std::move(st));
    }
    return src;
}

struct Rendered {
    std::vector<float> out;                 // interleaved stereo
    std::vector<MusicEvent> events;
    float at(std::size_t frame) const { return out[2 * frame]; }
};

// Mixes `frames` frames in blocks of `block`, calling `act(frameCountSoFar)` before each block when it is given.
Rendered mix_blocks(MusicTransport& tr, std::size_t frames, std::size_t block) {
    Rendered r;
    r.out.assign(frames * 2, 0.0f);
    for (std::size_t done = 0; done < frames;) {
        const std::size_t n = std::min(block, frames - done);
        tr.mix(r.out.data() + 2 * done, int(n));
        done += n;
    }
    tr.take_events(r.events);
    return r;
}

constexpr std::size_t kBeat = 22050, kBar = 88200;

}  // namespace

TEST_CASE("music: quantization lands on the beat, the bar line or the end of the section") {
    SongDoc song = parsed(demo_json());
    auto src = fake_source(song, {{0.0f, 1000}});
    const MusicMap& m = src->map;
    CHECK(m.barFrames == double(kBar));
    CHECK(m.beatFrames == double(kBeat));
    CHECK(m.sections.size() == 3);
    CHECK(m.section_index("main") == 1);
    CHECK(m.section_index("nope") == -1);
    // None: where the playhead is.
    CHECK(music_boundary(m, 30000, MusicQuantize::None, 0) == 30000);
    // Beat / bar: the next line; a request exactly on a line lands on it.
    CHECK(music_boundary(m, 30000, MusicQuantize::Beat, 0) == double(2 * kBeat));
    CHECK(music_boundary(m, double(2 * kBeat), MusicQuantize::Beat, 0) == double(2 * kBeat));
    CHECK(music_boundary(m, 30000, MusicQuantize::Bar, 0) == double(kBar));
    CHECK(music_boundary(m, double(kBar), MusicQuantize::Bar, 0) == double(kBar));
    CHECK(music_boundary(m, double(kBar + 1), MusicQuantize::Bar, 0) == double(2 * kBar));
    // Section: the end of the pass the playhead is in (intro: 1 bar; main: bars 2-3).
    CHECK(music_boundary(m, 30000, MusicQuantize::Section, 0) == double(kBar));
    CHECK(music_boundary(m, double(kBar + 5000), MusicQuantize::Section, 0) == double(3 * kBar));
    // Never past the limit (where the playhead wraps).
    CHECK(music_boundary(m, double(kBar + 5000), MusicQuantize::Section, double(2 * kBar)) == double(2 * kBar));
}

TEST_CASE("music: a layer's gain is a smoothstep below its threshold") {
    CHECK(music_layer_gain(0.0f, 0.0f, 0.25f) == 1.0f);   // the base layer always plays
    CHECK(music_layer_gain(0.0f, 0.5f, 0.25f) == 0.0f);
    CHECK(music_layer_gain(0.25f, 0.5f, 0.25f) == 0.0f);  // threshold - range
    CHECK(music_layer_gain(0.375f, 0.5f, 0.25f) == doctest::Approx(0.5f));
    CHECK(music_layer_gain(0.5f, 0.5f, 0.25f) == 1.0f);
    CHECK(music_layer_gain(1.0f, 0.5f, 0.25f) == 1.0f);
    CHECK(music_layer_gain(0.49f, 0.5f, 0.0f) == 0.0f);   // range 0: a switch
    CHECK(music_layer_gain(0.5f, 0.5f, 0.0f) == 1.0f);
}

TEST_CASE("music: auto mode picks stems for low tiers, phones that are not high-end and the web, only when stems exist") {
    MusicDeviceProfile desktop, lowDesktop, phone, phoneHigh, web;
    lowDesktop.tier = "low";
    phone.formFactor = "phone";
    phone.tier = "medium";
    phoneHigh.formFactor = "phone";
    phoneHigh.tier = "high";
    web.web = true;
    CHECK(music_resolve_mode(MusicMode::Auto, desktop, true) == MusicMode::Live);
    CHECK(music_resolve_mode(MusicMode::Auto, lowDesktop, true) == MusicMode::Stems);
    CHECK(music_resolve_mode(MusicMode::Auto, phone, true) == MusicMode::Stems);
    CHECK(music_resolve_mode(MusicMode::Auto, phoneHigh, true) == MusicMode::Live);
    CHECK(music_resolve_mode(MusicMode::Auto, web, true) == MusicMode::Stems);
    // No stem files: live whatever was asked.
    CHECK(music_resolve_mode(MusicMode::Auto, phone, false) == MusicMode::Live);
    CHECK(music_resolve_mode(MusicMode::Stems, desktop, false) == MusicMode::Live);
    // Taken as written otherwise.
    CHECK(music_resolve_mode(MusicMode::Live, phone, true) == MusicMode::Live);
    CHECK(music_resolve_mode(MusicMode::Stems, desktop, true) == MusicMode::Stems);
    std::string why;
    music_resolve_mode(MusicMode::Auto, phone, true, &why);
    CHECK_FALSE(why.empty());
}

TEST_CASE("music: layers fade with the intensity, each over the layer fade") {
    SongDoc song = parsed(demo_json());
    // Base layer 4000, a second one at 0.5 (8000) and a third at 1.0 (16000).
    auto src = fake_source(song, {{0.0f, 4000}, {0.5f, 8000}, {1.0f, 16000}});
    MusicTransport tr;
    tr.set_layer_fade(0.5f, 0.25f);
    std::string err;
    REQUIRE(tr.start(src, -1, 0.0f, &err));
    Rendered a = mix_blocks(tr, 22050, 512);
    CHECK(a.at(20000) == doctest::Approx(4000.0f / 32768.0f).epsilon(0.001));   // only the base layer
    tr.set_intensity(1.0f, MusicQuantize::None);
    Rendered b = mix_blocks(tr, 44100, 512);
    // The fade is 0.5 s = 22050 frames: halfway the layers are between, at the end all three play.
    const float full = (4000.0f + 8000.0f + 16000.0f) / 32768.0f;
    CHECK(b.at(100) < full * 0.5f);
    CHECK(b.at(100) >= 4000.0f / 32768.0f - 1e-4f);
    CHECK(b.at(30000) == doctest::Approx(full).epsilon(0.001));
    // Monotonic going up, no step bigger than one frame of the fade.
    float prev = 0.0f;
    for (std::size_t i = 0; i < 22050; ++i) {
        CHECK(b.at(i) >= prev - 1e-6f);
        prev = b.at(i);
    }
    // Back down: the layers leave again.
    tr.set_intensity(0.0f, MusicQuantize::None);
    Rendered c = mix_blocks(tr, 44100, 512);
    CHECK(c.at(40000) == doctest::Approx(4000.0f / 32768.0f).epsilon(0.001));
    // A layer whose threshold is 0.5 is half in at intensity 0.375.
    MusicTransport mid;
    mid.set_layer_fade(0.0f, 0.25f);
    REQUIRE(mid.start(src, -1, 0.375f, &err));
    Rendered d = mix_blocks(mid, 2000, 512);
    CHECK(d.at(1500) == doctest::Approx((4000.0f + 4000.0f) / 32768.0f).epsilon(0.001));
}

TEST_CASE("music: beat, bar and section events come in order, on the frames the song says") {
    SongDoc song = parsed(demo_json());
    auto src = fake_source(song, {{0.0f, 1000}});
    MusicTransport tr;
    std::string err;
    REQUIRE(tr.start(src, -1, 0.0f, &err));
    Rendered r = mix_blocks(tr, 5 * kBar + 10, 777);
    std::vector<MusicEvent> beats, bars, sections;
    for (const MusicEvent& e : r.events) {
        if (e.kind == MusicEventKind::Beat) beats.push_back(e);
        if (e.kind == MusicEventKind::Bar) bars.push_back(e);
        if (e.kind == MusicEventKind::Section) sections.push_back(e);
    }
    // The first beat is the first frame; four per bar. The loop (bars 2-3) repeats after the first pass, so bar numbers go 1 2 3 2 3 ...
    REQUIRE(beats.size() >= 20);
    for (std::size_t i = 0; i < 20; ++i) {
        CHECK(beats[i].frame == i * kBeat);
        CHECK(beats[i].b == int(i % 4) + 1);
        CHECK(beats[i].d == int(i) + 1);
    }
    CHECK(beats[0].a == 1);
    CHECK(beats[4].a == 2);
    CHECK(beats[8].a == 3);
    CHECK(beats[12].a == 2);  // the loop took the playhead back to bar 2
    REQUIRE(bars.size() >= 5);
    CHECK(bars[0].frame == 0);
    CHECK(bars[1].frame == kBar);
    CHECK(bars[0].a == 1);
    CHECK(bars[1].a == 2);
    REQUIRE(sections.size() >= 3);
    CHECK(sections[0].a == 0);
    CHECK(sections[0].frame == 0);
    CHECK(sections[1].a == 1);
    CHECK(sections[1].frame == kBar);
    // The loop: one Loop event, on the frame of the wrap.
    std::vector<std::uint64_t> loops;
    for (const MusicEvent& e : r.events)
        if (e.kind == MusicEventKind::Loop) loops.push_back(e.frame);
    REQUIRE(loops.size() >= 2);
    CHECK(loops[0] == 3 * kBar);   // the loop is bars 2-3
    CHECK(loops[1] == 5 * kBar);
}

TEST_CASE("music: the events and the output are the same whatever the block size") {
    SongDoc song = parsed(demo_json());
    auto src = fake_source(song, {{0.0f, 1000}, {0.5f, 2000}});
    auto run = [&](std::size_t block) {
        MusicTransport tr;
        std::string err;
        tr.set_layer_fade(0.2f, 0.25f);
        REQUIRE(tr.start(src, -1, 0.0f, &err));
        Rendered r;
        r.out.assign(4 * kBar * 2, 0.0f);
        for (std::size_t done = 0; done < 4 * kBar;) {
            // Gameplay-style calls between blocks, at the same frames in every run.
            if (done == 3 * kBeat + 1000 - (3 * kBeat + 1000) % block) {}  // (calls below are keyed to the frame count, not the block)
            const std::size_t n = std::min(block, 4 * kBar - done);
            tr.mix(r.out.data() + 2 * done, int(n));
            done += n;
        }
        tr.take_events(r.events);
        return r;
    };
    Rendered a = run(512), b = run(100), c = run(4096), d = run(1);
    REQUIRE(a.events.size() == b.events.size());
    REQUIRE(a.events.size() == c.events.size());
    REQUIRE(a.events.size() == d.events.size());
    for (std::size_t i = 0; i < a.events.size(); ++i) {
        CHECK(a.events[i].frame == b.events[i].frame);
        CHECK(a.events[i].frame == c.events[i].frame);
        CHECK(a.events[i].kind == d.events[i].kind);
        CHECK(a.events[i].a == b.events[i].a);
    }
    CHECK(a.out == b.out);
    CHECK(a.out == c.out);
    CHECK(a.out == d.out);
}

TEST_CASE("music: a section change waits for the bar and lands on its first frame") {
    SongDoc song = parsed(demo_json());
    auto src = fake_source(song, {{0.0f, 1000}});
    for (std::size_t block : {std::size_t(512), std::size_t(97)}) {
        MusicTransport tr;
        std::string err;
        REQUIRE(tr.start(src, -1, 0.0f, &err));
        mix_blocks(tr, 30000, block);   // somewhere in beat 2 of bar 1
        std::vector<MusicEvent> ev;
        tr.take_events(ev);
        REQUIRE(tr.go_to_section(2, MusicQuantize::Bar, 0.0f, &err));   // outro
        CHECK(tr.pending_count() == 1);
        Rendered r = mix_blocks(tr, 2 * kBar, block);
        CHECK(tr.pending_count() == 0);
        const MusicEvent* sec = nullptr;
        for (const MusicEvent& e : r.events)
            if (e.kind == MusicEventKind::Section && e.a == 2) sec = &e;
        REQUIRE(sec != nullptr);
        CHECK(sec->frame == kBar);   // the bar line after frame 30000
        // The unknown one is an error that lists the sections.
        CHECK_FALSE(tr.go_to_section(9, MusicQuantize::Bar, 0.0f, &err));
        CHECK_FALSE(err.empty());
    }
}

TEST_CASE("music: a stinger clip is scheduled on the boundary, a section stinger plays over the music, both can duck it") {
    SongDoc song = parsed(demo_json());
    auto src = fake_source(song, {{0.0f, 4000}});
    MusicTransport tr;
    std::string err;
    REQUIRE(tr.start(src, -1, 0.0f, &err));
    Rendered pre = mix_blocks(tr, 30000, 512);
    std::vector<MusicEvent> ev;
    tr.take_events(ev);
    // A clip: the mixer gets the delay to the next beat (30000 -> 44100) and starts its voice there.
    CHECK(tr.schedule_clip_stinger(MusicQuantize::Beat) == std::int64_t(2 * kBeat) - 30000);
    CHECK(tr.schedule_clip_stinger(MusicQuantize::None) == 0);
    tr.duck(MusicQuantize::Beat, 0.5f, 0.0f, 0.1f, 0.0f);
    Rendered r = mix_blocks(tr, kBeat, 300);
    const float base = 4000.0f / 32768.0f;
    CHECK(r.at(100) == doctest::Approx(base).epsilon(0.001));            // before the boundary: untouched
    CHECK(r.at(14100 + 500) == doctest::Approx(base * 0.5f).epsilon(0.02));  // ducked while held
    CHECK(r.at(14100 + 6000) == doctest::Approx(base).epsilon(0.01));    // recovered
    int stingers = 0;
    for (const MusicEvent& e : r.events)
        if (e.kind == MusicEventKind::Stinger) {
            ++stingers;
        }
    CHECK(stingers == 2);
    // A section: the outro (stem level 4000) over the music from the bar line, mixed on top of it.
    REQUIRE(tr.play_section_stinger(2, MusicQuantize::Bar, 1.0f, 0.0f, &err));
    CHECK_FALSE(tr.play_section_stinger(7, MusicQuantize::Bar, 1.0f, 0.0f, &err));
    Rendered s = mix_blocks(tr, 2 * kBar, 512);
    // Before the bar line (frame 88200 of the song) one head; after it the stinger adds a second playing the outro at once.
    const std::size_t at = kBar - 30000 - kBeat;   // output frames since the end of `r` until the bar line
    CHECK(s.at(at - 100) == doctest::Approx(base).epsilon(0.01));
    CHECK(s.at(at + 100) == doctest::Approx(2.0f * base).epsilon(0.02));
}

TEST_CASE("music: a crossfade to another song is equal-power over the fade and starts at the boundary") {
    SongDoc song = parsed(demo_json());
    auto a = fake_source(song, {{0.0f, 8000}}, "music/a.song.json");
    auto b = fake_source(song, {{0.0f, 8000}}, "music/b.song.json");
    MusicTransport tr;
    std::string err;
    REQUIRE(tr.start(a, -1, 0.0f, &err));
    mix_blocks(tr, 10000, 512);
    std::vector<MusicEvent> ev;
    tr.take_events(ev);
    const float level = 8000.0f / 32768.0f;
    REQUIRE(tr.crossfade_to(b, -1, MusicQuantize::Bar, 1.0f, &err));
    Rendered r = mix_blocks(tr, kBar + 44100 + 2000, 512);
    // Until the bar line only the old song: level. During the fade the sum of two constant stems of the same level is
    // sqrt(1-x)+sqrt(x) times level (equal power on correlated material: it dips less than 3 dB, it never goes silent).
    CHECK(r.at(kBar - 10000 - 100) == doctest::Approx(level).epsilon(0.001));
    const std::size_t mid = kBar - 10000 + 22050;
    const float expected = level * (std::sqrt(0.5f) + std::sqrt(0.5f));
    CHECK(r.at(mid) == doctest::Approx(expected).epsilon(0.02));
    // After it only the new song.
    CHECK(r.at(kBar - 10000 + 44100 + 1000) == doctest::Approx(level).epsilon(0.001));
    CHECK(tr.source() == b.get());
    int crossfades = 0;
    std::uint64_t frame = 0;
    for (const MusicEvent& e : r.events)
        if (e.kind == MusicEventKind::Crossfade) {
            ++crossfades;
            frame = e.frame;
            CHECK(e.src == b.get());
        }
    CHECK(crossfades == 1);
    CHECK(frame == kBar);   // frames count from the start of the player
    CHECK(tr.head_count() == 1);
}

TEST_CASE("music: a song without a loop plays through and ends, and stop fades out") {
    Json j = demo_json();
    j["sections"][1]["kind"] = "section";
    SongDoc song = parsed(j);
    auto src = fake_source(song, {{0.0f, 4000}});
    MusicTransport tr;
    std::string err;
    tr.set_loop(false);
    REQUIRE(tr.start(src, -1, 0.0f, &err));
    Rendered r = mix_blocks(tr, 6 * kBar, 4096);
    CHECK(tr.ended());
    CHECK_FALSE(tr.playing());
    int ended = 0;
    for (const MusicEvent& e : r.events)
        if (e.kind == MusicEventKind::Ended) ++ended;
    CHECK(ended == 1);
    CHECK(r.at(6 * kBar - 10) == 0.0f);

    MusicTransport st;
    REQUIRE(st.start(src, -1, 0.0f, &err));
    mix_blocks(st, 1000, 256);
    st.stop(MusicQuantize::None, 0.1f);
    Rendered f = mix_blocks(st, 8000, 256);
    CHECK(f.at(10) > f.at(2000));        // going down
    CHECK(f.at(6000) == 0.0f);           // 0.1 s = 4410 frames
    CHECK(st.ended());
}


// ---- the player inside the mixer ------------------------------------------------------------------------------------------------------

namespace {

// A project folder with the demo song (and a second one, 90 BPM) and a World with one MusicPlayer entity.
struct PlayerFx : audio_test::Fixture {
    World world;
    Entity e;
    PlayerFx() {
        REQUIRE(fs::write_text("music/test.song.json", demo_json().dump()).ok());
        Json other = demo_json();
        other["tempo"] = 90;
        REQUIRE(fs::write_text("music/other.song.json", other.dump()).ok());
        e = world.create("music", "music");
        MusicPlayer& mp = world.add<MusicPlayer>(e);
        mp.song = "music/test.song.json";
        mp.volume = 1.0f;
        mp.layerFade = 0.1f;
    }
    MusicPlayer& mp() { return *world.get<MusicPlayer>(e); }
    // `seconds` of game time in 1/60 s frames, the way the engine does it.
    void step(double seconds) {
        const int frames = int(std::lround(seconds * 60.0));
        for (int i = 0; i < frames; ++i) {
            audio.update(world, 1.0f / 60.0f);
            audio.advance_null_device(1.0 / 60.0);
        }
    }
    std::vector<GameEvent> events(const std::string& name) {
        std::vector<GameEvent> out;
        for (const GameEvent& g : world.events().game)
            if (g.name == name) out.push_back(g);
        return out;
    }
};

}  // namespace

TEST_CASE("music player: the component starts the song, fills its runtime fields and sends the events") {
    PlayerFx fx;
    fx.audio.update(fx.world, 1.0f / 60.0f);
    CHECK(fx.mp().playing);
    CHECK(fx.mp().ready);
    CHECK(fx.mp().activeMode == "live");
    CHECK(fx.mp().section == "intro");
    CHECK(fx.mp().tempo == doctest::Approx(120.0f));
    CHECK(fx.events("music.ready").size() == 1);
    fx.step(2.2);
    CHECK(fx.mp().bar == 2);       // 2.2 s at 120 BPM: bar 2 started at 2 s
    CHECK(fx.mp().section == "main");
    auto beats = fx.events("music.beat");
    REQUIRE(beats.size() >= 4);
    CHECK(beats[0].data["bar"] == 1);
    CHECK(beats[0].data["beat"] == 1);
    CHECK(beats[0].data["section"] == "intro");
    CHECK(beats[0].data["id"] == "music");
    CHECK(beats[0].data["song"] == "music/test.song.json");
    CHECK(beats[1].data["frame"] == kBeat);
    CHECK(beats[1].data["time"].get<double>() == doctest::Approx(0.5));
    CHECK(fx.events("music.bar").size() >= 2);
    auto sections = fx.events("music.section");
    REQUIRE(sections.size() >= 2);
    CHECK(sections[1].data["section"] == "main");
    // stop: playing goes false and the music fades out.
    fx.mp().playing = false;
    fx.world.events().game.clear();
    fx.step(0.5);
    CHECK_FALSE(fx.mp().playing);
    CHECK(fx.mp().bar == 0);
    CHECK(fx.events("music.ended").size() == 1);
    CHECK(fx.audio.music_status(fx.world, fx.e).playing == false);
}

TEST_CASE("music player: at full intensity the mixer output is the render of the song") {
    PlayerFx fx;
    fx.mp().intensity = 1.0f;
    fx.mp().layerFade = 0.0f;
    fx.audio.start_recording();
    fx.step(2.5);
    Recording rec = fx.finish();
    auto song = load_song("music/test.song.json");
    REQUIRE(bool(song));
    auto tl = expand_song(*song);
    REQUIRE(bool(tl));
    SongAssetOptions options;
    options.loop = true;
    auto render = render_song_asset(*song, *tl, options);
    REQUIRE(bool(render));
    const std::vector<float>& mix = render->mix.clip.samples;
    REQUIRE(rec.frames() >= 100000);
    double worst = 0.0, peak = 0.0;
    for (std::size_t i = 0; i < 100000; ++i) {
        worst = std::max(worst, double(std::fabs(rec.l[i] - mix[2 * i])));
        worst = std::max(worst, double(std::fabs(rec.r[i] - mix[2 * i + 1])));
        peak = std::max(peak, double(std::fabs(mix[2 * i])));
    }
    CHECK(peak > 0.01);        // there is something to compare
    CHECK(worst < 0.002);      // 16-bit stems and a 16-bit recording
}

TEST_CASE("music player: intensity brings the layers in, a quantized section jump lands on the bar") {
    PlayerFx fx;
    fx.mp().layerFade = 0.05f;
    fx.audio.start_recording();
    fx.step(1.0);
    fx.mp().intensity = 1.0f;
    fx.step(1.0);
    Recording rec = fx.finish();
    // Only the base layer (the rhythm layer is the song's first: drums), then everyone: the tail of the second is louder.
    const float early = rec.peak(0, 20000), late = rec.peak(60000, 88000);
    CHECK(late > early * 1.1f);

    // goToSection: asked mid-bar, lands on the next bar line and the player reports it.
    PlayerFx go;
    go.step(0.7);
    REQUIRE(go.audio.music_go_to_section(go.world, go.e, "outro", MusicQuantize::Bar, 0.0f).ok());
    go.world.events().game.clear();
    go.step(0.2);
    CHECK(go.mp().section == "intro");           // the bar line is at 2 s
    go.step(1.3);
    CHECK(go.mp().section == "outro");
    auto sections = go.events("music.section");
    REQUIRE_FALSE(sections.empty());
    CHECK(sections.back().data["section"] == "outro");
    CHECK(sections.back().data["frame"] == kBar);
    // Unknown section: the error says which exist.
    auto bad = go.audio.music_go_to_section(go.world, go.e, "ouro", MusicQuantize::Bar);
    REQUIRE_FALSE(bad.ok());
    CHECK(bad.error().message.find("outro") != std::string::npos);
}

TEST_CASE("music player: a clip stinger starts on the bar line and ducks the music") {
    auto record = [](bool stinger) {
        PlayerFx fx;
        fx.mp().intensity = 1.0f;
        fx.audio.start_recording();
        fx.step(0.7);
        if (stinger) {
            MusicStingerSpec spec;
            spec.clip = "sounds/sine.wav";
            spec.quantize = MusicQuantize::Bar;
            REQUIRE(fx.audio.music_play_stinger(fx.world, fx.e, spec).ok());
        }
        fx.step(2.0);
        return fx.finish();
    };
    Recording plain = record(false), with = record(true);
    REQUIRE(plain.frames() == with.frames());
    std::size_t first = 0;
    for (std::size_t i = 0; i < plain.frames(); ++i)
        if (std::fabs(plain.l[i] - with.l[i]) > 1e-4f) { first = i; break; }
    // The bar line is at 88200 frames; the voice starts there (the first sample of a sine is 0).
    CHECK(first >= kBar);
    CHECK(first <= kBar + 3);
    // Same in a second run: the music is deterministic.
    Recording again = record(true);
    CHECK(again.l == with.l);
    CHECK(again.r == with.r);

    // A stinger needs music.
    PlayerFx idle;
    idle.mp().playOnStart = false;
    idle.audio.update(idle.world, 1.0f / 60.0f);
    MusicStingerSpec spec;
    spec.clip = "sounds/sine.wav";
    auto r = idle.audio.music_play_stinger(idle.world, idle.e, spec);
    CHECK_FALSE(r.ok());
    spec.section = "intro";
    CHECK_FALSE(idle.audio.music_play_stinger(idle.world, idle.e, spec).ok());   // both given
}

TEST_CASE("music player: a clip stinger has a higher priority than the default, so a full mixer replaces a sound for it") {
    PlayerFx fx;
    fx.step(0.7);
    PlayParams loop;
    loop.loop = true;
    for (int i = 0; i < 64; ++i) REQUIRE(fx.audio.play("sounds/sine.wav", loop) != 0);  // 64 effects as loud as the stinger
    CHECK(fx.audio.play("sounds/sine.wav", loop) == 0);  // the 65th is refused: same priority, not louder
    MusicStingerSpec spec;
    spec.clip = "sounds/sine.wav";
    spec.quantize = MusicQuantize::None;
    REQUIRE(fx.audio.music_play_stinger(fx.world, fx.e, spec).ok());
    const Json st = fx.audio.stats();
    CHECK(st.at("voicesStolen").get<int>() == 1);
    CHECK(st.at("voicesRejected").get<int>() == 1);  // the 65th effect only
}

TEST_CASE("music player: crossfading to another song keeps playing and reports the new one") {
    PlayerFx fx;
    fx.step(0.7);
    REQUIRE(fx.audio.music_crossfade_to(fx.world, fx.e, "music/other.song.json", "", MusicQuantize::Bar, 1.0f).ok());
    fx.world.events().game.clear();
    fx.step(6.0);
    CHECK(fx.mp().song == "music/other.song.json");
    CHECK(fx.mp().tempo == doctest::Approx(90.0f));
    CHECK(fx.mp().playing);
    CHECK(fx.events("music.crossfade").size() == 1);
    CHECK(fx.audio.music_status(fx.world, fx.e).song == "music/other.song.json");
    CHECK(fx.audio.music_status(fx.world, fx.e).heads == 1);
}

TEST_CASE("music player: a player of the next scene with the same song takes over without a restart") {
    PlayerFx fx;
    fx.step(3.0);   // bar 2 of the song
    const int bar = fx.mp().bar;
    REQUIRE(bar >= 2);
    fx.world.destroy(fx.e);
    fx.world.flush();
    Entity again = fx.world.create("music2", "music2");
    MusicPlayer& mp = fx.world.add<MusicPlayer>(again);
    mp.song = "music/test.song.json";
    mp.volume = 1.0f;
    fx.audio.update(fx.world, 1.0f / 60.0f);
    CHECK(fx.world.get<MusicPlayer>(again)->playing);
    CHECK(fx.world.get<MusicPlayer>(again)->bar == bar);
    CHECK(fx.audio.music_players().size() == 1);

    // Without a player of the same song the old one fades out and goes.
    fx.world.destroy(again);
    fx.world.flush();
    fx.audio.update(fx.world, 1.0f / 60.0f);
    CHECK(fx.audio.music_players().size() == 1);
    CHECK(fx.audio.music_players()[0]["orphan"] == true);
    fx.step(1.0);
    CHECK(fx.audio.music_players().empty());
}

TEST_CASE("music player: an unknown song or section is an error that says what to do, and nothing plays") {
    PlayerFx fx;
    fx.mp().song = "music/missing.song.json";
    fx.audio.update(fx.world, 1.0f / 60.0f);
    CHECK_FALSE(fx.mp().ready);
    MusicStatus st = fx.audio.music_status(fx.world, fx.e);
    CHECK(st.exists);
    CHECK_FALSE(st.error.empty());
    // An entity with no component.
    Entity plain = fx.world.create("plain", "plain");
    auto r = fx.audio.music_play(fx.world, plain, "music/test.song.json");
    CHECK_FALSE(r.ok());
    CHECK(r.error().message.find("MusicPlayer") != std::string::npos);
}

// ---- hot reload, the device a test pretends to run on, the style loudness ---------------------------------------------------------------

namespace {
// RMS of the loudest stem of a source, in the units of the song (the stem scale undone).
double source_rms(const MusicSource& src) {
    double best = 0.0;
    for (const MusicStem& st : src.stems) {
        double sum = 0.0;
        for (std::int16_t v : st.pcm) sum += double(v) * st.scale * double(v) * st.scale;
        best = std::max(best, st.pcm.empty() ? 0.0 : std::sqrt(sum / double(st.pcm.size())));
    }
    return best;
}
}  // namespace

TEST_CASE("music player: a song edited on disk is fetched again and the player crossfades to it in the section that sounds") {
    PlayerFx fx;
    fx.step(2.5);  // in "main" (bar 2)
    REQUIRE(fx.mp().section == "main");
    CHECK(fx.mp().tempo == doctest::Approx(120.0f));
    CHECK(fx.events("music.ready").size() == 1);

    // The song, edited: another tempo, and the section "main" is now called "verse" (it no longer exists).
    Json edited = demo_json();
    edited["tempo"] = 90;
    edited["sections"][1]["name"] = "verse";
    REQUIRE(fs::write_text("music/test.song.json", edited.dump()).ok());
    fx.world.events().game.clear();
    fx.audio.reload_song("music/test.song.json");
    fx.step(6.0);
    CHECK(fx.mp().playing);
    CHECK(fx.mp().tempo == doctest::Approx(90.0f));   // the running game hears the new version
    CHECK(fx.events("music.ready").size() == 1);      // announced again for the new render
    CHECK(fx.events("music.crossfade").size() == 1);
    CHECK(fx.audio.music_status(fx.world, fx.e).heads == 1);
    CHECK(fx.audio.music_status(fx.world, fx.e).error.empty());
    const auto names = fx.audio.music_status(fx.world, fx.e).sections;
    CHECK(std::find(names.begin(), names.end(), "verse") != names.end());

    // Edited again while it plays, now without any change of structure: the same section carries on.
    fx.step(0.1);
    edited["tempo"] = 100;
    REQUIRE(fs::write_text("music/test.song.json", edited.dump()).ok());
    fx.audio.reload_song("./music/test.song.json");   // any spelling of the path
    fx.step(8.0);
    CHECK(fx.mp().tempo == doctest::Approx(100.0f));
}

TEST_CASE("music player: a song that is not playing is read again from disk on the next play after a reload") {
    PlayerFx fx;
    fx.step(0.5);
    fx.mp().playing = false;
    fx.step(1.0);
    CHECK_FALSE(fx.mp().playing);
    Json edited = demo_json();
    edited["tempo"] = 90;
    REQUIRE(fs::write_text("music/test.song.json", edited.dump()).ok());
    fx.audio.reload_song("music/test.song.json");
    REQUIRE(fx.audio.music_play(fx.world, fx.e).ok());
    fx.step(0.5);
    CHECK(fx.mp().playing);
    CHECK(fx.mp().tempo == doctest::Approx(90.0f));
}

TEST_CASE("music player: a device change makes an `auto` player pick live or stems again; live and stems players stay") {
    PlayerFx fx;
    // Render the stems of the demo song to files, the way music.render leaves them, and describe them in assets.json.
    SongDoc song = parsed(demo_json());
    auto live = music_render_source(song, timeline_of(song), "music/test.song.json");
    REQUIRE(bool(live));
    Json stems = Json::array();
    for (std::size_t i = 0; i < (*live)->stems.size(); ++i) {
        const MusicStem& st = (*live)->stems[i];
        std::vector<float> samples(st.pcm.size());
        for (std::size_t k = 0; k < samples.size(); ++k) samples[k] = float(st.pcm[k]) * st.scale;
        const std::string file = "assets/music/test_" + st.name + ".wav";
        audio_test::write_file(fx.dir / file, audio_test::wav_bytes(samples, 2, kMusicRate));
        stems.push_back(Json::object({{"path", file}, {"name", st.name}, {"intensity", st.threshold}}));
    }
    REQUIRE(stems.size() >= 2);
    fx.write_assets(Json::object({{"format", "factoria.assets/1"},
                                  {"assets", Json::object({{"assets/music/test.wav", Json::object({{"import", Json::object({{"music", Json::object({{"role", "mix"}, {"song", "music/test.song.json"}, {"stems", stems}})}})}})}})}})
                        .dump());
    fx.step(0.5);
    REQUIRE(fx.mp().activeMode == "live");   // a desktop: auto is live
    fx.world.events().game.clear();

    MusicDeviceProfile phone;
    phone.formFactor = "phone";
    phone.tier = "medium";
    fx.audio.set_music_device(phone);
    fx.step(3.0);
    CHECK(fx.mp().activeMode == "stems");
    CHECK(fx.mp().playing);
    CHECK(fx.events("music.crossfade").size() == 1);

    // A player that asked for live is not moved by the device; a second change to the same profile does nothing.
    fx.mp().mode = MusicMode::Live;
    fx.audio.set_music_device(phone);
    fx.world.events().game.clear();
    fx.step(1.0);
    CHECK(fx.events("music.crossfade").empty());
    MusicDeviceProfile desktop;
    fx.mp().mode = MusicMode::Auto;
    fx.audio.set_music_device(desktop);
    fx.step(3.0);
    CHECK(fx.mp().activeMode == "live");
}

TEST_CASE("music: a live render brings a `loudness: style` master to the style guide's music level") {
    audio_test::Fixture fx;
    Json j = demo_json();
    j["mixer"]["master"] = Json::object({{"loudness", "style"}, {"limiter", false}});
    REQUIRE(fs::write_text("music/loud.song.json", j.dump()).ok());
    auto level = [&](double lufs, const char* master) {
        Json song = j;
        song["mixer"]["master"]["loudness"] = master;
        REQUIRE(fs::write_text("music/loud.song.json", song.dump()).ok());
        fx.write_assets(Json::object({{"format", "factoria.assets/1"},
                                      {"style", Json::object({{"audio", Json::object({{"loudnessLufs", Json::object({{"music", lufs}})}})}})}})
                            .dump());
        std::string note;
        auto src = music_load_source("music/loud.song.json", MusicMode::Live, MusicStemPlan{}, &note);
        REQUIRE(bool(src));
        return source_rms(**src);
    };
    const double quiet = level(-30.0, "style");
    const double loud = level(-9.0, "style");   // (the manifest is re-read when its size changes: -9.0 is shorter than -30.0)
    CHECK(loud / quiet == doctest::Approx(std::pow(10.0, 21.0 / 20.0)).epsilon(0.1));   // 21 LU apart
    // A master that is not on "style" ignores the guide.
    CHECK(level(-30.0, "off") == doctest::Approx(level(-9.0, "off")));
}

// ---- the music cache and the player with a device thread ------------------------------------------------------------------------------

TEST_CASE("music cache: past its budget it forgets the songs played longest ago that nothing plays") {
    PlayerFx fx;
    fx.mp().quantize = MusicQuantize::None;  // quick crossfades between the songs
    fx.mp().crossfadeBars = 0.25f;
    for (const char* n : {"a", "b", "c", "d"})
        REQUIRE(fs::write_text(std::string("music/") + n + ".song.json", demo_json().dump()).ok());
    auto play = [&](const char* n) {
        fx.mp().song = std::string("music/") + n + ".song.json";
        fx.step(1.0);  // the crossfade ends and the song before is let go
        REQUIRE(fx.mp().playing);
        REQUIRE(fx.mp().ready);
    };
    auto cached = [&] {
        std::vector<std::string> out;
        for (const auto& [key, bytes] : AudioTestAccess::music_cache(fx.audio)) out.push_back(key.substr(0, key.find('|')));
        return out;
    };
    play("a");
    play("b");
    play("c");
    play("a");  // played again: now newer than b
    play("c");
    const auto sizes = AudioTestAccess::music_cache(fx.audio);
    REQUIRE(sizes.size() == 3);
    const std::size_t song = sizes[0].second;  // the four songs are the same piece: the same size
    REQUIRE(song > 0);
    for (const auto& [key, bytes] : sizes) REQUIRE(bytes == song);

    // Room for three: loading d lets go of b, the least recently played; a, loaded first, stays.
    AudioTestAccess::set_music_cache_budget(fx.audio, 4 * song - 1);
    play("d");
    CHECK(cached() == std::vector<std::string>{"music/a.song.json", "music/c.song.json", "music/d.song.json"});
    // Room for none: a song still sounding (d, fading out while b loads) stays whatever the budget; the others go.
    AudioTestAccess::set_music_cache_budget(fx.audio, 1);
    play("b");
    CHECK(cached() == std::vector<std::string>{"music/b.song.json", "music/d.song.json"});
}

namespace {
float render_device(Audio& audio, int blocks) {
    thread_local std::vector<float> buf(512 * 2);
    float peak = 0.0f;
    for (int i = 0; i < blocks; ++i) {
        AudioTestAccess::render(audio, buf.data(), 512, 2);
        for (float v : buf) peak = std::max(peak, std::fabs(v));
    }
    return peak;
}
}  // namespace

TEST_CASE("music player: with a device thread the song loads on a job and the transport's commands mix without allocating") {
    audio_test::JobPool pool(jobs::Settings::threads(2));
    {
        PlayerFx fx;
        fx.mp().quantize = MusicQuantize::Beat;
        fx.mp().crossfadeBars = 0.25f;
        fx.mp().intensity = 0.4f;  // the rhythm layer (the harmony one comes in at 0.5)
        AudioTestAccess::use_manual_device(fx.audio, 48000);
        (void)render_device(fx.audio, 0);  // makes this thread's output buffer
        std::size_t allocs = 0;
        auto frame = [&](int blocks) {
            fx.audio.update(fx.world, 1.0f / 60.0f);  // the game's frame: commit, refill, take back
            audio_test::AllocCounter::Scope scope;
            const float peak = render_device(fx.audio, blocks);
            allocs += scope.count();
            return peak;
        };
        // The load runs on a worker while the game keeps going (a safety net far above the time it takes).
        const auto deadline = std::chrono::steady_clock::now() + std::chrono::seconds(60);
        while (!fx.mp().ready && std::chrono::steady_clock::now() < deadline) frame(2);
        REQUIRE(fx.mp().ready);
        float peak = 0.0f;
        for (int i = 0; i < 60; ++i) peak = std::max(peak, frame(2));
        CHECK(peak > 0.01f);
        CHECK(fx.mp().playing);

        // Intensity changes, a section jump, a stinger and a crossfade to another song: commands the callback applies.
        fx.audio.music_set_intensity(fx.world, fx.e, 1.0f);
        for (int i = 0; i < 30; ++i) frame(2);
        REQUIRE(fx.audio.music_go_to_section(fx.world, fx.e, "main", MusicQuantize::Beat).ok());
        MusicStingerSpec spec;
        spec.clip = "sounds/sine.wav";
        spec.quantize = MusicQuantize::Beat;
        spec.duck = 0.5f;
        REQUIRE(fx.audio.music_play_stinger(fx.world, fx.e, spec).ok());
        for (int i = 0; i < 60; ++i) frame(2);
        fx.mp().song = "music/other.song.json";
        const auto again = std::chrono::steady_clock::now() + std::chrono::seconds(60);
        while (fx.mp().tempo != 90.0f && std::chrono::steady_clock::now() < again) frame(2);
        CHECK(fx.mp().tempo == doctest::Approx(90.0f));
        for (int i = 0; i < 60; ++i) frame(2);
        CHECK(fx.mp().playing);
        CHECK_MESSAGE(allocs == 0, "the device callback allocated " << allocs << " times while the music played");
    }
}

// ---- a stalled device: the music settings that were dropped come back -------------------------------------------------------------

namespace {

// The game's frames while the device runs again: a count of frames, each one update and two blocks.
void run_frames(PlayerFx& fx, int frames) {
    for (int i = 0; i < frames; ++i) {
        fx.audio.update(fx.world, 1.0f / 60.0f);
        (void)render_device(fx.audio, 2);
        AudioTestAccess::pump(fx.audio);
    }
}

// Settings of the "ui" bus: they fill the mixer's ring (2048) and then overflow the staging queue (8192) of a device that
// takes nothing, so the oldest music settings are dropped.
void stall_junk(Audio& audio, int count) {
    for (int i = 0; i < count; ++i) audio.set_bus_volume("ui", 0.5f + 0.0001f * float(i % 100), 0.0f);
}

}  // namespace

TEST_CASE("music player: volume, loop, intensity and bus dropped while the device stalls are sent again") {
    PlayerFx fx;
    AudioTestAccess::use_manual_device(fx.audio, 48000);
    fx.mp().volume = 1.0f;
    run_frames(fx, 6);
    REQUIRE(fx.mp().playing);
    REQUIRE(fx.mp().ready);
    REQUIRE(fx.audio.music_status(fx.world, fx.e).volume == doctest::Approx(1.0f));
    REQUIRE(AudioTestAccess::music_loop(fx.audio, fx.world, fx.e));
    const int busBefore = AudioTestAccess::music_channel_bus(fx.audio, fx.world, fx.e);
    REQUIRE(busBefore >= 0);

    stall_junk(fx.audio, 2100);
    fx.mp().volume = 0.25f;
    fx.mp().loop = false;
    fx.mp().intensity = 0.8f;
    fx.audio.update(fx.world, 1.0f / 60.0f);  // the three settings are staged (Lossy), older than the junk that follows
    stall_junk(fx.audio, 9000);
    CHECK(fx.audio.stats()["settingsDropped"].get<int>() >= 3);
    // Nothing of it reached the mixer.
    CHECK(fx.audio.music_status(fx.world, fx.e).volume == doctest::Approx(1.0f));

    run_frames(fx, 40);
    CHECK(AudioTestAccess::staged_commands(fx.audio) == 0);
    const MusicStatus st = fx.audio.music_status(fx.world, fx.e);
    CHECK(st.volume == doctest::Approx(0.25f));
    CHECK(st.intensity == doctest::Approx(0.8f));
    CHECK_FALSE(AudioTestAccess::music_loop(fx.audio, fx.world, fx.e));
    CHECK(AudioTestAccess::music_channel_bus(fx.audio, fx.world, fx.e) == busBefore);
    CHECK(fx.mp().playing);
}

TEST_CASE("music player: a player that lost its entity gets its last settings again after a stall") {
    PlayerFx fx;
    AudioTestAccess::use_manual_device(fx.audio, 48000);
    run_frames(fx, 6);
    REQUIRE(fx.mp().playing);
    REQUIRE(fx.mp().ready);

    stall_junk(fx.audio, 2100);
    fx.mp().volume = 0.25f;
    fx.audio.update(fx.world, 1.0f / 60.0f);  // staged
    fx.world.destroy_immediate(fx.e);         // the player plays on as an orphan and fades out
    fx.audio.update(fx.world, 1.0f / 60.0f);
    stall_junk(fx.audio, 9000);
    CHECK(fx.audio.stats()["settingsDropped"].get<int>() >= 1);

    // A few frames only: the orphan is gone once its fade has run (about 0.5 s), long after the queue has emptied.
    run_frames(fx, 6);
    Json players = fx.audio.music_players();
    REQUIRE(players.size() == 1);
    CHECK(players[0]["orphan"].get<bool>());
    CHECK(players[0]["volume"].get<float>() == doctest::Approx(0.25f));
}
