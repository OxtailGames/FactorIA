#include <doctest.h>

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <cstring>
#include <filesystem>

#include "fa/audio/audio.h"
#include "fa/core/fs.h"
#include "fa/core/log.h"

using namespace fa;

namespace {

// Writes a 16-bit mono PCM WAV sine wave (own writer, independent from the engine's).
void write_sine_wav(const std::filesystem::path& file, double seconds, double freq = 440.0, double amp = 0.5, int rate = 44100) {
    std::size_t n = std::size_t(seconds * rate);
    std::vector<std::uint8_t> b;
    auto u32 = [&](std::uint32_t v) { for (int i = 0; i < 4; ++i) b.push_back(std::uint8_t(v >> (8 * i))); };
    auto u16 = [&](std::uint16_t v) { b.push_back(std::uint8_t(v)); b.push_back(std::uint8_t(v >> 8)); };
    auto tag = [&](const char* s) { for (int i = 0; i < 4; ++i) b.push_back(std::uint8_t(s[i])); };
    tag("RIFF"); u32(std::uint32_t(36 + n * 2)); tag("WAVE"); tag("fmt "); u32(16); u16(1); u16(1);
    u32(std::uint32_t(rate)); u32(std::uint32_t(rate * 2)); u16(2); u16(16); tag("data"); u32(std::uint32_t(n * 2));
    for (std::size_t i = 0; i < n; ++i) {
        double s = amp * std::sin(2.0 * 3.14159265358979323846 * freq * double(i) / rate);
        u16(std::uint16_t(std::int16_t(std::lround(s * 32767.0))));
    }
    std::filesystem::create_directories(file.parent_path());
    FILE* f = std::fopen(file.string().c_str(), "wb");
    REQUIRE(f != nullptr);
    std::fwrite(b.data(), 1, b.size(), f);
    std::fclose(f);
}

struct Recording {
    std::vector<float> l, r;
    std::size_t frames() const { return l.size(); }
    float peak(std::size_t from = 0, std::size_t to = SIZE_MAX) const {
        float p = 0;
        for (std::size_t i = from; i < std::min(to, l.size()); ++i) p = std::max({p, std::fabs(l[i]), std::fabs(r[i])});
        return p;
    }
    float peak_l() const { float p = 0; for (float v : l) p = std::max(p, std::fabs(v)); return p; }
    float peak_r() const { float p = 0; for (float v : r) p = std::max(p, std::fabs(v)); return p; }
    // index one past the last non-silent frame
    std::size_t sound_end(float thr = 0.01f) const {
        for (std::size_t i = l.size(); i > 0; --i) if (std::fabs(l[i - 1]) > thr || std::fabs(r[i - 1]) > thr) return i;
        return 0;
    }
};

Recording read_wav16(const std::string& path) {
    auto bytes = fs::read_bytes(path);
    REQUIRE(bytes.ok());
    const auto& d = *bytes;
    REQUIRE(d.size() >= 44);
    CHECK(std::memcmp(d.data(), "RIFF", 4) == 0);
    CHECK(std::memcmp(d.data() + 8, "WAVE", 4) == 0);
    Recording rec;
    std::size_t n = (d.size() - 44) / 4;
    for (std::size_t i = 0; i < n; ++i) {
        auto s = [&](std::size_t off) { return float(std::int16_t(d[44 + i * 4 + off] | (d[44 + i * 4 + off + 1] << 8))) / 32768.0f; };
        rec.l.push_back(s(0));
        rec.r.push_back(s(2));
    }
    return rec;
}

struct Fixture {
    std::filesystem::path dir;
    Audio audio;
    Fixture() {
        dir = fs::make_temp_dir("factoria_audio_test");
        fs::set_project_root(dir);
        write_sine_wav(dir / "sounds/sine.wav", 1.0);
        std::string err;
        REQUIRE(audio.init(false, &err));
    }
    ~Fixture() {
        audio.shutdown();
        std::filesystem::remove_all(dir);
    }
    // advance in 1/60 s engine frames
    void run(double seconds) {
        int frames = int(std::lround(seconds * 60.0));
        for (int i = 0; i < frames; ++i) audio.advance_null_device(1.0 / 60.0);
    }
    Recording finish(const char* name = "out/rec.wav") {
        std::string err;
        REQUIRE_MESSAGE(audio.stop_recording(name, &err), err);
        return read_wav16(name);
    }
};

}  // namespace

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
    CHECK(measure(p).peak() == doctest::Approx(0.25f).epsilon(0.03));
    PlayParams ui;
    ui.bus = "ui";
    CHECK(measure(ui).peak() == doctest::Approx(0.5f).epsilon(0.03));
    fx.audio.set_bus_volume("sfx", 1.0f);
    fx.audio.set_master_volume(0.5f);
    CHECK(fx.audio.bus_volume("master") == 0.5f);
    CHECK(measure(p).peak() == doctest::Approx(0.25f).epsilon(0.03));
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
    for (int i = 0; i < 30; ++i) { fx.audio.update(world, 1.0f / 60.0f); fx.audio.advance_null_device(1.0 / 60.0); }
    CHECK(world.get<AudioSource>(e)->playing);
    for (int i = 0; i < 60; ++i) { fx.audio.update(world, 1.0f / 60.0f); fx.audio.advance_null_device(1.0 / 60.0); }
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
        for (int i = 0; i < 12; ++i) { fx.audio.update(world, 1.0f / 60.0f); fx.audio.advance_null_device(1.0 / 60.0); }
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
        PlayParams a; a.pitch = 1.37f; a.pan = 0.3f;
        PlayParams b; b.loop = true; b.pitch = 0.81f; b.volume = 0.4f;
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
