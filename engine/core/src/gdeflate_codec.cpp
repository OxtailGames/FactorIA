// GDeflate: the GPU-friendly Deflate64 stream that DirectStorage 1.1 decompresses on the GPU. Written for the engine
// from the published description of the format (a Deflate64 bitstream cut into 64 KiB tiles, each tile interleaved
// over 32 sub-streams); no code of the reference implementation is used. See docs/design/ARCHITECTURE_FILES.md,
// "GDeflate", for the layout this file implements and how it is tested against the reference.
//
// Stream: an 8-byte header { id = 4, magic = 0xFB, numTiles u16, u32 { tileSizeIdx (2 bits) = 1, lastTileSize (18
// bits; 0 = a full tile), reserved (12 bits) = 0 } }, a table of numTiles u32 (entry 0 is the compressed size of the
// LAST tile, entry i > 0 the offset of tile i in the tile data), then the tile data. A tile holds up to 65536 bytes.
//
// Tile: the bits of an ordinary Deflate64 stream (one or more blocks) dealt to 32 lanes. Each lane has a 64-bit buffer
// that starts with the first 32 bits of the lane; the stream starts with those 32 words in lane order. Whenever a lane
// has used its buffer down to fewer than 32 bits it takes the next 32-bit word of the stream, so the words appear in
// the order the lanes ask for them. The symbols of a block go to the lanes round-robin from lane 0; a match takes its
// length symbol (and extra bits) in its lane and its distance (symbol and extra bits) in the SAME lane one round later,
// so that lane skips one symbol; the end-of-block symbol is followed by one more round for the pending distances. A
// block header goes to lane 0 (3 bits, then for a dynamic block 5 + 5 + 4 bits), the 3-bit precode lengths go to lanes
// 0, 1, 2 ..., the code-length symbols round-robin from lane 0, a stored block is a 16-bit length in lane 0 (no
// alignment, no complement) followed by one byte per lane round-robin from lane 0. Deflate64 differences: length
// symbol 285 is length 3 + 16 extra bits, distance symbols 30 and 31 exist (up to 65536). Matches never leave their tile.
//
// Pure, deterministic, thread-safe (no global state); everything is little-endian and 64-bit safe for wasm32.
#include <algorithm>
#include <array>
#include <bit>
#include <cstdint>
#include <cstring>
#include <span>
#include <string>
#include <vector>

#include "compress_internal.h"

