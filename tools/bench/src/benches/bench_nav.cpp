// Navigation benchmark: failed searches on a large grid, answered from the reachability labels or by A* running to
// exhaustion (the same bits either way; engine/physics/tests/test_nav_reach.cpp compares them).
#include <memory>
#include <vector>

#include "../../../../engine/physics/src/nav_grid.h"
#include "benches.h"
#include "fa/core/math.h"

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
        Rng rng(94);
        for (int i = 0; i < kQueries; ++i) {
            starts.push_back(at(int(rng.next_u32() % 200), int(rng.next_u32() % 200)));
            goals.push_back(at(c0 + 3 + int(rng.next_u32() % 5), c0 + 2 + int(rng.next_u32() % 15)));
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

}  // namespace

void add_nav_benches(std::vector<Bench>& out) {
    out.push_back(nav_unreachable(true));
    out.push_back(nav_unreachable(false));
}

}  // namespace fa::bench
