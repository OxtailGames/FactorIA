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

#include "../src/direct_storage/pack_direct_storage.h"
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
    // A full batch, its status and its event fill an empty queue, which holds one entry less than its capacity.
    DirectQueueRoom room(kDirectQueueCapacity);
    CHECK(room.free_entries() == kDirectQueueCapacity - 1);
    CHECK(room.take(kDirectBatchRequests));
    CHECK(room.free_entries() == 0);
    CHECK(!room.take(0));  // even an empty submission takes its status and its event
    room.give(kDirectBatchRequests);
    CHECK(room.free_entries() == kDirectQueueCapacity - 1);
    CHECK(!room.take(kDirectBatchRequests + 1));  // too big for the queue: nothing taken
    CHECK(room.free_entries() == kDirectQueueCapacity - 1);
    CHECK(room.take(10));
    CHECK(room.take(10));
    CHECK(room.free_entries() == kDirectQueueCapacity - 1 - 2 * direct_queue_entries(10));
    CHECK(DirectQueueRoom(kDirectGpuQueueCapacity).take(kDirectGpuReadRequests));
}

TEST_CASE("directstorage: a read into a GPU buffer sends whole blocks to DirectStorage, partial ones to the CPU") {
    const auto blocks = blocks_of(5);
    const std::uint64_t size = 4 * B + 100;
    SUBCASE("a whole file is all GPU") {
        const auto r = plan_direct_requests(blocks, B, size, 0, size);
        const auto split = split_direct_buffer(r);
        CHECK(split.gpu == std::vector<std::size_t>{0, 1, 2, 3, 4});
        CHECK(split.cpu.empty());
    }
    SUBCASE("a range with partial ends") {
        const auto r = plan_direct_requests(blocks, B, size, B / 2, 3 * B);
        const auto split = split_direct_buffer(r);
        REQUIRE(r.size() == 4);
        CHECK(split.gpu == std::vector<std::size_t>{1, 2});
        REQUIRE(split.cpu.size() == 2);
        CHECK(split.cpu[0].outOffset == 0);
        CHECK(split.cpu[0].length == B / 2);
        CHECK(split.cpu[1].outOffset == 3 * B - B / 2);
        CHECK(split.cpu[1].length == B / 2);
    }
    SUBCASE("a range inside one block is all CPU") {
        const auto split = split_direct_buffer(plan_direct_requests(blocks, B, size, 7, 50));
        CHECK(split.gpu.empty());
        REQUIRE(split.cpu.size() == 1);
        CHECK(split.cpu[0].outOffset == 0);
        CHECK(split.cpu[0].length == 50);
    }
    CHECK(split_direct_buffer({}).gpu.empty());
}

TEST_CASE("directstorage: texture regions are laid out as D3D12's copyable footprint") {
    CHECK(direct_texture_pitch(1) == 256);
    CHECK(direct_texture_pitch(256) == 256);
    CHECK(direct_texture_pitch(257) == 512);
    CHECK(direct_texture_pitch(0) == 0);
    CHECK(direct_texture_bytes(100, 1) == 100);  // one row: unpadded
    CHECK(direct_texture_bytes(100, 3) == 2 * 256 + 100);
    CHECK(direct_texture_bytes(1024, 4) == 4096);  // rows of a multiple of 256: no padding
    CHECK(direct_texture_bytes(0, 4) == 0);
    CHECK(direct_texture_bytes(100, 0) == 0);
}

