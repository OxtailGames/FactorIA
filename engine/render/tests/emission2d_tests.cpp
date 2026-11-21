// M74.2 emission and masks of the 2D renderer: Sprite/Tilemap emission (lit or not, in HDR so it feeds the bloom), light layers (the
// light buffer path with one buffer per distinct set of lights, and the per-pixel path), Light2D cookies, the rim light and the
// normal maps made from the sprite itself (docs/rendering/RENDERING_2D_EMISSION.md).
// Default camera: the 320x180 target shows world (x, y) at pixel (160 + x, 90 - y).
#include "test_util.h"

#include <algorithm>
#include <cmath>
#include <mutex>
#include <string>
#include <vector>

#include "fa/core/image_tools.h"
#include "fa/core/log.h"
#include "fa/scene/tilemap.h"
#include "light_layers.h"
#include "render_internal.h"
#include "renderer_test_access.h"

using namespace fa;
using namespace fa::test;

namespace {

bool near(const Color& a, const Color& b, float tol = 0.04f) {
    return std::fabs(a.r - b.r) <= tol && std::fabs(a.g - b.g) <= tol && std::fabs(a.b - b.b) <= tol;
}

void save(const Image& img, const char* path) { REQUIRE(save_png(img, path).ok()); }

Image solid(int w, int h, Color c) {
    Image img;
    img.width = w;
    img.height = h;
    img.rgba.resize(std::size_t(w) * std::size_t(h) * 4);
    for (int y = 0; y < h; ++y)
        for (int x = 0; x < w; ++x) img.set_pixel(x, y, c);
    return img;
}

// The warnings and errors logged while the object lives.
struct ProblemLog {
    struct Lines {
        std::mutex mu;
        std::vector<std::string> lines;
    };
    std::shared_ptr<Lines> shared = std::make_shared<Lines>();
    int id;
    ProblemLog()
        : id(add_log_sink([l = shared](const LogEntry& e) {
              if (e.level < LogLevel::Warn) return;
              std::lock_guard<std::mutex> lk(l->mu);
              l->lines.push_back(e.message);
          })) {}
    ~ProblemLog() { remove_log_sink(id); }
    ProblemLog(const ProblemLog&) = delete;
    ProblemLog& operator=(const ProblemLog&) = delete;
    int count(const std::string& needle) const {
        std::lock_guard<std::mutex> lk(shared->mu);
        return int(std::count_if(shared->lines.begin(), shared->lines.end(),
                                 [&](const std::string& x) { return x.find(needle) != std::string::npos; }));
    }
    int size() const {
        std::lock_guard<std::mutex> lk(shared->mu);
        return int(shared->lines.size());
    }
};

Entity camera_at(World& w, Vec3 pos = {0, 0, 0}) {
    Entity cam = make(w, "cam", pos);
    w.add<Camera>(cam).clearColor = Color::black();
    return cam;
}

void save_white() { save(solid(16, 16, Color::white()), "assets/white16.png"); }

Entity lit_sprite(World& w, Vec3 pos, Vec2 size, std::int32_t layers = 1) {
    Entity e = make(w, "lit", pos);
    auto& sp = w.add<Sprite>(e);
    sp.texture = "assets/white16.png";
    sp.size = size;
    sp.lit = true;
    sp.lightLayers = layers;
    return e;
}

Entity lamp_at(World& w, Vec3 pos, float radius, std::int32_t layers = -1, float intensity = 1.0f) {
    Entity e = make(w, "lamp", pos);
    auto& l = w.add<Light2D>(e);
    l.radius = radius;
    l.falloff = 1;
    l.intensity = intensity;
    l.lightLayers = layers;
    return e;
}

float red(const Image& img, int x, int y) { return img.pixel(x, y).r; }

// 32x32: its left half white, its right half black (a cookie that lets light through on its left side only).
void save_half_cookie(const char* path) {
    Image img = solid(32, 32, Color::black());
    for (int y = 0; y < 32; ++y)
        for (int x = 0; x < 16; ++x) img.set_pixel(x, y, Color::white());
    save(img, path);
}

}  // namespace

// ------------------------------------------------------------------------------------------------------- emission

