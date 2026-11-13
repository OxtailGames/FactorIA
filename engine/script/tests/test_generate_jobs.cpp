// The tilemap.generate jobs a script started are forgotten with its context; jobs started by anything else are not.
#include <doctest.h>

#include <algorithm>

#include "test_host.h"

using namespace fa;
using namespace fa::test;

TEST_CASE("tilemap.generate jobs: shutting the script system down drops the jobs the script started and no others") {
    TestHost h("generate_jobs");
    int nextJob = 40;
    // A stand-in for the engine's commands: it only numbers the jobs, so the test checks which numbers the script system reports.
    const Json anyObject =
        Json::object({{"type", "object"}, {"properties", Json::object()}, {"additionalProperties", true}});
    h.cmds.add({"tilemap.generate_start", "builtin", "", anyObject, false, "scene"}, [&](const Json&) {
        return Json::object({{"job", ++nextJob}, {"width", 4}, {"height", 4}, {"seed", 1}});
    });
    h.cmds.add({"tilemap.generate_step", "builtin", "", anyObject, false, "scene"}, [](const Json&) {
        return Json::object({{"done", false}, {"progress", 0.0}, {"attempts", 1}, {"work", 0}});
    });
    h.cmds.add({"tilemap.generate_cancel", "builtin", "", anyObject, false, "scene"},
               [](const Json&) { return Json::object({{"cancelled", true}}); });
    // The real commands change memory only ({read, state}): the stand-ins say so, as a game script is granted no more.
    for (const char* name : {"tilemap.generate_start", "tilemap.generate_step", "tilemap.generate_cancel"})
        REQUIRE(h.cmds.declare_capabilities(name, capability_sets::changes_state()));
    h.file("scenes/main.scene.json", R"({"format":"factoria.scene/1","entities":[]})");
    h.file("tests/g.test.js", R"JS(
import { test, expect, game } from "factoria:test";
import { tilemap } from "factoria";

test("starts two generations", () => {
  globalThis.a = tilemap.generate({ sample: ["##", "##"], legend: { "#": 0 }, size: [4, 4], seed: 1 });
  globalThis.b = tilemap.generate({ sample: ["##", "##"], legend: { "#": 0 }, size: [4, 4], seed: 2 });
  game.step(1);
  expect(globalThis.a.done).toBe(false);
});
)JS");
    REQUIRE(h.start());
    // a job the console (or MCP, or the editor) started before: the script system never saw it
    auto console = h.cmds.call("tilemap.generate_start", Json::object());
    REQUIRE(console.ok);
    const int consoleJob = console.result["job"].get<int>();
    TestReport rep = h.scripts.run_tests({"tests/g.test.js"});
    MESSAGE(rep.summary());
    REQUIRE(rep.ok());
    h.scripts.shutdown();
    CHECK(h.droppedJobs.size() == 2);
    CHECK(std::find(h.droppedJobs.begin(), h.droppedJobs.end(), consoleJob) == h.droppedJobs.end());
    CHECK(std::find(h.droppedJobs.begin(), h.droppedJobs.end(), consoleJob + 1) != h.droppedJobs.end());
    CHECK(std::find(h.droppedJobs.begin(), h.droppedJobs.end(), consoleJob + 2) != h.droppedJobs.end());
}
