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
//
// Conventions
//   * Bodies use WORLD transforms (parents included); Transform.scale (x,y) scales colliders. Transform
//     changes made by gameplay since the last step teleport the body (also for static colliders).
//     Inactive entities (active_in_hierarchy == false) have their body disabled.
//   * Collider2D.layer is the category bit (1 << layer), mask the accepted categories (-1 = all). Triggers
//     (isTrigger) are sensors: they never collide, and are invisible to raycasts; overlap_* queries DO report
//     them. Sensors only detect non-sensor shapes (two triggers never report each other).
//   * Events: contact begin/end (trigger=false, impulse = approach speed in world units/s) and sensor
//     begin/end (trigger=true; a = the trigger, b = the visitor). Tilemap tiles do not generate trigger events.
//   * TILEMAP: Tilemap.solidTiles => static boxes (horizontal runs per row merged, equal consecutive rows
//     merged too). The Tilemap entity's world position is the map's TOP-LEFT corner, +Y up, row 0 = top row:
//     tile (col,row) covers x in [px + col*tw, px + (col+1)*tw], y in [py - (row+1)*th, py - row*th]
//     (tw,th = tileSize * world scale). The renderer must draw tilemaps with the same convention, and both read the map
//     through tilemap_grid() (fa/scene/tilemap.h): an array of rows defines its own size, a flat list uses width/height.
//   * apply_impulse/apply_force take world units (impulse / ppm is passed to Box2D); mass comes from
//     collider area (meters^2) * density.
//   * RAYCASTS: a collider that contains the ray origin is skipped (see RaycastOptions); `ignore` skips an entity and
//     its children; triggers are skipped unless ignoreTriggers=false.
//   * ONE-WAY PLATFORMS (Collider2D.oneWay): contact enabled only while the other body's bottom is above the
//     platform's top and it is not moving up relative to it (Box2D pre-solve; world runs single-threaded).
//     Assumes the platform is unrotated or flipped 180 degrees (flipped = one-way from below). Sides never block.
//   * TILEMAP COLLISION: every tile index listed in Tilemap.solidTiles becomes part of ONE static body per Tilemap
//     entity, as axis-aligned boxes: each row's horizontal runs of solid tiles are merged into one box, and
//     identical runs in consecutive rows are merged into one taller box. Shapes: layer 0 (category bit 1), mask = all,
//     friction 0.5, restitution 0, not triggers (no trigger events from tiles). Tile boxes are not one-way: for
//     jump-through ledges put a separate entity with Collider2D.oneWay on top of the map instead of a solid tile
//     index. Merging can leave seams between boxes of different row spans (possible ghost contacts for
//     friction > 0 characters sliding along them); give characters friction 0 against walls, or use a capsule/circle
//     foot. The tilemap body follows the Tilemap entity's world transform.
//   * is_grounded2d: any touching contact whose normal points up (> 0.7) with a gap <= tolerance (pixels).
//   * 3D: spheres + axis-aligned boxes only. Transform.rotation is IGNORED (never read or written); sizes are
//     scaled by world scale. Semi-implicit Euler with subSteps sub-steps, positional correction, restitution
//     (ignored below 0.5 m/s) and Coulomb friction; no continuous collision (very fast bodies can tunnel).
//     Bodies are processed in creation order => deterministic. Dynamic bodies need a RigidBody3D; a Collider3D
//     alone is static. 3D events: contact begin/end between solid colliders (within 1 cm) and trigger overlaps.
//     Impulse = approach speed (m/s). Kinematic bodies follow RigidBody3D.velocity and push dynamic bodies.
//   * 3D RIDERS: dynamic bodies resting on top of a kinematic body (gap <= 2 cm, contact normal up) inherit its
//     displacement every sub-step (horizontal; and downward), so they ride moving platforms; friction then acts
//     on the velocity RELATIVE to the platform. A static/kinematic body teleported by gameplay carries its riders
//     by the same displacement. Stacked riders (rider on a rider) are not carried.
//   * 3D ROTATION: RigidBody3D.angularVelocity (deg/s about world x,y,z) is added to Transform.rotation (euler
//     degrees) each step for dynamic and kinematic bodies. Collision shapes stay AXIS-ALIGNED and ignore the
//     rotation; it is visual only. rollWithMotion: a dynamic sphere touching ground (contact normal up) gets
//     angularVelocity = rolling rate: axis = up x velocity, rate = |horizontal v| / radius (deg/s).
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

