// Modifiers that move, copy or re-shade a mesh: mirror, arrays, solidify, deformers, smoothing, weld and shading.
// (bevel: model_bevel.cpp; subdivision: model_subdivide.cpp; boolean: model_boolean.cpp; lathe, sweep, loft: model_profile.cpp.)
#include "fa/scene/model_modifiers.h"

#include <algorithm>
#include <cmath>
#include <cstring>

#include "model_mesh_ops.h"

namespace fa {

using namespace mm;

namespace {

constexpr int kU[3] = {1, 2, 0};  // the two axes that are not `a`, in cyclic order: (a + 1) % 3 and (a + 2) % 3
constexpr int kW[3] = {2, 0, 1};

int clamp_axis(int a) { return a < 0 ? 0 : (a > 2 ? 2 : a); }

Mat4 axis_rotation(int axis, float deg) {
    return axis == 0 ? Mat4::rotate_x_deg(deg) : (axis == 1 ? Mat4::rotate_y_deg(deg) : Mat4::rotate_z_deg(deg));
}

// The stretch of an axis a deformer works on: the given ends, or the extent of the mesh.
void axis_range(const ModelMesh& m, int axis, bool hasFrom, float from, bool hasTo, float to, float& lo, float& hi) {
    Vec3 bmin, bmax;
    m.bounds(bmin, bmax);
    lo = hasFrom ? from : bmin[axis];
    hi = hasTo ? to : bmax[axis];
}

// Moves every vertex of `m` with `f(position, welded id) -> position` so that vertices at one place stay together, then recomputes the
// normals keeping the smoothing groups the mesh had.
template <class F>
ModelMesh move_vertices(const ModelMesh& m, F&& f) {
    ModelMesh out = m;
    for (std::size_t v = 0; v < out.positions.size(); ++v) out.positions[v] = f(m.positions[v], v);
    return refresh_normals(out, m);
}

}  // namespace

// ---- mirror and arrays ---------------------------------------------------------------------------------------------------------

ModelMesh model_mirror(const ModelMesh& m, const ModelMirrorParams& p) {
    const int a = clamp_axis(p.axis);
    ModelMesh base = m;
    if (p.merge) {
        for (std::size_t v = 0; v < base.positions.size(); ++v) {
            if (std::fabs(base.positions[v][a] - p.offset) > p.mergeDistance) continue;
            base.positions[v][a] = p.offset;
            Vec3 n = base.normals[v];
            n[a] = 0;
            if (length_sq(n) > 1e-6f) base.normals[v] = normalize(n);
        }
    }
    ModelMesh copy = base;
    for (Vec3& q : copy.positions) q[a] = 2.0f * p.offset - q[a];
    for (Vec3& n : copy.normals) n[a] = -n[a];
    for (std::size_t i = 0; i + 2 < copy.indices.size(); i += 3) std::swap(copy.indices[i + 1], copy.indices[i + 2]);
    base.append(copy);
    return p.merge ? dedup_vertices(base) : base;
}

ModelMesh model_array(const ModelMesh& m, const ModelArrayParams& p) {
    Vec3 offset = p.offset;
    if (p.relative) {
        Vec3 bmin, bmax;
        m.bounds(bmin, bmax);
        offset = offset * (bmax - bmin);
    }
    const Mat4 step = Mat4::translate(offset) * Mat4::rotate_euler_deg(p.stepRotation) * Mat4::scale(p.stepScale);
    ModelMesh out;
    Mat4 cur;  // identity
    for (int k = 0; k < std::max(p.count, 1); ++k) {
        ModelMesh copy = m;
        if (k > 0) copy.transform(cur);
        out.append(copy);
        cur = step * cur;
        // step * cur applies the new translation after the earlier rotations; a pure translation step keeps copy k at k * offset
    }
    return p.merge ? model_weld(out, {p.mergeDistance}) : out;
}

ModelMesh model_radial_array(const ModelMesh& m, const ModelRadialArrayParams& p) {
    const int axis = clamp_axis(p.axis);
    const int count = std::max(p.count, 1);
    const bool full = p.angle >= 359.999f || p.angle <= -359.999f;
    const float stepDeg = count <= 1 ? 0.0f : (full ? p.angle / float(count) : p.angle / float(count - 1));
    Vec3 bmin, bmax;
    m.bounds(bmin, bmax);
    const Vec3 mid = (bmin + bmax) * 0.5f - p.center;
    ModelMesh out;
    for (int k = 0; k < count; ++k) {
        ModelMesh copy = m;
        const float deg = stepDeg * float(k);
        if (k > 0) {
            const Mat4 around = Mat4::translate(p.center) * axis_rotation(axis, deg) * Mat4::translate(p.center * -1.0f);
            if (p.faceCenter) {
                copy.transform(around);
            } else {
                const Vec3 moved = around.transform_point(mid + p.center) - (mid + p.center);
                copy.transform(Mat4::translate(moved));
            }
        }
        out.append(copy);
    }
    return p.merge ? model_weld(out, {p.mergeDistance}) : out;
}

// ---- solidify --------------------------------------------------------------------------------------------------------------------

ModelMesh model_solidify(const ModelMesh& m, const ModelSolidifyParams& p) {
    std::vector<std::uint32_t> weldedOf;
    const Soup s = to_soup(m, kWeldTolerance, &weldedOf);
    if (s.tris.empty()) return m;
    const std::size_t wc = s.pos.size();
    // vertex normals of the welded surface (angle-weighted over every face around the vertex) and how much to stretch the offset
    std::vector<Vec3> vn(wc, Vec3{0, 0, 0});
    std::vector<Vec3> fn(s.tris.size());
    for (std::size_t t = 0; t < s.tris.size(); ++t) {
        fn[t] = unit_or(s.face_cross(t), Vec3{0, 0, 0});
        for (int k = 0; k < 3; ++k) {
            const Vec3 q = s.pos[s.tris[t][std::size_t(k)]];
            const Vec3 e1 = s.pos[s.tris[t][std::size_t((k + 1) % 3)]] - q, e2 = s.pos[s.tris[t][std::size_t((k + 2) % 3)]] - q;
            if (length_sq(e1) < 1e-30f || length_sq(e2) < 1e-30f) continue;
            vn[s.tris[t][std::size_t(k)]] += fn[t] * det::atan2(length(cross(e1, e2)), dot(e1, e2));
        }
    }
    for (Vec3& n : vn) n = unit_or(n, Vec3{0, 1, 0});
    std::vector<float> stretch(wc, 1.0f);
    if (p.even) {
        std::vector<float> sum(wc, 0.0f);
        std::vector<int> cnt(wc, 0);
        for (std::size_t t = 0; t < s.tris.size(); ++t)
            for (std::uint32_t v : s.tris[t]) {
                sum[v] += dot(vn[v], fn[t]);
                ++cnt[v];
            }
        for (std::size_t v = 0; v < wc; ++v)
            if (cnt[v] > 0) stretch[v] = 1.0f / std::max(sum[v] / float(cnt[v]), 0.25f);
    }
    const float t = p.thickness;
    const float outer = t * (1.0f + p.offset) * 0.5f, inner = outer - t;
    auto shifted = [&](std::size_t w, float amount) { return s.pos[w] + vn[w] * (amount * stretch[w]); };

    ModelMesh outerMesh = m, innerMesh = m;
    for (std::size_t v = 0; v < m.positions.size(); ++v) {
        outerMesh.positions[v] = shifted(weldedOf[v], outer);
        innerMesh.positions[v] = shifted(weldedOf[v], inner);
    }
    outerMesh = refresh_normals(outerMesh, m);
    innerMesh = refresh_normals(innerMesh, m);
    for (Vec3& n : innerMesh.normals) n = -n;
    for (std::size_t i = 0; i + 2 < innerMesh.indices.size(); i += 3) std::swap(innerMesh.indices[i + 1], innerMesh.indices[i + 2]);

    // walls along the boundary edges (edges that exactly one triangle uses)
    const Edges edges = build_edges(s);
    ModelMesh walls;
    if (!edges.edges.empty()) {
        for (std::size_t e = 0; e < edges.edges.size(); ++e) {
            if (edges.edges[e].count != 1) continue;
            const EdgeUse& use = edges.uses[edges.edges[e].first];
            const std::uint32_t tri = use.tri;
            const int slot = use.slot;
            const std::uint32_t wa = s.tris[tri][std::size_t(slot)], wb = s.tris[tri][std::size_t((slot + 1) % 3)];
            const Attr& aa = s.attr[tri][std::size_t(slot)];
            const Attr& ab = s.attr[tri][std::size_t((slot + 1) % 3)];
            const Vec3 ao = shifted(wa, outer), ai = shifted(wa, inner), bo = shifted(wb, outer), bi = shifted(wb, inner);
            const Vec3 n = unit_or(cross(ai - ao, bi - ao) + cross(bi - ao, bo - ao), Vec3{0, 1, 0});
            const std::uint32_t base = std::uint32_t(walls.positions.size());
            for (const Vec3& q : {ao, ai, bi, bo}) {
                walls.positions.push_back(q);
                walls.normals.push_back(n);
            }
            walls.uvs.insert(walls.uvs.end(), {aa.uv, aa.uv, ab.uv, ab.uv});
            if (s.colors) walls.colors.insert(walls.colors.end(), {aa.color, aa.color, ab.color, ab.color});
            walls.indices.insert(walls.indices.end(), {base, base + 1, base + 2, base, base + 2, base + 3});
            walls.triParts.insert(walls.triParts.end(), {s.part[tri], s.part[tri]});
        }
    }
    outerMesh.append(innerMesh);
    outerMesh.append(walls);
    return dedup_vertices(outerMesh);
}

// ---- deformers -------------------------------------------------------------------------------------------------------------------

ModelMesh model_bend(const ModelMesh& m, const ModelBendParams& p) {
    const int a = clamp_axis(p.axis);
    float lo, hi;
    axis_range(m, a, p.hasFrom, p.from, p.hasTo, p.to, lo, hi);
    const float len = hi - lo;
    const float ang = radians(p.angle);
    if (len < 1e-6f || std::fabs(ang) < 1e-6f) return m;
    const float radius = len / ang;
    const int u = kU[a], w = kW[a];
    float sd, cd;
    det::sin_cos(radians(p.direction), sd, cd);
    return move_vertices(m, [&](Vec3 q, std::size_t) {
        const float t = q[a];
        const float dist = q[u] * cd + q[w] * sd;      // offset towards the bend direction
        const float side = -q[u] * sd + q[w] * cd;     // across it: unchanged
        const float tc = clamp(t, lo, hi);
        const float phi = (tc - lo) / radius;
        float sp, cp;
        det::sin_cos(phi, sp, cp);
        const float rho = radius - dist;
        float along = lo + rho * sp, toward = radius - rho * cp;
        const float extra = t - tc;  // beyond the ends the model continues straight along the tangent
        along += extra * cp;
        toward += extra * sp;
        Vec3 r;
        r[a] = along;
        r[u] = toward * cd - side * sd;
        r[w] = toward * sd + side * cd;
        return r;
    });
}

ModelMesh model_twist(const ModelMesh& m, const ModelTwistParams& p) {
    const int a = clamp_axis(p.axis);
    float lo, hi;
    axis_range(m, a, p.hasFrom, p.from, p.hasTo, p.to, lo, hi);
    const float len = hi - lo;
    if (len < 1e-6f || std::fabs(p.angle) < 1e-6f) return m;
    const int u = kU[a], w = kW[a];
    return move_vertices(m, [&](Vec3 q, std::size_t) {
        const float k = clamp((q[a] - lo) / len, 0.0f, 1.0f);
        float s, c;
        det::sin_cos(radians(p.angle * k), s, c);
        Vec3 r = q;
        r[u] = q[u] * c - q[w] * s;
        r[w] = q[u] * s + q[w] * c;
        return r;
    });
}

ModelMesh model_taper(const ModelMesh& m, const ModelTaperParams& p) {
    const int a = clamp_axis(p.axis);
    float lo, hi;
    axis_range(m, a, p.hasFrom, p.from, p.hasTo, p.to, lo, hi);
    const float len = hi - lo;
    if (len < 1e-6f) return m;
    const int u = kU[a], w = kW[a];
    return move_vertices(m, [&](Vec3 q, std::size_t) {
        const float k = clamp((q[a] - lo) / len, 0.0f, 1.0f);
        const float sc = lerp(p.startScale, p.endScale, k);
        Vec3 r = q;
        r[u] = q[u] * sc;
        r[w] = q[w] * sc;
        return r;
    });
}

namespace {

std::uint32_t hash_cell(std::int32_t x, std::int32_t y, std::int32_t z, std::uint32_t seed) {
    std::uint32_t h = seed * 0x9E3779B1u;
    h ^= std::uint32_t(x) * 0x85EBCA6Bu;
    h = (h << 13) | (h >> 19);
    h ^= std::uint32_t(y) * 0xC2B2AE35u;
    h = (h << 11) | (h >> 21);
    h ^= std::uint32_t(z) * 0x27D4EB2Fu;
    h ^= h >> 15;
    h *= 0x2C1B3C6Du;
    h ^= h >> 12;
    h *= 0x297A2D39u;
    h ^= h >> 15;
    return h;
}

float lattice(std::int32_t x, std::int32_t y, std::int32_t z, std::uint32_t seed) {
    return float(hash_cell(x, y, z, seed) & 0xFFFFFFu) / 8388607.5f - 1.0f;  // -1..1
}

float fade(float t) { return t * t * (3.0f - 2.0f * t); }

// Value noise in -1..1.
float value_noise(Vec3 p, std::uint32_t seed) {
    constexpr float kLimit = 1.0e9f;  // keeps the lattice coordinates inside int32
    p = {clamp(p.x, -kLimit, kLimit), clamp(p.y, -kLimit, kLimit), clamp(p.z, -kLimit, kLimit)};
    const float fx = std::floor(p.x), fy = std::floor(p.y), fz = std::floor(p.z);
    const std::int32_t ix = std::int32_t(fx), iy = std::int32_t(fy), iz = std::int32_t(fz);
    const float tx = fade(p.x - fx), ty = fade(p.y - fy), tz = fade(p.z - fz);
    float v[2][2][2];
    for (int dx = 0; dx < 2; ++dx)
        for (int dy = 0; dy < 2; ++dy)
            for (int dz = 0; dz < 2; ++dz) v[dx][dy][dz] = lattice(ix + dx, iy + dy, iz + dz, seed);
    const float x00 = lerp(v[0][0][0], v[1][0][0], tx), x10 = lerp(v[0][1][0], v[1][1][0], tx);
    const float x01 = lerp(v[0][0][1], v[1][0][1], tx), x11 = lerp(v[0][1][1], v[1][1][1], tx);
    return lerp(lerp(x00, x10, ty), lerp(x01, x11, ty), tz);
}

float fractal(Vec3 p, const ModelNoiseParams& q, std::uint32_t seedOffset) {
    float sum = 0, amp = 1, freq = q.frequency;
    for (int o = 0; o < std::max(q.octaves, 1); ++o) {
        sum += amp * value_noise(p * freq, std::uint32_t(q.seed) * 7919u + seedOffset + std::uint32_t(o) * 104729u);
        amp *= 0.5f;
        freq *= 2.0f;
    }
    return sum;
}

}  // namespace

float model_value_noise(Vec3 p, std::uint32_t seed) { return value_noise(p, seed); }

ModelMesh model_noise(const ModelMesh& m, const ModelNoiseParams& p) {
    std::vector<std::uint32_t> id = cluster_points(m.positions, kWeldTolerance);
    // one direction per welded vertex, so a seam where normals differ (a hard edge, a uv cut) is displaced the same way on both sides
    std::vector<Vec3> dir(m.positions.size(), Vec3{0, 0, 0});
    if (p.alongNormal) {
        std::uint32_t clusters = 0;
        for (std::uint32_t c : id) clusters = std::max(clusters, c + 1);
        std::vector<Vec3> sum(clusters, Vec3{0, 0, 0});
        for (std::size_t v = 0; v < m.positions.size(); ++v) sum[id[v]] += m.normals[v];
        for (std::size_t v = 0; v < m.positions.size(); ++v) dir[v] = unit_or(sum[id[v]], m.normals[v]);
    }
    return move_vertices(m, [&](Vec3 q, std::size_t v) {
        if (p.alongNormal) return q + dir[v] * (p.amplitude * fractal(q, p, 0));
        return q + Vec3{fractal(q, p, 1), fractal(q, p, 2), fractal(q, p, 3)} * p.amplitude;
    });
}

// ---- smoothing, welding and shading --------------------------------------------------------------------------------------------------

ModelMesh model_smooth(const ModelMesh& m, const ModelSmoothParams& p) {
    std::vector<std::uint32_t> weldedOf;
    Soup s = to_soup(m, kWeldTolerance, &weldedOf);
    if (s.tris.empty() || p.iterations <= 0) return m;
    const Edges edges = build_edges(s);
    const std::size_t wc = s.pos.size();
    std::vector<std::vector<std::uint32_t>> nb(wc);
    std::vector<char> locked(wc, 0);
    std::vector<Vec3> fn(s.tris.size());
    for (std::size_t t = 0; t < s.tris.size(); ++t) fn[t] = unit_or(s.face_cross(t), Vec3{0, 0, 0});
    const float cosSharp = det::cos(radians(p.sharpAngle));
    for (std::size_t e = 0; e < edges.edges.size(); ++e) {
        const Edges::Edge& ed = edges.edges[e];
        nb[ed.lo].push_back(ed.hi);
        nb[ed.hi].push_back(ed.lo);
        if (ed.count == 1 && p.lockBoundary) locked[ed.lo] = locked[ed.hi] = 1;
        if (ed.count != 2 && ed.count != 1) locked[ed.lo] = locked[ed.hi] = 1;  // a non-manifold edge stays
        if (ed.count == 2 && p.sharpAngle < 179.999f &&
            dot(fn[edges.uses[ed.first].tri], fn[edges.uses[ed.first + 1].tri]) < cosSharp)
            locked[ed.lo] = locked[ed.hi] = 1;
    }
    for (auto& list : nb) {
        std::sort(list.begin(), list.end());
        list.erase(std::unique(list.begin(), list.end()), list.end());
    }
    const float lambda = clamp(p.factor, 0.0f, 1.0f);
    const float mu = -lambda / (1.0f - 0.1f * lambda);
    std::vector<Vec3> cur = s.pos, next = s.pos;
    auto relax = [&](float k) {
        for (std::size_t v = 0; v < wc; ++v) {
            if (locked[v] || nb[v].empty()) {
                next[v] = cur[v];
                continue;
            }
            Vec3 avg{0, 0, 0};
            for (std::uint32_t n : nb[v]) avg += cur[n];
            avg = avg / float(nb[v].size());
            next[v] = cur[v] + (avg - cur[v]) * k;
        }
        cur.swap(next);
    };
    for (int it = 0; it < p.iterations; ++it) {
        relax(lambda);
        if (p.taubin) relax(mu);
    }
    ModelMesh out = m;
    for (std::size_t v = 0; v < out.positions.size(); ++v) out.positions[v] = cur[weldedOf[v]];
    return refresh_normals(out, m);
}

ModelMesh model_weld(const ModelMesh& m, const ModelWeldParams& p) {
    std::vector<Vec3> centers;
    const std::vector<std::uint32_t> id = cluster_points(m.positions, std::max(p.distance, 0.0f), &centers);
    ModelMesh moved = m;
    for (std::size_t v = 0; v < moved.positions.size(); ++v) moved.positions[v] = centers[id[v]];
    ModelMesh out = dedup_vertices(moved);
    // triangles whose corners met have no area
    ModelMesh clean = drop_degenerate(out);
    return clean;
}

ModelMesh model_shade(const ModelMesh& m, const ModelShadeParams& p) {
    const Soup s = to_soup(m);
    if (s.tris.empty()) return m;
    switch (p.mode) {
        case ModelShadeMode::Flat: return from_soup(s, 0, true);
        case ModelShadeMode::Smooth: return from_soup(s, 180);
        case ModelShadeMode::Auto: break;
    }
    return from_soup(s, p.angle);
}

}  // namespace fa
