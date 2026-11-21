#include "fa/scene/bvh.h"

#include <algorithm>
#include <cmath>
#include <utility>

namespace fa {

bool TriBvh::build(const Vec3* corners, std::size_t triangleCount, const std::atomic<bool>* cancel) {
    return build(std::vector<Vec3>(corners, corners + triangleCount * 3), cancel);
}

bool TriBvh::build(std::vector<Vec3>&& corners, const std::atomic<bool>* cancel) {
    corners_ = std::move(corners);
    const std::size_t triangleCount = corners_.size() / 3;
    corners_.resize(triangleCount * 3);
    nodes_.clear();
    order_.clear();
    lo_ = hi_ = Vec3{};
    centroid_.assign(triangleCount, Vec3{});
    for (std::size_t t = 0; t < triangleCount; ++t) {
        const Vec3 a = corners_[3 * t], b = corners_[3 * t + 1], c = corners_[3 * t + 2];
        centroid_[t] = (a + b + c) / 3.0f;
        if (length(cross(b - a, c - a)) > 0.0f) order_.push_back(std::uint32_t(t));
    }
    if (order_.empty()) return true;
    nodes_.reserve(order_.size() / 2 + 2);
    build_range(0, std::uint32_t(order_.size()), cancel);
    if (cancel && cancel->load(std::memory_order_relaxed)) {
        nodes_.clear();
        order_.clear();
        return false;
    }
    lo_ = nodes_[0].lo;
    hi_ = nodes_[0].hi;
    return true;
}

std::uint32_t TriBvh::build_range(std::uint32_t first, std::uint32_t count, const std::atomic<bool>* cancel) {
    const std::uint32_t self = std::uint32_t(nodes_.size());
    nodes_.emplace_back();
    if (cancel && count > 4 && cancel->load(std::memory_order_relaxed)) {  // the caller throws the tree away
        nodes_[self].leaf = true;
        nodes_[self].a = first;
        nodes_[self].b = 0;
        return self;
    }
    Vec3 lo = corners_[3 * std::size_t(order_[first])], hi = lo;
    Vec3 clo = centroid_[order_[first]], chi = clo;
    for (std::uint32_t k = first; k < first + count; ++k) {
        for (std::size_t c = 0; c < 3; ++c) {
            lo = min(lo, corners_[3 * std::size_t(order_[k]) + c]);
            hi = max(hi, corners_[3 * std::size_t(order_[k]) + c]);
        }
        clo = min(clo, centroid_[order_[k]]);
        chi = max(chi, centroid_[order_[k]]);
    }
    nodes_[self].lo = lo;
    nodes_[self].hi = hi;
    if (count <= 4) {
        nodes_[self].leaf = true;
        nodes_[self].a = first;
        nodes_[self].b = count;
        return self;
    }
    const Vec3 ext = chi - clo;
    const int axis = ext.x >= ext.y && ext.x >= ext.z ? 0 : (ext.y >= ext.z ? 1 : 2);
    std::sort(order_.begin() + first, order_.begin() + first + count, [&](std::uint32_t l, std::uint32_t r) {
        const float cl = centroid_[l][axis], cr = centroid_[r][axis];
        return cl != cr ? cl < cr : l < r;  // a total order: the same tree on every platform
    });
    const std::uint32_t half = count / 2;
    const std::uint32_t left = build_range(first, half, cancel);
    const std::uint32_t right = build_range(first + half, count - half, cancel);
    nodes_[self].a = left;
    nodes_[self].b = right;
    return self;
}

bool TriBvh::query(Vec3 o, Vec3 d, float tmax, std::int32_t skip, bool anyHit, RayHit& out) const {
    if (nodes_.empty()) return false;
    const Vec3 inv{std::fabs(d.x) > 1e-12f ? 1.0f / d.x : 1e12f, std::fabs(d.y) > 1e-12f ? 1.0f / d.y : 1e12f,
                   std::fabs(d.z) > 1e-12f ? 1.0f / d.z : 1e12f};
    float best = tmax;
    bool hit = false;
    std::uint32_t stack[128];
    int sp = 0;
    stack[sp++] = 0;
    auto box = [&](const Node& n) {
        float t0 = 0, t1 = best;
        for (int a = 0; a < 3; ++a) {
            float ta = (n.lo[a] - o[a]) * inv[a], tb = (n.hi[a] - o[a]) * inv[a];
            if (ta > tb) std::swap(ta, tb);
            t0 = std::max(t0, ta);
            t1 = std::min(t1, tb);
            if (t0 > t1) return false;
        }
        return true;
    };
    while (sp > 0) {
        const Node& n = nodes_[stack[--sp]];
        if (!box(n)) continue;
        if (n.leaf) {
            for (std::uint32_t k = n.a; k < n.a + n.b; ++k) {
                const std::uint32_t t = order_[k];
                if (std::int32_t(t) == skip) continue;
                const Vec3 p0 = corners_[3 * std::size_t(t)], e1 = corners_[3 * std::size_t(t) + 1] - p0,
                           e2 = corners_[3 * std::size_t(t) + 2] - p0;
                const Vec3 pv = cross(d, e2);
                const float det = dot(e1, pv);
                if (std::fabs(det) < 1e-14f) continue;
                const float idet = 1.0f / det;
                const Vec3 tv = o - p0;
                const float u = dot(tv, pv) * idet;
                if (u < 0 || u > 1) continue;
                const Vec3 qv = cross(tv, e1);
                const float v = dot(d, qv) * idet;
                if (v < 0 || u + v > 1) continue;
                const float tt = dot(e2, qv) * idet;
                if (tt > 1e-7f && tt < best) {
                    best = tt;
                    hit = true;
                    out.t = tt;
                    out.tri = std::int32_t(t);
                    out.u = u;
                    out.v = v;
                    if (anyHit) return true;
                }
            }
        } else {
            stack[sp++] = n.b;
            stack[sp++] = n.a;
        }
    }
    return hit;
}

bool TriBvh::closest(Vec3 o, Vec3 d, float tmax, std::int32_t skip, RayHit& hit) const {
    hit = RayHit{};
    return query(o, d, tmax, skip, false, hit);
}

bool TriBvh::occluded(Vec3 o, Vec3 d, float tmax, std::int32_t skip) const {
    RayHit h;
    return query(o, d, tmax, skip, true, h);
}

float TriBvh::nearest(Vec3 o, Vec3 d, float tmax, std::int32_t skip) const {
    RayHit h;
    return query(o, d, tmax, skip, false, h) ? h.t : -1.0f;
}

}  // namespace fa
