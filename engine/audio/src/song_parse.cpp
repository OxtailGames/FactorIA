// Reads `*.song.json` into a SongDoc (fa/audio/song.h) and unrolls its arrangement into a timeline. Every problem is reported with its
// JSON pointer (and line and column inside note text), what is wrong and how to fix it; names get "did you mean".
#include <algorithm>
#include <cctype>
#include <format>
#include <initializer_list>

#include "fa/audio/song.h"
#include "fa/audio/song_instruments.h"
#include "fa/audio/song_theory.h"
#include "fa/audio/sfx.h"
#include "fa/core/fs.h"
#include "fa/core/strings.h"

namespace fa {

namespace {

constexpr std::size_t kMaxPatternsPerTrack = 64;
constexpr double kMaxBeat = 100000.0;
constexpr std::size_t kMaxEffects = 8;
constexpr std::size_t kSongMaxBuses = 8;

std::string join(const std::vector<std::string>& names, std::size_t limit = 12) {
    std::string out;
    for (std::size_t i = 0; i < names.size() && i < limit; ++i) out += (out.empty() ? "" : ", ") + names[i];
    if (names.size() > limit) out += ", ...";
    return out;
}

bool valid_name(const std::string& n) {
    if (n.empty() || n.size() > 32) return false;
    return std::all_of(n.begin(), n.end(), [](char c) { return std::isalnum(static_cast<unsigned char>(c)) || c == '_' || c == '-'; });
}

std::string escape_pointer(const std::string& s) {
    std::string out;
    for (char c : s) out += c == '~' ? "~0" : c == '/' ? "~1" : std::string(1, c);
    return out;
}

struct Parser {
    std::vector<SongIssue> issues;

    void err(const std::string& pointer, std::string message, std::string hint) {
        hint.erase(0, hint.find_first_not_of(' '));  // "did you mean" is empty when nothing is close, and the sentence after it starts with a space
        issues.push_back({pointer, std::move(message), std::move(hint), 0, 0});
    }

    void unknown_keys(const Json& obj, const std::string& pointer, std::initializer_list<const char*> allowed, const std::string& what) {
        std::vector<std::string> names;
        for (const char* a : allowed) names.emplace_back(a);
        for (auto it = obj.begin(); it != obj.end(); ++it) {
            if (std::find(names.begin(), names.end(), it.key()) != names.end()) continue;
            err(pointer + "/" + escape_pointer(it.key()), "unknown key `" + it.key() + "` in " + what, did_you_mean(it.key(), names));
        }
    }

    bool number(const Json& obj, const std::string& pointer, const char* key, double& out, double lo, double hi, const std::string& hint) {
        auto it = obj.find(key);
        if (it == obj.end()) return false;
        const std::string where = pointer + "/" + key;
        if (!it->is_number()) {
            err(where, std::string(key) + " must be a number, got " + describe_json_value(*it), hint);
            return false;
        }
        const double v = it->get<double>();
        if (!(v >= lo && v <= hi)) {
            err(where, std::format("{} is {:g}, outside {:g} to {:g}", key, v, lo, hi), hint);
            return false;
        }
        out = v;
        return true;
    }

    bool text(const Json& obj, const std::string& pointer, const char* key, std::string& out, const std::string& hint) {
        auto it = obj.find(key);
        if (it == obj.end()) return false;
        if (!it->is_string()) {
            err(pointer + "/" + key, std::string(key) + " must be text, got " + describe_json_value(*it), hint);
            return false;
        }
        out = it->get<std::string>();
        return true;
    }

    // ---- automation ------------------------------------------------------------------------------------------------
    void automation(const Json& j, const std::string& pointer, bool master, std::vector<SongAutomation>& out) {
        if (!j.is_array()) {
            err(pointer, "automation must be a list of lanes, got " + describe_json_value(j),
                "Write [{\"param\": \"volume\", \"points\": [[0, 0.2], [16, 1]]}]: beats counted in quarter notes from the start of the song.");
            return;
        }
        std::vector<std::string> params = master ? std::vector<std::string>{"volume", "filter"} : std::vector<std::string>{"volume", "pan", "filter", "macro.<name>"};
        std::vector<std::string> macroNames;
        for (const SfxMacroInfo& m : sfx_macros()) macroNames.push_back(m.name);
        for (std::size_t i = 0; i < j.size(); ++i) {
            const std::string at = pointer + "/" + std::to_string(i);
            const Json& lane = j[i];
            if (!lane.is_object()) {
                err(at, "an automation lane must be an object, got " + describe_json_value(lane), "Write {\"param\": \"volume\", \"points\": [[0, 0.2], [16, 1]]}.");
                continue;
            }
            unknown_keys(lane, at, {"param", "points", "curve"}, "an automation lane");
            SongAutomation a;
            std::string param;
            if (!text(lane, at, "param", param, "One of: " + join(params) + ".") || param.empty()) {
                if (lane.find("param") == lane.end()) err(at, "an automation lane needs a `param`", "One of: " + join(params) + ".");
                continue;
            }
            double lo = 0, hi = 1;
            bool known = true;
            if (param == "volume") { lo = 0; hi = 2; }
            else if (param == "filter") { lo = 40; hi = 20000; }
            else if (param == "pan" && !master) { lo = -1; hi = 1; }
            else if (param.rfind("macro.", 0) == 0 && !master) {
                lo = -1; hi = 1;
                const std::string name = param.substr(6);
                if (std::find(macroNames.begin(), macroNames.end(), name) == macroNames.end()) {
                    err(at + "/param", "unknown macro `" + name + "` in `" + param + "`", did_you_mean(name, macroNames) + " Built-in macros: " + join(macroNames) + ".");
                    continue;
                }
            } else known = false;
            if (!known) {
                err(at + "/param", "unknown automation param `" + param + "`" + (master ? " (the song's own lanes are volume and filter)" : ""), did_you_mean(param, params) + " Params: " + join(params) + ".");
                continue;
            }
            a.param = param;
            if (auto c = lane.find("curve"); c != lane.end()) {
                const std::string cv = c->is_string() ? c->get<std::string>() : std::string();
                if (cv == "linear" || cv == "step" || cv == "smooth") a.curve = cv;
                else err(at + "/curve", "curve must be \"linear\", \"step\" or \"smooth\", got " + describe_json_value(*c), "linear ramps between points, step jumps at each point, smooth eases.");
            }
            auto pts = lane.find("points");
            if (pts == lane.end() || !pts->is_array() || pts->empty() || pts->size() > 2000) {
                err(at + "/points", pts == lane.end() ? "an automation lane needs `points`" : "points must be a list of 1 to 2000 [beat, value] pairs, got " + describe_json_value(*pts),
                    "Write \"points\": [[0, 0.2], [16, 1]]: the beat (quarter notes from the song start) and the value.");
                continue;
            }
            double lastBeat = -1;
            for (std::size_t k = 0; k < pts->size(); ++k) {
                const Json& p = (*pts)[k];
                const std::string pat = at + "/points/" + std::to_string(k);
                if (!p.is_array() || p.size() != 2 || !p[0].is_number() || !p[1].is_number()) {
                    err(pat, "a point must be [beat, value], got " + describe_json_value(p), "Write [8, 0.5]: at beat 8 the value is 0.5.");
                    continue;
                }
                const double beat = p[0].get<double>(), value = p[1].get<double>();
                if (!(beat >= 0 && beat <= kMaxBeat)) { err(pat + "/0", std::format("beat {:g} is outside 0 to {:g}", beat, kMaxBeat), "Beats count quarter notes from the start of the song."); continue; }
                if (beat < lastBeat) { err(pat + "/0", std::format("beat {:g} comes before the previous point at {:g}", beat, lastBeat), "List the points in time order."); continue; }
                if (!(value >= lo && value <= hi)) { err(pat + "/1", std::format("{} value {:g} is outside {:g} to {:g}", param, value, lo, hi), "Keep the value in range."); continue; }
                lastBeat = beat;
                a.points.emplace_back(beat, value);
            }
            out.push_back(std::move(a));
        }
    }

