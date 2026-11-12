// tilemap.generate from a script: the same generator as the command, spread over frames, with the sample's markers placed as
// entities. The determinism contract (the level and stats.work do not depend on how the work is cut) is checked against the command.
#include <doctest.h>

#include <algorithm>
#include <filesystem>
#include <fstream>

#include "fa/core/fs.h"
#include "fa/runtime/engine.h"
#include "fa/scene/tilemap.h"

using namespace fa;
namespace stdfs = std::filesystem;

namespace {

const char* kProject = R"({
  "format": "factoria.project/1", "name": "Wfc Script Test", "id": "com.example.wfcscript",
  "mainScene": "scenes/main.scene.json",
  "display": { "width": 320, "height": 180, "scaleMode": "pixelPerfect" }
})";

const char* kScene = R"({
  "format": "factoria.scene/1",
  "entities": [
    { "id": "cam", "components": { "Camera": {} } },
    { "id": "example", "components": { "Tilemap": {
        "tileSize": [16, 16], "width": 8, "height": 6,
        "tiles": [ 0,0,0,0,0,0,0,0,  0,1,1,1,1,1,1,0,  0,1,0,0,1,0,1,0,  0,1,1,1,1,0,1,0,  0,1,0,1,1,1,1,0,  0,0,0,0,0,0,0,0 ] } } },
    { "id": "target", "components": { "Tilemap": { "tileSize": [16, 16], "width": 2, "height": 2, "tiles": [-1,-1,-1,-1] } } }
  ]
})";

const char* kOther = R"({"format": "factoria.scene/1", "entities": [ { "id": "cam", "components": { "Camera": {} } } ]})";

// 16 x 16 sample with a few walls and one coin ('o'), as ASCII rows.
const char* kRows = R"(["................","..####..........","..#..#....##....","..#..#....##....","..####..........","................","......#.........",
  "......#....###..","...........#.#..","...........###..","..##............","..##......#.....","................","....#.....o.#...",
  "................","................"])";

const char* kLegend = R"({"#":0,"o":{"prefab":"prefabs/coin.prefab.json"}})";

struct Session {
    stdfs::path dir;
    Engine engine;
    Session() {
        dir = fs::make_temp_dir("fa_wfc_script_test").value();
        write("factoria.json", kProject);
        write("scenes/main.scene.json", kScene);
        write("scenes/other.scene.json", kOther);
        write("prefabs/coin.prefab.json", R"({"format":"factoria.prefab/1","entity":{"id":"coin","components":{"Transform":{"position":[0,0]}}}})");
        EngineConfig c;
        c.projectDir = dir.generic_string();
        c.headless = true;
        c.hotReload = false;
        std::string err;
        REQUIRE_MESSAGE(engine.init(c, nullptr, &err), err);
        engine.step(1);
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
    // Runs script code; returns the whole script.eval answer (ok/error), without failing the test.
    CommandResult run(const std::string& code) { return engine.commands().call("script.eval", Json::object({{"code", code}})); }
    Json eval(const std::string& code) {
        CommandResult r = run(code);
        INFO(code << " -> " << r.error.dump());
        REQUIRE(r.ok);
        return r.result["value"];
    }
    // Steps frames until `globalThis.job` is done; returns how many frames it took (-1: more than `limit`).
    int frames_until_done(int limit = 400) {
        for (int f = 0; f < limit; ++f) {
            if (eval("globalThis.job.done").get<bool>()) return f;
            engine.step(1);
        }
        return -1;
    }
    CommandResult call(const std::string& cmd, const Json& args) { return engine.commands().call(cmd, args); }
};

std::string args_js(const std::string& extra) { return std::string("{ sample: ") + kRows + ", legend: " + kLegend + ", " + extra + " }"; }
Json args_json(const std::string& extra) { return Json::parse(std::string(R"({"sample":)") + kRows + R"(,"legend":)" + kLegend + "," + extra + "}"); }
std::string error_text(const CommandResult& r) {
    if (r.ok) return std::string();  // doctest -s builds the message on success too
    return r.error.value("code", std::string()) + ": " + r.error.value("message", std::string()) + " | " + r.error.value("hint", std::string()); }
bool contains(const std::string& s, const std::string& n) { return s.find(n) != std::string::npos; }

}  // namespace

