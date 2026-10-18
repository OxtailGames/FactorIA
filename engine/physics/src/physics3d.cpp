// Simple 3D physics: spheres + oriented boxes, semi-implicit Euler, impulse resolution, automatic continuous collision.
// Boxes follow the entity's world rotation. A dynamic box (or a sphere with rollWithMotion off) without lockRotation is
// a rigid body: its contacts are manifolds (clipped faces), the solver applies normal and friction impulses at the
// contact points and so turns it (inertia tensor from its size and mass, orientation kept as a quaternion). Everything
// else (arcade rolling spheres, locked bodies, kinematic and static bodies) keeps the original torque-free single-point
// solver. An unrotated box keeps the exact axis-aligned code paths. Calm dynamic bodies fall asleep in islands, a box
// turning in the air precesses (gyroscopic_step), and the sub-step motion is swept for impacts, rotation included.
// Capsules, convex hulls and triangle meshes (physics3d_shapes.cpp) share all of this through collide(); joints are in
// physics3d_joints.cpp and the character controller in physics3d_character.cpp.
#include <algorithm>
#include <cmath>
#include <format>
#include <unordered_set>

#include "fa/core/log.h"
#include "fa/scene/mesh_geometry.h"

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
constexpr float kManifoldGap = 0.003f;  // box-box manifold points this far above the reference face still count (m)
constexpr int kRigidIterations = 8;     // velocity iterations of the rigid-body solver, per sub-step
constexpr int kMaxToiEvents = 32;       // time-of-impact stops (and rest-of-the-sub-step continuations) per sub-step
constexpr float kTouchSkin = 0.002f;    // a swept pair this deep at the start of the move is touching, not overlapping (m)
constexpr float kTouchGain = 0.0005f;   // ...and counts as hit again once it sinks this much deeper (m)
constexpr float kWarmRadius = 0.05f;    // a contact point inherits the impulses of the previous sub-step's one this close (m)
constexpr float kSleepSpeed = 0.05f;    // a body is calm below this speed (m/s; its fastest point counts, spin included)
constexpr float kTimeToSleep = 0.5f;    // ...and falls asleep, with the bodies it touches, after this long (s)

const char* type_name(BodyType t) {
    switch (t) {
        case BodyType::Static: return "static";
        case BodyType::Kinematic: return "kinematic";
        default: return "dynamic";
    }
}

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

// True when the unit basis is not the identity (beyond float noise): the box then takes the oriented code paths.
bool is_turned(const Vec3* r) {
    return std::fabs(r[0].y) > kAlignedEps || std::fabs(r[0].z) > kAlignedEps || std::fabs(r[1].x) > kAlignedEps ||
           std::fabs(r[1].z) > kAlignedEps || std::fabs(r[2].x) > kAlignedEps || std::fabs(r[2].y) > kAlignedEps;
}

// Unit quaternion <-> basis columns (the columns of Mat4::from_quat).
void axes_of(Quat q, Vec3* ax) {
    const float xx = q.x * q.x, yy = q.y * q.y, zz = q.z * q.z, xy = q.x * q.y, xz = q.x * q.z, yz = q.y * q.z;
    const float wx = q.w * q.x, wy = q.w * q.y, wz = q.w * q.z;
    ax[0] = {1 - 2 * (yy + zz), 2 * (xy + wz), 2 * (xz - wy)};
    ax[1] = {2 * (xy - wz), 1 - 2 * (xx + zz), 2 * (yz + wx)};
    ax[2] = {2 * (xz + wy), 2 * (yz - wx), 1 - 2 * (xx + yy)};
}
Quat quat_of(const Vec3* ax) {
    const float m00 = ax[0].x, m11 = ax[1].y, m22 = ax[2].z, tr = m00 + m11 + m22;
    Quat q;
    if (tr > 0.0f) {
        const float s = std::sqrt(tr + 1.0f) * 2.0f;
        q = {(ax[1].z - ax[2].y) / s, (ax[2].x - ax[0].z) / s, (ax[0].y - ax[1].x) / s, 0.25f * s};
    } else if (m00 >= m11 && m00 >= m22) {
        const float s = std::sqrt(1.0f + m00 - m11 - m22) * 2.0f;
        q = {0.25f * s, (ax[1].x + ax[0].y) / s, (ax[2].x + ax[0].z) / s, (ax[1].z - ax[2].y) / s};
    } else if (m11 >= m22) {
        const float s = std::sqrt(1.0f + m11 - m00 - m22) * 2.0f;
        q = {(ax[1].x + ax[0].y) / s, 0.25f * s, (ax[2].y + ax[1].z) / s, (ax[2].x - ax[0].z) / s};
    } else {
        const float s = std::sqrt(1.0f + m22 - m00 - m11) * 2.0f;
        q = {(ax[2].x + ax[0].z) / s, (ax[2].y + ax[1].z) / s, 0.25f * s, (ax[0].y - ax[1].x) / s};
    }
    return normalize(q);
}

// Transform.rotation (local euler degrees) that gives the entity the world basis `ax`.
Vec3 local_euler(const World& world, Entity e, const Vec3* ax) {
    const Entity parent = world.parent(e);
    if (parent.is_null()) return euler_of(ax);
    const WorldPose pp = world_pose(world, parent);
    Vec3 lc[3];
    for (int i = 0; i < 3; ++i) lc[i] = {dot(pp.axis[0], ax[i]), dot(pp.axis[1], ax[i]), dot(pp.axis[2], ax[i])};
    return euler_of(lc);
}

// Gyroscopic torque of a body turning about a non-principal axis (Euler's equations I w' = -w x I w, body frame),
// integrated with the implicit midpoint rule: I (w1 - w0) + h wm x (I wm) = 0 with wm = (w0 + w1) / 2, solved by Newton
// iterations (the idea of Bullet's computeGyroscopicImpulseImplicit, with the second-order midpoint rule). It keeps the
// two quadratic invariants of the free rotation, kinetic energy and |I w|, so a fast spin about the intermediate axis
// neither blows up nor loses speed. w0 and the result are the body-frame angular velocity (rad/s), `inertia` the
// principal moments.
Vec3 gyroscopic_step(Vec3 w0, Vec3 inertia, float h) {
    Vec3 w1 = w0;
    for (int it = 0; it < 4; ++it) {
        const Vec3 wm = (w0 + w1) * 0.5f, L = wm * inertia;
        const Vec3 res = (w1 - w0) * inertia + cross(wm, L) * h;  // residual of the midpoint equation
        // Jacobian rows: I + h/2 (skew(wm) I - skew(L))
        const float k = 0.5f * h;
        const Vec3 r0{inertia.x, k * (L.z - wm.z * inertia.y), k * (wm.y * inertia.z - L.y)};
        const Vec3 r1{k * (wm.z * inertia.x - L.z), inertia.y, k * (L.x - wm.x * inertia.z)};
        const Vec3 r2{k * (L.y - wm.y * inertia.x), k * (wm.x * inertia.y - L.x), inertia.z};
        const Vec3 c0 = cross(r1, r2), c1 = cross(r2, r0), c2 = cross(r0, r1);  // columns of J^-1 times det
        const float det = dot(r0, c0);
        if (!(std::fabs(det) > 1e-6f * inertia.x * inertia.y * inertia.z)) break;
        const Vec3 dw = (c0 * res.x + c1 * res.y + c2 * res.z) / det;
        w1 -= dw;
        if (length_sq(dw) < 1e-12f * (length_sq(w1) + 1e-12f)) break;
    }
    return w1;
}

// `q` turned by angular velocity `w` (rad/s, world axes) for `seconds`.
Quat turned(Quat q, Vec3 w, float seconds) {
    const float len = length(w);
    if (!(len > 0.0f)) return q;
    const float half = 0.5f * len * seconds, s = std::sin(half) / len;
    return normalize(Quat{w.x * s, w.y * s, w.z * s, std::cos(half)} * q);
}

}  // namespace

