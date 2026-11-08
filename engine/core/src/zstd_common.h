// Tables and structures shared by the Zstandard decoder and encoder (RFC 8878).
#pragma once

#include <cstddef>
#include <cstdint>

namespace fa::codec::zstd {

inline constexpr std::uint32_t kFrameMagic = 0xFD2FB528u;
inline constexpr std::uint32_t kSkippableMask = 0xFFFFFFF0u;
inline constexpr std::uint32_t kSkippableMagic = 0x184D2A50u;
inline constexpr std::size_t kBlockMax = 128 * 1024;
// Windows over 128 MiB (the limit the reference decoder accepts by default) are refused: a pack block is a few MiB.
inline constexpr unsigned kMaxWindowLog = 27;

inline constexpr unsigned kMaxLlSymbol = 35;
inline constexpr unsigned kMaxMlSymbol = 52;
inline constexpr unsigned kMaxOfSymbol = 31;
inline constexpr unsigned kMaxLlLog = 9;
inline constexpr unsigned kMaxMlLog = 9;
inline constexpr unsigned kMaxOfLog = 8;
inline constexpr unsigned kMaxHufWeightLog = 6;  // accuracy of the FSE table that codes Huffman weights
inline constexpr unsigned kMaxHufBits = 12;      // longest Huffman code the decoder accepts (the encoder uses 11)

inline constexpr std::uint8_t kLlExtraBits[36] = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,  0,  0,  0,  1,  1,
                                                  1, 1, 2, 2, 3, 3, 4, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16};
inline constexpr std::uint32_t kLlBase[36] = {0,  1,  2,  3,  4,  5,  6,  7,   8,   9,    10,   11,
                                              12, 13, 14, 15, 16, 18, 20, 22,  24,  28,   32,   40,
                                              48, 64, 128, 256, 512, 1024, 2048, 4096, 8192, 16384, 32768, 65536};
inline constexpr std::uint8_t kMlExtraBits[53] = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                                                  0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 3, 3, 4, 4, 5, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16};
inline constexpr std::uint32_t kMlBase[53] = {3,  4,  5,  6,  7,  8,  9,  10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20,
                                              21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 37, 39, 41,
                                              43, 47, 51, 59, 67, 83, 99, 131, 259, 515, 1027, 2051, 4099, 8195, 16387, 32771, 65539};

// Default distributions (RFC 8878, 3.1.1.3.2.2): -1 is a "less than 1" probability.
inline constexpr std::int16_t kLlDefaultNorm[36] = {4, 3, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1, 1, 1, 2, 2,
                                                    2, 2, 2, 2, 2, 2, 2, 3, 2, 1, 1, 1, 1, 1, -1, -1, -1, -1};
inline constexpr unsigned kLlDefaultLog = 6;
inline constexpr std::int16_t kMlDefaultNorm[53] = {1, 4, 3, 2, 2, 2, 2, 2, 2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
                                                    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, -1, -1, -1, -1, -1, -1, -1};
inline constexpr unsigned kMlDefaultLog = 6;
inline constexpr std::int16_t kOfDefaultNorm[29] = {1, 1, 1, 1, 1, 1, 2, 2, 2, 1, 1, 1, 1, 1, 1,
                                                    1, 1, 1, 1, 1, 1, 1, 1, 1, -1, -1, -1, -1, -1};
inline constexpr unsigned kOfDefaultLog = 5;

// One cell of an FSE decoding table.
struct FseCell {
    std::uint16_t newState;
    std::uint8_t symbol;
    std::uint8_t nbBits;
};

}  // namespace fa::codec::zstd
