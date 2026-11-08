// Block codecs of fa/core/compress.h: the engine's own LZ4 block and Zstandard (RFC 8878) codecs, dispatched here.
// lz4_codec.cpp, zstd_decode.cpp, zstd_encode.cpp and xxh64.cpp hold the formats (compress_internal.h).
#include <algorithm>
#include <array>
#include <cstring>
#include <new>
#include <string>

#include "compress_internal.h"
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

std::size_t compress_bound(Codec codec, std::size_t size) {
    switch (codec) {
        case Codec::Store: return size;
        case Codec::Lz4: return codec::lz4_compress_bound(size);
        case Codec::Zstd: return codec::zstd_compress_bound(size);
    }
    return size;
}

Result<std::vector<std::uint8_t>> compress(std::span<const std::uint8_t> input, const CompressOptions& options) {
    if (static_cast<std::uint64_t>(input.size()) > codec::kMaxCompressInput)
        return Error{"cannot compress " + std::to_string(input.size()) + " bytes in one block (the limit is 1 GiB)",
                     "split the data into blocks of a few MiB and compress each one"};
    try {
        std::vector<std::uint8_t> out;
        switch (options.codec) {
            case Codec::Store: out.assign(input.begin(), input.end()); break;
            case Codec::Lz4:
                codec::lz4_compress(input, options.level == 0 ? 1 : std::clamp(options.level, 1, 12), out);
                break;
            case Codec::Zstd:
                codec::zstd_compress(input, options.level == 0 ? 3 : std::clamp(options.level, 1, 19), false, out);
                break;
        }
        return out;
    } catch (const std::bad_alloc&) {
        return Error{"out of memory compressing " + std::to_string(input.size()) + " bytes",
                     "compress smaller blocks or close other programs"};
    }
}

Result<void> decompress_into(Codec codec, std::span<const std::uint8_t> block, std::span<std::uint8_t> out) {
    try {
        switch (codec) {
            case Codec::Store:
                if (block.size() != out.size())
                    return Error{"stored block holds " + std::to_string(block.size()) + " bytes, expected " +
                                     std::to_string(out.size()),
                                 "the pack is damaged: export the game again"};
                if (!block.empty()) std::memcpy(out.data(), block.data(), block.size());
                return {};
            case Codec::Lz4: return codec::lz4_decompress(block, out);
            case Codec::Zstd: return codec::zstd_decompress(block, out, true);
        }
    } catch (const std::bad_alloc&) {
        return Error{"out of memory decompressing a block", "close other programs and try again"};
    }
    return Error{"unknown codec", "use \"store\", \"lz4\" or \"zstd\""};
}

Result<std::vector<std::uint8_t>> decompress(Codec codec, std::span<const std::uint8_t> block,
                                             std::size_t expectedSize) {
    // A damaged header can claim any size: refuse what this block could never hold before allocating it.
    const std::uint64_t most = codec::max_decoded_size(codec, block.size());
    if (static_cast<std::uint64_t>(expectedSize) > most)
        return Error{"a " + std::string(codec_name(codec)) + " block of " + std::to_string(block.size()) +
                         " bytes cannot hold " + std::to_string(expectedSize) + " bytes",
                     "the pack is damaged: export the game again"};
    std::vector<std::uint8_t> out;
    try {
        out.resize(expectedSize);
    } catch (const std::bad_alloc&) {
        return Error{"out of memory for " + std::to_string(expectedSize) + " bytes", "close other programs"};
    }
    if (auto r = decompress_into(codec, block, out); !r) return r.error();
    return out;
}

}  // namespace fa
