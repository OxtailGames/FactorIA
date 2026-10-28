// CameraView: a UI widget that draws a named camera inside its rectangle (clipped, layered like any widget), the studio
// lighting of a Camera and Camera.viewportSpace.
#include "test_util.h"

#include <cmath>
#include <string>

using namespace fa;
using namespace fa::test;

namespace {

const Color kClear{0.1f, 0.1f, 0.1f, 1};   // what the game camera clears to
const Color kStage{0.1f, 0.2f, 0.6f, 1};   // what the view camera clears to

bool near(const Color& a, const Color& b, float tol = 0.03f) {
    return std::fabs(a.r - b.r) <= tol && std::fabs(a.g - b.g) <= tol && std::fabs(a.b - b.b) <= tol;
}

// How many pixels of the rectangle differ between two images.
int differing(const Image& a, const Image& b, int x0, int y0, int x1, int y1) {
    int n = 0;
    for (int y = y0; y < y1; ++y)
        for (int x = x0; x < x1; ++x)
            if (!near(a.pixel(x, y), b.pixel(x, y), 2.0f / 255.0f)) ++n;
    return n;
}

void game_camera(World& w) {
    auto& c = w.add<Camera>(make(w, "game"));
    c.clearColor = kClear;
}

// A perspective camera, not drawn by itself (primary = false), at `stage` looking down -Z. Studio lighting by default
// (it keeps the scene's sky out of the picture, so the clear colour shows).
Entity view_camera(World& w, const char* name, Vec3 stage, Camera** out = nullptr) {
    Entity e = make(w, name, stage + Vec3{0, 0, 4});
    auto& c = w.add<Camera>(e);
    c.projection = Projection::Perspective;
    c.fov = 50;
    c.primary = false;
    c.clearColor = kStage;
    c.lighting = CameraLighting::Studio;
    if (out) *out = &c;
    return e;
}

Entity cube_at(World& w, Vec3 pos, Color color, float yaw = 0.0f) {
    Entity e = make(w, "cube", pos);
    w.get<Transform>(e)->rotation = {0, yaw, 0};
    auto& m = w.add<MeshRenderer>(e);
    m.mesh = "cube";
    m.color = color;
    return e;
}

CameraView& view_widget(World& w, const char* name, const char* camera, float x, float y, float width, float height) {
    Entity e = make(w, name, {x, y, 0});
    CameraView& v = w.add<CameraView>(e);
    v.camera = camera;
    v.size = {width, height};
    v.pivot = {0, 1};
    return v;
}

}  // namespace

TEST_CASE("camera view: draws its camera inside the rectangle, and only there") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    World w;
    game_camera(w);
    view_camera(w, "stage", {500, 0, 0});
    cube_at(w, {500, 0, 0}, Color::hex(0xe04040));
    view_widget(w, "view", "stage", 40, 30, 120, 100);
    Image img = g.render(w);
    CHECK(g.renderer.stats().views == 1);
    CHECK(near(img.pixel(100, 80), Color::hex(0xe04040), 0.5f));       // the cube, lit
    CHECK(img.pixel(100, 80).r > img.pixel(100, 80).b * 2.0f);
    CHECK(near(img.pixel(45, 35), kStage));                             // the view camera's own clear colour
    CHECK(near(img.pixel(155, 125), kStage));
    CHECK(near(img.pixel(20, 80), kClear));                             // outside the rectangle: the game
    CHECK(near(img.pixel(200, 80), kClear));
    CHECK(near(img.pixel(100, 15), kClear));
    CHECK(near(img.pixel(100, 145), kClear));
    // The 3D scene is not drawn by the game camera too.
    CHECK(near(img.pixel(160, 90), kClear));
}

