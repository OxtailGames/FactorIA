// Reads `*.audio.json` into an AudioDoc (fa/audio/audio_doc.h). Every problem is reported with its JSON pointer, what is wrong and
// how to fix it; names get "did you mean". The step catalog below is the one place that knows the fields of each step: the parser,
// `audio.info`, the docs reference and schemas/audio.schema.json all follow it.
#include <algorithm>
#include <cmath>
#include <format>

#include "fa/audio/audio_doc.h"
#include "fa/core/fs.h"
#include "fa/core/strings.h"

namespace fa {

namespace {

using F = AudioFieldInfo;

F num(const char* key, const char* doc, double lo, double hi, std::optional<double> def = std::nullopt, bool required = false) {
    F f;
    f.key = key;
    f.type = "number";
    f.doc = doc;
    f.min = lo;
    f.max = hi;
    if (def) f.def = Json(*def);
    f.required = required;
    return f;
}
F integer(const char* key, const char* doc, double lo, double hi, std::optional<double> def = std::nullopt) {
    F f = num(key, doc, lo, hi, def);
    f.type = "integer";
    if (def) f.def = Json(std::int64_t(*def));
    return f;
}
F boolean(const char* key, const char* doc, bool def) {
    F f;
    f.key = key;
    f.type = "boolean";
    f.doc = doc;
    f.def = Json(def);
    return f;
}
F choice(const char* key, const char* doc, std::vector<std::string> choices, std::optional<std::string> def = std::nullopt, bool required = false) {
    F f;
    f.key = key;
    f.type = "string";
    f.doc = doc;
    f.choices = std::move(choices);
    if (def) f.def = Json(*def);
    f.required = required;
    return f;
}
F text(const char* key, const char* doc, const char* type = "string", bool required = false) {
    F f;
    f.key = key;
    f.type = type;
    f.doc = doc;
    f.required = required;
    return f;
}

const std::vector<std::string> kFadeCurves = {"linear", "equalPower", "smooth", "exponential", "logarithmic"};
const std::vector<std::string> kBandTypes = {"lowShelf", "highShelf", "peak", "lowPass", "highPass"};

std::vector<AudioStepInfo> make_catalog() {
    std::vector<AudioStepInfo> c;
    c.push_back({"trim",
                 "Cuts the sound to a part: from `start` to `end` (or `length` after `start`), in seconds. With `auto` it also removes the silence at both ends: everything quieter than "
                 "`thresholdDb` before the first and after the last loud sample, keeping `padding` seconds of it. Use it first, so later steps and the loop work on the sound itself.",
                 {num("start", "Seconds cut from the beginning (default 0).", 0, 3600), num("end", "Seconds where the sound ends (default: its end). Not with `length`.", 0, 3600),
                  num("length", "Seconds to keep from `start`. Not with `end`.", 0.001, 3600), boolean("auto", "Also trim the silence at the start and the end.", false),
                  num("thresholdDb", "auto: samples below this level (dBFS) count as silence.", -120, 0, -50.0), num("padding", "auto: seconds of silence kept at each end.", 0, 5, 0.01)}});
    c.push_back({"fade",
                 "Fades the start in and/or the end out over `in` / `out` seconds. `curve` shapes it: linear, equalPower (a quarter sine: constant loudness when two sounds cross), smooth (a half cosine: S-shaped), "
                 "exponential (slow start: x squared), logarithmic (fast start). A fade out of a few milliseconds removes the click at the end of a cut.",
                 {num("in", "Seconds of fade in at the start.", 0, 60, 0.0), num("out", "Seconds of fade out at the end.", 0, 60, 0.0),
                  choice("curve", "The shape of the fade.", kFadeCurves, "linear")}});
    c.push_back({"normalize",
                 "Sets the level: `mode` peak makes the loudest sample reach `target` dBFS (default -1); `mode` lufs makes the integrated loudness (BS.1770, the measure assets.check_mix uses) reach `target` LUFS (default -16) "
                 "but never lets the peak pass `ceilingDb`. Put it last, or after the steps that change the level.",
                 {choice("mode", "peak or lufs.", {"peak", "lufs"}, "peak"), num("target", "dBFS (peak) or LUFS (lufs). Default -1 for peak, -16 for lufs.", -70, 0),
                  num("ceilingDb", "lufs: the loudest sample stays under this (dBFS).", -40, 0, -1.0)}});
    c.push_back({"gain", "Multiplies the level by `db` decibels (negative is quieter).", {num("db", "Decibels, -60 to 60.", -60, 60, std::nullopt, true)}});
    c.push_back({"pitch",
                 "Moves the pitch by `semitones` and keeps the duration (a time stretch and a resample, both written for this engine). Good to about +/-7 semitones for sound effects; beyond, voices and tones start to sound processed.",
                 {num("semitones", "Semitones, -24 to 24 (12 is an octave up).", -24, 24, std::nullopt, true)}});
    c.push_back({"stretch",
                 "Changes the duration and keeps the pitch (WSOLA). `factor` multiplies the length (2 is twice as long) or `seconds` sets the length. Noise and tones stretch well; sharp transients smear a little at large factors.",
                 {num("factor", "Length multiplier, 0.25 to 4. Not with `seconds`.", 0.25, 4), num("seconds", "The new length in seconds. Not with `factor`.", 0.02, 120)}});
    c.push_back({"speed", "Plays the sound `factor` times as fast, so pitch and duration move together like a tape (2: half as long, an octave up).",
                 {num("factor", "Speed, 0.25 to 4.", 0.25, 4, std::nullopt, true)}});
    {
        F bands = text("bands", "1 to 8 bands, applied in order. Each is {\"type\": lowShelf|highShelf|peak|lowPass|highPass, \"freq\": Hz, \"gainDb\": dB (shelf, peak), \"q\": 0.1-18}.", "bands", true);
        c.push_back({"eq", "An equalizer: low and high shelves, peaking bands and 12 dB/octave low-pass and high-pass filters (RBJ biquads).", {bands}});
    }
    c.push_back({"compressor",
                 "Reduces the dynamic range: above `thresholdDb` the level rises only 1 dB for every `ratio` dB. `attack` and `release` (seconds) say how fast the gain follows, `kneeDb` softens the corner, `makeupDb` "
                 "brings the level back up. The detector looks at the loudest channel, so a stereo image does not shift.",
                 {num("thresholdDb", "Level above which the compressor acts, dBFS.", -80, 0, -18.0), num("ratio", "dB in for 1 dB out above the threshold (1 = off, 100 = limiter).", 1, 100, 4.0),
                  num("attack", "Seconds to clamp down.", 0.0001, 1, 0.005), num("release", "Seconds to let go.", 0.005, 5, 0.1),
                  num("kneeDb", "Width of the soft knee in dB (0 = hard).", 0, 24, 0.0), num("makeupDb", "Gain added after compressing.", -24, 48, 0.0)}});
    c.push_back({"reverb",
                 "Adds a room: the synth's reverb (eight damped combs and four all-passes). The sound is extended by `tail` seconds so the reverb can die away.",
                 {num("mix", "Level of the wet signal added to the dry one.", 0, 1, 0.3), num("decay", "Seconds the room rings (RT60).", 0.1, 10, 1.5),
                  num("damping", "How fast high frequencies die: 0 bright, 1 dull.", 0, 1, 0.5), num("size", "Scales the delay lines: 0.25 small room, 4 hall.", 0.25, 4, 1.0),
                  num("preDelay", "Seconds before the reverb starts.", 0, 0.5, 0.0), num("tail", "Seconds added after the sound (default: decay, at most 5).", 0, 30)}});
    c.push_back({"delay",
                 "An echo: the synth's feedback delay. The sound is extended by `tail` seconds so the repeats can die away.",
                 {num("time", "Seconds between repeats.", 0.001, 2, 0.25), num("feedback", "Share of each repeat fed back (0.95 at most).", 0, 0.95, 0.4),
                  num("mix", "Level of the echoes added to the dry sound.", 0, 1, 0.4), num("tone", "Low-pass in the feedback loop in Hz, 0 = off (darker repeats).", 0, 20000, 0.0),
                  num("tail", "Seconds added after the sound (default: until the repeats are 60 dB down, at most 8 repeats).", 0, 30)}});
    c.push_back({"reverse", "Plays the sound backwards (a reverse cymbal, a suck-in before a hit).", {}});
    c.push_back({"layer",
                 "Mixes another sound over this one: `source` is a WAV/OGG, an .sfx.json patch or another .audio.json. It starts `offset` seconds in, at `gainDb`, optionally moved by `semitones`. "
                 "If it ends later than the sound, the sound grows. A mono layer on a stereo sound plays on both sides.",
                 {text("source", "Project path of the sound to mix in.", "path", true), num("offset", "Seconds after the start where the layer begins.", 0, 120, 0.0),
                  num("gainDb", "Level of the layer.", -60, 24, 0.0), num("semitones", "Pitch of the layer (duration kept).", -24, 24, 0.0),
                  integer("seed", "An .sfx.json layer: added to the patch's seed (another take of its noise).", 0, 1e15, 0.0), text("note", "An .sfx.json layer: transpose the patch to this note, e.g. \"C4\".")}});
    c.push_back({"loop",
                 "Makes the sound loop without a seam. The part from `start` to `end` is the loop body; its last `crossfade` seconds are blended into its first ones, so when playback wraps from the end to the "
                 "start the wave carries on. Whatever is before `start` is kept as an intro that plays once; whatever is after `end` is dropped. The loop points are written to the baked file's import settings "
                 "(loopStart, loopEnd in assets.json), which AudioSource, audio.play and audio.music honour with loop on. Only gain and normalize may follow a loop step.",
                 {num("start", "Seconds where the loop body begins (default 0).", 0, 3600, 0.0), num("end", "Seconds where the loop body ends (default: the end of the sound).", 0, 3600),
                  num("crossfade", "Seconds blended over the seam; at most half the body.", 0.001, 10, 0.05), choice("curve", "equalPower suits unrelated material, linear suits the same wave.", {"equalPower", "linear"}, "equalPower")}});
    c.push_back({"granular",
                 "Replaces the sound by a texture made of tiny grains of it (a rain from a click, a swarm from a vowel): each grain is `grainSize` seconds of the sound, Hann-windowed, and `density` grains start per "
                 "second. The read position moves through the sound (see `scan`) with a random offset (`jitter`), each grain's pitch is moved up to +/-`pitchSpread` semitones. Seeded, so the same step always "
                 "makes the same texture.",
                 {num("length", "Seconds of texture to make.", 0.05, 120, std::nullopt, true), num("grainSize", "Seconds per grain.", 0.005, 1, 0.06), num("density", "Grains started per second.", 1, 500, 40.0),
                  num("jitter", "Random offset of each grain's read position, as a share of the sound, up to half of it either way (0 = none, 1 = up to half the sound before or after the scan position).", 0, 1, 0.2),
                  num("pitchSpread", "Each grain is moved by a random amount up to this many semitones either way.", 0, 24, 0.0),
                  num("scan", "How much the read position moves through the sound over the texture: 1 once from start to end, 0 stays in the middle.", 0, 1, 1.0),
                  num("start", "Seconds where the part of the sound to read from begins.", 0, 3600, 0.0), num("end", "Seconds where it ends (default: the end of the sound).", 0, 3600),
                  integer("seed", "Another seed is another texture.", 0, 1e15, 0.0)}});
    return c;
}

std::string join_names(const std::vector<std::string>& names) {
    std::string out;
    for (const std::string& n : names) out += (out.empty() ? "\"" : ", \"") + n + "\"";
    return out;
}

struct Parser {
    std::vector<AudioDocIssue> issues;

