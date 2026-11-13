// KTX2 textures on the CPU (no GPU): what an export writes as the compressed twin of a texture (docs/ASSETS.md, "Textures").
#pragma once

#include <cstddef>
#include <cstdint>

#include "fa/core/image.h"
#include "fa/core/types.h"

namespace fa {

// Decodes the first (largest) mip level of a KTX2 file (Basis Universal, UASTC or ETC1S, one 2D texture) to RGBA8. The
// renderer transcodes to the block format the GPU samples instead; this is for tools, tests and anything that has to
// look at the pixels. Every damaged, truncated or unsupported file is an error that says so, and so is one whose header
// claims more than kMaxImageSide x kMaxImageSide pixels or kMaxImagePixels (fa/core/image.h): never a crash.
Result<Image> decode_ktx2(const std::uint8_t* data, std::size_t size);

}  // namespace fa
