// Area and portal culling, the pure part (portal_graph.h).
#include "portal_graph.h"

#include <algorithm>
#include <cmath>
#include <limits>
#include <utility>

namespace fa::render {

namespace {

constexpr float kMinW = 1.0e-4f;  // a corner closer than this to the camera plane is clipped at it

struct Rect {
    float x0 = -1, y0 = -1, x1 = 1, y1 = 1;
    bool empty() const { return !(x0 <= x1) || !(y0 <= y1); }
    bool contains(const Rect& o) const { return x0 <= o.x0 && y0 <= o.y0 && x1 >= o.x1 && y1 >= o.y1; }
};

float axis_len(const Mat4& m, int col) {
    return std::sqrt(m.at(col, 0) * m.at(col, 0) + m.at(col, 1) * m.at(col, 1) + m.at(col, 2) * m.at(col, 2));
}

bool holds(const Mat4& inv, Vec3 size, Vec3 p) {
    const Vec3 l = inv.transform_point(p);
    return std::fabs(l.x) <= size.x * 0.5f && std::fabs(l.y) <= size.y * 0.5f && std::fabs(l.z) <= size.z * 0.5f;
}

bool inside(const PortalAreaBox& a, Vec3 p) { return a.valid && holds(a.inv, a.size, p); }
bool inside(const PortalBox& a, Vec3 p) { return a.valid && holds(a.inv, a.size, p); }

// The screen rectangle of a portal's box, clipped at the camera plane. False when the box is wholly behind the camera or not finite.
bool project_box(const PortalBox& p, const Mat4& viewProj, Rect& out) {
    Vec4 c[8];
    const Mat4 mvp = viewProj * p.model;
    for (int k = 0; k < 8; ++k) {
        const Vec4 v{(k & 1) ? p.size.x * 0.5f : -p.size.x * 0.5f, (k & 2) ? p.size.y * 0.5f : -p.size.y * 0.5f,
                     (k & 4) ? p.size.z * 0.5f : -p.size.z * 0.5f, 1.0f};
        c[k] = mvp * v;
        if (!std::isfinite(c[k].x + c[k].y + c[k].z + c[k].w)) return false;
    }
    constexpr float inf = std::numeric_limits<float>::infinity();
    Rect r{inf, inf, -inf, -inf};
    bool any = false;
    auto add = [&](float x, float y, float w) {
        r.x0 = std::min(r.x0, x / w);
        r.x1 = std::max(r.x1, x / w);
        r.y0 = std::min(r.y0, y / w);
        r.y1 = std::max(r.y1, y / w);
        any = true;
    };
    for (int k = 0; k < 8; ++k)
        if (c[k].w >= kMinW) add(c[k].x, c[k].y, c[k].w);
    static constexpr int edges[12][2] = {{0, 1}, {2, 3}, {4, 5}, {6, 7}, {0, 2}, {1, 3},
                                         {4, 6}, {5, 7}, {0, 4}, {1, 5}, {2, 6}, {3, 7}};
    for (const auto& e : edges) {
        const Vec4 &a = c[e[0]], &b = c[e[1]];
        if ((a.w >= kMinW) == (b.w >= kMinW)) continue;  // wholly on one side
        const float t = (kMinW - a.w) / (b.w - a.w);
        add(a.x + (b.x - a.x) * t, a.y + (b.y - a.y) * t, kMinW);
    }
    if (!any) return false;
    out = r;
    return true;
}

struct Walker {
    const std::vector<PortalBox>& portals;
    const Mat4& viewProj;
    std::vector<std::int32_t> path;
    std::vector<std::pair<std::int32_t, Rect>> seen;  // every (area, rectangle) visit so far
    std::vector<std::int32_t> reached;
    std::vector<std::size_t> used;  // indices of the portals gone through
    int steps = 0;
    bool capped = false;

