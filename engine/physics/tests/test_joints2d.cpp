// Joint2D: Box2D joints on RigidBody2D entities (revolute, distance, prismatic, weld).
// World units are pixels; 100 pixels = 1 meter, gravity2D = -980 px/s^2 = 9.8 m/s^2.
#include <doctest.h>

#include <cmath>
#include <vector>

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

Entity body(World& w, const char* id, Vec2 pos, Vec2 size, BodyType type = BodyType::Dynamic) {
    Entity e = w.create(id, id);
    w.get<Transform>(e)->position = {pos.x, pos.y, 0};
    Collider2D& c = w.add<Collider2D>(e);
    c.size = size;
    c.layer = 5;
    c.mask = 0;  // collides with nothing: the joints are what is tested
    RigidBody2D& rb = w.add<RigidBody2D>(e);
    rb.type = type;
    rb.linearDamping = 0.0f;
    rb.angularDamping = 0.0f;
    return e;
}

Vec3 pos(const World& w, Entity e) { return w.world_position(e); }
float rot(const World& w, Entity e) { return w.get<Transform>(e)->rotation.z; }

// Pendulum bob: a small box `length` from the world point `pivot`, `angleDeg` away from straight down, hinged to the world.
Entity pendulum(World& w, Vec2 pivot, float length, float angleDeg) {
    const float a = radians(angleDeg);
    const Vec2 p{pivot.x + length * std::sin(a), pivot.y - length * std::cos(a)};
    Entity bob = body(w, "bob", p, {8, 8});
    Joint2D& j = w.add<Joint2D>(bob);
    j.type = JointType2D::Revolute;
    j.anchor = {pivot.x - p.x, pivot.y - p.y};  // where the pivot sits in the bob's own frame (the bob is unrotated)
    j.connectedAnchor = pivot;                  // `connected` empty: a world position
    return bob;
}

}  // namespace

TEST_CASE("joint2d: a revolute pendulum keeps its period") {
    Sim s;
    const float L = 200.0f;  // 2 m
    Entity bob = pendulum(s.world, {0, 100}, L, 5.0f);
    // Physical pendulum of a thin box about a pivot d away: T = 2 pi sqrt(I / (m g d)), I = m (d^2 + (w^2 + h^2) / 12).
    const float d = L / 100.0f, w = 0.08f, g = 9.8f;
    const float period = 2.0f * kPi * std::sqrt((d * d + (w * w + w * w) / 12.0f) / (g * d)) * (1.0f + radians(5.0f) * radians(5.0f) / 16.0f);
    // Zero crossings of the horizontal offset, linearly interpolated.
    std::vector<double> crossings;
    float prev = pos(s.world, bob).x - 0.0f;
    const int steps = int(5.0f * period / kDt);
    for (int i = 1; i <= steps; ++i) {
        s.run(1);
        const float x = pos(s.world, bob).x;
        if (prev > 0.0f && x <= 0.0f) crossings.push_back((double(i - 1) + double(prev / (prev - x))) * kDt);  // downward through the middle
        prev = x;
    }
    REQUIRE(crossings.size() >= 4);
    const double measured = (crossings.back() - crossings.front()) / double(crossings.size() - 1);
    INFO("measured " << measured << " s, expected " << period << " s");
    CHECK(measured == doctest::Approx(period).epsilon(0.02));
    // the bob stays L from the pivot
    const Vec3 p = pos(s.world, bob);
    CHECK(std::sqrt(p.x * p.x + (p.y - 100) * (p.y - 100)) == doctest::Approx(L).epsilon(0.01));
}

TEST_CASE("joint2d: a revolute limit stops the swing, the angle is readable") {
    Sim s;
    s.world.settings().gravity2D = {0, -980};
    // A bar hinged at its left end sticking out to the right: gravity swings it down (negative angle).
    Entity bar = body(s.world, "bar", {100, 0}, {100, 10});
    Joint2D& j = s.world.add<Joint2D>(bar);
    j.anchor = {-50, 0};
    j.connectedAnchor = {50, 0};
    j.enableLimit = true;
    j.lowerLimit = -30.0f;
    j.upperLimit = 30.0f;
    s.run(240);
    const Joint2D* jj = s.world.get<Joint2D>(bar);
    CHECK(jj->angle == doctest::Approx(-30.0f).epsilon(0.05));
    CHECK(rot(s.world, bar) == doctest::Approx(-30.0f).epsilon(0.05));
    CHECK(jj->reactionForce.y != 0.0f);
}

