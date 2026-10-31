// Drag and drop through the whole engine: `draggable` on a widget, ui.on("dragStart" | "dragOver" | "drop" | "dragCancel"), drop
// rules, the drag image, ui.dragging, the swallowed click, a gamepad cursor (ui.setPointer) and game.drag from JavaScript tests.
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
  "name": "Drag Test",
  "id": "com.example.dragtest",
  "mainScene": "scenes/main.scene.json",
  "display": { "width": 1280, "height": 720, "scaleMode": "stretch" }
})";

// src: a draggable Button (centre 128, 360); zone: a Panel (centre 640, 360, 300 x 200); plain: a Button that takes no drop; chip: a Panel for the
// drag image (centre starts at 40, 20); the world is everything else, e.g. (640, 650).
const char* kScene = R"({
  "format": "factoria.scene/1",
  "entities": [
    { "id": "cam", "components": { "Camera": {} } },
    { "id": "src", "components": { "Button": { "text": "Worker", "size": [160, 60], "anchor": [0.1, 0.5], "pivot": [0.5, 0.5],
        "draggable": { "payload": { "n": 7 }, "slop": 6 }, "tooltip": "Drag me" } } },
    { "id": "zone", "components": { "Panel": { "size": [300, 200], "anchor": [0.5, 0.5], "pivot": [0.5, 0.5] } } },
    { "id": "plain", "components": { "Button": { "text": "Plain", "size": [120, 50], "anchor": [0.9, 0.2], "pivot": [0.5, 0.5] } } },
    { "id": "chip", "components": { "Panel": { "size": [80, 30], "anchor": [0, 0], "pivot": [0.5, 0.5], "color": [0.2, 0.4, 0.8, 1] } } }
  ]
})";

const char* kTest = R"JS(
import { test, expect, game } from "factoria:test";
import { ui, world } from "factoria";
import main from "../scenes/main.scene.json";

const WORLD = { x: 640, y: 650 };
function record() {
  const log = [];
  for (const t of ["click", "dragStart", "dragOver", "drop", "dragCancel"]) ui.on(t, (e) => log.push({ type: t, id: e.id, target: e.target ? e.target.id : null, accepts: e.accepts, x: e.x, y: e.y, payload: e.payload, reason: e.reason }));
  return log;
}
const types = (log) => [...new Set(log.map((e) => e.type))];

test("a drag from a Button onto a Panel fires the events in order and no click", () => {
  game.loadJson(main);
  game.step(2);
  ui.setDropTarget("zone", true);
  const log = record();
  game.drag("src", "zone");
  expect(types(log)).toEqual(["dragStart", "dragOver", "drop"]);
  expect(log[0].type).toBe("dragStart");
  expect(log[log.length - 1].type).toBe("drop");
  expect(log.filter((e) => e.type === "click").length).toBe(0);
  const drop = log[log.length - 1];
  expect(drop.id).toBe("src");
  expect(drop.target).toBe("zone");
  expect(drop.accepts).toBe(true);
  expect(drop.payload).toEqual({ n: 7 });
  expect(drop.x).toBe(640);
  expect(drop.y).toBe(360);
  expect(ui.dragging).toBeNull();
  expect(ui.focused === null || ui.focused.id === "src").toBe(true);
});

test("a press released before the slop is a click, not a drag", () => {
  game.loadJson(main);
  game.step(2);
  const log = record();
  game.click("src");
  expect(types(log)).toEqual(["click"]);
});

test("a drop over the world reports no target and the screen position", () => {
  game.loadJson(main);
  game.step(2);
  const log = record();
  game.drag("src", WORLD);
  const drop = log.find((e) => e.type === "drop");
  expect(drop).toBeTruthy();
  expect(drop.target).toBeNull();
  expect(drop.x).toBe(WORLD.x);
  expect(drop.y).toBe(WORLD.y);
  expect(drop.accepts).toBe(true);
  expect(log.some((e) => e.type === "click")).toBe(false);
  ui.setWorldDropTarget(false);
  log.length = 0;
  game.drag("src", WORLD);
  expect(types(log)).toEqual(["dragStart", "dragOver", "dragCancel"]);
  expect(log[log.length - 1].reason).toBe("rejected");
});

