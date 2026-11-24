// M76-P2: temporal antialiasing (src/renderer_taa.cpp, shaders/taa.glsl, taa_shared.glsl). The scenes are a white unlit square turned 30 degrees on a
// black sky, so everything the resolve does shows on its diagonal edges. The pictures are compared as means over the edge pixels and as pixel
// counts, with thresholds far from what the resolve reaches (they run on every backend, with 8-bit captures). The pure CPU part (the plan)
// needs no GPU.
#include "test_util.h"

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <string>
#include <vector>

#include "frame_graph.h"
#include "postprocess.h"
#include "render_features.h"
#include "render_internal.h"
#include "renderer_taa.h"
#include "renderer_test_access.h"

using namespace fa;
using namespace fa::test;
using render::CameraInfo;
using render::PostStack;

namespace {

// A renderer of its own on the test GPU (the history and the frame counters are the renderer's, so each test starts clean).
struct Own {
    Gfx& g;
    Renderer r;
    bool ok = false;
    std::string error;
    int width, height;
    explicit Own(Gfx& gx, int w = 320, int h = 180) : g(gx), width(w), height(h) {
        RendererDesc d;
        d.designWidth = w;
        d.designHeight = h;
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
            w.advance_clock(1.0 / 60.0);
            r.begin_frame();
            r.render_world(w, 1.0f / 60.0f);
            r.end_frame();
            g.gpu.end_frame();
        }
    }
    Image capture() {
        Image img;
        std::string err;
        const bool captured = r.capture(img, &err);
        INFO("capture error: " << err);
        REQUIRE(captured);
        return img;
    }
    Image draw(World& w, int n = 1) {
        frame(w, n);
        return capture();
    }
    std::vector<std::string> order() {
        const render::FrameGraph* graph = render::renderer_frame_graph(r);
        REQUIRE(graph != nullptr);
        return graph->order_names();
    }
};

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

// A white square (unlit cube seen face on) turned 30 degrees on a black sky; the camera at z = 10 looks down -Z. The square is 3 m wide: about
// 78 px of a 320 x 180 picture.
struct Scene {
    World w;
    Entity cam = kNullEntity;
    Entity box = kNullEntity;
    Scene() {
        const float x = 0.0f;
        cam = make(w, "cam", {x, 0, 10});
        auto& c = w.add<Camera>(cam);
        c.projection = Projection::Perspective;
        c.fov = 60.0f;
        c.clearColor = Color{0, 0, 0, 1};
        w.settings().skyColor = w.settings().horizonColor = Color{0, 0, 0, 1};
        box = make(w, "box", {x, 0, 0});
        Transform* t = w.get<Transform>(box);
        t->scale = {3.0f, 3.0f, 3.0f};
        t->rotation = {0.0f, 0.0f, 30.0f};
        auto& m = w.add<MeshRenderer>(box);
        m.mesh = "cube";
        m.color = Color::white();
        m.unlit = true;
    }
    PostProcess& post() { return camera_post(w, cam); }
    void taa(bool on = true) { post().temporalAAEnabled = on; }
    void move_x(float x) { w.get<Transform>(cam)->position.x = x; }
};

