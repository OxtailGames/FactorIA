// Zstandard encoder (RFC 8878), written for the engine. It writes standard frames that record their content size, cut
// into blocks of 128 KiB, each block raw, RLE or compressed (Huffman-coded literals, FSE-coded sequences); the choice
// is always the smallest. Levels 1..19 select the match finder:
//   1-2    one hash table, greedy, skipping ahead over data that does not match
//   3-19   hash chains with repeat-offset candidates and lazy matching; the search depth grows with the level
// Every decision uses integers (the same input and level give the same bytes on any platform).
#include <algorithm>
#include <array>
#include <bit>
#include <cstddef>
#include <cstdint>
#include <span>
#include <vector>

#include "compress_internal.h"
#include "zstd_common.h"

namespace fa::codec {

using namespace zstd;

std::size_t zstd_compress_bound(std::size_t size) {
    return sat_size(static_cast<std::uint64_t>(size) + (static_cast<std::uint64_t>(size) >> 8) + 64);
}

namespace {

// ---- Bit writer -----------------------------------------------------------------------------------------------------

// Fills bytes from the least significant bit up.
class BitWriter {
public:
    explicit BitWriter(std::vector<std::uint8_t>& out) : out_(out) {}
    void add(std::uint64_t value, unsigned bits) {  // bits <= 32
        acc_ |= (value & ((1ull << bits) - 1)) << n_;
        n_ += bits;
        while (n_ >= 8) {
            out_.push_back(static_cast<std::uint8_t>(acc_));
            acc_ >>= 8;
            n_ -= 8;
        }
    }
    // Ends a backward stream: a 1 bit marks where the data stops, then zero padding to a whole byte.
    void close_with_mark() {
        add(1, 1);
        finish();
    }
    void finish() {
        if (n_ > 0) out_.push_back(static_cast<std::uint8_t>(acc_));
        acc_ = 0;
        n_ = 0;
    }

private:
    std::vector<std::uint8_t>& out_;
    std::uint64_t acc_ = 0;
    unsigned n_ = 0;
};

// floor(256 * log2(x)) for 1 <= x < 2^16, integers only.
std::uint32_t ilog2_q8(std::uint32_t x) {
    const unsigned hb = highbit32(x);
    std::uint64_t m = hb >= 15 ? (x >> (hb - 15)) : (static_cast<std::uint64_t>(x) << (15 - hb));
    std::uint32_t r = hb << 8;
    for (unsigned i = 0; i < 8; ++i) {
        m = (m * m) >> 15;
        if (m >= (1u << 16)) {
            r |= 128u >> i;
            m >>= 1;
        }
    }
    return r;
}

// ---- FSE encoding ---------------------------------------------------------------------------------------------------

struct FseSymbolTT {
    std::int32_t deltaFindState;
    std::uint32_t deltaNbBits;
};

struct FseCTable {
    unsigned log = 0;
    bool rle = false;  // one symbol, no bits
    std::vector<std::uint16_t> stateTable;
    std::array<FseSymbolTT, 64> tt{};
};

void fse_build_ctable(FseCTable& t, const std::int16_t* norm, unsigned symbols, unsigned log) {
    const unsigned size = 1u << log;
    t.log = log;
    t.rle = false;
    t.stateTable.assign(size, 0);
    std::array<std::uint32_t, 65> cumul{};
    for (unsigned s = 0; s < symbols; ++s) cumul[s + 1] = cumul[s] + (norm[s] == -1 ? 1u : static_cast<std::uint32_t>(norm[s]));
    std::vector<std::uint8_t> tableSymbol(size);
    unsigned high = size - 1;
    for (unsigned s = 0; s < symbols; ++s)
        if (norm[s] == -1) tableSymbol[high--] = static_cast<std::uint8_t>(s);
    const unsigned step = (size >> 1) + (size >> 3) + 3;
    const unsigned mask = size - 1;
    unsigned pos = 0;
    for (unsigned s = 0; s < symbols; ++s)
        for (int i = 0; i < norm[s]; ++i) {
            tableSymbol[pos] = static_cast<std::uint8_t>(s);
            do pos = (pos + step) & mask;
            while (pos > high);
        }
    for (unsigned u = 0; u < size; ++u) t.stateTable[cumul[tableSymbol[u]]++] = static_cast<std::uint16_t>(size + u);
    std::int32_t total = 0;
    for (unsigned s = 0; s < symbols; ++s) {
        if (norm[s] == 0) {
            t.tt[s].deltaNbBits = ((log + 1) << 16) - size;
            t.tt[s].deltaFindState = 0;
        } else if (norm[s] == -1 || norm[s] == 1) {
            t.tt[s].deltaNbBits = (log << 16) - size;
            t.tt[s].deltaFindState = total - 1;
            ++total;
        } else {
            const unsigned maxBitsOut = log - highbit32(static_cast<std::uint32_t>(norm[s] - 1));
            const std::uint32_t minStatePlus = static_cast<std::uint32_t>(norm[s]) << maxBitsOut;
            t.tt[s].deltaNbBits = (maxBitsOut << 16) - minStatePlus;
            t.tt[s].deltaFindState = total - norm[s];
            total += norm[s];
        }
    }
}

struct FseState {
    std::uint32_t value = 0;
};

void fse_init_state(const FseCTable& t, FseState& st, unsigned symbol) {
    if (t.rle) return;
    const FseSymbolTT& tt = t.tt[symbol];
    const std::uint32_t nbBitsOut = (tt.deltaNbBits + (1u << 15)) >> 16;
    const std::uint32_t v = (nbBitsOut << 16) - tt.deltaNbBits;
    st.value = t.stateTable[static_cast<std::size_t>(static_cast<std::int32_t>(v >> nbBitsOut) + tt.deltaFindState)];
}

void fse_encode(const FseCTable& t, FseState& st, unsigned symbol, BitWriter& bw) {
    if (t.rle) return;
    const FseSymbolTT& tt = t.tt[symbol];
    const std::uint32_t nbBitsOut = (st.value + tt.deltaNbBits) >> 16;
    bw.add(st.value, nbBitsOut);
    st.value = t.stateTable[static_cast<std::size_t>(static_cast<std::int32_t>(st.value >> nbBitsOut) + tt.deltaFindState)];
}

void fse_flush(const FseCTable& t, const FseState& st, BitWriter& bw) {
    if (t.rle) return;
    bw.add(st.value, t.log);
}

// Scales counts to a distribution that adds up to 1 << log, every used symbol at least 1 (largest remainder method).
bool fse_normalize(const std::uint32_t* count, unsigned symbols, std::uint64_t total, unsigned log,
                   std::int16_t* norm) {
    const std::int64_t size = 1ll << log;
    unsigned used = 0;
    for (unsigned s = 0; s < symbols; ++s) used += count[s] != 0;
    if (used == 0 || used > static_cast<std::uint64_t>(size)) return false;
    std::int64_t sum = 0;
    for (unsigned s = 0; s < symbols; ++s) {
        if (count[s] == 0) {
            norm[s] = 0;
            continue;
        }
        std::int64_t v = static_cast<std::int64_t>(count[s]) * size / static_cast<std::int64_t>(total);
        if (v < 1) v = 1;
        norm[s] = static_cast<std::int16_t>(v);
        sum += v;
    }
    const std::int64_t t64 = static_cast<std::int64_t>(total);
    while (sum < size) {  // give the missing slots to the symbols that lost the most to rounding
        std::int64_t bestErr = -1;
        unsigned best = 0;
        for (unsigned s = 0; s < symbols; ++s) {
            if (count[s] == 0) continue;
            const std::int64_t err = static_cast<std::int64_t>(count[s]) * size - static_cast<std::int64_t>(norm[s]) * t64;
            if (bestErr < 0 || err > bestErr) {
                bestErr = err;
                best = s;
            }
        }
        ++norm[best];
        ++sum;
    }
    while (sum > size) {  // take slots back from the symbols that got the most extra
        std::int64_t bestErr = 0;
        bool found = false;
        unsigned best = 0;
        for (unsigned s = 0; s < symbols; ++s) {
            if (norm[s] <= 1) continue;
            const std::int64_t err = static_cast<std::int64_t>(norm[s]) * t64 - static_cast<std::int64_t>(count[s]) * size;
            if (!found || err > bestErr) {
                found = true;
                bestErr = err;
                best = s;
            }
        }
        if (!found) return false;
        --norm[best];
        --sum;
    }
    return true;
}

// The accuracy log for a distribution of `total` samples over symbols 0..maxSymbol.
unsigned fse_optimal_log(unsigned maxLog, std::uint64_t total, unsigned maxSymbol) {
    const unsigned hb = total > 1 ? highbit64(total - 1) : 0;
    const int maxBitsSrc = static_cast<int>(hb) - 2;
    const unsigned minBitsSrc = hb + 1;
    const unsigned minBitsSymbols = (maxSymbol > 0 ? highbit32(maxSymbol) : 0) + 2;
    const unsigned minBits = std::min(minBitsSrc, minBitsSymbols);
    int log = static_cast<int>(maxLog);
    if (maxBitsSrc < log) log = maxBitsSrc;
    if (static_cast<int>(minBits) > log) log = static_cast<int>(minBits);
    if (log < 5) log = 5;
    if (log > static_cast<int>(maxLog)) log = static_cast<int>(maxLog);
    return static_cast<unsigned>(log);
}

// Writes the description of a distribution (the inverse of the decoder's read_ncount).
void fse_write_ncount(const std::int16_t* norm, unsigned symbols, unsigned log, std::vector<std::uint8_t>& out) {
    BitWriter bw(out);
    const std::int32_t size = 1 << log;
    std::int32_t remaining = size + 1;
    std::int32_t threshold = size;
    unsigned nbBits = log + 1;
    bw.add(log - 5, 4);
    unsigned sym = 0;
    bool previous0 = false;
    while (sym < symbols && remaining > 1) {
        if (previous0) {
            unsigned start = sym;
            while (sym < symbols && norm[sym] == 0) ++sym;
            if (sym == symbols) break;
            while (sym >= start + 24) {
                start += 24;
                bw.add(0xFFFF, 16);
            }
            while (sym >= start + 3) {
                start += 3;
                bw.add(3, 2);
            }
            bw.add(sym - start, 2);
        }
        std::int32_t count = norm[sym++];
        const std::int32_t max = (2 * threshold - 1) - remaining;
        remaining -= count < 0 ? -count : count;
        ++count;
        if (count >= threshold) count += max;
        bw.add(static_cast<std::uint32_t>(count), nbBits - (count < max ? 1u : 0u));
        previous0 = count == 1;
        while (remaining < threshold) {
            --nbBits;
            threshold >>= 1;
        }
    }
    bw.finish();
}

// Bits needed (in 1/256 bit) to code `count` samples per symbol with a distribution.
std::uint64_t fse_cost_q8(const std::uint32_t* count, unsigned symbols, const std::int16_t* norm, unsigned log) {
    std::uint64_t bits = 0;
    for (unsigned s = 0; s < symbols; ++s) {
        if (!count[s]) continue;
        const std::int32_t n = norm[s] < 0 ? 1 : norm[s];
        if (n == 0) return UINT64_MAX / 4;  // the symbol cannot be coded
        bits += static_cast<std::uint64_t>(count[s]) * ((log << 8) - ilog2_q8(static_cast<std::uint32_t>(n)));
    }
    return bits;
}

// ---- Huffman encoding -----------------------------------------------------------------------------------------------

constexpr unsigned kHufMaxBits = 11;

struct HufCode {
    std::array<std::uint8_t, 256> len{};
    std::array<std::uint16_t, 256> code{};
    unsigned maxBits = 0;
    unsigned lastSymbol = 0;  // highest symbol with a code
};

// Code lengths for a histogram (at least 2 used symbols), at most kHufMaxBits, complete (Kraft sum exactly 1).
bool huffman_build(const std::uint32_t* hist, HufCode& h) {
    std::vector<unsigned> syms;
    for (unsigned s = 0; s < 256; ++s)
        if (hist[s]) syms.push_back(s);
    if (syms.size() < 2) return false;
    std::sort(syms.begin(), syms.end(), [&](unsigned a, unsigned b) { return hist[a] != hist[b] ? hist[a] < hist[b] : a < b; });
    const std::size_t n = syms.size();
    // Two-queue construction: leaves in ascending weight, internal nodes are created in ascending weight too.
    std::vector<std::uint64_t> weight(2 * n - 1);
    std::vector<std::uint32_t> parent(2 * n - 1, 0);
    for (std::size_t i = 0; i < n; ++i) weight[i] = hist[syms[i]];
    std::size_t leaf = 0, node = n, made = n;
    auto take = [&]() -> std::size_t {
        if (leaf < n && (node >= made || weight[leaf] <= weight[node])) return leaf++;
        return node++;
    };
    while (made < 2 * n - 1) {
        const std::size_t a = take();
        const std::size_t b = take();
        weight[made] = weight[a] + weight[b];
        parent[a] = parent[b] = static_cast<std::uint32_t>(made);
        ++made;
    }
    std::vector<unsigned> depth(2 * n - 1, 0);
    for (std::size_t i = 2 * n - 2; i-- > 0;) depth[i] = depth[parent[i]] + 1;
    std::vector<unsigned> len(n);  // by position in `syms` (ascending weight)
    for (std::size_t i = 0; i < n; ++i) len[i] = depth[i];
    // Limit the length: clamp, then lengthen the rarest short codes until the Kraft sum fits, then use up what is left.
    const unsigned limit = kHufMaxBits;
    bool clamped = false;
    for (auto& l : len)
        if (l > limit) {
            l = limit;
            clamped = true;
        }
    if (clamped) {
        std::uint64_t kraft = 0;
        for (unsigned l : len) kraft += 1ull << (limit - l);
        const std::uint64_t full = 1ull << limit;
        while (kraft > full) {
            // the rarest symbol whose code is shorter than the limit (len[] is in ascending weight order)
            std::size_t pick = n;
            for (std::size_t i = 0; i < n; ++i)
                if (len[i] < limit) {
                    pick = i;
                    break;
                }
            if (pick == n) return false;
            kraft -= 1ull << (limit - len[pick] - 1);
            ++len[pick];
        }
        while (kraft < full) {
            // the most frequent symbol that can take a shorter code without passing the Kraft sum
            std::size_t pick = n;
            for (std::size_t i = n; i-- > 0;)
                if (len[i] > 1 && kraft + (1ull << (limit - len[i])) <= full) {
                    pick = i;
                    break;
                }
            if (pick == n) return false;
            kraft += 1ull << (limit - len[pick]);
            --len[pick];
        }
    }
    h.len.fill(0);
    h.code.fill(0);
    h.maxBits = 0;
    h.lastSymbol = 0;
    for (std::size_t i = 0; i < n; ++i) {
        h.len[syms[i]] = static_cast<std::uint8_t>(len[i]);
        h.maxBits = std::max(h.maxBits, len[i]);
        h.lastSymbol = std::max(h.lastSymbol, syms[i]);
    }
    // Canonical codes in the order the decoder lays out its table: longest codes first, then by symbol.
    std::uint32_t pos = 0;
    for (unsigned l = h.maxBits; l >= 1; --l)
        for (unsigned s = 0; s < 256; ++s) {
            if (h.len[s] != l) continue;
            h.code[s] = static_cast<std::uint16_t>(pos >> (h.maxBits - l));
            pos += 1u << (h.maxBits - l);
        }
    return pos == (1u << h.maxBits);
}

// Interleaved two-state FSE coding of the Huffman weights (RFC 8878, 4.2.1.2). Returns false when it does not help.
bool huffman_weights_fse(const std::uint8_t* weights, unsigned count, std::vector<std::uint8_t>& out) {
    if (count < 3) return false;
    std::array<std::uint32_t, 16> hist{};
    unsigned maxSym = 0, distinct = 0;
    for (unsigned i = 0; i < count; ++i) {
        if (hist[weights[i]]++ == 0) ++distinct;
        maxSym = std::max<unsigned>(maxSym, weights[i]);
    }
    if (distinct < 2) return false;
    const unsigned log = fse_optimal_log(kMaxHufWeightLog, count, maxSym);
    std::array<std::int16_t, 16> norm{};
    if (!fse_normalize(hist.data(), maxSym + 1, count, log, norm.data())) return false;
    std::vector<std::uint8_t> tmp;
    fse_write_ncount(norm.data(), maxSym + 1, log, tmp);
    FseCTable ct;
    fse_build_ctable(ct, norm.data(), maxSym + 1, log);
    BitWriter bw(tmp);
    FseState s1, s2;
    // Symbol k belongs to state 1 when k is even; the last two initialize the states, the rest are coded backwards.
    fse_init_state(ct, (count & 1) ? s1 : s2, weights[count - 1]);
    fse_init_state(ct, (count & 1) ? s2 : s1, weights[count - 2]);
    for (unsigned k = count - 2; k-- > 0;) fse_encode(ct, (k & 1) ? s2 : s1, weights[k], bw);
    fse_flush(ct, s2, bw);
    fse_flush(ct, s1, bw);
    bw.close_with_mark();
    out.insert(out.end(), tmp.begin(), tmp.end());
    return true;
}

// The Huffman tree description (weights) of a code. Returns false when no form fits.
bool huffman_write_tree(const HufCode& h, std::vector<std::uint8_t>& out) {
    const unsigned count = h.lastSymbol;  // the last symbol's weight is implied
    std::array<std::uint8_t, 256> weights{};
    for (unsigned s = 0; s < count; ++s) weights[s] = static_cast<std::uint8_t>(h.len[s] ? h.maxBits + 1 - h.len[s] : 0);
    std::vector<std::uint8_t> fse;
    const bool haveFse = huffman_weights_fse(weights.data(), count, fse) && fse.size() < 128;
    const std::size_t direct = count <= 128 ? 1 + (count + 1) / 2 : SIZE_MAX;
    if (haveFse && 1 + fse.size() < direct) {
        out.push_back(static_cast<std::uint8_t>(fse.size()));
        out.insert(out.end(), fse.begin(), fse.end());
        return true;
    }
    if (count > 128 || count == 0) return false;
    out.push_back(static_cast<std::uint8_t>(127 + count));
    for (unsigned i = 0; i < count; i += 2)
        out.push_back(static_cast<std::uint8_t>((weights[i] << 4) | (i + 1 < count ? weights[i + 1] : 0)));
    return true;
}

void huffman_stream(const HufCode& h, const std::uint8_t* src, std::size_t n, std::vector<std::uint8_t>& out) {
    BitWriter bw(out);
    for (std::size_t i = n; i-- > 0;) bw.add(h.code[src[i]], h.len[src[i]]);
    bw.close_with_mark();
}

// ---- Match finders --------------------------------------------------------------------------------------------------

struct Seq {
    std::uint32_t litLen;
    std::uint32_t matchLen;
    std::uint32_t offset;   // distance back
    std::uint32_t offBase;  // the Offset_Value written: 1..3 repeat offsets, else offset + 3
};

// Offset_Value for a match and the effect on the three repeat offsets (mirrors the decoder).
std::uint32_t offset_value(std::uint32_t offset, std::uint32_t litLen, std::uint32_t* rep) {
    std::uint32_t value;
    if (litLen > 0) {
        if (offset == rep[0]) return 1;
        if (offset == rep[1]) {
            value = 2;
            rep[1] = rep[0];
            rep[0] = offset;
            return value;
        }
        if (offset == rep[2]) {
            value = 3;
            rep[2] = rep[1];
            rep[1] = rep[0];
            rep[0] = offset;
            return value;
        }
    } else {
        if (offset == rep[1]) {
            rep[1] = rep[0];
            rep[0] = offset;
            return 1;
        }
        if (offset == rep[2]) {
            rep[2] = rep[1];
            rep[1] = rep[0];
            rep[0] = offset;
            return 2;
        }
        if (rep[0] > 1 && offset == rep[0] - 1) {
            rep[2] = rep[1];
            rep[1] = rep[0];
            rep[0] = offset;
            return 3;
        }
    }
    rep[2] = rep[1];
    rep[1] = rep[0];
    rep[0] = offset;
    return offset + 3;
}

inline std::size_t count_match(const std::uint8_t* a, const std::uint8_t* b, const std::uint8_t* limit) {
    const std::uint8_t* const start = a;
    while (limit - a >= 8) {
        const std::uint64_t diff = load64(a) ^ load64(b);
        if (diff) return static_cast<std::size_t>(a - start) + static_cast<std::size_t>(std::countr_zero(diff) >> 3);
        a += 8;
        b += 8;
    }
    while (a < limit && *a == *b) {
        ++a;
        ++b;
    }
    return static_cast<std::size_t>(a - start);
}

inline std::size_t hash4(std::uint32_t v, unsigned bits) { return (v * 2654435761u) >> (32 - bits); }

constexpr std::size_t kMinMatch = 4;

struct Params {
    int strategy;       // 0 fast (one hash table), 1 hash chains
    unsigned windowLog;
    unsigned hashLog;   // hash table of 4-byte sequences (the chain heads for strategy 1)
    unsigned stepShift; // strategy 0: the step grows by 1 every 1 << stepShift bytes without a match
    unsigned attempts;  // strategy 1: chain links followed per position
    unsigned lazy;
    unsigned nice;
};

Params params_for(int level) {
    switch (level) {
        case 1: return {0, 20, 16, 7, 0, 0, 0};
        case 2: return {0, 20, 17, 8, 0, 0, 0};
        case 3: return {1, 21, 17, 0, 6, 1, 24};
        case 4: return {1, 21, 17, 0, 10, 1, 32};
        case 5: return {1, 22, 18, 0, 14, 1, 32};
        case 6: return {1, 22, 18, 0, 16, 1, 40};
        case 7: return {1, 22, 18, 0, 24, 2, 56};
        case 8: return {1, 22, 18, 0, 32, 2, 64};
        case 9: return {1, 22, 18, 0, 48, 2, 64};
        case 10: return {1, 22, 19, 0, 64, 2, 96};
        case 11: return {1, 22, 19, 0, 96, 2, 128};
        case 12: return {1, 23, 19, 0, 128, 2, 160};
        case 13: return {1, 23, 20, 0, 256, 2, 224};
        case 14: return {1, 23, 20, 0, 384, 2, 256};
        case 15: return {1, 23, 20, 0, 512, 2, 320};
        case 16: return {1, 23, 20, 0, 768, 2, 384};
        case 17: return {1, 23, 20, 0, 1024, 2, 512};
        case 18: return {1, 23, 20, 0, 1536, 2, 768};
        default: return {1, 23, 20, 0, 2048, 2, 1024};
    }
}

unsigned ceil_log2(std::uint64_t v) { return v <= 1 ? 0 : highbit64(v - 1) + 1; }

class Matcher {
public:
    Matcher(const std::uint8_t* src, std::size_t n, const Params& p, std::size_t maxDist)
        : src_(src), n_(n), p_(p), maxDist_(maxDist) {
        // Tables never need to be larger than the input (smaller tables also make small blocks faster to set up).
        const unsigned fit = std::max(10u, ceil_log2(n) + 1);
        hashLog_ = std::min(p.hashLog, fit);
        if (p.strategy == 1) {
            const unsigned chainLog = std::min(std::max(10u, ceil_log2(n)), 22u);
            chainSize_ = std::size_t{1} << chainLog;
            head_.assign(std::size_t{1} << hashLog_, 0);
            chain_.assign(chainSize_, 0);
        } else {
            tableShort_.assign(std::size_t{1} << hashLog_, 0);
        }
    }

