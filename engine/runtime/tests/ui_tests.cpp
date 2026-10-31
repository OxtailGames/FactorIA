// The game UI through the whole engine: default ui_* actions, the ui.state command, and a menu driven only by game.gamepad()
// taps from a JavaScript test (ui.on, ui.focus, ui.focused).
#include <doctest.h>

#include <algorithm>
#include <chrono>
#include <filesystem>
#include <fstream>

#include "fa/core/fs.h"
#include "fa/runtime/engine.h"
#include "fa/runtime/project.h"

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
import { ui, world } from "factoria";
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

test("game.setSlider drags like a player: ui.change once, clamped and snapped; a script write sends nothing", () => {
  game.loadJson(menu);
  game.step(1);
  const seen = [];
  const stop = ui.on("change", "music", (e) => seen.push(e.value));
  const slider = game.find("music").get("Slider");
  slider.value = 0.2;                              // from a script: no event
  game.step(1);
  expect(seen).toEqual([]);
  game.setSlider("music", 0.84);                   // step 0.1
  game.step(1);
  expect(seen).toEqual([0.8]);
  expect(slider.value).toBeCloseTo(0.8, 5);
  expect(ui.focused.id).toBe("music");
  game.setSlider("music", 7);
  game.step(1);
  expect(seen).toEqual([0.8, 1]);
  game.setSlider("music", 1);                      // already there
  game.step(1);
  expect(seen.length).toBe(2);
  expect(() => game.setSlider("play", 0.5)).toThrow(/no Slider/);
  expect(() => game.setSlider("music", "loud")).toThrow(/number/);
  stop();
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

test("ui.focus on a disabled Button returns false instead of throwing", () => {
  game.loadJson(menu);
  game.step(1);
  expect(ui.focus("options")).toBe(true);
  world.find("options").get("Button").interactable = false;
  game.step(1);
  expect(ui.focused.id).not.toBe("options");       // the focused widget was disabled: it lost the focus
  ui.focus(null);
  expect(ui.focus("options")).toBe(false);
  expect(ui.focused).toBeNull();                   // nothing changed
  expect(ui.focus("play")).toBe(true);             // a screen falls back to an enabled button
  expect(ui.focused.id).toBe("play");
  expect(() => ui.focus("menu")).toThrow(/container/);
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

TEST_CASE("ui.layout() sizes autoSize widgets right away, with no game.step") {
    TempProject p("layout");
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(p.config(), nullptr, &err), err);
    e.step(2);
    const char* code = R"JS(
      const b = world.find("play");
      b.get("Button").autoSize = true;
      b.get("Button").text = "A rather long label for this button, longer than two hundred pixels";
      const before = b.get("Button").size[0];
      ui.layout();
      const after = b.get("Button").size[0];
      ({ before, after, rect: ui.rectOf(b).w });
    )JS";
    auto r = e.commands().call("script.eval", Json{{"code", code}});
    REQUIRE_MESSAGE(r.ok, r.error.dump());
    const Json& v = r.result["value"];
    CHECK(v["before"].get<double>() == doctest::Approx(200));
    CHECK(v["after"].get<double>() > 300);
    CHECK(v["rect"].get<double>() == doctest::Approx(v["after"].get<double>()));
    e.shutdown();
}

TEST_CASE("ui.set_text_scale is the text size option: ui.textScale and ui.state see it, a bad value teaches") {
    TempProject p("textscale");
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(p.config(), nullptr, &err), err);
    const CommandInfo* info = e.commands().info("ui.set_text_scale");
    REQUIRE(info != nullptr);
    CHECK_FALSE(info->readOnly);
    CHECK(info->description.find("Example") != std::string::npos);
    CHECK(info->description.find("not save") != std::string::npos);  // it says the game stores the option
    CHECK(e.commands().call("ui.state", Json::object()).result["textScale"] == 1.0);
    auto r = e.commands().call("ui.set_text_scale", Json{{"scale", 1.5}});
    REQUIRE_MESSAGE(r.ok, r.error.dump());
    CHECK(r.result["textScale"] == 1.5);
    CHECK(e.text_scale() == 1.5f);
    CHECK(e.commands().call("ui.state", Json::object()).result["textScale"] == 1.5);
    CHECK(e.commands().call("script.eval", Json{{"code", "ui.textScale"}}).result["value"] == 1.5);  // a script sees the same option
    e.commands().call("script.eval", Json{{"code", "ui.textScale = 2"}});
    CHECK(e.text_scale() == 2.0f);                                                                    // and a script sets it
    for (auto [bad, what] : {std::pair{0.1, "minimum 0.5"}, std::pair{3.5, "maximum 3"}, std::pair{100.0, "maximum 3"}}) {
        r = e.commands().call("ui.set_text_scale", Json{{"scale", bad}});
        REQUIRE_FALSE(r.ok);
        CHECK(r.error["message"].get<std::string>().find(what) != std::string::npos);  // the schema says which end was crossed
        CHECK_FALSE(r.error["hint"].get<std::string>().empty());
    }
    CHECK(e.text_scale() == 2.0f);  // a rejected value changes nothing
    e.shutdown();
}

TEST_CASE("ui.set_scale is the interface scale: ui.scale, ui.state and the rectangles see it, a bad value teaches") {
    TempProject p("uiscale");
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(p.config(), nullptr, &err), err);
    const CommandInfo* info = e.commands().info("ui.set_scale");
    REQUIRE(info != nullptr);
    CHECK_FALSE(info->readOnly);
    CHECK(info->description.find("Example") != std::string::npos);
    CHECK(info->description.find("not save") != std::string::npos);  // it says the game stores the option
    CHECK(e.commands().call("ui.state", Json::object()).result["uiScale"] == 1.0);
    auto r1 = e.commands().call("ui.state", Json::object());
    Json before;
    for (const Json& w : r1.result["widgets"])
        if (w["id"] == "play") before = w["rect"];
    REQUIRE(before.is_array());
    auto r = e.commands().call("ui.set_scale", Json{{"scale", 1.5}});
    REQUIRE_MESSAGE(r.ok, r.error.dump());
    CHECK(r.result["uiScale"] == 1.5);
    CHECK(e.ui_scale() == 1.5f);
    CHECK(e.world().ui_scale() == 1.5f);
    auto st = e.commands().call("ui.state", Json::object());
    CHECK(st.result["uiScale"] == 1.5);
    for (const Json& w : st.result["widgets"])
        if (w["id"] == "play") {
            CHECK(w["rect"][2].get<float>() == doctest::Approx(1.5f * before[2].get<float>()));  // the size of the button on screen
            CHECK(w["rect"][3].get<float>() == doctest::Approx(1.5f * before[3].get<float>()));
        }
    CHECK(e.commands().call("script.eval", Json{{"code", "ui.scale"}}).result["value"] == 1.5);  // a script sees the same option
    e.commands().call("script.eval", Json{{"code", "ui.scale = 2"}});
    CHECK(e.ui_scale() == 2.0f);                                                                  // and a script sets it
    for (auto [bad, what] : {std::pair{0.1, "minimum 0.5"}, std::pair{3.5, "maximum 3"}, std::pair{100.0, "maximum 3"}}) {
        r = e.commands().call("ui.set_scale", Json{{"scale", bad}});
        REQUIRE_FALSE(r.ok);
        CHECK(r.error["message"].get<std::string>().find(what) != std::string::npos);
        CHECK_FALSE(r.error["hint"].get<std::string>().empty());
    }
    CHECK(e.ui_scale() == 2.0f);  // a rejected value changes nothing
    e.shutdown();
}

