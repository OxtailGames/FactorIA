// Sound patches (fa/audio/sfx.h): every oscillator and effect on a measurable property, determinism, the presets, and the errors.
#include <doctest.h>

#include <cmath>
#include <cstring>
#include <cstdint>
#include <set>
#include <string>

#include "audio_test_helpers.h"
#include "fa/audio/analysis.h"
#include "fa/audio/sfx.h"

using namespace fa;

namespace {

constexpr double kPi = 3.14159265358979323846;

// A patch with one layer from the JSON of `layer`, 1 second long, not levelled (normalize none) and with no fade, so the
// samples are what the layer makes.
SfxAudio render_layer_json(const std::string& layer, double length = 1.0, const std::string& extra = "") {
    const std::string text = R"({"format": "factoria.sfx/1", "length": )" + std::to_string(length) + R"(, "fadeOut": 0, "layers": [)" + layer + "]" +
                             R"(, "master": {"normalize": {"mode": "none"}})" + extra + "}";
    auto json = parse_json(text);
    REQUIRE_MESSAGE(json.ok(), (json.ok() ? "" : json.error().to_string()));
    auto patch = parse_sfx(*json, "test");
    REQUIRE_MESSAGE(patch.ok(), (patch.ok() ? "" : patch.error().to_string()));
    auto audio = render_sfx(*patch);
    REQUIRE_MESSAGE(audio.ok(), (audio.ok() ? "" : audio.error().to_string()));
    return *audio;
}

SfxAudio render_osc(const std::string& oscillator, double freq = 441.0, const std::string& layerExtra = "") {
    return render_layer_json(R"({"oscillators": [)" + oscillator + R"(], "pitch": {"freq": )" + std::to_string(freq) +
                             R"(}, "amp": {"attack": 0, "sustain": 1, "release": 0})" + layerExtra + "}");
}

// Frequency from upward zero crossings between two times.
double crossings_hz(const SfxAudio& a, double t0, double t1) {
    const std::size_t i0 = std::size_t(t0 * a.sampleRate), i1 = std::min(a.samples.size(), std::size_t(t1 * a.sampleRate));
    int n = 0;
    for (std::size_t i = i0 + 1; i < i1; ++i)
        if (a.samples[i - 1] < 0.0f && a.samples[i] >= 0.0f) ++n;
    return double(n) / (t1 - t0);
}

// The amplitude of the component at `hz` (Goertzel, over [t0, t1)), as a peak value.
double component(const SfxAudio& a, double hz, double t0 = 0.0, double t1 = -1.0) {
    const std::size_t i0 = std::size_t(t0 * a.sampleRate), i1 = t1 < 0 ? a.samples.size() : std::min(a.samples.size(), std::size_t(t1 * a.sampleRate));
    double re = 0.0, im = 0.0;
    for (std::size_t i = i0; i < i1; ++i) {
        const double ph = 2.0 * kPi * hz * double(i) / double(a.sampleRate);
        re += a.samples[i] * std::cos(ph);
        im += a.samples[i] * std::sin(ph);
    }
    return 2.0 * std::sqrt(re * re + im * im) / double(i1 - i0);
}

double rms(const SfxAudio& a, double t0 = 0.0, double t1 = -1.0) {
    const std::size_t i0 = std::size_t(t0 * a.sampleRate), i1 = t1 < 0 ? a.samples.size() : std::min(a.samples.size(), std::size_t(t1 * a.sampleRate));
    double sum = 0.0;
    for (std::size_t i = i0; i < i1; ++i) sum += double(a.samples[i]) * double(a.samples[i]);
    return std::sqrt(sum / double(i1 - i0));
}

double peak(const SfxAudio& a, double t0 = 0.0, double t1 = -1.0) {
    const std::size_t i0 = std::size_t(t0 * a.sampleRate), i1 = t1 < 0 ? a.samples.size() : std::min(a.samples.size(), std::size_t(t1 * a.sampleRate));
    double p = 0.0;
    for (std::size_t i = i0; i < i1; ++i) p = std::max(p, std::fabs(double(a.samples[i])));
    return p;
}

double autocorr1(const SfxAudio& a) {
    double num = 0.0, den = 0.0;
    for (std::size_t i = 1; i < a.samples.size(); ++i) {
        num += double(a.samples[i]) * double(a.samples[i - 1]);
        den += double(a.samples[i]) * double(a.samples[i]);
    }
    return num / den;
}

std::uint64_t fnv(const std::vector<float>& s) {
    std::uint64_t h = 1469598103934665603ull;
    for (float f : s) {
        std::uint32_t bits;
        std::memcpy(&bits, &f, 4);
        for (int i = 0; i < 4; ++i) h = (h ^ ((bits >> (8 * i)) & 255)) * 1099511628211ull;
    }
    return h;
}

}  // namespace

