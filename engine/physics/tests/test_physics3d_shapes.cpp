// 3D capsule, convex and triangle-mesh colliders, joints and the character controller.
#include <doctest.h>

#include <algorithm>
#include <chrono>
#include <cmath>
#include <cstring>
#include <fstream>
#include <string>

#include "fa/core/fs.h"
#include "fa/physics/physics.h"

using namespace fa;

namespace {

constexpr float kDt = 1.0f / 60.0f;
constexpr float kPiF = 3.14159265358979f;

struct Sim {
    World world;
    Physics physics;
    std::vector<CollisionEvent> events;
    Sim() { physics.init(PhysicsSettings{}); }
    void run(int steps) {
        for (int i = 0; i < steps; ++i) {
            world.events().clear();
            physics.step(world, kDt);
            for (const CollisionEvent& e : world.events().collisions) events.push_back(e);
            world.advance_clock(kDt);
            world.flush();
        }
    }
    int count(CollisionEvent::Phase ph, bool trigger) const {
        int n = 0;
        for (const auto& e : events) if (e.phase == ph && e.trigger == trigger) ++n;
        return n;
    }
};

enum class Kind { Box, Sphere, Capsule, Convex, Mesh };

// A collider of the given kind with a 1 m footprint on every axis it has one (box 1 m, sphere / capsule radius 0.5, the
// "cube" model for convex and mesh), so every pair touches at 1 m between the centres.
Entity add_shape(World& w, const char* id, Vec3 pos, Kind kind, Vec3 scale = {1, 1, 1}) {
    Entity e = w.create(id, id);
    Transform* t = w.get<Transform>(e);
    t->position = pos;
    t->scale = scale;
    Collider3D& c = w.add<Collider3D>(e);
    switch (kind) {
        case Kind::Box: c.shape = ColliderShape3D::Box; c.size = {1, 1, 1}; break;
        case Kind::Sphere: c.shape = ColliderShape3D::Sphere; c.radius = 0.5f; break;
        case Kind::Capsule: c.shape = ColliderShape3D::Capsule; c.radius = 0.5f; c.height = 2.0f; break;
        case Kind::Convex: c.shape = ColliderShape3D::Convex; c.mesh = "cube"; break;
        case Kind::Mesh: c.shape = ColliderShape3D::Mesh; c.mesh = "cube"; break;
    }
    return e;
}
RigidBody3D& make_body(World& w, Entity e, BodyType type = BodyType::Dynamic) {
    RigidBody3D& rb = w.add<RigidBody3D>(e);
    rb.type = type;
    return rb;
}
Vec3 pos_of(const World& w, Entity e) { return w.world_position(e); }
Vec3 local_y(const World& w, Entity e) {
    const Mat4 m = w.world_matrix(e);
    return normalize(Vec3{m.at(1, 0), m.at(1, 1), m.at(1, 2)});
}

Vec3 local_x(const World& w, Entity e) {
    const Mat4 m = w.world_matrix(e);
    return normalize(Vec3{m.at(0, 0), m.at(0, 1), m.at(0, 2)});
}

const char* kind_name(Kind k) {
    switch (k) {
        case Kind::Box: return "box";
        case Kind::Sphere: return "sphere";
        case Kind::Capsule: return "capsule";
        case Kind::Convex: return "convex";
        default: return "mesh";
    }
}

}  // namespace

TEST_CASE("3d shapes: every pair of shapes touches, overlaps and separates correctly") {
    const Kind kinds[] = {Kind::Box, Kind::Sphere, Kind::Capsule, Kind::Convex, Kind::Mesh};
    for (Kind ka : kinds) {
        for (Kind kb : kinds) {
            if (ka == Kind::Mesh && kb == Kind::Mesh) continue;  // two static colliders never meet
            CAPTURE(kind_name(ka));
            CAPTURE(kind_name(kb));
            for (float gap : {0.02f, -0.1f, 0.3f}) {
                CAPTURE(gap);
                Sim s;
                Entity a = add_shape(s.world, "a", {0, 0, 0}, ka);
                Entity b = add_shape(s.world, "b", {1.0f + gap, 0, 0}, kb);
                s.physics.sync(s.world);
                if (gap == 0.02f) {
                    CHECK(s.physics.is_touching3d(s.world, a, {1, 0, 0}, 0.05f));
                    CHECK(s.physics.is_touching3d(s.world, b, {-1, 0, 0}, 0.05f));
                    CHECK_FALSE(s.physics.is_touching3d(s.world, a, {1, 0, 0}, 0.005f));
                    CHECK_FALSE(s.physics.is_touching3d(s.world, a, {-1, 0, 0}, 0.05f));  // wrong side
                } else if (gap < 0.0f) {
                    CHECK(s.physics.is_touching3d(s.world, a, {1, 0, 0}, 0.005f));
                    CHECK(s.physics.is_touching3d(s.world, b, {-1, 0, 0}, 0.005f));
                } else {
                    CHECK_FALSE(s.physics.is_touching3d(s.world, a, {1, 0, 0}, 0.05f));
                }
                (void)b;
            }
        }
    }
}

TEST_CASE("3d shapes: boxes, spheres, capsules and hulls land on box, convex and mesh floors and rest") {
    struct Floor { Kind kind; const char* name; };
    const Floor floors[] = {{Kind::Box, "box floor"}, {Kind::Convex, "convex floor"}, {Kind::Mesh, "mesh floor"}};
    struct Faller { Kind kind; float restY; };
    const Faller fallers[] = {{Kind::Box, 0.5f}, {Kind::Sphere, 0.5f}, {Kind::Capsule, 1.0f}, {Kind::Convex, 0.5f}};
    for (const Floor& f : floors) {
        for (const Faller& fl : fallers) {
            CAPTURE(f.name);
            CAPTURE(kind_name(fl.kind));
            Sim s;
            add_shape(s.world, "floor", {0, -0.5f, 0}, f.kind, {20, 1, 20});
            Entity e = add_shape(s.world, "body", {0.1f, 3, 0.05f}, fl.kind);
            make_body(s.world, e);
            s.run(240);
            const Vec3 p = pos_of(s.world, e);
            CHECK(p.y == doctest::Approx(fl.restY).epsilon(0.03));
            CHECK(std::fabs(p.x - 0.1f) < 0.3f);
            CHECK(std::fabs(s.world.get<RigidBody3D>(e)->velocity.y) < 0.1f);
        }
    }
}

TEST_CASE("3d shapes: a tilted rigid capsule falls over and lies flat on a mesh floor, resting on both ends") {
    Sim s;
    add_shape(s.world, "floor", {0, -0.5f, 0}, Kind::Mesh, {20, 1, 20});
    Entity cap = add_shape(s.world, "cap", {0, 2, 0}, Kind::Capsule);
    s.world.get<Transform>(cap)->rotation = {0, 0, 35};
    make_body(s.world, cap);
    s.run(360);
    CHECK(std::fabs(local_y(s.world, cap).y) < 0.08f);  // lying on its side
    CHECK(pos_of(s.world, cap).y == doctest::Approx(0.5f).epsilon(0.05));
    s.run(120);
    Json state = s.physics.debug_state(s.world);
    bool awake = true;
    for (const Json& b : state) if (b["entity"] == "cap") awake = b["awake"].get<bool>();
    CHECK_FALSE(awake);  // it fell asleep: the two-point contact is steady
}

