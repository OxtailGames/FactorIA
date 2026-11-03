// The playheads of one music player (M56.4): reads a MusicSource, fades its stems with the intensity, changes sections and songs on
// the beat, plays stingers and ducks, and queues the beat events. mix() runs on the audio thread: it reads buffers that exist already,
// uses fixed-size arrays and allocates nothing. Everything else is called by the game thread; the owner (the mixer) serialises both
// with its own lock. A MusicTransport can also run alone, offline (tests, tools): feed mix() any block sizes and the output is the same.
//
// Time. `mixed` counts the output frames mixed so far; the playhead advances `ratio` song frames (kMusicRate Hz) per output frame
// (ratio = kMusicRate / device rate, 1 on the null device). A change that waits for a boundary is scheduled at the output frame the
// boundary falls on, computed from the playhead when it was asked for, so what lands where depends on the frames mixed and on nothing
// else: not on the block sizes, the wall clock or the threads. Splitting a block at every boundary makes it sample-exact.
#pragma once

#include <array>
#include <cstdint>
#include <functional>
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
    // Dips the music while a stinger plays, from the boundary on: down by `amount` (0..1) in `attack` seconds, held for `hold` seconds, back in `release`.
    void duck(MusicQuantize q, float amount, float attack, float hold, float release);
    // Crosses over to another song: from the boundary (of the song now playing), the new one starts at `section` (-1: the beginning) and
    // fades in while the old fades out, both over `fadeSeconds`. The new song's own tempo is not changed: the boundary is a bar line of the
    // old song and the new one starts on a bar line of its own.
    bool crossfade_to(std::shared_ptr<const MusicSource> src, int section, MusicQuantize q, float fadeSeconds, std::string* error);

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
    MusicStatus status() const;
    // The gain the layer fades have reached, per stem of the main head's source.
    std::vector<float> stem_gains() const;
    // Moves the queued events to `out` (oldest first).
    void take_events(std::vector<MusicEvent>& out);
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
    // The owner keeps sources alive while a head may read them; call after changing the sources, under the same lock as mix().
    void prune_sources();
};

}  // namespace fa
