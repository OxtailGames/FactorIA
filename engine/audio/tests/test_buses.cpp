// Project buses (factoria.json "audio.buses"), the voice list, the end of a voice and the listener zoom.
#include <doctest.h>

#include <cmath>

#include "audio_test_helpers.h"
#include "fa/audio/audio.h"
#include "fa/audio/snapshots.h"
#include "fa/scene/components.h"
#include "fa/scene/world.h"

using namespace fa;
using namespace audio_test;

namespace {

PlayParams on(const char* bus, bool loop = true) {
    PlayParams p;
    p.bus = bus;
    p.loop = loop;
    return p;
}

// The peak of one second of the sine clip (amplitude 0.5) with the voice on `bus`.
float level(Fixture& fx, const char* bus) {
    fx.audio.stop_all();
    fx.audio.start_recording();
    fx.audio.play("sounds/sine.wav", on(bus));
    fx.run(0.5);
    return fx.finish("out/bus.wav").peak(2000);
}

bool has(const std::vector<AudioIssue>& list, const std::string& pointer, const std::string& text) {
    for (const AudioIssue& i : list)
        if (i.pointer == pointer && i.message.find(text) != std::string::npos) return true;
    return false;
}

}  // namespace

TEST_CASE("buses: a project bus scales the voices on it and its parent scales it") {
    Fixture fx;
    fx.audio.set_buses({{"ambience", "sfx"}, {"birds", "ambience"}, {"voiceover", "master"}});
    CHECK(fx.audio.bus_names() == std::vector<std::string>{"sfx", "music", "ui", "master", "ambience", "birds", "voiceover"});
    CHECK(level(fx, "ambience") == doctest::Approx(0.5f).epsilon(0.03));
    fx.audio.set_bus_volume("ambience", 0.5f);
    CHECK(fx.audio.bus_volume("ambience") == 0.5f);
    CHECK(level(fx, "ambience") == doctest::Approx(0.25f).epsilon(0.03));
    CHECK(level(fx, "sfx") == doctest::Approx(0.5f).epsilon(0.03));  // the child does not scale its parent
    fx.audio.set_bus_volume("sfx", 0.5f);                            // the parent scales the child
    CHECK(level(fx, "ambience") == doctest::Approx(0.125f).epsilon(0.05));
    fx.audio.set_bus_volume("birds", 0.5f);                          // a grandchild: birds x ambience x sfx
    CHECK(level(fx, "birds") == doctest::Approx(0.0625f).epsilon(0.08));
    CHECK(level(fx, "voiceover") == doctest::Approx(0.5f).epsilon(0.03));  // under the master, not under sfx
    fx.audio.set_bus_volume("master", 0.5f);
    CHECK(level(fx, "voiceover") == doctest::Approx(0.25f).epsilon(0.03));
    CHECK(fx.audio.stats()["busParents"]["birds"] == "ambience");
    CHECK(fx.audio.stats()["buses"]["birds"] == 0.5);
}

