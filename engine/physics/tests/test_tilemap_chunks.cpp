// Tilemap colliders and the tile cost grid are kept in 32 x 32 cell chunks: an edit rebuilds only the chunks it changed,
// and the result is what a fresh build of the same tiles gives.
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
Entity add_map(Sim& s, int w, int h, const std::vector<int>& tiles) {
    Entity map = s.world.create("map", "map");
    Tilemap& tm = s.world.add<Tilemap>(map);
    tm.tileSize = {kTile, kTile};
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
    return sig;
}

// The same tiles in a world of their own that never saw an edit.
std::string fresh_signature(const Tilemap& tm, int w, int h) {
    Sim fresh;
    Entity map = fresh.world.create("map", "map");
    Tilemap& copy = fresh.world.add<Tilemap>(map);
    copy.tileSize = tm.tileSize;
    copy.solidTiles = tm.solidTiles;
    set_tilemap_grid(copy, w, h, tilemap_grid(tm).tiles);
    fresh.run(2);
    return collision_signature(fresh, w, h);
}

}  // namespace

TEST_CASE("2d chunks: random single edits give the colliders of a fresh build, in the chunks they touch only") {
    constexpr int W = 70, H = 45;  // 3 x 2 chunks of 32 cells
    Rng rng(1234);
    Sim s;
    Entity map = add_map(s, W, H, random_tiles(rng, W, H));
    s.run(2);
    Tilemap& tm = *s.world.get<Tilemap>(map);
    REQUIRE(collision_signature(s, W, H) == fresh_signature(tm, W, H));
    const std::int64_t built = s.tilemap_state()["chunkRebuilds"].get<std::int64_t>();
    CHECK(built == 6);  // every chunk of the first build
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
        const std::int64_t now = s.tilemap_state()["chunkRebuilds"].get<std::int64_t>();
        CHECK(now - rebuilds <= std::min<std::int64_t>(edits, 6));  // never more chunks than edits (or than there are)
        rebuilds = now;
    }
    CHECK(s.tilemap_state()["fullScans"].get<int>() == 0);  // every step was explained by the edits
}

TEST_CASE("2d chunks: one edit rebuilds one chunk; boxes never cross a chunk edge") {
    Sim s;
    // A solid floor 100 cells wide, 3 rows: runs are cut at the chunk edges (columns 32, 64, 96): 4 boxes.
    std::vector<int> tiles(100 * 4, -1);
    for (int c = 0; c < 100; ++c) tiles[std::size_t(3 * 100 + c)] = 1;
    Entity map = add_map(s, 100, 4, tiles);
    s.run(2);
    CHECK(s.shapes() == 4);
    Tilemap& tm = *s.world.get<Tilemap>(map);
    REQUIRE(set_tilemap_tile(tm, 40, 3, -1));  // splits the second chunk's box in two
    s.run(1);
    CHECK(s.shapes() == 5);
    CHECK(s.tilemap_state()["chunkRebuilds"].get<int>() == 5);  // the four chunks of the first build, and the one edited
}

