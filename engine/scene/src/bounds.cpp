#include "fa/scene/bounds.h"

#include <algorithm>
#include <cmath>

#include "fa/core/utf8.h"
#include "fa/scene/rich_text.h"
#include "fa/scene/tilemap.h"
#include "fa/scene/ui_rect.h"

namespace fa {

namespace {

// Corners of the local rectangle [x0,x1] x [y0,y1], counter-clockwise from the minimum corner.
std::array<Vec2, 4> rect_quad(float x0, float y0, float x1, float y1) {
    return {Vec2{x0, y0}, Vec2{x1, y0}, Vec2{x1, y1}, Vec2{x0, y1}};
}

VisualFootprint make(const char* component, RenderSpace space, std::int32_t layer, Vec2 anchor, bool safeArea,
                     const std::array<Vec2, 4>& box) {
    VisualFootprint v;
    v.component = component;
    v.space = space;
    v.layer = layer;
    v.anchor = space == RenderSpace::Screen ? anchor : Vec2{0, 0};
    v.safeArea = space == RenderSpace::Screen && safeArea;
    v.box = box;
    v.hull = box;
    return v;
}

}  // namespace

Mat4 sprite_shear_matrix(Vec2 skew) {
    Mat4 m = Mat4::identity();
    const float tx = std::tan(radians(std::clamp(std::isfinite(skew.x) ? skew.x : 0.0f, -80.0f, 80.0f)));
    const float ty = std::tan(radians(std::clamp(std::isfinite(skew.y) ? skew.y : 0.0f, -80.0f, 80.0f)));
    m.at(1, 0) = tx;  // column 1 (the y axis) gets an x part
    m.at(0, 1) = ty;  // column 0 (the x axis) gets a y part
    return m;
}

Vec2 sprite_shear_point(Vec2 p, Vec2 skew) {
    if (skew.x == 0.0f && skew.y == 0.0f) return p;
    const float tx = std::tan(radians(std::clamp(std::isfinite(skew.x) ? skew.x : 0.0f, -80.0f, 80.0f)));
    const float ty = std::tan(radians(std::clamp(std::isfinite(skew.y) ? skew.y : 0.0f, -80.0f, 80.0f)));
    return {p.x + p.y * tx, p.y + p.x * ty};
}

bool sprite_mesh_grid(const Sprite& s, int& columns, int& rows) {
    columns = std::clamp(s.meshColumns, 0, kMaxSpriteMeshSide);
    rows = std::clamp(s.meshRows, 0, kMaxSpriteMeshSide);
    return columns > 0 && rows > 0 && columns * rows <= kMaxSpriteMeshCells;
}

std::vector<float> sprite_vertex_offsets(const Sprite& s, int columns, int rows) {
    std::vector<float> out;
    if (!s.vertexOffsets.is_array() || s.vertexOffsets.empty()) return out;
    out.assign(std::size_t(columns + 1) * std::size_t(rows + 1) * 2, 0.0f);
    std::size_t i = 0;
    for (const Json& v : s.vertexOffsets) {
        if (i >= out.size()) break;
        if (v.is_number()) {
            const float f = float(v.get<double>());
            out[i] = std::isfinite(f) ? f : 0.0f;
        }
        ++i;
    }
    return out;
}

Vec2 approx_text_size(const std::string& text, float fontSize, float maxWidth, bool markup) {
    if (markup) {  // the visible characters: tags take no room, an icon is two characters (1.2 em: as tall as the line)
        const MarkupText m = parse_markup(utf8_decode(text));
        std::string visible;
        for (std::size_t i = 0; i < m.text.size(); ++i) {
            if (m.attrs[i].icon >= 0) visible += "ii";
            else utf8_append(visible, m.text[i]);
        }
        return approx_text_size(visible, fontSize, maxWidth, false);
    }
    float lineW = 0, maxLine = 0;
    int lines = 1;
    for (char c : text) {
        if (c == '\n') {
            maxLine = std::max(maxLine, lineW);
            lineW = 0;
            ++lines;
            continue;
        }
        const float adv = fontSize * 0.6f;
        if (maxWidth > 0 && lineW + adv > maxWidth && lineW > 0) {
            maxLine = std::max(maxLine, lineW);
            lineW = 0;
            ++lines;
        }
        lineW += adv;
    }
    maxLine = std::max(maxLine, lineW);
    return {maxLine, static_cast<float>(lines) * fontSize * 1.2f};
}

std::vector<VisualFootprint> visual_footprints(const World& W, Entity e, const VisualMeasure& measure, bool includeScreenSpace) {
    std::vector<VisualFootprint> out;

    if (const Tilemap* tm = W.get<Tilemap>(e)) {
        const TilemapSize size = tilemap_size(*tm);
        // What the renderer draws: local x right, y DOWN from the top-left corner (an isometric map: the box of its diamonds).
        if (!size.empty() && tm->tileSize.x > 0 && tm->tileSize.y > 0) {
            const Rect b = tilemap_local_bounds(*tm, size);
            out.push_back(make("Tilemap", RenderSpace::World, tm->layer, Vec2{0, 0}, false, rect_quad(b.x, b.y, b.x + b.w, b.y + b.h)));
        }
    }

    if (const Sprite* s = W.get<Sprite>(e); s && (includeScreenSpace || s->space == RenderSpace::World)) {
        Vec2 size = s->size;
        if (size.x <= 0 || size.y <= 0) {  // 0 = the region, else the whole texture; 32 for a plain colour quad
            Vec2 base{32.0f, 32.0f};
            if (!s->texture.empty()) {
                if (s->region.w > 0 && s->region.h > 0) {
                    base = {s->region.w, s->region.h};
                } else {
                    if (measure.textureSize) base = measure.textureSize(s->texture);
                    if (const SpriteAnimator* a = W.get<SpriteAnimator>(e))  // the renderer sets the region to one frame of the sheet
                        base = {base.x / static_cast<float>(std::max(1, a->columns)), base.y / static_cast<float>(std::max(1, a->rows))};
                }
            }
            size = {size.x > 0 ? size.x : base.x, size.y > 0 ? size.y : base.y};
        }
        const float x0 = -s->pivot.x * size.x, y0 = -s->pivot.y * size.y, x1 = (1.0f - s->pivot.x) * size.x, y1 = (1.0f - s->pivot.y) * size.y;
        std::array<Vec2, 4> box = rect_quad(x0, y0, x1, y1);
        int cols = 0, rows = 0;
        const std::vector<float> offsets = sprite_mesh_grid(*s, cols, rows) ? sprite_vertex_offsets(*s, cols, rows) : std::vector<float>();
        if (!offsets.empty()) {  // a deformed grid: the rectangle around its moved, sheared vertices
            float lox = 1e30f, loy = 1e30f, hix = -1e30f, hiy = -1e30f;
            for (int j = 0; j <= rows; ++j)
                for (int i = 0; i <= cols; ++i) {
                    const std::size_t k = (std::size_t(j) * std::size_t(cols + 1) + std::size_t(i)) * 2;
                    const Vec2 p = sprite_shear_point({x0 + (x1 - x0) * float(i) / float(cols) + offsets[k],
                                                       y1 + (y0 - y1) * float(j) / float(rows) + offsets[k + 1]}, s->skew);
                    lox = std::min(lox, p.x); hix = std::max(hix, p.x);
                    loy = std::min(loy, p.y); hiy = std::max(hiy, p.y);
                }
            box = rect_quad(lox, loy, hix, hiy);
        } else if (s->skew.x != 0.0f || s->skew.y != 0.0f) {
            for (Vec2& c : box) c = sprite_shear_point(c, s->skew);
        }
        out.push_back(make("Sprite", s->space, s->layer, s->anchor, s->safeArea, box));
    }

    if (const Shape2D* s = W.get<Shape2D>(e); s && (includeScreenSpace || s->space == RenderSpace::World)) {
        const float bx0 = -s->pivot.x * s->size.x, by0 = -s->pivot.y * s->size.y;
        switch (s->shape) {
            case ShapeType::Rectangle: {  // a soft edge reaches softness / 2 beyond the box
                const float g = std::max(s->softness, 0.0f) * 0.5f;
                out.push_back(make("Shape2D", s->space, s->layer, s->anchor, s->safeArea,
                                   rect_quad(bx0 - g, by0 - g, bx0 + s->size.x + g, by0 + s->size.y + g)));
                break;
            }
            case ShapeType::Triangle:
            case ShapeType::Polygon:  // a polygon's or star's vertices lie inside the size box; the box is its footprint
            case ShapeType::Star:
                out.push_back(make("Shape2D", s->space, s->layer, s->anchor, s->safeArea, rect_quad(bx0, by0, bx0 + s->size.x, by0 + s->size.y)));
                break;
            case ShapeType::Diamond: {  // the rhombus on the midpoints of the size box's edges
                const float w = s->size.x, h = s->size.y;
                VisualFootprint v = make("Shape2D", s->space, s->layer, s->anchor, s->safeArea, rect_quad(bx0, by0, bx0 + w, by0 + h));
                v.hull = {Vec2{bx0 + w * 0.5f, by0}, Vec2{bx0 + w, by0 + h * 0.5f}, Vec2{bx0 + w * 0.5f, by0 + h}, Vec2{bx0, by0 + h * 0.5f}};
                out.push_back(v);
                break;
            }
            case ShapeType::Circle: {  // size.x is the diameter and the pivot refers to the circle's bounding square
                const float cy0 = -s->pivot.y * s->size.x, g = std::max(s->softness, 0.0f) * 0.5f;
                out.push_back(make("Shape2D", s->space, s->layer, s->anchor, s->safeArea,
                                   rect_quad(bx0 - g, cy0 - g, bx0 + s->size.x + g, cy0 + s->size.x + g)));
                break;
            }
            case ShapeType::Line: {  // from the origin to `size`, as thick as the stroke
                const float len = length(s->size);
                if (len < 1e-6f) break;  // the renderer draws nothing
                const Vec2 n = perp(s->size / len) * (std::max(s->thickness, 0.5f) * 0.5f);
                // Around the stroke: start - n, end - n, end + n, start + n.
                out.push_back(make("Shape2D", s->space, s->layer, s->anchor, s->safeArea,
                                   {Vec2{-n.x, -n.y}, Vec2{s->size.x - n.x, s->size.y - n.y},
                                    Vec2{s->size.x + n.x, s->size.y + n.y}, Vec2{n.x, n.y}}));
                break;
            }
        }
    }

    if (const Text* t = W.get<Text>(e);
        t && (includeScreenSpace || t->space == RenderSpace::World) && !t->text.empty() && t->fontSize > 0.0f) {
        Vec2 size = measure.textSize ? measure.textSize(*t) : approx_text_size(*t, measure.textScale);
        // A centred or right-aligned Text with a maxWidth is drawn in a box of that width (the renderer aligns inside it), so
        // that is the box layout and ui.state must see: a short note aligned to the end of a wrap box stays in its rectangle.
        const bool startIsRight = text_starts_right(*t, W.rtl());
        const bool left = t->align == Align::Left || (t->align == Align::Start && !startIsRight) || (t->align == Align::End && startIsRight);
        if (t->maxWidth > 0.0f && !left) size.x = std::max(size.x, t->maxWidth);
        out.push_back(make("Text", t->space, t->layer, t->anchor, t->safeArea,
                           rect_quad(-t->pivot.x * size.x, -t->pivot.y * size.y, (1.0f - t->pivot.x) * size.x,
                                     (1.0f - t->pivot.y) * size.y)));
    }
    // A UI widget: always screen space, its size box placed by pivot (see ui_rect.h).
    if (const UiBox* b = includeScreenSpace ? ui_box(W, e) : nullptr)
        out.push_back(make(ui_kind_name(ui_kind(W, e)), RenderSpace::Screen, b->layer, b->anchor, b->safeArea,
                           rect_quad(-b->pivot.x * b->size.x, -b->pivot.y * b->size.y, (1.0f - b->pivot.x) * b->size.x,
                                     (1.0f - b->pivot.y) * b->size.y)));
    if (includeScreenSpace && ui_mirrored(W, e))  // the mirror image of what is drawn in screen space: x flips about the origin
        for (VisualFootprint& v : out) {
            if (v.space != RenderSpace::Screen) continue;
            v.mirrored = true;
            v.anchor.x = 1.0f - v.anchor.x;
            for (Vec2& p : v.box) p.x = -p.x;
            for (Vec2& p : v.hull) p.x = -p.x;
        }
    return out;
}

Mat4 visual_world_matrix(const World& W, Entity e) {
    Mat4 m = W.world_matrix(e);
    if (const Parallax* p = W.get<Parallax>(e)) {
        m.at(3, 0) += p->offset.x;
        m.at(3, 1) += p->offset.y;
    }
    return m;
}

std::optional<Rect> entity_world_rect(const World& W, Entity e, const VisualMeasure& measure) {
    const std::vector<VisualFootprint> parts = visual_footprints(W, e, measure, false);
    const Mat4 m = visual_world_matrix(W, e);
    bool any = false;
    float x0 = 0, y0 = 0, x1 = 0, y1 = 0;
    for (const VisualFootprint& part : parts) {
        for (const Vec2& p : part.hull) {
            const Vec3 q = m.transform_point({p.x, p.y, 0.0f});
            if (!any) {
                x0 = x1 = q.x;
                y0 = y1 = q.y;
                any = true;
            } else {
                x0 = std::min(x0, q.x);
                y0 = std::min(y0, q.y);
                x1 = std::max(x1, q.x);
                y1 = std::max(y1, q.y);
            }
        }
    }
    if (!any) return std::nullopt;
    return Rect{x0, y0, x1 - x0, y1 - y0};
}

Mat4 footprint_matrix(const World& w, Entity e, const VisualFootprint& part, Vec2 designSize) {
    Mat4 m = part.space == RenderSpace::Screen ? w.world_matrix(e) : visual_world_matrix(w, e);  // world parts: moved by Parallax
    if (part.space == RenderSpace::Screen) {
        const float k = ui_scale_clamped(w.ui_scale());
        m = Mat4::scale({k, k, 1.0f}) * m;
        if (part.mirrored) m.at(3, 0) = -m.at(3, 0);  // a mirrored part: its box and anchor are flipped already
        const Vec2 a = anchor_point(part.anchor, part.safeArea, designSize, w.safe_insets());
        m.at(3, 0) += a.x;
        m.at(3, 1) += a.y;
    }
    return m;
}

bool footprint_hit(const World& w, Entity e, const VisualFootprint& part, Vec2 designSize, Vec2 point) {
    const Mat4 m = footprint_matrix(w, e, part, designSize);
    // Into the part's local space (y up): rotation and scale of the entity are undone, so the box is the oriented one.
    const Vec3 p = m.inverse().transform_point({point.x, point.y, 0.0f});
    return point_in_quad({p.x, part.space == RenderSpace::Screen ? -p.y : p.y}, part.box);
}

bool point_in_quad(Vec2 p, const std::array<Vec2, 4>& q) {
    // A quad with no area (a zero-size shape) contains nothing.
    float area2 = 0;
    for (size_t i = 0; i < 4; ++i) {
        const Vec2 a = q[i], b = q[(i + 1) % 4];
        area2 += a.x * b.y - b.x * a.y;
    }
    if (std::fabs(area2) < 1e-6f) return false;
    bool anyPositive = false, anyNegative = false;
    for (size_t i = 0; i < 4; ++i) {
        const Vec2 a = q[i], b = q[(i + 1) % 4];
        const float edge = length(b - a);
        if (edge < 1e-9f) continue;
        // Signed distance of p from the edge line; a thousandth of a unit of slack so a point exactly on a border is inside.
        const float side = ((b.x - a.x) * (p.y - a.y) - (b.y - a.y) * (p.x - a.x)) / edge;
        if (side > 1e-3f) anyPositive = true;
        else if (side < -1e-3f) anyNegative = true;
    }
    return !(anyPositive && anyNegative);
}

}  // namespace fa
