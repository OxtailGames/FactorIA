// M71-D2: depth of field and camera motion blur (src/renderer_dof.cpp, shaders/dof.glsl, shaders/motion_blur.glsl). The scenes are meshes on a
// black sky, so the sharpness of an object is read from its edge: the number of pixels of a row that are neither black nor white.
// A sharp edge has none or one, a blur of r pixels about r. The pure CPU parts (the plan, the focus smoothing) need no GPU.
#include "test_util.h"

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <string>
#include <vector>

#include "frame_graph.h"
#include "postprocess.h"
#include "postprocess_resolve.h"
#include "render_features.h"
#include "render_internal.h"
#include "renderer_dof.h"
#include "renderer_test_access.h"

using namespace fa;
using namespace fa::test;
using render::CameraInfo;
using render::PostStack;

namespace {

// A renderer of its own (its frame counter and its memory of the frame before are its own) on the test GPU.
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
    Image draw(World& w, float dt = 1.0f / 60.0f) {
        r.begin_frame();
        r.render_world(w, dt);
        r.end_frame();
        g.gpu.end_frame();
        Image img;
        std::string err;
        const bool captured = r.capture(img, &err);
        INFO("capture error: " << err);
        REQUIRE(captured);
        return img;
    }
    std::vector<std::string> order() {
        const render::FrameGraph* graph = render::renderer_frame_graph(r);
        REQUIRE(graph != nullptr);
        return graph->order_names();
    }
};

Entity add_camera(World& w, Vec3 pos, const char* name = "cam") {
    Entity cam = make(w, name, pos);
    auto& c = w.add<Camera>(cam);
    c.projection = Projection::Perspective;
    c.fov = 60.0f;
    c.clearColor = Color{0, 0, 0, 1};
    w.settings().skyColor = w.settings().horizonColor = Color{0, 0, 0, 1};
    return cam;
}
Entity add_cube(World& w, Vec3 pos, float size) {
    Entity e = make(w, "cube", pos);
    w.get<Transform>(e)->scale = {size, size, size};
    auto& m = w.add<MeshRenderer>(e);
    m.mesh = "cube";
    m.color = Color::white();
    m.unlit = true;
    return e;
}
PostProcess& post_of(World& w, Entity cam) {
    PostProcess* p = w.get<PostProcess>(cam);
    return p ? *p : w.add<PostProcess>(cam);
}

// The camera at (0, 0, 10) looking down -Z. `nearCube`: 2 m wide, its front face 9 m away, 35 px wide at x 91 .. 125. `farCube`: 9 m wide at
// x = 12, its front face 40 m away: about the same size on the screen (35 px, x 189 .. 225), and so a 35 px bar to blur.
struct Scene {
    World w;
    Entity cam = kNullEntity;
    Entity nearCube = kNullEntity;
    Entity farCube = kNullEntity;
    Scene() {
        cam = add_camera(w, {0, 0, 10});
        nearCube = add_cube(w, {-3, 0, 0}, 2.0f);
        farCube = add_cube(w, {12, 0, -34.5f}, 9.0f);
    }
    PostProcess& post() { return post_of(w, cam); }
    void dof(float focus, float range = 1.0f, float nearBlur = 8.0f, float farBlur = 8.0f) {
        PostProcess& p = post();
        p.depthOfFieldEnabled = true;
        p.depthOfFieldFocusDistance = focus;
        p.depthOfFieldFocusRange = range;
        p.depthOfFieldNearBlur = nearBlur;
        p.depthOfFieldFarBlur = farBlur;
    }
};

// How many pixels of row y in [x0, x1) are neither black nor white: the width of the edges there.
int soft_pixels(const Image& img, int y, int x0, int x1) {
    int n = 0;
    for (int x = x0; x < x1; ++x) {
        const float v = img.pixel(x, y).r;
        if (v > 0.08f && v < 0.92f) ++n;
    }
    return n;
}
// The same along a column.
int soft_pixels_col(const Image& img, int x, int y0, int y1) {
    int n = 0;
    for (int y = y0; y < y1; ++y) {
        const float v = img.pixel(x, y).r;
        if (v > 0.08f && v < 0.92f) ++n;
    }
    return n;
}
// The largest channel difference of two pictures in a rectangle (0..255).
int max_diff(const Image& a, const Image& b, int x0 = 0, int y0 = 0, int x1 = 1 << 20, int y1 = 1 << 20) {
    REQUIRE(a.width == b.width);
    REQUIRE(a.height == b.height);
    int worst = 0;
    for (int y = y0; y < std::min(y1, a.height); ++y)
        for (int x = x0; x < std::min(x1, a.width); ++x)
            for (int c = 0; c < 4; ++c) {
                const std::size_t i = (std::size_t(y) * std::size_t(a.width) + std::size_t(x)) * 4 + std::size_t(c);
                worst = std::max(worst, std::abs(int(a.rgba[i]) - int(b.rgba[i])));
            }
    return worst;
}
bool has_pass(const std::vector<std::string>& names, const char* part) {
    for (const std::string& n : names)
        if (n.find(part) != std::string::npos) return true;
    return false;
}
std::string joined(const std::vector<std::string>& names) {
    std::string o;
    for (const std::string& s : names) o += s + " ";
    return o;
}

// The plan of a camera at z = 10 looking down -Z.
CameraInfo camera_info() {
    CameraInfo c;
    c.view = Mat4::translate({0, 0, -10});
    c.proj = Mat4::perspective(60.0f, 16.0f / 9.0f, 0.1f, 1000.0f, true);
    c.viewProj = c.proj * c.view;
    c.invViewProj = c.viewProj.inverse();
    c.perspective = true;
    return c;
}
PostStack stack_of(const PostProcess& fx) {
    PostStack s;
    s.fx = fx;
    if (fx.depthOfFieldEnabled) s.mask |= 1u << int(PostEffect::DepthOfField);
    if (fx.motionBlurEnabled) s.mask |= 1u << int(PostEffect::MotionBlur);
    return s;
}

}  // namespace