    // Appends the sequences covering src[start, end); the bytes after the last match are literals.
    void parse(std::size_t start, std::size_t end, std::uint32_t* rep, std::vector<Seq>& seqs) {
        if (end - start < 16) return;
        switch (p_.strategy) {
            case 0: parse_fast(start, end, rep, seqs); break;
            default: parse_chain(start, end, rep, seqs); break;
        }
    }

private:
    struct Cand {
        std::size_t len = 0;
        std::size_t off = 0;
    };

    void commit(std::vector<Seq>& seqs, std::size_t anchor, std::size_t at, std::size_t len, std::size_t off,
                std::uint32_t* rep) {
        const std::uint32_t ll = static_cast<std::uint32_t>(at - anchor);
        const std::uint32_t base = offset_value(static_cast<std::uint32_t>(off), ll, rep);
        seqs.push_back({ll, static_cast<std::uint32_t>(len), static_cast<std::uint32_t>(off), base});
    }

    // Longest agreement of src[ip..] with src[ip - off..], at least kMinMatch or 0.
    std::size_t match_at(std::size_t ip, std::size_t off, std::size_t end) const {
        if (off == 0 || off > ip || off > maxDist_) return 0;
        const std::uint8_t* a = src_ + ip;
        const std::uint8_t* b = a - off;
        if (load32(a) != load32(b)) return 0;
        return kMinMatch + count_match(a + kMinMatch, b + kMinMatch, src_ + end);
    }

