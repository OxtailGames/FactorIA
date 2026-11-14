// Simple 3D physics: spheres + oriented boxes, semi-implicit Euler, impulse resolution, automatic continuous collision.
// Boxes follow the entity's world rotation. A dynamic box (or a sphere with rollWithMotion off) without lockRotation is
// a rigid body: its contacts are manifolds (clipped faces), the solver applies normal and friction impulses at the
// contact points (soft contacts, a manifold's points solved together: see solve_manifold) and so turns it (inertia tensor
// from its size and mass, orientation kept as a quaternion). Everything
// else (arcade rolling spheres, locked bodies, kinematic and static bodies) keeps the original torque-free single-point
// solver. An unrotated box keeps the exact axis-aligned code paths. Calm dynamic bodies fall asleep in islands, a box
// turning in the air precesses (gyroscopic_step), and the sub-step motion is swept for impacts, rotation included.
// Capsules, convex hulls and triangle meshes (physics3d_shapes.cpp) share all of this through collide(); joints are in
// physics3d_joints.cpp and the character controller in physics3d_character.cpp.
#include <algorithm>
#include <cmath>
#include <format>
#include <iterator>
#include <unordered_set>

#include "fa/core/jobs.h"
#include "fa/core/log.h"
#include "fa/scene/mesh_geometry.h"

#include "inertia3d.h"
#include "physics_internal.h"

namespace fa::detail {

namespace {
constexpr float kSlop = 0.001f;           // allowed penetration (m)
constexpr float kMaxCorrection = 0.2f;    // the most a manifold point is pushed out per correction pass (m)
constexpr float kPercent = 0.9f;          // positional correction strength
constexpr float kPushOut = 3.0f;          // the most speed a soft contact pushes a penetration out with (m/s)
constexpr float kContactHertz = 60.0f;    // stiffness of a soft contact: its spring's frequency (Hz) ...
constexpr float kContactDamping = 10.0f;  // ... and its damping ratio (a dynamic pair; against a static body the spring is 2x stiffer)
constexpr int kBiasIterations = 2;        // velocity passes with the soft push-out, before the sub-step's motion
constexpr float kRestSpeed = 0.5f;        // a body pressed against another dynamic body and slower than this (m/s) is settling: ...
constexpr float kRestDamping = 1.0f;      // ... it loses speed at this rate (1/s), so what rolls or rocks on a pile comes to rest
constexpr float kBounceThreshold = 0.5f;  // m/s below which restitution is ignored
constexpr float kBeginMargin = 0.01f;     // solid contact begins within this gap
constexpr float kEndMargin = 0.05f;       // ...and ends once the gap exceeds this
constexpr int kIterations = 2;
constexpr float kRiderGap = 0.02f;    // a dynamic body this close above a kinematic one is carried by it
constexpr float kAlignedEps = 1e-6f;  // off-diagonal rotation below this = axis-aligned (exact AABB paths)
constexpr float kSweepTol = 1e-4f;    // swept contacts are bisected to this distance (m)
constexpr float kCastSkin = 0.01f;  // shape casts: penetration at `from` up to this is a resting touch, not an overlap
constexpr float kManifoldGap = 0.003f;  // box-box manifold points this far above the reference face still count (m)
constexpr int kRigidIterations = 8;     // velocity iterations of the rigid-body solver, per sub-step
constexpr int kChainIterations = 16;    // ...for the bodies of a chain of three or more joined bodies (a rope bridge)
constexpr float kChainDrag = 1.0f;      // ...and those bodies lose this much speed per second (1/s): a bridge settles
constexpr float kStartOverlap = 0.01f;  // a dynamic body starting this deep inside a static collider is reported (m)
constexpr int kMaxToiEvents = 32;       // time-of-impact stops (and rest-of-the-sub-step continuations) per sub-step
constexpr float kTouchSkin =
    0.002f;  // a swept pair this deep at the start of the move is touching, not overlapping (m)
constexpr float kTouchGain = 0.0005f;  // ...and counts as hit again once it sinks this much deeper (m)
constexpr float kWarmRadius =
    0.05f;  // a contact point inherits the impulses of the previous sub-step's one this close (m)
// Pair scans on the job system (docs/ARCHITECTURE.md, "Physics on jobs"): the narrow phase of a big scene is computed by
// chunks of rows in parallel (each row asks the broad phase for its candidate partners) and replayed in row order, so the
// result is the one of the single-threaded scan.
constexpr std::size_t kMinParallelRows = 64;  // fewer rows than this: the scan runs on the calling thread
constexpr std::size_t kPairChunkRows = 16;    // rows of one chunk
// Broad phase (broadphase3d.h): a body's fat box is its bounds grown by this margin (m) and, when it moves, stretched by
// its velocity over kFatStretchSteps steps; a body at rest keeps a thin one.
constexpr float kFatMarginMoving = 0.1f;
constexpr float kFatMarginStill = 0.02f;
constexpr float kFatStretchSteps = 2.0f;
constexpr float kSmallReach = 2.0f;  // an island search asks the broad phase for bodies of at most this reach
constexpr float kBpEps = 1e-3f;       // the boxes a query asks about are this much bigger than the narrow phase's reach
constexpr float kSleepSpeed = 0.05f;  // a body is calm below this speed (m/s; its fastest point counts, spin included)
constexpr float kTimeToSleep = 0.5f;  // ...and falls asleep, with the bodies it touches, after this long (s)
constexpr int kStragglers = 64;          // a pile of N bodies sleeps with up to N / kStragglers of them still creeping ...
constexpr float kStragglerSpeed = 0.3f;  // ... each slower than this (m/s): a big pile never stops completely

// Islands: indices that belong together. The root of a set is its smallest index, so the result never depends on the
// order the links were made in.
struct UnionFind {
    std::vector<std::size_t> p;
    explicit UnionFind(std::size_t n) : p(n) {
        for (std::size_t i = 0; i < n; ++i) p[i] = i;
    }
    std::size_t find(std::size_t x) {
        while (p[x] != x) x = p[x] = p[p[x]];
        return x;
    }
    void unite(std::size_t a, std::size_t b) {
        a = find(a);
        b = find(b);
        if (a < b)
            p[b] = a;
        else if (b < a)
            p[a] = b;
    }
};

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
        yaw = det::atan2(ax[2].x, ax[2].z);
        roll = det::atan2(ax[0].y, ax[1].y);
    } else {  // gimbal lock: fold the roll into the yaw
        yaw = det::atan2(-ax[0].z, ax[0].x);
        roll = 0.0f;
    }
    return {degrees(det::asin(sp)), degrees(yaw), degrees(roll)};
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
    const float half = 0.5f * len * seconds, s = det::sin(half) / len;
    return normalize(Quat{w.x * s, w.y * s, w.z * s, det::cos(half)} * q);
}

}  // namespace

void Physics3D::reset() {
    bodies_.clear();
    bp_.clear();
    index_.clear();
    touching_.clear();
    frozen_.clear();
    frozenDirty_ = false;
    warm_.clear();
    joints_.clear();
    jointOrder_.clear();
    navs_.clear();
    navOrder_.clear();
    lastWorld_ = nullptr;
    ++layoutGen_;
    awakeStale_ = true;
    chainsMarked_ = false;
    nextSeq_ = 1;
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
            awakeStale_ = true;
            frozenDirty_ = true;
        }
    }
}

void Physics3D::wake_touching(std::uint64_t seq) {
    for (const std::vector<std::pair<PairKey, PairState>>* pairs : {&touching_, &frozen_})
        for (const auto& [key, st] : *pairs) {
            if (key.first != seq && key.second != seq) continue;
            const std::uint64_t other = key.first == seq ? key.second : key.first;
            auto it = std::lower_bound(bodies_.begin(), bodies_.end(), other,
                                       [](const Body& b, std::uint64_t s) { return b.seq < s; });
            if (it != bodies_.end() && it->seq == other) wake(*it);
        }
}