    void err(const std::string& pointer, std::string message, std::string hint) { issues.push_back({pointer, std::move(message), std::move(hint)}); }

    void unknown_keys(const Json& obj, const std::string& pointer, const std::vector<std::string>& allowed, const std::string& what) {
        for (auto it = obj.begin(); it != obj.end(); ++it) {
            const std::string& key = it.key();
            if (std::find(allowed.begin(), allowed.end(), key) != allowed.end()) continue;
            err(pointer + "/" + key, "unknown key `" + key + "` in " + what, did_you_mean(key, allowed));
        }
    }

    // Reads one field of a step into `out` (default when absent); reports a wrong one.
    void field(const Json& obj, const std::string& pointer, const AudioFieldInfo& f, Json& out) {
        auto it = obj.find(f.key);
        const std::string where = pointer + "/" + f.key;
        if (it == obj.end()) {
            if (f.def) out[f.key] = *f.def;
            else if (f.required) err(pointer, "missing `" + f.key + "`", f.doc);
            return;
        }
        const Json& v = *it;
        if (f.type == "number" || f.type == "integer") {
            if (!v.is_number() || (f.type == "integer" && !v.is_number_integer())) {
                err(where, f.key + " must be " + (f.type == "integer" ? "a whole number" : "a number") + ", got " + describe_json_value(v), f.doc);
                return;
            }
            const double d = v.get<double>();
            if (!std::isfinite(d) || d < *f.min || d > *f.max) {
                err(where, std::format("{} is {}, outside {} to {}", f.key, d, *f.min, *f.max), f.doc);
                return;
            }
            out[f.key] = v;
        } else if (f.type == "boolean") {
            if (!v.is_boolean()) {
                err(where, f.key + " must be true or false, got " + describe_json_value(v), "Write true or false.");
                return;
            }
            out[f.key] = v;
        } else if (f.type == "string") {
            if (!v.is_string()) {
                err(where, f.key + " must be " + (f.choices.empty() ? "text" : "one of " + join_names(f.choices)) + ", got " + describe_json_value(v), f.doc);
                return;
            }
            const std::string s = v.get<std::string>();
            if (!f.choices.empty() && std::find(f.choices.begin(), f.choices.end(), s) == f.choices.end()) {
                err(where, "unknown " + f.key + " \"" + s + "\"", did_you_mean(s, f.choices) + " Options: " + join_names(f.choices) + ".");
                return;
            }
            out[f.key] = v;
        } else if (f.type == "path") {
            if (!v.is_string() || v.get<std::string>().empty()) {
                err(where, f.key + " must be a project path such as \"assets/raw/door.wav\", got " + describe_json_value(v), f.doc);
                return;
            }
            out[f.key] = v;
        }
    }

