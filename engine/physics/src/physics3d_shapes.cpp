// Capsule, convex-hull and triangle-mesh colliders of Physics3D: contacts through the convex cores of shape3d.h, the
// triangle mid-phase, ray casts and the shared mesh data. Box and sphere keep their own exact code in physics3d.cpp.
#include <algorithm>
#include <cmath>

#include "fa/core/strings.h"
#include "fa/scene/mesh_geometry.h"
#include "physics_internal.h"

namespace fa::detail {

namespace {
constexpr float kManifoldGap = 0.003f;  // manifold points this far above the surface still count (m)
constexpr float kProbeLift = 0.2f;      // mesh manifolds probe the surface from this far above each candidate point (m)
constexpr float kLowBand = 0.05f;       // ...for candidates this close to the lowest one (m)

Vec3 core_centre(const Core& c) {
    return c.kind == Core::Segment ? (c.a + c.b) * 0.5f : (c.kind == Core::Triangle ? (c.a + c.b + c.c) / 3.0f : c.a);
}
}  // namespace

float Physics3D::bound_radius(const Body& b) {
    switch (b.kind) {
        case Body::Kind::Sphere: return b.radius;
        case Body::Kind::Capsule: return b.segHalf + b.radius;
        case Body::Kind::Box: return length(b.half);
        default: return length(b.lcenter) + length(b.half);
    }
}

float Physics3D::min_half_extent(const Body& b) {
    switch (b.kind) {
        case Body::Kind::Sphere:
        case Body::Kind::Capsule: return b.radius;
        default: return std::min({b.half.x, b.half.y, b.half.z});
    }
}

// Axis-aligned bounds of a shape in world space (sweep broad phase, mid-phase queries).
void Physics3D::aabb(const Body& b, Vec3& lo, Vec3& hi) {
    Vec3 centre = b.center, e;
    switch (b.kind) {
        case Body::Kind::Sphere: e = Vec3{b.radius}; break;
        case Body::Kind::Capsule:
            e = Vec3{std::fabs(b.ax[1].x), std::fabs(b.ax[1].y), std::fabs(b.ax[1].z)} * b.segHalf + Vec3{b.radius};
            break;
        default:
            if (b.kind != Body::Kind::Box) centre = b.center + frame_to_world(b.ax, b.lcenter);
            e = {std::fabs(b.ax[0].x) * b.half.x + std::fabs(b.ax[1].x) * b.half.y + std::fabs(b.ax[2].x) * b.half.z,
                 std::fabs(b.ax[0].y) * b.half.x + std::fabs(b.ax[1].y) * b.half.y + std::fabs(b.ax[2].y) * b.half.z,
                 std::fabs(b.ax[0].z) * b.half.x + std::fabs(b.ax[1].z) * b.half.y + std::fabs(b.ax[2].z) * b.half.z};
            break;
    }
    lo = centre - e;
    hi = centre + e;
}

Core Physics3D::core_of(const Body& b) {
    Core c;
    c.a = b.center;
    switch (b.kind) {
        case Body::Kind::Sphere:
            c.kind = Core::Point;
            c.radius = b.radius;
            break;
        case Body::Kind::Capsule:
            c.kind = Core::Segment;
            c.a = b.center - b.ax[1] * b.segHalf;
            c.b = b.center + b.ax[1] * b.segHalf;
            c.radius = b.radius;
            break;
        case Body::Kind::Box:
            c.kind = Core::Box;
            c.half = b.half;
            for (int i = 0; i < 3; ++i) c.ax[i] = b.ax[i];
            break;
        default:  // convex (a mesh never becomes a core: its triangles do)
            c.kind = Core::Hull;
            c.verts = b.data ? b.data->hull.data() : nullptr;
            c.count = b.data ? int(b.data->hull.size()) : 0;
            c.scale = b.gscale;
            for (int i = 0; i < 3; ++i) c.ax[i] = b.ax[i];
            break;
    }
    return c;
}

// Contact between two convex shapes (core + radius); normal from A to B.
Physics3D::Contact Physics3D::core_contact(const Core& A, const Core& B, float margin) {
    Contact c;
    const float rr = A.radius + B.radius;
    const GjkResult g = gjk(A, B);
    if (!g.overlap) {
        if (!(g.dist < rr + margin) || g.dist < 1e-9f) return c;
        const Vec3 n = (g.pb - g.pa) / g.dist;
        c.normal = n;
        c.depth = rr - g.dist;
        c.point = (g.pa + n * A.radius + g.pb - n * B.radius) * 0.5f;
        c.hit = true;
        return c;
    }
    const EpaResult e = epa(A, B, g);  // the cores themselves overlap: deep penetration
    if (!e.ok) return c;
    c.normal = e.normal;
    c.depth = e.depth + rr;
    c.point = (e.pa + e.pb) * 0.5f;
    c.hit = true;
    return c;
}

// One triangle (a flat core) against a convex shape; normal from the triangle to the shape.
Physics3D::Contact Physics3D::tri_contact(const Core& T, const Core& X, float margin) {
    Contact c;
    const GjkResult g = gjk(T, X);
    if (!g.overlap) {
        if (!(g.dist < X.radius + margin) || g.dist < 1e-9f) return c;
        c.normal = (g.pb - g.pa) / g.dist;
        c.depth = X.radius - g.dist;
        c.point = g.pa;
        c.hit = true;
        return c;
    }
    // The shape's core crosses the triangle: a flat triangle has no inside for EPA, so push out along its plane normal
    // (towards the side the shape's centre is on) by the shape's deepest point.
    Vec3 nt = normalize(cross(T.b - T.a, T.c - T.a));
    if (length_sq(nt) < 0.5f) return c;
    if (dot(core_centre(X) - T.a, nt) < 0.0f) nt = -nt;
    const Vec3 p = core_support(X, -nt) - nt * X.radius;
    c.normal = nt;
    c.depth = dot(T.a - p, nt);
    c.point = p;
    c.hit = c.depth > -margin;
    return c;
}

// A convex shape against a triangle mesh (static): the deepest contact over the triangles near it, found through the BVH.
// manifold: a box or hull resting on the mesh gets one contact point per low corner (ray-probed down onto the surface), a
// capsule lying flat gets one per end (see add_capsule_points), so a rigid body rests on a ramp instead of rocking.
Physics3D::Contact Physics3D::mesh_contact(const Body& mesh, const Body& other, float margin, bool manifold) {
    Contact best;
    if (!mesh.data) return best;
    const ShapeData& d = *mesh.data;
    const Core X = core_of(other);
    Vec3 lo, hi;
    aabb(other, lo, hi);
    lo -= Vec3{margin};
    hi += Vec3{margin};
    Vec3 mlo{1e30f, 1e30f, 1e30f}, mhi{-1e30f, -1e30f, -1e30f};
    for (int i = 0; i < 8; ++i) {
        const Vec3 corner{(i & 1) ? hi.x : lo.x, (i & 2) ? hi.y : lo.y, (i & 4) ? hi.z : lo.z};
        const Vec3 l = world_to_frame(mesh.ax, corner - mesh.center) / mesh.gscale;
        mlo = min(mlo, l);
        mhi = max(mhi, l);
    }
    auto world = [&](Vec3 v) { return mesh.center + frame_to_world(mesh.ax, v * mesh.gscale); };
    d.query(mlo, mhi, [&](std::uint32_t tri) {
        Core T;
        T.kind = Core::Triangle;
        T.a = world(d.tri_vertex(tri, 0));
        T.b = world(d.tri_vertex(tri, 1));
        T.c = world(d.tri_vertex(tri, 2));
        const Contact c = tri_contact(T, X, margin);
        if (c.hit && (!best.hit || c.depth > best.depth + 1e-7f)) best = c;
    });
    if (!best.hit || !manifold || (other.kind != Body::Kind::Box && other.kind != Body::Kind::Convex)) return best;
    // Candidate points: the box corners / hull vertices nearest the surface (lowest along the contact normal).
    const Vec3 n = best.normal;  // mesh -> other
    std::vector<Vec3> cand;
    if (other.kind == Body::Kind::Box) {
        for (int i = 0; i < 8; ++i)
            cand.push_back(other.center + other.ax[0] * ((i & 1) ? other.half.x : -other.half.x) +
                           other.ax[1] * ((i & 2) ? other.half.y : -other.half.y) +
                           other.ax[2] * ((i & 4) ? other.half.z : -other.half.z));
    } else {
        for (const Vec3& v : other.data->hull)
            cand.push_back(other.center + frame_to_world(other.ax, v * other.gscale));
    }
    float lowest = 1e30f;
    for (const Vec3& p : cand) lowest = std::min(lowest, dot(p, n));
    std::vector<std::pair<float, std::size_t>> low;
    for (std::size_t i = 0; i < cand.size(); ++i)
        if (dot(cand[i], n) <= lowest + kLowBand) low.push_back({dot(cand[i], n), i});
    std::sort(low.begin(), low.end());
    int count = 0;
    Contact m = best;
    for (const auto& [h, idx] : low) {
        if (count >= kMaxPts) break;
        const Vec3 p = cand[idx];
        const Vec3 org = world_to_frame(mesh.ax, p + n * kProbeLift - mesh.center) / mesh.gscale;
        const Vec3 dir = world_to_frame(mesh.ax, -n) / mesh.gscale;
        float t = 0.0f;
        std::uint32_t tri = 0;
        Vec3 nl;
        if (!ray_triangles(d, org, dir, kProbeLift + kLowBand, t, tri, nl)) continue;
        const Vec3 nw = normalize(frame_to_world(mesh.ax, nl / mesh.gscale));
        if (dot(nw, n) < 0.8f) continue;  // a wall or a steep neighbour: not part of this face contact
        const float depth = kProbeLift - t;
        if (depth < -kManifoldGap) continue;
        m.pts[count] = p + n * (depth * 0.5f);
        m.depths[count] = depth;
        ++count;
    }
    if (count > 0) {
        m.n = count;
        m.point = {};
        for (int i = 0; i < count; ++i) m.point += m.pts[i];
        m.point = m.point / float(count);
        return m;
    }
    return best;
}

// A capsule lying flat on a surface touches it along its whole straight part: add the contact points of both end spheres
// (probed as spheres against the other shape) so a rigid capsule does not pivot about one point.
void Physics3D::add_capsule_points(const Body& a, const Body& b, Contact& c) {
    const Body* cap = b.kind == Body::Kind::Capsule ? &b : (a.kind == Body::Kind::Capsule ? &a : nullptr);
    if (!cap || cap->segHalf < 1e-4f) return;
    const bool capIsB = cap == &b;
    const Body& other = capIsB ? a : b;
    const Vec3 u = cap->ax[1];
    if (std::fabs(dot(u, c.normal)) > 0.3f) return;
    Body probe;
    probe.kind = Body::Kind::Sphere;
    probe.hasShape = true;
    probe.enabled = true;
    probe.radius = cap->radius;
    Contact q[2];
    for (int s = 0; s < 2; ++s) {
        probe.center = cap->center + u * (s ? cap->segHalf : -cap->segHalf);
        q[s] = capIsB ? collide(other, probe, kManifoldGap) : collide(probe, other, kManifoldGap);
        if (!q[s].hit || dot(q[s].normal, c.normal) < 0.7f || q[s].depth < -kManifoldGap) return;
    }
    c.n = 2;
    c.point = {};
    for (int s = 0; s < 2; ++s) {
        c.pts[s] = q[s].point;
        c.depths[s] = q[s].depth;
        c.point += q[s].point * 0.5f;
    }
}

// Contact for any pair with a capsule, convex hull or mesh; normal from a to b, depth > 0 penetrating.
Physics3D::Contact Physics3D::collide_general(const Body& a, const Body& b, float margin, bool manifold) {
    Contact none;
    if (a.kind == Body::Kind::Mesh && b.kind == Body::Kind::Mesh) return none;
    Vec3 alo, ahi, blo, bhi;
    aabb(a, alo, ahi);
    aabb(b, blo, bhi);
    if (alo.x > bhi.x + margin || ahi.x < blo.x - margin || alo.y > bhi.y + margin || ahi.y < blo.y - margin ||
        alo.z > bhi.z + margin || ahi.z < blo.z - margin)
        return none;
    Contact c;
    if (a.kind == Body::Kind::Mesh) {
        c = mesh_contact(a, b, margin, manifold);
    } else if (b.kind == Body::Kind::Mesh) {
        c = mesh_contact(b, a, margin, manifold);
        c.normal = -c.normal;
    } else {
        c = core_contact(core_of(a), core_of(b), margin);
    }
    if (c.hit && manifold && c.n == 0) add_capsule_points(a, b, c);
    return c;
}

// Sphere tracing against a convex core: advance by the gap to the shape (it cannot be hit sooner), bisect if a minimum step
// jumped inside. Grazing hits at under ~3 degrees may be missed.
static bool ray_core(const Core& core, Vec3 origin, Vec3 d, float maxT, float& tOut, Vec3& normal) {
    Core pt;
    pt.kind = Core::Point;
    GjkResult g;
    auto gap_at = [&](float t) {
        pt.a = origin + d * t;
        g = gjk(pt, core);
        return g.overlap ? -1.0f : g.dist - core.radius;
    };
    if (gap_at(0.0f) <= 0.0f) return false;  // the origin is inside: skipped, like the other shapes
    float t = 0.0f, prev = 0.0f;
    for (int it = 0; it < 256; ++it) {
        const float gap = gap_at(t);
        if (gap <= 1e-4f) {
            if (gap < 0.0f) {  // stepped inside: the surface lies between prev (outside) and t
                float lo = prev, hi = t;
                for (int k = 0; k < 40; ++k) {
                    const float mid = 0.5f * (lo + hi);
                    if (gap_at(mid) < 0.0f) hi = mid;
                    else lo = mid;
                }
                t = lo;
                gap_at(t);
            }
            const Vec3 n = g.overlap ? Vec3{} : normalize(g.pa - g.pb);
            normal = length_sq(n) > 0.5f ? n : -d;
            tOut = t;
            return true;
        }
        if (t >= maxT) return false;
        prev = t;
        t = std::min(t + std::max(gap, 5e-4f), maxT);
    }
    return false;
}

// Ray against a capsule, convex hull or mesh (dir unit). Skips shapes that contain the origin; for a mesh, the first
// triangle hit (either side) with the normal facing the ray.
bool Physics3D::ray_body(const Body& b, Vec3 origin, Vec3 dir, float maxT, float& t, Vec3& normal) {
    if (b.kind == Body::Kind::Mesh) {
        if (!b.data) return false;
        const Vec3 org = world_to_frame(b.ax, origin - b.center) / b.gscale;
        const Vec3 d = world_to_frame(b.ax, dir) / b.gscale;  // not unit: t stays in world meters
        std::uint32_t tri = 0;
        Vec3 nl;
        if (!ray_triangles(*b.data, org, d, maxT, t, tri, nl)) return false;
        normal = normalize(frame_to_world(b.ax, nl / b.gscale));
        if (dot(normal, dir) > 0.0f) normal = -normal;
        return true;
    }
    return ray_core(core_of(b), origin, dir, maxT, t, normal);
}

// A procedural mesh ("mesh:N", fa/scene/mesh_store.h) is cached under its id and version, so an update builds a new shape and
// the bodies using the mesh pick it up; prune_procedural_shapes() drops the ones nobody can ask for any more.
std::shared_ptr<const ShapeData> Physics3D::shape_data(World& world, const std::string& mesh, bool bvh, std::string& problem) {
    std::string key = std::string(bvh ? "M:" : "H:") + mesh_key(mesh);
    std::shared_ptr<const MeshGeometry> geometry;
    if (MeshStore::is_id(mesh)) {
        auto entry = world.meshes().get(mesh);
        if (!entry) {
            problem = entry.error().to_string();
            return nullptr;
        }
        key += "@" + std::to_string((*entry)->version);
        if (auto it = shapes_.find(key); it != shapes_.end()) return it->second;
        geometry = world.meshes().geometry(mesh);
    } else {
        if (auto it = shapes_.find(key); it != shapes_.end()) return it->second;
        auto loaded = load_mesh_geometry(mesh);
        if (!loaded) {
            problem = loaded.error().to_string();
            return nullptr;
        }
        geometry = loaded.value();
    }
    auto data = make_shape_data(geometry, !bvh, bvh);
    shapes_[key] = data;
    return data;
}

void Physics3D::prune_procedural_shapes(const World& world) {
    for (auto it = shapes_.begin(); it != shapes_.end();) {
        const std::string& key = it->first;  // "M:mesh:3@7"
        const std::size_t at = key.find('@');
        bool keep = true;
        if (at != std::string::npos && MeshStore::is_id(std::string_view(key).substr(2, at - 2))) {
            const MeshStore::Entry* e = world.meshes().find(key.substr(2, at - 2));
            keep = e && std::to_string(e->version) == key.substr(at + 1);
        }
        it = keep ? std::next(it) : shapes_.erase(it);
    }
}

std::vector<std::string> Physics3D::problems() const {
    std::vector<std::string> out;
    for (const Body& b : bodies_)
        if (!b.problem.empty()) out.push_back(b.problem);
    for (const auto& [key, j] : joints_)
        if (!j.problem.empty()) out.push_back(j.problem);
    return out;
}

}  // namespace fa::detail
