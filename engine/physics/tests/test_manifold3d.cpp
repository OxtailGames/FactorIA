// 3D contact manifolds: the points a box-box, capsule-box or capsule-capsule contact is made of, and the ids that keep them
// recognisable from one sub-step to the next (the solver's warm start depends on them).
#include <doctest.h>

#include <algorithm>
#include <cmath>
#include <set>
#include <vector>

#include "../src/physics_internal.h"
#include "fa/physics/physics.h"

namespace fa::detail {

struct Physics3DTestAccess {
    using Body = Physics3D::Body;
    using Contact = Physics3D::Contact;
    static Contact collide(const Body& a, const Body& b) { return Physics3D::collide(a, b, 0.0f, true); }
};

}  // namespace fa::detail

using namespace fa;
using namespace fa::detail;
using Acc = Physics3DTestAccess;

namespace {

constexpr float kPiF = 3.14159265358979f;

void set_axes(Acc::Body& b, Vec3 x, Vec3 y, Vec3 z) {
    b.ax[0] = b.rot[0] = x;
    b.ax[1] = b.rot[1] = y;
    b.ax[2] = b.rot[2] = z;
}

// A box turned by `ax` degrees about X, then `ay` about Y, then `az` about Z (only the cases the tests need).
Acc::Body make_box(Vec3 centre, Vec3 half, float yaw = 0.0f, float roll = 0.0f, float pitch = 0.0f) {
    Acc::Body b;
    b.kind = Acc::Body::Kind::Box;
    b.hasShape = true;
    b.half = half;
    b.center = centre;
    const float ry = yaw * kPiF / 180.0f, rz = roll * kPiF / 180.0f, rx = pitch * kPiF / 180.0f;
    Vec3 x{1, 0, 0}, y{0, 1, 0}, z{0, 0, 1};
    auto about_x = [&](Vec3 v) { return Vec3{v.x, v.y * std::cos(rx) - v.z * std::sin(rx), v.y * std::sin(rx) + v.z * std::cos(rx)}; };
    auto about_y = [&](Vec3 v) { return Vec3{v.x * std::cos(ry) + v.z * std::sin(ry), v.y, -v.x * std::sin(ry) + v.z * std::cos(ry)}; };
    auto about_z = [&](Vec3 v) { return Vec3{v.x * std::cos(rz) - v.y * std::sin(rz), v.x * std::sin(rz) + v.y * std::cos(rz), v.z}; };
    auto turn = [&](Vec3 v) { return about_z(about_y(about_x(v))); };
    set_axes(b, turn(x), turn(y), turn(z));
    b.rotated = yaw != 0.0f || roll != 0.0f || pitch != 0.0f;
    return b;
}

// A capsule lying along X (its straight part runs from -segHalf to +segHalf).
Acc::Body make_capsule_along_x(Vec3 centre, float radius, float segHalf) {
    Acc::Body b;
    b.kind = Acc::Body::Kind::Capsule;
    b.hasShape = true;
    b.center = centre;
    b.radius = radius;
    b.segHalf = segHalf;
    b.half = {segHalf + radius, radius, radius};
    set_axes(b, {0, 1, 0}, {1, 0, 0}, {0, 0, -1});
    b.rotated = true;
    return b;
}

std::set<std::uint32_t> id_set(const Acc::Contact& c) {
    return std::set<std::uint32_t>(c.ids, c.ids + c.n);
}

}  // namespace

TEST_CASE("manifold3d: a box lying on a box touches in four points, one per corner of the overlap") {
    const Acc::Body floor = make_box({0, 0, 0}, {2, 0.5f, 2});
    const Acc::Body top = make_box({0.3f, 0.99f, -0.2f}, {0.5f, 0.5f, 0.5f});
    const Acc::Contact c = Acc::collide(floor, top);
    REQUIRE(c.hit);
    CHECK(c.n == 4);
    CHECK(c.normal.y > 0.999f);
    CHECK(id_set(c).size() == 4);
    for (int i = 0; i < c.n; ++i) {
        CHECK(c.depths[i] == doctest::Approx(0.01f).epsilon(0.05));
        CHECK(std::fabs(c.pts[i].x - 0.3f) == doctest::Approx(0.5f).epsilon(0.01));
        CHECK(std::fabs(c.pts[i].z + 0.2f) == doctest::Approx(0.5f).epsilon(0.01));
    }
}

