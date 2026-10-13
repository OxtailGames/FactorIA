// Physics: 2D (Box2D v3) and simple 3D (spheres + axis-aligned boxes).
//
// Each fixed step:
//   physics.step(world, dt)
//     1. creates/updates/destroys bodies for entities with RigidBody2D/3D and
//        Collider2D/3D (entities with a collider but no body are static);
//        Tilemap.solidTiles generate static boxes.
//     2. pushes RigidBody*.velocity written by scripts into the solver,
//        teleports bodies whose Transform was moved by gameplay code.
//     3. steps the simulation (2D sub-steps = 4).
//     4. writes back Transform (position + rotation.z) and velocity.
//     5. appends CollisionEvents (begin/end, triggers) to world.events().
// 2D units: world units (pixels) are converted with pixelsPerMeter internally,
// so gameplay never sees meters.
#pragma once

#include <memory>
#include <optional>
#include <vector>

#include "fa/core/json.h"
#include "fa/core/math.h"
#include "fa/scene/world.h"

namespace fa {

struct PhysicsSettings {
    float pixelsPerMeter = 100.0f;  // 2D scale (Box2D works best with 0.1..10 m objects)
    int subSteps = 4;
};

struct RaycastHit {
    Entity entity;
    Vec3 point;
    Vec3 normal;
    float distance = 0.0f;  // from ray origin, world units
};

class Physics {
public:
    Physics();
    ~Physics();

    void init(const PhysicsSettings& settings);
    void shutdown();
    void reset();  // drop all bodies (scene change)

    void step(World& world, float dt);

    // ----- queries (world units; 2D queries ignore z)
    std::optional<RaycastHit> raycast2d(World& world, Vec2 from, Vec2 to, std::int32_t mask = -1);
    std::vector<Entity> overlap_circle2d(World& world, Vec2 center, float radius, std::int32_t mask = -1);
    std::vector<Entity> overlap_box2d(World& world, Rect box, std::int32_t mask = -1);
    std::optional<RaycastHit> raycast3d(World& world, Vec3 origin, Vec3 dir, float maxDistance, std::int32_t mask = -1);
    std::vector<Entity> overlap_sphere3d(World& world, Vec3 center, float radius, std::int32_t mask = -1);

    // ----- direct body control (applied immediately if the body exists)
    void apply_impulse(World& world, Entity e, Vec3 impulse);  // 2D uses x,y
    void apply_force(World& world, Entity e, Vec3 force);
    void set_velocity(World& world, Entity e, Vec3 velocity);
    bool is_grounded2d(World& world, Entity e, float tolerance = 2.0f);  // contact with a normal pointing up

    // Debug: list of bodies and shapes (for the editor / AI inspection).
    Json debug_state(const World& world) const;
    struct DebugShape { enum Kind { Box, Circle, Sphere } kind; Vec3 center; Vec3 size; float rotation; bool trigger; };
    std::vector<DebugShape> debug_shapes(const World& world) const;

    struct Impl;

private:
    std::unique_ptr<Impl> impl_;
};

}  // namespace fa