    void extend_back(std::size_t anchor, std::size_t& ip, std::size_t off, std::size_t& len) const {
        while (ip > anchor && ip > off && src_[ip - 1] == src_[ip - off - 1]) {
            --ip;
            ++len;
        }
    }

    void parse_fast(std::size_t start, std::size_t end, std::uint32_t* rep, std::vector<Seq>& seqs) {
        std::size_t anchor = start, ip = start;
        const std::size_t limit = end - 8;
        while (ip <= limit) {
            const std::uint32_t seq4 = load32(src_ + ip);
            const std::size_t h = hash4(seq4, hashLog_);
            const std::size_t cand = tableShort_[h];
            tableShort_[h] = static_cast<std::uint32_t>(ip);
            std::size_t len = match_at(ip, rep[0], end), off = rep[0];
            if (len == 0 && cand < ip) {
                len = match_at(ip, ip - cand, end);
                off = ip - cand;
            }
            if (len == 0) {
                ip += 1 + ((ip - anchor) >> p_.stepShift);
                continue;
            }
            extend_back(anchor, ip, off, len);
            commit(seqs, anchor, ip, len, off, rep);
            ip += len;
            anchor = ip;
            if (ip - 2 <= limit) tableShort_[hash4(load32(src_ + ip - 2), hashLog_)] = static_cast<std::uint32_t>(ip - 2);
        }
    }

