// Private: the 2D (Box2D) and 3D (custom) back-ends behind fa::Physics.
#pragma once

#include <map>
#include <memory>
#include <string>
#include <unordered_map>
#include <unordered_set>
#include <vector>

#include "box2d/box2d.h"
#include "fa/physics/physics.h"
#include "shape3d.h"

namespace fa::detail {

// Collision bits: category = 1 << clamp(layer, 0, 31); mask -1 = everything.
inline std::uint64_t category_bits(std::int32_t layer) { return 1ull << (layer < 0 ? 0 : (layer > 31 ? 31 : layer)); }
inline std::uint64_t mask_bits(std::int32_t mask) { return mask == -1 ? ~0ull : std::uint64_t(std::uint32_t(mask)); }

// An entity marked by World::destroy() is gone for physics at once (no body, no collisions, no query hits), although
// World::flush() only erases it at the end of the frame. Use this instead of World::alive() for anything physical.
inline bool live(const World& world, Entity e) { return world.alive(e) && !world.pending_destroy(e); }

// World-space pose helpers (position, rotation about Z in degrees, scale) from World::world_matrix.
struct WorldPose {
    Vec3 position;
    float rotZ = 0.0f;  // degrees
    Vec3 scale{1, 1, 1};
    Vec3 axis[3] = {{1, 0, 0}, {0, 1, 0}, {0, 0, 1}};  // full rotation (3D): unit columns of the world matrix
};
WorldPose world_pose(const World& world, Entity e);
// True if `e` is `ignore` or one of its descendants (false when ignore is null).
bool entity_or_ancestor_is(const World& world, Entity e, Entity ignore);

// ------------------------------------------------------------------ 2D ----
class Physics2D {
public:
    ~Physics2D();
    void init(const PhysicsSettings& s);
    void shutdown();
    void reset();
    void sync(World& world);
    void step(World& world, float dt);

    std::optional<RaycastHit> raycast(World& world, Vec2 from, Vec2 to, const RaycastOptions& opt);
    std::optional<RaycastHit> shape_cast(World& world, const CastShape& shape, Vec2 from, Vec2 to,
                                         const RaycastOptions& opt);
    std::vector<Entity> overlap_circle(World& world, Vec2 center, float radius, std::int32_t mask);
    std::vector<Entity> overlap_box(World& world, Rect box, std::int32_t mask);
    void apply_impulse(World& world, Entity e, Vec3 impulse);
    void apply_force(World& world, Entity e, Vec3 force);
    void set_velocity(World& world, Entity e, Vec3 velocity);
    bool is_grounded(World& world, Entity e, float tolerance) { return is_touching(world, e, {0, -1}, tolerance); }
    bool is_touching(World& world, Entity e, Vec2 dir, float tolerance);
    bool has_body(Entity e) const { return bodies_.count(e.bits()) != 0; }
    static bool pre_solve(b2ShapeId a, b2ShapeId b, b2Manifold* m, void* ctx);
    void debug_state(const World& world, Json& out) const;
    void debug_shapes(const World& world, std::vector<Physics::DebugShape>& out) const;

private:
    struct LocalShape {
        enum Kind { Box, Circle, Capsule } kind = Box;
        Vec2 offset;      // meters, body space
        Vec2 half;        // box half extents / (radius, halfHeight of capsule axis) in meters
        bool trigger = false;
    };
    struct Body {
        Entity e;
        std::string id;
        b2BodyId body = b2_nullBodyId;
        std::uint64_t hash = 0;
        BodyType type = BodyType::Static;
        bool hasRigid = false;
        bool enabled = true;
        Vec3 lastPos;           // world position as last written / observed
        float lastRotZ = 0.0f;  // world rotation (degrees) as last written / observed
        Vec2 lastVel;           // component velocity as last written back
        float lastAngVel = 0.0f;
        b2Vec2 lastB2Pos{0, 0};
        float lastB2Angle = 0.0f;
        std::vector<LocalShape> shapes;
        float contAngle = 0.0f;  // continuous (unwrapped) body angle, radians
        std::uint64_t seen = 0;
    };
    struct ShapeInfo {
        std::uint64_t entity = 0;
        bool trigger = false;
        bool oneWay = false;
    };