TEST_CASE("depth of field: both effects are drawn effects now (render.supports, post_drawn_mask)") {
    const std::uint32_t mask = render::post_drawn_mask();
    CHECK(((mask >> int(PostEffect::DepthOfField)) & 1u) == 1u);
    CHECK(((mask >> int(PostEffect::MotionBlur)) & 1u) == 1u);
}

TEST_CASE(
    "depth of field: smooth_focus moves by the engine clock only, and stays put when it has no speed or a bad number") {
    using render::smooth_focus;
    CHECK(smooth_focus(10.0f, 20.0f, 0.0f, 0.1f) == 10.0f);
    CHECK(smooth_focus(10.0f, 20.0f, 5.0f, 0.0f) == 10.0f);
    CHECK(smooth_focus(10.0f, std::nanf(""), 5.0f, 0.1f) == 10.0f);
    const float one = smooth_focus(10.0f, 20.0f, 5.0f, 0.1f);
    CHECK(one == doctest::Approx(10.0f + 10.0f * (1.0f - std::exp(-0.5f))).epsilon(1e-5));
    // The same time in one step or in two reaches the same place (the factor is exponential), within rounding.
    const float two = smooth_focus(smooth_focus(10.0f, 20.0f, 5.0f, 0.05f), 20.0f, 5.0f, 0.05f);
    CHECK(two == doctest::Approx(one).epsilon(1e-4));
    float f = 10.0f;
    for (int i = 0; i < 600; ++i) f = smooth_focus(f, 20.0f, 5.0f, 1.0f / 60.0f);
    CHECK(f == doctest::Approx(20.0f).epsilon(1e-3));
    CHECK(f <= 20.0f);
}

TEST_CASE("depth of field: the gather has a tap count that depends on the radius only") {
    CHECK(render::dof_gather_taps(0.0f) >= 8);
    CHECK(render::dof_gather_taps(1000.0f) <= 64);
    int last = 0;
    for (float r = 0.0f; r <= 40.0f; r += 1.0f) {
        const int n = render::dof_gather_taps(r);
        CHECK(n >= last);
        last = n;
    }
    CHECK(render::dof_gather_taps(6.0f) == render::dof_gather_taps(6.0f));
}

TEST_CASE("depth of field: the plan follows the target's view depth, deterministically, and falls back without one") {
    World w;
    const Entity target = make(w, "target", {0, 0, 0});  // 10 m in front of the camera
    PostProcess fx;
    fx.depthOfFieldEnabled = true;
    fx.depthOfFieldFocusDistance = 30.0f;
    fx.depthOfFieldFocusSpeed = 4.0f;
    fx.depthOfFieldTarget = target;
    const PostStack stack = stack_of(fx);
    const CameraInfo cam = camera_info();
    const Mat4 none;

    auto run = [&](std::vector<float>& focusByFrame) {
        render::SceneFx fxState;
        for (std::uint64_t frame = 1; frame <= 90; ++frame) {
            const render::SceneFxPlan p = fxState.plan(w, cam, stack, 7, frame, 1.0f / 60.0f, 1.0f, none, false);
            REQUIRE(p.dof);
            focusByFrame.push_back(p.focus);
        }
    };
    std::vector<float> a, b;
    run(a);
    run(b);
    CHECK(a == b);                               // the same frames give the same focus, bit for bit
    CHECK(a.front() == doctest::Approx(10.0f));  // the first frame is focused at once: there is nothing to move from
    for (std::size_t i = 1; i < a.size(); ++i) CHECK(a[i] == doctest::Approx(10.0f).epsilon(1e-5));

    // Changing the target's place: the focus moves toward it a part of the way each frame, never past it.
    render::SceneFx fxState;
    fxState.plan(w, cam, stack, 7, 1, 1.0f / 60.0f, 1.0f, none, false);
    w.get<Transform>(target)->position = {0, 0, -20};  // now 30 m away
    float last = fxState.focus_of(7);
    CHECK(last == doctest::Approx(10.0f));
    for (std::uint64_t frame = 2; frame <= 200; ++frame) {
        const float f = fxState.plan(w, cam, stack, 7, frame, 1.0f / 60.0f, 1.0f, none, false).focus;
        CHECK(f > last);
        CHECK(f <= 30.0f);
        last = f;
    }
    CHECK(last == doctest::Approx(30.0f).epsilon(1e-3));

    // A destroyed target: the stack's focus distance.
    w.destroy_immediate(target);
    const render::SceneFxPlan gone = fxState.plan(w, cam, stack, 7, 201, 1.0f / 60.0f, 1.0f, none, false);
    CHECK(gone.focus == doctest::Approx(30.0f));
    PostProcess far = fx;
    far.depthOfFieldFocusDistance = 55.0f;
    CHECK(fxState.plan(w, cam, stack_of(far), 7, 202, 1.0f / 60.0f, 1.0f, none, false).focus == doctest::Approx(55.0f));
    // A camera that asked nobody for two frames is forgotten.
    fxState.plan(w, cam, stack, 8, 410, 1.0f / 60.0f, 1.0f, none, false);
    CHECK(std::isnan(fxState.focus_of(7)));
}

