// M75.4b: the renderer follows the floating origin (src/renderer_origin.cpp; docs/BIG_WORLDS.md "Floating origin"). A rebase moves every local
// position of the world by -offset; what the renderer keeps in world space across frames moves with it, so the frame of the rebase draws
// what the frame without it would have drawn. The tests compare pictures with a tolerance and read counters (no golden: they run on every
// backend):
//   - the camera the motion blur reprojects from moves with the world (the matrix, and the picture of a motion-blur scene);
//   - the shadow cascades and the 2D GI field snap in absolute space, so a shift is a whole number of texels;
//   - the 2D GI history and the realtime GI grid are kept, not started again;
//   - the renderer is an observer of the world it draws and of no other, in whatever order the two are destroyed.
#include "test_util.h"

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <memory>
#include <string>
#include <vector>

#include "fa/core/json.h"

#include "gi2d.h"
#include "render_internal.h"
#include "renderer_test_access.h"
#include "shadow_cascades.h"

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
    Image draw(World& w) {
        frame(w);
        Image img;
        std::string err;
        const bool captured = r.capture(img, &err);
        INFO("capture error: " << err);
        REQUIRE(captured);
        return img;
    }
};

// How many pixels differ by more than `tol` (0..255) in any channel. Positions 4 km out are floats of half a millimetre, so a hard edge may
// land a hundredth of a pixel away and flip a pixel on either side of a cube: a handful of pixels are allowed to differ, a smear is
// thousands.
int differing_pixels(const Image& a, const Image& b, int tol = 24) {
    REQUIRE(a.width == b.width);
    REQUIRE(a.height == b.height);
    int n = 0;
    for (std::size_t p = 0; p + 3 < a.rgba.size() && p + 3 < b.rgba.size(); p += 4) {
        int worst = 0;
        for (std::size_t c = 0; c < 4; ++c) worst = std::max(worst, std::abs(int(a.rgba[p + c]) - int(b.rgba[p + c])));
        if (worst > tol) ++n;
    }
    return n;
}

// How many pixels of the row are neither black nor white: the width of the soft edges (a blurred bar has many, a sharp one has none or one).
int soft_pixels(const Image& img, int y, int x0, int x1) {
    int n = 0;
    for (int x = x0; x < x1; ++x) {
        const float v = img.pixel(x, y).r;
        if (v > 0.08f && v < 0.92f) ++n;
    }
    return n;
}

constexpr float kFar =
    4352.0f;  // 17 steps of 256: where the scenes below are built, far enough that a float is coarse (0.5 mm)

// The scene of the motion blur tests (dof_motion_tests.cpp) built `kFar` away on x: a camera at (kFar, 0, 10) looking down -Z, a near cube
// (2 m wide, 35 px) and a far one.
struct Far {
    World w;
    Entity cam = kNullEntity;
    Far() {
        cam = make(w, "cam", {kFar, 0, 10});
        auto& c = w.add<Camera>(cam);
        c.projection = Projection::Perspective;
        c.fov = 60.0f;
        c.clearColor = Color{0, 0, 0, 1};
        w.settings().skyColor = w.settings().horizonColor = Color{0, 0, 0, 1};
        add_cube({kFar - 3, 0, 0}, 2.0f);
        add_cube({kFar + 12, 0, -34.5f}, 9.0f);
    }
    void add_cube(Vec3 pos, float size) {
        Entity e = make(w, "cube", pos);
        w.get<Transform>(e)->scale = {size, size, size};
        auto& m = w.add<MeshRenderer>(e);
        m.mesh = "cube";
        m.color = Color::white();
        m.unlit = true;
    }
    void motion_blur() {
        PostProcess& p = camera_post(w, cam);
        p.motionBlurEnabled = true;
        p.motionBlurIntensity = 1.0f;
        p.motionBlurSamples = 16;
    }
};

}  // namespace

