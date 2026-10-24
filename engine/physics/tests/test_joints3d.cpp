// Joint3D: start overlaps, stalled motors, chains (rope bridges) that sleep, islands that do not disturb each other,
// and `connected: ""` meaning the world.
#include <doctest.h>

#include <cmath>
#include <cstring>
#include <string>
#include <vector>

#include "fa/core/log.h"
#include "fa/physics/physics.h"
#include "fa/scene/serialize.h"

using namespace fa;

namespace {

constexpr float kDt = 1.0f / 60.0f;

struct Sim {
    World world;
    Physics physics;
    Sim() { physics.init(PhysicsSettings{}); }
    void run(int steps) {
        for (int i = 0; i < steps; ++i) {
            world.events().clear();
            physics.step(world, kDt);
            world.advance_clock(kDt);
            world.flush();
        }
    }
};

Entity add_box(World& w, const char* id, Vec3 pos, Vec3 size, bool dynamic) {
    Entity e = w.create(id, id);
    w.get<Transform>(e)->position = pos;
    w.add<Collider3D>(e).size = size;
    if (dynamic) w.add<RigidBody3D>(e);
    return e;
}

// Messages of the "physics" log category while alive.
struct LogCatcher {
    std::vector<std::string> lines;
    int id;
    LogCatcher() {
        id = add_log_sink([this](const LogEntry& e) {
            if (e.category == "physics" && e.level >= LogLevel::Warn) lines.push_back(e.message);
        });
    }
    ~LogCatcher() { remove_log_sink(id); }
};

// A rope bridge like the Clockwork Courier's: `n` planks (1 m long, 0.6 m wide) hanging in a parabola between x0 and
// x0 + n, each hinged to the next one; the first from a static anchor, the last from the world. Default damping.
std::vector<Entity> add_bridge(World& w, const std::string& name, float z, int n, float sag = 0.35f, float width = 0.6f) {
    auto curve = [&](float t) { return Vec3{float(n) * t, -sag * 4.0f * t * (1.0f - t), z}; };
    std::vector<Entity> planks;
    for (int i = 0; i < n; ++i) {
        const Vec3 a = curve(float(i) / float(n)), b = curve(float(i + 1) / float(n));
        const Vec3 d = b - a;
        Entity e = w.create(name + "_" + std::to_string(i), name + "_" + std::to_string(i));
        Transform* t = w.get<Transform>(e);
        t->position = (a + b) * 0.5f - Vec3{0, 0.07f, 0};
        t->rotation = {0, 0, std::atan2(d.y, d.x) * 180.0f / 3.14159265f};
        w.add<Collider3D>(e).size = {length(d) * 0.94f, 0.14f, width};
        w.add<RigidBody3D>(e).mass = 6.0f;
        planks.push_back(e);
    }
    for (int i = 0; i < n; ++i) {
        Joint3D& j = w.add<Joint3D>(planks[std::size_t(i)]);
        j.axis = {0, 0, 1};
        j.anchor = {0.5f, 0.0f, 0};  // the far end
        j.anchor.x = 0.5f * length(curve(float(i + 1) / float(n)) - curve(float(i) / float(n))) * 0.94f;
        if (i + 1 < n) j.connected = planks[std::size_t(i + 1)];
    }
    Entity start = w.create(name + "_start", name + "_start");
    w.get<Transform>(start)->position = curve(0);
    w.add<Collider3D>(start).size = {0.05f, 0.05f, 0.05f};
    w.add<RigidBody3D>(start).type = BodyType::Static;
    Joint3D& js = w.add<Joint3D>(start);
    js.axis = {0, 0, 1};
    js.connected = planks[0];
    return planks;
}

int awake_count(Sim& s, const std::string& prefix) {
    int n = 0;
    for (const Json& b : s.physics.debug_state(s.world)) {
        const std::string id = b.value("entity", std::string());
        if (id.rfind(prefix, 0) == 0 && b.value("awake", false)) ++n;
    }
    return n;
}

}  // namespace

