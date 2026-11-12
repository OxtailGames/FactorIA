// Every command the runtime registers declares its capabilities (core/capability.h, docs/ARCHITECTURE.md, "Commands",
// "Capabilities"), and a few of them are checked for the set that matters most: what a game script may and may not call.
#include <doctest.h>

#include <filesystem>
#include <fstream>

#include "fa/core/fs.h"
#include "fa/runtime/engine.h"

using namespace fa;
namespace stdfs = std::filesystem;

namespace {

const char* kProject = R"({
  "format": "factoria.project/1",
  "name": "Capabilities Test",
  "id": "com.example.capabilities",
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
        dir = fs::make_temp_dir("fa_capabilities_test");
        stdfs::create_directories(dir / "scenes");
        std::ofstream(dir / "factoria.json", std::ios::binary) << kProject;
        std::ofstream(dir / "scenes/main.scene.json", std::ios::binary) << kScene;
    }
    ~TempProject() {
        std::error_code ec;
        stdfs::remove_all(dir, ec);
    }
};

}  // namespace

TEST_CASE("capabilities: every command of the runtime declares them, and readOnly agrees") {
    TempProject p;
    EngineConfig c;
    c.projectDir = p.dir.generic_string();
    c.headless = true;
    c.hotReload = false;
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(c, nullptr, &err), err);
    const Json all = e.commands().describe();
    REQUIRE(all.size() > 100);
    std::string undeclared, inconsistent;
    for (const Json& d : all) {
        const std::string name = d["name"].get<std::string>();
        const CommandInfo* info = e.commands().info(name);
        REQUIRE(info != nullptr);
        if (!info->capabilitiesDeclared) undeclared += " " + name;
        if (info->readOnly != info->capabilities.without(Capability::Read).empty()) inconsistent += " " + name;
        CHECK_MESSAGE(info->capabilities.has(Capability::Read), name);
    }
    CHECK_MESSAGE(undeclared.empty(), "commands without a capability declaration:" << undeclared);
    CHECK_MESSAGE(inconsistent.empty(), "readOnly disagrees with the capabilities of:" << inconsistent);

    auto caps = [&](const char* name) { return e.commands().info(name)->capabilities; };
    // What a game script may call (read + state)...
    for (const char* n : {"scene.spawn", "scene.set_component", "scene.load", "game.step", "game.input", "ui.set_slider", "mesh.create", "tilemap.set_tile",
                          "vfx.play", "script.eval", "game.state", "nav.find_path", "audio.music"})
        CHECK_MESSAGE(capability_sets::game_player().has_all(caps(n)), n);
    // ...and what it may not.
    for (const char* n : {"scene.save", "input.record", "game.screenshot", "mesh.save", "prefab.save", "scene.format", "anim.set_keys",
                          "scene.import_ascii", "vfx.filmstrip", "storage.clear"})
        CHECK_FALSE_MESSAGE(capability_sets::game_player().has_all(caps(n)), n);
    CHECK(caps("storage.clear").has(Capability::WriteProject));  // the game's own save files; an MCP agent resets a game with it
    CHECK(caps("scene.save").has(Capability::WriteProject));
    CHECK_FALSE(caps("scene.save").has(Capability::WriteAnywhere));
}
