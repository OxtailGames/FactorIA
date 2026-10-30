// The pointer through a render target: a mesh shows the picture of a camera with Camera.renderTarget, and a mouse over the mesh
// reaches the Interactables of that camera's page by the mesh's UV (hover, click, slider drags), on a flat quad and on a curved,
// stretched cylinder. Real engine, real renderer (the headless GPU), real meshes.
#include <doctest.h>

#include <cmath>
#include <filesystem>
#include <fstream>

#include "fa/core/fs.h"
#include "fa/runtime/engine.h"

using namespace fa;
namespace stdfs = std::filesystem;

namespace {

const char* kProject = R"({
  "format": "factoria.project/1",
  "name": "Target Pointer Test",
  "id": "com.example.targetpointer",
  "mainScene": "scenes/main.scene.json",
  "display": { "width": 320, "height": 180, "scaleMode": "pixelPerfect" },
  "physics": { "fixedHz": 60, "pixelsPerMeter": 100 }
})";

// The page is 200 x 100 pixels seen by an orthographic camera at (1000, 0): page pixel (px, py) is world (1000 + px - 100, 50 - py).
// A toggle (the click flips `on`) at page pixel (60, 50), a slider along page x 20..80 at y 80, and a toggle at (150, 30) that is on
// the back of the cylinder.
std::string scene(const std::string& mesh, const std::string& scale) {
    return R"({
  "format": "factoria.scene/1",
  "entities": [
    { "id": "cam", "components": { "Transform": { "position": [0, 0, 3] },
                                   "Camera": { "projection": "perspective", "clearColor": "#000000" } } },
    { "id": "pagecam", "components": { "Transform": { "position": [1000, 0, 0] },
                                       "Camera": { "renderTarget": "page", "renderTargetSize": [200, 100], "orthoSize": 50,
                                                   "clearColor": "#204060" } } },
    { "id": "toggle", "components": { "Transform": { "position": [960, 0, 0] }, "Shape2D": { "size": [30, 20], "color": "#e02020" },
                                      "Interactable": { "kind": "toggle" } } },
    { "id": "slider", "components": { "Transform": { "position": [950, -30, 0] }, "Shape2D": { "size": [60, 10], "color": "#20c040" },
                                      "Interactable": { "kind": "slider" } } },
    { "id": "back", "components": { "Transform": { "position": [1050, 20, 0] }, "Shape2D": { "size": [30, 20], "color": "#ffffff" },
                                    "Interactable": { "kind": "toggle" } } },
    { "id": "screen", "components": { "Transform": { "scale": )" + scale + R"( },
                                      "MeshRenderer": { "mesh": ")" + mesh + R"(", "texture": "target:page", "unlit": true } } }
  ]
})";
}

struct TempProject {
    stdfs::path dir;
    TempProject(const std::string& name, const std::string& mesh, const std::string& scale) {
        dir = fs::make_temp_dir("fa_target_pointer_" + name);
        stdfs::create_directories(dir / "scenes");
        std::ofstream(dir / "factoria.json", std::ios::binary) << kProject;
        std::ofstream(dir / "scenes/main.scene.json", std::ios::binary) << scene(mesh, scale);
    }
    ~TempProject() {
        std::error_code ec;
        stdfs::remove_all(dir, ec);
    }
};

struct Rig {
    TempProject project;
    Engine e;
    bool cylinder;

    Rig(const char* name, const char* mesh, const char* scale) : project(name, mesh, scale), cylinder(std::string(mesh) == "cylinder") {
        EngineConfig c;
        c.projectDir = project.dir.generic_string();
        c.headless = true;
        c.hotReload = false;
        std::string err;
        REQUIRE_MESSAGE(e.init(c, nullptr, &err), err);
        REQUIRE(e.renderer());
        e.step(2);
    }
    Entity id(const char* name) { return e.world().find(name); }
    Interactable& ia(const char* name) { return *e.world().get<Interactable>(id(name)); }

