// M76-P1d: the motion vectors and the reactive mask of the 2D quads (sprites, shapes, particles; src/renderer_draw.cpp plan_quad_motion /
// quad_motion_pass / fill_quad_motion, shaders/quad_motion.glsl, quadlist.cpp). The velocity image and the mask are read back through
// RendererTestAccess (force_velocity: every camera asks for the velocity; the mask is drawn when the temporal antialiasing is on and a
// blended quad is reactive). The contract:
//   - a cutout (coverage >= one half) sprite writes its translation, rotation and scale: uvPrev - uvCurr from the unjittered matrices; what no
//     quad drew keeps the sentinel, and a camera that pans over a still sprite gives it the camera's motion;
//   - a blended or additive quad never overwrites a velocity: it is marked in the reactive mask instead (R8, the MAX of the values);
//   - the mask makes the temporal resolve trust the pixels the particle covers now: a bright particle that moves over a busy background has
//     its leading edge at once, not at a tenth of its brightness per frame;
//   - with the temporal antialiasing off nothing of this exists: no pass, and the picture is the same, bit for bit.
// Thresholds are far above half-float and rasterisation noise and far below what the cases draw, so they hold on llvmpipe and WARP too.
#include "test_util.h"

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <string>
#include <vector>

#include "fa/scene/jitter.h"
#include "fa/scene/particles.h"
#include "fa/scene/tilemap.h"

#include "frame_graph.h"
#include "postprocess.h"
#include "render_internal.h"
#include "renderer_test_access.h"

using namespace fa;
using namespace fa::test;
using namespace fa::render;

namespace {

constexpr int kW = 320, kH = 180;

struct Own {
    Gfx& g;
    Renderer r;
    bool ok = false;
    std::string error;
    explicit Own(Gfx& gx, bool velocity = true) : g(gx) {
        RendererDesc d;
        d.designWidth = kW;
        d.designHeight = kH;
        d.sampleCount = 1;
        d.headless = true;
        d.adoptContext = true;
        ok = r.init(d, g.gpu.environment(), &error);
        if (ok) RendererTestAccess::force_velocity(r, velocity);
    }
    ~Own() { r.shutdown(); }
    Own(const Own&) = delete;
    Own& operator=(const Own&) = delete;
    void frame(World& w, int n = 1) {
        for (int i = 0; i < n; ++i) {
            w.advance_clock(1.0 / 60.0);
            Gfx::simulate(w, 1.0f / 60.0f);  // the particles move on, as the runtime's step does
            r.begin_frame();
            r.render_world(w, 1.0f / 60.0f);
            r.end_frame();
            g.gpu.end_frame();
        }
    }
    Image draw(World& w, int n = 1) {
        frame(w, n);
        Image img;
        std::string err;
        const bool captured = r.capture(img, &err);
        INFO("capture error: " << err);
        REQUIRE(captured);
        return img;
    }
    bool has(const char* part) {
        const FrameGraph* graph = renderer_frame_graph(r);
        REQUIRE(graph != nullptr);
        for (const std::string& n : graph->order_names())
            if (n.find(part) != std::string::npos) return true;
        return false;
    }
};

// A plane of RGBA floats read back (velocity or mask), the first channel of a texel at (x, y).
struct Plane {
    std::vector<float> px;
    int w = 0, h = 0;
    float r(int x, int y) const { return px[(std::size_t(y) * std::size_t(w) + std::size_t(x)) * 4]; }
    float g(int x, int y) const { return px[(std::size_t(y) * std::size_t(w) + std::size_t(x)) * 4 + 1]; }
    bool none(int x, int y) const { return VelocityRef::is_none(r(x, y)) || VelocityRef::is_none(g(x, y)); }
};
Plane read_velocity(Own& o) {
    Plane p;
    std::string err;
    const bool ok = RendererTestAccess::read_velocity(o.r, p.px, p.w, p.h, &err);
    INFO("read_velocity: " << err);
    REQUIRE(ok);
    REQUIRE(p.w == kW);
    REQUIRE(p.h == kH);
    return p;
}
Plane read_reactive(Own& o) {
    Plane p;
    std::string err;
    const bool ok = RendererTestAccess::read_reactive(o.r, p.px, p.w, p.h, &err);
    INFO("read_reactive: " << err);
    REQUIRE(ok);
    REQUIRE(p.w == kW);
    REQUIRE(p.h == kH);
    return p;
}

// A 2D camera (orthographic, world units = design pixels, the origin at the centre, +Y up) with the temporal antialiasing on or off.
Entity add_camera2d(World& w, bool taa) {
    Entity cam = make(w, "cam");
    w.add<Camera>(cam).clearColor = Color{0, 0, 0, 1};
    camera_post(w, cam).temporalAAEnabled = taa;
    return cam;
}
Entity add_sprite(World& w, const char* name, Vec3 pos, float size, Color color, BlendMode blend = BlendMode::Alpha,
                  const std::string& texture = {}) {
    Entity e = make(w, name, pos);
    auto& s = w.add<Sprite>(e);
    s.texture = texture;
    s.size = {size, size};
    s.color = color;
    s.blend = blend;
    s.layer = 5;
    return e;
}
void move_x(World& w, Entity e, float x) { w.get<Transform>(e)->position.x = x; }
// The pixel of the world point (x, y) of a 2D scene seen by a camera at the origin.
int px_x(float x) { return kW / 2 + int(std::floor(x)); }
int px_y(float y) { return kH / 2 - int(std::ceil(y)); }

// A busy background: a sprite as large as the picture with a fine checker (4 px cells, grey and dark), so a stale pixel of a moving particle
// cannot hide in a flat colour (the resolve clamps its history to the colours around the pixel).
std::string write_busy_background() {
    Image img;
    img.width = 64;
    img.height = 36;
    img.rgba.resize(std::size_t(img.width) * std::size_t(img.height) * 4);
    for (int y = 0; y < img.height; ++y)
        for (int x = 0; x < img.width; ++x)
            img.set_pixel(x, y,
                          ((x / 2 + y / 2) % 2 == 0) ? Color{0.45f, 0.45f, 0.45f, 1} : Color{0.05f, 0.05f, 0.05f, 1});
    const std::string path = "assets/quad_motion_busy.png";
    REQUIRE(save_png(img, path).ok());
    return path;
}

// A white and black checker of 16 x 16 texels, 2 per cell: a particle made of it has fine detail, so the colours around any pixel span the
// whole range and the resolve's neighbourhood clamp cannot hide a stale history.
std::string write_checker_square() {
    Image img;
    img.width = 16;
    img.height = 16;
    img.rgba.resize(16 * 16 * 4);
    for (int y = 0; y < 16; ++y)
        for (int x = 0; x < 16; ++x)
            img.set_pixel(x, y, ((x / 2 + y / 2) % 2 == 0) ? Color::white() : Color{0, 0, 0, 1});
    const std::string path = "assets/quad_motion_square.png";
    REQUIRE(save_png(img, path).ok());
    return path;
}

// The emitter of a moving bright dot: one particle that stays where the emitter is (local space), additive, 30 px; soft round by default, a
// hard-edged square with `texture`.
Entity add_dot(World& w, float reactive, Vec3 pos = {0, 0, 0}, const std::string& texture = {}) {
    Entity e = make(w, "dot", pos);
    auto& p = w.add<ParticleEmitter>(e);
    p.rate = 0;
    p.burst = 1;
    p.seed = 5;
    p.lifetime = 1000.0f;
    p.lifetimeVariance = 0;
    p.speed = 0;
    p.speedVariance = 0;
    p.spread = 0;
    p.gravity = {0, 0, 0};
    p.startSize = 30;
    p.endSize = 30;
    p.startColor = Color{1, 1, 1, 1};
    p.endColor = Color{1, 1, 1, 1};
    p.worldSpace = false;
    p.blend = BlendMode::Additive;
    p.layer = 20;
    p.reactive = reactive;
    p.texture = texture;
    return e;
}

struct CleanAssets {
    CleanAssets() { gfx().renderer.clear_asset_cache(); }
    ~CleanAssets() { gfx().renderer.clear_asset_cache(); }
};

}  // namespace

