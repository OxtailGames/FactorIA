// HRTF for headphones (docs/sound/SOUND_SPATIAL.md, "Headphones"): AudioListener.spatialization "hrtf" places a spatial sound with the parametric
// head model of the mixer (a delay and a head-shadow filter per ear) instead of the pan. These tests measure what comes out of the
// mixer on the null device (the headless recorder): the time difference between the ears against Woodworth's formula, the level
// difference and the shadow of high frequencies, front/back symmetry, a source that moves, and that "pan" is what it always was.
#include <doctest.h>

#include <algorithm>
#include <cmath>
#include <filesystem>
#include <functional>
#include <limits>
#include <memory>
#include <mutex>
#include <string>
#include <vector>

#include "../src/audio_testing.h"
#include "alloc_counter.h"
#include "audio_test_helpers.h"
#include "fa/audio/audio.h"
#include "fa/core/log.h"
#include "fa/scene/components.h"

using namespace fa;
using namespace audio_test;

namespace {

constexpr float kDt = 1.0f / 60.0f;
constexpr double kRate = 44100.0;
constexpr float kPiF = 3.14159265358979f;

struct Scene {
    World world;
    Entity listener;
    explicit Scene(bool hrtf = true, float headRadius = 0.0875f, float speedOfSound = 343.0f) {
        listener = world.create("ear", "ear");
        AudioListener& al = world.add<AudioListener>(listener);
        al.spatialization = hrtf ? AudioSpatialization::Hrtf : AudioSpatialization::Pan;
        al.headRadius = headRadius;
        al.speedOfSound = speedOfSound;
    }
    Entity source(const std::string& clip, Vec3 pos, bool loop, float range = 100000.0f,
                  const std::string& id = "src") {
        Entity s = world.create(id, id);
        AudioSource& src = world.add<AudioSource>(s);
        src.clip = clip;
        src.playOnStart = true;
        src.loop = loop;
        src.spatial = true;
        src.range = range;
        world.get<Transform>(s)->position = pos;
        return s;
    }
};

void tick(Fixture& fx, Scene& sc) {
    fx.audio.update(sc.world, kDt);
    fx.audio.advance_null_device(kDt);
}

// A smooth pulse (a Gaussian of sigma 40 frames, mostly below 400 Hz), so its place in time is the same through a filter that
// only changes the high frequencies, at 0.05 s of a clip of 0.3 s.
void write_pulse(const std::filesystem::path& file, int channels = 1, int silentChannel = -1) {
    std::vector<float> s;
    const int n = int(0.3 * kRate), centre = int(0.05 * kRate);
    for (int i = 0; i < n; ++i) {
        const double x = double(i - centre) / 40.0;
        const float v = float(0.8 * std::exp(-0.5 * x * x));
        for (int c = 0; c < channels; ++c) s.push_back(c == silentChannel ? 0.0f : v);
    }
    write_file(file, wav_bytes(s, channels, int(kRate)));
}

// The clips of these tests, in a project: a pulse (mono, and stereo with a silent right channel), a low and a high tone.
void write_clips(const std::filesystem::path& dir) {
    write_pulse(dir / "sounds/pulse.wav");
    write_pulse(dir / "sounds/left_only.wav", 2, 1);
    write_sine_wav(dir / "sounds/low.wav", 1.0, 200.0, 0.4);
    write_sine_wav(dir / "sounds/high.wav", 1.0, 6000.0, 0.4);
    write_sine_wav(dir / "sounds/tone.wav", 1.0, 300.0, 0.5);
}

// The listener hears `clip` from `pos` (the listener at the origin looks down -Z, its right is +X) for `seconds`. Every call has
// an Audio of its own: a World at the address of the last one would keep the sources of that one.
Recording hear(const std::string& clip, Vec3 pos, bool loop, double seconds,
               const std::function<void(Scene&)>& setup = {}, bool hrtf = true) {
    Fixture fx;
    write_clips(fx.dir);
    Scene sc(hrtf);
    if (setup) setup(sc);
    sc.source(clip, pos, loop);
    fx.audio.start_recording();
    for (int i = 0, n = int(std::lround(seconds * 60.0)); i < n; ++i) tick(fx, sc);
    return fx.finish();
}

double centroid(const std::vector<float>& x) {
    double sum = 0.0, weighted = 0.0;
    for (std::size_t i = 0; i < x.size(); ++i) {
        sum += x[i];
        weighted += double(i) * x[i];
    }
    return sum != 0.0 ? weighted / sum : 0.0;
}

// Frames by which the sound arrives later at the left ear than at the right one (negative: earlier).
double itd_frames(const Recording& rec) { return centroid(rec.l) - centroid(rec.r); }

double rms(const std::vector<float>& x, std::size_t from, std::size_t to) {
    double e = 0.0;
    for (std::size_t i = from; i < to; ++i) e += double(x[i]) * double(x[i]);
    return std::sqrt(e / double(to - from));
}

double woodworth_frames(float lateral, float radius = 0.0875f, float speed = 343.0f) {
    return double(audio_hrtf_itd(lateral, radius / speed)) * kRate;
}

}  // namespace

