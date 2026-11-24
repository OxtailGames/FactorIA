// M74-P3b: the radiance cascades of the 2D GI field (engine/render/src/gi2d.h, gi2d.glsl, docs/rendering/RENDERING_2D_GI.md). Pure tests of
// what a quality means (counts, intervals, the platform budget), then tests that draw on the host's GPU and read the irradiance image back:
//   - an emitter lights the probes around it, the light falls off with the distance and an occluder shadows what is behind it;
//   - a coloured wall bounces the light (the first frame already, through the priming chain) and bounce 0 does not;
//   - the history of the bounce follows a camera that moves and starts again when the size changes;
//   - lit visuals get the light, unlit visuals are the same pixels with and without GlobalIllumination2D;
//   - golden: 2d_gi;
//   - the irradiance image (view 14) and the picture of fa_scene_color (view 15) are bound in the same draw: a sprite material that reads the
//     scene colour in a scene with GI copies the GI-lit picture, and without GI it draws as before.
// On GLCORE, D3D11 and Metal the RGBA16F targets are REQUIRED (Own::gi_ready); only a GLES3-class GPU without them skips.
#include "fa/core/engine_version.h"
#include "test_util.h"

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <filesystem>
#include <fstream>
#include <string>
#include <vector>

#include "fa/core/json.h"

#include "frame_graph.h"
#include "gi2d.h"
#include "render_internal.h"
#include "renderer_test_access.h"

using namespace fa;
using namespace fa::test;
using namespace fa::render;

