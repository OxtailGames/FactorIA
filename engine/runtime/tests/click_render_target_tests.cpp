// game.click and a page shown on a mesh: the UI of a stage drawn by a camera with Camera.renderTarget, the target on a MeshRenderer.
// A click at a screen position over the mesh reaches the widget of the page and names it (`widget`, `via`); a click by id on a widget that
// only the page shows is aimed backwards through the mesh and goes where the real mouse would reach it; the ones that cannot be reached
// say why. Real engine, real renderer (the headless GPU).
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
  "name": "Click Target Test",
  "id": "com.example.clicktarget",
  "mainScene": "scenes/main.scene.json",
  "display": { "width": 320, "height": 180, "scaleMode": "pixelPerfect" },
  "physics": { "fixedHz": 60, "pixelsPerMeter": 100 }
})";

// The stage (tag "page") is 200 x 100 pixels seen by an orthographic camera at (1000, 0): page pixel (px, py) is world (1000 + px - 100,
// 50 - py). The main camera hides the stage. toggle (page 60, 50), slider (page 20..80 at y 80), vanish (page 140, 50: a script turns
// it off in the frame it is pressed), far (page 500, 50: outside the picture), and a toggle nobody draws on a page ("plain").
// "screen" shows the page on a quad. "cover" (not in the scene: tests add it) is another quad in front.
const char* kScene = R"({
  "format": "factoria.scene/1",
  "entities": [
    { "id": "cam", "components": { "Transform": { "position": [0, 0, 3] },
                                   "Camera": { "projection": "perspective", "clearColor": "#000000", "hideTags": ["page", "other"] } } },
    { "id": "pagecam", "components": { "Transform": { "position": [1000, 0, 0] },
                                       "Camera": { "renderTarget": "page", "renderTargetSize": [200, 100], "orthoSize": 50,
                                                   "clearColor": "#204060", "showTags": ["page"] } } },
    { "id": "othercam", "components": { "Transform": { "position": [2000, 0, 0] },
                                        "Camera": { "renderTarget": "other", "renderTargetSize": [200, 100], "orthoSize": 50,
                                                    "clearColor": "#602040", "showTags": ["other"] } } },
    { "id": "toggle", "tags": ["page"], "components": { "Transform": { "position": [960, 0, 0] }, "Shape2D": { "size": [30, 20], "color": "#e02020" },
                                                        "Interactable": { "kind": "toggle" } } },
    { "id": "slider", "tags": ["page"], "components": { "Transform": { "position": [950, -30, 0] }, "Shape2D": { "size": [60, 10], "color": "#20c040" },
                                                        "Interactable": { "kind": "slider" } } },
    { "id": "vanish", "tags": ["page"], "components": { "Transform": { "position": [1040, 0, 0] }, "Shape2D": { "size": [30, 20], "color": "#ffffff" },
                                                        "Interactable": { "kind": "button" } } },
    { "id": "far", "tags": ["page"], "components": { "Transform": { "position": [1400, 0, 0] }, "Shape2D": { "size": [30, 20], "color": "#ffffff" },
                                                      "Interactable": { "kind": "toggle" } } },
    { "id": "plain", "components": { "Transform": { "position": [1050, 20, 0] }, "Shape2D": { "size": [30, 20], "color": "#ffffff" },
                                     "Interactable": { "kind": "toggle" } } },
    { "id": "screen", "components": { "Transform": { "scale": [2, 1, 1] }, "MeshRenderer": { "mesh": "quad", "texture": "target:page", "unlit": true } } },
    { "id": "turner", "components": { "Script": { "path": "scripts/turner.js" } } }
  ]
})";

const char* kTurner = R"JS(
import { Behaviour, world, input } from 'factoria';
export default class Turner extends Behaviour {
  onUpdate() {
    const v = world.find('vanish');
    if (v.active && input.mouse.pressed('left') && v.get('Interactable').pressed) v.active = false;
  }
}
)JS";

