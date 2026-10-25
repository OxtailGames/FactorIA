// Tile pathfinding (docs/NAVIGATION.md, "Tile paths"): A* over the cells of a Tilemap or of a cost grid.
// The same pattern as NavGrid::search: a priority queue with the total order (f, h, cell index), arrays stamped with the
// query number instead of cleared, and `closest`. No clock and no randomness: one query gives one path on every run.
#include <algorithm>
#include <cmath>
#include <cstdint>
#include <format>
#include <limits>
#include <queue>

#include "fa/core/strings.h"
#include "fa/physics/nav.h"
#include "fa/scene/tilemap.h"

namespace fa {

namespace {

constexpr float kSqrt2 = 1.41421356f;

// Search state that survives between queries (a script asks every few frames on the same map): stamps say which entries
// belong to the current query, so nothing is cleared.
struct Scratch {
    std::vector<float> g;
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

NavTilePath nav_find_tile_path(const NavTileGrid& grid, int fromCol, int fromRow, int toCol, int toRow,
                               const NavTileOptions& o) {
    const int W = grid.width, H = grid.height;
    const std::size_t total = std::size_t(std::max(W, 0)) * std::size_t(std::max(H, 0));
    auto inside = [&](int c, int r) { return c >= 0 && r >= 0 && c < W && r < H; };
    if (W <= 0 || H <= 0 || grid.cost.size() < total)
        return fail("start_off_map", "the grid is empty", "Pass a Tilemap with tiles, or a grid {width, height, cost} with width * height costs.");
    if (!inside(fromCol, fromRow))
        return fail("start_off_map", std::format("the start cell ({}, {}) is outside the {} x {} map", fromCol, fromRow, W, H),
                    "Cells are 0-based (col, row) with row 0 at the top.");
    if (!inside(toCol, toRow))
        return fail("goal_off_map", std::format("the goal cell ({}, {}) is outside the {} x {} map", toCol, toRow, W, H),
                    "Cells are 0-based (col, row) with row 0 at the top.");
    auto idx = [&](int c, int r) { return std::int32_t(std::size_t(r) * std::size_t(W) + std::size_t(c)); };
    auto blocked = [&](std::int32_t i) { return !(grid.cost[std::size_t(i)] >= 0.0f); };  // also NaN
    const std::int32_t start = idx(fromCol, fromRow), goal = idx(toCol, toRow);
    if (blocked(goal) && !o.allowBlockedGoal && !o.closest)
        return fail("goal_blocked", std::format("the goal cell ({}, {}) is blocked", toCol, toRow),
                    "Aim at an open cell, pass closest: true to get the nearest reachable one, or allowBlockedGoal: true to end ON a blocked cell.");

    // The cheapest cell bounds how cheap a step can be, so the heuristic never overestimates.
    float minCost = std::numeric_limits<float>::infinity();
    for (std::size_t i = 0; i < total; ++i)
        if (grid.cost[i] >= 0.0f) minCost = std::min(minCost, grid.cost[i]);
    if (!std::isfinite(minCost)) minCost = 0.0f;
    if (o.allowBlockedGoal) minCost = std::min(minCost, 1.0f);
    auto heuristic = [&](int c, int r) {
        const float dx = float(std::abs(c - toCol)), dy = float(std::abs(r - toRow));
        const float steps = o.diagonals ? (dx + dy) + (kSqrt2 - 2.0f) * std::min(dx, dy) : dx + dy;
        return steps * minCost;
    };

    struct Item {
        float f, h, g;
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
    sc.g[std::size_t(start)] = 0.0f;
    sc.parent[std::size_t(start)] = -1;
    sc.seen[std::size_t(start)] = sc.now;
    const float h0 = heuristic(fromCol, fromRow);
    open.push({h0, h0, 0.0f, start});
    std::int32_t nearest = start;
    float nearestH = h0;
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
        if (it.h < nearestH - 1e-6f) {
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
            const float ng = it.g + enter * (k >= 4 ? kSqrt2 : 1.0f);
            const std::size_t ni = std::size_t(n);
            if (sc.seen[ni] == sc.now && ng >= sc.g[ni]) continue;
            sc.seen[ni] = sc.now;
            sc.g[ni] = ng;
            sc.parent[ni] = it.idx;
            const float h = heuristic(nc, nr);
            open.push({ng + h, h, ng, n});
        }
    }

    NavTilePath out;
    std::int32_t end = goal;
    if (!reached) {
        if (!o.closest) {
            if (tooFar)
                return fail("too_far", std::format("gave up after {} cells without reaching ({}, {})", o.maxNodes, toCol, toRow),
                            "Raise maxNodes, search from nearer, or pass closest: true to walk toward the goal anyway.");
            return fail("blocked", std::format("no route from ({}, {}) to ({}, {}): walls or blocked cells close every way",
                                               fromCol, fromRow, toCol, toRow),
                        "Open a way, give the blocked tiles a cost in `costs` instead of Infinity, or pass closest: true.");
        }
        end = nearest;
        out.complete = false;
    }
    out.found = true;
    for (std::int32_t i = end; i >= 0; i = sc.parent[std::size_t(i)]) out.cells.push_back({int(i % W), int(i / W)});
    std::reverse(out.cells.begin(), out.cells.end());
    out.cost = sc.g[std::size_t(end)];
    for (std::size_t i = 1; i < out.cells.size(); ++i) {
        const float dx = float(out.cells[i].first - out.cells[i - 1].first) * grid.cellSize.x;
        const float dy = float(out.cells[i].second - out.cells[i - 1].second) * grid.cellSize.y;
        out.length += std::sqrt(dx * dx + dy * dy);
    }
    return out;
}

NavTileGrid nav_tile_grid_from_tilemap(const Tilemap& tm, const Json& costs) {
    NavTileGrid g;
    const TilemapSize size = tilemap_size(tm);
    if (size.empty()) return g;
    g.width = size.width;
    g.height = size.height;
    g.cellSize = tm.tileSize;
    g.cost.assign(std::size_t(g.width) * std::size_t(g.height), 1.0f);
    std::vector<int> solid;
    if (tm.solidTiles.is_array())
        for (const Json& j : tm.solidTiles)
            if (j.is_number()) solid.push_back(tile_index(int(j.get<double>())));
    // Per tile index: the override (a cost, or -1 for blocked) in a small sorted table.
    std::vector<std::pair<int, float>> over;
    if (costs.is_object())
        for (auto it = costs.begin(); it != costs.end(); ++it) {
            int key = 0;
            try {
                key = std::stoi(it.key());
            } catch (...) {
                continue;
            }
            const float v = it.value().is_number() ? it.value().get<float>() : -1.0f;
            over.push_back({key, v < 0.0f || std::isnan(v) ? -1.0f : v});
        }
    std::sort(over.begin(), over.end());
    for (int r = 0; r < g.height; ++r)
        for (int c = 0; c < g.width; ++c) {
            const int idx = tile_index(tilemap_tile_at(tm, size, c, r));
            float cost = std::find(solid.begin(), solid.end(), idx) != solid.end() ? -1.0f : 1.0f;
            auto o = std::lower_bound(over.begin(), over.end(), std::make_pair(idx, -std::numeric_limits<float>::infinity()));
            if (o != over.end() && o->first == idx) cost = o->second;
            g.cost[std::size_t(r) * std::size_t(g.width) + std::size_t(c)] = cost;
        }
    return g;
}

namespace {

Result<std::pair<int, int>> cell_arg(const Json& a, const char* key) {
    const Json v = a.value(key, Json());
    if (!v.is_array() || v.size() != 2 || !v[0].is_number() || !v[1].is_number())
        return Error{std::format("nav.findTilePath: '{}' must be a cell [col, row] of two numbers, but got {}.", key, v.dump()),
                     std::string("Cells are 0-based with row 0 at the top, e.g. \"") + key + "\":[3,2]."};
    return std::make_pair(int(std::floor(v[0].get<double>())), int(std::floor(v[1].get<double>())));
}

}  // namespace

Result<Json> nav_tile_query(World& world, const Json& args) {
    const bool hasMap = args.contains("tilemap") && !args["tilemap"].is_null();
    const bool hasGrid = args.contains("grid") && !args["grid"].is_null();
    if (hasMap == hasGrid)
        return Error{"nav.findTilePath: pass exactly one of `tilemap` (an entity with a Tilemap) or `grid` ({width, height, cost}).",
                     "Example: {\"tilemap\":\"ground\",\"from\":[0,0],\"to\":[5,3]} or {\"grid\":{\"width\":4,\"height\":3,\"cost\":[1,1,1,1,1,-1,-1,1,1,1,1,1]},\"from\":[0,0],\"to\":[3,2]}."};
    auto from = cell_arg(args, "from");
    if (!from.ok()) return from.error();
    auto to = cell_arg(args, "to");
    if (!to.ok()) return to.error();

    NavTileGrid grid;
    Mat4 toWorld;
    bool worldPoints = false;
    if (hasMap) {
        const std::string id = args["tilemap"].is_string() ? args["tilemap"].get<std::string>() : args["tilemap"].dump();
        const Entity e = world.find_by_id(id);
        if (e.is_null())
            return Error{"nav.findTilePath: no entity '" + id + "'.", "Pass the id of an entity that has a Tilemap component."};
        const Tilemap* tm = world.get<Tilemap>(e);
        if (!tm)
            return Error{"nav.findTilePath: entity '" + id + "' has no Tilemap component.",
                         "Pass a Tilemap entity, or a plain grid {width, height, cost}."};
        grid = nav_tile_grid_from_tilemap(*tm, args.value("costs", Json()));
        if (grid.width <= 0 || grid.height <= 0)
            return Error{"nav.findTilePath: the Tilemap on '" + id + "' has no tiles.", "Fill Tilemap.tiles (and width/height for a flat list)."};
        toWorld = world.world_matrix(e);
        worldPoints = true;
    } else {
        const Json& gj = args["grid"];
        const int w = gj.is_object() && gj.value("width", Json()).is_number() ? int(gj["width"].get<double>()) : 0;
        const int h = gj.is_object() && gj.value("height", Json()).is_number() ? int(gj["height"].get<double>()) : 0;
        const Json cost = gj.is_object() ? gj.value("cost", Json()) : Json();
        if (w <= 0 || h <= 0 || !cost.is_array() || cost.size() != std::size_t(w) * std::size_t(h))
            return Error{std::format("nav.findTilePath: `grid` needs width > 0, height > 0 and a `cost` array of width * height numbers (got {}).",
                                     cost.is_array() ? std::format("{} entries for {} x {}", cost.size(), w, h) : std::string("no cost array")),
                         "cost is row-major with row 0 at the top; a number >= 0 is the cost of entering the cell, null or a negative number blocks it."};
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
            if (v.is_array() && v.size() == 2 && v[0].is_number() && v[1].is_number()) return Vec2{v[0].get<float>(), v[1].get<float>()};
            return def;
        };
        grid.origin = vec2("origin", {0, 0});
        grid.cellSize = vec2("cellSize", {1, 1});
    }

    NavTileOptions o;
    o.diagonals = args.value("diagonals", false);
    o.closest = args.value("closest", false);
    o.allowBlockedGoal = args.value("allowBlockedGoal", false);
    o.maxNodes = std::max(1, args.value("maxNodes", o.maxNodes));
    const NavTilePath p = nav_find_tile_path(grid, from.value().first, from.value().second, to.value().first, to.value().second, o);

    Json out = Json::object();
    out["found"] = p.found;
    out["complete"] = p.found && p.complete;
    Json cells = Json::array(), points = Json::array();
    for (const auto& c : p.cells) {
        cells.push_back(Json::array({c.first, c.second}));
        const float lx = grid.origin.x + (float(c.first) + 0.5f) * grid.cellSize.x;
        const float ly = grid.origin.y - (float(c.second) + 0.5f) * grid.cellSize.y;
        if (worldPoints) {
            const Vec3 w = toWorld.transform_point({lx, ly, 0.0f});
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

}  // namespace fa
