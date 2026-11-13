// QR code encoder: see fa/tooling/qr.h. The structure follows the standard's own clauses (data codewords, error
// correction blocks and their interleaving, function patterns, zig-zag placement, masking by penalty score).
#include "fa/tooling/qr.h"

#include <algorithm>
#include <array>
#include <cstdlib>

namespace fa {

namespace {

constexpr int kMinVersion = 1, kMaxVersion = 40;

int ecc_index(QrEcc ecc) { return static_cast<int>(ecc); }

// ISO 18004 Table 9: error correction codewords per block, then the number of blocks, by [level][version] (index 0 unused).
constexpr std::int8_t kEccPerBlock[4][41] = {
    {-1, 7,  10, 15, 20, 26, 18, 20, 24, 30, 18, 20, 24, 26, 30, 22, 24, 28, 30, 28, 28,
     28, 28, 30, 30, 26, 28, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30},
    {-1, 10, 16, 26, 18, 24, 16, 18, 22, 22, 26, 30, 22, 22, 24, 24, 28, 28, 26, 26, 26,
     26, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28},
    {-1, 13, 22, 18, 26, 18, 24, 18, 22, 20, 24, 28, 26, 24, 20, 30, 24, 28, 28, 26, 30,
     28, 30, 30, 30, 30, 28, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30},
    {-1, 17, 28, 22, 16, 22, 28, 26, 26, 24, 28, 24, 28, 22, 24, 24, 30, 28, 28, 26, 28,
     30, 24, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30},
};
constexpr std::int8_t kBlocks[4][41] = {
    {-1, 1, 1, 1,  1,  1,  2,  2,  2,  2,  4,  4,  4,  4,  4,  6,  6,  6,  6,  7, 8,
     8,  9, 9, 10, 12, 12, 12, 13, 14, 15, 16, 17, 18, 19, 19, 20, 21, 22, 24, 25},
    {-1, 1,  1,  1,  2,  2,  4,  4,  4,  5,  5,  5,  8,  9,  9,  10, 10, 11, 13, 14, 16,
     17, 17, 18, 20, 21, 23, 25, 26, 28, 29, 31, 33, 35, 37, 38, 40, 43, 45, 47, 49},
    {-1, 1,  1,  2,  2,  4,  4,  6,  6,  8,  8,  8,  10, 12, 16, 12, 17, 16, 18, 21, 20,
     23, 23, 25, 27, 29, 34, 34, 35, 38, 40, 43, 45, 48, 51, 53, 56, 59, 62, 65, 68},
    {-1, 1,  1,  2,  4,  4,  4,  5,  6,  8,  8,  11, 11, 16, 16, 18, 16, 19, 21, 25, 25,
     25, 34, 30, 32, 35, 37, 40, 42, 45, 48, 51, 54, 57, 60, 63, 66, 70, 74, 77, 81},
};

// The modules of version `version` that can hold data and error correction bits (all but the function patterns).
int raw_data_modules(int version) {
    int result = (16 * version + 128) * version + 64;
    if (version >= 2) {
        const int numAlign = version / 7 + 2;
        result -= (25 * numAlign - 10) * numAlign - 55;
        if (version >= 7) result -= 36;
    }
    return result;
}

int data_codewords(int version, QrEcc ecc) {
    const int e = ecc_index(ecc);
    return raw_data_modules(version) / 8 - kEccPerBlock[e][version] * kBlocks[e][version];
}

int length_bits(int version) { return version <= 9 ? 8 : 16; }  // character count indicator of byte mode

std::uint8_t gf_multiply(std::uint8_t x, std::uint8_t y) {
    int z = 0;
    for (int i = 7; i >= 0; --i) {
        z = (z << 1) ^ ((z >> 7) * 0x11D);
        z ^= ((y >> i) & 1) * x;
    }
    return static_cast<std::uint8_t>(z);
}

std::vector<std::uint8_t> rs_divisor(int degree) {
    std::vector<std::uint8_t> result(static_cast<std::size_t>(degree), 0);
    result.back() =
        1;  // the polynomial "x^0" of the product (x - r^0)(x - r^1)...(x - r^(degree-1)), highest power first
    std::uint8_t root = 1;
    for (int i = 0; i < degree; ++i) {
        for (std::size_t j = 0; j < result.size(); ++j) {
            result[j] = gf_multiply(result[j], root);
            if (j + 1 < result.size()) result[j] ^= result[j + 1];
        }
        root = gf_multiply(root, 0x02);
    }
    return result;
}

bool bit_of(std::uint32_t x, int i) { return ((x >> i) & 1) != 0; }

class Builder {
public:
    Builder(int version, QrEcc ecc)
        : version_(version), ecc_(ecc), size_(version * 4 + 17),
          modules_(static_cast<std::size_t>(size_) * static_cast<std::size_t>(size_), 0),
          isFunction_(modules_.size(), 0) {
        draw_function_patterns();
    }

