// ECS and hierarchy benchmarks: World::each, entities_with, spawn / destroy, world_matrix.
#include <memory>

#include "benches.h"
#include "fa/core/math.h"
#include "fa/scene/components.h"
#include "fa/scene/world.h"

namespace fa::bench {

namespace {

constexpr int kEntities = 20000;

// A world with kEntities entities: all have Transform and Sprite, every fourth a RigidBody2D, every eighth a Collider2D too.
std::shared_ptr<World> make_populated_world() {
    ensure_builtin_components();
    auto w = std::make_shared<World>();
    Rng rng(1234);
    for (int i = 0; i < kEntities; ++i) {
        Entity e = w->create();
        Transform* t = w->get<Transform>(e);
        t->position = {float(rng.next_u32() % 2000) - 1000.0f, float(rng.next_u32() % 2000) - 1000.0f, 0};
        Sprite& s = w->add<Sprite>(e);
        s.color.a = 0.25f + float(rng.next_u32() % 4) * 0.25f;
        if (i % 4 == 0) w->add<RigidBody2D>(e).gravityScale = 1.0f + float(i % 3);
        if (i % 8 == 0) w->add<Collider2D>(e);
    }
    return w;
}

Bench ecs_each() {
    Bench b;
    b.name = "ecs.each";
    b.summary = "World::each over 20000 entities: all of them (2 components), a quarter of them (3 components), a quarter by its smallest pool";
    b.make = [] {
        auto w = make_populated_world();
        Prepared p;
        p.items = 16 * 27500;  // per pass: 20000 + 5000 + 2500
        p.unit = "entities walked";
        p.run = [w] {
            double sum = 0;
            for (int pass = 0; pass < 16; ++pass) {
                w->each<Transform, Sprite>([&](Entity, Transform& t, Sprite& s) { sum += t.position.x * s.color.a; });
                w->each<Sprite, RigidBody2D, Transform>(
                    [&](Entity, Sprite& s, RigidBody2D& rb, Transform& t) { sum += rb.gravityScale + s.color.a + t.position.y; });
                w->each<RigidBody2D, Collider2D>([&](Entity, RigidBody2D& rb, Collider2D& c) { sum += rb.gravityScale + c.friction; });
            }
            return sum;
        };
        return p;
    };
    return b;
}

Bench ecs_entities_with() {
    Bench b;
    b.name = "ecs.entities_with";
    b.summary = "World::entities_with(type) 200 times for a pool of 20000 and 200 times for one of 2500 (the snapshot is a copy)";
    b.make = [] {
        auto w = make_populated_world();
        Prepared p;
        p.items = 400;
        p.unit = "queries";
        p.run = [w] {
            std::size_t n = 0;
            for (int i = 0; i < 200; ++i) {
                n += w->entities_with(&World::type_of<Sprite>()).size();
                n += w->entities_with(&World::type_of<Collider2D>()).size();
            }
            return double(n);
        };
        return p;
    };
    return b;
}

Bench ecs_spawn_destroy() {
    Bench b;
    b.name = "ecs.spawn_destroy";
    b.summary = "Create 30000 entities with three components each, set their fields, destroy them all and flush";
    b.make = [] {
        ensure_builtin_components();
        auto w = std::make_shared<World>();
        Prepared p;
        p.items = 30000;
        p.unit = "entities";
        p.run = [w] {
            std::vector<Entity> made;
            made.reserve(30000);
            for (int i = 0; i < 30000; ++i) {
                Entity e = w->create();
                w->get<Transform>(e)->position = {float(i), float(i % 7), 0};
                w->add<Sprite>(e).color.r = 0.5f;
                w->add<Collider2D>(e).size = {8, 8};
                made.push_back(e);
            }
            double sum = double(w->entities_with(&World::type_of<Sprite>()).size());
            for (Entity e : made) w->destroy(e);
            w->flush();
            return sum + double(w->entities_with(&World::type_of<Sprite>()).size());
        };
        return p;
    };
    return b;
}

// ------------------------------------------------------------------------------------------------ hierarchy

Bench hierarchy_deep() {
    Bench b;
    b.name = "hierarchy.deep";
    b.summary = "World::world_matrix of every entity of a chain 400 deep (each one walks its whole parent chain)";
    b.make = [] {
        ensure_builtin_components();
        auto w = std::make_shared<World>();
        auto chain = std::make_shared<std::vector<Entity>>();
        Entity parent = kNullEntity;
        for (int i = 0; i < 400; ++i) {
            Entity e = w->create();
            Transform* t = w->get<Transform>(e);
            t->position = {1.0f, 0.5f, 0};
            t->rotation = {0, 0, 0.5f};
            if (!parent.is_null()) w->set_parent(e, parent);
            chain->push_back(e);
            parent = e;
        }
        Prepared p;
        p.items = 400 * 401 / 2;
        p.unit = "parent steps";
        p.run = [w, chain] {
            double sum = 0;
            for (int pass = 0; pass < 3; ++pass)
                for (Entity e : *chain) sum += w->world_matrix(e).m[12];
            return sum;
        };
        return p;
    };
    return b;
}

Bench hierarchy_wide() {
    Bench b;
    b.name = "hierarchy.wide";
    b.summary = "World::world_position of 20000 leaves of a tree 4 levels deep (30 x 30 x 22 below the root), 2 passes";
    b.make = [] {
        ensure_builtin_components();
        auto w = std::make_shared<World>();
        auto leaves = std::make_shared<std::vector<Entity>>();
        Rng rng(99);
        Entity root = w->create();
        for (int a = 0; a < 30; ++a) {
            Entity ea = w->create();
            w->get<Transform>(ea)->position = {float(a), 0, 0};
            w->set_parent(ea, root);
            for (int c = 0; c < 30; ++c) {
                Entity ec = w->create();
                Transform* tc = w->get<Transform>(ec);
                tc->position = {0, float(c), 0};
                tc->rotation = {0, 0, float(rng.next_u32() % 90)};
                w->set_parent(ec, ea);
                for (int d = 0; d < 22; ++d) {
                    Entity ed = w->create();
                    w->get<Transform>(ed)->position = {float(d), 1, 0};
                    w->set_parent(ed, ec);
                    leaves->push_back(ed);
                }
            }
        }
        Prepared p;
        p.items = std::int64_t(leaves->size()) * 2;
        p.unit = "leaves";
        p.run = [w, leaves] {
            double sum = 0;
            for (int pass = 0; pass < 2; ++pass)
                for (Entity e : *leaves) sum += w->world_position(e).x;
            return sum;
        };
        return p;
    };
    return b;
}

}  // namespace

void add_ecs_benches(std::vector<Bench>& out) {
    out.push_back(ecs_each());
    out.push_back(ecs_entities_with());
    out.push_back(ecs_spawn_destroy());
}

void add_hierarchy_benches(std::vector<Bench>& out) {
    out.push_back(hierarchy_deep());
    out.push_back(hierarchy_wide());
}

}  // namespace fa::bench
