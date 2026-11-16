// fa/core/crypto.h: SHA-256, HMAC (RFC 4231), HKDF (RFC 5869), ChaCha20 / Poly1305 / the AEAD (RFC 8439) against the RFC
// vectors, the sealed-blob file format, tamper detection and the helpers.
#include <doctest.h>

#include <algorithm>
#include <cstdint>
#include <string>
#include <vector>

#include "../src/crypto_internal.h"
#include "fa/core/crypto.h"

using namespace fa;
using namespace fa::crypto;

namespace {

Bytes unhex(std::string_view hex) {
    Bytes out;
    int hi = -1;
    for (const char c : hex) {
        int v;
        if (c >= '0' && c <= '9')
            v = c - '0';
        else if (c >= 'a' && c <= 'f')
            v = c - 'a' + 10;
        else if (c >= 'A' && c <= 'F')
            v = c - 'A' + 10;
        else
            continue;  // spaces, colons
        if (hi < 0)
            hi = v;
        else
            out.push_back(std::uint8_t(hi * 16 + v)), hi = -1;
    }
    return out;
}

std::string hex(ByteView b) {
    static const char* d = "0123456789abcdef";
    std::string s;
    for (const std::uint8_t x : b) s += d[x >> 4], s += d[x & 15];
    return s;
}

Bytes repeat(std::uint8_t v, std::size_t n) { return Bytes(n, v); }
Bytes text(std::string_view s) { return Bytes(s.begin(), s.end()); }

Nonce nonce_of(const Bytes& b) {
    REQUIRE(b.size() == kNonceSize);
    Nonce n;
    std::copy(b.begin(), b.end(), n.begin());
    return n;
}
Key counting_key(std::uint8_t first) {
    Key k;
    for (std::size_t i = 0; i < k.size(); ++i) k[i] = std::uint8_t(first + i);
    return k;
}

const char* kSunscreen =
    "Ladies and Gentlemen of the class of '99: If I could offer you only one tip for the future, sunscreen would be it.";

}  // namespace

TEST_CASE("crypto: SHA-256 as raw bytes") {
    CHECK(hex(sha256({})) == "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855");
    CHECK(hex(sha256(text("abc"))) == "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad");
    CHECK(hex(sha256(text("abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq"))) ==
          "248d6a61d20638b8e5c026930c3e6039a33ce45964ff2167f6ecedd419db06c1");
}

TEST_CASE("crypto: HMAC-SHA256, RFC 4231 test cases") {
    CHECK(hex(hmac_sha256(repeat(0x0b, 20), text("Hi There"))) ==
          "b0344c61d8db38535ca8afceaf0bf12b881dc200c9833da726e9376c2e32cff7");
    CHECK(hex(hmac_sha256(text("Jefe"), text("what do ya want for nothing?"))) ==
          "5bdcc146bf60754e6a042426089575c75a003f089d2739839dec58b964ec3843");
    CHECK(hex(hmac_sha256(repeat(0xaa, 20), repeat(0xdd, 50))) ==
          "773ea91e36800e46854db8ebd09181a72959098b3ef8c122d9635514ced565fe");
    CHECK(hex(hmac_sha256(unhex("0102030405060708090a0b0c0d0e0f10111213141516171819"), repeat(0xcd, 50))) ==
          "82558a389a443c0ea4cc819899f2083a85f0faa3e578f8077a2e3ff46729665b");
    // A key longer than the 64-byte block is hashed first.
    CHECK(hex(hmac_sha256(repeat(0xaa, 131), text("Test Using Larger Than Block-Size Key - Hash Key First"))) ==
          "60e431591ee0b67f0d8a26aacbf5b77f8e0bc6213728c5140546040f0ee37f54");
    CHECK(hex(hmac_sha256(repeat(0xaa, 131),
                          text("This is a test using a larger than block-size key and a larger than block-size data. The key "
                               "needs to be hashed before being used by the HMAC algorithm."))) ==
          "9b09ffa71b942fcb27635fbcd5b0e944bfdc63644f0713938a7f51535c3a35e2");
    // Empty key and empty data work (the key is padded with zeros).
    CHECK(hex(hmac_sha256({}, {})) == "b613679a0814d9ec772f95d778c35fc5ff1697c493715653c6c712144292c5ad");
}

