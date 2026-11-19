// M71-C3b: the transient screen effects (fa/scene/screen_fx.h) and the radial blur on the GPU, drawn by the camera's final post
// pass (post.glsl: shockwave 4096, heat haze 8192, radial blur 16384, flash / fade overlay 32768), each compared with the CPU form
// of the same maths (src/post_fx.h) on the picture drawn without the effect. The CPU maths alone are in postfx_tests.cpp, the
// state, bounds and clock in the scene tests.
#include "test_util.h"

#include <algorithm>
#include <cmath>
#include <functional>
#include <string>
#include <vector>

#include "frame_graph.h"
#include "post_fx.h"
#include "render_internal.h"
#include "renderer_test_access.h"

#include "fa/scene/screen_fx.h"

using namespace fa;
using namespace fa::test;
using fa::render::PostFx;

namespace {

constexpr float kStep = 1.0f / 255.0f;

// Flat areas of several colours and a white and a dark stripe, over a bluish grey (the picture of postfx_render_tests.cpp).
struct FxScene {
    World world;
    Entity cam;
    explicit FxScene(bool linear = false) {
        if (linear) world.settings().colorSpace = ColorSpace::Linear;
        cam = make(world, "cam");
        world.add<Camera>(cam).clearColor = Color{0.31f, 0.35f, 0.42f, 1};
        patch({-90, 40}, {50, 40}, Color{0.85f, 0.25f, 0.15f, 1});
        patch({-30, 40}, {50, 40}, Color{0.2f, 0.7f, 0.25f, 1});
        patch({30, 40}, {50, 40}, Color{0.2f, 0.3f, 0.85f, 1});
        patch({-60, -40}, {80, 40}, Color{0.95f, 0.9f, 0.7f, 1});
        patch({60, -40}, {60, 60}, Color{0.12f, 0.1f, 0.14f, 1});
        patch({20, 0}, {10, 170}, Color{1, 1, 1, 1});
        patch({-110, 0}, {8, 170}, Color{0.1f, 0.1f, 0.1f, 1});
    }
    void patch(Vec2 at, Vec2 size, Color c) {
        Entity e = make(world, "patch", {at.x, at.y, 0});
        auto& s = world.add<Shape2D>(e);
        s.shape = ShapeType::Rectangle;
        s.size = size;
        s.color = c;
    }
};

std::vector<std::string> order_of(Gfx& g) {
    const render::FrameGraph* graph = render::renderer_frame_graph(g.renderer);
    REQUIRE(graph != nullptr);
    return graph->order_names();
}

Vec3 texel(const Image& im, int x, int y) {
    const Color c = im.pixel(std::clamp(x, 0, im.width - 1), std::clamp(y, 0, im.height - 1));
    return {c.r, c.g, c.b};
}
// The bilinear sample of the picture at uv (top-left origin); the edge colour beyond its edges (the post pass clamps).
Vec3 bilinear(const Image& im, Vec2 uv) {
    uv = {saturate(uv.x), saturate(uv.y)};
    const float fx = uv.x * float(im.width) - 0.5f, fy = uv.y * float(im.height) - 0.5f;
    const int x0 = int(std::floor(fx)), y0 = int(std::floor(fy));
    const float tx = fx - float(x0), ty = fy - float(y0);
    const Vec3 a = lerp(texel(im, x0, y0), texel(im, x0 + 1, y0), tx);
    const Vec3 b = lerp(texel(im, x0, y0 + 1), texel(im, x0 + 1, y0 + 1), tx);
    return lerp(a, b, ty);
}
Vec2 uv_of(const Image& im, int x, int y) {
    return {(float(x) + 0.5f) / float(im.width), (float(y) + 0.5f) / float(im.height)};
}

struct Diff {
    double mean = 0.0;
    float max = 0.0f;
};
// How far `got` is from `want(x, y)` over the pixels x in [x0, x1) (all rows).
Diff compare(const Image& got, const std::function<Vec3(int, int)>& want, int x0 = 0, int x1 = -1) {
    Diff d;
    double sum = 0.0;
    if (x1 < 0) x1 = got.width;
    for (int y = 0; y < got.height; ++y)
        for (int x = x0; x < x1; ++x) {
            const Vec3 g = texel(got, x, y), w = want(x, y);
            for (int i = 0; i < 3; ++i) {
                const float e = std::fabs(g[i] - w[i]);
                sum += e;
                d.max = std::max(d.max, e);
            }
        }
    d.mean = sum / (double(x1 - x0) * double(got.height) * 3.0);
    return d;
}

// What the camera `camera` (null: every one) draws of the world's live effects, as the renderer builds it (identity projection).
PostFx fx_of(const World& world, Entity camera = kNullEntity, const Mat4& viewProj = Mat4{}) {
    std::vector<ScreenFx> mine;
    for (const ScreenFx& e : world.feel().screenFx.live)
        if (!e.camera || e.camera == camera) mine.push_back(e);
    PostFx fx;
    render::add_screen_fx(fx, mine, viewProj);
    return fx;
}

ScreenFxOptions opts(ScreenFxKind kind, float duration) {
    ScreenFxOptions o = screen_fx_defaults(kind);
    o.duration = duration;
    return o;
}

void start(World& w, const ScreenFxOptions& o, Entity camera = kNullEntity) {
    const Result<void> r = screen_fx_start(w, camera, o);
    REQUIRE(r.ok());
}

}  // namespace