namespace fa::codec {

namespace {

constexpr std::size_t kTileSize = 65536;
constexpr unsigned kLanes = 32;
constexpr std::size_t kHeaderBytes = 8;
constexpr std::size_t kPreambleBytes = kLanes * 4;  // the first 32-bit word of every lane
constexpr std::uint8_t kStreamId = 4;
constexpr std::uint8_t kStreamMagic = 0xFB;  // id ^ 0xFF
constexpr unsigned kMaxMatch = 65538;  // symbol 285: 3 + 16 extra bits
constexpr unsigned kMinMatch = 3;
constexpr std::uint32_t kNone = 0xFFFFFFFFu;

// Deflate64 tables. Length symbols 257..285 (index 0..28), distance symbols 0..31.
constexpr std::array<std::uint16_t, 29> kLenBase = {3,  4,  5,  6,  7,  8,  9,  10, 11,  13,  15,  17,  19,  23, 27,
                                                    31, 35, 43, 51, 59, 67, 83, 99, 115, 131, 163, 195, 227, 3};
constexpr std::array<std::uint8_t, 29> kLenExtra = {0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2,
                                                    2, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5, 16};
constexpr std::array<std::uint32_t, 32> kDistBase = {1,   2,   3,   4,   5,   7,    9,    13,   17,   25,   33,
                                                     49,  65,  97,  129, 193, 257,  385,  513,  769,  1025, 1537,
                                                     2049, 3073, 4097, 6145, 8193, 12289, 16385, 24577, 32769, 49153};
constexpr std::array<std::uint8_t, 32> kDistExtra = {0, 0, 0, 0, 1, 1, 2, 2, 3, 3,  4,  4,  5,  5,  6,  6,
                                                     7, 7, 8, 8, 9, 9, 10, 10, 11, 11, 12, 12, 13, 13, 14, 14};
constexpr std::array<std::uint8_t, 19> kPrecodeOrder = {16, 17, 18, 0, 8, 7, 9, 6, 10, 5, 11, 4, 12, 3, 13, 2, 14, 1, 15};

constexpr unsigned kEndOfBlock = 256;
constexpr unsigned kNumLitLen = 288;
constexpr unsigned kNumDist = 32;
constexpr unsigned kNumPrecode = 19;

// ---- Encoder --------------------------------------------------------------------------------------------------------

// Length (3..258) -> index of its symbol among 257..284.
struct LenSlotTable {
    std::array<std::uint8_t, 259> slot{};
    constexpr LenSlotTable() {
        for (unsigned len = 3; len <= 258; ++len) {
            unsigned s = 0;
            for (unsigned i = 0; i < 28; ++i)
                if (kLenBase[i] <= len) s = i;
            slot[len] = static_cast<std::uint8_t>(s);
        }
    }
};
constexpr LenSlotTable kLenSlots{};

// Distance (1..65536) -> distance symbol.
inline unsigned dist_slot(unsigned dist) {
    const unsigned d = dist - 1;
    if (d < 4) return d;
    const unsigned n = 31u - static_cast<unsigned>(std::countl_zero(d));
    return 2 * n + ((d >> (n - 1)) & 1u);
}

inline std::uint32_t reverse_bits(std::uint32_t code, unsigned len) {
    std::uint32_t r = 0;
    for (unsigned i = 0; i < len; ++i) {
        r = (r << 1) | (code & 1u);
        code >>= 1;
    }
    return r;
}

// Code lengths (at most `maxLen` bits) of a Huffman code for `n` symbols. At least two symbols always get a code (a
// code of one symbol is incomplete, which some decoders refuse). Too long codes are fixed by halving the frequencies.
void huffman_lengths(const std::uint32_t* freq, unsigned n, unsigned maxLen, std::uint8_t* lens) {
    std::array<std::uint32_t, kNumLitLen> f{};
    unsigned used = 0;
    for (unsigned s = 0; s < n; ++s) {
        f[s] = freq[s];
        used += f[s] != 0;
    }
    for (unsigned s = 0; s < n && used < 2; ++s)
        if (f[s] == 0) {
            f[s] = 1;
            ++used;
        }
    for (;;) {
        std::array<std::uint16_t, kNumLitLen> order{};
        unsigned m = 0;
        for (unsigned s = 0; s < n; ++s)
            if (f[s]) order[m++] = static_cast<std::uint16_t>(s);
        std::sort(order.begin(), order.begin() + m, [&](std::uint16_t a, std::uint16_t b) {
            return f[a] != f[b] ? f[a] < f[b] : a < b;
        });
        // Two-queue construction: the leaves in order, and the internal nodes, which are created in order too.
        std::array<std::uint32_t, 2 * kNumLitLen> weight{};
        std::array<std::uint16_t, 2 * kNumLitLen> left{}, right{}, depth{};
        for (unsigned i = 0; i < m; ++i) weight[i] = f[order[i]];
        unsigned leaf = 0, node = m, made = m;
        auto take = [&]() -> unsigned {
            if (leaf < m && (node >= made || weight[leaf] <= weight[node])) return leaf++;
            return node++;
        };
        for (unsigned k = 0; k + 1 < m; ++k) {
            const unsigned a = take();
            const unsigned b = take();
            weight[made] = weight[a] + weight[b];
            left[made] = static_cast<std::uint16_t>(a);
            right[made] = static_cast<std::uint16_t>(b);
            ++made;
        }
        unsigned maxDepth = 0;
        for (unsigned k = made - 1; k >= m && k < made; --k) {
            depth[left[k]] = static_cast<std::uint16_t>(depth[k] + 1);
            depth[right[k]] = static_cast<std::uint16_t>(depth[k] + 1);
        }
        for (unsigned i = 0; i < m; ++i) maxDepth = std::max<unsigned>(maxDepth, depth[i]);
        if (maxDepth <= maxLen) {
            for (unsigned s = 0; s < n; ++s) lens[s] = 0;
            for (unsigned i = 0; i < m; ++i) lens[order[i]] = static_cast<std::uint8_t>(depth[i]);
            return;
        }
        for (unsigned s = 0; s < n; ++s)
            if (f[s]) f[s] = (f[s] + 1) >> 1;
    }
}

// Canonical codewords, bit-reversed for an LSB-first stream.
void canonical_codes(const std::uint8_t* lens, unsigned n, std::uint16_t* codes) {
    std::array<unsigned, 16> count{};
    for (unsigned s = 0; s < n; ++s) ++count[lens[s]];
    count[0] = 0;
    std::array<unsigned, 17> next{};
    unsigned code = 0;
    for (unsigned l = 1; l <= 15; ++l) {
        code = (code + count[l - 1]) << 1;
        next[l] = code;
    }
    for (unsigned s = 0; s < n; ++s) {
        const unsigned l = lens[s];
        codes[s] = l ? static_cast<std::uint16_t>(reverse_bits(next[l]++, l)) : 0;
    }
}

// The 32 lanes of a tile being written: each lane collects bits and flushes 32-bit words into the place the decoder
// will read them from. A word is reserved for a lane in the order the decoder's lanes ask for one, which is when the
// lane (as the decoder sees it) has fewer than 32 bits left.
class LaneWriter {
public:
    void start(std::vector<std::uint8_t>& out) {
        out_ = &out;
        out.assign(kPreambleBytes, 0);
        idx_ = 0;
        for (unsigned n = 0; n < kLanes; ++n) {
            bitbuf_[n] = 0;
            bitcount_[n] = 0;
            input_[n] = 32;  // the decoder starts with one word per lane
            write_[n] = n * 4;
            next_[n] = kNone;
        }
    }
    void reset_lane() { idx_ = 0; }
    unsigned lane() const { return idx_; }
    void set_lane(unsigned n) { idx_ = n; }
    // Moves to the next lane; the result is 1 when the lanes wrapped around (a new round starts).
    unsigned advance() {
        idx_ = (idx_ + 1) & (kLanes - 1);
        return idx_ == 0 ? 1u : 0u;
    }
    void add(std::uint32_t bits, unsigned count) {
        const unsigned l = idx_;
        bitbuf_[l] |= static_cast<std::uint64_t>(bits) << bitcount_[l];
        bitcount_[l] += static_cast<int>(count);
        input_[l] -= static_cast<int>(count);
        if (bitcount_[l] >= 32) {
            if (next_[l] == kNone) reserve(l);  // not reachable: the decoder-side count is always ahead
            store32(out_->data() + write_[l], static_cast<std::uint32_t>(bitbuf_[l]));
            bitbuf_[l] >>= 32;
            bitcount_[l] -= 32;
            write_[l] = next_[l];
            next_[l] = kNone;
        }
        if (input_[l] < 32 && next_[l] == kNone) reserve(l);
    }
    // Writes what every lane still holds. The stream is complete afterwards.
    void finish() {
        for (unsigned l = 0; l < kLanes; ++l)
            store32(out_->data() + write_[l], static_cast<std::uint32_t>(bitbuf_[l]));
    }

private:
    void reserve(unsigned l) {
        next_[l] = static_cast<std::uint32_t>(out_->size());
        out_->resize(out_->size() + 4, 0);
        input_[l] += 32;
    }
    std::vector<std::uint8_t>* out_ = nullptr;
    std::array<std::uint64_t, kLanes> bitbuf_{};
    std::array<int, kLanes> bitcount_{};
    std::array<int, kLanes> input_{};
    std::array<std::size_t, kLanes> write_{};
    std::array<std::uint32_t, kLanes> next_{};
    unsigned idx_ = 0;
};

struct Token {
    std::uint32_t length;  // 0: a literal (the byte is in `value`), else the match length 3..65538
    std::uint32_t value;   // the literal byte, or the match distance 1..65535
};

struct LevelParams {
    unsigned chain;  // candidates looked at per position
    unsigned nice;   // a match this long ends the search
    bool lazy;
};

LevelParams level_params(int level) {
    static constexpr LevelParams table[12] = {{4, 16, false},   {8, 32, false},    {16, 64, false},    {16, 32, true},
                                              {24, 48, true},   {48, 128, true},   {96, 192, true},    {192, 258, true},
                                              {384, 512, true}, {768, 1024, true}, {1536, 2048, true}, {4096, 4096, true}};
    return table[std::clamp(level, 1, 12) - 1];
}

class TileEncoder {
public:
    explicit TileEncoder(int level) : params_(level_params(level)), head_(1u << kHashBits), prev_(kTileSize) {
        tokens_.reserve(kTileSize);
    }

