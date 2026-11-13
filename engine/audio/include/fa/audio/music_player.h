// Adaptive music at runtime (M56.4): a song document played as layers (stems) that fade with an intensity, sections that change on
// the beat or the bar, stingers, crossfades between songs, and beat events for scripts. docs/MUSIC.md, "Playing a song in a game".
//
// Three layers, from the data up:
//   * MusicMap: the song's timeline as frame positions (tempo, meter, sections, the loop, marks for every beat). Pure data and pure
//     functions (quantization, layer gains, the mode choice) so they are tested without a mixer.
//   * MusicSource: a map plus the PCM of the stems. `live` renders them from the document when the player starts (render_song_asset,
//     the bytes music.preview writes); `stems` reads the files music.render wrote. The audio callback only reads these buffers.
//   * The player inside the mixer (music_transport.h, private): playheads over a source, section jumps, stingers, ducking and the
//     event queue. It allocates nothing while it mixes.
//
// The musical clock is the mixer's frame counter (44100 Hz "song frames", advanced by 44100/deviceRate per output frame), never the
// wall clock or the render rate. On the null device (headless runs, tests) the mixer advances exactly the frames the game clock asks
// for, so beats, bars and sections happen at the same frames on every run and every machine; on a sound device they follow the real
// audio position. Events are queued by the mixer and reach scripts in Audio::update, on the game thread.
#pragma once

#include <cstdint>
#include <memory>
#include <optional>
#include <string>
#include <string_view>
#include <vector>

#include "fa/audio/song.h"
#include "fa/core/json.h"
#include "fa/core/types.h"
#include "fa/scene/components.h"

namespace fa {

inline constexpr int kMusicRate = 44100;           // the rate of every music source (the mixer's own)
inline constexpr std::size_t kMusicMaxStems = 16;  // stems one player mixes at once

// ---- Quantization, layers, mode choice (pure) ----------------------------------------------------------------------------------

const char* music_quantize_name(MusicQuantize q);
std::optional<MusicQuantize> music_quantize_from_name(std::string_view name);

// The gain (0..1) of a stem whose threshold is `threshold` at `intensity`: 1 at and above the threshold, 0 below
// `threshold - range`, a smoothstep between. A stem with threshold <= 0 always plays. `range` 0 switches at the threshold.
float music_layer_gain(float intensity, float threshold, float range);

// What the device is, for choosing between live synthesis and stems (Engine::device_info()).
struct MusicDeviceProfile {
    std::string formFactor = "desktop";  // "desktop" | "phone" | "tablet"
    std::string tier = "high";           // "low" | "medium" | "high"
    bool web = false;
};

// What `mode` means on this device. "auto" is stems whenever the song has stem files (a long ogg stem streams, so it costs a window
// instead of 10 MB a minute, and nothing is rendered) and live when it has none; the device only changes the reason it reports.
// "live" and "stems" are taken as written.
// `stemsAvailable` is whether the song has stem files: auto without them is live, and an explicit "stems" without them is live
// as well (the caller warns). `stemsStale` is MusicStemPlan::stale: the song is not the one the stems were rendered from, so "auto"
// plays it live (a song edit is heard at once, as a live song's is) while an explicit "stems" still plays the files.
MusicMode music_resolve_mode(MusicMode mode, const MusicDeviceProfile& device, bool stemsAvailable,
                             std::string* why = nullptr, bool stemsStale = false);

// ---- The timeline ----------------------------------------------------------------------------------------------------------------

struct MusicMark {  // a beat of the song (a strong beat: every beat, or every dotted quarter in compound time)
    double frame = 0.0;
    std::int32_t bar = 1;   // 1-based bar of the song
    std::int32_t beat = 1;  // 1-based beat of the bar
    std::int32_t span = 0;  // index in MusicMap::spans of the section pass this beat is in
    bool sectionStart = false;
};

struct MusicSpan {                  // one play of a section
    std::int32_t section = 0;       // index in MusicMap::sections
    std::int32_t pass = 0;          // 0-based repeat
    double start = 0.0, end = 0.0;  // frames
    std::int32_t startBar = 1;      // 1-based
    std::int32_t bars = 0;
};

struct MusicSection {
    std::string name, kind;  // kind: intro | loop | outro | section
    std::int32_t firstSpan = 0;
};

struct MusicMap {
    double tempo = 120.0;  // quarter notes per minute
    SongMeter meter;
    double barFrames = 0.0, beatFrames = 0.0;  // beatFrames: one strong beat
    double musicEnd = 0.0;                     // frame where the music (without the tail) ends
    std::int64_t frames = 0;                   // length of each stem
    std::vector<MusicSection> sections;
    std::vector<MusicSpan> spans;
    std::vector<MusicMark> marks;  // sorted by frame
    bool hasLoop = false;
    double loopStart = 0.0, loopEnd = 0.0;  // the loop sections, whole
    double playEnd = 0.0;  // where a play-through stops (the end of the last outro, else the end of the clip)
    double endFade = 0.0;  // frames of fade-out at playEnd (0 when the clip's own tail follows)

