// Camera.viewport: split screen. Every active camera draws into its own rectangle of the target.
#include "test_util.h"

#include <cmath>

using namespace fa;
using namespace fa::test;

namespace {

// Target of the shared fixture: 320x180 design pixels, one world unit per design pixel for a camera with orthoSize 0.

bool near_color(Color a, Color b, float tol = 4.0f / 255.0f) {
    return std::fabs(a.r - b.r) <= tol && std::fabs(a.g - b.g) <= tol && std::fabs(a.b - b.b) <= tol;
}

Entity camera(World& w, const char* name, Vec3 pos, Rect viewport, Color clear, int depth = 0) {
    Entity e = make(w, name, pos);
    auto& c = w.add<Camera>(e);
    c.viewport = viewport;
    c.clearColor = clear;
    c.depth = depth;
    return e;
}

Entity square(World& w, Vec3 pos, Color color, float size = 40.0f) {
    Entity e = make(w, "square", pos);
    auto& s = w.add<Shape2D>(e);
    s.shape = ShapeType::Rectangle;
    s.size = {size, size};
    s.color = color;
    return e;
}

const Color kRed{1, 0, 0, 1}, kGreen{0, 1, 0, 1}, kBlue{0, 0, 1, 1}, kYellow{1, 1, 0, 1};
const Color kGrey{0.2f, 0.2f, 0.2f, 1}, kDark{0.05f, 0.05f, 0.3f, 1}, kTeal{0.0f, 0.3f, 0.3f, 1};

}  // namespace

TEST_CASE("split screen: two cameras draw their own half, each with its own clear colour and culling") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    World w;
    camera(w, "left", {0, 0, 0}, {0, 0, 0.5f, 1}, kGrey, 0);
    camera(w, "right", {500, 0, 0}, {0.5f, 0, 0.5f, 1}, kDark, 1);
    square(w, {0, 0, 0}, kRed);       // seen by the left camera only
    square(w, {500, 0, 0}, kBlue);    // seen by the right camera only
    Image img = g.render(w);
    CHECK(near_color(img.pixel(80, 90), kRed));      // centre of the left half
    CHECK(near_color(img.pixel(240, 90), kBlue));    // centre of the right half
    CHECK(near_color(img.pixel(10, 10), kGrey));
    CHECK(near_color(img.pixel(150, 170), kGrey));
    CHECK(near_color(img.pixel(170, 10), kDark));
    CHECK(near_color(img.pixel(310, 170), kDark));
    // Nothing of one view leaks into the other half.
    CHECK(near_color(img.pixel(130, 90), kGrey));
    CHECK(near_color(img.pixel(190, 90), kDark));
    // The halves meet without a gap at the seam.
    CHECK(near_color(img.pixel(159, 5), kGrey));
    CHECK(near_color(img.pixel(160, 5), kDark));
}

TEST_CASE("split screen: the viewport sets the aspect, so a half keeps the world scale") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    World w;
    camera(w, "left", {0, 0, 0}, {0, 0, 0.5f, 1}, kGrey, 0);
    // A 100x100 square at the origin is 100 pixels wide in the left half (one world unit per design pixel), not stretched.
    square(w, {0, 0, 0}, kRed, 100.0f);
    Image img = g.render(w);
    CHECK(near_color(img.pixel(80, 90), kRed));
    CHECK(near_color(img.pixel(80 - 48, 90), kRed));
    CHECK(near_color(img.pixel(80 - 52, 90), kGrey));
    CHECK(near_color(img.pixel(80, 90 - 48), kRed));
    CHECK(near_color(img.pixel(80, 90 - 52), kGrey));
}

