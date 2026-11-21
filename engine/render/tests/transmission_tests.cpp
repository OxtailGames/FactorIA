// M73-P6b: transmission and volume (glass, liquids). The refraction atlas is pure arithmetic (xmit_layout, no GPU); the drawing runs on the
// backend of the machine: a glass ball in front of a coloured wall shows the wall, tinted by the attenuation, blurred by the roughness, and a
// frame with no visible glass copies nothing and is the frame it was before the feature (docs/rendering/RENDERING_TRANSMISSION.md).
#include "test_util.h"

#include <algorithm>
#include <cmath>
#include <cstring>

#include "material_cost.h"
#include "renderer_xmit.h"

using namespace fa;
using namespace fa::test;
using fa::render::kXmitMaxLevels;
using fa::render::xmit_layout;
using fa::render::XmitLayout;

namespace {

// A wall of `stripes` unlit cubes behind the glass (alternating `a` and `b`), seen from a camera 4 m in front of the origin.
struct Glass {
    World world;
    Entity cam, ball, sun;

    Glass(Color a, Color b, int stripes, float transmission = 1.0f, float roughness = 0.0f) {
        cam = make(world, "cam", {0, 0, 4});
        auto& c = world.add<Camera>(cam);
        c.projection = Projection::Perspective;
        c.fov = 40;
        world.settings().ambientLight = Color{0, 0, 0, 1};
        world.settings().skyColor = Color{0, 0, 0, 1};
        world.settings().horizonColor = Color{0, 0, 0, 1};
        const float width = 4.0f / float(stripes);
        for (int i = 0; i < stripes; ++i) {
            Entity e = make(world, "stripe", {-2.0f + width * (float(i) + 0.5f), 0, -2});
            world.get<Transform>(e)->scale = {width, 4, 0.1f};
            auto& m = world.add<MeshRenderer>(e);
            m.mesh = "cube";
            m.unlit = true;
            m.color = (i % 2 == 0) ? a : b;
        }
        ball = make(world, "glass", {0, 0, 0});
        world.get<Transform>(ball)->scale = {1.6f, 1.6f, 1.6f};
        auto& m = world.add<MeshRenderer>(ball);
        m.mesh = "sphere";
        m.color = Color{1, 1, 1, 1};
        m.roughness = roughness;
        m.metallic = 0.0f;
        m.transmission = transmission;
        sun = make(world, "sun", {0, 4, 0});
        world.get<Transform>(sun)->rotation = {-70, 40, 0};  // grazing: the highlight is not at the ball's centre
        auto& l = world.add<Light>(sun);
        l.type = LightType::Directional;
        l.intensity = 1.0f;
        l.castShadows = false;
    }
    MeshRenderer& mesh() { return *world.get<MeshRenderer>(ball); }
};

// The mean colour of the box (x0,y0)-(x1,y1) of the 320x180 picture: the middle of the ball is 40 pixels from its edge.
Color mean_of(const Image& img, int x0 = 140, int y0 = 70, int x1 = 180, int y1 = 110) {
    double r = 0, g = 0, b = 0;
    int n = 0;
    for (int y = y0; y < y1; ++y)
        for (int x = x0; x < x1; ++x) {
            const Color c = img.pixel(x, y);
            r += c.r;
            g += c.g;
            b += c.b;
            ++n;
        }
    return Color{float(r / n), float(g / n), float(b / n), 1.0f};
}

float luma(const Color& c) { return 0.2126f * c.r + 0.7152f * c.g + 0.0722f * c.b; }

// The variance of the luma over the same box: a blurred picture of stripes has little.
double variance_of(const Image& img, int x0 = 125, int y0 = 60, int x1 = 195, int y1 = 120) {
    double sum = 0, sum2 = 0;
    int n = 0;
    for (int y = y0; y < y1; ++y)
        for (int x = x0; x < x1; ++x) {
            const double l = luma(img.pixel(x, y));
            sum += l;
            sum2 += l * l;
            ++n;
        }
    const double mean = sum / n;
    return sum2 / n - mean * mean;
}

int differing_pixels(const Image& a, const Image& b, int x0, int y0, int x1, int y1) {
    int n = 0;
    for (int y = y0; y < y1; ++y)
        for (int x = x0; x < x1; ++x) {
            const Color p = a.pixel(x, y), q = b.pixel(x, y);
            if (std::fabs(p.r - q.r) > 2.0f / 255 || std::fabs(p.g - q.g) > 2.0f / 255 ||
                std::fabs(p.b - q.b) > 2.0f / 255)
                ++n;
        }
    return n;
}

}  // namespace

