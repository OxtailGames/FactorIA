#include <doctest.h>

#include <set>

#include "../src/audio_testing.h"
#include "audio_test_helpers.h"
#include "fa/audio/audio.h"
#include "fa/core/asset_manifest.h"
#include "fa/core/fs.h"
#include "fa/core/log.h"
#include "fa/scene/feel.h"

using namespace fa;
using namespace audio_test;

TEST_CASE("audio: play a WAV, record it, check length and peak") {
    Fixture fx;
    CHECK(fx.audio.load("sounds/sine.wav"));
    fx.audio.start_recording();
    VoiceId v = fx.audio.play("sounds/sine.wav");
    REQUIRE(v != 0);
    CHECK(fx.audio.is_playing(v));
    fx.run(1.5);
    CHECK_FALSE(fx.audio.is_playing(v));
    Recording rec = fx.finish();
    CHECK(rec.frames() == 66150);  // exactly the advanced time
    CHECK(rec.peak() == doctest::Approx(0.5f).epsilon(0.02));
    CHECK(rec.sound_end() == doctest::Approx(44100.0).epsilon(0.002));
    CHECK(rec.peak(50000) < 0.001f);  // silent after the clip
    Json st = fx.audio.stats();
    CHECK(st["loadedClips"] == 1);
    CHECK(st["activeVoices"] == 0);
}

TEST_CASE("audio: pitch changes duration, loop keeps playing, stop silences") {
    Fixture fx;
    fx.audio.start_recording();
    PlayParams fast;
    fast.pitch = 2.0f;
    fx.audio.play("sounds/sine.wav", fast);
    fx.run(1.0);
    Recording rec = fx.finish("out/pitch.wav");
    CHECK(rec.sound_end() == doctest::Approx(22050.0).epsilon(0.01));
    CHECK(rec.peak() == doctest::Approx(0.5f).epsilon(0.03));

    fx.audio.start_recording();
    PlayParams lp;
    lp.loop = true;
    VoiceId v = fx.audio.play("sounds/sine.wav", lp);
    fx.run(3.0);
    CHECK(fx.audio.is_playing(v));
    Recording loop = fx.finish("out/loop.wav");
    CHECK(loop.peak(loop.frames() - 4000) > 0.4f);

    fx.audio.start_recording();
    fx.run(0.1);
    fx.audio.stop(v);
    CHECK_FALSE(fx.audio.is_playing(v));
    fx.run(0.1);
    Recording stopped = fx.finish("out/stop.wav");
    CHECK(stopped.peak(0, 4400) > 0.4f);
    CHECK(stopped.peak(4410 + 800) < 0.0001f);
}

TEST_CASE("audio: buses, master volume, pan and fades") {
    Fixture fx;
    auto measure = [&](const PlayParams& p, double secs = 0.2) {
        fx.audio.stop_all();
        fx.audio.start_recording();
        fx.audio.play("sounds/sine.wav", p);
        fx.run(secs);
        return fx.finish("out/m.wav");
    };
    PlayParams p;
    CHECK(measure(p).peak() == doctest::Approx(0.5f).epsilon(0.03));
    CHECK(fx.audio.bus_volume("music") == 1.0f);
    fx.audio.set_bus_volume("sfx", 0.5f);
    CHECK(fx.audio.bus_volume("sfx") == 0.5f);
    CHECK(fx.audio.bus_volume("nope") == -1.0f);
    CHECK(measure(p).peak(1000) ==
          doctest::Approx(0.25f).epsilon(0.03));  // a bus volume ramps over about 10 ms: measure after it
    PlayParams ui;
    ui.bus = "ui";
    CHECK(measure(ui).peak() == doctest::Approx(0.5f).epsilon(0.03));
    fx.audio.set_bus_volume("sfx", 1.0f);
    fx.audio.set_master_volume(0.5f);
    CHECK(fx.audio.bus_volume("master") == 0.5f);
    CHECK(measure(p).peak(1000) == doctest::Approx(0.25f).epsilon(0.03));
    fx.audio.set_master_volume(1.0f);
    PlayParams left;
    left.pan = -1.0f;
    Recording rl = measure(left);
    CHECK(rl.peak_l() == doctest::Approx(0.5f).epsilon(0.03));
    CHECK(rl.peak_r() < 0.001f);
    PlayParams right;
    right.pan = 1.0f;
    Recording rr = measure(right);
    CHECK(rr.peak_l() < 0.001f);
    CHECK(rr.peak_r() > 0.4f);
    PlayParams half;
    half.volume = 0.5f;
    CHECK(measure(half).peak() == doctest::Approx(0.25f).epsilon(0.03));

    // music with fade-in: starts quiet, reaches full level
    fx.audio.stop_all();
    fx.audio.start_recording();
    fx.audio.play_music("sounds/sine.wav", 1.0f, 0.5f);
    fx.run(1.0);
    Recording fade = fx.finish("out/fade.wav");
    CHECK(fade.peak(0, 2000) < 0.1f);
    CHECK(fade.peak(fade.frames() - 4000) > 0.45f);
    CHECK(fx.audio.stats()["music"] == "sounds/sine.wav");
    fx.audio.stop_music(0.25f);
    fx.audio.start_recording();
    fx.run(1.0);
    Recording out = fx.finish("out/fadeout.wav");
    CHECK(out.peak(0, 1000) > 0.2f);
    CHECK(out.peak(out.frames() - 4000) < 0.0001f);
    CHECK(fx.audio.stats()["activeVoices"] == 0);
}