bool Physics3D::filters_pass(const Body& a, const Body& b) {
    if (!a.noCollide.empty() && std::find(a.noCollide.begin(), a.noCollide.end(), b.seq) != a.noCollide.end())
        return false;
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
                if (pen < best) {
                    best = pen;
                    axis = i;
                    sgn = d >= 0.0f ? 1.0f : -1.0f;
                }
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
                if (pen < best) {
                    best = pen;
                    axis = i;
                    sgn = l[i] >= 0.0f ? 1.0f : -1.0f;
                }
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
// the six face axes over the nine edge-edge axes unless an edge axis is clearly shallower (stable resting contacts), and
// the faces of `a` over those of `b` unless b's is clearly shallower (so a pair keeps its reference face from step to step).
void Physics3D::box_box_sat(const Body& a, const Body& b, float margin, Contact& c, bool manifold) {
    const Vec3 d = b.center - a.center;
    float edgeOv = 1e30f;
    float faceOv[2] = {1e30f, 1e30f};  // least overlap along a face axis of a (0) and of b (1)
    Vec3 faceN[2], edgeN;
    int faceAxis[2] = {0, 0}, edgeI = 0, edgeJ = 0;
    auto test = [&](Vec3 axis, bool edge, int owner, int index) {  // false = separated by more than the margin
        float ra = 0.0f, rb = 0.0f;
        for (int i = 0; i < 3; ++i) {
            ra += std::fabs(dot(a.ax[i], axis)) * a.half[i];
            rb += std::fabs(dot(b.ax[i], axis)) * b.half[i];
        }
        const float proj = dot(d, axis);
        const float ov = ra + rb - std::fabs(proj);
        if (ov <= -margin) return false;
        if (edge) {
            if (ov < edgeOv) {
                edgeOv = ov;
                edgeN = proj >= 0.0f ? axis : -axis;
                edgeI = owner;  // an edge axis is a x b: the axis of a and the axis of b
                edgeJ = index;
            }
        } else if (ov < faceOv[owner]) {
            faceOv[owner] = ov;
            faceN[owner] = proj >= 0.0f ? axis : -axis;
            faceAxis[owner] = index;
        }
        return true;
    };
    for (int i = 0; i < 3; ++i)
        if (!test(a.ax[i], false, 0, i) || !test(b.ax[i], false, 1, i)) return;
    for (int i = 0; i < 3; ++i) {
        for (int j = 0; j < 3; ++j) {
            Vec3 x = cross(a.ax[i], b.ax[j]);
            const float len = length(x);
            if (len < 1e-4f) continue;  // parallel edges: the face axes cover them
            if (!test(x / len, true, i, j)) return;
        }
    }
    const int refOwner = faceOv[1] < faceOv[0] - 0.001f - 0.02f * std::fabs(faceOv[0]) ? 1 : 0;
    const float bestFace = std::min(faceOv[0], faceOv[1]);
    const bool useEdge = edgeOv < bestFace * 0.95f - 0.01f;
    c.depth = useEdge ? edgeOv : faceOv[refOwner];
    c.normal = useEdge ? edgeN : faceN[refOwner];
    c.hit = true;
    if (useEdge) {
        // Edge against edge: the closest points of the two supporting edges (the edge of a along its axis i at the corner
        // furthest along the normal, the edge of b along its axis j at the corner furthest against it), one contact point.
        Vec3 pa = a.center, pb = b.center;
        std::uint32_t signs = 0;
        for (int m = 0; m < 3; ++m) {
            const float sa = dot(c.normal, a.ax[m]) >= 0.0f ? 1.0f : -1.0f;
            const float sb = dot(c.normal, b.ax[m]) >= 0.0f ? 1.0f : -1.0f;
            if (m != edgeI) pa += a.ax[m] * (a.half[m] * sa);
            if (m != edgeJ) pb -= b.ax[m] * (b.half[m] * sb);
            signs |= (sa > 0.0f ? 1u : 0u) << m;
            signs |= (sb > 0.0f ? 1u : 0u) << (3 + m);
        }
        const Vec3 u = a.ax[edgeI], v = b.ax[edgeJ], r = pa - pb;
        const float uv = dot(u, v), ru = dot(r, u), rv = dot(r, v), den = std::max(1.0f - uv * uv, 1e-8f);
        float s = std::clamp((uv * rv - ru) / den, -a.half[edgeI], a.half[edgeI]);
        const float t = std::clamp(rv + s * uv, -b.half[edgeJ], b.half[edgeJ]);
        s = std::clamp(t * uv - ru, -a.half[edgeI], a.half[edgeI]);
        c.point = ((pa + u * s) + (pb + v * t)) * 0.5f;
        if (manifold) {
            c.n = 1;
            c.pts[0] = c.point;
            c.depths[0] = c.depth;
            c.ids[0] = mix_id(0xED6Eu, std::uint32_t(edgeI * 3 + edgeJ), signs);
        }
        return;
    }
    // Contact point: b's deepest point against the normal (a face centre where b's face is parallel), averaged with its
    // closest point on a.
    Vec3 p = b.center;
    for (int i = 0; i < 3; ++i) {
        const float s = dot(c.normal, b.ax[i]);
        if (std::fabs(s) > 1e-4f) p -= b.ax[i] * (s > 0.0f ? b.half[i] : -b.half[i]);
    }
    const Vec3 q = a.center + frame_to_world(a.ax, min(max(world_to_frame(a.ax, p - a.center), -a.half), a.half));
    c.point = (p + q) * 0.5f;
    if (manifold) {  // face contact: the incident face clipped to the reference face
        if (refOwner == 0)
            face_manifold(a, faceAxis[0], c.normal, b, 0, c);
        else
            face_manifold(b, faceAxis[1], -c.normal, a, 1, c);
    }
}

// Contact manifold of a face-to-face box contact: the face of `inc` that points most against `refNormal` (the outward
// normal of face `refAxis` of `ref`) is clipped to the side planes of that reference face, and the corners of the result
// that are not more than kManifoldGap above the reference plane become the contact points (depth < 0 = still apart),
// reduced to at most kMaxPts. Each corner carries the id of its feature (a corner of the incident face, or the crossing of
// one of its edges with a side plane), so the same corner has the same id for as long as the faces overlap that way.
void Physics3D::face_manifold(const Body& ref, int refAxis, Vec3 refNormal, const Body& inc, int refOwner, Contact& c) {
    int k = 0;
    float bestDot = 0.0f;
    for (int i = 0; i < 3; ++i) {
        const float d = std::fabs(dot(inc.ax[i], refNormal));
        if (d > bestDot) {
            bestDot = d;
            k = i;
        }
    }
    const float side = dot(inc.ax[k], refNormal) > 0.0f ? -1.0f : 1.0f;  // outward direction of the incident face
    const int u = (k + 1) % 3, v = (k + 2) % 3;
    const Vec3 fc = inc.center + inc.ax[k] * (side * inc.half[k]);
    const Vec3 up = inc.ax[u] * inc.half[u], uq = inc.ax[v] * inc.half[v];
    struct Vert {
        Vec3 p;
        std::uint32_t id;
    };
    // The corners of the incident face; an id is the corner's index in the box (one bit per axis: on the + side).
    const std::uint32_t base = side > 0.0f ? 1u << k : 0u;
    Vert poly[16] = {{fc + up + uq, base | (1u << u) | (1u << v)},
                     {fc - up + uq, base | (1u << v)},
                     {fc - up - uq, base},
                     {fc + up - uq, base | (1u << u)}},
         tmp[16];
    int cnt = 4;
    constexpr float kClipEps = 1e-6f;  // a corner this far outside a side plane still counts as on it (no near-duplicates)
    for (int s = 0; s < 4 && cnt > 0; ++s) {  // Sutherland-Hodgman against the reference face's four side planes
        const int w = (refAxis + 1 + (s >> 1)) % 3;
        const Vec3 m = (s & 1) ? -ref.ax[w] : ref.ax[w];
        const float h = ref.half[w];
        int out = 0;
        for (int i = 0; i < cnt; ++i) {
            const Vert cur = poly[i], nxt = poly[(i + 1) % cnt];
            const float dc = dot(cur.p - ref.center, m) - h, dn = dot(nxt.p - ref.center, m) - h;
            const bool inC = dc <= kClipEps, inN = dn <= kClipEps;
            if (inC) tmp[out++] = cur;
            if (inC != inN) {
                // With the tolerance the corners can be on different sides while dc and dn are almost equal (an edge nearly
                // parallel to the plane) or on the same side of zero: t is kept on the edge, never beyond its ends.
                const float span = dc - dn;
                const float t = span != 0.0f ? std::clamp(dc / span, 0.0f, 1.0f) : 0.0f;
                tmp[out++] = {cur.p + (nxt.p - cur.p) * t,
                              mix_id(std::min(cur.id, nxt.id), std::max(cur.id, nxt.id), 100u + std::uint32_t(s))};
            }
        }
        for (int i = 0; i < out; ++i) poly[i] = tmp[i];
        cnt = out;
    }
    const Vec3 faceCenter = ref.center + refNormal * ref.half[refAxis];
    const std::uint32_t refFace =
        std::uint32_t(refOwner * 8 + refAxis * 2 + (dot(refNormal, ref.ax[refAxis]) > 0.0f ? 1 : 0));
    const std::uint32_t incFace = std::uint32_t(k * 2 + (side > 0.0f ? 1 : 0));
    Vec3 pts[16];
    float depths[16];
    std::uint32_t ids[16];
    int m = 0;
    for (int i = 0; i < cnt; ++i) {
        const float sep = dot(poly[i].p - faceCenter, refNormal);
        if (sep > kManifoldGap) continue;
        pts[m] = poly[i].p - refNormal * (sep * 0.5f);  // half way between the corner and the reference plane
        depths[m] = -sep;
        ids[m] = mix_id(refFace, incFace, poly[i].id);
        ++m;
    }
    c.n = 0;
    if (m > 0) reduce_manifold(c, pts, depths, ids, m);
}

// The points of a manifold: merged when closer than kMergeDist and reduced to at most kMaxPts. Four points are chosen:
// the deepest one, the one farthest from it, and the two that span the largest triangles with them (one on each side of that
// line when there are points on both, else the two largest on the one side; a thin sliver keeps three points). Every comparison has a tolerance and falls back to the lowest index, so float
// noise in the inputs does not change the choice, and the output is in the winding order of the polygon.
void Physics3D::reduce_manifold(Contact& c, const Vec3* pts, const float* depths, const std::uint32_t* ids, int n) {
    constexpr float kMergeDist = 1e-4f;  // points closer than this are one point (m)
    constexpr float kDepthTie = 1e-3f;   // depths within this of the deepest are tied (m)
    constexpr float kTie = 1e-5f;        // ties of squared distances and areas
    constexpr int kCap = 16;
    Vec3 p[kCap];
    float d[kCap];
    std::uint32_t id[kCap];
    int m = 0;
    for (int i = 0; i < n && i < kCap; ++i) {
        int same = -1;
        for (int j = 0; j < m && same < 0; ++j)
            if (length_sq(p[j] - pts[i]) < kMergeDist * kMergeDist) same = j;
        if (same >= 0) {
            d[same] = std::max(d[same], depths[i]);
            continue;
        }
        p[m] = pts[i];
        d[m] = depths[i];
        id[m] = ids[i];
        ++m;
    }
    int sel[kMaxPts];
    int count = 0;
    if (m <= kMaxPts) {
        for (int i = 0; i < m; ++i) sel[count++] = i;
    } else {
        float deepest = d[0];
        for (int i = 1; i < m; ++i) deepest = std::max(deepest, d[i]);
        int i0 = 0;
        while (d[i0] < deepest - kDepthTie) ++i0;
        float far2 = -1.0f;
        for (int i = 0; i < m; ++i)
            if (i != i0) far2 = std::max(far2, length_sq(p[i] - p[i0]));
        int i1 = -1;
        for (int i = 0; i < m && i1 < 0; ++i)
            if (i != i0 && length_sq(p[i] - p[i0]) >= far2 - kTie) i1 = i;
        if (i1 < 0) i1 = i0 == 0 ? 1 : 0;  // never: far2 is the largest distance, one point reaches it
        const Vec3 edge = p[i1] - p[i0];
        float area[kCap];
        float hi = -1e30f, lo = 1e30f;
        for (int i = 0; i < m; ++i) {
            area[i] = (i == i0 || i == i1) ? 0.0f : dot(cross(edge, p[i] - p[i0]), c.normal);
            if (i != i0 && i != i1) {
                hi = std::max(hi, area[i]);
                lo = std::min(lo, area[i]);
            }
        }
        int i2 = -1, i3 = -1;
        if (hi > kTie && lo < -kTie) {  // points on both sides of the line: the largest triangle on each side
            for (int i = 0; i < m && i2 < 0; ++i)
                if (i != i0 && i != i1 && area[i] >= hi - kTie) i2 = i;
            for (int i = 0; i < m && i3 < 0; ++i)
                if (i != i0 && i != i1 && area[i] <= lo + kTie) i3 = i;
        } else {  // everything on one side (whichever it is): the two largest triangles
            float first = -1.0f;
            for (int i = 0; i < m; ++i)
                if (i != i0 && i != i1) first = std::max(first, std::fabs(area[i]));
            for (int i = 0; i < m && i2 < 0; ++i)
                if (i != i0 && i != i1 && std::fabs(area[i]) >= first - kTie) i2 = i;
            float second = -1.0f;
            for (int i = 0; i < m; ++i)
                if (i != i0 && i != i1 && i != i2) second = std::max(second, std::fabs(area[i]));
            for (int i = 0; i < m && i3 < 0; ++i)
                if (i != i0 && i != i1 && i != i2 && std::fabs(area[i]) >= second - kTie) i3 = i;
        }
        sel[count++] = i0;
        sel[count++] = i2;
        sel[count++] = i1;
        if (i3 >= 0) sel[count++] = i3;
    }
    c.n = count;
    c.point = {};
    for (int i = 0; i < count; ++i) {
        c.pts[i] = p[sel[i]];
        c.depths[i] = d[sel[i]];
        c.ids[i] = id[sel[i]];
        c.point += c.pts[i];
    }
    c.point = c.point / float(std::max(count, 1));
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
            if (o < best) {
                best = o;
                axis = i;
            }
        }
        c.depth = best;
        c.normal = {};
        c.normal[axis] = d[axis] >= 0.0f ? 1.0f : -1.0f;
        Vec3 lo = max(a.center - a.half, b.center - b.half), hi = min(a.center + a.half, b.center + b.half);
        c.point = (lo + hi) * 0.5f;
        c.hit = true;
        if (manifold) {  // the four corners of the overlap rectangle, on the plane half way through the overlap
            const int i = (axis + 1) % 3, j = (axis + 2) % 3;
            Vec3 pts[4];
            float depths[4];
            std::uint32_t ids[4];
            int m = 0;
            for (int si = 0; si < 2; ++si) {
                for (int sj = 0; sj < 2; ++sj) {
                    Vec3 p;
                    p[axis] = (lo[axis] + hi[axis]) * 0.5f;
                    p[i] = si ? hi[i] : lo[i];
                    p[j] = sj ? hi[j] : lo[j];
                    pts[m] = p;
                    depths[m] = best;
                    ids[m] = mix_id(std::uint32_t(axis * 2 + (d[axis] >= 0.0f ? 1 : 0)), 0x10u + std::uint32_t(si * 2 + sj));
                    ++m;
                }
            }
            reduce_manifold(c, pts, depths, ids, m);
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
    if (moverSpin != Vec3{}) {
        mlo = mover.center - Vec3{bound_radius(mover)};
        mhi = mover.center + Vec3{bound_radius(mover)};
    }
    if (targetSpin != Vec3{}) {
        tlo = target.center - Vec3{bound_radius(target)};
        thi = target.center + Vec3{bound_radius(target)};
    }
    const Vec3 slo = min(mlo, mlo + disp), shi = max(mhi, mhi + disp);  // broad phase: swept bounds vs target bounds
    if (slo.x > thi.x || shi.x < tlo.x || slo.y > thi.y || shi.y < tlo.y || slo.z > thi.z || shi.z < tlo.z)
        return false;
    const float extent = 2.0f * min_half_extent(mover);
    const float steps = std::min(std::ceil(travel / (0.5f * extent)), 100000.0f);
    const int n = std::max(int(steps), 1);
    const Vec3 from = mover.center;
    const Vec3 moverAx[3] = {mover.ax[0], mover.ax[1], mover.ax[2]},
               targetAx[3] = {target.ax[0], target.ax[1], target.ax[2]};
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
        if (c0.hit && c0.depth > kTouchSkin)
            overlapping = true;
        else if (c0.hit)
            limit = c0.depth + kTouchGain;
    }
    if (!overlapping) {
        float lo = 0.0f;
        for (int i = 1; i <= n && !found; ++i) {
            const float t = float(i) / float(n);
            if (!overlaps(t)) {
                lo = t;
                continue;
            }
            float hi = t;
            for (int k = 0; k < 32 && (hi - lo) * travel > kSweepTol; ++k) {
                const float mid = 0.5f * (lo + hi);
                if (overlaps(mid))
                    hi = mid;
                else
                    lo = mid;
            }
            tHit = hi;
            found = true;
        }
    }
    mover.center = from;
    for (int i = 0; i < 3; ++i) {
        mover.ax[i] = moverAx[i];
        target.ax[i] = targetAx[i];
    }
    mover.rotated = moverRotated;
    target.rotated = targetRotated;
    return found;
}

