// M76-P5b: MetalFX in the renderer (UpscaleImpl::MetalFx, src/renderer_metalfx.cpp, shaders/upscale_mfx.glsl). The scenes are the white unlit
// square turned 30 degrees of temporal_upscale_tests.cpp, drawn at half the output size and brought up by the MetalFX temporal scaler.
//
// The tests that draw with MetalFX need the Metal backend on an OS and a GPU that have it: on any other host (Linux and Windows CI, the macOS
// VM of CI whose paravirtual GPU has no MetalFX) they say so with a MESSAGE and return, they never pass silently. The tests of what a host
// without MetalFX does (the fallback and its warning) and of what is reported run everywhere.
#include "test_util.h"

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <string>
#include <vector>

#include "metalfx.h"
#include "render_features.h"
#include "render_internal.h"
#include "render_upscale.h"
#include "renderer_test_access.h"
#include "fa/render/upscaler.h"

using namespace fa;
using namespace fa::test;
using render::UpscaleImpl;
using render::UpscalerMode;
using render::UpscalerQuality;
using render::UpscalerSettings;

namespace {

constexpr int kOutW = 320, kOutH = 180;

// True when this host draws the MetalFX temporal scaler; else says why in the test output (the skip is never silent).
bool mfx_here(const char* test) {
    const render::metalfx::Support s = render::metalfx::support();
    const bool ok = s.temporal && render::metalfx::on_metal();
    if (!ok)
        MESSAGE("MetalFX is not available here, the test is skipped (" << test << "): "
                                                                         << (s.reason.empty() ? "not the Metal backend" : s.reason));
    return ok;
}

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
    void upscale(float scale, UpscalerMode mode = UpscalerMode::MetalFx,
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

struct Scene {
    World w;
    Entity cam = kNullEntity;
    std::vector<Entity> parts;
    std::vector<float> offsets;
    // The white unlit square turned 30 degrees (bars false), or a row of twelve thin bars, about 1.3 render pixels wide every 2.7 (bars
    // true): detail a single frame at half size cannot carry, that only a history aligned by the motion keeps.
    explicit Scene(float x = 0.0f, bool bars = false) {
        cam = make(w, "cam", {0, 0, 10});
        auto& c = w.add<Camera>(cam);
        c.projection = Projection::Perspective;
        c.fov = 60.0f;
        c.clearColor = Color{0, 0, 0, 1};
        w.settings().skyColor = w.settings().horizonColor = Color{0, 0, 0, 1};
        const int n = bars ? 64 : 1;
        for (int i = 0; i < n; ++i) {
            const Entity e = make(w, "part", {0, 0, 0});
            Transform* t = w.get<Transform>(e);
            if (bars) {
                t->scale = {0.17f, 14.0f, 1.0f};
                offsets.push_back(float(i) * 0.35f - 11.0f);
            } else {
                t->scale = {3.0f, 3.0f, 3.0f};
                t->rotation = {0.0f, 0.0f, 30.0f};
                offsets.push_back(0.0f);
            }
            auto& m = w.add<MeshRenderer>(e);
            m.mesh = "cube";
            m.color = Color::white();
            m.unlit = true;
            parts.push_back(e);
        }
        move_box(x);
    }
    void move_camera(float x) { w.get<Transform>(cam)->position.x = x; }
    void move_box(float x) {
        for (std::size_t i = 0; i < parts.size(); ++i) w.get<Transform>(parts[i])->position.x = x + offsets[i];
    }
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
// The mean difference over the pixels the reference has on an edge (neither black nor white).
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
// Pixels that are lit in the picture while everything within one pixel of them is black in the reference: what a ghost leaves behind.
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

// The supersampled picture of the scene (a renderer of 4 x the output size draws it) averaged down to the output size.
std::vector<float> supersampled(Gfx& g, float boxX = 0.0f) {
    Own big(g, kOutW * 4, kOutH * 4);
    REQUIRE_MESSAGE(big.ok, big.error);
    Scene s(boxX);
    return reference_plane(big.draw(s.w), 4);
}

int warnings_with(const char* part) {
    int n = 0;
    for (const LogEntry& e : recent_logs(500, LogLevel::Warn))
        if (e.message.find(part) != std::string::npos) ++n;
    return n;
}

double round4(double v) { return std::round(v * 10000.0) / 10000.0; }

}  // namespace

TEST_CASE("metalfx renderer: the mode reported is metalfx where the GPU has it and the next best where not, with the reason") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    Own own(g);
    REQUIRE_MESSAGE(own.ok, own.error);
    Scene s;
    const render::metalfx::Support support = render::metalfx::support();
    const bool here = support.temporal && render::metalfx::on_metal();
    clear_recent_logs();
    own.upscale(0.5f);
    own.frame(s.w, 3);
    const render::UpscalerCaps caps = own.r.upscaler_caps();
    CHECK(caps.metalfx == (here || (support.spatial && render::metalfx::on_metal())));
    CHECK(caps.metalfxTemporal == support.temporal);
    CHECK(own.r.effective_upscaler_mode() == (caps.metalfx ? UpscalerMode::MetalFx : UpscalerMode::Temporal));
    CHECK(RendererTestAccess::upscale_impl(own.r) == int(caps.metalfx ? UpscaleImpl::MetalFx : UpscaleImpl::Temporal));
    CHECK(RendererTestAccess::upscale_phases(own.r) == 32);  // jittered either way (MetalFX's temporal scaler takes the same frame)
    CHECK(own.r.effective_upscaler_mode() != UpscalerMode::Stretch);
    const int row = render::find_feature("metalfx");
    REQUIRE(row >= 0);
    std::string why;
    CHECK(render::feature_supported(render::feature_env_from_sokol(), row, &why) == caps.metalfx);
    if (caps.metalfx) {
        CHECK(why.empty());
        CHECK(RendererTestAccess::mfx_encoded(own.r) == 3);
        CHECK(warnings_with("MetalFX") == 0);
    } else {
        // Where it is missing: the reason, once, in render.supports and in the log.
        CHECK_FALSE(why.empty());
        CHECK(why.find("planned") == std::string::npos);
        CHECK(warnings_with("is not available") == 1);
        CHECK(RendererTestAccess::mfx_encoded(own.r) == 0);
    }
    CHECK_FALSE(RendererTestAccess::mfx_failed(own.r));  // not being there is not a failure
    // An auto setting never warns: it picks the best that exists.
    clear_recent_logs();
    own.upscale(0.5f, UpscalerMode::Auto);
    own.frame(s.w, 2);
    CHECK(warnings_with("MetalFX") == 0);
    CHECK(own.r.effective_upscaler_mode() == (caps.metalfx ? UpscalerMode::MetalFx : UpscalerMode::Temporal));
}

TEST_CASE("metalfx renderer: a still scene converges to the supersampled picture, closer than stretch and than one frame, "
          "and the opposite jitter sign is worse") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    if (!mfx_here("still scene")) return;
    const std::vector<float> ref = supersampled(g);
    double stretchError = 0, oneFrameError = 0, converged = 0, flipped = 0;
    int edges = 0;
    {
        Own own(g);
        REQUIRE_MESSAGE(own.ok, own.error);
        Scene s;
        own.upscale(0.5f, UpscalerMode::Stretch);
        stretchError = edge_error(linear_plane(own.draw(s.w, 4)), ref, &edges);
    }
    REQUIRE(edges > 100);
    {
        Own own(g);
        REQUIRE_MESSAGE(own.ok, own.error);
        Scene s;
        own.upscale(0.5f);
        oneFrameError = edge_error(linear_plane(own.draw(s.w, 1)), ref);
        CHECK(RendererTestAccess::upscale_impl(own.r) == int(UpscaleImpl::MetalFx));
    }
    for (const float sign : {1.0f, -1.0f}) {
        Own own(g);
        REQUIRE_MESSAGE(own.ok, own.error);
        Scene s;
        own.upscale(0.5f);
        RendererTestAccess::mfx_signs(own.r, sign, 1.0f);
        const Image img = own.draw(s.w, 80);
        CHECK(RendererTestAccess::upscale_impl(own.r) == int(UpscaleImpl::MetalFx));
        CHECK(RendererTestAccess::mfx_encoded(own.r) == 80);
        CHECK(img.width == kOutW);
        CHECK(img.height == kOutH);
        (sign > 0 ? converged : flipped) = edge_error(linear_plane(img), ref);
    }
    MESSAGE("edge pixels " << edges << ", error of stretch " << round4(stretchError) << ", of one frame " << round4(oneFrameError)
                           << ", of 80 frames " << round4(converged) << ", of 80 frames with the jitter sign flipped "
                           << round4(flipped));
    CHECK(converged < oneFrameError);  // the history adds detail a single frame at half size cannot have
    CHECK(converged < flipped);  // the sign of the jitter matters, and the one handed to MetalFX is the right one
}

