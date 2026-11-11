// music.create, music.edit, music.instrument, music.chord, music.scale, music.arpeggio, music.bassline and music.drums: making and changing
// song documents (`*.song.json`, docs/MUSIC.md) and the theory helpers behind them. Every command that changes a song validates the
// result with parse_song before it writes, so a mistake is reported with its pointer, line and column and the file stays as it was.
#include <algorithm>
#include <cmath>
#include <format>
#include <set>

#include "assets_internal.h"
#include "fa/audio/sfx.h"
#include "fa/audio/song.h"
#include "fa/audio/song_helpers.h"
#include "fa/audio/song_instruments.h"
#include "fa/audio/song_theory.h"
#include "fa/audio/soundfont.h"
#include "fa/core/strings.h"
#include "fa/tooling/style_guide.h"
#include "music_internal.h"
#include "util.h"

namespace fa::assets_detail::music {

namespace {

using tooling_detail::arg_bool;
using tooling_detail::arg_int;
using tooling_detail::arg_string;

std::string join_names(const std::vector<std::string>& v) { return join(v, ", "); }

// ---------------------------------------------------------------- reading arguments ---

SongMeter parse_meter_text(const std::string& text, const char* command) {
    SongMeter m;
    const std::size_t slash = text.find('/');
    bool ok = slash != std::string::npos && slash > 0 && slash + 1 < text.size();
    int beats = 0, unit = 0;
    if (ok) {
        try {
            std::size_t used = 0;
            beats = std::stoi(text.substr(0, slash), &used);
            ok = used == slash;
            unit = std::stoi(text.substr(slash + 1), &used);
            ok = ok && used == text.size() - slash - 1;
        } catch (...) {
            ok = false;
        }
    }
    if (!ok || beats < 1 || beats > 16 || (unit != 2 && unit != 4 && unit != 8 && unit != 16))
        fail("invalid_argument", std::string(command) + ": meter '" + text + "' must look like \"4/4\" (1 to 16 beats of a half, quarter, eighth or sixteenth note).", "Common meters: \"4/4\", \"3/4\", \"6/8\", \"5/4\".");
    m.beats = beats;
    m.unit = unit;
    return m;
}

int parse_key_text(const std::string& text, const char* command) {
    auto pc = song_pitch_class(text);
    if (!pc) {
        std::vector<std::string> names;
        for (int i = 0; i < 12; ++i) names.push_back(song_pitch_class_name(i));
        fail("invalid_argument", std::string(command) + ": key '" + text + "' is not a note name.", "Write a letter with an optional # or b: \"C\", \"F#\", \"Bb\". " + did_you_mean(text, names));
    }
    return *pc;
}

void check_mode_text(const std::string& mode, const char* command) {
    std::vector<std::string> names;
    for (const SongScaleInfo& s : song_scales()) names.push_back(s.name);
    if (std::find(names.begin(), names.end(), mode) == names.end())
        fail("invalid_argument", std::string(command) + ": unknown mode '" + mode + "'.", did_you_mean(mode, names) + " Modes: " + join_names(names) + " (music.scale lists them with their notes).");
}

// Roman numerals in a progression ("i VI III VII", "I V vi IV", "bVII"): chord names start with a capital A to G, so a first letter i or v (any case)
// or a b/# before one of them is a degree.
bool looks_roman(const std::string& text) {
    std::size_t i = 0;
    while (i < text.size() && (text[i] == ' ' || text[i] == '|')) ++i;
    if (i >= text.size()) return false;
    if ((text[i] == 'b' || text[i] == '#') && i + 1 < text.size()) ++i;
    return std::string("ivIV").find(text[i]) != std::string::npos;
}

struct Progression {
    std::string names;                  // chord names ("Am F C G")
    std::vector<SongChordStep> steps;
    int bars = 0;                       // whole bars it lasts
};

Progression make_progression(const std::string& text, int keyRoot, const std::string& mode, const SongMeter& meter, const char* command) {
    Progression p;
    p.names = text;
    if (looks_roman(text)) {
        auto named = song_roman_progression(text, keyRoot, mode);
        if (!named) fail("invalid_argument", std::string(command) + ": " + named.error().message, named.error().hint);
        p.names = *named;
    }
    auto steps = song_parse_progression(p.names, meter, 0);
    if (!steps) fail("invalid_argument", std::string(command) + ": " + steps.error().message, steps.error().hint);
    p.steps = std::move(*steps);
    std::int64_t ticks = 0;
    for (const SongChordStep& s : p.steps) ticks += s.ticks;
    p.bars = int((ticks + meter.barTicks() - 1) / meter.barTicks());
    return p;
}

// The song a helper command reads its meter, key and mode from (when it has a `path`) and the arguments that override them.
struct Context {
    SongMeter meter;
    int keyRoot = 0;
    std::string key = "C";
    std::string mode = "major";
    std::optional<Loaded> song;
};

Context read_context(const std::string& projectDir, const Json& a, const char* command) {
    Context c;
    if (a.contains("path")) {
        c.song = load_song_file(projectDir, song_path(arg_string(a, "path", true)));
        c.meter = c.song->doc.meter;
        c.key = c.song->doc.key;
        c.keyRoot = c.song->doc.keyRoot;
        c.mode = c.song->doc.mode;
    }
    if (a.contains("meter")) c.meter = parse_meter_text(arg_string(a, "meter", true), command);
    if (a.contains("key")) {
        c.key = arg_string(a, "key", true);
        c.keyRoot = parse_key_text(c.key, command);
    }
    if (a.contains("mode")) {
        c.mode = arg_string(a, "mode", true);
        check_mode_text(c.mode, command);
    }
    return c;
}

double arg_double(const Json& a, const char* key, double def, double lo, double hi, const char* command) {
    if (!a.contains(key) || a[key].is_null()) return def;
    if (!a[key].is_number()) fail("invalid_argument", std::string(command) + ": `" + key + "` must be a number, got " + a[key].dump() + ".", std::format("Use a number from {:g} to {:g}.", lo, hi));
    const double v = a[key].get<double>();
    if (v < lo || v > hi) fail("invalid_argument", std::string(command) + ": `" + key + "` " + a[key].dump() + std::format(" is outside {:g} to {:g}.", lo, hi), std::format("Use a number from {:g} to {:g}.", lo, hi));
    return v;
}

int arg_int_range(const Json& a, const char* key, int def, int lo, int hi, const char* command) {
    if (!a.contains(key) || a[key].is_null()) return def;
    if (!a[key].is_number_integer()) fail("invalid_argument", std::string(command) + ": `" + key + "` must be a whole number, got " + a[key].dump() + ".", std::format("Use a whole number from {} to {}.", lo, hi));
    const long long v = a[key].get<long long>();
    if (v < lo || v > hi) fail("invalid_argument", std::string(command) + ": `" + key + "` " + a[key].dump() + std::format(" is outside {} to {}.", lo, hi), std::format("Use a whole number from {} to {}.", lo, hi));
    return int(v);
}

// ---------------------------------------------------------------- editing the document ---

Json& ensure_object(Json& parent, const char* key) {
    if (!parent.contains(key) || !parent[key].is_object()) parent[key] = Json::object();
    return parent[key];
}

Json& ensure_array(Json& parent, const char* key) {
    if (!parent.contains(key) || !parent[key].is_array()) parent[key] = Json::array();
    return parent[key];
}

std::vector<std::string> track_names(const Json& song) {
    std::vector<std::string> names;
    if (song.contains("tracks") && song["tracks"].is_object())
        for (auto it = song["tracks"].begin(); it != song["tracks"].end(); ++it) names.push_back(it.key());
    return names;
}

std::vector<std::string> section_names(const Json& song) {
    std::vector<std::string> names;
    if (song.contains("sections") && song["sections"].is_array())
        for (const Json& s : song["sections"])
            if (s.is_object() && s.contains("name") && s["name"].is_string()) names.push_back(s["name"].get<std::string>());
    return names;
}

std::vector<std::string> pattern_names(const Json& track) {
    std::vector<std::string> names;
    if (track.contains("patterns") && track["patterns"].is_object())
        for (auto it = track["patterns"].begin(); it != track["patterns"].end(); ++it) names.push_back(it.key());
    return names;
}

struct OpCtx {
    std::size_t index = 0;
    std::string op;
    std::string where() const { return "op " + std::to_string(index + 1) + " (" + op + ")"; }
};

[[noreturn]] void op_fail(const OpCtx& c, const std::string& message, const std::string& hint) { fail("invalid_argument", c.where() + ": " + message, hint); }

std::string op_string(const OpCtx& c, const Json& op, const char* key, bool required) {
    if (!op.contains(key)) {
        if (required) op_fail(c, std::string("`") + key + "` is missing.", std::string("Add \"") + key + "\" to the operation.");
        return {};
    }
    if (!op[key].is_string()) op_fail(c, std::string("`") + key + "` must be text, got " + op[key].dump() + ".", "Write it as a string.");
    return op[key].get<std::string>();
}

void op_keys(const OpCtx& c, const Json& op, const std::vector<std::string>& allowed) {
    std::vector<std::string> all = allowed;
    all.push_back("op");
    for (auto it = op.begin(); it != op.end(); ++it)
        if (std::find(all.begin(), all.end(), it.key()) == all.end())
            op_fail(c, "unknown field `" + it.key() + "`.", did_you_mean(it.key(), all) + " This operation takes: " + join_names(allowed) + ".");
}

std::size_t find_section(const Json& song, const OpCtx& c, const std::string& name) {
    const std::vector<std::string> names = section_names(song);
    for (std::size_t i = 0; i < names.size(); ++i)
        if (names[i] == name) return i;
    op_fail(c, "there is no section '" + name + "'.", names.empty() ? "The song has no sections: add_section creates one." : did_you_mean(name, names) + " Sections: " + join_names(names) + ".");
}

Json& find_track_json(Json& song, const OpCtx& c, const std::string& name) {
    const std::vector<std::string> names = track_names(song);
    if (std::find(names.begin(), names.end(), name) == names.end())
        op_fail(c, "there is no track '" + name + "'.", names.empty() ? "The song has no tracks: add_track creates one." : did_you_mean(name, names) + " Tracks: " + join_names(names) + ".");
    return song["tracks"][name];
}

// The entries of a section's track, as the tokens of the arrangement text ("a*2", "rest*2").
std::vector<std::string> entry_tokens(const Json& entries) {
    std::vector<std::string> out;
    auto split = [&](const std::string& text) {
        std::string cur;
        for (char ch : text) {
            if (ch == ' ' || ch == '\t' || ch == '\n') {
                if (!cur.empty()) out.push_back(cur);
                cur.clear();
            } else {
                cur += ch;
            }
        }
        if (!cur.empty()) out.push_back(cur);
    };
    if (entries.is_string()) split(entries.get<std::string>());
    else if (entries.is_array())
        for (const Json& e : entries) {
            if (e.is_string()) split(e.get<std::string>());
            else if (e.is_object() && e.contains("pattern") && e["pattern"].is_string()) out.push_back(e["pattern"].get<std::string>() + (e.value("repeat", 1) > 1 ? "*" + std::to_string(e.value("repeat", 1)) : std::string()));
            else if (e.is_object() && e.contains("rest")) out.push_back("rest" + (e["rest"].is_number_integer() && e["rest"].get<int>() > 1 ? "*" + std::to_string(e["rest"].get<int>()) : std::string()));
        }
    return out;
}

std::string token_name(const std::string& token) { return token.substr(0, token.find('*')); }

// Removes the references to the pattern `pattern` of `track` from every section.
void drop_pattern_references(Json& song, const std::string& track, const std::string& pattern) {
    if (!song.contains("sections") || !song["sections"].is_array()) return;
    for (Json& s : song["sections"]) {
        if (!s.is_object() || !s.contains("play") || !s["play"].is_object() || !s["play"].contains(track)) continue;
        std::vector<std::string> kept;
        for (const std::string& t : entry_tokens(s["play"][track]))
            if (token_name(t) != pattern) kept.push_back(t);
        if (kept.empty()) s["play"].erase(track);
        else s["play"][track] = join(kept, " ");
    }
}

// A layer lists tracks, as ["a", "b"] or {tracks: [...]}; `edit` is called on that list.
template <class F>
void edit_layer_lists(Json& song, F edit) {
    if (!song.contains("layers") || !song["layers"].is_object()) return;
    for (auto it = song["layers"].begin(); it != song["layers"].end(); ++it) {
        Json* list = it.value().is_array() ? &it.value() : (it.value().is_object() && it.value().contains("tracks") ? &it.value()["tracks"] : nullptr);
        if (list && list->is_array()) edit(*list);
    }
}

void drop_track_references(Json& song, const std::string& track) {
    edit_layer_lists(song, [&](Json& list) {
        Json kept = Json::array();
        for (const Json& n : list)
            if (!(n.is_string() && n.get<std::string>() == track)) kept.push_back(n);
        list = kept;
    });
    if (song.contains("layers") && song["layers"].is_object()) {
        // a layer left with no track goes
        Json kept = Json::object();
        for (auto it = song["layers"].begin(); it != song["layers"].end(); ++it) {
            const Json& list = it.value().is_array() ? it.value() : (it.value().is_object() && it.value().contains("tracks") ? it.value()["tracks"] : Json::array());
            if (list.is_array() && !list.empty()) kept[it.key()] = it.value();
        }
        if (kept.empty()) song.erase("layers");
        else song["layers"] = kept;
    }
    if (!song.contains("sections") || !song["sections"].is_array()) return;
    for (Json& s : song["sections"]) {
        if (!s.is_object()) continue;
        if (s.contains("play") && s["play"].is_object()) s["play"].erase(track);
        if (s.contains("mute") && s["mute"].is_array()) {
            Json kept = Json::array();
            for (const Json& m : s["mute"])
                if (!(m.is_string() && m.get<std::string>() == track)) kept.push_back(m);
            if (kept.empty()) s.erase("mute");
            else s["mute"] = kept;
        }
    }
}

void rename_track_references(Json& song, const std::string& from, const std::string& to) {
    edit_layer_lists(song, [&](Json& list) {
        for (Json& n : list)
            if (n.is_string() && n.get<std::string>() == from) n = to;
    });
    if (!song.contains("sections") || !song["sections"].is_array()) return;
    for (Json& s : song["sections"]) {
        if (!s.is_object()) continue;
        if (s.contains("play") && s["play"].is_object() && s["play"].contains(from)) {
            Json renamed = Json::object();
            for (auto it = s["play"].begin(); it != s["play"].end(); ++it) renamed[it.key() == from ? to : it.key()] = it.value();
            s["play"] = renamed;
        }
        if (s.contains("mute") && s["mute"].is_array())
            for (Json& m : s["mute"])
                if (m.is_string() && m.get<std::string>() == from) m = to;
    }
}

// Sets what `track` plays in the section at `index`: text or a list of entries; null removes it.
void set_entries(Json& song, std::size_t index, const std::string& track, const Json& entries) {
    Json& section = song["sections"][index];
    Json& play = ensure_object(section, "play");
    if (entries.is_null()) {
        play.erase(track);
    } else {
        play[track] = entries;
    }
}

void append_entry(Json& song, std::size_t index, const std::string& track, const std::string& pattern) {
    Json& play = ensure_object(song["sections"][index], "play");
    if (!play.contains(track)) {
        play[track] = pattern;
        return;
    }
    if (play[track].is_string()) play[track] = play[track].get<std::string>() + " " + pattern;
    else if (play[track].is_array()) play[track].push_back(pattern);
    else play[track] = pattern;
}

void apply_play_map(Json& song, const OpCtx& c, const Json& map) {
    if (!map.is_object()) op_fail(c, "`play` must be an object of section name to what the track plays there.", "Write \"play\": {\"loop\": \"a*2\", \"outro\": \"b\"}.");
    for (auto it = map.begin(); it != map.end(); ++it) {
        find_section(song, c, it.key());
    }
}

// The notes array of a set_pattern ([{pitch, tick, duration, velocity, accent, staccato}, ...], the shape music.notes returns) as note text.
// Note times are ticks (960 per quarter) from the start of the pattern; the text is as long as `bars` (default: the bars the last note needs).
Json notes_array_value(const OpCtx& c, const Json& op, const Json& song) {
    const SongMeter meter = song.contains("meter") && song["meter"].is_string() ? parse_meter_text(song["meter"].get<std::string>(), "music.edit") : SongMeter{};
    std::vector<SongRollNote> notes;
    std::int64_t last = 0;
    std::size_t n = 0;
    for (const Json& j : op["notes"]) {
        ++n;
        const std::string at = "notes[" + std::to_string(n - 1) + "]";
        if (!j.is_object()) op_fail(c, at + " must be an object {pitch, tick, duration}, got " + j.dump() + ".", "Example: {\"pitch\": 60, \"tick\": 0, \"duration\": 960}.");
        for (auto it = j.begin(); it != j.end(); ++it)
            if (it.key() != "pitch" && it.key() != "tick" && it.key() != "duration" && it.key() != "velocity" && it.key() != "accent" && it.key() != "staccato" && it.key() != "name")
                op_fail(c, at + " has no field '" + it.key() + "'.", "A note has pitch, tick, duration, velocity, accent and staccato. " + did_you_mean(it.key(), std::vector<std::string>{"pitch", "tick", "duration", "velocity", "accent", "staccato"}));
        SongRollNote r;
        if (!j.contains("pitch")) op_fail(c, at + " has no `pitch`.", "Give a MIDI number (60 is C4) or a note name (\"C4\").");
        if (j["pitch"].is_string()) {
            const auto pitch = song_parse_pitch(j["pitch"].get<std::string>());
            if (!pitch) op_fail(c, at + ": '" + j["pitch"].get<std::string>() + "' is not a note name.", "Write a name such as \"C4\", \"F#3\" or \"Bb5\", or a MIDI number.");
            r.pitch = *pitch;
        } else if (j["pitch"].is_number_integer()) {
            r.pitch = int(std::clamp<long long>(j["pitch"].get<long long>(), -1000, 1000));
        } else {
            op_fail(c, at + ": `pitch` must be a MIDI number or a note name, got " + j["pitch"].dump() + ".", "Write 60 or \"C4\".");
        }
        for (const char* key : {"tick", "duration"})
            if (!j.contains(key) || !j[key].is_number()) op_fail(c, at + ": `" + key + "` must be a number of ticks (960 per quarter note).", std::string("Write \"") + key + "\": " + (std::string(key) == "tick" ? "0" : "960") + ".");
        r.tick = std::int64_t(std::llround(j["tick"].get<double>()));
        r.duration = std::int64_t(std::llround(j["duration"].get<double>()));
        if (j.contains("velocity")) {
            if (!j["velocity"].is_number_integer()) op_fail(c, at + ": `velocity` must be a whole number 1 to 127.", "Write \"velocity\": 90.");
            r.velocity = int(std::clamp<long long>(j["velocity"].get<long long>(), -1000, 1000));
        }
        if (j.contains("accent") && j["accent"].is_boolean()) r.accent = j["accent"].get<bool>();
        if (j.contains("staccato") && j["staccato"].is_boolean()) r.staccato = j["staccato"].get<bool>();
        last = std::max(last, r.tick + r.duration);
        notes.push_back(r);
    }
    int bars = 0;
    if (op.contains("bars")) {
        if (!op["bars"].is_number_integer() || op["bars"].get<long long>() < 1 || op["bars"].get<long long>() > kSongMaxBars)
            op_fail(c, "`bars` must be a whole number from 1 to " + std::to_string(kSongMaxBars) + ", got " + op["bars"].dump() + ".", "Write \"bars\": 2.");
        bars = int(op["bars"].get<long long>());
    } else {
        bars = int(std::max<std::int64_t>(1, (last + meter.barTicks() - 1) / meter.barTicks()));
    }
    auto text = song_write_note_text(notes, meter, bars);
    if (!text) op_fail(c, text.error().message, text.error().hint);
    return Json(*text);   // padded with rests to `bars` bars, so the text alone says the length
}

Json pattern_value(const OpCtx& c, const Json& op, const Json& song) {
    if (op.contains("notes") && op["notes"].is_array() && !op.contains("grid")) {
        if (op.contains("step")) op_fail(c, "`step` only applies to a drum `grid`.", "Remove it, or use `grid` for a drum pattern.");
        return notes_array_value(c, op, song);
    }
    const bool hasNotes = op.contains("notes"), hasGrid = op.contains("grid");
    if (hasNotes == hasGrid) op_fail(c, "give exactly one of `notes` (note text for a pitched track) and `grid` (drum lanes).", "Example: {\"notes\": \"C4:4 E4 G4 r\"} or {\"grid\": {\"kick\": \"x...x...\"}, \"step\": \"8\"}.");
    if (hasNotes) {
        if (!op["notes"].is_string()) op_fail(c, "`notes` must be note text or a list of notes, got " + op["notes"].dump() + ".", "Write \"notes\": \"C4:4 E4 G4 r\" (docs/MUSIC.md has the notation) or [{\"pitch\": 60, \"tick\": 0, \"duration\": 960}].");
        if (op.contains("step")) op_fail(c, "`step` only applies to a drum `grid`.", "Remove it, or use `grid` for a drum pattern.");
        if (!op.contains("bars")) return op["notes"];
        return Json::object({{"notes", op["notes"]}, {"bars", op["bars"]}});
    }
    if (!op["grid"].is_object()) op_fail(c, "`grid` must be an object of lane name to step text.", "Write \"grid\": {\"kick\": \"x...x...\", \"snare\": \"....x...\"}.");
    Json v = Json::object({{"grid", op["grid"]}});
    if (op.contains("step")) v["step"] = op["step"];
    if (op.contains("bars")) v["bars"] = op["bars"];
    return v;
}

void apply_automation(Json& holder, const OpCtx& c, const Json& op) {
    const std::string param = op_string(c, op, "param", true);
    Json& lanes = ensure_array(holder, "automation");
    std::size_t at = lanes.size();
    for (std::size_t i = 0; i < lanes.size(); ++i)
        if (lanes[i].is_object() && lanes[i].value("param", std::string()) == param) at = i;
    const bool remove = !op.contains("points") || op["points"].is_null() || (op["points"].is_array() && op["points"].empty());
    if (remove) {
        if (at < lanes.size()) lanes.erase(lanes.begin() + long(at));
        if (lanes.empty()) holder.erase("automation");
        return;
    }
    Json lane = Json::object({{"param", param}, {"points", op["points"]}});
    if (op.contains("curve")) lane["curve"] = op["curve"];
    if (at < lanes.size()) lanes[at] = lane;
    else lanes.push_back(lane);
}

// Applies one operation of music.edit to the document and says what it did.
std::string apply_op(Json& song, const OpCtx& c, const Json& op) {
    const std::string name = c.op;
    if (name == "set_song") {
        op_keys(c, op, {"tempo", "meter", "key", "mode", "swing", "swingGrid", "seed", "volume", "doc"});
        std::vector<std::string> changed;
        for (auto it = op.begin(); it != op.end(); ++it) {
            if (it.key() == "op") continue;
            if (it.value().is_null()) song.erase(it.key());
            else song[it.key()] = it.value();
            changed.push_back(it.key());
        }
        if (changed.empty()) op_fail(c, "nothing to set.", "Give at least one of: tempo, meter, key, mode, swing, swingGrid, seed, volume, doc.");
        return "set " + join_names(changed);
    }
    if (name == "add_track") {
        op_keys(c, op, {"track", "instrument", "volume", "pan", "mute", "solo", "voices", "effects", "sends", "transpose", "swing", "range", "kit", "patterns", "automation", "play"});
        const std::string track = op_string(c, op, "track", true);
        Json& tracks = ensure_object(song, "tracks");
        if (tracks.contains(track)) op_fail(c, "the track '" + track + "' exists.", "set_track changes it, set_pattern changes its patterns; remove_track first to start over.");
        if (!op.contains("instrument")) op_fail(c, "`instrument` is missing.", "Name a built-in (pluck, pad, bass, lead, bell, organ, strings, chiptune, flute, kit for drums), a preset or a .sfx.json (music.instrument lists them).");
        Json t = Json::object();
        for (const char* key : {"instrument", "volume", "pan", "mute", "solo", "voices", "effects", "sends", "transpose", "swing", "range", "kit"})
            if (op.contains(key)) t[key] = op[key];
        t["patterns"] = op.contains("patterns") ? op["patterns"] : Json::object();
        if (op.contains("automation")) t["automation"] = op["automation"];
        tracks[track] = t;
        if (op.contains("play")) {
            apply_play_map(song, c, op["play"]);
            for (auto it = op["play"].begin(); it != op["play"].end(); ++it) set_entries(song, find_section(song, c, it.key()), track, it.value());
        }
        return "added track " + track + " (" + op["instrument"].dump() + ")";
    }
    if (name == "set_track") {
        op_keys(c, op, {"track", "name", "instrument", "volume", "pan", "mute", "solo", "voices", "effects", "sends", "transpose", "swing", "range", "kit", "automation"});
        const std::string track = op_string(c, op, "track", true);
        find_track_json(song, c, track);
        std::vector<std::string> changed;
        for (auto it = op.begin(); it != op.end(); ++it) {
            const std::string& key = it.key();
            if (key == "op" || key == "track" || key == "name") continue;
            Json& t = song["tracks"][track];
            if (it.value().is_null()) {
                if (key == "instrument") op_fail(c, "a track cannot lose its `instrument`.", "Set another instrument instead.");
                t.erase(key);
            } else {
                t[key] = it.value();
            }
            changed.push_back(key);
        }
        if (op.contains("name")) {
            const std::string to = op_string(c, op, "name", true);
            const std::vector<std::string> existing = track_names(song);
            if (to != track && std::find(existing.begin(), existing.end(), to) != existing.end()) op_fail(c, "a track named '" + to + "' exists.", "Choose another name.");
            Json renamed = Json::object();
            for (auto it = song["tracks"].begin(); it != song["tracks"].end(); ++it) renamed[it.key() == track ? to : it.key()] = it.value();
            song["tracks"] = renamed;
            rename_track_references(song, track, to);
            changed.push_back("name -> " + to);
        }
        if (changed.empty()) op_fail(c, "nothing to change.", "Give at least one of: name, instrument, volume, pan, mute, solo, voices, effects, sends, transpose, swing, range, kit, automation.");
        return "changed track " + track + ": " + join_names(changed);
    }
    if (name == "set_layers") {
        op_keys(c, op, {"layers"});
        if (!op.contains("layers") || !op["layers"].is_object())
            op_fail(c, "`layers` must be an object of layer name -> tracks.", "Example: {\"layers\": {\"drums\": [\"drums\"], \"harmony\": {\"tracks\": [\"pad\", \"keys\"], \"intensity\": 0.4}}}. A layer set to null is removed; the tracks no layer names form the layer `other`.");
        Json& layers = ensure_object(song, "layers");
        std::vector<std::string> changed;
        for (auto it = op["layers"].begin(); it != op["layers"].end(); ++it) {
            if (it.value().is_null()) {
                if (!layers.contains(it.key())) {
                    std::vector<std::string> names;
                    for (auto l = layers.begin(); l != layers.end(); ++l) names.push_back(l.key());
                    op_fail(c, "there is no layer '" + it.key() + "' to remove.", names.empty() ? "The song has no layers." : did_you_mean(it.key(), names) + " Layers: " + join_names(names) + ".");
                }
                layers.erase(it.key());
                changed.push_back("removed " + it.key());
            } else {
                layers[it.key()] = it.value();
                changed.push_back(it.key());
            }
        }
        if (layers.empty()) song.erase("layers");
        return "set the layers: " + join_names(changed);
    }
    if (name == "set_mixer") {
        op_keys(c, op, {"buses", "master"});
        if (!op.contains("buses") && !op.contains("master"))
            op_fail(c, "nothing to set.", "Give `buses` ({\"reverb\": {\"effects\": [{\"type\":\"reverb\",\"room\":0.7,\"mix\":1}], \"volume\": 0.8}}) or `master` ({\"limiter\": true, \"loudness\": \"style\"}).");
        Json& mixer = ensure_object(song, "mixer");
        std::vector<std::string> changed;
        if (op.contains("buses")) {
            if (!op["buses"].is_object()) op_fail(c, "`buses` must be an object of bus name -> bus.", "Example: {\"buses\": {\"hall\": {\"effects\": [{\"type\":\"reverb\",\"room\":0.8}]}}}. A bus set to null is removed.");
            Json& buses = ensure_object(mixer, "buses");
            for (auto it = op["buses"].begin(); it != op["buses"].end(); ++it) {
                const std::string bus = it.key();
                if (it.value().is_null()) {
                    if (!buses.contains(bus)) {
                        std::vector<std::string> names;
                        for (auto b = buses.begin(); b != buses.end(); ++b) names.push_back(b.key());
                        op_fail(c, "there is no bus '" + bus + "' to remove.", names.empty() ? "The song has no buses." : did_you_mean(bus, names) + " Buses: " + join_names(names) + ".");
                    }
                    buses.erase(bus);
                    if (song.contains("tracks") && song["tracks"].is_object())
                        for (auto t = song["tracks"].begin(); t != song["tracks"].end(); ++t)
                            if (t.value().is_object() && t.value().contains("sends") && t.value()["sends"].is_object()) {
                                t.value()["sends"].erase(bus);
                                if (t.value()["sends"].empty()) t.value().erase("sends");
                            }
                    changed.push_back("removed bus " + bus);
                } else if (!it.value().is_object()) {
                    op_fail(c, "the bus '" + bus + "' must be an object (volume, pan, mute, effects) or null to remove it.", "Example: {\"volume\": 0.8, \"effects\": [{\"type\":\"reverb\",\"room\":0.8}]}.");
                } else {
                    Json& target = ensure_object(buses, bus.c_str());
                    for (auto f = it.value().begin(); f != it.value().end(); ++f) {
                        if (f.value().is_null()) target.erase(f.key());
                        else target[f.key()] = f.value();
                    }
                    changed.push_back("bus " + bus);
                }
            }
            if (buses.empty()) mixer.erase("buses");
        }
        if (op.contains("master")) {
            if (!op["master"].is_object()) op_fail(c, "`master` must be an object (effects, limiter, loudness).", "Example: {\"limiter\": {\"ceilingDb\": -1}, \"loudness\": -16}. A field set to null goes back to its default.");
            Json& master = ensure_object(mixer, "master");
            for (auto f = op["master"].begin(); f != op["master"].end(); ++f) {
                if (f.value().is_null()) master.erase(f.key());
                else master[f.key()] = f.value();
                changed.push_back("master " + f.key());
            }
            if (master.empty()) mixer.erase("master");
        }
        if (mixer.empty()) song.erase("mixer");
        return "set the mixer: " + join_names(changed);
    }
    if (name == "remove_track") {
        op_keys(c, op, {"track"});
        const std::string track = op_string(c, op, "track", true);
        find_track_json(song, c, track);
        song["tracks"].erase(track);
        drop_track_references(song, track);
        return "removed track " + track + " and what the sections said about it";
    }
    if (name == "set_pattern") {
        op_keys(c, op, {"track", "pattern", "notes", "grid", "step", "bars", "play"});
        const std::string track = op_string(c, op, "track", true), pattern = op_string(c, op, "pattern", true);
        find_track_json(song, c, track);
        const Json value = pattern_value(c, op, song);
        const bool existed = ensure_object(song["tracks"][track], "patterns").contains(pattern);
        song["tracks"][track]["patterns"][pattern] = value;
        if (op.contains("play")) {
            apply_play_map(song, c, op["play"]);
            for (auto it = op["play"].begin(); it != op["play"].end(); ++it) set_entries(song, find_section(song, c, it.key()), track, it.value());
        }
        return std::string(existed ? "replaced" : "added") + " pattern " + track + "/" + pattern;
    }
    if (name == "remove_pattern") {
        op_keys(c, op, {"track", "pattern"});
        const std::string track = op_string(c, op, "track", true), pattern = op_string(c, op, "pattern", true);
        Json& t = find_track_json(song, c, track);
        const std::vector<std::string> names = pattern_names(t);
        if (std::find(names.begin(), names.end(), pattern) == names.end())
            op_fail(c, "the track '" + track + "' has no pattern '" + pattern + "'.", did_you_mean(pattern, names) + " Patterns: " + join_names(names) + ".");
        if (names.size() == 1) op_fail(c, "'" + pattern + "' is the only pattern of '" + track + "', and a track needs at least one.", "remove_track removes the whole track, or set_pattern another pattern first.");
        t["patterns"].erase(pattern);
        drop_pattern_references(song, track, pattern);
        return "removed pattern " + track + "/" + pattern + " and its uses in the sections";
    }
    if (name == "add_section") {
        op_keys(c, op, {"section", "kind", "repeat", "bars", "mute", "play", "index"});
        const std::string section = op_string(c, op, "section", true);
        const std::vector<std::string> existing = section_names(song);
        if (std::find(existing.begin(), existing.end(), section) != existing.end()) op_fail(c, "the section '" + section + "' exists.", "set_section changes it; choose another name.");
        Json s = Json::object({{"name", section}});
        for (const char* key : {"kind", "repeat", "bars", "mute"})
            if (op.contains(key)) s[key] = op[key];
        s["play"] = op.contains("play") ? op["play"] : Json::object();
        Json& sections = ensure_array(song, "sections");
        std::size_t at = sections.size();
        if (op.contains("index")) {
            if (!op["index"].is_number_integer() || op["index"].get<long long>() < 1 || op["index"].get<long long>() > (long long)(sections.size()) + 1)
                op_fail(c, "`index` " + op["index"].dump() + " is outside 1 to " + std::to_string(sections.size() + 1) + ".", "Sections are numbered from 1 in play order; leave `index` out to append.");
            at = std::size_t(op["index"].get<long long>() - 1);
        }
        sections.insert(sections.begin() + long(at), s);
        return "added section " + section + " at position " + std::to_string(at + 1);
    }
    if (name == "set_section") {
        op_keys(c, op, {"section", "name", "kind", "repeat", "bars", "mute", "play"});
        const std::string section = op_string(c, op, "section", true);
        const std::size_t si = find_section(song, c, section);
        std::vector<std::string> changed;
        for (auto it = op.begin(); it != op.end(); ++it) {
            const std::string& key = it.key();
            if (key == "op" || key == "section") continue;
            Json& s = song["sections"][si];
            if (key == "play") {
                if (!it.value().is_object()) op_fail(c, "`play` must be an object of track name to what it plays.", "Write \"play\": {\"bass\": \"line*2\", \"drums\": null}: null stops a track in this section; tracks not named are left alone.");
                for (auto p = it.value().begin(); p != it.value().end(); ++p) {
                    const std::vector<std::string> tracks = track_names(song);
                    if (std::find(tracks.begin(), tracks.end(), p.key()) == tracks.end())
                        op_fail(c, "`play` names the unknown track '" + p.key() + "'.", did_you_mean(p.key(), tracks) + " Tracks: " + join_names(tracks) + ".");
                    set_entries(song, si, p.key(), p.value());
                }
                changed.push_back("play");
                continue;
            }
            if (key == "name") {
                const std::string to = op_string(c, op, "name", true);
                const std::vector<std::string> existing = section_names(song);
                if (to != section && std::find(existing.begin(), existing.end(), to) != existing.end()) op_fail(c, "a section named '" + to + "' exists.", "Choose another name.");
            }
            if (it.value().is_null()) s.erase(key);
            else s[key] = it.value();
            changed.push_back(key);
        }
        if (changed.empty()) op_fail(c, "nothing to change.", "Give at least one of: name, kind, repeat, bars, mute, play.");
        return "changed section " + section + ": " + join_names(changed);
    }
    if (name == "remove_section") {
        op_keys(c, op, {"section"});
        const std::string section = op_string(c, op, "section", true);
        const std::size_t si = find_section(song, c, section);
        song["sections"].erase(song["sections"].begin() + long(si));
        return "removed section " + section;
    }
    if (name == "move_section") {
        op_keys(c, op, {"section", "index"});
        const std::string section = op_string(c, op, "section", true);
        const std::size_t si = find_section(song, c, section);
        const std::size_t n = song["sections"].size();
        if (!op.contains("index") || !op["index"].is_number_integer() || op["index"].get<long long>() < 1 || op["index"].get<long long>() > (long long)(n))
            op_fail(c, "`index` must be a whole number from 1 to " + std::to_string(n) + ".", "The new position of the section in play order, counted from 1.");
        Json moved = song["sections"][si];
        song["sections"].erase(song["sections"].begin() + long(si));
        const std::size_t at = std::size_t(op["index"].get<long long>() - 1);
        song["sections"].insert(song["sections"].begin() + long(at), moved);
        return "moved section " + section + " to position " + std::to_string(at + 1);
    }
    if (name == "arrange") {
        op_keys(c, op, {"section", "track", "entries"});
        const std::string section = op_string(c, op, "section", true), track = op_string(c, op, "track", true);
        const std::size_t si = find_section(song, c, section);
        find_track_json(song, c, track);
        if (!op.contains("entries")) op_fail(c, "`entries` is missing.", "Write \"entries\": \"a a b*2\" (patterns in order, *N repeats one, rest is a silent bar), or null to stop the track in this section.");
        set_entries(song, si, track, op["entries"]);
        return op["entries"].is_null() ? "the track " + track + " no longer plays in " + section : "section " + section + ": " + track + " plays " + op["entries"].dump();
    }
    if (name == "mute") {
        op_keys(c, op, {"section", "tracks", "muted"});
        const std::string section = op_string(c, op, "section", true);
        const std::size_t si = find_section(song, c, section);
        if (!op.contains("tracks") || !op["tracks"].is_array() || op["tracks"].empty()) op_fail(c, "`tracks` must be a list of track names.", "Write \"tracks\": [\"drums\", \"arp\"].");
        const bool muted = !op.contains("muted") || op["muted"].get<bool>();
        const std::vector<std::string> known = track_names(song);
        std::vector<std::string> now;
        if (song["sections"][si].contains("mute") && song["sections"][si]["mute"].is_array())
            for (const Json& m : song["sections"][si]["mute"])
                if (m.is_string()) now.push_back(m.get<std::string>());
        for (const Json& t : op["tracks"]) {
            const std::string tn = t.is_string() ? t.get<std::string>() : std::string();
            if (std::find(known.begin(), known.end(), tn) == known.end()) op_fail(c, "unknown track " + t.dump() + ".", did_you_mean(tn, known) + " Tracks: " + join_names(known) + ".");
            auto at = std::find(now.begin(), now.end(), tn);
            if (muted && at == now.end()) now.push_back(tn);
            if (!muted && at != now.end()) now.erase(at);
        }
        if (now.empty()) song["sections"][si].erase("mute");
        else song["sections"][si]["mute"] = now;
        return std::string(muted ? "muted " : "unmuted ") + join_names(op["tracks"].get<std::vector<std::string>>()) + " in " + section;
    }
    if (name == "set_automation") {
        op_keys(c, op, {"track", "param", "points", "curve"});
        const std::string track = op_string(c, op, "track", false);
        if (track.empty()) apply_automation(song, c, op);
        else {
            find_track_json(song, c, track);
            apply_automation(song["tracks"][track], c, op);
        }
        const bool removed = !op.contains("points") || op["points"].is_null() || (op["points"].is_array() && op["points"].empty());
        return std::string(removed ? "removed" : "set") + " the " + op_string(c, op, "param", true) + " lane" + (track.empty() ? " of the whole song" : " of " + track);
    }
    op_fail(c, "unknown operation '" + name + "'.",
            did_you_mean(name, std::vector<std::string>{"set_song", "add_track", "set_track", "set_mixer", "set_layers", "remove_track", "set_pattern", "remove_pattern", "add_section", "set_section", "remove_section", "move_section", "arrange", "mute", "set_automation"}));
}

// Validates the document, writes it and builds the answer of a command that changed a song.
Json finish_edit(const std::string& projectDir, const Json& a, const std::string& rel, const Json& song, Json edits, const char* command) {
    SongDoc doc = check_song_json(song, rel, "Nothing was written.");
    const SongTimeline tl = expand_or_fail(doc, rel);
    write_song(projectDir, rel, song);
    Json result = Json::object({{"path", rel}, {"edits", edits}});
    Json s = summary_json(doc, tl);
    for (auto it = s.begin(); it != s.end(); ++it) result[it.key()] = it.value();
    if (arg_bool(a, "picture", false)) add_piano_roll(projectDir, a, doc, tl, result);
    Json steps = Json::array();
    steps.push_back("music.check finds notes outside the key, clashes and mud; music.info draws the piano roll; music.preview renders the sound (a preview made before this edit is now stale).");
    (void)command;
    result["nextSteps"] = steps;
    return result;
}

Json music_edit_command(const std::string& projectDir, const Json& a) {
    check_arg_keys("music.edit", a, "", {"path", "ops", "picture", "pictureOut", "width", "fromBar", "bars"});
    const std::string rel = song_path(arg_string(a, "path", true));
    Loaded loaded = load_song_file(projectDir, rel);
    if (!a.contains("ops") || !a["ops"].is_array() || a["ops"].empty())
        fail("invalid_argument", "music.edit: `ops` must be a non-empty list of operations.", "Example: {\"path\":\"" + rel + "\",\"ops\":[{\"op\":\"set_song\",\"tempo\":96},{\"op\":\"mute\",\"section\":\"intro\",\"tracks\":[\"drums\"]}]}");
    Json song = loaded.json;
    Json edits = Json::array();
    for (std::size_t i = 0; i < a["ops"].size(); ++i) {
        const Json& op = a["ops"][i];
        OpCtx c;
        c.index = i;
        if (!op.is_object() || !op.contains("op") || !op["op"].is_string())
            fail("invalid_argument", "music.edit: op " + std::to_string(i + 1) + " must be an object with an `op` name.", "Operations: set_song, add_track, set_track, set_mixer, set_layers, remove_track, set_pattern, remove_pattern, add_section, set_section, remove_section, move_section, arrange, mute, set_automation.");
        c.op = op["op"].get<std::string>();
        edits.push_back(apply_op(song, c, op));
    }
    return finish_edit(projectDir, a, rel, song, edits, "music.edit");
}

// ---------------------------------------------------------------- music.notes ---

Json music_notes_command(const std::string& projectDir, const Json& a) {
    check_arg_keys("music.notes", a, "", {"path", "track", "pattern"});
    const std::string rel = song_path(arg_string(a, "path", true));
    const Loaded loaded = load_song_file(projectDir, rel);
    const std::string trackName = arg_string(a, "track", true), patternName = arg_string(a, "pattern", true);
    const SongTrack* track = loaded.doc.find_track(trackName);
    if (!track) {
        std::vector<std::string> names;
        for (const SongTrack& t : loaded.doc.tracks) names.push_back(t.name);
        fail("invalid_argument", "music.notes: " + rel + " has no track '" + trackName + "'.", did_you_mean(trackName, names) + " Tracks: " + join_names(names) + ".");
    }
    const SongPattern* pattern = track->find_pattern(patternName);
    if (!pattern) {
        std::vector<std::string> names;
        for (const SongPattern& p : track->patterns) names.push_back(p.name);
        fail("invalid_argument", "music.notes: the track '" + trackName + "' has no pattern '" + patternName + "'.", did_you_mean(patternName, names) + " Patterns: " + join_names(names) + ".");
    }
    Json result = Json::object({{"track", trackName}, {"pattern", patternName}, {"bars", pattern->bars}, {"meter", meter_text(loaded.doc.meter)},
                                {"ticksPerQuarter", kSongPpq}, {"ticks", pattern->lengthTicks}, {"drums", track->drums}});
    if (track->drums) {
        Json hits = Json::array();
        for (const SongEvent& e : pattern->events) hits.push_back(Json::object({{"lane", e.drum}, {"tick", e.tick}, {"duration", e.duration}, {"velocity", e.velocity}, {"accent", e.accent}}));
        result["grid"] = pattern->grid;
        result["hits"] = hits;
        result["nextSteps"] = Json::array({"A drum pattern is edited as a grid: music.edit set_pattern {track, pattern, grid, step, bars}."});
        return result;
    }
    Json notes = Json::array();
    for (const SongRollNote& n : song_roll_notes(*pattern))
        notes.push_back(Json::object({{"pitch", n.pitch}, {"name", song_pitch_name(n.pitch)}, {"tick", n.tick}, {"duration", n.duration}, {"velocity", n.velocity}, {"accent", n.accent}, {"staccato", n.staccato}}));
    result["notes"] = notes;
    result["text"] = pattern->text;
    result["nextSteps"] = Json::array({"music.edit set_pattern {track, pattern, notes: <this list, changed>} writes the notes back as note text (chord names and groups become the notes they play; starts and ends round to 40 ticks)."});
    return result;
}

// ---------------------------------------------------------------- music.create ---

Json music_create_command(const std::string& projectDir, const Json& a) {
    check_arg_keys("music.create", a, "", {"path", "tempo", "meter", "key", "mode", "progression", "style", "bassStyle", "arpeggio", "swing", "doc", "seed", "overwrite", "picture", "pictureOut", "width", "fromBar", "bars"});
    const std::string rel = song_path(arg_string(a, "path", true));
    const stdfs::path file = project_file(projectDir, rel);
    std::error_code ec;
    if (!arg_bool(a, "overwrite", false) && stdfs::exists(file, ec))
        fail("exists", "'" + rel + "' already exists.", "Edit it with music.edit, or pass overwrite: true to start over.");

    const SongMeter meter = a.contains("meter") ? parse_meter_text(arg_string(a, "meter", true), "music.create") : SongMeter{};
    const std::string key = arg_string(a, "key", false, "A");
    const std::string mode = arg_string(a, "mode", false, "minor");
    const int keyRoot = parse_key_text(key, "music.create");
    check_mode_text(mode, "music.create");

    std::string style = arg_string(a, "style", false);
    if (style.empty()) style = (meter.beats == 3 && meter.unit == 4) ? "waltz" : "rock";
    const SongDrumStyle* drumStyle = nullptr;
    std::vector<std::string> styleNames;
    for (const SongDrumStyle& s : song_drum_styles()) {
        styleNames.push_back(s.name);
        if (s.name == style) drumStyle = &s;
    }
    if (!drumStyle) fail("invalid_argument", "music.create: unknown drum style '" + style + "'.", did_you_mean(style, styleNames) + " Styles: " + join_names(styleNames) + " (music.drums describes them).");

    double tempo = drumStyle->tempoLow > 0 ? double(drumStyle->tempoLow + drumStyle->tempoHigh) / 2.0 : 100.0;
    if (a.contains("tempo")) tempo = arg_double(a, "tempo", tempo, 20, 400, "music.create");

    // The default progression: the usual four chords of the mode.
    std::string progText = arg_string(a, "progression", false);
    if (progText.empty()) {
        if (mode == "minor") progText = "i VI III VII";
        else if (mode == "major") progText = "I V vi IV";
        else {
            const std::vector<std::string> chords = song_diatonic_chords(keyRoot, mode, false);
            if (chords.size() < 7) fail("invalid_argument", "music.create: the mode '" + mode + "' has no seven-note chords to build a default progression from.", "Give a `progression`, e.g. \"" + key + " " + key + "\" with chord names (music.chord lists the spellings).");
            progText = chords[0] + " " + chords[5] + " " + chords[3] + " " + chords[4];
        }
    }
    Progression prog = make_progression(progText, keyRoot, mode, meter, "music.create");

    std::string bassStyle = arg_string(a, "bassStyle", false, "root_fifth");
    {
        std::vector<std::string> names;
        for (const auto& [n, what] : song_bass_styles()) names.push_back(n);
        if (std::find(names.begin(), names.end(), bassStyle) == names.end())
            fail("invalid_argument", "music.create: unknown bassStyle '" + bassStyle + "'.", did_you_mean(bassStyle, names) + " Styles: " + join_names(names) + ".");
    }
    const bool arp = arg_bool(a, "arpeggio", true);

    SongPadOptions padOptions;
    auto pad = song_chord_pad(prog.steps, meter, padOptions);
    if (!pad) fail("failed", "music.create: " + pad.error().message, pad.error().hint);
    SongBassOptions bassOptions;
    bassOptions.style = bassStyle;
    auto bass = song_bassline(prog.steps, meter, bassOptions);
    if (!bass) fail("failed", "music.create: " + bass.error().message, bass.error().hint);
    auto drums = song_drum_pattern(style, meter, prog.bars, false);
    if (!drums) fail("invalid_argument", "music.create: " + drums.error().message, drums.error().hint);

    Json song = Json::object({{"format", kSongFormat}});
    song["doc"] = a.contains("doc") ? a["doc"] : Json(std::format("A starting point in {} {}: {} over {} bars, {} drums.", key, mode, prog.names, prog.bars, style));
    song["tempo"] = tempo;
    song["meter"] = meter_text(meter);
    song["key"] = key;
    song["mode"] = mode;
    if (a.contains("swing")) song["swing"] = a["swing"];
    if (a.contains("seed")) song["seed"] = a["seed"];
    Json tracks = Json::object();
    tracks["pad"] = Json::object({{"instrument", "pad"}, {"volume", 0.7}, {"patterns", Json::object({{"chords", *pad}})}});
    tracks["bass"] = Json::object({{"instrument", "bass"}, {"volume", 0.9}, {"patterns", Json::object({{"line", *bass}})}});
    tracks["drums"] = Json::object({{"instrument", "kit"}, {"volume", 0.8}, {"patterns", Json::object({{"groove", *drums}})}});
    Json introPlay = Json::object({{"pad", "chords"}}), loopPlay = Json::object({{"pad", "chords"}, {"bass", "line"}, {"drums", "groove"}}), outroPlay = Json::object({{"pad", "chords"}, {"bass", "line"}});
    if (arp) {
        SongArpeggioOptions o;
        o.octave = 4;
        o.velocity = 80;
        auto text = song_arpeggio(prog.steps, meter, o);
        if (!text) fail("failed", "music.create: " + text.error().message, text.error().hint);
        tracks["arp"] = Json::object({{"instrument", "pluck"}, {"volume", 0.6}, {"patterns", Json::object({{"arp", *text}})}});
        introPlay["arp"] = "arp";
        loopPlay["arp"] = "arp";
    }
    song["tracks"] = tracks;
    song["sections"] = Json::array({Json::object({{"name", "intro"}, {"kind", "intro"}, {"play", introPlay}}),
                                    Json::object({{"name", "loop"}, {"kind", "loop"}, {"repeat", 2}, {"play", loopPlay}}),
                                    Json::object({{"name", "outro"}, {"kind", "outro"}, {"play", outroPlay}})});

    SongDoc doc = check_song_json(song, rel, "music.create made an invalid song: this is a bug in the generator.");
    const SongTimeline tl = expand_or_fail(doc, rel);
    write_song(projectDir, rel, song);
    Json result = Json::object({{"path", rel}, {"created", true}, {"progression", prog.names}});
    Json s = summary_json(doc, tl);
    for (auto it = s.begin(); it != s.end(); ++it) result[it.key()] = it.value();
    if (arg_bool(a, "picture", true)) add_piano_roll(projectDir, a, doc, tl, result);
    result["nextSteps"] = Json::array({"This is a starting point to change, not a finished piece: music.edit rewrites a pattern (set_pattern), the arrangement (arrange, mute) or the tempo (set_song).",
                                       "music.check finds problems before you listen; music.preview " + rel + " renders it to a WAV."});
    return result;
}

// ---------------------------------------------------------------- helper commands ---

// Puts `value` as the pattern `pattern` of `track` in the song of `ctx`, creating the track with `instrument` when it does not exist, and
// optionally adds it to the end of what the track plays in `section`.
Json write_pattern(const std::string& projectDir, const Json& a, Context& ctx, const std::string& defTrack, const std::string& defPattern, const std::string& defInstrument, const Json& value, const char* command) {
    Loaded& loaded = *ctx.song;
    Json song = loaded.json;
    const std::string track = arg_string(a, "track", false, defTrack), pattern = arg_string(a, "pattern", false, defPattern);
    const std::string instrument = arg_string(a, "instrument", false, defInstrument);
    const bool created = !(song.contains("tracks") && song["tracks"].is_object() && song["tracks"].contains(track));
    Json& tracks = ensure_object(song, "tracks");
    if (created) tracks[track] = Json::object({{"instrument", instrument}, {"patterns", Json::object()}});
    const bool replaced = !created && ensure_object(tracks[track], "patterns").contains(pattern);
    ensure_object(tracks[track], "patterns")[pattern] = value;
    OpCtx c;
    c.op = command;
    Json edits = Json::array();
    edits.push_back(std::string(created ? "added track " + track + " (" + instrument + ") with " : replaced ? "replaced " : "added ") + "pattern " + track + "/" + pattern);
    if (a.contains("section")) {
        const std::string section = arg_string(a, "section", true);
        const std::size_t si = find_section(song, c, section);
        append_entry(song, si, track, pattern);
        edits.push_back("section " + section + ": " + pattern + " is added to what " + track + " plays");
    }
    return finish_edit(projectDir, a, loaded.rel, song, edits, command);
}

const char* const kWriteDoc = "Write the pattern into this song (a `path` under assets/ ending in .song.json): the track is created if it does not exist.";

Json music_chord_command(const std::string& projectDir, const Json& a) {
    check_arg_keys("music.chord", a, "", {"name", "progression", "path", "key", "mode", "meter", "octave"});
    const int octave = arg_int_range(a, "octave", 3, -1, 8, "music.chord");
    if (!a.contains("name") && !a.contains("progression")) {
        Json qualities = Json::array();
        for (const SongQualityInfo& q : song_chord_qualities()) {
            std::vector<std::string> iv;
            for (int i : q.intervals) iv.push_back(std::to_string(i));
            qualities.push_back(Json::object({{"suffix", q.spelling}, {"intervals", join(iv, " ")}, {"what", q.what}}));
        }
        return Json::object({{"qualities", qualities},
                             {"nextSteps", Json::array({"Give a chord name: {\"name\":\"Am7\",\"octave\":3} returns its notes, MIDI numbers and the text for a pattern; {\"progression\":\"i VI III VII\",\"key\":\"A\",\"mode\":\"minor\"} spells a progression."})}});
    }
    if (a.contains("name") && a.contains("progression")) fail("invalid_argument", "music.chord: give `name` (one chord) or `progression` (several), not both.", "Example: {\"name\":\"Cmaj7/G\"} or {\"progression\":\"Am F C G\"}.");
    auto chord_json = [&](const SongChord& chord) {
        const std::vector<int> pitches = song_chord_pitches(chord, octave);
        Json notes = Json::array(), midi = Json::array();
        std::string bracket;
        for (int p : pitches) {
            notes.push_back(song_pitch_name(p, song_prefers_flats(chord.root, "major")));
            midi.push_back(p);
            bracket += (bracket.empty() ? "" : " ") + song_pitch_name(p);
        }
        std::vector<std::string> iv;
        for (int i : chord.intervals) iv.push_back(std::to_string(i));
        return Json::object({{"name", chord.name}, {"notes", notes}, {"midi", midi}, {"intervals", join(iv, " ")}, {"byName", "(" + chord.name + "@" + std::to_string(octave) + ")"}, {"asNotes", "[" + bracket + "]"}});
    };
    if (a.contains("name")) {
        auto chord = song_parse_chord(arg_string(a, "name", true));
        if (!chord) fail("invalid_argument", "music.chord: " + chord.error().message, chord.error().hint);
        Json result = chord_json(*chord);
        result["nextSteps"] = Json::array({"In note text write the chord as " + result["byName"].get<std::string>() + ":2 (it follows the song's meter and any `transpose`), or spell the notes " + result["asNotes"].get<std::string>() + ":2."});
        return result;
    }
    Context ctx = read_context(projectDir, a, "music.chord");
    Progression prog = make_progression(arg_string(a, "progression", true), ctx.keyRoot, ctx.mode, ctx.meter, "music.chord");
    Json chords = Json::array();
    for (const SongChordStep& s : prog.steps) {
        Json j = chord_json(s.chord);
        j["bars"] = num(double(s.ticks) / double(ctx.meter.barTicks()), 2);
        chords.push_back(j);
    }
    SongPadOptions po;
    po.octave = octave;
    auto pad = song_chord_pad(prog.steps, ctx.meter, po);
    Json result = Json::object({{"progression", prog.names}, {"key", ctx.key}, {"mode", ctx.mode}, {"meter", meter_text(ctx.meter)}, {"bars", prog.bars}, {"chords", chords}});
    if (pad) result["pad"] = *pad;
    result["nextSteps"] = Json::array({"`pad` is the progression as sustained chords: music.edit set_pattern {\"track\":\"pad\",\"pattern\":\"chords\",\"notes\": <pad>} puts it in a song; music.arpeggio and music.bassline play the same chords."});
    return result;
}

std::string roman_label(int degree, const std::string& chordName) {
    static const char* const numerals[] = {"I", "II", "III", "IV", "V", "VI", "VII"};
    std::string n = numerals[std::clamp(degree, 0, 6)];
    auto chord = song_parse_chord(chordName);
    if (!chord) return n;
    std::string q = chord->quality;
    const bool minorThird = chord->intervals.size() > 1 && chord->intervals[1] == 3;
    if (minorThird) {
        std::transform(n.begin(), n.end(), n.begin(), [](unsigned char ch) { return char(std::tolower(ch)); });
        if (starts_with(q, "m") && !starts_with(q, "maj")) q = q.substr(1);
    }
    return n + q;
}

Json music_scale_command(const std::string&, const Json& a) {
    check_arg_keys("music.scale", a, "", {"key", "mode"});
    if (!a.contains("key") && !a.contains("mode")) {
        Json scales = Json::array();
        for (const SongScaleInfo& s : song_scales()) {
            std::vector<std::string> iv;
            for (int i : s.intervals) iv.push_back(std::to_string(i));
            scales.push_back(Json::object({{"mode", s.name}, {"intervals", join(iv, " ")}, {"notes", s.intervals.size()}, {"what", s.what}}));
        }
        return Json::object({{"scales", scales}, {"nextSteps", Json::array({"Give a key and a mode: {\"key\":\"D\",\"mode\":\"dorian\"} returns its notes and the chords on each degree."})}});
    }
    const std::string key = arg_string(a, "key", false, "C"), mode = arg_string(a, "mode", false, "major");
    const int root = parse_key_text(key, "music.scale");
    check_mode_text(mode, "music.scale");
    const bool flats = song_prefers_flats(root, mode);
    auto pcs = song_scale_pitch_classes(root, mode);
    Json notes = Json::array(), classes = Json::array();
    for (int pc : *pcs) {
        notes.push_back(song_pitch_class_name(pc, flats));
        classes.push_back(pc);
    }
    std::vector<std::string> iv;
    for (const SongScaleInfo& s : song_scales())
        if (s.name == mode)
            for (int i : s.intervals) iv.push_back(std::to_string(i));
    Json result = Json::object({{"key", key}, {"mode", mode}, {"notes", notes}, {"pitchClasses", classes}, {"intervals", join(iv, " ")}, {"spelling", flats ? "flats" : "sharps"}});
    for (const bool sevenths : {false, true}) {
        const std::vector<std::string> chords = song_diatonic_chords(root, mode, sevenths);
        Json list = Json::array();
        for (std::size_t i = 0; i < chords.size(); ++i) list.push_back(Json::object({{"degree", i + 1}, {"roman", roman_label(int(i), chords[i])}, {"chord", chords[i]}}));
        if (!list.empty()) result[sevenths ? "sevenths" : "triads"] = list;
    }
    if (!result.contains("triads")) result["note"] = "A scale of " + std::to_string(pcs->size()) + " notes has no triads on its degrees; use the notes directly.";
    result["nextSteps"] = Json::array({"A progression in Roman numerals works in any command: {\"progression\":\"i VI III VII\",\"key\":\"" + key + "\",\"mode\":\"" + mode + "\"}. A note outside these is flagged by music.check (off_key)."});
    return result;
}

Json music_arpeggio_command(const std::string& projectDir, const Json& a) {
    check_arg_keys("music.arpeggio", a, "", {"progression", "path", "track", "pattern", "instrument", "section", "key", "mode", "meter", "direction", "octaves", "rate", "triplet", "octave", "velocity", "accent", "staccato", "seed", "picture", "pictureOut", "width", "fromBar", "bars"});
    Context ctx = read_context(projectDir, a, "music.arpeggio");
    Progression prog = make_progression(arg_string(a, "progression", true), ctx.keyRoot, ctx.mode, ctx.meter, "music.arpeggio");
    SongArpeggioOptions o;
    o.direction = arg_string(a, "direction", false, "up");
    o.octaves = arg_int_range(a, "octaves", 1, 1, 4, "music.arpeggio");
    o.rate = arg_int_range(a, "rate", 16, 4, 32, "music.arpeggio");
    o.triplet = arg_bool(a, "triplet", false);
    o.octave = arg_int_range(a, "octave", 3, 0, 7, "music.arpeggio");
    o.velocity = arg_int_range(a, "velocity", 90, 1, 127, "music.arpeggio");
    o.accent = arg_bool(a, "accent", true);
    o.staccato = arg_bool(a, "staccato", false);
    o.seed = std::uint64_t(arg_int(a, "seed", 0));
    auto text = song_arpeggio(prog.steps, ctx.meter, o);
    if (!text) fail("invalid_argument", "music.arpeggio: " + text.error().message, text.error().hint);
    if (!ctx.song) {
        return Json::object({{"progression", prog.names}, {"bars", prog.bars}, {"notes", *text},
                             {"nextSteps", Json::array({"Use it as a pattern: music.edit set_pattern {\"track\":\"arp\",\"pattern\":\"arp\",\"notes\": <notes>}, or pass `path` (and `section`) to write it into a song."})}});
    }
    Json result = write_pattern(projectDir, a, ctx, "arp", "arp", "pluck", Json(*text), "music.arpeggio");
    result["notes"] = *text;
    return result;
}

Json music_bassline_command(const std::string& projectDir, const Json& a) {
    check_arg_keys("music.bassline", a, "", {"progression", "path", "track", "pattern", "instrument", "section", "key", "mode", "meter", "style", "octave", "rate", "velocity", "picture", "pictureOut", "width", "fromBar", "bars"});
    Context ctx = read_context(projectDir, a, "music.bassline");
    Progression prog = make_progression(arg_string(a, "progression", true), ctx.keyRoot, ctx.mode, ctx.meter, "music.bassline");
    SongBassOptions o;
    o.style = arg_string(a, "style", false, "root_fifth");
    o.octave = arg_int_range(a, "octave", 2, 0, 5, "music.bassline");
    o.rate = arg_int_range(a, "rate", 0, 0, 8, "music.bassline");
    o.velocity = arg_int_range(a, "velocity", 100, 1, 127, "music.bassline");
    std::vector<std::string> names;
    for (const auto& [n, what] : song_bass_styles()) names.push_back(n);
    if (std::find(names.begin(), names.end(), o.style) == names.end())
        fail("invalid_argument", "music.bassline: unknown style '" + o.style + "'.", did_you_mean(o.style, names) + " Styles: " + join_names(names) + ".");
    auto text = song_bassline(prog.steps, ctx.meter, o);
    if (!text) fail("invalid_argument", "music.bassline: " + text.error().message, text.error().hint);
    if (!ctx.song) {
        return Json::object({{"progression", prog.names}, {"bars", prog.bars}, {"notes", *text},
                             {"nextSteps", Json::array({"Use it as a pattern: music.edit set_pattern {\"track\":\"bass\",\"pattern\":\"line\",\"notes\": <notes>}, or pass `path` (and `section`) to write it into a song."})}});
    }
    Json result = write_pattern(projectDir, a, ctx, "bass", "bass", "bass", Json(*text), "music.bassline");
    result["notes"] = *text;
    return result;
}

Json music_drums_command(const std::string& projectDir, const Json& a) {
    check_arg_keys("music.drums", a, "", {"style", "bars", "fill", "path", "track", "pattern", "section", "meter", "picture", "pictureOut", "width", "fromBar", "bars"});
    if (!a.contains("style")) {
        Json styles = Json::array();
        for (const SongDrumStyle& s : song_drum_styles())
            styles.push_back(Json::object({{"style", s.name}, {"what", s.what}, {"meter", s.meter}, {"tempo", std::format("{} to {} bpm", s.tempoLow, s.tempoHigh)}}));
        Json lanes = Json::array();
        for (const SongDrumLane& l : song_drum_lanes()) lanes.push_back(Json::object({{"lane", l.name}, {"what", l.what}}));
        return Json::object({{"styles", styles}, {"lanes", lanes}, {"nextSteps", Json::array({"Pick a style: {\"style\":\"rock\",\"bars\":4,\"fill\":true}; add `path` and `section` to write it into a song."})}});
    }
    Context ctx = read_context(projectDir, a, "music.drums");
    const std::string style = arg_string(a, "style", true);
    std::vector<std::string> names;
    for (const SongDrumStyle& s : song_drum_styles()) names.push_back(s.name);
    if (std::find(names.begin(), names.end(), style) == names.end())
        fail("invalid_argument", "music.drums: unknown style '" + style + "'.", did_you_mean(style, names) + " Styles: " + join_names(names) + ".");
    const int bars = arg_int_range(a, "bars", 1, 1, 64, "music.drums");
    auto pattern = song_drum_pattern(style, ctx.meter, bars, arg_bool(a, "fill", false));
    if (!pattern) fail("invalid_argument", "music.drums: " + pattern.error().message, pattern.error().hint);
    if (!ctx.song) {
        return Json::object({{"style", style}, {"bars", bars}, {"meter", meter_text(ctx.meter)}, {"pattern", *pattern},
                             {"nextSteps", Json::array({"Use it: music.edit set_pattern {\"track\":\"drums\",\"pattern\":\"groove\",\"grid\": <pattern.grid>,\"step\": <pattern.step>} on a track with instrument \"kit\"; or pass `path` to write it."})}});
    }
    Json picture = a;  // `bars` is the pattern's length here, not the picture's
    picture.erase("bars");
    Json result = write_pattern(projectDir, picture, ctx, "drums", "groove", "kit", *pattern, "music.drums");
    result["pattern"] = *pattern;
    return result;
}

// ---------------------------------------------------------------- music.instrument ---

Json music_instrument_command(const std::string& projectDir, const Json& a) {
    check_arg_keys("music.instrument", a, "", {"name", "path", "overwrite"});
    if (!a.contains("name")) {
        Json built = Json::array();
        for (const SongInstrumentInfo& i : song_instruments())
            built.push_back(Json::object({{"name", i.name}, {"family", i.family}, {"what", i.what}, {"range", song_pitch_name(i.low) + " to " + song_pitch_name(i.high)}, {"voices", i.voices}}));
        Json families = Json::array();
        for (const SongInstrumentFamily& f : song_instrument_families()) {
            Json names = Json::array();
            for (const SongInstrumentInfo& i : song_instruments())
                if (i.family == f.name) names.push_back(i.name);
            families.push_back(Json::object({{"family", f.name}, {"what", f.what}, {"instruments", names}}));
        }
        Json kits = Json::array();
        for (const SongKitInfo& k : song_kits()) kits.push_back(Json::object({{"kit", k.name}, {"instrument", k.instrument}, {"what", k.what}}));
        Json lanes = Json::array();
        for (const SongDrumLane& l : song_drum_lanes()) lanes.push_back(Json::object({{"name", "kit:" + l.name}, {"lane", l.name}, {"what", l.what}}));
        Json presets = Json::array();
        for (const SfxPresetInfo& p : sfx_presets()) presets.push_back(p.name);
        Json patches = Json::array();
        Json fonts = Json::array();
        std::error_code ec;
        const stdfs::path root = stdfs::path(projectDir) / "assets";
        if (stdfs::is_directory(root, ec)) {
            std::vector<std::string> found, foundFonts;
            for (stdfs::recursive_directory_iterator it(root, stdfs::directory_options::skip_permission_denied, ec), end; !ec && it != end; it.increment(ec))
                if (it->is_regular_file(ec)) {
                    const std::string rel = stdfs::relative(it->path(), projectDir, ec).generic_string();
                    if (ends_with(to_lower(rel), ".sfx.json")) found.push_back(rel);
                    else if (ends_with(to_lower(rel), ".sf2")) foundFonts.push_back(rel);
                }
            std::sort(found.begin(), found.end());
            std::sort(foundFonts.begin(), foundFonts.end());
            for (const std::string& f : found) patches.push_back(f);
            for (const std::string& f : foundFonts) fonts.push_back(f);
        }
        return Json::object({{"instruments", built}, {"families", families}, {"kits", kits}, {"kitLanes", lanes}, {"sfxPresets", presets}, {"projectPatches", patches}, {"soundfonts", fonts},
                             {"nextSteps", Json::array({"A track's `instrument` is one of these names (\"kit\" for drums, \"kit:electronic\" or \"kit:chiptune\" for the other kits), an sfx preset name, or the path of a .sfx.json. To change one, copy its patch: {\"name\":\"pluck\",\"path\":\"assets/audio/my_pluck.sfx.json\"}, edit the numbers (sfx.tweak) and point the track at the file.",
                                                        "A SoundFont (.sf2) in the project plays as {\"soundfont\": \"assets/audio/piano.sf2\", \"preset\": \"Grand Piano\"}; music.instrument with its path as `name` lists its presets."})}});
    }
    std::string name = arg_string(a, "name", true);
    if (ends_with(to_lower(name), ".sf2")) {
        if (a.contains("path")) fail("invalid_argument", "music.instrument: `path` writes a patch, and a SoundFont is not one.", "Drop `path`: a track plays the .sf2 as it is ({\"soundfont\": \"" + name + "\", \"preset\": ...}).");
        auto norm = fs::normalize_checked(name);
        if (!norm.ok() || norm->empty() || !starts_with(*norm, "assets/"))
            fail("invalid_argument", "music.instrument: the SoundFont '" + name + "' must be a project path under assets/.", "Example: \"assets/audio/piano.sf2\".");
        Result<Soundfont> font = [&] {
            ProjectRootGuard root(projectDir);
            return Soundfont::load(*norm);
        }();
        if (!font.ok()) fail("not_found", "music.instrument: " + font.error().message, font.error().hint);
        Json list = Json::array();
        for (const SoundfontPreset& p : font->presets())
            list.push_back(Json::object({{"name", p.name}, {"bank", p.bank}, {"program", p.program}, {"drums", p.bank == 128}}));
        Json result = Json::object({{"soundfont", *norm}, {"presets", list}});
        if (!font->presets().empty()) {
            const SoundfontPreset& first = font->presets().front();
            result["nextSteps"] = Json::array({"Point a track at one: music.edit set_track {\"track\":\"keys\",\"instrument\":{\"soundfont\":\"" + *norm + "\",\"preset\":\"" + first.name + "\"}} (or the shorthand \"" + *norm + "#" + first.name +
                                               "\"). A preset in bank 128 is a drum kit: use it on a track with a drum pattern, and each lane plays its General MIDI key."});
        }
        return result;
    }
    if (auto variant = song_kit_variant(name); variant && !a.contains("path")) {
        // A whole kit: its lanes and the name of each lane's patch (music.instrument <that name> shows the patch).
        const std::string prefix = *variant == "acoustic" ? "kit:" : "kit:" + *variant + ":";
        Json laneList = Json::array();
        for (const SongDrumLane& l : song_drum_lanes()) laneList.push_back(Json::object({{"lane", l.name}, {"what", l.what}, {"patch", prefix + l.name}}));
        std::string what;
        for (const SongKitInfo& k : song_kits())
            if (k.name == *variant) what = k.what;
        return Json::object({{"kit", *variant}, {"instrument", name}, {"what", what}, {"lanes", laneList},
                             {"nextSteps", Json::array({"A drum track writes \"instrument\": \"" + name + "\" and grids by lane name. `music.instrument` with a lane's `patch` shows the sound and, with `path`, copies it to a .sfx.json that a track's `kit` can replace the lane with."})}});
    }
    std::string lookup = name;
    std::vector<std::string> all;
    for (const SongInstrumentInfo& i : song_instruments()) all.push_back(i.name);
    for (const SongDrumLane& l : song_drum_lanes()) all.push_back("kit:" + l.name);
    if (!song_instrument_patch(lookup) && !starts_with(lookup, "kit:")) lookup = "kit:" + lookup;
    auto patch = song_instrument_patch(lookup);
    if (!patch) fail("not_found", "There is no built-in instrument or drum lane '" + name + "'.", did_you_mean(name, all) + " Built-in: " + join_names(all) + ".");
    Json result = Json::object({{"name", lookup}, {"patch", *patch}});
    if (auto range = song_instrument_range(lookup)) result["range"] = song_pitch_name(range->first) + " to " + song_pitch_name(range->second);
    if (a.contains("path")) {
        std::string rel = arg_string(a, "path", true);
        auto norm = fs::normalize_checked(rel);
        if (!norm.ok() || norm->empty() || !starts_with(*norm, "assets/") || !ends_with(to_lower(*norm), ".sfx.json"))
            fail("invalid_argument", "music.instrument: `path` '" + rel + "' must be a .sfx.json under assets/.", "Example: \"assets/audio/my_pluck.sfx.json\".");
        const stdfs::path file = project_file(projectDir, *norm);
        std::error_code ec;
        if (!arg_bool(a, "overwrite", false) && stdfs::exists(file, ec)) fail("exists", "'" + *norm + "' already exists.", "Pass overwrite: true to replace it, or choose another path.");
        std::string err;
        if (!tooling_detail::write_file(file, dump_json(*patch), &err)) fail("failed", "Cannot write '" + *norm + "': " + err, "Check that the folder is writable.");
        result["wrote"] = *norm;
        result["nextSteps"] = Json::array({"Point a track at it: music.edit set_track {\"track\":\"lead\",\"instrument\":\"" + *norm + "\"}. sfx.tweak and sfx.render change and hear the patch; a pitched instrument is played at each note's pitch."});
    } else {
        result["nextSteps"] = Json::array({"This is the patch behind the name (docs/SOUND.md). Add `path` to copy it into the project as a .sfx.json you can change."});
    }
    return result;
}

}  // namespace

void register_music_edit_commands(CommandRegistry& registry, const std::string& projectDir) {
    const Json pictureArgs = obj({{"picture", boolean("Return the piano-roll picture (`$image`) of the song after the change.", false)},
                                  {"pictureOut", str("Also keep the picture's PNG at this project path (ends in .png).")},
                                  {"width", integer("Width of the picture in pixels (default 1000).", 400, 2400)},
                                  {"fromBar", integer("First bar shown in the picture (default 1).", 1, kSongMaxBars)},
                                  {"bars", integer("Number of bars shown (default: to the end).", 1, kSongMaxBars)}});
    auto with_picture = [&](Json props) {
        for (auto it = pictureArgs.begin(); it != pictureArgs.end(); ++it)
            if (!props.contains(it.key())) props[it.key()] = it.value();
        return props;
    };
    auto schema = [](Json props, std::vector<std::string> required = {}) {
        Json s = Json::object({{"type", "object"}, {"additionalProperties", false}, {"properties", props}});
        if (!required.empty()) s["required"] = required;
        return s;
    };
    auto add = [&](const char* name, bool readOnly, const char* summary, const std::string& description, Json inputSchema, Json (*fn)(const std::string&, const Json&)) {
        CommandInfo info;
        info.name = name;
        info.category = "assets";
        info.readOnly = readOnly;
        info.summary = summary;
        info.description = description;
        info.inputSchema = std::move(inputSchema);
        registry.add(info, [projectDir, fn](const Json& args) { return fn(projectDir, args.is_null() ? Json::object() : args); });
    };
    const Json pathArg = str("The song, project-relative, under assets/ and ending in .song.json, e.g. \"assets/music/theme.song.json\".");
    const Json writeArgs = obj({{"path", str(kWriteDoc)},
                                {"track", str("Track the pattern goes in (created with `instrument` when it does not exist).")},
                                {"pattern", str("Name of the pattern.")},
                                {"section", str("Also add the pattern to the end of what the track plays in this section, so it sounds.")}});
    auto merged = [](Json a, const Json& b) {
        for (auto it = b.begin(); it != b.end(); ++it) a[it.key()] = it.value();
        return a;
    };

    add("music.create", false, "Write a new song document: pad, bass, drums and an arpeggio over a chord progression, with intro, loop and outro.",
        "Makes a complete, valid starting song at `path` (assets/..., ending in .song.json): a pad playing the chords, a bassline, a drum groove in a style and (unless arpeggio is false) a plucked arpeggio; sections intro, loop (twice) and outro. "
        "It is a starting point to change with music.edit, not a finished piece. `progression` is chord names (\"Am F C G\") or Roman numerals in the key (\"i VI III VII\"; `*2` holds a chord two bars). Defaults: tempo from the drum style's usual range, "
        "4/4, key A minor, progression \"i VI III VII\" (minor) or \"I V vi IV\" (major), style rock (waltz in 3/4), bass root_fifth. Fails with `exists` when the file is there unless overwrite is true. Returns the song's summary and a piano-roll "
        "picture (`$image`). Example: {\"path\":\"assets/music/theme.song.json\",\"key\":\"D\",\"mode\":\"dorian\",\"tempo\":96,\"style\":\"funk\"}",
        schema(with_picture(obj({{"path", pathArg},
                                 {"picture", boolean("Return the piano-roll picture (`$image`) of the new song.", true)},
                                 {"tempo", number("Quarter notes per minute, 20 to 400. Default: the middle of the drum style's usual range.", 20, 400)},
                                 {"meter", str("Meter such as \"4/4\", \"3/4\" or \"6/8\". Default 4/4.")},
                                 {"key", str("Key, a note name such as \"A\", \"F#\" or \"Bb\". Default A.")},
                                 {"mode", str("Scale: major, minor, dorian, phrygian, lydian, mixolydian, ... (music.scale lists them). Default minor.")},
                                 {"progression", str("Chords by name (\"Am F C G\", \"Am7 | Fmaj7\") or Roman numerals in the key (\"i VI III VII\"); *N holds a chord N bars. Default: the usual four chords of the mode.")},
                                 {"style", str("Drum style (music.drums lists them): rock, funk, waltz, ... Default rock, or waltz in 3/4.")},
                                 {"bassStyle", str("Bassline style: root, root_fifth, octave or walking. Default root_fifth.")},
                                 {"arpeggio", boolean("Add a plucked arpeggio track.", true)},
                                 {"swing", number("Swing from 0 (straight) to 1 (triplet feel).", 0, 1)},
                                 {"doc", str("A sentence about the song, stored in the document.")},
                                 {"seed", Json::object({{"type", "integer"}, {"minimum", 0}, {"description", "The song's seed (the take of random hits and arpeggios)."}})},
                                 {"overwrite", boolean("Replace the file when it exists.", false)}})),
                    {"path"}),
        music_create_command);

    add("music.edit", false, "Change a song document: tempo, tracks, patterns, sections, the arrangement, mutes and automation, checked before anything is written.",
        "Applies `ops` in order to the song at `path` and writes it, but only if the result is a valid song "
        "(otherwise it fails with `invalid_song`, every problem in data.issues, and the file is untouched). "
        "Example: "
        "{\"path\":\"assets/music/theme.song.json\",\"ops\":[{\"op\":\"set_pattern\",\"track\":\"bass\",\"pattern\":\"line\",\"notes\":\"A2:8 "
        "A2 E3 A2 | G2:8 G2 D3 G2\"},{\"op\":\"mute\",\"section\":\"intro\",\"tracks\":[\"drums\"]}]}"
        FA_COMMAND_DETAILS
        "Each op is an object with `op` and its fields: set_song {tempo, meter, key, mode, swing, swingGrid, "
        "seed, volume, doc} (null removes a field); add_track {track, instrument, volume, pan, mute, solo, "
        "voices, effects, sends, transpose, swing, range, kit, patterns, automation, play}; set_track "
        "{track, name (renames and updates the sections), instrument (a name, a .sfx.json, \"x.sf2#Preset\" "
        "or {soundfont, preset, bank}), volume, pan, mute, solo, voices, effects, sends, transpose, swing, "
        "range, kit, automation} (null removes); set_mixer {buses: {name: {volume, pan, mute, effects} | "
        "null}, master: {effects, limiter, loudness}} (docs/MUSIC.md \"Mixer\"; a bus merges field by field, "
        "null removes a bus or a field); set_layers {layers: {name: [tracks] | {tracks, intensity, doc} | "
        "null}} (the groups of tracks music.render writes as stems and a layered player brings in; "
        "docs/MUSIC.md \"Layers\"); remove_track {track} (and every mention in the sections); set_pattern "
        "{track, pattern, notes (note text, or a list of {pitch, tick, duration, velocity, accent, staccato} "
        "that is written as note text) | grid+step+bars, play}; remove_pattern {track, pattern} (and its "
        "uses in the sections); add_section {section, kind (intro, loop, outro, section), repeat, bars, "
        "mute, play, index}; set_section {section, name, kind, repeat, bars, mute, play} (play changes only "
        "the tracks named, null stops one); remove_section {section}; move_section {section, index}; arrange "
        "{section, track, entries} (\"a a b*2 rest\", a list, or null to stop the track in that section); "
        "mute {section, tracks, muted}; set_automation {track (omit for the whole song), param (volume, pan, "
        "filter, macro.<name>), points [[beat, value], ...], curve (linear, step, smooth)} (no points "
        "removes the lane). `play` in add_track and set_pattern is {section: entries} to place the pattern "
        "at once. Note text is in docs/MUSIC.md. Returns the song's summary and what each op did.",
        schema(with_picture(obj({{"path", pathArg},
                                 {"ops", Json::object({{"type", "array"}, {"minItems", 1}, {"items", Json::object({{"type", "object"}, {"additionalProperties", true}, {"description", "One operation: `op` and its fields (see the command's description)."}, {"required", Json::array({"op"})},
                                                                                                                      {"properties", obj({{"op", Json::object({{"type", "string"}, {"enum", Json::array({"set_song", "add_track", "set_track", "set_mixer", "set_layers", "remove_track", "set_pattern", "remove_pattern", "add_section", "set_section", "remove_section", "move_section", "arrange", "mute", "set_automation"})}, {"description", "What to do."}})}})}})},
                                                    {"description", "The operations, applied in order."}})}})),
               {"path", "ops"}),
        music_edit_command);

    add("music.notes", true, "List the notes of one pitched pattern of a song (pitch, tick, duration, velocity), or the hits of a drum pattern, as a piano roll sees them.",
        "Reads the pattern `pattern` of `track` in the song at `path` and returns its notes sorted by start: `pitch` (MIDI, 60 is C4), `name`, `tick` and `duration` (960 ticks per quarter note, from the start of the pattern), `velocity`, `accent` and `staccato`; "
        "a chord is one note per pitch. `text` is the note text as written. The list goes back through music.edit set_pattern with `notes` as a list (changing, adding or removing notes), which writes it as note text again. A drum pattern returns its `grid` and `hits`. "
        "Example: {\"path\":\"assets/music/theme.song.json\",\"track\":\"bass\",\"pattern\":\"line\"}",
        schema(obj({{"path", pathArg}, {"track", str("The track.")}, {"pattern", str("The pattern of that track.")}}), {"path", "track", "pattern"}),
        music_notes_command);

    add("music.instrument", false, "List the built-in song instruments (by family), the drum kits and lanes, sfx presets and project SoundFonts, show the patch behind an instrument, or list a SoundFont's presets.",
        "Without `name` it lists what a track's `instrument` can be: the built-in pitched instruments (with family, note range and polyphony), the drum kits (acoustic \"kit\", \"kit:electronic\", \"kit:chiptune\") and their lanes (\"kit:kick\"), the sfx presets, the .sfx.json patches and the .sf2 SoundFonts in the project. "
        "With `name` set to a .sf2 path under assets/ it lists that SoundFont's presets (name, bank, program) so a track can name one. With `name` set to a built-in it returns that instrument's "
        "patch (the JSON of a .sfx.json, docs/SOUND.md; a bare lane name like \"kick\" works) and, with `path`, writes it to a .sfx.json under assets/ so you can change the numbers and point a track at the copy. A pitched patch is played once per note, "
        "re-pitched to the note. Example: {\"name\":\"pluck\",\"path\":\"assets/audio/my_pluck.sfx.json\"}",
        schema(obj({{"name", str("A built-in instrument (\"pluck\"), a drum lane (\"kit:kick\", \"kit:electronic:kick\" or \"kick\") or a project .sf2 (\"assets/audio/piano.sf2\": lists its presets). Omit to list them all.")},
                    {"path", str("Write the patch here (a .sfx.json under assets/).")},
                    {"overwrite", boolean("Replace the file at `path` when it exists.", false)}})),
        music_instrument_command);

    add("music.chord", true, "Spell a chord by name, or a chord progression in a key: notes, MIDI numbers and the note text to paste.",
        "With `name` (\"Am7\", \"Cmaj7/G\", \"F#dim\", \"Dsus4\") it returns the chord's notes at `octave`, their MIDI numbers, the interval list and the two ways to write it in note text. With `progression` (names, or Roman numerals in `key` and `mode`, or those of the "
        "song at `path`) it returns every chord and `pad`, the progression as sustained chords. With no arguments it lists the chord qualities the notation knows. Example: {\"progression\":\"i VI III VII\",\"key\":\"A\",\"mode\":\"minor\"}",
        schema(obj({{"name", str("One chord: root, quality, optional /bass. Omit to list qualities.")},
                    {"progression", str("Chord names or Roman numerals; *N holds a chord N bars.")},
                    {"path", str("Read meter, key and mode from this song.")},
                    {"key", str("Key for Roman numerals. Default C, or the song's.")},
                    {"mode", str("Scale for Roman numerals. Default major, or the song's.")},
                    {"meter", str("Meter such as \"4/4\". Default 4/4, or the song's.")},
                    {"octave", integer("Octave of the chord's root (C4 is middle C). Default 3.", -1, 8)}})),
        music_chord_command);

    add("music.scale", true, "Say which notes a scale or mode has and the chords built on its degrees (with Roman numerals).",
        "With `key` and `mode` returns the scale's notes, intervals, and the triads and seventh chords on every degree labelled with Roman numerals (the same names a progression accepts). With no arguments it lists every scale the notation knows. "
        "Example: {\"key\":\"D\",\"mode\":\"dorian\"}",
        schema(obj({{"key", str("Tonic, a note name such as \"A\" or \"Bb\". Default C.")}, {"mode", str("Scale name: major, minor, dorian, ... Default major.")}})),
        music_scale_command);

    add("music.arpeggio", false, "Make an arpeggio over a chord progression as note text, and optionally put it in a song.",
        "Spells the chords of `progression` one note after another, in a direction (up, down, updown, downup, random), over 1 to 4 octaves, at a rate, with the first note of each beat accented. Returns the note text. With `path` it also writes the text as a "
        "pattern (default track \"arp\", pattern \"arp\", instrument pluck; created when missing), and with `section` adds it to what the track plays there; meter, key and mode come from the song. "
        "Example: {\"progression\":\"Am F C G\",\"direction\":\"updown\",\"octaves\":2,\"path\":\"assets/music/theme.song.json\",\"section\":\"loop\"}",
        schema(with_picture(merged(writeArgs, obj({{"progression", str("Chord names or Roman numerals (in `key`/`mode`); *N holds a chord N bars.")},
                                                   {"instrument", str("Instrument of the track when it is created. Default pluck.")},
                                                   {"key", str("Key for Roman numerals. Default C, or the song's.")},
                                                   {"mode", str("Scale for Roman numerals. Default major, or the song's.")},
                                                   {"meter", str("Meter. Default 4/4, or the song's.")},
                                                   {"direction", str("up, down, updown, downup or random. Default up.")},
                                                   {"octaves", integer("Octaves the chord is stacked over, 1 to 4. Default 1.", 1, 4)},
                                                   {"rate", integer("Note value of a step: 4, 8, 16 or 32. Default 16.", 4, 32)},
                                                   {"triplet", boolean("Steps are triplets of the rate.", false)},
                                                   {"octave", integer("Octave of the chords' roots. Default 3.", 0, 7)},
                                                   {"velocity", integer("Note velocity 1 to 127. Default 90.", 1, 127)},
                                                   {"accent", boolean("Accent the first note of every beat.", true)},
                                                   {"staccato", boolean("Short notes.", false)},
                                                   {"seed", Json::object({{"type", "integer"}, {"minimum", 0}, {"description", "Direction random: the same seed gives the same notes."}})}}))),
               {"progression"}),
        music_arpeggio_command);

    add("music.bassline", false, "Make a bassline over a chord progression as note text, and optionally put it in a song.",
        "A bass part from the progression: root (a note per beat on the root), root_fifth, octave (eighths jumping an octave) or walking (stepwise toward the next chord). Returns the note text. With `path` it writes it as a pattern "
        "(default track \"bass\", pattern \"bass\", instrument bass; created when missing) and, with `section`, plays it there. Example: {\"progression\":\"i VI III VII\",\"key\":\"A\",\"mode\":\"minor\",\"style\":\"walking\"}",
        schema(with_picture(merged(writeArgs, obj({{"progression", str("Chord names or Roman numerals (in `key`/`mode`); *N holds a chord N bars.")},
                                                   {"instrument", str("Instrument of the track when it is created. Default bass.")},
                                                   {"key", str("Key for Roman numerals. Default C, or the song's.")},
                                                   {"mode", str("Scale for Roman numerals. Default major, or the song's.")},
                                                   {"meter", str("Meter. Default 4/4, or the song's.")},
                                                   {"style", str("root, root_fifth, octave or walking. Default root_fifth.")},
                                                   {"octave", integer("Octave of C for the bass. Default 2.", 0, 5)},
                                                   {"rate", integer("Note value: 4 or 8; 0 = the style's own.", 0, 8)},
                                                   {"velocity", integer("Note velocity 1 to 127. Default 100.", 1, 127)}}))),
               {"progression"}),
        music_bassline_command);

    add("music.drums", false, "Make a drum pattern in a style (rock, funk, waltz, ...), and optionally put it in a song.",
        "Without `style` it lists the styles and the kit's lanes. With one it returns a drum pattern ({\"grid\": {lane: steps}, \"step\": \"16\"}) of `bars` bars, with a tom fill on the last beat if `fill` is set. With `path` it writes it as a pattern "
        "(default track \"drums\", pattern \"groove\", instrument kit; created when missing) and with `section` plays it there; the meter comes from the song. A style written for 4/4 fails in 3/4 and says so. Example: {\"style\":\"funk\",\"bars\":2,\"fill\":true}",
        schema(with_picture(merged(writeArgs, obj({{"style", str("Style name. Omit to list the styles.")},
                                                   {"bars", integer("Bars in the pattern. Default 1.", 1, 64)},
                                                   {"fill", boolean("Make the last beat of the last bar a tom fill.", false)},
                                                   {"meter", str("Meter. Default 4/4, or the song's.")}})))),
        music_drums_command);
}

}  // namespace fa::assets_detail::music