TEST_CASE("audio: missing and unsupported clips fail with one helpful error") {
    Fixture fx;
    std::size_t before = error_count();
    CHECK_FALSE(fx.audio.load("sounds/sine2.wav"));
    CHECK(fx.audio.play("sounds/sine2.wav") == 0);
    CHECK(error_count() == before + 1);
    auto logs = recent_logs(5, LogLevel::Error);
    REQUIRE_FALSE(logs.empty());
    CHECK(logs.back().message.find("sounds/sine2.wav") != std::string::npos);
    CHECK(logs.back().message.find("sounds/sine.wav") != std::string::npos);  // did-you-mean

    REQUIRE(fs::write_text("sounds/notes.txt", "hello").ok());
    CHECK_FALSE(fx.audio.load("sounds/notes.txt"));
    logs = recent_logs(1, LogLevel::Error);
    CHECK(logs.back().message.find(".wav") != std::string::npos);
    REQUIRE(fs::write_text("sounds/bad.wav", "not a wav file at all").ok());
    CHECK_FALSE(fx.audio.load("sounds/bad.wav"));
}

TEST_CASE("audio: non-44100 clips are resampled on load") {
    Fixture fx;
    write_sine_wav(fx.dir / "sounds/low.wav", 1.0, 220.0, 0.5, 22050);
    fx.audio.start_recording();
    fx.audio.play("sounds/low.wav");
    fx.run(1.5);
    Recording rec = fx.finish();
    CHECK(rec.sound_end() == doctest::Approx(44100.0).epsilon(0.005));
    CHECK(rec.peak() == doctest::Approx(0.5f).epsilon(0.03));
}

TEST_CASE("audio: reload_clip swaps the data of a loaded clip") {
    Fixture fx;
    CHECK(fx.audio.load("sounds/sine.wav"));
    write_sine_wav(fx.dir / "sounds/sine.wav", 0.5);
    fx.audio.reload_clip("sounds/sine.wav");
    fx.audio.start_recording();
    fx.audio.play("sounds/sine.wav");
    fx.run(1.0);
    CHECK(fx.finish().sound_end() == doctest::Approx(22050.0).epsilon(0.01));
}

TEST_CASE("audio: reload_clip moves a playing voice into the new clip's loop points, and ends one past the new end") {
    constexpr double kRate = 44100.0;
    Fixture fx;
    auto set_loop = [](double start, double end) {
        REQUIRE(assets::update_entry("sounds/sine.wav", [&](Json& e) {
                    e["import"]["loopStart"] = start;
                    e["import"]["loopEnd"] = end;
                }).ok());
    };
    set_loop(0.1, 1.0);
    PlayParams lp;
    lp.loop = true;
    const VoiceId looping = fx.audio.play("sounds/sine.wav", lp);
    const VoiceId once = fx.audio.play("sounds/sine.wav");
    REQUIRE(looping != 0);
    REQUIRE(once != 0);
    fx.run(0.8);
    CHECK(AudioTestAccess::voice_position(fx.audio, looping) == doctest::Approx(0.8 * kRate).epsilon(0.02));

    // The file is now half as long and loops inside 0.1..0.4 s: the voices were at 0.8 s.
    write_sine_wav(fx.dir / "sounds/sine.wav", 0.5);
    set_loop(0.1, 0.4);
    fx.audio.reload_clip("sounds/sine.wav");
    const double pos =
        AudioTestAccess::voice_position(fx.audio, looping);  // the null device applies the command at once
    CHECK(pos >= 0.1 * kRate - 1.0);
    CHECK(pos < 0.4 * kRate);
    // A voice that does not loop and was past the new clip's end is put at its end.
    const double pos1 = AudioTestAccess::voice_position(fx.audio, once);
    CHECK(pos1 == doctest::Approx(0.5 * kRate));  // it ends in the next block
    fx.run(0.1);
    CHECK_FALSE(fx.audio.is_playing(once));
    CHECK(fx.audio.is_playing(looping));
}

