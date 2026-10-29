// The part of SVG that nanosvg does not draw and assets.rasterize_svg adds on top of it: clip-path (<clipPath>), mask (<mask>,
// luminance) and pattern fills (<pattern>). The document is read into a small element tree; every shape that uses one of the
// three is rendered on its own transparent layer by nanosvg, the layer is multiplied by the clip or mask, and the layers are
// composited in paint order. A document that uses none of them is left to the plain nanosvg pass.
#pragma once

#include <string>
#include <vector>

#include "fa/core/image.h"

struct NSVGimage;

namespace fa::assets_detail {

// Returns false (and touches nothing) when the SVG has no clip-path, mask or pattern fill. Otherwise draws the whole picture
// into `out` (already sized and cleared), pushes the problems it found (missing ids, unsupported attributes) to `warnings`
// and returns true. `image` is the nanosvg parse of the same text (its size and the root element decide the mapping).
bool render_svg_layers(const std::string& text, const NSVGimage* image, Image& out, float tx, float ty, float scale,
                       std::vector<std::string>& warnings);

}  // namespace fa::assets_detail