    // Appends the tile's stream (a multiple of 4 bytes) to `out`.
    void encode(const std::uint8_t* tile, std::size_t n, std::vector<std::uint8_t>& out) {
        parse(tile, n);
        write_dynamic(dynamic_);
        const std::vector<std::uint8_t>* best = &dynamic_;
        // A stored tile costs about n + 128 bytes: only worth building when the Huffman stream is that big.
        if (dynamic_.size() >= n + 96) {
            write_stored(tile, n, stored_);
            if (stored_.size() <= dynamic_.size()) best = &stored_;
        }
        out.insert(out.end(), best->begin(), best->end());
    }

private:
    static constexpr unsigned kHashBits = 15;
    struct Match {
        unsigned length = 0;
        unsigned distance = 0;
    };

    unsigned hash(const std::uint8_t* p) const {
        const std::uint32_t v = static_cast<std::uint32_t>(p[0]) | (static_cast<std::uint32_t>(p[1]) << 8) |
                                (static_cast<std::uint32_t>(p[2]) << 16);
        return (v * 2654435761u) >> (32 - kHashBits);
    }
    void insert(const std::uint8_t* t, std::size_t n, std::size_t pos) {
        if (pos + kMinMatch > n) return;
        const unsigned h = hash(t + pos);
        prev_[pos] = head_[h];
        head_[h] = static_cast<std::int32_t>(pos);
    }
    static unsigned common_length(const std::uint8_t* a, const std::uint8_t* b, std::size_t max) {
        std::size_t l = 0;
        while (l + 8 <= max) {
            const std::uint64_t x = load64(a + l) ^ load64(b + l);
            if (x) return static_cast<unsigned>(l + (static_cast<unsigned>(std::countr_zero(x)) >> 3));
            l += 8;
        }
        while (l < max && a[l] == b[l]) ++l;
        return static_cast<unsigned>(l);
    }
    // The best match at `pos` among the earlier positions of the tile; inserts `pos` into the hash chains.
    Match search(const std::uint8_t* t, std::size_t n, std::size_t pos) {
        Match result;
        if (pos + kMinMatch > n) return result;
        const unsigned h = hash(t + pos);
        std::int32_t cand = head_[h];
        prev_[pos] = cand;
        head_[h] = static_cast<std::int32_t>(pos);
        const unsigned maxLen = static_cast<unsigned>(std::min<std::size_t>(n - pos, kMaxMatch));
        unsigned best = kMinMatch - 1, bestDist = 0;
        unsigned depth = params_.chain;
        while (cand >= 0 && depth-- > 0 && best < maxLen) {
            const std::size_t c = static_cast<std::size_t>(cand);
            if (t[c + best] == t[pos + best]) {
                const unsigned len = common_length(t + c, t + pos, maxLen);
                if (len > best) {
                    best = len;
                    bestDist = static_cast<unsigned>(pos - c);
                    if (len >= params_.nice) break;
                }
            }
            cand = prev_[c];
        }
        if (best >= kMinMatch && !(best == kMinMatch && bestDist > 4096)) {
            result.length = best;
            result.distance = bestDist;
        }
        return result;
    }

    void parse(const std::uint8_t* t, std::size_t n) {
        std::fill(head_.begin(), head_.end(), -1);
        tokens_.clear();
        std::size_t pos = 0;
        Match cur = search(t, n, 0);
        while (pos < n) {
            if (cur.length < kMinMatch) {
                tokens_.push_back({0, t[pos]});
                ++pos;
                cur = pos < n ? search(t, n, pos) : Match{};
                continue;
            }
            if (params_.lazy && cur.length < params_.nice && pos + 1 < n) {
                const Match next = search(t, n, pos + 1);
                if (next.length > cur.length) {
                    tokens_.push_back({0, t[pos]});
                    ++pos;
                    cur = next;
                    continue;
                }
                tokens_.push_back({cur.length, cur.distance});
                for (std::size_t p = pos + 2; p < pos + cur.length; ++p) insert(t, n, p);
            } else {
                tokens_.push_back({cur.length, cur.distance});
                for (std::size_t p = pos + 1; p < pos + cur.length; ++p) insert(t, n, p);
            }
            pos += cur.length;
            cur = pos < n ? search(t, n, pos) : Match{};
        }
    }

    // ---- Dynamic Huffman block ----

