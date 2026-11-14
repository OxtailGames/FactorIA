// Navigation benchmark: failed searches on a large grid, answered from the reachability labels or by A* running to
// exhaustion (the same bits either way; engine/physics/tests/test_nav_reach.cpp compares them).
#include <cstdio>
#include <cstdlib>
#include <memory>
#include <vector>

#include "../../../../engine/physics/src/nav_grid.h"
#include "benches.h"
#include "fa/core/math.h"
#include "fa/physics/nav.h"
#include "fa/scene/components.h"
#include "fa/scene/tilemap.h"
#include "fa/scene/world.h"

namespace fa::bench {

namespace {

constexpr int kGrid = 320;    // cells per side: 102400 spans
constexpr int kQueries = 40;  // failed searches per run

// A floor with a walled-in room in the far corner, and queries from the open floor to the inside of the room.
struct NavScene {
    detail::NavGrid grid;
    std::vector<int> starts, goals;
    explicit NavScene(bool shortcut) {
        detail::NavParams p;
        p.origin = {0, -1, 0};
        p.nx = kGrid;
        p.nz = kGrid;
        p.cell = 0.5f;
        p.radius = 0.25f;
        p.yMin = -1;
        p.yMax = 5;
        std::vector<detail::NavEntry> entries;
        entries.reserve(std::size_t(kGrid) * kGrid);
        const int c0 = kGrid - 40, c1 = kGrid - 20;  // a room 20 x 20 cells
        for (int z = 0; z < kGrid; ++z) {
            for (int x = 0; x < kGrid; ++x) {
                const bool ring =
                    (x == c0 || x == c1 || z == c0 || z == c1) && x >= c0 && x <= c1 && z >= c0 && z <= c1;
                detail::NavEntry e;
                e.cell = z * kGrid + x;
                e.solid = ring ? detail::NavSolid{-1.0f, 3.0f, 0.0f} : detail::NavSolid{-1.0f, 0.0f, 1.0f};
                entries.push_back(e);
            }
        }
        grid.build(p, entries);
        grid.set_reach_shortcut(shortcut);
        auto at = [&](int x, int z) {
            return grid.find_span({(float(x) + 0.5f) * 0.5f, 0.0f, (float(z) + 0.5f) * 0.5f}, 0.5f, 0.5f);
        };
        // A query on a cell without a span would index outside the search scratch: stop the bench with a message.
        auto must = [&](int x, int z) {
            const int s = at(x, z);
            if (s < 0) {
                std::fprintf(stderr, "bench nav.unreachable: no span at cell (%d, %d)\n", x, z);
                std::abort();
            }
            return s;
        };
        Rng rng(94);
        for (int i = 0; i < kQueries; ++i) {
            starts.push_back(must(int(rng.next_u32() % 200), int(rng.next_u32() % 200)));
            goals.push_back(must(c0 + 3 + int(rng.next_u32() % 5), c0 + 2 + int(rng.next_u32() % 15)));
        }
    }
    double run() {
        double sum = 0.0;
        for (int i = 0; i < kQueries; ++i) {
            int closest = -1;
            const auto chain = grid.search(starts[std::size_t(i)], goals[std::size_t(i)], &closest, nullptr);
            sum += double(chain.size()) + double(closest);
        }
        return sum;
    }
};

Bench nav_unreachable(bool shortcut) {
    Bench b;
    b.name = shortcut ? "nav.unreachable" : "nav.unreachable_astar";
    b.summary = shortcut ? "NavGrid::search x40 into a walled-in room on a 320 x 320 grid, answered from the labels"
                         : "the same 40 failed searches with A* running to exhaustion (the labels off)";
    b.make = [shortcut] {
        auto scene = std::make_shared<NavScene>(shortcut);
        Prepared p;
        p.items = kQueries;
        p.unit = "searches";
        p.run = [scene] { return scene->run(); };
        return p;
    };
    return b;
}

// A 512 x 512 Tilemap (262144 cells) with a solid wall every 8th row (a gap every 16 columns), and a short tile path asked
// right after each single-tile edit: the cost is keeping the cost grid in step with the edit, since the search itself
// only crosses a few cells.
struct TileNavScene {
    std::unique_ptr<World> world;
    Entity map;
    // A new world before every run: the edits of the last one must not be what this one starts from.
    void reset() {
        world = std::make_unique<World>();
        map = world->create("ground", "ground");
        Tilemap& tm = world->add<Tilemap>(map);
        tm.tileSize = {16, 16};
        tm.solidTiles = Json::array({1});
        constexpr int n = 512;
        std::vector<int> tiles(std::size_t(n) * std::size_t(n), -1);
        for (int r = 7; r < n; r += 8)
            for (int c = 0; c < n; ++c)
                if (c % 16 != 15) tiles[std::size_t(r) * n + std::size_t(c)] = 1;
        set_tilemap_grid(tm, n, n, tiles);
        (void)nav_tile_query(*world, query());  // the cost grid exists before the clock starts
    }
    static Json query() { return Json::parse(R"({"tilemap":"ground","from":[0,0],"to":[10,3]})"); }
    double run() {
        Tilemap& tm = *world->get<Tilemap>(map);
        const Json q = query();
        double sum = 0;
        for (int i = 0; i < kQueries; ++i) {
            const int col = 3 + 16 * (i % 32), row = 15 + 8 * (i / 32);
            const int now = tilemap_tile_at(tm, tilemap_size(tm), col, row);
            set_tilemap_tile(tm, col, row, now == 1 ? -1 : 1);
            auto path = nav_tile_query(*world, q);
            sum += path.ok() ? path.value()["cost"].get<double>() : -1.0;
        }
        return sum + double(tm.tiles.version());
    }
};

Bench nav_tilemap_edit() {
    Bench b;
    b.name = "nav.tilemap_edit";
    b.summary = "set_tilemap_tile + nav.findTilePath x40 on a 512 x 512 Tilemap: the tile cost grid follows each edit";
    b.warnRatio = 2.0;  // a run lasts about a millisecond once the grid is kept: the clock moves it more than the work
    b.failRatio = 5.0;
    b.make = [] {
        auto scene = std::make_shared<TileNavScene>();
        Prepared p;
        p.items = kQueries;
        p.unit = "edits and queries";
        p.prepare = [scene] { scene->reset(); };
        p.run = [scene] { return scene->run(); };
        return p;
    };
    return b;
}

}  // namespace

void add_nav_benches(std::vector<Bench>& out) {
    out.push_back(nav_unreachable(true));
    out.push_back(nav_unreachable(false));
    out.push_back(nav_tilemap_edit());
}

}  // namespace fa::bench
