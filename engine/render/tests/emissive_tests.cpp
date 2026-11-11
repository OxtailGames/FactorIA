// MeshRenderer.emissiveStrength: an emissive colour above white. The screen clamps at white, but the game target holds the
// value (a float format) so Camera.bloom sees how much brighter than white a surface is.
#include "test_util.h"

#include <algorithm>
#include <cmath>

using namespace fa;
using namespace fa::test;

namespace {

// A camera looking down -Z at a sphere that gives off light only (unlit, black albedo): its pixel is emissive * strength.
struct GlowScene {
    World world;
    Entity cam, glow;

    GlowScene(Color emissive, float strength) {
        cam = make(world, "cam", {0, 0, 4});
        auto& c = world.add<Camera>(cam);
        c.projection = Projection::Perspective;
        c.fov = 40;
        c.clearColor = Color{0, 0, 0, 1};
        world.settings().ambientLight = Color{0, 0, 0, 1};
        world.settings().skyColor = Color{0, 0, 0, 1};  // the 3D background (clearColor is for 2D)
        world.settings().horizonColor = Color{0, 0, 0, 1};
        glow = make(world, "glow", {0, 0, 0});
        auto& m = world.add<MeshRenderer>(glow);
        m.mesh = "sphere";
        m.color = Color{0, 0, 0, 1};
        m.unlit = true;
        m.emissive = emissive;
        m.emissiveStrength = strength;
    }
    MeshRenderer& mesh() { return *world.get<MeshRenderer>(glow); }
    void bloom(float threshold, float intensity = 1.0f, float radius = 12.0f) {
        Camera& c = *world.get<Camera>(cam);
        c.bloom = true;
        c.bloomThreshold = threshold;
        c.bloomIntensity = intensity;
        c.bloomRadius = radius;
    }
};

// Sum of the red channel over the picture outside the sphere's disc (the halo bloom paints around it).
double halo(const Image& img) {
    double sum = 0;
    const int cx = img.width / 2, cy = img.height / 2;
    for (int y = 0; y < img.height; ++y)
        for (int x = 0; x < img.width; ++x)
            if (std::hypot(x - cx, y - cy) > 40.0) sum += img.pixel(x, y).r;
    return sum;
}

}  // namespace

TEST_CASE("emissiveStrength multiplies the emitted colour, and the screen clamps at white") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    const Color centre = [&] {
        GlowScene s(Color{0.25f, 0.25f, 0.25f, 1}, 1.0f);
        return g.render(s.world).pixel(160, 90);
    }();
    CHECK(centre.r == doctest::Approx(0.25f).epsilon(0.03));
    GlowScene s(Color{0.25f, 0.25f, 0.25f, 1}, 2.0f);
    CHECK(g.render(s.world).pixel(160, 90).r == doctest::Approx(0.5f).epsilon(0.03));
    s.mesh().emissiveStrength = 8.0f;  // 2.0 in the game target, white on the screen
    const Color white = g.render(s.world).pixel(160, 90);
    CHECK(white.r == doctest::Approx(1.0f).epsilon(0.01));
    CHECK(white.g == doctest::Approx(1.0f).epsilon(0.01));
    s.mesh().emissiveStrength = 0.0f;  // no glow at all
    CHECK(g.render(s.world).pixel(160, 90).r < 0.02f);
    s.mesh().emissiveStrength = std::nanf("");  // a script wrote garbage: no glow, no NaN pixel
    CHECK(g.render(s.world).pixel(160, 90).r < 0.02f);
}

TEST_CASE("emissiveStrength above 1 makes a bigger, brighter bloom halo when the game target is float") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    // 0.5 * 2 = 1.0 and 0.5 * 8 = 4.0: both are white on the surface, but the second carries four times the light into the blur.
    GlowScene s(Color{0.5f, 0.5f, 0.5f, 1}, 2.0f);
    s.bloom(0.6f);
    const double weak = halo(g.render(s.world));
    s.mesh().emissiveStrength = 8.0f;
    const double strong = halo(g.render(s.world));
    INFO("hdr_scene=" << g.renderer.hdr_scene() << " weak=" << weak << " strong=" << strong);
    CHECK(weak > 0.0);  // plain bloom works on any GPU
    if (g.renderer.hdr_scene()) CHECK(strong > weak * 1.5);
    else CHECK(strong == doctest::Approx(weak).epsilon(0.05));  // an 8-bit target clamps both to white

    // Below the threshold nothing glows: 0.5 * 1 = 0.5 < 0.6.
    s.mesh().emissiveStrength = 1.0f;
    CHECK(halo(g.render(s.world)) < 1.0);
}

TEST_CASE("emissiveStrength splits a batch exactly like a different emissive colour does") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    auto draws = [&](float strengthB, Color emissiveB) {
        GlowScene s(Color{0.3f, 0.3f, 0.3f, 1}, 1.0f);
        Entity other = make(s.world, "other", {1.5f, 0, 0});
        auto& m = s.world.add<MeshRenderer>(other);
        m.mesh = "sphere";
        m.color = Color{0, 0, 0, 1};
        m.unlit = true;
        m.emissive = emissiveB;
        m.emissiveStrength = strengthB;
        g.render(s.world);
        return g.renderer.stats().drawCalls;
    };
    const int same = draws(1.0f, Color{0.3f, 0.3f, 0.3f, 1});
    const int otherStrength = draws(3.0f, Color{0.3f, 0.3f, 0.3f, 1});
    const int otherColour = draws(1.0f, Color{0.6f, 0.3f, 0.3f, 1});
    CHECK(otherStrength == same + 1);
    CHECK(otherColour == same + 1);
}
