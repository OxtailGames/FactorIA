// Area lights, light cookies and IES profiles drawn (M73.1b; docs/design/ARCHITECTURE_RENDERING_LIGHTING.md, "The light atlas"): a rectangle
// light, a spot light with a cookie and a point light with a profile each have a golden; an area light far away lights like the point
// light it replaces; a scene that asks for none of them draws the same pixels with or without the atlas having been made once. The
// parser and the packing are in ies_tests.cpp and light_atlas_tests.cpp (no GPU).
#include "test_util.h"

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <string>

#include "fa/core/fs.h"
#include "fa/core/image.h"

using namespace fa;
using namespace fa::test;

namespace {

// A white floor seen from above, no ambient light and a black sky: only the lights under test draw.
struct Floor {
    World world;
    Entity cam, floor;

    explicit Floor(float camHeight = 7.0f) {
        cam = make(world, "cam", {0, camHeight, 0});
        world.get<Transform>(cam)->rotation = {-90, 0, 0};
        auto& c = world.add<Camera>(cam);
        c.projection = Projection::Perspective;
        c.fov = 50;
        world.settings().ambientLight = Color{0, 0, 0, 1};
        world.settings().skyColor = Color{0, 0, 0, 1};
        world.settings().horizonColor = Color{0, 0, 0, 1};
        floor = make(world, "floor", {0, 0, 0});
        world.get<Transform>(floor)->scale = {10, 1, 10};
        auto& m = world.add<MeshRenderer>(floor);
        m.mesh = "plane";
        m.color = Color{0.8f, 0.8f, 0.8f, 1};
        m.metallic = 0.0f;
        m.roughness = 0.7f;
    }
    // A light `height` metres above the floor pointing down.
    Light& add_light(const char* name, LightType type, float height, Vec3 offset = {0, 0, 0}) {
        Entity e = make(world, name, {offset.x, height, offset.z});
        world.get<Transform>(e)->rotation = {-90, 0, 0};
        Light& l = world.add<Light>(e);
        l.type = type;
        l.castShadows = false;
        return l;
    }
};

Image checker(int cells, int px) {
    Image img;
    img.width = img.height = cells * px;
    img.rgba.resize(std::size_t(img.width) * std::size_t(img.height) * 4);
    for (int y = 0; y < img.height; ++y)
        for (int x = 0; x < img.width; ++x) {
            const bool on = ((x / px) + (y / px)) % 2 == 0;
            std::uint8_t* p = &img.rgba[(std::size_t(y) * std::size_t(img.width) + std::size_t(x)) * 4];
            p[0] = on ? 255 : 20;
            p[1] = on ? 230 : 20;
            p[2] = on ? 200 : 60;
            p[3] = 255;
        }
    return img;
}

// A small downlight profile written for these tests: a narrow beam with a dark ring and a second, weaker one.
const char* const kLamp = "IESNA:LM-63-2002\n"
                          "[TEST] FA-RENDER-001\n"
                          "[LUMINAIRE] Test beam\n"
                          "TILT=NONE\n"
                          "1 1000 1 9 1 1 2 0.1 0.1 0\n"
                          "1 1 10\n"
                          "0 10 20 30 40 50 60 75 90\n"
                          "0\n"
                          "1000 900 600 150 20 400 120 10 0\n";

int px(const Image& img, int x, int y, int c = 0) {
    return img.rgba[(std::size_t(y) * std::size_t(img.width) + std::size_t(x)) * 4 + std::size_t(c)];
}

double mean_abs_diff(const Image& a, const Image& b) {
    REQUIRE(a.width == b.width);
    REQUIRE(a.height == b.height);
    double sum = 0;
    for (std::size_t i = 0; i < a.rgba.size(); ++i) sum += std::abs(int(a.rgba[i]) - int(b.rgba[i])) / 255.0;
    return sum / double(a.rgba.size());
}

}  // namespace

TEST_CASE("area lights: a rectangle light draws its golden, lit on the front only") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    Floor f;
    Light& l = f.add_light("panel", LightType::Area, 2.0f, {0, 0, 0});
    l.shape = LightShape::Rectangle;
    l.size = {3.0f, 1.0f};
    l.color = Color{1.0f, 0.9f, 0.75f, 1};
    l.intensity = 2.0f;
    l.range = 14.0f;
    const Image img = g.render(f.world);
    CHECK(expect_golden(img, "3d_area_light_rect", 0.006).ok());
    // The middle of the floor is lit, the far corner much less.
    CHECK(px(img, img.width / 2, img.height / 2) > px(img, 4, 4) + 20);
    // The same light turned to face up lights the floor with nothing: a rectangle emits from its front.
    f.world.get<Transform>(f.world.find("panel"))->rotation = {90, 0, 0};
    const Image back = g.render(f.world);
    CHECK(px(back, back.width / 2, back.height / 2) < 4);
    // A tube is two-sided: facing up it still lights the floor.
    f.world.get<Light>(f.world.find("panel"))->shape = LightShape::Tube;
    const Image tube = g.render(f.world);
    CHECK(px(tube, tube.width / 2, tube.height / 2) > 20);
}

