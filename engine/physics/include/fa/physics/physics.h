// Physics: 2D (Box2D v3) and simple 3D (spheres + oriented boxes).
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
//     changes made by gameplay since the last step teleport the body (also for static colliders). A teleport wakes
//     the body and every body touching it, so a body that fell asleep falls again from its new place, and bodies
//     asleep on a platform that was moved away do not hover; isGrounded() reflects the new place after one step.
//     Inactive entities (active_in_hierarchy == false) have their body disabled.
//   * An entity marked by World::destroy() (pending_destroy) is gone for physics at once, although the world erases it
//     only at flush(): its body is removed at the next sync/step and queries, contacts and events already ignore it.
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
//   * SHAPE CASTS (2D): b2World_CastShape with proxies built to stop ON the surface (raw Box2D stops a box 0.5 cm
//     short of a wall and a circle 0.5 cm inside it). A collider the shape penetrates by more than 1 cm at `from` is
//     skipped; one it only touches (resting contact) blocks the cast, at distance 0, only when the shape moves towards
//     it. Tile boxes are reported as the Tilemap entity, like raycasts. Rotated colliders give the face normal.
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
//   * 3D: spheres + ORIENTED boxes. A box follows the entity's WORLD rotation (Transform.rotation with parents; the
//     basis columns are normalised, so scale only sizes the box) and its Collider3D.offset is rotated and scaled with the
//     entity. Box vs sphere clamps the sphere centre in the box frame; box vs box is a 15-axis SAT whose contact normal
//     is the minimum-penetration axis. Queries (raycast3d, overlap_sphere3d, shape_cast3d, is_touching3d), riders,
//     events and debug output all use the oriented shape (read from the Transform in sync(), so a spin applied by
//     angularVelocity shows in queries from the next sync() on). An unrotated box takes an exact axis-aligned fast path.
//     Semi-implicit Euler with subSteps sub-steps, positional correction, restitution (ignored below 0.5 m/s) and
//     Coulomb friction. Bodies are processed in creation order => deterministic. Dynamic bodies need a RigidBody3D; a
//     Collider3D alone is static. 3D events: contact begin/end between solid colliders (within 1 cm) and trigger
//     overlaps. Impulse = approach speed (m/s). Kinematic bodies follow RigidBody3D.velocity and push dynamic bodies.
//   * 3D SHAPES (Collider3D.shape): Box, Sphere, CAPSULE (radius + height tip to tip along the entity's local Y, so it
//     rotates with the entity), CONVEX (the convex hull of the vertices of Collider3D.mesh: a primitive name or a
//     .gltf/.glb path, read without the GPU by fa_scene's load_mesh_geometry, cached by name; clouds over 256 points are
//     reduced to the 256 extreme points of well-spread directions) and MESH (the triangles of Collider3D.mesh, STATIC
//     ONLY: a dynamic or kinematic body with a mesh collider is reported as a teaching problem, logged once, shown in
//     debug_state["problem"] and Physics::problems3d(), and its collider is ignored). Box and Sphere keep their exact
//     code; Capsule, Convex and Mesh ("general" shapes) are convex cores (a point, a segment or a hull) plus a rounding
//     radius, tested with GJK distance (EPA when the cores overlap, plane normal for a flat triangle). A mesh is split
//     into triangles by a BVH (median split, 4 triangles per leaf) so only the triangles near the other shape are
//     tested, and rays walk the BVH. Rigid-body contacts of general shapes are manifolds like boxes: a capsule lying
//     flat gets two end points, a box or hull on a mesh gets its low corners ray-probed onto the surface, everything
//     else one point; a dynamic capsule/convex has the bounding-box inertia and its origin is its centre of mass.
//     Rays against a capsule/convex use sphere tracing over GJK (a ray grazing under ~3 degrees may miss); mesh rays are
//     exact (Moller-Trumbore). Every shape works with contacts against every other shape, raycast3d, shape_cast3d,
//     overlap_sphere3d, is_touching3d, CCD, sleeping, events and debug_shapes/debug_state (Capsule / Convex / Mesh kinds).
//   * 3D JOINTS (Joint3D on an entity with RigidBody3D + Collider3D): Hinge, Ball or Fixed between that body and
//     Joint3D.connected (empty = the world). Anchors are local points (autoAnchor derives the connected one from the
//     current pose); a hinge has an axis, optional limits (degrees, relative to the pose the joint was created in) and an
//     optional motor (degrees/s, torque limit). A point constraint (3x3 effective-mass inverse, Baumgarte feedback; in a
//     chain the error is removed by moving the bodies instead) plus angular rows are solved in the same sequential-impulse
//     loop as the contacts, linearised and warm started each sub-step, so a pendulum keeps its physical period.
//     Joint3D.angle (degrees) is written back. Bodies that are part of a joint always turn (rotating rigid bodies) and
//     sleep as a group (JOINT ISLANDS); collideConnected=false (default) stops the pair from colliding. Jointed bodies are processed in creation order => deterministic. A joint that cannot be built (no body,
//     itself, a connected entity without a body) is a teaching problem like a bad mesh collider.
//   * NAVIGATION (NavMesh3D, nav.h): the STATIC 3D colliders inside the component's box (no RigidBody3D or a static one,
//     not triggers, not Collider3D.navObstacle) are rasterised into a 2.5D grid of cellSize cells holding the walkable
//     surfaces of each column: ground not steeper than maxSlope, with agentHeight of room above it, at least agentRadius
//     from a wall or a drop (erosion by distance over the links), joined to the neighbour cells within stepHeight (8
//     directions, no corner cutting). Boxes are covered exactly (any overlap of a cell counts, so thin walls are never
//     missed); other shapes are sampled 3x3 per cell with vertical rays, so a wall thinner than half a cell can be
//     missed. Baked by sync()/step() when a mesh has none or its static colliders changed (autoBake), or by nav_bake.
//     Colliders with navObstacle are not baked: wherever they are now (checked every sync/step with a pose signature, only
//     the cells they covered and cover are re-marked) they block the spans in reach of their footprint plus the radius.
//     Searches are A* with total tie-breaks and string pulling: same input, same path.
//   * 3D CHARACTER CONTROLLER (CharacterController3D): a kinematic capsule (radius, height, centre, stepOffset,
//     slopeLimit degrees, skin) moved by Physics::move_character (script: physics.moveCharacter) or by its `velocity`
//     field every step. Collide-and-slide: the capsule is swept like shape_cast3d, stops a skin short of what it hits
//     and slides the rest along the surface (up to 5 times). A wall that is a step (<= stepOffset) is climbed (lift,
//     forward at least 0.7 radius, drop); a surface steeper than slopeLimit acts as a wall (not climbed); going down it
//     snaps back onto the ground (stepOffset + skin). On a walkable slope the walk follows the surface, so horizontal
//     speed is kept. Result: position, moved, isGrounded, groundNormal, ground, hitWall, hitCeiling (also in
//     CharacterController3D.isGrounded / groundNormal). Dynamic bodies in the way get the character's speed times
//     pushStrength (a push; never a body held by a Joint3D). A kinematic body the character stands on (gap <= skin +
//     4 cm, contact normal up) CARRIES it every step: its displacement (velocity or a script teleport), and the turn of
//     its angularVelocity about the platform's centre (the character yaws with it); carriedByPlatforms=false turns that
//     off. Standing on a dynamic body it presses on it with mass * gravity at its feet (applyWeight), so a seesaw tips.
//     The controller has no gravity (the script adds its own); riders on top of it (dynamic bodies) are carried by it.
//     Other bodies see it as a kinematic capsule.
//   * 3D ROTATION DYNAMICS: a dynamic BOX, or a dynamic SPHERE with RigidBody3D.rollWithMotion off, without
//     RigidBody3D.lockRotation is a rigid body. Its inertia tensor is the solid box's (diagonal in the box frame from the
//     scaled size and mass, rotated into the world through the orientation) or the solid sphere's (2/5 m r^2 about every
//     axis), contacts are manifolds (the touching face clipped to the other box's face: up to 8 points; edge-edge and
//     sphere contacts have one) and the solver applies friction and normal impulses AT the contact points, so a box
//     tips over a ledge, tumbles and settles on a face, a sphere hitting it off-centre spins it, and a rigid sphere on a
//     slope rolls without slipping (spin = speed / radius) while a glancing hit spins both spheres. Impulses are
//     accumulated and clamped per point (Gauss-Seidel, 8 iterations per sub-step, alternating sweep order) and warm
//     started from the previous sub-step's solution of the same contact points; positional correction is translation
//     only. The orientation is a quaternion kept by the body and integrated every sub-step about the collider centre;
//     a box turning about a non-principal axis precesses (gyroscopic term, Euler's equations in the body frame by the
//     implicit midpoint rule: kinetic energy and |angular momentum| are kept, so a spin about the intermediate axis of
//     a plank flips it over without blowing up). The orientation is written to Transform.rotation (local
//     euler; the parent's rotation is taken into account) after the step, and a Transform.rotation that differs from
//     what was written last (gameplay turned the body) re-reads the orientation from the Transform. angularDamping
//     slows the spin; boxes have no rolling resistance (rollingFriction is for arcade spheres).
//   * 3D SLEEPING: a dynamic body whose fastest point (spin included) stays under 5 cm/s for 0.5 s falls asleep with
//     every body linked to it by contacts (islands sleep together: a stack sleeps as one). Asleep = no gravity, no
//     solver work, no events, frozen pose. It wakes when an awake dynamic body or a moving kinematic body comes within
//     2 cm, on gameplay writes of Transform position/rotation (a teleport also wakes the bodies touching the body) or
//     RigidBody3D velocity/angularVelocity, on apply_force/apply_impulse/set_velocity, on a changed scene gravity,
//     and when a body it touched is destroyed, disabled, resized or moved (its support is gone). A rider on a moving
//     kinematic platform never sleeps. Like 2D, scripts have no sleep API; debug_state reports `awake` per body.
//     JOINT ISLANDS: bodies joined by Joint3D are linked like touching bodies, so a settled chain (a rope bridge) falls
//     asleep as a whole and wakes as a whole; a joint with a motor (useMotor) keeps its bodies awake. A chain of three
//     or more jointed dynamic bodies is solved with 16 iterations per sub-step instead of 8, its point error is removed by
//     moving the bodies (never through the velocity: Baumgarte pumped energy into a taut bridge) and the bodies lose 1 /s
//     of their speed on top of RigidBody3D damping, so a bridge hangs still and sleeps within seconds. Joint3D.damping
//     (1/s) adds friction to the relative turning of any hinge or ball; Joint3D.stalled reads true when a motor pushes
//     for 0.25 s without the joint turning.
//     Continuous collision is solved per island (bodies linked by joints or by shapes close enough to touch within the
//     sub-step): an impact in one island no longer stops the bodies of the others, so unrelated groups move the same
//     with or without each other.
//     lockRotation (and every rollWithMotion sphere, kinematic and static body) keeps the original single-point
//     torque-free solver: contacts never turn it; angularVelocity written by gameplay still turns it (euler-added to the
//     Transform each step). An arcade sphere (rollWithMotion, the default) is spun to match its motion instead and
//     friction only slows it (rollingFriction). A rigid sphere has no rolling resistance: on flat ground it keeps
//     rolling until angularDamping / linearDamping or an obstacle stops it; lockRotation makes it slide instead.
//   * START OVERLAPS: a dynamic body that starts inside a static collider (deeper than 1 cm) is reported once, by a
//     warning in the log on the first step it exists, naming both entities, the depth and the fix.
//   * 3D SHAPE CAST (shape_cast3d): the swept sphere / axis-aligned box is stepped along the path (at most half its
//     smallest extent per step), the first step that overlaps a collider is bisected to ~0.1 mm, and normal/point come
//     from the contact at that time. A collider cannot slip between two steps (the shape is at least two steps long),
//     but a grazing touch at the very edge of the swept volume may be missed. Cost grows with path length / extent.
//     At `from` it behaves like the 2D cast: a collider penetrated by more than 1 cm is skipped; one only touched
//     (a body resting on the ground penetrates it ~1 mm) blocks the cast at distance 0 when the shape moves towards it.
//   * 3D CONTINUOUS COLLISION (automatic): every sub-step, each pair with a dynamic body whose RELATIVE displacement over
//     the sub-step exceeds about half the smaller body's smallest extent (sphere: its radius) is swept in relative motion
//     (the smaller body against the other one standing at its start pose, same stepping + bisection as shape_cast3d):
//     dynamic vs static, dynamic vs kinematic (the kinematic's own motion within the sub-step counts) and dynamic vs
//     dynamic (two 60 m/s spheres flying at each other). The earliest time of impact among the pairs of an island stops
//     the bodies of THAT island there (each moved by its own velocity * that fraction), the contacts are resolved
//     (stop / bounce / slide: the normal solver, no positional correction since the overlap is ~0.1 mm) and the rest of
//     the sub-step continues with the new velocities, repeating up to 32 impacts per sub-step (when they run out, the rest of the move waits
//     for the next sub-step instead of being applied unswept). So a 60 m/s sphere does not pass a 0.2 m wall
//     and keeps sliding along a ramp it hits instead of losing the rest of its move. Pairs that already overlap at
//     the start of the (remaining) move (deeper than 2 mm) are left to the solver; a pair left touching by the last
//     impact is swept again. A rotating box is swept through its own turn within the sub-step (its far end counts as
//     travel), so a fast spinning rod cannot swing through a thin wall.
//   * 3D RIDERS: dynamic bodies resting on top of a kinematic body (gap <= 2 cm, contact normal up) inherit its
//     displacement every sub-step (horizontal; and downward), so they ride moving platforms; friction then acts
//     on the velocity RELATIVE to the platform. A static/kinematic body teleported by gameplay carries its riders
//     by the same displacement. Stacked riders (rider on a rider) are not carried.
//   * 3D ANGULAR VELOCITY: RigidBody3D.angularVelocity (deg/s about world x,y,z) turns the entity: for rotating bodies
//     (see ROTATION DYNAMICS) as a quaternion about the collider centre; for kinematic, lockRotation and arcade sphere
//     bodies it is added to Transform.rotation (euler degrees) each step. Box colliders turn with it. rollWithMotion: a
//     dynamic sphere touching ground (contact normal up) gets angularVelocity = rolling rate: axis = up x velocity,
//     rate = |horizontal v| / radius (deg/s). ROLLING RESISTANCE: such a sphere's contacts cap the tangential impulse
//     at RigidBody3D.rollingFriction * normalImpulse (default 0.02) instead of sqrt(muA * muB) * normalImpulse, so on flat
//     ground its speed decays by about rollingFriction * g per second. With rollWithMotion false (and no lockRotation)
//     the sphere is a rigid body instead; with lockRotation too, the sliding friction of the colliders applies and the
//     ball stops quickly.
#pragma once

