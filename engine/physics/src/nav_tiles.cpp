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
    // (A grid kept by a script has it already: a short route must not sweep the whole map.)
    float minCost = grid.minOpenCost;
    if (!(minCost >= 0.0f)) minCost = nav_tile_min_open_cost(grid);
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
        const Vec2 a = nav_tile_cell_center(grid, out.cells[i - 1].first, out.cells[i - 1].second);
        const Vec2 b = nav_tile_cell_center(grid, out.cells[i].first, out.cells[i].second);
        out.length += std::sqrt((b.x - a.x) * (b.x - a.x) + (b.y - a.y) * (b.y - a.y));
    }
    return out;
}

Vec2 nav_tile_cell_center(const NavTileGrid& grid, int col, int row) {
    if (grid.isometric)
        return {grid.origin.x + float(col - row) * grid.cellSize.x * 0.5f, grid.origin.y - float(col + row + 1) * grid.cellSize.y * 0.5f};
    return {grid.origin.x + (float(col) + 0.5f) * grid.cellSize.x, grid.origin.y - (float(row) + 0.5f) * grid.cellSize.y};
}

NavTileGrid nav_tile_grid_from_tilemap(const Tilemap& tm, const Json& costs) {
    NavTileGrid g;
    const TilemapSize size = tilemap_size(tm);
    if (size.empty()) return g;
    g.width = size.width;
    g.height = size.height;
    g.cellSize = {tm.tileSize.x, tilemap_ground_height(tm)};
    g.isometric = tilemap_isometric(tm);
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

Result<std::pair<int, int>> cell_value(const Json& v, const char* who, const std::string& key) {
    if (!v.is_array() || v.size() != 2 || !v[0].is_number() || !v[1].is_number())
        return Error{std::format("{}: '{}' must be a cell [col, row] of two numbers, but got {}.", who, key, v.dump()),
                     "Cells are 0-based with row 0 at the top, e.g. \"" + key + "\":[3,2]."};
    return std::make_pair(int(std::floor(v[0].get<double>())), int(std::floor(v[1].get<double>())));
}

Result<std::pair<int, int>> cell_arg(const Json& a, const char* key) { return cell_value(a.value(key, Json()), "nav.findTilePath", key); }

}  // namespace

