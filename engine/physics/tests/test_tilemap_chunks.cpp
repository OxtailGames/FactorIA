// Tilemap colliders are one decomposition of the solid cells (a long floor is one box) that an edit patches box by box, and
// the nav cost grid is kept and patched cell by cell: either way the result is what a fresh build of the same tiles gives.
#include <doctest.h>

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <string>
#include <utility>
#include <vector>

#include "fa/core/math.h"
#include "fa/physics/nav.h"
#include "fa/physics/physics.h"
#include "fa/scene/tilemap.h"

using namespace fa;

namespace {

constexpr float kDt = 1.0f / 60.0f;
constexpr float kTile = 8.0f;

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
    Json tilemap_state() {
        for (const Json& j : physics.debug_state(world))
            if (j.value("kind", "") == "tilemap") return j;
        return Json();
    }
    int shapes() {
        const Json j = tilemap_state();
        return j.is_null() ? -1 : j["shapeCount"].get<int>();
    }
};

// A map of w x h cells whose top-left corner is the origin; tiles 1 and 2 are solid, 3 is decoration.
Entity add_map(Sim& s, int w, int h, const std::vector<int>& tiles,
               TilemapProjection projection = TilemapProjection::Orthogonal) {
    Entity map = s.world.create("map", "map");
    Tilemap& tm = s.world.add<Tilemap>(map);
    tm.tileSize = {kTile, kTile};
    tm.projection = projection;
    tm.solidTiles = Json::array({1, 2});
    set_tilemap_grid(tm, w, h, tiles);
    return map;
}

std::vector<int> random_tiles(Rng& rng, int w, int h) {
    std::vector<int> t(std::size_t(w) * std::size_t(h));
    for (int& v : t) {
        const std::uint32_t r = rng.next_u32() % 10;
        v = r < 4 ? 1 : r < 5 ? 2 : r < 6 ? 3 : -1;
    }
    return t;
}

// What collides, as a string: for every cell whether a small box in its middle touches the map, plus the nearest hit of
// a ray along every row and every column (from both ends).
std::string collision_signature(Sim& s, int w, int h) {
    std::string sig;
    for (int r = 0; r < h; ++r)
        for (int c = 0; c < w; ++c) {
            const float cx = (float(c) + 0.5f) * kTile, cy = -(float(r) + 0.5f) * kTile;
            sig += s.physics.overlap_box2d(s.world, Rect{cx - 1, cy - 1, 2, 2}).empty() ? '.' : '#';
        }
    auto ray = [&](Vec2 a, Vec2 b) {
        const auto hit = s.physics.raycast2d(s.world, a, b);
        sig += hit ? std::to_string(std::lround(hit->distance * 100.0f)) + ";" : "-;";
    };
    const float W = float(w) * kTile, H = float(h) * kTile;
    for (int r = 0; r < h; ++r) {
        const float y = -(float(r) + 0.5f) * kTile;
        ray({-4, y}, {W + 4, y});
        ray({W + 4, y}, {-4, y});
    }
    for (int c = 0; c < w; ++c) {
        const float x = (float(c) + 0.5f) * kTile;
        ray({x, 4}, {x, -H - 4});
        ray({x, -H - 4}, {x, 4});
    }
    // And the boxes themselves (sorted): an edited map has the very decomposition of a fresh build.
    std::vector<std::string> boxes;
    for (const Physics::DebugShape& d : s.physics.debug_shapes(s.world))
        boxes.push_back(std::to_string(std::lround(d.center.x * 10)) + "," + std::to_string(std::lround(d.center.y * 10)) + "," +
                        std::to_string(std::lround(d.size.x * 10)) + "," + std::to_string(std::lround(d.size.y * 10)));
    std::sort(boxes.begin(), boxes.end());
    for (const std::string& b : boxes) sig += "|" + b;
    return sig;
}

// The same tiles in a world of their own that never saw an edit.
std::string fresh_signature(const Tilemap& tm, int w, int h) {
    Sim fresh;
    Entity map = fresh.world.create("map", "map");
    Tilemap& copy = fresh.world.add<Tilemap>(map);
    copy.tileSize = tm.tileSize;
    copy.projection = tm.projection;
    copy.groundHeight = tm.groundHeight;
    copy.solidTiles = tm.solidTiles;
    set_tilemap_grid(copy, w, h, tilemap_grid(tm).tiles);
    fresh.run(2);
    return collision_signature(fresh, w, h);
}

}  // namespace

