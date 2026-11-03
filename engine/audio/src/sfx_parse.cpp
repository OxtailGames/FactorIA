// Reads `*.sfx.json` into an SfxPatch (fa/audio/sfx.h). Every problem is reported with its JSON pointer, what is wrong and how to
// fix it; names get "did you mean". The rules (ranges, names) are the ones docs/SOUND.md and schemas/sfx.schema.json list.
#include <algorithm>
#include <cctype>
#include <format>
#include <initializer_list>

#include "fa/audio/sfx.h"
#include "fa/core/fs.h"
#include "fa/core/strings.h"
#include "sfx_math.h"

namespace fa {

namespace {

constexpr std::size_t kMaxLayers = 16, kMaxOscillators = 8, kMaxEffects = 8, kMaxTable = 4096, kMaxArpSteps = 32;

std::string join_names(const std::vector<std::string>& names) {
    std::string out;
    for (const std::string& n : names) out += (out.empty() ? "\"" : ", \"") + n + "\"";
    return out;
}

struct Parser {
    std::vector<SfxIssue> issues;

    void err(const std::string& pointer, std::string message, std::string hint) { issues.push_back({pointer, std::move(message), std::move(hint)}); }

    // Reports the keys of `obj` that are not in `allowed`.
    void unknown_keys(const Json& obj, const std::string& pointer, std::initializer_list<const char*> allowed, const std::string& what) {
        std::vector<std::string> names;
        for (const char* a : allowed) names.emplace_back(a);
        for (auto it = obj.begin(); it != obj.end(); ++it) {
            const std::string& key = it.key();
            if (std::find(names.begin(), names.end(), key) != names.end()) continue;
            err(pointer + "/" + key, "unknown key `" + key + "` in " + what, did_you_mean(key, names));
        }
    }

    // obj[key] as a number in [lo, hi]; false when absent (out unchanged) or invalid (reported).
    bool number(const Json& obj, const std::string& pointer, const char* key, double& out, double lo, double hi, const std::string& unit,
                const std::string& hint) {
        auto it = obj.find(key);
        if (it == obj.end()) return false;
        const std::string where = pointer + "/" + key;
        if (!it->is_number()) {
            err(where, std::string(key) + " must be a number" + unit + ", got " + describe_json_value(*it), hint);
            return false;
        }
        const double v = it->get<double>();
        if (!(v >= lo && v <= hi)) {
            err(where, std::format("{} is {}, outside {} to {}{}", key, v, lo, hi, unit), hint);
            return false;
        }
        out = v;
        return true;
    }

    bool boolean(const Json& obj, const std::string& pointer, const char* key, bool& out) {
        auto it = obj.find(key);
        if (it == obj.end()) return false;
        if (!it->is_boolean()) {
            err(pointer + "/" + key, std::string(key) + " must be true or false, got " + describe_json_value(*it), "Write true or false.");
            return false;
        }
        out = it->get<bool>();
        return true;
    }

    // obj[key] as one of `names`; index into names, or -1.
    int choice(const Json& obj, const std::string& pointer, const char* key, const std::vector<std::string>& names, const std::string& hintExtra = {}) {
        auto it = obj.find(key);
        if (it == obj.end()) return -1;
        const std::string where = pointer + "/" + key;
        if (!it->is_string()) {
            err(where, std::string(key) + " must be one of " + join_names(names) + ", got " + describe_json_value(*it), hintExtra);
            return -1;
        }
        const std::string v = it->get<std::string>();
        for (std::size_t i = 0; i < names.size(); ++i)
            if (names[i] == v) return int(i);
        err(where, std::string("unknown ") + key + " \"" + v + "\"", did_you_mean(v, names) + hintExtra);
        return -1;
    }

    bool object(const Json& value, const std::string& pointer, const std::string& what, const std::string& example) {
        if (value.is_object()) return true;
        err(pointer, what + " must be an object, got " + describe_json_value(value), "Write " + example + ".");
        return false;
    }

    // ---- pieces -------------------------------------------------------------------------------------------------

