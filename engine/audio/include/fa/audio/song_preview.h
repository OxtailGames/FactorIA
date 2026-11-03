// The song renderer (M56.1, M56.2): every note of the timeline is played by its track's instrument (a synthesized patch of
// song_instruments.h, a project `.sfx.json`, or a SoundFont preset of soundfont.h) at the note's pitch and velocity, runs through the
// track's chain (filter lane, insert effects, fader, pan), reaches the buses by the track's sends, and the master adds the song's
// volume, the master lanes and effects, the loudness normalization and the limiter (song.h "mixer"). The result is an ordinary stereo
// AudioClip with its loudness measured, so `music.preview` can write a WAV, `music.check` can judge the loudness and tests can compare
// bytes. Deterministic: the same song and options give the same samples on every platform (the synth's own math, a fixed mixing
// order, no wall-clock), and nothing here needs a tools-only dependency, so the game runtime can use it (M56.4).
#pragma once

#include <cstdint>
#include <optional>
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
    // The integrated loudness (LUFS) the master brings the render to when the song says `"loudness": "style"` (the style guide's music
    // loudness, which tools read from assets.json). Without it, "style" leaves the level the mix adds up to.
    std::optional<double> targetLufs;
};

// What one track contributed (its pan stage output, before the sends), for the mix report.
struct SongTrackStats {
    std::string name;
    int notes = 0;
    double peakDb = -200.0;           // sample peak of the track in the mix
    double lufs = -70.0;              // its integrated loudness
};

// What the master did.
struct SongMasterStats {
    double peakBeforeDb = -200.0;     // sample peak after the master effects, before the loudness gain and the limiter
    double lufsBefore = -70.0;        // loudness at that point
    double normalizeGainDb = 0.0;     // gain the loudness normalization added (0 when it is off)
    std::optional<double> targetLufs; // the loudness the normalization aimed at (nothing when it is off)
    double limiterReductionDb = 0.0;  // the most the limiter pulled the level down (0 = it never acted)
    bool limiter = false;
    double ceilingDb = 0.0;
};

struct SongRender {
    AudioClip clip;                   // stereo, `lufs` and `peakDb` measured over the whole render
    double seconds = 0.0;             // of the music (without the tail)
    int notes = 0;                    // notes played
    int renders = 0;                  // distinct note renders (the rest were cached)
    std::vector<std::string> inputs;  // project files read (instrument patches, SoundFonts)
    std::vector<SongTrackStats> tracks;   // the tracks that played, in song order
    SongMasterStats master;
};

// Fails when a track's instrument cannot be loaded (the message names the track, the file and how to fix it) or the song is longer than maxSeconds.
Result<SongRender> render_song(const SongDoc& song, const SongTimeline& timeline, const SongRenderOptions& options = {});

}  // namespace fa
