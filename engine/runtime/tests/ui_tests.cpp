// The game UI through the whole engine: default ui_* actions, the ui.state command, and a menu driven only by game.gamepad()
// taps from a JavaScript test (ui.on, ui.focus, ui.focused).
#include <doctest.h>

#include <algorithm>
#include <filesystem>
#include <fstream>

#include "fa/core/fs.h"
#include "fa/runtime/engine.h"

using namespace fa;
namespace stdfs = std::filesystem;

namespace {

const char* kProject = R"({
  "format": "factoria.project/1",
  "name": "Ui Test",
  "id": "com.example.uitest",
  "mainScene": "scenes/main.scene.json",
  "display": { "width": 320, "height": 180, "scaleMode": "pixelPerfect" },
  "input": { "actions": { "jump": ["Space"] } }
})";

// A main menu: a column Panel with four widgets; "play" asks for the focus.
const char* kMenu = R"({
  "format": "factoria.scene/1",
  "entities": [
    { "id": "cam", "components": { "Camera": {} } },
    { "id": "menu",
      "components": { "Transform": { "position": [160, 20] },
                      "Panel": { "size": [240, 140], "pivot": [0.5, 1], "layout": "column", "spacing": 8, "padding": [8, 8, 8, 8] } },
      "children": [
        { "id": "play", "components": { "Button": { "text": "Play", "size": [200, 30], "autoFocus": true } } },
        { "id": "options", "components": { "Button": { "text": "Options", "size": [200, 30] } } },
        { "id": "music", "components": { "Slider": { "label": "Music", "value": 0.5, "step": 0.1, "size": [200, 30] } } },
        { "id": "sound", "components": { "Toggle": { "label": "Sound", "size": [200, 30] } } }
      ] }
  ]
})";

const char* kMenuTest = R"JS(
import { test, expect, game } from "factoria:test";
import { ui } from "factoria";
import menu from "../scenes/main.scene.json";

function record() {
  const log = [];
  const stops = ["focus", "click", "change", "submit", "cancel"].map((type) =>
    ui.on(type, (e) => log.push(e.type + ":" + e.id + (e.value === undefined ? "" : "=" + e.value))));
  return { log, stop: () => stops.forEach((s) => s()) };
}

test("the gamepad alone walks the menu: focus, click, slider, toggle, cancel", () => {
  game.loadJson(menu);
  const r = record();
  game.step(1);
  expect(ui.focused.id).toBe("play");              // autoFocus takes the focus when nothing has it
  expect(r.log).toEqual(["focus:play"]);
  const pad = game.gamepad();
  pad.tap("A");
  expect(r.log.slice(1)).toEqual(["click:play"]);
  pad.tap("DpadDown");
  pad.tap("DpadDown");
  expect(ui.focused.id).toBe("music");
  pad.tap("DpadRight");                            // left / right on a slider change its value by `step`
  expect(ui.focused.get("Slider").value).toBeCloseTo(0.6, 3);
  pad.tap("DpadDown");
  pad.tap("A");                                    // submit on a toggle flips it
  pad.tap("B");                                    // cancel carries the focused widget
  expect(r.log.slice(2)).toEqual(["focus:options", "focus:music", "change:music=0.6", "focus:sound", "change:sound=true", "cancel:sound"]);
  for (let i = 0; i < 4; i++) pad.tap("DpadUp");   // the top is the end: the focus stays on play, no wrap
  expect(ui.focused.id).toBe("play");
  r.stop();
});

test("ui.on can listen to one widget; ui.focus and ui.on explain mistakes", () => {
  game.loadJson(menu);
  game.step(1);
  const seen = [];
  const stop = ui.on("click", "options", (e) => seen.push(e.id + "/" + e.entity.id));
  game.gamepad().tap("A");                         // play is focused: a click, but not on "options"
  expect(seen).toEqual([]);
  ui.focus("options");
  expect(ui.focused.id).toBe("options");
  game.gamepad().tap("A");
  expect(seen).toEqual(["options/options"]);
  stop();
  game.gamepad().tap("A");
  expect(seen.length).toBe(1);                     // unsubscribed
  expect(() => ui.focus("menu")).toThrow(/container/);
  expect(() => ui.on("clik", () => {})).toThrow(/did you mean "click"/);
  expect(() => ui.on("click", "play")).toThrow(/function/);
  ui.focus(null);
  expect(ui.focused).toBeNull();
  expect(ui.hovered).toBeNull();
});
)JS";