namespace {

struct Own {
    Gfx& g;
    Renderer r;
    bool ok = false;
    std::string error;
    explicit Own(Gfx& gx) : g(gx) {
        RendererDesc d;
        d.designWidth = 320;
        d.designHeight = 180;
        d.sampleCount = 1;
        d.headless = true;
        d.adoptContext = true;
        ok = r.init(d, g.gpu.environment(), &error);
    }
    ~Own() { r.shutdown(); }
    Own(const Own&) = delete;
    Own& operator=(const Own&) = delete;
    void frame(World& w, int n = 1) {
        for (int i = 0; i < n; ++i) {
            r.begin_frame();
            r.render_world(w, 0.0f);
            r.end_frame();
            g.gpu.end_frame();
        }
    }
    bool gi_ready() {
        REQUIRE(renderer_gpu(r)->has_device());
        const gpu::Device& dev = renderer_gpu(r)->device();
        const bool have = Gi2dSystem::float_targets_ok(dev);
        const gpu::Backend b = dev.backend();
        if (b == gpu::Backend::Gl || b == gpu::Backend::D3d11 || b == gpu::Backend::Metal) {
            INFO("this backend must have RGBA16F render targets that blend and filter");
            REQUIRE(have);
        }
        if (!have) MESSAGE("no RGBA16F targets on this GPU: the cascades are not drawn here");
        return have;
    }
};

void write_white() {
    Image white;
    white.width = white.height = 16;
    white.rgba.assign(16 * 16 * 4, 255);
    REQUIRE(save_png(white, "assets/white16.png").ok());
}

Entity camera_at(World& w, Vec3 pos) {
    Entity e = make(w, "cam", pos);
    w.add<Camera>(e).clearColor = Color{0, 0, 0, 1};
    return e;
}

Entity add_gi(World& w, GI2DQuality q, float bounce, float range = 32.0f, float intensity = 1.0f) {
    Entity e = make(w, "gi", {0, 0, 0});
    auto& gi = w.add<GlobalIllumination2D>(e);
    gi.quality = q;
    gi.bounce = bounce;
    gi.range = range;
    gi.intensity = intensity;
    gi.resolutionScale = 1.0f;  // one texel a world unit in the 320 x 180 test view
    return e;
}

Entity glow(World& w, const char* name, Vec3 pos, Vec2 size, Color emissive, float power, bool lit = false) {
    Entity e = make(w, name, pos);
    auto& s = w.add<Sprite>(e);
    s.texture = "assets/white16.png";
    s.size = size;
    s.lit = lit;
    s.color = Color{0, 0, 0, 1};
    s.emissive = emissive;
    s.emissiveIntensity = power;
    return e;
}

// A wall: a sprite of `color` that is also a shadow caster, so the occluder image holds its colour as the albedo.
Entity wall(World& w, const char* name, Vec3 pos, Vec2 size, Color color) {
    Entity e = make(w, name, pos);
    auto& s = w.add<Sprite>(e);
    s.texture = "assets/white16.png";
    s.size = size;
    s.color = color;
    s.lit = true;
    auto& sc = w.add<ShadowCaster2D>(e);
    sc.shape = ShadowCaster2DShape::Box;
    sc.size = size;
    return e;
}

struct Irr {
    std::vector<float> px;
    int w = 0, h = 0, spacing = 0;
    double texel = 1.0, ox = 0.0, oy = 0.0;
    // The probe that holds the world point (rgb premultiplied by the validity in a).
    const float* at(double wx, double wy) const {
        const int i = std::clamp(int(std::floor((wx - ox) / (texel * spacing))), 0, w - 1);
        const int j = std::clamp(int(std::floor((wy - oy) / (texel * spacing))), 0, h - 1);
        return &px[(std::size_t(j) * std::size_t(w) + std::size_t(i)) * 4];
    }
    // The light at a world point as the visuals read it: rgb divided by the validity.
    float channel(double wx, double wy, int c) const {
        const float* p = at(wx, wy);
        return p[3] > 0.02f ? p[c] / p[3] : 0.0f;
    }
};

bool read_irr(Own& o, Irr& out) {
    const Gi2dFieldInfo info = renderer_gi2d_info(o.r, 0);
    if (!info.ready || !info.irradianceReady) return false;
    out.w = info.irradianceWidth;
    out.h = info.irradianceHeight;
    out.spacing = info.probeSpacing;
    out.texel = info.texel;
    out.ox = info.originX;
    out.oy = info.originY;
    std::string error;
    const bool ok = renderer_gi2d_read(o.r, 0, 3, out.px, &error);
    INFO("read error: " << error);
    return ok && out.px.size() == std::size_t(out.w) * std::size_t(out.h) * 4;
}

int cascade_passes(Own& o, const char* what) {
    const FrameGraph* graph = renderer_frame_graph(o.r);
    int n = 0;
    if (!graph) return 0;
    for (const std::string& name : graph->order_names())
        if (name.find(what) != std::string::npos) ++n;
    return n;
}

Gi2dGeometry geometry_of(float w, float h, float range, float scale = 1.0f) {
    Gi2dSettings s;
    s.on = true;
    s.range = range;
    s.resolutionScale = scale;
    return gi2d_geometry(Rect{-w / 2, -h / 2, w, h}, 1.0f, s);
}

double color_diff(const Image& a, const Image& b) {
    REQUIRE(a.width == b.width);
    REQUIRE(a.height == b.height);
    double worst = 0.0;
    for (int y = 0; y < a.height; ++y)
        for (int x = 0; x < a.width; ++x) {
            const Color p = a.pixel(x, y), q = b.pixel(x, y);
            worst = std::max(
                {worst, double(std::fabs(p.r - q.r)), double(std::fabs(p.g - q.g)), double(std::fabs(p.b - q.b))});
        }
    return worst;
}

}  // namespace

TEST_CASE("gi2d cascades: a quality is a set of counts, the same on every machine") {
    const Gi2dQualityCounts low = gi2d_quality_counts(GI2DQuality::Low), med = gi2d_quality_counts(GI2DQuality::Medium),
                            high = gi2d_quality_counts(GI2DQuality::High);
    CHECK(low.spacing0 == 4);
    CHECK(low.cascades == 3);
    CHECK(med.spacing0 == 2);
    CHECK(med.cascades == 4);
    CHECK(high.spacing0 == 2);
    CHECK(high.cascades == 5);
    CHECK(low.steps < med.steps);
    CHECK(med.steps < high.steps);
    // The cascades of a field of 416 x 256 texels (a 320 x 180 view, range 32, one texel a unit).
    const Gi2dGeometry g = geometry_of(320, 180, 32);
    REQUIRE(g.valid);
    CHECK(g.width == 416);
    CHECK(g.height == 256);
    for (GI2DQuality q : {GI2DQuality::Low, GI2DQuality::Medium, GI2DQuality::High}) {
        const Gi2dCascadePlan p = gi2d_cascade_plan(q, g, false);
        REQUIRE(p.ok);
        const Gi2dQualityCounts c = gi2d_quality_counts(q);
        CHECK(p.cascades == c.cascades);  // 488 texels across: every quality uses all its cascades here
        CHECK(p.rays0 == c.spacing0 * c.spacing0);
        CHECK(p.gridW * p.spacing0 == g.width);
        CHECK(p.gridH * p.spacing0 == g.height);
        // The largest probe spacing divides the field, and the intervals follow each other.
        CHECK(g.width % (p.spacing0 << (p.cascades - 1)) == 0);
        CHECK(p.interval_start(0) == 0.0);
        for (int i = 1; i < p.cascades; ++i) CHECK(p.interval_start(i) == p.interval_end(i - 1));
        for (int i = 1; i < p.cascades; ++i) CHECK(p.interval_end(i) > p.interval_end(i - 1) * 3.9);
        CHECK(p.totalBytes <= kGi2dMaxBytes);
    }
    // A small field needs fewer cascades than the quality allows: the last interval already covers its diagonal.
    const Gi2dCascadePlan small = gi2d_cascade_plan(GI2DQuality::High, geometry_of(8, 8, 1), false);
    REQUIRE(small.ok);
    CHECK(small.cascades < 5);
    CHECK(small.reach >= std::hypot(double(geometry_of(8, 8, 1).width), double(geometry_of(8, 8, 1).height)));
}

