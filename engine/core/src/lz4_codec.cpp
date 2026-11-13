// The LZ4 block format (https://github.com/lz4/lz4/blob/dev/doc/lz4_Block_format.md), written for the engine.
//
// A block is a run of sequences: a token (literal length in the high nibble, match length - 4 in the low one; 15 means
// "more length bytes follow, each added, until one is below 255"), the literals, a 2-byte little-endian offset and the
// extra match length bytes. The last sequence has literals only. A valid block ends with at least 5 literal bytes and
// its last match starts at least 12 bytes before the end.
//
// Encoder levels: 1 greedy with a hash table and a growing skip over incompressible data, 2 the same without the skip,
// 3..12 hash chains with lazy matching (one position ahead up to level 5, two from level 6) and a search depth that
// doubles about every level.
#include <algorithm>
#include <array>

#include "compress_internal.h"

namespace fa::codec {

Error block_error(const char* codec, const std::string& what, std::ptrdiff_t offset) {
    return Error{std::string(codec) + " block is damaged: " + what + " (at byte " + std::to_string(offset) + ")",
                 "the data is cut short or changed after it was written: export the game again"};
}

// ---- Decoder ------------------------------------------------------------------------------------------------------

Result<void> lz4_decompress(std::span<const std::uint8_t> block, std::span<std::uint8_t> out) {
    const std::uint8_t* ip = block.data();
    const std::uint8_t* const iend = ip + block.size();
    std::uint8_t* op = out.data();
    std::uint8_t* const ostart = op;
    std::uint8_t* const oend = op + out.size();
    if (block.empty()) return block_error("lz4", "the block is empty", 0);
    for (;;) {
        if (ip >= iend)
            return block_error("lz4", "the block ends after a match, without a last token", ip - block.data());
        const std::uint32_t token = *ip++;
        // Literal length.
        std::uint64_t litLen = token >> 4;
        if (litLen == 15) {
            for (;;) {
                if (ip >= iend) return block_error("lz4", "the literal length runs past the end", ip - block.data());
                const std::uint32_t b = *ip++;
                litLen += b;
                if (b != 255) break;
            }
        }
        if (litLen > static_cast<std::uint64_t>(iend - ip))
            return block_error("lz4", "the literals run past the end of the block", ip - block.data());
        if (litLen > static_cast<std::uint64_t>(oend - op))
            return block_error("lz4", "the data is longer than the " + std::to_string(out.size()) + " bytes expected",
                               ip - block.data());
        if (litLen) std::memcpy(op, ip, static_cast<std::size_t>(litLen));
        ip += litLen;
        op += litLen;
        if (ip == iend) break;  // the last sequence has literals only
        // Match.
        if (iend - ip < 2) return block_error("lz4", "the match offset is cut short", ip - block.data());
        const std::size_t offset = load16(ip);
        ip += 2;
        if (offset == 0) return block_error("lz4", "a match has offset 0", ip - block.data() - 2);
        if (offset > static_cast<std::size_t>(op - ostart))
            return block_error("lz4", "a match reaches before the start of the data", ip - block.data() - 2);
        std::uint64_t matchLen = token & 15;
        if (matchLen == 15) {
            for (;;) {
                if (ip >= iend) return block_error("lz4", "the match length runs past the end", ip - block.data());
                const std::uint32_t b = *ip++;
                matchLen += b;
                if (b != 255) break;
            }
        }
        matchLen += 4;
        if (matchLen > static_cast<std::uint64_t>(oend - op))
            return block_error("lz4", "the data is longer than the " + std::to_string(out.size()) + " bytes expected",
                               ip - block.data());
        std::size_t remaining = static_cast<std::size_t>(matchLen);
        const std::uint8_t* src = op - offset;
        if (offset == 1) {
            std::memset(op, *src, remaining);
            op += remaining;
        } else {
            // Copy in chunks no longer than the distance to the source: each chunk is a plain non-overlapping copy
            // and the distance grows, so an overlapping match (a repeating pattern) takes few memcpy calls.
            while (remaining) {
                const std::size_t chunk = std::min<std::size_t>(remaining, static_cast<std::size_t>(op - src));
                std::memcpy(op, src, chunk);
                op += chunk;
                remaining -= chunk;
            }
        }
    }
    if (op != oend)
        return block_error("lz4",
                           "the block holds " + std::to_string(op - ostart) + " bytes but " +
                               std::to_string(out.size()) + " were expected",
                           static_cast<std::ptrdiff_t>(block.size()));
    return {};
}

// ---- Encoder ------------------------------------------------------------------------------------------------------

std::size_t lz4_compress_bound(std::size_t size) {
    return sat_size(static_cast<std::uint64_t>(size) + size / 255 + 16);
}

namespace {

constexpr std::size_t kMinMatch = 4;
constexpr std::size_t kLastLiterals = 5;  // the last 5 bytes of a block are literals
constexpr std::size_t kMfLimit = 12;      // the last match starts at least 12 bytes before the end
constexpr std::size_t kMaxOffset = 65535;

inline std::uint32_t hash4(std::uint32_t v, unsigned bits) { return (v * 2654435761u) >> (32 - bits); }

// Number of equal bytes of a[0..) and b[0..), a < limit, never reading at or past `limit` (a is the one that moves).
inline std::size_t count_equal(const std::uint8_t* a, const std::uint8_t* b, const std::uint8_t* limit) {
    const std::uint8_t* const start = a;
    while (limit - a >= 8) {
        const std::uint64_t diff = load64(a) ^ load64(b);
        if (diff) {
            // The first differing byte in memory order: lowest set bit on little-endian loads (load64 is LE).
            return static_cast<std::size_t>(a - start) + static_cast<std::size_t>(std::countr_zero(diff) >> 3);
        }
        a += 8;
        b += 8;
    }
    while (a < limit && *a == *b) {
        ++a;
        ++b;
    }
    return static_cast<std::size_t>(a - start);
}

class Writer {
public:
    explicit Writer(std::vector<std::uint8_t>& out) : out_(out) {}