// The picture's red channel as values 0..1, row 0 on top. The headless target is linear (a coverage of one half is a value of one half), so a
// mean of the samples of a pixel is the mean of their values.
std::vector<float> linear_plane(const Image& img) {
    std::vector<float> v(std::size_t(img.width) * std::size_t(img.height));
    for (std::size_t i = 0; i < v.size(); ++i) v[i] = float(img.rgba[i * 4]) / 255.0f;
    return v;
}
// A picture drawn `k` times larger, averaged down by k x k boxes: the supersampled reference of a picture of width / k.
std::vector<float> reference_plane(const Image& big, int k) {
    const int w = big.width / k, h = big.height / k;
    const std::vector<float> src = linear_plane(big);
    std::vector<float> out(std::size_t(w) * std::size_t(h), 0.0f);
    for (int y = 0; y < h; ++y)
        for (int x = 0; x < w; ++x) {
            float s = 0;
            for (int j = 0; j < k; ++j)
                for (int i = 0; i < k; ++i)
                    s += src[std::size_t(y * k + j) * std::size_t(big.width) + std::size_t(x * k + i)];
            out[std::size_t(y) * std::size_t(w) + std::size_t(x)] = s / float(k * k);
        }
    return out;
}
// The mean absolute error of `img` against `ref` over the edge pixels of the reference (neither black nor white there), and how many there are.
double edge_error(const std::vector<float>& img, const std::vector<float>& ref, int* edges = nullptr) {
    REQUIRE(img.size() == ref.size());
    double sum = 0;
    int n = 0;
    for (std::size_t i = 0; i < ref.size(); ++i) {
        if (ref[i] <= 0.01f || ref[i] >= 0.99f) continue;
        sum += std::fabs(double(img[i]) - double(ref[i]));
        ++n;
    }
    if (edges) *edges = n;
    return n > 0 ? sum / n : 0.0;
}
// Pixels that the reference has black (and its neighbours too, so an edge pixel does not count) where `img` is lit: the trail of a ghost.
int ghost_pixels(const std::vector<float>& img, const std::vector<float>& ref, int w, int h, float lit = 0.15f) {
    int n = 0;
    for (int y = 1; y + 1 < h; ++y)
        for (int x = 1; x + 1 < w; ++x) {
            bool dark = true;
            for (int j = -1; j <= 1; ++j)
                for (int i = -1; i <= 1; ++i)
                    dark = dark && ref[std::size_t(y + j) * std::size_t(w) + std::size_t(x + i)] < 0.005f;
            if (dark && img[std::size_t(y) * std::size_t(w) + std::size_t(x)] > lit) ++n;
        }
    return n;
}
bool same_pixels(const Image& a, const Image& b) {
    return a.width == b.width && a.height == b.height && a.rgba == b.rgba;
}

// The 4 x 4 supersampled picture of the scene (a renderer of 1280 x 720 draws it), averaged down to 320 x 180; the camera at `cameraX`.
std::vector<float> supersampled(Gfx& g, float cameraX = 0.0f) {
    Own big(g, 1280, 720);
    REQUIRE_MESSAGE(big.ok, big.error);
    Scene s;
    s.move_x(cameraX);
    return reference_plane(big.draw(s.w), 4);
}

}  // namespace

TEST_CASE("temporal antialiasing: the plan is off without the effect, off for a frame that is not the game's, and "
          "clamps its numbers") {
    CameraInfo cam;
    cam.view = Mat4::translate({0, 0, -10});
    cam.proj = Mat4::perspective(60.0f, 16.0f / 9.0f, 0.1f, 1000.0f, true);
    cam.viewProj = cam.proj * cam.view;
    cam.perspective = true;
    PostStack off;
    PostStack on;
    on.fx.temporalAAEnabled = true;
    on.mask = 1u << int(PostEffect::TemporalAA);
    const Mat4 prev = cam.viewProj;
    CHECK_FALSE(render::make_taa_plan(cam, off, true, true, 7, 5, 1, 0, prev, true).on);
    CHECK_FALSE(render::make_taa_plan(cam, on, false, true, 7, 5, 1, 0, prev, true)
                    .on);  // a capture of the world between two frames
    CHECK_FALSE(render::make_taa_plan(cam, on, true, false, 7, 5, 1, 0, prev, true).on);  // the shaders failed
    const render::TaaPlan p = render::make_taa_plan(cam, on, true, true, 7, 5, 11, 3, prev, true);
    CHECK(p.on);
    CHECK(p.prevValid);
    CHECK(p.camKey == 7);
    CHECK(p.serial == 5);
    CHECK(p.sceneKey == 11);
    CHECK(p.originShifts == 3);
    CHECK(p.feedback == doctest::Approx(0.9f));
    // The same camera as the frame before: a view-space point goes to the clip position it has now (the matrix of a still camera).
    const Vec4 a = p.prevFromView * Vec4{1.0f, 2.0f, -5.0f, 1.0f};
    const Vec4 b = cam.proj * Vec4{1.0f, 2.0f, -5.0f, 1.0f};
    CHECK(a.x / a.w == doctest::Approx(b.x / b.w).epsilon(1e-4));
    CHECK(a.y / a.w == doctest::Approx(b.y / b.w).epsilon(1e-4));
    // No frame before: no reprojection.
    CHECK_FALSE(render::make_taa_plan(cam, on, true, true, 7, 5, 1, 0, prev, false).prevValid);
    // Numbers the stack cannot use: clamped, or the default for what is not a number.
    on.fx.temporalAAFeedback = 5.0f;
    on.fx.temporalAASharpen = -1.0f;
    on.fx.temporalAAVarianceGamma = std::nanf("");
    on.fx.temporalAAReactiveScale = 100.0f;
    const render::TaaPlan c = render::make_taa_plan(cam, on, true, true, 7, 5, 1, 0, prev, true);
    CHECK(c.feedback == doctest::Approx(0.98f));
    CHECK(c.sharpen == 0.0f);
    CHECK(c.gamma == doctest::Approx(1.0f));
    CHECK(c.reactiveScale == doctest::Approx(4.0f));
}

