// M76-P4: the temporal upscaler (UpscaleImpl::Temporal in src/renderer_upscale.cpp, TaaFx::upscale in src/renderer_taa.cpp, the resolve of
// shaders/taa_shared.glsl). The scenes are the white unlit square turned 30 degrees of taa_tests.cpp (plus a red marker at the top left of the
// picture, so a flipped copy shows), drawn at half the output size and resolved to the output size. The pictures are compared as means over the
// edge pixels and as pixel counts, with thresholds far from what the resolve reaches (they run on every backend, with 8-bit captures). The
// planning of the stage (phases, mode, plan) needs no GPU.
#include "test_util.h"

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <limits>
#include <string>
#include <vector>

#include "frame_graph.h"
#include "postprocess.h"
#include "render_features.h"
#include "render_internal.h"
#include "render_upscale.h"
#include "renderer_taa.h"
#include "renderer_test_access.h"
#include "fa/render/upscaler.h"
#include "fa/scene/jitter.h"

using namespace fa;
using namespace fa::test;
using render::CameraInfo;
using render::PostStack;
using render::UpscaleImpl;
using render::UpscalerMode;
using render::UpscalerQuality;
using render::UpscalerSettings;

namespace {

constexpr int kOutW = 320, kOutH = 180;

struct Own {
    Gfx& g;
    Renderer r;
    bool ok = false;
    std::string error;
    explicit Own(Gfx& gx, int w = kOutW, int h = kOutH) : g(gx) {
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
    // The renderer draws at `scale` of the output size and the upscale stage brings it back; `mode` as a game would set it.
    void upscale(float scale, UpscalerMode mode = UpscalerMode::Temporal,
                 UpscalerQuality quality = UpscalerQuality::Performance, float sharpness = 0.5f) {
        r.set_render_scale(scale);
        r.set_upscale_stage(true);
        UpscalerSettings u;
        u.mode = mode;
        u.quality = quality;
        u.sharpness = sharpness;
        r.set_upscaler(u);
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

// The white square of taa_tests.cpp, and a red 1 m square at the top left of the picture (world -6, 3: pixel 66, 43 of 320 x 180).
struct Scene {
    World w;
    Entity cam = kNullEntity;
    Entity box = kNullEntity;
    Entity marker = kNullEntity;
    Scene() {
        cam = make(w, "cam", {0, 0, 10});
        auto& c = w.add<Camera>(cam);
        c.projection = Projection::Perspective;
        c.fov = 60.0f;
        c.clearColor = Color{0, 0, 0, 1};
        w.settings().skyColor = w.settings().horizonColor = Color{0, 0, 0, 1};
        box = make(w, "box", {0, 0, 0});
        Transform* t = w.get<Transform>(box);
        t->scale = {3.0f, 3.0f, 3.0f};
        t->rotation = {0.0f, 0.0f, 30.0f};
        auto& m = w.add<MeshRenderer>(box);
        m.mesh = "cube";
        m.color = Color::white();
        m.unlit = true;
        marker = make(w, "marker", {-6, 3, 0});
        w.get<Transform>(marker)->scale = {1.0f, 1.0f, 1.0f};
        auto& mm = w.add<MeshRenderer>(marker);
        mm.mesh = "cube";
        mm.color = Color{1, 0, 0, 1};
        mm.unlit = true;
    }
    PostProcess& post() { return camera_post(w, cam); }
    void taa(bool on = true) { post().temporalAAEnabled = on; }
    void move_x(float x) { w.get<Transform>(cam)->position.x = x; }
    void hide_marker() { w.set_active(marker, false); }
};

std::vector<float> linear_plane(const Image& img) {
    std::vector<float> v(std::size_t(img.width) * std::size_t(img.height));
    for (std::size_t i = 0; i < v.size(); ++i) v[i] = float(img.rgba[i * 4]) / 255.0f;
    return v;
}
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

// The supersampled picture of the scene (a renderer of 4 x the output size draws it) averaged down to the output size; without the marker.
std::vector<float> supersampled(Gfx& g, float cameraX = 0.0f) {
    Own big(g, kOutW * 4, kOutH * 4);
    REQUIRE_MESSAGE(big.ok, big.error);
    Scene s;
    s.hide_marker();
    s.move_x(cameraX);
    return reference_plane(big.draw(s.w), 4);
}

// The red marker is at the top left: red there, black in the three mirrored places (a copy that flips shows in one of them).
void check_marker(const Image& img) {
    REQUIRE(img.width == kOutW);
    REQUIRE(img.height == kOutH);
    const Color tl = img.pixel(66, 43);
    CHECK(tl.r > 0.8f);
    CHECK(tl.g < 0.2f);
    CHECK(tl.b < 0.2f);
    for (const auto& p : {std::pair<int, int>{kOutW - 1 - 66, 43}, std::pair<int, int>{66, kOutH - 1 - 43},
                          std::pair<int, int>{kOutW - 1 - 66, kOutH - 1 - 43}})
        CHECK(img.pixel(p.first, p.second).r < 0.1f);
}

int phys(int out, float scale) { return std::max(1, int(std::lround(double(out) * double(scale)))); }

}  // namespace

TEST_CASE(
    "temporal upscaler: the jitter phases follow the area ratio of the output to the render size, 8 at the same size") {
    CHECK(render::upscale_jitter_phases(320, 180, 320, 180) == 8);
    CHECK(render::upscale_jitter_phases(160, 90, 320, 180) == 32);      // 8 * 2^2
    CHECK(render::upscale_jitter_phases(1280, 720, 1920, 1080) == 18);  // 8 * 2.25
    CHECK(render::upscale_jitter_phases(1129, 635, 1920, 1080) ==
          24);  // 1 / 1.7: the sizes are rounded: 8 * 2.89 = 23.1 -> 24
    CHECK(render::upscale_jitter_phases(640, 360, 1920, 1080) == 72);           // 8 * 9
    CHECK(render::upscale_jitter_phases(80, 45, 320, 180) == 128);              // 8 * 16: the largest
    CHECK(render::upscale_jitter_phases(10, 6, 320, 180) == kJitterPhasesMax);  // clamped, never more than the table
    CHECK(render::upscale_jitter_phases(0, 0, 0, 0) >= 1);                      // no division by zero
    // The phases never go down when the render size goes down.
    int last = 0;
    for (const int w : {320, 240, 200, 160, 120, 100, 80}) {
        const int p = render::upscale_jitter_phases(w, w * 9 / 16, 320, 180);
        CHECK(p >= last);
        last = p;
    }
}

TEST_CASE("temporal upscaler: the effective mode is temporal where it can be drawn, spatial where it cannot, stretch "
          "for pixel art") {
    render::UpscalerCaps can;  // a GPU whose TAA shaders compiled, on a frame of one camera
    can.temporal = true;
    render::UpscalerCaps pixel = can;
    pixel.pixelArt = true;
    render::UpscalerCaps several = can;  // a split screen or two cameras: one history cannot serve them
    several.multiCamera = true;
    render::UpscalerCaps noTaa;  // the TAA shaders failed or its histories do not fit
    UpscalerSettings s;
    s.mode = UpscalerMode::Stretch;
    CHECK(render::effective_upscaler_mode(s, can) == UpscalerMode::Stretch);
    s.mode = UpscalerMode::Temporal;
    CHECK(render::effective_upscaler_mode(s, can) == UpscalerMode::Temporal);
    CHECK(render::effective_upscaler_mode(s) ==
          UpscalerMode::Spatial);  // a host with no renderer: what the caps default to
    CHECK(render::effective_upscaler_mode(s, noTaa) == UpscalerMode::Spatial);    // the fallback, never a bare stretch
    CHECK(render::effective_upscaler_mode(s, several) == UpscalerMode::Spatial);  // several cameras
    CHECK(render::effective_upscaler_mode(s, pixel) == UpscalerMode::Stretch);    // pixel art is never blended
    s.mode = UpscalerMode::Auto;
    CHECK(render::effective_upscaler_mode(s, can) == UpscalerMode::Temporal);
    CHECK(render::effective_upscaler_mode(s, several) == UpscalerMode::Spatial);
    CHECK(render::effective_upscaler_mode(s, pixel) == UpscalerMode::Stretch);
    CHECK(render::effective_upscaler_mode(s, noTaa) == UpscalerMode::Spatial);
    s.mode = UpscalerMode::MetalFx;
    CHECK(render::effective_upscaler_mode(s, can) ==
          UpscalerMode::Temporal);  // metalfx is not drawn yet: the next best
    CHECK(render::effective_upscaler_mode(s, several) == UpscalerMode::Spatial);
}

TEST_CASE("temporal upscaler: its plan uses the camera's TemporalAA fields, or the defaults, and its own history key") {
    CameraInfo cam;
    cam.view = Mat4::translate({0, 0, -10});
    cam.proj = Mat4::perspective(60.0f, 16.0f / 9.0f, 0.1f, 1000.0f, true);
    cam.viewProj = cam.proj * cam.view;
    cam.perspective = true;
    const Mat4 prev = cam.viewProj;
    PostStack none;  // no TemporalAA in the stack
    const render::TaaPlan a = render::make_upscale_taa_plan(cam, &none, true, true, 0.5f, 5, 11, 3, prev, true);
    CHECK(a.on);
    CHECK(a.camKey == render::kUpscaleCamKey);
    CHECK(a.serial == 5);
    CHECK(a.sceneKey == 11);
    CHECK(a.originShifts == 3);
    CHECK(a.prevValid);
    CHECK(a.feedback == doctest::Approx(0.9f));  // the defaults of the effect
    const render::TaaPlan b = render::make_upscale_taa_plan(cam, nullptr, true, true, 0.5f, 5, 11, 3, prev, true);
    CHECK(b.on);
    CHECK(b.sharpen == doctest::Approx(a.sharpen));
    // The fields of the stack's TemporalAA are used when it has one.
    PostStack with;
    with.fx.temporalAAEnabled = true;
    with.fx.temporalAAFeedback = 0.5f;
    with.mask = 1u << int(PostEffect::TemporalAA);
    CHECK(render::make_upscale_taa_plan(cam, &with, true, true, 0.5f, 5, 11, 3, prev, true).feedback ==
          doctest::Approx(0.5f));
    // The sharpness of the upscaler scales the sharpen: 0 is none, 1 is twice the effect's own (up to 1).
    CHECK(render::make_upscale_taa_plan(cam, &none, true, true, 0.0f, 5, 11, 3, prev, true).sharpen ==
          doctest::Approx(0.0f));
    CHECK(render::make_upscale_taa_plan(cam, &none, true, true, 1.0f, 5, 11, 3, prev, true).sharpen >= a.sharpen);
    // Not the game's frame, or the shaders failed: no plan.
    CHECK_FALSE(render::make_upscale_taa_plan(cam, &none, false, true, 0.5f, 5, 11, 3, prev, true).on);
    CHECK_FALSE(render::make_upscale_taa_plan(cam, &none, true, false, 0.5f, 5, 11, 3, prev, true).on);
}

TEST_CASE("temporal upscaler: render.supports says it is drawn, on every backend with a fragment pass") {
    const int i = render::find_feature("temporalUpscaler");
    REQUIRE(i >= 0);
    CHECK(render::feature_table()[std::size_t(i)].planned == nullptr);
}

TEST_CASE("temporal upscaler: the stage draws at the render size with the jitter, resolves to the output size, and the "
          "camera's own TAA pass is skipped") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    Own own(g);
    REQUIRE_MESSAGE(own.ok, own.error);
    Scene s;
    s.taa();  // the camera asks for its own temporal antialiasing too: the upscaler's resolve is the one that runs
    own.upscale(0.5f);
    bool jittered = false;
    for (int f = 0; f < 6; ++f) {
        own.frame(s.w);
        for (const Vec2& j : RendererTestAccess::last_jitter(own.r)) {
            jittered = jittered || j.x != 0.0f || j.y != 0.0f;
            CHECK(std::fabs(j.x) <= 0.5f);
            CHECK(std::fabs(j.y) <= 0.5f);
        }
    }
    CHECK(jittered);
    const Image img = own.capture();
    CHECK(img.width == kOutW);
    CHECK(img.height == kOutH);
    const std::vector<std::string> names = own.order();
    INFO(joined(names));
    CHECK(has_pass(names, "upscale"));
    CHECK_FALSE(has_pass(names, "taa-resolve"));  // the camera's own TAA passes are not declared
    CHECK_FALSE(has_pass(names, "taa-output"));
    CHECK(RendererTestAccess::upscale_impl(own.r) == int(UpscaleImpl::Temporal));
    CHECK(RendererTestAccess::upscale_phases(own.r) ==
          render::upscale_jitter_phases(phys(kOutW, 0.5f), phys(kOutH, 0.5f), kOutW, kOutH));
    CHECK(RendererTestAccess::upscale_phases(own.r) == 32);
    CHECK(RendererTestAccess::upscale_used_history(own.r));
    CHECK(RendererTestAccess::taa_images(own.r) == 2);  // one history (two images), the upscaler's: none for the camera
    CHECK(own.r.effective_upscaler_mode() == UpscalerMode::Temporal);
}

TEST_CASE("temporal upscaler: quality modes give their render sizes and phase counts, the picture is always the output "
          "size") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    for (const UpscalerQuality q : {UpscalerQuality::Quality, UpscalerQuality::Balanced, UpscalerQuality::Performance,
                                    UpscalerQuality::UltraPerformance}) {
        CAPTURE(int(q));
        Own own(g);
        REQUIRE_MESSAGE(own.ok, own.error);
        Scene s;
        const float scale = render::upscaler_quality_scale(q);
        own.upscale(scale, UpscalerMode::Temporal, q);
        const Image img = own.draw(s.w, 3);
        CHECK(img.width == kOutW);
        CHECK(img.height == kOutH);
        CHECK(RendererTestAccess::upscale_impl(own.r) == int(UpscaleImpl::Temporal));
        const int expected = render::upscale_jitter_phases(phys(kOutW, scale), phys(kOutH, scale), kOutW, kOutH);
        CHECK(RendererTestAccess::upscale_phases(own.r) == expected);
        CHECK(expected ==
              std::clamp(int(std::ceil(8.0 * double(kOutW) * kOutH / (double(phys(kOutW, scale)) * phys(kOutH, scale)) -
                                       1e-6)),
                         1, kJitterPhasesMax));
        check_marker(img);
    }
    // The phases of the four modes grow with the smaller render size.
    int last = 0;
    for (const UpscalerQuality q : {UpscalerQuality::Quality, UpscalerQuality::Balanced, UpscalerQuality::Performance,
                                    UpscalerQuality::UltraPerformance}) {
        const float scale = render::upscaler_quality_scale(q);
        const int p = render::upscale_jitter_phases(phys(kOutW, scale), phys(kOutH, scale), kOutW, kOutH);
        CHECK(p > last);
        last = p;
    }
}

TEST_CASE("temporal upscaler: a still scene at half size converges to the supersampled picture, far closer than "
          "stretch and than one frame") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    const std::vector<float> ref = supersampled(g);
    double stretchError = 0, oneFrameError = 0, temporalError = 0;
    int edges = 0;
    {
        Own own(g);
        REQUIRE_MESSAGE(own.ok, own.error);
        Scene s;
        s.hide_marker();
        own.upscale(0.5f, UpscalerMode::Stretch);
        const Image img = own.draw(s.w, 4);
        CHECK(RendererTestAccess::upscale_impl(own.r) == int(UpscaleImpl::Stretch));
        stretchError = edge_error(linear_plane(img), ref, &edges);
    }
    REQUIRE(edges > 100);
    {
        Own own(g);
        REQUIRE_MESSAGE(own.ok, own.error);
        Scene s;
        s.hide_marker();
        own.upscale(0.5f);
        oneFrameError = edge_error(linear_plane(own.draw(s.w, 1)), ref);
        CHECK_FALSE(RendererTestAccess::upscale_used_history(own.r));  // the first frame has no history
    }
    {
        Own own(g);
        REQUIRE_MESSAGE(own.ok, own.error);
        Scene s;
        s.hide_marker();
        own.upscale(0.5f);
        const Image img = own.draw(s.w, 80);  // two rounds of the 32 phases
        CHECK(RendererTestAccess::upscale_used_history(own.r));
        temporalError = edge_error(linear_plane(img), ref);
    }
    INFO("edge pixels " << edges << ", error of stretch " << stretchError << ", of one frame " << oneFrameError
                        << ", of 80 frames " << temporalError);
    CHECK(stretchError > 0.05);
    CHECK(
        temporalError <
        0.75 *
            stretchError);  // the sum of the phases is as sharp as a 2 px box filter allows: the sharpen does the rest
    CHECK(temporalError < 0.75 * oneFrameError);
}

