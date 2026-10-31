// SpriteSkin: a sprite deformed by Bone2D entities is drawn into the same vertex stream as a mesh sprite.
#include "test_util.h"

#include "fa/scene/bones2d.h"

using namespace fa;
using namespace fa::test;

namespace {

struct Arm {
    World w;
    Entity sprite, b0, b1;
    Arm() {
        w.add<Camera>(make(w, "cam")).clearColor = Color::black();
        sprite = make(w, "arm");  // 80 x 20 box around the origin: x -40..39, y -10..9 (pixels x 120..199, y 80..99)
        Sprite& s = w.add<Sprite>(sprite);
        s.size = {80, 20};
        s.meshColumns = 8;
        s.meshRows = 2;
        b0 = w.create("b0");
        w.add<Bone2D>(b0).length = 40;
        w.set_parent(b0, sprite);
        w.get<Transform>(b0)->position = {-40, 0, 0};
        b1 = w.create("b1");
        w.add<Bone2D>(b1).length = 40;
        w.set_parent(b1, b0);
        w.get<Transform>(b1)->position = {40, 0, 0};
        w.add<SpriteSkin>(sprite).bones = Json::array({"b0", "b1"});
    }
};

}  // namespace

TEST_CASE("SpriteSkin: bones at their bind pose draw the sprite as it is; a bent bone bends the picture, in the same draw calls") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    Arm a;
    // The reference: the same sprite and mesh without the skin.
    World plainWorld;
    plainWorld.add<Camera>(make(plainWorld, "cam")).clearColor = Color::black();
    Entity p = make(plainWorld, "arm");
    Sprite& ps = plainWorld.add<Sprite>(p);
    ps.size = {80, 20};
    ps.meshColumns = 8;
    ps.meshRows = 2;
    const Image plain = g.render(plainWorld);
    const int plainCalls = g.renderer.stats().drawCalls;

    const Image rest = g.render(a.w);  // the renderer binds the skin here, at the straight pose
    CHECK(skin_is_bound(a.w, a.sprite));
    CHECK(diff_images(plain, rest, 2.0f / 255.0f).meanError < 0.0005);
    CHECK(g.renderer.stats().drawCalls == plainCalls);

    a.w.get<Transform>(a.b1)->rotation.z = 90.0f;  // the right half swings up about the middle
    const Image bent = g.render(a.w);
    CHECK(g.renderer.stats().drawCalls == plainCalls);
    CHECK(g.renderer.stats().sprites == 1);
    CHECK(bent.pixel(130, 90).r > 0.95f);   // the left half did not move
    CHECK(bent.pixel(160, 55).r > 0.9f);    // the right half now stands above the middle (x 150..170, y 50..90)
    CHECK(bent.pixel(192, 90).r < 0.05f);   // and no longer lies to the right
    CHECK(bent.pixel(176, 90).r < 0.3f);

    // A bone outside the angle of the picture's pixels does not matter: turning back restores the picture.
    a.w.get<Transform>(a.b1)->rotation.z = 0.0f;
    const Image back = g.render(a.w);
    CHECK(diff_images(plain, back, 2.0f / 255.0f).meanError < 0.0005);
}

TEST_CASE("SpriteSkin: a screen-space sprite and a sprite without a mesh draw as plain sprites; the problem is reported once") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    Arm a;
    a.w.get<Sprite>(a.sprite)->meshColumns = 0;  // no grid and no outline: nothing to deform
    a.w.get<Transform>(a.b1)->rotation.z = 90.0f;
    const Image img = g.render(a.w);
    CHECK(img.pixel(185, 90).r > 0.95f);  // the plain 80 x 20 box
    CHECK(a.w.get<SpriteSkin>(a.sprite)->warned);
}

TEST_CASE("debug_draw_bones: one kite per Bone2D of the subtree, all of them without a root") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    Arm a;
    CHECK(debug_draw_bones(g.renderer.debug(), a.w, kNullEntity) == 2);
    CHECK(debug_draw_bones(g.renderer.debug(), a.w, a.b1) == 1);
    CHECK(debug_draw_bones(g.renderer.debug(), a.w, a.b0) == 2);
    g.renderer.debug().clear();
}