TEST_CASE("ui.mirrorRtl: on by default, factoria.json and ui.set_mirror_rtl turn it off, a script reads and sets it, a test file starts from it") {
    TempProject p("uimirror", R"({
  "format": "factoria.project/1", "name": "Ui Mirror", "mainScene": "scenes/main.scene.json",
  "display": { "width": 320, "height": 180 }, "ui": { "mirrorRtl": false }
})");
    auto proj = load_project(p.dir.generic_string());
    REQUIRE(proj.ok());
    CHECK_FALSE(proj->uiMirrorRtl);
    CHECK(proj->to_json()["ui"]["mirrorRtl"] == false);
    TempProject none("uimirror_none");
    CHECK(load_project(none.dir.generic_string())->uiMirrorRtl);
    CHECK_FALSE(load_project(none.dir.generic_string())->to_json().contains("ui"));
    TempProject bad("uimirror_bad", R"({"name":"x","ui":{"mirrorRtl":"yes"}})");
    auto err1 = load_project(bad.dir.generic_string());
    REQUIRE_FALSE(err1.ok());
    CHECK(err1.error().message.find("/ui/mirrorRtl") != std::string::npos);
    CHECK_FALSE(err1.error().hint.empty());

    p.write("tests/mirror.test.js", R"JS(
import { test, expect } from "factoria:test";
import { ui } from "factoria";
test("starts at the project's value, even after another file changed it", () => {
  expect(ui.mirrorRtl).toBe(false);
  ui.mirrorRtl = true;
  expect(ui.mirrorRtl).toBe(true);
});
test("a number is no switch", () => { expect(() => { ui.mirrorRtl = 1; }).toThrow(); });
)JS");
    p.write("tests/mirror2.test.js", R"JS(
import { test, expect } from "factoria:test";
import { ui } from "factoria";
test("a second file starts at the project's value again", () => { expect(ui.mirrorRtl).toBe(false); });
)JS");
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(p.config(), nullptr, &err), err);
    CHECK_FALSE(e.world().ui_mirror_rtl());
    CHECK_FALSE(e.default_ui_mirror_rtl());
    const CommandInfo* info = e.commands().info("ui.set_mirror_rtl");
    REQUIRE(info != nullptr);
    CHECK_FALSE(info->readOnly);
    CHECK(info->description.find("Example") != std::string::npos);
    auto r = e.commands().call("ui.set_mirror_rtl", Json{{"value", true}});
    REQUIRE_MESSAGE(r.ok, r.error.dump());
    CHECK(r.result["mirrorRtl"] == true);
    CHECK(r.result["mirrored"] == false);  // the language is left to right
    e.world().set_rtl(true);
    CHECK(e.commands().call("ui.set_mirror_rtl", Json{{"value", true}}).result["mirrored"] == true);
    CHECK(e.commands().call("script.eval", Json{{"code", "ui.mirrorRtl"}}).result["value"] == true);
    e.commands().call("script.eval", Json{{"code", "ui.mirrorRtl = false"}});
    CHECK_FALSE(e.world().ui_mirror());
    CHECK_FALSE(e.commands().call("ui.set_mirror_rtl", Json{{"value", "no"}}).ok);
    e.world().set_rtl(false);
    auto t = e.commands().call("project.test", Json::object());
    REQUIRE_MESSAGE(t.ok, t.error.dump());
    CHECK_MESSAGE(t.result["ok"].get<bool>(), t.result.dump(2));
    CHECK(t.result["passed"].get<int>() == 3);
    e.shutdown();
}

