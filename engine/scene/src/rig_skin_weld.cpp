// The welded mesh and the helpers on sparse weights of the skin weights (rig_skin_internal.h).
#include <algorithm>
#include <cmath>
#include <numeric>
#include <tuple>

#include "rig_skin_internal.h"

namespace fa::rig_skin_detail {

float seg_dist2(Vec3 p, const Seg& s) {
    const Vec3 d = s.b - s.a;
    const float len2 = length_sq(d);
    float t = len2 > 1e-12f ? dot(p - s.a, d) / len2 : 0.0f;
    t = clamp(t, 0.0f, 1.0f);
    return length_sq(p - (s.a + d * t));
}

Weld build_weld(const MeshData& mesh, const std::vector<char>& triOn, float eps) {
    Weld w;
    const std::size_t n = mesh.vertex_count();
    w.nodeOf.assign(n, kNone);
    std::vector<char> used(n, 0);
    const std::size_t tris = mesh.indices.size() / 3;
    for (std::size_t t = 0; t < tris; ++t) {
        if (t < triOn.size() && !triOn[t]) continue;
        for (int k = 0; k < 3; ++k) {
            const std::uint32_t v = mesh.indices[t * 3 + std::size_t(k)];
            if (v < n) used[v] = 1;
        }
    }
    // weld: sort the used vertices by their quantised position (the index breaks ties), one node per run
    const double inv = 1.0 / double(std::max(eps, 1e-9f));
    struct Key {
        long long x, y, z;
        std::uint32_t v;
    };
    std::vector<Key> keys;
    for (std::size_t v = 0; v < n; ++v)
        if (used[v])
            keys.push_back({std::llround(double(mesh.positions[v * 3]) * inv),
                            std::llround(double(mesh.positions[v * 3 + 1]) * inv),
                            std::llround(double(mesh.positions[v * 3 + 2]) * inv), std::uint32_t(v)});
    std::sort(keys.begin(), keys.end(),
              [](const Key& a, const Key& b) { return std::tie(a.x, a.y, a.z, a.v) < std::tie(b.x, b.y, b.z, b.v); });
    for (std::size_t i = 0; i < keys.size(); ++i) {
        if (i == 0 || keys[i].x != keys[i - 1].x || keys[i].y != keys[i - 1].y || keys[i].z != keys[i - 1].z) {
            w.pos.push_back(
                {mesh.positions[keys[i].v * 3], mesh.positions[keys[i].v * 3 + 1], mesh.positions[keys[i].v * 3 + 2]});
        }
        w.nodeOf[keys[i].v] = std::uint32_t(w.pos.size() - 1);
    }
    const std::size_t nn = w.pos.size();
    w.mass.assign(nn, 0.0);

    // triangles and the cotangent weights
    struct Half {
        std::uint32_t i, j;
        float c;
    };
    std::vector<Half> halves;
    for (std::size_t t = 0; t < tris; ++t) {
        if (t < triOn.size() && !triOn[t]) continue;
        std::array<std::uint32_t, 3> a{};
        bool ok = true;
        for (int k = 0; k < 3; ++k) {
            const std::uint32_t v = mesh.indices[t * 3 + std::size_t(k)];
            if (v >= n) {
                ok = false;
                break;
            }
            a[std::size_t(k)] = w.nodeOf[v];
        }
        if (!ok || a[0] == a[1] || a[1] == a[2] || a[0] == a[2]) continue;
        const Vec3 p0 = w.pos[a[0]], p1 = w.pos[a[1]], p2 = w.pos[a[2]];
        const double area2 = double(length(cross(p1 - p0, p2 - p0)));  // twice the area
        if (area2 < 1e-12) continue;
        w.tris.push_back(a);
        const double area = 0.5 * area2;
        for (int k = 0; k < 3; ++k) {
            const std::uint32_t i = a[std::size_t(k)], j = a[std::size_t((k + 1) % 3)], o = a[std::size_t((k + 2) % 3)];
            // the angle at `o` is opposite the edge i-j
            const Vec3 u = w.pos[i] - w.pos[o], v = w.pos[j] - w.pos[o];
            const double cx = double(length(cross(u, v)));
            const double c = cx > 1e-12 ? double(dot(u, v)) / cx : 0.0;
            // clamp the cotangent of near-degenerate angles: a sliver must not make the matrix explode
            const float cw = float(0.5 * std::clamp(c, -10.0, 10.0));
            halves.push_back({i, j, cw});
            halves.push_back({j, i, cw});
            w.mass[i] += area / 3.0;
        }
    }
    std::sort(halves.begin(), halves.end(),
              [](const Half& a, const Half& b) { return std::tie(a.i, a.j) < std::tie(b.i, b.j); });
    w.rowStart.assign(nn + 1, 0);
    for (std::size_t h = 0; h < halves.size();) {
        std::size_t e = h;
        float sum = 0;
        while (e < halves.size() && halves[e].i == halves[h].i && halves[e].j == halves[h].j) sum += halves[e++].c;
        w.col.push_back(halves[h].j);
        w.cot.push_back(std::max(
            sum,
            0.0f));  // a negative weight (two obtuse angles) is dropped: the Laplacian stays positive semi-definite
        ++w.rowStart[halves[h].i + 1];
        h = e;
    }
    for (std::size_t i = 0; i < nn; ++i) w.rowStart[i + 1] += w.rowStart[i];

    // connected pieces, numbered in the order of their lowest node
    w.component.assign(nn, kNone);
    std::vector<std::uint32_t> stack;
    for (std::size_t s = 0; s < nn; ++s) {
        if (w.component[s] != kNone) continue;
        const std::uint32_t id = w.components++;
        w.component[s] = id;
        stack.push_back(std::uint32_t(s));
        while (!stack.empty()) {
            const std::uint32_t i = stack.back();
            stack.pop_back();
            for (std::uint32_t e = w.rowStart[i]; e < w.rowStart[i + 1]; ++e)
                if (w.component[w.col[e]] == kNone) {
                    w.component[w.col[e]] = id;
                    stack.push_back(w.col[e]);
                }
        }
    }
    return w;
}

float weight_of(const Infl& w, std::uint16_t bone) {
    for (const auto& e : w)
        if (e.first == bone) return e.second;
    return 0.0f;
}
float total_of(const Infl& w) {
    float s = 0;
    for (const auto& e : w) s += e.second;
    return s;
}
void normalize_infl(Infl& w, float cut) {
    if (w.empty()) return;
    std::pair<std::uint16_t, float> best = w[0];
    for (const auto& e : w)
        if (e.second > best.second) best = e;
    Infl kept;
    for (const auto& e : w)
        if (e.second >= cut) kept.push_back(e);
    if (kept.empty()) kept.push_back(best);
    const float s = total_of(kept);
    if (s <= 0) {
        kept.assign(1, {best.first, 1.0f});
    } else {
        for (auto& e : kept) e.second /= s;
    }
    w = std::move(kept);
}
void limit_infl(Infl& w, int k) {
    if (int(w.size()) > k) {
        std::vector<std::pair<std::uint16_t, float>> order = w;
        std::sort(order.begin(), order.end(), [](const auto& a, const auto& b) {
            return a.second > b.second || (a.second == b.second && a.first < b.first);
        });
        order.resize(std::size_t(k));
        std::sort(order.begin(), order.end());
        w = std::move(order);
    }
    normalize_infl(w, 0.0f);
}
void accumulate(const Infl& w, float scale, std::vector<float>& acc) {
    for (const auto& e : w) acc[e.first] += e.second * scale;
}
Infl from_dense(const std::vector<float>& acc, float cut) {
    Infl out;
    for (std::size_t b = 0; b < acc.size(); ++b)
        if (acc[b] > cut) out.push_back({std::uint16_t(b), acc[b]});
    return out;
}

}  // namespace fa::rig_skin_detail