TEST_CASE("audio: a feel sound plays on its bus with the entity that asked for it; a clip that cannot play is not "
          "tried again in the scene") {
    Fixture fx;
    World world;
    const Entity hero = world.create("hero", "hero");
    SoundOptions good;
    good.path = "sounds/sine.wav";
    REQUIRE(feel_sound(world, hero, good).ok());
    fx.audio.update(world, 1.0f / 60.0f);
    std::vector<AudioEvent> log = fx.audio.play_log();
    REQUIRE(log.size() == 1);
    CHECK(log[0].ok);
    CHECK(log[0].source == world.id_of(hero));

    SoundOptions missing;
    missing.path = "sounds/not_there.wav";
    for (int i = 0; i < 3; ++i) {
        REQUIRE(feel_sound(world, hero, missing).ok());
        fx.audio.update(world, 1.0f / 60.0f);
    }
    log = fx.audio.play_log();
    int failed = 0;
    for (const AudioEvent& ev : log) failed += ev.ok ? 0 : 1;
    CHECK(failed == 1);  // the first try is logged; the other two never reach the decoder
    CHECK(world.feel().failedSounds.count("sounds/not_there.wav") == 1);

    // a new scene tries again (the file may exist by now)
    world.clear();
    REQUIRE(feel_sound(world, kNullEntity, missing).ok());
    fx.audio.update(world, 1.0f / 60.0f);
    failed = 0;
    for (const AudioEvent& ev : fx.audio.play_log()) failed += ev.ok ? 0 : 1;
    CHECK(failed == 2);
}

TEST_CASE("audio: AudioSource playOnStart through a World") {
    Fixture fx;
    World world;
    Entity e = world.create("sfx", "sfx");
    AudioSource& src = world.add<AudioSource>(e);
    src.clip = "sounds/sine.wav";
    src.playOnStart = true;
    fx.audio.start_recording();
    fx.audio.update(world, 1.0f / 60.0f);
    CHECK(world.get<AudioSource>(e)->playing);
    CHECK(fx.audio.stats()["activeVoices"] == 1);
    for (int i = 0; i < 30; ++i) {
        fx.audio.update(world, 1.0f / 60.0f);
        fx.audio.advance_null_device(1.0 / 60.0);
    }
    CHECK(world.get<AudioSource>(e)->playing);
    for (int i = 0; i < 60; ++i) {
        fx.audio.update(world, 1.0f / 60.0f);
        fx.audio.advance_null_device(1.0 / 60.0);
    }
    // non-looping clip ended -> engine cleared `playing`, and it does not restart
    CHECK_FALSE(world.get<AudioSource>(e)->playing);
    fx.audio.update(world, 1.0f / 60.0f);
    CHECK(fx.audio.stats()["activeVoices"] == 0);
    Recording rec = fx.finish();
    CHECK(rec.peak() == doctest::Approx(0.5f).epsilon(0.03));

    // scripts start it again by setting playing = true, and stop it with false
    world.get<AudioSource>(e)->playing = true;
    fx.audio.update(world, 1.0f / 60.0f);
    CHECK(fx.audio.stats()["activeVoices"] == 1);
    world.get<AudioSource>(e)->playing = false;
    fx.audio.update(world, 1.0f / 60.0f);
    CHECK(fx.audio.stats()["activeVoices"] == 0);

    // destroying the entity stops its sound
    world.get<AudioSource>(e)->playing = true;
    fx.audio.update(world, 1.0f / 60.0f);
    CHECK(fx.audio.stats()["activeVoices"] == 1);
    world.destroy(e);
    world.flush();
    fx.audio.update(world, 1.0f / 60.0f);
    CHECK(fx.audio.stats()["activeVoices"] == 0);
}

TEST_CASE("audio: spatial sources pan and attenuate relative to the listener") {
    Fixture fx;
    World world;
    Entity listener = world.create("ear", "ear");
    world.add<AudioListener>(listener);
    Entity s = world.create("src", "src");
    AudioSource& src = world.add<AudioSource>(s);
    src.clip = "sounds/sine.wav";
    src.playOnStart = true;
    src.loop = true;
    src.spatial = true;
    src.range = 800.0f;

    auto measure = [&](Vec3 pos) {
        world.get<Transform>(s)->position = pos;
        fx.audio.start_recording();
        for (int i = 0; i < 12; ++i) {
            fx.audio.update(world, 1.0f / 60.0f);
            fx.audio.advance_null_device(1.0 / 60.0);
        }
        return fx.finish("out/sp.wav");
    };
    Recording near = measure({0, 0, 0});
    CHECK(near.peak_l() == doctest::Approx(0.5f).epsilon(0.05));
    CHECK(near.peak_r() == doctest::Approx(0.5f).epsilon(0.05));
    Recording right = measure({400, 0, 0});  // half range: half volume, panned fully right
    CHECK(right.peak_r() == doctest::Approx(0.25f).epsilon(0.1));
    CHECK(right.peak_l() < 0.01f);
    Recording far = measure({900, 0, 0});  // beyond range: silent
    CHECK(far.peak() < 0.001f);
}

