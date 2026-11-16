// Doppler and occlusion of 3D audio (docs/SOUND.md, "Doppler" and "Occlusion"): the pitch a moving source or listener gets, the
// rays Audio asks for (a fake probe stands in for physics, which the audio module cannot reach), their budget and smoothing, and
// the per-voice low-pass of the mixer.
#include <doctest.h>

#include <cmath>
#include <functional>
#include <set>
#include <string>
#include <vector>

#include "../src/audio_testing.h"
#include "audio_test_helpers.h"
#include "fa/audio/audio.h"
#include "fa/scene/components.h"

using namespace fa;
using namespace audio_test;

namespace {

constexpr float kDt = 1.0f / 60.0f;

// The first voice of a source's entity (by the id the play log and active_voices give), or a null Json.
Json voice_of(Audio& audio, const std::string& source = "") {
    for (const Json& v : audio.active_voices())
        if (source.empty() || v["source"] == source) return v;
    return Json();
}

struct Scene {
    World world;
    Entity listener;
    explicit Scene(float speedOfSound = 343.0f) {
        listener = world.create("ear", "ear");
        world.add<AudioListener>(listener).speedOfSound = speedOfSound;
    }
    Entity source(const std::string& id, Vec3 pos, const std::function<void(AudioSource&)>& setup = {}) {
        Entity s = world.create(id, id);
        AudioSource& src = world.add<AudioSource>(s);
        src.clip = "sounds/sine.wav";
        src.playOnStart = true;
        src.loop = true;
        src.spatial = true;
        src.range = 100000.0f;
        world.get<Transform>(s)->position = pos;
        if (setup) setup(src);
        return s;
    }
    void move(Entity e, Vec3 pos) { world.get<Transform>(e)->position = pos; }
};

void tick(Fixture& fx, Scene& sc) {
    fx.audio.update(sc.world, kDt);
    fx.audio.advance_null_device(kDt);
}

}  // namespace

TEST_CASE("doppler: the pitch ratio of a source and a listener that approach or separate") {
    const float c = 343.0f;
    // at rest, or with the level 0: exactly 1
    CHECK(audio_doppler_pitch({0, 0, 0}, {0, 0, 0}, {100, 0, 0}, {0, 0, 0}, c, 1.0f) == 1.0f);
    CHECK(audio_doppler_pitch({0, 0, 0}, {50, 0, 0}, {100, 0, 0}, {-50, 0, 0}, c, 0.0f) == 1.0f);
    // a source that comes at 50: c / (c - 50); one that goes away: c / (c + 50)
    CHECK(audio_doppler_pitch({0, 0, 0}, {0, 0, 0}, {100, 0, 0}, {-50, 0, 0}, c, 1.0f) ==
          doctest::Approx(c / (c - 50)));
    CHECK(audio_doppler_pitch({0, 0, 0}, {0, 0, 0}, {100, 0, 0}, {50, 0, 0}, c, 1.0f) == doctest::Approx(c / (c + 50)));
    // a listener that walks towards the source: (c + 50) / c; away from it: lower
    CHECK(audio_doppler_pitch({0, 0, 0}, {50, 0, 0}, {100, 0, 0}, {0, 0, 0}, c, 1.0f) == doctest::Approx((c + 50) / c));
    CHECK(audio_doppler_pitch({0, 0, 0}, {-50, 0, 0}, {100, 0, 0}, {0, 0, 0}, c, 1.0f) < 1.0f);
    // sideways movement does not shift
    CHECK(audio_doppler_pitch({0, 0, 0}, {0, 0, 0}, {100, 0, 0}, {0, 80, 0}, c, 1.0f) == doctest::Approx(1.0f));
    // the level is the exponent: 2 doubles the shift in octaves
    CHECK(audio_doppler_pitch({0, 0, 0}, {0, 0, 0}, {100, 0, 0}, {-50, 0, 0}, c, 2.0f) ==
          doctest::Approx(std::pow(c / (c - 50), 2.0f)));
    // the factor stays in 0.25..4 however fast and however exaggerated
    CHECK(audio_doppler_pitch({0, 0, 0}, {0, 0, 0}, {100, 0, 0}, {-330, 0, 0}, c, 10.0f) == kDopplerMaxPitch);
    CHECK(audio_doppler_pitch({0, 0, 0}, {0, 0, 0}, {100, 0, 0}, {330, 0, 0}, c, 10.0f) == kDopplerMinPitch);
    // the same place: nothing to project on
    CHECK(audio_doppler_pitch({1, 2, 3}, {5, 0, 0}, {1, 2, 3}, {-5, 0, 0}, c, 1.0f) == 1.0f);
    // velocity: delta over dt, nothing for a jump of more than four speeds of sound per second
    CHECK(audio_velocity({2, 0, 0}, 1.0f / 60.0f, c).x == doctest::Approx(120.0f));
    CHECK(audio_velocity({100000, 0, 0}, 1.0f / 60.0f, c).x == 0.0f);
    CHECK(audio_velocity({2, 0, 0}, 0.0f, c).x == 0.0f);
}