TEST_CASE("floating origin render: the camera motion blur reprojects from is the camera shifted by the offset") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    Image
        still;  // the same scene drawn three times with no rebase (another renderer: two do not share one context's history)
    {
        Own own(g);
        REQUIRE(own.ok);
        Far t;
        t.motion_blur();
        own.frame(t.w, 2);
        still = own.draw(t.w);
    }
    Own o(g);
    REQUIRE_MESSAGE(o.ok, o.error);
    Far s;
    s.motion_blur();
    o.frame(s.w, 2);
    Mat4 before;
    REQUIRE(RendererTestAccess::prev_view_proj(o.r, s.cam, before));
    const std::uint64_t shifts = RendererTestAccess::origin_shifts(o.r);
    const Vec3 offset{4096.0f, 0.0f, 0.0f};
    s.w.rebase(offset);
    CHECK(RendererTestAccess::origin_shifts(o.r) == shifts + 1);
    Mat4 after;
    REQUIRE(RendererTestAccess::prev_view_proj(o.r, s.cam, after));
    // A point that did not move: the matrix of the frame before knew it at q, the shifted one at q - offset, and they give the same clip.
    for (Vec3 q : {Vec3{kFar - 3, 0, 0}, Vec3{kFar + 12, 1, -34.5f}, Vec3{kFar, -2, 3}}) {
        const Vec4 a = before * Vec4{q, 1.0f};
        const Vec4 b = after * Vec4{q - offset, 1.0f};
        INFO("clip before " << a.x << " " << a.y << " " << a.z << " " << a.w << ", after " << b.x << " " << b.y << " "
                            << b.z << " " << b.w);
        CHECK(std::fabs(a.x - b.x) < 0.02f);
        CHECK(std::fabs(a.y - b.y) < 0.02f);
        CHECK(std::fabs(a.z - b.z) < 0.02f);
        CHECK(std::fabs(a.w - b.w) < 0.02f);
    }
    // The frame of the rebase: nothing moved on the screen, so nothing is smeared and the picture is the one without a rebase.
    const Image rebased = o.draw(s.w);
    INFO("pixels that differ: " << differing_pixels(rebased, still));
    CHECK(differing_pixels(rebased, still) <= 150);
    CHECK(soft_pixels(rebased, 90, 80, 140) <= 6);  // the near cube's vertical edges stay sharp
}

TEST_CASE("floating origin render: a rebase between frames of a moving camera keeps its blur and does not add one") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    // The same move of the camera, one metre sideways, with and without a rebase in between: the same picture.
    auto run = [&](bool rebase) {
        Own o(g);
        REQUIRE_MESSAGE(o.ok, o.error);
        Far s;
        s.motion_blur();
        o.frame(s.w, 2);
        s.w.get<Transform>(s.cam)->position.x += 1.0f;
        if (rebase) s.w.rebase({4096.0f, 0.0f, 0.0f});
        return o.draw(s.w);
    };
    const Image plain = run(false);
    const Image rebased = run(true);
    INFO("soft plain " << soft_pixels(plain, 90, 60, 150) << ", rebased " << soft_pixels(rebased, 90, 60, 150));
    CHECK(soft_pixels(plain, 90, 60, 150) >= 12);  // it does blur
    CHECK(differing_pixels(rebased, plain) <= 150);
}

TEST_CASE(
    "floating origin render: a world swap and either order of destruction never call into a dead renderer or world") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    {
        // The renderer is destroyed first: the world's observer is removed, a later rebase calls nobody.
        auto w = std::make_unique<World>();
        w->add<Camera>(make(*w, "cam", {kFar, 0, 10}));
        {
            Own o(g);
            REQUIRE(o.ok);
            o.frame(*w);
            CHECK(RendererTestAccess::origin_watched(o.r, w.get()));
            w->rebase({256.0f, 0.0f, 0.0f});
            CHECK(RendererTestAccess::origin_shifts(o.r) == 1);
        }
        w->rebase({256.0f, 0.0f, 0.0f});  // would call into the dead renderer
        CHECK(w->rebase_count() == 2);
    }
    {
        // The world is destroyed first: the renderer forgets it and never removes an observer from it.
        Own o(g);
        REQUIRE(o.ok);
        auto w = std::make_unique<World>();
        Entity cam = make(*w, "cam", {kFar, 0, 10});
        w->add<Camera>(cam);
        o.frame(*w);
        CHECK(RendererTestAccess::origin_watched(o.r, w.get()));
        w.reset();
        // Another world, perhaps at the same address: the renderer watches it, and only it.
        auto w2 = std::make_unique<World>();
        Entity cam2 = make(*w2, "cam", {kFar, 0, 10});
        w2->add<Camera>(cam2);
        o.frame(*w2);
        CHECK(RendererTestAccess::origin_watched(o.r, w2.get()));
        w2->rebase({256.0f, 0.0f, 0.0f});
        CHECK(RendererTestAccess::origin_shifts(o.r) == 1);
        // A world swap while both live: the first no longer reaches the renderer, the second does.
        World a, b;
        for (World* w3 : {&a, &b}) {
            Entity c = make(*w3, "cam", {0, 0, 10});
            w3->add<Camera>(c);
        }
        o.frame(a);
        o.frame(b);
        a.rebase({256.0f, 0.0f, 0.0f});
        CHECK(RendererTestAccess::origin_shifts(o.r) == 1);
        b.rebase({256.0f, 0.0f, 0.0f});
        CHECK(RendererTestAccess::origin_shifts(o.r) == 2);
        // The renderer shut down while the world lives: nothing is left behind.
        o.r.shutdown();
        b.rebase({256.0f, 0.0f, 0.0f});
        CHECK(RendererTestAccess::origin_shifts(o.r) == 0);  // no implementation any more
    }
}

