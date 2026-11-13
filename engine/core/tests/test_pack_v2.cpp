// game.pak format 2: blocks, codecs, checksums, memory mapping and its fallback, pack order, Windows rules, the load trace.
#include <doctest.h>

#include <algorithm>
#include <atomic>
#include <cstdlib>
#include <filesystem>
#include <fstream>
#include <iterator>
#include <string>
#include <thread>
#include <vector>

#include "fa/core/compress.h"
#include "fa/core/fs.h"
#include "fa/core/load_trace.h"
#include "fa/core/pack.h"

#ifdef _WIN32
#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif
#ifndef NOMINMAX
#define NOMINMAX
#endif
#include <windows.h>
#endif

using namespace fa;
namespace stdfs = std::filesystem;

namespace {

constexpr std::uint64_t B = kPackBlockSize;

struct Scratch {
    stdfs::path oldRoot, dir;
    Scratch() : oldRoot(fs::project_root()), dir(fs::make_temp_dir("fa_test_pack2").value()) {}
    ~Scratch() {
        fs::unmount_pack();
        fs::set_project_root(oldRoot);
        std::error_code ec;
        stdfs::remove_all(dir, ec);
    }
    stdfs::path pak() const { return dir / "game.pak"; }
};

struct RulesScope {
    bool before = fs::windows_rules();
    explicit RulesScope(bool on) { fs::set_windows_rules(on); }
    ~RulesScope() { fs::set_windows_rules(before); }
};

// The Windows build running under Wine (the MinGW CI job): Wine keeps some POSIX file behaviour real Windows does not.
bool running_under_wine() {
#ifdef _WIN32
    const HMODULE ntdll = GetModuleHandleW(L"ntdll.dll");
    return ntdll && GetProcAddress(ntdll, "wine_get_version") != nullptr;
#else
    return false;
#endif
}

void set_env(const char* name, const char* value) {
#ifdef _WIN32
    _putenv_s(name, value ? value : "");
#else
    if (value) ::setenv(name, value, 1);
    else ::unsetenv(name);
#endif
}

std::string read_file(const stdfs::path& p) {
    std::ifstream in(p, std::ios::binary);
    return std::string(std::istreambuf_iterator<char>(in), {});
}
void write_file(const stdfs::path& p, const std::string& data) { std::ofstream(p, std::ios::binary | std::ios::trunc) << data; }
std::vector<std::uint8_t> bytes_of(const std::string& s) { return {s.begin(), s.end()}; }

// Bytes that compress (repeating words) and bytes that do not (an LCG: deterministic, no rand()).
std::vector<std::uint8_t> text_bytes(std::size_t n, int salt = 0) {
    static const char* words[] = {"entity ", "transform ", "sprite ", "{\"x\":1,", "\"y\":2}, ", "collider ", "\n"};
    std::vector<std::uint8_t> out;
    out.reserve(n);
    std::uint32_t k = std::uint32_t(salt);
    while (out.size() < n) {
        k = k * 1103515245u + 12345u;
        for (const char* c = words[(k >> 16) % 7]; *c && out.size() < n; ++c) out.push_back(std::uint8_t(*c));
    }
    return out;
}
std::vector<std::uint8_t> noise_bytes(std::size_t n, std::uint32_t seed) {
    std::vector<std::uint8_t> out(n);
    std::uint32_t k = seed;
    for (auto& b : out) {
        k = k * 1664525u + 1013904223u;
        b = std::uint8_t(k >> 24);
    }
    return out;
}

// Sizes around the block size: none, one byte, one block less one, one block, one more, several blocks.
const std::vector<std::uint64_t> kSizes = {0, 1, B - 1, B, B + 1, 3 * B + 5};

void check_ranges(const PackReader& p, const std::string& path, const std::vector<std::uint8_t>& want) {
    auto all = p.read(path);
    REQUIRE_MESSAGE(all.ok(), path << ": " << (all.ok() ? "" : all.error().to_string()));
    CHECK(all.value() == want);
    const std::uint64_t n = want.size();
    // Ranges that start and end on and around block boundaries, and ranges past the end (clamped).
    for (std::uint64_t from : {std::uint64_t(0), std::uint64_t(1), B - 1, B, B + 1, n / 2, n}) {
        for (std::uint64_t len : {std::uint64_t(0), std::uint64_t(1), std::uint64_t(2), B, B + 2, n}) {
            auto r = p.read_range(path, from, len);
            REQUIRE(r.ok());
            const std::uint64_t f = std::min(from, n), l = std::min(len, n - f);
            CHECK_MESSAGE(r.value() == std::vector<std::uint8_t>(want.begin() + std::ptrdiff_t(f), want.begin() + std::ptrdiff_t(f + l)),
                          path << " from " << from << " len " << len);
        }
    }
}

}  // namespace

