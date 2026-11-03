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
#include <string_view>
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

// ---- Rendering a song to a game asset (M56.3) ----

// The loop of a song: its `loop` sections, whole. Frames are at the render's sample rate, exact at the bar boundaries.
struct SongLoopRegion {
    std::int64_t startTick = 0, endTick = 0;
    int startBar = 1;                 // 1-based bar the loop starts at
    int bars = 0;
    std::size_t startFrame = 0, endFrame = 0;
    std::vector<std::string> sections;
};

// How the tracks are split into stems: which stem each track's dry sound goes to, and which stem each track's send to each bus goes to.
struct SongStemPlan {
    std::string grouping;                         // "layers", "tracks", "buses" ("mix" for the single mix)
    std::vector<std::string> names;               // one per stem
    std::vector<std::string> kinds;               // "layer", "track", "dry", "bus" (or "mix")
    std::vector<double> intensity;                // 0..1 per stem: when a layered player brings it in
    std::vector<std::vector<std::string>> tracks; // per stem: the tracks whose dry sound it holds
    std::vector<std::vector<std::string>> buses;  // per stem: the buses whose return it holds
    std::vector<int> dryStem;                     // per track (song order): its dry stem
    std::vector<std::vector<int>> sendStem;       // per track, per bus: the stem of that send
};

// `grouping` is "layers" (the song's `layers` plus the rest in "other"), "tracks" or "buses".
Result<SongStemPlan> song_stem_plan(const SongDoc& song, std::string_view grouping);

struct SongStem {
    std::string name, kind;
    double intensity = 0.0;
    std::vector<std::string> tracks, buses;
    AudioClip clip;                   // same length, sample rate and loop as the mix
};

struct SongAssetOptions {
    SongRenderOptions render;         // fromBar / bars are ignored: an asset is the whole song
    bool loop = true;                 // find the loop section and wrap its tail onto its start
    std::optional<SongStemPlan> stems;
};

struct SongAssetRender {
    SongRender mix;                   // `mix.clip.loop` holds the loop points when the song has a loop section
    std::optional<SongLoopRegion> loop;
    std::vector<SongStem> stems;
    // The largest difference between the stems' sum and the mix, in dB (full scale). The stems carry the mix's loudness gain and
    // limiter gain, so with linear buses and master effects it is float rounding (about -140 dB); a compressor, distortion or
    // bitcrush on a bus or the master acts on the sum and not on each stem, so it is larger there (stemsExact is false).
    double stemSumErrorDb = -200.0;
    bool stemsExact = true;
};

// Renders the whole song (intro, loop, outro) for a game: the loop's tail (reverb, releases) is folded onto the loop start so the
// loop is seamless, and the stems are rendered under the same master gain.
Result<SongAssetRender> render_song_asset(const SongDoc& song, const SongTimeline& timeline, const SongAssetOptions& options = {});

}  // namespace fa
