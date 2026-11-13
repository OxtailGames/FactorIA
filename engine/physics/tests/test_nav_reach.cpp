// NavGrid::search answers "unreachable" from reachability labels before running A*: the answers are the bits A* gives.
#include <doctest.h>

#include <cstdint>
#include <vector>

#include "../src/nav_grid.h"
#include "fa/core/math.h"

using namespace fa;
using detail::NavEntry;
using detail::NavGrid;
using detail::NavParams;

namespace {

// A flat grid (cell 0.5 m, top y = 0) with walls where `wall[cell]` is set (solid, no walkable top).
void build_flat_grid(NavGrid& g, int nx, int nz, const std::vector<char>& wall) {
    NavParams p;
    p.origin = {0, -1, 0};
    p.nx = nx;
    p.nz = nz;
    p.cell = 0.5f;
    p.radius = 0.25f;
    p.yMin = -1;
    p.yMax = 5;
    std::vector<NavEntry> entries;
    for (int c = 0; c < nx * nz; ++c) {
        NavEntry e;
        e.cell = c;
        e.solid = wall[std::size_t(c)] ? detail::NavSolid{-1.0f, 3.0f, 0.0f} : detail::NavSolid{-1.0f, 0.0f, 1.0f};
        entries.push_back(e);
    }
    g.build(p, entries);
}

int span_at(const NavGrid& g, int ix, int iz) {
    return g.find_span({(float(ix) + 0.5f) * 0.5f, 0.0f, (float(iz) + 0.5f) * 0.5f}, 0.5f, 0.5f);
}

struct Answer {
    std::vector<int> chain, via;
    int closest = -2;
    bool operator==(const Answer& o) const { return chain == o.chain && via == o.via && closest == o.closest; }
};

Answer ask(const NavGrid& g, int a, int b, bool wantClosest = true) {
    Answer r;
    r.chain = g.search(a, b, wantClosest ? &r.closest : nullptr, &r.via);
    return r;
}

// Both paths (labels off, labels on) must give the same bits.
bool same_both_ways(NavGrid& g, int a, int b, bool wantClosest = true) {
    g.set_reach_shortcut(false);
    const Answer old = ask(g, a, b, wantClosest);
    g.set_reach_shortcut(true);
    return old == ask(g, a, b, wantClosest);
}

}  // namespace

TEST_CASE("nav grid: a separate island is unreachable at once, with the closest span of A*") {
    const int nx = 12, nz = 8;
    std::vector<char> wall(std::size_t(nx * nz), 0);
    for (int z = 0; z < nz; ++z) wall[std::size_t(z * nx + 6)] = 1;  // a wall splits the floor in two
    NavGrid g;
    build_flat_grid(g, nx, nz, wall);
    CHECK(g.region_count() == 2);
    const int a = span_at(g, 1, 3), b = span_at(g, 10, 4);
    REQUIRE(a >= 0);
    REQUIRE(b >= 0);
    CHECK(g.reach_valid());
    CHECK(ask(g, a, b).chain.empty());
    CHECK(same_both_ways(g, a, b));
    CHECK(same_both_ways(g, a, b, false));
    CHECK(same_both_ways(g, b, a));
    CHECK(same_both_ways(g, a, span_at(g, 2, 3)));  // same island: found, as always
    CHECK_FALSE(ask(g, a, span_at(g, 2, 3)).chain.empty());
}

TEST_CASE("nav grid: a one-way link is a path one way and a failed search the other, labels or not") {
    const int nx = 12, nz = 6;
    std::vector<char> wall(std::size_t(nx * nz), 0);
    for (int z = 0; z < nz; ++z) wall[std::size_t(z * nx + 6)] = 1;
    NavGrid g;
    build_flat_grid(g, nx, nz, wall);
    const int a = span_at(g, 1, 2), b = span_at(g, 10, 3);
    g.set_links({{0, a, b, 0.0f}});
    g.refresh();
    CHECK(g.region_count() == 1);  // the region labels count the link both ways
    CHECK_FALSE(ask(g, a, b).chain.empty());
    CHECK(ask(g, b, a).chain.empty());
    CHECK(same_both_ways(g, a, b));
    CHECK(same_both_ways(g, b, a));  // the same component: A* runs and says the same
}