TEST_CASE("quad motion: a cutout sprite writes its translation, a blended or additive one writes none and is marked "
          "reactive, and what no quad drew keeps the sentinel") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    CleanAssets clean;
    Own o(g);
    REQUIRE_MESSAGE(o.ok, o.error);
    World w;
    add_camera2d(w, true);
    const Entity mover = add_sprite(w, "mover", {-60, 40, 0}, 20, Color{1, 1, 1, 1});
    add_sprite(w, "still", {60, 40, 0}, 20, Color{1, 1, 1, 1});
    const Entity glass = add_sprite(w, "glass", {-60, -40, 0}, 20, Color{1, 1, 1, 0.3f});
    const Entity glow = add_sprite(w, "glow", {60, -40, 0}, 20, Color{1, 0.5f, 0.2f, 1}, BlendMode::Additive);
    // An opaque sprite flagged reactive (Sprite.reactive: a flash, a world-space HUD element): it writes the mask, not a vector.
    const Entity flash = add_sprite(w, "flash", {0, 70, 0}, 20, Color{1, 1, 1, 1});
    w.get<Sprite>(flash)->reactive = 0.6f;
    float x = -60;
    for (int f = 1; f <= 6; ++f) {
        x = -60 + 4.0f * float(f);
        move_x(w, mover, x);
        move_x(w, glass, x);
        move_x(w, glow, 120.0f - x);
        o.frame(w);
        if (f == 1) {  // the first frame of a camera has no history: no motion of its own
            const Plane v = read_velocity(o);
            REQUIRE_FALSE(v.none(px_x(x), px_y(40)));
            CHECK(std::fabs(v.r(px_x(x), px_y(40))) < 5.0e-4f);
        }
    }
    CHECK(o.has("taa-resolve"));
    CHECK(o.has("quad-velocity"));
    CHECK(o.has("quad-reactive"));
    const Plane v = read_velocity(o);
    // The mover: 4 px to the right in a picture 320 px wide, y unchanged.
    REQUIRE_FALSE(v.none(px_x(x), px_y(40)));
    CHECK(v.r(px_x(x), px_y(40)) == doctest::Approx(-4.0f / float(kW)).scale(1.0).epsilon(0.002));
    CHECK(std::fabs(v.g(px_x(x), px_y(40))) < 5.0e-4f);
    // The still sprite: zero. The pixel just outside the mover and the background: the sentinel (no quad drew them).
    REQUIRE_FALSE(v.none(px_x(60), px_y(40)));
    CHECK(std::fabs(v.r(px_x(60), px_y(40))) < 5.0e-4f);
    CHECK(v.none(px_x(x), px_y(40) + 25));
    CHECK(v.none(px_x(0), px_y(0)));
    // The translucent and the additive sprites wrote no velocity.
    CHECK(v.none(px_x(x), px_y(-40)));
    CHECK(v.none(px_x(120.0f - x), px_y(-40)));
    const Plane m = read_reactive(o);
    CHECK(m.r(px_x(120.0f - x), px_y(-40)) > 0.99f);  // additive: reactive by itself
    CHECK(m.r(px_x(x), px_y(-40)) <
          0.01f);  // alpha 0.3: a blend, but only the quads marked reactive count (a sprite is not)
    CHECK(m.r(px_x(x), px_y(40)) < 0.01f);  // the cutout is not reactive
    CHECK(m.r(px_x(0), px_y(0)) < 0.01f);
    CHECK(v.none(px_x(0), px_y(70)));
    CHECK(m.r(px_x(0), px_y(70)) == doctest::Approx(0.6f).scale(1.0).epsilon(0.02));
}