TEST_CASE("pack v2: XXH32 checksum matches the reference vectors") {
    CHECK(pack_checksum({}) == 0x02CC5D05u);
    const std::string abc = "abc";
    CHECK(pack_checksum(std::span<const std::uint8_t>(reinterpret_cast<const std::uint8_t*>(abc.data()), abc.size())) == 0x32D153FFu);
    const std::string fox = "The quick brown fox jumps over the lazy dog";
    CHECK(pack_checksum(std::span<const std::uint8_t>(reinterpret_cast<const std::uint8_t*>(fox.data()), fox.size())) == 0xE85EA4DEu);
}

TEST_CASE("pack v2: default codecs by file type") {
    CHECK(pack_default_codec("assets/hero.png") == Codec::Store);
    CHECK(pack_default_codec("assets/music/song.OGG") == Codec::Store);
    CHECK(pack_default_codec("assets/sfx/hit.qoa") == Codec::Store);
    CHECK(pack_default_codec("assets/intro.mp4") == Codec::Store);
    CHECK(pack_default_codec("assets/t.basis") == Codec::Store);
    CHECK(pack_default_codec("scenes/main.scene.json") == Codec::Lz4);
    CHECK(pack_default_codec("scripts/player.js") == Codec::Lz4);
    CHECK(pack_default_codec("assets/ship.glb") == Codec::Lz4);
    CHECK(pack_default_codec("assets/raw.bmp") == Codec::Lz4);
    CHECK(pack_default_codec("assets/fonts/ui.ttf") == Codec::Zstd);
    CHECK(pack_default_codec("docs/credits.txt") == Codec::Zstd);
    // KTX2: the header says whether the levels are supercompressed (u32 at byte 44).
    std::vector<std::uint8_t> head(48, 0);
    CHECK(pack_default_codec("assets/t.ktx2", head) == Codec::Lz4);
    head[44] = 2;  // zstd supercompression
    CHECK(pack_default_codec("assets/t.ktx2", head) == Codec::Store);
    CHECK(pack_default_codec("assets/t.ktx2") == Codec::Store);  // no header: assume it is
}

TEST_CASE("pack v2: store round trip across block boundaries, mapped and read") {
    Scratch s;
    PackWriter w;
    std::vector<std::vector<std::uint8_t>> data;
    for (std::size_t i = 0; i < kSizes.size(); ++i) {
        data.push_back(noise_bytes(std::size_t(kSizes[i]), std::uint32_t(i + 1)));
        REQUIRE(w.add_bytes("data/f" + std::to_string(i) + ".bin", data.back(), Codec::Store).ok());
    }
    auto stats = w.write(s.pak());
    REQUIRE(stats.ok());
    CHECK(stats.value().files == kSizes.size());
    CHECK(stats.value().codecs[0].files == kSizes.size());
    CHECK(stats.value().bytes == stats.value().storedBytes);
    CHECK(stats.value().packBytes == stdfs::file_size(s.pak()));
    CHECK(!stdfs::exists(s.dir / "game.pak.tmp"));

    for (bool map : {true, false}) {
        CAPTURE(map);
        auto opened = PackReader::open(s.pak(), PackOpenOptions{map});
        REQUIRE(opened.ok());
        const PackReader& p = *opened.value();
        CHECK(p.format_version() == 2);
#if !defined(__EMSCRIPTEN__)
        if (sizeof(void*) == 8) CHECK(p.mapped() == map);
#endif
        for (std::size_t i = 0; i < kSizes.size(); ++i) {
            const std::string path = "data/f" + std::to_string(i) + ".bin";
            CHECK(p.size_of(path) == std::int64_t(kSizes[i]));
            CHECK(p.stored_size_of(path) == std::int64_t(kSizes[i]));
            CHECK(p.codec_of(path) == Codec::Store);
            check_ranges(p, path, data[i]);
        }
        CHECK(p.counters().reads > 0);
    }
}