TEST_CASE("hrtf: Woodworth's time difference and the head time") {
    const float a = 0.0875f / 343.0f;
    CHECK(audio_hrtf_itd(0.0f, a) == 0.0f);
    CHECK(audio_hrtf_itd(1.0f, a) == doctest::Approx(a * (kPiF * 0.5f + 1.0f)));
    CHECK(audio_hrtf_itd(-1.0f, a) == doctest::Approx(-a * (kPiF * 0.5f + 1.0f)));
    CHECK(audio_hrtf_itd(0.5f, a) == doctest::Approx(a * (kPiF / 6.0f + 0.5f)));  // 30 degrees from the median plane
    CHECK(audio_hrtf_itd(7.0f, a) == audio_hrtf_itd(1.0f, a));                    // clamped, never NaN
    // the head time: radius over speed of sound, clamped to the heads the model takes
    bool clamped = true;
    CHECK(audio_hrtf_head_time(0.0875f, 343.0f, &clamped) == doctest::Approx(a));
    CHECK_FALSE(clamped);
    CHECK(audio_hrtf_head_time(8.75f, 34300.0f, &clamped) == doctest::Approx(a));  // a world in pixels: same head
    CHECK_FALSE(clamped);
    CHECK(audio_hrtf_head_time(5.0f, 343.0f, &clamped) == doctest::Approx(kHrtfMaxHeadRadius / 343.0f));
    CHECK(clamped);
    CHECK(audio_hrtf_head_time(0.0001f, 343.0f, &clamped) == doctest::Approx(kHrtfMinHeadRadius / 343.0f));
    CHECK(clamped);
    CHECK(audio_hrtf_head_time(0.0875f, 0.0f) == doctest::Approx(a));  // no speed of sound: 343
    CHECK(audio_hrtf_head_time(std::nanf(""), 343.0f, &clamped) == doctest::Approx(kHrtfMinHeadRadius / 343.0f));
    CHECK(clamped);
}

TEST_CASE("hrtf: a sound to the right arrives earlier and louder at the right ear, by Woodworth's time") {
    const Recording rec = hear("sounds/pulse.wav", {3, 0, 0}, false, 0.4);
    REQUIRE(rec.frames() > 10000);
    const double expected = woodworth_frames(1.0f);  // 0.656 ms: 28.9 frames
    CHECK(expected == doctest::Approx(28.9).epsilon(0.01));
    CHECK(itd_frames(rec) == doctest::Approx(expected).epsilon(0.03));
    CHECK(rec.peak_r() > rec.peak_l());  // louder at the near ear
    // the far ear is not silent: the sound is heard with both
    CHECK(rec.peak_l() > 0.1f);
    // to the left: the mirror image
    const Recording left = hear("sounds/pulse.wav", {-3, 0, 0}, false, 0.4);
    CHECK(itd_frames(left) == doctest::Approx(-expected).epsilon(0.03));
    CHECK(left.peak_l() > left.peak_r());
}