test("a widget with no drop rule refuses; a function rule decides each time", () => {
  game.loadJson(main);
  game.step(2);
  const log = record();
  game.drag("src", "plain");
  expect(log[log.length - 1]).toMatchObject({ type: "dragCancel", reason: "rejected", accepts: false });
  expect(log[log.length - 1].target).toBe("plain");
  let allow = false;
  const seen = [];
  ui.setDropTarget("plain", (d) => { seen.push(d.payload); return allow; });
  log.length = 0;
  game.drag("src", "plain");
  expect(log[log.length - 1].type).toBe("dragCancel");
  expect(seen.length).toBeGreaterThan(0);
  expect(seen[0]).toEqual({ n: 7 });
  allow = true;
  log.length = 0;
  game.drag("src", "plain");
  expect(log[log.length - 1]).toMatchObject({ type: "drop", target: "plain", accepts: true });
  ui.setDropTarget("plain", null);
  log.length = 0;
  game.drag("src", "plain");
  expect(log[log.length - 1].type).toBe("dragCancel");
});

test("ui.dragging is set while dragging, and ui_cancel ends the drag without a click or a drop", () => {
  game.loadJson(main);
  game.step(2);
  ui.setDropTarget("zone", true);
  const log = record();
  game.mouseMove("src");
  game.mouseDown("left");
  game.step(1);
  expect(ui.dragging).toBeNull();
  game.mouseMove({ x: 400, y: 360 });
  game.step(1);
  expect(ui.dragging).not.toBeNull();
  expect(ui.dragging.source.id).toBe("src");
  expect(ui.dragging.payload).toEqual({ n: 7 });
  expect(ui.dragging.from.x).toBeCloseTo(128, 0);
  expect(ui.dragging.x).toBe(400);
  expect(ui.dragging.target).toBeNull();
  game.mouseMove("zone");
  game.step(1);
  expect(ui.dragging.target.id).toBe("zone");
  expect(ui.dragging.accepts).toBe(true);
  game.press("ui_cancel");
  game.step(1);
  game.release("ui_cancel");
  expect(ui.dragging).toBeNull();
  game.mouseUp("left");
  game.step(2);
  expect(types(log)).toEqual(["dragStart", "dragOver", "dragCancel"]);
  expect(log[log.length - 1].reason).toBe("cancel");
  // ui.cancelDrag() does the same
  log.length = 0;
  game.mouseMove("src");
  game.mouseDown("left");
  game.step(1);
  game.mouseMove("zone");
  game.step(1);
  ui.cancelDrag();
  game.mouseUp("left");
  game.step(2);
  expect(log[log.length - 1]).toMatchObject({ type: "dragCancel", reason: "script" });
  expect(log.some((e) => e.type === "drop" || e.type === "click")).toBe(false);
});

test("the drag image follows the pointer and is never the target", () => {
  game.loadJson(main);
  game.step(2);
  ui.setDropTarget("zone", true);
  ui.on("dragStart", () => ui.setDragImage("chip"));
  game.mouseMove("src");
  game.mouseDown("left");
  game.step(1);
  game.mouseMove({ x: 300, y: 200 });
  game.step(2);
  const r = ui.rectOf("chip");
  expect(r.x + r.w / 2).toBeCloseTo(300, 0);
  expect(r.y + r.h / 2).toBeCloseTo(200, 0);
  game.mouseMove("zone");
  game.step(2);
  expect(ui.dragging.target.id).toBe("zone");   // the chip is under the pointer too, but ignored
  expect(ui.hovered === null || ui.hovered.id !== "chip").toBe(true);
  game.mouseUp("left");
  game.step(2);
  expect(ui.dragging).toBeNull();
  expect(() => ui.setDragImage("nope")).toThrow();
});