TEST_CASE("quad motion: a camera that pans over a still sprite gives it the camera's motion, the background keeps the "
          "sentinel") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    CleanAssets clean;
    Own o(g);
    REQUIRE_MESSAGE(o.ok, o.error);
    World w;
    const Entity cam = add_camera2d(w, true);
    add_sprite(w, "s", {0, 0, 0}, 40, Color{1, 1, 1, 1});
    for (int f = 1; f <= 5; ++f) {
        w.get<Transform>(cam)->position.x = 3.0f * float(f);
        o.frame(w);
    }
    const Plane v = read_velocity(o);
    const int x = px_x(-15), y = px_y(0);  // the sprite is 15 px left of the camera centre now
    REQUIRE_FALSE(v.none(x, y));
    CHECK(v.r(x, y) == doctest::Approx(3.0f / float(kW)).scale(1.0).epsilon(0.002));  // it slid 3 px to the left
    CHECK(std::fabs(v.g(x, y)) < 5.0e-4f);
    CHECK(v.none(px_x(100), y));
}

TEST_CASE("quad motion: a particle behind a mesh is not in the reactive mask (the prepass's depth hides it), one in "
          "front is, "
          "and a perspective camera's velocity is the mesh's alone") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    CleanAssets clean;
    Own o(g);
    REQUIRE_MESSAGE(o.ok, o.error);
    World w;
    Entity cam = make(w, "cam", {0, 0, 10});
    auto& c = w.add<Camera>(cam);
    c.projection = Projection::Perspective;
    c.fov = 60;
    c.clearColor = Color{0, 0, 0, 1};
    w.settings().skyColor = w.settings().horizonColor = Color{0, 0, 0, 1};
    camera_post(w, cam).temporalAAEnabled = true;
    Entity cube = make(w, "cube", {0, 0, 0});
    w.get<Transform>(cube)->scale = {
        6, 6, 6};  // 6 m wide: 134 px of a 320 x 180 picture (its front face at z = 3, 7 m from the camera)
    auto& mr = w.add<MeshRenderer>(cube);
    mr.mesh = "cube";
    mr.unlit = true;
    mr.color = Color::white();
    // Behind the cube: a soft dot 24 m wide (232 px at 16 m) that sticks out of the cube on both sides. In front of it: one 1.5 m wide (58 px).
    Entity behind = add_dot(w, 1.0f, {0, 0, -6});
    Entity front = add_dot(w, 1.0f, {0, 0, 6});
    for (Entity e : {behind, front}) {
        auto* p = w.get<ParticleEmitter>(e);
        p->is3D = true;
    }
    w.get<ParticleEmitter>(behind)->startSize = w.get<ParticleEmitter>(behind)->endSize = 24;
    w.get<ParticleEmitter>(front)->startSize = w.get<ParticleEmitter>(front)->endSize = 1.5f;
    o.frame(w, 4);
    CHECK(o.has("quad-reactive"));
    const Plane m = read_reactive(o);
    const Plane v = read_velocity(o);
    INFO("front " << m.r(kW / 2, kH / 2) << ", behind, on the cube " << m.r(kW / 2 + 45, kH / 2)
                  << ", behind, past the cube " << m.r(kW / 2 + 85, kH / 2));
    CHECK(m.r(kW / 2, kH / 2) > 0.9f);        // the particle in front of the cube
    CHECK(m.r(kW / 2 + 45, kH / 2) < 0.01f);  // the big one is behind the cube's face there: hidden
    CHECK(m.r(kW / 2 + 85, kH / 2) > 0.05f);  // and visible past the cube's silhouette
    // The velocity of the cube's pixels is the cube's (a still scene: zero), whatever particle is in front of it.
    REQUIRE_FALSE(v.none(kW / 2, kH / 2));
    CHECK(std::fabs(v.r(kW / 2, kH / 2)) < 5.0e-4f);
    CHECK(std::fabs(v.g(kW / 2, kH / 2)) < 5.0e-4f);
}