    int section_index(std::string_view name) const;  // -1 when unknown
    std::vector<std::string> section_names() const;
    int span_at(double frame) const;  // the span a frame is in (-1 outside the music)
    // 1-based bar and beat of a frame.
    void position(double frame, int& bar, int& beat) const;
};

// Frames of a tick: the same rounding the renderer uses for its loop points, so the map agrees with the stems to the frame.
double music_tick_frame(const SongDoc& song, std::int64_t tick);

// The map of a song for stems of `clipFrames` frames (0: the length of the music). The loop is the song's loop sections, in the frames the
// renderer wrote its loop points at.
Result<MusicMap> music_map_build(const SongDoc& song, const SongTimeline& timeline, std::int64_t clipFrames);

// The frame a change requested while the playhead is at `pos` lands on: `pos` itself for none, the next beat / bar line / end of the
// section pass otherwise (a request exactly on a boundary lands there). Never past `limit` (where the playhead wraps or ends): a
// change that would land after the wrap lands at the wrap. `limit` <= 0 means no limit.
double music_boundary(const MusicMap& map, double pos, MusicQuantize q, double limit);

// ---- Stems and sources -----------------------------------------------------------------------------------------------------------

namespace audio_detail {
class MusicStemStream;  // src/music_stream.h (private): a stem that streams from its ogg
}

struct MusicStem {
    std::string name;
    float threshold = 0.0f;  // intensity at which the stem is full
    float scale =
        1.0f;  // sample = pcm * scale (the 16-bit PCM is normalized to the stem's peak); 1 for a streamed stem
    std::vector<std::int16_t> pcm;  // interleaved stereo, kMusicRate; empty for a streamed stem
    // Set: the stem streams from its encoded file (a window of decoded chunks, kept ahead by decode jobs) and `pcm` is empty.
    std::shared_ptr<audio_detail::MusicStemStream> stream;
    std::int64_t streamFrames = 0;  // the length of a streamed stem
    std::size_t frames() const { return stream ? std::size_t(streamFrames) : pcm.size() / 2; }
    std::size_t bytes() const;  // what the stem holds in memory: the PCM, or a streamed stem's window and encoded bytes
};

struct MusicSource {
    std::string path;  // the song
    std::string mode;  // "live" | "stems": how it was made
    MusicMap map;
    std::vector<MusicStem> stems;
    bool layered = false;       // the stems are the song's layers (intensity does something)
    std::size_t bytes() const;  // the memory of every stem (MusicStem::bytes)
    bool streamed() const;      // the stems stream from their ogg files
    // Blocks in which the mixer found a streamed stem's chunk not decoded and played silence, and the frames of that silence, over the stems.
    std::uint64_t underrun_events() const;
    std::uint64_t underrun_frames() const;
};

// Decodes the first chunks at song frame `pos` of every streamed stem of `src` (a no-op for a source that is decoded whole), so a jump
// or a start there finds its audio ready. Call it on the game thread before sending the command that moves a playhead to `pos`.
void music_prime(const MusicSource& src, double pos);

// A stem of float samples (interleaved stereo) into 16-bit PCM and scale.
MusicStem music_make_stem(std::string name, float threshold, const std::vector<float>& interleaved);

// Renders the song to a source: the song's layers as stems (the song as one stem when it declares none). Deterministic. Synchronous,
// takes seconds for a long song: a windowed player runs it on a worker thread.
Result<std::shared_ptr<MusicSource>> music_render_source(const SongDoc& song, const SongTimeline& timeline,
                                                         std::string path);

// One stem file of import.music.
struct MusicStemFile {
    std::string name, path;
    float threshold = 0.0f;
};
// import.music of the song's mix in assets.json: the stem files music.render wrote (empty = none).
struct MusicStemPlan {
    std::string mixPath;
    std::vector<MusicStemFile> files;
    std::string stream =
        "auto";  // import.music.stream: "auto" (stems of 20 s or more stream), "always" or "never" (decode whole)
    // The song file is not the one music.render rendered the stems from: the sha256 the mix entry recorded for it (provenance.recipe.inputs)
    // differs from the file's now. False when the entry records none or the song cannot be read.
    bool stale = false;
};
MusicStemPlan music_stem_plan_of(std::string_view songPath);
// Reads the stem files of `plan` (whole, into 16-bit PCM). Fails with a hint when a file is missing, the stems differ in length, or
// they are shorter than the song now is (the song changed after music.render).
Result<std::shared_ptr<MusicSource>> music_load_stems(const SongDoc& song, const SongTimeline& timeline,
                                                      std::string path, const MusicStemPlan& plan);

// Loads the song at `path` and makes its source in `mode` (live or stems; auto is taken as live): the whole step a player does when it
// starts, and what a worker thread runs. `plan` is music_stem_plan_of(path), read on the game thread. When the stems cannot be used
// the song is rendered live and `note` says why (empty otherwise).
Result<std::shared_ptr<MusicSource>> music_load_source(std::string path, MusicMode mode, const MusicStemPlan& plan,
                                                       std::string* note);

// A stinger: a short piece that plays over the music, from the next boundary on (Audio::music_play_stinger, MusicAPI.playStinger).
struct MusicStingerSpec {
    std::string clip;     // an audio clip to play (its voice starts on the boundary's frame)
    std::string section;  // or a section of the playing song, played with all its layers (set one of the two)
    std::optional<MusicQuantize> quantize;  // when it starts (empty: the player's `quantize`)
    float volume = 1.0f;                    // 0..4, on top of the player's volume (a clip) or of the song (a section)
    float tail = 1.5f;                      // a section stinger: seconds of what rings after the section ends
    std::string bus;                        // a clip stinger: the bus (empty: the player's)
    float duck = 0.0f;                      // 0..1: how much the music dips while the stinger plays (0 = it does not)
    float duckAttack = 0.05f;               // seconds to dip
    float duckHold = -1.0f;    // seconds the dip lasts before it recovers (negative: the length of the clip or section)
    float duckRelease = 0.5f;  // seconds to come back
};

// What a music call scheduled (Audio::music_go_to_section, music_set_intensity, music_crossfade_to; the script and command results).
// `frame` is the output frame the change lands on, worked out from the mixer's latest state (the same count as the `frame` of the
// events and `mixedFrames`): exact on the null device, a block or two off with a sound device that has not caught up. Empty when
// the change cannot be placed yet (nothing plays, or the song is still loading): then the player's state says when it happened.
struct MusicChange {
    std::optional<std::uint64_t> frame;
    double time = 0.0;  // seconds of the audio clock, frame / device rate
    MusicQuantize quantize = MusicQuantize::None;
    Json to_json() const;
};

// ---- What a player is, for tools ---------------------------------------------------------------------------------------------------

struct MusicStatus {
    bool exists = false;
    bool ready = false, playing = false, ended = false;
    std::string song, mode, section;
    int bar = 0, beat = 0;
    double positionSeconds = 0.0;
    double tempo = 0.0;
    float intensity = 0.0f, volume = 1.0f;
    // `intensity` is the one the layers follow now (= appliedIntensity). requestedIntensity is the last one asked for: the
    // component's value, which the layers reach on the layerQuantize boundary.
    float appliedIntensity = 0.0f, requestedIntensity = 0.0f;
    // The next quantized jump (a section change or a crossfade) that waits for its boundary: the song and section that will
    // sound after it and the output frame it lands on (the `frame` of the music.section / music.crossfade event). Empty
    // while none waits. `song` and `section` above are always what is audible now.
    std::string pendingSong, pendingSection;
    std::optional<std::uint64_t> pendingAt;
    std::string bus = "music";
    std::vector<std::string> sections;  // the sections of the song (empty until it is loaded)
    std::vector<std::string> stems;
    std::vector<float> stemGains;  // the gain each stem has now
    int pending = 0;               // quantized changes waiting for their boundary
    int heads = 0;                 // playheads sounding (more than one during a transition)
    std::string error;             // why it could not start
    Json to_json() const;
};

}  // namespace fa
