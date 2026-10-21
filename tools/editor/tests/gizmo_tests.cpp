// The gizmo math (gizmo_model.h): handle layout and hit testing, drag distances through an orthographic and a perspective
// projection, snapping, a child of a rotated and scaled parent, rotation across 180 degrees, euler composition, scale clamping.
// No window, renderer or ImGui: the projections are built here from the engine's own Mat4.
#include <cmath>

#include "doctest.h"
#include "gizmo_model.h"

using namespace fa;
using namespace fa::editor;

namespace {

// 2D camera: world y up, panel y down, `zoom` px per world unit, the origin at (400, 300).
ProjectFn ortho(float zoom = 2.0f) { return [zoom](Vec3 p) { return Vec2{400 + p.x * zoom, 300 - p.y * zoom}; }; }

// A perspective camera at (0, 0, 10) looking down -z, 800x600 panel.
ProjectFn perspective() {
    const Mat4 view = Mat4::look_at({0, 0, 10}, {0, 0, 0});
    const Mat4 vp = Mat4::perspective(60.0f, 800.0f / 600.0f, 0.1f, 100.0f, false) * view;
    return [vp](Vec3 p) {
        const Vec4 c = vp * Vec4{p, 1.0f};
        return Vec2{(c.x / c.w * 0.5f + 0.5f) * 800.0f, (1.0f - (c.y / c.w * 0.5f + 0.5f)) * 600.0f};
    };
}

bool near_v(Vec3 a, Vec3 b, float eps = 1e-3f) { return length(a - b) < eps; }

const GizmoShape* find_shape(const std::vector<GizmoShape>& shapes, GizmoKind kind, int axis) {
    for (const GizmoShape& s : shapes)
        if (s.handle.kind == kind && s.handle.axis == axis) return &s;
    return nullptr;
}

}  // namespace

TEST_CASE("gizmo: the layout has the handles of the mode, and Z only for a 3D view") {
    GizmoView v;
    v.project = ortho();
    GizmoFrame f;
    f.pivot = {10, 20, 0};
    CHECK(gizmo_layout(GizmoMode::Select, v, f).empty());
    auto move = gizmo_layout(GizmoMode::Move, v, f);
    CHECK(move.size() == 3);  // x, y, plane
    CHECK(find_shape(move, GizmoKind::MoveAxis, 2) == nullptr);
    CHECK(find_shape(move, GizmoKind::MovePlane, -1) != nullptr);
    auto rot = gizmo_layout(GizmoMode::Rotate, v, f);
    REQUIRE(rot.size() == 1);
    CHECK(rot[0].handle.axis == 2);
    CHECK(gizmo_layout(GizmoMode::Scale, v, f).size() == 3);  // x, y, all

    v.project = perspective();
    v.threeD = true;
    f.pivot = {0, 0, 0};
    CHECK(gizmo_layout(GizmoMode::Rotate, v, f).size() == 3);
    // z points at the camera: its arrow is foreshortened to nothing and left out; the other two stay.
    move = gizmo_layout(GizmoMode::Move, v, f);
    CHECK(find_shape(move, GizmoKind::MoveAxis, 0) != nullptr);
    CHECK(find_shape(move, GizmoKind::MoveAxis, 2) == nullptr);
    f.pivot = {3, 0, 0};  // off to the side the z axis shows
    move = gizmo_layout(GizmoMode::Move, v, f);
    CHECK(find_shape(move, GizmoKind::MoveAxis, 2) != nullptr);
}

TEST_CASE("gizmo: handles keep their pixel size whatever the zoom") {
    for (float zoom : {0.5f, 2.0f, 40.0f}) {
        GizmoView v;
        v.project = ortho(zoom);
        const auto shapes = gizmo_layout(GizmoMode::Move, v, GizmoFrame{});
        const GizmoShape* x = find_shape(shapes, GizmoKind::MoveAxis, 0);
        REQUIRE(x);
        CHECK(std::hypot(x->to.x - x->from.x, x->to.y - x->from.y) == doctest::Approx(v.armPx));
    }
}