TEST_CASE("temporal antialiasing: render.supports says it is drawn on every backend") {
    CHECK(((render::post_drawn_mask() >> int(PostEffect::TemporalAA)) & 1u) == 1u);
}

TEST_CASE("temporal antialiasing: off draws no pass, no image and no jitter, and the picture is the same bit for bit") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    Image plain;
    {
        Own own(g);
        REQUIRE_MESSAGE(own.ok, own.error);
        Scene s;
        plain = own.draw(s.w, 4);
        CHECK_FALSE(has_pass(own.order(), "taa"));
        CHECK(RendererTestAccess::taa_images(own.r) == 0);
        for (const Vec2& j : RendererTestAccess::last_jitter(own.r)) {
            CHECK(j.x == 0.0f);
            CHECK(j.y == 0.0f);
        }
    }
    {
        // The fields of the effect are ignored while it is off.
        Own own(g);
        REQUIRE_MESSAGE(own.ok, own.error);
        Scene s;
        s.post().temporalAAFeedback = 0.5f;
        s.post().temporalAASharpen = 1.0f;
        s.post().temporalAAVarianceGamma = 2.0f;
        const Image again = own.draw(s.w, 4);
        CHECK(same_pixels(plain, again));
        CHECK_FALSE(has_pass(own.order(), "taa"));
    }
    {
        // On, then off: the passes and the history go, and the picture is the plain one again.
        Own own(g);
        REQUIRE_MESSAGE(own.ok, own.error);
        Scene s;
        s.taa();
        own.frame(s.w, 3);
        CHECK(has_pass(own.order(), "taa-resolve"));
        CHECK(RendererTestAccess::taa_images(own.r) == 2);
        s.taa(false);
        const Image off = own.draw(s.w, 3);
        CHECK_FALSE(has_pass(own.order(), "taa"));
        CHECK(RendererTestAccess::taa_images(own.r) == 0);
        CHECK(same_pixels(plain, off));
    }
}

TEST_CASE("temporal antialiasing: the jitter and the passes exist only while the effect is on") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    Own own(g);
    REQUIRE_MESSAGE(own.ok, own.error);
    Scene s;
    s.taa();
    bool jittered = false;
    for (int f = 0; f < 4; ++f) {
        own.frame(s.w);
        const std::vector<Vec2> j = RendererTestAccess::last_jitter(own.r);
        REQUIRE(j.size() == 1);
        jittered = jittered || j[0].x != 0.0f || j[0].y != 0.0f;
        CHECK(std::fabs(j[0].x) <= 0.5f);
        CHECK(std::fabs(j[0].y) <= 0.5f);
    }
    CHECK(jittered);
    const std::vector<std::string> names = own.order();
    INFO(joined(names));
    CHECK(has_pass(names, "taa-resolve"));
    CHECK(has_pass(names, "taa-output"));
    // The resolve sits before the depth of field and the final pass, after the scene is drawn.
    std::size_t resolve = 0, output = 0;
    for (std::size_t i = 0; i < names.size(); ++i) {
        if (names[i].find("taa-resolve") != std::string::npos) resolve = i;
        if (names[i].find("taa-output") != std::string::npos) output = i;
    }
    CHECK(resolve > 0);
    CHECK(output == resolve + 1);
    s.taa(false);
    own.frame(s.w);
    for (const Vec2& j : RendererTestAccess::last_jitter(own.r)) {
        CHECK(j.x == 0.0f);
        CHECK(j.y == 0.0f);
    }
}

