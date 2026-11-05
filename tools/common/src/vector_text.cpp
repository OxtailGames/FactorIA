// vector.text_to_path: text as outlines of the engine's own fonts (outline_text in fa/render/fonts.h), so it survives without the font.
#include <cmath>

#include "fa/render/fonts.h"
#include "vector_shapes.h"

namespace fa::vec {

Result<Path> build_text(const std::string& text, const std::string& font, double size, P at, const std::string& anchor, double letterSpacing,
                        double lineSpacing, TextMetrics* metrics) {
    const TextAnchor a = anchor == "middle" ? TextAnchor::Middle : anchor == "end" ? TextAnchor::End : TextAnchor::Start;
    auto outline = outline_text(text, font, float(size), a, float(letterSpacing), float(lineSpacing));
    if (!outline) return outline.error();
    Path path;
    SubPath cur;
    bool open = false;
    P pen{};
    auto pt = [&](float x, float y) { return P{at.x + double(x), at.y + double(y)}; };
    auto finish = [&] {
        if (open) {
            cur.closed = true;
            path.push_back(cur);
        }
        open = false;
        cur = SubPath{};
    };
    for (const TextOutlineCmd& c : outline->cmds) {
        switch (c.kind) {
            case TextOutlineCmd::Move:
                finish();
                cur.start = pen = pt(c.x, c.y);
                open = true;
                break;
            case TextOutlineCmd::Line: {
                Seg s;
                s.p = pt(c.x, c.y);
                cur.segs.push_back(s);
                pen = s.p;
                break;
            }
            case TextOutlineCmd::Quad: {
                const P q = pt(c.cx, c.cy), e = pt(c.x, c.y);
                Seg s;
                s.cubic = true;
                s.c1 = pen + (q - pen) * (2.0 / 3.0);
                s.c2 = e + (q - e) * (2.0 / 3.0);
                s.p = e;
                cur.segs.push_back(s);
                pen = e;
                break;
            }
            case TextOutlineCmd::Cubic: {
                Seg s;
                s.cubic = true;
                s.c1 = pt(c.cx, c.cy);
                s.c2 = pt(c.dx, c.dy);
                s.p = pt(c.x, c.y);
                cur.segs.push_back(s);
                pen = s.p;
                break;
            }
            case TextOutlineCmd::Close: finish(); break;
        }
    }
    finish();
    if (metrics) {
        metrics->advance = outline->advance;
        metrics->lineHeight = outline->lineHeight;
        metrics->lines = int(outline->lineWidths.size());
        metrics->glyphs = outline->glyphs;
        metrics->missing = outline->missing;
    }
    return path;
}

}  // namespace fa::vec

namespace fa {

Result<std::string> vector_text_path(const std::string& text, const std::string& font, double size, VecPoint at, const std::string& anchor,
                                     double letterSpacing, int decimals, double* advance, int* glyphs) {
    vec::TextMetrics m;
    auto path = vec::build_text(text, font, size, {at.x, at.y}, anchor, letterSpacing, 1.0, &m);
    if (!path) return path.error();
    if (advance) *advance = m.advance;
    if (glyphs) *glyphs = m.glyphs;
    return vec::path_to_data(*path, decimals);
}

}  // namespace fa
