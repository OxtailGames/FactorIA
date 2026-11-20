// A bounding volume hierarchy over triangles for ray queries, the same on every platform: the tree depends only on the
// triangles (a median split on the longest axis of the centroids, ties broken by triangle index) and the queries use + - * /
// and compares only, so a ray gives the same hit with any thread count. Used by the model texture maps (ambient occlusion,
// thickness) and by the lightmap baker (lightmap_bake.h). Both faces of a triangle are hit; a triangle with no area is left out.
#pragma once

#include <cstddef>
#include <cstdint>
#include <vector>

#include "fa/core/math.h"

namespace fa {

struct RayHit {
    float t = -1;           // distance along the (unit) direction
    std::int32_t tri = -1;  // index of the triangle in the order given to build(), -1 for no hit
    float u = 0, v = 0;     // barycentric weights of corners 1 and 2 at the hit (corner 0 weighs 1 - u - v)
};

class TriBvh {
public:
    // `corners` holds three points per triangle (triangle t is corners[3t], corners[3t + 1], corners[3t + 2]); they are copied.
    void build(const Vec3* corners, std::size_t triangleCount);
    std::size_t triangle_count() const { return corners_.size() / 3; }
    bool empty() const { return nodes_.empty(); }
    Vec3 bounds_min() const { return lo_; }
    Vec3 bounds_max() const { return hi_; }

    // The nearest hit of the ray `origin + t * dir` (dir unit) with 1e-7 < t < tmax, ignoring triangle `skip`. False for none.
    bool closest(Vec3 origin, Vec3 dir, float tmax, std::int32_t skip, RayHit& hit) const;
    // True when anything is hit before tmax (stops at the first one found: cheaper than closest()).
    bool occluded(Vec3 origin, Vec3 dir, float tmax, std::int32_t skip) const;
    // Distance of the nearest hit, or a negative number for none.
    float nearest(Vec3 origin, Vec3 dir, float tmax, std::int32_t skip) const;

private:
    struct Node {
        Vec3 lo, hi;
        std::uint32_t a = 0, b = 0;  // inner: children; leaf: first (in order_) and count
        bool leaf = false;
    };
    std::uint32_t build_range(std::uint32_t first, std::uint32_t count);
    bool query(Vec3 origin, Vec3 dir, float tmax, std::int32_t skip, bool anyHit, RayHit& hit) const;
    std::vector<Vec3> corners_;
    std::vector<Node> nodes_;
    std::vector<std::uint32_t> order_;
    std::vector<Vec3> centroid_;
    Vec3 lo_{}, hi_{};
};

}  // namespace fa
