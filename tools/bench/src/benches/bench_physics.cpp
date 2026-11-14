// Physics benchmarks: one second (60 steps) of a pile of falling bodies in 2D (Box2D) and in 3D (the engine's own solver).
#include <cmath>
#include <format>
#include <memory>
#include <vector>

#include "benches.h"
#include "fa/core/math.h"
#include "fa/physics/physics.h"
#include "fa/scene/components.h"
#include "fa/scene/tilemap.h"
#include "fa/scene/world.h"

namespace fa::bench {

namespace {

constexpr float kDt = 1.0f / 60.0f;
constexpr int kSteps = 60;
constexpr int k3dSteps = 20;     // the 3D solver costs more per body
constexpr int k3dPitSteps = 10;  // 1000 bodies: the first steps of the fall, then the first impacts

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

// 1000 spheres, capsules and boxes (one every 1.4 m in layers of 10 x 10) falling into a pit of four walls and a floor.
void build_pit_3d(World& w) {
    auto wall = [&](Vec3 pos, Vec3 size) {
        Entity e = w.create();
        w.get<Transform>(e)->position = pos;
        w.add<Collider3D>(e).size = size;  // no RigidBody3D: static
    };
    wall({0, -0.5f, 0}, {30, 1, 30});
    wall({-15.5f, 5, 0}, {1, 12, 32});
    wall({15.5f, 5, 0}, {1, 12, 32});
    wall({0, 5, -15.5f}, {32, 12, 1});
    wall({0, 5, 15.5f}, {32, 12, 1});
    Rng rng(94);
    for (int i = 0; i < 1000; ++i) {
        const int layer = i / 100, k = i % 100;
        Entity e = w.create();
        w.get<Transform>(e)->position = {-6.3f + 1.4f * float(k % 10) + 0.01f * float(rng.next_u32() % 20),
                                         0.8f + 1.3f * float(layer),
                                         -6.3f + 1.4f * float(k / 10) + 0.01f * float(rng.next_u32() % 20)};
        Collider3D& c = w.add<Collider3D>(e);
        if (i % 3 == 0) {
            c.shape = ColliderShape3D::Sphere;
            c.radius = 0.5f;
        } else if (i % 3 == 1) {
            c.shape = ColliderShape3D::Capsule;
            c.radius = 0.3f;
            c.height = 1.2f;
        } else {
            c.size = {0.9f, 0.9f, 0.9f};
        }
        w.add<RigidBody3D>(e);
    }
}

// The others are dropped from a height they reach after 90 steps (1.5 s: what the pile needs to fall asleep), so they land
// during the timed steps.
constexpr int kMostlyAsleepWarmup = 90;
constexpr float kMostlyAsleepDrop = 12.3f;

// 1000 unit boxes (25 x 20 per layer, two layers, touching) resting on a big floor, and `awake` bodies (spheres, capsules and
// boxes) 30 m away that fall onto the same floor. The pile falls asleep within a second; the others do not.
void build_mostly_asleep_3d(World& w, int awake, int pile = 1000) {
    Entity floor = w.create();
    w.get<Transform>(floor)->position = {0, -0.5f, 0};
    w.add<Collider3D>(floor).size = {200, 1, 200};
    for (int i = 0; i < pile; ++i) {
        const int layer = i / 500, k = i % 500;
        Entity e = w.create();
        w.get<Transform>(e)->position = {-12.0f + float(k % 25), 0.5f + float(layer), -10.0f + float(k / 25)};
        w.add<Collider3D>(e).size = {1, 1, 1};
        w.add<RigidBody3D>(e);
    }
    for (int i = 0; i < awake; ++i) {
        Entity e = w.create();
        w.get<Transform>(e)->position = {30.0f + 2.0f * float(i % 10), kMostlyAsleepDrop + 0.4f * float(i % 4),
                                         2.0f * float(i / 10)};
        Collider3D& c = w.add<Collider3D>(e);
        if (i % 3 == 0) {
            c.shape = ColliderShape3D::Sphere;
            c.radius = 0.5f;
        } else if (i % 3 == 1) {
            c.shape = ColliderShape3D::Capsule;
            c.radius = 0.3f;
            c.height = 1.2f;
        } else {
            c.size = {0.9f, 0.9f, 0.9f};
        }
        w.add<RigidBody3D>(e);
    }
}

// A column of 100 boxes with a 2 cm gap each on a static floor.
void build_stack_3d(World& w) {
    Entity ground = w.create();
    w.get<Transform>(ground)->position = {0, -0.5f, 0};
    w.add<Collider3D>(ground).size = {20, 1, 20};
    for (int i = 0; i < 100; ++i) {
        Entity e = w.create();
        w.get<Transform>(e)->position = {0, 0.5f + 1.02f * float(i), 0};
        w.add<Collider3D>(e).size = {1, 1, 1};
        w.add<RigidBody3D>(e);
    }
}

Bench physics_3d_pit() {
    Bench b;
    b.name = "physics.step3d_1000";
    b.summary = "Physics::step x10: 1000 spheres, capsules and boxes falling into a walled pit (3D)";
    b.make = [] {
        auto sim = std::make_shared<Sim>();
        Prepared p;
        p.items = 1000 * k3dPitSteps;
        p.unit = "body steps";
        p.prepare = [sim] {
            sim->reset();
            build_pit_3d(*sim->world);
            sim->physics.sync(*sim->world);
        };
        p.run = [sim] { return sim->run_steps(k3dPitSteps); };
        return p;
    };
    return b;
}

// The pile is put to sleep before the timed steps (not timed): what is measured is a world of sleeping bodies with a few
// awake ones elsewhere. The sleeping bodies must cost (almost) nothing: the step takes about what the awake ones alone take.
Bench physics_3d_mostly_asleep(int pile, const char* name) {
    Bench b;
    b.name = name;
    b.summary = std::format("Physics::step x{}: {} sleeping boxes in a pile and 20 bodies falling elsewhere (3D)",
                            k3dSteps, pile);
    b.make = [pile] {
        auto sim = std::make_shared<Sim>();
        Prepared p;
        p.items = 20 * k3dSteps;
        p.unit = "awake body steps";
        p.prepare = [sim, pile] {
            sim->reset();
            build_mostly_asleep_3d(*sim->world, 20, pile);
            sim->physics.sync(*sim->world);
            for (int i = 0; i < kMostlyAsleepWarmup; ++i) {  // the pile sleeps while the others are still falling
                sim->world->events().clear();
                sim->physics.step(*sim->world, kDt);
                sim->world->advance_clock(kDt);
                sim->world->flush();
            }
        };
        p.run = [sim] { return sim->run_steps(k3dSteps); };
        return p;
    };
    return b;
}

Bench physics_3d_stack() {
    Bench b;
    b.name = "physics.step3d_stack100";
    b.summary = "Physics::step x60: a column of 100 boxes dropped on a floor (3D)";
    b.make = [] {
        auto sim = std::make_shared<Sim>();
        Prepared p;
        p.items = 100 * kSteps;
        p.unit = "body steps";
        p.prepare = [sim] {
            sim->reset();
            build_stack_3d(*sim->world);
            sim->physics.sync(*sim->world);
        };
        p.run = [sim] { return sim->run_steps(kSteps); };
        return p;
    };
    return b;
}

// A `n` x `n` Tilemap with a solid platform of 15 tiles every 16 columns on every 8th row (256 x 256: 65536 cells, 512 boxes).
void build_tilemap_2d(World& w, int n = 256) {
    Entity e = w.create();
    Tilemap& tm = w.add<Tilemap>(e);
    tm.tileSize = {16, 16};
    tm.solidTiles = Json::array({1});
    std::vector<int> tiles(std::size_t(n) * std::size_t(n), -1);
    for (int r = 7; r < n; r += 8)
        for (int c = 0; c < n; ++c)
            if (c % 16 != 15) tiles[std::size_t(r) * std::size_t(n) + std::size_t(c)] = 1;
    set_tilemap_grid(tm, n, n, tiles);
}

// One cell of a large map changes, then the 2D physics steps and brings its colliders up to date: the cost follows the
// number of edits, not the 65536 cells of the map (the array's version and the edits say what was written).
Bench physics_tilemap_edit(int n) {
    Bench b;
    b.name = n == 256 ? "physics.tilemap_edit" : "physics.tilemap_edit_large";
    b.summary = std::format(
        "set_tilemap_tile + Physics::step x40: one cell of a {0} x {0} Tilemap changes per step (2D collision)", n);
    b.warnRatio =
        2.5;  // a run lasts a fraction of a millisecond: the clock and a busy machine move it more than the work
    b.failRatio = 6.0;
    b.make = [n] {
        auto sim = std::make_shared<Sim>();
        Prepared p;
        p.items = 40;
        p.unit = "cell edits";
        p.prepare = [sim, n] {
            sim->reset();
            build_tilemap_2d(*sim->world, n);
            sim->physics.sync(*sim->world);  // the colliders exist before the clock starts
            sim->run_steps(2);
        };
        p.run = [sim, n] {
            Entity map = sim->world->entities_with(&World::type_of<Tilemap>()).front();
            Tilemap& tm = *sim->world->get<Tilemap>(map);
            double sum = 0;
            for (int i = 0; i < 40; ++i) {
                // a platform tile appears or goes away: row 15 + 8k, column 3 + 16 * (i % (n / 16))
                const int col = 3 + 16 * (i % (n / 16)), row = 15 + 8 * (i / (n / 16));
                const int now = tilemap_tile_at(tm, tilemap_size(tm), col, row);
                set_tilemap_tile(tm, col, row, now == 1 ? -1 : 1);
                sum += sim->run_steps(1);
            }
            return sum + double(tm.tiles.version());
        };
        return p;
    };
    return b;
}

// A `side` x `side` heightfield (cells of 0.5 m, rolling hills up to 0.8 m) with `bodies` spheres, capsules and boxes
// dropped on it from 2 to 6 m. `lock` makes the spheres and capsules slide instead of roll, so they stay where they land
// and fall asleep (the edit bench).
void build_heightfield_3d(World& w, int side, int bodies, bool lock) {
    Entity f = w.create();
    w.add<Collider3D>(f).shape = ColliderShape3D::Heightfield;
    Heightfield3D& g = w.add<Heightfield3D>(f);
    g.rows = side;
    g.columns = side;
    g.cellSize = {0.5f, 0.5f};
    std::vector<float> h(std::size_t(side) * std::size_t(side));
    for (int r = 0; r < side; ++r)
        for (int c = 0; c < side; ++c)
            h[std::size_t(r) * std::size_t(side) + std::size_t(c)] =
                0.8f * std::sin(0.15f * float(c)) * std::cos(0.12f * float(r));
    g.heights.assign(h.data(), h.size());
    Rng rng(2024);
    auto unit = [&] { return float(rng.next_u32() >> 8) / float(1u << 24); };
    const float half = 0.0625f * float(side - 1);  // the bodies start over the middle eighth of the field
    for (int i = 0; i < bodies; ++i) {
        Entity e = w.create();
        const float x = (unit() * 2.0f - 1.0f) * half, z = (unit() * 2.0f - 1.0f) * half;
        w.get<Transform>(e)->position = {x, 2.0f + 4.0f * unit() + 0.8f, z};
        Collider3D& c = w.add<Collider3D>(e);
        RigidBody3D& rb = w.add<RigidBody3D>(e);
        if (i % 3 == 0) {
            c.shape = ColliderShape3D::Sphere;
            c.radius = 0.4f;
            rb.lockRotation = lock;
            rb.rollWithMotion = !lock;
        } else if (i % 3 == 1) {
            c.shape = ColliderShape3D::Capsule;
            c.radius = 0.3f;
            c.height = 1.2f;
            rb.lockRotation = lock;
        } else {
            c.size = {0.8f, 0.8f, 0.8f};
        }
    }
}

// 200 bodies fall onto a 256 x 256 field of hills and roll around on it.
Bench physics_heightfield_step() {
    Bench b;
    b.name = "physics.heightfield_step";
    b.summary = std::format(
        "Physics::step x{}: 200 spheres, capsules and boxes falling onto a 256 x 256 heightfield (3D)", k3dSteps);
    b.make = [] {
        auto sim = std::make_shared<Sim>();
        Prepared p;
        p.items = 200 * k3dSteps;
        p.unit = "body steps";
        p.prepare = [sim] {
            sim->reset();
            build_heightfield_3d(*sim->world, 256, 200, false);
            sim->physics.sync(*sim->world);  // the grid is read before the clock starts
            sim->run_steps(30);              // the first bodies are down and in contact
        };
        p.run = [sim] { return sim->run_steps(k3dSteps); };
        return p;
    };
    return b;
}

// One sample of a 256 x 256 field changes per step (a brush stroke), with 100 sleeping bodies on it: the cost follows what
// the edit touches, not the 65536 samples.
Bench physics_heightfield_edit() {
    Bench b;
    b.name = "physics.heightfield_edit";
    b.summary = "Heightfield3D.heights.set + Physics::step x40: one height of a 256 x 256 field changes per step (3D "
                "collision)";
    b.warnRatio =
        2.5;  // a run lasts a fraction of a millisecond: the clock and a busy machine move it more than the work
    b.failRatio = 6.0;
    b.make = [] {
        auto sim = std::make_shared<Sim>();
        Prepared p;
        p.items = 40;
        p.unit = "height edits";
        p.prepare = [sim] {
            sim->reset();
            build_heightfield_3d(*sim->world, 256, 100, true);
            sim->physics.sync(*sim->world);
            sim->run_steps(300);  // the bodies land and fall asleep
        };
        p.run = [sim] {
            Entity field = sim->world->entities_with(&World::type_of<Heightfield3D>()).front();
            Heightfield3D& g = *sim->world->get<Heightfield3D>(field);
            double sum = 0;
            for (int i = 0; i < 40; ++i) {
                const std::size_t at =
                    std::size_t(20 + 5 * i) * 256 + std::size_t(31 + 5 * i);  // a stroke across the field
                g.heights.set(at, g.heights.cdata()[at] + 0.05f);             // cdata: reading does not dirty the array
                sum += sim->run_steps(1);
            }
            return sum + double(g.heights.version());
        };
        return p;
    };
    return b;
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

// Scene queries in a world of 1000 bodies that has settled (most of them asleep): the queries must not walk every body.
// The world is built once (the queries do not change it).
enum class QueryKind { Rays, Overlaps };
Bench physics_3d_queries(QueryKind kind) {
    const bool rays = kind == QueryKind::Rays;
    constexpr int kRays = 10000, kOverlaps = 2000;
    Bench b;
    b.name = rays ? "physics.raycast3d_1000" : "physics.overlap3d_1000";
    b.summary =
        rays ? std::format("Physics::raycast3d x{}: rays through a settled pile of 1000 bodies (3D)", kRays)
             : std::format("Physics::overlap_sphere3d x{}: spheres of 1.5 m in a settled pile of 1000 bodies (3D)",
                           kOverlaps);
    b.make = [rays] {
        auto sim = std::make_shared<Sim>();
        auto built = std::make_shared<bool>(false);
        Prepared p;
        p.items = rays ? kRays : kOverlaps;
        p.unit = rays ? "rays" : "overlap queries";
        p.prepare = [sim, built] {
            if (*built) return;
            *built = true;
            sim->reset();
            build_pit_3d(*sim->world);
            sim->physics.sync(*sim->world);
            sim->run_steps(240);  // the pile lands and falls asleep
        };
        p.run = [sim, rays] {
            Rng rng(7);
            auto unit = [&] { return float(rng.next_u32() >> 8) / float(1u << 24); };
            double sum = 0.0;
            if (rays) {
                for (int i = 0; i < kRays; ++i) {  // from above and from the sides, towards the middle of the pit
                    const Vec3 from = i % 2 == 0 ? Vec3{-14.0f + 28.0f * unit(), 14.0f, -14.0f + 28.0f * unit()}
                                                 : Vec3{-20.0f, 4.0f * unit(), -14.0f + 28.0f * unit()};
                    const Vec3 to{-7.0f + 14.0f * unit(), 4.0f * unit(), -7.0f + 14.0f * unit()};
                    if (auto h = sim->physics.raycast3d(*sim->world, from, to - from, 40.0f, -1)) sum += h->distance;
                }
            } else {
                for (int i = 0; i < kOverlaps; ++i) {
                    const Vec3 c{-8.0f + 16.0f * unit(), 6.0f * unit(), -8.0f + 16.0f * unit()};
                    sum += double(sim->physics.overlap_sphere3d(*sim->world, c, 1.5f, -1).size());
                }
            }
            return sum;
        };
        return p;
    };
    return b;
}

}  // namespace

void add_physics_benches(std::vector<Bench>& out) {
    out.push_back(physics_2d());
    out.push_back(physics_3d());
    out.push_back(physics_3d_pit());
    out.push_back(physics_3d_stack());
    out.push_back(physics_3d_mostly_asleep(1000, "physics.step3d_mostly_asleep"));
    out.push_back(physics_3d_queries(QueryKind::Rays));
    out.push_back(physics_3d_queries(QueryKind::Overlaps));
    out.push_back(physics_tilemap_edit(256));
    out.push_back(physics_tilemap_edit(512));
    out.push_back(physics_heightfield_step());
    out.push_back(physics_heightfield_edit());
}

}  // namespace fa::bench
