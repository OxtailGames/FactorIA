// Pitch names, chords and scales (fa/audio/song_theory.h).
#include "fa/audio/song_theory.h"

#include <algorithm>
#include <cctype>

#include "fa/core/strings.h"
#include "sfx_math.h"

namespace fa {

namespace {

constexpr const char* kSharpNames[12] = {"C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"};
constexpr const char* kFlatNames[12] = {"C", "Db", "D", "Eb", "E", "F", "Gb", "G", "Ab", "A", "Bb", "B"};

int letter_class(char c) {
    switch (c) {
        case 'C': return 0;
        case 'D': return 2;
        case 'E': return 4;
        case 'F': return 5;
        case 'G': return 7;
        case 'A': return 9;
        case 'B': return 11;
        default: return -1;
    }
}

// Reads a letter and up to two accidentals from the front of `text`; `used` is how many characters it took.
std::optional<int> read_pitch_class(std::string_view text, std::size_t& used) {
    if (text.empty()) return std::nullopt;
    const int base = letter_class(text[0]);
    if (base < 0) return std::nullopt;
    int pc = base;
    std::size_t i = 1;
    if (i < text.size() && (text[i] == '#' || text[i] == 'b')) {
        const char acc = text[i];
        int n = 0;
        while (i < text.size() && text[i] == acc && n < 2) {
            ++i;
            ++n;
        }
        pc += acc == '#' ? n : -n;
    }
    used = i;
    return ((pc % 12) + 12) % 12;
}

const std::vector<SongQualityInfo> kQualities = {
    {"", {0, 4, 7}, "major triad"},
    {"maj", {0, 4, 7}, "major triad"},
    {"m", {0, 3, 7}, "minor triad"},
    {"min", {0, 3, 7}, "minor triad"},
    {"-", {0, 3, 7}, "minor triad"},
    {"dim", {0, 3, 6}, "diminished triad"},
    {"o", {0, 3, 6}, "diminished triad"},
    {"aug", {0, 4, 8}, "augmented triad"},
    {"+", {0, 4, 8}, "augmented triad"},
    {"sus2", {0, 2, 7}, "suspended second"},
    {"sus4", {0, 5, 7}, "suspended fourth"},
    {"sus", {0, 5, 7}, "suspended fourth"},
    {"5", {0, 7}, "power chord (root and fifth)"},
    {"6", {0, 4, 7, 9}, "major sixth"},
    {"m6", {0, 3, 7, 9}, "minor sixth"},
    {"69", {0, 4, 7, 9, 14}, "major sixth with a ninth"},
    {"7", {0, 4, 7, 10}, "dominant seventh"},
    {"maj7", {0, 4, 7, 11}, "major seventh"},
    {"M7", {0, 4, 7, 11}, "major seventh"},
    {"m7", {0, 3, 7, 10}, "minor seventh"},
    {"min7", {0, 3, 7, 10}, "minor seventh"},
    {"-7", {0, 3, 7, 10}, "minor seventh"},
    {"mMaj7", {0, 3, 7, 11}, "minor with a major seventh"},
    {"mM7", {0, 3, 7, 11}, "minor with a major seventh"},
    {"dim7", {0, 3, 6, 9}, "diminished seventh"},
    {"o7", {0, 3, 6, 9}, "diminished seventh"},
    {"m7b5", {0, 3, 6, 10}, "half-diminished seventh"},
    {"7sus4", {0, 5, 7, 10}, "dominant seventh, suspended fourth"},
    {"7b5", {0, 4, 6, 10}, "dominant seventh, flat fifth"},
    {"7#5", {0, 4, 8, 10}, "dominant seventh, sharp fifth"},
    {"aug7", {0, 4, 8, 10}, "dominant seventh, sharp fifth"},
    {"7b9", {0, 4, 7, 10, 13}, "dominant seventh, flat ninth"},
    {"7#9", {0, 4, 7, 10, 15}, "dominant seventh, sharp ninth"},
    {"9", {0, 4, 7, 10, 14}, "dominant ninth"},
    {"maj9", {0, 4, 7, 11, 14}, "major ninth"},
    {"m9", {0, 3, 7, 10, 14}, "minor ninth"},
    {"add9", {0, 4, 7, 14}, "major triad with a ninth (no seventh)"},
    {"madd9", {0, 3, 7, 14}, "minor triad with a ninth (no seventh)"},
    {"add11", {0, 4, 7, 17}, "major triad with an eleventh"},
    {"11", {0, 4, 7, 10, 14, 17}, "dominant eleventh"},
    {"m11", {0, 3, 7, 10, 14, 17}, "minor eleventh"},
    {"13", {0, 4, 7, 10, 14, 21}, "dominant thirteenth"},
    {"maj7#11", {0, 4, 7, 11, 18}, "major seventh, sharp eleventh"},
};

const std::vector<SongScaleInfo> kScales = {
    {"major", {0, 2, 4, 5, 7, 9, 11}, "the major (Ionian) scale: bright, settled"},
    {"minor", {0, 2, 3, 5, 7, 8, 10}, "natural minor (Aeolian): dark, serious"},
    {"dorian", {0, 2, 3, 5, 7, 9, 10}, "minor with a raised sixth: jazzy, hopeful"},
    {"phrygian", {0, 1, 3, 5, 7, 8, 10}, "minor with a lowered second: Spanish, tense"},
    {"lydian", {0, 2, 4, 6, 7, 9, 11}, "major with a raised fourth: dreamy, floating"},
    {"mixolydian", {0, 2, 4, 5, 7, 9, 10}, "major with a lowered seventh: rock, folk, playful"},
    {"locrian", {0, 1, 3, 5, 6, 8, 10}, "the unstable mode: dissonant, rarely a home key"},
    {"harmonic_minor", {0, 2, 3, 5, 7, 8, 11}, "minor with a raised seventh: classical drama, a leading tone"},
    {"melodic_minor", {0, 2, 3, 5, 7, 9, 11}, "minor with raised sixth and seventh (going up)"},
    {"pentatonic_major", {0, 2, 4, 7, 9}, "five notes with no tension: folk, easy melodies"},
    {"pentatonic_minor", {0, 3, 5, 7, 10}, "five notes: rock and blues riffs"},
    {"blues", {0, 3, 5, 6, 7, 10}, "minor pentatonic plus the blue note"},
    {"whole_tone", {0, 2, 4, 6, 8, 10}, "six equal steps: dreamlike, no home"},
    {"chromatic", {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11}, "every note"},
};

}  // namespace

std::optional<int> song_pitch_class(std::string_view text) {
    std::size_t used = 0;
    auto pc = read_pitch_class(text, used);
    if (!pc || used != text.size()) return std::nullopt;
    return pc;
}

std::optional<int> song_parse_pitch(std::string_view text) {
    std::size_t used = 0;
    auto pc = read_pitch_class(text, used);
    if (!pc) return std::nullopt;
    std::string_view rest = text.substr(used);
    if (rest.empty() || rest.size() > 2) return std::nullopt;
    std::size_t i = 0;
    bool neg = false;
    if (rest[0] == '-') {
        neg = true;
        i = 1;
    }
    if (i >= rest.size() || !std::isdigit(static_cast<unsigned char>(rest[i])) || i + 1 != rest.size())
        return std::nullopt;
    const int octave = (neg ? -1 : 1) * (rest[i] - '0');
    // The accidental can cross an octave boundary (Cb4 is B3, B#3 is C4): recompute from the letter.
    int letter = letter_class(text[0]);
    int shift = *pc - letter;
    if (shift > 6) shift -= 12;
    if (shift < -6) shift += 12;
    const int midi = (octave + 1) * 12 + letter + shift;
    if (midi < 0 || midi > 127) return std::nullopt;
    return midi;
}

std::string song_pitch_class_name(int pitchClass, bool flats) {
    const int pc = ((pitchClass % 12) + 12) % 12;
    return flats ? kFlatNames[pc] : kSharpNames[pc];
}

std::string song_pitch_name(int midi, bool flats) {
    const int octave = (midi >= 0 ? midi / 12 : -((11 - midi) / 12)) - 1;
    return song_pitch_class_name(midi, flats) + std::to_string(octave);
}

double song_midi_hz(int midi) { return 440.0 * sfx_math::exp2(double(midi - 69) / 12.0); }

const std::vector<SongQualityInfo>& song_chord_qualities() { return kQualities; }

Result<SongChord> song_parse_chord(std::string_view name) {
    SongChord chord;
    chord.name = std::string(name);
    std::size_t used = 0;
    auto root = read_pitch_class(name, used);
    if (!root)
        return Error{"`" + std::string(name) + "` is not a chord: it must start with a note letter A to G",
                     "Write the root, then the quality: Am7, Cmaj7/G, F#dim, Dsus4, Bb, Cadd9."};
    chord.root = *root;
    std::string_view rest = name.substr(used);
    const std::size_t slash = rest.find('/');
    std::string_view quality = rest.substr(0, slash);
    if (slash != std::string_view::npos) {
        auto bass = song_pitch_class(rest.substr(slash + 1));
        if (!bass)
            return Error{"`" + std::string(rest.substr(slash + 1)) + "` after the slash of `" + std::string(name) +
                             "` is not a note",
                         "The bass note is a pitch class such as G or F#: Cmaj7/G."};
        chord.bass = *bass;
    }
    chord.quality = std::string(quality);
    for (const SongQualityInfo& q : kQualities)
        if (q.spelling == quality) {
            chord.intervals = q.intervals;
            return chord;
        }
    std::vector<std::string> names;
    for (const SongQualityInfo& q : kQualities)
        if (!q.spelling.empty()) names.push_back(q.spelling);
    return Error{
        "unknown chord quality `" + std::string(quality) + "` in `" + std::string(name) + "`",
        did_you_mean(std::string(quality), names) +
            " Qualities: m, dim, aug, sus2, sus4, 5, 6, m6, 7, maj7, m7, mMaj7, dim7, m7b5, 9, maj9, m9, add9, 11, 13 "
            "(docs/MUSIC.md lists them all)."};
}

std::vector<int> song_chord_pitches(const SongChord& chord, int rootOctave) {
    std::vector<int> out;
    const int rootMidi = (rootOctave + 1) * 12 + chord.root;
    if (chord.bass >= 0) {
        int below = rootMidi - (((chord.root - chord.bass) % 12) + 12) % 12;
        if (below == rootMidi) below -= 12;
        if (below >= 0 && below <= 127) out.push_back(below);
    }
    for (int iv : chord.intervals) {
        const int m = rootMidi + iv;
        if (m >= 0 && m <= 127) out.push_back(m);
    }
    std::sort(out.begin(), out.end());
    return out;
}

const std::vector<SongScaleInfo>& song_scales() { return kScales; }

std::optional<std::vector<int>> song_scale_pitch_classes(int rootPitchClass, std::string_view mode) {
    for (const SongScaleInfo& s : kScales) {
        if (s.name != mode) continue;
        std::vector<int> out;
        for (int iv : s.intervals) out.push_back(((rootPitchClass + iv) % 12 + 12) % 12);
        return out;
    }
    return std::nullopt;
}

std::vector<int> song_scale_notes(int rootPitchClass, std::string_view mode, int lowMidi, int highMidi) {
    std::vector<int> out;
    auto pcs = song_scale_pitch_classes(rootPitchClass, mode);
    if (!pcs) return out;
    for (int m = std::max(0, lowMidi); m <= std::min(127, highMidi); ++m)
        if (std::find(pcs->begin(), pcs->end(), m % 12) != pcs->end()) out.push_back(m);
    return out;
}

bool song_prefers_flats(int rootPitchClass, std::string_view mode) {
    // The major key with the same notes: its tonic sits this many semitones below the mode's tonic.
    int below = 0;
    if (mode == "minor" || mode == "harmonic_minor" || mode == "melodic_minor" || mode == "pentatonic_minor" ||
        mode == "blues")
        below = 9;
    else if (mode == "dorian")
        below = 2;
    else if (mode == "phrygian")
        below = 4;
    else if (mode == "lydian")
        below = 5;
    else if (mode == "mixolydian")
        below = 7;
    else if (mode == "locrian")
        below = 11;
    const int major = ((rootPitchClass - below) % 12 + 12) % 12;
    return major == 5 || major == 10 || major == 3 || major == 8 || major == 1 || major == 6;
}

std::vector<std::string> song_diatonic_chords(int rootPitchClass, std::string_view mode, bool sevenths) {
    std::vector<std::string> out;
    auto pcs = song_scale_pitch_classes(rootPitchClass, mode);
    if (!pcs || pcs->size() != 7) return out;
    const bool flats = song_prefers_flats(rootPitchClass, mode);
    for (int d = 0; d < 7; ++d) {
        const int root = (*pcs)[d];
        const int third = ((*pcs)[(d + 2) % 7] - root + 12) % 12;
        const int fifth = ((*pcs)[(d + 4) % 7] - root + 12) % 12;
        const int seventh = ((*pcs)[(d + 6) % 7] - root + 12) % 12;
        std::string q;
        if (third == 4 && fifth == 7)
            q = sevenths ? (seventh == 11 ? "maj7" : "7") : "";
        else if (third == 3 && fifth == 7)
            q = sevenths ? (seventh == 11 ? "mMaj7" : "m7") : "m";
        else if (third == 3 && fifth == 6)
            q = sevenths ? (seventh == 9 ? "dim7" : "m7b5") : "dim";
        else if (third == 4 && fifth == 8)
            q = sevenths ? "aug7" : "aug";
        else
            q = "?";
        out.push_back(song_pitch_class_name(root, flats) + q);
    }
    return out;
}

}  // namespace fa