TEST_CASE("2d tilemap boxes: random edits give the colliders of a fresh build, and rebuild the boxes they touch only") {
    constexpr int W = 70, H = 45;
    Rng rng(1234);
    Sim s;
    Entity map = add_map(s, W, H, random_tiles(rng, W, H));
    s.run(2);
    Tilemap& tm = *s.world.get<Tilemap>(map);
    REQUIRE(collision_signature(s, W, H) == fresh_signature(tm, W, H));
    const std::int64_t built = s.tilemap_state()["boxesBuilt"].get<std::int64_t>();
    CHECK(built == s.shapes());  // the first build made every box once
    std::int64_t rebuilds = built;
    for (int round = 0; round < 12; ++round) {
        INFO("round " << round);
        const int edits = 1 + int(rng.next_u32() % 30);
        for (int i = 0; i < edits; ++i) {
            const int c = int(rng.next_u32() % std::uint32_t(W)), r = int(rng.next_u32() % std::uint32_t(H));
            const std::uint32_t v = rng.next_u32() % 6;
            const int value = v == 0 ? -1 : v == 1 ? 3 : v == 2 ? make_tile(1, 1) : v == 3 ? 2 : 1;
            REQUIRE(set_tilemap_tile(tm, c, r, value));
        }
        s.run(1);
        CHECK(collision_signature(s, W, H) == fresh_signature(tm, W, H));
        const std::int64_t now = s.tilemap_state()["boxesBuilt"].get<std::int64_t>();
        // An edit takes apart the boxes it touches (its own, and the ones above and below that join its row): a handful per
        // edit, never the map.
        CHECK(now - rebuilds <= edits * 12);
        rebuilds = now;
    }
    CHECK(s.tilemap_state()["fullScans"].get<int>() == 0);  // every step was explained by the edits
}

namespace {

// Edits one cell at random (solid, decoration, empty) and checks the map against a fresh build, `rounds` times.
void edit_and_compare(Sim& s, Entity map, int w, int h, Rng& rng, int rounds, int editsPerRound) {
    Tilemap& tm = *s.world.get<Tilemap>(map);
    for (int round = 0; round < rounds; ++round) {
        INFO("round " << round);
        for (int i = 0; i < editsPerRound; ++i) {
            const int c = int(rng.next_u32() % std::uint32_t(w)), r = int(rng.next_u32() % std::uint32_t(h));
            const std::uint32_t v = rng.next_u32() % 4;
            REQUIRE(set_tilemap_tile(tm, c, r, v == 0 ? -1 : v == 1 ? 3 : v == 2 ? 2 : 1));
        }
        s.run(1);
        CHECK(collision_signature(s, w, h) == fresh_signature(tm, w, h));
    }
}

}  // namespace

TEST_CASE("2d tilemap boxes: rectangular rooms split and merged by edits in the middle equal a fresh build") {
    constexpr int W = 56, H = 34;
    Rng rng(777);
    std::vector<int> tiles(std::size_t(W) * std::size_t(H), -1);
    for (int room = 0; room < 9; ++room) {  // solid blocks 3 to 20 cells on a side, some overlapping
        const int bw = 3 + int(rng.next_u32() % 18), bh = 3 + int(rng.next_u32() % 18);
        const int x0 = int(rng.next_u32() % std::uint32_t(W - bw + 1)), y0 = int(rng.next_u32() % std::uint32_t(H - bh + 1));
        for (int r = y0; r < y0 + bh; ++r)
            for (int c = x0; c < x0 + bw; ++c) tiles[std::size_t(r) * W + std::size_t(c)] = 1;
    }
    Sim s;
    Entity map = add_map(s, W, H, tiles);
    s.run(2);
    Tilemap& tm = *s.world.get<Tilemap>(map);
    REQUIRE(collision_signature(s, W, H) == fresh_signature(tm, W, H));
    // Holes punched in the middle of a block (it splits into runs and boxes), then filled again (they merge back).
    std::vector<std::pair<int, int>> holes;
    for (int i = 0; i < 60; ++i) {
        const int c = 2 + int(rng.next_u32() % std::uint32_t(W - 4)), r = 2 + int(rng.next_u32() % std::uint32_t(H - 4));
        if (tiles[std::size_t(r) * W + std::size_t(c)] != 1 || std::find(holes.begin(), holes.end(), std::make_pair(c, r)) != holes.end())
            continue;
        holes.push_back({c, r});
        REQUIRE(set_tilemap_tile(tm, c, r, -1));
        s.run(1);
        CHECK(collision_signature(s, W, H) == fresh_signature(tm, W, H));
    }
    for (auto [c, r] : holes) {
        REQUIRE(set_tilemap_tile(tm, c, r, 1));
        s.run(1);
        CHECK(collision_signature(s, W, H) == fresh_signature(tm, W, H));
    }
    CHECK(holes.size() >= 8);
    // Everything back to the first tiles: the very boxes of the first build.
    CHECK(tilemap_grid(tm).tiles == tiles);
    edit_and_compare(s, map, W, H, rng, 6, 25);
}

