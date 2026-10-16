// Panel and ScrollList layout. See ui.h and the Panel / ScrollList docs in components.cpp.
#include <algorithm>
#include <cmath>

#include "ui_internal.h"

namespace fa {

namespace {

using ui_detail::depth_of;
using ui_detail::screen_rect;

struct Child {
    Entity e;
    Rect r;
};

std::vector<Child> children_of(const World& w, Entity e, Vec2 design, const VisualMeasure& m) {
    std::vector<Child> out;
    for (Entity c : w.children(e)) {
        if (!w.info(c).active) continue;
        if (const std::optional<Rect> r = screen_rect(w, c, design, m)) out.push_back({c, *r});
    }
    return out;
}

// Where a box of `size` goes inside `avail`; a box larger than the space sticks to the start.
float align_offset(UiAlign a, float avail, float size) {
    const float spare = std::max(0.0f, avail - size);
    return a == UiAlign::Start ? 0.0f : a == UiAlign::Center ? spare * 0.5f : spare;
}

Vec2 content_size(UiLayout layout, const std::vector<Child>& ch, float spacing, int columns) {
    const int n = int(ch.size());
    if (n == 0) return {0, 0};
    float sumW = 0, sumH = 0, maxW = 0, maxH = 0;
    for (const Child& c : ch) {
        sumW += c.r.w;
        sumH += c.r.h;
        maxW = std::max(maxW, c.r.w);
        maxH = std::max(maxH, c.r.h);
    }
    const float gaps = spacing * float(n - 1);
    switch (layout) {
        case UiLayout::Column: return {maxW, sumH + gaps};
        case UiLayout::Row: return {sumW + gaps, maxH};
        case UiLayout::Grid: {
            const int cols = std::min(std::max(columns, 1), n), rows = (n + cols - 1) / cols;
            return {float(cols) * maxW + float(cols - 1) * spacing, float(rows) * maxH + float(rows - 1) * spacing};
        }
        case UiLayout::None: break;
    }
    return {0, 0};
}

// Top-left corner of every child's slot, in the box `inner` (the container minus its padding).
std::vector<Vec2> place(UiLayout layout, const std::vector<Child>& ch, const Rect& inner, float spacing, int columns,
                        UiAlign align, UiAlign justify) {
    const Vec2 content = content_size(layout, ch, spacing, columns);
    std::vector<Vec2> out;
    out.reserve(ch.size());
    if (layout == UiLayout::Grid) {
        float cellW = 0, cellH = 0;
        for (const Child& c : ch) {
            cellW = std::max(cellW, c.r.w);
            cellH = std::max(cellH, c.r.h);
        }
        const int cols = std::min(std::max(columns, 1), int(ch.size()));
        const float x0 = inner.x + align_offset(justify, inner.w, content.x), y0 = inner.y + align_offset(justify, inner.h, content.y);
        for (std::size_t i = 0; i < ch.size(); ++i) {
            const float cx = x0 + float(int(i) % cols) * (cellW + spacing), cy = y0 + float(int(i) / cols) * (cellH + spacing);
            out.push_back({cx + align_offset(align, cellW, ch[i].r.w), cy + align_offset(align, cellH, ch[i].r.h)});
        }
    } else if (layout == UiLayout::Column) {
        float y = inner.y + align_offset(justify, inner.h, content.y);
        for (const Child& c : ch) {
            out.push_back({inner.x + align_offset(align, inner.w, c.r.w), y});
            y += c.r.h + spacing;
        }
    } else {  // Row
        float x = inner.x + align_offset(justify, inner.w, content.x);
        for (const Child& c : ch) {
            out.push_back({x, inner.y + align_offset(align, inner.h, c.r.h)});
            x += c.r.w + spacing;
        }
    }
    return out;
}

// Moves the child's Transform.position so its rectangle's top-left lands on `slot` (a delta in screen pixels).
void move_to(World& w, const Child& c, Vec2 slot) {
    const float dx = slot.x - c.r.x, dy = slot.y - c.r.y;
    if (std::fabs(dx) < 1e-4f && std::fabs(dy) < 1e-4f) return;
    Transform* t = w.get<Transform>(c.e);
    t->position.x += dx;
    t->position.y += dy;
}

Rect inner_box(const Rect& r, const Vec4& pad) {
    return {r.x + pad.x, r.y + pad.y, std::max(0.0f, r.w - pad.x - pad.z), std::max(0.0f, r.h - pad.y - pad.w)};
}

void layout_panel(World& w, Entity e, Panel& p, Vec2 design, const VisualMeasure& m) {
    if (p.layout == UiLayout::None) return;  // ponytail: fit needs a layout; with none the content has no defined size
    const std::vector<Child> ch = children_of(w, e, design, m);
    if (p.fit) {
        const Vec2 c = content_size(p.layout, ch, p.spacing, p.columns);
        p.size = {c.x + p.padding.x + p.padding.z, c.y + p.padding.y + p.padding.w};
    }
    const Rect inner = inner_box(*ui_rect(w, e, design), p.padding);
    const std::vector<Vec2> slots = place(p.layout, ch, inner, p.spacing, p.columns, p.align, p.justify);
    for (std::size_t i = 0; i < ch.size(); ++i) move_to(w, ch[i], slots[i]);
}

// `focus`: the entity to scroll into view (null when the focus did not just change).
void layout_scroll(World& w, Entity e, ScrollList& s, Entity focus, Vec2 design, const VisualMeasure& m) {
    const std::vector<Child> ch = children_of(w, e, design, m);
    const Rect inner = inner_box(*ui_rect(w, e, design), s.padding);
    const Vec2 content = content_size(UiLayout::Column, ch, s.spacing, 1);
    if (!std::isfinite(s.scroll)) s.scroll = 0.0f;
    if (focus) {  // keep the direct child that holds the focused widget inside the inner box, moving as little as needed
        float top = 0;
        for (const Child& c : ch) {
            bool holds = false;
            for (Entity a = focus; a; a = w.parent(a)) holds = holds || a == c.e;
            if (holds) {
                if (top < s.scroll || c.r.h > inner.h) s.scroll = top;
                else if (top + c.r.h > s.scroll + inner.h) s.scroll = top + c.r.h - inner.h;
                break;
            }
            top += c.r.h + s.spacing;
        }
    }
    s.scroll = std::clamp(s.scroll, 0.0f, std::max(0.0f, content.y - inner.h));
    std::vector<Vec2> slots = place(UiLayout::Column, ch, inner, s.spacing, 1, UiAlign::Start, UiAlign::Start);
    for (std::size_t i = 0; i < ch.size(); ++i) move_to(w, ch[i], {slots[i].x, slots[i].y - s.scroll});
}

}  // namespace

namespace ui_detail {

std::optional<Rect> screen_rect(const World& w, Entity e, Vec2 designSize, const VisualMeasure& measure) {
    if (const std::optional<Rect> r = ui_rect(w, e, designSize)) return r;
    const Mat4 m = w.world_matrix(e);
    bool any = false;
    float x0 = 0, y0 = 0, x1 = 0, y1 = 0;
    for (const VisualFootprint& f : visual_footprints(w, e, measure, true)) {
        if (f.space != RenderSpace::Screen) continue;
        for (const Vec2& p : f.box) {  // the renderer draws a local point (lx, ly) at world_matrix * (lx, -ly) + anchor * design
            const Vec3 q = m.transform_point({p.x, -p.y, 0.0f});
            const float sx = q.x + f.anchor.x * designSize.x, sy = q.y + f.anchor.y * designSize.y;
            x0 = any ? std::min(x0, sx) : sx;
            y0 = any ? std::min(y0, sy) : sy;
            x1 = any ? std::max(x1, sx) : sx;
            y1 = any ? std::max(y1, sy) : sy;
            any = true;
        }
    }
    if (!any) return std::nullopt;
    return Rect{x0, y0, x1 - x0, y1 - y0};
}

}  // namespace ui_detail

void UiSystem::layout(World& w, Vec2 design, const VisualMeasure& m) {
    // Containers deepest first: a nested container is sized and fills itself before the container around it places it
    // (moving a container moves its whole subtree, so what it already placed stays in place).
    std::vector<std::pair<int, Entity>> containers;
    for (const TypeInfo* type : {&World::type_of<Panel>(), &World::type_of<ScrollList>()})
        for (Entity e : w.entities_with(type))
            if (w.alive(e) && w.active_in_hierarchy(e)) containers.push_back({depth_of(w, e), e});
    std::stable_sort(containers.begin(), containers.end(), [](const auto& a, const auto& b) { return a.first > b.first; });
    for (const auto& [depth, e] : containers) {
        if (ScrollList* s = w.get<ScrollList>(e)) layout_scroll(w, e, *s, scrollToFocus_ ? focus_ : kNullEntity, design, m);
        else if (Panel* p = w.get<Panel>(e)) layout_panel(w, e, *p, design, m);
    }
    scrollToFocus_ = false;
}

}  // namespace fa
