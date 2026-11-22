// M74.4: the picture drawn so far in the camera (fa_scene_color() in sprite materials), Water2D and DistortionZone2D
// (docs/rendering/RENDERING_2D_WATER.md). The fixtures sprite_scene and sprite_pool are in tests/data/materials; their twins are
// committed (tools/common/tests/shaders_fixtures_test.cpp keeps them current).
#include "fa/core/engine_version.h"
#include "test_util.h"

#include <algorithm>
#include <cmath>
#include <fstream>
#include <memory>
#include <mutex>
#include <string>
#include <vector>

#include "fa/core/json.h"
#include "render_internal.h"
#include "renderer_test_access.h"
#include "water2d.h"

using namespace fa;
using namespace fa::test;
using namespace fa::render;

namespace {

// The fixture materials are copied into the test project; every twin gets this build's engine version.
void install_materials() {
    namespace sfs = std::filesystem;
    const sfs::path src = sfs::path(FA_RENDER_DATA_DIR) / "materials";
    for (const auto& e : sfs::recursive_directory_iterator(src)) {
        if (!e.is_regular_file()) continue;
        std::ifstream in(e.path(), std::ios::binary);
        std::string bytes((std::istreambuf_iterator<char>(in)), std::istreambuf_iterator<char>());
        if (e.path().extension() == ".shader") {
            Json twin = Json::parse(bytes);
            twin["engine"] = FA_ENGINE_VERSION;
            bytes = twin.dump();
        }
        REQUIRE(fs::write_bytes(sfs::relative(e.path(), src).generic_string(), bytes.data(), bytes.size()).ok());
    }
}

struct MaterialScope {
    MaterialScope() {
        gfx().renderer.clear_asset_cache();
        install_materials();
    }
    ~MaterialScope() { gfx().renderer.clear_asset_cache(); }
};

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
    bool empty() const {
        std::lock_guard<std::mutex> lk(shared->mu);
        return shared->lines.empty();
    }
};

void camera2d(World& w) {
    Entity cam = make(w, "cam");
    w.add<Camera>(cam).clearColor = Color::black();
}

Entity block(World& w, Vec3 p, Vec2 size, Color c, int layer = 0, const char* material = "") {
    Entity e = make(w, "block", p);
    auto& s = w.add<Sprite>(e);
    s.size = size;
    s.color = c;
    s.layer = layer;
    s.material = material;
    return e;
}

Entity water(World& w, Vec3 p, Vec2 size) {
    Entity e = make(w, "water", p);
    Water2D& a = w.add<Water2D>(e);
    a.size = size;
    a.tint = Color{0, 0, 0, 0};
    a.reflection = 0.0f;
    a.refraction = 0.0f;
    a.waveAmplitude = 0.0f;
    a.waveSpeed = 0.0f;
    return e;
}

constexpr float kTol = 0.05f;

void near(const Color& got, float r, float g, float b, float tol = kTol) {
    CHECK(std::fabs(got.r - r) <= tol);
    CHECK(std::fabs(got.g - g) <= tol);
    CHECK(std::fabs(got.b - b) <= tol);
}

constexpr const char* kScene = "materials/sprite_scene.material.json";
constexpr const char* kPool = "materials/sprite_pool.material.json";

// The 320x180 target of the test renderer shows the world 1 unit per pixel, y up: world (x, y) is at the pixel (160 + x, 90 - y).
int px(float x) { return int(std::lround(160.0f + x)); }
int py(float y) { return int(std::lround(90.0f - y)); }

QuadBatch reader() {
    QuadBatch b;
    b.effect = 1;
    return b;
}
QuadBatch plain_batch() { return QuadBatch{}; }

}  // namespace

