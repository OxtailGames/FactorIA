// DirectStorage reads of game.pak (engine/core/src/pack_direct_storage.h): the plan of the requests and their batches
// (pure, every platform) and, on Windows x64, a gdeflate pack read through dstorage.dll when it is there.
#include <doctest.h>

#include <algorithm>
#include <cstdint>
#include <cstdlib>
#include <filesystem>
#include <string>
#include <system_error>
#include <utility>
#include <vector>

#include "../src/pack_direct_storage.h"
#include "fa/core/compress.h"
#include "fa/core/fs.h"
#include "fa/core/pack.h"

using namespace fa;
using namespace fa::detail;
namespace stdfs = std::filesystem;

namespace {

constexpr std::uint64_t B = 256 * 1024;

// `count` blocks laid one after another from offset 16, each `stored` bytes; every third one raw.
std::vector<DirectBlock> blocks_of(std::size_t count, std::uint32_t stored = 1000) {
    std::vector<DirectBlock> out;
    std::uint64_t offset = 16;
    for (std::size_t k = 0; k < count; ++k) {
        out.push_back(DirectBlock{offset, stored, k % 3 == 2});
        offset += stored;
    }
    return out;
}

}  // namespace

TEST_CASE("directstorage: a whole file is one request per block, straight into the caller's buffer") {
    const auto blocks = blocks_of(4);
    const std::uint64_t size = 3 * B + 5;
    const auto r = plan_direct_requests(blocks, B, size, 0, size);
    REQUIRE(r.size() == 4);
    for (std::size_t k = 0; k < 4; ++k) {
        CAPTURE(k);
        CHECK(r[k].block == k);
        CHECK(r[k].fileOffset == blocks[k].offset);
        CHECK(r[k].storedSize == blocks[k].stored);
        CHECK(r[k].compressed == !blocks[k].raw);
        CHECK(r[k].scratch == -1);
        CHECK(r[k].outOffset == k * B);
        CHECK(r[k].copyLength == r[k].decodedSize);
    }
    CHECK(r[0].decodedSize == B);
    CHECK(r[3].decodedSize == 5);  // the last block holds what is left of the file
    CHECK(!r[2].compressed);       // a raw block is a plain read
}

TEST_CASE("directstorage: the partial first and last blocks of a range go through the two scratch buffers") {
    const auto blocks = blocks_of(4);
    const std::uint64_t size = 3 * B + 5;
    SUBCASE("across two blocks") {
        const auto r = plan_direct_requests(blocks, B, size, B + 10, B);
        REQUIRE(r.size() == 2);
        CHECK(r[0].block == 1);
        CHECK(r[0].scratch == 0);
        CHECK(r[0].copyFrom == 10);
        CHECK(r[0].copyLength == B - 10);
        CHECK(r[0].outOffset == 0);
        CHECK(r[0].decodedSize == B);  // the whole block is decoded, its part copied
        CHECK(r[1].block == 2);
        CHECK(r[1].scratch == 1);
        CHECK(r[1].copyFrom == 0);
        CHECK(r[1].copyLength == 10);
        CHECK(r[1].outOffset == B - 10);
    }
    SUBCASE("inside one block") {
        const auto r = plan_direct_requests(blocks, B, size, 5, 10);
        REQUIRE(r.size() == 1);
        CHECK(r[0].scratch == 0);
        CHECK(r[0].copyFrom == 5);
        CHECK(r[0].copyLength == 10);
        CHECK(r[0].outOffset == 0);
    }
    SUBCASE("whole blocks in the middle need no scratch") {
        const auto r = plan_direct_requests(blocks, B, size, B / 2, 2 * B);
        REQUIRE(r.size() == 3);
        CHECK(r[0].scratch == 0);
        CHECK(r[1].scratch == -1);
        CHECK(r[1].outOffset == B / 2);
        CHECK(r[2].scratch == 1);
        CHECK(r[2].copyLength == B / 2);
    }
    SUBCASE("a range that starts at a block and runs to the end of the file is whole blocks") {
        const auto r = plan_direct_requests(blocks, B, size, 2 * B, B + 5);
        REQUIRE(r.size() == 2);
        CHECK(r[0].scratch == -1);
        CHECK(r[1].scratch == -1);
        CHECK(r[1].decodedSize == 5);
    }
}

TEST_CASE("directstorage: empty ranges, ranges past the end and an index that is too short plan nothing") {
    const auto blocks = blocks_of(2);
    CHECK(plan_direct_requests(blocks, B, B + 3, 0, 0).empty());
    CHECK(plan_direct_requests(blocks, B, B + 3, B + 3, 10).empty());
    CHECK(plan_direct_requests(blocks, 0, B + 3, 0, 10).empty());
    CHECK(plan_direct_requests(blocks, B, 5 * B, 0, 5 * B).empty());  // block 4 is not in the index
    const auto clamped = plan_direct_requests(blocks, B, B + 3, B, 1000);
    REQUIRE(clamped.size() == 1);
    CHECK(clamped[0].copyLength == 3);
}

