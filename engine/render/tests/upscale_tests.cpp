// M76-P3a: the upscale stage (src/renderer_upscale.cpp, render_upscale.h) and the HUD drawn at the output resolution. Headless, on the test GPU,
// with a renderer of its own (like dof_motion_tests.cpp): the picture is read from capture(), the passes from the frame graph.
#include "test_util.h"

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <cstdlib>
#include <string>
#include <utility>
#include <vector>

#include "frame_graph.h"
#include "render_upscale.h"
#include "renderer_test_access.h"

using namespace fa;
using namespace fa::test;

namespace {

struct Own {
    Gfx& g;
    Renderer r;
    bool ok = false;
    std::string error;
    explicit Own(Gfx& gx, int samples = 1) : g(gx) {
        RendererDesc d;
        d.designWidth = 320;
        d.designHeight = 180;
        d.sampleCount = samples;
        d.headless = true;
        d.adoptContext = true;
        ok = r.init(d, g.gpu.environment(), &error);
    }
    ~Own() { r.shutdown(); }
    Own(const Own&) = delete;
    Own& operator=(const Own&) = delete;
    void frames(World& w, int n) {
        for (int i = 0; i < n; ++i) {
            r.begin_frame();
            r.render_world(w, 1.0f / 60.0f);
            r.end_frame();
            g.gpu.end_frame();
        }
    }
    Image draw(World& w) {
        r.begin_frame();
        r.render_world(w, 1.0f / 60.0f);
        r.end_frame();
        g.gpu.end_frame();
        Image img;
        std::string err;
        const bool captured = r.capture(img, &err);
        INFO("capture error: " << err);
        REQUIRE(captured);
        return img;
    }
    bool has_pass(const char* name) {
        const render::FrameGraph* graph = render::renderer_frame_graph(r);
        REQUIRE(graph != nullptr);
        const std::string tail = std::string("/") + name;  // a pass of a camera job is named "<job>/<pass>"
        for (const std::string& n : graph->order_names())
            if (n == name || (n.size() > tail.size() && n.compare(n.size() - tail.size(), tail.size(), tail) == 0))
                return true;
        return false;
    }
};

struct Ink {
    int x0 = 1 << 20, y0 = 1 << 20, x1 = -1, y1 = -1;
    bool any() const { return x1 >= x0; }
    int w() const { return x1 - x0 + 1; }
    int h() const { return y1 - y0 + 1; }
};
Ink ink(const Image& img, int rx0, int ry0, int rx1, int ry1, float threshold = 0.35f) {
    Ink k;
    for (int y = std::max(ry0, 0); y < std::min(ry1, img.height); ++y)
        for (int x = std::max(rx0, 0); x < std::min(rx1, img.width); ++x)
            if (img.pixel(x, y).r > threshold) {
                k.x0 = std::min(k.x0, x);
                k.y0 = std::min(k.y0, y);
                k.x1 = std::max(k.x1, x);
                k.y1 = std::max(k.y1, y);
            }
    return k;
}

void put_text(World& w, const char* name, Vec3 pos, RenderSpace space) {
    Entity e = make(w, name, pos);
    auto& t = w.add<Text>(e);
    t.text = "HHHH";
    t.fontSize = 20;
    t.space = space;
    t.pivot = {0, 1};
}

// A black picture with a HUD text at the top left (pixels 10 .. ~70, 10 .. ~25 of the design size) and a world text in the lower right.
struct Scene {
    World w;
    Scene() {
        w.add<Camera>(make(w, "cam")).clearColor = Color::black();
        put_text(w, "hud", {10, 10, 0}, RenderSpace::Screen);
        put_text(w, "world", {70, -30, 0}, RenderSpace::World);
    }
};

int max_diff(const Image& a, const Image& b) {
    REQUIRE(a.width == b.width);
    REQUIRE(a.height == b.height);
    int worst = 0;
    for (int y = 0; y < a.height; ++y)
        for (int x = 0; x < a.width; ++x) {
            const Color p = a.pixel(x, y), q = b.pixel(x, y);
            for (const float d : {p.r - q.r, p.g - q.g, p.b - q.b, p.a - q.a})
                worst = std::max(worst, int(std::abs(d) * 255.0f + 0.5f));
        }
    return worst;
}

}  // namespace