    void sequence(const std::uint8_t* lit, std::size_t litLen, std::size_t offset, std::size_t matchLen) {
        const std::size_t ml = matchLen - kMinMatch;
        const std::size_t base = out_.size();
        out_.resize(base + 1 + (litLen / 255 + 1) + litLen + 2 + (ml / 255 + 1));
        std::uint8_t* p = out_.data() + base;
        std::uint8_t* const token = p++;
        *token = static_cast<std::uint8_t>((std::min<std::size_t>(litLen, 15) << 4) | std::min<std::size_t>(ml, 15));
        if (litLen >= 15) p = extra(p, litLen - 15);
        if (litLen) std::memcpy(p, lit, litLen);
        p += litLen;
        store16(p, static_cast<std::uint32_t>(offset));
        p += 2;
        if (ml >= 15) p = extra(p, ml - 15);
        out_.resize(static_cast<std::size_t>(p - out_.data()));
    }

    void last_literals(const std::uint8_t* lit, std::size_t litLen) {
        const std::size_t base = out_.size();
        out_.resize(base + 1 + (litLen / 255 + 1) + litLen);
        std::uint8_t* p = out_.data() + base;
        *p++ = static_cast<std::uint8_t>(std::min<std::size_t>(litLen, 15) << 4);
        if (litLen >= 15) p = extra(p, litLen - 15);
        if (litLen) std::memcpy(p, lit, litLen);
        p += litLen;
        out_.resize(static_cast<std::size_t>(p - out_.data()));
    }

private:
    static std::uint8_t* extra(std::uint8_t* p, std::size_t len) {
        while (len >= 255) {
            *p++ = 255;
            len -= 255;
        }
        *p++ = static_cast<std::uint8_t>(len);
        return p;
    }
    std::vector<std::uint8_t>& out_;
};

// Levels 1 and 2: a hash table of the last position of every 4-byte hash, greedy matches. Positions are indices
// (a pointer advanced by `step` could point past the end of the input, which is undefined even if never read).
void compress_fast(const std::uint8_t* src, std::size_t n, bool skip, Writer& w) {
    std::size_t anchor = 0;
    if (n >= kMfLimit + 1) {
        constexpr unsigned kBits = 16;
        std::vector<std::uint32_t> table(std::size_t{1} << kBits, 0);
        const std::size_t mfLimit = n - kMfLimit;          // last position a match may start at
        const std::size_t matchLimit = n - kLastLiterals;  // a match ends at or before this
        std::size_t ip = 0;
        table[hash4(load32(src), kBits)] = 0;
        ++ip;
        for (;;) {
            // Search for a match; a long run of misses speeds up (level 1) so incompressible data stays fast.
            std::size_t ref;
            std::uint32_t searchNb = 1u << 6;
            std::size_t step = 1;
            for (;;) {
                const std::uint32_t seq = load32(src + ip);
                const std::uint32_t h = hash4(seq, kBits);
                ref = table[h];
                table[h] = static_cast<std::uint32_t>(ip);
                if (ref < ip && ip - ref <= kMaxOffset && load32(src + ref) == seq) break;
                ip += step;
                if (skip) step = searchNb++ >> 6;
                if (ip > mfLimit) goto finish;
            }
            // Extend backwards over the literals pending, then forwards.
            while (ip > anchor && ref > 0 && src[ip - 1] == src[ref - 1]) {
                --ip;
                --ref;
            }
            const std::size_t matchLen =
                kMinMatch + count_equal(src + ip + kMinMatch, src + ref + kMinMatch, src + matchLimit);
            w.sequence(src + anchor, ip - anchor, ip - ref, matchLen);
            ip += matchLen;
            anchor = ip;
            if (ip > mfLimit) break;
            table[hash4(load32(src + ip - 2), kBits)] = static_cast<std::uint32_t>(ip - 2);
        }
    }
finish:
    w.last_literals(src + anchor, n - anchor);
}

struct HcParams {
    unsigned attempts;  // chain entries examined per position
    unsigned lazy;      // 0 greedy, 1 look one position ahead, 2 two positions
    unsigned nice;      // a match this long is taken at once
};

constexpr std::array<HcParams, 10> kHc = {{
    {16, 1, 32},      // 3
    {32, 1, 48},      // 4
    {64, 1, 64},      // 5
    {128, 2, 96},     // 6
    {256, 2, 128},    // 7
    {512, 2, 192},    // 8
    {1024, 2, 256},   // 9
    {2048, 2, 384},   // 10
    {4096, 2, 512},   // 11
    {8192, 2, 1024},  // 12
}};

// Levels 3..12: hash chains (every position is linked to the previous one with the same 4-byte hash).
class HashChain {
public:
    HashChain(const std::uint8_t* src, std::size_t n, const HcParams& p)
        : src_(src), n_(n), p_(p), head_(std::size_t{1} << kBits, 0), chain_(65536, 0xFFFF) {}