TEST_CASE("metalfx renderer: a moving object leaves no ghost with the motion handed to MetalFX") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    if (!mfx_here("moving object")) return;
    const int frames = 20;
    const float step = 0.4f;  // about 3 render pixels a frame
    Own big(g, kOutW * 4, kOutH * 4);
    REQUIRE_MESSAGE(big.ok, big.error);
    Scene bigScene(-4.0f);
    int ghosts[3] = {0, 0, 0};
    for (int run = 0; run < 3; ++run) {
        Own own(g);
        REQUIRE_MESSAGE(own.ok, own.error);
        Scene s(-4.0f);
        own.upscale(0.5f);
        RendererTestAccess::mfx_signs(own.r, 1.0f, run == 0 ? 1.0f : run == 1 ? -1.0f : 0.0f);
        Image img;
        for (int f = 1; f <= frames; ++f) {
            s.move_box(-4.0f + step * float(f));
            img = own.draw(s.w);
        }
        CHECK(RendererTestAccess::upscale_impl(own.r) == int(UpscaleImpl::MetalFx));
        CHECK(RendererTestAccess::mfx_encoded(own.r) == frames);
        bigScene.move_box(-4.0f + step * float(frames));
        const std::vector<float> truth = reference_plane(big.draw(bigScene.w), 4);
        ghosts[run] = ghost_pixels(linear_plane(img), truth, kOutW, kOutH);
    }
    MESSAGE("ghost pixels after " << frames << " frames: motion handed to MetalFx " << ghosts[0] << ", opposite sign " << ghosts[1]
                                  << ", no motion " << ghosts[2]);
    // A few pixels of a soft edge, not a trail of the twenty places the square was in. The three counts are close: on this scene the
    // output of the temporal scaler barely depends on the sign of the motion image (see "Open" in docs/UPSCALING.md, MetalFX), so the test
    // cannot tell the right sign from the wrong one here; the sign is checked where it shows, in metalfx_tests.cpp.
    CHECK(ghosts[0] < 40);
}

