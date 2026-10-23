// assets.synth_sound: makes a short sound effect from a preset, offline: no provider, no key. The WAV is a pure function of
// (preset, seed, seconds): the noise comes from a small integer generator seeded with `seed`, never from the clock.
#include <algorithm>
#include <cmath>
#include <cstdint>
#include <format>

#include "assets_internal.h"
#include "fa/core/asset_manifest.h"
#include "fa/core/strings.h"
#include "fa/tooling/asset_import.h"
#include "util.h"

namespace fa::assets_detail {

namespace {

constexpr int kSampleRate = 44100;
constexpr double kPi = 3.14159265358979323846;

enum class Wave { Sine, Square, Saw, Triangle };

// One voice: a tone that sweeps from freq0 to freq1, mixed with filtered noise, under an attack/decay envelope.
struct Preset {
    const char* name;
    const char* what;
    double seconds;
    Wave wave;
    double freq0, freq1;     // Hz at the start and the end (exponential sweep)
    double noise;            // 0..1: share of noise in the mix
    double noiseCutoff;      // 0..1: one-pole low-pass of the noise (1 = white)
    double attack;           // seconds
    double decayPower;       // envelope = (1 - t)^decayPower after the attack
    double vibratoHz, vibratoDepth;  // vibrato of the pitch (depth = fraction of the frequency)
    double tremoloHz, tremoloDepth;  // pulses of the volume (a growl's rattle, a bark's chops)
    double arpeggio;         // coin/pickup: second note this many semitones higher, halfway through
    double duty;             // square wave duty cycle
};

constexpr Preset kPresets[] = {
    {"bark", "a dog bark: two short rough barks", 0.45, Wave::Saw, 520, 260, 0.35, 0.35, 0.005, 2.2, 0, 0, 7.5, 0.95, 0, 0.5},
    {"growl", "a low growl: a rattling low saw with noise", 0.9, Wave::Saw, 95, 70, 0.45, 0.2, 0.08, 0.6, 5, 0.05, 28, 0.6, 0, 0.5},
    {"meow", "a cat meow: a rising then falling vowel-like tone", 0.7, Wave::Triangle, 420, 600, 0.05, 0.3, 0.06, 1.2, 6, 0.03, 0, 0, 0, 0.5},
    {"screech", "a high rough screech", 0.6, Wave::Saw, 1500, 1100, 0.3, 0.8, 0.01, 1.0, 14, 0.06, 0, 0, 0, 0.5},
    {"whoosh", "air passing: noise swelling and fading", 0.6, Wave::Sine, 200, 200, 1.0, 0.18, 0.2, 1.5, 0, 0, 0, 0, 0, 0.5},
    {"explosion", "a blast: low rumble and a noise burst", 1.1, Wave::Sine, 90, 35, 0.75, 0.12, 0.003, 2.0, 0, 0, 0, 0, 0, 0.5},
    {"hit", "an impact: a short thump with a click", 0.18, Wave::Square, 220, 60, 0.4, 0.5, 0.001, 2.5, 0, 0, 0, 0, 0, 0.5},
    {"coin", "a coin pickup: two bright notes", 0.35, Wave::Square, 988, 988, 0, 1, 0.002, 1.3, 0, 0, 0, 0, 5, 0.25},
    {"pickup", "an item pickup: a quick rising blip", 0.25, Wave::Square, 440, 880, 0, 1, 0.002, 1.2, 0, 0, 0, 0, 0, 0.5},
    {"jump", "a jump: a rising chirp", 0.28, Wave::Square, 260, 700, 0, 1, 0.002, 1.1, 0, 0, 0, 0, 0, 0.5},
    {"powerup", "a power-up: a fast rising arpeggio-like sweep", 0.6, Wave::Square, 330, 1320, 0, 1, 0.002, 0.8, 18, 0.03, 0, 0, 0, 0.5},
    {"laser", "a laser shot: a quick falling zap", 0.3, Wave::Saw, 1800, 220, 0.05, 0.9, 0.001, 1.4, 0, 0, 0, 0, 0, 0.5},
    {"blip", "a UI blip: a very short tone", 0.08, Wave::Square, 700, 700, 0, 1, 0.001, 1.0, 0, 0, 0, 0, 0, 0.5},
    {"click", "a UI click: a tiny noise tick", 0.04, Wave::Sine, 1200, 1200, 0.9, 0.7, 0.0005, 2.5, 0, 0, 0, 0, 0, 0.5},
    {"error", "a refusal buzz: two low square pulses", 0.4, Wave::Square, 130, 110, 0.05, 0.5, 0.003, 0.5, 0, 0, 11, 0.9, 0, 0.5},
    {"splash", "water: a noisy plop that fades", 0.5, Wave::Sine, 500, 150, 0.8, 0.3, 0.005, 2.0, 0, 0, 0, 0, 0, 0.5},
    {"footstep", "a soft footstep on dirt", 0.14, Wave::Sine, 110, 70, 0.8, 0.12, 0.002, 2.5, 0, 0, 0, 0, 0, 0.5},
};

const Preset* find_preset(const std::string& name) {
    for (const Preset& p : kPresets)
        if (name == p.name) return &p;
    return nullptr;
}

std::vector<std::string> preset_names() {
    std::vector<std::string> out;
    for (const Preset& p : kPresets) out.push_back(p.name);
    return out;
}

// splitmix64: a tiny generator whose output is the same on every platform.
struct Rng {
    std::uint64_t s;
    std::uint64_t next() {
        std::uint64_t z = (s += 0x9E3779B97F4A7C15ull);
        z = (z ^ (z >> 30)) * 0xBF58476D1CE4E5B9ull;
        z = (z ^ (z >> 27)) * 0x94D049BB133111EBull;
        return z ^ (z >> 31);
    }
    double unit() { return double(next() >> 11) / double(1ull << 53); }               // 0..1
    double range(double lo, double hi) { return lo + (hi - lo) * unit(); }
    double signed_unit() { return unit() * 2.0 - 1.0; }                                // -1..1
};

double oscillator(Wave wave, double phase, double duty) {
    const double x = phase - std::floor(phase);
    switch (wave) {
        case Wave::Sine: return std::sin(2.0 * kPi * x);
        case Wave::Square: return x < duty ? 0.6 : -0.6;
        case Wave::Saw: return 2.0 * x - 1.0;
        case Wave::Triangle: return 4.0 * std::fabs(x - 0.5) - 1.0;
    }
    return 0.0;
}

std::vector<std::int16_t> synthesize(const Preset& preset, std::uint64_t seed, double seconds) {
    Rng rng{seed * 0x2545F4914F6CDD1Dull + 0x1234567ull};
    // The seed moves pitch, length of the envelope and the noise a little, so two seeds are two takes of the same sound.
    const double pitch = rng.range(0.9, 1.1);
    const double rate = rng.range(0.92, 1.08);
    const int total = std::max(1, int(std::lround(seconds * kSampleRate)));
    std::vector<double> samples(std::size_t(total), 0.0);
    double phase = 0.0, lp = 0.0;
    const double a = std::clamp(preset.noiseCutoff, 0.001, 1.0);
    for (int i = 0; i < total; ++i) {
        const double t = double(i) / double(total);          // 0..1 over the sound
        const double sec = double(i) / kSampleRate;
        double f = preset.freq0 * std::pow(preset.freq1 / preset.freq0, t) * pitch;
        if (preset.arpeggio != 0 && t >= 0.4) f *= std::pow(2.0, preset.arpeggio / 12.0);
        if (preset.vibratoHz > 0) f *= 1.0 + preset.vibratoDepth * std::sin(2.0 * kPi * preset.vibratoHz * sec);
        phase += f / kSampleRate;
        lp += a * (rng.signed_unit() - lp);
        const double tone = oscillator(preset.wave, phase, preset.duty);
        double v = tone * (1.0 - preset.noise) + lp * preset.noise * (a < 0.5 ? 2.5 : 1.0);
        const double attack = std::max(preset.attack, 1.0 / kSampleRate);
        double env = std::min(1.0, sec / attack) * std::pow(std::max(0.0, 1.0 - t), preset.decayPower * rate);
        if (preset.tremoloHz > 0) {
            const double chop = 0.5 + 0.5 * std::sin(2.0 * kPi * preset.tremoloHz * rate * sec);
            env *= 1.0 - preset.tremoloDepth * (1.0 - chop);
        }
        if (std::string(preset.name) == "bark") {  // two barks: the second starts at 55 percent, a little lower
            const double u = t < 0.5 ? t / 0.5 : (t - 0.5) / 0.5;
            env = std::min(1.0, sec / 0.004) * std::pow(1.0 - u, 2.2) * (t < 0.5 ? 1.0 : 0.8);
        }
        samples[std::size_t(i)] = v * env;
    }
    // Gentle low-pass for rough tones so the saws do not hiss, then normalize the peak to -3 dBFS.
    double prev = 0.0, peak = 0.0;
    for (double& s : samples) {
        prev += 0.55 * (s - prev);
        s = std::tanh(1.4 * prev);
        peak = std::max(peak, std::fabs(s));
    }
    std::vector<std::int16_t> out(samples.size());
    const double scale = peak > 1e-9 ? 0.708 / peak : 0.0;
    for (std::size_t i = 0; i < samples.size(); ++i) out[i] = std::int16_t(std::lround(std::clamp(samples[i] * scale, -1.0, 1.0) * 32767.0));
    return out;
}

std::string wav_bytes(const std::vector<std::int16_t>& pcm) {
    std::string out;
    auto u32 = [&](std::uint32_t v) { for (int i = 0; i < 4; ++i) out.push_back(char((v >> (8 * i)) & 255)); };
    auto u16 = [&](std::uint16_t v) { for (int i = 0; i < 2; ++i) out.push_back(char((v >> (8 * i)) & 255)); };
    const std::uint32_t dataBytes = std::uint32_t(pcm.size() * 2);
    out += "RIFF"; u32(36 + dataBytes); out += "WAVEfmt "; u32(16); u16(1); u16(1);
    u32(kSampleRate); u32(kSampleRate * 2); u16(2); u16(16);
    out += "data"; u32(dataBytes);
    for (std::int16_t s : pcm) u16(std::uint16_t(s));
    return out;
}

Json synth_sound(const std::string& projectDir, const Json& a) {
    check_arg_keys("assets.synth_sound", a, "", {"path", "preset", "seed", "seconds", "overwrite"});
    const std::string path = tooling_detail::arg_string(a, "path", true);
    const std::string presetName = to_lower(tooling_detail::arg_string(a, "preset", true));
    const Preset* preset = find_preset(presetName);
    if (!preset) {
        const auto names = preset_names();
        fail("invalid_argument", "Unknown preset '" + presetName + "'.", did_you_mean(presetName, names) + " Presets: " + join(names, ", ") + ".");
    }
    auto norm = fs::normalize_checked(path);
    if (!norm.ok() || norm->empty() || !starts_with(*norm, "assets/"))
        fail("invalid_argument", "The sound goes under assets/, and '" + path + "' is not there.", "Use a path such as \"assets/audio/" + presetName + ".wav\".");
    if (to_lower(fs::extension(*norm)) != ".wav")
        fail("invalid_argument", "assets.synth_sound writes WAV files, and '" + *norm + "' does not end in .wav.", "Use a path such as \"assets/audio/" + presetName + ".wav\".");
    const long seed = tooling_detail::arg_int(a, "seed", 0);
    double seconds = preset->seconds;
    if (a.contains("seconds")) {
        if (!a["seconds"].is_number() || a["seconds"].get<double>() < 0.02 || a["seconds"].get<double>() > 10.0)
            fail("invalid_argument", "seconds must be a number from 0.02 to 10.", "Leave it out for the preset's own length (" + std::format("{:.2f}", preset->seconds) + " s for " + presetName + ").");
        seconds = a["seconds"].get<double>();
    }
    const bool overwrite = tooling_detail::arg_bool(a, "overwrite", false);
    const stdfs::path file = project_file(projectDir, *norm);
    std::error_code ec;
    if (!overwrite && stdfs::exists(file, ec)) fail("exists", "'" + *norm + "' already exists.", "Pass overwrite: true to replace it, or choose another `path`.");
    require_usable_manifest(projectDir);

    const std::string bytes = wav_bytes(synthesize(*preset, std::uint64_t(seed), seconds));
    std::string err;
    if (!tooling_detail::write_file(file, bytes, &err)) fail("failed", err);

    Json provenance = Json::object({{"origin", "original"},
                                    {"ai", false},
                                    {"kind", "sound"},
                                    {"provider", "factoria assets.synth_sound"},
                                    {"seed", seed},
                                    {"license", "CC0 (made by the engine's offline synthesizer)"},
                                    {"author", "factoria"},
                                    {"notes", "preset " + presetName + ", " + std::format("{:.2f}", seconds) + " s, seed " + std::to_string(seed)},
                                    {"date", assets::today()}});
    {
        ProjectRootGuard root(projectDir);
        auto r = assets::update_entry(*norm, [&](Json& e) {
            e.erase("analysis");
            e["provenance"] = provenance;
        });
        if (!r.ok()) fail("failed", "The sound was written, but assets.json was not updated: " + r.error().message, r.error().hint);
    }
    return Json::object({{"path", *norm}, {"preset", presetName}, {"seed", seed}, {"seconds", seconds}, {"bytes", bytes.size()}, {"provenance", provenance},
                         {"nextSteps", Json::array({"Play it: audio.play(\"" + *norm + "\") in a script, or an AudioSource \"clip\".",
                                                    "Another take of the same sound: change `seed`. Same seed, same bytes."})}});
}

}  // namespace

void register_synth_sound_command(CommandRegistry& registry, const std::string& projectDir) {
    std::string presets;
    for (const Preset& p : kPresets) presets += std::string("\n- ") + p.name + ": " + p.what + ".";
    CommandInfo info;
    info.name = "assets.synth_sound";
    info.category = "assets";
    info.readOnly = false;
    info.summary = "Make a game sound (bark, growl, coin, jump, explosion...) offline from a preset: a deterministic WAV, no provider and no key.";
    info.description =
        "Synthesizes a short mono 16-bit 44.1 kHz WAV at `path` (under assets/, ending in .wav) from `preset`, with no AI provider and no "
        "key. The same preset, seed and seconds always give the same bytes; another `seed` is another take of the same sound "
        "(pitch and timing move a little). Peaks at -3 dBFS. Records provenance in assets.json (origin original, ai false, license "
        "CC0, the preset and the seed). Presets:" + presets +
        "\nGood for placeholders and simple effects; for richer sounds import a CC0 kit (docs/ASSETS.md) or use assets.generate_sound. "
        "Example: {\"path\":\"assets/audio/dog_bark.wav\",\"preset\":\"bark\",\"seed\":3}";
    info.inputSchema = Json::object(
        {{"type", "object"},
         {"required", Json::array({"path", "preset"})},
         {"additionalProperties", false},
         {"properties",
          Json::object(
              {{"path", Json::object({{"type", "string"}, {"description", "Where to write the WAV, project-relative, under assets/ and ending in .wav, e.g. \"assets/audio/bark.wav\"."}})},
               {"preset", Json::object({{"type", "string"}, {"enum", preset_names()}, {"description", "The kind of sound to make. See the list in the command description."}})},
               {"seed", Json::object({{"type", "integer"}, {"default", 0}, {"description", "Chooses the take: the same preset and seed always give the same file; change it for a variation (pitch and timing shift up to about 10 percent)."}})},
               {"seconds", Json::object({{"type", "number"}, {"minimum", 0.02}, {"maximum", 10}, {"description", "Length in seconds. Default: the preset's own length."}})},
               {"overwrite", Json::object({{"type", "boolean"}, {"default", false}, {"description", "Replace the file when it already exists."}})}})}});
    registry.add(info, [projectDir](const Json& args) { return synth_sound(projectDir, args); });
}

}  // namespace fa::assets_detail
