#include <doctest.h>

#include <algorithm>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <filesystem>
#include <fstream>
#include <iterator>
#include <limits>
#include <string>
#include <vector>

#include "../src/compress_internal.h"
#include "fa/core/compress.h"
#include "fa_test_paths.h"

using namespace fa;
using Bytes = std::vector<std::uint8_t>;

namespace {

// A small fixed-seed generator (splitmix64): the same bytes on every platform.
struct Rng {
    std::uint64_t s;
    explicit Rng(std::uint64_t seed) : s(seed) {}
    std::uint64_t next() {
        std::uint64_t z = (s += 0x9E3779B97F4A7C15ull);
        z = (z ^ (z >> 30)) * 0xBF58476D1CE4E5B9ull;
        z = (z ^ (z >> 27)) * 0x94D049BB133111EBull;
        return z ^ (z >> 31);
    }
    std::uint32_t below(std::uint32_t n) { return static_cast<std::uint32_t>(next() % n); }
};

Bytes read_file(const std::string& path) {
    std::ifstream in(path, std::ios::binary);
    REQUIRE_MESSAGE(in.good(), "missing file " << path);
    return Bytes((std::istreambuf_iterator<char>(in)), std::istreambuf_iterator<char>());
}

Bytes repo_file(const char* relative) { return read_file(std::string(FA_REPO_ROOT "/") + relative); }
Bytes fixture(const char* name) {
    return read_file(std::string(FA_REPO_ROOT "/engine/core/tests/data/codecs/") + name);
}

Bytes random_bytes(std::size_t n, std::uint64_t seed) {
    Rng r(seed);
    Bytes b(n);
    for (auto& v : b) v = static_cast<std::uint8_t>(r.next());
    return b;
}

// Words from a small vocabulary, a plausible text.
Bytes text_bytes(std::size_t n, std::uint64_t seed) {
    static const char* const words[] = {"the",      "entity", "component", "scene",  "player", "moves",  "to",
                                        "position", "and",    "plays",     "a",      "sound",  "when",   "health",
                                        "reaches",  "zero",   "level",     "engine", "frame",  "update", "of",
                                        "camera",   "sprite", "tile",      "script"};
    Rng r(seed);
    std::string s;
    while (s.size() < n) {
        s += words[r.below(25)];
        s += (r.below(12) == 0) ? ".\n" : " ";
    }
    s.resize(n);
    return Bytes(s.begin(), s.end());
}

// Some bytes of structure: records with a counter, a flag and a few skewed values (like a binary table).
Bytes record_bytes(std::size_t n, std::uint64_t seed) {
    Rng r(seed);
    Bytes b;
    std::uint32_t counter = 0;
    while (b.size() < n) {
        for (int i = 0; i < 4; ++i) b.push_back(static_cast<std::uint8_t>(counter >> (8 * i)));
        ++counter;
        b.push_back(static_cast<std::uint8_t>(r.below(4) == 0));
        b.push_back(static_cast<std::uint8_t>(r.below(8) * r.below(8)));
        for (int i = 0; i < 6; ++i) b.push_back(0);
    }
    b.resize(n);
    return b;
}

struct Input {
    std::string name;
    Bytes data;
};

// `big` selects the sizes: the Debug test run keeps the inputs small.
std::vector<Input> inputs(bool big) {
    const std::size_t scale = big ? 4 : 1;
    std::vector<Input> v;
    v.push_back({"empty", {}});
    v.push_back({"one byte", {42}});
    v.push_back({"two bytes", {7, 7}});
    v.push_back({"twelve bytes", Bytes(12, 'x')});
    v.push_back({"thirteen distinct", Bytes{1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13}});
    v.push_back({"all zero", Bytes(30000 * scale, 0)});
    v.push_back({"all zero 300k", Bytes(300000, 0)});
    v.push_back({"random", random_bytes(20000 * scale, 1)});
    {
        Bytes b;
        for (std::size_t i = 0; i < 20000 * scale; ++i) b.push_back(static_cast<std::uint8_t>("abcabcab"[i % 8]));
        v.push_back({"repetitive", std::move(b)});
    }
    v.push_back({"text", text_bytes(60000 * scale, 2)});
    v.push_back({"records", record_bytes(40000 * scale, 3)});
    v.push_back({"json", fixture("ground.json")});
    v.push_back({"binary (mpg)", repo_file("engine/core/tests/data/colors.mpg")});
    {
        // Matches that overlap their own output, long distances and a literal run past 15 and 255.
        Bytes b = random_bytes(300, 4);
        for (int i = 0; i < 5; ++i) b.insert(b.end(), b.begin(), b.begin() + 290);
        Bytes r2 = random_bytes(70000, 5);
        b.insert(b.end(), r2.begin(), r2.end());
        b.insert(b.end(), r2.begin(), r2.begin() + 66000);
        v.push_back({"mixed", std::move(b)});
    }
    return v;
}

template <class R>
std::string err_text(const R& r) {
    return r.ok() ? std::string() : r.error().to_string();
}

Bytes must_compress(const Bytes& in, Codec codec, int level) {
    auto r = compress(in, {codec, level});
    REQUIRE_MESSAGE(r.ok(), err_text(r));
    return std::move(r.value());
}

void roundtrip(const Input& in, Codec codec, int level) {
    const Bytes block = must_compress(in.data, codec, level);
    CHECK_MESSAGE(block.size() <= compress_bound(codec, in.data.size()),
                  in.name << " " << codec_name(codec) << " L" << level << ": bound " << block.size());
    auto out = decompress(codec, block, in.data.size());
    REQUIRE_MESSAGE(out.ok(), in.name << " " << codec_name(codec) << " L" << level << ": " << err_text(out));
    CHECK_MESSAGE(out.value() == in.data, in.name << " " << codec_name(codec) << " L" << level << " differs");
    // Deterministic: compressing again gives the same bytes.
    CHECK(must_compress(in.data, codec, level) == block);
}

}  // namespace