    void insert_to(std::size_t upto) {
        const std::size_t last = n_ >= kMinMatch ? n_ - kMinMatch + 1 : 0;
        if (upto > last) upto = last;
        while (next_ < upto) {
            const std::size_t h = hash4(load32(src_ + next_), hashLog_);
            chain_[next_ & (chainSize_ - 1)] = head_[h];  // previous position + 1
            head_[h] = static_cast<std::uint32_t>(next_ + 1);
            ++next_;
        }
    }

    static long long gain_of(const Cand& c, bool isRep) {
        return static_cast<long long>(c.len) * 4 - (isRep ? 0 : static_cast<long long>(highbit64(c.off + 1)));
    }

    // The best match at ip: the longest of the hash chain, compared by gain with the three repeat offsets.
    Cand find(std::size_t ip, std::size_t end, const std::uint32_t* rep) {
        insert_to(ip + 1);
        Cand best;
        bool bestRep = false;
        for (int r = 0; r < 3; ++r) {
            const std::size_t len = match_at(ip, rep[r], end);
            if (len && (best.len == 0 || gain_of({len, rep[r]}, true) > gain_of(best, bestRep))) {
                best = {len, rep[r]};
                bestRep = true;
            }
        }
        const std::uint8_t* const here = src_ + ip;
        const std::uint8_t* const limit = src_ + end;
        const std::uint32_t seq = load32(here);
        std::uint32_t cand = head_[hash4(seq, hashLog_)];
        Cand chainBest;
        unsigned attempts = p_.attempts;
        while (cand && attempts--) {
            const std::size_t cpos = cand - 1;
            if (cpos < ip) {
                const std::size_t dist = ip - cpos;
                if (dist > maxDist_ || dist >= chainSize_) break;
                const std::uint8_t* ref = src_ + cpos;
                if ((chainBest.len == 0 || (here + chainBest.len < limit && ref[chainBest.len] == here[chainBest.len])) &&
                    load32(ref) == seq) {
                    const std::size_t len = kMinMatch + count_match(here + kMinMatch, ref + kMinMatch, limit);
                    if (len > chainBest.len) {
                        chainBest = {len, dist};
                        if (len >= p_.nice || here + len >= limit) break;
                    }
                }
            }
            if (cpos == 0) break;
            const std::uint32_t next = chain_[cpos & (chainSize_ - 1)];
            if (next == 0 || next - 1 >= cpos) break;
            cand = next;
        }
        if (chainBest.len && (best.len == 0 || gain_of(chainBest, false) > gain_of(best, bestRep))) best = chainBest;
        return best;
    }

