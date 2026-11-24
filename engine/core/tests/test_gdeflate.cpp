// GDeflate (fa::Codec::GDeflate): round trips across tile and block boundaries, the layout of the stream, corrupt input,
// determinism, the pak with gdeflate blocks (mapped and read, and through the storage layer) and a decode-speed bench.
// The test vectors a Windows CI job checks against DirectStorage's own decoder are written by the case "test vectors"
// (docs/design/ARCHITECTURE_FILES.md, "GDeflate").
#include <doctest.h>

#include <algorithm>
#include <chrono>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <filesystem>
#include <fstream>
#include <iterator>
#include <string>
#include <vector>

#include "../src/compress_internal.h"
#include "fa/core/compress.h"
#include "fa/core/fs.h"
#include "fa/core/pack.h"
#include "fa_test_paths.h"

using namespace fa;
using Bytes = std::vector<std::uint8_t>;
namespace stdfs = std::filesystem;

namespace {

constexpr std::size_t kTile = 65536;

struct Rng {
    std::uint64_t s;
    explicit Rng(std::uint64_t seed) : s(seed) {}
    std::uint64_t next() {
        std::uint64_t z = (s += 0x9E3779B97F4A7C15ull);
        z = (z ^ (z >> 30)) * 0xBF58476D1CE4E5B9ull;
        z = (z ^ (z >> 27)) * 0x94D049BB133111EBull;
        return z ^ (z >> 31);
    }
};

Bytes random_bytes(std::size_t n, std::uint64_t seed) {
    Rng r(seed);
    Bytes b(n);
    for (auto& v : b) v = static_cast<std::uint8_t>(r.next());
    return b;
}

Bytes text_bytes(std::size_t n, std::uint64_t seed) {
    static const char* const words[] = {"the",   "entity", "component", "scene",  "player", "moves",  "to",
                                        "pos",   "and",    "plays",     "a",      "sound",  "when",   "health",
                                        "reach", "zero",   "level",     "engine", "frame",  "update", "of"};
    Rng r(seed);
    Bytes out;
    out.reserve(n + 16);
    while (out.size() < n) {
        const char* w = words[r.next() % (sizeof(words) / sizeof(words[0]))];
        for (; *w; ++w) out.push_back(static_cast<std::uint8_t>(*w));
        out.push_back(r.next() % 9 == 0 ? '\n' : ' ');
    }
    out.resize(n);
    return out;
}

// Long matches, distances that reach the far end of the tile, and a run of one byte: the Deflate64 corners.
Bytes structured_bytes(std::size_t n) {
    Bytes b = random_bytes(n, 99);
    for (std::size_t i = 40000; i < std::min<std::size_t>(n, 60000); ++i) b[i] = 7;             // a long run
    for (std::size_t i = 61000; i < std::min<std::size_t>(n, 65536); ++i) b[i] = b[i - 60000];  // far matches
    for (std::size_t i = 70000; i + 1 < n && i < 120000; ++i) b[i] = b[i - 65500];              // across tiles
    return b;
}

Bytes round_trip(const Bytes& in, int level = 0) {
    auto c = compress(in, CompressOptions{Codec::GDeflate, level});
    REQUIRE(c.ok());
    CHECK(c.value().size() <= compress_bound(Codec::GDeflate, in.size()));
    auto d = decompress(Codec::GDeflate, c.value(), in.size());
    REQUIRE_MESSAGE(d.ok(), (d.ok() ? "" : d.error().message));
    return d.value();
}

Bytes stream_of(const Bytes& in, int level = 0) {
    auto c = compress(in, CompressOptions{Codec::GDeflate, level});
    REQUIRE(c.ok());
    return c.value();
}

std::uint32_t le32(const Bytes& b, std::size_t at) { return codec::load32(b.data() + at); }

}  // namespace

TEST_CASE("gdeflate: names and parsing") {
    CHECK(codec_name(Codec::GDeflate) == "gdeflate");
    auto c = parse_codec("gdeflate");
    REQUIRE(c.ok());
    CHECK(c.value() == Codec::GDeflate);
    auto bad = parse_codec("gdeflat");
    REQUIRE(!bad.ok());
    CHECK(bad.error().message.find("gdeflat") != std::string::npos);
    CHECK(bad.error().hint.find("gdeflate") != std::string::npos);
}

