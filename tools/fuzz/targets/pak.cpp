// fa::PackReader::open_memory on any bytes (the reader of game.pak): every byte string is a pack or an error. What opens is
// read the ways the engine reads a pack: whole files, ranges, views, listings.
#include <algorithm>
#include <cstddef>
#include <cstdint>
#include <span>
#include <string>
#include <vector>

#include "fa/core/pack.h"
#include "fuzz_support.h"

namespace {

std::uint64_t get_le(const std::uint8_t* p, int n) {
    std::uint64_t v = 0;
    for (int i = n - 1; i >= 0; --i) v = (v << 8) | p[i];
    return v;
}

// A format 2 index ends with the checksum of the bytes before it, so a mutated index would be refused at once and the
// parser behind the checksum would never see it. When the footer points at an index in the file, write the right checksum.
void fix_index_checksum(std::vector<std::uint8_t>& pack) {
    constexpr std::size_t kHeader = 16, kFooter = 24;
    if (pack.size() < kHeader + kFooter + 4 || get_le(&pack[8], 4) != fa::kPackFormatVersion) return;
    const std::uint64_t offset = get_le(&pack[pack.size() - kFooter], 8), length = get_le(&pack[pack.size() - kFooter + 8], 8);
    if (length < 4 || offset < kHeader || offset > pack.size() - kFooter || length != pack.size() - kFooter - offset) return;
    const std::uint32_t sum = fa::pack_checksum(std::span<const std::uint8_t>(&pack[std::size_t(offset)], std::size_t(length) - 4));
    for (int i = 0; i < 4; ++i) pack[std::size_t(offset + length) - 4 + std::size_t(i)] = std::uint8_t(sum >> (8 * i));
}

}  // namespace

extern "C" int LLVMFuzzerTestOneInput(const std::uint8_t* data, std::size_t size) {
    static const bool once = (fa::fuzz::quiet(), true);
    (void)once;
    std::vector<std::uint8_t> bytes(data, data + size);
    fix_index_checksum(bytes);
    auto opened = fa::PackReader::open_memory(std::move(bytes), "fuzz.pak");
    if (!opened) return 0;
    const fa::PackReader& pack = *opened.value();
    constexpr std::int64_t kReadCap = 16 << 20;  // a pack may claim far more than the input holds
    std::size_t visited = 0;
    for (const std::string& path : pack.list("", true)) {
        if (++visited > 64) break;
        if (!pack.contains(path)) fa::fuzz::fail("list() names a file contains() denies");
        const std::int64_t decoded = pack.size_of(path);
        (void)pack.stored_size_of(path);
        (void)pack.codec_of(path);
        (void)pack.is_directory(path);
        if (decoded < 0 || decoded > kReadCap) continue;
        auto whole = pack.read(path);
        if (whole && std::int64_t(whole.value().size()) != decoded) fa::fuzz::fail("read() returned another size than size_of()");
        (void)pack.read_range(path, 0, 100);
        (void)pack.read_range(path, std::uint64_t(decoded) / 2, 4096);
        (void)pack.read_range(path, std::uint64_t(decoded) + 5, 10);
        (void)pack.view(path);
    }
    (void)pack.list("", false);
    (void)pack.list("a", true);
    (void)pack.data_order();
    (void)pack.read("no/such/file.txt");
    (void)pack.counters();
    return 0;
}