TEST_CASE("codecs: names parse and unknown names get a suggestion") {
    CHECK(codec_name(Codec::Lz4) == "lz4");
    CHECK(parse_codec("zstd").value() == Codec::Zstd);
    CHECK(parse_codec("store").value() == Codec::Store);
    auto bad = parse_codec("zst");
    REQUIRE_FALSE(bad.ok());
    CHECK(bad.error().to_string().find("zstd") != std::string::npos);
}

TEST_CASE("lz4: round trips at every level") {
    for (const Input& in : inputs(false))
        for (int level : {0, 1, 2, 3, 4, 5, 6, 8, 9, 12}) roundtrip(in, Codec::Lz4, level);
}

TEST_CASE("lz4: a higher level never gives a worse ratio on text, and compressible data shrinks") {
    const Bytes text = text_bytes(100000, 9);
    const std::size_t l1 = must_compress(text, Codec::Lz4, 1).size();
    const std::size_t l9 = must_compress(text, Codec::Lz4, 9).size();
    const std::size_t l12 = must_compress(text, Codec::Lz4, 12).size();
    CHECK(l1 < text.size() / 2);
    CHECK(l9 <= l1);
    CHECK(l12 <= l9 + l9 / 50);
    CHECK(must_compress(Bytes(100000, 0), Codec::Lz4, 1).size() < 600);
}

TEST_CASE("lz4: levels outside the range are clamped") {
    const Bytes text = text_bytes(5000, 10);
    CHECK(must_compress(text, Codec::Lz4, 99) == must_compress(text, Codec::Lz4, 12));
    CHECK(must_compress(text, Codec::Lz4, -5) == must_compress(text, Codec::Lz4, 1));
}

TEST_CASE("store: bytes unchanged, a wrong size is an error") {
    const Bytes data = {1, 2, 3, 4};
    CHECK(must_compress(data, Codec::Store, 0) == data);
    CHECK(decompress(Codec::Store, data, 4).value() == data);
    CHECK_FALSE(decompress(Codec::Store, data, 5).ok());
}