    static std::uint64_t shape_key(b2ShapeId id) {
        return std::uint64_t(std::uint32_t(id.index1)) | (std::uint64_t(id.generation) << 32) |
               (std::uint64_t(id.world0) << 48);
    }
    void ensure_world(World& world);
    void destroy_body(Body& b);
    void destroy_tile_body(std::uint64_t key);
    void register_shape(b2ShapeId s, Entity e, bool trigger, bool oneWay, std::vector<std::uint64_t>* keys = nullptr);
    void sync_entity(World& world, Entity e, RigidBody2D* rb, Collider2D* col);
    void build_body(World& world, Body& b, RigidBody2D* rb, Collider2D* col, const WorldPose& pose);
    void sync_tilemaps(World& world);
    void sync_joints(World& world);   // Joint2D components <-> Box2D joints
    void read_joints(World& world);   // reaction force, angle and translation back into the components
    void destroy_joint(std::uint64_t key);
    void push_state(World& world, Entity e, Body& b, RigidBody2D* rb);
    void writeback(World& world, Entity e, Body& b, RigidBody2D* rb);
    void collect_events(World& world);
    Entity entity_of(b2ShapeId s, bool* trigger = nullptr) const;
    Entity entity_of_alive(const World& world, b2ShapeId s, bool* trigger) const;

    struct TileBody {
        Entity e;
        std::string id;
        b2BodyId body = b2_nullBodyId;
        std::uint64_t hash = 0;
        std::vector<std::uint64_t> shapeKeys;
        std::vector<Rect> boxes;  // world-space AABBs (for debug)
        Vec3 pos;
        float rotZ = 0;
        std::uint64_t seen = 0;
    };

    // A Joint2D as built in Box2D. `shape` is what forces a rebuild (type, bodies, anchors, axis, collideConnected); `tuning`
    // (limits, motor, spring, length) is applied to the live joint when it changes.
    struct JointRec {
        b2JointId joint = b2_nullJointId;
        std::uint64_t shape = 0, tuning = 0;
        JointType2D type = JointType2D::Revolute;
        float referenceAngle = 0.0f;  // relative body angle when the joint was made (radians): joint angle 0
        float restLength = 0.0f;      // distance joints: the anchors' distance when the joint was made (meters)
        std::uint64_t seen = 0;
    };

