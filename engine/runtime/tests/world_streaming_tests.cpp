// M75.3: world streaming (docs/BIG_WORLDS_STREAMING.md, "Streaming"): the cells of a streamed world load and unload around the
// StreamingAnchor entities through the whole engine (BackgroundLoader jobs of Kind::CellLoad, the streamer of
// engine/runtime), the commands world.cells and world.stream_status, the events, the scene change, physics and a 2D index.
// The fixture world is engine/runtime/tests/fixtures/streaming: 3x3 cells of 100 m on XZ (worlds/grid.world.json) and
// 3x2 cells on XY (worlds/grid2d.world.json). No sleeps and no wall-clock asserts: every wait is a frame loop with a cap
// 10x above what it needs, and the loads count units, not milliseconds.
#include <doctest.h>

#include <algorithm>
#include <filesystem>
#include <fstream>
#include <iterator>
#include <limits>
#include <set>
#include <string>
#include <vector>

#include "fa/core/fs.h"
#include "fa/physics/physics.h"
#include "fa/runtime/engine.h"
#include "fa/scene/components_world.h"
#include "fa/scene/serialize.h"
#include "fa_test_paths.h"

using namespace fa;
namespace stdfs = std::filesystem;

namespace {

// A temporary copy of the fixture project (a test may change a file of it).
struct StreamProject {
    stdfs::path dir;
    StreamProject() {
        dir = fs::make_temp_dir("fa_streaming").value();
        stdfs::copy(stdfs::path(FA_RUNTIME_FIXTURES) / "streaming", dir, stdfs::copy_options::recursive);
    }
    ~StreamProject() {
        std::error_code ec;
        stdfs::remove_all(dir, ec);
    }
    void write(const std::string& rel, const std::string& text) const {
        stdfs::create_directories((dir / rel).parent_path());
        std::ofstream(dir / rel, std::ios::binary) << text;
    }
    EngineConfig config(const std::string& jobThreads = "0", const std::string& scene = "") const {
        EngineConfig c;
        c.projectDir = dir.generic_string();
        c.headless = true;
        c.graphics = false;
        c.hotReload = false;
        c.jobThreads = jobThreads;
        c.scene = scene;
        return c;
    }
};

Json call(Engine& e, const std::string& name, const Json& args = Json::object()) {
    auto r = e.commands().call(name, args);
    INFO(name << " " << args.dump() << " -> " << r.error.dump());
    REQUIRE(r.ok);
    return r.result;
}

Json eval(Engine& e, const std::string& code) {
    auto r = e.commands().call("script.eval", Json::object({{"code", code}}));
    INFO(code << " -> " << r.error.dump());
    REQUIRE(r.ok);
    return r.result["value"];
}

std::vector<std::string> ids_in_state(Engine& e, const std::string& state) {
    const Json r = call(e, "world.cells", Json::object({{"state", state}}));
    std::vector<std::string> ids;
    for (const Json& c : r["cells"]) ids.push_back(c["id"].get<std::string>());
    std::sort(ids.begin(), ids.end());
    return ids;
}

using Ids = std::vector<std::string>;

void move(Engine& e, const char* id, float x, float y, float z) {
    const Entity a = e.world().find_by_id(id);
    REQUIRE(e.world().alive(a));
    e.world().get<Transform>(a)->position = {x, y, z};
}

StreamedWorld& streamed(Engine& e) {
    StreamedWorld* s = e.world().get<StreamedWorld>(e.world().find_by_id("streamer"));
    REQUIRE(s != nullptr);
    return *s;
}

// Steps until nothing is queued, loading, waiting or unloading (the caps are far above what the fixture needs).
void settle(Engine& e, int maxFrames = 200) {
    for (int f = 0; f < maxFrames; ++f) {
        e.step(1);
        const Json s = call(e, "world.stream_status");
        if (s["pending"].empty() && s["cellsUnloading"].get<int>() == 0 && s["cellsQueued"].get<int>() == 0 && f > 0)
            return;
    }
    FAIL("the streamer did not settle: " << call(e, "world.stream_status").dump());
}

const std::vector<std::string> kModes = {"0", "1",
                                         "8"};  // 0: the loader reads on the main thread; 1, 8: IO and decode threads

}  // namespace

