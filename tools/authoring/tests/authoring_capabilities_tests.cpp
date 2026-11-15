// The capabilities of the authoring commands (core/capability.h): they declare them, and a game script (the player's, and the
// editor's Play) may not call them. The same checks as engine/runtime/tests/command_capabilities_tests.cpp makes for the
// commands of the player.
#include <doctest.h>

#include <algorithm>
#include <filesystem>
#include <fstream>

#include "fa/authoring/authoring.h"
#include "fa/core/capability.h"
#include "fa/core/fs.h"
#include "fa/runtime/engine.h"

using namespace fa;
namespace stdfs = std::filesystem;

namespace {

const char* kProject = R"({
  "format": "factoria.project/1",
  "name": "Authoring Capabilities Test",
  "id": "com.example.authoringcapabilities",
  "mainScene": "scenes/main.scene.json",
  "display": { "width": 320, "height": 180, "scaleMode": "pixelPerfect" },
  "physics": { "fixedHz": 60, "pixelsPerMeter": 100 }
})";

// A game script that tries the authoring commands from onStart.
const char* kProbeScript = R"JS(
import { Behaviour, fa } from "factoria";
export default class Probe extends Behaviour {
  onStart() {
    globalThis.R = {};
    const tries = {
      "scene.format": { path: "scenes/main.scene.json" },
      "prefab.save": { id: "probe", path: "prefabs/never.prefab.json" },
    };
    for (const name of Object.keys(tries)) {
      try { fa.call(name, tries[name]); globalThis.R[name] = "ok"; }
      catch (e) { globalThis.R[name] = { code: e.code, hint: e.hint }; }
    }
  }
}
)JS";

const char* kProbeScene = R"({
  "format": "factoria.scene/1",
  "entities": [
    { "id": "cam", "name": "Camera", "components": { "Camera": { "clearColor": "#202020" } } },
    { "id": "probe", "components": { "Script": { "path": "scripts/probe.js" } } } ]
})";

struct TempProject {
    stdfs::path dir;
    TempProject() {
        dir = fs::make_temp_dir("fa_authoring_caps_test").value();
        stdfs::create_directories(dir / "scenes");
        stdfs::create_directories(dir / "scripts");
        std::ofstream(dir / "factoria.json", std::ios::binary) << kProject;
        std::ofstream(dir / "scripts/probe.js", std::ios::binary) << kProbeScript;
        std::ofstream(dir / "scenes/main.scene.json", std::ios::binary) << kProbeScene;
    }
    ~TempProject() {
        std::error_code ec;
        stdfs::remove_all(dir, ec);
    }
};

void check_game_script_set(bool editorMode) {
    authoring::install();
    TempProject p;
    EngineConfig c;
    c.projectDir = p.dir.generic_string();
    c.headless = true;
    c.hotReload = false;
    c.editorMode = editorMode;
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(c, nullptr, &err), err);
    for (int i = 0; i < 12; ++i) e.step(1);
    CommandResult r = e.commands().call("script.eval", Json::object({{"code", "globalThis.R"}}));
    REQUIRE_MESSAGE(r.ok, r.error.dump());
    const Json probes = r.result["value"];
    for (const char* denied : {"scene.format", "prefab.save"}) {
        CAPTURE(denied);
        REQUIRE(probes[denied].is_object());
        CHECK(probes[denied]["code"] == "capability_denied");
        const std::string hint = probes[denied]["hint"].get<std::string>();
        CHECK(hint.find(editorMode ? "Play" : "Game scripts get {read, state}") != std::string::npos);
        CHECK(hint.find("factoria call") != std::string::npos);
    }
    CHECK_FALSE(stdfs::exists(p.dir / "prefabs/never.prefab.json"));
    e.shutdown();
}

}  // namespace