// ---- Zstandard ----------------------------------------------------------------------------------------------------

TEST_CASE("zstd: round trips") {
    for (const Input& in : inputs(false))
        for (int level : {0, 1, 2, 3, 4, 6, 9, 12, 19}) roundtrip(in, Codec::Zstd, level);
}

TEST_CASE("zstd: block size edges and a frame without a single segment") {
    for (std::size_t n : {std::size_t{131071}, std::size_t{131072}, std::size_t{131073}, std::size_t{262144}}) {
        const Bytes data = text_bytes(n, 20 + n);
        for (int level : {1, 5}) roundtrip({"text " + std::to_string(n), data}, Codec::Zstd, level);
        roundtrip({"zero " + std::to_string(n), Bytes(n, 0)}, Codec::Zstd, 3);
    }
    // Longer than the window of level 1 (1 MiB): the header then carries a window size instead of a single segment.
    Bytes big = text_bytes(1300000, 30);
    const Bytes more = random_bytes(5000, 31);
    big.insert(big.end(), more.begin(), more.end());
    big.insert(big.end(), big.begin(), big.begin() + 200000);  // a match 1.3 MB back: past the window, must not be used
    const Bytes block = must_compress(big, Codec::Zstd, 1);
    CHECK((block[4] & 0x20) == 0);  // not a single segment: the header carries a window size
    auto out = decompress(Codec::Zstd, block, big.size());
    REQUIRE_MESSAGE(out.ok(), err_text(out));
    CHECK(out.value() == big);
}

TEST_CASE("zstd: ratio is near the reference zstd -3 and a higher level gives a smaller frame") {
    const Bytes json = fixture("ground.json");
    const std::size_t l1 = must_compress(json, Codec::Zstd, 1).size();
    const std::size_t l3 = must_compress(json, Codec::Zstd, 3).size();
    const std::size_t l9 = must_compress(json, Codec::Zstd, 9).size();
    const std::size_t l19 = must_compress(json, Codec::Zstd, 19).size();
    // The reference tool makes 6606 bytes at -3 and 4965 at -19 (fixtures ground.l3.zst and ground.l19.zst).
    CHECK(l3 <= fixture("ground.l3.zst").size() + fixture("ground.l3.zst").size() / 20);
    CHECK(l19 <= fixture("ground.l19.zst").size() + fixture("ground.l19.zst").size() / 10);
    CHECK(l3 <= l1);
    CHECK(l9 <= l3);
    CHECK(l19 <= l9);
    CHECK(must_compress(Bytes(100000, 0), Codec::Zstd, 3).size() < 40);
    // Data that does not compress costs a few bytes more, not a lot more.
    const Bytes noise = random_bytes(50000, 40);
    CHECK(must_compress(noise, Codec::Zstd, 3).size() <= noise.size() + 32);
}

TEST_CASE("zstd: levels outside the range are clamped") {
    const Bytes text = text_bytes(5000, 11);
    CHECK(must_compress(text, Codec::Zstd, 99) == must_compress(text, Codec::Zstd, 19));
    CHECK(must_compress(text, Codec::Zstd, -5) == must_compress(text, Codec::Zstd, 1));
    CHECK(must_compress(text, Codec::Zstd, 0) == must_compress(text, Codec::Zstd, 3));
}

TEST_CASE("zstd: frames made by the reference tool decode (committed fixtures)") {
    const Bytes json = fixture("ground.json");
    for (const char* name : {"ground.l1.zst", "ground.l3.zst", "ground.l19.zst", "ground.l3.nocheck.zst",
                             "ground.l22.zst", "ground.stdin.zst", "ground.frames.zst"}) {
        const Bytes frame = fixture(name);
        auto out = decompress(Codec::Zstd, frame, json.size());
        REQUIRE_MESSAGE(out.ok(), name << ": " << err_text(out));
        CHECK_MESSAGE(out.value() == json, name);
    }
    const Bytes zeros = decompress(Codec::Zstd, fixture("zeros300k.zst"), 300000).value();
    CHECK(zeros == Bytes(300000, 0));
    const Bytes noise = fixture("random2k.bin");
    CHECK(decompress(Codec::Zstd, fixture("random2k.l3.zst"), noise.size()).value() == noise);
}