TEST_CASE("depth of field: the blur is in design pixels times the render scale; no effect, no plan") {
    World w;
    PostProcess fx;
    fx.depthOfFieldEnabled = true;
    fx.depthOfFieldNearBlur = 4.0f;
    fx.depthOfFieldFarBlur = 6.0f;
    render::SceneFx fxState;
    const CameraInfo cam = camera_info();
    const Mat4 none;
    const render::SceneFxPlan p = fxState.plan(w, cam, stack_of(fx), 1, 1, 0.016f, 2.0f, none, false);
    CHECK(p.nearPx == doctest::Approx(8.0f));
    CHECK(p.farPx == doctest::Approx(12.0f));
    fx.depthOfFieldNearBlur = 0.0f;
    fx.depthOfFieldFarBlur = 0.0f;
    CHECK_FALSE(fxState.plan(w, cam, stack_of(fx), 1, 2, 0.016f, 1.0f, none, false).any());
    PostProcess off;
    CHECK_FALSE(fxState.plan(w, cam, stack_of(off), 1, 3, 0.016f, 1.0f, none, false).any());
}

TEST_CASE("motion blur: the plan blurs only with the frame before; a cut, the first frame or a zero shutter do not") {
    World w;
    PostProcess fx;
    fx.motionBlurEnabled = true;
    fx.motionBlurIntensity = 0.5f;
    fx.motionBlurSamples = 100;  // out of range: clamped
    render::SceneFx fxState;
    const CameraInfo cam = camera_info();
    CHECK_FALSE(fxState.plan(w, cam, stack_of(fx), 1, 1, 0.016f, 1.0f, cam.viewProj, false).any());
    const render::SceneFxPlan p = fxState.plan(w, cam, stack_of(fx), 1, 2, 0.016f, 1.0f, cam.viewProj, true);
    CHECK(p.motion);
    CHECK(p.motionTaps == 32);
    fx.motionBlurIntensity = 0.0f;
    CHECK_FALSE(fxState.plan(w, cam, stack_of(fx), 1, 3, 0.016f, 1.0f, cam.viewProj, true).any());
}

TEST_CASE("depth of field: an object at the focus stays sharp, one far behind it is blurred, off is the same picture "
          "as no stack") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    for (const int samples : {1, 4}) {
        CAPTURE(samples);
        Own own(g, samples);
        REQUIRE_MESSAGE(own.ok, own.error);
        Scene plain;
        const Image reference = own.draw(plain.w);
        const int nearSharp = soft_pixels(reference, 90, 80, 140);
        const int farSharp = soft_pixels(reference, 90, 180, 240);
        CHECK(nearSharp <= 6);
        CHECK(farSharp <= 6);
        CHECK_FALSE(has_pass(own.order(), "dof-"));

        Scene s;
        s.dof(10.0f);  // the near cube's faces are 9 .. 11 m away
        const Image img = own.draw(s.w);
        const std::vector<std::string> order = own.order();
        INFO(joined(order));
        CHECK(has_pass(order, "dof-down"));
        CHECK(has_pass(order, "dof-gather"));
        CHECK(has_pass(order, "dof-composite"));
        CHECK(soft_pixels(img, 90, 80, 140) <= 6);    // at the focus: as sharp as without the effect
        CHECK(soft_pixels(img, 90, 180, 240) >= 10);  // 30 m behind it: two soft edges
        CHECK(soft_pixels(img, 90, 180, 240) > farSharp + 6);
        // A blur keeps the light: the far cube is still bright in its middle and the sky still black.
        CHECK(img.pixel(207, 90).r > 0.9f);
        CHECK(img.pixel(20, 20).r < 0.02f);
        // The effect off again: the same picture as a scene that never had a stack.
        Scene off;
        off.post();
        off.post().depthOfFieldEnabled = false;
        CHECK(max_diff(own.draw(off.w), reference) == 0);
        CHECK_FALSE(has_pass(own.order(), "dof-"));
    }
}

TEST_CASE("depth of field: an object in front of the focus is blurred and its blur grows past its edge") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    Own own(g);
    REQUIRE_MESSAGE(own.ok, own.error);
    auto make_scene = [](Scene& s) {
        // A 1 m cube 2.5 m from the camera: 62 px wide, edges at x 129 and 191.
        s.w.destroy_immediate(s.nearCube);
        s.w.destroy_immediate(s.farCube);
        add_cube(s.w, {0, 0, 7}, 1.0f);
    };
    Scene plain;
    make_scene(plain);
    const Image reference = own.draw(plain.w);
    CHECK(soft_pixels(reference, 90, 100, 220) <= 4);
    CHECK(reference.pixel(125, 90).r < 0.02f);

    Scene s;
    make_scene(s);
    s.dof(20.0f, 1.0f, 8.0f, 8.0f);
    const Image img = own.draw(s.w);
    CHECK(soft_pixels(img, 90, 100, 220) >= 10);
    CHECK(img.pixel(125, 90).r > 0.05f);  // the near blur reaches outside the silhouette ...
    CHECK(img.pixel(160, 90).r > 0.9f);   // ... and the middle of the cube stays bright
    // Far blur 0: the near cube is still blurred (the settings are independent).
    Scene onlyNear;
    make_scene(onlyNear);
    onlyNear.dof(20.0f, 1.0f, 8.0f, 0.0f);
    CHECK(soft_pixels(own.draw(onlyNear.w), 90, 100, 220) >= 10);
    // Near blur 0: it is not.
    Scene onlyFar;
    make_scene(onlyFar);
    onlyFar.dof(20.0f, 1.0f, 0.0f, 8.0f);
    CHECK(soft_pixels(own.draw(onlyFar.w), 90, 100, 220) <= 6);
}

