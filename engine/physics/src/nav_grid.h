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
        std::int32_t block = 0;   // how many obstacles (or walkable bodies over it) cover this span now
        std::int32_t gen = 0;     // dynamic spans: bumped each time the slot is reused (stale references are ignored)
        std::int32_t next = -1;   // dynamic spans: next span of the same cell
        bool eroded = false;      // too close to a wall or a drop for the agent's radius, NOW (counts walkable bodies)
        bool erodedBase = false;  // the same without any walkable body: what the bake found
        bool dynamic = false;     // top surface of a walkable moving body (Collider3D.navWalkable)
        bool alive = true;        // dynamic slots: false while free
    };
    // An off-mesh link joined to two spans (NavLink3D). `id` is the index the caller gave it.
    struct LinkEdge {
        std::int32_t id = 0, from = -1, to = -1;
        float cost = 0.0f;  // extra path length (meters) added to the straight distance
    };
    struct Footprint {
        std::int32_t cell = 0;
        float bottom = 0.0f, top = 0.0f;
    };

    // Builds the grid from solid intervals (entries are sorted and consumed).
    void build(const NavParams& params, std::vector<NavEntry>& entries);

    const NavParams& params() const { return p_; }
    int span_count() const { return int(spans_.size()); }          // baked (static) spans
    int total_count() const { return int(spans_.size() + dyn_.size()); }  // static + dynamic slots (free ones are not usable)
    int static_count() const { return int(spans_.size()); }
    int walkable_count() const { return walkable_; }  // spans that survived erosion
    int region_count() const { return regions_; }
    const Span& span(int s) const { return sp(s); }
    bool usable(int s) const { const Span& a = sp(s); return a.alive && !a.eroded && a.block == 0; }
    Vec3 center(int s) const;  // world position of the span's surface at the cell centre
    int cell_x(int cell) const { return cell % p_.nx; }
    int cell_z(int cell) const { return cell / p_.nx; }
    int cell_at(float x, float z) const;  // -1 outside the grid
    bool inside(Vec3 p) const;            // within the baked bounds

    // `staticOnly`: baked spans only, whether or not something blocks them now (how off-mesh links find their ends).
    // The usable span under/at `p` in its own cell: the highest surface in [p.y - reachDown, p.y + reachUp]. -1 if none.
    int find_span(Vec3 p, float reachDown, float reachUp, bool staticOnly = false) const;
    // The nearest usable span (horizontal distance, then lowest index) within `maxDist` whose surface is in the same
    // vertical window. -1 if none.
    int nearest_span(Vec3 p, float reachDown, float reachUp, float maxDist, float* dist = nullptr, bool staticOnly = false) const;
    // The nearest usable span anywhere (3D distance); -1 if the grid has none.
    int nearest_anywhere(Vec3 p, float* dist = nullptr) const;

    // A* from `start` to `goal` over usable spans. Returns the span chain (start..goal) when reached; otherwise an empty
    // chain, and `closest` = the reached span nearest to the goal.
    // `viaLink` (optional) gets, for every span of the chain, the id of the off-mesh link used to arrive there (-1 = a
    // normal step; the first span has -1).
    std::vector<int> search(int start, int goal, int* closest = nullptr, std::vector<int>* viaLink = nullptr) const;
    // String pulling: keeps the spans that are corners of a straight walk over usable cells. A link is never cut: the
    // chain is pulled on each side of it. `cornerLink` (optional) gets, for every corner, the link id it was reached by.
    std::vector<int> pull(const std::vector<int>& chain, const std::vector<int>* viaLink = nullptr,
                          std::vector<int>* cornerLink = nullptr) const;
    bool line_clear(int a, int b) const;

    // Moving obstacles: blocks the spans their footprint (plus the agent radius) covers. Replaces the previous
    // footprint of the same key, touching only the spans involved.
    void set_obstacle(std::uint64_t key, const std::vector<Footprint>& footprint);
    void clear_obstacle(std::uint64_t key);
    std::size_t obstacle_count() const { return obstacles_.size(); }

    // Off-mesh links (static spans only). Replaces the list and recomputes the walkable areas.
    void set_links(std::vector<LinkEdge> edges);
    std::size_t link_count() const { return links_edges_.size(); }

    // Walkable moving bodies (Collider3D.navWalkable): the top surfaces of one body as dynamic spans, and the static
    // spans it covers blocked. Replaces the previous state of the same key, touching only the cells whose spans changed;
    // `refresh` then redoes the erosion around them (call it once after a batch).
    void set_walkable(std::uint64_t key, const std::vector<NavEntry>& solids);
    void clear_walkable(std::uint64_t key);
    void refresh();
    std::size_t walkable_body_count() const { return walk_.size(); }
    int dynamic_count() const { return dynLive_; }