TEST_CASE("sfx: oscillators play the pitch they are asked for") {
    for (const char* wave : {"sine", "square", "saw", "triangle"}) {
        CAPTURE(wave);
        const SfxAudio a = render_osc(std::string(R"({"wave": ")") + wave + R"("})");
        CHECK(crossings_hz(a, 0.1, 0.9) == doctest::Approx(441.0).epsilon(0.02));
        CHECK(peak(a) > 0.9);
        CHECK(peak(a) < 1.15);
    }
    // A drawn wavetable: one cycle of [0, 1, 0, -1] is a rough sine at the same pitch.
    const SfxAudio t = render_osc(R"({"wave": "table", "table": [0, 0.5, 1, 0.5, 0, -0.5, -1, -0.5]})");
    CHECK(crossings_hz(t, 0.1, 0.9) == doctest::Approx(441.0).epsilon(0.02));
    CHECK(component(t, 441.0) > 0.8);
}

TEST_CASE("sfx: the sine is a clean sine and the square follows its duty") {
    const SfxAudio s = render_osc(R"({"wave": "sine"})");
    CHECK(component(s, 441.0) == doctest::Approx(1.0).epsilon(0.01));
    CHECK(component(s, 1323.0) < 0.01);
    for (double duty : {0.125, 0.25, 0.5}) {
        const SfxAudio q = render_osc("{\"wave\": \"square\", \"duty\": " + std::to_string(duty) + "}");
        std::size_t high = 0;
        for (float v : q.samples) high += v > 0.0f ? 1 : 0;
        CHECK(double(high) / double(q.samples.size()) == doctest::Approx(duty).epsilon(0.02));
    }
}

TEST_CASE("sfx: noise colors lean toward the low end in order") {
    auto lean = [&](const char* color) {
        return autocorr1(render_osc(std::string(R"({"wave": "noise", "color": ")") + color + R"("})"));
    };
    const double white = lean("white"), pink = lean("pink"), brown = lean("brown");
    CHECK(std::fabs(white) < 0.05);
    CHECK(pink > white + 0.3);
    CHECK(brown > pink + 0.1);
    CHECK(brown > 0.9);
    // All three are at a similar level (the scaling keeps their RMS close to white noise's 0.577).
    for (const char* color : {"white", "pink", "brown"}) {
        const double r = rms(render_osc(std::string(R"({"wave": "noise", "color": ")") + color + R"("})"));
        CHECK(r > 0.3);
        CHECK(r < 0.9);
    }
}

TEST_CASE("sfx: frequency modulation makes sidebands, ring modulation removes the carrier") {
    const SfxAudio plain = render_osc(R"({"wave": "sine"})", 400.0);
    const SfxAudio fm = render_osc(R"({"wave": "sine", "fm": {"ratio": 1, "index": 2}})", 400.0);
    CHECK(component(plain, 800.0) < 0.01);
    CHECK(component(fm, 800.0) > 0.2);
    CHECK(component(fm, 1200.0) > 0.1);
    // Index 0 is no modulation.
    const SfxAudio fm0 = render_osc(R"({"wave": "sine", "fm": {"ratio": 1, "index": 0}})", 400.0);
    CHECK(component(fm0, 800.0) < 0.01);
    // sin(a) * sin(1.5 a): components at 0.5 f and 2.5 f, none at f.
    const SfxAudio ring = render_osc(R"({"wave": "sine", "ring": {"ratio": 1.5}})", 400.0);
    CHECK(component(ring, 400.0) < 0.02);
    CHECK(component(ring, 200.0) > 0.4);
    CHECK(component(ring, 1000.0) > 0.4);
}

TEST_CASE("sfx: the amplitude envelope has the attack, decay and release it describes") {
    const std::string osc = R"("oscillators": [{"wave": "sine"}], "pitch": {"freq": 440})";
    // Attack 0.2 s, decay 0.2 s to a sustain of 0.5, held 0.6 s, release 0.2 s (the gate closes at 0.6).
    const SfxAudio a = render_layer_json("{" + osc + R"(, "length": 0.6, "amp": {"attack": 0.2, "decay": 0.2, "sustain": 0.5, "release": 0.2}})", 0.6,
                                         R"(, "tail": 0.2)");
    CHECK(peak(a, 0.0, 0.02) < 0.15);
    CHECK(peak(a, 0.19, 0.21) > 0.95);
    CHECK(peak(a, 0.45, 0.55) == doctest::Approx(0.5).epsilon(0.03));
    CHECK(peak(a, 0.70, 0.72) < 0.5 * 0.7);  // released
    CHECK(peak(a, 0.79, 0.8) < 0.05);        // gone at the end
    // The tail is part of the length of the audio.
    CHECK(a.seconds() == doctest::Approx(0.8).epsilon(0.001));
}

TEST_CASE("sfx: pitch sweeps, arpeggios and pitch envelopes move the frequency") {
    const SfxAudio sweep = render_layer_json(R"({"oscillators": [{"wave": "sine"}], "pitch": {"freq": 400, "sweep": {"semitones": 12}}, "amp": {"attack": 0, "release": 0}})");
    CHECK(crossings_hz(sweep, 0.0, 0.1) == doctest::Approx(405.0).epsilon(0.05));
    CHECK(crossings_hz(sweep, 0.9, 1.0) > 700.0);
    const SfxAudio arp = render_layer_json(R"({"oscillators": [{"wave": "sine"}], "pitch": {"freq": 400, "arpeggio": {"steps": [0, 12], "rate": 2}}, "amp": {"attack": 0, "release": 0}})");
    CHECK(crossings_hz(arp, 0.05, 0.45) == doctest::Approx(400.0).epsilon(0.02));
    CHECK(crossings_hz(arp, 0.55, 0.95) == doctest::Approx(800.0).epsilon(0.02));
    const SfxAudio env = render_layer_json(R"({"oscillators": [{"wave": "sine"}], "pitch": {"freq": 400, "env": {"amount": 12, "decay": 0.2, "sustain": 0}}, "amp": {"attack": 0, "release": 0}})");
    CHECK(crossings_hz(env, 0.0, 0.03) > 650.0);
    CHECK(crossings_hz(env, 0.5, 0.9) == doctest::Approx(400.0).epsilon(0.02));
}

TEST_CASE("sfx: a transposed render plays the patch at another pitch") {
    auto json = parse_json(R"({"format": "factoria.sfx/1", "length": 1, "fadeOut": 0, "layers": [{"oscillators": [{"wave": "sine"}], "pitch": {"freq": 440}}]})");
    REQUIRE(json.ok());
    auto patch = parse_sfx(*json);
    REQUIRE(patch.ok());
    SfxRenderOptions o;
    o.freqHz = 660.0;
    auto a = render_sfx(*patch, o);
    REQUIRE(a.ok());
    CHECK(crossings_hz(*a, 0.1, 0.9) == doctest::Approx(660.0).epsilon(0.02));
    CHECK(patch->root_hz() == doctest::Approx(440.0));
}

TEST_CASE("sfx: layer filters attenuate on the side they should") {
    auto level_at = [&](const char* filter, double hz) {
        return component(render_osc(R"({"wave": "sine"})", hz, std::string(R"(, "filter": )") + filter), hz, 0.1, 0.9);
    };
    // Low-pass at 1000 Hz: 4 kHz is a few octaves above, 200 Hz is below.
    CHECK(level_at(R"({"mode": "lowpass", "cutoff": 1000})", 4000.0) < 0.1);
    CHECK(level_at(R"({"mode": "lowpass", "cutoff": 1000})", 200.0) > 0.95);
    CHECK(level_at(R"({"mode": "highpass", "cutoff": 1000})", 200.0) < 0.1);
    CHECK(level_at(R"({"mode": "highpass", "cutoff": 1000})", 4000.0) > 0.95);
    CHECK(level_at(R"({"mode": "bandpass", "cutoff": 1000, "resonance": 4})", 1000.0) > 0.9);
    CHECK(level_at(R"({"mode": "bandpass", "cutoff": 1000, "resonance": 4})", 100.0) < 0.15);
    // At the cutoff a flat low-pass is 3 dB down.
    CHECK(level_at(R"({"mode": "lowpass", "cutoff": 1000})", 1000.0) == doctest::Approx(0.707).epsilon(0.05));
    // Resonance lifts the cutoff: the gain at the cutoff of a low-pass is its Q (the output is clipped at 1, so a quiet input).
    const SfxAudio quiet = render_osc(R"({"wave": "sine", "gain": 0.1})", 1000.0, R"(, "filter": {"mode": "lowpass", "cutoff": 1000, "resonance": 8})");
    CHECK(component(quiet, 1000.0, 0.1, 0.9) / 0.1 == doctest::Approx(8.0).epsilon(0.05));
}

TEST_CASE("sfx: a filter envelope opens the cutoff and closes it again") {
    // White noise through a low-pass that starts 4 octaves above 400 Hz and falls to it.
    const SfxAudio a = render_osc(R"({"wave": "noise"})", 440.0,
                                  R"(, "filter": {"mode": "lowpass", "cutoff": 400, "env": {"amount": 4, "decay": 0.3, "sustain": 0}})");
    CHECK(rms(a, 0.0, 0.05) > 1.7 * rms(a, 0.6, 1.0));
}

TEST_CASE("sfx: distortion, bitcrush, delay and reverb do what they say") {
    const std::string sine = R"({"oscillators": [{"wave": "sine", "gain": 0.5}], "pitch": {"freq": 441}, "amp": {"attack": 0, "release": 0}}, )";
    auto with_master = [&](const std::string& effect, double length = 1.0, const std::string& extra = "") {
        auto json = parse_json(R"({"format": "factoria.sfx/1", "length": )" + std::to_string(length) + R"(, "fadeOut": 0, "layers": [)" + sine.substr(0, sine.size() - 2) + "]" +
                               R"(, "master": {"effects": [)" + effect + R"(], "normalize": {"mode": "none"}})" + extra + "}");
        REQUIRE_MESSAGE(json.ok(), (json.ok() ? "" : json.error().to_string()));
        auto patch = parse_sfx(*json);
        REQUIRE_MESSAGE(patch.ok(), (patch.ok() ? "" : patch.error().to_string()));
        auto a = render_sfx(*patch);
        REQUIRE(a.ok());
        return *a;
    };
    SUBCASE("hard distortion flattens the peaks and adds odd harmonics") {
        const SfxAudio a = with_master(R"({"type": "distortion", "mode": "hard", "drive": 10})");
        CHECK(peak(a) == doctest::Approx(1.0).epsilon(0.01));
        CHECK(component(a, 1323.0) > 0.1);  // 3rd harmonic
        CHECK(component(a, 882.0) < 0.02);  // no 2nd
    }
    SUBCASE("soft distortion stays under 1") {
        const SfxAudio a = with_master(R"({"type": "distortion", "mode": "soft", "drive": 20})");
        CHECK(peak(a) <= 1.0);
        CHECK(component(a, 1323.0) > 0.05);
    }
    SUBCASE("fold distortion bends the peaks back") {
        const SfxAudio a = with_master(R"({"type": "distortion", "mode": "fold", "drive": 4})");
        CHECK(peak(a) <= 1.0);
        CHECK(component(a, 1323.0) > 0.05);
    }
    SUBCASE("bitcrush leaves few distinct levels") {
        const SfxAudio a = with_master(R"({"type": "bitcrush", "bits": 3})");
        std::set<float> levels(a.samples.begin(), a.samples.end());
        CHECK(levels.size() <= 8);
        CHECK(levels.size() >= 3);
        const SfxAudio held = with_master(R"({"type": "bitcrush", "bits": 16, "rate": 4410})");
        CHECK(component(held, 441.0) > 0.4);
        std::size_t changes = 0;
        for (std::size_t i = 1; i < held.samples.size(); ++i) changes += held.samples[i] != held.samples[i - 1] ? 1 : 0;
        CHECK(changes < held.samples.size() / 8);  // a held sample changes once every 10
    }
    SUBCASE("a delay repeats the sound later") {
        // A 50 ms burst of sine, then an echo 0.2 s later.
        auto json = parse_json(R"({"format": "factoria.sfx/1", "length": 0.05, "tail": 0.6, "fadeOut": 0, "layers": [{"oscillators": [{"wave": "sine"}], "pitch": {"freq": 441},
            "amp": {"attack": 0, "release": 0}}], "master": {"effects": [{"type": "delay", "time": 0.2, "feedback": 0.5, "mix": 1}], "normalize": {"mode": "none"}}})");
        REQUIRE(json.ok());
        auto patch = parse_sfx(*json);
        REQUIRE(patch.ok());
        auto a = render_sfx(*patch);
        REQUIRE(a.ok());
        CHECK(peak(*a, 0.0, 0.05) > 0.9);
        CHECK(peak(*a, 0.1, 0.19) < 0.01);
        CHECK(peak(*a, 0.21, 0.25) == doctest::Approx(1.0).epsilon(0.05));
        CHECK(peak(*a, 0.41, 0.45) == doctest::Approx(0.5).epsilon(0.05));
        CHECK(peak(*a, 0.61, 0.65) == doctest::Approx(0.25).epsilon(0.05));
    }
    SUBCASE("a reverb keeps ringing after the sound and dies away") {
        auto render_with = [&](const char* effects) {
            auto json = parse_json(std::string(R"({"format": "factoria.sfx/1", "length": 0.1, "tail": 1.5, "fadeOut": 0, "layers": [{"oscillators": [{"wave": "noise"}],
                "amp": {"attack": 0, "release": 0}}], "master": {"effects": [)") + effects + R"(], "normalize": {"mode": "none"}}})");
            REQUIRE(json.ok());
            auto patch = parse_sfx(*json);
            REQUIRE(patch.ok());
            auto a = render_sfx(*patch);
            REQUIRE(a.ok());
            return *a;
        };
        const SfxAudio dry = render_with("");
        const SfxAudio wet = render_with(R"({"type": "reverb", "decay": 1.0, "mix": 0.5})");
        CHECK(rms(dry, 0.2, 0.4) < 1e-6);
        CHECK(rms(wet, 0.15, 0.3) > 0.01);
        CHECK(rms(wet, 1.3, 1.6) < 0.2 * rms(wet, 0.15, 0.3));
    }
}