TEST_CASE("zstd: the content checksum is written and checked") {
    const Bytes json = fixture("ground.json");
    Bytes frame;
    codec::zstd_compress(json, 3, true, frame);
    auto ok = decompress(Codec::Zstd, frame, json.size());
    REQUIRE_MESSAGE(ok.ok(), err_text(ok));
    CHECK(ok.value() == json);
    Bytes plain;
    codec::zstd_compress(json, 3, false, plain);
    CHECK(frame.size() == plain.size() + 4);
    // Any change to the checksum, or to the data it covers, is an error.
    Bytes bad = frame;
    bad.back() ^= 1;
    CHECK_FALSE(decompress(Codec::Zstd, bad, json.size()).ok());
    // The reference frame carries a checksum too.
    Bytes ref = fixture("ground.l3.zst");
    ref.back() ^= 0x80;
    auto r = decompress(Codec::Zstd, ref, json.size());
    REQUIRE_FALSE(r.ok());
    CHECK(r.error().to_string().find("checksum") != std::string::npos);
}

TEST_CASE("zstd: a wrong expected size, a huge one, and refused frames are errors") {
    const Bytes json = fixture("ground.json");
    const Bytes frame = must_compress(json, Codec::Zstd, 3);
    CHECK_FALSE(decompress(Codec::Zstd, frame, json.size() - 1).ok());
    CHECK_FALSE(decompress(Codec::Zstd, frame, json.size() + 1).ok());
    CHECK_FALSE(decompress(Codec::Zstd, frame, 0).ok());
    // The stdin fixture has no content size: the size check is the caller's expected size.
    const Bytes noSize = fixture("ground.stdin.zst");
    CHECK_FALSE(decompress(Codec::Zstd, noSize, json.size() - 1).ok());
    CHECK_FALSE(decompress(Codec::Zstd, noSize, json.size() + 1).ok());
    // Sizes no block this small can hold: refused before anything is allocated.
    CHECK_FALSE(decompress(Codec::Zstd, frame, std::numeric_limits<std::size_t>::max()).ok());
    CHECK_FALSE(decompress(Codec::Zstd, frame, std::size_t{1} << 40).ok());
    CHECK_FALSE(decompress(Codec::Lz4, Bytes{0x10, 'a'}, std::numeric_limits<std::size_t>::max()).ok());
    CHECK_FALSE(decompress(Codec::Lz4, Bytes{0x10, 'a'}, std::size_t{1} << 40).ok());
}

namespace {
// A frame header (single segment, content size in one byte) followed by `rest`.
Bytes small_frame(std::uint8_t contentSize, const Bytes& rest) {
    Bytes f = {0x28, 0xB5, 0x2F, 0xFD, 0x20, contentSize};
    f.insert(f.end(), rest.begin(), rest.end());
    return f;
}
Bytes with_header(std::uint8_t fhd, const Bytes& afterFhd, const Bytes& rest) {
    Bytes f = {0x28, 0xB5, 0x2F, 0xFD, fhd};
    f.insert(f.end(), afterFhd.begin(), afterFhd.end());
    f.insert(f.end(), rest.begin(), rest.end());
    return f;
}
// A compressed block (type 2, last) around `body`.
Bytes compressed_block(const Bytes& body) {
    const std::uint32_t h = 1u | (2u << 1) | (static_cast<std::uint32_t>(body.size()) << 3);
    Bytes b = {static_cast<std::uint8_t>(h), static_cast<std::uint8_t>(h >> 8), static_cast<std::uint8_t>(h >> 16)};
    b.insert(b.end(), body.begin(), body.end());
    return b;
}
std::string why_not(const Bytes& frame, std::size_t expected) {
    auto r = decompress(Codec::Zstd, frame, expected);
    REQUIRE_MESSAGE(!r.ok(), "a malformed frame decoded");
    return r.error().to_string();
}
}  // namespace