#include <memory>
#include <optional>
#include <vector>

#include "fa/core/json.h"
#include "fa/core/math.h"
#include "fa/physics/nav.h"
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

// Shape swept by shape_cast2d/3d, centred on the cast position and axis-aligned. Sizes are full sizes in world units
// (2D pixels, 3D meters), like Collider2D/Collider3D. 2D: Circle (radius) or Box (size.x, size.y). 3D: Circle is a
// sphere (radius), Box uses size.x/y/z.
struct CastShape {
    enum class Kind { Circle, Box } kind = Kind::Circle;
    float radius = 0.5f;
    Vec3 size{1, 1, 1};
};

// Parses the JSON shape object of the physics.shape_cast command and physics.shapeCast(shape, ...) in scripts:
//   2D: {"shape":"circle","radius":8}    {"shape":"box","size":[16,24]}
//   3D: {"shape":"sphere","radius":0.5}  {"shape":"box","size":[1,2,1]}
// `size` may also be {"x":..,"y":..(,"z":..)}; sizes and radii must be positive. Errors teach: what is wrong, an
// example, "did you mean" for a misspelt shape or key, and a note when the 3D name is used in 2D or the other way round.
Result<CastShape> cast_shape_from_json(const Json& j, bool is3d);

// Result of Physics::move_character: where the character ended up and what it stands on.
struct CharacterMoveResult {
    Vec3 position;        // entity world position after the move
    Vec3 moved;           // the displacement actually done
    bool isGrounded = false;
    Vec3 groundNormal{0, 1, 0};
    Entity ground;        // entity under the feet (null when airborne)
    bool hitWall = false;     // slid along a wall or a slope too steep to climb
    bool hitCeiling = false;  // bumped its head
};