TEST_CASE(
    "quad motion: the reactive mask is the particle's footprint, by emitter, and zero where the emitter says so") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    CleanAssets clean;
    float centre = 0, edge = 0, outside = 0, half = 0;
    {
        Own o(g);
        REQUIRE_MESSAGE(o.ok, o.error);
        World w;
        add_camera2d(w, true);
        add_dot(w, 1.0f, {-50, 0, 0});
        add_dot(w, 0.5f, {50, 0, 0});
        o.frame(w, 4);
        CHECK(o.has("quad-reactive"));
        const Plane m = read_reactive(o);
        centre = m.r(px_x(-50), px_y(0));
        edge = m.r(px_x(-50 + 8), px_y(0));
        outside = m.r(px_x(-50 + 40), px_y(0));
        half = m.r(px_x(50), px_y(0));
    }
    INFO("centre " << centre << " edge " << edge << " outside " << outside << " half " << half);
    CHECK(centre > 0.95f);
    CHECK(edge > 0.05f);
    CHECK(edge < centre);  // the soft dot: its coverage multiplies the mask
    CHECK(outside < 0.01f);
    CHECK(half > 0.45f);
    CHECK(half < 0.55f);  // emitter.reactive 0.5 at the centre
    {
        // reactive 0: no mask at all, the pass is not even declared.
        Own o(g);
        REQUIRE_MESSAGE(o.ok, o.error);
        World w;
        add_camera2d(w, true);
        add_dot(w, 0.0f);
        o.frame(w, 4);
        CHECK_FALSE(o.has("quad-reactive"));
        CHECK(o.has("taa-resolve"));
    }
}

TEST_CASE(
    "quad motion: a bright particle moving over a busy background has its leading edge at once with the mask, and "
    "a measurable lag without it") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    CleanAssets clean;
    const std::string bg = write_busy_background();
    const std::string square = write_checker_square();
    const int frames = 20;
    const float step = 8.0f;  // px a frame: a third of the dot's width
    auto scene = [&](World& w, float reactive, float scale, bool taa, float x) {
        const Entity cam = add_camera2d(w, taa);
        camera_post(w, cam).temporalAAReactiveScale = scale;
        Entity back = add_sprite(w, "bg", {0, 0, 0}, 0, Color::white(), BlendMode::Alpha, bg);
        w.get<Sprite>(back)->size = {float(kW), float(kH)};
        w.get<Sprite>(back)->layer = -5;
        w.get<Sprite>(back)->pixelArt = true;
        return add_dot(w, reactive, {x, 0, 0}, square);
    };
    // The truth: the same picture drawn without the temporal antialiasing, the dot at its last place.
    const float last = -80.0f + step * float(frames);
    Image truth;
    {
        Own o(g, false);
        REQUIRE_MESSAGE(o.ok, o.error);
        World w;
        scene(w, 1.0f, 1.0f, false, last);
        truth = o.draw(w, 3);
    }
    auto run = [&](float reactive, float scale) {
        Own o(g);
        REQUIRE_MESSAGE(o.ok, o.error);
        World w;
        const Entity dot = scene(w, reactive, scale, true, -80.0f);
        Image img;
        for (int f = 1; f <= frames; ++f) {
            move_x(w, dot, -80.0f + step * float(f));
            img = o.draw(w);
        }
        return img;
    };
    // The mean error against the truth over the columns [x0, x1) of the dot's rows. The footprint is the dot's 30 px square at its last place: with
    // the mask its pixels are the current frame's, without it they hold 90% of a history in which the dot was one step (8 px) to the left, so the
    // leading strip (the last 8 columns) is far off. The trail is the 16 columns behind the footprint, where the dot was in the frames before: the
    // mask does not cover them (it holds the pixels the dot covers now), so there it must not make things worse, and the resolve's own
    // neighbourhood clamp is what keeps it small.
    auto error_over = [&](const Image& img, float x0, float x1) {
        double sum = 0;
        int n = 0;
        for (int y = px_y(14); y <= px_y(-14); ++y)
            for (int x = px_x(x0); x < px_x(x1); ++x) {
                sum += std::fabs(double(img.pixel(x, y).r) - double(truth.pixel(x, y).r));
                ++n;
            }
        return sum / double(std::max(n, 1));
    };
    const Image withMask = run(1.0f, 1.0f);
    const Image noMask = run(0.0f, 1.0f);
    const Image scaleZero = run(1.0f, 0.0f);
    const double eMask = error_over(withMask, last - 15, last + 15), eNo = error_over(noMask, last - 15, last + 15),
                 eZero = error_over(scaleZero, last - 15, last + 15);
    const double tMask = error_over(withMask, last - 31, last - 15), tNo = error_over(noMask, last - 31, last - 15);
    INFO("footprint error: with the mask " << eMask << ", without " << eNo << ", reactive scale 0 " << eZero
                                           << "; trail: with the mask " << tMask << ", without " << tNo);
    CHECK(eNo > 0.08);
    CHECK(eMask < 0.4 * eNo);
    CHECK(eZero > 0.8 * eNo);  // the camera's reactive scale multiplies the mask: at 0 it is as if there were none
    CHECK(tMask <= tNo + 0.02);
}