    // `data`: the data codewords (padded); returns the finished symbol.
    QrCode build(const std::vector<std::uint8_t>& data) {
        draw_codewords(add_ecc_and_interleave(data));
        int bestMask = 0;
        long bestPenalty = -1;
        for (int mask = 0; mask < 8; ++mask) {
            apply_mask(mask);
            draw_format_bits(mask);
            const long penalty = penalty_score();
            if (bestPenalty < 0 || penalty < bestPenalty) {
                bestMask = mask;
                bestPenalty = penalty;
            }
            apply_mask(mask);  // XOR again: undo
        }
        apply_mask(bestMask);
        draw_format_bits(bestMask);
        QrCode q;
        q.version = version_;
        q.size = size_;
        q.mask = bestMask;
        q.ecc = ecc_;
        q.modules = std::move(modules_);
        return q;
    }

private:
    int version_;
    QrEcc ecc_;
    int size_;
    std::vector<std::uint8_t> modules_, isFunction_;

    std::size_t at(int x, int y) const {
        return static_cast<std::size_t>(y) * static_cast<std::size_t>(size_) + static_cast<std::size_t>(x);
    }
    bool module(int x, int y) const { return modules_[at(x, y)] != 0; }
    void set_function(int x, int y, bool dark) {
        modules_[at(x, y)] = dark ? 1 : 0;
        isFunction_[at(x, y)] = 1;
    }

    void draw_function_patterns() {
        for (int i = 0; i < size_; ++i) {  // timing patterns
            set_function(6, i, i % 2 == 0);
            set_function(i, 6, i % 2 == 0);
        }
        draw_finder(3, 3);
        draw_finder(size_ - 4, 3);
        draw_finder(3, size_ - 4);
        const std::vector<int> align = alignment_positions();
        const int n = static_cast<int>(align.size());
        for (int i = 0; i < n; ++i)
            for (int j = 0; j < n; ++j)
                if (!((i == 0 && j == 0) || (i == 0 && j == n - 1) || (i == n - 1 && j == 0)))
                    draw_alignment(align[static_cast<std::size_t>(i)], align[static_cast<std::size_t>(j)]);
        draw_format_bits(0);  // reserves the format area; the real mask is drawn last
        draw_version();
    }

    void draw_finder(int cx, int cy) {  // the 7x7 finder pattern with its light separator
        for (int dy = -4; dy <= 4; ++dy)
            for (int dx = -4; dx <= 4; ++dx) {
                const int dist = std::max(std::abs(dx), std::abs(dy));
                const int x = cx + dx, y = cy + dy;
                if (x >= 0 && x < size_ && y >= 0 && y < size_) set_function(x, y, dist != 2 && dist != 4);
            }
    }

    void draw_alignment(int cx, int cy) {
        for (int dy = -2; dy <= 2; ++dy)
            for (int dx = -2; dx <= 2; ++dx) set_function(cx + dx, cy + dy, std::max(std::abs(dx), std::abs(dy)) != 1);
    }

    std::vector<int> alignment_positions() const {
        if (version_ == 1) return {};
        const int numAlign = version_ / 7 + 2;
        const int step = version_ == 32 ? 26 : (version_ * 4 + numAlign * 2 + 1) / (numAlign * 2 - 2) * 2;
        std::vector<int> result{6};
        for (int pos = size_ - 7; static_cast<int>(result.size()) < numAlign; pos -= step)
            result.insert(result.begin() + 1, pos);
        return result;
    }