TEST_CASE("crypto: HKDF-SHA256, RFC 5869 test cases") {
    auto a = hkdf_sha256(repeat(0x0b, 22), unhex("000102030405060708090a0b0c"), unhex("f0f1f2f3f4f5f6f7f8f9"), 42);
    REQUIRE(a);
    CHECK(hex(*a) == "3cb25f25faacd57a90434f64d0362f2a2d2d0a90cf1a5a4c5db02d56ecc4c5bf34007208d5b887185865");

    Bytes ikm, salt, info;
    for (int i = 0x00; i <= 0x4f; ++i) ikm.push_back(std::uint8_t(i));
    for (int i = 0x60; i <= 0xaf; ++i) salt.push_back(std::uint8_t(i));
    for (int i = 0xb0; i <= 0xff; ++i) info.push_back(std::uint8_t(i));
    auto b = hkdf_sha256(ikm, salt, info, 82);
    REQUIRE(b);
    CHECK(hex(*b) ==
          "b11e398dc80327a1c8e7f78c596a49344f012eda2d4efad8a050cc4c19afa97c59045a99cac7827271cb41c65e590e09da3275600c2f09b836"
          "7793a9aca3db71cc30c58179ec3e87c14c01d5c1f3434f1d87");

    auto c = hkdf_sha256(repeat(0x0b, 22), {}, {}, 42);  // no salt, no info
    REQUIRE(c);
    CHECK(hex(*c) == "8da4e775a563c18f715f802a063c5a31b8a11f5c5ee1879ec3454e5f3c738d2d9d201395faa4b61a96c8");

    CHECK(hkdf_sha256(repeat(1, 4), {}, {}, 0)->empty());
    CHECK(hkdf_sha256(repeat(1, 4), {}, {}, 255 * 32)->size() == 255 * 32);
    auto tooLong = hkdf_sha256(repeat(1, 4), {}, {}, 255 * 32 + 1);
    REQUIRE_FALSE(tooLong);
    CHECK(tooLong.error().message.find("8160") != std::string::npos);
    CHECK_FALSE(tooLong.error().hint.empty());
}

TEST_CASE("crypto: key_from_secret is stable and separates contexts") {
    const Key a = key_from_secret("a long random secret", "save-slots");
    CHECK(a == key_from_secret("a long random secret", "save-slots"));
    CHECK(a != key_from_secret("a long random secret", "settings"));
    CHECK(a != key_from_secret("another secret", "save-slots"));
    CHECK(a != Key{});
}

TEST_CASE("crypto: ChaCha20 block function, RFC 8439 section 2.3.2") {
    std::uint8_t out[64];
    crypto::detail::chacha20_block(counting_key(0), 1, nonce_of(unhex("000000090000004a00000000")), out);
    CHECK(hex(ByteView(out, 64)) ==
          "10f1e7e4d13b5915500fdd1fa32071c4c7d1f4c733c068030422aa9ac3d46c4ed2826446079faa0914c2d705d98b02a2b5129cd1de164eb9cb"
          "d083e8a2503c4e");
}

TEST_CASE("crypto: ChaCha20 encryption, RFC 8439 section 2.4.2") {
    const Bytes pt = text(kSunscreen);
    Bytes ct(pt.size());
    crypto::detail::chacha20_xor(counting_key(0), 1, nonce_of(unhex("000000000000004a00000000")), pt, ct.data());
    CHECK(hex(ct) ==
          "6e2e359a2568f98041ba0728dd0d6981e97e7aec1d4360c20a27afccfd9fae0bf91b65c5524733ab8f593dabcd62b3571639d624e65152ab8f"
          "530c359f0861d807ca0dbf500d6a6156a38e088a22b65e52bc514d16ccf806818ce91ab77937365af90bbf74a35be6b40b8eedf2785e42874d");
    // Decryption is the same operation, in place.
    crypto::detail::chacha20_xor(counting_key(0), 1, nonce_of(unhex("000000000000004a00000000")), ct, ct.data());
    CHECK(ct == pt);
}

