#include "shape3d.h"

#include <algorithm>
#include <cmath>
#include <numeric>

namespace fa::detail {

namespace {

constexpr int kLeafTriangles = 4;
constexpr int kMaxHullVertices = 256;

struct Builder {
    ShapeData& d;
    std::vector<Vec3> centroid;
    std::vector<Vec3> lo, hi;  // per triangle

    int build(int first, int count) {
        const int index = int(d.nodes.size());
        d.nodes.emplace_back();
        Vec3 nlo{1e30f, 1e30f, 1e30f}, nhi{-1e30f, -1e30f, -1e30f}, clo = nlo, chi = nhi;
        for (int i = first; i < first + count; ++i) {
            const std::uint32_t t = d.order[i];
            nlo = min(nlo, lo[t]);
            nhi = max(nhi, hi[t]);
            clo = min(clo, centroid[t]);
            chi = max(chi, centroid[t]);
        }
        d.nodes[index].lo = nlo;
        d.nodes[index].hi = nhi;
        if (count <= kLeafTriangles) {
            d.nodes[index].first = first;
            d.nodes[index].count = count;
            return index;
        }
        const Vec3 ext = chi - clo;
        const int axis = (ext.x >= ext.y && ext.x >= ext.z) ? 0 : (ext.y >= ext.z ? 1 : 2);
        auto begin = d.order.begin() + first;
        const int mid = count / 2;
        std::nth_element(begin, begin + mid, begin + count, [&](std::uint32_t a, std::uint32_t b) {
            const float ca = centroid[a][axis], cb = centroid[b][axis];
            return ca != cb ? ca < cb : a < b;  // index tie-break: the same tree on every run
        });
        const int l = build(first, mid);
        const int r = build(first + mid, count - mid);
        d.nodes[index].left = l;
        d.nodes[index].right = r;
        return index;
    }
};

// Extreme vertices in many directions: a cloud of at most kMaxHullVertices points that keeps the shape of the hull.
std::vector<Vec3> reduce_cloud(const std::vector<Vec3>& pts) {
    std::vector<std::uint32_t> ids(pts.size());
    std::iota(ids.begin(), ids.end(), 0u);
    std::sort(ids.begin(), ids.end(), [&](std::uint32_t a, std::uint32_t b) {
        const Vec3 &p = pts[a], &q = pts[b];
        if (p.x != q.x) return p.x < q.x;
        if (p.y != q.y) return p.y < q.y;
        if (p.z != q.z) return p.z < q.z;
        return a < b;
    });
    std::vector<Vec3> unique;
    for (std::uint32_t i : ids)
        if (unique.empty() || !(unique.back() == pts[i])) unique.push_back(pts[i]);
    if (int(unique.size()) <= kMaxHullVertices) return unique;
    std::vector<char> keep(unique.size(), 0);
    const int dirs = kMaxHullVertices - 14;
    auto extreme = [&](Vec3 d) {
        std::size_t best = 0;
        float bestDot = -1e30f;
        for (std::size_t i = 0; i < unique.size(); ++i) {
            const float v = dot(unique[i], d);
            if (v > bestDot) { bestDot = v; best = i; }
        }
        keep[best] = 1;
    };
    for (int s = 0; s < 3; ++s)
        for (float sign : {-1.0f, 1.0f}) {
            Vec3 d{};
            d[s] = sign;
            extreme(d);
        }
    for (int i = 0; i < 8; ++i) extreme(normalize(Vec3{(i & 1) ? 1.0f : -1.0f, (i & 2) ? 1.0f : -1.0f, (i & 4) ? 1.0f : -1.0f}));
    for (int i = 0; i < dirs; ++i) {  // Fibonacci sphere
        const float y = 1.0f - 2.0f * (float(i) + 0.5f) / float(dirs), r = std::sqrt(std::max(0.0f, 1.0f - y * y));
        const float phi = float(i) * 2.39996323f;
        extreme({std::cos(phi) * r, y, std::sin(phi) * r});
    }
    std::vector<Vec3> out;
    for (std::size_t i = 0; i < unique.size(); ++i)
        if (keep[i]) out.push_back(unique[i]);
    return out;
}

}  // namespace

std::shared_ptr<ShapeData> make_shape_data(std::shared_ptr<const MeshGeometry> geometry, bool hull, bool bvh) {
    auto d = std::make_shared<ShapeData>();
    d->geometry = std::move(geometry);
    const MeshGeometry& g = *d->geometry;
    if (hull) d->hull = reduce_cloud(g.positions);
    if (bvh) {
        d->triangles = int(g.indices.size() / 3);
        Builder b{*d, {}, {}, {}};
        b.centroid.resize(d->triangles);
        b.lo.resize(d->triangles);
        b.hi.resize(d->triangles);
        for (int t = 0; t < d->triangles; ++t) {
            const Vec3 p = g.positions[g.indices[t * 3]], q = g.positions[g.indices[t * 3 + 1]],
                       r = g.positions[g.indices[t * 3 + 2]];
            b.lo[t] = min(p, min(q, r));
            b.hi[t] = max(p, max(q, r));
            b.centroid[t] = (p + q + r) / 3.0f;
        }
        d->order.resize(d->triangles);
        std::iota(d->order.begin(), d->order.end(), 0u);
        if (d->triangles > 0) b.build(0, d->triangles);
    }
    return d;
}

bool ray_triangles(const ShapeData& data, Vec3 origin, Vec3 dir, float maxT, float& tOut, std::uint32_t& triOut,
                   Vec3& normal) {
    if (data.nodes.empty()) return false;
    const Vec3 inv{std::fabs(dir.x) > 1e-12f ? 1.0f / dir.x : 1e30f, std::fabs(dir.y) > 1e-12f ? 1.0f / dir.y : 1e30f,
                   std::fabs(dir.z) > 1e-12f ? 1.0f / dir.z : 1e30f};
    float best = maxT;
    bool found = false;
    int stack[64], top = 0;
    stack[top++] = 0;
    while (top > 0) {
        const ShapeData::Node& n = data.nodes[stack[--top]];
        float t0 = 0.0f, t1 = best;
        for (int i = 0; i < 3; ++i) {
            float a = (n.lo[i] - origin[i]) * inv[i], b = (n.hi[i] - origin[i]) * inv[i];
            if (a > b) std::swap(a, b);
            t0 = std::max(t0, a);
            t1 = std::min(t1, b);
        }
        if (t0 > t1) continue;
        if (n.left >= 0) {
            stack[top++] = n.right;
            stack[top++] = n.left;
            continue;
        }
        for (int i = 0; i < n.count; ++i) {
            const std::uint32_t tri = data.order[n.first + i];
            const Vec3 p0 = data.tri_vertex(tri, 0), p1 = data.tri_vertex(tri, 1), p2 = data.tri_vertex(tri, 2);
            const Vec3 e1 = p1 - p0, e2 = p2 - p0, pv = cross(dir, e2);
            const float det = dot(e1, pv);
            if (std::fabs(det) < 1e-12f) continue;
            const float invDet = 1.0f / det;
            const Vec3 tv = origin - p0;
            const float u = dot(tv, pv) * invDet;
            if (u < 0.0f || u > 1.0f) continue;
            const Vec3 qv = cross(tv, e1);
            const float v = dot(dir, qv) * invDet;
            if (v < 0.0f || u + v > 1.0f) continue;
            const float t = dot(e2, qv) * invDet;
            if (t < 0.0f || t > best) continue;
            if (t == best && found && tri > triOut) continue;
            best = t;
            tOut = t;
            triOut = tri;
            Vec3 nn = normalize(cross(e1, e2));
            normal = dot(nn, dir) > 0.0f ? -nn : nn;
            found = true;
        }
    }
    return found;
}

// ---------------------------------------------------------------- cores ----
Vec3 core_support(const Core& c, Vec3 d) {
    switch (c.kind) {
        case Core::Point: return c.a;
        case Core::Segment: return dot(c.b - c.a, d) > 0.0f ? c.b : c.a;
        case Core::Triangle: {
            const float da = dot(c.a, d), db = dot(c.b, d), dc = dot(c.c, d);
            return (da >= db && da >= dc) ? c.a : (db >= dc ? c.b : c.c);
        }
        case Core::Box: {
            Vec3 p = c.a;
            for (int i = 0; i < 3; ++i) p += c.ax[i] * (dot(d, c.ax[i]) >= 0.0f ? c.half[i] : -c.half[i]);
            return p;
        }
        case Core::Hull: {
            // max over v of dot(d, R (S v)) = dot(S R^T d, v)
            const Vec3 dl{dot(d, c.ax[0]) * c.scale.x, dot(d, c.ax[1]) * c.scale.y, dot(d, c.ax[2]) * c.scale.z};
            int best = 0;
            float bestDot = -1e30f;
            for (int i = 0; i < c.count; ++i) {
                const float v = dot(dl, c.verts[i]);
                if (v > bestDot) { bestDot = v; best = i; }
            }
            const Vec3 v = c.verts[best];
            return c.a + c.ax[0] * (v.x * c.scale.x) + c.ax[1] * (v.y * c.scale.y) + c.ax[2] * (v.z * c.scale.z);
        }
    }
    return c.a;
}

namespace {

using Vtx = GjkResult::Vertex;

Vtx make_vertex(const Core& A, const Core& B, Vec3 d) {
    Vtx v;
    v.a = core_support(A, d);
    v.b = core_support(B, -d);
    v.w = v.a - v.b;
    return v;
}

// Closest point to the origin on a segment / triangle / tetrahedron of Minkowski vertices; the simplex is reduced to the
// feature that holds that point and lam gets its barycentric coordinates. Real-Time Collision Detection, 5.1.
Vec3 reduce2(Vtx* s, int& n, float* lam) {
    const Vec3 a = s[0].w, ab = s[1].w - a;
    const float len2 = dot(ab, ab);
    const float t = len2 > 1e-20f ? dot(-a, ab) / len2 : 0.0f;
    if (t <= 0.0f) { n = 1; lam[0] = 1.0f; return a; }
    if (t >= 1.0f) { s[0] = s[1]; n = 1; lam[0] = 1.0f; return s[0].w; }
    lam[0] = 1.0f - t;
    lam[1] = t;
    return a + ab * t;
}

Vec3 reduce3(Vtx* s, int& n, float* lam) {
    const Vec3 a = s[0].w, b = s[1].w, c = s[2].w;
    const Vec3 ab = b - a, ac = c - a;
    const float d1 = dot(ab, -a), d2 = dot(ac, -a);
    if (d1 <= 0.0f && d2 <= 0.0f) { n = 1; lam[0] = 1.0f; return a; }
    const float d3 = dot(ab, -b), d4 = dot(ac, -b);
    if (d3 >= 0.0f && d4 <= d3) { s[0] = s[1]; n = 1; lam[0] = 1.0f; return b; }
    const float vc = d1 * d4 - d3 * d2;
    if (vc <= 0.0f && d1 >= 0.0f && d3 <= 0.0f) {
        const float v = d1 / (d1 - d3);
        n = 2; lam[0] = 1.0f - v; lam[1] = v;
        return a + ab * v;
    }
    const float d5 = dot(ab, -c), d6 = dot(ac, -c);
    if (d6 >= 0.0f && d5 <= d6) { s[0] = s[2]; n = 1; lam[0] = 1.0f; return c; }
    const float vb = d5 * d2 - d1 * d6;
    if (vb <= 0.0f && d2 >= 0.0f && d6 <= 0.0f) {
        const float w = d2 / (d2 - d6);
        s[1] = s[2];
        n = 2; lam[0] = 1.0f - w; lam[1] = w;
        return a + ac * w;
    }
    const float va = d3 * d6 - d5 * d4;
    if (va <= 0.0f && (d4 - d3) >= 0.0f && (d5 - d6) >= 0.0f) {
        const float w = (d4 - d3) / ((d4 - d3) + (d5 - d6));
        s[0] = s[1];
        s[1] = s[2];
        n = 2; lam[0] = 1.0f - w; lam[1] = w;
        return b + (c - b) * w;
    }
    const float denom = 1.0f / (va + vb + vc);
    const float v = vb * denom, w = vc * denom;
    n = 3; lam[0] = 1.0f - v - w; lam[1] = v; lam[2] = w;
    return a + ab * v + ac * w;
}

// Returns false when the origin is inside the tetrahedron.
bool reduce4(Vtx* s, int& n, float* lam, Vec3& closest) {
    static const int faces[4][4] = {{0, 1, 2, 3}, {0, 3, 1, 2}, {0, 2, 3, 1}, {1, 3, 2, 0}};
    float bestD2 = 1e30f;
    bool outside = false;
    Vtx bestS[3];
    int bestN = 0;
    float bestLam[4] = {};
    for (auto& f : faces) {
        const Vec3 vi = s[f[0]].w, vj = s[f[1]].w, vk = s[f[2]].w, vl = s[f[3]].w;
        const Vec3 nrm = cross(vj - vi, vk - vi);
        if (dot(nrm, -vi) * dot(nrm, vl - vi) > 0.0f) continue;  // origin on the same side as the fourth vertex
        outside = true;
        Vtx tri[3] = {s[f[0]], s[f[1]], s[f[2]]};
        int tn = 3;
        float tl[4] = {};
        const Vec3 p = reduce3(tri, tn, tl);
        const float d2 = dot(p, p);
        if (d2 < bestD2) {
            bestD2 = d2;
            closest = p;
            bestN = tn;
            for (int i = 0; i < tn; ++i) { bestS[i] = tri[i]; bestLam[i] = tl[i]; }
        }
    }
    if (!outside) return false;
    n = bestN;
    for (int i = 0; i < n; ++i) { s[i] = bestS[i]; lam[i] = bestLam[i]; }
    return true;
}

}  // namespace

GjkResult gjk(const Core& A, const Core& B) {
    GjkResult out;
    Vec3 dir = B.a - A.a;
    if (length_sq(dir) < 1e-12f) dir = {1, 0.3f, 0.2f};
    Vtx s[4];
    int n = 1;
    s[0] = make_vertex(A, B, dir);
    float lam[4] = {1, 0, 0, 0};
    Vec3 v = s[0].w;
    for (int it = 0; it < 64; ++it) {
        if (n == 1) { v = s[0].w; lam[0] = 1.0f; }
        else if (n == 2) v = reduce2(s, n, lam);
        else if (n == 3) v = reduce3(s, n, lam);
        else if (!reduce4(s, n, lam, v)) { out.overlap = true; break; }
        const float v2 = dot(v, v);
        if (v2 < 1e-12f) { out.overlap = true; break; }
        const Vtx w = make_vertex(A, B, -v);
        if (v2 - dot(v, w.w) <= 1e-6f * v2) break;  // the new support point goes no nearer: converged
        bool dup = false;
        for (int i = 0; i < n; ++i) if (length_sq(s[i].w - w.w) < 1e-14f) dup = true;
        if (dup) break;
        s[n++] = w;
    }
    if (!out.overlap) {  // refresh the barycentric coordinates (stale when the iteration cap ended the loop)
        if (n == 2) reduce2(s, n, lam);
        else if (n == 3) reduce3(s, n, lam);
        else if (n == 4) {
            Vec3 c;
            if (!reduce4(s, n, lam, c)) out.overlap = true;
        }
    }
    for (int i = 0; i < n; ++i) out.v[i] = s[i];
    out.n = n;
    if (!out.overlap) {
        out.pa = out.pb = {};
        for (int i = 0; i < n; ++i) {
            out.pa += s[i].a * lam[i];
            out.pb += s[i].b * lam[i];
        }
        out.dist = length(out.pa - out.pb);
    }
    return out;
}

// ------------------------------------------------------------------ EPA ----
EpaResult epa(const Core& A, const Core& B, const GjkResult& g) {
    struct Face {
        int i[3];
        Vec3 n;
        float d;
        bool alive;
    };
    EpaResult res;
    std::vector<Vtx> vs(g.v, g.v + g.n);
    // Grow the simplex to a tetrahedron around the origin.
    static const Vec3 probes[] = {{1, 0, 0}, {-1, 0, 0}, {0, 1, 0}, {0, -1, 0}, {0, 0, 1}, {0, 0, -1},
                                  {0.577f, 0.577f, 0.577f}, {-0.577f, 0.577f, -0.577f}, {0.577f, -0.577f, -0.577f},
                                  {-0.577f, -0.577f, 0.577f}};
    auto dimension_ok = [&](const std::vector<Vtx>& v) {
        const std::size_t k = v.size();
        if (k == 2) return length_sq(v[1].w - v[0].w) > 1e-10f;
        if (k == 3) return length_sq(cross(v[1].w - v[0].w, v[2].w - v[0].w)) > 1e-10f;
        if (k == 4) return std::fabs(dot(cross(v[1].w - v[0].w, v[2].w - v[0].w), v[3].w - v[0].w)) > 1e-8f;
        return true;
    };
    while (vs.size() < 4) {
        bool grown = false;
        for (const Vec3& p : probes) {
            Vec3 d = p;
            if (vs.size() == 2) {  // perpendicular to the edge
                const Vec3 e = normalize(vs[1].w - vs[0].w);
                d = normalize(p - e * dot(p, e));
                if (length_sq(d) < 0.5f) continue;
            } else if (vs.size() == 3) {  // along the triangle's normal
                d = normalize(cross(vs[1].w - vs[0].w, vs[2].w - vs[0].w));
                if (p.x < 0.0f || (p.x == 0.0f && p.y < 0.0f) || (p.x == 0.0f && p.y == 0.0f && p.z < 0.0f)) d = -d;
            }
            std::vector<Vtx> trial = vs;
            trial.push_back(make_vertex(A, B, d));
            if (dimension_ok(trial)) { vs = std::move(trial); grown = true; break; }
        }
        if (!grown) return res;
    }
    std::vector<Face> faces;
    const Vec3 inside = (vs[0].w + vs[1].w + vs[2].w + vs[3].w) * 0.25f;  // stays inside the growing polytope
    auto add_face = [&](int a, int b, int c) {
        Face f{{a, b, c}, normalize(cross(vs[b].w - vs[a].w, vs[c].w - vs[a].w)), 0.0f, true};
        if (dot(f.n, inside - vs[a].w) > 0.0f) { std::swap(f.i[1], f.i[2]); f.n = -f.n; }
        f.d = std::max(dot(f.n, vs[a].w), 0.0f);
        faces.push_back(f);
    };
    add_face(0, 1, 2);
    add_face(0, 3, 1);
    add_face(0, 2, 3);
    add_face(1, 3, 2);
    int best = 0;
    for (int iter = 0; iter < 64; ++iter) {
        best = -1;
        for (int i = 0; i < int(faces.size()); ++i)
            if (faces[i].alive && (best < 0 || faces[i].d < faces[best].d)) best = i;
        if (best < 0) return res;
        const Face f = faces[best];
        const Vtx w = make_vertex(A, B, f.n);
        if (dot(w.w, f.n) - f.d < 1e-4f) break;
        // Faces visible from w are replaced by a cone from w to the horizon.
        std::vector<std::pair<int, int>> horizon;
        for (Face& q : faces) {
            if (!q.alive || dot(q.n, w.w - vs[q.i[0]].w) <= 1e-6f) continue;
            q.alive = false;
            for (int e = 0; e < 3; ++e) {
                const std::pair<int, int> edge{q.i[e], q.i[(e + 1) % 3]};
                auto rev = std::find(horizon.begin(), horizon.end(), std::pair<int, int>{edge.second, edge.first});
                if (rev != horizon.end()) horizon.erase(rev);
                else horizon.push_back(edge);
            }
        }
        if (horizon.empty()) break;
        const int wi = int(vs.size());
        vs.push_back(w);
        for (auto& e : horizon) add_face(e.first, e.second, wi);
    }
    best = -1;
    for (int i = 0; i < int(faces.size()); ++i)
        if (faces[i].alive && (best < 0 || faces[i].d < faces[best].d)) best = i;
    if (best < 0) return res;
    const Face& f = faces[best];
    // Barycentric coordinates of the origin's projection onto the face.
    const Vec3 p = f.n * f.d, a = vs[f.i[0]].w, b = vs[f.i[1]].w, c = vs[f.i[2]].w;
    const Vec3 v0 = b - a, v1 = c - a, v2 = p - a;
    const float d00 = dot(v0, v0), d01 = dot(v0, v1), d11 = dot(v1, v1), d20 = dot(v2, v0), d21 = dot(v2, v1);
    const float den = d00 * d11 - d01 * d01;
    float u = 1.0f / 3.0f, w = 1.0f / 3.0f;
    if (std::fabs(den) > 1e-14f) {
        const float vv = (d11 * d20 - d01 * d21) / den, ww = (d00 * d21 - d01 * d20) / den;
        u = 1.0f - vv - ww;
        w = ww;
        const float v = vv;
        res.pa = vs[f.i[0]].a * u + vs[f.i[1]].a * v + vs[f.i[2]].a * w;
        res.pb = vs[f.i[0]].b * u + vs[f.i[1]].b * v + vs[f.i[2]].b * w;
    } else {
        res.pa = (vs[f.i[0]].a + vs[f.i[1]].a + vs[f.i[2]].a) / 3.0f;
        res.pb = (vs[f.i[0]].b + vs[f.i[1]].b + vs[f.i[2]].b) / 3.0f;
    }
    res.normal = f.n;
    res.depth = f.d;
    res.ok = true;
    return res;
}

}  // namespace fa::detail
