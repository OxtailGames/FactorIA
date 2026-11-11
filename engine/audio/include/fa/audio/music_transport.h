// The playheads of one music player (M56.4): reads a MusicSource, fades its stems with the intensity, changes sections and songs on
// the beat, plays stingers and ducks, and queues the beat events. A transport is used by one thread at a time. In fa_audio that is
// the thread that mixes: the game sends the commands through the mixer's command queue and reads the state from the capture()
// copies the mixer publishes. mix(), the raw-pointer commands, pop_event() and capture() read buffers that exist already, use
// fixed-size arrays and allocate nothing; the owner keeps the sources alive while capture() lists them in `refs`. The shared_ptr
// commands hold their source themselves (they allocate: tools and tests). A MusicTransport can also run alone, offline (tests,
// tools): feed mix() any block sizes and the output is the same.
//
// Time. `mixed` counts the output frames mixed so far; the playhead advances `ratio` song frames (kMusicRate Hz) per output frame
// (ratio = kMusicRate / device rate, 1 on the null device). A change that waits for a boundary is scheduled at the output frame the
// boundary falls on, computed from the playhead when it was asked for, so what lands where depends on the frames mixed and on nothing
// else: not on the block sizes, the wall clock or the threads. Splitting a block at every boundary makes it sample-exact.
#pragma once

#include <array>
#include <cstdint>
#include <functional>
#include <optional>
#include <vector>

#include "fa/audio/music_player.h"

namespace fa {

enum class MusicEventKind : std::uint8_t { Beat, Bar, Section, Loop, Ended, Stinger, Crossfade };

// What the mixer saw, stamped with the output frame it happened on.
struct MusicEvent {
    MusicEventKind kind = MusicEventKind::Beat;
    std::int32_t a = 0, b = 0, c = 0, d = 0;
    std::uint64_t frame = 0;      // output frames mixed when it happened
    const MusicSource* src = nullptr;   // the song it happened in (valid until the owner prunes sources, after it has taken the events)
    // Beat: a bar (1-based), b beat (1-based), c section index, d beats played since play (1 for the first).
    // Bar: a bar, b section index, c bars played since play.
    // Section: a section index, b pass (0-based), c bar.
    // Loop: a loops completed since play.   Ended: a 0 = reached the end, 1 = stopped.
    // Stinger: a 0 = clip, 1 = song section; b section index (-1 for a clip).   Crossfade: a 0.
};

constexpr std::size_t kMusicMaxHeads = 8;
constexpr std::size_t kMusicMaxPending = 24;
constexpr std::size_t kMusicEventCapacity = 1024;

// A copy of what the game side reads of a transport, fixed size: the mixer makes one after each block it mixes (capture()) and
// hands it over without a lock. status_of() turns it into a MusicStatus.
struct MusicTransportState {
    bool playing = false, ended = false, active = false;
    const MusicSource* src = nullptr;  // of the main playhead
    double pos = 0.0;                  // song frames of the main playhead
    float volume = 1.0f, intensity = 0.0f;
    int pending = 0, heads = 0;
    std::uint64_t mixed = 0;
    std::array<float, kMusicMaxStems> stemGains{};
    std::size_t stemCount = 0;
    double limit = 0.0;                // where the main playhead wraps or ends (song frames; 0 = no limit)
    double ratio = 1.0;                // song frames per output frame
    // The earliest quantized jump that waits (a section change or a crossfade): the source and position it lands on, and the
    // output frame. The latest intensity change that waits, if any.
    const MusicSource* pendingSrc = nullptr;
    double pendingPos = 0.0;
    std::uint64_t pendingAt = 0;
    bool hasPendingIntensity = false;
    float pendingIntensity = 0.0f;
    std::array<const MusicSource*, kMusicMaxHeads + kMusicMaxPending> refs{};  // every source a head or a pending reads
    std::size_t refCount = 0;
};

class MusicTransport {
public:
    MusicTransport();

