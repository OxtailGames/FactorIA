#include <doctest.h>

#include "fa/scene/serialize.h"
#include "fa/scene/tilemap.h"

using namespace fa;

namespace {

Tilemap map_with(int w, int h, const char* tilesJson, const char* solidJson = "[]") {
    Tilemap tm;
    tm.width = w;
    tm.height = h;
    tm.tiles = Json::parse(tilesJson);
    tm.solidTiles = Json::parse(solidJson);
    tm.tileSize = {16, 16};
    return tm;
}

const TilemapIssue* find_issue(const std::vector<TilemapIssue>& issues, const std::string& pointer, const std::string& needle = "") {
    for (const TilemapIssue& i : issues)
        if (i.pointer == pointer && i.message.find(needle) != std::string::npos) return &i;
    return nullptr;
}

}  // namespace

TEST_CASE("tilemap: valid data in both forms has no issues") {
    CHECK(check_tilemap(Tilemap{}).empty());  // an empty default tilemap is fine
    CHECK(check_tilemap(map_with(3, 2, "[-1,0,1, 2,2,2]", "[0,1]")).empty());
    CHECK(check_tilemap(map_with(3, 2, "[[-1,0,1],[2,2,2]]", "[0]")).empty());
    CHECK(check_tilemap(map_with(0, 0, "[[-1,0,1],[2,2,2]]")).size() == 1);  // rows form without width/height: only a warning
    CHECK_FALSE(check_tilemap(map_with(0, 0, "[[-1,0,1],[2,2,2]]"))[0].error);
}

TEST_CASE("tilemap: a flat array must have width*height entries") {
    auto issues = check_tilemap(map_with(3, 3, "[0,0,0, 1,1,1]"));
    REQUIRE(issues.size() == 1);
    CHECK(issues[0].error);
    CHECK(issues[0].pointer == "/tiles");
    CHECK(issues[0].message.find("6 entries") != std::string::npos);
    CHECK(issues[0].message.find("3 x 3 = 9") != std::string::npos);
    CHECK(issues[0].hint.find("row 0 at the TOP") != std::string::npos);
    CHECK(issues[0].hint.find("scene.import_ascii") != std::string::npos);
}

TEST_CASE("tilemap: rows must be equal and match width and height") {
    auto issues = check_tilemap(map_with(3, 2, "[[0,0,0],[1,1]]"));
    REQUIRE(issues.size() == 1);
    CHECK(issues[0].pointer == "/tiles/1");
    CHECK(issues[0].message.find("row 1") != std::string::npos);
    CHECK(issues[0].message.find("2 entries") != std::string::npos);

    issues = check_tilemap(map_with(3, 3, "[[0,0,0],[1,1,1]]"));
    REQUIRE(issues.size() == 1);
    CHECK(issues[0].pointer == "/tiles");
    CHECK(issues[0].message.find("2 rows but height is 3") != std::string::npos);

    issues = check_tilemap(map_with(3, 2, "[[0,0,0], 5]"));
    REQUIRE(issues.size() >= 1);
    CHECK(issues[0].pointer == "/tiles/1");
    CHECK(issues[0].message.find("mixes") != std::string::npos);
}

TEST_CASE("tilemap: tile values must be integers >= -1 (strings point at scene.import_ascii)") {
    auto issues = check_tilemap(map_with(2, 2, "[0, \"#\", -2, 1.5]"));
    REQUIRE(issues.size() == 3);
    const TilemapIssue* str = find_issue(issues, "/tiles/1", "string");
    REQUIRE(str != nullptr);
    CHECK(str->hint.find("scene.import_ascii") != std::string::npos);
    CHECK(find_issue(issues, "/tiles/2", "-2") != nullptr);
    CHECK(find_issue(issues, "/tiles/3", "whole number") != nullptr);

    // A broken map does not flood the output.
    std::string many = "[";
    for (int i = 0; i < 100; ++i) many += std::string(i ? "," : "") + "\"x\"";
    many += "]";
    issues = check_tilemap(map_with(10, 10, many.c_str()));
    CHECK(issues.size() <= 7);
    CHECK(find_issue(issues, "/tiles", "more invalid tiles") != nullptr);

    issues = check_tilemap(map_with(1, 1, "\"##\""));
    REQUIRE(issues.size() == 1);
    CHECK(issues[0].message.find("must be an array") != std::string::npos);
}

