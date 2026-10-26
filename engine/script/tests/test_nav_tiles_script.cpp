// nav.findTilePath, nav.tileVersion and bt from scripts.
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