TEST_CASE(
    "floating origin render: the shadow cascades snap in absolute space, so a shift leaves them on the same texels") {
    const Vec3 light = normalize(Vec3{-0.4f, -1.0f, -0.3f});
    const int tile = 1024;
    const float radius = 23.7f;  // a texel of 0.0463: 256 is not a multiple of it
    const Vec3 centre{kFar + 2.3f, 3.0f, -4.1f};
    const Vec3 offset{4096.0f, 0.0f, 0.0f};
    const DVec3 origin0{0, 0, 0}, origin1{4096.0, 0.0, 0.0};
    const CascadeFit a = fit_cascade(centre, radius, light, tile, -50.0f, true, origin0);
    const CascadeFit b = fit_cascade(centre - offset, radius, light, tile, -50.0f, true, origin1);
    // The snapped centre in absolute coordinates is the same, up to the float error of the position.
    const DVec3 abs0 = origin0 + to_dvec3(a.centre), abs1 = origin1 + to_dvec3(b.centre);
    CHECK(std::fabs(abs0.x - abs1.x) < 2e-3);
    CHECK(std::fabs(abs0.y - abs1.y) < 2e-3);
    CHECK(std::fabs(abs0.z - abs1.z) < 2e-3);
    // Without the origin the grid is fixed to the new local zero: the snapped centre lands up to a texel away (what the origin fixes).
    const CascadeFit c = fit_cascade(centre - offset, radius, light, tile, -50.0f, true);
    const DVec3 abs2 = origin1 + to_dvec3(c.centre);
    const double texel = double(a.texel);
    CHECK(std::fabs(abs2.x - abs0.x) + std::fabs(abs2.y - abs0.y) + std::fabs(abs2.z - abs0.z) > 0.05 * texel);
    // And the origin at zero is the plain snap, bit for bit.
    const CascadeFit d = fit_cascade(centre, radius, light, tile, -50.0f, true);
    CHECK(d.centre.x == a.centre.x);
    CHECK(d.centre.y == a.centre.y);
    CHECK(d.centre.z == a.centre.z);
}

TEST_CASE("floating origin render: the 2D GI field lies on the same absolute texels after a shift") {
    Gi2dSettings s;
    s.on = true;
    s.range = 32.0f;
    s.resolutionScale = 0.75f;  // a texel of 1.333: 256 is not a multiple of it
    const Rect view{kFar - 160.0f, -90.0f, 320.0f, 180.0f};
    const Gi2dGeometry a = gi2d_geometry(view, 1.0f, s, 0.0, 0.0);
    const Gi2dGeometry b = gi2d_geometry(Rect{view.x - 4096.0f, view.y, view.w, view.h}, 1.0f, s, 4096.0, 0.0);
    REQUIRE(a.valid);
    REQUIRE(b.valid);
    CHECK(b.width == a.width);
    CHECK(a.originX == doctest::Approx(b.originX + 4096.0).epsilon(1e-12));
    CHECK(a.originY == b.originY);
    const double texels = (a.originX - (b.originX + 4096.0)) / a.texel;
    CHECK(std::fabs(texels) < 1e-6);
    // The plain geometry (no origin) is unchanged.
    CHECK(gi2d_geometry(view, 1.0f, s).originX == a.originX);
}

namespace {

void write_white() {
    Image white;
    white.width = white.height = 16;
    white.rgba.assign(16 * 16 * 4, 255);
    REQUIRE(save_png(white, "assets/white16.png").ok());
}

}  // namespace