    void envelope(const Json& j, const std::string& pointer, SfxEnvelope& env, bool withAmount, double* amount, const char* amountUnit) {
        if (!object(j, pointer, "an envelope", "{\"attack\": 0.01, \"decay\": 0.2, \"sustain\": 0.5, \"release\": 0.1}")) return;
        if (withAmount) unknown_keys(j, pointer, {"amount", "attack", "decay", "sustain", "release", "curve"}, "an envelope");
        else unknown_keys(j, pointer, {"attack", "decay", "sustain", "release", "curve"}, "an envelope");
        const std::string time = " (seconds)";
        number(j, pointer, "attack", env.attack, 0.0, 30.0, time, "Seconds the level takes to rise from 0 to 1, e.g. 0.005.");
        number(j, pointer, "decay", env.decay, 0.0, 30.0, time, "Seconds the level takes to fall from 1 to `sustain`, e.g. 0.2.");
        number(j, pointer, "sustain", env.sustain, 0.0, 1.0, "", "The level held after the decay, 0 (silence) to 1 (full). Use 0 for a sound that dies away on its own.");
        number(j, pointer, "release", env.release, 0.0, 30.0, time, "Seconds the level takes to fall to 0 after the note is released at `length`.");
        number(j, pointer, "curve", env.curve, 0.2, 8.0, "", "1 is a straight line; 2 to 4 gives a punchy decay that falls fast first; below 1 the opposite.");
        if (withAmount && amount) {
            if (!j.contains("amount")) err(pointer + "/amount", "this envelope needs `amount`", std::string("Write \"amount\": 12, how far the envelope moves the value at its peak (") + amountUnit + ").");
            else number(j, pointer, "amount", *amount, -96.0, 96.0, std::string(" (") + amountUnit + ")", std::string("How far the envelope moves the value at its peak, in ") + amountUnit + ".");
        }
    }

    // A pitch/filter envelope: the keys of an envelope plus `amount`.
    void modulation(const Json& j, const std::string& pointer, SfxModulation& mod, const char* unit) {
        mod.enabled = true;
        mod.env = SfxEnvelope{0.0, 0.0, 1.0, 0.0, 1.0};
        envelope(j, pointer, mod.env, true, &mod.amount, unit);
    }

    SfxWave wave_name(const Json& j, const std::string& pointer, const char* key, bool allowNoiseAndTable, SfxWave fallback) {
        static const std::vector<std::string> all = {"sine", "square", "saw", "triangle", "noise", "table"};
        static const std::vector<std::string> shapes = {"sine", "square", "saw", "triangle"};
        const int i = choice(j, pointer, key, allowNoiseAndTable ? all : shapes, allowNoiseAndTable ? "" : " A modulator is a plain wave: sine, square, saw or triangle.");
        return i < 0 ? fallback : SfxWave(i);
    }

    void oscillator(const Json& j, const std::string& pointer, SfxOscillator& osc) {
        if (!object(j, pointer, "an oscillator", "{\"wave\": \"saw\"}")) return;
        unknown_keys(j, pointer, {"wave", "duty", "color", "table", "ratio", "detune", "freq", "gain", "phase", "fm", "ring"}, "an oscillator");
        if (!j.contains("wave")) err(pointer + "/wave", "an oscillator needs `wave`", "Write \"wave\": \"sine\" (sine, square, saw, triangle, noise or table).");
        osc.wave = wave_name(j, pointer, "wave", true, SfxWave::Sine);
        if (j.contains("duty")) {
            if (osc.wave != SfxWave::Square) err(pointer + "/duty", "`duty` only applies to wave \"square\"", "Remove `duty`, or use \"wave\": \"square\".");
            else number(j, pointer, "duty", osc.duty, 0.02, 0.98, "", "The share of each cycle that is high: 0.5 is a plain square, 0.25 or 0.125 is thin and nasal (chiptune).");
        }
        if (j.contains("color")) {
            static const std::vector<std::string> colors = {"white", "pink", "brown"};
            if (osc.wave != SfxWave::Noise) err(pointer + "/color", "`color` only applies to wave \"noise\"", "Remove `color`, or use \"wave\": \"noise\".");
            else if (int c = choice(j, pointer, "color", colors, " white is bright hiss, pink is rain-like, brown is a deep rumble."); c >= 0) osc.noise = SfxNoise(c);
        }
        if (osc.wave == SfxWave::Table) {
            auto it = j.find("table");
            if (it == j.end()) err(pointer + "/table", "wave \"table\" needs `table`", "Write \"table\": [0, 0.7, 1, 0.7, 0, -0.7, -1, -0.7], one cycle of the wave drawn as 2 to 4096 numbers from -1 to 1.");
            else if (!it->is_array() || it->size() < 2 || it->size() > kMaxTable)
                err(pointer + "/table", "table must be an array of 2 to 4096 numbers, got " + describe_json_value(*it), "One cycle of the wave, drawn left to right: [0, 1, 0, -1] is a rough sine.");
            else {
                for (std::size_t i = 0; i < it->size(); ++i) {
                    const Json& v = (*it)[i];
                    if (!v.is_number() || v.get<double>() < -1.0 || v.get<double>() > 1.0) {
                        err(pointer + "/table/" + std::to_string(i), "table values are numbers from -1 to 1, got " + describe_json_value(v), "Scale the drawing so its peaks are 1 and -1.");
                        break;
                    }
                    osc.table.push_back(v.get<double>());
                }
            }
        } else if (j.contains("table")) {
            err(pointer + "/table", "`table` is only read when wave is \"table\"", "Set \"wave\": \"table\", or remove `table`.");
        }
        number(j, pointer, "ratio", osc.ratio, 0.01, 64.0, "", "A multiple of the layer's frequency: 2 is an octave up, 0.5 an octave down, 1.5 a fifth up.");
        number(j, pointer, "detune", osc.detune, -2400.0, 2400.0, " (cents)", "100 cents are one semitone; 5 to 15 cents between two oscillators makes a fat, chorused tone.");
        number(j, pointer, "freq", osc.freq, 1.0, 20000.0, " (Hz)", "A fixed frequency in Hz that ignores the layer's pitch. Leave it out to follow `pitch`.");
        number(j, pointer, "gain", osc.gain, 0.0, 8.0, "", "Linear level of this oscillator inside the layer, 1 is unchanged.");
        number(j, pointer, "phase", osc.phase, 0.0, 1.0, "", "Where in its cycle the oscillator starts, 0 to 1.");
        if (osc.wave == SfxWave::Noise && (j.contains("ratio") || j.contains("detune") || j.contains("freq") || j.contains("phase") || j.contains("fm")))
            err(pointer, "noise has no pitch: `ratio`, `detune`, `freq`, `phase` and `fm` do not apply", "Shape noise with the layer's `filter`, or use `ring` to make it metallic.");
        if (auto it = j.find("fm"); it != j.end()) fm(*it, pointer + "/fm", osc.fm);
        if (auto it = j.find("ring"); it != j.end()) ring(*it, pointer + "/ring", osc.ring);
    }