TEST_CASE("tilemap.generate (script): the level and the work are those of the command, spread over several frames") {
    Session s;
    const std::string extra = R"("size":[56,40],"seed":9,"n":3)";
    auto ref = s.call("tilemap.generate", args_json(extra));
    REQUIRE_MESSAGE(ref.ok, error_text(ref));
    const long long refWork = ref.result["stats"]["work"].get<long long>();
    REQUIRE(refWork > 600000);  // more than one frame's share (500000 units without a window), or the test proves nothing

    s.eval("globalThis.job = tilemap.generate(" + args_js("size: [56, 40], seed: 9, n: 3") + ")");
    CHECK(s.eval("globalThis.job.done") == false);
    CHECK(s.eval("globalThis.job.progress") == 0);
    CHECK(s.eval("globalThis.job.result") == nullptr);
    double last = 0;
    int frames = 0;
    bool grew = false;
    for (; frames < 400 && !s.eval("globalThis.job.done").get<bool>(); ++frames) {
        s.engine.step(1);
        const double p = s.eval("globalThis.job.progress").get<double>();
        CHECK(p >= last);
        grew = grew || p > last;
        last = p;
    }
    REQUIRE(s.eval("globalThis.job.done") == true);
    CHECK(s.eval("globalThis.job.error") == "");
    CHECK(frames >= 2);
    CHECK(grew);
    CHECK(s.eval("globalThis.job.progress") == 1);
    CHECK(s.eval("globalThis.job.work").get<long long>() == refWork);
    CHECK(s.eval("JSON.stringify(globalThis.job.result.rows)").get<std::string>() == ref.result["rows"].dump());
    CHECK(s.eval("globalThis.job.result.stats.work").get<long long>() == refWork);
    CHECK(s.eval("globalThis.job.result.seed") == 9);

    // The frames it takes are a function of the work, not of the machine: a second run takes exactly as many.
    s.eval("globalThis.job = tilemap.generate(" + args_js("size: [56, 40], seed: 9, n: 3") + ")");
    CHECK(s.frames_until_done() == frames);
}

TEST_CASE("tilemap.generate (script): the per-frame budget is shared by the running generations") {
    Session s;
    const std::string a = args_js("size: [56, 40], seed: 9, n: 3");
    // alone, a generation gets the whole frame (500000 units without a window)...
    s.eval("globalThis.job = tilemap.generate(" + a + ")");
    s.engine.step(1);
    const long long alone = s.eval("globalThis.job.work").get<long long>();
    CHECK(alone >= 400000);
    CHECK(alone <= 520000);
    s.eval("globalThis.job.cancel()");
    // ...four together get a quarter each, so a frame never does more than the same 500000 in all
    s.eval("globalThis.jobs = [1, 2, 3, 4].map((i) => tilemap.generate(" + args_js("size: [56, 40], seed: 9 + i, n: 3") + "))");
    s.engine.step(1);
    long long together = 0;
    for (int i = 0; i < 4; ++i) {
        const long long w = s.eval("globalThis.jobs[" + std::to_string(i) + "].work").get<long long>();
        CHECK(w <= 150000);   // a quarter of the frame plus one chunk (16384) of overshoot
        CHECK(w > 0);
        together += w;
    }
    CHECK(together <= 520000);
    s.eval("globalThis.jobs.forEach((j) => j.cancel())");
}

TEST_CASE("tilemap.generate (script): place builds the Tilemap and one entity per marker, the way scene.import_ascii does") {
    Session s;
    s.eval("globalThis.job = tilemap.generate(" +
           args_js("size: [24, 16], seed: 3, constraints: { counts: [{ tile: 'o', min: 3, max: 3 }] }, place: { entity: 'level', tilemap: { tileSize: [16, 16] }, position: [0, 0] }") + ")");
    REQUIRE(s.frames_until_done() >= 0);
    const Json jobError = s.eval("globalThis.job.error");  // not inside the message: eval asserts, and doctest -s would deadlock on the nested assertion
    REQUIRE_MESSAGE(jobError == "", jobError.dump());
    const Json rows = Json::parse(s.eval("JSON.stringify(globalThis.job.result.rows)").get<std::string>());
    int coins = 0;
    for (const Json& row : rows)
        for (char c : row.get<std::string>()) coins += c == 'o';
    CHECK(coins == 3);
    const Entity level = s.engine.world().find("level");
    REQUIRE(level != Entity{});
    const Tilemap* tm = s.engine.world().get<Tilemap>(level);
    REQUIRE(tm != nullptr);
    CHECK(tm->width == 24);
    CHECK(tm->height == 16);
    int tagged = 0;
    s.engine.world().each<Transform>([&](Entity e, Transform&) {
        const std::string id = s.engine.world().id_of(e);
        if (id.rfind("coin_", 0) == 0) ++tagged;
    });
    CHECK(tagged == 3);
    CHECK(s.eval("globalThis.job.result.placed.tilemap") == "level");
    CHECK(s.eval("globalThis.job.result.placed.spawned.length") == 3);
}