    // The screen point where the mesh shows page pixel (px, py): the quad maps u to x and v down to y; the cylinder wraps u round it.
    Vec2 screen(float px, float py) {
        const float u = px / 200.0f, v = py / 100.0f;
        Vec3 local = cylinder ? Vec3{0.5f * std::cos(u * kTau), 0.5f - v, 0.5f * std::sin(u * kTau)} : Vec3{u - 0.5f, 0.5f - v, 0.0f};
        return e.renderer()->world_to_screen(e.world().world_matrix(id("screen")).transform_point(local));
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

void check_page(Rig& r, float sliderTol) {
    // Hover: the pointer over the picture of the toggle hovers the toggle, which is 940 world units away from the camera's view.
    r.mouse(r.screen(60, 50), false);
    CHECK(r.ia("toggle").hovered);
    CHECK_FALSE(r.ia("slider").hovered);
    r.mouse(r.screen(60, 68), false);  // between the toggle (y 40..60) and the slider (y 75..85): nothing
    CHECK_FALSE(r.ia("toggle").hovered);
    CHECK_FALSE(r.ia("slider").hovered);
    r.mouse(r.screen(50, 80), false);
    CHECK(r.ia("slider").hovered);
    // Click flips the toggle; a press that ends off it does not.
    r.mouse({5, 5}, false);
    CHECK_FALSE(r.ia("toggle").on);
    r.tap(r.screen(60, 50));
    CHECK(r.ia("toggle").on);
    r.mouse(r.screen(60, 50), true);
    CHECK(r.ia("toggle").pressed);
    r.mouse(r.screen(110, 10), true);
    r.mouse(r.screen(110, 10), false);
    CHECK(r.ia("toggle").on);  // still on: released away from it
    r.tap(r.screen(60, 50));
    CHECK_FALSE(r.ia("toggle").on);
    // A click on empty picture or off the mesh does nothing to them.
    r.tap(r.screen(100, 5));
    r.tap({300, 170});
    CHECK_FALSE(r.ia("toggle").on);
    // Slider drag: the track is page x 20..80.
    r.mouse(r.screen(35, 80), true);
    CHECK(r.ia("slider").pressed);
    CHECK(r.ia("slider").value == doctest::Approx(0.25f).epsilon(sliderTol));
    r.mouse(r.screen(65, 80), true);
    CHECK(r.ia("slider").value == doctest::Approx(0.75f).epsilon(sliderTol));
    r.mouse(r.screen(65, 95), true);  // dragged off the bar along the page: only the position along the track counts
    CHECK(r.ia("slider").value == doctest::Approx(0.75f).epsilon(sliderTol));
    r.mouse({315, 175}, true);  // off the mesh, off the screen rectangle: the drag goes on, the value goes to an end
    const float far = r.ia("slider").value;
    CHECK((far < 0.05f || far > 0.95f));
    r.mouse({315, 175}, false);
    CHECK_FALSE(r.ia("slider").pressed);
    const float kept = r.ia("slider").value;
    r.mouse(r.screen(50, 80), false);
    CHECK(r.ia("slider").value == kept);  // released: moving does not drag
}

}  // namespace

TEST_CASE("render target pointer: a flat quad gives hover, click and slider drag by its UV") {
    Rig r("quad", "quad", "[2, 1, 1]");
    check_page(r, 0.03f);
}

TEST_CASE("render target pointer: a curved, stretched cylinder gives the same by its UV") {
    Rig r("cyl", "cylinder", "[1.6, 0.9, 1.6]");
    check_page(r, 0.06f);
    // The toggle at page pixel (150, 30) is on the far side of the cylinder (u = 0.75): the mouse over where that side projects hits
    // the near side, which shows another part of the page.
    r.mouse(r.screen(150, 30), false);
    CHECK_FALSE(r.ia("back").hovered);
}

TEST_CASE("render target pointer: a mesh that does not show a target leaves the main view's Interactables alone") {
    Rig r("plain", "quad", "[2, 1, 1]");
    r.e.commands().call("scene.set_component", Json{{"id", "screen"}, {"component", "MeshRenderer"}, {"fields", Json{{"texture", ""}}}});
    r.e.step(2);
    r.mouse(r.screen(60, 50), false);
    CHECK_FALSE(r.ia("toggle").hovered);
}

// ---------------------------------------------------------------------------------------------------- procedural meshes

namespace {

// A page of `cols` x `rows` quads (uv (0,0) at the top-left, as the engine's quad) in the XY plane: u goes along x over `width`
// from `x0`, v down over one unit, and z bends it: z = bend * (x / width)^2 * width. Positions are exact at the grid vertices.
Json page_mesh(int cols, int rows, float x0, float width, float bend) {
    Json positions = Json::array(), uvs = Json::array(), indices = Json::array();
    for (int j = 0; j <= rows; ++j)
        for (int i = 0; i <= cols; ++i) {
            const float u = float(i) / float(cols), v = float(j) / float(rows);
            const float x = x0 + (u - 0.5f) * width;
            for (float f : {x, 0.5f - v, bend * x * x}) positions.push_back(f);
            uvs.push_back(u);
            uvs.push_back(v);
        }
    for (int j = 0; j < rows; ++j)
        for (int i = 0; i < cols; ++i) {
            const int a = j * (cols + 1) + i, b = a + 1, c = a + cols + 1, d = c + 1;
            for (int k : {a, c, b, b, c, d}) indices.push_back(k);
        }
    return Json{{"positions", positions}, {"uvs", uvs}, {"indices", indices}};
}

// Rig whose "screen" entity shows a procedural mesh instead of a built-in one.
struct ProceduralRig : Rig {
    int cols, rows;
    float x0 = 0.0f, width = 2.0f, bend = 0.0f;
    std::string meshId;

