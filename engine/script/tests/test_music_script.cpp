// entity.music: a MusicPlayer driven from a script. The song is rendered live on the null device, so the mixer's frame counter (advanced
// here with the game clock, the way a headless run does) decides where beats, bars and sections fall; two runs give the same frames.
#include <doctest.h>

#include "test_host.h"

using namespace fa;
using namespace fa::test;

namespace {

Json ev(TestHost& h, const std::string& code) {
    auto r = h.scripts.eval(code);
    if (!r.ok()) FAIL(r.error().to_string());
    return *r;
}
std::string ev_err(TestHost& h, const std::string& code) {
    auto r = h.scripts.eval(code);
    return r.ok() ? std::string() : r.error().message;
}
double num(TestHost& h, const std::string& code) { return ev(h, code).get<double>(); }

// 120 BPM in 4/4: a bar is 2 s. intro (1 bar), main (loop, 2 bars), outro (1 bar); a rhythm layer and a harmony layer from intensity 0.5.
const char* kSong = R"({
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
    {"name": "outro", "kind": "outro", "play": {"pad": "o"}}]})";

// The frames the game clock gives the mixer: 1/60 s each, like the engine's fixed step on the null device.
void run(TestHost& h, int frames) {
    for (int i = 0; i < frames; ++i) {
        h.step_frames(1);
        h.au.advance_null_device(h.fdt);
    }
}

const char* kSpawn = R"(globalThis.e = world.spawn({ id: 'theme', components: {
    MusicPlayer: { song: 'music/test.song.json', mode: 'live', volume: 1, layerFade: 0.1 } } });
    globalThis.log = [];
    e.music.on('beat', (d) => log.push('beat:' + d.bar + '.' + d.beat + '@' + d.frame));
    e.music.on('section', (d) => log.push('section:' + d.section + '@' + d.frame));
    e.music.on('ready', (d) => log.push('ready:' + d.mode));)";

}  // namespace

TEST_CASE("entity.music: a player that has no MusicPlayer says how to add one") {
    TestHost h("music_missing");
    REQUIRE(h.start());
    ev(h, "globalThis.e = world.spawn({ id: 'plain', components: {} });");
    const std::string err = ev_err(h, "e.music.play()");
    CHECK(err.find("no MusicPlayer component") != std::string::npos);
    CHECK(err.find("entity.add(\"MusicPlayer\"") != std::string::npos);
}

TEST_CASE("entity.music: the song starts, its beats and sections reach the script on the mixer's frames") {
    TestHost h("music_events");
    h.file("music/test.song.json", kSong);
    REQUIRE(h.start());
    ev(h, kSpawn);
    run(h, 3);
    CHECK(ev(h, "e.music.ready").get<bool>());
    CHECK(ev(h, "e.music.playing").get<bool>());
    CHECK(ev(h, "e.music.section").get<std::string>() == "intro");
    CHECK(num(h, "e.music.tempo") == doctest::Approx(120.0));
    CHECK(ev(h, "e.music.sections.join(',')").get<std::string>() == "intro,main,outro");
    CHECK(ev(h, "e.music.status.mode").get<std::string>() == "live");
    run(h, 130);  // 2.2 s: bar 2 started at 2 s
    CHECK(num(h, "e.music.bar") == 2);
    CHECK(ev(h, "e.music.section").get<std::string>() == "main");
    const std::string log = ev(h, "log.join(' ')").get<std::string>();
    CHECK(log.find("ready:live") == 0);
    CHECK(log.find("beat:1.1@0") != std::string::npos);
    CHECK(log.find("beat:1.2@22050") != std::string::npos);      // half a second at 120 BPM
    CHECK(log.find("section:main@88200") != std::string::npos);  // the start of bar 2
}

TEST_CASE("entity.music: the same project gives the same frames on every run") {
    std::string first;
    for (int run_i = 0; run_i < 2; ++run_i) {
        TestHost h("music_determinism" + std::to_string(run_i));
        h.file("music/test.song.json", kSong);
        REQUIRE(h.start());
        ev(h, kSpawn);
        run(h, 200);
        const std::string log = ev(h, "log.join(' ')").get<std::string>();
        if (run_i == 0)
            first = log;
        else
            CHECK(log == first);
        CHECK(log.size() > 20);
    }
}