    struct Item {
        std::uint8_t symbol;
        std::uint8_t extra;
    };

    void write_dynamic(std::vector<std::uint8_t>& out) {
        std::array<std::uint32_t, kNumLitLen> litFreq{};
        std::array<std::uint32_t, kNumDist> distFreq{};
        for (const Token& t : tokens_) {
            if (t.length == 0) {
                ++litFreq[t.value];
            } else {
                ++litFreq[length_symbol(t.length)];
                ++distFreq[dist_slot(t.value)];
            }
        }
        litFreq[kEndOfBlock] = 1;
        std::array<std::uint8_t, kNumLitLen> litLens{};
        std::array<std::uint8_t, kNumDist> distLens{};
        huffman_lengths(litFreq.data(), kNumLitLen, 15, litLens.data());
        huffman_lengths(distFreq.data(), kNumDist, 15, distLens.data());
        std::array<std::uint16_t, kNumLitLen> litCodes{};
        std::array<std::uint16_t, kNumDist> distCodes{};
        canonical_codes(litLens.data(), kNumLitLen, litCodes.data());
        canonical_codes(distLens.data(), kNumDist, distCodes.data());

        unsigned hlit = kNumLitLen;
        while (hlit > 257 && litLens[hlit - 1] == 0) --hlit;
        unsigned hdist = kNumDist;
        while (hdist > 1 && distLens[hdist - 1] == 0) --hdist;

        // Run-length items of the code lengths (the two codes are one sequence, as in Deflate).
        std::array<std::uint8_t, kNumLitLen + kNumDist> all{};
        std::copy(litLens.begin(), litLens.begin() + hlit, all.begin());
        std::copy(distLens.begin(), distLens.begin() + hdist, all.begin() + hlit);
        const unsigned total = hlit + hdist;
        items_.clear();
        std::array<std::uint32_t, kNumPrecode> preFreq{};
        auto put = [&](unsigned symbol, unsigned extra) {
            items_.push_back({static_cast<std::uint8_t>(symbol), static_cast<std::uint8_t>(extra)});
            ++preFreq[symbol];
        };
        for (unsigned i = 0; i < total;) {
            const std::uint8_t v = all[i];
            unsigned run = 1;
            while (i + run < total && all[i + run] == v) ++run;
            if (v == 0) {
                while (run >= 3) {
                    const unsigned take = run >= 11 ? std::min(run, 138u) : run;
                    put(take >= 11 ? 18 : 17, take >= 11 ? take - 11 : take - 3);
                    i += take;
                    run -= take;
                }
            } else {
                put(v, 0);
                ++i;
                --run;
                while (run >= 3) {
                    const unsigned take = std::min(run, 6u);
                    put(16, take - 3);
                    i += take;
                    run -= take;
                }
            }
            for (; run > 0; --run, ++i) put(v, 0);
        }
        std::array<std::uint8_t, kNumPrecode> preLens{};
        std::array<std::uint16_t, kNumPrecode> preCodes{};
        huffman_lengths(preFreq.data(), kNumPrecode, 7, preLens.data());
        canonical_codes(preLens.data(), kNumPrecode, preCodes.data());
        unsigned explicitLens = kNumPrecode;
        while (explicitLens > 4 && preLens[kPrecodeOrder[explicitLens - 1]] == 0) --explicitLens;

        // Header: 3 bits, 14 bits, the precode lengths, the code lengths.
        writer_.start(out);
        writer_.add(1, 1);  // final
        writer_.add(2, 2);  // dynamic
        writer_.add(hlit - 257, 5);
        writer_.add(hdist - 1, 5);
        writer_.add(explicitLens - 4, 4);
        for (unsigned i = 0; i < explicitLens; ++i) {
            writer_.add(preLens[kPrecodeOrder[i]], 3);
            writer_.advance();
        }
        writer_.reset_lane();
        for (const Item& it : items_) {
            writer_.add(preCodes[it.symbol], preLens[it.symbol]);
            if (it.symbol == 16) writer_.add(it.extra, 2);
            else if (it.symbol == 17) writer_.add(it.extra, 3);
            else if (it.symbol == 18) writer_.add(it.extra, 7);
            writer_.advance();
        }
        writer_.reset_lane();
        write_symbols(litLens.data(), litCodes.data(), distLens.data(), distCodes.data());
        writer_.finish();
    }

    static unsigned length_symbol(unsigned length) { return length <= 258 ? 257 + kLenSlots.slot[length] : 285; }

    struct PendingCopy {
        std::uint32_t bits = 0;
        unsigned count = 0;
        unsigned round = 0;  // 0: none
    };

    // The literals and matches of the tile as the 32 lanes see them: a match's distance goes to the same lane one
    // round after its length.
    void write_symbols(const std::uint8_t* litLens, const std::uint16_t* litCodes, const std::uint8_t* distLens,
                       const std::uint16_t* distCodes) {
        std::array<PendingCopy, kLanes> copies{};
        unsigned round = 1;
        auto flush_previous_round = [&]() {
            while (round > 1 && copies[writer_.lane()].round == round - 1) {
                PendingCopy& c = copies[writer_.lane()];
                c.round = 0;
                writer_.add(c.bits, c.count);
                round += writer_.advance();
            }
        };
        for (const Token& t : tokens_) {
            flush_previous_round();
            if (t.length == 0) {
                writer_.add(litCodes[t.value], litLens[t.value]);
            } else {
                const unsigned sym = length_symbol(t.length);
                writer_.add(litCodes[sym], litLens[sym]);
                if (sym == 285) {
                    writer_.add(t.length - 3, 16);
                } else {
                    const unsigned slot = sym - 257;
                    writer_.add(t.length - kLenBase[slot], kLenExtra[slot]);
                }
                const unsigned ds = dist_slot(t.value);
                PendingCopy& c = copies[writer_.lane()];
                c.bits = distCodes[ds] | ((t.value - kDistBase[ds]) << distLens[ds]);
                c.count = distLens[ds] + kDistExtra[ds];
                c.round = round;
            }
            round += writer_.advance();
        }
        flush_previous_round();
        writer_.add(litCodes[kEndOfBlock], litLens[kEndOfBlock]);
        round += writer_.advance();
        // The last round: the pending distances, in the order the lanes come, starting after the end-of-block lane.
        const unsigned split = writer_.lane();
        for (unsigned n = split; n < kLanes; ++n)
            if (round > 1 && copies[n].round == round - 1) {
                writer_.set_lane(n);
                writer_.add(copies[n].bits, copies[n].count);
            }
        for (unsigned n = 0; n < split; ++n)
            if (copies[n].round == round) {
                writer_.set_lane(n);
                writer_.add(copies[n].bits, copies[n].count);
            }
    }

