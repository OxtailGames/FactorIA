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

TEST_CASE("depth of field: smooth_focus moves by the engine clock only, and stays put when it has no speed or a bad number") {
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
    CHECK(a == b);  // the same frames give the same focus, bit for bit
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

TEST_CASE("depth of field: an object at the focus stays sharp, one far behind it is blurred, off is the same picture as no stack") {
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
        CHECK(soft_pixels(img, 90, 80, 140) <= 6);   // at the focus: as sharp as without the effect
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
    CHECK(img.pixel(125, 90).r > 0.05f);   // the near blur reaches outside the silhouette ...
    CHECK(img.pixel(160, 90).r > 0.9f);    // ... and the middle of the cube stays bright
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

TEST_CASE("motion blur: a still camera gives the same picture, a moving one smears along its movement, a cut or the first frame do not") {
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
