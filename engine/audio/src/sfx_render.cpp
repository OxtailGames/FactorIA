// The synthesizer behind `*.sfx.json` (fa/audio/sfx.h): oscillators, FM and ring modulation, envelopes, filters, effects and
// layers, rendered offline into mono samples. Deterministic: see sfx.h and sfx_math.h for how (own math, no libm transcendentals).
#include <algorithm>
#include <array>
#include <cmath>
#include <format>
#include <numeric>

#include "fa/audio/sfx.h"
#include "sfx_macros.h"
#include "sfx_math.h"

namespace fa {

using sfx_math::SfxRng;
using sfx_math::db_to_gain;
using sfx_math::exp2;
using sfx_math::gain_to_db;
using sfx_math::kLog10Of2;
using sfx_math::kLog2E;
using sfx_math::kTwoPi;
using sfx_math::log2;
using sfx_math::pow10;
using sfx_math::semitones_to_ratio;
using sfx_math::sin_turns;
using sfx_math::tan_pi;
using sfx_math::cos_turns;

double SfxEnvelope::level(double t, double gate) const {
    if (t < 0.0) return 0.0;
    auto shaped = [&](double u) { return curve == 1.0 ? u : sfx_math::pow(u, curve); };
    auto held = [&](double tt) {  // the level while the note is held
        if (tt < attack) return attack > 0.0 ? shaped(tt / attack) : 1.0;
        tt -= attack;
        if (tt < decay) return sustain + (1.0 - sustain) * shaped(1.0 - tt / decay);
        return sustain;
    };
    if (t <= gate) return held(t);
    if (release <= 0.0) return 0.0;
    const double r = t - gate;
    if (r >= release) return 0.0;
    return held(gate) * shaped(1.0 - r / release);
}

namespace {

// ---- waves --------------------------------------------------------------------------------------------------------------

// PolyBLEP: the correction that removes the aliasing of a step edge. `t` is the phase 0..1, `dt` the phase step per sample.
double blep(double t, double dt) {
    if (t < dt) {
        t /= dt;
        return t + t - t * t - 1.0;
    }
    if (t > 1.0 - dt) {
        t = (t - 1.0) / dt;
        return t * t + t + t + 1.0;
    }
    return 0.0;
}

double frac(double x) { return x - std::floor(x); }

// One sample of a tone wave at phase `x` (turns). `dt` > 0 band-limits the edges of the saw and the square (polyBLEP); 0 is the
// plain shape (phase modulation moves the edges, so FM uses it). Saw, triangle and sine start at 0; the square starts high.
double tone(SfxWave wave, double x, double dt, double duty, const std::vector<double>* table) {
    switch (wave) {
        case SfxWave::Sine: return sin_turns(x);
        case SfxWave::Saw: {
            const double p = frac(x + 0.5);
            return 2.0 * p - 1.0 - (dt > 0.0 ? blep(p, dt) : 0.0);
        }
        case SfxWave::Square: {
            const double p = frac(x);
            double v = p < duty ? 1.0 : -1.0;
            if (dt > 0.0) v += blep(p, dt) - blep(frac(p + 1.0 - duty), dt);
            return v - (2.0 * duty - 1.0);  // no DC offset: a thin pulse swings around 0 like every other wave
        }
        case SfxWave::Triangle: return 4.0 * std::fabs(frac(x + 0.75) - 0.5) - 1.0;
        case SfxWave::Table: {
            const std::size_t n = table ? table->size() : 0;
            if (n == 0) return 0.0;
            const double pos = frac(x) * double(n);
            const std::size_t i = std::min(n - 1, std::size_t(pos));
            const double f = pos - double(i);
            return (*table)[i] + ((*table)[(i + 1) % n] - (*table)[i]) * f;
        }
        case SfxWave::Noise: break;
    }
    return 0.0;
}

// White, pink (Paul Kellet's filter) or brown (leaky integrator) noise, each scaled to about the same RMS as uniform white (0.577).
struct NoiseSource {
    SfxRng rng;
    SfxNoise color = SfxNoise::White;
    double b0 = 0, b1 = 0, b2 = 0, brown = 0;
    double next() {
        const double w = rng.signed_unit();
        switch (color) {
            case SfxNoise::White: return w;
            case SfxNoise::Pink:
                b0 = 0.99765 * b0 + w * 0.0990460;
                b1 = 0.96300 * b1 + w * 0.2965164;
                b2 = 0.57000 * b2 + w * 1.0526913;
                return (b0 + b1 + b2 + w * 0.1848) * 0.338;
            case SfxNoise::Brown:
                brown = (brown + 0.02 * w) / 1.02;
                return brown * 10.0;
        }
        return w;
    }
};

SfxRng stream(std::uint64_t seed, std::size_t layer, std::size_t osc) {
    SfxRng r{seed * 0x2545F4914F6CDD1Dull + 0x1234567ull + (std::uint64_t(layer) * 16 + std::uint64_t(osc) + 1) * 0xD1B54A32D192ED03ull};
    r.next();
    return r;
}

// ---- filter -------------------------------------------------------------------------------------------------------------

// A state-variable filter (the trapezoidal-integration form of Andrew Simper): stable while the cutoff moves.
struct Svf {
    double a1 = 0, a2 = 0, a3 = 0, k = 1, ic1 = 0, ic2 = 0;
    SfxFilterMode mode = SfxFilterMode::LowPass;
    void set(SfxFilterMode m, double cutoff, double q, double sampleRate) {
        mode = m;
        cutoff = std::clamp(cutoff, 20.0, 0.45 * sampleRate);
        const double g = tan_pi(cutoff / sampleRate);
        k = 1.0 / q;
        a1 = 1.0 / (1.0 + g * (g + k));
        a2 = g * a1;
        a3 = g * a2;
    }
    double process(double x) {
        const double v3 = x - ic2;
        const double v1 = a1 * ic1 + a2 * v3;
        const double v2 = ic2 + a2 * ic1 + a3 * v3;
        ic1 = 2.0 * v1 - ic1;
        ic2 = 2.0 * v2 - ic2;
        switch (mode) {
            case SfxFilterMode::LowPass: return v2;
            case SfxFilterMode::HighPass: return x - k * v1 - v2;
            case SfxFilterMode::BandPass: return k * v1;
        }
        return x;
    }
};

// ---- effects ------------------------------------------------------------------------------------------------------------

void fx_filter(std::vector<double>& buf, const SfxFilter& f, int rate) {
    Svf svf;
    const double n = double(std::max<std::size_t>(1, buf.size()));
    if (f.cutoffTo > 0.0) {
        const double octaves = log2(f.cutoffTo / f.cutoff);
        for (std::size_t i = 0; i < buf.size(); ++i) {
            svf.set(f.mode, f.cutoff * exp2(octaves * (double(i) / n)), f.resonance, rate);
            buf[i] = svf.process(buf[i]);
        }
    } else {
        svf.set(f.mode, f.cutoff, f.resonance, rate);
        for (double& s : buf) s = svf.process(s);
    }
}

void fx_distortion(std::vector<double>& buf, const SfxEffect& e) {
    for (double& s : buf) {
        const double y = s * e.drive;
        double w;
        switch (e.shape) {
            case SfxDistortion::Soft: w = sfx_math::tanh(y); break;
            case SfxDistortion::Hard: w = std::clamp(y, -1.0, 1.0); break;
            default: w = 1.0 - 4.0 * std::fabs(frac((y + 1.0) * 0.25) - 0.5); break;  // fold: a triangle wave of period 4
        }
        s = s * (1.0 - e.mix) + w * e.level * e.mix;
    }
}

void fx_bitcrush(std::vector<double>& buf, const SfxEffect& e, int rate) {
    const double levels = exp2(e.bits - 1.0);
    const double step = e.rate > 0.0 ? e.rate / double(rate) : 1.0;
    double acc = 1.0, held = 0.0;
    for (double& s : buf) {
        acc += step;
        if (acc >= 1.0) {
            acc -= 1.0;
            held = std::round(std::clamp(s, -1.0, 1.0) * levels) / levels;
        }
        s = s * (1.0 - e.mix) + held * e.mix;
    }
}

void fx_delay(std::vector<double>& buf, const SfxEffect& e, int rate) {
    const std::size_t length = std::max<std::size_t>(1, std::size_t(std::lround(e.time * double(rate))));
    std::vector<double> line(length, 0.0);
    const double smooth = e.tone > 0.0 ? 1.0 - exp2(-kTwoPi * (e.tone / double(rate)) * kLog2E) : 1.0;
    double lp = 0.0;
    std::size_t pos = 0;
    for (double& s : buf) {
        double echo = line[pos];
        lp += smooth * (echo - lp);
        echo = lp;
        line[pos] = s + echo * e.feedback;
        pos = (pos + 1) % length;
        s += echo * e.mix;
    }
}

// A Schroeder/Moorer reverb (Freeverb's layout): eight damped feedback combs in parallel, four all-passes in series.
void fx_reverb(std::vector<double>& buf, const SfxEffect& e, int rate) {
    constexpr std::array<int, 8> combs = {1116, 1188, 1277, 1356, 1422, 1491, 1557, 1617};
    constexpr std::array<int, 4> allpasses = {556, 441, 341, 225};
    const double scale = e.size * double(rate) / 44100.0;
    const double damp = e.damping * 0.85;
    struct Comb { std::vector<double> line; std::size_t pos = 0; double feedback = 0, store = 0; };
    std::vector<Comb> cs(combs.size());
    double power = 0.0;
    for (std::size_t c = 0; c < combs.size(); ++c) {
        const std::size_t len = std::max<std::size_t>(8, std::size_t(std::lround(double(combs[c]) * scale)));
        cs[c].line.assign(len, 0.0);
        cs[c].feedback = pow10(-3.0 * double(len) / (double(rate) * e.decay));
        power += 1.0 / (1.0 - cs[c].feedback * cs[c].feedback);
    }
    const double wetGain = 1.0 / std::sqrt(power);  // the wet signal has about the level of the input for noise
    struct Allpass { std::vector<double> line; std::size_t pos = 0; };
    std::vector<Allpass> aps(allpasses.size());
    for (std::size_t a = 0; a < allpasses.size(); ++a) aps[a].line.assign(std::max<std::size_t>(4, std::size_t(std::lround(double(allpasses[a]) * scale))), 0.0);
    const std::size_t preLength = std::size_t(std::lround(e.preDelay * double(rate)));
    std::vector<double> pre(preLength, 0.0);
    std::size_t prePos = 0;
    for (double& s : buf) {
        double in = s;
        if (preLength > 0) {
            std::swap(in, pre[prePos]);
            prePos = (prePos + 1) % preLength;
        }
        double sum = 0.0;
        for (Comb& c : cs) {
            const double out = c.line[c.pos];
            c.store = out * (1.0 - damp) + c.store * damp;
            c.line[c.pos] = in + c.store * c.feedback;
            c.pos = (c.pos + 1) % c.line.size();
            sum += out;
        }
        double wet = sum * wetGain;
        for (Allpass& a : aps) {
            const double out = a.line[a.pos];
            a.line[a.pos] = wet + out * 0.5;
            a.pos = (a.pos + 1) % a.line.size();
            wet = out - wet;
        }
        s += wet * e.mix;
    }
}

void apply_effects(std::vector<double>& buf, const std::vector<SfxEffect>& effects, int rate) {
    for (const SfxEffect& e : effects) {
        if (!e.enabled) continue;
        switch (e.type) {
            case SfxEffectType::Filter: fx_filter(buf, e.filter, rate); break;
            case SfxEffectType::Distortion: fx_distortion(buf, e); break;
            case SfxEffectType::Bitcrush: fx_bitcrush(buf, e, rate); break;
            case SfxEffectType::Delay: fx_delay(buf, e, rate); break;
            case SfxEffectType::Reverb: fx_reverb(buf, e, rate); break;
        }
    }
}

// ---- layers -------------------------------------------------------------------------------------------------------------

struct OscState {
    double phase = 0.0, modPhase = 0.0, ringPhase = 0.0;
    NoiseSource noise;
};

void render_layer(const SfxPatch& patch, const SfxLayer& layer, std::size_t index, std::uint64_t seed, double transpose, std::size_t startSample,
                  double length, std::vector<double>& mix) {
    const int rate = patch.sampleRate;
    const double dtBase = 1.0 / double(rate);
    const double gate = layer.length > 0.0 ? layer.length : std::max(0.001, length - layer.start);
    const std::size_t total = mix.size();
    if (startSample >= total) return;
    const std::size_t room = total - startSample;
    std::vector<double> buf(room, 0.0);
    const std::size_t active = std::min(room, std::size_t(std::lround((gate + layer.amp.release + 0.002) * double(rate))));

    std::vector<OscState> osc(layer.oscillators.size());
    for (std::size_t o = 0; o < osc.size(); ++o) {
        osc[o].noise.rng = stream(seed, index, o);
        osc[o].noise.color = layer.oscillators[o].noise;
        osc[o].phase = layer.oscillators[o].phase;
    }
    const SfxPitch& p = layer.pitch;
    const bool pitchMoves = p.sweep || p.env.enabled || (p.vibratoRate > 0.0 && p.vibratoDepth > 0.0) || !p.arpSteps.empty();
    const double sweepTime = p.sweepTime > 0.0 ? p.sweepTime : gate;
    std::vector<double> detune(layer.oscillators.size());
    for (std::size_t o = 0; o < detune.size(); ++o) detune[o] = exp2(layer.oscillators[o].detune / 1200.0);
    double ratio = transpose;

    Svf filter;
    const bool filterMoves = layer.filter.enabled && layer.filter.env.enabled;
    if (layer.filter.enabled) filter.set(layer.filter.mode, layer.filter.cutoff, layer.filter.resonance, rate);

    for (std::size_t n = 0; n < active; ++n) {
        const double t = double(n) * dtBase;
        const double amp = layer.amp.level(t, gate);
        if (pitchMoves) {
            double semis = 0.0;
            if (p.sweep) semis += p.sweepSemitones * sfx_math::pow(std::min(1.0, t / sweepTime), p.sweepCurve);
            if (p.env.enabled) semis += p.env.amount * p.env.env.level(t, gate);
            if (p.vibratoRate > 0.0 && p.vibratoDepth > 0.0) {
                const double fade = p.vibratoDelay > 0.0 ? std::min(1.0, t / p.vibratoDelay) : 1.0;
                semis += p.vibratoDepth * 0.01 * fade * sin_turns(p.vibratoRate * t);
            }
            if (!p.arpSteps.empty()) {
                const std::size_t step = std::size_t(t * p.arpRate);
                semis += p.arpSteps[p.arpLoop ? step % p.arpSteps.size() : std::min(step, p.arpSteps.size() - 1)];
            }
            ratio = transpose * semitones_to_ratio(semis);
        }
        double x = 0.0;
        for (std::size_t o = 0; o < osc.size(); ++o) {
            const SfxOscillator& def = layer.oscillators[o];
            OscState& st = osc[o];
            double v;
            if (def.wave == SfxWave::Noise) {
                v = st.noise.next();
            } else {
                const double f = std::min(def.freq > 0.0 ? def.freq : p.freq * ratio * def.ratio * detune[o], 0.49 * double(rate));
                const double dt = f * dtBase;
                if (def.fm.enabled) {
                    const double mf = def.fm.hz > 0.0 ? def.fm.hz : f * def.fm.ratio;
                    st.modPhase = frac(st.modPhase + mf * dtBase);
                    const double index = def.fm.index * (def.fm.hasIndexEnv ? def.fm.indexEnv.level(t, gate) : 1.0);
                    const double m = tone(def.fm.wave, st.modPhase, 0.0, 0.5, nullptr);
                    v = tone(def.wave, st.phase + index * m / kTwoPi, 0.0, def.duty, &def.table);
                } else {
                    v = tone(def.wave, st.phase, dt, def.duty, &def.table);
                }
                st.phase = frac(st.phase + dt);
                if (def.ring.enabled) {
                    const double rf = def.ring.hz > 0.0 ? def.ring.hz : f * def.ring.ratio;
                    st.ringPhase = frac(st.ringPhase + rf * dtBase);
                    v *= 1.0 - def.ring.mix + def.ring.mix * tone(def.ring.wave, st.ringPhase, 0.0, 0.5, nullptr);
                }
            }
            x += v * def.gain;
        }
        if (layer.filter.enabled) {
            if (filterMoves) {
                const double cutoff = layer.filter.cutoff * exp2(layer.filter.env.amount * layer.filter.env.env.level(t, gate));
                filter.set(layer.filter.mode, cutoff, layer.filter.resonance, rate);
            }
            x = filter.process(x);
        }
        double g = amp * layer.gain;
        if (layer.tremoloRate > 0.0 && layer.tremoloDepth > 0.0) g *= 1.0 - layer.tremoloDepth * (0.5 - 0.5 * sin_turns(layer.tremoloRate * t));
        buf[n] = x * g;
    }
    apply_effects(buf, layer.effects, rate);
    for (std::size_t i = 0; i < room; ++i) mix[startSample + i] += buf[i];
}

// ---- loudness (BS.1770, the algorithm of measure_loudness with this file's math) --------------------------------------------

struct Biquad {
    double b0 = 1, b1 = 0, b2 = 0, a1 = 0, a2 = 0, z1 = 0, z2 = 0;
    double process(double x) {
        const double y = b0 * x + z1;
        z1 = b1 * x - a1 * y + z2;
        z2 = b2 * x - a2 * y;
        return y;
    }
};

double lufs_of(double meanSquare) { return meanSquare > 0.0 ? -0.691 + 10.0 * kLog10Of2 * log2(meanSquare) : -1e9; }

// Integrated loudness of a clip played on both sides, -70 for silence; and its sample peak.
void measure(const std::vector<double>& samples, int rate, double& lufs, double& peak) {
    const double fs = double(rate);
    Biquad shelf, highpass;
    {
        constexpr double shelfHz = 1681.974450955533, shelfGainDb = 3.999843853973347, shelfQ = 0.7071752369554196;
        const double k = tan_pi(shelfHz / fs);
        const double vh = pow10(shelfGainDb / 20.0), vb = sfx_math::pow(vh, 0.4996667741545416);
        const double a0 = 1.0 + k / shelfQ + k * k;
        shelf.b0 = (vh + vb * k / shelfQ + k * k) / a0;
        shelf.b1 = 2.0 * (k * k - vh) / a0;
        shelf.b2 = (vh - vb * k / shelfQ + k * k) / a0;
        shelf.a1 = 2.0 * (k * k - 1.0) / a0;
        shelf.a2 = (1.0 - k / shelfQ + k * k) / a0;
        constexpr double highpassHz = 38.13547087602444, highpassQ = 0.5003270373238773;
        const double k2 = tan_pi(highpassHz / fs);
        const double b0 = 1.0 + k2 / highpassQ + k2 * k2;
        highpass.b0 = 1.0;
        highpass.b1 = -2.0;
        highpass.b2 = 1.0;
        highpass.a1 = 2.0 * (k2 * k2 - 1.0) / b0;
        highpass.a2 = (1.0 - k2 / highpassQ + k2 * k2) / b0;
    }
    const std::size_t hop = std::max<std::size_t>(1, std::size_t(std::lround(0.1 * fs)));
    const double blockLength = 4.0 * double(hop);
    double ring[4] = {};
    double hopEnergy = 0.0;
    std::size_t hopFill = 0, hops = 0;
    std::vector<double> blocks;
    peak = 0.0;
    for (double s : samples) {
        peak = std::max(peak, std::fabs(s));
        const double y = highpass.process(shelf.process(s));
        hopEnergy += 2.0 * y * y;  // both sides
        if (++hopFill < hop) continue;
        ring[hops++ % 4] = hopEnergy;
        hopEnergy = 0.0;
        hopFill = 0;
        if (hops >= 4) blocks.push_back((ring[0] + ring[1] + ring[2] + ring[3]) / blockLength);
    }
    if (blocks.empty()) blocks.push_back((ring[0] + ring[1] + ring[2] + ring[3] + hopEnergy) / blockLength);
    std::vector<double> audible;
    for (double z : blocks)
        if (lufs_of(z) > -70.0) audible.push_back(z);
    lufs = -70.0;
    if (audible.empty()) return;
    const double relativeGate = lufs_of(std::accumulate(audible.begin(), audible.end(), 0.0) / double(audible.size())) - 10.0;
    double sum = 0.0;
    std::size_t count = 0;
    for (double z : audible)
        if (lufs_of(z) > relativeGate) { sum += z; ++count; }
    if (count > 0) lufs = lufs_of(sum / double(count));
}

}  // namespace

Result<SfxAudio> render_sfx(const SfxPatch& base, const SfxRenderOptions& options) {
    // Macros and variants change a copy of the patch; a patch without them is rendered as it is, bit for bit as before.
    const sfx_detail::MacroValues macros = sfx_detail::effective_macros(base, options.macros);
    const bool hasVariant = options.variant >= 0;
    if (hasVariant && (base.variations.count <= 0 || options.variant >= base.variations.count))
        return make_error(base.variations.count <= 0 ? "the patch declares no variations" : std::format("variant {} does not exist: the patch has {}", options.variant + 1, base.variations.count),
                          "Declare \"variations\": {\"count\": 6} in the patch; variants are numbered from 1.");
    SfxPatch work;
    const SfxPatch* use = &base;
    double macroTranspose = 1.0, velocity = options.velocity;
    sfx_detail::Tilt tilt;
    std::uint64_t variantSeed = 0;
    double lengthScale = 1.0;
    if (macros.any() || hasVariant) {
        work = base;
        use = &work;
        sfx_detail::apply_macros(work, macros, macroTranspose, tilt);
        if (hasVariant) {
            const SfxVariantParams v = sfx_variant_params(base.variations, options.variant);
            sfx_detail::apply_variant(work, v);
            macroTranspose *= exp2(v.pitchCents / 1200.0);
            velocity *= db_to_gain(v.gainDb);
            variantSeed = v.seedOffset;
            lengthScale = v.lengthScale;
        }
    }
    const SfxPatch& patch = *use;
    const double length = (options.length >= 0.0 ? options.length : patch.length) * lengthScale;
    const double tail = options.tail >= 0.0 ? options.tail : patch.tail;
    if (!(length + tail > 0.0) || length + tail > kSfxMaxSeconds)
        return make_error("a sound of " + std::to_string(length + tail) + " seconds cannot be rendered", "A sound patch is 0.001 to 30 seconds long (length + tail).");
    if (patch.layers.empty()) return make_error("the patch has no layers", "Add at least one layer with an oscillator; sfx.preset gives a full example.");
    const int rate = patch.sampleRate;
    const std::size_t total = std::max<std::size_t>(1, std::size_t(std::lround((length + tail) * double(rate))));
    const std::uint64_t seed = patch.seed + options.seed + variantSeed;
    const double transpose = (options.freqHz > 0.0 ? options.freqHz / patch.root_hz() : 1.0) * macroTranspose;

    std::vector<double> mix(total, 0.0);
    for (std::size_t i = 0; i < patch.layers.size(); ++i) {
        const SfxLayer& layer = patch.layers[i];
        render_layer(patch, layer, i, seed, transpose, std::size_t(std::lround(layer.start * double(rate))), length, mix);
    }
    if (patch.gain != 1.0)
        for (double& s : mix) s *= patch.gain;
    apply_effects(mix, patch.effects, rate);
    if (tilt.any()) sfx_detail::apply_tilt(mix, tilt, rate);

    const std::size_t fade = std::min(total, std::size_t(std::lround(patch.fadeOut * double(rate))));
    for (std::size_t i = 0; i < fade; ++i) mix[total - 1 - i] *= double(i) / double(fade);

    // Level the sound.
    const SfxNormalize norm = options.normalize ? *options.normalize : patch.normalize;
    double lufs = -70.0, peak = 0.0;
    measure(mix, rate, lufs, peak);
    double gainDb = 0.0;
    if (norm.mode != SfxNormalizeMode::None && peak > 1e-9 && (norm.mode == SfxNormalizeMode::Peak || lufs > -70.0)) {
        const double peakDb = gain_to_db(peak);
        if (norm.mode == SfxNormalizeMode::Peak) gainDb = std::clamp(norm.target - peakDb, -60.0, 60.0);
        else gainDb = std::min(std::clamp(norm.target - lufs, -24.0, 24.0), norm.ceilingDb - peakDb);
    }
    gainDb += gain_to_db(std::max(velocity, 1e-6)) * (velocity == 1.0 ? 0.0 : 1.0);
    const double gain = db_to_gain(gainDb);

    SfxAudio audio;
    audio.sampleRate = rate;
    audio.samples.resize(total);
    for (std::size_t i = 0; i < total; ++i) audio.samples[i] = float(std::clamp(mix[i] * gain, -1.0, 1.0));
    audio.lufs = lufs > -70.0 ? lufs + gainDb : -70.0;
    audio.peakDb = peak > 1e-9 ? gain_to_db(peak) + gainDb : -200.0;
    return audio;
}

void stretch_sfx(SfxPatch& patch, double factor) {
    if (!(factor > 0.0)) return;
    auto env = [&](SfxEnvelope& e) { e.attack *= factor; e.decay *= factor; e.release *= factor; };
    auto mod = [&](SfxModulation& m) { env(m.env); };
    auto fx = [&](std::vector<SfxEffect>& list) {
        for (SfxEffect& e : list) {
            e.time *= factor;
            e.preDelay *= factor;
            mod(e.filter.env);
        }
    };
    patch.length *= factor;
    patch.tail *= factor;
    for (SfxLayer& l : patch.layers) {
        l.start *= factor;
        l.length *= factor;
        env(l.amp);
        mod(l.pitch.env);
        mod(l.filter.env);
        l.pitch.sweepTime *= factor;
        l.pitch.vibratoDelay *= factor;
        l.pitch.arpRate /= factor;
        for (SfxOscillator& o : l.oscillators)
            if (o.fm.hasIndexEnv) env(o.fm.indexEnv);
        fx(l.effects);
    }
    fx(patch.effects);
}

std::vector<std::uint8_t> sfx_wav_bytes(const SfxAudio& audio) {
    std::vector<std::uint8_t> out;
    const std::uint32_t dataBytes = std::uint32_t(audio.samples.size() * 2);
    out.reserve(44 + dataBytes);
    auto u32 = [&](std::uint32_t v) { for (int i = 0; i < 4; ++i) out.push_back(std::uint8_t((v >> (8 * i)) & 255)); };
    auto u16 = [&](std::uint16_t v) { for (int i = 0; i < 2; ++i) out.push_back(std::uint8_t((v >> (8 * i)) & 255)); };
    auto tag = [&](const char* s) { for (int i = 0; i < 4; ++i) out.push_back(std::uint8_t(s[i])); };
    tag("RIFF"); u32(36 + dataBytes); tag("WAVE"); tag("fmt "); u32(16); u16(1); u16(1);
    u32(std::uint32_t(audio.sampleRate)); u32(std::uint32_t(audio.sampleRate) * 2); u16(2); u16(16);
    tag("data"); u32(dataBytes);
    for (float s : audio.samples) u16(std::uint16_t(std::int16_t(std::lround(std::clamp(s, -1.0f, 1.0f) * 32767.0f))));
    return out;
}

}  // namespace fa
