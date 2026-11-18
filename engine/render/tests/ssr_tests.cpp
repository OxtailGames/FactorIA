// M71-D3a: screen-space reflections (src/renderer_ssr.cpp, shaders/ssr.glsl). The scenes are an unlit black floor and an unlit red cube on it,
// seen by a camera at height 3 that looks down -Z: the floor shows the cube mirrored below it, and the geometry of that mirror image is
// known (see `Scene`). The pure CPU parts (the plan, the drawn mask, the prepass gating) need no GPU.
#include "test_util.h"

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <memory>
#include <string>
#include <vector>

#include "frame_graph.h"
#include "postprocess.h"
#include "postprocess_resolve.h"
#include "render_features.h"
#include "render_internal.h"
#include "renderer_ssr.h"

using namespace fa;
using namespace fa::test;
using render::CameraInfo;
using render::PostStack;

namespace {

// A renderer of its own on the test GPU, at 320x180 design pixels.
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
Entity add_box(World& w, Vec3 pos, Vec3 size, Color color) {
    Entity e = make(w, "box", pos);
    w.get<Transform>(e)->scale = size;
    auto& m = w.add<MeshRenderer>(e);
    m.mesh = "cube";
    m.color = color;
    m.unlit = true;
    return e;
}
PostProcess& post_of(World& w, Entity cam) {
    PostProcess* p = w.get<PostProcess>(cam);
    return p ? *p : w.add<PostProcess>(cam);
}
void enable_ssr(PostProcess& p, float intensity = 1.0f, int steps = 32) {
    p.ssrEnabled = true;
    p.ssrIntensity = intensity;
    p.ssrSteps = steps;
}

// The camera at (x, 3, 10) looks down -Z at a floor (40 x 40, its top at y = 0) with a 1 m cube standing on it at (x, 0 .. 1, 0). The focal
// length is 90 / tan(30 deg) = 155.9 px, so the cube's front face (9.5 m away) is x = 152 .. 168 and its bottom edge is row 139, its top row
// 123. The floor mirrors that face below the bottom edge: the mirror image of the face point at height h is at row 139 + 15.4 * h, so rows
// 140 .. 154 of columns 153 .. 167 show it. A floor pixel below that (row 160 and further) reflects the sky over the top of the cube.
struct Scene {
    World w;
    Entity cam = kNullEntity;
    float x = 0.0f;
    explicit Scene(float cx = 0.0f, float cubeX = 0.0f) : x(cx) {
        cam = add_camera(w, {cx, 3, 10});
        add_box(w, {cx, -0.1f, 0}, {40, 0.2f, 40}, Color{0, 0, 0, 1});
        add_box(w, {cubeX, 0.5f, 0}, {1, 1, 1}, Color{1, 0, 0, 1});
    }
    PostProcess& post() { return post_of(w, cam); }
};

// The mean of the red channel over a rectangle of pixels [x0, x1) x [y0, y1).
float mean_red(const Image& img, int x0, int y0, int x1, int y1) {
    double sum = 0;
    int n = 0;
    for (int y = y0; y < y1; ++y)
        for (int x = x0; x < x1; ++x) {
            sum += img.pixel(x, y).r;
            ++n;
        }
    return float(sum / std::max(n, 1));
}
float max_red(const Image& img, int x0, int y0, int x1, int y1) {
    float m = 0;
    for (int y = y0; y < y1; ++y)
        for (int x = x0; x < x1; ++x) m = std::max(m, img.pixel(x, y).r);
    return m;
}
bool all_finite_colors(const Image& img) {
    for (int y = 0; y < img.height; ++y)
        for (int x = 0; x < img.width; ++x) {
            const Color c = img.pixel(x, y);
            if (!std::isfinite(c.r) || !std::isfinite(c.g) || !std::isfinite(c.b) || !std::isfinite(c.a)) return false;
        }
    return true;
}
bool same_bytes(const Image& a, const Image& b) {
    return a.width == b.width && a.height == b.height && a.rgba == b.rgba;
}
int count_passes(const std::vector<std::string>& names, const char* part) {
    int n = 0;
    for (const std::string& s : names)
        if (s.find(part) != std::string::npos) ++n;
    return n;
}
std::string joined(const std::vector<std::string>& names) {
    std::string o;
    for (const std::string& s : names) o += s + " ";
    return o;
}

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
    if (fx.ssrEnabled) s.mask |= 1u << int(PostEffect::Ssr);
    return s;
}

}  // namespace

