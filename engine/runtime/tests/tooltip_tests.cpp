// Tooltips through the whole engine: the "ui" section of factoria.json, the `tooltip` of a widget, ui.tooltip / ui.showTooltip /
// ui.setTooltip / ui.setWorldTooltip from JavaScript tests, the touch rule and ui.check_layout.
#include <doctest.h>

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
  "name": "Tooltip Test",
  "id": "com.example.tooltiptest",
  "mainScene": "scenes/main.scene.json",
  "display": { "width": 1280, "height": 720, "scaleMode": "stretch" },
  "ui": { "tooltipDelay": 0.5, "tooltip": { "maxWidth": 240 } }
})";

// A button in each corner of the 1280 x 720 screen (a pivot is y up: [0, 1] is the top-left corner), one in the middle that gets its tooltip from a function, and one with none.
const char* kScene = R"({
  "format": "factoria.scene/1",
  "entities": [
    { "id": "cam", "components": { "Camera": {} } },
    { "id": "tl", "components": { "Button": { "text": "TL", "size": [160, 60], "anchor": [0, 0], "pivot": [0, 1], "tooltip": "Top left" } } },
    { "id": "tr", "components": { "Button": { "text": "TR", "size": [160, 60], "anchor": [1, 0], "pivot": [1, 1], "tooltip": {"title": "Top right", "lines": ["one", "two"]} } } },
    { "id": "bl", "components": { "Button": { "text": "BL", "size": [160, 60], "anchor": [0, 1], "pivot": [0, 0], "tooltip": "Bottom left, with a longer text that wraps onto a second line at the maximum width" } } },
    { "id": "br", "components": { "Button": { "text": "BR", "size": [160, 60], "anchor": [1, 1], "pivot": [1, 0], "tooltip": {"title": "Bottom right", "lines": ["a", {"text": "b", "color": "#ff0000"}]} } } },
    { "id": "mid", "components": { "Button": { "text": "Mid", "size": [160, 60], "anchor": [0.5, 0.5], "pivot": [0.5, 0.5] } } },
    { "id": "plain", "components": { "Button": { "text": "Plain", "size": [100, 40], "anchor": [0.25, 0.5], "pivot": [0.5, 0.5] } } },
    { "id": "panel", "components": { "Panel": { "size": [300, 100], "layout": "column", "anchor": [0.75, 0.5], "pivot": [0.5, 0.5], "tooltip": "A panel" } },
      "children": [ { "id": "inside", "components": { "Button": { "text": "In", "size": [80, 30], "anchor": [0.5, 0.5], "pivot": [0.5, 0.5] } } } ] }
  ]
})";

// 60 lines cannot fit a 720 px screen.
const char* kBigScene = R"({
  "format": "factoria.scene/1",
  "entities": [
    { "id": "cam", "components": { "Camera": {} } },
    { "id": "huge", "components": { "Button": { "text": "Huge", "size": [160, 60], "tooltip": {"title": "Too much", "lines": [
      "1","2","3","4","5","6","7","8","9","10","11","12","13","14","15","16","17","18","19","20","21","22","23","24","25","26","27","28","29","30",
      "31","32","33","34","35","36","37","38","39","40","41","42","43","44","45","46","47","48","49","50","51","52","53","54","55","56","57","58","59","60"]} } } }
  ]
})";

const char* kTest = R"JS(
import { test, expect, game } from "factoria:test";
import { ui, world, fa } from "factoria";
import main from "../scenes/main.scene.json";

const SCREEN = { w: 1280, h: 720 };
function inside(r) { return r[0] >= 0 && r[1] >= 0 && r[0] + r[2] <= SCREEN.w && r[1] + r[3] <= SCREEN.h; }

test("the project's delay is what a test file starts with", () => {
  expect(ui.tooltipDelay).toBe(0.5);
  ui.tooltipDelay = 2;
  expect(ui.tooltipDelay).toBe(2);
  expect(() => { ui.tooltipDelay = -1; }).toThrow(/0 to 60/);
  ui.tooltipDelay = 0.5;
});