    bool boolean(const Json& obj, const std::string& pointer, const char* key, bool& out, const std::string& hint) {
        auto it = obj.find(key);
        if (it == obj.end()) return false;
        if (!it->is_boolean()) {
            err(pointer + "/" + key, std::string(key) + " must be true or false, got " + describe_json_value(*it), hint);
            return false;
        }
        out = it->get<bool>();
        return true;
    }

    // ---- effects (the insert chain of a track, a bus or the master) --------------------------------------------------
    void effects(const Json& j, const std::string& pointer, std::vector<AudioStep>& out) {
        static const std::string kEffects = "eq, filter, compressor, distortion, bitcrush, delay, reverb";
        if (!j.is_array() || j.size() > kMaxEffects) {
            err(pointer, "effects must be a list of at most 8 effects, got " + describe_json_value(j),
                "Write [{\"type\": \"eq\", \"bands\": [{\"type\": \"highPass\", \"freq\": 90}]}, {\"type\": \"compressor\"}]: they run in this order. Effect types: " + kEffects + ".");
            return;
        }
        for (std::size_t i = 0; i < j.size(); ++i) {
            const std::string at = pointer + "/" + std::to_string(i);
            if (j[i].is_object()) {
                auto type = j[i].find("type");
                if (type != j[i].end() && type->is_string() && !audio_step_is_effect(type->get<std::string>())) {
                    const std::string t = type->get<std::string>();
                    err(at + "/type", "`" + t + "` is not an effect a mixer can run",
                        did_you_mean(t, std::vector<std::string>{"eq", "filter", "compressor", "distortion", "bitcrush", "delay", "reverb"}) + " Effect types: " + kEffects + ".");
                    continue;
                }
            }
            std::vector<AudioDocIssue> found;
            auto step = parse_audio_step(j[i], at, &found);
            for (const AudioDocIssue& f : found) issues.push_back({f.pointer, f.message, f.hint, 0, 0});
            if (step) out.push_back(std::move(*step));
        }
    }

    // ---- instrument --------------------------------------------------------------------------------------------------
    static bool has_suffix(const std::string& s, const char* suffix) {
        const std::string x = suffix;
        return s.size() > x.size() && s.compare(s.size() - x.size(), x.size(), x) == 0;
    }
    static bool is_soundfont_text(const std::string& s) {
        const std::size_t hash = s.find('#');
        return has_suffix(hash == std::string::npos ? s : s.substr(0, hash), ".sf2");
    }

    // A project file path: relative, forward slashes, no `..` (the renderer reads it through the project's file system).
    void check_project_path(const std::string& pointer, const std::string& path) {
        const bool bad = path.empty() || path[0] == '/' || path.find('\\') != std::string::npos || path.find(':') != std::string::npos || path.find("..") != std::string::npos;
        if (bad) err(pointer, "the file path `" + path + "` is not inside the project", "Use a project-relative path with forward slashes, e.g. assets/audio/piano.sf2.");
    }

    // The tracks' instrument text of a SoundFont: "<path>#<preset name>" or "<path>#<bank>:<program>".
    static std::string soundfont_text(const SongSoundfont& sf) {
        return sf.path + "#" + (sf.presetName.empty() ? std::to_string(sf.bank) + ":" + std::to_string(sf.program) : sf.presetName);
    }

    // "assets/audio/piano.sf2#Grand Piano" (or "#0:5", "#128:0" for a percussion preset, or no '#' for the first preset of bank 0).
    void soundfont_shorthand(const std::string& pointer, const std::string& text, SongTrack& t) {
        const std::size_t hash = text.find('#');
        t.soundfont.path = hash == std::string::npos ? text : text.substr(0, hash);
        check_project_path(pointer, t.soundfont.path);
        const std::string preset = hash == std::string::npos ? std::string() : text.substr(hash + 1);
        const std::size_t colon = preset.find(':');
        bool numeric = colon != std::string::npos && colon > 0 && colon + 1 < preset.size() && preset.size() <= 7;
        for (std::size_t i = 0; numeric && i < preset.size(); ++i)
            if (i != colon && !(preset[i] >= '0' && preset[i] <= '9')) numeric = false;
        if (numeric) {
            t.soundfont.bank = std::stoi(preset.substr(0, colon));
            t.soundfont.program = std::stoi(preset.substr(colon + 1));
            if (t.soundfont.bank > 128 || t.soundfont.program > 127)
                err(pointer, "the preset `" + preset + "` is outside bank 0 to 128 and program 0 to 127", "General MIDI banks are 0 to 127, and 128 holds the percussion kit.");
        } else {
            t.soundfont.presetName = preset;
        }
        t.soundfont.drums = t.soundfont.bank == 128;
        t.drums = t.soundfont.drums;
        t.instrument = soundfont_text(t.soundfont);
    }