TEST_CASE("gi2d cascades: over the platform's budget the plan says so and teaches") {
    const Gi2dGeometry g = geometry_of(320, 180, 32);
    // High needs five cascade passes: a phone or a browser budgets four.
    const Gi2dCascadePlan phoneHigh = gi2d_cascade_plan(GI2DQuality::High, g, true);
    CHECK_FALSE(phoneHigh.ok);
    CHECK(phoneHigh.why.find("quality") != std::string::npos);
    CHECK(phoneHigh.why.find("medium") != std::string::npos);
    CHECK(gi2d_cascade_plan(GI2DQuality::Medium, g, true).ok);
    // A big field costs more memory than a phone budgets, the same field is fine on a desktop GPU.
    const Gi2dGeometry big = geometry_of(1920, 1080, 256, 1.0f);
    REQUIRE(big.valid);
    const Gi2dCascadePlan phoneBig = gi2d_cascade_plan(GI2DQuality::Low, big, true);
    CHECK_FALSE(phoneBig.ok);
    CHECK(phoneBig.why.find("MiB") != std::string::npos);
    CHECK(phoneBig.why.find("resolutionScale") != std::string::npos);
    CHECK(gi2d_cascade_plan(GI2DQuality::Low, big, false).ok);
    // The largest field a desktop makes (2048 x 2048) is inside the desktop budget with every image counted.
    const Gi2dGeometry cap = geometry_of(100000, 100000, 100000, 1.0f);
    REQUIRE(cap.valid);
    CHECK(cap.width == kGi2dMaxSize);
    CHECK(gi2d_cascade_plan(GI2DQuality::High, cap, false).ok);
    CHECK_FALSE(gi2d_cascade_plan(GI2DQuality::Medium, Gi2dGeometry{}, false).ok);
}

TEST_CASE("gi2d cascades: an emitter lights the probes around it, less far away, and an occluder casts a shadow") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    Own o(g);
    REQUIRE(o.ok);
    if (!o.gi_ready()) return;
    write_white();
    World w;
    camera_at(w, {0, 0, 0});
    add_gi(w, GI2DQuality::Medium, 0.0f);
    glow(w, "lamp", {-100, 0, 0}, {16, 16}, Color{1, 0, 0, 1}, 4.0f);
    wall(w, "wall", {0, 0, 0}, {6, 80}, Color{0.5f, 0.5f, 0.5f, 1});
    o.frame(w);
    const Gi2dFieldInfo info = renderer_gi2d_info(o.r, 0);
    REQUIRE(info.ready);
    CHECK(info.cascades == 4);
    CHECK(info.probeSpacing == 2);
    Irr irr;
    REQUIRE(read_irr(o, irr));
    CHECK(irr.w == 208);
    CHECK(irr.h == 128);
    const float near = irr.channel(-80, 0, 0), mid = irr.channel(-50, 0, 0), farther = irr.channel(-20, 0, 0);
    INFO("red at x = -80: " << near << ", -50: " << mid << ", -20: " << farther);
    CHECK(near > 0.05f);
    CHECK(near > mid);
    CHECK(mid > farther);
    CHECK(farther > 0.0f);
    // The light is red: no green or blue comes out of nothing.
    CHECK(irr.channel(-80, 0, 1) < 0.01f);
    CHECK(irr.channel(-80, 0, 2) < 0.01f);
    // Behind the wall (at x = +40) the lamp is hidden: the same distance from the lamp but above the wall's end is lit, the point behind is not.
    const float open = irr.channel(40, 70, 0), hidden = irr.channel(40, 0, 0);
    INFO("red at (40, 70): " << open << ", behind the wall (40, 0): " << hidden);
    CHECK(open > 0.003f);
    CHECK(hidden < open * 0.5f);
    // The pass names: one per cascade, the irradiance, and no priming chain (bounce is 0).
    CHECK(cascade_passes(o, "/gi-cascade-") == 4);
    CHECK(cascade_passes(o, "/gi-irradiance") == 1);
    CHECK(cascade_passes(o, "/gi-prime") == 0);
    CHECK_FALSE(info.primed);
}