TEST_CASE("doppler: an AudioSource approaching, receding, the listener walking, and level 0") {
    // a new Audio for each run: a World of the same address as the last one would keep the sources of that one
    auto settled_pitch = [&](const std::function<void(Scene&, Entity, int)>& moveFn, float level) {
        Fixture fx;
        Scene sc;
        Entity s = sc.source("src", {500, 0, 0}, [&](AudioSource& a) { a.dopplerLevel = level; });
        tick(fx, sc);
        // the first frame: a new source has no velocity yet, so no shift
        CHECK(voice_of(fx.audio)["pitch"].get<float>() == 1.0f);
        for (int i = 1; i <= 90; ++i) {
            moveFn(sc, s, i);
            tick(fx, sc);
        }
        return voice_of(fx.audio)["pitch"].get<float>();
    };
    // 2 units per frame = 120 per second, towards the listener at the origin
    const auto approach = [](Scene& sc, Entity s, int i) { sc.move(s, {500.0f - 2.0f * float(i), 0, 0}); };
    const auto recede = [](Scene& sc, Entity s, int i) { sc.move(s, {500.0f + 2.0f * float(i), 0, 0}); };
    const auto walk = [](Scene& sc, Entity, int i) { sc.move(sc.listener, {2.0f * float(i), 0, 0}); };
    CHECK(settled_pitch(approach, 1.0f) == doctest::Approx(343.0f / (343.0f - 120.0f)).epsilon(0.002));
    CHECK(settled_pitch(recede, 1.0f) == doctest::Approx(343.0f / (343.0f + 120.0f)).epsilon(0.002));
    CHECK(settled_pitch(walk, 1.0f) == doctest::Approx((343.0f + 120.0f) / 343.0f).epsilon(0.002));
    // level 0 is the pitch of a source with no doppler, bit for bit
    CHECK(settled_pitch(approach, 0.0f) == 1.0f);
}

TEST_CASE("doppler: the pitch glides (no jump), and a teleport gives no shift") {
    Fixture fx;
    Scene sc;
    Entity s = sc.source("src", {500, 0, 0}, [](AudioSource& a) { a.dopplerLevel = 1.0f; });
    for (int i = 0; i < 10; ++i) tick(fx, sc);
    CHECK(voice_of(fx.audio)["pitch"].get<float>() == 1.0f);
    // a start of 120 units per second: the pitch moves towards 1.54 over several frames, never in one
    float last = 1.0f, biggest = 0.0f;
    for (int i = 1; i <= 30; ++i) {
        sc.move(s, {500.0f - 2.0f * float(i), 0, 0});
        tick(fx, sc);
        const float p = voice_of(fx.audio)["pitch"].get<float>();
        biggest = std::max(biggest, p - last);
        CHECK(p >= last);
        last = p;
    }
    CHECK(biggest < 0.2f);
    CHECK(last > 1.3f);
    // a teleport: 100000 units in one frame is a jump, not a speed
    sc.move(s, {100000, 0, 0});
    for (int i = 0; i < 90; ++i) tick(fx, sc);
    CHECK(voice_of(fx.audio)["pitch"].get<float>() == doctest::Approx(1.0f).epsilon(0.001));
    // a first frame at a distance: a source created far away and still has no shift
    Scene far;
    far.source("src", {100000, 0, 0}, [](AudioSource& a) { a.dopplerLevel = 1.0f; });
    for (int i = 0; i < 5; ++i) tick(fx, far);
    CHECK(voice_of(fx.audio)["pitch"].get<float>() == 1.0f);
}

