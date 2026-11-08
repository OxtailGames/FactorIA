// XXH64 (xxHash, 64-bit), written for the engine from the public algorithm description. Zstandard frames end with
// the low 32 bits of the XXH64 (seed 0) of their content.
#include "compress_internal.h"

namespace fa::codec {

namespace {
constexpr std::uint64_t P1 = 0x9E3779B185EBCA87ull;
constexpr std::uint64_t P2 = 0xC2B2AE3D27D4EB4Full;
constexpr std::uint64_t P3 = 0x165667B19E3779F9ull;
constexpr std::uint64_t P4 = 0x85EBCA77C2B2AE63ull;
constexpr std::uint64_t P5 = 0x27D4EB2F165667C5ull;

inline std::uint64_t rotl64(std::uint64_t x, int r) { return (x << r) | (x >> (64 - r)); }
inline std::uint64_t round1(std::uint64_t acc, std::uint64_t input) {
    acc += input * P2;
    acc = rotl64(acc, 31);
    return acc * P1;
}
inline std::uint64_t merge(std::uint64_t acc, std::uint64_t val) {
    acc ^= round1(0, val);
    return acc * P1 + P4;
}
}  // namespace

std::uint64_t xxh64(const std::uint8_t* data, std::size_t size, std::uint64_t seed) {
    const std::uint8_t* p = data;
    const std::uint8_t* const end = data + size;
    std::uint64_t h;
    if (size >= 32) {
        std::uint64_t v1 = seed + P1 + P2, v2 = seed + P2, v3 = seed, v4 = seed - P1;
        const std::uint8_t* const limit = end - 32;
        do {
            v1 = round1(v1, load64(p));
            v2 = round1(v2, load64(p + 8));
            v3 = round1(v3, load64(p + 16));
            v4 = round1(v4, load64(p + 24));
            p += 32;
        } while (p <= limit);
        h = rotl64(v1, 1) + rotl64(v2, 7) + rotl64(v3, 12) + rotl64(v4, 18);
        h = merge(h, v1);
        h = merge(h, v2);
        h = merge(h, v3);
        h = merge(h, v4);
    } else {
        h = seed + P5;
    }
    h += static_cast<std::uint64_t>(size);
    while (end - p >= 8) {
        h ^= round1(0, load64(p));
        h = rotl64(h, 27) * P1 + P4;
        p += 8;
    }
    if (end - p >= 4) {
        h ^= static_cast<std::uint64_t>(load32(p)) * P1;
        h = rotl64(h, 23) * P2 + P3;
        p += 4;
    }
    while (p < end) {
        h ^= static_cast<std::uint64_t>(*p) * P5;
        h = rotl64(h, 11) * P1;
        ++p;
    }
    h ^= h >> 33;
    h *= P2;
    h ^= h >> 29;
    h *= P3;
    h ^= h >> 32;
    return h;
}

}  // namespace fa::codec
