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
    // Rows form: the rows define the size, so width/height are not needed (even with solid tiles).
    CHECK(check_tilemap(map_with(0, 0, "[[-1,0,1],[2,2,2]]", "[0,2]")).empty());
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

TEST_CASE("tilemap: a flat array without width is read as one row (warning); solidTiles and tileSize are checked") {
    // Collision and drawing both read it as ONE row of 3 tiles, so it is a warning, never an error.
    auto issues = check_tilemap(map_with(0, 0, "[0,1,0]", "[0]"));
    REQUIRE(issues.size() == 1);
    CHECK_FALSE(issues[0].error);
    CHECK(issues[0].pointer == "/width");
    CHECK(issues[0].message.find("3 x 1") != std::string::npos);
    CHECK(issues[0].hint.find("array of rows") != std::string::npos);

    // Width alone is enough when the list fills whole rows; a ragged last row is a warning.
    CHECK(check_tilemap(map_with(3, 0, "[0,1,0, 1,1,1]")).empty());
    issues = check_tilemap(map_with(3, 0, "[0,1,0, 1]"));
    REQUIRE(issues.size() == 1);
    CHECK_FALSE(issues[0].error);
    CHECK(issues[0].pointer == "/height");

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

TEST_CASE("tilemap: tilemap_grid is the one definition of the map size, for both forms") {
    // Rows form: size from the rows, width/height fields not needed.
    TilemapGrid g = tilemap_grid(map_with(0, 0, "[[-1,0,1],[2,2,2]]"));
    CHECK(g.width == 3);
    CHECK(g.height == 2);
    CHECK(g.tiles == std::vector<int>{-1, 0, 1, 2, 2, 2});
    CHECK(g.at(2, 0) == 1);
    CHECK(g.at(0, 1) == 2);
    CHECK(g.at(3, 0) == -1);   // outside the map
    CHECK(g.at(0, -1) == -1);
    CHECK_FALSE(g.empty());

    // Rows form ignores width/height (check_tilemap reports a disagreement); short rows are padded, junk is -1.
    g = tilemap_grid(map_with(9, 9, "[[0,1,2],[3],\"x\"]"));
    CHECK(g.width == 3);
    CHECK(g.height == 3);
    CHECK(g.tiles == std::vector<int>{0, 1, 2, 3, -1, -1, -1, -1, -1});

    // Flat form: width/height fields.
    g = tilemap_grid(map_with(3, 2, "[-1,0,1, 2,2,2]"));
    CHECK(g.width == 3);
    CHECK(g.height == 2);
    CHECK(g.tiles == std::vector<int>{-1, 0, 1, 2, 2, 2});
    // ... too few entries are -1, extra ones are ignored.
    CHECK(tilemap_grid(map_with(3, 2, "[1,1,1, 2]")).tiles == std::vector<int>{1, 1, 1, 2, -1, -1});
    CHECK(tilemap_grid(map_with(2, 1, "[1,1,1,1]")).tiles == std::vector<int>{1, 1});
    // ... a missing width is ONE row (or tiles / height columns), a missing height is the rows the list needs.
    g = tilemap_grid(map_with(0, 0, "[0,1,0]"));
    CHECK((g.width == 3 && g.height == 1));
    g = tilemap_grid(map_with(0, 2, "[0,1,0, 1,1,1]"));
    CHECK((g.width == 3 && g.height == 2));
    g = tilemap_grid(map_with(3, 0, "[0,1,0, 1,1]"));
    CHECK((g.width == 3 && g.height == 2));
    CHECK(g.tiles == std::vector<int>{0, 1, 0, 1, 1, -1});

    // Anything that is not a tile index is empty: strings, negatives other than -1, null.
    CHECK(tilemap_grid(map_with(4, 1, "[\"a\", -5, null, 7]")).tiles == std::vector<int>{-1, -1, -1, 7});

    // No tiles, no grid; the size alone agrees with the grid.
    CHECK(tilemap_grid(Tilemap{}).empty());
    CHECK(tilemap_grid(map_with(3, 2, "[]")).empty());
    CHECK(tilemap_size(map_with(0, 0, "[[0,1],[2,3],[4,5]]")).height == 3);
    CHECK(tilemap_size(map_with(0, 0, "[[0,1],[2,3],[4,5]]")).width == 2);
    CHECK(tilemap_size(map_with(0, 0, "[0,1,2,3,4]")).width == 5);
}

TEST_CASE("tilemap: columns 0 (the default) is derived from the tileset image") {
    Tilemap tm;
    CHECK(tm.columns == 0);
    tm.tileSize = {32, 32};
    CHECK(tileset_columns(tm, 128) == 4);  // 128 / 32
    CHECK(tileset_columns(tm, 16) == 1);   // narrower than one tile: at least 1
    CHECK(tileset_columns(tm, 0) == 0);    // unknown image
    tm.columns = 3;
    CHECK(tileset_columns(tm, 128) == 3);  // an explicit value wins
    CHECK(tileset_columns(tm, 0) == 3);

    // A scene that does not mention columns loads with 0; an explicit 0 is accepted, an explicit 1 stays 1.
    World w;
    Json scene = Json::parse(R"({
      "format": "factoria.scene/1",
      "entities": [
        { "id": "auto", "components": { "Tilemap": { "tileSize": [32, 32] } } },
        { "id": "zero", "components": { "Tilemap": { "columns": 0 } } },
        { "id": "one", "components": { "Tilemap": { "columns": 1 } } }
      ] })");
    LoadReport r = load_scene(w, scene, "level.scene.json");
    CHECK(r.messages.empty());
    CHECK(w.get<Tilemap>(w.find_by_id("auto"))->columns == 0);
    CHECK(w.get<Tilemap>(w.find_by_id("zero"))->columns == 0);
    CHECK(w.get<Tilemap>(w.find_by_id("one"))->columns == 1);
}