TEST_CASE("audio: play_at is heard from a place like a spatial AudioSource") {
    Fixture fx;
    World world;
    Entity listener = world.create("ear", "ear");
    world.add<AudioListener>(listener);
    PlayParams pp;
    pp.volume = 0.8f;
    auto last = [&]() { return fx.audio.play_log().back(); };

    VoiceId near = fx.audio.play_at(world, "sounds/sine.wav", pp, {0, 0, 0}, 100.0f);
    CHECK(near != 0);
    CHECK(last().volume == doctest::Approx(0.8f));
    CHECK(last().pan == doctest::Approx(0.0f));
    VoiceId half = fx.audio.play_at(world, "sounds/sine.wav", pp, {50, 0, 0}, 100.0f);  // half the range, to the right
    CHECK(half != 0);
    CHECK(last().volume == doctest::Approx(0.4f));
    CHECK(last().pan == doctest::Approx(1.0f));
    fx.audio.play_at(world, "sounds/sine.wav", pp, {-25, 0, 0}, 100.0f);
    CHECK(last().volume == doctest::Approx(0.6f));
    CHECK(last().pan == doctest::Approx(-0.5f));
    const std::size_t logged = fx.audio.play_log().size();
    CHECK(fx.audio.play_at(world, "sounds/sine.wav", pp, {100, 0, 0}, 100.0f) == 0);  // at the range: silent, no voice
    CHECK(fx.audio.play_log().size() == logged);
    // the listener's zoom stretches the reach
    world.get<AudioListener>(listener)->zoom = 2.0f;
    fx.audio.play_at(world, "sounds/sine.wav", pp, {100, 0, 0}, 100.0f);
    CHECK(last().volume == doctest::Approx(0.4f));
    // no listener: plays as play() does
    World empty;
    fx.audio.play_at(empty, "sounds/sine.wav", pp, {900, 0, 0}, 100.0f);
    CHECK(last().volume == doctest::Approx(0.8f));
}

TEST_CASE("audio: rolloff curves") {
    // linear: the classic 1 - d/range by default, from refDistance with one
    CHECK(audio_spatial_gain(AudioRolloff::Linear, 25, 100) == doctest::Approx(0.75f));
    CHECK(audio_spatial_gain(AudioRolloff::Linear, 100, 100) == 0.0f);
    CHECK(audio_spatial_gain(AudioRolloff::Linear, 10, 100, 20) == doctest::Approx(1.0f));
    CHECK(audio_spatial_gain(AudioRolloff::Linear, 60, 100, 20) == doctest::Approx(0.5f));
    CHECK(audio_spatial_gain(AudioRolloff::Linear, 60, 100, 20, 0.5f) == doctest::Approx(0.75f));
    // inverse: r / (r + k (d - r)); refDistance 0 = range / 20
    CHECK(audio_spatial_gain(AudioRolloff::Inverse, 3, 100, 10) == doctest::Approx(1.0f));
    CHECK(audio_spatial_gain(AudioRolloff::Inverse, 20, 100, 10) == doctest::Approx(0.5f));
    CHECK(audio_spatial_gain(AudioRolloff::Inverse, 20, 100, 10, 2.0f) == doctest::Approx(1.0f / 3.0f));
    CHECK(audio_spatial_gain(AudioRolloff::Inverse, 10, 100) == doctest::Approx(0.5f));  // r = 100 / 20 = 5
    CHECK(audio_spatial_gain(AudioRolloff::Inverse, 100, 100, 10) == 0.0f);              // cut at the range
    // exponential: (d / r) ^ -k
    CHECK(audio_spatial_gain(AudioRolloff::Exponential, 20, 100, 10) == doctest::Approx(0.5f));
    CHECK(audio_spatial_gain(AudioRolloff::Exponential, 20, 100, 10, 2.0f) == doctest::Approx(0.25f));
    CHECK(audio_spatial_gain(AudioRolloff::Exponential, 5, 100, 10, 2.0f) == doctest::Approx(1.0f));
    CHECK(audio_spatial_gain(AudioRolloff::Exponential, 150, 100, 10) == 0.0f);
    // exactly at the reach: 0 for the three; refDistance at or above the range holds at 99.9% of it
    for (AudioRolloff r : {AudioRolloff::Linear, AudioRolloff::Inverse, AudioRolloff::Exponential})
        CHECK(audio_spatial_gain(r, 100, 100, 10) == 0.0f);
    CHECK(audio_spatial_gain(AudioRolloff::Linear, 50, 100, 500) == doctest::Approx(1.0f));
    CHECK(audio_spatial_gain(AudioRolloff::Linear, 99.95f, 100, 500) == doctest::Approx(0.5f).epsilon(0.01));
    // a tiny refDistance with factor 0 stays at full volume
    CHECK(audio_spatial_gain(AudioRolloff::Inverse, 50, 100, 1e-8f, 0.0f) == doctest::Approx(1.0f));
}