TEST_CASE("water2d: scene_map turns a world point into the screen uv the shaders read and the copy's position") {
    // A 320x180 camera rectangle that is the whole target: the world (-160..160, -90..90) is the screen.
    const Mat4 vp = Mat4::ortho(-160, 160, -90, 90, -1, 1, true);
    const SceneMap whole = scene_map(vp, 0, 0, 320, 180, 320, 180);
    auto uv_of = [](const SceneMap& m, float x, float y) {
        const float q[4] = {x, y, 0.0f, 1.0f};
        float r[3] = {0, 0, 0};
        for (int k = 0; k < 3; ++k)
            for (int c = 0; c < 4; ++c) r[k] += m.worldUv[k][c] * q[c];
        return Vec2{r[0] / r[2], r[1] / r[2]};
    };
    const Vec2 centre = uv_of(whole, 0, 0), topLeft = uv_of(whole, -160, 90), bottomRight = uv_of(whole, 160, -90);
    CHECK(centre.x == doctest::Approx(0.5f).epsilon(1e-4));
    CHECK(centre.y == doctest::Approx(0.5f).epsilon(1e-4));
    CHECK(topLeft.x == doctest::Approx(0.0f).epsilon(1e-4));
    CHECK(topLeft.y == doctest::Approx(0.0f).epsilon(1e-4));  // y runs DOWN: the top of the world is v = 0
    CHECK(bottomRight.x == doctest::Approx(1.0f).epsilon(1e-4));
    CHECK(bottomRight.y == doctest::Approx(1.0f).epsilon(1e-4));
    CHECK(whole.scene[0] == doctest::Approx(1.0f));
    CHECK(whole.scene[2] == doctest::Approx(0.0f));

    // The right half of the target (x = 160, w = 160) drawn with the camera that sees world x 0..160: the screen uv of world x = 0 is 0.5,
    // and the copy (which holds only that half) starts at the screen uv 0.5 and spans 0.5.
    const Mat4 half = Mat4::ortho(0, 160, -90, 90, -1, 1, true);
    const SceneMap right = scene_map(half, 160, 0, 160, 180, 320, 180);
    CHECK(uv_of(right, 0, 0).x == doctest::Approx(0.5f).epsilon(1e-4));
    CHECK(uv_of(right, 160, 0).x == doctest::Approx(1.0f).epsilon(1e-4));
    CHECK(right.scene[0] == doctest::Approx(2.0f));   // screen uv * 2 ...
    CHECK(right.scene[2] == doctest::Approx(-1.0f));  // ... - 1: uv 0.5 is the copy's left edge, 1.0 its right edge
    // A degenerate rectangle never divides by zero.
    const SceneMap none = scene_map(vp, 0, 0, 0, 0, 0, 0);
    CHECK(std::isfinite(none.scene[0]));
    CHECK(std::isfinite(none.worldUv[2][3]));
}

TEST_CASE("water2d: the copies are planned by runs of reading batches, at most kMaxSceneCopies of them") {
    std::vector<QuadBatch> none = {plain_batch(), plain_batch()};
    std::vector<std::uint32_t> at;
    CHECK(count_scene_readers(none) == 0);
    CHECK(plan_scene_copies(none, at) == 0);
    CHECK(at.empty());

    // reader reader plain reader: two runs; the first run's two batches share one copy.
    std::vector<QuadBatch> mixed = {plain_batch(), reader(), reader(), plain_batch(), reader()};
    CHECK(count_scene_readers(mixed) == 3);
    CHECK(plan_scene_copies(mixed, at) == 2);
    REQUIRE(at.size() == 2);
    CHECK(at[0] == 1);
    CHECK(at[1] == 4);

    // More runs than the cap: the first kMaxSceneCopies are planned, the count says how many there are.
    std::vector<QuadBatch> many;
    for (int i = 0; i < 3 * kMaxSceneCopies; ++i) {
        many.push_back(reader());
        many.push_back(plain_batch());
    }
    at.clear();
    CHECK(plan_scene_copies(many, at) == 3 * kMaxSceneCopies);
    CHECK(int(at.size()) == kMaxSceneCopies);
}

TEST_CASE("water2d: a frame without a reader makes no copy and draws as before") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    MaterialScope scope;
    World w;
    camera2d(w);
    block(w, {0, 0, 0}, {80, 40}, Color{1, 0, 0, 1});
    block(w, {50, 20, 0}, {80, 40}, Color{0, 1, 0, 1}, 1);
    g.render(w);
    CHECK(g.renderer.stats().sceneCopies == 0);
    CHECK(g.renderer.stats().drawCalls >= 1);
}