TEST_CASE("3d shapes: raycast hits capsules, convex hulls and meshes with the right distance and normal") {
    Sim s;
    Entity cap = add_shape(s.world, "cap", {0, 0, 0}, Kind::Capsule);
    Entity hull = add_shape(s.world, "hull", {10, 0, 0}, Kind::Convex);
    Entity mesh = add_shape(s.world, "mesh", {0, 0, 20}, Kind::Mesh, {2, 1, 2});
    s.physics.sync(s.world);
    auto side = s.physics.raycast3d(s.world, {-5, 0.2f, 0}, {1, 0, 0}, 100);
    REQUIRE(side);
    CHECK(side->entity == cap);
    CHECK(side->distance == doctest::Approx(4.5f).epsilon(0.002));  // the straight part
    CHECK(side->normal.x < -0.99f);
    auto cap_round = s.physics.raycast3d(s.world, {-5, 0.9f, 0}, {1, 0, 0}, 100);  // 0.4 above the cap's centre: x = -0.3
    REQUIRE(cap_round);
    CHECK(cap_round->distance == doctest::Approx(4.7f).epsilon(0.003));
    auto tip = s.physics.raycast3d(s.world, {0, 5, 0}, {0, -1, 0}, 100);
    REQUIRE(tip);
    CHECK(tip->distance == doctest::Approx(4.0f).epsilon(0.002));
    CHECK(tip->normal.y > 0.99f);
    auto h = s.physics.raycast3d(s.world, {5, 0.1f, 0.2f}, {1, 0, 0}, 100);
    REQUIRE(h);
    CHECK(h->entity == hull);
    CHECK(h->distance == doctest::Approx(4.5f).epsilon(0.002));
    CHECK(h->normal.x < -0.99f);
    auto m = s.physics.raycast3d(s.world, {0.3f, 5, 20.4f}, {0, -1, 0}, 100);
    REQUIRE(m);
    CHECK(m->entity == mesh);
    CHECK(m->distance == doctest::Approx(4.5f).epsilon(0.002));
    CHECK(m->normal.y > 0.99f);
    auto side2 = s.physics.raycast3d(s.world, {-5, 0.2f, 20.3f}, {1, 0, 0}, 100);
    REQUIRE(side2);
    CHECK(side2->distance == doctest::Approx(4.0f).epsilon(0.002));  // the mesh is 2 m wide (scale 2)
    CHECK(side2->normal.x < -0.99f);
    CHECK_FALSE(s.physics.raycast3d(s.world, {-5, 0.2f, 0}, {1, 0, 0}, 4.0f));  // too short
    // a ray starting inside a capsule or hull skips it, like every other shape
    auto inside = s.physics.raycast3d(s.world, {0, 0, 0}, {1, 0, 0}, 100);
    REQUIRE(inside);
    CHECK(inside->entity == hull);
}

TEST_CASE("3d shapes: overlap_sphere3d, shape_cast3d and is_touching3d see capsules, hulls and meshes") {
    Sim s;
    Entity cap = add_shape(s.world, "cap", {0, 0, 0}, Kind::Capsule);
    Entity hull = add_shape(s.world, "hull", {10, 0, 0}, Kind::Convex);
    Entity mesh = add_shape(s.world, "mesh", {0, 0, 20}, Kind::Mesh, {2, 1, 2});
    s.physics.sync(s.world);
    auto at = [&](Vec3 c, float r) { return s.physics.overlap_sphere3d(s.world, c, r); };
    CHECK(at({0, 0.9f, 0}, 0.3f) == std::vector<Entity>{cap});      // over the capsule's cap
    CHECK(at({0, 1.6f, 0}, 0.3f).empty());
    CHECK(at({10.7f, 0, 0}, 0.3f) == std::vector<Entity>{hull});
    CHECK(at({0, 0.6f, 20}, 0.2f) == std::vector<Entity>{mesh});
    CHECK(at({0, 1.5f, 20}, 0.2f).empty());
    CastShape ball;
    ball.kind = CastShape::Kind::Circle;
    ball.radius = 0.25f;
    auto hit = s.physics.shape_cast3d(s.world, ball, {-5, 0, 0}, {5, 0, 0});
    REQUIRE(hit);
    CHECK(hit->entity == cap);
    CHECK(hit->distance == doctest::Approx(5.0f - 0.75f).epsilon(0.002));
    CHECK(hit->normal.x < -0.99f);
    CastShape box;
    box.kind = CastShape::Kind::Box;
    box.size = {1, 1, 1};
    auto down = s.physics.shape_cast3d(s.world, box, {0.3f, 5, 20}, {0.3f, -5, 20});
    REQUIRE(down);
    CHECK(down->entity == mesh);
    CHECK(down->distance == doctest::Approx(5.0f - 0.5f - 0.5f).epsilon(0.002));
    CHECK(down->normal.y > 0.99f);
    auto toHull = s.physics.shape_cast3d(s.world, ball, {10, 5, 0}, {10, -5, 0});
    REQUIRE(toHull);
    CHECK(toHull->entity == hull);
    CHECK(toHull->distance == doctest::Approx(5.0f - 0.5f - 0.25f).epsilon(0.002));
}

TEST_CASE("3d shapes: a mesh collider on a dynamic or kinematic body is a teaching error, and ignored") {
    Sim s;
    Entity floor = add_shape(s.world, "floor", {0, -0.5f, 0}, Kind::Box, {20, 1, 20});
    (void)floor;
    Entity dyn = add_shape(s.world, "dyn", {0, 3, 0}, Kind::Mesh);
    make_body(s.world, dyn);
    Entity kin = add_shape(s.world, "kin", {3, 3, 0}, Kind::Mesh);
    make_body(s.world, kin, BodyType::Kinematic);
    Entity okStatic = add_shape(s.world, "okstatic", {6, 0.5f, 0}, Kind::Mesh);
    make_body(s.world, okStatic, BodyType::Static);
    s.run(2);
    auto problems = s.physics.problems3d();
    REQUIRE(problems.size() == 2);
    CHECK(problems[0].find("'dyn'") != std::string::npos);
    CHECK(problems[0].find("dynamic") != std::string::npos);
    CHECK(problems[0].find("convex") != std::string::npos);  // says what to use instead
    CHECK(problems[1].find("kinematic") != std::string::npos);
    Json state = s.physics.debug_state(s.world);
    int withProblem = 0;
    for (const Json& b : state) if (b.contains("problem")) ++withProblem;
    CHECK(withProblem == 2);
    s.run(60);  // the ignored bodies have no shape: the dynamic one falls through the floor
    CHECK(pos_of(s.world, dyn).y < -2.0f);
    CHECK(pos_of(s.world, okStatic).y == doctest::Approx(0.5f));
    // fixing the shape clears the error
    s.world.get<Collider3D>(dyn)->shape = ColliderShape3D::Convex;
    s.world.get<Transform>(dyn)->position = {0, 3, 0};
    s.run(2);
    CHECK(s.physics.problems3d().size() == 1);
}