TEST_CASE("upscale stage: the selector knows 'stretch', 'spatial', 'temporal' and 'metalfx' and falls back to stretch "
          "for every "
          "other name") {
    bool known = true;
    CHECK(render::select_upscale_impl("stretch", &known) == render::UpscaleImpl::Stretch);
    CHECK(known);
    known = false;
    CHECK(render::select_upscale_impl("spatial", &known) == render::UpscaleImpl::Spatial);
    CHECK(known);
    known = false;
    CHECK(render::select_upscale_impl("temporal", &known) == render::UpscaleImpl::Temporal);  // M76-P4
    CHECK(known);
    known = false;
    CHECK(render::select_upscale_impl("metalfx", &known) == render::UpscaleImpl::MetalFx);  // M76-P5b
    CHECK(known);
    for (const char* name : {"", "bogus", "Stretch", "fsr2"}) {
        CAPTURE(name);
        known = true;
        CHECK(render::select_upscale_impl(name, &known) == render::UpscaleImpl::Stretch);
        CHECK_FALSE(known);
    }
    CHECK(render::select_upscale_impl("bogus") == render::UpscaleImpl::Stretch);  // `known` is optional
    CHECK(std::string(render::upscale_impl_name(render::UpscaleImpl::Stretch)) == "stretch");
    CHECK(std::string(render::upscale_impl_name(render::UpscaleImpl::Spatial)) == "spatial");
    CHECK(std::string(render::upscale_impl_name(render::UpscaleImpl::Temporal)) == "temporal");
    CHECK(std::string(render::upscale_impl_name(render::UpscaleImpl::MetalFx)) == "metalfx");
}

TEST_CASE("upscale stage: at scale 1 it is off, with no pass and no new picture, even when asked for") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    Own own(g);
    REQUIRE_MESSAGE(own.ok, own.error);
    Scene s;
    const Image before = own.draw(s.w);
    CHECK_FALSE(own.has_pass("upscale"));
    REQUIRE(ink(before, 0, 0, 140, 65).any());
    own.r.set_upscale_stage(true);
    CHECK(own.r.upscale_stage());
    const Image on = own.draw(s.w);
    CHECK_FALSE(own.has_pass("upscale"));
    CHECK_FALSE(own.has_pass("hud-over-upscale"));
    CHECK(on.width == 320);
    CHECK(on.height == 180);
    CHECK(max_diff(on, before) == 0);
}

TEST_CASE("upscale stage: at scale 0.5 the picture is the design size and the HUD text is as sharp as at scale 1") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    Own own(g);
    REQUIRE_MESSAGE(own.ok, own.error);
    Scene s;
    const Image full = own.draw(s.w);
    const Ink hudFull = ink(full, 0, 0, 140, 65);
    const Ink worldFull = ink(full, 220, 100, 320, 180);
    REQUIRE(hudFull.any());
    REQUIRE(worldFull.any());

    // Without the stage (the screenshot scale of the CLI): the image has the scaled size and the HUD is half as big.
    own.r.set_render_scale(0.5f);
    const Image small = own.draw(s.w);
    CHECK(small.width == 160);
    CHECK(small.height == 90);
    CHECK_FALSE(own.has_pass("upscale"));
    const Ink hudSmall = ink(small, 0, 0, 70, 33);
    REQUIRE(hudSmall.any());
    CHECK(std::abs(hudSmall.w() * 2 - hudFull.w()) <= 3);

    // With it: the design size, the world text from the smaller picture, the HUD text drawn at the output size.
    own.r.set_upscale_stage(true);
    const Image out = own.draw(s.w);
    CHECK(out.width == 320);
    CHECK(out.height == 180);
    CHECK(own.has_pass("upscale"));
    CHECK(own.has_pass("hud-over-upscale"));
    const Ink hudOut = ink(out, 0, 0, 140, 65);
    REQUIRE(hudOut.any());
    CHECK(hudOut.x0 == hudFull.x0);
    CHECK(hudOut.y0 == hudFull.y0);
    CHECK(hudOut.w() == hudFull.w());
    CHECK(hudOut.h() == hudFull.h());
    // Same glyph raster as at scale 1: the HUD part of the picture is identical (the world text is not in that corner).
    int worst = 0;
    for (int y = 0; y < 65; ++y)
        for (int x = 0; x < 140; ++x)
            worst = std::max(worst, int(std::abs(out.pixel(x, y).r - full.pixel(x, y).r) * 255.0f + 0.5f));
    CHECK(worst <= 2);
    // The world text is there, drawn at the lower resolution and scaled up (about the same place and size as at scale 1).
    const Ink worldOut = ink(out, 220, 100, 320, 180);
    REQUIRE(worldOut.any());
    CHECK(std::abs(worldOut.w() - worldFull.w()) <= 4);
    CHECK(std::abs(worldOut.x0 - worldFull.x0) <= 3);

    // Back to the whole picture at scale 1: no pass, the first picture.
    own.r.set_render_scale(1.0f);
    const Image again = own.draw(s.w);
    CHECK_FALSE(own.has_pass("upscale"));
    CHECK(max_diff(again, full) == 0);
}

