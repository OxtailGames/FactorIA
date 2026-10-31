#include "fa/scene/camera_query.h"

#include <algorithm>
#include <cmath>

#include "fa/scene/components.h"

namespace fa {

std::vector<Entity> rendering_cameras(World& w) {
    struct Found { Entity e; int depth; };
    std::vector<Found> found;
    w.each<Camera>([&](Entity e, Camera& c) {
        if (c.primary && c.renderTarget.empty() && w.active_in_hierarchy(e)) found.push_back({e, c.depth});
    });
    std::stable_sort(found.begin(), found.end(), [](const Found& a, const Found& b) { return a.depth < b.depth; });
    if (found.size() > 8) found.resize(8);
    std::vector<Entity> out;
    for (const Found& f : found) out.push_back(f.e);
    return out;
}

Rect clamped_camera_viewport(const Camera& c) {
    Rect v = c.viewport;
    if (!std::isfinite(v.x) || !std::isfinite(v.y) || !std::isfinite(v.w) || !std::isfinite(v.h) || v.w <= 0.0f || v.h <= 0.0f) return Rect{0, 0, 1, 1};
    v.x = std::clamp(v.x, 0.0f, 0.999f);
    v.y = std::clamp(v.y, 0.0f, 0.999f);
    v.w = std::min(v.w, 1.0f - v.x);
    v.h = std::min(v.h, 1.0f - v.y);
    return v;
}

Entity camera_containing(World& w, Vec2 design, Vec2 point) {
    const std::vector<Entity> cams = rendering_cameras(w);
    const float nx = point.x / design.x, ny = point.y / design.y;
    for (std::size_t i = cams.size(); i-- > 0;) {
        const Rect v = clamped_camera_viewport(*w.get<Camera>(cams[i]));
        if (nx >= v.x && nx < v.x + v.w && ny >= v.y && ny < v.y + v.h) return cams[i];
    }
    return cams.empty() ? kNullEntity : cams.front();
}

OrthoView ortho_view(World& w, Vec2 design, Entity named, const Vec2* point) {
    const std::vector<Entity> cams = rendering_cameras(w);
    Entity cam = cams.empty() ? kNullEntity : cams.front();
    if (!named.is_null() && std::find(cams.begin(), cams.end(), named) != cams.end()) cam = named;
    else if (point && cams.size() > 1) cam = camera_containing(w, design, *point);
    OrthoView v;
    v.camera = cam;
    const Camera* c = cam.is_null() ? nullptr : w.get<Camera>(cam);
    if (c) v.viewport = clamped_camera_viewport(*c);
    const float viewH = design.y * v.viewport.h;
    const float ortho = c && c->orthoSize > 0 ? c->orthoSize : viewH * 0.5f;
    v.scale = viewH * 0.5f / ortho;
    v.position = cam.is_null() ? Vec3{} : w.world_position(cam);
    v.center = {(v.viewport.x + v.viewport.w * 0.5f) * design.x, (v.viewport.y + v.viewport.h * 0.5f) * design.y};
    return v;
}

}  // namespace fa
