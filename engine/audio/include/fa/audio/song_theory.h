// The music theory the song documents (song.h) and their helpers lean on: pitch names, chords by name, scales and modes. Pure
// functions over MIDI numbers (C4 = middle C = 60, A4 = 69 = 440 Hz) and pitch classes (0 = C ... 11 = B), no tables of notes
// to load and no floating point except `song_midi_hz`, which uses the synth's own exp2 so it is the same on every platform.
#pragma once

#include <optional>
#include <string>
#include <string_view>
#include <vector>

#include "fa/core/types.h"

namespace fa {

// "C", "F#", "Bb", "E#", "Cbb" -> 0..11; nothing for anything else (the whole text must be the pitch class).
std::optional<int> song_pitch_class(std::string_view text);
// "C4" -> 60, "F#3" -> 54, "Bb-1" -> 10; nothing unless the whole text is a note name with an octave (-1 to 9). 0 to 127 only.
std::optional<int> song_parse_pitch(std::string_view text);
// 60 -> "C4"; sharps (or flats with `flats`).
std::string song_pitch_name(int midi, bool flats = false);
// 1 -> "C#" (or "Db").
std::string song_pitch_class_name(int pitchClass, bool flats = false);
// The frequency of a MIDI note, 440 Hz at 69. Deterministic.
double song_midi_hz(int midi);

// A chord by name: "Am7", "Cmaj7/G", "F#dim", "Dsus4", "Cadd9". `intervals` are semitones above the root (0 first); `bass` is the
// pitch class after the slash (-1 when there is none).
struct SongChord {
    std::string name;
    int root = 0;
    int bass = -1;
    std::string quality;  // "" (major), "m", "7", "maj7", ...
    std::vector<int> intervals;
};
// Fails with the qualities the engine knows and a "did you mean" for a wrong one.
Result<SongChord> song_parse_chord(std::string_view name);
// The MIDI notes of a chord with its root at `rootOctave` (C4 is octave 4), lowest first; a slash bass is added below the root
// (Cmaj7/G at octave 3: G2 C3 E3 G3 B3). Pitches above 127 are dropped.
std::vector<int> song_chord_pitches(const SongChord& chord, int rootOctave);
// Every quality spelling the parser accepts, with the intervals it means ("m7" -> 0 3 7 10), for the docs and for messages.
struct SongQualityInfo {
    std::string spelling;
    std::vector<int> intervals;
    std::string what;
};
const std::vector<SongQualityInfo>& song_chord_qualities();

struct SongScaleInfo {
    std::string name;            // "major", "minor", "dorian", ...
    std::vector<int> intervals;  // semitones above the tonic
    std::string what;
};
const std::vector<SongScaleInfo>& song_scales();
// The pitch classes (0..11, ascending from the tonic) of the scale `mode` on tonic `rootPitchClass`; nothing for an unknown mode.
std::optional<std::vector<int>> song_scale_pitch_classes(int rootPitchClass, std::string_view mode);
// The notes of the scale between `lowMidi` and `highMidi` inclusive, ascending.
std::vector<int> song_scale_notes(int rootPitchClass, std::string_view mode, int lowMidi, int highMidi);
// Whether the key is written with flats (F major, D minor, Bb dorian) rather than sharps: the spelling of the chords and notes the
// helpers make.
bool song_prefers_flats(int rootPitchClass, std::string_view mode);
// The seven (or fewer) chords built on the degrees of the scale, as names: major -> "C Dm Em F G Am Bdim". `sevenths` builds
// four-note chords (Cmaj7 Dm7 Em7 F maj7 G7 Am7 Bm7b5). Only for scales of 7 notes; empty otherwise.
std::vector<std::string> song_diatonic_chords(int rootPitchClass, std::string_view mode, bool sevenths);

}  // namespace fa
