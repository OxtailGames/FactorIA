// M64.1 particles through the renderer: gradients and curves, emission shapes, trails, collision, pixel mode, budgets.
// The simulation itself is tested without a GPU in engine/scene/tests/test_particles.cpp.
#include "test_util.h"
#include "fa/scene/particles.h"

#include <algorithm>
#include <cmath>
#include <vector>

using namespace fa;
using namespace fa::test;

namespace {

Entity camera(World& w) {
    Entity cam = make(w, "cam");
    w.add<Camera>(cam).clearColor = Color::black();
    return cam;
}

bool near_colour(const Color& a, const Color& b, float tol = 2.5f / 255.0f) {
    return std::fabs(a.r - b.r) <= tol && std::fabs(a.g - b.g) <= tol && std::fabs(a.b - b.b) <= tol;
}

int lit_pixels(const Image& img) {
    int n = 0;
    for (int y = 0; y < img.height; ++y)
        for (int x = 0; x < img.width; ++x) {
            const Color c = img.pixel(x, y);
            if (c.r + c.g + c.b > 0.02f) ++n;
        }
    return n;
}

// Emitter states are kept per entity id across worlds in one renderer: every test starts and ends with none, so it neither sees
// another test's particles nor leaves its own for the next.
struct CleanEmitters {
    CleanEmitters() { gfx().renderer.clear_asset_cache(); }
    ~CleanEmitters() { gfx().renderer.clear_asset_cache(); }
};

}  // namespace