struct Rig {
    stdfs::path dir;
    Engine e;
    explicit Rig(const std::string& scene = kScene) {
        dir = fs::make_temp_dir("fa_click_target");
        stdfs::create_directories(dir / "scenes");
        stdfs::create_directories(dir / "scripts");
        std::ofstream(dir / "factoria.json", std::ios::binary) << kProject;
        std::ofstream(dir / "scenes/main.scene.json", std::ios::binary) << scene;
        std::ofstream(dir / "scripts/turner.js", std::ios::binary) << kTurner;
        EngineConfig c;
        c.projectDir = dir.generic_string();
        c.headless = true;
        c.hotReload = false;
        std::string err;
        REQUIRE_MESSAGE(e.init(c, nullptr, &err), err);
        REQUIRE(e.renderer());
        e.step(2);
    }
    ~Rig() {
        e.shutdown();
        std::error_code ec;
        stdfs::remove_all(dir, ec);
    }
    Entity id(const char* name) { return e.world().find(name); }
    Interactable& ia(const char* name) { return *e.world().get<Interactable>(id(name)); }
    // The screen point where the quad shows page pixel (px, py).
    Vec2 page(float px, float py) {
        return e.renderer()->world_to_screen(e.world().world_matrix(id("screen")).transform_point({px / 200.0f - 0.5f, 0.5f - py / 100.0f, 0.0f}));
    }
    CommandResult click(Json args) { return e.commands().call("game.click", args); }
    CommandResult click_at(Vec2 p) { return click(Json{{"position", Json::array({p.x, p.y})}}); }
    CommandResult click_id(const char* name) { return click(Json{{"id", name}}); }
    void add_quad(const char* name, const char* target, Json transform) {
        const Json e1 = Json{{"id", name}, {"components", Json{{"Transform", transform},
                                                             {"MeshRenderer", Json{{"mesh", "quad"}, {"texture", std::string("target:") + target}, {"unlit", true}}}}}};
        auto r = e.commands().call("scene.spawn", e1);
        REQUIRE_MESSAGE(r.ok, r.error.dump());
        e.step(2);
    }
};

std::string text(const CommandResult& r) { return r.error.dump(); }

}  // namespace

TEST_CASE("game.click {position} over a mesh that shows a page reports the widget it reached and how") {
    Rig r;
    auto res = r.click_at(r.page(60, 50));
    REQUIRE_MESSAGE(res.ok, text(res));
    CHECK(res.result["widget"] == "toggle");
    REQUIRE(res.result.contains("via"));
    CHECK(res.result["via"]["mesh"] == "screen");
    CHECK(res.result["via"]["target"] == "pagecam");
    CHECK(r.ia("toggle").on);
    // The slider under the mouse is named too (it is not the toggle).
    res = r.click_at(r.page(50, 80));
    REQUIRE_MESSAGE(res.ok, text(res));
    CHECK(res.result["widget"] == "slider");
    // Empty picture: no widget, but the click went through the mesh and the result says so.
    res = r.click_at(r.page(100, 5));
    REQUIRE_MESSAGE(res.ok, text(res));
    CHECK(res.result["widget"].is_null());
    CHECK(res.result["via"]["mesh"] == "screen");
    // Off the mesh: no widget, no via.
    res = r.click_at({300, 170});
    REQUIRE_MESSAGE(res.ok, text(res));
    CHECK(res.result["widget"].is_null());
    CHECK_FALSE(res.result.contains("via"));
}

TEST_CASE("game.click names the widget a click removes in the frame the button went down") {
    Rig r;
    auto res = r.click_at(r.page(140, 50));
    REQUIRE_MESSAGE(res.ok, text(res));
    CHECK_FALSE(r.e.world().active_in_hierarchy(r.id("vanish")));  // the script turned the page widget off while it was pressed
    CHECK(res.result["widget"] == "vanish");
    CHECK(res.result["via"]["mesh"] == "screen");
}

TEST_CASE("game.click {id} of a widget that only a page shows goes through the mesh") {
    Rig r;
    auto res = r.click_id("toggle");
    REQUIRE_MESSAGE(res.ok, text(res));
    CHECK(res.result["widget"] == "toggle");
    CHECK(res.result["via"]["mesh"] == "screen");
    CHECK(res.result["via"]["target"] == "pagecam");
    CHECK(r.ia("toggle").on);
    // It aimed at the toggle's own place on the mesh.
    const Vec2 want = r.page(60, 50);
    CHECK(res.result["position"][0].get<float>() == doctest::Approx(want.x).epsilon(0.02));
    CHECK(res.result["position"][1].get<float>() == doctest::Approx(want.y).epsilon(0.02));
    // A slider is clicked at the centre of its track: half way.
    res = r.click_id("slider");
    REQUIRE_MESSAGE(res.ok, text(res));
    CHECK(res.result["widget"] == "slider");
    CHECK(r.ia("slider").value == doctest::Approx(0.5f).epsilon(0.1f));
    // A click on the toggle again flips it back, through the same way.
    REQUIRE(r.click_id("toggle").ok);
    CHECK_FALSE(r.ia("toggle").on);
}

TEST_CASE("game.click {id} finds a free place of the widget when a mesh in front covers part of it") {
    Rig r;
    // A second page in front of the left of the screen mesh. The slider is page x 20..80 (mesh x -0.8..-0.2 at z 0); the cover is a unit quad
    // 0.5 units nearer the camera, so it spans screen-plane x -1.8..-0.35 there: the centre of the slider is under it, its right end is not.
    r.add_quad("cover", "other", Json{{"position", Json::array({-0.79, 0.0, 0.5})}, {"scale", Json::array({1.0, 1.0, 1.0})}});
    const Vec2 centre = r.page(50, 80);
    auto probe = r.click_at(centre);
    REQUIRE_MESSAGE(probe.ok, text(probe));
    CHECK(probe.result["via"]["mesh"] == "cover");  // the mouse at the slider's centre now reaches the cover's page, not the slider
    CHECK(probe.result["widget"].is_null());
    auto res = r.click_id("slider");
    REQUIRE_MESSAGE(res.ok, text(res));
    CHECK(res.result["widget"] == "slider");
    CHECK(res.result["via"]["mesh"] == "screen");
}

