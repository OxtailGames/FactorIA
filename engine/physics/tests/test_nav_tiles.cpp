// Tile pathfinding: A* over a Tilemap or a cost grid (nav_find_tile_path, nav_tile_query).
#include <doctest.h>

#include <cmath>

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
