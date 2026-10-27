// Tile pathfinding: A* over a Tilemap or a cost grid (nav_find_tile_path, nav_tile_query).
#include <doctest.h>

#include <cmath>
#include <limits>
#include <memory>
#include <tuple>

#include "fa/physics/nav.h"
#include "fa/scene/tilemap.h"

using namespace fa;

namespace {

// Rows of text, '#' blocked, digits a cost, '.' = 1.
NavTileGrid make_grid(std::initializer_list<const char*> rows) {
    NavTileGrid g;
    g.height = int(rows.size());
    for (const char* r : rows) {
        g.width = int(std::string(r).size());
        for (const char* c = r; *c; ++c) g.cost.push_back(*c == '#' ? -1.0f : *c == '.' ? 1.0f : float(*c - '0'));
    }
    return g;
}

bool has_cell(const NavTilePath& p, int c, int r) {
    for (const auto& x : p.cells)
        if (x.first == c && x.second == r) return true;
    return false;
}

}  // namespace

TEST_CASE("nav tiles: a path goes around a wall, 4-way") {
    const NavTileGrid g = make_grid({
        ".....",
        ".###.",
        ".....",
    });
    const NavTilePath p = nav_find_tile_path(g, 2, 0, 2, 2);
    REQUIRE(p.found);
    CHECK(p.complete);
    CHECK(p.cells.front() == std::make_pair(2, 0));
    CHECK(p.cells.back() == std::make_pair(2, 2));
    CHECK(p.cells.size() == 7);  // out to column 0 or 4 and back: 6 steps
    CHECK(p.cost == doctest::Approx(6.0f));
    CHECK_FALSE(has_cell(p, 2, 1));
    for (std::size_t i = 1; i < p.cells.size(); ++i)  // every step is orthogonal
        CHECK(std::abs(p.cells[i].first - p.cells[i - 1].first) + std::abs(p.cells[i].second - p.cells[i - 1].second) == 1);
}

TEST_CASE("nav tiles: diagonals shorten the path and never cut a corner") {
    const NavTileGrid g = make_grid({
        "...",
        ".#.",
        "...",
    });
    NavTileOptions o;
    o.diagonals = true;
    const NavTilePath p = nav_find_tile_path(g, 0, 0, 2, 2, o);
    REQUIRE(p.found);
    CHECK(p.cells.size() == 5);  // the centre is a wall: round the corner, no diagonal through (1,1)
    CHECK(p.cost == doctest::Approx(4.0f));
    // a diagonal between two blocked orthogonal cells is refused: (0,0) -> (1,1) with (1,0) and (0,1) blocked
    const NavTileGrid pinch = make_grid({
        ".#.",
        "#..",
        "...",
    });
    const NavTilePath q = nav_find_tile_path(pinch, 0, 0, 2, 2, o);
    CHECK_FALSE(q.found);
    CHECK(q.reason == "blocked");
    // an open diagonal field: 2 diagonal steps
    const NavTileGrid open = make_grid({"...", "...", "..."});
    const NavTilePath d = nav_find_tile_path(open, 0, 0, 2, 2, o);
    CHECK(d.cells.size() == 3);
    CHECK(d.cost == doctest::Approx(2.0f * 1.41421356f));
    // without diagonals the same query takes 4 steps
    CHECK(nav_find_tile_path(open, 0, 0, 2, 2).cells.size() == 5);
}