TEST_CASE("temporal upscaler: the picture is the right way up, with the marker at the top left (stretch, one frame and "
          "converged)") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    Own own(g);
    REQUIRE_MESSAGE(own.ok, own.error);
    Scene s;
    own.upscale(0.5f, UpscalerMode::Stretch);
    check_marker(own.draw(s.w, 2));
    own.upscale(0.5f);
    check_marker(own.draw(s.w, 1));
    check_marker(own.draw(s.w, 40));
    CHECK(RendererTestAccess::upscale_impl(own.r) == int(UpscaleImpl::Temporal));
}

TEST_CASE("temporal upscaler: a panning camera leaves no ghost behind the edge") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    const float step = 0.06f;
    const int frames = 50;
    const std::vector<float> truth = supersampled(g, step * float(frames));
    Own own(g);
    REQUIRE_MESSAGE(own.ok, own.error);
    Scene s;
    s.hide_marker();
    own.upscale(0.5f);
    Image img;
    for (int f = 1; f <= frames; ++f) {
        s.move_x(step * float(f));
        img = own.draw(s.w);
    }
    CHECK(RendererTestAccess::upscale_used_history(own.r));
    const std::vector<float> got = linear_plane(img);
    const int ghosts = ghost_pixels(got, truth, img.width, img.height);
    const double err = edge_error(got, truth);
    double stretchErr = 0;
    {
        Own plain(g);
        REQUIRE_MESSAGE(plain.ok, plain.error);
        Scene p;
        p.hide_marker();
        plain.upscale(0.5f, UpscalerMode::Stretch);
        p.move_x(step * float(frames));
        stretchErr = edge_error(linear_plane(plain.draw(p.w, 3)), truth);
    }
    INFO("ghost pixels " << ghosts << ", edge error " << err << ", of stretch " << stretchErr);
    CHECK(ghosts < 40);  // a ghost of ten frames is a band of 15 px along four edges: hundreds
    CHECK(err < 1.2 * stretchErr);
}