    // {"soundfont": "assets/audio/piano.sf2", "preset": "Grand Piano"} or {"soundfont": ..., "preset": 0, "bank": 0} or {"soundfont": ..., "drums": true}
    void soundfont_object(const Json& j, const std::string& pointer, SongTrack& t) {
        unknown_keys(j, pointer, {"soundfont", "preset", "bank", "drums"}, "an instrument");
        const std::string example = "{\"soundfont\": \"assets/audio/piano.sf2\", \"preset\": \"Grand Piano\"}";
        auto sf = j.find("soundfont");
        if (sf == j.end() || !sf->is_string() || !has_suffix(sf->get<std::string>(), ".sf2")) {
            err(pointer + "/soundfont", sf == j.end() ? "an instrument object needs `soundfont`, the project path of an .sf2 file"
                                                      : "soundfont must be the path of an .sf2 file, got " + describe_json_value(*sf),
                "Write " + example + ". The file is an asset the project brings; the engine includes none.");
        } else {
            t.soundfont.path = sf->get<std::string>();
            check_project_path(pointer + "/soundfont", t.soundfont.path);
        }
        bool drums = false;
        boolean(j, pointer, "drums", drums, "true plays the SoundFont's percussion kit (bank 128) with the drum lanes of a grid pattern.");
        int bank = drums ? 128 : 0;
        if (auto b = j.find("bank"); b != j.end()) {
            if (!b->is_number_integer() || b->get<int>() < 0 || b->get<int>() > 128) err(pointer + "/bank", "bank must be a whole number from 0 to 128, got " + describe_json_value(*b), "Melodic presets are in banks 0 to 127 (usually 0); 128 is the percussion kit.");
            else bank = b->get<int>();
        }
        if (drums && bank != 128) err(pointer + "/bank", "a drum SoundFont track uses bank 128, not " + std::to_string(bank), "Remove `bank` (128 is the default with \"drums\": true).");
        t.soundfont.bank = bank;
        if (auto pr = j.find("preset"); pr != j.end()) {
            if (pr->is_string()) {
                t.soundfont.presetName = pr->get<std::string>();
                if (j.find("bank") != j.end()) err(pointer + "/bank", "`bank` goes with a numeric `preset`; a preset name already picks the bank", "Remove `bank`, or write \"preset\": 0 for the program number.");
            } else if (pr->is_number_integer() && pr->get<int>() >= 0 && pr->get<int>() <= 127) {
                t.soundfont.program = pr->get<int>();
            } else {
                err(pointer + "/preset", "preset must be a preset name or a program number 0 to 127, got " + describe_json_value(*pr), "Write \"preset\": \"Grand Piano\" or \"preset\": 0 (music.instrument lists the presets of the file).");
            }
        }
        t.soundfont.drums = bank == 128;
        t.drums = t.soundfont.drums;
        t.instrument = soundfont_text(t.soundfont);
    }

    // Whether a name is acceptable at all; a path is only checked when the project is validated (the file may not exist here).
    bool instrument_name(const std::string& pointer, const std::string& name, bool& drums) {
        drums = false;
        if (song_kit_variant(name)) { drums = true; return true; }
        if (name.rfind("kit:", 0) == 0) {
            std::vector<std::string> kits;
            for (const SongKitInfo& k : song_kits()) kits.push_back(k.instrument);
            err(pointer, "unknown drum kit `" + name + "`", did_you_mean(name, kits) + " Kits: " + join(kits) + ".");
            return false;
        }
        if (name.find('/') != std::string::npos || (name.size() > 9 && name.compare(name.size() - 9, 9, ".sfx.json") == 0)) {
            if (name.size() <= 9 || name.compare(name.size() - 9, 9, ".sfx.json") != 0) {
                err(pointer, "the instrument path `" + name + "` is not a sound patch", "An instrument file ends in .sfx.json: assets/audio/lead.sfx.json (sfx.preset writes one), or .sf2 for a SoundFont.");
                return false;
            }
            check_project_path(pointer, name);
            return true;
        }
        std::vector<std::string> names;
        for (const SongKitInfo& k : song_kits()) names.push_back(k.instrument);
        for (const SongInstrumentInfo& i : song_instruments()) names.push_back(i.name);
        if (std::find(names.begin(), names.end(), name) != names.end()) return true;
        for (const SfxPresetInfo& p : sfx_presets()) {
            if (p.name == name) return true;
            names.push_back(p.name);
        }
        std::string builtin;
        for (const SongInstrumentInfo& i : song_instruments()) builtin += (builtin.empty() ? "" : ", ") + i.name;
        err(pointer, "unknown instrument `" + name + "`",
            did_you_mean(name, names) + " Built-in: kit / kit:electronic / kit:chiptune (drums), " + builtin +
                "; or the path of a sound patch (assets/audio/lead.sfx.json), a SoundFont ({\"soundfont\": \"assets/audio/x.sf2\", \"preset\": \"...\"}), or an sfx preset name. music.instrument lists them.");
        return false;
    }

    void instrument(const Json& inst, const std::string& pointer, SongTrack& t) {
        if (inst.is_object()) {
            soundfont_object(inst, pointer, t);
        } else if (inst.is_string()) {
            t.instrument = inst.get<std::string>();
            if (is_soundfont_text(t.instrument)) soundfont_shorthand(pointer, t.instrument, t);
            else instrument_name(pointer, t.instrument, t.drums);
        } else {
            err(pointer, "instrument must be text or a SoundFont object, got " + describe_json_value(inst),
                "Write \"instrument\": \"pluck\", or {\"soundfont\": \"assets/audio/piano.sf2\", \"preset\": \"Grand Piano\"}.");
        }
    }

    // ---- tracks ------------------------------------------------------------------------------------------------------
    int range_note(const Json& v, const std::string& pointer) {
        if (v.is_number_integer() && v.get<int>() >= 0 && v.get<int>() <= 127) return v.get<int>();
        if (v.is_string()) {
            if (auto m = song_parse_pitch(v.get<std::string>())) return *m;
        }
        err(pointer, "a range end must be a note name such as \"E1\" or a MIDI number 0 to 127, got " + describe_json_value(v), "Write \"range\": [\"E1\", \"G4\"].");
        return -1;
    }

