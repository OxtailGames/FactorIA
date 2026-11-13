// Song documents (`*.song.json`, format "factoria.song/1", schemas/song.schema.json, docs/MUSIC.md): music composed as data (M56.1).
// A song is a tempo, a meter and a key, a set of tracks (an instrument and named patterns each) and a list of sections that say which
// patterns every track plays and for how many repeats. Patterns are written as compact note text an AI can read and edit ("C4:8 E4 G4
// (Am7):2 r"), drums as a step grid. This header is the data model and the two steps every other part of M56 starts from:
//
//   parse_song   JSON -> SongDoc          every problem listed with its JSON pointer, line and column inside the note text, fix, "did you mean"
//   expand_song  SongDoc -> SongTimeline  the arrangement unrolled into one sorted list of timed note events (swing applied)
//
// The preview renderer (song_preview.h), the checks (song_check.h) and the commands read the timeline; the instruments and mixer
// (song_instruments.h, song_preview.h, M56.2), the stems, loop points and MIDI of M56.3 and the runtime player of M56.4 read the same
// model, so keep this the single description of "what notes play when" and "how it is mixed".
//
// Time. Positions are integer ticks, kSongPpq per quarter note (960 divides every note value down to a 64th triplet), so nothing
// drifts and a note's bar and beat are exact. The tempo is one number for the whole song (no tempo map yet).
// Determinism. Nothing here uses wall-clock time or the C library's random numbers: the arpeggiator's "random" is a splitmix64 stream
// from the seed you give.
#pragma once

#include <algorithm>
#include <cstdint>
#include <map>
#include <optional>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

#include "fa/audio/audio_doc.h"
#include "fa/core/json.h"
#include "fa/core/types.h"