TEST_CASE(
    "temporal antialiasing: a still diagonal edge converges to the supersampled picture far better than without it") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    const std::vector<float> ref = supersampled(g);
    double plainError = 0, taaError = 0;
    int edges = 0;
    {
        Own own(g);
        REQUIRE_MESSAGE(own.ok, own.error);
        Scene s;
        plainError = edge_error(linear_plane(own.draw(s.w, 4)), ref, &edges);
    }
    REQUIRE(edges > 100);
    {
        Own own(g);
        REQUIRE_MESSAGE(own.ok, own.error);
        Scene s;
        s.taa();
        const Image img = own.draw(s.w, 40);
        CHECK(RendererTestAccess::taa_used_history(own.r, s.cam));
        taaError = edge_error(linear_plane(img), ref);
    }
    INFO("edge pixels " << edges << ", error without " << plainError << ", with " << taaError);
    CHECK(plainError > 0.05);
    CHECK(taaError < 0.4 * plainError);
}

TEST_CASE(
    "temporal antialiasing: an 8-bit history (a GPU without half-float targets) converges too, and says so once") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    const std::vector<float> ref = supersampled(g);
    Own own(g);
    REQUIRE_MESSAGE(own.ok, own.error);
    RendererTestAccess::taa_force_rgba8(own.r, true);
    Scene s;
    s.taa();
    const Image img = own.draw(s.w, 40);
    CHECK(RendererTestAccess::taa_format(own.r) == int(SG_PIXELFORMAT_RGBA8));
    double plainError = 0;
    {
        Own plainOwn(g);
        REQUIRE_MESSAGE(plainOwn.ok, plainOwn.error);
        Scene p;
        plainError = edge_error(linear_plane(plainOwn.draw(p.w, 4)), ref);
    }
    const double taaError = edge_error(linear_plane(img), ref);
    INFO("error without " << plainError << ", with an 8-bit history " << taaError);
    CHECK(taaError < 0.5 * plainError);
}

TEST_CASE(
    "temporal antialiasing: a panning camera leaves no ghost behind the edge (reprojected from the prepass depth)") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    const float step = 0.06f;  // 1.5 px a frame
    const int frames = 40;
    Own own(g);
    REQUIRE_MESSAGE(own.ok, own.error);
    Scene s;
    s.taa();
    Image img;
    for (int f = 1; f <= frames; ++f) {
        s.move_x(step * float(f));
        img = own.draw(s.w);
    }
    // The camera moved, the square stayed: the reference is the supersampled picture from the last place of the camera.
    const std::vector<float> got = linear_plane(img);
    Own bigOwn(g, 1280, 720);
    REQUIRE_MESSAGE(bigOwn.ok, bigOwn.error);
    Scene bigScene;
    bigScene.move_x(step * float(frames));
    const std::vector<float> truth = reference_plane(bigOwn.draw(bigScene.w), 4);
    const int ghosts = ghost_pixels(got, truth, img.width, img.height);
    const double err = edge_error(got, truth);
    // The same walk without the effect: the edge error of an aliased edge.
    double plainErr = 0;
    {
        Own plainOwn(g);
        REQUIRE_MESSAGE(plainOwn.ok, plainOwn.error);
        Scene p;
        p.move_x(step * float(frames));
        plainErr = edge_error(linear_plane(plainOwn.draw(p.w, 3)), truth);
    }
    INFO("ghost pixels " << ghosts << ", edge error " << err << ", without the effect " << plainErr);
    CHECK(ghosts < 25);  // a ghost of ten frames is a band of 15 px along four edges: hundreds
    CHECK(err < 0.8 * plainErr);
}

