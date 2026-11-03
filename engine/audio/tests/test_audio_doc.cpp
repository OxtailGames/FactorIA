// Audio documents (fa/audio/audio_doc.h): every step measured on a property it must have (length, level, pitch, seam), determinism, the
// errors, and the loop points the mixer honours. The files and commands around it are tools/common/tests/audio_doc_test.cpp.
#include <doctest.h>

#include <cmath>
#include <cstdint>
#include <numbers>
#include <string>

#include "audio_test_helpers.h"
#include "fa/audio/analysis.h"
#include "fa/audio/audio_doc.h"

using namespace fa;
using namespace audio_test;

namespace {

constexpr int kRate = 44100;

// A project folder in the temp dir with the sources every test needs; the project root is it while the fixture lives.
struct DocProject {
    std::filesystem::path dir;
    DocProject() {
        dir = fs::make_temp_dir("factoria_audio_doc_test");
        fs::set_project_root(dir);
    }
    ~DocProject() { std::filesystem::remove_all(dir); }
    void sine(const std::string& name, double seconds, double hz, double amp = 0.5) { write_sine_wav(dir / name, seconds, hz, amp, kRate); }
    void samples(const std::string& name, const std::vector<float>& s, int channels = 1) { write_file(dir / name, wav_bytes(s, channels, kRate)); }
    void text(const std::string& name, const std::string& body) {
        std::filesystem::create_directories((dir / name).parent_path());
        REQUIRE(fs::write_text(name, body).ok());
    }
};

Json doc_json(const std::string& source, const std::string& steps, const std::string& extra = "") {
    const std::string text = R"({"format": "factoria.audio/1", "source": ")" + source + R"(", "steps": [)" + steps + "]" + extra + "}";
    auto json = parse_json(text);
    REQUIRE_MESSAGE(json.ok(), (json.ok() ? "" : json.error().to_string()));
    return *json;
}

AudioClip render(const std::string& source, const std::string& steps, const std::string& extra = "") {
    auto doc = parse_audio_doc(doc_json(source, steps, extra), "test.audio.json");
    REQUIRE_MESSAGE(doc.ok(), (doc.ok() ? "" : doc.error().to_string()));
    auto clip = render_audio_doc(*doc, "test.audio.json");
    REQUIRE_MESSAGE(clip.ok(), (clip.ok() ? "" : clip.error().to_string()));
    return *clip;
}

std::string render_error(const std::string& source, const std::string& steps) {
    auto doc = parse_audio_doc(doc_json(source, steps), "test.audio.json");
    if (!doc.ok()) return doc.error().message + " " + doc.error().hint;
    auto clip = render_audio_doc(*doc, "test.audio.json");
    REQUIRE_FALSE(clip.ok());
    return clip.error().message + " " + clip.error().hint;
}

// Frequency from the upward zero crossings between two times.
double crossings_hz(const std::vector<float>& s, double t0, double t1) {
    const std::size_t a = std::size_t(t0 * kRate), b = std::min(s.size(), std::size_t(t1 * kRate));
    int count = 0;
    double first = -1, last = -1;
    for (std::size_t i = a + 1; i < b; ++i) {
        if (s[i - 1] < 0.0f && s[i] >= 0.0f) {
            const double t = double(i - 1) + double(-s[i - 1]) / double(s[i] - s[i - 1]);
            if (first < 0) first = t;
            last = t;
            ++count;
        }
    }
    return count < 2 ? 0.0 : double(count - 1) * kRate / (last - first);
}

double rms(const std::vector<float>& s, std::size_t a, std::size_t b) {
    double sum = 0;
    for (std::size_t i = a; i < b && i < s.size(); ++i) sum += double(s[i]) * s[i];
    return std::sqrt(sum / double(std::max<std::size_t>(1, b - a)));
}

double db(double v) { return 20.0 * std::log10(std::max(v, 1e-12)); }

std::uint64_t fingerprint(const std::vector<float>& s) {
    std::uint64_t h = 1469598103934665603ull;  // FNV-1a over the bits
    for (float v : s) {
        std::uint32_t bits;
        std::memcpy(&bits, &v, 4);
        for (int i = 0; i < 4; ++i) h = (h ^ ((bits >> (8 * i)) & 255)) * 1099511628211ull;
    }
    return h;
}

// A deterministic noise (own generator; the document's own seed is not involved).
std::vector<float> noise(std::size_t n, double amp = 0.3) {
    std::vector<float> out(n);
    std::uint32_t s = 12345;
    for (float& v : out) {
        s = s * 1664525u + 1013904223u;
        v = float(amp * (double(s >> 8) / double(1 << 24) * 2.0 - 1.0));
    }
    return out;
}

}  // namespace