    // ---- configuration (game thread)
    void set_rate_ratio(double ratio) { ratio_ = ratio > 0.0 ? ratio : 1.0; }
    double rate_ratio() const { return ratio_; }
    void set_volume(float volume, float seconds = 0.02f);
    float volume() const { return volume_; }
    void set_loop(bool loop);
    bool loop() const { return loop_; }
    // Layer fades: seconds a stem takes, and the intensity span of a fade-in.
    void set_layer_fade(float seconds, float range) { layerFade_ = seconds; layerRange_ = range; }

    // ---- commands (game thread). Each returns false with `error` set when it cannot be done.
    // Starts the song at section `section` (-1: the beginning) at once; whatever played is cut after a short fade.
    bool start(std::shared_ptr<const MusicSource> src, int section, float intensity, std::string* error);
    // The same without holding the source: the caller keeps it alive while capture() lists it. Allocates nothing with a null `error`.
    bool start(const MusicSource* src, int section, float intensity, std::string* error);
    // What start() refuses, checked ahead (the game side validates before it queues the command): false with `error` set.
    static bool check_start(const MusicSource* src, int section, std::string* error);
    // Fades the music out over `fade` seconds when the boundary comes (None: now).
    void stop(MusicQuantize q, float fade);
    // The layers follow `intensity` from the boundary on, each fading over the layer fade.
    void set_intensity(float intensity, MusicQuantize q);
    // Jumps to the first pass of a section: an equal-power crossfade of `fade` seconds between the old and the new position. Fails for an unknown section.
    bool go_to_section(int section, MusicQuantize q, float fade, std::string* error);
    // Plays a section of the song over the music (all its layers) from the boundary on, then `tailSeconds` of what rings after it.
    bool play_section_stinger(int section, MusicQuantize q, float volume, float tailSeconds, std::string* error);
    // A stinger that is not a section (a clip the mixer plays itself): the output-frame delay until the boundary, so the mixer can start
    // its voice on the same frame; schedules the stinger event. Returns that delay.
    std::int64_t schedule_clip_stinger(MusicQuantize q);
    // Drops the section changes, crossfades and intensity changes that wait for their boundary (the player of the next scene adopted
    // this transport and wants none of what the previous one asked for). A crossfade that has started is not undone.
    void drop_pending_changes();
    // The output frame a change with `q` requested now (when the mixer is in `state`) lands on; empty when nothing plays.
    static std::optional<std::uint64_t> schedule_of(const MusicTransportState& state, MusicQuantize q);
    // Dips the music while a stinger plays, from the boundary on: down by `amount` (0..1) in `attack` seconds, held for `hold` seconds, back in `release`.
    void duck(MusicQuantize q, float amount, float attack, float hold, float release);
    // Crosses over to another song: from the boundary (of the song now playing), the new one starts at `section` (-1: the beginning) and
    // fades in while the old fades out, both over `fadeSeconds`. The new song's own tempo is not changed: the boundary is a bar line of the
    // old song and the new one starts on a bar line of its own.
    bool crossfade_to(std::shared_ptr<const MusicSource> src, int section, MusicQuantize q, float fadeSeconds, std::string* error);
    bool crossfade_to(const MusicSource* src, int section, MusicQuantize q, float fadeSeconds, std::string* error);  // see start()

    // ---- the audio thread
    // Adds `frames` stereo frames to `out`.
    void mix(float* out, int frames);