TEST_CASE("gizmo: hit-test priority: the centre square beats the arms, a scale box beats its arm, the nearest line wins") {
    GizmoView v;
    v.project = ortho();
    GizmoFrame f;
    auto move = gizmo_layout(GizmoMode::Move, v, f);
    const Vec2 c = v.project(f.pivot);
    CHECK(gizmo_hit(move, {c.x + 2, c.y - 1}, 7).kind == GizmoKind::MovePlane);  // on the arms' start too
    CHECK(gizmo_hit(move, {c.x + 40, c.y + 2}, 7) == GizmoHandle{GizmoKind::MoveAxis, 0});
    CHECK(gizmo_hit(move, {c.x + 1, c.y - 40}, 7) == GizmoHandle{GizmoKind::MoveAxis, 1});  // world y is up on screen
    CHECK_FALSE(gizmo_hit(move, {c.x + 40, c.y + 40}, 7));
    auto scale = gizmo_layout(GizmoMode::Scale, v, f);
    CHECK(gizmo_hit(scale, {c.x + v.armPx + 3, c.y + 2}, 7) == GizmoHandle{GizmoKind::ScaleAxis, 0});
    CHECK(gizmo_hit(scale, {c.x + 3, c.y + 3}, 7).kind == GizmoKind::ScaleAll);
    // Two arms 9 px apart near the tip: the closer one wins.
    GizmoShape a, b;
    a.type = b.type = GizmoShape::Type::Arm;
    a.handle = {GizmoKind::MoveAxis, 0};
    b.handle = {GizmoKind::MoveAxis, 1};
    a.from = {0, 0}; a.to = {100, 0};
    b.from = {0, 9}; b.to = {100, 9};
    CHECK(gizmo_hit({a, b}, {50, 6}, 7).axis == 1);
    CHECK(gizmo_hit({a, b}, {50, 2}, 7).axis == 0);
    CHECK(gizmo_hit({a, b}, {50, 4.5f}, 7).axis == 0);  // a tie goes to the first (x before y)
}

TEST_CASE("gizmo: a ring is hit on its line, not inside it") {
    GizmoView v;
    v.project = ortho();
    const auto rot = gizmo_layout(GizmoMode::Rotate, v, GizmoFrame{});
    const Vec2 c = v.project({0, 0, 0});
    CHECK(gizmo_hit(rot, {c.x + v.ringPx, c.y}, 5).kind == GizmoKind::RotateAxis);
    CHECK(gizmo_hit(rot, {c.x + v.ringPx - 3, c.y}, 5).kind == GizmoKind::RotateAxis);
    CHECK_FALSE(gizmo_hit(rot, {c.x, c.y}, 5));
    for (const GizmoShape& s : rot) CHECK(gizmo_hit(rot, gizmo_grab_point(s), 5) == s.handle);
    // Every handle can be grabbed at its grab point, in 3D too.
    v.project = perspective();
    v.threeD = true;
    GizmoFrame f;
    f.pivot = {3, 0, 0};
    for (GizmoMode m : {GizmoMode::Move, GizmoMode::Rotate, GizmoMode::Scale})
        for (const GizmoShape& s : gizmo_layout(m, v, f)) {
            INFO(gizmo_handle_name(s.handle));
            const auto shapes = gizmo_layout(m, v, f);
            CHECK(gizmo_hit(shapes, gizmo_grab_point(s), 5).kind != GizmoKind::None);
        }
}

TEST_CASE("gizmo: an axis drag moves the entity by the world distance the mouse covered (ortho)") {
    const ProjectFn p = ortho(2.0f);
    // 40 px right at 2 px per unit: 20 units along x; a vertical drag does not move x.
    CHECK(axis_drag_distance(p, {0, 0, 0}, {1, 0, 0}, {500, 300}, {540, 300}) == doctest::Approx(20.0f));
    CHECK(axis_drag_distance(p, {0, 0, 0}, {1, 0, 0}, {500, 300}, {500, 380}) == doctest::Approx(0.0f));
    // y is up in the world, down on screen: 30 px up is +15 units.
    CHECK(axis_drag_distance(p, {0, 0, 0}, {0, 1, 0}, {500, 300}, {500, 270}) == doctest::Approx(15.0f));
}

