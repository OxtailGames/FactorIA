// Draws a text layout: the glyphs of every colour and weight as ONE item of the glyph atlas (so one batch), then the pictures
// of a rich text, one item per texture they come from.
#include "frame.h"

namespace fa::render {

int emit_text(QuadList& list, const Mat4& m, bool screen, const TextLayout& lay, Color color, Fonts& fonts, Assets& assets, int layer,
              float secondary, const Rect& clip, int visible, Color tint) {
    const auto shown = [visible](std::int32_t grapheme) { return visible < 0 || grapheme < visible; };
    int drawn = 0;
    for (const TextQuad& q : lay.quads) drawn += shown(q.grapheme) ? 1 : 0;
    if (drawn > 0) {
        list.begin_item(layer, secondary, fonts.atlas(), SamplerKind::Linear, BlendMode::Alpha, clip);
        QuadEmitter em{list, m, screen, pack_color(color), kModeGlyph, 0};
        const std::uint32_t base = em.color;
        for (const TextQuad& q : lay.quads) {
            if (!shown(q.grapheme)) continue;
            if (q.color == 0 || std::size_t(q.color) > lay.palette.size()) {
                em.color = base;
            } else {
                const Color& c = lay.palette[std::size_t(q.color) - 1];  // a run colour replaces the RGB; the opacity stays the text's
                em.color = pack_color(Color{c.r * tint.r, c.g * tint.g, c.b * tint.b, c.a * color.a});
            }
            em.rect(q.x0, q.y0, q.x1, q.y1, q.u0, q.v0, q.u1, q.v1);
        }
        list.end_item();
    }
    // The pictures: tinted by the opacity and the Tint only. Items of one texture merge into one batch when they follow each other.
    for (std::size_t d = 0; d < lay.iconDefs.size(); ++d) {
        bool any = false;
        for (const IconQuad& q : lay.icons) any = any || (std::size_t(q.def) == d && shown(q.grapheme));
        if (!any) continue;
        const RichIcon& def = lay.iconDefs[d];
        TextureAsset* tex = assets.texture(def.texture);
        const Vec2 lo = tex->uv(float(def.x), float(def.y)), hi = tex->uv(float(def.x + def.w), float(def.y + def.h));
        list.begin_item(layer, secondary, tex, SamplerKind::Linear, BlendMode::Alpha, clip);
        QuadEmitter em{list, m, screen, pack_color(Color{tint.r, tint.g, tint.b, color.a}), kModeTextured, 0};
        for (const IconQuad& q : lay.icons)
            if (std::size_t(q.def) == d && shown(q.grapheme)) em.rect(q.x0, q.y0, q.x1, q.y1, lo.x, lo.y, hi.x, hi.y);
        list.end_item();
    }
    return drawn;
}

}  // namespace fa::render