TEST_CASE("audio: play_at and AudioSource use the same rolloff") {
    Fixture fx;
    World world;
    Entity listener = world.create("ear", "ear");
    world.add<AudioListener>(listener);
    struct Case {
        AudioRolloff r;
        float ref, k;
    };
    const Case cases[] = {{AudioRolloff::Linear, 0, 1},
                          {AudioRolloff::Linear, 20, 1},
                          {AudioRolloff::Inverse, 10, 1},
                          {AudioRolloff::Inverse, 0, 2},
                          {AudioRolloff::Exponential, 10, 1.5f}};
    for (const Case& c : cases) {
        PlayParams pp;
        pp.volume = 1.0f;
        fx.audio.play_at(world, "sounds/sine.wav", pp, {40, 0, 0}, 100.0f, c.r, c.ref, c.k);
        const float viaPlay = fx.audio.play_log().back().volume;
        CHECK(viaPlay == doctest::Approx(audio_spatial_gain(c.r, 40, 100, c.ref, c.k)));
        CHECK(viaPlay > 0.0f);

        World w2;
        Entity l2 = w2.create("ear", "ear");
        w2.add<AudioListener>(l2);
        Entity s = w2.create("src", "src");
        AudioSource& src = w2.add<AudioSource>(s);
        src.clip = "sounds/sine.wav";
        src.playOnStart = true;
        src.spatial = true;
        src.range = 100.0f;
        src.rolloff = c.r;
        src.refDistance = c.ref;
        src.rolloffFactor = c.k;
        w2.get<Transform>(s)->position = {40, 0, 0};
        const std::size_t before = fx.audio.play_log().size();
        for (int i = 0; i < 3; ++i) {
            fx.audio.update(w2, 1.0f / 60.0f);
            fx.audio.advance_null_device(1.0 / 60.0);
        }
        REQUIRE(fx.audio.play_log().size() == before + 1);
        CHECK(fx.audio.play_log().back().volume == doctest::Approx(viaPlay));
        fx.audio.update(world, 1.0f / 60.0f);  // back to the first World: the next w2 may reuse this one's address
    }
    // zoom != 1 with a refDistance: both stretch together and AudioSource agrees with play_at
    {
        world.get<AudioListener>(listener)->zoom = 2.0f;
        PlayParams pp;
        pp.volume = 1.0f;
        fx.audio.play_at(world, "sounds/sine.wav", pp, {60, 0, 0}, 100.0f, AudioRolloff::Inverse, 10.0f, 1.0f);
        const float viaPlay = fx.audio.play_log().back().volume;
        CHECK(viaPlay == doctest::Approx(audio_spatial_gain(AudioRolloff::Inverse, 60, 200, 20, 1.0f)));
        World w3;
        Entity l3 = w3.create("ear", "ear");
        w3.add<AudioListener>(l3).zoom = 2.0f;
        Entity s = w3.create("src", "src");
        AudioSource& src = w3.add<AudioSource>(s);
        src.clip = "sounds/sine.wav";
        src.playOnStart = true;
        src.spatial = true;
        src.range = 100.0f;
        src.rolloff = AudioRolloff::Inverse;
        src.refDistance = 10.0f;
        w3.get<Transform>(s)->position = {60, 0, 0};
        const std::size_t before = fx.audio.play_log().size();
        for (int i = 0; i < 3; ++i) {
            fx.audio.update(w3, 1.0f / 60.0f);
            fx.audio.advance_null_device(1.0 / 60.0);
        }
        REQUIRE(fx.audio.play_log().size() == before + 1);
        CHECK(fx.audio.play_log().back().volume == doctest::Approx(viaPlay));
        fx.audio.update(world, 1.0f / 60.0f);
        world.get<AudioListener>(listener)->zoom = 1.0f;
    }
    // a silent sound inside the range (muted listener) still gets an id; only out of range returns 0
    world.get<AudioListener>(listener)->volume = 0.0f;
    PlayParams pp;
    CHECK(fx.audio.play_at(world, "sounds/sine.wav", pp, {10, 0, 0}, 100.0f) != 0);
    CHECK(fx.audio.play_at(world, "sounds/sine.wav", pp, {500, 0, 0}, 100.0f) == 0);
}

TEST_CASE("audio: scene music starts when SceneSettings.music changes") {
    Fixture fx;
    World world;
    world.settings().music = "sounds/sine.wav";
    world.settings().musicVolume = 0.8f;
    fx.audio.update(world, 1.0f / 60.0f);
    CHECK(fx.audio.stats()["music"] == "sounds/sine.wav");
    fx.run(1.0);
    fx.audio.update(world, 1.0f / 60.0f);
    CHECK(fx.audio.stats()["activeVoices"] == 1);
    world.settings().music = "";
    fx.audio.update(world, 1.0f / 60.0f);
    fx.run(1.0);
    CHECK(fx.audio.stats()["activeVoices"] == 0);
}

TEST_CASE("audio: null device mixing is deterministic") {
    auto run = [] {
        Fixture fx;
        fx.audio.start_recording();
        PlayParams a;
        a.pitch = 1.37f;
        a.pan = 0.3f;
        PlayParams b;
        b.loop = true;
        b.pitch = 0.81f;
        b.volume = 0.4f;
        fx.audio.play("sounds/sine.wav", a);
        fx.audio.play("sounds/sine.wav", b);
        fx.run(2.0);
        Recording r = fx.finish();
        return r;
    };
    Recording a = run(), b = run();
    REQUIRE(a.frames() == b.frames());
    CHECK(std::memcmp(a.l.data(), b.l.data(), a.l.size() * sizeof(float)) == 0);
    CHECK(std::memcmp(a.r.data(), b.r.data(), a.r.size() * sizeof(float)) == 0);
}

