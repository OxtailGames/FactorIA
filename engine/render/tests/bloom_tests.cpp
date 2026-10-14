// Camera.bloom: glow around bright pixels, applied into the game target (so screenshots show it).
//
// Cost measurement: FA_BLOOM_BENCH=1 build/<dir>/engine/render/fa_test_render -tc="bloom cost*" prints the
// ms/frame bloom adds at 1280x720 (see the last test case).
#include "test_util.h"

#include <algorithm>
#include <chrono>
#include <cmath>
#include <cstdio>
#include <cstdlib>
#include <limits>
#include <vector>

using namespace fa;
using namespace fa::test;

namespace {

constexpr int kW = 320;
constexpr int kH = 180;
const Color kClear{0.02f, 0.02f, 0.04f, 1.0f};

// The additive rectangle covers pixels x 140..179, y 80..99 (40x20 centered on the 320x180 target).
bool in_rect(int x, int y) { return x >= 140 && x < 180 && y >= 80 && y < 100; }

bool is_lit(const Color& c) {
    float over = std::max({c.r - kClear.r, c.g - kClear.g, c.b - kClear.b});
    return over > 3.0f / 255.0f;
}

struct Scene2D {
    World world;
    Entity cam;
    Entity shape;

    explicit Scene2D(Color color = Color{1.0f, 0.3f, 0.9f, 1.0f}) {
        cam = make(world, "cam");
        world.add<Camera>(cam).clearColor = kClear;
        shape = make(world, "neon", {0, 0, 0});
        auto& s = world.add<Shape2D>(shape);
        s.shape = ShapeType::Rectangle;
        s.size = {40, 20};
        s.color = color;
        s.blend = BlendMode::Additive;
    }
    Camera& camera() { return *world.get<Camera>(cam); }
    void bloom(bool on, float threshold = 0.5f, float intensity = 1.0f, float radius = 12.0f) {
        Camera& c = camera();
        c.bloom = on;
        c.bloomThreshold = threshold;
        c.bloomIntensity = intensity;
        c.bloomRadius = radius;
    }
};

int lit_outside_rect(const Image& img) {
    int n = 0;
    for (int y = 0; y < img.height; ++y)
        for (int x = 0; x < img.width; ++x)
            if (!in_rect(x, y) && is_lit(img.pixel(x, y))) ++n;
    return n;
}

// Largest distance (in pixels, along the row through the rectangle's center) at which a lit pixel is found.
int glow_reach_right(const Image& img) {
    int reach = 0;
    for (int x = 180; x < img.width; ++x)
        if (is_lit(img.pixel(x, 90))) reach = x - 179;
    return reach;
}

float max_channel(const Color& c) { return std::max({c.r, c.g, c.b}); }

}  // namespace

TEST_CASE("bloom: a bright additive shape glows outside its rectangle only when enabled") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    REQUIRE(g.renderer.target_width() == kW);
    Scene2D s;

    s.bloom(false);
    Image off = g.render(s.world);
    CHECK(lit_outside_rect(off) == 0);
    CHECK(max_channel(off.pixel(160, 90)) > 0.95f);  // the rectangle itself is bright

    s.bloom(true);
    Image on = g.render(s.world);
    INFO("lit pixels outside the rectangle with bloom on: " << lit_outside_rect(on));
    CHECK(lit_outside_rect(on) > 300);

    // The glow hugs the rectangle on every side and fades with distance ...
    Color nearLeft = on.pixel(136, 90), farLeft = on.pixel(120, 90);
    CHECK(is_lit(nearLeft));
    CHECK(max_channel(nearLeft) > max_channel(farLeft));
    CHECK(is_lit(on.pixel(160, 77)));   // above
    CHECK(is_lit(on.pixel(160, 103)));  // below
    // ... keeps the hue (magenta-ish: red and blue dominate green) ...
    Color halo = on.pixel(136, 90);
    CHECK(halo.r > halo.g);
    CHECK(halo.b > halo.g);
    // ... never reaches the far corners, and only ADDS light (the rectangle is already saturated).
    CHECK_FALSE(is_lit(on.pixel(2, 2)));
    CHECK_FALSE(is_lit(on.pixel(kW - 3, kH - 3)));
    for (int y = 0; y < kH; ++y)
        for (int x = 0; x < kW; ++x) {
            Color a = off.pixel(x, y), b = on.pixel(x, y);
            REQUIRE(b.r >= a.r - 1e-4f);
            REQUIRE(b.g >= a.g - 1e-4f);
            REQUIRE(b.b >= a.b - 1e-4f);
        }
    // Alpha is untouched, so screenshots stay opaque.
    for (int y = 0; y < kH; y += 7)
        for (int x = 0; x < kW; x += 7) CHECK(on.pixel(x, y).a == doctest::Approx(1.0f).epsilon(0.01));
    CHECK(g.renderer.stats().drawCalls > 0);
}

