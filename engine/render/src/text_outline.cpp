// Text as vector outlines for outline_text (fa/render/fonts.h): the same shaping the renderer uses, the glyph shapes of stb_truetype.
#include <algorithm>
#include <cmath>

#include "fa/render/fonts.h"
#include "font_internal.h"
#include "text_shaper.h"

namespace fa {

Result<TextOutline> outline_text(std::string_view utf8, const std::string& font, float size, TextAnchor anchor, float letterSpacing,
                                 float lineSpacing) {
    auto primary = render::load_font_face(font);
    if (!primary->ok) return make_error(primary->error, primary->hint);
    std::unique_ptr<render::FontFace> fallback;
    if (!font.empty() && font != "builtin") fallback = render::load_font_face("builtin");
    auto chain = [&](std::size_t i) -> render::FontFace* {
        if (i == 0) return primary.get();
        return i == 1 && fallback && fallback->ok ? fallback.get() : nullptr;
    };
    // Shape at a large integer size so the positions keep their precision; everything is scaled to `size` after.
    constexpr int kPx = 2048;
    const render::ShapedText shaped = render::shape_text(utf8, kPx, 0.0f, 2, chain);
    const float toUnit = size / float(kPx);

    TextOutline out;
    int asc = 0, desc = 0, gap = 0;
    stbtt_GetFontVMetrics(&primary->info, &asc, &desc, &gap);
    const float fs = size / float(primary->unitsPerEm);
    out.ascent = float(asc) * fs;
    out.descent = -float(desc) * fs;
    out.lineHeight = (out.ascent + out.descent + float(gap) * fs) * lineSpacing;
    out.missing.assign(shaped.missing.begin(), shaped.missing.end());

    float baseline = 0;
    for (const render::ShapedLine& line : shaped.lines) {
        int count = 0;
        for (const render::ShapedGlyph& g : line.glyphs)
            if (g.icon < 0) ++count;
        const float width = line.width * toUnit + float(count) * letterSpacing * size;
        out.lineWidths.push_back(width);
        out.advance = std::max(out.advance, width);
        const float shift = anchor == TextAnchor::Start ? 0.0f : anchor == TextAnchor::Middle ? -width * 0.5f : -width;
        int index = 0;
        for (const render::ShapedGlyph& g : line.glyphs) {
            if (g.icon >= 0 || !g.face) continue;
            ++out.glyphs;
            const float ox = shift + g.x * toUnit + float(index) * letterSpacing * size;
            const float oy = baseline - g.y * toUnit;
            ++index;
            if (g.gid == 0) continue;
            const float s = size / float(g.face->unitsPerEm);
            stbtt_vertex* verts = nullptr;
            const int n = stbtt_GetGlyphShape(&g.face->info, int(g.gid), &verts);
            bool open = false;
            auto px = [&](int v) { return ox + float(v) * s; };
            auto py = [&](int v) { return oy - float(v) * s; };
            for (int i = 0; i < n; ++i) {
                const stbtt_vertex& v = verts[i];
                TextOutlineCmd c;
                switch (v.type) {
                    case STBTT_vmove:
                        if (open) out.cmds.push_back({TextOutlineCmd::Close});
                        c.kind = TextOutlineCmd::Move;
                        open = true;
                        break;
                    case STBTT_vline: c.kind = TextOutlineCmd::Line; break;
                    case STBTT_vcurve:
                        c.kind = TextOutlineCmd::Quad;
                        c.cx = px(v.cx);
                        c.cy = py(v.cy);
                        break;
                    default:
                        c.kind = TextOutlineCmd::Cubic;
                        c.cx = px(v.cx);
                        c.cy = py(v.cy);
                        c.dx = px(v.cx1);
                        c.dy = py(v.cy1);
                        break;
                }
                c.x = px(v.x);
                c.y = py(v.y);
                out.cmds.push_back(c);
            }
            if (open) out.cmds.push_back({TextOutlineCmd::Close});
            stbtt_FreeShape(&g.face->info, verts);
        }
        baseline += out.lineHeight;
    }
    return out;
}

}  // namespace fa