    void bands(const Json& obj, const std::string& pointer, Json& out) {
        auto it = obj.find("bands");
        if (it == obj.end()) {
            err(pointer, "an eq step needs `bands`", "Write \"bands\": [{\"type\": \"highShelf\", \"freq\": 6000, \"gainDb\": -4}] (types: " + join_names(kBandTypes) + ").");
            return;
        }
        const std::string where = pointer + "/bands";
        if (!it->is_array() || it->empty() || it->size() > 8) {
            err(where, "`bands` must be a list of 1 to 8 bands, got " + describe_json_value(*it), "Each band is {\"type\": \"peak\", \"freq\": 1000, \"gainDb\": 3, \"q\": 1}.");
            return;
        }
        Json list = Json::array();
        for (std::size_t i = 0; i < it->size(); ++i) {
            const Json& b = (*it)[i];
            const std::string bp = where + "/" + std::to_string(i);
            if (!b.is_object()) {
                err(bp, "a band must be an object, got " + describe_json_value(b), "Write {\"type\": \"peak\", \"freq\": 1000, \"gainDb\": 3, \"q\": 1}.");
                continue;
            }
            unknown_keys(b, bp, {"type", "freq", "gainDb", "q"}, "an eq band");
            Json band = Json::object();
            field(b, bp, choice("type", "The band type.", kBandTypes, std::nullopt, true), band);
            if (!b.contains("type")) err(bp, "missing `type`", "One of " + join_names(kBandTypes) + ".");
            field(b, bp, num("freq", "Centre or corner frequency in Hz.", 20, 20000, std::nullopt, true), band);
            field(b, bp, num("gainDb", "Boost or cut in dB (shelf and peak).", -24, 24, 0.0), band);
            field(b, bp, num("q", "Width: 0.707 is flat for a shelf, higher is narrower.", 0.1, 18, 0.707), band);
            list.push_back(std::move(band));
        }
        out["bands"] = std::move(list);
    }