TEST_CASE("audio doc: no steps re-exports the source; the numbers describe it") {
    DocProject p;
    p.sine("a.wav", 1.0, 441.0, 0.5);
    const AudioClip clip = render("a.wav", "");
    CHECK(clip.frames() == 44100);
    CHECK(clip.channels == 1);
    CHECK(clip.peakDb == doctest::Approx(-6.0).epsilon(0.02));
    CHECK(std::fabs(clip.lufs + 6.7) < 0.3);  // a -6 dBFS sine: -9 dB RMS, K-weighting, +3 dB for mono counted on both sides
    CHECK(clip.inputs == std::vector<std::string>{"a.wav"});
    CHECK_FALSE(clip.loop);
}

TEST_CASE("audio doc: trim by seconds keeps exactly that part; auto trim removes the silence and keeps the padding") {
    DocProject p;
    p.sine("a.wav", 1.0, 441.0);
    CHECK(render("a.wav", R"({"type":"trim","start":0.25,"end":0.75})").frames() == 22050);
    CHECK(render("a.wav", R"({"type":"trim","start":0.5,"length":0.1})").frames() == 4410);

    std::vector<float> s(kRate / 2, 0.0f);  // 0.5 s of silence, 0.2 s of tone, 0.3 s of silence
    add_sine(s, 0.2, 440.0, 0.5, kRate);
    s.resize(s.size() + std::size_t(0.3 * kRate), 0.0f);
    p.samples("gap.wav", s);
    const AudioClip trimmed = render("gap.wav", R"({"type":"trim","auto":true,"thresholdDb":-40,"padding":0.01})");
    CHECK(trimmed.seconds() == doctest::Approx(0.2 + 0.02).epsilon(0.03));
    CHECK(trimmed.peakDb == doctest::Approx(-6.0).epsilon(0.05));
    CHECK(render("gap.wav", R"({"type":"trim","auto":true,"padding":0})").seconds() < 0.2005);

    CHECK(render_error("a.wav", R"({"type":"trim","start":5})").find("/steps/0 (trim)") != std::string::npos);
    CHECK(render_error("gap.wav", R"({"type":"gain","db":-60},{"type":"trim","auto":true,"thresholdDb":-10})").find("below -10 dBFS") != std::string::npos);
}

TEST_CASE("audio doc: fade shapes the ends and leaves the middle alone") {
    DocProject p;
    p.samples("dc.wav", std::vector<float>(kRate, 0.5f));
    const AudioClip clip = render("dc.wav", R"({"type":"fade","in":0.1,"out":0.2})");
    const auto& s = clip.samples;
    CHECK(std::fabs(s.front()) < 1e-4f);
    CHECK(std::fabs(s.back()) < 1e-3f);
    CHECK(s[2205] == doctest::Approx(0.25f).epsilon(0.01));  // linear: half way through the fade in
    CHECK(s[22050] == doctest::Approx(0.5f).epsilon(0.001));
    const AudioClip power = render("dc.wav", R"({"type":"fade","in":0.1,"curve":"equalPower"})");
    CHECK(power.samples[2205] == doctest::Approx(0.5f * std::sin(std::numbers::pi / 4.0)).epsilon(0.01));
    const AudioClip expo = render("dc.wav", R"({"type":"fade","in":0.1,"curve":"exponential"})");
    CHECK(expo.samples[2205] == doctest::Approx(0.125f).epsilon(0.02));
}

