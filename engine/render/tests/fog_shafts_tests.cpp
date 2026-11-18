// M71-D3b: distance and height fog and sun shafts (src/renderer_fog.cpp, shaders/fog.glsl, shaders/sun_shafts.glsl). The scenes are unlit white
// cubes on a black sky (a bright one for the shafts), so a pixel's value is read straight from the fog that covers it. The expected values come
// from the same law written out on the CPU (an integral along the view ray summed in small steps). The CPU parts (the plan, the sun's place on
// the screen) need no GPU.
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
#include "renderer_fog.h"

using namespace fa;
using namespace fa::test;
using render::PostStack;

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
Entity add_cube(World& w, Vec3 pos, float size, Color color = Color::white()) {
    Entity e = make(w, "cube", pos);
    w.get<Transform>(e)->scale = {size, size, size};
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

// The camera at (0, 0, 10) looking down -Z, 320 x 180, fov 60. `nearCube`: 2 m wide, its front face 9 m away, centred at pixel (108, 90).
// `farCube`: 9 m wide, its front face 49 m away, centred at pixel (207, 90).
struct Scene {
    World w;
    Entity cam = kNullEntity;
    Entity nearCube = kNullEntity;
    Entity farCube = kNullEntity;
    Scene() {
        cam = add_camera(w, {0, 0, 10});
        nearCube = add_cube(w, {-3, 0, 0}, 2.0f);
        farCube = add_cube(w, {14.8f, 0, -43.5f}, 9.0f);
    }
    PostProcess& post() { return post_of(w, cam); }
    void fog(float density, Color color = Color{0.5f, 0.5f, 0.5f, 1.0f}, float start = 0.0f) {
        PostProcess& p = post();
        p.fogEnabled = true;
        p.fogColor = color;
        p.fogDensity = density;
        p.fogStart = start;
    }
};

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

// The world position of the surface seen at pixel (px, py) of the 320 x 180 picture when its view depth is `depth`, for the camera at z = 10.
Vec3 surface_at(int px, int py, float depth) {
    const float nx = (float(px) + 0.5f) / 160.0f - 1.0f;
    const float ny = 1.0f - (float(py) + 0.5f) / 90.0f;
    const float tanV = std::tan(radians(30.0f));
    const float tanH = tanV * 16.0f / 9.0f;
    return Vec3{nx * tanH * depth, ny * tanV * depth, 10.0f - depth};
}

// The fog the law of fog.glsl gives a surface point seen from the camera at (0, 0, 10): the distance term (density * length)^2 plus the
// height term, the integral of the density along the ray summed in small steps. Returns f, the part of the fog colour that replaces the scene.
float expected_fog(Vec3 p, float density, float start, float heightDensity, float base, float falloff) {
    const Vec3 eye{0, 0, 10};
    const Vec3 d = p - eye;
    const float dist = std::sqrt(d.x * d.x + d.y * d.y + d.z * d.z);
    const float len = dist - start;
    if (len <= 0.0f) return 0.0f;
    float tau = (density * len) * (density * len);
    if (heightDensity > 0.0f) {
        const int n = 4000;
        double acc = 0.0;
        for (int i = 0; i < n; ++i) {
            const float t = start + len * (float(i) + 0.5f) / float(n);
            const float y = eye.y + d.y * (t / dist);
            const float k = y - base;
            const float h = (k <= 0.0f || falloff < 1e-4f) ? heightDensity : heightDensity * std::exp(-falloff * k);
            acc += double(h) * double(len) / double(n);
        }
        tau += float(acc);
    }
    return 1.0f - std::exp(-tau);
}

CameraGeometry camera_info(bool perspective = true) {
    CameraGeometry c;
    c.view = Mat4::translate({0, 0, -10});
    c.proj = perspective ? Mat4::perspective(60.0f, 16.0f / 9.0f, 0.1f, 1000.0f, true)
                         : Mat4::ortho(-8.0f, 8.0f, -4.5f, 4.5f, 0.1f, 1000.0f, true);
    c.viewProj = c.proj * c.view;
    c.invViewProj = c.viewProj.inverse();
    c.position = {0, 0, 10};
    c.perspective = perspective;
    return c;
}
PostStack stack_of(const PostProcess& fx) {
    PostStack s;
    s.fx = fx;
    if (fx.fogEnabled) s.mask |= 1u << int(PostEffect::Fog);
    if (fx.sunShaftsEnabled) s.mask |= 1u << int(PostEffect::SunShafts);
    return s;
}

}  // namespace

