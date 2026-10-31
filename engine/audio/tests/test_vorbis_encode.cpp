// encode_vorbis: the Ogg Vorbis encoder of assets.convert_audio. The engine's own decoder (stb_vorbis) reads what it writes.
#include <doctest.h>

#include <cmath>
#include <numbers>

#include "audio_test_helpers.h"
#include "fa/audio/analysis.h"
#include "fa/audio/convert.h"

// The pull API of audio_vorbis.c (private to fa_audio, declared here to read samples back).
extern "C" {
void* fa_vorbis_open(const unsigned char* data, int size, int* channels, int* rate, unsigned int* frames);
int fa_vorbis_read(void* v, int channels, float* out, int frames);
void fa_vorbis_close(void* v);
}

using namespace fa;
using namespace audio_test;

namespace {

struct Decoded {
    int channels = 0, rate = 0;
    unsigned frames = 0;
    std::vector<float> samples;  // interleaved
};

Decoded decode(const std::vector<std::uint8_t>& ogg) {
    Decoded d;
    void* v = fa_vorbis_open(ogg.data(), static_cast<int>(ogg.size()), &d.channels, &d.rate, &d.frames);
    REQUIRE(v != nullptr);
    d.samples.resize(static_cast<std::size_t>(d.frames + 4096) * d.channels);
    const int got = fa_vorbis_read(v, d.channels, d.samples.data(), static_cast<int>(d.frames + 4096));
    d.samples.resize(static_cast<std::size_t>(got) * d.channels);
    fa_vorbis_close(v);
    return d;
}

std::vector<float> mixture(double seconds, int rate, double a) {
    std::vector<float> s;
    const std::size_t n = static_cast<std::size_t>(seconds * rate);
    std::uint32_t noise = 12345;
    for (std::size_t i = 0; i < n; ++i) {
        noise = noise * 1664525u + 1013904223u;
        const double t = static_cast<double>(i) / rate;
        s.push_back(static_cast<float>(a * (0.5 * std::sin(2 * std::numbers::pi * 440 * t) + 0.25 * std::sin(2 * std::numbers::pi * 1250 * t) +
                                            0.05 * ((noise >> 8) / 8388608.0 - 1.0))));
    }
    return s;
}

}  // namespace

TEST_CASE("encode_vorbis: a mono clip decodes to the same length and the same sound, in a smaller file") {
    const int rate = 22050;
    const std::vector<float> pcm = mixture(1.37, rate, 0.8);
    const auto wav = wav_bytes(pcm, 1, rate);
    auto ogg = encode_vorbis(wav);
    REQUIRE_MESSAGE(ogg.ok(), (ogg.ok() ? "" : ogg.error().to_string()));
    CHECK(std::string(ogg->begin(), ogg->begin() + 4) == "OggS");
    CHECK(ogg->size() < wav.size() / 2);
    const Decoded d = decode(*ogg);
    CHECK(d.channels == 1);
    CHECK(d.rate == rate);
    REQUIRE(d.frames == pcm.size());
    REQUIRE(d.samples.size() == pcm.size());
    double err = 0, sig = 0;
    for (std::size_t i = 0; i < pcm.size(); ++i) {
        err += (d.samples[i] - pcm[i]) * (d.samples[i] - pcm[i]);
        sig += pcm[i] * pcm[i];
    }
    const double snr = 10 * std::log10(sig / std::max(err, 1e-12));
    MESSAGE("snr " << snr << " dB, " << ogg->size() << " bytes from " << wav.size());
    CHECK(snr > 20.0);
}

TEST_CASE("encode_vorbis: stereo keeps the channels apart, the same input gives the same bytes, quality changes the size") {
    const int rate = 16000;
    std::vector<float> st;
    const std::vector<float> l = mixture(0.8, rate, 0.7);
    for (float s : l) {
        st.push_back(s);
        st.push_back(0.0f);  // silent right side
    }
    const auto wav = wav_bytes(st, 2, rate);
    auto a = encode_vorbis(wav, 0.5);
    auto b = encode_vorbis(wav, 0.5);
    auto high = encode_vorbis(wav, 1.0);
    auto low = encode_vorbis(wav, 0.0);
    REQUIRE((a.ok() && b.ok() && high.ok() && low.ok()));
    CHECK(*a == *b);
    CHECK(low->size() < a->size());
    CHECK(a->size() < high->size());
    const Decoded d = decode(*a);
    REQUIRE(d.channels == 2);
    REQUIRE(d.frames == l.size());
    float rightPeak = 0, leftPeak = 0;
    for (std::size_t i = 0; i + 1 < d.samples.size(); i += 2) {
        leftPeak = std::max(leftPeak, std::fabs(d.samples[i]));
        rightPeak = std::max(rightPeak, std::fabs(d.samples[i + 1]));
    }
    CHECK(leftPeak > 0.5f);
    CHECK(rightPeak < 0.001f);
}

TEST_CASE("encode_vorbis: silence, a very short clip, and what it refuses") {
    const int rate = 8000;
    auto silent = encode_vorbis(wav_bytes(std::vector<float>(3000, 0.0f), 1, rate));
    REQUIRE(silent.ok());
    const Decoded ds = decode(*silent);
    CHECK(ds.frames == 3000);
    float peak = 0;
    for (float s : ds.samples) peak = std::max(peak, std::fabs(s));
    CHECK(peak < 1e-4f);
    auto tiny = encode_vorbis(wav_bytes(std::vector<float>(10, 0.3f), 1, rate));
    REQUIRE(tiny.ok());
    CHECK(decode(*tiny).frames == 10);
    CHECK_FALSE(encode_vorbis(wav_bytes(std::vector<float>(100, 0.0f), 1, rate), 1.5).ok());
    const std::vector<std::uint8_t> junk = {1, 2, 3};
    CHECK_FALSE(encode_vorbis(junk).ok());
    CHECK_FALSE(encode_vorbis(wav_bytes(std::vector<float>(300, 0.0f), 3, rate)).ok());
}

TEST_CASE("encode_vorbis: the engine measures the loudness of the file like the WAV's") {
    const int rate = 22050;
    const std::vector<float> pcm = mixture(3.0, rate, 0.5);
    const auto wav = wav_bytes(pcm, 1, rate);
    auto ogg = encode_vorbis(wav);
    REQUIRE(ogg.ok());
    auto lw = measure_loudness(wav, ".wav");
    auto lo = measure_loudness(*ogg, ".ogg");
    REQUIRE((lw.ok() && lo.ok()));
    CHECK(lo->integratedLufs == doctest::Approx(lw->integratedLufs).epsilon(0.05));
    CHECK(lo->seconds == doctest::Approx(lw->seconds).epsilon(0.001));
}