TEST_CASE(
    "capabilities: every authoring command declares them, and a game script may not call prefab.save or scene.format") {
    authoring::install();
    TempProject p;
    EngineConfig c;
    c.projectDir = p.dir.generic_string();
    c.headless = true;
    c.hotReload = false;
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(c, nullptr, &err), err);
    const std::vector<std::string> runtime = e.runtime_command_names();
    std::string undeclared, inconsistent;
    int authoringCommands = 0;
    for (const CommandInfo* info : e.commands().list()) {
        if (std::binary_search(runtime.begin(), runtime.end(), info->name)) continue;
        ++authoringCommands;
        if (!info->capabilitiesDeclared) undeclared += " " + info->name;
        if (info->readOnly != info->capabilities.without(Capability::Read).empty()) inconsistent += " " + info->name;
    }
    CHECK(authoringCommands >= 2);
    CHECK_MESSAGE(undeclared.empty(), "commands without a capability declaration:" << undeclared);
    CHECK_MESSAGE(inconsistent.empty(), "readOnly disagrees with the capabilities of:" << inconsistent);
    for (const char* name : {"prefab.save", "scene.format"}) {
        const CommandInfo* info = e.commands().info(name);
        REQUIRE_MESSAGE(info != nullptr, name);
        CHECK_FALSE_MESSAGE(capability_sets::game_player().has_all(info->capabilities), name);
        CHECK_MESSAGE(info->capabilities.has(Capability::WriteProject), name);
    }
    e.shutdown();
}

TEST_CASE("capabilities: game scripts of the player cannot call scene.format or prefab.save") {
    check_game_script_set(false);
}

TEST_CASE("capabilities: the editor's Play cannot call scene.format or prefab.save either") {
    check_game_script_set(true);
}

TEST_CASE(
    "authoring: anim.*, bones.create and skin.* are not commands of the player, and the writers confine their path") {
    authoring::install();
    TempProject p;
    TempProject outside;
    EngineConfig c;
    c.projectDir = p.dir.generic_string();
    c.headless = true;
    c.hotReload = false;
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(c, nullptr, &err), err);
    const std::vector<std::string> runtime = e.runtime_command_names();
    for (const char* name :
         {"anim.create_clip",  "anim.set_keys",     "anim.remove_keys", "anim.move_keys",  "anim.set_interp",
          "anim.add_track",    "anim.remove_track", "anim.add_event",   "anim.move_event", "anim.set_event",
          "anim.remove_event", "anim.set_clip",     "anim.restore",     "anim.list",       "anim.pose",
          "anim.filmstrip",    "anim.check",        "bones.create",     "skin.bind",       "skin.auto_weights",
          "skin.set_weights"}) {
        CAPTURE(name);
        CHECK_FALSE(std::binary_search(runtime.begin(), runtime.end(), std::string(name)));
        CHECK(e.commands().info(name) != nullptr);
    }
    CHECK_FALSE(capability_sets::game_player().has_all(e.commands().info("anim.set_keys")->capabilities));

    auto code = [](const CommandResult& r) { return r.ok ? std::string("ok") : r.error.value("code", std::string()); };
    {
        CommandCallerScope mcp(CommandCaller::Mcp);
        CHECK(code(e.commands().call("anim.create_clip", Json::object({{"path", "../x.anim.json"},
                                                                       {"duration", 1.0}}))) == "path_outside_root");
        CHECK(code(e.commands().call("anim.create_clip",
                                     Json::object({{"path", (outside.dir / "x.anim.json").generic_string()},
                                                   {"duration", 1.0}}))) == "absolute_path_denied");
        CHECK(code(e.commands().call("anim.restore", Json::object({{"path", ".factoria/x.anim.json"},
                                                                   {"clip", nullptr}}))) == "managed_path_denied");
    }
    {
        CommandCapabilityScope readOnly(capability_sets::mcp_read_only());
        CHECK(code(e.commands().call("anim.create_clip", Json::object({{"path", "out/y.anim.json"},
                                                                       {"duration", 1.0}}))) == "capability_denied");
    }
    // The command-line user may name an absolute path.
    CHECK(code(e.commands().call(
              "anim.create_clip",
              Json::object({{"path", (outside.dir / "abs.anim.json").generic_string()}, {"duration", 1.0}}))) == "ok");
    CHECK(stdfs::exists(outside.dir / "abs.anim.json"));
    e.shutdown();
}