TEST_CASE("ssr: the effect is a drawn effect (render.supports, post_drawn_mask) and its passes count as post passes") {
    CHECK(((render::post_drawn_mask() >> int(PostEffect::Ssr)) & 1u) == 1u);
    CHECK(is_post_pass("camera:0/ssr-trace"));
    CHECK(is_post_pass("ssr-copy"));
    CHECK_FALSE(is_post_pass("ssrx"));
}

TEST_CASE(
    "ssr: the plan clamps every number, takes the camera's projection and is empty without intensity or an effect") {
    PostProcess fx;
    fx.ssrEnabled = true;
    const CameraInfo cam = camera_info();
    render::SsrPlan p = render::make_ssr_plan(cam, stack_of(fx));
    REQUIRE(p.any());
    CHECK(p.intensity == doctest::Approx(0.5f));  // the default: a matte wall must not look like a mirror
    CHECK(PostProcess{}.ssrIntensity == doctest::Approx(0.5f));
    CHECK(p.steps == 32);
    CHECK(p.maxDistance == doctest::Approx(50.0f));
    CHECK(p.thickness == doctest::Approx(0.3f));
    CHECK(p.proj[0] == doctest::Approx(cam.proj.at(0, 0)));
    CHECK(p.proj[1] == doctest::Approx(cam.proj.at(1, 1)));
    CHECK(p.proj[6] == doctest::Approx(-1.0f));  // a perspective camera: clip w = -z

    fx.ssrSteps = 1;
    CHECK(render::make_ssr_plan(cam, stack_of(fx)).steps == 8);
    fx.ssrSteps = 100000;
    CHECK(render::make_ssr_plan(cam, stack_of(fx)).steps == 128);
    fx.ssrIntensity = 7.0f;
    fx.ssrThickness = 0.0f;
    fx.ssrMaxDistance = std::nanf("");
    p = render::make_ssr_plan(cam, stack_of(fx));
    CHECK(p.intensity == doctest::Approx(1.0f));
    CHECK(p.thickness == doctest::Approx(0.01f));
    CHECK(p.maxDistance == doctest::Approx(50.0f));

    fx.ssrIntensity = std::nanf("");
    CHECK(render::make_ssr_plan(cam, stack_of(fx)).intensity == doctest::Approx(0.5f));
    fx.ssrIntensity = 0.0f;
    CHECK_FALSE(render::make_ssr_plan(cam, stack_of(fx)).any());
    CHECK_FALSE(render::ssr_active(stack_of(fx)));
    fx.ssrIntensity = 1.0f;
    fx.ssrEnabled = false;
    CHECK_FALSE(render::make_ssr_plan(cam, stack_of(fx)).any());

    // An orthographic camera: clip w is 1.
    fx.ssrEnabled = true;
    CameraInfo ortho = cam;
    ortho.proj = Mat4::ortho(-8.0f, 8.0f, -4.5f, 4.5f, 0.1f, 100.0f, true);
    const render::SsrPlan o = render::make_ssr_plan(ortho, stack_of(fx));
    CHECK(o.any());
    CHECK(o.proj[6] == doctest::Approx(0.0f));
    CHECK(o.proj[7] == doctest::Approx(1.0f));
    // A matrix that is not usable draws nothing.
    CameraInfo broken = cam;
    broken.proj = Mat4{};
    broken.proj.at(0, 0) = 0.0f;
    CHECK_FALSE(render::make_ssr_plan(broken, stack_of(fx)).any());
}

TEST_CASE("ssr: the prepass is planned only for an effect that draws something") {
    CameraInfo cam = camera_info();
    PostProcess fx;
    fx.ssrEnabled = true;
    cam.postStack = std::make_shared<PostStack>(stack_of(fx));
    render::PostPlan plan = render::make_post_plan(cam, false);
    CHECK(plan.needsDepth);
    CHECK(plan.needsNormals);

    fx.ssrIntensity = 0.0f;
    cam.postStack = std::make_shared<PostStack>(stack_of(fx));
    plan = render::make_post_plan(cam, false);
    CHECK_FALSE(plan.needsDepth);
    CHECK_FALSE(plan.needsNormals);

    PostProcess off;
    cam.postStack = std::make_shared<PostStack>(stack_of(off));
    plan = render::make_post_plan(cam, false);
    CHECK_FALSE(plan.needsDepth);
}