// Options for raycast2d/raycast3d.
//   * mask: layers the ray can hit (-1 = all).
//   * ignore: entity whose colliders (and its descendants' colliders) are skipped; use the caster itself.
//   * ignoreTriggers: trigger colliders are skipped (default); set false to hit them too.
// Colliders that CONTAIN the ray origin are always skipped (a ray cast from inside the caster does not hit it);
// a ray starting inside the ground ignores the ground.
struct RaycastOptions {
    std::int32_t mask = -1;
    Entity ignore;  // default = none
    bool ignoreTriggers = true;
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
    // Create/update/destroy bodies to match the components WITHOUT simulating. step() does this itself;
    // the engine also calls it after scene loads and before scripts' fixed update so freshly spawned
    // entities can be ray-cast / queried in the same frame.
    void sync(World& world);

    // ----- queries (world units; 2D queries ignore z)
    std::optional<RaycastHit> raycast2d(World& world, Vec2 from, Vec2 to, std::int32_t mask = -1);
    std::optional<RaycastHit> raycast2d(World& world, Vec2 from, Vec2 to, const RaycastOptions& options);
    std::vector<Entity> overlap_circle2d(World& world, Vec2 center, float radius, std::int32_t mask = -1);
    std::vector<Entity> overlap_box2d(World& world, Rect box, std::int32_t mask = -1);
    std::optional<RaycastHit> raycast3d(World& world, Vec3 origin, Vec3 dir, float maxDistance, std::int32_t mask = -1);
    std::optional<RaycastHit> raycast3d(World& world, Vec3 origin, Vec3 dir, float maxDistance,
                                        const RaycastOptions& options);
    std::vector<Entity> overlap_sphere3d(World& world, Vec3 center, float radius, std::int32_t mask = -1);

    // ----- direct body control (applied immediately if the body exists)
    void apply_impulse(World& world, Entity e, Vec3 impulse);  // 2D uses x,y
    void apply_force(World& world, Entity e, Vec3 force);
    void set_velocity(World& world, Entity e, Vec3 velocity);
    bool is_grounded2d(World& world, Entity e, float tolerance = 2.0f);  // contact with a normal pointing up
    // Dispatches to 2D (tolerance in pixels, default 2) or 3D (tolerance in meters, default 0.05) by the body's
    // dimension. tolerance < 0 = that default. False if the entity has no body.
    bool is_grounded(World& world, Entity e, float tolerance = -1.0f);
    // Is there a solid contact against the body in `direction` (the obstacle lies that way)? 2D: {-1,0} wall left,
    // {1,0} wall right, {0,-1} ground, {0,1} ceiling (pixels, default 2). Contact normal within ~45 degrees of
    // the direction. Triggers never count. Ledge detection is a raycast pattern: cast a short ray DOWN from a
    // point just ahead of the feet (x + sign * halfWidth, y - halfHeight + 2) and treat "no hit" as a ledge.
    bool is_touching2d(World& world, Entity e, Vec2 direction, float tolerance = 2.0f);
    // 3D equivalent (tolerance in meters; any direction, normalized internally).
    bool is_touching3d(World& world, Entity e, Vec3 direction, float tolerance = 0.05f);

    // Debug: list of bodies and shapes (for the editor / AI inspection).
    Json debug_state(const World& world) const;
    struct DebugShape { enum Kind { Box, Circle, Sphere } kind; Vec3 center; Vec3 size; float rotation; bool trigger; };
    std::vector<DebugShape> debug_shapes(const World& world) const;

    struct Impl;

private:
    std::unique_ptr<Impl> impl_;
};

}  // namespace fa
