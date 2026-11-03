// Standard MIDI Files (M56.3): an own reader and writer of SMF formats 0 and 1, the way every DAW and tracker saves a song. This is only
// the file format (chunks, delta times, running status, meta events); song_midi.h turns it into a song document and back.
//
// Times in a MidiFile are in the file's own ticks (`division` per quarter note); nothing is converted or quantized here. The reader keeps
// every event it understands in file order per track, with its absolute tick and the byte offset it started at, so a later problem can
// point at the exact place. Errors teach: the byte offset, what was expected and what to do.
#pragma once

#include <cstdint>
#include <string>
#include <string_view>
#include <vector>

#include "fa/core/types.h"

namespace fa {

// One event of a track. `kind` is the high nibble of a channel message (0x80 note off, 0x90 note on, 0xA0 key pressure, 0xB0 controller,
// 0xC0 program change, 0xD0 channel pressure, 0xE0 pitch bend) or 0xFF for a meta event (`metaType` says which) or 0xF0 for a system
// exclusive message (`data` holds its bytes).
struct MidiEvent {
    std::int64_t tick = 0;            // absolute, from the start of the track
    std::uint8_t kind = 0;
    std::uint8_t channel = 0;         // 0..15 (channel messages)
    std::uint8_t data1 = 0, data2 = 0;
    std::uint8_t metaType = 0;        // kind 0xFF
    std::vector<std::uint8_t> data;   // payload of a meta or system exclusive event
    std::size_t offset = 0;           // byte offset of the event in the file (reader); 0 for events a program builds

    std::string text() const { return std::string(data.begin(), data.end()); }
};

inline constexpr std::uint8_t kMidiNoteOff = 0x80, kMidiNoteOn = 0x90, kMidiController = 0xB0, kMidiProgram = 0xC0, kMidiMeta = 0xFF, kMidiSysex = 0xF0;
// Meta event types used by songs.
inline constexpr std::uint8_t kMetaText = 0x01, kMetaCopyright = 0x02, kMetaTrackName = 0x03, kMetaInstrumentName = 0x04, kMetaLyric = 0x05,
                              kMetaMarker = 0x06, kMetaCue = 0x07, kMetaEndOfTrack = 0x2F, kMetaTempo = 0x51, kMetaTimeSignature = 0x58, kMetaKeySignature = 0x59;

struct MidiTrack {
    std::vector<MidiEvent> events;    // in file order (ticks never decrease)
};

struct MidiFile {
    int format = 1;                   // 0 (one track) or 1 (a conductor track and one track per part)
    int division = 480;               // ticks per quarter note
    std::vector<MidiTrack> tracks;
};

// Reads an SMF. `label` (the file name) starts every error. Formats 0 and 1 are read (2 is rejected with the way to convert it); running
// status, meta events and system exclusive messages are understood; unknown chunks are skipped; a track without its end-of-track event
// is accepted when the chunk ends. SMPTE time division is rejected (songs count quarter notes).
Result<MidiFile> parse_midi(const std::vector<std::uint8_t>& bytes, std::string_view label = "midi");

// Writes `file` as an SMF (every event with its status byte: no running status, so any reader takes it). Events must be in tick order per
// track; an end-of-track event is added at the last tick when the track has none. Fails when a tick or a payload is out of range.
Result<std::vector<std::uint8_t>> write_midi(const MidiFile& file);

}  // namespace fa
