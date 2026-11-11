#include "music_stream.h"

#include <algorithm>
#include <cstring>

namespace fa::audio_detail {

std::shared_ptr<MusicStemStream> MusicStemStream::open(std::shared_ptr<const Bytes> bytes, std::string_view ext, std::string* why) {
    auto fail = [&](const char* text) {
        if (why) *why = text;
        return std::shared_ptr<MusicStemStream>();
    };
    if (!bytes || bytes->empty()) return fail("the file is empty");
    if (ext != ".ogg") return fail("only .ogg stems stream");
    std::string problem;
    auto dec = open_decoder(bytes->data(), bytes->size(), ext, &problem);
    if (!dec) return fail("it is not a valid OGG Vorbis file");
    if (dec->rate() != kMixRate) return fail("it is not 44100 Hz");
    if (dec->channels() < 1 || dec->channels() > 2) return fail("it is neither mono nor stereo");
    if (dec->frames() == 0) return fail("its length is not in the file header");
    std::shared_ptr<MusicStemStream> s(new MusicStemStream());
    s->frames_ = std::int64_t(dec->frames());
    s->channels_ = dec->channels();
    s->bytes_ = std::move(bytes);
    s->dec_ = std::move(dec);
    s->scratch_.resize(std::size_t(kMusicChunkFrames) * std::size_t(s->channels_));
    for (Slot& slot : s->slots_) slot.data.assign(std::size_t(kMusicChunkFrames) * 2, 0.0f);
    s->resident_ = s->bytes_->size() + kMusicSlots * std::size_t(kMusicChunkFrames) * 2 * sizeof(float) + s->scratch_.size() * sizeof(float);
    s->decodePos_ = 0;
    // The last chunk proves the length (the decoder gives as many frames as the header says) and that seeking lands.
    if (!s->claim()) return fail("internal error");
    s->ensure(s->chunk_count() - 1, false);
    s->unclaim();
    if (s->decode_errors() != 0) return fail("its length differs from the header or it cannot seek");
    return s;
}

const float* MusicStemStream::pin(std::int64_t chunk, int* slot) {
    const std::uint64_t ready = ready_word(chunk);
    for (std::size_t i = 0; i < slots_.size(); ++i) {
        std::atomic<std::uint64_t>& st = slots_[i].state;
        std::uint64_t s = st.load(std::memory_order_acquire);
        while ((s & ~kReaders) == ready) {  // holds the chunk and is not LOADING (the word differs otherwise)
            if ((s & kReaders) == kReaders) return nullptr;
            // Acquire: the decoder's writes of the chunk (released with the ready word) are visible. On failure `s` is reloaded.
            if (st.compare_exchange_weak(s, s + 1, std::memory_order_acquire, std::memory_order_acquire)) {
                *slot = int(i);
                return slots_[i].data.data();
            }
        }
    }
    return nullptr;
}

bool MusicStemStream::resident(std::int64_t chunk) const {
    const std::uint64_t ready = ready_word(chunk);
    for (const Slot& s : slots_)
        if ((s.state.load(std::memory_order_acquire) & ~kReaders) == ready) return true;
    return false;
}

std::size_t MusicStemStream::decoded_chunks() const {
    std::size_t n = 0;
    for (const Slot& s : slots_) n += (s.state.load(std::memory_order_relaxed) & ~(kReaders | kLoading)) != 0 ? 1 : 0;
    return n;
}

bool MusicStemStream::wanted_or_primed(std::int64_t chunk) const {
    for (std::size_t i = 0; i < wantedCount_; ++i)
        if (wanted_[i] == chunk) return true;
    for (const Primed& p : primed_)
        if (p.chunk == chunk && p.until >= tick_) return true;
    return false;
}

void MusicStemStream::set_wanted(const std::int64_t* chunks, std::size_t n) {
    ++tick_;
    wantedCount_ = std::min(n, wanted_.size());
    for (std::size_t i = 0; i < wantedCount_; ++i) wanted_[i] = chunks[i];
}

bool MusicStemStream::missing_any() const {
    const std::int64_t count = chunk_count();
    for (std::size_t i = 0; i < wantedCount_; ++i)
        if (wanted_[i] >= 0 && wanted_[i] < count && !resident(wanted_[i])) return true;
    return false;
}

// A slot for `forChunk`, already marked LOADING with its word: an empty one, else the one farthest from the chunk that nobody reads and (when
// asked) nobody wants.
int MusicStemStream::take_slot(std::int64_t forChunk, bool respectWanted) {
    const std::uint64_t mine = ready_word(forChunk) | kLoading;
    bool skip[kMusicSlots] = {};
    for (std::size_t round = 0; round < slots_.size(); ++round) {
        int best = -1;
        std::int64_t bestDistance = -1;
        std::uint64_t bestWord = 0;
        for (std::size_t i = 0; i < slots_.size(); ++i) {
            if (skip[i]) continue;
            const std::uint64_t s = slots_[i].state.load(std::memory_order_acquire);
            if (s == 0) {
                best = int(i);
                bestWord = s;
                break;
            }
            if ((s & (kReaders | kLoading)) != 0) continue;  // read right now, or being filled
            const std::int64_t c = std::int64_t(s >> 16) - 1;
            if (respectWanted && wanted_or_primed(c)) continue;
            const std::int64_t d = c > forChunk ? c - forChunk : forChunk - c;
            if (d > bestDistance) {
                best = int(i);
                bestDistance = d;
                bestWord = s;
            }
        }
        if (best < 0) return -1;
        std::uint64_t expected = bestWord;
        // Acquire: the mixer's reads of the old chunk (it unpinned with release) are finished before we overwrite it.
        if (slots_[std::size_t(best)].state.compare_exchange_strong(expected, mine, std::memory_order_acquire, std::memory_order_relaxed))
            return best;
        skip[best] = true;  // a reader pinned it in between: try another
    }
    return -1;
}

std::size_t MusicStemStream::decode_into(int slot, std::int64_t chunk) {
    const std::int64_t start = chunk * kMusicChunkFrames;
    const std::size_t want = std::size_t(std::min(kMusicChunkFrames, frames_ - start));
    std::size_t got = 0;
    bool ok = true;
    if (decodePos_ != start) {
        ok = dec_->seek(std::uint64_t(start));
        if (ok) decodePos_ = start;
    }
    if (ok) {
        got = dec_->read(scratch_.data(), want);
        decodePos_ = start + std::int64_t(got);
        if (got < want) ok = false;
    }
    if (!ok) {
        decodePos_ = -1;  // the next chunk seeks
        decodeErrors_.fetch_add(1, std::memory_order_relaxed);
    }
    float* d = slots_[std::size_t(slot)].data.data();
    if (channels_ == 2) {
        std::memcpy(d, scratch_.data(), got * 2 * sizeof(float));
    } else {
        for (std::size_t i = 0; i < got; ++i) d[2 * i] = d[2 * i + 1] = scratch_[i];
    }
    std::fill(d + got * 2, d + std::size_t(kMusicChunkFrames) * 2, 0.0f);
    return got;
}

bool MusicStemStream::ensure(std::int64_t chunk, bool respectWanted) {
    if (chunk < 0 || chunk >= chunk_count()) return false;
    if (resident(chunk)) return true;
    const int slot = take_slot(chunk, respectWanted);
    if (slot < 0) return false;
    decode_into(slot, chunk);
    // Release: the chunk's samples are written before the mixer (acquire in pin) can see the ready word.
    slots_[std::size_t(slot)].state.store(ready_word(chunk), std::memory_order_release);
    return true;
}

std::size_t MusicStemStream::fill_wanted(std::size_t most) {
    std::size_t made = 0;
    const std::int64_t count = chunk_count();
    for (std::size_t i = 0; i < wantedCount_ && made < most; ++i) {
        const std::int64_t c = wanted_[i];
        if (c < 0 || c >= count || resident(c)) continue;
        if (!ensure(c, true)) break;  // the window is full of chunks that are wanted
        ++made;
    }
    return made;
}

void MusicStemStream::prime(std::int64_t first, std::int64_t count) {
    for (std::int64_t c = first; c < first + count; ++c) {
        if (c < 0 || c >= chunk_count()) continue;
        Primed& p = primed_[primedNext_];
        primedNext_ = (primedNext_ + 1) % primed_.size();
        p.chunk = c;
        p.until = tick_ + 240;
        ensure(c, true);
    }
}

bool MusicStemStream::decode_now(std::int64_t chunk) { return ensure(chunk, false); }

}  // namespace fa::audio_detail
