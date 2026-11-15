// fa_authoring and the command extension hook of fa_runtime (fa/runtime/command_extension.h): the player's command set has no
// authoring commands, an Engine of a process that called fa::authoring::install() has them, install() can be repeated.
#include <doctest.h>

#include <algorithm>
#include <atomic>
#include <filesystem>
#include <fstream>

#include "fa/authoring/authoring.h"
#include "fa/core/fs.h"
#include "fa/runtime/command_extension.h"
#include "fa/runtime/engine.h"

using namespace fa;
namespace stdfs = std::filesystem;

namespace {

const char* kProject = R"({
  "format": "factoria.project/1",
  "name": "Authoring Test",
  "id": "com.example.authoringtest",
  "mainScene": "scenes/main.scene.json",
  "display": { "width": 320, "height": 180, "scaleMode": "pixelPerfect" },
  "physics": { "fixedHz": 60, "pixelsPerMeter": 100 }
})";

const char* kScene = R"({
  "format": "factoria.scene/1",
  "entities": [ { "id": "cam", "name": "Camera", "components": { "Camera": { "clearColor": "#202020" } } } ]
})";

struct TempProject {
    stdfs::path dir;
    TempProject() {
        dir = fs::make_temp_dir("fa_authoring_test").value();
        stdfs::create_directories(dir / "scenes");
        std::ofstream(dir / "factoria.json", std::ios::binary) << kProject;
        std::ofstream(dir / "scenes/main.scene.json", std::ios::binary) << kScene;
    }
    ~TempProject() {
        std::error_code ec;
        stdfs::remove_all(dir, ec);
    }
    EngineConfig config() const {
        EngineConfig c;
        c.projectDir = dir.generic_string();
        c.headless = true;
        c.hotReload = false;
        return c;
    }
};

bool contains(const std::vector<std::string>& names, const std::string& name) {
    return std::find(names.begin(), names.end(), name) != names.end();
}

}  // namespace

TEST_CASE("authoring: install() registers one extension, and a second call changes nothing") {
    authoring::install();
    authoring::install();
    const std::vector<std::string> names = command_extension_names();
    CHECK(std::count(names.begin(), names.end(), "authoring") == 1);
    CHECK_FALSE(register_command_extension("authoring", [](Engine&) {}));  // the name is taken: nothing added
    const std::vector<std::string> after = command_extension_names();
    CHECK(std::count(after.begin(), after.end(), "authoring") == 1);
}

TEST_CASE("authoring: the runtime command set (the player's) lacks the authoring commands, an Engine here has them") {
    authoring::install();
    TempProject p;
    Engine e;
    CHECK(e.runtime_command_names().empty());  // before init
    std::string err;
    REQUIRE_MESSAGE(e.init(p.config(), nullptr, &err), err);

    const std::vector<std::string> runtime = e.runtime_command_names();
    REQUIRE_FALSE(runtime.empty());
    CHECK(std::is_sorted(runtime.begin(), runtime.end()));
    // What a player has...
    CHECK(contains(runtime, "scene.save"));
    CHECK(contains(runtime, "tilemap.generate"));
    CHECK(contains(runtime, "game.step"));
    // ...and what only the tools add.
    CHECK_FALSE(contains(runtime, "scene.format"));
    CHECK_FALSE(contains(runtime, "prefab.save"));
    CHECK(e.commands().has("scene.format"));
    CHECK(e.commands().has("prefab.save"));
    // Every runtime command is still there, and the engine has more commands than the player.
    for (const std::string& name : runtime) CHECK_MESSAGE(e.commands().has(name), name);
    CHECK(e.commands().list().size() > runtime.size());
    e.shutdown();
}

namespace {
std::atomic<bool> g_pingArmed{false};
}

TEST_CASE("authoring: a command extension runs after the built-in commands, in Engine::init, for each engine") {
    // An extension that is armed only by this test, so no other test of this process sees its command.
    REQUIRE(register_command_extension("authoring-test-ping", [](Engine& engine) {
        if (!g_pingArmed) return;
        // The built-ins are registered already when an extension runs.
        CHECK(engine.commands().has("scene.save"));
        engine.commands().add({"authoring_test.ping", "Test command.",
                               "Answers {pong: true}. Example: authoring_test.ping {}",
                               Json::parse(R"({"type":"object","properties":{}})"), true, "test"},
                              [](const Json&) { return Json::object({{"pong", true}}); });
    }));
    TempProject p;
    g_pingArmed = true;
    Engine armed;
    std::string err;
    REQUIRE_MESSAGE(armed.init(p.config(), nullptr, &err), err);
    g_pingArmed = false;
    CHECK(armed.commands().call("authoring_test.ping").result["pong"] == true);
    // It is an extension's command, not a runtime one.
    CHECK_FALSE(contains(armed.runtime_command_names(), "authoring_test.ping"));
    armed.shutdown();

    Engine later;
    REQUIRE_MESSAGE(later.init(p.config(), nullptr, &err), err);
    CHECK_FALSE(later.commands().has("authoring_test.ping"));  // disarmed: the extension ran and added nothing
    later.shutdown();
}
