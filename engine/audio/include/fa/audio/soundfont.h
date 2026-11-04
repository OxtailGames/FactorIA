// SoundFont (.sf2) instruments (M56.2): a project brings an `.sf2` file as an asset and a song track plays one of its presets
// (`{"soundfont": "assets/audio/piano.sf2", "preset": "Grand Piano"}`, docs/MUSIC.md "SoundFonts"). The synthesis is TinySoundFont
// (external/tinysoundfont, MIT) behind this small interface, so no other file includes it. Nothing here is required by the engine: a game
// that ships no SoundFont never loads one, and the synthesized instruments (song_instruments.h) need no file at all.
//
// Determinism. TinySoundFont's libm calls are redirected to the synth's own math (audio_tsf_math.cpp), so the same file and the same notes give
// the same samples on every platform. There are no live random numbers: nothing in a SoundFont renderer is random.
#pragma once

#include <cstdint>
#include <memory>
#include <string>
#include <string_view>
#include <vector>

#include "fa/core/types.h"

namespace fa {

struct SoundfontPreset {
    std::string name;                 // "Acoustic Grand Piano"
    int bank = 0;                     // 0..127 melodic, 128 percussion (General MIDI)
    int program = 0;                  // 0..127: the preset number inside the bank
};

// One note for the renderer: `startFrame` and `heldFrames` count samples at the render rate; the note is released after `heldFrames`
// and rings on by itself (the preset's own release).
struct SoundfontNote {
    std::int64_t startFrame = 0;
    std::int64_t heldFrames = 1;
    int key = 60;                     // MIDI note 0..127
    float velocity = 0.8f;            // 0..1 (MIDI velocity / 127)
};

class Soundfont {
public:
    // Reads `path` through the VFS (project-relative) and parses it. The errors say which file and what to do.
    static Result<Soundfont> load(std::string_view path);
    // Parses a file already in memory; `label` names it in the errors.
    static Result<Soundfont> from_memory(const std::vector<std::uint8_t>& bytes, std::string_view label);

    const std::string& path() const { return path_; }
    // Every preset of the file in file order.
    const std::vector<SoundfontPreset>& presets() const { return presets_; }

    // The index (into presets()) of a preset by name (exact first, then ignoring case) or by bank and program number. The error lists the
    // close names or the available numbers.
    Result<int> find_preset(std::string_view name) const;
    Result<int> find_preset(int bank, int program) const;

    // Renders `notes` with preset `preset` into `left` and `right` (resized to `frames`; the notes are added in sequence, so the voices
    // of overlapping notes sum). Notes that start after `frames` are ignored. Nothing is shared with other renders, so several can run.
    Result<void> render(int preset, int rate, const std::vector<SoundfontNote>& notes, std::size_t frames, std::vector<double>& left,
                        std::vector<double>& right) const;

private:
    struct Impl;
    std::shared_ptr<Impl> impl_;
    std::string path_;
    std::vector<SoundfontPreset> presets_;
};

}  // namespace fa
