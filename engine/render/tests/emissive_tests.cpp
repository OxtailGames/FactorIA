// MeshRenderer.emissiveStrength: an emissive colour above white. The screen clamps at white, but the game target holds the
// value (a float format) so Camera.bloom sees how much brighter than white a surface is.
#include "test_util.h"

#include <algorithm>
#include <array>
#include <cmath>
#include <cstdlib>
#include <string>

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
    // Margin: the strong halo carries 4x the light of the weak one into the blur (4.0 against 1.0), but the sum counts the pixels
    // outside the disc after the screen clamps them at white, so the ratio measured is well below 4. 1.5 is a loose floor that a
    // different blur or MSAA kernel will not cross; a clamped (8-bit) target gives a ratio of 1.
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

namespace {

// Sets (or, with nullptr, clears) an environment variable for the life of the object.
struct EnvGuard {
    std::string name, old;
    bool had = false;
    EnvGuard(const char* n, const char* value) : name(n) {
        if (const char* cur = std::getenv(n)) {
            had = true;
            old = cur;
        }
        set(value);
    }
    ~EnvGuard() { set(had ? old.c_str() : nullptr); }
    void set(const char* value) const {
#if defined(_WIN32)
        _putenv_s(name.c_str(), value ? value : "");  // an empty value removes the variable
#else
        if (value) setenv(name.c_str(), value, 1);
        else unsetenv(name.c_str());
#endif
    }
};

}  // namespace

TEST_CASE("the game target falls back to RGBA8 when the GPU cannot make the float images, and the picture does not change") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    GlowScene s(Color{0.25f, 0.5f, 0.75f, 1}, 1.0f);
    s.bloom(0.2f);
    const Image reference = g.render(s.world);

    // A second renderer on the same device (it adopts the open context) with the failure injected: the float target is "not VALID".
    EnvGuard hook("FA_SCENE_FORMAT", "rgba16f_invalid");
    Renderer fallback;
    RendererDesc d;
    d.designWidth = 320;
    d.designHeight = 180;
    d.sampleCount = std::getenv("FA_TEST_SAMPLES") ? std::atoi(std::getenv("FA_TEST_SAMPLES")) : 1;
    d.headless = true;
    d.adoptContext = true;
    std::string error;
    REQUIRE_MESSAGE(fallback.init(d, g.gpu.environment(), &error), error);
    CHECK_FALSE(fallback.hdr_scene());  // reports the format really used
    fallback.set_target_size(200, 100);  // rebuilding the targets keeps working in the fallback format
    fallback.set_target_size(320, 180);
    fallback.begin_frame();
    fallback.render_world(s.world, 0.0f);
    fallback.end_frame();
    g.gpu.end_frame();
    Image img;
    REQUIRE_MESSAGE(fallback.capture(img, &error), error);
    REQUIRE(img.width == reference.width);
    REQUIRE(img.height == reference.height);
    // The scene stays below white everywhere, so an 8-bit target draws what a float one does, within rounding.
    double worst = 0;
    for (int y = 0; y < img.height; y += 3)
        for (int x = 0; x < img.width; x += 3) {
            const Color a = img.pixel(x, y), b = reference.pixel(x, y);
            worst = std::max({worst, double(std::fabs(a.r - b.r)), double(std::fabs(a.g - b.g)), double(std::fabs(a.b - b.b))});
        }
    CHECK(worst < 0.03);
    fallback.shutdown();
}

TEST_CASE("bloom does not spread a NaN or infinite source over the glow of its neighbour") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    // Two lamps side by side: the left one glows normally, the right one writes NaN (a custom material's pow() of a negative, a
    // 0/0 in a script). The reference is the same scene with a black right lamp. The bright pass must drop the NaN, otherwise
    // the blur carries it over the left lamp's halo and disc and those pixels come out wrong. Compared on the left half of the
    // picture, which holds the whole left lamp and its halo but not the right lamp's own surface.
    auto left_half = [&](Color right) {
        GlowScene s(Color{0.9f, 0.6f, 0.3f, 1}, 1.0f);
        s.world.get<Transform>(s.glow)->position = {-0.6f, 0, 0};
        Entity other = make(s.world, "other", {0.6f, 0, 0});
        auto& m = s.world.add<MeshRenderer>(other);
        m.mesh = "sphere";
        m.color = Color{0, 0, 0, 1};
        m.unlit = true;
        m.emissive = right;
        s.bloom(0.2f, 1.0f, 30.0f);
        const Image img = g.render(s.world);
        std::array<double, 3> sum{0, 0, 0};
        for (int y = 0; y < img.height; ++y)
            for (int x = 0; x < img.width / 2; ++x) {
                const Color c = img.pixel(x, y);
                sum[0] += c.r;
                sum[1] += c.g;
                sum[2] += c.b;
            }
        return sum;
    };
    const float nan = std::nanf("");
    const auto clean = left_half(Color{0, 0, 0, 1});
    const auto dirty = left_half(Color{nan, nan, nan, 1});
    // An infinite red channel must not light the neighbour more than the brightest finite one (1.0, white) does: in the float
    // target the bright pass drops it, in an 8-bit target it is clamped to 1 on the way in. Not with MSAA: the resolve averages
    // the Inf at the lamp's edge with its empty samples into a large finite number, which is light to the bright pass.
    const bool msaa = std::getenv("FA_TEST_SAMPLES") && std::atoi(std::getenv("FA_TEST_SAMPLES")) > 1;
    const auto inf = left_half(Color{INFINITY, 0.5f, 0.5f, 1});
    const auto one = left_half(Color{1.0f, 0.5f, 0.5f, 1});
    INFO("hdr_scene=" << g.renderer.hdr_scene() << " clean=" << clean[0] << "," << clean[1] << "," << clean[2] << " dirty=" << dirty[0]
                      << "," << dirty[1] << "," << dirty[2] << " inf=" << inf[0] << " one=" << one[0]);
    CHECK(clean[0] > 100.0);  // the left lamp does glow
    for (int c = 0; c < 3; ++c) {
        CHECK(dirty[c] == doctest::Approx(clean[c]).epsilon(0.01));
        if (!msaa) CHECK(inf[c] <= one[c] * 1.01);
    }
}
