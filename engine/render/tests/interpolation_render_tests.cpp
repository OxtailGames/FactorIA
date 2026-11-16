// Render interpolation (fa/scene/interpolation.h) and the renderer: the picture is made from the blended pose of the camera, while
// what scripts ask (world_to_screen, screen_to_world, Parallax.offset) is answered from its real pose, whatever the alpha.
#include "test_util.h"

#include <cmath>

#include "fa/scene/bounds.h"
#include "fa/scene/interpolation.h"

using namespace fa;
using namespace fa::test;

namespace {

bool near(const Color& a, const Color& b, float tol = 0.03f) {
    return std::fabs(a.r - b.r) <= tol && std::fabs(a.g - b.g) <= tol && std::fabs(a.b - b.b) <= tol;
}

// A camera that a fixed step moved from x = 0 to `to`, and the frame drawn `alpha` of the way there.
struct Scene {
    World w;
    Entity cam, mover, mark;
    explicit Scene(float to, double alpha, bool moveCamera = true) {
        w.interp().enabled = true;
        cam = make(w, "cam", {0, 0, 0});
        w.add<Camera>(cam).clearColor = Color::black();
        mover = make(w, "mover", {0, 50, 0});
        w.add<Sprite>(mover).size = {4, 4};
        mark = make(w, "mark", {20, 0, 0});  // a square where the BLENDED camera (at x = 20) looks
        auto& s = w.add<Shape2D>(mark);
        s.shape = ShapeType::Rectangle;
        s.size = {4, 4};
        s.color = Color::hex(0xff0000);
        interp_update(w, 1.0, true);
        interp_begin_step(w);
        if (moveCamera) w.get<Transform>(cam)->position.x = to;
        w.get<Transform>(mover)->position.x += 10.0f;
        interp_update(w, alpha, true);
        interp_update(w, alpha, false);
    }
};

}  // namespace

TEST_CASE("render interpolation: queries answer from the real camera pose, the picture is drawn from the blended one") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    for (const double alpha : {0.5, 1.0}) {
        INFO("alpha " << alpha);
        Scene s(40.0f, alpha);
        CHECK((s.w.interp().poseCount > 0) == (alpha < 1.0));  // alpha 1 draws the real pose: nothing is blended
        Image img = g.render(s.w);
        // The real camera is at x = 40 whatever the alpha: a world point on it is at the middle of the screen.
        const Vec2 mid = g.renderer.world_to_screen({40, 0, 0});
        CHECK(mid.x == doctest::Approx(160.0f));
        CHECK(mid.y == doctest::Approx(90.0f));
        const Vec3 back = g.renderer.screen_to_world({170, 80}, 0.0f);
        CHECK(back.x == doctest::Approx(50.0f));
        CHECK(back.y == doctest::Approx(10.0f));
        // Same through the camera named.
        CHECK(g.renderer.world_to_screen({40, 0, 0}, s.cam).x == doctest::Approx(160.0f));
        // The drawing is at the blended pose: the camera looks at x = 40 * alpha.
        const int px = int(std::lround(160.0 + (20.0 - 40.0 * alpha)));
        CHECK(near(img.pixel(px, 90), Color::hex(0xff0000)));
        // update() alone (no drawing) answers the same.
        g.renderer.update(s.w);
        CHECK(g.renderer.world_to_screen({40, 0, 0}).x == doctest::Approx(160.0f));
    }
}

TEST_CASE("render interpolation: a blended entity that is not the camera leaves the queries alone") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    Scene s(0.0f, 0.5, false);  // the camera did not move: only the sprite is blended
    REQUIRE(s.w.interp().poseCount > 0);
    g.render(s.w);
    CHECK(g.renderer.world_to_screen({0, 0, 0}).x == doctest::Approx(160.0f));
    CHECK(g.renderer.screen_to_world({170, 80}, 0.0f).x == doctest::Approx(10.0f));
}

TEST_CASE("render interpolation: a camera under a blended parent is blended, queries use the real pose") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    World w;
    w.interp().enabled = true;
    Entity rig = make(w, "rig", {0, 0, 0});
    Entity cam = make(w, "cam", {0, 0, 0});
    w.add<Camera>(cam);
    w.set_parent(cam, rig);
    Entity otherCam =
        make(w, "other", {0, 0, 0});  // a second camera that is not the primary one: it must not take the queries
    w.add<Camera>(otherCam).primary = false;
    interp_update(w, 1.0, true);
    interp_begin_step(w);
    w.get<Transform>(rig)->position.x = 40.0f;
    interp_update(w, 0.5, true);
    interp_update(w, 0.5, false);
    REQUIRE(w.interp().pose_of(rig) !=
            nullptr);  // the parent is blended, so the camera under it is drawn from a blended pose
    g.render(w);
    CHECK(g.renderer.world_to_screen({40, 0, 0}).x == doctest::Approx(160.0f));
}

TEST_CASE("render interpolation: Parallax.offset follows the real camera, whatever the alpha") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    for (const double alpha : {0.25, 0.5, 1.0}) {
        INFO("alpha " << alpha);
        Scene s(40.0f, alpha);
        Entity layer = make(s.w, "layer", {0, 0, 0});
        s.w.add<Sprite>(layer).size = {4, 4};
        s.w.add<Parallax>(layer).factor = {0.5f, 0.5f};
        g.render(s.w);
        CHECK(s.w.get<Parallax>(layer)->offset.x == doctest::Approx(20.0f));  // 40 * (1 - 0.5)
        // entity.bounds() of the layer is moved by the same offset: a 4 x 4 sprite at the origin, centred on x = 20
        const std::optional<Rect> box = entity_world_rect(s.w, layer);
        REQUIRE(box.has_value());
        CHECK(box->x + box->w * 0.5f == doctest::Approx(20.0f));
        g.renderer.update(s.w);
        CHECK(s.w.get<Parallax>(layer)->offset.x == doctest::Approx(20.0f));
        const std::optional<Rect> again = entity_world_rect(s.w, layer);
        REQUIRE(again.has_value());
        CHECK(again->x + again->w * 0.5f == doctest::Approx(20.0f));
    }
}