TEST_CASE("temporal upscaler: a cut, a resize, a render scale change and a quality change start the history again; a "
          "still frame keeps it") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    Own own(g);
    REQUIRE_MESSAGE(own.ok, own.error);
    Scene s;
    own.upscale(0.5f);
    own.frame(s.w);
    CHECK_FALSE(RendererTestAccess::upscale_used_history(own.r));
    own.frame(s.w);
    CHECK(RendererTestAccess::upscale_used_history(own.r));
    const int started = RendererTestAccess::taa_resets(own.r);
    own.frame(s.w, 3);
    CHECK(RendererTestAccess::upscale_used_history(own.r));
    CHECK(RendererTestAccess::taa_resets(own.r) == started);

    // A cut: the world jumped forty ticks ahead.
    for (int i = 0; i < 40; ++i) s.w.advance_clock(1.0 / 60.0);
    own.frame(s.w);
    CHECK_FALSE(RendererTestAccess::upscale_used_history(own.r));
    CHECK(RendererTestAccess::taa_resets(own.r) == started + 1);
    own.frame(s.w);
    CHECK(RendererTestAccess::upscale_used_history(own.r));

    // A quality change at the same render size: the history is resolved with other phases.
    const int beforeQuality = RendererTestAccess::taa_resets(own.r);
    own.upscale(0.5f, UpscalerMode::Temporal, UpscalerQuality::Balanced);
    own.frame(s.w);
    CHECK_FALSE(RendererTestAccess::upscale_used_history(own.r));
    CHECK(RendererTestAccess::taa_resets(own.r) == beforeQuality + 1);
    own.frame(s.w);
    CHECK(RendererTestAccess::upscale_used_history(own.r));

    // A change of the render scale (another render size).
    const int beforeScale = RendererTestAccess::taa_resets(own.r);
    own.upscale(0.6f, UpscalerMode::Temporal, UpscalerQuality::Balanced);
    own.frame(s.w);
    CHECK_FALSE(RendererTestAccess::upscale_used_history(own.r));
    CHECK(RendererTestAccess::taa_resets(own.r) == beforeScale + 1);
    own.frame(s.w);
    CHECK(RendererTestAccess::upscale_used_history(own.r));

    // A resize of the output: the history has another size.
    const int beforeResize = RendererTestAccess::taa_resets(own.r);
    own.r.set_target_size(256, 144);
    own.frame(s.w);
    CHECK_FALSE(RendererTestAccess::upscale_used_history(own.r));
    CHECK(RendererTestAccess::taa_resets(own.r) == beforeResize + 1);
    own.frame(s.w);
    CHECK(RendererTestAccess::upscale_used_history(own.r));
}

