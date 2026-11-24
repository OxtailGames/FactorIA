// The D3D12 backend's pack reads into buffers and textures (src/gpu/d3d12_pack_reads_win32.cpp, M77-P11b2). On Windows
// every case makes a WARP device with the debug layer. With the DirectStorage DLLs (`factoria setup directstorage`,
// FA_DIRECTSTORAGE_DIR) the gdeflate cases check that DirectStorage wrote the resource; without them they check the CPU
// fallback's bytes and say so (MESSAGE), or fail with FA_DIRECTSTORAGE_REQUIRE=1 (the Windows CI job). A runtime that
// loaded but refuses the WARP device (its queue, the file or a request) is a MESSAGE even then. The fallback
// cases (a pack in memory, an lz4 file, a texture region whose rows do not fill whole blocks) run everywhere D3D12 does.
// Elsewhere one case checks the footprint the Windows texture case lays its pack out with.
#include <doctest.h>

#include <algorithm>
#include <cstdint>
#include <cstdlib>
#include <filesystem>
#include <memory>
#include <string>
#include <system_error>
#include <utility>
#include <vector>

#include "../../core/src/direct_storage/pack_direct_storage.h"
#include "fa/core/compress.h"
#include "fa/core/fs.h"
#include "fa/core/pack.h"
#include "gpu/d3d12_device.h"

using namespace fa::gpu;

namespace {

constexpr std::uint64_t B = fa::kPackBlockSize;

// Bytes that GDeflate compresses (text-like): the pack keeps its blocks compressed.
[[maybe_unused]] std::vector<std::uint8_t> text(std::size_t n, std::uint32_t seed) {
    std::vector<std::uint8_t> b(n);
    std::uint32_t x = seed * 2654435761u + 1u;
    for (auto& v : b) v = std::uint8_t("abcdefgh  \n"[((x = x * 1664525u + 1013904223u) >> 24) % 11]);
    return b;
}

}  // namespace

TEST_CASE("d3d12 pack reads: a 64-texel RGBA8 region is whole 256-byte rows in whole blocks") {
    using namespace fa::detail;
    // The Windows texture case: 64x2048 RGBA8, rows of 256 bytes (no padding), two blocks of 1024 rows each.
    CHECK(direct_texture_pitch(256) == 256);
    CHECK(direct_texture_bytes(256, 2048) == 2 * B);
    std::vector<DirectBlock> blocks{{16, 1000, false}, {1016, 1000, false}};
    const auto requests = plan_direct_requests(blocks, B, 2 * B, 0, 2 * B);
    const auto spans = plan_direct_texture_rows(requests, 256, 2048);
    REQUIRE(spans.size() == 2);
    CHECK(spans[1].firstRow == 1024);
    CHECK(spans[1].rowCount == 1024);
    // 60 texels (240-byte rows, 256 apart) over two blocks: the padding after a block's last row is in no block.
    const std::uint64_t padded = direct_texture_bytes(240, 2048);
    const auto paddedRequests = plan_direct_requests(blocks, B, padded, 0, padded);
    CHECK(plan_direct_texture_rows(paddedRequests, 240, 2048).empty());
}

#if defined(_WIN32)

using fa::gpu::d3d12::D3d12Device;
using fa::gpu::d3d12::PackImageRegion;
using fa::gpu::d3d12::PackReadResult;
using fa::gpu::d3d12::PackReadTicket;
using fa::gpu::d3d12::PackSource;

