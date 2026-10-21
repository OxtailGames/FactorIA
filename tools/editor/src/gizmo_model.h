// The math behind the viewport's transform gizmos (move / rotate / scale), with no ImGui, renderer or window: where the handles
// are on screen, which one the mouse is over, and what a drag of each one does to a Transform. Everything works through a
// projection function (world point -> panel pixels), so an orthographic 2D camera, a perspective 3D camera and screen-space
// (HUD) entities share the code. The viewport (viewport_gizmo.cpp) only draws the shapes and calls these; gizmo_tests.cpp
// covers them. All screen coordinates are the viewport panel's pixels, y down.
#pragma once

#include <functional>
#include <string>
#include <vector>

#include "fa/core/math.h"

namespace fa::editor {

enum class GizmoMode { Select, Move, Rotate, Scale };
const char* gizmo_mode_name(GizmoMode mode);

enum class GizmoKind { None, MoveAxis, MovePlane, RotateAxis, ScaleAxis, ScaleAll };
struct GizmoHandle {
    GizmoKind kind = GizmoKind::None;
    int axis = -1;  // 0 x, 1 y, 2 z for the axis kinds
    bool operator==(const GizmoHandle& o) const { return kind == o.kind && axis == o.axis; }
    explicit operator bool() const { return kind != GizmoKind::None; }
};
std::string gizmo_handle_name(GizmoHandle h);  // "move:x", "move:plane", "rotate:z", "scale:all"...

using ProjectFn = std::function<Vec2(Vec3)>;  // world point -> panel pixels

struct GizmoView {
    ProjectFn project;
    bool threeD = false;        // a perspective camera looking at a world-space entity: z handles and three rotation rings
    float armPx = 80.0f;        // length of an arrow / scale handle
    float ringPx = 62.0f;       // radius of a rotation ring
    float tipHalfPx = 6.0f;     // half size of a scale handle's end box
    float centreHalfPx = 8.0f;  // half size of the centre square (free move, uniform scale)
};

// What the gizmo is attached to: the pivot in world space and the entity's LOCAL axes as world directions (unit length).
struct GizmoFrame {
    Vec3 pivot{};
    Vec3 local[3] = {{1, 0, 0}, {0, 1, 0}, {0, 0, 1}};
};

struct GizmoShape {
    enum class Type { Arm, Centre, Ring } type = Type::Arm;
    GizmoHandle handle;
    Vec2 from{}, to{};        // Arm: pivot -> tip (screen)
    Vec2 dir{};               // Arm: unit screen direction
    bool tipBox = false;      // Arm: ends in a box (scale)
    Vec2 centre{};            // the pivot on screen (Centre: the square's centre)
    float half = 0;           // Centre / tip box half size
    std::vector<Vec2> ring;   // Ring: closed polyline
};

// The shapes of `mode`'s gizmo (empty for Select). Move arms follow the WORLD axes, rotation rings and scale handles the LOCAL
// ones. An axis that points almost straight at the camera is left out (it cannot be dragged).
std::vector<GizmoShape> gizmo_layout(GizmoMode mode, const GizmoView& view, const GizmoFrame& frame);
// The handle under `mouse` (tolerance `tolPx` around lines). Priority: the centre square, then a scale handle's end box, then
// the nearest arm or ring.
GizmoHandle gizmo_hit(const std::vector<GizmoShape>& shapes, Vec2 mouse, float tolPx);
// A point on the shape that gizmo_hit maps back to the same handle (the tests and the autotest grab handles there).
Vec2 gizmo_grab_point(const GizmoShape& s);

// ------------------------------------------------------------------------------------------------------------- move
// World distance along the unit world `axis` that a mouse drag from `mouseStart` to `mouseNow` stands for.
float axis_drag_distance(const ProjectFn& project, Vec3 pivot, Vec3 axis, Vec2 mouseStart, Vec2 mouseNow);
// Intersection of the ray (o, d) with the plane through `p` with normal `n`; false when parallel or behind the origin.
bool ray_plane(Vec3 o, Vec3 d, Vec3 p, Vec3 n, Vec3& out);
// `v` rounded to a multiple of `step` (step <= 0: unchanged).
float snap_to(float v, float step);
// `moved` with every component that differs from `start` snapped to `step`.
Vec3 snap_move(Vec3 start, Vec3 moved, float step);
// A world position in the space of a parent with world matrix `parentWorld` (identity: no parent): the local position to write.
Vec3 world_to_local_position(const Mat4& parentWorld, Vec3 world);

// -------------------------------------------------------------------------------------------------------- rotate
float wrap_deg(float deg);  // into (-180, 180]
// The mouse's angle around the projected pivot in degrees (screen angle, y down: clockwise grows).
float mouse_angle_deg(Vec2 pivot, Vec2 mouse);
// +1 when a positive turn about the world axis u x v shows clockwise on screen, -1 when counter-clockwise: how a change of the
// mouse's screen angle maps to a turn about the axis.
float rotation_sign(const ProjectFn& project, Vec3 pivot, Vec3 u, Vec3 v);
// Accumulates the mouse angle without jumps: crossing +-180 keeps turning in the same direction.
struct AngleTracker {
    float last = 0, total = 0;
    void start(float angle) { last = angle; total = 0; }
    float update(float angle) { total += wrap_deg(angle - last); last = angle; return total; }
};
// Turns the euler rotation (pitch x, yaw y, roll z; R = Ry * Rx * Rz) by `deg` about its own LOCAL axis `axis`.
Vec3 rotate_local_euler(Vec3 euler, int axis, float deg);

// --------------------------------------------------------------------------------------------------------- scale
constexpr float kMinScaleFactor = 0.01f;
// Factor of a drag along an axis handle: how far the mouse is along the handle's screen direction now, relative to where it
// grabbed it. Never below kMinScaleFactor.
float scale_axis_factor(Vec2 pivot, Vec2 dir, Vec2 mouseStart, Vec2 mouseNow);
// Factor of the centre box: right and up grow, left and down shrink; `refPx` of travel doubles it.
float scale_uniform_factor(Vec2 mouseStart, Vec2 mouseNow, float refPx);
// start * factor, keeping start's sign. With `snapStep` the value snaps to it and stays at least one step away from 0.
float scale_apply(float start, float factor, float snapStep);

}  // namespace fa::editor