TEST_CASE("zstd: malformed headers and tables are errors that say why") {
    const Bytes emptyLast = {0x01, 0x00, 0x00};  // a last raw block of 0 bytes
    CHECK(why_not(Bytes{1, 2, 3, 4, 5, 6, 7, 8}, 0).find("magic") != std::string::npos);
    CHECK(why_not(Bytes{}, 0).find("empty") != std::string::npos);
    CHECK(why_not(Bytes{0x28, 0xB5, 0x2F}, 0).find("cut short") != std::string::npos);
    // a window of 2^30 bytes (descriptor exponent 20), over the engine's cap
    CHECK(why_not(with_header(0x00, {20 << 3}, emptyLast), 0).find("window") != std::string::npos);
    // a dictionary id
    CHECK(why_not(with_header(0x20 | 0x01, {5, 0}, emptyLast), 0).find("dictionary") != std::string::npos);
    // the reserved bit of the frame header
    CHECK_FALSE(decompress(Codec::Zstd, with_header(0x28, {0}, emptyLast), 0).ok());
    // the reserved block type
    CHECK_FALSE(decompress(Codec::Zstd, small_frame(0, Bytes{0x07, 0x00, 0x00}), 0).ok());
    // a raw block of 128 KiB + 1
    {
        const std::uint32_t h = 1u | (static_cast<std::uint32_t>(131073) << 3);
        Bytes f = with_header(0x20 | 0x80, {0x01, 0x00, 0x02, 0x00}, {});
        f.insert(f.end(),
                 {static_cast<std::uint8_t>(h), static_cast<std::uint8_t>(h >> 8), static_cast<std::uint8_t>(h >> 16)});
        f.resize(f.size() + 131073, 'x');
        CHECK_FALSE(decompress(Codec::Zstd, f, 131073).ok());
    }
    // content size 10 in the header, 11 expected; a block that is cut short
    CHECK_FALSE(decompress(Codec::Zstd, small_frame(10, Bytes{0x01 | (10 << 3), 0, 0, 'a'}), 10).ok());
    CHECK(why_not(small_frame(10, Bytes{0x01, 0, 0}), 11).find("10") != std::string::npos);
    // the sequence section: reserved mode bits, a repeat table nobody defined, a table with accuracy 20 bits
    const Bytes lits = {0x28, 'a', 'b', 'c', 'd', 'e'};  // 5 raw literals
    auto body = [&](const Bytes& seq) {
        Bytes b = lits;
        b.insert(b.end(), seq.begin(), seq.end());
        return small_frame(200, compressed_block(b));
    };
    CHECK(why_not(body({1, 0x01, 0xFF}), 200).find("reserved") != std::string::npos);
    CHECK(why_not(body({1, 0xC0, 0xFF}), 200).find("repeat") != std::string::npos);
    CHECK(why_not(body({1, 0x80, 0x0F, 0xFF, 0xFF, 0xFF}), 200).find("accuracy") != std::string::npos);
    CHECK_FALSE(decompress(Codec::Zstd, body({1, 0x80, 0x00, 0x00, 0x00, 0xFF}), 200).ok());  // does not add up
    CHECK_FALSE(decompress(Codec::Zstd, body({1, 0x00}), 200).ok());                          // no bitstream
    CHECK_FALSE(decompress(Codec::Zstd, body({1, 0x00, 0x00}), 200).ok());                    // no end mark
    CHECK_FALSE(decompress(Codec::Zstd, body({200, 0x00, 0xFF, 0xFF, 0xFF}), 200).ok());      // cut short
    // literals: treeless without an earlier tree, Huffman weights too large / all zero / not a complete code
    auto huf = [&](std::uint8_t type, const Bytes& tree) {
        // single stream, 10 literals, compressed size = tree + 2 stream bytes
        const std::uint32_t comp = static_cast<std::uint32_t>(tree.size() + 2);
        const std::uint32_t h = type | (0u << 2) | (10u << 4) | (comp << 14);
        Bytes b = {static_cast<std::uint8_t>(h), static_cast<std::uint8_t>(h >> 8), static_cast<std::uint8_t>(h >> 16)};
        b.insert(b.end(), tree.begin(), tree.end());
        b.push_back(0xFF);
        b.push_back(0x01);
        b.push_back(0);  // zero sequences
        return small_frame(200, compressed_block(b));
    };
    CHECK(why_not(huf(3, {}), 200).find("no earlier block") != std::string::npos);
    CHECK_FALSE(decompress(Codec::Zstd, huf(2, {129, 0xFF}), 200).ok());  // weights 15, 15
    CHECK_FALSE(decompress(Codec::Zstd, huf(2, {129, 0x00}), 200).ok());  // all zero
    CHECK_FALSE(
        decompress(Codec::Zstd, huf(2, {130, 0x13, 0x30}), 200).ok());      // 1, 3, 3, (implied): not a power of two
    CHECK_FALSE(decompress(Codec::Zstd, huf(2, {}), 200).ok());             // tree missing
    CHECK_FALSE(decompress(Codec::Zstd, huf(2, {20, 1, 2, 3}), 200).ok());  // FSE weights cut short
}