TEST_CASE(
    "streaming: the wanted cells load around the anchor, and a cell stays loaded until it is past the unload radius") {
    StreamProject p;
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(p.config(), nullptr, &err), err);
    // The anchor stands in cell [0, 0]; loadRadius 60 reaches [1, 0] and [0, 1] (50 m away) and not [1, 1] (70.7 m).
    settle(e);
    CHECK(ids_in_state(e, "loaded") == Ids{"0,0", "0,1", "1,0"});
    CHECK(ids_in_state(e, "unloaded").size() == 6);
    // The cell root is named, flagged, and holds the cell's entities.
    const Entity root = e.world().find_by_id("cell_0_0");
    REQUIRE(e.world().alive(root));
    CHECK(e.world().info(root).name == "cell 0,0");
    CHECK(e.world().info(root).streamedCell);
    const Entity floor = e.world().find_by_id("floor_0_0");
    REQUIRE(e.world().alive(floor));
    CHECK(e.world().parent(floor) == root);
    // A cell is not part of the scene that is saved.
    CHECK(save_scene(e.world()).dump().find("floor_0_0") == std::string::npos);

    // Walk to [0, 1] (z 150): [1, 0] is 70.7 m away, past the load radius but inside the unload radius: it stays.
    move(e, "anchor", 50, 0, 150);
    settle(e);
    CHECK(ids_in_state(e, "loaded") == Ids{"0,0", "0,1", "0,2", "1,0", "1,1"});
    // z 170: [1, 0] is 86 m away (past 80) and goes; [0, 0] is 70 m away (kept, not wanted).
    move(e, "anchor", 50, 0, 170);
    settle(e);
    CHECK(ids_in_state(e, "loaded") == Ids{"0,0", "0,1", "0,2", "1,1", "1,2"});
    CHECK_FALSE(e.world().alive(e.world().find_by_id("cell_1_0")));
    // The height of an anchor never matters, and the radius is on the XZ plane.
    move(e, "anchor", 50, 5000, 170);
    settle(e);
    CHECK(ids_in_state(e, "loaded") == Ids{"0,0", "0,1", "0,2", "1,1", "1,2"});
    // keepLoaded loads everything whatever the anchors say; turning it off lets the far cells go again.
    streamed(e).keepLoaded = true;
    settle(e);
    CHECK(ids_in_state(e, "loaded").size() == 9);
    streamed(e).keepLoaded = false;
    settle(e);
    CHECK(ids_in_state(e, "loaded") == Ids{"0,0", "0,1", "0,2", "1,1", "1,2"});
    // enabled = false unloads everything.
    streamed(e).enabled = false;
    settle(e);
    CHECK(ids_in_state(e, "loaded").empty());
    CHECK(call(e, "world.stream_status")["enabled"] == false);
    e.shutdown();
}

TEST_CASE("streaming: events cellLoaded and cellUnloaded carry the coordinate") {
    StreamProject p;
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(p.config(), nullptr, &err), err);
    eval(e, "globalThis.loaded = []; globalThis.unloaded = [];"
            "world.on('cellLoaded', (d) => loaded.push(d.coord[0] + ',' + d.coord[1] + ':' + d.entities));"
            "world.on('cellUnloaded', (d) => unloaded.push(d.id)); 0");
    settle(e);
    CHECK(eval(e, "loaded.length").get<int>() == 3);
    CHECK(eval(e, "loaded[0]").get<std::string>() == "0,0:2");  // the floor and the marker
    CHECK(eval(e, "unloaded.length").get<int>() == 0);
    move(e, "anchor", 250, 0, 250);
    settle(e);
    CHECK(eval(e, "unloaded.length").get<int>() == 3);
    CHECK(eval(e, "unloaded.indexOf('0,0') >= 0").get<bool>());
    e.shutdown();
}