Result<bool> nav_tile_map(World& world, const Json& args, const char* who, NavTileGrid& grid, Mat4& toWorld, bool& worldPoints) {
    const bool hasMap = args.contains("tilemap") && !args["tilemap"].is_null();
    const bool hasGrid = args.contains("grid") && !args["grid"].is_null();
    if (hasMap == hasGrid)
        return Error{std::string(who) + ": pass exactly one of `tilemap` (an entity with a Tilemap) or `grid` ({width, height, cost}).",
                     "Example: {\"tilemap\":\"ground\",\"from\":[0,0],\"to\":[5,3]} or {\"grid\":{\"width\":4,\"height\":3,\"cost\":[1,1,1,1,1,-1,-1,1,1,1,1,1]},\"from\":[0,0],\"to\":[3,2]}."};
    if (hasMap) {
        const std::string id = args["tilemap"].is_string() ? args["tilemap"].get<std::string>() : args["tilemap"].dump();
        const Entity e = world.find_by_id(id);
        if (e.is_null())
            return Error{std::string(who) + ": no entity '" + id + "'.", "Pass the id of an entity that has a Tilemap component."};
        const Tilemap* tm = world.get<Tilemap>(e);
        if (!tm)
            return Error{std::string(who) + ": entity '" + id + "' has no Tilemap component.",
                         "Pass a Tilemap entity, or a plain grid {width, height, cost}."};
        grid = nav_tile_grid_from_tilemap(*tm, args.value("costs", Json()));
        if (grid.width <= 0 || grid.height <= 0)
            return Error{std::string(who) + ": the Tilemap on '" + id + "' has no tiles.", "Fill Tilemap.tiles (and width/height for a flat list)."};
        toWorld = world.world_matrix(e);
        worldPoints = true;
    } else {
        const Json& gj = args["grid"];
        const int w = gj.is_object() && gj.value("width", Json()).is_number() ? int(gj["width"].get<double>()) : 0;
        const int h = gj.is_object() && gj.value("height", Json()).is_number() ? int(gj["height"].get<double>()) : 0;
        const Json cost = gj.is_object() ? gj.value("cost", Json()) : Json();
        if (w <= 0 || h <= 0 || !cost.is_array() || cost.size() != std::size_t(w) * std::size_t(h))
            return Error{std::string(who) + ": `grid` needs width > 0, height > 0 and a `cost` array of width * height numbers (got " +
                             (cost.is_array() ? std::format("{} entries for {} x {}", cost.size(), w, h) : std::string("no cost array")) + ").",
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
    return true;
}

Result<Json> nav_tile_query(World& world, const Json& args) {
    NavTileGrid grid;
    Mat4 toWorld;
    bool worldPoints = false;
    auto map = nav_tile_map(world, args, "nav.findTilePath", grid, toWorld, worldPoints);
    if (!map.ok()) return map.error();
    auto from = cell_arg(args, "from");
    if (!from.ok()) return from.error();
    auto to = cell_arg(args, "to");
    if (!to.ok()) return to.error();

    return nav_tile_run(grid, worldPoints ? &toWorld : nullptr, args, from.value(), to.value());
}

Result<Json> nav_tile_run(const NavTileGrid& grid, const Mat4* toWorld, const Json& args, std::pair<int, int> from,
                          std::pair<int, int> to) {
    // Checked before reading: Json::value throws on a wrong type, and a script passes whatever it was given.
    for (const char* key : {"diagonals", "closest", "allowBlockedGoal"})
        if (args.contains(key) && !args[key].is_boolean())
            return Error{std::format("nav.findTilePath: `{}` must be true or false, but got {}.", key, args[key].dump()),
                         std::format("Pass {}: true, or leave it out (default false).", key)};
    if (args.contains("maxNodes") && !args["maxNodes"].is_number())
        return Error{std::format("nav.findTilePath: `maxNodes` must be a number, but got {}.", args["maxNodes"].dump()),
                     "Pass the most cells the search may expand, e.g. maxNodes: 5000 (default 100000)."};
    NavTileOptions o;
    o.diagonals = args.value("diagonals", false);
    o.closest = args.value("closest", false);
    o.allowBlockedGoal = args.value("allowBlockedGoal", false);
    o.maxNodes = std::max(1, args.value("maxNodes", o.maxNodes));
    const NavTilePath p = nav_find_tile_path(grid, from.first, from.second, to.first, to.second, o);

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

Result<Json> nav_flow_query(World& world, const Json& args) {
    const char* who = "nav.flow_field";
    NavTileGrid grid;
    Mat4 toWorld;
    bool worldPoints = false;
    auto map = nav_tile_map(world, args, who, grid, toWorld, worldPoints);
    if (!map.ok()) return map.error();
    if (!args.contains("goals") || !args["goals"].is_array() || args["goals"].empty())
        return Error{std::string(who) + ": `goals` must be a non-empty list of cells [[col,row], ...].",
                     "Example: {\"tilemap\":\"ground\",\"goals\":[[3,2],[9,9]],\"from\":[0,0]}."};
    for (const char* key : {"diagonals"})
        if (args.contains(key) && !args[key].is_boolean())
            return Error{std::format("{}: `{}` must be true or false, but got {}.", who, key, args[key].dump()), "Pass true, or leave it out (default false)."};
    auto cg = std::make_shared<NavCostGrid>(grid.width, grid.height, grid.origin, grid.cellSize);
    cg->assign(grid.cost);
    std::vector<std::pair<int, int>> goals;
    for (std::size_t i = 0; i < args["goals"].size(); ++i) {
        auto g = cell_value(args["goals"][i], who, "goals[" + std::to_string(i) + "]");
        if (!g.ok()) return g.error();
        if (!cg->inside(g.value().first, g.value().second))
            return Error{std::format("{}: goal ({}, {}) is outside the {} x {} map.", who, g.value().first, g.value().second, grid.width, grid.height),
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