TEST_CASE("directstorage: batches hold at most the queue's room and the staging buffer's bytes") {
    std::vector<DirectRequest> big(600), small(600);
    for (auto& r : big) r.decodedSize = std::uint32_t(B);
    for (auto& r : small) r.decodedSize = 1024;
    const auto byBytes = batch_direct_requests(big, kDirectBatchRequests, kDirectBatchBytes);
    REQUIRE(byBytes.size() == 5);  // 32 MiB / 256 KiB = 128 blocks a batch
    CHECK(byBytes[0].first == 0);
    CHECK(byBytes[0].count == 128);
    CHECK(byBytes[0].decodedBytes == kDirectBatchBytes);
    CHECK(byBytes[4].first == 512);
    CHECK(byBytes[4].count == 88);
    const auto byCount = batch_direct_requests(small, kDirectBatchRequests, kDirectBatchBytes);
    REQUIRE(byCount.size() == 3);
    CHECK(byCount[0].count == kDirectBatchRequests);
    CHECK(byCount[1].first == kDirectBatchRequests);
    CHECK(byCount[2].count == 600 - 2 * kDirectBatchRequests);
    // A request larger than the byte limit makes a batch of its own; a limit of 0 requests counts as 1.
    const auto alone = batch_direct_requests(big, 10, 1000);
    CHECK(alone.size() == 600);
    CHECK(batch_direct_requests(small, 0, kDirectBatchBytes).size() == 600);
    CHECK(batch_direct_requests({}, 10, 1000).empty());
    CHECK(kDirectBatchRequests + 2 <= kDirectQueueCapacity);  // room for the status and the event of a batch
}

#if defined(_WIN32) && defined(_WIN64)
TEST_CASE("directstorage: a gdeflate pack is read through DirectStorage, whole files and ranges (Windows x64)") {
    // dstorage.dll and dstoragecore.dll from FA_DIRECTSTORAGE_DIR or next to the test (`factoria setup directstorage`).
    // Skipped without them; a failure with FA_DIRECTSTORAGE_REQUIRE=1 (the Windows CI job).
    if (auto ok = direct_storage_available(); !ok.ok()) {
        const char* require = std::getenv("FA_DIRECTSTORAGE_REQUIRE");
        if (require && std::string(require) == "1") FAIL(ok.error().to_string());
        MESSAGE("skipped: " << ok.error().to_string());
        return;
    }
    struct Scratch {
        stdfs::path dir = fs::make_temp_dir("fa_test_dstorage").value();
        ~Scratch() {
            std::error_code ec;
            stdfs::remove_all(dir, ec);
        }
    } s;
    // Text compresses (gdeflate blocks); the noise in "mixed" keeps some blocks raw inside a gdeflate file.
    auto text = [](std::size_t n, std::uint32_t seed) {
        std::vector<std::uint8_t> b(n);
        std::uint32_t x = seed;
        for (std::size_t i = 0; i < n; ++i) {
            x = x * 1664525u + 1013904223u;
            b[i] = std::uint8_t("abcdefgh  \n"[(x >> 24) % 11]);
        }
        return b;
    };
    auto noise = [](std::size_t n, std::uint32_t seed) {
        std::vector<std::uint8_t> b(n);
        std::uint32_t x = seed;
        for (auto& v : b) v = std::uint8_t((x = x * 1664525u + 1013904223u) >> 24);
        return b;
    };
    std::vector<std::pair<std::string, std::vector<std::uint8_t>>> files;
    files.emplace_back("a/small.json", text(1000, 1));
    files.emplace_back("a/block.json", text(std::size_t(B), 2));
    files.emplace_back("a/large.json", text(std::size_t(140 * B + 17), 3));  // more than one batch
    auto mixed = text(std::size_t(3 * B), 4);
    const auto n = noise(std::size_t(B), 5);
    std::copy(n.begin(), n.end(), mixed.begin() + std::ptrdiff_t(B));  // block 2 of 3 does not compress
    files.emplace_back("a/mixed.bin", mixed);
    PackWriter w;
    for (const auto& [path, data] : files) REQUIRE(w.add_bytes(path, data, Codec::GDeflate).ok());
    auto stats = w.write(s.dir / "game.pak");
    REQUIRE_MESSAGE(stats.ok(), (stats.ok() ? "" : stats.error().to_string()));
    CHECK(stats.value().blocksKeptRaw >= 1);

    for (bool map : {true, false}) {
        CAPTURE(map);
        auto opened = PackReader::open(s.dir / "game.pak", PackOpenOptions{map});
        REQUIRE_MESSAGE(opened.ok(), (opened.ok() ? "" : opened.error().to_string()));
        const PackReader& p = *opened.value();
        for (const auto& [path, want] : files) {
            CAPTURE(path);
            CHECK(p.codec_of(path) == Codec::GDeflate);
            auto all = p.read(path);
            REQUIRE_MESSAGE(all.ok(), (all.ok() ? "" : all.error().to_string()));
            CHECK(all.value() == want);
            const std::size_t from = want.size() / 3,
                              len = std::min<std::size_t>(std::size_t(B) + 777, want.size() - from);
            auto part = p.read_range(path, from, len);
            REQUIRE(part.ok());
            CHECK(part.value() == std::vector<std::uint8_t>(want.begin() + std::ptrdiff_t(from),
                                                            want.begin() + std::ptrdiff_t(from + len)));
        }
        std::uint64_t blocks = 0;
        for (const auto& [path, want] : files) blocks += (want.size() + B - 1) / B;
        CHECK(p.counters().directBlocks >= blocks);  // every whole-file read went through DirectStorage
    }
}
#endif
