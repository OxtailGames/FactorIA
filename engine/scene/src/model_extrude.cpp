// Polygon triangulation (ear clipping with the holes bridged to the outline), extrusion into a closed solid, and the `text`
// primitive built on both (fa/scene/model_kernel.h).
#include <algorithm>
#include <cmath>
#include <utility>

#include "fa/scene/model_kernel.h"

namespace fa {

namespace {

float area2(Vec2 a, Vec2 b, Vec2 c) { return cross(b - a, c - a); }
bool same(Vec2 a, Vec2 b) { return a.x == b.x && a.y == b.y; }

float signed_area(const std::vector<Vec2>& poly) {
    double s = 0;
    for (std::size_t i = 0, n = poly.size(); i < n; ++i) {
        const Vec2 a = poly[i], b = poly[(i + 1) % n];
        s += double(a.x) * double(b.y) - double(b.x) * double(a.y);
    }
    return float(s * 0.5);
}

// Inside or on the edge of the counter-clockwise triangle abc.
bool in_triangle(Vec2 a, Vec2 b, Vec2 c, Vec2 p) {
    return area2(a, b, p) >= 0 && area2(b, c, p) >= 0 && area2(c, a, p) >= 0;
}

// Do the segments pq and rs cross at a point interior to both?
bool segments_cross(Vec2 p, Vec2 q, Vec2 r, Vec2 s) {
    if (same(p, r) || same(p, s) || same(q, r) || same(q, s)) return false;
    const float d1 = area2(p, q, r), d2 = area2(p, q, s), d3 = area2(r, s, p), d4 = area2(r, s, q);
    return ((d1 > 0 && d2 < 0) || (d1 < 0 && d2 > 0)) && ((d3 > 0 && d4 < 0) || (d3 < 0 && d4 > 0));
}

// Does the direction p -> m lie inside the polygon's interior angle at p (between its neighbours, counter-clockwise polygon)?
bool in_cone(Vec2 prev, Vec2 p, Vec2 next, Vec2 m) {
    if (area2(prev, p, next) >= 0) return area2(prev, p, m) > 0 && area2(p, next, m) > 0;  // convex corner
    return !(area2(p, next, m) <= 0 && area2(prev, p, m) <= 0);                            // reflex corner
}

}  // namespace

std::vector<std::uint32_t> triangulate_polygon(const std::vector<Vec2>& outer,
                                               const std::vector<std::vector<Vec2>>& holes) {
    std::vector<std::uint32_t> out;
    if (outer.size() < 3) return out;
    std::vector<Vec2> pts = outer;
    struct HoleRing {
        std::vector<std::uint32_t> ring;  // counter-clockwise outer, clockwise holes
        float maxX = 0;
        std::uint32_t rightmost = 0;  // position in `ring` of the vertex with the largest x
    };
    std::vector<std::uint32_t> ring(outer.size());
    for (std::uint32_t i = 0; i < ring.size(); ++i) ring[i] = i;
    if (signed_area(outer) < 0) std::reverse(ring.begin(), ring.end());
    std::vector<HoleRing> pending;
    for (const auto& h : holes) {
        if (h.size() < 3) continue;
        HoleRing hr;
        const std::uint32_t base = std::uint32_t(pts.size());
        pts.insert(pts.end(), h.begin(), h.end());
        for (std::uint32_t i = 0; i < h.size(); ++i) hr.ring.push_back(base + i);
        if (signed_area(h) > 0) std::reverse(hr.ring.begin(), hr.ring.end());
        hr.maxX = -1e30f;
        for (std::uint32_t i = 0; i < hr.ring.size(); ++i)
            if (pts[hr.ring[i]].x > hr.maxX) hr.maxX = pts[hr.ring[i]].x, hr.rightmost = i;
        pending.push_back(std::move(hr));
    }
    std::stable_sort(pending.begin(), pending.end(),
                     [](const HoleRing& a, const HoleRing& b) { return a.maxX > b.maxX; });

    // Bridge each hole, the rightmost first, to the nearest vertex of the outline it can see.
    for (std::size_t hi = 0; hi < pending.size(); ++hi) {
        const HoleRing& hole = pending[hi];
        const std::size_t hn = hole.ring.size();
        const std::uint32_t mi = hole.rightmost;
        const Vec2 m = pts[hole.ring[mi]];
        const Vec2 mPrev = pts[hole.ring[(mi + hn - 1) % hn]], mNext = pts[hole.ring[(mi + 1) % hn]];
        std::size_t best = ring.size();
        float bestDist = 1e30f;
        bool bestVisible = false;
        for (std::size_t pi = 0; pi < ring.size(); ++pi) {
            const Vec2 p = pts[ring[pi]];
            const float d = length_sq(p - m);
            const bool visible = [&] {
                const std::size_t rn = ring.size();
                if (!in_cone(pts[ring[(pi + rn - 1) % rn]], p, pts[ring[(pi + 1) % rn]], m)) return false;
                if (!in_cone(mPrev, m, mNext, p)) return false;
                for (std::size_t e = 0; e < rn; ++e)
                    if (segments_cross(m, p, pts[ring[e]], pts[ring[(e + 1) % rn]])) return false;
                for (std::size_t oj = hi; oj < pending.size(); ++oj) {
                    const auto& other = pending[oj].ring;
                    for (std::size_t e = 0; e < other.size(); ++e)
                        if (segments_cross(m, p, pts[other[e]], pts[other[(e + 1) % other.size()]])) return false;
                }
                return true;
            }();
            if ((visible && !bestVisible) || (visible == bestVisible && d < bestDist))
                best = pi, bestDist = d, bestVisible = visible;
        }
        // ... P, M, the hole all the way round back to M, P again, ...
        std::vector<std::uint32_t> merged(ring.begin(), ring.begin() + std::ptrdiff_t(best) + 1);
        for (std::size_t k = 0; k <= hn; ++k) merged.push_back(hole.ring[(mi + k) % hn]);
        merged.push_back(ring[best]);
        merged.insert(merged.end(), ring.begin() + std::ptrdiff_t(best) + 1, ring.end());
        ring = std::move(merged);
    }

    // Ear clipping.
    std::size_t start = 0;
    while (ring.size() > 3) {
        const std::size_t n = ring.size();
        bool clipped = false;
        for (std::size_t step = 0; step < n && !clipped; ++step) {
            const std::size_t i = (start + step) % n, pi = (i + n - 1) % n, ni = (i + 1) % n;
            const Vec2 a = pts[ring[pi]], b = pts[ring[i]], c = pts[ring[ni]];
            if (area2(a, b, c) <= 0) continue;
            bool ear = true;
            for (std::size_t j = 0; j < n && ear; ++j) {
                if (j == pi || j == i || j == ni) continue;
                const Vec2 q = pts[ring[j]];
                if (same(q, a) || same(q, b) || same(q, c)) continue;
                if (in_triangle(a, b, c, q)) ear = false;
            }
            if (!ear) continue;
            out.push_back(ring[pi]);
            out.push_back(ring[i]);
            out.push_back(ring[ni]);
            ring.erase(ring.begin() + std::ptrdiff_t(i));
            start = i == 0 ? 0 : i - 1;
            clipped = true;
        }
        if (clipped) continue;
        // No ear: the polygon is not simple. Drop a flat vertex, else cut the first convex one anyway, so this always ends.
        std::size_t drop = n;
        for (std::size_t i = 0; i < n && drop == n; ++i)
            if (area2(pts[ring[(i + n - 1) % n]], pts[ring[i]], pts[ring[(i + 1) % n]]) <= 0) drop = i;
        if (drop == n) {
            drop = 0;
            out.push_back(ring[n - 1]);
            out.push_back(ring[0]);
            out.push_back(ring[1]);
        }
        ring.erase(ring.begin() + std::ptrdiff_t(drop));
        start = 0;
    }
    if (ring.size() == 3 && area2(pts[ring[0]], pts[ring[1]], pts[ring[2]]) > 0) {
        out.push_back(ring[0]);
        out.push_back(ring[1]);
        out.push_back(ring[2]);
    }
    return out;
}

namespace {

// Repeated points and points on a straight run carry nothing; they would only make T-junctions between a cap and the walls.
void clean_contour(std::vector<Vec2>& c) {
    bool changed = true;
    while (changed && c.size() >= 3) {
        changed = false;
        for (std::size_t i = 0; i < c.size() && c.size() >= 3; ++i) {
            const std::size_t n = c.size();
            const Vec2 a = c[(i + n - 1) % n], b = c[i], d = c[(i + 1) % n];
            const Vec2 e1 = b - a, e2 = d - b;
            const float l1 = length(e1), l2 = length(e2);
            const bool repeated = l1 < 1e-7f;
            const bool flat = std::fabs(cross(e1, e2)) <= 1e-6f * l1 * l2 && dot(e1, e2) > 0;
            if (repeated || flat) {
                c.erase(c.begin() + std::ptrdiff_t(i));
                changed = true;
                --i;
            }
        }
    }
}

}  // namespace

ModelMesh extrude_polygons(const std::vector<ModelPolygon>& polygons, float depth, float creaseDeg) {
    ModelMesh m;
    const float h = std::max(depth, 1e-4f) * 0.5f;
    const float creaseCos = det::cos(radians(creaseDeg));
    std::vector<ModelPolygon> polys;
    Vec2 bmin{1e30f, 1e30f}, bmax{-1e30f, -1e30f};
    for (ModelPolygon p : polygons) {
        clean_contour(p.outer);
        if (p.outer.size() < 3) continue;
        if (signed_area(p.outer) < 0) std::reverse(p.outer.begin(), p.outer.end());
        std::vector<std::vector<Vec2>> holes;
        for (auto& hole : p.holes) {
            clean_contour(hole);
            if (hole.size() < 3) continue;
            if (signed_area(hole) > 0) std::reverse(hole.begin(), hole.end());
            holes.push_back(std::move(hole));
        }
        p.holes = std::move(holes);
        for (const Vec2& v : p.outer) bmin = min(bmin, v), bmax = max(bmax, v);
        polys.push_back(std::move(p));
    }
    if (polys.empty()) return m;
    const Vec2 span{std::max(bmax.x - bmin.x, 1e-6f), std::max(bmax.y - bmin.y, 1e-6f)};
    auto cap_uv = [&](Vec2 p) { return Vec2{(p.x - bmin.x) / span.x, 1.0f - (p.y - bmin.y) / span.y}; };

    auto add_vertex = [&](Vec3 pos, Vec3 nor, Vec2 uv) {
        m.positions.push_back(pos);
        m.normals.push_back(nor);
        m.uvs.push_back(uv);
        return std::uint32_t(m.positions.size() - 1);
    };

    for (const ModelPolygon& poly : polys) {
        std::vector<Vec2> all = poly.outer;
        for (const auto& hole : poly.holes) all.insert(all.end(), hole.begin(), hole.end());
        const std::vector<std::uint32_t> tris = triangulate_polygon(poly.outer, poly.holes);
        const std::uint32_t front = std::uint32_t(m.positions.size());
        for (const Vec2& p : all) add_vertex({p.x, p.y, h}, {0, 0, 1}, cap_uv(p));
        const std::uint32_t back = std::uint32_t(m.positions.size());
        for (const Vec2& p : all) add_vertex({p.x, p.y, -h}, {0, 0, -1}, cap_uv(p));
        for (std::size_t i = 0; i + 2 < tris.size(); i += 3) {
            m.indices.push_back(front + tris[i]);
            m.indices.push_back(front + tris[i + 1]);
            m.indices.push_back(front + tris[i + 2]);
            m.indices.push_back(back + tris[i]);
            m.indices.push_back(back + tris[i + 2]);
            m.indices.push_back(back + tris[i + 1]);
        }

        // Walls: the solid is on the left of every contour (the outline counter-clockwise, the holes clockwise), so the outward
        // normal is the right-hand side of the direction of travel.
        auto wall = [&](const std::vector<Vec2>& c) {
            const std::size_t n = c.size();
            std::vector<Vec3> edgeN(n);
            std::vector<float> run(n + 1, 0.0f);
            for (std::size_t i = 0; i < n; ++i) {
                const Vec2 d = c[(i + 1) % n] - c[i];
                const Vec2 dn = normalize(d);
                edgeN[i] = {dn.y, -dn.x, 0};
                run[i + 1] = run[i] + length(d);
            }
            const float total = std::max(run[n], 1e-6f);
            for (std::size_t i = 0; i < n; ++i) {
                const std::size_t prev = (i + n - 1) % n, next = (i + 1) % n;
                auto corner = [&](std::size_t other) {
                    const bool smooth = dot(edgeN[i], edgeN[other]) > creaseCos;
                    return smooth ? normalize(edgeN[i] + edgeN[other]) : edgeN[i];
                };
                const Vec3 na = corner(prev), nb = corner(next);
                const Vec2 a = c[i], b = c[next];
                const float ua = run[i] / total, ub = run[i + 1] / total;
                const std::uint32_t ab = add_vertex({a.x, a.y, -h}, na, {ua, 1});
                const std::uint32_t bb = add_vertex({b.x, b.y, -h}, nb, {ub, 1});
                const std::uint32_t bf = add_vertex({b.x, b.y, h}, nb, {ub, 0});
                const std::uint32_t af = add_vertex({a.x, a.y, h}, na, {ua, 0});
                m.indices.insert(m.indices.end(), {ab, bb, bf, ab, bf, af});
            }
        };
        wall(poly.outer);
        for (const auto& hole : poly.holes) wall(hole);
    }
    m.triParts.assign(m.triangle_count(), 0);
    return m;
}

// ---- text --------------------------------------------------------------------------------------------------------------

namespace {

bool point_in_polygon(const std::vector<Vec2>& poly, Vec2 p) {
    bool inside = false;
    for (std::size_t i = 0, j = poly.size() - 1; i < poly.size(); j = i++) {
        const Vec2 a = poly[i], b = poly[j];
        if ((a.y > p.y) != (b.y > p.y) && p.x < (b.x - a.x) * (p.y - a.y) / (b.y - a.y) + a.x) inside = !inside;
    }
    return inside;
}

}  // namespace

ModelMesh model_text(const ModelTextOutline& outline, const ModelTextParams& p) {
    const int curveSegs = std::max(1, std::min(p.curveSegments, 64));
    const float size = std::max(p.size, 1e-4f);
    std::vector<std::vector<Vec2>> contours;
    std::vector<Vec2> cur;
    Vec2 pen{};
    auto point = [&](float x, float y) { return Vec2{x * size, -y * size}; };  // em units, y down -> meters, y up
    auto finish = [&] {
        if (cur.size() >= 3) contours.push_back(cur);
        cur.clear();
    };
    for (const ModelGlyphCmd& c : outline.cmds) {
        switch (c.kind) {
            case ModelGlyphCmd::Move:
                finish();
                pen = point(c.x, c.y);
                cur.push_back(pen);
                break;
            case ModelGlyphCmd::Line:
                pen = point(c.x, c.y);
                cur.push_back(pen);
                break;
            case ModelGlyphCmd::Quad: {
                const Vec2 p0 = pen, p1 = point(c.cx, c.cy), p2 = point(c.x, c.y);
                for (int i = 1; i <= curveSegs; ++i) {
                    const float t = float(i) / float(curveSegs), u = 1.0f - t;
                    cur.push_back(p0 * (u * u) + p1 * (2 * u * t) + p2 * (t * t));
                }
                pen = p2;
                break;
            }
            case ModelGlyphCmd::Cubic: {
                const Vec2 p0 = pen, p1 = point(c.cx, c.cy), p2 = point(c.dx, c.dy), p3 = point(c.x, c.y);
                for (int i = 1; i <= curveSegs; ++i) {
                    const float t = float(i) / float(curveSegs), u = 1.0f - t;
                    cur.push_back(p0 * (u * u * u) + p1 * (3 * u * u * t) + p2 * (3 * u * t * t) + p3 * (t * t * t));
                }
                pen = p3;
                break;
            }
            case ModelGlyphCmd::Close: finish(); break;
        }
    }
    finish();
    for (auto& c : contours) clean_contour(c);
    contours.erase(std::remove_if(contours.begin(), contours.end(), [](const auto& c) { return c.size() < 3; }),
                   contours.end());
    if (contours.empty()) return {};

    // Nesting decides what is a hole: a contour inside an odd number of others cuts the smallest one around it.
    const std::size_t n = contours.size();
    std::vector<float> areas(n);
    for (std::size_t i = 0; i < n; ++i) areas[i] = std::fabs(signed_area(contours[i]));
    std::vector<int> depthOf(n, 0), parent(n, -1);
    for (std::size_t i = 0; i < n; ++i) {
        for (std::size_t j = 0; j < n; ++j) {
            if (i == j || areas[j] <= areas[i] || !point_in_polygon(contours[j], contours[i][0])) continue;
            ++depthOf[i];
            if (parent[i] < 0 || areas[j] < areas[std::size_t(parent[i])]) parent[i] = int(j);
        }
    }
    std::vector<ModelPolygon> polys;
    std::vector<int> polyOf(n, -1);
    for (std::size_t i = 0; i < n; ++i)
        if (depthOf[i] % 2 == 0) {
            polyOf[i] = int(polys.size());
            ModelPolygon poly;
            poly.outer = contours[i];
            polys.push_back(std::move(poly));
        }
    for (std::size_t i = 0; i < n; ++i)
        if (depthOf[i] % 2 == 1 && parent[i] >= 0 && polyOf[std::size_t(parent[i])] >= 0)
            polys[std::size_t(polyOf[std::size_t(parent[i])])].holes.push_back(contours[i]);
    return extrude_polygons(polys, p.depth, 40.0f);
}

}  // namespace fa
