#include "fa/audio/song_midi.h"

#include <algorithm>
#include <cmath>
#include <format>
#include <map>
#include <set>

#include "fa/audio/song_instruments.h"
#include "fa/audio/song_theory.h"
#include "fa/audio/soundfont.h"
#include "fa/core/strings.h"

namespace fa {

namespace {

// ---- General MIDI ------------------------------------------------------------------------------------------------------------

// The built-in instrument for each of the 128 programs, written per family of eight.
const char* const kProgramInstrument[128] = {
    // 0-7 piano
    "piano", "piano", "piano", "piano", "epiano", "epiano", "clav", "clav",
    // 8-15 chromatic percussion
    "music_box", "bell_glass", "music_box", "vibraphone", "marimba", "marimba", "bell", "pluck_bright",
    // 16-23 organ
    "organ", "organ", "organ", "organ", "organ", "organ", "organ", "organ",
    // 24-31 guitar
    "guitar", "pluck", "pluck_soft", "pluck_soft", "pluck", "pluck_bright", "pluck_bright", "pluck",
    // 32-39 bass
    "bass_pluck", "bass_pluck", "bass_pluck", "bass_sub", "bass_pluck", "bass_pluck", "bass", "bass_fm",
    // 40-47 strings
    "strings", "strings", "strings", "strings", "strings_soft", "pluck", "harp", "bass_sub",
    // 48-55 ensemble
    "strings", "strings_soft", "strings", "strings_soft", "choir", "choir", "choir", "brass",
    // 56-63 brass
    "brass", "brass", "brass", "brass", "horns", "brass", "brass", "brass",
    // 64-71 reed
    "clarinet", "clarinet", "clarinet", "clarinet", "oboe", "oboe", "clarinet", "clarinet",
    // 72-79 pipe
    "flute", "flute", "flute", "flute", "flute", "flute", "flute", "flute",
    // 80-87 synth lead
    "lead", "lead_saw", "lead_soft", "lead_fm", "lead_acid", "lead_soft", "lead_saw", "lead_acid",
    // 88-95 synth pad
    "pad", "pad", "pad", "choir", "pad_glass", "pad_dark", "pad_glass", "pad_sweep",
    // 96-103 synth effects
    "pad_sweep", "pad_dark", "bell_glass", "pad_glass", "pad_glass", "pad_dark", "pad_glass", "pad_sweep",
    // 104-111 ethnic
    "pluck_bright", "pluck_bright", "pluck", "harp", "music_box", "oboe", "strings", "oboe",
    // 112-119 percussive
    "bell", "bell", "marimba", "marimba", "bass_sub", "bass_sub", "bass_sub", "pad_sweep",
    // 120-127 sound effects
    "pluck", "flute", "pad_dark", "bell_glass", "bell", "pad_dark", "pad_dark", "pad_dark",
};

struct InstrumentProgram {
    const char* name;
    int program;
};
const InstrumentProgram kInstrumentPrograms[] = {
    {"keys", 4},         {"piano", 0},       {"epiano", 4},       {"clav", 7},          {"organ", 16},        {"pluck", 25},
    {"pluck_soft", 24},  {"pluck_bright", 26}, {"guitar", 24},    {"harp", 46},         {"bass", 38},         {"bass_sub", 35},
    {"bass_pluck", 33},  {"bass_acid", 38},  {"bass_fm", 39},     {"bass_square", 38},  {"lead", 80},         {"lead_saw", 81},
    {"lead_soft", 85},   {"lead_fm", 83},    {"lead_acid", 84},   {"pad", 88},         {"pad_glass", 92},    {"pad_dark", 93},
    {"pad_sweep", 95},   {"bell", 14},       {"bell_glass", 9},   {"music_box", 10},   {"marimba", 12},      {"vibraphone", 11},
    {"strings", 48},     {"strings_soft", 49}, {"brass", 61},     {"horns", 60},        {"choir", 52},        {"flute", 73},
    {"clarinet", 71},    {"oboe", 68},       {"chiptune", 80},    {"chip_square", 80},  {"chip_pulse", 81},   {"chip_triangle", 79},
    {"chip_wave", 82},   {"chip_noise", 120},
};

struct DrumKey {
    const char* lane;
    int key;
};
// The key each lane exports as.
const DrumKey kDrumKeys[] = {
    {"kick", 36},   {"snare", 38},  {"clap", 39},     {"rim", 37},      {"hat", 42},      {"openhat", 46}, {"hat_pedal", 44}, {"shaker", 70},
    {"tambourine", 54}, {"tom_low", 43}, {"tom_mid", 47}, {"tom_high", 50}, {"ride", 51}, {"crash", 49},  {"cowbell", 56},
};

// Every General MIDI percussion key (35..81) that has a lane of the kit.
const DrumKey kDrumImport[] = {
    {"kick", 35}, {"kick", 36}, {"rim", 37}, {"snare", 38}, {"clap", 39}, {"snare", 40}, {"tom_low", 41}, {"hat", 42}, {"tom_low", 43},
    {"hat_pedal", 44}, {"tom_mid", 45}, {"openhat", 46}, {"tom_mid", 47}, {"tom_high", 48}, {"crash", 49}, {"tom_high", 50}, {"ride", 51},
    {"crash", 52}, {"ride", 53}, {"tambourine", 54}, {"crash", 55}, {"cowbell", 56}, {"crash", 57}, {"ride", 59}, {"shaker", 69},
    {"shaker", 70}, {"shaker", 82},
};

constexpr std::int64_t kBase = 20;  // finest step of the note text: a 64th-note triplet is 40 ticks, a 64th 60

// The ticks of every duration the note text can write (:1 .. :64, dotted, double dotted, triplets), largest first. Multiples of 20 only.
struct DurationToken {
    std::int64_t ticks;
    const char* text;
};
const std::vector<DurationToken>& duration_tokens() {
    static const std::vector<DurationToken> tokens = [] {
        std::vector<DurationToken> t;
        const int dens[] = {1, 2, 4, 8, 16, 32, 64};
        for (int den : dens) {
            const std::int64_t base = 4 * kSongPpq / den;
            auto keep = [&](std::int64_t ticks, const std::string& text) {
                if (ticks % kBase != 0 || ticks < 40) return;
                static std::vector<std::string> store;  // text outlives the table
                store.reserve(512);
                store.push_back(text);
                t.push_back({ticks, store.back().c_str()});
            };
            keep(base, ":" + std::to_string(den));
            keep(base * 3 / 2, ":" + std::to_string(den) + ".");
            keep(base * 7 / 4, ":" + std::to_string(den) + "..");
            keep(base * 2 / 3, ":" + std::to_string(den) + "t");
        }
        std::sort(t.begin(), t.end(), [](const DurationToken& a, const DurationToken& b) { return a.ticks > b.ticks; });
        return t;
    }();
    return tokens;
}

// `ticks` (a multiple of 20, at least 40) as a sum of note values; the leftover is never 20 (which no value can say).
std::vector<const DurationToken*> split_duration(std::int64_t ticks) {
    std::vector<const DurationToken*> out;
    while (ticks > 0) {
        const DurationToken* pick = nullptr;
        for (const DurationToken& d : duration_tokens())
            if (d.ticks <= ticks && (ticks - d.ticks == 0 || ticks - d.ticks >= 40)) {
                pick = &d;
                break;
            }
        if (!pick) break;  // only a 20-tick remainder gets here, which snapping never produces
        out.push_back(pick);
        ticks -= pick->ticks;
    }
    return out;
}

// ---- reading -----------------------------------------------------------------------------------------------------------------

struct Note {
    std::int64_t start = 0, end = 0;  // song ticks
    int pitch = 0;
    int velocity = 90;
};

struct Group {
    int midiTrack = 0;
    int channel = 0;
    int program = 0;
    bool drums = false;
    int volume = 127;                 // controller 7 when the first note started
    int pan = 64;
    std::vector<Note> notes;
    std::string trackName;            // the MIDI track's name
    std::string instrumentName;       // the MIDI track's Instrument Name meta
};

struct Marker {
    std::int64_t tick = 0;
    std::string text;
};

std::string sanitize_name(const std::string& text) {
    std::string out;
    for (char c : text) {
        if (std::isalnum(static_cast<unsigned char>(c)) || c == '_' || c == '-') out += c;
        else if (!out.empty() && out.back() != '_') out += '_';
    }
    while (!out.empty() && out.back() == '_') out.pop_back();
    if (out.size() > 32) out.resize(32);
    return out;
}

std::string unique_name(std::string name, std::set<std::string>& used) {
    if (name.empty()) name = "part";
    std::string candidate = name;
    for (int n = 2; used.count(candidate); ++n) {
        const std::string suffix = "_" + std::to_string(n);
        candidate = name.substr(0, 32 - suffix.size()) + suffix;
    }
    used.insert(candidate);
    return candidate;
}

std::string lower(std::string s) {
    for (char& c : s) c = char(std::tolower(static_cast<unsigned char>(c)));
    return s;
}

std::int64_t grid_ticks(const std::string& quantize, std::string& error) {
    if (quantize.empty() || quantize == "off") return kBase;
    std::string digits = quantize;
    bool triplet = false;
    if (!digits.empty() && digits.back() == 't') {
        triplet = true;
        digits.pop_back();
    }
    int den = 0;
    if (!digits.empty() && digits.size() <= 2 && std::all_of(digits.begin(), digits.end(), [](char c) { return c >= '0' && c <= '9'; })) den = std::stoi(digits);
    if (den != 1 && den != 2 && den != 4 && den != 8 && den != 16 && den != 32 && den != 64) {
        error = "quantize `" + quantize + "` is not \"off\" or a note value";
        return 0;
    }
    std::int64_t t = 4 * kSongPpq / den;
    if (triplet) t = t * 2 / 3;
    if (t % kBase != 0) {
        error = "quantize `" + quantize + "` is finer than the note text can write";
        return 0;
    }
    return t;
}

std::int64_t snap(std::int64_t tick, std::int64_t grid) { return ((tick + grid / 2) / grid) * grid; }

// The note text of one stretch of a track.
struct PitchedEvent {
    std::int64_t start = 0, end = 0;
    int velocity = 90;
    std::vector<int> pitches;
};

// `notes` start inside [from, from + length) and are cut at its end; positions become relative to `from`.
std::string pitched_text(const std::vector<Note>& notes, std::int64_t from, std::int64_t length, std::int64_t barTicks) {
    std::vector<PitchedEvent> events;
    {
        std::vector<const Note*> sorted;
        for (const Note& n : notes) sorted.push_back(&n);
        std::sort(sorted.begin(), sorted.end(), [](const Note* a, const Note* b) {
            return std::tie(a->start, a->end, a->velocity, a->pitch) < std::tie(b->start, b->end, b->velocity, b->pitch);
        });
        for (const Note* n : sorted) {
            const std::int64_t s = n->start - from, e = std::min(n->end - from, length);
            if (!events.empty() && events.back().start == s && events.back().end == e && events.back().velocity == n->velocity) events.back().pitches.push_back(n->pitch);
            else events.push_back({s, std::max(e, s + 2 * kBase), n->velocity, {n->pitch}});
        }
    }
    std::vector<std::vector<PitchedEvent>> voices;
    std::vector<std::int64_t> voiceEnd;
    for (const PitchedEvent& e : events) {
        std::size_t v = 0;
        while (v < voices.size() && voiceEnd[v] > e.start) ++v;
        if (v == voices.size()) {
            voices.emplace_back();
            voiceEnd.push_back(0);
        }
        voices[v].push_back(e);
        voiceEnd[v] = e.end;
    }
    // The note text cannot write a gap or a note of exactly 20 ticks (1/48 of a quarter note): close such a sliver by holding the note
    // before it a little longer (or starting the first one a little earlier).
    for (auto& voice : voices) {
        for (std::size_t k = 0; k < voice.size(); ++k) {
            const std::int64_t gap = voice[k].start - (k ? voice[k - 1].end : 0);
            if (gap == kBase) {
                if (k) voice[k - 1].end += kBase;
                else voice[k].start -= kBase;
            }
        }
        if (length - voice.back().end == kBase) voice.back().end += kBase;
    }
    std::string text;
    int velocity = 90;
    for (std::size_t v = 0; v < voices.size(); ++v) {
        std::string tokens;
        std::int64_t at = 0;
        std::int64_t duration = kSongPpq;  // the note text's sticky duration; each voice starts at a quarter
        auto add = [&](const std::string& token) {
            if (!tokens.empty()) tokens += ' ';
            tokens += token;
        };
        // One stretch [from, to) as pieces that do not cross a bar line; `body` is the note or "r", `tie` joins the pieces of a note.
        auto stretch = [&](std::int64_t a, std::int64_t b, const std::string& body, bool tie) {
            while (a < b) {
                const std::int64_t barEnd = (a / barTicks + 1) * barTicks;
                const std::int64_t pieceEnd = std::min(b, barEnd);
                if (a % barTicks == 0 && a > 0 && length > barTicks) add("|");
                const auto parts = split_duration(pieceEnd - a);
                for (std::size_t i = 0; i < parts.size(); ++i) {
                    std::string token = body;
                    if (parts[i]->ticks != duration) {
                        token += parts[i]->text;
                        duration = parts[i]->ticks;
                    }
                    const bool last = pieceEnd == b && i + 1 == parts.size();
                    if (tie && !last) token += '~';
                    add(token);
                }
                a = pieceEnd;
            }
        };
        for (const PitchedEvent* ep = voices[v].data(); ep != voices[v].data() + voices[v].size(); ++ep) {
            const PitchedEvent* e = ep;
            if (e->start > at) stretch(at, e->start, "r", false);
            if (e->velocity != velocity) {
                add("v" + std::to_string(e->velocity));
                velocity = e->velocity;
            }
            std::string body;
            if (e->pitches.size() == 1) {
                body = song_pitch_name(e->pitches[0]);
            } else {
                std::vector<int> sorted = e->pitches;
                std::sort(sorted.begin(), sorted.end());
                sorted.erase(std::unique(sorted.begin(), sorted.end()), sorted.end());
                body = "[";
                for (std::size_t i = 0; i < sorted.size(); ++i) body += (i ? " " : "") + song_pitch_name(sorted[i]);
                body += "]";
                if (sorted.size() == 1) body = song_pitch_name(sorted[0]);
            }
            stretch(e->start, e->end, body, true);
            at = e->end;
        }
        if (at < length) stretch(at, length, "r", false);
        text += (v ? " & " : "") + tokens;
    }
    return text;
}

struct DrumHit {
    std::string lane;
    std::int64_t tick = 0;            // relative to the start of the stretch
    int velocity = 100;
};

struct StepGrid {
    const char* name;
    std::int64_t ticks;
};
constexpr StepGrid kStepGrids[] = {{"8", 480}, {"16", 240}, {"8t", 320}, {"16t", 160}, {"32", 120}};

// A drum pattern of `bars` bars for the hits; `lossy` counts hits that did not land on a step of the grid.
Json drum_pattern(const std::vector<DrumHit>& hits, std::int64_t bars, std::int64_t barTicks, int& lossy) {
    const StepGrid* best = nullptr;
    std::int64_t bestError = 0;
    for (const StepGrid& g : kStepGrids) {
        if (barTicks % g.ticks != 0) continue;
        std::int64_t error = 0;
        for (const DrumHit& h : hits) {
            const std::int64_t r = h.tick % g.ticks;
            error += std::min(r, g.ticks - r);
        }
        if (!best || error < bestError) {
            best = &g;
            bestError = error;
        }
        if (error == 0) break;  // the coarsest grid that holds every hit
    }
    const std::int64_t steps = bars * barTicks / best->ticks;
    std::map<std::string, std::string> lanes;
    std::map<std::string, std::vector<int>> velocities;
    for (const DrumHit& h : hits) {
        std::int64_t step = (h.tick + best->ticks / 2) / best->ticks;
        if (step * best->ticks != h.tick) ++lossy;
        step = std::min(step, steps - 1);
        auto& v = velocities[h.lane];
        if (v.empty()) v.assign(std::size_t(steps), 0);
        v[std::size_t(step)] = std::max(v[std::size_t(step)], h.velocity);
    }
    Json grid = Json::object();
    for (const SongDrumLane& lane : song_drum_lanes()) {
        auto it = velocities.find(lane.name);
        if (it == velocities.end()) continue;
        std::string s;
        for (int v : it->second) s += v == 0 ? '.' : (v < 76 ? 'o' : (v < 112 ? 'x' : 'X'));
        grid[lane.name] = s;
    }
    Json out = Json::object();
    out["step"] = best->name;
    out["grid"] = grid;
    if (bars > 1) out["bars"] = bars;
    return out;
}

struct Chunk {
    std::int64_t bar0 = 0, bars = 1;
    bool rest = true;
    Json pattern;                     // string (pitched) or object (drums); null for a rest
    std::string key;
};

struct Section {
    std::string name, kind = "section";
    std::int64_t bar0 = 0, bars = 0;
};

std::string key_name(int sharps, bool minor) {
    static const char* major[] = {"C", "Db", "D", "Eb", "E", "F", "F#", "G", "Ab", "A", "Bb", "B"};
    static const char* minorNames[] = {"C", "C#", "D", "Eb", "E", "F", "F#", "G", "G#", "A", "Bb", "B"};
    const int pc = ((sharps * 7) % 12 + 12) % 12;
    return minor ? minorNames[(pc + 9) % 12] : major[pc];
}

int key_sharps(int pitchClass, bool minor) {
    static const int sharpsOfMajor[12] = {0, -5, 2, -3, 4, -1, 6, 1, -4, 3, -2, 5};
    return sharpsOfMajor[minor ? (pitchClass + 3) % 12 : pitchClass];
}

bool minor_mode(const std::string& mode) {
    static const std::set<std::string> minorModes = {"minor", "dorian", "phrygian", "locrian", "harmonic_minor", "melodic_minor", "pentatonic_minor", "blues"};
    return minorModes.count(mode) > 0;
}

}  // namespace

std::string gm_program_instrument(int program) { return kProgramInstrument[std::clamp(program, 0, 127)]; }

int gm_instrument_program(std::string_view instrument) {
    for (const InstrumentProgram& p : kInstrumentPrograms)
        if (instrument == p.name) return p.program;
    return -1;
}

std::optional<std::string> gm_drum_lane(int key) {
    for (const DrumKey& d : kDrumImport)
        if (d.key == key) return std::string(d.lane);
    return std::nullopt;
}

int gm_drum_key(std::string_view lane) {
    for (const DrumKey& d : kDrumKeys)
        if (lane == d.lane) return d.key;
    return -1;
}

// ---- import ------------------------------------------------------------------------------------------------------------------

Result<MidiImportResult> midi_to_song(const MidiFile& file, const MidiImportOptions& options) {
    MidiImportResult result;
    auto& warnings = result.warnings;
    std::string qerr;
    const std::int64_t grid = grid_ticks(options.quantize, qerr);
    if (grid == 0) return make_error(qerr, "Use \"off\" (keep the timing), or a note value: \"4\" quarter, \"8\" eighth, \"16\" sixteenth, \"32\", \"8t\" or \"16t\" triplets.");
    const double scale = double(kSongPpq) / double(file.division);
    auto to_song = [&](std::int64_t tick) { return std::int64_t(std::llround(double(tick) * scale)); };

    // The conductor: first tempo, meter, key; markers from every track.
    std::optional<double> tempo;
    SongMeter meter;
    bool meterSet = false;
    int sharps = 0;
    bool minor = false, keySet = false;
    std::vector<Marker> markers;
    std::int64_t fileEnd = 0;  // where the tracks end: trailing silence of a loop-exact export stays
    int tempoChanges = 0, meterChanges = 0, keyChanges = 0;
    for (const MidiTrack& t : file.tracks)
        for (const MidiEvent& e : t.events) {
            if (e.kind != kMidiMeta) continue;
            if (e.metaType == kMetaEndOfTrack) fileEnd = std::max(fileEnd, to_song(e.tick));
            if (e.metaType == kMetaTempo && e.data.size() == 3) {
                const double us = double((e.data[0] << 16) | (e.data[1] << 8) | e.data[2]);
                if (us <= 0) continue;
                if (!tempo) tempo = std::round(60000000.0 / us * 1000.0) / 1000.0;
                else if (std::abs(60000000.0 / us - *tempo) > 0.01) ++tempoChanges;
            } else if (e.metaType == kMetaTimeSignature && e.data.size() >= 2) {
                const int beats = e.data[0], unit = 1 << std::min<int>(e.data[1], 6);
                if (!meterSet) {
                    meterSet = true;
                    if (beats >= 1 && beats <= 16 && (unit == 2 || unit == 4 || unit == 8 || unit == 16)) {
                        meter.beats = beats;
                        meter.unit = unit;
                    } else {
                        warnings.push_back(std::format("the time signature {}/{} is outside what songs hold (1 to 16 beats of a half, quarter, eighth or sixteenth note); 4/4 is used", beats, unit));
                    }
                } else if (beats != meter.beats || unit != meter.unit) {
                    ++meterChanges;
                }
            } else if (e.metaType == kMetaKeySignature && e.data.size() >= 2) {
                const int sf = int(std::int8_t(e.data[0]));
                if (!keySet) {
                    keySet = true;
                    sharps = std::clamp(sf, -7, 7);
                    minor = e.data[1] == 1;
                } else if (sf != sharps) {
                    ++keyChanges;
                }
            } else if (e.metaType == kMetaMarker || e.metaType == kMetaCue) {
                markers.push_back({to_song(e.tick), e.text()});
            }
        }
    if (tempoChanges > 0) warnings.push_back(std::format("the file changes tempo {} time(s); a song has one tempo, so only the first ({:g} BPM) is used and the notes keep their place in the bars", tempoChanges, tempo.value_or(120.0)));
    if (meterChanges > 0) warnings.push_back(std::format("the file changes the time signature {} time(s); a song has one meter, so only the first ({}/{}) is used", meterChanges, meter.beats, meter.unit));
    if (keyChanges > 0) warnings.push_back(std::format("the file changes key {} time(s); only the first is used", keyChanges));
    double songTempo = tempo.value_or(120.0);
    if (songTempo < 20.0 || songTempo > 400.0) {
        warnings.push_back(std::format("the tempo {:g} BPM is outside 20 to 400, which songs hold; {:g} is used", songTempo, std::clamp(songTempo, 20.0, 400.0)));
        songTempo = std::clamp(songTempo, 20.0, 400.0);
    }
    const std::int64_t barTicks = meter.barTicks();

    // The notes, per (MIDI track, channel, program).
    std::vector<Group> groups;
    std::map<std::tuple<int, int, int>, std::size_t> groupOf;
    std::size_t droppedPerc = 0;
    std::set<int> droppedKeys;
    int unterminated = 0, programChangesIgnored = 0;
    for (std::size_t ti = 0; ti < file.tracks.size(); ++ti) {
        const MidiTrack& track = file.tracks[ti];
        std::string trackName, instrumentName;
        for (const MidiEvent& e : track.events) {
            if (e.kind == kMidiMeta && e.metaType == kMetaTrackName && trackName.empty()) trackName = e.text();
            if (e.kind == kMidiMeta && e.metaType == kMetaInstrumentName && instrumentName.empty()) instrumentName = e.text();
        }
        struct Held {
            std::int64_t start = 0;
            int velocity = 0;
            bool sustained = false;   // the key is up but the pedal holds the note
            std::size_t group = 0;
        };
        struct ChannelState {
            int program = 0, volume = 127, pan = 64;
            bool pedal = false;
            std::map<int, Held> held;
            bool programSeen = false;
            std::set<int> programsUsed;
        };
        ChannelState channels[16];
        auto group_for = [&](int ch, ChannelState& cs) -> std::size_t {
            const bool drums = ch == 9;
            const auto key = std::make_tuple(int(ti), ch, drums ? 0 : cs.program);
            auto found = groupOf.find(key);
            if (found != groupOf.end()) return found->second;
            Group g;
            g.midiTrack = int(ti);
            g.channel = ch;
            g.program = drums ? 0 : cs.program;
            g.drums = drums;
            g.volume = cs.volume;
            g.pan = cs.pan;
            g.trackName = trackName;
            g.instrumentName = instrumentName;
            groups.push_back(std::move(g));
            groupOf[key] = groups.size() - 1;
            cs.programsUsed.insert(cs.program);
            return groups.size() - 1;
        };
        auto finish = [&](ChannelState& cs, int pitch, std::int64_t end) {
            auto it = cs.held.find(pitch);
            if (it == cs.held.end()) return;
            Note n;
            n.start = it->second.start;
            n.end = std::max(end, n.start + 1);
            n.pitch = pitch;
            n.velocity = it->second.velocity;
            groups[it->second.group].notes.push_back(n);
            cs.held.erase(it);
        };
        std::int64_t lastTick = 0;
        for (const MidiEvent& e : track.events) {
            lastTick = e.tick;
            if (e.kind == kMidiMeta || e.kind == kMidiSysex) continue;
            ChannelState& cs = channels[e.channel];
            const std::int64_t tick = to_song(e.tick);
            if (e.kind == kMidiProgram) {
                if (cs.programSeen && cs.program != e.data1) {
                    // a later program applies to the notes that start after it
                }
                cs.program = e.data1;
                cs.programSeen = true;
            } else if (e.kind == kMidiController) {
                if (e.data1 == 7) cs.volume = e.data2;
                else if (e.data1 == 10) cs.pan = e.data2;
                else if (e.data1 == 64) {
                    const bool down = e.data2 >= 64;
                    if (cs.pedal && !down) {
                        std::vector<int> release;
                        for (auto& [pitch, h] : cs.held)
                            if (h.sustained) release.push_back(pitch);
                        for (int p : release) finish(cs, p, tick);
                    }
                    cs.pedal = down;
                }
            } else if (e.kind == kMidiNoteOn && e.data2 > 0) {
                if (e.channel == 9 && !gm_drum_lane(e.data1)) {
                    ++droppedPerc;
                    droppedKeys.insert(e.data1);
                    continue;
                }
                finish(cs, e.data1, tick);  // a new strike ends the note of the same key
                Held h;
                h.start = tick;
                h.velocity = e.data2;
                h.group = group_for(e.channel, cs);
                cs.held[e.data1] = h;
            } else if (e.kind == kMidiNoteOff || (e.kind == kMidiNoteOn && e.data2 == 0)) {
                auto it = cs.held.find(e.data1);
                if (it == cs.held.end()) continue;
                if (cs.pedal && e.channel != 9) it->second.sustained = true;
                else finish(cs, e.data1, tick);
            }
        }
        for (int ch = 0; ch < 16; ++ch) {
            std::vector<int> open;
            for (auto& [pitch, h] : channels[ch].held) open.push_back(pitch);
            for (int p : open) {
                finish(channels[ch], p, to_song(lastTick));
                ++unterminated;
            }
            if (channels[ch].programsUsed.size() > 1) programChangesIgnored += 0;
        }
    }
    (void)programChangesIgnored;
    if (unterminated > 0) warnings.push_back(std::format("{} note(s) never got a note off; they end where their track ends", unterminated));
    if (droppedPerc > 0) {
        std::string keys;
        for (int k : droppedKeys) keys += (keys.empty() ? "" : ", ") + std::to_string(k);
        warnings.push_back(std::format("{} percussion hit(s) on channel 10 use keys the built-in kit has no lane for (keys {}); they are left out", droppedPerc, keys));
    }

    // Quantize, clip repeated strikes, drop empty groups.
    std::int64_t songEnd = 0;
    std::size_t total = 0;
    for (Group& g : groups) {
        for (Note& n : g.notes) {
            n.start = snap(n.start, grid);
            n.end = snap(n.end, grid);
            if (g.drums) n.end = n.start + grid;
            if (!g.drums && n.end - n.start < 2 * kBase) n.end = n.start + std::max(grid, 2 * kBase);  // the shortest value the note text writes is 40
        }
        std::sort(g.notes.begin(), g.notes.end(), [](const Note& a, const Note& b) { return std::tie(a.start, a.pitch, a.end) < std::tie(b.start, b.pitch, b.end); });
        // Two strikes of one key at one time are one; a strike ends the earlier note of its key.
        std::vector<Note> kept;
        std::map<int, std::size_t> lastOfPitch;
        for (const Note& n : g.notes) {
            auto it = lastOfPitch.find(n.pitch);
            if (it != lastOfPitch.end()) {
                Note& prev = kept[it->second];
                if (prev.start == n.start) {
                    prev.end = std::max(prev.end, n.end);
                    prev.velocity = std::max(prev.velocity, n.velocity);
                    continue;
                }
                if (prev.end > n.start) prev.end = n.start;
            }
            lastOfPitch[n.pitch] = kept.size();
            kept.push_back(n);
        }
        g.notes = std::move(kept);
        std::sort(g.notes.begin(), g.notes.end(), [](const Note& a, const Note& b) { return std::tie(a.start, a.pitch) < std::tie(b.start, b.pitch); });
        for (const Note& n : g.notes) songEnd = std::max(songEnd, g.drums ? n.start + 1 : n.end);
        total += g.notes.size();
    }
    groups.erase(std::remove_if(groups.begin(), groups.end(), [](const Group& g) { return g.notes.empty(); }), groups.end());
    if (total == 0)
        return make_error("the MIDI file has no notes to import", "A file with only tempo or marker events gives no song. Check that the notes are not all on tracks the export left out.");
    if (total > kSongMaxNotes) return make_error(std::format("the MIDI file has {} notes, more than a song holds ({})", total, kSongMaxNotes), "Import a shorter piece, or split the file.");
    if (groups.size() > kSongMaxTracks)
        return make_error(std::format("the MIDI file plays {} different parts (a track, channel and program each); a song has at most {} tracks", groups.size(), kSongMaxTracks),
                          "Merge parts in your DAW (one program per channel), or split the file.");
    songEnd = std::max(songEnd, fileEnd);
    const int totalBars = int(std::max<std::int64_t>(1, (songEnd + barTicks - 1) / barTicks));
    if (totalBars > kSongMaxBars) return make_error(std::format("the MIDI file lasts {} bars, more than a song holds ({})", totalBars, kSongMaxBars), "Import a shorter piece.");

    // Sections from the markers.
    std::vector<Section> sections;
    {
        std::stable_sort(markers.begin(), markers.end(), [](const Marker& a, const Marker& b) { return a.tick < b.tick; });
        std::set<std::string> usedNames;
        std::int64_t lastBar = -1;
        for (const Marker& m : markers) {
            const std::int64_t bar = std::clamp<std::int64_t>((m.tick + barTicks / 2) / barTicks, 0, totalBars - 1);
            if (bar == lastBar) {
                warnings.push_back(std::format("the marker \"{}\" falls in bar {}, where there is already a section; it is left out", m.text, bar + 1));
                continue;
            }
            std::string text = m.text;
            std::string kind;
            const std::size_t colon = text.find(':');
            if (colon != std::string::npos) {
                const std::string head = lower(text.substr(0, colon));
                if (head == "intro" || head == "loop" || head == "outro" || head == "section") {
                    kind = head;
                    text = text.substr(colon + 1);
                }
            }
            if (kind.empty()) {
                const std::string l = lower(text);
                kind = l.rfind("intro", 0) == 0 ? "intro" : l.rfind("loop", 0) == 0 ? "loop" : (l.rfind("outro", 0) == 0 ? "outro" : "section");
            }
            std::string name = sanitize_name(text);
            if (name.empty()) name = kind == "section" ? "section" : kind;
            if (!sections.empty()) sections.back().bars = bar - sections.back().bar0;
            if (sections.empty() && bar > 0) {
                Section start;
                start.name = unique_name("start", usedNames);
                start.bar0 = 0;
                start.bars = bar;
                sections.push_back(start);
            }
            Section s;
            s.name = unique_name(name, usedNames);
            s.kind = kind;
            s.bar0 = bar;
            sections.push_back(s);
            lastBar = bar;
        }
        if (sections.empty()) {
            Section s;
            s.name = "main";
            s.kind = options.loopWhole ? "loop" : "section";
            sections.push_back(s);
        }
        sections.back().bars = totalBars - sections.back().bar0;
        // The loop is one stretch: later runs of loop sections become plain sections.
        bool seenRun = false, inRun = false;
        for (Section& s : sections) {
            if (s.kind == "loop") {
                if (seenRun && !inRun) {
                    s.kind = "section";
                    warnings.push_back(std::format("the section `{}` is named like a loop but a loop is one stretch of the song; it is a plain section", s.name));
                } else {
                    inRun = true;
                    seenRun = true;
                }
            } else {
                inRun = false;
            }
        }
        if (sections.size() > kSongMaxSections)
            return make_error(std::format("the MIDI file has {} markers, more than the {} sections a song holds", sections.size(), kSongMaxSections), "Remove markers in your DAW, or import without them.");
    }

    // SoundFont for the pitched parts.
    std::optional<Soundfont> font;
    if (!options.soundfont.empty()) {
        auto loaded = Soundfont::load(options.soundfont);
        if (!loaded) return make_error("cannot use the SoundFont: " + loaded.error().message, loaded.error().hint);
        font = std::move(*loaded);
    }

    // The tracks.
    Json tracks = Json::object();
    std::vector<std::vector<std::string>> sectionPlay(sections.size());  // unused index helper
    std::vector<Json> sectionPlays(sections.size(), Json::object());
    std::set<std::string> trackNames;
    int patternCount = 0, clipped = 0, lossy = 0;
    std::set<std::string> fontMisses;
    for (std::size_t gi = 0; gi < groups.size(); ++gi) {
        Group& g = groups[gi];
        // instrument
        std::string instrument;
        if (g.drums) {
            instrument = "kit";
            if (font) {
                auto preset = font->find_preset(128, 0);
                if (preset) instrument = options.soundfont + "#128:0";
                else fontMisses.insert("the SoundFont has no percussion kit (bank 128), so the drums use the built-in kit");
            }
        } else {
            const std::string named = g.instrumentName;
            const bool namedBuiltin = !named.empty() && gm_instrument_program(named) >= 0;
            if (namedBuiltin) {
                instrument = named;
            } else if (font) {
                auto preset = font->find_preset(0, g.program);
                if (preset) instrument = options.soundfont + "#0:" + std::to_string(g.program);
                else {
                    fontMisses.insert(std::format("the SoundFont has no preset for program {} (bank 0); the built-in instrument {} plays it", g.program, gm_program_instrument(g.program)));
                    instrument = gm_program_instrument(g.program);
                }
            } else {
                instrument = gm_program_instrument(g.program);
            }
        }
        std::string base = sanitize_name(g.trackName);
        if (g.drums) base = base.empty() || file.tracks.size() == 1 ? "drums" : base;
        if (base.empty()) base = g.drums ? "drums" : sanitize_name(instrument.find('#') == std::string::npos ? instrument : "sf");
        const std::string name = unique_name(base, trackNames);

        Json track = Json::object();
        track["instrument"] = instrument;
        if (g.volume != 127) track["volume"] = std::round(double(g.volume) / 127.0 * 100.0) / 100.0;
        if (g.pan != 64) track["pan"] = std::round(std::clamp((double(g.pan) - 64.0) / 63.0, -1.0, 1.0) * 100.0) / 100.0;

        // chunks: the bars of every section, written as patterns
        auto notes_in = [&](std::int64_t from, std::int64_t to, std::vector<Note>& out) {
            out.clear();
            auto lo = std::lower_bound(g.notes.begin(), g.notes.end(), from, [](const Note& n, std::int64_t t) { return n.start < t; });
            for (auto it = lo; it != g.notes.end() && it->start < to; ++it) out.push_back(*it);
        };
        auto chunk_of = [&](std::int64_t bar0, std::int64_t bars, std::int64_t sectionEndBar, bool wholeSection) -> Chunk {
            Chunk c;
            c.bar0 = bar0;
            c.bars = bars;
            std::vector<Note> in;
            notes_in(bar0 * barTicks, (bar0 + bars) * barTicks, in);
            if (in.empty()) return c;
            c.rest = false;
            if (g.drums) {
                std::vector<DrumHit> hits;
                for (const Note& n : in) {
                    const auto lane = gm_drum_lane(n.pitch);
                    if (lane) hits.push_back({*lane, n.start - bar0 * barTicks, n.velocity});
                }
                c.pattern = drum_pattern(hits, bars, barTicks, lossy);
                c.key = c.pattern.dump();
            } else {
                std::vector<Note> cut = in;
                const std::int64_t limit = (wholeSection ? sectionEndBar : sectionEndBar) * barTicks;
                for (Note& n : cut) {
                    if (n.end > limit) {
                        n.end = limit;
                        ++clipped;
                    }
                    if (n.end <= n.start) n.end = n.start + kBase;
                }
                c.pattern = pitched_text(cut, bar0 * barTicks, bars * barTicks, barTicks);
                c.key = c.pattern.get<std::string>();
            }
            return c;
        };
        struct Plan {
            std::vector<std::vector<Chunk>> perSection;
            std::map<std::string, std::string> names;   // key -> pattern name
            std::vector<std::pair<std::string, Json>> patterns;
        };
        auto build = [&](bool bySection) -> std::optional<Plan> {
            Plan plan;
            int savedClipped = clipped, savedLossy = lossy;
            for (const Section& s : sections) {
                std::vector<Chunk> chunks;
                const std::int64_t end = s.bar0 + s.bars;
                if (bySection) {
                    if (s.bars > 256) { clipped = savedClipped; lossy = savedLossy; return std::nullopt; }
                    chunks.push_back(chunk_of(s.bar0, s.bars, end, true));
                } else {
                    std::int64_t bar = s.bar0;
                    while (bar < end) {
                        std::int64_t stop = bar + 1;
                        if (!g.drums) {
                            // a note that crosses a bar line keeps its bars together, up to the end of the section
                            while (stop < end) {
                                std::vector<Note> in;
                                notes_in(bar * barTicks, stop * barTicks, in);
                                std::int64_t maxEnd = 0;
                                for (const Note& n : in) maxEnd = std::max(maxEnd, n.end);
                                if (maxEnd <= stop * barTicks) break;
                                stop = std::min(end, (maxEnd + barTicks - 1) / barTicks);
                            }
                            if (stop - bar > 256) { clipped = savedClipped; lossy = savedLossy; return std::nullopt; }
                        }
                        chunks.push_back(chunk_of(bar, stop - bar, end, false));
                        bar = stop;
                    }
                }
                for (Chunk& c : chunks) {
                    if (c.rest) continue;
                    if (!plan.names.count(c.key)) {
                        const std::string pname = "p" + std::to_string(plan.patterns.size() + 1);
                        plan.names[c.key] = pname;
                        plan.patterns.push_back({pname, c.pattern});
                    }
                }
                plan.perSection.push_back(std::move(chunks));
            }
            if (plan.patterns.size() > 64) return std::nullopt;
            return plan;
        };
        const int c0 = clipped, l0 = lossy;
        auto plan = build(false);
        if (!plan) {
            clipped = c0;
            lossy = l0;
            plan = build(true);
        }
        if (!plan)
            return make_error(std::format("the track `{}` has more than 64 different bars, even written as one pattern per section", name),
                              "Import with a coarser quantize (\"16\" or \"8t\"), so repeated bars come out identical, or split the file.");
        Json patterns = Json::object();
        for (auto& [pname, pj] : plan->patterns) patterns[pname] = pj;
        track["patterns"] = patterns;
        patternCount += int(plan->patterns.size());
        tracks[name] = track;
        // what the track plays in each section
        for (std::size_t si = 0; si < sections.size(); ++si) {
            std::string play;
            bool any = false;
            std::string pending;
            std::int64_t pendingCount = 0;
            auto flush = [&] {
                if (pendingCount == 0) return;
                play += (play.empty() ? "" : " ") + pending + (pendingCount > 1 ? "*" + std::to_string(pendingCount) : "");
                pendingCount = 0;
            };
            for (const Chunk& c : plan->perSection[si]) {
                const std::string what = c.rest ? "rest" : plan->names[c.key];
                const std::int64_t count = c.rest ? c.bars : 1;
                if (!c.rest) any = true;
                if (pendingCount > 0 && pending == what) {
                    pendingCount += count;
                } else {
                    flush();
                    pending = what;
                    pendingCount = count;
                }
            }
            flush();
            if (any) sectionPlays[si][name] = play;
        }
    }
    for (const std::string& m : fontMisses) warnings.push_back(m);
    if (clipped > 0) warnings.push_back(std::format("{} note(s) were held past the end of their section and are cut there", clipped));
    if (lossy > 0) warnings.push_back(std::format("{} drum hit(s) did not fall on a step of the drum grid (8, 16, 8t, 16t, 32) and moved to the nearest one; import with quantize \"16\" to make it deliberate", lossy));

    Json doc = Json::object();
    doc["format"] = kSongFormat;
    std::string source = options.source.empty() ? "a MIDI file" : options.source;
    doc["doc"] = "Imported from " + source + ".";
    doc["tempo"] = songTempo;
    doc["meter"] = std::format("{}/{}", meter.beats, meter.unit);
    const std::string key = key_name(sharps, minor);
    doc["key"] = key;
    doc["mode"] = minor ? "minor" : "major";
    doc["tracks"] = tracks;
    Json secs = Json::array();
    for (std::size_t si = 0; si < sections.size(); ++si) {
        Json s = Json::object();
        s["name"] = sections[si].name;
        if (sections[si].kind != "section") s["kind"] = sections[si].kind;
        s["bars"] = sections[si].bars;
        s["play"] = sectionPlays[si];
        secs.push_back(s);
    }
    doc["sections"] = secs;

    std::vector<SongIssue> issues;
    auto parsed = parse_song(doc, "the imported song", &issues);
    if (!parsed)
        return make_error("the imported song does not pass the song checks (this is a bug in the importer): " + parsed.error().message,
                          "Report it with the MIDI file; " + parsed.error().hint);
    result.song = std::move(doc);
    result.tracks = int(groups.size());
    result.notes = int(total);
    result.bars = totalBars;
    result.sections = int(sections.size());
    result.patterns = patternCount;
    result.tempo = songTempo;
    result.meter = std::format("{}/{}", meter.beats, meter.unit);
    result.key = key;
    result.mode = minor ? "minor" : "major";
    return result;
}

// ---- export ------------------------------------------------------------------------------------------------------------------

namespace {

void put_text(MidiTrack& t, std::int64_t tick, std::uint8_t type, const std::string& text) {
    MidiEvent e;
    e.tick = tick;
    e.kind = kMidiMeta;
    e.metaType = type;
    e.data.assign(text.begin(), text.end());
    t.events.push_back(std::move(e));
}

MidiEvent channel_event(std::int64_t tick, std::uint8_t kind, int channel, int d1, int d2 = 0) {
    MidiEvent e;
    e.tick = tick;
    e.kind = kind;
    e.channel = std::uint8_t(channel);
    e.data1 = std::uint8_t(d1);
    e.data2 = std::uint8_t(d2);
    return e;
}

}  // namespace

Result<MidiExportResult> song_to_midi(const SongDoc& song, const SongTimeline& timeline) {
    MidiExportResult out;
    MidiFile file;
    file.format = 1;
    file.division = kSongPpq;

    MidiTrack conductor;
    put_text(conductor, 0, kMetaTrackName, "FactorIA song");
    {
        MidiEvent e;
        e.kind = kMidiMeta;
        e.metaType = kMetaTempo;
        const std::uint32_t us = std::uint32_t(std::llround(60000000.0 / song.tempo));
        e.data = {std::uint8_t(us >> 16), std::uint8_t(us >> 8), std::uint8_t(us)};
        conductor.events.push_back(e);
    }
    {
        MidiEvent e;
        e.kind = kMidiMeta;
        e.metaType = kMetaTimeSignature;
        int dd = 0;
        while ((1 << dd) < song.meter.unit) ++dd;
        e.data = {std::uint8_t(song.meter.beats), std::uint8_t(dd), 24, 8};
        conductor.events.push_back(e);
    }
    {
        MidiEvent e;
        e.kind = kMidiMeta;
        e.metaType = kMetaKeySignature;
        const bool minor = minor_mode(song.mode);
        e.data = {std::uint8_t(std::int8_t(key_sharps(song.keyRoot, minor))), std::uint8_t(minor ? 1 : 0)};
        conductor.events.push_back(e);
    }
    for (const SongSpan& span : timeline.spans) {
        if (span.pass != 0) continue;
        const SongSection& s = song.sections[std::size_t(span.section)];
        put_text(conductor, span.startTick, kMetaMarker, (s.kind == "section" || s.kind == s.name) ? s.name : s.kind + ":" + s.name);
    }
    file.tracks.push_back(std::move(conductor));

    bool anySolo = false;
    for (const SongTrack& t : song.tracks) anySolo = anySolo || t.solo;
    int nextChannel = 0;
    int sharedChannels = 0;
    std::set<std::string> skippedLanes;
    for (std::size_t ti = 0; ti < song.tracks.size(); ++ti) {
        const SongTrack& track = song.tracks[ti];
        if (track.mute || (anySolo && !track.solo)) {
            out.warnings.push_back("the track `" + track.name + "` is " + (track.mute ? "muted" : "not soloed") + " and is not written");
            continue;
        }
        int channel = 9;
        if (!track.drums) {
            if (nextChannel == 9) ++nextChannel;
            if (nextChannel > 15) {
                nextChannel = 0;
                ++sharedChannels;
            }
            if (nextChannel == 9) ++nextChannel;
            channel = nextChannel++;
        }
        MidiTrack mt;
        put_text(mt, 0, kMetaTrackName, track.name);
        std::string instrumentText = track.instrument;
        put_text(mt, 0, kMetaInstrumentName, instrumentText);
        if (!track.drums) {
            int program = gm_instrument_program(track.instrument);
            if (program < 0 && track.soundfont.present() && !track.soundfont.drums) program = std::clamp(track.soundfont.program, 0, 127);
            if (program < 0) program = 0;
            mt.events.push_back(channel_event(0, kMidiProgram, channel, program));
        }
        mt.events.push_back(channel_event(0, kMidiController, channel, 7, std::clamp(int(std::lround(track.volume * 127.0)), 0, 127)));
        mt.events.push_back(channel_event(0, kMidiController, channel, 10, std::clamp(int(std::lround((track.pan + 1.0) * 63.5)), 0, 127)));
        struct Timed {
            std::int64_t tick;
            int order;                // 0 off, 1 on
            MidiEvent e;
        };
        std::vector<Timed> notes;
        for (const SongNote& n : timeline.notes) {
            if (n.track != int(ti)) continue;
            int key = n.pitch;
            if (track.drums) {
                key = gm_drum_key(n.drum);
                if (key < 0) {
                    skippedLanes.insert(track.name + "/" + n.drum);
                    continue;
                }
            }
            if (key < 0 || key > 127) continue;
            const std::int64_t length = track.drums ? std::min<std::int64_t>(n.gateTicks(), 120) : n.gateTicks();
            notes.push_back({n.tick, 1, channel_event(n.tick, kMidiNoteOn, channel, key, std::clamp(n.velocity, 1, 127))});
            notes.push_back({n.tick + length, 0, channel_event(n.tick + length, kMidiNoteOff, channel, key, 0)});
            ++out.notes;
        }
        std::stable_sort(notes.begin(), notes.end(), [](const Timed& a, const Timed& b) { return std::tie(a.tick, a.order) < std::tie(b.tick, b.order); });
        for (Timed& t : notes) mt.events.push_back(std::move(t.e));
        // the setup events are at tick 0, before any note
        file.tracks.push_back(std::move(mt));
        ++out.tracks;
    }
    for (const std::string& lane : skippedLanes)
        out.warnings.push_back("the drum lane `" + lane + "` is not a General MIDI percussion lane of the built-in kit and is not written");
    if (sharedChannels > 0) out.warnings.push_back("the song has more than 15 pitched tracks, so some share a MIDI channel (each is still its own MIDI track)");
    auto bytes = write_midi(file);
    if (!bytes) return bytes.error();
    out.bytes = std::move(*bytes);
    return out;
}

}  // namespace fa
