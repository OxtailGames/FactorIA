// assets.generate_loop and assets.convert_audio: audio made and converted offline, with no provider and no key.
//
// generate_loop writes a seamless loop (a noise bed such as wind, a fire or a clock, or a drone / chord progression for
// music) as a pure function of its arguments and `seed`: the noise comes from a small integer generator, never from the
// clock. convert_audio turns a WAV in the project into an Ogg Vorbis file with the encoder of fa_audio (encode_vorbis).
#include <algorithm>
#include <cmath>
#include <cstdint>
#include <format>
#include <map>

#include "assets_internal.h"
#include "fa/audio/convert.h"
#include "fa/core/asset_manifest.h"
#include "fa/core/strings.h"
#include "fa/tooling/asset_import.h"
#include "util.h"

namespace fa::assets_detail {

namespace {

constexpr double kPi = 3.14159265358979323846;
constexpr double kTau = 2 * kPi;

struct Rng {  // splitmix64
    std::uint64_t s;
    std::uint64_t next() {
        std::uint64_t z = (s += 0x9E3779B97F4A7C15ull);
        z = (z ^ (z >> 30)) * 0xBF58476D1CE4E5B9ull;
        z = (z ^ (z >> 27)) * 0x94D049BB133111EBull;
        return z ^ (z >> 31);
    }
    double unit() { return double(next() >> 11) / double(1ull << 53); }
    double range(double lo, double hi) { return lo + (hi - lo) * unit(); }
    double signed_unit() { return unit() * 2.0 - 1.0; }
};

using Buf = std::vector<double>;

// Runs `step` (a filter with state) over the loop twice and keeps the second pass: the state at the end of the loop is
// the state at its start, so the filter leaves no seam.
template <class Step>
Buf circular(const Buf& x, Step step) {
    Buf y(x.size());
    for (int pass = 0; pass < 2; ++pass)
        for (std::size_t i = 0; i < x.size(); ++i) y[i] = step(x[i]);
    return y;
}

Buf lowpass(const Buf& x, double cutoffHz, int rate) {
    const double k = 1.0 - std::exp(-kTau * cutoffHz / rate);
    double s = 0;
    return circular(x, [&](double v) { return s += (v - s) * k; });
}

// Adds `signal` to the loop at `start`, wrapping round the end.
void wrap_add(Buf& buf, std::int64_t start, const Buf& signal, double gain) {
    const std::int64_t n = std::int64_t(buf.size());
    for (std::size_t i = 0; i < signal.size(); ++i) {
        const std::int64_t at = ((start + std::int64_t(i)) % n + n) % n;  // start may be negative: a note that begins before the loop
        buf[std::size_t(at)] += signal[i] * gain;
    }
}

void normalize_to(Buf& buf, double peak) {
    double top = 1e-12;
    for (double v : buf) top = std::max(top, std::fabs(v));
    for (double& v : buf) v *= peak / top;
}

// ---- noise beds ----------------------------------------------------------------------------------------------------------

struct NoiseSpec {
    std::string color = "brown";
    double cutoff = 0, level = 1, gusts = 0, crackles = 0, tick = 0;
    std::vector<double> hum;
};

Buf noise_loop(const NoiseSpec& sp, std::uint64_t seed, double seconds, int rate) {
    const std::size_t n = std::size_t(std::llround(seconds * rate));
    Rng rng{seed};
    Buf white(n);
    for (double& v : white) v = rng.signed_unit();
    Buf bed = white;
    if (sp.color == "pink") {  // Paul Kellett's economy filter
        double b0 = 0, b1 = 0, b2 = 0, b3 = 0, b4 = 0, b5 = 0, b6 = 0;
        bed = circular(white, [&](double w) {
            b0 = 0.99886 * b0 + w * 0.0555179;
            b1 = 0.99332 * b1 + w * 0.0750759;
            b2 = 0.96900 * b2 + w * 0.1538520;
            b3 = 0.86650 * b3 + w * 0.3104856;
            b4 = 0.55000 * b4 + w * 0.5329522;
            b5 = -0.7616 * b5 - w * 0.0168980;
            const double out = b0 + b1 + b2 + b3 + b4 + b5 + b6 + w * 0.5362;
            b6 = w * 0.115926;
            return out;
        });
    } else if (sp.color == "brown") {
        double s = 0;
        bed = circular(white, [&](double w) { return s = 0.997 * s + 0.05 * w; });
    }
    if (sp.cutoff > 0) bed = lowpass(bed, sp.cutoff, rate);
    normalize_to(bed, 1.0);
    if (sp.gusts > 0) {  // slow swells whose periods divide the loop, so the end meets the start
        const int base = std::max(1, int(std::lround(seconds / 10.0)));
        const double p1 = rng.range(0, kTau), p2 = rng.range(0, kTau);
        for (std::size_t i = 0; i < n; ++i) {
            const double u = double(i) / double(n);
            const double g = 0.5 * std::sin(kTau * base * u) + 0.3 * std::sin(kTau * (2 * base + 1) * u + p1) + 0.2 * std::sin(kTau * (3 * base + 2) * u + p2);
            bed[i] *= std::max(0.0, 1.0 + sp.gusts * g);
        }
    }
    for (double& v : bed) v *= sp.level;
    for (double hz : sp.hum) {  // a hum snapped to a whole number of cycles in the loop
        const double cycles = std::max(1.0, std::round(hz * seconds));
        for (std::size_t i = 0; i < n; ++i) bed[i] += 0.3 * std::sin(kTau * cycles * double(i) / double(n));
    }
    const std::int64_t pops = std::int64_t(std::llround(sp.crackles * seconds));
    for (std::int64_t p = 0; p < pops; ++p) {
        const std::int64_t at = std::int64_t(rng.unit() * double(n));
        const std::size_t len = std::max<std::size_t>(2, std::size_t(rate * rng.range(0.004, 0.03)));
        const double gain = rng.range(0.15, 0.9) * (rng.unit() < 0.12 ? 1.6 : 1.0);
        Buf pop(len);
        for (std::size_t i = 0; i < len; ++i) pop[i] = rng.signed_unit() * std::exp(-double(i) / (double(len) / 3.5));
        wrap_add(bed, at, pop, gain * 0.7);
    }
    if (sp.tick > 0) {  // tick (higher) and tock (lower), alternating
        const std::int64_t count = std::int64_t(std::llround(seconds / sp.tick));
        for (std::int64_t k = 0; k < count; ++k) {
            const bool high = k % 2 == 0;
            const double ring = high ? 2300 : 1750, body = high ? 640 : 520;
            const std::size_t len = std::size_t(rate * 0.25);
            Rng tr{seed + 100 + std::uint64_t(k)};
            Buf sig(len);
            for (std::size_t i = 0; i < len; ++i) {
                const double t = double(i) / rate;
                sig[i] = tr.signed_unit() * std::exp(-t / 0.0015) * 0.9 + std::sin(kTau * ring * t) * std::exp(-t / 0.012) * 0.5 +
                         std::sin(kTau * body * t) * std::exp(-t / 0.03) * 0.7;
            }
            wrap_add(bed, std::int64_t(std::llround(double(k) * sp.tick * rate)), sig, 1.0);
        }
    }
    return bed;
}

// ---- drones and chord progressions -------------------------------------------------------------------------------------------

double note_frequency(const Json& note, const std::string& where) {
    if (note.is_number() && note.get<double>() > 10 && note.get<double>() < 12000) return note.get<double>();
    if (note.is_string()) {
        const std::string s = note.get<std::string>();
        static const std::map<char, int> base = {{'C', 0}, {'D', 2}, {'E', 4}, {'F', 5}, {'G', 7}, {'A', 9}, {'B', 11}};
        std::size_t i = 0;
        int semis = -1;
        if (!s.empty() && base.count(s[0])) {
            semis = base.at(s[0]);
            i = 1;
            if (i < s.size() && s[i] == '#') ++semis, ++i;
            else if (i < s.size() && s[i] == 'b') --semis, ++i;
            if (i < s.size() && (s[i] >= '0' && s[i] <= '8') && i + 1 == s.size()) {
                const int octave = s[i] - '0';
                return 440.0 * std::pow(2.0, (semis + 12 * (octave + 1) - 69) / 12.0);
            }
        }
    }
    fail("invalid_argument", where + ": '" + note.dump() + "' is not a note.", "Use a note name such as \"A3\", \"F#2\" or \"Eb4\" (octaves 0 to 8), or a frequency in Hz (10 to 12000).");
}

// A soft sustained note: three partials with a slow attack and release, wrapped round the loop.
void pad(Buf& buf, int rate, double start, double secs, double freq, double gain, double bright) {
    const std::size_t len = std::size_t(secs * rate);
    const double att = rate * std::min(1.6, secs * 0.4), rel = rate * std::min(2.2, secs * 0.5);
    Buf sig(len);
    for (std::size_t i = 0; i < len; ++i) {
        const double env = std::min({1.0, double(i) / att, double(len - i) / rel});
        const double t = double(i) / rate;
        sig[i] = (std::sin(kTau * freq * t) + 0.5 * std::sin(kTau * freq * 1.003 * t + 1.0) + bright * std::sin(kTau * freq * 2 * t)) * env;
    }
    wrap_add(buf, std::int64_t(std::llround(start * rate)), sig, gain);
}

// A music-box note: a bright sine that dies away.
void pluck(Buf& buf, int rate, double start, double freq, double gain) {
    constexpr double ring = 1.6;
    const std::size_t len = std::size_t(rate * ring * 2);
    Buf sig(len);
    for (std::size_t i = 0; i < len; ++i) {
        const double t = double(i) / rate;
        sig[i] = (std::sin(kTau * freq * t) + 0.3 * std::sin(kTau * freq * 3 * t) * std::exp(-t / 0.15)) * std::exp(-t / ring);
    }
    wrap_add(buf, std::int64_t(std::llround(start * rate)), sig, gain);
}

struct Arpeggio {
    double every = 0, gain = 0.2;
    std::vector<int> pattern;  // index into the chord (past its end: the same note an octave up); -1 is a rest
};

struct DroneSpec {
    std::vector<std::vector<double>> chords;
    double chordSeconds = 0, bass = 0.5, brightness = 0.3;
    double underNote = 0, underLevel = 0.5;  // one soft note held under the whole loop (0: none)
    Arpeggio arpeggio;
};

Buf drone_loop(const DroneSpec& sp, std::uint64_t seed, double seconds, int rate) {
    Buf buf(std::size_t(std::llround(seconds * rate)), 0.0);
    Rng rng{seed};
    if (sp.underNote > 0) pad(buf, rate, 0, double(buf.size()) / rate, sp.underNote, sp.underLevel, 0.05);
    for (std::size_t b = 0; b < sp.chords.size(); ++b) {
        const double start = double(b) * sp.chordSeconds;
        const auto& chord = sp.chords[b];
        for (double f : chord) pad(buf, rate, start - 0.2, sp.chordSeconds + 1.2, f, 0.22, sp.brightness);
        if (sp.bass > 0) pad(buf, rate, start - 0.2, sp.chordSeconds + 1.2, chord[0] / 2, sp.bass, 0.1);
        if (sp.arpeggio.every > 0 && !sp.arpeggio.pattern.empty()) {
            const int steps = std::max(1, int(sp.chordSeconds / sp.arpeggio.every));
            for (int s = 0; s < steps; ++s) {
                const int idx = sp.arpeggio.pattern[(b * std::size_t(steps) + std::size_t(s)) % sp.arpeggio.pattern.size()];
                const double jitter = rng.range(0, 0.02);  // drawn for every step, so a rest does not shift the later ones
                if (idx < 0) continue;
                const double f = chord[std::size_t(idx) % chord.size()] * (std::size_t(idx) >= chord.size() ? 2.0 : 1.0);
                pluck(buf, rate, start + s * sp.arpeggio.every + jitter, f, sp.arpeggio.gain);
            }
        }
    }
    return buf;
}

// ---- files ---------------------------------------------------------------------------------------------------------------------

std::string wav_bytes(const Buf& samples, int rate, double peak) {
    std::string out;
    auto u32 = [&](std::uint32_t v) { for (int i = 0; i < 4; ++i) out.push_back(char((v >> (8 * i)) & 255)); };
    auto u16 = [&](std::uint16_t v) { for (int i = 0; i < 2; ++i) out.push_back(char((v >> (8 * i)) & 255)); };
    const std::uint32_t dataBytes = std::uint32_t(samples.size() * 2);
    out += "RIFF"; u32(36 + dataBytes); out += "WAVEfmt "; u32(16); u16(1); u16(1);
    u32(std::uint32_t(rate)); u32(std::uint32_t(rate) * 2); u16(2); u16(16);
    out += "data"; u32(dataBytes);
    double top = 1e-12;
    for (double v : samples) top = std::max(top, std::fabs(v));
    for (double v : samples) u16(std::uint16_t(std::int16_t(std::lround(std::clamp(v / top * peak, -1.0, 1.0) * 32767.0))));
    return out;
}

std::string project_audio_path(const Json& a, const char* key, const char* command, const std::vector<std::string>& extensions, const std::string& example) {
    const std::string path = tooling_detail::arg_string(a, key, true);
    auto norm = fs::normalize_checked(path);
    if (!norm.ok() || norm->empty() || !starts_with(*norm, "assets/"))
        fail("invalid_argument", std::string("The ") + key + " goes under assets/, and '" + path + "' is not there.", "Use a path such as \"" + example + "\".");
    const std::string ext = to_lower(fs::extension(*norm));
    if (std::find(extensions.begin(), extensions.end(), ext) == extensions.end())
        fail("invalid_argument", std::string(command) + " needs '" + *norm + "' to end in " + join(extensions, " or ") + ".", "Use a path such as \"" + example + "\".");
    return *norm;
}

double number_arg(const char* command, const Json& a, const char* key, double def, double lo, double hi) {
    if (!a.contains(key)) return def;
    if (!a[key].is_number() || a[key].get<double>() < lo || a[key].get<double>() > hi)
        arg_error(command, std::string("/") + key, "must be a number from " + std::format("{}", lo) + " to " + std::format("{}", hi) + ".", "Leave it out for the default (" + std::format("{}", def) + ").");
    return a[key].get<double>();
}

void record_provenance(const std::string& projectDir, const std::string& path, const Json& provenance) {
    ProjectRootGuard root(projectDir);
    auto r = assets::update_entry(path, [&](Json& e) {
        e.erase("analysis");
        e["provenance"] = provenance;
    });
    if (!r.ok()) fail("failed", "The sound was written, but assets.json was not updated: " + r.error().message, r.error().hint);
}

Json generate_loop(const std::string& projectDir, const Json& a) {
    constexpr const char* cmd = "assets.generate_loop";
    check_arg_keys(cmd, a, "", {"path", "kind", "seconds", "sampleRate", "seed", "peak", "quality", "overwrite", "color", "cutoff", "level", "gusts", "crackles",
                                "tick", "hum", "chords", "chordSeconds", "bass", "brightness", "arpeggio", "underNote", "underLevel"});
    const std::string path = project_audio_path(a, "path", cmd, {".wav", ".ogg"}, "assets/audio/wind.wav");
    const std::string kind = to_lower(tooling_detail::arg_string(a, "kind", true));
    if (kind != "noise" && kind != "drone")
        fail("invalid_argument", "Unknown kind '" + kind + "'.", did_you_mean(kind, std::vector<std::string>{"noise", "drone"}) + " kind is \"noise\" (wind, fire, rain, a clock) or \"drone\" (pads and chords for music).");
    const long seed = tooling_detail::arg_int(a, "seed", 0);
    const int rate = int(number_arg(cmd, a, "sampleRate", 22050, 8000, 48000));
    const double peak = number_arg(cmd, a, "peak", 0.6, 0.05, 0.95);
    const double quality = number_arg(cmd, a, "quality", 0.6, 0, 1);
    const bool overwrite = tooling_detail::arg_bool(a, "overwrite", false);
    // arguments of the other kind are mistakes, not ignored settings
    const std::vector<std::string> noiseKeys = {"color", "cutoff", "level", "gusts", "crackles", "tick", "hum"};
    const std::vector<std::string> droneKeys = {"chords", "chordSeconds", "bass", "brightness", "arpeggio", "underNote", "underLevel"};
    for (const std::string& key : kind == "noise" ? droneKeys : noiseKeys)
        if (a.contains(key)) arg_error(cmd, "/" + key, "belongs to kind \"" + (kind == "noise" ? std::string("drone") : std::string("noise")) + "\", not \"" + kind + "\".", "Remove it, or set kind to \"" + (kind == "noise" ? std::string("drone") : std::string("noise")) + "\".");

    double seconds = number_arg(cmd, a, "seconds", 12, 1, 120);
    Buf pcm;
    std::string notes;
    if (kind == "noise") {
        NoiseSpec sp;
        sp.color = to_lower(tooling_detail::arg_string(a, "color", false, "brown"));
        if (sp.color != "white" && sp.color != "pink" && sp.color != "brown")
            arg_error(cmd, "/color", "'" + sp.color + "' is not a noise color.", did_you_mean(sp.color, std::vector<std::string>{"white", "pink", "brown"}) + " white is hiss, pink is rain, brown is rumble and wind.");
        sp.cutoff = number_arg(cmd, a, "cutoff", 0, 0, 20000);
        sp.level = number_arg(cmd, a, "level", 1, 0, 1);
        sp.gusts = number_arg(cmd, a, "gusts", 0, 0, 1);
        sp.crackles = number_arg(cmd, a, "crackles", 0, 0, 200);
        sp.tick = number_arg(cmd, a, "tick", 0, 0, 30);
        if (a.contains("hum")) {
            if (!a["hum"].is_array()) arg_error(cmd, "/hum", "must be an array of frequencies in Hz.", "For example [55, 110].");
            for (const Json& h : a["hum"]) sp.hum.push_back(note_frequency(h, std::string(cmd) + " /hum"));
        }
        if (sp.level == 0 && sp.tick == 0 && sp.hum.empty() && sp.crackles == 0)
            arg_error(cmd, "/level", "0 with no tick, hum or crackles makes silence.", "Raise `level`, or add `tick`, `hum` or `crackles`.");
        pcm = noise_loop(sp, std::uint64_t(seed), seconds, rate);
        notes = std::format("noise {}, cutoff {} Hz, level {}, gusts {}, crackles {}/s, tick {} s", sp.color, sp.cutoff, sp.level, sp.gusts, sp.crackles, sp.tick);
    } else {
        DroneSpec sp;
        if (!a.contains("chords") || !a["chords"].is_array() || a["chords"].empty())
            arg_error(cmd, "/chords", "kind \"drone\" needs `chords`: an array of chords, each an array of notes.", "For example [[\"A2\",\"E3\"]] for one drone, or [[\"D3\",\"F3\",\"A3\"],[\"Bb2\",\"D3\",\"F3\"]] for a progression.");
        for (std::size_t c = 0; c < a["chords"].size(); ++c) {
            const Json& chord = a["chords"][c];
            if (!chord.is_array() || chord.empty()) arg_error(cmd, "/chords/" + std::to_string(c), "must be an array of notes.", "For example [\"A3\",\"C4\",\"E4\"].");
            std::vector<double> freqs;
            for (std::size_t n = 0; n < chord.size(); ++n) freqs.push_back(note_frequency(chord[n], std::string(cmd) + " /chords/" + std::to_string(c) + "/" + std::to_string(n)));
            sp.chords.push_back(freqs);
        }
        if (a.contains("chordSeconds")) sp.chordSeconds = number_arg(cmd, a, "chordSeconds", 6, 0.5, 60);
        if (a.contains("chordSeconds") && !a.contains("seconds")) seconds = sp.chordSeconds * double(sp.chords.size());
        if (seconds > 120) arg_error(cmd, "/chordSeconds", "chords times chordSeconds is more than 120 s.", "Use fewer chords or a shorter chordSeconds.");
        if (sp.chordSeconds <= 0) sp.chordSeconds = seconds / double(sp.chords.size());
        if (std::fabs(sp.chordSeconds * double(sp.chords.size()) - seconds) > 0.01)
            arg_error(cmd, "/seconds", "the chords last " + std::format("{}", sp.chordSeconds * double(sp.chords.size())) + " s (chords x chordSeconds), not " + std::format("{}", seconds) + ".", "Leave `seconds` out, or make it chords x chordSeconds.");
        sp.bass = number_arg(cmd, a, "bass", 0.5, 0, 1);
        sp.brightness = number_arg(cmd, a, "brightness", 0.3, 0, 1);
        if (a.contains("underNote")) sp.underNote = note_frequency(a["underNote"], "/underNote");
        sp.underLevel = number_arg(cmd, a, "underLevel", 0.5, 0, 1);
        if (a.contains("arpeggio")) {
            const Json& ar = a["arpeggio"];
            if (!ar.is_object()) arg_error(cmd, "/arpeggio", "must be an object {every, pattern, gain}.", "For example {\"every\": 0.75, \"pattern\": [0, 2, 1, null], \"gain\": 0.2}.");
            check_arg_keys(cmd, ar, "/arpeggio", {"every", "pattern", "gain"});
            sp.arpeggio.every = number_arg(cmd, ar, "every", 0.75, 0.1, 30);
            sp.arpeggio.gain = number_arg(cmd, ar, "gain", 0.2, 0, 1);
            if (!ar.contains("pattern") || !ar["pattern"].is_array() || ar["pattern"].empty())
                arg_error(cmd, "/arpeggio/pattern", "needs an array of chord indexes (null is a rest).", "For example [0, 2, 1, null]: index 0 is the chord's first note; an index past its end is the same note an octave up.");
            for (const Json& v : ar["pattern"]) {
                if (v.is_null()) sp.arpeggio.pattern.push_back(-1);
                else if (v.is_number_integer() && v.get<int>() >= 0) sp.arpeggio.pattern.push_back(v.get<int>());
                else arg_error(cmd, "/arpeggio/pattern", "holds '" + v.dump() + "', not a chord index.", "Use whole numbers from 0 up, or null for a rest.");
            }
        }
        pcm = drone_loop(sp, std::uint64_t(seed), seconds, rate);
        notes = std::format("{} chord(s) of {} s, bass {}, brightness {}{}", sp.chords.size(), sp.chordSeconds, sp.bass, sp.brightness, sp.arpeggio.every > 0 ? ", arpeggio" : "");
    }
    const stdfs::path file = project_file(projectDir, path);
    std::error_code ec;
    if (!overwrite && stdfs::exists(file, ec)) fail("exists", "'" + path + "' already exists.", "Pass overwrite: true to replace it, or choose another `path`.");
    require_usable_manifest(projectDir);

    std::string bytes = wav_bytes(pcm, rate, peak);
    const bool ogg = to_lower(fs::extension(path)) == ".ogg";
    if (ogg) {
        auto encoded = encode_vorbis({reinterpret_cast<const std::uint8_t*>(bytes.data()), bytes.size()}, quality);
        if (!encoded.ok()) fail("failed", "The loop could not be encoded as Ogg: " + encoded.error().message, encoded.error().hint);
        bytes.assign(reinterpret_cast<const char*>(encoded->data()), encoded->size());
    }
    std::string err;
    if (!tooling_detail::write_file(file, bytes, &err)) fail("failed", err);
    const Json provenance = Json::object({{"origin", "original"}, {"ai", false}, {"kind", "sound"}, {"provider", "factoria assets.generate_loop"}, {"seed", seed},
                                          {"license", "CC0-1.0"}, {"author", "factoria"},
                                          {"notes", "Synthesised loop (" + kind + "): " + notes + ", " + std::format("{:.2f}", seconds) + " s at " + std::to_string(rate) + " Hz, seed " + std::to_string(seed) + ". No recording or sample."},
                                          {"date", assets::today()}});
    record_provenance(projectDir, path, provenance);
    Json next = Json::array({"Loop it: an AudioSource with \"loop\": true, or audio.music(\"" + path + "\").",
                             "Another take: change `seed`. Same arguments, same bytes."});
    if (ogg) next.push_back("A WAV loop repeats sample for sample; an Ogg Vorbis loop is within the codec's noise at its seam, which ambience hides.");
    return Json::object({{"path", path}, {"kind", kind}, {"seconds", seconds}, {"sampleRate", rate}, {"seed", seed}, {"bytes", bytes.size()}, {"provenance", provenance}, {"nextSteps", next}});
}

Json convert_audio(const std::string& projectDir, const Json& a) {
    constexpr const char* cmd = "assets.convert_audio";
    check_arg_keys(cmd, a, "", {"path", "to", "quality", "overwrite"});
    const std::string path = project_audio_path(a, "path", cmd, {".wav"}, "assets/audio/wind.wav");
    const std::string to = a.contains("to") ? project_audio_path(a, "to", cmd, {".ogg"}, "assets/audio/wind.ogg")
                                            : fs::parent(path).empty() ? fs::stem(path) + ".ogg" : fs::parent(path) + "/" + fs::stem(path) + ".ogg";
    const double quality = number_arg(cmd, a, "quality", 0.6, 0, 1);
    const bool overwrite = tooling_detail::arg_bool(a, "overwrite", false);
    const stdfs::path source = project_file(projectDir, path), dest = project_file(projectDir, to);
    std::error_code ec;
    if (!stdfs::exists(source, ec)) fail("not_found", "'" + path + "' does not exist.", "Make or import the WAV first (assets.generate_loop, assets.synth_sound, assets.import).");
    if (!overwrite && stdfs::exists(dest, ec)) fail("exists", "'" + to + "' already exists.", "Pass overwrite: true to replace it, or choose another `to`.");
    require_usable_manifest(projectDir);
    auto wav = read_bytes(source);
    if (!wav.ok()) fail("failed", wav.error().message, wav.error().hint);
    auto encoded = encode_vorbis(*wav, quality);
    if (!encoded.ok()) fail("failed", "'" + path + "' could not be converted: " + encoded.error().message, encoded.error().hint);
    std::string err;
    if (!tooling_detail::write_file(dest, std::string_view(reinterpret_cast<const char*>(encoded->data()), encoded->size()), &err)) fail("failed", err);

    Json provenance;
    {
        ProjectRootGuard root(projectDir);
        const Json* old = nullptr;
        const Json entry = assets::entry(path);
        if (entry.is_object() && entry.contains("provenance") && entry["provenance"].is_object()) old = &entry["provenance"];
        provenance = old ? *old : Json::object({{"origin", "original"}, {"ai", false}, {"kind", "sound"}, {"author", "factoria"}, {"date", assets::today()}});
        std::string notes = provenance.value("notes", std::string());
        if (!notes.empty()) notes += " ";
        provenance["notes"] = notes + "Converted from " + path + " to Ogg Vorbis (quality " + std::format("{}", quality) + ") by assets.convert_audio.";
        if (!old) provenance["notes"] = "Converted from " + path + " (which had no provenance record) to Ogg Vorbis by assets.convert_audio. Describe where the WAV came from with assets.set_provenance.";
    }
    record_provenance(projectDir, to, provenance);
    Json out = Json::object({{"path", to}, {"source", path}, {"quality", quality}, {"sourceBytes", wav->size()}, {"bytes", encoded->size()}, {"provenance", provenance},
                             {"nextSteps", Json::array({"Point scenes and scripts at '" + to + "' and delete '" + path + "' when nothing else uses it (the WAV is kept).",
                                                        "Listen for artifacts: raise `quality` (0 to 1) if the Ogg sounds rough; check loudness with assets.analyze_audio."})}});
    return out;
}

}  // namespace

void register_audio_commands(CommandRegistry& registry, const std::string& projectDir) {
    {
        CommandInfo info;
        info.name = "assets.generate_loop";
        info.category = "assets";
        info.readOnly = false;
        info.summary = "Make a seamless loop offline (a wind or fire bed, a clock, a drone or chord pad) as a WAV or Ogg: no provider, no key.";
        info.description =
            "Synthesizes a mono loop at `path` (under assets/, .wav or .ogg) from `kind`, with no AI provider and no key. The same arguments and "
            "`seed` always give the same bytes. The end of the loop meets its start: filters run round the loop, gusts and hums have a whole number of "
            "cycles, and pops, ticks and notes wrap round the end. Records provenance in assets.json (origin original, ai false, license CC0).\n"
            "kind \"noise\": a bed of `color` noise (white = hiss, pink = rain, brown = rumble and wind) low-passed at `cutoff` Hz and scaled by `level`; "
            "`gusts` (0 to 1) swells it slowly; `crackles` adds random pops per second (a fire); `tick` adds a tick-tock every that many seconds (a "
            "clock; make `seconds` a multiple of it and `level` 0 for the ticks alone); `hum` adds sines at those Hz (a cellar's mains hum).\n"
            "kind \"drone\": `chords`, an array of chords of notes (\"A3\", \"F#2\", \"Eb4\", or Hz); each chord is a soft pad lasting `chordSeconds`, with "
            "the first note an octave down at `bass` level. A single chord is a drone. `arpeggio` {every, pattern, gain} plays music-box plucks over "
            "it: `pattern` holds chord indexes (null = a rest, past the chord's end = an octave up).\n"
            "Wind: {\"kind\":\"noise\",\"color\":\"brown\",\"cutoff\":900,\"gusts\":0.6,\"seconds\":20}. Fire: {\"kind\":\"noise\",\"color\":\"brown\",\"cutoff\":600,\"crackles\":4}. "
            "Clock: {\"kind\":\"noise\",\"level\":0,\"tick\":1,\"seconds\":4}. Score: {\"kind\":\"drone\",\"chords\":[[\"D3\",\"F3\",\"A3\"],[\"Bb2\",\"D3\",\"F3\"]],"
            "\"chordSeconds\":6,\"arpeggio\":{\"every\":0.75,\"pattern\":[0,2,1,2],\"gain\":0.16}}. A WAV loops sample for sample; an Ogg loop is smaller and "
            "within the codec's noise at the seam (see assets.convert_audio).";
        info.inputSchema = Json::parse(R"({
          "type":"object","required":["path","kind"],"additionalProperties":false,
          "properties":{
            "path":{"type":"string","description":"Where to write the loop, project-relative, under assets/ and ending in .wav or .ogg, e.g. \"assets/audio/wind.wav\"."},
            "kind":{"type":"string","enum":["noise","drone"],"description":"noise: a bed (wind, fire, rain, a clock). drone: pads and chords (music, a mood)."},
            "seconds":{"type":"number","minimum":1,"maximum":120,"description":"Length of the loop (default 12). For a drone with chordSeconds, leave it out to get chords x chordSeconds."},
            "sampleRate":{"type":"integer","minimum":8000,"maximum":48000,"default":22050,"description":"Sample rate in Hz. 22050 is plenty for ambience; the engine resamples."},
            "seed":{"type":"integer","default":0,"description":"Chooses the take: the same arguments and seed give the same file."},
            "peak":{"type":"number","minimum":0.05,"maximum":0.95,"default":0.6,"description":"Loudest sample as a fraction of full scale. Default 0.6 (-4.4 dBFS)."},
            "quality":{"type":"number","minimum":0,"maximum":1,"default":0.6,"description":"Ogg only: quality of the encoding (more quality, bigger file)."},
            "overwrite":{"type":"boolean","default":false,"description":"Replace the file when it already exists."},
            "color":{"type":"string","enum":["white","pink","brown"],"description":"(Default brown.) noise: the colour of the noise."},
            "cutoff":{"type":"number","minimum":0,"maximum":20000,"description":"(Default 0.) noise: low-pass in Hz; 0 leaves the noise as it is. Lower is darker (wind 500-1500, fire 400-800)."},
            "level":{"type":"number","minimum":0,"maximum":1,"description":"(Default 1.) noise: volume of the bed relative to the pops, ticks and hum; 0 makes them the only sound."},
            "gusts":{"type":"number","minimum":0,"maximum":1,"description":"(Default 0.) noise: depth of slow swells of the bed (0 steady, 1 deep gusts)."},
            "crackles":{"type":"number","minimum":0,"maximum":200,"description":"(Default 0.) noise: random pops per second (a fire: 3-6)."},
            "tick":{"type":"number","minimum":0,"maximum":30,"description":"(Default 0.) noise: seconds between the ticks of a clock (alternating tick and tock); 0 for none."},
            "hum":{"type":"array","items":{"type":["number","string"]},"description":"noise: frequencies in Hz (or note names) of steady hum tones added to the bed."},
            "chords":{"type":"array","items":{"type":"array","items":{"type":["string","number"]}},"description":"drone: chords, each an array of note names (\"A3\", \"F#2\") or Hz. The first note of a chord is also played an octave down."},
            "chordSeconds":{"type":"number","minimum":0.5,"maximum":60,"description":"drone: seconds each chord lasts. Default: seconds divided by the number of chords."},
            "bass":{"type":"number","minimum":0,"maximum":1,"description":"(Default 0.5.) drone: level of the low note under each chord."},
            "brightness":{"type":"number","minimum":0,"maximum":1,"description":"(Default 0.3.) drone: level of the octave partial above each note (0 dull, 1 bright)."},
            "underNote":{"description":"drone: one soft note held under the whole loop, whatever the chords do: a name such as \"D1\" or a frequency in Hz."},
            "underLevel":{"type":"number","minimum":0,"maximum":1,"description":"(Default 0.5.) drone: level of `underNote`."},
            "arpeggio":{"type":"object","description":"drone: music-box plucks over the chords.","additionalProperties":false,"required":["pattern"],
              "properties":{"every":{"type":"number","default":0.75,"description":"Seconds between plucks."},
                            "pattern":{"type":"array","items":{"type":["integer","null"]},"description":"Chord indexes to pluck in turn, looping; null is a rest; an index past the chord's end is an octave up."},
                            "gain":{"type":"number","default":0.2,"description":"Volume of the plucks against the pads."}}}
          }})");
        registry.add(info, [projectDir](const Json& args) { return generate_loop(projectDir, args); });
    }
    {
        CommandInfo info;
        info.name = "assets.convert_audio";
        info.category = "assets";
        info.readOnly = false;
        info.summary = "Convert a WAV in the project to Ogg Vorbis (smaller, streams well) and record where it came from.";
        info.description =
            "Reads the WAV at `path` (8, 16, 24 or 32-bit PCM or float, mono or stereo) and writes an Ogg Vorbis file at `to` (default: the same name ending in "
            ".ogg), with the encoder of this engine (fixed block size, no stereo coupling: about 4 to 6 times smaller than 16-bit WAV at the default quality, "
            "less than libvorbis would reach). The sample rate and length are kept. The WAV stays; the provenance of the WAV is copied to the Ogg with a note. "
            "Use it for music and long ambience (a streamed .ogg keeps little in memory, docs/ASSETS.md); keep short effects as WAV. "
            "Example: {\"path\":\"assets/audio/wind.wav\",\"quality\":0.6}";
        info.inputSchema = Json::parse(R"({
          "type":"object","required":["path"],"additionalProperties":false,
          "properties":{
            "path":{"type":"string","description":"The WAV to convert, project-relative, under assets/."},
            "to":{"type":"string","description":"Where to write the Ogg, under assets/ and ending in .ogg. Default: next to the WAV, same name."},
            "quality":{"type":"number","minimum":0,"maximum":1,"default":0.6,"description":"0 to 1. Higher is bigger and closer to the WAV; 0.6 suits ambience, 0.8 music."},
            "overwrite":{"type":"boolean","default":false,"description":"Replace the Ogg when it already exists."}
          }})");
        registry.add(info, [projectDir](const Json& args) { return convert_audio(projectDir, args); });
    }
}

}  // namespace fa::assets_detail