TEST_CASE("2d tilemap boxes: an isometric map edited has the diamonds of a fresh build") {
    constexpr int W = 18, H = 14;
    Rng rng(4321);
    Sim s;
    Entity map = add_map(s, W, H, random_tiles(rng, W, H), TilemapProjection::Isometric);
    s.run(2);
    Tilemap& tm = *s.world.get<Tilemap>(map);
    CHECK(s.shapes() > 0);
    CHECK(collision_signature(s, W, H) == fresh_signature(tm, W, H));
    edit_and_compare(s, map, W, H, rng, 8, 10);
}

TEST_CASE("2d tilemap boxes: the debug boxes follow a Tilemap that moved, edited or not") {
    constexpr int W = 20, H = 8;
    std::vector<int> tiles(std::size_t(W) * std::size_t(H), -1);
    for (int c = 0; c < W; ++c) tiles[std::size_t(7) * W + std::size_t(c)] = 1;
    auto boxes_of = [](Sim& sim) {
        std::vector<std::string> out;
        for (const Physics::DebugShape& d : sim.physics.debug_shapes(sim.world))
            out.push_back(std::to_string(std::lround(d.center.x)) + "," + std::to_string(std::lround(d.center.y)) + "," +
                          std::to_string(std::lround(d.size.x)) + "," + std::to_string(std::lround(d.size.y)));
        std::sort(out.begin(), out.end());
        return out;
    };
    Sim s;
    Entity map = add_map(s, W, H, tiles);
    s.run(2);
    const std::vector<std::string> before = boxes_of(s);
    REQUIRE(before.size() == 1);
    s.world.set_world_position(map, {100.0f, 50.0f, 0.0f});
    s.run(1);
    Tilemap& tm = *s.world.get<Tilemap>(map);
    REQUIRE(set_tilemap_tile(tm, 5, 7, -1));  // splits the floor after the map moved
    s.run(1);
    Sim fresh;
    Entity same = add_map(fresh, W, H, tilemap_grid(tm).tiles);
    fresh.world.set_world_position(same, {100.0f, 50.0f, 0.0f});
    fresh.run(2);
    CHECK(boxes_of(s) == boxes_of(fresh));
    CHECK(boxes_of(s).size() == 2);
}

TEST_CASE("nav tiles: a scene unload (Physics::reset) lets go of the kept grids") {
    constexpr int W = 40, H = 40;
    Sim s;
    (void)add_map(s, W, H, std::vector<int>(std::size_t(W) * H, -1));
    nav_tile_cache_clear();
    const Json query = Json::parse(R"({"tilemap":"map","from":[0,0],"to":[39,39]})");
    REQUIRE(nav_tile_query(s.world, query).ok());
    REQUIRE(nav_tile_query(s.world, query).ok());
    CHECK(nav_tile_cache_stats().fullBuilds == 1);
    CHECK(nav_tile_cache_stats().hits >= 1);
    s.physics.reset();
    REQUIRE(nav_tile_query(s.world, query).ok());
    CHECK(nav_tile_cache_stats().fullBuilds == 2);  // the grid of the old scene was gone
}