TEST_CASE("project: ui.scale is the interface scale a run starts with, it validates, and a test file starts from it") {
    TempProject p("uiscale_project", R"({
  "format": "factoria.project/1", "name": "Ui Scale", "mainScene": "scenes/main.scene.json",
  "display": { "width": 320, "height": 180 }, "ui": { "scale": 1.25 }
})");
    auto proj = load_project(p.dir.generic_string());
    REQUIRE(proj.ok());
    CHECK(proj->uiScale == doctest::Approx(1.25f));
    CHECK(proj->to_json()["ui"]["scale"].get<double>() == doctest::Approx(1.25));
    TempProject none("uiscale_project_none");
    CHECK(load_project(none.dir.generic_string())->uiScale == 1.0f);
    int n = 0;
    for (const char* bad : {R"({"name":"x","ui":{"scale":"big"}})", R"({"name":"x","ui":{"scale":4}})", R"({"name":"x","ui":{"scale":0.2}})",
                            R"({"name":"x","ui":3})"}) {
        TempProject b("uiscale_project_bad" + std::to_string(n++), bad);
        auto e = load_project(b.dir.generic_string());
        REQUIRE_FALSE(e.ok());
        CHECK(e.error().message.find("/ui") != std::string::npos);
        CHECK_FALSE(e.error().hint.empty());
    }

    p.write("tests/scale.test.js", R"JS(
import { test, expect } from "factoria:test";
import { ui } from "factoria";
test("starts at the project's ui.scale, even after another file changed it", () => {
  expect(ui.scale).toBe(1.25);
  ui.scale = 2;
});
)JS");
    p.write("tests/scale2.test.js", R"JS(
import { test, expect } from "factoria:test";
import { ui } from "factoria";
test("a second file starts at the project's value again", () => { expect(ui.scale).toBe(1.25); });
)JS");
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(p.config(), nullptr, &err), err);
    CHECK(e.ui_scale() == 1.25f);
    CHECK(e.default_ui_scale() == 1.25f);
    CHECK(e.world().ui_scale() == 1.25f);
    // the start-up change is no event: nothing waits for the first frame's listeners
    for (const GameEvent& ev : e.world().events().game) CHECK(ev.name != "ui.scale");
    auto t = e.commands().call("project.test", Json::object());
    REQUIRE_MESSAGE(t.ok, t.error.dump());
    CHECK_MESSAGE(t.result["ok"].get<bool>(), t.result.dump(2));
    CHECK(t.result["passed"].get<int>() == 2);
    CHECK(e.ui_scale() == 1.25f);

    // The player's choice survives a reload of factoria.json for another setting; a new project value replaces it.
    e.commands().call("ui.set_scale", Json{{"scale", 2.0}});
    auto rewrite = [&](const char* text, int seconds) {
        p.write("factoria.json", text);
        stdfs::last_write_time(p.dir / "factoria.json", stdfs::file_time_type::clock::now() + std::chrono::seconds(seconds));
        auto reload = e.commands().call("scene.reload", Json::object());
        REQUIRE_MESSAGE(reload.ok, reload.error.dump());
    };
    rewrite(R"({"format":"factoria.project/1","name":"Ui Scale","mainScene":"scenes/main.scene.json","display":{"width":320,"height":180},
               "physics":{"fixedHz":30},"ui":{"scale":1.25}})", 10);
    CHECK(e.ui_scale() == 2.0f);
    rewrite(R"({"format":"factoria.project/1","name":"Ui Scale","mainScene":"scenes/main.scene.json","display":{"width":320,"height":180},
               "ui":{"scale":1.5}})", 20);
    CHECK(e.ui_scale() == 1.5f);
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
    CHECK(t.result["passed"].get<int>() == 4);
    e.shutdown();
}

