// scene.save leaves out the entities a script spawned at runtime (they come back when the script runs again).
#include <doctest.h>

#include <filesystem>
#include <fstream>

#include "fa/core/fs.h"
#include "fa/runtime/engine.h"
#include "fa/scene/serialize.h"

using namespace fa;
namespace stdfs = std::filesystem;

namespace {

const char* kProject = R"({
  "format": "factoria.project/1",
  "name": "Spawn Save Test",
  "id": "com.example.spawnsave",
  "mainScene": "scenes/main.scene.json",
  "display": { "width": 320, "height": 180, "scaleMode": "pixelPerfect" },
  "physics": { "fixedHz": 60, "pixelsPerMeter": 100 }
})";

const char* kScene = R"({
  "format": "factoria.scene/1",
  "entities": [
    { "id": "hero", "components": { "Transform": { "position": [10, 0, 0] } } },
    { "id": "builder", "components": { "Script": { "path": "scripts/builder.js" } } }
  ]
})";

const char* kScript = R"JS(
import { Behaviour, world } from 'factoria';
export default class Builder extends Behaviour {
  onStart() {
    const group = world.spawn({ id: 'spawned_group', name: 'Group', components: { Transform: { position: [1, 2, 0] } },
                                children: [{ id: 'spawned_kid', components: { Transform: { position: [3, 0, 0] } } }] });
    world.spawn({ id: 'spawned_loose', components: { Shape2D: { size: [4, 4] } } });
    world.spawn({ id: 'under_hero', components: {} }, world.find('hero'));
  }
}
)JS";

struct Session {
    stdfs::path dir;
    Engine engine;
    Session() {
        dir = fs::make_temp_dir("fa_spawnsave_test");
        stdfs::create_directories(dir / "scenes");
        stdfs::create_directories(dir / "scripts");
        std::ofstream(dir / "factoria.json", std::ios::binary) << kProject;
        std::ofstream(dir / "scenes/main.scene.json", std::ios::binary) << kScene;
        std::ofstream(dir / "scripts/builder.js", std::ios::binary) << kScript;
        EngineConfig c;
        c.projectDir = dir.generic_string();
        c.headless = true;
        c.hotReload = false;
        std::string err;
        REQUIRE_MESSAGE(engine.init(c, nullptr, &err), err);
        engine.step(2);  // onStart runs
    }
    ~Session() {
        engine.shutdown();
        std::error_code ec;
        stdfs::remove_all(dir, ec);
    }
    CommandResult call(const std::string& cmd, const char* args) { return engine.commands().call(cmd, Json::parse(args)); }
    std::string read(const char* rel) {
        std::ifstream f(dir / rel, std::ios::binary);
        return std::string(std::istreambuf_iterator<char>(f), {});
    }
};

}  // namespace

TEST_CASE("scene.save: entities a script spawned are left out, authored ones are saved, and the result says so") {
    Session s;
    REQUIRE(s.engine.world().find_by_id("spawned_loose").is_null() == false);  // the script did run
    REQUIRE(s.call("scene.spawn", R"({"id":"authored","name":"Authored"})").ok);
    auto r = s.call("scene.save", R"({"path":"scenes/out.scene.json"})");
    REQUIRE_MESSAGE(r.ok, r.error.dump());
    const std::string text = s.read("scenes/out.scene.json");
    CHECK(text.find("\"authored\"") != std::string::npos);
    CHECK(text.find("\"hero\"") != std::string::npos);
    CHECK(text.find("spawned_loose") == std::string::npos);
    CHECK(text.find("spawned_group") == std::string::npos);
    CHECK(text.find("spawned_kid") == std::string::npos);  // children of a spawned entity go with it
    CHECK(text.find("under_hero") == std::string::npos);   // a spawned child of an authored entity too
    CHECK(r.result["skippedSpawned"]["count"] == 4);       // group + kid + loose + under_hero
    CHECK(r.result["skippedSpawned"]["first"].size() == 3);
    CHECK(r.result["hint"].get<std::string>().find("includeSpawned") != std::string::npos);
    // The running world keeps them.
    CHECK_FALSE(s.engine.world().find_by_id("spawned_kid").is_null());
}

TEST_CASE("scene.save: includeSpawned bakes the spawned entities on request") {
    Session s;
    auto r = s.call("scene.save", R"({"path":"scenes/all.scene.json","includeSpawned":true})");
    REQUIRE_MESSAGE(r.ok, r.error.dump());
    const std::string text = s.read("scenes/all.scene.json");
    CHECK(text.find("spawned_loose") != std::string::npos);
    CHECK(text.find("spawned_kid") != std::string::npos);
    CHECK(text.find("under_hero") != std::string::npos);
    CHECK_FALSE(r.result.contains("skippedSpawned"));
}

TEST_CASE("save_scene keeps spawned entities for snapshots (Play/Stop, undo) unless asked to skip them") {
    Session s;
    Json all = save_scene(s.engine.world());
    CHECK(all.dump().find("spawned_kid") != std::string::npos);
    SpawnedSkip skip;
    Json file = save_scene(s.engine.world(), true, &skip);
    CHECK(file.dump().find("spawned_kid") == std::string::npos);
    CHECK(skip.count == 4);
}