    // Adds every position below `upto` (the last 3 bytes cannot hold a 4-byte sequence).
    void insert_to(std::size_t upto) {
        const std::size_t last = n_ >= kMinMatch ? n_ - kMinMatch + 1 : 0;
        if (upto > last) upto = last;
        while (next_ < upto) {
            const std::uint32_t h = hash4(load32(src_ + next_), kBits);
            const std::uint32_t prev = head_[h];  // position + 1, 0 = none
            std::size_t delta = prev ? next_ - (prev - 1) : 0xFFFF;
            if (delta > 0xFFFF) delta = 0xFFFF;
            chain_[next_ & 0xFFFF] = static_cast<std::uint16_t>(delta);
            head_[h] = static_cast<std::uint32_t>(next_ + 1);
            ++next_;
        }
    }

    // The longest match for position `pos` that beats `best`; returns its length (0 = none) and offset.
    std::size_t find(std::size_t pos, std::size_t best, std::size_t& offset) {
        insert_to(pos + 1);
        const std::uint8_t* const ip = src_ + pos;
        const std::uint8_t* const matchLimit = src_ + n_ - kLastLiterals;
        const std::uint32_t seq = load32(ip);
        std::uint32_t cand = head_[hash4(seq, kBits)];
        std::size_t found = 0;
        unsigned attempts = p_.attempts;
        while (cand && attempts--) {
            const std::size_t cpos = cand - 1;
            if (cpos < pos) {  // (the position itself heads the chain: step over it)
                if (pos - cpos > kMaxOffset) break;
                const std::uint8_t* ref = src_ + cpos;
                // A longer match than the best so far must agree at the byte past the best length too.
                if (best != 0 && ip + best >= matchLimit) break;
                if ((best == 0 || ref[best] == ip[best]) && load32(ref) == seq) {
                    const std::size_t len = kMinMatch + count_equal(ip + kMinMatch, ref + kMinMatch, matchLimit);
                    if (len > best) {
                        best = len;
                        found = len;
                        offset = pos - cpos;
                        if (len >= p_.nice || ip + len >= matchLimit) break;
                    }
                }
            }
            const std::size_t delta = chain_[cpos & 0xFFFF];
            if (delta == 0xFFFF || delta > cpos) break;
            cand = static_cast<std::uint32_t>(cpos - delta + 1);
        }
        return found;
    }

private:
    static constexpr unsigned kBits = 15;
    const std::uint8_t* src_;
    std::size_t n_;
    HcParams p_;
    std::size_t next_ = 0;
    std::vector<std::uint32_t> head_;
    std::vector<std::uint16_t> chain_;
};

void compress_hc(const std::uint8_t* src, std::size_t n, int level, Writer& w) {
    const std::uint8_t* const iend = src + n;
    std::size_t anchor = 0;
    if (n >= kMfLimit + 1) {
        HashChain hc(src, n, kHc[static_cast<std::size_t>(level - 3)]);
        const unsigned lazy = kHc[static_cast<std::size_t>(level - 3)].lazy;
        const std::size_t mfLimit = n - kMfLimit;  // last position a match may start at
        std::size_t ip = 0;
        while (ip <= mfLimit) {
            std::size_t offset = 0;
            std::size_t len = hc.find(ip, 0, offset);
            if (len == 0) {
                ++ip;
                continue;
            }
            // Lazy matching: a match one or two positions later that is longer wins, the bytes in between are literals.
            for (unsigned step = 0; step < lazy && len < kHc[static_cast<std::size_t>(level - 3)].nice; ++step) {
                if (ip + 1 > mfLimit) break;
                std::size_t off2 = 0;
                const std::size_t len2 = hc.find(ip + 1, len, off2);
                if (len2 <= len) break;
                ++ip;
                len = len2;
                offset = off2;
            }
            std::size_t start = ip;
            std::size_t ref = start - offset;
            while (start > anchor && ref > 0 && src[start - 1] == src[ref - 1]) {
                --start;
                --ref;
                ++len;
            }
            w.sequence(src + anchor, start - anchor, offset, len);
            ip = start + len;
            anchor = ip;
        }
    }
    w.last_literals(src + anchor, static_cast<std::size_t>(iend - (src + anchor)));
}

}  // namespace

void lz4_compress(std::span<const std::uint8_t> input, int level, std::vector<std::uint8_t>& out) {
    level = std::clamp(level, 1, 12);
    out.reserve(out.size() + lz4_compress_bound(input.size()));
    Writer w(out);
    if (level <= 2)
        compress_fast(input.data(), input.size(), level == 1, w);
    else
        compress_hc(input.data(), input.size(), level, w);
}

}  // namespace fa::codec
