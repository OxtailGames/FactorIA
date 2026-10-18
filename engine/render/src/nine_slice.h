// 9-slice borders shared by the UI backgrounds (ui2d.cpp, Panel.slice) and Sprite.slice (scene2d.cpp).
#pragma once

#include <algorithm>

#include "fa/core/math.h"

namespace fa::render {

// Fits the borders `slice` = [left, top, right, bottom] (source pixels) of a source picture srcW x srcH drawn into a
// target of dstW x dstH (any unit; one source pixel = one target unit). The corners keep their size; borders that do not
// fit shrink together, so they never cover more than the picture or the target.
//   border: the four borders in target units, order left, top, right, bottom
//   uvBorder: the same as a fraction of the source picture
inline void nine_slice_fit(const Vec4& slice, float srcW, float srcH, float dstW, float dstH, float border[4], float uvBorder[4]) {
    const float size[2] = {srcW, srcH};
    const float want[4] = {std::max(0.0f, slice.x), std::max(0.0f, slice.y), std::max(0.0f, slice.z), std::max(0.0f, slice.w)};
    for (int axis = 0; axis < 2; ++axis) {  // 0: left + right against the width, 1: top + bottom against the height
        const float a = want[axis], z = want[axis + 2];
        const float sum = a + z, limit = std::min(size[axis], axis == 0 ? dstW : dstH);
        const float k = sum > limit && sum > 0 ? limit / sum : 1.0f;
        border[axis] = a * k;
        border[axis + 2] = z * k;
        uvBorder[axis] = a * k / size[axis];
        uvBorder[axis + 2] = z * k / size[axis];
    }
}

}  // namespace fa::render