TEST_CASE("2d chunks: a write and its revert, or a flag-only write, rebuild nothing and keep the stamp fresh") {
    constexpr int W = 40, H = 40;
    Rng rng(7);
    Sim s;
    Entity map = add_map(s, W, H, random_tiles(rng, W, H));
    s.run(2);
    Tilemap& tm = *s.world.get<Tilemap>(map);
    const std::int64_t rebuilds = s.tilemap_state()["chunkRebuilds"].get<std::int64_t>();
    const int old = tilemap_tile_at(tm, tilemap_size(tm), 5, 5);
    // Write, then put it back before physics looks: the same collision as before.
    REQUIRE(set_tilemap_tile(tm, 5, 5, old == 1 ? -1 : 1));
    REQUIRE(set_tilemap_tile(tm, 5, 5, old));
    s.run(1);
    CHECK(s.tilemap_state()["chunkRebuilds"].get<std::int64_t>() == rebuilds);
    // A flag on a solid tile or a different solid tile: no collider changes.
    int solidCol = -1;
    for (int c = 0; c < W && solidCol < 0; ++c)
        if (tile_index(tilemap_tile_at(tm, tilemap_size(tm), c, 10)) == 1) solidCol = c;
    REQUIRE(solidCol >= 0);
    REQUIRE(set_tilemap_tile(tm, solidCol, 10, make_tile(1, 2)));
    s.run(1);
    CHECK(s.tilemap_state()["chunkRebuilds"].get<std::int64_t>() == rebuilds);
    // Later steps with no write at all, and then a real edit, never fall back to scanning the map.
    s.run(5);
    REQUIRE(set_tilemap_tile(tm, 6, 6, tile_index(tilemap_tile_at(tm, tilemap_size(tm), 6, 6)) == 1 ? -1 : 1));
    s.run(1);
    CHECK(s.tilemap_state()["fullScans"].get<int>() == 0);
    CHECK(s.tilemap_state()["chunkRebuilds"].get<std::int64_t>() == rebuilds + 1);
}

TEST_CASE("2d chunks: a write that bypasses the edit list scans the map once and rebuilds only the chunks that differ") {
    constexpr int W = 70, H = 70;
    Rng rng(99);
    Sim s;
    Entity map = add_map(s, W, H, random_tiles(rng, W, H));
    s.run(2);
    Tilemap& tm = *s.world.get<Tilemap>(map);
    const std::int64_t rebuilds = s.tilemap_state()["chunkRebuilds"].get<std::int64_t>();
    // Straight into the array: no edit is recorded, the version moves.
    const std::size_t i = std::size_t(40) * W + 40;
    tm.tiles.set(i, std::as_const(tm.tiles)[i] == 1 ? -1 : 1);
    s.run(1);
    CHECK(s.tilemap_state()["fullScans"].get<int>() == 1);
    CHECK(s.tilemap_state()["chunkRebuilds"].get<std::int64_t>() == rebuilds + 1);
    CHECK(collision_signature(s, W, H) == fresh_signature(tm, W, H));
    s.run(3);  // and the next steps are cheap again
    CHECK(s.tilemap_state()["fullScans"].get<int>() == 1);
}

TEST_CASE("2d chunks: assigning a whole Tilemap does not replay the edits the source carried") {
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

TEST_CASE("2d chunks: a map with no solid tiles builds no body, and gets one when a solid tile is declared") {
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

TEST_CASE("2d chunks: a body standing on an untouched chunk keeps its contact while another chunk changes") {
    Sim s;
    std::vector<int> tiles(100 * 4, -1);
    for (int c = 0; c < 100; ++c) tiles[std::size_t(3 * 100 + c)] = 1;
    Entity map = add_map(s, 100, 4, tiles);
    Entity box = s.world.create("box", "box");
    s.world.get<Transform>(box)->position = {kTile * 10.0f, -kTile * 3.0f + 4.0f, 0};  // standing on column 10
    s.world.add<Collider2D>(box).size = {6, 6};
    s.world.add<RigidBody2D>(box).type = BodyType::Dynamic;
    s.run(60);
    Tilemap& tm = *s.world.get<Tilemap>(map);
    int ends = 0;
    for (int i = 0; i < 4; ++i) {
        REQUIRE(set_tilemap_tile(tm, 80 + i, 3, -1));  // the last chunk, far from the box
        s.world.events().clear();
        s.physics.step(s.world, kDt);
        for (const auto& c : s.world.events().collisions)
            if (c.phase == CollisionEvent::Phase::End) ++ends;
        s.world.advance_clock(kDt);
        s.world.flush();
    }
    CHECK(ends == 0);
    CHECK(s.world.world_position(box).y > -kTile * 3.0f);  // still on the floor
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
