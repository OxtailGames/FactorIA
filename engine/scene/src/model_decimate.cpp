// Quadric error decimation (model_decimate.h).
#include <algorithm>
#include <array>
#include <cmath>
#include <queue>

#include "fa/scene/model_decimate.h"

namespace fa {

namespace {

struct D3 {
    double x = 0, y = 0, z = 0;
};
D3 operator+(D3 a, D3 b) { return {a.x + b.x, a.y + b.y, a.z + b.z}; }
D3 operator-(D3 a, D3 b) { return {a.x - b.x, a.y - b.y, a.z - b.z}; }
D3 operator*(D3 a, double s) { return {a.x * s, a.y * s, a.z * s}; }
double dot3(D3 a, D3 b) { return a.x * b.x + a.y * b.y + a.z * b.z; }
D3 cross3(D3 a, D3 b) { return {a.y * b.z - a.z * b.y, a.z * b.x - a.x * b.z, a.x * b.y - a.y * b.x}; }
double len3(D3 a) { return std::sqrt(dot3(a, a)); }

// The sum of squared distances to a set of planes, as a symmetric 4x4 matrix: [a b; b c] with the upper triangle in c[10].
struct Quadric {
    double c[10] = {};
    double area = 0;  // the weight of the face planes (not of the boundary planes): what the error is averaged over
    void add_plane(D3 n, double d, double w) {
        c[0] += w * n.x * n.x;
        c[1] += w * n.x * n.y;
        c[2] += w * n.x * n.z;
        c[3] += w * n.x * d;
        c[4] += w * n.y * n.y;
        c[5] += w * n.y * n.z;
        c[6] += w * n.y * d;
        c[7] += w * n.z * n.z;
        c[8] += w * n.z * d;
        c[9] += w * d * d;
    }
    Quadric operator+(const Quadric& o) const {
        Quadric r;
        for (int i = 0; i < 10; ++i) r.c[i] = c[i] + o.c[i];
        r.area = area + o.area;
        return r;
    }
    double eval(D3 v) const {
        return c[0] * v.x * v.x + 2 * c[1] * v.x * v.y + 2 * c[2] * v.x * v.z + 2 * c[3] * v.x + c[4] * v.y * v.y + 2 * c[5] * v.y * v.z + 2 * c[6] * v.y +
               c[7] * v.z * v.z + 2 * c[8] * v.z + c[9];
    }
    // The point that minimises the error, when the 3x3 part is well conditioned.
    bool optimum(D3& out) const {
        const double a = c[0], b = c[1], cc = c[2], d = c[4], e = c[5], f = c[7];
        const double det = a * (d * f - e * e) - b * (b * f - e * cc) + cc * (b * e - d * cc);
        const double scale = (a + d + f) / 3.0;
        if (std::fabs(det) <= 1.0e-9 * scale * scale * scale) return false;
        const double bx = -c[3], by = -c[6], bz = -c[8];
        out.x = (bx * (d * f - e * e) - b * (by * f - e * bz) + cc * (by * e - d * bz)) / det;
        out.y = (a * (by * f - e * bz) - bx * (b * f - e * cc) + cc * (b * bz - by * cc)) / det;
        out.z = (a * (d * bz - by * e) - b * (b * bz - by * cc) + bx * (b * e - d * cc)) / det;
        return true;
    }
};

struct Entry {
    double cost;       // the quadric error: what the limit is checked against
    double key;        // what orders the heap: the cost plus a small length term, so equal costs (flat regions) go shortest edge first
    std::uint32_t a, b, va, vb;
    D3 pos;
    bool operator<(const Entry& o) const {  // priority_queue pops the greatest: make the cheapest the greatest
        if (key != o.key) return key > o.key;
        if (a != o.a) return a > o.a;
        return b > o.b;
    }
};

struct Decimator {
    std::vector<D3> p;
    std::vector<Quadric> q;
    std::vector<char> onBoundary, vdead;
    std::vector<std::uint32_t> ver;
    std::vector<std::array<std::uint32_t, 3>> tri;
    std::vector<char> tdead;
    std::vector<std::uint32_t> part;
    std::vector<std::vector<std::uint32_t>> vt;
    std::priority_queue<Entry> heap;

