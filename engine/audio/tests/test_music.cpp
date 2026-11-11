// Adaptive music at runtime (M56.4): the quantization math, the layers, the mode choice, the transport (section jumps, stingers,
// crossfades, events, determinism) on synthetic stems, and the player inside the mixer against the song's own render.
#include <doctest.h>

#include <algorithm>
#include <atomic>
#include <chrono>
#include <cmath>
#include <string>
#include <thread>
#include <vector>

#include "../src/audio_testing.h"
#include "../src/music_stream.h"
#include "alloc_counter.h"
#include "audio_test_helpers.h"
#include "fa/audio/audio.h"
#include "fa/audio/convert.h"
#include "fa/audio/music_player.h"
#include "fa/audio/music_transport.h"
#include "fa/audio/song.h"
#include "fa/audio/song_preview.h"
#include "fa/core/fs.h"
#include "fa/core/hash.h"
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

TEST_CASE("music: auto mode picks the stems whenever the song has stem files, live otherwise") {
    MusicDeviceProfile desktop, lowDesktop, phone, phoneHigh, web;
    lowDesktop.tier = "low";
    phone.formFactor = "phone";
    phone.tier = "medium";
    phoneHigh.formFactor = "phone";
    phoneHigh.tier = "high";
    web.web = true;
    CHECK(music_resolve_mode(MusicMode::Auto, desktop, true) == MusicMode::Stems);  // they play from their encoded ogg (M101.1b)
    CHECK(music_resolve_mode(MusicMode::Auto, lowDesktop, true) == MusicMode::Stems);
    CHECK(music_resolve_mode(MusicMode::Auto, phone, true) == MusicMode::Stems);
    CHECK(music_resolve_mode(MusicMode::Auto, phoneHigh, true) == MusicMode::Stems);
    CHECK(music_resolve_mode(MusicMode::Auto, web, true) == MusicMode::Stems);
    // No stem files: live whatever was asked.
    CHECK(music_resolve_mode(MusicMode::Auto, phone, false) == MusicMode::Live);
    CHECK(music_resolve_mode(MusicMode::Auto, desktop, false) == MusicMode::Live);
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

TEST_CASE("music: a section stinger that waits for its boundary asks the service for its own length, not the rest of the song") {
    SongDoc song = parsed(demo_json());
    auto src = fake_source(song, {{0.0f, 4000}});
    MusicTransport tr;
    std::string err;
    REQUIRE(tr.start(src, -1, 0.0f, &err));
    (void)mix_blocks(tr, 30000, 512);
    REQUIRE(tr.play_section_stinger(0, MusicQuantize::Bar, 1.0f, 0.0f, &err));   // the intro: a bar long, over the music
    MusicTransportState st;
    tr.capture(st);
    const MusicWant* overlay = nullptr;
    for (std::size_t i = 0; i < st.wantCount; ++i)
        if (st.wants[i].pos < 1.0) overlay = &st.wants[i];   // the main head is 30000 frames in; the stinger waits at the intro's start
    REQUIRE(overlay != nullptr);
    CHECK(overlay->end > double(kBar) - 1.0);   // 0 would be "nowhere known": the look-ahead would run past the stinger's end
    CHECK(overlay->end < 1.5 * double(kBar));
    CHECK_FALSE(overlay->wraps);
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

TEST_CASE("music player: an `auto` player plays the stems when the song has them; a live player stays live whatever the device") {
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
    REQUIRE(fx.mp().activeMode == "stems");   // auto with stem files: the stems, on a desktop too
    fx.world.events().game.clear();

    // A device change that does not change the choice moves nothing.
    MusicDeviceProfile phone;
    phone.formFactor = "phone";
    phone.tier = "medium";
    fx.audio.set_music_device(phone);
    fx.step(3.0);
    CHECK(fx.mp().activeMode == "stems");
    CHECK(fx.mp().playing);
    CHECK(fx.events("music.crossfade").empty());

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

// ---- Pending state (M101.2): what is audible versus what is queued, and what a call reports -----------------------------------------

namespace {

// A song whose only section is `loop`: it lacks the `intro` and `main` of the demo song.
void write_loop_only_song() {
    Json j = demo_json();
    j["sections"] = Json::array({Json::object({{"name", "loop"}, {"kind", "loop"}, {"play", Json::object({{"pad", "a"}, {"drums", "g*2"}})}})});
    REQUIRE(fs::write_text("music/loop.song.json", j.dump()).ok());
}

// A player of "the next scene" for `song`: the old entity is gone, the new one is the fixture's.
Entity next_scene_player(PlayerFx& fx, const std::string& song) {
    fx.world.destroy(fx.e);
    fx.world.flush();
    Entity again = fx.world.create("music2", "music2");
    MusicPlayer& mp = fx.world.add<MusicPlayer>(again);
    mp.song = song;
    mp.volume = 1.0f;
    mp.layerFade = 0.1f;
    fx.e = again;
    return again;
}

}  // namespace

TEST_CASE("music player: a queued crossfade shows as pendingSong / pendingSection / pendingAt until it starts, and the call says its frame") {
    PlayerFx fx;
    fx.step(0.7);
    auto before = fx.audio.music_status(fx.world, fx.e);
    CHECK(before.pendingSong.empty());
    CHECK_FALSE(before.pendingAt.has_value());
    CHECK(before.to_json()["pendingSong"].is_null());

    auto change = fx.audio.music_crossfade_to(fx.world, fx.e, "music/other.song.json", "", MusicQuantize::Bar, 1.0f);
    REQUIRE(change.ok());
    REQUIRE(change->frame.has_value());
    CHECK(*change->frame == kBar);                         // the bar line at 2 s
    CHECK(change->time == doctest::Approx(2.0));
    CHECK(change->quantize == MusicQuantize::Bar);
    CHECK(change->to_json()["quantize"] == "bar");
    fx.world.events().game.clear();
    fx.step(0.3);
    // The component already names the new song; what is audible, and what waits, is in the status.
    CHECK(fx.mp().song == "music/other.song.json");
    auto st = fx.audio.music_status(fx.world, fx.e);
    CHECK(st.song == "music/test.song.json");
    CHECK(st.pendingSong == "music/other.song.json");
    CHECK(st.pendingSection == "intro");                   // the beginning of the other song
    REQUIRE(st.pendingAt.has_value());
    CHECK(*st.pendingAt == *change->frame);
    CHECK(st.to_json()["pendingAt"] == kBar);
    CHECK(st.pending == 1);

    fx.step(1.5);
    auto crossed = fx.events("music.crossfade");
    REQUIRE(crossed.size() == 1);
    CHECK(crossed[0].data["frame"] == *change->frame);      // the frame the call promised
    auto after = fx.audio.music_status(fx.world, fx.e);
    CHECK(after.song == "music/other.song.json");
    CHECK(after.pendingSong.empty());
    CHECK_FALSE(after.pendingAt.has_value());
}

TEST_CASE("music player: goToSection and setIntensity say the frame they land on; the applied intensity follows at that frame") {
    PlayerFx fx;
    fx.step(0.7);
    auto go = fx.audio.music_go_to_section(fx.world, fx.e, "main", MusicQuantize::Bar, 0.0f);
    REQUIRE(go.ok());
    REQUIRE(go->frame.has_value());
    CHECK(*go->frame == kBar);
    fx.step(0.1);
    auto st = fx.audio.music_status(fx.world, fx.e);
    CHECK(st.song == "music/test.song.json");
    CHECK(st.pendingSong == "music/test.song.json");
    CHECK(st.pendingSection == "main");
    CHECK(st.pendingAt == kBar);
    fx.world.events().game.clear();

    // A quantized intensity: requested at once, applied at the frame.
    auto inten = fx.audio.music_set_intensity(fx.world, fx.e, 1.0f, MusicQuantize::Bar);
    REQUIRE(inten.frame.has_value());
    CHECK(*inten.frame == kBar);
    fx.step(0.1);
    st = fx.audio.music_status(fx.world, fx.e);
    CHECK(st.intensity == doctest::Approx(0.0f));
    CHECK(st.appliedIntensity == doctest::Approx(0.0f));
    CHECK(st.requestedIntensity == doctest::Approx(1.0f));
    fx.step(1.4);
    st = fx.audio.music_status(fx.world, fx.e);
    CHECK(st.section == "main");
    CHECK(st.intensity == doctest::Approx(1.0f));
    CHECK(st.appliedIntensity == doctest::Approx(1.0f));
    CHECK(st.requestedIntensity == doctest::Approx(1.0f));
    CHECK_FALSE(st.pendingAt.has_value());
    auto sections = fx.events("music.section");
    REQUIRE_FALSE(sections.empty());
    CHECK(sections.back().data["frame"] == *go->frame);

    // Not started yet: nothing to place.
    PlayerFx idle;
    idle.mp().playOnStart = false;
    idle.audio.update(idle.world, 1.0f / 60.0f);
    auto none = idle.audio.music_set_intensity(idle.world, idle.e, 0.5f, MusicQuantize::Beat);
    CHECK_FALSE(none.frame.has_value());
    CHECK(none.to_json()["frame"].is_null());
    CHECK(none.to_json()["time"].is_null());
}

TEST_CASE("music player: crossfadeTo without a section starts the other song at its beginning, not at the component's startSection") {
    PlayerFx fx;
    write_loop_only_song();
    fx.mp().startSection = "main";                         // a section of the first song only
    fx.step(0.7);
    CHECK(fx.mp().section == "main");
    REQUIRE(fx.audio.music_crossfade_to(fx.world, fx.e, "music/loop.song.json", "", MusicQuantize::Beat, 0.5f).ok());
    fx.step(1.5);
    CHECK(fx.mp().song == "music/loop.song.json");
    CHECK(fx.mp().playing);
    CHECK(fx.mp().section == "loop");
    auto st = fx.audio.music_status(fx.world, fx.e);
    CHECK(st.song == "music/loop.song.json");
    CHECK(st.error.empty());

    // A section given still wins.
    PlayerFx named;
    named.step(0.7);
    REQUIRE(named.audio.music_crossfade_to(named.world, named.e, "music/other.song.json", "main", MusicQuantize::Beat, 0.5f).ok());
    named.step(1.5);
    CHECK(named.mp().section == "main");
}

TEST_CASE("music player: a crossfade queued by the previous scene is dropped when the next scene's player takes the transport over") {
    PlayerFx fx;
    fx.step(0.7);
    REQUIRE(fx.audio.music_crossfade_to(fx.world, fx.e, "music/other.song.json", "", MusicQuantize::Bar, 1.0f).ok());
    REQUIRE(fx.audio.music_go_to_section(fx.world, fx.e, "outro", MusicQuantize::Bar, 0.0f).ok());
    fx.step(0.3);                                          // before the bar line at 2 s
    REQUIRE(fx.audio.music_status(fx.world, fx.e).pending == 2);

    // The scene reloads: its player wants the song that was audible.
    const Entity again = next_scene_player(fx, "music/test.song.json");
    fx.world.events().game.clear();
    fx.step(0.1);
    REQUIRE(fx.audio.music_players().size() == 1);
    CHECK(fx.audio.music_players()[0]["orphan"] == false);
    auto st = fx.audio.music_status(fx.world, again);
    CHECK(st.song == "music/test.song.json");
    CHECK(st.pending == 0);
    CHECK(st.pendingSong.empty());
    CHECK_FALSE(st.pendingAt.has_value());
    CHECK(st.positionSeconds > 0.9);                       // not restarted: it plays on from where it was (1.0 s)
    CHECK(st.positionSeconds < 1.2);

    // The bar line comes: neither the crossfade nor the section jump happens, and the new scene's own calls run against the song it hears.
    fx.step(2.5);
    CHECK(fx.events("music.crossfade").empty());
    st = fx.audio.music_status(fx.world, again);
    CHECK(st.song == "music/test.song.json");
    CHECK(fx.world.get<MusicPlayer>(again)->section == "main");   // the intro ended into main: no jump to outro
    CHECK(fx.audio.music_go_to_section(fx.world, again, "main", MusicQuantize::Bar).ok());
}

TEST_CASE("music player: a crossfade that had started when the scene changed is adopted with its target song") {
    PlayerFx fx;
    fx.step(0.7);
    REQUIRE(fx.audio.music_crossfade_to(fx.world, fx.e, "music/other.song.json", "", MusicQuantize::Bar, 1.0f).ok());
    fx.step(2.5);                                          // the crossfade started at 2 s and lasts 2 s
    REQUIRE(fx.audio.music_status(fx.world, fx.e).song == "music/other.song.json");

    const Entity again = next_scene_player(fx, "music/other.song.json");
    fx.step(0.1);
    REQUIRE(fx.audio.music_players().size() == 1);
    CHECK(fx.audio.music_players()[0]["orphan"] == false);
    auto st = fx.audio.music_status(fx.world, again);
    CHECK(st.song == "music/other.song.json");
    CHECK(st.tempo == doctest::Approx(90.0));
    CHECK(st.positionSeconds > 0.5);                       // still the same playhead: not restarted
    CHECK(fx.audio.music_go_to_section(fx.world, again, "main", MusicQuantize::Bar).ok());
}

namespace {

// A player on a device that a test drives, with the jobs of the project run only when the test says (jobs::end_frame): a song the
// player loads stays "loading" for as long as the test wants.
struct LoadingFx : PlayerFx {
    audio_test::JobPool pool{jobs::Settings::threads(0)};
    LoadingFx() { AudioTestAccess::use_manual_device(audio, 44100); }
    void frame(bool runJobs) {
        audio.update(world, 1.0f / 60.0f);
        (void)render_device(audio, 2);
        if (runJobs) jobs::end_frame();
    }
    void play_a_little() {
        for (int i = 0; i < 20 && !mp().ready; ++i) frame(true);
        REQUIRE(mp().ready);
        for (int i = 0; i < 20; ++i) frame(false);
    }
};

}  // namespace

TEST_CASE("music player: crossfadeTo while the song still loads has no frame yet, and pendingSong says what waits") {
    LoadingFx fx;
    fx.play_a_little();
    auto change = fx.audio.music_crossfade_to(fx.world, fx.e, "music/other.song.json", "", MusicQuantize::Bar, 1.0f);
    REQUIRE(change.ok());
    CHECK_FALSE(change->frame.has_value());
    CHECK(change->to_json()["frame"].is_null());
    CHECK(change->quantize == MusicQuantize::Bar);
    for (int i = 0; i < 3; ++i) fx.frame(false);   // the job has not run: the song is loading
    auto st = fx.audio.music_status(fx.world, fx.e);
    CHECK(st.song == "music/test.song.json");
    CHECK(st.pendingSong == "music/other.song.json");
    CHECK_FALSE(st.pendingAt.has_value());
    CHECK(st.to_json()["pendingSong"] == "music/other.song.json");
    CHECK(st.to_json()["pendingAt"].is_null());

    // The load ends: the crossfade is handed to the mixer and now has its frame.
    fx.frame(true);
    for (int i = 0; i < 10 && !fx.audio.music_status(fx.world, fx.e).pendingAt.has_value(); ++i) fx.frame(false);
    st = fx.audio.music_status(fx.world, fx.e);
    CHECK(st.song == "music/test.song.json");
    CHECK(st.pendingSong == "music/other.song.json");
    CHECK(st.pendingAt.has_value());
}

TEST_CASE("music player: a song that fails to load is an error of the player, not a pending change") {
    LoadingFx fx;
    REQUIRE(fs::write_text("music/broken.song.json", "{ \"format\": ").ok());
    fx.play_a_little();
    REQUIRE(fx.audio.music_crossfade_to(fx.world, fx.e, "music/broken.song.json", "", MusicQuantize::Bar, 1.0f).ok());
    fx.frame(false);
    CHECK(fx.audio.music_status(fx.world, fx.e).pendingSong == "music/broken.song.json");   // while it loads
    fx.frame(true);                                                                           // the load fails
    for (int i = 0; i < 3; ++i) fx.frame(false);
    const auto st = fx.audio.music_status(fx.world, fx.e);
    CHECK_FALSE(st.error.empty());
    CHECK(st.pendingSong.empty());                  // nothing waits for it, now or ever
    CHECK_FALSE(st.pendingAt.has_value());
    CHECK(st.song == "music/test.song.json");       // the song that was playing is still what is audible
}

TEST_CASE("music player: a player of the next scene that wants the target of a crossfade not started yet is not adopted") {
    PlayerFx fx;
    fx.step(0.7);
    REQUIRE(fx.audio.music_crossfade_to(fx.world, fx.e, "music/other.song.json", "", MusicQuantize::Bar, 1.0f).ok());
    fx.step(0.1);                                          // the other song is loaded (the null device does it in the call), the bar line is at 2 s
    const Entity again = next_scene_player(fx, "music/other.song.json");
    fx.step(0.1);
    const Json players = fx.audio.music_players();
    REQUIRE(players.size() == 2);
    int orphans = 0;
    for (const Json& p : players) {
        if (p["orphan"] != true) continue;
        ++orphans;
        CHECK(p["pendingSong"].is_null());                 // an orphan asks for nothing
        CHECK(p["pendingAt"].is_null());
    }
    CHECK(orphans == 1);
    const auto st = fx.audio.music_status(fx.world, again);
    CHECK(st.song == "music/other.song.json");
    CHECK(st.positionSeconds < 0.5);                       // its own transport, from the beginning
    CHECK(st.pendingSong.empty());
}

TEST_CASE("music player: two intensity changes for the same boundary leave one, the last") {
    PlayerFx fx;
    fx.step(0.7);
    const auto first = fx.audio.music_set_intensity(fx.world, fx.e, 1.0f, MusicQuantize::Bar);
    const auto second = fx.audio.music_set_intensity(fx.world, fx.e, 0.5f, MusicQuantize::Bar);
    REQUIRE(first.frame.has_value());
    REQUIRE(second.frame.has_value());
    CHECK(*first.frame == kBar);
    CHECK(*second.frame == kBar);
    fx.step(0.1);
    auto st = fx.audio.music_status(fx.world, fx.e);
    CHECK(st.pending == 1);                                // the second replaced the first
    CHECK(st.requestedIntensity == doctest::Approx(0.5f));
    CHECK(st.appliedIntensity == doctest::Approx(0.0f));
    fx.step(1.4);
    st = fx.audio.music_status(fx.world, fx.e);
    CHECK(st.pending == 0);
    CHECK(st.appliedIntensity == doctest::Approx(0.5f));
}

TEST_CASE("music player: crossfadeTo a song the transport refuses is an error that says why, and the player stops") {
    PlayerFx fx;
    // A song with more stems than a player mixes: the loader refuses such a song, so the source is put in the cache ready-made.
    SongDoc song = parsed(demo_json());
    std::vector<std::pair<float, int>> stems;
    for (std::size_t i = 0; i <= kMusicMaxStems; ++i) stems.push_back({0.0f, 100});
    AudioTestAccess::put_music_source(fx.audio, fake_source(song, stems, "music/big.song.json"));
    REQUIRE(fs::write_text("music/big.song.json", demo_json().dump()).ok());
    fx.step(0.7);
    auto r = fx.audio.music_crossfade_to(fx.world, fx.e, "music/big.song.json", "", MusicQuantize::Bar, 1.0f);
    REQUIRE_FALSE(r.ok());
    CHECK(r.error().message.find("music/big.song.json") != std::string::npos);
    CHECK(r.error().message.find("stems") != std::string::npos);
    CHECK_FALSE(r.error().hint.empty());
    CHECK_FALSE(fx.mp().playing);
    CHECK_FALSE(fx.audio.music_status(fx.world, fx.e).error.empty());
}

TEST_CASE("music cache: stats count the decoded stems of every cached song, exactly, and a song let go stops counting") {
    PlayerFx fx;
    fx.mp().quantize = MusicQuantize::None;
    fx.mp().crossfadeBars = 0.25f;
    fx.step(0.5);
    REQUIRE(fx.mp().ready);
    // What the cache must hold: every stem of the render, 16-bit stereo, counted by hand from frames x channels x sample size.
    auto expected = [&](const Json& doc) {
        SongDoc song = parsed(doc);
        auto src = music_render_source(song, timeline_of(song), "x.song.json");
        REQUIRE(bool(src));
        std::size_t n = 0;
        for (const MusicStem& s : (*src)->stems) n += s.frames() * 2 /*channels*/ * sizeof(std::int16_t);
        return n;
    };
    Json other = demo_json();
    other["tempo"] = 90;
    const std::size_t a = expected(demo_json());
    const std::size_t b = expected(other);
    REQUIRE(a > 0);
    REQUIRE(b != a);

    const Json st = fx.audio.stats();
    CHECK(st["musicBytes"].get<std::size_t>() == a);
    CHECK(st["decodedBytes"].get<std::size_t>() == a);  // no clip is loaded: the music is all the decoded audio there is
    CHECK(fx.audio.music_bytes() == a);
    const Json cache = fx.audio.music_cache_json();
    REQUIRE(cache.size() == 1);
    CHECK(cache[0]["song"] == "music/test.song.json");
    CHECK(cache[0]["mode"] == "live");
    CHECK(cache[0]["bytes"].get<std::size_t>() == a);
    std::size_t stemSum = 0;
    for (const Json& s : cache[0]["stems"]) stemSum += s["bytes"].get<std::size_t>();
    CHECK(stemSum == a);

    // The other song joins the cache (the first one still counts: the cache keeps what was played), then the first is let
    // go (a reload drops it) and its bytes stop counting.
    fx.mp().song = "music/other.song.json";
    fx.step(1.0);
    REQUIRE(fx.mp().ready);
    CHECK(fx.audio.music_bytes() == a + b);
    CHECK(fx.audio.music_cache_json().size() == 2);
    fx.audio.reload_song("music/test.song.json");
    CHECK(fx.audio.music_bytes() == b);
    CHECK(fx.audio.stats()["musicBytes"].get<std::size_t>() == b);
    CHECK(fx.audio.music_cache_json().size() == 1);
}

// ---- streamed stems (M101.1b): the stems stay encoded and a window of decoded chunks follows the playheads ----------------------------

namespace {

using audio_detail::MusicStemStream;

// `seconds` of stereo that changes in time (two tones and a slow wobble), so a chunk decoded from the wrong place is easy to tell.
std::vector<float> wobble(double seconds, double freq) {
    std::vector<float> s;
    const std::size_t n = std::size_t(seconds * kMusicRate);
    s.reserve(n * 2);
    for (std::size_t i = 0; i < n; ++i) {
        const double t = double(i) / kMusicRate;
        const double env = 0.6 + 0.3 * std::sin(0.7 * t);
        s.push_back(float(env * 0.4 * std::sin(6.2831853 * freq * t)));
        s.push_back(float(env * 0.3 * std::sin(6.2831853 * freq * 1.5 * t + 0.4 * std::sin(3.0 * t))));
    }
    return s;
}

std::vector<std::uint8_t> ogg_of(const std::vector<float>& stereo) {
    auto ogg = encode_vorbis(audio_test::wav_bytes(stereo, 2, kMusicRate));
    REQUIRE_MESSAGE(ogg.ok(), (ogg.ok() ? "" : ogg.error().to_string()));
    return *ogg;
}

struct OggStems {
    std::vector<std::vector<std::uint8_t>> files;
    std::vector<std::string> names;
    std::vector<float> thresholds;
    std::size_t frames = 0;
};

// The stems of the demo song as music.render would leave them, in ogg (encoded once for the whole test run).
const OggStems& demo_ogg_stems() {
    static const OggStems stems = [] {
        OggStems o;
        SongDoc song = parsed(demo_json());
        auto live = music_render_source(song, timeline_of(song), "music/test.song.json");
        REQUIRE(bool(live));
        for (const MusicStem& st : (*live)->stems) {
            std::vector<float> samples(st.pcm.size());
            for (std::size_t k = 0; k < samples.size(); ++k) samples[k] = float(st.pcm[k]) * st.scale;
            o.files.push_back(ogg_of(samples));
            o.names.push_back(st.name);
            o.thresholds.push_back(st.threshold);
            o.frames = st.frames();
        }
        return o;
    }();
    return stems;
}

// Writes the files and the import.music of the demo song's mix, with `stream` as its import.music.stream ("" = not written). `songSha`
// ("" = none) is the hash of the song that music.render records in the mix entry's provenance.recipe.inputs.
void install_stems(audio_test::Fixture& fx, const OggStems& s, const std::string& stream, const std::string& songSha = std::string()) {
    Json stems = Json::array();
    for (std::size_t i = 0; i < s.files.size(); ++i) {
        const std::string file = "assets/music/test_" + s.names[i] + ".ogg";
        audio_test::write_file(fx.dir / file, s.files[i]);
        stems.push_back(Json::object({{"path", file}, {"name", s.names[i]}, {"intensity", s.thresholds[i]}}));
    }
    Json music = Json::object({{"role", "mix"}, {"song", "music/test.song.json"}, {"stems", stems}});
    if (!stream.empty()) music["stream"] = stream;
    Json entry = Json::object({{"import", Json::object({{"music", music}})}});
    if (!songSha.empty()) {
        Json inputs = Json::array({Json::object({{"path", "music/test.song.json"}, {"sha256", songSha}})});
        entry["provenance"] = Json::object({{"recipe", Json::object({{"command", "music.render"}, {"args", Json::object()}, {"inputs", inputs}})}});
    }
    fx.write_assets(Json::object({{"format", "factoria.assets/1"}, {"assets", Json::object({{"assets/music/test.ogg", entry}})}}).dump());
}

}  // namespace

TEST_CASE("music stream: a chunk decoded after a seek is the one decoded in order, and what cannot stream says why") {
    const std::vector<std::uint8_t> ogg = ogg_of(wobble(6.0, 330.0));
    auto bytes = std::make_shared<const audio_detail::Bytes>(ogg);
    std::string why;
    auto inOrder = MusicStemStream::open(bytes, ".ogg", &why);
    REQUIRE_MESSAGE(inOrder, why);
    auto jumpy = MusicStemStream::open(bytes, ".ogg", &why);
    REQUIRE_MESSAGE(jumpy, why);
    CHECK(inOrder->frames() == 6 * kMusicRate);
    const std::int64_t count = inOrder->chunk_count();
    REQUIRE(count > 24);  // more chunks than the window holds

    auto copy = [](MusicStemStream& s, std::int64_t chunk) {
        std::vector<float> out;
        int slot = -1;
        const float* d = s.pin(chunk, &slot);
        REQUIRE(d != nullptr);
        out.assign(d, d + 2 * audio_detail::kMusicChunkFrames);
        s.unpin(slot);
        return out;
    };
    std::vector<std::vector<float>> sequential;
    REQUIRE(inOrder->claim());
    for (std::int64_t c = 0; c < count; ++c) {
        REQUIRE(inOrder->decode_now(c));
        sequential.push_back(copy(*inOrder, c));
    }
    inOrder->unclaim();
    CHECK(inOrder->decode_errors() == 0);

    // Chunks in a scattered order (each one seeks, backwards and forwards), against the ones decoded in order.
    REQUIRE(jumpy->claim());
    const std::int64_t order[] = {20, 3, count - 1, 0, 17, count - 2, 9, 2, 11, 1};
    for (std::int64_t c : order) {
        REQUIRE(jumpy->decode_now(c));
        const std::vector<float> got = copy(*jumpy, c);
        double worst = 0.0;
        for (std::size_t i = 0; i < got.size(); ++i) worst = std::max(worst, double(std::fabs(got[i] - sequential[std::size_t(c)][i])));
        CHECK_MESSAGE(worst == 0.0, "chunk " << c << " differs by " << worst << " after a seek");
    }
    jumpy->unclaim();
    CHECK(jumpy->decode_errors() == 0);
    // The chunk past the end of the stem is silence, not noise.
    const std::vector<float>& last = sequential.back();
    const std::size_t tail = std::size_t(inOrder->frames() - (count - 1) * audio_detail::kMusicChunkFrames);
    for (std::size_t i = tail * 2; i < last.size(); ++i) CHECK(last[i] == 0.0f);

    // What cannot stream: a WAV, a rate that is not the mixer's.
    why.clear();
    auto wav = std::make_shared<const audio_detail::Bytes>(audio_test::wav_bytes(wobble(1.0, 220.0), 2, kMusicRate));
    CHECK_FALSE(MusicStemStream::open(wav, ".wav", &why));
    CHECK(why.find("ogg") != std::string::npos);
    std::vector<float> mono;
    audio_test::add_sine(mono, 1.0, 440.0, 0.5, 22050);
    auto slow = encode_vorbis(audio_test::wav_bytes(mono, 1, 22050));
    REQUIRE(slow.ok());
    why.clear();
    CHECK_FALSE(MusicStemStream::open(std::make_shared<const audio_detail::Bytes>(*slow), ".ogg", &why));
    CHECK(why.find("44100") != std::string::npos);
}

TEST_CASE("music player: streamed stems play the same as whole-decoded ones, section jumps and loops land on the same frames") {
    const OggStems& stems = demo_ogg_stems();
    struct Run {
        Recording rec;
        std::vector<std::pair<std::string, std::uint64_t>> events;
        Json cache;
        Json stats;
    };
    auto play = [&](const std::string& stream) {
        PlayerFx fx;
        install_stems(fx, stems, stream);
        fx.mp().quantize = MusicQuantize::Beat;
        fx.mp().layerFade = 0.1f;
        fx.mp().intensity = 0.2f;
        fx.audio.start_recording();
        fx.step(1.0);
        REQUIRE(fx.mp().playing);
        fx.audio.music_set_intensity(fx.world, fx.e, 1.0f, MusicQuantize::Beat);   // the harmony layer fades in
        fx.step(1.5);
        REQUIRE(fx.audio.music_go_to_section(fx.world, fx.e, "main", MusicQuantize::Bar, 0.05f).ok());
        fx.step(5.0);                                                              // the loop wraps (bars 2-3 of 4) at least once
        REQUIRE(fx.audio.music_go_to_section(fx.world, fx.e, "intro", MusicQuantize::Beat, 0.0f).ok());  // back to the start: a seek
        fx.step(1.0);
        MusicStingerSpec spec;
        spec.section = "outro";
        spec.quantize = MusicQuantize::Beat;
        REQUIRE(fx.audio.music_play_stinger(fx.world, fx.e, spec).ok());
        fx.step(3.0);
        Run run;
        for (const GameEvent& g : fx.world.events().game)
            if (g.name.rfind("music.", 0) == 0)
                run.events.emplace_back(g.name + ":" + g.data.value("section", std::string()), g.data.value("frame", std::uint64_t(0)));
        run.rec = fx.finish();
        run.cache = fx.audio.music_cache_json();
        run.stats = fx.audio.stats();
        return run;
    };
    const Run streamed = play("always");
    const Run whole = play("never");
    REQUIRE(streamed.cache.size() == 1);
    CHECK(streamed.cache[0]["mode"] == "stems");
    CHECK(streamed.cache[0]["streamed"] == true);
    CHECK(streamed.stats["streamedSongs"] == 1);
    CHECK(streamed.stats["musicUnderruns"] == 0);   // the null device decodes on the spot: no gap
    REQUIRE(whole.cache.size() == 1);
    CHECK(whole.cache[0]["mode"] == "stems");
    CHECK(whole.cache[0]["streamed"] == false);
    CHECK(whole.stats["streamedSongs"] == 0);

    // The same events on the same frames (sections, loops, beats, the stinger), and the same sound within the 16-bit rounding of the
    // whole path: a stream that is a frame off would be 0.03 or more away on this tone.
    CHECK(streamed.events == whole.events);
    CHECK(streamed.events.size() > 20);
    REQUIRE(streamed.rec.frames() == whole.rec.frames());
    CHECK(whole.rec.peak() > 0.05f);
    double worst = 0.0;
    for (std::size_t i = 0; i < whole.rec.frames(); ++i)
        worst = std::max({worst, double(std::fabs(streamed.rec.l[i] - whole.rec.l[i])), double(std::fabs(streamed.rec.r[i] - whole.rec.r[i]))});
    CHECK(worst < 0.002);
}

TEST_CASE("music player: import.music.stream decides which stems stream, `auto` from 20 seconds on, and the memory of each way") {
    const OggStems& demo = demo_ogg_stems();  // about 10 seconds a stem
    auto streamed_after = [&](const std::string& stream) {
        PlayerFx fx;
        install_stems(fx, demo, stream);
        fx.step(0.5);
        REQUIRE(fx.mp().ready);
        const Json cache = fx.audio.music_cache_json();
        REQUIRE(cache.size() == 1);
        CHECK(cache[0]["mode"] == "stems");
        return cache[0]["streamed"].get<bool>();
    };
    CHECK_FALSE(streamed_after(""));       // auto: the stems are shorter than 20 seconds, decoded whole
    CHECK_FALSE(streamed_after("auto"));
    CHECK_FALSE(streamed_after("never"));
    CHECK(streamed_after("always"));

    // Four layers of a minute: the rule a long song gets (docs/MUSIC.md, "What the music costs in memory").
    OggStems minute;
    const std::vector<float> tone = wobble(60.0, 196.0);
    const std::vector<std::uint8_t> file = ogg_of(tone);
    minute.frames = tone.size() / 2;
    for (int i = 0; i < 4; ++i) {
        minute.files.push_back(file);
        minute.names.push_back("layer" + std::to_string(i));
        minute.thresholds.push_back(0.25f * float(i));
    }
    const std::size_t wholeBytes = 4 * minute.frames * 2 * sizeof(std::int16_t);
    CHECK(wholeBytes > 40'000'000);
    {
        PlayerFx fx;
        install_stems(fx, minute, "");   // auto: a minute streams
        fx.mp().intensity = 1.0f;
        fx.step(0.5);
        REQUIRE(fx.mp().ready);
        const Json cache = fx.audio.music_cache_json();
        REQUIRE(cache.size() == 1);
        CHECK(cache[0]["streamed"] == true);
        REQUIRE(cache[0]["stems"].size() == 4);
        for (const Json& s : cache[0]["stems"]) CHECK(s["streamed"] == true);
        const std::size_t streamedBytes = fx.audio.music_bytes();
        CHECK(fx.audio.stats()["musicBytes"].get<std::size_t>() == streamedBytes);
        // The window is fixed: the encoded file, 32 chunks (2 MiB) and a scratch buffer each, whatever the song's length.
        CHECK(streamedBytes < 4 * (file.size() + 2'300'000));
        CHECK(streamedBytes < 12'000'000);
        CHECK(streamedBytes * 3 < wholeBytes);
        // Playing, jumping and looping does not grow it.
        fx.step(3.0);
        REQUIRE(fx.audio.music_go_to_section(fx.world, fx.e, "outro", MusicQuantize::None, 0.0f).ok());
        fx.step(3.0);
        CHECK(fx.audio.music_bytes() == streamedBytes);
    }
    {
        PlayerFx fx;
        install_stems(fx, minute, "never");
        fx.step(0.5);
        REQUIRE(fx.mp().ready);
        CHECK(fx.audio.music_bytes() == wholeBytes);
        CHECK(fx.audio.stats()["streamedSongs"] == 0);
    }
}

TEST_CASE("music player: a player that asks for live renders the song live, with stem files there and whatever the device") {
    PlayerFx fx;
    install_stems(fx, demo_ogg_stems(), "always");
    fx.mp().mode = MusicMode::Live;
    MusicDeviceProfile phone;
    phone.formFactor = "phone";
    phone.tier = "medium";
    fx.audio.set_music_device(phone);
    fx.step(0.5);
    REQUIRE(fx.mp().ready);
    CHECK(fx.mp().activeMode == "live");
    CHECK(fx.audio.stats()["streamedSongs"] == 0);
}

TEST_CASE("music player: a streamed song whose chunks are not decoded plays silence, is counted, and comes back when the service catches up") {
    PlayerFx fx;
    install_stems(fx, demo_ogg_stems(), "always");
    fx.mp().intensity = 1.0f;
    fx.mp().layerFade = 0.0f;
    AudioTestAccess::use_manual_device(fx.audio, 44100);
    AudioTestAccess::set_stream_service(fx.audio, false);  // as if the music service were late
    auto frame = [&](int blocks) {
        fx.audio.update(fx.world, 1.0f / 60.0f);
        const float peak = render_device(fx.audio, blocks);
        (void)AudioTestAccess::music_service_pass(fx.audio);  // what the service thread does every few ms (nothing while it is off)
        return peak;
    };
    for (int i = 0; i < 10 && !fx.mp().ready; ++i) frame(1);
    REQUIRE(fx.mp().ready);
    // The first chunks were decoded when the song loaded (about 0.37 s): sound, then the window runs dry.
    float early = 0.0f;
    for (int i = 0; i < 8; ++i) early = std::max(early, frame(2));
    CHECK(early > 0.01f);
    for (int i = 0; i < 60; ++i) frame(2);   // past the primed chunks (32 blocks), never waiting for the decoder
    CHECK(frame(4) == 0.0f);                 // silence, not noise or a repeat
    Json st = fx.audio.stats();
    CHECK(st["musicUnderruns"].get<std::uint64_t>() > 0);
    CHECK(st["musicUnderrunFrames"].get<std::uint64_t>() >= std::uint64_t(20 * 512));
    CHECK(st["underruns"].get<std::uint64_t>() >= st["musicUnderruns"].get<std::uint64_t>());
    CHECK(fx.audio.music_cache_json()[0]["underruns"].get<std::uint64_t>() == st["musicUnderruns"].get<std::uint64_t>());
    CHECK(fx.mp().playing);   // the music kept its place in time: a song cannot wait

    // The service is back: the window is refilled ahead of the playhead and the sound returns.
    AudioTestAccess::set_stream_service(fx.audio, true);
    frame(1);
    float again = 0.0f;
    for (int i = 0; i < 6; ++i) again = std::max(again, frame(2));
    CHECK(again > 0.01f);
    const std::uint64_t before = fx.audio.stats()["musicUnderruns"].get<std::uint64_t>();
    for (int i = 0; i < 40; ++i) frame(2);
    CHECK(fx.audio.stats()["musicUnderruns"].get<std::uint64_t>() == before);   // refilled every frame: no more gaps
}

TEST_CASE("music player: with a device thread a streamed song mixes without allocating, through jumps, a stinger and a crossfade") {
    audio_test::JobPool pool(jobs::Settings::threads(2));
    {
        PlayerFx fx;
        install_stems(fx, demo_ogg_stems(), "always");
        fx.mp().quantize = MusicQuantize::Beat;
        fx.mp().crossfadeBars = 0.25f;
        fx.mp().intensity = 1.0f;
        AudioTestAccess::use_manual_device(fx.audio, 48000);
        AudioTestAccess::start_music_thread(fx.audio);
        (void)render_device(fx.audio, 0);
        std::size_t allocs = 0;
        auto frame = [&](int blocks) {
            fx.audio.update(fx.world, 1.0f / 60.0f);
            audio_test::AllocCounter::Scope scope;
            const float peak = render_device(fx.audio, blocks);
            allocs += scope.count();
            return peak;
        };
        const auto deadline = std::chrono::steady_clock::now() + std::chrono::seconds(60);   // a safety net far above the load
        while (!fx.mp().ready && std::chrono::steady_clock::now() < deadline) frame(2);
        REQUIRE(fx.mp().ready);
        CHECK(fx.audio.stats()["streamedSongs"] == 1);
        float early = 0.0f;
        for (int i = 0; i < 10; ++i) early = std::max(early, frame(2));   // inside the chunks decoded at the load
        CHECK(early > 0.01f);
        for (int i = 0; i < 50; ++i) frame(2);
        REQUIRE(fx.audio.music_go_to_section(fx.world, fx.e, "main", MusicQuantize::Beat).ok());
        MusicStingerSpec spec;
        spec.section = "outro";
        spec.quantize = MusicQuantize::Beat;
        spec.duck = 0.5f;
        REQUIRE(fx.audio.music_play_stinger(fx.world, fx.e, spec).ok());
        for (int i = 0; i < 60; ++i) frame(2);
        fx.mp().song = "music/other.song.json";   // a crossfade to a song that renders live
        const auto again = std::chrono::steady_clock::now() + std::chrono::seconds(60);
        while (fx.mp().tempo != 90.0f && std::chrono::steady_clock::now() < again) frame(2);
        CHECK(fx.mp().tempo == doctest::Approx(90.0f));
        for (int i = 0; i < 60; ++i) frame(2);
        CHECK(fx.mp().playing);
        CHECK_MESSAGE(allocs == 0, "the device callback allocated " << allocs << " times while the streamed music played");
    }
}

TEST_CASE("music player: the callback, the game and the music service thread share a streamed song while it jumps") {
    audio_test::JobPool pool(jobs::Settings::threads(2));
    {
        PlayerFx fx;
        install_stems(fx, demo_ogg_stems(), "always");
        fx.mp().quantize = MusicQuantize::Beat;
        fx.mp().intensity = 1.0f;
        AudioTestAccess::use_manual_device(fx.audio, 48000);
        AudioTestAccess::start_music_thread(fx.audio);
        const auto deadline = std::chrono::steady_clock::now() + std::chrono::seconds(60);   // a safety net far above the load
        while (!fx.mp().ready && std::chrono::steady_clock::now() < deadline) {
            fx.audio.update(fx.world, 1.0f / 60.0f);
            (void)render_device(fx.audio, 1);
        }
        REQUIRE(fx.mp().ready);
        std::atomic<bool> stopMixing{false};
        std::atomic<std::size_t> allocs{0};
        std::atomic<std::uint64_t> blocks{0};
        std::thread callback([&] {
            std::vector<float> buf(512 * 2);
            while (!stopMixing.load(std::memory_order_acquire)) {
                {
                    audio_test::AllocCounter::Scope scope;
                    AudioTestAccess::render(fx.audio, buf.data(), 512, 2);
                    allocs.fetch_add(scope.count(), std::memory_order_relaxed);
                }
                blocks.fetch_add(1, std::memory_order_relaxed);
                std::this_thread::yield();
            }
        });
        // The game: 400 frames, a jump to a section, an intensity or a stinger in most of them (a few hundred commands, 10x under the ring).
        static const char* const kSections[] = {"intro", "main", "outro", "main"};
        MusicStingerSpec spec;
        spec.section = "outro";
        spec.quantize = MusicQuantize::Beat;
        for (int i = 0; i < 400; ++i) {
            fx.audio.update(fx.world, 1.0f / 60.0f);
            if (i % 4 == 1) (void)fx.audio.music_go_to_section(fx.world, fx.e, kSections[(i / 4) % 4], MusicQuantize::None, 0.02f);
            if (i % 9 == 4) (void)fx.audio.music_set_intensity(fx.world, fx.e, (i / 9) % 2 ? 1.0f : 0.1f);
            if (i % 50 == 7) (void)fx.audio.music_play_stinger(fx.world, fx.e, spec);
            if (i % 20 == 0) (void)fx.audio.stats();
            std::this_thread::yield();
        }
        stopMixing.store(true, std::memory_order_release);
        callback.join();
        CHECK(blocks.load() > 0);
        CHECK_MESSAGE(allocs.load() == 0, "the device callback allocated " << allocs.load() << " times");
        CHECK(fx.mp().playing);
        const Json st = fx.audio.stats();
        CHECK(st["commandsDropped"].get<std::uint64_t>() == 0);
        CHECK(st["streamedSongs"] == 1);
    }
}

TEST_CASE("music stream: the service skips a stem the mixer stopped publishing, decodes the urgent chunks first and rests when nothing can change") {
    auto bytes = std::make_shared<const audio_detail::Bytes>(ogg_of(wobble(8.0, 262.0)));
    std::string why;
    auto s = MusicStemStream::open(bytes, ".ogg", &why);
    REQUIRE_MESSAGE(s, why);
    REQUIRE(s->chunk_count() > std::int64_t(audio_detail::kMusicSlots));   // more chunks than the window holds

    // live(): published within the last 3 publishes; a publish newer than the counter the pass read is not stale (unsigned wrap).
    CHECK_FALSE(s->live(10));   // never published
    const std::size_t opened = s->decoded_chunks();   // opening may decode a first chunk to read the header
    CHECK_FALSE(s->service(10));
    CHECK(s->decoded_chunks() == opened);             // a stem nobody reads is left alone
    s->publish_head(10, 0.0, 0.0, 0.0, false);
    CHECK(s->live(10));
    CHECK(s->live(13));
    CHECK_FALSE(s->live(14));
    CHECK(s->live(9));

    // The urgent round: only the first kMusicUrgent chunks of the head.
    CHECK(s->service(10, true));   // more is missing and the thread made progress
    for (std::int64_t c = 0; c < audio_detail::kMusicUrgent; ++c) CHECK(s->resident(c));
    CHECK_FALSE(s->resident(audio_detail::kMusicUrgent));
    // The full round fills the look-ahead; a stem with nothing left to do answers "no need to come back".
    int passes = 0;
    while (s->service(10) && passes < 20) ++passes;
    CHECK(passes < 20);
    for (std::int64_t c = 0; c < audio_detail::kMusicLookAhead; ++c) CHECK(s->resident(c));
    CHECK_FALSE(s->service(10));
    CHECK_FALSE(s->missing_any());

    // A window that cannot hold what is wanted: three heads and a jump just primed. Nothing more can be decoded, so the pass says so
    // (answering "come back soon" forever would wake the thread every 2 ms for nothing).
    auto crowded = MusicStemStream::open(bytes, ".ogg", &why);
    REQUIRE_MESSAGE(crowded, why);
    crowded->prime(36, 4);
    crowded->publish_head(20, 0.0, 0.0, 0.0, false);
    crowded->publish_head(20, 12.0 * double(audio_detail::kMusicChunkFrames), 0.0, 0.0, false);
    crowded->publish_head(20, 24.0 * double(audio_detail::kMusicChunkFrames), 0.0, 0.0, false);
    passes = 0;
    while (crowded->service(20) && passes < 20) ++passes;
    CHECK(passes < 20);
    CHECK(crowded->decoded_chunks() == audio_detail::kMusicSlots);
    CHECK_FALSE(crowded->service(20));
}

TEST_CASE("music stream: a game that waits for a stem gives up after the limit it was given, and gets it when the holder lets go") {
    auto bytes = std::make_shared<const audio_detail::Bytes>(ogg_of(wobble(2.0, 330.0)));
    std::string why;
    auto s = MusicStemStream::open(bytes, ".ogg", &why);
    REQUIRE_MESSAGE(s, why);
    s->set_claim_wait_limit(30);
    REQUIRE(s->claim());
    const auto t0 = std::chrono::steady_clock::now();
    CHECK_FALSE(s->claim_wait());   // the holder never lets go
    CHECK(std::chrono::steady_clock::now() - t0 >= std::chrono::milliseconds(15));   // the limit is a lower bound; a slow machine may take longer
    CHECK(s->waiters() == 0);
    s->unclaim();
    CHECK(s->claim_wait());
    s->unclaim();
}

TEST_CASE("music stream: underruns are added to the tally of the stem and to the one the Audio keeps") {
    auto bytes = std::make_shared<const audio_detail::Bytes>(ogg_of(wobble(1.0, 220.0)));
    std::string why;
    auto s = MusicStemStream::open(bytes, ".ogg", &why);
    REQUIRE_MESSAGE(s, why);
    s->note_underrun(7);   // before a tally exists: only the stem counts
    auto tally = std::make_shared<audio_detail::MusicTally>();
    s->set_tally(tally);
    s->note_underrun(100);
    s->note_underrun(28);
    CHECK(s->underrun_events() == 3);
    CHECK(s->underrun_frames() == 135);
    CHECK(tally->events.load() == 2);
    CHECK(tally->frames.load() == 128);
}

namespace {

// A player on the manual device whose song is loaded and has played a little (its window is ahead of the playhead).
struct DeviceFx : PlayerFx {
    explicit DeviceFx(const std::string& stems = "always") {
        install_stems(*this, demo_ogg_stems(), stems);
        mp().intensity = 1.0f;
        mp().layerFade = 0.0f;
        AudioTestAccess::use_manual_device(audio, 44100);
    }
    float frame(int blocks) {
        audio.update(world, 1.0f / 60.0f);
        const float peak = render_device(audio, blocks);
        (void)AudioTestAccess::music_service_pass(audio);
        return peak;
    }
    void play_a_little() {
        for (int i = 0; i < 10 && !mp().ready; ++i) frame(1);
        REQUIRE(mp().ready);
        for (int i = 0; i < 60; ++i) frame(2);
    }
};

}  // namespace

TEST_CASE("music player: a jump with no quantize while the music service holds the stem lands on decoded chunks") {
    DeviceFx fx;
    fx.play_a_little();   // the intro, about 1.6 s in; the outro (6 s, chunk 32) is far past the window
    const auto streams = AudioTestAccess::music_streams(fx.audio);
    REQUIRE(streams.size() == 2);
    const std::uint64_t before = fx.audio.stats()["musicUnderruns"].get<std::uint64_t>();
    // The wait for the stem has a safety net of 500 ms; a loaded machine could run past it before the "service" below runs.
    AudioTestAccess::set_claim_wait_limit(fx.audio, 60000);
    for (const auto& s : streams) {
        CHECK_FALSE(s->resident(33));   // the jump's target is not decoded
        REQUIRE(s->claim());            // a decode of the service is in flight on every stem
    }
    // It lets go of a stem when the game waits for it (the decoder yields between chunks to a waiter).
    std::atomic<std::size_t> released{0};
    std::thread service([&] {
        const auto deadline = std::chrono::steady_clock::now() + std::chrono::seconds(30);   // a safety net far above the wait
        for (const auto& s : streams) {
            while (s->waiters() == 0 && std::chrono::steady_clock::now() < deadline) std::this_thread::yield();
            s->unclaim();
            released.fetch_add(1);
        }
    });
    REQUIRE(fx.audio.music_go_to_section(fx.world, fx.e, "outro", MusicQuantize::None, 0.0f).ok());
    service.join();
    CHECK(released.load() == streams.size());
    for (const auto& s : streams) CHECK(s->resident(33));   // the game decoded it itself once the service gave the claim up
    float peak = 0.0f;
    for (int i = 0; i < 20; ++i) peak = std::max(peak, fx.frame(2));
    CHECK(peak > 0.01f);
    CHECK(fx.mp().section == "outro");
    CHECK(fx.audio.stats()["musicUnderruns"].get<std::uint64_t>() == before);
    CHECK(before == 0);
}

TEST_CASE("music player: the music keeps its window with no call of the game for longer than the look-ahead") {
    auto quiet_run = [](bool service) {
        DeviceFx fx;
        fx.play_a_little();
        AudioTestAccess::set_stream_service(fx.audio, service);
        // 7 seconds of the device's callbacks and the service's passes and not one call of the game: a stalled game thread, past the
        // window (6 s) and the look-ahead (2.2 s); the loop of the main section wraps meanwhile.
        float peak = 0.0f;
        std::vector<float> buf(512 * 2);
        for (int i = 0; i < 600; ++i) {
            AudioTestAccess::render(fx.audio, buf.data(), 512, 2);
            for (float v : buf) peak = std::max(peak, std::fabs(v));
            (void)AudioTestAccess::music_service_pass(fx.audio);
        }
        return std::make_pair(fx.audio.stats()["musicUnderruns"].get<std::uint64_t>(), peak);
    };
    const auto served = quiet_run(true);
    CHECK(served.first == 0);
    CHECK(served.second > 0.01f);
    // Without the service the same run goes dry (the test would pass for any reason otherwise).
    CHECK(quiet_run(false).first > 0);
}

TEST_CASE("music player: a song the cache let go of while it plays keeps counting its underruns and its bytes") {
    DeviceFx fx;
    fx.play_a_little();
    AudioTestAccess::set_stream_service(fx.audio, false);
    std::vector<float> buf(512 * 2);
    for (int i = 0; i < 600; ++i) AudioTestAccess::render(fx.audio, buf.data(), 512, 2);   // no refill: the window runs dry
    const std::uint64_t dry = fx.audio.stats()["musicUnderruns"].get<std::uint64_t>();
    const std::size_t bytes = fx.audio.music_bytes();
    REQUIRE(dry > 0);
    REQUIRE(bytes > 0);
    fx.audio.reload_song("music/test.song.json");   // out of the cache; the player still plays this source until it reloads
    CHECK(fx.audio.music_cache_json().size() == 0);
    CHECK(fx.audio.stats()["musicUnderruns"].get<std::uint64_t>() == dry);
    CHECK(fx.audio.music_bytes() == bytes);
    CHECK(fx.audio.stats()["musicBytes"].get<std::size_t>() == bytes);
}

TEST_CASE("music player: the music service thread follows the playhead while the game goes on, and shutdown joins it") {
    audio_test::JobPool pool(jobs::Settings::threads(2));
    {
        DeviceFx fx;
        AudioTestAccess::start_music_thread(fx.audio);
        const auto deadline = std::chrono::steady_clock::now() + std::chrono::seconds(60);   // a safety net far above the load
        while (!fx.mp().ready && std::chrono::steady_clock::now() < deadline) {
            fx.audio.update(fx.world, 1.0f / 60.0f);
            (void)render_device(fx.audio, 1);
        }
        REQUIRE(fx.mp().ready);
        const auto streams = AudioTestAccess::music_streams(fx.audio);
        REQUIRE(streams.size() == 2);
        // The game does not call the service: each frame waits (a condition, not a time) until the thread has decoded 4 chunks ahead.
        for (int i = 0; i < 150; ++i) {
            fx.audio.update(fx.world, 1.0f / 60.0f);
            (void)render_device(fx.audio, 2);
            const std::int64_t ahead = (std::int64_t(fx.audio.music_status(fx.world, fx.e).positionSeconds * 44100.0) >> 13) + 4;
            for (const auto& s : streams)
                while (!s->resident(ahead) && std::chrono::steady_clock::now() < deadline) std::this_thread::yield();
        }
        CHECK(std::chrono::steady_clock::now() < deadline);
        CHECK(fx.audio.stats()["musicUnderruns"].get<std::uint64_t>() == 0);
        CHECK(fx.mp().playing);
    }   // ~Audio: shutdown() stops and joins the thread (a hang here is the test failing)
}

TEST_CASE("music player: auto plays live a song that changed after music.render, with the length unchanged") {
    const OggStems& stems = demo_ogg_stems();
    Json edited = demo_json();
    edited["tracks"]["pad"]["patterns"]["i"] = "(Dm@3):1";   // another chord, the same length: the stems are no longer this song
    auto sha_of_song = [] {   // of the bytes on disk, as music.render records them
        auto bytes = fs::read_bytes("music/test.song.json");
        REQUIRE(bool(bytes));
        return sha256_hex(bytes->data(), bytes->size());
    };
    auto play = [&](MusicMode mode, const Json& song) {
        PlayerFx fx;
        const std::string recorded = sha_of_song();   // the file PlayerFx wrote: the demo song
        REQUIRE(fs::write_text("music/test.song.json", song.dump()).ok());
        install_stems(fx, stems, "", recorded);
        fx.mp().mode = mode;
        fx.step(0.5);
        REQUIRE(fx.mp().ready);
        return fx.mp().activeMode;
    };
    CHECK(play(MusicMode::Auto, demo_json()) == "stems");   // the recorded hash is the file's: the stems are current
    CHECK(play(MusicMode::Auto, edited) == "live");         // not any more: the edit is heard
    CHECK(play(MusicMode::Stems, edited) == "stems");       // asked for by hand: the files play
    CHECK(play(MusicMode::Live, demo_json()) == "live");

    // The plan says it, and the mode choice has its own reason.
    PlayerFx fx;
    const std::string recorded = sha_of_song();
    REQUIRE(fs::write_text("music/test.song.json", edited.dump()).ok());
    install_stems(fx, stems, "", recorded);
    CHECK(music_stem_plan_of("music/test.song.json").stale);
    std::string why;
    CHECK(music_resolve_mode(MusicMode::Auto, MusicDeviceProfile{}, true, &why, true) == MusicMode::Live);
    CHECK(why.find("music.render") != std::string::npos);
    CHECK(music_resolve_mode(MusicMode::Stems, MusicDeviceProfile{}, true, nullptr, true) == MusicMode::Stems);
    // A mix entry that records no hash (an older project) is never stale.
    install_stems(fx, stems, "");
    CHECK_FALSE(music_stem_plan_of("music/test.song.json").stale);
}