TEST_CASE("gdeflate: round trips across sizes, kinds of data and levels") {
    const std::size_t sizes[] = {
        0, 1, 2, 3, 31, 32, 33, 255, 4096, kTile - 1, kTile, kTile + 1, 2 * kTile - 1, 2 * kTile, 262144, 262144 + 17};
    for (std::size_t n : sizes) {
        CAPTURE(n);
        CHECK(round_trip(Bytes(n, 0)) == Bytes(n, 0));
        const Bytes text = text_bytes(n, n + 1);
        CHECK(round_trip(text) == text);
        const Bytes noise = random_bytes(n, n + 7);
        CHECK(round_trip(noise) == noise);
        const Bytes mixed = structured_bytes(n);
        CHECK(round_trip(mixed) == mixed);
    }
    const Bytes text = text_bytes(200000, 5);
    for (int level : {1, 2, 3, 4, 6, 9, 12}) {
        CAPTURE(level);
        CHECK(round_trip(text, level) == text);
    }
    // Levels out of range are clamped, 0 is the default.
    CHECK(round_trip(text, 99) == text);
    CHECK(stream_of(text, 0) == stream_of(text, 6));
}

TEST_CASE("gdeflate: the ratio is that of deflate on text, and incompressible data costs little") {
    const Bytes text = text_bytes(262144, 3);
    const Bytes packed = stream_of(text);
    CHECK(packed.size() < text.size() / 2);
    const Bytes zeros(262144, 0);
    CHECK(stream_of(zeros).size() < 8 + 16 + 4 * 512);
    const Bytes noise = random_bytes(262144, 4);
    const Bytes stored = stream_of(noise);
    // Four stored tiles: the bytes plus the lane words, the 3-bit and 16-bit headers and the 8-byte stream header.
    CHECK(stored.size() <= noise.size() + 8 + 16 + 4 * 160);
    CHECK(stored.size() <= compress_bound(Codec::GDeflate, noise.size()));
    CHECK(compress_bound(Codec::GDeflate, 0) >= 8);
}

TEST_CASE("gdeflate: the stream header and the tile table") {
    for (std::size_t n : {std::size_t(1), kTile - 1, kTile, kTile + 1, 3 * kTile + 5}) {
        CAPTURE(n);
        const Bytes s = stream_of(text_bytes(n, 2));
        const std::size_t tiles = (n + kTile - 1) / kTile;
        REQUIRE(s.size() >= 8 + 4 * tiles);
        CHECK(s[0] == 4);
        CHECK(s[1] == 0xFB);
        CHECK(s[2] + (s[3] << 8) == int(tiles));
        const std::uint32_t word = le32(s, 4);
        CHECK((word & 3u) == 1u);                        // tile size index 1: 64 KiB
        CHECK(((word >> 2) & 0x3FFFFu) == (n % kTile));  // 0 = the last tile is full
        CHECK((word >> 20) == 0u);                       // reserved
        const std::size_t data = 8 + 4 * tiles;
        // entry 0: size of the last tile; entry i: offset of tile i in the data.
        std::size_t prev = 0;
        for (std::size_t t = 1; t < tiles; ++t) {
            const std::size_t off = le32(s, 8 + 4 * t);
            CHECK(off > prev);
            CHECK(off % 4 == 0);
            prev = off;
        }
        CHECK(data + (tiles > 1 ? prev : 0) + le32(s, 8) == s.size());
    }
    // An empty input: a header and no tiles.
    const Bytes empty = stream_of({});
    CHECK(empty.size() == 8);
    CHECK(round_trip({}).empty());
}

TEST_CASE("gdeflate: a tile is read exactly (every lane word the encoder wrote is the decoder's, in order)") {
    for (std::size_t n : {std::size_t(1), std::size_t(40), std::size_t(5000), kTile}) {
        for (int kind = 0; kind < 3; ++kind) {
            const Bytes in = kind == 0 ? text_bytes(n, 11) : kind == 1 ? random_bytes(n, 12) : structured_bytes(n);
            const Bytes s = stream_of(in);
            const std::size_t data = 8 + 4;
            Bytes out(n);
            auto r = codec::gdeflate_decode_tile(std::span<const std::uint8_t>(s).subspan(data), out);
            REQUIRE_MESSAGE(r.ok(), (r.ok() ? "" : r.error().message));
            CHECK(r.value() == s.size() - data);
            CHECK(r.value() >= 128);
            CHECK(out == in);
        }
    }
}

