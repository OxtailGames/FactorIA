// Every command the runtime registers declares its capabilities (core/capability.h, docs/ARCHITECTURE.md, "Commands",
// "Capabilities"), and a few of them are checked for the set that matters most: what a game script may and may not call.
#include <doctest.h>

#include <filesystem>
#include <fstream>
#include <functional>
#include <vector>

#include "fa/core/capability.h"
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
        dir = fs::make_temp_dir("fa_capabilities_test").value();
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
    for (const char* n :
         {"scene.spawn", "scene.set_component", "scene.load", "game.step", "game.input", "ui.set_slider", "mesh.create",
          "tilemap.set_tile", "vfx.play", "game.screenshot", "anim.filmstrip", "vfx.filmstrip", "script.eval",
          "game.state", "nav.find_path", "audio.music"})
        CHECK_MESSAGE(capability_sets::game_player().has_all(caps(n)), n);
    // ...and what it may not.
    for (const char* n :
         {"scene.save", "input.record", "mesh.save", "prefab.save", "scene.format", "anim.set_keys", "storage.clear"})
        CHECK_FALSE_MESSAGE(capability_sets::game_player().has_all(caps(n)), n);
    CHECK(caps("storage.clear")
              .has(Capability::WriteProject));  // the game's own save files; an MCP agent resets a game with it
    CHECK(caps("scene.save").has(Capability::WriteProject));
    CHECK_FALSE(caps("scene.save").has(Capability::WriteAnywhere));
}

namespace {

// A game script that tries commands of every kind from onStart, and tilemap.generate with `place` (the library helper that
// used to call scene.import_ascii, a command that can write a file).
const char* kProbeScript = R"JS(
import { Behaviour, fa, tilemap } from "factoria";
export default class Probe extends Behaviour {
  onStart() {
    globalThis.R = {};
    const tries = {
      "scene.spawn": { id: "spawned", components: { Transform: { position: [1, 2] } } },
      "game.state": {},
      "scene.save": { path: "scenes/never.scene.json" },
      "scene.import_ascii": { rows: ["#"], legend: { "#": 0 }, path: "scenes/never.scene.json", save: true },
      "scene.place_ascii": { rows: ["#"], legend: { "#": 0 }, entity: "viaPlace", tilemap: { tileSize: [16, 16] } },
      "scene.format": { path: "scenes/main.scene.json" },
    };
    for (const name of Object.keys(tries)) {
      try { fa.call(name, tries[name]); globalThis.R[name] = "ok"; }
      catch (e) { globalThis.R[name] = { code: e.code, hint: e.hint }; }
    }
    globalThis.job = tilemap.generate({ sample: ["##", "##"], legend: { "#": 0 }, size: [4, 4], seed: 1, n: 2,
                                       place: { entity: "generated", tilemap: { tileSize: [16, 16] } } });
  }
}
)JS";

const char* kProbeScene = R"({
  "format": "factoria.scene/1",
  "entities": [
    { "id": "cam", "name": "Camera", "components": { "Camera": { "clearColor": "#202020" } } },
    { "id": "probe", "components": { "Script": { "path": "scripts/probe.js" } } } ]
})";

