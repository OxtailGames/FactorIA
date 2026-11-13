// Zstandard decoder (RFC 8878), written for the engine. It reads every frame the reference encoder writes at any level
// (no dictionaries), checks everything it reads against the block's and the output's bounds, and never allocates more
// than the 128 KiB literal buffer: the output is the caller's buffer.
#include <algorithm>
#include <array>
#include <memory>

#include "compress_internal.h"
#include "zstd_common.h"

namespace fa::codec {

using namespace zstd;

namespace {

// ---- Backward bit stream (Huffman streams, sequences, FSE-coded weights) -------------------------------------------
// The writer fills bytes from the least significant bit up and ends with a 1 bit (the sentinel) after the last data
// bit; the reader starts below the sentinel and goes down. `remaining` counts the unread bits; reading past the start
// makes it negative (a damaged stream) and returns zeros.
struct BackBits {
    const std::uint8_t* p = nullptr;
    std::int64_t size = 0;       // bytes
    std::int64_t remaining = 0;  // unread bits

    bool init(const std::uint8_t* data, std::size_t n) {
        if (n == 0 || data[n - 1] == 0) return false;
        p = data;
        size = static_cast<std::int64_t>(n);
        remaining = (size - 1) * 8 + static_cast<std::int64_t>(highbit32(data[n - 1]));
        return true;
    }