TEST_CASE("fog: both effects are drawn effects now (render.supports, post_drawn_mask)") {
    const std::uint32_t mask = render::post_drawn_mask();
    CHECK(((mask >> int(PostEffect::Fog)) & 1u) == 1u);
    CHECK(((mask >> int(PostEffect::SunShafts)) & 1u) == 1u);
}

TEST_CASE("fog: the plan clamps the stack's numbers, and draws nothing without a density or an intensity") {
    PostProcess fx;
    fx.fogEnabled = true;
    fx.fogDensity = 0.0f;
    const CameraGeometry cam = camera_info();
    CHECK_FALSE(render::fog_has_effect(stack_of(fx)));
    CHECK_FALSE(render::make_fog_plan(cam, stack_of(fx), false, nullptr).any());
    fx.fogHeightDensity = 0.2f;  // a height fog alone is a fog
    CHECK(render::make_fog_plan(cam, stack_of(fx), false, nullptr).fog);
    fx.fogHeightDensity = 0.0f;
    fx.fogDensity = std::nanf("");
    CHECK_FALSE(render::make_fog_plan(cam, stack_of(fx), false, nullptr).any());
    fx.fogDensity = 1000.0f;
    fx.fogStart = -5.0f;
    const render::FogFxPlan p = render::make_fog_plan(cam, stack_of(fx), false, nullptr);
    CHECK(p.fog);
    CHECK(p.density == doctest::Approx(10.0f));
    CHECK(p.start == doctest::Approx(0.0f));
    // The colour is in the scene's colour space: a linear scene gets linear light.
    fx.fogColor = Color{0.5f, 0.5f, 0.5f, 1.0f};
    CHECK(render::make_fog_plan(cam, stack_of(fx), false, nullptr).color[0] == doctest::Approx(0.5f));
    CHECK(render::make_fog_plan(cam, stack_of(fx), true, nullptr).color[0] == doctest::Approx(0.2140f).epsilon(0.01));
    // Off in the stack: nothing, whatever the numbers.
    PostStack off = stack_of(fx);
    off.mask = 0;
    CHECK_FALSE(render::make_fog_plan(cam, off, false, nullptr).any());
}

TEST_CASE("sun shafts: the sun's place on the screen, fading out behind the camera and off the screen") {
    const CameraGeometry cam = camera_info();
    Vec2 uv{};
    float fade = -1.0f;
    // Straight ahead: the middle of the screen, full strength.
    REQUIRE(render::sun_screen_position(cam, Vec3{0, 0, -1}, &uv, &fade));
    CHECK(uv.x == doctest::Approx(0.5f));
    CHECK(uv.y == doctest::Approx(0.5f));
    CHECK(fade == doctest::Approx(1.0f));
    // 15 degrees above the view direction: up the screen by tan(15) / tan(30) of half its height.
    const float a = radians(15.0f);
    REQUIRE(render::sun_screen_position(cam, Vec3{0, std::sin(a), -std::cos(a)}, &uv, &fade));
    CHECK(uv.x == doctest::Approx(0.5f));
    CHECK(uv.y == doctest::Approx(0.5f - 0.5f * std::tan(a) / std::tan(radians(30.0f))).epsilon(1e-4));
    CHECK(fade == doctest::Approx(1.0f));
    // Behind the camera: no place on the screen, no light.
    REQUIRE(render::sun_screen_position(cam, Vec3{0, 0.2f, 1}, &uv, &fade));
    CHECK(fade == 0.0f);
    // Beside the camera and far off the screen.
    REQUIRE(render::sun_screen_position(cam, Vec3{1, 0, -0.05f}, &uv, &fade));
    CHECK(fade == 0.0f);
    // Just outside the edge: weaker, not gone.
    const float b = radians(33.0f);
    REQUIRE(render::sun_screen_position(cam, Vec3{0, std::sin(b), -std::cos(b)}, &uv, &fade));
    CHECK(fade > 0.0f);
    CHECK(fade < 1.0f);
    // An orthographic camera has no place for a sun at infinity; a bad direction has none either.
    CHECK_FALSE(render::sun_screen_position(camera_info(false), Vec3{0, 0, -1}, &uv, &fade));
    CHECK_FALSE(render::sun_screen_position(cam, Vec3{std::nanf(""), 0, -1}, &uv, &fade));
    CHECK_FALSE(render::sun_screen_position(cam, Vec3{0, 0, 0}, &uv, &fade));

    // The plan: no sun (no directional light), no shafts; a sun behind the camera, none either; one in front, with the intensity faded.
    PostProcess fx;
    fx.sunShaftsEnabled = true;
    fx.sunShaftsIntensity = 0.8f;
    CHECK_FALSE(render::make_fog_plan(cam, stack_of(fx), false, nullptr).shafts);
    const Vec3 behind{0, 0, 1}, ahead{0, 0, -1};
    CHECK_FALSE(render::make_fog_plan(cam, stack_of(fx), false, &behind).shafts);
    const render::FogFxPlan p = render::make_fog_plan(cam, stack_of(fx), false, &ahead);
    CHECK(p.shafts);
    CHECK(p.intensity == doctest::Approx(0.8f));
    fx.sunShaftsIntensity = 0.0f;
    CHECK_FALSE(render::make_fog_plan(cam, stack_of(fx), false, &ahead).any());
    fx.sunShaftsIntensity = 0.8f;
    fx.sunShaftsLength = 0.0f;
    CHECK_FALSE(render::make_fog_plan(cam, stack_of(fx), false, &ahead).any());
}