TEST_CASE("pack v2: lz4 and zstd round trip across block boundaries") {
    Scratch s;
    PackWriter w;
    std::vector<std::pair<std::string, std::vector<std::uint8_t>>> files;
    for (Codec c : {Codec::Lz4, Codec::Zstd})
        for (std::size_t i = 0; i < kSizes.size(); ++i) {
            files.emplace_back(std::string(codec_name(c)) + "/f" + std::to_string(i) + ".json", text_bytes(std::size_t(kSizes[i]), int(i)));
            REQUIRE(w.add_bytes(files.back().first, files.back().second, c).ok());
        }
    // Noise does not compress: the blocks stay as they are and the file is recorded as stored.
    files.emplace_back("noise.bin", noise_bytes(std::size_t(2 * B + 3), 7));
    REQUIRE(w.add_bytes("noise.bin", files.back().second, Codec::Zstd).ok());
    auto stats = w.write(s.pak());
    REQUIRE(stats.ok());
    CHECK(stats.value().compressErrors == 0);
    CHECK(stats.value().storedBytes < stats.value().bytes);
    CHECK(stats.value().codecs[std::size_t(Codec::Lz4)].storedBytes < stats.value().codecs[std::size_t(Codec::Lz4)].bytes);

    for (bool map : {true, false}) {
        CAPTURE(map);
        auto opened = PackReader::open(s.pak(), PackOpenOptions{map});
        REQUIRE(opened.ok());
        const PackReader& p = *opened.value();
        CHECK(p.codec_of("noise.bin") == Codec::Store);
        CHECK(p.codec_of("lz4/f5.json") == Codec::Lz4);
        CHECK(p.codec_of("zstd/f5.json") == Codec::Zstd);
        CHECK(p.stored_size_of("zstd/f5.json") < p.size_of("zstd/f5.json"));
        for (const auto& [path, want] : files) check_ranges(p, path, want);
        auto v = p.view("lz4/f5.json");
        REQUIRE(v.ok());
        CHECK(!v.value().mapped());  // compressed: decoded into a buffer the view owns
        CHECK(v.value().to_vector() == files[5].second);
    }
}

TEST_CASE("pack v2: a format 1 pack is still read") {
    Scratch s;
    // Format 1 written by hand: header, the bytes, index (count; u16 len, path, u64 offset, u64 size), footer.
    auto le = [](std::string& out, std::uint64_t v, int n) {
        for (int i = 0; i < n; ++i) out.push_back(char((v >> (8 * i)) & 0xff));
    };
    const std::string a = "{\"name\":\"Old\"}", b = "hello old pack";
    std::string pak = "FAPACK\r\n";
    le(pak, 1, 4);
    le(pak, 0, 4);
    const std::uint64_t offA = pak.size();
    pak += a;
    const std::uint64_t offB = pak.size();
    pak += b;
    const std::uint64_t indexOffset = pak.size();
    std::string index;
    le(index, 2, 4);
    for (auto [path, off, size] : {std::tuple<std::string, std::uint64_t, std::uint64_t>{"factoria.json", offA, a.size()},
                                   {"notes/b.txt", offB, b.size()}}) {
        le(index, path.size(), 2);
        index += path;
        le(index, off, 8);
        le(index, size, 8);
    }
    pak += index;
    le(pak, indexOffset, 8);
    le(pak, index.size(), 8);
    pak += "FAPKEND!";
    write_file(s.pak(), pak);

    for (bool map : {true, false}) {
        auto opened = PackReader::open(s.pak(), PackOpenOptions{map});
        REQUIRE_MESSAGE(opened.ok(), (opened.ok() ? "" : opened.error().to_string()));
        const PackReader& p = *opened.value();
        CHECK(p.format_version() == 1);
        CHECK(p.file_count() == 2);
        auto ra = p.read("factoria.json");
        REQUIRE(ra.ok());
        CHECK(std::string(ra.value().begin(), ra.value().end()) == a);
        auto rb = p.read_range("notes/b.txt", 6, 3);
        REQUIRE(rb.ok());
        CHECK(std::string(rb.value().begin(), rb.value().end()) == "old");
        auto v = p.view("notes/b.txt");
        REQUIRE(v.ok());
        CHECK(std::string(v.value().text()) == b);
    }
}