TEST_CASE("split screen: four cameras draw the four quarters") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    World w;
    const Color clears[4] = {{0.1f, 0, 0, 1}, {0, 0.1f, 0, 1}, {0, 0, 0.1f, 1}, {0.1f, 0.1f, 0, 1}};
    const Color shapes[4] = {kRed, kGreen, kBlue, kYellow};
    for (int i = 0; i < 4; ++i) {
        const float x = float(i % 2) * 0.5f, y = float(i / 2) * 0.5f;
        camera(w, "cam", {1000.0f * float(i), 0, 0}, {x, y, 0.5f, 0.5f}, clears[i], i);
        square(w, {1000.0f * float(i), 0, 0}, shapes[i], 30.0f);
    }
    Image img = g.render(w);
    for (int i = 0; i < 4; ++i) {
        const int cx = (i % 2) * 160 + 80, cy = (i / 2) * 90 + 45;
        INFO("quarter " << i);
        CHECK(near_color(img.pixel(cx, cy), shapes[i]));
        CHECK(near_color(img.pixel(cx - 70, cy - 35), clears[i]));
        CHECK(near_color(img.pixel(cx + 70, cy + 35), clears[i]));
    }
}

TEST_CASE("split screen: clear is per camera") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    World w;
    camera(w, "back", {0, 0, 0}, {0, 0, 1, 1}, kGrey, 0);
    Entity inset = camera(w, "inset", {500, 0, 0}, {0.5f, 0.5f, 0.5f, 0.5f}, kTeal, 1);
    square(w, {0, 0, 0}, kRed, 60.0f);
    square(w, {500, 0, 0}, kBlue, 20.0f);
    Image img = g.render(w);
    CHECK(near_color(img.pixel(145, 75), kRed));      // the full-screen camera (its red square is cut by the inset)
    CHECK(near_color(img.pixel(240, 135), kBlue));    // the inset: centre of the bottom right quarter
    CHECK(near_color(img.pixel(300, 170), kTeal));    // the inset cleared its own rectangle
    CHECK(near_color(img.pixel(300, 10), kGrey));     // outside the inset the first camera shows
    // Without a clear the inset draws over the first camera's picture instead.
    w.get<Camera>(inset)->clear = false;
    img = g.render(w);
    CHECK(near_color(img.pixel(240, 135), kBlue));
    CHECK(near_color(img.pixel(300, 170), kGrey));
}

TEST_CASE("split screen: the screen-space items are drawn once over the whole screen after the cameras") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    World w;
    camera(w, "left", {0, 0, 0}, {0, 0, 0.5f, 1}, kGrey, 0);
    camera(w, "right", {500, 0, 0}, {0.5f, 0, 0.5f, 1}, kDark, 1);
    Entity hud = make(w, "hud", {160, 90, 0});  // the centre of the screen, on the seam between the two views
    auto& s = w.add<Shape2D>(hud);
    s.shape = ShapeType::Rectangle;
    s.size = {40, 20};
    s.color = kYellow;
    s.space = RenderSpace::Screen;
    Image img = g.render(w);
    CHECK(near_color(img.pixel(150, 90), kYellow));
    CHECK(near_color(img.pixel(170, 90), kYellow));
    CHECK(near_color(img.pixel(135, 90), kGrey));
    CHECK(near_color(img.pixel(185, 90), kDark));
}

TEST_CASE("split screen: the 2D lights of a camera light its own rectangle only") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    World w;
    w.settings().ambientLight = Color{0, 0, 0, 1};
    camera(w, "left", {0, 0, 0}, {0, 0, 0.5f, 1}, kGrey, 0);
    camera(w, "right", {500, 0, 0}, {0.5f, 0, 0.5f, 1}, kGrey, 1);
    for (float x : {0.0f, 500.0f}) {
        Entity e = square(w, {x, 0, 0}, Color::white(), 100.0f);
        w.get<Shape2D>(e)->lit = true;
    }
    Entity lamp = make(w, "lamp", {0, 0, 0});  // lights the left square only: the right one is 500 units away
    auto& l = w.add<Light2D>(lamp);
    l.radius = 120;
    l.falloff = 1;
    Image img = g.render(w);
    CHECK(img.pixel(80, 90).r > 0.9f);
    CHECK(img.pixel(240, 90).r < 0.05f);
    // The other way round: move the lamp and the lit side follows it.
    w.get<Transform>(lamp)->position = {500, 0, 0};
    img = g.render(w);
    CHECK(img.pixel(80, 90).r < 0.05f);
    CHECK(img.pixel(240, 90).r > 0.9f);
}

