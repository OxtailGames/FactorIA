// The mixer side of fa_audio (private): everything the audio callback touches, and the queues between it and the game.
//
// Threads. The game thread (every public Audio call, under Audio::Impl's own API mutex) and the thread that mixes (the
// device callback; the game thread itself on the null device) share nothing but what is in this file, and they share it
// without a lock:
//   - commands   game -> mixer, SpscRing<Cmd*>: a heap object the game made; the mixer runs it and hands it back.
//   - returns    mixer -> game, SpscRing<Ret>: the commands it is done with (the game frees them, with whatever they
//                carry back) and the voices that ended.
//   - StreamRing per streamed voice: a job (or the game thread) decodes ahead, the mixer reads.
//   - PcmRing per voice the game feeds (videos, the editor's previews).
//   - SampleRing for the recorder: the mixer writes the output, the game drains it.
//   - MusicChannel per MusicPlayer: a TripleBuffer of the transport's state and a ring of its events, mixer -> game.
//   - a few atomics (peak, frames mixed, underruns, the last command applied).
// The mixer never takes a lock, never allocates and never frees: the objects it reads (clips, rings, reverbs, bus tables,
// music sources) belong to the game side, which keeps each alive until the mixer said it let go of it (the command that
// removed it came back, or the voice's end did). docs/SOUND.md, "The audio callback".
#pragma once

#include <array>
#include <atomic>
#include <cstddef>
#include <cstdint>
#include <functional>
#include <memory>
#include <string>
#include <vector>

#include "audio_decoder.h"
#include "audio_rings.h"
#include "bus_fx.h"
#include "fa/audio/music_transport.h"

namespace fa::audio_detail {

using VoiceIdT = std::uint32_t;  // fa::VoiceId

constexpr int kRate = kMixRate;
constexpr std::size_t kMaxVoices = 64;
constexpr std::size_t kMaxPlayers = 64;     // MusicPlayer transports mixed at once
constexpr std::size_t kScratchFrames = 4096; // the most frames one mix_block() call mixes (render() splits bigger callbacks)
constexpr int kNullBlock = 512;             // the null device mixes in blocks of this many frames

// The bus table: 0..2 are the built-in buses, kMasterBus the master (its "buffer" is the output), and the project's buses
// (factoria.json "audio.buses") follow from kFirstProjectBus.
enum BusIndex { BusSfx = 0, BusMusic = 1, BusUi = 2, BusBuiltin = 3 };
constexpr int kMasterBus = BusBuiltin;
constexpr int kFirstProjectBus = BusBuiltin + 1;
constexpr float kDuckThreshold = 0.01f;   // -40 dBFS: a bus that peaks above this ducks the buses that listen to it
constexpr float kLowpassOpen = 20000.0f;  // where a cutoff slides from or to when the filter is switched on or off
constexpr double kReverbTail = 4.0;       // seconds the reverb keeps running after its bus went silent (it decays to -100 dB)

// Frames a streamed voice keeps decoded ahead of the mixer, and the least room worth a decode job. 12288 frames are 279 ms
// at 44.1 kHz (96 KB): the game thread asks for a refill every frame, so only a game-thread stall longer than that
// underruns. Music (play_music and its layers) keeps one second (345 KB), so a three-minute song still holds a small part
// of what decoding it whole would.
constexpr std::size_t kStreamFrames = 12288;
constexpr std::size_t kMusicStreamFrames = std::size_t(kRate);
constexpr std::size_t kStreamRefill = 2048;
constexpr std::size_t kStreamPrefill = 4096;  // decoded on the game thread when the voice starts

struct Clip {
    std::string path;
    std::vector<float> data;  // interleaved stereo, 44100 Hz; empty for a streamed clip
    std::shared_ptr<const Bytes> encoded;  // a streamed clip keeps its file: each voice decodes it as it plays
    std::string ext;          // of `encoded`
    std::size_t frames = 0;   // 44100 Hz frames (counted from the header for a streamed clip)
    int srcChannels = 0;
    int srcRate = 0;
    float gain = 1.0f;        // loudness normalization (the `normalize` import setting)
    // Loop points (the `loopStart` / `loopEnd` import settings, in seconds): a looping voice plays loopStart..loopEnd over and
    // over after the first pass. In 44100 Hz frames; loopEnd 0 = no loop points (the whole clip loops).
    std::size_t loopStart = 0, loopEnd = 0;
};

// The decoded frames of one streamed voice, ahead of the mixer: a ring of stereo frames numbered from 0 along the clip's
// timeline (a looping clip's timeline never ends). One producer at a time decodes into it (whoever holds claim(): a job, or
// the game thread); the mixer reads.
class StreamRing {
public:
    StreamRing(Resampler source, std::size_t capacityFrames)
        : source_(std::move(source)), buf_(capacityFrames * 2), cap_(capacityFrames) {}