TEST_CASE("hrtf: the time difference follows the angle and the head radius") {
    // 30 degrees to the right, in front: sin = 0.5 (a source at (1.5, 0, -2.598))
    const Recording thirty = hear("sounds/pulse.wav", {1.5f, 0, -2.598f}, false, 0.4);
    CHECK(itd_frames(thirty) == doctest::Approx(woodworth_frames(0.5f)).epsilon(0.04));
    // straight ahead and straight behind: the same at both ears
    const Recording ahead = hear("sounds/pulse.wav", {0, 0, -3}, false, 0.4);
    CHECK(std::fabs(itd_frames(ahead)) < 0.3);
    CHECK(ahead.peak_l() == doctest::Approx(ahead.peak_r()).epsilon(0.02));
    // a bigger head: a longer difference
    const Recording big = hear("sounds/pulse.wav", {3, 0, 0}, false, 0.4,
                               [](Scene& sc) { sc.world.get<AudioListener>(sc.listener)->headRadius = 0.115f; });
    CHECK(itd_frames(big) == doctest::Approx(woodworth_frames(1.0f, 0.115f)).epsilon(0.03));
    // the same head in a world of pixels: headRadius and speedOfSound in those units give the same time
    const Recording pixels = hear("sounds/pulse.wav", {300, 0, 0}, false, 0.4, [](Scene& sc) {
        AudioListener& al = *sc.world.get<AudioListener>(sc.listener);
        al.headRadius = 8.75f;
        al.speedOfSound = 34300.0f;
    });
    CHECK(itd_frames(pixels) == doctest::Approx(woodworth_frames(1.0f)).epsilon(0.03));
}

TEST_CASE("hrtf: the time difference is the same in front and behind") {
    const Recording front = hear("sounds/pulse.wav", {2.5f, 0, -2.5f}, false, 0.4);
    const Recording back = hear("sounds/pulse.wav", {2.5f, 0, 2.5f}, false, 0.4);
    const Recording above =
        hear("sounds/pulse.wav", {2.5f, 2.5f, 0}, false, 0.4);  // the same angle from the median plane
    const double expected = woodworth_frames(std::sqrt(0.5f));
    CHECK(itd_frames(front) == doctest::Approx(expected).epsilon(0.03));
    CHECK(std::fabs(itd_frames(back) - itd_frames(front)) < 0.4);
    CHECK(std::fabs(itd_frames(above) - itd_frames(front)) < 0.4);
    // above the head and below it: no difference between the ears
    const Recording over = hear("sounds/pulse.wav", {0, 3, 0}, false, 0.4);
    CHECK(std::fabs(itd_frames(over)) < 0.3);
}

TEST_CASE("hrtf: the head shadows the high frequencies of the far ear more than the low ones") {
    // a sound to the right, for 0.4 s of a loop: measured over the last 0.2 s
    const auto far_over_near = [&](const char* clip) {
        const Recording rec = hear(clip, {3, 0, 0}, true, 0.4);
        const std::size_t from = rec.frames() / 2, to = rec.frames();
        const double near = rms(rec.r, from, to), far = rms(rec.l, from, to);
        CHECK(near > 0.05);
        return far / near;
    };
    const double low = far_over_near("sounds/low.wav"), high = far_over_near("sounds/high.wav");
    CHECK(low == doctest::Approx(0.708).epsilon(0.06));  // the broadband 3 dB of a sound at 90 degrees
    CHECK(high < 0.5 * low);
    CHECK(high < 0.2);
    // a sound straight ahead is the same in both ears at any frequency
    const Recording ahead = hear("sounds/high.wav", {0, 0, -3}, true, 0.4);
    CHECK(rms(ahead.l, ahead.frames() / 2, ahead.frames()) ==
          doctest::Approx(rms(ahead.r, ahead.frames() / 2, ahead.frames())).epsilon(0.02));
}

TEST_CASE("hrtf: a stereo clip is heard as the mix of its two channels, with the time and level of the place") {
    const Recording ahead = hear("sounds/left_only.wav", {0, 0, -3}, false, 0.4);
    CHECK(ahead.peak_l() > 0.1f);
    CHECK(ahead.peak_l() == doctest::Approx(ahead.peak_r()).epsilon(0.02));  // not the file's left channel only
    const Recording right = hear("sounds/left_only.wav", {3, 0, 0}, false, 0.4);
    CHECK(itd_frames(right) == doctest::Approx(woodworth_frames(1.0f)).epsilon(0.03));
}