    void fm(const Json& j, const std::string& pointer, SfxFm& out) {
        if (!object(j, pointer, "fm", "{\"ratio\": 2, \"index\": 3}")) return;
        unknown_keys(j, pointer, {"ratio", "hz", "index", "wave", "indexEnv"}, "fm");
        out.enabled = true;
        if (j.contains("ratio") && j.contains("hz")) err(pointer, "give `ratio` or `hz`, not both", "`ratio` follows the oscillator's pitch (2 = an octave above it); `hz` is a fixed frequency.");
        number(j, pointer, "ratio", out.ratio, 0.01, 64.0, "", "The modulator's frequency as a multiple of the oscillator's; whole numbers sound harmonic (bells use 1.4 or 3.5).");
        number(j, pointer, "hz", out.hz, 0.1, 20000.0, " (Hz)", "A fixed modulator frequency in Hz.");
        number(j, pointer, "index", out.index, 0.0, 40.0, " (radians)", "How far the modulator bends the phase: 0.5 is a hint of brightness, 3 to 8 is a metallic clang.");
        out.wave = wave_name(j, pointer, "wave", false, SfxWave::Sine);
        if (auto it = j.find("indexEnv"); it != j.end()) {
            out.hasIndexEnv = true;
            out.indexEnv = SfxEnvelope{0.0, 0.0, 1.0, 0.0, 1.0};
            envelope(*it, pointer + "/indexEnv", out.indexEnv, false, nullptr, "");
        }
    }

    void ring(const Json& j, const std::string& pointer, SfxRing& out) {
        if (!object(j, pointer, "ring", "{\"ratio\": 1.5, \"mix\": 1}")) return;
        unknown_keys(j, pointer, {"ratio", "hz", "mix", "wave"}, "ring");
        out.enabled = true;
        if (j.contains("ratio") && j.contains("hz")) err(pointer, "give `ratio` or `hz`, not both", "`ratio` follows the oscillator's pitch; `hz` is a fixed frequency.");
        number(j, pointer, "ratio", out.ratio, 0.01, 64.0, "", "The modulator's frequency as a multiple of the oscillator's; odd ratios sound metallic and inharmonic.");
        number(j, pointer, "hz", out.hz, 0.1, 20000.0, " (Hz)", "A fixed modulator frequency in Hz.");
        number(j, pointer, "mix", out.mix, 0.0, 1.0, "", "0 leaves the oscillator as it is, 1 is full ring modulation.");
        out.wave = wave_name(j, pointer, "wave", false, SfxWave::Sine);
    }