TEST_CASE("bloom: golden image of a small neon scene") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    World w;
    Entity cam = make(w, "cam");
    {
        auto& c = w.add<Camera>(cam);
        c.clearColor = kClear;
        c.bloom = true;
        c.bloomThreshold = 0.6f;
        c.bloomIntensity = 1.2f;
        c.bloomRadius = 14.0f;
    }
    auto neon = [&](Vec3 p, ShapeType type, Vec2 size, Color color, bool filled = true, float thickness = 2) {
        Entity e = make(w, "neon", p);
        auto& s = w.add<Shape2D>(e);
        s.shape = type; s.size = size; s.color = color; s.filled = filled; s.thickness = thickness;
        s.blend = BlendMode::Additive;
    };
    neon({-90, 40, 0}, ShapeType::Rectangle, {60, 30}, Color{1.0f, 0.1f, 0.8f, 1});
    neon({0, 40, 0}, ShapeType::Circle, {50, 50}, Color{0.1f, 0.9f, 1.0f, 1}, false, 4);
    neon({90, 40, 0}, ShapeType::Circle, {30, 30}, Color{1.0f, 0.9f, 0.2f, 1});
    neon({-60, -40, 0}, ShapeType::Line, {120, 30}, Color{0.3f, 1.0f, 0.3f, 1}, true, 2);
    neon({70, -45, 0}, ShapeType::Triangle, {50, 50}, Color{0.6f, 0.4f, 1.0f, 1}, false, 3);
    neon({-120, -70, 0}, ShapeType::Rectangle, {40, 14}, Color{0.3f, 0.2f, 0.25f, 1});  // too dim to glow
    expect_golden(g.render(w), "2d_bloom");
}

TEST_CASE("bloom: the glow sits on the shape, not mirrored (off-center shape)") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    Scene2D s;
    s.world.get<Transform>(s.shape)->position = {-100, 50, 0};  // pixels x 40..79, y 30..49 (top-left of the frame)
    s.bloom(true);
    Image img = g.render(s.world);
    CHECK(is_lit(img.pixel(60, 26)));                   // just above the shape
    CHECK(is_lit(img.pixel(60, 53)));                   // just below
    CHECK(is_lit(img.pixel(36, 40)));                   // just left
    CHECK(is_lit(img.pixel(83, 40)));                   // just right
    CHECK_FALSE(is_lit(img.pixel(60, kH - 1 - 26)));    // vertically mirrored position
    CHECK_FALSE(is_lit(img.pixel(kW - 1 - 60, 40)));    // horizontally mirrored position
    CHECK_FALSE(is_lit(img.pixel(kW - 1 - 60, kH - 1 - 40)));
}

TEST_CASE("bloom: off is pixel-identical, with or without tuned values, and leaves no residue") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    Scene2D s;
    Image reference = g.render(s.world);  // default camera: bloom never touched

    // bloom = false ignores the other three fields completely.
    s.bloom(false, 0.1f, 5.0f, 100.0f);
    Image tuned = g.render(s.world);
    CHECK(tuned.rgba == reference.rgba);

    // On, then off again: exactly the original picture (no state is carried between frames).
    s.bloom(true);
    Image on = g.render(s.world);
    CHECK(on.rgba != reference.rgba);
    s.bloom(false);
    Image offAgain = g.render(s.world);
    CHECK(offAgain.rgba == reference.rgba);

    // Enabled but with zero intensity adds nothing.
    s.bloom(true, 0.5f, 0.0f, 12.0f);
    CHECK(g.render(s.world).rgba == reference.rgba);
}

