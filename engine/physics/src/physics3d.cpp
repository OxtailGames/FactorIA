// Simple 3D physics: spheres + axis-aligned boxes, semi-implicit Euler, impulse resolution.
// Rotation is ignored (colliders are always axis-aligned); Transform.rotation is never written.
#include <algorithm>
#include <cmath>
#include <unordered_set>

#include "physics_internal.h"

namespace fa::detail {

namespace {
constexpr float kSlop = 0.001f;           // allowed penetration (m)
constexpr float kPercent = 0.9f;          // positional correction strength
constexpr float kBounceThreshold = 0.5f;  // m/s below which restitution is ignored
constexpr float kBeginMargin = 0.01f;     // solid contact begins within this gap
constexpr float kEndMargin = 0.05f;       // ...and ends once the gap exceeds this
constexpr int kIterations = 2;

const char* type_name(BodyType t) {
    switch (t) {
        case BodyType::Static: return "static";
        case BodyType::Kinematic: return "kinematic";
        default: return "dynamic";
    }
}
}  // namespace

void Physics3D::reset() {
    bodies_.clear();
    index_.clear();
    touching_.clear();
    lastWorld_ = nullptr;
    nextSeq_ = 1;
}

bool Physics3D::filters_pass(const Body& a, const Body& b) {
    return (category_bits(a.layer) & mask_bits(b.mask)) != 0 && (category_bits(b.layer) & mask_bits(a.mask)) != 0;
}

// Contact between a and b; normal points from a to b. depth > 0 means penetrating; hit when depth > -margin.
Physics3D::Contact Physics3D::collide(const Body& a, const Body& b, float margin) {
    Contact c;
    if (!a.hasShape || !b.hasShape) return c;
    auto sphere_box = [&](const Body& box, const Body& sph, Contact& out) {  // normal: box -> sphere
        Vec3 lo = box.center - box.half, hi = box.center + box.half;
        Vec3 q = min(max(sph.center, lo), hi);
        Vec3 diff = sph.center - q;
        float dist = length(diff);
        if (dist > 1e-6f) {
            out.depth = sph.radius - dist;
            out.normal = diff / dist;
            out.point = q;
        } else {  // center inside the box: exit through the nearest face
            int axis = 0;
            float best = 1e30f;
            float sgn = 1.0f;
            for (int i = 0; i < 3; ++i) {
                float d = sph.center[i] - box.center[i];
                float pen = box.half[i] - std::fabs(d);
                if (pen < best) { best = pen; axis = i; sgn = d >= 0.0f ? 1.0f : -1.0f; }
            }
            out.normal = {};
            out.normal[axis] = sgn;
            out.depth = best + sph.radius;
            out.point = sph.center;
        }
        out.hit = out.depth > -margin;
    };
    if (!a.box && !b.box) {
        Vec3 d = b.center - a.center;
        float dist = length(d);
        c.depth = a.radius + b.radius - dist;
        c.normal = dist > 1e-6f ? d / dist : Vec3{0, 1, 0};
        c.point = a.center + c.normal * a.radius;
        c.hit = c.depth > -margin;
    } else if (a.box && b.box) {
        Vec3 d = b.center - a.center;
        float best = 1e30f;
        int axis = 0;
        for (int i = 0; i < 3; ++i) {
            float o = a.half[i] + b.half[i] - std::fabs(d[i]);
            if (o <= -margin) return c;
            if (o < best) { best = o; axis = i; }
        }
        c.depth = best;
        c.normal = {};
        c.normal[axis] = d[axis] >= 0.0f ? 1.0f : -1.0f;
        Vec3 lo = max(a.center - a.half, b.center - b.half), hi = min(a.center + a.half, b.center + b.half);
        c.point = (lo + hi) * 0.5f;
        c.hit = true;
    } else if (a.box) {
        sphere_box(a, b, c);
    } else {
        sphere_box(b, a, c);
        c.normal = -c.normal;
    }
    return c;
}

void Physics3D::sync(World& world) {
    const std::uint64_t stamp = stepCounter_;
    for (Entity e : world.entities()) {
        RigidBody3D* rb = world.get<RigidBody3D>(e);
        Collider3D* col = world.get<Collider3D>(e);
        if (!rb && !col) continue;
        const std::uint64_t key = e.bits();
        WorldPose pose = world_pose(world, e);
        auto it = index_.find(key);
        if (it != index_.end() && bodies_[it->second].id != world.id_of(e)) {
            bodies_[it->second] = Body{};  // entity slot reused after World::clear(): start fresh
            bodies_[it->second].seq = nextSeq_++;
            bodies_[it->second].e = e;
            bodies_[it->second].id = world.id_of(e);
            bodies_[it->second].lastPos = pose.position + Vec3{1e9f, 0, 0};  // force initial placement below
        }
        if (it == index_.end()) {
            Body nb;
            nb.e = e;
            nb.id = world.id_of(e);
            nb.seq = nextSeq_++;
            nb.lastPos = pose.position;
            nb.lastVel = rb ? rb->velocity : Vec3{};
            nb.vel = nb.lastVel;
            bodies_.push_back(std::move(nb));
            it = index_.emplace(key, bodies_.size() - 1).first;
            bodies_.back().center = pose.position;  // refined below
        }
        Body& b = bodies_[it->second];
        b.seen = stamp;
        b.type = rb ? rb->type : BodyType::Static;
        b.hasRigid = rb != nullptr;
        b.mass = rb ? std::max(rb->mass, 1e-4f) : 1.0f;
        b.invMass = b.type == BodyType::Dynamic ? 1.0f / b.mass : 0.0f;
        b.gravityScale = rb ? rb->gravityScale : 1.0f;
        b.damping = rb ? std::max(rb->linearDamping, 0.0f) : 0.0f;
        b.hasShape = col != nullptr;
        if (col) {
            Vec3 as{std::fabs(pose.scale.x), std::fabs(pose.scale.y), std::fabs(pose.scale.z)};
            b.box = col->shape == ColliderShape3D::Box;
            b.half = {std::max(col->size.x * as.x * 0.5f, 1e-3f), std::max(col->size.y * as.y * 0.5f, 1e-3f),
                      std::max(col->size.z * as.z * 0.5f, 1e-3f)};
            b.radius = std::max(col->radius * std::max({as.x, as.y, as.z}), 1e-3f);
            b.offset = col->offset * pose.scale;
            b.trigger = col->isTrigger;
            b.friction = std::max(col->friction, 0.0f);
            b.restitution = std::max(col->restitution, 0.0f);
            b.layer = col->layer;
            b.mask = col->mask;
        } else {
            b.offset = {};
            b.trigger = false;
        }
        b.enabled = world.active_in_hierarchy(e);
        if (!b.enabled) continue;
        // Gameplay moved the Transform since the last writeback -> teleport (keep velocity).
        Vec3 dp = pose.position - b.lastPos;
        if (std::fabs(dp.x) > 1e-4f || std::fabs(dp.y) > 1e-4f || std::fabs(dp.z) > 1e-4f || b.type == BodyType::Static) {
            b.center = pose.position + b.offset;
            b.lastPos = pose.position;
            b.lastCenter = b.center;
        }
        if (rb && rb->velocity != b.lastVel) {
            b.vel = rb->velocity;
            b.lastVel = rb->velocity;
        }
    }
    // Sweep destroyed entities / removed components, keeping creation order.
    bool any = false;
    for (const Body& b : bodies_) if (b.seen != stamp || !world.alive(b.e)) { any = true; break; }
    if (any) {
        std::vector<Body> kept;
        kept.reserve(bodies_.size());
        for (Body& b : bodies_) if (b.seen == stamp && world.alive(b.e)) kept.push_back(std::move(b));
        bodies_ = std::move(kept);
        index_.clear();
        for (std::size_t i = 0; i < bodies_.size(); ++i) index_[bodies_[i].e.bits()] = i;
    }
}

void Physics3D::solve_pair(Body& a, Body& b, const Contact& c, float, float& impact) {
    const float ia = a.invMass, ib = b.invMass, sum = ia + ib;
    if (sum <= 0.0f) return;
    const Vec3 n = c.normal;
    if (c.depth > kSlop) {
        Vec3 corr = n * ((c.depth - kSlop) * kPercent / sum);
        a.center -= corr * ia;
        b.center += corr * ib;
    }
    Vec3 rv = b.vel - a.vel;
    float vn = dot(rv, n);
    float j = 0.0f;
    if (vn < 0.0f) {
        float e = std::max(a.restitution, b.restitution);
        if (-vn < kBounceThreshold) e = 0.0f;
        j = -(1.0f + e) * vn / sum;
        a.vel -= n * (j * ia);
        b.vel += n * (j * ib);
        impact = std::max(impact, -vn);
    }
    if (j > 0.0f) {
        rv = b.vel - a.vel;
        Vec3 vt = rv - n * dot(rv, n);
        float lt = length(vt);
        if (lt > 1e-6f) {
            float mu = std::sqrt(a.friction * b.friction);
            float jt = std::min(lt / sum, mu * j);
            Vec3 t = vt / lt;
            a.vel += t * (jt * ia);
            b.vel -= t * (jt * ib);
        }
    }
}

void Physics3D::step(World& world, float dt) {
    if (lastWorld_ != &world) {
        reset();
        lastWorld_ = &world;
    }
    ++stepCounter_;
    sync(world);
    const std::size_t n = bodies_.size();
    if (n == 0) {
        touching_.clear();
        return;
    }
    const Vec3 g = world.settings().gravity3D;
    const int subs = std::max(settings_.subSteps, 1);
    const float h = dt / float(subs);
    std::map<PairKey, float> impacts;

    auto movable = [](const Body& b) { return b.type != BodyType::Static; };
    for (int s = 0; s < subs; ++s) {
        for (Body& b : bodies_) {
            if (!b.enabled) continue;
            if (b.type == BodyType::Dynamic) {
                b.vel += (g * b.gravityScale + b.force * b.invMass) * h;
                if (b.damping > 0.0f) b.vel *= 1.0f / (1.0f + h * b.damping);
                b.center += b.vel * h;
            } else if (b.type == BodyType::Kinematic) {
                b.center += b.vel * h;
            }
        }
        for (int it = 0; it < kIterations; ++it) {
            for (std::size_t i = 0; i < n; ++i) {
                Body& a = bodies_[i];
                if (!a.enabled || !a.hasShape || a.trigger) continue;
                for (std::size_t k = i + 1; k < n; ++k) {
                    Body& b = bodies_[k];
                    if (!b.enabled || !b.hasShape || b.trigger) continue;
                    if (a.type != BodyType::Dynamic && b.type != BodyType::Dynamic) continue;
                    if (!filters_pass(a, b)) continue;
                    Contact c = collide(a, b, 0.0f);
                    if (!c.hit || c.depth < 0.0f) continue;
                    float& impact = impacts[{a.seq, b.seq}];
                    solve_pair(a, b, c, h, impact);
                }
            }
        }
    }
    for (Body& b : bodies_) b.force = {};

    // ---- events: track overlapping pairs across frames
    std::map<PairKey, PairState> cur;
    auto& out = world.events().collisions;
    struct Begin { PairKey key; PairState st; Contact c; };
    std::vector<Begin> begins;
    for (std::size_t i = 0; i < n; ++i) {
        const Body& a = bodies_[i];
        if (!a.enabled || !a.hasShape) continue;
        for (std::size_t k = i + 1; k < n; ++k) {
            const Body& b = bodies_[k];
            if (!b.enabled || !b.hasShape) continue;
            if (!movable(a) && !movable(b)) continue;
            if (!filters_pass(a, b)) continue;
            const bool trig = a.trigger || b.trigger;
            if (trig && a.trigger && b.trigger) continue;
            PairKey key{a.seq, b.seq};
            bool was = touching_.count(key) != 0;
            float margin = trig ? 0.0f : (was ? kEndMargin : kBeginMargin);
            Contact c = collide(a, b, margin);
            bool now = trig ? (c.hit && c.depth > 0.0f) : c.hit;
            if (!now) continue;
            PairState st{a.e, b.e, trig};
            cur[key] = st;
            if (!was) begins.push_back({key, st, c});
        }
    }
    for (auto& [key, st] : touching_) {
        if (cur.count(key)) continue;
        if (!world.alive(st.a) || !world.alive(st.b)) continue;
        CollisionEvent ev;
        ev.phase = CollisionEvent::Phase::End;
        ev.a = st.a;
        ev.b = st.b;
        ev.trigger = st.trigger;
        out.push_back(ev);
    }
    for (Begin& bg : begins) {
        CollisionEvent ev;
        ev.phase = CollisionEvent::Phase::Begin;
        ev.a = bg.st.a;
        ev.b = bg.st.b;
        ev.trigger = bg.st.trigger;
        ev.point = bg.c.point;
        ev.normal = bg.c.normal;
        auto im = impacts.find(bg.key);
        ev.impulse = im != impacts.end() ? im->second : 0.0f;
        out.push_back(ev);
    }
    touching_ = std::move(cur);

    // ---- write back
    for (Body& b : bodies_) {
        if (!b.enabled || b.type == BodyType::Static || !world.alive(b.e)) continue;
        if (b.center != b.lastCenter) {
            world.set_world_position(b.e, b.center - b.offset);
            b.lastPos = world.world_position(b.e);
            b.lastCenter = b.center;
        }
        if (RigidBody3D* rb = world.get<RigidBody3D>(b.e)) {
            rb->velocity = b.vel;
            b.lastVel = b.vel;
        }
    }
}

// ------------------------------------------------------------- queries ----
std::optional<RaycastHit> Physics3D::raycast(World& world, Vec3 origin, Vec3 dir, float maxDistance, std::int32_t mask) {
    (void)world;
    Vec3 d = normalize(dir);
    if (length_sq(d) < 0.5f) return std::nullopt;
    const std::uint64_t qmask = mask_bits(mask);
    float bestT = maxDistance;
    const Body* best = nullptr;
    Vec3 bestN;
    for (const Body& b : bodies_) {
        if (!b.enabled || !b.hasShape || b.trigger) continue;
        if ((category_bits(b.layer) & qmask) == 0) continue;
        float t = 0.0f;
        Vec3 nrm;
        if (b.box) {
            Vec3 lo = b.center - b.half, hi = b.center + b.half;
            float tmin = 0.0f, tmax = bestT;
            int axisHit = -1;
            float sgnHit = 0.0f;
            bool miss = false;
            for (int i = 0; i < 3 && !miss; ++i) {
                if (std::fabs(d[i]) < 1e-9f) {
                    if (origin[i] < lo[i] || origin[i] > hi[i]) miss = true;
                } else {
                    float t1 = (lo[i] - origin[i]) / d[i], t2 = (hi[i] - origin[i]) / d[i];
                    float sgn = -1.0f;  // entering through the low face -> normal points to -axis
                    if (t1 > t2) { std::swap(t1, t2); sgn = 1.0f; }
                    if (t1 > tmin) { tmin = t1; axisHit = i; sgnHit = sgn; }
                    tmax = std::min(tmax, t2);
                    if (tmin > tmax) miss = true;
                }
            }
            if (miss) continue;
            t = tmin;
            if (axisHit >= 0) { nrm = {}; nrm[axisHit] = sgnHit; }
            else nrm = -d;  // origin inside the box
        } else {
            Vec3 m = origin - b.center;
            float bb = dot(m, d), cc = dot(m, m) - b.radius * b.radius;
            if (cc > 0.0f && bb > 0.0f) continue;
            float disc = bb * bb - cc;
            if (disc < 0.0f) continue;
            t = std::max(-bb - std::sqrt(disc), 0.0f);
            Vec3 p = origin + d * t;
            nrm = cc <= 0.0f ? -d : normalize(p - b.center);
        }
        if (t <= bestT) {
            bestT = t;
            best = &b;
            bestN = nrm;
        }
    }
    if (!best) return std::nullopt;
    RaycastHit h;
    h.entity = best->e;
    h.point = origin + d * bestT;
    h.normal = bestN;
    h.distance = bestT;
    return h;
}

std::vector<Entity> Physics3D::overlap_sphere(World& world, Vec3 center, float radius, std::int32_t mask) {
    std::vector<Entity> out;
    Body probe;
    probe.box = false;
    probe.hasShape = true;
    probe.radius = std::max(radius, 0.0f);
    probe.center = center;
    const std::uint64_t qmask = mask_bits(mask);
    for (const Body& b : bodies_) {
        if (!b.enabled || !b.hasShape || !world.alive(b.e)) continue;
        if ((category_bits(b.layer) & qmask) == 0) continue;
        Contact c = collide(probe, b, 0.0f);
        if (c.hit && c.depth >= 0.0f) out.push_back(b.e);
    }
    return out;
}

// ------------------------------------------------------- direct control ----
void Physics3D::apply_impulse(World& world, Entity e, Vec3 impulse) {
    auto it = index_.find(e.bits());
    if (it == index_.end()) return;
    Body& b = bodies_[it->second];
    if (b.type != BodyType::Dynamic) return;
    b.vel += impulse * b.invMass;
    if (auto* rb = world.get<RigidBody3D>(e)) rb->velocity = b.vel;
    b.lastVel = b.vel;
}

void Physics3D::apply_force(World&, Entity e, Vec3 force) {
    auto it = index_.find(e.bits());
    if (it == index_.end()) return;
    Body& b = bodies_[it->second];
    if (b.type == BodyType::Dynamic) b.force += force;
}

void Physics3D::set_velocity(World& world, Entity e, Vec3 velocity) {
    auto it = index_.find(e.bits());
    if (it == index_.end()) return;
    Body& b = bodies_[it->second];
    if (b.type == BodyType::Static) return;
    b.vel = velocity;
    if (auto* rb = world.get<RigidBody3D>(e)) rb->velocity = velocity;
    b.lastVel = velocity;
}

// --------------------------------------------------------------- debug ----
void Physics3D::debug_state(const World& world, Json& out) const {
    for (const Body& b : bodies_) {
        if (!world.alive(b.e)) continue;
        Json j = Json::object();
        j["entity"] = world.id_of(b.e);
        j["dimension"] = "3d";
        j["type"] = type_name(b.type);
        Vec3 p = b.center - b.offset;
        j["position"] = Json::array({p.x, p.y, p.z});
        j["velocity"] = Json::array({b.vel.x, b.vel.y, b.vel.z});
        j["enabled"] = b.enabled;
        Json shapes = Json::array();
        if (b.hasShape) {
            Json s = Json::object();
            if (b.box) {
                s["kind"] = "box";
                s["size"] = Json::array({b.half.x * 2, b.half.y * 2, b.half.z * 2});
            } else {
                s["kind"] = "sphere";
                s["radius"] = b.radius;
            }
            s["offset"] = Json::array({b.offset.x, b.offset.y, b.offset.z});
            s["trigger"] = b.trigger;
            shapes.push_back(s);
        }
        j["shapes"] = shapes;
        out.push_back(j);
    }
}

void Physics3D::debug_shapes(const World& world, std::vector<Physics::DebugShape>& out) const {
    for (const Body& b : bodies_) {
        if (!b.enabled || !b.hasShape || !world.alive(b.e)) continue;
        if (b.box) out.push_back({Physics::DebugShape::Box, b.center, b.half * 2.0f, 0.0f, b.trigger});
        else out.push_back({Physics::DebugShape::Sphere, b.center, Vec3{b.radius * 2.0f}, 0.0f, b.trigger});
    }
}

}  // namespace fa::detail