    void track(const std::string& name, const Json& j, const SongMeter& meter, SongTrack& t) {
        const std::string pointer = "/tracks/" + escape_pointer(name);
        t.name = name;
        if (!valid_name(name)) {
            err(pointer, "the track name `" + name + "` must be 1 to 32 letters, digits, - or _", "Rename it, e.g. \"lead\" or \"bass_2\".");
        }
        if (!j.is_object()) {
            err(pointer, "a track must be an object, got " + describe_json_value(j), "Write {\"instrument\": \"pluck\", \"patterns\": {\"a\": \"C4:4 E4 G4 r\"}}.");
            return;
        }
        unknown_keys(j, pointer, {"instrument", "volume", "pan", "mute", "solo", "voices", "effects", "sends", "transpose", "swing", "range", "kit", "patterns", "automation"}, "a track");
        auto inst = j.find("instrument");
        if (inst == j.end()) err(pointer, "the track `" + name + "` has no `instrument`", "Name a built-in instrument (pluck, pad, bass, lead, bell, strings, chiptune, ...; kit for drums; music.instrument lists them), an .sfx.json patch or a SoundFont.");
        else instrument(*inst, pointer + "/instrument", t);
        number(j, pointer, "volume", t.volume, 0.0, 2.0, "Linear gain, 1 = the instrument as designed.");
        number(j, pointer, "pan", t.pan, -1.0, 1.0, "-1 is left, 0 centre, 1 right.");
        boolean(j, pointer, "mute", t.mute, "true silences the track in the mix (the mixer's mute button).");
        boolean(j, pointer, "solo", t.solo, "true plays only the soloed tracks (the mixer's solo button).");
        if (auto v = j.find("voices"); v != j.end()) {
            if (!v->is_number_integer() || v->get<int>() < 0 || v->get<int>() > 64) err(pointer + "/voices", "voices must be a whole number from 0 to 64, got " + describe_json_value(*v), "The most notes held at once; a new note cuts the oldest. 0 uses the instrument's own limit (music.instrument lists it).");
            else t.voices = v->get<int>();
        }
        if (auto e = j.find("effects"); e != j.end()) effects(*e, pointer + "/effects", t.effects);
        if (auto sn = j.find("sends"); sn != j.end()) {
            if (!sn->is_object()) err(pointer + "/sends", "sends must be an object from bus name to level, got " + describe_json_value(*sn), "Write {\"reverb\": 0.3}: the share of the track's sound sent to the bus `reverb` (0 to 2).");
            else for (auto it = sn->begin(); it != sn->end(); ++it) {
                const std::string sp = pointer + "/sends/" + escape_pointer(it.key());
                if (!it->is_number() || !(it->get<double>() >= 0.0 && it->get<double>() <= 2.0)) { err(sp, "a send level is a number from 0 to 2, got " + describe_json_value(*it), "0.3 sends a little, 1 sends as much as the track plays."); continue; }
                t.sends[it.key()] = it->get<double>();
            }
        }
        if (auto tr = j.find("transpose"); tr != j.end()) {
            if (!tr->is_number_integer() || tr->get<int>() < -48 || tr->get<int>() > 48) err(pointer + "/transpose", "transpose must be a whole number of semitones from -48 to 48, got " + describe_json_value(*tr), "12 is an octave up.");
            else t.transpose = tr->get<int>();
        }
        if (auto sw = j.find("swing"); sw != j.end()) {
            double v = 0;
            if (number(j, pointer, "swing", v, 0.0, 1.0, "0 is straight, 1 a full triplet feel.")) t.swing = v;
        }
        if (auto r = j.find("range"); r != j.end()) {
            if (!r->is_array() || r->size() != 2) err(pointer + "/range", "range must be [lowest, highest], got " + describe_json_value(*r), "Write \"range\": [\"E1\", \"G4\"].");
            else {
                const int lo = range_note((*r)[0], pointer + "/range/0"), hi = range_note((*r)[1], pointer + "/range/1");
                if (lo >= 0 && hi >= 0) {
                    if (lo > hi) err(pointer + "/range", "the lowest note is above the highest", "Write the lowest first: [\"E1\", \"G4\"].");
                    else { t.rangeLow = lo; t.rangeHigh = hi; }
                }
            }
        }
        if (auto k = j.find("kit"); k != j.end()) {
            if (!t.drums) err(pointer + "/kit", "`kit` only applies to a drum track (instrument \"kit\")", "Remove it or set \"instrument\": \"kit\".");
            else if (!k->is_object()) err(pointer + "/kit", "kit must be an object from lane to instrument, got " + describe_json_value(*k), "Write {\"kick\": \"assets/audio/my_kick.sfx.json\"}.");
            else {
                std::vector<std::string> lanes;
                for (const SongDrumLane& l : song_drum_lanes()) lanes.push_back(l.name);
                for (auto it = k->begin(); it != k->end(); ++it) {
                    const std::string kp = pointer + "/kit/" + escape_pointer(it.key());
                    if (!it->is_string()) { err(kp, "a kit lane must name a .sfx.json patch, got " + describe_json_value(*it), "Write \"assets/audio/my_kick.sfx.json\"."); continue; }
                    const std::string path = it->get<std::string>();
                    if (path.size() <= 9 || path.compare(path.size() - 9, 9, ".sfx.json") != 0) {
                        err(kp, "`" + path + "` is not a sound patch", "A kit lane is replaced by an .sfx.json file: assets/audio/my_kick.sfx.json.");
                        continue;
                    }
                    t.kit[it.key()] = path;
                    if (std::find(lanes.begin(), lanes.end(), it.key()) == lanes.end() && !valid_name(it.key()))
                        err(kp, "the lane name `" + it.key() + "` must be letters, digits, - or _", "Name an extra lane like \"cowbell\".");
                }
            }
        }
        auto pats = j.find("patterns");
        if (pats == j.end() || !pats->is_object() || pats->empty() || pats->size() > kMaxPatternsPerTrack) {
            err(pointer + "/patterns", pats == j.end() ? "the track `" + name + "` has no `patterns`" : "patterns must be an object of 1 to 64 named patterns, got " + describe_json_value(*pats),
                t.drums ? "Write {\"rock\": {\"grid\": {\"kick\": \"x...x...x...x...\"}}}." : "Write {\"a\": \"C4:4 E4 G4 r\"}: a name and its notes.");
        } else {
            for (auto it = pats->begin(); it != pats->end(); ++it) pattern(name, it.key(), it.value(), meter, t);
        }
        if (auto a = j.find("automation"); a != j.end()) automation(*a, pointer + "/automation", false, t.automation);
    }

    void pattern(const std::string& track, const std::string& name, const Json& j, const SongMeter& meter, SongTrack& t) {
        const std::string pointer = "/tracks/" + escape_pointer(track) + "/patterns/" + escape_pointer(name);
        if (!valid_name(name)) { err(pointer, "the pattern name `" + name + "` must be 1 to 32 letters, digits, - or _", "Rename it, e.g. \"verse\" or \"a\"."); return; }
        if (name == "rest") { err(pointer, "`rest` is reserved in arrangements for a bar of silence", "Name the pattern something else."); return; }
        SongPattern p;
        p.name = name;
        if (t.drums) {
            if (j.is_string()) {
                err(pointer, "a drum track's pattern is a step grid, not note text", "Write {\"grid\": {\"kick\": \"x...x...x...x...\", \"snare\": \"....x.......x...\"}}.");
                return;
            }
            if (song_parse_drum_grid(j, pointer, meter, t.kit, p, issues)) t.patterns.push_back(std::move(p));
            return;
        }
        int declaredBars = 0;
        const Json* notes = &j;
        std::string notesPointer = pointer;
        if (j.is_object()) {
            unknown_keys(j, pointer, {"notes", "bars"}, "a pattern");
            auto n = j.find("notes");
            if (n == j.end()) { err(pointer, "the pattern has no `notes`", "Write {\"notes\": \"C4:4 E4 G4 r\", \"bars\": 2} or just the note text."); return; }
            notes = &*n;
            notesPointer = pointer + "/notes";
            if (auto b = j.find("bars"); b != j.end()) {
                if (!b->is_number_integer() || b->get<int>() < 1 || b->get<int>() > 256) err(pointer + "/bars", "bars must be a whole number from 1 to 256, got " + describe_json_value(*b), "The pattern is padded with silence to this many bars.");
                else declaredBars = b->get<int>();
            }
        }
        if (!notes->is_string()) {
            const bool grid = j.is_object() && j.find("grid") != j.end();
            err(pointer, "a pattern is note text, got " + describe_json_value(*notes),
                grid ? "`grid` patterns are for drum tracks (instrument \"kit\"). A pitched track takes note text such as \"C4:4 E4 G4 r\"." : "Write the notes as text: \"C4:4 E4 G4 r\" (docs/MUSIC.md \"Writing notes\").");
            return;
        }
        if (song_parse_note_text(notes->get<std::string>(), notesPointer, meter, declaredBars, p, issues)) t.patterns.push_back(std::move(p));
    }