    void filter(const Json& j, const std::string& pointer, SfxFilter& f, bool inEffect) {
        static const std::vector<std::string> modes = {"lowpass", "highpass", "bandpass"};
        if (!inEffect && !object(j, pointer, "filter", "{\"mode\": \"lowpass\", \"cutoff\": 2000}")) return;
        f.enabled = true;
        if (!inEffect) unknown_keys(j, pointer, {"mode", "cutoff", "resonance", "env"}, "a filter");
        if (int m = choice(j, pointer, "mode", modes, " lowpass removes highs (muffles), highpass removes lows (thins), bandpass keeps a band (nasal, radio)."); m >= 0) f.mode = SfxFilterMode(m);
        if (!j.contains("cutoff")) err(pointer + "/cutoff", "a filter needs `cutoff`", "Write \"cutoff\": 2000, the frequency in Hz where the filter starts to act.");
        number(j, pointer, "cutoff", f.cutoff, 20.0, 20000.0, " (Hz)", "The frequency where the filter acts, e.g. 800 for a dull sound or 6000 for a bright one.");
        number(j, pointer, "resonance", f.resonance, 0.5, 30.0, " (Q)", "0.707 is flat; 2 to 8 adds a whistle at the cutoff; above 15 it nearly rings by itself.");
        if (inEffect) {
            number(j, pointer, "to", f.cutoffTo, 20.0, 20000.0, " (Hz)", "The cutoff the filter slides to by the end of the sound.");
        } else if (auto it = j.find("env"); it != j.end()) {
            modulation(*it, pointer + "/env", f.env, "octaves");
        }
    }

    void effect(const Json& j, const std::string& pointer, SfxEffect& e) {
        static const std::vector<std::string> types = {"filter", "distortion", "bitcrush", "delay", "reverb"};
        if (!object(j, pointer, "an effect", "{\"type\": \"reverb\", \"decay\": 1.2, \"mix\": 0.25}")) return;
        const int t = choice(j, pointer, "type", types);
        if (!j.contains("type")) err(pointer + "/type", "an effect needs `type`", "One of " + join_names(types) + ".");
        if (t < 0) return;
        e.type = SfxEffectType(t);
        boolean(j, pointer, "enabled", e.enabled);
        auto addedHint = [](const char* what) { return std::string("How loud ") + what + " when added to the dry sound, which always stays: 0 is none, 1 is as loud as the dry sound."; };
        const std::string mixHint = "How much of the effect is heard: 0 is the dry sound, 1 only the effect.";
        switch (e.type) {
            case SfxEffectType::Filter:
                unknown_keys(j, pointer, {"type", "enabled", "mode", "cutoff", "resonance", "to"}, "a filter effect");
                filter(j, pointer, e.filter, true);
                break;
            case SfxEffectType::Distortion: {
                static const std::vector<std::string> shapes = {"soft", "hard", "fold"};
                unknown_keys(j, pointer, {"type", "enabled", "mode", "drive", "level", "mix"}, "a distortion effect");
                if (int s = choice(j, pointer, "mode", shapes, " soft rounds the peaks (tube-like), hard clips them flat, fold bends them back (metallic)."); s >= 0) e.shape = SfxDistortion(s);
                number(j, pointer, "drive", e.drive, 1.0, 100.0, "", "Gain into the distortion: 2 is warm, 10 is crunchy, 50 is a wall of fuzz.");
                number(j, pointer, "level", e.level, 0.0, 4.0, "", "Gain after the distortion, to bring the level back down.");
                e.mix = 1.0;
                number(j, pointer, "mix", e.mix, 0.0, 1.0, "", mixHint);
                break;
            }
            case SfxEffectType::Bitcrush:
                unknown_keys(j, pointer, {"type", "enabled", "bits", "rate", "mix"}, "a bitcrush effect");
                number(j, pointer, "bits", e.bits, 1.0, 16.0, " (bits)", "Resolution of each sample: 8 is gritty, 4 is harsh, 12 is mild.");
                number(j, pointer, "rate", e.rate, 100.0, 96000.0, " (Hz)", "The rate samples are held at: 8000 sounds like an old console. Leave out to keep the patch's sample rate.");
                e.mix = 1.0;
                number(j, pointer, "mix", e.mix, 0.0, 1.0, "", mixHint);
                break;
            case SfxEffectType::Delay:
                unknown_keys(j, pointer, {"type", "enabled", "time", "feedback", "tone", "mix"}, "a delay effect");
                number(j, pointer, "time", e.time, 0.001, 2.0, " (seconds)", "Time between repeats: 0.08 slaps back, 0.3 is an echo.");
                number(j, pointer, "feedback", e.feedback, 0.0, 0.95, "", "How much of each repeat feeds the next: 0.3 gives a few echoes, 0.8 a long trail.");
                number(j, pointer, "tone", e.tone, 100.0, 20000.0, " (Hz)", "A low-pass in the feedback so each repeat is darker; leave out for none.");
                e.mix = 0.35;
                number(j, pointer, "mix", e.mix, 0.0, 1.0, "", addedHint("the repeats are"));
                break;
            case SfxEffectType::Reverb:
                unknown_keys(j, pointer, {"type", "enabled", "decay", "damping", "size", "preDelay", "mix"}, "a reverb effect");
                number(j, pointer, "decay", e.decay, 0.05, 10.0, " (seconds)", "Time the reverb takes to die away (RT60): 0.4 a small room, 1.5 a hall, 4 a cathedral. Give the patch a `tail` as long.");
                number(j, pointer, "damping", e.damping, 0.0, 1.0, "", "0 is bright, 1 is dark and soft.");
                number(j, pointer, "size", e.size, 0.25, 2.0, "", "Scales the room: 0.5 is tight, 1 is the default, 2 is spacious and a little metallic.");
                number(j, pointer, "preDelay", e.preDelay, 0.0, 0.5, " (seconds)", "Gap before the reverb starts; 0.02 to 0.05 keeps the dry sound clear.");
                e.mix = 0.25;
                number(j, pointer, "mix", e.mix, 0.0, 1.0, "", addedHint("the reverb is"));
                break;
        }
    }