    // ---- Stored blocks (a tile that does not compress) ----

    void write_stored(const std::uint8_t* t, std::size_t n, std::vector<std::uint8_t>& out) {
        writer_.start(out);
        std::size_t pos = 0;
        do {
            const std::size_t chunk = std::min<std::size_t>(n - pos, 65535);
            writer_.reset_lane();
            writer_.add(pos + chunk == n ? 1 : 0, 1);
            writer_.add(0, 2);
            writer_.add(static_cast<std::uint32_t>(chunk), 16);
            for (std::size_t i = 0; i < chunk; ++i) {
                writer_.add(t[pos + i], 8);
                writer_.advance();
            }
            pos += chunk;
        } while (pos < n);
        writer_.finish();
    }

    LevelParams params_;
    std::vector<std::int32_t> head_;
    std::vector<std::int32_t> prev_;
    std::vector<Token> tokens_;
    std::vector<Item> items_;
    LaneWriter writer_;
    std::vector<std::uint8_t> dynamic_;
    std::vector<std::uint8_t> stored_;
};

// ---- Decoder --------------------------------------------------------------------------------------------------------

// Decode table entries: bits 0..4 the number of bits to consume, bits 5..9 the number of extra bits, bits 10..13 flags,
// bits 16..31 the value (a literal byte, a length or distance base, a precode symbol, or a subtable's offset).
constexpr std::uint32_t kSub = 1u << 10;   // a pointer to a subtable (bits 0..4: its index width)
constexpr std::uint32_t kLit = 1u << 11;   // a literal
constexpr std::uint32_t kEob = 1u << 12;   // end of block
constexpr std::uint32_t kBad = 1u << 13;   // a symbol that cannot occur (or a hole in an incomplete code)

enum class Kind { Precode, LitLen, Offset };

constexpr std::uint32_t make_entry(Kind kind, unsigned sym, unsigned len) {
    switch (kind) {
        case Kind::Precode: return (sym << 16) | len;
        case Kind::LitLen:
            if (sym < 256) return kLit | (sym << 16) | len;
            if (sym == kEndOfBlock) return kEob | len;
            if (sym <= 285)
                return (static_cast<std::uint32_t>(kLenBase[sym - 257]) << 16) |
                       (static_cast<std::uint32_t>(kLenExtra[sym - 257]) << 5) | len;
            return kBad | len;
        case Kind::Offset:
            if (sym < kNumDist) return (kDistBase[sym] << 16) | (static_cast<std::uint32_t>(kDistExtra[sym]) << 5) | len;
            return kBad | len;
    }
    return kBad;
}

// Builds a two-level decode table for the canonical code of `lens`. Returns an empty string, or what is wrong with the
// code. A code must be complete, except for a single symbol of length 1 and (with `allowEmpty`) no symbol at all.
std::string build_table(const std::uint8_t* lens, unsigned n, unsigned primary, Kind kind, bool allowEmpty,
                        std::vector<std::uint32_t>& table) {
    std::array<unsigned, 16> count{};
    for (unsigned s = 0; s < n; ++s) ++count[lens[s]];
    const unsigned used = n - count[0];
    count[0] = 0;
    int left = 1;
    for (unsigned l = 1; l <= 15; ++l) {
        left = (left << 1) - static_cast<int>(count[l]);
        if (left < 0) return "its code lengths oversubscribe the code";
    }
    table.assign(std::size_t(1) << primary, kBad);
    if (used == 0) return allowEmpty ? std::string() : std::string("it has no codes");
    if (left > 0 && !(used == 1 && count[1] == 1)) return "its code lengths leave the code incomplete";

    std::array<unsigned, 17> next{};
    unsigned code = 0;
    for (unsigned l = 1; l <= 15; ++l) {
        code = (code + count[l - 1]) << 1;
        next[l] = code;
    }
    std::array<std::uint16_t, kNumLitLen + kNumDist> reversed{};
    std::array<std::uint8_t, 1u << 10> subBits{};
    const unsigned mask = (1u << primary) - 1;
    for (unsigned s = 0; s < n; ++s) {
        const unsigned l = lens[s];
        if (!l) continue;
        reversed[s] = static_cast<std::uint16_t>(reverse_bits(next[l]++, l));
        if (l > primary) {
            std::uint8_t& sb = subBits[reversed[s] & mask];
            sb = std::max<std::uint8_t>(sb, static_cast<std::uint8_t>(l - primary));
        }
    }
    for (unsigned low = 0; low <= mask; ++low)
        if (subBits[low]) {
            table[low] = kSub | subBits[low] | (static_cast<std::uint32_t>(table.size()) << 16);
            table.resize(table.size() + (std::size_t(1) << subBits[low]), kBad);
        }
    for (unsigned s = 0; s < n; ++s) {
        const unsigned l = lens[s];
        if (!l) continue;
        const unsigned r = reversed[s];
        if (l <= primary) {
            const std::uint32_t e = make_entry(kind, s, l);
            for (unsigned i = r; i <= mask; i += 1u << l) table[i] = e;
        } else {
            const std::uint32_t sub = table[r & mask];
            const std::size_t base = sub >> 16;
            const unsigned width = sub & 31;
            const unsigned eLen = l - primary;
            const std::uint32_t e = make_entry(kind, s, eLen);
            for (unsigned i = r >> primary; i < (1u << width); i += 1u << eLen) table[base + i] = e;
        }
    }
    return {};
}

// One tile. All errors set `error_` (what is wrong) and `errorAt_` (byte of the tile near which it was found).
class TileDecoder {
public:
    // Decodes the tile in `in` into `out` (exactly out.size() bytes). `consumed` gets the bytes of `in` that were read.
    bool run(std::span<const std::uint8_t> in, std::span<std::uint8_t> out, std::size_t& consumed) {
        in_ = in.data();
        inSize_ = in.size();
        inPos_ = kPreambleBytes;
        out_ = out.data();
        outSize_ = out.size();
        outPos_ = 0;
        pending_ = 0;
        if (in.size() < kPreambleBytes)
            return fail("the tile holds " + std::to_string(in.size()) + " bytes, fewer than the 128 of its 32 lane words",
                        0);
        for (unsigned l = 0; l < kLanes; ++l) {
            buf_[l] = load32(in_ + 4 * l);
            cnt_[l] = 32;
        }
        for (;;) {
            const bool last = pop(0, 1) != 0;
            const unsigned type = pop(0, 2);
            if (!ensure(0)) return false;
            bool ok = false;
            switch (type) {
                case 0: ok = stored_block(); break;
                case 1: ok = static_block(); break;
                case 2: ok = dynamic_block(); break;
                default: return fail("a block has the reserved type 3", inPos_);
            }
            if (!ok) return false;
            if (last) break;
        }
        if (outPos_ != outSize_)
            return fail("the tile decodes to " + std::to_string(outPos_) + " bytes, expected " + std::to_string(outSize_),
                        inPos_);
        consumed = inPos_;
        return true;
    }