test("a tooltip shows after the delay and not before, and hides when the pointer moves away", () => {
  game.loadJson(main);
  game.mouseMove("tl");
  game.step(20);                       // 0.33 s
  expect(ui.tooltip).toBeNull();
  game.step(20);                       // 0.67 s
  expect(ui.tooltip).not.toBeNull();
  expect(ui.tooltip.lines).toEqual(["Top left"]);
  expect(ui.tooltip.source).toBe("widget");
  expect(ui.tooltip.widget).toBe("tl");
  expect(inside(ui.tooltip.rect)).toBe(true);
  game.mouseMove({ x: 700, y: 200 });  // away from every widget
  game.step(1);
  expect(ui.tooltip).toBeNull();
  game.mouseMove("tl");
  game.step(10);                       // the timer started over
  expect(ui.tooltip).toBeNull();
});

test("a pointer that wanders within a few pixels keeps resting", () => {
  game.loadJson(main);
  game.mouseMove({ x: 50, y: 30 });
  game.step(20);
  game.mouseMove({ x: 52, y: 31 });
  game.step(20);
  expect(ui.tooltip).not.toBeNull();
});

test("ui.state reports the tooltip", () => {
  game.loadJson(main);
  ui.tooltipDelay = 0;
  game.mouseMove("tr");
  game.step(2);
  const t = fa.call("ui.state", {}).tooltip;
  expect(t.title).toBe("Top right");
  expect(t.lines).toEqual(["one", "two"]);
});

test("the tooltip stays inside the 1280 x 720 screen at each corner", () => {
  game.loadJson(main);
  ui.tooltipDelay = 0;
  for (const [id, x, y] of [["tl", 0, 0], ["tr", 1279, 0], ["bl", 0, 719], ["br", 1279, 719]]) {
    game.mouseMove({ x, y });
    game.step(3);
    const t = ui.tooltip;
    expect(t === null ? "none at " + id : "shown").toBe("shown");
    expect(t.widget).toBe(id);
    expect(inside(t.rect)).toBe(true);
  }
  // the wrapped line made the bottom-left box taller than one line
  game.mouseMove({ x: 0, y: 719 });
  game.step(2);
  expect(ui.tooltip.rect[3]).toBeGreaterThan(50);
});

test("a child shows the tooltip of the nearest ancestor that has one", () => {
  game.loadJson(main);
  ui.tooltipDelay = 0;
  game.mouseMove("inside");
  game.step(2);
  expect(ui.tooltip.lines).toEqual(["A panel"]);
  game.mouseMove("plain");
  game.step(2);
  expect(ui.tooltip).toBeNull();
});

test("ui.showTooltip shows now, stays inside the screen, and hides with the pointer or ui.hideTooltip", () => {
  game.loadJson(main);
  game.mouseMove({ x: 640, y: 100 });
  game.step(1);
  ui.showTooltip({ title: "Market", lines: ["Sells fish"] }, { x: 1279, y: 719 });
  expect(ui.tooltip.title).toBe("Market");
  expect(ui.tooltip.source).toBe("manual");
  expect(inside(ui.tooltip.rect)).toBe(true);
  game.step(30);
  expect(ui.tooltip).not.toBeNull();   // no rest needed, stays while the pointer does
  ui.hideTooltip();
  expect(ui.tooltip).toBeNull();
  ui.showTooltip("again", { x: 10, y: 10 });
  game.mouseMove({ x: 400, y: 100 });
  game.step(1);
  expect(ui.tooltip).toBeNull();
  expect(() => ui.showTooltip(5, { x: 1, y: 1 })).toThrow(/string/);
  expect(() => ui.showTooltip("x")).toThrow(/second argument/);
});

test("ui.setTooltip gives a widget a function; it can return nothing", () => {
  game.loadJson(main);
  ui.tooltipDelay = 0;
  let on = true;
  ui.setTooltip("mid", () => (on ? { title: "Mid", lines: ["x", ""] } : null));
  game.mouseMove("mid");
  game.step(2);
  expect(ui.tooltip.title).toBe("Mid");
  expect(ui.tooltip.lines).toEqual(["x"]);   // the empty line is skipped
  expect(ui.tooltip.source).toBe("script");
  on = false;
  game.step(2);
  expect(ui.tooltip).toBeNull();
  ui.setTooltip("mid", "now static");
  game.step(2);
  expect(ui.tooltip.lines).toEqual(["now static"]);
  ui.setTooltip("mid", null);
  game.step(2);
  expect(ui.tooltip).toBeNull();
});