    void effects(const Json& j, const std::string& pointer, std::vector<SfxEffect>& out) {
        if (!j.is_array() || j.size() > kMaxEffects) {
            err(pointer, "effects must be an array of at most 8 effects, got " + describe_json_value(j), "Write [{\"type\": \"reverb\", \"mix\": 0.2}]. The order is the order they are heard in.");
            return;
        }
        for (std::size_t i = 0; i < j.size(); ++i) {
            SfxEffect e;
            effect(j[i], pointer + "/" + std::to_string(i), e);
            out.push_back(std::move(e));
        }
    }

    void pitch(const Json& j, const std::string& pointer, SfxPitch& p) {
        if (!object(j, pointer, "pitch", "{\"freq\": 440}")) return;
        unknown_keys(j, pointer, {"freq", "note", "sweep", "env", "vibrato", "arpeggio"}, "pitch");
        if (j.contains("freq") && j.contains("note")) err(pointer, "give `freq` or `note`, not both", "\"freq\": 440 and \"note\": \"A4\" are the same pitch.");
        number(j, pointer, "freq", p.freq, 1.0, 20000.0, " (Hz)", "The base frequency in Hz, e.g. 440 (A4). Or write a `note` such as \"A4\".");
        if (auto it = j.find("note"); it != j.end()) {
            std::optional<double> hz = it->is_string() ? sfx_note_hz(it->get<std::string>()) : std::nullopt;
            if (!hz) err(pointer + "/note", "note must be a name like \"A4\", \"C#3\" or \"Bb2\", got " + describe_json_value(*it), "Letter A to G, optional # or b, octave number; C4 is middle C and A4 is 440 Hz.");
            else p.freq = *hz;
        }
        if (auto it = j.find("sweep"); it != j.end() && object(*it, pointer + "/sweep", "sweep", "{\"to\": 220, \"time\": 0.2}")) {
            const std::string sp = pointer + "/sweep";
            unknown_keys(*it, sp, {"to", "semitones", "time", "curve"}, "sweep");
            p.sweep = true;
            if (it->contains("to") == it->contains("semitones")) err(sp, "give `to` (a frequency in Hz) or `semitones` (a step from the base pitch), one of them", "{\"to\": 220} slides to 220 Hz; {\"semitones\": -12} slides an octave down.");
            double to = 0.0;
            if (number(*it, sp, "to", to, 1.0, 20000.0, " (Hz)", "The frequency the pitch slides to, in Hz.")) p.sweepSemitones = 12.0 * sfx_math::log2(to / p.freq);
            number(*it, sp, "semitones", p.sweepSemitones, -96.0, 96.0, " (semitones)", "How far the pitch slides: 12 is an octave up, -12 an octave down.");
            number(*it, sp, "time", p.sweepTime, 0.001, 30.0, " (seconds)", "How long the slide takes. Leave out to slide over the whole layer.");
            number(*it, sp, "curve", p.sweepCurve, 0.1, 8.0, "", "1 slides at a constant rate (an even whoop); 3 jumps fast at first then settles (a zap); below 1 starts slowly.");
        }
        if (auto it = j.find("env"); it != j.end()) modulation(*it, pointer + "/env", p.env, "semitones");
        if (auto it = j.find("vibrato"); it != j.end() && object(*it, pointer + "/vibrato", "vibrato", "{\"rate\": 6, \"depth\": 20}")) {
            const std::string vp = pointer + "/vibrato";
            unknown_keys(*it, vp, {"rate", "depth", "delay"}, "vibrato");
            if (!it->contains("rate")) err(vp + "/rate", "vibrato needs `rate`", "Write \"rate\": 6, wobbles per second.");
            if (!it->contains("depth")) err(vp + "/depth", "vibrato needs `depth`", "Write \"depth\": 20, the size of the wobble in cents (100 = a semitone).");
            number(*it, vp, "rate", p.vibratoRate, 0.1, 40.0, " (Hz)", "Wobbles per second: 5 to 7 is a singer's vibrato.");
            number(*it, vp, "depth", p.vibratoDepth, 0.0, 2400.0, " (cents)", "Peak size of the wobble: 10 to 30 is natural, 100 is a siren.");
            number(*it, vp, "delay", p.vibratoDelay, 0.0, 30.0, " (seconds)", "Seconds the vibrato fades in over.");
        }
        if (auto it = j.find("arpeggio"); it != j.end() && object(*it, pointer + "/arpeggio", "arpeggio", "{\"steps\": [0, 4, 7], \"rate\": 12}")) {
            const std::string ap = pointer + "/arpeggio";
            unknown_keys(*it, ap, {"steps", "rate", "mode"}, "arpeggio");
            auto sit = it->find("steps");
            if (sit == it->end() || !sit->is_array() || sit->empty() || sit->size() > kMaxArpSteps)
                err(ap + "/steps", "steps must be an array of 1 to 32 semitone offsets, got " + (sit == it->end() ? std::string("nothing") : describe_json_value(*sit)),
                    "Write \"steps\": [0, 4, 7] for a major chord from the base pitch, [0, 7, 12] for open fifths.");
            else
                for (std::size_t i = 0; i < sit->size(); ++i) {
                    if (!(*sit)[i].is_number() || std::abs((*sit)[i].get<double>()) > 48.0) {
                        err(ap + "/steps/" + std::to_string(i), "a step is a number of semitones from -48 to 48, got " + describe_json_value((*sit)[i]), "0 is the base pitch, 12 an octave up.");
                        break;
                    }
                    p.arpSteps.push_back((*sit)[i].get<double>());
                }
            number(*it, ap, "rate", p.arpRate, 0.5, 200.0, " (steps per second)", "How many steps play per second: 8 to 16 is a classic chiptune arpeggio.");
            static const std::vector<std::string> modes = {"loop", "once"};
            if (int m = choice(*it, ap, "mode", modes, " loop repeats the steps; once plays them in turn and stays on the last."); m >= 0) p.arpLoop = (m == 0);
        }
    }

