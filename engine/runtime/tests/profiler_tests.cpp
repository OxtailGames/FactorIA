// The profiler (fa/core/profiler.h) in a running engine: the report of run_headless, and the rule that it never changes what the
// game does.
#include <doctest.h>

#include <filesystem>
#include <fstream>
#include <sstream>

#include "fa/core/fs.h"
#include "fa/core/profiler.h"
#include "fa/runtime/engine.h"

using namespace fa;
namespace stdfs = std::filesystem;

namespace {

const char* kProject = R"({
  "format": "factoria.project/1",
  "name": "Profiler Test",
  "id": "com.example.profilertest",
  "mainScene": "scenes/main.scene.json",
  "display": { "width": 320, "height": 180, "scaleMode": "pixelPerfect" },
  "physics": { "fixedHz": 60, "pixelsPerMeter": 100 },
  "input": { "actions": { "jump": ["Space"] } }
})";

const char* kScene = R"({
  "format": "factoria.scene/1",
  "entities": [
    { "id": "cam", "components": { "Camera": { "clearColor": "#203040" } } },
    { "id": "busy", "components": { "Transform": { "position": [-40, 0, 0] }, "Shape2D": { "size": [20, 20] },
                                    "Script": { "path": "scripts/busy.js" } } },
    { "id": "idle", "components": { "Transform": { "position": [40, 0, 0] }, "Shape2D": { "size": [20, 20] },
                                    "Script": { "path": "scripts/idle.js" } } },
    { "id": "ball", "components": { "Transform": { "position": [0, 60, 0] }, "Shape2D": { "shape": "circle", "size": [20, 20] },
                                    "RigidBody2D": {}, "Collider2D": { "shape": "circle", "radius": 10 } } }
  ]
})";

// Spends real time every frame, and moves its entity with its own call count so the state shows it ran.
const char* kBusy = R"(import { Behaviour, vec2 } from "factoria";
export default class BusyWork extends Behaviour {
  onUpdate(dt) {
    let x = 0;
    for (let i = 0; i < 60000; i++) x += Math.sqrt(i);
    this.n = (this.n || 0) + 1;
    this.entity.position = vec2(-40, x > 0 ? this.n % 50 : 0);
  }
}
)";
const char* kIdle = R"(import { Behaviour } from "factoria";
export default class IdleThing extends Behaviour {
  onUpdate(dt) {}
}
)";

struct Project {
    stdfs::path dir;
    Project() {
        dir = fs::make_temp_dir("fa_profiler_test");
        write("factoria.json", kProject);
        write("scenes/main.scene.json", kScene);
        write("scripts/busy.js", kBusy);
        write("scripts/idle.js", kIdle);
        write("replay.json", R"({"frames":{"2":{"press":["jump"]},"9":{"release":["jump"]}}})");
    }
    ~Project() {
        std::error_code ec;
        stdfs::remove_all(dir, ec);
    }
    void write(const std::string& rel, const std::string& text) const {
        stdfs::create_directories((dir / rel).parent_path());
        std::ofstream(dir / rel, std::ios::binary) << text;
    }
    std::string path(const std::string& rel = "") const { return rel.empty() ? dir.generic_string() : (dir / rel).generic_string(); }
    std::string read(const std::string& rel) const {
        std::ifstream f(dir / rel, std::ios::binary);
        std::stringstream ss;
        ss << f.rdbuf();
        return ss.str();
    }
};

EngineConfig headless(const Project& p) {
    EngineConfig c;
    c.projectDir = p.path();
    c.headless = true;
    c.hotReload = false;
    c.memoryStorage = true;
    return c;
}

const Json* find_class(const Json& behaviours, const std::string& name) {
    for (const Json& b : behaviours)
        if (b.value("class", std::string()) == name) return &b;
    return nullptr;
}

}  // namespace

