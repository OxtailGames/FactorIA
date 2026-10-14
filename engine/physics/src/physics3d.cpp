// Simple 3D physics: spheres + oriented boxes, semi-implicit Euler, impulse resolution, automatic continuous collision.
// Boxes follow the entity's world rotation; the rotation itself only comes from Transform / angularVelocity (collisions
// apply no torque). An unrotated box keeps the exact axis-aligned code paths.
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
constexpr float kRiderGap = 0.02f;    // a dynamic body this close above a kinematic one is carried by it
constexpr float kAlignedEps = 1e-6f;  // off-diagonal rotation below this = axis-aligned (exact AABB paths)
constexpr float kSweepTol = 1e-4f;    // swept contacts are bisected to this distance (m)
constexpr float kCastSkin = 0.01f;    // shape casts: penetration at `from` up to this is a resting touch, not an overlap

const char* type_name(BodyType t) {
    switch (t) {
        case BodyType::Static: return "static";
        case BodyType::Kinematic: return "kinematic";
        default: return "dynamic";
    }
}

constexpr Vec3 kIdentityAxes[3] = {{1, 0, 0}, {0, 1, 0}, {0, 0, 1}};

// Box frame <-> world: v.x * ax0 + v.y * ax1 + v.z * ax2, and its transpose.
Vec3 frame_to_world(const Vec3* ax, Vec3 v) { return ax[0] * v.x + ax[1] * v.y + ax[2] * v.z; }
Vec3 world_to_frame(const Vec3* ax, Vec3 v) { return {dot(v, ax[0]), dot(v, ax[1]), dot(v, ax[2])}; }

// Euler degrees (pitch about X, yaw about Y, roll about Z; R = Ry * Rx * Rz like Transform.rotation) of a unit basis.
Vec3 euler_of(const Vec3* ax) {
    const float sp = clamp(-ax[2].y, -1.0f, 1.0f);
    float yaw, roll;
    if (std::fabs(sp) < 0.9999f) {
        yaw = std::atan2(ax[2].x, ax[2].z);
        roll = std::atan2(ax[0].y, ax[1].y);
    } else {  // gimbal lock: fold the roll into the yaw
        yaw = std::atan2(-ax[0].z, ax[0].x);
        roll = 0.0f;
    }
    return {degrees(std::asin(sp)), degrees(yaw), degrees(roll)};
}