    // ---- state (any thread the owner locks for)
    bool active() const;                    // a playhead is sounding or something is pending
    bool playing() const { return main_ >= 0; }
    bool ended() const { return ended_; }   // the music reached its end or was stopped (until start() again)
    std::uint64_t mixed() const { return mixed_; }
    float intensity() const { return intensity_; }
    int pending_count() const;
    int head_count() const;
    const MusicSource* source() const;      // of the main playhead (null when nothing plays)
    double position() const;                // song frames of the main playhead (0 when nothing plays)
    MusicStatus status() const;  // status_of(capture())
    void capture(MusicTransportState& out) const;
    static MusicStatus status_of(const MusicTransportState& state);
    // The gain the layer fades have reached, per stem of the main head's source.
    std::vector<float> stem_gains() const;
    // Moves the queued events to `out` (oldest first).
    void take_events(std::vector<MusicEvent>& out);
    bool pop_event(MusicEvent& out);  // moves the oldest queued event to `out`; false when none waits (allocates nothing)
    std::size_t event_count() const { return ringCount_; }
    std::uint64_t dropped_events() const { return dropped_; }
    // True when no head or pending refers to `src` (the owner may free it).
    bool references(const MusicSource* src) const;

private:
    struct Head {
        bool active = false, main = false, overlay = false;
        const MusicSource* src = nullptr;
        double pos = 0.0;
        bool armed = false;                // wraps at wrapEnd
        double wrapStart = 0.0, wrapEnd = 0.0;
        double endPos = 0.0, tailFade = 0.0;   // the head ends at endPos; the last tailFade frames fade out
        float level = 1.0f;                // overlay volume
        float x = 1.0f, xTarget = 1.0f, xStep = 0.0f;   // equal-power fade: gain sqrt(x)
        long xLeft = 0;
        bool killAtFade = false;
        std::array<float, kMusicMaxStems> gain{}, target{}, step{};
        std::array<long, kMusicMaxStems> left{};
        std::size_t cursor = 0;            // next mark to announce (main head only)
    };
    enum class Kind : std::uint8_t { Jump, Intensity, Stop, Overlay, Duck, Event };
    struct Pending {
        bool used = false;
        Kind kind = Kind::Event;
        std::uint64_t at = 0, seq = 0;     // output frame; order of the request
        const MusicSource* src = nullptr;
        double pos = 0.0, end = 0.0;
        long fadeFrames = 0;
        float f0 = 0.0f, f1 = 0.0f, f2 = 0.0f, f3 = 0.0f;
        std::int32_t i0 = 0, i1 = 0;
        bool crossfade = false;
    };
    struct DuckState {
        enum Phase : std::uint8_t { Idle, Attack, Hold, Release } phase = Idle;
        float level = 1.0f, amount = 0.0f;
        long left = 0, hold = 0, release = 0;
        float step = 0.0f;
    };

    long frames_of(float seconds) const;
    std::uint64_t frame_at(double songPos, double fromPos) const;       // output frame (absolute) a song position is reached at
    Pending* add_pending(Kind kind, std::uint64_t at);
    double limit_of(const Head& h) const;
    Head* free_head();
    void retarget(Head& h, float intensity, long over);
    void fire(const Pending& p);
    void do_jump(const Pending& p);
    void settle();
    bool settle_main();
    void announce_marks(Head& h);
    void mix_head(Head& h, float* out, const float* env, int n);
    void step_envelope(float* env, int n);
    void emit(MusicEventKind kind, int a, int b, int c, int d = 0, const MusicSource* src = nullptr);
    void seek_cursor(Head& h, double from) const;
    void hold(const std::shared_ptr<const MusicSource>& src);
    void setup_wrap(Head& h) const;
    void cancel_pending();

    std::array<Head, kMusicMaxHeads> heads_;
    std::array<Pending, kMusicMaxPending> pending_;
    std::array<MusicEvent, kMusicEventCapacity> ring_;
    std::size_t ringHead_ = 0, ringCount_ = 0;
    std::uint64_t dropped_ = 0;
    int main_ = -1;
    bool ended_ = false, loop_ = true;
    double ratio_ = 1.0;
    std::uint64_t mixed_ = 0, seq_ = 0;
    float intensity_ = 0.0f;
    float volume_ = 1.0f, volCur_ = 1.0f, volStep_ = 0.0f;
    long volLeft_ = 0;
    float layerFade_ = 1.0f, layerRange_ = 0.25f;
    std::int64_t beats_ = 0, bars_ = 0, loops_ = 0;
    DuckState duck_;
    std::vector<std::shared_ptr<const MusicSource>> held_;   // the heads and pendings hold raw pointers: these keep the sources alive

public:
    // Drops the sources the shared_ptr commands hold that no head or pending reads any more (same thread as mix()).
    void prune_sources();
};

}  // namespace fa