TEST_CASE("game.click {id} says why a widget on a page cannot be clicked") {
    SUBCASE("outside the view of the target camera") {
        Rig r;
        auto res = r.click_id("far");
        CHECK_FALSE(res.ok);
        const std::string m = text(res);
        CHECK(m.find("'far' cannot be clicked") != std::string::npos);
        CHECK(m.find("outside the view") != std::string::npos);
        CHECK(m.find("pagecam") != std::string::npos);
        CHECK_FALSE(r.ia("far").on);
    }
    SUBCASE("no mesh shows the target") {
        Rig r;
        r.e.world().destroy(r.id("screen"));
        r.e.step(2);
        auto res = r.click_id("toggle");
        CHECK_FALSE(res.ok);
        CHECK(text(res).find("no MeshRenderer shows") != std::string::npos);
    }
    SUBCASE("the mesh is inactive") {
        Rig r;
        r.e.world().info(r.id("screen")).active = false;
        r.e.step(2);
        auto res = r.click_id("toggle");
        CHECK_FALSE(res.ok);
        CHECK(text(res).find("inactive") != std::string::npos);
        CHECK_FALSE(r.ia("toggle").on);
    }
    SUBCASE("the mesh is off the screen") {
        Rig r;
        r.e.world().get<Transform>(r.id("screen"))->position = {50, 0, 0};
        r.e.step(2);
        auto res = r.click_id("toggle");
        CHECK_FALSE(res.ok);
        CHECK(text(res).find("off the screen") != std::string::npos);
    }
    SUBCASE("another page's mesh covers it all") {
        Rig r;
        r.add_quad("cover", "other", Json{{"position", Json::array({0.0, 0.0, 0.5})}, {"scale", Json::array({3.0, 3.0, 1.0})}});
        auto res = r.click_id("toggle");
        CHECK_FALSE(res.ok);
        const std::string m = text(res);
        CHECK(m.find("covered") != std::string::npos);
        CHECK(m.find("'cover' is in front") != std::string::npos);
        CHECK_FALSE(r.ia("toggle").on);
    }
    SUBCASE("a page shown on a mesh the main camera does not draw (a target inside a target)") {
        Rig r;
        r.e.world().info(r.id("screen")).tags = {"other"};  // only othercam draws it now; the main camera hides "other"
        r.e.step(2);
        auto res = r.click_id("toggle");
        CHECK_FALSE(res.ok);
        CHECK(text(res).find("inside another render target") != std::string::npos);
    }
}

TEST_CASE("game.click {id}: a widget no camera shows keeps its old error, one in plain view its old click") {
    Rig r;
    // "plain" is not tagged: the main camera draws it (off screen, far away) and no page does: the old behaviour (a click where it is).
    auto res = r.click_id("plain");
    CHECK_MESSAGE(res.ok, text(res));
    // A widget the main camera hides and no render-target camera draws: the error says both.
    r.e.world().info(r.id("plain")).tags = {"other"};
    r.e.world().get<Camera>(r.id("othercam"))->showTags = Json::array({"nothing"});
    r.e.step(2);
    res = r.click_id("plain");
    CHECK_FALSE(res.ok);
    CHECK(text(res).find("no camera with a Camera.renderTarget draws it") != std::string::npos);
}

TEST_CASE("render.pick names the widget through the mesh and says via") {
    Rig r;
    auto res = r.e.commands().call("render.pick", Json{{"position", Json::array({r.page(60, 50).x, r.page(60, 50).y})}});
    REQUIRE_MESSAGE(res.ok, text(res));
    CHECK(res.result["widget"] == "toggle");
    CHECK(res.result["via"]["mesh"] == "screen");
    CHECK(res.result["via"]["target"] == "pagecam");
}

TEST_CASE("game.click by id from a JavaScript test reaches a widget a page shows") {
    Rig r;
    stdfs::create_directories(r.dir / "tests");
    std::ofstream(r.dir / "tests/page.test.js", std::ios::binary) << R"JS(
import { test, expect, game } from "factoria:test";
test("a click by id goes through the mesh", () => {
  game.click("toggle");
  expect(game.find("toggle").get("Interactable").on).toBe(true);
  game.click(game.find("toggle"));
  expect(game.find("toggle").get("Interactable").on).toBe(false);
  expect(() => game.click("far")).toThrow(/outside the view/);
});
)JS";
    auto t = r.e.commands().call("project.test", Json::object());
    REQUIRE_MESSAGE(t.ok, t.error.dump());
    CHECK_MESSAGE(t.result["ok"].get<bool>(), t.result.dump(2));
    CHECK(t.result["passed"].get<int>() == 1);
}