    void draw_format_bits(int mask) {
        const std::uint32_t bits = qr_format_bits(ecc_, mask);
        for (int i = 0; i <= 5; ++i) set_function(8, i, bit_of(bits, i));
        set_function(8, 7, bit_of(bits, 6));
        set_function(8, 8, bit_of(bits, 7));
        set_function(7, 8, bit_of(bits, 8));
        for (int i = 9; i < 15; ++i) set_function(14 - i, 8, bit_of(bits, i));
        for (int i = 0; i < 8; ++i) set_function(size_ - 1 - i, 8, bit_of(bits, i));
        for (int i = 8; i < 15; ++i) set_function(8, size_ - 15 + i, bit_of(bits, i));
        set_function(8, size_ - 8, true);  // the always-dark module
    }

    void draw_version() {
        if (version_ < 7) return;
        std::uint32_t rem = static_cast<std::uint32_t>(version_);
        for (int i = 0; i < 12; ++i) rem = (rem << 1) ^ ((rem >> 11) * 0x1F25);
        const std::uint32_t bits = static_cast<std::uint32_t>(version_) << 12 | rem;  // 18 bits
        for (int i = 0; i < 18; ++i) {
            const bool bit = bit_of(bits, i);
            const int a = size_ - 11 + i % 3, b = i / 3;
            set_function(a, b, bit);
            set_function(b, a, bit);
        }
    }

    std::vector<std::uint8_t> add_ecc_and_interleave(const std::vector<std::uint8_t>& data) const {
        const int e = ecc_index(ecc_);
        const int numBlocks = kBlocks[e][version_], blockEccLen = kEccPerBlock[e][version_];
        const int rawCodewords = raw_data_modules(version_) / 8;
        const int numShortBlocks = numBlocks - rawCodewords % numBlocks;
        const int shortBlockLen = rawCodewords / numBlocks;
        std::vector<std::vector<std::uint8_t>> blocks;
        std::size_t k = 0;
        for (int i = 0; i < numBlocks; ++i) {
            const std::size_t len =
                static_cast<std::size_t>(shortBlockLen - blockEccLen + (i < numShortBlocks ? 0 : 1));
            std::vector<std::uint8_t> block(data.begin() + static_cast<std::ptrdiff_t>(k),
                                            data.begin() + static_cast<std::ptrdiff_t>(k + len));
            k += len;
            const std::vector<std::uint8_t> ecc = qr_reed_solomon(block, blockEccLen);
            if (i < numShortBlocks) block.push_back(0);  // the slot the longer blocks use, skipped below
            block.insert(block.end(), ecc.begin(), ecc.end());
            blocks.push_back(std::move(block));
        }
        std::vector<std::uint8_t> result;
        result.reserve(static_cast<std::size_t>(rawCodewords));
        for (std::size_t i = 0; i < blocks[0].size(); ++i)
            for (std::size_t j = 0; j < blocks.size(); ++j)
                if (i != static_cast<std::size_t>(shortBlockLen - blockEccLen) ||
                    j >= static_cast<std::size_t>(numShortBlocks))
                    result.push_back(blocks[j][i]);
        return result;
    }

    void draw_codewords(const std::vector<std::uint8_t>& data) {
        std::size_t i = 0;                                     // bit index
        for (int right = size_ - 1; right >= 1; right -= 2) {  // pairs of columns, right to left
            if (right == 6) right = 5;                         // the vertical timing column is skipped
            for (int vert = 0; vert < size_; ++vert)
                for (int j = 0; j < 2; ++j) {
                    const int x = right - j;
                    const bool upward = ((right + 1) & 2) == 0;
                    const int y = upward ? size_ - 1 - vert : vert;
                    if (!isFunction_[at(x, y)] && i < data.size() * 8) {
                        modules_[at(x, y)] = bit_of(data[i >> 3], 7 - static_cast<int>(i & 7)) ? 1 : 0;
                        ++i;
                    }
                }
        }
    }

