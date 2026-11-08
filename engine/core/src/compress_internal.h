// Private header of the block codecs (compress_blocks.cpp, lz4_codec.cpp, zstd_decode.cpp, zstd_encode.cpp, xxh64.cpp).
// Everything here is pure: no global state, no floats in any decision, explicit little-endian loads and stores, and
// size arithmetic in 64 bits (the web build has a 32-bit size_t).
#pragma once

#include <bit>
#include <cstddef>
#include <cstdint>
#include <cstring>
#include <span>
#include <string>
#include <vector>

#include "fa/core/types.h"

namespace fa::codec {

// ---- Little-endian access (memcpy: no type punning, no alignment assumption) --------------------------------------

inline std::uint16_t load16(const std::uint8_t* p) {
    std::uint16_t v;
    std::memcpy(&v, p, 2);
    if constexpr (std::endian::native == std::endian::big) v = static_cast<std::uint16_t>((v >> 8) | (v << 8));
    return v;
}
inline std::uint32_t load32(const std::uint8_t* p) {
    std::uint32_t v;
    std::memcpy(&v, p, 4);
    if constexpr (std::endian::native == std::endian::big)
        v = (v >> 24) | ((v >> 8) & 0xFF00u) | ((v << 8) & 0xFF0000u) | (v << 24);
    return v;
}
inline std::uint64_t load64(const std::uint8_t* p) {
    std::uint64_t v;
    std::memcpy(&v, p, 8);
    if constexpr (std::endian::native == std::endian::big) {
        std::uint64_t r = 0;
        for (int i = 0; i < 8; ++i) r = (r << 8) | ((v >> (8 * i)) & 0xFF);
        v = r;
    }
    return v;
}
inline void store16(std::uint8_t* p, std::uint32_t v) {
    p[0] = static_cast<std::uint8_t>(v);
    p[1] = static_cast<std::uint8_t>(v >> 8);
}
inline void store32(std::uint8_t* p, std::uint32_t v) {
    for (int i = 0; i < 4; ++i) p[i] = static_cast<std::uint8_t>(v >> (8 * i));
}
inline void store64(std::uint8_t* p, std::uint64_t v) {
    for (int i = 0; i < 8; ++i) p[i] = static_cast<std::uint8_t>(v >> (8 * i));
}

// Index of the highest set bit of a non-zero value (floor(log2)).
inline unsigned highbit32(std::uint32_t v) { return 31u - static_cast<unsigned>(std::countl_zero(v)); }
inline unsigned highbit64(std::uint64_t v) { return 63u - static_cast<unsigned>(std::countl_zero(v)); }

// a + b, a * b with saturation at the largest size_t (the web build is wasm32).
inline std::size_t sat_size(std::uint64_t v) {
    return v > static_cast<std::uint64_t>(SIZE_MAX) ? SIZE_MAX : static_cast<std::size_t>(v);
}

// An error that names the codec, what is wrong and where (byte offset in the block).
Error block_error(const char* codec, const std::string& what, std::ptrdiff_t offset);

// Inputs over this size are refused by compress() (game.pak compresses in blocks of a few MiB).
inline constexpr std::uint64_t kMaxCompressInput = 1ull << 30;

// ---- XXH64 (seed 0), the content checksum of Zstandard frames ------------------------------------------------------
std::uint64_t xxh64(const std::uint8_t* data, std::size_t size, std::uint64_t seed = 0);

// ---- LZ4 block format ---------------------------------------------------------------------------------------------
std::size_t lz4_compress_bound(std::size_t size);
// level 1..12 (already clamped). The output is appended to `out`.
void lz4_compress(std::span<const std::uint8_t> input, int level, std::vector<std::uint8_t>& out);
// Decodes exactly out.size() bytes.
Result<void> lz4_decompress(std::span<const std::uint8_t> block, std::span<std::uint8_t> out);

// ---- Zstandard frame format ---------------------------------------------------------------------------------------
std::size_t zstd_compress_bound(std::size_t size);
// level 1..19 (already clamped). `checksum` appends the XXH64 content checksum (the engine's packs do not use it).
void zstd_compress(std::span<const std::uint8_t> input, int level, bool checksum, std::vector<std::uint8_t>& out);
// Decodes all the frames of `block` (skippable frames are skipped) into `out`. With `exact` the frames must fill
// out.size() bytes exactly; without it they may produce less (written gets the count) but never more.
Result<void> zstd_decompress(std::span<const std::uint8_t> block, std::span<std::uint8_t> out, bool exact,
                             std::size_t* written = nullptr);
// The content size recorded in the header of the first frame (not skippable): false when unknown or not a frame.
bool zstd_frame_content_size(std::span<const std::uint8_t> block, std::uint64_t& size);

}  // namespace fa::codec