TEST_CASE("camera view: a missing, inactive or empty camera draws only the background") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    World w;
    game_camera(w);
    view_widget(w, "none", "", 10, 10, 60, 60).color = Color{0.8f, 0.1f, 0.1f, 1};
    view_widget(w, "missing", "nobody", 90, 10, 60, 60).color = Color{0.1f, 0.8f, 0.1f, 1};
    Entity off = view_camera(w, "off", {500, 0, 0});
    cube_at(w, {500, 0, 0}, Color::hex(0xe04040));
    w.set_active(off, false);
    view_widget(w, "inactive", "off", 170, 10, 60, 60).color = Color{0.1f, 0.1f, 0.8f, 1};
    view_widget(w, "clear", "nobody", 250, 10, 60, 60);  // no background at all: nothing
    Image img = g.render(w);
    CHECK(g.renderer.stats().views == 0);
    CHECK(near(img.pixel(40, 40), Color{0.8f, 0.1f, 0.1f, 1}));
    CHECK(near(img.pixel(120, 40), Color{0.1f, 0.8f, 0.1f, 1}));
    CHECK(near(img.pixel(200, 40), Color{0.1f, 0.1f, 0.8f, 1}));
    CHECK(near(img.pixel(280, 40), kClear));
}

TEST_CASE("camera view: what the mesh does shows in the widget (a turning mesh), the rest of the frame stays put") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    World w;
    game_camera(w);
    view_camera(w, "stage", {500, 0, 0});
    Entity cube = cube_at(w, {500, 0, 0}, Color::hex(0xe0b040));
    w.get<Transform>(cube)->scale = {1.6f, 1, 1};   // not a cube: turning it changes the outline
    view_widget(w, "view", "stage", 40, 30, 120, 100);
    const Image a = g.render(w);
    w.get<Transform>(cube)->rotation = {0, 50, 0};
    const Image b = g.render(w);
    CHECK(differing(a, b, 40, 30, 160, 130) > 300);
    CHECK(differing(a, b, 0, 0, 320, 30) == 0);
    CHECK(differing(a, b, 0, 130, 320, 180) == 0);
    CHECK(differing(a, b, 160, 0, 320, 180) == 0);
}

TEST_CASE("camera view: a ScrollList clips it, a Panel above it covers it, two views of one camera each get a picture") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    World w;
    game_camera(w);
    view_camera(w, "stage", {500, 0, 0});
    cube_at(w, {500, 0, 0}, Color::hex(0xe04040));

    // A list 100 px wide and 60 px tall; its child view is 100 x 120, so the lower half is cut at y = 80.
    Entity listE = make(w, "list", {10, 20, 0});
    auto& list = w.add<ScrollList>(listE);
    list.size = {100, 60};
    list.pivot = {0, 1};
    list.padding = {0, 0, 0, 0};
    view_widget(w, "inlist", "stage", 10, 20, 100, 120);
    w.set_parent(w.find("inlist"), listE, true);

    // A modal Panel over the right half of the second view.
    view_widget(w, "second", "stage", 150, 20, 160, 120);
    Entity panelE = make(w, "dialog", {230, 20, 0});
    auto& panel = w.add<Panel>(panelE);
    panel.size = {80, 120};
    panel.pivot = {0, 1};
    panel.color = Color{0.9f, 0.9f, 0.1f, 1};
    panel.modal = true;
    panel.layer = 300;

    Image img = g.render(w);
    CHECK(g.renderer.stats().views == 2);
    CHECK(near(img.pixel(15, 25), kStage));             // inside the list: the view's background
    CHECK(near(img.pixel(15, 75), kStage));
    CHECK(near(img.pixel(15, 90), kClear));             // below the list's bottom edge: clipped away
    CHECK(near(img.pixel(15, 135), kClear));
    CHECK(near(img.pixel(155, 25), kStage));            // second view, left of the dialog
    CHECK(near(img.pixel(235, 25), Color{0.9f, 0.9f, 0.1f, 1}));  // the dialog covers it
    CHECK(near(img.pixel(300, 130), Color{0.9f, 0.9f, 0.1f, 1}));
    // Both pictures show the cube (the first through the clip, the second to the left of the dialog).
    CHECK(img.pixel(60, 72).r > 0.4f);
    CHECK(img.pixel(222, 80).r > 0.4f);
}