TEST_CASE(
    "quad motion: with the temporal antialiasing off no pass is declared and the picture is the same bit for bit") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    CleanAssets clean;
    auto run = [&](bool velocity, float reactive) {
        Own o(g, velocity);
        REQUIRE_MESSAGE(o.ok, o.error);
        World w;
        add_camera2d(w, false);
        add_sprite(w, "a", {-40, 0, 0}, 30, Color{1, 0.6f, 0.2f, 1});
        add_sprite(w, "b", {40, 0, 0}, 30, Color{0.2f, 0.6f, 1, 0.6f});
        add_dot(w, reactive, {0, 30, 0});
        const Image img = o.draw(w, 4);
        CHECK_FALSE(o.has("quad-velocity"));
        CHECK_FALSE(o.has("quad-reactive"));
        CHECK_FALSE(o.has("velocity-probe"));
        return img;
    };
    const Image a = run(false, 1.0f);
    const Image b = run(false, 0.0f);
    REQUIRE(a.rgba.size() == b.rgba.size());
    CHECK(a.rgba == b.rgba);
    // The velocity forced on (a test or the debug view) adds the pass and does not change the picture of a frame without the effect.
    Own o(g, true);
    REQUIRE_MESSAGE(o.ok, o.error);
    World w;
    add_camera2d(w, false);
    add_sprite(w, "a", {-40, 0, 0}, 30, Color{1, 0.6f, 0.2f, 1});
    add_sprite(w, "b", {40, 0, 0}, 30, Color{0.2f, 0.6f, 1, 0.6f});
    add_dot(w, 1.0f, {0, 30, 0});
    const Image forced = o.draw(w, 4);
    CHECK(o.has("quad-velocity"));
    CHECK_FALSE(o.has("quad-reactive"));  // the mask is for the effects that read it, not for the velocity alone
    CHECK(a.rgba == forced.rgba);
}

TEST_CASE("quad motion: the debug view motionVectors paints what the quads wrote") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    CleanAssets clean;
    Own o(g, false);
    REQUIRE_MESSAGE(o.ok, o.error);
    World w;
    add_camera2d(w, false);
    const Entity s = add_sprite(w, "s", {0, 0, 0}, 40, Color{1, 1, 1, 1});
    o.r.set_debug_view(DebugView::MotionVectors);
    Image img;
    for (int f = 1; f <= 4; ++f) {
        move_x(w, s, 4.0f * float(f));
        img = o.draw(w);
    }
    CHECK(o.has("prepass-view"));
    CHECK(o.has("quad-velocity"));
    const Color on = img.pixel(px_x(16), px_y(0)), off = img.pixel(px_x(-100), px_y(0));
    INFO("on the sprite " << on.r << " " << on.g << " " << on.b << ", off it " << off.r << " " << off.g << " "
                          << off.b);
    CHECK(std::fabs(off.r - 0.3f) < 0.03f);  // the sentinel is a flat grey
    CHECK(std::fabs(off.g - 0.3f) < 0.03f);
    CHECK((std::fabs(on.r - off.r) + std::fabs(on.g - off.g) + std::fabs(on.b - off.b)) >
          0.2f);  // a hue over the sprite
    o.r.set_debug_view(DebugView::None);
}

TEST_CASE("quad motion: a tilemap moved by its Transform has a velocity of its own") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    CleanAssets clean;
    Own o(g);
    REQUIRE_MESSAGE(o.ok, o.error);
    const std::string tileset = write_checker_square();
    World w;
    add_camera2d(w, true);
    Entity map = make(w, "map", {-60, 40, 0});
    auto& tm = w.add<Tilemap>(map);
    tm.tileset = tileset;
    tm.tileSize = {16, 16};
    set_tilemap_tiles(tm, Json::array({Json::array({0, 0})}));
    float x = -60;
    for (int f = 1; f <= 5; ++f) {
        x = -60 + 4.0f * float(f);
        move_x(w, map, x);
        o.frame(w);
    }
    const Plane v = read_velocity(o);
    // The first tile spans x .. x + 16 and 16 px down from y = 40: its pixels moved 4 px to the right, the camera did not.
    const int tx = px_x(x + 8), ty = px_y(32);
    REQUIRE_FALSE(v.none(tx, ty));
    CHECK(v.r(tx, ty) == doctest::Approx(-4.0f / float(kW)).scale(1.0).epsilon(0.002));
    CHECK(std::fabs(v.g(tx, ty)) < 5.0e-4f);
    CHECK(v.none(px_x(x + 8), px_y(32) + 40));  // the background
}

TEST_CASE(
    "quad motion: with the jitter on, the velocity covers the pixels the sprite's colour covers, the edge ones too") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    CleanAssets clean;
    Own o(g);
    REQUIRE_MESSAGE(o.ok, o.error);
    RendererTestAccess::force_jitter(o.r, kJitterPhasesDefault);
    World w;
    add_camera2d(w, false);  // no resolve: the picture is the jittered colour as drawn
    // Edges at .9, .3 (x) and .8, .2 (y) of a pixel: whichever way the jitter (up to half a pixel) moves the samples, some edge pixel flips.
    const Entity box = add_sprite(w, "box", {0.1f, 0.0f, 0}, 40.4f, Color{1, 1, 1, 1});
    w.get<Sprite>(box)->size = {40.4f, 40.6f};
    int jitteredFrames = 0, covered = 0, mismatch = 0;
    for (int f = 0; f < 12; ++f) {
        const Image img = o.draw(w);
        bool shifted = false;
        for (const Vec2& j : RendererTestAccess::last_jitter(o.r)) shifted = shifted || j.x != 0.0f || j.y != 0.0f;
        jitteredFrames += shifted ? 1 : 0;
        const Plane v = read_velocity(o);
        for (int y = 70; y < 110; ++y)
            for (int x = 130; x < 190; ++x) {
                const bool colour = img.pixel(x, y).r > 0.5f, vel = !v.none(x, y);
                covered += colour ? 1 : 0;
                mismatch += colour != vel ? 1 : 0;
            }
    }
    CHECK(jitteredFrames >= 8);
    CHECK(covered > 12 * 1500);
    CHECK(mismatch == 0);
}