TEST_CASE("hrtf: a source that sweeps from one side to the other makes no click") {
    Fixture fx;
    write_sine_wav(fx.dir / "sounds/tone.wav", 1.0, 300.0, 0.5);
    Scene sc;
    Entity s = sc.source("sounds/tone.wav", {-6, 0, -1}, true);
    fx.audio.start_recording();
    for (int i = 0; i < 6; ++i) tick(fx, sc);
    // across the front in 0.1 s (a ridiculous speed: the jump is the test), then still
    for (int i = 1; i <= 6; ++i) {
        sc.world.get<Transform>(s)->position = {-6.0f + 2.0f * float(i), 0, -1};
        tick(fx, sc);
    }
    for (int i = 0; i < 12; ++i) tick(fx, sc);
    const Recording rec = fx.finish();
    // a 300 Hz sine of amplitude 0.5 moves by at most 0.0214 per frame; the delay of an ear changing by at most 3% adds a little
    float biggestL = 0.0f, biggestR = 0.0f;
    for (std::size_t i = 2000; i < rec.frames();
         ++i) {  // the first 2000 frames are the sound starting (a shelf boosts its onset)
        biggestL = std::max(biggestL, std::fabs(rec.l[i] - rec.l[i - 1]));
        biggestR = std::max(biggestR, std::fabs(rec.r[i] - rec.r[i - 1]));
    }
    CHECK(biggestL < 0.04f);
    CHECK(biggestR < 0.04f);
    // it ended on the right: louder at the right ear, which leads
    const std::size_t from = rec.frames() - 4000;
    CHECK(rms(rec.r, from, rec.frames()) > 1.05 * rms(rec.l, from, rec.frames()));
}

TEST_CASE("hrtf: a sound played at a place follows the listener when it turns") {
    Fixture fx;
    write_sine_wav(fx.dir / "sounds/tone.wav", 1.0, 3000.0, 0.4);
    Scene sc;
    tick(fx, sc);
    SpatialSound sound;
    sound.range = 100000.0f;
    PlayParams params;
    params.loop = true;
    const VoiceId v = fx.audio.play_at(sc.world, "sounds/tone.wav", params, {3, 0, 0}, sound);
    REQUIRE(v != 0);
    CHECK(AudioTestAccess::voice_hrtf(fx.audio, v));
    fx.audio.start_recording();
    for (int i = 0; i < 12; ++i) tick(fx, sc);
    const Recording before = fx.finish("out/before.wav");
    // the listener turns around (yaw 180): the sound is now at its left
    sc.world.get<Transform>(sc.listener)->rotation = {0, 180, 0};
    fx.audio.start_recording();
    for (int i = 0; i < 12; ++i) tick(fx, sc);
    const Recording after = fx.finish("out/after.wav");
    const std::size_t a = before.frames() / 2, b = after.frames() / 2;
    CHECK(rms(before.r, a, before.frames()) > 2.0 * rms(before.l, a, before.frames()));
    CHECK(rms(after.l, b, after.frames()) > 2.0 * rms(after.r, b, after.frames()));
}

TEST_CASE("hrtf: pan is what it always was") {
    Fixture fx;
    // what a spatial source with the default listener is heard as: its volume and pan, read from the voice
    Scene sc(false);
    sc.source("sounds/sine.wav", {30, 0, 0}, true, 100.0f);
    fx.audio.start_recording();
    fx.audio.update(sc.world, kDt);
    const Json voice = fx.audio.active_voices()[0];
    const float volume = voice["volume"].get<float>(), pan = voice["pan"].get<float>();
    const VoiceId id = voice["id"].get<VoiceId>();
    CHECK(volume == doctest::Approx(0.7f));
    CHECK(pan == doctest::Approx(0.6f));
    CHECK_FALSE(AudioTestAccess::voice_hrtf(fx.audio, id));
    for (int i = 0; i < 24; ++i) tick(fx, sc);
    fx.audio.stop(id);
    fx.run(0.05);
    const Recording heard = fx.finish();
    REQUIRE(heard.peak() > 0.1f);
    // the same samples, bit for bit, as a plain sound played with that volume and pan: the mixer's pan path was not touched
    fx.audio.start_recording();
    PlayParams params;
    params.loop = true;
    params.volume = volume;
    params.pan = pan;
    const VoiceId plainId = fx.audio.play("sounds/sine.wav", params);
    REQUIRE(plainId != 0);
    fx.run(0.4);
    fx.audio.stop(plainId);
    fx.run(0.05);
    const Recording plain = fx.finish();
    REQUIRE(heard.frames() == plain.frames());
    CHECK(heard.l == plain.l);
    CHECK(heard.r == plain.r);
}