    PhysicsSettings settings_;
    bool inited_ = false;
    b2WorldId world_ = b2_nullWorldId;
    b2BodyId ground_ = b2_nullBodyId;  // static body at the origin: the other end of a Joint2D with no `connected`
    const World* lastWorld_ = nullptr;
    std::unordered_map<std::uint64_t, JointRec> joints_;  // by the entity that owns the Joint2D
    std::unordered_set<std::uint64_t> jointWarned_;       // entities whose broken Joint2D was already reported
    std::unordered_map<std::uint64_t, Body> bodies_;
    std::unordered_map<std::uint64_t, TileBody> tiles_;
    std::unordered_map<std::uint64_t, ShapeInfo> shapes_;
    std::vector<std::uint64_t> deadNow_, deadPrev_;
    std::uint64_t stepCounter_ = 0;
    Vec2 lastGravity_{1e30f, 1e30f};
    std::vector<Entity> order_;  // entity iteration order of the last sync (for stable debug output)
};

// ------------------------------------------------------------------ 3D ----
class Physics3D {
public:
    void sync(World& world);  // bodies <-> components without simulating
    void init(const PhysicsSettings& s) { settings_ = s; }
    void reset();
    void step(World& world, float dt);
    std::optional<RaycastHit> raycast(World& world, Vec3 origin, Vec3 dir, float maxDistance, const RaycastOptions& opt);
    std::optional<RaycastHit> shape_cast(World& world, const CastShape& shape, Vec3 from, Vec3 to,
                                         const RaycastOptions& opt);
    bool is_touching(World& world, Entity e, Vec3 dir, float tolerance);
    std::vector<Entity> overlap_sphere(World& world, Vec3 center, float radius, std::int32_t mask);
    void apply_impulse(World& world, Entity e, Vec3 impulse);
    void apply_force(World& world, Entity e, Vec3 force);
    void set_velocity(World& world, Entity e, Vec3 velocity);
    bool has_body(Entity e) const { return index_.count(e.bits()) != 0; }
    // Character controller: moves the capsule by `delta` with move-and-slide (see physics3d_character.cpp).
    std::optional<CharacterMoveResult> move_character(World& world, Entity e, Vec3 delta);
    // Why the entity's Collider3D / Joint3D / CharacterController3D cannot be used ("" = fine); see Physics::problems3d.
    std::vector<std::string> problems() const;
    void debug_state(const World& world, Json& out) const;
    void debug_shapes(const World& world, std::vector<Physics::DebugShape>& out) const;

private:
    static constexpr int kMaxPts = 8;  // contact points of a box-box manifold (a quad clipped by 4 planes)
    struct Body {
        Entity e;
        std::string id;
        std::uint64_t seq = 0;  // creation order
        BodyType type = BodyType::Static;
        bool hasRigid = false;
        bool hasShape = false;
        bool box = true;
        bool trigger = false;
        bool enabled = true;
        float mass = 1.0f, invMass = 1.0f;
        float gravityScale = 1.0f, damping = 0.0f, angDamping = 0.0f;
        float friction = 0.4f, restitution = 0.0f;
        std::int32_t layer = 0, mask = -1;
        // Shape: Box and Sphere have their own exact code; Capsule, Convex and Mesh go through the convex cores of
        // shape3d.h (`general()`). `box` is true only for Kind::Box.
        enum class Kind { Box, Sphere, Capsule, Convex, Mesh } kind = Kind::Box;
        bool general() const { return kind >= Kind::Capsule; }
        Vec3 half{0.5f, 0.5f, 0.5f};  // box half extents along its own axes (scaled); capsule / convex / mesh: bounding box
        float radius = 0.5f;          // sphere / capsule radius (scaled)
        float segHalf = 0.0f;         // capsule: half the length of the straight part, along the entity's local Y (scaled)
        Vec3 gscale{1, 1, 1};         // convex / mesh: per-axis scale of the model's vertices
        Vec3 lcenter;                 // convex / mesh: centre of the model's bounding box (scaled, entity axes)
        std::shared_ptr<const ShapeData> data;  // convex hull cloud / mesh BVH, shared by all colliders of one mesh
        Vec3 rot[3] = {{1, 0, 0}, {0, 1, 0}, {0, 0, 1}};  // the entity's world rotation (any shape; joints use it)
        Vec3 localScale{1, 1, 1};     // the entity's world scale (joint anchors are scaled with it)
        std::vector<std::uint64_t> noCollide;  // seq of bodies joined to this one by a joint that forbids their collision
        bool jointed = false;         // has a Joint3D: always a rotating rigid body, never sleeps
        bool character = false;       // CharacterController3D: kinematic capsule moved by move_character
        float stepOffset = 0.3f, slopeLimit = 45.0f, skin = 0.02f;  // character controller
        std::string problem;          // why the collider is ignored ("" = none)
        std::string meshName;         // convex / mesh: Collider3D.mesh
        // Box frame in world space: the entity's world rotation. Exactly the identity (and `rotated` false, which
        // selects the exact axis-aligned code paths) unless the box is turned.
        Vec3 ax[3] = {{1, 0, 0}, {0, 1, 0}, {0, 0, 1}};
        bool rotated = false;
        // Rotation dynamics: a dynamic box (or rigid sphere) without lockRotation is turned by contacts. `orient` is the authority
        // between steps (the Transform is written from it; `lastEuler` is what was written, so a different Transform
        // value means gameplay turned the body and `orient` is re-read from it). invI = inverse inertia, body frame.
        bool rotDyn = false;
        bool rotDirty = false;     // orientation changed this step: Transform.rotation must be rewritten
        bool originDirty = false;  // the box turned about an offset collider centre: the entity origin must be rewritten
        Quat orient;
        Vec3 lastEuler;
        Vec3 invI;
        float rollMu = -1.0f;         // rolling resistance of a rolling sphere (replaces friction); < 0 = not rolling
        Vec3 localOffset;             // collider offset (scaled, in the entity's own axes)
        Vec3 offset;                  // collider offset in world axes (scaled, rotated with the entity)
        Vec3 center;                  // collider center (world)
        Vec3 vel;
        Vec3 force;
        Vec3 angVel, lastAngVel;  // deg/s
        bool rollWithMotion = true;
        Vec3 pendingCarry;  // displacement of a teleported static/kinematic body, applied to its riders
        Vec3 lastPos, lastVel, lastCenter;  // gameplay-visible values last written / observed
        // Sleeping: a dynamic body (and every body linked to it by contacts) whose speed stayed tiny for kTimeToSleep stops
        // costing solver work and sends no events. Bodies that fell asleep together share `sleepGroup` and wake together.
        bool asleep = false;
        bool moved = false;  // gameplay teleported this body since the last step: it wakes whatever it now touches
        float sleepTime = 0.0f;
        std::uint64_t sleepGroup = 0;
        std::uint64_t seen = 0;
        // What a sleeping body's neighbours depend on: when any of it changes (a platform resized, disabled, made dynamic...)
        // the body and the bodies that touched it wake up.
        struct Sig {
            BodyType type;
            bool enabled, hasShape, box, trigger, rotDyn;
            float mass, gravityScale, radius;
            Vec3 half, offset, ax[3];
            std::int32_t layer, mask;
            Kind kind;
            float segHalf;
            Vec3 gscale;
            const ShapeData* data;
            bool operator==(const Sig&) const = default;
        };
        Sig sig() const {
            return {type, enabled, hasShape, box, trigger, rotDyn, mass, gravityScale, radius, half, offset,
                    {ax[0], ax[1], ax[2]}, layer, mask, kind, segHalf, gscale, data.get()};
        }
    };
    struct Contact {
        bool hit = false;
        Vec3 normal;  // from a to b
        float depth = 0.0f;  // > 0 penetrating; may be slightly negative within margin
        Vec3 point;
        // Box-box face contacts (collide(..., manifold = true)): the clipped incident face. depths[i] < 0 = still apart.
        int n = 0;
        Vec3 pts[kMaxPts];
        float depths[kMaxPts] = {};
    };
    using PairKey = std::pair<std::uint64_t, std::uint64_t>;  // body seq numbers, lo < hi
    struct PairState {
        Entity a, b;
        bool trigger = false;
    };
    // One manifold prepared for the rigid-body solver (see Physics3D::step).
    struct RigidContact {
        std::size_t ia, ib;
        PairKey key;
        Vec3 n;
        Vec3 ca, cb;  // body centres when built (to track the translation done by the position pass)
        float mu = 0.0f;
        int carrier = 0;  // 1: a is the kinematic platform carrying b; 2: the other way round
        int count = 0;
        struct Pt {
            Vec3 ra, rb;
            float depth = 0.0f, kn = 1.0f, target = 0.0f, jn = 0.0f;
            Vec3 jt;
        } pt[kMaxPts];
    };

