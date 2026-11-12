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
                          "vfx.play", "game.screenshot", "anim.filmstrip", "vfx.filmstrip", "script.eval", "game.state", "nav.find_path", "audio.music"})
        CHECK_MESSAGE(capability_sets::game_player().has_all(caps(n)), n);
    // ...and what it may not.
    for (const char* n : {"scene.save", "input.record", "mesh.save", "prefab.save", "scene.format", "anim.set_keys",
                          "scene.import_ascii", "storage.clear"})
        CHECK_FALSE_MESSAGE(capability_sets::game_player().has_all(caps(n)), n);
    CHECK(caps("storage.clear").has(Capability::WriteProject));  // the game's own save files; an MCP agent resets a game with it
    CHECK(caps("scene.save").has(Capability::WriteProject));
    CHECK_FALSE(caps("scene.save").has(Capability::WriteAnywhere));
}

TEST_CASE("capabilities: the path of game.screenshot needs writeProject and stays inside the project") {
    TempProject p;
    EngineConfig c;
    c.projectDir = p.dir.generic_string();
    c.headless = true;
    c.hotReload = false;
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(c, nullptr, &err), err);
    auto code_of = [&](const char* path) {
        const CommandResult r = e.commands().call("game.screenshot", Json::object({{"path", path}}));
        return r.ok ? std::string("ok") : r.error.value("code", std::string());
    };
    // Without a GPU the picture itself may fail ("unavailable"), so these check only that the path was not refused.
    auto not_refused = [&](const std::string& code) {
        return code != "capability_denied" && code != "absolute_path_denied" && code != "path_outside_root" && code != "managed_path_denied";
    };
    {
        CommandCallerScope mcp(CommandCaller::Mcp);
        CHECK(not_refused(code_of("shots/a.png")));
        CHECK(code_of("/tmp/x.png") == "absolute_path_denied");
        CHECK(code_of("../x.png") == "path_outside_root");
        CHECK(code_of(".git/x.png") == "managed_path_denied");
        CHECK(code_of(".factoria/x.png") == "managed_path_denied");
        const CommandResult none = e.commands().call("game.screenshot");
        CHECK(not_refused(none.ok ? "ok" : none.error.value("code", std::string())));
    }
    {
        CommandCapabilityScope readOnly(capability_sets::mcp_read_only());
        const CommandResult r = e.commands().call("game.screenshot", Json::object({{"path", "shots/a.png"}}));
        REQUIRE_FALSE(r.ok);
        CHECK(r.error["code"] == "capability_denied");
        CHECK(r.error["data"]["missing"] == Json::parse(R"(["writeProject"])"));
        const CommandResult none = e.commands().call("game.screenshot");  // no path: only {read, state}
        CHECK((none.ok || none.error.value("code", std::string()) != "capability_denied"));
    }
    {
        CommandCapabilityScope script(capability_sets::game_player());  // what fa.call from a game script has
        const CommandResult none = e.commands().call("game.screenshot");
        CHECK((none.ok || none.error.value("code", std::string()) != "capability_denied"));
        CHECK(code_of("shots/a.png") == "capability_denied");
    }
    CHECK_FALSE(stdfs::exists(p.dir / "x.png"));
}