TEST_CASE("temporal antialiasing: a moving object leaves no ghost behind its edge (the motion vector of the prepass, "
          "M76-P1b)") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    const float step =
        0.06f;  // 1.7 px a frame, the camera does not move: the depth reprojection alone would find no motion at all
    const int frames = 40;
    Own own(g);
    REQUIRE_MESSAGE(own.ok, own.error);
    RendererTestAccess::force_velocity(own.r,
                                       true);  // also keeps the velocity image of the last frame for the check below
    Scene s;
    s.taa();
    Image img;
    for (int f = 1; f <= frames; ++f) {
        s.w.get<Transform>(s.box)->position.x = step * float(f);
        img = own.draw(s.w);
    }
    // The vector the resolve read at the middle of the square: the square's own motion (uvPrev - uvCurr, so to the left), not the sentinel.
    // The front face is 8.5 m from the camera: 4.9 m of half height over 90 px.
    std::vector<float> vel;
    int vw = 0, vh = 0;
    std::string err;
    REQUIRE_MESSAGE(RendererTestAccess::read_velocity(own.r, vel, vw, vh, &err), err);
    const float pxPerMetre = 90.0f / (8.5f * std::tan(30.0f * 3.14159265f / 180.0f));
    const int cx = 160 + int(step * float(frames) * pxPerMetre), cy = 90;
    const std::size_t at = (std::size_t(cy) * std::size_t(vw) + std::size_t(cx)) * 4;
    REQUIRE(vw == img.width);
    CHECK_FALSE(render::VelocityRef::is_none(vel[at]));
    CHECK(vel[at] == doctest::Approx(-step * pxPerMetre / float(vw)).epsilon(0.1));
    CHECK(std::fabs(vel[at + 1]) < 5.0e-4f);
    // The reference: the square at its last place, supersampled.
    const std::vector<float> got = linear_plane(img);
    Own bigOwn(g, 1280, 720);
    REQUIRE_MESSAGE(bigOwn.ok, bigOwn.error);
    Scene bigScene;
    bigScene.w.get<Transform>(bigScene.box)->position.x = step * float(frames);
    const std::vector<float> truth = reference_plane(bigOwn.draw(bigScene.w), 4);
    const int ghosts = ghost_pixels(got, truth, img.width, img.height);
    const double e = edge_error(got, truth);
    double plainErr = 0;
    {
        Own plainOwn(g);
        REQUIRE_MESSAGE(plainOwn.ok, plainOwn.error);
        Scene p;
        p.w.get<Transform>(p.box)->position.x = step * float(frames);
        plainErr = edge_error(linear_plane(plainOwn.draw(p.w, 3)), truth);
    }
    INFO("ghost pixels " << ghosts << ", edge error " << e << ", without the effect " << plainErr);
    CHECK(ghosts < 25);  // a ghost of ten frames is a band of 17 px along the trailing edges: hundreds
    CHECK(e < 0.8 * plainErr);
}