// A menu made of plain entities in the world (no Button anywhere), played like a person: the pointer, the keyboard and game.click by id.
static const char* const kWorldMenu = R"({
  "format": "factoria.scene/1",
  "entities": [
    { "id": "cam", "components": { "Camera": {} } },
    { "id": "board", "components": { "Transform": { "position": [20, 0], "scale": [1, 1, 1] } },
      "children": [
        { "id": "start", "components": { "Transform": { "position": [-60, 40] }, "Shape2D": { "size": [60, 20] },
                                         "Interactable": { "autoFocus": true } },
          "children": [ { "id": "start_glow", "components": { "Transform": { "position": [0, 0] }, "Shape2D": { "size": [64, 24], "color": [1, 1, 0, 1] },
                                                              "InteractableVisual": { "mode": "show", "when": "hover" } } } ] },
        { "id": "music", "components": { "Transform": { "position": [-60, 10] }, "Shape2D": { "size": [60, 20] },
                                         "Interactable": { "kind": "toggle" } },
          "children": [ { "id": "music_tick", "components": { "Transform": { "position": [0, 0] }, "Shape2D": { "size": [10, 10] },
                                                              "InteractableVisual": { "mode": "show", "when": "on" } } } ] },
        { "id": "volume", "components": { "Transform": { "position": [-60, -20] }, "Shape2D": { "size": [100, 10] },
                                          "Interactable": { "kind": "slider", "step": 0.1, "knob": "volume_knob" } },
          "children": [ { "id": "volume_knob", "components": { "Transform": { "position": [-50, 0] }, "Shape2D": { "size": [6, 14] } } } ] },
        { "id": "locked", "components": { "Transform": { "position": [-60, -50] }, "Shape2D": { "size": [60, 20] },
                                          "Interactable": { "enabled": false } } }
      ] },
    { "id": "back", "components": { "Button": { "text": "Back", "size": [50, 20], "anchor": [1, 1], "pivot": [1, 1] } } }
  ]
})";

static const char* const kWorldMenuTest = R"JS(
import { test, expect, game } from "factoria:test";
import { ui } from "factoria";
import menu from "../scenes/main.scene.json";

function record() {
  const log = [];
  const stops = ["focus", "blur", "hover", "press", "release", "click", "change"].map((type) =>
    ui.on(type, (e) => log.push(type + ":" + e.id + (e.value === undefined ? "" : "=" + e.value))));
  return { log, stop: () => stops.forEach((s) => s()) };
}

