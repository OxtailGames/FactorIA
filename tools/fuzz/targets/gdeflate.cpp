// fa::decompress / decompress_into with Codec::GDeflate on any bytes (the stream of game.pak's gdeflate blocks, which
// DirectStorage also decodes): every byte string is a block of the asked size or an error, never a read or write out of
// bounds. The input's first three bytes are the size the block must decode to (at most 1 MiB, like a pack block of a
// few hundred KiB); the rest is the stream. What the encoder writes of that rest decodes back to the same bytes.
#include <algorithm>
#include <cstddef>
#include <cstdint>
#include <span>
#include <vector>

#include "fa/core/compress.h"
#include "fuzz_support.h"

extern "C" int LLVMFuzzerTestOneInput(const std::uint8_t* data, std::size_t size) {
    static const bool once = (fa::fuzz::quiet(), true);
    (void)once;
    if (size < 3) return 0;
    constexpr std::size_t kMaxOut = std::size_t(1) << 20;
    const std::size_t expected =
        (std::size_t(data[0]) | std::size_t(data[1]) << 8 | std::size_t(data[2]) << 16) % (kMaxOut + 1);
    const std::span<const std::uint8_t> stream(data + 3, size - 3);

    auto block = fa::decompress(fa::Codec::GDeflate, stream, expected);
    if (block && block.value().size() != expected) fa::fuzz::fail("decompress returned another size than asked");
    std::vector<std::uint8_t> out(expected, 0xCD);
    auto into = fa::decompress_into(fa::Codec::GDeflate, stream, out);
    if (into.ok() != block.ok()) fa::fuzz::fail("decompress and decompress_into disagree on the same stream");
    if (into && out != block.value()) fa::fuzz::fail("decompress and decompress_into decoded different bytes");

    // The round trip of the stream's bytes as data (small inputs: one or two 64 KiB tiles), at a level from the input.
    if (stream.size() <= (std::size_t(1) << 17)) {
        auto packed = fa::compress(stream, fa::CompressOptions{fa::Codec::GDeflate, int(data[0] % 13)});
        if (!packed) fa::fuzz::fail("compress refused a small input");
        auto back = fa::decompress(fa::Codec::GDeflate, packed.value(), stream.size());
        if (!back) fa::fuzz::fail("compress wrote a gdeflate stream that decompress refuses");
        if (!std::equal(back.value().begin(), back.value().end(), stream.begin(), stream.end()))
            fa::fuzz::fail("a gdeflate round trip changed the bytes");
    }
    return 0;
}
