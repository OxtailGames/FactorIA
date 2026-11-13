// Generators from profiles: lathe (a profile turned about the Y axis), sweep (a closed profile moved along a path) and loft (a skin
// through sections). All three build a Soup of rings of welded vertex ids and let `from_soup` give the normals by the crease angle, so
// seams are smooth, hard corners stay hard, and the same ring vertex is shared by the side walls and the caps.
#include <algorithm>
#include <cmath>
#include <format>

#include "fa/scene/model_modifiers.h"
#include "model_mesh_ops.h"

namespace fa {

using namespace mm;

namespace {

float signed_area(const std::vector<Vec2>& p) {
    float a = 0;
    for (std::size_t i = 0; i < p.size(); ++i) {
        const Vec2 q = p[i], r = p[(i + 1) % p.size()];
        a += q.x * r.y - r.x * q.y;
    }
    return a * 0.5f;
}

Attr uv_attr(float u, float v) {
    Attr a;
    a.uv = {u, v};
    return a;
}

void emit_tri(Soup& s, std::uint32_t a, std::uint32_t b, std::uint32_t c, Attr aa, Attr ab, Attr ac) {
    if (a == b || b == c || a == c) return;
    if (length_sq(cross(s.pos[b] - s.pos[a], s.pos[c] - s.pos[a])) < 1e-22f)
        return;  // no area (a ring collapsed to a point)
    s.add_tri(a, b, c, aa, ab, ac, 0);
}

// A flat polygon given as ids of s: triangulated in its own plane and added facing `outward`.
void cap_polygon(Soup& s, const std::vector<std::uint32_t>& ids, Vec3 outward) {
    if (ids.size() < 3) return;
    Vec3 n{0, 0, 0};
    for (std::size_t i = 0; i < ids.size(); ++i) {
        const Vec3 a = s.pos[ids[i]], b = s.pos[ids[(i + 1) % ids.size()]];
        n += Vec3{(a.y - b.y) * (a.z + b.z), (a.z - b.z) * (a.x + b.x), (a.x - b.x) * (a.y + b.y)};
    }
    if (length_sq(n) < 1e-18f) return;
    n = normalize(n);
    const Vec3 ref = std::fabs(n.y) < 0.9f ? Vec3{0, 1, 0} : Vec3{1, 0, 0};
    const Vec3 u = normalize(cross(ref, n)), v = cross(n, u);
    std::vector<Vec2> pts;
    Vec2 lo{1e30f, 1e30f}, hi{-1e30f, -1e30f};
    for (std::uint32_t id : ids) {
        const Vec2 q{dot(s.pos[id], u), dot(s.pos[id], v)};
        pts.push_back(q);
        lo = min(lo, q);
        hi = max(hi, q);
    }
    const Vec2 size{std::max(hi.x - lo.x, 1e-6f), std::max(hi.y - lo.y, 1e-6f)};
    const std::vector<std::uint32_t> tris = triangulate_polygon(pts, {});
    const bool flip = dot(n, outward) < 0;
    for (std::size_t t = 0; t + 2 < tris.size(); t += 3) {
        std::uint32_t k[3] = {tris[t], tris[t + 1], tris[t + 2]};
        if (flip) std::swap(k[1], k[2]);
        Attr at[3];
        for (int q = 0; q < 3; ++q)
            at[q] = uv_attr((pts[k[q]].x - lo.x) / size.x, 1.0f - (pts[k[q]].y - lo.y) / size.y);
        emit_tri(s, ids[k[0]], ids[k[1]], ids[k[2]], at[0], at[1], at[2]);
    }
}

// Rings of points joined by quads. ring[k][i] is point i of ring k. `flip` reverses the winding of the walls. The walls' uvs are
// (u[i], v[k]); u and v have one entry more than the points when the profile / path is closed (the last equals 1 and is the seam).
Soup tube(const std::vector<std::vector<Vec3>>& ring, bool profileClosed, bool pathClosed, bool flip,
          const std::vector<float>& u, const std::vector<float>& v, bool cap, Vec3 startOut, Vec3 endOut) {
    Soup s;
    const std::size_t K = ring.size(), P = ring[0].size();
    std::vector<std::vector<std::uint32_t>> id(K, std::vector<std::uint32_t>(P));
    for (std::size_t k = 0; k < K; ++k)
        for (std::size_t i = 0; i < P; ++i) id[k][i] = s.add_vertex(ring[k][i]);
    const std::size_t segK = pathClosed ? K : K - 1, segP = profileClosed ? P : P - 1;
    for (std::size_t k = 0; k < segK; ++k) {
        const std::size_t k1 = (k + 1) % K;
        for (std::size_t i = 0; i < segP; ++i) {
            const std::size_t i1 = (i + 1) % P;
            const std::uint32_t a = id[k][i], b = id[k][i1], c = id[k1][i1], d = id[k1][i];
            const Attr ua = uv_attr(u[i], v[k]), ub = uv_attr(u[i + 1], v[k]), uc = uv_attr(u[i + 1], v[k + 1]),
                       ud = uv_attr(u[i], v[k + 1]);
            if (flip) {
                emit_tri(s, a, c, b, ua, uc, ub);
                emit_tri(s, a, d, c, ua, ud, uc);
            } else {
                emit_tri(s, a, b, c, ua, ub, uc);
                emit_tri(s, a, c, d, ua, uc, ud);
            }
        }
    }
    if (cap && profileClosed && !pathClosed) {
        cap_polygon(s, id[0], startOut);
        cap_polygon(s, id[K - 1], endOut);
    }
    return s;
}

Vec3 catmull_rom(Vec3 p0, Vec3 p1, Vec3 p2, Vec3 p3, float t) {
    const float t2 = t * t, t3 = t2 * t;
    return (p1 * 2.0f + (p2 - p0) * t + (p0 * 2.0f - p1 * 5.0f + p2 * 4.0f - p3) * t2 +
            (p1 * 3.0f - p0 - p2 * 3.0f + p3) * t3) *
           0.5f;
}

Vec3 rotate_about(Vec3 v, Vec3 axis, float deg) {
    float s, c;
    det::sin_cos(radians(deg), s, c);
    return v * c + cross(axis, v) * s + axis * (dot(axis, v) * (1.0f - c));
}

}  // namespace

// ---- lathe -----------------------------------------------------------------------------------------------------------------------------

ModelMesh model_lathe(const ModelLatheParams& p) {
    std::vector<Vec2> pts;
    for (const Vec2& q : p.profile) {
        const Vec2 r{std::max(q.x, 0.0f), q.y};
        if (pts.empty() || length(r - pts.back()) > 1e-7f) pts.push_back(r);
    }
    if (pts.size() < 2) return {};
    const bool full = p.angle >= 359.999f;
    const int N = std::clamp(p.segments, full ? 3 : 1, 512);
    const float angle = full ? 360.0f : std::max(p.angle, 0.01f);
    // an outline that comes back to its first point is a loop (a ring, a tube wall, a torus): turned as it is, nothing is added
    const bool loop = pts.size() >= 4 && length(pts.front() - pts.back()) <= 1e-7f;
    if (loop) pts.pop_back();
    // an end off the axis is closed with a disc: the profile is extended to the axis there
    if (p.cap && !loop) {
        if (pts.front().x > 1e-7f) pts.insert(pts.begin(), Vec2{0, pts.front().y});
        if (pts.back().x > 1e-7f) pts.push_back(Vec2{0, pts.back().y});
    }
    // the front must be on the right-hand side: a profile that runs the other way is reversed
    if (signed_area(pts) < 0) std::reverse(pts.begin(), pts.end());
    const std::size_t P = pts.size();
    std::vector<float> arc(P, 0.0f);
    for (std::size_t i = 1; i < P; ++i) arc[i] = arc[i - 1] + length(pts[i] - pts[i - 1]);
    const float total = std::max(arc.back() + (loop ? length(pts[0] - pts.back()) : 0.0f), 1e-9f);

    std::vector<float> sins(std::size_t(N) + 1), coss(std::size_t(N) + 1);
    for (int j = 0; j <= N; ++j) {
        if (full && j == N) {
            sins[std::size_t(j)] = sins[0];
            coss[std::size_t(j)] = coss[0];
        } else {
            det::sin_cos(radians(angle * float(j) / float(N)), sins[std::size_t(j)], coss[std::size_t(j)]);
        }
    }
    Soup s;
    // ids[j][i]: ring j of the profile point i; points on the axis are one vertex for every ring
    const int J = N + 1;
    std::vector<std::vector<std::uint32_t>> id(std::size_t(J), std::vector<std::uint32_t>(std::size_t(P), 0u));
    std::vector<std::uint32_t> axisId(P, UINT32_MAX);
    for (int j = 0; j < J; ++j)
        for (std::size_t i = 0; i < P; ++i) {
            if (full && j == N) {
                id[std::size_t(j)][i] = id[0][i];
                continue;
            }
            if (pts[i].x <= 1e-7f) {
                if (axisId[i] == UINT32_MAX) axisId[i] = s.add_vertex({0, pts[i].y, 0});
                id[std::size_t(j)][i] = axisId[i];
            } else {
                id[std::size_t(j)][i] =
                    s.add_vertex({pts[i].x * sins[std::size_t(j)], pts[i].y, pts[i].x * coss[std::size_t(j)]});
            }
        }
    for (std::size_t i = 0; i + (loop ? 0 : 1) < P; ++i) {
        const std::size_t i1 = (i + 1) % P;
        const float v0 = 1.0f - arc[i] / total, v1 = 1.0f - (loop && i1 == 0 ? total : arc[i1]) / total;
        for (int j = 0; j < N; ++j) {
            const float u0 = float(j) / float(N), u1 = float(j + 1) / float(N);
            const std::uint32_t a = id[std::size_t(j)][i], b = id[std::size_t(j + 1)][i],
                                c = id[std::size_t(j + 1)][i1], d = id[std::size_t(j)][i1];
            const Attr aa = uv_attr(u0, v0), ab = uv_attr(u1, v0), ac = uv_attr(u1, v1), ad = uv_attr(u0, v1);
            emit_tri(s, a, b, c, aa, ab, ac);
            emit_tri(s, a, c, d, aa, ac, ad);
        }
    }
    // a partial turn is closed with a flat wall at each end (the profile polygon)
    if (!full && p.cap && std::fabs(signed_area(pts)) > 1e-9f) {
        const std::vector<std::uint32_t> tris = triangulate_polygon(pts, {});
        for (std::size_t t = 0; t + 2 < tris.size(); t += 3) {
            const std::uint32_t k[3] = {tris[t], tris[t + 1], tris[t + 2]};
            Attr at[3];
            for (int q = 0; q < 3; ++q) at[q] = uv_attr(pts[k[q]].x, 1.0f - pts[k[q]].y);
            emit_tri(s, id[0][k[0]], id[0][k[1]], id[0][k[2]], at[0], at[1], at[2]);
            emit_tri(s, id[std::size_t(N)][k[0]], id[std::size_t(N)][k[2]], id[std::size_t(N)][k[1]], at[0], at[2],
                     at[1]);
        }
    }
    return from_soup(s, p.creaseAngle);
}

// ---- sweep -----------------------------------------------------------------------------------------------------------------------------

Result<ModelMesh> model_sweep(const ModelSweepParams& p) {
    if (p.profile.size() < 3)
        return make_error("a sweep needs a profile of at least 3 points",
                          "Give `profile` a closed shape, e.g. [[-0.1,-0.1],[0.1,-0.1],[0.1,0.1],[-0.1,0.1]].");
    if (p.path.size() < 2)
        return make_error("a sweep needs a path of at least 2 points",
                          "Give `path` the points to follow, e.g. [[0,0,0],[0,1,0]].");
    const bool closed = p.closed && p.path.size() >= 3;
    // the path: control points, or a Catmull-Rom curve through them
    std::vector<Vec3> raw;
    const std::size_t n = p.path.size();
    const int sub = std::clamp(p.pathSegments, 1, 64);
    if (p.smooth && n >= 3) {
        const std::size_t spans = closed ? n : n - 1;
        auto at = [&](long i) {
            if (closed) return p.path[std::size_t(((i % long(n)) + long(n)) % long(n))];
            if (i < 0) return p.path[0] * 2.0f - p.path[1];
            if (i >= long(n)) return p.path[n - 1] * 2.0f - p.path[n - 2];
            return p.path[std::size_t(i)];
        };
        for (std::size_t sp = 0; sp < spans; ++sp)
            for (int k = 0; k < sub; ++k)
                raw.push_back(catmull_rom(at(long(sp) - 1), at(long(sp)), at(long(sp) + 1), at(long(sp) + 2),
                                          float(k) / float(sub)));
        if (!closed) raw.push_back(p.path[n - 1]);
    } else {
        raw = p.path;
    }
    std::vector<Vec3> pt;
    for (const Vec3& q : raw)
        if (pt.empty() || length(q - pt.back()) > 1e-6f) pt.push_back(q);
    if (closed && pt.size() > 1 && length(pt.back() - pt.front()) <= 1e-6f) pt.pop_back();
    const std::size_t K = pt.size();
    if (K < 2)
        return make_error("the sweep's path points are all in the same place", "Give `path` points that are apart.");
    if (K * p.profile.size() * 2 > kModelMaxTriangles)
        return make_error(std::format("the sweep would have about {} triangles ({} path samples x {} profile points), "
                                      "more than the {} a node may make",
                                      K * p.profile.size() * 2, K, p.profile.size(), kModelMaxTriangles),
                          "Lower `pathSegments` or use fewer profile points.");

    // tangents at the rings: the bisector of the two neighbouring pieces
    std::vector<Vec3> T(K);
    for (std::size_t k = 0; k < K; ++k) {
        const bool hasPrev = closed || k > 0, hasNext = closed || k + 1 < K;
        const Vec3 prev = hasPrev ? normalize(pt[k] - pt[(k + K - 1) % K]) : Vec3{0, 0, 0};
        const Vec3 next = hasNext ? normalize(pt[(k + 1) % K] - pt[k]) : Vec3{0, 0, 0};
        Vec3 t = prev + next;
        if (length_sq(t) < 1e-8f) t = hasNext ? next : prev;
        T[k] = normalize(t);
    }
    // arc length fraction at each ring
    std::vector<float> frac(K, 0.0f);
    for (std::size_t k = 1; k < K; ++k) frac[k] = frac[k - 1] + length(pt[k] - pt[k - 1]);
    float total = frac.back();
    if (closed) total += length(pt[0] - pt[K - 1]);
    total = std::max(total, 1e-9f);
    for (float& f : frac) f /= total;

    // rotation-minimising frames (double reflection): N and B = N x T
    std::vector<Vec3> N(K);
    {
        Vec3 up{0, 1, 0};
        if (std::fabs(dot(T[0], up)) > 0.999f) up = {0, 0, -1};
        const Vec3 b0 = normalize(up - T[0] * dot(up, T[0]));
        N[0] = cross(T[0], b0);
    }
    for (std::size_t k = 0; k + 1 < K; ++k) {
        const Vec3 v1 = pt[k + 1] - pt[k];
        const float c1 = dot(v1, v1);
        Vec3 rL = N[k], tL = T[k];
        if (c1 > 1e-20f) {
            rL = N[k] - v1 * (2.0f / c1 * dot(v1, N[k]));
            tL = T[k] - v1 * (2.0f / c1 * dot(v1, T[k]));
        }
        const Vec3 v2 = T[k + 1] - tL;
        const float c2 = dot(v2, v2);
        Vec3 nn = rL;
        if (c2 > 1e-20f) nn = rL - v2 * (2.0f / c2 * dot(v2, rL));
        nn = nn - T[k + 1] * dot(nn, T[k + 1]);
        N[k + 1] = unit_or(nn, N[k]);
    }
    if (closed) {
        // carry the frame once round and spread the angle it comes back turned by over the whole loop, so the ends meet
        const Vec3 v1 = pt[0] - pt[K - 1];
        const float c1 = dot(v1, v1);
        Vec3 rL = N[K - 1], tL = T[K - 1];
        if (c1 > 1e-20f) {
            rL = N[K - 1] - v1 * (2.0f / c1 * dot(v1, N[K - 1]));
            tL = T[K - 1] - v1 * (2.0f / c1 * dot(v1, T[K - 1]));
        }
        const Vec3 v2 = T[0] - tL;
        const float c2 = dot(v2, v2);
        Vec3 nEnd = rL;
        if (c2 > 1e-20f) nEnd = rL - v2 * (2.0f / c2 * dot(v2, rL));
        nEnd = unit_or(nEnd - T[0] * dot(nEnd, T[0]), N[0]);
        const float phi = degrees(det::atan2(dot(cross(nEnd, N[0]), T[0]), dot(nEnd, N[0])));
        for (std::size_t k = 0; k < K; ++k) N[k] = rotate_about(N[k], T[k], phi * frac[k]);
    }

    // the profile, counter-clockwise
    std::vector<Vec2> prof = p.profile;
    if (signed_area(prof) < 0) std::reverse(prof.begin(), prof.end());
    const std::size_t P = prof.size();
    std::vector<float> pu(P + 1, 0.0f);
    for (std::size_t i = 1; i <= P; ++i) pu[i] = pu[i - 1] + length(prof[i % P] - prof[i - 1]);
    const float plen = std::max(pu[P], 1e-9f);
    for (float& f : pu) f /= plen;

    std::vector<std::vector<Vec3>> ring(K, std::vector<Vec3>(P));
    for (std::size_t k = 0; k < K; ++k) {
        Vec3 nk = N[k];
        if (p.twist != 0) nk = rotate_about(nk, T[k], p.twist * frac[k]);
        const Vec3 bk = cross(nk, T[k]);
        const float sc = lerp(p.scaleStart, p.scaleEnd, frac[k]);
        // a corner of a straight-piece path is mitred: stretch the part of the profile that lies in the plane of the turn
        float stretch = 0;
        Vec3 turn{0, 0, 0};
        if (!p.smooth || n < 3) {
            const bool hasPrev = closed || k > 0, hasNext = closed || k + 1 < K;
            if (hasPrev && hasNext) {
                const Vec3 in = normalize(pt[k] - pt[(k + K - 1) % K]), out = normalize(pt[(k + 1) % K] - pt[k]);
                const float c = clamp(dot(in, out), -1.0f, 1.0f);
                const float halfCos = std::max(det::cos(det::acos(c) * 0.5f), 0.2f);
                turn = unit_or(out - in, Vec3{0, 0, 0});
                stretch = 1.0f / halfCos - 1.0f;
            }
        }
        for (std::size_t i = 0; i < P; ++i) {
            Vec3 o = (nk * prof[i].x + bk * prof[i].y) * sc;
            if (stretch != 0) o = o + turn * (dot(o, turn) * stretch);
            ring[k][i] = pt[k] + o;
        }
    }
    std::vector<float> vv(K + 1);
    for (std::size_t k = 0; k < K; ++k) vv[k] = frac[k];
    vv[K] = 1.0f;
    Soup s = tube(ring, true, closed, true, pu, vv, p.cap, T[0] * -1.0f, T[K - 1]);
    return from_soup(s, p.creaseAngle);
}

// ---- loft ------------------------------------------------------------------------------------------------------------------------------

Result<ModelMesh> model_loft(const ModelLoftParams& p) {
    if (p.sections.size() < 2)
        return make_error(
            "a loft needs at least 2 sections",
            "Give `sections` two or more lists of points, e.g. a square and a circle with the same number of points.");
    const std::size_t P = p.sections[0].size();
    for (std::size_t k = 0; k < p.sections.size(); ++k)
        if (p.sections[k].size() != P)
            return make_error(std::format("section {} has {} points but section 0 has {}", k, p.sections[k].size(), P),
                              "Every section of a loft needs the same number of points; the point i of one is joined "
                              "to the point i of the next.");
    if (P < (p.closed ? 3u : 2u))
        return make_error("the sections have too few points", p.closed ? "A closed section needs at least 3 points."
                                                                       : "An open section needs at least 2 points.");
    const std::size_t S = p.sections.size();
    const int steps = std::clamp(p.steps, 1, 64);
    const std::size_t R = (S - 1) * std::size_t(steps) + 1;
    if (R * P * 2 > kModelMaxTriangles)
        return make_error(std::format("the loft would have about {} triangles, more than the {} a node may make",
                                      R * P * 2, kModelMaxTriangles),
                          "Lower `steps` or use fewer points per section.");
    std::vector<std::vector<Vec3>> ring(R, std::vector<Vec3>(P));
    const bool curve = p.smooth && S >= 3;
    for (std::size_t sp = 0; sp + 1 < S; ++sp)
        for (int k = 0; k <= steps; ++k) {
            if (sp > 0 && k == 0) continue;
            const float t = float(k) / float(steps);
            const std::size_t r = sp * std::size_t(steps) + std::size_t(k);
            for (std::size_t i = 0; i < P; ++i) {
                const Vec3 p1 = p.sections[sp][i], p2 = p.sections[sp + 1][i];
                if (curve) {
                    const Vec3 p0 = sp > 0 ? p.sections[sp - 1][i] : p1 * 2.0f - p2;
                    const Vec3 p3 = sp + 2 < S ? p.sections[sp + 2][i] : p2 * 2.0f - p1;
                    ring[r][i] = catmull_rom(p0, p1, p2, p3, t);
                } else {
                    ring[r][i] = lerp(p1, p2, t);
                }
            }
        }
    auto centroid = [&](const std::vector<Vec3>& pts) {
        Vec3 c{0, 0, 0};
        for (const Vec3& q : pts) c += q;
        return c / float(pts.size());
    };
    const Vec3 dir = unit_or(centroid(ring[R - 1]) - centroid(ring[0]), Vec3{0, 1, 0});
    Vec3 newell{0, 0, 0};
    for (std::size_t i = 0; i < P; ++i) {
        const Vec3 a = ring[0][i], b = ring[0][(i + 1) % P];
        newell += Vec3{(a.y - b.y) * (a.z + b.z), (a.z - b.z) * (a.x + b.x), (a.x - b.x) * (a.y + b.y)};
    }
    // sections counter-clockwise as seen looking back along the loft's direction give outward walls with the plain winding
    const bool flip = dot(newell, dir) < 0;
    std::vector<float> u(P + 1, 0.0f);
    for (std::size_t i = 1; i <= P; ++i) u[i] = u[i - 1] + length(ring[0][i % P] - ring[0][i - 1]);
    const float len = std::max(u[P], 1e-9f);
    for (float& f : u) f /= len;
    std::vector<float> v(R + 1);
    for (std::size_t r = 0; r < R; ++r) v[r] = float(r) / float(R - 1);
    v[R] = 1.0f;
    Soup s = tube(ring, p.closed, false, flip, u, v, p.cap, dir * -1.0f, dir);
    return from_soup(s, p.creaseAngle);
}

}  // namespace fa