TEST_CASE("3d start overlaps: a body started inside a static collider is reported once, naming both") {
    LogCatcher log;
    Sim s;
    add_box(s.world, "slab", {0, 0, 0}, {4, 1, 4}, false);
    add_box(s.world, "plank", {0, 0.85f, 0}, {1, 1, 1}, true);  // 0.15 m inside the slab's top
    add_box(s.world, "clear", {10, 1.0f, 0}, {1, 1, 1}, true);   // resting on nothing: no overlap
    const std::vector<StartOverlap> found = s.physics.start_overlaps3d(s.world);
    REQUIRE(found.size() == 1);
    CHECK(s.world.id_of(found[0].body) == "plank");
    CHECK(s.world.id_of(found[0].collider) == "slab");
    CHECK(found[0].depth == doctest::Approx(0.15f).epsilon(0.05));
    CHECK(found[0].message.find("'plank'") != std::string::npos);
    CHECK(found[0].message.find("'slab'") != std::string::npos);
    CHECK(found[0].message.find("0.15 m") != std::string::npos);
    CHECK(log.lines.empty());  // asking does not log
    s.run(120);
    int hits = 0;
    for (const std::string& l : log.lines)
        if (l.find("'plank'") != std::string::npos && l.find("'slab'") != std::string::npos) ++hits;
    CHECK(hits == 1);  // one warning over 120 steps
    CHECK(log.lines.size() == 1);
}

TEST_CASE("3d start overlaps: a body resting on the ground (a millimetre in) is not reported") {
    LogCatcher log;
    Sim s;
    add_box(s.world, "ground", {0, -0.5f, 0}, {20, 1, 20}, false);
    add_box(s.world, "crate", {0, 0.5f, 0}, {1, 1, 1}, true);
    s.run(60);
    CHECK(log.lines.empty());
}

TEST_CASE("3d joints: a motor driven into a wall reads stalled; a free one and one at its limit do not") {
    auto gate = [](Sim& s, const char* id, float z) {
        Entity e = add_box(s.world, id, {0.5f, 0, z}, {1.0f, 2.0f, 0.1f}, true);
        s.world.get<RigidBody3D>(e)->gravityScale = 0.0f;
        Joint3D& j = s.world.add<Joint3D>(e);
        j.anchor = {-0.5f, 0, 0};
        j.axis = {0, 1, 0};
        j.useMotor = true;
        j.motorSpeed = 60.0f;
        j.maxMotorTorque = 30.0f;
        return e;
    };
    Sim s;
    Entity blocked = gate(s, "blocked", 0);
    // The wall: where the gate's free end arrives after ~35 degrees (the gate swings its +x end towards -z or +z).
    add_box(s.world, "wall", {0.9f, 0, -0.55f}, {0.4f, 3, 0.4f}, false);
    Entity free = gate(s, "free", 10);
    Entity limited = gate(s, "limited", 20);
    Joint3D* lj = s.world.get<Joint3D>(limited);
    lj->useLimits = true;
    lj->lowerLimit = -90;
    lj->upperLimit = 40;
    s.run(30);
    CHECK_FALSE(s.world.get<Joint3D>(blocked)->stalled);  // it has not reached the wall yet, or only just
    s.run(150);
    CHECK(s.world.get<Joint3D>(blocked)->stalled);
    CHECK(std::fabs(s.world.get<Joint3D>(blocked)->angle) < 60.0f);
    CHECK_FALSE(s.world.get<Joint3D>(free)->stalled);
    CHECK_FALSE(s.world.get<Joint3D>(limited)->stalled);
    CHECK(std::fabs(s.world.get<Joint3D>(limited)->angle) == doctest::Approx(40.0f).epsilon(0.1));
    // The wall goes away: the gate moves again.
    s.world.destroy(s.world.find_by_id("wall"));
    s.run(90);
    CHECK_FALSE(s.world.get<Joint3D>(blocked)->stalled);
}

TEST_CASE("3d joints: a 12-plank bridge settles and falls asleep within 5 s") {
    Sim s;
    auto planks = add_bridge(s.world, "b", 0, 12);
    s.run(300);
    CHECK(awake_count(s, "b_") == 0);
    for (Entity e : planks) CHECK(s.world.world_position(e).y > -1.0f);  // it holds: nothing fell through
    // Still a bridge when it is not taut, and with the hinges of every plank damped as the recipe says.
    Sim loose;
    auto slack = add_bridge(loose.world, "c", 0, 12, 1.5f);
    for (Entity e : slack) loose.world.get<Joint3D>(e)->damping = 2.0f;
    loose.run(300);
    CHECK(awake_count(loose, "c_") == 0);
}