test("a world-space menu of plain entities is played with the pointer", () => {
  game.loadJson(menu);
  const r = record();
  game.step(1);
  expect(ui.focused.id).toBe("start");                                  // autoFocus
  const rect = ui.rectOf("start");                                      // seen through the camera: 60 x 20 at world (-40, 40)
  expect(rect.w).toBe(60);
  expect(rect.h).toBe(20);
  expect(ui.widgetAt(rect.x + 5, rect.y + 5).id).toBe("start");
  expect(ui.widgetAt(5, 5)).toBeNull();
  r.log.length = 0;
  game.mouseMove("start");
  game.step(1);
  expect(ui.hovered.id).toBe("start");
  expect(game.find("start_glow").active).toBe(true);                    // the highlight child follows hover with no code
  game.mouseMove("music");
  game.step(1);
  expect(game.find("start_glow").active).toBe(false);
  expect(r.log).toEqual(["hover:start=true", "hover:start=false", "hover:music=true"]);
  r.log.length = 0;
  game.click("music");                                                  // a toggle: change, and its tick appears
  expect(game.find("music").get("Interactable").on).toBe(true);
  expect(game.find("music_tick").active).toBe(true);
  expect(r.log).toContain("press:music");
  expect(r.log).toContain("release:music=true");
  expect(r.log).toContain("change:music=true");
  expect(r.log).not.toContain("click:music");                         // a toggle sends change, a button click
  expect(() => game.click("locked")).not.toThrow();                     // a disabled widget takes the click and ignores it
  expect(game.find("locked").get("Interactable").state).toBe("disabled");
  expect(ui.focused.id).toBe("music");
  r.stop();
});

test("the keyboard walks world widgets and a screen Button alike; Tab and confirm work", () => {
  game.loadJson(menu);
  game.step(1);
  expect(ui.focused.id).toBe("start");
  game.tap("ui_down");
  expect(ui.focused.id).toBe("music");
  game.tap("ui_submit");
  expect(game.find("music").get("Interactable").on).toBe(true);
  game.tap("ui_down");
  expect(ui.focused.id).toBe("volume");
  game.tap("ui_right");                                                 // the slider moves by its step
  expect(game.find("volume").get("Interactable").value).toBeCloseTo(0.1, 3);
  game.tap("ui_down");
  expect(ui.focused.id).not.toBe("locked");                             // a disabled widget is skipped
  game.tap("ui_next");
  const order = [ui.focused.id];
  game.tap("ui_next");
  order.push(ui.focused.id);
  expect(new Set(order).size).toBe(2);                                  // Tab moves on, it does not stay
});

test("a slider Interactable: dragging the track and game.setSlider set the value and move the knob", () => {
  game.loadJson(menu);
  game.step(1);
  const seen = [];
  const stop = ui.on("change", "volume", (e) => seen.push(e.value));
  const knob = game.find("volume_knob");
  game.setSlider("volume", 0.5);
  game.step(1);
  expect(seen).toEqual([0.5]);
  expect(knob.get("Transform").position.x).toBeCloseTo(0, 3);          // halfway along a 100 wide track
  const r = ui.rectOf("volume");
  game.drag([r.x + r.w / 2, r.y + r.h / 2], [r.x + r.w, r.y + r.h / 2]);
  expect(game.find("volume").get("Interactable").value).toBeCloseTo(1, 3);
  expect(knob.get("Transform").position.x).toBeCloseTo(50, 3);
  stop();
});
)JS";

TEST_CASE("Interactable: a world-space menu of plain entities is played with the pointer, the keyboard and game.click") {
    TempProject p("worldmenu");
    p.write("scenes/main.scene.json", kWorldMenu);
    p.write("tests/menu.test.js", kWorldMenuTest);
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(p.config(), nullptr, &err), err);
    auto t = e.commands().call("project.test", Json::object());
    REQUIRE_MESSAGE(t.ok, t.error.dump());
    CHECK_MESSAGE(t.result["ok"].get<bool>(), t.result.dump(2));
    CHECK(t.result["passed"].get<int>() == 3);
    // The commands find it by id, like a person clicking it.
    e.step(1);
    auto r = e.commands().call("game.click", Json::parse(R"({"id":"start"})"));
    REQUIRE_MESSAGE(r.ok, r.error.dump());
    CHECK(r.result["widget"] == "start");
    auto st = e.commands().call("ui.state", Json::object());
    REQUIRE(st.ok);
    bool found = false;
    for (const Json& w : st.result["widgets"])
        if (w["id"] == "volume") {
            found = true;
            CHECK(w["kind"] == "Interactable");
            CHECK(w["interactableKind"] == "slider");
        }
    CHECK(found);
    r = e.commands().call("ui.set_slider", Json::parse(R"({"id":"volume","value":0.3})"));
    REQUIRE_MESSAGE(r.ok, r.error.dump());
    CHECK(r.result["value"].get<float>() == doctest::Approx(0.3f));
    r = e.commands().call("ui.set_slider", Json::parse(R"({"id":"start","value":0.3})"));
    CHECK_FALSE(r.ok);
    e.shutdown();
}