private:
    NavParams p_;
    std::vector<std::int32_t> cellFirst_;  // spans of cell c: [cellFirst_[c], cellFirst_[c + 1])
    std::vector<Span> spans_;
    std::vector<std::int32_t> links_;      // 8 per span: neighbour span or -1
    int walkable_ = 0, regions_ = 0;
    struct Ref {
        std::int32_t span = 0, gen = 0;
    };
    std::map<std::uint64_t, std::vector<Ref>> obstacles_;  // key -> spans it blocks
    struct DynSpec {
        std::int32_t cell = 0;
        float y = 0.0f, ceil = 1e30f;
        std::int32_t span = -1;  // the dynamic span holding it
    };
    struct Walk {
        std::vector<DynSpec> specs;          // sorted by (cell, y)
        std::vector<std::int32_t> blocked;   // static spans under or in it, sorted
    };
    std::map<std::uint64_t, Walk> walk_;
    std::vector<Span> dyn_;                   // dynamic spans: id = spans_.size() + index
    std::vector<std::int32_t> dynFree_;       // free slots (lowest used first)
    std::vector<std::int32_t> dynHead_;       // per cell: first dynamic span (lazily allocated)
    std::vector<std::int32_t> dirty_;         // cells whose spans changed since the last refresh
    int dynLive_ = 0;
    std::vector<LinkEdge> links_edges_;       // sorted by `from`
    std::vector<std::int32_t> linkFirst_;     // per static span: first edge in links_edges_ (size spans + 1)
    mutable std::vector<std::int32_t> parentLink_;
    std::vector<float> edist_;                // erosion scratch (by span), valid where edistStamp_ == edistNow_
    std::vector<std::int32_t> edistStamp_;
    std::int32_t edistNow_ = 0;
    std::vector<std::uint8_t> cellMark_;      // erosion scratch (by cell)
    // Search scratch (a query is single-threaded), reset by a stamp instead of clearing.
    mutable std::vector<float> g_;
    mutable std::vector<std::int32_t> parent_, stamp_, closed_;
    mutable std::int32_t stampNow_ = 0;

    Span& sp(int s) { return std::size_t(s) < spans_.size() ? spans_[std::size_t(s)] : dyn_[std::size_t(s) - spans_.size()]; }
    const Span& sp(int s) const {
        return std::size_t(s) < spans_.size() ? spans_[std::size_t(s)] : dyn_[std::size_t(s) - spans_.size()];
    }
    template <class F>
    void each_in_cell(int c, F&& f) const;  // static spans of the cell, then dynamic ones
    int link(int s, int dir) const { return links_[std::size_t(s) * 8 + std::size_t(dir)]; }
    // The spans `s` can step to in direction `dir` (not yet checked for `usable`): the baked link and/or dynamic ones.
    int neighbours(int s, int dir, int out[2]) const;
    int pick_in_cell(int s, int c, bool dynOnly, bool staticOnly) const;
    float edge_distance(int s) const;
    int alloc_dyn();
    void free_dyn(int id);
    void erode_around(const std::vector<std::int32_t>& cells);
    void scratch_resize();
    int pick_neighbour(int s, int nx, int nz) const;
    void make_links();
    void erode();
    void make_regions();
    float quantize(float y) const;
};

}  // namespace fa::detail