TEST_CASE("streaming: several loads run at once up to maxLoadsInFlight, and at most maxAppliesPerFrame cells are added "
          "per frame") {
    for (int cap : {1, 2, 3}) {
        for (int applies : {1, 3}) {
            INFO("maxLoadsInFlight " << cap << ", maxAppliesPerFrame " << applies);
            StreamProject p;
            Engine e;
            std::string err;
            REQUIRE_MESSAGE(e.init(p.config(), nullptr, &err), err);
            streamed(e).maxLoadsInFlight = cap;
            streamed(e).maxAppliesPerFrame = applies;
            int mostInFlight = 0, mostApplied = 0;
            for (int f = 0; f < 60; ++f) {
                e.step(1);
                const Json s = call(e, "world.stream_status");
                mostInFlight = std::max(mostInFlight, s["inFlight"].get<int>());
                mostApplied = std::max(mostApplied, s["appliedThisFrame"].get<int>());
                CHECK(s["inFlight"].get<int>() <= cap);
                CHECK(s["appliedThisFrame"].get<int>() <= applies);
                CHECK(s["maxLoadsInFlight"].get<int>() == cap);
            }
            CHECK(mostInFlight == std::min(cap, 3));  // the three wanted cells: the cap is reached, never passed
            CHECK(mostApplied >= 1);
            CHECK(mostApplied <= applies);
            CHECK(ids_in_state(e, "loaded") == Ids{"0,0", "0,1", "1,0"});
            const Json s = call(e, "world.stream_status");
            CHECK(s["loadsStarted"].get<int>() == 3);
            CHECK(s["cellsApplied"].get<int>() == 3);
            CHECK(s["budget"]["mode"] == "units");
            CHECK(s["budget"]["units"].get<int>() == 4);
            e.shutdown();
        }
    }
}

TEST_CASE("streaming: a load that is no longer wanted is cancelled, and nothing of it reaches the world") {
    StreamProject p;
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(p.config(), nullptr, &err), err);
    eval(e,
         "globalThis.loaded = []; globalThis.unloaded = [];"
         "world.on('cellLoaded', (d) => loaded.push(d.id)); world.on('cellUnloaded', (d) => unloaded.push(d.id)); 0");
    // maxLoadsInFlight 3 starts all three wanted cells at the first fixed tick, and maxAppliesPerFrame 1 adds at most ONE of them in
    // that frame whatever the loader finished in it: at least two jobs are still in flight (or parsed and waiting) after step(1).
    streamed(e).maxLoadsInFlight = 3;
    streamed(e).maxAppliesPerFrame = 1;
    e.step(1);
    Json s = call(e, "world.stream_status");
    CHECK(s["loadsStarted"].get<int>() == 3);
    CHECK(s["cellsApplied"].get<int>() <= 1);
    CHECK(s["cellsLoading"].get<int>() >= 2);
    // The anchor leaves: the next fixed tick cancels them before they can be applied.
    move(e, "anchor", 5000, 0, 5000);
    settle(e);
    s = call(e, "world.stream_status");
    CHECK(s["cellsLoaded"].get<int>() == 0);
    CHECK(s["loadsCancelled"].get<int>() >= 2);
    CHECK(s["loadsStarted"].get<int>() == 3);
    CHECK(s["cellsApplied"].get<int>() <= 1);
    CHECK(eval(e, "loaded.length").get<int>() == s["cellsApplied"].get<int>());
    CHECK(eval(e, "unloaded.length").get<int>() == s["unloadsDone"].get<int>());
    CHECK(s["cellsApplied"].get<int>() == s["unloadsDone"].get<int>());  // what was applied was unloaded again
    CHECK(s["loadsStarted"].get<int>() == s["cellsApplied"].get<int>() + s["loadsCancelled"].get<int>());
    for (const char* id : {"floor_0_0", "floor_1_0", "floor_0_1"})
        CHECK_FALSE(e.world().alive(e.world().find_by_id(id)));
    e.shutdown();
}

