// Composition helpers (M56.1): chord progressions, arpeggiators, basslines and drum patterns by style. Each makes the note text or
// drum grid a song pattern takes (song.h, docs/MUSIC.md), so an AI asks for "a walking bass over Am F C G" and gets text it can drop
// into a track, read, and change. Deterministic: the only randomness is a splitmix64 stream from the seed you pass.
#pragma once

#include <cstdint>
#include <string>
#include <string_view>
#include <vector>

#include "fa/audio/song.h"
#include "fa/audio/song_theory.h"

namespace fa {

// One chord of a progression and how long it lasts.
struct SongChordStep {
    SongChord chord;
    std::int64_t ticks = 0;
};
// "Am F C G", "Am7 | Fmaj7 | C | G7", "Am*2 F*2": names separated by spaces or `|`; `*N` makes a chord last N bars; every other chord
// lasts `beatsPerChord` beats (0 = one bar). Fails with the chord that is wrong and a "did you mean".
Result<std::vector<SongChordStep>> song_parse_progression(std::string_view text, const SongMeter& meter,
                                                          double beatsPerChord = 0);

// A progression written as Roman numerals in a key, turned into chord names: "i VI III VII" in A minor is "Am F C G". Numerals are
// I to VII (upper case = major, lower case = minor, `dim` or a degree sign = diminished), `b` or `#` before them lowers or raises the
// degree ("bVII"), a suffix is kept ("V7", "iim7", "Isus4", "vi*2" holds two bars). The degrees are those of `mode`'s scale (seven notes).
Result<std::string> song_roman_progression(std::string_view text, int keyRootPitchClass, std::string_view mode);

struct SongPadOptions {
    int octave = 3;  // root octave of the chords
    int velocity = 80;
};
// The progression as sustained chords by name with bar lines: "(Am@3):1 | (F@3) | ...". A chord longer than a bar is tied across.
Result<std::string> song_chord_pad(const std::vector<SongChordStep>& progression, const SongMeter& meter,
                                   const SongPadOptions& options);

struct SongArpeggioOptions {
    std::string direction = "up";  // up, down, updown, downup, random
    int octaves = 1;               // 1 to 4: the chord is repeated this many octaves up before the pattern turns
    int rate = 16;                 // note value of one step: 4, 8, 16 or 32 (a quarter, eighth, ...)
    bool triplet = false;          // the steps are triplets of that value
    int octave = 3;                // root octave of the chords
    int velocity = 90;
    bool accent = true;  // accent the first note of every beat
    bool staccato = false;
    std::uint64_t seed = 0;  // direction random: the same seed gives the same notes
};
// The arpeggio of each chord of the progression as note text with bar lines, e.g. "C3:16! E3 G3 C4 ...".
Result<std::string> song_arpeggio(const std::vector<SongChordStep>& progression, const SongMeter& meter,
                                  const SongArpeggioOptions& options);

struct SongBassOptions {
    std::string style = "root";  // root, root_fifth, octave, walking
    int octave = 2;              // the octave of C for the bass (roots from G up are put an octave lower to stay low)
    int rate = 0;                // note value: 4 or 8 (0 = the style's own: quarters, eighths for octave)
    int velocity = 100;
};
// A bassline over the progression as note text with bar lines.
Result<std::string> song_bassline(const std::vector<SongChordStep>& progression, const SongMeter& meter,
                                  const SongBassOptions& options);
const std::vector<std::pair<std::string, std::string>>& song_bass_styles();  // name, what

struct SongDrumStyle {
    std::string name;
    std::string what;
    std::string meter;                // "4/4" or "3/4": the meter its grid is written for
    int tempoLow = 0, tempoHigh = 0;  // the tempo range it is usually played at
};
const std::vector<SongDrumStyle>& song_drum_styles();
// A drum pattern object ({"grid": {...}, "step": "16"}) of `bars` bars; with `fill` the last beat of the last bar is a tom fill.
// Fails for a style that is not written for the song's meter.
Result<Json> song_drum_pattern(std::string_view style, const SongMeter& meter, int bars, bool fill);

}  // namespace fa
