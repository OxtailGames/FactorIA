// Renders an audio document (audio_doc.h): loads the source, applies the steps in order on `double` samples, measures, and writes WAV
// or OGG bytes. The effects (reverb, delay) and the loudness measure are the synth's own (sfx.h); the time stretch and the resampler
// are audio_dsp.cpp's. Deterministic: see audio_doc.h.
#include <algorithm>
#include <cmath>
#include <format>

#include "fa/audio/analysis.h"
#include "fa/audio/audio_doc.h"
#include "fa/audio/convert.h"
#include "fa/core/fs.h"
#include "fa/core/strings.h"
#include "sfx_math.h"

namespace fa {

namespace {

using sfx_math::SfxRng;
using sfx_math::cos_turns;
using sfx_math::db_to_gain;
using sfx_math::exp2;
using sfx_math::gain_to_db;
using sfx_math::kLog10Of2;
using sfx_math::kLog2E;
using sfx_math::log2;
using sfx_math::sin_turns;

constexpr int kMaxDepth = 8;  // documents layering documents

struct Buf {
    int rate = 44100;
    std::vector<std::vector<double>> ch;  // 1 or 2 channels of the same length
    std::optional<AudioLoop> loop;
    std::size_t frames() const { return ch.empty() ? 0 : ch[0].size(); }
    double seconds() const { return rate > 0 ? double(frames()) / double(rate) : 0.0; }
};

struct Context {
    std::vector<std::string> stack;   // documents being rendered (cycle guard)
    std::vector<std::string> inputs;  // files read
    void input(const std::string& path) {
        if (std::find(inputs.begin(), inputs.end(), path) == inputs.end()) inputs.push_back(path);
    }
};

struct Failure {
    std::string message, hint;
};
// Steps fail with one of these; render_audio_doc turns it into a Result with the step's pointer.
[[noreturn]] void fail(std::string message, std::string hint) { throw Failure{std::move(message), std::move(hint)}; }

double peak_of(const Buf& b) {
    double p = 0.0;
    for (const auto& c : b.ch)
        for (double s : c) p = std::max(p, std::fabs(s));
    return p;
}

void check_length(std::size_t frames, int rate, const char* what) {
    if (double(frames) > kAudioDocMaxSeconds * double(rate))
        fail(std::string(what) + " would be " + std::format("{:.0f}", double(frames) / double(rate)) + " seconds long",
             std::format("Sounds in an audio document are at most {:.0f} seconds; trim or stretch less.", kAudioDocMaxSeconds));
}

// ---- helpers over parameters ----

double num(const Json& p, const char* key, double fallback = 0.0) { return p.contains(key) && p[key].is_number() ? p[key].get<double>() : fallback; }

std::size_t secs_to_frames(double seconds, int rate) { return std::size_t(std::llround(std::max(0.0, seconds) * double(rate))); }

void make_stereo(Buf& b) {
    if (b.ch.size() == 1) b.ch.push_back(b.ch[0]);
}

// ---- sources ----

Result<AudioClip> render_nested(const AudioDoc& doc, const std::string& file, Context& ctx, int depth, std::optional<std::uint64_t> seed);

Buf load_source(const AudioSourceRef& src, Context& ctx, int depth, std::uint64_t docSeed) {
    const std::string lower = to_lower(src.path);
    Buf buf;
    if (ends_with(lower, ".sfx.json")) {
        std::vector<SfxIssue> issues;
        auto patch = load_sfx(src.path, &issues);
        if (!patch) fail("the sound patch '" + src.path + "' is not valid: " + patch.error().message, patch.error().hint.empty() ? "sfx.info checks a patch and lists every problem." : patch.error().hint);
        ctx.input(src.path);
        SfxRenderOptions options;
        options.seed = src.seed;
        if (src.hz) options.freqHz = *src.hz;
        auto audio = render_sfx(*patch, options);
        if (!audio) fail("the sound patch '" + src.path + "' cannot be rendered: " + audio.error().message, audio.error().hint);
        buf.rate = audio->sampleRate;
        buf.ch.assign(1, std::vector<double>(audio->samples.begin(), audio->samples.end()));
        return buf;
    }
    if (ends_with(lower, kAudioDocSuffix)) {
        if (depth + 1 > kMaxDepth) fail("audio documents are nested more than " + std::to_string(kMaxDepth) + " deep at '" + src.path + "'", "Flatten the chain: bake the inner document and use its sound as the source.");
        if (std::find(ctx.stack.begin(), ctx.stack.end(), src.path) != ctx.stack.end())
            fail("'" + src.path + "' uses itself as a source (directly or through another document)", "A document cannot be built from its own sound; break the cycle.");
        std::vector<AudioDocIssue> issues;
        auto inner = load_audio_doc(src.path, &issues);
        if (!inner) fail("the audio document '" + src.path + "' is not valid: " + inner.error().message, inner.error().hint);
        ctx.input(src.path);
        auto clip = render_nested(*inner, src.path, ctx, depth + 1, src.seed ? std::optional<std::uint64_t>(src.seed) : std::nullopt);
        if (!clip) fail(clip.error().message, clip.error().hint);
        buf.rate = clip->sampleRate;
        buf.ch.assign(std::size_t(clip->channels), std::vector<double>(clip->frames()));
        for (std::size_t i = 0; i < clip->frames(); ++i)
            for (int c = 0; c < clip->channels; ++c) buf.ch[std::size_t(c)][i] = clip->samples[i * std::size_t(clip->channels) + std::size_t(c)];
        return buf;
    }
    (void)docSeed;
    auto file = read_audio_file(src.path);
    if (!file) fail("cannot read the sound '" + src.path + "': " + file.error().message, file.error().hint.empty() ? "Use a project-relative path such as \"assets/raw/door.wav\"." : file.error().hint);
    ctx.input(src.path);
    auto decoded = decode_audio(file->bytes, fs::extension(file->path), kAudioDocMaxSeconds + 1.0);
    if (!decoded) fail("cannot decode '" + src.path + "': " + decoded.error().message, decoded.error().hint);
    if (decoded->frames() == 0) fail("'" + src.path + "' has no audio samples", "Check that the file is not empty or cut short.");
    buf.rate = decoded->rate;
    buf.ch.assign(std::size_t(decoded->channels), std::vector<double>(decoded->frames()));
    for (std::size_t i = 0; i < decoded->frames(); ++i)
        for (int c = 0; c < decoded->channels; ++c) buf.ch[std::size_t(c)][i] = decoded->samples[i * std::size_t(decoded->channels) + std::size_t(c)];
    check_length(buf.frames(), buf.rate, ("'" + src.path + "'").c_str());
    return buf;
}

// ---- steps ----

void step_trim(Buf& b, const Json& p) {
    const std::size_t n = b.frames();
    const std::size_t s0 = std::min(n, secs_to_frames(num(p, "start"), b.rate));
    std::size_t e0 = n;
    if (p.contains("end")) e0 = std::min(n, secs_to_frames(num(p, "end"), b.rate));
    else if (p.contains("length")) e0 = std::min(n, s0 + secs_to_frames(num(p, "length"), b.rate));
    if (e0 <= s0) fail(std::format("the trim leaves nothing: the sound is {:.3f} s long and the trim starts at {:.3f} s", b.seconds(), num(p, "start")), "Use a `start` inside the sound (audio.info says how long it is at this point).");
    for (auto& c : b.ch) c = std::vector<double>(c.begin() + std::ptrdiff_t(s0), c.begin() + std::ptrdiff_t(e0));
    if (p.value("auto", false)) {
        const double threshold = db_to_gain(num(p, "thresholdDb", -50.0));
        const std::size_t m = b.frames();
        std::size_t first = m, last = 0;
        for (std::size_t i = 0; i < m; ++i) {
            double v = 0.0;
            for (const auto& c : b.ch) v = std::max(v, std::fabs(c[i]));
            if (v >= threshold) {
                first = std::min(first, i);
                last = i;
            }
        }
        if (first == m) fail(std::format("the whole sound is below {:.0f} dBFS, so auto trim would remove all of it", num(p, "thresholdDb", -50.0)), "Lower thresholdDb (e.g. -70) or normalize before the trim.");
        const std::size_t pad = secs_to_frames(num(p, "padding", 0.01), b.rate);
        const std::size_t from = first > pad ? first - pad : 0, to = std::min(m, last + 1 + pad);
        for (auto& c : b.ch) c = std::vector<double>(c.begin() + std::ptrdiff_t(from), c.begin() + std::ptrdiff_t(to));
    }
}

double fade_curve(const std::string& curve, double x) {
    if (curve == "equalPower") return sin_turns(x * 0.25);
    if (curve == "smooth") return 0.5 - 0.5 * cos_turns(x * 0.5);
    if (curve == "exponential") return x * x;
    if (curve == "logarithmic") return 1.0 - (1.0 - x) * (1.0 - x);
    return x;
}

void step_fade(Buf& b, const Json& p) {
    const std::string curve = p.value("curve", std::string("linear"));
    const std::size_t n = b.frames();
    const std::size_t in = std::min(n, secs_to_frames(num(p, "in"), b.rate)), out = std::min(n, secs_to_frames(num(p, "out"), b.rate));
    for (auto& c : b.ch) {
        for (std::size_t i = 0; i < in; ++i) c[i] *= fade_curve(curve, double(i) / double(in));
        for (std::size_t j = 0; j < out; ++j) c[n - 1 - j] *= fade_curve(curve, double(j) / double(out));
    }
}

void apply_gain(Buf& b, double gain) {
    for (auto& c : b.ch)
        for (double& s : c) s *= gain;
}

void measure(const Buf& b, double& lufs, double& peak) { sfx_measure_loudness(b.ch, b.rate, lufs, peak); }

void step_normalize(Buf& b, const Json& p) {
    double lufs = -70.0, peak = 0.0;
    measure(b, lufs, peak);
    if (peak < 1e-9) return;  // silence stays silence
    const bool byLoudness = p.value("mode", std::string("peak")) == "lufs";
    const double peakDb = gain_to_db(peak);
    double gainDb;
    if (byLoudness) {
        if (lufs <= -70.0) return;
        gainDb = std::min(std::clamp(num(p, "target", -16.0) - lufs, -60.0, 60.0), num(p, "ceilingDb", -1.0) - peakDb);
    } else {
        gainDb = std::clamp(num(p, "target", -1.0) - peakDb, -60.0, 60.0);
    }
    apply_gain(b, db_to_gain(gainDb));
}

void step_stretch(Buf& b, const Json& p) {
    double factor = p.contains("factor") ? num(p, "factor") : num(p, "seconds") / std::max(1e-9, b.seconds());
    factor = std::clamp(factor, 0.01, 100.0);
    check_length(std::size_t(double(b.frames()) * factor), b.rate, "the stretched sound");
    audio_time_stretch(b.ch, b.rate, factor);
}

void step_speed(Buf& b, const Json& p) {
    const double factor = num(p, "factor", 1.0);
    for (auto& c : b.ch) c = audio_resample(c, factor);
}

// ---- eq ----

struct Biquad {
    double b0 = 1, b1 = 0, b2 = 0, a1 = 0, a2 = 0, z1 = 0, z2 = 0;
    double process(double x) {
        const double y = b0 * x + z1;
        z1 = b1 * x - a1 * y + z2;
        z2 = b2 * x - a2 * y;
        return y;
    }
};

// RBJ audio-EQ-cookbook coefficients.
Biquad make_band(const std::string& type, double freq, double gainDb, double q, int rate) {
    freq = std::clamp(freq, 10.0, 0.49 * double(rate));
    const double sw = sin_turns(freq / double(rate)), cw = cos_turns(freq / double(rate));
    const double alpha = sw / (2.0 * q);
    const double A = sfx_math::pow10(gainDb / 40.0);
    double b0, b1, b2, a0, a1, a2;
    if (type == "lowPass") {
        b0 = (1 - cw) / 2; b1 = 1 - cw; b2 = b0; a0 = 1 + alpha; a1 = -2 * cw; a2 = 1 - alpha;
    } else if (type == "highPass") {
        b0 = (1 + cw) / 2; b1 = -(1 + cw); b2 = b0; a0 = 1 + alpha; a1 = -2 * cw; a2 = 1 - alpha;
    } else if (type == "peak") {
        b0 = 1 + alpha * A; b1 = -2 * cw; b2 = 1 - alpha * A; a0 = 1 + alpha / A; a1 = -2 * cw; a2 = 1 - alpha / A;
    } else {
        const double sq = 2.0 * std::sqrt(A) * alpha;
        if (type == "lowShelf") {
            b0 = A * ((A + 1) - (A - 1) * cw + sq); b1 = 2 * A * ((A - 1) - (A + 1) * cw); b2 = A * ((A + 1) - (A - 1) * cw - sq);
            a0 = (A + 1) + (A - 1) * cw + sq; a1 = -2 * ((A - 1) + (A + 1) * cw); a2 = (A + 1) + (A - 1) * cw - sq;
        } else {  // highShelf
            b0 = A * ((A + 1) + (A - 1) * cw + sq); b1 = -2 * A * ((A - 1) + (A + 1) * cw); b2 = A * ((A + 1) + (A - 1) * cw - sq);
            a0 = (A + 1) - (A - 1) * cw + sq; a1 = 2 * ((A - 1) - (A + 1) * cw); a2 = (A + 1) - (A - 1) * cw - sq;
        }
    }
    Biquad bq;
    bq.b0 = b0 / a0; bq.b1 = b1 / a0; bq.b2 = b2 / a0; bq.a1 = a1 / a0; bq.a2 = a2 / a0;
    return bq;
}

void step_eq(Buf& b, const Json& p) {
    for (const Json& band : p["bands"]) {
        for (auto& c : b.ch) {
            Biquad bq = make_band(band.value("type", std::string("peak")), num(band, "freq", 1000.0), num(band, "gainDb"), num(band, "q", 0.707), b.rate);
            for (double& s : c) s = bq.process(s);
        }
    }
}

// ---- compressor ----

void step_compressor(Buf& b, const Json& p) {
    const double threshold = num(p, "thresholdDb", -18.0), ratio = num(p, "ratio", 4.0), knee = num(p, "kneeDb"), makeup = num(p, "makeupDb");
    const double attack = exp2(-kLog2E / (num(p, "attack", 0.005) * double(b.rate))), release = exp2(-kLog2E / (num(p, "release", 0.1) * double(b.rate)));
    double reduction = 0.0;  // dB, 0 or negative
    for (std::size_t i = 0; i < b.frames(); ++i) {
        double level = 1e-9;
        for (const auto& c : b.ch) level = std::max(level, std::fabs(c[i]));
        const double db = gain_to_db(level), over = db - threshold;
        double outDb;
        if (knee > 0.0 && 2.0 * over > -knee && 2.0 * over < knee) {
            const double t = over + knee / 2.0;
            outDb = db + (1.0 / ratio - 1.0) * t * t / (2.0 * knee);
        } else if (over <= 0.0 || 2.0 * over <= -knee) {
            outDb = db;
        } else {
            outDb = threshold + over / ratio;
        }
        const double target = outDb - db;
        const double k = target < reduction ? attack : release;
        reduction = target + k * (reduction - target);
        const double g = db_to_gain(reduction + makeup);
        for (auto& c : b.ch) c[i] *= g;
    }
}

// ---- effects ----

void extend(Buf& b, std::size_t frames) {
    check_length(b.frames() + frames, b.rate, "the sound with its tail");
    for (auto& c : b.ch) c.resize(c.size() + frames, 0.0);
}

void step_reverb(Buf& b, const Json& p) {
    SfxEffect e;
    e.type = SfxEffectType::Reverb;
    e.mix = num(p, "mix", 0.3);
    e.decay = num(p, "decay", 1.5);
    e.damping = num(p, "damping", 0.5);
    e.size = num(p, "size", 1.0);
    e.preDelay = num(p, "preDelay");
    extend(b, secs_to_frames(p.contains("tail") ? num(p, "tail") : std::min(5.0, e.decay), b.rate));
    for (auto& c : b.ch) sfx_run_effects(c, {e}, b.rate);
}

void step_delay(Buf& b, const Json& p) {
    SfxEffect e;
    e.type = SfxEffectType::Delay;
    e.time = num(p, "time", 0.25);
    e.feedback = num(p, "feedback", 0.4);
    e.mix = num(p, "mix", 0.4);
    e.tone = num(p, "tone");
    double tail = num(p, "tail", -1.0);
    if (tail < 0.0) {
        // Repeats until the echo is 60 dB down: feedback^n = 0.001, at most 8 of them.
        const double repeats = e.feedback > 0.0 ? std::min(8.0, std::ceil(-3.0 / (log2(e.feedback) * kLog10Of2))) : 1.0;
        tail = e.time * (repeats + 1.0);
    }
    extend(b, secs_to_frames(tail, b.rate));
    for (auto& c : b.ch) sfx_run_effects(c, {e}, b.rate);
}

// ---- layer ----

void step_layer(Buf& b, const Json& p, Context& ctx, int depth, std::uint64_t docSeed) {
    AudioSourceRef ref;
    ref.path = p["source"].get<std::string>();
    ref.seed = std::uint64_t(num(p, "seed")) + docSeed * 0;
    if (p.contains("note")) {
        auto hz = sfx_note_hz(p["note"].get<std::string>());
        if (!hz) fail("note \"" + p["note"].get<std::string>() + "\" is not a note name", "Write a name like \"A4\", \"C#3\" or \"Bb2\".");
        ref.hz = hz;
    }
    Buf layer = load_source(ref, ctx, depth, docSeed);
    if (layer.rate != b.rate) {
        const double step = double(layer.rate) / double(b.rate);
        for (auto& c : layer.ch) c = audio_resample(c, step);
        layer.rate = b.rate;
    }
    if (num(p, "semitones") != 0.0) audio_pitch_shift(layer.ch, layer.rate, num(p, "semitones"));
    if (layer.ch.size() > b.ch.size()) make_stereo(b);
    else if (layer.ch.size() < b.ch.size()) make_stereo(layer);
    const double gain = db_to_gain(num(p, "gainDb"));
    const std::size_t offset = secs_to_frames(num(p, "offset"), b.rate);
    const std::size_t total = std::max(b.frames(), offset + layer.frames());
    check_length(total, b.rate, "the layered sound");
    for (std::size_t c = 0; c < b.ch.size(); ++c) {
        b.ch[c].resize(total, 0.0);
        for (std::size_t i = 0; i < layer.frames(); ++i) b.ch[c][offset + i] += layer.ch[c][i] * gain;
    }
}

// ---- loop ----

void step_loop(Buf& b, const Json& p) {
    const std::size_t n = b.frames();
    const std::size_t s0 = std::min(n, secs_to_frames(num(p, "start"), b.rate));
    const std::size_t e0 = p.contains("end") ? std::min(n, secs_to_frames(num(p, "end"), b.rate)) : n;
    if (e0 < s0 + 8) fail(std::format("the loop body is too short: it runs from {:.3f} s to {:.3f} s of a {:.3f} s sound", double(s0) / b.rate, double(e0) / b.rate, b.seconds()), "Set `start` and `end` inside the sound (audio.info says how long it is at this step).");
    const std::size_t xf = secs_to_frames(num(p, "crossfade", 0.05), b.rate);
    if (xf < 1 || xf * 2 > e0 - s0)
        fail(std::format("the crossfade of {:.3f} s does not fit: the loop body is {:.3f} s and the crossfade may be at most half of it", num(p, "crossfade", 0.05), double(e0 - s0) / b.rate),
             std::format("Use \"crossfade\" up to {:.3f} or a longer body.", double(e0 - s0) / b.rate / 2.0));
    const bool equalPower = p.value("curve", std::string("equalPower")) == "equalPower";
    // The end of the body, from e0-xf on, is mixed under the start of the body while it fades out: when playback wraps from the new end
    // to the start, the wave carries on from the sample before e0-xf into e0-xf itself.
    for (auto& c : b.ch) {
        for (std::size_t i = 0; i < xf; ++i) {
            const double x = double(i) / double(xf);
            const double up = equalPower ? sin_turns(x * 0.25) : x, down = equalPower ? cos_turns(x * 0.25) : 1.0 - x;
            c[s0 + i] = c[s0 + i] * up + c[e0 - xf + i] * down;
        }
        c.resize(e0 - xf);
    }
    b.loop = AudioLoop{s0, e0 - xf};
}

// ---- granular ----

void step_granular(Buf& b, const Json& p, std::uint64_t seed) {
    const std::size_t n = b.frames();
    const std::size_t s0 = std::min(n - 1, secs_to_frames(num(p, "start"), b.rate));
    const std::size_t e0 = p.contains("end") ? std::min(n, secs_to_frames(num(p, "end"), b.rate)) : n;
    if (e0 < s0 + 2) fail("the region to read grains from is empty", "Set `start` and `end` inside the sound (it is " + std::format("{:.3f}", b.seconds()) + " s long here).");
    const std::size_t length = std::max<std::size_t>(1, secs_to_frames(num(p, "length"), b.rate));
    check_length(length, b.rate, "the granular texture");
    const std::size_t grain = std::max<std::size_t>(4, secs_to_frames(num(p, "grainSize", 0.06), b.rate));
    const double density = num(p, "density", 40.0), jitter = num(p, "jitter", 0.2), spread = num(p, "pitchSpread"), scan = num(p, "scan", 1.0);
    const double region = double(e0 - s0);
    const double overlap = density * double(grain) / double(b.rate);
    const double norm = overlap > 1.0 ? 1.0 / std::sqrt(overlap) : 1.0;
    std::vector<double> window(grain);
    for (std::size_t j = 0; j < grain; ++j) window[j] = 0.5 - 0.5 * cos_turns((double(j) + 0.5) / double(grain));
    const double spacing = double(b.rate) / density;  // frames between grain starts
    const std::size_t count = std::size_t(std::floor(double(length) / spacing)) + 1;
    SfxRng rng{seed};
    rng.next();
    std::vector<std::vector<double>> out(b.ch.size(), std::vector<double>(length, 0.0));
    for (std::size_t k = 0; k < count; ++k) {
        const double u = rng.signed_unit(), pitchU = rng.signed_unit(), timeU = rng.signed_unit();  // always three draws per grain
        const double onset = double(k) * spacing + timeU * jitter * 0.5 * spacing;
        if (onset < -double(grain) || onset >= double(length)) continue;
        const double progress = std::clamp(onset / double(length), 0.0, 1.0);
        const double centre01 = std::clamp(progress * scan + 0.5 * (1.0 - scan) + u * jitter * 0.5, 0.0, 1.0);
        const double ratio = sfx_math::semitones_to_ratio(pitchU * spread);
        const double centre = double(s0) + centre01 * region;
        const double first = centre - 0.5 * double(grain) * ratio;
        const long long o0 = (long long)std::llround(onset);
        for (std::size_t j = 0; j < grain; ++j) {
            const long long o = o0 + (long long)j;
            if (o < 0 || o >= (long long)length) continue;
            const double pos = first + double(j) * ratio;
            if (pos < double(s0) || pos >= double(e0 - 1)) continue;
            const std::size_t i0 = std::size_t(pos);
            const double f = pos - double(i0);
            for (std::size_t c = 0; c < b.ch.size(); ++c)
                out[c][std::size_t(o)] += (b.ch[c][i0] + (b.ch[c][i0 + 1] - b.ch[c][i0]) * f) * window[j] * norm;
        }
    }
    b.ch = std::move(out);
    b.loop.reset();
}

std::uint64_t step_seed(std::uint64_t docSeed, std::size_t index, std::uint64_t own) {
    return docSeed * 0x2545F4914F6CDD1Dull + (std::uint64_t(index) + 1) * 0xD1B54A32D192ED03ull + own * 0x9E3779B97F4A7C15ull + 0x1234567ull;
}

// ---- the chain ----

Result<AudioClip> render_chain(const AudioDoc& doc, const std::string& file, Context& ctx, int depth, std::optional<std::uint64_t> seedOverride, int stopAfter) {
    const std::string where = file.empty() ? std::string("audio document") : file;
    const std::uint64_t docSeed = seedOverride ? *seedOverride : doc.seed;
    ctx.stack.push_back(file);
    AudioClip clip;
    try {
        Buf b;
        try {
            b = load_source(doc.source, ctx, depth, docSeed);
        } catch (const Failure& f) {
            throw Failure{where + " /source: " + f.message, f.hint};
        }
        for (std::size_t i = 0; i < doc.steps.size(); ++i) {
            if (stopAfter >= 0 && int(i) > stopAfter) break;
            const AudioStep& st = doc.steps[i];
            AudioStepReport report;
            report.type = st.type;
            if (st.params.value("enabled", true) == false) {
                report.skipped = true;
                report.seconds = b.seconds();
                report.peakDb = peak_of(b) > 1e-9 ? gain_to_db(peak_of(b)) : -200.0;
                clip.steps.push_back(report);
                continue;
            }
            try {
                const Json& p = st.params;
                const std::string& t = st.type;
                const bool hadLoop = b.loop.has_value();
                if (t == "trim") step_trim(b, p);
                else if (t == "fade") step_fade(b, p);
                else if (t == "normalize") step_normalize(b, p);
                else if (t == "gain") apply_gain(b, db_to_gain(num(p, "db")));
                else if (t == "pitch") audio_pitch_shift(b.ch, b.rate, num(p, "semitones"));
                else if (t == "stretch") step_stretch(b, p);
                else if (t == "speed") step_speed(b, p);
                else if (t == "eq") step_eq(b, p);
                else if (t == "compressor") step_compressor(b, p);
                else if (t == "reverb") step_reverb(b, p);
                else if (t == "delay") step_delay(b, p);
                else if (t == "reverse") { for (auto& c : b.ch) std::reverse(c.begin(), c.end()); }
                else if (t == "layer") step_layer(b, p, ctx, depth, docSeed);
                else if (t == "loop") step_loop(b, p);
                else if (t == "granular") step_granular(b, p, step_seed(docSeed, i, std::uint64_t(num(p, "seed"))));
                if (hadLoop && t != "gain" && t != "normalize") b.loop.reset();
            } catch (const Failure& f) {
                throw Failure{where + " /steps/" + std::to_string(i) + " (" + st.type + "): " + f.message, f.hint};
            }
            report.seconds = b.seconds();
            report.peakDb = peak_of(b) > 1e-9 ? gain_to_db(peak_of(b)) : -200.0;
            clip.steps.push_back(report);
        }
        if (doc.output.channels == "mono" && b.ch.size() == 2) {
            for (std::size_t i = 0; i < b.frames(); ++i) b.ch[0][i] = (b.ch[0][i] + b.ch[1][i]) * 0.5;
            b.ch.pop_back();
        }
        double lufs = -70.0, peak = 0.0;
        measure(b, lufs, peak);
        clip.sampleRate = b.rate;
        clip.channels = int(b.ch.size());
        clip.samples.resize(b.frames() * b.ch.size());
        for (std::size_t i = 0; i < b.frames(); ++i)
            for (std::size_t c = 0; c < b.ch.size(); ++c) clip.samples[i * b.ch.size() + c] = float(std::clamp(b.ch[c][i], -1.0, 1.0));
        clip.lufs = lufs;
        clip.peakDb = peak > 1e-9 ? gain_to_db(peak) : -200.0;
        clip.loop = b.loop;
        if (clip.frames() == 0) throw Failure{where + ": the chain left no samples", "Check the trim steps."};
    } catch (const Failure& f) {
        ctx.stack.pop_back();
        return make_error(f.message, f.hint);
    }
    ctx.stack.pop_back();
    clip.inputs = ctx.inputs;
    return clip;
}

Result<AudioClip> render_nested(const AudioDoc& doc, const std::string& file, Context& ctx, int depth, std::optional<std::uint64_t> seed) {
    return render_chain(doc, file, ctx, depth, seed, -1);
}

void put_u32(std::vector<std::uint8_t>& out, std::uint32_t v) { for (int i = 0; i < 4; ++i) out.push_back(std::uint8_t((v >> (8 * i)) & 255)); }
void put_u16(std::vector<std::uint8_t>& out, std::uint16_t v) { for (int i = 0; i < 2; ++i) out.push_back(std::uint8_t((v >> (8 * i)) & 255)); }
void put_tag(std::vector<std::uint8_t>& out, const char* s) { for (int i = 0; i < 4; ++i) out.push_back(std::uint8_t(s[i])); }

}  // namespace

std::vector<float> AudioClip::mono() const {
    std::vector<float> out(frames());
    for (std::size_t i = 0; i < out.size(); ++i) {
        double sum = 0.0;
        for (int c = 0; c < channels; ++c) sum += double(samples[i * std::size_t(channels) + std::size_t(c)]);
        out[i] = float(sum / double(channels));
    }
    return out;
}

Result<AudioClip> render_audio_doc(const AudioDoc& doc, std::string_view file, const AudioRenderOptions& options) {
    Context ctx;
    return render_chain(doc, std::string(file), ctx, 0, options.seed, options.stopAfter);
}

std::vector<std::uint8_t> audio_wav_bytes(const AudioClip& clip) {
    std::vector<std::uint8_t> out;
    const std::uint32_t dataBytes = std::uint32_t(clip.samples.size() * 2);
    const std::uint32_t smplBytes = clip.loop ? 8 + 36 + 24 : 0;
    out.reserve(44 + dataBytes + smplBytes);
    const std::uint16_t channels = std::uint16_t(clip.channels);
    put_tag(out, "RIFF"); put_u32(out, 36 + dataBytes + smplBytes); put_tag(out, "WAVE"); put_tag(out, "fmt "); put_u32(out, 16); put_u16(out, 1); put_u16(out, channels);
    put_u32(out, std::uint32_t(clip.sampleRate)); put_u32(out, std::uint32_t(clip.sampleRate) * channels * 2); put_u16(out, std::uint16_t(channels * 2)); put_u16(out, 16);
    put_tag(out, "data"); put_u32(out, dataBytes);
    for (float s : clip.samples) put_u16(out, std::uint16_t(std::int16_t(std::lround(std::clamp(s, -1.0f, 1.0f) * 32767.0f))));
    if (clip.loop) {  // the standard `smpl` chunk with one forward loop (its end is the last frame played, inclusive)
        put_tag(out, "smpl"); put_u32(out, 36 + 24);
        put_u32(out, 0); put_u32(out, 0); put_u32(out, std::uint32_t(1000000000.0 / double(clip.sampleRate))); put_u32(out, 60); put_u32(out, 0); put_u32(out, 0); put_u32(out, 0);
        put_u32(out, 1); put_u32(out, 0);
        put_u32(out, 0); put_u32(out, 0); put_u32(out, std::uint32_t(clip.loop->start)); put_u32(out, std::uint32_t(clip.loop->end - 1)); put_u32(out, 0); put_u32(out, 0);
    }
    return out;
}

Result<std::vector<std::uint8_t>> audio_encode(const AudioClip& clip, const AudioOutput& output) {
    std::vector<std::uint8_t> wav = audio_wav_bytes(clip);
    if (output.format != "ogg") return wav;
    return encode_vorbis(wav, output.quality);
}

}  // namespace fa