TEST_CASE("streaming: a scene change cancels every cell job and nothing is applied to the new scene") {
    for (const std::string& mode : kModes) {
        INFO("job threads " << mode);
        StreamProject p;
        Engine e;
        std::string err;
        REQUIRE_MESSAGE(e.init(p.config(mode), nullptr, &err), err);
        streamed(e).maxLoadsInFlight = 3;
        e.step(1);  // three jobs in flight
        CHECK(call(e, "world.stream_status")["loadsStarted"].get<int>() == 3);
        call(e, "scene.load", Json::object({{"path", "scenes/other.scene.json"}}));
        e.step(30);
        for (int j = 0; j < 3; ++j)
            for (int i = 0; i < 3; ++i) {
                CHECK_FALSE(
                    e.world().alive(e.world().find_by_id("floor_" + std::to_string(i) + "_" + std::to_string(j))));
                CHECK_FALSE(
                    e.world().alive(e.world().find_by_id("cell_" + std::to_string(i) + "_" + std::to_string(j))));
            }
        CHECK(e.world().alive(e.world().find_by_id("nothing")));
        const Json s = call(e, "world.stream_status");
        CHECK(s["cellsTotal"].get<int>() == 0);
        CHECK(s["cellsLoaded"].get<int>() == 0);
        CHECK(s["cellsApplied"].get<int>() == 0);
        CHECK(call(e, "load.status")["jobs"].size() == 0);  // no cell job is left in the loader
        // Back to the streamed scene: it streams again from nothing.
        call(e, "scene.load", Json::object({{"path", "scenes/main.scene.json"}}));
        settle(e);
        CHECK(ids_in_state(e, "loaded") == Ids{"0,0", "0,1", "1,0"});
        e.shutdown();
    }
}

TEST_CASE("streaming: with two anchors the cells load in a fixed order, the same with every job thread count") {
    struct Variant {
        int priorityFirst, prioritySecond;
        Ids expected;
    };
    // The first anchor is at (50, 50) and wants [0,0] (0 m), [1,0] and [0,1] (50 m). The second at (250, 250) wants [2,2] (0 m), [2,1] and
    // [1,2] (50 m). Higher priority first, then nearer, then (j, i): [2,1] before [1,2], [1,0] before [0,1].
    const Variant variants[] = {{0, 5, {"2,2", "2,1", "1,2", "0,0", "1,0", "0,1"}},
                                {5, 0, {"0,0", "1,0", "0,1", "2,2", "2,1", "1,2"}}};
    for (const Variant& v : variants) {
        for (const std::string& mode : kModes) {
            INFO("priorities " << v.priorityFirst << "/" << v.prioritySecond << ", job threads " << mode);
            StreamProject p;
            Engine e;
            std::string err;
            REQUIRE_MESSAGE(e.init(p.config(mode), nullptr, &err), err);
            const Entity a2 = e.world().create("anchor 2", "anchor2");
            e.world().get<Transform>(a2)->position = {250, 0, 250};
            StreamingAnchor& sa = e.world().add<StreamingAnchor>(a2);
            sa.loadRadius = 60;
            sa.unloadRadius = 80;
            sa.priority = v.prioritySecond;
            e.world().get<StreamingAnchor>(e.world().find_by_id("anchor"))->priority = v.priorityFirst;
            eval(e, "globalThis.order = []; world.on('cellLoaded', (d) => order.push(d.id)); 0");
            settle(e);
            const Json order = eval(e, "order");
            Ids got;
            for (const Json& id : order) got.push_back(id.get<std::string>());
            CHECK(got == v.expected);
            CHECK(ids_in_state(e, "loaded").size() == 6);
            e.shutdown();
        }
    }
}

TEST_CASE("streaming: the colliders of a cell join the physics world when it loads and leave when it unloads") {
    StreamProject p;
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(p.config(), nullptr, &err), err);
    auto floor_hit = [&](float x, float z) {
        auto hit = e.physics().raycast3d(e.world(), {x, 10.0f, z}, {0, -1, 0}, 20.0f);
        return hit ? e.world().info(hit->entity).id : std::string();
    };
    CHECK(floor_hit(50, 50).empty());  // nothing is loaded before the first tick
    settle(e);
    e.step(2);
    CHECK(floor_hit(50, 50) == "floor_0_0");
    CHECK(floor_hit(150, 50) == "floor_1_0");
    CHECK(floor_hit(250, 250).empty());  // not loaded
    move(e, "anchor", 250, 0, 250);
    settle(e);
    e.step(2);
    CHECK(floor_hit(250, 250) == "floor_2_2");
    CHECK(floor_hit(50, 50).empty());  // unloaded: no stale body answers
    CHECK(floor_hit(150, 50).empty());
    // And back: the same colliders again.
    move(e, "anchor", 50, 0, 50);
    settle(e);
    e.step(2);
    CHECK(floor_hit(50, 50) == "floor_0_0");
    CHECK(floor_hit(250, 250).empty());
    e.shutdown();
}