    const std::string& error() const { return error_; }
    std::size_t error_at() const { return errorAt_; }

private:
    bool fail(std::string what, std::size_t at) {
        error_ = std::move(what);
        errorAt_ = at;
        return false;
    }
    std::uint32_t pop(unsigned lane, unsigned n) {
        const std::uint32_t v = static_cast<std::uint32_t>(buf_[lane]) & ((1u << n) - 1u);
        buf_[lane] >>= n;
        cnt_[lane] -= n;
        return v;
    }
    // Reloads a lane that has fewer than 32 bits: the lanes take the stream's words in the order they ask.
    bool ensure(unsigned lane) {
        if (cnt_[lane] >= 32) return true;
        if (inPos_ + 4 > inSize_)
            return fail("the tile ends before the lane words its blocks ask for (needs bytes " +
                            std::to_string(inPos_) + ".." + std::to_string(inPos_ + 4) + " of " +
                            std::to_string(inSize_) + ")",
                        inPos_);
        buf_[lane] |= static_cast<std::uint64_t>(load32(in_ + inPos_)) << cnt_[lane];
        inPos_ += 4;
        cnt_[lane] += 32;
        return true;
    }
    std::uint32_t lookup(const std::vector<std::uint32_t>& table, unsigned primary, unsigned lane) {
        std::uint32_t e = table[static_cast<std::uint32_t>(buf_[lane]) & ((1u << primary) - 1u)];
        if (e & kSub) {
            buf_[lane] >>= primary;
            cnt_[lane] -= primary;
            e = table[(e >> 16) + (static_cast<std::uint32_t>(buf_[lane]) & ((1u << (e & 31u)) - 1u))];
        }
        const unsigned l = e & 31u;
        buf_[lane] >>= l;
        cnt_[lane] -= l;
        return e;
    }

    bool stored_block() {
        const std::size_t len = pop(0, 16);
        if (len > outSize_ - outPos_)
            return fail("a stored block of " + std::to_string(len) + " bytes does not fit in the " +
                            std::to_string(outSize_) + "-byte tile",
                        inPos_);
        unsigned lane = 0;
        for (std::size_t i = 0; i < len; ++i) {
            out_[outPos_++] = static_cast<std::uint8_t>(pop(lane, 8));
            if (!ensure(lane)) return false;
            lane = (lane + 1) & (kLanes - 1);
        }
        return true;
    }

    bool static_block() {
        std::array<std::uint8_t, kNumLitLen + kNumDist> lens{};
        for (unsigned i = 0; i < 144; ++i) lens[i] = 8;
        for (unsigned i = 144; i < 256; ++i) lens[i] = 9;
        for (unsigned i = 256; i < 280; ++i) lens[i] = 7;
        for (unsigned i = 280; i < 288; ++i) lens[i] = 8;
        for (unsigned i = 288; i < 320; ++i) lens[i] = 5;
        return symbols(lens.data(), kNumLitLen, lens.data() + kNumLitLen, kNumDist);
    }