TEST_CASE("fog: a far object is closer to the fog colour than a near one, as the law says; the sky is not fogged") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    for (const int samples : {1, 4}) {
        CAPTURE(samples);
        Own own(g, samples);
        REQUIRE_MESSAGE(own.ok, own.error);
        Scene plain;
        plain.w.settings().skyColor = plain.w.settings().horizonColor = Color{0.8f, 0.2f, 0.2f, 1.0f};
        const Image reference = own.draw(plain.w);
        CHECK_FALSE(has_pass(own.order(), "fog-"));
        CHECK_FALSE(has_pass(own.order(), "prepass"));  // nothing reads the depth: no prepass
        CHECK(reference.pixel(108, 90).r > 0.99f);
        CHECK(reference.pixel(207, 90).r > 0.99f);

        Scene s;
        s.w.settings().skyColor = s.w.settings().horizonColor = Color{0.8f, 0.2f, 0.2f, 1.0f};
        s.fog(0.02f);
        const Image img = own.draw(s.w);
        const std::vector<std::string> order = own.order();
        INFO(joined(order));
        CHECK(has_pass(order, "/prepass"));
        const float nearR = img.pixel(108, 90).r, farR = img.pixel(207, 90).r;
        CHECK(std::fabs(farR - 0.5f) < std::fabs(nearR - 0.5f) - 0.2f);  // the far one is much closer to the fog colour
        const float fNear = expected_fog(surface_at(108, 90, 9.0f), 0.02f, 0, 0, 0, 0);
        const float fFar = expected_fog(surface_at(207, 90, 49.0f), 0.02f, 0, 0, 0, 0);
        CHECK(nearR == doctest::Approx(1.0f - 0.5f * fNear).epsilon(0.02));
        CHECK(farR == doctest::Approx(1.0f - 0.5f * fFar).epsilon(0.02));
        CHECK(img.pixel(207, 90).g == doctest::Approx(farR).epsilon(0.01));  // a grey fog keeps the white grey
        // The sky is the picture without the fog, to the last bit.
        CHECK(max_diff(img, reference, 0, 0, 60, 60) == 0);
        CHECK(img.pixel(20, 20).r > 0.7f);
        // The effect off again: the same picture as a scene that never had a stack.
        Scene off;
        off.w.settings().skyColor = off.w.settings().horizonColor = Color{0.8f, 0.2f, 0.2f, 1.0f};
        off.post();
        CHECK(max_diff(own.draw(off.w), reference) == 0);
        CHECK_FALSE(has_pass(own.order(), "fog-"));
        // Switched on with nothing to draw (no density): the same, and no prepass for it.
        Scene zero;
        zero.w.settings().skyColor = zero.w.settings().horizonColor = Color{0.8f, 0.2f, 0.2f, 1.0f};
        zero.fog(0.0f);
        CHECK(max_diff(own.draw(zero.w), reference) == 0);
        CHECK_FALSE(has_pass(own.order(), "fog-"));
        CHECK_FALSE(has_pass(own.order(), "prepass"));
    }
}