TEST_CASE("sfx: layers start where they are told and add up") {
    const SfxAudio a = render_layer_json(
        R"({"start": 0.5, "length": 0.3, "gain": 0.5, "oscillators": [{"wave": "sine"}], "pitch": {"freq": 441}, "amp": {"attack": 0, "release": 0}},
           {"oscillators": [{"wave": "sine"}], "pitch": {"freq": 441}, "length": 0.2, "amp": {"attack": 0, "release": 0}})");
    CHECK(peak(a, 0.0, 0.19) > 0.95);
    CHECK(peak(a, 0.25, 0.45) < 0.01);
    CHECK(peak(a, 0.5, 0.79) == doctest::Approx(0.5).epsilon(0.03));
    CHECK(peak(a, 0.85, 1.0) < 0.01);
}

TEST_CASE("sfx: normalization reaches the target loudness, and measures what the engine measures") {
    auto json = parse_json(R"({"format": "factoria.sfx/1", "length": 0.6, "layers": [{"oscillators": [{"wave": "saw"}, {"wave": "noise", "gain": 0.3}], "pitch": {"freq": 220}}]})");
    REQUIRE(json.ok());
    auto patch = parse_sfx(*json);
    REQUIRE(patch.ok());
    auto a = render_sfx(*patch);
    REQUIRE(a.ok());
    CHECK(a->lufs == doctest::Approx(-18.0).epsilon(0.02));
    CHECK(a->peakDb <= -0.99);
    auto engine = measure_loudness(sfx_wav_bytes(*a), ".wav");
    REQUIRE(engine.ok());
    CHECK(engine->integratedLufs == doctest::Approx(a->lufs).epsilon(0.02));  // 16-bit rounding aside
    // Peak mode and none.
    SfxRenderOptions peakMode;
    peakMode.normalize = SfxNormalize{SfxNormalizeMode::Peak, -6.0, -1.0};
    auto p = render_sfx(*patch, peakMode);
    REQUIRE(p.ok());
    CHECK(p->peakDb == doctest::Approx(-6.0).epsilon(0.01));
    // Velocity scales after the normalization.
    SfxRenderOptions soft;
    soft.velocity = 0.5;
    auto s = render_sfx(*patch, soft);
    REQUIRE(s.ok());
    CHECK(s->lufs == doctest::Approx(-18.0 - 6.02).epsilon(0.02));
}