    bool dynamic_block() {
        const unsigned hlit = pop(0, 5) + 257;
        const unsigned hdist = pop(0, 5) + 1;
        const unsigned hclen = pop(0, 4) + 4;
        if (!ensure(0)) return false;
        std::array<std::uint8_t, kNumPrecode> preLens{};
        for (unsigned i = 0; i < hclen; ++i) {
            preLens[kPrecodeOrder[i]] = static_cast<std::uint8_t>(pop(i & (kLanes - 1), 3));
            if (!ensure(i & (kLanes - 1))) return false;
        }
        if (auto e = build_table(preLens.data(), kNumPrecode, 7, Kind::Precode, false, preTable_); !e.empty())
            return fail("the code that packs the code lengths is damaged: " + e, inPos_);
        std::array<std::uint8_t, kNumLitLen + kNumDist + 140> lens{};
        const unsigned total = hlit + hdist;
        unsigned lane = 0;
        for (unsigned i = 0; i < total;) {
            const std::uint32_t e = lookup(preTable_, 7, lane);
            if (e & kBad) return fail("a code length has an invalid code", inPos_);
            const unsigned sym = e >> 16;
            if (sym < 16) {
                lens[i++] = static_cast<std::uint8_t>(sym);
            } else {
                unsigned rep = 0;
                std::uint8_t value = 0;
                if (sym == 16) {
                    if (i == 0) return fail("a code length repeats the previous one at the very start", inPos_);
                    value = lens[i - 1];
                    rep = 3 + pop(lane, 2);
                } else if (sym == 17) {
                    rep = 3 + pop(lane, 3);
                } else {
                    rep = 11 + pop(lane, 7);
                }
                if (i + rep > total) return fail("the code lengths run past the " + std::to_string(total) + " announced", inPos_);
                for (unsigned k = 0; k < rep; ++k) lens[i++] = value;
            }
            if (!ensure(lane)) return false;
            lane = (lane + 1) & (kLanes - 1);
        }
        if (lens[kEndOfBlock] == 0) return fail("the literal/length code has no end-of-block symbol", inPos_);
        return symbols(lens.data(), hlit, lens.data() + hlit, hdist);
    }

    bool symbols(const std::uint8_t* litLens, unsigned hlit, const std::uint8_t* distLens, unsigned hdist) {
        if (auto e = build_table(litLens, hlit, 10, Kind::LitLen, false, litTable_); !e.empty())
            return fail("the literal/length code is damaged: " + e, inPos_);
        if (auto e = build_table(distLens, hdist, 8, Kind::Offset, true, distTable_); !e.empty())
            return fail("the distance code is damaged: " + e, inPos_);
        unsigned lane = 0;
        for (;;) {
            if ((pending_ >> lane) & 1u) {
                if (!finish_copy(lane)) return false;
            } else {
                const std::uint32_t e = lookup(litTable_, 10, lane);
                if (e & kLit) {
                    if (outPos_ == outSize_) return fail("the block decodes to more than the " + std::to_string(outSize_) + "-byte tile", inPos_);
                    out_[outPos_++] = static_cast<std::uint8_t>(e >> 16);
                } else if (e & kEob) {
                    break;
                } else if (e & kBad) {
                    return fail("a literal/length symbol has an invalid code", inPos_);
                } else {
                    const std::size_t len = (e >> 16) + pop(lane, (e >> 5) & 31u);
                    if (len > outSize_ - outPos_)
                        return fail("a match of " + std::to_string(len) + " bytes runs past the end of the " +
                                        std::to_string(outSize_) + "-byte tile",
                                    inPos_);
                    pendLen_[lane] = static_cast<std::uint32_t>(len);
                    pendPos_[lane] = static_cast<std::uint32_t>(outPos_);
                    pending_ |= 1u << lane;
                    outPos_ += len;
                }
            }
            if (!ensure(lane)) return false;
            lane = (lane + 1) & (kLanes - 1);
        }
        // The end-of-block lane and the 31 after it: the distances still pending.
        for (unsigned n = 0; n < kLanes; ++n) {
            if (((pending_ >> lane) & 1u) && !finish_copy(lane)) return false;
            if (!ensure(lane)) return false;
            lane = (lane + 1) & (kLanes - 1);
        }
        return true;
    }

    // The distance of the match this lane started one round ago, and the copy.
    bool finish_copy(unsigned lane) {
        pending_ &= ~(1u << lane);
        const std::uint32_t e = lookup(distTable_, 8, lane);
        if (e & kBad) return fail("a match distance has an invalid code", inPos_);
        const std::size_t distance = (e >> 16) + pop(lane, (e >> 5) & 31u);
        const std::size_t at = pendPos_[lane];
        const std::size_t len = pendLen_[lane];
        if (distance > at)
            return fail("a match reaches " + std::to_string(distance) + " bytes back, " + std::to_string(at) +
                            " bytes into the tile",
                        inPos_);
        std::uint8_t* dst = out_ + at;
        const std::uint8_t* src = dst - distance;
        if (distance == 1) {
            std::memset(dst, *src, len);
        } else if (distance >= len) {
            std::memcpy(dst, src, len);
        } else {
            // Overlapping: chunks no longer than the distance to the source, which grows as the copy goes.
            std::size_t remaining = len;
            while (remaining) {
                const std::size_t chunk = std::min<std::size_t>(remaining, static_cast<std::size_t>(dst - src));
                std::memcpy(dst, src, chunk);
                dst += chunk;
                remaining -= chunk;
            }
        }
        return true;
    }

