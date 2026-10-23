// scene.preload / assets.preload: progress over several frames, a load that reads nothing, errors that teach.
#include <doctest.h>

#include "test_host.h"

using namespace fa;
using namespace fa::test;

namespace {
void write_models_scene(TestHost& h) {
    // Ten "models" (any bytes: the test host draws nothing), a texture and a prefab that points at a fifth model.
    for (const char* m : {"a", "b", "c", "d", "e", "f", "g", "h", "i", "j"}) h.file(std::string("assets/models/") + m + ".glb", std::string("glTF-") + m);
    h.file("assets/hero.png", "not really a png");
    h.file("prefabs/crate.prefab.json", R"({"format":"factoria.prefab/1","entities":[{"id":"crate","components":{
        "Transform":{},"MeshRenderer":{"mesh":"assets/models/e.glb"}}}]})");
    h.file("scenes/level2.scene.json", R"({"format":"factoria.scene/1","entities":[
        {"id":"a","components":{"Transform":{},"MeshRenderer":{"mesh":"assets/models/a.glb"}}},
        {"id":"b","components":{"Transform":{},"MeshRenderer":{"mesh":"assets/models/b.glb"}}},
        {"id":"c","components":{"Transform":{},"MeshRenderer":{"mesh":"assets/models/c.glb"}}},
        {"id":"d","components":{"Transform":{},"MeshRenderer":{"mesh":"assets/models/d.glb"}}},
        {"id":"f","components":{"Transform":{},"MeshRenderer":{"mesh":"assets/models/f.glb"}}},
        {"id":"g","components":{"Transform":{},"MeshRenderer":{"mesh":"assets/models/g.glb"}}},
        {"id":"h","components":{"Transform":{},"MeshRenderer":{"mesh":"assets/models/h.glb"}}},
        {"id":"i","components":{"Transform":{},"MeshRenderer":{"mesh":"assets/models/i.glb"}}},
        {"id":"j","components":{"Transform":{},"MeshRenderer":{"mesh":"assets/models/j.glb"}}},
        {"id":"hero","components":{"Transform":{},"Sprite":{"texture":"assets/hero.png"}}},
        {"id":"spawner","components":{"Transform":{},"Script":{"props":{"prefab":"prefabs/crate.prefab.json"}}}}]})");
    h.file("scenes/main.scene.json", R"({"format":"factoria.scene/1","entities":[]})");
}
}  // namespace

TEST_CASE("preload: scene.preload shows progress over several frames, then scene.load reads nothing") {
    TestHost h("preload_scene");
    write_models_scene(h);
    h.file("tests/p.test.js", R"JS(
import { test, expect, game } from "factoria:test";
import { scene } from "factoria";

test("progress grows frame by frame", () => {
  const job = scene.preload("scenes/level2.scene.json");
  expect(job.progress).toBe(0);
  expect(job.done).toBe(false);
  const seen = [];
  let frames = 0;
  while (!job.done && frames < 50) {
    game.step(1);
    frames++;
    seen.push(job.progress);
  }
  expect(job.done).toBe(true);
  expect(job.progress).toBe(1);
  expect(seen.length).toBeGreaterThan(1);
  for (let i = 1; i < seen.length; i++) expect(seen[i] >= seen[i - 1]).toBe(true);
  expect(seen[0] > 0 && seen[0] < 1).toBe(true);
  // the same on every machine: the scan reads the scene and the prefab (one unit), then one unit per file: 9 models,
  // the texture and the model of the prefab. 12 units, 4 per frame in a test: 3 frames, and "files" counts units.
  expect(frames).toBe(3);
  expect(seen[0]).toBeCloseTo(4 / 12, 5);
  expect(job.files).toBe(12);

  const before = game.fileReads();
  scene.load("scenes/level2.scene.json");
  game.step(1);
  expect(scene.current).toBe("scenes/level2.scene.json");
  expect(game.find("hero")).not.toBeNull();
  expect(game.fileReads()).toBe(before);
});

test("the Promise resolves with the totals", () => {
  const job = scene.preload("scenes/level2.scene.json");
  let result = null;
  job.promise.then((r) => { result = r; });
  game.step(20);
  expect(result).not.toBeNull();
  expect(result.files).toBe(12);
  expect(result.bytes).toBeGreaterThan(100);
});

test("the files stay in memory for the first load after the job and go at the second", () => {
  const job = scene.preload("scenes/level2.scene.json");
  game.step(20);
  const before = game.fileReads();
  scene.load("scenes/level2.scene.json");
  game.step(1);
  expect(game.fileReads()).toBe(before);
  scene.reload(); // the second load finishes the files' time in memory
  game.step(1);
  scene.reload();
  game.step(1);
  expect(game.fileReads()).toBeGreaterThan(before);
});
)JS");
    REQUIRE(h.start());
    TestReport rep = h.scripts.run_tests({"tests/p.test.js"});
    MESSAGE(rep.summary());
    CHECK(rep.ok());
    CHECK(rep.passed == 3);
}