TEST_CASE("temporal upscaler: the HUD is drawn at the output size, as sharp as at scale 1, and the history of the "
          "world is not touched by it") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    auto hud_scene = [](World& w) {
        w.add<Camera>(make(w, "cam")).clearColor = Color::black();
        Entity e = make(w, "hud", {10, 10, 0});
        auto& t = w.add<Text>(e);
        t.text = "HHHH";
        t.fontSize = 20;
        t.space = RenderSpace::Screen;
        t.pivot = {0, 1};
    };
    Own own(g);
    REQUIRE_MESSAGE(own.ok, own.error);
    World w;
    hud_scene(w);
    const Image full = own.draw(w);
    own.upscale(0.5f);
    const Image out = own.draw(w, 12);
    CHECK(RendererTestAccess::upscale_impl(own.r) == int(UpscaleImpl::Temporal));
    CHECK(has_pass(own.order(), "hud-over-upscale"));
    REQUIRE(out.width == kOutW);
    int worst = 0;
    for (int y = 0; y < 65; ++y)
        for (int x = 0; x < 140; ++x)
            worst = std::max(worst, int(std::abs(out.pixel(x, y).r - full.pixel(x, y).r) * 255.0f + 0.5f));
    CHECK(worst <= 2);  // the same glyph raster as at scale 1: never jittered, never resolved
}

