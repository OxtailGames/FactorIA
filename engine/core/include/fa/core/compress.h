// Lossless compression.
//
// zlib (RFC 1950, deflate): used by `storage.set(key, value, {compress: true})` and PSD/PNG code.
//
// Block codecs (M70.4), FactorIA's own implementations of two public formats, used by game.pak:
//   lz4   the LZ4 block format (no frame): very fast to decode (GB/s), modest ratio. For data read on the hot path
//         of a load where decode time matters more than size (scenes, meshes, scripts, raw images).
//   zstd  the Zstandard frame format (RFC 8878): slower to encode, still fast to decode, much better ratio. For
//         larger data that compresses well (text, JSON, fonts, uncompressed texture payloads).
//   store no compression (data that is compressed already: PNG, OGG, QOA, KTX2 with supercompression, MP4).
// No outside library: both are written for the engine and are byte-compatible with the reference tools (`lz4 -d` on
// our block wrapped in an LZ4 frame and `zstd -d` on our frames give the bytes back; our decoders read blocks and
// frames those tools write; tests check both ways with committed fixtures made by the reference tools).
//
// Decoders never trust their input: a damaged or hostile block is an error (no read or write out of bounds, no
// allocation beyond the caller's expected size), so a cut-short or tampered game.pak fails with a message. Everything
// here is pure and thread-safe (no global state), and the same input and options give the same bytes on every platform
// and compiler (a pack built on Windows is byte-identical to one built on macOS).
#pragma once

#include <cstddef>
#include <cstdint>
#include <span>
#include <string>
#include <string_view>
#include <vector>

#include "fa/core/types.h"

namespace fa {

// The zlib stream of `data` (RFC 1950, deflate). Deterministic: the same bytes always give the same stream.
std::string zlib_compress(std::string_view data);
// The bytes of a zlib stream. `expectedSize` is a hint for the buffer (0 when unknown). An error names what is wrong
// (a truncated or damaged stream).
Result<std::string> zlib_decompress(std::string_view stream, std::size_t expectedSize = 0);

// ---- Block codecs (game.pak) ------------------------------------------------------------------------------------

enum class Codec : std::uint8_t {
    Store = 0,
    Lz4 = 1,
    Zstd = 2,
};

// "store", "lz4", "zstd": the names used in factoria.json and in pack reports.
std::string_view codec_name(Codec codec);
// Parses a name; an unknown one is an error with a "did you mean".
Result<Codec> parse_codec(std::string_view name);

// Level: lz4 1 (fast) .. 12 (high compression, same decoder); zstd 1 .. 19. 0 = the codec's default (lz4 1, zstd 3).
// Out-of-range levels are clamped. Store ignores it.
struct CompressOptions {
    Codec codec = Codec::Lz4;
    int level = 0;
};

// Upper bound of compress()'s output for `size` input bytes (to reserve once).
std::size_t compress_bound(Codec codec, std::size_t size);

// Compresses `input` into one self-contained block (lz4: a raw block; zstd: one frame that records its content size;
// store: the bytes as they are). Never fails for valid options; an input over 1 GiB is an error (game.pak compresses
// in blocks of at most a few MiB).
Result<std::vector<std::uint8_t>> compress(std::span<const std::uint8_t> input, const CompressOptions& options);

// Decompresses one block into exactly `expectedSize` bytes. A block that decodes to another size, or is damaged, is
// an error naming what is wrong and where (offset in the block).
Result<std::vector<std::uint8_t>> decompress(Codec codec, std::span<const std::uint8_t> block,
                                             std::size_t expectedSize);
// Same, into a caller buffer of exactly `out.size()` bytes (memory-mapped packs decode in place). It makes no
// allocation proportional to the output; the zstd decoder still allocates its working state on every call (~14 KiB, plus
// up to 128 KiB of literals), which it frees before returning.
Result<void> decompress_into(Codec codec, std::span<const std::uint8_t> block, std::span<std::uint8_t> out);

}  // namespace fa