TEST_CASE("ssr: a cube on a floor appears mirrored in it, at the pixels the geometry says, and the off states draw the "
          "same frame") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    for (const int samples : {1, 4}) {
        CAPTURE(samples);
        Own own(g, samples);
        REQUIRE_MESSAGE(own.ok, own.error);
        Scene plain;
        const Image reference = own.draw(plain.w);
        CHECK(count_passes(own.order(), "ssr-") == 0);
        CHECK(count_passes(own.order(), "prepass") == 0);
        CHECK(reference.pixel(160, 130).r > 0.95f);             // the cube
        CHECK(max_red(reference, 100, 140, 220, 180) < 0.02f);  // the floor: black

        // Off in the three ways: no stack, a stack without the effect, the effect without intensity. The same bytes, and no pass.
        Scene noEffect;
        noEffect.post().vignetteEnabled = false;
        CHECK(same_bytes(own.draw(noEffect.w), reference));
        Scene noIntensity;
        enable_ssr(noIntensity.post(), 0.0f);
        const Image zero = own.draw(noIntensity.w);
        CHECK(same_bytes(zero, reference));
        CHECK(count_passes(own.order(), "ssr-") == 0);
        CHECK(count_passes(own.order(), "prepass") == 0);  // nothing else needs it: not drawn

        Scene s;
        enable_ssr(s.post());
        const Image img = own.draw(s.w);
        const std::vector<std::string> order = own.order();
        INFO(joined(order));
        CHECK(count_passes(order, "prepass") == 1);
        CHECK(count_passes(order, "ssr-trace") == 1);
        CHECK(count_passes(order, "ssr-copy") == 1);
        CHECK(all_finite_colors(img));
        // The mirror image: red under the cube, in the columns of its face and the rows below its bottom edge...
        CHECK(mean_red(img, 155, 142, 165, 152) > 0.15f);
        CHECK(img.pixel(160, 147).r > 0.15f);
        CHECK(img.pixel(160, 147).r < 0.6f);  // a reflection mixed in with the fresnel term, not a mirror
        CHECK(img.pixel(160, 147).g < 0.05f);
        CHECK(img.pixel(160, 147).b < 0.05f);
        // ... and nowhere else: beside it, far below it (the rays go over the top of the cube) and in the sky.
        CHECK(max_red(img, 100, 142, 140, 156) < 0.02f);
        CHECK(max_red(img, 180, 142, 220, 156) < 0.02f);
        CHECK(max_red(img, 140, 162, 180, 180) < 0.02f);
        CHECK(max_red(img, 0, 0, 320, 100) == doctest::Approx(max_red(reference, 0, 0, 320, 100)));
        // The cube itself is untouched (its normal faces the camera, so its reflection goes back to the camera and finds nothing).
        CHECK(img.pixel(160, 130).r > 0.95f);
        // Half the intensity: about half the reflection.
        Scene half;
        enable_ssr(half.post(), 0.5f);
        const float full = mean_red(img, 155, 142, 165, 152);
        const float halfRed = mean_red(own.draw(half.w), 155, 142, 165, 152);
        CHECK(halfRed > 0.3f * full);
        CHECK(halfRed < 0.7f * full);
        // The effect off again: the same picture as a scene that never had a stack.
        Scene off;
        off.post().ssrEnabled = false;
        CHECK(same_bytes(own.draw(off.w), reference));
        CHECK(count_passes(own.order(), "ssr-") == 0);
    }
}

TEST_CASE("ssr: nothing off the screen is reflected") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    Own own(g);
    REQUIRE_MESSAGE(own.ok, own.error);
    // The cube is 30 m to the left: out of the picture. Its mirror image would be on the floor, but the screen has no light to reflect.
    Scene s(0.0f, -30.0f);
    enable_ssr(s.post());
    const Image img = own.draw(s.w);
    CHECK(count_passes(own.order(), "ssr-trace") == 1);  // the effect runs (and finds nothing)
    CHECK(all_finite_colors(img));
    CHECK(max_red(img, 0, 0, 320, 180) < 0.02f);
}