TEST_CASE("tilemap.generate (script): into writes the tiles of an entity that exists, from an entity sample") {
    Session s;
    s.eval("globalThis.job = tilemap.generate({ sample: world.find('example'), size: [20, 12], seed: 5, n: 2, rows: true, into: world.find('target') })");
    REQUIRE(s.frames_until_done() >= 0);
    const Json jobError = s.eval("globalThis.job.error");  // not inside the message: eval asserts, and doctest -s would deadlock on the nested assertion
    REQUIRE_MESSAGE(jobError == "", jobError.dump());
    const Tilemap* tm = s.engine.world().get<Tilemap>(s.engine.world().find("target"));
    REQUIRE(tm != nullptr);
    CHECK(tm->width == 20);
    CHECK(tm->height == 12);
    // The same level as the command writes
    auto ref = s.call("tilemap.generate", Json::object({{"sample", "example"}, {"size", Json::array({20, 12})}, {"seed", 5}, {"n", 2}}));
    REQUIRE_MESSAGE(ref.ok, error_text(ref));
    CHECK(s.eval("JSON.stringify(globalThis.job.result.rows)").get<std::string>() == ref.result["rows"].dump());
}

TEST_CASE("tilemap.generate (script): a scene load ends the generation and nothing is placed") {
    Session s;
    s.eval("globalThis.rejected = ''; globalThis.job = tilemap.generate(" +
           args_js("size: [56, 40], seed: 9, place: { entity: 'late' }") + "); globalThis.job.promise.catch((e) => { globalThis.rejected = e.message; });");
    s.engine.step(1);
    REQUIRE(s.eval("globalThis.job.done") == false);
    std::string err;
    REQUIRE_MESSAGE(s.engine.load_scene("scenes/other.scene.json", &err), err);
    s.engine.step(2);
    CHECK(s.eval("globalThis.job.done") == true);
    const std::string error = s.eval("globalThis.job.error").get<std::string>();
    CHECK(contains(error, "scene"));
    CHECK(contains(s.eval("globalThis.job.hint").get<std::string>(), "again"));
    CHECK(contains(s.eval("globalThis.rejected").get<std::string>(), "scene"));
    CHECK(s.eval("globalThis.job.result") == nullptr);
    CHECK(s.engine.world().find("late") == Entity{});
    // the job is gone from the engine too: its memory was given back
    auto step = s.call("tilemap.generate_step", Json::object({{"job", 1}}));
    CHECK_FALSE(step.ok);
    CHECK(contains(error_text(step), "no generation"));
}