TEST_CASE("depth of field: the autofocus follows the target entity (and the focus distance is the fallback)") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    Own own(g);
    REQUIRE_MESSAGE(own.ok, own.error);
    // Focus distance 10 puts the near cube at the focus; the target is the far cube, so the focus moves to 40 m: the near cube is blurred and
    // the far one is sharp. A fast speed makes the first frames the same as the last.
    Scene s;
    s.dof(10.0f);
    s.post().depthOfFieldTarget = s.farCube;
    s.post().depthOfFieldFocusSpeed = 100.0f;
    Image img;
    for (int i = 0; i < 4; ++i) img = own.draw(s.w);
    CHECK(soft_pixels(img, 90, 180, 240) <= 6);
    CHECK(soft_pixels(img, 90, 80, 140) >= 10);
    // The target destroyed: back to the stack's focus distance, the near cube sharp again.
    s.w.destroy_immediate(s.farCube);
    Image back;
    for (int i = 0; i < 3; ++i) back = own.draw(s.w);
    CHECK(soft_pixels(back, 90, 80, 140) <= 6);
}

TEST_CASE("motion blur: a still camera gives the same picture, a moving one smears along its movement, a cut or the "
          "first frame do not") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    auto motion_scene = [](Scene& s) {
        PostProcess& p = s.post();
        p.motionBlurEnabled = true;
        p.motionBlurIntensity = 1.0f;
        p.motionBlurSamples = 16;
    };
    // The sharp picture of the camera at x = 1 (what a frame without blur shows).
    Image sharpAtOne;
    {
        Own own(g);
        REQUIRE_MESSAGE(own.ok, own.error);
        Scene s;
        s.w.get<Transform>(s.cam)->position.x = 1.0f;
        sharpAtOne = own.draw(s.w);
        CHECK(soft_pixels(sharpAtOne, 90, 80, 140) <= 6);
    }
    SUBCASE("a still camera") {
        Own own(g);
        REQUIRE_MESSAGE(own.ok, own.error);
        Scene s;
        const Image reference = own.draw(s.w);
        motion_scene(s);
        own.draw(s.w);
        const Image still = own.draw(s.w);
        CHECK(max_diff(still, reference) <= 1);
    }
    SUBCASE("a camera that moves sideways") {
        Own own(g);
        REQUIRE_MESSAGE(own.ok, own.error);
        Scene s;
        motion_scene(s);
        const Image first = own.draw(s.w);
        CHECK(max_diff(first, own.draw(s.w)) <= 1);  // a second frame at the same place: nothing moved
        s.w.get<Transform>(s.cam)->position.x = 1.0f;
        const Image moved = own.draw(s.w);
        const std::vector<std::string> order = own.order();
        INFO(joined(order));
        CHECK(has_pass(order, "motion-blur"));
        // The vertical edges of the cube are smeared, its horizontal ones (across the movement) are not.
        const int along = soft_pixels(moved, 90, 60, 150);
        const int across = soft_pixels_col(moved, 91, 60, 85);
        INFO("along " << along << ", across " << across);
        CHECK(along >= 12);
        CHECK(across <= 4);
        CHECK(max_diff(moved, sharpAtOne) > 40);
        // The light stays: the middle of the cube is as bright as before.
        CHECK(moved.pixel(91, 90).r > 0.9f);
        // Moving back the other way smears too; a camera that stops gives the sharp picture again.
        const Image stopped = own.draw(s.w);
        CHECK(max_diff(stopped, sharpAtOne) <= 1);
    }
    SUBCASE("the first frame") {
        Own own(g);
        REQUIRE_MESSAGE(own.ok, own.error);
        Scene s;
        s.w.get<Transform>(s.cam)->position.x = 1.0f;
        motion_scene(s);
        const Image first = own.draw(s.w);
        CHECK(max_diff(first, sharpAtOne) <= 1);
    }
    SUBCASE("after a cut (the camera did not draw the frame before)") {
        Own own(g);
        REQUIRE_MESSAGE(own.ok, own.error);
        Scene s;
        motion_scene(s);
        own.draw(s.w);
        // Another camera draws one frame, then the first one is back somewhere else.
        const Entity other = add_camera(s.w, {1, 0, 10}, "other");
        s.w.set_active(s.cam, false);
        own.draw(s.w);
        s.w.set_active(s.cam, true);
        s.w.set_active(other, false);
        s.w.get<Transform>(s.cam)->position.x = 1.0f;
        const Image back = own.draw(s.w);
        CHECK(max_diff(back, sharpAtOne) <= 1);
        CHECK_FALSE(has_pass(own.order(), "motion-blur"));
    }
}

TEST_CASE("motion blur and depth of field together: one picture, both effects, and the same frame on every run") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    auto run = [&](Image& out) {
        Own own(g);
        REQUIRE_MESSAGE(own.ok, own.error);
        Scene s;
        s.dof(10.0f);
        s.post().motionBlurEnabled = true;
        s.post().motionBlurIntensity = 1.0f;
        own.draw(s.w);
        s.w.get<Transform>(s.cam)->position.x = 1.0f;
        out = own.draw(s.w);
        const std::vector<std::string> order = own.order();
        INFO(joined(order));
        CHECK(has_pass(order, "dof-composite"));
        CHECK(has_pass(order, "motion-blur"));
        CHECK_FALSE(has_pass(order, "dof-copy"));  // the motion pass writes the picture itself
    };
    Image a, b;
    run(a);
    run(b);
    CHECK(max_diff(a, b) == 0);
}

