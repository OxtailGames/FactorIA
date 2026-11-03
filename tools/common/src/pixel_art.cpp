// Pixel-exact drawing and palette-indexed pictures (fa/tooling/pixel_art.h, docs/IMAGES.md "Pixel art").
#include "fa/tooling/pixel_art.h"

#include <algorithm>
#include <cmath>
#include <format>
#include <map>

#include "fa/core/strings.h"

namespace fa {

namespace {

std::array<double, 3> oklab(std::uint8_t r8, std::uint8_t g8, std::uint8_t b8) {
    auto lin = [](double c) { return c <= 0.04045 ? c / 12.92 : std::pow((c + 0.055) / 1.055, 2.4); };
    const double r = lin(r8 / 255.0), g = lin(g8 / 255.0), b = lin(b8 / 255.0);
    const double l = std::cbrt(0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b);
    const double m = std::cbrt(0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b);
    const double s = std::cbrt(0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b);
    return {0.2104542553 * l + 0.7936177850 * m - 0.0040720468 * s, 1.9779984951 * l - 2.4285922050 * m + 0.4505937099 * s,
            0.0259040371 * l + 0.7827717662 * m - 0.8086757660 * s};
}

double dist2(const std::array<double, 3>& a, const std::array<double, 3>& b) {
    const double dl = a[0] - b[0], da = a[1] - b[1], db = a[2] - b[2];
    return dl * dl + da * da + db * db;
}

std::string hex_of(const std::array<std::uint8_t, 3>& c) { return std::format("#{:02x}{:02x}{:02x}", c[0], c[1], c[2]); }

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

std::string PixelPalette::hex(int index) const { return index >= 0 && index < size() ? hex_of(entries[std::size_t(index)].rgb) : std::string(); }

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
    const std::string forms = "A palette colour is its index (3), its name (\"skin\") or its colour (\"#e0a070\"); "
                              + std::string(allowTransparent ? "null or \".\" is transparent. " : "") + "Palette: " + join(labels, ", ") + ".";
    if (ref.is_null()) {
        if (allowTransparent) return -1;
        return make_error("A colour is required here, got null.", forms);
    }
    if (ref.is_number_integer()) {
        const long long i = ref.get<long long>();
        if (i < 0 || i >= n)
            return make_error(std::format("Palette index {} is outside the palette of {} colours (0 to {}).", i, n, n - 1), forms);
        return int(i);
    }
    if (!ref.is_string()) return make_error("A colour is an index, a name or a palette colour, got " + describe_json_value(ref) + ".", forms);
    const std::string s = ref.get<std::string>();
    if (allowTransparent && (s == "." || s == "transparent" || s == "none" || s.empty())) return -1;
    if (auto byName = palette.find_name(s)) return *byName;
    if (s.size() == 1) {
        const int idx = pixel_char_index(s[0]);
        if (idx >= 0) {
            if (idx >= n) return make_error(std::format("Palette index '{}' ({}) is outside the palette of {} colours.", s, idx, n), forms);
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
        const std::string nearLabel = palette.entries[std::size_t(near)].name.empty() ? palette.hex(near) : palette.entries[std::size_t(near)].name + " " + palette.hex(near);
        return make_error(std::format("The colour {} is not in the palette. The nearest palette colour is {} (index {}).", hex_of({r, g, bl}), nearLabel, near),
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
    if (rows.empty()) return make_error("An indexed picture needs at least one row.", "Rows are strings of palette characters, '.' for transparent: [\"..11..\", \".1221.\"].");
    const std::size_t w = rows[0].size();
    if (w == 0) return make_error("Row 0 is empty.", "Every row has one character per pixel.");
    IndexGrid g(int(w), int(rows.size()));
    for (std::size_t y = 0; y < rows.size(); ++y) {
        if (rows[y].size() != w)
            return make_error(std::format("Row {} has {} characters but row 0 has {}.", y, rows[y].size(), w), "Every row has the same width.");
        for (std::size_t x = 0; x < w; ++x) {
            const int idx = pixel_char_index(rows[y][x]);
            if (idx == -2)
                return make_error(std::format("Row {}, column {}: '{}' is not a palette character.", y, x, rows[y][x]),
                                  "Use '.' for transparent and " + std::string(kPixelIndexChars.substr(0, 12)) + "... for palette indices 0, 1, 2, ...");
            if (paletteSize >= 0 && idx >= paletteSize)
                return make_error(std::format("Row {}, column {}: '{}' is palette index {}, but the palette has {} colours.", y, x, rows[y][x], idx, paletteSize),
                                  paletteSize > 0 ? std::format("The palette characters are {}.", std::string(kPixelIndexChars.substr(0, std::size_t(paletteSize)))) : "Give the document a palette first.");
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
        if (e2 >= dy) { err += dy; x += sx; }
        if (e2 <= dx) { err += dx; y += sy; }
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
        if (e2 <= dy) { y0++; y1--; err += dy += a; }
        if (e2 >= dx || 2 * err > dy) { x0++; x1--; err += dx += b1; }
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