    void layer(const Json& j, const std::string& pointer, SfxLayer& l) {
        if (!object(j, pointer, "a layer", "{\"oscillators\": [{\"wave\": \"sine\"}]}")) return;
        unknown_keys(j, pointer, {"name", "start", "length", "gain", "oscillators", "pitch", "amp", "tremolo", "filter", "effects"}, "a layer");
        if (auto it = j.find("name"); it != j.end() && it->is_string()) l.name = it->get<std::string>();
        number(j, pointer, "start", l.start, 0.0, 30.0, " (seconds)", "When the layer starts, in seconds from the start of the sound.");
        number(j, pointer, "length", l.length, 0.001, 30.0, " (seconds)", "How long the layer is held before its release. Leave out to hold it until the patch's `length`.");
        number(j, pointer, "gain", l.gain, 0.0, 8.0, "", "Linear level of the layer in the mix, 1 is unchanged, 0.5 is 6 dB quieter.");
        auto oit = j.find("oscillators");
        if (oit == j.end() || !oit->is_array() || oit->empty() || oit->size() > kMaxOscillators)
            err(pointer + "/oscillators", "a layer needs `oscillators`, an array of 1 to 8, got " + (oit == j.end() ? std::string("nothing") : describe_json_value(*oit)),
                "Write \"oscillators\": [{\"wave\": \"saw\"}]; several oscillators are added together.");
        else
            for (std::size_t i = 0; i < oit->size(); ++i) {
                SfxOscillator osc;
                oscillator((*oit)[i], pointer + "/oscillators/" + std::to_string(i), osc);
                l.oscillators.push_back(std::move(osc));
            }
        if (auto it = j.find("pitch"); it != j.end()) pitch(*it, pointer + "/pitch", l.pitch);
        if (auto it = j.find("amp"); it != j.end()) envelope(*it, pointer + "/amp", l.amp, false, nullptr, "");
        if (auto it = j.find("tremolo"); it != j.end() && object(*it, pointer + "/tremolo", "tremolo", "{\"rate\": 8, \"depth\": 0.5}")) {
            const std::string tp = pointer + "/tremolo";
            unknown_keys(*it, tp, {"rate", "depth"}, "tremolo");
            if (!it->contains("rate")) err(tp + "/rate", "tremolo needs `rate`", "Write \"rate\": 8, pulses per second.");
            if (!it->contains("depth")) err(tp + "/depth", "tremolo needs `depth`", "Write \"depth\": 0.5, 0 (none) to 1 (the volume drops to silence).");
            number(*it, tp, "rate", l.tremoloRate, 0.1, 100.0, " (Hz)", "Pulses per second: 5 is a gentle wobble, 25 a growl's rattle.");
            number(*it, tp, "depth", l.tremoloDepth, 0.0, 1.0, "", "How deep the volume dips: 0.3 is gentle, 1 chops to silence.");
        }
        if (auto it = j.find("filter"); it != j.end()) filter(*it, pointer + "/filter", l.filter, false);
        if (auto it = j.find("effects"); it != j.end()) effects(*it, pointer + "/effects", l.effects);
    }