void Physics3D::reset() {
    bodies_.clear();
    index_.clear();
    touching_.clear();
    warm_.clear();
    lastWorld_ = nullptr;
    nextSeq_ = 1;
    carry_ = 0.0f;
    lastGravity_ = {1e30f, 1e30f, 1e30f};
}

void Physics3D::wake(Body& b) {
    b.sleepTime = 0.0f;
    if (!b.asleep) return;
    const std::uint64_t group = b.sleepGroup;
    for (Body& o : bodies_) {
        if (o.asleep && o.sleepGroup == group) {
            o.asleep = false;
            o.sleepTime = 0.0f;
        }
    }
}

void Physics3D::wake_touching(std::uint64_t seq) {
    for (const auto& [key, st] : touching_) {
        if (key.first != seq && key.second != seq) continue;
        const std::uint64_t other = key.first == seq ? key.second : key.first;
        auto it = std::lower_bound(bodies_.begin(), bodies_.end(), other, [](const Body& b, std::uint64_t s) { return b.seq < s; });
        if (it != bodies_.end() && it->seq == other) wake(*it);
    }
}

bool Physics3D::filters_pass(const Body& a, const Body& b) {
    if (!a.noCollide.empty() && std::find(a.noCollide.begin(), a.noCollide.end(), b.seq) != a.noCollide.end()) return false;
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
void Physics3D::box_box_sat(const Body& a, const Body& b, float margin, Contact& c, bool manifold) {
    const Vec3 d = b.center - a.center;
    float faceOv = 1e30f, edgeOv = 1e30f;
    Vec3 faceN, edgeN;
    int faceOwner = 0, faceAxis = 0;  // which body (0 = a, 1 = b) and axis index gave the least-penetration face axis
    auto test = [&](Vec3 axis, bool edge, int owner, int index) {  // false = separated by more than the margin
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
            if (!edge) { faceOwner = owner; faceAxis = index; }
        }
        return true;
    };
    for (int i = 0; i < 3; ++i) if (!test(a.ax[i], false, 0, i) || !test(b.ax[i], false, 1, i)) return;
    for (int i = 0; i < 3; ++i) {
        for (int j = 0; j < 3; ++j) {
            Vec3 x = cross(a.ax[i], b.ax[j]);
            const float len = length(x);
            if (len < 1e-4f) continue;  // parallel edges: the face axes cover them
            if (!test(x / len, true, 0, 0)) return;
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
    if (manifold && !useEdge) {  // face contact: the incident face clipped to the reference face (edge contacts: one point)
        if (faceOwner == 0) face_manifold(a, faceAxis, c.normal, b, c);
        else face_manifold(b, faceAxis, -c.normal, a, c);
        if (c.n > 0) {
            c.point = {};
            for (int i = 0; i < c.n; ++i) c.point += c.pts[i];
            c.point = c.point / float(c.n);
        }
    }
}

// Contact manifold of a face-to-face box contact: the face of `inc` that points most against `refNormal` (the outward
// normal of face `refAxis` of `ref`) is clipped to the side planes of that reference face, and the corners of the result
// that are not more than kManifoldGap above the reference plane become the contact points (depth < 0 = still apart).
void Physics3D::face_manifold(const Body& ref, int refAxis, Vec3 refNormal, const Body& inc, Contact& c) {
    int k = 0;
    float bestDot = 0.0f;
    for (int i = 0; i < 3; ++i) {
        const float d = std::fabs(dot(inc.ax[i], refNormal));
        if (d > bestDot) { bestDot = d; k = i; }
    }
    const float side = dot(inc.ax[k], refNormal) > 0.0f ? -1.0f : 1.0f;  // outward direction of the incident face
    const Vec3 fc = inc.center + inc.ax[k] * (side * inc.half[k]);
    const Vec3 up = inc.ax[(k + 1) % 3] * inc.half[(k + 1) % 3], uq = inc.ax[(k + 2) % 3] * inc.half[(k + 2) % 3];
    Vec3 poly[16] = {fc + up + uq, fc - up + uq, fc - up - uq, fc + up - uq}, tmp[16];
    int cnt = 4;
    for (int s = 0; s < 4 && cnt > 0; ++s) {  // Sutherland-Hodgman against the reference face's four side planes
        const int u = (refAxis + 1 + (s >> 1)) % 3;
        const Vec3 m = (s & 1) ? -ref.ax[u] : ref.ax[u];
        const float h = ref.half[u];
        int out = 0;
        for (int i = 0; i < cnt; ++i) {
            const Vec3 cur = poly[i], nxt = poly[(i + 1) % cnt];
            const float dc = dot(cur - ref.center, m) - h, dn = dot(nxt - ref.center, m) - h;
            if (dc <= 0.0f) tmp[out++] = cur;
            if ((dc <= 0.0f) != (dn <= 0.0f)) tmp[out++] = cur + (nxt - cur) * (dc / (dc - dn));
        }
        for (int i = 0; i < out; ++i) poly[i] = tmp[i];
        cnt = out;
    }
    const Vec3 faceCenter = ref.center + refNormal * ref.half[refAxis];
    c.n = 0;
    for (int i = 0; i < cnt && c.n < kMaxPts; ++i) {
        const float sep = dot(poly[i] - faceCenter, refNormal);
        if (sep > kManifoldGap) continue;
        c.pts[c.n] = poly[i] - refNormal * (sep * 0.5f);  // half way between the corner and the reference plane
        c.depths[c.n] = -sep;
        ++c.n;
    }
}

// Contact between a and b; normal points from a to b. depth > 0 means penetrating; hit when depth > -margin.
// manifold: box-box contacts also fill the contact points of the touching face (see face_manifold).
Physics3D::Contact Physics3D::collide(const Body& a, const Body& b, float margin, bool manifold) {
    Contact c;
    if (!a.hasShape || !b.hasShape) return c;
    if (a.general() || b.general()) return collide_general(a, b, margin, manifold);
    if (a.kind != Body::Kind::Box && b.kind != Body::Kind::Box) {
        Vec3 d = b.center - a.center;
        float dist = length(d);
        c.depth = a.radius + b.radius - dist;
        c.normal = dist > 1e-6f ? d / dist : Vec3{0, 1, 0};
        c.point = a.center + c.normal * a.radius;
        c.hit = c.depth > -margin;
    } else if (a.kind == Body::Kind::Box && b.kind == Body::Kind::Box) {
        if (a.rotated || b.rotated) {
            box_box_sat(a, b, margin, c, manifold);
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
        if (manifold) {  // the four corners of the overlap rectangle, on the plane half way through the overlap
            const int i = (axis + 1) % 3, j = (axis + 2) % 3;
            for (int si = 0; si < 2; ++si) {
                for (int sj = 0; sj < 2; ++sj) {
                    Vec3 p;
                    p[axis] = (lo[axis] + hi[axis]) * 0.5f;
                    p[i] = si ? hi[i] : lo[i];
                    p[j] = sj ? hi[j] : lo[j];
                    c.pts[c.n] = p;
                    c.depths[c.n++] = best;
                }
            }
        }
    } else if (a.kind == Body::Kind::Box) {
        sphere_box(a, b, margin, c);
    } else {
        sphere_box(b, a, margin, c);
        c.normal = -c.normal;
    }
    return c;
}

// First fraction t in (0, 1] of `disp` at which `mover` (centre moved by t * disp, turned by t * moverSpin) overlaps
// `target` (turned in place by t * targetSpin), found by stepping at most half the mover's smallest extent and bisecting
// the first overlapping step to kSweepTol (tHit overlaps, by <= ~0.1 mm). The spins are the rotations (rad, about world
// axes) a box makes over the whole move; the far end of a turning box counts as travel, so a long thin box spinning
// fast cannot swing through a wall between two steps. False when it never overlaps, or when it already overlaps at
// t = 0 by more than kTouchSkin (that contact is left to the caller). Both bodies are restored before returning.
bool Physics3D::sweep(Body& mover, Vec3 disp, Vec3 moverSpin, Body& target, Vec3 targetSpin, float& tHit) {
    const float len = length(disp);
    const float travel = len + turning_reach(mover, moverSpin) + turning_reach(target, targetSpin);
    if (!(travel > 0.0f) || !std::isfinite(travel)) return false;
    Vec3 mlo, mhi, tlo, thi;
    aabb(mover, mlo, mhi);
    aabb(target, tlo, thi);
    if (moverSpin != Vec3{}) { mlo = mover.center - Vec3{bound_radius(mover)}; mhi = mover.center + Vec3{bound_radius(mover)}; }
    if (targetSpin != Vec3{}) { tlo = target.center - Vec3{bound_radius(target)}; thi = target.center + Vec3{bound_radius(target)}; }
    const Vec3 slo = min(mlo, mlo + disp), shi = max(mhi, mhi + disp);  // broad phase: swept bounds vs target bounds
    if (slo.x > thi.x || shi.x < tlo.x || slo.y > thi.y || shi.y < tlo.y || slo.z > thi.z || shi.z < tlo.z)
        return false;
    const float extent = 2.0f * min_half_extent(mover);
    const float steps = std::min(std::ceil(travel / (0.5f * extent)), 100000.0f);
    const int n = std::max(int(steps), 1);
    const Vec3 from = mover.center;
    const Vec3 moverAx[3] = {mover.ax[0], mover.ax[1], mover.ax[2]}, targetAx[3] = {target.ax[0], target.ax[1], target.ax[2]};
    const bool moverRotated = mover.rotated, targetRotated = target.rotated;
    auto turn = [](Body& b, Vec3 spin, float t) {  // the collision frame of b after t of its spin
        if (spin == Vec3{}) return;
        axes_of(turned(b.orient, spin, t), b.ax);
        b.rotated = true;
    };
    // A pair that touches at the start (the previous impact left it ~0.1 mm in) is swept too: it only counts as hit once it
    // sinks kTouchGain deeper, so the rest of a sub-step after an impact still catches the next one (a box pivoting
    // about the corner that hit swings its far end into the wall). Deeper than kTouchSkin = a real overlap: the solver's.
    float limit = -1e30f;  // penetration depth beyond which the mover counts as overlapping
    auto overlaps = [&](float t) {
        mover.center = from + disp * t;
        turn(mover, moverSpin, t);
        turn(target, targetSpin, t);
        const Contact c = collide(target, mover, 0.0f);
        return c.hit && c.depth > limit;
    };
    bool found = false;
    bool overlapping = false;
    {
        const Contact c0 = collide(target, mover, 0.0f);
        if (c0.hit && c0.depth > kTouchSkin) overlapping = true;
        else if (c0.hit) limit = c0.depth + kTouchGain;
    }
    if (!overlapping) {
        float lo = 0.0f;
        for (int i = 1; i <= n && !found; ++i) {
            const float t = float(i) / float(n);
            if (!overlaps(t)) { lo = t; continue; }
            float hi = t;
            for (int k = 0; k < 32 && (hi - lo) * travel > kSweepTol; ++k) {
                const float mid = 0.5f * (lo + hi);
                if (overlaps(mid)) hi = mid;
                else lo = mid;
            }
            tHit = hi;
            found = true;
        }
    }
    mover.center = from;
    for (int i = 0; i < 3; ++i) { mover.ax[i] = moverAx[i]; target.ax[i] = targetAx[i]; }
    mover.rotated = moverRotated;
    target.rotated = targetRotated;
    return found;
}

void Physics3D::sync(World& world) {
    const std::uint64_t stamp = stepCounter_;
    std::unordered_set<std::uint64_t> joinTargets;  // bodies another entity's Joint3D is attached to: they turn too
    for (Entity e : world.entities())
        if (const Joint3D* j = world.get<Joint3D>(e); j && !j->connected.is_null()) joinTargets.insert(j->connected.bits());
    for (Entity e : world.entities()) {
        RigidBody3D* rb = world.get<RigidBody3D>(e);
        Collider3D* col = world.get<Collider3D>(e);
        CharacterController3D* cc = world.get<CharacterController3D>(e);
        Joint3D* jt = world.get<Joint3D>(e);
        if ((!rb && !col && !cc) || world.pending_destroy(e)) continue;  // pending destroy: never seen -> swept below
        const std::uint64_t key = e.bits();
        WorldPose pose = world_pose(world, e);
        auto it = index_.find(key);
        bool existed = it != index_.end();
        if (it != index_.end() && bodies_[it->second].id != world.id_of(e)) {
            wake_touching(bodies_[it->second].seq);
            existed = false;
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
        const Body::Sig before = b.sig();
        b.seen = stamp;
        b.localScale = pose.scale;
        b.type = cc ? BodyType::Kinematic : (rb ? rb->type : BodyType::Static);
        b.hasRigid = rb != nullptr;
        b.mass = rb ? std::max(rb->mass, 1e-4f) : 1.0f;
        b.invMass = b.type == BodyType::Dynamic ? 1.0f / b.mass : 0.0f;
        b.gravityScale = rb ? rb->gravityScale : 1.0f;
        b.damping = rb ? std::max(rb->linearDamping, 0.0f) : 0.0f;
        b.rollWithMotion = rb ? rb->rollWithMotion : false;
        b.angDamping = rb ? std::max(rb->angularDamping, 0.0f) : 0.0f;
        // A collider that cannot be used (a Mesh on a moving body, a missing mesh) is reported once and ignored.
        std::string problem;
        std::shared_ptr<const ShapeData> shapeData;
        if (col && !cc) {
            const bool isStatic = !rb || rb->type == BodyType::Static;
            if (col->shape == ColliderShape3D::Mesh && !isStatic)
                problem = std::format(
                    "entity '{}' has a Collider3D with shape \"mesh\" on a {} RigidBody3D. Triangle meshes are only for "
                    "static level geometry (a moving body has no inside to push out of). Use shape \"convex\" for a "
                    "moving body, or build it from several boxes/capsules, or set the RigidBody3D type to static.",
                    world.id_of(e), rb->type == BodyType::Dynamic ? "dynamic" : "kinematic");
            else if (col->shape == ColliderShape3D::Convex || col->shape == ColliderShape3D::Mesh) {
                std::string why;
                shapeData = shape_data(col->mesh, col->shape == ColliderShape3D::Mesh, why);
                if (!shapeData) problem = std::format("entity '{}': Collider3D shape \"{}\": {}", world.id_of(e),
                                                      col->shape == ColliderShape3D::Mesh ? "mesh" : "convex", why);
            }
        }
        if (problem != b.problem) {
            b.problem = problem;
            if (!problem.empty()) FA_ERROR("physics", "{}", problem);
        }
        const bool usable = col && !cc && problem.empty();
        b.hasShape = usable || cc;
        b.character = cc != nullptr;
        b.jointed = (jt != nullptr && rb != nullptr && !cc) || (rb && joinTargets.count(e.bits()) != 0);
        b.noCollide.clear();
        const Vec3 oldOffset = b.offset;
        if (usable || cc) {
            Vec3 as{std::fabs(pose.scale.x), std::fabs(pose.scale.y), std::fabs(pose.scale.z)};
            const float flat = std::max(as.x, as.z);
            Body::Kind kind = Body::Kind::Box;
            if (cc) kind = Body::Kind::Capsule;
            else switch (col->shape) {
                case ColliderShape3D::Sphere: kind = Body::Kind::Sphere; break;
                case ColliderShape3D::Capsule: kind = Body::Kind::Capsule; break;
                case ColliderShape3D::Convex: kind = Body::Kind::Convex; break;
                case ColliderShape3D::Mesh: kind = Body::Kind::Mesh; break;
                default: break;
            }
            b.kind = kind;
            b.data = shapeData;
            b.meshName = (!cc && b.data) ? col->mesh : std::string();
            b.gscale = {1, 1, 1};
            b.segHalf = 0.0f;
            b.lcenter = {};
            if (kind == Body::Kind::Capsule) {  // a collider capsule and a character's capsule are the same shape
                b.radius = std::max((cc ? cc->radius : col->radius) * flat, 1e-3f);
                b.segHalf = std::max((cc ? cc->height : col->height) * as.y * 0.5f - b.radius, 0.0f);
                b.half = {b.radius, b.segHalf + b.radius, b.radius};
                if (cc) {
                    b.stepOffset = std::max(cc->stepOffset * as.y, 0.0f);
                    b.slopeLimit = clamp(cc->slopeLimit, 0.0f, 89.0f);
                    b.skin = std::max(cc->skin, 1e-3f);
                }
            } else if (b.data) {
                const MeshGeometry& g = *b.data->geometry;
                b.gscale = {std::max(as.x, 1e-3f), std::max(as.y, 1e-3f), std::max(as.z, 1e-3f)};
                b.half = max((g.bmax - g.bmin) * 0.5f * b.gscale, Vec3{1e-3f});
                b.lcenter = (g.bmax + g.bmin) * 0.5f * b.gscale;
                b.radius = 0.0f;
            } else {
                b.half = {std::max(col->size.x * as.x * 0.5f, 1e-3f), std::max(col->size.y * as.y * 0.5f, 1e-3f),
                          std::max(col->size.z * as.z * 0.5f, 1e-3f)};
                b.radius = std::max(col->radius * std::max({as.x, as.y, as.z}), 1e-3f);
            }
            // Orientation = the entity's world rotation (columns normalised, so scale only sizes the box). An unturned
            // entity keeps the identity frame and the exact axis-aligned paths. ponytail: a sheared world matrix (a
            // non-uniformly scaled, rotated parent) has non-orthogonal columns, which are used as if orthonormal.
            const Vec3* r = pose.axis;
            Vec3 ownAx[3];
            // Boxes, capsules, hulls and spheres without rollWithMotion (the arcade rolling model) are rigid bodies turned
            // by contacts; a jointed body must turn too (the joint holds it by a point away from its centre).
            const bool trig = cc ? false : col->isTrigger;
            const bool lockRot = rb && rb->lockRotation;
            const bool wantRot = rb && !cc && rb->type == BodyType::Dynamic && !trig &&
                                 (b.jointed || (!lockRot && (kind != Body::Kind::Sphere || !rb->rollWithMotion)));
            if (wantRot) {
                // A rotating box keeps its quaternion between steps; only a Transform.rotation that differs from what
                // the solver wrote last (or a parent in the way) makes it re-read the orientation from the Transform.
                const Transform* tr = world.get<Transform>(e);
                const bool keep = b.rotDyn && tr && tr->rotation == b.lastEuler &&
                                  world.parent(e).is_null();
                if (!keep) {
                    b.orient = quat_of(pose.axis);
                    b.lastEuler = tr ? tr->rotation : Vec3{};
                }
                axes_of(b.orient, ownAx);
                r = ownAx;
                const float m = b.mass, hx2 = b.half.x * b.half.x, hy2 = b.half.y * b.half.y, hz2 = b.half.z * b.half.z;
                if (kind != Body::Kind::Sphere) b.invI = {3.0f / (m * (hy2 + hz2)), 3.0f / (m * (hx2 + hz2)), 3.0f / (m * (hx2 + hy2))};
                else b.invI = Vec3{2.5f / (m * b.radius * b.radius)};  // solid sphere: I = 2/5 m r^2
            }
            b.rotDyn = wantRot;
            const bool turned = is_turned(r);
            const Vec3 off = cc ? cc->center : col->offset;
            b.localOffset = off * pose.scale;
            b.offset = turned ? frame_to_world(r, b.localOffset) : b.localOffset;
            b.rotated = kind != Body::Kind::Sphere && turned;
            for (int i = 0; i < 3; ++i) {
                b.ax[i] = b.rotated ? r[i] : kIdentityAxes[i];
                b.rot[i] = r[i];
            }
            b.trigger = trig;
            b.friction = cc ? 0.0f : std::max(col->friction, 0.0f);
            b.restitution = cc ? 0.0f : std::max(col->restitution, 0.0f);
            b.layer = cc ? cc->layer : col->layer;
            b.mask = cc ? cc->mask : col->mask;
        } else {
            b.offset = {};
            b.localOffset = {};
            b.rotated = false;
            b.rotDyn = false;
            b.trigger = false;
            b.data = nullptr;
            for (int i = 0; i < 3; ++i) b.rot[i] = pose.axis[i];
        }
        b.rollMu = (rb && usable && rb->type == BodyType::Dynamic && rb->rollWithMotion && b.kind == Body::Kind::Sphere)
                       ? std::max(rb->rollingFriction, 0.0f) : -1.0f;
        if (b.offset != oldOffset) {  // offset edited, or turned/scaled with the entity: the shape follows the origin
            b.center += b.offset - oldOffset;
            b.lastCenter += b.offset - oldOffset;
        }
        b.enabled = world.active_in_hierarchy(e);
        // Sleeping bodies must follow everything gameplay does to them or to what they rest on: a changed body or collider
        // (including enabling and disabling) and a teleport wake the body and the bodies touching it; a written velocity
        // wakes the body's group.
        if (existed && b.sig() != before) {
            wake(b);
            wake_touching(b.seq);
        }
        if (!b.enabled) continue;
        // Gameplay moved the Transform since the last writeback -> teleport (keep velocity).
        Vec3 dp = pose.position - b.lastPos;
        const bool moved = std::fabs(dp.x) > 1e-4f || std::fabs(dp.y) > 1e-4f || std::fabs(dp.z) > 1e-4f;
        if (moved || b.type == BodyType::Static) {
            const bool placed = b.lastPos.x < 1e8f;  // false right after slot reuse (forced initial placement)
            if (placed && b.type != BodyType::Dynamic) b.pendingCarry += pose.position - b.lastPos;
            b.center = pose.position + b.offset;
            b.lastPos = pose.position;
            b.lastCenter = b.center;
        }
        if (moved) {
            b.moved = true;
            wake(b);
            wake_touching(b.seq);
        }
        if (rb && rb->angularVelocity != b.lastAngVel) {
            b.angVel = rb->angularVelocity;
            b.lastAngVel = rb->angularVelocity;
            wake(b);
        }
        if (rb && rb->velocity != b.lastVel) {
            b.vel = rb->velocity;
            b.lastVel = rb->velocity;
            wake(b);
        }
    }
    // Sweep destroyed entities / removed components, keeping creation order. What rested on them is woken first.
    bool any = false;
    for (const Body& b : bodies_) if (b.seen != stamp || !live(world, b.e)) { any = true; wake_touching(b.seq); }
    if (any) {
        std::vector<Body> kept;
        kept.reserve(bodies_.size());
        for (Body& b : bodies_) if (b.seen == stamp && live(world, b.e)) kept.push_back(std::move(b));
        bodies_ = std::move(kept);
        index_.clear();
        for (std::size_t i = 0; i < bodies_.size(); ++i) index_[bodies_[i].e.bits()] = i;
    }
    sync_joints(world, stamp);
}

// Rebuilds the collision frame (basis, offset) of a rotating box from its quaternion.
void Physics3D::refresh_frame(Body& b) {
    Vec3 r[3];
    axes_of(b.orient, r);
    const bool turned = is_turned(r);
    const Vec3 oldOffset = b.offset;
    b.rotated = b.kind != Body::Kind::Sphere && turned;
    for (int i = 0; i < 3; ++i) {
        b.ax[i] = b.rotated ? r[i] : kIdentityAxes[i];
        b.rot[i] = r[i];
    }
    b.offset = turned ? frame_to_world(r, b.localOffset) : b.localOffset;
    if (b.offset != oldOffset) b.originDirty = true;  // the entity origin hangs off the (offset) collider centre
}

// Turns a rotating box by its angular velocity for `seconds` (about its centre, world axes).
void Physics3D::integrate_orient(Body& b, float seconds) {
    if (!(length_sq(b.angVel) > 0.0f)) return;
    b.orient = turned(b.orient, b.angVel * kDegToRad, seconds);
    b.rotDirty = true;
    refresh_frame(b);
}

// Velocity of the point at lever arm r from the centre. Only bodies that contacts can turn contribute their spin: the
// spin of a rolling sphere (rollWithMotion), a kinematic bar or a locked box is not part of the contact velocity, as in
// the single-point solver (a rolling sphere would otherwise be at rest at its contact point and feel no friction).
Vec3 Physics3D::point_velocity(const Body& b, Vec3 r) {
    return b.rotDyn ? b.vel + cross(b.angVel * kDegToRad, r) : b.vel;
}

// World inverse inertia times v: R * diag(invI) * R^T * v. Zero for bodies contacts cannot turn.
Vec3 Physics3D::inv_inertia_mul(const Body& b, Vec3 v) {
    if (!b.rotDyn) return {};
    return frame_to_world(b.ax, world_to_frame(b.ax, v) * b.invI);
}

// Original torque-free solver for one pair: one contact point, no angular terms (spheres, locked boxes, kinematic).
void Physics3D::solve_pair(Body& a, Body& b, const Contact& c, float, float& impact, bool carried, bool positional) {
    const float ia = a.invMass, ib = b.invMass, sum = ia + ib;
    if (sum <= 0.0f) return;
    const Vec3 n = c.normal;
    if (positional && c.depth > kSlop) {
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

// Prepares the rigid-body solver's view of a manifold: lever arms, effective normal mass and the velocity each point's
// normal constraint aims for (a bounce, or the closing speed that just reaches a point still slightly apart).
bool Physics3D::build_rigid_contact(const Body& a, const Body& b, std::size_t ia, std::size_t ib, const Contact& c,
                                    float h, int carrier, float& impact, RigidContact& rc) {
    if (a.invMass + b.invMass <= 0.0f) return false;
    rc.ia = ia;
    rc.ib = ib;
    rc.n = c.normal;
    rc.ca = a.center;
    rc.cb = b.center;
    rc.carrier = carrier;
    rc.mu = (a.rollMu >= 0.0f || b.rollMu >= 0.0f) ? std::max(a.rollMu, b.rollMu) : std::sqrt(a.friction * b.friction);
    rc.count = c.n > 0 ? c.n : 1;  // single-point contacts (spheres, box edges) use Contact::point
    const float e = std::max(a.restitution, b.restitution);
    for (int i = 0; i < rc.count; ++i) {
        RigidContact::Pt& p = rc.pt[i];
        const Vec3 pos = c.n > 0 ? c.pts[i] : c.point;
        p.depth = c.n > 0 ? c.depths[i] : c.depth;
        p.ra = pos - a.center;
        p.rb = pos - b.center;
        const Vec3 rna = cross(p.ra, c.normal), rnb = cross(p.rb, c.normal);
        p.kn = a.invMass + b.invMass + dot(rna, inv_inertia_mul(a, rna)) + dot(rnb, inv_inertia_mul(b, rnb));
        const float vn = dot(point_velocity(b, p.rb) - point_velocity(a, p.ra), c.normal);
        if (vn < 0.0f) impact = std::max(impact, -vn);
        p.target = (e > 0.0f && -vn >= kBounceThreshold) ? -e * vn : std::min(p.depth, 0.0f) / h;
        p.jn = 0.0f;
        p.jt = {};
    }
    return true;
}

// One velocity pass over a manifold: per point a friction impulse (cone of mu * accumulated normal impulse) and then a
// normal impulse (accumulated and clamped at zero, so a later point can take back what an earlier one over-corrected).
// Impulses act at the contact point, so they change the angular velocity of boxes that contacts can turn.
void Physics3D::solve_velocity(std::vector<Body>& bodies, RigidContact& rc, bool reverse) {
    Body& a = bodies[rc.ia];
    Body& b = bodies[rc.ib];
    const float ia = a.invMass, ib = b.invMass;
    const Vec3 n = rc.n;
    auto push = [](Body& x, Vec3 r, Vec3 impulse) {  // impulse at lever arm r
        x.vel += impulse * x.invMass;
        x.angVel += inv_inertia_mul(x, cross(r, impulse)) * kRadToDeg;
    };
    for (int step = 0; step < rc.count; ++step) {
        RigidContact::Pt& p = rc.pt[reverse ? rc.count - 1 - step : step];  // alternate the sweep order: no bias
        {
            const Vec3 va = point_velocity(a, p.ra), vb = point_velocity(b, p.rb);
            // A carried rider already moved with its platform: friction acts on the rider's own velocity.
            const Vec3 rv = rc.carrier == 1 ? vb : (rc.carrier == 2 ? -va : vb - va);
            const Vec3 vt = rv - n * dot(rv, n);
            const float lt = length(vt);
            if (lt > 1e-6f) {
                const Vec3 t = vt / lt;
                const Vec3 rta = cross(p.ra, t), rtb = cross(p.rb, t);
                const float kt = ia + ib + dot(rta, inv_inertia_mul(a, rta)) + dot(rtb, inv_inertia_mul(b, rtb));
                Vec3 total = p.jt - t * (lt / kt);
                const float limit = rc.mu * p.jn, len = length(total);
                if (len > limit) total = total * (limit / len);
                const Vec3 delta = total - p.jt;
                p.jt = total;
                push(b, p.rb, delta);
                push(a, p.ra, -delta);
            }
        }
        const float vn = dot(point_velocity(b, p.rb) - point_velocity(a, p.ra), n);
        const float before = p.jn;
        p.jn = std::max(before + (p.target - vn) / p.kn, 0.0f);
        const Vec3 impulse = n * (p.jn - before);
        push(b, p.rb, impulse);
        push(a, p.ra, -impulse);
    }
}

// Pushes the pair apart along the normal by the part of its deepest point's penetration that exceeds kSlop (translation
// only; rotation is left to the velocity pass). The depth is kept up to date from the centres' motion since the build.
void Physics3D::correct_position(std::vector<Body>& bodies, const RigidContact& rc) {
    Body& a = bodies[rc.ia];
    Body& b = bodies[rc.ib];
    const float sum = a.invMass + b.invMass;
    float depth = -1e30f;
    for (int i = 0; i < rc.count; ++i) depth = std::max(depth, rc.pt[i].depth);
    depth -= dot((b.center - rc.cb) - (a.center - rc.ca), rc.n);
    if (depth > kSlop) {
        const Vec3 corr = rc.n * ((depth - kSlop) * kPercent / sum);
        a.center -= corr * a.invMass;
        b.center += corr * b.invMass;
    }
}

void Physics3D::step(World& world, float dt) {
    if (lastWorld_ != &world) {
        reset();
        lastWorld_ = &world;
    }
    ++stepCounter_;
    lastDt_ = dt;
    sync(world);
    const std::size_t n = bodies_.size();
    if (n == 0) {
        touching_.clear();
        return;
    }
    for (std::size_t i = 0; i < n; ++i) {  // characters with a velocity walk first, so what they push moves this step
        if (!bodies_[i].character || !bodies_[i].enabled) continue;
        const CharacterController3D* cc = world.get<CharacterController3D>(bodies_[i].e);
        if (!cc || cc->velocity == Vec3{}) continue;
        move_character_body(world, bodies_[i], cc->velocity * dt);
    }
    const Vec3 g = world.settings().gravity3D;
    if (g != lastGravity_) {  // a body asleep on the old gravity would hover on the new one
        lastGravity_ = g;
        for (Body& b : bodies_) wake(b);
    }
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
        for (std::size_t i : riders) {
            wake(bodies_[i]);
            bodies_[i].center += dp;
        }
    }

    auto movable = [](const Body& b) { return b.type != BodyType::Static; };
    auto live_dyn = [](const Body& b) { return b.type == BodyType::Dynamic && !b.asleep; };
    std::vector<std::size_t> riders;
    std::vector<Vec3> disp(n);
    std::vector<RigidContact> rigid;

    // A sleeping body (with its whole group) wakes as soon as something that moves comes within kRiderGap of it: an awake
    // dynamic body, a kinematic body with a velocity, or a body gameplay teleported this step (its new place may overlap).
    auto wake_touched = [&]() {
        if (std::none_of(bodies_.begin(), bodies_.end(), [](const Body& b) { return b.asleep; })) return;
        for (std::size_t i = 0; i < n; ++i) {
            const Body& m = bodies_[i];
            if (!m.enabled || !m.hasShape || m.trigger) continue;
            const bool mover = live_dyn(m) || (m.type != BodyType::Dynamic && (m.moved || m.vel != Vec3{} || m.angVel != Vec3{}));
            if (!mover) continue;
            for (std::size_t k = 0; k < n; ++k) {
                Body& s = bodies_[k];
                if (!s.asleep || !s.enabled || !s.hasShape || s.trigger || !filters_pass(m, s)) continue;
                if (collide(m, s, kRiderGap).hit) wake(s);
            }
        }
    };

    // Time of the first impact (fraction of `disp`, 1 = none) among all pairs that close in on each other faster than
    // the smaller body's half extent per sub-step. The pair is swept in relative motion: the smaller body moves by
    // disp[mover] - disp[target] against the other one standing still at its start position, so two fast dynamic bodies
    // and a fast kinematic body against a dynamic one are caught as well as a dynamic body against a static wall.
    // A rotating box also sweeps through the turn it makes within `span` (its far end can travel more than its centre).
    // Pairs that already overlap at the start (deeper than a touch) are left to the contact solver.
    auto first_impact = [&](float span) {
        auto spin_over = [&](const Body& b) {
            return b.kind != Body::Kind::Sphere && b.rotDyn && live_dyn(b) ? b.angVel * (kDegToRad * span) : Vec3{};  // a sphere turns in place
        };
        float tFirst = 1.0f;
        for (std::size_t i = 0; i < n; ++i) {
            Body& a = bodies_[i];
            if (!a.enabled || !a.hasShape || a.trigger) continue;
            for (std::size_t k = i + 1; k < n; ++k) {
                Body& b = bodies_[k];
                if (!b.enabled || !b.hasShape || b.trigger) continue;
                const bool dynA = a.type == BodyType::Dynamic, dynB = b.type == BodyType::Dynamic;
                if ((!dynA && !dynB) || !filters_pass(a, b)) continue;
                const bool bMoves = !dynA || (dynB && min_half_extent(b) < min_half_extent(a));  // b is the mover
                Body& mover = bMoves ? b : a;
                Body& target = bMoves ? a : b;
                const Vec3 rel = bMoves ? disp[k] - disp[i] : disp[i] - disp[k];
                const Vec3 moverSpin = spin_over(mover), targetSpin = spin_over(target);
                const float he = min_half_extent(mover);
                float t = 1.0f;
                if (length(rel) + turning_reach(mover, moverSpin) + turning_reach(target, targetSpin) > he &&
                    sweep(mover, rel, moverSpin, target, targetSpin, t) && t < tFirst)
                    tFirst = t;
            }
        }
        return tFirst;
    };

    // Resolves the contacts at the current positions. Pairs of rotating boxes (rotDyn) go through the rigid-body solver
    // (manifolds, impulses at the contact points, accumulated and clamped); every other pair keeps the original solver.
    // positional: also push overlapping bodies apart (not at a time-of-impact stop: the overlap there is ~0.1 mm).
    auto resolve = [&](bool positional) {
        wake_touched();
        rigid.clear();
        for (std::size_t i = 0; i < n; ++i) {
            Body& a = bodies_[i];
            if (!a.enabled || !a.hasShape || a.trigger) continue;
            for (std::size_t k = i + 1; k < n; ++k) {
                Body& b = bodies_[k];
                if (!b.enabled || !b.hasShape || b.trigger) continue;
                if (!a.rotDyn && !b.rotDyn) continue;
                if (!live_dyn(a) && !live_dyn(b)) continue;
                if (!filters_pass(a, b)) continue;
                Contact c = collide(a, b, 0.0f, true);
                if (!c.hit || c.depth < 0.0f) continue;
                float& impact = impacts[{a.seq, b.seq}];
                const int car = (carrier[k] == int(i) && a.type == BodyType::Kinematic)
                                    ? 1
                                    : ((carrier[i] == int(k) && b.type == BodyType::Kinematic) ? 2 : 0);
                RigidContact rc;
                if (!build_rigid_contact(a, b, i, k, c, h, car, impact, rc)) continue;
                rc.key = {a.seq, b.seq};
                if (positional) {  // warm start: re-apply what the same contact points carried in the previous sub-step
                    auto cached = warm_.find(rc.key);
                    if (cached != warm_.end()) {
                        std::vector<WarmPt>& old = cached->second;
                        std::vector<char> used(old.size(), 0);
                        for (int pi = 0; pi < rc.count; ++pi) {
                            RigidContact::Pt& p = rc.pt[pi];
                            const Vec3 pos = a.center + p.ra;
                            int best = -1;
                            float bestD = kWarmRadius * kWarmRadius;
                            for (std::size_t oi = 0; oi < old.size(); ++oi) {
                                const float d = length_sq(old[oi].pos - pos);
                                if (!used[oi] && d < bestD) { bestD = d; best = int(oi); }
                            }
                            if (best < 0) continue;
                            used[best] = 1;
                            p.jn = old[best].jn;
                            p.jt = old[best].jt;
                            const Vec3 impulse = rc.n * p.jn + p.jt;
                            b.vel += impulse * b.invMass;
                            b.angVel += inv_inertia_mul(b, cross(p.rb, impulse)) * kRadToDeg;
                            a.vel -= impulse * a.invMass;
                            a.angVel -= inv_inertia_mul(a, cross(p.ra, impulse)) * kRadToDeg;
                        }
                    }
                }
                rigid.push_back(rc);
            }
        }
        const bool jointsOn = positional && prepare_joints(h);
        const int iterations = (rigid.empty() && !jointsOn) ? kIterations : kRigidIterations;
        for (int it = 0; it < iterations; ++it) {
            for (std::size_t i = 0; i < n && it < kIterations; ++i) {
                Body& a = bodies_[i];
                if (!a.enabled || !a.hasShape || a.trigger) continue;
                for (std::size_t k = i + 1; k < n; ++k) {
                    Body& b = bodies_[k];
                    if (!b.enabled || !b.hasShape || b.trigger) continue;
                    if (a.rotDyn || b.rotDyn) continue;
                    if (!live_dyn(a) && !live_dyn(b)) continue;
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
                        solve_pair(b, a, m, h, impact, carried, positional);
                    } else {
                        solve_pair(a, b, c, h, impact, carried, positional);
                    }
                }
            }
            for (std::size_t ri = 0; ri < rigid.size(); ++ri) {
                RigidContact& rc = rigid[(it & 1) ? rigid.size() - 1 - ri : ri];
                if (positional && it < kIterations) correct_position(bodies_, rc);
                solve_velocity(bodies_, rc, (it & 1) != 0);
            }
            if (jointsOn) solve_joints(h);
        }
        if (positional) {  // remember the solution as the next sub-step's starting point
            warm_.clear();
            for (const RigidContact& rc : rigid) {
                std::vector<WarmPt>& cache = warm_[rc.key];
                for (int pi = 0; pi < rc.count; ++pi)
                    cache.push_back({rc.ca + rc.pt[pi].ra, rc.pt[pi].jn, rc.pt[pi].jt});
            }
        }
    };

    for (int s = 0; s < subs; ++s) {
        std::fill(carrier.begin(), carrier.end(), -1);
        for (std::size_t k = 0; k < n; ++k) {
            const Body& p = bodies_[k];
            if (p.type != BodyType::Kinematic || p.vel == Vec3{}) continue;
            riders.clear();
            find_riders(k, riders);
            Vec3 d = p.vel * h;
            if (d.y > 0.0f) d.y = 0.0f;  // upward motion is delivered by the contact itself
            for (std::size_t i : riders) {
                if (carrier[i] >= 0) continue;
                carrier[i] = int(k);
                bodies_[i].center += d;
            }
        }
        for (Body& b : bodies_) {
            if (!b.enabled || !live_dyn(b)) continue;
            b.vel += (g * b.gravityScale + b.force * b.invMass) * h;
            if (b.damping > 0.0f) b.vel *= 1.0f / (1.0f + h * b.damping);
            if (b.angDamping > 0.0f) b.angVel *= 1.0f / (1.0f + h * b.angDamping);
            if (b.rotDyn && b.kind != Body::Kind::Sphere && b.angVel != Vec3{}) {  // a box turning in the air precesses like a real one
                const Vec3 w = world_to_frame(b.ax, b.angVel * kDegToRad);
                const Vec3 turned = gyroscopic_step(w, {1.0f / b.invI.x, 1.0f / b.invI.y, 1.0f / b.invI.z}, h);
                b.angVel = frame_to_world(b.ax, turned) * kRadToDeg;
            }
        }
        // Motion with continuous collision. The bodies advance together up to the first impact (a time of impact), the
        // contacts are resolved there (the velocity of the hit bodies changes: stop, bounce, slide), and the rest of the
        // sub-step continues with the new velocities, so a fast body keeps sliding along the surface it hit.
        float remaining = 1.0f + carry_;  // plus what the previous sub-step had no impacts left to move
        carry_ = 0.0f;
        for (int event = 0;; ++event) {
            if (event == kMaxToiEvents) {  // more impacts than this sub-step can resolve: the rest of the move waits
                carry_ = std::min(remaining, 1.0f);
                break;
            }
            const float span = h * remaining;
            for (std::size_t i = 0; i < n; ++i) {
                const Body& b = bodies_[i];
                disp[i] = (b.enabled && movable(b) && !b.asleep) ? b.vel * span : Vec3{};
            }
            const float tHit = first_impact(span);
            for (std::size_t i = 0; i < n; ++i) {
                Body& b = bodies_[i];
                if (!b.enabled || !movable(b)) continue;
                b.center += disp[i] * tHit;
                if (b.rotDyn) integrate_orient(b, span * tHit);
            }
            if (tHit >= 1.0f) break;
            resolve(false);
            remaining *= 1.0f - tHit;
            if (remaining < 1e-3f) break;
        }
        resolve(true);
    }
    for (Body& b : bodies_) {
        b.force = {};
        b.moved = false;
    }

    // ---- events: track overlapping pairs across frames
    std::map<PairKey, PairState> cur;
    auto& out = world.events().collisions;
    struct Begin { PairKey key; PairState st; Contact c; };
    std::vector<Begin> begins;
    std::vector<char> supported(n, 0);  // dynamic body has solid ground (normal up) under it
    std::vector<std::pair<std::size_t, std::size_t>> links;  // touching awake dynamic bodies: they sleep together
    std::vector<char> hold(n, 0);  // touches a moving kinematic body: must stay awake
    auto driving = [](const Body& b) { return b.type == BodyType::Kinematic && (b.vel != Vec3{} || b.angVel != Vec3{}); };
    for (std::size_t i = 0; i < n; ++i) {
        const Body& a = bodies_[i];
        if (!a.enabled || !a.hasShape) continue;
        for (std::size_t k = i + 1; k < n; ++k) {
            const Body& b = bodies_[k];
            if (!b.enabled || !b.hasShape) continue;
            PairKey key{a.seq, b.seq};
            if ((a.asleep || !movable(a)) && (b.asleep || !movable(b))) {  // nothing moves: the pair keeps its state
                auto old = touching_.find(key);
                if (old != touching_.end()) cur.insert(*old);
                continue;
            }
            if (!filters_pass(a, b)) continue;
            const bool trig = a.trigger || b.trigger;
            if (trig && a.trigger && b.trigger) continue;
            bool was = touching_.count(key) != 0;
            float margin = trig ? 0.0f : (was ? kEndMargin : kBeginMargin);
            Contact c = collide(a, b, margin);
            bool now = trig ? (c.hit && c.depth > 0.0f) : c.hit;
            if (!now) continue;
            if (!trig) {
                if (b.type == BodyType::Dynamic && c.normal.y > 0.7f) supported[k] = 1;
                if (a.type == BodyType::Dynamic && c.normal.y < -0.7f) supported[i] = 1;
                if (live_dyn(a) && live_dyn(b)) links.push_back({i, k});
                if (live_dyn(a) && driving(b)) hold[i] = 1;
                if (live_dyn(b) && driving(a)) hold[k] = 1;
            }
            PairState st{a.e, b.e, trig};
            cur[key] = st;
            if (!was) begins.push_back({key, st, c});
        }
    }
    for (auto& [key, st] : touching_) {
        if (cur.count(key)) continue;
        if (!live(world, st.a) || !live(world, st.b)) continue;
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
        if (!b.enabled || !live_dyn(b) || b.kind != Body::Kind::Sphere || !b.hasShape || b.trigger) continue;
        if (!b.rollWithMotion || !supported[i]) continue;
        // axis = up x v = (vz, 0, -vx); rate = |v| / r (rad/s) -> deg/s along that axis => components (vz, 0, -vx) / r
        const float k = degrees(1.0f) / b.radius;
        b.angVel = {b.vel.z * k, 0.0f, -b.vel.x * k};
    }

    // ---- sleeping: bodies linked by contacts form an island, and an island whose members were all calm for kTimeToSleep
    // (and touch no moving kinematic body) falls asleep together: zero velocity, no solver work, no events, until woken.
    std::vector<std::size_t> root(n);
    for (std::size_t i = 0; i < n; ++i) root[i] = i;
    auto find_root = [&](std::size_t x) {
        while (root[x] != x) x = root[x] = root[root[x]];
        return x;
    };
    for (const auto& [i, k] : links) root[find_root(i)] = find_root(k);
    std::vector<char> ready(n, 1);
    for (std::size_t i = 0; i < n; ++i) {
        Body& b = bodies_[i];
        if (!b.enabled || !live_dyn(b)) continue;
        const float reach = !b.hasShape ? 0.0f : bound_radius(b);  // fastest point of the shape
        const bool calm = std::max(length(b.vel), length(b.angVel) * kDegToRad * reach) < kSleepSpeed;
        b.sleepTime = calm ? b.sleepTime + dt : 0.0f;
        if (b.sleepTime < kTimeToSleep || hold[i] || b.jointed) ready[find_root(i)] = 0;
    }
    for (std::size_t i = 0; i < n; ++i) {
        Body& b = bodies_[i];
        if (!b.enabled || !live_dyn(b) || !ready[find_root(i)]) continue;
        b.asleep = true;
        b.sleepGroup = bodies_[find_root(i)].seq;  // the island is named after its root (seq is never reused)
        b.vel = b.angVel = {};
    }

    // ---- write back
    for (Body& b : bodies_) {
        if (!b.enabled || b.type == BodyType::Static || !world.alive(b.e)) continue;
        if (Transform* t = world.get<Transform>(b.e)) {
            if (b.rotDyn) {  // the quaternion was integrated during the sub-steps: write it as the entity's rotation
                if (b.rotDirty) {
                    Vec3 r[3];
                    axes_of(b.orient, r);
                    t->rotation = local_euler(world, b.e, r);
                    b.lastEuler = t->rotation;
                }
            } else if (b.angVel != Vec3{}) {
                t->rotation += b.angVel * dt;
            }
        }
        b.rotDirty = false;
        if (RigidBody3D* rb = world.get<RigidBody3D>(b.e)) {
            rb->angularVelocity = b.angVel;
            b.lastAngVel = b.angVel;
        }
        if (b.center != b.lastCenter || b.originDirty) {
            world.set_world_position(b.e, b.center - b.offset);
            b.lastPos = world.world_position(b.e);
            b.lastCenter = b.center;
        }
        b.originDirty = false;
        if (RigidBody3D* rb = world.get<RigidBody3D>(b.e)) {
            rb->velocity = b.vel;
            b.lastVel = b.vel;
        }
    }
    finish_joints(world);
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
        if (!b.enabled || !b.hasShape || (b.trigger && opt.ignoreTriggers) || !live(world, b.e)) continue;
        if ((category_bits(b.layer) & qmask) == 0) continue;
        if (entity_or_ancestor_is(world, b.e, opt.ignore)) continue;
        if (b.general()) {  // capsule / convex / mesh
            float t = 0.0f;
            Vec3 gn;
            if (ray_body(b, origin, d, bestT, t, gn) && t <= bestT) {
                bestT = t;
                best = &b;
                bestN = gn;
            }
            continue;
        }
        // A turned box is tested in its own frame (same distances); an unturned one in world space, exactly as before.
        Vec3 lo = b.center - b.half, hi = b.center + b.half, org = origin, od = d;
        if (b.rotated) {
            lo = -b.half;
            hi = b.half;
            org = world_to_frame(b.ax, origin - b.center);
            od = world_to_frame(b.ax, d);
        }
        {   // origin inside this collider: skip it
            bool inside = b.kind == Body::Kind::Box ? (org.x > lo.x && org.x < hi.x && org.y > lo.y && org.y < hi.y &&
                                   org.z > lo.z && org.z < hi.z)
                                : length_sq(origin - b.center) < b.radius * b.radius;
            if (inside) continue;
        }
        float t = 0.0f;
        Vec3 nrm;
        if (b.kind == Body::Kind::Box) {
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
    probe.kind = shape.kind == CastShape::Kind::Box ? Body::Kind::Box : Body::Kind::Sphere;
    probe.half = {std::max(shape.size.x * 0.5f, 1e-3f), std::max(shape.size.y * 0.5f, 1e-3f),
                  std::max(shape.size.z * 0.5f, 1e-3f)};
    probe.radius = std::max(shape.radius, 1e-3f);
    probe.center = from;
    const std::uint64_t qmask = mask_bits(opt.mask);
    float bestT = 2.0f;
    const Body* best = nullptr;
    for (Body& b : bodies_) {  // (sweep restores what it touches)
        if (!b.enabled || !b.hasShape || (b.trigger && opt.ignoreTriggers) || !live(world, b.e)) continue;
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
        if (sweep(probe, disp, {}, b, {}, t) && t < bestT) {
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
        if (&b == &a || !b.enabled || !b.hasShape || b.trigger || !live(world, b.e)) continue;
        if (!filters_pass(a, b)) continue;
        Contact c = collide(a, b, std::max(tolerance, 0.0f));
        if (c.hit && dot(c.normal, dir) > 0.7f) return true;
    }
    return false;
}

std::vector<Entity> Physics3D::overlap_sphere(World& world, Vec3 center, float radius, std::int32_t mask) {
    std::vector<Entity> out;
    Body probe;
    probe.kind = Body::Kind::Sphere;
    probe.hasShape = true;
    probe.radius = std::max(radius, 0.0f);
    probe.center = center;
    const std::uint64_t qmask = mask_bits(mask);
    for (const Body& b : bodies_) {
        if (!b.enabled || !b.hasShape || !live(world, b.e)) continue;
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
    wake(b);
    b.vel += impulse * b.invMass;
    if (auto* rb = world.get<RigidBody3D>(e)) rb->velocity = b.vel;
    b.lastVel = b.vel;
}

void Physics3D::apply_force(World&, Entity e, Vec3 force) {
    auto it = index_.find(e.bits());
    if (it == index_.end()) return;
    Body& b = bodies_[it->second];
    if (b.type != BodyType::Dynamic) return;
    wake(b);
    b.force += force;
}

void Physics3D::set_velocity(World& world, Entity e, Vec3 velocity) {
    auto it = index_.find(e.bits());
    if (it == index_.end()) return;
    Body& b = bodies_[it->second];
    if (b.type == BodyType::Static) return;
    wake(b);
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
        j["awake"] = b.enabled && b.type != BodyType::Static && !b.asleep;  // like Box2D: false for static bodies
        Json shapes = Json::array();
        if (b.hasShape) {
            Json s = Json::object();
            const Vec3 rot = b.rotated ? euler_of(b.ax) : Vec3{};  // world rotation, euler degrees (like Transform)
            switch (b.kind) {
                case Body::Kind::Box:
                    s["kind"] = "box";
                    s["size"] = Json::array({b.half.x * 2, b.half.y * 2, b.half.z * 2});
                    s["rotation"] = Json::array({rot.x, rot.y, rot.z});
                    break;
                case Body::Kind::Sphere:
                    s["kind"] = "sphere";
                    s["radius"] = b.radius;
                    break;
                case Body::Kind::Capsule:
                    s["kind"] = "capsule";
                    s["radius"] = b.radius;
                    s["height"] = (b.segHalf + b.radius) * 2.0f;
                    s["rotation"] = Json::array({rot.x, rot.y, rot.z});
                    break;
                default:
                    s["kind"] = b.kind == Body::Kind::Convex ? "convex" : "mesh";
                    s["mesh"] = b.meshName;
                    s["triangles"] = b.data ? int(b.data->geometry->indices.size() / 3) : 0;
                    s["size"] = Json::array({b.half.x * 2, b.half.y * 2, b.half.z * 2});  // bounding box
                    s["rotation"] = Json::array({rot.x, rot.y, rot.z});
                    break;
            }
            s["offset"] = Json::array({b.offset.x, b.offset.y, b.offset.z});
            s["trigger"] = b.trigger;
            shapes.push_back(s);
        }
        j["shapes"] = shapes;
        if (b.character) j["character"] = true;
        if (b.jointed) j["jointed"] = true;
        if (!b.problem.empty()) j["problem"] = b.problem;
        out.push_back(j);
    }
}

void Physics3D::debug_shapes(const World& world, std::vector<Physics::DebugShape>& out) const {
    for (const Body& b : bodies_) {
        if (!b.enabled || !b.hasShape || !live(world, b.e)) continue;
        const Vec3 rot = b.rotated ? euler_of(b.ax) : Vec3{};
        switch (b.kind) {
            case Body::Kind::Box:
                out.push_back({Physics::DebugShape::Box, b.center, b.half * 2.0f, rot.z, b.trigger, rot});
                break;
            case Body::Kind::Sphere:
                out.push_back({Physics::DebugShape::Sphere, b.center, Vec3{b.radius * 2.0f}, 0.0f, b.trigger});
                break;
            case Body::Kind::Capsule:  // size = {diameter, full height, diameter} along the entity's local Y
                out.push_back({Physics::DebugShape::Capsule, b.center, Vec3{b.radius * 2.0f, (b.segHalf + b.radius) * 2.0f, b.radius * 2.0f},
                               rot.z, b.trigger, rot});
                break;
            default:  // convex / mesh: the oriented bounding box of the model (centre moved to the box's centre)
                out.push_back({b.kind == Body::Kind::Convex ? Physics::DebugShape::Convex : Physics::DebugShape::Mesh,
                               b.center + frame_to_world(b.ax, b.lcenter), b.half * 2.0f, rot.z, b.trigger, rot});
                break;
        }
    }
}

}  // namespace fa::detail
