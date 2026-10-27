// Lossless compression of byte strings (zlib format), used by `storage.set(key, value, {compress: true})`.
#pragma once

#include <string>
#include <string_view>

#include "fa/core/types.h"

namespace fa {

// The zlib stream of `data` (RFC 1950, deflate). Deterministic: the same bytes always give the same stream.
std::string zlib_compress(std::string_view data);
// The bytes of a zlib stream. `expectedSize` is a hint for the buffer (0 when unknown). An error names what is wrong
// (a truncated or damaged stream).
Result<std::string> zlib_decompress(std::string_view stream, std::size_t expectedSize = 0);

}  // namespace fa
