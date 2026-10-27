// Single-tile writes (set_tilemap_tile / entity.tilemap.setTile): 2D physics patches only the colliders that changed.
#include <doctest.h>

#include <chrono>
#include <cmath>

#include "fa/physics/physics.h"
#include "fa/scene/tilemap.h"

using namespace fa;

namespace {

constexpr float kDt = 1.0f / 60.0f;

struct Sim {
    World world;
    Physics physics;
    Sim() { physics.init(PhysicsSettings{}); }
    void run(int steps) {
        for (int i = 0; i < steps; ++i) {
            world.events().clear();
            physics.step(world, kDt);
            world.advance_clock(kDt);
            world.flush();
        }
    }
};

// A 10 x 3 map with a solid floor on the bottom row (tile 1), top-left corner at (-80, 0): the floor's top is y = -32.
Entity add_floor_map(Sim& s, bool rows) {
    Entity map = s.world.create("map", "map");
    s.world.get<Transform>(map)->position = {-80, 0, 0};
    Tilemap& tm = s.world.add<Tilemap>(map);
    tm.tileSize = {16, 16};
    tm.solidTiles = Json::array({1});
    Json flat = Json::array();
    for (int r = 0; r < 3; ++r) {
        Json row = Json::array();
        for (int c = 0; c < 10; ++c) {
            flat.push_back(r == 2 ? 1 : -1);
            row.push_back(r == 2 ? 1 : -1);
        }
        if (rows) tm.tiles.push_back(row);
    }
    if (!rows) {
        tm.width = 10;
        tm.height = 3;
        tm.tiles = flat;
    }
    return map;
}

Entity add_body(Sim& s, Vec2 pos, Vec2 size) {
    Entity e = s.world.create("box", "box");
    s.world.get<Transform>(e)->position = {pos.x, pos.y, 0};
    s.world.add<Collider2D>(e).size = size;
    s.world.add<RigidBody2D>(e).type = BodyType::Dynamic;
    return e;
}

int tile_box_count(Sim& s) {
    for (const Json& j : s.physics.debug_state(s.world))
        if (j.value("kind", "") == "tilemap") return j["shapeCount"].get<int>();
    return -1;
}

bool floor_at(Sim& s, int col) {
    const float x = -80.0f + 16.0f * float(col) + 8.0f;
    return s.physics.raycast2d(s.world, {x, -20}, {x, -40}).has_value();
}

}  // namespace

TEST_CASE("2d: setTile opens a hole a body falls through on the next step, in both tile layouts") {
    for (bool rows : {false, true}) {
        INFO("rows form: " << rows);
        Sim s;
        Entity map = add_floor_map(s, rows);
        // A 12 wide box over column 5 (x in [0, 16]): it fits through a one-tile hole.
        Entity box = add_body(s, {8, 40}, {12, 12});
        s.run(120);
        CHECK(s.world.world_position(box).y == doctest::Approx(-26.0f).epsilon(0.05));  // on the floor (y = -32 + 6)
        REQUIRE(tile_box_count(s) == 1);
        Tilemap& tm = *s.world.get<Tilemap>(map);
        REQUIRE(set_tilemap_tile(tm, 5, 2, -1));
        s.run(1);
        CHECK(tile_box_count(s) == 2);  // the floor box was split around the hole: only that box was rebuilt
        s.run(120);
        CHECK(s.world.world_position(box).y < -60.0f);  // fell through the hole
        CHECK(tm.edits.empty());                         // physics consumed the edits
        // Closing it again puts a floor back (the box lies below it now, so look with a ray).
        REQUIRE(set_tilemap_tile(tm, 5, 2, 1));
        s.run(1);
        CHECK(floor_at(s, 5));
    }
}

TEST_CASE("2d: single writes patch the colliders; a whole-array write still rebuilds") {
    Sim s;
    Entity map = add_floor_map(s, false);
    Tilemap& tm = *s.world.get<Tilemap>(map);
    // A second, separate solid block on the top row that no edit below touches.
    REQUIRE(set_tilemap_tile(tm, 9, 0, 1));
    s.run(2);
    const int before = tile_box_count(s);
    REQUIRE(before == 2);
    REQUIRE(set_tilemap_tile(tm, 0, 2, -1));  // trims the end of the floor box
    s.run(1);
    CHECK(tile_box_count(s) == before);
    CHECK_FALSE(floor_at(s, 0));
    CHECK(floor_at(s, 1));
    // Many writes in one step are one patch, and the result is what a whole rebuild would give.
    for (int i = 0; i < 1000; ++i) REQUIRE(set_tilemap_tile(tm, 3 + (i % 2), 2, i % 3 == 0 ? -1 : 1));
    s.run(1);
    CHECK(tm.edits.empty());
    for (int c = 0; c < 10; ++c) CHECK(floor_at(s, c) == (tilemap_tile_at(tm, tilemap_size(tm), c, 2) == 1));
    // A whole-array write (no edits recorded) is caught by the hash and the body is rebuilt from the new tiles.
    Json tiles = tm.tiles;
    tiles[std::size_t(2 * 10 + 7)] = -1;
    tm.tiles = tiles;
    s.run(1);
    CHECK_FALSE(floor_at(s, 7));
    CHECK(floor_at(s, 8));
}

