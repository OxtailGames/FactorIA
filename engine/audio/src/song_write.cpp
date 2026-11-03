// Notes -> note text (fa/audio/song.h, docs/MUSIC.md "Writing notes"): the inverse of song_parse_note_text, for the editors that change a
// pattern note by note (the Music panel's piano roll, the notes list of music.edit). What is written is plain notes: chords by name, groups
// and repeats of the text it replaces come back as the notes they play.
#include <algorithm>
#include <format>
#include <map>

#include "fa/audio/song.h"
#include "fa/audio/song_theory.h"

namespace fa {

namespace {

constexpr std::int64_t kGrid = 40;            // ticks: the 64th-note triplet, the finest step every duration is a multiple of
constexpr int kAccentBoost = 22;              // song_notation.cpp: what `!` adds to the velocity

// The durations note text can say (":4", ":8.", ":8t", ...) that are a whole number of kGrid steps, by length.
const std::map<std::int64_t, std::string>& duration_table() {
    static const std::map<std::int64_t, std::string> table = [] {
        std::map<std::int64_t, std::string> t;
        for (int den : {1, 2, 4, 8, 16, 32, 64}) {
            const std::int64_t base = std::int64_t(4 * kSongPpq / den);
            const std::string d = std::to_string(den);
            const std::pair<std::int64_t, std::string> forms[] = {{base, d}, {base * 3 / 2, d + "."}, {base * 7 / 4, d + ".."}, {base * 2 / 3, d + "t"}};
            for (const auto& [ticks, text] : forms)
                if (ticks % kGrid == 0 && !t.count(ticks)) t[ticks] = text;
        }
        return t;
    }();
    return table;
}

std::int64_t snap(std::int64_t ticks) { return (ticks + kGrid / 2) / kGrid * kGrid; }

struct Group {                                // notes that sound as one event: they start and end together and are played the same way
    std::int64_t tick = 0, end = 0;
    std::vector<int> pitches;
    int velocity = 90;
    bool accent = false, staccato = false;
};

struct Writer {
    SongMeter meter;
    std::int64_t length = 0;
    int curVelocity = 90;                       // sticky across voices, like the parser's
    std::int64_t curDuration = kSongPpq;        // sticky inside a voice; every voice starts at a quarter
    std::string out;

    void token(const std::string& t) {
        if (!out.empty() && out.back() != '\n') out += ' ';
        out += t;
    }