TEST_CASE("3d shapes: convex and mesh colliders without a usable mesh say what is wrong") {
    Sim s;
    Entity none = add_shape(s.world, "nomesh", {0, 0, 0}, Kind::Convex);
    s.world.get<Collider3D>(none)->mesh.clear();
    Entity typo = add_shape(s.world, "typo", {3, 0, 0}, Kind::Mesh);
    s.world.get<Collider3D>(typo)->mesh = "cubee";
    Entity missing = add_shape(s.world, "missing", {6, 0, 0}, Kind::Convex);
    s.world.get<Collider3D>(missing)->mesh = "assets/models/not_there.glb";
    s.run(1);
    auto problems = s.physics.problems3d();
    REQUIRE(problems.size() == 3);
    CHECK(problems[0].find("has no `mesh`") != std::string::npos);
    CHECK(problems[1].find("Did you mean") != std::string::npos);
    CHECK(problems[1].find("cube") != std::string::npos);
    CHECK(problems[2].find("not_there.glb") != std::string::npos);
}

TEST_CASE("3d shapes: events, triggers and sleeping work with every new shape") {
    Sim s;
    add_shape(s.world, "floor", {0, -0.5f, 0}, Kind::Mesh, {20, 1, 20});
    Entity cap = add_shape(s.world, "cap", {0, 2, 0}, Kind::Capsule);
    make_body(s.world, cap).lockRotation = true;
    Entity zone = add_shape(s.world, "zone", {5, 1, 0}, Kind::Convex, {2, 2, 2});
    s.world.get<Collider3D>(zone)->isTrigger = true;
    Entity ball = add_shape(s.world, "ball", {5, 6, 0}, Kind::Sphere);
    make_body(s.world, ball);
    s.run(200);
    CHECK(s.count(CollisionEvent::Phase::Begin, false) >= 1);  // the capsule landed on the mesh
    CHECK(s.count(CollisionEvent::Phase::Begin, true) == 1);   // the ball entered the convex trigger
    s.world.get<Transform>(ball)->position = {20, 1, 0};       // taken out of it
    s.run(5);
    CHECK(s.count(CollisionEvent::Phase::End, true) == 1);
    s.run(120);
    Json state = s.physics.debug_state(s.world);
    for (const Json& b : state) {
        if (b["entity"] == "cap") CHECK_FALSE(b["awake"].get<bool>());
    }
}

TEST_CASE("3d shapes: continuous collision keeps a fast sphere and a fast capsule from passing a mesh wall") {
    int passed = 0;
    for (int trial = 0; trial < 60; ++trial) {
        Sim s;
        s.world.settings().gravity3D = {0, 0, 0};
        Entity wall = add_shape(s.world, "wall", {5, 0, 0}, Kind::Mesh, {0.1f, 6, 6});
        (void)wall;
        Entity ball = add_shape(s.world, "ball", {0, float(trial % 7) * 0.2f - 0.6f, 0}, trial % 2 ? Kind::Sphere : Kind::Capsule);
        make_body(s.world, ball).velocity = {70.0f + float(trial), 0, 0};
        s.run(30);
        if (pos_of(s.world, ball).x > 5.0f) ++passed;
    }
    CHECK(passed == 0);
}

TEST_CASE("3d shapes: a mesh ramp of thousands of triangles is fast to query") {
    // The sphere primitive has about 1 000 triangles; 20 of them are 20 000 triangles for the ball to roll over. The BVH keeps
    // each contact query to a handful of triangles.
    Sim s;
    for (int i = 0; i < 20; ++i) {
        Entity m = add_shape(s.world, ("m" + std::to_string(i)).c_str(), {float(i) * 1.9f, 0, 0}, Kind::Mesh);
        s.world.get<Collider3D>(m)->mesh = "sphere";
        s.world.get<Transform>(m)->scale = {2, 2, 2};
    }
    Entity ball = add_shape(s.world, "ball", {0, 3, 0}, Kind::Sphere);
    make_body(s.world, ball).velocity = {6, 0, 0};
    const auto t0 = std::chrono::steady_clock::now();
    s.run(120);
    const double ms = std::chrono::duration<double, std::milli>(std::chrono::steady_clock::now() - t0).count();
    CHECK(ms < 2000.0);  // 20 000 triangles; far under a frame budget per step
    CHECK(pos_of(s.world, ball).y > 0.6f);  // it rolled over the spheres, never fell into one
}

TEST_CASE("3d shapes: debug_shapes and debug_state report capsules, hulls and meshes") {
    Sim s;
    Entity cap = add_shape(s.world, "cap", {0, 0, 0}, Kind::Capsule);
    s.world.get<Transform>(cap)->rotation = {0, 0, 30};
    add_shape(s.world, "hull", {5, 0, 0}, Kind::Convex, {2, 1, 3});
    add_shape(s.world, "mesh", {10, 0, 0}, Kind::Mesh);
    s.run(1);
    auto shapes = s.physics.debug_shapes(s.world);
    REQUIRE(shapes.size() == 3);
    CHECK(shapes[0].kind == Physics::DebugShape::Capsule);
    CHECK(shapes[0].size.y == doctest::Approx(2.0f));
    CHECK(shapes[0].euler.z == doctest::Approx(30.0f).epsilon(0.01));
    CHECK(shapes[1].kind == Physics::DebugShape::Convex);
    CHECK(shapes[1].size.x == doctest::Approx(2.0f));
    CHECK(shapes[1].size.z == doctest::Approx(3.0f));
    CHECK(shapes[2].kind == Physics::DebugShape::Mesh);
    Json state = s.physics.debug_state(s.world);
    REQUIRE(state.size() == 3);
    CHECK(state[0]["shapes"][0]["kind"] == "capsule");
    CHECK(state[0]["shapes"][0]["height"].get<float>() == doctest::Approx(2.0f));
    CHECK(state[1]["shapes"][0]["kind"] == "convex");
    CHECK(state[2]["shapes"][0]["kind"] == "mesh");
    CHECK(state[2]["shapes"][0]["triangles"].get<int>() == 12);
}

TEST_CASE("3d shapes: two identical runs with every shape give bit-identical transforms") {
    auto run = [] {
        Sim s;
        add_shape(s.world, "floor", {0, -0.5f, 0}, Kind::Mesh, {30, 1, 30});
        std::vector<Entity> bodies;
        const Kind kinds[] = {Kind::Capsule, Kind::Convex, Kind::Box, Kind::Sphere, Kind::Capsule, Kind::Convex};
        for (int i = 0; i < 12; ++i) {
            Entity e = add_shape(s.world, ("b" + std::to_string(i)).c_str(), {float(i % 3) * 0.4f, 1.0f + float(i) * 1.1f, float(i % 2) * 0.3f},
                                 kinds[i % 6]);
            s.world.get<Transform>(e)->rotation = {float(i) * 11.0f, float(i) * 7.0f, float(i) * 13.0f};
            make_body(s.world, e);
            bodies.push_back(e);
        }
        s.run(400);
        std::vector<float> out;
        for (Entity e : bodies) {
            const Transform* t = s.world.get<Transform>(e);
            out.insert(out.end(), {t->position.x, t->position.y, t->position.z, t->rotation.x, t->rotation.y, t->rotation.z});
        }
        return out;
    };
    auto a = run(), b = run();
    REQUIRE(a.size() == b.size());
    CHECK(std::memcmp(a.data(), b.data(), a.size() * sizeof(float)) == 0);
    for (float v : a) CHECK(std::isfinite(v));
}

