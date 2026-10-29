#include "sheet_checks.h"

#include <algorithm>
#include <cmath>
#include <format>

namespace fa::assets_detail {

double picture_difference(const Image& a, const Image& b) {
    if (a.rgba.size() != b.rgba.size() || a.rgba.empty()) return 0;
    double sum = 0;
    for (std::size_t i = 0; i < a.rgba.size(); i += 4) {
        const double a1 = a.rgba[i + 3], a2 = b.rgba[i + 3];
        const double colour = (std::abs(a.rgba[i] - b.rgba[i]) + std::abs(a.rgba[i + 1] - b.rgba[i + 1]) + std::abs(a.rgba[i + 2] - b.rgba[i + 2])) / 3.0;
        sum += std::abs(a1 - a2) + std::min(a1, a2) / 255.0 * colour;
    }
    return sum / (255.0 * double(a.rgba.size() / 4));
}

bool picture_is_empty(const Image& im) {
    for (std::size_t i = 3; i < im.rgba.size(); i += 4)
        if (im.rgba[i] != 0) return false;
    return true;
}

bool touches_edge(const Image& im) {
    auto ink = [&](int x, int y) { return im.rgba[(std::size_t(y) * im.width + x) * 4 + 3] > 8; };
    for (int x = 0; x < im.width; ++x)
        if (ink(x, 0) || ink(x, im.height - 1)) return true;
    for (int y = 0; y < im.height; ++y)
        if (ink(0, y) || ink(im.width - 1, y)) return true;
    return false;
}

std::string list_frames(const std::vector<std::string>& names) {
    std::string out;
    for (std::size_t i = 0; i < names.size() && i < 12; ++i) out += (i ? ", " : "") + names[i];
    if (names.size() > 12) out += std::format(", ... ({} in all)", names.size());
    return out;
}

InkBox ink_box(const Image& im) {
    InkBox box;
    for (int y = 0; y < im.height; ++y)
        for (int x = 0; x < im.width; ++x) {
            if (im.rgba[(std::size_t(y) * im.width + x) * 4 + 3] <= 8) continue;
            if (box.empty) {
                box = {false, x, y, x, y};
            } else {
                box.x0 = std::min(box.x0, x);
                box.y0 = std::min(box.y0, y);
                box.x1 = std::max(box.x1, x);
                box.y1 = std::max(box.y1, y);
            }
        }
    return box;
}

std::optional<std::string> loop_seam_warning(const std::vector<const Image*>& frames, const std::string& label) {
    if (frames.size() < 3) return std::nullopt;
    double consecutive = 0;
    for (std::size_t f = 1; f < frames.size(); ++f) consecutive += picture_difference(*frames[f - 1], *frames[f]);
    consecutive /= double(frames.size() - 1);
    const double wrap = picture_difference(*frames.back(), *frames.front());
    if (wrap > 0.004 && wrap > 2.5 * consecutive)
        return std::format("The loop{} jumps: its last frame differs from the first {:.1f} times more than the frames differ from each other, so a pop shows when it repeats. "
                           "Let the last frame lead into the first: draw frame i at progress = frame / frames (it reaches 1 only after the last frame), or set loop: false.",
                           label, consecutive > 0 ? wrap / consecutive : 99.0);
    if (consecutive > 0.004 && wrap < 0.1 * consecutive)
        return std::format("The loop{} stops for a frame: its last frame is the same as the first, shown twice when it repeats. Draw frame i at progress = frame / frames, "
                           "so the end is the frame after the last.", label);
    return std::nullopt;
}

}  // namespace fa::assets_detail