TEST_CASE("camera view: studio lighting ignores the scene's lights and ambient; the scene's lighting does not") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    World w;
    game_camera(w);
    Camera* studioCam = nullptr;
    Camera* sceneCam = nullptr;
    view_camera(w, "studio", {500, 0, 0}, &studioCam);
    view_camera(w, "studio2", {900, 0, 0});
    view_camera(w, "plain", {700, 0, 0}, &sceneCam);
    sceneCam->lighting = CameraLighting::Scene;
    for (float x : {500.0f, 900.0f, 700.0f}) cube_at(w, {x, 0, 0}, Color::hex(0x9a7040));
    // A bright scene: a strong sun and a lit ambient.
    Entity sun = make(w, "sun", {0, 10, 0});
    w.get<Transform>(sun)->rotation = {-60, 30, 0};
    auto& light = w.add<Light>(sun);
    light.type = LightType::Directional;
    light.intensity = 6.0f;
    view_widget(w, "a", "studio", 10, 20, 90, 90);
    view_widget(w, "b", "studio2", 115, 20, 90, 90);
    view_widget(w, "c", "plain", 220, 20, 90, 90);
    const Image bright = g.render(w);
    light.intensity = 0.0f;
    const Image dark = g.render(w);
    // The studio views look the same with the sun at 6 and at 0 ...
    CHECK(differing(bright, dark, 10, 20, 100, 110) == 0);
    CHECK(differing(bright, dark, 115, 20, 205, 110) == 0);
    // ... and the same wherever the item stands.
    CHECK(near(bright.pixel(55, 65), bright.pixel(160, 65), 0.01f));
    // The studio picture is lit (not black, not blown out), the scene-lit one follows the sun.
    const Color s = bright.pixel(55, 65);
    CHECK(s.r > 0.15f);
    CHECK(s.r < 0.95f);
    CHECK(s.r > s.b);
    CHECK(differing(bright, dark, 220, 20, 310, 110) > 500);
}

TEST_CASE("camera view: studioIntensity scales the studio rig") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    World w;
    game_camera(w);
    Camera* cam = nullptr;
    view_camera(w, "stage", {500, 0, 0}, &cam);
    cube_at(w, {500, 0, 0}, Color::hex(0x808080));
    view_widget(w, "view", "stage", 40, 30, 120, 100);
    cam->studioIntensity = 0.5f;
    const float dim = g.render(w).pixel(100, 80).r;
    cam->studioIntensity = 1.0f;
    const float full = g.render(w).pixel(100, 80).r;
    CHECK(full > dim + 0.05f);
}

TEST_CASE("camera: viewportSpace design counts the fractions on the design area, screen on the whole (grown) target") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    World w;
    Entity e = make(w, "cam");
    auto& cam = w.add<Camera>(e);
    cam.clearColor = kClear;
    cam.viewport = {0, 0, 0.5f, 1};
    Entity sq = make(w, "square", {0, 0, 0});
    auto& shape = w.add<Shape2D>(sq);
    shape.shape = ShapeType::Rectangle;
    shape.size = {40, 40};
    shape.color = Color{1, 0, 0, 1};

    g.renderer.set_target_size(640, 180);  // what Expand does on a wider window: the design area is 320 x 180 from the left
    cam.viewportSpace = ViewportSpace::Screen;
    Image screen = g.render(w);
    cam.viewportSpace = ViewportSpace::Design;
    Image design = g.render(w);
    g.renderer.set_target_size(320, 180);

    REQUIRE(screen.width == 640);
    CHECK(near(screen.pixel(160, 90), Color{1, 0, 0, 1}));   // the left half of 640 px: centre at x = 160
    CHECK(near(design.pixel(80, 90), Color{1, 0, 0, 1}));    // the left half of the 320 px design area: centre at x = 80
    CHECK(near(design.pixel(160, 90), kClear));
}