TEST_CASE("pack v2: a damaged pack is an error that names the file and the block") {
    Scratch s;
    PackWriter w;
    const auto data = noise_bytes(std::size_t(2 * B + 10), 3);
    REQUIRE(w.add_bytes("a.bin", data, Codec::Store).ok());
    REQUIRE(w.write(s.pak()).ok());
    const std::string good = read_file(s.pak());
    const stdfs::path bad = s.dir / "bad.pak";

    SUBCASE("cut short") {
        write_file(bad, good.substr(0, good.size() - 1));
        auto r = PackReader::open(bad);
        REQUIRE(!r.ok());
        CHECK(r.error().message.find("incomplete") != std::string::npos);
        CHECK(r.error().hint.find("Export the game again") != std::string::npos);
        write_file(bad, good.substr(0, 16 + B));  // the data stops in the middle: no footer either
        CHECK(!PackReader::open(bad).ok());
    }
    SUBCASE("a flipped byte in a block") {
        std::string flipped = good;
        flipped[std::size_t(16 + B + 5)] ^= 0x40;  // block 2
        write_file(bad, flipped);
        for (bool map : {true, false}) {
            auto opened = PackReader::open(bad, PackOpenOptions{map});
            REQUIRE(opened.ok());  // the index is fine
            auto r = opened.value()->read("a.bin");
            REQUIRE(!r.ok());
            CHECK(r.error().message.find("damaged: block 2 of 3 of 'a.bin' does not match its checksum") != std::string::npos);
            CHECK(r.error().hint.find("Export the game again") != std::string::npos);
            CHECK(opened.value()->read_range("a.bin", 0, 100).ok());  // block 1 is intact and the only one read
            CHECK(!opened.value()->view("a.bin").ok());
        }
    }
    SUBCASE("a flipped byte in the index") {
        std::string flipped = good;
        flipped[flipped.size() - 24 - 10] ^= 0x01;
        write_file(bad, flipped);
        auto r = PackReader::open(bad);
        REQUIRE(!r.ok());
        CHECK(r.error().message.find("index does not match its checksum") != std::string::npos);
    }
    SUBCASE("a wrong block checksum (index checksum still right)") {
        std::string wrong = good;
        // index: count, block size, block count (12), entry of "a.bin" (2 + 5 + 1 + 8 + 8 + 8 + 4 = 36), then the table.
        auto u64 = [&](std::size_t at) {
            std::uint64_t v = 0;
            for (int i = 0; i < 8; ++i) v |= std::uint64_t(std::uint8_t(wrong[at + std::size_t(i)])) << (8 * i);
            return v;
        };
        const std::size_t indexOffset = std::size_t(u64(wrong.size() - 24)), indexSize = std::size_t(u64(wrong.size() - 16));
        const std::size_t firstChecksum = indexOffset + 12 + 36 + 4;
        wrong[firstChecksum] ^= 0x10;
        const std::uint32_t sum = pack_checksum(std::span<const std::uint8_t>(
            reinterpret_cast<const std::uint8_t*>(wrong.data()) + indexOffset, indexSize - 4));
        for (int i = 0; i < 4; ++i) wrong[indexOffset + indexSize - 4 + std::size_t(i)] = char((sum >> (8 * i)) & 0xff);
        write_file(bad, wrong);
        auto opened = PackReader::open(bad);
        REQUIRE(opened.ok());
        auto r = opened.value()->read_range("a.bin", 0, 1);
        REQUIRE(!r.ok());
        CHECK(r.error().message.find("block 1 of 3 of 'a.bin' does not match its checksum") != std::string::npos);
        CHECK(opened.value()->read_range("a.bin", B, 1).ok());
    }
}

