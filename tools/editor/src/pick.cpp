// Picking and selection-outline geometry. The footprint of an entity's 2D visuals comes from the ENGINE
// (fa/scene/bounds.h, the same code behind `entity.bounds()` in scripts); this file only adds what an editor needs on top:
//   * a fallback marker for entities that draw nothing (colliders, empty entities),
//   * screen-space visuals, which entity.bounds() deliberately skips: design pixels, origin top-left, local y flipped and
//     the translation moved by the component's `anchor` (exactly what the renderer does),
//   * hit tests in the entity's local space, so a rotated or scaled entity is picked by its real (oriented) box.
// Nothing here touches the window, the renderer or ImGui, so tests can call it on a bare World.
#include <algorithm>
#include <cmath>

#include "editor_internal.h"
#include "fa/scene/ui_rect.h"

namespace fa::editor {

namespace {

std::array<Vec2, 4> rect_quad(Vec2 center, Vec2 half) {
    return {Vec2{center.x - half.x, center.y - half.y}, Vec2{center.x + half.x, center.y - half.y},
            Vec2{center.x + half.x, center.y + half.y}, Vec2{center.x - half.x, center.y + half.y}};
}

VisualFootprint marker(const char* component, int layer, Vec2 center, Vec2 half) {
    VisualFootprint v;
    v.component = component;
    v.layer = layer;
    v.box = rect_quad(center, half);
    v.hull = v.box;
    return v;
}

// The world matrix the renderer draws a part with: screen-space parts get their anchor added to the translation.
Mat4 part_matrix(const World& w, Entity e, const VisualFootprint& part, Vec2 designSize) {
    Mat4 m = part.space == RenderSpace::Screen ? w.world_matrix(e) : visual_world_matrix(w, e);  // world parts: moved by Parallax
    if (part.space == RenderSpace::Screen) {
        const Vec2 a = anchor_point(part.anchor, part.safeArea, designSize, w.safe_insets());
        m.at(3, 0) += a.x;
        m.at(3, 1) += a.y;
    }
    return m;
}

// Local point (x, y up) of a part -> world xy (world parts) or design pixels (screen parts).
Vec2 to_scene(const Mat4& m, const VisualFootprint& part, Vec2 local) {
    const Vec3 p = m.transform_point({local.x, part.space == RenderSpace::Screen ? -local.y : local.y, 0.0f});
    return {p.x, p.y};
}

}  // namespace

PickBounds pick_bounds(const World& w, Entity e, const VisualMeasure& measure) {
    PickBounds b;
    b.valid = true;
    std::vector<VisualFootprint> all = visual_footprints(w, e, measure, true);
    // An entity with a world-space visual is picked in the world; one that only has screen-space visuals on the screen.
    const bool anyWorld = std::any_of(all.begin(), all.end(), [](const VisualFootprint& v) { return v.space == RenderSpace::World; });
    for (VisualFootprint& v : all)
        if (!anyWorld || v.space == RenderSpace::World) b.parts.push_back(v);
    if (!b.parts.empty()) {
        b.screenSpace = !anyWorld;
        b.layer = b.parts.front().layer;
        for (const VisualFootprint& v : b.parts) b.layer = std::max(b.layer, int(v.layer));
        return b;
    }
    if (const Collider2D* c = w.get<Collider2D>(e)) {
        const Vec2 half = c->shape == ColliderShape::Circle ? Vec2{c->radius, c->radius} : c->size * 0.5f;
        b.parts.push_back(marker("Collider2D", -1000, c->offset, half));
        b.layer = -1000;
        return b;
    }
    b.parts.push_back(marker("", -2000, {0, 0}, {12, 12}));  // a lone entity (empty, light, camera): a small handle at its origin
    b.layer = -2000;
    return b;
}

std::vector<PickOutline> pick_outlines(const World& w, Entity e, const PickBounds& b, Vec2 designSize) {
    std::vector<PickOutline> out;
    for (const VisualFootprint& part : b.parts) {
        const Mat4 m = part_matrix(w, e, part, designSize);
        PickOutline o;
        o.screenSpace = part.space == RenderSpace::Screen;
        for (size_t i = 0; i < 4; ++i) {
            o.box[i] = to_scene(m, part, part.box[i]);
            o.hull[i] = to_scene(m, part, part.hull[i]);
        }
        o.hasHull = false;
        for (size_t i = 0; i < 4; ++i)
            if (part.hull[i].x != part.box[i].x || part.hull[i].y != part.box[i].y) o.hasHull = true;
        out.push_back(o);
    }
    return out;
}

Vec2 pick_origin(const World& w, Entity e, const PickBounds& b, Vec2 designSize) {
    if (!b.parts.empty()) {
        const VisualFootprint& part = b.parts.front();
        return to_scene(part_matrix(w, e, part, designSize), part, {0, 0});
    }
    const Vec3 p = w.world_position(e);
    return {p.x, p.y};
}

bool pick_hit(const World& w, Entity e, const PickBounds& b, Vec2 point, Vec2 designSize, int* layerOut) {
    bool hit = false;
    int layer = 0;
    for (const VisualFootprint& part : b.parts) {
        const Mat4 m = part_matrix(w, e, part, designSize);
        // Into the part's local space (y up): rotation and scale of the entity are undone, so the box is the oriented one.
        const Vec3 p = m.inverse().transform_point({point.x, point.y, 0.0f});
        const Vec2 local{p.x, part.space == RenderSpace::Screen ? -p.y : p.y};
        if (!point_in_quad(local, part.box)) continue;
        if (!hit || part.layer > layer) layer = part.layer;
        hit = true;
    }
    if (hit && layerOut) *layerOut = layer;
    return hit;
}

}  // namespace fa::editor