TEST_CASE("gdeflate: a stored block written by hand decodes (lane layout of the format)") {
    // One final stored block of "AB": 3-bit header and 16-bit length in lane 0, then one byte per lane from lane 0.
    Bytes tile(256, 0);  // 32 lane words, and the one more lane 0 takes after its 3 header bits
    codec::store32(tile.data(), 1u | (2u << 3) | (std::uint32_t('A') << 19));
    codec::store32(tile.data() + 4, 'B');
    Bytes out(2);
    auto r = codec::gdeflate_decode_tile(tile, out);
    REQUIRE_MESSAGE(r.ok(), (r.ok() ? "" : r.error().message));
    CHECK(r.value() == 136);  // the 128 lane bytes and the words lanes 0 and 1 took when they ran low
    CHECK(out == Bytes{'A', 'B'});
    // The same bytes with the wrong expected size are an error, not a short read.
    Bytes three(3);
    CHECK(!codec::gdeflate_decode_tile(tile, three).ok());
}

TEST_CASE("gdeflate: a static block written by hand decodes, with a match one round after its length") {
    // Static Huffman block "a" x 6 as literal 'a' + match (length 5, distance 1), end of block. Lane 0: header and the
    // literal; lane 1: the length symbol; lane 2: end of block; the distance (code 0, 5 bits) goes to lane 1 in round 2.
    struct Lane {
        std::uint64_t bits = 0;
        unsigned n = 0;
        void put(std::uint32_t v, unsigned c) {
            bits |= std::uint64_t(v) << n;
            n += c;
        }
        // Huffman codes go in MSB first.
        void code(std::uint32_t v, unsigned c) {
            for (unsigned i = 0; i < c; ++i) put((v >> (c - 1 - i)) & 1u, 1);
        }
    };
    Lane l0, l1, l2;
    l0.put(1, 1);                    // final
    l0.put(1, 2);                    // static
    l0.code(0x30 + 'a', 8);          // literals 0..143: 8 bits, 00110000 + value
    l1.code(0x00 + (259 - 256), 7);  // 256..279: 7 bits from 0000000; length symbol 259 = length 5
    l2.code(0, 7);                   // 256 = end of block
    l1.code(0, 5);                   // distance symbol 0 = distance 1
    Bytes tile(256, 0);
    codec::store32(tile.data() + 0, static_cast<std::uint32_t>(l0.bits));
    codec::store32(tile.data() + 4, static_cast<std::uint32_t>(l1.bits));
    codec::store32(tile.data() + 8, static_cast<std::uint32_t>(l2.bits));
    Bytes out(6);
    auto r = codec::gdeflate_decode_tile(tile, out);
    REQUIRE_MESSAGE(r.ok(), (r.ok() ? "" : r.error().message));
    CHECK(out == Bytes(6, 'a'));
}