TEST_CASE("preload: assets.preload, gltf buffers, release, and errors that teach") {
    TestHost h("preload_assets");
    h.file("scenes/main.scene.json", R"({"format":"factoria.scene/1","entities":[]})");
    h.file("assets/boss.gltf", R"({"asset":{"version":"2.0"},"buffers":[{"uri":"boss.bin","byteLength":4}],"images":[{"uri":"boss.png"}]})");
    h.file("assets/boss.bin", "1234");
    h.file("assets/boss.png", "png");
    h.file("assets/theme.ogg", "ogg");
    h.file("assets/other.ogg", "ogg2");
    h.file("tests/a.test.js", R"JS(
import { test, expect, game } from "factoria:test";
import { assets, scene } from "factoria";

test("a gltf brings its buffer and texture", () => {
  const job = assets.preload(["assets/boss.gltf", "assets/theme.ogg"]);
  game.step(10);
  expect(job.done).toBe(true);
  expect(job.files).toBe(4);
  expect(job.error).toBe("");
});

test("release gives the unread files back", () => {
  const before = game.fileReads();
  const job = assets.preload(["assets/other.ogg"]);
  game.step(5);
  expect(game.fileReads()).toBe(before + 1);
  job.release();
});

test("mistakes throw with a did-you-mean", () => {
  expect(() => scene.preload("scenes/levl2.scene.json")).toThrow("does not exist");
  expect(() => scene.preload("scenes/main.scene.jsn")).toThrow("main.scene.json");
  expect(() => scene.preload("")).toThrow("expects a scene path");
  expect(() => assets.preload(["assets/them.ogg"])).toThrow("theme.ogg");
  expect(() => assets.preload([])).toThrow("non-empty array");
  expect(() => assets.preload("assets/theme.ogg")).toThrow("non-empty array");
});

)JS");
    REQUIRE(h.start());
    TestReport rep = h.scripts.run_tests({"tests/a.test.js"});
    MESSAGE(rep.summary());
    CHECK(rep.ok());
}

TEST_CASE("preload: a broken scene rejects the Promise and sets error") {
    TestHost h("preload_broken");
    h.file("scenes/main.scene.json", R"({"format":"factoria.scene/1","entities":[]})");
    h.file("scenes/broken.scene.json", "{ not json");
    h.file("tests/b.test.js", R"JS(
import { test, expect, game } from "factoria:test";
import { scene } from "factoria";

test("rejects", () => {
  const job = scene.preload("scenes/broken.scene.json");
  let reason = null;
  job.promise.catch((e) => { reason = e; });
  game.step(3);
  expect(job.done).toBe(true);
  expect(job.progress < 1).toBe(true);
  expect(job.error).toContain("invalid JSON");
  expect(reason).not.toBeNull();
  expect(reason.message).toContain("scene.preload");
});
)JS");
    REQUIRE(h.start());
    TestReport rep = h.scripts.run_tests({"tests/b.test.js"});
    MESSAGE(rep.summary());
    CHECK(rep.ok());
}