    // The n (<= 32) bits just below the read position as a number; the position is not moved.
    std::uint32_t peek(unsigned n) const {
        if (n == 0) return 0;
        const std::int64_t start = remaining - static_cast<std::int64_t>(n);
        if (start >= 0) return extract(start, n);
        const std::int64_t have = static_cast<std::int64_t>(n) + start;  // bits that exist
        if (have <= 0) return 0;
        return extract(0, static_cast<unsigned>(have)) << static_cast<unsigned>(-start);
    }
    void skip(unsigned n) { remaining -= static_cast<std::int64_t>(n); }
    std::uint32_t read(unsigned n) {
        const std::uint32_t v = peek(n);
        remaining -= static_cast<std::int64_t>(n);
        return v;
    }

private:
    // Bits [start, start + n) of the stream, start >= 0, start + n <= remaining.
    std::uint32_t extract(std::int64_t start, unsigned n) const {
        const std::int64_t hi = (start + static_cast<std::int64_t>(n) - 1) >> 3;  // byte holding the top bit
        std::uint64_t w;
        std::int64_t base;
        if (hi >= 7) {
            base = hi - 7;
            w = load64(p + base);
        } else {
            base = 0;
            w = 0;
            for (std::int64_t i = 0; i <= hi; ++i) w |= static_cast<std::uint64_t>(p[i]) << (8 * i);
        }
        const unsigned shift = static_cast<unsigned>(start - base * 8);
        const std::uint64_t mask = n >= 32 ? 0xFFFFFFFFull : ((1ull << n) - 1);
        return static_cast<std::uint32_t>((w >> shift) & mask);
    }
};

// ---- FSE ------------------------------------------------------------------------------------------------------------

struct FseTable {
    unsigned log = 0;
    std::array<FseCell, 512> cell{};
};

// A table of one repeated symbol, no bits (the RLE mode of sequences).
void fse_rle(FseTable& t, unsigned symbol) {
    t.log = 0;
    t.cell[0] = FseCell{0, static_cast<std::uint8_t>(symbol), 0};
}

// Builds the decoding table of a normalized distribution (counts sum to 1 << log, -1 = "less than 1").
bool fse_build(FseTable& t, const std::int16_t* norm, unsigned symbols, unsigned log) {
    const unsigned size = 1u << log;
    std::array<std::uint16_t, 256> next{};
    unsigned high = size - 1;
    for (unsigned s = 0; s < symbols; ++s) {
        if (norm[s] == -1) {
            t.cell[high].symbol = static_cast<std::uint8_t>(s);
            --high;
            next[s] = 1;
        } else {
            next[s] = static_cast<std::uint16_t>(norm[s]);
        }
    }
    const unsigned step = (size >> 1) + (size >> 3) + 3;
    const unsigned mask = size - 1;
    unsigned pos = 0;
    for (unsigned s = 0; s < symbols; ++s) {
        for (int i = 0; i < norm[s]; ++i) {
            t.cell[pos].symbol = static_cast<std::uint8_t>(s);
            do pos = (pos + step) & mask;
            while (pos > high);
        }
    }
    if (pos != 0) return false;
    for (unsigned u = 0; u < size; ++u) {
        const unsigned s = t.cell[u].symbol;
        const unsigned nextState = next[s]++;
        const unsigned nb = log - highbit32(nextState);
        t.cell[u].nbBits = static_cast<std::uint8_t>(nb);
        t.cell[u].newState = static_cast<std::uint16_t>((nextState << nb) - size);
    }
    t.log = log;
    return true;
}

// Reads an FSE table description (the "normalized count"): forward bit stream, 4 bits of accuracy log - 5, then one
// variable-width count per symbol. Returns the bytes used; `symbols` receives the number of symbols described.
Result<std::size_t> read_ncount(const std::uint8_t* p, std::size_t avail, const std::uint8_t* base, std::int16_t* norm,
                                unsigned maxSymbols, unsigned maxLog, unsigned& symbols, unsigned& log) {
    auto bits_at = [&](std::size_t bitPos) -> std::uint32_t {  // 32 bits from bitPos, zeros past the end
        const std::size_t byte = bitPos >> 3;
        std::uint64_t w = 0;
        for (std::size_t i = 0; i < 5; ++i)
            if (byte + i < avail) w |= static_cast<std::uint64_t>(p[byte + i]) << (8 * i);
        return static_cast<std::uint32_t>(w >> (bitPos & 7));
    };
    if (avail == 0) return block_error("zstd", "a table description is missing", p - base);
    std::size_t bitPos = 0;
    log = (bits_at(0) & 15u) + 5;
    bitPos = 4;
    if (log > maxLog)
        return block_error("zstd",
                           "a table has accuracy " + std::to_string(log) + " bits, more than the " +
                               std::to_string(maxLog) + " allowed",
                           p - base);
    std::int32_t remaining = static_cast<std::int32_t>((1u << log) + 1);
    std::uint32_t threshold = 1u << log;
    unsigned nbBits = log + 1;
    unsigned sym = 0;
    bool previous0 = false;
    while (remaining > 1 && sym < maxSymbols) {
        if (previous0) {
            unsigned n0 = sym;
            for (;;) {
                const unsigned r = bits_at(bitPos) & 3u;
                bitPos += 2;
                n0 += r;
                if (r != 3) break;
                if (n0 > maxSymbols + 3) break;  // a damaged run of repeat flags; caught right below
            }
            if (n0 >= maxSymbols) return block_error("zstd", "a table describes too many symbols", p - base);
            while (sym < n0) norm[sym++] = 0;
        }
        const std::int32_t max = static_cast<std::int32_t>(2 * threshold - 1) - remaining;
        std::int32_t count;
        const std::uint32_t v = bits_at(bitPos);
        if (static_cast<std::int32_t>(v & (threshold - 1)) < max) {
            count = static_cast<std::int32_t>(v & (threshold - 1));
            bitPos += nbBits - 1;
        } else {
            count = static_cast<std::int32_t>(v & (2 * threshold - 1));
            if (count >= static_cast<std::int32_t>(threshold)) count -= max;
            bitPos += nbBits;
        }
        --count;
        remaining -= count < 0 ? -count : count;
        norm[sym++] = static_cast<std::int16_t>(count);
        previous0 = count == 0;
        while (remaining < static_cast<std::int32_t>(threshold) && nbBits > 0) {
            --nbBits;
            threshold >>= 1;
        }
        if (threshold == 0) break;
    }
    if (remaining != 1) return block_error("zstd", "a table description does not add up", p - base);
    const std::size_t used = (bitPos + 7) >> 3;
    if (used > avail) return block_error("zstd", "a table description is cut short", p - base);
    symbols = sym;
    return used;
}

// ---- Huffman --------------------------------------------------------------------------------------------------------

struct HufTable {
    unsigned maxBits = 0;
    struct Cell {
        std::uint8_t symbol;
        std::uint8_t nbBits;
    };
    std::array<Cell, 1u << kMaxHufBits> cell{};
};

// Reads a Huffman tree description (the weights) and builds the table; returns the bytes used.
Result<std::size_t> read_huffman_tree(const std::uint8_t* p, std::size_t avail, const std::uint8_t* base,
                                      HufTable& table) {
    if (avail == 0) return block_error("zstd", "the Huffman table is missing", p - base);
    // 255 weights at most; the decoding loop below writes up to 3 per round, hence the slack.
    std::array<std::uint8_t, 260> weights{};
    unsigned count = 0;
    const unsigned header = p[0];
    std::size_t used;
    if (header >= 128) {
        count = header - 127;
        const std::size_t bytes = (count + 1) / 2;
        if (1 + bytes > avail) return block_error("zstd", "the Huffman weights are cut short", p - base);
        for (unsigned i = 0; i < count; ++i) {
            const unsigned b = p[1 + i / 2];
            weights[i] = static_cast<std::uint8_t>((i & 1) ? (b & 15) : (b >> 4));
        }
        used = 1 + bytes;
    } else {
        const std::size_t comp = header;
        if (comp == 0 || 1 + comp > avail) return block_error("zstd", "the Huffman weights are cut short", p - base);
        std::array<std::int16_t, 16> norm{};
        unsigned symbols = 0, log = 0;
        auto nc = read_ncount(p + 1, comp, base, norm.data(), 13, kMaxHufWeightLog, symbols, log);
        if (!nc) return nc.error();
        FseTable ft;
        if (!fse_build(ft, norm.data(), symbols, log))
            return block_error("zstd", "the Huffman weight table is invalid", p - base);
        BackBits bits;
        if (!bits.init(p + 1 + nc.value(), comp - nc.value()))
            return block_error("zstd", "the Huffman weight stream is empty or has no end mark", p - base);
        unsigned s1 = bits.read(log), s2 = bits.read(log);
        for (;;) {
            if (count > 255) return block_error("zstd", "more than 255 Huffman weights", p - base);
            weights[count++] = ft.cell[s1].symbol;
            s1 = ft.cell[s1].newState + bits.read(ft.cell[s1].nbBits);
            if (bits.remaining < 0) {
                weights[count++] = ft.cell[s2].symbol;
                break;
            }
            weights[count++] = ft.cell[s2].symbol;
            s2 = ft.cell[s2].newState + bits.read(ft.cell[s2].nbBits);
            if (bits.remaining < 0) {
                weights[count++] = ft.cell[s1].symbol;
                break;
            }
        }
        used = 1 + comp;
    }
    if (count > 255) return block_error("zstd", "more than 255 Huffman weights", p - base);
    // The last weight is implied: the weights add up to a power of two.
    std::uint64_t total = 0;
    for (unsigned i = 0; i < count; ++i) {
        if (weights[i] > kMaxHufBits) return block_error("zstd", "a Huffman weight is too large", p - base);
        if (weights[i]) total += 1ull << (weights[i] - 1);
    }
    if (total == 0) return block_error("zstd", "the Huffman weights are all zero", p - base);
    const unsigned maxBits = highbit64(total) + 1;
    if (maxBits > kMaxHufBits) return block_error("zstd", "a Huffman code is too long", p - base);
    const std::uint64_t rest = (1ull << maxBits) - total;
    if ((rest & (rest - 1)) != 0) return block_error("zstd", "the Huffman weights do not complete a code", p - base);
    weights[count++] = static_cast<std::uint8_t>(highbit64(rest) + 1);
    // Cells are laid out by increasing weight (longest codes first), then by symbol.
    std::array<std::uint32_t, kMaxHufBits + 2> rankStart{};
    for (unsigned i = 0; i < count; ++i)
        if (weights[i]) rankStart[weights[i]] += 1u << (weights[i] - 1);
    std::uint32_t pos = 0;
    for (unsigned w = 1; w <= maxBits; ++w) {
        const std::uint32_t n = rankStart[w];
        rankStart[w] = pos;
        pos += n;
    }
    for (unsigned i = 0; i < count; ++i) {
        const unsigned w = weights[i];
        if (!w) continue;
        const std::uint32_t n = 1u << (w - 1);
        const std::uint8_t nb = static_cast<std::uint8_t>(maxBits + 1 - w);
        for (std::uint32_t k = 0; k < n; ++k) table.cell[rankStart[w] + k] = {static_cast<std::uint8_t>(i), nb};
        rankStart[w] += n;
    }
    table.maxBits = maxBits;
    return used;
}

// Decodes `count` symbols from one Huffman stream; the stream must be used up exactly.
bool huffman_stream(const HufTable& t, const std::uint8_t* src, std::size_t n, std::uint8_t* dst, std::size_t count) {
    BackBits bits;
    if (!bits.init(src, n)) return false;
    const unsigned mb = t.maxBits;
    for (std::size_t i = 0; i < count; ++i) {
        const HufTable::Cell c = t.cell[bits.peek(mb)];
        dst[i] = c.symbol;
        bits.skip(c.nbBits);
    }
    return bits.remaining == 0;
}

// ---- Frame decoding -------------------------------------------------------------------------------------------------

struct State {
    HufTable huf;
    bool hufValid = false;
    FseTable ll, of, ml;
    bool llValid = false, ofValid = false, mlValid = false;
    std::uint32_t rep[3] = {1, 4, 8};
    std::vector<std::uint8_t> literals;
};

class Decoder {
public:
    Decoder(std::span<const std::uint8_t> in, std::span<std::uint8_t> out) : in_(in), base_(in.data()), out_(out) {}