TEST_CASE("2d tilemap boxes: a long floor is one box, an edit splits it and a second edit joins it again") {
    Sim s;
    std::vector<int> tiles(100 * 4, -1);
    for (int c = 0; c < 100; ++c) tiles[std::size_t(3 * 100 + c)] = 1;
    Entity map = add_map(s, 100, 4, tiles);
    s.run(2);
    CHECK(s.shapes() == 1);  // no seam at columns 32, 64, 96
    Tilemap& tm = *s.world.get<Tilemap>(map);
    REQUIRE(set_tilemap_tile(tm, 40, 3, -1));
    s.run(1);
    CHECK(s.shapes() == 2);
    CHECK(s.tilemap_state()["boxesBuilt"].get<int>() == 3);  // the floor, and the two halves
    REQUIRE(set_tilemap_tile(tm, 40, 3, 1));
    s.run(1);
    CHECK(s.shapes() == 1);
    CHECK(s.tilemap_state()["boxesBuilt"].get<int>() == 4);
    // A tile on top of the floor makes a box of its own (a different run); two more of the same columns stack into one.
    REQUIRE(set_tilemap_tile(tm, 10, 2, 1));
    REQUIRE(set_tilemap_tile(tm, 10, 1, 1));
    s.run(1);
    CHECK(s.shapes() == 2);
}

TEST_CASE("2d tilemap boxes: a write and its revert, or a flag-only write, rebuild nothing and keep the stamp fresh") {
    constexpr int W = 40, H = 40;
    Rng rng(7);
    Sim s;
    Entity map = add_map(s, W, H, random_tiles(rng, W, H));
    s.run(2);
    Tilemap& tm = *s.world.get<Tilemap>(map);
    const std::int64_t rebuilds = s.tilemap_state()["boxesBuilt"].get<std::int64_t>();
    const int old = tilemap_tile_at(tm, tilemap_size(tm), 5, 5);
    // Write, then put it back before physics looks: the same collision as before.
    REQUIRE(set_tilemap_tile(tm, 5, 5, old == 1 ? -1 : 1));
    REQUIRE(set_tilemap_tile(tm, 5, 5, old));
    s.run(1);
    CHECK(s.tilemap_state()["boxesBuilt"].get<std::int64_t>() == rebuilds);
    // A flag on a solid tile or a different solid tile: no collider changes.
    int solidCol = -1;
    for (int c = 0; c < W && solidCol < 0; ++c)
        if (tile_index(tilemap_tile_at(tm, tilemap_size(tm), c, 10)) == 1) solidCol = c;
    REQUIRE(solidCol >= 0);
    REQUIRE(set_tilemap_tile(tm, solidCol, 10, make_tile(1, 2)));
    s.run(1);
    CHECK(s.tilemap_state()["boxesBuilt"].get<std::int64_t>() == rebuilds);
    // Later steps with no write at all, and then a real edit, never fall back to scanning the map.
    s.run(5);
    REQUIRE(set_tilemap_tile(tm, 6, 6, tile_index(tilemap_tile_at(tm, tilemap_size(tm), 6, 6)) == 1 ? -1 : 1));
    s.run(1);
    CHECK(s.tilemap_state()["fullScans"].get<int>() == 0);
    CHECK(s.tilemap_state()["boxesBuilt"].get<std::int64_t>() > rebuilds);
}

TEST_CASE("2d tilemap boxes: a write that bypasses the edit list scans the map once and rebuilds only the boxes that differ") {
    constexpr int W = 70, H = 70;
    Rng rng(99);
    Sim s;
    Entity map = add_map(s, W, H, random_tiles(rng, W, H));
    s.run(2);
    Tilemap& tm = *s.world.get<Tilemap>(map);
    const std::int64_t rebuilds = s.tilemap_state()["boxesBuilt"].get<std::int64_t>();
    // Straight into the array: no edit is recorded, the version moves.
    const std::size_t i = std::size_t(40) * W + 40;
    tm.tiles.set(i, std::as_const(tm.tiles)[i] == 1 ? -1 : 1);
    s.run(1);
    CHECK(s.tilemap_state()["fullScans"].get<int>() == 1);
    CHECK(s.tilemap_state()["boxesBuilt"].get<std::int64_t>() > rebuilds);
    CHECK(collision_signature(s, W, H) == fresh_signature(tm, W, H));
    s.run(3);  // and the next steps are cheap again
    CHECK(s.tilemap_state()["fullScans"].get<int>() == 1);
}