TEST_CASE("buses: effects and ducking take the project names, a parent's effect covers the buses under it") {
    Fixture fx;
    write_sine_wav(fx.dir / "sounds/hi.wav", 1.0, 8000.0, 0.5);
    fx.audio.set_buses({{"ambience", "sfx"}});
    // A low-pass on the parent removes a high tone played on the child.
    REQUIRE(fx.audio.set_bus_lowpass("sfx", 300.0f).ok());
    fx.audio.start_recording();
    fx.audio.play("sounds/hi.wav", on("ambience"));
    fx.run(0.5);
    CHECK(fx.finish("out/lp.wav").peak(4000) < 0.05f);
    REQUIRE(fx.audio.set_bus_lowpass("sfx", 0.0f).ok());
    fx.audio.stop_all();
    // A low-pass on the child itself.
    REQUIRE(fx.audio.set_bus_lowpass("ambience", 300.0f).ok());
    CHECK(fx.audio.bus_state("ambience")["lowpass"] == 300.0);
    // Ducking: music goes down while the ambience bus plays.
    REQUIRE(fx.audio.set_bus_lowpass("ambience", 0.0f).ok());
    DuckSettings d;
    d.by = "ambience";
    d.amount = 1.0f;
    d.attack = 0.0f;
    d.release = 0.05f;
    REQUIRE(fx.audio.set_bus_duck("music", d).ok());
    CHECK(fx.audio.bus_state("music")["duck"]["by"] == "ambience");
    fx.audio.start_recording();
    fx.audio.play("sounds/sine.wav", on("music"));
    fx.run(0.3);
    CHECK(fx.finish("out/duck1.wav").peak(8000) > 0.4f);
    fx.audio.start_recording();
    fx.audio.play("sounds/hi.wav", on("ambience"));
    fx.run(0.5);
    Recording r = fx.finish("out/duck2.wav");
    // The ambience tone (8 kHz) is heard, the 440 Hz music is ducked to silence: a ducked music leaves only the 8 kHz sine.
    CHECK(r.peak(8000) == doctest::Approx(0.5f).epsilon(0.05));
    // Unknown names teach.
    auto bad = fx.audio.set_bus_lowpass("ambiance", 300.0f);
    REQUIRE_FALSE(bad.ok());
    CHECK(bad.error().message.find("Did you mean 'ambience'") != std::string::npos);
    CHECK(fx.audio.bus_volume("ambiance") < 0.0f);
    CHECK_FALSE(fx.audio.set_bus_duck("master", d).ok());
    // A snapshot can name a project bus.
    AudioSnapshots snaps;
    snaps["quiet"].buses["ambience"].volume = 0.25f;
    fx.audio.set_snapshots(snaps);
    REQUIRE(fx.audio.apply_snapshot("quiet", 0.0f).ok());
    CHECK(fx.audio.bus_state("ambience")["snapshotVolume"] == 0.25);
    fx.audio.reset_bus_effects();
    CHECK(fx.audio.bus_state("ambience")["snapshotVolume"] == 1.0);
}

TEST_CASE("buses: set_buses keeps what stays, sends voices of a removed bus to sfx, skips a bad parent") {
    Fixture fx;
    fx.audio.set_buses({{"ambience", "sfx"}, {"extra", "master"}});
    fx.audio.set_bus_volume("ambience", 0.3f);
    const VoiceId v = fx.audio.play("sounds/sine.wav", on("extra"));
    REQUIRE(v != 0);
    CHECK(fx.audio.active_voices()[0]["bus"] == "extra");
    fx.audio.set_buses({{"ambience", "sfx"}, {"orphan", "nowhere"}});
    CHECK(fx.audio.bus_volume("ambience") == doctest::Approx(0.3f));
    CHECK(fx.audio.bus_volume("extra") < 0.0f);
    CHECK(fx.audio.bus_volume("orphan") < 0.0f);
    CHECK(fx.audio.active_voices()[0]["bus"] == "sfx");
    // A child declared before its parent works.
    fx.audio.set_buses({{"leaf", "branch"}, {"branch", "music"}});
    CHECK(fx.audio.bus_names().back() == "leaf");
    CHECK(fx.audio.stats()["busParents"]["leaf"] == "branch");
    // A voice on an unknown bus plays on sfx, and the log says sfx.
    fx.audio.clear_play_log();
    fx.audio.play("sounds/sine.wav", on("nonexistent"));
    CHECK(fx.audio.play_log().back().bus == "sfx");
}

