// A game run from a game pack (fa::fs::mount_pack, fa/core/pack.h): what the player does for a `--release` desktop export.
#include <doctest.h>

#include <filesystem>
#include <cstring>

#include "fa/core/fs.h"
#include "fa/core/image.h"
#include "fa/core/pack.h"
#include "fa/runtime/engine.h"
#include "fa/runtime/project.h"
#include "fa/script/bytecode.h"

using namespace fa;
namespace stdfs = std::filesystem;

namespace {

const char* kPackProject = R"({
  "format": "factoria.project/1",
  "name": "Pack Game",
  "id": "com.example.packgame",
  "mainScene": "scenes/main.scene.json",
  "icon": "assets/dot.png",
  "display": { "width": 320, "height": 180, "scaleMode": "pixelPerfect" },
  "physics": { "fixedHz": 60, "pixelsPerMeter": 100 }
})";

const char* kPackScene = R"({
  "format": "factoria.scene/1",
  "entities": [
    { "id": "cam", "name": "Camera", "components": { "Camera": { "clearColor": "#203040" } } },
    { "id": "ground", "name": "Ground",
      "components": { "Transform": { "position": [0, -70, 0] }, "Shape2D": { "size": [300, 20], "color": "#40a040" },
                      "RigidBody2D": { "type": "static" }, "Collider2D": { "size": [300, 20] } } },
    { "id": "ball", "name": "Ball",
      "components": { "Transform": { "position": [0, 60, 0] }, "Sprite": { "texture": "assets/dot.png", "size": [20, 20] },
                      "RigidBody2D": {}, "Collider2D": { "shape": "circle", "radius": 10 },
                      "Script": { "path": "scripts/counter.js", "props": { "step": 2 } } } }
  ]
})";

// Counts its own updates (the proof that the script ran) and imports a module and a JSON file, as games do.
const char* kCounterScript = R"(// UNIQUE_COMMENT_COUNTER
import { Behaviour } from "factoria";
import { twice } from "./lib/util.js";
import tuning from "../data/tuning.json";
export default class Counter extends Behaviour {
  step = 1;
  count = 0;
  onUpdate() { this.count += twice(this.step) + tuning.bonus; globalThis.COUNT = this.count; }
}
)";

// A game folder on disk, packed the way an export does it (scripts compiled), then DELETED: only the pack is left.
struct PackedGame {
    stdfs::path dir;       // holds game.pak; the (absent) game/ folder inside it is the project root, like next to the player's exe
    stdfs::path projectDir;

    explicit PackedGame(const std::string& name, bool bytecode = true, const char* counter = kCounterScript) {
        dir = fs::make_temp_dir("fa_runtime_pack_" + name);
        projectDir = dir / "game";
        Image dot;
        dot.width = dot.height = 2;
        dot.rgba = {255, 255, 255, 255, 255, 0, 0, 255, 0, 255, 0, 255, 0, 0, 255, 255};
        const auto png = encode_png(dot);

        PackWriter w;
        auto text = [](const char* s) { return std::vector<std::uint8_t>(s, s + std::strlen(s)); };
        auto add_script = [&](const std::string& path, const std::string& source) {
            if (bytecode) {
                auto bc = compile_script_bytecode(source, path);
                REQUIRE_MESSAGE(bc.ok(), (bc.ok() ? "" : bc.error().to_string()));
                REQUIRE(w.add_bytes(path, std::move(bc.value())).ok());
            } else {
                REQUIRE(w.add_bytes(path, std::vector<std::uint8_t>(source.begin(), source.end())).ok());
            }
        };
        REQUIRE(w.add_bytes("factoria.json", text(kPackProject)).ok());
        REQUIRE(w.add_bytes("scenes/main.scene.json", text(kPackScene)).ok());
        REQUIRE(w.add_bytes("assets/dot.png", std::vector<std::uint8_t>(png.begin(), png.end())).ok());
        REQUIRE(w.add_bytes("data/tuning.json", text("{\"bonus\": 1}")).ok());
        add_script("scripts/counter.js", counter);
        add_script("scripts/lib/util.js", "export const twice = (n) => n * 2;\n");
        REQUIRE(w.write(dir / "game.pak").ok());
    }
    ~PackedGame() {
        fs::unmount_pack();
        std::error_code ec;
        stdfs::remove_all(dir, ec);
    }
    EngineConfig config() const {
        EngineConfig c;
        c.projectDir = projectDir.generic_string();
        c.headless = true;
        c.hotReload = false;
        return c;
    }
};

}  // namespace