TEST_CASE("2d tilemap boxes: assigning a whole Tilemap does not replay the edits the source carried") {
    constexpr int W = 50, H = 40;
    Rng rng(5);
    Sim s;
    Entity map = add_map(s, W, H, random_tiles(rng, W, H));
    s.run(2);
    Tilemap& tm = *s.world.get<Tilemap>(map);
    // Another map with other tiles whose edit log holds exactly one entry: the version of tm moves by one when it is
    // assigned, the same count, though the edit explains none of the difference.
    Tilemap other = tm;
    set_tilemap_tiles(other, [&] {
        Json t = Json::array();
        for (int v : random_tiles(rng, W, H)) t.push_back(v);
        return t;
    }());
    REQUIRE(set_tilemap_tile(other, 3, 3, std::as_const(other.tiles)[std::size_t(3 * W + 3)] == 1 ? -1 : 1));
    REQUIRE(other.edits.size() == 1);
    tm = other;
    s.run(1);
    CHECK(collision_signature(s, W, H) == fresh_signature(tm, W, H));
    // Moving it in gives the same.
    Tilemap third = tm;
    set_tilemap_tiles(third, [&] {
        Json t = Json::array();
        for (int v : random_tiles(rng, W, H)) t.push_back(v);
        return t;
    }());
    REQUIRE(set_tilemap_tile(third, 9, 9, std::as_const(third.tiles)[std::size_t(9 * W + 9)] == 1 ? -1 : 1));
    tm = std::move(third);
    s.run(1);
    CHECK(collision_signature(s, W, H) == fresh_signature(tm, W, H));
}

TEST_CASE("2d tilemap boxes: a map with no solid tiles builds no body, and gets one when a solid tile is declared") {
    Sim s;
    std::vector<int> tiles(40 * 40, 3);
    Entity map = add_map(s, 40, 40, tiles);
    Tilemap& tm = *s.world.get<Tilemap>(map);
    tm.solidTiles = Json::array();
    s.run(3);
    CHECK(s.shapes() == -1);
    for (int i = 0; i < 10; ++i) REQUIRE(set_tilemap_tile(tm, i, i, 1));
    s.run(1);
    CHECK(s.shapes() == -1);
    tm.solidTiles = Json::array({1});
    s.run(1);
    CHECK(s.shapes() == 10);
}

TEST_CASE("2d tilemap boxes: a body standing on an untouched box keeps its contact while another part of the floor changes") {
    Sim s;
    std::vector<int> tiles(100 * 6, -1);
    for (int c = 0; c < 100; ++c) tiles[std::size_t(5 * 100 + c)] = 1;  // a floor...
    for (int c = 8; c < 14; ++c) tiles[std::size_t(3 * 100 + c)] = 1;   // ...and a platform above it
    Entity map = add_map(s, 100, 6, tiles);
    Entity box = s.world.create("box", "box");
    s.world.get<Transform>(box)->position = {kTile * 10.0f, -kTile * 3.0f + 4.0f, 0};  // standing on the platform
    s.world.add<Collider2D>(box).size = {6, 6};
    s.world.add<RigidBody2D>(box).type = BodyType::Dynamic;
    s.run(60);
    Tilemap& tm = *s.world.get<Tilemap>(map);
    int ends = 0;
    for (int i = 0; i < 4; ++i) {
        REQUIRE(set_tilemap_tile(tm, 80 + i, 5, -1));  // the far end of the floor: the platform box is not touched
        s.world.events().clear();
        s.physics.step(s.world, kDt);
        for (const auto& c : s.world.events().collisions)
            if (c.phase == CollisionEvent::Phase::End) ++ends;
        s.world.advance_clock(kDt);
        s.world.flush();
    }
    CHECK(ends == 0);
    CHECK(s.world.world_position(box).y > -kTile * 4.0f);  // still on the platform
}

namespace {

// The grid nav_tile_map hands out (the kept one, patched) against a grid read from scratch.
void check_grid_matches_fresh(World& world, const Tilemap& tm, const Json& costs) {
    NavTileGrid cached;
    Mat4 toWorld;
    bool worldPoints = false;
    Json args = Json::object();
    args["tilemap"] = "ground";
    if (!costs.is_null()) args["costs"] = costs;
    REQUIRE(nav_tile_map(world, args, "test", cached, toWorld, worldPoints).ok());
    const NavTileGrid fresh = nav_tile_grid_from_tilemap(tm, costs);
    REQUIRE(cached.width == fresh.width);
    REQUIRE(cached.height == fresh.height);
    CHECK(cached.cost == fresh.cost);
    CHECK(cached.cellSize == fresh.cellSize);
    CHECK(cached.isometric == fresh.isometric);
    CHECK(cached.minOpenCost == nav_tile_min_open_cost(fresh));
}

}  // namespace