namespace {

// The vector the velocity image holds at the pixel whose centre is the world point (x, y) of a 2D scene seen by a camera at the origin, for a
// point that was at `before` on the frame before (uv units: the picture is 1 wide and 1 tall; +y of the world is up, of the picture down).
Vec2 expected_velocity(Vec2 now, Vec2 before) {
    return {(before.x - now.x) / float(kW), -(before.y - now.y) / float(kH)};
}

// The pixel's centre in the world, for the pixel px_x(x) / px_y(y).
Vec2 pixel_centre(int px, int py) { return {float(px - kW / 2) + 0.5f, float(kH / 2 - py) - 0.5f}; }

}  // namespace

TEST_CASE("quad motion: a sprite that turns about its centre has tangential vectors at its corners, with the sign of "
          "the turn") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    CleanAssets clean;
    for (const float step : {4.0f, -4.0f}) {
        INFO("degrees per frame: " << step);
        Own o(g);
        REQUIRE_MESSAGE(o.ok, o.error);
        World w;
        add_camera2d(w, true);
        const Entity spin = add_sprite(w, "spin", {0, 0, 0}, 80, Color{1, 1, 1, 1});
        for (int f = 1; f <= 6; ++f) {
            w.get<Transform>(spin)->rotation.z = step * float(f);
            o.frame(w);
        }
        const Plane v = read_velocity(o);
        const float a = step * 3.14159265f / 180.0f;  // the turn between the two last frames
        float biggest = 0.0f;
        // The four corners of the middle of the sprite (inside it whatever its angle is: 40 px from the centre to a side) and the centre.
        for (const Vec2 q : {Vec2{22, 22}, Vec2{-22, 22}, Vec2{-22, -22}, Vec2{22, -22}}) {
            const int x = px_x(q.x), y = px_y(q.y);
            REQUIRE_FALSE(v.none(x, y));
            const Vec2 now = pixel_centre(x, y);
            // The point of the sprite that is at `now` was at now turned back by `a` about the centre.
            const Vec2 before = {now.x * std::cos(-a) - now.y * std::sin(-a),
                                 now.x * std::sin(-a) + now.y * std::cos(-a)};
            const Vec2 want = expected_velocity(now, before);
            CHECK(v.r(x, y) == doctest::Approx(want.x).scale(1.0).epsilon(0.05));
            CHECK(v.g(x, y) == doctest::Approx(want.y).scale(1.0).epsilon(0.05));
            // Tangential: its sign is the sign of the turn (counter-clockwise: the corner it comes from is clockwise of it).
            CHECK(v.r(x, y) * want.x > 0.0f);
            CHECK(v.g(x, y) * want.y > 0.0f);
            biggest = std::max(biggest, std::fabs(want.x));
        }
        CHECK(biggest > 0.004f);  // 1.5 px of 320 or more: far above the half-float noise
        // The centre does not move.
        REQUIRE_FALSE(v.none(px_x(0), px_y(0)));
        CHECK(std::fabs(v.r(px_x(0), px_y(0))) < 1.5e-3f);
        CHECK(std::fabs(v.g(px_x(0), px_y(0))) < 1.5e-3f);
    }
}

TEST_CASE(
    "quad motion: a sprite that grows has vectors that point to the centre, bigger the farther the pixel is from it") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    CleanAssets clean;
    Own o(g);
    REQUIRE_MESSAGE(o.ok, o.error);
    World w;
    add_camera2d(w, true);
    const Entity grow = add_sprite(w, "grow", {0, 0, 0}, 60, Color{1, 1, 1, 1});
    float scale = 1.0f, last = 1.0f;
    for (int f = 1; f <= 6; ++f) {
        last = scale;
        scale = 1.0f + 0.1f * float(f);
        w.get<Transform>(grow)->scale = {scale, scale, 1};
        o.frame(w);
    }
    const Plane v = read_velocity(o);
    float near_x = 0.0f, far_x = 0.0f;
    for (const float d : {12.0f, 40.0f}) {  // pixels on the right of the centre, inside the sprite (it is 96 wide now)
        const int x = px_x(d), y = px_y(0.5f);
        REQUIRE_FALSE(v.none(x, y));
        const Vec2 now = pixel_centre(x, y);
        const Vec2 want = expected_velocity(now, {now.x * last / scale, now.y * last / scale});
        CHECK(want.x < 0.0f);  // it was nearer to the centre: uvPrev - uvCurr points the way of the centre, to the left
        CHECK(v.r(x, y) == doctest::Approx(want.x).scale(1.0).epsilon(0.05));
        (d < 20.0f ? near_x : far_x) = v.r(x, y);
    }
    CHECK(far_x < near_x);  // both negative: the farther one moved more
    CHECK(near_x < 0.0f);
}

TEST_CASE("quad motion: an Additive sprite with reactive 0 opts out of the mask and writes no vector, by default it is "
          "reactive 1") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    CleanAssets clean;
    Own o(g);
    REQUIRE_MESSAGE(o.ok, o.error);
    World w;
    add_camera2d(w, true);
    // An opaque sprite far from the two: with only Additive items nothing writes a vector and the frame has no velocity image at all.
    add_sprite(w, "anchor", {0, 60, 0}, 20, Color{0.2f, 0.2f, 0.2f, 1});
    add_sprite(w, "by_blend", {-60, 0, 0}, 20, Color{1, 0.5f, 0.2f, 1}, BlendMode::Additive);
    const Entity opt_out = add_sprite(w, "opt_out", {60, 0, 0}, 20, Color{1, 0.5f, 0.2f, 1}, BlendMode::Additive);
    CHECK(w.get<Sprite>(opt_out)->reactive == -1.0f);
    w.get<Sprite>(opt_out)->reactive = 0.0f;
    o.frame(w, 3);
    const Plane m = read_reactive(o);
    CHECK(m.r(px_x(-60), px_y(0)) > 0.99f);
    CHECK(m.r(px_x(60), px_y(0)) < 0.01f);
    const Plane v = read_velocity(o);
    CHECK(v.none(px_x(60), px_y(0)));  // an Additive item never overwrites a vector
}