TEST_CASE("crypto: Poly1305, RFC 8439 section 2.5.2") {
    const Bytes key = unhex("85d6be7857556d337f4452fe42d506a80103808afb0db2fd4abff6af4149f51b");
    std::uint8_t tag[16];
    crypto::detail::poly1305_tag(key.data(), text("Cryptographic Forum Research Group"), tag);
    CHECK(hex(ByteView(tag, 16)) == "a8061dc1305136c6c22b8baf0c0127a9");

    // The edges of the 2^130 - 5 arithmetic (RFC 8439 appendix A.3, vectors 5 and 6): the message 2^128 - 1 + 1 reduces.
    const Bytes r1 = unhex("0200000000000000000000000000000000000000000000000000000000000000");
    crypto::detail::poly1305_tag(r1.data(), unhex("ffffffffffffffffffffffffffffffff"), tag);
    CHECK(hex(ByteView(tag, 16)) == "03000000000000000000000000000000");
    const Bytes r2 = unhex("02000000000000000000000000000000ffffffffffffffffffffffffffffffff");
    crypto::detail::poly1305_tag(r2.data(), unhex("02000000000000000000000000000000"), tag);
    CHECK(hex(ByteView(tag, 16)) == "03000000000000000000000000000000");
    // Empty message: the tag is just the pad (s).
    const Bytes r3 = unhex("0000000000000000000000000000000001020304050607080910111213141516");
    crypto::detail::poly1305_tag(r3.data(), {}, tag);
    CHECK(hex(ByteView(tag, 16)) == "01020304050607080910111213141516");
}

TEST_CASE("crypto: ChaCha20-Poly1305 AEAD, RFC 8439 section 2.8.2") {
    const Key key = counting_key(0x80);
    const Nonce nonce = nonce_of(unhex("070000004041424344454647"));
    const Bytes aad = unhex("50515253c0c1c2c3c4c5c6c7");
    const Bytes pt = text(kSunscreen);
    const std::string expectedCt =
        "d31a8d34648e60db7b86afbc53ef7ec2a4aded51296e08fea9e2b5a736ee62d63dbea45e8ca9671282fafb69da92728b1a71de0a9e060b2905"
        "d6a5b67ecd3b3692ddbd7f2d778b8c9803aee328091b58fab324e4fad675945585808b4831d7bc3ff4def08e4b7a9de576d26586cec64b6116";
    const std::string expectedTag = "1ae10b594f09e26a7e902ecbd0600691";

    auto sealed = aead_seal(key, nonce, aad, pt);
    REQUIRE(sealed);
    CHECK(hex(*sealed) == expectedCt + expectedTag);

    auto opened = aead_open(key, nonce, aad, *sealed);
    REQUIRE(opened);
    CHECK(*opened == pt);
}