TEST_CASE("sfx: the same patch gives the same bytes, and the seed picks the noise") {
    const char* text = R"({"format": "factoria.sfx/1", "length": 0.4, "tail": 0.3, "seed": 5, "layers": [
        {"oscillators": [{"wave": "saw", "detune": 7}, {"wave": "noise", "color": "pink", "gain": 0.4},
                         {"wave": "sine", "fm": {"ratio": 2.01, "index": 3, "indexEnv": {"decay": 0.3, "sustain": 0}}, "ring": {"ratio": 1.5, "mix": 0.3}}],
         "pitch": {"freq": 330, "sweep": {"semitones": -5}, "vibrato": {"rate": 6, "depth": 20}}, "tremolo": {"rate": 9, "depth": 0.3},
         "filter": {"mode": "lowpass", "cutoff": 2000, "resonance": 3, "env": {"amount": 2, "decay": 0.2, "sustain": 0}}}],
        "master": {"effects": [{"type": "distortion", "mode": "soft", "drive": 3}, {"type": "bitcrush", "bits": 10, "mix": 0.5},
                               {"type": "delay", "time": 0.12, "feedback": 0.3, "tone": 3000}, {"type": "reverb", "decay": 0.5}]}})";
    auto json = parse_json(text);
    REQUIRE(json.ok());
    auto patch = parse_sfx(*json);
    REQUIRE_MESSAGE(patch.ok(), (patch.ok() ? "" : patch.error().to_string()));
    auto a = render_sfx(*patch);
    auto b = render_sfx(*patch);
    REQUIRE((a.ok() && b.ok()));
    CHECK(sfx_wav_bytes(*a) == sfx_wav_bytes(*b));
    CHECK(a->samples == b->samples);
    SfxRenderOptions other;
    other.seed = 1;
    auto c = render_sfx(*patch, other);
    REQUIRE(c.ok());
    CHECK(c->samples != a->samples);
    // A fingerprint of the samples: it is the same on every platform and compiler the engine builds on (docs/SOUND.md,
    // "Determinism"). If this fails on one platform only, the renderer is not deterministic there.
    CHECK(fnv(a->samples) == 0xb9ffe7f650f7f70dull);
}