TEST_CASE("doppler: audio.play at a position uses the velocity it is given, and the listener's") {
    Fixture fx;
    Scene sc;
    tick(fx, sc);
    SpatialSound sound;
    sound.range = 100000.0f;
    sound.velocity = {-50, 0, 0};
    sound.dopplerLevel = 1.0f;
    PlayParams params;
    params.loop = true;
    VoiceId v = fx.audio.play_at(sc.world, "sounds/sine.wav", params, {100, 0, 0}, sound);
    REQUIRE(v != 0);
    CHECK(voice_of(fx.audio)["pitch"].get<float>() == doctest::Approx(343.0f / (343.0f - 50.0f)));
    // later the pitch still follows it, and the listener's own movement joins in
    for (int i = 0; i < 60; ++i) tick(fx, sc);
    CHECK(voice_of(fx.audio)["pitch"].get<float>() == doctest::Approx(343.0f / (343.0f - 50.0f)).epsilon(0.001));
    for (int i = 1; i <= 90; ++i) {
        sc.move(sc.listener, {float(i), 0, 0});  // 60 units per second towards the sound (it stays in front, at 100)
        tick(fx, sc);
    }
    CHECK(voice_of(fx.audio)["pitch"].get<float>() ==
          doctest::Approx((343.0f + 60.0f) / (343.0f - 50.0f)).epsilon(0.002));
    // no dopplerLevel: the plain pitch
    sound.dopplerLevel = 0.0f;
    fx.audio.stop_all();
    v = fx.audio.play_at(sc.world, "sounds/sine.wav", params, {200, 0, 0}, sound);
    CHECK(voice_of(fx.audio)["pitch"].get<float>() == 1.0f);
}

TEST_CASE("occlusion: the probe's answer sets the volume and the low-pass, smoothly") {
    Fixture fx;
    Scene sc;
    bool blocked = true;
    int calls = 0;
    AudioOcclusionRay seen;
    fx.audio.set_occlusion_probe([&](World&, const AudioOcclusionRay& ray) {
        ++calls;
        seen = ray;
        return blocked;
    });
    Entity s = sc.source("src", {40, 0, 0}, [](AudioSource& a) {
        a.range = 100.0f;
        a.occlusion = true;
        a.occlusionMask = 6;
        a.occlusionGain = 0.4f;
        a.occlusionLowpass = 1500.0f;
    });
    tick(fx, sc);
    // the first answer applies at once: a sound that starts behind a wall starts muffled
    const Json v = voice_of(fx.audio);
    CHECK(v["volume"].get<float>() == doctest::Approx(0.6f * 0.4f));
    CHECK(AudioTestAccess::voice_lowpass(fx.audio, v["id"].get<VoiceId>()) == doctest::Approx(1500.0f));
    CHECK(calls == 1);
    CHECK(seen.mask == 6);
    CHECK(seen.source == s);
    CHECK(seen.listener == sc.listener);
    CHECK(seen.from.x == 0.0f);
    CHECK(seen.to.x == 40.0f);
    // a source is asked again about every 0.1 s, not every frame
    for (int i = 0; i < 4; ++i) tick(fx, sc);
    CHECK(calls == 1);
    // the wall goes away: volume and cutoff move over about 0.1 s, in steps no bigger than their share of it
    blocked = false;
    float last = voice_of(fx.audio)["volume"].get<float>(), biggest = 0.0f;
    bool between = false;
    for (int i = 0; i < 30; ++i) {
        tick(fx, sc);
        const float vol = voice_of(fx.audio)["volume"].get<float>();
        biggest = std::max(biggest, vol - last);
        between = between || (vol > 0.25f && vol < 0.59f);
        CHECK(vol >= last);
        last = vol;
    }
    CHECK(calls >= 2);
    CHECK(between);
    CHECK(biggest < 0.1f);
    CHECK(last == doctest::Approx(0.6f));
    CHECK(AudioTestAccess::voice_lowpass(fx.audio, voice_of(fx.audio)["id"].get<VoiceId>()) == 0.0f);
    // blocked again: back down
    blocked = true;
    for (int i = 0; i < 30; ++i) tick(fx, sc);
    CHECK(voice_of(fx.audio)["volume"].get<float>() == doctest::Approx(0.24f));
}