// ------------------------------------------------------------ ramp mesh ----

namespace {

std::string base64(const std::vector<std::uint8_t>& bytes) {
    static const char* table = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    std::string out;
    for (std::size_t i = 0; i < bytes.size(); i += 3) {
        const std::uint32_t v = (std::uint32_t(bytes[i]) << 16) | (i + 1 < bytes.size() ? std::uint32_t(bytes[i + 1]) << 8 : 0u) |
                                (i + 2 < bytes.size() ? std::uint32_t(bytes[i + 2]) : 0u);
        out += table[(v >> 18) & 63];
        out += table[(v >> 12) & 63];
        out += i + 1 < bytes.size() ? table[(v >> 6) & 63] : '=';
        out += i + 2 < bytes.size() ? table[v & 63] : '=';
    }
    return out;
}

// Writes <dir>/ramp.gltf: a nx x nz grid of quads rising along +X at `slopeDeg`, `length` x `width` metres, starting at
// x = 0, y = 0 (z centred). Triangles = 2 * nx * nz.
std::string gRampName = "ramp.gltf";  // unique per RampProject: the engine caches loaded meshes by name

void write_ramp_gltf(const std::filesystem::path& dir, int nx, int nz, float length, float width, float slopeDeg) {
    std::vector<float> pos;
    for (int j = 0; j <= nz; ++j)
        for (int i = 0; i <= nx; ++i) {
            const float x = length * float(i) / float(nx), z = width * (float(j) / float(nz) - 0.5f);
            pos.insert(pos.end(), {x, x * std::tan(slopeDeg * kPiF / 180.0f), z});
        }
    std::vector<std::uint32_t> idx;
    for (int j = 0; j < nz; ++j)
        for (int i = 0; i < nx; ++i) {
            const std::uint32_t a = std::uint32_t(j * (nx + 1) + i), b = a + 1, c = a + std::uint32_t(nx + 1), d = c + 1;
            idx.insert(idx.end(), {a, c, b, b, c, d});
        }
    std::vector<std::uint8_t> bytes(idx.size() * 4 + pos.size() * 4);
    std::memcpy(bytes.data(), idx.data(), idx.size() * 4);
    std::memcpy(bytes.data() + idx.size() * 4, pos.data(), pos.size() * 4);
    const std::string json =
        R"({"asset":{"version":"2.0"},"scene":0,"scenes":[{"nodes":[0]}],"nodes":[{"mesh":0}],)"
        R"("meshes":[{"primitives":[{"attributes":{"POSITION":1},"indices":0}]}],)"
        R"("buffers":[{"uri":"data:application/octet-stream;base64,)" + base64(bytes) + R"(","byteLength":)" +
        std::to_string(bytes.size()) + R"(}],)"
        R"("bufferViews":[{"buffer":0,"byteOffset":0,"byteLength":)" + std::to_string(idx.size() * 4) + R"(},)"
        R"({"buffer":0,"byteOffset":)" + std::to_string(idx.size() * 4) + R"(,"byteLength":)" + std::to_string(pos.size() * 4) + R"(}],)"
        R"("accessors":[{"bufferView":0,"componentType":5125,"count":)" + std::to_string(idx.size()) + R"(,"type":"SCALAR"},)"
        R"({"bufferView":1,"componentType":5126,"count":)" + std::to_string(pos.size() / 3) + R"(,"type":"VEC3"}]})";
    std::ofstream(dir / gRampName, std::ios::binary) << json;
}

struct RampProject {
    std::filesystem::path dir, oldRoot;
    explicit RampProject(int nx, int nz, float length, float width, float slopeDeg) {
        static int counter = 0;
        gRampName = "ramp" + std::to_string(++counter) + ".gltf";
        oldRoot = fs::project_root();
        dir = fs::make_temp_dir("fa_test_ramp");
        fs::set_project_root(dir);
        write_ramp_gltf(dir, nx, nz, length, width, slopeDeg);
    }
    ~RampProject() {
        fs::set_project_root(oldRoot);
        std::error_code ec;
        std::filesystem::remove_all(dir, ec);
    }
};

Entity add_gltf_ramp(World& w) {
    Entity r = w.create("ramp", "ramp");
    Collider3D& c = w.add<Collider3D>(r);
    c.shape = ColliderShape3D::Mesh;
    c.mesh = gRampName;
    return r;
}

Entity add_flat_floor(World& w) {
    Entity f = w.create("floor", "floor");
    w.get<Transform>(f)->position = {-5, -0.5f, 0};
    Collider3D& c = w.add<Collider3D>(f);
    c.size = {10, 1, 10};
    return f;
}

}  // namespace

TEST_CASE("3d shapes: a glTF mesh collider loads, raycasts and reports its triangle count") {
    RampProject project(80, 40, 12.0f, 6.0f, 20.0f);
    Sim s;
    Entity ramp = add_gltf_ramp(s.world);
    s.physics.sync(s.world);
    Json state = s.physics.debug_state(s.world);
    REQUIRE(state.size() == 1);
    CHECK(state[0]["shapes"][0]["triangles"].get<int>() == 6400);
    auto hit = s.physics.raycast3d(s.world, {6, 10, 0.3f}, {0, -1, 0}, 50);
    REQUIRE(hit);
    CHECK(hit->entity == ramp);
    CHECK(hit->point.y == doctest::Approx(6.0f * std::tan(20.0f * kPiF / 180.0f)).epsilon(0.003));
    CHECK(hit->normal.y == doctest::Approx(std::cos(20.0f * kPiF / 180.0f)).epsilon(0.003));
    CHECK(s.physics.problems3d().empty());
}

// ------------------------------------------------- character controller ----

namespace {

Entity add_character(World& w, Vec3 pos, const char* id = "hero") {
    Entity e = w.create(id, id);
    w.get<Transform>(e)->position = pos;
    w.add<CharacterController3D>(e);
    return e;
}

Entity add_big_floor(World& w) {
    Entity f = w.create("bigfloor", "bigfloor");
    w.get<Transform>(f)->position = {0, -0.5f, 0};
    w.add<Collider3D>(f).size = {40, 1, 40};
    return f;
}

// One "frame" of a script: walk by `velocity` (m/s, horizontal) plus simple gravity while airborne, then step the physics.
struct Walker {
    Sim& sim;
    Entity e;
    float vy = 0.0f;
    bool grounded = false;
    int airborneFrames = 0;
    CharacterMoveResult last;
    void frame(Vec3 velocity) {
        const Vec3 delta = Vec3{velocity.x, vy, velocity.z} * kDt;
        auto r = sim.physics.move_character(sim.world, e, delta);
        REQUIRE(r.has_value());
        last = *r;
        grounded = r->isGrounded;
        if (!grounded) ++airborneFrames;
        vy = grounded ? -0.5f : vy - 9.81f * kDt;
        sim.run(1);
    }
    void walk(Vec3 velocity, int frames) {
        for (int i = 0; i < frames; ++i) frame(velocity);
    }
};

}  // namespace