TEST_CASE("tilemap: solid tiles need width and height; solidTiles and tileSize are checked") {
    auto issues = check_tilemap(map_with(0, 0, "[0,1,0]", "[0]"));
    REQUIRE(issues.size() == 1);
    CHECK(issues[0].error);
    CHECK(issues[0].message.find("do not collide") != std::string::npos);

    issues = check_tilemap(map_with(0, 0, "[0,1,0]"));
    REQUIRE(issues.size() == 1);
    CHECK_FALSE(issues[0].error);

    issues = check_tilemap(map_with(1, 1, "[0]", "[0, \"a\", 1.5]"));
    REQUIRE(issues.size() == 2);
    CHECK(issues[0].pointer == "/solidTiles/1");

    Tilemap tm = map_with(1, 1, "[0]");
    tm.tileSize = {0, 16};
    issues = check_tilemap(tm);
    REQUIRE(issues.size() == 1);
    CHECK(issues[0].pointer == "/tileSize");
}

TEST_CASE("tilemap: the scene loader reports bad tilemap data with file pointers, and the entity still loads") {
    World w;
    Json scene = Json::parse(R"({
      "format": "factoria.scene/1",
      "entities": [
        { "id": "ok", "components": { "Tilemap": { "width": 2, "height": 1, "tiles": [0, 1] } } },
        { "id": "map", "components": { "Tilemap": { "width": 3, "height": 2, "tiles": [0, 1, 0, 1], "solidTiles": [0] } } }
      ] })");
    LoadReport r = load_scene(w, scene, "level.scene.json");
    REQUIRE(r.messages.size() == 1);
    const LoadMessage& m = r.messages[0];
    CHECK(m.severity == LoadMessage::Severity::Error);
    CHECK(m.pointer == "/entities/1/components/Tilemap/tiles");
    CHECK(m.source == "level.scene.json");
    CHECK(m.message.find("4 entries") != std::string::npos);
    CHECK_FALSE(m.hint.empty());
    CHECK(w.entity_count() == 2);

    // Patching another field of an already inconsistent tilemap is not blocked (checks run on load, not on patch).
    Entity map = w.find_by_id("map");
    REQUIRE(bool(map));
    auto patched = patch_component(w, map, World::type_of<Tilemap>(), Json::parse(R"({"layer": 3})"));
    CHECK(patched.ok());
    CHECK(w.get<Tilemap>(map)->layer == 3);
}

TEST_CASE("tilemap: grid helpers") {
    Tilemap tm;
    tm.tileSize = {32, 16};
    set_tilemap_grid(tm, 3, 2, {0, -1, 2, 3, 4, 5});
    CHECK(tm.width == 3);
    CHECK(tm.height == 2);
    CHECK(tm.tiles == Json::parse("[0,-1,2,3,4,5]"));
    CHECK(check_tilemap(tm).empty());

    // Cell (col 2, row 1): centre ((2 + 0.5) * 32, -(1 + 0.5) * 16), row 0 is the top row.
    Vec2 c = tilemap_cell_center(tm, 2, 1);
    CHECK(c.x == doctest::Approx(80.0f));
    CHECK(c.y == doctest::Approx(-24.0f));

    // 128x32 image of 32x32 tiles: 4 columns x 1 row.
    tm.tileSize = {32, 32};
    tm.columns = 4;
    CHECK(tileset_tile_count(tm, 128, 32) == 4);
    tm.columns = 2;
    CHECK(tileset_tile_count(tm, 128, 64) == 4);  // columns * whole tile rows
    tm.columns = 0;
    CHECK(tileset_tile_count(tm, 128, 64) == 8);  // columns derived from the image width
    CHECK(tileset_tile_count(tm, 0, 64) == 0);
    CHECK(tileset_tile_count(tm, 128, 16) == 0);  // shorter than one tile row
}
