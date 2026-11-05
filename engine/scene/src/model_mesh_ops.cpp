// Shared helpers of the modifiers: welding by distance, the triangle soup, edges, normals by smoothing angle.
#include "model_mesh_ops.h"

#include <algorithm>
#include <cmath>
#include <cstring>
#include <map>
#include <unordered_map>

#include "fa/core/det_math.h"

namespace fa::mm {

namespace {

struct CellKey {
    std::int64_t x, y, z;
    bool operator==(const CellKey& o) const { return x == o.x && y == o.y && z == o.z; }
};
struct CellHash {
    std::size_t operator()(const CellKey& k) const {
        std::uint64_t h = 1469598103934665603ull;
        for (std::int64_t v : {k.x, k.y, k.z}) {
            h ^= static_cast<std::uint64_t>(v);
            h *= 1099511628211ull;
        }
        return static_cast<std::size_t>(h);
    }
};

struct VertexKey {
    std::array<std::uint32_t, 12> w;
    bool operator==(const VertexKey& o) const { return w == o.w; }
};
struct VertexKeyHash {
    std::size_t operator()(const VertexKey& k) const {
        std::uint64_t h = 1469598103934665603ull;
        for (std::uint32_t v : k.w) {
            h ^= v;
            h *= 1099511628211ull;
        }
        return static_cast<std::size_t>(h);
    }
};

std::uint32_t bits(float f) {
    f += 0.0f;  // -0 -> +0
    std::uint32_t u;
    std::memcpy(&u, &f, sizeof u);
    return u;
}

}  // namespace

float angle_deg(Vec3 a, Vec3 b) {
    const float d = clamp(dot(a, b), -1.0f, 1.0f);
    return degrees(det::acos(d));
}

Vec3 unit_or(Vec3 v, Vec3 fallback) {
    const float l = length(v);
    return l > 1e-20f ? v / l : fallback;
}

std::vector<std::uint32_t> cluster_points(const std::vector<Vec3>& points, float distance, std::vector<Vec3>* centers) {
    std::vector<std::uint32_t> id(points.size(), 0);
    const float cell = std::max(distance, 1e-9f);
    const float inv = 1.0f / cell;
    std::unordered_map<CellKey, std::vector<std::uint32_t>, CellHash> grid;  // cell -> cluster ids whose first point is in it
    std::vector<std::uint32_t> first;                                          // cluster id -> its first point
    std::vector<Vec3> sum;
    std::vector<std::uint32_t> count;
    const float d2 = distance * distance;
    for (std::size_t i = 0; i < points.size(); ++i) {
        const Vec3& p = points[i];
        const CellKey c{std::int64_t(std::floor(p.x * inv)), std::int64_t(std::floor(p.y * inv)), std::int64_t(std::floor(p.z * inv))};
        std::uint32_t found = UINT32_MAX;
        float best = 0;
        for (std::int64_t dx = -1; dx <= 1; ++dx)
            for (std::int64_t dy = -1; dy <= 1; ++dy)
                for (std::int64_t dz = -1; dz <= 1; ++dz) {
                    auto it = grid.find({c.x + dx, c.y + dy, c.z + dz});
                    if (it == grid.end()) continue;
                    for (std::uint32_t cl : it->second) {
                        const float dd = length_sq(points[first[cl]] - p);
                        if (dd <= d2 && (found == UINT32_MAX || dd < best || (dd == best && cl < found))) {
                            found = cl;
                            best = dd;
                        }
                    }
                }
        if (found == UINT32_MAX) {
            found = std::uint32_t(first.size());
            first.push_back(std::uint32_t(i));
            sum.push_back({0, 0, 0});
            count.push_back(0);
            grid[c].push_back(found);
        }
        id[i] = found;
        sum[found] = sum[found] + p;
        ++count[found];
    }
    if (centers) {
        centers->resize(first.size());
        for (std::size_t k = 0; k < first.size(); ++k) (*centers)[k] = sum[k] / float(count[k]);
    }
    return id;
}

Soup to_soup(const ModelMesh& m, float tolerance, std::vector<std::uint32_t>* welded) {
    Soup s;
    s.colors = !m.colors.empty();
    std::vector<std::uint32_t> id = cluster_points(m.positions, tolerance);
    if (welded) *welded = id;
    // the welded position of a cluster is its first vertex
    std::uint32_t clusters = 0;
    for (std::uint32_t v : id) clusters = std::max(clusters, v + 1);
    s.pos.assign(clusters, Vec3{});
    std::vector<char> seen(clusters, 0);
    for (std::size_t i = 0; i < id.size(); ++i)
        if (!seen[id[i]]) {
            seen[id[i]] = 1;
            s.pos[id[i]] = m.positions[i];
        }
    const std::size_t tris = m.triangle_count();
    s.tris.reserve(tris);
    s.attr.reserve(tris);
    s.part.reserve(tris);
    for (std::size_t t = 0; t < tris; ++t) {
        std::array<std::uint32_t, 3> ids{};
        std::array<Attr, 3> at;
        for (int k = 0; k < 3; ++k) {
            const std::uint32_t v = m.indices[t * 3 + std::size_t(k)];
            ids[std::size_t(k)] = id[v];
            at[std::size_t(k)].uv = v < m.uvs.size() ? m.uvs[v] : Vec2{};
            at[std::size_t(k)].color = v < m.colors.size() ? m.colors[v] : Vec4{1, 1, 1, 1};
        }
        if (ids[0] == ids[1] || ids[1] == ids[2] || ids[0] == ids[2]) continue;  // collapsed by the weld: no area
        s.tris.push_back(ids);
        s.attr.push_back(at);
        s.part.push_back(t < m.triParts.size() ? m.triParts[t] : 0);
        s.src.push_back(std::uint32_t(t));
    }
    return s;
}

std::vector<Vec3> corner_normals(const Soup& s, float creaseDeg) {
    const std::size_t tc = s.tris.size();
    std::vector<Vec3> fn(tc);
    std::vector<std::array<float, 3>> angle(tc);
    for (std::size_t t = 0; t < tc; ++t) {
        const auto& ids = s.tris[t];
        fn[t] = unit_or(s.face_cross(t), Vec3{0, 0, 0});
        for (int k = 0; k < 3; ++k) {
            const Vec3 p = s.pos[ids[std::size_t(k)]];
            const Vec3 e1 = s.pos[ids[std::size_t((k + 1) % 3)]] - p, e2 = s.pos[ids[std::size_t((k + 2) % 3)]] - p;
            const float l1 = length(e1), l2 = length(e2);
            if (l1 < 1e-20f || l2 < 1e-20f) {
                angle[t][std::size_t(k)] = 0;
                continue;
            }
            const float c = length(cross(e1, e2)), d = dot(e1, e2);
            angle[t][std::size_t(k)] = det::atan2(c, d);
        }
    }
    // corners around each welded vertex (counting sort)
    std::vector<std::uint32_t> start(s.pos.size() + 1, 0);
    for (const auto& ids : s.tris)
        for (std::uint32_t v : ids) ++start[v + 1];
    for (std::size_t v = 0; v < s.pos.size(); ++v) start[v + 1] += start[v];
    std::vector<std::uint32_t> list(tc * 3);
    {
        std::vector<std::uint32_t> cursor(start.begin(), start.end() - 1);
        for (std::size_t t = 0; t < tc; ++t)
            for (int k = 0; k < 3; ++k) list[cursor[s.tris[t][std::size_t(k)]]++] = std::uint32_t(t * 3 + std::size_t(k));
    }
    const bool all = creaseDeg >= 179.999f;
    const float cosCrease = det::cos(radians(creaseDeg));
    std::vector<Vec3> out(tc * 3);
    for (std::size_t v = 0; v < s.pos.size(); ++v) {
        for (std::uint32_t a = start[v]; a < start[v + 1]; ++a) {
            const std::size_t ta = list[a] / 3;
            Vec3 sum{0, 0, 0};
            for (std::uint32_t b = start[v]; b < start[v + 1]; ++b) {
                const std::size_t tb = list[b] / 3, kb = list[b] % 3;
                if (!all && ta != tb && dot(fn[ta], fn[tb]) < cosCrease) continue;
                sum = sum + fn[tb] * angle[tb][kb];
            }
            Vec3 n = unit_or(sum, fn[ta]);
            if (length_sq(n) < 0.5f) n = Vec3{0, 1, 0};
            out[list[a]] = n;
        }
    }
    return out;
}

ModelMesh dedup_vertices(const ModelMesh& m) {
    ModelMesh out;
    std::unordered_map<VertexKey, std::uint32_t, VertexKeyHash> index;
    index.reserve(m.positions.size());
    std::vector<std::uint32_t> remap(m.positions.size());
    const bool hasUv = m.uvs.size() == m.positions.size(), hasColor = m.colors.size() == m.positions.size();
    for (std::size_t v = 0; v < m.positions.size(); ++v) {
        const Vec3 p = m.positions[v], n = v < m.normals.size() ? m.normals[v] : Vec3{};
        const Vec2 uv = hasUv ? m.uvs[v] : Vec2{};
        const Vec4 c = hasColor ? m.colors[v] : Vec4{1, 1, 1, 1};
        VertexKey key{{bits(p.x), bits(p.y), bits(p.z), bits(n.x), bits(n.y), bits(n.z), bits(uv.x), bits(uv.y), bits(c.x), bits(c.y), bits(c.z), bits(c.w)}};
        auto [it, fresh] = index.emplace(key, std::uint32_t(out.positions.size()));
        if (fresh) {
            out.positions.push_back(p);
            out.normals.push_back(n);
            out.uvs.push_back(uv);
            if (hasColor) out.colors.push_back(c);
        }
        remap[v] = it->second;
    }
    out.indices.reserve(m.indices.size());
    for (std::uint32_t i : m.indices) out.indices.push_back(remap[i]);
    out.triParts = m.triParts;
    return out;
}

ModelMesh drop_degenerate(const ModelMesh& m) {
    ModelMesh out = m;
    out.indices.clear();
    out.triParts.clear();
    // corners within the weld tolerance of each other are one point of the surface: a triangle with two of them has collapsed
    const std::vector<std::uint32_t> cluster = cluster_points(m.positions, kWeldTolerance);
    for (std::size_t t = 0; t < m.triangle_count(); ++t) {
        const std::uint32_t a = m.indices[t * 3], b = m.indices[t * 3 + 1], c = m.indices[t * 3 + 2];
        if (a == b || b == c || a == c) continue;
        if (cluster[a] == cluster[b] || cluster[b] == cluster[c] || cluster[a] == cluster[c]) continue;
        if (length_sq(cross(m.positions[b] - m.positions[a], m.positions[c] - m.positions[a])) < 1e-24f) continue;
        out.indices.insert(out.indices.end(), {a, b, c});
        out.triParts.push_back(t < m.triParts.size() ? m.triParts[t] : 0);
    }
    return out;
}

ModelMesh from_soup_normals(const Soup& s, const std::vector<Vec3>& normals) {
    ModelMesh m;
    std::unordered_map<VertexKey, std::uint32_t, VertexKeyHash> index;
    index.reserve(s.tris.size() * 2);
    m.indices.reserve(s.tris.size() * 3);
    m.triParts.reserve(s.tris.size());
    for (std::size_t t = 0; t < s.tris.size(); ++t) {
        for (int k = 0; k < 3; ++k) {
            const Vec3 p = s.pos[s.tris[t][std::size_t(k)]];
            const Vec3 n = normals[t * 3 + std::size_t(k)];
            const Attr& a = s.attr[t][std::size_t(k)];
            VertexKey key{{bits(p.x), bits(p.y), bits(p.z), bits(n.x), bits(n.y), bits(n.z), bits(a.uv.x), bits(a.uv.y), bits(a.color.x), bits(a.color.y),
                           bits(a.color.z), bits(a.color.w)}};
            auto [it, fresh] = index.emplace(key, std::uint32_t(m.positions.size()));
            if (fresh) {
                m.positions.push_back(p);
                m.normals.push_back(n);
                m.uvs.push_back(a.uv);
                if (s.colors) m.colors.push_back(a.color);
            }
            m.indices.push_back(it->second);
        }
        m.triParts.push_back(s.part[t]);
    }
    return m;
}

ModelMesh from_soup(const Soup& s, float creaseDeg, bool flat) {
    if (flat) {
        std::vector<Vec3> n(s.tris.size() * 3);
        for (std::size_t t = 0; t < s.tris.size(); ++t) {
            const Vec3 fn = unit_or(s.face_cross(t), Vec3{0, 1, 0});
            n[t * 3] = n[t * 3 + 1] = n[t * 3 + 2] = fn;
        }
        return from_soup_normals(s, n);
    }
    return from_soup_normals(s, corner_normals(s, creaseDeg));
}

Edges build_edges(const Soup& s) {
    struct Rec {
        std::uint32_t lo, hi, tri;
        std::uint8_t slot;
        bool fwd;
    };
    std::vector<Rec> recs;
    recs.reserve(s.tris.size() * 3);
    for (std::size_t t = 0; t < s.tris.size(); ++t)
        for (int k = 0; k < 3; ++k) {
            const std::uint32_t a = s.tris[t][std::size_t(k)], b = s.tris[t][std::size_t((k + 1) % 3)];
            recs.push_back({std::min(a, b), std::max(a, b), std::uint32_t(t), std::uint8_t(k), a < b});
        }
    std::sort(recs.begin(), recs.end(), [](const Rec& x, const Rec& y) {
        if (x.lo != y.lo) return x.lo < y.lo;
        if (x.hi != y.hi) return x.hi < y.hi;
        if (x.tri != y.tri) return x.tri < y.tri;
        return x.slot < y.slot;
    });
    Edges e;
    e.triEdge.assign(s.tris.size() * 3, 0);
    e.uses.reserve(recs.size());
    for (std::size_t i = 0; i < recs.size(); ++i) {
        if (i == 0 || recs[i].lo != recs[i - 1].lo || recs[i].hi != recs[i - 1].hi) e.edges.push_back({recs[i].lo, recs[i].hi, std::uint32_t(i), 0});
        ++e.edges.back().count;
        e.uses.push_back({recs[i].tri, recs[i].slot, recs[i].fwd});
        e.triEdge[recs[i].tri * 3 + recs[i].slot] = std::uint32_t(e.edges.size() - 1);
    }
    return e;
}

ModelMesh refresh_normals(const ModelMesh& moved, const ModelMesh& original) {
    ModelMesh out = moved;
    const std::size_t vc = moved.positions.size();
    if (original.normals.size() != vc) return out;
    std::vector<std::uint32_t> cluster = cluster_points(original.positions, kWeldTolerance);
    std::map<std::array<std::int64_t, 4>, std::uint32_t> groups;
    std::vector<std::uint32_t> group(vc);
    for (std::size_t v = 0; v < vc; ++v) {
        const Vec3 n = original.normals[v];
        const std::array<std::int64_t, 4> key{cluster[v], std::llround(double(n.x) * 1000.0), std::llround(double(n.y) * 1000.0), std::llround(double(n.z) * 1000.0)};
        auto it = groups.emplace(key, std::uint32_t(groups.size())).first;
        group[v] = it->second;
    }
    std::vector<Vec3> sum(groups.size(), Vec3{0, 0, 0});
    for (std::size_t t = 0; t < moved.triangle_count(); ++t) {
        const std::uint32_t i[3] = {moved.indices[t * 3], moved.indices[t * 3 + 1], moved.indices[t * 3 + 2]};
        const Vec3 p[3] = {moved.positions[i[0]], moved.positions[i[1]], moved.positions[i[2]]};
        const Vec3 fn = unit_or(cross(p[1] - p[0], p[2] - p[0]), Vec3{0, 0, 0});
        for (int k = 0; k < 3; ++k) {
            const Vec3 e1 = p[(k + 1) % 3] - p[k], e2 = p[(k + 2) % 3] - p[k];
            if (length_sq(e1) < 1e-30f || length_sq(e2) < 1e-30f) continue;
            const float ang = det::atan2(length(cross(e1, e2)), dot(e1, e2));
            sum[group[i[k]]] = sum[group[i[k]]] + fn * ang;
        }
    }
    for (std::size_t v = 0; v < vc; ++v) {
        const Vec3 n = unit_or(sum[group[v]], original.normals[v]);
        out.normals[v] = n;
    }
    return out;
}

}  // namespace fa::mm