// How many 2x2 blocks of the output (cells x0..x1, y0..y1 of the half size picture) are not one flat value.
int mixed_blocks(const Image& img, int x0, int y0, int x1, int y1) {
    int n = 0;
    for (int y = y0; y < y1; ++y)
        for (int x = x0; x < x1; ++x) {
            const float a = img.pixel(2 * x, 2 * y).r;
            for (const auto& d : {std::pair<int, int>{1, 0}, std::pair<int, int>{0, 1}, std::pair<int, int>{1, 1}})
                if (std::abs(a - img.pixel(2 * x + d.first, 2 * y + d.second).r) > 0.01f) {
                    ++n;
                    break;
                }
        }
    return n;
}

TEST_CASE("upscale stage: pixel-perfect scaling keeps hard pixel edges (Nearest), the default scaling is smooth") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    Own own(g);
    REQUIRE_MESSAGE(own.ok, own.error);
    own.r.set_render_scale(0.5f);
    own.r.set_upscale_stage(true);
    Scene s;
    // The world text (lower right, half size cells 110 .. 160 x 50 .. 90) is drawn at 160x90 and scaled by exactly 2: with Nearest every
    // 2x2 block of the output is one pixel of it. The HUD text is in the other corner, drawn at the output size.
    own.r.set_scale_mode(ScaleMode::PixelPerfect);
    const Image hard = own.draw(s.w);
    REQUIRE(own.has_pass("upscale"));
    REQUIRE(ink(hard, 220, 100, 320, 180).any());
    CHECK(mixed_blocks(hard, 110, 50, 160, 90) == 0);

    own.r.set_scale_mode(ScaleMode::Fit);
    const Image soft = own.draw(s.w);
    REQUIRE(own.has_pass("upscale"));
    CHECK(mixed_blocks(soft, 110, 50, 160, 90) > 20);
}

// The scene of the tests below with a bloom on its camera.
void add_bloom(Scene& s, bool screenSpace) {
    PostProcess& p = s.w.add<PostProcess>(s.w.find("cam"));
    p.bloomEnabled = true;
    p.bloomIntensity = 1.5f;
    p.bloomThreshold = 0.2f;
    p.bloomRadius = 12.0f;
    p.bloomScreenSpace = screenSpace;
}

// The picture of a half size image scaled up by two with a bilinear filter, as the stretch stage and the present draw it.
float bilinear_r(const Image& small, int x, int y) {
    const float fx = (float(x) + 0.5f) / 2.0f - 0.5f, fy = (float(y) + 0.5f) / 2.0f - 0.5f;
    const int x0 = int(std::floor(fx)), y0 = int(std::floor(fy));
    const float tx = fx - float(x0), ty = fy - float(y0);
    auto at = [&](int px, int py) {
        return small.pixel(std::clamp(px, 0, small.width - 1), std::clamp(py, 0, small.height - 1)).r;
    };
    return (at(x0, y0) * (1 - tx) + at(x0 + 1, y0) * tx) * (1 - ty) +
           (at(x0, y0 + 1) * (1 - tx) + at(x0 + 1, y0 + 1) * tx) * ty;
}

