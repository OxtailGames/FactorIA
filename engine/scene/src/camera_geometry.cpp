#include "fa/scene/camera_geometry.h"

#include <algorithm>
#include <cmath>

#include "fa/core/log.h"
#include "fa/scene/camera_query.h"
#include "fa/scene/components.h"

namespace fa {

namespace {

const CameraGeometry& default_camera() {
    static const CameraGeometry kNone{};
    return kNone;
}

}  // namespace

Rect sanitize_camera_viewport(const Rect& v, std::string& warned) {
    const std::string problem = camera_viewport_problem(v);
    if (problem.empty()) {
        const float x = std::clamp(v.x, 0.0f, 1.0f), y = std::clamp(v.y, 0.0f, 1.0f);
        return Rect{x, y, std::min(v.w, 1.0f - x), std::min(v.h, 1.0f - y)};
    }
    if (warned != problem) {
        warned = problem;
        FA_WARN("render",
                "{}: the camera is drawn with the nearest valid rectangle. Hint: viewport is [x, y, width, height] as "
                "fractions of the screen with [0, 0] the top-left corner, e.g. [0, 0, 0.5, 1] for the left half",
                problem);
    }
    if (!std::isfinite(v.x) || !std::isfinite(v.y) || !std::isfinite(v.w) || !std::isfinite(v.h) || v.w <= 0.0f ||
        v.h <= 0.0f)
        return Rect{0, 0, 1, 1};
    const float x = std::clamp(v.x, 0.0f, 0.999f), y = std::clamp(v.y, 0.0f, 0.999f);
    return Rect{x, y, std::min(v.w, 1.0f - x), std::min(v.h, 1.0f - y)};
}

CameraGeometry camera_geometry(World& world, Entity best, const CameraTarget& target, std::string& warnedViewport,
                               const Vec2* viewSize, bool renderTarget) {
    CameraGeometry ci;
    Camera cam;  // defaults when no camera exists
    Mat4 camWorld;
    if (best) {
        cam = *world.get<Camera>(best);
        camWorld = world.drawn_matrix(best);
        ci.fromEntity = true;
        ci.entity = best;
        ci.depth = cam.depth;
        ci.viewport = sanitize_camera_viewport(cam.viewport, warnedViewport);
        if (cam.viewportSpace == ViewportSpace::Design && !viewSize) {
            // The fractions count the design resolution from the top-left corner: the same pixels in fractions of the target.
            const float sx = float(target.designWidth) / float(std::max(1, target.width)),
                        sy = float(target.designHeight) / float(std::max(1, target.height));
            const float x = std::min(ci.viewport.x * sx, 1.0f), y = std::min(ci.viewport.y * sy, 1.0f);
            ci.viewport = Rect{x, y, std::min(ci.viewport.w * sx, 1.0f - x), std::min(ci.viewport.h * sy, 1.0f - y)};
        }
    }
    // A CameraView's camera fills its image whatever its Camera.viewport says, and always clears it.
    if (viewSize) ci.viewport = Rect{0, 0, 1, 1};
    // The view is drawn into the viewport: its aspect and its height in design pixels are the rectangle's.
    const float viewW = viewSize ? viewSize->x : float(target.width) * ci.viewport.w,
                viewH = viewSize ? viewSize->y : float(target.height) * ci.viewport.h;
    const float aspect = viewW / std::max(viewH, 1.0f);
    // Remove scale from the camera's world matrix: view = R^T * T^-1.
    Vec3 t = camWorld.translation();
    Vec3 x = normalize(Vec3{camWorld.at(0, 0), camWorld.at(0, 1), camWorld.at(0, 2)});
    Vec3 y = normalize(Vec3{camWorld.at(1, 0), camWorld.at(1, 1), camWorld.at(1, 2)});
    Vec3 z = normalize(Vec3{camWorld.at(2, 0), camWorld.at(2, 1), camWorld.at(2, 2)});
    Mat4 view;
    view.at(0, 0) = x.x;
    view.at(1, 0) = x.y;
    view.at(2, 0) = x.z;
    view.at(0, 1) = y.x;
    view.at(1, 1) = y.y;
    view.at(2, 1) = y.z;
    view.at(0, 2) = z.x;
    view.at(1, 2) = z.y;
    view.at(2, 2) = z.z;
    view.at(3, 0) = -dot(x, t);
    view.at(3, 1) = -dot(y, t);
    view.at(3, 2) = -dot(z, t);
    ci.view = view;
    ci.position = t;
    ci.right = x;
    ci.up = y;
    ci.forward = -z;
    // proj for drawing (the backend's depth range) and for queries (always -1..1)
    Mat4 projGl;
    if (cam.projection == Projection::Perspective) {
        ci.perspective = true;
        ci.fov = cam.fov;
        const float nearP = std::max(1e-3f, cam.nearPlane), farP = std::max(cam.farPlane, cam.nearPlane + 0.01f);
        ci.proj = Mat4::perspective(cam.fov, aspect, nearP, farP, target.zeroToOne);
        projGl = target.zeroToOne ? Mat4::perspective(cam.fov, aspect, nearP, farP, false) : ci.proj;
        ci.pixelsPerUnit = 1.0f;
    } else {
        float halfH = cam.orthoSize > 0 ? cam.orthoSize : viewH * 0.5f;
        float halfW = halfH * aspect;
        if (target.expand && cam.orthoSize > 0 && !renderTarget) {
            // Expand: the design height (landscape-ish targets) or design width (taller targets) stays fixed;
            // the other axis grows with the window aspect.
            float designAspect = float(target.designWidth) / float(std::max(1, target.designHeight));
            if (aspect < designAspect) {
                halfW = cam.orthoSize * designAspect;
                halfH = halfW / aspect;
            }
        }
        ci.halfH = halfH;
        ci.halfW = halfW;
        ci.pixelsPerUnit = viewH / (2.0f * halfH);
        ci.proj = Mat4::ortho(-halfW, halfW, -halfH, halfH, -1000.0f, 1000.0f, target.zeroToOne);
        projGl = target.zeroToOne ? Mat4::ortho(-halfW, halfW, -halfH, halfH, -1000.0f, 1000.0f, false) : ci.proj;
        ci.visible = Rect{t.x - halfW, t.y - halfH, halfW * 2, halfH * 2};
        // Rotated 2D cameras: use a conservative (circumscribed) rectangle for culling.
        float rad = std::sqrt(halfW * halfW + halfH * halfH);
        if (std::fabs(x.y) > 1e-3f) ci.visible = Rect{t.x - rad, t.y - rad, rad * 2, rad * 2};
    }
    ci.viewProj = ci.proj * ci.view;
    ci.invViewProj = ci.viewProj.inverse();
    if (target.zeroToOne) {
        ci.queryViewProj = projGl * ci.view;
        ci.queryInvViewProj = ci.queryViewProj.inverse();
    } else {
        ci.queryViewProj = ci.viewProj;
        ci.queryInvViewProj = ci.invViewProj;
    }
    return ci;
}

Vec2 CameraGeometry::world_to_screen(Vec3 p, Vec2 target) const {
    const Vec4 c = queryViewProj * Vec4{p, 1.0f};
    const float w = std::fabs(c.w) > 1e-8f ? c.w : 1e-8f;
    const float nx = c.x / w, ny = c.y / w;
    return {(viewport.x + (nx * 0.5f + 0.5f) * viewport.w) * target.x,
            (viewport.y + (1.0f - (ny * 0.5f + 0.5f)) * viewport.h) * target.y};
}

void CameraGeometry::screen_ray(Vec2 s, Vec2 target, Vec3& origin, Vec3& dir) const {
    const float nx = ((s.x / target.x - viewport.x) / viewport.w) * 2.0f - 1.0f;
    const float ny = 1.0f - ((s.y / target.y - viewport.y) / viewport.h) * 2.0f;
    const Vec3 a = queryInvViewProj.transform_point({nx, ny, -1.0f});
    const Vec3 b = queryInvViewProj.transform_point({nx, ny, 1.0f});
    origin = a;
    dir = normalize(b - a);
    if (perspective) origin = position;
}

Vec3 CameraGeometry::screen_to_world(Vec2 s, Vec2 target, float planeDepth) const {
    Vec3 o, d;
    screen_ray(s, target, o, d);
    if (perspective) return o + d * planeDepth;
    if (std::fabs(d.z) < 1e-6f) return {o.x, o.y, planeDepth};
    const float t = (planeDepth - o.z) / d.z;
    return o + d * t;
}

// ---- CameraSet --------------------------------------------------------------------------------------------------------------

void CameraSet::refresh(World& world, const CameraTarget& size) {
    target_ = size;
    std::size_t total = 0;
    const std::vector<Entity> entities = rendering_cameras(world, &total);
    if (total > entities.size()) {
        if (!warnedCameras_) {
            warnedCameras_ = true;
            FA_WARN(
                "render",
                "{} cameras are active (primary) but a frame draws at most {}: the ones with the highest depth are "
                "left out. Hint: set primary to false on the cameras you do not need, e.g. when a split screen ends",
                total, entities.size());
        }
    }
    cameras_.clear();
    for (const Entity e : entities) cameras_.push_back(camera_geometry(world, e, size, warnedViewport_));
    if (cameras_.empty()) cameras_.push_back(camera_geometry(world, kNullEntity, size, warnedViewport_));
}

Vec2 CameraSet::world_to_screen(Vec3 p, Entity camera) const {
    const CameraGeometry* c = pick_camera(cameras_, camera, nullptr, target());
    return (c ? *c : default_camera()).world_to_screen(p, target());
}

void CameraSet::screen_ray(Vec2 s, Vec3& origin, Vec3& dir, Entity camera) const {
    const CameraGeometry* c = pick_camera(cameras_, camera, &s, target());
    (c ? *c : default_camera()).screen_ray(s, target(), origin, dir);
}

Vec3 CameraSet::screen_to_world(Vec2 s, float depth, Entity camera) const {
    const CameraGeometry* c = pick_camera(cameras_, camera, &s, target());
    return (c ? *c : default_camera()).screen_to_world(s, target(), depth);
}

std::vector<Entity> CameraSet::cameras() const {
    std::vector<Entity> out;
    for (const CameraGeometry& c : cameras_)
        if (c.entity) out.push_back(c.entity);
    return out;
}

Entity CameraSet::camera_at(Vec2 screen) const {
    const CameraGeometry* c = pick_camera(cameras_, kNullEntity, &screen, target());
    return c ? c->entity : kNullEntity;
}

void update_parallax(World& world, Vec2 camPos) {
    world.each<Parallax>(
        [&](Entity, Parallax& p) { p.offset = {camPos.x * (1.0f - p.factor.x), camPos.y * (1.0f - p.factor.y)}; });
}

}  // namespace fa