TEST_CASE("audio doc: normalize reaches the peak or loudness target within half a unit") {
    DocProject p;
    p.sine("quiet.wav", 1.0, 441.0, 0.05);
    for (double target : {-1.0, -6.0, -12.0}) {
        const AudioClip clip = render("quiet.wav", R"({"type":"normalize","target":)" + std::to_string(target) + "}");
        CHECK(std::fabs(clip.peakDb - target) < 0.5);
    }
    for (double target : {-14.0, -20.0, -26.0}) {
        const AudioClip clip = render("quiet.wav", R"({"type":"normalize","mode":"lufs","target":)" + std::to_string(target) + R"(,"ceilingDb":-0.5})");
        CHECK(std::fabs(clip.lufs - target) < 0.5);
    }
    // the ceiling wins over the loudness target
    const AudioClip capped = render("quiet.wav", R"({"type":"normalize","mode":"lufs","target":-3,"ceilingDb":-6})");
    CHECK(capped.peakDb <= -5.5);
    CHECK(capped.lufs < -3.5);
    // silence stays silence
    p.samples("silence.wav", std::vector<float>(4410, 0.0f));
    CHECK(render("silence.wav", R"({"type":"normalize","target":-3})").peakDb < -100);
}

TEST_CASE("audio doc: gain is decibels") {
    DocProject p;
    p.sine("a.wav", 0.5, 441.0, 0.25);
    const AudioClip clip = render("a.wav", R"({"type":"gain","db":6.0206})");
    CHECK(clip.peakDb == doctest::Approx(-6.0).epsilon(0.01));
    CHECK(clip.samples[10] == doctest::Approx(render("a.wav", "").samples[10] * 2.0f).epsilon(0.001));
}

TEST_CASE("audio doc: pitch shifts the fundamental and keeps the duration; stretch changes the duration and keeps the pitch") {
    DocProject p;
    p.sine("a.wav", 1.0, 440.0, 0.5);
    const AudioClip base = render("a.wav", "");
    CHECK(crossings_hz(base.samples, 0.2, 0.8) == doctest::Approx(440.0).epsilon(0.002));

    for (double semitones : {12.0, 7.0, -12.0, -5.0}) {
        const AudioClip clip = render("a.wav", R"({"type":"pitch","semitones":)" + std::to_string(semitones) + "}");
        CHECK(clip.frames() == base.frames());
        const double want = 440.0 * std::pow(2.0, semitones / 12.0);
        CHECK(crossings_hz(clip.samples, 0.2, 0.8) == doctest::Approx(want).epsilon(0.015));
        CHECK(clip.peakDb == doctest::Approx(base.peakDb).epsilon(0.25));
    }

    for (double factor : {2.0, 0.5, 1.5}) {
        const AudioClip clip = render("a.wav", R"({"type":"stretch","factor":)" + std::to_string(factor) + "}");
        CHECK(double(clip.frames()) == doctest::Approx(44100.0 * factor).epsilon(0.002));
        CHECK(crossings_hz(clip.samples, 0.2 * factor, 0.8 * factor) == doctest::Approx(440.0).epsilon(0.015));
    }
    const AudioClip seconds = render("a.wav", R"({"type":"stretch","seconds":2.5})");
    CHECK(seconds.seconds() == doctest::Approx(2.5).epsilon(0.002));

    // the centroid of a noise burst rises with the pitch
    p.samples("n.wav", noise(kRate));
    const AudioClip noisy = render("n.wav", R"({"type":"eq","bands":[{"type":"lowPass","freq":3000}]})");
    const AudioClip up = render("n.wav", R"({"type":"eq","bands":[{"type":"lowPass","freq":3000}]},{"type":"pitch","semitones":12})");
    SfxAudio a, b;
    a.sampleRate = b.sampleRate = kRate;
    a.samples = noisy.samples;
    b.samples = up.samples;
    CHECK(sfx_centroid_hz(b) > sfx_centroid_hz(a) * 1.5);
}