    // ---- sources ----

    bool source(const Json& v, const std::string& pointer, AudioSourceRef& out) {
        const std::string example = "\"assets/raw/door.wav\", \"assets/audio/laser.sfx.json\" or {\"path\": \"assets/audio/laser.sfx.json\", \"note\": \"C4\"}";
        const Json* path = &v;
        if (v.is_object()) {
            unknown_keys(v, pointer, {"path", "seed", "note"}, "a source");
            auto p = v.find("path");
            if (p == v.end()) {
                err(pointer, "the source object has no `path`", "Write " + example + ".");
                return false;
            }
            path = &*p;
            if (auto s = v.find("seed"); s != v.end()) {
                if (!s->is_number_integer() || s->get<long long>() < 0) err(pointer + "/seed", "seed must be a whole number, 0 or more, got " + describe_json_value(*s), "It is added to the patch's seed: another take of its noise.");
                else out.seed = s->get<std::uint64_t>();
            }
            if (auto n = v.find("note"); n != v.end()) {
                std::optional<double> hz = n->is_string() ? sfx_note_hz(n->get<std::string>()) : std::nullopt;
                if (!hz) err(pointer + "/note", "note must be a name like \"A4\", \"C#3\" or \"Bb2\", got " + describe_json_value(*n), "It transposes an .sfx.json source so its root pitch becomes this note.");
                else {
                    out.hz = hz;
                    out.note = n->get<std::string>();
                }
            }
        }
        if (!path->is_string() || path->get<std::string>().empty()) {
            err(v.is_object() ? pointer + "/path" : pointer, "the source must be a project path, got " + describe_json_value(*path), "Write " + example + ".");
            return false;
        }
        out.path = path->get<std::string>();
        const std::string ext = to_lower(fs::extension(out.path));
        const std::string lower = to_lower(out.path);
        const bool known = ends_with(lower, ".sfx.json") || ends_with(lower, kAudioDocSuffix) || ext == ".wav" || ext == ".ogg" || ext == ".mp3" || ext == ".qoa";
        if (!known) {
            err(v.is_object() ? pointer + "/path" : pointer, "'" + out.path + "' is not a sound this format reads", "Sources are .wav, .ogg, .mp3, .qoa files, .sfx.json sound patches and .audio.json documents.");
            return false;
        }
        return true;
    }