namespace fa {

inline constexpr const char* kSongFormat = "factoria.song/1";
inline constexpr const char* kSongSuffix = ".song.json";
inline constexpr int kSongPpq = 960;  // ticks per quarter note
inline constexpr std::size_t kSongMaxTracks = 32;
inline constexpr std::size_t kSongMaxSections = 64;
inline constexpr int kSongMaxBars = 4096;             // in the whole song
inline constexpr std::size_t kSongMaxNotes = 400000;  // in the timeline

// One problem of a song document: where (a JSON pointer such as "/tracks/lead/patterns/a"), what is wrong and how to fix it. For
// a problem inside note text, `line` and `column` (both 1-based, counted in the text of that one string, where a "\n" starts a new
// line) say where; both are 0 for a problem that is not in text.
struct SongIssue {
    std::string pointer;
    std::string message;
    std::string hint;
    int line = 0;
    int column = 0;
};

// "<file>: <pointer> (line L, column C): <message> <hint>": the message every command and CLI shows for an issue.
std::string song_issue_text(const SongIssue& issue, std::string_view file = {});

// Where a note came from, so a check can point at the exact token: the JSON pointer of the pattern text, and the line, column and
// length of the token inside it (0 for a drum step, which is addressed by lane and step in `label`).
struct SongSource {
    std::string pointer;
    int line = 0;
    int column = 0;
    int length = 0;
    std::string label;  // the token as written ("C4:8!") or "kick step 5"
};

struct SongMeter {
    int beats = 4;  // numerator
    int unit = 4;   // denominator: 2, 4, 8 or 16
    std::int64_t barTicks() const { return std::int64_t(beats) * (4 * kSongPpq / unit); }
    std::int64_t beatTicks() const {
        return std::int64_t(4 * kSongPpq / unit);
    }  // one beat of the meter (a quarter in x/4)
    // Ticks between strong beats: every beat, or every three eighths in compound time (6/8, 9/8, 12/8).
    std::int64_t strongTicks() const {
        return (unit == 8 && beats % 3 == 0 && beats > 3) ? 3 * beatTicks() : beatTicks();
    }
};

// One written event of a pattern, relative to the start of the pattern.
struct SongEvent {
    std::int64_t tick = 0;
    std::int64_t duration = 0;  // as written, in ticks
    std::vector<int> pitches;   // MIDI notes (several = a chord); empty for a drum hit
    std::string drum;           // drum tracks: the lane ("kick", "snare", ...)
    int velocity = 90;          // 1..127
    bool accent = false;        // `!` (already added to the velocity)
    double gate = 1.0;          // share of `duration` the note is held; `'` makes it 0.5
    std::string chord;          // the chord name when written by name, "" otherwise
    SongSource source;
};

struct SongPattern {
    std::string name;
    std::string text;              // the notes as written (pitched patterns)
    Json grid;                     // drum patterns: the grid object as written
    std::int64_t lengthTicks = 0;  // a whole number of bars
    int bars = 0;
    std::vector<SongEvent> events;  // sorted by tick
};

// A lane of values over the song: `points` are {beat, value} with the beat counted in quarter notes from the start of the song.
struct SongAutomation {
    std::string param;  // "volume", "pan", "filter" or "macro.<name>"
    std::vector<std::pair<double, double>> points;
    std::string curve = "linear";  // "linear", "step" or "smooth"
    // The value at `beat` (before the first point the first value, after the last the last); `fallback` for a lane without points.
    double value_at(double beat, double fallback) const;
};

// A SoundFont (.sf2) instrument: `path` is a project file, the preset is picked by name or by bank and program number.
struct SongSoundfont {
    std::string path;        // empty: the track does not use a SoundFont
    std::string presetName;  // "Acoustic Grand Piano" (matched exactly, then without case); empty = use bank/program
    int bank = 0;            // 128 for a drum kit
    int program = 0;         // the preset number inside the bank
    bool drums = false;      // the track is a drum track played by the SoundFont's kit
    bool present() const { return !path.empty(); }
};

struct SongTrack {
    std::string name;
    std::string
        instrument;  // "kit" / "kit:<variant>" (a drum kit), a built-in instrument, a preset name, a project `.sfx.json`
                     // path, or "<file>.sf2#<preset>" for a SoundFont track (see `soundfont`)
    bool drums = false;
    SongSoundfont soundfont;
    double volume = 1.0;  // linear
    double pan = 0.0;     // -1 left .. 1 right
    bool mute = false;    // the mixer's mute button: the track plays no notes
    bool solo = false;    // the mixer's solo button: when any track is soloed only soloed tracks play
    int voices = 0;       // most notes held at once (a new note steals the oldest); 0 = the instrument's own limit
    std::vector<AudioStep>
        effects;  // the track's insert chain (audio_step_is_effect steps), before the fader and the pan
    std::map<std::string, double> sends;     // bus name -> level (0..2) of the post-fader send
    int transpose = 0;                       // semitones added to every pitched note
    std::optional<double> swing;             // overrides the song's swing
    int rangeLow = -1, rangeHigh = -1;       // MIDI range of the instrument; -1 = use the instrument's own
    std::map<std::string, std::string> kit;  // drum tracks: lane -> instrument, to replace a lane of the built-in kit
    std::vector<SongPattern> patterns;
    std::vector<SongAutomation> automation;
    const SongPattern* find_pattern(std::string_view name) const;
};

// What a section's track plays: patterns in order, each repeated `repeat` times; a rest is `pattern` empty and `repeat` its bars.
struct SongPlayEntry {
    std::string pattern;
    int repeat = 1;
};
struct SongSectionTrack {
    std::string track;
    std::vector<SongPlayEntry> entries;
};
struct SongSection {
    std::string name;
    std::string kind = "section";  // "intro", "loop", "outro" or "section"
    int repeat = 1;                // the section plays this many times in a row
    int bars = 0;                  // resolved: `bars` as written, or the longest track
    bool barsWritten = false;
    std::vector<std::string> mute;  // tracks that stay silent in this section
    std::vector<SongSectionTrack> play;
};

// A bus the tracks send to (a shared reverb or delay). Its input is the sum of the sends; its output goes to the master.
// On a bus, `reverb` and `delay` steps return only the effect (the dry sound is the track itself).
struct SongBus {
    std::string name;
    double volume = 1.0;
    double pan = 0.0;
    bool mute = false;
    std::vector<AudioStep> effects;
};

// The master bus: effects, then the limiter, then the level that reaches the loudness target.
struct SongMaster {
    std::vector<AudioStep> effects;  // after the song's `volume`, before the limiter
    bool limiter = true;             // a lookahead peak limiter that keeps every sample under `ceilingDb`
    double ceilingDb = -1.0;         // dBFS
    double limiterRelease = 0.1;     // seconds
    enum class Loudness { Style, Off, Target };
    Loudness loudness = Loudness::
        Style;  // Style: the style guide's music loudness when the renderer is given one; Target: `loudnessLufs`
    double loudnessLufs = -16.0;  // Target: the integrated loudness (LUFS) the render is brought to
};

struct SongMixer {
    std::vector<SongBus> buses;
    SongMaster master;
    const SongBus* find_bus(std::string_view name) const;
};

// A layer (M56.3): a named group of tracks that the stems of `music.render` render as one file and the adaptive player (M56.4) fades in
// and out. `intensity` is the music intensity (0..1) from which the layer plays: the base layer is 0, the busiest layer 1.
struct SongLayer {
    std::string name;
    std::vector<std::string> tracks;
    double intensity = 0.0;
    bool intensityWritten =
        false;  // `intensity` was written in the document (otherwise it is spread evenly over the layers)
    std::string doc;
};

struct SongDoc {
    std::string doc;
    double tempo = 120.0;  // quarter notes per minute
    SongMeter meter;
    std::string key = "C";
    int keyRoot = 0;  // pitch class of `key`
    std::string mode = "major";
    double swing = 0.0;  // 0..1: how far the off-beats are delayed toward a triplet feel
    int swingGrid = 8;   // 8: eighth-note off-beats, 16: sixteenth-note
    std::uint64_t seed = 0;
    double volume = 0.8;  // master gain
    SongMixer mixer;
    std::vector<SongTrack> tracks;
    std::vector<SongSection> sections;
    std::vector<SongAutomation> automation;  // master lanes: volume, filter
    std::vector<SongLayer> layers;           // as written (empty: the song declares none); see song_layers()
    Json source;                             // the document as written

