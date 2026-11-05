// Catmull-Clark subdivision (docs/MODELING.md, "subdivide").
//
// The welded triangles are first joined back into quads where two coplanar triangles of one part form a convex quad, so a box made of
// 12 triangles subdivides like a box of 6 quads. Each level then turns every n-gon into n quads (face point, edge point, vertex point,
// edge point) with the classic rules; open boundaries, edges used by more than two faces and edges whose faces turn by more than
// `creaseAngle` are creases: their edge points are midpoints and their vertices follow the cubic B-spline curve (two creases) or stay
// (a corner). Texture coordinates and colours are interpolated linearly over each face (they are per corner, so seams survive).
#include <algorithm>
#include <cmath>

#include "fa/scene/model_modifiers.h"
#include "model_mesh_ops.h"

namespace fa {

using namespace mm;

namespace {

struct Face {
    int n = 3;
    std::uint32_t v[4]{};
    Attr a[4]{};
    bool crease[4]{};  // side i runs from corner i to corner i + 1
    std::uint32_t part = 0;
};

Vec3 newell_normal(const std::vector<Vec3>& pos, const Face& f) {
    Vec3 n{0, 0, 0};
    for (int i = 0; i < f.n; ++i) {
        const Vec3 a = pos[f.v[i]], b = pos[f.v[(i + 1) % f.n]];
        n += Vec3{(a.y - b.y) * (a.z + b.z), (a.z - b.z) * (a.x + b.x), (a.x - b.x) * (a.y + b.y)};
    }
    return unit_or(n, Vec3{0, 0, 0});
}

struct EdgeRec {
    std::uint32_t lo, hi, face;
    std::uint8_t slot;
};

Attr average_attr(const Attr* a, int n) {
    Attr r;
    r.uv = {0, 0};
    r.color = {0, 0, 0, 0};
    for (int i = 0; i < n; ++i) {
        r.uv = r.uv + a[i].uv;
        r.color = r.color + a[i].color;
    }
    const float inv = 1.0f / float(n);
    r.uv = r.uv * inv;
    r.color = r.color * inv;
    return r;
}

// Joins coplanar triangle pairs into quads. Edges are visited in sorted order, so the result depends only on the input.
std::vector<Face> make_faces(const Soup& s) {
    const Edges edges = build_edges(s);
    const std::size_t tc = s.tris.size();
    std::vector<char> used(tc, 0);
    std::vector<Face> quads;
    std::vector<Vec3> fn(tc);
    for (std::size_t t = 0; t < tc; ++t) fn[t] = unit_or(s.face_cross(t), Vec3{0, 0, 0});
    std::vector<std::pair<std::uint32_t, std::uint32_t>> pairs;  // (first triangle, second triangle) in visiting order
    std::vector<std::array<std::uint32_t, 2>> slots;
    for (std::size_t e = 0; e < edges.edges.size(); ++e) {
        if (!edges.regular(e)) continue;
        const EdgeUse& u0 = edges.uses[edges.edges[e].first];
        const EdgeUse& u1 = edges.uses[edges.edges[e].first + 1];
        if (used[u0.tri] || used[u1.tri] || s.part[u0.tri] != s.part[u1.tri]) continue;
        if (dot(fn[u0.tri], fn[u1.tri]) < 0.99985f) continue;
        // t1 walks x -> y, t2 walks y -> x; the quad (counter-clockwise) is x, z2, y, z1
        const EdgeUse& f1 = u0;
        const EdgeUse& f2 = u1;
        const std::uint32_t x = s.tris[f1.tri][f1.slot], y = s.tris[f1.tri][(f1.slot + 1) % 3], z1 = s.tris[f1.tri][(f1.slot + 2) % 3];
        const std::uint32_t z2 = s.tris[f2.tri][(f2.slot + 2) % 3];
        if (z1 == z2) continue;
        const Vec3 q[4] = {s.pos[x], s.pos[z2], s.pos[y], s.pos[z1]};
        bool convex = true;
        for (int i = 0; i < 4; ++i) {
            const Vec3 c = cross(q[(i + 1) % 4] - q[i], q[(i + 2) % 4] - q[(i + 1) % 4]);
            if (dot(c, fn[f1.tri]) <= 1e-12f) convex = false;
        }
        if (!convex) continue;
        used[f1.tri] = used[f2.tri] = 1;
        Face f;
        f.n = 4;
        f.v[0] = x; f.v[1] = z2; f.v[2] = y; f.v[3] = z1;
        f.a[0] = s.attr[f1.tri][f1.slot];
        f.a[1] = s.attr[f2.tri][(f2.slot + 2) % 3];
        f.a[2] = s.attr[f1.tri][(f1.slot + 1) % 3];
        f.a[3] = s.attr[f1.tri][(f1.slot + 2) % 3];
        f.part = s.part[f1.tri];
        quads.push_back(f);
    }
    std::vector<Face> faces;
    faces.reserve(tc);
    // quads first (in edge order), then the triangles that were not merged (in triangle order): both depend only on the input
    for (const Face& q : quads) faces.push_back(q);
    for (std::size_t t = 0; t < tc; ++t) {
        if (used[t]) continue;
        Face f;
        f.n = 3;
        for (int k = 0; k < 3; ++k) {
            f.v[k] = s.tris[t][std::size_t(k)];
            f.a[k] = s.attr[t][std::size_t(k)];
        }
        f.part = s.part[t];
        faces.push_back(f);
    }
    return faces;
}

void subdivide_once(std::vector<Vec3>& pos, std::vector<Face>& faces, bool first, float creaseCos, bool anyCrease) {
    const std::size_t nv = pos.size(), nf = faces.size();
    std::vector<EdgeRec> recs;
    recs.reserve(nf * 4);
    for (std::size_t f = 0; f < nf; ++f)
        for (int i = 0; i < faces[f].n; ++i) {
            const std::uint32_t a = faces[f].v[i], b = faces[f].v[(i + 1) % faces[f].n];
            recs.push_back({std::min(a, b), std::max(a, b), std::uint32_t(f), std::uint8_t(i)});
        }
    std::sort(recs.begin(), recs.end(), [](const EdgeRec& x, const EdgeRec& y) {
        if (x.lo != y.lo) return x.lo < y.lo;
        if (x.hi != y.hi) return x.hi < y.hi;
        if (x.face != y.face) return x.face < y.face;
        return x.slot < y.slot;
    });
    struct EdgeInfo {
        std::uint32_t lo, hi;
        std::uint32_t f0 = UINT32_MAX, f1 = UINT32_MAX;
        int count = 0;
        bool crease = false;
        bool flagged = false;
    };
    std::vector<EdgeInfo> einfo;
    std::vector<std::uint32_t> edgeOf(nf * 4, 0);
    std::vector<Vec3> faceNormal;
    if (first && anyCrease) {
        faceNormal.resize(nf);
        for (std::size_t f = 0; f < nf; ++f) faceNormal[f] = newell_normal(pos, faces[f]);
    }
    for (std::size_t i = 0; i < recs.size(); ++i) {
        if (i == 0 || recs[i].lo != recs[i - 1].lo || recs[i].hi != recs[i - 1].hi) {
            EdgeInfo e;
            e.lo = recs[i].lo;
            e.hi = recs[i].hi;
            einfo.push_back(e);
        }
        EdgeInfo& e = einfo.back();
        if (e.count == 0) e.f0 = recs[i].face;
        else if (e.count == 1) e.f1 = recs[i].face;
        ++e.count;
        if (faces[recs[i].face].crease[recs[i].slot]) e.flagged = true;
        edgeOf[std::size_t(recs[i].face) * 4 + recs[i].slot] = std::uint32_t(einfo.size() - 1);
    }
    for (EdgeInfo& e : einfo) {
        e.crease = e.count != 2 || e.flagged;
        if (!e.crease && first && anyCrease && dot(faceNormal[e.f0], faceNormal[e.f1]) < creaseCos) e.crease = true;
    }
    const std::size_t ne = einfo.size();

    // face points
    std::vector<Vec3> facePt(nf);
    std::vector<Attr> faceAttr(nf);
    for (std::size_t f = 0; f < nf; ++f) {
        Vec3 sum{0, 0, 0};
        for (int i = 0; i < faces[f].n; ++i) sum += pos[faces[f].v[i]];
        facePt[f] = sum / float(faces[f].n);
        faceAttr[f] = average_attr(faces[f].a, faces[f].n);
    }
    // edge points
    std::vector<Vec3> edgePt(ne);
    for (std::size_t e = 0; e < ne; ++e) {
        const Vec3 mid = (pos[einfo[e].lo] + pos[einfo[e].hi]) * 0.5f;
        if (einfo[e].crease || einfo[e].count != 2) edgePt[e] = mid;
        else edgePt[e] = (pos[einfo[e].lo] + pos[einfo[e].hi] + facePt[einfo[e].f0] + facePt[einfo[e].f1]) * 0.25f;
    }
    // vertex points
    std::vector<Vec3> fsum(nv, Vec3{0, 0, 0}), rsum(nv, Vec3{0, 0, 0}), csum(nv, Vec3{0, 0, 0});
    std::vector<int> nF(nv, 0), nE(nv, 0), nC(nv, 0);
    for (std::size_t f = 0; f < nf; ++f)
        for (int i = 0; i < faces[f].n; ++i) {
            fsum[faces[f].v[i]] += facePt[f];
            ++nF[faces[f].v[i]];
        }
    for (std::size_t e = 0; e < ne; ++e) {
        const std::uint32_t a = einfo[e].lo, b = einfo[e].hi;
        const Vec3 mid = (pos[a] + pos[b]) * 0.5f;
        rsum[a] += mid; rsum[b] += mid;
        ++nE[a]; ++nE[b];
        if (einfo[e].crease) {
            ++nC[a]; ++nC[b];
            csum[a] += pos[b];
            csum[b] += pos[a];
        }
    }
    std::vector<Vec3> newPos(nv + ne + nf);
    for (std::size_t v = 0; v < nv; ++v) {
        const Vec3 P = pos[v];
        if (nF[v] == 0) newPos[v] = P;
        else if (nC[v] == 0) {
            const int n = nE[v];
            if (n < 3) newPos[v] = P;
            else newPos[v] = (fsum[v] / float(nF[v]) + rsum[v] / float(n) * 2.0f + P * float(n - 3)) / float(n);
        } else if (nC[v] == 2) newPos[v] = (P * 6.0f + csum[v]) * 0.125f;
        else newPos[v] = P;
    }
    for (std::size_t e = 0; e < ne; ++e) newPos[nv + e] = edgePt[e];
    for (std::size_t f = 0; f < nf; ++f) newPos[nv + ne + f] = facePt[f];

    std::vector<Face> out;
    out.reserve(nf * 4);
    for (std::size_t f = 0; f < nf; ++f) {
        const Face& src = faces[f];
        const int n = src.n;
        Attr edgeAttr[4];
        for (int i = 0; i < n; ++i) edgeAttr[i] = lerp_attr(src.a[i], src.a[(i + 1) % n], 0.5f);
        for (int i = 0; i < n; ++i) {
            const int prev = (i + n - 1) % n;
            Face q;
            q.n = 4;
            q.part = src.part;
            q.v[0] = src.v[i];
            q.v[1] = std::uint32_t(nv) + edgeOf[f * 4 + std::size_t(i)];
            q.v[2] = std::uint32_t(nv + ne + f);
            q.v[3] = std::uint32_t(nv) + edgeOf[f * 4 + std::size_t(prev)];
            q.a[0] = src.a[i];
            q.a[1] = edgeAttr[i];
            q.a[2] = faceAttr[f];
            q.a[3] = edgeAttr[prev];
            q.crease[0] = einfo[edgeOf[f * 4 + std::size_t(i)]].crease;
            q.crease[3] = einfo[edgeOf[f * 4 + std::size_t(prev)]].crease;
            out.push_back(q);
        }
    }
    pos.swap(newPos);
    faces.swap(out);
}

}  // namespace

std::size_t model_subdivide_triangle_bound(const ModelMesh& m, int levels) {
    if (levels <= 0) return m.triangle_count();
    double tris = double(m.triangle_count()) * 6.0;  // a triangle gives three quads, a quad four; two triangles per quad
    for (int l = 1; l < levels && tris < 1e12; ++l) tris *= 4.0;
    return tris > 1e12 ? std::size_t(1e12) : std::size_t(tris);
}

ModelMesh model_subdivide(const ModelMesh& m, const ModelSubdivideParams& p) {
    if (p.levels <= 0) return m;
    const Soup s = to_soup(m);
    if (s.tris.empty()) return m;
    std::vector<Face> faces = make_faces(s);
    std::vector<Vec3> pos = s.pos;
    const bool anyCrease = p.creaseAngle < 179.999f;
    const float creaseCos = det::cos(radians(p.creaseAngle));
    for (int l = 0; l < p.levels; ++l) subdivide_once(pos, faces, l == 0, creaseCos, anyCrease);

    Soup out;
    out.pos = std::move(pos);
    out.colors = s.colors;
    out.tris.reserve(faces.size() * 2);
    for (const Face& f : faces) {
        out.add_tri(f.v[0], f.v[1], f.v[2], f.a[0], f.a[1], f.a[2], f.part);
        if (f.n == 4) out.add_tri(f.v[0], f.v[2], f.v[3], f.a[0], f.a[2], f.a[3], f.part);
    }
    return from_soup(out, p.creaseAngle);
}

}  // namespace fa