TEST_CASE("occlusion: off by default, without a probe, with a cutoff of 20000, and for a non-spatial source") {
    int calls = 0;
    const auto probe = [&](World&, const AudioOcclusionRay&) {
        ++calls;
        return true;
    };
    {
        Fixture fx;
        Scene sc;
        sc.source("src", {40, 0, 0}, [](AudioSource& a) { a.range = 100.0f; });
        fx.audio.set_occlusion_probe(probe);
        for (int i = 0; i < 20; ++i) tick(fx, sc);
        CHECK(calls == 0);  // occlusion is off: no ray, and the plain volume
        CHECK(voice_of(fx.audio)["volume"].get<float>() == doctest::Approx(0.6f));
    }
    {
        Fixture fx;  // a cutoff of 20000: the volume drops, the voice has no filter
        Scene sc;
        sc.source("src", {40, 0, 0}, [](AudioSource& a) {
            a.range = 100.0f;
            a.occlusion = true;
            a.occlusionLowpass = 20000.0f;
        });
        fx.audio.set_occlusion_probe(probe);
        for (int i = 0; i < 5; ++i) tick(fx, sc);
        CHECK(voice_of(fx.audio)["volume"].get<float>() == doctest::Approx(0.24f));
        CHECK(AudioTestAccess::voice_lowpass(fx.audio, voice_of(fx.audio)["id"].get<VoiceId>()) == 0.0f);
    }
    {
        Fixture fx;
        Scene sc;
        sc.source("src", {40, 0, 0}, [](AudioSource& a) {
            a.range = 100.0f;
            a.occlusion = true;
            a.spatial = false;
        });
        fx.audio.set_occlusion_probe(probe);
        calls = 0;
        for (int i = 0; i < 5; ++i) tick(fx, sc);
        CHECK(calls == 0);
    }
    {
        Fixture fx;  // no probe set: nothing is occluded
        Scene sc;
        sc.source("src", {40, 0, 0}, [](AudioSource& a) {
            a.range = 100.0f;
            a.occlusion = true;
        });
        for (int i = 0; i < 5; ++i) tick(fx, sc);
        CHECK(voice_of(fx.audio)["volume"].get<float>() == doctest::Approx(0.6f));
    }
}

TEST_CASE("occlusion: at most kAudioOcclusionRaysPerFrame rays per frame, every source gets its turn") {
    Fixture fx;
    Scene sc;
    int calls = 0;
    std::set<std::uint64_t> asked;
    fx.audio.set_occlusion_probe([&](World&, const AudioOcclusionRay& ray) {
        ++calls;
        asked.insert(ray.source.bits());
        return true;
    });
    const int count = 3 * kAudioOcclusionRaysPerFrame + 4;
    for (int i = 0; i < count; ++i)
        sc.source("s" + std::to_string(i), {10.0f + float(i), 0, 0}, [](AudioSource& a) {
            a.range = 1000.0f;
            a.occlusion = true;
        });
    int most = 0;
    for (int frame = 0; frame < 10; ++frame) {
        const int before = calls;
        tick(fx, sc);
        most = std::max(most, calls - before);
        if (frame == 0) CHECK(calls == kAudioOcclusionRaysPerFrame);
    }
    CHECK(most <= kAudioOcclusionRaysPerFrame);
    CHECK(asked.size() == std::size_t(count));  // 28 sources: all of them within four frames
    // a sound at a place that asks for occlusion uses the same budget: after the update that refills it, one ray is free
    SpatialSound sound;
    sound.occlusion = true;
    sound.range = 1000.0f;
    const int before = calls;
    fx.audio.play_at(sc.world, "sounds/sine.wav", PlayParams{}, {30, 0, 0}, sound);
    CHECK(calls == before + 1);
}

