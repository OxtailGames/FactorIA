// nav.findTilePath, nav.tileVersion and bt from scripts.
#include <doctest.h>

#include <chrono>
#include <cstdio>

#include "test_host.h"

using namespace fa;
using namespace fa::test;

namespace {
Json eval_ok(TestHost& h, const char* code) {
    auto r = h.scripts.eval(code);
    REQUIRE_MESSAGE(r.ok(), (r.ok() ? "" : r.error().to_string()));
    return r.value();
}
std::string eval_err(TestHost& h, const char* code) {
    auto r = h.scripts.eval(code);
    REQUIRE_FALSE(r.ok());
    return r.error().to_string();
}
}  // namespace

TEST_CASE("nav.findTilePath: a Tilemap entity, a grid, version and errors") {
    TestHost h("nav_tiles");
    h.file("scenes/main.scene.json", Json::object({{"format", "factoria.scene/1"}, {"entities", Json::array({
        Json::parse(R"({"id":"ground","components":{"Transform":{"position":[0,0,0]},
            "Tilemap":{"tileSize":[16,16],"width":4,"height":3,"solidTiles":[1],"tiles":[0,0,0,0, 0,1,1,0, 0,0,0,0]}}})")})}}).dump());
    REQUIRE(h.start());
    CHECK(h.load_scene_now("scenes/main.scene.json").empty());
    h.step_frames(2);
    CHECK(eval_ok(h, "nav.findTilePath(world.find('ground'), {col:0,row:1}, [3,1]).cells.length").get<int>() == 6);
    CHECK(eval_ok(h, "nav.findTilePath('ground', [0,1], [3,1]).points[0].x").get<double>() == doctest::Approx(8.0));
    CHECK(eval_ok(h, "nav.findTilePath('ground', [0,1], [3,1], { costs: { 1: 1.5 } }).cells.length").get<int>() == 4);
    // Infinity blocks, closest still answers
    CHECK(eval_ok(h, "nav.findTilePath('ground', [0,1], [3,1], { costs: { 0: Infinity } }).reason") == "goal_blocked");
    CHECK(eval_ok(h, "nav.findTilePath('ground', [0,1], [3,1], { costs: { 0: Infinity }, closest: true }).complete") == false);
    CHECK(eval_ok(h, "nav.findTilePath('ground', [0,0], [3,0], { diagonals: true }).cells.length").get<int>() == 4);
    // a grid: Infinity, -1 and null block
    CHECK(eval_ok(h, "nav.findTilePath({ width: 3, height: 3, cost: [1,Infinity,1, 1,-1,1, 1,1,1] }, [0,0], [2,0]).cost").get<int>() == 6);
    // the version counts setTile writes
    CHECK(eval_ok(h, "const v = nav.tileVersion('ground'); world.find('ground').tilemap.setTile(0, 0, 1); nav.tileVersion('ground') - v").get<int>() == 1);
    CHECK(eval_ok(h, "nav.findTilePath('ground', [3,0], [3,0]).cells.length").get<int>() == 1);
    // writes that replace `tiles` as a whole count too: no change = same number, any change = a higher one
    // (scene.set_component and the editor write the same field; runtime tests cover them)
    CHECK(eval_ok(h, "nav.tileVersion('ground') - nav.tileVersion('ground')").get<int>() == 0);
    CHECK(eval_ok(h, "const v = nav.tileVersion('ground'); world.find('ground').get('Tilemap').tiles = [0,0,0,0, 0,0,0,0, 0,0,0,0]; nav.tileVersion('ground') > v").get<bool>());
    CHECK(eval_ok(h, "const v = nav.tileVersion('ground'); world.find('ground').get('Tilemap').tiles = [0,0,0,0, 0,0,0,0, 0,0,0,0]; nav.tileVersion('ground') === v").get<bool>());
    // a setTile followed by a whole replacement before the next look still reads as changed
    CHECK(eval_ok(h, "const v = nav.tileVersion('ground'); const t = world.find('ground'); t.tilemap.setTile(1, 1, 3); t.get('Tilemap').tiles = [0,0,0,0, 0,0,0,0, 0,0,0,0]; nav.tileVersion('ground') > v").get<bool>());
    // errors teach
    CHECK(eval_err(h, "nav.findTilePath('ground', 'a', [1,1])").find("col, row") != std::string::npos);
    CHECK(eval_err(h, "nav.findTilePath(42, [0,0], [1,1])").find("grid") != std::string::npos);
    CHECK(eval_err(h, "nav.findTilePath('nothing', [0,0], [1,1])").find("nothing") != std::string::npos);
    CHECK(eval_ok(h, "nav.findTilePath('ground', [0,0], [9,9]).reason") == "goal_off_map");
    // a wrong option type is a script error, not a crash
    CHECK(eval_err(h, "nav.findTilePath('ground', [0,0], [1,0], { diagonals: 'yes' })").find("true or false") != std::string::npos);
    CHECK(eval_err(h, "nav.findTilePath('ground', [0,0], [1,0], { maxNodes: 'lots' })").find("maxNodes") != std::string::npos);
}

TEST_CASE("nav.createGrid and nav.flowField: a kept grid, setCost, flow fields and errors") {
    TestHost h("nav_grid_handles");
    h.file("scenes/main.scene.json", Json::object({{"format", "factoria.scene/1"}, {"entities", Json::array()}}).dump());
    REQUIRE(h.start());
    CHECK(h.load_scene_now("scenes/main.scene.json").empty());
    // the grid gives the paths of the array form
    CHECK(eval_ok(h, R"(
      const cost = [1,1,1,1,1, 1,Infinity,Infinity,Infinity,1, 1,1,1,1,1];
      globalThis.g = nav.createGrid({ width: 5, height: 3, cost, origin: [10, 20], cellSize: 2 });
      const a = nav.findTilePath({ width: 5, height: 3, cost, origin: [10, 20], cellSize: 2 }, [2, 0], [2, 2]);
      const b = nav.findTilePath(g, [2, 0], [2, 2]);
      JSON.stringify(a.cells) === JSON.stringify(b.cells) && a.cost === b.cost && b.points[0].x === 15 && b.points[0].y === 19 && b.found
    )").get<bool>());
    // setCost: the next path sees it; the version counts changes
    CHECK(eval_ok(h, "globalThis.v = g.version; g.setCost(2, 1, 1); g.setCost(2, 1, 1); [g.version - v, nav.findTilePath(g, [2, 0], [2, 2]).cost, g.getCost(1, 1), g.getCost(2, 1)]") == Json::parse("[1,2,\"Infinity\",1]"));
    CHECK(eval_ok(h, "g.setCost(2, 1, null); String(g.getCost(2, 1))") == "Infinity");  // null blocks too
    CHECK(eval_ok(h, "g.findPath([2, 0], [2, 2]).cost").get<int>() == 6);
    // flow field: distances, steps, path, goals, rebuild
    CHECK(eval_ok(h, R"(
      globalThis.f = nav.flowField(g, [{ col: 2, row: 2 }, [4, 0]]);
      const s0 = f.stepToward(0, 0);
      [f.distance(2, 2), f.distance(0, 0), s0.col, s0.row, f.stepToward(2, 2), f.pathFrom(0, 0).length, f.rebuilds]
    )") == Json::parse("[0,4,1,0,null,5,1]"));
    CHECK(eval_ok(h, "g.setCost(2, 1, 1); [f.distance(2, 0), f.rebuilds]") == Json::parse("[2,2]"));
    CHECK(eval_ok(h, "f.stepToward({ col: 2, row: 0 }).col").get<int>() == 3);
    // a field with no reachable goal answers Infinity and null
    CHECK(eval_ok(h, "const w = nav.createGrid({ width: 3, height: 1, cost: [1, Infinity, 1] }); const wf = nav.flowField(w, [2, 0]); [wf.distance(0, 0) === Infinity, wf.stepToward(0, 0), wf.pathFrom(0, 0).length]") == Json::parse("[true,null,0]"));
    CHECK(eval_ok(h, "nav.createGrid({ width: 2, height: 2 }).getCost(1, 1)").get<int>() == 1);
    // errors teach
    CHECK(eval_err(h, "nav.createGrid({ width: 2, height: 2, cost: [1] })").find("width * height = 4") != std::string::npos);
    CHECK(eval_err(h, "nav.createGrid({ width: 0, height: 2 })").find("width and height") != std::string::npos);
    CHECK(eval_err(h, "g.setCost(9, 9, 1)").find("outside the 5 x 3 grid") != std::string::npos);
    CHECK(eval_err(h, "g.setCost(1, 1, 'x')").find("cost must be a number") != std::string::npos);
    CHECK(eval_err(h, "nav.flowField(g, [9, 9])").find("outside") != std::string::npos);
    CHECK(eval_err(h, "nav.flowField(g, [])").find("at least one goal") != std::string::npos);
    CHECK(eval_err(h, "nav.flowField({ width: 2, height: 2, cost: [1,1,1,1] }, [0, 0])").find("nav.createGrid") != std::string::npos);
    CHECK(eval_err(h, "f.distance('a', 1)").find("col, row") != std::string::npos);
    CHECK(eval_ok(h, "nav.findTilePath(g, [0,0], [9,9]).reason") == "goal_off_map");
    CHECK(eval_err(h, "nav.findTilePath(g, [0,0], [1,0], { diagonals: 'yes' })").find("true or false") != std::string::npos);
}

// 600 walkers on a 60 x 60 map for 75 ticks, each asking for its next step toward one of 6 buildings every tick. The array
// form converts and sweeps the whole map on every call; the kept grid does not; the flow field answers in O(1) after one
// search per goal. The numbers are printed so a later change can see where they stand.
TEST_CASE("nav benchmark: 600 walkers on a 60x60 grid, array form vs kept grid vs flow field") {
    TestHost h("nav_grid_bench");
    h.file("scenes/main.scene.json", Json::object({{"format", "factoria.scene/1"}, {"entities", Json::array()}}).dump());
    REQUIRE(h.start());
    CHECK(h.load_scene_now("scenes/main.scene.json").empty());
    eval_ok(h, R"(
      globalThis.W = 60; globalThis.H = 60;
      globalThis.cost = new Array(W * H);
      for (let r = 0; r < H; r++) for (let c = 0; c < W; c++) cost[r * W + c] = (r % 6 === 3 && c % 20 !== 7) ? Infinity : 1;
      globalThis.goals = [[5, 5], [54, 5], [30, 28], [5, 52], [54, 52], [30, 40]];
      let s = 777;
      const rnd = () => { s = (s * 1103515245 + 12345) & 0x7fffffff; return s >> 8; };
      globalThis.start = [];
      while (start.length < 600) { const i = rnd() % (W * H); if (cost[i] !== Infinity) start.push([i % W, (i - i % W) / W, rnd() % goals.length]); }
      // begin(mode) sets the walkers up; tick(n) runs n ticks (the watchdog limits one eval to 5 seconds)
      globalThis.begin = (mode) => {
        globalThis.mode = mode;
        globalThis.walkers = start.map((w) => ({ c: w[0], r: w[1], g: w[2] }));
        globalThis.grid = mode === "array" ? { width: W, height: H, cost } : nav.createGrid({ width: W, height: H, cost });
        globalThis.fields = mode === "flow" ? goals.map((g) => nav.flowField(grid, g)) : null;
        globalThis.moved = 0;
      };
      globalThis.tick = (n) => {
        for (let t = 0; t < n; t++)
          for (const w of walkers) {
            let nx = null;
            if (fields) nx = fields[w.g].stepToward(w.c, w.r);
            else { const p = nav.findTilePath(grid, [w.c, w.r], goals[w.g]); if (p.found && p.cells.length > 1) nx = p.cells[1]; }
            if (nx) { w.c = nx.col; w.r = nx.row; moved++; }
          }
      };
      globalThis.result = () => [moved, walkers.reduce((a, w) => a + w.c * 100 + w.r, 0)];
    )");
    // Runs `ticks` ticks one eval at a time (the watchdog stops an eval after 5 seconds) and returns {ms, result}.
    auto time_it = [&](const char* mode, int ticks) {
        eval_ok(h, (std::string("begin('") + mode + "')").c_str());
        double ms = 0;
        for (int t = 0; t < ticks; ++t) {
            const auto t0 = std::chrono::steady_clock::now();
            eval_ok(h, "tick(1)");
            ms += std::chrono::duration<double, std::milli>(std::chrono::steady_clock::now() - t0).count();
        }
        return std::make_pair(ms, eval_ok(h, "result()"));
    };
    // The array form costs seconds per tick in a Debug build, so it runs 3 ticks and is scaled to 75 (every tick asks the same
    // 600 questions); the other two run all 75.
    constexpr int kSample = 3;
    const auto arraySample = time_it("array", kSample);
    const auto gridSample = time_it("grid", kSample);
    const auto grid = time_it("grid", 75);
    const auto flow = time_it("flow", 75);
    const double arrayMs = arraySample.first * 75.0 / kSample;
    std::printf("nav benchmark (600 walkers, 60x60, 75 ticks, Debug build): array form %.0f ms (%d ticks measured, scaled), "
                "kept grid %.0f ms, flow field %.0f ms\n", arrayMs, kSample, grid.first, flow.first);
    // The array form and the kept grid take the very same steps. The flow field takes shortest steps too, but may break a tie
    // another way, so only its step count is compared.
    CHECK(arraySample.second == gridSample.second);
    CHECK(flow.second[0] == grid.second[0]);
    CHECK(grid.first < arrayMs * 0.8);
    CHECK(flow.first < arrayMs * 0.1);
}

TEST_CASE("bt: every node type from factoria") {
    TestHost h("bt_nodes");
    h.file("scenes/main.scene.json", Json::object({{"format", "factoria.scene/1"}, {"entities", Json::array()}}).dump());
    REQUIRE(h.start());
    CHECK(h.load_scene_now("scenes/main.scene.json").empty());
    const char* code = R"(
      const { SUCCESS, FAILURE, RUNNING, Tree, sequence, selector, condition, action, wait, cooldown, inverter, succeeder } = bt;
      const ok = action(() => SUCCESS), no = action(() => FAILURE), busy = action(() => RUNNING);
      const out = {};
      out.cond = [new Tree(condition((b) => b.x), { x: 0 }).tick(0.1), new Tree(condition((b) => b.x), { x: 1 }).tick(0.1)];
      out.seq = [new Tree(sequence(ok, ok)).tick(0.1), new Tree(sequence(ok, no, ok)).tick(0.1), new Tree(sequence(ok, busy)).tick(0.1)];
      out.sel = [new Tree(selector(no, ok)).tick(0.1), new Tree(selector(no, no)).tick(0.1), new Tree(selector(no, busy, ok)).tick(0.1)];
      const w = new Tree(wait(0.25)); out.wait = [w.tick(0.1), w.tick(0.1), w.tick(0.1)];
      let runs = 0; const c = new Tree(cooldown(1, action(() => { runs++; return SUCCESS; })));
      out.cool = [c.tick(0.1), c.tick(0.4), c.tick(0.4), c.tick(0.4)]; out.runs = runs;
      out.inv = [new Tree(inverter(ok)).tick(0), new Tree(inverter(no)).tick(0), new Tree(inverter(busy)).tick(0)];
      out.suc = [new Tree(succeeder(no)).tick(0), new Tree(succeeder(busy)).tick(0)];
      const log = []; const t = new Tree(selector(sequence(condition((b) => b.go), action(() => RUNNING)),
        action(() => RUNNING, { onEnter: () => log.push("in"), onExit: (b, s) => log.push(s) })), { go: false });
      t.tick(0.1); t.blackboard.go = true; t.tick(0.1); out.log = log;
      out
    )";
    const Json o = eval_ok(h, code);
    CHECK(o["cond"] == Json::parse(R"(["failure","success"])"));
    CHECK(o["seq"] == Json::parse(R"(["success","failure","running"])"));
    CHECK(o["sel"] == Json::parse(R"(["success","failure","running"])"));
    CHECK(o["wait"] == Json::parse(R"(["running","running","success"])"));
    CHECK(o["cool"] == Json::parse(R"(["success","failure","failure","success"])"));
    CHECK(o["runs"] == 2);
    CHECK(o["inv"] == Json::parse(R"(["failure","success","running"])"));
    CHECK(o["suc"] == Json::parse(R"(["success","running"])"));
    CHECK(o["log"] == Json::parse(R"(["in","aborted"])"));
    CHECK(eval_err(h, "new bt.Tree(bt.action(() => 5)).tick(0.1)").find("SUCCESS") != std::string::npos);
    CHECK(eval_err(h, "bt.sequence(1)").find("not a node") != std::string::npos);
}

TEST_CASE("bt: parallel and repeat") {
    TestHost h("bt_parallel_repeat");
    h.file("scenes/main.scene.json", Json::object({{"format", "factoria.scene/1"}, {"entities", Json::array()}}).dump());
    REQUIRE(h.start());
    CHECK(h.load_scene_now("scenes/main.scene.json").empty());
    const char* code = R"(
      const { SUCCESS, FAILURE, RUNNING, Tree, sequence, parallel, repeat, action, wait } = bt;
      const ok = action(() => SUCCESS), no = action(() => FAILURE), busy = action(() => RUNNING);
      const out = {};
      out.all = [new Tree(parallel(ok, ok)).tick(0.1), new Tree(parallel(ok, busy)).tick(0.1), new Tree(parallel(busy, no)).tick(0.1), new Tree(parallel()).tick(0.1)];
      out.any = [new Tree(parallel({ succeed: "any" }, busy, ok)).tick(0.1), new Tree(parallel({ succeed: "any" }, busy, busy)).tick(0.1),
                 new Tree(parallel({ succeed: "any" }, busy, no)).tick(0.1), new Tree(parallel({ succeed: "any" })).tick(0.1)];
      // all: waits of 0.1 and 0.3 finish on different ticks; the node succeeds when both did, and the first is not restarted
      const p = new Tree(parallel(wait(0.1), wait(0.25))); out.waits = [p.tick(0.1), p.tick(0.1), p.tick(0.1)];
      // a running child is aborted when the node finishes, and starts fresh when the node runs again
      const log = []; const hooks = { onEnter: () => log.push("in"), onExit: (b, s) => log.push(s) };
      let n = 0;
      const q = new Tree(parallel(action(() => RUNNING, hooks), action(() => (++n === 2 ? FAILURE : RUNNING))));
      out.abort = [q.tick(0.1), q.tick(0.1), q.tick(0.1)]; out.log = log;
      // repeat
      let runs = 0; const r3 = new Tree(repeat(action(() => { runs++; return SUCCESS; }), 3));
      out.rep = [r3.tick(0.1), r3.tick(0.1), r3.tick(0.1), r3.tick(0.1)]; out.runs = runs;
      let runs2 = 0; const rf = new Tree(repeat(action(() => { runs2++; return SUCCESS; })));
      out.forever = [rf.tick(0.1), rf.tick(0.1), rf.tick(0.1)]; out.runs2 = runs2;
      let k = 0; const rfail = new Tree(repeat(action(() => (++k >= 3 ? FAILURE : SUCCESS))));
      out.repFail = [rfail.tick(0), rfail.tick(0), rfail.tick(0)];
      out.repBusy = new Tree(repeat(busy, 2)).tick(0);
      const rw = new Tree(repeat(sequence(wait(0.2), ok), 2)); out.repWait = [0.1, 0.1, 0.1, 0.1, 0.1].map((d) => rw.tick(d));
      out
    )";
    const Json o = eval_ok(h, code);
    CHECK(o["all"] == Json::parse(R"(["success","running","failure","success"])"));
    CHECK(o["any"] == Json::parse(R"(["success","running","failure","failure"])"));
    CHECK(o["waits"] == Json::parse(R"(["running","running","success"])"));
    CHECK(o["abort"] == Json::parse(R"(["running","failure","running"])"));
    CHECK(o["log"] == Json::parse(R"(["in","aborted","in"])"));
    CHECK(o["rep"] == Json::parse(R"(["running","running","success","running"])"));
    CHECK(o["runs"] == 4);
    CHECK(o["forever"] == Json::parse(R"(["running","running","running"])"));
    CHECK(o["runs2"] == 3);
    CHECK(o["repFail"] == Json::parse(R"(["running","running","failure"])"));
    CHECK(o["repBusy"] == "running");
    CHECK(o["repWait"] == Json::parse(R"(["running","running","running","success","running"])"));
    CHECK(eval_err(h, "bt.parallel({ succeed: 'some' }, bt.action(() => 1))").find("\"all\" or \"any\"") != std::string::npos);
    CHECK(eval_err(h, "bt.parallel({ win: 'all' })").find("unknown option") != std::string::npos);
    CHECK(eval_err(h, "bt.parallel(1)").find("not a node") != std::string::npos);
    CHECK(eval_err(h, "bt.repeat(bt.action(() => 1), 0)").find("whole number") != std::string::npos);
    CHECK(eval_err(h, "bt.repeat(5)").find("not a node") != std::string::npos);
}
