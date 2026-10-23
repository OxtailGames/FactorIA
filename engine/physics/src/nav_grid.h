// Private: the navigation grid behind NavMesh3D (a 2.5D heightfield of walkable spans). It knows nothing about colliders:
// Physics3D rasterises them into solid intervals per cell (nav3d.cpp) and the grid does the rest, which makes it testable
// and keeps every step deterministic (fixed iteration order, total orderings, no hashing of pointers).
#pragma once

#include <cstdint>
#include <map>
#include <vector>

#include "fa/core/math.h"

namespace fa::detail {

// A column of solid matter in one cell: from `bottom` to `top`; `topNormalY` is the up component of the surface normal
// at the top (1 = flat ground).
struct NavSolid {
    float bottom = 0.0f, top = 0.0f, topNormalY = 1.0f;
};
struct NavEntry {
    std::int32_t cell = 0;
    NavSolid solid;
};

struct NavParams {
    Vec3 origin;  // minimum corner of the bounds
    int nx = 0, nz = 0;
    float cell = 0.25f, cellHeight = 0.05f;
    float radius = 0.3f, height = 1.8f, step = 0.4f, maxSlopeDeg = 45.0f;
    float yMin = 0.0f, yMax = 0.0f;  // vertical range of the bounds
};

class NavGrid {
public:
    struct Span {
        float y = 0.0f;       // height of the walkable surface (a multiple of cellHeight)
        float ceil = 1e30f;   // underside of whatever is above (1e30 = open sky)
        std::int32_t cell = 0;
        std::int32_t region = 0;  // 1-based walkable area; 0 = eroded
        std::int32_t block = 0;   // how many obstacles cover this span now
        bool eroded = false;      // too close to a wall or a drop for the agent's radius
    };
    struct Footprint {
        std::int32_t cell = 0;
        float bottom = 0.0f, top = 0.0f;
    };

    // Builds the grid from solid intervals (entries are sorted and consumed).
    void build(const NavParams& params, std::vector<NavEntry>& entries);

    const NavParams& params() const { return p_; }
    int span_count() const { return int(spans_.size()); }
    int walkable_count() const { return walkable_; }  // spans that survived erosion
    int region_count() const { return regions_; }
    const Span& span(int s) const { return spans_[std::size_t(s)]; }
    bool usable(int s) const { return !spans_[std::size_t(s)].eroded && spans_[std::size_t(s)].block == 0; }
    Vec3 center(int s) const;  // world position of the span's surface at the cell centre
    int cell_x(int cell) const { return cell % p_.nx; }
    int cell_z(int cell) const { return cell / p_.nx; }
    int cell_at(float x, float z) const;  // -1 outside the grid
    bool inside(Vec3 p) const;            // within the baked bounds

    // The usable span under/at `p` in its own cell: the highest surface in [p.y - reachDown, p.y + reachUp]. -1 if none.
    int find_span(Vec3 p, float reachDown, float reachUp) const;
    // The nearest usable span (horizontal distance, then lowest index) within `maxDist` whose surface is in the same
    // vertical window. -1 if none.
    int nearest_span(Vec3 p, float reachDown, float reachUp, float maxDist, float* dist = nullptr) const;
    // The nearest usable span anywhere (3D distance); -1 if the grid has none.
    int nearest_anywhere(Vec3 p, float* dist = nullptr) const;

    // A* from `start` to `goal` over usable spans. Returns the span chain (start..goal) when reached; otherwise an empty
    // chain, and `closest` = the reached span nearest to the goal.
    std::vector<int> search(int start, int goal, int* closest = nullptr) const;
    // String pulling: keeps the spans that are corners of a straight walk over usable cells.
    std::vector<int> pull(const std::vector<int>& chain) const;
    bool line_clear(int a, int b) const;

    // Moving obstacles: blocks the spans their footprint (plus the agent radius) covers. Replaces the previous
    // footprint of the same key, touching only the spans involved.
    void set_obstacle(std::uint64_t key, const std::vector<Footprint>& footprint);
    void clear_obstacle(std::uint64_t key);
    std::size_t obstacle_count() const { return obstacles_.size(); }

private:
    NavParams p_;
    std::vector<std::int32_t> cellFirst_;  // spans of cell c: [cellFirst_[c], cellFirst_[c + 1])
    std::vector<Span> spans_;
    std::vector<std::int32_t> links_;      // 8 per span: neighbour span or -1
    int walkable_ = 0, regions_ = 0;
    std::map<std::uint64_t, std::vector<std::int32_t>> obstacles_;  // key -> spans it blocks
    // Search scratch (a query is single-threaded), reset by a stamp instead of clearing.
    mutable std::vector<float> g_;
    mutable std::vector<std::int32_t> parent_, stamp_, closed_;
    mutable std::int32_t stampNow_ = 0;

    int link(int s, int dir) const { return links_[std::size_t(s) * 8 + std::size_t(dir)]; }
    int pick_neighbour(int s, int nx, int nz) const;
    void make_links();
    void erode();
    void make_regions();
    float quantize(float y) const;
};

}  // namespace fa::detail