TEST_CASE("water2d: a sprite material that calls fa_scene_color reads the picture drawn before it, shifted as asked") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    MaterialScope scope;
    ProblemLog log;
    World w;
    camera2d(w);
    // The background: red left of world x = 30, green right of it, blue in the top half and yellow in the bottom half of a strip on the left.
    block(w, {-65, 0, 0}, {190, 160}, Color{1, 0, 0, 1}, 0);
    block(w, {65, 0, 0}, {70, 160}, Color{0, 1, 0, 1}, 0);
    block(w, {-130, 40, 0}, {40, 20}, Color{0, 0, 1, 1}, 1);
    block(w, {-130, -40, 0}, {40, 20}, Color{1, 1, 0, 1}, 1);
    // dx = 0.25 of 320 px = 80 px: the material reads 80 px to the right of each of its pixels.
    Entity m = block(w, {-20, 0, 0}, {40, 40}, Color{0.8f, 0.7f, 0.9f, 1}, 5, kScene);
    w.get<Sprite>(m)->materialParams = Json::object({{"dx", 0.25}});
    // dy = 0.25 of 180 px = 45 px: the material reads 45 px BELOW each of its pixels (screen v runs down on every backend).
    Entity v = block(w, {-130, 0, 0}, {40, 20}, Color{0.8f, 0.7f, 0.9f, 1}, 5, kScene);
    w.get<Sprite>(v)->materialParams = Json::object({{"dy", 0.25}});
    const Image img = g.render(w);
    CHECK(g.renderer.stats().sceneCopies == 1);  // both sprites read the same picture; they are one run
    // Pixel of the material at world (-20, 0) reads the picture at world (60, 0): green. Without the shift it would be red.
    near(img.pixel(px(-20), py(0)), 0.0f, 1.0f, 0.0f);
    // Next to the material the background is untouched.
    near(img.pixel(px(-50), py(0)), 1.0f, 0.0f, 0.0f);
    // The vertical sprite at world (-130, 0), 20 px high: its centre reads 45 px below, at world (-130, -45): the yellow block (y -50..-30).
    near(img.pixel(px(-130), py(0)), 1.0f, 1.0f, 0.0f);
    CHECK(log.empty());
}

TEST_CASE("water2d: runs of reading draws that are apart each get their own copy, and the cap is a count") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    MaterialScope scope;
    auto frame = [&](int runs) {
        World w;
        // The renderer is shared by the whole file and says the cap once per scene: this scene path is the one of this case alone, so
        // the case does not depend on which case ran before it.
        w.set_scene_path("scenes/water2d-scene-copy-cap.json");
        camera2d(w);
        block(w, {0, 0, 0}, {300, 160}, Color{1, 0, 0, 1}, -5);
        for (int i = 0; i < runs; ++i) {
            // A sprite that reads the picture, then a plain one between it and the next: a new run each time.
            Entity r = block(w, {-120.0f + 15.0f * float(i), 0, 0}, {10, 10}, Color{1, 1, 1, 1}, 2 * i, kScene);
            w.get<Sprite>(r)->materialParams = Json::object({{"amount", 0.0}});
            block(w, {-120.0f + 15.0f * float(i), 30, 0}, {10, 10}, Color{0, 0, 1, 1}, 2 * i + 1);
        }
        return g.render(w);
    };
    {
        ProblemLog log;
        frame(3);
        CHECK(g.renderer.stats().sceneCopies == 3);
        CHECK(log.empty());
    }
    {
        ProblemLog log;
        frame(kMaxSceneCopies + 4);
        CHECK(g.renderer.stats().sceneCopies == kMaxSceneCopies);
        CHECK(log.count("separate runs") == 1);
        frame(kMaxSceneCopies + 4);  // said once
        CHECK(log.count("separate runs") == 1);
    }
}