TEST_CASE("upscale stage: a HUD that glows (bloomScreenSpace) stays in the game image, as without the stage") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    Own own(g);
    REQUIRE_MESSAGE(own.ok, own.error);
    Scene s;
    add_bloom(s, true);
    own.r.set_render_scale(0.5f);
    const Image base = own.draw(s.w);  // no stage: 160x90, the HUD in the game image, glowing
    REQUIRE(base.width == 160);
    own.r.set_upscale_stage(true);
    const Image out = own.draw(s.w);
    CHECK(out.width == 320);
    CHECK(out.height == 180);
    CHECK(own.has_pass("upscale"));
    CHECK_FALSE(own.has_pass("hud-over-upscale"));
    // The same picture as the base one, scaled up: the HUD was drawn, glow included, at the render resolution. (The scene image may be
    // filtered in linear light, so the comparison is of the mean over the picture and of the HUD's size, not of every edge pixel.)
    double sum = 0.0;
    for (int y = 0; y < 180; ++y)
        for (int x = 0; x < 320; ++x) sum += std::abs(out.pixel(x, y).r - bilinear_r(base, x, y));
    CHECK(sum / (320.0 * 180.0) * 255.0 < 1.0);
    const Ink hudBase = ink(base, 0, 0, 70, 33);
    const Ink hudOutInk = ink(out, 0, 0, 140, 65);
    REQUIRE(hudBase.any());
    REQUIRE(hudOutInk.any());
    CHECK(std::abs(hudOutInk.w() - 2 * hudBase.w()) <= 3);  // blurred like the game, not sharp text at the output size
    // And it does glow: next to the HUD text the picture is lighter than the black clear colour.
    const Ink hud = ink(out, 0, 0, 140, 65);
    REQUIRE(hud.any());
    CHECK(out.pixel(hud.x1 + 3, (hud.y0 + hud.y1) / 2).r > 0.02f);
}

TEST_CASE(
    "upscale stage: a bloom that does not reach the HUD, or a final pass, leaves the HUD sharp at the output size") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    Own own(g);
    REQUIRE_MESSAGE(own.ok, own.error);
    Scene plain;
    const Image fullPlain = own.draw(plain.w);
    const Ink hudFull = ink(fullPlain, 0, 0, 140, 65);
    REQUIRE(hudFull.any());
    own.r.set_render_scale(0.5f);
    own.r.set_upscale_stage(true);
    for (const int mode :
         {0, 1, 2}) {  // 0: bloom, bloomScreenSpace false; 1: tonemap (a final pass); 2: no post at all
        CAPTURE(mode);
        Scene s;
        if (mode == 0) add_bloom(s, false);
        if (mode == 1) {
            PostProcess& p = s.w.add<PostProcess>(s.w.find("cam"));
            p.tonemapEnabled = true;
            p.bloomEnabled = true;  // a final pass: the HUD never glows, whatever bloomScreenSpace says
            p.bloomScreenSpace = true;
        }
        const Image out = own.draw(s.w);
        CHECK(out.width == 320);
        CHECK(own.has_pass("upscale"));
        CHECK(own.has_pass("hud-over-upscale"));
        const Ink hud = ink(out, 0, 0, 140, 65);
        REQUIRE(hud.any());
        CHECK(hud.x0 == hudFull.x0);
        CHECK(hud.w() == hudFull.w());
        CHECK(hud.h() == hudFull.h());
    }
}

// ---- M76 POL-UPSCALE: what the HUD at the output size decides, and the images it keeps ------------------------------------------------------

namespace {

// The worst difference of the red channel between two pictures over the HUD's corner (the first 140 x 65 pixels).
int corner_diff(const Image& a, const Image& b) {
    int worst = 0;
    for (int y = 0; y < 65; ++y)
        for (int x = 0; x < 140; ++x)
            worst = std::max(worst, int(std::abs(a.pixel(x, y).r - b.pixel(x, y).r) * 255.0f + 0.5f));
    return worst;
}

// The brightest pixel of the corner, whatever the channel.
float corner_peak(const Image& img) {
    float peak = 0.0f;
    for (int y = 0; y < 65; ++y)
        for (int x = 0; x < 140; ++x) {
            const Color p = img.pixel(x, y);
            peak = std::max(peak, std::max(p.r, std::max(p.g, p.b)));
        }
    return peak;
}

}  // namespace