namespace {

bool contains(const std::string& s, const std::string& part) { return s.find(part) != std::string::npos; }

std::unique_ptr<D3d12Device> make_warp() {
    D3d12Options o;
    o.warp = true;
    o.debugLayer = true;
    auto d = D3d12Device::create(o);
    if (!d) {
        MESSAGE("d3d12: skipped, no WARP device: " << d.error().to_string());
        return nullptr;
    }
    return std::move(d.value());
}

std::string layer_errors(D3d12Device& dev) {
    std::string s;
    for (const std::string& e : dev.errors())
        if (contains(e, "debug layer")) s += e + "\n";
    return s;
}

// True when a read that could go to DirectStorage did not, and says why; the case then checks the CPU fallback's
// bytes instead of DirectStorage's counters. FA_DIRECTSTORAGE_REQUIRE=1 (the Windows CI job) fails only when the
// runtime itself is missing (the DLLs, the factory or its memory queue did not load): a runtime that loaded but did
// not write this WARP device's resource (its D3D12 queue, the file or a request refused) is a MESSAGE, since WARP is not
// a GPU DirectStorage has to serve; the Windows CI job greps its first words ("DirectStorage loaded but did not write
// this WARP device") and turns it into a ::warning, so keep them.
bool direct_missing(D3d12Device& dev) {
    const std::string why = dev.pack_reads_direct_why();
    if (why.empty()) return false;
    std::string runtimeWhy = "DirectStorage needs a 64-bit build";
#if defined(_WIN64)
    const auto available = fa::detail::direct_storage_available();
    runtimeWhy = available.ok() ? std::string() : available.error().to_string();
#endif
    if (!runtimeWhy.empty()) {
        const char* require = std::getenv("FA_DIRECTSTORAGE_REQUIRE");
        if (require && std::string(require) == "1")
            FAIL("DirectStorage did not write the resource, its runtime did not load: " << runtimeWhy);
        MESSAGE("DirectStorage not used (the CPU fallback was checked instead): " << why);
    } else {
        MESSAGE("DirectStorage loaded but did not write this WARP device's resource (the CPU fallback was checked "
                "instead): "
                << why);
    }
    return true;
}

struct Scratch {
    std::filesystem::path dir = fa::fs::make_temp_dir("fa_test_d3d12_pack").value();
    ~Scratch() {
        std::error_code ec;
        std::filesystem::remove_all(dir, ec);
    }
};

// Waits for the read (bounded) and returns how it went.
PackReadResult finish(D3d12Device& dev, PackReadTicket t) {
    PackReadResult r;
    REQUIRE(t.valid());
    REQUIRE(dev.poll_pack_read(t, r, true));
    CHECK_MESSAGE(r.error.empty(), r.error);
    return r;
}

}  // namespace

TEST_CASE("d3d12 pack reads: a gdeflate range fills a buffer, whole blocks through DirectStorage") {
    Scratch s;  // removed after the device, which may hold the pack's DirectStorage file open until it goes
    auto dev = make_warp();
    if (!dev) return;
    const std::vector<std::uint8_t> data = text(std::size_t(4 * B + 1000), 1);
    fa::PackWriter w;
    REQUIRE(w.add_bytes("a/data.bin", data, fa::Codec::GDeflate).ok());
    REQUIRE(w.write(s.dir / "game.pak").ok());
    auto pack = fa::PackReader::open(s.dir / "game.pak");
    REQUIRE(pack.ok());

    // From the middle of block 0 to the middle of block 3: two whole blocks, two partial ones, at offset 64.
    const std::uint64_t from = B / 2, size = 3 * B;
    BufferDesc bd;
    bd.size = std::size_t(size + 128);
    bd.usage.storageBuffer = true;
    bd.usage.copySrc = true;
    bd.usage.copyDst = true;
    bd.label = "pack-read";
    const Buffer buf = dev->make_buffer(bd);
    REQUIRE(dev->state(buf) == ResourceState::Valid);
    auto t = dev->read_pack_to_buffer(PackSource{pack.value(), "a/data.bin", from, size}, buf, 64);
    REQUIRE_MESSAGE(t.ok(), (t.ok() ? "" : t.error().to_string()));
    const PackReadResult r = finish(*dev, t.value());
    CHECK(r.bytes == size);
    if (!direct_missing(*dev)) {
        CHECK(r.direct);
        CHECK(r.directBlocks == 2);
        CHECK(dev->counters().packReadsDirect == 1);
        CHECK(pack.value()->counters().directBlocks >= 2);
    }
    std::vector<std::uint8_t> out;
    auto rb = dev->read_buffer(buf, 64, std::size_t(size), out);
    REQUIRE_MESSAGE(rb, rb.error().to_string());
    CHECK(out ==
          std::vector<std::uint8_t>(data.begin() + std::ptrdiff_t(from), data.begin() + std::ptrdiff_t(from + size)));
    // The buffer is usable afterwards: a second read of the whole file over it.
    auto t2 = dev->read_pack_to_buffer(PackSource{pack.value(), "a/data.bin", 0, B}, buf, 0);
    REQUIRE(t2.ok());
    finish(*dev, t2.value());
    rb = dev->read_buffer(buf, 0, std::size_t(B), out);
    REQUIRE(rb);
    CHECK(out == std::vector<std::uint8_t>(data.begin(), data.begin() + std::ptrdiff_t(B)));
    CHECK(dev->counters().packReadsInFlight == 0);
    CHECK_MESSAGE(layer_errors(*dev).empty(), layer_errors(*dev));
}

