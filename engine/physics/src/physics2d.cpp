// 2D physics on top of Box2D v3.
#include <algorithm>
#include <cmath>
#include <cstring>
#include <functional>

#include "fa/core/log.h"
#include "physics_internal.h"

namespace fa::detail {

namespace {

struct Hasher {
    std::uint64_t h = 1469598103934665603ull;
    void bytes(const void* p, std::size_t n) {
        const auto* b = static_cast<const unsigned char*>(p);
        for (std::size_t i = 0; i < n; ++i) { h ^= b[i]; h *= 1099511628211ull; }
    }
    template <class T> void add(const T& v) { bytes(&v, sizeof(T)); }
    void add(float v) { if (v == 0.0f) v = 0.0f; bytes(&v, sizeof v); }  // -0 == +0
};

float wrap_pi(float a) {
    while (a > kPi) a -= kTau;
    while (a < -kPi) a += kTau;
    return a;
}
float wrap_deg(float a) {
    while (a > 180.0f) a -= 360.0f;
    while (a < -180.0f) a += 360.0f;
    return a;
}

constexpr float kMinHalf = 0.005f;  // meters; Box2D dislikes degenerate polygons

std::uint64_t hash_collider(const RigidBody2D* rb, const Collider2D* col, const WorldPose& pose) {
    Hasher h;
    h.add(rb != nullptr);
    if (rb) {
        h.add(rb->type); h.add(rb->gravityScale); h.add(rb->linearDamping); h.add(rb->angularDamping);
        h.add(rb->fixedRotation); h.add(rb->bullet);
    }
    h.add(col != nullptr);
    if (col) {
        h.add(col->shape); h.add(col->size.x); h.add(col->size.y); h.add(col->radius);
        h.add(col->offset.x); h.add(col->offset.y); h.add(col->isTrigger); h.add(col->friction);
        h.add(col->restitution); h.add(col->density); h.add(col->oneWay); h.add(col->layer); h.add(col->mask);
        h.add(pose.scale.x); h.add(pose.scale.y);
    }
    return h.h;
}

std::vector<int> read_tiles(const Tilemap& tm) {
    int w = std::max(tm.width, 0), hgt = std::max(tm.height, 0);
    std::vector<int> out(std::size_t(w) * std::size_t(hgt), -1);
    if (!tm.tiles.is_array() || tm.tiles.empty()) return out;
    auto num = [](const Json& j) { return j.is_number() ? int(j.get<double>()) : -1; };
    if (tm.tiles[0].is_array()) {
        for (int r = 0; r < hgt && r < int(tm.tiles.size()); ++r) {
            const Json& row = tm.tiles[std::size_t(r)];
            if (!row.is_array()) continue;
            for (int c = 0; c < w && c < int(row.size()); ++c) out[std::size_t(r) * std::size_t(w) + std::size_t(c)] = num(row[std::size_t(c)]);
        }
    } else {
        for (std::size_t i = 0; i < out.size() && i < tm.tiles.size(); ++i) out[i] = num(tm.tiles[i]);
    }
    return out;
}

std::vector<int> read_solid(const Tilemap& tm) {
    std::vector<int> s;
    if (tm.solidTiles.is_array())
        for (const Json& j : tm.solidTiles)
            if (j.is_number()) s.push_back(int(j.get<double>()));
    std::sort(s.begin(), s.end());
    return s;
}

std::uint64_t hash_tilemap(const Tilemap& tm, const WorldPose& pose) {
    Hasher h;
    h.add(tm.width); h.add(tm.height); h.add(tm.tileSize.x); h.add(tm.tileSize.y);
    h.add(pose.scale.x); h.add(pose.scale.y);
    auto add_json = [&](const Json& j, auto&& self) -> void {
        if (j.is_array()) { for (const Json& c : j) self(c, self); h.add(std::uint8_t(0xff)); }
        else if (j.is_number()) h.add(int(j.get<double>()));
    };
    add_json(tm.tiles, add_json);
    h.add(std::uint8_t(0xee));
    add_json(tm.solidTiles, add_json);
    return h.h;
}

b2BodyType to_b2(BodyType t) {
    switch (t) {
        case BodyType::Static: return b2_staticBody;
        case BodyType::Kinematic: return b2_kinematicBody;
        default: return b2_dynamicBody;
    }
}

const char* type_name(BodyType t) {
    switch (t) {
        case BodyType::Static: return "static";
        case BodyType::Kinematic: return "kinematic";
        default: return "dynamic";
    }
}

}  // namespace

Physics2D::~Physics2D() { shutdown(); }

void Physics2D::init(const PhysicsSettings& s) {
    settings_ = s;
    reset();
    inited_ = true;
}

void Physics2D::shutdown() {
    if (B2_IS_NON_NULL(world_)) b2DestroyWorld(world_);
    world_ = b2_nullWorldId;
    bodies_.clear();
    tiles_.clear();
    shapes_.clear();
    deadNow_.clear();
    deadPrev_.clear();
    order_.clear();
    lastWorld_ = nullptr;
    lastGravity_ = {1e30f, 1e30f};
    inited_ = false;
}

void Physics2D::reset() {
    if (B2_IS_NON_NULL(world_)) b2DestroyWorld(world_);
    world_ = b2_nullWorldId;
    bodies_.clear();
    tiles_.clear();
    shapes_.clear();
    deadNow_.clear();
    deadPrev_.clear();
    order_.clear();
    lastWorld_ = nullptr;
    lastGravity_ = {1e30f, 1e30f};
}

void Physics2D::ensure_world(World& world) {
    if (!inited_) {
        inited_ = true;
    }
    if (lastWorld_ != &world || B2_IS_NULL(world_)) {
        reset();
        lastWorld_ = &world;
        b2WorldDef wd = b2DefaultWorldDef();
        wd.gravity = {0.0f, -9.8f};
        wd.hitEventThreshold = 0.05f;
        wd.workerCount = 1;  // single-threaded: the one-way pre-solve callback relies on it
        world_ = b2CreateWorld(&wd);
        b2World_SetPreSolveCallback(world_, &Physics2D::pre_solve, this);
    }
}

void Physics2D::register_shape(b2ShapeId s, Entity e, bool trigger, bool oneWay, std::vector<std::uint64_t>* keys) {
    shapes_[shape_key(s)] = ShapeInfo{e.bits(), trigger, oneWay};
    if (keys) keys->push_back(shape_key(s));
}

Entity Physics2D::entity_of(b2ShapeId s, bool* trigger) const {
    auto it = shapes_.find(shape_key(s));
    if (it == shapes_.end()) return kNullEntity;
    if (trigger) *trigger = it->second.trigger;
    return Entity::from_bits(it->second.entity);
}

Entity Physics2D::entity_of_alive(const World& world, b2ShapeId s, bool* trigger) const {
    Entity e = entity_of(s, trigger);
    return (!e.is_null() && world.alive(e)) ? e : kNullEntity;
}

void Physics2D::destroy_body(Body& b) {
    if (B2_IS_NON_NULL(b.body) && b2Body_IsValid(b.body)) {
        int n = b2Body_GetShapeCount(b.body);
        std::vector<b2ShapeId> ids(std::size_t(std::max(n, 0)));
        n = b2Body_GetShapes(b.body, ids.data(), n);
        for (int i = 0; i < n; ++i) deadNow_.push_back(shape_key(ids[std::size_t(i)]));
        b2DestroyBody(b.body);
    }
    b.body = b2_nullBodyId;
}

void Physics2D::destroy_tile_body(std::uint64_t key) {
    auto it = tiles_.find(key);
    if (it == tiles_.end()) return;
    for (std::uint64_t k : it->second.shapeKeys) deadNow_.push_back(k);
    if (B2_IS_NON_NULL(it->second.body) && b2Body_IsValid(it->second.body)) b2DestroyBody(it->second.body);
    tiles_.erase(it);
}

void Physics2D::build_body(World& world, Body& b, RigidBody2D* rb, Collider2D* col, const WorldPose& pose) {
    (void)world;
    const float inv = 1.0f / settings_.pixelsPerMeter;
    b.type = rb ? rb->type : BodyType::Static;
    b.hasRigid = rb != nullptr;
    b2BodyDef bd = b2DefaultBodyDef();
    bd.type = to_b2(b.type);
    bd.position = {pose.position.x * inv, pose.position.y * inv};
    bd.rotation = b2MakeRot(radians(pose.rotZ));
    if (rb && b.type != BodyType::Static) {
        bd.linearVelocity = {rb->velocity.x * inv, rb->velocity.y * inv};
        bd.angularVelocity = radians(rb->angularVelocity);
        bd.linearDamping = rb->linearDamping;
        bd.angularDamping = rb->angularDamping;
        bd.gravityScale = rb->gravityScale;
        bd.fixedRotation = rb->fixedRotation;
        bd.isBullet = rb->bullet;
    }
    b.body = b2CreateBody(world_, &bd);
    b.contAngle = radians(pose.rotZ);
    b.lastB2Pos = bd.position;
    b.lastB2Angle = b.contAngle;
    b.lastPos = pose.position;
    b.lastRotZ = pose.rotZ;
    b.lastVel = rb ? rb->velocity : Vec2{};
    b.lastAngVel = rb ? rb->angularVelocity : 0.0f;
    b.shapes.clear();

    if (col) {
        b2ShapeDef sd = b2DefaultShapeDef();
        sd.density = std::max(col->density, 0.0f);
        sd.material.friction = std::max(col->friction, 0.0f);
        sd.material.restitution = std::max(col->restitution, 0.0f);
        sd.filter.categoryBits = category_bits(col->layer);
        sd.filter.maskBits = mask_bits(col->mask);
        sd.isSensor = col->isTrigger;
        sd.enableSensorEvents = true;
        sd.enableContactEvents = true;
        sd.enableHitEvents = true;
        sd.enablePreSolveEvents = col->oneWay && !col->isTrigger;
        const float sx = std::fabs(pose.scale.x), sy = std::fabs(pose.scale.y);
        b2Vec2 off{col->offset.x * pose.scale.x * inv, col->offset.y * pose.scale.y * inv};
        LocalShape ls;
        ls.offset = {off.x, off.y};
        ls.trigger = col->isTrigger;
        b2ShapeId sid = b2_nullShapeId;
        switch (col->shape) {
            case ColliderShape::Box: {
                float hx = std::max(col->size.x * sx * 0.5f * inv, kMinHalf);
                float hy = std::max(col->size.y * sy * 0.5f * inv, kMinHalf);
                b2Polygon poly = b2MakeOffsetBox(hx, hy, off, b2MakeRot(0.0f));
                sid = b2CreatePolygonShape(b.body, &sd, &poly);
                ls.kind = LocalShape::Box;
                ls.half = {hx, hy};
                break;
            }
            case ColliderShape::Circle: {
                float r = std::max(col->radius * std::max(sx, sy) * inv, kMinHalf);
                b2Circle c{off, r};
                sid = b2CreateCircleShape(b.body, &sd, &c);
                ls.kind = LocalShape::Circle;
                ls.half = {r, r};
                break;
            }
            case ColliderShape::Capsule: {
                float w = std::max(col->size.x * sx * inv, 2 * kMinHalf);
                float hgt = std::max(col->size.y * sy * inv, 2 * kMinHalf);
                float r = w * 0.5f;
                if (hgt <= w) {
                    b2Circle c{off, hgt * 0.5f};
                    sid = b2CreateCircleShape(b.body, &sd, &c);
                    ls.kind = LocalShape::Circle;
                    ls.half = {hgt * 0.5f, hgt * 0.5f};
                } else {
                    float a = hgt * 0.5f - r;
                    b2Capsule cap{{off.x, off.y - a}, {off.x, off.y + a}, r};
                    sid = b2CreateCapsuleShape(b.body, &sd, &cap);
                    ls.kind = LocalShape::Capsule;
                    ls.half = {r, a};
                }
                break;
            }
        }
        register_shape(sid, b.e, col->isTrigger, col->oneWay && !col->isTrigger);
        b.shapes.push_back(ls);
    }
    if (b.type == BodyType::Dynamic && b2Body_GetMass(b.body) <= 0.0f) {
        // Shapeless / zero-density dynamic body: give it unit mass so gravity and impulses work.
        b2MassData md{};
        md.mass = 1.0f;
        md.rotationalInertia = 1.0f;
        b2Body_SetMassData(b.body, md);
    }
}

void Physics2D::sync_entity(World& world, Entity e, RigidBody2D* rb, Collider2D* col) {
    const float inv = 1.0f / settings_.pixelsPerMeter;
    const std::uint64_t key = e.bits();
    WorldPose pose = world_pose(world, e);
    std::uint64_t hash = hash_collider(rb, col, pose);
    auto it = bodies_.find(key);
    if (it != bodies_.end() && (it->second.hash != hash || it->second.id != world.id_of(e))) {
        destroy_body(it->second);
        bodies_.erase(it);
        it = bodies_.end();
    }
    if (it == bodies_.end()) {
        Body nb;
        nb.e = e;
        nb.id = world.id_of(e);
        nb.hash = hash;
        it = bodies_.emplace(key, std::move(nb)).first;
        build_body(world, it->second, rb, col, pose);
    }
    Body& b = it->second;
    b.seen = stepCounter_;

    const bool active = world.active_in_hierarchy(e);
    if (active != b.enabled) {
        if (active) b2Body_Enable(b.body);
        else b2Body_Disable(b.body);
        b.enabled = active;
    }
    if (!active) return;

    // Gameplay moved the Transform since our last writeback -> teleport.
    const float eps = 1e-3f;
    auto far = [&](float a, float c) { return std::fabs(a - c) > eps + 1e-6f * std::fabs(a); };
    if (far(pose.position.x, b.lastPos.x) || far(pose.position.y, b.lastPos.y) ||
        std::fabs(wrap_deg(pose.rotZ - b.lastRotZ)) > eps) {
        float newAngle = b.contAngle + radians(wrap_deg(pose.rotZ - b.lastRotZ));
        b2Vec2 p{pose.position.x * inv, pose.position.y * inv};
        b2Body_SetTransform(b.body, p, b2MakeRot(newAngle));
        b.contAngle = newAngle;
        b.lastB2Pos = p;
        b.lastB2Angle = newAngle;
        b.lastPos = pose.position;
        b.lastRotZ = pose.rotZ;
    }
    if (rb) push_state(world, e, b, rb);
    if (b.type != BodyType::Static) order_.push_back(e);
}

void Physics2D::push_state(World&, Entity, Body& b, RigidBody2D* rb) {
    if (b.type == BodyType::Static) return;
    const float inv = 1.0f / settings_.pixelsPerMeter;
    if (rb->velocity != b.lastVel) {
        b2Body_SetLinearVelocity(b.body, {rb->velocity.x * inv, rb->velocity.y * inv});
        if (rb->velocity.x != 0.0f || rb->velocity.y != 0.0f) b2Body_SetAwake(b.body, true);
        b.lastVel = rb->velocity;
    }
    if (rb->angularVelocity != b.lastAngVel) {
        b2Body_SetAngularVelocity(b.body, radians(rb->angularVelocity));
        if (rb->angularVelocity != 0.0f) b2Body_SetAwake(b.body, true);
        b.lastAngVel = rb->angularVelocity;
    }
}

void Physics2D::sync_tilemaps(World& world) {
    const float inv = 1.0f / settings_.pixelsPerMeter;
    for (Entity e : world.entities_with(&World::type_of<Tilemap>())) {
        if (!world.alive(e)) continue;
        Tilemap* tm = world.get<Tilemap>(e);
        if (!tm) continue;
        const std::uint64_t key = e.bits();
        WorldPose pose = world_pose(world, e);
        std::uint64_t hash = hash_tilemap(*tm, pose);
        auto it = tiles_.find(key);
        if (it != tiles_.end() && (it->second.hash != hash || it->second.id != world.id_of(e))) {
            destroy_tile_body(key);
            it = tiles_.end();
        }
        const bool active = world.active_in_hierarchy(e);
        if (it == tiles_.end()) {
            std::vector<int> solid = read_solid(*tm);
            if (solid.empty() || tm->width <= 0 || tm->height <= 0) {
                // No collision: remember nothing; nothing to build.
                continue;
            }
            std::vector<int> tiles = read_tiles(*tm);
            const int w = tm->width, hgt = tm->height;
            auto is_solid = [&](int c, int r) {
                int t = tiles[std::size_t(r) * std::size_t(w) + std::size_t(c)];
                return t >= 0 && std::binary_search(solid.begin(), solid.end(), t);
            };
            // Horizontal runs per row, then merge identical runs of consecutive rows into taller boxes.
            struct Run { int c0, c1, r0, r1; };
            std::vector<Run> runs;
            std::vector<std::size_t> prevIdx;
            for (int r = 0; r < hgt; ++r) {
                std::vector<std::size_t> curIdx;
                int c = 0;
                while (c < w) {
                    if (!is_solid(c, r)) { ++c; continue; }
                    int c0 = c;
                    while (c < w && is_solid(c, r)) ++c;
                    bool found = false;
                    for (std::size_t idx : prevIdx) {
                        if (runs[idx].c0 == c0 && runs[idx].c1 == c - 1) {
                            runs[idx].r1 = r;
                            curIdx.push_back(idx);
                            found = true;
                            break;
                        }
                    }
                    if (!found) {
                        runs.push_back({c0, c - 1, r, r});
                        curIdx.push_back(runs.size() - 1);
                    }
                }
                prevIdx = std::move(curIdx);
            }

            TileBody tb;
            tb.e = e;
            tb.id = world.id_of(e);
            tb.hash = hash;
            tb.pos = pose.position;
            tb.rotZ = pose.rotZ;
            b2BodyDef bd = b2DefaultBodyDef();
            bd.type = b2_staticBody;
            bd.position = {pose.position.x * inv, pose.position.y * inv};
            bd.rotation = b2MakeRot(radians(pose.rotZ));
            tb.body = b2CreateBody(world_, &bd);
            const float tw = tm->tileSize.x * pose.scale.x, th = tm->tileSize.y * pose.scale.y;
            b2ShapeDef sd = b2DefaultShapeDef();
            sd.material.friction = 0.5f;
            sd.material.restitution = 0.0f;
            sd.filter.categoryBits = category_bits(0);
            sd.filter.maskBits = ~0ull;
            sd.enableSensorEvents = false;
            sd.enableContactEvents = true;
            sd.enableHitEvents = true;
            for (const Run& r : runs) {
                // Tilemap origin = TOP-LEFT corner, +Y up: tile (c, r) spans x in [c*tw, (c+1)*tw], y in [-(r+1)*th, -r*th].
                float cx = (float(r.c0 + r.c1 + 1) * 0.5f) * tw;
                float cy = -(float(r.r0 + r.r1 + 1) * 0.5f) * th;
                float hx = std::max(float(r.c1 - r.c0 + 1) * tw * 0.5f * inv, kMinHalf);
                float hy = std::max(float(r.r1 - r.r0 + 1) * th * 0.5f * inv, kMinHalf);
                b2Polygon poly = b2MakeOffsetBox(hx, hy, {cx * inv, cy * inv}, b2MakeRot(0.0f));
                b2ShapeId sid = b2CreatePolygonShape(tb.body, &sd, &poly);
                register_shape(sid, e, false, false, &tb.shapeKeys);
                // world-space AABB (rotation ignored for debug)
                float wx = pose.position.x + cx, wy = pose.position.y + cy;
                tb.boxes.push_back(Rect::from_center({wx, wy}, {hx * 2 / inv, hy * 2 / inv}));
            }
            it = tiles_.emplace(key, std::move(tb)).first;
        }
        TileBody& tb = it->second;
        tb.seen = stepCounter_;
        // Tilemap moved by gameplay: teleport the static body.
        if (active && (std::fabs(pose.position.x - tb.pos.x) > 1e-3f || std::fabs(pose.position.y - tb.pos.y) > 1e-3f ||
                       std::fabs(wrap_deg(pose.rotZ - tb.rotZ)) > 1e-3f)) {
            b2Body_SetTransform(tb.body, {pose.position.x * inv, pose.position.y * inv}, b2MakeRot(radians(pose.rotZ)));
            tb.pos = pose.position;
            tb.rotZ = pose.rotZ;
        }
        if (active != b2Body_IsEnabled(tb.body)) {
            if (active) b2Body_Enable(tb.body);
            else b2Body_Disable(tb.body);
        }
    }
}

void Physics2D::writeback(World& world, Entity e, Body& b, RigidBody2D* rb) {
    if (b.type == BodyType::Static || !b.enabled) return;
    const float ppm = settings_.pixelsPerMeter;
    if (b2Body_IsAwake(b.body)) {
        b2Vec2 p = b2Body_GetPosition(b.body);
        float ang = b2Rot_GetAngle(b2Body_GetRotation(b.body));
        float unwrapped = b.lastB2Angle + wrap_pi(ang - b.lastB2Angle);
        if (p.x != b.lastB2Pos.x || p.y != b.lastB2Pos.y || unwrapped != b.lastB2Angle) {
            WorldPose cur = world_pose(world, e);
            Transform* t = world.get<Transform>(e);
            float newRot = degrees(unwrapped);
            if (t) t->rotation.z += newRot - cur.rotZ;
            world.set_world_position(e, {p.x * ppm, p.y * ppm, cur.position.z});
            WorldPose after = world_pose(world, e);
            b.lastPos = after.position;
            b.lastRotZ = after.rotZ;
            b.lastB2Pos = p;
            b.lastB2Angle = unwrapped;
            b.contAngle = unwrapped;
        }
    }
    if (rb) {
        b2Vec2 v = b2Body_GetLinearVelocity(b.body);
        rb->velocity = {v.x * ppm, v.y * ppm};
        rb->angularVelocity = degrees(b2Body_GetAngularVelocity(b.body));
        b.lastVel = rb->velocity;
        b.lastAngVel = rb->angularVelocity;
    }
}

void Physics2D::collect_events(World& world) {
    const float ppm = settings_.pixelsPerMeter;
    b2ContactEvents ce = b2World_GetContactEvents(world_);
    std::map<std::pair<std::uint64_t, std::uint64_t>, float> hits;
    for (int i = 0; i < ce.hitCount; ++i) {
        const b2ContactHitEvent& h = ce.hitEvents[i];
        auto k = std::make_pair(shape_key(h.shapeIdA), shape_key(h.shapeIdB));
        hits[k] = std::max(hits[k], h.approachSpeed * ppm);
    }
    auto& out = world.events().collisions;
    for (int i = 0; i < ce.beginCount; ++i) {
        const b2ContactBeginTouchEvent& ev = ce.beginEvents[i];
        Entity a = entity_of_alive(world, ev.shapeIdA, nullptr);
        Entity b = entity_of_alive(world, ev.shapeIdB, nullptr);
        if (a.is_null() || b.is_null() || a == b) continue;
        CollisionEvent c;
        c.phase = CollisionEvent::Phase::Begin;
        c.a = a;
        c.b = b;
        c.trigger = false;
        c.normal = {ev.manifold.normal.x, ev.manifold.normal.y, 0.0f};
        if (ev.manifold.pointCount > 0) {
            b2Vec2 pt = ev.manifold.points[0].point;
            if (ev.manifold.pointCount > 1) {
                pt = {(pt.x + ev.manifold.points[1].point.x) * 0.5f, (pt.y + ev.manifold.points[1].point.y) * 0.5f};
            }
            c.point = {pt.x * ppm, pt.y * ppm, 0.0f};
        } else {
            c.point = world.world_position(a);
        }
        auto it = hits.find({shape_key(ev.shapeIdA), shape_key(ev.shapeIdB)});
        if (it == hits.end()) it = hits.find({shape_key(ev.shapeIdB), shape_key(ev.shapeIdA)});
        c.impulse = it != hits.end() ? it->second : 0.0f;
        out.push_back(c);
    }
    for (int i = 0; i < ce.endCount; ++i) {
        const b2ContactEndTouchEvent& ev = ce.endEvents[i];
        Entity a = entity_of_alive(world, ev.shapeIdA, nullptr);
        Entity b = entity_of_alive(world, ev.shapeIdB, nullptr);
        if (a.is_null() || b.is_null() || a == b) continue;
        CollisionEvent c;
        c.phase = CollisionEvent::Phase::End;
        c.a = a;
        c.b = b;
        out.push_back(c);
    }
    b2SensorEvents se = b2World_GetSensorEvents(world_);
    auto sensor_event = [&](b2ShapeId s, b2ShapeId v, CollisionEvent::Phase ph) {
        Entity a = entity_of_alive(world, s, nullptr);
        Entity b = entity_of_alive(world, v, nullptr);
        if (a.is_null() || b.is_null() || a == b) return;
        CollisionEvent c;
        c.phase = ph;
        c.a = a;
        c.b = b;
        c.trigger = true;
        if (ph == CollisionEvent::Phase::Begin) {
            Vec3 pa = world.world_position(a), pb = world.world_position(b);
            Vec3 d = pb - pa;
            c.normal = normalize(Vec3{d.x, d.y, 0.0f});
            c.point = pb;
        }
        out.push_back(c);
    };
    for (int i = 0; i < se.beginCount; ++i) sensor_event(se.beginEvents[i].sensorShapeId, se.beginEvents[i].visitorShapeId, CollisionEvent::Phase::Begin);
    for (int i = 0; i < se.endCount; ++i) {
        // Shapes may already be destroyed; the lookup table still knows them for one more step.
        sensor_event(se.endEvents[i].sensorShapeId, se.endEvents[i].visitorShapeId, CollisionEvent::Phase::End);
    }
}

// One-way platforms (Box2D pre-solve; runs on the calling thread because workerCount = 1). The contact is kept
// only if the visitor was fully above the platform's top (previous-step AABBs) and is not moving up relative to it.
bool Physics2D::pre_solve(b2ShapeId idA, b2ShapeId idB, b2Manifold*, void* ctx) {
    const auto* self = static_cast<const Physics2D*>(ctx);
    auto fa = self->shapes_.find(shape_key(idA));
    auto fb = self->shapes_.find(shape_key(idB));
    const bool aOne = fa != self->shapes_.end() && fa->second.oneWay;
    const bool bOne = fb != self->shapes_.end() && fb->second.oneWay;
    if (!aOne && !bOne) return true;
    if (aOne && bOne) return true;
    const b2ShapeId plat = aOne ? idA : idB, vis = aOne ? idB : idA;
    const b2BodyId pb = b2Shape_GetBody(plat), vb = b2Shape_GetBody(vis);
    const b2Rot q = b2Body_GetRotation(pb);
    const float up = q.c >= 0.0f ? 1.0f : -1.0f;  // platform +Y has y = cos(rotation)
    const b2AABB pa = b2Shape_GetAABB(plat), va = b2Shape_GetAABB(vis);
    const float platTop = up > 0 ? pa.upperBound.y : -pa.lowerBound.y;
    const float visBottom = up > 0 ? va.lowerBound.y : -va.upperBound.y;
    const float relV = up * (b2Body_GetLinearVelocity(vb).y - b2Body_GetLinearVelocity(pb).y);
    const float slop = 0.02f + std::max(0.0f, -relV) * (1.0f / 30.0f);
    if (relV > 0.05f) return false;  // moving up through it
    return visBottom >= platTop - slop;
}

void Physics2D::step(World& world, float dt) {
    ensure_world(world);
    ++stepCounter_;
    const float inv = 1.0f / settings_.pixelsPerMeter;
    Vec2 g = world.settings().gravity2D;
    if (g.x != lastGravity_.x || g.y != lastGravity_.y) {
        b2World_SetGravity(world_, {g.x * inv, g.y * inv});
        for (auto& [k, body] : bodies_) {
            if (body.type == BodyType::Dynamic && body.enabled) b2Body_SetAwake(body.body, true);
        }
        lastGravity_ = g;
    }

    // ---- 1. sync bodies with components (creation order)
    order_.clear();
    for (Entity e : world.entities()) {
        RigidBody2D* rb = world.get<RigidBody2D>(e);
        Collider2D* col = world.get<Collider2D>(e);
        if (!rb && !col) continue;
        sync_entity(world, e, rb, col);
    }
    sync_tilemaps(world);
    // sweep: destroyed entities / removed components
    for (auto it = bodies_.begin(); it != bodies_.end();) {
        if (it->second.seen != stepCounter_ || !world.alive(it->second.e)) {
            destroy_body(it->second);
            it = bodies_.erase(it);
        } else {
            ++it;
        }
    }
    for (auto it = tiles_.begin(); it != tiles_.end();) {
        if (it->second.seen != stepCounter_ || !world.alive(it->second.e)) {
            std::uint64_t k = it->first;
            ++it;
            destroy_tile_body(k);
        } else {
            ++it;
        }
    }

    // ---- 2. simulate
    b2World_Step(world_, dt, std::max(settings_.subSteps, 1));

    // ---- 3. write back
    for (Entity e : order_) {
        auto it = bodies_.find(e.bits());
        if (it == bodies_.end() || !world.alive(e)) continue;
        writeback(world, e, it->second, world.get<RigidBody2D>(e));
    }

    // ---- 4. events
    collect_events(world);
    for (std::uint64_t k : deadPrev_) shapes_.erase(k);
    deadPrev_ = std::move(deadNow_);
    deadNow_.clear();
}

// ------------------------------------------------------------- queries ----
namespace {
struct RayCtx {
    std::function<bool(b2ShapeId)> accept;
    b2ShapeId shape = b2_nullShapeId;
    b2Vec2 point{0, 0}, normal{0, 0};
    float fraction = 2.0f;
    bool hit = false;
};
float ray_cb(b2ShapeId shape, b2Vec2 point, b2Vec2 normal, float fraction, void* ctx) {
    auto* c = static_cast<RayCtx*>(ctx);
    if (!c->accept(shape)) return -1.0f;
    if (fraction < c->fraction) {
        c->fraction = fraction;
        c->shape = shape;
        c->point = point;
        c->normal = normal;
        c->hit = true;
    }
    return fraction;
}
struct OverlapCtx {
    std::function<void(b2ShapeId)> add;
};
bool overlap_cb(b2ShapeId shape, void* ctx) {
    static_cast<OverlapCtx*>(ctx)->add(shape);
    return true;
}
}  // namespace

std::optional<RaycastHit> Physics2D::raycast(World& world, Vec2 from, Vec2 to, const RaycastOptions& opt) {
    ensure_world(world);
    const float ppm = settings_.pixelsPerMeter;
    Vec2 d = to - from;
    float len = length(d);
    if (len < 1e-6f) return std::nullopt;
    RayCtx ctx;
    const b2Vec2 origin{from.x / ppm, from.y / ppm};
    ctx.accept = [&](b2ShapeId s) {
        bool trig = false;
        Entity e = entity_of(s, &trig);
        if (e.is_null() || !world.alive(e)) return false;
        if (trig && opt.ignoreTriggers) return false;
        if (entity_or_ancestor_is(world, e, opt.ignore)) return false;
        if (b2Shape_TestPoint(s, origin)) return false;  // origin inside this collider: skip it
        return true;
    };
    b2QueryFilter qf = b2DefaultQueryFilter();
    qf.categoryBits = ~0ull;
    qf.maskBits = mask_bits(opt.mask);
    b2World_CastRay(world_, {from.x / ppm, from.y / ppm}, {d.x / ppm, d.y / ppm}, qf, ray_cb, &ctx);
    if (!ctx.hit) return std::nullopt;
    RaycastHit h;
    h.entity = entity_of(ctx.shape);
    h.point = {ctx.point.x * ppm, ctx.point.y * ppm, 0.0f};
    h.normal = {ctx.normal.x, ctx.normal.y, 0.0f};
    h.distance = ctx.fraction * len;
    return h;
}

static std::vector<Entity> finish_overlap(std::vector<std::uint64_t>& bits, const World& world) {
    std::sort(bits.begin(), bits.end());
    bits.erase(std::unique(bits.begin(), bits.end()), bits.end());
    std::vector<Entity> out;
    for (std::uint64_t b : bits) {
        Entity e = Entity::from_bits(b);
        if (world.alive(e)) out.push_back(e);
    }
    return out;
}

std::vector<Entity> Physics2D::overlap_circle(World& world, Vec2 center, float radius, std::int32_t mask) {
    ensure_world(world);
    const float ppm = settings_.pixelsPerMeter;
    b2Vec2 c{center.x / ppm, center.y / ppm};
    b2ShapeProxy proxy = b2MakeProxy(&c, 1, std::max(radius, 0.0f) / ppm);
    std::vector<std::uint64_t> bits;
    OverlapCtx ctx{[&](b2ShapeId s) {
        Entity e = entity_of(s);
        if (!e.is_null()) bits.push_back(e.bits());
    }};
    b2QueryFilter qf = b2DefaultQueryFilter();
    qf.categoryBits = ~0ull;
    qf.maskBits = mask_bits(mask);
    b2World_OverlapShape(world_, &proxy, qf, overlap_cb, &ctx);
    return finish_overlap(bits, world);
}

std::vector<Entity> Physics2D::overlap_box(World& world, Rect box, std::int32_t mask) {
    ensure_world(world);
    const float ppm = settings_.pixelsPerMeter;
    b2Vec2 pts[4] = {{box.x / ppm, box.y / ppm},
                     {(box.x + box.w) / ppm, box.y / ppm},
                     {(box.x + box.w) / ppm, (box.y + box.h) / ppm},
                     {box.x / ppm, (box.y + box.h) / ppm}};
    b2ShapeProxy proxy = b2MakeProxy(pts, 4, 0.0f);
    std::vector<std::uint64_t> bits;
    OverlapCtx ctx{[&](b2ShapeId s) {
        Entity e = entity_of(s);
        if (!e.is_null()) bits.push_back(e.bits());
    }};
    b2QueryFilter qf = b2DefaultQueryFilter();
    qf.categoryBits = ~0ull;
    qf.maskBits = mask_bits(mask);
    b2World_OverlapShape(world_, &proxy, qf, overlap_cb, &ctx);
    return finish_overlap(bits, world);
}

// ------------------------------------------------------- direct control ----
void Physics2D::apply_impulse(World& world, Entity e, Vec3 impulse) {
    auto it = bodies_.find(e.bits());
    if (it == bodies_.end() || it->second.type != BodyType::Dynamic) return;
    const float inv = 1.0f / settings_.pixelsPerMeter;
    b2Body_ApplyLinearImpulseToCenter(it->second.body, {impulse.x * inv, impulse.y * inv}, true);
    if (auto* rb = world.get<RigidBody2D>(e)) {
        b2Vec2 v = b2Body_GetLinearVelocity(it->second.body);
        rb->velocity = {v.x / inv, v.y / inv};
        it->second.lastVel = rb->velocity;
    }
}

void Physics2D::apply_force(World& world, Entity e, Vec3 force) {
    (void)world;
    auto it = bodies_.find(e.bits());
    if (it == bodies_.end() || it->second.type != BodyType::Dynamic) return;
    const float inv = 1.0f / settings_.pixelsPerMeter;
    b2Body_ApplyForceToCenter(it->second.body, {force.x * inv, force.y * inv}, true);
}

void Physics2D::set_velocity(World& world, Entity e, Vec3 velocity) {
    auto it = bodies_.find(e.bits());
    if (it == bodies_.end() || it->second.type == BodyType::Static) return;
    const float inv = 1.0f / settings_.pixelsPerMeter;
    b2Body_SetLinearVelocity(it->second.body, {velocity.x * inv, velocity.y * inv});
    b2Body_SetAwake(it->second.body, true);
    if (auto* rb = world.get<RigidBody2D>(e)) rb->velocity = {velocity.x, velocity.y};
    it->second.lastVel = {velocity.x, velocity.y};
}

bool Physics2D::is_touching(World& world, Entity e, Vec2 dir, float tolerance) {
    (void)world;
    auto it = bodies_.find(e.bits());
    if (it == bodies_.end() || !it->second.enabled || !b2Body_IsValid(it->second.body)) return false;
    float dl = std::sqrt(dir.x * dir.x + dir.y * dir.y);
    if (dl < 1e-6f) return false;
    dir = {dir.x / dl, dir.y / dl};
    const float tol = tolerance / settings_.pixelsPerMeter;
    int cap = b2Body_GetContactCapacity(it->second.body);
    if (cap <= 0) return false;
    std::vector<b2ContactData> cd(static_cast<std::size_t>(cap));
    int n = b2Body_GetContactData(it->second.body, cd.data(), cap);
    for (int i = 0; i < n; ++i) {
        const b2ContactData& c = cd[std::size_t(i)];
        if (c.manifold.pointCount <= 0) continue;
        bool weAreA = B2_ID_EQUALS(b2Shape_GetBody(c.shapeIdA), it->second.body);
        b2Vec2 toOther = weAreA ? c.manifold.normal : b2Vec2{-c.manifold.normal.x, -c.manifold.normal.y};
        // 0.7 is exactly the old is_grounded2d threshold for dir = {0,-1}.
        if (toOther.x * dir.x + toOther.y * dir.y <= 0.7f) continue;
        float sep = c.manifold.points[0].separation;
        if (c.manifold.pointCount > 1) sep = std::min(sep, c.manifold.points[1].separation);
        if (sep <= tol) return true;
    }
    return false;
}

// --------------------------------------------------------------- debug ----
void Physics2D::debug_state(const World& world, Json& out) const {
    const float ppm = settings_.pixelsPerMeter;
    auto shape_json = [&](const LocalShape& s) {
        Json j = Json::object();
        j["kind"] = s.kind == LocalShape::Box ? "box" : (s.kind == LocalShape::Circle ? "circle" : "capsule");
        if (s.kind == LocalShape::Box) j["size"] = Json::array({s.half.x * 2 * ppm, s.half.y * 2 * ppm});
        else if (s.kind == LocalShape::Circle) j["radius"] = s.half.x * ppm;
        else j["size"] = Json::array({s.half.x * 2 * ppm, (s.half.y + s.half.x) * 2 * ppm});
        j["offset"] = Json::array({s.offset.x * ppm, s.offset.y * ppm});
        j["trigger"] = s.trigger;
        return j;
    };
    for (Entity e : world.entities()) {
        auto it = bodies_.find(e.bits());
        if (it != bodies_.end() && b2Body_IsValid(it->second.body)) {
            const Body& b = it->second;
            Json j = Json::object();
            j["entity"] = world.id_of(e);
            j["dimension"] = "2d";
            j["type"] = type_name(b.type);
            b2Vec2 p = b2Body_GetPosition(b.body);
            b2Vec2 v = b2Body_GetLinearVelocity(b.body);
            j["position"] = Json::array({p.x * ppm, p.y * ppm});
            j["rotation"] = degrees(b2Rot_GetAngle(b2Body_GetRotation(b.body)));
            j["velocity"] = Json::array({v.x * ppm, v.y * ppm});
            j["awake"] = b2Body_IsAwake(b.body);
            j["enabled"] = b.enabled;
            Json shapes = Json::array();
            for (const LocalShape& s : b.shapes) shapes.push_back(shape_json(s));
            j["shapes"] = shapes;
            out.push_back(j);
        }
        auto tt = tiles_.find(e.bits());
        if (tt != tiles_.end()) {
            Json j = Json::object();
            j["entity"] = world.id_of(e);
            j["dimension"] = "2d";
            j["type"] = "static";
            j["kind"] = "tilemap";
            j["position"] = Json::array({tt->second.pos.x, tt->second.pos.y});
            j["shapeCount"] = tt->second.boxes.size();
            out.push_back(j);
        }
    }
}

void Physics2D::debug_shapes(const World& world, std::vector<Physics::DebugShape>& out) const {
    const float ppm = settings_.pixelsPerMeter;
    for (Entity e : world.entities()) {
        auto it = bodies_.find(e.bits());
        if (it != bodies_.end() && b2Body_IsValid(it->second.body) && it->second.enabled) {
            const Body& b = it->second;
            b2Transform xf = b2Body_GetTransform(b.body);
            float rotDeg = degrees(b2Rot_GetAngle(xf.q));
            for (const LocalShape& s : b.shapes) {
                b2Vec2 c = b2TransformPoint(xf, {s.offset.x, s.offset.y});
                Vec3 center{c.x * ppm, c.y * ppm, 0.0f};
                if (s.kind == LocalShape::Circle) {
                    out.push_back({Physics::DebugShape::Circle, center, {s.half.x * 2 * ppm, s.half.x * 2 * ppm, 0}, rotDeg, s.trigger});
                } else if (s.kind == LocalShape::Box) {
                    out.push_back({Physics::DebugShape::Box, center, {s.half.x * 2 * ppm, s.half.y * 2 * ppm, 0}, rotDeg, s.trigger});
                } else {
                    out.push_back({Physics::DebugShape::Box, center, {s.half.x * 2 * ppm, (s.half.y + s.half.x) * 2 * ppm, 0}, rotDeg, s.trigger});
                }
            }
        }
        auto tt = tiles_.find(e.bits());
        if (tt != tiles_.end()) {
            for (const Rect& r : tt->second.boxes) {
                out.push_back({Physics::DebugShape::Box, {r.center().x, r.center().y, 0.0f}, {r.w, r.h, 0.0f}, 0.0f, false});
            }
        }
    }
}

}  // namespace fa::detail
