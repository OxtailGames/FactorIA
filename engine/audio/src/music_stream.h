// A music stem that streams from its ogg (private to fa_audio): M101.1b. Instead of decoding the whole stem into 16-bit PCM, the stem keeps
// its encoded bytes and a window of decoded chunks. A chunk is kMusicChunkFrames stereo float frames of the stem's own timeline (chunk c is
// frames c*K .. c*K+K-1), so a read is addressed by song position, not by playhead: a section jump, a loop wrap, a ghost head of a crossfade
// and a stinger all read the same store, and a stem that is silent costs nothing but a decode that is kept ahead anyway.
//
// Threads. One thread mixes (the device callback, or the game thread on the null device and the web) and reads; at most one other thread at a
// time decodes (whoever holds claim(): the audio service thread, or the game thread when it primes). The mixer never waits for the decoder
// and never allocates: a chunk that is not decoded when it is needed plays as silence and is counted (underruns), as a dry ring of a streamed
// clip does. On the null device and the web the mixer decodes the chunk itself (decode_now) so a headless run has every sample.
//
// Who keeps the window ahead. Not the game: its thread can stall for seconds (a long scene load, a breakpoint, a minimized window) and the
// music has to go on. The mixer publishes, for each stem, where its playheads and waiting jumps read (publish_head, relaxed atomics, once per
// callback); the audio service thread reads that (service) and decodes what is missing, whatever the game is doing. A jump that is about to
// happen is primed by the game (prime) before it sends the command; if the service thread is decoding at that moment the game waits for the
// claim (claim_wait) for the time of one chunk, because the decoder yields to a waiter between chunks.
//
// The handshake between the two is one atomic word per slot: (chunk + 1) << 16 | LOADING << 15 | readers. The mixer pins a slot (readers + 1,
// compare-exchange) only while it holds the chunk it wants and is not LOADING, and unpins when its block is done. The decoder takes a slot
// for another chunk only by a compare-exchange from "no readers" to LOADING, and then nobody reads it until it stores the new ready word with
// release. So a slot is never written while the mixer may read it, whatever the producer believed about where the playheads are.
#pragma once

#include <array>
#include <atomic>
#include <cstddef>
#include <cstdint>
#include <memory>
#include <string>
#include <string_view>
#include <vector>

#include "audio_decoder.h"
#include "fa/core/types.h"

namespace fa::audio_detail {

constexpr int kMusicChunkShift = 13;
constexpr std::int64_t kMusicChunkFrames = std::int64_t(1) << kMusicChunkShift;  // 8192 frames: 186 ms at 44100 Hz
// The window: 32 chunks, 6 s. A crossfade inside one song reads two heads (12 chunks of look-ahead each) and a jump just primed keeps up to 8
// protected, so 12 + 12 + 8 fills it; kMusicWantedMax never exceeds it, or the service would want what the window cannot hold.
constexpr std::size_t kMusicSlots = 32;
constexpr std::size_t kMusicWantedMax = kMusicSlots;  // chunks the service asks to keep decoded at once
constexpr std::int64_t kMusicLookAhead = 12;          // chunks ahead of a playhead kept decoded (2.2 s)
constexpr std::int64_t kMusicUrgent = 4;              // chunks of each playhead decoded before any other

// Underruns of many stems added up (the Audio owns one; a stem adds to it as well as to its own count, so a source that leaves the music
// cache while it still plays keeps being counted in stats()).
struct MusicTally {
    std::atomic<std::uint64_t> events{0}, frames{0};
};

// One stem. The mixer side (pin/unpin/note_underrun) and the producer side (everything else, under claim()) are separate.
class MusicStemStream {
public:
    // Opens an .ogg (44100 Hz, 1 or 2 channels) for streaming. Null with *why (a sentence) when it cannot stream: the caller decodes it whole.
    // It decodes the last chunk once, which proves the length in the header and that seeking works.
    static std::shared_ptr<MusicStemStream> open(std::shared_ptr<const Bytes> bytes, std::string_view ext,
                                                 std::string* why);

