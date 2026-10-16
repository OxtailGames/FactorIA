// Shared by the audio tests: WAV writers, a reader for the recorded output, and a project-in-a-temp-folder fixture.
#pragma once

#include <doctest.h>

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <cstring>
#include <filesystem>
#include <numbers>
#include <string>
#include <vector>

#include "fa/audio/audio.h"
#include "fa/core/fs.h"

namespace audio_test {

using namespace fa;

// A 16-bit PCM WAV of interleaved float samples (own writer, independent from the engine's).
inline std::vector<std::uint8_t> wav_bytes(const std::vector<float>& interleaved, int channels, int rate) {
    const std::size_t n = interleaved.size();
    std::vector<std::uint8_t> b;
    auto u32 = [&](std::uint32_t v) { for (int i = 0; i < 4; ++i) b.push_back(std::uint8_t(v >> (8 * i))); };
    auto u16 = [&](std::uint16_t v) { b.push_back(std::uint8_t(v)); b.push_back(std::uint8_t(v >> 8)); };
    auto tag = [&](const char* s) { for (int i = 0; i < 4; ++i) b.push_back(std::uint8_t(s[i])); };
    tag("RIFF"); u32(std::uint32_t(36 + n * 2)); tag("WAVE"); tag("fmt "); u32(16); u16(1); u16(std::uint16_t(channels));
    u32(std::uint32_t(rate)); u32(std::uint32_t(rate * channels * 2)); u16(std::uint16_t(channels * 2)); u16(16);
    tag("data"); u32(std::uint32_t(n * 2));
    for (float s : interleaved) u16(std::uint16_t(std::int16_t(std::lround(std::clamp(s, -1.0f, 1.0f) * 32767.0f))));
    return b;
}

inline void write_file(const std::filesystem::path& file, const std::vector<std::uint8_t>& b) {
    std::filesystem::create_directories(file.parent_path());
    FILE* f = std::fopen(file.string().c_str(), "wb");
    REQUIRE(f != nullptr);
    std::fwrite(b.data(), 1, b.size(), f);
    std::fclose(f);
}

inline double dbfs(double db) { return std::pow(10.0, db / 20.0); }

// `seconds` of a sine, mono, appended to `out`.
inline void add_sine(std::vector<float>& out, double seconds, double freq, double amp, int rate) {
    const std::size_t n = std::size_t(std::lround(seconds * rate));
    for (std::size_t i = 0; i < n; ++i) out.push_back(float(amp * std::sin(2.0 * std::numbers::pi * freq * double(i) / rate)));
}

// A 16-bit mono PCM WAV sine wave.
inline void write_sine_wav(const std::filesystem::path& file, double seconds, double freq = 440.0, double amp = 0.5, int rate = 44100) {
    std::vector<float> s;
    add_sine(s, seconds, freq, amp, rate);
    write_file(file, wav_bytes(s, 1, rate));
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

inline Recording read_wav16(const std::string& path) {
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
    // Import settings of the project (assets.json). Write it before the first play of the clips it describes.
    void write_assets(const std::string& json) { REQUIRE(fs::write_text("assets.json", json).ok()); }
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

}  // namespace audio_test