TEST_CASE("nav tiles: costs steer the path, a blocked goal and closest") {
    // a cheap detour beats an expensive straight line
    const NavTileGrid g = make_grid({
        ".9.",
        ".9.",
        "...",
    });
    NavTilePath p = nav_find_tile_path(g, 0, 0, 2, 0);
    REQUIRE(p.found);
    CHECK(p.cost == doctest::Approx(6.0f));  // down, down, right, right, up, up
    CHECK(has_cell(p, 1, 2));

    const NavTileGrid walled = make_grid({
        "..#..",
        "..#..",
        "..#.#",
    });
    p = nav_find_tile_path(walled, 0, 0, 4, 0);
    CHECK_FALSE(p.found);
    CHECK(p.reason == "blocked");
    CHECK_FALSE(p.hint.empty());
    NavTileOptions o;
    o.closest = true;
    p = nav_find_tile_path(walled, 0, 0, 4, 0, o);
    REQUIRE(p.found);
    CHECK_FALSE(p.complete);
    CHECK(p.cells.back() == std::make_pair(1, 0));  // the reachable cell nearest the goal
    // a blocked goal
    p = nav_find_tile_path(walled, 0, 0, 2, 0);
    CHECK(p.reason == "goal_blocked");
    NavTileOptions e;
    e.allowBlockedGoal = true;
    p = nav_find_tile_path(walled, 0, 0, 2, 0, e);
    REQUIRE(p.found);
    CHECK(p.complete);
    CHECK(p.cells.back() == std::make_pair(2, 0));
    // off the map and too far
    CHECK(nav_find_tile_path(walled, -1, 0, 1, 0).reason == "start_off_map");
    CHECK(nav_find_tile_path(walled, 0, 0, 9, 0).reason == "goal_off_map");
    NavTileOptions tiny;
    tiny.maxNodes = 2;
    CHECK(nav_find_tile_path(make_grid({"........."}), 0, 0, 8, 0, tiny).reason == "too_far");
}

TEST_CASE("nav tiles: the same query gives the same path twice, and with ties it is stable") {
    const NavTileGrid g = make_grid({
        ".......",
        ".......",
        "..###..",
        ".......",
        ".......",
    });
    NavTileOptions o;
    o.diagonals = true;
    const NavTilePath a = nav_find_tile_path(g, 0, 0, 6, 4, o);
    const NavTilePath b = nav_find_tile_path(g, 0, 0, 6, 4, o);
    REQUIRE(a.found);
    CHECK(a.cells == b.cells);
    // an unrelated query in between (the scratch arrays are reused) changes nothing
    nav_find_tile_path(make_grid({"..."}), 0, 0, 2, 0);
    CHECK(nav_find_tile_path(g, 0, 0, 6, 4, o).cells == a.cells);
}

TEST_CASE("nav tiles: a Tilemap entity, solid tiles, costs and world points") {
    World world;
    Entity map = world.create("ground", "ground");
    world.get<Transform>(map)->position = {100, 50, 0};
    Tilemap& tm = world.add<Tilemap>(map);
    tm.tileSize = {16, 16};
    tm.solidTiles = Json::array({1});
    tm.width = 4;
    tm.height = 3;
    tm.tiles = Json::parse("[0,0,0,0, 0,1,1,0, 0,0,0,0]");

    auto q = [&](const char* json) {
        auto r = nav_tile_query(world, Json::parse(json));
        REQUIRE_MESSAGE(r.ok(), (r.ok() ? "" : r.error().to_string()));
        return r.value();
    };
    Json r = q(R"({"tilemap":"ground","from":[0,1],"to":[3,1]})");
    CHECK(r["found"] == true);
    CHECK(r["cells"].size() == 6);  // round the two solid tiles
    // cell (0,1) centre: x = 100 + 8, y = 50 - 24
    CHECK(r["points"][0][0].get<float>() == doctest::Approx(108.0f));
    CHECK(r["points"][0][1].get<float>() == doctest::Approx(26.0f));
    // opening the solid tiles with costs: straight through
    r = q(R"({"tilemap":"ground","from":[0,1],"to":[3,1],"costs":{"1":1.5}})");
    CHECK(r["cells"].size() == 4);
    CHECK(r["cost"].get<float>() == doctest::Approx(4.0f));
    // costs can block a plain tile too
    r = q(R"({"tilemap":"ground","from":[0,1],"to":[3,1],"costs":{"0":null,"1":null}})");
    CHECK(r["found"] == false);
    // set_tilemap_tile bumps the counter and changes the next search
    const auto v0 = world.get<Tilemap>(map)->version;
    REQUIRE(set_tilemap_tile(*world.get<Tilemap>(map), 1, 0, 1));
    CHECK(world.get<Tilemap>(map)->version == v0 + 1);
    r = q(R"({"tilemap":"ground","from":[0,0],"to":[3,0]})");
    CHECK(r["cells"].size() == 8);  // the new wall at (1,0) forces the way round: down, across, back up
    // errors teach
    auto bad = nav_tile_query(world, Json::parse(R"({"tilemap":"nope","from":[0,0],"to":[1,1]})"));
    REQUIRE_FALSE(bad.ok());
    CHECK(bad.error().message.find("nope") != std::string::npos);
    bad = nav_tile_query(world, Json::parse(R"({"from":[0,0],"to":[1,1]})"));
    CHECK_FALSE(bad.ok());
    bad = nav_tile_query(world, Json::parse(R"({"grid":{"width":2,"height":2,"cost":[1]},"from":[0,0],"to":[1,1]})"));
    REQUIRE_FALSE(bad.ok());
    CHECK(bad.error().message.find("cost") != std::string::npos);
}

