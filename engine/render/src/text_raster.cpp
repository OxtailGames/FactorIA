// CPU text drawing for rasterize_text (fa/render/fonts.h): stb_truetype glyphs, laid out left to right.
#include <algorithm>
#include <cmath>
#include <cstdlib>

#include "fa/render/fonts.h"
#include "font_internal.h"

namespace fa {

namespace {

constexpr std::int64_t kMaxGlyphPixels = 1 << 22;   // one glyph's bitmap
constexpr std::int64_t kMaxBitmapPixels = 1 << 26;  // the whole line's bitmap

Result<TextBitmap> rasterize_with(std::string_view utf8, std::unique_ptr<render::FontFace> primary, float pixelSize) {
    if (!primary->ok) return make_error(primary->error, primary->hint);
    auto fallback = render::load_font_face("");
    const render::FontFace* faces[2] = {primary.get(), fallback->ok ? fallback.get() : nullptr};

    struct Placed {
        const render::FontFace* face;
        int glyph, x0, y0, x1, y1;  // pixel box relative to the baseline origin
        float scale, fx;            // font scale, sub-pixel x offset
    };
    std::vector<Placed> placed;
    float pen = 0;
    int minX = 1 << 30, minY = 1 << 30, maxX = -(1 << 30), maxY = -(1 << 30);
    for (char32_t cp : render::decode_text(utf8)) {
        if (cp == '\n') continue;
        if (!(std::fabs(pen) < 1e7f)) break;  // a font with a tiny units-per-em: the rest is far outside any bitmap
        const render::FontFace* face = faces[0];
        int glyph = face->stb_glyph(std::uint32_t(stbtt_FindGlyphIndex(&face->info, int(cp))));
        if (glyph == 0 && faces[1]) {
            face = faces[1];
            glyph = face->stb_glyph(std::uint32_t(stbtt_FindGlyphIndex(&face->info, int(cp))));
        }
        const float scale = stbtt_ScaleForMappingEmToPixels(&face->info, pixelSize);
        int adv = 0, lsb = 0;
        stbtt_GetGlyphHMetrics(&face->info, glyph, &adv, &lsb);
        const float fx = pen - std::floor(pen);
        Placed p{face, glyph, 0, 0, 0, 0, scale, fx};
        stbtt_GetGlyphBitmapBoxSubpixel(&face->info, glyph, scale, scale, fx, 0, &p.x0, &p.y0, &p.x1, &p.y1);
        // A font whose units-per-em is tiny draws a glyph hundreds of thousands of pixels wide (stb_truetype's box can be
        // INT_MAX): that glyph draws nothing, and its box is not moved by the pen (that sum would overflow).
        constexpr std::int64_t kFar = 1 << 24;
        const bool inRange = std::abs(std::int64_t(p.x0)) < kFar && std::abs(std::int64_t(p.x1)) < kFar &&
                             std::abs(std::int64_t(p.y0)) < kFar && std::abs(std::int64_t(p.y1)) < kFar;
        if (inRange) {
            p.x0 += int(std::floor(pen));
            p.x1 += int(std::floor(pen));
        }
        if (inRange && p.x1 > p.x0 && p.y1 > p.y0 && std::int64_t(p.x1 - p.x0) * (p.y1 - p.y0) <= kMaxGlyphPixels &&
            std::abs(p.x0) < (1 << 24)) {
            minX = std::min(minX, p.x0);
            minY = std::min(minY, p.y0);
            maxX = std::max(maxX, p.x1);
            maxY = std::max(maxY, p.y1);
            placed.push_back(p);
        }
        pen += adv * scale;
    }
    TextBitmap out;
    out.advance = pen;
    {
        int ascent = 0, descent = 0, lineGap = 0;
        stbtt_GetFontVMetrics(&primary->info, &ascent, &descent, &lineGap);
        const float scale = stbtt_ScaleForMappingEmToPixels(&primary->info, pixelSize);
        out.ascent = float(ascent) * scale;
        out.descent = -float(descent) * scale;
    }
    if (placed.empty()) return out;
    if (std::int64_t(maxX - minX) * (maxY - minY) > kMaxBitmapPixels)
        return make_error("the text is " + std::to_string(maxX - minX) + " x " + std::to_string(maxY - minY) +
                              " pixels, more than a bitmap of " + std::to_string(kMaxBitmapPixels / 1000000) +
                              " million pixels",
                          "Use a smaller pixel size or a shorter text.");
    out.originX = -minX;
    out.originY = -minY;
    out.width = maxX - minX;
    out.height = maxY - minY;
    out.coverage.assign(std::size_t(out.width) * out.height, 0);
    std::vector<unsigned char> tmp;
    for (const Placed& p : placed) {
        const int w = p.x1 - p.x0, h = p.y1 - p.y0;
        tmp.assign(std::size_t(w) * h, 0);
        stbtt_MakeGlyphBitmapSubpixel(&p.face->info, tmp.data(), w, h, w, p.scale, p.scale, p.fx, 0, p.glyph);
        for (int y = 0; y < h; ++y)
            for (int x = 0; x < w; ++x) {
                std::uint8_t& dst = out.coverage[std::size_t(y + p.y0 - minY) * out.width + (x + p.x0 - minX)];
                dst = std::max(dst, std::uint8_t(tmp[std::size_t(y) * w + x]));
            }
    }
    return out;
}

}  // namespace

Result<TextBitmap> rasterize_text(std::string_view utf8, const std::string& font, float pixelSize) {
    return rasterize_with(utf8, render::load_font_face(font), pixelSize);
}

Result<TextBitmap> rasterize_text(std::string_view utf8, const std::vector<std::uint8_t>& fontBytes, float pixelSize) {
    return rasterize_with(
        utf8,
        render::load_font_face_from_memory(std::vector<unsigned char>(fontBytes.begin(), fontBytes.end()), "font"),
        pixelSize);
}

}  // namespace fa