TEST_CASE("water2d: Water2D reflects what is above its surface and refracts what is below, and only what is drawn "
          "before it") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    MaterialScope scope;
    ProblemLog log;
    World w;
    camera2d(w);
    // Water 200 x 100 centred at the origin: the surface is at y = 50. A white block above it at y 70..90 (x -20..20), a red one under it.
    Entity pool = water(w, {0, 0, 0}, {200, 100});
    w.get<Water2D>(pool)->reflection = 1.0f;
    block(w, {0, 62, 0}, {40, 16}, Color{1, 1, 1, 1}, 0);
    block(w, {60, -10, 0}, {30, 30}, Color{1, 0, 0, 1}, 0);
    const Image img = g.render(w);
    CHECK(g.renderer.stats().sceneCopies == 1);
    // Above the surface: nothing of the water.
    near(img.pixel(px(0), py(62)), 1.0f, 1.0f, 1.0f);
    near(img.pixel(px(80), py(62)), 0.0f, 0.0f, 0.0f);
    // The mirror image of the block (y 54..70) about y = 50 is at y 30..46: a white patch in the water, a little dimmer than the block
    // (the water fades its mirror with the depth: 0.12 deep at y = 38), and none beside it.
    near(img.pixel(px(0), py(38)), 0.93f, 0.93f, 0.93f, 0.06f);
    near(img.pixel(px(-70), py(38)), 0.0f, 0.0f, 0.0f);
    // The red block under the surface is seen through it (no tint, no refraction); the water darkens what is deep (0.6 deep at y = -10: x 0.79).
    near(img.pixel(px(60), py(-10)), 0.79f, 0.0f, 0.0f, 0.04f);
    // Below the area nothing changed.
    near(img.pixel(px(0), py(-70)), 0.0f, 0.0f, 0.0f);
    CHECK(log.empty());
}

TEST_CASE("water2d: the tint, the layers and the clock") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    MaterialScope scope;
    auto frame = [&](float tintAlpha, float speed, int steps) {
        World w;
        camera2d(w);
        Entity pool = water(w, {0, 0, 0}, {200, 100});
        Water2D& a = *w.get<Water2D>(pool);
        a.tint = Color{0, 0, 1, tintAlpha};
        a.waveAmplitude = 4.0f;
        a.waveSpeed = speed;
        a.refraction = 6.0f;
        a.reflection = 0.0f;
        block(w, {0, -20, 0}, {160, 20}, Color{1, 0, 0, 1}, 0);  // seen through the water
        block(w, {0, -20, 0}, {20, 20}, Color{0, 1, 0, 1}, 20);  // above the water's layer: drawn over it
        for (int i = 0; i < steps; ++i) w.advance_clock(1.0 / 60.0);
        return g.render(w);
    };
    const Image clear = frame(0.0f, 0.0f, 0);
    const Image blue = frame(1.0f, 0.0f, 0);
    // A full tint hides what is below: the red band is gone and the water is blue (darkened by its depth), the green block on a higher layer
    // is not touched by the water in either.
    CHECK(clear.pixel(px(50), py(-20)).r > 0.5f);
    CHECK(blue.pixel(px(50), py(-20)).r < 0.1f);
    CHECK(blue.pixel(px(50), py(-20)).b > 0.4f);
    near(clear.pixel(px(0), py(-20)), 0.0f, 1.0f, 0.0f);
    near(blue.pixel(px(0), py(-20)), 0.0f, 1.0f, 0.0f);
    // The waves follow the engine clock: the same clock gives the same picture, a moved clock another one, and speed 0 freezes them.
    const Image a = frame(0.5f, 1.0f, 15);
    const Image b = frame(0.5f, 1.0f, 15);
    const Image c = frame(0.5f, 1.0f, 40);
    const Image still1 = frame(0.5f, 0.0f, 15);
    const Image still2 = frame(0.5f, 0.0f, 40);
    CHECK(diff_images(a, b, 1.0f / 255.0f).maxError <= 1.0 / 255.0);
    CHECK(diff_images(a, c, 2.0f / 255.0f).maxError > 2.0 / 255.0);
    CHECK(diff_images(still1, still2, 1.0f / 255.0f).maxError <= 1.0 / 255.0);
}

