#include "fa/scene/bounds.h"

#include <algorithm>
#include <cmath>

#include "fa/scene/tilemap.h"

namespace fa {

namespace {

// Corners of the local rectangle [x0,x1] x [y0,y1], counter-clockwise from the minimum corner.
std::array<Vec2, 4> rect_quad(float x0, float y0, float x1, float y1) {
    return {Vec2{x0, y0}, Vec2{x1, y0}, Vec2{x1, y1}, Vec2{x0, y1}};
}

VisualFootprint make(const char* component, RenderSpace space, std::int32_t layer, Vec2 anchor, const std::array<Vec2, 4>& box) {
    VisualFootprint v;
    v.component = component;
    v.space = space;
    v.layer = layer;
    v.anchor = space == RenderSpace::Screen ? anchor : Vec2{0, 0};
    v.box = box;
    v.hull = box;
    return v;
}

}  // namespace

Vec2 approx_text_size(const std::string& text, float fontSize, float maxWidth) {
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
        // What the renderer draws: local x right, y DOWN from the top-left corner.
        if (!size.empty() && tm->tileSize.x > 0 && tm->tileSize.y > 0)
            out.push_back(make("Tilemap", RenderSpace::World, tm->layer, Vec2{0, 0},
                               rect_quad(0.0f, -static_cast<float>(size.height) * tm->tileSize.y,
                                         static_cast<float>(size.width) * tm->tileSize.x, 0.0f)));
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
        out.push_back(make("Sprite", s->space, s->layer, s->anchor,
                           rect_quad(-s->pivot.x * size.x, -s->pivot.y * size.y, (1.0f - s->pivot.x) * size.x,
                                     (1.0f - s->pivot.y) * size.y)));
    }

    if (const Shape2D* s = W.get<Shape2D>(e); s && (includeScreenSpace || s->space == RenderSpace::World)) {
        const float bx0 = -s->pivot.x * s->size.x, by0 = -s->pivot.y * s->size.y;
        switch (s->shape) {
            case ShapeType::Rectangle:
            case ShapeType::Triangle:
            case ShapeType::Polygon:  // a polygon's or star's vertices lie inside the size box; the box is its footprint
            case ShapeType::Star:
                out.push_back(make("Shape2D", s->space, s->layer, s->anchor, rect_quad(bx0, by0, bx0 + s->size.x, by0 + s->size.y)));
                break;
            case ShapeType::Diamond: {  // the rhombus on the midpoints of the size box's edges
                const float w = s->size.x, h = s->size.y;
                VisualFootprint v = make("Shape2D", s->space, s->layer, s->anchor, rect_quad(bx0, by0, bx0 + w, by0 + h));
                v.hull = {Vec2{bx0 + w * 0.5f, by0}, Vec2{bx0 + w, by0 + h * 0.5f}, Vec2{bx0 + w * 0.5f, by0 + h}, Vec2{bx0, by0 + h * 0.5f}};
                out.push_back(v);
                break;
            }
            case ShapeType::Circle: {  // size.x is the diameter and the pivot refers to the circle's bounding square
                const float cy0 = -s->pivot.y * s->size.x;
                out.push_back(make("Shape2D", s->space, s->layer, s->anchor, rect_quad(bx0, cy0, bx0 + s->size.x, cy0 + s->size.x)));
                break;
            }
            case ShapeType::Line: {  // from the origin to `size`, as thick as the stroke
                const float len = length(s->size);
                if (len < 1e-6f) break;  // the renderer draws nothing
                const Vec2 n = perp(s->size / len) * (std::max(s->thickness, 0.5f) * 0.5f);
                // Around the stroke: start - n, end - n, end + n, start + n.
                out.push_back(make("Shape2D", s->space, s->layer, s->anchor,
                                   {Vec2{-n.x, -n.y}, Vec2{s->size.x - n.x, s->size.y - n.y},
                                    Vec2{s->size.x + n.x, s->size.y + n.y}, Vec2{n.x, n.y}}));
                break;
            }
        }
    }

    if (const Text* t = W.get<Text>(e);
        t && (includeScreenSpace || t->space == RenderSpace::World) && !t->text.empty() && t->fontSize > 0.0f) {
        const Vec2 size = measure.textSize ? measure.textSize(*t) : approx_text_size(t->text, t->fontSize, t->maxWidth);
        out.push_back(make("Text", t->space, t->layer, t->anchor,
                           rect_quad(-t->pivot.x * size.x, -t->pivot.y * size.y, (1.0f - t->pivot.x) * size.x,
                                     (1.0f - t->pivot.y) * size.y)));
    }
    return out;
}

std::optional<Rect> entity_world_rect(const World& W, Entity e, const VisualMeasure& measure) {
    const std::vector<VisualFootprint> parts = visual_footprints(W, e, measure, false);
    const Mat4 m = W.world_matrix(e);
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