TEST_CASE("upscale stage: a final pass and the colour filter reach the HUD at the output size, sharp, as at scale 1") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    Own own(g);
    REQUIRE_MESSAGE(own.ok, own.error);
    for (const bool linear : {false, true}) {
        CAPTURE(linear);
        Scene s;
        s.w.settings().colorSpace = linear ? ColorSpace::Linear : ColorSpace::Gamma;
        s.w.get<Text>(s.w.find("hud"))->color = Color{1, 0.2f, 0.1f, 1};
        PostProcess& p = s.w.add<PostProcess>(s.w.find("cam"));
        p.tonemapEnabled = true;
        p.colorFilterEnabled = true;
        p.colorFilterMode = ColorFilter::Greyscale;
        own.r.set_render_scale(1.0f);
        own.r.set_upscale_stage(false);
        const Image full = own.draw(s.w);
        own.r.set_render_scale(0.5f);
        own.r.set_upscale_stage(true);
        const Image out = own.draw(s.w);
        REQUIRE(out.width == 320);
        CHECK(own.has_pass("upscale"));
        CHECK(own.has_pass("hud-over-upscale"));
        CHECK(own.has_pass("output-color-filter"));  // after the items: the HUD is grey too
        REQUIRE(corner_peak(out) > 0.1f);
        // The filter reached the HUD: no pixel of the corner has a colour (grey: the three channels within the 8-bit noise).
        for (int y = 0; y < 65; ++y)
            for (int x = 0; x < 140; ++x) {
                const Color c = out.pixel(x, y);
                REQUIRE(std::abs(c.r - c.g) < 0.02f);
                REQUIRE(std::abs(c.g - c.b) < 0.02f);
            }
        CHECK(corner_diff(out, full) <= 3);  // the same glyph raster and the same pipeline as at scale 1
        const Ink a = ink(out, 0, 0, 140, 65, 0.1f), b = ink(full, 0, 0, 140, 65, 0.1f);
        REQUIRE(a.any());
        CHECK(a.x0 == b.x0);
        CHECK(a.w() == b.w());
        CHECK(a.h() == b.h());
    }
}

TEST_CASE("upscale stage: a split screen keeps the HUD at the output size, and a first camera with no pixel does not "
          "decide for "
          "the bloom of the second") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    Own own(g);
    REQUIRE_MESSAGE(own.ok, own.error);
    // Two halves, a HUD over both: sharp at the output size, in the same place as at scale 1.
    World split;
    for (int i = 0; i < 2; ++i) {
        Entity e = make(split, i == 0 ? "left" : "right", {0, 0, 0});
        auto& c = split.add<Camera>(e);
        c.viewport = {i == 0 ? 0.0f : 0.5f, 0, 0.5f, 1};
        c.clearColor = Color::black();
        c.depth = i;
    }
    put_text(split, "hud", {10, 10, 0}, RenderSpace::Screen);
    const Image full = own.draw(split);
    const Ink hudFull = ink(full, 0, 0, 140, 65);
    REQUIRE(hudFull.any());
    own.r.set_render_scale(0.5f);
    own.r.set_upscale_stage(true);
    const Image out = own.draw(split);
    CHECK(own.has_pass("hud-over-upscale"));
    const Ink hudOut = ink(out, 0, 0, 140, 65);
    REQUIRE(hudOut.any());
    CHECK(hudOut.x0 == hudFull.x0);
    CHECK(hudOut.w() == hudFull.w());
    CHECK(hudOut.h() == hudFull.h());

    // The bloom of the frame is the first camera that draws a pixel. A camera with an empty rectangle first and a glowing camera second
    // give the picture of the glowing camera alone: the HUD glows in the game image in both, there is no HUD pass over the upscale.
    own.r.set_render_scale(0.5f);
    Scene alone;
    add_bloom(alone, true);
    const Image ref = own.draw(alone.w);
    CHECK_FALSE(own.has_pass("hud-over-upscale"));
    Scene twice;
    add_bloom(twice, true);
    Entity empty = make(twice.w, "empty", {0, 0, 0});
    auto& ec = twice.w.add<Camera>(empty);
    ec.viewport = {0, 0, 0.0005f, 0.0005f};  // valid, but under half a pixel: draws nothing
    ec.depth = -5;                           // drawn first
    const Image two = own.draw(twice.w);
    CHECK_FALSE(own.has_pass("hud-over-upscale"));
    CHECK(max_diff(ref, two) <= 2);
}

TEST_CASE("upscale stage: a camera with a scene-colour effect and a glowing HUD keeps the HUD in the game image") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    Own own(g);
    REQUIRE_MESSAGE(own.ok, own.error);
    Scene s;
    add_bloom(s, true);
    PostProcess& p = *s.w.get<PostProcess>(s.w.find("cam"));
    p.depthOfFieldEnabled = true;
    own.r.set_render_scale(0.5f);
    const Image base = own.draw(s.w);
    own.r.set_upscale_stage(true);
    const Image out = own.draw(s.w);
    REQUIRE(out.width == 320);
    CHECK(own.has_pass("upscale"));
    CHECK_FALSE(own.has_pass("hud-over-upscale"));
    const Ink hudBase = ink(base, 0, 0, 70, 33), hudOut = ink(out, 0, 0, 140, 65);
    REQUIRE(hudBase.any());
    REQUIRE(hudOut.any());
    CHECK(std::abs(hudOut.w() - 2 * hudBase.w()) <= 3);  // drawn at the render resolution, as without the stage
}

