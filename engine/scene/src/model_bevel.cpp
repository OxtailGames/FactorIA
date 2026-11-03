// Bevel: the faces next to a sharp edge are pulled back from it and a strip of rows takes its place (docs/MODELING.md, "bevel").
//
// Method. The surface is welded (Soup). Around each vertex the triangle corners are grouped by walking across the edges that are NOT
// bevelled: a group is one smooth patch of the surface at that vertex. A group touched by two bevelled edges gets a new vertex at the point
// of its patch that is `width` from both edges; a group touched by one gets a vertex `width` from it; a group touched by none keeps the
// vertex. Every original triangle is rebuilt from its groups' vertices. Along each bevelled edge a strip joins the two faces' new edges,
// with `segments` rows on a quadratic curve that bends towards the old edge; where three or more bevelled edges meet, the strips'
// ends and the groups' vertices form a loop that a patch fills. Everything is joined by vertex id, so the result is closed where the
// input was.
#include <algorithm>
#include <cmath>
#include <format>
#include <map>

#include "fa/scene/model_modifiers.h"
#include "model_mesh_ops.h"

namespace fa {

using namespace mm;

namespace {

struct Side {
    std::uint32_t edge;
    std::uint8_t use;
};

struct Groups {
    std::vector<std::uint32_t> of;           // group of each corner (3 per triangle)
    std::vector<std::uint32_t> vertex;       // the welded vertex of each group
    std::vector<std::uint32_t> first;        // its first corner
    std::vector<Vec3> normal;                // area-weighted normal of its triangles
    std::vector<std::vector<Side>> sides;    // bevelled edges that touch it, one entry per face side
};

std::uint32_t find_root(std::vector<std::uint32_t>& p, std::uint32_t x) {
    while (p[x] != x) {
        p[x] = p[p[x]];
        x = p[x];
    }
    return x;
}

int corner_at(const Soup& s, std::uint32_t tri, std::uint32_t v) {
    for (int k = 0; k < 3; ++k)
        if (s.tris[tri][std::size_t(k)] == v) return k;
    return -1;
}

Groups make_groups(const Soup& s, const Edges& e, const std::vector<char>& bev) {
    const std::size_t corners = s.tris.size() * 3;
    std::vector<std::uint32_t> parent(corners);
    for (std::size_t c = 0; c < corners; ++c) parent[c] = std::uint32_t(c);
    for (std::size_t i = 0; i < e.edges.size(); ++i) {
        if (bev[i] || !e.regular(i)) continue;
        const std::uint32_t t0 = e.uses[e.edges[i].first].tri, t1 = e.uses[e.edges[i].first + 1].tri;
        for (std::uint32_t v : {e.edges[i].lo, e.edges[i].hi}) {
            const int c0 = corner_at(s, t0, v), c1 = corner_at(s, t1, v);
            if (c0 < 0 || c1 < 0) continue;
            std::uint32_t a = find_root(parent, t0 * 3 + std::uint32_t(c0)), b = find_root(parent, t1 * 3 + std::uint32_t(c1));
            if (a == b) continue;
            if (a < b) parent[b] = a;
            else parent[a] = b;
        }
    }
    Groups g;
    g.of.assign(corners, 0);
    std::vector<std::uint32_t> id(corners, UINT32_MAX);
    for (std::size_t c = 0; c < corners; ++c) {
        const std::uint32_t r = find_root(parent, std::uint32_t(c));
        if (id[r] == UINT32_MAX) {
            id[r] = std::uint32_t(g.vertex.size());
            g.vertex.push_back(s.tris[c / 3][c % 3]);
            g.first.push_back(std::uint32_t(c));
            g.normal.push_back({0, 0, 0});
        }
        g.of[c] = id[r];
        g.normal[id[r]] += s.face_cross(c / 3);
    }
    g.sides.assign(g.vertex.size(), {});
    for (std::size_t i = 0; i < e.edges.size(); ++i) {
        if (!bev[i]) continue;
        for (std::uint32_t k = 0; k < 2; ++k) {
            const EdgeUse& u = e.uses[e.edges[i].first + k];
            for (std::uint32_t v : {e.edges[i].lo, e.edges[i].hi}) {
                const int c = corner_at(s, u.tri, v);
                g.sides[g.of[u.tri * 3 + std::uint32_t(c)]].push_back({std::uint32_t(i), std::uint8_t(k)});
            }
        }
    }
    return g;
}

struct RowSet {
    std::vector<std::uint32_t> id;
    std::vector<Vec3> normal;
    std::vector<Attr> attr;
};

}  // namespace

Result<ModelMesh> model_bevel(const ModelMesh& m, const ModelBevelParams& p, std::size_t* bevelledEdges) {
    if (bevelledEdges) *bevelledEdges = 0;
    const Soup s = to_soup(m);
    if (s.tris.empty() || p.width <= 0) return m;
    const Edges edges = build_edges(s);
    const std::size_t ec = edges.edges.size();
    std::vector<Vec3> fn(s.tris.size());
    for (std::size_t t = 0; t < s.tris.size(); ++t) fn[t] = unit_or(s.face_cross(t), Vec3{0, 0, 0});
    const float cosA = det::cos(radians(p.angle));
    std::vector<char> bev(ec, 0);
    std::size_t bevCount = 0;
    for (std::size_t i = 0; i < ec; ++i) {
        if (!edges.regular(i)) continue;
        const Vec3 a = fn[edges.uses[edges.edges[i].first].tri], b = fn[edges.uses[edges.edges[i].first + 1].tri];
        if (length_sq(a) < 0.5f || length_sq(b) < 0.5f) continue;
        if (dot(a, b) < cosA) {
            bev[i] = 1;
            ++bevCount;
        }
    }
    if (bevCount == 0) return m;

    // vertices a bevel cannot be built at: an edge with more than two faces, or two faces walking it the same way
    std::vector<char> badVertex(s.pos.size(), 0);
    for (std::size_t i = 0; i < ec; ++i)
        if (edges.edges[i].count > 2 || (edges.edges[i].count == 2 && !edges.regular(i))) badVertex[edges.edges[i].lo] = badVertex[edges.edges[i].hi] = 1;

    Groups groups;
    for (int pass = 0; pass < 64; ++pass) {
        for (std::size_t i = 0; i < ec; ++i)
            if (bev[i] && (badVertex[edges.edges[i].lo] || badVertex[edges.edges[i].hi])) bev[i] = 0;
        groups = make_groups(s, edges, bev);
        bool changed = false;
        for (std::size_t g = 0; g < groups.vertex.size(); ++g) {
            const auto& sd = groups.sides[g];
            const bool invalid = sd.size() >= 3 || (sd.size() == 2 && sd[0].edge == sd[1].edge);
            if (invalid && !badVertex[groups.vertex[g]]) {
                badVertex[groups.vertex[g]] = 1;
                changed = true;
            }
        }
        if (!changed) break;
    }
    bevCount = 0;
    for (char b : bev) bevCount += b ? 1 : 0;
    if (bevelledEdges) *bevelledEdges = bevCount;
    if (bevCount == 0) return m;

    const std::size_t gc = groups.vertex.size();
    // where each group's vertex goes for a width, and whether every face survives it
    std::vector<Vec3> gpos(gc);
    auto place = [&](float w) {
        for (std::size_t g = 0; g < gc; ++g) {
            const std::uint32_t v = groups.vertex[g];
            const Vec3 P = s.pos[v];
            const auto& sd = groups.sides[g];
            gpos[g] = P;
            if (sd.empty()) continue;
            const Vec3 ng = unit_or(groups.normal[g], Vec3{0, 1, 0});
            Vec3 d[2];
            for (std::size_t k = 0; k < sd.size() && k < 2; ++k) {
                const Edges::Edge& ed = edges.edges[sd[k].edge];
                const std::uint32_t other = ed.lo == v ? ed.hi : ed.lo;
                const std::uint32_t tri = edges.uses[ed.first + sd[k].use].tri;
                std::uint32_t third = 0;
                for (std::uint32_t q : s.tris[tri])
                    if (q != v && q != other) third = q;
                Vec3 dir = unit_or(cross(ng, unit_or(s.pos[other] - P, Vec3{1, 0, 0})), Vec3{0, 0, 0});
                if (dot(dir, s.pos[third] - P) < 0) dir = -dir;
                d[k] = dir;
            }
            if (sd.size() == 1) gpos[g] = P + d[0] * w;
            else gpos[g] = P + (d[0] + d[1]) * (w / std::max(1.0f + dot(d[0], d[1]), 0.2f));
        }
        for (std::size_t t = 0; t < s.tris.size(); ++t) {
            const Vec3 nc = cross(gpos[groups.of[t * 3 + 1]] - gpos[groups.of[t * 3]], gpos[groups.of[t * 3 + 2]] - gpos[groups.of[t * 3]]);
            const Vec3 oc = s.face_cross(t);
            if (dot(nc, oc) <= 0.02f * dot(oc, oc)) return false;
            // a face turned half way round (a square whose corners swapped places) keeps its winding: look at its edges too
            for (int k = 0; k < 3; ++k) {
                const std::size_t i0 = t * 3 + std::size_t(k), i1 = t * 3 + std::size_t((k + 1) % 3);
                if (dot(gpos[groups.of[i1]] - gpos[groups.of[i0]], s.pos[s.tris[t][std::size_t((k + 1) % 3)]] - s.pos[s.tris[t][std::size_t(k)]]) <= 0) return false;
            }
        }
        return true;
    };
    float width = p.width;
    bool fits = place(width);
    for (int tries = 0; !fits && tries < 12; ++tries) {
        width *= 0.5f;
        fits = place(width);
    }
    if (width != p.width) {
        if (!fits)
            return make_error(std::format("a bevel of width {} does not fit: the faces next to the sharp edges are smaller than any bevel", p.width),
                              "Lower `width` a lot, or bevel only the larger parts of the model (put the bevel node around them).");
        // report a width that works, rounded down to two significant digits
        const float mag = std::pow(10.0f, std::floor(std::log10(width)) - 1.0f);
        const float shown = std::floor(width / mag) * mag;
        return make_error(std::format("a bevel of width {} is wider than the faces next to the sharp edges can give (a face would turn inside out)", p.width),
                          std::format("Use a width of about {} or less.", shown));
    }

    // ---- build ----------------------------------------------------------------------------------------------------------------
    Soup out;
    out.colors = s.colors;
    std::vector<Vec3> outN;
    std::vector<std::uint32_t> gid(gc);
    std::vector<std::uint32_t> keptVertex(s.pos.size(), UINT32_MAX);
    std::vector<char> hasBevel(s.pos.size(), 0);
    for (std::size_t i = 0; i < ec; ++i)
        if (bev[i]) hasBevel[edges.edges[i].lo] = hasBevel[edges.edges[i].hi] = 1;
    std::vector<Vec3> gnormal(gc);
    std::vector<Attr> gattr(gc);
    for (std::size_t g = 0; g < gc; ++g) {
        const std::uint32_t v = groups.vertex[g];
        if (hasBevel[v]) {
            gid[g] = out.add_vertex(gpos[g]);
        } else {
            if (keptVertex[v] == UINT32_MAX) keptVertex[v] = out.add_vertex(s.pos[v]);
            gid[g] = keptVertex[v];
        }
        const std::uint32_t c = groups.first[g];
        gnormal[g] = m.normals[m.indices[std::size_t(s.src[c / 3]) * 3 + c % 3]];
        gattr[g] = s.attr[c / 3][c % 3];
    }
    const int S = std::max(p.segments, 1);
    const bool round = p.roundness > 0;

    auto emit = [&](std::uint32_t a, std::uint32_t b, std::uint32_t c, const Attr& aa, const Attr& ab, const Attr& ac, std::uint32_t part,
                    Vec3 na, Vec3 nb, Vec3 nc) {
        out.add_tri(a, b, c, aa, ab, ac, part);
        if (!round) {
            na = nb = nc = unit_or(cross(out.pos[b] - out.pos[a], out.pos[c] - out.pos[a]), Vec3{0, 1, 0});
        }
        outN.insert(outN.end(), {na, nb, nc});
    };

    // the original faces, with their own normals
    for (std::size_t t = 0; t < s.tris.size(); ++t) {
        out.add_tri(gid[groups.of[t * 3]], gid[groups.of[t * 3 + 1]], gid[groups.of[t * 3 + 2]], s.attr[t][0], s.attr[t][1], s.attr[t][2], s.part[t]);
        for (std::size_t k = 0; k < 3; ++k) outN.push_back(m.normals[m.indices[std::size_t(s.src[t]) * 3 + k]]);
    }

    // rows between two groups at a vertex, shared by the strips and the corner patch (built once, in the order gmin -> gmax)
    std::map<std::array<std::uint32_t, 3>, RowSet> rowCache;
    struct RowRef {
        const RowSet* set;
        bool reversed;
        std::uint32_t id(int j) const { return set->id[std::size_t(reversed ? S_ - j : j)]; }
        Vec3 normal(int j) const { return set->normal[std::size_t(reversed ? S_ - j : j)]; }
        const Attr& attr(int j) const { return set->attr[std::size_t(reversed ? S_ - j : j)]; }
        int S_;
    };
    auto row = [&](std::uint32_t v, std::uint32_t ga, std::uint32_t gb) {
        const std::uint32_t lo = std::min(ga, gb), hi = std::max(ga, gb);
        const std::array<std::uint32_t, 3> key{v, lo, hi};
        auto it = rowCache.find(key);
        if (it == rowCache.end()) {
            RowSet r;
            const Vec3 p0 = gpos[lo], p2 = gpos[hi], corner = s.pos[v];
            const Vec3 ctl = lerp((p0 + p2) * 0.5f, corner, clamp(p.roundness, 0.0f, 1.0f));
            for (int j = 0; j <= S; ++j) {
                const float t = float(j) / float(S);
                if (j == 0) r.id.push_back(gid[lo]);
                else if (j == S) r.id.push_back(gid[hi]);
                else {
                    const float a = (1 - t) * (1 - t), b = 2 * t * (1 - t), c = t * t;
                    r.id.push_back(out.add_vertex(p0 * a + ctl * b + p2 * c));
                }
                r.normal.push_back(unit_or(lerp(gnormal[lo], gnormal[hi], t), gnormal[lo]));
                r.attr.push_back(lerp_attr(gattr[lo], gattr[hi], t));
            }
            it = rowCache.emplace(key, std::move(r)).first;
        }
        return RowRef{&it->second, ga > gb, S};
    };

    // strips
    for (std::size_t i = 0; i < ec; ++i) {
        if (!bev[i]) continue;
        const Edges::Edge& ed = edges.edges[i];
        const EdgeUse& u0 = edges.uses[ed.first];
        const EdgeUse& u1 = edges.uses[ed.first + 1];
        const EdgeUse& f1 = u0.forward ? u0 : u1;  // walks lo -> hi: its face is on the left
        const EdgeUse& f2 = u0.forward ? u1 : u0;
        auto group_at = [&](const EdgeUse& u, std::uint32_t v) { return groups.of[u.tri * 3 + std::uint32_t(corner_at(s, u.tri, v))]; };
        const RowRef ra = row(ed.lo, group_at(f2, ed.lo), group_at(f1, ed.lo));
        const RowRef rb = row(ed.hi, group_at(f2, ed.hi), group_at(f1, ed.hi));
        for (int j = 0; j < S; ++j) {
            const std::uint32_t part = (float(j) + 0.5f) * 2.0f < float(S) ? s.part[f2.tri] : s.part[f1.tri];
            const std::uint32_t a0 = ra.id(j), a1 = ra.id(j + 1), b0 = rb.id(j), b1 = rb.id(j + 1);
            emit(a0, b0, b1, ra.attr(j), rb.attr(j), rb.attr(j + 1), part, ra.normal(j), rb.normal(j), rb.normal(j + 1));
            emit(a0, b1, a1, ra.attr(j), rb.attr(j + 1), ra.attr(j + 1), part, ra.normal(j), rb.normal(j + 1), ra.normal(j + 1));
        }
    }

    // corner patches where three or more bevelled edges meet
    std::vector<std::vector<std::uint32_t>> vEdges(s.pos.size());
    for (std::size_t i = 0; i < ec; ++i)
        if (bev[i]) {
            vEdges[edges.edges[i].lo].push_back(std::uint32_t(i));
            vEdges[edges.edges[i].hi].push_back(std::uint32_t(i));
        }
    for (std::uint32_t v = 0; v < vEdges.size(); ++v) {
        if (vEdges[v].size() < 3) continue;
        struct Adj {
            std::uint32_t edge, other;
        };
        std::vector<std::uint32_t> gs;
        std::vector<std::vector<Adj>> adj;
        auto slot_of = [&](std::uint32_t g) {
            for (std::size_t k = 0; k < gs.size(); ++k)
                if (gs[k] == g) return k;
            gs.push_back(g);
            adj.emplace_back();
            return gs.size() - 1;
        };
        for (std::uint32_t e : vEdges[v]) {
            const Edges::Edge& ed = edges.edges[e];
            const EdgeUse& u0 = edges.uses[ed.first];
            const EdgeUse& u1 = edges.uses[ed.first + 1];
            const std::uint32_t ga = groups.of[u0.tri * 3 + std::uint32_t(corner_at(s, u0.tri, v))];
            const std::uint32_t gb = groups.of[u1.tri * 3 + std::uint32_t(corner_at(s, u1.tri, v))];
            const std::size_t ia = slot_of(ga), ib = slot_of(gb);
            adj[ia].push_back({e, gb});
            adj[ib].push_back({e, ga});
        }
        std::vector<char> visited(gs.size(), 0);
        for (std::size_t start = 0; start < gs.size(); ++start) {
            if (visited[start] || adj[start].size() != 2) continue;
            std::vector<std::size_t> cycle;
            std::size_t cur = start;
            std::uint32_t prevEdge = UINT32_MAX;
            bool closed = false, broken = false;
            while (true) {
                visited[cur] = 1;
                cycle.push_back(cur);
                if (adj[cur].size() != 2) { broken = true; break; }
                const Adj& step = adj[cur][0].edge != prevEdge ? adj[cur][0] : adj[cur][1];
                prevEdge = step.edge;
                const std::size_t next = slot_of(step.other);
                if (next == start) { closed = true; break; }
                if (visited[next]) { broken = true; break; }
                cur = next;
            }
            if (!closed || broken || cycle.size() < 3) continue;
            struct Pt {
                std::uint32_t id;
                Vec3 normal;
                Attr attr;
            };
            std::vector<Pt> loop;
            for (std::size_t q = 0; q < cycle.size(); ++q) {
                const RowRef r = row(v, gs[cycle[q]], gs[cycle[(q + 1) % cycle.size()]]);
                for (int j = 0; j < S; ++j) loop.push_back({r.id(j), r.normal(j), r.attr(j)});
            }
            Vec3 newell{0, 0, 0}, want{0, 0, 0};
            for (std::size_t q = 0; q < loop.size(); ++q) {
                const Vec3 a = out.pos[loop[q].id], b = out.pos[loop[(q + 1) % loop.size()].id];
                newell += Vec3{(a.y - b.y) * (a.z + b.z), (a.z - b.z) * (a.x + b.x), (a.x - b.x) * (a.y + b.y)};
            }
            for (std::size_t g : cycle) want += gnormal[gs[g]];
            if (dot(newell, want) < 0) std::reverse(loop.begin(), loop.end());
            const std::uint32_t part = s.part[groups.first[gs[cycle[0]]] / 3];
            if (loop.size() == 3) {
                emit(loop[0].id, loop[1].id, loop[2].id, loop[0].attr, loop[1].attr, loop[2].attr, part, loop[0].normal, loop[1].normal, loop[2].normal);
                continue;
            }
            Vec3 avg{0, 0, 0}, avgN{0, 0, 0};
            Attr cattr;
            cattr.uv = {0, 0};
            cattr.color = {0, 0, 0, 0};
            for (const Pt& pt : loop) {
                avg += out.pos[pt.id];
                avgN += pt.normal;
                cattr.uv = cattr.uv + pt.attr.uv;
                cattr.color = cattr.color + pt.attr.color;
            }
            const float inv = 1.0f / float(loop.size());
            avg = avg * inv;
            cattr.uv = cattr.uv * inv;
            cattr.color = cattr.color * inv;
            const std::uint32_t centre = out.add_vertex(avg + (s.pos[v] - avg) * (0.5f * clamp(p.roundness, 0.0f, 1.0f)));
            const Vec3 cn = unit_or(avgN, gnormal[gs[cycle[0]]]);
            for (std::size_t q = 0; q < loop.size(); ++q) {
                const Pt& a = loop[q];
                const Pt& b = loop[(q + 1) % loop.size()];
                emit(centre, a.id, b.id, cattr, a.attr, b.attr, part, cn, a.normal, b.normal);
            }
        }
    }
    return from_soup_normals(out, outN);
}

}  // namespace fa