TEST_CASE("bloom: deterministic, two runs give the same pixels") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    for (float radius : {6.0f, 12.0f, 40.0f}) {
        INFO("radius " << radius);
        Scene2D a;
        a.bloom(true, 0.4f, 1.3f, radius);
        Image first = g.render(a.world);
        Image second = g.render(a.world);  // same renderer, next frame
        CHECK(first.rgba == second.rgba);
        g.render(a.world);                 // interleave something different
        a.bloom(false);
        g.render(a.world);
        a.bloom(true, 0.4f, 1.3f, radius);
        Image third = g.render(a.world);
        CHECK(first.rgba == third.rgba);
        Scene2D b;                          // a brand-new world with identical content
        b.bloom(true, 0.4f, 1.3f, radius);
        CHECK(first.rgba == g.render(b.world).rgba);
    }
}

TEST_CASE("bloom: radius controls how far the glow reaches, intensity how strong, threshold what glows") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    Scene2D s;

    // radius: 4 < 16 < 40 < 100 design pixels cover the internal resolutions (1/2 .. 1/32).
    s.bloom(false);
    g.render(s.world);
    const int baseDrawCalls = g.renderer.stats().drawCalls;
    int previousReach = 0;
    int previousPasses = 0;
    for (float radius : {4.0f, 16.0f, 40.0f, 100.0f}) {
        s.bloom(true, 0.5f, 1.0f, radius);
        Image img = g.render(s.world);
        const int passes = g.renderer.stats().drawCalls - baseDrawCalls;
        CHECK(passes >= 4);  // bright, blur H, blur V, composite
        CHECK(passes <= 7);  // plus at most three downsamples for the widest radii
        CHECK(passes >= previousPasses);
        previousPasses = passes;
        int reach = glow_reach_right(img);
        INFO("radius " << radius << " reaches " << reach << " px, lit outside = " << lit_outside_rect(img));
        CHECK(lit_outside_rect(img) > 50);
        CHECK(reach >= 2);
        CHECK(reach <= int(radius * 1.5f) + 12);  // does not leak far past the requested radius
        CHECK(reach > previousReach);             // grows with the radius
        previousReach = reach;
    }

    // intensity scales the added light.
    s.bloom(true, 0.5f, 0.5f, 16.0f);
    float weak = max_channel(g.render(s.world).pixel(136, 90));
    s.bloom(true, 0.5f, 1.5f, 16.0f);
    float strong = max_channel(g.render(s.world).pixel(136, 90));
    CHECK(strong > weak + 0.1f);

    // threshold: a dim shape (brightness 0.3) does not glow above a threshold of 0.8 but does at 0.1.
    Scene2D dim{Color{0.3f, 0.1f, 0.2f, 1.0f}};
    dim.bloom(true, 0.8f, 1.0f, 16.0f);
    CHECK(lit_outside_rect(g.render(dim.world)) == 0);
    dim.bloom(true, 0.1f, 1.0f, 16.0f);
    CHECK(lit_outside_rect(g.render(dim.world)) > 100);
}

TEST_CASE("bloom: thin bright lines keep their glow (the threshold is applied before downsampling)") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    World w;
    Entity cam = make(w, "cam");
    w.add<Camera>(cam).clearColor = kClear;
    Entity line = make(w, "line", {0, 0, 0});
    auto& s = w.add<Shape2D>(line);
    s.shape = ShapeType::Rectangle;
    s.size = {80, 2};  // two pixels high (rows 89 and 90); pixel-aligned so MSAA does not dim it
    s.color = Color::white();
    s.blend = BlendMode::Additive;
    auto& c = *w.get<Camera>(cam);
    c.bloom = true;
    c.bloomThreshold = 0.8f;
    c.bloomIntensity = 2.0f;
    c.bloomRadius = 12.0f;
    Image img = g.render(w);
    int lit = 0;
    for (int y = 0; y < kH; ++y)
        for (int x = 0; x < kW; ++x)
            if (y != 89 && y != 90 && is_lit(img.pixel(x, y))) ++lit;
    CHECK(lit > 100);
}