void Physics3D::sync(World& world) {
    prune_procedural_shapes(world);
    const std::uint64_t stamp = ++syncCounter_;  // one per sync: two syncs between steps still sweep removed colliders
    std::unordered_set<std::uint64_t> joinTargets;  // bodies another entity's Joint3D is attached to: they turn too
    for (Entity e : world.entities())
        if (const Joint3D* j = world.get<Joint3D>(e); j && !j->connected.is_null())
            joinTargets.insert(j->connected.bits());
    for (Entity e : world.entities()) {
        RigidBody3D* rb = world.get<RigidBody3D>(e);
        Collider3D* col = world.get<Collider3D>(e);
        if (col && !col->enabled)
            col = nullptr;  // a disabled collider is as good as absent: no queries, contacts or bake
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
            bp_.destroy(bodies_[it->second].proxy);
            ++layoutGen_;
            bodies_[it->second] = Body{};  // entity slot reused after World::clear(): start fresh
            bodies_[it->second].seq = nextSeq_++;
            bodies_[it->second].e = e;
            bodies_[it->second].id = world.id_of(e);
            bodies_[it->second].lastPos = pose.position + Vec3{1e9f, 0, 0};  // force initial placement below
            awakeStale_ = true;
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
            awakeStale_ = true;
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
                    "entity '{}' has a Collider3D with shape \"mesh\" on a {} RigidBody3D. Triangle meshes are only "
                    "for "
                    "static level geometry (a moving body has no inside to push out of). Use shape \"convex\" for a "
                    "moving body, or build it from several boxes/capsules, or set the RigidBody3D type to static.",
                    world.id_of(e), rb->type == BodyType::Dynamic ? "dynamic" : "kinematic");
            else if (col->shape == ColliderShape3D::Convex || col->shape == ColliderShape3D::Mesh) {
                std::string why;
                shapeData = shape_data(world, col->mesh, col->shape == ColliderShape3D::Mesh, why);
                if (!shapeData)
                    problem = std::format("entity '{}': Collider3D shape \"{}\": {}", world.id_of(e),
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
            if (cc)
                kind = Body::Kind::Capsule;
            else
                switch (col->shape) {
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
                    b.carriedByPlatforms = cc->carriedByPlatforms;
                    b.applyWeight = cc->applyWeight;
                    b.charMass = std::max(cc->mass, 0.0f);
                    b.pushStrength = std::max(cc->pushStrength, 0.0f);
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
                const bool keep = b.rotDyn && tr && tr->rotation == b.lastEuler && world.parent(e).is_null();
                if (!keep) {
                    b.orient = quat_of(pose.axis);
                    b.lastEuler = tr ? tr->rotation : Vec3{};
                }
                axes_of(b.orient, ownAx);
                r = ownAx;
                // The solid's own moments about its three axes. A capsule is a cylinder plus two hemispheres, a convex hull
                // is integrated over its tetrahedra (about the model origin, products of inertia ignored). A box, a sphere
                // (2/5 m r^2) and a hull whose model is missing or flat keep the closed forms below.
                Vec3 shaped;
                if (kind == Body::Kind::Capsule) {
                    shaped = detail::capsule_inertia(b.mass, b.radius, b.segHalf);
                    b.invI = {1.0f / shaped.x, 1.0f / shaped.y, 1.0f / shaped.z};
                } else if (kind == Body::Kind::Convex && b.data &&
                           detail::hull_inertia(b.mass, *b.data, b.gscale, shaped)) {
                    b.invI = {1.0f / shaped.x, 1.0f / shaped.y, 1.0f / shaped.z};
                } else {
                    const float m = b.mass, hx2 = b.half.x * b.half.x, hy2 = b.half.y * b.half.y,
                                hz2 = b.half.z * b.half.z;
                    if (kind != Body::Kind::Sphere)
                        b.invI = {3.0f / (m * (hy2 + hz2)), 3.0f / (m * (hx2 + hz2)), 3.0f / (m * (hx2 + hy2))};
                    else
                        b.invI = Vec3{2.5f / (m * b.radius * b.radius)};  // solid sphere: I = 2/5 m r^2
                }
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
            b.navObstacle = !cc && col->navObstacle;
            b.navWalkable = !cc && col->navWalkable;
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
            b.navObstacle = false;
            b.navWalkable = false;
            b.data = nullptr;
            for (int i = 0; i < 3; ++i) b.rot[i] = pose.axis[i];
        }
        b.rollMu = (rb && usable && rb->type == BodyType::Dynamic && rb->rollWithMotion && b.kind == Body::Kind::Sphere)
                       ? std::max(rb->rollingFriction, 0.0f)
                       : -1.0f;
        if (b.offset != oldOffset) {  // offset edited, or turned/scaled with the entity: the shape follows the origin
            b.center += b.offset - oldOffset;
            b.lastCenter += b.offset - oldOffset;
            b.boxStale = true;
        }
        b.enabled = world.active_in_hierarchy(e);
        if (!b.enabled) b.force = {};  // (the step clears the force of the awake bodies only: none piles up while disabled)
        if (!existed) b.moved = true;  // a new body wakes what it appears in, like a teleported one
        // Sleeping bodies must follow everything gameplay does to them or to what they rest on: a changed body or collider
        // (including enabling and disabling) and a teleport wake the body and the bodies touching it; a written velocity
        // wakes the body's group.
        if (existed && b.sig() != before) {
            awakeStale_ = true;  // (its type or enabled flag may have changed)
            wake(b);
            wake_touching(b.seq);
            b.boxStale = true;
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
            b.boxStale = true;
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
    for (Body& b : bodies_)
        if (b.seen != stamp || !live(world, b.e)) {
            any = true;
            wake_touching(b.seq);
            bp_.destroy(b.proxy);
            b.proxy = Broadphase3D::kNone;
        }
    if (any) {
        std::vector<Body> kept;
        kept.reserve(bodies_.size());
        for (Body& b : bodies_)
            if (b.seen == stamp && live(world, b.e)) kept.push_back(std::move(b));
        bodies_ = std::move(kept);
        ++layoutGen_;
        awakeStale_ = true;
        index_.clear();
        for (std::size_t i = 0; i < bodies_.size(); ++i) index_[bodies_[i].e.bits()] = i;
    }
    sync_joints(world, stamp);
}

// One broad-phase leaf per enabled body with a shape (created, or removed when the body lost its shape or was disabled)
// and the payloads renumbered: the bodies shift when one is destroyed. A new leaf starts with its current bounds.
void Physics3D::bp_reconcile() {
    for (std::size_t i = 0; i < bodies_.size(); ++i) {
        Body& b = bodies_[i];
        const bool want = b.enabled && b.hasShape;
        if (want && b.proxy < 0) {
            b.proxy = bp_.create(Broadphase3D::make_fat(tight_box(b), kFatMarginStill, Vec3{}), std::uint32_t(i));
        } else if (!want && b.proxy >= 0) {
            bp_.destroy(b.proxy);
            b.proxy = Broadphase3D::kNone;
        } else if (b.proxy >= 0) {
            bp_.set_payload(b.proxy, std::uint32_t(i));
        }
    }
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

void Physics3D::turn_by(Body& b, Vec3 radians) {
    if (!(length_sq(radians) > 0.0f)) return;
    b.orient = turned(b.orient, radians, 1.0f);
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
        p.id = c.n > 0 ? c.ids[i] : 0u;
        p.ra = pos - a.center;
        p.rb = pos - b.center;
        p.la = world_to_frame(a.rot, p.ra);
        p.lb = world_to_frame(b.rot, p.rb);
        const Vec3 rna = cross(p.ra, c.normal), rnb = cross(p.rb, c.normal);
        p.kn = a.invMass + b.invMass + dot(rna, inv_inertia_mul(a, rna)) + dot(rnb, inv_inertia_mul(b, rnb));
        const float vn = dot(point_velocity(b, p.rb) - point_velocity(a, p.ra), c.normal);
        if (vn < 0.0f) impact = std::max(impact, -vn);
        p.target = (e > 0.0f && -vn >= kBounceThreshold) ? -e * vn : std::min(p.depth, 0.0f) / h;
        p.jn = 0.0f;
        p.jt = {};
    }
    // The points of a manifold are solved together (all from the same velocities, then applied at once), so that the
    // result does not depend on the order they are listed in: a box lying flat on another presses on its four corners
    // alike, and a stack of them does not lean to the side the first corner is on. Applying every point's full update
    // would overshoot (the points share the two bodies), so each update is scaled by 1 / (the largest sum of a row of the
    // points' coupling matrix K, in units of its diagonal): Gershgorin's bound, which makes the iteration converge.
    rc.omega = 1.0f;
    if (rc.count > 1) {
        Vec3 rna[kMaxPts], rnb[kMaxPts];
        for (int i = 0; i < rc.count; ++i) {
            rna[i] = inv_inertia_mul(a, cross(rc.pt[i].ra, c.normal));
            rnb[i] = inv_inertia_mul(b, cross(rc.pt[i].rb, c.normal));
        }
        float worst = 1.0f;
        for (int i = 0; i < rc.count; ++i) {
            float row = 0.0f;
            for (int j = 0; j < rc.count; ++j) {
                const float k = (i == j) ? rc.pt[i].kn
                                         : a.invMass + b.invMass + dot(cross(rc.pt[i].ra, c.normal), rna[j]) +
                                               dot(cross(rc.pt[i].rb, c.normal), rnb[j]);
                row += std::fabs(k);
            }
            worst = std::max(worst, row / rc.pt[i].kn);
        }
        rc.omega = 1.0f / worst;
    }
    return true;
}

// One velocity pass over a manifold, all its points together (see build_rigid_contact). Friction first (a cone of mu times
// the point's accumulated normal impulse), then the normal impulses, accumulated and clamped at zero.
// mode 0: every constraint rigid (a time-of-impact stop). mode 1: the normal constraints are soft and push a penetration
// out at up to kPushOut m/s (before the sub-step's motion, which turns that speed into a position change). mode 2: the
// relax pass after the motion: the same constraints without the push-out, so that speed is taken out again.
void Physics3D::solve_manifold(std::vector<Body>& bodies, RigidContact& rc, int mode, float h, const Soft& soft,
                               const Soft& softStatic) {
    Body& a = bodies[rc.ia];
    Body& b = bodies[rc.ib];
    const float ia = a.invMass, ib = b.invMass;
    const Vec3 n = rc.n;
    const float omega = rc.omega;
    const Soft& sf = (ia == 0.0f || ib == 0.0f) ? softStatic : soft;
    Vec3 forceB{}, torqueA{}, torqueB{};  // what a pass applies to b (a gets the opposite force)
    auto gather = [&](Vec3 ra, Vec3 rb, Vec3 impulse) {
        forceB += impulse;
        torqueA += cross(ra, impulse);
        torqueB += cross(rb, impulse);
    };
    auto apply = [&]() {
        b.vel += forceB * ib;
        b.angVel += inv_inertia_mul(b, torqueB) * kRadToDeg;
        a.vel -= forceB * ia;
        a.angVel -= inv_inertia_mul(a, torqueA) * kRadToDeg;
        forceB = {};
        torqueA = {};
        torqueB = {};
    };
    for (int i = 0; i < rc.count; ++i) {
        RigidContact::Pt& p = rc.pt[i];
        const Vec3 va = point_velocity(a, p.ra), vb = point_velocity(b, p.rb);
        // A carried rider already moved with its platform: friction acts on the rider's own velocity.
        const Vec3 rv = rc.carrier == 1 ? vb : (rc.carrier == 2 ? -va : vb - va);
        const Vec3 vt = rv - n * dot(rv, n);
        const float lt = length(vt);
        if (lt <= 1e-6f) continue;
        const Vec3 t = vt / lt;
        const Vec3 rta = cross(p.ra, t), rtb = cross(p.rb, t);
        const float kt = ia + ib + dot(rta, inv_inertia_mul(a, rta)) + dot(rtb, inv_inertia_mul(b, rtb));
        Vec3 total = p.jt - t * (omega * lt / kt);
        const float limit = rc.mu * p.jn, len = length(total);
        if (len > limit) total = total * (limit / len);
        gather(p.ra, p.rb, total - p.jt);
        p.jt = total;
    }
    apply();
    for (int i = 0; i < rc.count; ++i) {
        RigidContact::Pt& p = rc.pt[i];
        const float vn = dot(point_velocity(b, p.rb) - point_velocity(a, p.ra), n);
        float next;
        if (mode == 0 || p.target > 0.0f) {  // rigid: aim for the speed the restitution gives (zero when there is none)
            next = p.jn + omega * (p.target - vn) / p.kn;
        } else {
            // The penetration now: what the build measured, less what the bodies have moved apart along n since.
            const Vec3 rA = frame_to_world(a.rot, p.la), rB = frame_to_world(b.rot, p.lb);
            const float sep = dot((b.center + rB) - (a.center + rA), n) - p.depth;  // < 0: penetrating
            float bias = 0.0f, massScale = 1.0f, impulseScale = 0.0f;
            if (sep > 0.0f) {  // still apart: it may close exactly the gap
                bias = sep / h;
            } else if (mode == 1) {
                bias = std::max(sf.biasRate * std::min(sep + kSlop, 0.0f), -kPushOut);
                massScale = sf.massScale;
                impulseScale = sf.impulseScale;
            }
            next = p.jn - omega * (massScale * (vn + bias) / p.kn + impulseScale * p.jn);
        }
        next = std::max(next, 0.0f);
        gather(p.ra, p.rb, n * (next - p.jn));
        p.jn = next;
    }
    apply();
}

Physics3D::Soft Physics3D::make_soft(float hertz, float dampingRatio, float h) {
    Soft s;
    const float omega = 2.0f * 3.14159265f * hertz;
    const float a1 = 2.0f * dampingRatio + h * omega;
    const float a2 = h * omega * a1;
    const float a3 = 1.0f / (1.0f + a2);
    s.biasRate = omega / a1;
    s.massScale = a2 * a3;
    s.impulseScale = a3;
    return s;
}

// Pushes the pair apart at every manifold point whose penetration exceeds kSlop, along the normal and by the impulse the
// point's lever arms allow (so a tilted box is also turned back flat, which the velocity pass cannot do: it aims for
// zero closing speed, not for the depth). Each point's depth is kept up to date from the bodies' motion since the build
// (its anchors live in each body's frame), and a pass moves a point by at most kMaxCorrection.
void Physics3D::correct_position(std::vector<Body>& bodies, const RigidContact& rc) {
    Body& a = bodies[rc.ia];
    Body& b = bodies[rc.ib];
    const Vec3 n = rc.n;
    for (int i = 0; i < rc.count; ++i) {
        const RigidContact::Pt& p = rc.pt[i];
        const Vec3 rA = frame_to_world(a.rot, p.la), rB = frame_to_world(b.rot, p.lb);
        // Both bodies' copies of the point coincided at the build: what they have moved apart along n shrinks the depth.
        const float depth = p.depth - dot((b.center + rB) - (a.center + rA), n);
        if (depth <= kSlop) continue;
        const Vec3 rna = cross(rA, n), rnb = cross(rB, n);
        const float k = a.invMass + b.invMass + dot(rna, inv_inertia_mul(a, rna)) + dot(rnb, inv_inertia_mul(b, rnb));
        if (!(k > 0.0f)) continue;
        const Vec3 impulse = n * (std::min((depth - kSlop) * kPercent, kMaxCorrection) / k);
        a.center -= impulse * a.invMass;
        turn_by(a, inv_inertia_mul(a, cross(rA, -impulse)));
        b.center += impulse * b.invMass;
        turn_by(b, inv_inertia_mul(b, cross(rB, impulse)));
    }
}

std::vector<StartOverlap> Physics3D::start_overlaps(World& world, bool onlyNew) {
    std::vector<StartOverlap> out;
    for (Body& a : bodies_) {
        if (onlyNew && a.startChecked) continue;
        a.startChecked = true;
        if (!a.enabled || a.type != BodyType::Dynamic || !a.hasShape || a.trigger) continue;
        const Body* worst = nullptr;
        float depth = kStartOverlap;
        for (const Body& s : bodies_) {
            if (s.type != BodyType::Static || !s.enabled || !s.hasShape || s.trigger || !filters_pass(a, s)) continue;
            if (std::find(a.noCollide.begin(), a.noCollide.end(), s.seq) != a.noCollide.end()) continue;
            const Contact c = collide(a, s, 0.0f);
            if (c.hit && c.depth > depth) {
                depth = c.depth;
                worst = &s;
            }
        }
        if (!worst) continue;
        StartOverlap o;
        o.body = a.e;
        o.collider = worst->e;
        o.depth = depth;
        o.message = std::format("dynamic body '{}' starts inside the static collider of '{}' by {:.2f} m, so the first "
                                "physics step pushes it "
                                "out (a joint chain can buckle or ring from that). Move it at least {:.2f} m clear of "
                                "'{}', shrink one of the "
                                "two colliders, or make one of them a trigger.",
                                world.id_of(a.e), world.id_of(worst->e), depth, depth, world.id_of(worst->e));
        out.push_back(std::move(o));
    }
    return out;
}

void Physics3D::step(World& world, float dt) {
    if (lastWorld_ != &world) {
        reset();
        lastWorld_ = &world;
    }
    ++stepCounter_;
    lastDt_ = dt;
    sync(world);
    bp_reconcile();
    const std::size_t n = bodies_.size();
    if (n == 0) {
        touching_.clear();
        frozen_.clear();
        return;
    }
    // One pass over the bodies: the short lists the stages below walk instead of every body (the sleeping ones and the
    // static ones are in none of the lists that drive the pair scans, the integration and the write back).
    Rows& R = rows_;
    R.moved.clear();
    R.movedStatic.clear();
    R.stale.clear();
    R.platforms.clear();
    R.characters.clear();
    R.anyUnchecked = false;
    for (std::size_t i = 0; i < n; ++i) {
        const Body& b = bodies_[i];
        if (!b.startChecked) R.anyUnchecked = true;
        if (b.moved) {
            R.moved.push_back(i);
            if (b.enabled && b.type == BodyType::Static) R.movedStatic.push_back(i);
        }
        if (b.boxStale) R.stale.push_back(i);
        if (b.character && b.enabled) R.characters.push_back(i);
        if (b.type == BodyType::Kinematic && !b.character && (b.vel != Vec3{} || b.angVel != Vec3{}))
            R.platforms.push_back(i);
    }
    // A dynamic body that starts inside a static collider is reported once, the first step it exists.
    if (R.anyUnchecked)
        for (const StartOverlap& o : start_overlaps(world, true)) FA_WARN("physics", "{}", o.message);
    for (const std::size_t i : R.characters) {  // characters with a velocity walk first, so what they push moves this step
        const CharacterController3D* cc = world.get<CharacterController3D>(bodies_[i].e);
        if (!cc || cc->velocity == Vec3{}) continue;
        move_character_body(world, bodies_[i], cc->velocity * dt);
    }
    const Vec3 g = world.settings().gravity3D;
    if (g != lastGravity_) {  // a body asleep on the old gravity would hover on the new one
        lastGravity_ = g;
        for (Body& b : bodies_) wake(b);
    }
    // Joints seen from the bodies: which bodies a chain links (islands for sleeping and for the solver's iterations).
    struct JointLink {
        std::size_t a, b;
        bool motor;
    };
    std::vector<JointLink> jlinks;
    for (const JointState* jp : jointOrder_) {
        if (!jp->active) continue;
        auto ia = index_.find(jp->e.bits());
        if (ia == index_.end()) continue;
        std::size_t ib = kNoBody;
        if (jp->seqB != 0) {
            auto it = index_.find(jp->conn.bits());
            if (it == index_.end()) continue;
            ib = it->second;
        }
        jlinks.push_back({ia->second, ib, jp->useMotor});
    }
    if (!jlinks.empty() || chainsMarked_) {  // a chain of three or more jointed dynamic bodies gets more solver
                                             // iterations (a rope bridge settles); without joints nothing to reset
        chainsMarked_ = false;
        UnionFind chains(n);
        std::vector<int> size(n, 0);
        auto dyn = [&](std::size_t i) { return i != kNoBody && bodies_[i].type == BodyType::Dynamic; };
        for (const JointLink& l : jlinks)
            if (dyn(l.a) && dyn(l.b)) chains.unite(l.a, l.b);
        std::vector<char> inJoint(n, 0);
        for (const JointLink& l : jlinks) {
            inJoint[l.a] = 1;
            if (l.b != kNoBody) inJoint[l.b] = 1;
        }
        for (std::size_t i = 0; i < n; ++i) {
            bodies_[i].iterations = kRigidIterations;
            bodies_[i].chainDrag = 0.0f;
            if (inJoint[i] && dyn(i)) ++size[chains.find(i)];
        }
        for (std::size_t i = 0; i < n; ++i)
            if (dyn(i) && size[chains.find(i)] >= 3) {
                bodies_[i].iterations = kChainIterations;
                bodies_[i].chainDrag = kChainDrag;
                chainsMarked_ = true;
            }
    }
    const int subs = std::max(settings_.subSteps, 1);
    const float h = dt / float(subs);
    impacts_.clear();
    std::vector<char> charCarried(n, 0);  // per character: already carried by a platform this sub-step
    std::vector<int> carrier(n, -1);      // per body: index of the kinematic body carrying it this sub-step

    // Keeps the fat box of body i around the box `need` (the tree is written only when it no longer contains it).
    auto cover_one = [&](std::size_t i, const Aabb3& need) {
        const Body& b = bodies_[i];
        if (b.proxy < 0) return;
        const bool moving = b.type != BodyType::Static && !b.asleep;
        bp_.cover(b.proxy, need, moving ? kFatMarginMoving : kFatMarginStill,
                  moving ? b.vel * (dt * kFatStretchSteps) : Vec3{}, false);
    };
    // The characters a platform can carry (fixed for the step), so looking for the ones on a platform is not a scan of
    // every body.
    std::vector<std::size_t> carriable;
    for (const std::size_t i : R.characters)
        if (bodies_[i].carriedByPlatforms) carriable.push_back(i);
    // Dynamic bodies resting on top of body k (k at its current center, optionally shifted): the tree gives the bodies near
    // k, ascending. A body that was moved since its fat box was last covered is covered by whoever moved it.
    auto find_riders = [&](std::size_t k, std::vector<std::size_t>& out) {
        const Body& p = bodies_[k];
        if (!p.enabled || !p.hasShape || p.trigger) return;
        thread_local std::vector<std::uint32_t> near;
        bp_.sorted_query(aabb_grow(tight_box(p), kRiderGap + kBpEps), near);
        for (const std::uint32_t i : near) {
            const Body& d = bodies_[i];
            if (i == k || d.type != BodyType::Dynamic || !d.enabled || !d.hasShape || d.trigger) continue;
            if (!filters_pass(p, d)) continue;
            Contact c = collide(p, d, kRiderGap);
            if (c.hit && c.normal.y > 0.7f) out.push_back(i);
        }
    };
    // Characters standing on top of body k (a capsule rests a skin above the surface, so the gap is the controller's
    // own: skin + the ground probe, 0.06 m at the default skin).
    auto find_characters = [&](std::size_t k, std::vector<std::size_t>& out) {
        const Body& p = bodies_[k];
        if (!p.enabled || !p.hasShape || p.trigger || p.character) return;
        for (const std::size_t i : carriable) {
            const Body& c = bodies_[i];
            if (!filters_pass(p, c)) continue;
            const Contact ct = collide(p, c, c.skin + 0.04f);
            if (ct.hit && ct.normal.y > 0.7f) out.push_back(i);
        }
    };
    // Teleported static/kinematic bodies carry their riders by the same displacement (detected at the old pose).
    for (const std::size_t k : R.moved) {  // (a body is only teleported by a sync that also set its `moved`)
        Body& p = bodies_[k];
        if (p.pendingCarry == Vec3{}) continue;
        Vec3 dp = p.pendingCarry;
        p.pendingCarry = {};
        std::vector<std::size_t> riders;
        p.center -= dp;
        find_riders(k, riders);
        find_characters(k, riders);
        p.center += dp;
        for (std::size_t i : riders) {
            wake(bodies_[i]);
            bodies_[i].center += dp;
            cover_one(i, tight_box(bodies_[i]));
        }
    }

    auto movable = [](const Body& b) { return b.type != BodyType::Static; };
    auto live_dyn = [](const Body& b) { return b.type == BodyType::Dynamic && !b.asleep; };
    std::vector<std::size_t> riders;
    std::vector<Vec3> disp(n);
    std::vector<RigidContact> rigid;

    // The bodies a stage works on. Everything, or one island during the time-of-impact events (see the sub-step loop):
    // the pairs visited are those with at least one body in scope, always as (lower index, higher index).
    // No scope (null) = the whole world, whose rows are the awake bodies (rows_.awake: a sleeping or static body asks the
    // broad phase nothing; the pairs it is in are found from the awake body's row).
    std::vector<char> inScope(n, 0);  // (read only while a stage is scoped to an island)
    const std::vector<std::size_t>* scope = nullptr;
    std::uint64_t rowsGen = 1;  // changes whenever the awake list is rebuilt
    auto ensure_awake = [&]() {  // the awake list of the world, rebuilt after a body woke up
        if (!awakeStale_) return;
        awakeStale_ = false;
        ++rowsGen;
        R.awake.clear();
        R.isAwake.assign(n, 0);
        R.bigAsleep.clear();
        R.maxAsleepReach = 0.0f;
        R.anyAsleep = false;
        for (std::size_t i = 0; i < n; ++i) {
            const Body& b = bodies_[i];
            if (b.asleep) {
                R.anyAsleep = true;
                if (b.hasShape && !b.trigger) {  // (the island search treats it like an awake body at rest: reach = radius)
                    const float reach = bound_radius(b);
                    if (b.proxy < 0 || reach > kSmallReach || !aabb_contains(tight_box(b), Aabb3{b.center, b.center}))
                        R.bigAsleep.push_back(i);
                    else
                        R.maxAsleepReach = std::max(R.maxAsleepReach, reach);
                }
            }
            if (b.enabled && b.type != BodyType::Static && !b.asleep) {
                R.awake.push_back(i);
                R.isAwake[i] = 1;
            }
        }
    };
    auto rows_of = [&]() -> const std::vector<std::size_t>& {  // the rows of the current scope
        if (scope) return *scope;
        ensure_awake();
        return R.awake;
    };
    // ---- broad phase (broadphase3d.h). Every phase that looks for pairs first makes each body's fat box contain the box the
    // phase asks about (cover), then asks the tree row by row: the partners of body i are the bodies whose fat box overlaps
    // the box of i grown by the phase's reach, ascending, which is exactly the order the old all-pairs loop visited them in
    // (a body the tree does not return is further than the phase's reach, so the narrow phase would have said no).
    // Only the bodies that can have moved (the rows of the scope): a sleeping or static body keeps the box it was covered with
    // (a body gameplay changed is covered once by cover_stale, a body that falls asleep gets its box tightened then).
    auto cover = [&](auto&& need, bool tighten = false) {  // need(i, body): the box of body i this phase asks about
        for (const std::size_t i : rows_of()) {
            const Body& b = bodies_[i];
            if (b.proxy < 0) continue;
            const bool moving = b.type != BodyType::Static && !b.asleep;
            bp_.cover(b.proxy, need(i, b), moving ? kFatMarginMoving : kFatMarginStill,
                      moving ? b.vel * (dt * kFatStretchSteps) : Vec3{}, tighten);
        }
    };
    auto cover_stale = [&]() {  // the bodies sync changed (moved, resized, enabled...): their box in the tree is made anew
        for (const std::size_t i : R.stale) {
            Body& b = bodies_[i];
            b.boxStale = false;
            if (b.proxy < 0) continue;
            const bool moving = b.type != BodyType::Static && !b.asleep;
            bp_.cover(b.proxy, tight_box(b), moving ? kFatMarginMoving : kFatMarginStill,
                      moving ? b.vel * (dt * kFatStretchSteps) : Vec3{}, true);
        }
        R.stale.clear();
    };
    auto cover_tight = [&](bool tighten = false) {
        cover([](std::size_t, const Body& b) { return tight_box(b); }, tighten);
    };
    // The partners of row i (indices, ascending, at least `from`): the tree's answer for `q`, filtered like the pair loop
    // was. Without a scope the rows are the awake bodies. Plain: every pair is visited from its lower body, so a row sees
    // the partners above it. low: a row sees every partner except the awake ones below it (those rows see it), so the pairs
    // of an awake body with a sleeping or static body below it are found from the awake body (the caller puts the pairs
    // back in (lower, higher) order: replay_sorted). Inside an island's scope a pair is visited from its member (from the
    // lower one when both are members), and another island's movers cannot touch it this sub-step.
    auto collect = [&](std::size_t i, const Aabb3& q, std::size_t from, std::vector<std::uint32_t>& out,
                       bool low = false) {
        out.clear();
        if (bodies_[i].proxy < 0) return;
        bp_.sorted_query(q, out);
        if (!scope) {
            if (low) {
                FA_ASSERT(!awakeStale_, "the awake list is rebuilt before a scan");  // (this runs on the job threads)
                out.erase(std::remove_if(out.begin(), out.end(),
                                         [&](std::uint32_t k) { return k == i || (k < i && R.isAwake[k]); }),
                          out.end());
                return;
            }
            const std::uint32_t lo = std::uint32_t(std::max(from, i + 1));
            out.erase(out.begin(), std::lower_bound(out.begin(), out.end(), lo));
            return;
        }
        out.erase(std::remove_if(out.begin(), out.end(),
                                 [&](std::uint32_t k) {
                                     if (k < from || k == i) return true;
                                     return inScope[k] ? k < i : (movable(bodies_[k]) && !bodies_[k].asleep);
                                 }),
                  out.end());
    };
    auto for_row = [&](std::size_t i, const Aabb3& q,
                       auto&& fn) {  // the pairs of row i, in order (reads the bodies only)
        thread_local std::vector<std::uint32_t> cand;
        collect(i, q, 0, cand, true);
        for (std::uint32_t k : cand) fn(std::min<std::size_t>(i, k), std::max<std::size_t>(i, k));
    };
    auto for_pairs = [&](auto&& boxOf, auto&& fn) {  // boxOf(i): what row i asks about
        for (std::size_t i : rows_of()) for_row(i, boxOf(i), fn);
    };
    // The records of a pair scan (each has i < k and `low`: found from its higher body) in (i, k) order: the ones found from
    // their lower body come in order already, the others are sorted and merged in. The order is the one a scan of every body
    // as a row visits the pairs in, whatever the number of sleeping or static bodies.
    auto replay_sorted = [&](auto& parts, auto&& fn) {
        using Rec = typename std::decay_t<decltype(parts)>::value_type::value_type;
        std::vector<Rec*> lows;
        for (auto& part : parts)
            for (Rec& r : part)
                if (r.low) lows.push_back(&r);
        auto before = [](const Rec* a, const Rec* b) { return a->i != b->i ? a->i < b->i : a->k < b->k; };
        std::sort(lows.begin(), lows.end(), [&](const Rec* a, const Rec* b) { return before(a, b); });
        std::size_t li = 0;
        for (auto& part : parts)
            for (Rec& r : part) {
                if (r.low) continue;
                while (li < lows.size() && before(lows[li], &r)) fn(*lows[li++]);
                fn(r);
            }
        while (li < lows.size()) fn(*lows[li++]);
    };
    // Like for_pairs, for a loop whose callback moves the two bodies of the pair (the contact solver's position pass): a
    // body that leaves its fat box is put back in the tree at once, and a row whose body was pushed out of the box it asked
    // about asks again for the partners it has not reached yet. The callback order matters (the passes are Gauss-Seidel),
    // so the rows are visited in index order: a pair is visited from its lower body, and a sleeping or static body below
    // an awake one is a row too, when the awake body is near it. Only bodies without rotation dynamics pair here.
    std::vector<std::uint32_t> liveRow;
    std::vector<std::size_t> liveRows, liveExtra;
    std::uint64_t liveExtraWrites = ~std::uint64_t(0), liveExtraRows = 0;  // what `liveExtra` was computed for
    // The partners of a row of for_pairs_live. An extra row (a sleeping or static body below an awake one) only has work with
    // a dynamic body that is awake (the callback does nothing for two bodies that are not), so its partners are those:
    // found among the awake list when it is short (a floor box covering a big sleeping pile would otherwise answer the
    // whole pile on every call), else from the tree and filtered. The partners, and their order, are those of a plain row
    // without the ones whose pair does nothing.
    auto live_collect = [&](std::size_t i, const Aabb3& q, std::size_t from) {
        if (scope || R.isAwake[i]) {
            collect(i, q, from, liveRow);
            return;
        }
        liveRow.clear();
        if (bodies_[i].proxy < 0) return;
        const std::size_t lo = std::max(from, i + 1);
        constexpr std::size_t kBruteRows = 64;
        if (R.awake.size() <= kBruteRows) {
            for (const std::size_t j : R.awake) {
                const Body& o = bodies_[j];
                if (j >= lo && o.proxy >= 0 && live_dyn(o) && aabb_overlap(bp_.fat(o.proxy), q))
                    liveRow.push_back(std::uint32_t(j));
            }
            return;
        }
        collect(i, q, from, liveRow);
        liveRow.erase(std::remove_if(liveRow.begin(), liveRow.end(),
                                     [&](std::uint32_t j) { return !live_dyn(bodies_[j]); }),
                      liveRow.end());
    };
    auto for_pairs_live = [&](auto&& fn) {
        constexpr float kPad = 0.05f;
        liveRows.clear();
        for (const std::size_t i : rows_of())
            if (!bodies_[i].rotDyn) liveRows.push_back(i);
        if (liveRows.empty()) return;
        if (!scope) {
            // The extra rows only depend on the fat boxes (and on which bodies are awake), so they are asked for again
            // only when a box was written to the tree since.
            if (liveExtraWrites != bp_.writes() || liveExtraRows != rowsGen) {
                liveExtraWrites = bp_.writes();
                liveExtraRows = rowsGen;
                liveExtra.clear();
                for (const std::size_t i : liveRows) {
                    const int proxy = bodies_[i].proxy;
                    if (proxy < 0) continue;
                    bp_.query(aabb_grow(bp_.fat(proxy), kPad + kBpEps), [&](std::uint32_t k) {
                        if (k < i && !R.isAwake[k] && !bodies_[k].rotDyn) liveExtra.push_back(k);
                    });
                }
                std::sort(liveExtra.begin(), liveExtra.end());
                liveExtra.erase(std::unique(liveExtra.begin(), liveExtra.end()), liveExtra.end());
            }
            if (!liveExtra.empty()) {
                const std::size_t mid = liveRows.size();
                liveRows.insert(liveRows.end(), liveExtra.begin(), liveExtra.end());
                std::inplace_merge(liveRows.begin(), liveRows.begin() + std::ptrdiff_t(mid), liveRows.end());
            }
        }
        for (std::size_t i : liveRows) {
            if (bodies_[i].proxy < 0) continue;
            Aabb3 q = aabb_grow(tight_box(bodies_[i]), kPad);
            live_collect(i, q, 0);
            for (std::size_t pos = 0; pos < liveRow.size(); ++pos) {
                const std::size_t k = liveRow[pos];
                fn(std::min(i, k), std::max(i, k));
                const Aabb3 now = tight_box(bodies_[i]);
                cover_one(i, now);
                cover_one(k, tight_box(bodies_[k]));
                if (!aabb_contains(q, now)) {
                    q = aabb_grow(now, kPad);
                    live_collect(i, q, k + 1);
                    pos = std::size_t(-1);
                }
            }
        }
    };
    // The rows (bodies of the scope) of a pair scan split into chunks that depend only on the row count, and run on the job
    // threads when the scan is big enough: rowFn(row index in `rows`, out) appends the records of that row; the parts come
    // back in chunk order, rows in order, so replaying them is the sequential scan. Below the threshold (or without a
    // running pool) it is one part on the calling thread. The scan must only read the bodies (and the tree).
    auto scan_rows = [&](std::size_t rows, auto&& rowFn, auto& parts) {
        parts.clear();
        if (rows >= kMinParallelRows && jobs::running() && !jobs::inline_mode() && jobs::worker_count() > 0) {
            parts.resize(jobs::chunk_count(rows, kPairChunkRows));
            auto r = jobs::parallel_for("physics3d.pairs", rows, kPairChunkRows, [&](const jobs::Chunk& c) {
                for (std::size_t ri = c.begin; ri < c.end; ++ri) rowFn(ri, parts[c.index]);
            });
            if (r.ok()) return;
            FA_ERROR("physics", "3D pair scan on the job threads failed ({}); scanning on the calling thread",
                     r.error().message);
            parts.clear();
        }
        parts.emplace_back();
        for (std::size_t ri = 0; ri < rows; ++ri) rowFn(ri, parts.back());
    };

    // A sleeping body (with its whole group) wakes as soon as something that moves comes within kRiderGap of it: an awake
    // dynamic body, a kinematic body with a velocity, or a body gameplay teleported this step (its new place may overlap).
    auto wake_touched = [&]() {
        ensure_awake();
        if (!R.anyAsleep) return;
        auto visit = [&](std::size_t i) {
            const Body& m = bodies_[i];
            if (!m.enabled || !m.hasShape || m.trigger) return;
            const bool mover =
                live_dyn(m) || (m.type != BodyType::Dynamic && (m.moved || m.vel != Vec3{} || m.angVel != Vec3{}));
            if (!mover) return;
            bp_.query(aabb_grow(tight_box(m), kRiderGap + kBpEps), [&](std::uint32_t k) {
                Body& s = bodies_[k];
                if (!s.asleep || !s.enabled || !s.hasShape || s.trigger || !filters_pass(m, s)) return;
                if (collide(m, s, kRiderGap).hit) wake(s);
            });
        };
        // The rows are the awake bodies of the list as it was when the loop started: a sleeping body that wakes in here is not
        // visited as a mover in this call (the old loop over every body saw one with a higher index at once). It becomes
        // one in the next phase or sub-step, so a chain of sleepers that only touch a woken body's neighbours (not the body
        // itself) wakes one link per phase instead of all at once; the group of a body that wakes does wake together.
        for (const std::size_t i : rows_of()) visit(i);
        if (!scope)  // the static bodies gameplay placed this step
            for (const std::size_t i : R.movedStatic) visit(i);
    };

    // Time of the first impact (fraction of `disp`, 1 = none) among all pairs that close in on each other faster than
    // the smaller body's half extent per sub-step. The pair is swept in relative motion: the smaller body moves by
    // disp[mover] - disp[target] against the other one standing still at its start position, so two fast dynamic bodies
    // and a fast kinematic body against a dynamic one are caught as well as a dynamic body against a static wall.
    // A rotating box also sweeps through the turn it makes within `span` (its far end can travel more than its centre).
    // Pairs that already overlap at the start (deeper than a touch) are left to the contact solver.
    auto first_impact = [&](float span) {
        auto spin_over = [&](const Body& b) {
            return b.kind != Body::Kind::Sphere && b.rotDyn && live_dyn(b) ? b.angVel * (kDegToRad * span)
                                                                           : Vec3{};  // a sphere turns in place
        };
        // Rows ask about the bounds of the whole move (a turning body: its bounding sphere), which is also what sweep() tests
        // first: the swept box of a body vs the box of the other one, moved by the same amount.
        auto swept = [&](std::size_t i, const Body& b) {
            if (!inScope[i]) return tight_box(b);
            Aabb3 t = tight_box(b);
            if (spin_over(b) != Vec3{}) t = {b.center - Vec3{bound_radius(b)}, b.center + Vec3{bound_radius(b)}};
            return Aabb3{min(t.lo, t.lo + disp[i]), max(t.hi, t.hi + disp[i])};
        };
        cover(swept);
        float tFirst = 1.0f;
        for_pairs([&](std::size_t i) { return aabb_grow(swept(i, bodies_[i]), kBpEps); },
                  [&](std::size_t i, std::size_t k) {
                      Body& a = bodies_[i];
                      Body& b = bodies_[k];
                      if (!a.enabled || !a.hasShape || a.trigger || !b.enabled || !b.hasShape || b.trigger) return;
                      const bool dynA = a.type == BodyType::Dynamic, dynB = b.type == BodyType::Dynamic;
                      if ((!dynA && !dynB) || !filters_pass(a, b)) return;
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
                  });
        return tFirst;
    };

    // Resolves the contacts at the current positions. Pairs of rotating boxes (rotDyn) go through the rigid-body solver
    // (manifolds, impulses at the contact points, accumulated and clamped); every other pair keeps the original solver.
    // positional: also push overlapping bodies apart (not at a time-of-impact stop: the overlap there is ~0.1 mm).
    const float contactHertz = kContactHertz;
    const Soft soft = make_soft(contactHertz, kContactDamping, h);
    const Soft softStatic = make_soft(2.0f * contactHertz, kContactDamping, h);
    std::vector<RigidContact> held;  // the contacts of this sub-step, built before its motion and relaxed after it
    // Builds (collision, manifolds, warm start) the contacts of the pairs in scope into `list`.
    auto build_contacts = [&](std::vector<RigidContact>& list, bool positional) {
        cover_tight();  // the bodies moved since the last phase
        wake_touched();
        list.clear();
        struct RigidHit {
            std::size_t i, k;
            bool low;  // found from its higher body (see collect)
            Contact c;
        };
        std::vector<std::vector<RigidHit>>
            hitParts;  // the manifolds first (read only, on the job threads when big) ...
        const std::vector<std::size_t>& rows = rows_of();
        scan_rows(
            rows.size(),
            [&](std::size_t ri, std::vector<RigidHit>& out) {
                const std::size_t row = rows[ri];
                for_row(row, aabb_grow(tight_box(bodies_[row]), kBpEps), [&](std::size_t i, std::size_t k) {
                    const Body& a = bodies_[i];
                    const Body& b = bodies_[k];
                    if (!a.enabled || !a.hasShape || a.trigger || !b.enabled || !b.hasShape || b.trigger) return;
                    if (!a.rotDyn && !b.rotDyn) return;
                    if (!live_dyn(a) && !live_dyn(b)) return;
                    if (!filters_pass(a, b)) return;
                    Contact c = collide(a, b, 0.0f, true);
                    if (!c.hit || c.depth < 0.0f) return;
                    out.push_back({i, k, k == row, c});
                });
            },
            hitParts);
        // ... then each contact is built and warm started in pair order
        replay_sorted(hitParts, [&](RigidHit& hit) {
            {
                const std::size_t i = hit.i, k = hit.k;
                Body& a = bodies_[i];
                Body& b = bodies_[k];
                const Contact& c = hit.c;
                float& impact = impacts_[{a.seq, b.seq}];
                const int car = (carrier[k] == int(i) && a.type == BodyType::Kinematic)
                                    ? 1
                                    : ((carrier[i] == int(k) && b.type == BodyType::Kinematic) ? 2 : 0);
                RigidContact rc;
                if (!build_rigid_contact(a, b, i, k, c, h, car, impact, rc)) return;
                rc.key = {a.seq, b.seq};
                if (positional) {  // warm start: re-apply what the same contact points carried in the previous sub-step
                    if (const WarmEntry* cached = warm_find(rc.key)) {
                        const WarmEntry& old = *cached;
                        // Each point takes the impulses its feature (same id) carried in the previous sub-step; the points whose
                        // feature is new take those of the nearest point left over, if it is within kWarmRadius.
                        char taken[kMaxPts] = {};
                        int oldOf[kMaxPts];
                        for (int pi = 0; pi < rc.count; ++pi) {
                            oldOf[pi] = -1;
                            if (rc.pt[pi].id == 0) continue;
                            for (int oi = 0; oi < old.count; ++oi)
                                if (!taken[oi] && old.pt[oi].id == rc.pt[pi].id) {
                                    taken[oi] = 1;
                                    oldOf[pi] = oi;
                                    break;
                                }
                        }
                        for (int pi = 0; pi < rc.count; ++pi) {
                            if (oldOf[pi] >= 0) continue;
                            const Vec3 pos = a.center + rc.pt[pi].ra;
                            float bestD = kWarmRadius * kWarmRadius;
                            for (int oi = 0; oi < old.count; ++oi) {
                                const float dd = length_sq(old.pt[oi].pos - pos);
                                if (!taken[oi] && dd < bestD) {
                                    bestD = dd;
                                    oldOf[pi] = oi;
                                }
                            }
                            if (oldOf[pi] >= 0) taken[oldOf[pi]] = 1;
                        }
                        for (int pi = 0; pi < rc.count; ++pi) {
                            if (oldOf[pi] < 0) continue;
                            RigidContact::Pt& p = rc.pt[pi];
                            p.jn = old.pt[oldOf[pi]].jn;
                            p.jt = old.pt[oldOf[pi]].jt;
                            const Vec3 impulse = rc.n * p.jn + p.jt;
                            b.vel += impulse * b.invMass;
                            b.angVel += inv_inertia_mul(b, cross(p.rb, impulse)) * kRadToDeg;
                            a.vel -= impulse * a.invMass;
                            a.angVel -= inv_inertia_mul(a, cross(p.ra, impulse)) * kRadToDeg;
                        }
                    }
                }
                list.push_back(rc);
            }
        });
    };
    // The solver passes over `list`. positional: after the sub-step's motion (the relax pass of the soft contacts, the
    // simple pairs and the joints); else a time-of-impact stop, where every contact is solved hard and only the speeds change.
    auto iterate = [&](std::vector<RigidContact>& list, bool positional) {
        const bool jointsOn = positional && prepare_joints(h);
        // Iterations: 2 when only the simple pairs are solved; else each constraint gets the budget of its bodies (8, or
        // more for a joint chain), so a group's result never depends on the other groups of the world.
        auto budget = [&](std::size_t a, std::size_t b) {
            return std::max(bodies_[a].iterations, bodies_[b].iterations);
        };
        int iterations = (list.empty() && !jointsOn) ? kIterations : 0;
        for (const RigidContact& rc : list) iterations = std::max(iterations, budget(rc.ia, rc.ib));
        if (jointsOn)
            for (const JointState* jp : jointOrder_)
                if (jp->active && jp->live)
                    iterations = std::max(iterations, budget(jp->ia, jp->hasB ? jp->ib : jp->ia));
        for (int it = 0; it < iterations; ++it) {
            if (it < kIterations) {
                cover_tight();  // the rigid contacts and the joints of the last iteration moved bodies
                for_pairs_live([&](std::size_t i, std::size_t k) {
                    Body& a = bodies_[i];
                    Body& b = bodies_[k];
                    if (!a.enabled || !a.hasShape || a.trigger || !b.enabled || !b.hasShape || b.trigger) return;
                    if (a.rotDyn || b.rotDyn) return;
                    if (!live_dyn(a) && !live_dyn(b)) return;
                    if (!filters_pass(a, b)) return;
                    Contact c = collide(a, b, 0.0f);
                    if (!c.hit || c.depth < 0.0f) return;
                    float& impact = impacts_[{a.seq, b.seq}];
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
                });
            }
            for (std::size_t ri = 0; ri < list.size(); ++ri) {
                RigidContact& rc = list[(it & 1) ? list.size() - 1 - ri : ri];
                if (it >= budget(rc.ia, rc.ib)) continue;
                solve_manifold(bodies_, rc, positional ? 2 : 0, h, soft, softStatic);
            }
            if (jointsOn) solve_joints(h, it);
        }
        if (positional) {  // remember the solution as the next sub-step's starting point
            warm_.clear();
            bool ordered = true;
            for (const RigidContact& rc : list) {
                if (!warm_.empty() && !(warm_.back().key < rc.key)) ordered = false;  // contacts come in key order
                WarmEntry& e = warm_.emplace_back();
                e.key = rc.key;
                e.count = std::min(rc.count, int(kMaxPts));
                for (int pi = 0; pi < e.count; ++pi) e.pt[pi] = {rc.ca + rc.pt[pi].ra, rc.pt[pi].id, rc.pt[pi].jn, rc.pt[pi].jt};
            }
            if (!ordered)  // never in practice (the pair scan walks the bodies in seq order); keeps the lookup right
                std::stable_sort(warm_.begin(), warm_.end(),
                                 [](const WarmEntry& x, const WarmEntry& y) { return x.key < y.key; });
        }
    };

    auto resolve = [&](bool) {  // a time-of-impact stop: the contacts at that instant, solved hard
        build_contacts(rigid, false);
        iterate(rigid, false);
    };

    // A world where every body is asleep or static has nothing to simulate: no sub-steps, and the pair scan below finds no
    // new pair (the pairs it has keep their state), so the broad phase is not asked at all. A step of it costs only the
    // sync.
    // A static or kinematic body that gameplay placed this step is not asleep: its new place may overlap a sleeping pile,
    // which only the contact build (wake_touched) wakes.
    ensure_awake();
    const bool anyAwake = !R.awake.empty() || !R.movedStatic.empty();  // (a moved kinematic body is awake)
    std::vector<char> loaded(n, 0);  // per sub-step: bodies pressed against another dynamic body (settling below)
    if (anyAwake) {
        cover_stale();
        cover_tight(true);  // once per step: boxes that grew loose (a body that stopped) shrink back
    }
    for (int s = 0; s < (anyAwake ? subs : 0); ++s) {
        cover_tight();  // the previous sub-step moved the bodies after the last phase covered them
        std::fill(carrier.begin(), carrier.end(), -1);
        std::fill(charCarried.begin(), charCarried.end(), 0);
        for (const std::size_t k : R.platforms) {
            const Body& p = bodies_[k];
            if (p.vel != Vec3{}) {
                riders.clear();
                find_riders(k, riders);
                Vec3 d = p.vel * h;
                if (d.y > 0.0f) d.y = 0.0f;  // upward motion is delivered by the contact itself
                for (std::size_t i : riders) {
                    if (carrier[i] >= 0) continue;
                    carrier[i] = int(k);
                    bodies_[i].center += d;
                    cover_one(i, tight_box(bodies_[i]));
                }
            }
            // A character is kinematic too, so nothing pushes it up: it takes the whole displacement, and the turn of a
            // platform that spins (about the platform's centre; the character yaws with it).
            riders.clear();
            find_characters(k, riders);
            for (std::size_t i : riders) {
                if (charCarried[i]) continue;
                charCarried[i] = 1;
                Body& c = bodies_[i];
                c.center += p.vel * h;
                if (p.angVel != Vec3{}) {
                    const Vec3 rel = c.center - p.center;
                    const Vec3 w = p.angVel * (kDegToRad * h);
                    const float ang = length(w);
                    if (ang > 1e-9f) {  // Rodrigues rotation of the offset about the platform's turning axis
                        const Vec3 ax = w * (1.0f / ang);
                        const Vec3 turned = rel * det::cos(ang) + cross(ax, rel) * det::sin(ang) +
                                            ax * (dot(ax, rel) * (1.0f - det::cos(ang)));
                        c.center += turned - rel;
                    }
                    c.pendingTurn += p.angVel.y * h;
                }
                cover_one(i, tight_box(c));
            }
        }
        // A character presses on the dynamic body it stands on with mass * gravity, at its feet.
        for (const std::size_t i : R.characters) {
            Body& c = bodies_[i];
            if (!c.applyWeight || c.charMass <= 0.0f || c.support.is_null()) continue;
            auto sit = index_.find(c.support.bits());
            if (sit == index_.end()) continue;
            Body& under = bodies_[sit->second];
            if (under.type != BodyType::Dynamic || !under.enabled) continue;
            // Still on it: support is from the character's last move, and a script may have teleported it or stopped
            // moving it since (the same contact test that finds the characters on a platform).
            const Contact ct = collide(under, c, c.skin + 0.04f);
            if (!ct.hit || ct.normal.y <= 0.7f) continue;
            wake(under);
            const Vec3 impulse = g * (c.charMass * h);
            under.vel += impulse * under.invMass;
            const Vec3 foot = c.center - Vec3{0, c.segHalf + c.radius, 0};
            under.angVel += inv_inertia_mul(under, cross(foot - under.center, impulse)) * kRadToDeg;
        }
        for (const std::size_t i : rows_of()) {
            Body& b = bodies_[i];
            if (!b.enabled || !live_dyn(b)) continue;
            b.vel += (g * b.gravityScale + b.force * b.invMass) * h;
            if (b.damping + b.chainDrag > 0.0f) b.vel *= 1.0f / (1.0f + h * (b.damping + b.chainDrag));
            if (b.angDamping + b.chainDrag > 0.0f) b.angVel *= 1.0f / (1.0f + h * (b.angDamping + b.chainDrag));
            if (b.rotDyn && b.kind != Body::Kind::Sphere &&
                b.angVel != Vec3{}) {  // a box turning in the air precesses like a real one
                const Vec3 w = world_to_frame(b.ax, b.angVel * kDegToRad);
                const Vec3 turned = gyroscopic_step(w, {1.0f / b.invI.x, 1.0f / b.invI.y, 1.0f / b.invI.z}, h);
                b.angVel = frame_to_world(b.ax, turned) * kRadToDeg;
            }
        }
        // The contacts at the current poses, pushed out softly (their push-out speed moves the bodies in the motion below).
        build_contacts(held, true);
        for (int it = 0; it < kBiasIterations; ++it)
            for (std::size_t ri = 0; ri < held.size(); ++ri)
                solve_manifold(bodies_, held[(it & 1) ? held.size() - 1 - ri : ri], 1, h, soft, softStatic);
        std::vector<std::size_t> toiBodies;  // the bodies of the islands that had an impact in this sub-step
        // Motion with continuous collision, one ISLAND at a time: the bodies of an island advance together up to the first
        // impact among them (a time of impact), the contacts are resolved there (the velocity of the hit bodies changes:
        // stop, bounce, slide), and the rest of the sub-step continues with the new velocities, so a fast body keeps
        // sliding along the surface it hit. An island is a set of movable bodies linked by joints or close enough to
        // touch within the sub-step, so an impact (or too many of them) in one place never holds the bodies of another.
        {
            UnionFind islands(n);
            std::vector<std::size_t> movers;
            std::vector<float> reach(n, 0.0f);
            std::vector<char> isMover(n, 0);
            ensure_awake();
            auto reach_of = [&](const Body& b) {
                return b.hasShape && !b.trigger ? bound_radius(b) + length(b.vel) * h * 2.0f : 0.0f;
            };
            // The movers are the awake bodies and the sleeping bodies an awake one is close enough to join (the whole sleep
            // group of each: it wakes together): the rest of a sleeping pile is no part of any island, and a pile nothing is
            // near costs nothing here. "Close enough" is the test that joins two movers below, so an island is what it was
            // when the sleeping bodies were movers too.
            std::vector<std::uint64_t> playGroups;
            if (R.anyAsleep) {
                auto near_enough = [&](const Body& a, const Body& sl) {
                    if (!sl.hasShape || sl.trigger || !sl.enabled || !filters_pass(a, sl)) return false;
                    const float lim = reach_of(a) + bound_radius(sl) + 0.1f;
                    return length_sq(a.center - sl.center) <= lim * lim;
                };
                for (const std::size_t i : R.awake) {
                    const Body& a = bodies_[i];
                    if (!a.hasShape || a.trigger) continue;
                    const float rr = reach_of(a) + R.maxAsleepReach + 0.1f + kBpEps;
                    bp_.query(Aabb3{a.center - Vec3{rr}, a.center + Vec3{rr}}, [&](std::uint32_t k) {
                        const Body& sl = bodies_[k];
                        if (sl.asleep && near_enough(a, sl)) playGroups.push_back(sl.sleepGroup);
                    });
                    for (const std::size_t k : R.bigAsleep)
                        if (near_enough(a, bodies_[k])) playGroups.push_back(bodies_[k].sleepGroup);
                }
                for (const JointLink& l : jlinks)  // a joint to an awake body
                    if (l.b != kNoBody) {
                        const Body& a = bodies_[l.a];
                        const Body& b = bodies_[l.b];
                        if (a.enabled && b.enabled && movable(a) && movable(b) && a.asleep != b.asleep)
                            playGroups.push_back(a.asleep ? a.sleepGroup : b.sleepGroup);
                    }
                std::sort(playGroups.begin(), playGroups.end());
                playGroups.erase(std::unique(playGroups.begin(), playGroups.end()), playGroups.end());
            }
            if (playGroups.empty()) {
                movers = R.awake;
                for (const std::size_t i : movers) isMover[i] = 1;
            } else {
                for (std::size_t i = 0; i < n; ++i) {
                    const Body& b = bodies_[i];
                    if (!b.enabled || !movable(b)) continue;
                    if (b.asleep && !std::binary_search(playGroups.begin(), playGroups.end(), b.sleepGroup)) continue;
                    movers.push_back(i);
                    isMover[i] = 1;
                }
            }
            for (const std::size_t i : movers) reach[i] = reach_of(bodies_[i]);
            for (const JointLink& l : jlinks)
                if (l.b != kNoBody && movable(bodies_[l.a]) && movable(bodies_[l.b])) islands.unite(l.a, l.b);
            // Two movers join when their centres are closer than their reaches (plus 0.1 m). A mover of small reach (the
            // centre of every one is inside its fat box) finds its partners in the tree; the few movers the tree cannot
            // answer for (a big reach, or a centre outside the box) are tried against every mover. The islands do not depend
            // on the order the pairs are united in.
            auto try_unite = [&](std::size_t i, std::size_t k) {  // i < k, both movers
                const Body& a = bodies_[i];
                const Body& b = bodies_[k];
                if (!b.hasShape || b.trigger) return;
                if (a.type != BodyType::Dynamic && b.type != BodyType::Dynamic) return;
                const float lim = reach[i] + reach[k] + 0.1f;
                if (length_sq(a.center - b.center) > lim * lim) return;
                if (islands.find(i) != islands.find(k) && filters_pass(a, b)) islands.unite(i, k);
            };
            std::vector<std::size_t> special;
            std::vector<char> isSpecial(n, 0);
            float maxSmall = 0.0f;  // the biggest reach among the movers the tree answers for
            for (std::size_t i : movers) {
                const Body& b = bodies_[i];
                if (!b.hasShape || b.trigger) continue;
                if (b.proxy < 0 || reach[i] > kSmallReach || !aabb_contains(tight_box(b), Aabb3{b.center, b.center})) {
                    special.push_back(i);
                    isSpecial[i] = 1;
                } else {
                    maxSmall = std::max(maxSmall, reach[i]);
                }
            }
            for (std::size_t mi = 0; mi < movers.size(); ++mi) {
                const std::size_t i = movers[mi];
                const Body& a = bodies_[i];
                if (!a.hasShape || a.trigger) continue;
                if (isSpecial[i]) {
                    for (std::size_t mk = mi + 1; mk < movers.size(); ++mk) try_unite(i, movers[mk]);
                    continue;
                }
                const float rr = reach[i] + maxSmall + 0.1f + kBpEps;
                bp_.query(Aabb3{a.center - Vec3{rr}, a.center + Vec3{rr}}, [&](std::uint32_t k) {
                    if (k > i && isMover[k]) try_unite(i, k);
                });
                for (std::size_t k : special)
                    if (k > i) try_unite(i, k);
            }
            std::vector<std::vector<std::size_t>> groups;
            std::vector<std::size_t> groupOf(n, kNoBody);
            for (std::size_t i : movers) {
                const std::size_t r = islands.find(i);
                if (groupOf[r] == kNoBody) {
                    groupOf[r] = groups.size();
                    groups.emplace_back();
                }
                groups[groupOf[r]].push_back(i);
            }
            for (const std::vector<std::size_t>& members : groups) {
                float remaining = 1.0f;
                bool moving = false;
                for (std::size_t i : members) {
                    const Body& b = bodies_[i];
                    remaining = std::max(
                        remaining, 1.0f + b.carry);  // plus what the previous sub-step had no impacts left to move
                    moving = moving || b.carry > 0.0f || (!b.asleep && (b.vel != Vec3{} || b.angVel != Vec3{}));
                }
                for (std::size_t i : members) bodies_[i].carry = 0.0f;
                if (!moving) continue;
                scope = &members;
                for (std::size_t i : members) inScope[i] = 1;
                float carryOut = 0.0f;
                bool hit = false;
                for (int event = 0;; ++event) {
                    if (event ==
                        kMaxToiEvents) {  // more impacts than this sub-step can resolve: the rest of the move waits
                        carryOut = std::min(remaining, 1.0f);
                        break;
                    }
                    const float span = h * remaining;
                    for (std::size_t i : members) {
                        const Body& b = bodies_[i];
                        disp[i] = (b.enabled && movable(b) && !b.asleep) ? b.vel * span : Vec3{};
                    }
                    const float tHit = first_impact(span);
                    for (std::size_t i : members) {
                        Body& b = bodies_[i];
                        if (!b.enabled || !movable(b)) continue;
                        b.center += disp[i] * tHit;
                        if (b.rotDyn) integrate_orient(b, span * tHit);
                    }
                    if (tHit >= 1.0f) break;
                    resolve(false);
                    hit = true;
                    remaining *= 1.0f - tHit;
                    if (remaining < 1e-3f) break;
                }
                for (std::size_t i : members) bodies_[i].carry = carryOut;
                scope = nullptr;
                for (std::size_t i : members) inScope[i] = 0;
                if (hit) toiBodies.insert(toiBodies.end(), members.begin(), members.end());
            }
        }
        if (!toiBodies.empty()) {  // the bodies that had impacts in this sub-step: what their turn swept past is pushed back out
            std::sort(toiBodies.begin(), toiBodies.end());
            scope = &toiBodies;
            for (std::size_t i : toiBodies) inScope[i] = 1;
            build_contacts(rigid, false);
            for (int pass = 0; pass < 2; ++pass)
                for (const RigidContact& rc : rigid) correct_position(bodies_, rc);
            iterate(rigid, false);
            scope = nullptr;
            for (std::size_t i : toiBodies) inScope[i] = 0;
        }
        iterate(held, true);  // after the motion: the relax pass of the contacts, the simple pairs and the joints
        {  // settling: a slow rotating body pressed against another dynamic body loses speed (a capsule rolling on a pile
           // has no other brake). A body alone on the ground keeps its motion: a puck, a ball rolling down a gentle slope,
           // a spin. (Damping those too made the pit of 1000 never sleep: what settles a pile is its own contacts.)
            std::fill(loaded.begin(), loaded.end(), 0);
            for (const RigidContact& rc : held) {
                if (!live_dyn(bodies_[rc.ia]) || !live_dyn(bodies_[rc.ib])) continue;
                bool load = false;
                for (int pi = 0; pi < rc.count; ++pi) load = load || rc.pt[pi].jn > 0.0f;
                if (load) loaded[rc.ia] = loaded[rc.ib] = 1;
            }
            const float keep = 1.0f / (1.0f + h * kRestDamping);
            for (const std::size_t i : rows_of()) {
                Body& b = bodies_[i];
                if (!loaded[i] || !live_dyn(b) || !b.rotDyn || length(b.vel) >= kRestSpeed) continue;
                b.vel *= keep;
                b.angVel *= keep;
            }
        }
    }
    ensure_awake();  // (a force is only applied to a body that is awake)
    for (const std::size_t i : R.awake) bodies_[i].force = {};
    for (const std::size_t i : R.moved) bodies_[i].moved = false;

    // ---- events: track overlapping pairs across frames
    std::vector<std::pair<PairKey, PairState>>& cur = touchingNext_;  // filled in key order (scan order)
    cur.clear();
    bool curOrdered = true;
    auto& out = world.events().collisions;
    struct Begin {
        PairKey key;
        PairState st;
        Contact c;
    };
    std::vector<Begin> begins;
    std::vector<char> supported(n, 0);                       // dynamic body has solid ground (normal up) under it
    std::vector<std::pair<std::size_t, std::size_t>> links;  // touching awake dynamic bodies: they sleep together
    std::vector<char> hold(n, 0);                            // touches a moving kinematic body: must stay awake
    auto driving = [](const Body& b) {
        return b.type == BodyType::Kinematic && (b.vel != Vec3{} || b.angVel != Vec3{});
    };
    // The pair scan reads the bodies and `touching_` only (on the job threads when big); what it finds is replayed in
    // pair order below, so `cur`, `begins`, `supported`, `links` and `hold` come out as the single-threaded scan makes them.
    struct PairRec {
        std::size_t i, k;
        bool low;  // found from its higher body (see collect)
        PairKey key;
        bool was, trig;
        PairState st;
        Contact c;
    };
    std::vector<std::vector<PairRec>> pairParts;
    // The pairs of two bodies at rest (asleep or static) keep their state: they live in `frozen_` and are not looked at,
    // while the pairs with an awake body are found from the awake body's row.
    auto at_rest = [](const Body& b) { return b.enabled && b.hasShape && (b.asleep || b.type == BodyType::Static); };
    auto pair_bodies = [&](std::pair<PairKey, PairState>& e, std::size_t& ia, std::size_t& ib) {
        PairState& st = e.second;
        if (st.layout != layoutGen_) {
            const auto a = index_.find(st.a.bits());
            const auto b = index_.find(st.b.bits());
            if (a == index_.end() || b == index_.end()) return false;
            st.ia = std::uint32_t(a->second);
            st.ib = std::uint32_t(b->second);
            st.layout = layoutGen_;
        }
        ia = st.ia;
        ib = st.ib;
        return ia < n && ib < n && bodies_[ia].seq == e.first.first && bodies_[ib].seq == e.first.second;
    };
    auto merge_pairs = [](std::vector<std::pair<PairKey, PairState>>& into,
                          std::vector<std::pair<PairKey, PairState>>& from) {
        if (from.empty()) return;
        std::vector<std::pair<PairKey, PairState>> merged;
        merged.reserve(into.size() + from.size());
        std::merge(std::make_move_iterator(into.begin()), std::make_move_iterator(into.end()),
                   std::make_move_iterator(from.begin()), std::make_move_iterator(from.end()),
                   std::back_inserter(merged), [](const auto& x, const auto& y) { return x.first < y.first; });
        into.swap(merged);
        from.clear();
    };
    ensure_awake();
    if ((frozenDirty_ || frozenLayout_ != layoutGen_) && !frozen_.empty()) {  // a pair may have a body that is not at rest
        std::vector<std::pair<PairKey, PairState>> thawed;
        std::size_t w = 0;
        for (std::size_t r = 0; r < frozen_.size(); ++r) {
            std::size_t ia = 0, ib = 0;
            if (pair_bodies(frozen_[r], ia, ib) && at_rest(bodies_[ia]) && at_rest(bodies_[ib])) {
                if (w != r) frozen_[w] = std::move(frozen_[r]);
                ++w;
            } else {
                thawed.push_back(std::move(frozen_[r]));
            }
        }
        frozen_.resize(w);
        merge_pairs(touching_, thawed);
    }
    frozenDirty_ = false;
    frozenLayout_ = layoutGen_;
    {  // the pairs whose bodies both went to rest (they fell asleep, or one was made static) are put away
        std::vector<std::pair<PairKey, PairState>> resting;
        std::size_t w = 0;
        for (std::size_t r = 0; r < touching_.size(); ++r) {
            std::size_t ia = 0, ib = 0;
            if (pair_bodies(touching_[r], ia, ib) && at_rest(bodies_[ia]) && at_rest(bodies_[ib])) {
                resting.push_back(std::move(touching_[r]));
            } else {
                if (w != r) touching_[w] = std::move(touching_[r]);
                ++w;
            }
        }
        touching_.resize(w);
        merge_pairs(frozen_, resting);
    }
    if (anyAwake) cover_tight();
    const std::vector<std::size_t>& awakeRows = R.awake;
    scan_rows(
        awakeRows.size(),
        [&](std::size_t ri, std::vector<PairRec>& outRecs) {
            const std::size_t row = awakeRows[ri];
            const Body& r = bodies_[row];
            if (!r.hasShape) return;
            // The candidates: the bodies within the contact margin, except the awake ones below the row (their rows find it).
            thread_local std::vector<std::uint32_t> cand;
            collect(row, aabb_grow(tight_box(r), kEndMargin + kBpEps), 0, cand, true);
            for (const std::uint32_t other : cand) {
                const std::size_t i = std::min<std::size_t>(row, other), k = std::max<std::size_t>(row, other);
                const Body& a = bodies_[i];
                const Body& b = bodies_[k];
                if (!a.enabled || !a.hasShape || !b.enabled || !b.hasShape) continue;
                PairKey key{a.seq, b.seq};
                if (!filters_pass(a, b)) continue;
                const bool trig = a.trigger || b.trigger;
                if (trig && a.trigger && b.trigger) continue;
                bool was = touching_find(key) != nullptr;
                float margin = trig ? 0.0f : (was ? kEndMargin : kBeginMargin);
                Contact c = collide(a, b, margin);
                bool now = trig ? (c.hit && c.depth > 0.0f) : c.hit;
                if (!now) continue;
                outRecs.push_back({i, k, k == row, key, was, trig,
                                   PairState{a.e, b.e, trig, std::uint32_t(i), std::uint32_t(k), layoutGen_}, c});
            }
        },
        pairParts);
    replay_sorted(pairParts, [&](PairRec& r) {
        {
            const std::size_t i = r.i, k = r.k;
            const Body& a = bodies_[i];
            const Body& b = bodies_[k];
            if (!r.trig) {
                if (b.type == BodyType::Dynamic && r.c.normal.y > 0.7f) supported[k] = 1;
                if (a.type == BodyType::Dynamic && r.c.normal.y < -0.7f) supported[i] = 1;
                if (live_dyn(a) && live_dyn(b)) links.push_back({i, k});
                if (live_dyn(a) && driving(b)) hold[i] = 1;
                if (live_dyn(b) && driving(a)) hold[k] = 1;
            }
            if (!cur.empty() && !(cur.back().first < r.key)) curOrdered = false;
            cur.emplace_back(r.key, r.st);
            if (!r.was) begins.push_back({r.key, r.st, r.c});
        }
    });
    if (!curOrdered)  // never in practice (rows and columns of the scan ascend); keeps the lookups right
        std::stable_sort(cur.begin(), cur.end(), [](const auto& x, const auto& y) { return x.first < y.first; });
    auto in_cur = [&](const PairKey& key) {
        auto it =
            std::lower_bound(cur.begin(), cur.end(), key,
                             [](const std::pair<PairKey, PairState>& e, const PairKey& k) { return e.first < k; });
        return it != cur.end() && it->first == key;
    };
    for (auto& [key, st] : touching_) {
        if (in_cur(key)) continue;
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
        const float* im = impacts_.find(bg.key);
        ev.impulse = im ? *im : 0.0f;
        out.push_back(ev);
    }
    touching_.swap(touchingNext_);

    // ---- rolling: spheres on the ground spin to match their horizontal motion
    for (const std::size_t i : R.awake) {
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
    // Joined bodies sleep as one: a settled chain costs nothing. A motor keeps its bodies awake (it is working), and so
    // does a joint to a kinematic body that moves.
    for (const JointLink& l : jlinks) {
        const bool aLive = live_dyn(bodies_[l.a]);
        const bool bLive = l.b != kNoBody && live_dyn(bodies_[l.b]);
        if (aLive && bLive) root[find_root(l.a)] = find_root(l.b);
        if (l.motor) {
            if (aLive) hold[l.a] = 1;
            if (bLive) hold[l.b] = 1;
        }
        if (l.b != kNoBody && aLive && driving(bodies_[l.b])) hold[l.a] = 1;
        if (bLive && driving(bodies_[l.a])) hold[l.b] = 1;
    }
    std::vector<int> size(n, 0), restless(n, 0);  // per island root: its bodies, and those still moving faster than kSleepSpeed
    std::vector<float> fastest(n, 0.0f), speeds(n, 0.0f);
    std::vector<char> ready(n, 1);  // per island root
    for (const std::size_t i : R.awake) {
        Body& b = bodies_[i];
        if (!b.enabled || !live_dyn(b)) continue;
        const float reach = !b.hasShape ? 0.0f : bound_radius(b);  // fastest point of the shape
        // An arcade sphere (rollWithMotion) only spins to match its motion: a stale spin it kept from before it stopped being
        // supported does not count.
        const bool arcade = b.kind == Body::Kind::Sphere && b.rollWithMotion;
        const float speed = std::max(length(b.vel), arcade ? 0.0f : length(b.angVel) * kDegToRad * reach);
        speeds[i] = speed;
        const std::size_t r = find_root(i);
        ++size[r];
        if (speed >= kSleepSpeed) {
            ++restless[r];
            fastest[r] = std::max(fastest[r], speed);
        }
        if (hold[i]) ready[r] = 0;
    }
    for (const std::size_t i : R.awake) {
        Body& b = bodies_[i];
        if (!b.enabled || !live_dyn(b)) continue;
        const std::size_t r = find_root(i);
        // A big pile never stops completely: a few of its bodies keep creeping. They do not keep it awake while there are
        // at most one in kStragglers of them and each is slower than kStragglerSpeed.
        const bool excused = restless[r] <= size[r] / kStragglers && fastest[r] < kStragglerSpeed;
        b.sleepTime = (speeds[i] < kSleepSpeed || excused) ? b.sleepTime + dt : 0.0f;
        if (b.sleepTime < kTimeToSleep) ready[r] = 0;
    }
    bool fellAsleep = false;
    for (const std::size_t i : R.awake) {
        Body& b = bodies_[i];
        if (!b.enabled || !live_dyn(b) || !ready[find_root(i)]) continue;
        b.asleep = true;
        b.sleepGroup = bodies_[find_root(i)].seq;  // the island is named after its root (seq is never reused)
        b.vel = b.angVel = {};
        fellAsleep = true;
        if (b.proxy >= 0)  // its box in the broad phase shrinks to what a body at rest needs
            bp_.cover(b.proxy, tight_box(b), kFatMarginStill, Vec3{}, true);
    }

    // ---- write back (the bodies that were awake in this step; a body at rest has nothing to write)
    for (const std::size_t i : R.awake) {
        Body& b = bodies_[i];
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
        if (b.pendingTurn != 0.0f) {
            if (Transform* t = world.get<Transform>(b.e)) t->rotation.y += b.pendingTurn;
            b.pendingTurn = 0.0f;
        }
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
    if (fellAsleep) awakeStale_ = true;
    finish_joints(world, dt);
}

// ------------------------------------------------------------- queries ----
// One body against a ray (origin, unit direction d): true with the entry distance and normal when it is hit within
// `limit`. Shared by raycast (limit shrinks to the best hit so far) and raycast_all (limit = maxDistance).
bool Physics3D::ray_vs_body(const Body& b, Vec3 origin, Vec3 d, float limit, float& tOut, Vec3& nOut) {
    if (b.general()) {  // capsule / convex / mesh
        float t = 0.0f;
        Vec3 gn;
        if (ray_body(b, origin, d, limit, t, gn) && t <= limit) {
            tOut = t;
            nOut = gn;
            return true;
        }
        return false;
    }
    // A turned box is tested in its own frame (same distances); an unturned one in world space, exactly as before.
    Vec3 lo = b.center - b.half, hi = b.center + b.half, org = origin, od = d;
    if (b.rotated) {
        lo = -b.half;
        hi = b.half;
        org = world_to_frame(b.ax, origin - b.center);
        od = world_to_frame(b.ax, d);
    }
    {  // origin inside this collider: skip it
        bool inside = b.kind == Body::Kind::Box ? (org.x > lo.x && org.x < hi.x && org.y > lo.y && org.y < hi.y &&
                                                   org.z > lo.z && org.z < hi.z)
                                                : length_sq(origin - b.center) < b.radius * b.radius;
        if (inside) return false;
    }
    float t = 0.0f;
    Vec3 nrm;
    if (b.kind == Body::Kind::Box) {
        float tmin = 0.0f, tmax = limit;
        int axisHit = -1;
        float sgnHit = 0.0f;
        bool miss = false;
        for (int i = 0; i < 3 && !miss; ++i) {
            if (std::fabs(od[i]) < 1e-9f) {
                if (org[i] < lo[i] || org[i] > hi[i]) miss = true;
            } else {
                float t1 = (lo[i] - org[i]) / od[i], t2 = (hi[i] - org[i]) / od[i];
                float sgn = -1.0f;  // entering through the low face -> normal points to -axis
                if (t1 > t2) {
                    std::swap(t1, t2);
                    sgn = 1.0f;
                }
                if (t1 > tmin) {
                    tmin = t1;
                    axisHit = i;
                    sgnHit = sgn;
                }
                tmax = std::min(tmax, t2);
                if (tmin > tmax) miss = true;
            }
        }
        if (miss) return false;
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
        if (cc > 0.0f && bb > 0.0f) return false;
        float disc = bb * bb - cc;
        if (disc < 0.0f) return false;
        t = std::max(-bb - std::sqrt(disc), 0.0f);
        Vec3 p = origin + d * t;
        nrm = cc <= 0.0f ? -d : normalize(p - b.center);
    }
    if (t > limit) return false;
    tOut = t;
    nOut = nrm;
    return true;
}

bool Physics3D::ray_candidate(const World& world, const Body& b, const RaycastOptions& opt, std::uint64_t qmask) {
    if (!b.enabled || !b.hasShape || (b.trigger && opt.ignoreTriggers) || !live(world, b.e)) return false;
    if ((category_bits(b.layer) & qmask) == 0) return false;
    return !entity_or_ancestor_is(world, b.e, opt.ignore);
}

std::optional<RaycastHit> Physics3D::raycast(World& world, Vec3 origin, Vec3 dir, float maxDistance,
                                             const RaycastOptions& opt) {
    Vec3 d = normalize(dir);
    if (length_sq(d) < 0.5f) return std::nullopt;
    const std::uint64_t qmask = mask_bits(opt.mask);
    float bestT = maxDistance;
    const Body* best = nullptr;
    Vec3 bestN;
    for (const Body& b : bodies_) {
        if (!ray_candidate(world, b, opt, qmask)) continue;
        float t = 0.0f;
        Vec3 n;
        if (ray_vs_body(b, origin, d, bestT, t, n)) {
            bestT = t;
            best = &b;
            bestN = n;
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

std::vector<RaycastHit> Physics3D::raycast_all(World& world, Vec3 origin, Vec3 dir, float maxDistance,
                                               const RaycastOptions& opt) {
    std::vector<RaycastHit> out;
    Vec3 d = normalize(dir);
    if (length_sq(d) < 0.5f || opt.maxHits <= 0) return out;
    const std::uint64_t qmask = mask_bits(opt.mask);
    for (const Body& b : bodies_) {
        if (!ray_candidate(world, b, opt, qmask)) continue;
        float t = 0.0f;
        Vec3 n;
        if (!ray_vs_body(b, origin, d, maxDistance, t, n)) continue;
        RaycastHit h;
        h.entity = b.e;
        h.point = origin + d * t;
        h.normal = n;
        h.distance = t;
        out.push_back(h);
    }
    std::stable_sort(out.begin(), out.end(),
                     [](const RaycastHit& a, const RaycastHit& b) { return a.distance < b.distance; });
    if (out.size() > static_cast<std::size_t>(opt.maxHits)) out.resize(static_cast<std::size_t>(opt.maxHits));
    return out;
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
    if (b.type != BodyType::Dynamic || !b.enabled) return;  // a disabled body has no step to clear it
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
                out.push_back({Physics::DebugShape::Capsule, b.center,
                               Vec3{b.radius * 2.0f, (b.segHalf + b.radius) * 2.0f, b.radius * 2.0f}, rot.z, b.trigger,
                               rot});
                break;
            default:  // convex / mesh: the oriented bounding box of the model (centre moved to the box's centre)
                out.push_back({b.kind == Body::Kind::Convex ? Physics::DebugShape::Convex : Physics::DebugShape::Mesh,
                               b.center + frame_to_world(b.ax, b.lcenter), b.half * 2.0f, rot.z, b.trigger, rot});
                break;
        }
    }
}

}  // namespace fa::detail