TEST_CASE("voices: activeVoices lists what plays, and a voice's end is reported once") {
    Fixture fx;
    fx.audio.set_buses({{"ambience", "sfx"}});
    CHECK(fx.audio.active_voices().empty());
    PlayParams loopParams = on("ambience");
    loopParams.volume = 0.4f;
    const VoiceId bed = fx.audio.play("sounds/sine.wav", loopParams);
    PlayParams once;
    once.notifyEnd = true;
    const VoiceId shot = fx.audio.play("sounds/sine.wav", once);  // 1 s
    const Json voices = fx.audio.active_voices();
    REQUIRE(voices.size() == 2);
    CHECK(voices[0]["id"] == bed);
    CHECK(voices[0]["path"] == "sounds/sine.wav");
    CHECK(voices[0]["bus"] == "ambience");
    CHECK(voices[0]["loop"] == true);
    CHECK(voices[0]["volume"].get<float>() == doctest::Approx(0.4f));
    CHECK(voices[1]["id"] == shot);
    CHECK(voices[1]["bus"] == "sfx");
    fx.run(0.5);
    CHECK(fx.audio.take_ended_voices().empty());
    fx.run(0.7);
    CHECK(fx.audio.take_ended_voices() == std::vector<VoiceId>{shot});
    CHECK(fx.audio.take_ended_voices().empty());  // once
    CHECK(fx.audio.active_voices().size() == 1);
    CHECK_FALSE(fx.audio.is_playing(shot));

    // stop() ends a voice too; a voice played without notifyEnd is never listed; stop_all and a scene load drop the list.
    const VoiceId a = fx.audio.play("sounds/sine.wav", [] { PlayParams p; p.loop = true; p.notifyEnd = true; return p; }());
    fx.audio.stop(a);
    CHECK(fx.audio.take_ended_voices() == std::vector<VoiceId>{a});
    fx.audio.stop(bed);
    CHECK(fx.audio.take_ended_voices().empty());
    PlayParams n = once;
    fx.audio.play("sounds/sine.wav", n);
    fx.audio.stop_all();
    CHECK(fx.audio.take_ended_voices().empty());
    fx.audio.play("sounds/sine.wav", n);
    fx.run(1.2);  // it ended, nobody asked yet
    fx.audio.on_scene_load();
    CHECK(fx.audio.take_ended_voices().empty());  // the scene that wanted to know is gone
}

TEST_CASE("voices: setVoiceVolume is in the play log, with the target, the fade and the voice") {
    Fixture fx;
    const VoiceId v = fx.audio.play("sounds/sine.wav", on("sfx"));
    fx.audio.clear_play_log();
    fx.audio.set_voice_volume(v, 0.25f, 2.0f);
    fx.audio.set_voice_volume(9999, 0.5f);  // not a voice: nothing logged
    const std::vector<AudioEvent> log = fx.audio.play_log();
    REQUIRE(log.size() == 1);
    CHECK(log[0].kind == "setVoiceVolume");
    CHECK(log[0].voice == v);
    CHECK(log[0].path == "sounds/sine.wav");
    CHECK(log[0].volume == 0.25f);
    CHECK(log[0].fade == 2.0f);
    CHECK(log[0].bus == "sfx");
    CHECK(fx.audio.active_voices()[0]["volume"].get<float>() == doctest::Approx(0.25f));
    // The play entry names its voice.
    fx.audio.clear_play_log();
    const VoiceId w = fx.audio.play("sounds/sine.wav");
    CHECK(fx.audio.play_log()[0].kind == "play");
    CHECK(fx.audio.play_log()[0].voice == w);
    CHECK(fx.audio.play_log()[0].to_json()["voice"] == w);
}