TEST_CASE("3d character: falls onto the ground, stands a skin above it, walks, reports isGrounded and the ground") {
    Sim s;
    Entity floor = add_big_floor(s.world);
    Entity hero = add_character(s.world, {0, 1.5f, 0});
    Walker w{s, hero};
    w.walk({0, 0, 0}, 60);
    CHECK(w.grounded);
    CHECK(w.last.ground == floor);
    CHECK(w.last.groundNormal.y > 0.99f);
    CHECK(pos_of(s.world, hero).y == doctest::Approx(0.9f + 0.02f).epsilon(0.03));
    CHECK(s.world.get<CharacterController3D>(hero)->isGrounded);
    w.walk({2, 0, 0}, 60);
    CHECK(pos_of(s.world, hero).x == doctest::Approx(2.0f).epsilon(0.03));
    CHECK(w.grounded);
    Entity plain = s.world.create("plain", "plain");
    CHECK_FALSE(s.physics.move_character(s.world, plain, {1, 0, 0}).has_value());
}

TEST_CASE("3d character: slides along a wall, stops at a head-on wall, bumps its head") {
    Sim s;
    add_big_floor(s.world);
    Entity wall = s.world.create("wall", "wall");
    s.world.get<Transform>(wall)->position = {3, 2, 0};
    s.world.add<Collider3D>(wall).size = {1, 4, 20};
    Entity roof = s.world.create("roof", "roof");
    s.world.get<Transform>(roof)->position = {-6, 2.6f, 0};
    s.world.add<Collider3D>(roof).size = {6, 1, 6};
    Entity hero = add_character(s.world, {0, 1.0f, 0});
    Walker w{s, hero};
    w.walk({0, 0, 0}, 30);
    w.walk({4, 0, 0}, 120);
    CHECK(pos_of(s.world, hero).x == doctest::Approx(3.0f - 0.5f - 0.4f - 0.02f).epsilon(0.02));
    CHECK(w.last.hitWall);
    const float z0 = pos_of(s.world, hero).z;
    w.walk({3, 0, 3}, 60);
    CHECK(pos_of(s.world, hero).x < 2.2f);
    CHECK(pos_of(s.world, hero).z - z0 == doctest::Approx(3.0f).epsilon(0.05));
    s.world.get<Transform>(hero)->position = {-6, 1.0f, 0};
    w.vy = 0;
    w.walk({0, 0, 0}, 30);
    auto jump = s.physics.move_character(s.world, hero, {0, 1.0f, 0});
    REQUIRE(jump);
    CHECK(jump->hitCeiling);
    CHECK(pos_of(s.world, hero).y + 0.9f <= 2.1f);
}

TEST_CASE("3d character: climbs a step up to stepOffset and is stopped by a higher one") {
    for (float height : {0.25f, 0.5f}) {
        CAPTURE(height);
        Sim s;
        add_big_floor(s.world);
        Entity step = s.world.create("step", "step");
        s.world.get<Transform>(step)->position = {4, height * 0.5f, 0};
        s.world.add<Collider3D>(step).size = {4, height, 10};
        Entity hero = add_character(s.world, {0, 1.0f, 0});
        Walker w{s, hero};
        w.walk({0, 0, 0}, 30);
        w.walk({2, 0, 0}, 150);
        if (height < 0.3f) {
            CHECK(pos_of(s.world, hero).x > 4.0f);
            CHECK(pos_of(s.world, hero).y == doctest::Approx(height + 0.9f + 0.02f).epsilon(0.05));
            CHECK(w.grounded);
        } else {
            CHECK(pos_of(s.world, hero).x < 2.0f - 0.4f + 0.05f);
            CHECK(pos_of(s.world, hero).y == doctest::Approx(0.92f).epsilon(0.05));
        }
    }
}

TEST_CASE("3d character: walks up a 6400-triangle glTF mesh ramp, stays grounded and snaps down it again") {
    RampProject project(80, 40, 12.0f, 6.0f, 20.0f);
    Sim s;
    add_flat_floor(s.world);
    add_gltf_ramp(s.world);
    Entity hero = add_character(s.world, {-3, 1.2f, 0});
    Walker w{s, hero};
    w.walk({0, 0, 0}, 45);
    REQUIRE(w.grounded);
    const auto t0 = std::chrono::steady_clock::now();
    w.walk({3, 0, 0}, 180);
    const double ms = std::chrono::duration<double, std::milli>(std::chrono::steady_clock::now() - t0).count();
    const Vec3 p = pos_of(s.world, hero);
    const float tan20 = std::tan(20.0f * kPiF / 180.0f);
    CHECK(p.x > 5.5f);
    CHECK(p.x < 6.05f);
    CHECK(p.y > p.x * tan20 + 0.8f);
    CHECK(p.y < p.x * tan20 + 1.4f);
    CHECK(std::fabs(p.z) < 0.01f);
    CHECK(w.grounded);
    CHECK(w.last.groundNormal.y == doctest::Approx(std::cos(20.0f * kPiF / 180.0f)).epsilon(0.02));
    CHECK(w.last.groundNormal.x < -0.3f);
    CHECK(ms < 3000.0);
    w.airborneFrames = 0;
    w.walk({-3, 0, 0}, 150);
    CHECK(pos_of(s.world, hero).x < 2.0f);
    CHECK(w.airborneFrames <= 3);
}

TEST_CASE("3d character: will not climb a slope steeper than slopeLimit, climbs a gentler one") {
    float heightGained[2] = {};
    int i = 0;
    for (float slope : {30.0f, 60.0f}) {
        RampProject project(20, 10, 12.0f, 6.0f, slope);
        Sim s;
        add_flat_floor(s.world);
        add_gltf_ramp(s.world);
        Entity hero = add_character(s.world, {-2, 1.2f, 0});
        Walker w{s, hero};
        w.walk({0, 0, 0}, 40);
        w.walk({2, 0, 0}, 180);
        heightGained[i++] = pos_of(s.world, hero).y - 0.92f;
    }
    CHECK(heightGained[0] > 1.5f);
    CHECK(heightGained[1] < 0.6f);
}

TEST_CASE("3d character: pushes dynamic bodies it walks into") {
    Sim s;
    add_big_floor(s.world);
    Entity crate = s.world.create("crate", "crate");
    s.world.get<Transform>(crate)->position = {2.0f, 0.5f, 0};
    s.world.add<Collider3D>(crate);
    s.world.add<RigidBody3D>(crate).mass = 5.0f;
    Entity hero = add_character(s.world, {0, 1.0f, 0});
    Walker w{s, hero};
    w.walk({0, 0, 0}, 30);
    w.walk({2, 0, 0}, 120);
    CHECK(pos_of(s.world, crate).x > 3.2f);
    CHECK(pos_of(s.world, hero).x < pos_of(s.world, crate).x - 0.9f + 0.05f);
    CHECK(pos_of(s.world, hero).x > 1.5f);
}

TEST_CASE("3d character: CharacterController3D.velocity moves it every step") {
    Sim s;
    add_big_floor(s.world);
    Entity hero = add_character(s.world, {0, 0.95f, 0});
    s.run(5);
    s.world.get<CharacterController3D>(hero)->velocity = {2, 0, 0};
    s.run(60);
    CHECK(pos_of(s.world, hero).x == doctest::Approx(2.0f).epsilon(0.03));
}