TEST_CASE("screen.set_safe_area: a notched phone moves the widgets anchored to the safe area, and only those") {
    TempProject p("safearea");
    p.write("scenes/main.scene.json", R"({
  "format": "factoria.scene/1",
  "entities": [
    { "id": "cam", "components": { "Camera": {} } },
    { "id": "safe", "components": { "Transform": { "position": [10, 10] },
        "Button": { "text": "Safe", "size": [50, 20], "anchor": [0, 0], "safeArea": true } } },
    { "id": "raw", "components": { "Transform": { "position": [10, 10] },
        "Button": { "text": "Raw", "size": [50, 20], "anchor": [0, 0] } } }
  ]
})");
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(p.config(), nullptr, &err), err);
    const CommandInfo* info = e.commands().info("screen.set_safe_area");
    REQUIRE(info != nullptr);
    CHECK_FALSE(info->readOnly);
    CHECK(info->description.find("Example") != std::string::npos);
    auto rect_of = [&](const char* id) {
        e.step(1);
        const auto state = e.commands().call("ui.state", Json::object());  // kept alive: the loop reads inside it
        for (const Json& w : state.result["widgets"])
            if (w["id"] == id) return w["rect"];
        return Json();
    };
    const Json rawBase = rect_of("raw");
    const Json safeBase = rect_of("safe");
    CHECK(safeBase == rawBase);  // no notch: the whole screen, both anchored to its corner
    auto r = e.commands().call("screen.set_safe_area", Json{{"profile", "phone-portrait"}});
    REQUIRE_MESSAGE(r.ok, r.error.dump());
    const float top = r.result["insets"]["top"].get<float>();
    CHECK(top > 0);
    CHECK(rect_of("safe")[1].get<float>() == doctest::Approx(safeBase[1].get<float>() + top));  // moved down by the notch
    CHECK(rect_of("raw") == rawBase);  // not anchored to the safe area: stays under the notch
    r = e.commands().call("screen.set_safe_area", Json{{"left", 30}});
    REQUIRE_MESSAGE(r.ok, r.error.dump());
    CHECK(rect_of("safe")[0].get<float>() == doctest::Approx(safeBase[0].get<float>() + 30));
    CHECK(rect_of("safe")[1] == safeBase[1]);
    // mistakes teach
    r = e.commands().call("screen.set_safe_area", Json{{"profile", "phone-portait"}});
    REQUIRE_FALSE(r.ok);
    CHECK(r.error["message"].get<std::string>().find("Did you mean 'phone-portrait'") != std::string::npos);
    r = e.commands().call("screen.set_safe_area", Json{{"left", 400}});
    REQUIRE_FALSE(r.ok);
    CHECK_FALSE(r.error["hint"].get<std::string>().empty());
    e.shutdown();
}

TEST_CASE("on-screen gamepad: a JavaScript test plays the pad actions with two fingers") {
    TempProject p("touchpad", R"({"name": "x", "mainScene": "scenes/main.scene.json", "display": {"width": 320, "height": 180},
      "input": {"actions": {"left": ["A", "GamepadLeftStickLeft"], "right": ["D", "GamepadLeftStickRight"],
                            "down": ["S", "GamepadLeftStickDown"], "up": ["W", "GamepadLeftStickUp"],
                            "jump": ["Space", "GamepadA"], "tap": ["Touch"]}}})");
    // The stick in the bottom-left corner (rect 10..90 x 90..170, centre [50, 130]), the button in the bottom-right one
    // (rect 250..310 x 110..170, centre [280, 140]).
    p.write("scenes/pad.scene.json", R"({
  "format": "factoria.scene/1",
  "entities": [
    { "id": "cam", "components": { "Camera": {} } },
    { "id": "stick", "components": { "Transform": { "position": [10, -10] },
        "TouchStick": { "anchor": [0, 1], "pivot": [0, 0], "size": [80, 80] } } },
    { "id": "jump", "components": { "Transform": { "position": [-10, -10] },
        "TouchButton": { "anchor": [1, 1], "pivot": [1, 0], "size": [60, 60], "button": "A", "text": "A" } } }
  ]
})");
    p.write("tests/pad.test.js", R"JS(
import { test, expect, game } from "factoria:test";
import { input, world } from "factoria";
import pad from "../scenes/pad.scene.json";

test("move and jump at once; the fingers are the pad's, not touches", () => {
  game.loadJson(pad);
  game.step(1);
  const stick = world.find("stick").get("TouchStick");
  expect(stick.shown).toBe(false);                  // touch-only: hidden before the first touch
  game.touchStart([50, 130]);                       // the stick's centre
  game.touchMove([90, 130]);                        // its right edge: full tilt
  game.touchStart([280, 140], 2);                   // a second finger on the button
  game.step(1);
  expect(input.vector("left", "right", "down", "up").x).toBeCloseTo(1, 3);
  expect(input.down("jump")).toBe(true);
  expect(input.down("tap")).toBe(false);
  expect(input.touches.length).toBe(0);
  expect(world.find("stick").get("TouchStick").shown).toBe(true);
  expect(world.find("jump").get("TouchButton").pressed).toBe(true);
  game.touchMove([50, 170]);                        // down
  game.step(1);
  expect(input.vector("left", "right", "down", "up").y).toBeCloseTo(-1, 3);
  game.touchEnd(2);
  game.touchEnd();
  game.step(1);
  expect(input.down("jump")).toBe(false);
  expect(input.vector("left", "right", "down", "up").y).toBe(0);
  game.touch([160, 40]);                            // anywhere else: an ordinary touch
  expect(input.down("jump")).toBe(false);
});
)JS");
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(p.config(), nullptr, &err), err);
    auto t = e.commands().call("project.test", Json::object());
    REQUIRE_MESSAGE(t.ok, t.error.dump());
    CHECK_MESSAGE(t.result["ok"].get<bool>(), t.result.dump(2));
    CHECK(t.result["passed"].get<int>() == 1);
    e.shutdown();
}