TEST_CASE("fog: fogStart keeps what is nearer than it clear") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    Own own(g);
    REQUIRE_MESSAGE(own.ok, own.error);
    Scene plain;
    const Image reference = own.draw(plain.w);
    Scene s;
    s.fog(0.05f, Color{0.5f, 0.5f, 0.5f, 1.0f}, 20.0f);
    const Image img = own.draw(s.w);
    // The near cube (9 .. 11 m) is closer than the start: untouched, to the last bit; the far one (49 m) has 29 m of fog.
    CHECK(max_diff(img, reference, 80, 60, 140, 120) == 0);
    const float farR = img.pixel(207, 90).r;
    CHECK(farR ==
          doctest::Approx(1.0f - 0.5f * expected_fog(surface_at(207, 90, 49.0f), 0.05f, 20.0f, 0, 0, 0)).epsilon(0.02));
    CHECK(farR < 0.55f);
    // A start beyond everything: no pixel changes.
    Scene beyond;
    beyond.fog(0.05f, Color{0.5f, 0.5f, 0.5f, 1.0f}, 500.0f);
    CHECK(max_diff(own.draw(beyond.w), reference) == 0);
}

TEST_CASE("fog: the height fog is thicker below fogHeightBase and thins above it, along the whole ray") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    Own own(g);
    REQUIRE_MESSAGE(own.ok, own.error);
    // Two cubes at the same distance, one 3.5 m above the camera and one 3.5 m below, on a layer of fog that is thickest at y = 0.
    Scene s;
    s.w.destroy_immediate(s.nearCube);
    s.w.destroy_immediate(s.farCube);
    add_cube(s.w, {-2, 3.5f, 0}, 1.5f);
    add_cube(s.w, {-2, -3.5f, 0}, 1.5f);
    PostProcess& p = s.post();
    p.fogEnabled = true;
    p.fogColor = Color{0, 0, 0, 1};  // black fog: a pixel's value is how much of the scene is left
    p.fogDensity = 0.0f;
    p.fogHeightDensity = 0.3f;
    p.fogHeightBase = 0.0f;
    p.fogHeightFalloff = 0.5f;
    const Image img = own.draw(s.w);
    INFO(joined(own.order()));
    CHECK(has_pass(own.order(), "/prepass"));
    // The cubes' front faces are 9.25 m away (z = 0.75), at pixels (126, 31) above and (126, 149) below.
    const float up = img.pixel(126, 31).r, down = img.pixel(126, 149).r;
    CHECK(up > down + 0.15f);
    CHECK(up == doctest::Approx(1.0f - expected_fog(surface_at(126, 31, 9.25f), 0, 0, 0.3f, 0.0f, 0.5f)).epsilon(0.03));
    CHECK(down ==
          doctest::Approx(1.0f - expected_fog(surface_at(126, 149, 9.25f), 0, 0, 0.3f, 0.0f, 0.5f)).epsilon(0.03));
    // Moving the base up above both cubes makes them equally thick (the layer is flat up to its base).
    p.fogHeightBase = 10.0f;
    p.fogHeightFalloff = 0.5f;
    const Image flat = own.draw(s.w);
    CHECK(std::fabs(flat.pixel(126, 31).r - flat.pixel(126, 149).r) < 0.03f);
    // A height density of 0 draws no fog at all (no pass).
    p.fogHeightDensity = 0.0f;
    own.draw(s.w);
    CHECK_FALSE(has_pass(own.order(), "fog-"));
}

TEST_CASE("fog: the stack's fog replaces SceneSettings.fogDensity, so the two never add up") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    Own own(g);
    REQUIRE_MESSAGE(own.ok, own.error);
    const Color fogColor{0.5f, 0.6f, 0.7f, 1.0f};
    // The forward fog alone.
    Scene forward;
    forward.w.settings().fogColor = fogColor;
    forward.w.settings().fogDensity = 0.02f;
    const Image fwd = own.draw(forward.w);
    CHECK_FALSE(has_pass(own.order(), "fog-"));
    // The stack's fog alone: the same law, so the same picture (within the rounding of two different paths).
    Scene stackOnly;
    stackOnly.fog(0.02f, fogColor);
    const Image st = own.draw(stackOnly.w);
    CHECK(has_pass(own.order(), "/prepass"));
    CHECK(max_diff(st, fwd, 80, 60, 240, 120) <= 3);
    CHECK(fwd.pixel(207, 90).r < 0.75f);  // the fog is there
    // Both on: the stack's fog stands in for the scene's; if both were drawn the far cube would be fogged a second time.
    Scene both;
    both.w.settings().fogColor = fogColor;
    both.w.settings().fogDensity = 0.02f;
    both.fog(0.02f, fogColor);
    const Image b = own.draw(both.w);
    CHECK(max_diff(b, st, 0, 0, 320, 180) <= 1);
    // A stack whose fog draws nothing (no density) leaves the scene's fog alone.
    Scene idle;
    idle.w.settings().fogColor = fogColor;
    idle.w.settings().fogDensity = 0.02f;
    idle.fog(0.0f, fogColor);
    CHECK(max_diff(own.draw(idle.w), fwd) == 0);
}