TEST_CASE("gizmo: an axis drag follows the axis' own screen direction in perspective") {
    const ProjectFn p = perspective();
    const Vec3 pivot{0, 0, 0};
    const Vec2 a = p(pivot), one = p({1, 0, 0});
    const float pxPerUnit = one.x - a.x;
    REQUIRE(pxPerUnit > 10.0f);
    CHECK(axis_drag_distance(p, pivot, {1, 0, 0}, a, {a.x + 3 * pxPerUnit, a.y + 50}) == doctest::Approx(3.0f).epsilon(1e-3));
    // The z axis points at the camera: it projects to a point at the centre, nothing to drag along.
    CHECK(axis_drag_distance(p, pivot, {0, 0, 1}, a, {a.x + 100, a.y}) == doctest::Approx(0.0f).epsilon(1e-3));
    // An axis that shows: drag along its screen direction.
    const Vec3 off{4, 0, 0};
    const Vec2 b = p(off), bz = p(off + Vec3{0, 0, 1});
    const Vec2 d{bz.x - b.x, bz.y - b.y};
    CHECK(axis_drag_distance(p, off, {0, 0, 1}, b, {b.x + 2 * d.x, b.y + 2 * d.y}) == doctest::Approx(2.0f).epsilon(1e-3));
}

TEST_CASE("gizmo: ray_plane") {
    Vec3 hit;
    CHECK(ray_plane({0, 0, 10}, {0, 0, -1}, {0, 0, 2}, {0, 0, 1}, hit));
    CHECK(near_v(hit, {0, 0, 2}));
    CHECK_FALSE(ray_plane({0, 0, 10}, {1, 0, 0}, {0, 0, 2}, {0, 0, 1}, hit));   // parallel
    CHECK_FALSE(ray_plane({0, 0, 10}, {0, 0, 1}, {0, 0, 2}, {0, 0, 1}, hit));   // behind the origin
}

TEST_CASE("gizmo: Ctrl snaps the value, not the delta") {
    CHECK(snap_to(7.4f, 1.0f) == 7.0f);
    CHECK(snap_to(7.6f, 1.0f) == 8.0f);
    CHECK(snap_to(0.37f, 0.25f) == doctest::Approx(0.25f));
    CHECK(snap_to(-0.4f, 0.25f) == doctest::Approx(-0.5f));
    CHECK(snap_to(3.3f, 0.0f) == 3.3f);
    // An entity that started at 2.3 and dragged 4.4 along x lands on 7 (the value 6.7 snapped), not on 2.3 + 4 = 6.3.
    const Vec3 start{2.3f, 5.5f, 0};
    const Vec3 s = snap_move(start, {6.7f, 5.5f, 0}, 1.0f);
    CHECK(s.x == 7.0f);
    CHECK(s.y == 5.5f);  // an axis that did not move keeps its (unsnapped) value
}

TEST_CASE("gizmo: a child of a rotated and scaled parent ends where the mouse put it in world space") {
    const Mat4 parent = Mat4::trs({100, 50, 0}, {0, 0, 30}, {2, 3, 1});
    const Vec3 childLocal{10, -4, 0};
    const Vec3 startWorld = parent.transform_point(childLocal);
    const ProjectFn p = ortho(1.5f);
    // Drag along world x by 25 units and then check the local value maps back to exactly that world position.
    const float t = axis_drag_distance(p, startWorld, {1, 0, 0}, {0, 0}, {37.5f, 0});
    CHECK(t == doctest::Approx(25.0f));
    const Vec3 targetWorld = startWorld + Vec3{t, 0, 0};
    const Vec3 local = world_to_local_position(parent, targetWorld);
    CHECK(near_v(parent.transform_point(local), targetWorld));
    CHECK_FALSE(near_v(local, childLocal + Vec3{t, 0, 0}));  // not the naive "add the delta to the local value"
    // No parent: identity.
    CHECK(near_v(world_to_local_position(Mat4::identity(), {1, 2, 3}), {1, 2, 3}));
}

TEST_CASE("gizmo: rotation sign matches the screen: counter-clockwise in a y-up world, clockwise in a y-down HUD") {
    const ProjectFn world = ortho();
    CHECK(rotation_sign(world, {0, 0, 0}, {1, 0, 0}, {0, 1, 0}) == -1.0f);
    const ProjectFn hud = [](Vec3 p) { return Vec2{p.x, p.y}; };
    CHECK(rotation_sign(hud, {0, 0, 0}, {1, 0, 0}, {0, 1, 0}) == 1.0f);
    // Mouse straight above the pivot (screen angle -90) to the right of it (0): +90 on screen = clockwise = -90 about world z.
    const float a0 = mouse_angle_deg({100, 100}, {100, 50}), a1 = mouse_angle_deg({100, 100}, {150, 100});
    CHECK(a1 - a0 == doctest::Approx(90.0f));
    CHECK(rotation_sign(world, {0, 0, 0}, {1, 0, 0}, {0, 1, 0}) * (a1 - a0) == doctest::Approx(-90.0f));
}