TEST_CASE("audio: the play log records every play request with the clock world's frame") {
    Fixture fx;
    World world;
    for (int i = 0; i < 3; ++i) world.advance_clock(1.0 / 60.0);
    fx.audio.set_clock(&world);

    PlayParams ui;
    ui.volume = 0.5f;
    ui.bus = "ui";
    CHECK(fx.audio.play("sounds/sine.wav", ui) != 0);
    CHECK(fx.audio.play("sounds/nope.wav") == 0);  // missing clip: logged with ok = false
    fx.audio.play_music("./sounds/sine.wav", 0.4f, 0.0f);
    fx.audio.play_music("sounds/sine.wav", 0.6f, 0.0f);  // same track again: a retune, not a new play

    std::vector<AudioEvent> log = fx.audio.play_log();
    REQUIRE(log.size() == 3);
    CHECK(log[0].seq == 1);
    CHECK(log[0].frame == 3);
    CHECK(log[0].time == doctest::Approx(3.0 / 60.0));
    CHECK(log[0].path == "sounds/sine.wav");
    CHECK(log[0].bus == "ui");
    CHECK(log[0].volume == doctest::Approx(0.5f));
    CHECK(log[0].ok);
    CHECK_FALSE(log[0].music);
    CHECK(log[1].path == "sounds/nope.wav");
    CHECK_FALSE(log[1].ok);
    CHECK(log[2].path == "sounds/sine.wav");  // normalized
    CHECK(log[2].music);
    CHECK(log[2].loop);
    CHECK(log[2].bus == "music");
    CHECK(fx.audio.play_log(2).size() == 1);  // only entries after seq 2

    // AudioSource components are logged with their entity id as `source`
    Entity e = world.create("coin_sfx", "coin_sfx");
    AudioSource& src = world.add<AudioSource>(e);
    src.clip = "sounds/sine.wav";
    src.playOnStart = true;
    fx.audio.update(world, 1.0f / 60.0f);
    log = fx.audio.play_log(3);
    REQUIRE(log.size() == 1);
    CHECK(log[0].source == "coin_sfx");
    Json j = log[0].to_json();
    CHECK(j["source"] == "coin_sfx");
    CHECK(j["seq"] == 4);

    fx.audio.clear_play_log();
    CHECK(fx.audio.play_log().empty());
    fx.audio.play("sounds/sine.wav");
    CHECK(fx.audio.play_log().at(0).seq == 5);  // seq keeps increasing after a clear
}

TEST_CASE("audio: a scene load restarts the scene's music, even the same track") {
    Fixture fx;
    World world;
    world.settings().music = "sounds/sine.wav";
    fx.audio.update(world, 1.0f / 60.0f);
    fx.run(1.0);
    CHECK(fx.audio.stats()["activeVoices"] == 1);
    const std::size_t played = fx.audio.play_log().size();

    // What Engine does when a scene loads: sounds stop, then update() sees the new scene (same SceneSettings.music).
    fx.audio.on_scene_load();
    CHECK(fx.audio.stats()["activeVoices"] == 0);
    CHECK(fx.audio.stats()["music"] == "");
    fx.audio.update(world, 1.0f / 60.0f);
    CHECK(fx.audio.stats()["activeVoices"] == 1);
    CHECK(fx.audio.stats()["music"] == "sounds/sine.wav");
    CHECK(fx.audio.play_log().size() == played + 1);
    fx.audio.start_recording();
    fx.run(1.0);
    CHECK(fx.finish().peak(30000) > 0.1f);  // it is audible, not only reported

    // A scene without music after one with music: nothing plays.
    world.settings().music = "";
    fx.audio.on_scene_load();
    fx.audio.update(world, 1.0f / 60.0f);
    fx.run(1.0);
    CHECK(fx.audio.stats()["activeVoices"] == 0);
}

TEST_CASE("audio: music with persist survives scene loads; a scene with the same track does not restart it") {
    Fixture fx;
    write_sine_wav(fx.dir / "sounds/other.wav", 1.0, 220.0);
    World world;
    fx.audio.play_music("sounds/sine.wav", 0.6f, 0.0f, true);
    VoiceId sfx = fx.audio.play("sounds/sine.wav");
    fx.run(0.2);
    const std::size_t played = fx.audio.play_log().size();
    fx.audio.on_scene_load();
    CHECK_FALSE(fx.audio.is_playing(sfx));
    CHECK(fx.audio.stats()["activeVoices"] == 1);
    CHECK(fx.audio.stats()["music"] == "sounds/sine.wav");
    world.settings().music = "sounds/sine.wav";
    fx.audio.update(world, 1.0f / 60.0f);
    CHECK(fx.audio.stats()["activeVoices"] == 1);
    CHECK(fx.audio.play_log().size() == played);  // not played again
    fx.run(0.2);

    fx.audio.on_scene_load();  // still persisted after the scene's own update
    CHECK(fx.audio.stats()["activeVoices"] == 1);

    // another scene with another track replaces it, and that one is not persisted
    world.settings().music = "sounds/other.wav";
    fx.audio.on_scene_load();
    fx.audio.update(world, 1.0f / 60.0f);
    fx.run(1.0);
    CHECK(fx.audio.stats()["music"] == "sounds/other.wav");
    CHECK(fx.audio.stats()["activeVoices"] == 1);
    fx.audio.on_scene_load();
    CHECK(fx.audio.stats()["activeVoices"] == 0);

    // stop_all stops a persisted track too
    fx.audio.play_music("sounds/sine.wav", 0.6f, 0.0f, true);
    fx.audio.stop_all();
    fx.audio.on_scene_load();
    CHECK(fx.audio.stats()["activeVoices"] == 0);
}