TEST_CASE("gi2d cascades: a coloured wall bounces the light (the first frame already) and bounce 0 does not") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    Own o(g);
    REQUIRE(o.ok);
    if (!o.gi_ready()) return;
    write_white();
    World w;
    camera_at(w, {0, 0, 0});
    Entity gi = add_gi(w, GI2DQuality::Medium, 1.0f);
    glow(w, "lamp", {-100, 0, 0}, {16, 16}, Color{1, 1, 1, 1}, 4.0f);
    wall(w, "wall", {-40, 0, 0}, {10, 90}, Color{0, 1, 0, 1});
    // The probe in front of the wall, on the lamp's side, between them: direct white light plus the wall's green.
    auto ratio = [&](const Irr& irr) {
        const double r = irr.channel(-60, 0, 0), gr = irr.channel(-60, 0, 1);
        INFO("at (-60, 0): red " << r << ", green " << gr);
        return gr / std::max(r, 1e-6);
    };
    o.frame(w);  // the first frame: no history, so the priming chain runs
    Gi2dFieldInfo info = renderer_gi2d_info(o.r, 0);
    REQUIRE(info.ready);
    CHECK(info.primed);
    CHECK(cascade_passes(o, "/gi-prime-cascade-") == 4);
    Irr first;
    REQUIRE(read_irr(o, first));
    CHECK(first.channel(-60, 0, 0) > 0.05f);
    CHECK(ratio(first) > 1.03);  // the wall adds green to the white of the lamp
    o.frame(w, 3);
    info = renderer_gi2d_info(o.r, 0);
    CHECK_FALSE(info.primed);  // the history of the last frame is there
    CHECK(cascade_passes(o, "/gi-prime") == 0);
    Irr later;
    REQUIRE(read_irr(o, later));
    CHECK(ratio(later) > 1.03);
    // Without bounce the wall only blocks: red, green and blue are what the lamp gives.
    w.get<GlobalIllumination2D>(gi)->bounce = 0.0f;
    o.frame(w, 2);
    Irr none;
    REQUIRE(read_irr(o, none));
    CHECK(std::fabs(ratio(none) - 1.0) < 0.02);
}

TEST_CASE(
    "gi2d cascades: the history follows a camera that moves by whole texels and starts again when the size changes") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    Own o(g);
    REQUIRE(o.ok);
    if (!o.gi_ready()) return;
    write_white();
    World w;
    Entity cam = camera_at(w, {0, 0, 0});
    Entity gi = add_gi(w, GI2DQuality::Low, 0.5f);
    glow(w, "lamp", {-100, 0, 0}, {16, 16}, Color{1, 1, 1, 1}, 4.0f);
    wall(w, "wall", {-40, 0, 0}, {10, 90}, Color{0, 1, 0, 1});
    o.frame(w, 3);
    Irr a;
    REQUIRE(read_irr(o, a));
    const float before = a.channel(-60, 0, 1);
    REQUIRE(before > 0.02f);
    // The camera moves 20 units: the same world point gives the same light (no flicker, no priming).
    w.get<Transform>(cam)->position = Vec3{20, 0, 0};
    o.frame(w);
    Gi2dFieldInfo info = renderer_gi2d_info(o.r, 0);
    REQUIRE(info.ready);
    CHECK_FALSE(info.primed);
    Irr b;
    REQUIRE(read_irr(o, b));
    const float after = b.channel(-60, 0, 1);
    INFO("green at (-60, 0) before the move: " << before << ", after: " << after);
    CHECK(after == doctest::Approx(before).epsilon(0.25));
    // A zoom out to 1.5 times the view changes the texel (1 -> 1.5 world units: the history was made for another texel size, so it cannot be
    // shifted by whole texels) and with it the size: the bounce starts from nothing.
    const double texelBefore = info.texel;
    w.get<Camera>(cam)->orthoSize = 135.0f;  // from 90 (the design height / 2)
    o.frame(w);
    info = renderer_gi2d_info(o.r, 0);
    REQUIRE(info.ready);
    CHECK(info.texel == doctest::Approx(texelBefore * 1.5));
    CHECK(info.primed);
    o.frame(w);
    CHECK_FALSE(renderer_gi2d_info(o.r, 0).primed);
    // A larger range changes the size of the field and NOT the texel: the images are made again all the same, so the history is gone.
    const Gi2dFieldInfo small = renderer_gi2d_info(o.r, 0);
    w.get<GlobalIllumination2D>(gi)->range = 160.0f;
    o.frame(w);
    info = renderer_gi2d_info(o.r, 0);
    REQUIRE(info.ready);
    CHECK(info.texel == small.texel);
    CHECK((info.width != small.width || info.height != small.height));
    CHECK(info.primed);
    o.frame(w);
    CHECK_FALSE(renderer_gi2d_info(o.r, 0).primed);
}