TEST_CASE("area lights: far from the floor a small area light lights like the point light of the same intensity") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    auto centre = [&](bool area, LightShape shape) {
        Floor f(9.0f);
        Light& l = f.add_light("lamp", area ? LightType::Area : LightType::Point, 5.0f);
        l.shape = shape;
        l.size = {0.4f, 0.4f};
        l.intensity = 0.4f;
        l.range = 30.0f;
        const Image img = g.render(f.world);
        return double(px(img, img.width / 2, img.height / 2, 1));
    };
    const double point = centre(false, LightShape::Rectangle);
    REQUIRE(point > 30);
    REQUIRE(point < 180);
    for (LightShape shape : {LightShape::Rectangle, LightShape::Disc, LightShape::Tube}) {
        const double area = centre(true, shape);
        MESSAGE("shape " << int(shape) << ": point " << point << ", area " << area);
        CHECK(area == doctest::Approx(point).epsilon(0.05));
    }
}

TEST_CASE("light cookies: a spot light projects its texture, and draws its golden") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    REQUIRE(save_png(checker(4, 8), "assets/cookie_checker.png").ok());
    Floor f;
    Light& l = f.add_light("spot", LightType::Spot, 4.0f);
    l.spotAngle = 40.0f;
    l.range = 16.0f;
    l.intensity = 3.0f;
    const Image plain = g.render(f.world);
    f.world.get<Light>(f.world.find("spot"))->cookie = "assets/cookie_checker.png";
    const Image img = g.render(f.world);
    CHECK(expect_golden(img, "3d_light_cookie_spot", 0.006).ok());
    CHECK(mean_abs_diff(plain, img) > 0.01);
    // The pattern: along a row through the middle of a row of cells the lit pixels alternate between bright and dark cells.
    int transitions = 0;
    const int row = img.height / 2 - 22;
    bool bright = px(img, 90, row) > 150;
    for (int x = 90; x <= 230; ++x) {
        const int v = px(img, x, row);
        if (bright && v < 90) bright = false, ++transitions;
        if (!bright && v > 150) bright = true, ++transitions;
    }
    CHECK(transitions >= 2);
    // A cookie that is missing is reported and the light is drawn without it.
    f.world.get<Light>(f.world.find("spot"))->cookie = "assets/no_such_cookie.png";
    const Image missing = g.render(f.world);
    CHECK(mean_abs_diff(plain, missing) < 0.004);
}

TEST_CASE("IES profiles: a point light follows the distribution of its file, and draws its golden") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    REQUIRE(fs::write_text("assets/test_beam.ies", kLamp).ok());
    Floor f;
    Light& l = f.add_light("lamp", LightType::Point, 3.0f);
    l.range = 20.0f;
    l.intensity = 2.0f;
    const Image plain = g.render(f.world);
    f.world.get<Light>(f.world.find("lamp"))->ies = "assets/test_beam.ies";
    const Image img = g.render(f.world);
    CHECK(expect_golden(img, "3d_light_ies", 0.006).ok());
    CHECK(mean_abs_diff(plain, img) > 0.01);
    // The nadir is the brightest point of the profile; the plain point light is brightest there too, but its fall-off to the sides is
    // the cosine alone, while the profile has a dark ring at 40 degrees (a radius of 3 m x tan 40 = 2.5 m on the floor).
    const int cx = img.width / 2, cy = img.height / 2;
    CHECK(px(img, cx, cy, 1) > 100);
    const double metresPerPixel = 2.0 * 7.0 * std::tan(25.0 * 3.14159265 / 180.0) / double(img.height);
    const int ringPx = int(2.5 / metresPerPixel);
    CHECK(px(img, cx + ringPx, cy, 1) < px(plain, cx + ringPx, cy, 1));
}

TEST_CASE("light atlas: a scene that asks for no area light, cookie or profile draws the same pixels after the atlas "
          "was made and freed") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    REQUIRE(save_png(checker(2, 8), "assets/cookie_identity.png").ok());
    Floor f;
    Light& a = f.add_light("a", LightType::Point, 3.0f, {-1, 0, 0});
    a.intensity = 0.8f;
    Light& b = f.add_light("b", LightType::Spot, 4.0f, {1, 0, 0});
    b.intensity = 2.5f;
    b.spotAngle = 35.0f;
    const Image before = g.render(f.world);
    f.world.get<Light>(f.world.find("b"))->cookie = "assets/cookie_identity.png";
    const Image with = g.render(f.world);
    CHECK(mean_abs_diff(before, with) > 0.002);
    f.world.get<Light>(f.world.find("b"))->cookie.clear();
    const Image after = g.render(f.world);
    CHECK(before.rgba == after.rgba);
}

TEST_CASE("light cookies: a file changed on disk is baked again after reload_asset") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    REQUIRE(save_png(checker(4, 8), "assets/cookie_reload.png").ok());
    Floor f;
    Light& l = f.add_light("spot", LightType::Spot, 4.0f);
    l.spotAngle = 40.0f;
    l.range = 16.0f;
    l.intensity = 3.0f;
    l.cookie = "assets/cookie_reload.png";
    const Image first = g.render(f.world);
    Image solid;
    solid.width = solid.height = 8;
    solid.rgba.assign(std::size_t(8 * 8 * 4), 255);
    REQUIRE(save_png(solid, "assets/cookie_reload.png").ok());
    const Image stale = g.render(f.world);
    CHECK(first.rgba == stale.rgba);  // not read again until the renderer is told
    g.renderer.reload_asset("assets/cookie_reload.png");
    const Image fresh = g.render(f.world);
    CHECK(mean_abs_diff(first, fresh) > 0.005);
}