TEST_CASE("zstd and lz4: truncation and bit flips are errors or other data, never a crash") {
    const Bytes json = fixture("ground.json");
    Bytes withSum;
    codec::zstd_compress(json, 3, true, withSum);
    struct Sample {
        const char* name;
        Codec codec;
        Bytes block;
        bool checked;  // a decoded result must be the original
    };
    std::vector<Sample> samples;
    samples.push_back({"zstd ours", Codec::Zstd, withSum, true});
    samples.push_back({"zstd L1 ours", Codec::Zstd, must_compress(json, Codec::Zstd, 1), false});
    samples.push_back({"zstd reference", Codec::Zstd, fixture("ground.l3.zst"), true});
    samples.push_back({"zstd reference L19", Codec::Zstd, fixture("ground.l19.zst"), true});
    samples.push_back({"lz4 ours", Codec::Lz4, must_compress(json, Codec::Lz4, 1), false});
    samples.push_back({"lz4 L9 ours", Codec::Lz4, must_compress(json, Codec::Lz4, 9), false});
    Rng rng(77);
    for (const Sample& s : samples) {
        // Every cut: a block missing its end can never give the full size back.
        const std::size_t step = std::max<std::size_t>(1, s.block.size() / 150);
        for (std::size_t cut = 0; cut < s.block.size(); cut += (cut < 40 || cut + 40 > s.block.size()) ? 1 : step) {
            const Bytes part(s.block.begin(), s.block.begin() + static_cast<std::ptrdiff_t>(cut));
            CHECK_MESSAGE(!decompress(s.codec, part, json.size()).ok(), s.name << " cut at " << cut << " decoded");
        }
        // Flips of one bit at fixed pseudo-random places.
        std::size_t errors = 0;
        for (int i = 0; i < 400; ++i) {
            Bytes bad = s.block;
            bad[rng.below(static_cast<std::uint32_t>(bad.size()))] ^= static_cast<std::uint8_t>(1u << rng.below(8));
            auto r = decompress(s.codec, bad, json.size());
            if (!r.ok()) {
                ++errors;
                CHECK_FALSE(r.error().to_string().empty());
            } else if (s.checked) {
                CHECK_MESSAGE(r.value() == json, s.name << ": a damaged frame decoded to other data");
            }
        }
        CHECK_MESSAGE(errors > 100, s.name << ": only " << errors << " of 400 flips were noticed");
    }
}

