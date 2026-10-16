// Loudness (ITU-R BS.1770-4 / EBU R128), normalization, and the .qoa format.
#include <doctest.h>

#include <fstream>
#include <iterator>

#include "audio_test_helpers.h"
#include "fa/audio/analysis.h"
#include "fa/audio/audio.h"
#include "fa/audio/convert.h"
#include "fa/core/fs.h"
#include "fa/core/log.h"

using namespace fa;
using namespace audio_test;

namespace {

Loudness measure(const std::vector<float>& mono, int rate) {
    auto m = measure_loudness(wav_bytes(mono, 1, rate), ".wav");
    REQUIRE_MESSAGE(m.ok(), (m.ok() ? "" : m.error().to_string()));
    return *m;
}

// The Json of assets.json for one asset's import settings.
std::string assets_json(const std::string& path, const std::string& importSettings, const std::string& analysis = "{}") {
    return R"({"format": "factoria.assets/1", "assets": {")" + path + R"(": {"import": )" + importSettings + R"(, "analysis": )" + analysis + "}}}";
}

float recorded_peak(Fixture& fx, const char* clip, PlayParams p = {}, double seconds = 1.0) {
    fx.audio.stop_all();
    fx.audio.start_recording();
    fx.audio.play(clip, p);
    fx.run(seconds);
    return fx.finish().peak();
}

}  // namespace

TEST_CASE("loudness: a 1 kHz sine at -23 dBFS reads -23 LUFS at any sample rate") {
    // EBU Tech 3341, test 1: the filters are derived for each rate, not the 48 kHz values of the standard.
    for (int rate : {48000, 44100, 22050, 16000}) {
        CAPTURE(rate);
        std::vector<float> s;
        add_sine(s, 20.0, 1000.0, dbfs(-23.0), rate);
        const Loudness l = measure(s, rate);
        CHECK(l.integratedLufs == doctest::Approx(-23.0).epsilon(0.1 / 23.0));  // +-0.1 LU
        CHECK(l.peakDb == doctest::Approx(-23.0).epsilon(0.1 / 23.0));
        CHECK(l.seconds == doctest::Approx(20.0));
    }
}

TEST_CASE("loudness: both sides count, a mono clip counts as the same sound on both") {
    std::vector<float> tone, stereo, silent;
    add_sine(tone, 10.0, 1000.0, dbfs(-23.0), 44100);
    for (float s : tone) {  // left only: half the power of the same tone on both sides
        stereo.push_back(s);
        stereo.push_back(0.0f);
    }
    auto left = measure_loudness(wav_bytes(stereo, 2, 44100), ".wav");
    REQUIRE(left.ok());
    CHECK(left->integratedLufs == doctest::Approx(-26.0).epsilon(0.1 / 26.0));
    CHECK(measure(tone, 44100).integratedLufs == doctest::Approx(-23.0).epsilon(0.1 / 23.0));
}

TEST_CASE("loudness: the gates leave out silence and passages 10 LU below the rest") {
    const int rate = 44100;
    std::vector<float> silence, a, b;
    add_sine(a, 10.0, 0.0, 0.0, rate);  // 10 s of digital silence
    add_sine(a, 20.0, 1000.0, dbfs(-23.0), rate);
    add_sine(a, 10.0, 0.0, 0.0, rate);
    CHECK(measure(a, rate).integratedLufs == doctest::Approx(-23.0).epsilon(0.1 / 23.0));  // absolute gate, -70 LUFS

    // EBU Tech 3341, test 5 style: a long passage at -23 between quieter ones at -36 (more than 10 LU below)
    add_sine(b, 10.0, 1000.0, dbfs(-36.0), rate);
    add_sine(b, 60.0, 1000.0, dbfs(-23.0), rate);
    add_sine(b, 10.0, 1000.0, dbfs(-36.0), rate);
    CHECK(measure(b, rate).integratedLufs == doctest::Approx(-23.0).epsilon(0.1 / 23.0));  // relative gate

    std::vector<float> faint;  // nothing above -70 LUFS
    add_sine(faint, 20.0, 1000.0, dbfs(-75.0), rate);
    const Loudness f = measure(faint, rate);
    CHECK(f.integratedLufs == kSilentLufs);
    CHECK(f.peakDb == doctest::Approx(-75.0).epsilon(0.01));
    CHECK_FALSE(measure_loudness(wav_bytes(silence, 1, rate), ".wav").ok());  // no samples at all
}

