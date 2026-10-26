// Rich text through the whole engine: the project's "text" section, ui.markupProblems and ui.measureText for scripts, and a
// Button whose label has an icon run, driven from a JavaScript test.
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
  "name": "Rich Text Test",
  "id": "com.example.richtext",
  "mainScene": "scenes/main.scene.json",
  "display": { "width": 320, "height": 180 },
  "text": {
    "colors": { "good": "#80dc80", "bad": [1, 0.48, 0.42, 1] },
    "icons": { "fish": { "texture": "assets/icons.png", "region": [0, 0, 16, 16] } }
  }
})";

const char* kScene = R"({
  "format": "factoria.scene/1",
  "entities": [
    { "id": "cam", "components": { "Camera": {} } },
    { "id": "buy", "components": { "Transform": { "position": [10, 10] },
        "Button": { "text": "[c:good]Buy[/c] [icon:fish]", "markup": true, "autoSize": true, "size": [10, 10], "fontSize": 20, "anchor": [0, 0] } } },
    { "id": "raw", "components": { "Transform": { "position": [10, 60] },
        "Button": { "text": "[c:good]Buy[/c] [icon:fish]", "autoSize": true, "size": [10, 10], "fontSize": 20, "anchor": [0, 0] } } }
  ]
})";

// The label of a Button is measured as it is drawn: tags take no room and an icon is a picture as tall as the line (two
// characters when headless). Nothing here awaits, so the scene cannot change under the test.
const char* kTest = R"JS(
import { test, expect, game } from "factoria:test";
import { ui } from "factoria";
import scene from "../scenes/main.scene.json";

test("a Button label with an icon run is as wide as its visible characters, and the same label without markup shows the tags", () => {
  game.loadJson(scene);
  ui.layout();
  const buy = ui.rectOf("buy"), raw = ui.rectOf("raw");
  // the label is "Buy " and a picture as tall as the line (1:1), with no room for the tags
  const icon = ui.measureText("[icon:fish]", { fontSize: 20, markup: true });
  expect(icon.width).toBeGreaterThan(0);
  expect(icon.width).toBeCloseTo(icon.height, 3);
  const label = ui.measureText("Buy ", { fontSize: 20 }).width + icon.width;
  expect(ui.measureText("[c:good]Buy[/c] [icon:fish]", { fontSize: 20, markup: true }).width).toBeCloseTo(label, 3);
  expect(buy.w).toBeGreaterThanOrEqual(label);
  expect(buy.w).toBeLessThan(raw.w);       // the raw label is longer: it shows [c:good] and [icon:fish]
  // [b] around the text is the bold option, which a regular face emboldens (wider, never narrower)
  const bold = ui.measureText("[b]Buy[/b]", { fontSize: 20, markup: true }).width;
  expect(bold).toBeCloseTo(ui.measureText("Buy", { fontSize: 20, bold: true }).width, 3);
  expect(bold).toBeGreaterThanOrEqual(ui.measureText("Buy", { fontSize: 20 }).width);
});

test("ui.markupProblems reads the markup against the project's text section", () => {
  expect(ui.markupProblems("[c:good]Sold[/c] [b]3[/b] [icon:fish]")).toEqual([]);
  const problems = ui.markupProblems("[c:gode]x[/c] [icon:fsh] [oops] [b]y");
  expect(problems.length).toBe(4);
  expect(problems[0]).toMatch(/unknown tag \[oops\]/);
  expect(problems.join("\n")).toMatch(/unknown colour 'gode'.*good/);
  expect(problems.join("\n")).toMatch(/unknown icon 'fsh'.*fish/);
  expect(problems.join("\n")).toMatch(/\[b\] is never closed/);
});
)JS";

struct TempProject {
    stdfs::path dir;
    explicit TempProject(const std::string& name, const char* project = kProject) {
        dir = fs::make_temp_dir("fa_rich_text_test_" + name);
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

TEST_CASE("rich text: a JavaScript test measures a Button label with an icon run and checks the markup") {
    TempProject p("js");
    p.write("tests/rich.test.js", kTest);
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(p.config(), nullptr, &err), err);
    auto t = e.commands().call("project.test", Json::object());
    REQUIRE_MESSAGE(t.ok, t.error.dump());
    CHECK_MESSAGE(t.result["ok"].get<bool>(), t.result.dump(2));
    CHECK(t.result["passed"].get<int>() == 2);
    e.shutdown();
}

TEST_CASE("rich text: a broken text section is reported at start and counts as empty") {
    TempProject p("broken", R"({"name": "x", "mainScene": "scenes/main.scene.json",
      "text": {"colors": {"good": 12}, "icons": {"fish": {"texture": "assets/i.png"}}}})");
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(p.config(), nullptr, &err), err);
    const auto info = e.commands().call("engine.info", Json::object());
    REQUIRE(info.ok);
    REQUIRE(info.result.contains("startupProblems"));
    bool found = false;
    for (const Json& line : info.result["startupProblems"]) {
        const std::string s = line.get<std::string>();
        if (s.rfind("text:", 0) == 0) {
            found = true;
            CHECK(s.find("/text/colors/good") != std::string::npos);
            CHECK(s.find("hint") != std::string::npos);
            CHECK(s.find("more") != std::string::npos);  // the icon without a region is the second problem
        }
    }
    CHECK(found);
    // ignored as a whole: [c:good] is unknown now
    auto r = e.commands().call("script.eval", Json{{"code", "ui.markupProblems('[c:good]x[/c]').length"}});
    REQUIRE_MESSAGE(r.ok, r.error.dump());
    CHECK(r.result["value"] == 1);
    e.shutdown();
}