    // ---- producer
    // The right to decode. Acquire: the producer before us released it after its last write (unclaim), so its decoder state
    // and indexes are visible here.
    bool claim() {
        bool expected = false;
        return busy_.compare_exchange_strong(expected, true, std::memory_order_acquire, std::memory_order_relaxed);
    }
    void unclaim() { busy_.store(false, std::memory_order_release); }  // release: pairs with claim()
    // Frames fill() could add now; 0 once the clip has ended.
    std::size_t room() const {
        if (end_.load(std::memory_order_acquire) != kNoEnd) return 0;
        return cap_ - std::size_t(write_.load(std::memory_order_relaxed) - read_.load(std::memory_order_acquire));
    }
    // Decodes up to `most` frames into the free part of the ring (only the claim holder calls it). Returns the frames made.
    std::size_t fill(std::size_t most);

    // ---- consumer (the mixer)
    // The frame at fractional position `pos` (interpolated with the next one). 1 = a frame; 0 = not decoded yet (an
    // underrun); -1 = the clip ended before it.
    int at(double pos, float& l, float& r) const {
        const std::uint64_t i0 = std::uint64_t(pos);
        // Acquire on write_ first: the producer stores end_ before it releases write_, so the end that goes with these
        // frames is visible too (an end seen without its frames is still "not decoded": i0 >= w below).
        const std::uint64_t w = write_.load(std::memory_order_acquire);
        const std::uint64_t end = end_.load(std::memory_order_acquire);
        if (i0 >= end) return -1;
        if (i0 >= w) return 0;
        const float* a = &buf_[2 * std::size_t(i0 % cap_)];
        if (i0 + 1 >= w) {
            if (i0 + 1 < end) return 0;
            l = a[0];  // the last frame of the clip
            r = a[1];
            return 1;
        }
        const float* b = &buf_[2 * std::size_t((i0 + 1) % cap_)];
        const float t = float(pos - double(i0));
        l = a[0] + (b[0] - a[0]) * t;
        r = a[1] + (b[1] - a[1]) * t;
        return 1;
    }
    // Hands the frames before `frame` back to the producer (never past what is decoded: a voice whose pitch jumped over the
    // last decoded frame still needs the frames from there). Release: the reads of those frames are done before the producer
    // (acquire in room()/fill()) overwrites them. The acquire on write_ only bounds the value.
    void release_before(std::uint64_t frame) {
        const std::uint64_t w = write_.load(std::memory_order_acquire);
        read_.store(frame < w ? frame : w, std::memory_order_release);
    }