TEST_CASE("crypto: AEAD against an independent reference for other lengths") {
    // Generated with a separate pure-Python implementation that reproduces the RFC 8439 vectors: (aad length, plaintext
    // length, SHA-256 of the ciphertext, tag). The padding of the AAD and of the ciphertext differ in every row.
    struct Row {
        std::size_t aad, pt;
        const char* ctSha;
        const char* tag;
    };
    const Row rows[] = {
        {0, 0, "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855", "b787aeec6f7e07d7b655e991cfbe89c8"},
        {33, 0, "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855", "8d873d58423f524189540db61ab076ec"},
        {0, 1, "e9b0c031f0493d3fd6b0b668260c79e7efe734bfd4b4115f9d82bc3be609c294", "6f183f95cb2dd54cc5f0258d24f68382"},
        {17, 64, "6a1cc781ff342580fa626e7958b8b2f11d1789eaaf5f4cd1097717c8495d946c", "f4d929650c649f199357ca253697a43c"},
        {5, 1000, "1c6f5759bb9580fbd39220c57e3251abd6e5443fabeae6e450a558ce7292d49e", "827c8c2bda2a327edc9bf135c37b5b4f"},
    };
    Key key;
    for (std::size_t i = 0; i < key.size(); ++i) key[i] = std::uint8_t((i * 5 + 1) & 255);
    Nonce nonce;
    for (std::size_t i = 0; i < nonce.size(); ++i) nonce[i] = std::uint8_t((i * 3 + 9) & 255);
    for (const Row& row : rows) {
        CAPTURE(row.aad);
        CAPTURE(row.pt);
        Bytes aad(row.aad), pt(row.pt);
        for (std::size_t i = 0; i < aad.size(); ++i) aad[i] = std::uint8_t((i * 11 + 2) & 255);
        for (std::size_t i = 0; i < pt.size(); ++i) pt[i] = std::uint8_t((i * 7 + 3) & 255);
        auto sealed = aead_seal(key, nonce, aad, pt);
        REQUIRE(sealed);
        REQUIRE(sealed->size() == row.pt + kTagSize);
        CHECK(hex(sha256(ByteView(sealed->data(), row.pt))) == row.ctSha);
        CHECK(hex(ByteView(sealed->data() + row.pt, kTagSize)) == row.tag);
        auto opened = aead_open(key, nonce, aad, *sealed);
        REQUIRE(opened);
        CHECK(*opened == pt);
    }
}

TEST_CASE("crypto: the AEAD refuses anything that changed, and returns no plaintext") {
    const Key key = counting_key(1);
    const Nonce nonce = nonce_of(unhex("000102030405060708090a0b"));
    const Bytes aad = text("slot-3");
    const Bytes pt = text("gold=100;level=4;secret plaintext that must not leak");
    auto sealed = aead_seal(key, nonce, aad, pt);
    REQUIRE(sealed);

    SUBCASE("wrong key, nonce or aad") {
        Key other = key;
        other[31] ^= 1;
        auto r = aead_open(other, nonce, aad, *sealed);
        REQUIRE_FALSE(r);
        CHECK(r.error().message.find("the data was changed or the key is wrong") != std::string::npos);
        CHECK_FALSE(r.error().hint.empty());
        Nonce n2 = nonce;
        n2[0] ^= 1;
        CHECK_FALSE(aead_open(key, n2, aad, *sealed));
        CHECK_FALSE(aead_open(key, nonce, text("slot-4"), *sealed));
        CHECK_FALSE(aead_open(key, nonce, {}, *sealed));
        CHECK(aead_open(key, nonce, aad, *sealed));
    }
    SUBCASE("every single flipped bit of the ciphertext and the tag") {
        for (std::size_t i = 0; i < sealed->size(); ++i)
            for (int bit = 0; bit < 8; ++bit) {
                Bytes bad = *sealed;
                bad[i] ^= std::uint8_t(1 << bit);
                REQUIRE_FALSE(aead_open(key, nonce, aad, bad));
            }
    }
    SUBCASE("truncated and extended") {
        for (std::size_t n = 0; n < sealed->size(); ++n)
            REQUIRE_FALSE(aead_open(key, nonce, aad, ByteView(sealed->data(), n)));
        Bytes longer = *sealed;
        longer.push_back(0);
        CHECK_FALSE(aead_open(key, nonce, aad, longer));
    }
}