TEST_CASE("sfx: every synth_sound preset is a valid patch that renders a sensible sound") {
    REQUIRE(sfx_presets().size() >= 17);
    for (const SfxPresetInfo& info : sfx_presets()) {
        CAPTURE(info.name);
        auto json = sfx_preset_patch(info.name);
        REQUIRE(json.has_value());
        std::vector<SfxIssue> issues;
        auto patch = parse_sfx(*json, info.name, &issues);
        REQUIRE_MESSAGE(patch.ok(), (patch.ok() ? "" : patch.error().to_string()));
        CHECK(issues.empty());
        CHECK(!patch->doc.empty());
        auto a = render_sfx(*patch);
        REQUIRE(a.ok());
        CHECK(a->seconds() > 0.03);
        CHECK(a->seconds() < 1.5);
        // -18 LUFS, or less where the peak ceiling (-1 dBFS) stops the gain first (a 40 ms click is loud for its energy).
        CHECK((std::fabs(a->lufs + 18.0) < 0.5 || (a->lufs < -18.0 && a->peakDb > -1.05)));
        CHECK(a->peakDb <= -0.99);
        CHECK(a->peakDb > -25.0);
        // It ends quietly: the last milliseconds are near silence.
        CHECK(peak(*a, a->seconds() - 0.002, a->seconds()) < 0.05);
        // And it is not a constant: it has a start and a shape.
        CHECK(rms(*a) > 0.01);
    }
    CHECK_FALSE(sfx_preset_patch("no_such_preset").has_value());
}