TEST_CASE("bloom: invalid values are clamped instead of breaking the frame") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    Scene2D s;
    s.bloom(true);

    const float nan = std::numeric_limits<float>::quiet_NaN();
    const float inf = std::numeric_limits<float>::infinity();
    struct Case { float threshold, intensity, radius; };
    for (Case c : {Case{nan, nan, nan}, Case{-5, -1, -3}, Case{5, 1e9f, 1e9f}, Case{0.5f, 1, 0}, Case{inf, inf, inf},
                   Case{0.5f, 1, -inf}}) {
        s.bloom(true, c.threshold, c.intensity, c.radius);
        Image img = g.render(s.world);
        CHECK(img.width == kW);
        CHECK(max_channel(img.pixel(160, 90)) > 0.9f);
    }
    // NaN fields fall back to the defaults, so the picture equals the one with the defaults written out.
    s.bloom(true, nan, nan, nan);
    Image nanImg = g.render(s.world);
    const Camera defaults;
    s.bloom(true, defaults.bloomThreshold, defaults.bloomIntensity, defaults.bloomRadius);
    CHECK(nanImg.rgba == g.render(s.world).rgba);
    // The documented defaults: off, and visibly glowing once switched on.
    CHECK_FALSE(defaults.bloom);
    s.camera() = Camera{};
    s.camera().clearColor = kClear;
    s.camera().bloom = true;
    CHECK(lit_outside_rect(g.render(s.world)) > 300);
}

TEST_CASE("bloom: works for 3D cameras") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    World w;
    w.settings().skyColor = Color{0.02f, 0.02f, 0.04f, 1};
    w.settings().horizonColor = Color{0.02f, 0.02f, 0.04f, 1};
    Entity cam = make(w, "cam", {0, 0, 5});
    auto& c = w.add<Camera>(cam);
    c.projection = Projection::Perspective;
    c.fov = 50;
    Entity cube = make(w, "cube", {0, 0, 0});
    auto& m = w.add<MeshRenderer>(cube);
    m.mesh = "cube";
    m.unlit = true;
    m.color = Color{1.0f, 0.4f, 0.1f, 1.0f};

    c.bloom = false;
    Image off = g.render(w);
    c.bloom = true;
    c.bloomThreshold = 0.5f;
    c.bloomIntensity = 1.0f;
    c.bloomRadius = 16.0f;
    Image on = g.render(w);

    int brightened = 0, outsideBefore = 0;
    for (int y = 0; y < kH; ++y)
        for (int x = 0; x < kW; ++x) {
            Color a = off.pixel(x, y), b = on.pixel(x, y);
            if (max_channel(a) < 0.1f) {
                ++outsideBefore;
                if (max_channel(b) > max_channel(a) + 3.0f / 255.0f) ++brightened;
            }
        }
    INFO("sky pixels brightened by the glow: " << brightened << " of " << outsideBefore);
    CHECK(brightened > 200);
    CHECK(on.rgba != off.rgba);
    // The corners of the frame are far from the cube and stay dark.
    CHECK(max_channel(on.pixel(2, 2)) < 0.1f);
    // Repeating the frame gives the same pixels.
    CHECK(g.render(w).rgba == on.rgba);
}

TEST_CASE("bloom: follows a resized game target") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    Scene2D s;
    s.bloom(true);
    Image small = g.render(s.world);
    g.renderer.set_target_size(400, 200);
    Image wide = g.render(s.world);
    CHECK(wide.width == 400);
    CHECK(wide.height == 200);
    CHECK(wide.pixel(224, 100).r > kClear.r + 0.05f);  // glow 4 px right of the rectangle (x 180..219) in the bigger target
    g.renderer.set_target_size(kW, kH);
    Image back = g.render(s.world);
    CHECK(back.rgba == small.rgba);
}

// ---- Camera.bloomScreenSpace -------------------------------------------------------------------------------------------
// The additive world rectangle of Scene2D glows at x >= ~120. The HUD lives in the top-left corner (x < 110), far
// enough from that glow to tell the two apart.

