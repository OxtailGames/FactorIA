// Camera.showTags / hideTags: which entities a camera draws, on the screen and into a render target. These run on whatever
// backend the machine has (Metal, GL, D3D11).
#include "test_util.h"

#include <cmath>
#include <string>
#include <vector>

#include "fa/scene/camera_mask.h"

using namespace fa;
using namespace fa::test;

namespace {

const Color kPage{0.1f, 0.2f, 0.7f, 1};  // what the page camera clears to
const Color kBlack{0, 0, 0, 1};
const Color kRed = Color::hex(0xe02020);
const Color kGreen = Color::hex(0x20c040);

bool near(const Color& a, const Color& b, float tol = 0.06f) {
    return std::fabs(a.r - b.r) <= tol && std::fabs(a.g - b.g) <= tol && std::fabs(a.b - b.b) <= tol;
}

Camera& game_camera(World& w) {
    Entity e = make(w, "game");
    Camera& c = w.add<Camera>(e);
    c.clearColor = kBlack;
    return c;
}

Camera& target_camera(World& w, const char* name, Vec3 at, int width, int height) {
    Entity e = make(w, (std::string("cam-") + name).c_str(), at);
    Camera& c = w.add<Camera>(e);
    c.renderTarget = name;
    c.renderTargetSize = Vec2{float(width), float(height)};
    c.orthoSize = float(height) / 2;
    c.clearColor = kPage;
    return c;
}

Entity shape(World& w, const char* name, Vec3 pos, Vec2 size, Color color, std::vector<std::string> tags = {}) {
    Entity e = make(w, name, pos);
    auto& s = w.add<Shape2D>(e);
    s.size = size;
    s.color = color;
    w.info(e).tags = std::move(tags);
    return e;
}

Entity sprite_showing(World& w, const char* name, Vec3 pos, Vec2 size, const std::string& texture) {
    Entity e = make(w, name, pos);
    auto& s = w.add<Sprite>(e);
    s.texture = texture;
    s.size = size;
    s.pixelArt = true;
    return e;
}

}  // namespace

TEST_CASE("camera tags: a render-target camera with showTags draws only the entities that have the tag") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    World w;
    game_camera(w);
    Camera& page = target_camera(w, "page", {1000, 0, 0}, 64, 32);
    page.showTags = Json::array({"page"});
    shape(w, "red", {1000 - 22, 11, 0}, {20, 10}, kRed, {"page"});      // top-left of the page, tagged
    shape(w, "green", {1000 + 22, -11, 0}, {20, 10}, kGreen);           // bottom-right, no tag: not drawn into the page
    sprite_showing(w, "screen", {0, 0, 0}, {128, 64}, "target:page");   // covers x 96..224, y 58..122 of the 320 x 180 screen
    Image img = g.render(w);
    CHECK(near(img.pixel(110, 66), kRed));
    CHECK(near(img.pixel(210, 114), kPage));
    CHECK(near(img.pixel(50, 90), kBlack));
}

TEST_CASE("camera tags: a child follows its parent's tag, for showTags and for hideTags") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    World w;
    Camera& cam = game_camera(w);
    cam.hideTags = Json::array({"hidden"});
    Entity hidden = shape(w, "hidden-parent", {-60, 0, 0}, {20, 20}, kRed, {"hidden"});
    Entity child = shape(w, "child", {0, 0, 0}, {20, 20}, kRed);  // a child at its parent's position + (30, 0): no tag of its own
    w.set_parent(child, hidden);
    w.get<Transform>(child)->position = {30, 0, 0};
    shape(w, "visible", {60, 0, 0}, {20, 20}, kGreen);
    Image img = g.render(w);
    CHECK(near(img.pixel(160 - 60, 90), kBlack));  // the tagged parent
    CHECK(near(img.pixel(160 - 30, 90), kBlack));   // its child
    CHECK(near(img.pixel(160 + 60, 90), kGreen));

    // Now the same scene with showTags on the parent: parent and child are drawn, the untagged shape is not.
    cam.hideTags = Json::array();
    cam.showTags = Json::array({"hidden"});
    img = g.render(w);
    CHECK(near(img.pixel(160 - 60, 90), kRed));
    CHECK(near(img.pixel(160 - 30, 90), kRed));
    CHECK(near(img.pixel(160 + 60, 90), kBlack));
}

TEST_CASE("camera tags: the same world seen by two cameras, each with its own mask") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    World w;
    Camera& game = game_camera(w);
    game.hideTags = Json::array({"page"});  // the screen leaves the page's content out...
    Camera& page = target_camera(w, "page", {0, 0, 0}, 64, 32);  // ...which the page camera draws at the same place
    page.showTags = Json::array({"page"});
    shape(w, "red", {-22, 11, 0}, {20, 10}, kRed, {"page"});
    shape(w, "green", {22, -11, 0}, {20, 10}, kGreen);
    sprite_showing(w, "screen", {0, 70, 0}, {128, 64}, "target:page");
    Image img = g.render(w);
    // On the screen: the green shape (no tag), the red one is hidden; the sprite shows only the red one.
    CHECK(near(img.pixel(160 + 22, 90 + 11), kGreen));
    CHECK(near(img.pixel(160 - 22, 90 - 11), kBlack));
    // The sprite is centred at y = +70 (screen y 20), so the top-left of the page is at about screen (110, -4): look at the middle
    // of its lower half instead, which is the page's clear colour with the green shape missing.
    CHECK(near(img.pixel(160 + 44, 20 + 22), kPage));
}

TEST_CASE("camera tags: a camera that does not draw the sprite showing its own target gets no checker") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    World w;
    game_camera(w);
    Camera& mirror = target_camera(w, "mirror", {1000, 0, 0}, 64, 32);
    mirror.hideTags = Json::array({"screen"});
    Entity self = sprite_showing(w, "self", {1000, 0, 0}, {64, 32}, "target:mirror");
    w.info(self).tags = {"screen"};
    Entity screen = sprite_showing(w, "screen", {0, 0, 0}, {128, 64}, "target:mirror");
    (void)screen;
    Image img = g.render(w);
    // The target is its clear colour: the sprite that would show it to itself is not drawn by that camera.
    CHECK(near(img.pixel(160, 90), kPage));
    CHECK(near(img.pixel(110, 66), kPage));
}

TEST_CASE("camera tags: Text and Sprite in world space follow the mask, screen-space visuals do not") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    World w;
    Camera& cam = game_camera(w);
    cam.hideTags = Json::array({"hidden"});
    Entity hudBox = shape(w, "hud", {160, 90, 0}, {40, 40}, kRed, {"hidden"});  // screen space: design pixels from the top-left
    w.get<Shape2D>(hudBox)->space = RenderSpace::Screen;  // a screen-space visual keeps its rules
    Image img = g.render(w);
    CHECK(near(img.pixel(160, 90), kRed));
}

TEST_CASE("camera tags: a mask costs nothing when both lists are empty and does not change what is drawn") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    World w;
    game_camera(w);
    shape(w, "box", {0, 0, 0}, {40, 40}, kGreen, {"anything"});
    Image img = g.render(w);
    CHECK(near(img.pixel(160, 90), kGreen));
}