TEST_CASE("gdeflate: corrupt input is an error that names the block, tile and byte, never a crash") {
    const Bytes in = text_bytes(2 * kTile + 100, 21);
    const Bytes good = stream_of(in);
    Bytes out(in.size());
    REQUIRE(decompress_into(Codec::GDeflate, good, out).ok());

    auto expect_error = [&](const Bytes& bad, const char* what) {
        CAPTURE(what);
        auto r = decompress_into(Codec::GDeflate, bad, out);
        REQUIRE(!r.ok());
        CHECK(r.error().message.find("gdeflate") != std::string::npos);
        CHECK(r.error().message.find("byte") != std::string::npos);
        CHECK(!r.error().hint.empty());
        return r.error().message;
    };
    {
        Bytes bad = good;
        bad[0] = 5;
        expect_error(bad, "id");
        bad = good;
        bad[1] = 0;
        expect_error(bad, "magic");
        bad = good;
        bad[4] = 2;  // tile size index 2
        expect_error(bad, "tile size index");
        bad = good;
        bad[7] = 0x10;  // reserved bits
        expect_error(bad, "reserved");
        bad = good;
        bad[2] = 4;  // more tiles than the output holds
        expect_error(bad, "tile count");
    }
    expect_error(Bytes(good.begin(), good.begin() + 5), "cut inside the header");
    expect_error(Bytes(good.begin(), good.begin() + 14), "cut inside the table");
    {
        Bytes bad = good;
        codec::store32(bad.data() + 8 + 8, static_cast<std::uint32_t>(good.size()));  // tile 2 starts past the end
        const std::string m = expect_error(bad, "offset past the end");
        CHECK(m.find("tile") != std::string::npos);
    }
    {
        Bytes bad = good;
        codec::store32(bad.data() + 8 + 4, 0x7FFFFFFFu);  // tile 1 starts beyond tile 2
        expect_error(bad, "offsets out of order");
    }
    // The size the caller expects must be the size the stream holds.
    {
        Bytes wrong(in.size() - 1);
        CHECK(!decompress_into(Codec::GDeflate, good, wrong).ok());
    }
    // Every cut of a small stream, and every flipped byte: an error, or the same bytes, never undefined behaviour
    // (the sanitizer jobs of CI would report it).
    const Bytes small = text_bytes(3000, 3);
    const Bytes stream = stream_of(small);
    Bytes sout(small.size());
    for (std::size_t cut = 0; cut < stream.size(); ++cut) {
        auto r = decompress_into(Codec::GDeflate, std::span<const std::uint8_t>(stream.data(), cut), sout);
        CHECK(!r.ok());
    }
    int errors = 0;
    for (std::size_t i = 0; i < stream.size(); ++i)
        for (std::uint8_t mask : {std::uint8_t(0x01), std::uint8_t(0x80), std::uint8_t(0xFF)}) {
            Bytes bad = stream;
            bad[i] ^= mask;
            auto r = decompress_into(Codec::GDeflate, bad, sout);
            if (!r.ok()) {
                ++errors;
                CHECK(r.error().message.find("gdeflate") != std::string::npos);
            }
        }
    CHECK(errors > 0);
    // A block the size of the claim cannot hold is refused before anything is allocated.
    auto huge = decompress(Codec::GDeflate, good, SIZE_MAX / 2);
    CHECK(!huge.ok());
    // Noise as a stream.
    for (std::uint64_t seed = 1; seed <= 20; ++seed) {
        Bytes noise = random_bytes(600, seed);
        noise[0] = 4;
        noise[1] = 0xFB;
        noise[2] = 1;
        noise[3] = 0;
        noise[4] = 1;
        noise[5] = noise[6] = noise[7] = 0;
        Bytes nout(kTile);
        (void)decompress_into(Codec::GDeflate, noise, nout);
    }
}

TEST_CASE("gdeflate: damaged tiles are named by their index and byte") {
    const Bytes in = random_bytes(3 * kTile, 31);  // stored tiles
    Bytes s = stream_of(in);
    // Make tile 1's first block a reserved type: bits 1..2 of lane 0's first word.
    const std::size_t data = 8 + 4 * 3;
    const std::size_t tile1 = data + le32(s, 8 + 4);
    s[tile1] |= 0x06;
    Bytes out(in.size());
    auto r = decompress_into(Codec::GDeflate, s, out);
    REQUIRE(!r.ok());
    CHECK(r.error().message.find("tile 1") != std::string::npos);
    const std::size_t atPos = r.error().message.find("(at byte ");
    REQUIRE(atPos != std::string::npos);
    CHECK(std::stoull(r.error().message.substr(atPos + 9)) >= tile1);  // inside tile 1 or after its lane words
}

TEST_CASE("gdeflate: the output is deterministic") {
    const Bytes in = structured_bytes(300000);
    const Bytes a = stream_of(in);
    const Bytes b = stream_of(in);
    CHECK(a == b);
    // The same through a second compression of a copy at another address and after other work.
    Bytes copy = in;
    (void)stream_of(text_bytes(1000, 1));
    CHECK(stream_of(copy) == a);
}