TEST_CASE("hrtf: a mono output device keeps the pan") {
    Fixture fx;
    // a mono device: the head model would add the ears together
    AudioTestAccess::set_device_channels(fx.audio, 1);
    Scene sc;
    sc.source("sounds/sine.wav", {30, 0, 0}, true, 100.0f);
    for (int i = 0; i < 3; ++i) tick(fx, sc);
    const Json voices = fx.audio.active_voices();
    REQUIRE(voices.size() == 1);
    CHECK_FALSE(AudioTestAccess::voice_hrtf(fx.audio, voices[0]["id"].get<VoiceId>()));
    CHECK(voices[0]["pan"].get<float>() == doctest::Approx(0.6f));
}

TEST_CASE("hrtf: a camera as the listener (a 2D game) keeps the pan") {
    Fixture fx;
    World world;  // no AudioListener: the primary camera hears
    Entity cam = world.create("cam", "cam");
    world.add<Camera>(cam).primary = true;
    Entity s = world.create("src", "src");
    AudioSource& src = world.add<AudioSource>(s);
    src.clip = "sounds/sine.wav";
    src.playOnStart = true;
    src.loop = true;
    src.spatial = true;
    src.range = 100.0f;
    world.get<Transform>(s)->position = {30, 0, 0};
    for (int i = 0; i < 3; ++i) {
        fx.audio.update(world, kDt);
        fx.audio.advance_null_device(kDt);
    }
    const Json voices = fx.audio.active_voices();
    REQUIRE(voices.size() == 1);
    CHECK_FALSE(AudioTestAccess::voice_hrtf(fx.audio, voices[0]["id"].get<VoiceId>()));
    CHECK(voices[0]["pan"].get<float>() == doctest::Approx(0.6f));
}

TEST_CASE("hrtf: an AudioListener with hrtf puts a spatial source under the head model") {
    Fixture fx;
    Scene sc;
    sc.source("sounds/sine.wav", {30, 0, 0}, true, 100.0f);
    for (int i = 0; i < 3; ++i) tick(fx, sc);
    REQUIRE(fx.audio.active_voices().size() == 1);
    CHECK(AudioTestAccess::voice_hrtf(fx.audio, fx.audio.active_voices()[0]["id"].get<VoiceId>()));
}

TEST_CASE("hrtf: switching the listener back to pan puts the voice back to the pan") {
    Fixture fx;
    Scene sc;
    sc.source("sounds/sine.wav", {30, 0, 0}, true, 100.0f);
    for (int i = 0; i < 3; ++i) tick(fx, sc);
    const VoiceId v = fx.audio.active_voices()[0]["id"].get<VoiceId>();
    CHECK(AudioTestAccess::voice_hrtf(fx.audio, v));
    sc.world.get<AudioListener>(sc.listener)->spatialization = AudioSpatialization::Pan;
    for (int i = 0; i < 3; ++i) tick(fx, sc);
    CHECK_FALSE(AudioTestAccess::voice_hrtf(fx.audio, v));
}

TEST_CASE("hrtf: a head the model does not take is clamped, and the warning says how to fix it, once") {
    struct Lines {
        std::mutex mu;
        std::vector<std::string> warnings;
    };
    auto lines = std::make_shared<Lines>();
    const int sink = add_log_sink([lines](const LogEntry& e) {
        if (e.level != LogLevel::Warn || e.category != "audio") return;
        std::lock_guard<std::mutex> lk(lines->mu);
        lines->warnings.push_back(e.message);
    });
    Fixture fx;
    write_clips(fx.dir);
    // a head of 8.75 in a world of meters (a pixel game that forgot speedOfSound)
    Scene sc(true, 8.75f, 343.0f);
    sc.source("sounds/pulse.wav", {3, 0, 0}, false);
    fx.audio.start_recording();
    for (int i = 0; i < 24; ++i) tick(fx, sc);
    const Recording rec = fx.finish();
    remove_log_sink(sink);
    // the head is the largest the model takes, not 100 times that
    CHECK(itd_frames(rec) == doctest::Approx(woodworth_frames(1.0f, kHrtfMaxHeadRadius)).epsilon(0.03));
    std::lock_guard<std::mutex> lk(lines->mu);
    REQUIRE(lines->warnings.size() == 1);  // 24 updates, one line
    const std::string& w = lines->warnings[0];
    CHECK(w.find("headRadius") != std::string::npos);
    CHECK(w.find("speedOfSound") != std::string::npos);
    CHECK(w.find("hint") != std::string::npos);
}