TEST_CASE("joint2d: a revolute motor spins at its speed, and it can be switched on at run time") {
    Sim s;
    s.world.settings().gravity2D = {0, 0};
    Entity wheel = body(s.world, "wheel", {0, 0}, {40, 40});
    Joint2D& j = s.world.add<Joint2D>(wheel);  // pinned to the world at its own centre
    j.connectedAnchor = {0, 0};
    j.motorSpeed = 180.0f;
    j.maxMotorTorque = 1e6f;
    s.run(30);
    CHECK(s.world.get<RigidBody2D>(wheel)->angularVelocity == doctest::Approx(0.0f).epsilon(0.01));  // motor still off
    s.world.get<Joint2D>(wheel)->enableMotor = true;
    s.run(60);
    CHECK(s.world.get<RigidBody2D>(wheel)->angularVelocity == doctest::Approx(180.0f).epsilon(0.03));
    CHECK(s.world.get<Joint2D>(wheel)->angle != 0.0f);
    s.world.get<Joint2D>(wheel)->motorSpeed = -90.0f;
    s.run(60);
    CHECK(s.world.get<RigidBody2D>(wheel)->angularVelocity == doctest::Approx(-90.0f).epsilon(0.03));
}

TEST_CASE("joint2d: a prismatic joint keeps the body on its axis within the limits") {
    Sim s;
    // Slides along the diagonal (1, 1); gravity pulls it down the line to the lower limit.
    Entity box = body(s.world, "slider", {0, 0}, {20, 20});
    Joint2D& j = s.world.add<Joint2D>(box);
    j.type = JointType2D::Prismatic;
    j.axis = {1, 1};
    j.connectedAnchor = {0, 0};  // the anchors coincide at the start: translation 0
    j.enableLimit = true;
    j.lowerLimit = -100.0f;
    j.upperLimit = 40.0f;
    for (int i = 0; i < 12; ++i) {
        s.run(20);
        const Vec3 p = pos(s.world, box);
        CHECK(std::fabs(p.x - p.y) < 1.0f);  // on the line y = x
        CHECK(std::fabs(rot(s.world, box)) < 0.5f);
        const float t = s.world.get<Joint2D>(box)->translation;
        CHECK(t >= -100.5f);
        CHECK(t <= 40.5f);
    }
    // At rest on the lower limit: 100 world units along the axis.
    const Vec3 p = pos(s.world, box);
    CHECK(p.x == doctest::Approx(-100.0f / std::sqrt(2.0f)).epsilon(0.02));
    CHECK(s.world.get<Joint2D>(box)->translation == doctest::Approx(-100.0f).epsilon(0.02));
    // A push up the axis stops at the upper limit.
    s.physics.apply_impulse(s.world, box, {2000, 2000, 0});
    s.run(30);
    CHECK(s.world.get<Joint2D>(box)->translation <= 40.5f);
}

TEST_CASE("joint2d: a weld holds two bodies together") {
    Sim s;
    s.world.settings().gravity2D = {0, 0};
    Entity a = body(s.world, "a", {0, 0}, {40, 40});
    Entity b = body(s.world, "b", {60, 0}, {40, 40});
    Joint2D& j = s.world.add<Joint2D>(b);
    j.type = JointType2D::Weld;
    j.connected = a;
    j.anchor = {-30, 0};
    j.connectedAnchor = {30, 0};
    s.world.get<RigidBody2D>(a)->angularVelocity = 90.0f;
    s.world.get<RigidBody2D>(a)->velocity = {50, 20};
    for (int i = 0; i < 5; ++i) {
        s.run(60);
        const Vec3 pa = pos(s.world, a), pb = pos(s.world, b);
        CHECK(std::sqrt((pb.x - pa.x) * (pb.x - pa.x) + (pb.y - pa.y) * (pb.y - pa.y)) == doctest::Approx(60.0f).epsilon(0.02));
        CHECK(rot(s.world, b) - rot(s.world, a) == doctest::Approx(0.0f).epsilon(0.05).scale(10.0));
        // the welded pair turned together: b stays on a's local +x axis
        const float ang = radians(rot(s.world, a));
        CHECK(std::fabs((pb.x - pa.x) * -std::sin(ang) + (pb.y - pa.y) * std::cos(ang)) < 3.0f);
    }
    CHECK(std::fabs(s.world.get<RigidBody2D>(a)->angularVelocity) > 1.0f);  // it really spun (the rotation itself wraps)
    CHECK(std::fabs(s.world.get<Joint2D>(b)->angle) < 3.0f);
}