TEST_CASE("crypto: empty and large plaintexts, unaligned inputs") {
    const Key key = key_from_secret("test", "unit");
    const Nonce nonce = nonce_of(unhex("a0a1a2a3a4a5a6a7a8a9aaab"));

    auto empty = aead_seal(key, nonce, {}, {});
    REQUIRE(empty);
    CHECK(empty->size() == kTagSize);
    auto openedEmpty = aead_open(key, nonce, {}, *empty);
    REQUIRE(openedEmpty);
    CHECK(openedEmpty->empty());

    Bytes big(3 * 1024 * 1024 + 13);
    for (std::size_t i = 0; i < big.size(); ++i) big[i] = std::uint8_t(i * 31 + (i >> 8));
    auto sealedBig = aead_seal(key, nonce, text("aad"), big);
    REQUIRE(sealedBig);
    CHECK(sealedBig->size() == big.size() + kTagSize);
    CHECK(std::equal(sealedBig->begin(), sealedBig->begin() + 64, big.begin()) == false);  // it is encrypted
    auto openedBig = aead_open(key, nonce, text("aad"), *sealedBig);
    REQUIRE(openedBig);
    CHECK(*openedBig == big);

    // Input and aad that start at an odd address, and an output compared with the aligned one.
    const Bytes pt = text(kSunscreen);
    Bytes buf(pt.size() + 8), aadBuf(8 + 12);
    const Bytes aad = unhex("50515253c0c1c2c3c4c5c6c7");
    auto reference = aead_seal(key, nonce, aad, pt);
    REQUIRE(reference);
    for (std::size_t off = 1; off < 8; ++off) {
        std::copy(pt.begin(), pt.end(), buf.begin() + std::ptrdiff_t(off));
        std::copy(aad.begin(), aad.end(), aadBuf.begin() + std::ptrdiff_t(off));
        auto s = aead_seal(key, nonce, ByteView(aadBuf.data() + off, aad.size()), ByteView(buf.data() + off, pt.size()));
        REQUIRE(s);
        CHECK(*s == *reference);
        Bytes sealedBuf(reference->size() + 8);
        std::copy(reference->begin(), reference->end(), sealedBuf.begin() + std::ptrdiff_t(off));
        auto o = aead_open(key, nonce, ByteView(aadBuf.data() + off, aad.size()),
                           ByteView(sealedBuf.data() + off, reference->size()));
        REQUIRE(o);
        CHECK(*o == pt);
        CHECK(hmac_sha256(ByteView(aadBuf.data() + off, aad.size()), ByteView(buf.data() + off, pt.size())) ==
              hmac_sha256(aad, pt));
    }
}

TEST_CASE("crypto: constant_time_equal, secure_zero, random_bytes") {
    CHECK(constant_time_equal(text("abc"), text("abc")));
    CHECK_FALSE(constant_time_equal(text("abc"), text("abd")));
    CHECK_FALSE(constant_time_equal(text("abc"), text("abcd")));
    CHECK(constant_time_equal({}, {}));

    Key k = counting_key(1);
    secure_zero(k);
    CHECK(k == Key{});
    std::uint8_t raw[5] = {1, 2, 3, 4, 5};
    secure_zero(raw, 3);
    CHECK((raw[0] == 0 && raw[2] == 0 && raw[3] == 4 && raw[4] == 5));

    CHECK(random_bytes({}));
    Bytes a(1000), b(1000);  // more than getentropy's 256 bytes per call
    REQUIRE(random_bytes(a));
    REQUIRE(random_bytes(b));
    CHECK(a != b);
    CHECK(std::count(a.begin(), a.end(), 0) < 100);  // 1000 random bytes hold about 4 zeros
    Nonce n1, n2;
    REQUIRE(random_bytes(n1));
    REQUIRE(random_bytes(n2));
    CHECK(n1 != n2);
}

TEST_CASE("crypto: sealed blob round trip and format") {
    const Key key = key_from_secret("secret", "save-slots");
    const std::string data = "{\"gold\":100,\"level\":4}";
    auto blob = seal_blob(key, text("slot-1"), data);
    REQUIRE(blob);
    CHECK(blob->size() == data.size() + kBlobOverhead);
    CHECK(blob->substr(0, 4) == "FASB");
    CHECK(static_cast<std::uint8_t>((*blob)[4]) == kBlobVersion);
    CHECK((*blob)[5] == 0);
    CHECK(is_sealed_blob(*blob));
    CHECK(blob->find("gold") == std::string::npos);  // not readable as text

    auto opened = open_blob(key, text("slot-1"), *blob);
    REQUIRE(opened);
    CHECK(*opened == data);

    // A fresh salt and nonce each time: the same data seals to different files that both open.
    auto again = seal_blob(key, text("slot-1"), data);
    REQUIRE(again);
    CHECK(*again != *blob);
    CHECK(blob->substr(6, 28) != again->substr(6, 28));
    CHECK(*open_blob(key, text("slot-1"), *again) == data);

    // No aad is a different binding from some aad.
    auto noAad = seal_blob(key, {}, data);
    REQUIRE(noAad);
    CHECK(open_blob(key, {}, *noAad));
    CHECK_FALSE(open_blob(key, text("slot-1"), *noAad));
}

