// M75-P5a: the level of detail of a Terrain, the CPU half (src/terrain_lod.h; docs/design/ARCHITECTURE_RENDERING.md, "Terrain"). No GPU: these
// run where `ctest -LE gpu` does. The selection is checked by counts per distance and by a watertight test: for many cameras over a rough
// terrain, every vertex on the edge of a selected node lies on the edge of each neighbour it touches (the morph formula is the CPU twin of
// the vertex shader's), so the terrain has no cracks and does not pop where the level changes.
#include <doctest.h>

#include <algorithm>
#include <chrono>
#include <cmath>
#include <cstdint>
#include <cstdio>

#include "terrain_lod.h"

using namespace fa;
using namespace fa::render;

namespace {

std::uint32_t hash2(int x, int y, std::uint32_t seed) {
    std::uint32_t h = std::uint32_t(x) * 374761393u + std::uint32_t(y) * 668265263u + seed * 2246822519u;
    h = (h ^ (h >> 13)) * 1274126177u;
    return h ^ (h >> 16);
}

// Rough, deterministic relief: three octaves of value noise.
std::shared_ptr<TerrainHeights> rough(int n, std::uint32_t seed = 7) {
    auto h = TerrainHeights::flat(n);
    for (int r = 0; r < n; ++r)
        for (int c = 0; c < n; ++c) {
            float v = 0.0f, amp = 0.5f;
            for (int o = 0, cell = 64; o < 3; ++o, cell /= 4, amp *= 0.5f) {
                const int cx = c / cell, cy = r / cell;
                const float fx = float(c % cell) / float(cell), fy = float(r % cell) / float(cell);
                auto at = [&](int x, int y) { return float(hash2(x, y, seed + std::uint32_t(o)) & 0xFFFF) / 65535.0f; };
                const float a = at(cx, cy), b = at(cx + 1, cy), d = at(cx, cy + 1), e = at(cx + 1, cy + 1);
                v += amp * ((a * (1 - fx) + b * fx) * (1 - fy) + (d * (1 - fx) + e * fx) * fy);
            }
            h->data[std::size_t(r) * std::size_t(n) + std::size_t(c)] =
                std::uint16_t(std::clamp(v * 65535.0f, 0.0f, 65535.0f));
        }
    return h;
}

TerrainGrid grid_for(int n, float sizeMetres, float heightScale = 300.0f) {
    Terrain3D t;
    t.size = {sizeMetres, sizeMetres};
    t.heightScale = heightScale;
    return terrain_grid_of(t, n);
}

struct Setup {
    std::shared_ptr<TerrainHeights> h;
    TerrainGrid g;
    TerrainTileBounds bounds;
    TerrainLodRanges ranges;
    Setup(int n, float size, float quality = 1.0f, float heightScale = 300.0f) {
        h = rough(n);
        g = grid_for(n, size, heightScale);
        bounds.build(*h);
        ranges = TerrainLodRanges::make(g, g.levels(), quality);
    }
    TerrainSelection select(Vec3 cam) const {
        TerrainSelection s;
        select_terrain_nodes(g, bounds, ranges, cam, nullptr, s);
        return s;
    }
};

}  // namespace

TEST_CASE("TerrainGrid: the levels of the quadtree and the local coordinates") {
    CHECK(grid_for(33, 100).levels() == 1);
    CHECK(grid_for(65, 100).levels() == 2);
    CHECK(grid_for(1025, 100).levels() == 6);
    CHECK(grid_for(4097, 100).levels() == 8);
    const TerrainGrid g = grid_for(65, 64.0f, 10.0f);  // 1 m cells
    CHECK(g.cellX == doctest::Approx(1.0f));
    CHECK(g.x_of(0) == doctest::Approx(-32.0f));
    CHECK(g.x_of(64) == doctest::Approx(32.0f));
    CHECK(g.y_of(65535.0f) == doctest::Approx(10.0f));
}