// ---------------------------------------------------------------------------------------------------------------------
// The atlas layout (no GPU)
// ---------------------------------------------------------------------------------------------------------------------

TEST_CASE("transmission: the material cost of a mesh-less unlit renderer with transmission reports transmission off") {
    // No mesh asset (it did not load) and no material: only the MeshRenderer's own fields count, and unlit never refracts.
    MeshRenderer mr;
    mr.transmission = 1.0f;
    mr.unlit = true;
    const Json off = fa::render::material_cost_report(mr, nullptr, nullptr, 0, 0);
    bool found = false;
    for (const Json& f : off["features"]) {
        if (f["name"] != "transmission") continue;
        found = true;
        CHECK(f["active"] == false);
        CHECK(f["extraPasses"] == 0);
    }
    CHECK(found);
    CHECK(off["extraPasses"] == 0);
    // The same renderer lit does refract.
    mr.unlit = false;
    const Json on = fa::render::material_cost_report(mr, nullptr, nullptr, 0, 0);
    for (const Json& f : on["features"])
        if (f["name"] == "transmission") CHECK(f["active"] == true);
}

TEST_CASE("transmission: the refraction atlas holds the picture and a half-size chain, at most five levels") {
    // 320 x 180: level 0 on the left, levels 1.. stacked in a column at its right.
    const XmitLayout l = xmit_layout(320, 180);
    REQUIRE(l.levels == kXmitMaxLevels);
    CHECK(l.level[0].x == 0);
    CHECK(l.level[0].y == 0);
    CHECK(l.level[0].w == 320);
    CHECK(l.level[0].h == 180);
    CHECK(l.level[1].x == 320);
    CHECK(l.level[1].y == 0);
    CHECK(l.level[1].w == 160);
    CHECK(l.level[1].h == 90);
    CHECK(l.level[2].x == 320);
    CHECK(l.level[2].y == 90);
    CHECK(l.level[2].w == 80);
    CHECK(l.level[2].h == 45);
    CHECK(l.level[3].y == 135);
    CHECK(l.level[3].h == 22);
    CHECK(l.level[4].y == 157);
    CHECK(l.level[4].w == 20);
    CHECK(l.level[4].h == 11);
    CHECK(l.atlasW == 480);
    CHECK(l.atlasH == 180);  // the column is 168 rows: the picture's height decides

    // Every level lies inside the atlas and no two levels overlap.
    for (int a = 0; a < l.levels; ++a) {
        CHECK(l.level[a].x + l.level[a].w <= l.atlasW);
        CHECK(l.level[a].y + l.level[a].h <= l.atlasH);
        for (int b = a + 1; b < l.levels; ++b) {
            const bool apart =
                l.level[a].x + l.level[a].w <= l.level[b].x || l.level[b].x + l.level[b].w <= l.level[a].x ||
                l.level[a].y + l.level[a].h <= l.level[b].y || l.level[b].y + l.level[b].h <= l.level[a].y;
            CHECK(apart);
        }
    }
}

TEST_CASE("transmission: a small camera rectangle has fewer levels, and nothing at all below one pixel") {
    CHECK(xmit_layout(0, 10).levels == 0);
    CHECK(xmit_layout(10, -1).levels == 0);
    const XmitLayout one = xmit_layout(1, 1);
    CHECK(one.levels == 1);
    CHECK(one.atlasW == 1);
    CHECK(one.atlasH == 1);
    const XmitLayout two = xmit_layout(2, 2);
    CHECK(two.levels == 2);
    CHECK(two.level[1].w == 1);
    CHECK(two.level[1].h == 1);
    CHECK(two.level[1].x == 2);
    CHECK(two.atlasW == 3);
    // The shorter side counts: 8 x 100 halves to 4, 2, 1.
    CHECK(xmit_layout(8, 100).levels == 4);
    // A tall thin rectangle: the stacked column is taller than the picture only when the picture is small, never more than twice its height.
    const XmitLayout tall = xmit_layout(16, 16);
    CHECK(tall.levels == 5);
    CHECK(tall.atlasH >= 16);
    CHECK(tall.atlasH <= 32);
}