TEST_CASE("streaming: a 2D index lays its cells on XY, and the Z of an anchor never matters") {
    StreamProject p;
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(p.config("0", "scenes/main2d.scene.json"), nullptr, &err), err);
    settle(e);
    CHECK(ids_in_state(e, "loaded") == Ids{"0,0", "0,1", "1,0"});
    CHECK(e.world().alive(e.world().find_by_id("tile_1_0")));
    CHECK(call(e, "world.cells")["dimension"] == "2d");
    move(e, "anchor", 250, 50, 9000);  // far along z: ignored
    settle(e);
    CHECK(ids_in_state(e, "loaded") == Ids{"1,0", "2,0", "2,1"});
    CHECK(e.world().alive(e.world().find_by_id("tile_2_1")));
    CHECK_FALSE(e.world().alive(e.world().find_by_id("tile_0_0")));
    e.shutdown();
}

TEST_CASE("streaming: the camera is an anchor when StreamedWorld.cameraLoadRadius is set") {
    StreamProject p;
    p.write("scenes/camera.scene.json", R"({"format":"factoria.scene/1","entities":[
      {"id":"streamer","components":{"StreamedWorld":{"world":"worlds/grid.world.json","cameraLoadRadius":60}}},
      {"id":"cam","components":{"Transform":{"position":[250,5,250]},"Camera":{"projection":"Perspective"}}}]})");
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(p.config("0", "scenes/camera.scene.json"), nullptr, &err), err);
    settle(e);
    CHECK(ids_in_state(e, "loaded") == Ids{"1,2", "2,1", "2,2"});
    CHECK(call(e, "world.stream_status")["anchors"].get<int>() == 1);
    e.shutdown();
}

TEST_CASE("streaming: world.cells and world.stream_status answer without a streamed world, and a wrong index teaches") {
    StreamProject p;
    p.write("scenes/none.scene.json", R"({"format":"factoria.scene/1","entities":[]})");
    {
        Engine e;
        std::string err;
        REQUIRE_MESSAGE(e.init(p.config("0", "scenes/none.scene.json"), nullptr, &err), err);
        e.step(3);
        const Json s = call(e, "world.stream_status");
        CHECK(s["enabled"] == false);
        CHECK(s["cellsTotal"].get<int>() == 0);
        auto r = e.commands().call("world.cells", Json::object());
        REQUIRE_FALSE(r.ok);
        CHECK(r.error["code"] == "no_streamed_world");
        e.shutdown();
    }
    // a cell file that is missing: the index is refused at once, naming the file and the pointer, nothing is loaded
    stdfs::remove(p.dir / "cells/1_0.scene.json");
    {
        Engine e;
        std::string err;
        REQUIRE_MESSAGE(e.init(p.config(), nullptr, &err), err);
        e.step(5);
        const Json s = call(e, "world.stream_status");
        CHECK(s["cellsLoaded"].get<int>() == 0);
        const std::string last = s["lastError"].get<std::string>();
        CHECK(last.find("cells/1_0.scene.json") != std::string::npos);
        CHECK(last.find("/cells/") != std::string::npos);
        auto r = e.commands().call("world.cells", Json::object());
        REQUIRE_FALSE(r.ok);
        CHECK(r.error["code"] == "no_streamed_world");
        e.shutdown();
    }
    // an index that does not exist
    p.write("scenes/missing.scene.json", R"({"format":"factoria.scene/1","entities":[
      {"id":"streamer","components":{"StreamedWorld":{"world":"worlds/gird.world.json"}}}]})");
    {
        Engine e;
        std::string err;
        REQUIRE_MESSAGE(e.init(p.config("0", "scenes/missing.scene.json"), nullptr, &err), err);
        e.step(3);
        const std::string last = call(e, "world.stream_status")["lastError"].get<std::string>();
        CHECK(last.find("gird.world.json") != std::string::npos);
        e.shutdown();
    }
}