TEST_CASE("profiler: run_headless reports systems, behaviour classes, gpu and memory") {
    Project p;
    HeadlessRunOptions o;
    o.frames = 40;
    o.profile = true;
    o.profileWarmup = 5;
    Json report;
    REQUIRE(run_headless(headless(p), o, &report) == 0);
    REQUIRE(report.contains("profile"));
    const Json& prof = report["profile"];
    CHECK(prof["frames"] == 35);  // the warm-up is not counted
    CHECK(prof["frameMs"]["avg"].get<double>() > 0.0);
    for (const char* sys : {"platform", "physics", "scriptsFixedUpdate", "animation", "ui", "scriptsUpdate", "audio",
                            "scriptsLateUpdate", "render", "endOfFrame"}) {
        INFO(sys);
        REQUIRE(prof["systems"].contains(sys));
        CHECK(prof["systems"][sys]["avgMs"].get<double>() >= 0.0);
        CHECK(prof["systems"][sys]["maxMs"].get<double>() >= prof["systems"][sys]["avgMs"].get<double>());
    }
    // The scripts are where the time went: the busy loop shows in scriptsUpdate, and more than anything else the game does.
    CHECK(prof["systems"]["scriptsUpdate"]["avgMs"].get<double>() > prof["systems"]["physics"]["avgMs"].get<double>());

    const Json* busy = find_class(prof["behaviours"], "BusyWork");
    const Json* idle = find_class(prof["behaviours"], "IdleThing");
    REQUIRE(busy);
    REQUIRE(idle);
    CHECK((*busy)["path"] == "scripts/busy.js");
    CHECK((*idle)["path"] == "scripts/idle.js");
    CHECK((*busy)["avgMs"].get<double>() > (*idle)["avgMs"].get<double>());
    CHECK((*busy)["callsPerFrame"].get<double>() == doctest::Approx(1.0));  // one onUpdate per frame
    CHECK((*idle)["callsPerFrame"].get<double>() == doctest::Approx(1.0));
    CHECK(prof["behaviours"][0]["class"] == "BusyWork");  // sorted by time, the slowest first

    // GPU: a number where the backend can time, else null with the reason (never missing).
    MESSAGE("gpu: ", prof["gpu"].dump());
    REQUIRE(prof["gpu"].contains("avgMs"));
    if (prof["gpu"]["avgMs"].is_null()) CHECK(prof["gpu"]["reason"].is_string());
    else CHECK(prof["gpu"]["avgMs"].get<double>() >= 0.0);

    REQUIRE(prof["memory"].contains("start"));
    CHECK(prof["memory"]["end"]["entities"].get<int>() >= 4);
    CHECK(prof["memory"]["peak"]["processMB"].get<double>() > 0.0);
    CHECK(prof["memory"]["end"]["jsHeapMB"].get<double>() > 0.0);
    CHECK_FALSE(Profiler::on());  // switched back off when the run ended
}

TEST_CASE("profiler: a run without it has no profile section, and it costs nothing to leave off") {
    Project p;
    HeadlessRunOptions o;
    o.frames = 5;
    Json report;
    REQUIRE(run_headless(headless(p), o, &report) == 0);
    CHECK_FALSE(report.contains("profile"));
    CHECK_FALSE(Profiler::on());
}

TEST_CASE("profiler: game.state, screenshots and a replay are byte-identical with it on and off") {
    Project p;
    auto run = [&](bool profile, const std::string& tag) {
        HeadlessRunOptions o;
        o.frames = 30;
        o.profile = profile;
        o.inputReplayPath = p.path("replay.json");
        o.stateOutPath = p.path("state_" + tag + ".json");
        o.screenshotFrames = {29};
        o.screenshotPattern = p.path("shot_" + tag + ".png");
        Json report;
        const int code = run_headless(headless(p), o, &report);
        INFO(tag, ": ", report.dump());
        REQUIRE(code == 0);
    };
    run(false, "off");
    run(true, "on");
    run(false, "off2");
    const std::string off = p.read("state_off.json");
    CHECK_FALSE(off.empty());
    CHECK(off == p.read("state_off2.json"));  // the baseline itself is reproducible
    CHECK(p.read("state_on.json") == off);
    CHECK(off.find("cpuMs") == std::string::npos);  // timing never reaches game.state
    const std::string shot = p.read("shot_off.png");
    if (!shot.empty()) CHECK(p.read("shot_on.png") == shot);

    // The same through a live engine: stepping with the profiler on leaves exactly the same world.
    auto state_after = [&](bool profile) {
        Profiler::get().set_enabled(profile);
        Engine e;
        std::string err;
        REQUIRE_MESSAGE(e.init(headless(p), nullptr, &err), err);
        e.step(20);
        Json st = e.state();
        e.shutdown();
        Profiler::get().set_enabled(false);
        return st.dump();
    };
    CHECK(state_after(true) == state_after(false));
}

TEST_CASE("profiler: ProfBehaviourScope charges nested probes to the inner one only") {
    Profiler& pr = Profiler::get();
    pr.set_enabled(true);
    pr.begin_frame();
    const std::string outer = "Outer", inner = "Inner", path = "scripts/x.js";
    // The inner scope is much longer than the outer's own work, so a busy CI runner that preempts this thread for a few
    // milliseconds cannot make the outer look as if it had been charged the inner's time.
    {
        ProfBehaviourScope a(outer, path);
        const double t0 = Profiler::now_ms();
        while (Profiler::now_ms() - t0 < 2.0) {}  // outer's own work
        {
            ProfBehaviourScope b(inner, path);
            const double t1 = Profiler::now_ms();
            while (Profiler::now_ms() - t1 < 40.0) {}
        }
    }
    pr.end_frame();
    const ProfFrame f = pr.last();
    pr.set_enabled(false);
    REQUIRE(f.classes.size() == 2);
    auto find = [&](const std::string& name) {
        for (const auto& c : f.classes)
            if (c.className == name) return c.ms;
        FAIL("no class " << name << " in the frame");
        return 0.0;
    };
    const double inner_ms = find(inner), outer_ms = find(outer);
    CHECK(inner_ms >= 40.0);
    CHECK(outer_ms >= 2.0);
    CHECK(outer_ms < 40.0);  // the 40 ms of the inner scope are not counted again
}