TEST_CASE("water2d: a hidden or empty water draws nothing and costs no copy") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    MaterialScope scope;
    World w;
    camera2d(w);
    block(w, {0, 0, 0}, {80, 40}, Color{1, 0, 0, 1});
    Entity hidden = water(w, {0, 0, 0}, {100, 50});
    w.set_active(hidden, false);
    Entity empty = water(w, {50, 0, 0}, {0, 0});
    (void)empty;
    g.render(w);
    CHECK(g.renderer.stats().sceneCopies == 0);
}

TEST_CASE("water2d: a Water2D or DistortionZone2D wholly outside the view makes no copy and no extra draw") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    MaterialScope scope;
    // The same scene with the area at `x`: far outside the 320 x 180 view (x = 1000), or in it (x = 0).
    auto frame = [&](bool zone, float x, int& drawCalls) {
        World w;
        camera2d(w);
        block(w, {0, 0, 0}, {80, 40}, Color{1, 0, 0, 1});
        if (zone) {
            Entity e = make(w, "haze", {x, 0, 0});
            w.add<DistortionZone2D>(e).size = {60, 40};
        } else {
            water(w, {x, 0, 0}, {100, 50});
        }
        g.render(w);
        drawCalls = g.renderer.stats().drawCalls;
        return g.renderer.stats().sceneCopies;
    };
    int bare = 0, outside = 0, inside = 0;
    {
        World w;
        camera2d(w);
        block(w, {0, 0, 0}, {80, 40}, Color{1, 0, 0, 1});
        g.render(w);
        bare = g.renderer.stats().drawCalls;
    }
    for (const bool zone : {false, true}) {
        CAPTURE(zone);
        CHECK(frame(zone, 1000.0f, outside) == 0);
        CHECK(outside == bare);  // nothing is drawn, so no split pass either
        CHECK(frame(zone, 0.0f, inside) == 1);
        CHECK(inside > bare);
        // Just past the edge of the view (x in -160..160): the area is 100 (water) or 60 (zone) wide, so half of that is its reach.
        const float half = zone ? 30.0f : 50.0f;
        CHECK(frame(zone, 160.0f + half + 2.0f, outside) == 0);
        CHECK(frame(zone, 160.0f + half - 2.0f, inside) == 1);
    }
}

TEST_CASE("water2d: Water2D.material receives the fields as params and replaces the built-in look") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    MaterialScope scope;
    ProblemLog log;
    World w;
    camera2d(w);
    block(w, {0, 0, 0}, {300, 160}, Color{0, 1, 0, 1}, -5);
    Entity pool = water(w, {0, 0, 0}, {100, 60});
    Water2D& a = *w.get<Water2D>(pool);
    a.material = kPool;
    a.tint = Color{1, 0, 0, 1};  // the material mixes the picture with `tint` by its alpha: a red pool
    a.refraction = 0.0f;
    const Image img = g.render(w);
    CHECK(g.renderer.stats().sceneCopies == 1);
    near(img.pixel(px(0), py(0)), 1.0f, 0.0f, 0.0f);  // inside: the tint of the component
    near(img.pixel(px(0), py(-10)), 1.0f, 0.0f, 0.0f);
    near(img.pixel(px(0), py(60)), 0.0f, 1.0f,
         0.0f);  // above the area (the surface is its top edge, y = 30): the background
    near(img.pixel(px(80), py(0)), 0.0f, 1.0f, 0.0f);
    // The fixture declares size, tint, reflection, refraction, waveAmplitude, waveLength, waveSpeed and strength; the ones a Water2D has
    // all arrived (no "unknown param" warning) and the material's own `strength` kept its default.
    CHECK(log.empty());
    CHECK(g.renderer.stats().materialFallbacks.empty());
}

