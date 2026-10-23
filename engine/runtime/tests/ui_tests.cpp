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
