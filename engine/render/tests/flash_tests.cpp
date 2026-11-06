// Game feel flash (fa/scene/feel.h): an entity drawn in one colour. Pixel checks of a sprite, a Shape2D and a 3D mesh flashed at
// full strength, a half strength mix, and that the entity's own colour is never written.
#include "test_util.h"

#include <cmath>

#include "fa/scene/feel.h"

using namespace fa;
using namespace fa::test;

namespace {

constexpr float kTol = 0.04f;  // 4 % of a channel: filtering and 8-bit quantisation

Entity camera2d(World& w) {
    Entity cam = make(w, "cam");
    w.add<Camera>(cam).clearColor = Color::black();
    return cam;
}

Entity sprite(World& w, Vec3 p, Color color) {
    Entity e = make(w, "sprite", p);
    auto& s = w.add<Sprite>(e);
    s.size = {60, 40};
    s.color = color;
    return e;
}

Entity shape(World& w, Vec3 p, ShapeType type, Color color) {
    Entity e = make(w, "shape", p);
    auto& s = w.add<Shape2D>(e);
    s.shape = type;
    s.size = {60, 40};
    s.color = color;
    return e;
}

void flash_now(World& w, Entity e, Color c, float strength, bool fade = false) {
    REQUIRE(feel_flash(w, e, {c, 1.0f, fade, strength}).ok());  // not advanced by a frame: the whole strength shows
}

void near(const Color& got, float r, float g, float b, float tol = kTol) {
    CHECK(std::fabs(got.r - r) <= tol);
    CHECK(std::fabs(got.g - g) <= tol);
    CHECK(std::fabs(got.b - b) <= tol);
}

}  // namespace

TEST_CASE("flash: a Sprite at strength 1 is the flash colour, at 0.5 half way, and its own colour is untouched") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    World w;
    camera2d(w);
    const Color own{0.1f, 0.4f, 0.9f, 1.0f};
    Entity s = sprite(w, {0, 0, 0}, own);
    near(g.render(w).pixel(160, 90), 0.1f, 0.4f, 0.9f);  // not flashing
    flash_now(w, s, Color{1, 0, 0, 1}, 1.0f);
    near(g.render(w).pixel(160, 90), 1.0f, 0.0f, 0.0f);
    flash_now(w, s, Color{1, 0, 0, 1}, 0.5f);
    near(g.render(w).pixel(160, 90), 0.55f, 0.2f, 0.45f);
    CHECK(w.get<Sprite>(s)->color.r == 0.1f);  // the component never changed
    CHECK(w.get<Sprite>(s)->color.b == 0.9f);
    feel_cancel(w, s);
    near(g.render(w).pixel(160, 90), 0.1f, 0.4f, 0.9f);  // and the flash is over
}

TEST_CASE("flash: a child is flashed with its parent, and an unrelated sprite is not") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    World w;
    camera2d(w);
    Entity parent = make(w, "parent", {-60, 0, 0});
    Entity child = sprite(w, {0, 0, 0}, Color{0.1f, 0.4f, 0.9f, 1.0f});
    w.set_parent(child, parent);
    sprite(w, {60, 0, 0}, Color{0.1f, 0.4f, 0.9f, 1.0f});
    flash_now(w, parent, Color{1, 1, 1, 1}, 1.0f);
    const Image img = g.render(w);
    near(img.pixel(100, 90), 1.0f, 1.0f, 1.0f);  // the child, at x = -60
    near(img.pixel(220, 90), 0.1f, 0.4f, 0.9f);  // the other one
}

TEST_CASE("flash: a Shape2D (rectangle, circle and diamond) at strength 1 and 0.5") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    for (ShapeType type : {ShapeType::Rectangle, ShapeType::Circle, ShapeType::Diamond}) {
        World w;
        camera2d(w);
        Entity s = shape(w, {0, 0, 0}, type, Color{0.1f, 0.4f, 0.9f, 1.0f});
        near(g.render(w).pixel(160, 90), 0.1f, 0.4f, 0.9f);
        flash_now(w, s, Color{1, 0.5f, 0, 1}, 1.0f);
        near(g.render(w).pixel(160, 90), 1.0f, 0.5f, 0.0f);
        flash_now(w, s, Color{1, 0.5f, 0, 1}, 0.5f);
        near(g.render(w).pixel(160, 90), 0.55f, 0.45f, 0.45f);
        CHECK(w.get<Shape2D>(s)->color.g == 0.4f);
    }
}

TEST_CASE("flash: a lit 3D mesh at strength 1 is the flash colour, in the light and in the dark") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    World w;
    Entity cam = make(w, "cam", {0, 0, 5});
    auto& c = w.add<Camera>(cam);
    c.projection = Projection::Perspective;
    c.fov = 60;
    w.settings().ambientLight = Color{0.2f, 0.2f, 0.2f, 1};
    Entity cube = make(w, "cube", {0, 0, 0});
    auto& m = w.add<MeshRenderer>(cube);
    m.mesh = "cube";
    m.color = Color{0.1f, 0.4f, 0.9f, 1.0f};
    Entity sun = make(w, "sun");
    w.get<Transform>(sun)->rotation = {-30, 20, 0};
    w.add<Light>(sun).type = LightType::Directional;

    const Color plain = g.render(w).pixel(160, 90);
    CHECK(plain.b > plain.r + 0.1f);  // a blue cube
    flash_now(w, cube, Color{1, 0.2f, 0.2f, 1}, 1.0f);
    const Color flashed = g.render(w).pixel(160, 90);
    CHECK(flashed.r > 0.9f);                 // the flash colour ...
    CHECK(flashed.g == doctest::Approx(0.2f).epsilon(0.25));
    CHECK(flashed.b < 0.4f);                 // ... not the blue of the cube
    // No light at all: emission carries it, the silhouette is still the flash colour.
    w.destroy(sun);
    w.flush();
    w.settings().ambientLight = Color{0, 0, 0, 1};
    const Color dark = g.render(w).pixel(160, 90);
    CHECK(dark.r > 0.9f);
    CHECK(dark.b < 0.4f);
    // Half way is between the two.
    flash_now(w, cube, Color{1, 0.2f, 0.2f, 1}, 0.5f);
    const Color half = g.render(w).pixel(160, 90);
    CHECK(half.r > 0.3f);
    CHECK(half.r < dark.r);
    CHECK(w.get<MeshRenderer>(cube)->color.b == 0.9f);  // the material colour never changed
}