    const std::uint8_t* in_ = nullptr;
    std::size_t inSize_ = 0, inPos_ = 0;
    std::uint8_t* out_ = nullptr;
    std::size_t outSize_ = 0, outPos_ = 0;
    std::array<std::uint64_t, kLanes> buf_{};
    std::array<unsigned, kLanes> cnt_{};
    std::array<std::uint32_t, kLanes> pendLen_{};
    std::array<std::uint32_t, kLanes> pendPos_{};
    std::uint32_t pending_ = 0;
    std::vector<std::uint32_t> litTable_, distTable_, preTable_;
    std::string error_;
    std::size_t errorAt_ = 0;
};

}  // namespace

// ---- Public (compress_internal.h) -----------------------------------------------------------------------------------

std::size_t gdeflate_compress_bound(std::size_t size) {
    const std::uint64_t tiles = (static_cast<std::uint64_t>(size) + kTileSize - 1) / kTileSize;
    // Every tile is at most its bytes plus its 32 lane words and a few bits of block headers (a stored tile).
    return sat_size(kHeaderBytes + tiles * 4 + static_cast<std::uint64_t>(size) + tiles * 256);
}

void gdeflate_compress(std::span<const std::uint8_t> input, int level, std::vector<std::uint8_t>& out) {
    const std::size_t n = input.size();
    const std::size_t tiles = (n + kTileSize - 1) / kTileSize;
    // The caller (compress) refuses inputs over 1 GiB, far under the 65535 tiles of a stream.
    const std::size_t lastSize = n - (tiles ? (tiles - 1) * kTileSize : 0);
    const std::size_t headerStart = out.size();
    out.resize(headerStart + kHeaderBytes + tiles * 4, 0);
    TileEncoder encoder(level);
    std::vector<std::uint32_t> offsets(tiles, 0);
    const std::size_t dataStart = out.size();
    std::uint32_t lastTileBytes = 0;
    for (std::size_t t = 0; t < tiles; ++t) {
        const std::size_t begin = t * kTileSize;
        const std::size_t len = std::min<std::size_t>(kTileSize, n - begin);
        offsets[t] = static_cast<std::uint32_t>(out.size() - dataStart);
        const std::size_t before = out.size();
        encoder.encode(input.data() + begin, len, out);
        if (t + 1 == tiles) lastTileBytes = static_cast<std::uint32_t>(out.size() - before);
    }
    std::uint8_t* h = out.data() + headerStart;
    h[0] = kStreamId;
    h[1] = kStreamMagic;
    store16(h + 2, static_cast<std::uint32_t>(tiles));
    store32(h + 4, 1u | ((lastSize == kTileSize ? 0u : static_cast<std::uint32_t>(lastSize)) << 2));
    if (tiles == 0) store32(h + 4, 1u);
    for (std::size_t t = 0; t < tiles; ++t) store32(h + kHeaderBytes + 4 * t, t == 0 ? lastTileBytes : offsets[t]);
}

Result<std::size_t> gdeflate_decode_tile(std::span<const std::uint8_t> tile, std::span<std::uint8_t> out) {
    TileDecoder decoder;
    std::size_t consumed = 0;
    if (!decoder.run(tile, out, consumed)) return block_error("gdeflate", decoder.error(), static_cast<std::ptrdiff_t>(decoder.error_at()));
    return consumed;
}

Result<void> gdeflate_decompress(std::span<const std::uint8_t> block, std::span<std::uint8_t> out) {
    if (block.size() < kHeaderBytes)
        return block_error("gdeflate", "the block holds " + std::to_string(block.size()) + " bytes, fewer than the 8 of the stream header", 0);
    const std::uint8_t* b = block.data();
    if (b[0] != kStreamId || b[1] != kStreamMagic)
        return block_error("gdeflate",
                           "the header is not a GDeflate stream (id " + std::to_string(b[0]) + ", magic " + std::to_string(b[1]) +
                               "; expected 4 and 251)",
                           0);
    const std::size_t tiles = load16(b + 2);
    const std::uint32_t word = load32(b + 4);
    if ((word & 3u) != 1u)
        return block_error("gdeflate", "the tile size index is " + std::to_string(word & 3u) + ", only 1 (64 KiB tiles) exists", 4);
    const std::size_t lastField = (word >> 2) & 0x3FFFFu;
    if (lastField >= kTileSize || (word >> 20) != 0)
        return block_error("gdeflate", "the last tile size or the reserved bits of the header are invalid", 4);
    if (tiles == 0 && lastField != 0) return block_error("gdeflate", "the stream has no tiles but a last tile size", 4);
    const std::uint64_t total =
        tiles == 0 ? 0 : static_cast<std::uint64_t>(tiles - 1) * kTileSize + (lastField == 0 ? kTileSize : lastField);
    if (total != out.size())
        return block_error("gdeflate",
                           "the stream holds " + std::to_string(total) + " bytes but " + std::to_string(out.size()) + " were expected", 2);
    const std::uint64_t dataStart = kHeaderBytes + static_cast<std::uint64_t>(tiles) * 4;
    if (dataStart > block.size()) return block_error("gdeflate", "the tile table is cut short", static_cast<std::ptrdiff_t>(block.size()));
    const std::uint8_t* table = b + kHeaderBytes;
    const std::uint8_t* data = b + dataStart;
    const std::uint64_t dataSize = block.size() - dataStart;
    TileDecoder decoder;
    for (std::size_t t = 0; t < tiles; ++t) {
        const std::uint64_t begin = t == 0 ? 0 : load32(table + 4 * t);
        const std::uint64_t end = t + 1 < tiles ? load32(table + 4 * (t + 1)) : begin + load32(table);
        const std::ptrdiff_t at = static_cast<std::ptrdiff_t>(dataStart + begin);
        if (begin > end || end > dataSize)
            return block_error("gdeflate",
                               "tile " + std::to_string(t) + " is bytes " + std::to_string(begin) + ".." + std::to_string(end) +
                                   " of the tile data, which holds " + std::to_string(dataSize),
                               at);
        const std::size_t outBegin = t * kTileSize;
        const std::size_t outLen = std::min<std::size_t>(kTileSize, out.size() - outBegin);
        std::size_t consumed = 0;
        if (!decoder.run(std::span<const std::uint8_t>(data + begin, static_cast<std::size_t>(end - begin)),
                         out.subspan(outBegin, outLen), consumed))
            return block_error("gdeflate", "tile " + std::to_string(t) + ": " + decoder.error(),
                               at + static_cast<std::ptrdiff_t>(decoder.error_at()));
    }
    return {};
}

}  // namespace fa::codec