    // ---- steps ----

    void step(const Json& s, std::size_t index, std::vector<AudioStep>& out) {
        const std::string pointer = "/steps/" + std::to_string(index);
        if (!s.is_object()) {
            err(pointer, "a step must be an object, got " + describe_json_value(s), "Write {\"type\": \"fade\", \"out\": 0.05}.");
            return;
        }
        std::vector<std::string> types;
        for (const AudioStepInfo& t : audio_step_types()) types.push_back(t.type);
        auto typeIt = s.find("type");
        if (typeIt == s.end() || !typeIt->is_string()) {
            err(pointer + (typeIt == s.end() ? "" : "/type"), typeIt == s.end() ? "the step has no `type`" : "`type` must be text, got " + describe_json_value(*typeIt),
                "Step types: " + join_names(types) + ".");
            return;
        }
        const std::string type = typeIt->get<std::string>();
        const auto info = std::find_if(audio_step_types().begin(), audio_step_types().end(), [&](const AudioStepInfo& t) { return t.type == type; });
        if (info == audio_step_types().end()) {
            err(pointer + "/type", "unknown step type \"" + type + "\"", did_you_mean(type, types) + " Step types: " + join_names(types) + ".");
            return;
        }
        std::vector<std::string> allowed = {"type", "enabled", "doc"};
        for (const AudioFieldInfo& f : info->fields) allowed.push_back(f.key);
        unknown_keys(s, pointer, allowed, "a " + type + " step");
        AudioStep step;
        step.type = type;
        step.params = Json::object();
        for (const AudioFieldInfo& f : info->fields) {
            if (f.type == "bands") bands(s, pointer, step.params);
            else field(s, pointer, f, step.params);
        }
        if (auto e = s.find("enabled"); e != s.end()) {
            if (!e->is_boolean()) err(pointer + "/enabled", "enabled must be true or false, got " + describe_json_value(*e), "false skips the step without deleting it.");
            else step.params["enabled"] = *e;
        }
        if (auto d = s.find("doc"); d != s.end()) {
            if (!d->is_string()) err(pointer + "/doc", "doc must be text, got " + describe_json_value(*d), "A note on why the step is there.");
            else step.params["doc"] = *d;
        }
        crosscheck(step, pointer, s);
        out.push_back(std::move(step));
    }

