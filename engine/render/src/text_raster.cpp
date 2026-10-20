// CPU text drawing for rasterize_text (fa/render/fonts.h): stb_truetype glyphs, laid out left to right.
#include <algorithm>
#include <cmath>

#include "fa/render/fonts.h"
#include "font_internal.h"

namespace fa {

Result<TextBitmap> rasterize_text(std::string_view utf8, const std::string& font, float pixelSize) {
    auto primary = render::load_font_face(font);
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
        const render::FontFace* face = faces[0];
        int glyph = stbtt_FindGlyphIndex(&face->info, int(cp));
        if (glyph == 0 && faces[1]) {
            face = faces[1];
            glyph = stbtt_FindGlyphIndex(&face->info, int(cp));
        }
        const float scale = stbtt_ScaleForMappingEmToPixels(&face->info, pixelSize);
        int adv = 0, lsb = 0;
        stbtt_GetGlyphHMetrics(&face->info, glyph, &adv, &lsb);
        const float fx = pen - std::floor(pen);
        Placed p{face, glyph, 0, 0, 0, 0, scale, fx};
        stbtt_GetGlyphBitmapBoxSubpixel(&face->info, glyph, scale, scale, fx, 0, &p.x0, &p.y0, &p.x1, &p.y1);
        p.x0 += int(std::floor(pen));
        p.x1 += int(std::floor(pen));
        if (p.x1 > p.x0 && p.y1 > p.y0) {
            minX = std::min(minX, p.x0);
            minY = std::min(minY, p.y0);
            maxX = std::max(maxX, p.x1);
            maxY = std::max(maxY, p.y1);
            placed.push_back(p);
        }
        pen += adv * scale;
    }
    TextBitmap out;
    if (placed.empty()) return out;
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

}  // namespace fa