TEST_CASE("zstd and lz4: random garbage never crashes the decoders") {
    Rng rng(123);
    for (int i = 0; i < 1500; ++i) {
        const std::size_t n = 1 + rng.below(300);
        Bytes junk(n);
        for (auto& b : junk) b = static_cast<std::uint8_t>(rng.next());
        // lz4 takes any bytes; zstd gets a valid header so the garbage reaches the block decoder
        auto l = decompress(Codec::Lz4, junk, 1 + rng.below(4000));
        (void)l;
        const std::uint32_t expected = 1 + rng.below(200);
        Bytes f = {0x28, 0xB5, 0x2F, 0xFD, 0x20, static_cast<std::uint8_t>(expected > 255 ? 255 : expected)};
        f.insert(f.end(), {0, 0, 0});
        const std::uint32_t kind = rng.below(2);
        const std::uint32_t h = 1u | (2u << 1) | (static_cast<std::uint32_t>(n) << 3);
        f[6] = static_cast<std::uint8_t>(h);
        f[7] = static_cast<std::uint8_t>(h >> 8);
        f[8] = static_cast<std::uint8_t>(h >> 16);
        // sometimes start the block with plausible literals and sequence headers
        if (kind == 1 && n > 8) {
            junk[0] = static_cast<std::uint8_t>(0x28 | (rng.below(2) ? 0 : 2));
            junk[6] = static_cast<std::uint8_t>(1 + rng.below(3));
        }
        f.insert(f.end(), junk.begin(), junk.end());
        auto z = decompress(Codec::Zstd, f, expected);
        (void)z;
    }
    CHECK(true);
}

// ---- LZ4 interop and damaged blocks -------------------------------------------------------------------------------

namespace {
// The data of an LZ4 frame as the reference tool writes it (blocks, no dictionary), through our block decoder.
Bytes lz4_frame_data(const Bytes& f, std::size_t total) {
    REQUIRE(f.size() > 11);
    REQUIRE(f[0] == 0x04);
    REQUIRE(f[1] == 0x22);
    REQUIRE(f[2] == 0x4D);
    REQUIRE(f[3] == 0x18);
    const std::uint8_t flg = f[4], bd = f[5];
    const std::size_t blockMax = std::size_t{1} << (8 + 2 * ((bd >> 4) & 7));  // 4: 64 KiB, 5: 256 KiB ...
    std::size_t at = 6 + ((flg & 0x08) ? 8 : 0) + 1;
    Bytes data;
    while (at + 4 <= f.size()) {
        std::uint32_t size =
            f[at] | (f[at + 1] << 8) | (f[at + 2] << 16) | (static_cast<std::uint32_t>(f[at + 3]) << 24);
        at += 4;
        if (size == 0) break;
        const bool stored = (size & 0x80000000u) != 0;
        size &= 0x7FFFFFFFu;
        REQUIRE(at + size <= f.size());
        const Bytes blk(f.begin() + static_cast<std::ptrdiff_t>(at),
                        f.begin() + static_cast<std::ptrdiff_t>(at + size));
        at += size + ((flg & 0x10) ? 4 : 0);
        if (stored) {
            data.insert(data.end(), blk.begin(), blk.end());
        } else {
            auto out = decompress(Codec::Lz4, blk, std::min(blockMax, total - data.size()));
            REQUIRE_MESSAGE(out.ok(), err_text(out));
            data.insert(data.end(), out.value().begin(), out.value().end());
        }
    }
    return data;
}
}  // namespace

TEST_CASE("lz4: blocks made by the reference tool decode (committed fixtures)") {
    const Bytes json = fixture("ground.json");
    for (const char* name : {"ground.l1.lz4", "ground.l9.lz4", "ground.l12.lz4"})
        CHECK_MESSAGE(lz4_frame_data(fixture(name), json.size()) == json, name);
    CHECK(lz4_frame_data(fixture("zeros300k.lz4"), 300000) == Bytes(300000, 0));
    CHECK(lz4_frame_data(fixture("random2k.lz4"), 2000) == fixture("random2k.bin"));
}

