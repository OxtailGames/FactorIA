// Private: the 2D (Box2D) and 3D (custom) back-ends behind fa::Physics.
#pragma once

#include <map>
#include <string>
#include <unordered_map>
#include <vector>

#include "box2d/box2d.h"
#include "fa/physics/physics.h"

namespace fa::detail {

// Collision bits: category = 1 << clamp(layer, 0, 31); mask -1 = everything.
inline std::uint64_t category_bits(std::int32_t layer) { return 1ull << (layer < 0 ? 0 : (layer > 31 ? 31 : layer)); }
inline std::uint64_t mask_bits(std::int32_t mask) { return mask == -1 ? ~0ull : std::uint64_t(std::uint32_t(mask)); }

// World-space pose helpers (position, rotation about Z in degrees, scale) from World::world_matrix.
struct WorldPose {
    Vec3 position;
    float rotZ = 0.0f;  // degrees
    Vec3 scale{1, 1, 1};
};
WorldPose world_pose(const World& world, Entity e);

// ------------------------------------------------------------------ 2D ----
class Physics2D {
public:
    ~Physics2D();
    void init(const PhysicsSettings& s);
    void shutdown();
    void reset();
    void step(World& world, float dt);

    std::optional<RaycastHit> raycast(World& world, Vec2 from, Vec2 to, std::int32_t mask);
    std::vector<Entity> overlap_circle(World& world, Vec2 center, float radius, std::int32_t mask);
    std::vector<Entity> overlap_box(World& world, Rect box, std::int32_t mask);
    void apply_impulse(World& world, Entity e, Vec3 impulse);
    void apply_force(World& world, Entity e, Vec3 force);
    void set_velocity(World& world, Entity e, Vec3 velocity);
    bool is_grounded(World& world, Entity e, float tolerance);
    bool has_body(Entity e) const { return bodies_.count(e.bits()) != 0; }
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
    };

    static std::uint64_t shape_key(b2ShapeId id) {
        return std::uint64_t(std::uint32_t(id.index1)) | (std::uint64_t(id.generation) << 32) |
               (std::uint64_t(id.world0) << 48);
    }
    void ensure_world(World& world);
    void destroy_body(Body& b);
    void destroy_tile_body(std::uint64_t key);
    void register_shape(b2ShapeId s, Entity e, bool trigger, std::vector<std::uint64_t>* keys = nullptr);
    void sync_entity(World& world, Entity e, RigidBody2D* rb, Collider2D* col);
    void build_body(World& world, Body& b, RigidBody2D* rb, Collider2D* col, const WorldPose& pose);
    void sync_tilemaps(World& world);
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

    PhysicsSettings settings_;
    bool inited_ = false;
    b2WorldId world_ = b2_nullWorldId;
    const World* lastWorld_ = nullptr;
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
    void init(const PhysicsSettings& s) { settings_ = s; }
    void reset();
    void step(World& world, float dt);
    std::optional<RaycastHit> raycast(World& world, Vec3 origin, Vec3 dir, float maxDistance, std::int32_t mask);
    std::vector<Entity> overlap_sphere(World& world, Vec3 center, float radius, std::int32_t mask);
    void apply_impulse(World& world, Entity e, Vec3 impulse);
    void apply_force(World& world, Entity e, Vec3 force);
    void set_velocity(World& world, Entity e, Vec3 velocity);
    bool has_body(Entity e) const { return index_.count(e.bits()) != 0; }
    void debug_state(const World& world, Json& out) const;
    void debug_shapes(const World& world, std::vector<Physics::DebugShape>& out) const;

private:
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
        float gravityScale = 1.0f, damping = 0.0f;
        float friction = 0.4f, restitution = 0.0f;
        std::int32_t layer = 0, mask = -1;
        Vec3 half{0.5f, 0.5f, 0.5f};  // box half extents (scaled)
        float radius = 0.5f;          // sphere (scaled)
        Vec3 offset;                  // scaled collider offset
        Vec3 center;                  // collider center (world)
        Vec3 vel;
        Vec3 force;
        Vec3 lastPos, lastVel, lastCenter;  // gameplay-visible values last written / observed
        std::uint64_t seen = 0;
    };
    struct Contact {
        bool hit = false;
        Vec3 normal;  // from a to b
        float depth = 0.0f;  // > 0 penetrating; may be slightly negative within margin
        Vec3 point;
    };
    using PairKey = std::pair<std::uint64_t, std::uint64_t>;  // body seq numbers, lo < hi
    struct PairState {
        Entity a, b;
        bool trigger = false;
    };

    static Contact collide(const Body& a, const Body& b, float margin);
    static bool filters_pass(const Body& a, const Body& b);
    void sync(World& world);
    void solve_pair(Body& a, Body& b, const Contact& c, float h, float& impact);

    PhysicsSettings settings_;
    std::vector<Body> bodies_;  // sorted by seq (creation order)
    std::unordered_map<std::uint64_t, std::size_t> index_;  // entity bits -> index in bodies_
    std::uint64_t nextSeq_ = 1;
    const World* lastWorld_ = nullptr;
    std::uint64_t stepCounter_ = 0;
    std::map<PairKey, PairState> touching_;  // pairs overlapping after the previous step
};

}  // namespace fa::detail
