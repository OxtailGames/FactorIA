// Pixel-exact drawing and palette-indexed pictures (fa/tooling/pixel_art.h, docs/IMAGES.md "Pixel art").
#include "fa/tooling/pixel_art.h"

#include <algorithm>
#include <cmath>
#include <format>
#include <map>
#include <set>

#include "fa/core/strings.h"

namespace fa {

namespace {

std::array<double, 3> oklab(std::uint8_t r8, std::uint8_t g8, std::uint8_t b8) {
    auto lin = [](double c) { return c <= 0.04045 ? c / 12.92 : std::pow((c + 0.055) / 1.055, 2.4); };
    const double r = lin(r8 / 255.0), g = lin(g8 / 255.0), b = lin(b8 / 255.0);
    const double l = std::cbrt(0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b);
    const double m = std::cbrt(0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b);
    const double s = std::cbrt(0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b);
    return {0.2104542553 * l + 0.7936177850 * m - 0.0040720468 * s,
            1.9779984951 * l - 2.4285922050 * m + 0.4505937099 * s,
            0.0259040371 * l + 0.7827717662 * m - 0.8086757660 * s};
}

double dist2(const std::array<double, 3>& a, const std::array<double, 3>& b) {
    const double dl = a[0] - b[0], da = a[1] - b[1], db = a[2] - b[2];
    return dl * dl + da * da + db * db;
}

std::string hex_of(const std::array<std::uint8_t, 3>& c) {
    return std::format("#{:02x}{:02x}{:02x}", c[0], c[1], c[2]);
}

void sort_unique(std::vector<PixelPoint>& v) {
    std::sort(v.begin(), v.end());
    v.erase(std::unique(v.begin(), v.end()), v.end());
}

}  // namespace

char pixel_index_char(int index) {
    if (index == -1) return kPixelTransparentChar;
    return index >= 0 && index < kMaxIndexedColours ? kPixelIndexChars[std::size_t(index)] : '?';
}

int pixel_char_index(char c) {
    if (c == kPixelTransparentChar) return -1;
    const auto pos = kPixelIndexChars.find(c);
    return pos == std::string_view::npos ? -2 : int(pos);
}

// ---- palette -----------------------------------------------------------------------------------------------------------------

std::string PixelPalette::hex(int index) const {
    return index >= 0 && index < size() ? hex_of(entries[std::size_t(index)].rgb) : std::string();
}

std::string PixelPalette::label(int index) const {
    if (index < 0 || index >= size()) return "transparent";
    const Entry& e = entries[std::size_t(index)];
    return e.name.empty() ? hex_of(e.rgb) : e.name;
}

std::optional<int> PixelPalette::find_name(std::string_view name) const {
    for (int i = 0; i < size(); ++i)
        if (!entries[std::size_t(i)].name.empty() && entries[std::size_t(i)].name == name) return i;
    const std::string lower = to_lower(std::string(name));
    for (int i = 0; i < size(); ++i)
        if (!entries[std::size_t(i)].name.empty() && to_lower(entries[std::size_t(i)].name) == lower) return i;
    return std::nullopt;
}

std::optional<int> PixelPalette::find_rgb(std::uint8_t r, std::uint8_t g, std::uint8_t b) const {
    for (int i = 0; i < size(); ++i)
        if (entries[std::size_t(i)].rgb == std::array<std::uint8_t, 3>{r, g, b}) return i;
    return std::nullopt;
}

int PixelPalette::nearest(std::uint8_t r, std::uint8_t g, std::uint8_t b) const {
    const auto p = oklab(r, g, b);
    int best = 0;
    double bestD = 1e30;
    for (int i = 0; i < size(); ++i) {
        const auto& c = entries[std::size_t(i)].rgb;
        const double d = dist2(p, oklab(c[0], c[1], c[2]));
        if (d < bestD) bestD = d, best = i;
    }
    return best;
}

std::optional<std::pair<int, int>> PixelPalette::ramp_of(int index) const {
    for (std::size_t r = 0; r < ramps.size(); ++r)
        for (std::size_t k = 0; k < ramps[r].size(); ++k)
            if (ramps[r][k] == index) return std::make_pair(int(r), int(k));
    return std::nullopt;
}

int PixelPalette::step(int index, int steps) const {
    if (index < 0 || index >= size() || steps == 0) return index;
    const int dir = steps < 0 ? -1 : 1;
    for (int n = std::abs(steps); n > 0; --n) {
        if (auto at = ramp_of(index)) {
            const auto& ramp = ramps[std::size_t(at->first)];
            const int next = std::clamp(at->second + dir, 0, int(ramp.size()) - 1);
            index = ramp[std::size_t(next)];
            continue;
        }
        const auto& own = entries[std::size_t(index)].rgb;
        const auto lab = oklab(own[0], own[1], own[2]);
        int best = index;
        double bestD = 1e30;
        for (int i = 0; i < size(); ++i) {
            if (i == index) continue;
            const auto& c = entries[std::size_t(i)].rgb;
            const auto other = oklab(c[0], c[1], c[2]);
            if (dir < 0 ? other[0] >= lab[0] - 1e-6 : other[0] <= lab[0] + 1e-6) continue;
            const double d = dist2(lab, other);
            if (d < bestD) bestD = d, best = i;
        }
        if (best == index) break;
        index = best;
    }
    return index;
}

Result<int> pixel_palette_find(const PixelPalette& palette, const Json& ref, bool allowTransparent) {
    const int n = palette.size();
    std::vector<std::string> labels;
    for (int i = 0; i < n; ++i) labels.push_back(palette.label(i));
    const std::string forms = "A palette colour is its index (3), its name (\"skin\") or its colour (\"#e0a070\"); " +
                              std::string(allowTransparent ? "null or \".\" is transparent. " : "") +
                              "Palette: " + join(labels, ", ") + ".";
    if (ref.is_null()) {
        if (allowTransparent) return -1;
        return make_error("A colour is required here, got null.", forms);
    }
    if (ref.is_number_integer()) {
        const long long i = ref.get<long long>();
        if (i < 0 || i >= n)
            return make_error(
                std::format("Palette index {} is outside the palette of {} colours (0 to {}).", i, n, n - 1), forms);
        return int(i);
    }
    if (!ref.is_string())
        return make_error("A colour is an index, a name or a palette colour, got " + describe_json_value(ref) + ".",
                          forms);
    const std::string s = ref.get<std::string>();
    if (allowTransparent && (s == "." || s == "transparent" || s == "none" || s.empty())) return -1;
    if (auto byName = palette.find_name(s)) return *byName;
    if (s.size() == 1) {
        const int idx = pixel_char_index(s[0]);
        if (idx >= 0) {
            if (idx >= n)
                return make_error(
                    std::format("Palette index '{}' ({}) is outside the palette of {} colours.", s, idx, n), forms);
            return idx;
        }
    }
    Color c;
    std::string err;
    if (n > 0 && json_to(ref, c, &err)) {
        const auto b = [](float v) { return std::uint8_t(std::lround(std::clamp(v, 0.0f, 1.0f) * 255.0f)); };
        const std::uint8_t r = b(c.r), g = b(c.g), bl = b(c.b);
        if (auto found = palette.find_rgb(r, g, bl)) return *found;
        const int near = palette.nearest(r, g, bl);
        const std::string nearLabel = palette.entries[std::size_t(near)].name.empty()
                                          ? palette.hex(near)
                                          : palette.entries[std::size_t(near)].name + " " + palette.hex(near);
        return make_error(
            std::format("The colour {} is not in the palette. The nearest palette colour is {} (index {}).",
                        hex_of({r, g, bl}), nearLabel, near),
            "Use that colour, or add the new colour to the document's palette (image.palette).");
    }
    return make_error("'" + s + "' is not a palette colour.", did_you_mean(s, labels) + " " + forms);
}

// ---- grids -------------------------------------------------------------------------------------------------------------------

std::vector<std::string> index_grid_rows(const IndexGrid& g) {
    std::vector<std::string> rows;
    rows.reserve(std::size_t(g.h));
    for (int y = 0; y < g.h; ++y) {
        std::string row(std::size_t(g.w), '.');
        for (int x = 0; x < g.w; ++x) row[std::size_t(x)] = pixel_index_char(g.v[std::size_t(y) * g.w + x]);
        rows.push_back(std::move(row));
    }
    return rows;
}

Result<IndexGrid> index_grid_from_rows(const std::vector<std::string>& rows, int paletteSize) {
    if (rows.empty())
        return make_error("An indexed picture needs at least one row.",
                          "Rows are strings of palette characters, '.' for transparent: [\"..11..\", \".1221.\"].");
    const std::size_t w = rows[0].size();
    if (w == 0) return make_error("Row 0 is empty.", "Every row has one character per pixel.");
    IndexGrid g(int(w), int(rows.size()));
    for (std::size_t y = 0; y < rows.size(); ++y) {
        if (rows[y].size() != w)
            return make_error(std::format("Row {} has {} characters but row 0 has {}.", y, rows[y].size(), w),
                              "Every row has the same width.");
        for (std::size_t x = 0; x < w; ++x) {
            const int idx = pixel_char_index(rows[y][x]);
            if (idx == -2)
                return make_error(std::format("Row {}, column {}: '{}' is not a palette character.", y, x, rows[y][x]),
                                  "Use '.' for transparent and " + std::string(kPixelIndexChars.substr(0, 12)) +
                                      "... for palette indices 0, 1, 2, ...");
            if (paletteSize >= 0 && idx >= paletteSize)
                return make_error(
                    std::format("Row {}, column {}: '{}' is palette index {}, but the palette has {} colours.", y, x,
                                rows[y][x], idx, paletteSize),
                    paletteSize > 0 ? std::format("The palette characters are {}.",
                                                  std::string(kPixelIndexChars.substr(0, std::size_t(paletteSize))))
                                    : "Give the document a palette first.");
            g.v[y * w + x] = idx;
        }
    }
    return g;
}

Image index_grid_image(const IndexGrid& g, const PixelPalette& palette) {
    Image img;
    img.width = g.w;
    img.height = g.h;
    img.rgba.assign(std::size_t(g.w) * g.h * 4, 0);
    for (std::size_t i = 0; i < g.v.size(); ++i) {
        const int idx = g.v[i];
        if (idx < 0 || idx >= palette.size()) continue;
        const auto& c = palette.entries[std::size_t(idx)].rgb;
        img.rgba[i * 4] = c[0];
        img.rgba[i * 4 + 1] = c[1];
        img.rgba[i * 4 + 2] = c[2];
        img.rgba[i * 4 + 3] = 255;
    }
    return img;
}

// ---- shapes ------------------------------------------------------------------------------------------------------------------

std::vector<PixelPoint> pixel_line(PixelPoint a, PixelPoint b) {
    std::vector<PixelPoint> out;
    const int dx = std::abs(b.x - a.x), sx = a.x < b.x ? 1 : -1;
    const int dy = -std::abs(b.y - a.y), sy = a.y < b.y ? 1 : -1;
    int err = dx + dy;
    int x = a.x, y = a.y;
    for (;;) {
        out.push_back({x, y});
        if (x == b.x && y == b.y) break;
        const int e2 = 2 * err;
        if (e2 >= dy) {
            err += dy;
            x += sx;
        }
        if (e2 <= dx) {
            err += dx;
            y += sy;
        }
    }
    return out;
}

std::vector<PixelPoint> pixel_perfect(const std::vector<PixelPoint>& chain) {
    if (chain.size() < 3) return chain;
    std::vector<PixelPoint> out{chain.front()};
    for (std::size_t i = 1; i + 1 < chain.size(); ++i) {
        const PixelPoint& prev = out.back();
        const PixelPoint& next = chain[i + 1];
        if (std::abs(prev.x - next.x) == 1 && std::abs(prev.y - next.y) == 1) continue;  // chain[i] only turns a corner
        out.push_back(chain[i]);
    }
    out.push_back(chain.back());
    return out;
}

std::vector<PixelPoint> pixel_polyline(const std::vector<PixelPoint>& points, bool perfect, bool closed) {
    std::vector<PixelPoint> pts;
    for (const PixelPoint& p : points)
        if (pts.empty() || !(pts.back() == p)) pts.push_back(p);
    if (closed && pts.size() > 1 && !(pts.back() == pts.front())) pts.push_back(pts.front());
    std::vector<PixelPoint> chain;
    if (pts.size() == 1) chain = pts;
    for (std::size_t i = 0; i + 1 < pts.size(); ++i) {
        auto seg = pixel_line(pts[i], pts[i + 1]);
        chain.insert(chain.end(), chain.empty() ? seg.begin() : seg.begin() + 1, seg.end());
    }
    return perfect ? pixel_perfect(chain) : chain;
}

std::vector<PixelPoint> pixel_rect(int x, int y, int width, int height, bool filled) {
    std::vector<PixelPoint> out;
    if (width < 1 || height < 1) return out;
    for (int j = 0; j < height; ++j)
        for (int i = 0; i < width; ++i)
            if (filled || j == 0 || j == height - 1 || i == 0 || i == width - 1) out.push_back({x + i, y + j});
    return out;
}

std::vector<PixelPoint> pixel_ellipse(int x, int y, int width, int height, bool filled) {
    std::vector<PixelPoint> out;
    if (width < 1 || height < 1) return out;
    // Zingl's midpoint ellipse in a rectangle (exact for odd and even sizes)
    long long x0 = x, y0 = y, x1 = x + width - 1, y1 = y + height - 1;
    long long a = std::llabs(x1 - x0), b = std::llabs(y1 - y0), b1 = b & 1;
    long long dx = 4 * (1 - a) * b * b, dy = 4 * (b1 + 1) * a * a;
    long long err = dx + dy + b1 * a * a, e2;
    y0 += (b + 1) / 2;
    y1 = y0 - b1;
    a *= 8 * a;
    b1 = 8 * b * b;
    auto plot = [&](long long px, long long py) { out.push_back({int(px), int(py)}); };
    do {
        plot(x1, y0);
        plot(x0, y0);
        plot(x0, y1);
        plot(x1, y1);
        e2 = 2 * err;
        if (e2 <= dy) {
            y0++;
            y1--;
            err += dy += a;
        }
        if (e2 >= dx || 2 * err > dy) {
            x0++;
            x1--;
            err += dx += b1;
        }
    } while (x0 <= x1);
    while (y0 - y1 < b) {  // a flat ellipse: finish the tips
        plot(x0 - 1, y0);
        plot(x1 + 1, y0++);
        plot(x0 - 1, y1);
        plot(x1 + 1, y1--);
    }
    if (filled) {
        std::map<int, std::pair<int, int>> span;  // row -> [min x, max x]
        for (const PixelPoint& p : out) {
            auto [it, fresh] = span.try_emplace(p.y, std::make_pair(p.x, p.x));
            if (!fresh) it->second = {std::min(it->second.first, p.x), std::max(it->second.second, p.x)};
        }
        out.clear();
        for (const auto& [row, s] : span)
            for (int px = s.first; px <= s.second; ++px) out.push_back({px, row});
    }
    sort_unique(out);
    return out;
}

std::vector<PixelPoint> pixel_polygon(const std::vector<PixelPoint>& points, bool filled) {
    std::vector<PixelPoint> out = pixel_polyline(points, false, true);
    if (filled && points.size() >= 3) {
        int minY = points[0].y, maxY = points[0].y;
        for (const PixelPoint& p : points) minY = std::min(minY, p.y), maxY = std::max(maxY, p.y);
        const std::size_t n = points.size();
        for (int y = minY; y <= maxY; ++y) {
            const double yc = y + 0.5;
            std::vector<double> xs;
            for (std::size_t i = 0; i < n; ++i) {
                const PixelPoint& p = points[i];
                const PixelPoint& q = points[(i + 1) % n];
                if (p.y == q.y) continue;
                const double py = p.y + 0.5, qy = q.y + 0.5;
                if (yc < std::min(py, qy) || yc >= std::max(py, qy)) continue;
                xs.push_back(p.x + 0.5 + (yc - py) * (q.x - p.x) / (qy - py));
            }
            std::sort(xs.begin(), xs.end());
            for (std::size_t k = 0; k + 1 < xs.size(); k += 2) {
                const int from = int(std::ceil(xs[k] - 0.5)), to = int(std::ceil(xs[k + 1] - 0.5)) - 1;
                for (int x = from; x <= to; ++x) out.push_back({x, y});
            }
        }
    }
    sort_unique(out);
    return out;
}

std::vector<PixelPoint> pixel_flood(const IndexGrid& grid, int x, int y, bool eightConnected) {
    std::vector<PixelPoint> out;
    if (!grid.inside(x, y)) return out;
    const int target = grid.at(x, y);
    std::vector<char> seen(grid.v.size(), 0);
    std::vector<PixelPoint> stack{{x, y}};
    seen[std::size_t(y) * grid.w + x] = 1;
    while (!stack.empty()) {
        const PixelPoint p = stack.back();
        stack.pop_back();
        out.push_back(p);
        for (int dy = -1; dy <= 1; ++dy)
            for (int dx = -1; dx <= 1; ++dx) {
                if ((dx == 0 && dy == 0) || (!eightConnected && dx != 0 && dy != 0)) continue;
                const int nx = p.x + dx, ny = p.y + dy;
                if (!grid.inside(nx, ny) || seen[std::size_t(ny) * grid.w + nx] || grid.at(nx, ny) != target) continue;
                seen[std::size_t(ny) * grid.w + nx] = 1;
                stack.push_back({nx, ny});
            }
    }
    std::sort(out.begin(), out.end());
    return out;
}

}  // namespace fa