TEST_CASE("quad motion: a sprite with a material of its own: reactive ones write the mask over their quad, the others "
          "no vector") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    MaterialScope scope;
    CleanAssets clean;
    Own o(g);
    REQUIRE_MESSAGE(o.ok, o.error);
    World w;
    add_camera2d(w, true);
    auto with_material = [&](const char* name, Vec3 pos, BlendMode blend) {
        const Entity e = add_sprite(w, name, pos, 20, Color{1, 1, 1, 1}, blend);
        auto* s = w.get<Sprite>(e);
        s->material = "materials/sprite_tint.material.json";
        s->materialParams = Json::object();
        s->materialParams["tint"] = Json::array({1.0, 1.0, 1.0, 1.0});
        return e;
    };
    with_material("glow", {-60, 0, 0}, BlendMode::Additive);  // reactive by its blend
    const Entity flash = with_material("flash", {0, 0, 0}, BlendMode::Alpha);
    w.get<Sprite>(flash)->reactive = 0.6f;
    with_material("plain", {60, 0, 0}, BlendMode::Alpha);  // a cutout with a material: no vector, no mask
    add_sprite(w, "anchor", {0, -60, 0}, 20,
               Color{0.2f, 0.2f, 0.2f, 1});  // writes a vector: the frame has a velocity image to read
    float x = 0;
    for (int f = 1; f <= 5; ++f) {
        x = float(f);
        move_x(w, flash, x);
        o.frame(w);
    }
    CHECK(o.has("quad-reactive"));
    const Plane m = read_reactive(o);
    CHECK(m.r(px_x(-60), px_y(0)) > 0.99f);  // the additive sprite with a material has its mask (it lost it before)
    CHECK(m.r(px_x(x), px_y(0)) == doctest::Approx(0.6f).scale(1.0).epsilon(0.03));
    CHECK(m.r(px_x(60), px_y(0)) < 0.01f);
    CHECK(m.r(px_x(0), px_y(60)) < 0.01f);
    const Plane v = read_velocity(o);
    CHECK(
        v.none(px_x(60),
               px_y(0)));  // the material's discard and vertex() are not followed: the camera's motion, not a footprint
    CHECK(v.none(px_x(-60), px_y(0)));
}

TEST_CASE("quad motion: a capture of a camera with the temporal antialiasing on draws the same picture as with it off "
          "(and needs no velocity for it)") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    CleanAssets clean;
    Own o(g, false);
    REQUIRE_MESSAGE(o.ok, o.error);
    World w;
    Entity cam = make(w, "cam", {0, 0, 10});
    auto& c = w.add<Camera>(cam);
    c.projection = Projection::Perspective;
    c.fov = 60;
    c.clearColor = Color{0, 0, 0, 1};
    camera_post(w, cam).temporalAAEnabled = true;
    Entity cube = make(w, "cube", {0, 0, 0});
    w.get<Transform>(cube)->scale = {3, 3, 3};
    auto& mr = w.add<MeshRenderer>(cube);
    mr.mesh = "cube";
    mr.unlit = true;
    add_sprite(w, "s", {-2, 1, 0}, 1.5f, Color{1, 0.4f, 0.1f, 1});
    o.frame(w, 3);
    CHECK(o.has("prepass"));  // the game's own frames: the resolve reads the velocity the prepass writes
    // A capture has no history to resolve, so nothing reads a velocity and plan_job takes the request back (no prepass, no per-instance
    // previous model, no quad-velocity pass). The passes of a capture are in a graph of its own that nobody can read, so what this checks is the
    // picture: the camera with the effect on gives the one it gives with the effect off, bit for bit, for a mesh and a sprite.
    auto shot_with = [&](bool taa) {
        camera_post(w, cam).temporalAAEnabled = taa;
        Renderer::CameraCapture spec;
        spec.camera = cam;
        spec.width = kW;
        spec.height = kH;
        Image shot;
        std::string err;
        REQUIRE_MESSAGE(o.r.capture_camera(w, spec, shot, &err), err);
        return shot;
    };
    const Image off = shot_with(false);
    CHECK_FALSE(RendererTestAccess::last_job_needs_velocity(o.r));
    const Image on = shot_with(true);
    // A capture plans no post stack: it asks for no velocity, with the effect on as off.
    CHECK_FALSE(RendererTestAccess::last_job_needs_velocity(o.r));
    REQUIRE(on.width == off.width);
    REQUIRE(on.height == off.height);
    CHECK(on.rgba == off.rgba);
}