TEST_CASE("gi2d cascades: a camera that takes the slot of another one does not inherit its history") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    Own o(g);
    REQUIRE(o.ok);
    if (!o.gi_ready()) return;
    write_white();
    World w;
    Entity first = camera_at(w, {0, 0, 0});
    Entity second = camera_at(w, {0, 0, 0});
    w.get<Camera>(second)->clear = false;
    add_gi(w, GI2DQuality::Low, 0.5f);
    glow(w, "lamp", {-100, 0, 0}, {16, 16}, Color{1, 1, 1, 1}, 4.0f);
    wall(w, "wall", {-40, 0, 0}, {10, 90}, Color{0, 1, 0, 1});
    o.frame(w, 3);
    CHECK(renderer_gi2d_slots_in_use(o.r) == 2);
    CHECK_FALSE(renderer_gi2d_info(o.r, 0).primed);
    // The first camera goes away: the second one is now job "camera:0" and takes slot 0, with a field of the same size and texel but made
    // for another job. Its history is not its own light.
    w.get<Camera>(first)->primary = false;
    o.frame(w);
    CHECK(renderer_gi2d_slots_in_use(o.r) == 1);
    const Gi2dFieldInfo info = renderer_gi2d_info(o.r, 0);
    REQUIRE(info.ready);
    CHECK(info.primed);
    o.frame(w);
    CHECK_FALSE(renderer_gi2d_info(o.r, 0).primed);
}

TEST_CASE("gi2d cascades: a closed box with bounce 1 and white walls stays bounded (the loop gain is capped)") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    Own o(g);
    REQUIRE(o.ok);
    if (!o.gi_ready()) return;
    write_white();
    World w;
    camera_at(w, {0, 0, 0});
    add_gi(w, GI2DQuality::Medium, 1.0f);
    const Color white{1, 1, 1, 1};
    glow(w, "lamp", {0, 0, 0}, {8, 8}, white, 2.0f);
    wall(w, "left", {-60, 0, 0}, {10, 100}, white);
    wall(w, "right", {60, 0, 0}, {10, 100}, white);
    wall(w, "top", {0, 45, 0}, {130, 10}, white);
    wall(w, "bottom", {0, -45, 0}, {130, 10}, white);
    auto brightest = [&]() {
        Irr irr;
        REQUIRE(read_irr(o, irr));
        float best = 0.0f;
        for (std::size_t i = 0; i + 3 < irr.px.size(); i += 4) {
            if (irr.px[i + 3] <= 0.02f) continue;
            for (int c = 0; c < 3; ++c) {
                const float v = irr.px[i + std::size_t(c)] / irr.px[i + 3];
                REQUIRE(std::isfinite(v));
                best = std::max(best, v);
            }
        }
        return best;
    };
    o.frame(w, 60);
    const float at60 = brightest();
    o.frame(w, 90);
    const float at150 = brightest();
    INFO("brightest probe after 60 frames: " << at60 << ", after 150: " << at150);
    CHECK(at60 > 0.05f);
    // The lamp gives at most 2 to a probe; with a loop gain of at most kGi2dMaxBounceGain the light settles under 2 / (1 - gain) = 40.
    CHECK(at150 < 2.0f / (1.0f - kGi2dMaxBounceGain) + 1.0f);
    // And it has settled: a gain of 1 would keep growing by the same amount every frame.
    CHECK(at150 < at60 * 1.5f);
}