TEST_CASE("audio doc: speed moves pitch and duration together") {
    DocProject p;
    p.sine("a.wav", 1.0, 440.0);
    const AudioClip clip = render("a.wav", R"({"type":"speed","factor":2})");
    CHECK(clip.frames() == 22050);
    CHECK(crossings_hz(clip.samples, 0.1, 0.45) == doctest::Approx(880.0).epsilon(0.005));
    CHECK(clip.peakDb == doctest::Approx(-6.0).epsilon(0.03));
}

TEST_CASE("audio doc: eq cuts and boosts where it says, and the filters pass the other side") {
    DocProject p;
    p.sine("low.wav", 0.5, 200.0, 0.3);
    p.sine("high.wav", 0.5, 6000.0, 0.3);
    p.sine("mid.wav", 0.5, 1000.0, 0.1);
    const std::size_t a = 11025, b = 22050;  // the settled second half
    auto level = [&](const std::string& src, const std::string& bands) { return db(rms(render(src, R"({"type":"eq","bands":)" + bands + "}").samples, a, b)) - db(rms(render(src, "").samples, a, b)); };
    CHECK(level("high.wav", R"([{"type":"lowPass","freq":1000}])") < -25.0);
    CHECK(level("low.wav", R"([{"type":"lowPass","freq":1000}])") > -0.5);
    CHECK(level("low.wav", R"([{"type":"highPass","freq":1000}])") < -20.0);
    CHECK(level("high.wav", R"([{"type":"highPass","freq":1000}])") > -0.5);
    CHECK(level("mid.wav", R"([{"type":"peak","freq":1000,"gainDb":9,"q":1}])") == doctest::Approx(9.0).epsilon(0.05));
    CHECK(level("mid.wav", R"([{"type":"peak","freq":4000,"gainDb":9,"q":4}])") == doctest::Approx(0.0).epsilon(0.5));
    CHECK(level("low.wav", R"([{"type":"lowShelf","freq":1000,"gainDb":6}])") == doctest::Approx(6.0).epsilon(0.1));
    CHECK(level("high.wav", R"([{"type":"highShelf","freq":1000,"gainDb":-6}])") == doctest::Approx(-6.0).epsilon(0.1));
}

TEST_CASE("audio doc: the compressor reduces what is above the threshold by the ratio") {
    DocProject p;
    p.sine("loud.wav", 1.0, 441.0, 0.9);  // -0.9 dBFS
    const AudioClip clip = render("loud.wav", R"({"type":"compressor","thresholdDb":-20,"ratio":4,"attack":0.001,"release":0.05})");
    // peak: -0.9 dB is 19.1 dB over the threshold, 4.8 dB over after compressing: -15.2 dBFS once the gain has settled
    double settled = 0;
    for (std::size_t i = 30000; i < clip.samples.size(); ++i) settled = std::max(settled, double(std::fabs(clip.samples[i])));
    CHECK(db(settled) == doctest::Approx(-15.2).epsilon(0.05));
    // below the threshold nothing changes
    p.sine("soft.wav", 0.5, 441.0, 0.05);
    CHECK(render("soft.wav", R"({"type":"compressor","thresholdDb":-20,"ratio":4})").peakDb == doctest::Approx(render("soft.wav", "").peakDb).epsilon(0.01));
    // makeup adds back
    const AudioClip made = render("loud.wav", R"({"type":"compressor","thresholdDb":-20,"ratio":4,"attack":0.001,"makeupDb":6})");
    CHECK(made.peakDb > clip.peakDb + 3.0);
}