test("ui.setWorldTooltip answers when the pointer rests on no widget", () => {
  game.loadJson(main);
  ui.tooltipDelay = 0;
  ui.setWorldTooltip((x, y) => (x > 600 && x < 700 ? "world " + Math.round(x) : null));
  game.mouseMove({ x: 650, y: 300 });
  game.step(2);
  expect(ui.tooltip.source).toBe("world");
  expect(ui.tooltip.lines).toEqual(["world 650"]);
  game.mouseMove({ x: 800, y: 300 });
  game.step(2);
  expect(ui.tooltip).toBeNull();
  game.mouseMove("tl");                  // over a widget: its own tooltip
  game.step(2);
  expect(ui.tooltip.source).toBe("widget");
});

test("the functions end with the scene", () => {
  game.loadJson(main);
  ui.tooltipDelay = 0;
  ui.setWorldTooltip(() => "gone");
  game.loadJson(main);
  game.mouseMove({ x: 650, y: 300 });
  game.step(3);
  expect(ui.tooltip).toBeNull();
});

test("a touch shows no tooltip unless the project turns it on; the mouse does again", () => {
  game.loadJson(main);
  ui.tooltipDelay = 0;
  game.touchStart("tl");
  game.touchEnd();
  game.step(3);
  expect(ui.tooltip).toBeNull();
  game.mouseMove({ x: 60, y: 30 });
  game.step(3);
  expect(ui.tooltip).not.toBeNull();
});

test("a bad tooltip is reported by ui.setTooltip", () => {
  game.loadJson(main);
  expect(() => ui.setTooltip("tl", 5)).toThrow(/string/);
  expect(() => ui.setWorldTooltip("x")).toThrow(/function/);
  ui.tooltipDelay = 3;   // left changed on purpose: tooltip2.test.js starts from the project's value
});
)JS";

struct TempProject {
    stdfs::path dir;
    explicit TempProject(const std::string& name, const char* project = kProject) {
        dir = fs::make_temp_dir("fa_tooltip_test_" + name);
        write("factoria.json", project);
        write("scenes/main.scene.json", kScene);
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

TEST_CASE("tooltips: JavaScript tests for the delay, placement, showTooltip, functions and touch") {
    TempProject p("js");
    p.write("tests/tooltip.test.js", kTest);
    p.write("tests/tooltip2.test.js", R"JS(
import { test, expect } from "factoria:test";
import { ui } from "factoria";
test("a second file starts at the project's delay again", () => { expect(ui.tooltipDelay).toBe(0.5); });
)JS");
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(p.config(), nullptr, &err), err);
    auto t = e.commands().call("project.test", Json::object());
    REQUIRE_MESSAGE(t.ok, t.error.dump());
    CHECK_MESSAGE(t.result["ok"].get<bool>(), t.result.dump(2));
    CHECK(t.result["failed"].get<int>() == 0);
    CHECK(t.result["passed"].get<int>() >= 13);
    e.shutdown();
}

TEST_CASE("tooltips: factoria.json mistakes name the pointer and the fix") {
    TempProject p("bad", R"({"format":"factoria.project/1","name":"x","mainScene":"scenes/main.scene.json","ui":{"tooltip":{"fontsize":12}}})");
    auto r = load_project(p.dir.generic_string());
    REQUIRE_FALSE(r.ok());
    CHECK(r.error().message.find("/ui/tooltip/fontsize") != std::string::npos);
    CHECK(r.error().message.find("fontSize") != std::string::npos);
    TempProject q("good");
    auto ok = load_project(q.dir.generic_string());
    REQUIRE_MESSAGE(ok.ok(), ok.error().to_string());
    CHECK(ok->uiTooltip.delay == doctest::Approx(0.5f));
    CHECK(ok->uiTooltip.style.maxWidth == doctest::Approx(240.0f));
}

TEST_CASE("ui.check_layout reports a tooltip that cannot fit the screen") {
    TempProject p("check");
    p.write("scenes/big.scene.json", kBigScene);
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(p.config(), nullptr, &err), err);
    auto r = e.commands().call("ui.check_layout", Json{{"scenes", Json::array({"scenes/big.scene.json", "scenes/main.scene.json"})}, {"pseudo", false}});
    REQUIRE_MESSAGE(r.ok, r.error.dump());
    int tooltipIssues = 0;
    for (const Json& i : r.result["issues"])
        if (i["kind"] == "tooltip") {
            ++tooltipIssues;
            CHECK(i["entity"] == "huge");
            CHECK(i["scene"] == "scenes/big.scene.json");
        }
    CHECK(tooltipIssues == 1);
    e.shutdown();
}