TEST_CASE("temporal upscaler: pixel art (PixelPerfect) stays stretch and a frame with two cameras falls back to the "
          "spatial upscaler, with no jitter") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    {
        Own own(g);
        REQUIRE_MESSAGE(own.ok, own.error);
        Scene s;
        own.upscale(0.5f);
        own.r.set_scale_mode(ScaleMode::PixelPerfect);
        own.frame(s.w, 3);
        CHECK(own.r.effective_upscaler_mode() == UpscalerMode::Stretch);
        CHECK(RendererTestAccess::upscale_impl(own.r) == int(UpscaleImpl::Stretch));
        CHECK(RendererTestAccess::upscale_phases(own.r) == 0);
        for (const Vec2& j : RendererTestAccess::last_jitter(own.r)) {
            CHECK(j.x == 0.0f);
            CHECK(j.y == 0.0f);
        }
        CHECK(RendererTestAccess::taa_images(own.r) == 0);
        CHECK(has_pass(own.order(), "upscale"));
        own.r.set_scale_mode(ScaleMode::Fit);
        own.frame(s.w, 2);
        CHECK(own.r.effective_upscaler_mode() == UpscalerMode::Temporal);
        CHECK(RendererTestAccess::upscale_impl(own.r) == int(UpscaleImpl::Temporal));
    }
    {
        // Two cameras (a split screen): the jitter of one would show in the other's rectangle, so the frame is drawn with the spatial
        // upscaler (the same picture as the mode "spatial"), and the effective mode says so.
        Own own(g);
        REQUIRE_MESSAGE(own.ok, own.error);
        Scene s;
        s.w.get<Camera>(s.cam)->viewport = Rect{0, 0, 0.5f, 1};
        Entity second = make(s.w, "second", {0, 0, 10});
        auto& c = s.w.add<Camera>(second);
        c.projection = Projection::Perspective;
        c.viewport = Rect{0.5f, 0, 0.5f, 1};
        own.upscale(0.5f);
        const Image fallback = own.draw(s.w, 3);
        CHECK(RendererTestAccess::upscale_impl(own.r) == int(UpscaleImpl::Spatial));
        CHECK(own.r.effective_upscaler_mode() == UpscalerMode::Spatial);
        CHECK(RendererTestAccess::upscale_phases(own.r) == 0);
        CHECK(RendererTestAccess::taa_images(own.r) == 0);
        for (const Vec2& j : RendererTestAccess::last_jitter(own.r)) {
            CHECK(j.x == 0.0f);
            CHECK(j.y == 0.0f);
        }
        own.upscale(0.5f, UpscalerMode::Spatial);
        const Image spatial = own.draw(s.w, 3);
        CHECK(RendererTestAccess::upscale_impl(own.r) == int(UpscaleImpl::Spatial));
        REQUIRE(fallback.width == spatial.width);
        int worst = 0;
        for (int y = 0; y < fallback.height; ++y)
            for (int x = 0; x < fallback.width; ++x)
                worst = std::max(worst, int(std::abs(fallback.pixel(x, y).r - spatial.pixel(x, y).r) * 255.0f + 0.5f));
        CHECK(worst == 0);
    }
}