TEST_CASE("streaming: world.cells lists the index with states, sorted by distance, filtered and capped") {
    StreamProject p;
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(p.config(), nullptr, &err), err);
    // Before the first tick the index is already readable.
    Json r = call(e, "world.cells");
    CHECK(r["total"].get<int>() == 9);
    CHECK(r["world"] == "worlds/grid.world.json");
    CHECK(r["cells"][0]["id"] == "0,0");  // the anchor is inside it
    CHECK(r["cells"][0]["distance"].get<double>() == 0.0);
    CHECK(r["cells"][0]["state"] == "unloaded");
    CHECK(r["cells"][0]["bounds"]["max"].size() == 3);
    settle(e);
    r = call(e, "world.cells", Json::object({{"limit", 2}}));
    CHECK(r["cells"].size() == 2);
    CHECK(r["truncated"] == true);
    CHECK(r["matching"].get<int>() == 9);
    r = call(e, "world.cells", Json::object({{"state", "loaded"}}));
    CHECK(r["cells"].size() == 3);
    CHECK(r["cells"][0]["entities"].get<int>() == 2);
    const Json s = call(e, "world.stream_status");
    CHECK(s["cellsLoaded"].get<int>() == 3);
    CHECK(s["anchors"].get<int>() == 1);
    CHECK(s["bytesLoaded"].get<int>() > 0);
    CHECK(s["lastError"] == "");
    e.shutdown();
}

TEST_CASE("streaming: a cell whose file is broken is tried again after a fixed number of ticks, and the error goes "
          "when it loads") {
    StreamProject p;
    const std::string good = [&] {
        std::ifstream in(p.dir / "cells/1_0.scene.json", std::ios::binary);
        return std::string((std::istreambuf_iterator<char>(in)), std::istreambuf_iterator<char>());
    }();
    p.write("cells/1_0.scene.json", "{ this is not json");
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(p.config(), nullptr, &err), err);
    settle(e);
    CHECK(ids_in_state(e, "loaded") == Ids{"0,0", "0,1"});
    Json s = call(e, "world.stream_status");
    CHECK(s["lastError"].get<std::string>().find("cell 1,0") != std::string::npos);
    const Json listed = call(e, "world.cells", Json::object({{"state", "unloaded"}}));
    bool failedFlag = false;
    for (const Json& c : listed["cells"])
        if (c["id"] == "1,0") failedFlag = c.contains("failed") && c["failed"] == true;
    CHECK(failedFlag);
    const int started = s["loadsStarted"].get<int>();
    // Mend the file. It is not tried again at once (a fixed number of ticks must pass), but it is, and then the error is gone.
    p.write("cells/1_0.scene.json", good);
    e.step(5);
    CHECK(call(e, "world.stream_status")["loadsStarted"].get<int>() == started);
    bool loaded = false;
    for (int f = 0; f < 1000 && !loaded; ++f) {  // 120 ticks are needed: the cap is far above
        e.step(1);
        loaded = e.world().alive(e.world().find_by_id("floor_1_0"));
    }
    REQUIRE(loaded);
    settle(e);
    s = call(e, "world.stream_status");
    CHECK(s["lastError"] == "");
    CHECK(s["loadsStarted"].get<int>() == started + 1);
    CHECK(ids_in_state(e, "loaded") == Ids{"0,0", "0,1", "1,0"});
    e.shutdown();
}

TEST_CASE("streaming: an anchor at a position that is not a number loads nothing and does not break the streamer") {
    StreamProject p;
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(p.config(), nullptr, &err), err);
    const float nan = std::numeric_limits<float>::quiet_NaN();
    move(e, "anchor", nan, 0, nan);
    e.step(5);
    Json s = call(e, "world.stream_status");
    CHECK(s["anchors"].get<int>() == 0);
    CHECK(s["cellsLoaded"].get<int>() == 0);
    CHECK(s["loadsStarted"].get<int>() == 0);
    move(e, "anchor", std::numeric_limits<float>::infinity(), 0, 50);
    e.step(5);
    CHECK(call(e, "world.stream_status")["cellsLoaded"].get<int>() == 0);
    move(e, "anchor", 50, 0, 50);  // back to a real position: the cells come
    settle(e);
    CHECK(ids_in_state(e, "loaded") == Ids{"0,0", "0,1", "1,0"});
    e.shutdown();
}