TEST_CASE("audio doc: reverb and delay extend the sound by their tail and add what they promise") {
    DocProject p;
    std::vector<float> click(kRate / 10, 0.0f);
    click[0] = 0.8f;
    p.samples("click.wav", click);
    const AudioClip dry = render("click.wav", "");
    const AudioClip delayed = render("click.wav", R"({"type":"delay","time":0.05,"feedback":0.5,"mix":0.5})");
    CHECK(delayed.frames() > dry.frames());
    CHECK(std::fabs(delayed.samples[std::size_t(0.05 * kRate)]) > 0.1f);      // the first echo
    CHECK(std::fabs(delayed.samples[std::size_t(0.05 * kRate) + 1000]) < 0.01f);
    CHECK(std::fabs(delayed.samples[std::size_t(0.10 * kRate)]) > 0.05f);     // the second, quieter
    const AudioClip room = render("click.wav", R"({"type":"reverb","decay":1.0,"mix":0.5,"tail":1.0})");
    CHECK(room.seconds() == doctest::Approx(1.1).epsilon(0.01));
    CHECK(rms(room.samples, 6000, 20000) > 0.001);                              // a tail where the dry sound is silent
    CHECK(rms(dry.samples, 6000, 20000) == 0.0);
}

TEST_CASE("audio doc: reverse plays the samples backwards; layer mixes at an offset and a level") {
    DocProject p;
    p.samples("n.wav", noise(5000));
    const AudioClip fwd = render("n.wav", ""), rev = render("n.wav", R"({"type":"reverse"})");
    REQUIRE(rev.frames() == fwd.frames());
    for (std::size_t i = 0; i < fwd.frames(); i += 97) CHECK(rev.samples[i] == fwd.samples[fwd.frames() - 1 - i]);

    p.sine("a.wav", 0.5, 440.0, 0.3);
    p.sine("b.wav", 0.5, 1000.0, 0.3);
    const AudioClip mix = render("a.wav", R"({"type":"layer","source":"b.wav","offset":0.25,"gainDb":-6})");
    CHECK(mix.seconds() == doctest::Approx(0.75).epsilon(0.002));
    const AudioClip a = render("a.wav", "");
    CHECK(mix.samples[1000] == a.samples[1000]);                       // before the layer starts
    CHECK(rms(mix.samples, 12000, 21000) > rms(a.samples, 12000, 21000) * 1.05);  // two sounds are louder than one
    CHECK(rms(mix.samples, 25000, 33000) == doctest::Approx(0.3 * 0.5 / std::sqrt(2.0) * 1.0).epsilon(0.06));  // the layer alone, 6 dB down
    CHECK(mix.inputs == std::vector<std::string>{"a.wav", "b.wav"});
    CHECK(render_error("a.wav", R"({"type":"layer","source":"missing.wav"})").find("missing.wav") != std::string::npos);
}

TEST_CASE("audio doc: a loop crossfades the seam so the wave carries on, and reports the loop points") {
    DocProject p;
    p.sine("a.wav", 1.0, 440.3, 0.5);  // a period that does not divide the body: a plain cut would click
    const AudioClip clip = render("a.wav", R"({"type":"loop","start":0.2,"end":0.9,"crossfade":0.05})");
    REQUIRE(clip.loop.has_value());
    CHECK(clip.loop->start == std::size_t(std::llround(0.2 * kRate)));
    CHECK(clip.loop->end == std::size_t(std::llround(0.9 * kRate)) - std::size_t(std::llround(0.05 * kRate)));
    CHECK(clip.frames() == clip.loop->end);
    const auto& s = clip.samples;
    const double maxStep = 0.5 * 2.0 * std::numbers::pi * 440.3 / kRate;
    const double seam = std::fabs(double(s[clip.loop->start]) - double(s[clip.loop->end - 1]));
    CHECK(seam <= maxStep * 1.2);
    // the plain cut is not continuous: that is what the crossfade fixes
    const AudioClip cut = render("a.wav", R"({"type":"trim","start":0.2,"end":0.85})");
    const double plain = std::fabs(double(cut.samples.front()) - double(cut.samples.back()));
    CHECK(plain > maxStep * 2.0);
    // the intro before `start` is untouched
    CHECK(s[1000] == render("a.wav", "").samples[1000]);
    // linear curve: the same continuity
    const AudioClip lin = render("a.wav", R"({"type":"loop","start":0.2,"end":0.9,"crossfade":0.05,"curve":"linear"})");
    CHECK(std::fabs(double(lin.samples[lin.loop->start]) - double(lin.samples[lin.loop->end - 1])) <= maxStep * 1.2);
    // gain keeps the loop; another step after it is refused when the document is read
    CHECK(render("a.wav", R"({"type":"loop","start":0.2,"crossfade":0.05},{"type":"gain","db":-3})").loop.has_value());
    auto bad = parse_audio_doc(doc_json("a.wav", R"({"type":"loop","crossfade":0.05},{"type":"reverse"})"));
    REQUIRE_FALSE(bad.ok());
    CHECK(bad.error().message.find("/steps/1") != std::string::npos);
    CHECK(render_error("a.wav", R"({"type":"loop","start":0.2,"end":0.3,"crossfade":0.2})").find("crossfade") != std::string::npos);
}