TEST_CASE("temporal upscaler: off (mode stretch) draws no jitter, no history and the same picture bit for bit, before "
          "and after a temporal frame") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    Own own(g);
    REQUIRE_MESSAGE(own.ok, own.error);
    Scene s;
    own.upscale(0.5f, UpscalerMode::Stretch);
    const Image before = own.draw(s.w, 4);
    CHECK(RendererTestAccess::upscale_impl(own.r) == int(UpscaleImpl::Stretch));
    CHECK(RendererTestAccess::upscale_phases(own.r) == 0);
    CHECK(RendererTestAccess::taa_images(own.r) == 0);
    for (const Vec2& j : RendererTestAccess::last_jitter(own.r)) {
        CHECK(j.x == 0.0f);
        CHECK(j.y == 0.0f);
    }
    own.upscale(0.5f);
    own.frame(s.w, 4);
    CHECK(RendererTestAccess::taa_images(own.r) == 2);
    own.upscale(0.5f, UpscalerMode::Stretch);
    const Image after = own.draw(s.w, 4);
    CHECK(RendererTestAccess::taa_images(own.r) == 0);  // the history is freed
    CHECK(same_pixels(before, after));
}

TEST_CASE("temporal upscaler: a NaN that reaches the resolve is dropped and never stays in the history") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    Own own(g);
    REQUIRE_MESSAGE(own.ok, own.error);
    Scene s;
    s.hide_marker();
    own.upscale(0.5f);
    const float nan = std::numeric_limits<float>::quiet_NaN();
    s.w.get<MeshRenderer>(s.box)->color = Color{nan, nan, nan, 1};
    own.frame(s.w, 6);  // the square is NaN for a few frames: the history of its pixels would be NaN
    s.w.get<MeshRenderer>(s.box)->color = Color::white();
    const Image img = own.draw(s.w, 40);
    // Inside the square (a disc of radius 18 px around the middle is all square: the square is 47 px wide) every pixel is white again, none black or stuck.
    int dark = 0;
    for (int y = 0; y < img.height; ++y)
        for (int x = 0; x < img.width; ++x) {
            const float dx = float(x) - 160.0f, dy = float(y) - 90.0f;
            if (dx * dx + dy * dy > 18.0f * 18.0f) continue;
            const Color c = img.pixel(x, y);
            if (!(c.r > 0.9f && c.g > 0.9f && c.b > 0.9f)) ++dark;
        }
    CHECK(dark == 0);
}

