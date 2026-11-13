// A small RGBA canvas the picture commands draw on (assets.spectrogram, music.info): filled and dashed lines, rectangles and
// text in the engine's built-in font, blended with an alpha. Header-only and private to tools/common.
#pragma once

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <map>
#include <string>
#include <utility>

#include "fa/core/image.h"
#include "fa/render/fonts.h"

namespace fa::picture {

struct Rgb {
    std::uint8_t r, g, b;
};

class Canvas {
public:
    Canvas(int w, int h, Rgb bg) {
        img.width = w;
        img.height = h;
        img.rgba.resize(std::size_t(w) * std::size_t(h) * 4);
        for (std::size_t i = 0; i < img.rgba.size(); i += 4) {
            img.rgba[i] = bg.r;
            img.rgba[i + 1] = bg.g;
            img.rgba[i + 2] = bg.b;
            img.rgba[i + 3] = 255;
        }
    }
    void blend(int x, int y, Rgb c, double a) {
        if (x < 0 || y < 0 || x >= img.width || y >= img.height || a <= 0) return;
        std::uint8_t* p = &img.rgba[(std::size_t(y) * std::size_t(img.width) + std::size_t(x)) * 4];
        p[0] = std::uint8_t(p[0] + (c.r - p[0]) * a);
        p[1] = std::uint8_t(p[1] + (c.g - p[1]) * a);
        p[2] = std::uint8_t(p[2] + (c.b - p[2]) * a);
    }
    void rect(int x0, int y0, int x1, int y1, Rgb c, double a = 1.0) {
        for (int y = y0; y <= y1; ++y)
            for (int x = x0; x <= x1; ++x) blend(x, y, c, a);
    }
    void vline(int x, int y0, int y1, Rgb c, double a = 1.0, int dash = 0) {
        for (int y = y0; y <= y1; ++y)
            if (!dash || (y / dash) % 2 == 0) blend(x, y, c, a);
    }
    void hline(int x0, int x1, int y, Rgb c, double a = 1.0, int dash = 0) {
        for (int x = x0; x <= x1; ++x)
            if (!dash || (x / dash) % 2 == 0) blend(x, y, c, a);
    }
    void line(double x0, double y0, double x1, double y1, Rgb c, int thickness) {
        const int steps = std::max(1, int(std::ceil(std::max(std::fabs(x1 - x0), std::fabs(y1 - y0)))));
        const int half = thickness / 2;
        for (int i = 0; i <= steps; ++i) {
            const double t = double(i) / steps;
            const int x = int(std::lround(x0 + (x1 - x0) * t)), y = int(std::lround(y0 + (y1 - y0) * t));
            rect(x - half, y - half, x - half + thickness - 1, y - half + thickness - 1, c);
        }
    }
    // Text with the engine's built-in font (DejaVu Sans). `anchor`: 0 = x is the left edge, 1 = centre, 2 = right edge; the
    // text is centred on y when `middle`, else y is its top.
    void text(const std::string& s, int x, int y, int size, Rgb c, int anchor = 0, bool middle = false) {
        if (s.empty()) return;
        const auto key = std::make_pair(s, size);
        auto it = cache.find(key);
        if (it == cache.end()) {
            auto bmp = rasterize_text(s, "", float(size));
            it = cache.emplace(key, bmp ? std::move(*bmp) : TextBitmap{}).first;
        }
        const TextBitmap& bmp = it->second;
        const int left = anchor == 0 ? x : anchor == 1 ? x - bmp.width / 2 : x - bmp.width;
        const int top = middle ? y - bmp.height / 2 : y;
        for (int yy = 0; yy < bmp.height; ++yy)
            for (int xx = 0; xx < bmp.width; ++xx)
                blend(left + xx, top + yy, c,
                      bmp.coverage[std::size_t(yy) * std::size_t(bmp.width) + std::size_t(xx)] / 255.0);
    }
    Image img;
    std::map<std::pair<std::string, int>, TextBitmap> cache;
};

inline Rgb magma(double t) {
    static const Rgb stops[] = {{0, 0, 4},     {40, 11, 84},   {101, 21, 110}, {159, 42, 99},
                                {212, 72, 66}, {245, 125, 21}, {250, 193, 39}, {252, 255, 164}};
    t = std::clamp(t, 0.0, 1.0) * 7.0;
    const int i = std::min(6, int(t));
    const double f = t - i;
    auto mix = [&](std::uint8_t a, std::uint8_t b) { return std::uint8_t(a + (b - a) * f); };
    return {mix(stops[i].r, stops[i + 1].r), mix(stops[i].g, stops[i + 1].g), mix(stops[i].b, stops[i + 1].b)};
}

}  // namespace fa::picture