TEST_CASE("nav tiles: the cost grid of a Tilemap follows single edits and equals a fresh build") {
    constexpr int W = 90, H = 70;
    Rng rng(42);
    World world;
    Entity map = world.create("ground", "ground");
    Tilemap& tm = world.add<Tilemap>(map);
    tm.tileSize = {kTile, kTile};
    tm.solidTiles = Json::array({1});
    set_tilemap_grid(tm, W, H, random_tiles(rng, W, H));
    nav_tile_cache_clear();
    check_grid_matches_fresh(world, tm, Json());
    CHECK(nav_tile_cache_stats().fullBuilds == 1);
    check_grid_matches_fresh(world, tm, Json());  // nothing changed
    CHECK(nav_tile_cache_stats().hits >= 1);
    const Json costs = Json::parse(R"({"2":3.5,"3":null})");
    check_grid_matches_fresh(world, tm, costs);  // another rule set is another grid
    CHECK(nav_tile_cache_stats().fullBuilds == 2);
    for (int round = 0; round < 15; ++round) {
        INFO("round " << round);
        const int edits = 1 + int(rng.next_u32() % 40);
        for (int i = 0; i < edits; ++i) {
            const int c = int(rng.next_u32() % std::uint32_t(W)), r = int(rng.next_u32() % std::uint32_t(H));
            const std::uint32_t v = rng.next_u32() % 5;
            REQUIRE(set_tilemap_tile(tm, c, r, v == 0 ? -1 : v == 1 ? 3 : v == 2 ? make_tile(1, 1) : v == 3 ? 2 : 1));
        }
        check_grid_matches_fresh(world, tm, round % 2 ? costs : Json());
    }
    const NavTileCacheStats stats = nav_tile_cache_stats();
    CHECK(stats.fullBuilds == 2);  // every later ask was a patch or a hit
    CHECK(stats.patches >= 8);
    CHECK(stats.patchedCells >= stats.patches);
}

TEST_CASE("nav tiles: queries on an edited Tilemap answer like a fresh build, a write the list does not explain rebuilds") {
    constexpr int W = 60, H = 40;
    Rng rng(8);
    World world;
    Entity map = world.create("ground", "ground");
    Tilemap& tm = world.add<Tilemap>(map);
    tm.tileSize = {kTile, kTile};
    tm.solidTiles = Json::array({1});
    set_tilemap_grid(tm, W, H, random_tiles(rng, W, H));
    nav_tile_cache_clear();
    const Json query = Json::parse(R"({"tilemap":"ground","from":[0,0],"to":[55,35],"closest":true,"diagonals":true})");
    auto answer = [&] {
        auto r = nav_tile_query(world, query);
        REQUIRE(r.ok());
        return r.value();
    };
    auto fresh_answer = [&] {
        nav_tile_cache_clear();  // forget the kept grid: this one reads every cell
        return answer();
    };
    answer();
    for (int round = 0; round < 6; ++round) {
        for (int i = 0; i < 20; ++i)
            REQUIRE(set_tilemap_tile(tm, int(rng.next_u32() % W), int(rng.next_u32() % H), rng.next_u32() % 2 ? 1 : -1));
        const Json kept = answer();
        CHECK(nav_tile_cache_stats().fullBuilds == 1);  // the grid of the first ask, patched since
        CHECK(nav_tile_cache_stats().patches == 1);
        CHECK(kept == fresh_answer());
        CHECK(nav_tile_cache_stats().fullBuilds == 1);  // fresh_answer started the counters again: one full read
        answer();  // the kept grid again, for the next round
    }
    // Straight into the array: no edit explains the new version, so the grid is read again.
    nav_tile_cache_clear();
    answer();
    tm.tiles.set(std::size_t(5) * W + 5, std::as_const(tm.tiles)[std::size_t(5) * W + 5] == 1 ? -1 : 1);
    answer();
    CHECK(nav_tile_cache_stats().fullBuilds == 2);
    check_grid_matches_fresh(world, tm, Json());
    // Assigning another Tilemap over it (its own edit log, one version step): never replayed as if it explained the change.
    Tilemap other = tm;
    set_tilemap_tiles(other, [&] {
        Json t = Json::array();
        for (int v : random_tiles(rng, W, H)) t.push_back(v);
        return t;
    }());
    REQUIRE(set_tilemap_tile(other, 2, 2, std::as_const(other.tiles)[std::size_t(2) * W + 2] == 1 ? -1 : 1));
    tm = other;
    check_grid_matches_fresh(world, tm, Json());
    // A small map is read each time (no kept grid) and still correct after a write.
    Entity small = world.create("small", "small");
    Tilemap& st = world.add<Tilemap>(small);
    st.tileSize = {kTile, kTile};
    st.solidTiles = Json::array({1});
    set_tilemap_grid(st, 4, 4, std::vector<int>(16, -1));
    const Json sq = Json::parse(R"({"tilemap":"small","from":[0,0],"to":[3,3]})");
    auto open = nav_tile_query(world, sq);
    REQUIRE(open.ok());
    CHECK(open.value()["found"] == true);
    for (int r = 0; r < 4; ++r) REQUIRE(set_tilemap_tile(st, 1, r, 1));  // a wall across the map
    auto shut = nav_tile_query(world, sq);
    REQUIRE(shut.ok());
    CHECK(shut.value()["found"] == false);
}