TEST_CASE(
    "emission: a lit sprite glows with no light at all, an unlit one adds it to its colour, black emits nothing") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    save_white();
    World w;
    camera_at(w);
    w.settings().ambientLight = Color{0, 0, 0, 1};
    Entity lit = lit_sprite(w, {-60, 0, 0}, {40, 40});
    w.get<Sprite>(lit)->emissive = Color{1.0f, 0.5f, 0.0f, 1};
    Entity plain = make(w, "plain", {0, 0, 0});
    auto& ps = w.add<Sprite>(plain);
    ps.texture = "assets/white16.png";
    ps.size = {40, 40};
    ps.color = Color{0, 0, 0, 1};  // an unlit black sprite: only the emission is left
    ps.emissive = Color{0.2f, 0.6f, 1.0f, 1};
    Entity dark = lit_sprite(w, {60, 0, 0}, {40, 40});
    (void)dark;  // lit, no emission, no light
    Image img = g.render(w);
    CHECK(near(img.pixel(100, 90), Color{1.0f, 0.5f, 0.0f, 1}));
    CHECK(near(img.pixel(160, 90), Color{0.2f, 0.6f, 1.0f, 1}));
    CHECK(near(img.pixel(220, 90), Color{0, 0, 0, 1}));
    // the intensity scales it (clamped to 1 on the screen) and the sprite's alpha shapes it
    w.get<Sprite>(lit)->emissiveIntensity = 0.5f;
    img = g.render(w);
    CHECK(near(img.pixel(100, 90), Color{0.5f, 0.25f, 0.0f, 1}, 0.06f));
    w.get<Sprite>(lit)->color = Color{1, 1, 1, 0.0f};
    img = g.render(w);
    CHECK(near(img.pixel(100, 90), Color{0, 0, 0, 1}, 0.03f));
}

TEST_CASE(
    "emission: emissiveMap says where the sprite glows, a tilemap glows too, and it adds to what the lights give") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    save_white();
    save_half_cookie("assets/half_mask.png");  // white on the left half
    World w;
    camera_at(w);
    w.settings().ambientLight = Color{0.25f, 0.25f, 0.25f, 1};
    Entity s = lit_sprite(w, {-60, 40, 0}, {32, 32});
    auto& sp = *w.get<Sprite>(s);
    sp.emissive = Color{0, 1, 0, 1};
    sp.emissiveMap = "assets/half_mask.png";
    Entity map = make(w, "map", {0, -60, 0});
    auto& tm = w.add<Tilemap>(map);
    tm.tileset = "assets/white16.png";
    tm.lit = true;
    tm.tileSize = {16, 16};
    tm.emissive = Color{0, 0, 1, 1};
    set_tilemap_tiles(tm, Json::array({Json::array({0, 0})}));
    Image img = g.render(w);
    // left half of the sprite: ambient 0.25 white + green; right half: only the ambient
    CHECK(near(img.pixel(92, 50), Color{0.25f, 1.0f, 0.25f, 1}));
    CHECK(near(img.pixel(108, 50), Color{0.25f, 0.25f, 0.25f, 1}));
    // the tilemap (160..192 x, 150..166 y): its tiles glow blue over the ambient
    CHECK(near(img.pixel(168, 158), Color{0.25f, 0.25f, 1.0f, 1}));
    // a lamp lights the sprite and the glow stays on top of it
    lamp_at(w, {-60, 40, 0}, 80);
    img = g.render(w);
    CHECK(near(img.pixel(92, 50), Color{1.0f, 1.0f, 1.0f, 1}, 0.06f));
}

TEST_CASE("emission: a value over 1 feeds the bloom, a value of 1 on a plain sprite gives much less") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    save_white();
    auto halo = [&](float intensity) {
        World w;
        Entity cam = camera_at(w);
        set_bloom(w, cam, true, 0.7f, 1.2f, 14.0f);
        w.settings().ambientLight = Color{0, 0, 0, 1};
        Entity e = lit_sprite(w, {0, 0, 0}, {40, 20});
        w.get<Sprite>(e)->color = Color{0, 0, 0, 1};
        w.get<Sprite>(e)->emissive = Color{1, 1, 1, 1};
        w.get<Sprite>(e)->emissiveIntensity = intensity;
        return g.render(w);
    };
    const Image dim = halo(0.3f), one = halo(1.0f), hot = halo(6.0f);
    // the glow beside the rectangle (it covers x 140..179): 8 pixels to its right
    CHECK(red(dim, 188, 90) < 0.02f);  // below the bloom threshold: no halo
    CHECK(red(hot, 188, 90) > red(one, 188, 90) + 0.05f);
    CHECK(red(hot, 188, 90) > 0.15f);
    // the rectangle itself is clamped to white on the screen
    CHECK(red(hot, 160, 90) > 0.95f);
    CHECK(red(one, 160, 90) > 0.95f);
}