TEST_CASE("split screen: conversions use the camera under the point, or the camera you name") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    World w;
    Entity left = camera(w, "left", {0, 0, 0}, {0, 0, 0.5f, 1}, kGrey, 0);
    Entity right = camera(w, "right", {500, 0, 0}, {0.5f, 0, 0.5f, 1}, kDark, 1);
    (void)g.render(w);
    Renderer& r = g.renderer;
    // The centre of each half is the centre of that camera.
    Vec3 a = r.screen_to_world({80, 90});
    Vec3 b = r.screen_to_world({240, 90});
    CHECK(a.x == doctest::Approx(0.0f).epsilon(0.01));
    CHECK(a.y == doctest::Approx(0.0f).epsilon(0.01));
    CHECK(b.x == doctest::Approx(500.0f).epsilon(0.01));
    CHECK(b.y == doctest::Approx(0.0f).epsilon(0.01));
    // One world unit per design pixel: 30 pixels right and 20 pixels up of the centre of the right half.
    Vec3 c = r.screen_to_world({270, 70});
    CHECK(c.x == doctest::Approx(530.0f).epsilon(0.01));
    CHECK(c.y == doctest::Approx(20.0f).epsilon(0.01));
    // Naming a camera uses it whatever the point: the centre of the right half seen through the left camera.
    Vec3 d = r.screen_to_world({240, 90}, 0.0f, left);
    CHECK(d.x == doctest::Approx(160.0f).epsilon(0.01));
    // And back: world_to_screen projects with the camera named (the first one by default).
    Vec2 s1 = r.world_to_screen({530, 20, 0}, right);
    CHECK(s1.x == doctest::Approx(270.0f).epsilon(0.01));
    CHECK(s1.y == doctest::Approx(70.0f).epsilon(0.01));
    Vec2 s2 = r.world_to_screen({30, 20, 0});
    CHECK(s2.x == doctest::Approx(110.0f).epsilon(0.01));
    CHECK(s2.y == doctest::Approx(70.0f).epsilon(0.01));
    // Picking: the camera under the mouse.
    CHECK(r.camera_at({10, 10}) == left);
    CHECK(r.camera_at({300, 100}) == right);
    CHECK(r.camera_at({159, 100}) == left);
    CHECK(r.camera_at({160, 100}) == right);
    const std::vector<Entity> cams = r.cameras();
    REQUIRE(cams.size() == 2);
    CHECK(cams[0] == left);
    CHECK(cams[1] == right);
    // The ray of a point of the right half starts in the right camera's view.
    Vec3 o, dir;
    r.screen_ray({240, 90}, o, dir);
    CHECK(o.x == doctest::Approx(500.0f).epsilon(0.01));
}

TEST_CASE("split screen: overlapping viewports pick the camera drawn last (highest depth)") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    World w;
    Entity back = camera(w, "back", {0, 0, 0}, {0, 0, 1, 1}, kGrey, 0);
    Entity inset = camera(w, "inset", {500, 0, 0}, {0.5f, 0.5f, 0.5f, 0.5f}, kTeal, 3);
    (void)g.render(w);
    CHECK(g.renderer.camera_at({20, 20}) == back);
    CHECK(g.renderer.camera_at({300, 170}) == inset);
    // A point outside every viewport falls to the first camera.
    CHECK(g.renderer.camera_at({-5, -5}) == back);
}

TEST_CASE("split screen: a single camera with a full viewport is one pass and one clear, as before") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    World w;
    camera(w, "cam", {0, 0, 0}, {0, 0, 1, 1}, kGrey, 0);
    square(w, {0, 0, 0}, kRed);
    Image img = g.render(w);
    CHECK(near_color(img.pixel(160, 90), kRed));
    CHECK(near_color(img.pixel(5, 5), kGrey));
    CHECK(g.renderer.stats().drawCalls == 1);
}