    // ---- mixer ---------------------------------------------------------------------------------------------------------
    void mixer(const Json& j, SongMixer& m) {
        const std::string pointer = "/mixer";
        if (!j.is_object()) {
            err(pointer, "mixer must be an object, got " + describe_json_value(j), "Write {\"buses\": {\"reverb\": {\"effects\": [{\"type\": \"reverb\", \"decay\": 1.8}]}}, \"master\": {\"loudness\": \"style\"}}.");
            return;
        }
        unknown_keys(j, pointer, {"buses", "master"}, "the mixer");
        if (auto b = j.find("buses"); b != j.end()) {
            if (!b->is_object() || b->size() > kSongMaxBuses) {
                err(pointer + "/buses", "buses must be an object of at most 8 named buses, got " + describe_json_value(*b),
                    "Write {\"reverb\": {\"effects\": [{\"type\": \"reverb\", \"decay\": 1.8}]}}; tracks send to a bus with \"sends\": {\"reverb\": 0.3}.");
            } else {
                for (auto it = b->begin(); it != b->end(); ++it) {
                    const std::string bp = pointer + "/buses/" + escape_pointer(it.key());
                    SongBus bus;
                    bus.name = it.key();
                    if (!valid_name(bus.name)) err(bp, "the bus name `" + bus.name + "` must be 1 to 32 letters, digits, - or _", "Rename it, e.g. \"reverb\" or \"delay_1\".");
                    if (!it->is_object()) { err(bp, "a bus must be an object, got " + describe_json_value(*it), "Write {\"volume\": 1, \"effects\": [{\"type\": \"reverb\", \"decay\": 1.8}]}."); continue; }
                    unknown_keys(*it, bp, {"volume", "pan", "mute", "effects"}, "a bus");
                    number(*it, bp, "volume", bus.volume, 0.0, 2.0, "Linear gain of the bus's output, 1 = as the effects return it.");
                    number(*it, bp, "pan", bus.pan, -1.0, 1.0, "-1 is left, 0 centre, 1 right: a balance of the bus's stereo output.");
                    boolean(*it, bp, "mute", bus.mute, "true silences the bus (the sends still exist).");
                    if (auto e = it->find("effects"); e != it->end()) effects(*e, bp + "/effects", bus.effects);
                    m.buses.push_back(std::move(bus));
                }
            }
        }
        if (auto mj = j.find("master"); mj != j.end()) {
            const std::string mp = pointer + "/master";
            if (!mj->is_object()) { err(mp, "master must be an object, got " + describe_json_value(*mj), "Write {\"limiter\": true, \"loudness\": \"style\"}."); return; }
            unknown_keys(*mj, mp, {"effects", "limiter", "loudness"}, "the master bus");
            if (auto e = mj->find("effects"); e != mj->end()) effects(*e, mp + "/effects", m.master.effects);
            if (auto l = mj->find("limiter"); l != mj->end()) {
                const std::string lp = mp + "/limiter";
                if (l->is_boolean()) m.master.limiter = l->get<bool>();
                else if (l->is_object()) {
                    unknown_keys(*l, lp, {"ceilingDb", "release"}, "the limiter");
                    m.master.limiter = true;
                    number(*l, lp, "ceilingDb", m.master.ceilingDb, -24.0, 0.0, "The loudest sample stays under this level in dBFS: -1 is the default, -0.3 is closer to full scale.");
                    number(*l, lp, "release", m.master.limiterRelease, 0.005, 2.0, "Seconds the gain takes to come back after a peak: 0.1 is a clean default, 0.02 is tighter.");
                } else err(lp, "limiter must be true, false or {\"ceilingDb\": -1, \"release\": 0.1}, got " + describe_json_value(*l), "false lets the mix peak above full scale (music.check reports it).");
            }
            if (auto l = mj->find("loudness"); l != mj->end()) {
                const std::string lp = mp + "/loudness";
                if (l->is_string() && l->get<std::string>() == "style") m.master.loudness = SongMaster::Loudness::Style;
                else if (l->is_string() && l->get<std::string>() == "off") m.master.loudness = SongMaster::Loudness::Off;
                else if (l->is_number() && l->get<double>() >= -40.0 && l->get<double>() <= -5.0) {
                    m.master.loudness = SongMaster::Loudness::Target;
                    m.master.loudnessLufs = l->get<double>();
                } else err(lp, "loudness must be \"style\", \"off\" or a number of LUFS from -40 to -5, got " + describe_json_value(*l),
                           "\"style\" brings the render to the style guide's music loudness (assets.json, style.audio.loudnessLufs.music), \"off\" leaves the level the mix adds up to, -16 targets -16 LUFS.");
            }
        }
    }

    // The buses sends point at.
    void resolve_sends(const SongDoc& song) {
        std::vector<std::string> names;
        for (const SongBus& b : song.mixer.buses) names.push_back(b.name);
        for (const SongTrack& t : song.tracks)
            for (const auto& send : t.sends)
                if (!song.mixer.find_bus(send.first))
                    err("/tracks/" + escape_pointer(t.name) + "/sends/" + escape_pointer(send.first), "the track `" + t.name + "` sends to the unknown bus `" + send.first + "`",
                        did_you_mean(send.first, names) + (names.empty() ? " The song has no buses: add one under \"mixer\": {\"buses\": {\"" + send.first + "\": {\"effects\": [...]}}}." : " Buses: " + join(names) + "."));
    }

    // ---- sections ----------------------------------------------------------------------------------------------------
    bool entry_text(const std::string& s, const std::string& pointer, std::vector<SongPlayEntry>& out) {
        std::size_t i = 0;
        bool ok = true;
        while (i < s.size()) {
            while (i < s.size() && std::isspace(static_cast<unsigned char>(s[i]))) ++i;
            if (i >= s.size()) break;
            std::size_t j = i;
            while (j < s.size() && !std::isspace(static_cast<unsigned char>(s[j]))) ++j;
            std::string word = s.substr(i, j - i);
            i = j;
            SongPlayEntry e;
            const std::size_t star = word.find('*');
            if (star != std::string::npos) {
                const std::string count = word.substr(star + 1);
                if (count.empty() || count.size() > 3 || !std::all_of(count.begin(), count.end(), [](char c) { return c >= '0' && c <= '9'; }) || std::stoi(count) < 1 || std::stoi(count) > 256) {
                    err(pointer, "`" + word + "`: the repeat after * must be a number from 1 to 256", "Write a*2 to play pattern a twice.");
                    ok = false;
                    continue;
                }
                e.repeat = std::stoi(count);
                word = word.substr(0, star);
            }
            e.pattern = word == "rest" ? std::string() : word;
            if (word.empty()) { err(pointer, "an arrangement entry needs a pattern name before the *", "Write a*2."); ok = false; continue; }
            out.push_back(std::move(e));
        }
        return ok;
    }