    static Contact collide(const Body& a, const Body& b, float margin, bool manifold = false);
    // Capsule / convex / mesh pairs (physics3d_shapes.cpp).
    static Contact collide_general(const Body& a, const Body& b, float margin, bool manifold);
    static Contact mesh_contact(const Body& mesh, const Body& other, float margin, bool manifold);
    static Contact core_contact(const Core& A, const Core& B, float margin);
    static Contact tri_contact(const Core& tri, const Core& other, float margin);
    static void add_capsule_points(const Body& a, const Body& b, Contact& c);
    static Core core_of(const Body& b);
    static void aabb(const Body& b, Vec3& lo, Vec3& hi);
    static float bound_radius(const Body& b);
    static float min_half_extent(const Body& b);
    static bool ray_body(const Body& b, Vec3 origin, Vec3 dir, float maxT, float& t, Vec3& normal);
    static void sphere_box(const Body& box, const Body& sph, float margin, Contact& out);
    static void box_box_sat(const Body& a, const Body& b, float margin, Contact& out, bool manifold);
    static void face_manifold(const Body& ref, int refAxis, Vec3 refNormal, const Body& inc, Contact& out);
    static bool sweep(Body& mover, Vec3 disp, Vec3 moverSpin, Body& target, Vec3 targetSpin, float& tHit);
    // How far the far end of a box travels when it turns by `spin` (rad, world axes): |spin| times its bounding radius.
    static float turning_reach(const Body& b, Vec3 spin) { return b.kind != Body::Kind::Sphere ? length(spin) * bound_radius(b) : 0.0f; }
    static bool filters_pass(const Body& a, const Body& b);
    static void refresh_frame(Body& b);
    static void integrate_orient(Body& b, float seconds);
    static Vec3 inv_inertia_mul(const Body& b, Vec3 v);
    static Vec3 point_velocity(const Body& b, Vec3 r);
    void solve_pair(Body& a, Body& b, const Contact& c, float h, float& impact, bool carried, bool positional);
    static bool build_rigid_contact(const Body& a, const Body& b, std::size_t ia, std::size_t ib, const Contact& c,
                                    float h, int carrier, float& impact, RigidContact& out);
    static void solve_velocity(std::vector<Body>& bodies, RigidContact& rc, bool reverse);
    static void correct_position(std::vector<Body>& bodies, const RigidContact& rc);
    void wake(Body& b);                      // b and everything that fell asleep with it
    void wake_touching(std::uint64_t seq);  // the bodies that touched body `seq` after the previous step