TEST_CASE("streaming: the per-frame counters of world.stream_status go back to 0 in a frame where nothing happens") {
    StreamProject p;
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(p.config(), nullptr, &err), err);
    bool sawApply = false;
    for (int f = 0; f < 60; ++f) {
        e.step(1);
        const Json s = call(e, "world.stream_status");
        sawApply = sawApply || s["appliedThisFrame"].get<int>() > 0;
    }
    CHECK(sawApply);
    e.step(1);
    const Json s = call(e, "world.stream_status");
    CHECK(s["appliedThisFrame"].get<int>() == 0);
    CHECK(s["unloadedThisFrame"].get<int>() == 0);
    CHECK(s["unitsThisFrame"].get<int>() == 0);
    e.shutdown();
}

TEST_CASE("streaming: a world whose floating origin is shifted loads and unloads the same cells, at their absolute "
          "positions") {
    // The same walk twice: once with the origin at 0 and once after World::rebase moved it by (4096, 0, 4096). The index and the
    // cell files hold ABSOLUTE positions, the anchor's local position is what moved. A cell loads under its root, which
    // stands at the absolute (0, 0, 0) (a load under a parent is placed by the parent: load_scene shifts only the roots it creates).
    auto walk = [&](bool shifted) {
        StreamProject p;
        Engine e;
        std::string err;
        REQUIRE_MESSAGE(e.init(p.config(), nullptr, &err), err);
        if (shifted) e.world().rebase(Vec3{4096, 0, 4096});
        CHECK(e.world().origin().x == (shifted ? 4096.0 : 0.0));
        auto go = [&](double x, double z) {  // the anchor goes to the ABSOLUTE position (x, 0, z)
            const Entity a = e.world().find_by_id("anchor");
            REQUIRE(e.world().alive(a));
            e.world().get<Transform>(a)->position = e.world().to_local(DVec3{x, 0.0, z});
        };
        go(50, 50);
        settle(e);
        std::vector<Ids> seen;
        seen.push_back(ids_in_state(e, "loaded"));
        CHECK(seen.back() == Ids{"0,0", "0,1", "1,0"});
        // A cell's entity is at its absolute position (150, 1, 150) in the cell [1, 1] once it loads, whatever the origin is.
        go(150, 150);
        settle(e);
        seen.push_back(ids_in_state(e, "loaded"));
        const Entity marker = e.world().find_by_id("marker_1_1");
        REQUIRE(e.world().alive(marker));
        const DVec3 abs = e.world().absolute_position(marker);
        CHECK(abs.x == doctest::Approx(150.0));
        CHECK(abs.y == doctest::Approx(1.0));
        CHECK(abs.z == doctest::Approx(150.0));
        const Vec3 local = e.world().world_position(marker);
        CHECK(double(local.x) == doctest::Approx(shifted ? 150.0 - 4096.0 : 150.0));
        // A rebase while cells are loaded changes what is local, never what is loaded: no load or unload starts.
        const Json before = call(e, "world.stream_status");
        e.world().rebase(Vec3{256, 0, 256});
        settle(e);
        e.step(5);
        const Json after = call(e, "world.stream_status");
        CHECK(after["loadsStarted"] == before["loadsStarted"]);
        CHECK(after["unloadsDone"] == before["unloadsDone"]);
        seen.push_back(ids_in_state(e, "loaded"));
        CHECK(seen.back() == seen[1]);
        go(50, 170);
        settle(e);
        seen.push_back(ids_in_state(e, "loaded"));
        CHECK(seen.back() == Ids{"0,0", "0,1", "0,2", "1,1", "1,2"});
        e.shutdown();
        return seen;
    };
    CHECK(walk(false) == walk(true));
}