    std::int64_t frames() const { return frames_; }
    std::int64_t chunk_count() const { return (frames_ + kMusicChunkFrames - 1) / kMusicChunkFrames; }
    // The memory the stem holds, constant for its life: the encoded bytes, the window and the decoder's scratch buffer (the decoder's own
    // state, about 100 KB, is not counted).
    std::size_t resident_bytes() const { return resident_; }

    // ---- the mixer side (never waits, never allocates)
    // Pins the slot that holds `chunk`: the data (2 * kMusicChunkFrames floats, interleaved) or null when it is not decoded. `*slot` is the
    // handle for unpin(). A pinned slot is never reused.
    const float* pin(std::int64_t chunk, int* slot);
    void unpin(int slot) { slots_[std::size_t(slot)].state.fetch_sub(1, std::memory_order_release); }
    void note_underrun(std::uint64_t frames) {
        underrunEvents_.fetch_add(1, std::memory_order_relaxed);
        underrunFrames_.fetch_add(frames, std::memory_order_relaxed);
        if (tally_) {
            tally_->events.fetch_add(1, std::memory_order_relaxed);
            tally_->frames.fetch_add(frames, std::memory_order_relaxed);
        }
    }
    // Before the stem reaches the mixer (the game thread, when the song enters the cache): where else its underruns are added.
    void set_tally(std::shared_ptr<MusicTally> tally) {
        FA_ASSERT(!tally_, "set_tally is called once, before the mixer sees the stem");
        tally_ = std::move(tally);
    }
    std::uint64_t underrun_events() const { return underrunEvents_.load(std::memory_order_relaxed); }
    std::uint64_t underrun_frames() const { return underrunFrames_.load(std::memory_order_relaxed); }

    // Where a playhead (or a waiting jump) of this stem reads, from song frames: the mixer calls it for each want after each publish of the
    // transport, with the same `seq` (Mixer::musicSeq) for all the calls of one publish. Mixer thread only; never allocates.
    void publish_head(std::uint64_t seq, double pos, double end, double wrapStart, bool wraps);

    // ---- the producer side
    // The right to decode (and to touch the wanted list). Acquire pairs with the release of unclaim().
    bool claim() {
        bool expected = false;
        return busy_.compare_exchange_strong(expected, true, std::memory_order_acquire, std::memory_order_relaxed);
    }
    void unclaim() { busy_.store(false, std::memory_order_release); }
    // claim() that waits for the holder, for the time of a chunk (the holder yields to a waiter between chunks, fill_wanted); false after a
    // safety deadline of half a second, far above that (a test sets another one with set_claim_wait_limit, so a loaded machine cannot reach it).
    bool claim_wait();
    void set_claim_wait_limit(int milliseconds) { claimWaitMs_.store(milliseconds, std::memory_order_relaxed); }
    int waiters() const { return waiters_.load(std::memory_order_relaxed); }
    // The mixer's publish counter (Mixer::musicSeq, one per audio block) as the service thread read it: chunks of prime() stay protected
    // for kPrimedBlocks of them, whatever the pace of the service thread.
    void tick(std::uint64_t pass) { pass_.store(pass, std::memory_order_relaxed); }
    // One pass of the service thread: when the mixer published this stem lately (`mixSeq` is the mixer's current Mixer::musicSeq), takes the
    // claim (skips the stem when someone else has it), turns the published heads into the wanted chunks and decodes the missing ones. With
    // `urgentOnly` only the first kMusicUrgent chunks of every head (the pass runs that round on every stem before the full one, so a stem
    // with a long way to fill does not keep another one waiting). True when a wanted chunk is still missing and the thread can make
    // progress on it (it comes back soon): false when the window is full of chunks that are wanted, which nothing can fix by trying again.
    bool service(std::uint64_t mixSeq, bool urgentOnly = false);
    // True when the mixer published this stem within the last few publishes.
    bool live(std::uint64_t mixSeq) const;
    // Replaces the chunks to keep decoded, most urgent first (at most kMusicWantedMax). Chunks decoded by prime() stay protected for a while.
    void set_wanted(const std::int64_t* chunks, std::size_t n);
    // True when a wanted chunk is not decoded.
    bool missing_any() const;
    // Decodes up to `most` of the first `upTo` wanted chunks that are not decoded, in order, and stops early when a claim_wait() is waiting.
    // Returns how many it made.
    std::size_t fill_wanted(std::size_t most, std::size_t upTo = kMusicWantedMax);
    // Decodes chunks [first, first + count) now and keeps them out of the way of eviction for the next kPrimedBlocks audio blocks. The game uses it
    // before it sends a command that jumps somewhere, so the target is there whatever the jobs are doing.
    void prime(std::int64_t first, std::int64_t count);
    // Decodes `chunk` into any slot nobody reads (the null device and the web, on the thread that mixes). False if it could not.
    bool decode_now(std::int64_t chunk);
    bool resident(std::int64_t chunk) const;
    std::size_t decoded_chunks() const;  // slots holding a chunk (a statistic)
    // Decodes of a chunk whose seek or read failed (it plays as silence) and chunks that came out shorter than the header said.
    std::uint64_t decode_errors() const { return decodeErrors_.load(std::memory_order_relaxed); }

private:
    MusicStemStream() = default;
    struct Slot {
        std::atomic<std::uint64_t> state{0};  // see the top of the file; 0 = empty
        std::vector<float> data;
    };
    static constexpr std::uint64_t kReaders = 0x7fff, kLoading = 0x8000;
    static std::uint64_t ready_word(std::int64_t chunk) { return std::uint64_t(chunk + 1) << 16; }