TEST_CASE("nav grid: an obstacle that closes a passage and reopens it keeps every answer the same") {
    const int nx = 14, nz = 8;
    std::vector<char> wall(std::size_t(nx * nz), 0);
    for (int z = 0; z < nz; ++z)
        if (z != 4) wall[std::size_t(z * nx + 7)] = 1;  // one gap, at z = 4
    NavGrid g;
    build_flat_grid(g, nx, nz, wall);
    const int a = span_at(g, 1, 1), b = span_at(g, 12, 6);
    CHECK_FALSE(ask(g, a, b).chain.empty());
    NavGrid::Footprint door;
    door.cell = 4 * nx + 7;
    door.bottom = 0.0f;
    door.top = 1.8f;
    g.set_obstacle(1, {door});
    g.refresh();
    CHECK_FALSE(g.reach_valid());  // stale until a search fails
    CHECK(ask(g, a, b).chain.empty());
    g.refresh();
    CHECK(g.reach_valid());  // that failure asked for the labels
    CHECK(same_both_ways(g, a, b));
    CHECK(same_both_ways(g, a, b, false));
    g.clear_obstacle(1);
    g.refresh();
    CHECK_FALSE(g.reach_valid());
    CHECK_FALSE(ask(g, a, b).chain.empty());  // reopened: found (stale labels never say "unreachable")
    CHECK(same_both_ways(g, a, b));
    // A plank over the wall next to a closed door: a walkable body joins the two halves.
    g.set_obstacle(1, {door});
    g.set_walkable(7, {{3 * nx + 7, {-0.2f, 0.0f, 1.0f}}});
    g.refresh();
    CHECK(same_both_ways(g, a, b));
    g.clear_walkable(7);
    g.refresh();
    CHECK(same_both_ways(g, a, b));
}

TEST_CASE("nav grid: random grids give the same answers with and without the labels") {
    Rng rng(94005);
    int shortcut = 0, queries = 0;
    for (int round = 0; round < 6; ++round) {
        const int nx = 20 + int(rng.next_u32() % 8), nz = 18 + int(rng.next_u32() % 8);
        std::vector<char> wall(std::size_t(nx * nz), 0);
        for (auto& w : wall) w = (rng.next_u32() % 100) < 38 ? char(1) : char(0);
        NavGrid g;
        build_flat_grid(g, nx, nz, wall);
        std::vector<int> floor;  // baked spans
        for (int s = 0; s < g.static_count(); ++s)
            if (!g.span(s).erodedBase) floor.push_back(s);
        if (floor.size() < 4) continue;
        auto pick = [&] { return floor[rng.next_u32() % floor.size()]; };
        std::vector<NavGrid::LinkEdge> edges;
        for (int i = 0; i < 3; ++i) edges.push_back({i, pick(), pick(), 0.0f});
        g.set_links(edges);  // one-way: nothing adds the way back
        for (int step = 0; step < 60; ++step) {
            const std::uint32_t what = rng.next_u32() % 5;
            const std::uint64_t key = rng.next_u32() % 4;
            const int c = int(rng.next_u32() % std::uint32_t(nx * nz));
            if (what == 0) {
                g.set_obstacle(key, {{c, 0.0f, 1.8f}, {(c + 1) % (nx * nz), 0.0f, 1.8f}});
            } else if (what == 1) {
                g.clear_obstacle(key);
            } else if (what == 2) {
                g.set_walkable(10 + key, {{c, {-0.2f, 0.0f, 1.0f}}, {(c + 1) % (nx * nz), {-0.2f, 0.0f, 1.0f}}});
            } else if (what == 3) {
                g.clear_walkable(10 + key);
            }
            g.refresh();
            for (int q = 0; q < 6; ++q) {
                const int a = pick();
                int b = pick();
                if (rng.next_u32() % 4 == 0 && g.total_count() > g.static_count())
                    b = g.static_count() + int(rng.next_u32() % std::uint32_t(g.total_count() - g.static_count()));
                const bool wantClosest = rng.next_u32() % 3 != 0;
                if (g.reach_valid()) ++shortcut;
                ++queries;
                if (!same_both_ways(g, a, b, wantClosest)) {
                    FAIL_CHECK("round " << round << " step " << step << " query " << a << " -> " << b);
                    return;
                }
            }
        }
    }
    CHECK(queries > 1000);
    CHECK(shortcut > queries / 10);  // the labels were in use for a good part of the queries
}