namespace {

constexpr int kHudX1 = 110;  // the HUD region is x < kHudX1 (and the world glow stays right of it)

// Bright screen-space items in the left part of the frame: a white rectangle [20,60) x [10,30), the text "HUD" and a diamond.
void add_hud(World& w) {
    Entity box = make(w, "hud-box", {20, 10, 0});
    auto& b = w.add<Shape2D>(box);
    b.shape = ShapeType::Rectangle;
    b.size = {40, 20};
    b.color = Color::white();
    b.space = RenderSpace::Screen;
    b.pivot = {0, 1};  // visual top-left corner at the position
    Entity label = make(w, "hud-text", {20, 45, 0});
    auto& t = w.add<Text>(label);
    t.text = "HUD";
    t.fontSize = 24;
    t.color = Color::white();
    t.space = RenderSpace::Screen;
    // A tilted diamond: its slanted edges are anti-aliased with MSAA, so the HUD pass must be multisampled too.
    Entity gem = make(w, "hud-gem", {40, 110, 0});
    w.get<Transform>(gem)->rotation = {0, 0, 20};
    auto& d = w.add<Shape2D>(gem);
    d.shape = ShapeType::Diamond;
    d.size = {30, 30};
    d.color = Color::white();
    d.space = RenderSpace::Screen;
}

// Pixels of the HUD region that differ from the same frame without bloom (the glow around the HUD).
int hud_glow_pixels(const Image& withBloom, const Image& withoutBloom) {
    int n = 0;
    for (int y = 0; y < withBloom.height; ++y)
        for (int x = 0; x < kHudX1; ++x) {
            Color a = withBloom.pixel(x, y), b = withoutBloom.pixel(x, y);
            if (std::max({a.r - b.r, a.g - b.g, a.b - b.b}) > 3.0f / 255.0f) ++n;
        }
    return n;
}

// Pixels right of the HUD region (outside the world rectangle) that the glow lit up.
int world_glow_pixels(const Image& img) {
    int n = 0;
    for (int y = 0; y < img.height; ++y)
        for (int x = kHudX1; x < img.width; ++x)
            if (!in_rect(x, y) && is_lit(img.pixel(x, y))) ++n;
    return n;
}

int max_abs_diff(const Image& a, const Image& b) {
    int worst = 0;
    for (std::size_t i = 0; i < a.rgba.size(); ++i) worst = std::max(worst, std::abs(int(a.rgba[i]) - int(b.rgba[i])));
    return worst;
}

}  // namespace

TEST_CASE("bloomScreenSpace: true (the default) makes screen-space items glow, false keeps the HUD crisp") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    CHECK(Camera{}.bloomScreenSpace);  // default = today's behaviour: the whole frame glows
    Scene2D s;
    add_hud(s.world);

    s.bloom(false);
    Image off = g.render(s.world);
    CHECK(hud_glow_pixels(off, off) == 0);
    CHECK(max_channel(off.pixel(40, 20)) > 0.95f);  // the HUD rectangle is bright
    CHECK(world_glow_pixels(off) == 0);

    s.bloom(true);
    s.camera().bloomScreenSpace = true;
    Image glowing = g.render(s.world);
    INFO("HUD glow pixels with bloomScreenSpace=true: " << hud_glow_pixels(glowing, off));
    CHECK(hud_glow_pixels(glowing, off) > 300);
    CHECK(world_glow_pixels(glowing) > 300);

    s.camera().bloomScreenSpace = false;
    Image crisp = g.render(s.world);
    CHECK(hud_glow_pixels(crisp, off) == 0);  // not one pixel around the HUD changed: it is exactly the frame without bloom
    CHECK(world_glow_pixels(crisp) > 300);    // the world still glows
    CHECK(max_channel(crisp.pixel(40, 20)) > 0.95f);
    for (int y = 0; y < kH; ++y)              // HUD region identical, including the text glyphs
        for (int x = 0; x < kHudX1; ++x) {
            REQUIRE(crisp.pixel(x, y).r == off.pixel(x, y).r);
            REQUIRE(crisp.pixel(x, y).g == off.pixel(x, y).g);
            REQUIRE(crisp.pixel(x, y).b == off.pixel(x, y).b);
        }

    // The world glow does not depend on the flag (MSAA rounds per sample: allow 2/255).
    int worst = 0;
    for (int y = 0; y < kH; ++y)
        for (int x = kHudX1; x < kW; ++x)
            for (int ch = 0; ch < 3; ++ch) {
                std::size_t i = (std::size_t(y) * kW + std::size_t(x)) * 4 + std::size_t(ch);
                worst = std::max(worst, std::abs(int(crisp.rgba[i]) - int(glowing.rgba[i])));
            }
    CHECK(worst <= 2);
}

TEST_CASE("bloomScreenSpace: the flag changes nothing without a HUD, with bloom off or with zero intensity") {
    Gfx& g = gfx();
    REQUIRE(g.ok);

    // No screen-space items: both settings give the same picture (MSAA rounds per sample: allow 2/255).
    Scene2D s;
    s.bloom(true);
    s.camera().bloomScreenSpace = true;
    Image a = g.render(s.world);
    s.camera().bloomScreenSpace = false;
    Image b = g.render(s.world);
    CHECK(max_abs_diff(a, b) <= 2);

    // Bloom off ignores the flag completely, HUD or not: pixel-identical.
    add_hud(s.world);
    s.bloom(false);
    s.camera().bloomScreenSpace = true;
    Image offTrue = g.render(s.world);
    s.camera().bloomScreenSpace = false;
    Image offFalse = g.render(s.world);
    CHECK(offTrue.rgba == offFalse.rgba);

    // Zero intensity adds nothing, so nothing is split either.
    s.bloom(true, 0.5f, 0.0f, 12.0f);
    Image zeroFalse = g.render(s.world);
    CHECK(zeroFalse.rgba == offTrue.rgba);
}