TEST_CASE("emission: golden - emissive sprites, tiles and a lamp in the dark, with bloom") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    save_white();
    World w;
    Entity cam = camera_at(w);
    set_bloom(w, cam, true, 0.8f, 1.0f, 12.0f);
    w.settings().ambientLight = Color{0.05f, 0.06f, 0.1f, 1};
    const Color colors[4] = {Color{1.0f, 0.2f, 0.4f, 1}, Color{0.2f, 1.0f, 0.5f, 1}, Color{0.3f, 0.5f, 1.0f, 1},
                             Color{1.0f, 0.8f, 0.2f, 1}};
    const float powers[4] = {0.4f, 1.0f, 3.0f, 8.0f};
    for (int i = 0; i < 4; ++i) {
        Entity e = lit_sprite(w, {-105.0f + 70.0f * float(i), 40, 0}, {36, 18});
        w.get<Sprite>(e)->color = Color{0.2f, 0.2f, 0.25f, 1};
        w.get<Sprite>(e)->emissive = colors[i];
        w.get<Sprite>(e)->emissiveIntensity = powers[i];
    }
    Entity map = make(w, "strip", {-112, -50, 0});
    auto& tm = w.add<Tilemap>(map);
    tm.tileset = "assets/white16.png";
    tm.lit = true;
    tm.tileSize = {16, 16};
    tm.emissive = Color{0.2f, 0.9f, 1.0f, 1};
    tm.emissiveIntensity = 2.5f;
    set_tilemap_tiles(tm, Json::array({Json::array({0, 0, 0, 0, 0, 0, 0})}));
    lamp_at(w, {0, -20, 0}, 90, -1, 0.6f);
    expect_golden(g.render(w), "2d_emission_bloom");
}

// -------------------------------------------------------------------------------------------------- light layers

TEST_CASE("light layers: a light lights a receiver only when their masks share a bit (buffer path)") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    save_white();
    World w;
    camera_at(w);
    w.settings().ambientLight = Color{0, 0, 0, 1};
    Entity a = lit_sprite(w, {-60, 0, 0}, {30, 30}, 1);
    Entity b = lit_sprite(w, {60, 0, 0}, {30, 30}, 2);
    lamp_at(w, {-60, 0, 0}, 45, 1);  // lights the receivers of bit 0 only
    lamp_at(w, {60, 0, 0}, 45, 2, 0.5f);
    Image img = g.render(w);
    CHECK(red(img, 100, 90) > 0.9f);
    CHECK(red(img, 220, 90) == doctest::Approx(0.5f).epsilon(0.05));
    // swap the receivers' masks: each sits under the other's lamp, which does not reach it
    w.get<Sprite>(a)->lightLayers = 2;
    w.get<Sprite>(b)->lightLayers = 1;
    img = g.render(w);
    CHECK(red(img, 100, 90) < 0.02f);
    CHECK(red(img, 220, 90) < 0.02f);
    // a receiver on both bits meets both lamps; mask 0 meets none
    w.get<Sprite>(a)->lightLayers = 3;
    w.get<Sprite>(b)->lightLayers = 0;
    img = g.render(w);
    CHECK(red(img, 100, 90) > 0.9f);
    CHECK(red(img, 220, 90) < 0.02f);
}

TEST_CASE("light layers: more distinct masks than buffers fall back to the per-pixel loop and still obey the rule, "
          "with one warning") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    save_white();
    World w;
    camera_at(w);
    w.settings().ambientLight = Color{0, 0, 0, 1};
    std::vector<Entity> sprites;
    for (int i = 0; i < 5; ++i) {  // five distinct masks, one more than the buffers a frame has
        const float x = -120.0f + 60.0f * float(i);
        sprites.push_back(lit_sprite(w, {x, 0, 0}, {30, 30}, 1 << i));
        lamp_at(w, {x, 0, 0}, 40, 1 << i, 1.0f);
    }
    ProblemLog log;
    Image img = g.render(w);
    for (int i = 0; i < 5; ++i) {
        CAPTURE(i);
        CHECK(red(img, 160 - 120 + 60 * i, 90) > 0.9f);
    }
    CHECK(log.count("lightLayers") == 1);
    img = g.render(w);
    CHECK(log.count("lightLayers") == 1);  // once
    // the sprite of the third lamp now listens to the second layer only: dark under its own lamp
    w.get<Sprite>(sprites[2])->lightLayers = 2;
    img = g.render(w);
    CHECK(red(img, 160, 90) < 0.02f);
    CHECK(red(img, 100, 90) > 0.9f);
    CHECK(red(img, 220, 90) > 0.9f);
}