// ---------------------------------------------------------------------------------------------------------------------
// Drawing
// ---------------------------------------------------------------------------------------------------------------------

TEST_CASE("transmission: a glass ball in front of a red wall shows the wall, an opaque one does not") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    const Color red{0.9f, 0.1f, 0.1f, 1};
    Glass glass(red, red, 1);
    const Image glassy = g.render(glass.world);
    const RenderStats stats = g.renderer.stats();
    CHECK(stats.transmissiveMeshes == 1);
    CHECK(stats.transmissionCopies == 1);
    CHECK(stats.transmissionPlain == 0);

    Glass opaque(red, red, 1, 0.0f);
    const Image solid = g.render(opaque.world);
    CHECK(g.renderer.stats().transmissionCopies == 0);

    const Color through = mean_of(glassy);
    const Color body = mean_of(solid);
    // The glass is the wall (red) seen through it; the opaque ball is a grey-white body lit by the sun.
    CHECK(through.r > 2.0f * through.g);
    CHECK(through.r > 2.0f * through.b);
    CHECK(body.r < 1.6f * body.g);
}

TEST_CASE("transmission: the thickness bends the picture inside the ball and leaves the rest alone") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    const Color white{1, 1, 1, 1}, black{0, 0, 0, 1};
    Glass straight(white, black, 10);  // thickness 0: the light is not offset, the wall is seen straight through
    const Image flat = g.render(straight.world);
    Glass bent(white, black, 10);
    bent.mesh().thickness = 0.8f;
    const Image refracted = g.render(bent.world);
    CHECK(g.renderer.stats().transmissionCopies == 1);
    // The ball is about 100 pixels across in the middle of the 320 x 180 picture: outside it nothing differs.
    CHECK(differing_pixels(refracted, flat, 0, 0, 80, 180) == 0);
    CHECK(differing_pixels(refracted, flat, 240, 0, 320, 180) == 0);
    // Inside, the stripes moved: a large part of the box differs.
    CHECK(differing_pixels(refracted, flat, 120, 50, 200, 130) > 1200);

    // The glass is not the wall: with the ball gone the same box shows the stripes as they are.
    Glass gone(white, black, 10);
    gone.world.remove<MeshRenderer>(gone.ball);
    const Image wall = g.render(gone.world);
    CHECK(g.renderer.stats().transmissionCopies == 0);
    CHECK(differing_pixels(refracted, wall, 0, 0, 80, 180) == 0);
    CHECK(differing_pixels(refracted, wall, 120, 50, 200, 130) > 1200);
}

TEST_CASE("transmission: the attenuation colour tints what passes through, over the distance given") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    const Color white{1, 1, 1, 1};
    Glass clear(white, white, 1);
    clear.mesh().thickness = 1.0f;  // thickness with no attenuation distance: not tinted
    const Color plain = mean_of(g.render(clear.world));

    Glass green(white, white, 1);
    green.mesh().thickness = 1.0f;
    green.mesh().attenuationColor = Color{0.2f, 1.0f, 0.2f, 1};
    green.mesh().attenuationDistance = 0.5f;  // twice the colour over the one metre
    const Color tinted = mean_of(g.render(green.world));

    CHECK(plain.r > 0.3f);  // the wall is bright
    CHECK(tinted.g > 0.7f * plain.g);
    CHECK(tinted.r < 0.5f * plain.r);
    CHECK(tinted.b < 0.5f * plain.b);
}