TEST_CASE("game.input back is the Back button: a script handler consumes it") {
    TempProject p("back");
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(p.config(), nullptr, &err), err);
    e.commands().call("script.eval", Json{{"code", "globalThis.backs = 0; input.onBack(() => { globalThis.backs++; return true; })"}});
    auto b = e.commands().call("game.input", Json{{"back", true}});
    REQUIRE_MESSAGE(b.ok, b.error.dump());
    e.step(1);
    CHECK(e.commands().call("script.eval", Json{{"code", "globalThis.backs"}}).result["value"] == 1);
    e.shutdown();
}

// Focus path -> Input::keyboard_shown(), which the windowed runner hands to app_show_keyboard (the platform call; the
// headless engine only records the request, so this is the "faked" platform: what the phone would be told).
TEST_CASE("ui: a focused TextField raises the on-screen keyboard and blur hides it") {
    TempProject p("keyboard");
    p.write("scenes/main.scene.json", R"({
      "format": "factoria.scene/1",
      "entities": [
        { "id": "cam", "components": { "Camera": {} } },
        { "id": "name", "components": { "TextField": { "size": [200, 30] } } },
        { "id": "ok", "components": { "Transform": { "position": [0, 60, 0] }, "Button": { "size": [80, 30] } } }
      ] })");
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(p.config(), nullptr, &err), err);
    auto eval = [&](const char* code) {
        auto r = e.commands().call("script.eval", Json{{"code", code}});
        REQUIRE_MESSAGE(r.ok, r.error.dump());
    };
    e.step(2);
    CHECK_FALSE(e.input().keyboard_shown());  // nothing has the focus
    eval("ui.focus('name')");
    e.step(1);
    CHECK(e.input().keyboard_shown());
    eval("ui.focus('ok')");
    e.step(1);
    CHECK_FALSE(e.input().keyboard_shown());
    eval("ui.focus('name')");
    e.step(1);
    CHECK(e.input().keyboard_shown());
    eval("ui.focus(null)");
    e.step(1);
    CHECK_FALSE(e.input().keyboard_shown());
    // A gamepad player gets the game's own on-screen keyboard (docs/MENUS.md), not the phone's.
    e.input().set_last_device(InputDevice::Gamepad);
    eval("ui.focus('name')");
    e.step(1);
    CHECK_FALSE(e.input().keyboard_shown());
    e.shutdown();
}