namespace {
struct Sky {
    World w;
    Entity cam, sun;
    Sky(float sunPitch, float sunYaw) {
        cam = make(w, "cam", {0, 0, 0});
        auto& c = w.add<Camera>(cam);
        c.projection = Projection::Perspective;
        c.fov = 120.0f;
        w.settings().ambientLight = Color{0, 0, 0, 1};
        w.settings().skyModel = SkyModel::Physical;
        sun = make(w, "sun", {0, 5, 0});
        auto& l = w.add<Light>(sun);
        l.type = LightType::Directional;
        l.intensity = 1.0f;
        l.castShadows = false;
        w.get<Transform>(sun)->rotation = {sunPitch, sunYaw, 0};
    }
};
}  // namespace

// The mean absolute difference of two pictures, in 0..255 steps.
double mean_diff(const Image& a, const Image& b) {
    REQUIRE(a.width == b.width);
    REQUIRE(a.height == b.height);
    double sum = 0;
    for (int y = 0; y < a.height; ++y)
        for (int x = 0; x < a.width; ++x)
            sum += std::fabs(a.pixel(x, y).r - b.pixel(x, y).r) + std::fabs(a.pixel(x, y).g - b.pixel(x, y).g);
    return sum / (2.0 * a.width * a.height) * 255.0;
}