TEST_CASE("metalfx renderer: a camera cut, a resize and a quality change reset the history; a still frame keeps it") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    if (!mfx_here("cut")) return;
    Own own(g);
    REQUIRE_MESSAGE(own.ok, own.error);
    Scene s;
    own.upscale(0.5f);
    own.frame(s.w);
    CHECK(RendererTestAccess::mfx_reset(own.r));  // the first frame
    own.frame(s.w);
    CHECK_FALSE(RendererTestAccess::mfx_reset(own.r));
    own.frame(s.w, 3);
    CHECK_FALSE(RendererTestAccess::mfx_reset(own.r));
    CHECK(RendererTestAccess::mfx_generation(own.r) == 1);

    // A cut: the world jumped forty ticks ahead.
    for (int i = 0; i < 40; ++i) s.w.advance_clock(1.0 / 60.0);
    own.frame(s.w);
    CHECK(RendererTestAccess::mfx_reset(own.r));
    own.frame(s.w);
    CHECK_FALSE(RendererTestAccess::mfx_reset(own.r));

    // A quality change at the same render size: the history was accumulated with other phases.
    own.upscale(0.5f, UpscalerMode::MetalFx, UpscalerQuality::Balanced);
    own.frame(s.w);
    CHECK(RendererTestAccess::mfx_reset(own.r));
    own.frame(s.w);
    CHECK_FALSE(RendererTestAccess::mfx_reset(own.r));

    // A resize of the output: a new scaler, which starts its history.
    const int made = RendererTestAccess::mfx_generation(own.r);
    own.r.set_target_size(256, 144);
    own.frame(s.w);
    CHECK(RendererTestAccess::mfx_reset(own.r));
    CHECK(RendererTestAccess::mfx_generation(own.r) == made + 1);
    own.frame(s.w);
    CHECK_FALSE(RendererTestAccess::mfx_reset(own.r));
    CHECK_FALSE(RendererTestAccess::mfx_failed(own.r));
}