    void play_list(const Json& j, const std::string& pointer, std::vector<SongPlayEntry>& out) {
        if (j.is_string()) { entry_text(j.get<std::string>(), pointer, out); }
        else if (j.is_array()) {
            for (std::size_t i = 0; i < j.size(); ++i) {
                const Json& e = j[i];
                const std::string at = pointer + "/" + std::to_string(i);
                if (e.is_string()) entry_text(e.get<std::string>(), at, out);
                else if (e.is_object()) {
                    unknown_keys(e, at, {"pattern", "repeat", "rest"}, "an arrangement entry");
                    SongPlayEntry pe;
                    double v = 1;
                    if (e.find("rest") != e.end()) {
                        if (number(e, at, "rest", v, 1, 256, "A whole number of bars of silence.")) { pe.repeat = int(v); out.push_back(pe); }
                    } else {
                        std::string pat;
                        if (!text(e, at, "pattern", pat, "The name of a pattern of this track.") || pat.empty()) { err(at, "an arrangement entry needs a `pattern` (or `rest`)", "Write {\"pattern\": \"a\", \"repeat\": 2} or {\"rest\": 2}."); continue; }
                        if (number(e, at, "repeat", v, 1, 256, "How many times in a row.")) pe.repeat = int(v);
                        pe.pattern = pat;
                        out.push_back(pe);
                    }
                } else err(at, "an arrangement entry must be text like \"a*2\" or an object, got " + describe_json_value(e), "Write \"a\", \"a*2\", \"rest\" or {\"pattern\": \"a\", \"repeat\": 2}.");
            }
        } else err(pointer, "what a track plays in a section must be a list of patterns or text like \"a a b*2\", got " + describe_json_value(j), "Write [\"a\", \"a\", \"b\"] or \"a*2 b\".");
    }

    void section(std::size_t index, const Json& j, SongDoc& song, std::vector<std::string>& seen) {
        const std::string pointer = "/sections/" + std::to_string(index);
        if (!j.is_object()) { err(pointer, "a section must be an object, got " + describe_json_value(j), "Write {\"name\": \"verse\", \"play\": {\"lead\": \"a\"}}."); return; }
        unknown_keys(j, pointer, {"name", "kind", "repeat", "bars", "mute", "play"}, "a section");
        SongSection s;
        if (!text(j, pointer, "name", s.name, "Name it: \"intro\", \"verse\", \"loop\"...") || s.name.empty() || s.name.size() > 40) {
            if (j.find("name") == j.end() || (j.find("name")->is_string() && (s.name.empty() || s.name.size() > 40))) err(pointer + "/name", "a section needs a `name` of 1 to 40 characters", "Write \"name\": \"verse\".");
        } else if (std::find(seen.begin(), seen.end(), s.name) != seen.end()) err(pointer + "/name", "two sections are called `" + s.name + "`", "Section names are unique so arrangement edits and loop points can name them.");
        seen.push_back(s.name);
        if (auto k = j.find("kind"); k != j.end()) {
            const std::vector<std::string> kinds = {"intro", "loop", "outro", "section"};
            const std::string v = k->is_string() ? k->get<std::string>() : std::string();
            if (std::find(kinds.begin(), kinds.end(), v) == kinds.end())
                err(pointer + "/kind", "kind must be one of intro, loop, outro, section, got " + describe_json_value(*k), did_you_mean(v, kinds) + " `loop` is the part a game repeats; intro plays once before it, outro once on the way out.");
            else s.kind = v;
        }
        double v = 1;
        if (number(j, pointer, "repeat", v, 1, 64, "How many times the section plays in a row.")) s.repeat = int(v);
        if (number(j, pointer, "bars", v, 1, 256, "The length in bars; the longest track decides when left out.")) { s.bars = int(v); s.barsWritten = true; }
        if (auto m = j.find("mute"); m != j.end()) {
            if (!m->is_array()) err(pointer + "/mute", "mute must be a list of track names, got " + describe_json_value(*m), "Write \"mute\": [\"drums\"].");
            else for (std::size_t i = 0; i < m->size(); ++i) {
                if (!(*m)[i].is_string()) { err(pointer + "/mute/" + std::to_string(i), "a muted track is named by text, got " + describe_json_value((*m)[i]), "Write the track's name."); continue; }
                s.mute.push_back((*m)[i].get<std::string>());
            }
        }
        if (auto p = j.find("play"); p != j.end()) {
            if (!p->is_object()) err(pointer + "/play", "play must be an object from track name to patterns, got " + describe_json_value(*p), "Write {\"lead\": \"a a b\", \"bass\": \"a*2\"}.");
            else for (auto it = p->begin(); it != p->end(); ++it) {
                SongSectionTrack st;
                st.track = it.key();
                play_list(it.value(), pointer + "/play/" + escape_pointer(it.key()), st.entries);
                s.play.push_back(std::move(st));
            }
        } else err(pointer, "the section `" + s.name + "` has no `play`", "Say what each track plays: \"play\": {\"lead\": \"a a b\", \"drums\": \"rock*4\"}.");
        song.sections.push_back(std::move(s));
    }

