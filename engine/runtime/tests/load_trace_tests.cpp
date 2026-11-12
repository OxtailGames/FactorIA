// The load trace through the whole engine (fa/core/load_trace.h): play.auto and the headless runner drive the engine's
// frames themselves, and what the game reads in them (a scene a script loads, the modules it imports, the bot hook) is
// still the session's: in the first-use order the sink gets, and in play.report's loading section.
#include <doctest.h>

#include <algorithm>
#include <filesystem>
#include <string>

#include "fa/core/fs.h"
#include "fa/core/json.h"
#include "fa/runtime/engine.h"
#include "fa/runtime/play_auto.h"

using namespace fa;
namespace stdfs = std::filesystem;

namespace {

// Two scenes: the main one's script loads the level after a few frames, the level's script imports a module. A bot hook
// that imports one too.
struct TwoScenes {
    stdfs::path dir = fs::make_temp_dir("fa_load_trace_engine").value();
    TwoScenes() {
        write("factoria.json", R"({"format":"factoria.project/1","name":"Trace","id":"com.example.trace",
            "mainScene":"scenes/main.scene.json","display":{"width":64,"height":64},"physics":{"fixedHz":60},
            "input":{"actions":{"jump":["Space"]}}})");
        write("scenes/main.scene.json", R"({"format":"factoria.scene/1","entities":[{"id":"cam","components":{"Camera":{}}},
            {"id":"go","components":{"Transform":{},"Script":{"path":"scripts/go.js"}}}]})");
        write("scripts/go.js", R"(
import { Behaviour, scene } from "factoria";
export default class Go extends Behaviour {
  onStart() { this.frames = 0; }
  onUpdate() { if (++this.frames === 5) scene.load("scenes/level.scene.json"); }
}
)");
        write("scenes/level.scene.json", R"({"format":"factoria.scene/1","entities":[{"id":"cam","components":{"Camera":{}}},
            {"id":"lv","components":{"Transform":{},"Script":{"path":"scripts/level.js"}}}]})");
        write("scripts/level.js", R"(
import { Behaviour } from "factoria";
import { bump } from "./level_helper.js";
export default class Level extends Behaviour { onUpdate() { bump(); } }
)");
        write("scripts/level_helper.js", "let n = 0;\nexport function bump() { n++; }\n");
        write("scripts/autoplay.js", R"(
import { game } from "factoria";
import { choose } from "./bot_helper.js";
game.autoplay((bot) => choose(bot));
)");
        write("scripts/bot_helper.js", "export function choose(bot) { return bot.rng.chance(0.1) ? [\"jump\"] : []; }\n");
    }
    ~TwoScenes() {
        std::error_code ec;
        stdfs::remove_all(dir, ec);
    }
    void write(const char* rel, const std::string& text) const { REQUIRE(fs::write_text((dir / rel).generic_string(), text).ok()); }
    EngineConfig config(LoadOrder* sinkOut) const {
        EngineConfig c;
        c.projectDir = dir.generic_string();
        c.graphics = false;
        c.loadOrderSink = [sinkOut](const LoadOrder& order) { *sinkOut = order; };
        return c;
    }
};

const SceneFiles* find_scene(const LoadOrder& order, const std::string& scene) {
    auto it = std::find_if(order.begin(), order.end(), [&](const SceneFiles& s) { return s.scene == scene; });
    return it == order.end() ? nullptr : &*it;
}

bool has(const std::vector<std::string>& v, const std::string& s) { return std::find(v.begin(), v.end(), s) != v.end(); }

bool anywhere(const LoadOrder& order, const std::string& file) {
    return std::any_of(order.begin(), order.end(), [&](const SceneFiles& s) { return has(s.files, file); });
}

}  // namespace

TEST_CASE("load trace: play.auto records the scene a script loads, its modules and the bot's, and play.report shows the loads") {
    TwoScenes p;
    LoadOrder order;
    PlayAutoOptions o;
    o.seconds = 1.0;  // 60 frames: the level loads on the fifth
    o.screenshots = false;
    auto r = play_auto(p.config(&order), o);
    REQUIRE_MESSAGE(r.ok(), (r.ok() ? std::string() : r.error().message));

    REQUIRE(!order.empty());
    // The engine reads factoria.json by its absolute path (a tool's read, not the game's), so the main scene comes first.
    CHECK(order.front().scene == "scenes/main.scene.json");
    const SceneFiles* mainScene = find_scene(order, "scenes/main.scene.json");
    REQUIRE(mainScene);
    CHECK(mainScene->files.front() == "scenes/main.scene.json");
    CHECK(has(mainScene->files, "scripts/go.js"));
    const SceneFiles* level = find_scene(order, "scenes/level.scene.json");
    REQUIRE(level);  // loaded by a script inside a frame play.auto ran itself
    REQUIRE(!level->files.empty());
    CHECK(level->files.front() == "scenes/level.scene.json");
    CHECK(has(level->files, "scripts/level.js"));
    CHECK(has(level->files, "scripts/level_helper.js"));
    CHECK(anywhere(order, "scripts/autoplay.js"));  // the bot hook is loaded outside any frame
    CHECK(anywhere(order, "scripts/bot_helper.js"));

    // play.report's loading section of the session: both scenes, with their reads.
    auto session = load_json_file((p.dir / ".factoria" / "sessions" / r.value()["session"].get<std::string>() / "session.json").generic_string());
    REQUIRE(session.ok());
    REQUIRE(session.value().contains("loading"));
    const Json& loading = session.value()["loading"];
    REQUIRE(loading.contains("reads"));
    CHECK(loading["reads"]["count"].get<std::uint64_t>() >= 6);
    REQUIRE(loading.contains("scenes"));
    REQUIRE(loading["scenes"].size() == 2);
    CHECK(loading["scenes"][1]["scene"] == "scenes/level.scene.json");
    CHECK(loading["scenes"][1]["files"].get<std::uint64_t>() >= 3);
}

TEST_CASE("load trace: a headless run (factoria run --headless) records the scene a script loads") {
    TwoScenes p;
    LoadOrder order;
    EngineConfig cfg = p.config(&order);
    cfg.headless = true;
    cfg.audioDevice = false;
    cfg.hotReload = false;
    cfg.traceLoads = true;
    HeadlessRunOptions o;
    o.frames = 30;
    Json report;
    CHECK(run_headless(cfg, o, &report) == 0);
    const SceneFiles* level = find_scene(order, "scenes/level.scene.json");
    REQUIRE(level);
    CHECK(level->files.front() == "scenes/level.scene.json");
    CHECK(has(level->files, "scripts/level.js"));
    CHECK(has(level->files, "scripts/level_helper.js"));
    CHECK_FALSE(anywhere(order, "scripts/autoplay.js"));  // nobody plays the bot in a run
}