    static constexpr std::uint64_t kPrimedBlocks =
        200;  // audio blocks the mixer publishes: 2.3 s at 512 frames and 44100 Hz
    static constexpr std::size_t kMaxHeads = 16;

    bool wanted_or_primed(std::int64_t chunk) const;
    void refresh_wanted();                                     // wanted_ from the published heads
    int take_slot(std::int64_t forChunk, bool respectWanted);  // a slot set to LOADING for forChunk, or -1
    std::size_t decode_into(int slot,
                            std::int64_t chunk);  // frames the decoder gave (the rest of the chunk is silence)
    bool ensure(std::int64_t chunk, bool respectWanted);

    std::shared_ptr<const Bytes> bytes_;
    std::unique_ptr<Decoder> dec_;
    std::int64_t frames_ = 0;
    int channels_ = 2;
    std::size_t resident_ = 0;
    std::array<Slot, kMusicSlots> slots_;
    std::vector<float> scratch_;  // the decoder's output before it is made stereo
    // The producer's (claim holder's):
    std::int64_t decodePos_ = 0;  // the frame the decoder returns next (-1: unknown, seek first)
    std::array<std::int64_t, kMusicWantedMax> wanted_{};
    std::size_t wantedCount_ = 0;
    std::size_t urgentCount_ = 0;  // the first of wanted_ that are the urgent round of refresh_wanted
    struct Primed {
        std::int64_t chunk = -1;
        std::uint64_t until = 0;
    };
    std::array<Primed, 8> primed_{};
    std::size_t primedNext_ = 0;
    std::atomic<std::uint64_t> pass_{0};
    std::atomic<bool> busy_{false};
    std::atomic<int> waiters_{0};
    std::atomic<int> claimWaitMs_{500};
    // Published by the mixer (publish_head), read by the service thread. Advisory: a read that mixes two publishes only decodes a chunk
    // that is not needed or one pass late. A head is packed: chunk of the position (21 bits), last chunk (21), chunk the loop continues from
    // (21), wraps (1).
    std::array<std::atomic<std::uint64_t>, kMaxHeads> heads_{};
    std::atomic<std::size_t> headCount_{0};
    std::atomic<std::uint64_t> stamp_{0};  // the seq of the last publish (0 = never)
    std::uint64_t pubSeq_ = 0;             // mixer thread only
    std::size_t pubCount_ = 0;
    std::atomic<std::uint64_t> underrunEvents_{0}, underrunFrames_{0}, decodeErrors_{0};
    std::shared_ptr<MusicTally> tally_;  // set once, before the mixer can see the stem
};

}  // namespace fa::audio_detail