TEST_CASE("nav tiles: a path on an isometric Tilemap walks the diamonds and reports world points at their centres") {
    World world;
    Entity map = world.create("iso", "iso");
    world.get<Transform>(map)->position = {1000, 0, 0};
    Tilemap& tm = world.add<Tilemap>(map);
    tm.projection = TilemapProjection::Isometric;
    tm.tileSize = {100, 50};
    tm.solidTiles = Json::array({1});
    tm.width = 4;
    tm.height = 3;
    tm.tiles = Json::parse("[0,0,0,0, 0,1,1,0, 0,0,0,0]");

    auto r = nav_tile_query(world, Json::parse(R"({"tilemap":"iso","from":[0,1],"to":[3,1]})"));
    REQUIRE(r.ok());
    const Json& j = r.value();
    CHECK(j["found"] == true);
    CHECK(j["cells"].size() == 6);  // round the two solid tiles, exactly as the grid logic says
    // Cell (0, 1): centre ((0 - 1) * 50, -(0 + 1 + 1) * 25) = (-50, -50) from the map's top vertex, plus the entity position.
    CHECK(j["points"][0][0].get<float>() == doctest::Approx(950.0f));
    CHECK(j["points"][0][1].get<float>() == doctest::Approx(-50.0f));
    // The last point is cell (3, 1): ((3 - 1) * 50, -(3 + 1 + 1) * 25) = (100, -125).
    const std::size_t n = j["points"].size();
    CHECK(j["points"][n - 1][0].get<float>() == doctest::Approx(1100.0f));
    CHECK(j["points"][n - 1][1].get<float>() == doctest::Approx(-125.0f));
    // A step along a column or a row is a diagonal on screen, sqrt(50^2 + 25^2) long.
    const NavTileGrid grid = nav_tile_grid_from_tilemap(tm, Json::object());
    CHECK(grid.isometric);
    const Vec2 a = nav_tile_cell_center(grid, 0, 0), b = nav_tile_cell_center(grid, 1, 0);
    CHECK(std::sqrt((b.x - a.x) * (b.x - a.x) + (b.y - a.y) * (b.y - a.y)) == doctest::Approx(std::sqrt(50.0f * 50.0f + 25.0f * 25.0f)));
    CHECK(j["length"].get<float>() == doctest::Approx(5.0f * std::sqrt(50.0f * 50.0f + 25.0f * 25.0f)));
}

TEST_CASE("nav tiles: a plain grid with origin and cell size") {
    World world;
    auto r = nav_tile_query(world, Json::parse(
        R"({"grid":{"width":3,"height":1,"cost":[1,null,1],"origin":[10,20],"cellSize":4},"from":[0,0],"to":[2,0],"closest":true})"));
    REQUIRE(r.ok());
    CHECK(r.value()["found"] == true);
    CHECK(r.value()["complete"] == false);
    CHECK(r.value()["points"].size() == 1);
    CHECK(r.value()["points"][0][0].get<float>() == doctest::Approx(12.0f));
    CHECK(r.value()["points"][0][1].get<float>() == doctest::Approx(18.0f));
}

namespace {

// A 24 x 18 map with walls and a few costly cells, made by a fixed generator (no rand()).
NavTileGrid noisy_grid() {
    NavTileGrid g;
    g.width = 24;
    g.height = 18;
    std::uint32_t s = 12345;
    for (int i = 0; i < g.width * g.height; ++i) {
        s = s * 1664525u + 1013904223u;
        const unsigned v = (s >> 16) % 10;
        g.cost.push_back(v < 2 ? -1.0f : v < 4 ? 3.0f : 1.0f);
    }
    g.cost[0] = 1.0f;
    return g;
}

}  // namespace

