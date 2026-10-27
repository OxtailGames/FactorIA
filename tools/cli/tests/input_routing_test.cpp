// Input routing as a script sees it (M33.6): a consumed action (a ui.on("cancel") handler that returns true), text input
// mode (a focused TextField takes the printable keys away from game actions) and Panel.wheelPassThrough. A small project
// with a "pause" action on P and Escape, a TextField and a modal Panel whose tests/*.test.js run on the engine
// `factoria test` builds.
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
import { input, ui, world } from "factoria";

const SCENE = "scenes/main.scene.json";
const load = () => { game.load(SCENE); game.step(3); globalThis.spy = { pauses: 0, wheel: 0 }; };

test("Escape closes a dialog and does not also open the pause menu", () => {
  load();
  const dialog = world.find("dialog");
  dialog.active = true;
  ui.on("cancel", () => {
    if (!dialog.active) return false;
    dialog.active = false;
    return true;
  });
  game.step(2);
  game.tapKey("Escape");
  game.step(3);
  expect(dialog.active).toBe(false);
  expect(globalThis.spy.pauses).toBe(0);
  game.tapKey("Escape"); // with the dialog closed the handler returns false: Escape pauses
  game.step(3);
  expect(globalThis.spy.pauses).toBe(1);
});

test("input.consume(action): later readers of the frame see it as not pressed, and so does any action on the same key", () => {
  load();
  let seen = null;
  ui.on("cancel", () => { seen = input.pressed("pause"); input.consume("pause"); });
  game.tapKey("Escape");
  game.step(3);
  expect(seen).toBe(true);
  expect(globalThis.spy.pauses).toBe(0);
  expect(() => input.consume("nope")).toThrow();
});

test("P typed in a TextField does not pause; the mode ends with the focus", () => {
  load();
  expect(input.textInputMode).toBe(false);
  ui.focus("field");
  game.step(2);
  expect(input.textInputMode).toBe(true);
  game.tapKey("P");
  game.step(3);
  expect(globalThis.spy.pauses).toBe(0);
  expect(input.down("pause")).toBe(false);
  ui.focus(null);
  game.step(2);
  expect(input.textInputMode).toBe(false);
  game.tapKey("P");
  game.step(3);
  expect(globalThis.spy.pauses).toBe(1);
});

test("a script's own text entry sets textInputMode, and a scene load clears it", () => {
  load();
  input.textInputMode = true;
  game.step(1);
  game.tapKey("P");
  game.step(3);
  expect(globalThis.spy.pauses).toBe(0);
  load();
  expect(input.textInputMode).toBe(false);
});

test("the wheel reaches a script under a modal Panel with wheelPassThrough, and not under one without", () => {
  load();
  const dialog = world.find("dialog");
  dialog.active = true;
  game.step(2);
  game.wheel(1);
  game.step(1);
  expect(globalThis.spy.wheel).toBe(0); // a plain modal keeps the wheel
  dialog.get("Panel").wheelPassThrough = true;
  game.step(1);
  game.wheel(1);
  game.step(1);
  expect(globalThis.spy.wheel).toBe(1);
});
)JS";

}  // namespace

TEST_CASE("scripts: input.consume, text input mode and Panel.wheelPassThrough") {
    const stdfs::path oldRoot = fa::fs::project_root();
    const stdfs::path dir = fa::fs::make_temp_dir("fa_cli_input_routing") / "proj";
    write_text(dir / "factoria.json", R"({"format":"factoria.project/1","name":"Routing","id":"com.factoria.tests.routing","version":"0.1.0",
        "mainScene":"scenes/main.scene.json","display":{"width":1280,"height":720,"scaleMode":"fit","fullscreen":false,"vsync":true},
        "physics":{"fixedHz":60,"pixelsPerMeter":100},"input":{"actions":{"pause":["P","Escape"]}}})");
    write_text(dir / "scenes" / "main.scene.json", R"({"format":"factoria.scene/1","entities":[
        {"id":"camera","components":{"Transform":{"position":[640,360,0]},"Camera":{}}},
        {"id":"spy","components":{"Script":{"path":"scripts/spy.js"}}},
        {"id":"field","components":{"TextField":{"size":[300,50],"anchor":[0.5,0.2]}}},
        {"id":"dialog","active":false,"components":{"Panel":{"size":[400,300],"anchor":[0.5,0.6],"modal":true}},
         "children":[{"id":"ok","components":{"Button":{"text":"Ok","size":[100,40]}}}]}]})");
    write_text(dir / "scripts" / "spy.js",
               "import { Behaviour, input } from \"factoria\";\n"
               "export default class Spy extends Behaviour {\n"
               "  onUpdate() {\n"
               "    const s = globalThis.spy;\n"
               "    if (!s) return;\n"
               "    if (input.pressed(\"pause\")) s.pauses++;\n"
               "    if (input.mouse.wheel !== 0) s.wheel = input.mouse.wheel;\n"
               "  }\n"
               "}\n");
    write_text(dir / "tests" / "routing.test.js", kTest);

    fa::cli::SessionOptions so;
    so.gfx = fa::cli::Gfx::None;
    auto session = fa::cli::Session::open(dir.string(), so);
    fa::TestReport rep = fa::cli::run_project_tests(session->engine(), "");
    CHECK_MESSAGE(rep.ok(), rep.summary());
    CHECK(rep.loadErrors.empty());
    CHECK(rep.passed == 5);
    CHECK(rep.failed == 0);
    session.reset();
    std::error_code ec;
    stdfs::remove_all(dir.parent_path(), ec);
    fa::fs::set_project_root(oldRoot);
}