TEST_CASE("loudness: a clip shorter than one 400 ms block is measured as that block padded with silence") {
    std::vector<float> blip;
    add_sine(blip, 0.1, 1000.0, dbfs(-3.0), 44100);  // a quarter of a block: 6 dB below the same tone held
    CHECK(measure(blip, 44100).integratedLufs == doctest::Approx(-9.0).epsilon(0.4 / 9.0));
}

TEST_CASE("loudness: measures what the engine decodes, ogg and qoa included") {
    std::ifstream in(std::filesystem::path(FA_REPO_ROOT) / "engine/audio/tests/fixtures/music_3min.ogg", std::ios::binary);
    REQUIRE(in.good());
    const std::vector<std::uint8_t> ogg((std::istreambuf_iterator<char>(in)), std::istreambuf_iterator<char>());
    auto m = measure_loudness(ogg, ".ogg");
    REQUIRE_MESSAGE(m.ok(), (m.ok() ? "" : m.error().to_string()));
    CHECK(m->seconds == doctest::Approx(180.0).epsilon(0.001));
    CHECK(m->peakDb > -6.5);  // the beeps (0.5 over the 0.05 tone, a little more after Vorbis)
    CHECK(m->peakDb < -3.5);
    CHECK(m->integratedLufs == doctest::Approx(-23.0).epsilon(0.08));  // the 0.05 tone and a beep in every 100 ms of 10 s

    std::vector<float> tone;
    add_sine(tone, 5.0, 1000.0, dbfs(-20.0), 44100);
    auto q = encode_qoa(wav_bytes(tone, 1, 44100));
    REQUIRE(q.ok());
    auto lq = measure_loudness(*q, ".qoa");
    REQUIRE(lq.ok());
    CHECK(lq->integratedLufs == doctest::Approx(measure(tone, 44100).integratedLufs).epsilon(0.01));

    CHECK_FALSE(measure_loudness(ogg, ".wav").ok());
    CHECK_FALSE(measure_loudness(ogg, ".flac").ok());
    CHECK_FALSE(measure_loudness(std::vector<std::uint8_t>{}, ".wav").ok());
}

TEST_CASE("loudness: the gain reaches the target, within 24 dB and without passing -1 dBFS") {
    CHECK(normalization_gain_db({-20.0, -6.0, 5.0}, -16.0) == doctest::Approx(4.0));
    CHECK(normalization_gain_db({-10.0, -6.0, 5.0}, -16.0) == doctest::Approx(-6.0));
    CHECK(normalization_gain_db({-60.0, -50.0, 5.0}, -16.0) == doctest::Approx(24.0));      // clamped
    CHECK(normalization_gain_db({-20.0, -5.0, 5.0}, -16.0) == doctest::Approx(4.0));         // peak -1 dBFS reached exactly
    CHECK(normalization_gain_db({-30.0, -3.0, 5.0}, -16.0) == doctest::Approx(2.0));         // 14 dB wanted, 2 dB left to -1 dBFS
    CHECK(normalization_gain_db({kSilentLufs, -200.0, 5.0}, -16.0) == 0.0);                  // nothing to scale
}

TEST_CASE("loudness: the analysis record is kept only while it describes the same file") {
    std::vector<float> tone;
    add_sine(tone, 2.0, 1000.0, 0.1, 44100);
    const std::vector<std::uint8_t> bytes = wav_bytes(tone, 1, 44100);
    const Loudness l = measure(tone, 44100);
    const Json record = loudness_analysis(l, bytes);
    CHECK(record["bytes"] == bytes.size());
    CHECK(record["sha256"].get<std::string>().size() == 64);

    auto fresh = cached_loudness(record, bytes);
    REQUIRE(fresh.has_value());
    CHECK(fresh->integratedLufs == doctest::Approx(l.integratedLufs).epsilon(0.001));
    std::vector<std::uint8_t> edited = bytes;
    edited[100] ^= 1;  // same length, other content
    CHECK_FALSE(cached_loudness(record, edited).has_value());
    CHECK_FALSE(cached_loudness(record, std::vector<std::uint8_t>(bytes.begin(), bytes.end() - 2)).has_value());
    Json broken = record;
    broken.erase("peakDb");
    CHECK_FALSE(cached_loudness(broken, bytes).has_value());
    broken = record;
    broken["loudnessLufs"] = "loud";
    CHECK_FALSE(cached_loudness(broken, bytes).has_value());
    CHECK_FALSE(cached_loudness(Json(), bytes).has_value());
}