TEST_CASE("pack v2: an index that claims more than a block can decode to is refused before anything is allocated") {
    // A hand-made index with right checksums (a tampered pack): one lz4 block of a run of zeros, whose block size and file
    // size are raised to 64 MiB. The reader must refuse it at open (a ~1 KiB lz4 block cannot give 64 MiB), not allocate
    // 64 MiB on read and only then fail to decode.
    Scratch s;
    PackWriter w;
    REQUIRE(w.add_bytes("a.bin", std::vector<std::uint8_t>(std::size_t(B), 0), Codec::Lz4).ok());
    REQUIRE(w.write(s.pak()).ok());
    std::string pak = read_file(s.pak());
    auto u64 = [&](std::size_t at) {
        std::uint64_t v = 0;
        for (int i = 0; i < 8; ++i) v |= std::uint64_t(std::uint8_t(pak[at + std::size_t(i)])) << (8 * i);
        return v;
    };
    auto put = [&](std::size_t at, std::uint64_t v, int n) {
        for (int i = 0; i < n; ++i) pak[at + std::size_t(i)] = char((v >> (8 * i)) & 0xff);
    };
    const std::size_t indexOffset = std::size_t(u64(pak.size() - 24)), indexSize = std::size_t(u64(pak.size() - 16));
    {
        auto opened = PackReader::open(s.pak());
        REQUIRE(opened.ok());
        REQUIRE(opened.value()->codec_of("a.bin") == Codec::Lz4);
        CHECK(opened.value()->stored_size_of("a.bin") < B / 64);
    }
    const std::uint64_t claimed = 64ull << 20;
    put(indexOffset + 4, claimed, 4);                // block size
    put(indexOffset + 12 + 2 + 5 + 1, claimed, 8);  // the size of a.bin (after u16 length, "a.bin", u8 codec)
    put(indexOffset + indexSize - 4,
        pack_checksum(std::span<const std::uint8_t>(reinterpret_cast<const std::uint8_t*>(pak.data()) + indexOffset, indexSize - 4)), 4);
    const stdfs::path bad = s.dir / "bad.pak";
    write_file(bad, pak);
    auto r = PackReader::open(bad);
    REQUIRE(!r.ok());
    CHECK(r.error().message.find("block 1 of 'a.bin' has an impossible size") != std::string::npos);
    CHECK(r.error().hint.find("Export the game again") != std::string::npos);

    // A file bigger than a pack of this size may hold (pack_max_file_size: 256 MiB for a small pack) is refused first.
    CHECK(pack_max_file_size(pak.size()) == kPackMinFileCap);
    CHECK(pack_max_file_size(64ull << 20) == 4096ull << 20);
    CHECK(pack_max_file_size(~std::uint64_t(0)) == ~std::uint64_t(0));
    put(indexOffset + 12 + 2 + 5 + 1, kPackMinFileCap * 2, 8);
    put(indexOffset + indexSize - 4,
        pack_checksum(std::span<const std::uint8_t>(reinterpret_cast<const std::uint8_t*>(pak.data()) + indexOffset, indexSize - 4)), 4);
    write_file(bad, pak);
    auto huge = PackReader::open(bad);
    REQUIRE(!huge.ok());
    CHECK(huge.error().message.find("is damaged ('a.bin' claims 536870912 bytes, more than a pack of") != std::string::npos);
    CHECK(huge.error().hint.find("Export the game again") != std::string::npos);
}

TEST_CASE("pack v2: many threads read one pack at once, mapped and read") {
    Scratch s;
    PackWriter w;
    std::vector<std::vector<std::uint8_t>> contents;
    // Few files and rounds (a loaded CI VM runs it too); the text files cross a block boundary, the noise ones do not.
    constexpr int kFiles = 8, kThreads = 8, kRounds = 4;
    for (int i = 0; i < kFiles; ++i) {
        contents.push_back(i % 2 ? noise_bytes(std::size_t(B / 3 + std::uint64_t(i) * 7919), std::uint32_t(i))
                                 : text_bytes(std::size_t(B + 1000 + i * 37), i));
        REQUIRE(w.add_bytes("d/" + std::to_string(i) + ".json", contents.back(), Codec::Lz4).ok());
    }
    REQUIRE(w.write(s.pak()).ok());
    for (bool map : {true, false}) {
        auto pack = PackReader::open(s.pak(), PackOpenOptions{map});
        REQUIRE(pack.ok());
        std::atomic<int> wrong{0};
        std::vector<std::thread> threads;
        for (int t = 0; t < kThreads; ++t)
            threads.emplace_back([&, t] {
                for (int round = 0; round < kRounds; ++round)
                    for (int i = 0; i < kFiles; ++i) {
                        const int n = (i + t * 5 + round) % kFiles;
                        const auto& want = contents[std::size_t(n)];
                        const std::string path = "d/" + std::to_string(n) + ".json";
                        if ((round + t) % 2) {
                            auto r = pack.value()->read(path);
                            if (!r.ok() || r.value() != want) ++wrong;
                        } else {
                            // Around the end of the first block: ranges of the text files span two blocks.
                            const std::uint64_t from = (B - 2500 + std::uint64_t(round * 997 + t * 131)) % want.size();
                            auto r = pack.value()->read_range(path, from, 5000);
                            const std::size_t l = std::min<std::size_t>(5000, want.size() - std::size_t(from));
                            if (!r.ok() || !std::equal(r.value().begin(), r.value().end(), want.begin() + std::ptrdiff_t(from)) ||
                                r.value().size() != l)
                                ++wrong;
                        }
                    }
            });
        for (auto& th : threads) th.join();
        CHECK(wrong == 0);
        CHECK(pack.value()->counters().reads == std::uint64_t(kThreads * kRounds * kFiles));
    }
}

TEST_CASE("pack v2: FA_PACK_MAP=0 makes every pack read without a mapping") {
    Scratch s;
    PackWriter w;
    REQUIRE(w.add_bytes("a.txt", bytes_of("abc")).ok());
    REQUIRE(w.write(s.pak()).ok());
    set_env("FA_PACK_MAP", "0");
    auto off = PackReader::open(s.pak());
    set_env("FA_PACK_MAP", nullptr);
    REQUIRE(off.ok());
    CHECK(!off.value()->mapped());
    CHECK(off.value()->read("a.txt").value() == bytes_of("abc"));
    auto on = PackReader::open(s.pak());
    REQUIRE(on.ok());
#if !defined(__EMSCRIPTEN__)
    if (sizeof(void*) == 8) CHECK(on.value()->mapped());
#endif
}