    D3 tri_normal(std::uint32_t t) const {
        const auto& v = tri[t];
        return cross3(p[v[1]] - p[v[0]], p[v[2]] - p[v[0]]);
    }

    // The best position for collapsing a and b into one vertex, and its cost.
    bool candidate(std::uint32_t a, std::uint32_t b, D3& pos, double& cost) const {
        const Quadric sum = q[a] + q[b];
        auto pick = [&](std::initializer_list<D3> options) {
            double best = 1e300;
            for (const D3& o : options) {
                const double c = sum.eval(o);
                if (c < best) {
                    best = c;
                    pos = o;
                }
            }
            cost = std::max(best, 0.0);
        };
        if (onBoundary[a] && onBoundary[b]) {
            pick({p[a], p[b], (p[a] + p[b]) * 0.5});
        } else if (onBoundary[a]) {
            pos = p[a];
            cost = std::max(sum.eval(pos), 0.0);
        } else if (onBoundary[b]) {
            pos = p[b];
            cost = std::max(sum.eval(pos), 0.0);
        } else {
            D3 opt;
            const D3 mid = (p[a] + p[b]) * 0.5;
            const double edge = len3(p[a] - p[b]);
            if (sum.optimum(opt) && len3(opt - mid) <= 2.0 * edge + 1.0e-12) {
                pos = opt;
                cost = std::max(sum.eval(pos), 0.0);
            } else {
                pick({p[a], p[b], mid});
            }
        }
        return true;
    }

    void push_edge(std::uint32_t a, std::uint32_t b) {
        if (a > b) std::swap(a, b);
        Entry e;
        e.a = a;
        e.b = b;
        e.va = ver[a];
        e.vb = ver[b];
        candidate(a, b, e.pos, e.cost);
        // Without it the many collapses that cost exactly nothing (a flat region) would all happen in index order and pile every vertex of the
        // region into the first one: a star with thousands of triangles that makes each next collapse slower and the triangles thin. The term is
        // small (a collapse of an edge of length L ranks like an error of 0.3% of L) so real error still decides between different shapes.
        const double len2 = dot3(p[a] - p[b], p[a] - p[b]);
        e.key = e.cost + 1.0e-5 * (q[a].area + q[b].area) * len2;
        heap.push(e);
    }

    static bool has(const std::array<std::uint32_t, 3>& t, std::uint32_t v) { return t[0] == v || t[1] == v || t[2] == v; }

    // Scratch lists for one collapse.
    std::vector<std::uint32_t> shared, onlyA, onlyB, nbrA, nbrB, merged;

    static void add_others(std::vector<std::uint32_t>& out, const std::array<std::uint32_t, 3>& t, std::uint32_t x, std::uint32_t y) {
        for (std::uint32_t v : t)
            if (v != x && v != y) out.push_back(v);
    }