TEST_CASE("normalize: every way of playing a clip applies the gain that reaches targetLufs") {
    Fixture fx;
    write_sine_wav(fx.dir / "sounds/quiet.wav", 3.0, 1000.0, 0.1);  // -20 LUFS
    fx.write_assets(assets_json("sounds/quiet.wav", R"({"normalize": true, "targetLufs": -16})"));
    const float want = float(0.1 * dbfs(4.0));  // +4 dB

    CHECK(recorded_peak(fx, "sounds/quiet.wav") == doctest::Approx(want).epsilon(0.02));
    PlayParams half;
    half.volume = 0.5f;
    CHECK(recorded_peak(fx, "sounds/quiet.wav", half) == doctest::Approx(want * 0.5f).epsilon(0.02));  // on top of the volume

    fx.audio.stop_all();
    fx.audio.start_recording();
    fx.audio.play_music("sounds/quiet.wav", 1.0f, 0.0f);
    fx.run(1.0);
    CHECK(fx.finish().peak() == doctest::Approx(want).epsilon(0.02));

    World world;
    Entity e = world.create("src", "src");
    AudioSource& src = world.add<AudioSource>(e);
    src.clip = "sounds/quiet.wav";
    src.playOnStart = true;
    fx.audio.stop_all();
    fx.audio.start_recording();
    for (int i = 0; i < 60; ++i) {
        fx.audio.update(world, 1.0f / 60.0f);
        fx.audio.advance_null_device(1.0 / 60.0);
    }
    CHECK(fx.finish().peak() == doctest::Approx(want).epsilon(0.02));
}

TEST_CASE("normalize: off by default, applied to a streamed clip, limited to 24 dB and to -1 dBFS") {
    Fixture fx;
    write_sine_wav(fx.dir / "sounds/plain.wav", 1.0, 1000.0, 0.1);
    write_sine_wav(fx.dir / "sounds/streamed.wav", 12.0, 1000.0, 0.1);
    write_sine_wav(fx.dir / "sounds/faint.wav", 1.0, 1000.0, 0.0005);
    std::vector<float> spiky;  // quiet, with one loud sample: it can only be raised until that one reaches -1 dBFS
    add_sine(spiky, 3.0, 1000.0, 0.05, 44100);
    spiky[2000] = 0.8f;
    write_file(fx.dir / "sounds/spiky.wav", wav_bytes(spiky, 1, 44100));
    fx.write_assets(R"({"format": "factoria.assets/1", "defaults": {"audio": {"targetLufs": -16}}, "assets": {
        "sounds/streamed.wav": {"import": {"normalize": true}},
        "sounds/faint.wav": {"import": {"normalize": true}},
        "sounds/spiky.wav": {"import": {"normalize": true}}}})");

    CHECK(recorded_peak(fx, "sounds/plain.wav") == doctest::Approx(0.1f).epsilon(0.02));  // normalize is off
    CHECK(recorded_peak(fx, "sounds/streamed.wav", {}, 2.0) == doctest::Approx(float(0.1 * dbfs(4.0))).epsilon(0.02));
    CHECK(fx.audio.stats()["streamedClips"].size() == 1);

    CHECK(recorded_peak(fx, "sounds/faint.wav") == doctest::Approx(float(0.0005 * dbfs(24.0))).epsilon(0.02));  // +24 dB, no more
    CHECK(recorded_peak(fx, "sounds/spiky.wav") <= float(dbfs(-1.0)) * 1.002f);
    CHECK(recorded_peak(fx, "sounds/spiky.wav") > float(dbfs(-1.0)) * 0.97f);  // and it did reach it
}

