// The Audio panel's feed (audio.log).
//
// Everything here is plain logic over a CommandRegistry: no ImGui, no Editor, no window. audio_panel.cpp only draws it, and tests
// call it directly against a headless Engine. The editor never reimplements what the command does; it runs it and keeps the
// plays it returns.
#pragma once

#include <cstddef>
#include <cstdint>
#include <string>
#include <vector>

#include "fa/core/command.h"
#include "fa/core/json.h"

namespace fa::editor {

struct AudioPlay {
    std::uint64_t seq = 0, frame = 0;
    double time = 0;
    std::string path, bus, source;
    float volume = 1, pitch = 1, pan = 0;
    bool loop = false, music = false, ok = true;
};

struct AudioLogState {
    std::vector<AudioPlay> plays;   // oldest first, capped at kMax
    std::uint64_t after = 0;        // seq of the newest play seen or cleared: the next poll asks for newer ones
    std::uint64_t dropped = 0;      // plays the engine's own log (4096) forgot
    std::string filter;             // keep plays whose path contains this (case-insensitive)
    bool onlyFailed = false;        // keep only plays whose clip failed to load
    bool autoScroll = true;
    std::uint64_t scrolledTo = 0;   // seq of the newest play the panel already scrolled to
    std::string error;              // last poll error ("" = fine)
    static constexpr std::size_t kMax = 2000;
};
// audio.log {after}: appends the plays newer than state.after. Returns the number of new plays.
std::size_t poll_audio_log(const CommandRegistry& commands, AudioLogState& state);
// Forgets what is shown; later polls only add plays newer than the newest one seen.
void clear_audio_log(AudioLogState& state);
// Forgets everything including the position (a new project has a new log that starts at seq 1).
void reset_audio_log(AudioLogState& state);
bool audio_play_visible(const AudioPlay& play, const AudioLogState& state);

}  // namespace fa::editor
