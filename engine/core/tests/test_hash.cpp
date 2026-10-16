#include <doctest.h>

#include <filesystem>
#include <fstream>
#include <string>

#include "fa/core/fs.h"
#include "fa/core/hash.h"

using namespace fa;

TEST_CASE("hash: SHA-256 standard test vectors") {
    CHECK(sha256_hex("") == "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855");
    CHECK(sha256_hex("abc") == "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad");
    CHECK(sha256_hex("abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq") ==
          "248d6a61d20638b8e5c026930c3e6039a33ce45964ff2167f6ecedd419db06c1");
    CHECK(sha256_hex("abcdefghbcdefghicdefghijdefghijkefghijklfghijklmghijklmnhijklmnoijklmnopjklmnopqklmnopqrlmnopqrsmnopqrstnopqrstu") ==
          "cf5b16a778af8380036ce59e7b0492370b249b11e8f07a51afac45037afee9d1");
    CHECK(sha256_hex(std::string(1000000, 'a')) == "cdc76e5c9914fb9281a1c7e284d73e67f1809a48a497200e046d39ccc7112cd0");
}

TEST_CASE("hash: SHA-1 standard test vectors") {
    CHECK(sha1_hex("") == "da39a3ee5e6b4b0d3255bfef95601890afd80709");
    CHECK(sha1_hex("abc") == "a9993e364706816aba3e25717850c26c9cd0d89d");
    CHECK(sha1_hex("abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq") == "84983e441c3bd26ebaae4aa1f95129e5e54670f1");
    CHECK(sha1_hex(std::string(1000000, 'a')) == "34aa973cd4c4daa4f61eeb2bdbad27316534016f");
    CHECK(sha1_hex("The quick brown fox jumps over the lazy dog") == "2fd4e1c67a2d28fced849ee1bb76e7391b93eb12");
}

TEST_CASE("hash: updating in odd-sized pieces equals hashing the whole buffer") {
    std::string data;
    for (int i = 0; i < 1000; ++i) data += char('a' + i % 26);
    for (std::size_t piece : {1u, 3u, 55u, 56u, 63u, 64u, 65u, 129u}) {
        Sha256 s256;
        Sha1 s1;
        for (std::size_t at = 0; at < data.size(); at += piece) {
            const std::string_view part = std::string_view(data).substr(at, piece);
            s256.update(part);
            s1.update(part);
        }
        CHECK_MESSAGE(s256.finish_hex() == sha256_hex(data), "piece size " << piece);
        CHECK_MESSAGE(s1.finish_hex() == sha1_hex(data), "piece size " << piece);
    }
    // Lengths around the padding boundary (55, 56, 63, 64 bytes) all hash without error and differ from each other.
    CHECK(sha256_hex(std::string(55, 'x')) != sha256_hex(std::string(56, 'x')));
    CHECK(sha256_hex(std::string(64, 'x')).size() == 64);
    CHECK(sha1_hex(std::string(56, 'x')).size() == 40);
}

TEST_CASE("hash: files are hashed in chunks and a missing file is an error that names it") {
    const std::filesystem::path dir = fs::make_temp_dir("fa_hash_test");
    const std::filesystem::path file = dir / "data.bin";
    {
        std::ofstream out(file, std::ios::binary);
        for (int i = 0; i < 200000; ++i) out << "abcdefghij";  // 2 MB: more than one read chunk
    }
    std::string whole(2000000, '\0');
    {
        std::ifstream in(file, std::ios::binary);
        in.read(whole.data(), std::streamsize(whole.size()));
    }
    auto sha256 = sha256_file_hex(file);
    auto sha1 = sha1_file_hex(file);
    REQUIRE(sha256.ok());
    REQUIRE(sha1.ok());
    CHECK(*sha256 == sha256_hex(whole));
    CHECK(*sha1 == sha1_hex(whole));

    auto missing = sha256_file_hex(dir / "nope.bin");
    REQUIRE_FALSE(missing.ok());
    CHECK(missing.error().message.find("nope.bin") != std::string::npos);
    CHECK_FALSE(missing.error().hint.empty());
    std::error_code ec;
    std::filesystem::remove_all(dir, ec);
}