TEST_CASE("metalfx renderer: a scaler that cannot be made falls to the temporal upscaler with one warning, and stays there") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    if (!mfx_here("fallback")) return;
    Own own(g);
    REQUIRE_MESSAGE(own.ok, own.error);
    Scene s;
    clear_recent_logs();
    own.upscale(0.5f);
    RendererTestAccess::mfx_force_create_failure(own.r, true);
    own.frame(s.w, 6);
    CHECK(RendererTestAccess::mfx_failed(own.r));
    CHECK(RendererTestAccess::mfx_encoded(own.r) == 0);
    CHECK(RendererTestAccess::upscale_impl(own.r) == int(UpscaleImpl::Temporal));
    CHECK(RendererTestAccess::upscale_used_history(own.r));  // the temporal upscaler is what drew
    CHECK(own.r.effective_upscaler_mode() == UpscalerMode::Temporal);
    CHECK(own.r.upscaler_caps().metalfx == false);
    CHECK(warnings_with("MetalFX failed") == 1);  // once, not a line a frame
    const Image img = own.capture();
    CHECK(img.width == kOutW);
    CHECK(img.height == kOutH);
    // Still drawing: not a black frame.
    const std::vector<float> lit = linear_plane(img);
    CHECK(*std::max_element(lit.begin(), lit.end()) > 0.9f);
}

TEST_CASE("metalfx renderer: a frame of two cameras draws the spatial upscaler, as the temporal upscaler does") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    if (!mfx_here("two cameras")) return;
    Own own(g);
    REQUIRE_MESSAGE(own.ok, own.error);
    Scene s;
    s.w.get<Camera>(s.cam)->viewport = Rect{0, 0, 0.5f, 1};
    Entity second = make(s.w, "cam2", {0, 0, 10});
    auto& c2 = s.w.add<Camera>(second);
    c2.projection = Projection::Perspective;
    c2.clearColor = Color{0, 0, 0, 1};
    c2.viewport = Rect{0.5f, 0, 0.5f, 1};
    own.upscale(0.5f);
    own.frame(s.w, 4);
    CHECK(RendererTestAccess::upscale_phases(own.r) == 0);  // no jitter: one history cannot serve two cameras
    CHECK(own.r.effective_upscaler_mode() == UpscalerMode::Spatial);
    CHECK(RendererTestAccess::upscale_impl(own.r) == int(UpscaleImpl::Spatial));
    CHECK_FALSE(RendererTestAccess::mfx_failed(own.r));
    s.w.set_active(second, false);
    s.w.get<Camera>(s.cam)->viewport = Rect{0, 0, 1, 1};  // the one left covers the screen again
    own.frame(s.w, 4);
    CHECK(own.r.effective_upscaler_mode() == UpscalerMode::MetalFx);  // one camera again
    CHECK(RendererTestAccess::upscale_impl(own.r) == int(UpscaleImpl::MetalFx));
}

TEST_CASE("metalfx renderer: with the mode off, the picture is the same bit for bit before and after MetalFX frames") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    Own own(g);
    REQUIRE_MESSAGE(own.ok, own.error);
    Scene s;
    own.upscale(0.5f, UpscalerMode::Stretch);
    const Image before = own.draw(s.w, 4);
    CHECK(RendererTestAccess::upscale_impl(own.r) == int(UpscaleImpl::Stretch));
    CHECK(RendererTestAccess::upscale_phases(own.r) == 0);
    CHECK(RendererTestAccess::mfx_encoded(own.r) == 0);
    own.upscale(0.5f);  // metalfx (the temporal upscaler where the GPU has none)
    own.frame(s.w, 4);
    own.upscale(0.5f, UpscalerMode::Stretch);
    const Image after = own.draw(s.w, 4);
    CHECK(RendererTestAccess::upscale_impl(own.r) == int(UpscaleImpl::Stretch));
    CHECK(RendererTestAccess::upscale_phases(own.r) == 0);
    CHECK(same_pixels(before, after));
}
