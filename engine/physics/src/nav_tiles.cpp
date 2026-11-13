// Tile pathfinding (docs/NAVIGATION.md, "Tile paths"): A* over the cells of a Tilemap or of a cost grid.
// The same pattern as NavGrid::search: a priority queue with the total order (f, h, cell index), arrays stamped with the
// query number instead of cleared, and `closest`. No clock and no randomness: one query gives one path on every run.
#include <algorithm>
#include <cmath>
#include <cstdint>
#include <format>
#include <limits>
#include <memory>
#include <mutex>
#include <queue>
#include <span>

#include "fa/core/jobs.h"
#include "fa/core/strings.h"
#include "fa/physics/nav.h"
#include "fa/scene/tilemap.h"

namespace fa {

namespace {

// The search runs in INTEGER fixed point: a cost is a whole number of 2^-20 units, a diagonal step is that number times sqrt(2)
// rounded once. The open list orders by (f, h, cell index) on integers, so two equal-cost routes are told apart by the same
// rule on every compiler and CPU (a float f = g + h would differ where one build fuses the multiply and the add and another
// does not, and the tie would break the other way). The reported cost is the integer sum converted back.
constexpr double kSqrt2 = 1.4142135623730951;
constexpr std::int64_t kOne = std::int64_t(1) << 20;       // fixed-point 1.0
constexpr std::int64_t kMaxStep = std::int64_t(1) << 50;   // the dearest single step (a cost of 2^30)
constexpr std::int64_t kInfinite = std::int64_t(1) << 62;  // sums saturate here, so they never overflow

std::int64_t
fixed_up(double v) {  // a cost as fixed point, rounded to nearest; NaN and negatives are 0, huge values saturate
    if (!(v > 0.0)) return 0;
    if (std::isinf(v))
        return kInfinite;  // an infinite cost is passable at an infinite price (the reported cost is infinity)
    if (v >= double(kMaxStep) / double(kOne)) return kMaxStep;
    return std::int64_t(std::llround(v * double(kOne)));
}
std::int64_t fixed_down(double v) {  // the same rounded DOWN: the heuristic must never exceed the true cost
    if (!(v > 0.0)) return 0;
    if (v >= double(kMaxStep) / double(kOne)) return kMaxStep;
    return std::int64_t(std::floor(v * double(kOne)));
}
std::int64_t diagonal_of(std::int64_t q) {
    return q >= kInfinite ? kInfinite : std::int64_t(std::llround(double(q) * kSqrt2));
}
std::int64_t add_sat(std::int64_t a, std::int64_t b) { return a >= kInfinite - b ? kInfinite : a + b; }
std::int64_t mul_sat(std::int64_t count, std::int64_t step) {
    return count > 0 && step > kInfinite / count ? kInfinite : count * step;
}

// Search state that survives between queries (a script asks every few frames on the same map): stamps say which entries
// belong to the current query, so nothing is cleared.
struct Scratch {
    std::vector<std::int64_t> g;
    std::vector<std::int32_t> parent;
    std::vector<std::uint32_t> seen, closed;
    std::uint32_t now = 0;
    void begin(std::size_t n) {
        if (g.size() < n) {
            g.resize(n);
            parent.resize(n);
            seen.assign(n, 0);
            closed.assign(n, 0);
            now = 0;
        }
        if (++now == 0) {  // wrapped around: start over
            std::fill(seen.begin(), seen.end(), 0);
            std::fill(closed.begin(), closed.end(), 0);
            now = 1;
        }
    }
};

NavTilePath fail(const char* reason, std::string message, std::string hint) {
    NavTilePath p;
    p.found = false;
    p.complete = false;
    p.reason = reason;
    p.message = std::move(message);
    p.hint = std::move(hint);
    return p;
}

}  // namespace

float nav_tile_min_open_cost(const NavTileGrid& grid) {
    float m = std::numeric_limits<float>::infinity();
    for (const float c : grid.cost)
        if (c >= 0.0f) m = std::min(m, c);
    return std::isfinite(m) ? m : 0.0f;
}

NavTilePath nav_find_tile_path(const NavTileGrid& grid, int fromCol, int fromRow, int toCol, int toRow,
                               const NavTileOptions& o) {
    const int W = grid.width, H = grid.height;
    const std::size_t total = std::size_t(std::max(W, 0)) * std::size_t(std::max(H, 0));
    auto inside = [&](int c, int r) { return c >= 0 && r >= 0 && c < W && r < H; };
    if (W <= 0 || H <= 0 || grid.cost.size() < total)
        return fail("start_off_map", "the grid is empty",
                    "Pass a Tilemap with tiles, or a grid {width, height, cost} with width * height costs.");
    if (!inside(fromCol, fromRow))
        return fail("start_off_map",
                    std::format("the start cell ({}, {}) is outside the {} x {} map", fromCol, fromRow, W, H),
                    "Cells are 0-based (col, row) with row 0 at the top.");
    if (!inside(toCol, toRow))
        return fail("goal_off_map",
                    std::format("the goal cell ({}, {}) is outside the {} x {} map", toCol, toRow, W, H),
                    "Cells are 0-based (col, row) with row 0 at the top.");
    auto idx = [&](int c, int r) { return std::int32_t(std::size_t(r) * std::size_t(W) + std::size_t(c)); };
    auto blocked = [&](std::int32_t i) { return !(grid.cost[std::size_t(i)] >= 0.0f); };  // also NaN
    const std::int32_t start = idx(fromCol, fromRow), goal = idx(toCol, toRow);
    if (blocked(goal) && !o.allowBlockedGoal && !o.closest)
        return fail("goal_blocked", std::format("the goal cell ({}, {}) is blocked", toCol, toRow),
                    "Aim at an open cell, pass closest: true to get the nearest reachable one, or allowBlockedGoal: "
                    "true to end ON a blocked cell.");

    // The cheapest cell bounds how cheap a step can be, so the heuristic never overestimates.
    // (A grid kept by a script has it already: a short route must not sweep the whole map.)
    float minCost = grid.minOpenCost;
    if (!(minCost >= 0.0f)) minCost = nav_tile_min_open_cost(grid);
    if (o.allowBlockedGoal) minCost = std::min(minCost, 1.0f);
    const std::int64_t minStep = fixed_down(double(minCost));
    const std::int64_t minDiag =
        std::int64_t(std::floor(double(minStep) * kSqrt2));  // <= the rounded diagonal of any dearer step
    auto heuristic = [&](int c, int r) {
        const std::int64_t dx = std::abs(c - toCol), dy = std::abs(r - toRow);
        if (!o.diagonals) return mul_sat(dx + dy, minStep);  // saturating: a lower bound stays a lower bound
        const std::int64_t diag = std::min(dx, dy);
        return add_sat(mul_sat(dx + dy - 2 * diag, minStep), mul_sat(diag, minDiag));
    };

    struct Item {
        std::int64_t f, h, g;
        std::int32_t idx;
    };
    struct Later {
        bool operator()(const Item& a, const Item& b) const {
            if (a.f != b.f) return a.f > b.f;
            if (a.h != b.h) return a.h > b.h;
            return a.idx > b.idx;
        }
    };
    static thread_local Scratch sc;
    sc.begin(total);
    std::priority_queue<Item, std::vector<Item>, Later> open;
    sc.g[std::size_t(start)] = 0;
    sc.parent[std::size_t(start)] = -1;
    sc.seen[std::size_t(start)] = sc.now;
    const std::int64_t h0 = heuristic(fromCol, fromRow);
    open.push({h0, h0, 0, start});
    std::int32_t nearest = start;
    std::int64_t nearestH = h0;
    bool reached = false, tooFar = false;
    int expanded = 0;
    static const int kDx[8] = {1, -1, 0, 0, 1, 1, -1, -1};
    static const int kDy[8] = {0, 0, 1, -1, 1, -1, 1, -1};
    while (!open.empty()) {
        const Item it = open.top();
        open.pop();
        const std::size_t s = std::size_t(it.idx);
        if (sc.closed[s] == sc.now || it.g > sc.g[s]) continue;
        sc.closed[s] = sc.now;
        if (it.idx == goal) {
            reached = true;
            break;
        }
        if (it.h < nearestH) {
            nearestH = it.h;
            nearest = it.idx;
        }
        if (++expanded > o.maxNodes) {
            tooFar = true;
            break;
        }
        const int cc = int(it.idx % W), cr = int(it.idx / W);
        const int dirs = o.diagonals ? 8 : 4;
        for (int k = 0; k < dirs; ++k) {
            const int nc = cc + kDx[k], nr = cr + kDy[k];
            if (!inside(nc, nr)) continue;
            const std::int32_t n = idx(nc, nr);
            if (sc.closed[std::size_t(n)] == sc.now) continue;
            float enter = grid.cost[std::size_t(n)];
            if (blocked(n)) {
                if (!(n == goal && o.allowBlockedGoal)) continue;
                enter = 1.0f;
            }
            if (k >= 4 && (blocked(idx(nc, cr)) || blocked(idx(cc, nr)))) continue;  // no corner cutting
            const std::int64_t base = fixed_up(double(enter));
            const std::int64_t ng = add_sat(it.g, k >= 4 ? diagonal_of(base) : base);
            const std::size_t ni = std::size_t(n);
            if (sc.seen[ni] == sc.now && ng >= sc.g[ni]) continue;
            sc.seen[ni] = sc.now;
            sc.g[ni] = ng;
            sc.parent[ni] = it.idx;
            const std::int64_t h = heuristic(nc, nr);
            open.push({add_sat(ng, h), h, ng, n});
        }
    }

    NavTilePath out;
    std::int32_t end = goal;
    if (!reached) {
        if (!o.closest) {
            if (tooFar)
                return fail(
                    "too_far",
                    std::format("gave up after {} cells without reaching ({}, {})", o.maxNodes, toCol, toRow),
                    "Raise maxNodes, search from nearer, or pass closest: true to walk toward the goal anyway.");
            return fail("blocked",
                        std::format("no route from ({}, {}) to ({}, {}): walls or blocked cells close every way",
                                    fromCol, fromRow, toCol, toRow),
                        "Open a way, make a blocked tile passable with a cost in `costs`, or pass closest: true.");
        }
        end = nearest;
        out.complete = false;
    }
    out.found = true;
    for (std::int32_t i = end; i >= 0; i = sc.parent[std::size_t(i)]) out.cells.push_back({int(i % W), int(i / W)});
    std::reverse(out.cells.begin(), out.cells.end());
    out.cost = sc.g[std::size_t(end)] >= kInfinite ? std::numeric_limits<float>::infinity()
                                                   : float(double(sc.g[std::size_t(end)]) / double(kOne));
    for (std::size_t i = 1; i < out.cells.size(); ++i) {
        const Vec2 a = nav_tile_cell_center(grid, out.cells[i - 1].first, out.cells[i - 1].second);
        const Vec2 b = nav_tile_cell_center(grid, out.cells[i].first, out.cells[i].second);
        out.length += std::sqrt((b.x - a.x) * (b.x - a.x) + (b.y - a.y) * (b.y - a.y));
    }
    return out;
}

Vec2 nav_tile_cell_center(const NavTileGrid& grid, int col, int row) {
    if (grid.isometric)
        return {grid.origin.x + float(col - row) * grid.cellSize.x * 0.5f,
                grid.origin.y - float(col + row + 1) * grid.cellSize.y * 0.5f};
    return {grid.origin.x + (float(col) + 0.5f) * grid.cellSize.x,
            grid.origin.y - (float(row) + 0.5f) * grid.cellSize.y};
}

float NavTileRules::cost(int tileIndex) const {
    float c = std::find(solid.begin(), solid.end(), tileIndex) != solid.end() ? -1.0f : 1.0f;
    auto o = std::lower_bound(costs.begin(), costs.end(),
                              std::make_pair(tileIndex, -std::numeric_limits<float>::infinity()));
    if (o != costs.end() && o->first == tileIndex) c = o->second;
    return c;
}

NavTileGrid nav_tile_grid_from_tiles(const std::vector<int>& tiles, int width, int height, const NavTileRules& rules) {
    NavTileGrid g;
    g.width = width;
    g.height = height;
    g.cost.resize(tiles.size());
    for (std::size_t i = 0; i < tiles.size(); ++i) g.cost[i] = rules.cost(tile_index(tiles[i]));
    return g;
}

namespace {

// The cost rule of a Tilemap: its solidTiles block, `costs` ({"<tile index>": cost | null}) override.
NavTileRules rules_of_tilemap(const Tilemap& tm, const Json& costs) {
    NavTileRules rules;
    if (tm.solidTiles.is_array())
        for (const Json& j : tm.solidTiles)
            if (j.is_number()) rules.solid.push_back(tile_index(int(j.get<double>())));
    // The overrides: a cost, or -1 for blocked.
    if (costs.is_object())
        for (auto it = costs.begin(); it != costs.end(); ++it) {
            int key = 0;
            try {
                key = std::stoi(it.key());
            } catch (...) {
                continue;
            }
            const float v = it.value().is_number() ? it.value().get<float>() : -1.0f;
            rules.costs.push_back({key, v < 0.0f || std::isnan(v) ? -1.0f : v});
        }
    rules.sort_costs();
    return rules;
}

// Every cell of the grid of `tm`, read from the tiles (cost = rules.cost(tile_index)); `g` keeps its buffer when it fits.
void fill_grid_from_tilemap(const Tilemap& tm, const TilemapSize& size, const NavTileRules& rules, NavTileGrid& g) {
    g.width = size.width;
    g.height = size.height;
    g.cost.resize(std::size_t(size.width) * std::size_t(size.height));
    // A map has few distinct tile indexes: the rule is looked up once per index, not per cell.
    int lastIndex = -2;
    float lastCost = 0.0f;
    std::size_t i = 0;
    for (int r = 0; r < size.height; ++r)
        for (int c = 0; c < size.width; ++c, ++i) {
            const int t = tile_index(tilemap_tile_at(tm, size, c, r));
            if (t != lastIndex) {
                lastIndex = t;
                lastCost = rules.cost(t);
            }
            g.cost[i] = lastCost;
        }
    g.cellSize = {tm.tileSize.x, tilemap_ground_height(tm)};
    g.isometric = tilemap_isometric(tm);
    g.minOpenCost = nav_tile_min_open_cost(g);
}

// The grids kept between asks (see nav_tile_cache_stats in nav.h). Few entries: a linear search under a mutex.
struct TileGridCache {
    struct Entry {
        std::uint64_t arrayId = 0;  // tm.tiles.id(): which array the grid was read from (never reused in the process)
        TilemapStamp stamp;         // the state of that array the grid shows
        NavTileRules rules;
        std::shared_ptr<NavTileGrid> grid;
        std::uint64_t used = 0;
    };
    std::mutex mutex;
    std::vector<Entry> entries;
    std::uint64_t tick = 0;
    NavTileCacheStats stats;
};
constexpr std::size_t kCacheMinCells = 1024;       // smaller maps are cheaper to read than to look up
constexpr std::size_t kCacheMaxCells = 1u << 22;   // cells kept in all (16 MiB of costs)
constexpr std::size_t kCacheMaxEntries = 16;       // grids kept (one per map and rule set)

TileGridCache& tile_cache() {
    static TileGridCache cache;
    return cache;
}

bool same_rules(const NavTileRules& a, const NavTileRules& b) { return a.solid == b.solid && a.costs == b.costs; }

}  // namespace

NavTileGrid nav_tile_grid_from_tilemap(const Tilemap& tm, const Json& costs) {
    NavTileGrid g;
    const TilemapSize size = tilemap_size(tm);
    if (size.empty()) return g;
    fill_grid_from_tilemap(tm, size, rules_of_tilemap(tm, costs), g);
    return g;
}

NavTileCacheStats nav_tile_cache_stats() {
    TileGridCache& c = tile_cache();
    std::lock_guard lock(c.mutex);
    return c.stats;
}

void nav_tile_cache_clear() {
    TileGridCache& c = tile_cache();
    std::lock_guard lock(c.mutex);
    c.entries.clear();
    c.stats = {};
}

namespace {

// The least recently used grids go until the rest fit the entry and cell bounds; the one used last (the one just made or
// refilled) stays.
void evict_to_bounds(TileGridCache& cache) {
    auto total = [&] {
        std::size_t n = 0;
        for (const TileGridCache::Entry& x : cache.entries) n += x.grid->cost.size();
        return n;
    };
    while (cache.entries.size() > 1 && (cache.entries.size() > kCacheMaxEntries || total() > kCacheMaxCells)) {
        std::size_t newest = 0;
        for (std::size_t i = 1; i < cache.entries.size(); ++i)
            if (cache.entries[i].used > cache.entries[newest].used) newest = i;
        std::size_t oldest = newest == 0 ? 1 : 0;
        for (std::size_t i = 0; i < cache.entries.size(); ++i)
            if (i != newest && cache.entries[i].used < cache.entries[oldest].used) oldest = i;
        cache.entries.erase(cache.entries.begin() + std::ptrdiff_t(oldest));
    }
}

// The cost grid of `tm` for `costs`: a kept one brought up to date, or a new one. Never null; empty when the map has no tiles.
std::shared_ptr<const NavTileGrid> tilemap_grid_cached(const Tilemap& tm, const Json& costs) {
    const TilemapSize size = tilemap_size(tm);
    if (size.empty()) return std::make_shared<NavTileGrid>();
    NavTileRules rules = rules_of_tilemap(tm, costs);
    const std::size_t cells = std::size_t(size.width) * std::size_t(size.height);
    if (cells < kCacheMinCells || cells > kCacheMaxCells) {
        auto g = std::make_shared<NavTileGrid>();
        fill_grid_from_tilemap(tm, size, rules, *g);
        return g;
    }
    TileGridCache& cache = tile_cache();
    std::lock_guard lock(cache.mutex);
    const TilemapStamp stamp = tilemap_stamp(tm);
    const Vec2 cellSize{tm.tileSize.x, tilemap_ground_height(tm)};
    const bool iso = tilemap_isometric(tm);
    TileGridCache::Entry* hit = nullptr;
    for (TileGridCache::Entry& e : cache.entries)
        if (e.arrayId == stamp.arrayId && same_rules(e.rules, rules)) {
            hit = &e;
            break;
        }
    if (hit) {
        hit->used = ++cache.tick;
        if (hit->stamp == stamp && hit->grid->cellSize == cellSize && hit->grid->isometric == iso) {
            ++cache.stats.hits;
            return hit->grid;
        }
        // Main-thread callers only: use_count() > 1 says "someone reads it" only if no other thread can copy the pointer now.
        if (hit->grid.use_count() > 1) hit->grid = std::make_shared<NavTileGrid>(*hit->grid);  // an ask is still reading it
        NavTileGrid& g = *hit->grid;
        std::span<const TileEdit> edits;
        if (tilemap_edits_since(tm, hit->stamp, edits) && g.width == size.width && g.height == size.height) {
            for (const TileEdit& ed : edits) {
                if (ed.cell < 0 || std::size_t(ed.cell) >= g.cost.size()) continue;
                const float v = rules.cost(ed.newIndex);
                float& cell = g.cost[std::size_t(ed.cell)];
                if (cell == v) continue;
                // Keep the cheapest open cost current without sweeping, unless the cell that held it got dearer or blocked.
                if (g.minOpenCost >= 0.0f) {
                    if (v >= 0.0f && v < g.minOpenCost)
                        g.minOpenCost = v;
                    else if (cell >= 0.0f && cell <= g.minOpenCost)
                        g.minOpenCost = -1.0f;
                }
                cell = v;
            }
            if (!(g.minOpenCost >= 0.0f)) g.minOpenCost = nav_tile_min_open_cost(g);
            g.cellSize = cellSize;
            g.isometric = iso;
            ++cache.stats.patches;
            cache.stats.patchedCells += edits.size();
        } else {
            fill_grid_from_tilemap(tm, size, rules, g);
            ++cache.stats.fullBuilds;
        }
        hit->stamp = stamp;
        std::shared_ptr<const NavTileGrid> out = hit->grid;
        evict_to_bounds(cache);  // a grid read again from scratch may be a different size than the one it replaced
        return out;
    }
    TileGridCache::Entry e;
    e.arrayId = stamp.arrayId;
    e.stamp = stamp;
    e.rules = std::move(rules);
    e.grid = std::make_shared<NavTileGrid>();
    fill_grid_from_tilemap(tm, size, e.rules, *e.grid);
    e.used = ++cache.tick;
    ++cache.stats.fullBuilds;
    std::shared_ptr<const NavTileGrid> out = e.grid;
    cache.entries.push_back(std::move(e));
    evict_to_bounds(cache);
    return out;
}

}  // namespace

namespace {

Result<std::pair<int, int>> cell_value(const Json& v, const char* who, const std::string& key) {
    if (!v.is_array() || v.size() != 2 || !v[0].is_number() || !v[1].is_number())
        return Error{std::format("{}: '{}' must be a cell [col, row] of two numbers, but got {}.", who, key, v.dump()),
                     "Cells are 0-based with row 0 at the top, e.g. \"" + key + "\":[3,2]."};
    auto whole = [](double d) {
        return int(std::floor(std::clamp(d, -1e9, 1e9)));
    };  // a huge number must not overflow int
    return std::make_pair(whole(v[0].get<double>()), whole(v[1].get<double>()));
}

Result<std::pair<int, int>> cell_arg(const Json& a, const char* key) {
    return cell_value(a.value(key, Json()), "nav.findTilePath", key);
}

}  // namespace

namespace {

// nav_tile_map's work: the grid as a shared pointer, so a Tilemap's kept grid is handed out without a copy.
Result<bool> tile_map_shared(World& world, const Json& args, const char* who, std::shared_ptr<const NavTileGrid>& out,
                             Mat4& toWorld, bool& worldPoints) {
    const bool hasMap = args.contains("tilemap") && !args["tilemap"].is_null();
    const bool hasGrid = args.contains("grid") && !args["grid"].is_null();
    if (hasMap == hasGrid)
        return Error{
            std::string(who) +
                ": pass exactly one of `tilemap` (an entity with a Tilemap) or `grid` ({width, height, cost}).",
            "Example: {\"tilemap\":\"ground\",\"from\":[0,0],\"to\":[5,3]} or "
            "{\"grid\":{\"width\":4,\"height\":3,\"cost\":[1,1,1,1,1,-1,-1,1,1,1,1,1]},\"from\":[0,0],\"to\":[3,2]}."};
    if (hasMap) {
        const std::string id =
            args["tilemap"].is_string() ? args["tilemap"].get<std::string>() : args["tilemap"].dump();
        const Entity e = world.find_by_id(id);
        if (e.is_null())
            return Error{std::string(who) + ": no entity '" + id + "'.",
                         "Pass the id of an entity that has a Tilemap component."};
        const Tilemap* tm = world.get<Tilemap>(e);
        if (!tm)
            return Error{std::string(who) + ": entity '" + id + "' has no Tilemap component.",
                         "Pass a Tilemap entity, or a plain grid {width, height, cost}."};
        out = tilemap_grid_cached(*tm, args.value("costs", Json()));
        if (out->width <= 0 || out->height <= 0)
            return Error{std::string(who) + ": the Tilemap on '" + id + "' has no tiles.",
                         "Fill Tilemap.tiles (and width/height for a flat list)."};
        toWorld = world.world_matrix(e);
        worldPoints = true;
    } else {
        auto built = std::make_shared<NavTileGrid>();
        NavTileGrid& grid = *built;
        const Json& gj = args["grid"];
        const int w = gj.is_object() && gj.value("width", Json()).is_number() ? int(gj["width"].get<double>()) : 0;
        const int h = gj.is_object() && gj.value("height", Json()).is_number() ? int(gj["height"].get<double>()) : 0;
        const Json cost = gj.is_object() ? gj.value("cost", Json()) : Json();
        if (w <= 0 || h <= 0 || !cost.is_array() || cost.size() != std::size_t(w) * std::size_t(h))
            return Error{std::string(who) +
                             ": `grid` needs width > 0, height > 0 and a `cost` array of width * height numbers (got " +
                             (cost.is_array() ? std::format("{} entries for {} x {}", cost.size(), w, h)
                                              : std::string("no cost array")) +
                             ").",
                         "cost is row-major with row 0 at the top; a number >= 0 is the cost of entering the cell, "
                         "null or a negative number blocks it."};
        grid.width = w;
        grid.height = h;
        grid.cost.resize(std::size_t(w) * std::size_t(h));
        for (std::size_t i = 0; i < grid.cost.size(); ++i) {
            const Json& c = cost[i];
            grid.cost[i] = c.is_number() && c.get<double>() >= 0.0 ? c.get<float>() : -1.0f;
        }
        auto vec2 = [&](const char* key, Vec2 def) {
            const Json v = gj.value(key, Json());
            if (v.is_number()) return Vec2{v.get<float>(), v.get<float>()};
            if (v.is_array() && v.size() == 2 && v[0].is_number() && v[1].is_number())
                return Vec2{v[0].get<float>(), v[1].get<float>()};
            return def;
        };
        grid.origin = vec2("origin", {0, 0});
        grid.cellSize = vec2("cellSize", {1, 1});
        grid.minOpenCost = nav_tile_min_open_cost(grid);  // once here, not by every search
        out = std::move(built);
    }
    return true;
}

}  // namespace

Result<bool> nav_tile_map(World& world, const Json& args, const char* who, NavTileGrid& grid, Mat4& toWorld,
                          bool& worldPoints) {
    std::shared_ptr<const NavTileGrid> shared;
    auto r = tile_map_shared(world, args, who, shared, toWorld, worldPoints);
    if (!r.ok()) return r.error();
    grid = *shared;
    return true;
}

Result<Json> nav_tile_query(World& world, const Json& args) {
    std::shared_ptr<const NavTileGrid> grid;
    Mat4 toWorld;
    bool worldPoints = false;
    auto map = tile_map_shared(world, args, "nav.findTilePath", grid, toWorld, worldPoints);
    if (!map.ok()) return map.error();
    auto from = cell_arg(args, "from");
    if (!from.ok()) return from.error();
    auto to = cell_arg(args, "to");
    if (!to.ok()) return to.error();

    return nav_tile_run(*grid, worldPoints ? &toWorld : nullptr, args, from.value(), to.value());
}

namespace {
// diagonals / closest / allowBlockedGoal / maxNodes of a tile query, checked before reading (Json::value throws on a wrong
// type, and a script passes whatever it was given).
Result<NavTileOptions> tile_options(const Json& args) {
    for (const char* key : {"diagonals", "closest", "allowBlockedGoal"})
        if (args.contains(key) && !args[key].is_boolean())
            return Error{
                std::format("nav.findTilePath: `{}` must be true or false, but got {}.", key, args[key].dump()),
                std::format("Pass {}: true, or leave it out (default false).", key)};
    if (args.contains("maxNodes") && !args["maxNodes"].is_number())
        return Error{std::format("nav.findTilePath: `maxNodes` must be a number, but got {}.", args["maxNodes"].dump()),
                     "Pass the most cells the search may expand, e.g. maxNodes: 5000 (default 100000)."};
    NavTileOptions o;
    o.diagonals = args.value("diagonals", false);
    o.closest = args.value("closest", false);
    o.allowBlockedGoal = args.value("allowBlockedGoal", false);
    o.maxNodes = std::max(1, args.value("maxNodes", o.maxNodes));
    return o;
}

Json tile_path_json(const NavTileGrid& grid, const Mat4* toWorld, const NavTilePath& p) {
    Json out = Json::object();
    out["found"] = p.found;
    out["complete"] = p.found && p.complete;
    Json cells = Json::array(), points = Json::array();
    for (const auto& c : p.cells) {
        cells.push_back(Json::array({c.first, c.second}));
        const Vec2 local = nav_tile_cell_center(grid, c.first, c.second);
        const float lx = local.x, ly = local.y;
        if (toWorld) {
            const Vec3 w = toWorld->transform_point({lx, ly, 0.0f});
            points.push_back(Json::array({w.x, w.y}));
        } else {
            points.push_back(Json::array({lx, ly}));
        }
    }
    out["cells"] = std::move(cells);
    out["points"] = std::move(points);
    out["cost"] = p.cost;
    out["length"] = p.length;
    if (!p.found) {
        out["reason"] = p.reason;
        out["message"] = p.message;
        out["hint"] = p.hint;
    }
    return out;
}
}  // namespace

Result<Json> nav_tile_run(const NavTileGrid& grid, const Mat4* toWorld, const Json& args, std::pair<int, int> from,
                          std::pair<int, int> to) {
    auto o = tile_options(args);
    if (!o.ok()) return o.error();
    return tile_path_json(grid, toWorld,
                          nav_find_tile_path(grid, from.first, from.second, to.first, to.second, o.value()));
}

Result<Json> nav_tile_run_many(const NavTileGrid& grid, const Mat4* toWorld, const Json& args,
                               const std::vector<std::pair<std::pair<int, int>, std::pair<int, int>>>& queries) {
    auto o = tile_options(args);
    if (!o.ok()) return o.error();
    if (queries.size() > kNavMaxBatch)
        return Error{
            std::format("nav.findTilePaths: {} queries in one call, the most is {}.", queries.size(), kNavMaxBatch),
            "Split the list into several calls."};
    std::vector<Json> results(queries.size());
    auto run = [&](std::size_t begin, std::size_t end) {
        for (std::size_t i = begin; i < end; ++i) {
            const auto& q = queries[i];
            results[i] = tile_path_json(
                grid, toWorld,
                nav_find_tile_path(grid, q.first.first, q.first.second, q.second.first, q.second.second, o.value()));
        }
    };
    if (queries.size() < kNavBatchMinQueries || !jobs::running() || jobs::inline_mode() || jobs::worker_count() <= 0) {
        run(0, queries.size());
    } else {
        // Each chunk writes only its own slots; the search keeps its working memory per thread (nav_find_tile_path).
        auto done = jobs::parallel_for("nav.find_tile_paths", queries.size(), kNavBatchGrain,
                                       [&](const jobs::Chunk& c) { run(c.begin, c.end); });
        if (!done) return Error{"nav.findTilePaths: " + done.error().message, done.error().hint};
    }
    Json out = Json::array();
    for (Json& r : results) out.push_back(std::move(r));
    return out;
}

Result<Json> nav_tile_query_many(World& world, const Json& args) {
    std::shared_ptr<const NavTileGrid> grid;
    Mat4 toWorld;
    bool worldPoints = false;
    auto map = tile_map_shared(world, args, "nav.findTilePaths", grid, toWorld, worldPoints);
    if (!map.ok()) return map.error();
    if (!args.contains("queries") || !args["queries"].is_array())
        return Error{
            "nav.findTilePaths /queries: pass a list of {from: [col,row], to: [col,row]}.",
            "Example: "
            "{\"tilemap\":\"ground\",\"queries\":[{\"from\":[0,0],\"to\":[5,3]},{\"from\":[1,1],\"to\":[9,2]}]}."};
    const Json& list = args["queries"];
    if (list.size() > kNavMaxBatch)
        return Error{std::format("nav.findTilePaths /queries: {} queries in one call, the most is {}.", list.size(),
                                 kNavMaxBatch),
                     "Split the list into several calls."};
    // Every query is checked before any search runs.
    std::vector<std::pair<std::pair<int, int>, std::pair<int, int>>> pairs;
    pairs.reserve(list.size());
    for (std::size_t i = 0; i < list.size(); ++i) {
        const std::string at = "/queries/" + std::to_string(i);
        const Json& q = list[i];
        if (!q.is_object())
            return Error{std::format("nav.findTilePaths {}: must be an object {{from, to}}, but got {}.", at, q.dump()),
                         "Each query is {\"from\":[col,row],\"to\":[col,row]}."};
        auto from = cell_value(q.value("from", Json()), "nav.findTilePaths", at + "/from");
        if (!from.ok()) return from.error();
        auto to = cell_value(q.value("to", Json()), "nav.findTilePaths", at + "/to");
        if (!to.ok()) return to.error();
        pairs.push_back({from.value(), to.value()});
    }
    return nav_tile_run_many(*grid, worldPoints ? &toWorld : nullptr, args, pairs);
}

Result<Json> nav_flow_query(World& world, const Json& args) {
    const char* who = "nav.flow_field";
    std::shared_ptr<const NavTileGrid> gridPtr;
    Mat4 toWorld;
    bool worldPoints = false;
    auto map = tile_map_shared(world, args, who, gridPtr, toWorld, worldPoints);
    if (!map.ok()) return map.error();
    const NavTileGrid& grid = *gridPtr;
    if (!args.contains("goals") || !args["goals"].is_array() || args["goals"].empty())
        return Error{std::string(who) + ": `goals` must be a non-empty list of cells [[col,row], ...].",
                     "Example: {\"tilemap\":\"ground\",\"goals\":[[3,2],[9,9]],\"from\":[0,0]}."};
    for (const char* key : {"diagonals"})
        if (args.contains(key) && !args[key].is_boolean())
            return Error{std::format("{}: `{}` must be true or false, but got {}.", who, key, args[key].dump()),
                         "Pass true, or leave it out (default false)."};
    auto cg = std::make_shared<NavCostGrid>(grid.width, grid.height, grid.origin, grid.cellSize);
    cg->assign(grid.cost);
    std::vector<std::pair<int, int>> goals;
    for (std::size_t i = 0; i < args["goals"].size(); ++i) {
        auto g = cell_value(args["goals"][i], who, "goals[" + std::to_string(i) + "]");
        if (!g.ok()) return g.error();
        if (!cg->inside(g.value().first, g.value().second))
            return Error{std::format("{}: goal ({}, {}) is outside the {} x {} map.", who, g.value().first,
                                     g.value().second, grid.width, grid.height),
                         "Cells are 0-based (col, row) with row 0 at the top."};
        goals.push_back(g.value());
    }
    NavFlowField field(cg, goals, args.value("diagonals", false));
    Json out = Json::object();
    out["width"] = grid.width;
    out["height"] = grid.height;
    Json dist = Json::array();
    for (int r = 0; r < grid.height; ++r)
        for (int c = 0; c < grid.width; ++c) {
            const float d = field.distance(c, r);
            dist.push_back(std::isfinite(d) ? Json(d) : Json());
        }
    out["distance"] = std::move(dist);
    if (args.contains("from")) {
        auto from = cell_value(args["from"], who, "from");
        if (!from.ok()) return from.error();
        const auto [fc, fr] = from.value();
        const float d = field.distance(fc, fr);
        out["reachable"] = std::isfinite(d);
        out["cost"] = std::isfinite(d) ? Json(d) : Json();
        int nc = 0, nr = 0;
        out["next"] = field.step_toward(fc, fr, nc, nr) ? Json::array({nc, nr}) : Json();
        Json path = Json::array();
        for (const auto& c : field.path_from(fc, fr)) path.push_back(Json::array({c.first, c.second}));
        out["path"] = std::move(path);
    }
    return out;
}

}  // namespace fa