TEST_CASE("screen fx: nothing alive draws no pass and the frame is byte-identical, with and without a PostProcess") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    for (const bool withStack : {false, true}) {
        INFO(std::string(withStack ? "with a PostProcess" : "no PostProcess"));
        FxScene ref;
        if (withStack) ref.world.add<PostProcess>(ref.cam);  // a stack with no effect on
        const Image off = g.draw(ref.world);
        CHECK(order_of(g) == std::vector<std::string>{"camera:0/game"});
        FxScene s;
        if (withStack) s.world.add<PostProcess>(s.cam);
        ScreenFxOptions o = opts(ScreenFxKind::Flash, 0.5f);
        o.color = Color{1, 0, 0, 1};
        start(s.world, o);
        const Image on = g.draw(s.world);
        CHECK(order_of(g) == std::vector<std::string>{"camera:0/game", "camera:0/post"});
        CHECK(on.rgba != off.rgba);
        // Cancelled (or over): the frame is the one it was, pass list and bytes.
        screen_fx_cancel(s.world, kNullEntity);
        const Image after = g.draw(s.world);
        CHECK(order_of(g) == std::vector<std::string>{"camera:0/game"});
        CHECK(after.rgba == off.rgba);
        // A flash that has run its time ends by itself.
        start(s.world, o);
        screen_fx_update(s.world, 0.6f);
        const Image ended = g.draw(s.world);
        CHECK(order_of(g) == std::vector<std::string>{"camera:0/game"});
        CHECK(ended.rgba == off.rgba);
    }
}

