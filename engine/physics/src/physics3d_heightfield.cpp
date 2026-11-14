// Contacts of Physics3D against a heightfield collider (heightfield3d.h): the cells under the other shape's bounds are two
// triangles each, a convex core is tested against them with GJK like a triangle mesh, and the results are cleaned up for a
// grid: a contact on an edge or corner shared with another triangle only counts when its normal lies between the normals
// of the triangles that meet there (no bump when something slides over the seams of a flat or gently sloped field), and
// the ground is solid below its surface (a body whose core sank under a triangle is pushed up, never down through it).
#include <algorithm>
#include <cmath>

#include "physics_internal.h"

namespace fa::detail {

namespace {
// The same constants as the mesh manifolds (physics3d_shapes.cpp): points this far above the surface still count, the probes
// start this far above the candidate points, and candidates this close to the lowest one are used.
constexpr float kManifoldGap = 0.003f;
constexpr float kProbeLift = 0.2f;
constexpr float kLowBand = 0.05f;
constexpr float kFeatureEps = 1e-4f;  // barycentric distance from an edge or corner that still counts as on it
constexpr float kConeSlack = 1e-3f;   // dot-product slack of the normal test (about 2.5 degrees near flat)

void barycentric(Vec3 p, const Core& T, float& u, float& v, float& w) {
    const Vec3 v0 = T.b - T.a, v1 = T.c - T.a, v2 = p - T.a;
    const float d00 = dot(v0, v0), d01 = dot(v0, v1), d11 = dot(v1, v1), d20 = dot(v2, v0), d21 = dot(v2, v1);
    const float den = d00 * d11 - d01 * d01;
    if (std::fabs(den) < 1e-20f) {
        u = 1.0f;
        v = w = 0.0f;
        return;
    }
    v = (d11 * d20 - d01 * d21) / den;
    w = (d00 * d21 - d01 * d20) / den;
    u = 1.0f - v - w;
}

// What one triangle says about the shape.
struct TriHit {
    Vec3 normal, point;
    float depth = 0.0f;
    int feature = 0;  // 0 the face, 1 an edge (index = the vertex opposite to it), 2 a corner (index = that vertex)
    int index = 0;
};

// One triangle of the field (a flat core) against a convex shape; the normal points from the triangle to the shape, and
// `up` is the triangle's own normal (pointing out of the ground).
bool field_triangle(const Core& T, const Core& X, float margin, Vec3 up, TriHit& out) {
    const GjkResult g = gjk(T, X);
    auto face = [&]() {  // the shape's deepest point below the triangle's plane
        const Vec3 p = core_support(X, -up) - up * X.radius;
        out.normal = up;
        out.point = p;
        out.depth = dot(T.a - p, up);
        out.feature = 0;
        return out.depth > -margin;
    };
    if (g.overlap) return face();
    if (!(g.dist < X.radius + margin) || g.dist < 1e-9f) return false;
    const Vec3 n = (g.pb - g.pa) / g.dist;
    float u, v, w;
    barycentric(g.pa, T, u, v, w);
    const int small = (u < kFeatureEps ? 1 : 0) + (v < kFeatureEps ? 1 : 0) + (w < kFeatureEps ? 1 : 0);
    if (small == 0) {
        if (dot(n, up) < 0.0f)
            return face();  // the shape is under the surface, above nothing: solid ground pushes it up
        out.normal = n;
        out.point = g.pa;
        out.depth = X.radius - g.dist;
        out.feature = 0;
        return true;
    }
    out.normal = n;
    out.point = g.pa;
    out.depth = X.radius - g.dist;
    if (small == 1) {
        out.feature = 1;
        out.index = u < kFeatureEps ? 0 : (v < kFeatureEps ? 1 : 2);
    } else {
        out.feature = 2;
        out.index = (u >= v && u >= w) ? 0 : (v >= w ? 1 : 2);
    }
    return true;
}
}  // namespace

Physics3D::Contact Physics3D::heightfield_contact(const Body& field, const Body& other, float margin, bool manifold) {
    Contact best;
    if (!field.hf || !field.hf->valid) return best;
    const HeightfieldShape& f = *field.hf;
    const Core X = core_of(other);
    Vec3 lo, hi;
    aabb(other, lo, hi);
    lo -= Vec3{margin};
    hi += Vec3{margin};
    Vec3 mlo{1e30f, 1e30f, 1e30f}, mhi{-1e30f, -1e30f, -1e30f};
    for (int i = 0; i < 8; ++i) {
        const Vec3 corner{(i & 1) ? hi.x : lo.x, (i & 2) ? hi.y : lo.y, (i & 4) ? hi.z : lo.z};
        const Vec3 l = world_to_frame(field.ax, corner - field.center) / field.gscale;
        mlo = min(mlo, l);
        mhi = max(mhi, l);
    }
    auto world = [&](Vec3 v) { return field.center + frame_to_world(field.ax, v * field.gscale); };
    auto up_of = [](const Core& T) { return normalize(cross(T.b - T.a, T.c - T.a)); };
    auto triangle_core = [&](int r, int c, int which) {
        Vec3 v[3];
        f.triangle(r, c, which, v);
        Core T;
        T.kind = Core::Triangle;
        T.a = world(v[0]);
        T.b = world(v[1]);
        T.c = world(v[2]);
        return T;
    };
    // Is the contact's normal one the surface really has there? Face contacts always are. On an edge or a corner it has to lie
    // between the normals of the triangles that meet at it (within the widest angle between two of them): anything else is the
    // contact of a seam the shape is beside, not on, and the triangle that owns that part of the surface gives the true one.
    auto genuine = [&](int r, int c, int which, const TriHit& h, const Core& T) {
        if (h.feature == 0) return true;
        Vec3 normals[7];
        int count = 0;
        normals[count++] = up_of(T);
        auto add = [&](int nr, int nc, int nw) {
            if (nr < 0 || nc < 0 || nr > f.rows - 2 || nc > f.cols - 2 || f.hole(nr, nc)) return false;
            normals[count++] = up_of(triangle_core(nr, nc, nw));
            return true;
        };
        bool open = false;
        if (h.feature == 1) {
            static constexpr int kEdge[2][3][3] = {{{1, 0, 1}, {0, 0, 1}, {0, -1, 1}},
                                                   {{0, 1, 0}, {-1, 0, 0}, {0, 0, 0}}};
            const int* n = kEdge[which][h.index];
            open = !add(r + n[0], c + n[1], n[2]);
        } else {
            int s[3][2];
            f.triangle_samples(r, c, which, s);
            const int vr = s[h.index][0], vc = s[h.index][1];
            // the six triangles around the sample (vr, vc): cells (vr-1, vc-1) T0 and T1, (vr-1, vc) T0, (vr, vc-1) T1,
            // (vr, vc) T0 and T1
            struct Around {
                int dr, dc, which;
            };
            static constexpr Around kAround[6] = {{-1, -1, 0}, {-1, -1, 1}, {-1, 0, 0},
                                                  {0, -1, 1},  {0, 0, 0},   {0, 0, 1}};
            for (const Around& a : kAround) {
                const int nr = vr + a.dr, nc = vc + a.dc;
                if (nr == r && nc == c && a.which == which) continue;
                // A cell this corner belongs to that is not solid (or does not exist) makes the corner part of an open border.
                if (nr < 0 || nc < 0 || nr > f.rows - 2 || nc > f.cols - 2 || f.hole(nr, nc)) {
                    open = true;
                    continue;
                }
                normals[count++] = up_of(triangle_core(nr, nc, a.which));
            }
        }
        if (open) return true;
        float lowest = 1.0f;
        for (int i = 0; i < count; ++i)
            for (int k = i + 1; k < count; ++k) lowest = std::min(lowest, dot(normals[i], normals[k]));
        for (int i = 0; i < count; ++i)
            if (dot(h.normal, normals[i]) < lowest - kConeSlack) return false;
        return true;
    };
    f.for_cells(mlo, mhi, [&](int r, int c) {
        for (int which = 0; which < 2; ++which) {
            const Core T = triangle_core(r, c, which);
            TriHit h;
            if (!field_triangle(T, X, margin, up_of(T), h) || !genuine(r, c, which, h, T)) continue;
            if (!best.hit || h.depth > best.depth + 1e-7f) {
                best.hit = true;
                best.normal = h.normal;
                best.depth = h.depth;
                best.point = h.point;
            }
        }
    });
    if (!best.hit) {
        // Solid ground, deep version: a body wholly below the cell under its centre (the terrain rose under it in one edit,
        // or it was put there) touches no cell of the search above, which skips the cells it is entirely under. It is
        // pushed up along the normal of the triangle over its centre when that cell is solid (a body under a hole fell
        // through it and keeps falling) and the body is at most kHeightfieldSolidDepth (world metres) below the surface
        // there, measured from its lowest bound: deeper than that it is outside the ground and falls on.
        const Vec3 ctr = world_to_frame(field.ax, other.center - field.center) / field.gscale;
        const float fx = (ctr.x - f.x0) / f.dx, fz = (ctr.z - f.z0) / f.dz;
        if (fx >= 0.0f && fx <= float(f.cols - 1) && fz >= 0.0f && fz <= float(f.rows - 1)) {
            const int c = std::min(int(fx), f.cols - 2), r = std::min(int(fz), f.rows - 2);
            float cl, ch;
            if (!f.hole(r, c)) {
                f.cell_range(r, c, cl, ch);
                if (cl > mhi.y) {  // wholly below the lowest sample of the cell
                    const int which = (fz - float(r)) >= (fx - float(c)) ? 0 : 1;
                    Vec3 v[3];
                    f.triangle(r, c, which, v);
                    const Vec3 nm = cross(v[1] - v[0], v[2] - v[0]);  // model space, nm.y = dx * dz > 0
                    const float surface = v[0].y - ((ctr.x - v[0].x) * nm.x + (ctr.z - v[0].z) * nm.z) / nm.y;
                    if ((surface - mlo.y) * field.gscale.y <= kHeightfieldSolidDepth) {
                        const Core T = triangle_core(r, c, which);
                        const Vec3 up = up_of(T);
                        const Vec3 p = core_support(X, -up) - up * X.radius;  // the deepest point of the shape
                        const float depth = dot(T.a - p, up);
                        if (depth > -margin) {
                            best.hit = true;
                            best.normal = up;
                            best.depth = depth;
                            best.point = p + up * (depth * 0.5f);
                        }
                    }
                }
            }
        }
    }
    if (!best.hit || !manifold || (other.kind != Body::Kind::Box && other.kind != Body::Kind::Convex)) return best;
    // A box or hull resting on the field gets one contact point per low corner, probed down onto the surface (as on a mesh).
    const Vec3 n = best.normal;  // field -> other
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
    constexpr int kCap = 16;  // a hull with many vertices in the low band: the first (lowest) 16 are candidates
    Vec3 pts[kCap];
    float depths[kCap];
    std::uint32_t ids[kCap];
    int count = 0;
    Contact m = best;
    for (const auto& [h, idx] : low) {
        if (count >= kCap) break;
        const Vec3 p = cand[idx];
        const Vec3 org = world_to_frame(field.ax, p + n * kProbeLift - field.center) / field.gscale;
        const Vec3 dir = world_to_frame(field.ax, -n) / field.gscale;
        float t = 0.0f;
        Vec3 nl;
        if (!ray_heightfield(f, org, dir, kProbeLift + kLowBand, t, nl)) continue;
        const Vec3 nw = normalize(frame_to_world(field.ax, nl / field.gscale));
        if (dot(nw, n) < 0.8f) continue;  // a wall or a steep neighbour: not part of this face contact
        const float depth = kProbeLift - t;
        if (depth < -kManifoldGap) continue;
        pts[count] = p + n * (depth * 0.5f);
        depths[count] = depth;
        ids[count] = mix_id(0x3E5Cu, std::uint32_t(idx));  // the corner (or hull vertex) of the shape that touches
        ++count;
    }
    if (count > 0) {
        reduce_manifold(m, pts, depths, ids, count);
        return m;
    }
    return best;
}

}  // namespace fa::detail