TEST_CASE("occlusion: audio.play at a position, blocked and not") {
    Fixture fx;
    Scene sc;
    bool blocked = true;
    fx.audio.set_occlusion_probe([&](World&, const AudioOcclusionRay& ray) {
        CHECK(ray.source.is_null());
        CHECK(ray.mask == 3);
        return blocked;
    });
    tick(fx, sc);
    SpatialSound sound;
    sound.range = 100.0f;
    sound.occlusion = true;
    sound.occlusionMask = 3;
    sound.occlusionGain = 0.5f;
    sound.occlusionLowpass = 800.0f;
    VoiceId v = fx.audio.play_at(sc.world, "sounds/sine.wav", PlayParams{}, {40, 0, 0}, sound);
    REQUIRE(v != 0);
    CHECK(fx.audio.play_log().back().volume == doctest::Approx(0.6f));  // the gain of the blocked path is apart from it
    CHECK(AudioTestAccess::voice_occlusion_gain(fx.audio, v) == doctest::Approx(0.5f));
    CHECK(AudioTestAccess::voice_lowpass(fx.audio, v) == doctest::Approx(800.0f));
    blocked = false;
    v = fx.audio.play_at(sc.world, "sounds/sine.wav", PlayParams{}, {40, 0, 0}, sound);
    CHECK(fx.audio.play_log().back().volume == doctest::Approx(0.6f));
    CHECK(AudioTestAccess::voice_occlusion_gain(fx.audio, v) == 1.0f);
    CHECK(AudioTestAccess::voice_lowpass(fx.audio, v) == 0.0f);
}

TEST_CASE("voice low-pass: off is bit-identical, and a high tone is attenuated") {
    Fixture fx;
    write_sine_wav(fx.dir / "sounds/high.wav", 1.0, 6000.0, 0.5);
    write_sine_wav(fx.dir / "sounds/low.wav", 1.0, 200.0, 0.5);
    auto record = [&](const char* clip, const std::function<void(VoiceId)>& setup) {
        fx.audio.start_recording();
        PlayParams params;
        params.loop = true;
        const VoiceId v = fx.audio.play(clip, params);
        REQUIRE(v != 0);
        if (setup) setup(v);
        fx.run(0.5);
        fx.audio.stop(v);
        fx.run(0.05);
        return fx.finish();
    };
    const Recording plain = record("sounds/high.wav", nullptr);
    REQUIRE(plain.peak() > 0.4f);
    // never set, set to 0 and set to 20000: the same samples exactly
    for (float hz : {0.0f, 20000.0f, 44100.0f}) {
        const Recording off =
            record("sounds/high.wav", [&](VoiceId v) { AudioTestAccess::set_voice_lowpass(fx.audio, v, hz); });
        REQUIRE(off.frames() == plain.frames());
        CHECK(off.l == plain.l);
        CHECK(off.r == plain.r);
    }
    // 6 kHz through a 500 Hz low-pass of 12 dB/octave: about -43 dB
    const Recording muffled =
        record("sounds/high.wav", [&](VoiceId v) { AudioTestAccess::set_voice_lowpass(fx.audio, v, 500.0f); });
    CHECK(muffled.peak(2000, 20000) < 0.05f * plain.peak());
    // 200 Hz through a 5 kHz low-pass passes
    const Recording low = record("sounds/low.wav", nullptr);
    const Recording lowFiltered =
        record("sounds/low.wav", [&](VoiceId v) { AudioTestAccess::set_voice_lowpass(fx.audio, v, 5000.0f); });
    CHECK(lowFiltered.peak(2000, 20000) == doctest::Approx(low.peak(2000, 20000)).epsilon(0.03));
}

TEST_CASE("voice low-pass: switching it on and off does not click") {
    Fixture fx;
    write_sine_wav(fx.dir / "sounds/low.wav", 1.0, 200.0, 0.5);
    fx.audio.start_recording();
    PlayParams params;
    params.loop = true;
    const VoiceId v = fx.audio.play("sounds/low.wav", params);
    fx.run(0.1);
    AudioTestAccess::set_voice_lowpass(fx.audio, v, 5000.0f);
    fx.run(0.1);
    // occlusion opens the cutoff geometrically towards 20000 before it takes the filter away: the switch-off is where it does nothing
    for (int i = 1; i <= 10; ++i) {
        AudioTestAccess::set_voice_lowpass(fx.audio, v, 5000.0f * std::pow(19000.0f / 5000.0f, float(i) / 10.0f));
        fx.run(0.01);
    }
    AudioTestAccess::set_voice_lowpass(fx.audio, v, 0.0f);
    fx.run(0.1);
    const Recording rec = fx.finish();
    // a 200 Hz sine of amplitude 0.5 moves by at most 0.5 * 2 pi 200 / 44100 = 0.0143 per sample: any step much bigger is a click
    float biggest = 0.0f;
    for (std::size_t i = 1; i < rec.frames(); ++i) biggest = std::max(biggest, std::fabs(rec.l[i] - rec.l[i - 1]));
    CHECK(biggest < 0.03f);
}