TEST_CASE("nav grid: a kept grid gives the same paths as the array form, before and after setCost") {
    NavTileGrid plain = noisy_grid();
    NavCostGrid kept(plain.width, plain.height, {0, 0}, {1, 1});
    kept.assign(plain.cost);
    CHECK(kept.version() == 1);
    for (const bool diagonals : {false, true}) {
        NavTileOptions o;
        o.diagonals = diagonals;
        o.closest = true;
        int compared = 0;
        for (int i = 0; i < 60; ++i) {
            const int fc = (i * 7) % plain.width, fr = (i * 5) % plain.height, tc = (i * 11 + 3) % plain.width, tr = (i * 3 + 1) % plain.height;
            const NavTilePath a = nav_find_tile_path(plain, fc, fr, tc, tr, o);
            const NavTilePath b = nav_find_tile_path(kept.grid(), fc, fr, tc, tr, o);
            REQUIRE(a.found == b.found);
            CHECK(a.cells == b.cells);
            CHECK(a.cost == b.cost);
            ++compared;
        }
        CHECK(compared == 60);
        // change cells, including the cheapest one, on both; the kept grid must follow
        for (const auto& [c, r, v] : {std::tuple{3, 3, -1.0f}, std::tuple{4, 3, 0.5f}, std::tuple{4, 3, 2.0f}, std::tuple{5, 6, 1.0f}}) {
            plain.cost[std::size_t(r * plain.width + c)] = v;
            CHECK(kept.set_cost(c, r, v));
        }
        for (int i = 0; i < 30; ++i) {
            const int fc = (i * 3) % plain.width, fr = (i * 5) % plain.height, tc = (i * 13 + 1) % plain.width, tr = (i * 7 + 2) % plain.height;
            const NavTilePath a = nav_find_tile_path(plain, fc, fr, tc, tr, o);
            const NavTilePath b = nav_find_tile_path(kept.grid(), fc, fr, tc, tr, o);
            REQUIRE(a.found == b.found);
            CHECK(a.cells == b.cells);
        }
    }
    CHECK_FALSE(kept.set_cost(24, 0, 1.0f));
    CHECK_FALSE(kept.set_cost(0, -1, 1.0f));
    const std::uint32_t v = kept.version();
    CHECK(kept.set_cost(0, 0, kept.cost(0, 0)));  // the same cost is not a change
    CHECK(kept.version() == v);
    kept.set_cost(0, 0, std::numeric_limits<float>::infinity());  // infinity blocks
    CHECK(kept.cost(0, 0) < 0.0f);
    CHECK(kept.version() == v + 1);
}

TEST_CASE("nav flow: distances equal the A* cost to the nearest goal, and steps reach it") {
    const NavTileGrid plain = noisy_grid();
    auto kept = std::make_shared<NavCostGrid>(plain.width, plain.height, Vec2{0, 0}, Vec2{1, 1});
    kept->assign(plain.cost);
    for (const bool diagonals : {false, true}) {
        const std::vector<std::pair<int, int>> goals = {{20, 15}, {2, 9}};
        NavFlowField field(kept, goals, diagonals);
        NavTileOptions o;
        o.diagonals = diagonals;
        int reachable = 0;
        for (int r = 0; r < plain.height; ++r)
            for (int c = 0; c < plain.width; ++c) {
                if (plain.cost[std::size_t(r * plain.width + c)] < 0.0f) {
                    CHECK(std::isinf(field.distance(c, r)));
                    continue;
                }
                // the nearest goal by the A* cost of each (a start cell is always allowed)
                float best = std::numeric_limits<float>::infinity();
                for (const auto& g : goals) {
                    const NavTilePath p = nav_find_tile_path(plain, g.first, g.second, c, r, o);
                    // A* costs the walk goal -> cell; the field costs cell -> goal. Costs are entering costs, so
                    // compare through the reverse query: cell -> goal.
                    const NavTilePath q = nav_find_tile_path(plain, c, r, g.first, g.second, o);
                    (void)p;
                    if (q.found) best = std::min(best, q.cost);
                }
                const float d = field.distance(c, r);
                if (std::isinf(best)) {
                    CHECK(std::isinf(d));
                    continue;
                }
                ++reachable;
                CHECK(d == doctest::Approx(best).epsilon(1e-4));
                // follow the steps: the cost never goes up, and it ends on a goal
                int cc = c, rr = r, guard = 1000;
                float last = d;
                int nc = 0, nr = 0;
                while (guard-- > 0 && field.step_toward(cc, rr, nc, nr)) {
                    CHECK(field.distance(nc, nr) <= last);
                    last = field.distance(nc, nr);
                    cc = nc;
                    rr = nr;
                }
                CHECK(guard > 0);
                CHECK(field.is_goal(cc, rr));
                const auto path = field.path_from(c, r);
                REQUIRE_FALSE(path.empty());
                CHECK(path.front() == std::make_pair(c, r));
                CHECK(path.back() == std::make_pair(cc, rr));
            }
        CHECK(reachable > 100);
    }
}