    // The memory the voice holds. Only the claim holder may call it (it reads the decoder's state): the game caches it
    // after the prefill, which it makes under the claim.
    std::size_t resident_bytes() const { return buf_.size() * sizeof(float) + source_.resident_bytes(); }
    bool ended() const { return end_.load(std::memory_order_acquire) != kNoEnd; }

private:
    static constexpr std::uint64_t kNoEnd = ~std::uint64_t(0);
    Resampler source_;          // the claim holder's
    std::vector<float> buf_;    // cap_ stereo frames
    std::size_t cap_;
    std::atomic<std::uint64_t> write_{0};    // frames decoded (producer stores, release)
    std::atomic<std::uint64_t> read_{0};     // frames the mixer is done with (consumer stores, release)
    std::atomic<std::uint64_t> end_{kNoEnd}; // the clip's length once the decoder reached it (stored before write_)
    std::atomic<bool> busy_{false};
};

// Samples the game pushes for one voice (a video's sound, the editor's previews): stereo at `rate`, read by the mixer with
// linear interpolation. It holds two seconds: what the game pushes beyond that drops the oldest samples (the mixer skips
// them), and the storage (four seconds) is never overwritten while the mixer may read it, so when it is full the newest
// samples are dropped instead.
class PcmRing {
public:
    explicit PcmRing(int rate) : rate_(rate > 0 ? rate : 1), cap_(std::size_t(rate_) * 4), buf_(cap_ * 2) {}
    int rate() const { return rate_; }

    // ---- producer (the game thread)
    void push(const float* stereo, std::size_t frames);
    void clear() { skip_.store(write_.load(std::memory_order_relaxed), std::memory_order_release); }  // see skip()
    // Frames queued and not played yet, fractional (the mixer's position is published in 40.24 fixed point).
    double queued() const;