    void parse_chain(std::size_t start, std::size_t end, std::uint32_t* rep, std::vector<Seq>& seqs) {
        std::size_t anchor = start, ip = start;
        const std::size_t limit = end - 8;
        while (ip <= limit) {
            Cand c = find(ip, end, rep);
            if (c.len < kMinMatch) {
                ++ip;
                continue;
            }
            const bool hasRep = c.off == rep[0] || c.off == rep[1] || c.off == rep[2];
            for (unsigned depth = 0; depth < p_.lazy && c.len < p_.nice;) {
                if (ip + 1 > limit) break;
                const Cand c2 = find(ip + 1, end, rep);
                const bool rep2 = c2.off == rep[0] || c2.off == rep[1] || c2.off == rep[2];
                if (c2.len >= kMinMatch && gain_of(c2, rep2) > gain_of(c, hasRep && depth == 0) + 4) {
                    ++ip;
                    c = c2;
                    ++depth;
                    continue;
                }
                if (p_.lazy >= 2 && ip + 2 <= limit) {
                    const Cand c3 = find(ip + 2, end, rep);
                    const bool rep3 = c3.off == rep[0] || c3.off == rep[1] || c3.off == rep[2];
                    if (c3.len >= kMinMatch && gain_of(c3, rep3) > gain_of(c, false) + 7) {
                        ip += 2;
                        c = c3;
                        depth += 2;
                        continue;
                    }
                }
                break;
            }
            std::size_t len = c.len;
            extend_back(anchor, ip, c.off, len);
            commit(seqs, anchor, ip, len, c.off, rep);
            ip += len;
            anchor = ip;
        }
    }

