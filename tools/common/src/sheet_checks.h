// Checks on the frames of a sprite sheet, shared by assets.animate_svg (on the frames it has just drawn) and
// assets.preview_sheet (on a sheet already in the project, from either maker or drawn by hand).
#pragma once

#include <optional>
#include <string>
#include <vector>

#include "fa/core/image.h"

namespace fa::assets_detail {

// Mean difference between two pictures of the same size, 0 (equal) to 2.
double picture_difference(const Image& a, const Image& b);
// True when no pixel has any alpha.
bool picture_is_empty(const Image& im);
// True when a visible pixel (alpha > 8) sits on the outermost row or column: the shape may be cut by the cell.
bool touches_edge(const Image& im);
// "3, 4, 5, ... (20 in all)": the first twelve names of a list.
std::string list_frames(const std::vector<std::string>& names);

// Box around the visible pixels (alpha > 8) of a picture; `empty` when there are none.
struct InkBox {
    bool empty = true;
    int x0 = 0, y0 = 0, x1 = 0, y1 = 0;  // inclusive pixel bounds
    int width() const { return empty ? 0 : x1 - x0 + 1; }
    int height() const { return empty ? 0 : y1 - y0 + 1; }
};
InkBox ink_box(const Image& im);

// The warning for a looping clip whose seam shows (the last frame differs from the first much more than the frames differ
// from each other) or stops (the last frame repeats the first); nullopt when the seam is fine or the clip has under three
// frames. `label` is "" or ` of clip "name"`.
std::optional<std::string> loop_seam_warning(const std::vector<const Image*>& frames, const std::string& label);

}  // namespace fa::assets_detail