TEST_CASE("3d character: a rigid capsule body (lockRotation) walks up a glTF mesh ramp too") {
    RampProject project(80, 40, 12.0f, 6.0f, 20.0f);
    Sim s;
    add_flat_floor(s.world);
    add_gltf_ramp(s.world);
    Entity cap = s.world.create("cap", "cap");
    s.world.get<Transform>(cap)->position = {-2, 1.2f, 0};
    Collider3D& c = s.world.add<Collider3D>(cap);
    c.shape = ColliderShape3D::Capsule;
    c.radius = 0.4f;
    c.height = 1.8f;
    c.friction = 0.2f;
    s.world.add<RigidBody3D>(cap).lockRotation = true;
    s.run(40);
    for (int i = 0; i < 240; ++i) {
        RigidBody3D* body = s.world.get<RigidBody3D>(cap);
        body->velocity = {3.0f, body->velocity.y, 0};
        s.run(1);
    }
    const Vec3 p = pos_of(s.world, cap);
    const float tan20 = std::tan(20.0f * kPiF / 180.0f);
    CHECK(p.x > 5.0f);
    CHECK(p.y > p.x * tan20 + 0.8f);
    CHECK(p.y < p.x * tan20 + 1.5f);
}

TEST_CASE("3d character: two identical runs give bit-identical transforms") {
    auto run = [] {
        RampProject project(40, 20, 12.0f, 6.0f, 20.0f);
        Sim s;
        add_flat_floor(s.world);
        add_gltf_ramp(s.world);
        Entity crate = s.world.create("crate", "crate");
        s.world.get<Transform>(crate)->position = {-1.0f, 0.5f, 0};
        s.world.add<Collider3D>(crate);
        s.world.add<RigidBody3D>(crate);
        Entity hero = add_character(s.world, {-4, 1.2f, 0.2f});
        Walker w{s, hero};
        w.walk({0, 0, 0}, 40);
        w.walk({3, 0, 0.2f}, 200);
        std::vector<float> out;
        for (Entity e : {hero, crate}) {
            const Vec3 p = pos_of(s.world, e);
            out.insert(out.end(), {p.x, p.y, p.z});
        }
        return out;
    };
    auto a = run(), b = run();
    CHECK(std::memcmp(a.data(), b.data(), a.size() * sizeof(float)) == 0);
}

// -------------------------------------------------------------- joints ----

namespace {

// A thin rod (0.1 x 1 x 0.1, 1 kg) hanging from a pivot, released `deg` degrees off the vertical.
Entity add_rod(World& w, const char* id, float deg, Entity connected = {}, Vec3 pivot = {0, 0, 0}) {
    Entity e = w.create(id, id);
    const float a = deg * kPiF / 180.0f;
    Transform* t = w.get<Transform>(e);
    t->position = pivot + Vec3{0.5f * std::sin(a), -0.5f * std::cos(a), 0};
    t->rotation = {0, 0, deg};
    w.add<Collider3D>(e).size = {0.1f, 1.0f, 0.1f};
    w.add<RigidBody3D>(e);
    Joint3D& j = w.add<Joint3D>(e);
    j.anchor = {0, 0.5f, 0};
    j.axis = {0, 0, 1};
    j.connected = connected;
    if (connected != Entity{}) j.autoAnchor = true;
    return e;
}

// Mean period between the first and the (crossings+1)-th downward zero crossing of the hinge angle.
float measure_period(Sim& s, Entity rod, int crossings, float maxSeconds = 30.0f) {
    std::vector<float> times;
    float prev = s.world.get<Joint3D>(rod)->angle;
    for (int i = 1; i < int(maxSeconds / kDt) && int(times.size()) <= crossings; ++i) {
        s.run(1);
        const float a = s.world.get<Joint3D>(rod)->angle;
        if (prev > 0.0f && a <= 0.0f) times.push_back((float(i) - 1.0f + prev / (prev - a)) * kDt);
        prev = a;
    }
    if (int(times.size()) <= crossings) return -1.0f;
    return (times.back() - times.front()) / float(crossings);
}

}  // namespace

TEST_CASE("3d joints: a hinge pendulum keeps the period of a physical pendulum over many swings") {
    const float g = 9.81f, d = 0.5f, ratio = (0.1f * 0.1f + 1.0f) / 12.0f + d * d;
    const float t0 = 2.0f * kPiF * std::sqrt(ratio / (g * d));
    for (float amplitude : {10.0f, 30.0f}) {
        CAPTURE(amplitude);
        const float a = amplitude * kPiF / 180.0f;
        const float expected = t0 * (1.0f + a * a / 16.0f + 11.0f * a * a * a * a / 3072.0f);
        Sim s;
        Entity rod = add_rod(s.world, "rod", amplitude);
        const float period = measure_period(s, rod, 6);
        REQUIRE(period > 0.0f);
        CHECK(period == doctest::Approx(expected).epsilon(0.015));
        const Vec3 top = pos_of(s.world, rod) + local_y(s.world, rod) * 0.5f;  // the pivot end never leaves the origin
        CHECK(length(top) < 0.01f);
    }
}

TEST_CASE("3d joints: a hinge to another body swings the same way, ball and fixed joints hold") {
    const float g = 9.81f, d = 0.5f, ratio = (0.1f * 0.1f + 1.0f) / 12.0f + d * d;
    const float t0 = 2.0f * kPiF * std::sqrt(ratio / (g * d));
    {
        Sim s;
        Entity post = s.world.create("post", "post");
        s.world.add<Collider3D>(post).size = {0.4f, 0.4f, 0.4f};
        Entity rod = add_rod(s.world, "rod", 10.0f, post);
        const float period = measure_period(s, rod, 4);
        REQUIRE(period > 0.0f);
        CHECK(period == doctest::Approx(t0 * 1.0019f).epsilon(0.015));
    }
    {
        Sim s;
        Entity previous;
        std::vector<Entity> links;
        for (int i = 0; i < 3; ++i) {
            const std::string name = "link" + std::to_string(i);
            Entity e = s.world.create(name, name);
            s.world.get<Transform>(e)->position = {0.25f + float(i) * 0.5f, 0, 0};
            s.world.add<Collider3D>(e).size = {0.5f, 0.1f, 0.1f};
            s.world.add<RigidBody3D>(e);
            Joint3D& j = s.world.add<Joint3D>(e);
            j.type = JointType3D::Ball;
            j.anchor = {-0.25f, 0, 0};
            j.connected = previous;
            previous = e;
            links.push_back(e);
        }
        float worst = 0.0f;
        for (int i = 0; i < 360; ++i) {
            s.run(1);
            for (int k = 0; k < 3; ++k) {
                const Vec3 xAxis = local_x(s.world, links[std::size_t(k)]);
                const Vec3 end = pos_of(s.world, links[std::size_t(k)]) - xAxis * 0.25f;
                Vec3 expected{};
                if (k > 0)
                    expected = pos_of(s.world, links[std::size_t(k - 1)]) + local_x(s.world, links[std::size_t(k - 1)]) * 0.25f;
                worst = std::max(worst, length(end - expected));
            }
        }
        CHECK(worst < 0.02f);
        CHECK(pos_of(s.world, links[2]).y < -0.5f);
    }
    {
        Sim s;
        Entity anchor = s.world.create("anchor", "anchor");
        s.world.add<Collider3D>(anchor);
        Entity box = s.world.create("box", "box");
        s.world.get<Transform>(box)->position = {1.5f, 0, 0};
        s.world.add<Collider3D>(box);
        s.world.add<RigidBody3D>(box);
        Joint3D& j = s.world.add<Joint3D>(box);
        j.type = JointType3D::Fixed;
        j.anchor = {-0.75f, 0, 0};
        j.connected = anchor;
        s.run(240);
        CHECK(pos_of(s.world, box).y == doctest::Approx(0.0f).epsilon(0.01));
        CHECK(pos_of(s.world, box).x == doctest::Approx(1.5f).epsilon(0.01));
    }
}