TEST_CASE("nav flow: a changed grid rebuilds the field, a blocked goal is entered, unreachable cells have no step") {
    auto kept = std::make_shared<NavCostGrid>(5, 3, Vec2{0, 0}, Vec2{1, 1});
    for (int r = 0; r < 3; ++r) kept->set_cost(2, r, -1.0f);  // a wall across column 2
    NavFlowField field(kept, {{4, 1}}, false);
    CHECK(field.distance(3, 1) == doctest::Approx(1.0f));
    CHECK(std::isinf(field.distance(0, 1)));
    int nc = 0, nr = 0;
    CHECK_FALSE(field.step_toward(0, 1, nc, nr));
    CHECK_FALSE(field.step_toward(4, 1, nc, nr));  // at the goal
    CHECK(field.path_from(0, 1).empty());
    CHECK(field.rebuilds() == 1);
    CHECK(field.distance(3, 1) == doctest::Approx(1.0f));
    CHECK(field.rebuilds() == 1);  // nothing changed: no rebuild
    kept->set_cost(2, 1, 1.0f);    // open a door
    CHECK(field.distance(0, 1) == doctest::Approx(4.0f));
    CHECK(field.rebuilds() == 2);
    REQUIRE(field.step_toward(0, 1, nc, nr));
    CHECK(nc == 1);
    CHECK(nr == 1);
    CHECK(field.path_from(0, 1).size() == 5);
    // ties go east first
    NavFlowField open(std::make_shared<NavCostGrid>(3, 3, Vec2{0, 0}, Vec2{1, 1}), {{2, 2}}, false);
    REQUIRE(open.step_toward(0, 0, nc, nr));
    CHECK(nc == 1);
    CHECK(nr == 0);
    // a blocked goal can be walked into at cost 1
    kept->set_cost(4, 1, -1.0f);
    CHECK(field.distance(3, 1) == doctest::Approx(1.0f));
    REQUIRE(field.step_toward(3, 1, nc, nr));
    CHECK(nc == 4);
    // goals off the map are dropped
    NavFlowField none(kept, {{9, 9}}, false);
    CHECK(std::isinf(none.distance(0, 0)));
}

TEST_CASE("nav flow: the nav.flow_field command") {
    World world;
    auto r = nav_flow_query(world, Json::parse(
        R"({"grid":{"width":4,"height":2,"cost":[1,1,null,1, 1,1,1,1]},"goals":[[3,0]],"from":[0,0]})"));
    REQUIRE(r.ok());
    CHECK(r.value()["distance"].size() == 8);
    CHECK(r.value()["distance"][2].is_null());
    CHECK(r.value()["distance"][4].get<float>() == doctest::Approx(4.0f));
    CHECK(r.value()["reachable"] == true);
    CHECK(r.value()["cost"].get<float>() == doctest::Approx(5.0f));
    CHECK(r.value()["next"] == Json::array({1, 0}));
    CHECK(r.value()["path"].size() == 6);
    auto bad = nav_flow_query(world, Json::parse(R"({"grid":{"width":2,"height":1,"cost":[1,1]},"goals":[[5,0]]})"));
    REQUIRE_FALSE(bad.ok());
    CHECK(bad.error().message.find("outside") != std::string::npos);
    bad = nav_flow_query(world, Json::parse(R"({"grid":{"width":2,"height":1,"cost":[1,1]}})"));
    REQUIRE_FALSE(bad.ok());
    CHECK(bad.error().message.find("goals") != std::string::npos);
}
