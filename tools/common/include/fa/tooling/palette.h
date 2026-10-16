// Palette lock: reduce an image to a fixed set of colours (assets.json style.palette, assets.generate_image).
#pragma once

#include <array>
#include <cstdint>
#include <vector>

#include "fa/core/image.h"
#include "fa/core/json.h"
#include "fa/core/types.h"

namespace fa {

using Palette = std::vector<std::array<std::uint8_t, 3>>;  // RGB
inline constexpr std::size_t kMaxPaletteColours = 256;

// The palette a `style.palette` value names: a list of "#rrggbb" strings, or the project-relative path of an image whose
// distinct opaque colours are the palette (read through fa::fs). The Errors name the bad colour or file, and say that an
// image with more than kMaxPaletteColours colours is not a palette.
Result<Palette> load_palette(const Json& spec);

// Every pixel takes the nearest palette colour (smallest squared distance in RGB); alpha is kept as it is.
Image quantize_to_palette(const Image& src, const Palette& palette);

}  // namespace fa