TEST_CASE(
    "TerrainTileBounds: the box of every node is the lowest and highest sample under it, and update keeps it so") {
    auto h = rough(129);
    TerrainTileBounds b;
    b.build(*h);
    REQUIRE(b.levels() == 3);
    auto brute = [&](int level, int tx, int ty) {
        const int span = 32 << level;
        std::uint16_t lo = 65535, hi = 0;
        for (int r = ty * span; r <= ty * span + span; ++r)
            for (int c = tx * span; c <= tx * span + span; ++c) {
                lo = std::min(lo, h->at(c, r));
                hi = std::max(hi, h->at(c, r));
            }
        return std::make_pair(lo, hi);
    };
    auto checkAll = [&] {
        for (int l = 0; l < b.levels(); ++l)
            for (int ty = 0; ty < b.tiles_per_side(l); ++ty)
                for (int tx = 0; tx < b.tiles_per_side(l); ++tx) {
                    const auto [lo, hi] = brute(l, tx, ty);
                    CHECK(b.min_raw(l, tx, ty) == lo);
                    CHECK(b.max_raw(l, tx, ty) == hi);
                }
    };
    checkAll();
    // raise one sample on the border of four tiles, lower another in a corner, then a rectangle
    h->set(64, 64, 65535);
    b.update(*h, {64, 64, 64, 64});
    checkAll();
    h->set(0, 0, 0);
    h->set(1, 0, 0);
    b.update(*h, {0, 0, 1, 0});
    checkAll();
    for (int r = 30; r <= 100; ++r)
        for (int c = 33; c <= 128; ++c) h->set(c, r, std::uint16_t((c * 7 + r * 13) & 0xFFFF));
    b.update(*h, {33, 30, 128, 100});
    checkAll();
}

TEST_CASE(
    "select_terrain_nodes: the nodes get coarser with distance, from a full ring of the finest to the root alone") {
    Setup s(1025, 1024.0f);  // 1 m cells, 6 levels, a finest node is 32 m
    REQUIRE(s.g.levels() == 6);
    std::size_t previous = ~std::size_t(0);
    std::size_t counts[6];
    int i = 0;
    for (float d : {0.0f, 100.0f, 250.0f, 500.0f, 900.0f, 4000.0f}) {
        const auto sel = s.select({d, 50.0f, 0.0f});
        counts[i++] = sel.nodes.size();
        CHECK(sel.nodes.size() <= previous);
        previous = sel.nodes.size();
        CHECK(sel.visited >= sel.nodes.size());
    }
    CHECK(counts[0] > 20);
    CHECK(counts[5] == 1);  // far away only the root is drawn
    // the finest level is used near the camera and only there
    const auto near = s.select({0, 50, 0});
    int finest = 0;
    for (const TerrainNode& n : near.nodes) finest += n.level == 0 ? 1 : 0;
    CHECK(finest >= 4);
    // the same camera and a higher lodQuality: more nodes (the terrain coarsens farther away); a lower one: fewer
    Setup better(1025, 1024.0f, 2.0f), worse(1025, 1024.0f, 0.5f);
    CHECK(better.select({0, 50, 0}).nodes.size() > near.nodes.size());
    CHECK(worse.select({0, 50, 0}).nodes.size() < near.nodes.size());
    // the nodes tile the terrain exactly once: their areas add up to the whole
    double area = 0;
    for (const TerrainNode& n : near.nodes) area += double(32 << n.level) * double(32 << n.level);
    CHECK(area == doctest::Approx(1024.0 * 1024.0));
    // the same selection twice is identical (deterministic order)
    const auto again = s.select({0, 50, 0});
    REQUIRE(again.nodes.size() == near.nodes.size());
    for (std::size_t k = 0; k < near.nodes.size(); ++k) {
        CHECK(again.nodes[k].level == near.nodes[k].level);
        CHECK(again.nodes[k].tx == near.nodes[k].tx);
        CHECK(again.nodes[k].ty == near.nodes[k].ty);
    }
}

TEST_CASE("select_terrain_nodes: the frustum test drops a node with everything under it") {
    Setup s(1025, 1024.0f);
    const auto all = s.select({0, 50, 0});
    // keep only the half with x < 0
    auto leftHalf = [](Vec3 lo, Vec3 hi) { return lo.x < 0.0f && hi.x > -600.0f; };
    TerrainSelection half;
    select_terrain_nodes(s.g, s.bounds, s.ranges, {0, 50, 0}, leftHalf, half);
    CHECK(half.nodes.size() < all.nodes.size());
    CHECK(half.nodes.size() > 0);
    for (const TerrainNode& n : half.nodes) {
        Vec3 lo, hi;
        terrain_node_box(s.g, n, lo, hi);
        CHECK(lo.x < 0.0f);
    }
    TerrainSelection none;
    select_terrain_nodes(s.g, s.bounds, s.ranges, {0, 50, 0}, [](Vec3, Vec3) { return false; }, none);
    CHECK(none.nodes.empty());
}