TEST_CASE("hrtf: mixing under the head model allocates nothing") {
    if constexpr (!AllocCounter::available) {
        MESSAGE("skipped: a sanitizer build owns the global operator new, so nothing is counted");
        return;
    }
    Fixture fx;
    write_sine_wav(fx.dir / "sounds/tone.wav", 1.0, 700.0, 0.4);
    Scene sc;
    for (int i = 0; i < 6; ++i)
        sc.source("sounds/tone.wav", {float(i) - 2.5f, float(i % 3), -3}, true, 100.0f, "s" + std::to_string(i));
    tick(fx, sc);
    REQUIRE(fx.audio.active_voices().size() == 6);
    fx.run(0.2);  // warm-up
    AllocCounter::Scope scope;
    fx.run(1.0);
    CHECK_MESSAGE(scope.count() == 0, "the mixer allocated " << scope.count() << " times while mixing 60 steps");
}

namespace {
// The warnings the audio category logs while `body` runs.
std::vector<std::string> audio_warnings_during(const std::function<void()>& body) {
    struct Lines {
        std::mutex mu;
        std::vector<std::string> warnings;
    };
    auto lines = std::make_shared<Lines>();
    const int sink = add_log_sink([lines](const LogEntry& e) {
        if (e.level != LogLevel::Warn || e.category != "audio") return;
        std::lock_guard<std::mutex> lk(lines->mu);
        lines->warnings.push_back(e.message);
    });
    body();
    remove_log_sink(sink);
    std::lock_guard<std::mutex> lk(lines->mu);
    return lines->warnings;
}

bool all_finite(const Recording& rec) {
    return std::all_of(rec.l.begin(), rec.l.end(), [](float v) { return std::isfinite(v); }) &&
           std::all_of(rec.r.begin(), rec.r.end(), [](float v) { return std::isfinite(v); });
}

// The biggest step between two frames of one channel.
float biggest_step(const std::vector<float>& x, std::size_t from = 0) {
    float step = 0.0f;
    for (std::size_t i = std::max<std::size_t>(from, 1); i < x.size(); ++i)
        step = std::max(step, std::fabs(x[i] - x[i - 1]));
    return step;
}
}  // namespace

TEST_CASE("hrtf: a position or a head that is not a number never reaches the sound") {
    const float inf = std::numeric_limits<float>::infinity(), nan = std::numeric_limits<float>::quiet_NaN();
    Fixture fx;
    write_clips(fx.dir);
    Scene sc(true, nan, nan);  // a head and a speed of sound that are not numbers
    Entity src = sc.source("sounds/tone.wav", {inf, 0, 0}, true, 100000.0f);
    fx.audio.start_recording();
    const std::vector<std::string> warnings = audio_warnings_during([&] {
        for (int i = 0; i < 12; ++i) tick(fx, sc);  // a source at infinity
        sc.world.get<Transform>(src)->position = {nan, 0, 0};
        for (int i = 0; i < 12; ++i) tick(fx, sc);  // at a place that is no place
        sc.world.get<Transform>(sc.listener)->position = {inf, inf, inf};
        for (int i = 0; i < 12; ++i) tick(fx, sc);  // and the listener too
        sc.world.get<Transform>(sc.listener)->position = {0, 0, 0};
        sc.world.get<Transform>(src)->position = {30, 0, 0};
        sc.world.get<AudioListener>(sc.listener)->headRadius = 0.0875f;
        sc.world.get<AudioListener>(sc.listener)->speedOfSound = 343.0f;
        for (int i = 0; i < 24; ++i) tick(fx, sc);  // everything back to normal
    });
    const Recording rec = fx.finish();
    CHECK(all_finite(rec));
    // the voice was not poisoned: the sound is there once the numbers are back, to the right (the source is at +X)
    const std::size_t from = rec.frames() - 4410;
    REQUIRE(rec.frames() > 8820);
    CHECK(rms(rec.r, from, rec.frames()) > 0.05);
    CHECK(rms(rec.r, from, rec.frames()) > rms(rec.l, from, rec.frames()));
    // the head that is not a number is told once, not at every frame
    int headWarnings = 0;
    for (const std::string& w : warnings)
        if (w.find("headRadius") != std::string::npos) ++headWarnings;
    CHECK(headWarnings <= 2);  // the NaN head, and no more until it changes (the normal head is not told)
    CHECK(headWarnings >= 1);
}