    static double get(const Json& p, const char* key, double fallback) { return p.contains(key) && p[key].is_number() ? p[key].get<double>() : fallback; }

    void crosscheck(const AudioStep& st, const std::string& pointer, const Json& raw) {
        const Json& p = st.params;
        const std::string& t = st.type;
        if (t == "trim") {
            if (p.contains("end") && p.contains("length")) err(pointer + "/length", "`end` and `length` both say where the trim stops", "Keep one: `end` is a time, `length` is a duration after `start`.");
            if (p.contains("end") && get(p, "end", 0) <= get(p, "start", 0)) err(pointer + "/end", "`end` is not after `start`", "Trim keeps start..end, so end must be larger.");
            if (!p.contains("start") && !p.contains("end") && !p.contains("length") && !p.value("auto", false))
                err(pointer, "this trim does nothing", "Give `start`, `end` or `length` (seconds), or \"auto\": true to cut the silence at the ends.");
        } else if (t == "fade") {
            if (get(p, "in", 0) <= 0 && get(p, "out", 0) <= 0) err(pointer, "this fade does nothing: `in` and `out` are both 0", "Give `in` and/or `out` in seconds, e.g. \"out\": 0.05.");
        } else if (t == "stretch") {
            if (p.contains("factor") == p.contains("seconds"))
                err(pointer, p.contains("factor") ? "`factor` and `seconds` both set the new length" : "a stretch step needs `factor` or `seconds`", "Write \"factor\": 1.5 (50% longer) or \"seconds\": 2.");
        } else if (t == "loop") {
            if (p.contains("end") && get(p, "end", 0) <= get(p, "start", 0)) err(pointer + "/end", "`end` is not after `start`", "The loop body runs from start to end; leave `end` out to loop to the end of the sound.");
        } else if (t == "eq" || t == "layer") {
            (void)raw;
        }
    }
};

}  // namespace

const std::vector<AudioStepInfo>& audio_step_types() {
    static const std::vector<AudioStepInfo> catalog = make_catalog();
    return catalog;
}

Result<AudioDoc> parse_audio_doc(const Json& json, std::string_view file, std::vector<AudioDocIssue>* issuesOut) {
    Parser p;
    AudioDoc doc;
    const std::string where = file.empty() ? std::string("audio document") : std::string(file);
    auto done = [&]() -> Result<AudioDoc> {
        if (issuesOut) *issuesOut = p.issues;
        if (p.issues.empty()) return doc;
        const AudioDocIssue& first = p.issues.front();
        std::string message = where + (first.pointer.empty() ? std::string() : " " + first.pointer) + ": " + first.message;
        if (p.issues.size() > 1) message += std::format(" (and {} more problem{})", p.issues.size() - 1, p.issues.size() == 2 ? "" : "s");
        return make_error(message, first.hint);
    };
    if (!json.is_object()) {
        p.err("", "an audio document must be a JSON object, got " + describe_json_value(json), "Start from {\"format\": \"factoria.audio/1\", \"source\": \"assets/raw/door.wav\", \"steps\": []} (schemas/audio.schema.json).");
        return done();
    }
    p.unknown_keys(json, "", {"$schema", "format", "doc", "source", "seed", "output", "steps"}, "an audio document");
    if (auto f = json.find("format"); f == json.end() || !f->is_string() || f->get<std::string>() != kAudioDocFormat)
        p.err("/format", f == json.end() ? "missing `format`" : "format must be \"factoria.audio/1\", got " + describe_json_value(*f), "Write \"format\": \"factoria.audio/1\".");
    if (auto d = json.find("doc"); d != json.end()) {
        if (!d->is_string()) p.err("/doc", "doc must be text, got " + describe_json_value(*d), "What the sound is and where it came from.");
        else doc.doc = d->get<std::string>();
    }
    if (auto s = json.find("source"); s == json.end())
        p.err("", "missing `source`", "Name the sound to start from: \"source\": \"assets/raw/door.wav\" (or an .sfx.json patch, or another .audio.json).");
    else p.source(*s, "/source", doc.source);
    if (auto s = json.find("seed"); s != json.end()) {
        if (!s->is_number_integer() || s->get<long long>() < 0) p.err("/seed", "seed must be a whole number, 0 or more, got " + describe_json_value(*s), "It picks the take of every random step (granular, an .sfx.json source).");
        else doc.seed = s->get<std::uint64_t>();
    }
    if (auto o = json.find("output"); o != json.end()) {
        if (!o->is_object()) p.err("/output", "output must be an object, got " + describe_json_value(*o), "Write {\"format\": \"ogg\", \"quality\": 0.5}.");
        else {
            p.unknown_keys(*o, "/output", {"format", "channels", "quality", "path"}, "output");
            Json out = Json::object();
            p.field(*o, "/output", choice("format", "wav or ogg.", {"wav", "ogg"}, "wav"), out);
            p.field(*o, "/output", choice("channels", "source or mono.", {"source", "mono"}, "source"), out);
            p.field(*o, "/output", num("quality", "Ogg quality 0..1.", 0, 1, 0.5), out);
            doc.output.format = out.value("format", "wav");
            doc.output.channels = out.value("channels", "source");
            doc.output.quality = out.value("quality", 0.5);
            if (auto path = o->find("path"); path != o->end()) {
                if (!path->is_string() || path->get<std::string>().empty() || !ends_with(to_lower(path->get<std::string>()), doc.output.format == "ogg" ? ".ogg" : ".wav"))
                    p.err("/output/path", "path must be a project path ending in ." + doc.output.format + ", got " + describe_json_value(*path), "Example: \"assets/audio/door_clean." + doc.output.format + "\". Leave it out to bake next to the document.");
                else doc.output.path = path->get<std::string>();
            }
        }
    }
    if (auto s = json.find("steps"); s == json.end()) {
        p.err("", "missing `steps`", "Write \"steps\": [] for a document that only re-exports its source, or add steps such as {\"type\": \"fade\", \"out\": 0.05}.");
    } else if (!s->is_array()) {
        p.err("/steps", "steps must be a list, got " + describe_json_value(*s), "Each step is an object with a `type`.");
    } else if (s->size() > kAudioDocMaxSteps) {
        p.err("/steps", std::format("{} steps is more than the {} a document may have", s->size(), kAudioDocMaxSteps), "Split the chain: make one document the source of another.");
    } else {
        for (std::size_t i = 0; i < s->size(); ++i) p.step((*s)[i], i, doc.steps);
        // After a loop step the seam is made: only a level change may follow, anything else would break it or move the loop points.
        bool looped = false;
        for (std::size_t i = 0; p.issues.empty() && i < doc.steps.size(); ++i) {
            const AudioStep& st = doc.steps[i];
            if (st.params.value("enabled", true) == false) continue;
            if (looped && st.type != "gain" && st.type != "normalize")
                p.err("/steps/" + std::to_string(i), "a " + st.type + " step after a loop step would break the seam", "Move it before the loop step; only gain and normalize may follow it.");
            if (st.type == "loop") looped = true;
        }
    }
    return done();
}

Result<AudioDoc> load_audio_doc(std::string_view path, std::vector<AudioDocIssue>* issues) {
    auto text = fs::read_text(path);
    if (!text)
        return make_error(std::string(path) + ": cannot read the audio document: " + text.error().message,
                          text.error().hint.empty() ? "Audio documents are *.audio.json files; audio.create writes a starting point." : text.error().hint);
    auto json = parse_json(*text, path);
    if (!json) return json.error();
    return parse_audio_doc(*json, path, issues);
}

}  // namespace fa