    void apply_mask(int mask) {
        for (int y = 0; y < size_; ++y)
            for (int x = 0; x < size_; ++x) {
                bool invert = false;
                switch (mask) {
                    case 0: invert = (x + y) % 2 == 0; break;
                    case 1: invert = y % 2 == 0; break;
                    case 2: invert = x % 3 == 0; break;
                    case 3: invert = (x + y) % 3 == 0; break;
                    case 4: invert = (x / 3 + y / 2) % 2 == 0; break;
                    case 5: invert = x * y % 2 + x * y % 3 == 0; break;
                    case 6: invert = (x * y % 2 + x * y % 3) % 2 == 0; break;
                    default: invert = ((x + y) % 2 + x * y % 3) % 2 == 0; break;
                }
                if (invert && !isFunction_[at(x, y)]) modules_[at(x, y)] ^= 1;
            }
    }

    // The four penalty rules of the standard (runs of five or more, 2x2 blocks, finder-like patterns, dark/light balance).
    long penalty_score() const {
        constexpr int kN1 = 3, kN2 = 3, kN3 = 40, kN4 = 10;
        long result = 0;
        for (int y = 0; y < size_; ++y) {
            bool runColor = false;
            int runX = 0;
            std::array<int, 7> history{};
            for (int x = 0; x < size_; ++x) {
                if (module(x, y) == runColor) {
                    ++runX;
                    if (runX == 5)
                        result += kN1;
                    else if (runX > 5)
                        ++result;
                } else {
                    history_add(runX, history);
                    if (!runColor) result += static_cast<long>(count_patterns(history)) * kN3;
                    runColor = module(x, y);
                    runX = 1;
                }
            }
            result += static_cast<long>(terminate_and_count(runColor, runX, history)) * kN3;
        }
        for (int x = 0; x < size_; ++x) {
            bool runColor = false;
            int runY = 0;
            std::array<int, 7> history{};
            for (int y = 0; y < size_; ++y) {
                if (module(x, y) == runColor) {
                    ++runY;
                    if (runY == 5)
                        result += kN1;
                    else if (runY > 5)
                        ++result;
                } else {
                    history_add(runY, history);
                    if (!runColor) result += static_cast<long>(count_patterns(history)) * kN3;
                    runColor = module(x, y);
                    runY = 1;
                }
            }
            result += static_cast<long>(terminate_and_count(runColor, runY, history)) * kN3;
        }
        for (int y = 0; y < size_ - 1; ++y)
            for (int x = 0; x < size_ - 1; ++x) {
                const bool c = module(x, y);
                if (c == module(x + 1, y) && c == module(x, y + 1) && c == module(x + 1, y + 1)) result += kN2;
            }
        long dark = 0;
        for (std::uint8_t m : modules_) dark += m;
        const long total = static_cast<long>(size_) * size_;
        const long k = (std::labs(dark * 20 - total * 10) + total - 1) / total - 1;
        result += k * kN4;
        return result;
    }