TEST_CASE("manifold3d: a box turned 45 degrees on a box still gets four points, inside the face and on its plane") {
    const Acc::Body floor = make_box({0, 0, 0}, {2, 0.5f, 2});
    const Acc::Body top = make_box({0.1f, 0.99f, 0.0f}, {0.5f, 0.5f, 0.5f}, 45.0f);
    const Acc::Contact c = Acc::collide(floor, top);
    REQUIRE(c.hit);
    CHECK(c.n == 4);
    CHECK(c.normal.y > 0.999f);
    CHECK(id_set(c).size() == 4);
    // the four corners of the turned square lie on a circle of radius 0.5 * sqrt(2) around its centre
    for (int i = 0; i < c.n; ++i) {
        const float dx = c.pts[i].x - 0.1f, dz = c.pts[i].z;
        CHECK(std::sqrt(dx * dx + dz * dz) == doctest::Approx(0.5f * std::sqrt(2.0f)).epsilon(0.02));
        CHECK(c.depths[i] == doctest::Approx(0.01f).epsilon(0.1));
    }
    // the same pair again: the same points in the same order (the choice depends on nothing but the geometry)
    const Acc::Contact again = Acc::collide(floor, top);
    REQUIRE(again.n == c.n);
    for (int i = 0; i < c.n; ++i) {
        CHECK(again.ids[i] == c.ids[i]);
        CHECK(again.pts[i] == c.pts[i]);
    }
}

TEST_CASE("manifold3d: two crossing edges touch in one point") {
    // A rests on an edge (turned 45 degrees about X: the edge runs along X); B hangs over it on an edge along Z.
    const float h = 0.5f * std::sqrt(2.0f);
    const Acc::Body a = make_box({0, 0, 0}, {0.5f, 0.5f, 0.5f}, 0.0f, 0.0f, 45.0f);
    const Acc::Body b = make_box({0.05f, 2.0f * h - 0.01f, 0.1f}, {0.5f, 0.5f, 0.5f}, 0.0f, 45.0f, 0.0f);
    const Acc::Contact c = Acc::collide(a, b);
    REQUIRE(c.hit);
    CHECK(c.n <= 1);
    CHECK(c.normal.y > 0.99f);
    CHECK(c.depth == doctest::Approx(0.01f).epsilon(0.1));
    CHECK(c.point.x == doctest::Approx(0.05f).epsilon(0.05));
    CHECK(std::fabs(c.point.z) < 0.01f);  // the edge of A runs along X at z = 0: that is where the edges cross
}

TEST_CASE("manifold3d: a capsule lying on a box touches in two points, one per end") {
    const Acc::Body floor = make_box({0, 0, 0}, {3, 0.5f, 3});
    const Acc::Body cap = make_capsule_along_x({0.2f, 0.74f, 0.1f}, 0.25f, 1.0f);
    const Acc::Contact c = Acc::collide(floor, cap);
    REQUIRE(c.hit);
    REQUIRE(c.n == 2);
    CHECK(c.normal.y > 0.999f);
    CHECK(id_set(c).size() == 2);
    CHECK(std::fabs(c.pts[0].x - c.pts[1].x) == doctest::Approx(2.0f).epsilon(0.01));
    for (int i = 0; i < 2; ++i) CHECK(c.depths[i] == doctest::Approx(0.01f).epsilon(0.1));
    // standing on its end it has no second point
    Acc::Body upright = make_capsule_along_x({0, 1.74f, 0}, 0.25f, 1.0f);
    set_axes(upright, {1, 0, 0}, {0, 1, 0}, {0, 0, 1});
    upright.center = {0, 1.74f, 0};
    CHECK(Acc::collide(floor, upright).n <= 1);
}

TEST_CASE("manifold3d: two parallel capsules touch in two points") {
    const Acc::Body low = make_capsule_along_x({0, 0, 0}, 0.25f, 1.0f);
    const Acc::Body high = make_capsule_along_x({0.1f, 0.49f, 0}, 0.25f, 1.0f);
    const Acc::Contact c = Acc::collide(low, high);
    REQUIRE(c.hit);
    CHECK(c.n == 2);
    CHECK(c.normal.y > 0.999f);
}

TEST_CASE("manifold3d: the ids of a sliding contact stay with their corner") {
    const Acc::Body floor = make_box({0, 0, 0}, {3, 0.5f, 3});
    for (const float yaw : {0.0f, 20.0f}) {  // aligned (exact path) and turned (SAT path)
        const Acc::Body before = make_box({0.0f, 0.99f, 0.0f}, {0.5f, 0.5f, 0.5f}, yaw);
        const Acc::Body after = make_box({0.04f, 0.9895f, -0.03f}, {0.5f, 0.5f, 0.5f}, yaw + (yaw != 0.0f ? 0.5f : 0.0f));
        const Acc::Contact c0 = Acc::collide(floor, before), c1 = Acc::collide(floor, after);
        REQUIRE(c0.n == 4);
        REQUIRE(c1.n == 4);
        CHECK(id_set(c0) == id_set(c1));
        for (int i = 0; i < 4; ++i) {  // each id is the same corner of the box: it moved by about the slide
            for (int k = 0; k < 4; ++k) {
                if (c0.ids[i] != c1.ids[k]) continue;
                CHECK(std::fabs(c1.pts[k].x - c0.pts[i].x) < 0.05f);
                CHECK(std::fabs(c1.pts[k].z - c0.pts[i].z) < 0.05f);
            }
        }
    }
}

