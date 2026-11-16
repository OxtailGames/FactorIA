// SHA-256 based HMAC / HKDF, ChaCha20-Poly1305 (RFC 8439) and the sealed-blob format. See fa/core/crypto.h.
//
// Everything that touches a key is written to run in a time that depends on the lengths only: no branch or table index
// on a secret byte. Words are loaded and stored little-endian byte by byte, so the code is the same on any endianness
// and on any alignment, and no shift is by 32 or more.
#include "fa/core/crypto.h"

#include <algorithm>
#include <atomic>
#include <cstring>
#include <limits>

#include "crypto_internal.h"
#include "fa/core/hash.h"

namespace fa::crypto {

namespace {

inline std::uint32_t load_le32(const std::uint8_t* p) {
    return std::uint32_t(p[0]) | (std::uint32_t(p[1]) << 8) | (std::uint32_t(p[2]) << 16) | (std::uint32_t(p[3]) << 24);
}

inline void store_le32(std::uint8_t* p, std::uint32_t v) {
    p[0] = std::uint8_t(v);
    p[1] = std::uint8_t(v >> 8);
    p[2] = std::uint8_t(v >> 16);
    p[3] = std::uint8_t(v >> 24);
}

inline void store_le64(std::uint8_t* p, std::uint64_t v) {
    for (int i = 0; i < 8; ++i) p[i] = std::uint8_t(v >> (8 * i));
}

// Rotate left by n in 1..31 (never 0 or 32: that would shift by 32).
inline std::uint32_t rotl32(std::uint32_t x, unsigned n) { return (x << n) | (x >> (32 - n)); }

// Wipes a local when it goes out of scope, on every return path.
struct Scrub {
    void* p;
    std::size_t n;
    ~Scrub() { secure_zero(p, n); }
};
template <class T>
Scrub scrub(T& obj) {
    return Scrub{&obj, sizeof obj};
}

void sha_update(Sha256& h, ByteView data) {
    if (!data.empty()) h.update(data.data(), data.size());  // no null pointer into memcpy for an empty view
}

// ---- ChaCha20 (RFC 8439, section 2.3 and 2.4) ------------------------------------------------------------------------

inline void quarter_round(std::uint32_t& a, std::uint32_t& b, std::uint32_t& c, std::uint32_t& d) {
    a += b, d ^= a, d = rotl32(d, 16);
    c += d, b ^= c, b = rotl32(b, 12);
    a += b, d ^= a, d = rotl32(d, 8);
    c += d, b ^= c, b = rotl32(b, 7);
}

struct ChaChaState {
    std::uint32_t s[16];
    ChaChaState(const Key& key, const Nonce& nonce, std::uint32_t counter) {
        s[0] = 0x61707865, s[1] = 0x3320646e, s[2] = 0x79622d32, s[3] = 0x6b206574;  // "expand 32-byte k"
        for (std::size_t i = 0; i < 8; ++i) s[4 + i] = load_le32(key.data() + 4 * i);
        s[12] = counter;
        for (std::size_t i = 0; i < 3; ++i) s[13 + i] = load_le32(nonce.data() + 4 * i);
    }
    ~ChaChaState() { secure_zero(s, sizeof s); }
};

// The 64-byte key stream block for the state's current counter.
void chacha_block(const ChaChaState& st, std::uint8_t out[64]) {
    std::uint32_t x[16];
    std::memcpy(x, st.s, sizeof x);
    for (int i = 0; i < 10; ++i) {
        quarter_round(x[0], x[4], x[8], x[12]);
        quarter_round(x[1], x[5], x[9], x[13]);
        quarter_round(x[2], x[6], x[10], x[14]);
        quarter_round(x[3], x[7], x[11], x[15]);
        quarter_round(x[0], x[5], x[10], x[15]);
        quarter_round(x[1], x[6], x[11], x[12]);
        quarter_round(x[2], x[7], x[8], x[13]);
        quarter_round(x[3], x[4], x[9], x[14]);
    }
    for (std::size_t i = 0; i < 16; ++i) store_le32(out + 4 * i, x[i] + st.s[i]);
    secure_zero(x, sizeof x);
}

// out = in XOR key stream, starting at block `counter`. `in` and `out` may be the same buffer.
void chacha_xor(const Key& key, const Nonce& nonce, std::uint32_t counter, const std::uint8_t* in, std::uint8_t* out,
                std::size_t size) {
    ChaChaState st(key, nonce, counter);
    std::uint8_t block[64];
    const auto wipe = scrub(block);
    while (size > 0) {
        chacha_block(st, block);
        const std::size_t n = std::min<std::size_t>(size, 64);
        for (std::size_t i = 0; i < n; ++i) out[i] = std::uint8_t(in[i] ^ block[i]);
        in += n, out += n, size -= n;
        ++st.s[12];  // the caller's size limit keeps the 32-bit counter from wrapping
    }
}

// ---- Poly1305 (RFC 8439, section 2.5): 26-bit limbs, 32x32 -> 64 bit products, no secret-dependent branch ----------------

class Poly1305 {
public:
    explicit Poly1305(const std::uint8_t key[32]) {
        const std::uint32_t t0 = load_le32(key), t1 = load_le32(key + 4), t2 = load_le32(key + 8),
                            t3 = load_le32(key + 12);
        r_[0] = t0 & 0x3ffffff;
        r_[1] = ((t0 >> 26) | (t1 << 6)) & 0x3ffff03;
        r_[2] = ((t1 >> 20) | (t2 << 12)) & 0x3ffc0ff;
        r_[3] = ((t2 >> 14) | (t3 << 18)) & 0x3f03fff;
        r_[4] = (t3 >> 8) & 0x00fffff;
        for (std::size_t i = 0; i < 4; ++i) pad_[i] = load_le32(key + 16 + 4 * i);
    }
    ~Poly1305() { secure_zero(this, sizeof *this); }