    const SongTrack* find_track(std::string_view name) const;
    int track_index(std::string_view name) const;
    double ticks_to_seconds(std::int64_t ticks) const { return double(ticks) * 60.0 / (tempo * double(kSongPpq)); }
    // The key's scale as pitch classes (empty for an unknown mode, which parse_song rejects).
    std::vector<int> scale_pitch_classes() const;
};

// The layers of the song with everything filled in: the intensities spread evenly when not written (the first layer 0, the last 1), and
// the tracks no layer names collected in a last layer called "other" (so the layers always add up to the whole song). A song without
// `layers` has none (a caller that wants stems then picks a grouping, see song_render.h).
std::vector<SongLayer> song_layers(const SongDoc& song);
inline constexpr const char* kSongRestLayer = "other";

// One note of the unrolled song.
struct SongNote {
    std::int64_t tick = 0;      // start, after swing
    std::int64_t duration = 0;  // written length, after swing
    int pitch = -1;             // MIDI, after the track's transpose; -1 for a drum hit
    std::string drum;
    int velocity = 90;
    double gate = 1.0;
    bool accent = false;
    int track = 0;  // index in SongDoc::tracks
    int span = 0;   // index in SongTimeline::spans
    std::string pattern;
    int chordId = -1;   // notes of one chord event share it (-1: a single note)
    std::string chord;  // the chord name when written by name
    SongSource source;
    std::int64_t gateTicks() const { return std::max<std::int64_t>(1, std::int64_t(double(duration) * gate)); }
    std::int64_t end() const { return tick + duration; }
};

// One play of a section: `section` (index in SongDoc::sections), `pass` (0-based repeat), and where it sits in the song.
struct SongSpan {
    int section = 0;
    int pass = 0;
    std::int64_t startTick = 0, endTick = 0;
    int startBar = 0;  // 0-based
    int bars = 0;
};

struct SongTimeline {
    std::vector<SongNote> notes;  // sorted by tick, then track, then pitch
    std::vector<SongSpan> spans;
    std::int64_t totalTicks = 0;
    int bars = 0;
    double seconds = 0.0;
    // "bar 3, beat 2.5" of a tick (1-based).
    std::string position_text(const SongDoc& song, std::int64_t tick) const;
};

// Reads a song. Every problem found is added to `issues` (not only the first); the returned error is the first one, formatted with
// `file`. A song with any issue is not returned.
Result<SongDoc> parse_song(const Json& json, std::string_view file = {}, std::vector<SongIssue>* issues = nullptr);
// parse_song of a file read through the VFS (project-relative).
Result<SongDoc> load_song(std::string_view path, std::vector<SongIssue>* issues = nullptr);

// Unrolls the arrangement: every section pass, every unmuted track, patterns placed bar after bar (a track's list repeats to fill the
// section, and is cut where the section ends), swing applied. Fails only if the song is longer than kSongMaxBars / kSongMaxNotes.
Result<SongTimeline> expand_song(const SongDoc& song);

// ---- the notation (song_notation.cpp) -------------------------------------------------------------------------------------------
// Parses note text into the events of a pattern. `barTicks` is the bar of the meter (bar lines and the pattern length are checked
// against it); `pointer` names the text in issues. `declaredBars` > 0 pads a shorter pattern with silence and rejects a longer one.
// Returns false when it added issues.
bool song_parse_note_text(std::string_view text, const std::string& pointer, const SongMeter& meter, int declaredBars,
                          SongPattern& out, std::vector<SongIssue>& issues);
// Parses a drum grid object ({"grid": {"kick": "x...x...", ...}, "step": "16"}) the same way.
bool song_parse_drum_grid(const Json& pattern, const std::string& pointer, const SongMeter& meter,
                          const std::map<std::string, std::string>& kit, SongPattern& out,
                          std::vector<SongIssue>& issues);

// ---- notes <-> text (song_write.cpp) --------------------------------------------------------------------------------------------
// One note of a pitched pattern as an editor sees it: where it starts and how long it is (ticks from the start of the pattern), its
// pitch (MIDI) and how it is played. `velocity` is the final one (it already includes the accent's boost).
struct SongRollNote {
    std::int64_t tick = 0;
    std::int64_t duration = kSongPpq;
    int pitch = 60;
    int velocity = 90;
    bool accent = false;
    bool staccato = false;
    bool operator==(const SongRollNote& o) const {
        return tick == o.tick && duration == o.duration && pitch == o.pitch && velocity == o.velocity &&
               accent == o.accent && staccato == o.staccato;
    }
};
// The notes a pitched pattern plays, sorted by start and pitch: a chord is one note per pitch.
std::vector<SongRollNote> song_roll_notes(const SongPattern& pattern);
// Note text for `notes` in a pattern of `bars` bars of `meter`, the inverse of song_parse_note_text: notes that overlap go in voices (`&`), notes
// that start and end together are written as a chord, a note longer than the notation's durations or crossing a bar line is tied, and the pattern
// is padded with rests to its length. Starts and ends are rounded to 40 ticks (a 64th-note triplet), the finest step the text can say. Fails,
// saying which note, for a pitch outside 0..127, a velocity outside 1..127, a note that starts outside the pattern or has no length.
Result<std::string> song_write_note_text(const std::vector<SongRollNote>& notes, const SongMeter& meter, int bars);

// The drum lanes of the built-in kit, in the order the docs list them.
struct SongDrumLane {
    std::string name;
    std::string what;
};
const std::vector<SongDrumLane>& song_drum_lanes();

}  // namespace fa