    // ---- consumer (the mixer)
    // Where the mixer must jump to (the frames before it were dropped). Acquire: pairs with the release in push()/clear().
    std::uint64_t skip() const { return skip_.load(std::memory_order_acquire); }
    // Frames pushed so far. Acquire: the samples below it are written (push() releases after copying them).
    std::uint64_t written() const { return write_.load(std::memory_order_acquire); }
    const float* frame(std::uint64_t i) const { return &buf_[2 * std::size_t(i % cap_)]; }
    // The mixer's position after a block. Release: its reads of the frames before it are done before push() reuses them.
    void consumed(double pos) {
        read_.store(std::uint64_t(pos), std::memory_order_release);
        pos_.store(std::uint64_t(pos * double(1 << 24)), std::memory_order_release);
    }

private:
    int rate_;
    std::size_t cap_;
    std::vector<float> buf_;
    std::atomic<std::uint64_t> write_{0};  // producer
    std::atomic<std::uint64_t> skip_{0};   // producer: frames before it are dropped
    std::atomic<std::uint64_t> read_{0};   // consumer: whole frames done with
    std::atomic<std::uint64_t> pos_{0};    // consumer: its position, 40.24 fixed point (for queued())
};

// Floats one thread writes and another reads, in bulk (the recorder: the mixer writes its output, the game drains it).
class SampleRing {
public:
    explicit SampleRing(std::size_t capacity) : buf_(round_up_pow2(capacity)), mask_(buf_.size() - 1) {}
    // Producer. Returns how many it wrote (fewer when full). Acquire on read_: the reader is done with what it released.
    // Release on write_: the samples are written before the reader sees the index.
    std::size_t write(const float* src, std::size_t n) {
        const std::uint64_t w = write_.load(std::memory_order_relaxed);
        const std::size_t room = buf_.size() - std::size_t(w - read_.load(std::memory_order_acquire));
        if (n > room) n = room;
        for (std::size_t i = 0; i < n; ++i) buf_[std::size_t((w + i) & mask_)] = src[i];
        write_.store(w + n, std::memory_order_release);
        return n;
    }
    // Consumer: appends everything waiting to `out`. Acquire on write_ (the samples are there), release on read_ (done with them).
    std::size_t drain(std::vector<float>& out, std::size_t most) {
        const std::uint64_t r = read_.load(std::memory_order_relaxed);
        std::size_t n = std::size_t(write_.load(std::memory_order_acquire) - r);
        if (n > most) n = most;
        for (std::size_t i = 0; i < n; ++i) out.push_back(buf_[std::size_t((r + i) & mask_)]);
        read_.store(r + n, std::memory_order_release);
        return n;
    }
    // Consumer: samples written and not drained yet. Acquire on write_ as in drain().
    std::size_t waiting() const {
        return std::size_t(write_.load(std::memory_order_acquire) - read_.load(std::memory_order_relaxed));
    }
    // Consumer: drops everything waiting. Release on read_: hands the slots back as drain() does.
    void skip_all() { read_.store(write_.load(std::memory_order_acquire), std::memory_order_release); }
    std::size_t lost() const { return lost_.load(std::memory_order_relaxed); }
    void add_lost(std::size_t n) { lost_.fetch_add(n, std::memory_order_relaxed); }  // a statistic: no ordering needed

private:
    std::vector<float> buf_;
    std::size_t mask_;
    std::atomic<std::uint64_t> write_{0}, read_{0};
    std::atomic<std::size_t> lost_{0};
};

// One voice in the mixer.
struct MixVoice {
    VoiceIdT id = 0;
    const Clip* clip = nullptr;   // null for a PCM voice
    StreamRing* stream = nullptr; // set for a streamed clip: `pos` then counts frames of the whole timeline
    PcmRing* pcm = nullptr;       // set for a voice the game feeds; `pos` is then the absolute frame in the ring
    double pos = 0.0;             // in clip frames (fractional for pitch)
    float volume = 1.0f, pitch = 1.0f, pan = 0.0f;
    bool loop = false;
    int bus = BusSfx;
    float fade = 1.0f, fadeTarget = 1.0f, fadeStep = 0.0f;
    long fadeFrames = 0;
    bool stopAtFadeEnd = false;
    // A ramp of `volume` itself (set_voice_volume with a fade): per frame `volume += volStep` for volFrames frames.
    float volTarget = 1.0f, volStep = 0.0f;
    long volFrames = 0;
    long delay = 0;  // output frames of silence left before it sounds (PlayParams::delayFrames)
    bool dead = false;
};

// The runtime state of one bus: its gain, its effects and its ducking. Moved over to the new table when the buses change.
struct BusRuntime {
    Ramp vol;   // the volume (the player's options; audio.setVolume)
    Ramp snap;  // the scale a snapshot sets
    // Low-pass: the cutoff moves in octaves (log2 of Hz).
    bool lpOn = false, lpOffAtEnd = false, lpDirty = false;
    Ramp lpLog;
    Lowpass lp;
    // Reverb: the game side allocates it the first time it is switched on and sends it with the command.
    bool rvOn = false, rvOffAtEnd = false;
    Ramp rvMix{0.0f, 0.0f, 0.0f, 0};
    std::unique_ptr<Reverb> rv;
    long rvQuiet = 0;  // frames since the bus last had a voice
    // Ducking.
    int duckBy = -1;
    float duckAmount = 0.0f;
    float duckAttack = 0.0f, duckRelease = 0.0f;  // one-pole coefficients
    float duckGain = 1.0f, duckEnv = 0.0f;
};

struct MixBus {
    int parent = kMasterBus;  // the bus this one is summed into
    int depth = 1;            // 1 = under the master; a bus is mixed after the buses under it
    BusRuntime rt;
};

// The bus table and every buffer the mixer needs for it, built whole on the game side (set_buses) and swapped in by a command.
struct MixTable {
    std::vector<MixBus> bus;
    std::vector<int> mixOrder;               // the buses but the master, deepest first: a bus is summed into its parent
    std::vector<std::vector<float>> busBuf;  // kScratchFrames stereo frames per bus
    std::vector<std::vector<float>> duckGains;
    std::vector<char> used, live, ducking;   // per-bus flags of one block
    // For the swap: per bus, the index in the table it replaces (-1: a new bus) and its ducking partner (-1: none); per bus
    // of the old table, the bus its voices move to.
    std::vector<int> fromOld, duckBy, voiceRemap;
    // Depths, order and buffers (game side, before the table is sent).
    void build();
};

// What the mixer publishes of a music transport.
struct MusicSnap {
    MusicTransportState state;
    std::uint64_t appliedSeq = 0;  // the last command the mixer had applied when it made this copy
    std::size_t backlog = 0;       // events still in the transport (not moved to the channel's ring yet)
};

// A MusicPlayer's transport in the mixer. The game owns it (and frees it once the command that removed it came back).
struct MusicChannel {
    MusicTransport tr;
    int bus = BusMusic;                     // mixer side
    TripleBuffer<MusicSnap> snap;           // mixer -> game
    SpscRing<MusicEvent> events{2048};      // mixer -> game
};

class Mixer;

// How a command is treated when the staging queue is full (Audio::Impl::drop_one): the oldest Droppable goes first (a play, a
// voice's volume/pitch/pan/bus), then the oldest Lossy (a bus or music setting); Keep commands (stops, removals, table swaps,
// starts of music, the recorder) are never dropped, they free or end something the game side waits for.
enum class CmdKind : std::uint8_t { Droppable, Lossy, Keep };

// What a Droppable or Lossy command sets, so that a dropped one is not lost for good: the game side marks that voice, bus or
// music player and sends its current state again once the staging queue has emptied (Audio::Impl::resync_dropped).
enum class SyncTarget : std::uint8_t { None, Voice, Bus, Music };
constexpr std::uint32_t kSyncAllBuses = 0xffffffffu;  // a snapshot sets every bus

// A Keep command that a later one with the same key makes useless (Audio::Impl::send, "coalesce"): the key is the kind in the
// top byte and a voice id below. 0 = never coalesced.
enum class CoalesceKind : std::uint8_t { None, Retune, Paused, ResetFx, StopAll };
constexpr std::uint64_t coalesce_key(CoalesceKind k, std::uint32_t id = 0) { return (std::uint64_t(k) << 32) | id; }

struct Cmd {
    std::uint64_t seq = 0;     // increasing; the mixer publishes the last one it applied
    std::uint64_t batch = 0;   // the commands of one API call: committed together, so applied in the same block
    CmdKind kind = CmdKind::Keep;
    SyncTarget sync = SyncTarget::None;  // Droppable/Lossy: what a drop leaves out of step
    std::uint32_t syncId = 0;            // the voice id (a bus is found by syncName; kSyncAllBuses: all of them)
    std::string syncName;                // Bus: the bus it sets, by name (a table swap moves the indexes under a stalled queue)
    std::uint64_t coalesceKey = 0;       // Keep: see CoalesceKind
    VoiceIdT play = 0;         // a play: the voice it starts (dropping it ends that voice on the game side)
    std::function<void(Mixer&, Cmd&)> run;  // runs on the mixer thread: no allocation, no lock
    // Carried to the mixer, or back from it to be freed on the game side with the command.
    std::unique_ptr<MixTable> table;
    std::unique_ptr<Reverb> reverb;
    std::unique_ptr<MusicChannel> channel;
    std::vector<std::shared_ptr<const MusicSource>> sources;
    std::shared_ptr<const void> keep;
    std::shared_ptr<SampleRing> rec;
};

struct Ret {
    enum Kind : std::uint8_t { Done, Ended } kind = Done;
    Cmd* cmd = nullptr;   // Done: the command, back to the game to free
    VoiceIdT voice = 0;   // Ended: the voice (natural end, stopped, or a play the full mixer refused)
};

class Mixer {
public:
    Mixer();
    ~Mixer();