    Result<void> run(bool exact, std::size_t* written);

private:
    Error fail(const std::string& what, const std::uint8_t* at) const { return block_error("zstd", what, at - base_); }
    Result<void> frame(const std::uint8_t*& ip);
    Result<void> compressed_block(const std::uint8_t* src, std::size_t size, std::uint8_t* frameStart,
                                  std::size_t windowSize, std::size_t blockMax);
    Result<void> literals_section(const std::uint8_t*& ip, const std::uint8_t* end, std::size_t blockMax,
                                  const std::uint8_t*& lit, std::size_t& litSize);
    Result<void> sequences_section(const std::uint8_t* ip, const std::uint8_t* end, const std::uint8_t* lit,
                                   std::size_t litSize, std::uint8_t* frameStart, std::size_t windowSize,
                                   std::size_t blockMax);
    Result<void> sequence_table(int kind, unsigned mode, const std::uint8_t*& ip, const std::uint8_t* end);

    std::span<const std::uint8_t> in_;
    const std::uint8_t* base_;
    std::span<std::uint8_t> out_;
    std::uint8_t* op_ = nullptr;
    std::unique_ptr<State> st_;
};

Result<void> Decoder::literals_section(const std::uint8_t*& ip, const std::uint8_t* end, std::size_t blockMax,
                                       const std::uint8_t*& lit, std::size_t& litSize) {
    if (ip >= end) return fail("the literals section is missing", ip);
    const std::uint32_t b0 = ip[0];
    const unsigned type = b0 & 3;
    const unsigned sizeFormat = (b0 >> 2) & 3;
    State& st = *st_;
    if (type <= 1) {  // raw or RLE: the size is in 5, 12 or 20 bits
        std::size_t headerSize;
        std::uint32_t regen;
        if ((sizeFormat & 1) == 0) {
            headerSize = 1;
            regen = b0 >> 3;
        } else if (sizeFormat == 1) {
            headerSize = 2;
            if (end - ip < 2) return fail("the literals header is cut short", ip);
            regen = (b0 >> 4) | (static_cast<std::uint32_t>(ip[1]) << 4);
        } else {
            headerSize = 3;
            if (end - ip < 3) return fail("the literals header is cut short", ip);
            regen = (b0 >> 4) | (static_cast<std::uint32_t>(ip[1]) << 4) | (static_cast<std::uint32_t>(ip[2]) << 12);
        }
        if (regen > blockMax) return fail("the literals are larger than a block can be", ip);
        ip += headerSize;
        if (type == 0) {
            if (static_cast<std::size_t>(end - ip) < regen) return fail("the raw literals are cut short", ip);
            lit = ip;
            litSize = regen;
            ip += regen;
        } else {
            if (ip >= end) return fail("the RLE literal is missing", ip);
            st.literals.assign(regen, *ip);
            lit = st.literals.data();
            litSize = regen;
            ++ip;
        }
        return {};
    }
    // Huffman-compressed (2) or reusing the previous table (3): sizes in 10, 14 or 18 bits.
    std::size_t headerSize;
    unsigned streams, sizeBits;
    if (sizeFormat <= 1) {
        headerSize = 3;
        streams = sizeFormat == 0 ? 1 : 4;
        sizeBits = 10;
    } else if (sizeFormat == 2) {
        headerSize = 4;
        streams = 4;
        sizeBits = 14;
    } else {
        headerSize = 5;
        streams = 4;
        sizeBits = 18;
    }
    if (static_cast<std::size_t>(end - ip) < headerSize) return fail("the literals header is cut short", ip);
    std::uint64_t h = 0;
    for (std::size_t i = 0; i < headerSize; ++i) h |= static_cast<std::uint64_t>(ip[i]) << (8 * i);
    const std::uint64_t sizeMask = (1ull << sizeBits) - 1;
    const std::size_t regen = static_cast<std::size_t>((h >> 4) & sizeMask);
    const std::size_t comp = static_cast<std::size_t>((h >> (4 + sizeBits)) & sizeMask);
    if (regen > blockMax) return fail("the literals are larger than a block can be", ip);
    ip += headerSize;
    if (comp > static_cast<std::size_t>(end - ip)) return fail("the compressed literals are cut short", ip);
    const std::uint8_t* const litEnd = ip + comp;
    if (type == 2) {
        auto used = read_huffman_tree(ip, comp, base_, st.huf);
        if (!used) return used.error();
        ip += used.value();
        st.hufValid = true;
    } else if (!st.hufValid) {
        return fail("the literals reuse a Huffman table that no earlier block defined", ip);
    }
    st.literals.resize(regen);
    std::uint8_t* const dst = st.literals.data();
    const std::size_t streamBytes = static_cast<std::size_t>(litEnd - ip);
    if (streams == 1) {
        if (!huffman_stream(st.huf, ip, streamBytes, dst, regen))
            return fail("the Huffman literal stream is damaged", ip);
    } else {
        if (streamBytes < 6 + 3) return fail("the Huffman jump table is cut short", ip);
        const std::size_t s1 = load16(ip), s2 = load16(ip + 2), s3 = load16(ip + 4);
        const std::size_t head = 6;
        if (s1 + s2 + s3 + head >= streamBytes) return fail("the Huffman stream sizes do not fit", ip);
        const std::size_t s4 = streamBytes - head - s1 - s2 - s3;
        const std::size_t seg = (regen + 3) / 4;
        if (3 * seg > regen) return fail("too few literals for four Huffman streams", ip);
        const std::uint8_t* s = ip + head;
        if (!huffman_stream(st.huf, s, s1, dst, seg) || !huffman_stream(st.huf, s + s1, s2, dst + seg, seg) ||
            !huffman_stream(st.huf, s + s1 + s2, s3, dst + 2 * seg, seg) ||
            !huffman_stream(st.huf, s + s1 + s2 + s3, s4, dst + 3 * seg, regen - 3 * seg))
            return fail("a Huffman literal stream is damaged", ip);
    }
    lit = dst;
    litSize = regen;
    ip = litEnd;
    return {};
}

// Sets up the table of one sequence field from its coding mode: 0 predefined, 1 RLE, 2 FSE-compressed, 3 repeat.
// kind: 0 literal lengths, 1 offsets, 2 match lengths.
Result<void> Decoder::sequence_table(int kind, unsigned mode, const std::uint8_t*& ip, const std::uint8_t* end) {
    State& st = *st_;
    FseTable& t = kind == 0 ? st.ll : kind == 1 ? st.of : st.ml;
    bool& valid = kind == 0 ? st.llValid : kind == 1 ? st.ofValid : st.mlValid;
    const unsigned maxSymbol = kind == 0 ? kMaxLlSymbol : kind == 1 ? kMaxOfSymbol : kMaxMlSymbol;
    const unsigned maxLog = kind == 0 ? kMaxLlLog : kind == 1 ? kMaxOfLog : kMaxMlLog;
    const char* const name = kind == 0 ? "literal length" : kind == 1 ? "offset" : "match length";
    switch (mode) {
        case 0: {
            const std::int16_t* norm = kind == 0 ? kLlDefaultNorm : kind == 1 ? kOfDefaultNorm : kMlDefaultNorm;
            const unsigned symbols = kind == 0 ? 36 : kind == 1 ? 29 : 53;
            const unsigned log = kind == 0 ? kLlDefaultLog : kind == 1 ? kOfDefaultLog : kMlDefaultLog;
            if (!fse_build(t, norm, symbols, log)) return fail("internal error in a default table", ip);
            break;
        }
        case 1:
            if (ip >= end) return fail(std::string("the ") + name + " symbol is missing", ip);
            if (*ip > maxSymbol) return fail(std::string("the ") + name + " symbol is out of range", ip);
            fse_rle(t, *ip);
            ++ip;
            break;
        case 2: {
            std::array<std::int16_t, 64> norm{};
            unsigned symbols = 0, log = 0;
            auto used = read_ncount(ip, static_cast<std::size_t>(end - ip), base_, norm.data(), maxSymbol + 1, maxLog,
                                    symbols, log);
            if (!used) return used.error();
            if (!fse_build(t, norm.data(), symbols, log))
                return fail(std::string("the ") + name + " table is invalid", ip);
            ip += used.value();
            break;
        }
        default:
            if (!valid) return fail(std::string("the ") + name + " table repeats one no earlier block defined", ip);
            return {};
    }
    valid = true;
    return {};
}

Result<void> Decoder::sequences_section(const std::uint8_t* ip, const std::uint8_t* end, const std::uint8_t* lit,
                                        std::size_t litSize, std::uint8_t* frameStart, std::size_t windowSize,
                                        std::size_t blockMax) {
    State& st = *st_;
    const std::uint8_t* const litEnd = lit + litSize;
    std::uint8_t* const blockStart = op_;
    if (ip >= end) return fail("the sequences section is missing", ip);
    std::size_t nbSeq = *ip++;
    if (nbSeq >= 128) {
        if (nbSeq == 255) {
            if (end - ip < 2) return fail("the sequence count is cut short", ip);
            nbSeq = static_cast<std::size_t>(load16(ip)) + 0x7F00;
            ip += 2;
        } else {
            if (ip >= end) return fail("the sequence count is cut short", ip);
            nbSeq = ((nbSeq - 128) << 8) + *ip++;
        }
    }
    std::uint8_t* const oend = out_.data() + out_.size();
    if (nbSeq == 0) {
        if (ip != end) return fail("bytes follow a block without sequences", ip);
        if (litSize > static_cast<std::size_t>(oend - op_)) return fail("the data is longer than expected", ip);
        if (litSize) std::memcpy(op_, lit, litSize);
        op_ += litSize;
        return {};
    }
    if (ip >= end) return fail("the sequence modes byte is missing", ip);
    const unsigned modes = *ip++;
    if (modes & 3) return fail("a reserved bit is set in the sequence modes", ip - 1);
    for (int kind = 0; kind < 3; ++kind)
        if (auto r = sequence_table(kind, (modes >> (6 - 2 * kind)) & 3, ip, end); !r) return r;
    BackBits bits;
    if (!bits.init(ip, static_cast<std::size_t>(end - ip)))
        return fail("the sequence stream is empty or has no end mark", ip);
    unsigned sLL = bits.read(st.ll.log), sOF = bits.read(st.of.log), sML = bits.read(st.ml.log);
    for (std::size_t i = 0; i < nbSeq; ++i) {
        const FseCell cLL = st.ll.cell[sLL], cOF = st.of.cell[sOF], cML = st.ml.cell[sML];
        const unsigned ofCode = cOF.symbol;
        std::uint32_t offVal = (1u << ofCode) + bits.read(ofCode);
        const std::size_t mlVal = kMlBase[cML.symbol] + bits.read(kMlExtraBits[cML.symbol]);
        const std::size_t llVal = kLlBase[cLL.symbol] + bits.read(kLlExtraBits[cLL.symbol]);
        if (i + 1 < nbSeq) {
            sLL = cLL.newState + bits.read(cLL.nbBits);
            sML = cML.newState + bits.read(cML.nbBits);
            sOF = cOF.newState + bits.read(cOF.nbBits);
        }
        if (bits.remaining < 0) return fail("the sequence stream is cut short", ip);
        // Offset: values 1..3 name a repeat offset.
        std::uint32_t offset;
        if (offVal > 3) {
            offset = offVal - 3;
            st.rep[2] = st.rep[1];
            st.rep[1] = st.rep[0];
            st.rep[0] = offset;
        } else {
            const unsigned idx = offVal - 1 + (llVal == 0 ? 1u : 0u);  // 0..3
            if (idx == 0) {
                offset = st.rep[0];
            } else {
                offset = idx == 3 ? st.rep[0] - 1 : st.rep[idx];
                if (idx >= 2) st.rep[2] = st.rep[1];
                st.rep[1] = st.rep[0];
                st.rep[0] = offset;
            }
        }
        if (offset == 0) return fail("a match has offset 0", ip);
        // Execute: the literals, then the match.
        if (llVal > static_cast<std::size_t>(litEnd - lit))
            return fail("the sequences use more literals than exist", ip);
        if (llVal > static_cast<std::size_t>(oend - op_)) return fail("the data is longer than expected", ip);
        if (llVal) std::memcpy(op_, lit, llVal);
        op_ += llVal;
        lit += llVal;
        const std::size_t produced = static_cast<std::size_t>(op_ - frameStart);
        if (offset > produced) return fail("a match reaches before the start of the frame", ip);
        if (offset > windowSize) return fail("a match reaches beyond the window", ip);
        if (mlVal > static_cast<std::size_t>(oend - op_)) return fail("the data is longer than expected", ip);
        if (static_cast<std::size_t>(op_ - blockStart) + mlVal > blockMax)
            return fail("a block regenerates more than the block size limit", ip);
        const std::uint8_t* src = op_ - offset;
        std::size_t remaining = mlVal;
        if (offset == 1) {
            std::memset(op_, *src, remaining);
            op_ += remaining;
        } else {
            while (remaining) {
                const std::size_t chunk = std::min<std::size_t>(remaining, static_cast<std::size_t>(op_ - src));
                std::memcpy(op_, src, chunk);
                op_ += chunk;
                remaining -= chunk;
            }
        }
    }
    if (bits.remaining != 0) return fail("the sequence stream has bits left over", ip);
    const std::size_t last = static_cast<std::size_t>(litEnd - lit);
    if (last > static_cast<std::size_t>(oend - op_)) return fail("the data is longer than expected", ip);
    if (static_cast<std::size_t>(op_ - blockStart) + last > blockMax)
        return fail("a block regenerates more than the block size limit", ip);
    if (last) std::memcpy(op_, lit, last);
    op_ += last;
    return {};
}

Result<void> Decoder::compressed_block(const std::uint8_t* src, std::size_t size, std::uint8_t* frameStart,
                                       std::size_t windowSize, std::size_t blockMax) {
    const std::uint8_t* ip = src;
    const std::uint8_t* const end = src + size;
    const std::uint8_t* lit = nullptr;
    std::size_t litSize = 0;
    if (auto r = literals_section(ip, end, blockMax, lit, litSize); !r) return r;
    return sequences_section(ip, end, lit, litSize, frameStart, windowSize, blockMax);
}

Result<void> Decoder::frame(const std::uint8_t*& ip) {
    const std::uint8_t* const end = in_.data() + in_.size();
    const std::uint8_t* const frameBegin = ip;
    ip += 4;  // magic (checked by the caller)
    if (ip >= end) return fail("the frame header is cut short", ip);
    const unsigned fhd = *ip++;
    const unsigned fcsFlag = fhd >> 6;
    const bool single = (fhd & 0x20) != 0;
    const bool checksum = (fhd & 0x04) != 0;
    const unsigned dictFlag = fhd & 3;
    if (fhd & 0x08) return fail("a reserved bit is set in the frame header", ip - 1);
    std::uint64_t windowSize = 0;
    if (!single) {
        if (ip >= end) return fail("the frame header is cut short", ip);
        const unsigned wd = *ip++;
        const unsigned exponent = wd >> 3, mantissa = wd & 7;
        const std::uint64_t windowBase = 1ull << (10 + exponent);
        windowSize = windowBase + (windowBase / 8) * mantissa;
        if (windowSize > (1ull << kMaxWindowLog))
            return fail("the frame needs a window of " + std::to_string(windowSize) +
                            " bytes, more than the 128 MiB this engine accepts (game packs never need it)",
                        ip - 1);
    }
    const std::size_t dictBytes = dictFlag == 0 ? 0 : dictFlag == 1 ? 1 : dictFlag == 2 ? 2 : 4;
    if (static_cast<std::size_t>(end - ip) < dictBytes) return fail("the frame header is cut short", ip);
    std::uint32_t dictId = 0;
    for (std::size_t i = 0; i < dictBytes; ++i) dictId |= static_cast<std::uint32_t>(ip[i]) << (8 * i);
    if (dictId != 0)
        return fail("the frame needs dictionary " + std::to_string(dictId) + ", which this engine does not support",
                    ip);
    ip += dictBytes;
    std::size_t fcsBytes = fcsFlag == 0 ? (single ? 1 : 0) : fcsFlag == 1 ? 2 : fcsFlag == 2 ? 4 : 8;
    if (static_cast<std::size_t>(end - ip) < fcsBytes) return fail("the frame header is cut short", ip);
    bool hasSize = fcsBytes != 0;
    std::uint64_t contentSize = 0;
    for (std::size_t i = 0; i < fcsBytes; ++i) contentSize |= static_cast<std::uint64_t>(ip[i]) << (8 * i);
    if (fcsBytes == 2) contentSize += 256;
    ip += fcsBytes;
    if (single) windowSize = contentSize;
    const std::uint64_t room = static_cast<std::uint64_t>(out_.data() + out_.size() - op_);
    if (hasSize && contentSize > room)
        return fail("the frame holds " + std::to_string(contentSize) + " bytes but only " + std::to_string(room) +
                        " are expected",
                    frameBegin);

    std::uint8_t* const frameStart = op_;
    const std::size_t blockMax = static_cast<std::size_t>(std::min<std::uint64_t>(windowSize, kBlockMax));
    const std::size_t window = static_cast<std::size_t>(std::min<std::uint64_t>(windowSize, 1ull << kMaxWindowLog));
    State& st = *st_;
    st.hufValid = st.llValid = st.ofValid = st.mlValid = false;
    st.rep[0] = 1;
    st.rep[1] = 4;
    st.rep[2] = 8;
    bool last = false;
    while (!last) {
        if (end - ip < 3) return fail("the frame is cut short before its last block", ip);
        const std::uint32_t bh = static_cast<std::uint32_t>(ip[0]) | (static_cast<std::uint32_t>(ip[1]) << 8) |
                                 (static_cast<std::uint32_t>(ip[2]) << 16);
        ip += 3;
        last = (bh & 1) != 0;
        const unsigned type = (bh >> 1) & 3;
        const std::size_t size = bh >> 3;
        const std::size_t outRoom = static_cast<std::size_t>(out_.data() + out_.size() - op_);
        switch (type) {
            case 0:
                if (size > blockMax) return fail("a block is larger than the block size limit", ip - 3);
                if (static_cast<std::size_t>(end - ip) < size) return fail("a raw block is cut short", ip);
                if (size > outRoom) return fail("the data is longer than expected", ip);
                if (size) std::memcpy(op_, ip, size);
                op_ += size;
                ip += size;
                break;
            case 1:
                if (size > blockMax) return fail("a block is larger than the block size limit", ip - 3);
                if (ip >= end) return fail("an RLE block is cut short", ip);
                if (size > outRoom) return fail("the data is longer than expected", ip);
                if (size) std::memset(op_, *ip, size);
                op_ += size;
                ++ip;
                break;
            case 2: {
                if (size > blockMax || size == 0) return fail("a compressed block has an invalid size", ip - 3);
                if (static_cast<std::size_t>(end - ip) < size) return fail("a compressed block is cut short", ip);
                if (auto r = compressed_block(ip, size, frameStart, window, blockMax); !r) return r;
                ip += size;
                break;
            }
            default: return fail("a block has the reserved type", ip - 3);
        }
    }
    if (hasSize && static_cast<std::uint64_t>(op_ - frameStart) != contentSize)
        return fail("the frame holds " + std::to_string(op_ - frameStart) + " bytes but its header says " +
                        std::to_string(contentSize),
                    ip);
    if (checksum) {
        if (end - ip < 4) return fail("the content checksum is cut short", ip);
        const std::uint32_t want = load32(ip);
        const std::uint32_t got =
            static_cast<std::uint32_t>(xxh64(frameStart, static_cast<std::size_t>(op_ - frameStart)));
        if (want != got) return fail("the content checksum does not match: the data is damaged", ip);
        ip += 4;
    }
    return {};
}

Result<void> Decoder::run(bool exact, std::size_t* written) {
    op_ = out_.data();
    st_ = std::make_unique<State>();
    const std::uint8_t* ip = in_.data();
    const std::uint8_t* const end = ip + in_.size();
    if (in_.empty()) return fail("the block is empty", ip);
    unsigned frames = 0;
    while (ip < end) {
        if (end - ip < 4) return fail("a frame magic number is cut short", ip);
        const std::uint32_t magic = load32(ip);
        if ((magic & kSkippableMask) == kSkippableMagic) {
            if (end - ip < 8) return fail("a skippable frame header is cut short", ip);
            const std::uint64_t n = load32(ip + 4);
            if (n > static_cast<std::uint64_t>(end - ip) - 8) return fail("a skippable frame is cut short", ip);
            ip += 8 + n;
            continue;
        }
        if (magic != kFrameMagic)
            return fail("this is not a Zstandard frame (bad magic number " + std::to_string(magic) + ")", ip);
        if (auto r = frame(ip); !r) return r;
        ++frames;
    }
    if (frames == 0) return fail("there is no Zstandard frame, only skippable ones", ip);
    if (written) *written = static_cast<std::size_t>(op_ - out_.data());
    if (exact && op_ != out_.data() + out_.size())
        return fail("the frames hold " + std::to_string(op_ - out_.data()) + " bytes but " +
                        std::to_string(out_.size()) + " were expected",
                    end);
    return {};
}

}  // namespace

Result<void> zstd_decompress(std::span<const std::uint8_t> block, std::span<std::uint8_t> out, bool exact,
                             std::size_t* written) {
    return Decoder(block, out).run(exact, written);
}

}  // namespace fa::codec