TEST_CASE("floating origin render: the 2D GI keeps its history across a rebase") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    Own o(g);
    REQUIRE(o.ok);
    if (!Gi2dSystem::float_targets_ok()) {
        MESSAGE("no RGBA16F targets on this GPU: the 2D GI is not drawn here");
        return;
    }
    write_white();
    World w;
    Entity cam = make(w, "cam", {kFar, 0, 0});
    w.add<Camera>(cam).clearColor = Color{0, 0, 0, 1};
    Entity gie = make(w, "gi", {kFar, 0, 0});
    auto& gi = w.add<GlobalIllumination2D>(gie);
    gi.quality = GI2DQuality::Low;
    gi.bounce = 0.5f;
    gi.range = 32.0f;
    gi.resolutionScale = 0.75f;
    auto sprite = [&](const char* name, Vec3 pos, Vec2 size, Color color, float power, bool wall) {
        Entity e = make(w, name, pos);
        auto& sp = w.add<Sprite>(e);
        sp.texture = "assets/white16.png";
        sp.size = size;
        sp.lit = wall;
        sp.color = wall ? color : Color{0, 0, 0, 1};
        sp.emissive = wall ? Color{0, 0, 0, 1} : color;
        sp.emissiveIntensity = power;
        if (wall) {
            auto& sc = w.add<ShadowCaster2D>(e);
            sc.shape = ShadowCaster2DShape::Box;
            sc.size = size;
        }
    };
    sprite("lamp", {kFar - 100, 0, 0}, {16, 16}, Color{1, 1, 1, 1}, 4.0f, false);
    sprite("wall", {kFar - 40, 0, 0}, {10, 90}, Color{0, 1, 0, 1}, 0.0f, true);
    o.frame(w, 3);
    Gi2dFieldInfo info = renderer_gi2d_info(o.r, 0);
    REQUIRE(info.ready);
    REQUIRE(info.irradianceReady);
    CHECK_FALSE(info.primed);
    const double texel = info.texel;
    const double originBefore = info.originX;
    const std::uint64_t shifts = RendererTestAccess::gi2d_shifts(o.r);
    w.rebase({4096.0f, 0.0f, 0.0f});
    CHECK(RendererTestAccess::gi2d_shifts(o.r) == shifts + 1);
    o.frame(w);
    info = renderer_gi2d_info(o.r, 0);
    REQUIRE(info.ready);
    CHECK(info.texel == texel);
    // The history was kept: the bounce did not start from the priming chain, and the field lies on the same absolute texels.
    CHECK_FALSE(info.primed);
    CHECK(info.history);
    const double moved = (info.originX + 4096.0 - originBefore) / texel;
    INFO("the field moved by " << moved << " texels");
    CHECK(std::fabs(moved) < 1e-6);
    o.frame(w);
    CHECK_FALSE(renderer_gi2d_info(o.r, 0).primed);
}

TEST_CASE("floating origin render: the realtime GI grid is not laid out again by a rebase") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    if (!g.renderer.supports("floatTargets")) {
        MESSAGE("this GPU has no half-float render targets: not run");
        return;
    }
    Own o(g);
    REQUIRE(o.ok);
    World w;
    Entity cam = make(w, "cam", {kFar, 0, 0});
    auto& c = w.add<Camera>(cam);
    c.projection = Projection::Perspective;
    c.fov = 60;
    w.settings().ambientLight = Color{0, 0, 0, 1};
    w.settings().skyColor = w.settings().horizonColor = Color{0, 0, 0, 1};
    for (float side : {6.0f, -6.0f}) {
        Entity e = make(w, side > 0 ? "red" : "green", {kFar + side, 0, 0});
        w.get<Transform>(e)->scale = {0.2f, 12, 12};
        auto& m = w.add<MeshRenderer>(e);
        m.mesh = "cube";
        m.color = Color{0, 0, 0, 1};
        m.unlit = true;
        m.emissive = side > 0 ? Color{1, 0, 0, 1} : Color{0, 1, 0, 1};
        m.castShadows = false;
    }
    Entity gie = make(w, "gi", {kFar, 0, 0});
    auto& gi = w.add<RealtimeGI>(gie);
    gi.size = {8, 0, 0};
    gi.spacing = 4.0f;
    gi.probesPerFrame = 1;  // a grid laid out again captures ONE probe a frame: three frames to be whole again
    gi.resolution = 16;
    gi.maxDistance = 30.0f;
    o.frame(w, 8);
    Json report = o.r.gi_report();
    INFO("report: " << report.dump(2));
    REQUIRE(report.contains("grids"));
    REQUIRE(report["grids"].size() == 1);
    if (report["grids"][0]["state"] == "unsupported") {
        MESSAGE("this GPU cannot blend into RGBA16F: not run");
        return;
    }
    REQUIRE(report["grids"][0]["captured"].get<int>() == 3);
    REQUIRE(report["grids"][0]["state"] == "ready");
    const double originBefore = report["grids"][0]["origin"][0].get<double>();
    w.rebase({4096.0f, 0.0f, 0.0f});
    o.frame(w);
    report = o.r.gi_report();
    INFO("report after the rebase: " << report.dump(2));
    REQUIRE(report["grids"].size() == 1);
    CHECK(report["grids"][0]["captured"].get<int>() == 3);  // not started from zero
    CHECK(report["grids"][0]["state"] == "ready");
    CHECK(report["grids"][0]["origin"][0].get<double>() == doctest::Approx(originBefore - 4096.0).epsilon(1e-6));
    CHECK(report["grids"][0]["cycles"].get<double>() >= 1.0);
}