TEST_CASE("light layers: the per-pixel path (a normal map) and the directional lights obey the masks too") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    save_white();
    save(solid(16, 16, Color{0.5f, 0.5f, 1.0f, 1}), "assets/flat_n.png");  // a flat normal map: lit like a flat sprite
    World w;
    camera_at(w);
    w.settings().ambientLight = Color{0, 0, 0, 1};
    Entity a = lit_sprite(w, {-60, 0, 0}, {30, 30}, 1);
    w.get<Sprite>(a)->normalMap = "assets/flat_n.png";
    Entity b = lit_sprite(w, {60, 0, 0}, {30, 30}, 2);
    w.get<Sprite>(b)->normalMap = "assets/flat_n.png";
    lamp_at(w, {-60, 0, 0}, 45, 1);
    lamp_at(w, {60, 0, 0}, 45, 1);
    Image img = g.render(w);
    CHECK(red(img, 100, 90) > 0.8f);
    CHECK(red(img, 220, 90) < 0.02f);  // the lamp is on layer 0, the sprite on layer 1
    Entity sun = make(w, "sun");
    auto& d = w.add<Light2D>(sun);
    d.type = Light2DType::Directional;
    d.direction = 270;
    d.elevation = 90;
    d.intensity = 0.4f;
    d.lightLayers = 2;
    img = g.render(w);
    CHECK(red(img, 220, 90) == doctest::Approx(0.4f).epsilon(0.1));  // the sun reaches b only
    CHECK(red(img, 100, 90) > 0.8f);
    CHECK(red(img, 100, 90) < 1.01f);
    CHECK(red(img, 40, 20) < 0.02f);  // and nothing else
}

TEST_CASE("light layers: Shape2D and Tilemap masks work like a sprite's") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    save_white();
    World w;
    camera_at(w);
    w.settings().ambientLight = Color{0, 0, 0, 1};
    Entity shape = make(w, "shape", {-60, 0, 0});
    auto& sh = w.add<Shape2D>(shape);
    sh.shape = ShapeType::Rectangle;
    sh.size = {30, 30};
    sh.lit = true;
    sh.lightLayers = 2;
    Entity map = make(w, "map", {32, 8, 0});
    auto& tm = w.add<Tilemap>(map);
    tm.tileset = "assets/white16.png";
    tm.lit = true;
    tm.tileSize = {16, 16};
    tm.lightLayers = 4;
    set_tilemap_tiles(tm, Json::array({Json::array({0, 0})}));
    lamp_at(w, {-60, 0, 0}, 45, 1);
    lamp_at(w, {48, 0, 0}, 45, 4);
    Image img = g.render(w);
    CHECK(red(img, 100, 90) < 0.02f);  // the shape listens to layer 1, the lamp is on 0
    CHECK(red(img, 208, 90) > 0.8f);   // the tilemap listens to layer 2: the second lamp
    w.get<Shape2D>(shape)->lightLayers = 1;
    img = g.render(w);
    CHECK(red(img, 100, 90) > 0.9f);
}

TEST_CASE("light layers: plan_light_layers shares a buffer between masks that reach the same lights") {
    using fa::render::Light2DData;
    using fa::render::LightLayerPlan;
    auto light = [](std::int32_t layers, float radius = 50.0f) {
        Light2DData l{};
        l.pos[3] = radius;
        l.layers = layers;
        return l;
    };
    // the default: every light on every layer, every receiver on layer 0 -> one buffer with every point light
    {
        std::vector<Light2DData> lights = {light(-1), light(-1), light(-1, -1.0f)};  // the last one is directional
        LightLayerPlan p = fa::render::plan_light_layers(lights, {1, 1, 1}, true);
        REQUIRE(p.buffers.size() == 1);
        CHECK(p.buffers[0] == std::vector<int>{0, 1});
        CHECK_FALSE(p.overflowed);
        CHECK(p.buffer_of(1) == 0);
    }
    // layers: masks 1 and 4 reach the same lights, so they share; mask 2 gets its own; mask 8 reaches nothing
    {
        std::vector<Light2DData> lights = {light(1 | 4), light(2), light(16)};
        LightLayerPlan p = fa::render::plan_light_layers(lights, {1, 2, 4, 8, 1}, true);
        REQUIRE(p.buffers.size() == 2);
        CHECK(p.buffer_of(1) == p.buffer_of(4));
        CHECK(p.buffer_of(1) != p.buffer_of(2));
        CHECK(p.buffer_of(8) == LightLayerPlan::kNoPoint);
        CHECK(p.masks.size() == 4);  // each distinct mask once
        CHECK_FALSE(p.overflowed);
    }
    // past the cap: the masks that find no buffer take the loop, the others keep theirs
    {
        std::vector<Light2DData> lights;
        std::vector<std::int32_t> masks;
        for (int i = 0; i < 6; ++i) {
            lights.push_back(light(1 << i));
            masks.push_back(1 << i);
        }
        LightLayerPlan p = fa::render::plan_light_layers(lights, masks, true, 4);
        CHECK(p.buffers.size() == 4);
        CHECK(p.overflowed);
        CHECK(p.buffer_of(1) == 0);
        CHECK(p.buffer_of(16) == LightLayerPlan::kLoop);
        CHECK(p.buffer_of(32) == LightLayerPlan::kLoop);
    }
    // no buffer path: the loop for everything
    {
        std::vector<Light2DData> lights = {light(-1)};
        LightLayerPlan p = fa::render::plan_light_layers(lights, {1, 2}, false);
        CHECK(p.buffers.empty());
        CHECK(p.buffer_of(2) == LightLayerPlan::kLoop);
        CHECK_FALSE(p.overflowed);
    }
    CHECK(fa::render::light_reaches(-1, 1));
    CHECK_FALSE(fa::render::light_reaches(2, 1));
    CHECK_FALSE(fa::render::light_reaches(-1, 0));
}

