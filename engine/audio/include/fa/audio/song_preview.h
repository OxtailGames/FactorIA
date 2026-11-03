// Offline preview of a song (M56.1): every note of the timeline is rendered with its track's instrument at the note's pitch, mixed
// with the track's volume, pan and automation, and the master lanes are applied. The result is an ordinary stereo AudioClip with its
// loudness measured, so `music.preview` can write a WAV, `music.check` can judge the loudness and tests can compare bytes.
// Deterministic: the same song and options give the same samples on every platform (the synth's own math, a fixed mixing order, no
// wall-clock). This is the preview, not the player: the instruments, mixer and stems of M56.2 and M56.3 build on the same notes.
#pragma once

#include <cstdint>
#include <string>
#include <vector>

#include "fa/audio/audio_doc.h"
#include "fa/audio/song.h"

namespace fa {

struct SongRenderOptions {
    int sampleRate = 44100;
    double maxSeconds = 180.0;        // longer songs fail with a hint to render a range (fromBar / bars) or to raise this
    double tailSeconds = 1.5;         // silence after the last note, for releases and reverbs
    int fromBar = 1;                  // 1-based: first bar rendered. Notes that start earlier are not played.
    int bars = 0;                     // number of bars rendered from `fromBar` (0 = to the end)
    std::vector<std::string> solo;    // when not empty only these tracks play
    std::vector<std::string> mute;    // tracks that do not play
    std::uint64_t seed = 0;           // added to the song's seed: another take of every noise
};

struct SongRender {
    AudioClip clip;                   // stereo, `lufs` and `peakDb` measured over the whole render
    double seconds = 0.0;             // of the music (without the tail)
    int notes = 0;                    // notes played
    int renders = 0;                  // distinct note renders (the rest were cached)
    std::vector<std::string> inputs;  // project files read (instrument patches)
};

// Fails when a track's instrument cannot be loaded (the message names the track and the file) or the song is longer than maxSeconds.
Result<SongRender> render_song(const SongDoc& song, const SongTimeline& timeline, const SongRenderOptions& options = {});

}  // namespace fa
