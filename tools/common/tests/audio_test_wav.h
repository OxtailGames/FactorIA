// A WAV for the audio tests of fa_tooling.
#pragma once

#include <cmath>
#include <cstdint>
#include <numbers>
#include <string>

namespace fa::testing {

// A 16-bit PCM WAV with a 1 kHz sine at this peak level in dBFS (its loudness reads about the same in LUFS); `channels`
// copies of it.
inline std::string sine_wav(double seconds, double peakDb, int channels = 1, int rate = 44100) {
    const std::size_t n = std::size_t(seconds * rate);
    const double amp = std::pow(10.0, peakDb / 20.0);
    std::string b;
    auto u32 = [&](std::uint32_t v) { for (int i = 0; i < 4; ++i) b.push_back(char(v >> (8 * i))); };
    auto u16 = [&](std::uint16_t v) { b.push_back(char(v)); b.push_back(char(v >> 8)); };
    b += "RIFF"; u32(std::uint32_t(36 + n * 2 * channels)); b += "WAVEfmt "; u32(16); u16(1); u16(std::uint16_t(channels));
    u32(std::uint32_t(rate)); u32(std::uint32_t(rate * 2 * channels)); u16(std::uint16_t(2 * channels)); u16(16);
    b += "data"; u32(std::uint32_t(n * 2 * channels));
    for (std::size_t i = 0; i < n; ++i) {
        const auto s = std::uint16_t(std::int16_t(std::lround(amp * std::sin(2.0 * std::numbers::pi * 1000.0 * double(i) / rate) * 32767.0)));
        for (int c = 0; c < channels; ++c) u16(s);
    }
    return b;
}

}  // namespace fa::testing