TEST_CASE("upscale stage: the images at the output size are made for the items, the depth only when there are items, "
          "and they go "
          "when the stage is off") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    for (const int samples : {1, 4}) {
        CAPTURE(samples);
        Own own(g, samples);
        REQUIRE_MESSAGE(own.ok, own.error);
        // A world with no screen-space item.
        World w;
        w.add<Camera>(make(w, "cam")).clearColor = Color::black();
        put_text(w, "world", {70, -30, 0}, RenderSpace::World);
        const auto none = RendererTestAccess::output_targets(own.r);
        CHECK_FALSE(none.out);
        own.r.set_render_scale(0.5f);
        own.r.set_upscale_stage(true);
        (void)own.draw(w);
        const auto idle = RendererTestAccess::output_targets(own.r);
        CHECK(
            idle.out);  // made for the decision of the frame (the glyphs' size), before there is anything to draw in it
        CHECK_FALSE(idle.outDepth);
        CHECK(idle.outW == 320);
        CHECK(idle.outH == 180);
        CHECK(idle.outSamples == 1);  // the upscaled picture is a single-sample image, whatever the game image has
        CHECK_FALSE(idle.filter);
        // A HUD item appears: the depth image is made, and kept when the item goes away again.
        const Entity hud = make(w, "hud", {10, 10, 0});
        auto& t = w.add<Text>(hud);
        t.text = "HHHH";
        t.fontSize = 20;
        t.space = RenderSpace::Screen;
        t.pivot = {0, 1};
        const Image with = own.draw(w);
        CHECK(own.has_pass("hud-over-upscale"));
        CHECK(ink(with, 0, 0, 140, 65).any());
        CHECK(RendererTestAccess::output_targets(own.r).outDepth);
        w.destroy(hud);
        (void)own.draw(w);
        CHECK_FALSE(own.has_pass("hud-over-upscale"));
        CHECK(RendererTestAccess::output_targets(own.r).outDepth);
        // The colour filter after the items gets its own image.
        PostProcess& p = w.add<PostProcess>(w.find("cam"));
        p.colorFilterEnabled = true;
        p.colorFilterMode = ColorFilter::Greyscale;
        (void)own.draw(w);
        CHECK(RendererTestAccess::output_targets(own.r).out);
        // Back to the whole picture: nothing of the stage is kept (after the idle frames: see the case of the hysteresis below).
        own.r.set_render_scale(1.0f);
        own.frames(w, RendererTestAccess::output_idle_frames());
        const auto off = RendererTestAccess::output_targets(own.r);
        CHECK_FALSE(off.out);
        CHECK_FALSE(off.filter);
        CHECK_FALSE(off.spatial);
    }
}

TEST_CASE("upscale stage: a frame without the stage keeps the output images, the idle frames in a row free them") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    Own own(g);
    REQUIRE_MESSAGE(own.ok, own.error);
    World w;
    w.add<Camera>(make(w, "cam")).clearColor = Color::black();
    const int idle = RendererTestAccess::output_idle_frames();
    own.r.set_render_scale(0.5f, 0.5f);
    own.r.set_upscale_stage(true);
    own.frames(w, 2);
    REQUIRE(RendererTestAccess::output_targets(own.r).out);
    // A scale that crosses 1 for one frame (a dynamic resolution at its ceiling) keeps the image, and the count starts again.
    for (int round = 0; round < 3; ++round) {
        own.r.set_render_scale(1.0f, 0.5f);  // a dynamic step: only the render size moves
        own.frames(w, idle - 1);
        CHECK(RendererTestAccess::output_targets(own.r).out);
        own.r.set_render_scale(0.5f, 0.5f);
        own.frames(w, 1);
        CHECK(RendererTestAccess::output_targets(own.r).out);
    }
    own.r.set_render_scale(1.0f, 0.5f);  // a dynamic step: only the render size moves
    own.frames(w, idle - 1);
    CHECK(RendererTestAccess::output_targets(own.r).out);
    own.frames(w, 1);
    CHECK_FALSE(RendererTestAccess::output_targets(own.r).out);
}