TEST_CASE("terrain_vertex_raw: a vertex is the sample while near, the middle of its coarse edge once far, and in "
          "between a blend") {
    Setup s(129, 128.0f);
    TerrainNode n;  // level 0, the tile at (1, 1): columns 32..64
    n.level = 0;
    n.tx = n.ty = 1;
    const Vec3 far{5000.0f, 0.0f, 5000.0f};
    // even vertices never move
    for (int gx : {0, 2, 10, 32})
        for (int gz : {0, 4, 32}) {
            CHECK(terrain_vertex_raw(*s.h, s.g, s.ranges, n, gx, gz, far) == float(s.h->at(32 + gx, 32 + gz)));
        }
    // an odd vertex far away is the mean of its two coarse neighbours along the row, the column or the diagonal
    const float mx = 0.5f * (float(s.h->at(32 + 4, 32 + 6)) + float(s.h->at(32 + 6, 32 + 6)));
    CHECK(terrain_vertex_raw(*s.h, s.g, s.ranges, n, 5, 6, far) == doctest::Approx(mx));
    const float mz = 0.5f * (float(s.h->at(32 + 6, 32 + 4)) + float(s.h->at(32 + 6, 32 + 6)));
    CHECK(terrain_vertex_raw(*s.h, s.g, s.ranges, n, 6, 5, far) == doctest::Approx(mz));
    const float diag = 0.5f * (float(s.h->at(32 + 4, 32 + 4)) + float(s.h->at(32 + 6, 32 + 6)));
    CHECK(terrain_vertex_raw(*s.h, s.g, s.ranges, n, 5, 5, far) == doctest::Approx(diag));
    // right under the camera it is the sample itself
    const Vec3 here{s.g.x_of(32 + 5), 0.0f, s.g.z_of(32 + 5)};
    CHECK(terrain_vertex_raw(*s.h, s.g, s.ranges, n, 5, 5, here) == float(s.h->at(32 + 5, 32 + 5)));
    // the morph factor rises from 0 at morph_start to 1 at the range, never going back
    float last = -1.0f;
    for (float d = 0; d < s.ranges.range[0] * 1.5f; d += s.ranges.range[0] / 50.0f) {
        const float m = s.ranges.morph(0, d);
        CHECK(m >= last);
        last = m;
        if (d <= s.ranges.morph_start(0)) CHECK(m == 0.0f);
        if (d >= s.ranges.morph_end(0)) CHECK(m == 1.0f);
    }
}

namespace {

// Every vertex on an edge of a selected node must lie on the (piecewise linear) edge of each node it touches. Returns the number of
// vertices compared; fails the test case with the worst gap otherwise.
std::size_t check_watertight(const Setup& s, const TerrainSelection& sel, Vec3 cam, float tolerance) {
    struct Box {
        Vec3 lo, hi;
    };
    std::vector<Box> boxes(sel.nodes.size());
    for (std::size_t i = 0; i < sel.nodes.size(); ++i) terrain_node_box(s.g, sel.nodes[i], boxes[i].lo, boxes[i].hi);
    const float eps = 0.01f;
    std::size_t compared = 0;
    float worst = 0.0f;
    auto pos = [&](const TerrainNode& n, int gx, int gz) {
        return terrain_vertex_position(*s.h, s.g, s.ranges, n, gx, gz, cam);
    };
    for (std::size_t a = 0; a < sel.nodes.size(); ++a)
        for (std::size_t b = 0; b < sel.nodes.size(); ++b) {
            if (a == b) continue;
            const Box &A = boxes[a], &B = boxes[b];
            // do they touch along a segment (share a border, not only a corner)?
            const bool touchX = std::fabs(A.hi.x - B.lo.x) < eps || std::fabs(B.hi.x - A.lo.x) < eps;
            const bool touchZ = std::fabs(A.hi.z - B.lo.z) < eps || std::fabs(B.hi.z - A.lo.z) < eps;
            const bool overlapX = std::min(A.hi.x, B.hi.x) - std::max(A.lo.x, B.lo.x) > eps;
            const bool overlapZ = std::min(A.hi.z, B.hi.z) - std::max(A.lo.z, B.lo.z) > eps;
            if (!((touchX && overlapZ) || (touchZ && overlapX))) continue;
            CHECK(std::abs(int(sel.nodes[a].level) - int(sel.nodes[b].level)) <= 1);
            // the edge of B that A touches, as a polyline of B's vertices
            const bool alongZ = touchX && overlapZ;  // the shared border runs along z (a vertical line x = const)
            const bool bIsRight = alongZ ? std::fabs(A.hi.x - B.lo.x) < eps : std::fabs(A.hi.z - B.lo.z) < eps;
            const int aSide = bIsRight ? 32 : 0,
                      bSide = bIsRight ? 0 : 32;  // the vertex row or column each node has on the border
            for (int k = 0; k <= 32; ++k) {
                const Vec3 p = pos(sel.nodes[a], alongZ ? aSide : k, alongZ ? k : aSide);
                // find the segment of B's border polyline that holds p
                const float t = alongZ ? p.z : p.x;
                float bestY = 0.0f;
                bool found = false;
                for (int j = 0; j < 32 && !found; ++j) {
                    const Vec3 q0 = pos(sel.nodes[b], alongZ ? bSide : j, alongZ ? j : bSide);
                    const Vec3 q1 = pos(sel.nodes[b], alongZ ? bSide : j + 1, alongZ ? j + 1 : bSide);
                    const float t0 = alongZ ? q0.z : q0.x, t1 = alongZ ? q1.z : q1.x;
                    if (t >= t0 - eps && t <= t1 + eps) {
                        const float u = t1 > t0 ? std::clamp((t - t0) / (t1 - t0), 0.0f, 1.0f) : 0.0f;
                        bestY = q0.y + (q1.y - q0.y) * u;
                        found = true;
                    }
                }
                if (!found) continue;  // outside B's span (A is longer than B)
                ++compared;
                worst = std::max(worst, std::fabs(bestY - p.y));
            }
        }
    CHECK(worst <= tolerance);
    return compared;
}

}  // namespace