TEST_CASE("depth of field: in a split screen each camera blurs its own rectangle only") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    auto make_split = [](Scene& s, bool withDof) {
        auto& left = *s.w.get<Camera>(s.cam);
        left.viewport = {0, 0, 0.5f, 1};
        const Entity right = add_camera(s.w, {0, 0, 10}, "right");
        auto& rc = *s.w.get<Camera>(right);
        rc.viewport = {0.5f, 0, 0.5f, 1};
        rc.depth = 1;
        if (withDof) s.dof(10.0f);  // the left camera's stack only
        return right;
    };
    Own own(g);
    REQUIRE_MESSAGE(own.ok, own.error);
    Scene plain;
    make_split(plain, false);
    const Image reference = own.draw(plain.w);
    Scene s;
    make_split(s, true);
    const Image img = own.draw(s.w);
    const std::vector<std::string> order = own.order();
    INFO(joined(order));
    CHECK(has_pass(order, "dof-composite"));
    // The right half is the picture of the scene without the effect, to the last bit: the left camera's passes drew inside its own rectangle.
    CHECK(max_diff(img, reference, 160, 0, 320, 180) <= 1);
    // The left half has the far cube blurred (x 94 .. 128 of a half-width picture) ...
    CHECK(max_diff(img, reference, 0, 0, 160, 180) > 20);
    CHECK(soft_pixels(img, 90, 100, 156) >= 8);
    CHECK(soft_pixels(reference, 90, 100, 156) <= 4);
    // ... and no light crossed the seam: its first columns on each side are what the reference has.
    CHECK(max_diff(img, reference, 158, 0, 162, 180) <= 20);

    // Both cameras with their own stack: the right one focuses far, so the right half shows the far cube sharp and the left half does not.
    Scene both;
    const Entity right = make_split(both, true);
    PostProcess& rp = post_of(both.w, right);
    rp.depthOfFieldEnabled = true;
    rp.depthOfFieldFocusDistance = 40.0f;
    rp.depthOfFieldFocusRange = 1.0f;
    rp.depthOfFieldNearBlur = 8.0f;
    rp.depthOfFieldFarBlur = 8.0f;
    const Image two = own.draw(both.w);
    CHECK(max_diff(two, img, 0, 0, 156, 180) <= 2);  // the left camera is not changed by the right one's settings
    CHECK(max_diff(two, reference, 160, 0, 320, 180) > 20);
}

TEST_CASE("depth of field and motion blur: a frame with nothing to blur asks for no prepass") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    Own own(g);
    REQUIRE_MESSAGE(own.ok, own.error);
    // A depth of field whose near and far blur are 0 draws nothing.
    {
        Scene s;
        s.dof(10.0f, 1.0f, 0.0f, 0.0f);
        own.draw(s.w);
        INFO(joined(own.order()));
        CHECK_FALSE(has_pass(own.order(), "prepass"));
        CHECK_FALSE(has_pass(own.order(), "dof-"));
    }
    // A depth of field that blurs does ask for it.
    {
        Scene s;
        s.dof(10.0f);
        own.draw(s.w);
        CHECK(has_pass(own.order(), "prepass"));
    }
    // A motion blur on the first frame (there is no frame before to move from) draws nothing, so it asks for nothing; the second frame does.
    {
        Own fresh(g);  // a renderer that has not drawn a camera with these ids before
        REQUIRE_MESSAGE(fresh.ok, fresh.error);
        Scene s;
        PostProcess& p = s.post();
        p.motionBlurEnabled = true;
        p.motionBlurIntensity = 1.0f;
        p.motionBlurMode = MotionBlurMode::Camera;
        fresh.draw(s.w);
        CHECK_FALSE(has_pass(fresh.order(), "prepass"));
        CHECK_FALSE(has_pass(fresh.order(), "motion-blur"));
        fresh.draw(s.w);
        CHECK(has_pass(fresh.order(), "prepass"));
        CHECK(has_pass(fresh.order(), "motion-blur"));
    }
    // The per-object blur asks for the velocity image from the first frame (the objects keep their models of the frame before), and blurs
    // from the second.
    {
        Own fresh(g);
        REQUIRE_MESSAGE(fresh.ok, fresh.error);
        Scene s;
        PostProcess& p = s.post();
        p.motionBlurEnabled = true;
        p.motionBlurIntensity = 1.0f;
        fresh.draw(s.w);
        CHECK(has_pass(fresh.order(), "prepass"));
        CHECK_FALSE(has_pass(fresh.order(), "motion-blur"));
        fresh.draw(s.w);
        CHECK(has_pass(fresh.order(), "motion-blur"));
        CHECK(has_pass(fresh.order(), "motion-velocity"));
    }
}

TEST_CASE(
    "motion blur: a world that jumped ahead (a seek, a scene load) is a cut, a few ticks between frames are not") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    Own own(g);
    REQUIRE_MESSAGE(own.ok, own.error);
    Scene s;
    PostProcess& p = s.post();
    p.motionBlurEnabled = true;
    p.motionBlurIntensity = 1.0f;
    own.draw(s.w);
    s.w.get<Transform>(s.cam)->position.x = 1.0f;
    for (int i = 0; i < 3; ++i) s.w.advance_clock(1.0 / 60.0);  // a slow frame: three ticks since the last drawn one
    own.draw(s.w);
    CHECK(has_pass(own.order(), "motion-blur"));
    s.w.get<Transform>(s.cam)->position.x = 2.0f;
    for (int i = 0; i < 40; ++i) s.w.advance_clock(1.0 / 60.0);  // forty ticks in one frame: a jump, not a movement
    own.draw(s.w);
    CHECK_FALSE(has_pass(own.order(), "motion-blur"));
    s.w.get<Transform>(s.cam)->position.x = 3.0f;
    own.draw(s.w);  // and the frame after it blurs again
    CHECK(has_pass(own.order(), "motion-blur"));
    s.w.get<Transform>(s.cam)->position.x = 4.0f;
    s.w.reset_clock();  // the clock went back: another scene
    own.draw(s.w);
    CHECK_FALSE(has_pass(own.order(), "motion-blur"));
}

// ---- M76-P1e: the per-object motion blur (shaders/motion_object.glsl) ----------------------------------------------------------------