TEST_CASE("d3d12 pack reads: a gdeflate texture region fills an RGBA8 image through DirectStorage") {
    Scratch s;  // removed after the device, which may hold the pack's DirectStorage file open until it goes
    auto dev = make_warp();
    if (!dev) return;
    // 64x2048 RGBA8: rows of 256 bytes, so the copyable footprint has no padding and each block holds 1024 rows.
    const int width = 64, height = 2048;
    const std::vector<std::uint8_t> texels = text(std::size_t(width) * std::size_t(height) * 4, 2);
    fa::PackWriter w;
    REQUIRE(w.add_bytes("tex/stone.bin", texels, fa::Codec::GDeflate).ok());
    REQUIRE(w.write(s.dir / "game.pak").ok());
    auto pack = fa::PackReader::open(s.dir / "game.pak");
    REQUIRE(pack.ok());

    ImageDesc id;
    id.width = width;
    id.height = height;
    id.pixelFormat = PixelFormat::Rgba8;
    id.usage.writeTransient = true;
    id.label = "pack-texture";
    const Image img = dev->make_image(id);
    REQUIRE(dev->state(img) == ResourceState::Valid);
    PackImageRegion region;
    region.width = width;
    region.height = height;
    auto t = dev->read_pack_to_image(PackSource{pack.value(), "tex/stone.bin", 0, texels.size()}, img, region);
    REQUIRE_MESSAGE(t.ok(), (t.ok() ? "" : t.error().to_string()));
    const PackReadResult r = finish(*dev, t.value());
    if (!direct_missing(*dev)) {
        CHECK(r.direct);
        CHECK(r.directBlocks == 2);
    }
    std::vector<std::uint8_t> out;
    auto rb = dev->read_image_region(img, 0, 0, 0, 0, width, height, out);
    REQUIRE_MESSAGE(rb, rb.error().to_string());
    CHECK(out == texels);
    CHECK_MESSAGE(layer_errors(*dev).empty(), layer_errors(*dev));
}

TEST_CASE("d3d12 pack reads: the 2x2 and 1x1 mips of a BC1 texture take one whole block each, with the debug layer") {
    Scratch s;  // removed after the device, which may hold the pack's DirectStorage file open until it goes
    auto dev = make_warp();
    if (!dev) return;
    // An 8x8 BC1 texture has four mips: 8x8, 4x4, 2x2 and 1x1. Each of the last two is one 8-byte block, which
    // DirectStorage writes with the box of the whole block (0..4 x 0..4, direct_texture_box), larger than the mip; the
    // debug layer checks that copy as it checks the device's own.
    const std::vector<std::uint8_t> mip2 = text(8, 7), mip3 = text(8, 8);
    fa::PackWriter w;
    REQUIRE(w.add_bytes("tex/mip2.bc1", mip2, fa::Codec::GDeflate).ok());
    REQUIRE(w.add_bytes("tex/mip3.bc1", mip3, fa::Codec::GDeflate).ok());
    REQUIRE(w.write(s.dir / "game.pak").ok());
    auto pack = fa::PackReader::open(s.dir / "game.pak");
    REQUIRE(pack.ok());

    ImageDesc id;
    id.width = 8;
    id.height = 8;
    id.numMipmaps = 4;
    id.pixelFormat = PixelFormat::Bc1Rgba;
    id.usage.writeTransient = true;
    id.label = "pack-bc1";
    const Image img = dev->make_image(id);
    REQUIRE(dev->state(img) == ResourceState::Valid);
    struct Mip {
        int mip, size;
        const char* path;
    };
    for (const Mip& m : {Mip{2, 2, "tex/mip2.bc1"}, Mip{3, 1, "tex/mip3.bc1"}}) {
        CAPTURE(m.mip);
        PackImageRegion region;
        region.mip = m.mip;
        region.width = m.size;
        region.height = m.size;
        auto t = dev->read_pack_to_image(PackSource{pack.value(), m.path, 0, 8}, img, region);
        REQUIRE_MESSAGE(t.ok(), (t.ok() ? "" : t.error().to_string()));
        const PackReadResult r = finish(*dev, t.value());
        CHECK(r.bytes == 8);
        if (!direct_missing(*dev)) {
            CHECK(r.direct);
            CHECK(r.directBlocks == 1);
        }
    }
    // Compressed images are not read back (read_image_region): the reads' results and the debug layer are the check.
    REQUIRE(dev->wait_idle());
    CHECK_MESSAGE(layer_errors(*dev).empty(), layer_errors(*dev));
}