TEST_CASE(
    "gdeflate: the pak keeps gdeflate blocks and reads them back, mapped and read, and through the storage layer") {
    struct Scratch {
        stdfs::path oldRoot = fs::project_root();
        stdfs::path dir = fs::make_temp_dir("fa_test_gdeflate").value();
        ~Scratch() {
            fs::unmount_pack();
            fs::set_project_root(oldRoot);
            std::error_code ec;
            stdfs::remove_all(dir, ec);
        }
    } s;
    const std::uint64_t B = kPackBlockSize;
    std::vector<std::pair<std::string, Bytes>> files;
    for (std::uint64_t n : {std::uint64_t(0), std::uint64_t(1), std::uint64_t(65536), B - 1, B, B + 1, 3 * B + 5})
        files.emplace_back("g/f" + std::to_string(n) + ".json", text_bytes(std::size_t(n), n + 1));
    files.emplace_back("g/noise.bin", random_bytes(std::size_t(2 * B + 3), 8));
    files.emplace_back("g/structured.bin", structured_bytes(std::size_t(B + 70000)));
    PackWriter w;
    for (const auto& [path, data] : files) REQUIRE(w.add_bytes(path, data, Codec::GDeflate).ok());
    auto stats = w.write(s.dir / "game.pak");
    REQUIRE_MESSAGE(stats.ok(), (stats.ok() ? "" : stats.error().to_string()));
    CHECK(stats.value().compressErrors == 0);
    CHECK(stats.value().codecs[std::size_t(Codec::GDeflate)].files >= 5);
    CHECK(stats.value().storedBytes < stats.value().bytes);

    for (bool map : {true, false}) {
        CAPTURE(map);
        auto opened = PackReader::open(s.dir / "game.pak", PackOpenOptions{map});
        REQUIRE_MESSAGE(opened.ok(), (opened.ok() ? "" : opened.error().to_string()));
        const PackReader& p = *opened.value();
        CHECK(p.format_version() == 2);
        CHECK(p.codec_of("g/f" + std::to_string(B) + ".json") == Codec::GDeflate);
        CHECK(p.codec_of("g/noise.bin") == Codec::Store);  // not compressible: recorded as stored
        for (const auto& [path, want] : files) {
            auto all = p.read(path);
            REQUIRE_MESSAGE(all.ok(), path << ": " << (all.ok() ? "" : all.error().to_string()));
            CHECK(all.value() == want);
            if (want.size() > 100) {
                auto part = p.read_range(path, want.size() / 2, 70000);
                REQUIRE(part.ok());
                const std::size_t from = want.size() / 2;
                const std::size_t len = std::min<std::size_t>(70000, want.size() - from);
                CHECK(part.value() == Bytes(want.begin() + from, want.begin() + from + len));
            }
        }
        auto v = p.view("g/f" + std::to_string(B) + ".json");
        REQUIRE(v.ok());
        CHECK(!v.value().mapped());  // decoded into a buffer the view owns
    }

    // Through the storage layer: mount the pack and read by path, as a game does.
    fs::set_project_root(s.dir / "nowhere");
    REQUIRE(fs::mount_pack(s.dir / "game.pak").ok());
    for (const auto& [path, want] : files) {
        auto r = fs::read_bytes(path);
        REQUIRE_MESSAGE(r.ok(), path << ": " << (r.ok() ? "" : r.error().to_string()));
        CHECK(r.value() == want);
    }
    fs::unmount_pack();

    // A pack cut short is refused when it is opened.
    auto bytes = [&] {
        std::ifstream in(s.dir / "game.pak", std::ios::binary);
        return Bytes((std::istreambuf_iterator<char>(in)), std::istreambuf_iterator<char>());
    }();
    bytes.resize(bytes.size() / 2);
    CHECK(!PackReader::open_memory(bytes, "cut.pak").ok());
}