TEST_CASE("quad motion: the velocity request of the temporal antialiasing is taken back by a frame that cannot resolve "
          "(no history image), what something else asks for stays") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    CleanAssets clean;
    for (const bool budget : {false, true}) {
        INFO("history budget of 1 byte: " << budget);
        Own o(g, false);
        REQUIRE_MESSAGE(o.ok, o.error);
        World w;
        Entity cam = make(w, "cam", {0, 0, 10});
        auto& c = w.add<Camera>(cam);
        c.projection = Projection::Perspective;
        c.fov = 60;
        c.clearColor = Color{0, 0, 0, 1};
        Entity cube = make(w, "cube", {0, 0, 0});
        w.add<MeshRenderer>(cube).mesh = "cube";
        camera_post(w, cam).temporalAAEnabled = true;
        // A budget no history fits in: the effect cannot run, so nothing reads a velocity (plan_job takes the request back: no
        // prepass, no previous model, no quad-velocity pass). Without it the effect resolves and asks.
        if (budget) RendererTestAccess::taa_set_budget(o.r, 1);
        o.frame(w, 3);
        CHECK(RendererTestAccess::taa_unavailable(o.r) == budget);
        CHECK(RendererTestAccess::last_job_needs_velocity(o.r) == !budget);
        // Another consumer of the velocity (the test hook here, as the debug view and the object motion blur) keeps its request.
        RendererTestAccess::force_velocity(o.r, true);
        o.frame(w, 1);
        CHECK(RendererTestAccess::last_job_needs_velocity(o.r));
    }
}

TEST_CASE(
    "quad motion: a sprite whose scale goes to 0 and back falls back to its translation, with no NaN in the image") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    CleanAssets clean;
    Own o(g);
    REQUIRE_MESSAGE(o.ok, o.error);
    World w;
    add_camera2d(w, true);
    const Entity s = add_sprite(w, "s", {0, 0, 0}, 80, Color{1, 1, 1, 1});
    auto all_finite = [&](const Plane& v) {
        for (int y = 0; y < kH; ++y)
            for (int x = 0; x < kW; ++x)
                if (!std::isfinite(v.r(x, y)) || !std::isfinite(v.g(x, y))) return false;
        return true;
    };
    float x = 0;
    for (int f = 1; f <= 4; ++f) {
        x = 4.0f * float(f);
        move_x(w, s, x);
        o.frame(w);
    }
    // The matrix has no inverse on this frame (the sprite draws nothing).
    x += 4.0f;
    move_x(w, s, x);
    w.get<Transform>(s)->scale = {0, 0, 1};
    o.frame(w);
    CHECK(all_finite(read_velocity(o)));
    for (int f = 0; f < 2; ++f) {
        x += 4.0f;
        move_x(w, s, x);
        w.get<Transform>(s)->scale = {1, 1, 1};
        o.frame(w);
        const Plane v = read_velocity(o);
        CHECK(all_finite(v));
        // Both frames after the zero scale (the frame before's matrix has no inverse on the first): the translation, 4 px of 320.
        for (const Vec2 q : {Vec2{-22, 22}, Vec2{22, -22}}) {
            const int px = px_x(x + q.x), py = px_y(q.y);
            REQUIRE_FALSE(v.none(px, py));
            CHECK(v.r(px, py) == doctest::Approx(-4.0f / float(kW)).scale(1.0).epsilon(0.02));
            CHECK(std::fabs(v.g(px, py)) < 5.0e-4f);
        }
    }
}

TEST_CASE("quad motion: a floating-origin rebase while a sprite turns leaves the rotation's motion, with no jump from "
          "the shift") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    CleanAssets clean;
    Own o(g);
    REQUIRE_MESSAGE(o.ok, o.error);
    World w;
    const Vec3 at{1000.0f, 0.0f, 0.0f};
    const Entity cam = add_camera2d(w, true);
    w.get<Transform>(cam)->position = at;
    const Entity spin = add_sprite(w, "spin", at, 80, Color{1, 1, 1, 1});
    const float step = 4.0f;
    const float a = step * 3.14159265f / 180.0f;
    for (int f = 1; f <= 8; ++f) {
        if (f == 5) w.rebase(at);  // every local position moves by -at: the scene is now around the origin
        w.get<Transform>(spin)->rotation.z = step * float(f);
        o.frame(w);
        if (f < 5) continue;
        INFO("frame " << f << (f == 5 ? " (the one right after the rebase)" : ""));
        const Plane v = read_velocity(o);
        float biggest = 0.0f;
        for (const Vec2 q : {Vec2{22, 22}, Vec2{-22, -22}}) {
            const int x = px_x(q.x), y = px_y(q.y);
            REQUIRE_FALSE(v.none(x, y));
            const Vec2 now = pixel_centre(x, y);
            const Vec2 before = {now.x * std::cos(-a) - now.y * std::sin(-a),
                                 now.x * std::sin(-a) + now.y * std::cos(-a)};
            const Vec2 want = expected_velocity(now, before);
            CHECK(v.r(x, y) == doctest::Approx(want.x).scale(1.0).epsilon(0.05));
            CHECK(v.g(x, y) == doctest::Approx(want.y).scale(1.0).epsilon(0.05));
            // The rotation's own motion survives the rebase (a zero vector would pass the loose Approx above).
            CHECK(v.r(x, y) * want.x > 0.0f);
            CHECK(v.g(x, y) * want.y > 0.0f);
            biggest = std::max(biggest, std::fabs(want.x));
        }
        CHECK(biggest > 0.004f);
        // The centre did not jump by the 1000 px of the shift.
        CHECK(std::fabs(v.r(px_x(0), px_y(0))) < 1.5e-3f);
        CHECK(std::fabs(v.g(px_x(0), px_y(0))) < 1.5e-3f);
    }
}