TEST_CASE("d3d12 pack reads: the device closes a pack's DirectStorage file once the pack and its reads are gone") {
    Scratch s;
    auto dev = make_warp();
    if (!dev) return;
    const std::vector<std::uint8_t> data = text(std::size_t(2 * B), 6);
    fa::PackWriter w;
    REQUIRE(w.add_bytes("a/data.bin", data, fa::Codec::GDeflate).ok());
    REQUIRE(w.write(s.dir / "game.pak").ok());
    auto opened = fa::PackReader::open(s.dir / "game.pak");
    REQUIRE(opened.ok());
    std::shared_ptr<const fa::PackReader> pack = std::move(opened.value());
    BufferDesc bd;
    bd.size = std::size_t(2 * B);
    bd.usage.copySrc = true;
    bd.usage.copyDst = true;
    bd.label = "closes";
    const Buffer buf = dev->make_buffer(bd);
    REQUIRE(dev->state(buf) == ResourceState::Valid);
    auto t = dev->read_pack_to_buffer(PackSource{pack, "a/data.bin", 0, 2 * B}, buf, 0);
    REQUIRE_MESSAGE(t.ok(), (t.ok() ? "" : t.error().to_string()));
    pack.reset();  // the read holds the pack now, and drops it when it is polled to its end
    const PackReadResult r = finish(*dev, t.value());
    CHECK(r.bytes == 2 * B);
    const auto c = dev->counters();
    if (c.packFilesOpened == 0)
        MESSAGE("the device never opened game.pak through DirectStorage ("
                << dev->pack_reads_direct_why()
                << "): closing its handle once the pack is gone (prune_files) was not covered, only that the CPU "
                   "fallback keeps no handle");
    else
        CHECK(c.packFilesClosed == c.packFilesOpened);
    // Nothing holds game.pak open any more, the device included: Windows lets it be deleted while the device lives.
    std::error_code ec;
    CHECK_MESSAGE(std::filesystem::remove(s.dir / "game.pak", ec), ec.message());
    CHECK(dev->counters().packReadsInFlight == 0);
}

TEST_CASE("d3d12 pack reads: a pack in memory, an lz4 file and a padded texture region take the CPU fallback") {
    Scratch s;  // removed after the device, which may hold the pack's DirectStorage file open until it goes
    auto dev = make_warp();
    if (!dev) return;
    const std::vector<std::uint8_t> data = text(std::size_t(2 * B + 300), 3);
    // 60x2048 RGBA8: 240-byte rows 256 bytes apart over two blocks, rows that do not fill whole blocks (the padding
    // after a block's last row is in no block): always the CPU.
    const std::uint64_t tallBytes = fa::detail::direct_texture_bytes(240, 2048);
    const std::vector<std::uint8_t> tall = text(std::size_t(tallBytes), 4);
    fa::PackWriter w;
    REQUIRE(w.add_bytes("a/data.bin", data, fa::Codec::GDeflate).ok());
    REQUIRE(w.add_bytes("a/data.lz4", data, fa::Codec::Lz4).ok());
    REQUIRE(w.add_bytes("tex/tall.bin", tall, fa::Codec::GDeflate).ok());
    REQUIRE(w.write(s.dir / "game.pak").ok());
    auto onDisk = fa::PackReader::open(s.dir / "game.pak");
    REQUIRE(onDisk.ok());
    auto bytes = fa::fs::read_bytes(fa::fs::path_to_utf8(s.dir / "game.pak"));
    REQUIRE(bytes.ok());
    auto inMemory = fa::PackReader::open_memory(std::move(bytes.value()));
    REQUIRE(inMemory.ok());

    BufferDesc bd;
    bd.size = data.size();
    bd.usage.copySrc = true;
    bd.usage.copyDst = true;
    bd.label = "fallback";
    const Buffer buf = dev->make_buffer(bd);
    REQUIRE(dev->state(buf) == ResourceState::Valid);
    std::vector<std::uint8_t> out;
    for (const auto& [pack, path] :
         {std::pair{inMemory.value(), "a/data.bin"}, std::pair{onDisk.value(), "a/data.lz4"}}) {
        CAPTURE(path);
        auto t = dev->read_pack_to_buffer(PackSource{pack, path, 100, data.size() - 100}, buf, 0);
        REQUIRE_MESSAGE(t.ok(), (t.ok() ? "" : t.error().to_string()));
        const PackReadResult r = finish(*dev, t.value());
        CHECK(!r.direct);
        CHECK(r.directBlocks == 0);
        CHECK(r.bytes == data.size() - 100);
        auto rb = dev->read_buffer(buf, 0, data.size() - 100, out);
        REQUIRE(rb);
        CHECK(out == std::vector<std::uint8_t>(data.begin() + 100, data.end()));
    }
    CHECK(dev->counters().packReadsCpu >= 2);

    ImageDesc id;
    id.width = 60;
    id.height = 2048;
    id.pixelFormat = PixelFormat::Rgba8;
    id.usage.writeTransient = true;
    id.label = "fallback-texture";
    const Image img = dev->make_image(id);
    REQUIRE(dev->state(img) == ResourceState::Valid);
    PackImageRegion region;
    region.width = 60;
    region.height = 2048;
    auto t = dev->read_pack_to_image(PackSource{onDisk.value(), "tex/tall.bin", 0, tallBytes}, img, region);
    REQUIRE_MESSAGE(t.ok(), (t.ok() ? "" : t.error().to_string()));
    const PackReadResult r = finish(*dev, t.value());
    CHECK(!r.direct);
    auto rb = dev->read_image_region(img, 0, 0, 0, 0, 60, 2048, out);
    REQUIRE(rb);
    REQUIRE(out.size() == std::size_t(60 * 2048 * 4));
    bool same = true;
    for (std::size_t row = 0; row < 2048 && same; ++row)
        same = std::equal(out.begin() + std::ptrdiff_t(row * 240), out.begin() + std::ptrdiff_t(row * 240 + 240),
                          tall.begin() + std::ptrdiff_t(row * 256));
    CHECK(same);
    CHECK_MESSAGE(layer_errors(*dev).empty(), layer_errors(*dev));
}