TEST_CASE("screen fx: a flash is the colour at its start and fades out, a fade goes to black and stays, a fade in "
          "comes back") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    for (const bool linear : {false, true}) {
        INFO(std::string(linear ? "linear scene" : "gamma scene"));
        FxScene refScene(linear);
        const Image ref = g.draw(refScene.world);
        // Flash: opacity `strength` (1) at t = 0, half of it halfway.
        FxScene s(linear);
        ScreenFxOptions flash = opts(ScreenFxKind::Flash, 0.8f);
        flash.color = Color{1.0f, 0.5f, 0.0f, 1};
        start(s.world, flash);
        Image img = g.draw(s.world);
        for (const auto& [x, y] : {std::pair{10, 10}, std::pair{160, 90}, std::pair{300, 170}}) {
            CHECK(img.pixel(x, y).r == doctest::Approx(1.0f).epsilon(0.01));
            CHECK(img.pixel(x, y).g == doctest::Approx(0.5f).epsilon(0.02));
            CHECK(img.pixel(x, y).b < 2.0f * kStep);
        }
        screen_fx_update(s.world, 0.4f);  // halfway
        img = g.draw(s.world);
        PostFx fx = fx_of(s.world);
        REQUIRE(fx.overlay);
        CHECK(fx.overlayAlpha == doctest::Approx(0.5f).epsilon(0.001));
        Diff d = compare(img, [&](int x, int y) { return render::overlay_color(fx, texel(ref, x, y)); });
        CHECK(d.max < 3.0f * kStep);
        screen_fx_update(s.world, 0.39f);  // nearly over
        img = g.draw(s.world);
        fx = fx_of(s.world);
        d = compare(img, [&](int x, int y) { return render::overlay_color(fx, texel(ref, x, y)); });
        CHECK(d.max < 3.0f * kStep);
        screen_fx_update(s.world, 0.1f);
        CHECK(s.world.feel().screenFx.live.empty());

        // Fade out to black: half way, then held black until it is cancelled.
        FxScene f(linear);
        ScreenFxOptions fade = opts(ScreenFxKind::Fade, 1.0f);
        fade.color = Color{0, 0, 0, 1};
        start(f.world, fade);
        screen_fx_update(f.world, 0.5f);
        img = g.draw(f.world);
        d = compare(img, [&](int x, int y) { return texel(ref, x, y) * 0.5f; });
        CHECK(d.max < 3.0f * kStep);
        screen_fx_update(f.world, 0.5f);
        img = g.draw(f.world);
        d = compare(img, [](int, int) { return Vec3{0, 0, 0}; });
        CHECK(d.max < 2.0f * kStep);
        screen_fx_update(f.world, 30.0f);  // held
        img = g.draw(f.world);
        d = compare(img, [](int, int) { return Vec3{0, 0, 0}; });
        CHECK(d.max < 2.0f * kStep);
        // Fade back in: black at the start, the picture at the end (the effect is gone).
        ScreenFxOptions in = fade;
        in.fadeIn = true;
        start(f.world, in);
        img = g.draw(f.world);
        d = compare(img, [](int, int) { return Vec3{0, 0, 0}; });
        CHECK(d.max < 2.0f * kStep);
        screen_fx_update(f.world, 1.1f);
        CHECK(f.world.feel().screenFx.live.empty());
        img = g.draw(f.world);
        CHECK(img.rgba == ref.rgba);
    }
}

TEST_CASE("screen fx: a shockwave pushes the picture outward around the ring as the CPU computes, the rest stays") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    FxScene refScene;
    const Image ref = g.draw(refScene.world);
    const float aspect = float(ref.width) / float(ref.height);
    FxScene s;
    ScreenFxOptions o = opts(ScreenFxKind::Shockwave, 1.0f);
    o.screen = {0.4f, 0.55f};
    o.strength = 0.08f;
    o.radius = 0.5f;
    o.width = 0.2f;
    start(s.world, o);
    screen_fx_update(s.world, 0.4f);
    const Image got = g.draw(s.world);
    CHECK(order_of(g) == std::vector<std::string>{"camera:0/game", "camera:0/post"});
    const PostFx fx = fx_of(s.world);
    REQUIRE(fx.ringCount == 1);
    CHECK(fx.rings[0].radius > 0.1f);
    const Diff d = compare(got, [&](int x, int y) {
        const Vec2 uv = uv_of(ref, x, y);
        return bilinear(ref, uv + render::shockwave_offset(fx, uv, aspect));
    });
    CHECK(d.mean < 0.006);
    // The ring did move something: far more than the CPU-less difference of two identical frames.
    const Diff moved = compare(got, [&](int x, int y) { return texel(ref, x, y); });
    CHECK(moved.mean > 0.01);
    // Outside the ring's band the picture is the one it was (the far corner, the centre).
    CHECK(compare(got, [&](int x, int y) { return texel(ref, x, y); }, 0, 8).mean < 0.02);
    const Vec2 c = fx.rings[0].center;
    CHECK(render::shockwave_offset(fx, c, aspect).x == 0.0f);
    const int mx = int(c.x * 320.0f), my = int(c.y * 180.0f);
    CHECK(std::fabs(texel(got, mx, my).x - texel(ref, mx, my).x) < 2.0f * kStep);
    // A ring centred on a world point is found where the camera projects it: x = +80 of 320 is 3/4 across.
    FxScene w;
    ScreenFxOptions ow = o;
    ow.atWorld = true;
    ow.world = {80, 0, 0};
    start(w.world, ow);
    screen_fx_update(w.world, 0.4f);
    const Image gotWorld = g.draw(w.world);
    ScreenFxOptions os = o;
    os.screen = {0.75f, 0.5f};
    FxScene sc;
    start(sc.world, os);
    screen_fx_update(sc.world, 0.4f);
    const Image gotScreen = g.draw(sc.world);
    CHECK(gotWorld.rgba == gotScreen.rgba);
}