TEST_CASE("fog: in a linear scene the fog colour is the colour the display shows when the fog is thick") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    Own own(g);
    REQUIRE_MESSAGE(own.ok, own.error);
    Scene s;
    s.w.settings().colorSpace = ColorSpace::Linear;
    s.fog(5.0f, Color{0.5f, 0.6f, 0.7f, 1.0f}, 20.0f);
    const Image img = own.draw(s.w);
    CHECK(has_pass(own.order(), "/prepass"));
    const Color c = img.pixel(207, 90);
    CHECK(c.r == doctest::Approx(0.5f).epsilon(0.02));
    CHECK(c.g == doctest::Approx(0.6f).epsilon(0.02));
    CHECK(c.b == doctest::Approx(0.7f).epsilon(0.02));
    CHECK(img.pixel(108, 90).r > 0.97f);  // the near cube is before the start
}

TEST_CASE("fog: in a split screen each camera fogs its own rectangle only") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    auto make_split = [](Scene& s, bool withFog) {
        auto& left = *s.w.get<Camera>(s.cam);
        left.viewport = {0, 0, 0.5f, 1};
        const Entity right = add_camera(s.w, {0, 0, 10}, "right");
        auto& rc = *s.w.get<Camera>(right);
        rc.viewport = {0.5f, 0, 0.5f, 1};
        rc.depth = 1;
        if (withFog) s.fog(0.03f);  // the left camera's stack only
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
    CHECK(has_pass(order, "/prepass"));
    // The right half is the picture without the effect, to the last bit; the left half has the cubes fogged.
    CHECK(max_diff(img, reference, 160, 0, 320, 180) == 0);
    CHECK(max_diff(img, reference, 0, 0, 160, 180) > 20);
    // Both with their own fog: the right one has none of the left one's, and the left one is not changed by it.
    Scene both;
    const Entity right = make_split(both, true);
    PostProcess& rp = post_of(both.w, right);
    rp.fogEnabled = true;
    rp.fogColor = Color{0, 0, 0, 1};
    rp.fogDensity = 0.03f;
    const Image two = own.draw(both.w);
    CHECK(max_diff(two, img, 0, 0, 160, 180) == 0);
    CHECK(max_diff(two, reference, 160, 0, 320, 180) > 20);
    CHECK(max_diff(two, img, 160, 0, 320, 180) > 20);  // black fog on the right
}

// The fog of what is drawn after the opaque meshes (blended meshes, sprites): each fogs itself by its own distance, not by the opaque mesh
// or the sky behind it. A cube at `centre` (its front face 1 m nearer than the centre) is a blended mesh by its alpha of 0.99.
static Entity add_glass(World& w, Vec3 pos, float size) { return add_cube(w, pos, size, Color{1, 1, 1, 0.99f}); }