    // Collapses the edge when that is safe; false when it is not (nothing is changed).
    bool collapse(const Entry& e, std::size_t& alive) {
        const std::uint32_t a = e.a, b = e.b;
        shared.clear();
        onlyA.clear();
        onlyB.clear();
        for (std::uint32_t t : vt[a]) {
            if (tdead[t]) continue;
            (has(tri[t], b) ? shared : onlyA).push_back(t);
        }
        for (std::uint32_t t : vt[b])
            if (!tdead[t] && !has(tri[t], a)) onlyB.push_back(t);
        if (shared.size() != 2) return false;
        // Boundaries: two boundary vertices may only merge along a boundary edge.
        if (onBoundary[a] && onBoundary[b] && part[shared[0]] == part[shared[1]]) return false;
        // The link condition: a and b may have only the two opposite vertices of the edge in common.
        nbrA.clear();
        nbrB.clear();
        for (std::uint32_t t : onlyA) add_others(nbrA, tri[t], a, b);
        for (std::uint32_t t : shared) {
            add_others(nbrA, tri[t], a, b);
            add_others(nbrB, tri[t], a, b);
        }
        for (std::uint32_t t : onlyB) add_others(nbrB, tri[t], a, b);
        std::sort(nbrA.begin(), nbrA.end());
        nbrA.erase(std::unique(nbrA.begin(), nbrA.end()), nbrA.end());
        std::sort(nbrB.begin(), nbrB.end());
        nbrB.erase(std::unique(nbrB.begin(), nbrB.end()), nbrB.end());
        std::size_t common = 0;
        for (std::size_t i = 0, j = 0; i < nbrA.size() && j < nbrB.size();) {
            if (nbrA[i] == nbrB[j]) {
                ++common;
                ++i;
                ++j;
            } else if (nbrA[i] < nbrB[j]) {
                ++i;
            } else {
                ++j;
            }
        }
        if (common != 2) return false;
        merged.clear();
        std::set_union(nbrA.begin(), nbrA.end(), nbrB.begin(), nbrB.end(), std::back_inserter(merged));
        if (merged.size() < 3) return false;  // would flatten a tetrahedron into a double-sided sheet
        // No triangle may flip or collapse.
        auto flips = [&](std::uint32_t t, std::uint32_t moved) {
            const D3 no = tri_normal(t);
            const auto saved = p[moved];
            p[moved] = e.pos;
            const D3 nn = tri_normal(t);
            p[moved] = saved;
            const double lo = len3(no), ln = len3(nn);
            if (lo < 1.0e-20) return false;
            return dot3(no, nn) <= 0.1 * lo * ln;
        };
        for (std::uint32_t t : onlyA)
            if (flips(t, a)) return false;
        for (std::uint32_t t : onlyB)
            if (flips(t, b)) return false;

        // do it: b disappears into a
        for (std::uint32_t t : shared) tdead[t] = 1;
        alive -= 2;
        for (std::uint32_t t : onlyB)
            for (std::uint32_t& v : tri[t])
                if (v == b) v = a;
        p[a] = e.pos;
        q[a] = q[a] + q[b];
        onBoundary[a] = onBoundary[a] || onBoundary[b];
        ++ver[a];
        vdead[b] = 1;
        vt[a].clear();
        vt[a].insert(vt[a].end(), onlyA.begin(), onlyA.end());
        vt[a].insert(vt[a].end(), onlyB.begin(), onlyB.end());
        vt[b].clear();
        for (std::uint32_t n : merged) {
            std::erase_if(vt[n], [&](std::uint32_t t) { return tdead[t] != 0; });
            push_edge(a, n);
        }
        return true;
    }
};

}  // namespace

ModelDecimateStats model_decimate(std::vector<Vec3>& positions, std::vector<std::uint32_t>& indices, std::vector<std::uint32_t>& triParts, const ModelDecimateParams& params) {
    ModelDecimateStats stats;
    const std::size_t triCount = indices.size() / 3;
    stats.trianglesBefore = stats.trianglesAfter = triCount;
    if (triCount < 4 || (params.targetTriangles == 0 && params.maxError <= 0)) return stats;

    Decimator d;
    const std::size_t vcount = positions.size();
    d.p.resize(vcount);
    for (std::size_t i = 0; i < vcount; ++i) d.p[i] = {positions[i].x, positions[i].y, positions[i].z};
    d.q.resize(vcount);
    d.onBoundary.assign(vcount, 0);
    d.vdead.assign(vcount, 0);
    d.ver.assign(vcount, 0);
    d.vt.resize(vcount);
    d.tri.resize(triCount);
    d.tdead.assign(triCount, 0);
    d.part.resize(triCount);
    for (std::size_t t = 0; t < triCount; ++t) {
        d.tri[t] = {indices[t * 3], indices[t * 3 + 1], indices[t * 3 + 2]};
        d.part[t] = triParts.size() == triCount ? triParts[t] : 0;
        for (std::uint32_t v : d.tri[t]) d.vt[v].push_back(std::uint32_t(t));
    }

    // face quadrics
    for (std::size_t t = 0; t < triCount; ++t) {
        const D3 n = d.tri_normal(std::uint32_t(t));
        const double l = len3(n);
        if (l < 1.0e-30) continue;
        const D3 u = n * (1.0 / l);
        const double area = 0.5 * l, off = -dot3(u, d.p[d.tri[t][0]]);
        for (std::uint32_t v : d.tri[t]) {
            d.q[v].add_plane(u, off, area);
            d.q[v].area += area;
        }
    }

    // boundaries: edges with one face (a border), more than two, or two faces of different parts
    struct EdgeRef {
        std::uint32_t lo, hi, tri;
        bool operator<(const EdgeRef& o) const { return lo != o.lo ? lo < o.lo : hi != o.hi ? hi < o.hi : tri < o.tri; }
    };
    std::vector<EdgeRef> edges;
    edges.reserve(triCount * 3);
    for (std::size_t t = 0; t < triCount; ++t)
        for (int k = 0; k < 3; ++k) {
            std::uint32_t u = d.tri[t][std::size_t(k)], v = d.tri[t][std::size_t((k + 1) % 3)];
            if (u > v) std::swap(u, v);
            edges.push_back({u, v, std::uint32_t(t)});
        }
    std::sort(edges.begin(), edges.end());
    std::vector<std::pair<std::uint32_t, std::uint32_t>> unique;
    for (std::size_t i = 0; i < edges.size();) {
        std::size_t j = i;
        while (j < edges.size() && edges[j].lo == edges[i].lo && edges[j].hi == edges[i].hi) ++j;
        unique.emplace_back(edges[i].lo, edges[i].hi);
        const std::size_t n = j - i;
        bool boundary = n != 2;
        if (n == 2 && d.part[edges[i].tri] != d.part[edges[i + 1].tri]) boundary = true;
        if (boundary) {
            const std::uint32_t lo = edges[i].lo, hi = edges[i].hi;
            d.onBoundary[lo] = d.onBoundary[hi] = 1;
            const D3 ev = d.p[hi] - d.p[lo];
            const double el = len3(ev);
            for (std::size_t k = i; k < j && el > 1.0e-30; ++k) {
                const D3 fn = d.tri_normal(edges[k].tri);
                const D3 pn = cross3(ev, fn);
                const double pl = len3(pn);
                if (pl < 1.0e-30) continue;
                const D3 u = pn * (1.0 / pl);
                const double w = 100.0 * el * el;  // a boundary moving sideways costs like many faces
                d.q[lo].add_plane(u, -dot3(u, d.p[lo]), w);
                d.q[hi].add_plane(u, -dot3(u, d.p[lo]), w);
            }
        }
        i = j;
    }
    edges = {};

    for (const auto& [u, v] : unique) d.push_edge(u, v);

    std::size_t alive = triCount;
    const std::size_t target = params.targetTriangles;
    while (!d.heap.empty() && (target == 0 || alive > target)) {
        const Entry e = d.heap.top();
        d.heap.pop();
        if (d.vdead[e.a] || d.vdead[e.b] || d.ver[e.a] != e.va || d.ver[e.b] != e.vb) continue;
        const double areaSum = d.q[e.a].area + d.q[e.b].area;
        const double err = areaSum > 0 ? std::sqrt(e.cost / areaSum) : 0.0;
        if (params.maxError > 0 && err > params.maxError) continue;
        if (!d.collapse(e, alive)) continue;
        ++stats.collapses;
        stats.maxErrorReached = std::max(stats.maxErrorReached, err);
    }

    // compact
    std::vector<std::uint32_t> remap(vcount, 0xFFFFFFFFu);
    std::vector<Vec3> outPos;
    std::vector<std::uint32_t> outIdx, outParts;
    for (std::size_t t = 0; t < triCount; ++t) {
        if (d.tdead[t]) continue;
        for (std::uint32_t v : d.tri[t]) {
            if (remap[v] == 0xFFFFFFFFu) remap[v] = std::uint32_t(vcount);  // placeholder: numbered below in vertex order
        }
    }
    std::uint32_t next = 0;
    for (std::size_t v = 0; v < vcount; ++v)
        if (remap[v] != 0xFFFFFFFFu) {
            remap[v] = next++;
            outPos.push_back({float(d.p[v].x), float(d.p[v].y), float(d.p[v].z)});
        }
    for (std::size_t t = 0; t < triCount; ++t) {
        if (d.tdead[t]) continue;
        for (std::uint32_t v : d.tri[t]) outIdx.push_back(remap[v]);
        outParts.push_back(d.part[t]);
    }
    positions = std::move(outPos);
    indices = std::move(outIdx);
    if (triParts.size() == triCount) triParts = std::move(outParts);
    stats.trianglesAfter = indices.size() / 3;
    return stats;
}

}  // namespace fa