TEST_CASE("gi2d cascades: a lit visual in screen space is not touched by the GI (its coordinates are pixels, not the "
          "world)") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    {
        Own probe(g);
        REQUIRE(probe.ok);
        if (!probe.gi_ready()) return;
    }
    write_white();
    auto build = [&](World& w, bool gi) {
        camera_at(w, {0, 0, 0});
        w.settings().ambientLight = Color{0.2f, 0.2f, 0.2f, 1};
        if (gi) add_gi(w, GI2DQuality::Medium, 0.5f, 64.0f, 2.0f);
        glow(w, "lamp", {60, -20, 0}, {30, 30}, Color{1, 0.5f, 0.2f, 1}, 6.0f);
        // Covers the whole screen, drawn in the screen group: its world_xy are screen pixels, which land inside the field of the world.
        Entity hud = make(w, "hud", {160, 90, 0});
        auto& s = w.add<Sprite>(hud);
        s.space = RenderSpace::Screen;
        s.texture = "assets/white16.png";
        s.size = {400, 300};
        s.color = Color{0.7f, 0.7f, 0.7f, 1};
        s.lit = true;
    };
    World withGi, without;
    build(withGi, true);
    build(without, false);
    CHECK(color_diff(g.render(withGi), g.render(without)) == 0.0);
}

TEST_CASE("gi2d cascades: lit visuals get the light, unlit visuals are the same pixels with and without GI") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    {
        Own probe(g);
        REQUIRE(probe.ok);
        if (!probe.gi_ready()) return;
    }
    write_white();
    auto build = [&](World& w, bool gi, bool lit) {
        camera_at(w, {0, 0, 0});
        w.settings().ambientLight = Color{0.1f, 0.1f, 0.1f, 1};
        if (gi) add_gi(w, GI2DQuality::Medium, 0.5f, 64.0f);
        glow(w, "lamp", {-60, 0, 0}, {20, 20}, Color{1, 0.4f, 0.2f, 1}, 3.0f, lit);
        Entity floor = make(w, "floor", {40, 0, 0});
        auto& s = w.add<Sprite>(floor);
        s.layer = -1;
        s.texture = "assets/white16.png";
        s.size = {120, 100};
        s.color = Color{0.8f, 0.8f, 0.8f, 1};
        s.lit = lit;
    };
    World withGi, without;
    build(withGi, true, false);
    build(without, false, false);
    const Image unlitA = g.render(withGi);
    const Image unlitB = g.render(without);
    CHECK(color_diff(unlitA, unlitB) == 0.0);  // nothing unlit receives GI: the same pixels
    World litGi, litNo;
    build(litGi, true, true);
    build(litNo, false, true);
    const Image a = g.render(litGi);
    const Image b = g.render(litNo);
    // Near the lamp the lit floor is brighter and warmer with GI (the lamp is at x = -60, the floor from x = -20).
    const Color pa = a.pixel(160 + 5, 90), pb = b.pixel(160 + 5, 90);
    INFO("lit floor with GI: " << pa.r << " " << pa.g << " " << pa.b << ", without: " << pb.r << " " << pb.g << " "
                               << pb.b);
    CHECK(pa.r > pb.r + 0.01f);
    CHECK(pa.r - pb.r > pa.b - pb.b);  // the lamp is orange
}