    PhysicsSettings settings_;
    std::vector<Body> bodies_;  // sorted by seq (creation order)
    std::unordered_map<std::uint64_t, std::size_t> index_;  // entity bits -> index in bodies_
    std::uint64_t nextSeq_ = 1;
    float carry_ = 0.0f;  // fraction of a sub-step's move left undone because of too many impacts; done in the next one
    Vec3 lastGravity_{1e30f, 1e30f, 1e30f};  // a changed scene gravity wakes every body
    const World* lastWorld_ = nullptr;
    std::uint64_t stepCounter_ = 0;
    std::map<PairKey, PairState> touching_;  // pairs overlapping after the previous step
    // Warm start of the rigid-body solver: the accumulated impulses of each pair's contact points at the end of the
    // previous sub-step (world position of the point + normal impulse + friction impulse).
    struct WarmPt {
        Vec3 pos;
        float jn = 0.0f;
        Vec3 jt;
    };
    std::map<PairKey, std::vector<WarmPt>> warm_;

    // ---- joints (physics3d_joints.cpp)
    struct JointState {
        Entity e, conn;
        std::uint64_t seqA = 0, seqB = 0;  // seqB 0 = the world
        std::size_t ia = 0, ib = 0;        // body indices for the current step
        bool active = false;               // both bodies exist and the settings are usable
        JointType3D type = JointType3D::Hinge;
        bool useLimits = false, useMotor = false, collide = false;
        float lower = 0.0f, upper = 0.0f, motorSpeed = 0.0f, maxTorque = 0.0f;  // radians, rad/s
        Vec3 anchorA, anchorB;             // local to each body (B: a world point when seqB == 0)
        Vec3 axisA, axisB;                 // hinge axis in each body's local frame
        Vec3 refA, refB;                   // hinge reference vector (angle 0) in each body's local frame
        Vec3 relCol[3];                    // fixed: R_A^T R_B when the joint was created
        // What the state above was built from; any change rebuilds it from the poses the bodies have now.
        JointType3D sigType = JointType3D::Hinge;
        Entity sigConnected;
        Vec3 sigAnchor, sigConnAnchor, sigAxis;
        bool sigAuto = true;
        // Accumulated impulses (warm start of the next sub-step).
        Vec3 pImp, aImp;
        float lowImp = 0.0f, upImp = 0.0f, motorImp = 0.0f;
        float angle = 0.0f;                // radians, this body relative to the connected one about the axis
        // Per sub-step cache (prepare_joints).
        Vec3 rA, rB, pBias, kinv[3], aw, t1, t2, fixBias;
        float k1 = 1.0f, k2 = 1.0f, kAxis = 1.0f, angBias = 0.0f;
        bool hasB = false;
        std::string problem;               // why the joint is inactive ("" = none)
        std::uint64_t seen = 0;
    };
    std::map<std::uint64_t, JointState> joints_;  // by owner entity bits
    void sync_joints(World& world, std::uint64_t stamp);
    bool prepare_joints(float h);  // false when no joint is active
    void solve_joints(float h);
    void finish_joints(World& world);
    static void build_joint(JointState& j, const Body& a, const Body* b, const Joint3D& jt);

    // ---- shapes of meshes, shared by every collider of the same mesh
    std::map<std::string, std::shared_ptr<ShapeData>> shapes_;
    std::shared_ptr<const ShapeData> shape_data(const std::string& mesh, bool bvh, std::string& problem);
    float lastDt_ = 1.0f / 60.0f;       // the last step's dt (character pushes turn a move into a speed)
    void move_character_body(World& world, Body& b, const CharacterController3D& cc, Vec3 delta, CharacterMoveResult& out);
};

}  // namespace fa::detail