    void visit(std::int32_t area, const Rect& view) {
        for (const auto& s : seen)
            if (s.first == area && s.second.contains(view)) return;  // an earlier visit saw all of this
        seen.emplace_back(area, view);
        if (std::find(reached.begin(), reached.end(), area) == reached.end()) reached.push_back(area);
        if (int(path.size()) >= kPortalMaxDepth) {
            capped =
                true;  // a deeper chain than any real building: the answer is not known, the caller draws everything
            return;
        }
        path.push_back(area);
        for (std::size_t i = 0; i < portals.size(); ++i) {
            const PortalBox& p = portals[i];
            if (!p.open) continue;
            std::int32_t other;
            if (p.areaA == area)
                other = p.areaB;
            else if (p.areaB == area)
                other = p.areaA;
            else
                continue;
            if (other == area || std::find(path.begin(), path.end(), other) != path.end()) continue;  // a cycle
            if (++steps > kPortalMaxSteps) {
                capped = true;
                break;
            }
            Rect pr;
            if (!project_box(p, viewProj, pr)) continue;
            Rect next{std::max(view.x0, pr.x0), std::max(view.y0, pr.y0), std::min(view.x1, pr.x1),
                      std::min(view.y1, pr.y1)};
            if (next.empty()) continue;
            if (std::find(used.begin(), used.end(), i) == used.end()) used.push_back(i);
            visit(other, next);
            if (capped) break;
        }
        path.pop_back();
    }
};

}  // namespace

PortalAreaBox make_portal_area(std::int32_t id, const Mat4& model, Vec3 size, std::uint64_t entity) {
    PortalAreaBox b;
    b.id = id;
    b.model = model;
    b.size = size;
    b.entity = entity;
    b.valid = axis_len(model, 0) > 1e-6f && axis_len(model, 1) > 1e-6f && axis_len(model, 2) > 1e-6f &&
              std::isfinite(size.x + size.y + size.z);
    if (b.valid) b.inv = model.inverse();
    return b;
}

PortalBox make_portal_box(std::int32_t areaA, std::int32_t areaB, const Mat4& model, Vec3 size, bool open,
                          std::uint64_t entity) {
    PortalBox b;
    b.areaA = areaA;
    b.areaB = areaB;
    b.model = model;
    b.size = size;
    b.open = open;
    b.entity = entity;
    b.valid = axis_len(model, 0) > 1e-6f && axis_len(model, 1) > 1e-6f && axis_len(model, 2) > 1e-6f &&
              std::isfinite(size.x + size.y + size.z);
    if (b.valid) b.inv = model.inverse();
    return b;
}

std::vector<std::int32_t> portal_start_areas(const std::vector<PortalAreaBox>& areas, const std::vector<PortalBox>& portals,
                                             Vec3 p) {
    std::vector<std::int32_t> out;
    for (const PortalAreaBox& a : areas)
        if (inside(a, p)) out.push_back(a.id);
    for (const PortalBox& d : portals)
        if (d.open && inside(d, p)) {
            out.push_back(d.areaA);
            out.push_back(d.areaB);
        }
    if (out.empty()) out.push_back(0);
    std::sort(out.begin(), out.end());
    out.erase(std::unique(out.begin(), out.end()), out.end());
    return out;
}

bool portal_mesh_seen(const std::vector<PortalAreaBox>& areas, const std::vector<std::int32_t>& reached, const Mat4& model,
                      Vec3 bmin, Vec3 bmax) {
    auto reachedId = [&](std::int32_t id) { return std::binary_search(reached.begin(), reached.end(), id); };
    bool whollyInside = false;
    for (const PortalAreaBox& a : areas) {
        if (!a.valid) continue;
        const Mat4 m = a.inv * model;  // model space of the mesh -> local space of the area
        constexpr float inf = std::numeric_limits<float>::infinity();
        Vec3 lo{inf, inf, inf}, hi{-inf, -inf, -inf};
        for (int k = 0; k < 8; ++k) {
            const Vec3 c = m.transform_point({(k & 1) ? bmax.x : bmin.x, (k & 2) ? bmax.y : bmin.y, (k & 4) ? bmax.z : bmin.z});
            lo = {std::min(lo.x, c.x), std::min(lo.y, c.y), std::min(lo.z, c.z)};
            hi = {std::max(hi.x, c.x), std::max(hi.y, c.y), std::max(hi.z, c.z)};
        }
        const Vec3 h = a.size * 0.5f;
        if (!(lo.x <= h.x && hi.x >= -h.x && lo.y <= h.y && hi.y >= -h.y && lo.z <= h.z && hi.z >= -h.z)) continue;
        if (reachedId(a.id)) return true;  // touches a room the camera sees
        if (lo.x >= -h.x && hi.x <= h.x && lo.y >= -h.y && hi.y <= h.y && lo.z >= -h.z && hi.z <= h.z)
            whollyInside = true;
    }
    return !whollyInside && reachedId(0);  // outside: in no box, or sticking out of every box it touches
}

PortalWalk portal_walk(const std::vector<PortalBox>& portals, const Mat4& viewProj,
                       const std::vector<std::int32_t>& startAreas) {
    Walker w{portals, viewProj, {}, {}, {}, {}, 0, false};
    for (const std::int32_t start : startAreas) {
        w.visit(start, Rect{});
        if (w.capped) break;
    }
    PortalWalk out;
    out.reached = std::move(w.reached);
    std::sort(out.reached.begin(), out.reached.end());
    out.portalsVisited = int(w.used.size());
    out.capped = w.capped;
    return out;
}

}  // namespace fa::render