// ----------------------------------------------------------------------------------------------------- cookies

TEST_CASE(
    "cookies: the picture shapes the light in the light's own space, turns with cookieRotationDeg, several at once") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    save_white();
    save_half_cookie("assets/cookie_half.png");
    World w;
    camera_at(w);
    w.settings().ambientLight = Color{0, 0, 0, 1};
    lit_sprite(w, {0, 0, 0}, {300, 100});
    Entity a = lamp_at(w, {-100, 0, 0}, 40);
    w.get<Light2D>(a)->cookie = "assets/cookie_half.png";
    Entity b = lamp_at(w, {100, 0, 0}, 40);
    w.get<Light2D>(b)->cookie = "assets/cookie_half.png";
    w.get<Light2D>(b)->cookieRotationDeg = 180;
    Entity c = lamp_at(w, {0, 0, 0}, 40);  // no cookie: the plain disc
    Image img = g.render(w);
    // lamp a: its left half passes the light, its right half is dark (the same distance from the lamp on both sides)
    CHECK(red(img, 160 - 100 - 20, 90) > 0.4f);
    CHECK(red(img, 160 - 100 + 20, 90) < 0.03f);
    // lamp b is turned half a turn: the other way round
    CHECK(red(img, 160 + 100 - 20, 90) < 0.03f);
    CHECK(red(img, 160 + 100 + 20, 90) > 0.4f);
    // the lamp without a cookie shines to both sides
    CHECK(red(img, 160 - 20, 90) > 0.4f);
    CHECK(red(img, 160 + 20, 90) > 0.4f);
    (void)c;
    // cookieScale: a small white square in a black picture covers a tenth of the light's diameter ...
    Image dot = solid(32, 32, Color::black());
    for (int y = 12; y < 20; ++y)
        for (int x = 12; x < 20; ++x) dot.set_pixel(x, y, Color::white());
    save(dot, "assets/cookie_dot.png");
    w.get<Light2D>(a)->cookie = "assets/cookie_dot.png";
    img = g.render(w);
    CHECK(red(img, 160 - 100, 90) > 0.9f);        // under the lamp: inside the square
    CHECK(red(img, 160 - 100 + 20, 90) < 0.03f);  // 20 units out: black
    // ... and four times the scale makes the square four times as wide
    w.get<Light2D>(a)->cookieScale = 4.0f;
    img = g.render(w);
    CHECK(red(img, 160 - 100 + 20, 90) > 0.3f);
}

TEST_CASE(
    "cookies: a live cookie (a camera's render target) is copied every frame, a file cookie only when it changes") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    save_white();
    save_half_cookie("assets/cookie_half.png");
    World w;
    camera_at(w);
    w.settings().ambientLight = Color{0, 0, 0, 1};
    // The page: a 64 x 64 camera far away whose picture is a white block on its left half (black elsewhere).
    Entity pageCam = make(w, "page-cam", {1000, 0, 0});
    Camera& pc = w.add<Camera>(pageCam);
    pc.depth =
        -1;  // cameras render in ascending depth: the page is drawn before the main camera (depth 0) whose light copies it
    pc.renderTarget = "cookiePage";
    pc.renderTargetSize = Vec2{64.0f, 64.0f};
    pc.orthoSize = 32.0f;
    pc.clearColor = Color::black();
    Entity block = make(w, "block", {1000 - 16, 0, 0});
    auto& shp = w.add<Shape2D>(block);
    shp.size = Vec2{32.0f, 64.0f};
    shp.color = Color::white();
    lit_sprite(w, {0, 0, 0}, {300, 100});
    Entity lamp = lamp_at(w, {0, 0, 0}, 40);
    w.get<Light2D>(lamp)->cookie = "target:cookiePage";
    Image img = g.render(w);
    CHECK(red(img, 160 - 20, 90) > 0.4f);   // the white half passes the light
    CHECK(red(img, 160 + 20, 90) < 0.03f);  // the black half does not
    // The page changes under the same texture: the block moves to the right half. The atlas must show the new picture.
    w.get<Transform>(block)->position = Vec3{1000 + 16, 0, 0};
    img = g.render(w);
    CHECK(red(img, 160 - 20, 90) < 0.03f);
    CHECK(red(img, 160 + 20, 90) > 0.4f);
    // A frame with the same picture is still right (the copy keeps running, nothing is frozen on the first one).
    img = g.render(w);
    CHECK(red(img, 160 - 20, 90) < 0.03f);
    CHECK(red(img, 160 + 20, 90) > 0.4f);
    // Back to a file cookie: its copy is made again (the stamp of the live frames was dropped) and then kept.
    w.get<Light2D>(lamp)->cookie = "assets/cookie_half.png";
    img = g.render(w);
    CHECK(red(img, 160 - 20, 90) > 0.4f);
    CHECK(red(img, 160 + 20, 90) < 0.03f);
}