    ProceduralRig(const char* name, int c, int r) : Rig(name, "quad", "[1, 1, 1]"), cols(c), rows(r) {
        auto made = e.commands().call("mesh.create", page_mesh(cols, rows, x0, width, bend));
        REQUIRE_MESSAGE(made.ok, made.error);
        meshId = made.result["id"].get<std::string>();
        e.world().get<MeshRenderer>(id("screen"))->mesh = meshId;
        e.step(2);
    }
    void reshape(float newX0, float newBend) {
        x0 = newX0;
        bend = newBend;
        Json args = page_mesh(cols, rows, x0, width, bend);
        args["id"] = meshId;
        auto r = e.commands().call("mesh.update", args);
        REQUIRE_MESSAGE(r.ok, r.error);
        e.step(1);
    }
    // The screen point where the page shows page pixel (px, py), on the mesh as it is NOW.
    Vec2 at(float px, float py) {
        const float u = px / 200.0f, v = py / 100.0f;
        const float x = x0 + (u - 0.5f) * width;
        return e.renderer()->world_to_screen(e.world().world_matrix(id("screen")).transform_point({x, 0.5f - v, bend * x * x}));
    }
};

}  // namespace

TEST_CASE("render target pointer: a procedural quad gives hover, click and slider drag by its UV") {
    ProceduralRig r("proc_quad", 1, 1);
    r.mouse(r.at(60, 50), false);
    CHECK(r.ia("toggle").hovered);
    r.mouse(r.at(60, 68), false);
    CHECK_FALSE(r.ia("toggle").hovered);
    r.tap(r.at(60, 50));
    CHECK(r.ia("toggle").on);
    r.tap(r.at(100, 5));
    CHECK(r.ia("toggle").on);
    r.mouse(r.at(35, 80), true);
    CHECK(r.ia("slider").pressed);
    CHECK(r.ia("slider").value == doctest::Approx(0.25f).epsilon(0.03f));
    r.mouse(r.at(65, 80), true);
    CHECK(r.ia("slider").value == doctest::Approx(0.75f).epsilon(0.03f));
    r.mouse({315, 175}, true);  // off the mesh: the drag goes on along the plane of the last triangle
    const float far = r.ia("slider").value;
    CHECK((far < 0.05f || far > 0.95f));
    r.mouse({315, 175}, false);
    CHECK_FALSE(r.ia("slider").pressed);
}

TEST_CASE("render target pointer: a procedural page that is bent and moved by mesh.update is hit where it is now") {
    ProceduralRig r("proc_bend", 40, 10);
    // A bent page: the corners come towards the camera.
    r.reshape(0.0f, 0.4f);
    r.tap(r.at(60, 50));
    CHECK(r.ia("toggle").on);
    r.mouse(r.at(50, 80), false);
    CHECK(r.ia("slider").hovered);

    // The surface is cached per version: asking again without an update gives the very same object.
    World& w = r.e.world();
    auto first = w.meshes().surface(r.meshId);
    REQUIRE(first);
    CHECK(w.meshes().surface(r.meshId) == first);
    r.mouse(r.at(60, 50), false);
    CHECK(w.meshes().surface(r.meshId) == first);  // frames of pointer work did not rebuild it

    // The page moves 0.4 to the right and bends the other way: the old place of the toggle now shows another part of the picture, the
    // toggle is where the new shape draws it.
    const Vec2 oldPlace = r.at(60, 50);
    r.reshape(0.4f, -0.3f);
    CHECK(w.meshes().surface(r.meshId) != first);
    r.mouse(oldPlace, false);
    CHECK_FALSE(r.ia("toggle").hovered);
    r.mouse(r.at(60, 50), false);
    CHECK(r.ia("toggle").hovered);
    r.tap(r.at(60, 50));
    CHECK_FALSE(r.ia("toggle").on);  // it was on: the click flipped it back
    r.tap(oldPlace);
    CHECK_FALSE(r.ia("toggle").on);  // the old place is not the toggle any more
    r.tap(r.at(60, 50));
    CHECK(r.ia("toggle").on);

    // A drag that started on the page before an update goes on after it.
    r.mouse(r.at(35, 80), true);
    CHECK(r.ia("slider").value == doctest::Approx(0.25f).epsilon(0.05f));
    r.reshape(0.2f, 0.2f);
    r.mouse(r.at(65, 80), true);
    CHECK(r.ia("slider").pressed);
    CHECK(r.ia("slider").value == doctest::Approx(0.75f).epsilon(0.05f));
    r.mouse(r.at(65, 80), false);
    CHECK_FALSE(r.ia("slider").pressed);
}

TEST_CASE("render target pointer: a procedural mesh shows the target through a submesh material, and a destroyed mesh is reported") {
    ProceduralRig r("proc_sub", 1, 1);
    // Move the target from MeshRenderer.texture to the submesh material: the pointer follows.
    Json args = page_mesh(1, 1, 0.0f, 2.0f, 0.0f);
    args["id"] = r.meshId;
    args["submeshes"] = Json::array({Json{{"material", Json{{"name", "page"}, {"texture", "target:page"}}}}});
    REQUIRE(r.e.commands().call("mesh.update", args).ok);
    r.e.commands().call("scene.set_component", Json{{"id", "screen"}, {"component", "MeshRenderer"}, {"fields", Json{{"texture", ""}}}});
    r.e.step(2);
    r.mouse(r.at(60, 50), false);
    CHECK(r.ia("toggle").hovered);
    r.mouse(r.at(150, 30), false);
    CHECK(r.ia("back").hovered);
    // Triangles outside every submesh are not drawn, so they do not answer the pointer: keep only the upper-left triangle (0, 2, 1) of
    // the quad. Page pixel (60, 50) is in it (u + v < 1), (150, 30) is in the other one (u + v > 1).
    args = Json::object({{"id", r.meshId}, {"indices", Json::array({0, 2, 1})},
                         {"submeshes", Json::array({Json{{"material", Json{{"name", "page"}, {"texture", "target:page"}}}}})}});
    REQUIRE(r.e.commands().call("mesh.update", args).ok);
    r.e.step(1);
    r.mouse(r.at(60, 50), false);
    CHECK(r.ia("toggle").hovered);
    r.mouse(r.at(150, 30), false);
    CHECK_FALSE(r.ia("back").hovered);
    REQUIRE(r.e.commands().call("mesh.destroy", Json{{"id", r.meshId}}).ok);
    r.e.step(2);
    r.mouse(r.at(60, 50), false);  // the mesh is gone: nothing is reached, and nothing crashes
    CHECK_FALSE(r.ia("toggle").hovered);
}