TEST_CASE("select_terrain_nodes: no cracks where the levels change, for many cameras over a rough terrain") {
    Setup s(1025, 1024.0f, 1.0f, 400.0f);
    std::size_t compared = 0;
    // from the ground to high above, near the border and the middle, by a few quality factors
    const Vec3 cams[] = {{0, 10, 0},      {137, 30, -211},   {-480, 5, 470}, {300, 120, 300},   {-60, 800, 45},
                         {511, 20, -511}, {-333, 60, 17.5f}, {20, 2, 2},     {250, 2000, -400}, {-100, 40, 250}};
    for (const Vec3& cam : cams) {
        const auto sel = s.select(cam);
        REQUIRE(!sel.nodes.empty());
        compared += check_watertight(s, sel, cam, 0.01f);
    }
    CHECK(compared > 1000);
    for (float q : {0.25f, 3.0f}) {
        Setup t(1025, 1024.0f, q, 400.0f);
        for (const Vec3& cam : {Vec3{0, 10, 0}, Vec3{137, 30, -211}, Vec3{-480, 5, 470}}) {
            const auto sel = t.select(cam);
            compared += check_watertight(t, sel, cam, 0.01f);
        }
    }
}

TEST_CASE("select_terrain_nodes: the selection of a 4097 x 4097 terrain stays small and fast") {
    // 16.8 million samples, 8 levels: only the nodes the camera needs are visited.
    auto h = TerrainHeights::flat(4097, 20000);
    TerrainTileBounds bounds;
    const auto t0 = std::chrono::steady_clock::now();
    bounds.build(*h);
    const double buildMs = std::chrono::duration<double, std::milli>(std::chrono::steady_clock::now() - t0).count();
    const TerrainGrid g = grid_for(4097, 8192.0f, 800.0f);  // 2 m cells, a finest node is 64 m
    const TerrainLodRanges ranges = TerrainLodRanges::make(g, g.levels(), 1.0f);
    TerrainSelection sel;
    double bestMs = 1e9;
    for (int run = 0; run < 20; ++run) {
        const auto a = std::chrono::steady_clock::now();
        for (int k = 0; k < 10; ++k)
            select_terrain_nodes(g, bounds, ranges, {float(k) * 37.0f, 60.0f, float(k) * -11.0f}, nullptr, sel);
        bestMs = std::min(
            bestMs, std::chrono::duration<double, std::milli>(std::chrono::steady_clock::now() - a).count() / 10.0);
    }
    std::printf("terrain 4097 x 4097: bounds built in %.1f ms, selection %.4f ms (%zu nodes, %u visited)\n", buildMs,
                bestMs, sel.nodes.size(), sel.visited);
    // A count, not a time: the same on every machine. 8 levels, a ring of the finest nodes around the camera.
    CHECK(sel.nodes.size() > 30);
    CHECK(sel.nodes.size() < 400);
    CHECK(sel.visited < 2000);
    CHECK(bestMs < 50.0);  // a safety net, 1000x the time of a normal machine
}