TEST_CASE("cookies: the per-pixel path (a normal map) applies the cookie too") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    save_white();
    save(solid(16, 16, Color{0.5f, 0.5f, 1.0f, 1}), "assets/flat_n.png");
    save_half_cookie("assets/cookie_half.png");
    World w;
    camera_at(w);
    w.settings().ambientLight = Color{0, 0, 0, 1};
    Entity s = lit_sprite(w, {0, 0, 0}, {200, 100});
    w.get<Sprite>(s)->normalMap = "assets/flat_n.png";
    Entity a = lamp_at(w, {0, 0, 0}, 50);
    w.get<Light2D>(a)->cookie = "assets/cookie_half.png";
    Image img = g.render(w);
    CHECK(red(img, 160 - 20, 90) > 0.4f);
    CHECK(red(img, 160 + 20, 90) < 0.03f);
    // the same lit sprite without the cookie is lit on both sides
    w.get<Light2D>(a)->cookie.clear();
    img = g.render(w);
    CHECK(red(img, 160 + 20, 90) > 0.4f);
}

TEST_CASE("cookies: a texture that is not there is one teaching error with a suggestion, the light still shines") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    save_white();
    save_half_cookie("assets/cookie_half.png");
    World w;
    camera_at(w);
    w.settings().ambientLight = Color{0, 0, 0, 1};
    lit_sprite(w, {0, 0, 0}, {200, 100});
    Entity a = lamp_at(w, {0, 0, 0}, 50);
    w.get<Light2D>(a)->cookie = "assets/cookie_haf.png";
    ProblemLog log;
    Image img = g.render(w);
    img = g.render(w);
    CHECK(log.count("cookie_haf.png") == 1);
    CHECK(log.count("assets/cookie_half.png") >= 1);  // the did-you-mean
    CHECK(red(img, 160 + 20, 90) > 0.4f);             // no cookie: the whole disc
    CHECK(red(img, 160 - 20, 90) > 0.4f);
}

TEST_CASE("cookies: assign_cookie_cells gives one cell per distinct picture and counts what does not fit") {
    using fa::render::Light2DData;
    std::vector<fa::render::TextureAsset> tex(fa::render::kMaxCookies2D + 3);
    std::vector<Light2DData> lights;
    for (std::size_t i = 0; i < tex.size(); ++i) {
        Light2DData l{};
        l.pos[3] = 40.0f;
        l.layers = -1;
        l.cookieTex = &tex[i];
        lights.push_back(l);
        lights.push_back(l);  // a second light with the same picture shares the cell
    }
    Light2DData plain{};
    plain.pos[3] = 40.0f;
    lights.push_back(plain);
    Light2DData sun{};
    sun.pos[3] = -1.0f;
    sun.cookieTex = &tex[0];  // a directional light has no cookie
    lights.push_back(sun);
    int dropped = 0;
    auto cells = fa::render::assign_cookie_cells(lights, &dropped);
    CHECK(int(cells.size()) == fa::render::kMaxCookies2D);
    CHECK(dropped == 3);
    CHECK(lights[0].cookieCell == 0);
    CHECK(lights[1].cookieCell == 0);
    CHECK(lights[2].cookieCell == 1);
    CHECK(lights[std::size_t(2 * fa::render::kMaxCookies2D)].cookieCell == -1);  // the first that did not fit
    CHECK(lights[lights.size() - 2].cookieCell == -1);
    CHECK(lights.back().cookieCell == -1);
    // the shader numbers: cell 5 of the 4x4 atlas, in both orientations of the render target
    Light2DData l = lights[10];  // the sixth distinct picture, cell 5
    CHECK(l.cookieCell == 5);
    l.cookieRot = 0.0f;
    l.cookieScale = 2.0f;
    auto d = fa::render::cookie_shader_data(l, false);
    CHECK(d.cell[0] == doctest::Approx(0.25f));  // column 1
    CHECK(d.cell[1] == doctest::Approx(0.25f));  // row 1
    CHECK(d.cell[2] == doctest::Approx(0.25f));
    CHECK(d.xf[2] == doctest::Approx(1.0f / (2.0f * 40.0f * 2.0f)));
    auto f = fa::render::cookie_shader_data(l, true);
    CHECK(f.cell[1] == doctest::Approx(0.75f));
    CHECK(f.cell[2] == doctest::Approx(-0.25f));
    CHECK(fa::render::cookie_shader_data(lights.back(), false).xf[2] == 0.0f);
}