// A dynamic 3D body that starts inside a static collider (Physics::start_overlaps3d, the first step's warning and
// `factoria validate`).
struct StartOverlap {
    Entity body;           // the dynamic body
    Entity collider;       // the static collider it overlaps
    float depth = 0.0f;    // how far it is inside, meters
    std::string message;   // one teaching sentence naming both entities, the depth and the fix
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
    // Sweep `shape` with its centre moving from `from` to `to` and return the first collider it would touch:
    // distance = how far the centre travels before contact, point = contact point, normal = the hit surface's normal
    // (pointing back at the shape). Colliders the shape already overlaps at `from` are skipped, like a raycast that
    // starts inside a collider. Options as for raycasts (mask, ignore + descendants, ignoreTriggers).
    std::optional<RaycastHit> shape_cast2d(World& world, const CastShape& shape, Vec2 from, Vec2 to,
                                           const RaycastOptions& options = {});
    std::optional<RaycastHit> shape_cast3d(World& world, const CastShape& shape, Vec3 from, Vec3 to,
                                           const RaycastOptions& options = {});

    // ----- 3D character controller (CharacterController3D): moves the capsule by `delta` (meters) with move-and-slide
    // at once and writes the Transform; nullopt if the entity has no controller. See the conventions above.
    std::optional<CharacterMoveResult> move_character(World& world, Entity e, Vec3 delta);
    // Problems found in the 3D colliders / joints / controllers (one teaching message each), e.g. a Mesh collider on a
    // dynamic body. The bodies concerned are ignored. Messages are also logged once and listed in debug_state.
    std::vector<std::string> problems3d() const;
    // The dynamic bodies that overlap a static collider (deeper than 1 cm) at their current pose, after syncing the
    // bodies; nothing is simulated or logged. `factoria validate` calls it for every scene; step() logs the same
    // warning once for each body on the first step it exists.
    std::vector<StartOverlap> start_overlaps3d(World& world);

