// Tests that drive the UI like a player (M33.8): game.tap(action) goes through the keys bound to it, so ui_submit presses the
// focused Button, and game.checkLayout() (ui.check_layout with current: true) measures the running scene with the panels a test has
// opened and without reloading it. Run on the engine `factoria test` builds, in a small project written to a temp dir.
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
import { ui, world } from "factoria";

const load = () => { game.load("scenes/main.scene.json"); game.step(3); globalThis.spy = { clicks: 0 }; };

test("game.tap('ui_submit') presses the focused Button, like Enter or Space", () => {
  load();
  ui.focus("go");
  game.step(2);
  game.tap("ui_submit");
  expect(globalThis.spy.clicks).toBe(1);
});

test("game.tap of an action that shares its key with ui_submit presses the Button too", () => {
  load();
  ui.focus("go");
  game.step(2);
  game.tap("interact"); // bound to Space, and so is ui_submit
  expect(globalThis.spy.clicks).toBe(1);
});

test("an action with no key or button is still held for the readers of that action", () => {
  load();
  game.tap("stickonly");
  expect(world.find("spy").behaviour.stick).toBe(1);
});

test("game.checkLayout() measures a panel the test opened and does not reload the scene", () => {
  load();
  expect(game.checkLayout({ textScales: [1], pseudo: false }).issues).toEqual([]);
  world.find("side").active = true;
  game.step(2);
  const report = game.checkLayout({ textScales: [1, 2], pseudo: false });
  expect(report.ok).toBe(false);
  const kinds = report.issues.map((i) => i.kind + ":" + i.entity);
  expect(kinds).toContain("overflow:long_label");
  expect(report.issues.find((i) => i.entity === "long_label").cases.map((c) => c.textScale)).toContain(2);
  expect(world.find("side").active).toBe(true); // not reloaded: the panel is still open
  expect(ui.textScale).toBe(1); // the text size is back
  expect(() => game.checkLayout(3)).toThrow("expects an object");
});
)JS";

}  // namespace

TEST_CASE("scripts: game.tap through the UI and game.checkLayout in the current frame") {
    const stdfs::path oldRoot = fa::fs::project_root();
    const stdfs::path dir = fa::fs::make_temp_dir("fa_cli_ui_player") / "proj";
    write_text(dir / "factoria.json", R"({"format":"factoria.project/1","name":"UiPlayer","id":"com.factoria.tests.uiplayer","version":"0.1.0",
        "mainScene":"scenes/main.scene.json","display":{"width":1280,"height":720,"scaleMode":"fit","fullscreen":false,"vsync":true},
        "physics":{"fixedHz":60,"pixelsPerMeter":100},
        "input":{"actions":{"interact":["Space"],"stickonly":["GamepadLeftStickUp"]}}})");
    write_text(dir / "scenes" / "main.scene.json", R"({"format":"factoria.scene/1","entities":[
        {"id":"camera","components":{"Transform":{"position":[640,360,0]},"Camera":{}}},
        {"id":"spy","components":{"Script":{"path":"scripts/spy.js"}}},
        {"id":"go","components":{"Button":{"text":"Go","size":[160,50],"anchor":[0.5,0.2]}}},
        {"id":"marker","components":{}},
        {"id":"side","active":false,"components":{"Panel":{"size":[300,200],"anchor":[0.85,0.6]}},
         "children":[{"id":"long_label","components":{"Button":{"text":"A very long label that cannot fit in a small button",
           "size":[120,40]}}}]}]})");
    write_text(dir / "scripts" / "spy.js",
               "import { Behaviour, ui, input } from \"factoria\";\n"
               "export default class Spy extends Behaviour {\n"
               "  stick = 0;\n"
               "  onStart() { ui.on(\"click\", (e) => { if (e.id === \"go\" && globalThis.spy) globalThis.spy.clicks++; }); }\n"
               "  onUpdate() { if (input.pressed(\"stickonly\")) this.stick++; }\n"
               "}\n");
    write_text(dir / "tests" / "ui_player.test.js", kTest);

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