// Axis-aligned bounds of a shape (for the sweep broad phase); an unturned box has the identity frame, so this is `half`.
void bounds_of(const Vec3* ax, bool box, Vec3 center, Vec3 half, float radius, Vec3& lo, Vec3& hi) {
    const Vec3 e = !box ? Vec3{radius}
                        : Vec3{std::fabs(ax[0].x) * half.x + std::fabs(ax[1].x) * half.y + std::fabs(ax[2].x) * half.z,
                               std::fabs(ax[0].y) * half.x + std::fabs(ax[1].y) * half.y + std::fabs(ax[2].y) * half.z,
                               std::fabs(ax[0].z) * half.x + std::fabs(ax[1].z) * half.y + std::fabs(ax[2].z) * half.z};
    lo = center - e;
    hi = center + e;
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

// Sphere vs box; normal points from the box to the sphere. Rotated boxes work in the box frame.
void Physics3D::sphere_box(const Body& box, const Body& sph, float margin, Contact& out) {
    if (!box.rotated) {  // exact axis-aligned path
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
    } else {
        const Vec3 l = world_to_frame(box.ax, sph.center - box.center);  // sphere centre in the box frame
        const Vec3 q = min(max(l, -box.half), box.half);
        const Vec3 diff = l - q;
        const float dist = length(diff);
        Vec3 n;  // box frame
        if (dist > 1e-6f) {
            out.depth = sph.radius - dist;
            n = diff / dist;
            out.point = box.center + frame_to_world(box.ax, q);
        } else {  // center inside the box: exit through the nearest face
            int axis = 0;
            float best = 1e30f;
            float sgn = 1.0f;
            for (int i = 0; i < 3; ++i) {
                float pen = box.half[i] - std::fabs(l[i]);
                if (pen < best) { best = pen; axis = i; sgn = l[i] >= 0.0f ? 1.0f : -1.0f; }
            }
            n[axis] = sgn;
            out.depth = best + sph.radius;
            out.point = sph.center;
        }
        out.normal = frame_to_world(box.ax, n);
    }
    out.hit = out.depth > -margin;
}

// Oriented box vs oriented box (at least one turned): 15-axis SAT. The normal is the least-penetration axis, preferring
// the six face axes over the nine edge-edge axes unless an edge axis is clearly shallower (stable resting contacts).
void Physics3D::box_box_sat(const Body& a, const Body& b, float margin, Contact& c) {
    const Vec3 d = b.center - a.center;
    float faceOv = 1e30f, edgeOv = 1e30f;
    Vec3 faceN, edgeN;
    auto test = [&](Vec3 axis, bool edge) {  // false = separated by more than the margin
        float ra = 0.0f, rb = 0.0f;
        for (int i = 0; i < 3; ++i) {
            ra += std::fabs(dot(a.ax[i], axis)) * a.half[i];
            rb += std::fabs(dot(b.ax[i], axis)) * b.half[i];
        }
        const float proj = dot(d, axis);
        const float ov = ra + rb - std::fabs(proj);
        if (ov <= -margin) return false;
        float& best = edge ? edgeOv : faceOv;
        if (ov < best) {
            best = ov;
            (edge ? edgeN : faceN) = proj >= 0.0f ? axis : -axis;
        }
        return true;
    };
    for (int i = 0; i < 3; ++i) if (!test(a.ax[i], false) || !test(b.ax[i], false)) return;
    for (int i = 0; i < 3; ++i) {
        for (int j = 0; j < 3; ++j) {
            Vec3 x = cross(a.ax[i], b.ax[j]);
            const float len = length(x);
            if (len < 1e-4f) continue;  // parallel edges: the face axes cover them
            if (!test(x / len, true)) return;
        }
    }
    const bool useEdge = edgeOv < faceOv * 0.95f - 0.01f;
    c.depth = useEdge ? edgeOv : faceOv;
    c.normal = useEdge ? edgeN : faceN;
    // Contact point: b's deepest point against the normal (a face centre where b's face is parallel), averaged with its
    // closest point on a.
    Vec3 p = b.center;
    for (int i = 0; i < 3; ++i) {
        const float s = dot(c.normal, b.ax[i]);
        if (std::fabs(s) > 1e-4f) p -= b.ax[i] * (s > 0.0f ? b.half[i] : -b.half[i]);
    }
    const Vec3 q = a.center + frame_to_world(a.ax, min(max(world_to_frame(a.ax, p - a.center), -a.half), a.half));
    c.point = (p + q) * 0.5f;
    c.hit = true;
}

// Contact between a and b; normal points from a to b. depth > 0 means penetrating; hit when depth > -margin.
Physics3D::Contact Physics3D::collide(const Body& a, const Body& b, float margin) {
    Contact c;
    if (!a.hasShape || !b.hasShape) return c;
    if (!a.box && !b.box) {
        Vec3 d = b.center - a.center;
        float dist = length(d);
        c.depth = a.radius + b.radius - dist;
        c.normal = dist > 1e-6f ? d / dist : Vec3{0, 1, 0};
        c.point = a.center + c.normal * a.radius;
        c.hit = c.depth > -margin;
    } else if (a.box && b.box) {
        if (a.rotated || b.rotated) {
            box_box_sat(a, b, margin, c);
            return c;
        }
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
        sphere_box(a, b, margin, c);
    } else {
        sphere_box(b, a, margin, c);
        c.normal = -c.normal;
    }
    return c;
}

// First fraction t in (0, 1] of `disp` at which `mover` (centre moved by t * disp) overlaps `target`, found by stepping
// at most half the mover's smallest extent and bisecting the first overlapping step to kSweepTol (tHit overlaps, by
// <= ~0.1 mm). False when it never does, or when it already overlaps at t = 0 (that contact is left to the caller).
// The mover is restored before returning.
bool Physics3D::sweep(Body& mover, Vec3 disp, const Body& target, float& tHit) {
    const float len = length(disp);
    if (!(len > 0.0f) || !std::isfinite(len)) return false;
    Vec3 mlo, mhi, tlo, thi;
    bounds_of(mover.ax, mover.box, mover.center, mover.half, mover.radius, mlo, mhi);
    bounds_of(target.ax, target.box, target.center, target.half, target.radius, tlo, thi);
    const Vec3 slo = min(mlo, mlo + disp), shi = max(mhi, mhi + disp);  // broad phase: swept bounds vs target bounds
    if (slo.x > thi.x || shi.x < tlo.x || slo.y > thi.y || shi.y < tlo.y || slo.z > thi.z || shi.z < tlo.z)
        return false;
    const float extent = mover.box ? 2.0f * std::min({mover.half.x, mover.half.y, mover.half.z}) : 2.0f * mover.radius;
    const float steps = std::min(std::ceil(len / (0.5f * extent)), 100000.0f);
    const int n = std::max(int(steps), 1);
    const Vec3 from = mover.center;
    auto overlaps = [&](float t) {
        mover.center = from + disp * t;
        return collide(target, mover, 0.0f).hit;
    };
    bool found = false;
    if (!overlaps(0.0f)) {
        float lo = 0.0f;
        for (int i = 1; i <= n && !found; ++i) {
            const float t = float(i) / float(n);
            if (!overlaps(t)) { lo = t; continue; }
            float hi = t;
            for (int k = 0; k < 32 && (hi - lo) * len > kSweepTol; ++k) {
                const float mid = 0.5f * (lo + hi);
                if (overlaps(mid)) hi = mid;
                else lo = mid;
            }
            tHit = hi;
            found = true;
        }
    }
    mover.center = from;
    return found;
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
            nb.angVel = rb ? rb->angularVelocity : Vec3{};
            nb.lastAngVel = nb.angVel;
            bodies_.push_back(std::move(nb));
            it = index_.emplace(key, bodies_.size() - 1).first;
            bodies_.back().center = pose.position;  // the collider offset is added below
        }
        Body& b = bodies_[it->second];
        b.seen = stamp;
        b.type = rb ? rb->type : BodyType::Static;
        b.hasRigid = rb != nullptr;
        b.mass = rb ? std::max(rb->mass, 1e-4f) : 1.0f;
        b.invMass = b.type == BodyType::Dynamic ? 1.0f / b.mass : 0.0f;
        b.gravityScale = rb ? rb->gravityScale : 1.0f;
        b.damping = rb ? std::max(rb->linearDamping, 0.0f) : 0.0f;
        b.rollWithMotion = rb ? rb->rollWithMotion : false;
        b.hasShape = col != nullptr;
        const Vec3 oldOffset = b.offset;
        if (col) {
            Vec3 as{std::fabs(pose.scale.x), std::fabs(pose.scale.y), std::fabs(pose.scale.z)};
            b.box = col->shape == ColliderShape3D::Box;
            b.half = {std::max(col->size.x * as.x * 0.5f, 1e-3f), std::max(col->size.y * as.y * 0.5f, 1e-3f),
                      std::max(col->size.z * as.z * 0.5f, 1e-3f)};
            b.radius = std::max(col->radius * std::max({as.x, as.y, as.z}), 1e-3f);
            // Orientation = the entity's world rotation (columns normalised, so scale only sizes the box). An unturned
            // entity keeps the identity frame and the exact axis-aligned paths. ponytail: a sheared world matrix (a
            // non-uniformly scaled, rotated parent) has non-orthogonal columns, which are used as if orthonormal.
            const Vec3* r = pose.axis;
            const bool turned = std::fabs(r[0].y) > kAlignedEps || std::fabs(r[0].z) > kAlignedEps ||
                                std::fabs(r[1].x) > kAlignedEps || std::fabs(r[1].z) > kAlignedEps ||
                                std::fabs(r[2].x) > kAlignedEps || std::fabs(r[2].y) > kAlignedEps;
            const Vec3 local = col->offset * pose.scale;
            b.offset = turned ? frame_to_world(r, local) : local;
            b.rotated = b.box && turned;
            for (int i = 0; i < 3; ++i) b.ax[i] = b.rotated ? r[i] : kIdentityAxes[i];
            b.trigger = col->isTrigger;
            b.friction = std::max(col->friction, 0.0f);
            b.restitution = std::max(col->restitution, 0.0f);
            b.layer = col->layer;
            b.mask = col->mask;
        } else {
            b.offset = {};
            b.rotated = false;
            b.trigger = false;
        }
        b.rollMu = (rb && col && rb->type == BodyType::Dynamic && rb->rollWithMotion && !b.box)
                       ? std::max(rb->rollingFriction, 0.0f) : -1.0f;
        if (b.offset != oldOffset) {  // offset edited, or turned/scaled with the entity: the shape follows the origin
            b.center += b.offset - oldOffset;
            b.lastCenter += b.offset - oldOffset;
        }
        b.enabled = world.active_in_hierarchy(e);
        if (!b.enabled) continue;
        // Gameplay moved the Transform since the last writeback -> teleport (keep velocity).
        Vec3 dp = pose.position - b.lastPos;
        if (std::fabs(dp.x) > 1e-4f || std::fabs(dp.y) > 1e-4f || std::fabs(dp.z) > 1e-4f || b.type == BodyType::Static) {
            const bool placed = b.lastPos.x < 1e8f;  // false right after slot reuse (forced initial placement)
            if (placed && b.type != BodyType::Dynamic) b.pendingCarry += pose.position - b.lastPos;
            b.center = pose.position + b.offset;
            b.lastPos = pose.position;
            b.lastCenter = b.center;
        }
        if (rb && rb->angularVelocity != b.lastAngVel) {
            b.angVel = rb->angularVelocity;
            b.lastAngVel = rb->angularVelocity;
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

void Physics3D::solve_pair(Body& a, Body& b, const Contact& c, float, float& impact, bool carried) {
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
        // A carried rider already moved with the platform: friction acts on its velocity relative to it.
        if (carried) rv = b.vel;
        Vec3 vt = rv - n * dot(rv, n);
        float lt = length(vt);
        if (lt > 1e-6f) {
            // A rolling sphere (rollWithMotion) is held back by rolling resistance instead of sliding friction.
            float mu = (a.rollMu >= 0.0f || b.rollMu >= 0.0f) ? std::max(a.rollMu, b.rollMu)
                                                              : std::sqrt(a.friction * b.friction);
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
    std::vector<int> carrier(n, -1);  // per body: index of the kinematic body carrying it this sub-step

    // Dynamic bodies resting on top of body k (k at its current center, optionally shifted).
    auto find_riders = [&](std::size_t k, std::vector<std::size_t>& out) {
        const Body& p = bodies_[k];
        if (!p.enabled || !p.hasShape || p.trigger) return;
        for (std::size_t i = 0; i < n; ++i) {
            const Body& d = bodies_[i];
            if (i == k || d.type != BodyType::Dynamic || !d.enabled || !d.hasShape || d.trigger) continue;
            if (!filters_pass(p, d)) continue;
            Contact c = collide(p, d, kRiderGap);
            if (c.hit && c.normal.y > 0.7f) out.push_back(i);
        }
    };
    // Teleported static/kinematic bodies carry their riders by the same displacement (detected at the old pose).
    for (std::size_t k = 0; k < n; ++k) {
        Body& p = bodies_[k];
        if (p.pendingCarry == Vec3{}) continue;
        Vec3 dp = p.pendingCarry;
        p.pendingCarry = {};
        std::vector<std::size_t> riders;
        p.center -= dp;
        find_riders(k, riders);
        p.center += dp;
        for (std::size_t i : riders) bodies_[i].center += dp;
    }

    auto movable = [](const Body& b) { return b.type != BodyType::Static; };
    std::vector<std::size_t> riders;
    for (int s = 0; s < subs; ++s) {
        std::fill(carrier.begin(), carrier.end(), -1);
        for (std::size_t k = 0; k < n; ++k) {
            const Body& p = bodies_[k];
            if (p.type != BodyType::Kinematic || p.vel == Vec3{}) continue;
            riders.clear();
            find_riders(k, riders);
            Vec3 disp = p.vel * h;
            if (disp.y > 0.0f) disp.y = 0.0f;  // upward motion is delivered by the contact itself
            for (std::size_t i : riders) {
                if (carrier[i] >= 0) continue;
                carrier[i] = int(k);
                bodies_[i].center += disp;
            }
        }
        for (std::size_t i = 0; i < n; ++i) {
            Body& b = bodies_[i];
            if (!b.enabled) continue;
            if (b.type == BodyType::Dynamic) {
                b.vel += (g * b.gravityScale + b.force * b.invMass) * h;
                if (b.damping > 0.0f) b.vel *= 1.0f / (1.0f + h * b.damping);
                Vec3 disp = b.vel * h;
                // Continuous collision: a move longer than half the body's smallest extent is swept against the solid
                // static/kinematic colliders and cut at the first contact. The body ends up ~0.1 mm INSIDE that
                // surface, so the contact solver below resolves its velocity (stop / bounce) like any other contact.
                // ponytail: dynamic-vs-dynamic pairs and kinematic motion inside the sub-step are not swept.
                if (b.hasShape && !b.trigger) {
                    const float halfExtent = b.box ? std::min({b.half.x, b.half.y, b.half.z}) : b.radius;
                    if (length_sq(disp) > halfExtent * halfExtent) {
                        float tFirst = 1.0f;
                        for (std::size_t k = 0; k < n; ++k) {
                            const Body& t = bodies_[k];
                            const bool solid = t.enabled && t.hasShape && !t.trigger && t.type != BodyType::Dynamic;
                            if (k == i || !solid || !filters_pass(b, t)) continue;
                            float th = 1.0f;
                            if (sweep(b, disp, t, th) && th < tFirst) tFirst = th;
                        }
                        disp *= tFirst;
                    }
                }
                b.center += disp;
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
                    const bool carried = (carrier[k] == int(i) && a.type == BodyType::Kinematic) ||
                                         (carrier[i] == int(k) && b.type == BodyType::Kinematic);
                    if (carrier[i] == int(k) && b.type == BodyType::Kinematic) {
                        // keep the normal pointing from a to b: swap roles through the mirrored contact
                        Contact m = c;
                        m.normal = -m.normal;
                        solve_pair(b, a, m, h, impact, carried);
                    } else {
                        solve_pair(a, b, c, h, impact, carried);
                    }
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
    std::vector<char> supported(n, 0);  // dynamic body has solid ground (normal up) under it
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
            if (!trig) {
                if (b.type == BodyType::Dynamic && c.normal.y > 0.7f) supported[k] = 1;
                if (a.type == BodyType::Dynamic && c.normal.y < -0.7f) supported[i] = 1;
            }
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

    // ---- rolling: spheres on the ground spin to match their horizontal motion
    for (std::size_t i = 0; i < n; ++i) {
        Body& b = bodies_[i];
        if (!b.enabled || b.type != BodyType::Dynamic || b.box || !b.hasShape || b.trigger) continue;
        if (!b.rollWithMotion || !supported[i]) continue;
        // axis = up x v = (vz, 0, -vx); rate = |v| / r (rad/s) -> deg/s along that axis => components (vz, 0, -vx) / r
        const float k = degrees(1.0f) / b.radius;
        b.angVel = {b.vel.z * k, 0.0f, -b.vel.x * k};
    }

    // ---- write back
    for (Body& b : bodies_) {
        if (!b.enabled || b.type == BodyType::Static || !world.alive(b.e)) continue;
        if (b.angVel != Vec3{}) {
            if (Transform* t = world.get<Transform>(b.e)) t->rotation += b.angVel * dt;
        }
        if (RigidBody3D* rb = world.get<RigidBody3D>(b.e)) {
            rb->angularVelocity = b.angVel;
            b.lastAngVel = b.angVel;
        }
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
std::optional<RaycastHit> Physics3D::raycast(World& world, Vec3 origin, Vec3 dir, float maxDistance, const RaycastOptions& opt) {
    Vec3 d = normalize(dir);
    if (length_sq(d) < 0.5f) return std::nullopt;
    const std::uint64_t qmask = mask_bits(opt.mask);
    float bestT = maxDistance;
    const Body* best = nullptr;
    Vec3 bestN;
    for (const Body& b : bodies_) {
        if (!b.enabled || !b.hasShape || (b.trigger && opt.ignoreTriggers)) continue;
        if ((category_bits(b.layer) & qmask) == 0) continue;
        if (entity_or_ancestor_is(world, b.e, opt.ignore)) continue;
        // A turned box is tested in its own frame (same distances); an unturned one in world space, exactly as before.
        Vec3 lo = b.center - b.half, hi = b.center + b.half, org = origin, od = d;
        if (b.rotated) {
            lo = -b.half;
            hi = b.half;
            org = world_to_frame(b.ax, origin - b.center);
            od = world_to_frame(b.ax, d);
        }
        {   // origin inside this collider: skip it
            bool inside = b.box ? (org.x > lo.x && org.x < hi.x && org.y > lo.y && org.y < hi.y &&
                                   org.z > lo.z && org.z < hi.z)
                                : length_sq(origin - b.center) < b.radius * b.radius;
            if (inside) continue;
        }
        float t = 0.0f;
        Vec3 nrm;
        if (b.box) {
            float tmin = 0.0f, tmax = bestT;
            int axisHit = -1;
            float sgnHit = 0.0f;
            bool miss = false;
            for (int i = 0; i < 3 && !miss; ++i) {
                if (std::fabs(od[i]) < 1e-9f) {
                    if (org[i] < lo[i] || org[i] > hi[i]) miss = true;
                } else {
                    float t1 = (lo[i] - org[i]) / od[i], t2 = (hi[i] - org[i]) / od[i];
                    float sgn = -1.0f;  // entering through the low face -> normal points to -axis
                    if (t1 > t2) { std::swap(t1, t2); sgn = 1.0f; }
                    if (t1 > tmin) { tmin = t1; axisHit = i; sgnHit = sgn; }
                    tmax = std::min(tmax, t2);
                    if (tmin > tmax) miss = true;
                }
            }
            if (miss) continue;
            t = tmin;
            if (axisHit >= 0) {
                nrm = {};
                nrm[axisHit] = sgnHit;
                if (b.rotated) nrm = frame_to_world(b.ax, nrm);
            } else {
                nrm = -d;  // origin inside the box
            }
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

std::optional<RaycastHit> Physics3D::shape_cast(World& world, const CastShape& shape, Vec3 from, Vec3 to,
                                                const RaycastOptions& opt) {
    const Vec3 disp = to - from;
    const float len = length(disp);
    if (!(len > 0.0f) || !std::isfinite(len)) return std::nullopt;
    Body probe;  // the swept shape as a body: axis-aligned, no entity
    probe.hasShape = true;
    probe.enabled = true;
    probe.box = shape.kind == CastShape::Kind::Box;
    probe.half = {std::max(shape.size.x * 0.5f, 1e-3f), std::max(shape.size.y * 0.5f, 1e-3f),
                  std::max(shape.size.z * 0.5f, 1e-3f)};
    probe.radius = std::max(shape.radius, 1e-3f);
    probe.center = from;
    const std::uint64_t qmask = mask_bits(opt.mask);
    float bestT = 2.0f;
    const Body* best = nullptr;
    for (const Body& b : bodies_) {
        if (!b.enabled || !b.hasShape || (b.trigger && opt.ignoreTriggers) || !world.alive(b.e)) continue;
        if ((category_bits(b.layer) & qmask) == 0) continue;
        if (entity_or_ancestor_is(world, b.e, opt.ignore)) continue;
        // At `from`, like the 2D cast: a collider penetrated deeper than the skin is skipped; one only touched (a body
        // resting on it penetrates ~1 mm) blocks the cast at distance 0, but only when the shape moves towards it.
        const Contact c0 = collide(b, probe, 0.0f);  // normal: collider -> shape
        if (c0.hit) {
            if (c0.depth <= kCastSkin && dot(disp, c0.normal) < -1e-4f * len && bestT > 0.0f) {
                bestT = 0.0f;
                best = &b;
            }
            continue;
        }
        float t = 0.0f;
        if (sweep(probe, disp, b, t) && t < bestT) {
            bestT = t;
            best = &b;
        }
    }
    if (!best) return std::nullopt;
    probe.center = from + disp * bestT;
    const Contact c = collide(*best, probe, 0.0f);  // normal: collider -> shape, i.e. pointing back at the shape
    RaycastHit h;
    h.entity = best->e;
    h.point = c.point;
    h.normal = c.normal;
    h.distance = bestT * len;
    return h;
}

bool Physics3D::is_touching(World& world, Entity e, Vec3 dir, float tolerance) {
    auto it = index_.find(e.bits());
    if (it == index_.end()) return false;
    const Body& a = bodies_[it->second];
    if (!a.enabled || !a.hasShape || a.trigger || length_sq(dir) < 1e-12f) return false;
    dir = normalize(dir);
    for (const Body& b : bodies_) {
        if (&b == &a || !b.enabled || !b.hasShape || b.trigger || !world.alive(b.e)) continue;
        if (!filters_pass(a, b)) continue;
        Contact c = collide(a, b, std::max(tolerance, 0.0f));
        if (c.hit && dot(c.normal, dir) > 0.7f) return true;
    }
    return false;
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
                const Vec3 rot = b.rotated ? euler_of(b.ax) : Vec3{};  // world rotation, euler degrees (like Transform)
                s["rotation"] = Json::array({rot.x, rot.y, rot.z});
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
        if (b.box) {
            const Vec3 rot = b.rotated ? euler_of(b.ax) : Vec3{};
            out.push_back({Physics::DebugShape::Box, b.center, b.half * 2.0f, rot.z, b.trigger, rot});
        } else {
            out.push_back({Physics::DebugShape::Sphere, b.center, Vec3{b.radius * 2.0f}, 0.0f, b.trigger});
        }
    }
}

}  // namespace fa::detail