    const std::uint8_t* src_;
    std::size_t n_;
    Params p_;
    std::size_t maxDist_;
    unsigned hashLog_ = 0;
    std::size_t chainSize_ = 0;
    std::size_t next_ = 0;
    std::vector<std::uint32_t> tableShort_, head_, chain_;
};

// ---- Block assembly -------------------------------------------------------------------------------------------------

unsigned ll_code(std::uint32_t v) {
    return static_cast<unsigned>(std::upper_bound(std::begin(kLlBase), std::end(kLlBase), v) - std::begin(kLlBase)) - 1;
}
unsigned ml_code(std::uint32_t matchLen) {
    return static_cast<unsigned>(std::upper_bound(std::begin(kMlBase), std::end(kMlBase), matchLen) - std::begin(kMlBase)) - 1;
}

// How one of the three symbol streams of a block is coded.
struct StreamCoding {
    unsigned mode = 0;  // 0 predefined, 1 RLE, 2 FSE
    FseCTable table;
    std::vector<std::uint8_t> header;  // the RLE symbol or the table description
};

// Picks and prepares the coding of a stream of `codes` (symbols < maxSymbols).
void choose_coding(const std::vector<std::uint8_t>& codes, unsigned maxSymbols, unsigned maxLog,
                   const std::int16_t* defNorm, unsigned defSymbols, unsigned defLog, StreamCoding& out) {
    std::array<std::uint32_t, 64> count{};
    unsigned maxUsed = 0, distinct = 0;
    for (std::uint8_t c : codes) {
        if (count[c]++ == 0) ++distinct;
        maxUsed = std::max<unsigned>(maxUsed, c);
    }
    const std::size_t nb = codes.size();
    (void)maxSymbols;
    // predefined
    bool defOk = maxUsed < defSymbols;
    std::uint64_t defCost = UINT64_MAX;
    if (defOk) defCost = fse_cost_q8(count.data(), defSymbols, defNorm, defLog);
    // RLE
    std::uint64_t rleCost = distinct == 1 ? 8u * 256u : UINT64_MAX;
    // custom
    std::uint64_t fseCost = UINT64_MAX;
    std::array<std::int16_t, 64> norm{};
    unsigned log = 0;
    std::vector<std::uint8_t> desc;
    if (distinct >= 2) {
        log = fse_optimal_log(maxLog, nb, maxUsed);
        if (fse_normalize(count.data(), maxUsed + 1, nb, log, norm.data())) {
            fse_write_ncount(norm.data(), maxUsed + 1, log, desc);
            fseCost = fse_cost_q8(count.data(), maxUsed + 1, norm.data(), log) + desc.size() * 8u * 256u;
        }
    }
    if (rleCost <= defCost && rleCost <= fseCost) {
        out.mode = 1;
        out.table.rle = true;
        out.table.log = 0;
        out.header = {static_cast<std::uint8_t>(codes[0])};
    } else if (defCost <= fseCost) {
        out.mode = 0;
        fse_build_ctable(out.table, defNorm, defSymbols, defLog);
    } else {
        out.mode = 2;
        fse_build_ctable(out.table, norm.data(), maxUsed + 1, log);
        out.header = std::move(desc);
    }
}

class Encoder {
public:
    Encoder(std::span<const std::uint8_t> in, int level, bool checksum, std::vector<std::uint8_t>& out)
        : in_(in), level_(level), checksum_(checksum), out_(out), params_(params_for(level)) {}