TEST_CASE("screen fx: a heat haze ripples the picture sideways inside its region as the CPU computes") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    FxScene refScene;
    const Image ref = g.draw(refScene.world);
    const float aspect = float(ref.width) / float(ref.height);
    FxScene s;
    ScreenFxOptions o = opts(ScreenFxKind::HeatHaze, 2.0f);
    o.region = {0.5f, 0.0f, 0.5f, 1.0f};
    o.strength = 0.01f;
    o.frequency = 6.0f;
    start(s.world, o);
    screen_fx_update(s.world, 0.8f);
    const Image got = g.draw(s.world);
    const PostFx fx = fx_of(s.world);
    REQUIRE(fx.hazeCount == 1);
    const Diff d = compare(got, [&](int x, int y) {
        const Vec2 uv = uv_of(ref, x, y);
        return bilinear(ref, uv + render::haze_offset(fx, uv, aspect));
    });
    CHECK(d.mean < 0.006);
    // The left half, outside the region, is untouched.
    CHECK(compare(got, [&](int x, int y) { return texel(ref, x, y); }, 0, 150).max < 2.0f * kStep);
    // Inside it something moved (the stripe at x = 20 has edges).
    CHECK(compare(got, [&](int x, int y) { return texel(ref, x, y); }, 170, 320).max > 0.05f);
}

TEST_CASE("radial blur: the persistent effect and the pulse average the taps toward the centre, as the CPU computes") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    FxScene refScene;
    const Image ref = g.draw(refScene.world);
    auto taps_average = [&](const PostFx& fx, int x, int y) {
        Vec2 taps[32];
        const int n = render::radial_blur_taps(fx, uv_of(ref, x, y), taps);
        Vec3 sum{0, 0, 0};
        for (int i = 0; i < n; ++i) sum = sum + bilinear(ref, taps[i]);
        return n > 0 ? sum * (1.0f / float(n)) : texel(ref, x, y);
    };
    // PostProcess.radialBlur.
    FxScene s;
    PostProcess& p = s.world.add<PostProcess>(s.cam);
    p.radialBlurEnabled = true;
    p.radialBlurIntensity = 0.8f;
    p.radialBlurCenter = {0.3f, 0.6f};
    p.radialBlurSamples = 16;
    Image got = g.draw(s.world);
    CHECK(order_of(g) == std::vector<std::string>{"camera:0/game", "camera:0/post"});
    render::PostStack stack;
    stack.fx = p;
    stack.sources = 1;
    stack.mask = 1u << int(PostEffect::RadialBlur);
    PostFx fx = render::make_post_fx(stack, 0);
    REQUIRE(fx.radialBlur);
    CHECK(fx.radialSamples == 16);
    CHECK(fx.radialLength == doctest::Approx(0.8f * render::kRadialBlurStrength));
    Diff d = compare(got, [&](int x, int y) { return taps_average(fx, x, y); });
    CHECK(d.mean < 0.006);
    CHECK(compare(got, [&](int x, int y) { return texel(ref, x, y); }).mean > 0.003);  // it did blur
    // The point of the picture is not blurred: the first tap is the pixel and the others are at the centre's distance 0.
    const int cx = int(0.3f * 320.0f), cy = int(0.6f * 180.0f);
    CHECK(std::fabs(texel(got, cx, cy).x - texel(ref, cx, cy).x) < 0.02f);

    // The pulse without any PostProcess: the same blur, dying out over its time.
    FxScene q;
    ScreenFxOptions o = opts(ScreenFxKind::RadialBlur, 0.5f);
    o.screen = {0.3f, 0.6f};
    o.intensity = 0.8f;
    o.samples = 16;
    start(q.world, o);
    got = g.draw(q.world);
    PostFx pulse = fx_of(q.world);
    REQUIRE(pulse.radialBlur);
    CHECK(pulse.radialLength == doctest::Approx(fx.radialLength));
    d = compare(got, [&](int x, int y) { return taps_average(pulse, x, y); });
    CHECK(d.mean < 0.006);
    screen_fx_update(q.world, 0.25f);
    got = g.draw(q.world);
    pulse = fx_of(q.world);
    CHECK(pulse.radialLength < fx.radialLength * 0.5f);
    d = compare(got, [&](int x, int y) { return taps_average(pulse, x, y); });
    CHECK(d.mean < 0.006);
}

