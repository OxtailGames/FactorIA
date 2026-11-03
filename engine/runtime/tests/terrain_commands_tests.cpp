// tilemap.paint_terrain / retile / terrains / set_terrains: the autotile commands of a Tilemap.
#include <doctest.h>

#include <filesystem>
#include <fstream>

#include "fa/core/fs.h"
#include "fa/runtime/engine.h"
#include "fa/scene/tilemap.h"

using namespace fa;
namespace stdfs = std::filesystem;

namespace {

const char* kProject = R"({
  "format": "factoria.project/1", "name": "Terrain Test", "id": "com.example.terraintest",
  "mainScene": "scenes/main.scene.json",
  "display": { "width": 320, "height": 180, "scaleMode": "pixelPerfect" },
  "physics": { "fixedHz": 60, "pixelsPerMeter": 100 }
})";

const char* kScene = R"({
  "format": "factoria.scene/1",
  "entities": [
    { "id": "cam", "name": "Camera", "components": { "Camera": { "clearColor": "#102030" } } },
    { "id": "map", "name": "Map", "components": { "Tilemap": {
        "tileSize": [16, 16], "width": 6, "height": 4,
        "tiles": [-1,-1,-1,-1,-1,-1, -1,-1,-1,-1,-1,-1, -1,-1,-1,-1,-1,-1, -1,-1,-1,-1,-1,-1],
        "terrains": [ { "name": "grass", "mode": "basic16", "first": 0, "seed": 1 },
                      { "name": "water", "mode": "basic16", "first": 16, "seed": 1 } ] } } },
    { "id": "plain", "name": "Plain", "components": { "Transform": { "position": [0, 0] } } }
  ]
})";

struct Session {
    stdfs::path dir;
    Engine engine;
    Session() {
        dir = fs::make_temp_dir("fa_terrain_test");
        write("factoria.json", kProject);
        write("scenes/main.scene.json", kScene);
        EngineConfig c;
        c.projectDir = dir.generic_string();
        c.headless = true;
        c.hotReload = false;
        std::string err;
        REQUIRE_MESSAGE(engine.init(c, nullptr, &err), err);
    }
    ~Session() {
        engine.shutdown();
        std::error_code ec;
        stdfs::remove_all(dir, ec);
    }
    void write(const std::string& rel, const std::string& text) const {
        stdfs::create_directories((dir / rel).parent_path());
        std::ofstream(dir / rel, std::ios::binary) << text;
    }
    CommandResult call(const std::string& cmd, const Json& args) { return engine.commands().call(cmd, args); }
    int tile(int col, int row) {
        Entity e = engine.world().find("map");
        const Tilemap* tm = engine.world().get<Tilemap>(e);
        return tilemap_tile_at(*tm, tilemap_size(*tm), col, row);
    }
};

std::string error_text(const CommandResult& r) { return r.error.value("message", std::string()) + " | " + r.error.value("hint", std::string()); }
bool contains(const std::string& s, const std::string& n) { return s.find(n) != std::string::npos; }

}  // namespace

TEST_CASE("tilemap.paint_terrain paints a rect, re-tiles the edges and reports the changes") {
    Session s;
    auto r = s.call("tilemap.paint_terrain", Json::parse(R"({"id":"map","terrain":"grass","rect":{"col":1,"row":1,"width":3,"height":2}})"));
    REQUIRE_MESSAGE(r.ok, error_text(r));
    CHECK(r.result["painted"] == 6);
    CHECK(r.result["outside"] == 0);
    CHECK(r.result["changed"].get<int>() >= 6);
    // basic16: slot = N*1 + E*2 + S*4 + W*8
    CHECK(s.tile(1, 1) == 2 + 4);
    CHECK(s.tile(2, 1) == 2 + 4 + 8);
    CHECK(s.tile(3, 2) == 1 + 8);
    CHECK(s.tile(0, 0) == -1);
    // the cells are written in place and physics/navigation see the edits
    Entity e = s.engine.world().find("map");
    CHECK(s.engine.world().get<Tilemap>(e)->version > 0);
}

TEST_CASE("tilemap.paint_terrain with erase empties the cells and re-tiles the neighbours") {
    Session s;
    REQUIRE(s.call("tilemap.paint_terrain", Json::parse(R"({"id":"map","terrain":"grass","cells":[[1,1],[2,1]]})")).ok);
    CHECK(s.tile(1, 1) == 2);
    auto r = s.call("tilemap.paint_terrain", Json::parse(R"({"id":"map","terrain":"grass","cells":[{"col":2,"row":1}],"erase":true})"));
    REQUIRE_MESSAGE(r.ok, error_text(r));
    CHECK(s.tile(2, 1) == -1);
    CHECK(s.tile(1, 1) == 0);
}