TEST_CASE("crypto: sealed blob of empty and large data") {
    const Key key = key_from_secret("secret", "save-slots");
    auto empty = seal_blob(key, {}, std::string_view());
    REQUIRE(empty);
    CHECK(empty->size() == kBlobOverhead);
    auto openedEmpty = open_blob(key, {}, *empty);
    REQUIRE(openedEmpty);
    CHECK(openedEmpty->empty());

    std::string big(2 * 1024 * 1024 + 5, '\0');
    for (std::size_t i = 0; i < big.size(); ++i) big[i] = char(i * 7 + (i >> 9));
    auto blob = seal_blob(key, text("big"), big);
    REQUIRE(blob);
    auto opened = open_blob(key, text("big"), *blob);
    REQUIRE(opened);
    CHECK(*opened == big);
}

TEST_CASE("crypto: a sealed blob with any byte changed does not open") {
    const Key key = key_from_secret("secret", "save-slots");
    const Bytes aad = text("slot-2");
    const std::string data = "hello, this is a save file of some length";
    auto blob = seal_blob(key, aad, data);
    REQUIRE(blob);
    for (std::size_t i = 0; i < blob->size(); ++i) {
        CAPTURE(i);
        std::string bad = *blob;
        bad[i] = char(bad[i] ^ 0x01);
        auto r = open_blob(key, aad, bad);
        REQUIRE_FALSE(r);
        CHECK_FALSE(r.error().message.empty());
        CHECK_FALSE(r.error().hint.empty());
    }
    for (std::size_t i = 0; i < blob->size(); ++i) {  // every byte replaced, not just one bit
        std::string bad = *blob;
        bad[i] = char(bad[i] ^ 0xff);
        REQUIRE_FALSE(open_blob(key, aad, bad));
    }
}

TEST_CASE("crypto: sealed blob errors teach") {
    const Key key = key_from_secret("secret", "save-slots");
    const Bytes aad = text("slot-2");
    auto blob = seal_blob(key, aad, "data");
    REQUIRE(blob);

    SUBCASE("wrong key and wrong aad") {
        auto r = open_blob(key_from_secret("other", "save-slots"), aad, *blob);
        REQUIRE_FALSE(r);
        CHECK(r.error().message.find("the data was changed or the key is wrong") != std::string::npos);
        auto r2 = open_blob(key, text("slot-9"), *blob);
        REQUIRE_FALSE(r2);
        CHECK(r2.error().message.find("the data was changed or the key is wrong") != std::string::npos);
    }
    SUBCASE("every truncation") {
        for (std::size_t n = 0; n < blob->size(); ++n) {
            auto r = open_blob(key, aad, std::string_view(*blob).substr(0, n));
            REQUIRE_FALSE(r);
        }
        auto shortR = open_blob(key, aad, blob->substr(0, 10));
        CHECK(shortR.error().message.find("truncated") != std::string::npos);
        auto extended = *blob + "x";
        CHECK_FALSE(open_blob(key, aad, extended));
    }
    SUBCASE("a plain file") {
        auto r = open_blob(key, aad, "{\"gold\":100}");
        REQUIRE_FALSE(r);
        CHECK(r.error().message.find("not a sealed file") != std::string::npos);
        CHECK_FALSE(is_sealed_blob("{\"gold\":100}"));
        CHECK_FALSE(is_sealed_blob(""));
        CHECK_FALSE(is_sealed_blob("FAS"));
    }
    SUBCASE("a newer format version") {
        std::string newer = *blob;
        newer[4] = char(kBlobVersion + 1);
        auto r = open_blob(key, aad, newer);
        REQUIRE_FALSE(r);
        CHECK(r.error().message.find("format version") != std::string::npos);
        CHECK(r.error().hint.find("update") != std::string::npos);
    }
}