TEST_CASE("game.input: a mouse button or key that goes up to down between frames is a press for scripts") {
    TempProject p("press_edge");
    p.write("scenes/main.scene.json", R"({"format":"factoria.scene/1","entities":[{"id":"cam","components":{"Camera":{}}},
        {"id":"p","components":{"Script":{"path":"p.js"}}}]})");
    p.write("p.js", "import { Behaviour, input } from 'factoria';\n"
                    "globalThis.log = [];\n"
                    "export default class P extends Behaviour {\n"
                    "  onUpdate() { if (input.mouse.pressed('left')) log.push('mp@' + input.mouse.position.x);\n"
                    "    if (input.mouse.released('left')) log.push('mr');\n"
                    "    if (input.keyPressed('Space')) log.push('kp'); if (input.keyReleased('Space')) log.push('kr'); }\n"
                    "}\n");
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(p.config(), nullptr, &err), err);
    auto call = [&](const char* cmd, const char* args) {
        auto r = e.commands().call(cmd, Json::parse(args));
        REQUIRE_MESSAGE(r.ok, r.error.dump());
    };
    auto log = [&] { return e.commands().call("script.eval", Json{{"code", "log.join(',')"}}).result["value"].get<std::string>(); };
    e.step(2);
    call("game.input", R"({"mouse":{"position":[100,50],"left":true}})");
    call("game.step", R"({"frames":1})");
    CHECK(log() == "mp@100");
    call("game.step", R"({"frames":2})");
    call("game.input", R"({"mouse":{"left":false}})");
    call("game.step", R"({"frames":1})");
    CHECK(log() == "mp@100,mr");
    call("game.input", R"({"key":"Space","down":true})");
    call("game.step", R"({"frames":1})");
    call("game.input", R"({"key":"Space","down":false})");
    call("game.step", R"({"frames":1})");
    CHECK(log() == "mp@100,mr,kp,kr");
    e.shutdown();
}

TEST_CASE("game.click: by position and by widget id, scripts see pressed and released, buttons get the click") {
    TempProject p("click_cmd");
    p.write("scenes/main.scene.json", R"({"format":"factoria.scene/1","entities":[{"id":"cam","components":{"Camera":{}}},
        {"id":"p","components":{"Script":{"path":"p.js"}}},
        {"id":"menu","components":{"Transform":{"position":[160,20]},"Panel":{"size":[240,140],"pivot":[0.5,1],"layout":"column","padding":[8,8,8,8]}},
         "children":[{"id":"play","components":{"Button":{"text":"Play","size":[200,30]}}},
                     {"id":"hidden","components":{"Button":{"text":"Hidden","size":[200,30]}}}]}]})");
    p.write("p.js", "import { Behaviour, input, ui, world } from 'factoria';\n"
                    "globalThis.log = [];\n"
                    "ui.on('click', (e) => log.push('click:' + e.id));\n"
                    "export default class P extends Behaviour {\n"
                    "  onStart() { world.find('hidden').active = false; }\n"
                    "  onUpdate() { if (input.mouse.pressed('left')) log.push('mp@' + input.mouse.position.x + ',' + input.mouse.position.y);\n"
                    "    if (input.mouse.released('left')) log.push('mr'); if (input.mouse.pressed('right')) log.push('rp'); }\n"
                    "}\n");
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(p.config(), nullptr, &err), err);
    e.step(2);
    auto log = [&] { return e.commands().call("script.eval", Json{{"code", "log.join(',')"}}).result["value"].get<std::string>(); };
    auto r = e.commands().call("game.click", Json::parse(R"({"position":[10,20]})"));
    REQUIRE_MESSAGE(r.ok, r.error.dump());
    CHECK(r.result["frames"] == 2);
    CHECK(log() == "mp@10,20,mr");
    r = e.commands().call("game.click", Json::parse(R"({"id":"play"})"));
    REQUIRE_MESSAGE(r.ok, r.error.dump());
    CHECK(r.result["widget"] == "play");
    CHECK(log().find("click:play") != std::string::npos);
    r = e.commands().call("game.click", Json::parse(R"({"position":[10,20],"button":"right","hold":3})"));
    REQUIRE(r.ok);
    CHECK(r.result["frames"] == 4);
    CHECK(log().find(",rp") != std::string::npos);
    CHECK_FALSE(e.input().mouse_down(MouseButton::Right));
    // Teaching errors: nothing to click, two targets, a widget that cannot be clicked.
    CHECK_FALSE(e.commands().call("game.click", Json::object()).ok);
    CHECK_FALSE(e.commands().call("game.click", Json::parse(R"({"id":"play","position":[1,1]})")).ok);
    r = e.commands().call("game.click", Json::parse(R"({"id":"hidden"})"));
    REQUIRE_FALSE(r.ok);
    CHECK(r.error["message"].get<std::string>().find("inactive") != std::string::npos);
    r = e.commands().call("game.click", Json::parse(R"({"id":"plya"})"));
    REQUIRE_FALSE(r.ok);
    CHECK(r.error["message"].get<std::string>().find("play") != std::string::npos);
    e.shutdown();
}