TEST_CASE("pack v2: open_memory reads a pack from bytes and refuses damaged ones without crashing") {
    Scratch s;
    PackWriter w;
    const auto big = text_bytes(std::size_t(2 * B + 10), 1);
    REQUIRE(w.add_bytes("a.json", big, Codec::Lz4).ok());
    REQUIRE(w.add_bytes("dir/b.bin", noise_bytes(300, 2), Codec::Store).ok());
    REQUIRE(w.write(s.pak()).ok());
    const std::string good = read_file(s.pak());
    const std::vector<std::uint8_t> bytes(good.begin(), good.end());

    auto opened = PackReader::open_memory(bytes, "download.pak");
    REQUIRE(opened.ok());
    const PackReader& p = *opened.value();
    CHECK(p.file_count() == 2);
    CHECK(p.read("a.json").value() == big);
    CHECK(p.read("dir/b.bin").value() == noise_bytes(300, 2));
    CHECK(p.view("dir/b.bin").ok());
    CHECK(p.read("nope.txt").error().hint.find("download.pak") != std::string::npos);

    // Every prefix and every single flipped byte is an error or a pack whose reads return a result: never a crash.
    CHECK(!PackReader::open_memory({}).ok());
    for (std::size_t n = 0; n < bytes.size(); n += 7) CHECK(!PackReader::open_memory(std::vector<std::uint8_t>(bytes.begin(), bytes.begin() + std::ptrdiff_t(n))).ok());
    for (std::size_t i = 0; i < bytes.size(); i += 5) {
        auto flipped = bytes;
        flipped[i] ^= 0x5A;
        if (auto r = PackReader::open_memory(std::move(flipped)); r.ok())
            for (const std::string& f : r.value()->list("", true)) (void)r.value()->read(f);
    }
}

TEST_CASE("pack v2: views share the mapping and outlive the reader and the mount") {
    Scratch s;
    PackWriter w;
    const auto big = noise_bytes(std::size_t(B + 77), 11);
    REQUIRE(w.add_bytes("assets/big.png", big).ok());  // .png: stored
    REQUIRE(w.add_bytes("scenes/main.scene.json", bytes_of("{\"entities\":[]}")).ok());
    REQUIRE(w.write(s.pak()).ok());
    fs::set_project_root(s.dir);
    REQUIRE(fs::mount_pack(s.pak()).ok());
    auto v = fs::read_view("assets/big.png");
    REQUIRE(v.ok());
#if !defined(__EMSCRIPTEN__)
    if (sizeof(void*) == 8) CHECK(v.value().mapped());
#endif
    fs::unmount_pack();  // the view keeps the pack mapped
    CHECK(v.value().size() == big.size());
    CHECK(v.value().to_vector() == big);

    // Unmapped: the same bytes in a buffer the view owns.
    auto reader = PackReader::open(s.pak(), PackOpenOptions{false});
    REQUIRE(reader.ok());
    auto owned = reader.value()->view("assets/big.png");
    REQUIRE(owned.ok());
    CHECK(!owned.value().mapped());
    reader.value().reset();
    CHECK(owned.value().to_vector() == big);

    // Loose files and warm files.
    fs::unmount_pack();
    {
        std::ofstream(s.dir / "loose.txt", std::ios::binary) << "\xEF\xBB\xBFloose";
    }
    auto loose = fs::read_view("loose.txt");
    REQUIRE(loose.ok());
    CHECK(loose.value().text() == "loose");
    CHECK(!loose.value().mapped());
    REQUIRE(fs::warm("loose.txt").ok());
    const auto reads = fs::disk_reads();
    auto warm = fs::read_view("loose.txt");
    REQUIRE(warm.ok());
    CHECK(warm.value().mapped());  // shares the warm bytes
    CHECK(fs::disk_reads() == reads);
    fs::unwarm_all();
    CHECK(warm.value().text() == "loose");
    auto missing = fs::read_view("loos.txt");
    REQUIRE(!missing.ok());
    CHECK(missing.error().hint.find("loose.txt") != std::string::npos);
}

