// Camera.showTags / hideTags and the pointer: a camera only hits what it draws. The main view's Interactables, game.click by id,
// and the page of a render target shown on a mesh. Real engine, real renderer (the headless GPU).
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
  "name": "Camera Tags Pointer Test",
  "id": "com.example.cameratags",
  "mainScene": "scenes/main.scene.json",
  "display": { "width": 320, "height": 180, "scaleMode": "pixelPerfect" },
  "physics": { "fixedHz": 60, "pixelsPerMeter": 100 }
})";

// The main camera is orthographic (one world unit per design pixel, (0, 0) at the centre of the 320 x 180 screen) and hides "hide".
// "btn" (tagged hide) and "btn2" sit side by side. The page (200 x 100 at (1000, 0), a camera that draws only "page") is shown on a quad
// above the buttons: "toggle" is tagged page, "ghost" is not, so the page camera does not draw it.
const char* kScene = R"({
  "format": "factoria.scene/1",
  "entities": [
    { "id": "cam", "components": { "Camera": { "clearColor": "#000000", "hideTags": ["hide"] } } },
    { "id": "pagecam", "components": { "Transform": { "position": [1000, 0, 0] },
                                       "Camera": { "renderTarget": "page", "renderTargetSize": [200, 100], "orthoSize": 50,
                                                   "clearColor": "#204060", "showTags": ["page"] } } },
    { "id": "btn", "tags": ["hide"], "components": { "Transform": { "position": [-60, -50, 0] }, "Shape2D": { "size": [40, 20], "color": "#e02020" },
                                                     "Interactable": { "kind": "toggle" } } },
    { "id": "btn2", "components": { "Transform": { "position": [60, -50, 0] }, "Shape2D": { "size": [40, 20], "color": "#20c040" },
                                    "Interactable": { "kind": "toggle" } } },
    { "id": "toggle", "tags": ["page"], "components": { "Transform": { "position": [960, 0, 0] }, "Shape2D": { "size": [30, 20], "color": "#e02020" },
                                                        "Interactable": { "kind": "toggle" } } },
    { "id": "ghost", "components": { "Transform": { "position": [1050, 20, 0] }, "Shape2D": { "size": [30, 20], "color": "#ffffff" },
                                     "Interactable": { "kind": "toggle" } } },
    { "id": "screen", "components": { "Transform": { "position": [0, 30, 0], "scale": [128, 64, 1] },
                                      "MeshRenderer": { "mesh": "quad", "texture": "target:page", "unlit": true } } }
  ]
})";

struct Rig {
    stdfs::path dir;
    Engine e;
    Rig() {
        dir = fs::make_temp_dir("fa_camera_tags_pointer");
        stdfs::create_directories(dir / "scenes");
        std::ofstream(dir / "factoria.json", std::ios::binary) << kProject;
        std::ofstream(dir / "scenes/main.scene.json", std::ios::binary) << kScene;
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
        std::error_code ec;
        stdfs::remove_all(dir, ec);
    }
    Entity id(const char* name) { return e.world().find(name); }
    Interactable& ia(const char* name) { return *e.world().get<Interactable>(id(name)); }
    // The screen point (design pixels, top-left origin) of a world point of the main camera.
    Vec2 screen_of(Vec3 p) { return e.renderer()->world_to_screen(p); }
    // The screen point where the quad shows page pixel (px, py): the quad maps u to x and v down to y.
    Vec2 page(float px, float py) {
        const float u = px / 200.0f, v = py / 100.0f;
        return e.renderer()->world_to_screen(e.world().world_matrix(id("screen")).transform_point({u - 0.5f, 0.5f - v, 0.0f}));
    }
    void mouse(Vec2 p, bool down) {
        e.commands().call("game.input", Json{{"mouse", Json{{"position", Json::array({p.x, p.y})}, {"left", down}}}});
        e.step(1);
    }
    void tap(Vec2 p) {
        mouse(p, true);
        mouse(p, false);
    }
};

}  // namespace

TEST_CASE("camera tags pointer: the main camera does not hit an Interactable it hides") {
    Rig r;
    const Vec2 hidden = r.screen_of({-60, -50, 0});
    const Vec2 shown = r.screen_of({60, -50, 0});
    r.mouse(hidden, false);
    CHECK_FALSE(r.ia("btn").hovered);
    r.tap(hidden);
    CHECK_FALSE(r.ia("btn").on);
    r.mouse(shown, false);
    CHECK(r.ia("btn2").hovered);
    r.tap(shown);
    CHECK(r.ia("btn2").on);
}

TEST_CASE("camera tags pointer: game.click by id says why a hidden Interactable cannot be clicked, a shown one works") {
    Rig r;
    const auto hidden = r.e.commands().call("game.click", Json{{"id", "btn"}});
    CHECK_FALSE(hidden.ok);
    CHECK(hidden.error.dump().find("showTags") != std::string::npos);
    CHECK_FALSE(r.ia("btn").on);
    const auto shown = r.e.commands().call("game.click", Json{{"id", "btn2"}});
    CHECK_MESSAGE(shown.ok, shown.error.dump());
    CHECK(r.ia("btn2").on);
}

TEST_CASE("camera tags pointer: the page camera's mask decides what the mesh passes the pointer to") {
    Rig r;
    // "toggle" is tagged page: the pointer over its picture reaches it.
    r.mouse(r.page(60, 50), false);
    CHECK(r.ia("toggle").hovered);
    r.tap(r.page(60, 50));
    CHECK(r.ia("toggle").on);
    // "ghost" is at page pixel (150, 30) but the page camera does not draw it, so there is nothing to click in the picture.
    r.mouse(r.page(150, 30), false);
    CHECK_FALSE(r.ia("ghost").hovered);
    r.tap(r.page(150, 30));
    CHECK_FALSE(r.ia("ghost").on);
}

TEST_CASE("camera tags pointer: a tag added to an entity takes effect on the next pointer move") {
    Rig r;
    const Vec2 hidden = r.screen_of({-60, -50, 0});
    r.e.world().info(r.id("btn")).tags.clear();  // no longer tagged "hide"
    r.mouse(hidden, false);
    CHECK(r.ia("btn").hovered);
    r.e.world().info(r.id("btn")).tags = {"hide"};
    r.mouse({1, 1}, false);
    CHECK_FALSE(r.ia("btn").hovered);
    r.mouse(hidden, false);
    CHECK_FALSE(r.ia("btn").hovered);
}