TEST_CASE("audio: a voice's volume moves in a straight line over its fade") {
    Fixture fx;
    PlayParams p;
    p.loop = true;
    p.volume = 0.0f;
    VoiceId v = fx.audio.play("sounds/sine.wav", p);
    fx.audio.start_recording();
    fx.run(0.5);
    fx.audio.set_voice_volume(v, 1.0f, 1.0f);
    fx.run(1.5);
    fx.audio.set_voice_volume(v, 0.25f);  // no fade: at once
    fx.run(0.5);
    Recording rec = fx.finish();
    CHECK(rec.peak(0, 22000) < 0.001f);                    // silent before the fade
    CHECK(rec.peak(22050 + 10000, 22050 + 12000) < 0.3f);  // about a quarter of the way
    CHECK(rec.peak(22050 + 10000, 22050 + 12000) > 0.05f);
    CHECK(rec.peak(22050 + 44100 + 2000, 22050 + 44100 + 20000) == doctest::Approx(0.5f).epsilon(0.03));  // full
    CHECK(rec.peak(rec.frames() - 20000) == doctest::Approx(0.125f).epsilon(0.05));
}

namespace {
// A ramp clip: every sample differs, so any offset between two copies shows in the mix.
void write_ramp_wav(const std::filesystem::path& file, double seconds) {
    std::vector<float> s;
    const std::size_t n = std::size_t(seconds * 44100);
    for (std::size_t i = 0; i < n; ++i) s.push_back(0.9f * (float(i) / float(n) * 2.0f - 1.0f));
    write_file(file, wav_bytes(s, 1, 44100));
}
}  // namespace

TEST_CASE("audio: music layers start on the same sample and stay aligned across loops, whole or streamed") {
    Fixture fx;
    fx.write_assets(R"({"format": "factoria.assets/1", "assets": {
        "sounds/ramp_s1.wav": {"import": {"stream": "always"}}, "sounds/ramp_s2.wav": {"import": {"stream": "always"}},
        "sounds/ramp_w1.wav": {"import": {"stream": "never"}}, "sounds/ramp_w2.wav": {"import": {"stream": "never"}}}})");
    for (const char* n : {"ramp_s1", "ramp_s2", "ramp_w1", "ramp_w2"})
        write_ramp_wav(fx.dir / (std::string("sounds/") + n + ".wav"), 0.7);

    for (const char* kind : {"w", "s"}) {
        const std::string a = std::string("sounds/ramp_") + kind + "1.wav",
                          b = std::string("sounds/ramp_") + kind + "2.wav";
        // Both layers at level 1 play the same clip: the mix must be exactly twice one layer.
        MusicLayer la{"a", a, 1.0f}, lb{"b", b, 0.0f};
        fx.audio.stop_all();
        fx.audio.start_recording();
        REQUIRE(fx.audio.play_music_layers({la, lb}, 0.25f, 0.0f));
        fx.run(2.2);
        Recording alone = fx.finish();
        fx.audio.stop_all();
        lb.level = 1.0f;
        fx.audio.start_recording();
        REQUIRE(fx.audio.play_music_layers({la, lb}, 0.25f, 0.0f));
        CHECK(fx.audio.stats()["activeVoices"] == 2);
        fx.run(2.2);
        Recording both = fx.finish();
        REQUIRE(both.frames() == alone.frames());
        float worst = 0;
        for (std::size_t i = 0; i < both.frames(); ++i)
            worst = std::max(worst, std::fabs(both.l[i] - 2.0f * alone.l[i]));
        INFO("kind " << kind);
        CHECK(worst < 0.001f);
        CHECK(alone.peak() > 0.1f);
        CHECK(fx.audio.layer_names() == std::vector<std::string>{"a", "b"});
    }
}

TEST_CASE("audio: setLayer fades a layer, stop_music stops every layer, a bad layer plays nothing") {
    Fixture fx;
    write_sine_wav(fx.dir / "sounds/hi.wav", 1.0, 880.0);
    CHECK_FALSE(
        fx.audio.play_music_layers({{"a", "sounds/sine.wav", 1.0f}, {"b", "sounds/missing.wav", 1.0f}}, 0.6f, 0.0f));
    CHECK(fx.audio.stats()["activeVoices"] == 0);

    REQUIRE(
        fx.audio.play_music_layers({{"base", "sounds/sine.wav", 1.0f}, {"lead", "sounds/hi.wav", 0.0f}}, 1.0f, 0.0f));
    CHECK(fx.audio.stats()["activeVoices"] == 2);
    auto log = fx.audio.play_log();
    REQUIRE(log.size() >= 2);
    CHECK(log[log.size() - 2].layer == "base");
    CHECK(log.back().layer == "lead");
    CHECK(log.back().to_json()["layer"] == "lead");
    CHECK(log.back().music);
    CHECK_FALSE(fx.audio.set_layer("nope", 1.0f));

    fx.run(0.2);
    fx.audio.start_recording();
    CHECK(fx.audio.set_layer("lead", 1.0f, 0.5f));
    CHECK(fx.audio.set_layer("base", 0.0f, 0.5f));
    fx.run(1.0);
    Recording rec = fx.finish();
    CHECK(rec.peak(0, 1000) > 0.4f);              // base only at first
    CHECK(rec.peak(rec.frames() - 4000) > 0.4f);  // lead only at the end
    fx.audio.stop_music(0.0f);
    CHECK(fx.audio.stats()["activeVoices"] == 0);
    CHECK(fx.audio.layer_names().empty());
}