TEST_CASE("tilemap.generate (script): cancel, caps and mistakes teach") {
    Session s;
    // cancel stops the work and rejects the promise
    s.eval("globalThis.rejected = ''; globalThis.job = tilemap.generate(" + args_js("size: [56, 40], seed: 9") + "); globalThis.job.promise.catch((e) => { globalThis.rejected = e.message; });");
    s.engine.step(1);
    s.eval("globalThis.job.cancel()");
    s.engine.step(1);
    CHECK(s.eval("globalThis.job.done") == true);
    CHECK(contains(s.eval("globalThis.rejected").get<std::string>(), "cancelled"));
    CHECK(s.call("tilemap.generate_cancel", Json::object({{"job", 1}})).result["cancelled"] == false);  // already gone

    // maxWork ends the generation with the message of the command
    s.eval("globalThis.job = tilemap.generate(" + args_js("size: [56, 40], seed: 9, maxWork: 1000") + ")");
    REQUIRE(s.frames_until_done() >= 0);
    CHECK(contains(s.eval("globalThis.job.error").get<std::string>(), "maxWork"));
    CHECK(s.eval("globalThis.job.hint").get<std::string>() != "");

    // a mistake in the arguments throws when called, with the same text as the command
    auto r = s.run("tilemap.generate({ size: [8, 8] })");
    CHECK_FALSE(r.ok);
    CHECK(contains(r.error.dump(), "sample"));
    r = s.run("tilemap.generate(" + args_js("size: [8, 8], into: 'target', place: true") + ")");
    CHECK_FALSE(r.ok);
    CHECK(contains(r.error.dump(), "not both"));
    r = s.run("tilemap.generate(" + args_js("size: [8, 8], place: { rows: ['#'] }") + ")");
    CHECK_FALSE(r.ok);
    CHECK(contains(r.error.dump(), "place.rows"));
    // `place` is checked when called, not after a finished generation: unknown key (with a suggestion), types, anchor
    r = s.run("tilemap.generate(" + args_js("size: [8, 8], place: { entiy: 'level' }") + ")");
    REQUIRE_FALSE(r.ok);
    CHECK(contains(r.error.dump(), "place.entiy"));
    CHECK(contains(r.error.dump(), "entity"));
    r = s.run("tilemap.generate(" + args_js("size: [8, 8], place: { entity: 5 }") + ")");
    REQUIRE_FALSE(r.ok);
    CHECK(contains(r.error.dump(), "place.entity"));
    r = s.run("tilemap.generate(" + args_js("size: [8, 8], place: { position: [1] }") + ")");
    REQUIRE_FALSE(r.ok);
    CHECK(contains(r.error.dump(), "place.position"));
    r = s.run("tilemap.generate(" + args_js("size: [8, 8], place: { anchor: 'centre' }") + ")");
    REQUIRE_FALSE(r.ok);
    CHECK(contains(r.error.dump(), "center"));
    r = s.run("tilemap.generate(" + args_js("size: [8, 8], place: { replace: 'yes' }") + ")");
    REQUIRE_FALSE(r.ok);
    CHECK(contains(r.error.dump(), "place.replace"));
    r = s.run("tilemap.generate(" + args_js("size: [8, 8], place: { tilemap: [] }") + ")");
    REQUIRE_FALSE(r.ok);
    CHECK(contains(r.error.dump(), "place.tilemap"));
    // none of them queued a job
    CHECK(s.call("tilemap.generate_cancel", Json::object({{"job", 1}})).result["cancelled"] == false);
    r = s.run("tilemap.generate('level')");
    CHECK_FALSE(r.ok);
    CHECK(contains(r.error.dump(), "expects an object"));
    r = s.run("tilemap.generate(" + args_js("size: [8, 8], seed: 1.5") + ")");
    CHECK_FALSE(r.ok);
    CHECK(contains(r.error.dump(), "seed"));

    // a limited number of generations at once
    for (int i = 0; i < 8; ++i) s.eval("tilemap.generate(" + args_js("size: [8, 8], seed: " + std::to_string(i)) + ")");
    r = s.run("tilemap.generate(" + args_js("size: [8, 8], seed: 99") + ")");
    CHECK_FALSE(r.ok);
    CHECK(contains(r.error.dump(), "8 generations"));
}

TEST_CASE("tilemap.generate (script): a Behaviour with rng.create picks the seed and places the level") {
    Session s;
    std::string script = R"JS(
import { Behaviour, tilemap, rng } from "factoria";
export default class Gen extends Behaviour {
  onStart() {
    const seed = rng.create(2024).int(0, 2147483647);
    globalThis.genSeed = seed;
    this.job = tilemap.generate({
      sample: @ROWS@, legend: { "#": 0, "o": { prefab: "prefabs/coin.prefab.json" } },
      size: [16, 10], seed, place: { entity: "run" },
    });
    this.job.promise.then((r) => { globalThis.genDone = r.stats.attempts; });
  }
}
)JS";
    script.replace(script.find("@ROWS@"), 6, kRows);
    s.write("scripts/gen.js", script);
    s.write("scenes/gen.scene.json", R"({"format":"factoria.scene/1","entities":[{"id":"cam","components":{"Camera":{}}},
        {"id":"gen","components":{"Transform":{},"Script":{"path":"scripts/gen.js"}}}]})");
    std::string err;
    REQUIRE_MESSAGE(s.engine.load_scene("scenes/gen.scene.json", &err), err);
    for (int f = 0; f < 100 && s.eval("typeof globalThis.genDone").get<std::string>() == "undefined"; ++f) s.engine.step(1);
    CHECK(s.eval("typeof globalThis.genDone").get<std::string>() == "number");
    CHECK(s.eval("globalThis.genSeed === rng.create(2024).int(0, 2147483647)") == true);  // the seed of the run comes from rng.create
    const Tilemap* tm = s.engine.world().get<Tilemap>(s.engine.world().find("run"));
    REQUIRE(tm != nullptr);
    CHECK(tm->width == 16);
}