TEST_CASE("water2d: DistortionZone2D ripples the picture inside its rectangle and leaves the rest alone") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    MaterialScope scope;
    auto frame = [&](float strength, bool zone) {
        World w;
        camera2d(w);
        // Vertical stripes 8 px wide.
        for (int i = -20; i < 20; ++i)
            block(w, {8.0f * float(i) + 4.0f, 0, 0}, {8, 170}, (i & 1) ? Color{1, 1, 1, 1} : Color{0, 0, 0, 1}, 0);
        if (zone) {
            Entity e = make(w, "haze", {0, 0, 0});
            DistortionZone2D& z = w.add<DistortionZone2D>(e);
            z.size = {120, 100};
            z.strength = strength;
        }
        return g.render(w);
    };
    const Image plain = frame(0.0f, false);
    const Image off = frame(0.0f, true);
    CHECK(g.renderer.stats().sceneCopies == 1);
    const Image on = frame(6.0f, true);
    // Strength 0 is the picture as it is (the copy is exact), 6 bends the stripes inside the zone and not outside.
    CHECK(diff_images(plain, off, 2.0f / 255.0f).maxError <= 2.0 / 255.0);
    int changedInside = 0, changedOutside = 0;
    for (int y = 0; y < plain.height; ++y)
        for (int x = 0; x < plain.width; ++x) {
            // The zone is 120 x 100 and has no border: its ripple fades out over the last 30 % towards the edge.
            const bool inside = std::abs(x - 160) < 56 && std::abs(y - 90) < 46;
            const bool outside = std::abs(x - 160) > 64 || std::abs(y - 90) > 54;
            const bool differs = std::fabs(plain.pixel(x, y).r - on.pixel(x, y).r) > 0.25f;
            if (differs && inside) ++changedInside;
            if (differs && outside) ++changedOutside;
        }
    CHECK(changedInside > 200);
    CHECK(changedOutside == 0);
}

TEST_CASE("water2d: golden image of a cellar pool with a lantern and a heat haze") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    MaterialScope scope;
    World w;
    camera2d(w);
    block(w, {0, 0, 0}, {320, 180}, Color{0.12f, 0.1f, 0.16f, 1}, -10);  // the wall
    block(w, {0, 30, 0}, {320, 6}, Color{0.35f, 0.25f, 0.2f, 1}, -9);    // a ledge
    for (int i = 0; i < 4; ++i)                                          // lanterns
        block(w, {-105.0f + 70.0f * float(i), 62, 0}, {10, 14}, Color{1.0f, 0.78f, 0.35f, 1}, 0);
    block(w, {-60, 20, 0}, {16, 30}, Color{0.2f, 0.45f, 0.25f, 1}, 0);  // a plant on the edge
    Entity pool = make(w, "pool", {0, -30, 0});
    Water2D& a = w.add<Water2D>(pool);
    a.size = {300, 56};
    a.tint = Color{0.1f, 0.35f, 0.5f, 0.45f};
    a.reflection = 0.7f;
    a.refraction = 3.0f;
    a.waveAmplitude = 1.5f;
    a.waveLength = 40.0f;
    block(w, {20, -30, 0}, {26, 12}, Color{0.8f, 0.3f, 0.2f, 1}, 0);  // a fish under the surface
    block(w, {75, -2, 0}, {18, 8}, Color{0.6f, 0.55f, 0.5f, 1}, 20);  // a log floating on it
    Entity haze = make(w, "haze", {110, 60, 0});
    DistortionZone2D& z = w.add<DistortionZone2D>(haze);
    z.size = {50, 60};
    z.strength = 3.0f;
    for (int i = 0; i < 30; ++i) w.advance_clock(1.0 / 60.0);
    const Image img = g.render(w);
    CHECK(g.renderer.stats().sceneCopies == 1);
    CHECK(expect_golden(img, "2d_water", 0.01).ok());
}

TEST_CASE("water2d: the supports rows of the features are drawn, not planned") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    const Json report = g.renderer.supports_report();
    for (const char* name : {"2dWater", "spriteSceneColor"}) {
        CAPTURE(name);
        bool found = false;
        for (const Json& f : report["features"]) {
            if (f["name"] != name) continue;
            found = true;
            CHECK(f["status"].dump().find("planned") == std::string::npos);
        }
        CHECK(found);
    }
}