TEST_CASE("transmission: the thicker the volume, the darker the light that comes out") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    const Color white{1, 1, 1, 1};
    float last = 1e9f;
    float first = 0.0f;
    for (float thickness : {0.0f, 0.3f, 1.0f, 2.0f}) {
        CAPTURE(thickness);
        Glass glass(white, white, 1);
        glass.mesh().thickness = thickness;
        glass.mesh().attenuationColor = Color{0.5f, 0.5f, 0.5f, 1};
        glass.mesh().attenuationDistance = 1.0f;
        const float l = luma(mean_of(g.render(glass.world)));
        if (thickness == 0.0f) first = l;
        CHECK(l < last);
        last = l;
    }
    CHECK(last < 0.5f * first);  // 2 m at 0.5 per metre: a quarter of the light
}

TEST_CASE("transmission: roughness blurs what is seen through the glass") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    const Color white{1, 1, 1, 1}, black{0, 0, 0, 1};
    Glass smooth(white, black, 14, 1.0f, 0.0f);
    const double sharp = variance_of(g.render(smooth.world));
    Glass rough(white, black, 14, 1.0f, 1.0f);
    const double blurred = variance_of(g.render(rough.world));
    CHECK(sharp > 0.02);  // the stripes are there
    CHECK(blurred < 0.5 * sharp);
    // A middle roughness is in between.
    Glass middle(white, black, 14, 1.0f, 0.5f);
    const double mid = variance_of(g.render(middle.world));
    CHECK(mid <= sharp);
    CHECK(mid >= blurred);
}

TEST_CASE("transmission: a frame with no visible glass copies nothing and is the frame without the glass") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    const Color red{0.9f, 0.1f, 0.1f, 1}, blue{0.1f, 0.1f, 0.9f, 1};
    Glass without(red, blue, 4);
    without.world.remove<MeshRenderer>(without.ball);
    const Image plain = g.render(without.world);
    CHECK(g.renderer.stats().transmissiveMeshes == 0);
    CHECK(g.renderer.stats().transmissionCopies == 0);

    // The same scene with a glass ball far outside the picture: culled, so nothing is copied and no pixel changes.
    Glass culled(red, blue, 4);
    culled.world.get<Transform>(culled.ball)->position = {400, 0, 0};
    const Image culledImage = g.render(culled.world);
    CHECK(g.renderer.stats().transmissiveMeshes == 0);
    CHECK(g.renderer.stats().transmissionCopies == 0);
    REQUIRE(culledImage.rgba.size() == plain.rgba.size());
    CHECK(std::memcmp(culledImage.rgba.data(), plain.rgba.data(), plain.rgba.size()) == 0);

    // Brought into the picture it is copied once (the statistics are per frame, not running totals), and taken away again it is zero.
    culled.world.get<Transform>(culled.ball)->position = {0, 0, 0};
    g.render(culled.world);
    CHECK(g.renderer.stats().transmissiveMeshes == 1);
    CHECK(g.renderer.stats().transmissionCopies == 1);
    g.render(without.world);
    CHECK(g.renderer.stats().transmissionCopies == 0);
}

TEST_CASE("transmission: two glass balls share one copy of the opaque picture") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    Glass glass(Color{0.9f, 0.1f, 0.1f, 1}, Color{0.1f, 0.1f, 0.9f, 1}, 4);
    Entity second = make(glass.world, "glass2", {-1.0f, 0, 0.5f});
    auto& m = glass.world.add<MeshRenderer>(second);
    m.mesh = "sphere";
    m.transmission = 0.8f;
    g.render(glass.world);
    CHECK(g.renderer.stats().transmissiveMeshes == 2);
    CHECK(g.renderer.stats().transmissionCopies == 1);
}

TEST_CASE("transmission: a glass ball with tinted, rough volume (golden)") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    Glass glass(Color{0.95f, 0.85f, 0.2f, 1}, Color{0.15f, 0.2f, 0.7f, 1}, 8, 1.0f, 0.25f);
    glass.mesh().thickness = 0.4f;
    glass.mesh().attenuationColor = Color{0.4f, 0.8f, 0.9f, 1};
    glass.mesh().attenuationDistance = 0.8f;
    const Image img = g.render(glass.world);
    expect_golden(img, "3d_transmission");
}