TEST_CASE("tilemap.generate_start / generate_step: any way of cutting the work gives the command's level") {
    Session s;
    const Json args = args_json(R"("size":[40,30],"seed":21)");
    auto ref = s.call("tilemap.generate", args);
    REQUIRE_MESSAGE(ref.ok, error_text(ref));
    auto start = s.call("tilemap.generate_start", args);
    REQUIRE_MESSAGE(start.ok, error_text(start));
    const int job = start.result["job"].get<int>();
    CHECK(start.result["width"] == 40);
    CHECK(start.result["memoryBytes"].get<long long>() > 0);
    int calls = 0;
    Json last;
    for (; calls < 100000; ++calls) {
        // alternate a tiny work budget and a time budget: neither may change the level
        Json stepArgs = Json::object({{"job", job}});
        if (calls % 2 == 0) stepArgs["work"] = 20000;
        else stepArgs["budgetMs"] = 0.5;
        auto r = s.call("tilemap.generate_step", stepArgs);
        REQUIRE_MESSAGE(r.ok, error_text(r));
        last = r.result;
        if (last["done"].get<bool>()) break;
    }
    REQUIRE(last["done"].get<bool>());
    CHECK(calls > 1);
    CHECK(last["result"]["rows"] == ref.result["rows"]);
    CHECK(last["result"]["stats"]["work"] == ref.result["stats"]["work"]);
    CHECK(last["progress"] == 1.0);
    // a finished job is gone
    auto again = s.call("tilemap.generate_step", Json::object({{"job", job}}));
    CHECK_FALSE(again.ok);
    CHECK(contains(error_text(again), "no generation"));
    // arguments of the step are checked
    auto start2 = s.call("tilemap.generate_start", args);
    REQUIRE(start2.ok);
    const Json id2 = start2.result["job"];
    auto bad = s.call("tilemap.generate_step", Json::object({{"job", id2}, {"work", 0}}));
    CHECK_FALSE(bad.ok);
    INFO(error_text(bad));
    CHECK(contains(error_text(bad), "work"));
    bad = s.call("tilemap.generate_step", Json::object({{"job", id2}, {"budgetMs", -1}}));
    CHECK_FALSE(bad.ok);
    INFO(error_text(bad));
    CHECK(contains(error_text(bad), "budgetMs"));
    CHECK(s.call("tilemap.generate_step", Json::object({{"work", 5}})).ok == false);  // no job
    CHECK(s.call("tilemap.generate_cancel", Json::object({{"job", id2}})).result["cancelled"] == true);
    // the start checks the arguments like the command: nothing is created for a mistake
    auto badStart = s.call("tilemap.generate_start", Json::object({{"size", Json::array({8, 8})}}));
    CHECK_FALSE(badStart.ok);
    CHECK(contains(error_text(badStart), "sample"));
}

TEST_CASE("tilemap.generate_step: the Tilemap of `into` is gone when the level is ready") {
    Session s;
    auto start = s.call("tilemap.generate_start", Json::parse(R"({"sample":"example","size":[12,8],"seed":5,"n":2,"into":"target"})"));
    REQUIRE_MESSAGE(start.ok, error_text(start));
    REQUIRE(s.call("scene.destroy", Json::object({{"id", "target"}})).ok);
    auto r = s.call("tilemap.generate_step", Json::object({{"job", start.result["job"]}, {"work", 100000000}}));
    CHECK_FALSE(r.ok);
    CHECK(contains(error_text(r), "`into`"));
    // the failed job was dropped
    CHECK(s.call("tilemap.generate_cancel", Json::object({{"job", start.result["job"]}})).result["cancelled"] == false);
}