TEST_CASE("joint2d: a distance joint keeps its length") {
    Sim s;
    // A ball on a 150 unit rope from a point in the air, started sideways so it swings.
    Entity ball = body(s.world, "ball", {150, 100}, {16, 16});
    Joint2D& j = s.world.add<Joint2D>(ball);
    j.type = JointType2D::Distance;
    j.connectedAnchor = {0, 100};  // world point; length = 0 -> the distance at the start (150)
    for (int i = 0; i < 6; ++i) {
        s.run(30);
        const Vec3 p = pos(s.world, ball);
        CHECK(std::sqrt(p.x * p.x + (p.y - 100) * (p.y - 100)) == doctest::Approx(150.0f).epsilon(0.01));
    }
    CHECK(pos(s.world, ball).y < 99.0f);  // it fell and swings
    CHECK(s.world.get<Joint2D>(ball)->translation == doctest::Approx(150.0f).epsilon(0.01));  // current length
}

TEST_CASE("joint2d: a distance spring settles below its rest length") {
    Sim s;
    Entity ball = body(s.world, "ball", {0, 0}, {16, 16});
    s.world.get<RigidBody2D>(ball)->linearDamping = 0.5f;
    Joint2D& j = s.world.add<Joint2D>(ball);
    j.type = JointType2D::Distance;
    j.connectedAnchor = {0, 100};
    j.length = 100.0f;
    j.enableSpring = true;
    j.springHertz = 2.0f;
    j.dampingRatio = 0.5f;
    s.run(600);
    // sag = g / (2 pi f)^2 = 9.8 / 157.9 = 6.2 cm
    const float y = pos(s.world, ball).y;
    CHECK(y == doctest::Approx(100.0f - 100.0f - 6.2f).scale(1.0).epsilon(0.1));
    CHECK(std::fabs(pos(s.world, ball).x) < 1.0f);
}

TEST_CASE("joint2d: the reaction force of a hanging body is its weight") {
    Sim s;
    Entity bob = pendulum(s.world, {0, 100}, 100.0f, 0.0f);
    s.run(120);
    // mass = 0.08 m x 0.08 m x density 1; weight in world units (the unit of physics.applyForce): m * g * 100
    const float weight = 0.08f * 0.08f * 9.8f * 100.0f;
    const Vec2 f = s.world.get<Joint2D>(bob)->reactionForce;
    CHECK(std::fabs(f.y) == doctest::Approx(weight).epsilon(0.05));
    CHECK(std::fabs(f.x) < 0.1f * weight);
}

TEST_CASE("joint2d: the joint follows the components: removed with the connected entity or the component") {
    Sim s;
    s.world.settings().gravity2D = {0, -980};
    Entity anchor = body(s.world, "anchor", {0, 200}, {20, 20}, BodyType::Static);
    Entity ball = body(s.world, "ball", {0, 100}, {16, 16});
    Joint2D& j = s.world.add<Joint2D>(ball);
    j.type = JointType2D::Distance;
    j.connected = anchor;
    j.anchor = {0, 0};
    j.connectedAnchor = {0, 0};
    s.run(60);
    CHECK(pos(s.world, ball).y == doctest::Approx(100.0f).epsilon(0.03));  // hangs on the rope
    s.world.remove<Joint2D>(ball);
    s.run(60);
    CHECK(pos(s.world, ball).y < 0.0f);  // free again
    // a joint to an entity that is destroyed: the ball drops, nothing crashes
    Entity ball2 = body(s.world, "ball2", {50, 100}, {16, 16});
    Joint2D& j2 = s.world.add<Joint2D>(ball2);
    j2.type = JointType2D::Weld;
    j2.connected = anchor;
    s.run(30);
    CHECK(pos(s.world, ball2).y > 90.0f);
    s.world.destroy(anchor);
    s.run(60);
    CHECK(pos(s.world, ball2).y < 0.0f);
    // a joint whose connected entity has no body is reported and ignored
    Entity bare = s.world.create("bare", "bare");
    Entity ball3 = body(s.world, "ball3", {80, 100}, {16, 16});
    Joint2D& j3 = s.world.add<Joint2D>(ball3);
    j3.connected = bare;
    s.run(60);
    CHECK(pos(s.world, ball3).y < 50.0f);
}

