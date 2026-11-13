// entity.tilemap.cellAt / cellToWorld for orthogonal and isometric maps (M31.25).
#include <doctest.h>

#include "test_host.h"

using namespace fa;
using namespace fa::test;

namespace {
Json eval_ok(TestHost& h, const char* code) {
    auto r = h.scripts.eval(code);
    REQUIRE_MESSAGE(r.ok(), (r.ok() ? "" : r.error().to_string()));
    return r.value();
}
}  // namespace

TEST_CASE("tilemap.cellAt and cellToWorld: both projections, the entity's transform, and cells outside the map") {
    TestHost h("tilemap_cells");
    h.file(
        "scenes/main.scene.json",
        Json::object(
            {{"format", "factoria.scene/1"},
             {"entities",
              Json::array({Json::parse(R"({"id":"ortho","components":{"Transform":{"position":[100,50,0]},
            "Tilemap":{"tileSize":[16,16],"width":4,"height":3,"tiles":[0,0,0,0, 0,0,0,0, 0,0,0,0]}}})"),
                           Json::parse(R"({"id":"iso","components":{"Transform":{"position":[1000,0,0],"scale":[2,2,1]},
            "Tilemap":{"projection":"isometric","tileSize":[100,50],"width":4,"height":3,"tiles":[0,0,0,0, 0,0,0,0, 0,0,0,0]}}})")})}})
            .dump());
    REQUIRE(h.start());
    CHECK(h.load_scene_now("scenes/main.scene.json").empty());
    h.step_frames(1);
    // Orthogonal: cell (1, 2) spans x [116, 132], y from 50 - 48 = 2 down to... centre (124, 10).
    CHECK(eval_ok(h, "const o = world.find('ortho').tilemap; const c = o.cellToWorld(1, 2); c.x === 124 && c.y === 10")
              .get<bool>());
    CHECK(eval_ok(h, "JSON.stringify(world.find('ortho').tilemap.cellAt({x: 124, y: 10}))") == "{\"col\":1,\"row\":2}");
    CHECK(eval_ok(h, "JSON.stringify(world.find('ortho').tilemap.cellAt([100.5, 49.5]))") == "{\"col\":0,\"row\":0}");
    CHECK(eval_ok(h, "world.find('ortho').tilemap.cellAt([99, 49])") == nullptr);   // left of the map
    CHECK(eval_ok(h, "world.find('ortho').tilemap.cellAt([110, 52])") == nullptr);  // above it
    // Isometric, scaled by 2: cell (c, r) centre = position + 2 * ((c - r) * 50, -(c + r + 1) * 25).
    CHECK(
        eval_ok(h, "const c = world.find('iso').tilemap.cellToWorld(3, 1); c.x === 1200 && c.y === -250").get<bool>());
    CHECK(eval_ok(h, "world.find('iso').tilemap.cellToWorld(-1, 0).x === 900")
              .get<bool>());  // outside the map: still a position
    CHECK(eval_ok(h, R"(
      const t = world.find('iso').tilemap; let bad = 0;
      for (let r = 0; r < 3; r++) for (let c = 0; c < 4; c++) {
        const p = t.cellToWorld(c, r);
        for (const d of [[0, 0], [60, 0], [-60, 0], [0, 20], [0, -20]]) {
          const hit = t.cellAt({ x: p.x + d[0], y: p.y + d[1] });
          if (!hit || hit.col !== c || hit.row !== r) bad++;
        }
      }
      bad)")
              .get<int>() == 0);
    CHECK(eval_ok(h, "world.find('iso').tilemap.cellAt(world.find('iso').tilemap.cellToWorld(5, 0))") ==
          nullptr);  // right of the map
    auto bad = h.scripts.eval("world.find('iso').tilemap.cellToWorld('a', 1)");
    REQUIRE_FALSE(bad.ok());
    CHECK(bad.error().to_string().find("cellToWorld") != std::string::npos);
}

TEST_CASE("tilemap.paintTerrain / eraseTerrain / retile / terrainAt: autotile from scripts") {
    TestHost h("tilemap_terrain");
    h.file(
        "scenes/main.scene.json",
        Json::object({{"format", "factoria.scene/1"},
                      {"entities", Json::array({Json::parse(
                                       R"({"id":"map","components":{"Tilemap":{"tileSize":[16,16],"width":4,"height":3,
            "tiles":[-1,-1,-1,-1, -1,-1,-1,-1, -1,-1,-1,-1],
            "terrains":[{"name":"grass","mode":"basic16","first":0}]}}})")})}})
            .dump());
    REQUIRE(h.start());
    CHECK(h.load_scene_now("scenes/main.scene.json").empty());
    h.step_frames(1);
    // basic16: slot = N*1 + E*2 + S*4 + W*8
    CHECK(eval_ok(h, R"(
      const t = world.find('map').tilemap;
      const r = t.paintTerrain('grass', [[0, 0], {col: 1, row: 0}]);
      JSON.stringify([r.painted, r.outside, t.getTile(0, 0), t.getTile(1, 0), t.terrainAt(0, 0), t.terrainAt(2, 2)]))") ==
          "[2,0,2,8,\"grass\",null]");
    CHECK(eval_ok(h, R"(
      const t = world.find('map').tilemap;
      const r = t.eraseTerrain('grass', [[1, 0]]);
      JSON.stringify([r.painted, t.getTile(1, 0), t.getTile(0, 0), r.changes.length]))") == "[1,-1,0,2]");
    // a tile written by hand is re-tiled by retile()
    CHECK(eval_ok(h, R"(
      const t = world.find('map').tilemap;
      t.setTile(1, 0, 0);
      const r = t.retile();
      JSON.stringify([r.changed, t.getTile(0, 0), t.getTile(1, 0)]))") == "[2,2,8]");
    // the cells outside the map are counted, not written
    CHECK(eval_ok(h, "world.find('map').tilemap.paintTerrain('grass', [[9, 9]]).outside").get<int>() == 1);

    auto unknown = h.scripts.eval("world.find('map').tilemap.paintTerrain('gras', [[0, 0]])");
    REQUIRE_FALSE(unknown.ok());
    CHECK(unknown.error().to_string().find("Unknown terrain 'gras'") != std::string::npos);
    CHECK(unknown.error().to_string().find("grass") != std::string::npos);
    auto badCells = h.scripts.eval("world.find('map').tilemap.paintTerrain('grass', [[0, 'x']])");
    REQUIRE_FALSE(badCells.ok());
    CHECK(badCells.error().to_string().find("cells[0]") != std::string::npos);
    auto badName = h.scripts.eval("world.find('map').tilemap.paintTerrain(3, [[0, 0]])");
    REQUIRE_FALSE(badName.ok());
    CHECK(badName.error().to_string().find("paintTerrain") != std::string::npos);
}