TEST_CASE("fog: a blended mesh over the sky is fogged, and in front of a far fogged cube it shows its own fog, not the "
          "far one's") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    for (const int samples : {1, 4}) {
        CAPTURE(samples);
        Own own(g, samples);
        REQUIRE_MESSAGE(own.ok, own.error);
        // Over the sky: a 2 m glass cube whose front face is 18 m away, at pixel (229, 38), where nothing opaque is behind it.
        Scene s;
        s.fog(0.05f);
        add_glass(s.w, {8, 6, -9}, 2.0f);
        const Image img = own.draw(s.w);
        INFO(joined(own.order()));
        CHECK(has_pass(own.order(), "/prepass"));
        const float f = expected_fog(surface_at(229, 38, 18.0f), 0.05f, 0, 0, 0, 0);
        CHECK(f > 0.3f);
        CHECK(img.pixel(229, 38).r == doctest::Approx(0.99f * (1.0f - 0.5f * f)).epsilon(0.03));
        // The sky around it keeps no fog (the sky is not fogged).
        CHECK(img.pixel(300, 10).r < 0.02f);
        // In front of the far cube (pixel (207, 90), 49 m): a glass cube 12 m from the camera, covering that pixel.
        Scene t;
        t.fog(0.05f);
        add_glass(t.w, {3.66f, 0, -3}, 2.0f);
        const Image front = own.draw(t.w);
        const float fOwn = expected_fog(surface_at(207, 90, 12.0f), 0.05f, 0, 0, 0, 0);
        const float fFar = expected_fog(surface_at(207, 90, 49.0f), 0.05f, 0, 0, 0, 0);
        CHECK(fFar > 0.95f);  // behind it the cube is all fog colour
        CHECK(fOwn < 0.5f);
        CHECK(front.pixel(207, 90).r == doctest::Approx(0.99f * (1.0f - 0.5f * fOwn) + 0.01f * 0.5f).epsilon(0.04));
        // A sprite 12 m away over the same cube is fogged by its own distance too.
        Scene u;
        u.fog(0.05f);
        const Entity spr = make(u.w, "spr", {3.66f, 0, -2});
        auto& sp = u.w.add<Sprite>(spr);
        sp.size = {2, 2};
        sp.color = Color{1, 1, 1, 1};
        const Image sprite = own.draw(u.w);
        const float fSprite = expected_fog(surface_at(207, 90, 12.0f), 0.05f, 0, 0, 0, 0);
        CHECK(sprite.pixel(207, 90).r == doctest::Approx(1.0f - 0.5f * fSprite).epsilon(0.04));
        // Without the stack's fog nothing of this changes the picture: a glass cube and a sprite draw as before.
        Scene off;
        add_glass(off.w, {8, 6, -9}, 2.0f);
        const Image none = own.draw(off.w);
        CHECK(none.pixel(229, 38).r > 0.97f);
    }
}

namespace {
// The sky is grey (0.6), the cube dark, the sun 15 degrees above the view direction in front of the camera (pixel (160, 48)).
struct SunScene {
    World w;
    Entity cam = kNullEntity;
    Entity sun = kNullEntity;
    explicit SunScene(bool sunAhead = true) {
        cam = add_camera(w, {0, 0, 10});
        w.settings().skyColor = w.settings().horizonColor = Color{0.6f, 0.6f, 0.6f, 1.0f};
        // Below the sun: its top edge is at pixel row 62, the sun at (160, 48); the sky between them lights the cube's top rows.
        add_cube(w, {0, 0.62f, 0}, 2.0f, Color{0.2f, 0.2f, 0.2f, 1.0f});
        sun = make(w, "sun", {0, 5, 0});
        // A directional light shines along the entity's forward: toward +Z (and down) when the sun is ahead of the camera.
        w.get<Transform>(sun)->rotation = sunAhead ? Vec3{-15, 180, 0} : Vec3{-15, 0, 0};
        auto& l = w.add<Light>(sun);
        l.type = LightType::Directional;
    }
    PostProcess& post() { return post_of(w, cam); }
    void shafts(float intensity = 0.5f, float threshold = 0.3f, float length = 0.5f) {
        PostProcess& p = post();
        p.sunShaftsEnabled = true;
        p.sunShaftsIntensity = intensity;
        p.sunShaftsThreshold = threshold;
        p.sunShaftsLength = length;
        p.sunShaftsColor = Color{1, 1, 1, 1};
    }
};
}  // namespace