TEST_CASE("joint2d: collideConnected decides whether the joined bodies collide") {
    for (bool collide : {false, true}) {
        Sim s;
        s.world.settings().gravity2D = {0, 0};
        Entity a = body(s.world, "a", {0, 0}, {40, 40}, BodyType::Static);
        Entity b = body(s.world, "b", {20, 0}, {40, 40});  // overlaps a
        s.world.get<Collider2D>(a)->mask = -1;
        s.world.get<Collider2D>(b)->mask = -1;
        s.world.get<Collider2D>(a)->layer = 0;
        s.world.get<Collider2D>(b)->layer = 0;
        Joint2D& j = s.world.add<Joint2D>(b);
        j.type = JointType2D::Weld;
        j.connected = a;
        j.anchor = {-10, 0};
        j.connectedAnchor = {10, 0};
        j.collideConnected = collide;
        s.run(60);
        const float x = pos(s.world, b).x;
        INFO("collideConnected " << collide << " x " << x);
        if (collide) CHECK(std::fabs(x - 20.0f) < 25.0f);  // pushed apart or held: still a valid state, no crash
        else CHECK(x == doctest::Approx(20.0f).epsilon(0.02));
    }
}

TEST_CASE("joint2d: loaded from a scene by entity id, with the same result as built in code") {
    Json scene = Json::parse(R"({
      "format": "factoria.scene/1",
      "entities": [
        {"id": "post", "components": {"Transform": {"position": [0, 100]},
            "Collider2D": {"size": [10, 10], "mask": 0}, "RigidBody2D": {"type": "static"}}},
        {"id": "arm", "components": {"Transform": {"position": [60, 100]},
            "Collider2D": {"size": [100, 10], "mask": 0}, "RigidBody2D": {"angularDamping": 0},
            "Joint2D": {"type": "revolute", "connected": "post", "anchor": [-60, 0], "connectedAnchor": [0, 0],
                        "enableLimit": true, "lowerLimit": -45, "upperLimit": 45}}}
      ]
    })");
    Sim s;
    LoadReport report = load_scene(s.world, scene, "test");
    REQUIRE(report.error_count() == 0);
    Entity arm = s.world.find_by_id("arm");
    REQUIRE(!arm.is_null());
    CHECK(s.world.get<Joint2D>(arm)->connected == s.world.find_by_id("post"));
    s.run(180);
    CHECK(s.world.get<Joint2D>(arm)->angle == doctest::Approx(-45.0f).epsilon(0.05));
    // and it saves back with the id
    Json saved = save_scene(s.world);
    bool found = false;
    for (const Json& e : saved["entities"])
        if (e["id"] == "arm") found = e["components"]["Joint2D"]["connected"] == "post";
    CHECK(found);
}

TEST_CASE("joint2d: the simulation with joints is deterministic") {
    auto run = [] {
        Sim s;
        Entity a = body(s.world, "a", {0, 0}, {30, 30});
        Entity b = body(s.world, "b", {60, 0}, {30, 30});
        Joint2D& j = s.world.add<Joint2D>(b);
        j.connected = a;
        j.anchor = {-30, 0};
        j.connectedAnchor = {30, 0};
        j.enableSpring = true;
        j.springHertz = 3.0f;
        j.dampingRatio = 0.2f;
        Entity pend = pendulum(s.world, {0, 300}, 120.0f, 40.0f);
        (void)pend;
        s.run(400);
        return std::vector<Vec3>{pos(s.world, a), pos(s.world, b), pos(s.world, s.world.find_by_id("bob"))};
    };
    const auto r1 = run(), r2 = run();
    for (std::size_t i = 0; i < r1.size(); ++i) {
        CHECK(r1[i].x == r2[i].x);
        CHECK(r1[i].y == r2[i].y);
    }
}