TEST_CASE("occlusion and doppler: a script's set_voice_volume (and its fade) on a sound played at a place is kept") {
    // The sound at the end of a fade to 0.5, measured through the mixer: a plain sound (nothing follows it) is the reference.
    const auto level_after_fade = [](bool follows, bool blocked, float occlusionGain) {
        Fixture fx;
        Scene sc;
        fx.audio.set_occlusion_probe([&](World&, const AudioOcclusionRay&) { return blocked; });
        tick(fx, sc);
        SpatialSound sound;
        sound.range = 100.0f;
        if (follows) {
            sound.dopplerLevel = 1.0f;
            sound.occlusion = true;
            sound.occlusionGain = occlusionGain;
            sound.occlusionLowpass = 20000.0f;  // volume only
        }
        PlayParams params;
        params.loop = true;
        const VoiceId v = fx.audio.play_at(sc.world, "sounds/sine.wav", params, {40, 0, 0}, sound);
        REQUIRE(v != 0);
        fx.audio.start_recording();
        fx.audio.set_voice_volume(v, 0.5f, 0.2f);
        for (int i = 0; i < 60; ++i) tick(fx, sc);  // one second: the fade (0.2 s) and the occlusion (0.1 s) are over
        CHECK(voice_of(fx.audio)["volume"].get<float>() == doctest::Approx(0.5f));
        const Recording rec = fx.finish();
        REQUIRE(rec.frames() > 40000);
        return rec.peak(rec.frames() - 4000, rec.frames());
    };
    const float reference = level_after_fade(false, false, 1.0f);
    REQUIRE(reference > 0.05f);
    // followed, not blocked: the same level (it used to snap back to the volume the sound started with)
    CHECK(level_after_fade(true, false, 0.5f) == doctest::Approx(reference).epsilon(0.01));
    // followed and blocked: the script's volume times the occlusion gain
    CHECK(level_after_fade(true, true, 0.5f) == doctest::Approx(reference * 0.5f).epsilon(0.02));
}

TEST_CASE("occlusion and doppler: a fade in progress is not interrupted while the occlusion changes") {
    Fixture fx;
    Scene sc;
    bool blocked = false;
    fx.audio.set_occlusion_probe([&](World&, const AudioOcclusionRay&) { return blocked; });
    tick(fx, sc);
    SpatialSound sound;
    sound.range = 100.0f;
    sound.occlusion = true;
    sound.occlusionGain = 0.5f;
    sound.occlusionLowpass = 20000.0f;
    PlayParams params;
    params.loop = true;
    const VoiceId v = fx.audio.play_at(sc.world, "sounds/sine.wav", params, {0, 0, -1}, sound);
    REQUIRE(v != 0);
    fx.audio.set_voice_volume(v, 0.0f, 1.0f);  // a one second fade out while the path gets blocked
    fx.audio.start_recording();
    for (int i = 0; i < 12; ++i) tick(fx, sc);
    blocked = true;
    for (int i = 0; i < 18; ++i) tick(fx, sc);
    const Recording rec = fx.finish();
    // the level falls steadily: no half-second window is louder than the one before it (a snap back to the start volume would be)
    const std::size_t w = rec.frames() / 6;
    float previous = rec.peak(0, w);
    REQUIRE(previous > 0.01f);
    for (int i = 1; i < 6; ++i) {
        const float now = rec.peak(std::size_t(i) * w, std::size_t(i + 1) * w);
        CHECK(now <= previous * 1.001f);
        previous = now;
    }
}