TEST_CASE("pack v2: the data follows set_order, the index stays sorted, and the bytes do not depend on the add order") {
    Scratch s;
    auto build = [&](bool reversed, const stdfs::path& out) {
        PackWriter w;
        std::vector<std::string> names = {"a.json", "b/c.json", "b/d.png", "e.txt", "z.js"};
        if (reversed) std::reverse(names.begin(), names.end());
        for (const std::string& n : names) REQUIRE(w.add_bytes(n, text_bytes(1000 + n.size() * 100, int(n.size()))).ok());
        w.set_order({"z.js", "missing.json", "b/d.png", "z.js"});
        auto stats = w.write(out);
        REQUIRE(stats.ok());
        CHECK(stats.value().orderedFiles == 2);
    };
    build(false, s.dir / "one.pak");
    build(true, s.dir / "two.pak");
    CHECK(read_file(s.dir / "one.pak") == read_file(s.dir / "two.pak"));
    auto p = PackReader::open(s.dir / "one.pak");
    REQUIRE(p.ok());
    CHECK(p.value()->data_order() == std::vector<std::string>{"z.js", "b/d.png", "a.json", "b/c.json", "e.txt"});
    CHECK(p.value()->list("", true) == std::vector<std::string>{"a.json", "b/c.json", "b/d.png", "e.txt", "z.js"});
}

TEST_CASE("pack v2: under the Windows rules an open pack cannot be replaced, mapped or not, and the old one stays") {
    RulesScope rules(true);
    for (const bool map : {true, false}) {
        CAPTURE(map);
        Scratch s;
        {
            PackWriter w;
            REQUIRE(w.add_bytes("a.txt", bytes_of("old")).ok());
            REQUIRE(w.write(s.pak()).ok());
        }
        auto running = PackReader::open(s.pak(), PackOpenOptions{map});  // a game that runs from the pack
        REQUIRE(running.ok());
        PackWriter again;
        REQUIRE(again.add_bytes("a.txt", bytes_of("new")).ok());
        auto r = again.write(s.pak());
        // Wine renames onto an open file as POSIX does, so only a real Windows (and the emulation) refuses.
        if (!running_under_wine()) {
            REQUIRE(!r.ok());
            CHECK(r.error().message.find("is open in another program") != std::string::npos);
            CHECK(r.error().hint.find("Close the game") != std::string::npos);
            CHECK(!stdfs::exists(s.dir / "game.pak.tmp"));
            CHECK(running.value()->read("a.txt").value() == bytes_of("old"));
        }
        running.value().reset();  // the game quits
        REQUIRE(again.write(s.pak()).ok());
        auto fresh = PackReader::open(s.pak(), PackOpenOptions{map});
        REQUIRE(fresh.ok());
        CHECK(fresh.value()->read("a.txt").value() == bytes_of("new"));
    }
}

TEST_CASE("load trace: reads by scene in first-read order, scene load times, slowest assets") {
    Scratch s;
    fs::set_project_root(s.dir);
    for (const char* f : {"a.json", "b.json", "c.json", "d.json"}) std::ofstream(s.dir / f, std::ios::binary) << "{\"n\":1}";
    CHECK(!LoadTrace::any());
    REQUIRE(fs::read_text("a.json").ok());  // before any trace: not recorded
    {
        LoadTrace trace;
        CHECK(LoadTrace::any());
        REQUIRE(fs::read_text("factoria-free.json").ok() == false);  // a failed read is not recorded
        REQUIRE(fs::read_text("b.json").ok());                      // before the first scene: the start-up group
        trace.scene_started("scenes/one.scene.json");
        REQUIRE(fs::read_text("a.json").ok());
        REQUIRE(fs::read_text("b.json").ok());  // already listed
        {
            AssetLoadScope asset("texture", "c.json");
            REQUIRE(fs::read_view("c.json").ok());
        }
        trace.frame_ended();
        trace.scene_started("scenes/two.scene.json");
        REQUIRE(fs::read_bytes("d.json").ok());
        REQUIRE(fs::read_bytes(fs::path_to_utf8(s.dir / "a.json")).ok());  // an absolute path is a tool's file, not the game's
        trace.scene_started("scenes/one.scene.json");  // loaded again: keeps its place
        REQUIRE(fs::read_bytes("a.json").ok());

        const LoadOrder order = trace.order();
        REQUIRE(order.size() == 3);
        CHECK(order[0].scene == LoadTrace::kStartupScene);
        CHECK(order[0].files == std::vector<std::string>{"b.json"});
        CHECK(order[1].scene == "scenes/one.scene.json");
        CHECK(order[1].files == std::vector<std::string>{"a.json", "c.json"});
        CHECK(order[2].scene == "scenes/two.scene.json");
        CHECK(order[2].files == std::vector<std::string>{"d.json"});

        const Json r = trace.report();
        CHECK(r["timeToFirstFrameMs"].is_number());
        REQUIRE(r["scenes"].size() == 3);
        CHECK(r["scenes"][0]["scene"] == "scenes/one.scene.json");
        CHECK(r["scenes"][0]["loadMs"].is_number());
        CHECK(r["scenes"][0]["files"] == 3);
        CHECK(r["scenes"][1]["loadMs"].is_null());  // no frame ended after it
        REQUIRE(r["slowestAssets"].size() == 1);
        CHECK(r["slowestAssets"][0]["path"] == "c.json");
        CHECK(r["slowestAssets"][0]["kind"] == "texture");
        CHECK(r["slowestAssets"][0]["bytes"] == 7);
        CHECK(r["reads"]["count"] == 6);  // b, a, b, c, d, a: the absolute path is not counted
        CHECK(r["reads"]["fromPack"] == 0);
    }
    CHECK(!LoadTrace::any());
}