    void normalize(const Json& j, const std::string& pointer, SfxNormalize& n) {
        static const std::vector<std::string> modes = {"lufs", "peak", "none"};
        if (!object(j, pointer, "normalize", "{\"mode\": \"lufs\", \"target\": -18}")) return;
        unknown_keys(j, pointer, {"mode", "target", "ceilingDb"}, "normalize");
        if (int m = choice(j, pointer, "mode", modes, " lufs levels by loudness (right for effects), peak by the loudest sample, none keeps the level the layers add up to (right for instruments)."); m >= 0)
            n.mode = SfxNormalizeMode(m);
        if (n.mode == SfxNormalizeMode::Peak) n.target = -3.0;
        number(j, pointer, "target", n.target, -60.0, 0.0, n.mode == SfxNormalizeMode::Peak ? " (dBFS)" : " (LUFS)", "The level to reach: -18 LUFS is a quiet sound effect, -14 is loud music. In mode peak it is the loudest sample in dBFS.");
        number(j, pointer, "ceilingDb", n.ceilingDb, -24.0, 0.0, " (dBFS)", "The loudest sample is kept under this when the gain would push it higher, e.g. -1.");
    }
};

}  // namespace

std::optional<double> sfx_note_hz(std::string_view note) {
    if (note.size() < 2) return std::nullopt;
    int semitone;
    switch (std::toupper(static_cast<unsigned char>(note[0]))) {
        case 'C': semitone = 0; break;
        case 'D': semitone = 2; break;
        case 'E': semitone = 4; break;
        case 'F': semitone = 5; break;
        case 'G': semitone = 7; break;
        case 'A': semitone = 9; break;
        case 'B': semitone = 11; break;
        default: return std::nullopt;
    }
    std::size_t i = 1;
    if (note[i] == '#') { ++semitone; ++i; }
    else if (note[i] == 'b') { --semitone; ++i; }
    if (i >= note.size()) return std::nullopt;
    bool negative = false;
    if (note[i] == '-') { negative = true; ++i; }
    if (i >= note.size() || note.size() - i > 2) return std::nullopt;
    int octave = 0;
    for (; i < note.size(); ++i) {
        if (note[i] < '0' || note[i] > '9') return std::nullopt;
        octave = octave * 10 + (note[i] - '0');
    }
    if (negative) octave = -octave;
    const int midi = (octave + 1) * 12 + semitone;
    return 440.0 * sfx_math::exp2(double(midi - 69) / 12.0);
}

double SfxPatch::root_hz() const {
    for (const SfxLayer& l : layers)
        for (const SfxOscillator& o : l.oscillators)
            if (o.wave != SfxWave::Noise && o.freq <= 0.0) return l.pitch.freq;
    return 440.0;
}

Result<SfxPatch> parse_sfx(const Json& json, std::string_view fileView, std::vector<SfxIssue>* issuesOut) {
    Parser p;
    SfxPatch patch;
    const std::string file(fileView);
    auto fail = [&]() -> Result<SfxPatch> {
        if (issuesOut) *issuesOut = p.issues;
        const SfxIssue& first = p.issues.front();
        std::string msg = (file.empty() ? "<sound patch>" : file) + " " + (first.pointer.empty() ? "/" : first.pointer) + ": " + first.message;
        if (p.issues.size() > 1) msg += std::format(" (and {} more problem{})", p.issues.size() - 1, p.issues.size() == 2 ? "" : "s");
        return make_error(msg, first.hint);
    };
    if (!json.is_object()) {
        p.err("", "a sound patch must be a JSON object, got " + describe_json_value(json),
              "Start from {\"format\": \"factoria.sfx/1\", \"length\": 0.3, \"layers\": [{\"oscillators\": [{\"wave\": \"sine\"}]}]} (schemas/sfx.schema.json; sfx.preset gives a full patch).");
        return fail();
    }
    p.unknown_keys(json, "", {"$schema", "format", "doc", "sampleRate", "length", "tail", "seed", "fadeOut", "gain", "layers", "master", "macros"}, "the patch");
    if (auto it = json.find("format"); it == json.end() || !it->is_string() || it->get<std::string>() != "factoria.sfx/1")
        p.err("/format", it == json.end() ? "missing `format`" : "format is " + describe_json_value(*it) + ", expected \"factoria.sfx/1\"", "Add \"format\": \"factoria.sfx/1\" at the top of the file.");
    if (auto it = json.find("doc"); it != json.end() && it->is_string()) patch.doc = it->get<std::string>();
    if (auto it = json.find("sampleRate"); it != json.end()) {
        if (!it->is_number_integer() || it->get<long long>() < 8000 || it->get<long long>() > 96000)
            p.err("/sampleRate", "sampleRate must be a whole number from 8000 to 96000, got " + describe_json_value(*it), "Use 44100 (the default), 48000, or 22050 for a smaller file.");
        else patch.sampleRate = it->get<int>();
    }
    p.number(json, "", "length", patch.length, 0.001, kSfxMaxSeconds, " (seconds)", "How long the sound is held, e.g. 0.3 for a blip or 2 for an explosion. A `tail` adds time after it.");
    p.number(json, "", "tail", patch.tail, 0.0, kSfxMaxSeconds, " (seconds)", "Extra seconds after `length` for releases, delay repeats and reverb to die away.");
    if (patch.length + patch.tail > kSfxMaxSeconds)
        p.err("/length", std::format("length + tail is {} s, over the {} s limit of a sound patch", patch.length + patch.tail, kSfxMaxSeconds), "Sound effects are short; use music tools for longer sounds.");
    if (auto it = json.find("seed"); it != json.end()) {
        if (!it->is_number_integer() || it->get<long long>() < 0) p.err("/seed", "seed must be a whole number, 0 or more, got " + describe_json_value(*it), "The seed picks the take of every noise: the same patch and seed give the same sound.");
        else patch.seed = it->get<std::uint64_t>();
    }
    p.number(json, "", "fadeOut", patch.fadeOut, 0.0, 1.0, " (seconds)", "The last stretch of the sound fades out so it never ends in a click; 0 turns it off.");
    p.number(json, "", "gain", patch.gain, 0.0, 8.0, "", "Linear gain of the mix before the master effects.");

    auto lit = json.find("layers");
    if (lit == json.end() || !lit->is_array() || lit->empty() || lit->size() > kMaxLayers) {
        p.err("/layers", "a patch needs `layers`, an array of 1 to 16, got " + (lit == json.end() ? std::string("nothing") : describe_json_value(*lit)),
              "Write \"layers\": [{\"oscillators\": [{\"wave\": \"sine\"}], \"pitch\": {\"freq\": 440}}]; layers play together, each can start later with `start`.");
    } else {
        for (std::size_t i = 0; i < lit->size(); ++i) {
            SfxLayer l;
            p.layer((*lit)[i], "/layers/" + std::to_string(i), l);
            patch.layers.push_back(std::move(l));
        }
    }
    if (auto it = json.find("master"); it != json.end() && p.object(*it, "/master", "master", "{\"effects\": [], \"normalize\": {\"mode\": \"lufs\", \"target\": -18}}")) {
        p.unknown_keys(*it, "/master", {"effects", "normalize"}, "master");
        if (auto e = it->find("effects"); e != it->end()) p.effects(*e, "/master/effects", patch.effects);
        if (auto n = it->find("normalize"); n != it->end()) p.normalize(*n, "/master/normalize", patch.normalize);
    }
    if (auto it = json.find("macros"); it != json.end()) {
        if (!it->is_object()) p.err("/macros", "macros must be an object, got " + describe_json_value(*it), "Macros are reserved for the next release; leave them out or write {}.");
        else patch.macros = *it;
    }
    if (!p.issues.empty()) return fail();
    if (issuesOut) issuesOut->clear();
    return patch;
}

Result<SfxPatch> load_sfx(std::string_view path, std::vector<SfxIssue>* issues) {
    auto text = fs::read_text(path);
    if (!text) return make_error(std::string(path) + ": cannot read the sound patch: " + text.error().message,
                                 text.error().hint.empty() ? "Sound patches are *.sfx.json files; sfx.preset writes a starting point." : text.error().hint);
    auto json = parse_json(*text, path);
    if (!json) return json.error();
    return parse_sfx(*json, path, issues);
}

}  // namespace fa