TEST_CASE("gdeflate: test vectors for the DirectStorage decoder") {
    // The vectors are fixed by seeds and sizes: raw bytes and the stream this encoder writes for them. The FNV-1a hash
    // of every raw and stream is pinned here, so a change of the encoder's output (on any platform: it is integer-only)
    // is a deliberate one (FA_GDEFLATE_PRINT_HASHES=1 prints the new values); FA_GDEFLATE_VECTORS_DIR=<dir> also
    // writes <name>.raw and <name>.gdef for a job that feeds them to DirectStorage's decoder (M77 P11b) and compares
    // the result to the .raw.
    struct Vector {
        const char* name;
        Bytes raw;
        std::uint64_t rawHash;
        std::uint64_t gdefHash;
    };
    std::vector<Vector> vectors;
    vectors.push_back({"empty", {}, 0xcbf29ce484222325ull, 0xfa78522c67d13e09ull});
    vectors.push_back({"byte", Bytes{42}, 0xaf63a74c8601927dull, 0x91e5d2497f6d8876ull});
    vectors.push_back(
        {"text_one_tile_less_one", text_bytes(kTile - 1, 1), 0x46be7a61e673b621ull, 0xd48e3ba0ff146bafull});
    vectors.push_back({"text_two_tiles", text_bytes(kTile + 1, 2), 0x0aee8c7a934b6e9eull, 0xe5a7988735a550a6ull});
    vectors.push_back({"text_block", text_bytes(262144, 3), 0xae0bbc0533a5585cull, 0x51387ba926f7915eull});
    vectors.push_back({"noise_block", random_bytes(262144, 4), 0x67b493646fb23a27ull, 0x377c41fe3c6cfcceull});
    vectors.push_back({"zeros_block", Bytes(262144, 0), 0x9c735bed0a722325ull, 0xf3bdb0a4666bfb84ull});
    vectors.push_back({"structured", structured_bytes(200000), 0x547946993377b75dull, 0x5d4ab3e52beff416ull});
    auto fnv = [](const Bytes& b) {
        std::uint64_t h = 0xcbf29ce484222325ull;
        for (std::uint8_t c : b) h = (h ^ c) * 0x100000001b3ull;
        return h;
    };
    const char* dir = std::getenv("FA_GDEFLATE_VECTORS_DIR");
    for (const Vector& v : vectors) {
        const Bytes s = stream_of(v.raw);
        Bytes out(v.raw.size());
        REQUIRE(decompress_into(Codec::GDeflate, s, out).ok());
        CHECK(out == v.raw);
        CHECK_MESSAGE(fnv(v.raw) == v.rawHash, v.name << ": the generated input changed");
        CHECK_MESSAGE(fnv(s) == v.gdefHash, v.name << ": the encoder's output changed");
        if (dir) {
            const stdfs::path base = stdfs::path(dir);
            std::ofstream(base / (std::string(v.name) + ".raw"), std::ios::binary)
                .write(reinterpret_cast<const char*>(v.raw.data()), std::streamsize(v.raw.size()));
            std::ofstream(base / (std::string(v.name) + ".gdef"), std::ios::binary)
                .write(reinterpret_cast<const char*>(s.data()), std::streamsize(s.size()));
        }
        if (!std::getenv("FA_GDEFLATE_PRINT_HASHES")) continue;
        std::printf("%s raw=%016llx gdef=%016llx size=%zu\n", v.name, static_cast<unsigned long long>(fnv(v.raw)),
                    static_cast<unsigned long long>(fnv(s)), s.size());
    }
}

TEST_CASE("gdeflate: decode speed against lz4 and zstd (prints MB/s, checks nothing about them)") {
    const Bytes in = text_bytes(8u << 20, 77);
    for (Codec c : {Codec::Lz4, Codec::Zstd, Codec::GDeflate}) {
        Bytes out(in.size());
        // Blocks of 256 KiB, as the pack stores them.
        std::vector<Bytes> blocks;
        for (std::size_t at = 0; at < in.size(); at += 262144) {
            auto b =
                compress(std::span<const std::uint8_t>(in).subspan(at, std::min<std::size_t>(262144, in.size() - at)),
                         CompressOptions{c, 0});
            REQUIRE(b.ok());
            blocks.push_back(std::move(b.value()));
        }
        double best = 1e30;
        for (int rep = 0; rep < 3; ++rep) {
            const auto t0 = std::chrono::steady_clock::now();
            std::size_t at = 0;
            for (const Bytes& b : blocks) {
                const std::size_t n = std::min<std::size_t>(262144, in.size() - at);
                REQUIRE(decompress_into(c, b, std::span<std::uint8_t>(out).subspan(at, n)).ok());
                at += n;
            }
            best = std::min(best, std::chrono::duration<double>(std::chrono::steady_clock::now() - t0).count());
        }
        CHECK(out == in);
        std::size_t stored = 0;
        for (const Bytes& b : blocks) stored += b.size();
        std::printf("[bench] %-8s ratio %.2f  decode %.0f MB/s\n", std::string(codec_name(c)).c_str(),
                    double(in.size()) / double(stored), double(in.size()) / best / 1e6);
    }
}