TEST_CASE("lz4: hand-made damaged blocks are errors") {
    // offset 0, an offset before the start, a literal run past the end, a match past the expected size, no offset
    CHECK_FALSE(decompress(Codec::Lz4, Bytes{0x14, 'a', 0, 0, 0x00}, 9).ok());
    CHECK_FALSE(decompress(Codec::Lz4, Bytes{0x14, 'a', 5, 0, 0x00}, 9).ok());
    CHECK_FALSE(decompress(Codec::Lz4, Bytes{0xF0, 0xFF, 0xFF, 'a'}, 10).ok());
    CHECK_FALSE(decompress(Codec::Lz4, Bytes{0x1F, 'a', 1, 0, 0xFF, 0xFF}, 8).ok());
    CHECK_FALSE(decompress(Codec::Lz4, Bytes{0x14, 'a'}, 9).ok());
    CHECK_FALSE(decompress(Codec::Lz4, Bytes{0x11, 'a', 1, 0}, 6).ok());  // ends with a match, no last token
    CHECK_FALSE(decompress(Codec::Lz4, Bytes{}, 5).ok());
    CHECK_FALSE(decompress(Codec::Lz4, Bytes{}, 0).ok());  // even an empty input is one token byte
    CHECK(decompress(Codec::Lz4, Bytes{0}, 0).ok());
    // a valid one for contrast: "a", an overlapping match of 20 at distance 1, then the final literals "bcdef"
    const Bytes good = {0x1F, 'a', 1, 0, 0x01, 0x50, 'b', 'c', 'd', 'e', 'f'};
    auto r = decompress(Codec::Lz4, good, 1 + 20 + 5);
    REQUIRE_MESSAGE(r.ok(), err_text(r));
    CHECK(r.value()[0] == 'a');
}

#if !defined(_WIN32)
// The `zstd` command line tool, when it is installed, reads the frames we write and we read what it writes. Without it
// (CI images, Windows) this case does nothing: the committed fixtures above cover the same ground.
TEST_CASE("zstd: round trip through the zstd command line tool when it is on the PATH") {
    if (std::system("zstd --version > /dev/null 2>&1") != 0) return;
    namespace fs = std::filesystem;
    const fs::path dir = fs::temp_directory_path() / "fa_test_zstd_cli";
    std::error_code ec;
    fs::remove_all(dir, ec);
    fs::create_directories(dir);
    auto write_bytes = [](const fs::path& path, const Bytes& data) {
        std::ofstream f(path, std::ios::binary);
        f.write(reinterpret_cast<const char*>(data.data()), static_cast<std::streamsize>(data.size()));
        return f.good();
    };
    const std::string raw = (dir / "raw.bin").string(), packed = (dir / "packed.zst").string();
    const std::string back = (dir / "back.bin").string();
    std::vector<Bytes> inputs = {fixture("ground.json"), text_bytes(70000, 5), random_bytes(3000, 6), Bytes(200000, 7)};
    for (const Bytes& input : inputs) {
        REQUIRE(write_bytes(raw, input));
        // ours -> zstd -d
        for (int level : {1, 3, 9, 19}) {
            const Bytes frame = must_compress(input, Codec::Zstd, level);
            REQUIRE(write_bytes(packed, frame));
            const std::string cmd = "zstd -q -d -f -o \"" + back + "\" \"" + packed + "\" > /dev/null 2>&1";
            CHECK_MESSAGE(std::system(cmd.c_str()) == 0, "zstd -d refused our level " << level << " frame");
            CHECK_MESSAGE(read_file(back) == input, "zstd -d gave other bytes for our level " << level << " frame");
        }
        // zstd -> ours
        for (int level : {1, 3, 19}) {
            const std::string cmd =
                "zstd -q -" + std::to_string(level) + " -f -o \"" + packed + "\" \"" + raw + "\" > /dev/null 2>&1";
            REQUIRE(std::system(cmd.c_str()) == 0);
            auto out = decompress(Codec::Zstd, read_file(packed), input.size());
            REQUIRE_MESSAGE(out.ok(), err_text(out));
            CHECK_MESSAGE(out.value() == input, "we read zstd -" << level << " wrongly");
        }
    }
    fs::remove_all(dir, ec);
}
#endif