TEST_CASE("hrtf: switching between pan and hrtf while a voice plays makes no click") {
    Fixture fx;
    write_clips(fx.dir);
    Scene sc(false);
    sc.source("sounds/tone.wav", {30, 0, 0}, true, 100.0f);
    for (int i = 0; i < 6; ++i) tick(fx, sc);
    const VoiceId v = fx.audio.active_voices()[0]["id"].get<VoiceId>();
    fx.audio.start_recording();
    for (int i = 0; i < 6; ++i) tick(fx, sc);
    sc.world.get<AudioListener>(sc.listener)->spatialization = AudioSpatialization::Hrtf;
    for (int i = 0; i < 12; ++i) tick(fx, sc);
    CHECK(AudioTestAccess::voice_hrtf(fx.audio, v));
    sc.world.get<AudioListener>(sc.listener)->spatialization = AudioSpatialization::Pan;
    for (int i = 0; i < 12; ++i) tick(fx, sc);
    CHECK_FALSE(AudioTestAccess::voice_hrtf(fx.audio, v));
    const Recording rec = fx.finish();
    REQUIRE(rec.peak() > 0.1f);
    // a 300 Hz tone of amplitude 0.5 changes by at most 0.04 between two frames; a start from an empty delay line or a jump from the
    // pan to the head's level would step by far more
    CHECK(biggest_step(rec.l) < 0.05f);
    CHECK(biggest_step(rec.r) < 0.05f);
}

TEST_CASE("hrtf: a voice that starts under the head model has no step at its first frames") {
    Fixture fx;
    write_clips(fx.dir);
    Scene sc;
    fx.audio.start_recording();
    sc.source("sounds/tone.wav", {30, 0, 0}, true, 100.0f);
    for (int i = 0; i < 6; ++i) tick(fx, sc);
    const Recording rec = fx.finish();
    REQUIRE(rec.peak() > 0.1f);
    CHECK(biggest_step(rec.l) < 0.05f);
    CHECK(biggest_step(rec.r) < 0.05f);
}

TEST_CASE("hrtf: an output of more than two channels keeps the pan, as a mono one does") {
    Fixture fx;
    AudioTestAccess::set_device_channels(fx.audio, 6);  // 5.1
    Scene sc;
    sc.source("sounds/sine.wav", {30, 0, 0}, true, 100.0f);
    for (int i = 0; i < 3; ++i) tick(fx, sc);
    const Json voices = fx.audio.active_voices();
    REQUIRE(voices.size() == 1);
    CHECK_FALSE(AudioTestAccess::voice_hrtf(fx.audio, voices[0]["id"].get<VoiceId>()));
    CHECK(voices[0]["pan"].get<float>() == doctest::Approx(0.6f));
}

TEST_CASE("hrtf: at 192 kHz the largest head's time difference is not cut short") {
    Fixture fx;
    write_clips(fx.dir);
    constexpr int kDeviceRate = 192000;
    AudioTestAccess::use_manual_device(fx.audio, kDeviceRate);
    Scene sc(true, kHrtfMaxHeadRadius, 343.0f);
    sc.source("sounds/pulse.wav", {1, 0, 0}, false);
    std::vector<float> l, r, block(512 * 2);
    for (int i = 0; i < 24; ++i) {
        fx.audio.update(sc.world, kDt);
        for (int b = 0; b < 6; ++b) {  // 3072 frames, a little under a frame of 1/60 s
            AudioTestAccess::render(fx.audio, block.data(), 512, 2);
            for (int k = 0; k < 512; ++k) {
                l.push_back(block[std::size_t(2 * k)]);
                r.push_back(block[std::size_t(2 * k + 1)]);
            }
        }
    }
    const double itd = centroid(l) - centroid(r);
    const double expected = double(audio_hrtf_itd(1.0f, kHrtfMaxHeadRadius / 343.0f)) * kDeviceRate;
    CHECK(expected >
          150.0);  // about 173 frames: a delay line sized in frames of 44.1 kHz (about 40 at most) would cut it short
    CHECK(itd == doctest::Approx(expected).epsilon(0.05));
}