TEST_CASE("sfx: a patch with mistakes lists them with pointers and suggestions") {
    auto parse = [&](const char* text, std::vector<SfxIssue>& issues) {
        auto json = parse_json(text);
        REQUIRE(json.ok());
        return parse_sfx(*json, "bad.sfx.json", &issues);
    };
    std::vector<SfxIssue> issues;
    SUBCASE("a misspelled key") {
        auto r = parse(R"({"format": "factoria.sfx/1", "lenght": 1, "layers": [{"oscillators": [{"wave": "sine"}]}]})", issues);
        CHECK_FALSE(r.ok());
        REQUIRE(issues.size() == 1);
        CHECK(issues[0].pointer == "/lenght");
        CHECK(issues[0].hint.find("length") != std::string::npos);
        CHECK(r.error().message.find("bad.sfx.json") != std::string::npos);
    }
    SUBCASE("a wrong wave name has a did-you-mean") {
        auto r = parse(R"({"format": "factoria.sfx/1", "layers": [{"oscillators": [{"wave": "sqare"}]}]})", issues);
        CHECK_FALSE(r.ok());
        REQUIRE(issues.size() == 1);
        CHECK(issues[0].pointer == "/layers/0/oscillators/0/wave");
        CHECK(issues[0].hint.find("square") != std::string::npos);
    }
    SUBCASE("every problem is listed, not only the first") {
        auto r = parse(R"({"format": "factoria.sfx/1", "length": -1, "layers": [{"oscillators": [{"wave": "sine"}], "filter": {"mode": "lowpas", "cutoff": 5}},
                           {"oscillators": []}], "master": {"effects": [{"type": "relverb"}]}})", issues);
        CHECK_FALSE(r.ok());
        CHECK(issues.size() >= 4);
        std::set<std::string> pointers;
        for (const SfxIssue& i : issues) {
            pointers.insert(i.pointer);
            CHECK_FALSE(i.message.empty());
            CHECK_FALSE(i.hint.empty());
        }
        CHECK(pointers.count("/length"));
        CHECK(pointers.count("/layers/0/filter/mode"));
        CHECK(pointers.count("/layers/0/filter/cutoff"));
        CHECK(pointers.count("/layers/1/oscillators"));
        CHECK(pointers.count("/master/effects/0/type"));
    }
    SUBCASE("a wrong format and a non-object") {
        CHECK_FALSE(parse(R"({"format": "factoria.sfx/2", "layers": []})", issues).ok());
        bool format = false;
        for (const SfxIssue& i : issues) format = format || i.pointer == "/format";
        CHECK(format);
        CHECK_FALSE(parse("[1]", issues).ok());
    }
    SUBCASE("a number of the wrong type says what it got") {
        auto r = parse(R"({"format": "factoria.sfx/1", "layers": [{"oscillators": [{"wave": "sine", "gain": "loud"}]}]})", issues);
        CHECK_FALSE(r.ok());
        REQUIRE(issues.size() == 1);
        CHECK(issues[0].pointer == "/layers/0/oscillators/0/gain");
        CHECK(issues[0].message.find("loud") != std::string::npos);
    }
}