TEST_CASE("gizmo: dragging the mouse across +-180 keeps turning") {
    AngleTracker t;
    t.start(170.0f);
    CHECK(t.update(179.0f) == doctest::Approx(9.0f));
    CHECK(t.update(-175.0f) == doctest::Approx(15.0f));  // not -345
    CHECK(t.update(-160.0f) == doctest::Approx(30.0f));
    // and back the other way
    CHECK(t.update(-175.0f) == doctest::Approx(15.0f));
    CHECK(t.update(175.0f) == doctest::Approx(5.0f));
    CHECK(wrap_deg(190.0f) == doctest::Approx(-170.0f));
    CHECK(wrap_deg(-180.0f) == doctest::Approx(180.0f));
    // roll keeps turning past 180: the value is not wrapped back.
    CHECK(rotate_local_euler({0, 0, 170}, 2, 25.0f).z == doctest::Approx(195.0f));
}

TEST_CASE("gizmo: rotating about local axes and reading the euler back is a round trip") {
    const Vec3 start{20, 35, -10};
    for (int axis = 0; axis < 3; ++axis) {
        const Vec3 turned = rotate_local_euler(start, axis, 40.0f);
        // Reference: the same turn as matrices, R * R_axis(40).
        const Mat4 want = Mat4::rotate_euler_deg(start) * (axis == 0 ? Mat4::rotate_x_deg(40) : axis == 1 ? Mat4::rotate_y_deg(40) : Mat4::rotate_z_deg(40));
        const Mat4 got = Mat4::rotate_euler_deg(turned);
        for (int i = 0; i < 16; ++i) CHECK(got.m[i] == doctest::Approx(want.m[i]).epsilon(1e-4));
        // and back
        const Vec3 back = rotate_local_euler(turned, axis, -40.0f);
        const Mat4 b = Mat4::rotate_euler_deg(back), s = Mat4::rotate_euler_deg(start);
        for (int i = 0; i < 16; ++i) CHECK(b.m[i] == doctest::Approx(s.m[i]).epsilon(1e-4));
    }
    // 2D: a plain roll.
    CHECK(near_v(rotate_local_euler({0, 0, 10}, 2, 15.0f), {0, 0, 25}));
    CHECK(snap_to(23.0f, 15.0f) == 30.0f);
}

TEST_CASE("gizmo: scale never reaches 0 or flips sign by accident") {
    CHECK(scale_axis_factor({0, 0}, {1, 0}, {80, 0}, {160, 0}) == doctest::Approx(2.0f));
    CHECK(scale_axis_factor({0, 0}, {1, 0}, {80, 0}, {-400, 0}) == kMinScaleFactor);  // dragged through the pivot and beyond
    CHECK(scale_axis_factor({0, 0}, {1, 0}, {80, 0}, {0, 0}) == kMinScaleFactor);
    CHECK(scale_axis_factor({0, 0}, {1, 0}, {0.2f, 0}, {50, 0}) == 1.0f);  // grabbed on the pivot: no division by ~0
    CHECK(scale_apply(2.0f, kMinScaleFactor, 0) == doctest::Approx(0.02f));
    CHECK(scale_apply(-2.0f, 1.5f, 0) == doctest::Approx(-3.0f));         // a mirrored entity stays mirrored
    CHECK(scale_apply(-2.0f, 0.0f, 0) < 0.0f);
    CHECK(scale_apply(0.0f, 3.0f, 0) == 0.0f);                              // nothing to scale
    CHECK(scale_apply(1.0f, 1.37f, 0.1f) == doctest::Approx(1.4f));         // Ctrl snaps to 0.1
    CHECK(scale_apply(1.0f, 0.01f, 0.1f) == doctest::Approx(0.1f));         // ...and never to 0
    CHECK(scale_uniform_factor({0, 0}, {80, 0}, 80.0f) == doctest::Approx(2.0f));
    CHECK(scale_uniform_factor({0, 0}, {0, 80}, 80.0f) == kMinScaleFactor);  // down shrinks, held at the minimum
    CHECK(scale_uniform_factor({0, 0}, {40, -40}, 80.0f) == doctest::Approx(2.0f));
}