    void run() {
        const std::size_t n = in_.size();
        const std::size_t windowMax = std::size_t{1} << params_.windowLog;
        const bool single = n <= windowMax;
        unsigned windowLog = params_.windowLog;
        std::size_t maxDist = windowMax;
        if (single) {
            maxDist = std::max<std::size_t>(n, 1);
        }
        write_frame_header(n, single, windowLog);
        const std::size_t blockMax = single ? std::min<std::size_t>(std::max<std::size_t>(n, 1), kBlockMax) : kBlockMax;
        if (n == 0) {
            out_.push_back(0x01);  // a last, empty, raw block
            out_.push_back(0);
            out_.push_back(0);
        } else {
            Matcher matcher(in_.data(), n, params_, maxDist);
            std::vector<Seq> seqs;
            std::uint32_t rep[3] = {1, 4, 8};
            for (std::size_t pos = 0; pos < n;) {
                const std::size_t len = std::min(blockMax, n - pos);
                seqs.clear();
                std::uint32_t trial[3] = {rep[0], rep[1], rep[2]};
                if (level_ >= 1) matcher.parse(pos, pos + len, trial, seqs);
                encode_block(pos, len, pos + len == n, seqs, trial, rep);
                pos += len;
            }
        }
        if (checksum_) {
            std::uint8_t cs[4];
            store32(cs, static_cast<std::uint32_t>(xxh64(in_.data(), in_.size())));
            out_.insert(out_.end(), cs, cs + 4);
        }
    }

private:
    void write_frame_header(std::size_t n, bool single, unsigned windowLog) {
        std::uint8_t magic[4];
        store32(magic, kFrameMagic);
        out_.insert(out_.end(), magic, magic + 4);
        unsigned fcsFlag;
        if (single)
            fcsFlag = n < 256 ? 0 : n < 65536 + 256 ? 1 : static_cast<std::uint64_t>(n) <= 0xFFFFFFFFull ? 2 : 3;
        else
            fcsFlag = n < 65536 + 256 ? 1 : static_cast<std::uint64_t>(n) <= 0xFFFFFFFFull ? 2 : 3;
        out_.push_back(static_cast<std::uint8_t>((fcsFlag << 6) | (single ? 0x20 : 0) | (checksum_ ? 0x04 : 0)));
        if (!single) out_.push_back(static_cast<std::uint8_t>((windowLog - 10) << 3));
        const std::uint64_t v = (fcsFlag == 1) ? n - 256 : n;
        const unsigned bytes = fcsFlag == 0 ? 1 : fcsFlag == 1 ? 2 : fcsFlag == 2 ? 4 : 8;
        for (unsigned i = 0; i < bytes; ++i) out_.push_back(static_cast<std::uint8_t>(v >> (8 * i)));
    }

    void block_header(bool last, unsigned type, std::size_t size) {
        const std::uint32_t h = (last ? 1u : 0u) | (type << 1) | (static_cast<std::uint32_t>(size) << 3);
        out_.push_back(static_cast<std::uint8_t>(h));
        out_.push_back(static_cast<std::uint8_t>(h >> 8));
        out_.push_back(static_cast<std::uint8_t>(h >> 16));
    }

    void encode_block(std::size_t pos, std::size_t len, bool last, const std::vector<Seq>& seqs,
                      const std::uint32_t* trialRep, std::uint32_t* rep) {
        const std::uint8_t* const src = in_.data() + pos;
        // RLE block?
        if (len >= 2) {
            bool same = true;
            for (std::size_t i = 1; i < len && same; ++i) same = src[i] == src[0];
            if (same) {
                block_header(last, 1, len);
                out_.push_back(src[0]);
                return;
            }
        }
        std::vector<std::uint8_t> body;
        if (len >= 32 && compress_body(src, len, seqs, body) && body.size() < len) {
            block_header(last, 2, body.size());
            out_.insert(out_.end(), body.begin(), body.end());
            rep[0] = trialRep[0];
            rep[1] = trialRep[1];
            rep[2] = trialRep[2];
            return;
        }
        block_header(last, 0, len);
        out_.insert(out_.end(), src, src + len);
    }

    // Literals section + sequences section; false if the block cannot be coded.
    bool compress_body(const std::uint8_t* src, std::size_t len, const std::vector<Seq>& seqs,
                       std::vector<std::uint8_t>& body) {
        std::vector<std::uint8_t> lits;
        lits.reserve(len);
        std::size_t at = 0;
        for (const Seq& s : seqs) {
            lits.insert(lits.end(), src + at, src + at + s.litLen);
            at += static_cast<std::size_t>(s.litLen) + s.matchLen;
        }
        lits.insert(lits.end(), src + at, src + len);
        write_literals(lits, body);
        write_sequences(seqs, body);
        return true;
    }

    static void raw_literals_header(std::size_t n, unsigned type, std::vector<std::uint8_t>& out) {
        if (n < 32) {
            out.push_back(static_cast<std::uint8_t>(type | (n << 3)));
        } else if (n < 4096) {
            const std::uint32_t h = type | (1u << 2) | (static_cast<std::uint32_t>(n) << 4);
            out.push_back(static_cast<std::uint8_t>(h));
            out.push_back(static_cast<std::uint8_t>(h >> 8));
        } else {
            const std::uint32_t h = type | (3u << 2) | (static_cast<std::uint32_t>(n) << 4);
            out.push_back(static_cast<std::uint8_t>(h));
            out.push_back(static_cast<std::uint8_t>(h >> 8));
            out.push_back(static_cast<std::uint8_t>(h >> 16));
        }
    }

    void write_literals(const std::vector<std::uint8_t>& lits, std::vector<std::uint8_t>& body) {
        const std::size_t n = lits.size();
        if (n >= 2) {
            bool same = true;
            for (std::size_t i = 1; i < n && same; ++i) same = lits[i] == lits[0];
            if (same) {
                raw_literals_header(n, 1, body);
                body.push_back(lits[0]);
                return;
            }
        }
        if (n >= 64) {
            std::vector<std::uint8_t> section;
            if (huffman_literals(lits, section) && section.size() + (n >> 6) + 2 < n + (n < 32 ? 1 : n < 4096 ? 2 : 3)) {
                body.insert(body.end(), section.begin(), section.end());
                return;
            }
        }
        raw_literals_header(n, 0, body);
        body.insert(body.end(), lits.begin(), lits.end());
    }