TEST_CASE("audio doc: granular is a texture of the source, deterministic for a seed, different for another") {
    DocProject p;
    p.sine("a.wav", 1.0, 440.0, 0.5);
    const std::string step = R"({"type":"granular","length":2.0,"grainSize":0.05,"density":60,"jitter":0.3,"pitchSpread":3,"seed":7})";
    const AudioClip one = render("a.wav", step), two = render("a.wav", step);
    CHECK(one.frames() == 88200);
    CHECK(one.samples == two.samples);
    CHECK(fingerprint(one.samples) == fingerprint(two.samples));
    CHECK(rms(one.samples, 20000, 60000) > 0.05);
    CHECK(one.peakDb < -1.0);  // the grains are normalized by their overlap: no pile-up
    const AudioClip other = render("a.wav", R"({"type":"granular","length":2.0,"grainSize":0.05,"density":60,"jitter":0.3,"pitchSpread":3,"seed":8})");
    CHECK(fingerprint(other.samples) != fingerprint(one.samples));
    // the document seed changes it too, and a render option replaces it
    const AudioClip docSeed = render("a.wav", step, R"(, "seed": 5)");
    CHECK(fingerprint(docSeed.samples) != fingerprint(one.samples));
    auto doc = parse_audio_doc(doc_json("a.wav", step, R"(, "seed": 5)"));
    REQUIRE(doc.ok());
    AudioRenderOptions options;
    options.seed = 0;
    auto replaced = render_audio_doc(*doc, "t", options);
    REQUIRE(replaced.ok());
    CHECK(fingerprint(replaced->samples) == fingerprint(render("a.wav", step).samples));
    // pinned: the same bytes on every platform and compiler (own math only)
    CHECK(fingerprint(one.samples) == 6780228220918206588ull);
}

TEST_CASE("audio doc: the whole chain is deterministic and the WAV bytes are identical") {
    DocProject p;
    p.samples("n.wav", noise(30000));
    const std::string steps = R"({"type":"trim","auto":true},{"type":"eq","bands":[{"type":"peak","freq":800,"gainDb":4}]},{"type":"pitch","semitones":-3},{"type":"stretch","factor":1.3},)"
                              R"({"type":"compressor"},{"type":"reverb","tail":0.3},{"type":"fade","in":0.01,"out":0.05},{"type":"normalize","target":-2})";
    const AudioClip a = render("n.wav", steps), b = render("n.wav", steps);
    CHECK(a.samples == b.samples);
    CHECK(audio_wav_bytes(a) == audio_wav_bytes(b));
    CHECK(a.steps.size() == 8);
    CHECK(a.steps[3].seconds == doctest::Approx(a.steps[2].seconds * 1.3).epsilon(0.01));
    // pinned across platforms
    CHECK(fingerprint(a.samples) == 9120487498610528295ull);
}