    void update(const std::uint8_t* m, std::size_t size) {
        if (size == 0) return;
        if (leftover_ > 0) {
            const std::size_t take = std::min(size, std::size_t(16) - leftover_);
            std::memcpy(buf_ + leftover_, m, take);
            leftover_ += take, m += take, size -= take;
            if (leftover_ < 16) return;
            blocks(buf_, 16, false);
            leftover_ = 0;
        }
        if (size >= 16) {
            const std::size_t whole = size & ~std::size_t(15);
            blocks(m, whole, false);
            m += whole, size -= whole;
        }
        if (size > 0) std::memcpy(buf_, m, size), leftover_ = size;
    }

    // Zero bytes up to the next multiple of 16 of `len` (the AEAD's padding).
    void pad16(std::uint64_t len) {
        static const std::uint8_t zeros[16] = {};
        const std::size_t rem = std::size_t(len % 16);
        if (rem != 0) update(zeros, 16 - rem);
    }

    void finish(std::uint8_t tag[16]) {
        if (leftover_ > 0) {
            buf_[leftover_] = 1;
            std::memset(buf_ + leftover_ + 1, 0, 16 - leftover_ - 1);
            blocks(buf_, 16, true);
        }
        constexpr std::uint32_t m = 0x3ffffff;
        std::uint32_t h0 = h_[0], h1 = h_[1], h2 = h_[2], h3 = h_[3], h4 = h_[4];
        std::uint32_t c = h1 >> 26;
        h1 &= m, h2 += c, c = h2 >> 26;
        h2 &= m, h3 += c, c = h3 >> 26;
        h3 &= m, h4 += c, c = h4 >> 26;
        h4 &= m, h0 += c * 5, c = h0 >> 26;
        h0 &= m, h1 += c;
        // g = h + 5 - 2^130: h >= p exactly when the subtraction does not borrow.
        std::uint32_t g0 = h0 + 5;
        c = g0 >> 26, g0 &= m;
        std::uint32_t g1 = h1 + c;
        c = g1 >> 26, g1 &= m;
        std::uint32_t g2 = h2 + c;
        c = g2 >> 26, g2 &= m;
        std::uint32_t g3 = h3 + c;
        c = g3 >> 26, g3 &= m;
        std::uint32_t g4 = h4 + c - (std::uint32_t(1) << 26);
        std::uint32_t mask = (g4 >> 31) - 1;  // all ones when h >= p (take g), zero otherwise (keep h)
        g0 &= mask, g1 &= mask, g2 &= mask, g3 &= mask, g4 &= mask;
        mask = ~mask;
        h0 = (h0 & mask) | g0, h1 = (h1 & mask) | g1, h2 = (h2 & mask) | g2, h3 = (h3 & mask) | g3,
        h4 = (h4 & mask) | g4;
        // h mod 2^128, then + pad
        const std::uint32_t w0 = h0 | (h1 << 26), w1 = (h1 >> 6) | (h2 << 20), w2 = (h2 >> 12) | (h3 << 14),
                            w3 = (h3 >> 18) | (h4 << 8);
        std::uint64_t f = std::uint64_t(w0) + pad_[0];
        store_le32(tag, std::uint32_t(f));
        f = std::uint64_t(w1) + pad_[1] + (f >> 32);
        store_le32(tag + 4, std::uint32_t(f));
        f = std::uint64_t(w2) + pad_[2] + (f >> 32);
        store_le32(tag + 8, std::uint32_t(f));
        f = std::uint64_t(w3) + pad_[3] + (f >> 32);
        store_le32(tag + 12, std::uint32_t(f));
    }

private:
    void blocks(const std::uint8_t* m, std::size_t size, bool last) {
        const std::uint32_t hibit = last ? 0 : (std::uint32_t(1) << 24);
        const std::uint32_t r0 = r_[0], r1 = r_[1], r2 = r_[2], r3 = r_[3], r4 = r_[4];
        const std::uint32_t s1 = r1 * 5, s2 = r2 * 5, s3 = r3 * 5, s4 = r4 * 5;
        std::uint32_t h0 = h_[0], h1 = h_[1], h2 = h_[2], h3 = h_[3], h4 = h_[4];
        for (; size >= 16; m += 16, size -= 16) {
            const std::uint32_t t0 = load_le32(m), t1 = load_le32(m + 4), t2 = load_le32(m + 8), t3 = load_le32(m + 12);
            h0 += t0 & 0x3ffffff;
            h1 += ((t0 >> 26) | (t1 << 6)) & 0x3ffffff;
            h2 += ((t1 >> 20) | (t2 << 12)) & 0x3ffffff;
            h3 += ((t2 >> 14) | (t3 << 18)) & 0x3ffffff;
            h4 += (t3 >> 8) | hibit;
            using u64 = std::uint64_t;
            u64 d0 = u64(h0) * r0 + u64(h1) * s4 + u64(h2) * s3 + u64(h3) * s2 + u64(h4) * s1;
            u64 d1 = u64(h0) * r1 + u64(h1) * r0 + u64(h2) * s4 + u64(h3) * s3 + u64(h4) * s2;
            u64 d2 = u64(h0) * r2 + u64(h1) * r1 + u64(h2) * r0 + u64(h3) * s4 + u64(h4) * s3;
            u64 d3 = u64(h0) * r3 + u64(h1) * r2 + u64(h2) * r1 + u64(h3) * r0 + u64(h4) * s4;
            u64 d4 = u64(h0) * r4 + u64(h1) * r3 + u64(h2) * r2 + u64(h3) * r1 + u64(h4) * r0;
            std::uint32_t c = std::uint32_t(d0 >> 26);
            h0 = std::uint32_t(d0) & 0x3ffffff;
            d1 += c, c = std::uint32_t(d1 >> 26);
            h1 = std::uint32_t(d1) & 0x3ffffff;
            d2 += c, c = std::uint32_t(d2 >> 26);
            h2 = std::uint32_t(d2) & 0x3ffffff;
            d3 += c, c = std::uint32_t(d3 >> 26);
            h3 = std::uint32_t(d3) & 0x3ffffff;
            d4 += c, c = std::uint32_t(d4 >> 26);
            h4 = std::uint32_t(d4) & 0x3ffffff;
            h0 += c * 5, c = h0 >> 26;
            h0 &= 0x3ffffff;
            h1 += c;
        }
        h_[0] = h0, h_[1] = h1, h_[2] = h2, h_[3] = h3, h_[4] = h4;
    }

