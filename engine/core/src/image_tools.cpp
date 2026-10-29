#include "fa/core/image_tools.h"

#include <algorithm>
#include <array>
#include <cmath>
#include <cstring>

#include "fa/core/strings.h"

namespace fa {

namespace {

Image blank(int w, int h) {
    Image out;
    out.width = w;
    out.height = h;
    out.rgba.assign(std::size_t(w) * std::size_t(h) * 4, 0);
    return out;
}

void fill_rect(Image& img, int x0, int y0, int w, int h, std::uint8_t r, std::uint8_t g, std::uint8_t b) {
    for (int y = std::max(0, y0); y < std::min(img.height, y0 + h); ++y)
        for (int x = std::max(0, x0); x < std::min(img.width, x0 + w); ++x) {
            std::uint8_t* p = &img.rgba[(std::size_t(y) * img.width + x) * 4];
            p[0] = r; p[1] = g; p[2] = b; p[3] = 255;
        }
}

// 5x7 glyphs, one byte per row, bit 4 = leftmost pixel.
struct Glyph {
    char ch;
    std::array<std::uint8_t, 7> rows;
};
constexpr Glyph kGlyphs[] = {
    {'0', {0b01110, 0b10001, 0b10011, 0b10101, 0b11001, 0b10001, 0b01110}},
    {'1', {0b00100, 0b01100, 0b00100, 0b00100, 0b00100, 0b00100, 0b01110}},
    {'2', {0b01110, 0b10001, 0b00001, 0b00010, 0b00100, 0b01000, 0b11111}},
    {'3', {0b11110, 0b00001, 0b00001, 0b01110, 0b00001, 0b00001, 0b11110}},
    {'4', {0b00010, 0b00110, 0b01010, 0b10010, 0b11111, 0b00010, 0b00010}},
    {'5', {0b11111, 0b10000, 0b11110, 0b00001, 0b00001, 0b10001, 0b01110}},
    {'6', {0b00110, 0b01000, 0b10000, 0b11110, 0b10001, 0b10001, 0b01110}},
    {'7', {0b11111, 0b00001, 0b00010, 0b00100, 0b01000, 0b01000, 0b01000}},
    {'8', {0b01110, 0b10001, 0b10001, 0b01110, 0b10001, 0b10001, 0b01110}},
    {'9', {0b01110, 0b10001, 0b10001, 0b01111, 0b00001, 0b00010, 0b01100}},
    {'f', {0b00110, 0b01001, 0b01000, 0b11100, 0b01000, 0b01000, 0b01000}},
    {'+', {0b00000, 0b00100, 0b00100, 0b11111, 0b00100, 0b00100, 0b00000}},
    {'-', {0b00000, 0b00000, 0b00000, 0b11111, 0b00000, 0b00000, 0b00000}},
};

constexpr int kGlyphW = 5, kGlyphH = 7, kGlyphAdvance = 6;

int label_width(const std::string& s, int k) { return s.empty() ? 0 : (int(s.size()) * kGlyphAdvance - 1) * k; }

void draw_label(Image& img, int x, int y, const std::string& text, int k) {
    if (text.empty()) return;
    const int pad = 2 * k;
    fill_rect(img, x, y, label_width(text, k) + 2 * pad, kGlyphH * k + 2 * pad, 0, 0, 0);
    int cx = x + pad;
    for (char c : text) {
        for (const Glyph& g : kGlyphs) {
            if (g.ch != c) continue;
            for (int row = 0; row < kGlyphH; ++row)
                for (int col = 0; col < kGlyphW; ++col)
                    if (g.rows[std::size_t(row)] & (1 << (kGlyphW - 1 - col)))
                        fill_rect(img, cx + col * k, y + pad + row * k, k, k, 255, 255, 255);
        }
        cx += kGlyphAdvance * k;
    }
}

}  // namespace

Image crop_image(const Image& src, int x, int y, int w, int h) {
    if (src.empty() || w < 1 || h < 1) return {};
    Image out = blank(w, h);
    const int x0 = std::max(0, x), x1 = std::min(src.width, x + w);
    if (x1 <= x0) return out;
    for (int yy = std::max(0, y); yy < std::min(src.height, y + h); ++yy)
        std::memcpy(&out.rgba[(std::size_t(yy - y) * w + (x0 - x)) * 4], &src.rgba[(std::size_t(yy) * src.width + x0) * 4],
                    std::size_t(x1 - x0) * 4);
    return out;
}

Image resize_nearest(const Image& src, int width, int height) {
    if (src.empty() || width < 1 || height < 1) return {};
    Image out = blank(width, height);
    for (int y = 0; y < height; ++y) {
        const int sy = std::min(src.height - 1, int((std::int64_t(y) * 2 + 1) * src.height / (std::int64_t(height) * 2)));
        for (int x = 0; x < width; ++x) {
            const int sx = std::min(src.width - 1, int((std::int64_t(x) * 2 + 1) * src.width / (std::int64_t(width) * 2)));
            std::memcpy(&out.rgba[(std::size_t(y) * width + x) * 4], &src.rgba[(std::size_t(sy) * src.width + sx) * 4], 4);
        }
    }
    return out;
}

SheetLayout sheet_layout(int count, int columns, int tileWidth, int tileHeight, int gap) {
    SheetLayout l;
    if (count < 1 || tileWidth < 1 || tileHeight < 1) return l;
    if (columns < 1) {
        // The column count that makes the sheet closest to square.
        columns = std::max(1, int(std::lround(std::sqrt(double(count) * tileHeight / tileWidth))));
    }
    l.columns = std::min(columns, count);
    l.rows = (count + l.columns - 1) / l.columns;
    l.tileWidth = tileWidth;
    l.tileHeight = tileHeight;
    l.gap = gap >= 0 ? gap : std::clamp(tileWidth / 80, 2, 12);
    l.width = l.columns * tileWidth + (l.columns + 1) * l.gap;
    l.height = l.rows * tileHeight + (l.rows + 1) * l.gap;
    return l;
}

Image contact_sheet(const std::vector<Image>& tiles, const std::vector<std::string>& labels, int columns, int gap,
                    SheetLayout* layoutOut) {
    if (tiles.empty() || tiles.front().empty()) return {};
    const SheetLayout l = sheet_layout(int(tiles.size()), columns, tiles.front().width, tiles.front().height, gap);
    if (layoutOut) *layoutOut = l;
    Image sheet = blank(l.width, l.height);
    fill_rect(sheet, 0, 0, l.width, l.height, 40, 40, 44);
    const int k = std::clamp(int(std::lround(l.tileWidth / 200.0)), 1, 4);  // label pixel size
    for (std::size_t i = 0; i < tiles.size(); ++i) {
        const int col = int(i) % l.columns, row = int(i) / l.columns;
        const int ox = l.gap + col * (l.tileWidth + l.gap), oy = l.gap + row * (l.tileHeight + l.gap);
        const Image tile = tiles[i].width == l.tileWidth && tiles[i].height == l.tileHeight
                               ? Image{}
                               : crop_image(tiles[i], 0, 0, l.tileWidth, l.tileHeight);
        const Image& src = tile.empty() ? tiles[i] : tile;
        for (int y = 0; y < l.tileHeight && y < src.height; ++y)
            std::memcpy(&sheet.rgba[(std::size_t(oy + y) * sheet.width + ox) * 4], &src.rgba[std::size_t(y) * src.width * 4],
                        std::size_t(std::min(l.tileWidth, src.width)) * 4);
        if (i < labels.size()) draw_label(sheet, ox, oy, labels[i], k);
    }
    return sheet;
}

Result<ProfileChannel> parse_profile_channel(std::string_view name) {
    static const std::pair<const char*, ProfileChannel> kChannels[] = {{"luminance", ProfileChannel::Luminance},
                                                                        {"red", ProfileChannel::Red},
                                                                        {"green", ProfileChannel::Green},
                                                                        {"blue", ProfileChannel::Blue}};
    std::vector<std::string> names;
    for (const auto& [n, c] : kChannels) {
        if (name == n) return c;
        names.push_back(n);
    }
    return make_error("Unknown channel '" + std::string(name) + "'.", did_you_mean(name, names));
}

std::vector<float> profile_line(const Image& img, Vec2 from, Vec2 to, ProfileChannel channel, std::vector<Vec2>* points) {
    std::vector<float> out;
    if (points) points->clear();
    if (img.empty()) return out;
    const float dx = to.x - from.x, dy = to.y - from.y;
    const int n = int(std::ceil(std::max(std::fabs(dx), std::fabs(dy)))) + 1;
    out.reserve(std::size_t(n));
    for (int i = 0; i < n; ++i) {
        const float t = n > 1 ? float(i) / float(n - 1) : 0.0f;
        const Vec2 p{from.x + dx * t, from.y + dy * t};
        const int px = std::clamp(int(std::floor(p.x)), 0, img.width - 1);
        const int py = std::clamp(int(std::floor(p.y)), 0, img.height - 1);
        const std::uint8_t* c = &img.rgba[(std::size_t(py) * img.width + px) * 4];
        float v = 0;
        switch (channel) {
            case ProfileChannel::Red: v = c[0]; break;
            case ProfileChannel::Green: v = c[1]; break;
            case ProfileChannel::Blue: v = c[2]; break;
            case ProfileChannel::Luminance: v = 0.2126f * c[0] + 0.7152f * c[1] + 0.0722f * c[2]; break;
        }
        out.push_back(v);
        if (points) points->push_back(p);
    }
    return out;
}

std::vector<ProfileStep> find_steps(const std::vector<float>& values, float threshold, int window, std::size_t maxSteps) {
    std::vector<ProfileStep> steps;
    window = std::max(1, window);
    const int n = int(values.size());
    for (int i = 0; i + 1 < n && steps.size() < maxSteps;) {
        int bestW = 0;
        float bestAbs = 0;
        for (int w = 1; w <= window && i + w < n; ++w) {
            const float d = std::fabs(values[std::size_t(i + w)] - values[std::size_t(i)]);
            if (d > bestAbs) { bestAbs = d; bestW = w; }
        }
        if (bestW > 0 && bestAbs >= threshold) {
            // A flat first or last sample is not part of the jump: report the riser itself (0, 0, 255 is a step of width 1).
            int first = i, w = bestW;
            const float flat = bestAbs * 0.1f;
            while (w > 1 && std::fabs(values[std::size_t(first + 1)] - values[std::size_t(first)]) <= flat) { ++first; --w; }
            while (w > 1 && std::fabs(values[std::size_t(first + w)] - values[std::size_t(first + w - 1)]) <= flat) --w;
            ProfileStep s;
            s.index = first;
            s.width = w;
            s.from = values[std::size_t(first)];
            s.to = values[std::size_t(first + w)];
            s.delta = s.to - s.from;
            steps.push_back(s);
            i = first + w;
        } else {
            ++i;
        }
    }
    return steps;
}

}  // namespace fa