TEST_CASE("audio doc: stopAfter renders the chain up to a step; enabled false skips one") {
    DocProject p;
    p.sine("a.wav", 1.0, 440.0, 0.5);
    auto doc = parse_audio_doc(doc_json("a.wav", R"({"type":"trim","length":0.5},{"type":"gain","db":-6,"enabled":false},{"type":"speed","factor":2})"));
    REQUIRE(doc.ok());
    AudioRenderOptions options;
    options.stopAfter = 0;
    auto first = render_audio_doc(*doc, "t", options);
    REQUIRE(first.ok());
    CHECK(first->frames() == 22050);
    CHECK(first->steps.size() == 1);
    auto all = render_audio_doc(*doc, "t");
    REQUIRE(all.ok());
    CHECK(all->frames() == 11025);
    CHECK(all->steps[1].skipped);
    CHECK(all->peakDb == doctest::Approx(-6.0).epsilon(0.03));  // the skipped gain did nothing
}

TEST_CASE("audio doc: sources can be a synth patch or another document; a document that uses itself is refused") {
    DocProject p;
    p.text("blip.sfx.json", R"({"format": "factoria.sfx/1", "length": 0.2, "layers": [{"oscillators": [{"wave": "sine"}], "pitch": {"note": "A4"}, "amp": {"attack": 0.002, "decay": 0.1, "sustain": 0}}]})");
    const AudioClip fromPatch = render("blip.sfx.json", R"({"type":"gain","db":-3})");
    CHECK(fromPatch.seconds() > 0.19);
    CHECK(fromPatch.inputs == std::vector<std::string>{"blip.sfx.json"});

    p.text("inner.audio.json", dump_json(doc_json("blip.sfx.json", R"({"type":"speed","factor":2})")));
    const AudioClip nested = render("inner.audio.json", R"({"type":"gain","db":-3})");
    CHECK(nested.seconds() == doctest::Approx(fromPatch.seconds() / 2.0).epsilon(0.05));
    CHECK(nested.inputs == std::vector<std::string>{"inner.audio.json", "blip.sfx.json"});

    p.text("a.audio.json", dump_json(doc_json("b.audio.json", "")));
    p.text("b.audio.json", dump_json(doc_json("a.audio.json", "")));
    auto doc = load_audio_doc("a.audio.json");
    REQUIRE(doc.ok());
    auto cyc = render_audio_doc(*doc, "a.audio.json");
    REQUIRE_FALSE(cyc.ok());
    CHECK(cyc.error().message.find("itself") != std::string::npos);
}

TEST_CASE("audio doc: stereo sources stay stereo or mix down; the clip converts to mono by averaging") {
    DocProject p;
    std::vector<float> st;
    for (int i = 0; i < 4410; ++i) {
        st.push_back(0.4f);
        st.push_back(-0.2f);
    }
    p.samples("st.wav", st, 2);
    const AudioClip stereo = render("st.wav", R"({"type":"gain","db":0})");
    CHECK(stereo.channels == 2);
    CHECK(stereo.samples[0] == doctest::Approx(0.4f).epsilon(0.001));
    CHECK(stereo.mono()[5] == doctest::Approx(0.1f).epsilon(0.01));
    const AudioClip mono = render("st.wav", "", R"(, "output": {"channels": "mono"})");
    CHECK(mono.channels == 1);
    CHECK(mono.samples[5] == doctest::Approx(0.1f).epsilon(0.01));
}

TEST_CASE("audio doc: WAV output carries the loop points in a smpl chunk, and Ogg encodes") {
    DocProject p;
    p.sine("a.wav", 1.0, 440.0);
    const AudioClip clip = render("a.wav", R"({"type":"loop","start":0.1,"end":0.8,"crossfade":0.05})");
    const auto wav = audio_wav_bytes(clip);
    const std::string text(wav.begin(), wav.end());
    const std::size_t smpl = text.find("smpl");
    REQUIRE(smpl != std::string::npos);
    auto u32 = [&](std::size_t at) { return std::uint32_t(wav[at]) | (std::uint32_t(wav[at + 1]) << 8) | (std::uint32_t(wav[at + 2]) << 16) | (std::uint32_t(wav[at + 3]) << 24); };
    CHECK(u32(smpl + 8 + 28) == 1);                              // one loop
    CHECK(u32(smpl + 8 + 36 + 8) == clip.loop->start);
    CHECK(u32(smpl + 8 + 36 + 12) == clip.loop->end - 1);
    CHECK(audio_wav_bytes(render("a.wav", "")).size() == 44 + 44100 * 2);

    AudioOutput out;
    out.format = "ogg";
    out.quality = 0.4;
    auto ogg = audio_encode(render("a.wav", ""), out);
    REQUIRE(ogg.ok());
    CHECK(std::string(ogg->begin(), ogg->begin() + 4) == "OggS");
    CHECK(ogg->size() < 44100);
}