    std::uint32_t r_[5];
    std::uint32_t h_[5] = {0, 0, 0, 0, 0};
    std::uint32_t pad_[4];
    std::uint8_t buf_[16] = {};
    std::size_t leftover_ = 0;
};

// ---- The AEAD, with the AAD in two pieces so a blob can authenticate its header and the caller's AAD ---------------------

// Poly1305 tag over aad1 || aad2 (padded), the ciphertext (padded) and both lengths, keyed by block 0 of the ChaCha20 stream.
void aead_tag(const Key& key, const Nonce& nonce, ByteView aad1, ByteView aad2, const std::uint8_t* ct, std::size_t ctSize,
              std::uint8_t tag[16]) {
    std::uint8_t block[64];
    const auto wipe = scrub(block);
    chacha_block(ChaChaState(key, nonce, 0), block);
    Poly1305 mac(block);  // the first 32 bytes are the one-time key
    const std::uint64_t aadSize = std::uint64_t(aad1.size()) + aad2.size();
    if (!aad1.empty()) mac.update(aad1.data(), aad1.size());
    if (!aad2.empty()) mac.update(aad2.data(), aad2.size());
    mac.pad16(aadSize);
    mac.update(ct, ctSize);
    mac.pad16(ctSize);
    std::uint8_t lens[16];
    store_le64(lens, aadSize);
    store_le64(lens + 8, ctSize);
    mac.update(lens, 16);
    mac.finish(tag);
}

// Writes ciphertext (n bytes) then the tag (16) to `out`.
void seal_into(const Key& key, const Nonce& nonce, ByteView aad1, ByteView aad2, ByteView plaintext, std::uint8_t* out) {
    if (!plaintext.empty()) chacha_xor(key, nonce, 1, plaintext.data(), out, plaintext.size());
    aead_tag(key, nonce, aad1, aad2, out, plaintext.size(), out + plaintext.size());
}

// Verifies the tag over `ct`, and only then decrypts into `out` (n bytes). False on a mismatch, with `out` untouched.
bool open_into(const Key& key, const Nonce& nonce, ByteView aad1, ByteView aad2, const std::uint8_t* ct, std::size_t n,
               const std::uint8_t* tag, std::uint8_t* out) {
    std::uint8_t expected[16];
    aead_tag(key, nonce, aad1, aad2, ct, n, expected);
    const bool same = constant_time_equal(ByteView(expected, 16), ByteView(tag, 16));
    if (!same) return false;
    if (n > 0) chacha_xor(key, nonce, 1, ct, out, n);
    return true;
}

Error too_large(std::uint64_t size) {
    return make_error("Cannot encrypt " + std::to_string(size) + " bytes in one message: the limit of ChaCha20-Poly1305 is " +
                          std::to_string(kMaxMessageSize) + " bytes.",
                      "Split the data into several sealed blobs.");
}

Error tag_mismatch(std::string_view what) {
    return make_error(std::string(what) + ": the data was changed or the key is wrong.",
                      "The file was edited, damaged or truncated, or it was sealed with another key (or another "
                      "associated-data value such as the slot name). Nothing was decrypted; restore a backup or start again.");
}

constexpr std::size_t kHeaderSize = 34;  // magic 4, version 1, reserved 1, salt 16, nonce 12
constexpr std::size_t kSaltSize = 16;
constexpr std::string_view kMagic = "FASB";
constexpr std::string_view kBlobKdfInfo = "factoria sealed blob v1";

// The key that seals one blob: HKDF over the caller's key and the blob's own salt, so a key never encrypts two blobs
// with the same derived key and the 96-bit random nonce collision limit of one key never applies.
Key blob_key(const Key& key, const std::uint8_t* salt) {
    auto okm = hkdf_sha256(ByteView(key), ByteView(salt, kSaltSize), as_bytes(kBlobKdfInfo), kKeySize);
    Key out;
    std::memcpy(out.data(), okm.value().data(), kKeySize);
    secure_zero(okm.value().data(), okm.value().size());
    return out;
}

}  // namespace

// ---- Internal (crypto_internal.h) ----------------------------------------------------------------------------------------

namespace detail {

void chacha20_block(const Key& key, std::uint32_t counter, const Nonce& nonce, std::uint8_t out[64]) {
    chacha_block(ChaChaState(key, nonce, counter), out);
}

void chacha20_xor(const Key& key, std::uint32_t counter, const Nonce& nonce, ByteView in, std::uint8_t* out) {
    if (!in.empty()) chacha_xor(key, nonce, counter, in.data(), out, in.size());
}

void poly1305_tag(const std::uint8_t key[32], ByteView msg, std::uint8_t tag[16]) {
    Poly1305 mac(key);
    if (!msg.empty()) mac.update(msg.data(), msg.size());
    mac.finish(tag);
}

}  // namespace detail

// ---- Public: helpers ---------------------------------------------------------------------------------------------------

void secure_zero(void* data, std::size_t size) {
    volatile std::uint8_t* p = static_cast<volatile std::uint8_t*>(data);
    for (std::size_t i = 0; i < size; ++i) p[i] = 0;
    std::atomic_signal_fence(std::memory_order_seq_cst);
}

bool constant_time_equal(ByteView a, ByteView b) {
    if (a.size() != b.size()) return false;  // lengths are not secret
    std::uint8_t diff = 0;
    for (std::size_t i = 0; i < a.size(); ++i) diff = std::uint8_t(diff | (a[i] ^ b[i]));
    return diff == 0;
}

// ---- Public: hashes ------------------------------------------------------------------------------------------------------

Digest sha256(ByteView data) {
    Sha256 h;
    sha_update(h, data);
    return h.finish();
}

Digest hmac_sha256(ByteView key, ByteView data) {
    std::uint8_t k[64] = {};
    if (key.size() > sizeof k) {
        Digest d = sha256(key);
        std::memcpy(k, d.data(), d.size());
        secure_zero(d);
    } else if (!key.empty()) {
        std::memcpy(k, key.data(), key.size());
    }
    std::uint8_t ipad[64], opad[64];
    for (std::size_t i = 0; i < 64; ++i) ipad[i] = std::uint8_t(k[i] ^ 0x36), opad[i] = std::uint8_t(k[i] ^ 0x5c);
    secure_zero(k, sizeof k);
    Sha256 inner;
    inner.update(ipad, sizeof ipad);
    sha_update(inner, data);
    Digest innerDigest = inner.finish();
    Sha256 outer;
    outer.update(opad, sizeof opad);
    outer.update(innerDigest.data(), innerDigest.size());
    Digest result = outer.finish();
    secure_zero(ipad, sizeof ipad);
    secure_zero(opad, sizeof opad);
    secure_zero(innerDigest);
    secure_zero(&inner, sizeof inner);
    secure_zero(&outer, sizeof outer);
    return result;
}

Result<Bytes> hkdf_sha256(ByteView ikm, ByteView salt, ByteView info, std::size_t length) {
    constexpr std::size_t kMax = 255 * kDigestSize;
    if (length > kMax)
        return make_error("HKDF-SHA256 cannot produce " + std::to_string(length) + " bytes: the limit is " +
                              std::to_string(kMax) + " (255 blocks of 32).",
                          "Ask for at most " + std::to_string(kMax) + " bytes, or derive several keys with different `info`.");
    const std::uint8_t zeros[kDigestSize] = {};
    Digest prk = hmac_sha256(salt.empty() ? ByteView(zeros, sizeof zeros) : salt, ikm);  // extract
    Bytes okm;
    okm.reserve(length);
    Bytes msg;
    msg.reserve(kDigestSize + info.size() + 1);
    Digest t = {};
    std::size_t tLen = 0;
    for (std::uint8_t counter = 1; okm.size() < length; ++counter) {  // expand
        msg.clear();
        msg.insert(msg.end(), t.begin(), t.begin() + std::ptrdiff_t(tLen));
        msg.insert(msg.end(), info.begin(), info.end());
        msg.push_back(counter);
        t = hmac_sha256(ByteView(prk), ByteView(msg));
        tLen = t.size();
        const std::size_t take = std::min(length - okm.size(), t.size());
        okm.insert(okm.end(), t.begin(), t.begin() + std::ptrdiff_t(take));
    }
    secure_zero(prk);
    secure_zero(t);
    secure_zero(msg.data(), msg.size());
    return okm;
}

Key key_from_secret(std::string_view secret, std::string_view context) {
    auto okm = hkdf_sha256(as_bytes(secret), as_bytes("factoria/crypto/key_from_secret/v1"), as_bytes(context), kKeySize);
    Key key;
    std::memcpy(key.data(), okm.value().data(), kKeySize);
    secure_zero(okm.value().data(), okm.value().size());
    return key;
}

// ---- Public: the AEAD ------------------------------------------------------------------------------------------------------

Result<Bytes> aead_seal(const Key& key, const Nonce& nonce, ByteView aad, ByteView plaintext) {
    if (std::uint64_t(plaintext.size()) > kMaxMessageSize) return too_large(plaintext.size());
    if (plaintext.size() > std::numeric_limits<std::size_t>::max() - kTagSize) return too_large(plaintext.size());
    Bytes out(plaintext.size() + kTagSize);
    seal_into(key, nonce, aad, ByteView(), plaintext, out.data());
    return out;
}

Result<Bytes> aead_open(const Key& key, const Nonce& nonce, ByteView aad, ByteView sealed) {
    if (sealed.size() < kTagSize)
        return make_error("Cannot decrypt " + std::to_string(sealed.size()) + " bytes: the data is shorter than the " +
                              std::to_string(kTagSize) + "-byte authentication tag.",
                          "The data was truncated, or it was not made by aead_seal.");
    const std::size_t n = sealed.size() - kTagSize;
    if (std::uint64_t(n) > kMaxMessageSize) return too_large(n);
    Bytes out(n);
    if (!open_into(key, nonce, aad, ByteView(), sealed.data(), n, sealed.data() + n, out.data()))
        return tag_mismatch("Authentication failed");
    return out;
}

// ---- Public: sealed blobs ---------------------------------------------------------------------------------------------------

bool is_sealed_blob(std::string_view blob) { return blob.size() >= kMagic.size() && blob.substr(0, kMagic.size()) == kMagic; }

Result<std::string> seal_blob(const Key& key, ByteView aad, ByteView data) {
    if (std::uint64_t(data.size()) > kMaxMessageSize || data.size() > std::numeric_limits<std::size_t>::max() - kBlobOverhead)
        return too_large(data.size());
    std::string blob(kBlobOverhead + data.size(), '\0');
    auto* out = reinterpret_cast<std::uint8_t*>(blob.data());
    std::memcpy(out, kMagic.data(), kMagic.size());
    out[4] = kBlobVersion;
    out[5] = 0;
    if (auto r = random_bytes(std::span<std::uint8_t>(out + 6, kSaltSize + kNonceSize)); !r)
        return make_error("Cannot seal the data: " + r.error().message, r.error().hint);
    Nonce nonce;
    std::memcpy(nonce.data(), out + 6 + kSaltSize, kNonceSize);
    Key sub = blob_key(key, out + 6);
    const auto wipe = scrub(sub);
    seal_into(sub, nonce, ByteView(out, kHeaderSize), aad, data, out + kHeaderSize);
    return blob;
}

Result<std::string> open_blob(const Key& key, ByteView aad, std::string_view blob) {
    if (!is_sealed_blob(blob))
        return make_error("This is not a sealed file: it does not start with the \"FASB\" marker.",
                          "A plain file (a save made before encryption was turned on) is read as it is; check with "
                          "is_sealed_blob first.");
    if (blob.size() < kBlobOverhead)
        return make_error("The sealed file is truncated: " + std::to_string(blob.size()) + " bytes, a sealed file has at least " +
                              std::to_string(kBlobOverhead) + ".",
                          "Restore a backup or start again.");
    const auto* in = reinterpret_cast<const std::uint8_t*>(blob.data());
    if (in[4] != kBlobVersion)
        return make_error("The sealed file has format version " + std::to_string(in[4]) + ", this engine reads version " +
                              std::to_string(kBlobVersion) + ".",
                          "It was written by a newer version of the engine: update the game.");
    const std::size_t n = blob.size() - kBlobOverhead;
    if (std::uint64_t(n) > kMaxMessageSize) return too_large(n);
    Nonce nonce;
    std::memcpy(nonce.data(), in + 6 + kSaltSize, kNonceSize);
    Key sub = blob_key(key, in + 6);
    const auto wipe = scrub(sub);
    std::string out(n, '\0');
    if (!open_into(sub, nonce, ByteView(in, kHeaderSize), aad, in + kHeaderSize, n, in + kHeaderSize + n,
                   reinterpret_cast<std::uint8_t*>(out.data())))
        return tag_mismatch("The sealed file failed authentication");
    return out;
}

}  // namespace fa::crypto