TEST_CASE("listener zoom: a zoom of 2 doubles the distance a positional sound is heard at") {
    Fixture fx;
    World world;
    Entity ear = world.create("ear", "ear");
    AudioListener& listener = world.add<AudioListener>(ear);
    Entity s = world.create("src", "src");
    AudioSource& src = world.add<AudioSource>(s);
    src.clip = "sounds/sine.wav";
    src.playOnStart = true;
    src.loop = true;
    src.spatial = true;
    src.range = 800.0f;
    const auto measure = [&](float x) {
        world.get<Transform>(s)->position = {x, 0, 0};
        fx.audio.start_recording();
        for (int i = 0; i < 12; ++i) { fx.audio.update(world, 1.0f / 60.0f); fx.audio.advance_null_device(1.0 / 60.0); }
        return fx.finish("out/zoom.wav");
    };
    CHECK(measure(400).peak_r() == doctest::Approx(0.25f).epsilon(0.1));       // zoom 1: half the range, half the volume
    CHECK(measure(900).peak() < 0.001f);                                       // beyond the range
    listener.zoom = 2.0f;
    CHECK(measure(400).peak_r() == doctest::Approx(0.375f).epsilon(0.1));      // 1 - 400 / 1600
    CHECK(measure(800).peak_r() == doctest::Approx(0.25f).epsilon(0.1));       // the old range now reaches half way
    CHECK(measure(1500).peak() > 0.02f);                                       // heard past the old range
    CHECK(measure(1700).peak() < 0.001f);                                      // silent at 2 x range
    listener.zoom = 0.5f;                                                      // zoomed in: half the reach
    CHECK(measure(300).peak_r() == doctest::Approx(0.125f).epsilon(0.15));     // 1 - 300 / 400
    CHECK(measure(500).peak() < 0.001f);
}

TEST_CASE("audio settings: buses parse, and every mistake names its place and a fix") {
    AudioSettingsParse p = parse_audio_settings(Json::parse(R"({"buses": {
        "birds": {"parent": "ambience"}, "ambience": {"parent": "sfx"}, "voiceover": {}},
        "snapshots": {"night": {"buses": {"ambience": {"volume": 0.5, "duck": {"by": "voiceover"}}}}}})"));
    REQUIRE(p.ok());
    CHECK(p.warnings.empty());
    REQUIRE(p.buses.size() == 3);
    CHECK(p.buses[0].name == "birds");  // in the order of the file, a parent may come after its child
    CHECK(p.buses[0].parent == "ambience");
    CHECK(p.buses[1].parent == "sfx");
    CHECK(p.buses[2].name == "voiceover");
    CHECK(p.buses[2].parent == "master");
    CHECK(p.snapshots["night"].buses.at("ambience").duck->by == "voiceover");

    p = parse_audio_settings(Json::parse(R"({"buses": {
        "sfx": {}, "Wind": {}, "a": {"parent": "ambiance"}, "ambience": {"parent": "sfx"}, "b": {"parent": "c"}, "c": {"parent": "b"},
        "d": {"parent": 3}, "e": {"parentt": "sfx"}, "f": {"parent": "f"}, "g": 4},
        "snapshots": {"s": {"buses": {"ambiance": {}, "music": {"duck": {"by": "ambiense"}}}}}})"));
    CHECK_FALSE(p.ok());
    CHECK(has(p.issues, "/audio/buses/sfx", "built-in"));
    CHECK(has(p.issues, "/audio/buses/Wind", "not a bus name"));
    CHECK(has(p.issues, "/audio/buses/a/parent", "Did you mean 'ambience'"));
    CHECK((has(p.issues, "/audio/buses/b/parent", "loop") || has(p.issues, "/audio/buses/c/parent", "loop")));
    CHECK(has(p.issues, "/audio/buses/d/parent", "expected the name of a bus"));
    CHECK(has(p.issues, "/audio/buses/f/parent", "its own parent"));
    CHECK(has(p.issues, "/audio/buses/g", "expected an object"));
    CHECK(has(p.warnings, "/audio/buses/e/parentt", "Did you mean 'parent'"));
    CHECK(has(p.issues, "/audio/snapshots/s/buses/ambiance", "Did you mean 'ambience'"));
    CHECK(has(p.issues, "/audio/snapshots/s/buses/music/duck/by", "Did you mean 'ambience'"));
    CHECK_FALSE(parse_audio_settings(Json::parse(R"({"buses": [1]})")).ok());
}