TEST_CASE("2d: a flip flag written with setTile keeps the tile solid") {
    Sim s;
    Entity map = add_floor_map(s, false);
    Tilemap& tm = *s.world.get<Tilemap>(map);
    s.run(1);
    REQUIRE(set_tilemap_tile(tm, 4, 2, make_tile(1, 1)));  // the same solid tile turned a quarter turn
    s.run(1);
    CHECK(floor_at(s, 4));
    CHECK(tile_box_count(s) == 1);  // no collider changed
}

TEST_CASE("tilemap: a write outside the map or with a bad tile value is refused and changes nothing") {
    Sim s;
    Entity map = add_floor_map(s, false);
    Tilemap& tm = *s.world.get<Tilemap>(map);
    const Json before = tm.tiles;
    CHECK_FALSE(set_tilemap_tile(tm, 10, 0, 1));
    CHECK_FALSE(set_tilemap_tile(tm, 0, 3, 1));
    CHECK_FALSE(set_tilemap_tile(tm, -1, 0, 1));
    CHECK_FALSE(set_tilemap_tile(tm, 0, 0, -2));
    CHECK(tm.tiles == before);
    CHECK(tm.edits.empty());
}

TEST_CASE("tilemap: 1000 single-tile writes cost less than rewriting the whole array once") {
    Tilemap tm;
    tm.tileSize = {16, 16};
    tm.width = 256;
    tm.height = 256;
    Json tiles = Json::array();
    for (int i = 0; i < 256 * 256; ++i) tiles.push_back(i % 7 == 0 ? 1 : -1);
    tm.tiles = tiles;
    using Clock = std::chrono::steady_clock;
    const auto t0 = Clock::now();
    for (int i = 0; i < 1000; ++i) REQUIRE(set_tilemap_tile(tm, (i * 37) % 256, (i * 11) % 256, i % 5));
    const auto t1 = Clock::now();
    Json copy = tm.tiles;  // what a script pays for one whole-array write: the array copied out, changed and set back
    copy[0] = 3;
    tm.tiles = copy;
    const auto t2 = Clock::now();
    // 1000 in-place writes against ONE copy-and-set of the array: a wide margin even on a slow, loaded machine.
    CHECK(t1 - t0 < t2 - t1);
    CHECK(tm.edits.size() <= 1000);
}

TEST_CASE("2d: an isometric map collides as diamonds, and single writes patch one diamond") {
    Sim s;
    Entity map = s.world.create("iso", "iso");
    Tilemap& tm = s.world.add<Tilemap>(map);
    tm.projection = TilemapProjection::Isometric;
    tm.tileSize = {100, 50};
    tm.solidTiles = Json::array({1});
    tm.width = 3;
    tm.height = 3;
    tm.tiles = Json::parse("[-1,-1,-1, -1,1,-1, -1,-1,-1]");
    s.run(2);
    // Cell (1, 1) is a diamond centred at (0, -75) with half-axes 50 x 25.
    CHECK(tile_box_count(s) == 1);
    auto solid_at = [&](Vec2 p) { return s.physics.raycast2d(s.world, {p.x, p.y + 30}, {p.x, p.y - 30}).has_value(); };
    CHECK(solid_at({0, -75}));
    CHECK(solid_at({30, -75}));
    // Inside the 100x50 square of the cell but outside the diamond: a short segment above the diamond's slanted top edge.
    CHECK_FALSE(s.physics.raycast2d(s.world, {45, -45}, {45, -60}).has_value());
    CHECK(s.physics.raycast2d(s.world, {5, -45}, {5, -60}).has_value());
    CHECK_FALSE(solid_at({0, -75 + 80}));
    // A neighbouring diamond is its own collider (no run merging): two cells give two shapes.
    REQUIRE(set_tilemap_tile(tm, 2, 1, 1));
    s.run(1);
    CHECK(tile_box_count(s) == 2);
    CHECK(solid_at({50, -100}));  // cell (2, 1): centre ((2 - 1) * 50, -(2 + 1 + 1) * 25) = (50, -100)
    REQUIRE(set_tilemap_tile(tm, 1, 1, -1));
    s.run(1);
    CHECK(tile_box_count(s) == 1);
    CHECK_FALSE(solid_at({-20, -75}));
    CHECK(solid_at({50, -100}));
    CHECK(tm.edits.empty());
}