TEST_CASE("sfx: notes, WAV bytes and limits") {
    CHECK(*sfx_note_hz("A4") == doctest::Approx(440.0));
    CHECK(*sfx_note_hz("C4") == doctest::Approx(261.6256).epsilon(0.0001));
    CHECK(*sfx_note_hz("Bb2") == doctest::Approx(116.5409).epsilon(0.0001));
    CHECK(*sfx_note_hz("C#3") == doctest::Approx(138.5913).epsilon(0.0001));
    CHECK_FALSE(sfx_note_hz("H4").has_value());
    CHECK_FALSE(sfx_note_hz("loud").has_value());

    SfxAudio a;
    a.sampleRate = 22050;
    a.samples = {0.0f, 1.0f, -1.0f, 0.5f};
    const auto wav = sfx_wav_bytes(a);
    REQUIRE(wav.size() == 44 + 8);
    CHECK(std::string(wav.begin(), wav.begin() + 4) == "RIFF");
    CHECK(std::string(wav.begin() + 8, wav.begin() + 12) == "WAVE");

    auto json = parse_json(R"({"format": "factoria.sfx/1", "length": 20, "tail": 20, "layers": [{"oscillators": [{"wave": "sine"}]}]})");
    REQUIRE(json.ok());
    std::vector<SfxIssue> issues;
    CHECK_FALSE(parse_sfx(*json, "long", &issues).ok());
}