TEST_CASE("ssr: a split screen traces each camera in its own rectangle") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    Own own(g);
    REQUIRE_MESSAGE(own.ok, own.error);
    // Two worlds side by side: the left camera at x = 0 and the right one at x = 100, each with a floor and a cube.
    auto build = [](World& w, bool leftSsr, bool rightSsr) {
        const Entity left = add_camera(w, {0, 3, 10}, "left");
        const Entity right = add_camera(w, {100, 3, 10}, "right");
        w.get<Camera>(left)->viewport = Rect{0, 0, 0.5f, 1};
        w.get<Camera>(right)->viewport = Rect{0.5f, 0, 0.5f, 1};
        w.get<Camera>(right)->depth = 1;
        for (const float x : {0.0f, 100.0f}) {
            add_box(w, {x, -0.1f, 0}, {40, 0.2f, 40}, Color{0, 0, 0, 1});
            add_box(w, {x, 0.5f, 0}, {1, 1, 1}, Color{1, 0, 0, 1});
        }
        if (leftSsr) enable_ssr(post_of(w, left));
        if (rightSsr) enable_ssr(post_of(w, right));
    };
    {
        World w;
        build(w, true, false);
        const Image img = own.draw(w);
        INFO(joined(own.order()));
        CHECK(count_passes(own.order(), "ssr-trace") == 1);
        CHECK(mean_red(img, 75, 142, 85, 152) > 0.15f);   // the left half: the mirror image under the cube at column 80
        CHECK(max_red(img, 235, 142, 245, 152) < 0.02f);  // the right half has no effect
        CHECK(img.pixel(80, 130).r > 0.95f);
        CHECK(img.pixel(240, 130).r > 0.95f);
    }
    {
        World w;
        build(w, false, true);
        const Image img = own.draw(w);
        CHECK(max_red(img, 75, 142, 85, 152) < 0.02f);
        CHECK(mean_red(img, 235, 142, 245, 152) > 0.15f);
        // The reflection stays inside the rectangle of its camera: the left half is untouched all over.
        CHECK(max_red(img, 0, 0, 160, 120) < 0.02f);
    }
    {
        World w;
        build(w, true, true);
        const Image img = own.draw(w);
        CHECK(count_passes(own.order(), "ssr-trace") == 2);
        CHECK(count_passes(own.order(), "ssr-copy") == 2);
        CHECK(mean_red(img, 75, 142, 85, 152) > 0.15f);
        CHECK(mean_red(img, 235, 142, 245, 152) > 0.15f);
        // Both halves look alike (the same scene seen by cameras of the same size), and nothing crosses the seam.
        CHECK(mean_red(img, 75, 142, 85, 152) == doctest::Approx(mean_red(img, 235, 142, 245, 152)).epsilon(0.05));
        CHECK(max_red(img, 150, 142, 170, 156) < 0.02f);
        CHECK(all_finite_colors(img));
    }
}

TEST_CASE("ssr: more steps find at least what fewer steps find, every count is finite, and the range is clamped") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    Own own(g);
    REQUIRE_MESSAGE(own.ok, own.error);
    float prev = -1.0f;
    float at32 = 0.0f;
    for (const int steps : {8, 32, 128, 5, 100000}) {
        CAPTURE(steps);
        Scene s;
        enable_ssr(s.post(), 1.0f, steps);
        const Image img = own.draw(s.w);
        CHECK(count_passes(own.order(), "ssr-trace") == 1);
        CHECK(all_finite_colors(img));
        const float m = mean_red(img, 153, 141, 167, 155);
        CHECK(m < 0.6f);
        CHECK(max_red(img, 100, 142, 140, 156) < 0.02f);
        if (steps == 32) at32 = m;
        if (steps == 128) {
            CHECK(m >= prev - 0.02f);  // 8 steps: a thin object can fall between two steps; 128 never finds less
            CHECK(m > 0.1f);
        }
        prev = m;
    }
    CHECK(at32 > 0.1f);
}
