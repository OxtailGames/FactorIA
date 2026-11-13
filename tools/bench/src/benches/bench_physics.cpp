// Physics benchmarks: one second (60 steps) of a pile of falling bodies in 2D (Box2D) and in 3D (the engine's own solver).
#include <memory>

#include "benches.h"
#include "fa/core/math.h"
#include "fa/physics/physics.h"
#include "fa/scene/components.h"
#include "fa/scene/world.h"

namespace fa::bench {

namespace {

constexpr float kDt = 1.0f / 60.0f;
constexpr int kSteps = 60;
constexpr int k3dSteps = 20;  // the 3D solver costs more per body

// A world and its physics, rebuilt before every run: bodies fall asleep, so a second run on the same world would measure a
// sleeping pile instead of the same work.
struct Sim {
    std::unique_ptr<World> world;
    Physics physics;
    Sim() { physics.init(PhysicsSettings{}); }
    void reset() {
        physics.reset();
        world = std::make_unique<World>();
    }
    double run_steps(int steps) {
        for (int i = 0; i < steps; ++i) {
            world->events().clear();
            physics.step(*world, kDt);
            world->advance_clock(kDt);
            world->flush();
        }
        double sum = double(world->events().collisions.size());
        world->each<Transform, RigidBody2D>(
            [&](Entity, Transform& t, RigidBody2D&) { sum += t.position.x + 2.0 * t.position.y; });
        world->each<Transform, RigidBody3D>(
            [&](Entity, Transform& t, RigidBody3D&) { sum += t.position.x + 2.0 * t.position.y + 3.0 * t.position.z; });
        return sum;
    }
};

void build_2d(World& w) {
    auto wall = [&](Vec2 pos, Vec2 size) {
        Entity e = w.create();
        w.get<Transform>(e)->position = {pos.x, pos.y, 0};
        w.add<Collider2D>(e).size = size;  // no RigidBody2D: static
    };
    wall({0, -320}, {1400, 40});
    wall({-420, -100}, {40, 700});
    wall({420, -100}, {40, 700});
    Rng rng(2024);
    for (int row = 0; row < 24; ++row) {
        for (int col = 0; col < 24; ++col) {
            Entity e = w.create();
            w.get<Transform>(e)->position = {-345.0f + float(col) * 30.0f + float(rng.next_u32() % 5),
                                             -250.0f + float(row) * 30.0f + float(rng.next_u32() % 5), 0};
            Collider2D& c = w.add<Collider2D>(e);
            if ((row + col) % 3 == 0) {
                c.shape = ColliderShape::Circle;
                c.radius = 12.0f;
            } else {
                c.size = {22.0f + float(rng.next_u32() % 5), 22.0f};
            }
            w.add<RigidBody2D>(e);
        }
    }
}

void build_3d(World& w) {
    Entity ground = w.create();
    w.get<Transform>(ground)->position = {0, -0.5f, 0};
    w.add<Collider3D>(ground).size = {40, 1, 40};  // no RigidBody3D: static
    Rng rng(2025);
    for (int layer = 0; layer < 4; ++layer) {
        for (int ix = 0; ix < 7; ++ix) {
            for (int iz = 0; iz < 7; ++iz) {
                Entity e = w.create();
                w.get<Transform>(e)->position = {-4.5f + float(ix) * 1.5f + float(rng.next_u32() % 20) * 0.01f,
                                                 1.0f + float(layer) * 1.4f,
                                                 -4.5f + float(iz) * 1.5f + float(rng.next_u32() % 20) * 0.01f};
                Collider3D& c = w.add<Collider3D>(e);
                const int kind = (ix + iz + layer) % 3;
                if (kind == 0) {
                    c.shape = ColliderShape3D::Sphere;
                    c.radius = 0.5f;
                } else if (kind == 1) {
                    c.shape = ColliderShape3D::Capsule;
                    c.radius = 0.35f;
                    c.height = 1.4f;
                } else {
                    c.size = {1, 1, 1};
                }
                RigidBody3D& rb = w.add<RigidBody3D>(e);
                rb.rollWithMotion = false;  // rigid bodies: the contacts spin them
            }
        }
    }
}

Bench physics_2d() {
    Bench b;
    b.name = "physics.step2d";
    b.summary = "Physics::step x60: 576 boxes and circles falling into a walled box (Box2D)";
    b.make = [] {
        auto sim = std::make_shared<Sim>();
        Prepared p;
        p.items = 576 * kSteps;
        p.unit = "body steps";
        p.prepare = [sim] {
            sim->reset();
            build_2d(*sim->world);
            sim->physics.sync(*sim->world);  // the bodies exist before the clock starts
        };
        p.run = [sim] { return sim->run_steps(kSteps); };
        return p;
    };
    return b;
}

Bench physics_3d() {
    Bench b;
    b.name = "physics.step3d";
    b.summary = "Physics::step x20: 196 spheres, capsules and boxes falling on a ground box (3D)";
    b.make = [] {
        auto sim = std::make_shared<Sim>();
        Prepared p;
        p.items = 196 * k3dSteps;
        p.unit = "body steps";
        p.prepare = [sim] {
            sim->reset();
            build_3d(*sim->world);
            sim->physics.sync(*sim->world);
        };
        p.run = [sim] { return sim->run_steps(k3dSteps); };
        return p;
    };
    return b;
}

}  // namespace

void add_physics_benches(std::vector<Bench>& out) {
    out.push_back(physics_2d());
    out.push_back(physics_3d());
}

}  // namespace fa::bench