// =====================================================================================================================================
// Pixel helpers
// =====================================================================================================================================

namespace fa {

namespace {

bool writable(const PixelMask& mask, const IndexGrid& g, int x, int y) {
    return mask.empty() || mask[std::size_t(y) * g.w + x] != 0;
}

// Sets a pixel when it differs; returns 1 when it did.
int put(IndexGrid& g, int x, int y, int v) {
    if (!g.inside(x, y) || g.v[std::size_t(y) * g.w + x] == v) return 0;
    g.set(x, y, v);
    return 1;
}

int darkest_of(const PixelPalette& pal, int index) {
    if (auto r = pal.ramp_of(index)) return pal.ramps[std::size_t(r->first)][0];
    return pal.step(index, -16);
}

// Votes for the most common value; ties go to the one seen first.
struct Votes {
    std::vector<std::pair<int, int>> v;
    void add(int value) {
        for (auto& e : v)
            if (e.first == value) {
                ++e.second;
                return;
            }
        v.push_back({value, 1});
    }
    bool empty() const { return v.empty(); }
    int best() const {
        int bi = 0;
        for (std::size_t i = 1; i < v.size(); ++i)
            if (v[i].second > v[std::size_t(bi)].second) bi = int(i);
        return v[std::size_t(bi)].first;
    }
};

}  // namespace

PixelLight pixel_light(double degrees) {
    const double r = degrees * 3.14159265358979323846 / 180.0;
    return {std::cos(r), -std::sin(r)};
}

int pixel_bayer(int n, int x, int y) {
    static const std::vector<int> m2 = {0, 2, 3, 1};
    static const auto grow = [](const std::vector<int>& m, int size) {
        std::vector<int> next(std::size_t(size) * size * 4);
        const int s2 = size * 2;
        for (int y = 0; y < size; ++y)
            for (int x = 0; x < size; ++x) {
                const int v = m[std::size_t(y) * size + x] * 4;
                next[std::size_t(y) * s2 + x] = v;
                next[std::size_t(y) * s2 + x + size] = v + 2;
                next[std::size_t(y + size) * s2 + x] = v + 3;
                next[std::size_t(y + size) * s2 + x + size] = v + 1;
            }
        return next;
    };
    static const std::vector<int> m4 = grow(m2, 2);
    static const std::vector<int> m8 = grow(m4, 4);
    const std::vector<int>& m = n == 2 ? m2 : n == 4 ? m4 : m8;
    const int size = n == 2 ? 2 : n == 4 ? 4 : 8;
    return m[std::size_t(((y % size) + size) % size) * size + std::size_t(((x % size) + size) % size)];
}

// ---- outline ---------------------------------------------------------------------------------------------------------------------

int pixel_outline(IndexGrid& g, const PixelPalette& pal, const PixelOutline& o, const PixelMask& mask) {
    const IndexGrid src = g;
    const PixelLight light = pixel_light(o.lightDegrees);
    int changed = 0;
    for (int y = 0; y < src.h; ++y)
        for (int x = 0; x < src.w; ++x) {
            if (!writable(mask, src, x, y)) continue;
            const int own = src.at(x, y);
            if (o.inner ? own < 0 : own >= 0) continue;
            Votes votes;
            double sx = 0, sy = 0;  // the sum of the directions towards the neighbours that count
            for (int dy = -1; dy <= 1; ++dy)
                for (int dx = -1; dx <= 1; ++dx) {
                    if ((dx == 0 && dy == 0) || (!o.eightConnected && dx != 0 && dy != 0)) continue;
                    const int n = src.at(x + dx, y + dy);
                    if (o.inner ? n != -1 : n < 0) continue;  // inner: next to transparency; outer: next to the shape
                    votes.add(n);
                    sx += dx;
                    sy += dy;
                }
            if (votes.empty()) continue;
            const int fill = o.inner ? own : votes.best();
            const double ox = o.inner ? sx : -sx, oy = o.inner ? sy : -sy;  // outwards, from the shape
            int colour = o.color;
            if (o.colour == PixelOutline::Colour::RampDarkest) {
                colour = darkest_of(pal, fill);
            } else if (o.colour == PixelOutline::Colour::Selective) {
                const bool lit = o.hasLight && ox * light.x + oy * light.y > 1e-9;
                colour = pal.step(fill, -(lit ? o.litShade : o.shade));
            }
            changed += put(g, x, y, colour);
        }
    return changed;
}

// ---- shading ---------------------------------------------------------------------------------------------------------------------

namespace {

// The amount (in steps) of a band system at depth d pixels from the edge: `levels` bands of `width`, the one at the edge the strongest.
int band_amount(int d, int width, int levels, int dither, int x, int y) {
    if (levels <= 0 || width <= 0) return 0;
    const int b = d / width, r = d % width;
    int amount = b < levels ? levels - b : 0;
    if (dither > 0 && b >= 1 && b <= levels && r < dither) {
        // the first pixels of a band are a mix with the stronger band before it
        if (pixel_bayer(4, x, y) * (dither + 1) < 16 * (dither - r)) amount = levels - b + 1;
    }
    return amount;
}

}  // namespace

int pixel_shade(IndexGrid& g, const PixelPalette& pal, const PixelShade& o, const PixelMask& mask) {
    const IndexGrid src = g;
    PixelLight light = pixel_light(o.lightDegrees);
    // a step of the ray moves one whole pixel along the light's longer axis, so a band's width counts pixels also on a diagonal
    const double longer = std::max(std::abs(light.x), std::abs(light.y));
    if (longer > 1e-9) light = {light.x / longer, light.y / longer};
    auto body = [&](int x, int y) { return src.at(x, y) >= 0 && writable(mask, src, x, y); };
    // how many pixels of the body lie in a direction from (x, y) before it ends (at most `limit`)
    auto reach = [&](int x, int y, double dx, double dy, int limit) {
        for (int k = 1; k <= limit; ++k) {
            const int qx = int(std::floor(x + k * dx + 0.5)), qy = int(std::floor(y + k * dy + 0.5));
            if (!src.inside(qx, qy) || !body(qx, qy)) return k - 1;
        }
        return limit;
    };
    const int shadowLimit = o.shadowLevels > 0 ? o.shadowLevels * o.shadowWidth + o.dither : 0;
    const int lightLimit = o.highlightLevels > 0 ? o.highlightLevels * o.highlightWidth + o.dither : 0;
    int changed = 0;
    for (int y = 0; y < src.h; ++y)
        for (int x = 0; x < src.w; ++x) {
            if (!body(x, y)) continue;
            const int cx = x + o.origin.x, cy = y + o.origin.y;
            int amount = 0;
            if (shadowLimit > 0)
                amount = -band_amount(reach(x, y, -light.x, -light.y, shadowLimit), o.shadowWidth, o.shadowLevels,
                                      o.dither, cx, cy);
            if (amount == 0 && lightLimit > 0)
                amount = band_amount(reach(x, y, light.x, light.y, lightLimit), o.highlightWidth, o.highlightLevels,
                                     o.dither, cx, cy);
            if (amount != 0) changed += put(g, x, y, pal.step(src.at(x, y), amount));
        }
    return changed;
}

// ---- dither ----------------------------------------------------------------------------------------------------------------------

namespace {

// true: the pixel takes colour b, for a share `level` of b.
bool dither_pick_b(double level, DitherPattern pattern, int x, int y) {
    level = std::clamp(level, 0.0, 1.0);
    if (pattern == DitherPattern::Checker) {
        if (level < 0.25) return false;
        if (level > 0.75) return true;
        return ((x + y) & 1) == 0;
    }
    const int n = pattern == DitherPattern::Bayer2 ? 2 : pattern == DitherPattern::Bayer4 ? 4 : 8;
    const int k = int(std::lround(level * n * n));
    return pixel_bayer(n, x, y) < k;
}

}  // namespace

int pixel_dither_blend(IndexGrid& g, int a, int b, double level, DitherPattern pattern, const PixelMask& mask,
                       bool onlyFilled, PixelPoint origin) {
    int changed = 0;
    for (int y = 0; y < g.h; ++y)
        for (int x = 0; x < g.w; ++x) {
            if (!writable(mask, g, x, y) || (onlyFilled && g.at(x, y) < 0)) continue;
            changed += put(g, x, y, dither_pick_b(level, pattern, x + origin.x, y + origin.y) ? b : a);
        }
    return changed;
}

int pixel_dither_gradient(IndexGrid& g, const std::vector<int>& colors, PixelPoint from, PixelPoint to,
                          DitherPattern pattern, const PixelMask& mask, bool onlyFilled, PixelPoint origin) {
    if (colors.size() < 2) return 0;
    const double dx = to.x - from.x, dy = to.y - from.y, len2 = dx * dx + dy * dy;
    const int segments = int(colors.size()) - 1;
    int changed = 0;
    for (int y = 0; y < g.h; ++y)
        for (int x = 0; x < g.w; ++x) {
            if (!writable(mask, g, x, y) || (onlyFilled && g.at(x, y) < 0)) continue;
            const double t = len2 > 0 ? std::clamp(((x - from.x) * dx + (y - from.y) * dy) / len2, 0.0, 1.0) : 0.0;
            const double u = t * segments;
            const int seg = std::min(segments - 1, int(std::floor(u)));
            const double f = u - seg;
            const int a = colors[std::size_t(seg)], b = colors[std::size_t(seg) + 1];
            changed += put(g, x, y, dither_pick_b(f, pattern, x + origin.x, y + origin.y) ? b : a);
        }
    return changed;
}

// ---- clean-up --------------------------------------------------------------------------------------------------------------------

namespace {

bool kept(const std::vector<int>& keep, int v) { return std::find(keep.begin(), keep.end(), v) != keep.end(); }

}  // namespace

PixelCleanupReport pixel_cleanup(IndexGrid& g, const PixelCleanup& o, const PixelMask& mask) {
    PixelCleanupReport report;
    const IndexGrid original = g;
    // orphans: simultaneous, decided on the picture as it is
    if (o.orphans) {
        const IndexGrid src = g;
        for (int y = 0; y < src.h; ++y)
            for (int x = 0; x < src.w; ++x) {
                if (!writable(mask, src, x, y)) continue;
                const int v = src.at(x, y);
                if ((v < 0 && !o.holes) || kept(o.keep, v)) continue;
                bool same = false;
                Votes votes;
                for (int dy = -1; dy <= 1 && !same; ++dy)
                    for (int dx = -1; dx <= 1; ++dx) {
                        if (dx == 0 && dy == 0) continue;
                        const int n = src.at(x + dx, y + dy);
                        const bool diagonal = dx != 0 && dy != 0;
                        if (n == -2) {
                            if (v < 0) same = true;  // a hole at the edge of the picture is not enclosed
                            continue;
                        }
                        if (n == v && (!diagonal || o.eightConnected)) {
                            same = true;
                            break;
                        }
                        if (n >= 0 && n != v) votes.add(n);
                    }
                if (same) continue;
                report.orphans += put(g, x, y, votes.empty() ? -1 : votes.best());
            }
    }
    // doubles: the corner pixel of a one-pixel line where it turns, unless it is a true right angle (both arms keep going straight)
    if (o.doubles) {
        for (int pass = 0; pass < 4; ++pass) {
            int removed = 0;
            for (int y = 0; y < g.h; ++y)
                for (int x = 0; x < g.w; ++x) {
                    if (!writable(mask, g, x, y)) continue;
                    const int v = g.at(x, y);
                    if (v < 0 || kept(o.keep, v)) continue;
                    int count = 0;
                    for (int dy = -1; dy <= 1; ++dy)
                        for (int dx = -1; dx <= 1; ++dx)
                            if ((dx || dy) && g.at(x + dx, y + dy) == v) ++count;
                    if (count != 2) continue;
                    const bool l = g.at(x - 1, y) == v, r = g.at(x + 1, y) == v, u = g.at(x, y - 1) == v,
                               d = g.at(x, y + 1) == v;
                    if (!((l != r) && (u != d) && (l || r) && (u || d)))
                        continue;  // one horizontal and one vertical neighbour, nothing else
                    const int hx = l ? -1 : 1, vy = u ? -1 : 1;
                    if (g.at(x + 2 * hx, y) == v && g.at(x, y + 2 * vy) == v)
                        continue;  // a right angle of a shape, not a bend of a line
                    Votes votes;
                    votes.add(g.at(x - hx, y));
                    votes.add(g.at(x, y - vy));
                    votes.add(g.at(x - hx, y - vy));
                    int bg = votes.best();
                    if (bg == -2) bg = -1;
                    if (bg == v) continue;
                    removed += put(g, x, y, bg);
                }
            report.doubles += removed;
            if (!removed) break;
        }
    }
    // jaggies: a nearly straight one-pixel line with uneven steps is redrawn between its ends
    if (o.jaggies) {
        const IndexGrid src = g;
        std::vector<std::uint8_t> visited(src.v.size(), 0);
        auto same_neighbours = [&](int x, int y) {
            std::vector<PixelPoint> out;
            const int v = src.at(x, y);
            for (int dy = -1; dy <= 1; ++dy)
                for (int dx = -1; dx <= 1; ++dx)
                    if ((dx || dy) && src.at(x + dx, y + dy) == v) out.push_back({x + dx, y + dy});
            return out;
        };
        for (int y = 0; y < src.h; ++y)
            for (int x = 0; x < src.w; ++x) {
                const int v = src.at(x, y);
                if (v < 0 || visited[std::size_t(y) * src.w + x] || kept(o.keep, v)) continue;
                if (same_neighbours(x, y).size() != 1) continue;  // a chain starts at an end
                std::vector<PixelPoint> chain{{x, y}};
                visited[std::size_t(y) * src.w + x] = 1;
                bool valid = true;
                PixelPoint prev{-100, -100}, cur{x, y};
                while (true) {
                    std::vector<PixelPoint> next;
                    for (const PixelPoint& n : same_neighbours(cur.x, cur.y))
                        if (!(n == prev)) next.push_back(n);
                    if (next.empty()) break;
                    if (next.size() > 1 || visited[std::size_t(next[0].y) * src.w + next[0].x]) {
                        valid = false;
                        break;
                    }
                    prev = cur;
                    cur = next[0];
                    visited[std::size_t(cur.y) * src.w + cur.x] = 1;
                    chain.push_back(cur);
                    if (same_neighbours(cur.x, cur.y).size() > 2) {
                        valid = false;
                        break;
                    }
                }
                if (!valid || chain.size() < 5 || same_neighbours(cur.x, cur.y).size() != 1) continue;
                bool allowed = true;
                for (const PixelPoint& p : chain) allowed = allowed && writable(mask, src, p.x, p.y);
                if (!allowed) continue;
                const PixelPoint e0 = chain.front(), e1 = chain.back();
                const double ex = e1.x - e0.x, ey = e1.y - e0.y, len = std::sqrt(ex * ex + ey * ey);
                if (len < 1) continue;
                double stray = 0;
                for (const PixelPoint& p : chain)
                    stray = std::max(stray, std::abs((p.x - e0.x) * ey - (p.y - e0.y) * ex) / len);
                if (stray > o.tolerance + 1e-9) continue;
                // the steps: groups of pixels sharing the minor coordinate, along the major axis
                const bool xMajor = std::abs(ex) >= std::abs(ey);
                std::vector<int> runs;
                bool monotonic = true;
                for (std::size_t i = 0; i < chain.size(); ++i) {
                    const int major = xMajor ? chain[i].x : chain[i].y, minor = xMajor ? chain[i].y : chain[i].x;
                    if (i == 0) {
                        runs.push_back(1);
                        continue;
                    }
                    const int pmajor = xMajor ? chain[i - 1].x : chain[i - 1].y,
                              pminor = xMajor ? chain[i - 1].y : chain[i - 1].x;
                    if (std::abs(major - pmajor) > 1 || (xMajor ? ex : ey) * (major - pmajor) < 0) monotonic = false;
                    if (minor == pminor)
                        ++runs.back();
                    else
                        runs.push_back(1);
                }
                if (!monotonic || runs.size() < 4) continue;
                const int lo = *std::min_element(runs.begin() + 1, runs.end() - 1),
                          hi = *std::max_element(runs.begin() + 1, runs.end() - 1);
                if (hi - lo <= 1) continue;
                std::vector<PixelPoint> ideal = pixel_line(e0, e1);
                std::set<PixelPoint> have(chain.begin(), chain.end()), want(ideal.begin(), ideal.end());
                Votes bgVotes;
                for (const PixelPoint& p : chain)
                    for (int dy = -1; dy <= 1; ++dy)
                        for (int dx = -1; dx <= 1; ++dx) {
                            const PixelPoint n{p.x + dx, p.y + dy};
                            if (have.count(n) || src.at(n.x, n.y) == -2) continue;
                            bgVotes.add(src.at(n.x, n.y));
                        }
                const int bg = bgVotes.empty() ? -1 : bgVotes.best();
                bool free = true;
                for (const PixelPoint& p : ideal)
                    if (!have.count(p) && (src.at(p.x, p.y) != bg || !writable(mask, src, p.x, p.y))) free = false;
                if (!free) continue;
                for (const PixelPoint& p : chain)
                    if (!want.count(p)) report.jaggies += put(g, p.x, p.y, bg);
                for (const PixelPoint& p : ideal)
                    if (!have.count(p)) report.jaggies += put(g, p.x, p.y, v);
            }
    }
    for (int y = 0; y < g.h; ++y)
        for (int x = 0; x < g.w; ++x)
            if (g.at(x, y) != original.at(x, y)) report.changed.push_back({x, y});
    return report;
}

// ---- scaling and rotation -----------------------------------------------------------------------------------------------------------

IndexGrid pixel_scale2x(const IndexGrid& g) {
    IndexGrid out(g.w * 2, g.h * 2);
    auto at = [&](int x, int y) { return g.at(std::clamp(x, 0, g.w - 1), std::clamp(y, 0, g.h - 1)); };
    for (int y = 0; y < g.h; ++y)
        for (int x = 0; x < g.w; ++x) {
            const int B = at(x, y - 1), D = at(x - 1, y), E = at(x, y), F = at(x + 1, y), H = at(x, y + 1);
            out.set(2 * x, 2 * y, (D == B && B != F && D != H) ? D : E);
            out.set(2 * x + 1, 2 * y, (B == F && B != D && F != H) ? F : E);
            out.set(2 * x, 2 * y + 1, (D == H && D != B && H != F) ? D : E);
            out.set(2 * x + 1, 2 * y + 1, (H == F && D != H && B != F) ? F : E);
        }
    return out;
}

IndexGrid pixel_scale3x(const IndexGrid& g) {
    IndexGrid out(g.w * 3, g.h * 3);
    auto at = [&](int x, int y) { return g.at(std::clamp(x, 0, g.w - 1), std::clamp(y, 0, g.h - 1)); };
    for (int y = 0; y < g.h; ++y)
        for (int x = 0; x < g.w; ++x) {
            const int A = at(x - 1, y - 1), B = at(x, y - 1), C = at(x + 1, y - 1), D = at(x - 1, y), E = at(x, y),
                      F = at(x + 1, y), G = at(x - 1, y + 1), H = at(x, y + 1), I = at(x + 1, y + 1);
            const int e[9] = {
                (D == B && D != H && B != F) ? D : E,
                ((D == B && D != H && B != F && E != C) || (B == F && B != D && F != H && E != A)) ? B : E,
                (B == F && B != D && F != H) ? F : E,
                ((H == D && H != F && D != B && E != A) || (D == B && D != H && B != F && E != G)) ? D : E,
                E,
                ((B == F && B != D && F != H && E != I) || (F == H && F != B && H != D && E != C)) ? F : E,
                (H == D && H != F && D != B) ? D : E,
                ((F == H && F != B && H != D && E != G) || (H == D && H != F && D != B && E != I)) ? H : E,
                (F == H && F != B && H != D) ? F : E};
            for (int k = 0; k < 9; ++k) out.set(3 * x + k % 3, 3 * y + k / 3, e[k]);
        }
    return out;
}

namespace {

// The commonest value of a box of the grid; a tie goes to an opaque colour, then to the lower index.
int box_mode(const IndexGrid& g, int x0, int y0, int x1, int y1, std::vector<int>& counts) {
    std::fill(counts.begin(), counts.end(), 0);
    for (int y = y0; y < y1; ++y)
        for (int x = x0; x < x1; ++x) ++counts[std::size_t(g.at(x, y) + 1)];
    int best = -1, bestCount = 0;
    for (std::size_t i = 1; i < counts.size(); ++i)  // opaque first, so a tie keeps the lower opaque index
        if (counts[i] > bestCount) bestCount = counts[i], best = int(i) - 1;
    if (counts[0] > bestCount) best = -1;
    return best;
}

int grid_max(const IndexGrid& g) {
    int m = -1;
    for (int v : g.v) m = std::max(m, v);
    return m;
}

}  // namespace

IndexGrid pixel_resample(const IndexGrid& g, int nw, int nh, PixelResample method) {
    IndexGrid out(std::max(1, nw), std::max(1, nh));
    if (g.w <= 0 || g.h <= 0) return out;
    std::vector<int> counts(std::size_t(grid_max(g) + 2));
    for (int y = 0; y < out.h; ++y)
        for (int x = 0; x < out.w; ++x) {
            const int x0 = int(std::int64_t(x) * g.w / out.w), y0 = int(std::int64_t(y) * g.h / out.h);
            if (method == PixelResample::Nearest) {
                const int sx = int((std::int64_t(2 * x + 1) * g.w) / (2 * std::int64_t(out.w))),
                          sy = int((std::int64_t(2 * y + 1) * g.h) / (2 * std::int64_t(out.h)));
                out.set(x, y, g.at(std::min(sx, g.w - 1), std::min(sy, g.h - 1)));
            } else {
                const int x1 = std::max(x0 + 1, int((std::int64_t(x + 1) * g.w + out.w - 1) / out.w)),
                          y1 = std::max(y0 + 1, int((std::int64_t(y + 1) * g.h + out.h - 1) / out.h));
                out.set(x, y, box_mode(g, x0, y0, std::min(x1, g.w), std::min(y1, g.h), counts));
            }
        }
    return out;
}

namespace {

// `src` rotated by `degrees` clockwise about its centre into a grid of outW x outH whose centre is the same point.
IndexGrid rotate_sampled(const IndexGrid& src, double degrees, int outW, int outH) {
    IndexGrid out(outW, outH);
    const double r = degrees * 3.14159265358979323846 / 180.0, c = std::cos(r), s = std::sin(r);
    const double scx = src.w / 2.0, scy = src.h / 2.0, ocx = outW / 2.0, ocy = outH / 2.0;
    for (int y = 0; y < outH; ++y)
        for (int x = 0; x < outW; ++x) {
            const double dx = x + 0.5 - ocx, dy = y + 0.5 - ocy;
            const int sx = int(std::floor(scx + dx * c + dy * s)), sy = int(std::floor(scy - dx * s + dy * c));
            out.set(x, y, src.inside(sx, sy) ? src.at(sx, sy) : -1);
        }
    return out;
}

}  // namespace

IndexGrid pixel_rotate(const IndexGrid& g, double degrees, PixelRotateMethod method) {
    if (g.w <= 0 || g.h <= 0) return g;
    double deg = std::fmod(degrees, 360.0);
    if (deg < 0) deg += 360.0;
    const int quarter = int(std::lround(deg / 90.0)) % 4;
    if (std::abs(deg - std::round(deg / 90.0) * 90.0) < 1e-9) {
        if (quarter == 0) return g;
        IndexGrid out(quarter == 2 ? g.w : g.h, quarter == 2 ? g.h : g.w);
        for (int y = 0; y < g.h; ++y)
            for (int x = 0; x < g.w; ++x) {
                if (quarter == 1)
                    out.set(g.h - 1 - y, x, g.at(x, y));
                else if (quarter == 2)
                    out.set(g.w - 1 - x, g.h - 1 - y, g.at(x, y));
                else
                    out.set(y, g.w - 1 - x, g.at(x, y));
            }
        return out;
    }
    const double r = deg * 3.14159265358979323846 / 180.0;
    const int ow = std::max(1, int(std::ceil(g.w * std::abs(std::cos(r)) + g.h * std::abs(std::sin(r)) - 1e-9)));
    const int oh = std::max(1, int(std::ceil(g.w * std::abs(std::sin(r)) + g.h * std::abs(std::cos(r)) - 1e-9)));
    if (method == PixelRotateMethod::Nearest) return rotate_sampled(g, deg, ow, oh);
    IndexGrid big = pixel_scale2x(pixel_scale2x(pixel_scale2x(g)));
    const IndexGrid turned = rotate_sampled(big, deg, ow * 8, oh * 8);
    return pixel_resample(turned, ow, oh, PixelResample::Mode);
}

// ---- from a picture ---------------------------------------------------------------------------------------------------------------------

Image pixel_area_downscale(const Image& src, int nw, int nh) {
    Image out;
    out.width = std::max(1, nw);
    out.height = std::max(1, nh);
    out.rgba.assign(std::size_t(out.width) * out.height * 4, 0);
    if (src.width <= 0 || src.height <= 0) return out;
    const double sx = double(src.width) / out.width, sy = double(src.height) / out.height;
    for (int y = 0; y < out.height; ++y) {
        const double y0 = y * sy, y1 = (y + 1) * sy;
        for (int x = 0; x < out.width; ++x) {
            const double x0 = x * sx, x1 = (x + 1) * sx;
            double wsum = 0, asum = 0, r = 0, gg = 0, b = 0;
            for (int py = int(std::floor(y0)); py < std::min(src.height, int(std::ceil(y1))); ++py) {
                const double wy = std::min(y1, py + 1.0) - std::max(y0, double(py));
                for (int px = int(std::floor(x0)); px < std::min(src.width, int(std::ceil(x1))); ++px) {
                    const double w = wy * (std::min(x1, px + 1.0) - std::max(x0, double(px)));
                    const std::uint8_t* p = &src.rgba[(std::size_t(py) * src.width + px) * 4];
                    const double a = p[3] / 255.0;
                    wsum += w;
                    asum += w * a;
                    r += w * a * p[0];
                    gg += w * a * p[1];
                    b += w * a * p[2];
                }
            }
            std::uint8_t* o = &out.rgba[(std::size_t(y) * out.width + x) * 4];
            if (asum > 0 && wsum > 0) {
                o[0] = std::uint8_t(std::lround(r / asum));
                o[1] = std::uint8_t(std::lround(gg / asum));
                o[2] = std::uint8_t(std::lround(b / asum));
                o[3] = std::uint8_t(std::lround(255.0 * asum / wsum));
            }
        }
    }
    return out;
}

IndexGrid pixel_dominant_downscale(const Image& src, const PixelPalette& pal, int nw, int nh, double alphaThreshold) {
    IndexGrid out(std::max(1, nw), std::max(1, nh));
    if (src.width <= 0 || src.height <= 0 || pal.empty()) return out;
    IndexGrid full(src.width, src.height);
    std::map<std::uint32_t, int> cache;
    for (int y = 0; y < src.height; ++y)
        for (int x = 0; x < src.width; ++x) {
            const std::uint8_t* p = &src.rgba[(std::size_t(y) * src.width + x) * 4];
            if (p[3] < 128) continue;
            const std::uint32_t key = (std::uint32_t(p[0]) << 16) | (std::uint32_t(p[1]) << 8) | p[2];
            auto it = cache.find(key);
            if (it == cache.end()) it = cache.emplace(key, pal.nearest(p[0], p[1], p[2])).first;
            full.set(x, y, it->second);
        }
    std::vector<int> counts(std::size_t(pal.size() + 1));
    for (int y = 0; y < out.h; ++y)
        for (int x = 0; x < out.w; ++x) {
            const int x0 = int(std::int64_t(x) * src.width / out.w), y0 = int(std::int64_t(y) * src.height / out.h);
            const int x1 =
                std::min(src.width, std::max(x0 + 1, int((std::int64_t(x + 1) * src.width + out.w - 1) / out.w)));
            const int y1 =
                std::min(src.height, std::max(y0 + 1, int((std::int64_t(y + 1) * src.height + out.h - 1) / out.h)));
            const int cells = (x1 - x0) * (y1 - y0);
            int opaque = 0;
            for (int py = y0; py < y1; ++py)
                for (int px = x0; px < x1; ++px) opaque += full.at(px, py) >= 0 ? 1 : 0;
            if (opaque == 0 || double(opaque) / cells < alphaThreshold) continue;
            // the commonest palette colour among the opaque pixels; a tie goes to the lower index
            std::fill(counts.begin(), counts.end(), 0);
            for (int py = y0; py < y1; ++py)
                for (int px = x0; px < x1; ++px)
                    if (full.at(px, py) >= 0) ++counts[std::size_t(full.at(px, py))];
            int best = 0;
            for (std::size_t i = 1; i < counts.size(); ++i)
                if (counts[i] > counts[std::size_t(best)]) best = int(i);
            out.set(x, y, best);
        }
    return out;
}

}  // namespace fa