TEST_CASE("manifold3d: swapping the two bodies gives the opposite normal and the same points") {
    const Acc::Body floor = make_box({0, 0, 0}, {2, 0.5f, 2});
    const Acc::Body top = make_box({0.1f, 0.99f, 0.0f}, {0.5f, 0.5f, 0.5f}, 30.0f);
    const Acc::Contact ab = Acc::collide(floor, top), ba = Acc::collide(top, floor);
    REQUIRE(ab.n == 4);
    REQUIRE(ba.n == 4);
    CHECK(ab.normal.y == doctest::Approx(-ba.normal.y));
    for (int i = 0; i < 4; ++i) {  // every point of one is a point of the other
        bool found = false;
        for (int k = 0; k < 4; ++k)
            if (length(ab.pts[i] - ba.pts[k]) < 0.02f) found = true;
        CHECK(found);
    }
}

// Over several steps: with a face contact of four points a box lying half over the edge of a slab is held flat (its centre
// is over the slab), where one point would let it pivot; and a turned box on a slab comes to rest lying on its face.
TEST_CASE("manifold3d: boxes resting on a slab keep lying flat over many steps") {
    World world;
    Physics physics;
    physics.init(PhysicsSettings{});
    Entity slab = world.create();
    world.get<Transform>(slab)->position = {0, -0.5f, 0};
    world.add<Collider3D>(slab).size = {4, 1, 4};
    Entity over = world.create();  // 0.4 m over the edge of the slab: its centre is 0.1 m inside
    world.get<Transform>(over)->position = {1.9f, 0.51f, 0};
    world.add<Collider3D>(over).size = {1, 1, 1};
    world.add<RigidBody3D>(over);
    Entity turned = world.create();
    world.get<Transform>(turned)->position = {-1.0f, 0.8f, 0};
    world.get<Transform>(turned)->rotation = {0, 45.0f, 0};
    world.add<Collider3D>(turned).size = {1, 1, 1};
    world.add<RigidBody3D>(turned);
    for (int i = 0; i < 180; ++i) {
        world.events().clear();
        physics.step(world, 1.0f / 60.0f);
        world.advance_clock(1.0f / 60.0f);
        world.flush();
    }
    for (const Entity e : {over, turned}) {
        const Vec3 r = world.get<Transform>(e)->rotation;
        CHECK(std::fabs(r.x) < 1.0f);
        CHECK(std::fabs(r.z) < 1.0f);
        CHECK(world.world_position(e).y == doctest::Approx(0.5f).epsilon(0.02));
    }
    CHECK(world.world_position(over).x == doctest::Approx(1.9f).epsilon(0.02));
}

// An edge of the incident face almost parallel to a side plane of the reference face and within the clipping tolerance of it
// (about a micrometre): the clip point must stay on that edge. Before, its parameter could fall outside [0, 1] and a point
// landed metres away from the face.
TEST_CASE("manifold3d: an incident edge a micrometre from a side plane never puts a point outside the faces") {
    const Acc::Body floor = make_box({0, 0, 0}, {2, 0.5f, 2});
    int checked = 0;
    for (const float yawRad : {-1e-5f, -3e-6f, -1e-6f, 1e-6f, 3e-6f, 1e-5f, 2e-4f}) {
        for (int step = -8; step <= 8; ++step) {
            const float edge = 2.0f - 0.5f + float(step) * 4e-7f;  // the outer edge of the top box sits at 2 + step * 4e-7
            for (const bool alongZ : {false, true}) {
                const Vec3 centre = alongZ ? Vec3{0.2f, 0.99f, edge} : Vec3{edge, 0.99f, 0.2f};
                const float yaw = yawRad * 180.0f / kPiF;
                const Acc::Body top = make_box(centre, {0.5f, 0.5f, 0.5f}, alongZ ? 90.0f + yaw : yaw);
                const Acc::Contact c = Acc::collide(floor, top);
                if (!c.hit || c.n == 0) continue;
                ++checked;
                CHECK(c.n <= 4);
                for (int i = 0; i < c.n; ++i) {  // inside the floor's face and inside the top box's footprint, with a tolerance
                    CHECK(std::fabs(c.pts[i].x) <= 2.0f + 1e-3f);
                    CHECK(std::fabs(c.pts[i].z) <= 2.0f + 1e-3f);
                    CHECK(std::fabs(c.pts[i].x - centre.x) <= 0.5f + 1e-3f);
                    CHECK(std::fabs(c.pts[i].z - centre.z) <= 0.5f + 1e-3f);
                }
            }
        }
    }
    CHECK(checked > 100);
}
