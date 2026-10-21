// The math behind the viewport gizmos: see gizmo_model.h.
#include "gizmo_model.h"

#include <algorithm>
#include <cmath>
#include <limits>

namespace fa::editor {

namespace {

const char* kAxisName[3] = {"x", "y", "z"};

Vec2 sub(Vec2 a, Vec2 b) { return {a.x - b.x, a.y - b.y}; }
float len2(Vec2 a) { return std::sqrt(a.x * a.x + a.y * a.y); }
float dot2(Vec2 a, Vec2 b) { return a.x * b.x + a.y * b.y; }

float seg_distance(Vec2 p, Vec2 a, Vec2 b) {
    const Vec2 ab = sub(b, a);
    const float l2 = dot2(ab, ab);
    const float t = l2 > 1e-12f ? std::clamp(dot2(sub(p, a), ab) / l2, 0.0f, 1.0f) : 0.0f;
    return len2(sub(p, Vec2{a.x + ab.x * t, a.y + ab.y * t}));
}

float ring_distance(Vec2 p, const std::vector<Vec2>& ring) {
    float best = std::numeric_limits<float>::max();
    for (size_t i = 0; i < ring.size(); ++i) best = std::min(best, seg_distance(p, ring[i], ring[(i + 1) % ring.size()]));
    return best;
}

}  // namespace

Vec3 unit_axis(int i) { return {i == 0 ? 1.0f : 0.0f, i == 1 ? 1.0f : 0.0f, i == 2 ? 1.0f : 0.0f}; }
float axis_value(Vec3 v, int i) { return i == 0 ? v.x : i == 1 ? v.y : v.z; }
Vec3 with_axis(Vec3 v, int i, float value) {
    if (i == 0) v.x = value;
    else if (i == 1) v.y = value;
    else v.z = value;
    return v;
}

const char* gizmo_mode_name(GizmoMode m) {
    switch (m) {
        case GizmoMode::Select: return "select";
        case GizmoMode::Move: return "move";
        case GizmoMode::Rotate: return "rotate";
        case GizmoMode::Scale: return "scale";
    }
    return "?";
}

std::string gizmo_handle_name(GizmoHandle h) {
    const char* axis = h.axis >= 0 && h.axis < 3 ? kAxisName[h.axis] : "?";
    switch (h.kind) {
        case GizmoKind::MoveAxis: return std::string("move:") + axis;
        case GizmoKind::MovePlane: return "move:plane";
        case GizmoKind::RotateAxis: return std::string("rotate:") + axis;
        case GizmoKind::ScaleAxis: return std::string("scale:") + axis;
        case GizmoKind::ScaleAll: return "scale:all";
        case GizmoKind::None: break;
    }
    return "none";
}

std::vector<GizmoShape> gizmo_layout(GizmoMode mode, const GizmoView& view, const GizmoFrame& frame) {
    std::vector<GizmoShape> out;
    if (mode == GizmoMode::Select || !view.project) return out;
    const Vec2 p0 = view.project(frame.pivot);
    // Screen pixels per world unit around the pivot: the best of the three world axes (one of them is never foreshortened much).
    float pxPerUnit = 0;
    for (int i = 0; i < 3; ++i) {
        pxPerUnit = std::max(pxPerUnit, len2(sub(view.project(frame.pivot + unit_axis(i)), p0)));
    }
    if (pxPerUnit < 1e-6f) pxPerUnit = 1.0f;

    if (mode == GizmoMode::Rotate) {
        // 2D: one ring around Z. 3D: one around each local axis, in the plane of the other two.
        for (int i = view.threeD ? 0 : 2; i < 3; ++i) {
            GizmoShape s;
            s.type = GizmoShape::Type::Ring;
            s.handle = {GizmoKind::RotateAxis, i};
            s.centre = p0;
            const Vec3 u = frame.local[(i + 1) % 3], v = frame.local[(i + 2) % 3];
            const float radius = view.ringPx / pxPerUnit;
            const int n = 64;
            for (int k = 0; k < n; ++k) {
                const float a = 2.0f * kPi * float(k) / float(n);
                s.ring.push_back(view.project(frame.pivot + (u * std::cos(a) + v * std::sin(a)) * radius));
            }
            out.push_back(std::move(s));
        }
        return out;
    }

    const bool move = mode == GizmoMode::Move;
    const float unit = view.armPx / pxPerUnit;  // world length of about one arm
    for (int i = 0; i < (view.threeD ? 3 : 2); ++i) {
        const Vec3 axis = move ? unit_axis(i) : frame.local[i];
        const Vec2 d = sub(view.project(frame.pivot + axis * unit), p0);
        const float l = len2(d);
        if (l < 0.15f * view.armPx) continue;  // pointing at the camera
        GizmoShape s;
        s.type = GizmoShape::Type::Arm;
        s.handle = {move ? GizmoKind::MoveAxis : GizmoKind::ScaleAxis, i};
        s.dir = {d.x / l, d.y / l};
        s.from = p0;
        s.to = {p0.x + s.dir.x * view.armPx, p0.y + s.dir.y * view.armPx};
        s.centre = p0;
        s.tipBox = !move;
        s.half = view.tipHalfPx;
        out.push_back(std::move(s));
    }
    GizmoShape c;
    c.type = GizmoShape::Type::Centre;
    c.handle = {move ? GizmoKind::MovePlane : GizmoKind::ScaleAll, -1};
    c.centre = p0;
    c.half = view.centreHalfPx;
    out.push_back(std::move(c));
    return out;
}

GizmoHandle gizmo_hit(const std::vector<GizmoShape>& shapes, Vec2 m, float tol) {
    for (const GizmoShape& s : shapes)
        if (s.type == GizmoShape::Type::Centre && std::fabs(m.x - s.centre.x) <= s.half && std::fabs(m.y - s.centre.y) <= s.half) return s.handle;
    for (const GizmoShape& s : shapes)
        if (s.type == GizmoShape::Type::Arm && s.tipBox && std::fabs(m.x - s.to.x) <= s.half && std::fabs(m.y - s.to.y) <= s.half) return s.handle;
    GizmoHandle best;
    float bestD = tol;
    for (const GizmoShape& s : shapes) {
        float d = std::numeric_limits<float>::max();
        if (s.type == GizmoShape::Type::Arm) d = seg_distance(m, s.from, s.to);
        else if (s.type == GizmoShape::Type::Ring) d = ring_distance(m, s.ring);
        if (d <= bestD && (d < bestD || !best)) {  // the first of equals wins (x before y before z)
            best = s.handle;
            bestD = d;
        }
    }
    return best;
}

Vec2 gizmo_grab_point(const GizmoShape& s) {
    switch (s.type) {
        case GizmoShape::Type::Arm:
            if (s.tipBox) return s.to;
            return {s.from.x + (s.to.x - s.from.x) * 0.7f, s.from.y + (s.to.y - s.from.y) * 0.7f};
        case GizmoShape::Type::Centre: return s.centre;
        case GizmoShape::Type::Ring: return s.ring.empty() ? s.centre : s.ring[s.ring.size() / 8];
    }
    return s.centre;
}

float axis_drag_distance(const ProjectFn& project, Vec3 pivot, Vec3 axis, Vec2 a, Vec2 b) {
    const Vec2 p0 = project(pivot), p1 = project(pivot + axis);
    const Vec2 d = sub(p1, p0);
    const float l2 = dot2(d, d);
    if (l2 < 1e-12f) return 0.0f;
    return dot2(sub(b, a), d) / l2;  // px along the axis' screen direction / px per world unit
}

bool ray_plane(Vec3 o, Vec3 d, Vec3 p, Vec3 n, Vec3& out) {
    const float denom = dot(d, n);
    if (std::fabs(denom) < 1e-6f) return false;
    const float t = dot(p - o, n) / denom;
    if (t < 0) return false;
    out = o + d * t;
    return true;
}

float snap_to(float v, float step) { return step > 0 ? std::round(v / step) * step : v; }

Vec3 snap_move(Vec3 start, Vec3 moved, float step) {
    auto snap = [step](float s, float m) { return std::fabs(m - s) > 1e-6f ? snap_to(m, step) : m; };
    return {snap(start.x, moved.x), snap(start.y, moved.y), snap(start.z, moved.z)};
}

Vec3 world_to_local_position(const Mat4& parentWorld, Vec3 world) { return parentWorld.inverse().transform_point(world); }

float wrap_deg(float d) {
    d = std::fmod(d, 360.0f);
    if (d > 180.0f) d -= 360.0f;
    if (d <= -180.0f) d += 360.0f;
    return d;
}

float mouse_angle_deg(Vec2 p, Vec2 m) { return degrees(std::atan2(m.y - p.y, m.x - p.x)); }

float rotation_sign(const ProjectFn& project, Vec3 pivot, Vec3 u, Vec3 v) {
    const Vec2 p0 = project(pivot);
    const Vec2 su = sub(project(pivot + u), p0), sv = sub(project(pivot + v), p0);
    return su.x * sv.y - su.y * sv.x >= 0 ? 1.0f : -1.0f;
}

Vec3 rotate_local_euler(Vec3 e, int axis, float deg) {
    if (axis == 2) return {e.x, e.y, e.z + deg};  // R * Rz(d) = Ry Rx Rz(z + d): exact, and keeps turning past 180
    return (Quat::from_euler_deg(e) * Quat::axis_angle_deg(unit_axis(axis), deg)).to_euler_deg();
}

float scale_axis_factor(Vec2 pivot, Vec2 dir, Vec2 a, Vec2 b) {
    const float start = dot2(sub(a, pivot), dir);
    if (std::fabs(start) < 1.0f) return 1.0f;
    return std::max(kMinScaleFactor, dot2(sub(b, pivot), dir) / start);
}

float scale_uniform_factor(Vec2 a, Vec2 b, float refPx) {
    return std::max(kMinScaleFactor, 1.0f + ((b.x - a.x) - (b.y - a.y)) / std::max(1.0f, refPx));
}

float scale_apply(float start, float factor, float snapStep) {
    if (start == 0.0f) return 0.0f;
    const float sign = start < 0 ? -1.0f : 1.0f;
    float mag = std::fabs(start) * std::max(factor, kMinScaleFactor);
    if (snapStep > 0) mag = std::max(snapStep, snap_to(mag, snapStep));
    return sign * mag;
}

}  // namespace fa::editor