TEST_CASE("pack: load_project reads factoria.json out of the mounted pack") {
    PackedGame g("project");
    REQUIRE(fs::mount_pack(g.dir / "game.pak").ok());
    fs::set_project_root(g.projectDir);
    auto project = load_project(g.projectDir.generic_string());
    REQUIRE_MESSAGE(project.ok(), (project.ok() ? "" : project.error().to_string()));
    CHECK(project->name == "Pack Game");
    CHECK(project->mainScene == "scenes/main.scene.json");
    CHECK(project->width == 320);
}

TEST_CASE("pack: an Engine runs the game from a mounted pack for some frames") {
    for (const bool bytecode : {true, false}) {
        CAPTURE(bytecode);
        PackedGame g(bytecode ? "run_bc" : "run_src", bytecode);
        REQUIRE_FALSE(stdfs::exists(g.projectDir));  // there is no game/ folder and no loose file: the pack is all there is
        REQUIRE(fs::mount_pack(g.dir / "game.pak").ok());

        Engine e;
        std::string err;
        REQUIRE_MESSAGE(e.init(g.config(), nullptr, &err), err);
        REQUIRE(e.renderer() != nullptr);
        CHECK(e.world().entity_count() == 3);
        CHECK(e.state()["scene"] == "scenes/main.scene.json");
        CHECK(e.state()["sceneIssues"].empty());  // the scene and the sprite's texture were found in the pack

        e.step(120);
        const Json s = e.state();
        CHECK(e.frame_index() == 120);
        CHECK(s["scriptErrors"].empty());
        double y = 0;
        for (const Json& ent : s["entities"])
            if (ent["id"] == "ball") y = ent["components"]["Transform"]["position"][1].get<double>();
        CHECK(y < 40);   // physics ran: the ball fell
        CHECK(y > -70);  // and rests on the ground
        // The script ran 120 updates: every one adds twice(step=2) + tuning.bonus(1) = 5, through the imported module and JSON.
        auto count = e.scripts().eval("globalThis.COUNT");
        REQUIRE(count.ok());
        CHECK(count->get<int>() == 600);

        // A frame can be drawn from the pack's texture.
        auto shot = e.commands().call("game.screenshot", Json::object());
        CHECK_MESSAGE(shot.ok, (shot.ok ? "" : shot.error.dump()));
        e.shutdown();
        fs::unmount_pack();
    }
}

TEST_CASE("pack: assets.list answers from the pack, with sizes") {
    PackedGame g("assets");
    REQUIRE(fs::mount_pack(g.dir / "game.pak").ok());
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(g.config(), nullptr, &err), err);
    auto r = e.commands().call("assets.list", Json::parse(R"({"folder":"assets"})"));
    REQUIRE(r.ok);
    REQUIRE(r.result["count"] == 1);
    CHECK(r.result["files"][0]["path"] == "assets/dot.png");
    CHECK(r.result["files"][0]["type"] == "texture");
    CHECK(r.result["files"][0]["size"].get<int>() > 0);
    e.shutdown();
}

TEST_CASE("pack: a missing start scene in the pack is reported like in a folder, with the pack's scenes as hint") {
    PackedGame g("noscene");
    REQUIRE(fs::mount_pack(g.dir / "game.pak").ok());
    EngineConfig c = g.config();
    c.scene = "scenes/mian.scene.json";
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(c, nullptr, &err), err);
    const Json s = e.state();
    REQUIRE(s["sceneIssues"].size() == 1);
    CHECK(s["sceneIssues"][0].get<std::string>().find("scenes/main.scene.json") != std::string::npos);
    e.shutdown();
}

TEST_CASE("pack: a script that fails inside a compiled module reports its file and line in the running game") {
    PackedGame g("scripterr", true,
                 "import { Behaviour } from 'factoria';\n\nexport default class Counter extends Behaviour {\n"
                 "  onUpdate() { this.nothing.x = 1; }\n}\n");
    REQUIRE(fs::mount_pack(g.dir / "game.pak").ok());
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(g.config(), nullptr, &err), err);
    e.step(3);
    const Json s = e.state();
    REQUIRE(s["scriptErrors"].size() >= 1);
    const Json& first = s["scriptErrors"][0];
    CHECK(first["file"] == "scripts/counter.js");
    CHECK(first["line"] == 4);
    e.shutdown();
}