void check_game_script_set(bool editorMode) {
    TempProject p;
    stdfs::create_directories(p.dir / "scripts");
    std::ofstream(p.dir / "scripts/probe.js", std::ios::binary) << kProbeScript;
    std::ofstream(p.dir / "scenes/main.scene.json", std::ios::binary) << kProbeScene;
    EngineConfig c;
    c.projectDir = p.dir.generic_string();
    c.headless = true;
    c.hotReload = false;
    c.editorMode = editorMode;
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(c, nullptr, &err), err);
    for (int i = 0; i < 12; ++i) e.step(1);
    auto ev = [&](const std::string& code) {
        CommandResult r = e.commands().call("script.eval", Json::object({{"code", code}}));
        REQUIRE_MESSAGE(r.ok, r.error.dump());
        return r.result["value"];
    };
    const Json r = ev("globalThis.R");
    for (const char* ok : {"scene.spawn", "game.state", "scene.place_ascii"}) {
        CAPTURE(ok);
        CHECK(r[ok] == "ok");
    }
    for (const char* denied : {"scene.save", "scene.import_ascii", "scene.format"}) {
        CAPTURE(denied);
        REQUIRE(r[denied].is_object());
        CHECK(r[denied]["code"] == "capability_denied");
        const std::string hint = r[denied]["hint"].get<std::string>();
        CHECK(hint.find(editorMode ? "Play" : "Game scripts get {read, state}") !=
              std::string::npos);  // the editor's Play says so
        CHECK(hint.find("factoria call") != std::string::npos);
    }
    CHECK(e.world().find("spawned") != Entity{});
    CHECK(e.world().find("viaPlace") != Entity{});
    // tilemap.generate with `place` works from a game script: it places its level with scene.place_ascii.
    CHECK(ev("globalThis.job.done") == true);
    CHECK(ev("globalThis.job.error") == "");
    CHECK(e.world().find("generated") != Entity{});
    CHECK_FALSE(stdfs::exists(p.dir / "scenes/never.scene.json"));
    CHECK(e.scripts().game_capabilities() == capability_sets::game_player());
    e.shutdown();
}

}  // namespace

TEST_CASE(
    "capabilities: the player's game scripts get {read, state}; their helpers (tilemap.generate place) still work") {
    check_game_script_set(false);
}

TEST_CASE("capabilities: the editor's Play gets the same set as the player") { check_game_script_set(true); }

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
        return code != "capability_denied" && code != "absolute_path_denied" && code != "path_outside_root" &&
               code != "managed_path_denied";
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

TEST_CASE("capabilities: scene.place_ascii is scene.import_ascii for the running world only") {
    TempProject p;
    EngineConfig c;
    c.projectDir = p.dir.generic_string();
    c.headless = true;
    c.hotReload = false;
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(c, nullptr, &err), err);
    CHECK(e.commands().info("scene.place_ascii")->capabilities == capability_sets::changes_state());
    for (const char* key : {"path", "from", "save", "dryRun", "edits"}) {
        CAPTURE(key);
        Json a = Json::object({{"rows", Json::array({"#"})}, {"legend", Json::object({{"#", 0}})}});
        a[key] = (std::string(key) == "save" || std::string(key) == "dryRun") ? Json(true) : Json("x");
        CommandResult r = e.commands().call("scene.place_ascii", a);
        REQUIRE_FALSE(r.ok);
        CHECK(r.error["code"] == "invalid_arguments");  // the schema of the twin has no such property
        CHECK(r.error.dump().find(key) != std::string::npos);
    }
    // The explanation of the refused arguments is in the schema (the validation error cannot carry it).
    const Json schema = e.commands().info("scene.place_ascii")->inputSchema;
    REQUIRE(schema.contains("description"));
    CHECK(schema["description"].get<std::string>().find("scene.import_ascii") != std::string::npos);
    e.shutdown();
}