TEST_CASE("temporal antialiasing: a cut, a resize and a render scale change start the history again; a still frame "
          "keeps it") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    Own own(g);
    REQUIRE_MESSAGE(own.ok, own.error);
    Scene s;
    s.taa();
    own.frame(s.w);
    CHECK_FALSE(RendererTestAccess::taa_used_history(own.r, s.cam));  // the first frame has no history
    own.frame(s.w);
    CHECK(RendererTestAccess::taa_used_history(own.r, s.cam));
    const int started = RendererTestAccess::taa_resets(own.r);
    own.frame(s.w, 3);
    CHECK(RendererTestAccess::taa_used_history(own.r, s.cam));
    CHECK(RendererTestAccess::taa_resets(own.r) == started);  // nothing dropped it

    // A cut: the world jumped forty ticks ahead (a seek, a scene load).
    for (int i = 0; i < 40; ++i) s.w.advance_clock(1.0 / 60.0);
    own.frame(s.w);
    CHECK_FALSE(RendererTestAccess::taa_used_history(own.r, s.cam));
    CHECK(RendererTestAccess::taa_resets(own.r) == started + 1);
    own.frame(s.w);
    CHECK(RendererTestAccess::taa_used_history(own.r, s.cam));

    // The camera did not draw a frame: another camera was the one, the history of the first is gone.
    s.w.set_active(s.cam, false);
    const Entity other = make(s.w, "other", {0, 0, 10});
    s.w.add<Camera>(other).projection = Projection::Perspective;
    own.frame(s.w, 3);
    s.w.set_active(s.cam, true);
    s.w.destroy_immediate(other);
    own.frame(s.w);
    CHECK_FALSE(RendererTestAccess::taa_used_history(own.r, s.cam));
    own.frame(s.w);
    CHECK(RendererTestAccess::taa_used_history(own.r, s.cam));

    // A resize: the images have another size.
    const int beforeResize = RendererTestAccess::taa_resets(own.r);
    own.r.set_target_size(256, 144);
    own.frame(s.w);
    CHECK_FALSE(RendererTestAccess::taa_used_history(own.r, s.cam));
    CHECK(RendererTestAccess::taa_resets(own.r) == beforeResize + 1);
    own.frame(s.w);
    CHECK(RendererTestAccess::taa_used_history(own.r, s.cam));

    // A change of the render scale: the same.
    const int beforeScale = RendererTestAccess::taa_resets(own.r);
    own.r.set_render_scale(0.5f);
    own.frame(s.w);
    CHECK_FALSE(RendererTestAccess::taa_used_history(own.r, s.cam));
    CHECK(RendererTestAccess::taa_resets(own.r) == beforeScale + 1);
    own.frame(s.w);
    CHECK(RendererTestAccess::taa_used_history(own.r, s.cam));
}

TEST_CASE("temporal antialiasing: a floating-origin shift starts the history again and does not smear the picture") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    Own own(g);
    REQUIRE_MESSAGE(own.ok, own.error);
    Scene s;
    s.taa();
    const float step = 0.06f;
    for (int f = 1; f <= 20; ++f) {
        s.move_x(step * float(f));
        own.frame(s.w);
    }
    CHECK(RendererTestAccess::taa_used_history(own.r, s.cam));
    const int before = RendererTestAccess::taa_resets(own.r);
    const std::uint64_t shifts = RendererTestAccess::origin_shifts(own.r);
    // The world moves by -4096 m in x (every local position, the camera's too) and the next frame draws what the frame without it would have.
    s.w.rebase({4096.0f, 0.0f, 0.0f});
    s.move_x(s.w.get<Transform>(s.cam)->position.x + step);
    const Image after = own.draw(s.w);
    CHECK(RendererTestAccess::origin_shifts(own.r) == shifts + 1);
    CHECK_FALSE(RendererTestAccess::taa_used_history(own.r, s.cam));
    CHECK(RendererTestAccess::taa_resets(own.r) == before + 1);
    // The picture is the square where it has to be: the camera is at 21 steps and the square at x = 0 (shifted with the world).
    const std::vector<float> got = linear_plane(after);
    Own bigOwn(g, 1280, 720);
    REQUIRE_MESSAGE(bigOwn.ok, bigOwn.error);
    Scene bigScene;
    bigScene.move_x(step * 21.0f);
    const std::vector<float> truth = reference_plane(bigOwn.draw(bigScene.w), 4);
    CHECK(ghost_pixels(got, truth, after.width, after.height) < 25);
    CHECK(edge_error(got, truth) <
          0.45);  // no history yet: an aliased edge, but in the right place (a smear or a jump is far over this)
    own.frame(s.w);
    CHECK(RendererTestAccess::taa_used_history(own.r, s.cam));
}

TEST_CASE("temporal antialiasing: the history is freed when the camera stops asking for a frame") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    Own own(g);
    REQUIRE_MESSAGE(own.ok, own.error);
    Scene s;
    s.taa();
    own.frame(s.w, 3);
    CHECK(RendererTestAccess::taa_images(own.r) == 2);
    s.w.set_active(s.cam, false);
    own.frame(s.w, 3);
    CHECK(RendererTestAccess::taa_images(own.r) == 0);
}