// The sky is not rejected by its depth when the camera turns fast: a physical sky with a sun disc (a hard, bright edge: its history is what keeps
// the disc from flickering), the camera of the antialiasing alternating between two poses 40 degrees apart (the depth of the sky seen from the
// other pose is 0.77 of what it was: the depth rejection, which is for surfaces, took the history of the whole sky). The flicker is how much
// the picture of the same pose changes between two frames four frames apart (other jitter): it is the unavoidable jitter-and-reproject
// residue of the sun disc when the camera stands still, and about three times that with the history kept; seven times and more without it.
TEST_CASE("temporal resolve: the history of the sky survives a fast turn of the camera (no depth rejection of what is "
          "at infinity)") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    double flicker[2] = {0, 0};
    for (int alternate : {0, 1}) {
        Own own(g);
        REQUIRE_MESSAGE(own.ok, own.error);
        Sky s(-10.0f, 180.0f);
        camera_post(s.w, s.cam).temporalAAEnabled = true;
        Image first, second;
        for (int n = 0; n <= 80; ++n) {
            const bool b = alternate && (n % 2 == 1);
            s.w.get<Transform>(s.cam)->rotation = {b ? 50.0f : 10.0f, 0,
                                                   0};  // the sun is at the middle in pose A, 40 degrees below it in B
            own.frame(s.w);
            if (n == 76) first = own.capture();
            if (n == 80) second = own.capture();
        }
        REQUIRE(first.pixel(160, 90).r > 0.9f);  // the sun disc is where it should be in pose A
        flicker[alternate] = mean_diff(first, second);
    }
    INFO("flicker standing still " << flicker[0] << ", turning 40 degrees every frame " << flicker[1]);
    CHECK(flicker[0] > 0.0);
    CHECK(flicker[1] < 4.5 * flicker[0]);
}
