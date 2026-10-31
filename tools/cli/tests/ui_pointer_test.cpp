// The UI hit test, the virtual pointer, the consumed wheel and an empty focus as a script sees them (ui.widgetAt,
// ui.setPointer, ui.pointerOverUi, ui.wheelConsumed, ui.focus(null)): a small project with a ScrollList, two buttons and a
// Panel whose tests/*.test.js run on the engine `factoria test` builds.
#include <doctest.h>

#include <filesystem>
#include <string>

#include "common.h"  // tools/cli/src: Session, run_project_tests
#include "fa/core/fs.h"
#include "fa/core/json.h"

namespace stdfs = std::filesystem;

namespace {

void write_text(const stdfs::path& p, const std::string& text) { REQUIRE(fa::fs::write_text(p.generic_string(), text).ok()); }

const char* kTest = R"JS(
import { test, expect, game } from "factoria:test";
import { input, ui, scene, world } from "factoria";

const SCENE = "scenes/main.scene.json";
const centre = (id) => { const r = ui.rectOf(id); return { x: r.x + r.w / 2, y: r.y + r.h / 2 }; };
const load = () => { game.load(SCENE); game.step(3); };

test("ui.widgetAt: the topmost widget, a Panel, nothing over empty space or a row the list clips", () => {
  load();
  expect(ui.widgetAt(centre("go").x, centre("go").y).id).toBe("go");
  expect(ui.widgetAt(centre("row0").x, centre("row0").y).id).toBe("row0");
  expect(ui.widgetAt(centre("card").x + 100, centre("card").y + 100).id).toBe("card");
  expect(ui.widgetAt(5, 700)).toBe(null);
  const list = ui.rectOf("list");
  const clipped = ui.rectOf("row4");
  expect(clipped.y).toBeGreaterThan(list.y + list.h);
  expect(ui.widgetAt(clipped.x + 5, clipped.y + 5)).toBe(null);
  expect(() => ui.widgetAt("a", 1)).toThrow();
});

test("ui.setPointer hovers and clicks a Button like the mouse, until setPointer(null)", () => {
  load();
  let clicks = 0;
  const off = ui.on("click", "other", () => clicks++);
  const p = centre("other");
  ui.setPointer(p.x, p.y);
  game.step(2);
  expect(ui.hovered.id).toBe("other");
  expect(ui.pointerOverUi).toBe(true);
  ui.setPointer(p.x, p.y, { down: true });
  game.step(1);
  ui.setPointer(p.x, p.y, { down: false });
  game.step(2);
  expect(clicks).toBe(1);
  ui.setPointer(2, 700);
  game.step(2);
  expect(ui.hovered).toBe(null);
  expect(ui.pointerOverUi).toBe(false);
  ui.setPointer(null);
  game.mouseMove(centre("go"));
  game.step(2);
  expect(ui.hovered.id).toBe("go");
  off();
});

test("the wheel over a ScrollList scrolls it and input.mouse.wheel reads 0; elsewhere it passes", () => {
  load();
  world.find("camera").add("Script", { path: "scripts/spy.js" });
  game.step(1);
  const y0 = ui.rectOf("row0").y;
  game.mouseMove(centre("list"));
  game.step(2);
  game.wheel(-1);
  game.step(1);
  expect(globalThis.spy.wheel).toBe(0);
  expect(globalThis.spy.consumed).toBe(true);
  game.step(2);
  expect(ui.rectOf("row0").y).toBeLessThan(y0);
  game.mouseMove({ x: 5, y: 700 });
  game.step(2);
  game.wheel(-1);
  game.step(1);
  expect(globalThis.spy.wheel).toBe(-1);
  expect(globalThis.spy.consumed).toBe(false);
});

test("ui.focus(null) stays empty over frames until an arrow key", () => {
  load();
  expect(ui.focused.id).toBe("go"); // its autoFocus
  ui.focus(null);
  game.step(10);
  expect(ui.focused).toBe(null);
  game.tapKey("Down"); // wakes autoFocus, does not also move it
  game.step(1);
  expect(ui.focused.id).toBe("go");
  game.tapKey("Down");
  game.step(1);
  expect(ui.focused.id).toBe("other");
});
)JS";

}  // namespace

TEST_CASE("scripts: ui.widgetAt, ui.setPointer, the consumed wheel and ui.focus(null)") {
    const stdfs::path oldRoot = fa::fs::project_root();
    const stdfs::path dir = fa::fs::make_temp_dir("fa_cli_ui_pointer") / "proj";
    write_text(dir / "factoria.json", R"({"format":"factoria.project/1","name":"Pointer","id":"com.factoria.tests.pointer","version":"0.1.0",
        "mainScene":"scenes/main.scene.json","display":{"width":1280,"height":720,"scaleMode":"fit","fullscreen":false,"vsync":true},
        "physics":{"fixedHz":60,"pixelsPerMeter":100},"input":{"actions":{"confirm":["Enter"]}}})");
    write_text(dir / "scenes" / "main.scene.json", R"({"format":"factoria.scene/1","entities":[
        {"id":"camera","components":{"Transform":{"position":[640,360,0]},"Camera":{}}},
        {"id":"card","components":{"Panel":{"size":[400,300],"anchor":[0.75,0.5],"layer":100}}},
        {"id":"go","components":{"Button":{"text":"Go","size":[200,50],"anchor":[0.75,0.4],"layer":300,"autoFocus":true}}},
        {"id":"other","components":{"Button":{"text":"Other","size":[200,50],"anchor":[0.75,0.6],"layer":300}}},
        {"id":"list","components":{"ScrollList":{"size":[300,100],"anchor":[0.2,0.2],"spacing":0,"padding":[0,0,0,0]}},
         "children":[
           {"id":"row0","components":{"Button":{"text":"zero","size":[200,40]}}},
           {"id":"row1","components":{"Button":{"text":"one","size":[200,40]}}},
           {"id":"row2","components":{"Button":{"text":"two","size":[200,40]}}},
           {"id":"row3","components":{"Button":{"text":"three","size":[200,40]}}},
           {"id":"row4","components":{"Button":{"text":"four","size":[200,40]}}}]}]})");
    write_text(dir / "scripts" / "spy.js",
               "import { Behaviour, input, ui } from \"factoria\";\n"
               "export default class Spy extends Behaviour {\n"
               "  onUpdate() { globalThis.spy = { wheel: input.mouse.wheel, consumed: ui.wheelConsumed }; }\n"
               "}\n");
    write_text(dir / "tests" / "pointer.test.js", kTest);

    fa::cli::SessionOptions so;
    so.gfx = fa::cli::Gfx::None;
    auto session = fa::cli::Session::open(dir.string(), so);
    fa::TestReport rep = fa::cli::run_project_tests(session->engine(), "");
    CHECK_MESSAGE(rep.ok(), rep.summary());
    CHECK(rep.loadErrors.empty());
    CHECK(rep.passed == 4);
    CHECK(rep.failed == 0);
    session.reset();
    std::error_code ec;
    stdfs::remove_all(dir.parent_path(), ec);
    fa::fs::set_project_root(oldRoot);
}