    // ---- set by the game side while nothing mixes (before the device starts, after it stopped)
    // The device callback mixes only while `armed`: before init() set the rate (and after shutdown()) it outputs silence
    // and touches nothing else. The game sets the rate and the fill mode while unarmed and then stores `armed` with
    // release; render() loads it with acquire, so those plain writes are visible to the callback that sees it true.
    std::atomic<bool> armed{false};
    void set_device_rate(int rate) { deviceRate_ = rate > 0 ? rate : kRate; }
    int device_rate() const { return deviceRate_; }
    // The null device: the mixer runs on the game thread, so a streamed voice that has nothing decoded decodes right there.
    void set_sync_fill(bool on) { syncFill_ = on; }

    // ---- the queues (sizes: docs/SOUND.md, "The audio callback")
    SpscRing<Cmd*> commands{2048};
    SpscRing<Ret> returns{4096};

    // ---- the thread that mixes
    // Applies the committed commands while the return ring has room for what they can end. Publishes the music state after.
    void apply_commands();
    // The device callback: applies the commands, mixes `frames` frames (split into kScratchFrames blocks) and lays them out in
    // `channels` channels.
    void render(float* out, int frames, int channels);
    // Mixes up to kScratchFrames stereo frames into `out` (overwrites).
    void mix_block(float* out, int frames);
    float block_peak() const { return blockPeak_; }

