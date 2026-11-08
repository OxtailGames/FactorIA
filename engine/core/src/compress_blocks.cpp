// Block codecs of fa/core/compress.h. CONTRACT STUB of M70.4: only `store` works; M70.4a replaces this file with the
// engine's own LZ4 block and Zstandard (RFC 8878) codecs.
#include <algorithm>
#include <array>
#include <cstring>
#include <string>

#include "fa/core/compress.h"
#include "fa/core/strings.h"

namespace fa {

std::string_view codec_name(Codec codec) {
    switch (codec) {
        case Codec::Store: return "store";
        case Codec::Lz4: return "lz4";
        case Codec::Zstd: return "zstd";
    }
    return "store";
}

Result<Codec> parse_codec(std::string_view name) {
    for (Codec c : {Codec::Store, Codec::Lz4, Codec::Zstd})
        if (codec_name(c) == name) return c;
    const std::array<std::string, 3> names{"store", "lz4", "zstd"};
    return Error{"unknown codec \"" + std::string(name) + "\"",
                 "use \"store\", \"lz4\" or \"zstd\"" + did_you_mean(name, names)};
}

std::size_t compress_bound(Codec, std::size_t size) { return size + size / 255 + 64; }

static Error not_yet(Codec codec) {
    return Error{std::string("codec \"") + std::string(codec_name(codec)) + "\" is not implemented yet (M70.4a stub)",
                 "use \"store\""};
}

Result<std::vector<std::uint8_t>> compress(std::span<const std::uint8_t> input, const CompressOptions& options) {
    if (options.codec != Codec::Store) return not_yet(options.codec);
    return std::vector<std::uint8_t>(input.begin(), input.end());
}

Result<void> decompress_into(Codec codec, std::span<const std::uint8_t> block, std::span<std::uint8_t> out) {
    if (codec != Codec::Store) return not_yet(codec);
    if (block.size() != out.size())
        return Error{"stored block holds " + std::to_string(block.size()) + " bytes, expected " +
                         std::to_string(out.size()),
                     "the pack is damaged: export the game again"};
    if (!block.empty()) std::memcpy(out.data(), block.data(), block.size());
    return {};
}

Result<std::vector<std::uint8_t>> decompress(Codec codec, std::span<const std::uint8_t> block,
                                             std::size_t expectedSize) {
    std::vector<std::uint8_t> out(expectedSize);
    if (auto r = decompress_into(codec, block, out); !r) return r.error();
    return out;
}

}  // namespace fa