TEST_CASE("normalize: uses the measurement assets.json holds for the file, and measures when it is stale") {
    Fixture fx;
    write_sine_wav(fx.dir / "sounds/tone.wav", 2.0, 1000.0, 0.1);  // really -20 LUFS
    const std::vector<std::uint8_t> bytes = *fs::read_bytes("sounds/tone.wav");
    const char* on = R"({"normalize": true, "targetLufs": -16})";

    // a recorded measurement that says -30 LUFS is believed: +14 dB, with no measuring (and so no log line about it)
    Json analysis = loudness_analysis({-30.0, -20.0, 2.0}, bytes);
    fx.write_assets(assets_json("sounds/tone.wav", on, analysis.dump()));
    clear_recent_logs();
    CHECK(recorded_peak(fx, "sounds/tone.wav") == doctest::Approx(float(0.1 * dbfs(14.0))).epsilon(0.02));
    for (const LogEntry& line : recent_logs(20, LogLevel::Info)) CHECK(line.message.find("measured") == std::string::npos);

    // the file changed after the measurement: it is stale, so the engine measures the file it has
    Audio fresh;
    std::string err;
    write_sine_wav(fx.dir / "sounds/tone.wav", 2.0, 1000.0, 0.2);  // really -14 LUFS
    REQUIRE(fresh.init(false, &err));
    fresh.start_recording();
    fresh.play("sounds/tone.wav");
    for (int i = 0; i < 60; ++i) fresh.advance_null_device(1.0 / 60.0);
    CHECK(fresh.stop_recording("out/stale.wav", &err));
    CHECK(read_wav16("out/stale.wav").peak() == doctest::Approx(float(0.2 * dbfs(-2.0))).epsilon(0.02));
    bool logged = false;
    for (const LogEntry& line : recent_logs(20, LogLevel::Info)) logged |= line.message.find("measured 'sounds/tone.wav'") != std::string::npos;
    CHECK(logged);

    // reload_clip measures the new file too
    write_sine_wav(fx.dir / "sounds/tone.wav", 2.0, 1000.0, 0.05);  // -26 LUFS: +10 dB
    fresh.reload_clip("sounds/tone.wav");
    fresh.start_recording();
    fresh.stop_all();
    fresh.play("sounds/tone.wav");
    for (int i = 0; i < 60; ++i) fresh.advance_null_device(1.0 / 60.0);
    CHECK(fresh.stop_recording("out/reloaded.wav", &err));
    CHECK(read_wav16("out/reloaded.wav").peak() == doctest::Approx(float(0.05 * dbfs(10.0))).epsilon(0.02));
    fresh.shutdown();
}

namespace {

std::vector<std::uint8_t> two_tone_wav(double seconds, int rate) {
    std::vector<float> l, r, st;
    add_sine(l, seconds, 330.0, 0.5, rate);
    add_sine(r, seconds, 550.0, 0.25, rate);
    for (std::size_t i = 0; i < l.size(); ++i) {
        st.push_back(l[i]);
        st.push_back(r[i]);
    }
    return wav_bytes(st, 2, rate);
}

bool streams_clip(Fixture& fx, const char* clip) {
    const Json stats = fx.audio.stats();
    for (const Json& name : stats["streamedClips"])
        if (name == clip) return true;
    return false;
}

}  // namespace

TEST_CASE("qoa: a WAV becomes a file under a quarter of its size that plays as the same sound") {
    Fixture fx;
    const std::vector<std::uint8_t> wav = two_tone_wav(3.0, 44100);
    auto q = encode_qoa(wav);
    REQUIRE_MESSAGE(q.ok(), (q.ok() ? "" : q.error().to_string()));
    CHECK(q->size() < wav.size() / 4);
    CHECK(q->size() > wav.size() / 8);
    write_file(fx.dir / "sounds/two.qoa", *q);
    write_file(fx.dir / "sounds/two.wav", wav);

    fx.audio.start_recording();
    fx.audio.play("sounds/two.qoa");
    fx.run(3.2);
    Recording lossy = fx.finish();
    CHECK(lossy.peak_l() == doctest::Approx(0.5f).epsilon(0.05));
    CHECK(lossy.peak_r() == doctest::Approx(0.25f).epsilon(0.05));
    CHECK(lossy.sound_end() == doctest::Approx(3.0 * 44100).epsilon(0.002));
    fx.audio.stop_all();
    fx.audio.start_recording();
    fx.audio.play("sounds/two.wav");
    fx.run(3.2);
    Recording exact = fx.finish();
    REQUIRE(exact.frames() == lossy.frames());
    double err = 0.0, ref = 0.0;  // QOA is lossy but close: a signal-to-error ratio well over 25 dB
    for (std::size_t i = 0; i < exact.frames(); ++i) {
        err += std::pow(exact.l[i] - lossy.l[i], 2) + std::pow(exact.r[i] - lossy.r[i], 2);
        ref += std::pow(exact.l[i], 2) + std::pow(exact.r[i], 2);
    }
    CHECK(10.0 * std::log10(ref / err) > 25.0);
}

