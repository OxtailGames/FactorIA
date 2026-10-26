// Panel and ScrollList layout. See ui.h and the Panel / ScrollList docs in components.cpp.
#include <algorithm>
#include <cmath>
#include <limits>
#include <utility>
#include <vector>

#include "fa/core/log.h"
#include "fa/scene/text_fit.h"
#include "ui_internal.h"

namespace fa {

namespace {

using ui_detail::control_of;
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

// The layout the panel is laid out with right now.
UiLayout used_layout(const Panel& p) { return p.usingFallback ? p.fallbackLayout : p.layout; }

// Panel.minSize and maxSize: 0 on an axis means no bound; when they cross, minSize wins.
Vec2 clamp_panel_size(const Panel& p, Vec2 size) {
    if (p.maxSize.x > 0) size.x = std::min(size.x, p.maxSize.x);
    if (p.maxSize.y > 0) size.y = std::min(size.y, p.maxSize.y);
    if (p.minSize.x > 0) size.x = std::max(size.x, p.minSize.x);
    if (p.minSize.y > 0) size.y = std::max(size.y, p.minSize.y);
    return size;
}

void layout_panel(World& w, Entity e, Panel& p, Vec2 design, const VisualMeasure& m) {
    const UiLayout layout = used_layout(p);
    if (layout == UiLayout::None) {  // ponytail: fit needs a layout; with none the content has no defined size
        p.size = clamp_panel_size(p, p.size);
        return;
    }
    const std::vector<Child> ch = children_of(w, e, design, m);
    if (p.fit) {
        const Vec2 c = content_size(layout, ch, p.spacing, p.columns);
        p.size = {c.x + p.padding.x + p.padding.z, c.y + p.padding.y + p.padding.w};
    }
    p.size = clamp_panel_size(p, p.size);
    const Rect inner = inner_box(*ui_layout_rect(w, e, design), p.padding);
    std::vector<Vec2> slots = place(layout, ch, inner, p.spacing, p.columns, p.align, p.justify);
    // Right to left: the left-to-right layout flipped about the middle of the box, so the first child, `start` and a grid's
    // first column all end up on the right.
    if (p.direction == UiDirection::Rtl || (p.direction == UiDirection::Auto && w.rtl()))
        for (std::size_t i = 0; i < ch.size(); ++i) slots[i].x = 2.0f * inner.x + inner.w - slots[i].x - ch[i].r.w;
    for (std::size_t i = 0; i < ch.size(); ++i) move_to(w, ch[i], slots[i]);
}

// Size of `s` as the renderer draws a UI label: at the player's text size (the measure does that), wrapped at `maxWidth` if > 0.
Vec2 label_extent(const VisualMeasure& m, const std::string& s, const std::string& font, float fontSize, float maxWidth,
                  float maxTextScale, TextStyle style = {}) {
    if (s.empty()) return {0, 0};
    Text t;
    t.text = s;
    t.font = font;
    t.fontSize = fontSize;
    t.maxWidth = maxWidth;
    t.markup = style.markup;
    t.bold = style.bold;
    t.maxTextScale = maxTextScale;  // autoShrink stays off: autoSize makes room for the label at its full (capped) size
    t.space = RenderSpace::Screen;
    return m.textSize ? m.textSize(t) : approx_text_size(t, m.textScale);
}

// The size a Button / Toggle / Slider with autoSize takes: its `design` size, or what its label needs when that is more.
// The margins match what fa_render draws (ui2d.cpp): a toggle's box and a slider's label / track / value zones.
Vec2 fitted_size(const Button& b, Vec2 design, const VisualMeasure& m) {
    Vec2 label = label_extent(m, b.text, b.font, b.fontSize, 0.0f, b.maxTextScale, {b.markup, b.bold});
    if (b.maxWidth > 0 && label.x > b.maxWidth) label = label_extent(m, b.text, b.font, b.fontSize, b.maxWidth, b.maxTextScale, {b.markup, b.bold});
    if (label.x <= 0) return design;
    return {std::max(design.x, std::ceil(label.x + 32.0f)), std::max(design.y, std::ceil(label.y + 16.0f))};
}

Vec2 fitted_size(const Toggle& t, Vec2 design, const VisualMeasure& m) {
    Vec2 label = label_extent(m, t.label, t.font, t.fontSize, 0.0f, t.maxTextScale, {t.markup, t.bold});
    if (t.maxWidth > 0 && label.x > t.maxWidth) label = label_extent(m, t.label, t.font, t.fontSize, t.maxWidth, t.maxTextScale, {t.markup, t.bold});
    if (label.x <= 0) return design;
    const float h = std::max(design.y, std::ceil(label.y + 16.0f));
    const float side = ui_toggle_box_side(t, h, m.textScale);
    return {std::max(design.x, std::ceil(side + 28.0f + label.x)), h};  // 6 margin + box + 10 gap + label + 12 margin
}

Vec2 fitted_size(const Slider& s, Vec2 design, const VisualMeasure& m) {
    Vec2 label = label_extent(m, s.label, s.font, s.fontSize, 0.0f, s.maxTextScale, {s.markup, s.bold});
    if (s.maxWidth > 0 && label.x > s.maxWidth) label = label_extent(m, s.label, s.font, s.fontSize, s.maxWidth, s.maxTextScale, {s.markup, s.bold});
    const bool above = ui_slider_label_above(s);
    // Beside the track the label gets 35% of the width inside the 8 px margins; above it, the whole width.
    float inner = label.x > 0 ? (above ? label.x : (label.x + 12.0f) / 0.35f) : 0.0f;
    float textH = above ? 0.0f : label.y;
    float height = 0.0f;
    if (above) height = std::ceil(label.y + 4.0f + kUiSliderRowHeight);  // label, then the row of the track
    if (s.showValue) {
        Vec2 value{0, 0};
        for (float v : {s.min, s.max}) {  // the ends of the range: the size must not change while the knob moves
            const Vec2 e = label_extent(m, ui_slider_value_text(s, v), s.font, s.fontSize, 0.0f, s.maxTextScale);
            value = {std::max(value.x, e.x), std::max(value.y, e.y)};
        }
        inner = std::max(inner, (value.x - 16.0f) / 0.15f);  // the value gets the last 15%; it may spill 8 px each side
        textH = std::max(textH, value.y);
    }
    if (inner <= 0 && height <= 0) return design;
    return {std::max(design.x, std::ceil(inner + 16.0f)), std::max({design.y, std::ceil(textH + 8.0f), height})};
}

// Sets the size of every autoSize widget of kind T. The design size is remembered: the UI wrote `applied` last time, so a
// different size now was written by the game (or the file) and is the new design size.
template <class T, class Memo>
void autosize_kind(World& w, Memo& memo, const VisualMeasure& m) {
    for (Entity e : w.entities_with(&World::type_of<T>())) {
        if (!w.alive(e)) continue;
        T* c = w.get<T>(e);
        const auto it = memo.find(e.bits());
        if (!c->autoSize) {
            if (it != memo.end()) memo.erase(it);
            continue;
        }
        if (!w.active_in_hierarchy(e)) continue;
        const bool ours = it != memo.end() && it->second.applied.x == c->size.x && it->second.applied.y == c->size.y;
        const Vec2 design = ours ? it->second.design : c->size;
        c->size = fitted_size(*c, design, m);
        memo[e.bits()] = {design, c->size};
    }
}

// Panel.uniformSize: every autoSize Button / Toggle / Slider below `root` takes the largest width and height among them.
// `applied` is the size the UI wrote, so the next frame still finds the design size.
template <class Memo>
void uniform_size(World& w, Entity root, Memo& memo) {
    std::vector<std::pair<Entity, UiControl*>> sized;
    std::vector<Entity> todo{root};
    Vec2 big{0, 0};
    while (!todo.empty()) {
        const Entity e = todo.back();
        todo.pop_back();
        for (Entity c : w.children(e)) {
            if (!w.info(c).active) continue;
            todo.push_back(c);
            if (!memo.count(c.bits())) continue;  // not an autoSize widget (autosize_kind keeps a memo for each)
            UiControl* u = control_of(w, c);
            if (!u) continue;
            sized.push_back({c, u});
            big = {std::max(big.x, u->size.x), std::max(big.y, u->size.y)};
        }
    }
    for (auto [c, u] : sized) {
        u->size = big;
        memo[c.bits()].applied = big;
    }
}

// The height a ScrollList needs to show all its children without scrolling.
float list_content_height(World& w, Entity e, const ScrollList& s, Vec2 design, const VisualMeasure& m) {
    return content_size(UiLayout::Column, children_of(w, e, design, m), s.spacing, 1).y + s.padding.y + s.padding.w;
}

// ScrollList.fill and ScrollList.shrink: the height the parent column leaves, see the fields' docs.
void apply_fill(World& w, Entity e, Vec2 design, const VisualMeasure& m) {
    ScrollList* s = w.get<ScrollList>(e);
    const Entity parent = w.parent(e);
    const Panel* p = parent ? w.get<Panel>(parent) : nullptr;
    if (!(s->fill || s->shrink) || !p || used_layout(*p) != UiLayout::Column) return;
    float others = 0;
    int kids = 0;
    std::vector<std::pair<float, Entity>> lists;  // the lists that share the room: their need (infinite for fill), and who
    for (const Child& c : children_of(w, parent, design, m)) {
        ++kids;
        ScrollList* l = w.get<ScrollList>(c.e);
        if (l && l->fill) lists.push_back({std::numeric_limits<float>::infinity(), c.e});
        else if (l && l->shrink) lists.push_back({list_content_height(w, c.e, *l, design, m), c.e});
        else others += c.r.h;
    }
    float room = p->size.y;
    if (p->fit) {
        const EdgeInsets in = ui_layout_insets(w);
        const float screenH = ui_layout_screen(w, design).y;
        room = p->safeArea ? screenH - in.top - in.bottom : screenH;
        if (p->maxSize.y > 0) room = std::min(room, p->maxSize.y);
    }
    const float free = room - p->padding.y - p->padding.w - p->spacing * float(std::max(0, kids - 1)) - others;
    // Water-filling: the shortest needs are met first, the rest share what is left equally.
    std::sort(lists.begin(), lists.end(), [](const auto& a, const auto& b) { return a.first < b.first; });
    float left = free;
    for (std::size_t i = 0; i < lists.size(); ++i) {
        const float share = left / float(lists.size() - i);
        const float h = std::max(64.0f, std::floor(std::min(lists[i].first, share)));
        if (lists[i].second == e) {
            s->size.y = h;
            return;
        }
        left -= h;
    }
}

// `focus`: the entity to scroll into view (null when the focus did not just change).
void layout_scroll(World& w, Entity e, ScrollList& s, Entity focus, Vec2 design, const VisualMeasure& m) {
    const std::vector<Child> ch = children_of(w, e, design, m);
    const Rect inner = inner_box(*ui_layout_rect(w, e, design), s.padding);
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

// Whether `e` (laid out with its `layout`) leaves the screen: the size it needs, or the size of the outermost fit Panel around
// it, is too wide for a row / grid or too tall for a column / grid.
bool leaves_screen(const World& w, Entity e, const Panel& p, Vec2 design, const VisualMeasure& m) {
    const Vec2 c = content_size(p.layout, children_of(w, e, design, m), p.spacing, p.columns);
    Vec2 need{c.x + p.padding.x + p.padding.z, c.y + p.padding.y + p.padding.w};
    for (Entity a = w.parent(e); a; a = w.parent(a)) {
        const Panel* up = w.get<Panel>(a);
        if (!up || !up->fit || used_layout(*up) == UiLayout::None) break;
        need = up->size;
    }
    const Vec2 screen = ui_layout_screen(w, design);
    const bool wide = need.x > screen.x + 0.5f, tall = need.y > screen.y + 0.5f;
    return (wide && (p.layout == UiLayout::Row || p.layout == UiLayout::Grid)) ||
           (tall && (p.layout == UiLayout::Column || p.layout == UiLayout::Grid));
}

}  // namespace

namespace ui_detail {

std::optional<Rect> screen_rect(const World& w, Entity e, Vec2 designSize, const VisualMeasure& measure) {
    if (const std::optional<Rect> r = ui_layout_rect(w, e, designSize)) return r;
    const Mat4 m = w.world_matrix(e);
    const Vec2 uiScreen = ui_layout_screen(w, designSize);
    const EdgeInsets uiInsets = ui_layout_insets(w);
    bool any = false;
    float x0 = 0, y0 = 0, x1 = 0, y1 = 0;
    for (const VisualFootprint& f : visual_footprints(w, e, measure, true)) {
        if (f.space != RenderSpace::Screen) continue;
        for (const Vec2& p : f.box) {  // the renderer draws a local point (lx, ly) at world_matrix * (lx, -ly) + the anchor point
            const Vec3 q = m.transform_point({p.x, -p.y, 0.0f});
            const Vec2 a = anchor_point(f.anchor, f.safeArea, uiScreen, uiInsets);
            const float sx = q.x + a.x, sy = q.y + a.y;
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

std::optional<Rect> ui_screen_rect(const World& w, Entity e, Vec2 designSize, const VisualMeasure& measure) {
    std::optional<Rect> r = ui_detail::screen_rect(w, e, designSize, measure);
    if (!r) return r;
    const float k = ui_scale_clamped(w.ui_scale());  // layout works in UI units; callers get screen pixels
    return Rect{r->x * k, r->y * k, r->w * k, r->h * k};
}

void UiSystem::layout(World& w, Vec2 design, const VisualMeasure& m, bool warn) {
    // Containers deepest first: a nested container is sized and fills itself before the container around it places it
    // (moving a container moves its whole subtree, so what it already placed stays in place).
    std::vector<std::pair<int, Entity>> containers;
    // Widgets that fit their label come first, so every container sees their final sizes.
    autosize_kind<Button>(w, autoSizes_, m);
    autosize_kind<Toggle>(w, autoSizes_, m);
    autosize_kind<Slider>(w, autoSizes_, m);
    for (auto it = autoSizes_.begin(); it != autoSizes_.end();)
        it = w.alive(Entity::from_bits(it->first)) ? std::next(it) : autoSizes_.erase(it);
    for (Entity e : w.entities_with(&World::type_of<Panel>()))
        if (w.alive(e) && w.active_in_hierarchy(e) && w.get<Panel>(e)->uniformSize) uniform_size(w, e, autoSizes_);
    for (const TypeInfo* type : {&World::type_of<Panel>(), &World::type_of<ScrollList>()})
        for (Entity e : w.entities_with(type))
            if (w.alive(e) && w.active_in_hierarchy(e)) containers.push_back({depth_of(w, e), e});
    // A `fill` list comes last among its siblings: the other children (nested panels included) have their final height by then.
    const auto fills = [&](Entity e) {
        const ScrollList* s = w.get<ScrollList>(e);
        return s && (s->fill || s->shrink);
    };
    std::stable_sort(containers.begin(), containers.end(), [&](const auto& a, const auto& b) {
        return a.first != b.first ? a.first > b.first : (!fills(a.second) && fills(b.second));
    });
    for (const auto& [depth, e] : containers)
        if (Panel* p = w.get<Panel>(e)) p->usingFallback = false;
    // ponytail: a panel that falls back costs one more layout pass per frame (cheap while UI trees are small).
    for (;;) {
        for (const auto& [depth, e] : containers) {
            if (ScrollList* s = w.get<ScrollList>(e)) {
                apply_fill(w, e, design, m);
                layout_scroll(w, e, *s, scrollToFocus_ ? focus_ : kNullEntity, design, m);
            } else if (Panel* p = w.get<Panel>(e)) {
                layout_panel(w, e, *p, design, m);
            }
        }
        std::vector<Entity> candidates;  // the deepest panels that leave the screen (containers are sorted deepest first)
        for (const auto& [depth, e] : containers) {
            if (!candidates.empty() && depth < depth_of(w, candidates.front())) break;
            const Panel* p = w.get<Panel>(e);
            if (p && p->fallbackLayout != UiLayout::None && p->fallbackLayout != p->layout && !p->usingFallback &&
                p->layout != UiLayout::None && leaves_screen(w, e, *p, design, m))
                candidates.push_back(e);
        }
        if (candidates.empty()) break;
        for (Entity e : candidates) w.get<Panel>(e)->usingFallback = true;
    }
    scrollToFocus_ = false;
    for (const auto& [depth, e] : containers) {  // only the final layout can be too big
        const Panel* p = w.get<Panel>(e);
        if (!warn || !p || !p->fit || used_layout(*p) == UiLayout::None) continue;
        const Vec2 screen = ui_layout_screen(w, design);
        if (p->size.x > screen.x + 0.5f || p->size.y > screen.y + 0.5f) {
            if (warnedFit_.insert(e.bits()).second)
                FA_WARN("ui",
                        "Panel '{}' (fit) is {} x {} px, larger than the {} x {} px screen, so part of it is off screen. Shorten its "
                        "texts, make a ScrollList in it `fill` the free height, set a `fallbackLayout`, lower the font sizes or "
                        "the interface scale (ui.scale; the sizes are in UI units, the screen is {} x {} of them).",
                        w.info(e).id, int(std::ceil(p->size.x)), int(std::ceil(p->size.y)), int(screen.x), int(screen.y),
                        int(screen.x), int(screen.y));
        } else {
            warnedFit_.erase(e.bits());
        }
    }
}

}  // namespace fa
