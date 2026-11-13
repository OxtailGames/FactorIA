// Macros, variations and the measurements of a rendered sound (fa/audio/sfx.h, docs/SOUND.md "Macros" and "Variations").
// Everything uses sfx_math.h only, so macros and variants render the same bits on every platform like the rest of the synthesizer.
#include "sfx_macros.h"

#include <algorithm>
#include <cmath>
#include <complex>
#include <format>

#include "fa/core/strings.h"
#include "sfx_math.h"

namespace fa {

using sfx_math::exp2;
using sfx_math::log2;

const std::vector<SfxMacroInfo>& sfx_macros() {
    static const std::vector<SfxMacroInfo> macros = {
        {"attack", "How fast the sound starts: -1 snaps (every attack time 16 times shorter), +1 swells in (16 times "
                   "longer, at least 75 ms)."},
        {"brightness", "How much high frequency there is: filter cutoffs and FM depth move, and a gentle exciter (up) "
                       "or low-pass (down) acts on the mix."},
        {"weight", "How heavy it feels: +1 pitches the sound down 5 semitones, darkens its filters and adds low body; "
                   "-1 thins it and lifts it."},
        {"tail", "How long it rings after the held part: +1 makes the tail and the reverb 8 times longer (a few tenths "
                 "of a second even from none), -1 cuts it short."},
        {"pitch",
         "Transposes the whole sound by up to an octave (-1 down, +1 up). Oscillators with a fixed `freq` stay."},
        {"grit",
         "Roughness: +1 adds hard saturation to the mix; -1 takes the distortion and bitcrush of the patch away."},
    };
    return macros;
}

double SfxPatch::macro_value(std::string_view name) const {
    for (const SfxMacroDef& m : macroDefs)
        if (m.name == name) return m.value;
    return 0.0;
}

std::string sfx_variant_path(std::string_view clip, int variant, int count) {
    const std::size_t slash = clip.find_last_of('/');
    const std::size_t dot = clip.find_last_of('.');
    const std::size_t stem =
        dot == std::string_view::npos || (slash != std::string_view::npos && dot < slash) ? clip.size() : dot;
    const int width = std::max(2, int(std::to_string(std::max(count, 1)).size()));
    std::string number = std::to_string(std::max(variant, 0));
    if (int(number.size()) < width) number.insert(0, std::size_t(width) - number.size(), '0');
    return std::string(clip.substr(0, stem)) + "_" + number + std::string(clip.substr(stem));
}

SfxVariantParams sfx_variant_params(const SfxVariations& v, int index) {
    sfx_math::SfxRng rng{v.seed * 0x9E3779B97F4A7C15ull ^ (std::uint64_t(index) + 1) * 0xD1B54A32D192ED03ull};
    rng.next();
    SfxVariantParams out;
    out.pitchCents = v.pitchCents * rng.signed_unit();
    out.lengthScale = 1.0 + v.lengthFraction * rng.signed_unit();
    out.gainDb = v.gainDb * rng.signed_unit();
    out.filterOctaves = v.filterOctaves * rng.signed_unit();
    out.seedOffset = v.noise ? (v.seed + 1) * 1000003ull + std::uint64_t(index) + 1 : 0;
    return out;
}

Result<Json> sfx_apply_macro_binds(const Json& patchJson, const SfxPatch& parsed,
                                   const std::map<std::string, double>& overrides) {
    Json out = patchJson;
    for (const SfxMacroDef& def : parsed.macroDefs) {
        if (def.binds.empty()) continue;
        double value = def.value;
        if (auto it = overrides.find(def.name); it != overrides.end()) value = it->second;
        value = std::clamp(value, -1.0, 1.0);
        const double t = (value + 1.0) * 0.5;
        for (const SfxMacroBind& b : def.binds) {
            Json::json_pointer ptr;
            try {
                ptr = Json::json_pointer(b.pointer);
            } catch (const std::exception&) {
                return make_error("macro " + def.name + ": '" + b.pointer + "' is not a JSON pointer",
                                  "Write it like \"/layers/0/filter/cutoff\".");
            }
            if (!out.contains(ptr) || !out[ptr].is_number())
                return make_error("macro " + def.name + ": '" + b.pointer + "' is not a number of this patch",
                                  "A bind sets an existing number: write the key in the patch first (for example the "
                                  "layer's filter cutoff), then bind it.");
            const double v =
                b.exponential ? b.atMin * sfx_math::pow(b.atMax / b.atMin, t) : b.atMin + (b.atMax - b.atMin) * t;
            out[ptr] = v;
        }
    }
    return out;
}

namespace sfx_detail {

MacroValues effective_macros(const SfxPatch& patch, const std::map<std::string, double>& overrides) {
    MacroValues m;
    static const char* names[6] = {"attack", "brightness", "weight", "tail", "pitch", "grit"};
    double* slots[6] = {&m.attack, &m.brightness, &m.weight, &m.tail, &m.pitch, &m.grit};
    for (int i = 0; i < 6; ++i) {
        double strength = 1.0;
        double value = 0.0;
        for (const SfxMacroDef& d : patch.macroDefs)
            if (d.builtin && d.name == names[i]) {
                value = d.value;
                strength = d.strength;
            }
        if (auto it = overrides.find(names[i]); it != overrides.end()) value = it->second;
        *slots[i] = std::clamp(value, -1.0, 1.0);
        m.strength[i] = strength;
    }
    return m;
}

namespace {

void scale_filter(SfxFilter& f, double factor) {
    if (!f.enabled) return;
    f.cutoff = std::clamp(f.cutoff * factor, 20.0, 20000.0);
    if (f.cutoffTo > 0.0) f.cutoffTo = std::clamp(f.cutoffTo * factor, 20.0, 20000.0);
}

void each_effect(SfxPatch& patch, const auto& fn) {
    for (SfxLayer& l : patch.layers)
        for (SfxEffect& e : l.effects) fn(e);
    for (SfxEffect& e : patch.effects) fn(e);
}

void scale_cutoffs(SfxPatch& patch, double factor) {
    for (SfxLayer& l : patch.layers) scale_filter(l.filter, factor);
    each_effect(patch, [&](SfxEffect& e) {
        if (e.type == SfxEffectType::Filter) scale_filter(e.filter, factor);
    });
}

}  // namespace

void apply_macros(SfxPatch& patch, const MacroValues& m, double& transpose, Tilt& tilt) {
    if (m.attack != 0.0) {
        const double k = exp2(4.0 * m.attack * m.strength[0]);
        for (SfxLayer& l : patch.layers) l.amp.attack = std::clamp((l.amp.attack + 0.005) * k - 0.005, 0.0, 30.0);
    }
    if (m.brightness != 0.0) {
        const double s = m.brightness * m.strength[1];
        scale_cutoffs(patch, exp2(1.5 * s));
        for (SfxLayer& l : patch.layers)
            for (SfxOscillator& o : l.oscillators)
                if (o.fm.enabled) o.fm.index = std::clamp(o.fm.index * exp2(s), 0.0, 100.0);
        tilt.brightness = std::clamp(s, -1.0, 1.0);
    }
    if (m.weight != 0.0) {
        const double s = m.weight * m.strength[2];
        transpose *= exp2(-5.0 * s / 12.0);
        scale_cutoffs(patch, exp2(-0.7 * s));
        tilt.weight = std::clamp(s, -1.0, 1.0);
    }
    if (m.tail != 0.0) {
        const double s = m.tail * m.strength[3];
        const double k = exp2(3.0 * s);
        patch.tail =
            std::min(std::max(0.0, (patch.tail + 0.05) * k - 0.05), std::max(0.0, kSfxMaxSeconds - patch.length));
        const double release = exp2(1.5 * s);
        for (SfxLayer& l : patch.layers) l.amp.release = std::min(30.0, l.amp.release * release);
        each_effect(patch, [&](SfxEffect& e) {
            if (e.type == SfxEffectType::Reverb) e.decay = std::clamp(e.decay * k, 0.05, 30.0);
        });
    }
    if (m.pitch != 0.0) transpose *= exp2(m.pitch * m.strength[4]);
    if (m.grit != 0.0) {
        const double s = std::clamp(m.grit * m.strength[5], -1.0, 1.0);
        if (s > 0.0) {
            SfxEffect e;
            e.type = SfxEffectType::Distortion;
            e.shape = SfxDistortion::Soft;
            e.drive = 1.0 + 9.0 * s;
            e.mix = s;
            patch.effects.push_back(e);
        } else {
            each_effect(patch, [&](SfxEffect& e) {
                if (e.type == SfxEffectType::Distortion || e.type == SfxEffectType::Bitcrush) e.mix *= 1.0 + s;
            });
        }
    }
}

void apply_variant(SfxPatch& patch, const SfxVariantParams& v) {
    for (SfxLayer& l : patch.layers) l.length *= v.lengthScale;
    if (v.filterOctaves != 0.0) scale_cutoffs(patch, exp2(v.filterOctaves));
}

namespace {

// The state-variable filter of the renderer, reduced to what the tilt needs (sfx_render.cpp has the same one).
struct Biquad2 {
    double a1 = 0, a2 = 0, a3 = 0, k = 1.4142135623730951, ic1 = 0, ic2 = 0;
    void set(double cutoff, double rate) {
        const double g = sfx_math::tan_pi(std::clamp(cutoff, 20.0, 0.45 * rate) / rate);
        a1 = 1.0 / (1.0 + g * (g + k));
        a2 = g * a1;
        a3 = g * a2;
    }
    // Returns {low-pass, high-pass}.
    std::pair<double, double> process(double x) {
        const double v3 = x - ic2;
        const double v1 = a1 * ic1 + a2 * v3;
        const double v2 = ic2 + a2 * ic1 + a3 * v3;
        ic1 = 2.0 * v1 - ic1;
        ic2 = 2.0 * v2 - ic2;
        return {v2, x - k * v1 - v2};
    }
};

}  // namespace

void apply_tilt(std::vector<double>& mix, const Tilt& tilt, int rate) {
    double peak = 0.0;
    for (double s : mix) peak = std::max(peak, std::fabs(s));
    if (!(peak > 1e-12)) return;
    const double fs = double(rate);
    std::vector<double> out = mix;
    if (tilt.brightness > 0.0) {
        // An exciter: saturate (new harmonics even for a pure tone), keep what is above 1.5 kHz, add it.
        Biquad2 hp;
        hp.set(1500.0, fs);
        const double amount = 1.5 * tilt.brightness * peak;
        for (std::size_t i = 0; i < mix.size(); ++i)
            out[i] += amount * hp.process(sfx_math::tanh(4.0 * mix[i] / peak)).second;
    } else if (tilt.brightness < 0.0) {
        Biquad2 lp;
        lp.set(18000.0 * exp2(4.5 * tilt.brightness), fs);
        for (std::size_t i = 0; i < mix.size(); ++i) out[i] = lp.process(out[i]).first;
    }
    if (tilt.weight != 0.0) {
        Biquad2 lp;
        lp.set(tilt.weight > 0.0 ? 160.0 : 300.0, fs);
        const double amount = tilt.weight > 0.0 ? 1.2 * tilt.weight : 0.7 * tilt.weight;
        for (std::size_t i = 0; i < mix.size(); ++i) out[i] += amount * lp.process(mix[i]).first;
    }
    mix = std::move(out);
}

}  // namespace sfx_detail

// ---- measurements -----------------------------------------------------------------------------------------------------------

namespace {

void fft(std::vector<std::complex<double>>& a) {
    const std::size_t n = a.size();
    for (std::size_t i = 1, j = 0; i < n; ++i) {
        std::size_t bit = n >> 1;
        for (; j & bit; bit >>= 1) j ^= bit;
        j ^= bit;
        if (i < j) std::swap(a[i], a[j]);
    }
    for (std::size_t len = 2; len <= n; len <<= 1) {
        for (std::size_t i = 0; i < n; i += len) {
            for (std::size_t k = 0; k < len / 2; ++k) {
                const double turns = -double(k) / double(len);
                const std::complex<double> w(sfx_math::cos_turns(turns), sfx_math::sin_turns(turns));
                const std::complex<double> u = a[i + k], v = a[i + k + len / 2] * w;
                a[i + k] = u + v;
                a[i + k + len / 2] = u - v;
            }
        }
    }
}

}  // namespace

double sfx_centroid_hz(const SfxAudio& audio) {
    constexpr std::size_t n = 2048, hop = 1024;
    const std::size_t total = audio.samples.size();
    if (total == 0 || audio.sampleRate <= 0) return 0.0;
    std::vector<double> window(n);
    for (std::size_t i = 0; i < n; ++i) window[i] = 0.5 - 0.5 * sfx_math::cos_turns(double(i) / double(n));
    std::vector<double> power(n / 2, 0.0);
    std::vector<std::complex<double>> buf(n);
    for (std::size_t start = 0; start == 0 || start + n / 2 < total; start += hop) {
        for (std::size_t i = 0; i < n; ++i)
            buf[i] = start + i < total ? double(audio.samples[start + i]) * window[i] : 0.0;
        fft(buf);
        for (std::size_t b = 1; b < n / 2; ++b) power[b] += std::norm(buf[b]);
    }
    double sum = 0.0, weighted = 0.0;
    for (std::size_t b = 1; b < n / 2; ++b) {
        sum += power[b];
        weighted += power[b] * double(b);
    }
    return sum > 0.0 ? weighted / sum * double(audio.sampleRate) / double(n) : 0.0;
}

double sfx_rise_seconds(const SfxAudio& audio) {
    const std::size_t win = std::max<std::size_t>(1, std::size_t(audio.sampleRate / 1000));  // 1 ms
    std::vector<double> env;
    double peak = 0.0;
    for (std::size_t i = 0; i < audio.samples.size(); i += win) {
        double m = 0.0;
        for (std::size_t k = i; k < std::min(audio.samples.size(), i + win); ++k)
            m = std::max(m, double(std::fabs(audio.samples[k])));
        env.push_back(m);
        peak = std::max(peak, m);
    }
    if (peak <= 0.0) return 0.0;
    for (std::size_t i = 0; i < env.size(); ++i)
        if (env[i] >= 0.9 * peak) return double(i * win) / double(audio.sampleRate);
    return 0.0;
}

}  // namespace fa
