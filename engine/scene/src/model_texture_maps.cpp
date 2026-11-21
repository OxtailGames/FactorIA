// Texturing, the measuring half: the mesh as triangles, the uv atlas rasterised into texels, a BVH, and the baked maps (ambient occlusion,
// thickness, curvature). CPU only, serial, deterministic.
#include <algorithm>
#include <cmath>
#include <limits>
#include <map>

#include "model_texture_internal.h"

namespace fa::mt {

namespace {
constexpr float kNaN = std::numeric_limits<float>::quiet_NaN();
}

bool needs(const std::vector<std::string>& list, const std::string& name) {
    return list.empty() || std::find(list.begin(), list.end(), name) != list.end();
}

// ---- geometry ----------------------------------------------------------------------------------------------------------------

Geo make_geo(const MeshData& mesh) {
    Geo g;
    const std::size_t n = mesh.vertex_count();
    g.pos.resize(n);
    g.nrm.resize(n);
    g.uv.resize(n);
    for (std::size_t i = 0; i < n; ++i) {
        g.pos[i] = {mesh.positions[i * 3], mesh.positions[i * 3 + 1], mesh.positions[i * 3 + 2]};
        g.nrm[i] = {mesh.normals[i * 3], mesh.normals[i * 3 + 1], mesh.normals[i * 3 + 2]};
        g.uv[i] = i * 2 + 1 < mesh.uvs.size() ? Vec2{mesh.uvs[i * 2], mesh.uvs[i * 2 + 1]} : Vec2{};
    }
    if (mesh.colors.size() == n * 4) {
        g.col.resize(n);
        for (std::size_t i = 0; i < n; ++i)
            g.col[i] = {mesh.colors[i * 4], mesh.colors[i * 4 + 1], mesh.colors[i * 4 + 2], mesh.colors[i * 4 + 3]};
    }
    for (std::size_t s = 0; s < mesh.submeshes.size(); ++s) {
        const MeshSubmesh& sm = mesh.submeshes[s];
        const std::size_t end = sm.count == kSubmeshToEnd
                                    ? mesh.indices.size()
                                    : std::min<std::size_t>(mesh.indices.size(), std::size_t(sm.start) + sm.count);
        for (std::size_t k = sm.start; k + 3 <= end; k += 3) {
            g.tri.push_back({mesh.indices[k], mesh.indices[k + 1], mesh.indices[k + 2]});
            g.sub.push_back(std::uint32_t(s));
        }
    }
    g.faceN.resize(g.tri.size());
    g.area.resize(g.tri.size());
    for (std::size_t t = 0; t < g.tri.size(); ++t) {
        const Vec3 c = cross(g.corner(t, 1) - g.corner(t, 0), g.corner(t, 2) - g.corner(t, 0));
        const float l = length(c);
        g.area[t] = l * 0.5f;
        g.faceN[t] = l > 1e-12f ? c / l : Vec3{};
    }
    g.bmin = mesh.bmin;
    g.bmax = mesh.bmax;
    if (!g.pos.empty() && length(g.bmax - g.bmin) <= 0) {
        g.bmin = g.bmax = g.pos[0];
        for (const Vec3& p : g.pos) {
            g.bmin = min(g.bmin, p);
            g.bmax = max(g.bmax, p);
        }
    }
    g.diag = std::max(length(g.bmax - g.bmin), 1e-6f);
    return g;
}

// ---- the atlas ---------------------------------------------------------------------------------------------------------------

Texels rasterize(const Geo& g, int size, int bleed) {
    Texels t;
    t.size = size;
    const std::size_t total = std::size_t(size) * std::size_t(size);
    t.tri.assign(total, -1);
    t.b1.assign(total, 0);
    t.b2.assign(total, 0);
    t.bled.assign(total, 0);
    std::vector<std::uint8_t> claimed(total, 0);
    const float S = float(size);
    for (std::size_t ti = 0; ti < g.tri.size(); ++ti) {
        if (g.area[ti] <= 0) continue;
        const Vec2 a = g.uv[g.tri[ti][0]] * S, b = g.uv[g.tri[ti][1]] * S, c = g.uv[g.tri[ti][2]] * S;
        const float det = (b.x - a.x) * (c.y - a.y) - (c.x - a.x) * (b.y - a.y);
        if (std::fabs(det) < 1e-12f) continue;
        const int x0 = std::max(0, int(std::ceil(std::min({a.x, b.x, c.x}) - 0.5f)));
        const int x1 = std::min(size - 1, int(std::floor(std::max({a.x, b.x, c.x}) - 0.5f)));
        const int y0 = std::max(0, int(std::ceil(std::min({a.y, b.y, c.y}) - 0.5f)));
        const int y1 = std::min(size - 1, int(std::floor(std::max({a.y, b.y, c.y}) - 0.5f)));
        for (int y = y0; y <= y1; ++y)
            for (int x = x0; x <= x1; ++x) {
                const float px = float(x) + 0.5f, py = float(y) + 0.5f;
                const float w1 = ((px - a.x) * (c.y - a.y) - (c.x - a.x) * (py - a.y)) / det;
                const float w2 = ((b.x - a.x) * (py - a.y) - (px - a.x) * (b.y - a.y)) / det;
                const float w0 = 1 - w1 - w2;
                const float eps = -1e-4f;
                if (w0 < eps || w1 < eps || w2 < eps) continue;
                const std::size_t i = std::size_t(y) * std::size_t(size) + std::size_t(x);
                if (claimed[i] == 1)
                    claimed[i] = 2;
                else if (claimed[i] == 0)
                    claimed[i] = 1;
                t.tri[i] = std::int32_t(ti);
                t.b1[i] = std::clamp(w1, 0.0f, 1.0f);
                t.b2[i] = std::clamp(w2, 0.0f, 1.0f);
            }
    }
    for (std::size_t i = 0; i < total; ++i) {
        if (claimed[i] >= 1) ++t.covered;
        if (claimed[i] == 2) ++t.overlapped;
    }
    for (int round = 0; round < bleed; ++round) {
        std::vector<std::int32_t> nt = t.tri;
        std::vector<float> n1 = t.b1, n2 = t.b2;
        std::vector<std::uint8_t> nb = t.bled;
        bool any = false;
        for (int y = 0; y < size; ++y)
            for (int x = 0; x < size; ++x) {
                const std::size_t i = std::size_t(y) * std::size_t(size) + std::size_t(x);
                if (t.tri[i] >= 0) continue;
                bool done = false;
                for (int dy = -1; dy <= 1 && !done; ++dy)
                    for (int dx = -1; dx <= 1 && !done; ++dx) {
                        const int xx = x + dx, yy = y + dy;
                        if (xx < 0 || yy < 0 || xx >= size || yy >= size) continue;
                        const std::size_t j = std::size_t(yy) * std::size_t(size) + std::size_t(xx);
                        if (t.tri[j] < 0) continue;
                        nt[i] = t.tri[j];
                        n1[i] = t.b1[j];
                        n2[i] = t.b2[j];
                        nb[i] = 1;
                        done = any = true;
                    }
            }
        t.tri = std::move(nt);
        t.b1 = std::move(n1);
        t.b2 = std::move(n2);
        t.bled = std::move(nb);
        if (!any) break;
    }
    return t;
}

Vec3 texel_point(const Geo& g, const Texels& t, std::size_t i) {
    const std::size_t ti = std::size_t(t.tri[i]);
    const Vec3 p0 = g.corner(ti, 0), p1 = g.corner(ti, 1), p2 = g.corner(ti, 2);
    return p0 + (p1 - p0) * t.b1[i] + (p2 - p0) * t.b2[i];
}
Vec3 texel_normal(const Geo& g, const Texels& t, std::size_t i) {
    const std::size_t ti = std::size_t(t.tri[i]);
    const float w1 = t.b1[i], w2 = t.b2[i], w0 = 1 - w1 - w2;
    const Vec3 n = g.nrm[g.tri[ti][0]] * w0 + g.nrm[g.tri[ti][1]] * w1 + g.nrm[g.tri[ti][2]] * w2;
    const float l = length(n);
    return l > 1e-6f ? n / l : g.faceN[ti];
}

// ---- BVH ---------------------------------------------------------------------------------------------------------------------

// The tree and the ray test live in fa::TriBvh (fa/scene/bvh.h), shared with the lightmap baker.
void Bvh::build(const Geo& g) {
    std::vector<Vec3> corners;
    corners.reserve(g.tri.size() * 3);
    for (std::size_t t = 0; t < g.tri.size(); ++t)
        for (int k = 0; k < 3; ++k) corners.push_back(g.corner(t, k));
    tree_.build(corners.data(), g.tri.size());
}

float Bvh::nearest(Vec3 o, Vec3 d, float tmax, std::int32_t skip) const { return tree_.nearest(o, d, tmax, skip); }

// ---- occlusion and thickness -------------------------------------------------------------------------------------------------

namespace {

float radical2(std::uint32_t i) {
    i = (i << 16) | (i >> 16);
    i = ((i & 0x55555555u) << 1) | ((i & 0xAAAAAAAAu) >> 1);
    i = ((i & 0x33333333u) << 2) | ((i & 0xCCCCCCCCu) >> 2);
    i = ((i & 0x0F0F0F0Fu) << 4) | ((i & 0xF0F0F0F0u) >> 4);
    i = ((i & 0x00FF00FFu) << 8) | ((i & 0xFF00FF00u) >> 8);
    return float(i) * 2.3283064365386963e-10f;
}

struct Basis {
    Vec3 t, b, n;
    Vec3 to_world(Vec3 l) const { return t * l.x + b * l.y + n * l.z; }
};
Basis basis_of(Vec3 n) {
    const Vec3 ref = std::fabs(n.x) < 0.9f ? Vec3{1, 0, 0} : Vec3{0, 1, 0};
    const Vec3 t = normalize(cross(ref, n));
    return {t, cross(n, t), n};
}

constexpr float kConeCos = 0.7660444431f;  // cos 40 degrees

}  // namespace

std::vector<float> compute_ao(const Geo& g, const Bvh& bvh, const Texels& t, int samples, float distance) {
    std::vector<float> out(t.tri.size(), kNaN);
    const float eps = g.diag * 5e-4f;
    for (std::size_t i = 0; i < t.tri.size(); ++i) {
        if (!t.has(i)) continue;
        const std::int32_t ti = t.tri[i];
        const Vec3 fn = g.faceN[std::size_t(ti)];
        if (length_sq(fn) < 0.5f) {
            out[i] = 1;
            continue;
        }
        const Vec3 o = texel_point(g, t, i) + fn * eps;
        const Basis bs = basis_of(fn);
        const float rot = hash01(i);
        float occ = 0;
        for (int s = 0; s < samples; ++s) {
            const float u1 = (float(s) + 0.5f) / float(samples);
            float phi = radical2(std::uint32_t(s)) + rot;
            phi -= std::floor(phi);
            float sn, cs;
            det::sin_cos(phi * kTau, sn, cs);
            const float r = std::sqrt(u1);
            const Vec3 dir = bs.to_world({r * cs, r * sn, std::sqrt(1 - u1)});
            const float hit = bvh.nearest(o, dir, distance, ti);
            if (hit >= 0) occ += 1 - hit / distance;
        }
        out[i] = 1 - occ / float(samples);
    }
    return out;
}

std::vector<float> compute_thickness(const Geo& g, const Bvh& bvh, const Texels& t, int samples, float distance) {
    std::vector<float> out(t.tri.size(), kNaN);
    const float eps = g.diag * 5e-4f;
    for (std::size_t i = 0; i < t.tri.size(); ++i) {
        if (!t.has(i)) continue;
        const std::int32_t ti = t.tri[i];
        const Vec3 fn = g.faceN[std::size_t(ti)];
        if (length_sq(fn) < 0.5f) {
            out[i] = 1;
            continue;
        }
        const Vec3 o = texel_point(g, t, i) - fn * eps;
        const Basis bs = basis_of(-fn);
        const float rot = hash01(i + 0x51ed270bull);
        float sum = 0;
        for (int s = 0; s < samples; ++s) {
            const float u1 = (float(s) + 0.5f) / float(samples);
            float phi = radical2(std::uint32_t(s)) + rot;
            phi -= std::floor(phi);
            float sn, cs;
            det::sin_cos(phi * kTau, sn, cs);
            const float z = 1 - u1 * (1 - kConeCos);
            const float r = std::sqrt(std::max(0.0f, 1 - z * z));
            const Vec3 dir = bs.to_world({r * cs, r * sn, z});
            const float hit = bvh.nearest(o, dir, distance, ti);
            sum += hit >= 0 ? hit : distance;
        }
        out[i] = saturate(sum / float(samples) / distance);
    }
    return out;
}

// ---- edges and curvature -----------------------------------------------------------------------------------------------------

void EdgeIndex::build(const Geo& g, float edgeAngleDeg, float maxWidth) {
    segs_.clear();
    vertexH_.assign(g.pos.size(), 0.0f);
    // weld by position
    const float q = std::max(g.diag * 1e-5f, 1e-7f);
    std::map<std::array<std::int64_t, 3>, std::uint32_t> ids;
    std::vector<std::uint32_t> weld(g.pos.size());
    std::vector<Vec3> wpos;
    for (std::size_t v = 0; v < g.pos.size(); ++v) {
        const std::array<std::int64_t, 3> key = {std::llround(g.pos[v].x / q), std::llround(g.pos[v].y / q),
                                                 std::llround(g.pos[v].z / q)};
        auto it = ids.find(key);
        if (it == ids.end()) {
            it = ids.emplace(key, std::uint32_t(wpos.size())).first;
            wpos.push_back(g.pos[v]);
        }
        weld[v] = it->second;
    }
    struct E {
        std::uint32_t a, b, tri;
        int opposite;  // corner index (0..2) of the vertex that is not on the edge
    };
    std::vector<E> edges;
    edges.reserve(g.tri.size() * 3);
    for (std::size_t t = 0; t < g.tri.size(); ++t) {
        if (g.area[t] <= 0) continue;
        for (int k = 0; k < 3; ++k) {
            const std::uint32_t wa = weld[g.tri[t][std::size_t(k)]], wb = weld[g.tri[t][std::size_t((k + 1) % 3)]];
            if (wa == wb) continue;
            edges.push_back({std::min(wa, wb), std::max(wa, wb), std::uint32_t(t), (k + 2) % 3});
        }
    }
    std::sort(edges.begin(), edges.end(),
              [](const E& l, const E& r) { return l.a != r.a ? l.a < r.a : (l.b != r.b ? l.b < r.b : l.tri < r.tri); });
    const float edgeRad = edgeAngleDeg * kDegToRad;
    std::vector<double> acc(wpos.size(), 0.0), areaAcc(wpos.size(), 0.0);
    for (std::size_t t = 0; t < g.tri.size(); ++t)
        for (int k = 0; k < 3; ++k) areaAcc[weld[g.tri[t][std::size_t(k)]]] += double(g.area[t]) / 3.0;
    for (std::size_t i = 0; i < edges.size();) {
        std::size_t j = i;
        while (j < edges.size() && edges[j].a == edges[i].a && edges[j].b == edges[i].b) ++j;
        const std::size_t count = j - i;
        const Vec3 pa = wpos[edges[i].a], pb = wpos[edges[i].b];
        const float len = length(pb - pa);
        if (count == 1) {
            segs_.push_back({pa, pb, 1.0f, true});  // the border of an open surface wears like a rim
        } else if (count == 2 && edges[i].tri != edges[i + 1].tri) {
            const E& e1 = edges[i];
            const E& e2 = edges[i + 1];
            const Vec3 n1 = g.faceN[e1.tri], n2 = g.faceN[e2.tri];
            const float sinA = length(cross(n1, n2)), cosA = dot(n1, n2);
            const float theta = det::atan2(sinA, cosA);
            const Vec3 opp = g.corner(e2.tri, e2.opposite);
            const bool convex = dot(n1, opp - pa) < 0;
            if (theta >= edgeRad) {
                segs_.push_back({pa, pb, std::min(1.0f, theta / (60.0f * kDegToRad)), convex});
            } else {
                const double w = double(convex ? 1.0f : -1.0f) * double(theta) * double(len);
                acc[e1.a] += w;
                acc[e1.b] += w;
            }
        }
        i = j;
    }
    std::vector<float> wh(wpos.size(), 0.0f);
    for (std::size_t v = 0; v < wpos.size(); ++v)
        wh[v] = areaAcc[v] > 1e-12 ? float(acc[v] / (4.0 * areaAcc[v])) : 0.0f;
    for (std::size_t v = 0; v < g.pos.size(); ++v) vertexH_[v] = wh[weld[v]];

    // a grid over the sharp edges
    lo_ = g.bmin;
    hi_ = g.bmax;
    const Vec3 ext = hi_ - lo_;
    cell_ = std::max(maxWidth, g.diag / 48.0f);
    nx_ = std::max(1, int(std::ceil(ext.x / cell_)));
    ny_ = std::max(1, int(std::ceil(ext.y / cell_)));
    nz_ = std::max(1, int(std::ceil(ext.z / cell_)));
    cells_.assign(std::size_t(nx_) * std::size_t(ny_) * std::size_t(nz_), {});
    auto cell_of = [&](float v, float lo, int n) { return std::clamp(int(std::floor((v - lo) / cell_)), 0, n - 1); };
    for (std::size_t s = 0; s < segs_.size(); ++s) {
        const Vec3 mn = min(segs_[s].a, segs_[s].b) - Vec3(maxWidth), mx = max(segs_[s].a, segs_[s].b) + Vec3(maxWidth);
        for (int z = cell_of(mn.z, lo_.z, nz_); z <= cell_of(mx.z, lo_.z, nz_); ++z)
            for (int y = cell_of(mn.y, lo_.y, ny_); y <= cell_of(mx.y, lo_.y, ny_); ++y)
                for (int x = cell_of(mn.x, lo_.x, nx_); x <= cell_of(mx.x, lo_.x, nx_); ++x)
                    cells_[(std::size_t(z) * std::size_t(ny_) + std::size_t(y)) * std::size_t(nx_) + std::size_t(x)]
                        .push_back(std::uint32_t(s));
    }
}

int EdgeIndex::cell_index(Vec3 p) const {
    const int x = std::clamp(int(std::floor((p.x - lo_.x) / cell_)), 0, nx_ - 1);
    const int y = std::clamp(int(std::floor((p.y - lo_.y) / cell_)), 0, ny_ - 1);
    const int z = std::clamp(int(std::floor((p.z - lo_.z) / cell_)), 0, nz_ - 1);
    return (z * ny_ + y) * nx_ + x;
}

void EdgeIndex::bands(Vec3 p, float width, float& convex, float& concave) const {
    convex = concave = 0;
    if (segs_.empty() || width <= 0) return;
    for (std::uint32_t s : cells_[std::size_t(cell_index(p))]) {
        const Seg& sg = segs_[s];
        const Vec3 ab = sg.b - sg.a;
        const float l2 = dot(ab, ab);
        const float t = l2 > 1e-18f ? saturate(dot(p - sg.a, ab) / l2) : 0.0f;
        const float d = length(p - (sg.a + ab * t));
        if (d >= width) continue;
        const float v = sg.strength * smooth(1 - d / width);
        float& slot = sg.convex ? convex : concave;
        slot = std::max(slot, v);
    }
}

float EdgeIndex::curvature(const Geo& g, const Texels& t, std::size_t i) const {
    const std::size_t ti = std::size_t(t.tri[i]);
    const float w1 = t.b1[i], w2 = t.b2[i], w0 = 1 - w1 - w2;
    return vertexH_[g.tri[ti][0]] * w0 + vertexH_[g.tri[ti][1]] * w1 + vertexH_[g.tri[ti][2]] * w2;
}

// ---- noise -------------------------------------------------------------------------------------------------------------------

float value_noise(Vec3 p, int seed) {
    const float fx = std::floor(p.x), fy = std::floor(p.y), fz = std::floor(p.z);
    const std::int64_t ix = std::int64_t(fx), iy = std::int64_t(fy), iz = std::int64_t(fz);
    const float tx = smooth(p.x - fx), ty = smooth(p.y - fy), tz = smooth(p.z - fz);
    auto h = [&](std::int64_t x, std::int64_t y, std::int64_t z) {
        std::uint64_t k = std::uint64_t(x) * 73856093ull ^ std::uint64_t(y) * 19349663ull ^
                          std::uint64_t(z) * 83492791ull ^ (std::uint64_t(std::uint32_t(seed)) << 40);
        return hash01(k);
    };
    float c[2][2][2];
    for (int dz = 0; dz < 2; ++dz)
        for (int dy = 0; dy < 2; ++dy)
            for (int dx = 0; dx < 2; ++dx) c[dz][dy][dx] = h(ix + dx, iy + dy, iz + dz);
    auto l = [](float a, float b, float t) { return a + (b - a) * t; };
    const float x00 = l(c[0][0][0], c[0][0][1], tx), x10 = l(c[0][1][0], c[0][1][1], tx);
    const float x01 = l(c[1][0][0], c[1][0][1], tx), x11 = l(c[1][1][0], c[1][1][1], tx);
    return l(l(x00, x10, ty), l(x01, x11, ty), tz);
}

}  // namespace fa::mt