namespace {

// A body pushed along a flat floor at constant speed (no friction, no damping) must not lose speed anywhere: a seam between
// two boxes of the floor (a ghost collision) would stop it.
float slowest_on_floor(Sim& s, Entity box, float from, float to, float v0) {
    float slowest = v0;
    for (int i = 0; i < 600; ++i) {
        s.run(1);
        const float x = s.world.world_position(box).x;
        if (x > from && x < to) slowest = std::min(slowest, s.world.get<RigidBody2D>(box)->velocity.x);
        if (x >= to) break;
    }
    return slowest;
}

Entity add_runner(Sim& s, ColliderShape shape, float x, float v0) {
    Entity box = s.world.create("runner", "runner");
    s.world.get<Transform>(box)->position = {x, -3.0f * kTile + 3.5f, 0};  // on the floor of row 3
    Collider2D& col = s.world.add<Collider2D>(box);
    col.shape = shape;
    col.size = shape == ColliderShape::Capsule ? Vec2{5, 8} : Vec2{6, 6};
    col.radius = 3.0f;
    col.friction = 0.0f;
    RigidBody2D& rb = s.world.add<RigidBody2D>(box);
    rb.type = BodyType::Dynamic;
    rb.fixedRotation = true;
    rb.velocity = {v0, 0};
    return box;
}

}  // namespace

TEST_CASE("2d floor: a body pushed along a 100 cell floor keeps its speed across the 32 and 64 cell marks") {
    for (ColliderShape shape : {ColliderShape::Box, ColliderShape::Circle, ColliderShape::Capsule}) {
        INFO("shape " << int(shape));
        Sim s;
        std::vector<int> tiles(100 * 4, -1);
        for (int c = 0; c < 100; ++c) tiles[std::size_t(3 * 100 + c)] = 1;
        add_map(s, 100, 4, tiles);
        const Entity box = add_runner(s, shape, 3.0f * kTile, 120.0f);
        s.run(30);  // settles on the floor
        CHECK(slowest_on_floor(s, box, 4.0f * kTile, 96.0f * kTile, 120.0f) > 119.0f);
    }
}

TEST_CASE("2d floor: the same after edits that split the floor and close it again") {
    Sim s;
    std::vector<int> tiles(100 * 5, -1);
    for (int c = 0; c < 100; ++c) tiles[std::size_t(3 * 100 + c)] = 1;
    Entity map = add_map(s, 100, 5, tiles);
    s.run(2);
    Tilemap& tm = *s.world.get<Tilemap>(map);
    REQUIRE(set_tilemap_tile(tm, 40, 3, -1));  // a pit ...
    s.run(1);
    REQUIRE(set_tilemap_tile(tm, 40, 3, 1));  // ...filled again
    REQUIRE(set_tilemap_tile(tm, 70, 4, 1));  // and a block under the floor in the third
    s.run(1);
    const Entity box = add_runner(s, ColliderShape::Box, 3.0f * kTile, 120.0f);
    s.run(30);
    CHECK(slowest_on_floor(s, box, 4.0f * kTile, 96.0f * kTile, 120.0f) > 119.0f);
}