TEST_CASE("3d joints: hinge limits stop a door, a motor drives a wheel") {
    {
        Sim s;
        Entity door = s.world.create("door", "door");
        s.world.get<Transform>(door)->position = {0.5f, 0, 0};
        s.world.add<Collider3D>(door).size = {1.0f, 2.0f, 0.1f};
        s.world.add<RigidBody3D>(door).gravityScale = 0.0f;
        Joint3D& j = s.world.add<Joint3D>(door);
        j.anchor = {-0.5f, 0, 0};
        j.axis = {0, 1, 0};
        j.useLimits = true;
        j.lowerLimit = -20;
        j.upperLimit = 60;
        s.world.get<RigidBody3D>(door)->angularVelocity = {0, 400, 0};
        s.run(45);
        CHECK(s.world.get<Joint3D>(door)->angle == doctest::Approx(60.0f).epsilon(0.04));
        s.world.get<RigidBody3D>(door)->angularVelocity = {0, -800, 0};
        s.run(24);
        CHECK(s.world.get<Joint3D>(door)->angle == doctest::Approx(-20.0f).epsilon(0.04));
    }
    {
        Sim s;
        Entity wheel = s.world.create("wheel", "wheel");
        s.world.add<Collider3D>(wheel).size = {1, 1, 0.2f};
        s.world.add<RigidBody3D>(wheel).gravityScale = 0.0f;
        Joint3D& j = s.world.add<Joint3D>(wheel);
        j.axis = {0, 0, 1};
        j.useMotor = true;
        j.motorSpeed = 90.0f;
        j.maxMotorTorque = 50.0f;
        s.run(90);
        CHECK(s.world.get<RigidBody3D>(wheel)->angularVelocity.z == doctest::Approx(90.0f).epsilon(0.03));
        s.world.get<Joint3D>(wheel)->maxMotorTorque = 0.001f;
        s.world.get<RigidBody3D>(wheel)->angularVelocity = {0, 0, 0};
        s.run(30);
        CHECK(std::fabs(s.world.get<RigidBody3D>(wheel)->angularVelocity.z) < 5.0f);
    }
}

TEST_CASE("3d joints: bad joints say what is wrong") {
    Sim s;
    Entity lone = s.world.create("lone", "lone");
    s.world.add<Joint3D>(lone);
    Entity self = s.world.create("self", "self");
    s.world.add<Collider3D>(self);
    s.world.add<RigidBody3D>(self);
    s.world.add<Joint3D>(self).connected = self;
    Entity noBody = s.world.create("nobody", "nobody");
    Entity bad = s.world.create("bad", "bad");
    s.world.add<Collider3D>(bad);
    s.world.add<RigidBody3D>(bad);
    s.world.add<Joint3D>(bad).connected = noBody;
    s.run(2);
    const auto problems = s.physics.problems3d();
    CHECK(problems.size() == 3);
    std::string all;
    for (const auto& p : problems) all += p + "\n";
    CHECK(all.find("no RigidBody3D") != std::string::npos);
    CHECK(all.find("itself") != std::string::npos);
    CHECK(all.find("nobody") != std::string::npos);
}

TEST_CASE("3d joints: a pendulum run is deterministic") {
    auto run = [] {
        Sim s;
        Entity rod = add_rod(s.world, "rod", 25.0f);
        Entity rod2 = add_rod(s.world, "rod2", -15.0f, rod, {0, -1.0f, 0});
        s.run(600);
        std::vector<float> out;
        for (Entity e : {rod, rod2}) {
            const Transform* t = s.world.get<Transform>(e);
            out.insert(out.end(), {t->position.x, t->position.y, t->position.z, t->rotation.x, t->rotation.y, t->rotation.z});
        }
        return out;
    };
    auto a = run(), b = run();
    CHECK(std::memcmp(a.data(), b.data(), a.size() * sizeof(float)) == 0);
    for (float v : a) CHECK(std::isfinite(v));
}

namespace {

// A rope bridge (planks chained with hinges from a post) plus boxes dropped on it, created in a fixed order.
std::vector<Entity> build_bridge_scene(World& w) {
    std::vector<Entity> all;
    auto post = [&](const char* id, float x) {
        Entity e = w.create(id, id);
        w.get<Transform>(e)->position = {x, 0, 0};
        w.add<Collider3D>(e).size = {0.4f, 1.0f, 1.0f};
        all.push_back(e);
        return e;
    };
    Entity previous = post("postL", 0.0f);
    const int planks = 7;
    for (int i = 0; i < planks; ++i) {
        const std::string name = "plank" + std::to_string(i);
        Entity e = w.create(name, name);
        w.get<Transform>(e)->position = {0.7f + 0.6f * float(i), 0.5f, 0};
        w.add<Collider3D>(e).size = {0.6f, 0.1f, 0.8f};
        w.add<RigidBody3D>(e).linearDamping = 0.1f;
        Joint3D& j = w.add<Joint3D>(e);
        j.anchor = {-0.3f, 0, 0};
        j.axis = {0, 0, 1};
        j.connected = previous;
        j.autoAnchor = true;
        previous = e;
        all.push_back(e);
    }
    post("postR", 0.7f + 0.6f * float(planks - 1) + 0.7f);
    for (int i = 0; i < 5; ++i) {
        const std::string name = "box" + std::to_string(i);
        Entity e = w.create(name, name);
        w.get<Transform>(e)->position = {1.0f + 0.7f * float(i), 1.5f + 0.4f * float(i), 0.05f * float(i)};
        w.add<Collider3D>(e).size = {0.3f, 0.3f, 0.3f};
        w.add<RigidBody3D>(e);
        all.push_back(e);
    }
    return all;
}

std::vector<float> run_bridge(Sim& s, const std::vector<Entity>& all, int frames) {
    s.run(frames);
    std::vector<float> out;
    for (Entity e : all) {
        const Transform* t = s.world.get<Transform>(e);
        out.insert(out.end(), {t->position.x, t->position.y, t->position.z, t->rotation.x, t->rotation.y, t->rotation.z});
    }
    return out;
}

}  // namespace