namespace {

// A camera at (0, 0, 10) and ONE unlit white cube (2 m wide, its front face 9 m away: 35 px wide at the middle of the 320 x 180 picture) on
// a black sky: a moving white bar over a static black background, so a pixel's value is how much of the bar covers it.
struct Bar {
    World w;
    Entity cam = kNullEntity;
    Entity cube = kNullEntity;
    Bar() {
        cam = add_camera(w, {0, 0, 10});
        cube = add_cube(w, {0, 0, 0}, 2.0f);
    }
    PostProcess& post() { return post_of(w, cam); }
    void blur(MotionBlurMode mode, float radius = 24.0f, int samples = 16) {
        PostProcess& p = post();
        p.motionBlurEnabled = true;
        p.motionBlurIntensity = 1.0f;
        p.motionBlurSamples = samples;
        p.motionBlurMode = mode;
        p.motionBlurMaxRadius = radius;
    }
    void move_to(float x) { w.get<Transform>(cube)->position.x = x; }
};

// The first and the last x of row y whose red is above `level`; -1 when none.
void extent(const Image& img, int y, float level, int& first, int& last) {
    first = last = -1;
    for (int x = 0; x < img.width; ++x)
        if (img.pixel(x, y).r > level) {
            if (first < 0) first = x;
            last = x;
        }
}
// The mean absolute difference of two pictures over the three channels, in 0..255 steps.
double mean_abs_diff(const Image& a, const Image& b) {
    REQUIRE(a.width == b.width);
    REQUIRE(a.height == b.height);
    double sum = 0;
    for (std::size_t i = 0; i < a.rgba.size(); ++i) sum += std::abs(int(a.rgba[i]) - int(b.rgba[i]));
    return sum / double(a.rgba.size());
}

}  // namespace

TEST_CASE("per-object motion blur: the plan reads the mode, the radius in design pixels, and asks for the velocity "
          "image only in object mode") {
    World w;
    PostProcess fx;
    fx.motionBlurEnabled = true;
    fx.motionBlurIntensity = 0.5f;
    render::SceneFx fxState;
    const CameraInfo cam = camera_info();
    // The default is per-object; the radius is in design pixels times the render scale, in 1 .. 64 design pixels and at most 128 pixels.
    CHECK(fx.motionBlurMode == MotionBlurMode::Object);
    render::SceneFxPlan p = fxState.plan(w, cam, stack_of(fx), 1, 2, 0.016f, 1.0f, cam.viewProj, true);
    CHECK(p.motion);
    CHECK(p.objects);
    CHECK(p.maxRadiusPx == doctest::Approx(24.0f));
    fx.motionBlurMaxRadius = 10.0f;
    CHECK(fxState.plan(w, cam, stack_of(fx), 1, 3, 0.016f, 2.0f, cam.viewProj, true).maxRadiusPx ==
          doctest::Approx(20.0f));
    fx.motionBlurMaxRadius = 1000.0f;  // out of range
    CHECK(fxState.plan(w, cam, stack_of(fx), 1, 4, 0.016f, 1.0f, cam.viewProj, true).maxRadiusPx ==
          doctest::Approx(64.0f));
    CHECK(fxState.plan(w, cam, stack_of(fx), 1, 5, 0.016f, 4.0f, cam.viewProj, true).maxRadiusPx ==
          doctest::Approx(128.0f));
    fx.motionBlurMaxRadius = std::nanf("");
    CHECK(fxState.plan(w, cam, stack_of(fx), 1, 6, 0.016f, 1.0f, cam.viewProj, true).maxRadiusPx ==
          doctest::Approx(24.0f));
    fx.motionBlurMode = MotionBlurMode::Camera;
    CHECK_FALSE(fxState.plan(w, cam, stack_of(fx), 1, 7, 0.016f, 1.0f, cam.viewProj, true).objects);

    // The velocity image: object mode asks for it (also on the frames that do not blur yet: the first, a cut), camera mode, the effect off and
    // a null shutter do not.
    auto wants_velocity = [&](const PostProcess& f, bool on) {
        CameraInfo c = camera_info();
        PostStack s = stack_of(f);
        if (!on) s.mask = 0;
        c.postStack = std::make_shared<const PostStack>(s);
        return render::make_post_plan(c, false).needsVelocity;
    };
    PostProcess obj;
    obj.motionBlurEnabled = true;
    obj.motionBlurIntensity = 0.5f;
    CHECK(wants_velocity(obj, true));
    CHECK_FALSE(wants_velocity(obj, false));
    PostProcess still = obj;
    still.motionBlurIntensity = 0.0f;
    CHECK_FALSE(wants_velocity(still, true));
    PostProcess cameraOnly = obj;
    cameraOnly.motionBlurMode = MotionBlurMode::Camera;
    CHECK_FALSE(wants_velocity(cameraOnly, true));
    PostProcess off;
    CHECK_FALSE(wants_velocity(off, false));
}

