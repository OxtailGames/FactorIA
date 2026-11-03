// The seam check of tiles (fa/tooling/image_tile.h).
#include "fa/tooling/image_tile.h"

#include <algorithm>
#include <cmath>
#include <cstdlib>

namespace fa {

namespace {

const std::uint8_t* px(const Image& img, int x, int y) { return &img.rgba[(std::size_t(y) * img.width + x) * 4]; }

bool tile_is_empty(const Image& img, int ox, int oy, int tw, int th) {
    for (int y = 0; y < th; ++y)
        for (int x = 0; x < tw; ++x)
            if (px(img, ox + x, oy + y)[3]) return false;
    return true;
}

// Adds the pair distance to `seam`, and the position `at` along the seam to its runs when it is further than the tolerance.
void note_pair(TileSeam& seam, int at, int distance, int tolerance, double& total) {
    ++seam.length;
    total += distance;
    seam.worst = std::max(seam.worst, distance);
    if (distance <= tolerance) return;
    ++seam.mismatched;
    if (!seam.runs.empty() && seam.runs.back().second == at - 1) seam.runs.back().second = at;
    else seam.runs.push_back({at, at});
}

// `halves`: bit 0 = compare the first half of the seam (its top half for a horizontal seam, its left half for a vertical one), bit 1 = the
// second half. A pair of tiles that only agrees on one side of the seam is compared on that half.
TileSeam compare_sides(const Image& img, int tw, int th, int columns, int a, int b, bool horizontal, int tolerance, int halves = 3) {
    TileSeam seam;
    seam.axis = horizontal ? "horizontal" : "vertical";
    seam.a = a;
    seam.b = b;
    const int ax = (a % columns) * tw, ay = (a / columns) * th, bx = (b % columns) * tw, by = (b / columns) * th;
    double total = 0;
    if (horizontal) {
        for (int y = 0; y < th; ++y)
            if (halves & (y < th / 2 ? 1 : 2)) note_pair(seam, y, tile_pixel_distance(px(img, ax + tw - 1, ay + y), px(img, bx, by + y)), tolerance, total);
    } else {
        for (int x = 0; x < tw; ++x)
            if (halves & (x < tw / 2 ? 1 : 2)) note_pair(seam, x, tile_pixel_distance(px(img, ax + x, ay + th - 1), px(img, bx + x, by)), tolerance, total);
    }
    seam.mean = seam.length ? total / seam.length : 0;
    return seam;
}

}  // namespace

TileGrid tile_grid_of(const Json& doc) {
    TileGrid g;
    auto it = doc.find("tile");
    if (it == doc.end()) return g;
    g.canvasW = doc.value("width", 0);
    g.canvasH = doc.value("height", 0);
    g.tw = g.canvasW;
    g.th = g.canvasH;
    if (it->is_object()) {
        if (it->contains("width") && (*it)["width"].is_number_integer()) g.tw = (*it)["width"].get<int>();
        if (it->contains("height") && (*it)["height"].is_number_integer()) g.th = (*it)["height"].get<int>();
    } else if (!(it->is_boolean() && it->get<bool>())) {
        return g;
    }
    g.on = g.tw > 0 && g.th > 0 && g.canvasW > 0 && g.canvasH > 0 && g.canvasW % g.tw == 0 && g.canvasH % g.th == 0;
    return g;
}

int tile_pixel_distance(const std::uint8_t* a, const std::uint8_t* b) {
    const int da = std::abs(int(a[3]) - int(b[3]));
    const int minA = std::min(int(a[3]), int(b[3]));
    int dc = 0;
    for (int c = 0; c < 3; ++c) dc = std::max(dc, std::abs(int(a[c]) - int(b[c])));
    dc = (dc * minA + 127) / 255;
    return std::max(da, dc);
}

double tile_interior_difference(const Image& img, int tw, int th) {
    if (tw <= 0 || th <= 0 || img.width % tw || img.height % th) return 0;
    double total = 0;
    long long count = 0;
    for (int ty = 0; ty < img.height / th; ++ty)
        for (int tx = 0; tx < img.width / tw; ++tx) {
            const int ox = tx * tw, oy = ty * th;
            for (int y = 0; y < th; ++y)
                for (int x = 0; x < tw; ++x) {
                    if (x + 1 < tw) total += tile_pixel_distance(px(img, ox + x, oy + y), px(img, ox + x + 1, oy + y)), ++count;
                    if (y + 1 < th) total += tile_pixel_distance(px(img, ox + x, oy + y), px(img, ox + x, oy + y + 1)), ++count;
                }
        }
    return count ? total / double(count) : 0;
}

int tile_automatic_tolerance(double interior, bool exact) { return exact ? 0 : int(std::ceil(interior * 1.5)); }

TileSeamReport check_tile_opposites(const Image& img, int tw, int th, int tolerance, bool exact) {
    TileSeamReport report;
    report.tileWidth = tw;
    report.tileHeight = th;
    if (tw <= 0 || th <= 0 || img.width % tw || img.height % th) return report;
    report.columns = img.width / tw;
    report.rows = img.height / th;
    report.interior = tile_interior_difference(img, tw, th);
    report.toleranceAutomatic = tolerance < 0;
    report.tolerance = tolerance < 0 ? tile_automatic_tolerance(report.interior, exact) : tolerance;
    for (int t = 0; t < report.columns * report.rows; ++t) {
        if (tile_is_empty(img, (t % report.columns) * tw, (t / report.columns) * th, tw, th)) continue;
        ++report.tilesChecked;
        for (bool horizontal : {true, false}) {
            TileSeam seam = compare_sides(img, tw, th, report.columns, t, t, horizontal, report.tolerance);
            ++report.seamsChecked;
            report.pixelPairs += seam.length;
            if (seam.mismatched) report.bad.push_back(std::move(seam));
        }
    }
    return report;
}

namespace {

// Which halves of the seam can be compared when tile A stands west of tile B (horizontal) or north of it (vertical): bit 0 the first half
// (top / left), bit 1 the second (bottom / right); 0 = the pair cannot stand side by side. Both tiles need the neighbour towards the other.
// In a blob47 set the four cells around the pair must give both tiles the diagonal bits they have, and then both halves are compared
// (an inner corner on one side meets an edge on the other: that is the point of the set). A 16-tile set knows no diagonals: a half is
// only comparable when both tiles have, or both lack, the neighbour on that side (otherwise the corner cell it would need is not in the
// set, and the art cannot be continuous there).
int pair_halves(int a, int b, bool horizontal, bool diagonals) {
    constexpr int N = 1, NE = 2, E = 4, SE = 8, S = 16, SW = 32, W = 64, NW = 128;
    auto bit = [](int m, int b2) { return (m & b2) != 0; };
    if (horizontal) {
        if (!bit(a, E) || !bit(b, W)) return 0;
        if (!diagonals) return (bit(a, N) == bit(b, N) ? 1 : 0) | (bit(a, S) == bit(b, S) ? 2 : 0);
        const bool top = bit(a, N) && bit(b, N), bottom = bit(a, S) && bit(b, S);
        return bit(a, NE) == top && bit(b, NW) == top && bit(a, SE) == bottom && bit(b, SW) == bottom ? 3 : 0;
    }
    if (!bit(a, S) || !bit(b, N)) return 0;
    if (!diagonals) return (bit(a, W) == bit(b, W) ? 1 : 0) | (bit(a, E) == bit(b, E) ? 2 : 0);
    const bool left = bit(a, W) && bit(b, W), right = bit(a, E) && bit(b, E);
    return bit(a, SW) == left && bit(b, NW) == left && bit(a, SE) == right && bit(b, NE) == right ? 3 : 0;
}

}  // namespace

TileSeamReport check_tile_set(const Image& img, int tw, int th, int columns, const std::vector<int>& masks, bool diagonals, int tolerance, bool exact) {
    TileSeamReport report;
    report.tileWidth = tw;
    report.tileHeight = th;
    report.columns = columns;
    if (tw <= 0 || th <= 0 || columns <= 0) return report;
    report.rows = int((masks.size() + std::size_t(columns) - 1) / std::size_t(columns));
    if (img.width < columns * tw || img.height < report.rows * th) return report;
    // the mean difference inside the tiles of the set (only the tiles the masks name)
    {
        double total = 0;
        long long count = 0;
        for (std::size_t t = 0; t < masks.size(); ++t) {
            if (masks[t] < 0) continue;
            const int ox = int(t % std::size_t(columns)) * tw, oy = int(t / std::size_t(columns)) * th;
            for (int y = 0; y < th; ++y)
                for (int x = 0; x < tw; ++x) {
                    if (x + 1 < tw) total += tile_pixel_distance(px(img, ox + x, oy + y), px(img, ox + x + 1, oy + y)), ++count;
                    if (y + 1 < th) total += tile_pixel_distance(px(img, ox + x, oy + y), px(img, ox + x, oy + y + 1)), ++count;
                }
        }
        report.interior = count ? total / double(count) : 0;
    }
    report.toleranceAutomatic = tolerance < 0;
    report.tolerance = tolerance < 0 ? tile_automatic_tolerance(report.interior, exact) : tolerance;
    for (std::size_t t = 0; t < masks.size(); ++t)
        if (masks[t] >= 0) ++report.tilesChecked;
    for (bool horizontal : {true, false})
        for (std::size_t a = 0; a < masks.size(); ++a) {
            if (masks[a] < 0) continue;
            for (std::size_t b = 0; b < masks.size(); ++b) {
                const int halves = masks[b] < 0 ? 0 : pair_halves(masks[a], masks[b], horizontal, diagonals);
                if (!halves) continue;
                TileSeam seam = compare_sides(img, tw, th, columns, int(a), int(b), horizontal, report.tolerance, halves);
                ++report.seamsChecked;
                report.pixelPairs += seam.length;
                if (seam.mismatched) report.bad.push_back(std::move(seam));
            }
        }
    return report;
}

namespace {

void tint_red(Image& img, int x, int y) {
    if (x < 0 || y < 0 || x >= img.width || y >= img.height) return;
    std::uint8_t* p = &img.rgba[(std::size_t(y) * img.width + x) * 4];
    p[0] = std::uint8_t((p[0] * 3 + 255 * 7) / 10);
    p[1] = std::uint8_t((p[1] * 3) / 10);
    p[2] = std::uint8_t((p[2] * 3) / 10);
    p[3] = 255;
}

void fill_rect(Image& img, int x0, int y0, int x1, int y1) {   // [x0, x1) x [y0, y1)
    for (int y = y0; y < y1; ++y)
        for (int x = x0; x < x1; ++x) tint_red(img, x, y);
}

Image magnified(const Image& src, int scale) {
    Image out;
    out.width = src.width * scale;
    out.height = src.height * scale;
    out.rgba.resize(std::size_t(out.width) * out.height * 4);
    for (int y = 0; y < out.height; ++y)
        for (int x = 0; x < out.width; ++x) std::copy_n(px(src, x / scale, y / scale), 4, &out.rgba[(std::size_t(y) * out.width + x) * 4]);
    return out;
}

}  // namespace

Image tile_check_preview(const Image& img, int tw, int th, int tile, const TileSeamReport& report, int scale) {
    scale = std::max(1, scale);
    Image tiled;
    tiled.width = tw * 3;
    tiled.height = th * 3;
    tiled.rgba.assign(std::size_t(tiled.width) * tiled.height * 4, 0);
    const int columns = std::max(1, img.width / std::max(1, tw));
    const int ox = (tile % columns) * tw, oy = (tile / columns) * th;
    for (int y = 0; y < tiled.height; ++y)
        for (int x = 0; x < tiled.width; ++x) {
            const int sx = ox + x % tw, sy = oy + y % th;
            if (sx < img.width && sy < img.height) std::copy_n(px(img, sx, sy), 4, &tiled.rgba[(std::size_t(y) * tiled.width + x) * 4]);
        }
    Image out = magnified(tiled, scale);
    const int band = std::max(1, scale / 2);
    for (const TileSeam& seam : report.bad) {
        if (seam.a != tile) continue;
        for (const auto& run : seam.runs) {
            if (seam.axis == "horizontal") {
                for (int boundary : {tw * scale, tw * 2 * scale}) fill_rect(out, boundary - band, (th + run.first) * scale, boundary + band, (th + run.second + 1) * scale);
            } else {
                for (int boundary : {th * scale, th * 2 * scale}) fill_rect(out, (tw + run.first) * scale, boundary - band, (tw + run.second + 1) * scale, boundary + band);
            }
        }
    }
    return out;
}

Image tile_set_preview(const Image& img, int tw, int th, const TileSeamReport& report, int scale) {
    scale = std::max(1, scale);
    Image out = magnified(img, scale);
    const int columns = std::max(1, report.columns);
    const int band = std::max(1, scale / 2);
    for (const TileSeam& seam : report.bad) {
        for (const auto& run : seam.runs) {
            const int ax = (seam.a % columns) * tw, ay = (seam.a / columns) * th, bx = (seam.b % columns) * tw, by = (seam.b / columns) * th;
            if (seam.axis == "horizontal") {
                fill_rect(out, (ax + tw) * scale - band, (ay + run.first) * scale, (ax + tw) * scale, (ay + run.second + 1) * scale);
                fill_rect(out, bx * scale, (by + run.first) * scale, bx * scale + band, (by + run.second + 1) * scale);
            } else {
                fill_rect(out, (ax + run.first) * scale, (ay + th) * scale - band, (ax + run.second + 1) * scale, (ay + th) * scale);
                fill_rect(out, (bx + run.first) * scale, by * scale, (bx + run.second + 1) * scale, by * scale + band);
            }
        }
    }
    return out;
}

}  // namespace fa