TEST_CASE("directstorage: a texture region goes to DirectStorage only when every block holds whole rows") {
    const auto blocks = blocks_of(8);
    SUBCASE("64 texels of RGBA8 a row: 1024 rows a block") {
        const std::uint32_t rowBytes = 256, rows = 2048 + 10;  // two whole blocks and a short last one
        const std::uint64_t size = direct_texture_bytes(rowBytes, rows);
        const auto r = plan_direct_requests(blocks, B, size, 0, size);
        const auto spans = plan_direct_texture_rows(r, rowBytes, rows);
        REQUIRE(spans.size() == 3);
        CHECK(spans[0].firstRow == 0);
        CHECK(spans[0].rowCount == 1024);
        CHECK(spans[1].firstRow == 1024);
        CHECK(spans[2].firstRow == 2048);
        CHECK(spans[2].rowCount == 10);
    }
    SUBCASE("a region in one block, padded rows") {
        const std::uint32_t rowBytes = 40, rows = 10;  // 10 x 10 RGBA8
        const std::uint64_t size = direct_texture_bytes(rowBytes, rows);
        const auto r = plan_direct_requests(blocks, B, size, 0, size);
        const auto spans = plan_direct_texture_rows(r, rowBytes, rows);
        REQUIRE(spans.size() == 1);
        CHECK(spans[0].rowCount == 10);
    }
    SUBCASE("padded rows across blocks: the CPU path") {
        const std::uint32_t rowBytes = 40, rows = 2000;  // 2000 rows 256 bytes apart: two blocks
        const std::uint64_t size = direct_texture_bytes(rowBytes, rows);
        CHECK(plan_direct_texture_rows(plan_direct_requests(blocks, B, size, 0, size), rowBytes, rows).empty());
    }
    SUBCASE("rows that straddle a block: the CPU path") {
        const std::uint32_t rowBytes = 768, rows = 400;  // 256 KiB is not a whole number of 768-byte rows
        const std::uint64_t size = direct_texture_bytes(rowBytes, rows);
        CHECK(plan_direct_texture_rows(plan_direct_requests(blocks, B, size, 0, size), rowBytes, rows).empty());
    }
    SUBCASE("a region that does not start at a block: the CPU path") {
        const std::uint32_t rowBytes = 256, rows = 16;
        const std::uint64_t size = direct_texture_bytes(rowBytes, rows);
        CHECK(plan_direct_texture_rows(plan_direct_requests(blocks, B, 4 * B, 512, size), rowBytes, rows).empty());
    }
    SUBCASE("a region shorter than the bytes (the file holds more than the region): the CPU path") {
        const std::uint32_t rowBytes = 256, rows = 16;
        const auto r = plan_direct_requests(blocks, B, 4 * B, 0, B);  // a whole block, 1024 rows
        CHECK(plan_direct_texture_rows(r, rowBytes, rows).empty());
    }
    CHECK(plan_direct_texture_rows({}, 256, 4).empty());
}

TEST_CASE("directstorage: the block limit of a read into a GPU resource holds for DirectStorage reads only") {
    // 600 MiB of a file: 2400 blocks, more than one DirectStorage submission holds.
    const std::uint64_t size = std::uint64_t(600) << 20;
    const auto blocks = blocks_of(std::size_t(size / B));
    const auto r = plan_direct_requests(blocks, B, size, 0, size);
    REQUIRE(r.size() == 2400);
    CHECK_FALSE(direct_gpu_read_fits(r.size(), true));  // DirectStorage would take it: split it
    CHECK(direct_gpu_read_fits(r.size(), false));       // the CPU fallback (lz4, a pack in memory) reads it whole
    CHECK(direct_gpu_read_fits(kDirectGpuReadRequests, true));
    CHECK_FALSE(direct_gpu_read_fits(kDirectGpuReadRequests + 1, true));
}

TEST_CASE("directstorage: a read's wait probes a status that says complete, warns, cancels, then aborts") {
    SUBCASE("a status that says complete without the event: a probe at once, once") {
        DirectWait w;
        CHECK(direct_wait_step(w, 1000, false) == DirectWaitStep::Wait);
        CHECK(direct_wait_step(w, 2000, true) == DirectWaitStep::Probe);
        CHECK(direct_wait_step(w, 3000, true) == DirectWaitStep::Wait);  // the probe is in the queue
        w.probed = false;  // what the read does when the queue had no room for the probe
        CHECK(direct_wait_step(w, 4000, true) == DirectWaitStep::Probe);
    }
    SUBCASE("a read that never ends: one warning, one cancellation, then the abort") {
        DirectWait w;
        CHECK(direct_wait_step(w, kDirectWarnMs - 1, false) == DirectWaitStep::Wait);
        CHECK(direct_wait_step(w, kDirectWarnMs, false) == DirectWaitStep::Warn);
        CHECK(direct_wait_step(w, kDirectWarnMs + 1000, false) == DirectWaitStep::Wait);
        CHECK(direct_wait_step(w, kDirectGiveUpMs, false) == DirectWaitStep::Cancel);
        CHECK(direct_wait_step(w, 2 * std::uint64_t(kDirectGiveUpMs) - 1, false) == DirectWaitStep::Wait);
        CHECK(direct_wait_step(w, 2 * std::uint64_t(kDirectGiveUpMs), false) == DirectWaitStep::Abort);
    }
    SUBCASE("the warning comes before the probe when both are due; the probe follows a second later") {
        DirectWait w;
        CHECK(direct_wait_step(w, kDirectWarnMs, true) == DirectWaitStep::Warn);
        CHECK(direct_wait_step(w, kDirectWarnMs + 1000, true) == DirectWaitStep::Probe);
    }
    SUBCASE("a probe a full queue puts off every second still lets the warning, the cancellation and the abort come") {
        DirectWait w;
        bool warned = false, cancelled = false, aborted = false;
        for (std::uint64_t ms = 1000; ms <= 2 * std::uint64_t(kDirectGiveUpMs) + 1000 && !aborted; ms += 1000) {
            const DirectWaitStep step = direct_wait_step(w, ms, true);
            warned = warned || step == DirectWaitStep::Warn;
            cancelled = cancelled || step == DirectWaitStep::Cancel;
            aborted = step == DirectWaitStep::Abort;
            if (step == DirectWaitStep::Probe) w.probed = false;  // the queue had no room for it
        }
        CHECK(warned);
        CHECK(cancelled);
        CHECK(aborted);
    }
}