    // The whole Huffman literals section (header, tree, streams).
    bool huffman_literals(const std::vector<std::uint8_t>& lits, std::vector<std::uint8_t>& section) {
        std::array<std::uint32_t, 256> hist{};
        for (std::uint8_t b : lits) ++hist[b];
        HufCode h;
        if (!huffman_build(hist.data(), h)) return false;
        std::vector<std::uint8_t> payload;
        if (!huffman_write_tree(h, payload)) return false;
        const std::size_t n = lits.size();
        const bool four = n >= 256;
        if (!four) {
            huffman_stream(h, lits.data(), n, payload);
        } else {
            const std::size_t seg = (n + 3) / 4;
            std::vector<std::uint8_t> s[4];
            for (int i = 0; i < 4; ++i) {
                const std::size_t from = seg * static_cast<std::size_t>(i);
                const std::size_t to = i == 3 ? n : seg * static_cast<std::size_t>(i + 1);
                huffman_stream(h, lits.data() + from, to - from, s[i]);
            }
            for (int i = 0; i < 3; ++i) {
                if (s[i].size() > 65535) return false;
                payload.push_back(static_cast<std::uint8_t>(s[i].size()));
                payload.push_back(static_cast<std::uint8_t>(s[i].size() >> 8));
            }
            for (int i = 0; i < 4; ++i) payload.insert(payload.end(), s[i].begin(), s[i].end());
        }
        const std::size_t comp = payload.size();
        unsigned sizeFormat, bits;
        if (!four) {
            sizeFormat = 0;
            bits = 10;
        } else if (n <= 1023 && comp <= 1023) {
            sizeFormat = 1;
            bits = 10;
        } else if (n <= 16383 && comp <= 16383) {
            sizeFormat = 2;
            bits = 14;
        } else {
            sizeFormat = 3;
            bits = 18;
        }
        if (comp >= (1u << bits) || n >= (1u << bits)) return false;
        const std::uint64_t head = 2u | (sizeFormat << 2) | (static_cast<std::uint64_t>(n) << 4) |
                                   (static_cast<std::uint64_t>(comp) << (4 + bits));
        const unsigned headBytes = sizeFormat <= 1 ? 3 : sizeFormat == 2 ? 4 : 5;
        for (unsigned i = 0; i < headBytes; ++i) section.push_back(static_cast<std::uint8_t>(head >> (8 * i)));
        section.insert(section.end(), payload.begin(), payload.end());
        return true;
    }

    void write_sequences(const std::vector<Seq>& seqs, std::vector<std::uint8_t>& body) {
        const std::size_t nb = seqs.size();
        if (nb < 128) {
            body.push_back(static_cast<std::uint8_t>(nb));
        } else if (nb < 0x7F00) {
            body.push_back(static_cast<std::uint8_t>((nb >> 8) + 128));
            body.push_back(static_cast<std::uint8_t>(nb));
        } else {
            body.push_back(255);
            body.push_back(static_cast<std::uint8_t>(nb - 0x7F00));
            body.push_back(static_cast<std::uint8_t>((nb - 0x7F00) >> 8));
        }
        if (nb == 0) return;
        std::vector<std::uint8_t> llc(nb), ofc(nb), mlc(nb);
        for (std::size_t i = 0; i < nb; ++i) {
            llc[i] = static_cast<std::uint8_t>(ll_code(seqs[i].litLen));
            mlc[i] = static_cast<std::uint8_t>(ml_code(seqs[i].matchLen));
            ofc[i] = static_cast<std::uint8_t>(highbit32(seqs[i].offBase));
        }
        StreamCoding cl, co, cm;
        choose_coding(llc, 36, kMaxLlLog, kLlDefaultNorm, 36, kLlDefaultLog, cl);
        choose_coding(ofc, 32, kMaxOfLog, kOfDefaultNorm, 29, kOfDefaultLog, co);
        choose_coding(mlc, 53, kMaxMlLog, kMlDefaultNorm, 53, kMlDefaultLog, cm);
        body.push_back(static_cast<std::uint8_t>((cl.mode << 6) | (co.mode << 4) | (cm.mode << 2)));
        body.insert(body.end(), cl.header.begin(), cl.header.end());
        body.insert(body.end(), co.header.begin(), co.header.end());
        body.insert(body.end(), cm.header.begin(), cm.header.end());
        BitWriter bw(body);
        FseState sMl, sOf, sLl;
        const std::size_t last = nb - 1;
        fse_init_state(cm.table, sMl, mlc[last]);
        fse_init_state(co.table, sOf, ofc[last]);
        fse_init_state(cl.table, sLl, llc[last]);
        auto extras = [&](std::size_t i) {
            bw.add(seqs[i].litLen - kLlBase[llc[i]], kLlExtraBits[llc[i]]);
            bw.add(seqs[i].matchLen - kMlBase[mlc[i]], kMlExtraBits[mlc[i]]);
            bw.add(seqs[i].offBase - (1u << ofc[i]), ofc[i]);
        };
        extras(last);
        for (std::size_t i = last; i-- > 0;) {
            fse_encode(co.table, sOf, ofc[i], bw);
            fse_encode(cm.table, sMl, mlc[i], bw);
            fse_encode(cl.table, sLl, llc[i], bw);
            extras(i);
        }
        fse_flush(cm.table, sMl, bw);
        fse_flush(co.table, sOf, bw);
        fse_flush(cl.table, sLl, bw);
        bw.close_with_mark();
    }

    std::span<const std::uint8_t> in_;
    int level_;
    bool checksum_;
    std::vector<std::uint8_t>& out_;
    Params params_;
};

}  // namespace

void zstd_compress(std::span<const std::uint8_t> input, int level, bool checksum, std::vector<std::uint8_t>& out) {
    level = std::clamp(level, 1, 19);
    out.reserve(out.size() + zstd_compress_bound(input.size()));
    Encoder(input, level, checksum, out).run();
}

}  // namespace fa::codec