TEST_CASE("qoa: a missing clip is read from its twin, with the import settings of the clip asked for") {
    Fixture fx;
    auto q = encode_qoa(two_tone_wav(2.0, 44100));
    REQUIRE(q.ok());
    write_file(fx.dir / "sounds/shipped.wav.qoa", *q);  // what an export leaves of sounds/shipped.wav
    fx.write_assets(R"({"format": "factoria.assets/1", "assets": {"sounds/shipped.wav": {"import": {"stream": "always"}}}})");

    CHECK(fx.audio.load("sounds/shipped.wav"));
    CHECK(streams_clip(fx, "sounds/shipped.wav"));  // the setting is keyed by the original path
    fx.audio.start_recording();
    VoiceId v = fx.audio.play("sounds/shipped.wav");
    CHECK(v != 0);
    fx.run(2.3);
    Recording rec = fx.finish();
    CHECK(rec.peak_l() == doctest::Approx(0.5f).epsilon(0.05));
    CHECK(rec.sound_end() == doctest::Approx(2.0 * 44100).epsilon(0.003));
    CHECK(fx.audio.play_log().back().ok);

    // the file wins when both exist, and a clip with neither says what to do
    write_sine_wav(fx.dir / "sounds/shipped.wav", 1.0, 440.0, 0.9);
    fx.audio.reload_clip("sounds/shipped.wav");
    CHECK(recorded_peak(fx, "sounds/shipped.wav") == doctest::Approx(0.9f).epsilon(0.02));
    clear_recent_logs();
    CHECK(fx.audio.play("sounds/nothing.wav") == 0);
    bool taught = false;
    for (const LogEntry& line : recent_logs(20, LogLevel::Warn)) taught |= line.message.find("sounds/nothing.wav") != std::string::npos;
    CHECK(taught);
}

TEST_CASE("qoa: a streamed .qoa plays like the same file decoded whole, and bad input is refused") {
    Fixture fx;
    auto q = encode_qoa(two_tone_wav(2.5, 44100));
    REQUIRE(q.ok());
    write_file(fx.dir / "sounds/a.qoa", *q);
    write_file(fx.dir / "sounds/b.qoa", *q);
    fx.write_assets(R"({"format": "factoria.assets/1", "assets": {"sounds/a.qoa": {"import": {"stream": "always"}},
        "sounds/b.qoa": {"import": {"stream": "never"}}}})");
    PlayParams looped;
    looped.loop = true;
    looped.pitch = 0.9f;
    fx.audio.start_recording();
    fx.audio.play("sounds/a.qoa", looped);
    fx.run(6.0);
    Recording streamed = fx.finish();
    fx.audio.stop_all();
    fx.audio.start_recording();
    fx.audio.play("sounds/b.qoa", looped);
    fx.run(6.0);
    Recording whole = fx.finish();
    CHECK(streams_clip(fx, "sounds/a.qoa"));
    CHECK_FALSE(streams_clip(fx, "sounds/b.qoa"));
    REQUIRE(streamed.frames() == whole.frames());
    float worst = 0.0f;
    for (std::size_t i = 0; i < whole.frames(); ++i) worst = std::max(worst, std::fabs(whole.l[i] - streamed.l[i]));
    CHECK(worst < 6.5e-5f);

    std::vector<std::uint8_t> truncated(q->begin(), q->begin() + 20);
    write_file(fx.dir / "sounds/cut.qoa", truncated);
    write_file(fx.dir / "sounds/junk.qoa", std::vector<std::uint8_t>(500, 0x42));
    CHECK_FALSE(fx.audio.load("sounds/cut.qoa"));
    CHECK_FALSE(fx.audio.load("sounds/junk.qoa"));
    CHECK_FALSE(measure_loudness(truncated, ".qoa").ok());

    CHECK_FALSE(encode_qoa(std::vector<std::uint8_t>(64, 0)).ok());  // not a WAV
    std::vector<float> nine(9 * 100, 0.1f);
    auto many = encode_qoa(wav_bytes(nine, 9, 44100));
    REQUIRE_FALSE(many.ok());
    CHECK(many.error().message.find("channel") != std::string::npos);
    CHECK_FALSE(many.error().hint.empty());
}