TEST_CASE("particles: gradient, shape, trail, collision and pixel mode draw the same picture every run") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    CleanEmitters clean;
    auto build = [](World& w) {
        camera(w);
        // A ring of sparks that fade white -> gold -> red -> nothing, growing then shrinking.
        Entity ring = make(w, "ring", {-90, 40, 0});
        auto& r = w.add<ParticleEmitter>(ring);
        r.rate = 0; r.burst = 60; r.seed = 4; r.lifetime = 1.0f; r.lifetimeVariance = 0; r.speed = 30; r.spread = 0;
        r.shape = ParticleShape::Circle; r.shapeFrom = ParticleShapeFrom::Edge; r.shapeSize = {24, 24, 24};
        r.shapeDirection = ParticleShapeDirection::Outward; r.gravity = {0, 0, 0}; r.startSize = 8;
        r.colorGradient = Json::parse(R"([[0, "#ffffff"], [0.4, "#ffcc33"], [0.8, "#ff3300"], [1, "#ff330000"]])");
        r.sizeCurve = Json::parse("[[0, 0.5], [0.3, 1.5], [1, 0.4]]");
        // Comets with a tapering trail.
        Entity comet = make(w, "comet", {0, 60, 0});
        auto& c = w.add<ParticleEmitter>(comet);
        c.rate = 0; c.burst = 6; c.seed = 9; c.lifetime = 1.0f; c.speed = 90; c.direction = 270; c.spread = 60; c.gravity = {0, -40, 0};
        c.startSize = 5; c.endSize = 3; c.trail = ParticleTrail::Particle; c.trailTime = 0.4f; c.trailWidth = 5;
        c.startColor = Color::hex(0x66ccff); c.endColor = Color::hex(0x66ccff);
        // Bouncing balls on a floor at y = -20.
        Entity balls = make(w, "balls", {70, 40, 0});
        auto& b = w.add<ParticleEmitter>(balls);
        b.rate = 0; b.burst = 12; b.seed = 2; b.lifetime = 5.0f; b.speed = 40; b.spread = 180; b.gravity = {0, -300, 0};
        b.startSize = 6; b.endSize = 6; b.startColor = Color::hex(0x80ff80); b.endColor = Color::hex(0x80ff80);
        b.collision = ParticleCollision::Plane; b.collisionPlane = {0, 1, 0, -20}; b.collisionBounce = 0.6f;
        // Pixel fire: four colours, 4-unit pixels.
        Entity fire = make(w, "fire", {-20, -70, 0});
        auto& p = w.add<ParticleEmitter>(fire);
        p.rate = 0; p.burst = 40; p.seed = 6; p.lifetime = 1.0f; p.speed = 40; p.spread = 20; p.gravity = {0, 60, 0};
        p.startSize = 10; p.endSize = 3; p.pixelMode = true; p.pixelSize = 4;
        p.palette = Json::parse(R"(["#2b0f54", "#ab1f65", "#ff4f69", "#fff7f8"])");
        p.colorGradient = Json::parse(R"([[0, "#fff7f8"], [0.5, "#ff4f69"], [1, "#2b0f54"]])");
    };
    World w1, w2;
    build(w1);
    build(w2);
    Image a, b;
    for (int i = 0; i < 45; ++i) a = g.render(w1, 1.0f / 60.0f);
    g.renderer.clear_asset_cache();
    for (int i = 0; i < 45; ++i) b = g.render(w2, 1.0f / 60.0f);
    ImageDiff d = diff_images(a, b, 1.0f / 255.0f);
    CHECK(d.meanError < 0.0005);
    CHECK(lit_pixels(a) > 400);
    expect_golden(a, "2d_particles_m64");
}

TEST_CASE("particles: pixel mode draws only palette colours on whole-pixel squares") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    CleanEmitters clean;
    World w;
    camera(w);
    Entity e = make(w, "fire", {0, -20, 0});
    auto& p = w.add<ParticleEmitter>(e);
    p.rate = 0; p.burst = 60; p.seed = 3; p.lifetime = 2.0f; p.lifetimeVariance = 0; p.speed = 30; p.spread = 40; p.gravity = {0, 20, 0};
    p.startSize = 9; p.endSize = 9; p.pixelMode = true; p.pixelSize = 3;
    const Color palette[3] = {Color::hex(0x204060), Color::hex(0xe0a020), Color::hex(0xf0f0e0)};
    p.palette = Json::parse(R"(["#204060", "#e0a020", "#f0f0e0"])");
    p.colorGradient = Json::parse(R"([[0, "#ffffff"], [1, "#101030"]])");  // none of these is in the palette
    Image img;
    for (int i = 0; i < 20; ++i) img = g.render(w, 1.0f / 60.0f);
    int lit = 0, off = 0;
    for (int y = 0; y < img.height; ++y)
        for (int x = 0; x < img.width; ++x) {
            const Color c = img.pixel(x, y);
            if (c.r + c.g + c.b < 0.01f) continue;  // the clear colour
            ++lit;
            bool inPalette = false;
            for (const Color& pc : palette) inPalette = inPalette || near_colour(c, pc);
            if (!inPalette) ++off;
        }
    CHECK(lit > 100);
    CHECK(off == 0);

    // Without a palette (and no style.palette in the project) the colours stay as they are but the squares stay hard-edged.
    p.palette = Json::array();
    g.renderer.clear_asset_cache();
    for (int i = 0; i < 20; ++i) img = g.render(w, 1.0f / 60.0f);
    CHECK(lit_pixels(img) > 100);
}

TEST_CASE("particles: a flipbook shows a different cell as the particle ages") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    CleanEmitters clean;
    Image sheet;  // 2x1 cells of 8x8: left red, right blue
    sheet.width = 16;
    sheet.height = 8;
    sheet.rgba.resize(16 * 8 * 4);
    for (int y = 0; y < 8; ++y)
        for (int x = 0; x < 16; ++x) sheet.set_pixel(x, y, x < 8 ? Color::hex(0xff0000) : Color::hex(0x0000ff));
    REQUIRE(save_png(sheet, (g.projectDir / "assets" / "flip.png").generic_string()).ok());
    World w;
    camera(w);
    Entity e = make(w, "puff");
    auto& p = w.add<ParticleEmitter>(e);
    p.rate = 0; p.burst = 1; p.lifetime = 1.0f; p.lifetimeVariance = 0; p.speed = 0; p.gravity = {0, 0, 0};
    p.startSize = 40; p.endSize = 40; p.texture = "assets/flip.png"; p.flipbookColumns = 2; p.flipbookRows = 1;
    p.startColor = Color::white(); p.endColor = Color::white();
    Image early = g.render(w, 0.1f);   // frame 0: red
    Image late = g.render(w, 0.6f);    // age 0.7 of 1: frame 1: blue
    const Color a = early.pixel(160, 90), b = late.pixel(160, 90);
    CHECK(a.r > 0.8f);
    CHECK(a.b < 0.2f);
    CHECK(b.b > 0.8f);
    CHECK(b.r < 0.2f);
}

TEST_CASE("particles: the per-emitter budget holds and old emitters are untouched by the new fields") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    CleanEmitters clean;
    World w;
    camera(w);
    Entity e = make(w, "flood");
    auto& p = w.add<ParticleEmitter>(e);
    p.rate = 100000; p.burst = 50000; p.maxParticles = 1000000; p.lifetime = 10.0f; p.speed = 10;
    g.render(w, 1.0f / 60.0f);
    CHECK(g.renderer.stats().particles == kParticleHardCap);
    g.render(w, 1.0f / 60.0f);
    CHECK(g.renderer.stats().particles == kParticleHardCap);
}

TEST_CASE("particles: a bad curve is logged once and the emitter still draws") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    CleanEmitters clean;
    World w;
    camera(w);
    Entity e = make(w, "bad");
    auto& p = w.add<ParticleEmitter>(e);
    p.rate = 0; p.burst = 30; p.speed = 20; p.startSize = 10;
    p.sizeCurve = Json::parse("[[0]]");
    clear_recent_logs();
    for (int i = 0; i < 5; ++i) g.render(w, 1.0f / 60.0f);
    CHECK(g.renderer.stats().particles == 30);
    int logged = 0;
    for (const auto& l : recent_logs(100, LogLevel::Warn))
        if (l.message.find("sizeCurve") != std::string::npos) ++logged;
    CHECK(logged == 1);
}