struct TempProject {
    stdfs::path dir;
    explicit TempProject(const std::string& name, const char* project = kProject) {
        dir = fs::make_temp_dir("fa_ui_runtime_test_" + name);
        write("factoria.json", project);
        write("scenes/main.scene.json", kMenu);
    }
    ~TempProject() {
        std::error_code ec;
        stdfs::remove_all(dir, ec);
    }
    void write(const std::string& rel, const std::string& text) const {
        stdfs::create_directories((dir / rel).parent_path());
        std::ofstream(dir / rel, std::ios::binary) << text;
    }
    EngineConfig config() const {
        EngineConfig c;
        c.projectDir = dir.generic_string();
        c.headless = true;
        c.hotReload = false;
        return c;
    }
};

}  // namespace

TEST_CASE("ui: the default ui_* actions exist unless the project defines them") {
    TempProject p("actions", R"({"name":"x","input":{"actions":{"ui_submit":["F"],"jump":["Space"]}}})");
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(p.config(), nullptr, &err), err);
    auto info = e.commands().call("project.info", Json::object());
    REQUIRE(info.ok);
    std::vector<std::string> names;
    for (const Json& a : info.result["inputActions"]) names.push_back(a.get<std::string>());
    for (const char* a : {"ui_up", "ui_down", "ui_left", "ui_right", "ui_submit", "ui_cancel", "jump"})
        CHECK(std::find(names.begin(), names.end(), a) != names.end());
    // the project's own ui_submit wins: F submits and Enter does not
    e.input().on_key(Key::Enter, true);
    CHECK_FALSE(e.input().action_pressed("ui_submit"));
    e.input().on_key(Key::F, true);
    CHECK(e.input().action_pressed("ui_submit"));
    e.shutdown();
}

TEST_CASE("ui.state lists the widgets in reading order with their rectangles and values") {
    TempProject p("state");
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(p.config(), nullptr, &err), err);
    const CommandInfo* info = e.commands().info("ui.state");
    REQUIRE(info != nullptr);
    CHECK(info->readOnly);
    CHECK(info->description.find("Example") != std::string::npos);
    e.step(2);
    auto r = e.commands().call("ui.state", Json::object());
    REQUIRE_MESSAGE(r.ok, r.error.dump());
    CHECK(r.result["focused"] == "play");  // autoFocus
    CHECK(r.result["hovered"].is_null());
    const Json& w = r.result["widgets"];
    REQUIRE(w.size() == 5);
    const char* order[5] = {"menu", "play", "options", "music", "sound"};
    for (int i = 0; i < 5; ++i) CHECK(w[std::size_t(i)]["id"] == order[i]);
    CHECK(w[0]["kind"] == "Panel");
    CHECK(w[1]["kind"] == "Button");
    CHECK(w[1]["text"] == "Play");
    CHECK(w[1]["focused"].get<bool>());
    CHECK_FALSE(w[2]["focused"].get<bool>());
    // the column puts the widgets in the middle of the panel (x 40..280, y 20..160, padding 8, spacing 8)
    CHECK(w[1]["rect"] == Json::parse("[60, 28, 200, 30]"));
    CHECK(w[2]["rect"] == Json::parse("[60, 66, 200, 30]"));
    CHECK(w[3]["value"] == 0.5);
    CHECK(w[3]["text"] == "Music");
    CHECK(w[4]["value"] == false);
    CHECK(w[1]["visible"].get<bool>());
    e.shutdown();
}

TEST_CASE("ui: a menu is driven by gamepad taps from a JavaScript test") {
    TempProject p("js");
    p.write("tests/ui.test.js", kMenuTest);
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(p.config(), nullptr, &err), err);
    auto t = e.commands().call("project.test", Json::object());
    REQUIRE_MESSAGE(t.ok, t.error.dump());
    CHECK_MESSAGE(t.result["ok"].get<bool>(), t.result.dump(2));
    CHECK(t.result["passed"].get<int>() == 2);
    e.shutdown();
}