TEST_CASE("gi2d cascades: golden - a lamp, a coloured wall and a dark room lit by bounced light") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    {
        Own probe(g);
        REQUIRE(probe.ok);
        if (!probe.gi_ready()) return;
    }
    write_white();
    World w;
    camera_at(w, {0, 0, 0});
    w.settings().ambientLight =
        Color{0.1f, 0.1f, 0.14f, 1};  // the walls show: the inside of a solid receives only the ambient light
    add_gi(w, GI2DQuality::Medium, 0.8f, 96.0f, 1.2f);
    Entity floor = make(w, "floor", {0, 0, 0});
    auto& fs = w.add<Sprite>(floor);
    fs.layer = -1;  // behind the lamps and walls (equal layers sort by y)
    fs.texture = "assets/white16.png";
    fs.size = {320, 180};
    fs.color = Color{0.6f, 0.6f, 0.6f, 1};
    fs.lit = true;
    glow(w, "lamp", {-90, 20, 0}, {14, 14}, Color{1.0f, 0.85f, 0.6f, 1}, 4.0f);
    glow(w, "blue", {100, -50, 0}, {10, 10}, Color{0.3f, 0.5f, 1.0f, 1}, 3.0f);
    wall(w, "green", {-20, 10, 0}, {10, 90}, Color{0.2f, 0.9f, 0.3f, 1});
    wall(w, "red", {40, -40, 0}, {90, 10}, Color{0.9f, 0.2f, 0.2f, 1});
    // The first frame draws the whole picture (the priming chain gives the bounce), so one frame is what the golden shows.
    GoldenLimits limits;
    limits.maxMeanError = 0.012;
    limits.maxDifferingShare = 0.12;
    limits.maxPixelError = 0.5;
    expect_golden(g.render(w), "2d_gi", limits);
}

TEST_CASE("gi2d cascades: the irradiance (view 14) and the scene colour (view 15) are bound together in one draw") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    {
        Own probe(g);
        REQUIRE(probe.ok);
        if (!probe.gi_ready()) return;
    }
    write_white();
    MaterialScope scope;
    // A lit floor next to an orange lamp, and on it an unlit sprite whose material (sprite_scene, amount 1, no shift) shows the picture
    // drawn so far: the floor under it. With GI that floor is lit by the cascades, so the material must show the GI-lit floor.
    auto build = [&](World& w, bool gi, bool material) {
        camera_at(w, {0, 0, 0});
        w.settings().ambientLight = Color{0.1f, 0.1f, 0.1f, 1};
        if (gi) add_gi(w, GI2DQuality::Medium, 0.5f, 64.0f);
        glow(w, "lamp", {-60, 0, 0}, {20, 20}, Color{1, 0.4f, 0.2f, 1}, 3.0f, false);
        Entity floor = make(w, "floor", {40, 0, 0});
        auto& s = w.add<Sprite>(floor);
        s.layer = -1;
        s.texture = "assets/white16.png";
        s.size = {120, 100};
        s.color = Color{0.8f, 0.8f, 0.8f, 1};
        s.lit = true;
        if (material) {
            Entity m = make(w, "mirror", {0, 20, 0});
            auto& ms = w.add<Sprite>(m);
            ms.layer = 5;
            ms.texture = "assets/white16.png";
            ms.size = {20, 20};
            ms.color = Color{0.3f, 0.6f, 0.9f, 1};
            ms.material = "materials/sprite_scene.material.json";
            ms.materialParams = Json::object({{"amount", 1.0}});
        }
    };
    auto near_color = [](const Color& a, const Color& b) {
        return std::fabs(a.r - b.r) <= 0.05f && std::fabs(a.g - b.g) <= 0.05f && std::fabs(a.b - b.b) <= 0.05f;
    };
    // The material's centre is the world point (0, 20): the pixel (160, 70) of the 320 x 180 target.
    const int cx = 160, cy = 70;
    World withGi, floorGiOnly, withoutGi, floorOffOnly;
    build(withGi, true, true);
    build(floorGiOnly, true, false);
    build(withoutGi, false, true);
    build(floorOffOnly, false, false);
    const Image matGi = g.render(withGi);
    CHECK(g.renderer.stats().sceneCopies == 1);
    const Image floorGi = g.render(floorGiOnly);
    const Image matOff = g.render(withoutGi);
    CHECK(g.renderer.stats().sceneCopies == 1);
    const Image floorOff = g.render(floorOffOnly);
    const Color a = matGi.pixel(cx, cy), fa = floorGi.pixel(cx, cy), b = matOff.pixel(cx, cy),
                fb = floorOff.pixel(cx, cy);
    INFO("material with GI " << a.r << " " << a.g << " " << a.b << ", floor with GI " << fa.r << " " << fa.g << " "
                             << fa.b);
    INFO("material without GI " << b.r << " " << b.g << " " << b.b << ", floor without GI " << fb.r << " " << fb.g
                                << " " << fb.b);
    // The GI is bound: the lit floor is brighter and warmer with it than without.
    CHECK(fa.r > fb.r + 0.01f);
    // The scene colour is bound too, and it is the picture with the GI in it (not the irradiance image, not a white image).
    CHECK(near_color(a, fa));
    // With GI off the material still shows the floor as before.
    CHECK(near_color(b, fb));
}