TEST_CASE("sun shafts: rays stream from the sun's place, stronger near it; nothing with the sun behind the camera") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    for (const int samples : {1, 4}) {
        CAPTURE(samples);
        Own own(g, samples);
        REQUIRE_MESSAGE(own.ok, own.error);
        SunScene plain;
        const Image reference = own.draw(plain.w);
        CHECK_FALSE(has_pass(own.order(), "shafts-"));
        CHECK_FALSE(has_pass(own.order(), "prepass"));
        // The sky is bright and the cube dark, as the scene says.
        CHECK(reference.pixel(20, 20).r > 0.5f);
        CHECK(reference.pixel(160, 48).r > 0.5f);  // the sun's place is sky
        CHECK(reference.pixel(160, 90).r < 0.4f);  // the cube is below it

        SunScene s;
        s.shafts();
        const Image img = own.draw(s.w);
        const std::vector<std::string> order = own.order();
        INFO(joined(order));
        CHECK(has_pass(order, "shafts-rays"));
        CHECK(has_pass(order, "shafts-add"));
        // On the cube, where the sky between it and the sun lights it: lighter than without the shafts.
        const float onCube = img.pixel(160, 70).r - reference.pixel(160, 70).r;
        CHECK(onCube > 0.03f);
        // The sky near the sun gets more of them than the sky far from it.
        const float nearSun = img.pixel(160, 12).r - reference.pixel(160, 12).r;
        const float farSun = img.pixel(15, 170).r - reference.pixel(15, 170).r;
        CHECK(nearSun > farSun + 0.03f);
        // The rays run toward the sun: a pixel on the sun's side of the cube is brighter than one at the same distance on the other side
        // (the line from the second pixel to the sun runs through the cube, which blocks the light).
        const float sunSide = img.pixel(160, 66).r - reference.pixel(160, 66).r;
        CHECK(sunSide > onCube - 1.0f / 255.0f);  // nearer to the sky that lights it: at least as bright
        // Nothing above one: the picture clamps and never goes NaN.
        CHECK(img.pixel(160, 12).r <= 1.0f);

        // The sun behind the camera: no pass, the same picture.
        SunScene behind(false);
        behind.shafts();
        CHECK(max_diff(own.draw(behind.w), reference) == 0);
        CHECK_FALSE(has_pass(own.order(), "shafts-"));
        CHECK_FALSE(has_pass(own.order(), "prepass"));  // the shafts alone, with no sun in view, ask for no depth

        // A threshold above the brightness of the sky: no light is cast, so the picture does not change.
        SunScene dim;
        dim.shafts(1.0f, 0.95f);
        CHECK(max_diff(own.draw(dim.w), reference) == 0);

        // A stack with the shafts off: the same picture as no stack at all.
        SunScene off;
        off.post();
        CHECK(max_diff(own.draw(off.w), reference) == 0);

        // No directional light: no sun, no shafts.
        SunScene dark;
        dark.shafts();
        dark.w.destroy_immediate(dark.sun);
        CHECK(max_diff(own.draw(dark.w), reference) <= 0);
        CHECK_FALSE(has_pass(own.order(), "shafts-"));
        CHECK_FALSE(has_pass(own.order(), "prepass"));

        // A sun that does not shine (intensity 0) is no sun: no shafts, no prepass for them.
        SunScene unlit;
        unlit.shafts();
        unlit.w.get<Light>(unlit.sun)->intensity = 0.0f;
        CHECK(max_diff(own.draw(unlit.w), reference) == 0);
        CHECK_FALSE(has_pass(own.order(), "shafts-"));
        CHECK_FALSE(has_pass(own.order(), "prepass"));

        // The same frame twice is the same picture (the jitter is a fixed pattern).
        CHECK(max_diff(own.draw(s.w), img) == 0);
    }
}

TEST_CASE("sun shafts: in a split screen each camera has its own sun place and rectangle") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    auto make_split = [](SunScene& s, bool withShafts) {
        auto& left = *s.w.get<Camera>(s.cam);
        left.viewport = {0, 0, 0.5f, 1};
        const Entity right = add_camera(s.w, {0, 0, 10}, "right");
        s.w.settings().skyColor = s.w.settings().horizonColor = Color{0.6f, 0.6f, 0.6f, 1.0f};
        auto& rc = *s.w.get<Camera>(right);
        rc.viewport = {0.5f, 0, 0.5f, 1};
        rc.depth = 1;
        if (withShafts) s.shafts();  // the left camera's stack only
        return right;
    };
    Own own(g);
    REQUIRE_MESSAGE(own.ok, own.error);
    SunScene plain;
    make_split(plain, false);
    const Image reference = own.draw(plain.w);
    SunScene s;
    make_split(s, true);
    const Image img = own.draw(s.w);
    INFO(joined(own.order()));
    CHECK(has_pass(own.order(), "shafts-add"));
    CHECK(max_diff(img, reference, 160, 0, 320, 180) == 0);  // the right camera's rectangle is untouched
    CHECK(max_diff(img, reference, 0, 0, 160, 180) > 10);    // the left one has its rays
}
