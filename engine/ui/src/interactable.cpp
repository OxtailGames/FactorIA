// Interactable: any entity composition as a widget. The geometry of its hit area (world space through the camera, or screen
// space), the state visuals (InteractableVisual), and the knob / fill of a slider. The input side lives in ui.cpp.
#include <algorithm>
#include <cmath>
#include <limits>

#include "fa/core/log.h"
#include "fa/scene/camera_query.h"
#include "ui_internal.h"

namespace fa {

namespace ui_detail {

namespace {

// The entity and its active descendants whose visuals make the area, e first. Left out: the subtree of another Interactable (it
// is a widget of its own), a slider's knob and fill, and the entities that Show / Hide with the state (a highlight bigger than the button would grow the
// area when it shows).
void collect(const World& w, Entity e, const Interactable& ia, std::vector<Entity>& out) {
    out.push_back(e);
    for (Entity c : w.children(e)) {
        if (!w.info(c).active || w.has<Interactable>(c)) continue;
        if (c == ia.knob || c == ia.fill) continue;  // they move with the value
        if (const InteractableVisual* v = w.get<InteractableVisual>(c); v && v->mode == VisualMode::Show) continue;
        collect(w, c, ia, out);
    }
}

struct Geometry {
    bool valid = false;
    bool world = false;
    std::array<Vec2, 4> quad{};
    Vec2 trackA{}, trackB{};
    int layer = 0;
    bool hasLocal = false;   // `local` is the area in the entity's own frame (knob and fill can be placed)
    Rect local;              // x, y = the minimum corner, y up (screen space too: the frame of the footprint boxes)
    bool yFlipped = false;   // screen space: a local y is a position.y of the opposite sign
};

Geometry geometry_of(const World& w, Entity e, const Interactable& ia, Vec2 design, const VisualMeasure& measure,
                     const ProjectFn& project, const Vec2* pointer) {
    Geometry g;
    std::vector<Entity> parts;
    collect(w, e, ia, parts);
    std::vector<std::vector<VisualFootprint>> prints;
    prints.reserve(parts.size());
    bool anyScreen = false;
    for (Entity d : parts) {
        prints.push_back(visual_footprints(w, d, measure, true));
        for (const VisualFootprint& f : prints.back()) {
            anyScreen = anyScreen || f.space == RenderSpace::Screen;
            g.layer = std::max(g.layer, f.layer);
        }
    }
    const bool screen = ia.space == InteractableSpace::Screen || (ia.space == InteractableSpace::Auto && anyScreen);
    const bool explicitArea = ia.size.x > 0.0f && ia.size.y > 0.0f;
    g.world = !screen;
    if (!screen) {
        const Mat4 me = visual_world_matrix(w, e);
        Rect local;
        if (explicitArea) {
            local = Rect::from_center(ia.offset, ia.size);
        } else {
            const Mat4 inv = me.inverse();
            bool any = false;
            float x0 = 0, y0 = 0, x1 = 0, y1 = 0;
            for (std::size_t i = 0; i < parts.size(); ++i) {
                const Mat4 md = visual_world_matrix(w, parts[i]);
                for (const VisualFootprint& f : prints[i]) {
                    if (f.space != RenderSpace::World) continue;
                    for (const Vec2& p : f.box) {
                        const Vec3 q = inv.transform_point(md.transform_point({p.x, p.y, 0.0f}));
                        x0 = any ? std::min(x0, q.x) : q.x;
                        y0 = any ? std::min(y0, q.y) : q.y;
                        x1 = any ? std::max(x1, q.x) : q.x;
                        y1 = any ? std::max(y1, q.y) : q.y;
                        any = true;
                    }
                }
            }
            if (!any) return g;
            local = Rect{x0, y0, x1 - x0, y1 - y0};
        }
        if (!(local.w > 0.0f) || !(local.h > 0.0f)) return g;
        const auto to_screen = [&](Vec2 p) { return project(me.transform_point({p.x, p.y, 0.0f}), pointer); };
        g.quad = {to_screen({local.x, local.y}), to_screen({local.x + local.w, local.y}), to_screen({local.x + local.w, local.y + local.h}),
                  to_screen({local.x, local.y + local.h})};
        const Vec2 c = local.center();
        if (ia.axis == InteractableAxis::X) {
            g.trackA = to_screen({local.x, c.y});
            g.trackB = to_screen({local.x + local.w, c.y});
        } else {
            g.trackA = to_screen({c.x, local.y});
            g.trackB = to_screen({c.x, local.y + local.h});
        }
        g.hasLocal = true;
        g.local = local;
        g.valid = true;
        return g;
    }
    // Screen space, in UI units until the end.
    const float k = ui_scale_clamped(w.ui_scale());
    if (explicitArea) {
        const VisualFootprint* base = nullptr;
        for (const VisualFootprint& f : prints.front())
            if (f.space == RenderSpace::Screen) {
                base = &f;
                break;
            }
        const Vec2 a = base ? anchor_point(base->anchor, base->safeArea, ui_layout_screen(w, design), ui_layout_insets(w)) : Vec2{0, 0};
        Mat4 m = w.world_matrix(e);
        if (base && base->mirrored) m.at(3, 0) = -m.at(3, 0);
        const Rect local = Rect::from_center(ia.offset, ia.size);
        const auto to_screen = [&](Vec2 p) {
            const Vec3 q = m.transform_point({p.x, -p.y, 0.0f});
            return Vec2{(q.x) * k + a.x * k, (q.y) * k + a.y * k};
        };
        g.quad = {to_screen({local.x, local.y}), to_screen({local.x + local.w, local.y}), to_screen({local.x + local.w, local.y + local.h}),
                  to_screen({local.x, local.y + local.h})};
        const Vec2 c = local.center();
        if (ia.axis == InteractableAxis::X) {
            g.trackA = to_screen({local.x, c.y});
            g.trackB = to_screen({local.x + local.w, c.y});
        } else {
            g.trackA = to_screen({c.x, local.y});
            g.trackB = to_screen({c.x, local.y + local.h});
        }
        g.hasLocal = true;
        g.yFlipped = true;
        g.local = local;
        g.valid = true;
        return g;
    }
    bool any = false;
    float x0 = 0, y0 = 0, x1 = 0, y1 = 0;
    for (Entity d : parts) {
        const std::optional<Rect> r = screen_rect(w, d, design, measure);
        if (!r) continue;
        x0 = any ? std::min(x0, r->x) : r->x;
        y0 = any ? std::min(y0, r->y) : r->y;
        x1 = any ? std::max(x1, r->x + r->w) : r->x + r->w;
        y1 = any ? std::max(y1, r->y + r->h) : r->y + r->h;
        any = true;
    }
    if (!any || !(x1 > x0) || !(y1 > y0)) return g;
    const Rect r{x0 * k, y0 * k, (x1 - x0) * k, (y1 - y0) * k};
    g.quad = {Vec2{r.x, r.y}, Vec2{r.x + r.w, r.y}, Vec2{r.x + r.w, r.y + r.h}, Vec2{r.x, r.y + r.h}};
    const Vec2 c = r.center();
    if (ia.axis == InteractableAxis::X) {
        g.trackA = {r.x, c.y};
        g.trackB = {r.x + r.w, c.y};
    } else {  // min at the bottom of the screen
        g.trackA = {c.x, r.y + r.h};
        g.trackB = {c.x, r.y};
    }
    g.valid = true;
    return g;
}

}  // namespace

bool is_custom(const World& w, Entity e) { return w.alive(e) && w.has<Interactable>(e) && ui_kind(w, e) == UiKind::None; }

std::vector<Item> interactable_items(const World& w, Vec2 design, const VisualMeasure& measure, Entity modal, const ProjectFn& project,
                                     const Vec2* pointer) {
    std::vector<Item> out;
    const std::vector<Entity> list = w.entities_with(&World::type_of<Interactable>());
    if (list.empty()) return out;
    // Without a hook: the scene's own cameras (orthographic), picked by the pointer.
    World& wm = const_cast<World&>(w);
    ProjectFn proj = project;
    if (!proj) {
        proj = [&wm, design](Vec3 p, const Vec2* pt) { return ortho_view(wm, design, kNullEntity, pt).to_screen(p); };
    }
    for (Entity e : list) {
        if (!w.alive(e) || !w.active_in_hierarchy(e) || ui_kind(w, e) != UiKind::None) continue;
        const Interactable& ia = *w.get<Interactable>(e);
        const Geometry g = geometry_of(w, e, ia, design, measure, proj, pointer);
        if (!g.valid) continue;
        bool inScope = true;
        if (modal) {
            inScope = false;
            for (Entity a = e; a && !inScope; a = w.parent(a)) inScope = a == modal;
        }
        Item it;
        it.e = e;
        it.layer = g.layer;
        it.interactable = ia.enabled && inScope;
        it.inScope = inScope;
        it.custom = true;
        it.world = g.world;
        it.quad = g.quad;
        it.trackA = g.trackA;
        it.trackB = g.trackB;
        float x0 = g.quad[0].x, y0 = g.quad[0].y, x1 = x0, y1 = y0;
        for (const Vec2& q : g.quad) {
            x0 = std::min(x0, q.x);
            y0 = std::min(y0, q.y);
            x1 = std::max(x1, q.x);
            y1 = std::max(y1, q.y);
        }
        it.rect = Rect{x0, y0, x1 - x0, y1 - y0};
        out.push_back(it);
    }
    return out;
}

bool item_contains(const Item& it, Vec2 p) { return it.custom ? it.rect.contains(p) && point_in_quad(p, it.quad) : it.rect.contains(p); }

float track_fraction(const Item& it, Vec2 p) {
    const Vec2 d = it.trackB - it.trackA;
    const float len2 = dot(d, d);
    if (!(len2 > 1e-6f)) return 0.0f;
    return std::clamp(dot(p - it.trackA, d) / len2, 0.0f, 1.0f);
}

float snap_value(float v, float lo, float hi, float step) {
    const double l = lo, h = std::max(lo, hi);
    double d = std::clamp(double(v), l, h);
    if (step > 0.0f) {  // the nearest step from lo, or hi itself when that is nearer (a range that is not a multiple of step)
        const double grid = std::clamp(l + std::round((d - l) / step) * step, l, h);
        d = std::fabs(h - d) < std::fabs(grid - d) ? h : grid;
    }
    return float(d);
}

}  // namespace ui_detail

// ----------------------------------------------------------------------------------------------------------- state --
namespace {

InteractableState state_of(const Interactable& ia) {
    if (!ia.enabled) return InteractableState::Disabled;
    if (ia.pressed) return InteractableState::Pressed;
    if (ia.hovered) return InteractableState::Hover;
    if (ia.focused) return InteractableState::Focused;
    return InteractableState::Normal;
}

bool holds(VisualWhen when, const Interactable& ia) {
    switch (when) {
        case VisualWhen::Always: return true;
        case VisualWhen::Normal: return ia.enabled && !ia.pressed && !ia.hovered && !ia.focused;
        case VisualWhen::Hover: return ia.hovered;
        case VisualWhen::Pressed: return ia.pressed;
        case VisualWhen::Focused: return ia.focused;
        case VisualWhen::Disabled: return !ia.enabled;
        case VisualWhen::On: return ia.on;
        case VisualWhen::Off: return !ia.on;
    }
    return false;
}

Color* tint_target(World& w, Entity e) {
    if (Sprite* s = w.get<Sprite>(e)) return &s->color;
    if (Shape2D* s = w.get<Shape2D>(e)) return &s->color;
    if (Text* t = w.get<Text>(e)) return &t->color;
    return nullptr;
}

float interactable_fraction(const Interactable& ia) {
    const float span = ia.max - ia.min;
    return span > 0.0f ? std::clamp((ia.value - ia.min) / span, 0.0f, 1.0f) : 0.0f;
}

bool same(const Color& a, const Color& b) { return a.r == b.r && a.g == b.g && a.b == b.b && a.a == b.a; }

}  // namespace

bool ui_is_interactable(const World& w, Entity e) { return ui_detail::is_custom(w, e); }

std::optional<Rect> UiSystem::interactable_rect(const World& w, Entity e, Vec2 design, const VisualMeasure& measure) const {
    if (!ui_detail::is_custom(w, e)) return std::nullopt;
    auto find = [&](const Vec2* pointer) -> std::optional<ui_detail::Item> {
        for (ui_detail::Item& it : ui_detail::interactable_items(w, design, measure, kNullEntity, project_, pointer))
            if (it.e == e) return it;
        return std::nullopt;
    };
    const std::optional<ui_detail::Item> first = find(nullptr);
    if (!first) return std::nullopt;
    if (!first->world) return first->rect;
    // A world widget is seen through the camera that draws at its own centre (several cameras may show different parts).
    const Vec2 centre{first->rect.x + first->rect.w / 2, first->rect.y + first->rect.h / 2};
    const std::optional<ui_detail::Item> again = find(&centre);
    return again ? again->rect : first->rect;
}

void UiSystem::sync_interactables(World& w, Vec2 design, const VisualMeasure& measure) {
    const bool anyIa = !w.entities_with(&World::type_of<Interactable>()).empty();
    const bool anyVis = !w.entities_with(&World::type_of<InteractableVisual>()).empty();
    if (!anyIa && !anyVis) return;
    w.each<Interactable>([&](Entity e, Interactable& ia) {
        if (!ia.enabled) ia.hovered = ia.pressed = ia.focused = false;
        ia.state = state_of(ia);
        if (ia.kind != InteractableKind::Slider || (!ia.knob && !ia.fill)) return;
        if (!w.active_in_hierarchy(e)) return;
        // The knob and the fill sit at the value: the track is the area along `axis`, in the entity's own frame.
        ui_detail::Geometry g = ui_detail::geometry_of(w, e, ia, design, measure,
                                                       [](Vec3, const Vec2*) { return Vec2{}; }, nullptr);
        if (!g.valid || !g.hasLocal) return;
        const float t = interactable_fraction(ia);
        const bool xAxis = ia.axis == InteractableAxis::X;
        const float lo = xAxis ? g.local.x : g.local.y, len = xAxis ? g.local.w : g.local.h;
        const float sign = (g.yFlipped && !xAxis) ? -1.0f : 1.0f;
        const auto place = [&](Entity child, const char* what, bool scale) {
            if (!child || !w.alive(child)) return;
            if (w.parent(child) != e) {
                if (warnedKnobs_.insert(child.bits()).second)
                    FA_WARN("ui", "Interactable '{}': {} '{}' is not a child of it, so it is not moved along the track (make it a child)",
                            w.id_of(e), what, w.id_of(child));
                return;
            }
            Transform* trp = w.get<Transform>(child);
            if (!trp) return;
            Transform& tr = *trp;
            float& pos = xAxis ? tr.position.x : tr.position.y;
            if (scale) {
                float& sc = xAxis ? tr.scale.x : tr.scale.y;
                pos = sign * lo;
                sc = std::max(t, 1e-4f);
            } else {
                pos = sign * (lo + t * len);
            }
        };
        place(ia.knob, "knob", false);
        place(ia.fill, "fill", true);
    });
    if (!anyVis) return;
    w.each<InteractableVisual>([&](Entity e, InteractableVisual& v) {
        Entity target = v.target;
        if (!target || !w.alive(target)) {
            target = kNullEntity;
            for (Entity a = e; a; a = w.parent(a))
                if (w.has<Interactable>(a)) {
                    target = a;
                    break;
                }
        }
        const Interactable* ia = target ? w.get<Interactable>(target) : nullptr;
        if (!ia) return;
        if (v.mode == VisualMode::Show) {
            if (target == e) return;  // hiding the widget itself would leave it unable to ever show again
            const bool on = holds(v.when, *ia);
            if (w.info(e).active != on) w.set_active(e, on);
        } else if (Color* c = tint_target(w, e)) {
            const Color& want = !ia->enabled ? v.disabled : ia->pressed ? v.pressed : ia->hovered ? v.hover : ia->focused ? v.focused : v.normal;
            if (!same(*c, want)) *c = want;
        }
    });
}

}  // namespace fa
