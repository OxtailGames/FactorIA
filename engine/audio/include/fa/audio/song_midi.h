// MIDI and songs (M56.3): `midi_to_song` turns a Standard MIDI File (midi.h) into a song document, `song_to_midi` writes a song as a
// format-1 file. Both are plain functions over data, so the tools (`music.import_midi`, `music.export_midi`) and the tests use the same code.
//
// Import (what a MIDI file becomes)
//   - Tempo, time signature and key signature come from the first such event; a later tempo or meter change is reported in `warnings` and
//     not applied (a song has one tempo and one meter). Times are rescaled to the song's 960 ticks per quarter note.
//   - Every (MIDI track, channel, program) that plays notes becomes a song track. Channel 10 (index 9) is a drum track: General MIDI
//     percussion keys become the lanes of the built-in kit (gm_drum_lane). The other tracks pick the built-in instrument nearest to the
//     General MIDI program (gm_program_instrument), or the SoundFont preset with that program when the options name a SoundFont.
//     An Instrument Name that names a built-in instrument (what `song_to_midi` writes) wins over the program.
//   - A note's velocity is kept exactly (drum hits become the grid's ghost / hit / accent velocities 52 / 100 / 124). The sustain pedal
//     (controller 64) lengthens a note up to the pedal release, like a piano. Controller 7 and 10 set the track's volume and pan.
//   - `quantize` moves note starts and ends to a grid: "off" (the default) keeps them as written to the finest step the note text can
//     say (1/48 of a quarter note); "16" is sixteenth notes, "8t" eighth-note triplets, "32", "4"... A note shorter than one step is one step.
//   - Markers and cue points (meta events 6 and 7) become sections at the nearest bar line: a name starting with intro, loop or outro
//     (or written "loop:name") gets that kind. Without markers the song is one section "main" (kind loop with `loopWhole`).
//   - Every track is written bar by bar: a bar that has already been seen in the same track becomes the same pattern (exact repeats are
//     collapsed), and a section plays patterns as `a*4 b rest`. Notes that cross a bar line are tied inside one pattern. If a track needs
//     more than 64 different bars, it is written as one pattern per section instead.
// Export (what a song becomes)
//   - Track 1 is the conductor: tempo, time signature, key signature and one marker per section (written "kind:name" when the kind is not
//     the name). Then one track per song track, with its name, its instrument (Instrument Name meta + the General MIDI program), controller 7
//     (volume, clamped to 1) and 10 (pan), and its notes. Drum tracks use channel 10 and the General MIDI percussion keys of the lanes.
//     A note lasts as long as it sounds (its gate), so staccato notes export short.
//   - The sounded timeline is written, so swing is in the note times, a track's `transpose` is in the pitches and notes silenced by a
//     section are not written. Muted tracks (and tracks not soloed while another is) are not written. Mixer, effects, buses and automation
//     have no MIDI equivalent and are not exported.
//   - import(export(song)) gives back the same notes, times and velocities (tests pin it) when the song has no swing and its notes are
//     whole multiples of 1/48 quarter note; the instruments, the mode (only major / minor is stored) and the mixer are not part of it.
#pragma once

#include <cstdint>
#include <optional>
#include <string>
#include <string_view>
#include <vector>

#include "fa/audio/midi.h"
#include "fa/audio/song.h"
#include "fa/core/json.h"

namespace fa {

// General MIDI.
// The built-in instrument nearest to a program (0..127), by family: 0 -> "piano", 40 -> "strings", 80 -> "lead".
std::string gm_program_instrument(int program);
// The program a built-in instrument exports as; -1 for a name that is not a built-in instrument.
int gm_instrument_program(std::string_view instrument);
// The lane of the built-in kit that a General MIDI percussion key (35..81) plays; nothing for a key the kit has no lane for.
std::optional<std::string> gm_drum_lane(int key);
// The key a lane exports as; -1 for a lane that is not in the built-in kit (a lane a track's `kit` adds).
int gm_drum_key(std::string_view lane);

struct MidiImportOptions {
    std::string quantize = "off";     // "off" or a note value: "4", "8", "16", "32", "64", "8t", "16t"...
    std::string source;               // the file name, for the document's `doc` text
    std::string soundfont;            // project path of an .sf2: pitched tracks play its preset with the track's program
    bool loopWhole = false;           // a file without markers: the one section is the song's loop
};

struct MidiImportResult {
    Json song;                        // a song document (it parses: parse_song accepts it)
    std::vector<std::string> warnings;
    int tracks = 0;
    int notes = 0;
    int bars = 0;
    int sections = 0;
    int patterns = 0;
    double tempo = 120.0;
    std::string meter = "4/4";
    std::string key = "C";
    std::string mode = "major";
};

// Fails (with what to do) when the file has no notes, a quantize that is not a note value, a SoundFont that cannot be read, more than 32
// tracks, or a piece longer than a song can be.
Result<MidiImportResult> midi_to_song(const MidiFile& file, const MidiImportOptions& options = {});

struct MidiExportResult {
    std::vector<std::uint8_t> bytes;
    std::vector<std::string> warnings;
    int tracks = 0;                   // song tracks written
    int notes = 0;
};

Result<MidiExportResult> song_to_midi(const SongDoc& song, const SongTimeline& timeline);

}  // namespace fa