TEST_CASE("entity.music: intensity, sections, stingers and stop") {
    TestHost h("music_calls");
    h.file("music/test.song.json", kSong);
    REQUIRE(h.start());
    ev(h, kSpawn);
    run(h, 3);
    ev(h, "e.music.setIntensity(1, { quantize: 'none' });");
    run(h, 30);
    CHECK(num(h, "e.music.intensity") == 1);
    const Json gains = ev(h, "e.music.status.stemGains");
    REQUIRE(gains.is_array());
    CHECK(gains.size() == 2);  // the rhythm and harmony layers
    for (const Json& g : gains) CHECK(g.get<double>() == doctest::Approx(1.0).epsilon(0.01));

    // The call answers where the jump lands, and the status says the same until it does.
    const Json go = ev(h, "globalThis.go = e.music.goToSection('outro', { quantize: 'bar', fade: 0.1 }); go");
    REQUIRE(go.is_object());
    CHECK(go["quantize"] == "bar");
    REQUIRE(go["frame"].is_number());
    CHECK(go["time"].get<double>() == doctest::Approx(go["frame"].get<double>() / 44100.0));
    CHECK(num(h, "e.music.status.pending") == 1);
    CHECK(ev(h, "e.music.pendingSong").get<std::string>() == "music/test.song.json");
    CHECK(ev(h, "e.music.pendingSection").get<std::string>() == "outro");
    CHECK(num(h, "e.music.pendingAt") == go["frame"].get<double>());
    CHECK(num(h, "e.music.appliedIntensity") == doctest::Approx(1.0));
    CHECK(num(h, "e.music.requestedIntensity") == doctest::Approx(1.0));
    run(h, 130);  // past the end of bar 1, at 2 s
    CHECK(ev(h, "e.music.section").get<std::string>() == "outro");
    CHECK(num(h, "e.music.status.pending") == 0);
    CHECK(ev(h, "e.music.pendingSong").is_null());
    CHECK(ev(h, "e.music.pendingAt").is_null());

    ev(h, "e.music.playStinger({ section: 'intro', quantize: 'beat', duck: 0.5 });");
    CHECK(num(h, "e.music.status.pending") >= 1);
    run(h, 60);
    CHECK(ev(h, "e.music.playing").get<bool>());

    ev(h, "e.music.stop({ fade: 0.1 });");
    CHECK_FALSE(ev(h, "e.music.component.playing").get<bool>());
    run(h, 30);
    CHECK_FALSE(ev(h, "e.music.playing").get<bool>());
}

TEST_CASE("entity.music: a call that cannot be made teaches") {
    TestHost h("music_errors");
    h.file("music/test.song.json", kSong);
    REQUIRE(h.start());
    ev(h, kSpawn);
    run(h, 3);
    std::string err = ev_err(h, "e.music.goToSection('boss')");
    CHECK(err.find("boss") != std::string::npos);
    CHECK(err.find("intro") != std::string::npos);  // the sections it has
    err = ev_err(h, "e.music.setIntensity('loud')");
    CHECK(err.find("expects a number") != std::string::npos);
    err = ev_err(h, "e.music.goToSection('main', { quantise: 'bar' })");
    CHECK(err.find("did you mean 'quantize'") != std::string::npos);
    err = ev_err(h, "e.music.goToSection('main', { quantize: 'bars' })");
    CHECK(err.find("did you mean 'bar'") != std::string::npos);
    err = ev_err(h, "e.music.on('beet', () => {})");
    CHECK(err.find("did you mean 'beat'") != std::string::npos);
    err = ev_err(h, "e.music.playStinger({})");
    CHECK(err.find("playStinger") != std::string::npos);
    err = ev_err(h, "e.music.crossfadeTo('music/missing.song.json')");
    CHECK(err.find("does not exist") != std::string::npos);
}

TEST_CASE("entity.music: events of a player that is gone do not reach the next scene's script") {
    TestHost h("music_scene");
    h.file("music/test.song.json", kSong);
    REQUIRE(h.start());
    ev(h, kSpawn);
    run(h, 130);
    CHECK(ev(h, "log.length").get<double>() > 3);
    // The scene changes: the entity and its listeners go. Nothing from the old player is delivered to what the new scene registers.
    h.load_scene_json_now(Json::object({{"entities", Json::array()}}), "empty");
    ev(h, "globalThis.after = []; world.on('music.beat', (d) => after.push(d.id));");
    run(h, 90);
    CHECK(num(h, "after.length") == 0);
}