TEST_CASE("bloomScreenSpace=false: a translucent HUD panel is blended over the glow, not under it") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    Scene2D s;
    s.bloom(true);
    s.camera().bloomScreenSpace = false;
    Image plain = g.render(s.world);
    const Color glow = plain.pixel(136, 90);  // glow just left of the world rectangle
    REQUIRE(is_lit(glow));

    // Half-transparent black panel over the glow, drawn in the HUD pass: the glow itself is halved.
    Entity panel = make(s.world, "panel", {110, 60, 0});
    auto& p = s.world.add<Shape2D>(panel);
    p.shape = ShapeType::Rectangle;
    p.size = {90, 60};
    p.color = Color{0, 0, 0, 0.5f};
    p.space = RenderSpace::Screen;
    p.pivot = {0, 1};  // screen x 110..199, y 60..119 covers the rectangle and its glow
    Image covered = g.render(s.world);
    Color c = covered.pixel(136, 90);
    CHECK(c.r == doctest::Approx(0.5f * glow.r).epsilon(0.03));
    CHECK(c.b == doctest::Approx(0.5f * glow.b).epsilon(0.03));
    CHECK(c.r < glow.r - 0.02f);

    // Outside the panel the glow is untouched.
    CHECK(covered.pixel(100, 90).r == doctest::Approx(plain.pixel(100, 90).r).epsilon(0.01));
}

TEST_CASE("bloomScreenSpace=false: screen debug text stays crisp as well") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    Scene2D s;
    s.bloom(false);
    auto frame = [&] {
        g.renderer.debug().text({20, 60}, "DEBUG", Color::white(), 24.0f);
        return g.render(s.world);
    };
    Image off = frame();
    s.bloom(true);
    s.camera().bloomScreenSpace = true;
    Image glowing = frame();
    CHECK(hud_glow_pixels(glowing, off) > 200);
    s.camera().bloomScreenSpace = false;
    Image crisp = frame();
    CHECK(hud_glow_pixels(crisp, off) == 0);
    CHECK(world_glow_pixels(crisp) > 300);
}

TEST_CASE("bloomScreenSpace=false: a HUD item drawn over a bright world shape covers it") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    Scene2D s;
    s.bloom(true);
    s.camera().bloomScreenSpace = false;
    Entity cover = make(s.world, "cover", {150, 80, 0});
    auto& c = s.world.add<Shape2D>(cover);
    c.shape = ShapeType::Rectangle;
    c.size = {20, 20};
    c.color = Color{0, 0, 1, 1};
    c.space = RenderSpace::Screen;
    c.pivot = {0, 1};  // screen x 150..169, y 80..99 (over the middle of the world rectangle)
    Image img = g.render(s.world);
    Color inside = img.pixel(160, 90);
    CHECK(inside.b > 0.95f);
    CHECK(inside.r < 0.2f);
    CHECK(inside.g < 0.2f);
    // The uncovered part of the world rectangle is still bright.
    CHECK(img.pixel(145, 85).r > 0.9f);
}

