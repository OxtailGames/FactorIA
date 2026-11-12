// Audio benchmarks: the software mixer, offline (the null device), two seconds of audio per run.
#include <cmath>
#include <cstdint>
#include <filesystem>
#include <fstream>
#include <memory>
#include <string>
#include <vector>

#include "benches.h"
#include "fa/audio/audio.h"
#include "fa/core/fs.h"
#include "fa/core/math.h"

namespace fa::bench {

namespace {

// A mono 16-bit WAV of two seconds: a sine and two harmonics (the samples only need to be something other than silence).
std::vector<std::uint8_t> tone_wav() {
    const int rate = 44100, frames = rate * 2;
    std::vector<std::uint8_t> out;
    auto u32 = [&](std::uint32_t v) { for (int i = 0; i < 4; ++i) out.push_back(std::uint8_t(v >> (8 * i))); };
    auto u16 = [&](std::uint16_t v) { for (int i = 0; i < 2; ++i) out.push_back(std::uint8_t(v >> (8 * i))); };
    auto tag = [&](const char* t) { for (int i = 0; i < 4; ++i) out.push_back(std::uint8_t(t[i])); };
    tag("RIFF"); u32(std::uint32_t(36 + frames * 2)); tag("WAVE"); tag("fmt "); u32(16); u16(1); u16(1); u32(rate); u32(rate * 2);
    u16(2); u16(16); tag("data"); u32(std::uint32_t(frames * 2));
    for (int i = 0; i < frames; ++i) {
        const double t = double(i) / rate;
        const double v = 0.5 * std::sin(6.283185307 * 220.0 * t) + 0.25 * std::sin(6.283185307 * 440.0 * t) +
                         0.125 * std::sin(6.283185307 * 660.0 * t);
        u16(std::uint16_t(std::int16_t(v * 20000.0)));
    }
    return out;
}

// The mixer with kVoices looping voices, the project folder it plays from and the thread-less null device.
struct AudioScene {
    std::filesystem::path dir;
    Audio audio;
    bool ok = false;
    std::string error;
    explicit AudioScene(bool busFx) {
        auto made = fs::make_temp_dir("fa_bench_audio");
        if (!made.ok()) {
            error = made.error().message;
            return;
        }
        dir = made.value();
        fs::set_project_root(dir);
        std::filesystem::create_directories(dir / "sounds");
        {
            const std::vector<std::uint8_t> wav = tone_wav();
            std::ofstream f(dir / "sounds" / "tone.wav", std::ios::binary);
            f.write(reinterpret_cast<const char*>(wav.data()), std::streamsize(wav.size()));
        }
        if (!audio.init(false, &error)) return;
        if (!audio.load("sounds/tone.wav")) {
            error = "could not load sounds/tone.wav";
            return;
        }
        Rng rng(77);
        for (int i = 0; i < 48; ++i) {
            PlayParams params;
            params.loop = true;
            params.volume = 0.2f;
            params.pitch = 0.75f + float(rng.next_u32() % 100) * 0.007f;  // 0.75 .. 1.44: every voice is resampled
            params.pan = float(int(rng.next_u32() % 200) - 100) / 100.0f;
            params.bus = i % 4 == 0 ? "music" : "sfx";
            if (audio.play("sounds/tone.wav", params) == 0) {
                error = "the mixer refused voice " + std::to_string(i);
                return;
            }
        }
        if (busFx) {
            (void)audio.set_bus_lowpass("sfx", 3000.0f);
            (void)audio.set_bus_reverb("sfx", 0.3f);
            (void)audio.set_bus_reverb("music", 0.2f);
        }
        audio.advance_null_device(0.1);  // the commands are applied and the first blocks mixed before the clock starts
        ok = true;
    }
    ~AudioScene() {
        audio.shutdown();
        std::error_code ec;
        std::filesystem::remove_all(dir, ec);
    }
};

Bench audio_mix(const char* name, const char* summary, bool busFx) {
    Bench b;
    b.name = name;
    b.summary = summary;
    b.make = [busFx] {
        auto scene = std::make_shared<AudioScene>(busFx);
        Prepared p;
        if (!scene->ok) {
            p.skip = "audio setup failed: " + scene->error;
            return p;
        }
        p.items = 2 * 44100 * 48;
        p.unit = "voice frames";
        p.run = [scene] {
            scene->audio.advance_null_device(2.0);
            return double(scene->audio.active_voices().size());
        };
        return p;
    };
    return b;
}

}  // namespace

void add_audio_benches(std::vector<Bench>& out) {
    out.push_back(audio_mix("audio.mix_voices", "Mix 2 s of audio: 48 looping voices at different pitches and pans, two buses", false));
    out.push_back(audio_mix("audio.mix_bus_fx", "The same 48 voices with a low-pass and a reverb on the buses", true));
}

}  // namespace fa::bench