TEST_CASE("audio: layers are never evicted by a full mixer and a scene load keeps persisted layers") {
    Fixture fx;
    REQUIRE(
        fx.audio.play_music_layers({{"a", "sounds/sine.wav", 1.0f}, {"b", "sounds/sine.wav", 1.0f}}, 0.2f, 0.0f, true));
    for (int i = 0; i < 100; ++i) fx.audio.play("sounds/sine.wav");
    CHECK(fx.audio.stats()["activeVoices"] == 64);
    fx.audio.on_scene_load();
    CHECK(fx.audio.stats()["activeVoices"] == 2);
    CHECK(fx.audio.set_layer("a", 0.5f));
    fx.audio.on_scene_load();
    CHECK(fx.audio.stats()["activeVoices"] == 2);
    fx.audio.stop_all();
    CHECK(fx.audio.layer_names().empty());
}

// The web player mixes in chunks of whatever the AudioWorklet asks for (512 frames up to 8192) instead of one block per engine
// frame; the mix must not depend on how it is cut.
TEST_CASE("audio: the mix is the same however it is cut into chunks (web AudioWorklet feed)") {
    auto record = [](double step, int steps) {
        Fixture fx;
        REQUIRE(fx.audio.load("sounds/sine.wav"));
        fx.audio.start_recording();
        fx.audio.play("sounds/sine.wav", {.pitch = 1.3f, .loop = true});
        for (int i = 0; i < steps; ++i) fx.audio.advance_null_device(step);
        return fx.finish();
    };
    Recording a = record(1.0 / 60.0, 120);       // 2 s in frames of 735
    Recording b = record(512.0 / 44100.0, 172);  // chunks of 512 (about 2 s)
    REQUIRE(a.frames() > 80000);
    REQUIRE(b.frames() > 80000);
    const std::size_t n = std::min(a.frames(), b.frames());
    float worst = 0;
    for (std::size_t i = 0; i < n; ++i) worst = std::max(worst, std::fabs(a.l[i] - b.l[i]));
    CHECK(worst < 0.001f);
    CHECK(a.peak() > 0.3f);
}

TEST_CASE("audio: an AudioSource with variants picks one per play, never the last one twice, the same on every run "
          "with the same seed") {
    auto run = [](std::uint64_t seed, int plays) {
        Fixture fx;
        World world;
        world.rng().reseed(seed);
        Entity e = world.create("step", "step");
        AudioSource& src = world.add<AudioSource>(e);
        src.clip =
            "sounds/step.wav";  // the variants (step_01.wav ...) do not exist: the play log still names what was picked
        src.variants = 4;
        std::vector<std::string> picked;
        for (int i = 0; i < plays; ++i) {
            world.get<AudioSource>(e)->playing = true;
            fx.audio.update(world, 1.0f / 60.0f);
        }
        for (const AudioEvent& ev : fx.audio.play_log()) picked.push_back(ev.path);
        return picked;
    };
    const std::vector<std::string> a = run(7, 24), b = run(7, 24), other = run(8, 24);
    REQUIRE(a.size() == 24);
    CHECK(a == b);      // deterministic
    CHECK(a != other);  // the seed matters
    std::set<std::string> distinct(a.begin(), a.end());
    CHECK(distinct.size() == 4);
    for (std::size_t i = 0; i < a.size(); ++i) {
        CHECK(a[i].starts_with("sounds/step_0"));
        CHECK(a[i].ends_with(".wav"));
        if (i > 0) CHECK(a[i] != a[i - 1]);
    }
    // the world's random numbers are not consumed by the picks
    World world;
    world.rng().reseed(3);
    const std::uint64_t before = world.rng().state();
    Fixture fx;
    Entity e = world.create("step", "step");
    AudioSource& src = world.add<AudioSource>(e);
    src.clip = "sounds/step.wav";
    src.variants = 4;
    src.playing = true;
    fx.audio.update(world, 1.0f / 60.0f);
    CHECK(world.rng().state() == before);
    // variants 0 or 1 plays the clip itself
    src.variants = 1;
    world.get<AudioSource>(e)->playing = true;
    fx.audio.update(world, 1.0f / 60.0f);
    CHECK(fx.audio.play_log().back().path == "sounds/step.wav");
}