TEST_CASE("3d joints: a sleeping bridge wakes when something lands on it") {
    Sim s;
    auto planks = add_bridge(s.world, "b", 0, 12);
    add_box(s.world, "ground", {6, -6, 0}, {40, 1, 8}, false);
    s.run(300);
    REQUIRE(awake_count(s, "b_") == 0);
    Entity crate = add_box(s.world, "crate", {6, 1.5f, 0}, {0.5f, 0.5f, 0.5f}, true);
    s.run(40);
    CHECK(awake_count(s, "b_") > 0);
    CHECK(s.world.world_position(crate).y < 1.4f);
}

TEST_CASE("3d joints: two bridges side by side move exactly as each one alone") {
    auto poses = [](bool first, bool second) {
        Sim s;
        std::vector<Entity> a, b;
        if (first) a = add_bridge(s.world, "a", 0, 12);
        if (second) b = add_bridge(s.world, "b", 3, 8, 0.5f);
        // A fast ball through the second bridge's neighbourhood gives the world a time-of-impact event.
        if (second) {
            Entity ball = s.world.create("ball", "ball");
            s.world.get<Transform>(ball)->position = {20, 3, 3};
            Collider3D& c = s.world.add<Collider3D>(ball);
            c.shape = ColliderShape3D::Sphere;
            c.radius = 0.2f;
            s.world.add<RigidBody3D>(ball).velocity = {-40, 0, 0};
            add_box(s.world, "wall", {16, 2, 3}, {0.2f, 6, 4}, false);
        }
        s.run(240);
        std::vector<float> out;
        for (const auto* g : {&a, &b})
            for (Entity e : *g) {
                const Vec3 p = s.world.world_position(e);
                out.insert(out.end(), {p.x, p.y, p.z});
            }
        return out;
    };
    const std::vector<float> alone1 = poses(true, false), alone2 = poses(false, true), both = poses(true, true);
    REQUIRE(both.size() == alone1.size() + alone2.size());
    CHECK(std::memcmp(both.data(), alone1.data(), alone1.size() * sizeof(float)) == 0);
    CHECK(std::memcmp(both.data() + alone1.size(), alone2.data(), alone2.size() * sizeof(float)) == 0);
}

TEST_CASE("3d joints: Joint3D.damping takes the swing out of a pendulum") {
    auto speed_after = [](float damping, int steps) {
        Sim s;
        Entity rod = add_box(s.world, "rod", {0.5f, 0, 0}, {1.0f, 0.1f, 0.1f}, true);  // released horizontal
        Joint3D& j = s.world.add<Joint3D>(rod);
        j.anchor = {-0.5f, 0, 0};
        j.axis = {0, 0, 1};
        j.damping = damping;
        s.run(steps);
        return length(s.world.get<RigidBody3D>(rod)->angularVelocity);
    };
    float freeMax = 0.0f;
    for (int steps = 240; steps < 300; steps += 7) freeMax = std::max(freeMax, speed_after(0.0f, steps));
    CHECK(freeMax > 100.0f);                    // deg/s: still swinging after 4+ s
    CHECK(speed_after(8.0f, 300) < 3.0f);       // hanging still
}

TEST_CASE("3d joints: connected \"\" is the world, in scene files, by set_component and when run") {
    Sim s;
    const char* scene = R"({
      "version": 1, "name": "j",
      "entities": [
        {"id": "ground", "components": {"Transform": {"position": [0, -3, 0]}, "Collider3D": {"size": [20, 1, 20]}}},
        {"id": "pendulum", "components": {
          "Transform": {"position": [0.5, 0, 0]},
          "Collider3D": {"size": [1, 0.1, 0.1]},
          "RigidBody3D": {},
          "Joint3D": {"anchor": [-0.5, 0, 0], "axis": [0, 0, 1], "connected": ""}}}
      ]})";
    auto parsed = parse_json(scene, "inline.scene.json");
    REQUIRE(parsed.ok());
    LoadReport r = load_scene(s.world, parsed.value(), "inline.scene.json");
    for (const auto& m : r.messages) INFO(m.message);
    CHECK(r.ok());
    Entity e = s.world.find_by_id("pendulum");
    REQUIRE_FALSE(e.is_null());
    CHECK(s.world.get<Joint3D>(e)->connected.is_null());
    s.run(30);
    CHECK(s.physics.problems3d().empty());
    CHECK(s.world.world_position(e).x < 0.5f);  // it swung about the pivot at the origin
    CHECK(s.world.world_position(e).y < -0.2f);
}