test("a gamepad cursor drags through ui.setPointer", () => {
  game.loadJson(main);
  game.step(2);
  ui.setDropTarget("zone", true);
  const log = record();
  const c = ui.rectOf("src");
  ui.setPointer(c.x + c.w / 2, c.y + c.h / 2, { down: true });
  game.step(1);
  ui.setPointer(400, 360, { down: true });
  game.step(1);
  expect(ui.dragging).not.toBeNull();
  ui.setPointer(640, 360, { down: true });
  game.step(1);
  ui.setPointer(640, 360, { down: false });
  game.step(1);
  expect(types(log)).toEqual(["dragStart", "dragOver", "drop"]);
  expect(log.some((e) => e.type === "click")).toBe(false);
  ui.setPointer(null);
});

test("a tooltip hides when a drag starts", () => {
  game.loadJson(main);
  game.step(2);
  game.mouseMove("src");
  game.step(40);
  expect(ui.tooltip).not.toBeNull();
  game.mouseDown("left");
  game.step(1);
  game.mouseMove({ x: 400, y: 360 });
  game.step(2);
  expect(ui.dragging).not.toBeNull();
  expect(ui.tooltip).toBeNull();
  game.mouseUp("left");
  game.step(2);
});

test("a drag ends with its scene", () => {
  game.loadJson(main);
  game.step(2);
  game.mouseMove("src");
  game.mouseDown("left");
  game.step(1);
  game.mouseMove({ x: 400, y: 360 });
  game.step(1);
  expect(ui.dragging).not.toBeNull();
  game.mouseUp("left");
  game.loadJson(main);
  game.step(2);
  expect(ui.dragging).toBeNull();
});

test("mistakes in the API explain themselves", () => {
  game.loadJson(main);
  expect(() => ui.on("dragstart", () => {})).toThrow(/dragStart/);
  expect(() => ui.setDropTarget("zone", "yes")).toThrow(/function/);
  expect(() => ui.setWorldDropTarget(5)).toThrow(/function/);
});
)JS";

struct TempProject {
    stdfs::path dir;
    explicit TempProject(const std::string& name, const char* project = kProject, const char* scene = kScene) {
        dir = fs::make_temp_dir("fa_drag_test_" + name);
        write("factoria.json", project);
        write("scenes/main.scene.json", scene);
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

TEST_CASE("drag and drop: JavaScript tests for the events, rules, the image, ui.dragging and game.drag") {
    TempProject p("js");
    p.write("tests/drag.test.js", kTest);
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(p.config(), nullptr, &err), err);
    auto t = e.commands().call("project.test", Json::object());
    REQUIRE_MESSAGE(t.ok, t.error.dump());
    CHECK_MESSAGE(t.result["ok"].get<bool>(), t.result.dump(2));
    CHECK(t.result["failed"].get<int>() == 0);
    CHECK(t.result["passed"].get<int>() >= 9);
    e.shutdown();
}

TEST_CASE("drag and drop: a bad draggable value is ignored (with a warning) and starts no drag") {
    TempProject p("bad", kProject, R"({
      "format": "factoria.scene/1",
      "entities": [ { "id": "cam", "components": { "Camera": {} } },
        { "id": "b", "components": { "Button": { "size": [100, 40], "draggable": { "slop": -3 } } } } ] })");
    p.write("tests/bad.test.js", R"JS(
import { test, expect, game } from "factoria:test";
import { ui } from "factoria";
import main from "../scenes/main.scene.json";
test("a negative slop does not start a drag", () => {
  game.loadJson(main);
  game.step(2);
  game.drag("b", { x: 700, y: 500 });
  expect(ui.dragging).toBeNull();
});
)JS");
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(p.config(), nullptr, &err), err);
    auto t = e.commands().call("project.test", Json::object());
    REQUIRE_MESSAGE(t.ok, t.error.dump());
    CHECK_MESSAGE(t.result["ok"].get<bool>(), t.result.dump(2));
    e.shutdown();
}