TEST_CASE("cookies: golden - window panes and a ring of light on a floor") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    save(solid(16, 16, Color::hex(0xb0a090)), "assets/floor16.png");
    Image panes = solid(64, 64, Color::black());  // a window: four panes with a cross of frame between them
    for (int y = 0; y < 64; ++y)
        for (int x = 0; x < 64; ++x)
            if (std::abs(x - 32) > 3 && std::abs(y - 32) > 3 && std::abs(x - 32) < 28 && std::abs(y - 32) < 28)
                panes.set_pixel(x, y, Color::white());
    save(panes, "assets/cookie_panes.png");
    Image ring = solid(64, 64, Color::black());
    for (int y = 0; y < 64; ++y)
        for (int x = 0; x < 64; ++x) {
            const float r = std::hypot(float(x) + 0.5f - 32.0f, float(y) + 0.5f - 32.0f);
            if (r > 18.0f && r < 28.0f) ring.set_pixel(x, y, Color::white());
        }
    save(ring, "assets/cookie_ring.png");
    World w;
    camera_at(w);
    w.settings().ambientLight = Color{0.06f, 0.06f, 0.1f, 1};
    Entity floor = make(w, "floor", {0, 0, 0});
    auto& sp = w.add<Sprite>(floor);
    sp.texture = "assets/floor16.png";
    sp.size = {320, 180};
    sp.lit = true;
    Entity a = lamp_at(w, {-75, 0, 0}, 75, -1, 1.2f);
    w.get<Light2D>(a)->cookie = "assets/cookie_panes.png";
    w.get<Light2D>(a)->cookieRotationDeg = 20;
    w.get<Light2D>(a)->color = Color{1.0f, 0.9f, 0.7f, 1};
    Entity b = lamp_at(w, {80, 5, 0}, 70, -1, 1.2f);
    w.get<Light2D>(b)->cookie = "assets/cookie_ring.png";
    w.get<Light2D>(b)->color = Color{0.6f, 0.8f, 1.0f, 1};
    expect_golden(g.render(w), "2d_cookie");
}

// ----------------------------------------------------------------------------------------------------- rim light

namespace {

// 48x48, an opaque white 32x32 square in the middle of a transparent picture (the rim reads the alpha, so it needs the margin).
void save_square(const char* path) {
    Image img = solid(48, 48, Color{1, 1, 1, 0});
    for (int y = 8; y < 40; ++y)
        for (int x = 8; x < 40; ++x) img.set_pixel(x, y, Color::white());
    save(img, path);
}

}  // namespace

TEST_CASE("rim light: the edge that faces a light glows in rimColor, the far edge and the unlit scene do not") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    save_square("assets/square48.png");
    World w;
    camera_at(w);
    w.settings().ambientLight = Color{0, 0, 0, 1};
    Entity e = make(w, "sq", {0, 0, 0});
    auto& sp = w.add<Sprite>(e);
    sp.texture = "assets/square48.png";
    sp.size = {48, 48};
    sp.lit = true;
    sp.color = Color{0.3f, 0.3f, 0.3f, 1};
    sp.rimColor = Color{1, 0, 0, 1};
    sp.rimIntensity = 2.0f;
    sp.rimWidth = 0.15f;
    Entity lamp = lamp_at(w, {-60, 0, 0}, 200);
    // the square covers x 144..175 (inner edge pixels 145 and 174)
    Image img = g.render(w);
    const Color left = img.pixel(145, 90), right = img.pixel(174, 90), mid = img.pixel(160, 90);
    CHECK(left.r - left.g > 0.15f);    // the edge towards the lamp is red
    CHECK(right.r - right.g < 0.03f);  // the one away from it is plain grey
    CHECK(mid.r - mid.g < 0.03f);
    // without a lamp there is nothing to rim
    w.get<Light2D>(lamp)->intensity = 0.0f;
    img = g.render(w);
    CHECK(img.pixel(145, 90).r < 0.05f);
    // rimIntensity 0 is the plain sprite again
    w.get<Light2D>(lamp)->intensity = 1.0f;
    w.get<Sprite>(e)->rimIntensity = 0.0f;
    img = g.render(w);
    CHECK(img.pixel(145, 90).r - img.pixel(145, 90).g < 0.03f);
    // the lamp on the other side moves the rim to the other edge
    w.get<Sprite>(e)->rimIntensity = 2.0f;
    w.get<Transform>(lamp)->position = {60, 0, 0};
    img = g.render(w);
    CHECK(img.pixel(174, 90).r - img.pixel(174, 90).g > 0.15f);
    CHECK(img.pixel(145, 90).r - img.pixel(145, 90).g < 0.03f);
}