    // `ticks` of `what` ("r" or a note or chord) from `cursor`, cut at the bar lines and into durations the text can say. Marks go on the first
    // piece; every piece but the last of a note is tied to the next. Moves the cursor.
    void put(std::int64_t& cursor, std::int64_t ticks, const std::string& what, bool rest, const std::string& marks) {
        const std::int64_t bar = meter.barTicks();
        const std::int64_t end = cursor + ticks;
        bool first = true;
        while (cursor < end) {
            std::int64_t piece = std::min(end - cursor, bar - cursor % bar);
            while (piece > 0 && cursor < end) {
                auto it = duration_table().upper_bound(piece);
                --it;                                           // the table starts at 40 and every piece is a multiple of it
                const std::int64_t d = it->first;
                const bool lastOfNote = cursor + d >= end;
                std::string t = what;
                if (d != curDuration) {
                    t += ":" + it->second;
                    curDuration = d;
                }
                if (first) t += marks;
                if (!rest && !lastOfNote) t += "~";
                token(t);
                first = false;
                cursor += d;
                piece -= d;
            }
            if (cursor % bar == 0 && cursor < length) token("|");
        }
    }
};

std::string pitches_text(const std::vector<int>& pitches) {
    if (pitches.size() == 1) return song_pitch_name(pitches[0]);
    std::string s = "[";
    for (std::size_t i = 0; i < pitches.size(); ++i) s += (i ? " " : "") + song_pitch_name(pitches[i]);
    return s + "]";
}

}  // namespace

std::vector<SongRollNote> song_roll_notes(const SongPattern& pattern) {
    std::vector<SongRollNote> notes;
    for (const SongEvent& e : pattern.events)
        for (int p : e.pitches) {
            SongRollNote n;
            n.tick = e.tick;
            n.duration = e.duration;
            n.pitch = p;
            n.velocity = e.velocity;
            n.accent = e.accent;
            n.staccato = e.gate < 1.0;
            notes.push_back(n);
        }
    std::stable_sort(notes.begin(), notes.end(), [](const SongRollNote& a, const SongRollNote& b) { return a.tick != b.tick ? a.tick < b.tick : a.pitch < b.pitch; });
    return notes;
}

Result<std::string> song_write_note_text(const std::vector<SongRollNote>& notes, const SongMeter& meter, int bars) {
    if (bars < 1 || bars > 256) return make_error("a pattern has " + std::to_string(bars) + " bars", "A pattern is 1 to 256 bars.");
    const std::int64_t length = std::int64_t(bars) * meter.barTicks();
    std::vector<Group> events;
    {
        std::vector<SongRollNote> sorted = notes;
        for (std::size_t i = 0; i < sorted.size(); ++i) {
            SongRollNote& n = sorted[i];
            const std::string where = "note " + std::to_string(i + 1) + " (" + (n.pitch >= 0 && n.pitch <= 127 ? song_pitch_name(n.pitch) : std::to_string(n.pitch)) + ")";
            if (n.pitch < 0 || n.pitch > 127) return make_error(where + " has pitch " + std::to_string(n.pitch) + ", which is not a MIDI note", "Pitches are MIDI numbers from 0 to 127 (60 is C4).");
            if (n.velocity < 1 || n.velocity > 127) return make_error(where + " has velocity " + std::to_string(n.velocity), "Velocity is 1 to 127.");
            if (n.tick < 0 || n.tick >= length)
                return make_error(where + " starts at tick " + std::to_string(n.tick) + ", outside the " + std::to_string(bars) + " bar(s) of the pattern (0 to " + std::to_string(length - 1) + ")",
                                  "Raise `bars`, or move the note inside the pattern (" + std::to_string(kSongPpq) + " ticks per quarter note).");
            if (n.duration < 1) return make_error(where + " has duration " + std::to_string(n.duration), "A note lasts at least 1 tick; the shortest the text can say is " + std::to_string(kGrid) + ".");
            const std::int64_t start = snap(n.tick);
            std::int64_t end = std::min(snap(n.tick + n.duration), length);
            if (end <= start) end = std::min(start + kGrid, length);
            n.tick = start;
            n.duration = end - start;
        }
        std::stable_sort(sorted.begin(), sorted.end(), [](const SongRollNote& a, const SongRollNote& b) {
            if (a.tick != b.tick) return a.tick < b.tick;
            if (a.duration != b.duration) return a.duration > b.duration;
            return a.pitch < b.pitch;
        });
        for (const SongRollNote& n : sorted) {
            const int velocity = n.velocity;
            const bool accent = n.accent && n.velocity - kAccentBoost >= 1;
            Group* same = nullptr;
            for (Group& g : events)
                if (g.tick == n.tick && g.end == n.tick + n.duration && g.velocity == velocity && g.accent == accent && g.staccato == n.staccato) same = &g;
            if (same) {
                if (std::find(same->pitches.begin(), same->pitches.end(), n.pitch) == same->pitches.end()) same->pitches.push_back(n.pitch);
                continue;
            }
            bool duplicate = false;   // the same pitch twice at the same moment is one note
            for (const Group& g : events)
                if (g.tick == n.tick && std::find(g.pitches.begin(), g.pitches.end(), n.pitch) != g.pitches.end()) duplicate = true;
            if (duplicate) continue;
            Group g;
            g.tick = n.tick;
            g.end = n.tick + n.duration;
            g.pitches = {n.pitch};
            g.velocity = velocity;
            g.accent = accent;
            g.staccato = n.staccato;
            events.push_back(std::move(g));
        }
        for (Group& g : events) std::sort(g.pitches.begin(), g.pitches.end());
    }

    // Overlapping events are voices: each event goes to the first voice that is free when it starts.
    std::vector<std::vector<const Group*>> voices;
    std::vector<std::int64_t> voiceEnd;
    for (const Group& g : events) {
        std::size_t v = 0;
        while (v < voices.size() && voiceEnd[v] > g.tick) ++v;
        if (v == voices.size()) {
            voices.emplace_back();
            voiceEnd.push_back(0);
        }
        voices[v].push_back(&g);
        voiceEnd[v] = g.end;
    }
    if (voices.empty()) voices.emplace_back();

    Writer w;
    w.meter = meter;
    w.length = length;
    for (std::size_t v = 0; v < voices.size(); ++v) {
        if (v > 0) {
            w.token("&");
            w.curDuration = kSongPpq;
        }
        std::int64_t cursor = 0;
        for (const Group* g : voices[v]) {
            if (g->tick > cursor) w.put(cursor, g->tick - cursor, "r", true, "");
            const int base = g->accent ? g->velocity - kAccentBoost : g->velocity;
            if (base != w.curVelocity) {
                w.token("v" + std::to_string(base));
                w.curVelocity = base;
            }
            w.put(cursor, g->end - g->tick, pitches_text(g->pitches), false, std::string(g->accent ? "!" : "") + (g->staccato ? "'" : ""));
        }
        if (cursor < length) w.put(cursor, length - cursor, "r", true, "");
    }
    return w.out;
}

}  // namespace fa
