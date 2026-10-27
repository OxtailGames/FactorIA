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
    h.file("scenes/main.scene.json", Json::object({{"format", "factoria.scene/1"}, {"entities", Json::array({
        Json::parse(R"({"id":"ortho","components":{"Transform":{"position":[100,50,0]},
            "Tilemap":{"tileSize":[16,16],"width":4,"height":3,"tiles":[0,0,0,0, 0,0,0,0, 0,0,0,0]}}})"),
        Json::parse(R"({"id":"iso","components":{"Transform":{"position":[1000,0,0],"scale":[2,2,1]},
            "Tilemap":{"projection":"isometric","tileSize":[100,50],"width":4,"height":3,"tiles":[0,0,0,0, 0,0,0,0, 0,0,0,0]}}})")})}}).dump());
    REQUIRE(h.start());
    CHECK(h.load_scene_now("scenes/main.scene.json").empty());
    h.step_frames(1);
    // Orthogonal: cell (1, 2) spans x [116, 132], y from 50 - 48 = 2 down to... centre (124, 10).
    CHECK(eval_ok(h, "const o = world.find('ortho').tilemap; const c = o.cellToWorld(1, 2); c.x === 124 && c.y === 10").get<bool>());
    CHECK(eval_ok(h, "JSON.stringify(world.find('ortho').tilemap.cellAt({x: 124, y: 10}))") == "{\"col\":1,\"row\":2}");
    CHECK(eval_ok(h, "JSON.stringify(world.find('ortho').tilemap.cellAt([100.5, 49.5]))") == "{\"col\":0,\"row\":0}");
    CHECK(eval_ok(h, "world.find('ortho').tilemap.cellAt([99, 49])") == nullptr);   // left of the map
    CHECK(eval_ok(h, "world.find('ortho').tilemap.cellAt([110, 52])") == nullptr);  // above it
    // Isometric, scaled by 2: cell (c, r) centre = position + 2 * ((c - r) * 50, -(c + r + 1) * 25).
    CHECK(eval_ok(h, "const c = world.find('iso').tilemap.cellToWorld(3, 1); c.x === 1200 && c.y === -250").get<bool>());
    CHECK(eval_ok(h, "world.find('iso').tilemap.cellToWorld(-1, 0).x === 900").get<bool>());  // outside the map: still a position
    CHECK(eval_ok(h, R"(
      const t = world.find('iso').tilemap; let bad = 0;
      for (let r = 0; r < 3; r++) for (let c = 0; c < 4; c++) {
        const p = t.cellToWorld(c, r);
        for (const d of [[0, 0], [60, 0], [-60, 0], [0, 20], [0, -20]]) {
          const hit = t.cellAt({ x: p.x + d[0], y: p.y + d[1] });
          if (!hit || hit.col !== c || hit.row !== r) bad++;
        }
      }
      bad)").get<int>() == 0);
    CHECK(eval_ok(h, "world.find('iso').tilemap.cellAt(world.find('iso').tilemap.cellToWorld(5, 0))") == nullptr);  // right of the map
    auto bad = h.scripts.eval("world.find('iso').tilemap.cellToWorld('a', 1)");
    REQUIRE_FALSE(bad.ok());
    CHECK(bad.error().to_string().find("cellToWorld") != std::string::npos);
}