// ------------------------------------------------------------------------------------------ generated normals

TEST_CASE("generated normals: normalFrom sprite and height draw exactly what the same map from a file draws") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    save_square("assets/square48.png");
    Image grey = solid(48, 48, Color::black());
    for (int y = 0; y < 48; ++y)
        for (int x = 0; x < 48; ++x) {
            const float v = 0.5f + 0.5f * std::sin(float(x) * 0.3f) * std::cos(float(y) * 0.25f);
            grey.set_pixel(x, y, Color{v, v, v, 1});
        }
    save(grey, "assets/height48.png");
    // the file the old way: the kernel of the engine's core applied to the same pictures, saved as the normal map
    auto square = load_image("assets/square48.png");
    REQUIRE(square.ok());
    save(normal_map_from_sprite(*square, 1.5), "assets/square48_n.png");
    auto height = load_image("assets/height48.png");
    REQUIRE(height.ok());
    save(normal_map_from_height_image(*height, 2.0), "assets/height48_n.png");

    auto draw = [&](SpriteNormalFrom from, const char* normalMap, const char* heightMap, float strength) {
        World w;
        camera_at(w);
        w.settings().ambientLight = Color{0.05f, 0.05f, 0.05f, 1};
        Entity e = make(w, "sq", {0, 0, 0});
        auto& sp = w.add<Sprite>(e);
        sp.texture = "assets/square48.png";
        sp.size = {48, 48};
        sp.lit = true;
        sp.pixelArt = false;
        sp.normalFrom = from;
        sp.normalMap = normalMap;
        sp.heightMap = heightMap;
        sp.normalStrength = strength;
        Entity lamp = lamp_at(w, {-30, 20, 0}, 160);
        w.get<Light2D>(lamp)->height = 30;
        return g.render(w);
    };
    const Image fromFile = draw(SpriteNormalFrom::File, "assets/square48_n.png", "", 1.0f);
    const Image fromSprite = draw(SpriteNormalFrom::Sprite, "", "", 1.5f);
    float worst = 0;
    for (int y = 0; y < 180; ++y)
        for (int x = 0; x < 320; ++x)
            worst = std::max(worst, std::fabs(fromFile.pixel(x, y).r - fromSprite.pixel(x, y).r));
    CHECK(worst < 0.01f);
    // and it is not the flat picture: the bevel is brighter on the side towards the lamp
    const Image flat = draw(SpriteNormalFrom::File, "", "", 1.0f);
    CHECK(red(fromSprite, 146, 90) > red(fromSprite, 173, 90) + 0.05f);
    CHECK(std::fabs(red(flat, 146, 90) - red(flat, 173, 90)) < red(fromSprite, 146, 90) - red(fromSprite, 173, 90));

    const Image heightFile = draw(SpriteNormalFrom::File, "assets/height48_n.png", "", 1.0f);
    const Image heightGen = draw(SpriteNormalFrom::Height, "", "assets/height48.png", 2.0f);
    worst = 0;
    for (int y = 0; y < 180; ++y)
        for (int x = 0; x < 320; ++x)
            worst = std::max(worst, std::fabs(heightFile.pixel(x, y).r - heightGen.pixel(x, y).r));
    CHECK(worst < 0.01f);
    // a heightMap that is not there: one error, the sprite is lit flat
    ProblemLog log;
    const Image missing = draw(SpriteNormalFrom::Height, "", "assets/nohere.png", 1.0f);
    draw(SpriteNormalFrom::Height, "", "assets/nohere.png", 1.0f);
    CHECK(log.count("nohere.png") >= 1);
    CHECK(red(missing, 160, 90) > 0.05f);
}

TEST_CASE(
    "generated normals: an animated strength keeps a bounded number of maps per picture, answered with the closest") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    save(solid(16, 16, Color::white()), "assets/gn_src.png");
    render::Assets assets(*render::renderer_gpu(g.renderer));
    const std::size_t before = assets.generated_normal_count();
    std::vector<render::TextureAsset*> made;
    for (int i = 0; i < 100; ++i) {
        render::TextureAsset* t = assets.generated_normal("assets/gn_src.png", false, 0.5f + float(i) * 0.1f);
        REQUIRE(t != nullptr);
        made.push_back(t);
    }
    CHECK(assets.generated_normal_count() - before == std::size_t(render::Assets::kMaxNormalVariants));
    // Past the bound a strength is answered with the closest one made: the 8 first (0.5 .. 1.2) are kept, so the large ones all get the last.
    CHECK(made[90] == made[99]);
    assets.clear();
}