    // ----- navigation (NavMesh3D; see fa/physics/nav.h and docs/NAVIGATION.md)
    // Bakes the NavMesh3D of entity `mesh` (an entity id; empty = every enabled NavMesh3D) from the static colliders as
    // they are now; physics bodies are synced first. Meshes with autoBake bake by themselves when the scene loads and when a
    // static collider changes, so a game rarely calls this. Errors teach (a box too big, no NavMesh3D, an unknown id).
    Result<std::vector<NavBakeStats>> nav_bake(World& world, const std::string& mesh = "");
    // Path on the walkable cells between two world points: A* over the cells, then string pulling so the points are few.
    // A search that finds nothing is NOT an Error: it returns found = false with reason, message and hint. Errors are for
    // a query that cannot be answered (no NavMesh3D, an unknown mesh id, a radius bigger than the mesh was baked for).
    Result<NavPath> nav_find_path(World& world, Vec3 from, Vec3 to, const NavPathOptions& options = {});
    // The walkable cells of every baked, enabled NavMesh3D (at most maxCells), for debug drawing. Bakes a mesh that has
    // none yet (autoBake) or whose static colliders changed.
    std::vector<NavCell> nav_cells(World& world, std::size_t maxCells = 200000);
    // Meshes and their state: bounds, parameters, baked stats, whether the static colliders changed since the bake.
    Json nav_info(World& world);

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
    // 2D shapes: `rotation` = degrees about Z, `euler` stays zero. 3D shapes: `euler` = the WORLD rotation of an
    // oriented box as euler degrees (pitch about X, yaw about Y, roll about Z; same convention as Transform.rotation,
    // zero for spheres) and `rotation` = euler.z. `size` is the box's full local size (unrotated extents). Capsule:
    // size = {diameter, full height, diameter} along the entity's local Y. Convex and Mesh: `center` and `size` are the
    // oriented bounding box of the model (draw it as a box; the triangles are in debug_state's `triangles`).
    struct DebugShape {
        enum Kind { Box, Circle, Sphere, Capsule, Convex, Mesh } kind;
        Vec3 center;
        Vec3 size;
        float rotation;
        bool trigger;
        Vec3 euler{};
    };
    std::vector<DebugShape> debug_shapes(const World& world) const;

    struct Impl;

private:
    std::unique_ptr<Impl> impl_;
};

}  // namespace fa