TEST_CASE("directstorage: a read ends with its status entry, and an event before the status is an error") {
    CHECK(direct_read_result(true, 0, "S_OK").ok());
    const auto failed = direct_read_result(true, std::int32_t(0x80070026u), "0x80070026");  // ERROR_HANDLE_EOF
    REQUIRE_FALSE(failed.ok());
    CHECK(failed.error().message.find("0x80070026") != std::string::npos);
    // The event (or the probe) came, enqueued after the status, and the entry is still not complete.
    const auto early = direct_read_result(false, std::int32_t(0x80004005u), "E_FAIL");
    REQUIRE_FALSE(early.ok());
    CHECK(early.error().message.find("before it wrote the read's status entry") != std::string::npos);
    CHECK(early.error().hint.find("factoria setup directstorage") != std::string::npos);
}

TEST_CASE("directstorage: with every status slot retired a read fails with an error that says what to do") {
    DirectSlotRetirement slots(3);
    CHECK_FALSE(slots.exhausted());
    slots.retire();
    slots.retire();
    CHECK_FALSE(slots.exhausted());  // one slot left: reads still wait for it
    slots.retire();
    CHECK(slots.exhausted());
    CHECK(slots.retired() == 3);
    slots.retire();  // never counts past the slots
    CHECK(slots.retired() == 3);
    const Error e = direct_slots_exhausted_error(32);
    CHECK(e.message.find("all 32 status slots") != std::string::npos);
    CHECK(e.message.find("are retired") != std::string::npos);
    CHECK(e.message.find("game.pak") == std::string::npos);  // any pack, whatever its name (pack.cpp names it)
    CHECK(e.hint.find("FA_DIRECTSTORAGE=0") != std::string::npos);
    CHECK(e.hint.find("read on the CPU") != std::string::npos);
}

TEST_CASE("directstorage: a texture request's box is whole 4x4 blocks of a compressed mip's physical size") {
    SUBCASE("a 2x2 mip of BC1: one block row of one 8-byte block, the box 0..4 x 0..4") {
        const std::vector<DirectBlock> blocks{{16, 8, true}};
        const auto r = plan_direct_requests(blocks, B, 8, 0, 8);
        const auto spans = plan_direct_texture_rows(r, 8, 1);
        REQUIRE(spans.size() == 1);
        const DirectTextureBox box = direct_texture_box(0, 0, 2, 2, spans[0], true);
        CHECK(box.left == 0);
        CHECK(box.top == 0);
        CHECK(box.right == 4);
        CHECK(box.bottom == 4);
    }
    SUBCASE("a region that reaches the edge of a 12x6 mip at (4, 4): the box ends at 12 x 8") {
        const DirectTextureBox box = direct_texture_box(4, 4, 8, 2, DirectRowSpan{0, 1}, true);
        CHECK(box.left == 4);
        CHECK(box.right == 12);
        CHECK(box.top == 4);
        CHECK(box.bottom == 8);
    }
    SUBCASE("block rows split over requests: each box starts on its own block row") {
        const DirectTextureBox second = direct_texture_box(0, 8, 64, 2050, DirectRowSpan{256, 257}, true);
        CHECK(second.top == 8 + 256 * 4);
        CHECK(second.bottom == 8 + 2052);  // the last block row, rounded up to whole blocks
    }
    SUBCASE("an uncompressed format: the texels as they are") {
        const DirectTextureBox box = direct_texture_box(3, 5, 7, 9, DirectRowSpan{2, 4}, false);
        CHECK(box.left == 3);
        CHECK(box.right == 10);
        CHECK(box.top == 7);
        CHECK(box.bottom == 11);
    }
}