TEST_CASE("split screen: render stats add up over the cameras of the frame") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    World w;
    camera(w, "left", {0, 0, 0}, {0, 0, 0.5f, 1}, kGrey, 0);
    camera(w, "right", {500, 0, 0}, {0.5f, 0, 0.5f, 1}, kDark, 1);
    square(w, {0, 0, 0}, kRed);
    square(w, {500, 0, 0}, kBlue);
    (void)g.render(w);
    // One draw call per camera for its quads, and one for the clear of the second camera's half.
    const int calls = g.renderer.stats().drawCalls;
    CHECK(calls >= 2);
    CHECK(calls <= 4);
    // The frame after has the same numbers: the stats are the last frame's, not a running total.
    (void)g.render(w);
    CHECK(g.renderer.stats().drawCalls == calls);
}

TEST_CASE("split screen: a viewport that does not fit is drawn with the nearest valid rectangle") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    World w;
    camera(w, "wide", {0, 0, 0}, {0.5f, 0, 2.0f, 1}, kGrey, 0);  // past the right edge: cut at the screen
    square(w, {0, 0, 0}, kRed);
    Image img = g.render(w);
    CHECK(near_color(img.pixel(240, 90), kRed));  // the centre of the right half, where the camera is
    CHECK(near_color(img.pixel(300, 170), kGrey));
}

TEST_CASE("split screen: perspective cameras each draw their own 3D view into their half") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    World w;
    w.settings().ambientLight = Color{1, 1, 1, 1};
    for (int i = 0; i < 2; ++i) {
        Entity cam = camera(w, "cam", {100.0f * float(i), 0, 5}, {0.5f * float(i), 0, 0.5f, 1}, kGrey, i);
        w.get<Camera>(cam)->projection = Projection::Perspective;
        Entity cube = make(w, "cube", {100.0f * float(i), 0, 0});
        auto& m = w.add<MeshRenderer>(cube);
        m.mesh = "cube";
        m.unlit = true;
        m.color = i == 0 ? kRed : kBlue;
    }
    Image img = g.render(w);
    CHECK(near_color(img.pixel(80, 90), kRed));     // the cube is centred in its half, the aspect of the half is kept
    CHECK(near_color(img.pixel(240, 90), kBlue));
    CHECK(img.pixel(80, 3).b > 0.5f);               // each half has its own sky
    CHECK(img.pixel(240, 3).b > 0.5f);
    CHECK(g.renderer.stats().meshes == 2);          // one cube per camera: the other one is far outside the view
}

TEST_CASE("split screen: bloom and the HUD work over the frame of several cameras") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    World w;
    Entity left = camera(w, "left", {0, 0, 0}, {0, 0, 0.5f, 1}, kGrey, 0);
    camera(w, "right", {500, 0, 0}, {0.5f, 0, 0.5f, 1}, kDark, 1);
    {
        auto& c = *w.get<Camera>(left);
        c.bloom = true;
        c.bloomThreshold = 0.5f;
        c.bloomIntensity = 1.0f;
        c.bloomRadius = 12.0f;
        c.bloomScreenSpace = false;
    }
    square(w, {0, 0, 0}, kYellow);
    square(w, {500, 0, 0}, kBlue);
    Entity hud = make(w, "hud", {160, 90, 0});
    auto& s = w.add<Shape2D>(hud);
    s.shape = ShapeType::Rectangle;
    s.size = {40, 20};
    s.color = kGreen;
    s.space = RenderSpace::Screen;
    Image img = g.render(w);
    CHECK(near_color(img.pixel(80, 90), kYellow, 0.15f));
    CHECK(near_color(img.pixel(240, 90), kBlue, 0.15f));
    CHECK(near_color(img.pixel(150, 90), kGreen));   // the HUD is drawn over the glow, whole
    CHECK(near_color(img.pixel(170, 90), kGreen));
    // The glow reaches around the yellow square of the left view
    CHECK(img.pixel(80 + 24, 90).r > kGrey.r + 0.02f);
}
