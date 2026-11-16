// The engine's occlusion probe (docs/SOUND.md, "Occlusion"): a ray from the listener to the source against the physics world, in 2D
// and 3D. Audio's own scheduling and smoothing are tested in engine/audio/tests/test_audio_doppler_occlusion.cpp.
#include <doctest.h>

#include "fa/runtime/audio_occlusion.h"

using namespace fa;

namespace {

struct Rig {
    World world;
    Physics physics;
    Rig() { physics.init(PhysicsSettings{}); }
    Entity wall3(const char* id, Vec3 at, Vec3 size = {1, 20, 20}) {
        Entity e = world.create(id, id);
        world.get<Transform>(e)->position = at;
        world.add<Collider3D>(e).size = size;
        return e;
    }
    Entity wall2(const char* id, Vec2 at, Vec2 size = {10, 200}) {
        Entity e = world.create(id, id);
        world.get<Transform>(e)->position = {at.x, at.y, 0};
        world.add<Collider2D>(e).size = size;
        return e;
    }
    bool blocked(Vec3 from, Vec3 to, Entity source = kNullEntity, Entity listener = kNullEntity,
                 std::int32_t mask = -1) {
        physics.sync(world);
        AudioOcclusionRay ray;
        ray.from = from;
        ray.to = to;
        ray.source = source;
        ray.listener = listener;
        ray.mask = mask;
        return audio_occlusion_blocked(physics, world, ray);
    }
};

}  // namespace

TEST_CASE("audio occlusion probe: a 3D collider between the listener and the source blocks, beside it does not") {
    Rig r;
    r.wall3("wall", {5, 0, 0});
    CHECK(r.blocked({0, 0, 0}, {10, 0, 0}));
    CHECK(r.blocked({10, 0, 0}, {0, 0, 0}));          // both ways
    CHECK_FALSE(r.blocked({0, 0, 0}, {3, 0, 0}));     // the source stops short of the wall
    CHECK_FALSE(r.blocked({0, 0, 30}, {10, 0, 30}));  // passes above the wall (it is 20 high and deep)
    CHECK_FALSE(r.blocked({0, 0, 0}, {0, 0, 0}));     // no distance, nothing in between
}

TEST_CASE("audio occlusion probe: a 2D collider blocks in a 2D game (x and y of the positions)") {
    Rig r;
    r.wall2("wall", {100, 0});
    CHECK(r.blocked({0, 0, 0}, {200, 0, 0}));
    CHECK_FALSE(r.blocked({0, 0, 0}, {50, 0, 0}));
    CHECK_FALSE(r.blocked({0, 300, 0}, {200, 300, 0}));  // above the wall (it is 200 high)
    CHECK_FALSE(r.blocked({150, 0, 0}, {200, 0, 0}));    // both on the same side
}

TEST_CASE("audio occlusion probe: the mask picks the layers that block") {
    Rig r;
    Entity w = r.wall3("wall", {5, 0, 0});
    r.world.get<Collider3D>(w)->layer = 3;
    CHECK(r.blocked({0, 0, 0}, {10, 0, 0}, kNullEntity, kNullEntity, 1 << 3));
    CHECK_FALSE(r.blocked({0, 0, 0}, {10, 0, 0}, kNullEntity, kNullEntity, 1 << 2));
    CHECK_FALSE(r.blocked({0, 0, 0}, {10, 0, 0}, kNullEntity, kNullEntity, 0));
    Entity w2 = r.wall2("wall2d", {100, 0});
    r.world.get<Collider2D>(w2)->layer = 5;
    CHECK(r.blocked({0, 0, 0}, {200, 0, 0}, kNullEntity, kNullEntity, 1 << 5));
    CHECK_FALSE(r.blocked({0, 0, 0}, {200, 0, 0}, kNullEntity, kNullEntity, 1 << 4));
}

TEST_CASE("audio occlusion probe: triggers, the source and the listener (and their children) never block") {
    Rig r;
    Entity trigger = r.wall3("trigger", {5, 0, 0});
    r.world.get<Collider3D>(trigger)->isTrigger = true;
    CHECK_FALSE(r.blocked({0, 0, 0}, {10, 0, 0}));

    Rig s;
    Entity src = s.wall3("source", {10, 0, 0}, {2, 2, 2});  // the source stands in its own collider
    CHECK_FALSE(s.blocked({0, 0, 0}, {10, 0, 0}, src));
    Entity wall = s.wall3("wall", {5, 0, 0});
    CHECK(s.blocked({0, 0, 0}, {10, 0, 0}, src));
    s.world.destroy_immediate(wall);
    CHECK_FALSE(s.blocked({0, 0, 0}, {10, 0, 0}, src));

    Rig l;  // the listener's own body and its child's collider are at the start of the ray
    Entity listener = l.wall3("listener", {0, 0, 0}, {2, 2, 2});
    Entity child = l.world.create("hat", "hat");
    l.world.set_parent(child, listener);
    l.world.add<Collider3D>(child).size = {4, 4, 4};
    CHECK_FALSE(l.blocked({0, 0, 0}, {10, 0, 0}, kNullEntity, listener));
    l.wall3("wall", {5, 0, 0});
    CHECK(l.blocked({0, 0, 0}, {10, 0, 0}, kNullEntity, listener));
}

TEST_CASE("audio occlusion probe: a disabled collider and a removed one let the sound through") {
    Rig r;
    Entity w = r.wall3("wall", {5, 0, 0});
    CHECK(r.blocked({0, 0, 0}, {10, 0, 0}));
    r.world.get<Collider3D>(w)->enabled = false;
    CHECK_FALSE(r.blocked({0, 0, 0}, {10, 0, 0}));
    r.world.get<Collider3D>(w)->enabled = true;
    CHECK(r.blocked({0, 0, 0}, {10, 0, 0}));
    r.world.destroy_immediate(w);
    CHECK_FALSE(r.blocked({0, 0, 0}, {10, 0, 0}));
}

TEST_CASE(
    "audio occlusion probe: a foreign collider around the listener lets the sound out, around the source it blocks") {
    Rig r;
    r.wall3("room", {0, 0, 0}, {6, 6, 6});  // the listener stands inside it
    CHECK_FALSE(r.blocked({0, 0, 0}, {2, 0, 0}));
    Rig s;
    s.wall3("room", {10, 0, 0}, {6, 6, 6});  // the source stands inside it, and it is not the source's entity
    CHECK(s.blocked({0, 0, 0}, {10, 0, 0}));
}