TEST_CASE("per-object motion blur: a moving cube blurs along its motion over a background that stays sharp") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    // Frame 1 at x = 0, frame 2 at x = 1: the cube moved 17 px (a full shutter: its blur reaches 8.7 px on each side).
    auto two_frames = [&](MotionBlurMode mode, Image& out, std::vector<std::string>* order = nullptr) {
        Own own(g);
        REQUIRE_MESSAGE(own.ok, own.error);
        Bar b;
        b.blur(mode);
        own.draw(b.w);
        b.move_to(1.0f);
        out = own.draw(b.w);
        if (order) *order = own.order();
    };
    Image sharp, object;
    std::vector<std::string> order;
    two_frames(MotionBlurMode::Camera, sharp);  // the camera does not move: nothing blurs, the cube is where it is
    two_frames(MotionBlurMode::Object, object, &order);
    INFO(joined(order));
    CHECK(has_pass(order, "motion-velocity"));
    CHECK(has_pass(order, "motion-tile-x"));
    CHECK(has_pass(order, "motion-tile-y"));
    CHECK(has_pass(order, "motion-blur"));
    int sf, sl;
    extent(sharp, 90, 0.5f, sf, sl);
    REQUIRE(sf > 0);
    CHECK(soft_pixels(sharp, 90, 0, 320) <= 4);  // the control: the camera-only blur leaves a moving cube sharp
    // The cube is blurred along its motion: its two vertical edges are soft, wide as the streak.
    const int soft = soft_pixels(object, 90, 0, 320);
    MESSAGE("soft pixels " << soft << ", the cube is at " << sf << " .. " << sl);
    CHECK(soft >= 12);
    // Across the motion the edges stay as sharp as they were.
    CHECK(soft_pixels_col(object, (sf + sl) / 2, 0, 90) <= 4);
    // The background stays sharp: it is exactly black everywhere out of reach of the streak (10 px from the silhouette; the streak reaches 9).
    int bad = 0;
    for (int y = 0; y < object.height; ++y)
        for (int x = 0; x < object.width; ++x)
            if ((x < sf - 11 || x > sl + 11) && object.pixel(x, y).r > 0.01f) ++bad;
    CHECK(bad == 0);
    // The blur falls off over several pixels on the outside of the silhouette (the filter keeps the moving object's own edge, as McGuire's does).
    CHECK(soft_pixels(object, 90, 0, sf) >= 5);
    CHECK(soft_pixels(object, 90, sl + 1, 320) >= 5);
    // The background does not smear into the cube: its middle keeps all of its light.
    CHECK(object.pixel((sf + sl) / 2, 90).r > 0.95f);
    // The light of the streak stays: the picture has about as much light as the sharp one (the weights are normalised, not a fade).
    double lightSharp = 0, lightObject = 0;
    for (int x = 0; x < 320; ++x) {
        lightSharp += sharp.pixel(x, 90).r;
        lightObject += object.pixel(x, 90).r;
    }
    CHECK(lightObject == doctest::Approx(lightSharp).epsilon(0.15));
    // The same frame on every run.
    Image again;
    two_frames(MotionBlurMode::Object, again);
    CHECK(max_diff(object, again) == 0);
}

TEST_CASE("per-object motion blur: the longest streak is the radius, the speed past it is cut") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    // A cube that moves 3 m (52 px) in one frame, the radius 6 px: the blur reaches 6 px on each side and no farther; with the radius
    // 40 px the streak is the whole movement (it reaches 26 px).
    auto reach = [&](MotionBlurMode mode, float radius, int& spread) {
        Own own(g);
        REQUIRE_MESSAGE(own.ok, own.error);
        Bar b;
        b.blur(mode, radius);
        b.move_to(-1.5f);
        own.draw(b.w);
        b.move_to(1.5f);
        const Image img = own.draw(b.w);
        int first, last, f0, l0;
        extent(img, 90, 0.004f, first, last);  // where any light is
        extent(img, 90, 0.996f, f0, l0);       // where the cube is fully lit
        spread =
            (l0 - f0 + 1) < 0 ? 0 : (last - first + 1) - (l0 - f0 + 1);  // the pixels of the soft edges (both sides)
        return img;
    };
    int small = 0, large = 0, none = 0;
    const Image sharp = reach(MotionBlurMode::Camera, 6.0f, none);
    const Image a = reach(MotionBlurMode::Object, 6.0f, small);
    const Image b = reach(MotionBlurMode::Object, 40.0f, large);
    int sf, sl;
    extent(sharp, 90, 0.5f, sf, sl);
    int af, al;
    extent(a, 90, 0.004f, af, al);
    INFO("sharp cube " << sf << " .. " << sl << ", with radius 6: light " << af << " .. " << al << ", soft " << small
                       << " and with 40: soft " << large);
    CHECK(none <= 2);
    CHECK(af >= sf - 7);  // the blur of a pixel reaches 6 px on each side: one more for the filter of the picture
    CHECK(al <= sl + 7);
    CHECK(small >= 6);
    CHECK(large > small + 10);
}

TEST_CASE("per-object motion blur: a static scene and a moving camera blur like the camera-only blur") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    auto run = [&](MotionBlurMode mode, Image& out) {
        Own own(g);
        REQUIRE_MESSAGE(own.ok, own.error);
        Scene s;
        PostProcess& p = s.post();
        p.motionBlurEnabled = true;
        p.motionBlurIntensity = 1.0f;
        p.motionBlurSamples = 16;
        p.motionBlurMode = mode;
        own.draw(s.w);
        s.w.get<Transform>(s.cam)->position.x = 1.0f;
        out = own.draw(s.w);
    };
    Image camera, object;
    run(MotionBlurMode::Camera, camera);
    run(MotionBlurMode::Object, object);
    // Both smear the vertical edges of the cubes by the camera's movement (the near one 17 px, the far one 4 px) and not the horizontal ones.
    const int camSoft = soft_pixels(camera, 90, 60, 250);
    const int objSoft = soft_pixels(object, 90, 60, 250);
    MESSAGE("soft pixels: camera " << camSoft << ", object " << objSoft << "; mean difference "
                                   << mean_abs_diff(camera, object));
    CHECK(camSoft >= 12);
    CHECK(objSoft >= 12);
    CHECK(std::abs(objSoft - camSoft) <= camSoft / 2 + 4);
    CHECK(soft_pixels_col(object, 91, 60, 85) <= 4);
    // The two pictures differ by the weights of the taps only (a tent and a cylinder against a box), never by a shifted or a missing blur.
    CHECK(mean_abs_diff(camera, object) < 2.0);
    CHECK(max_diff(camera, object) < 140);
}