    int count_patterns(const std::array<int, 7>& h) const {
        const int n = h[1];
        const bool core = n > 0 && h[2] == n && h[3] == n * 3 && h[4] == n && h[5] == n;
        return (core && h[0] >= n * 4 && h[6] >= n ? 1 : 0) + (core && h[6] >= n * 4 && h[0] >= n ? 1 : 0);
    }
    int terminate_and_count(bool runColor, int runLength, std::array<int, 7>& h) const {
        if (runColor) {
            history_add(runLength, h);
            runLength = 0;
        }
        runLength += size_;  // the light border beyond the end
        history_add(runLength, h);
        return count_patterns(h);
    }
    void history_add(int runLength, std::array<int, 7>& h) const {
        if (h[0] == 0) runLength += size_;  // the light border before the start
        for (std::size_t i = h.size() - 1; i >= 1; --i) h[i] = h[i - 1];
        h[0] = runLength;
    }
};

}  // namespace

std::vector<std::string> QrCode::rows() const {
    std::vector<std::string> out;
    for (int y = 0; y < size; ++y) {
        std::string row;
        for (int x = 0; x < size; ++x) row += dark(x, y) ? '#' : '.';
        out.push_back(std::move(row));
    }
    return out;
}

int qr_capacity_bytes(int version, QrEcc ecc) {
    if (version < kMinVersion || version > kMaxVersion) return 0;
    const int bits = data_codewords(version, ecc) * 8 - 4 - length_bits(version);
    const int bytes = bits / 8;
    // The character count indicator holds at most 2^bits - 1 characters.
    return std::min(bytes, (1 << length_bits(version)) - 1);
}

std::vector<std::uint8_t> qr_reed_solomon(const std::vector<std::uint8_t>& data, int eccLength) {
    if (eccLength <= 0) return {};
    const std::vector<std::uint8_t> divisor = rs_divisor(eccLength);
    std::vector<std::uint8_t> result(static_cast<std::size_t>(eccLength), 0);
    for (std::uint8_t b : data) {
        const std::uint8_t factor = b ^ result[0];
        result.erase(result.begin());
        result.push_back(0);
        for (std::size_t i = 0; i < result.size(); ++i) result[i] ^= gf_multiply(divisor[i], factor);
    }
    return result;
}

std::uint32_t qr_format_bits(QrEcc ecc, int mask) {
    constexpr int kEccBits[4] = {1, 0, 3, 2};  // L, M, Q, H
    const std::uint32_t data = static_cast<std::uint32_t>(kEccBits[ecc_index(ecc)] << 3 | (mask & 7));
    std::uint32_t rem = data;
    for (int i = 0; i < 10; ++i) rem = (rem << 1) ^ ((rem >> 9) * 0x537);
    return (data << 10 | rem) ^ 0x5412;
}

Result<QrCode> qr_encode(std::string_view data, QrEcc ecc, int minVersion) {
    minVersion = std::clamp(minVersion, kMinVersion, kMaxVersion);
    int version = 0;
    for (int v = minVersion; v <= kMaxVersion; ++v)
        if (static_cast<std::size_t>(qr_capacity_bytes(v, ecc)) >= data.size()) {
            version = v;
            break;
        }
    if (version == 0) {
        static const char* const kLevels[4] = {"Low", "Medium", "Quartile", "High"};
        return make_error("qr: " + std::to_string(data.size()) +
                              " bytes do not fit in a QR code at error correction level " + kLevels[ecc_index(ecc)] +
                              " (the biggest symbol, version 40, holds " +
                              std::to_string(qr_capacity_bytes(kMaxVersion, ecc)) + " bytes)",
                          "encode something shorter, or a lower error correction level");
    }
    // Bit stream: mode 0100, the character count, the bytes, a terminator of up to four zero bits, zeros to a byte boundary,
    // then the pad bytes 0xEC and 0x11 alternately up to the capacity.
    std::vector<std::uint8_t> bits;  // one bit per element, until packed
    auto put = [&bits](std::uint32_t value, int count) {
        for (int i = count - 1; i >= 0; --i) bits.push_back(static_cast<std::uint8_t>((value >> i) & 1));
    };
    put(0x4, 4);
    put(static_cast<std::uint32_t>(data.size()), length_bits(version));
    for (char c : data) put(static_cast<unsigned char>(c), 8);
    const std::size_t capacityBits = static_cast<std::size_t>(data_codewords(version, ecc)) * 8;
    for (int i = 0; i < 4 && bits.size() < capacityBits; ++i) bits.push_back(0);
    while (bits.size() % 8 != 0) bits.push_back(0);
    std::vector<std::uint8_t> codewords(bits.size() / 8, 0);
    for (std::size_t i = 0; i < bits.size(); ++i)
        codewords[i >> 3] = static_cast<std::uint8_t>(codewords[i >> 3] | bits[i] << (7 - (i & 7)));
    for (std::uint8_t pad = 0xEC; codewords.size() < capacityBits / 8; pad = pad == 0xEC ? 0x11 : 0xEC)
        codewords.push_back(pad);
    return Builder(version, ecc).build(codewords);
}

}  // namespace fa