TEST_CASE("directstorage: a pack tells where a range's blocks lie and checks their stored bytes") {
    struct Scratch {
        stdfs::path dir = fs::make_temp_dir("fa_test_dstorage_layout").value();
        ~Scratch() {
            std::error_code ec;
            stdfs::remove_all(dir, ec);
        }
    } s;
    std::vector<std::uint8_t> data(std::size_t(3 * B + 50));
    std::uint32_t x = 7;
    for (auto& v : data) v = std::uint8_t("abcdefgh  \n"[((x = x * 1664525u + 1013904223u) >> 24) % 11]);
    PackWriter w;
    REQUIRE(w.add_bytes("a/data.bin", data, Codec::GDeflate).ok());
    REQUIRE(w.add_bytes("a/plain.txt", std::vector<std::uint8_t>(10, 'x'), Codec::Store).ok());
    REQUIRE(w.write(s.dir / "game.pak").ok());
    auto opened = PackReader::open(s.dir / "game.pak");
    REQUIRE(opened.ok());
    const PackReader& p = *opened.value();

    auto layout = p.range_layout("a/data.bin", B + 10, B);
    REQUIRE(layout.ok());
    const auto& l = layout.value();
    CHECK(l.packFile == s.dir / "game.pak");
    CHECK(l.codec == Codec::GDeflate);
    CHECK(l.fileSize == data.size());
    CHECK(l.offset == B + 10);
    CHECK(l.size == B);
    CHECK(l.blockSize == B);
    CHECK(l.firstBlock == 1);
    REQUIRE(l.blocks.size() == 2);
    CHECK(l.blocks[0].offset < l.blocks[1].offset);
    CHECK(!l.blocks[0].raw);

    auto clamped = p.range_layout("a/data.bin", 3 * B, 1000);
    REQUIRE(clamped.ok());
    CHECK(clamped.value().size == 50);
    CHECK(clamped.value().blocks.size() == 1);
    CHECK(p.range_layout("a/data.bin", data.size(), 10).value().blocks.empty());
    auto missing = p.range_layout("a/date.bin", 0, 1);
    REQUIRE(!missing.ok());
    CHECK(missing.error().to_string().find("a/data.bin") != std::string::npos);  // did you mean

    CHECK(p.check_stored("a/data.bin", 0, data.size()).ok());
    CHECK(p.check_stored("a/plain.txt", 0, 10).ok());
    // A damaged stored byte: check_stored names the file and the block.
    auto bytes = fs::read_bytes(fs::path_to_utf8(s.dir / "game.pak"));
    REQUIRE(bytes.ok());
    std::vector<std::uint8_t> damaged = bytes.value();
    damaged[std::size_t(l.blocks[1].offset) + 3] ^= 0x5a;
    auto memory = PackReader::open_memory(std::move(damaged));
    REQUIRE(memory.ok());
    CHECK(memory.value()->range_layout("a/data.bin", 0, 1).value().packFile.empty());
    CHECK(memory.value()->check_stored("a/data.bin", 0, B).ok());  // block 1 only
    auto bad = memory.value()->check_stored("a/data.bin", 0, data.size());
    REQUIRE(!bad.ok());
    CHECK(bad.error().to_string().find("a/data.bin") != std::string::npos);
    CHECK(bad.error().to_string().find("block 3") != std::string::npos);

    const auto before = p.counters();
    p.count_external(100, 40, 2);
    CHECK(p.counters().reads == before.reads + 1);
    CHECK(p.counters().bytes == before.bytes + 100);
    CHECK(p.counters().storedBytes == before.storedBytes + 40);
    CHECK(p.counters().directBlocks == before.directBlocks + 2);
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