TEST_CASE("per-object motion blur: where no object wrote a velocity (the sky) the camera's own motion blurs it") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    // A physical sky with a big sun disc (20 degrees: a hard, bright edge) and no mesh at all: every pixel of the velocity image is the
    // sentinel. The camera turns 3 degrees between the two frames.
    auto run = [&](bool blur, MotionBlurMode mode, Image& out) {
        Own own(g);
        REQUIRE_MESSAGE(own.ok, own.error);
        World w;
        Entity cam = make(w, "cam", {0, 0, 0});
        auto& c = w.add<Camera>(cam);
        c.projection = Projection::Perspective;
        c.fov = 60.0f;
        w.settings().ambientLight = Color{0, 0, 0, 1};
        w.settings().skyModel = SkyModel::Physical;
        add_cube(w, {0, -1.5f, -20.0f},
                 1.0f);  // something to draw, so that the frame has a depth prepass (the sky stays the sentinel)
        w.settings().skySunSize = 20.0f;
        Entity sun = make(w, "sun", {0, 5, 0});
        auto& l = w.add<Light>(sun);
        l.type = LightType::Directional;
        l.intensity = 1.0f;
        l.castShadows = false;
        w.get<Transform>(sun)->rotation = {
            -10.0f, 180.0f, 0.0f};  // the sun 10 degrees over the horizon, on the side the camera looks to
        if (blur) {
            PostProcess& p = w.add<PostProcess>(cam);
            p.motionBlurEnabled = true;
            p.motionBlurIntensity = 1.0f;
            p.motionBlurSamples = 16;
            p.motionBlurMode = mode;
        }
        own.draw(w);
        w.get<Transform>(cam)->rotation = {0.0f, 3.0f, 0.0f};
        out = own.draw(w);
    };
    Image sharp, camera, object;
    run(false, MotionBlurMode::Object, sharp);
    run(true, MotionBlurMode::Camera, camera);
    run(true, MotionBlurMode::Object, object);
    // The row through the middle of the disc: the sun is a sharp-edged step; blurred, the step is spread over the streak.
    auto edge_width = [](const Image& img) {
        int n = 0;
        for (int y : {55, 60, 65})
            for (int x = 0; x < img.width; ++x) {
                const float v = img.pixel(x, y).r;
                const float lo = img.pixel(0, y).r, hi = img.pixel(img.width - 1, y).r;
                (void)lo;
                (void)hi;
                if (v > 0.1f && v < 0.9f) ++n;
            }
        return n;
    };
    INFO("sun edge pixels: sharp " << edge_width(sharp) << ", camera " << edge_width(camera) << ", object "
                                   << edge_width(object));
    CHECK(mean_abs_diff(sharp, camera) > 0.3);  // the camera's turn blurs the sun
    CHECK(mean_abs_diff(sharp, object) > 0.3);  // and so does the sentinel's fall back to the depth
    CHECK(mean_abs_diff(camera, object) < 0.6 * mean_abs_diff(sharp, camera) + 0.5);
}

TEST_CASE(
    "per-object motion blur: off and camera mode draw as before, and a world without a PostProcess does not change") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    // The effect off, in either mode: no pass of the blur, the picture of a world with no PostProcess at all.
    Image plain;
    {
        Own own(g);
        REQUIRE_MESSAGE(own.ok, own.error);
        Bar b;
        own.draw(b.w);
        b.move_to(1.0f);
        plain = own.draw(b.w);
        CHECK_FALSE(has_pass(own.order(), "motion-"));
    }
    for (const MotionBlurMode mode : {MotionBlurMode::Object, MotionBlurMode::Camera}) {
        Own own(g);
        REQUIRE_MESSAGE(own.ok, own.error);
        Bar b;
        b.blur(mode);
        b.post().motionBlurEnabled = false;
        own.draw(b.w);
        b.move_to(1.0f);
        const Image off = own.draw(b.w);
        CHECK_FALSE(has_pass(own.order(), "motion-"));
        CHECK(max_diff(off, plain) == 0);
    }
    // Camera mode: the passes of the camera-only blur and none of the per-object blur.
    {
        Own own(g);
        REQUIRE_MESSAGE(own.ok, own.error);
        Bar b;
        b.blur(MotionBlurMode::Camera);
        own.draw(b.w);
        b.move_to(1.0f);
        own.draw(b.w);
        const std::vector<std::string> order = own.order();
        INFO(joined(order));
        CHECK(has_pass(order, "motion-blur"));
        CHECK_FALSE(has_pass(order, "motion-velocity"));
        CHECK_FALSE(has_pass(order, "motion-tile"));
    }
}

TEST_CASE("per-object motion blur: with depth of field the gather reads the depth of field's picture and the frame is "
          "the same on every run") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    auto run = [&](Image& out) {
        Own own(g);
        REQUIRE_MESSAGE(own.ok, own.error);
        Bar b;
        b.blur(MotionBlurMode::Object);
        PostProcess& p = b.post();
        p.depthOfFieldEnabled = true;
        p.depthOfFieldFocusDistance = 10.0f;
        p.depthOfFieldFocusRange = 1.0f;
        p.depthOfFieldNearBlur = 4.0f;
        p.depthOfFieldFarBlur = 4.0f;
        own.draw(b.w);
        b.move_to(1.0f);
        out = own.draw(b.w);
        const std::vector<std::string> order = own.order();
        INFO(joined(order));
        CHECK(has_pass(order, "dof-composite"));
        CHECK(has_pass(order, "motion-velocity"));
        CHECK(has_pass(order, "motion-blur"));
        CHECK_FALSE(has_pass(order, "dof-copy"));
        CHECK_FALSE(has_pass(order, "motion-copy"));
    };
    Image a, b;
    run(a);
    run(b);
    CHECK(max_diff(a, b) == 0);
}