TEST_CASE("sfx: stretching a patch scales its times and keeps its pitch") {
    // A 440 Hz tone that sweeps up an octave over its whole 0.4 s, with an echo; stretched to twice as long.
    const char* text = R"({"format": "factoria.sfx/1", "length": 0.4, "tail": 0.1, "fadeOut": 0,
        "layers": [{"oscillators": [{"wave": "sine"}], "pitch": {"freq": 440, "sweep": {"semitones": 12, "time": 0.4}},
                    "amp": {"attack": 0.02, "decay": 0.1, "sustain": 0.5, "release": 0.05}}, 
                   {"start": 0.1, "length": 0.1, "oscillators": [{"wave": "saw"}], "pitch": {"freq": 220, "vibrato": {"rate": 6, "depth": 10, "delay": 0.1}}}],
        "master": {"effects": [{"type": "delay", "time": 0.1, "mix": 0.3}], "normalize": {"mode": "none"}}})";
    auto json = parse_json(text);
    REQUIRE(json.ok());
    auto patch = parse_sfx(*json, "test");
    REQUIRE(patch.ok());
    auto before = render_sfx(*patch);
    REQUIRE(before.ok());

    SfxPatch longer = *patch;
    stretch_sfx(longer, 2.0);
    CHECK(longer.length == doctest::Approx(0.8));
    CHECK(longer.tail == doctest::Approx(0.2));
    CHECK(longer.layers[0].amp.attack == doctest::Approx(0.04));
    CHECK(longer.layers[0].amp.release == doctest::Approx(0.1));
    CHECK(longer.layers[0].amp.sustain == doctest::Approx(0.5));  // a level, not a time
    CHECK(longer.layers[0].pitch.sweepTime == doctest::Approx(0.8));
    CHECK(longer.layers[0].pitch.freq == doctest::Approx(440.0));
    CHECK(longer.layers[1].start == doctest::Approx(0.2));
    CHECK(longer.layers[1].length == doctest::Approx(0.2));
    CHECK(longer.layers[1].pitch.vibratoDelay == doctest::Approx(0.2));
    CHECK(longer.layers[1].pitch.vibratoRate == doctest::Approx(6.0));  // a pitch-like rate stays
    CHECK(longer.effects[0].time == doctest::Approx(0.2));

    auto after = render_sfx(longer);
    REQUIRE(after.ok());
    CHECK(after->seconds() == doctest::Approx(2.0 * before->seconds()).epsilon(0.001));
    // the sweep starts at the same note and takes twice as long to climb: the frequency at 0.1 s of the short sound is the one at 0.2 s of the long one
    CHECK(crossings_hz(*after, 0.0, 0.05) == doctest::Approx(crossings_hz(*before, 0.0, 0.05)).epsilon(0.06));

    SfxPatch same = *patch;
    stretch_sfx(same, 1.0);
    auto again = render_sfx(same);
    REQUIRE(again.ok());
    CHECK(again->samples == before->samples);
}