TEST_CASE("tilemap.paint_terrain skips cells outside the map and refuses what it cannot do") {
    Session s;
    auto r = s.call("tilemap.paint_terrain", Json::parse(R"({"id":"map","terrain":"water","cells":[[0,0],[9,9]]})"));
    REQUIRE(r.ok);
    CHECK(r.result["painted"] == 1);
    CHECK(r.result["outside"] == 1);
    CHECK(s.tile(0, 0) == 16);

    auto unknown = s.call("tilemap.paint_terrain", Json::parse(R"({"id":"map","terrain":"watr","cells":[[0,0]]})"));
    REQUIRE_FALSE(unknown.ok);
    CHECK(contains(error_text(unknown), "Unknown terrain 'watr'"));
    CHECK(contains(error_text(unknown), "water"));

    auto noCells = s.call("tilemap.paint_terrain", Json::parse(R"({"id":"map","terrain":"water"})"));
    REQUIRE_FALSE(noCells.ok);
    CHECK(contains(error_text(noCells), "cells"));

    auto badCell = s.call("tilemap.paint_terrain", Json::parse(R"({"id":"map","terrain":"water","cells":[[1,"x"]]})"));
    REQUIRE_FALSE(badCell.ok);
    CHECK(contains(error_text(badCell), "cells[0]"));

    auto noMap = s.call("tilemap.paint_terrain", Json::parse(R"({"id":"plain","terrain":"water","cells":[[1,1]]})"));
    REQUIRE_FALSE(noMap.ok);
    CHECK(contains(error_text(noMap), "no Tilemap"));
}

TEST_CASE("tilemap.set_terrains checks the rules first, reads a rules file, and retiles on request") {
    Session s;
    auto bad = s.call("tilemap.set_terrains", Json::parse(R"({"id":"map","terrains":[{"name":"x","mode":"blob99","first":0}]})"));
    REQUIRE_FALSE(bad.ok);
    CHECK(contains(error_text(bad), "/terrains/0/mode"));
    CHECK(contains(error_text(bad), "blob47"));
    // nothing changed
    auto info = s.call("tilemap.terrains", Json::parse(R"({"id":"map"})"));
    REQUIRE(info.ok);
    CHECK(info.result["valid"] == true);
    CHECK(info.result["terrains"].size() == 2);

    s.write("assets/ground.terrains.json", R"({"format":"factoria.terrains/1","terrains":[{"name":"sand","mode":"basic16","first":40}]})");
    REQUIRE(s.call("tilemap.paint_terrain", Json::parse(R"({"id":"map","terrain":"grass","cells":[[1,1],[2,1]]})")).ok);
    auto set = s.call("tilemap.set_terrains", Json::parse(R"({"id":"map","path":"assets/ground.terrains.json"})"));
    REQUIRE_MESSAGE(set.ok, error_text(set));
    CHECK(set.result["terrains"] == Json::parse(R"(["sand"])"));
    auto none = s.call("tilemap.paint_terrain", Json::parse(R"({"id":"map","terrain":"grass","cells":[[0,0]]})"));
    CHECK_FALSE(none.ok);
    REQUIRE(s.call("tilemap.paint_terrain", Json::parse(R"({"id":"map","terrain":"sand","cells":[[4,2]]})")).ok);
    CHECK(s.tile(4, 2) == 40);

    auto missing = s.call("tilemap.set_terrains", Json::parse(R"({"id":"map","path":"assets/none.terrains.json"})"));
    REQUIRE_FALSE(missing.ok);
    CHECK(contains(error_text(missing), "none.terrains.json"));
    auto both = s.call("tilemap.set_terrains", Json::parse(R"({"id":"map"})"));
    REQUIRE_FALSE(both.ok);
}

TEST_CASE("tilemap.retile and tilemap.terrains") {
    Session s;
    for (int c = 0; c < 3; ++c) s.call("tilemap.set_tile", Json{{"id", "map"}, {"col", c}, {"row", 0}, {"tile", 0}});
    auto r = s.call("tilemap.retile", Json::parse(R"({"id":"map"})"));
    REQUIRE_MESSAGE(r.ok, error_text(r));
    CHECK(r.result["changed"] == 3);
    CHECK(s.tile(0, 0) == 2);
    CHECK(s.tile(1, 0) == 2 + 8);
    CHECK(s.tile(2, 0) == 8);
    auto info = s.call("tilemap.terrains", Json::parse(R"({"id":"map"})"));
    REQUIRE(info.ok);
    CHECK(info.result["terrains"][0]["name"] == "grass");
    CHECK(info.result["terrains"][0]["cells"] == 3);
    CHECK(info.result["terrains"][0]["slots"].size() == 16);
    CHECK(info.result["terrains"][0]["slots"][5]["mask"] == 17);  // slot 5 = N + S
}