namespace {

// Arguments of every command of the runtime that writes a file at a path its caller gives (M92.2b2), for the path `p`.
// `ext` is the file name ending the command wants.
struct WriterCase {
    const char* command;
    const char* ext;
    std::function<Json(const std::string& p)> args;
};

std::vector<WriterCase> writer_cases(const std::string& mesh) {
    return {
        {"scene.save", ".scene.json", [](const std::string& p) { return Json::object({{"path", p}}); }},
        {"scene.import_ascii", ".scene.json",
         [](const std::string& p) {
             return Json::object(
                 {{"rows", Json::parse(R"(["#."])")}, {"legend", Json::parse(R"({"#":0})")}, {"path", p}});
         }},
        {"scene.ascii_edit", ".json",
         [](const std::string& p) {
             return Json::object({{"file", p}, {"ops", Json::parse(R"([{"op":"put","col":0,"row":0,"glyph":"#"}])")}});
         }},
        {"anim.create_clip", ".anim.json",
         [](const std::string& p) { return Json::object({{"path", p}, {"duration", 1.0}}); }},
        {"anim.restore", ".anim.json",
         [](const std::string& p) { return Json::object({{"path", p}, {"clip", nullptr}}); }},
        {"mesh.save", ".glb", [mesh](const std::string& p) { return Json::object({{"id", mesh}, {"path", p}}); }},
    };
}

std::string error_code(const CommandResult& r) {
    return r.ok ? std::string("ok") : r.error.value("code", std::string());
}

// The path rules refused the call (the command may still fail for its own reasons: a missing file...).
bool path_refused(const std::string& code) {
    return code == "capability_denied" || code == "absolute_path_denied" || code == "path_outside_root" ||
           code == "managed_path_denied" || code == "invalid_path";
}

}  // namespace

TEST_CASE("capabilities: every command that writes a caller's path confines it (M92.2b2)") {
    TempProject p;
    TempProject outside;  // a folder that is not the project
    EngineConfig c;
    c.projectDir = p.dir.generic_string();
    c.headless = true;
    c.hotReload = false;
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(c, nullptr, &err), err);
    const CommandResult mesh =
        e.commands().call("mesh.create", Json::object({{"positions", Json::parse("[[0,0,0],[1,0,0],[1,1,0],[0,1,0]]")},
                                                       {"indices", Json::parse("[0,1,2,0,2,3]")}}));
    REQUIRE_MESSAGE(mesh.ok, mesh.error.dump());
    const std::string meshId = mesh.result["id"].get<std::string>();
    const std::vector<WriterCase> cases = writer_cases(meshId);

    {
        CommandCallerScope mcp(CommandCaller::Mcp);
        for (const WriterCase& w : cases) {
            CAPTURE(w.command);
            const std::string name = std::string("x") + w.ext;
            CHECK(error_code(e.commands().call(w.command, w.args("../" + name))) == "path_outside_root");
            CHECK(error_code(e.commands().call(w.command, w.args((outside.dir / name).generic_string()))) ==
                  "absolute_path_denied");
            CHECK(error_code(e.commands().call(w.command, w.args("/tmp/" + name))) == "absolute_path_denied");
            CHECK(error_code(e.commands().call(w.command, w.args(".git/" + name))) == "managed_path_denied");
            CHECK(error_code(e.commands().call(w.command, w.args(".factoria/" + name))) == "managed_path_denied");
            // A plain project path is not refused by the path rules.
            CHECK_MESSAGE(!path_refused(error_code(e.commands().call(w.command, w.args("out/" + name)))), w.command);
        }
        // The Windows spellings are refused on every system (a project moves between them), and a link into a managed folder too.
        std::error_code lec;
        stdfs::create_directories(p.dir / ".factoria", lec);
        stdfs::create_directory_symlink(p.dir / ".factoria", p.dir / "meta", lec);
        const bool linked = !lec;
        for (const WriterCase& w : cases) {
            CAPTURE(w.command);
            const std::string name = std::string("x") + w.ext;
            CHECK(error_code(e.commands().call(w.command, w.args("scenes\\..\\..\\" + name))) == "path_outside_root");
            CHECK(error_code(e.commands().call(w.command, w.args("..\\" + name))) == "path_outside_root");
            CHECK(error_code(e.commands().call(w.command, w.args("C:" + name))) == "absolute_path_denied");
            CHECK(error_code(e.commands().call(w.command, w.args("C:/" + name))) == "absolute_path_denied");
            CHECK(error_code(e.commands().call(w.command, w.args("C:\\" + name))) == "absolute_path_denied");
            CHECK(error_code(e.commands().call(w.command, w.args("\\\\server\\share\\" + name))) ==
                  "absolute_path_denied");
            CHECK(error_code(e.commands().call(w.command, w.args(".GIT/" + name))) == "managed_path_denied");
            CHECK(error_code(e.commands().call(w.command, w.args(".Factoria/" + name))) == "managed_path_denied");
            CHECK(error_code(e.commands().call(w.command, w.args(".git./" + name))) == "managed_path_denied");
            CHECK(error_code(e.commands().call(w.command, w.args("a/../.git/" + name))) == "managed_path_denied");
            if (linked)
                CHECK(error_code(e.commands().call(w.command, w.args("meta/" + name))) == "managed_path_denied");
            // A name Windows cannot create is refused for a new file ("conx.scene.json" is a normal name).
            CHECK_MESSAGE(!path_refused(error_code(e.commands().call(w.command, w.args("out/con" + name)))), w.command);
            CHECK(error_code(e.commands().call(w.command, w.args("out/nul.x/" + name))) == "invalid_path");
        }
        // input.record: a refused path leaves the recording running; a good one stops it.
        REQUIRE(e.commands().call("input.record", Json::object({{"action", "start"}})).ok);
        for (const char* bad : {"../r.json", "/tmp/r.json", ".git/r.json", ".factoria/r.json"}) {
            CAPTURE(bad);
            const CommandResult r =
                e.commands().call("input.record", Json::object({{"action", "stop"}, {"path", bad}}));
            CHECK(path_refused(error_code(r)));
            CHECK(e.input_recording());
        }
        const CommandResult good =
            e.commands().call("input.record", Json::object({{"action", "stop"}, {"path", "replays/r.json"}}));
        CHECK_MESSAGE(good.ok, good.error.dump());
        CHECK(stdfs::exists(p.dir / "replays" / "r.json"));

        // A path that passes the rules but cannot be written (a folder is there): the recording is stopped, and the error carries the
        // replay and the path tried, so the take is not lost.
        REQUIRE(e.commands().call("input.record", Json::object({{"action", "start"}})).ok);
        stdfs::create_directories(p.dir / "blocked.json");
        const CommandResult failed =
            e.commands().call("input.record", Json::object({{"action", "stop"}, {"path", "blocked.json"}}));
        REQUIRE_FALSE(failed.ok);
        CHECK(error_code(failed) == "failed");
        CHECK_FALSE(e.input_recording());
        REQUIRE(failed.error.contains("data"));
        CHECK(failed.error["data"].value("path", std::string()) == "blocked.json");
        CHECK(failed.error["data"].contains("replay"));
        CHECK(failed.error.value("message", std::string()).find("blocked.json") != std::string::npos);
    }
    CHECK_FALSE(stdfs::exists(outside.dir / "x.scene.json"));
    CHECK_FALSE(stdfs::exists(p.dir / ".git"));

    {
        // A read-only MCP session may not write any of them.
        CommandCapabilityScope readOnly(capability_sets::mcp_read_only());
        for (const WriterCase& w : cases) {
            CAPTURE(w.command);
            CHECK(error_code(e.commands().call(w.command, w.args(std::string("out/y") + w.ext))) ==
                  "capability_denied");
        }
    }

    // The command-line user (and the editor) may name an absolute path.
    CHECK(error_code(e.commands().call(
              "scene.save", Json::object({{"path", (outside.dir / "abs.scene.json").generic_string()}}))) == "ok");
    CHECK(stdfs::exists(outside.dir / "abs.scene.json"));
    CHECK(error_code(e.commands().call(
              "anim.create_clip",
              Json::object({{"path", (outside.dir / "abs.anim.json").generic_string()}, {"duration", 1.0}}))) == "ok");
    CHECK(stdfs::exists(outside.dir / "abs.anim.json"));
    CHECK(error_code(e.commands().call(
              "mesh.save", Json::object({{"id", meshId}, {"path", (outside.dir / "abs.glb").generic_string()}}))) ==
          "ok");
    CHECK(stdfs::exists(outside.dir / "abs.glb"));
    // An absolute path inside the project is the same file as the relative one and is kept in its relative spelling.
    const CommandResult inside = e.commands().call(
        "scene.save", Json::object({{"path", (p.dir / "scenes" / "inside.scene.json").generic_string()}}));
    REQUIRE_MESSAGE(inside.ok, inside.error.dump());
    CHECK(inside.result["saved"] == "scenes/inside.scene.json");
    // The managed folders stay closed to the user too; the scratch folder is open.
    CHECK(error_code(e.commands().call("scene.save", Json::object({{"path", ".git/x.scene.json"}}))) ==
          "managed_path_denied");
    CHECK(error_code(e.commands().call("scene.save", Json::object({{"path", ".factoria/x.scene.json"}}))) ==
          "managed_path_denied");
    CHECK(error_code(e.commands().call("scene.save", Json::object({{"path", ".factoria/tmp/x.scene.json"}}))) == "ok");
}