TEST_CASE("d3d12 pack reads: contradictions are teaching errors before any GPU work") {
    Scratch s;  // removed after the device, which may hold the pack's DirectStorage file open until it goes
    auto dev = make_warp();
    if (!dev) return;
    const std::vector<std::uint8_t> data = text(1000, 5);
    fa::PackWriter w;
    REQUIRE(w.add_bytes("a/data.bin", data, fa::Codec::GDeflate).ok());
    REQUIRE(w.write(s.dir / "game.pak").ok());
    auto pack = fa::PackReader::open(s.dir / "game.pak");
    REQUIRE(pack.ok());
    BufferDesc bd;
    bd.size = 512;
    bd.usage.copyDst = true;
    bd.label = "small";
    const Buffer buf = dev->make_buffer(bd);

    auto noPack = dev->read_pack_to_buffer(PackSource{nullptr, "a/data.bin", 0, 10}, buf, 0);
    REQUIRE(!noPack.ok());
    CHECK(contains(noPack.error().hint, "PackReader"));
    auto past = dev->read_pack_to_buffer(PackSource{pack.value(), "a/data.bin", 900, 200}, buf, 0);
    REQUIRE(!past.ok());
    CHECK(contains(past.error().message, "1000"));
    auto tooBig = dev->read_pack_to_buffer(PackSource{pack.value(), "a/data.bin", 0, 1000}, buf, 0);
    REQUIRE(!tooBig.ok());
    CHECK(contains(tooBig.error().message, "'small'"));
    auto typo = dev->read_pack_to_buffer(PackSource{pack.value(), "a/date.bin", 0, 10}, buf, 0);
    REQUIRE(!typo.ok());
    CHECK(contains(typo.error().to_string(), "a/data.bin"));  // did you mean

    ImageDesc id;
    id.width = 16;
    id.height = 16;
    id.pixelFormat = PixelFormat::Rgba8;
    id.usage.writeTransient = true;
    const Image img = dev->make_image(id);
    PackImageRegion region;
    region.x = 8;
    region.width = 16;
    region.height = 1;
    auto outside = dev->read_pack_to_image(PackSource{pack.value(), "a/data.bin", 0, 64}, img, region);
    REQUIRE(!outside.ok());
    CHECK(contains(outside.error().message, "16x16"));
    region.x = 0;
    auto wrongSize = dev->read_pack_to_image(PackSource{pack.value(), "a/data.bin", 0, 60}, img, region);
    REQUIRE(!wrongSize.ok());
    CHECK(contains(wrongSize.error().message, "needs 64"));
    CHECK(dev->counters().packReadsInFlight == 0);
}

#endif