TEST_CASE("3d physics: a scene simulates the same whatever the World and the physics held before it") {
    Sim fresh;
    const std::vector<float> reference = run_bridge(fresh, build_bridge_scene(fresh.world), 240);
    REQUIRE(reference.size() > 30);

    SUBCASE("after entities were created and destroyed (recycled slots)") {
        Sim s;
        std::vector<Entity> junk;
        for (int i = 0; i < 37; ++i) junk.push_back(s.world.create("junk" + std::to_string(i), "junk"));
        for (std::size_t i = 0; i < junk.size(); i += 2) s.world.destroy(junk[i]);
        s.world.flush();
        for (std::size_t i = 1; i < junk.size(); i += 2) s.world.destroy(junk[i]);
        s.world.flush();
        CHECK(run_bridge(s, build_bridge_scene(s.world), 240) == reference);
    }
    SUBCASE("after another scene ran and was cleared (World::clear + Physics::reset, like a scene load)") {
        Sim s;
        build_bridge_scene(s.world);
        for (int i = 0; i < 4; ++i) {  // extra entities so the slot numbers differ
            Entity e = s.world.create("extra" + std::to_string(i), "extra");
            s.world.add<Collider3D>(e);
            s.world.add<RigidBody3D>(e);
        }
        s.run(90);
        s.world.clear();
        s.physics.reset();
        for (int i = 0; i < 9; ++i) s.world.destroy(s.world.create("tmp" + std::to_string(i), "tmp"));
        s.world.flush();
        CHECK(run_bridge(s, build_bridge_scene(s.world), 240) == reference);
    }
}

// ------------------------------------- character on moving and dynamic bodies ----

namespace {

// A 8 x 0.4 x 4 kinematic platform whose top is at y = 1, moving at `velocity`.
Entity add_moving_platform(World& w, Vec3 velocity) {
    Entity p = w.create("platform", "platform");
    w.get<Transform>(p)->position = {0, 0.8f, 0};
    w.add<Collider3D>(p).size = {8, 0.4f, 4};
    RigidBody3D& rb = w.add<RigidBody3D>(p);
    rb.type = BodyType::Kinematic;
    rb.velocity = velocity;
    return p;
}

}  // namespace

TEST_CASE("3d character: a kinematic platform carries it for 300 frames; carriedByPlatforms=false lets it slide off") {
    for (bool carried : {true, false}) {
        Sim s;
        add_big_floor(s.world);
        Entity platform = add_moving_platform(s.world, {1.0f, 0, 0});
        Entity hero = add_character(s.world, {-2, 1.95f, 0});
        s.world.get<CharacterController3D>(hero)->carriedByPlatforms = carried;
        Walker w{s, hero};
        w.walk({0, 0, 0}, 30);
        REQUIRE(w.grounded);
        const float startHero = pos_of(s.world, hero).x, startPlat = pos_of(s.world, platform).x;
        float worstOffset = 0.0f;
        for (int i = 0; i < 300; ++i) {
            w.frame({0, 0, 0});
            worstOffset = std::max(worstOffset, std::fabs((pos_of(s.world, hero).x - startHero) -
                                                          (pos_of(s.world, platform).x - startPlat)));
        }
        const float moved = pos_of(s.world, platform).x - startPlat;
        CHECK(moved == doctest::Approx(5.0f).epsilon(0.03));
        if (carried) {
            CHECK(worstOffset < 0.05f);
            CHECK(w.grounded);
            CHECK(pos_of(s.world, hero).y == doctest::Approx(1.92f).epsilon(0.02));
        } else {
            CHECK(std::fabs(pos_of(s.world, hero).x - startHero) < 0.5f);  // it stayed, the platform left
        }
    }
}

TEST_CASE("3d character: a turning kinematic platform carries it round and turns it") {
    Sim s;
    Entity platform = add_moving_platform(s.world, {});
    s.world.get<RigidBody3D>(platform)->angularVelocity = {0, 36.0f, 0};  // 10 s per turn
    Entity hero = add_character(s.world, {2.5f, 1.95f, 0});
    Walker w{s, hero};
    w.walk({0, 0, 0}, 30);
    REQUIRE(w.grounded);
    const Vec3 c = pos_of(s.world, platform);
    const float r0 = std::hypot(pos_of(s.world, hero).x - c.x, pos_of(s.world, hero).z - c.z);
    const float yaw0 = s.world.get<Transform>(hero)->rotation.y;
    w.walk({0, 0, 0}, 150);  // 2.5 s = 90 degrees
    const Vec3 p = pos_of(s.world, hero);
    CHECK(std::hypot(p.x - c.x, p.z - c.z) == doctest::Approx(r0).epsilon(0.03));
    CHECK(std::fabs(p.z - c.z) > 0.8f * r0);  // a quarter turn: it is now beside the platform's z axis
    CHECK(std::fabs(s.world.get<Transform>(hero)->rotation.y - yaw0) > 60.0f);
}

TEST_CASE("3d character: its weight tips a seesaw on its pivot, and a jointed crate is not shoved") {
    SUBCASE("seesaw") {
        Sim s;
        add_big_floor(s.world);
        Entity plank = s.world.create("plank", "plank");
        s.world.get<Transform>(plank)->position = {0, 1.0f, 0};
        s.world.add<Collider3D>(plank).size = {4, 0.2f, 1.5f};
        s.world.add<RigidBody3D>(plank).mass = 20.0f;
        Joint3D& j = s.world.add<Joint3D>(plank);  // hinge on the world at the plank's centre, axis z
        j.axis = {0, 0, 1};
        Entity hero = add_character(s.world, {1.5f, 2.1f, 0});
        Walker w{s, hero};
        w.walk({0, 0, 0}, 120);
        const Vec3 p = pos_of(s.world, plank);
        CHECK(s.world.get<Transform>(plank)->rotation.z < -5.0f);  // the +x end, where it stands, went down
        CHECK(std::fabs(p.x) < 0.05f);
        CHECK(std::fabs(p.z) < 0.05f);
        CHECK(p.y == doctest::Approx(1.0f).epsilon(0.05));
        CHECK(w.grounded);
    }
    SUBCASE("a weightless character (applyWeight=false) leaves it level") {
        Sim s;
        Entity plank = s.world.create("plank", "plank");
        s.world.get<Transform>(plank)->position = {0, 1.0f, 0};
        s.world.add<Collider3D>(plank).size = {4, 0.2f, 1.5f};
        s.world.add<RigidBody3D>(plank).mass = 20.0f;
        s.world.add<Joint3D>(plank).axis = {0, 0, 1};
        Entity hero = add_character(s.world, {1.5f, 2.1f, 0});
        s.world.get<CharacterController3D>(hero)->applyWeight = false;
        Walker w{s, hero};
        w.walk({0, 0, 0}, 120);
        CHECK(std::fabs(s.world.get<Transform>(plank)->rotation.z) < 1.0f);
    }
    SUBCASE("free crate is pushed, jointed crate is not") {
        for (bool jointed : {false, true}) {
            Sim s;
            add_big_floor(s.world);
            Entity crate = s.world.create("crate", "crate");
            s.world.get<Transform>(crate)->position = {2.0f, 0.5f, 0};
            s.world.add<Collider3D>(crate);
            s.world.add<RigidBody3D>(crate).mass = 5.0f;
            if (jointed) s.world.add<Joint3D>(crate).axis = {0, 1, 0};
            Entity hero = add_character(s.world, {0, 1.0f, 0});
            Walker w{s, hero};
            w.walk({0, 0, 0}, 30);
            w.walk({2, 0, 0}, 120);
            if (jointed) {
                CHECK(std::fabs(pos_of(s.world, crate).x - 2.0f) < 0.1f);
                CHECK(pos_of(s.world, hero).x < 1.2f);
            } else {
                CHECK(pos_of(s.world, crate).x > 3.2f);
            }
        }
    }
}