TEST_CASE("load trace: a trace with an owner records only the reads made for it, on any thread") {
    Scratch s;
    fs::set_project_root(s.dir);
    for (const char* f : {"mine.json", "editor.json", "other.json", "worker.json", "asset.json"})
        std::ofstream(s.dir / f, std::ios::binary) << "{\"n\":1}";
    // Two engines in one process, each with its token; a token is never handed out twice.
    const LoadTrace::Owner engineA = LoadTrace::new_owner(), engineB = LoadTrace::new_owner();
    CHECK(engineA != LoadTrace::kNoOwner);
    CHECK(engineA != engineB);
    LoadTrace a(engineA), b(engineB);
    CHECK(LoadTrace::current_owner() == LoadTrace::kNoOwner);
    REQUIRE(fs::read_text("editor.json").ok());  // the editor's own read: nobody's
    {
        LoadTrace::ReadingFor reading(engineA);
        CHECK(LoadTrace::current_owner() == engineA);
        REQUIRE(fs::read_text("mine.json").ok());
        {
            LoadTrace::ReadingFor nested(engineB);  // another engine runs inside (an in-process play.auto)
            REQUIRE(fs::read_text("other.json").ok());
        }
        CHECK(LoadTrace::current_owner() == engineA);
        // A job handed to a worker thread takes its owner along (what a background loader does). The worker only
        // collects; the checks run on this thread (doctest's REQUIRE must not throw on another one).
        const LoadTrace::Owner owner = LoadTrace::current_owner();
        LoadTrace::Owner workerOwnerAtStart = owner;
        bool workerReadsOk = false;
        std::thread worker([&, owner] {
            workerOwnerAtStart = LoadTrace::current_owner();
            LoadTrace::ReadingFor onWorker(owner);
            const bool text = fs::read_text("worker.json").ok();
            AssetLoadScope asset("texture", "asset.json");
            workerReadsOk = text && fs::read_bytes("asset.json").ok();
        });
        worker.join();
        CHECK(workerOwnerAtStart == LoadTrace::kNoOwner);  // a thread is never an owner by itself
        CHECK(workerReadsOk);
    }
    {
        // A read for an engine that is gone (a loader thread finishing late) is nobody's, even when a new engine came.
        const LoadTrace::Owner gone = LoadTrace::new_owner();
        LoadTrace::ReadingFor late(gone);
        REQUIRE(fs::read_text("editor.json").ok());
    }
    CHECK(LoadTrace::current_owner() == LoadTrace::kNoOwner);
    const LoadOrder orderA = a.order();
    REQUIRE(orderA.size() == 1);
    CHECK(orderA[0].files == std::vector<std::string>{"mine.json", "worker.json", "asset.json"});
    REQUIRE(b.order().size() == 1);
    CHECK(b.order()[0].files == std::vector<std::string>{"other.json"});
    CHECK(a.report()["slowestAssets"].size() == 1);
    CHECK(b.report()["slowestAssets"].size() == 0);
}

TEST_CASE("load trace: reads from a mounted pack say so") {
    Scratch s;
    PackWriter w;
    REQUIRE(w.add_bytes("x.json", text_bytes(5000)).ok());
    REQUIRE(w.write(s.pak()).ok());
    REQUIRE(fs::mount_pack(s.pak()).ok());
    LoadTrace trace;
    REQUIRE(fs::read_bytes("x.json").ok());
    const Json r = trace.report();
    CHECK(r["reads"]["fromPack"] == 1);
    CHECK(r["reads"]["bytes"] == 5000);
    CHECK(r["reads"]["packStoredBytes"].get<std::uint64_t>() <= 5000);
}