TEST_CASE("audio doc: a document with mistakes lists every one with its pointer and a fix") {
    auto json = parse_json(R"({"format": "factoria.audio/1", "source": "a.wav", "steps": [
        {"type": "fad", "out": 0.1},
        {"type": "pitch", "semitones": 40},
        {"type": "stretch"},
        {"type": "trim", "strt": 1},
        {"type": "eq", "bands": [{"type": "peek", "freq": 100}]}]})");
    REQUIRE(json.ok());
    std::vector<AudioDocIssue> issues;
    auto doc = parse_audio_doc(*json, "bad.audio.json", &issues);
    REQUIRE_FALSE(doc.ok());
    CHECK(doc.error().message.find("bad.audio.json") != std::string::npos);
    auto find = [&](const std::string& pointer) -> const AudioDocIssue* {
        for (const AudioDocIssue& i : issues)
            if (i.pointer == pointer) return &i;
        return nullptr;
    };
    REQUIRE(find("/steps/0/type"));
    CHECK(find("/steps/0/type")->hint.find("fade") != std::string::npos);
    REQUIRE(find("/steps/1/semitones"));
    CHECK(find("/steps/1/semitones")->message.find("40") != std::string::npos);
    CHECK(find("/steps/2"));
    REQUIRE(find("/steps/3/strt"));
    CHECK(find("/steps/3/strt")->hint.find("start") != std::string::npos);
    CHECK(issues.size() >= 5);
    for (const AudioDocIssue& i : issues) CHECK_FALSE(i.hint.empty());

    auto empty = parse_audio_doc(*parse_json(R"({"steps": []})"), "x");
    CHECK_FALSE(empty.ok());
    CHECK(audio_step_types().size() == 15);
}

TEST_CASE("audio: loop points in the import settings make a looping clip wrap inside the region") {
    Fixture fx;
    std::vector<float> s(kRate, 0.1f);  // 0.5 s at 0.1, then 0.5 s at 0.5
    std::fill(s.begin() + kRate / 2, s.end(), 0.5f);
    write_file(fx.dir / "sounds/step.wav", wav_bytes(s, 1, kRate));
    fx.write_assets(R"({"assets": {"sounds/step.wav": {"import": {"loopStart": 0.5, "loopEnd": 1.0}}}})");
    fx.audio.start_recording();
    PlayParams lp;
    lp.loop = true;
    fx.audio.play("sounds/step.wav", lp);
    fx.run(3.0);
    const Recording rec = fx.finish("out/looped.wav");
    auto at = [&](double t) { return std::fabs(rec.l[std::size_t(t * kRate)]); };
    CHECK(at(0.25) > 0.0f);
    CHECK(at(1.5) == doctest::Approx(at(0.25) * 5.0f).epsilon(0.05));  // the intro never plays again: the second half repeats
    CHECK(at(2.9) == doctest::Approx(at(0.25) * 5.0f).epsilon(0.05));

    // without loop points the whole clip repeats
    Fixture fy;
    write_file(fy.dir / "sounds/step.wav", wav_bytes(s, 1, kRate));
    fy.audio.start_recording();
    fy.audio.play("sounds/step.wav", lp);
    fy.run(3.0);
    const Recording whole = fy.finish("out/whole.wav");
    CHECK(std::fabs(whole.l[std::size_t(1.25 * kRate)]) == doctest::Approx(std::fabs(whole.l[std::size_t(0.25 * kRate)])).epsilon(0.05));
}
