#include "fa/core/hash.h"

#include <algorithm>
#include <cstring>
#include <fstream>

namespace fa {

namespace {

constexpr char kHex[] = "0123456789abcdef";

std::string to_hex(const std::uint8_t* bytes, std::size_t n) {
    std::string s;
    s.reserve(n * 2);
    for (std::size_t i = 0; i < n; ++i) {
        s += kHex[bytes[i] >> 4];
        s += kHex[bytes[i] & 15];
    }
    return s;
}

inline std::uint32_t rotr(std::uint32_t x, int n) { return (x >> n) | (x << (32 - n)); }
inline std::uint32_t rotl(std::uint32_t x, int n) { return (x << n) | (x >> (32 - n)); }

// Shared padding: 0x80, zeros up to 56 mod 64, then the bit length as a 64-bit big-endian number.
template <class Hasher>
void pad_and_finish(Hasher& h, std::uint64_t totalBytes) {
    const std::uint64_t bits = totalBytes * 8;
    std::uint8_t pad[72] = {0x80};
    const std::size_t padLen = (totalBytes % 64 < 56) ? 56 - totalBytes % 64 : 120 - totalBytes % 64;
    std::uint8_t len[8];
    for (int i = 0; i < 8; ++i) len[i] = std::uint8_t(bits >> (56 - 8 * i));
    h.update(pad, padLen);
    h.update(len, 8);
}

template <class Hasher>
Result<std::string> hash_file(const std::filesystem::path& path, Hasher h) {
    std::ifstream in(path, std::ios::binary);
    if (!in)
        return make_error("Cannot read " + path.string() + " to compute its checksum.",
                          "Check that the file exists and is readable.");
    std::array<char, 1 << 16> chunk;
    while (in) {
        in.read(chunk.data(), std::streamsize(chunk.size()));
        if (const std::streamsize got = in.gcount(); got > 0) h.update(chunk.data(), std::size_t(got));
    }
    if (!in.eof())
        return make_error("Reading " + path.string() + " failed halfway while computing its checksum.",
                          "Check the disk and try again.");
    return h.finish_hex();
}

}  // namespace

// ---- SHA-256 ----------------------------------------------------------------------------------------------

namespace {
constexpr std::uint32_t kK256[64] = {
    0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5, 0xd807aa98, 0x12835b01,
    0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174, 0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc,
    0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da, 0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147,
    0x06ca6351, 0x14292967, 0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
    0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070, 0x19a4c116, 0x1e376c08,
    0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3, 0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208,
    0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2};
}  // namespace

Sha256::Sha256() : h_{0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a, 0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19} {}

void Sha256::block(const std::uint8_t* p) {
    std::uint32_t w[64];
    for (int i = 0; i < 16; ++i)
        w[i] = (std::uint32_t(p[4 * i]) << 24) | (std::uint32_t(p[4 * i + 1]) << 16) | (std::uint32_t(p[4 * i + 2]) << 8) |
               std::uint32_t(p[4 * i + 3]);
    for (int i = 16; i < 64; ++i) {
        const std::uint32_t s0 = rotr(w[i - 15], 7) ^ rotr(w[i - 15], 18) ^ (w[i - 15] >> 3);
        const std::uint32_t s1 = rotr(w[i - 2], 17) ^ rotr(w[i - 2], 19) ^ (w[i - 2] >> 10);
        w[i] = w[i - 16] + s0 + w[i - 7] + s1;
    }
    std::uint32_t a = h_[0], b = h_[1], c = h_[2], d = h_[3], e = h_[4], f = h_[5], g = h_[6], h = h_[7];
    for (int i = 0; i < 64; ++i) {
        const std::uint32_t S1 = rotr(e, 6) ^ rotr(e, 11) ^ rotr(e, 25);
        const std::uint32_t ch = (e & f) ^ (~e & g);
        const std::uint32_t t1 = h + S1 + ch + kK256[i] + w[i];
        const std::uint32_t S0 = rotr(a, 2) ^ rotr(a, 13) ^ rotr(a, 22);
        const std::uint32_t maj = (a & b) ^ (a & c) ^ (b & c);
        const std::uint32_t t2 = S0 + maj;
        h = g, g = f, f = e, e = d + t1, d = c, c = b, b = a, a = t1 + t2;
    }
    h_[0] += a, h_[1] += b, h_[2] += c, h_[3] += d, h_[4] += e, h_[5] += f, h_[6] += g, h_[7] += h;
}

void Sha256::update(const void* data, std::size_t size) {
    const auto* p = static_cast<const std::uint8_t*>(data);
    total_ += size;
    if (bufLen_ > 0) {
        const std::size_t take = std::min(size, buf_.size() - bufLen_);
        std::memcpy(buf_.data() + bufLen_, p, take);
        bufLen_ += take, p += take, size -= take;
        if (bufLen_ < buf_.size()) return;
        block(buf_.data());
        bufLen_ = 0;
    }
    for (; size >= 64; p += 64, size -= 64) block(p);
    if (size > 0) std::memcpy(buf_.data(), p, size), bufLen_ = size;
}

std::string Sha256::finish_hex() {
    const std::uint64_t total = total_;
    pad_and_finish(*this, total);
    std::uint8_t out[32];
    for (int i = 0; i < 8; ++i)
        for (int j = 0; j < 4; ++j) out[4 * i + j] = std::uint8_t(h_[i] >> (24 - 8 * j));
    return to_hex(out, sizeof out);
}

// ---- SHA-1 ------------------------------------------------------------------------------------------------

Sha1::Sha1() : h_{0x67452301, 0xEFCDAB89, 0x98BADCFE, 0x10325476, 0xC3D2E1F0} {}

void Sha1::block(const std::uint8_t* p) {
    std::uint32_t w[80];
    for (int i = 0; i < 16; ++i)
        w[i] = (std::uint32_t(p[4 * i]) << 24) | (std::uint32_t(p[4 * i + 1]) << 16) | (std::uint32_t(p[4 * i + 2]) << 8) |
               std::uint32_t(p[4 * i + 3]);
    for (int i = 16; i < 80; ++i) w[i] = rotl(w[i - 3] ^ w[i - 8] ^ w[i - 14] ^ w[i - 16], 1);
    std::uint32_t a = h_[0], b = h_[1], c = h_[2], d = h_[3], e = h_[4];
    for (int i = 0; i < 80; ++i) {
        std::uint32_t f, k;
        if (i < 20) f = (b & c) | (~b & d), k = 0x5A827999;
        else if (i < 40) f = b ^ c ^ d, k = 0x6ED9EBA1;
        else if (i < 60) f = (b & c) | (b & d) | (c & d), k = 0x8F1BBCDC;
        else f = b ^ c ^ d, k = 0xCA62C1D6;
        const std::uint32_t t = rotl(a, 5) + f + e + k + w[i];
        e = d, d = c, c = rotl(b, 30), b = a, a = t;
    }
    h_[0] += a, h_[1] += b, h_[2] += c, h_[3] += d, h_[4] += e;
}

void Sha1::update(const void* data, std::size_t size) {
    const auto* p = static_cast<const std::uint8_t*>(data);
    total_ += size;
    if (bufLen_ > 0) {
        const std::size_t take = std::min(size, buf_.size() - bufLen_);
        std::memcpy(buf_.data() + bufLen_, p, take);
        bufLen_ += take, p += take, size -= take;
        if (bufLen_ < buf_.size()) return;
        block(buf_.data());
        bufLen_ = 0;
    }
    for (; size >= 64; p += 64, size -= 64) block(p);
    if (size > 0) std::memcpy(buf_.data(), p, size), bufLen_ = size;
}

std::string Sha1::finish_hex() {
    const std::uint64_t total = total_;
    pad_and_finish(*this, total);
    std::uint8_t out[20];
    for (int i = 0; i < 5; ++i)
        for (int j = 0; j < 4; ++j) out[4 * i + j] = std::uint8_t(h_[i] >> (24 - 8 * j));
    return to_hex(out, sizeof out);
}

// ---- convenience --------------------------------------------------------------------------------------------

std::string sha256_hex(const void* data, std::size_t size) {
    Sha256 h;
    h.update(data, size);
    return h.finish_hex();
}

std::string sha1_hex(const void* data, std::size_t size) {
    Sha1 h;
    h.update(data, size);
    return h.finish_hex();
}

Result<std::string> sha256_file_hex(const std::filesystem::path& path) { return hash_file(path, Sha256()); }
Result<std::string> sha1_file_hex(const std::filesystem::path& path) { return hash_file(path, Sha1()); }

}  // namespace fa