TEST_CASE("bloomScreenSpace=false: screen-space particles stay crisp, world particles keep glowing") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    g.renderer.clear_asset_cache();
    Scene2D s;
    // A white additive dot in the HUD region: screen pixel (50, 90).
    Entity e = make(s.world, "hud-sparks", {50, 90, 0});
    auto& p = s.world.add<ParticleEmitter>(e);
    p.emitting = false; p.rate = 0; p.burst = 1; p.lifetime = 1000.0f; p.lifetimeVariance = 0; p.speed = 0;
    p.speedVariance = 0; p.spread = 0; p.gravity = {0, 0, 0}; p.startSize = p.endSize = 20;
    p.startColor = p.endColor = Color::white();
    p.blend = BlendMode::Additive;
    p.space = RenderSpace::Screen;

    s.bloom(false);
    Image off = g.render(s.world);
    CHECK(max_channel(off.pixel(50, 90)) > 0.95f);   // the dot
    CHECK(hud_glow_pixels(off, off) == 0);

    s.bloom(true);
    s.camera().bloomScreenSpace = true;
    Image glowing = g.render(s.world);
    INFO("glow pixels around the screen-space dot with bloomScreenSpace=true: " << hud_glow_pixels(glowing, off));
    CHECK(hud_glow_pixels(glowing, off) > 100);

    s.camera().bloomScreenSpace = false;
    Image crisp = g.render(s.world);
    CHECK(hud_glow_pixels(crisp, off) == 0);         // the HUD pass draws the dot after the bloom: no halo at all
    CHECK(max_channel(crisp.pixel(50, 90)) > 0.95f);
    CHECK(world_glow_pixels(crisp) > 300);           // the world rectangle still glows

    // The same emitter in world space (world (-110, 0) is the same pixel) is bloomed whatever the flag says.
    s.world.get<Transform>(e)->position = {-110, 0, 0};
    p.space = RenderSpace::World;
    g.renderer.clear_asset_cache();  // the particle born in screen space would stay in screen coordinates
    s.bloom(false);
    Image worldOff = g.render(s.world);
    s.bloom(true);
    Image worldGlow = g.render(s.world);
    CHECK(hud_glow_pixels(worldGlow, worldOff) > 100);
}

namespace {
bool bloom_bench_enabled() {
    const char* v = std::getenv("FA_BLOOM_BENCH");
    return v && std::string(v) == "1";
}
}  // namespace

// Prints how many ms/frame bloom adds at 1280x720. Wall-clock based, so it only runs on request
// (FA_BLOOM_BENCH=1) and never fails on a slow or busy machine. Each frame ends with a read-back so the
// software rasterizer has finished; the read-back cost is identical with bloom on and off and cancels out.
TEST_CASE("bloom cost at 1280x720 (FA_BLOOM_BENCH=1)" * doctest::skip(!bloom_bench_enabled())) {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    g.renderer.set_target_size(1280, 720);

    // A busy neon scene: 60 additive shapes plus a few that fill big areas.
    Scene2D s;
    for (int i = 0; i < 60; ++i) {
        Entity e = make(s.world, "n", {-600.0f + float(i % 20) * 60.0f, -250.0f + float(i / 20) * 200.0f, 0});
        auto& sh = s.world.add<Shape2D>(e);
        sh.shape = i % 3 == 0 ? ShapeType::Circle : ShapeType::Rectangle;
        sh.size = {40, 24};
        sh.color = Color{1.0f, 0.2f + 0.01f * float(i), 0.9f, 1.0f};
        sh.blend = BlendMode::Additive;
    }
    double lastCpuMs = 0.0;
    auto frame = [&](bool bloom, float radius) {
        s.bloom(bloom, 0.6f, 1.0f, radius);
        auto t0 = std::chrono::steady_clock::now();
        Image img = g.render(s.world);  // render + end_frame + capture (forces the GPU work to finish)
        auto t1 = std::chrono::steady_clock::now();
        (void)img;
        lastCpuMs = g.renderer.stats().cpuMs;  // CPU time spent recording the frame (no GPU wait)
        return std::chrono::duration<double, std::milli>(t1 - t0).count();
    };
    auto median = [](std::vector<double> v) {
        std::sort(v.begin(), v.end());
        return v[v.size() / 2];
    };

    std::printf("\nbloom cost at 1280x720 (%s):\n", g.gpu.description());
    for (int i = 0; i < 8; ++i) { frame(false, 16); frame(true, 16); }  // warm up (shader JIT, targets)
    for (float radius : {8.0f, 16.0f, 32.0f, 64.0f, 128.0f}) {
        std::vector<double> offMs, onMs, offCpu, onCpu;
        for (int i = 0; i < 40; ++i) {  // interleaved so drift and other processes hit both equally
            offMs.push_back(frame(false, radius));
            offCpu.push_back(lastCpuMs);
            onMs.push_back(frame(true, radius));
            onCpu.push_back(lastCpuMs);
        }
        double off = median(offMs), on = median(onMs);
        std::printf("  radius %5.0f: off %.2f ms, on %.2f ms, bloom adds %.2f ms/frame (CPU recording %.2f ms of it)\n", radius,
                    off, on, on - off, median(onCpu) - median(offCpu));
    }
    std::fflush(stdout);
    g.renderer.set_target_size(kW, kH);
}