    // Read by the game side. Each is one value written by the mixer alone: relaxed for the statistics, release/acquire
    // where the game acts on it (appliedSeq: the command and everything before it are done).
    std::atomic<std::uint64_t> appliedSeq{0};
    std::atomic<std::uint64_t> mixedTotal{0};
    std::atomic<std::uint64_t> underrunEvents{0};  // a streamed voice found nothing decoded (once per voice and block)
    std::atomic<std::uint64_t> underrunFrames{0};  // the frames of silence those played
    std::atomic<std::uint32_t> peakBits{0};        // the last block's peak (a float's bits)
    std::atomic<std::uint64_t> callbacks{0};       // device callbacks so far
    std::atomic<int> firstCallbackFrames{0}, firstCallbackChannels{0};

    // ---- state the commands change (mixer thread only)
    std::array<MixVoice, kMaxVoices> voices{};
    std::size_t voiceCount = 0;
    std::unique_ptr<MixTable> table;
    std::array<MusicChannel*, kMaxPlayers> players{};
    std::size_t playerCount = 0;
    SampleRing* rec = nullptr;
    bool paused = false;

    MixVoice* find_voice(VoiceIdT id);
    // Adds a voice; false when every slot is taken (the game side keeps at most kMaxVoices, so only a bug gets there).
    bool add_voice(const MixVoice& v);
    // Removes a voice now and tells the game (the command that asks has checked there is room in `returns`).
    void end_voice(VoiceIdT id);
    void end_all_voices();
    void add_player(MusicChannel* ch);
    void remove_player(MusicChannel* ch);
    void swap_table(Cmd& cmd);

    long ramp_frames(float seconds, bool declick) const;
    void start_fade(MixVoice& v, float target, float seconds, bool stopAtEnd) const;
    void start_volume_ramp(MixVoice& v, float target, float seconds) const;
    void set_lowpass(BusRuntime& fx, float hz, float fadeSeconds) const;
    void set_reverb(BusRuntime& fx, float mix, float fadeSeconds, std::unique_ptr<Reverb>& spare) const;
    void set_duck(BusRuntime& fx, int by, float amount, float attack, float release) const;
    void publish_music();

private:
    void mix_voices(int frames);
    void mix_pcm(MixVoice& v, float* out, int frames);
    void mix_stream(MixVoice& v, float* out, int frames, float gl, float gr, int first);
    bool run_effects(BusRuntime& fx, float* buf, int frames, bool used);
    static void apply_bus_gain(BusRuntime& fx, float* buf, int frames, bool live);
    void compute_duck(int d, int frames);
    void sweep_dead();

    int deviceRate_ = kRate;
    bool syncFill_ = true;
    float blockPeak_ = 0.0f;
    std::vector<float> tmp_;  // render(): the stereo mix of a device that is not stereo
};

}  // namespace fa::audio_detail