    // Names and lengths: every pattern a section plays exists, the tracks exist, the section's length is known.
    void resolve(SongDoc& song) {
        std::vector<std::string> trackNames;
        for (const SongTrack& t : song.tracks) trackNames.push_back(t.name);
        for (std::size_t si = 0; si < song.sections.size(); ++si) {
            SongSection& s = song.sections[si];
            const std::string sp = "/sections/" + std::to_string(si);
            for (const std::string& m : s.mute)
                if (std::find(trackNames.begin(), trackNames.end(), m) == trackNames.end())
                    err(sp + "/mute", "section `" + s.name + "` mutes the unknown track `" + m + "`", did_you_mean(m, trackNames) + " Tracks: " + join(trackNames) + ".");
            int longest = 0;
            for (const SongSectionTrack& st : s.play) {
                const SongTrack* t = song.find_track(st.track);
                const std::string tp = sp + "/play/" + escape_pointer(st.track);
                if (!t) {
                    err(tp, "section `" + s.name + "` plays the unknown track `" + st.track + "`", did_you_mean(st.track, trackNames) + " Tracks: " + join(trackNames) + ".");
                    continue;
                }
                std::vector<std::string> patNames;
                for (const SongPattern& p : t->patterns) patNames.push_back(p.name);
                int total = 0;
                for (const SongPlayEntry& e : st.entries) {
                    if (e.pattern.empty()) { total += e.repeat; continue; }
                    const SongPattern* p = t->find_pattern(e.pattern);
                    if (!p) {
                        if (!patNames.empty() || t->patterns.empty())
                            err(tp, "track `" + st.track + "` has no pattern `" + e.pattern + "`", did_you_mean(e.pattern, patNames) + " Its patterns: " + join(patNames) + ".");
                        continue;
                    }
                    total += p->bars * e.repeat;
                }
                longest = std::max(longest, total);
            }
            if (!s.barsWritten) s.bars = longest;
            if (s.bars <= 0 && s.play.empty() == false) err(sp, "the section `" + s.name + "` has no bars", "Give it `bars` or patterns for its tracks to play.");
        }
        long long bars = 0;
        for (const SongSection& s : song.sections) bars += (long long)s.bars * s.repeat;
        if (bars > kSongMaxBars) err("/sections", std::format("the song is {} bars long, more than the {} the engine plays", bars, kSongMaxBars), "Shorten the sections or their repeats; loop a section in the game instead of writing the repeats out.");
    }
};

}  // namespace

// ---- small members ------------------------------------------------------------------------------------------------------

namespace {
std::string issue_head(const SongIssue& issue, std::string_view file) {
    std::string out;
    if (!file.empty()) out += std::string(file) + ": ";
    out += issue.pointer.empty() ? "document" : issue.pointer;
    if (issue.line > 0) out += std::format(" (line {}, column {})", issue.line, issue.column);
    return out + ": " + issue.message;
}
}  // namespace

std::string song_issue_text(const SongIssue& issue, std::string_view file) {
    std::string out = issue_head(issue, file);
    if (!issue.hint.empty()) out += ". " + issue.hint;
    return out;
}

double SongAutomation::value_at(double beat, double fallback) const {
    if (points.empty()) return fallback;
    if (beat <= points.front().first) return points.front().second;
    if (beat >= points.back().first) return points.back().second;
    std::size_t hi = 1;
    while (hi < points.size() && points[hi].first <= beat) ++hi;
    const auto& a = points[hi - 1];
    const auto& b = points[hi];
    if (curve == "step" || b.first <= a.first) return a.second;
    double f = (beat - a.first) / (b.first - a.first);
    if (curve == "smooth") f = f * f * (3.0 - 2.0 * f);
    return a.second + (b.second - a.second) * f;
}

const SongPattern* SongTrack::find_pattern(std::string_view name) const {
    for (const SongPattern& p : patterns)
        if (p.name == name) return &p;
    return nullptr;
}

const SongBus* SongMixer::find_bus(std::string_view name) const {
    for (const SongBus& b : buses)
        if (b.name == name) return &b;
    return nullptr;
}

const SongTrack* SongDoc::find_track(std::string_view name) const {
    for (const SongTrack& t : tracks)
        if (t.name == name) return &t;
    return nullptr;
}

int SongDoc::track_index(std::string_view name) const {
    for (std::size_t i = 0; i < tracks.size(); ++i)
        if (tracks[i].name == name) return int(i);
    return -1;
}

std::vector<int> SongDoc::scale_pitch_classes() const { return song_scale_pitch_classes(keyRoot, mode).value_or(std::vector<int>{}); }

std::string SongTimeline::position_text(const SongDoc& song, std::int64_t tick) const {
    const std::int64_t bar = song.meter.barTicks();
    const std::int64_t inBar = tick % bar;
    const double beat = 1.0 + double(inBar) / double(song.meter.beatTicks());
    return std::format("bar {}, beat {:g}", tick / bar + 1, beat);
}

// ---- parse_song ---------------------------------------------------------------------------------------------------------

Result<SongDoc> parse_song(const Json& json, std::string_view file, std::vector<SongIssue>* issuesOut) {
    Parser p;
    SongDoc song;
    const std::string where = file.empty() ? std::string("song document") : std::string(file);
    auto done = [&]() -> Result<SongDoc> {
        if (issuesOut) *issuesOut = p.issues;
        if (p.issues.empty()) return std::move(song);
        const SongIssue& first = p.issues.front();
        std::string message = issue_head(first, where);
        const std::string hint = first.hint;
        if (p.issues.size() > 1) message += std::format(" (and {} more problem{})", p.issues.size() - 1, p.issues.size() == 2 ? "" : "s");
        return make_error(message, hint);
    };
    if (!json.is_object()) {
        p.err("", "a song document must be a JSON object, got " + describe_json_value(json),
              "Start from {\"format\": \"factoria.song/1\", \"tempo\": 120, \"tracks\": {...}, \"sections\": [...]} (music.create writes one; schemas/song.schema.json).");
        return done();
    }
    p.unknown_keys(json, "", {"$schema", "format", "doc", "tempo", "meter", "key", "mode", "swing", "swingGrid", "seed", "volume", "mixer", "tracks", "sections", "automation"}, "a song document");
    if (auto f = json.find("format"); f == json.end() || !f->is_string() || f->get<std::string>() != kSongFormat)
        p.err("/format", f == json.end() ? "missing `format`" : "format must be \"factoria.song/1\", got " + describe_json_value(*f), "Write \"format\": \"factoria.song/1\".");
    p.text(json, "", "doc", song.doc, "What the music is for and how it should feel.");
    p.number(json, "", "tempo", song.tempo, 20.0, 400.0, "Quarter notes per minute, e.g. 120.");
    p.number(json, "", "swing", song.swing, 0.0, 1.0, "0 is straight, 0.5 a lilt, 1 a full triplet feel.");
    p.number(json, "", "volume", song.volume, 0.0, 1.5, "Master gain, 0.8 by default.");
    if (auto s = json.find("seed"); s != json.end()) {
        if (!s->is_number_integer() || s->get<long long>() < 0) p.err("/seed", "seed must be a whole number, 0 or more, got " + describe_json_value(*s), "It picks the take of the drums' round-robin hits and of random arpeggios.");
        else song.seed = s->get<std::uint64_t>();
    }
    if (auto m = json.find("meter"); m != json.end()) {
        int beats = 0, unit = 0;
        const std::string v = m->is_string() ? m->get<std::string>() : std::string();
        const std::size_t slash = v.find('/');
        bool ok = slash != std::string::npos && slash > 0 && slash + 1 < v.size() && v.size() <= 5;
        if (ok) {
            for (std::size_t i = 0; i < v.size(); ++i)
                if (i != slash && !(v[i] >= '0' && v[i] <= '9')) ok = false;
        }
        if (ok) { beats = std::stoi(v.substr(0, slash)); unit = std::stoi(v.substr(slash + 1)); }
        if (!ok || beats < 1 || beats > 16 || (unit != 2 && unit != 4 && unit != 8 && unit != 16))
            p.err("/meter", "meter must be text like \"4/4\" (1 to 16 beats of a half, quarter, eighth or sixteenth), got " + describe_json_value(*m), "Common meters: \"4/4\", \"3/4\", \"6/8\", \"5/4\".");
        else { song.meter.beats = beats; song.meter.unit = unit; }
    }
    if (auto k = json.find("key"); k != json.end()) {
        const std::string v = k->is_string() ? k->get<std::string>() : std::string();
        if (auto pc = song_pitch_class(v)) { song.key = v; song.keyRoot = *pc; }
        else {
            std::string hint = "The key is the tonic note only (C, F#, Bb); the scale goes in \"mode\": \"minor\".";
            if (v.size() >= 2 && song_pitch_class(v.substr(0, v.size() - 1)) && v.back() == 'm') hint = "Write \"key\": \"" + v.substr(0, v.size() - 1) + "\" with \"mode\": \"minor\" (the key is the tonic note only).";
            p.err("/key", "key must be a note name such as \"C\", \"F#\" or \"Bb\", got " + describe_json_value(*k), hint);
        }
    }
    if (auto md = json.find("mode"); md != json.end()) {
        std::vector<std::string> names;
        for (const SongScaleInfo& s : song_scales()) names.push_back(s.name);
        const std::string v = md->is_string() ? md->get<std::string>() : std::string();
        if (std::find(names.begin(), names.end(), v) == names.end())
            p.err("/mode", "unknown mode " + describe_json_value(*md), did_you_mean(v, names) + " Modes: " + join(names, 20) + ".");
        else song.mode = v;
    }
    if (auto g = json.find("swingGrid"); g != json.end()) {
        if (g->is_number_integer() && (g->get<int>() == 8 || g->get<int>() == 16)) song.swingGrid = g->get<int>();
        else p.err("/swingGrid", "swingGrid must be 8 or 16, got " + describe_json_value(*g), "8 swings the eighth-note off-beats, 16 the sixteenth-note ones.");
    }
    if (auto a = json.find("automation"); a != json.end()) p.automation(*a, "/automation", true, song.automation);
    if (auto m = json.find("mixer"); m != json.end()) p.mixer(*m, song.mixer);

    if (auto t = json.find("tracks"); t == json.end() || !t->is_object() || t->empty() || t->size() > kSongMaxTracks) {
        p.err("/tracks", t == json.end() ? "the song has no `tracks`" : "tracks must be an object of 1 to 32 named tracks, got " + describe_json_value(*t),
              "Write {\"lead\": {\"instrument\": \"pluck\", \"patterns\": {\"a\": \"C4:4 E4 G4 r\"}}}.");
    } else {
        for (auto it = t->begin(); it != t->end(); ++it) {
            SongTrack track;
            p.track(it.key(), it.value(), song.meter, track);
            song.tracks.push_back(std::move(track));
        }
    }
    if (auto s = json.find("sections"); s == json.end() || !s->is_array() || s->empty() || s->size() > kSongMaxSections) {
        p.err("/sections", s == json.end() ? "the song has no `sections`" : "sections must be a list of 1 to 64 sections, got " + describe_json_value(*s),
              "Write [{\"name\": \"loop\", \"kind\": \"loop\", \"play\": {\"lead\": \"a\"}}].");
    } else {
        std::vector<std::string> seen;
        for (std::size_t i = 0; i < s->size(); ++i) p.section(i, (*s)[i], song, seen);
    }
    p.resolve_sends(song);
    if (p.issues.empty()) p.resolve(song);
    song.source = json;
    return done();
}

Result<SongDoc> load_song(std::string_view path, std::vector<SongIssue>* issues) {
    auto text = fs::read_text(path);
    if (!text)
        return make_error(std::string(path) + ": cannot read the song: " + text.error().message,
                          text.error().hint.empty() ? "Songs are *.song.json files; music.create writes a starting point." : text.error().hint);
    auto json = parse_json(*text, path);
    if (!json) return json.error();
    return parse_song(*json, path, issues);
}

// ---- expand_song --------------------------------------------------------------------------------------------------------

namespace {

// Moves a position inside an off-beat pair: the start of the second half of every pair of `grid` ticks is delayed by
// swing * grid / 3 (a full triplet feel at 1), and everything between the anchors is stretched to follow.
std::int64_t swung(std::int64_t t, std::int64_t grid, std::int64_t shift) {
    if (shift <= 0) return t;
    const std::int64_t pair = 2 * grid;
    const std::int64_t base = t - t % pair;
    const std::int64_t pos = t % pair;
    if (pos <= grid) return base + (pos * (grid + shift) + grid / 2) / grid;
    return base + grid + shift + ((pos - grid) * (grid - shift) + grid / 2) / grid;
}

}  // namespace

Result<SongTimeline> expand_song(const SongDoc& song) {
    SongTimeline tl;
    const std::int64_t bar = song.meter.barTicks();
    std::int64_t cursor = 0;
    int barCursor = 0;
    int chordIds = 0;
    const std::int64_t gridTicks = song.swingGrid == 16 ? kSongPpq / 4 : kSongPpq / 2;
    for (std::size_t si = 0; si < song.sections.size(); ++si) {
        const SongSection& s = song.sections[si];
        for (int pass = 0; pass < s.repeat; ++pass) {
            SongSpan span;
            span.section = int(si);
            span.pass = pass;
            span.startTick = cursor;
            span.startBar = barCursor;
            span.bars = s.bars;
            span.endTick = cursor + std::int64_t(s.bars) * bar;
            const int spanIndex = int(tl.spans.size());
            tl.spans.push_back(span);
            if (barCursor + s.bars > kSongMaxBars) return make_error("the song is longer than " + std::to_string(kSongMaxBars) + " bars", "Shorten the sections or their repeats.");
            for (const SongSectionTrack& st : s.play) {
                if (std::find(s.mute.begin(), s.mute.end(), st.track) != s.mute.end()) continue;
                const int ti = song.track_index(st.track);
                if (ti < 0) continue;
                const SongTrack& track = song.tracks[std::size_t(ti)];
                const double swing = track.swing ? *track.swing : song.swing;
                const std::int64_t shift = std::int64_t(swing * double(gridTicks) / 3.0 + 0.5);
                const std::int64_t sectionLen = std::int64_t(s.bars) * bar;
                std::int64_t offset = 0;
                // Unroll the list again and again until the section is full (a one-bar pattern fills a four-bar section).
                int guard = 0;
                while (offset < sectionLen && guard++ < 100000) {
                    const std::int64_t before = offset;
                    for (const SongPlayEntry& e : st.entries) {
                        for (int r = 0; r < e.repeat && offset < sectionLen; ++r) {
                            if (e.pattern.empty()) { offset += bar; continue; }
                            const SongPattern* pat = track.find_pattern(e.pattern);
                            if (!pat) continue;
                            for (const SongEvent& ev : pat->events) {
                                const std::int64_t at = offset + ev.tick;
                                if (at >= sectionLen) break;
                                const std::int64_t start = cursor + at, end = cursor + at + ev.duration;
                                const std::int64_t s0 = swung(start, gridTicks, shift), s1 = swung(end, gridTicks, shift);
                                const int chordId = ev.pitches.size() > 1 ? chordIds++ : -1;
                                auto make = [&](int pitch) {
                                    SongNote n;
                                    n.tick = s0;
                                    n.duration = std::max<std::int64_t>(1, s1 - s0);
                                    n.pitch = pitch;
                                    n.drum = ev.drum;
                                    n.velocity = ev.velocity;
                                    n.gate = ev.gate;
                                    n.accent = ev.accent;
                                    n.track = ti;
                                    n.span = spanIndex;
                                    n.pattern = pat->name;
                                    n.chordId = chordId;
                                    n.chord = ev.chord;
                                    n.source = ev.source;
                                    tl.notes.push_back(std::move(n));
                                };
                                if (track.drums) make(-1);
                                else for (int pitch : ev.pitches) make(std::clamp(pitch + track.transpose, 0, 127));
                                if (tl.notes.size() > kSongMaxNotes)
                                    return make_error("the song has more than " + std::to_string(kSongMaxNotes) + " notes", "Shorten the song or use fewer, longer notes.");
                            }
                            offset += pat->lengthTicks;
                        }
                    }
                    if (offset == before) break;
                }
            }
            cursor = span.endTick;
            barCursor += s.bars;
        }
    }
    tl.totalTicks = cursor;
    tl.bars = barCursor;
    tl.seconds = song.ticks_to_seconds(cursor);
    std::stable_sort(tl.notes.begin(), tl.notes.end(), [](const SongNote& a, const SongNote& b) {
        if (a.tick != b.tick) return a.tick < b.tick;
        if (a.track != b.track) return a.track < b.track;
        return a.pitch < b.pitch;
    });
    return tl;
}

}  // namespace fa