TEST_CASE(
    "screen fx: in a split screen an effect of one camera draws in its half only, every camera draws it in both") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    auto build = [](World& w, Entity& left, Entity& right) {
        left = make(w, "left", {0, 0, 0});
        auto& a = w.add<Camera>(left);
        a.viewport = {0, 0, 0.5f, 1};
        a.clearColor = Color{0.2f, 0.2f, 0.2f, 1};
        right = make(w, "right", {500, 0, 0});
        auto& b = w.add<Camera>(right);
        b.viewport = {0.5f, 0, 0.5f, 1};
        b.depth = 1;
        b.clearColor = Color{0.05f, 0.05f, 0.3f, 1};
        for (const float x : {0.0f, 500.0f}) {
            Entity e = make(w, "square", {x, 0, 0});
            auto& s = w.add<Shape2D>(e);
            s.shape = ShapeType::Rectangle;
            s.size = {50, 50};
            s.color = x == 0.0f ? Color{1, 0, 0, 1} : Color{0, 1, 0, 1};
        }
    };
    World refWorld;
    Entity l0, r0;
    build(refWorld, l0, r0);
    const Image ref = g.draw(refWorld);

    // A flash on the left camera only.
    World w;
    Entity left, right;
    build(w, left, right);
    ScreenFxOptions flash = opts(ScreenFxKind::Flash, 1.0f);
    flash.color = Color{1, 1, 1, 1};
    start(w, flash, left);
    Image img = g.draw(w);
    CHECK(compare(img, [](int, int) { return Vec3{1, 1, 1}; }, 0, 160).max < 2.0f * kStep);
    CHECK(compare(
              img, [&](int x, int y) { return texel(ref, x, y); }, 160, 320)
              .max < kStep);  // the right half is the one it was
    // The same effect aimed at the right camera: the left half is untouched.
    screen_fx_cancel(w, kNullEntity);
    start(w, flash, right);
    img = g.draw(w);
    CHECK(compare(img, [&](int x, int y) { return texel(ref, x, y); }, 0, 160).max < kStep);
    CHECK(compare(img, [](int, int) { return Vec3{1, 1, 1}; }, 160, 320).max < 2.0f * kStep);
    // A shockwave on the left camera: its centre is a fraction of ITS half.
    screen_fx_cancel(w, kNullEntity);
    ScreenFxOptions wave = opts(ScreenFxKind::Shockwave, 1.0f);
    wave.screen = {0.5f, 0.5f};
    wave.strength = 0.1f;
    wave.radius = 0.4f;
    wave.width = 0.2f;
    start(w, wave, left);
    screen_fx_update(w, 0.3f);
    img = g.draw(w);
    CHECK(compare(img, [&](int x, int y) { return texel(ref, x, y); }, 0, 160).max > 0.1f);
    CHECK(compare(img, [&](int x, int y) { return texel(ref, x, y); }, 160, 320).max < kStep);
    // Every camera: both halves.
    screen_fx_cancel(w, kNullEntity);
    start(w, flash);
    img = g.draw(w);
    CHECK(compare(img, [](int, int) { return Vec3{1, 1, 1}; }).max < 2.0f * kStep);
}
