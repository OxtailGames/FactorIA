// M76-P5b/P5c: MetalFX in the renderer (UpscaleImpl::MetalFx, src/renderer_metalfx.cpp, shaders/upscale_mfx.glsl). The scenes are the white unlit
// square turned 30 degrees of temporal_upscale_tests.cpp, drawn at half the output size and brought up by the MetalFX temporal scaler, and a
// textured stripe surface under a camera that pans and pitches.
//
// What runs where. The tests that draw with MetalFX need the Metal backend on an OS and a GPU that have it: on any other host (Linux and Windows
// CI, the macOS VM of CI whose paravirtual GPU has no MetalFX) they say so with a MESSAGE and return, they never pass silently. The tests
// that make the renderer believe MetalFX is there (RendererTestAccess::mfx_force_support) need the Metal backend only, with or without MetalFX:
// they run the preparation shader, the fallback after a failure and the clean-up of its images on every Metal GPU, the CI macOS VM included.
// On a backend that is not Metal they say so with a MESSAGE too; there the fallback is covered by "the mode reported ..." below.
#include "test_util.h"

#include <algorithm>
#include <atomic>
#include <chrono>
#include <cmath>
#include <cstdint>
#include <filesystem>
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
        MESSAGE("MetalFX is not available here, the test is skipped ("
                << test << "): " << (s.reason.empty() ? "not the Metal backend" : s.reason));
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

// True when the renderer can be made to believe MetalFX is there (any Metal GPU); else says why in the test output.
bool metal_here(const char* test) {
    const bool ok = sg_isvalid() && render::metalfx::on_metal();
    if (!ok) MESSAGE("This is not the Metal backend, the test is skipped (" << test << ")");
    return ok;
}

int warnings_with(const char* part) {
    int n = 0;
    for (const LogEntry& e : recent_logs(500, LogLevel::Warn))
        if (e.message.find(part) != std::string::npos) ++n;
    return n;
}

double round4(double v) { return std::round(v * 10000.0) / 10000.0; }

}  // namespace

TEST_CASE("metalfx renderer: the mode reported is metalfx where the GPU has it and the next best where not, with the "
          "reason") {
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
    CHECK(RendererTestAccess::upscale_phases(own.r) ==
          32);  // jittered either way (MetalFX's temporal scaler takes the same frame)
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

TEST_CASE(
    "metalfx renderer: a still scene converges to the supersampled picture, closer than stretch and than one frame, "
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
    MESSAGE("edge pixels " << edges << ", error of stretch " << round4(stretchError) << ", of one frame "
                           << round4(oneFrameError) << ", of 80 frames " << round4(converged)
                           << ", of 80 frames with the jitter sign flipped " << round4(flipped));
    CHECK(converged < oneFrameError);  // the history adds detail a single frame at half size cannot have
    CHECK(converged < flipped);        // the sign of the jitter matters, and the one handed to MetalFX is the right one
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
    MESSAGE("ghost pixels after " << frames << " frames: motion handed to MetalFx " << ghosts[0] << ", opposite sign "
                                  << ghosts[1] << ", no motion " << ghosts[2]);
    // A few pixels of a soft edge, not a trail of the twenty places the square was in. A square leaves few ghost pixels with either sign
    // (its edge is one soft step), so this test cannot tell the right sign from the wrong one; the stripe texture below and metalfx_tests.cpp do.
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

TEST_CASE(
    "metalfx renderer: a scaler that cannot be made falls to the temporal upscaler with one warning, and stays there") {
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

namespace {

// A textured surface of high-frequency vertical stripes (a png in a temporary directory of its own, two white texels and two black ones, tiled 42 times over the
// quad: a period of about 2.6 render pixels at half size) that moves to the right, under a camera that pans to the right and pitches: detail a
// single frame at half size cannot carry, that only a history aligned by the motion keeps. state(f) is the world of frame f.
struct StripeScene {
    World w;
    Entity cam = kNullEntity, quad = kNullEntity;
    std::filesystem::path dir;  // the texture's: not the working directory, which the tests share
    static constexpr float kTiles = 42.0f;
    StripeScene(const StripeScene&) = delete;
    StripeScene& operator=(const StripeScene&) = delete;
    ~StripeScene() {
        std::error_code ec;
        std::filesystem::remove_all(dir, ec);
    }
    explicit StripeScene(float f = 0.0f) {
        static std::atomic<int> counter{0};
        dir = std::filesystem::temp_directory_path() /
              ("fa_mfx_stripes_" + std::to_string(counter++) + "_" +
               std::to_string(std::uintmax_t(reinterpret_cast<std::uintptr_t>(this) & 0xffffff)));
        std::error_code ec;
        std::filesystem::remove_all(dir, ec);
        std::filesystem::create_directories(dir, ec);
        const std::filesystem::path file = dir / "mfx_stripes.png";
        Image tex;
        tex.width = 4;
        tex.height = 1;
        tex.rgba.assign(16, 255);
        for (std::size_t i = 2; i < 4; ++i)
            for (std::size_t c = 0; c < 3; ++c) tex.rgba[i * 4 + c] = 0;
        const Result<void> saved = save_png(tex, file.string());
        REQUIRE_MESSAGE(saved.ok(), "the stripe texture could not be written");
        cam = make(w, "cam", {0, 0, 10});
        auto& c = w.add<Camera>(cam);
        c.projection = Projection::Perspective;
        c.fov = 60.0f;
        c.clearColor = Color{0, 0, 0, 1};
        w.settings().skyColor = w.settings().horizonColor = Color{0, 0, 0, 1};
        quad = make(w, "stripes", {0, 0, 0});
        w.get<Transform>(quad)->scale = {14.0f, 8.0f, 1.0f};
        auto& m = w.add<MeshRenderer>(quad);
        m.mesh = "quad";
        m.texture = file.string();
        m.color = Color::white();
        m.unlit = true;
        m.uvScale = {kTiles, 1.0f};
        state(f);
    }
    void state(float f) {
        w.get<Transform>(quad)->position.x = -3.0f + 0.15f * f;
        Transform* t = w.get<Transform>(cam);
        t->position.x = 0.1f * f;                               // a pan: 0.8 render pixels a frame
        t->rotation = {1.5f * std::sin(0.2f * f), 0.0f, 0.0f};  // a pitch: up to 0.45 render pixels a frame
    }
};

// The mean absolute difference of two grey planes of kOutW x kOutH over the pixels at least `border` away from the edges.
double plane_error(const std::vector<float>& a, const std::vector<float>& b, int border = 8) {
    REQUIRE(a.size() == b.size());
    double sum = 0;
    int n = 0;
    for (int y = border; y < kOutH - border; ++y)
        for (int x = border; x < kOutW - border; ++x) {
            sum += std::fabs(double(a[std::size_t(y) * kOutW + std::size_t(x)]) -
                             double(b[std::size_t(y) * kOutW + std::size_t(x)]));
            ++n;
        }
    return n > 0 ? sum / n : 0.0;
}

}  // namespace

TEST_CASE("metalfx renderer: a stripe texture that moves under a panning, pitching camera follows the motion handed to "
          "MetalFX, "
          "against the opposite sign and none") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    if (!mfx_here("stripes")) return;
    const int frames = 30;
    std::vector<float> truth;
    {
        Own big(g, kOutW * 4, kOutH * 4);
        REQUIRE_MESSAGE(big.ok, big.error);
        StripeScene s{static_cast<float>(frames)};
        truth = reference_plane(big.draw(s.w), 4);
    }
    double err[3] = {1, 1, 1};
    double oneFrame = 1;
    for (int run = 0; run < 3; ++run) {
        Own own(g);
        REQUIRE_MESSAGE(own.ok, own.error);
        StripeScene s;
        own.upscale(0.5f);
        RendererTestAccess::mfx_signs(own.r, 1.0f, run == 0 ? 1.0f : run == 1 ? -1.0f : 0.0f);
        Image img;
        for (int f = 1; f <= frames; ++f) {
            s.state(float(f));
            own.frame(s.w);
            if (f == 1) {
                CHECK(RendererTestAccess::mfx_reset(own.r));  // the first frame starts the history
            } else {
                CHECK_FALSE(RendererTestAccess::mfx_reset(own.r));  // a camera that pans and pitches keeps it
            }
        }
        img = own.capture();
        CHECK(RendererTestAccess::upscale_impl(own.r) == int(UpscaleImpl::MetalFx));
        CHECK(RendererTestAccess::mfx_encoded(own.r) == frames);
        CHECK_FALSE(RendererTestAccess::mfx_failed(own.r));
        err[run] = plane_error(linear_plane(img), truth);
        if (run == 0) {
            Own one(g);
            REQUIRE_MESSAGE(one.ok, one.error);
            StripeScene s1{static_cast<float>(frames)};
            one.upscale(0.5f, UpscalerMode::Stretch);
            const Image oi = one.draw(s1.w, 1);
            oneFrame = plane_error(linear_plane(oi), truth);
        }
    }
    MESSAGE("mean error against the supersampled picture after "
            << frames << " frames: motion as handed to MetalFX " << round4(err[0]) << ", opposite sign "
            << round4(err[1]) << ", no motion " << round4(err[2]) << " (stretch of one frame " << round4(oneFrame)
            << ")");
    CHECK(err[0] < 0.8 * err[1]);
    CHECK(err[0] < 0.8 * err[2]);
    CHECK(err[0] < oneFrame);  // and it beats one frame stretched
}

TEST_CASE("metalfx renderer: the preparation pass writes the 0..1 depth and the UV motion of a camera that pans (any "
          "Metal GPU)") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    if (!metal_here("preparation values")) return;
    Own own(g);
    REQUIRE_MESSAGE(own.ok, own.error);
    Scene s;
    RendererTestAccess::mfx_force_support(own.r, true, true);
    RendererTestAccess::mfx_prep_only(own.r, true);
    own.upscale(0.5f);
    // The camera moves right and up by (0.1, 0.05) a frame, towards a surface 8.5 away (the front face of the cube, 1.5 in front of the middle).
    const float cx = 0.1f, cy = 0.05f;
    for (int f = 1; f <= 4; ++f) {
        Transform* t = s.w.get<Transform>(s.cam);
        t->position.x = cx * float(f);
        t->position.y = cy * float(f);
        own.frame(s.w);
    }
    CHECK_FALSE(RendererTestAccess::mfx_failed(own.r));
    CHECK(RendererTestAccess::upscale_impl(own.r) ==
          int(UpscaleImpl::Temporal));  // the frame went on to the temporal upscaler
    CHECK(RendererTestAccess::mfx_images(own.r) == 2);
    float v[3] = {0, 0, 0};
    std::string error;
    REQUIRE_MESSAGE(RendererTestAccess::mfx_read_prep(own.r, kOutW / 4, kOutH / 4, v, &error),
                    error);  // the middle of the 160 x 90 picture
    const float depth = 8.5f;
    const float halfH = depth * std::tan(30.0f * 3.14159265f / 180.0f), halfW = halfH * float(kOutW) / float(kOutH);
    // A surface that was where the camera was less far to the right is to the right of where it is now (x grows); up is y down in the image.
    const float wantX = 0.5f * cx / halfW, wantY = -0.5f * cy / halfH;
    MESSAGE("depth " << round4(v[0]) << " (expected " << round4(depth / (depth + 1.0f)) << "), motion " << round4(v[1])
                     << ", " << round4(v[2]) << " (expected " << round4(wantX) << ", " << round4(wantY) << ")");
    CHECK(v[0] == doctest::Approx(depth / (depth + 1.0f)).epsilon(0.01));
    CHECK(v[1] == doctest::Approx(wantX).epsilon(0.1));
    CHECK(v[2] == doctest::Approx(wantY).epsilon(0.1));
    // A corner of the picture, where nothing is drawn: the sky, 1 in the depth, and the motion of the camera at the far plane (about none).
    REQUIRE_MESSAGE(RendererTestAccess::mfx_read_prep(own.r, 2, 2, v, &error), error);
    CHECK(v[0] == doctest::Approx(1.0f).epsilon(0.001));
    CHECK(std::fabs(v[1]) < 0.01f);
    CHECK(std::fabs(v[2]) < 0.01f);
}

TEST_CASE("metalfx renderer: a MetalFX the GPU lacks, made to look present, falls to the temporal upscaler with one "
          "warning and clean "
          "images (any Metal GPU)") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    if (!metal_here("forced fallback")) return;
    Own own(g);
    REQUIRE_MESSAGE(own.ok, own.error);
    Scene s;
    clear_recent_logs();
    RendererTestAccess::mfx_force_support(own.r, true, true);
    RendererTestAccess::mfx_prep_only(own.r, true);
    own.upscale(0.5f);
    own.frame(s.w, 3);
    CHECK(own.r.upscaler_caps().metalfx);
    CHECK(own.r.effective_upscaler_mode() == UpscalerMode::MetalFx);
    CHECK(RendererTestAccess::mfx_images(own.r) ==
          2);  // the preparation images of the frames that went to the temporal upscaler
    CHECK_FALSE(RendererTestAccess::mfx_last_wrote(own.r));
    CHECK(RendererTestAccess::upscale_impl(own.r) == int(UpscaleImpl::Temporal));
    CHECK(warnings_with("MetalFX") == 0);

    // The scaler cannot be made: one warning, the temporal upscaler from then on, the caps say so and the images are gone.
    RendererTestAccess::mfx_prep_only(own.r, false);
    RendererTestAccess::mfx_force_create_failure(own.r, true);
    own.frame(s.w, 5);
    CHECK(RendererTestAccess::mfx_failed(own.r));
    CHECK(RendererTestAccess::mfx_encoded(own.r) == 0);
    CHECK_FALSE(RendererTestAccess::mfx_last_wrote(own.r));
    CHECK(RendererTestAccess::mfx_images(own.r) == 0);
    CHECK(own.r.upscaler_caps().metalfx == false);
    CHECK(own.r.effective_upscaler_mode() == UpscalerMode::Temporal);
    CHECK(RendererTestAccess::upscale_impl(own.r) == int(UpscaleImpl::Temporal));
    CHECK(RendererTestAccess::upscale_used_history(own.r));
    CHECK(warnings_with("MetalFX failed") == 1);  // once, not a line a frame
    const std::vector<float> lit = linear_plane(own.capture());
    CHECK(*std::max_element(lit.begin(), lit.end()) > 0.9f);  // still drawing
}

TEST_CASE("metalfx renderer: leaving the metalfx mode gives the preparation images back, and a spatial-only GPU never "
          "makes them (any Metal "
          "GPU)") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    if (!metal_here("leaving the mode")) return;
    Own own(g);
    REQUIRE_MESSAGE(own.ok, own.error);
    Scene s;
    RendererTestAccess::mfx_force_support(own.r, true, true);
    RendererTestAccess::mfx_prep_only(own.r, true);
    own.upscale(0.5f);
    own.frame(s.w, 3);
    CHECK(RendererTestAccess::mfx_images(own.r) == 2);
    own.upscale(0.5f, UpscalerMode::Temporal);
    own.frame(s.w, 2);
    CHECK(RendererTestAccess::mfx_images(own.r) == 0);
    CHECK_FALSE(
        RendererTestAccess::mfx_failed(own.r));  // leaving it is not a failure: coming back draws the images again
    own.upscale(0.5f);
    own.frame(s.w, 2);
    CHECK(RendererTestAccess::mfx_images(own.r) == 2);

    Own spatialOnly(g);
    REQUIRE_MESSAGE(spatialOnly.ok, spatialOnly.error);
    RendererTestAccess::mfx_force_support(spatialOnly.r, true, false);
    RendererTestAccess::mfx_prep_only(spatialOnly.r, true);
    spatialOnly.upscale(0.5f);
    spatialOnly.frame(s.w, 3);
    CHECK(spatialOnly.r.upscaler_caps().metalfx);
    CHECK_FALSE(spatialOnly.r.upscaler_caps().metalfxTemporal);
    CHECK(RendererTestAccess::mfx_images(spatialOnly.r) == 0);
    CHECK(RendererTestAccess::upscale_phases(spatialOnly.r) ==
          0);  // no jitter: the spatial scaler takes the frame as it is
}

TEST_CASE("metalfx renderer: frames queued without waiting for the GPU give the same picture every time") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    if (!mfx_here("determinism")) return;
    // MetalFX was once encoded behind the passes that wrote its inputs without waiting for them: the same frames, queued one after the other
    // (the picture is read at the end only), came out different from run to run. Frame 1 starts the history; frames 2 and later use it.
    for (int frames : {2, 6}) {
        std::uint64_t first = 0;
        for (int rep = 0; rep < 4; ++rep) {
            Own own(g);
            REQUIRE_MESSAGE(own.ok, own.error);
            StripeScene s;
            own.upscale(0.5f);
            for (int f = 1; f <= frames; ++f) {
                s.state(float(f));
                own.frame(s.w);
            }
            const Image img = own.capture();
            std::uint64_t h = 1469598103934665603ull;
            for (std::uint8_t b : img.rgba) h = (h ^ b) * 1099511628211ull;
            if (rep == 0) first = h;
            CHECK_MESSAGE(h == first, "frames " << frames << ", repetition " << rep << " differs from the first");
        }
    }
}

#if defined(SOKOL_METAL)
namespace {

// A bright additive square (a Sprite, 1.5 world units across, so reactive: an additive sprite counts as 1) in front of the stripes, at x.
Entity add_reactive_dot(World& w, float x) {
    Entity e = make(w, "dot", {x, 0, 1});
    auto& sp = w.add<Sprite>(e);
    sp.size = {1.5f, 1.5f};
    sp.color = Color{1, 1, 1, 1};
    sp.blend = BlendMode::Additive;
    sp.layer = 20;
    return e;
}

// How far the picture of the last frame is from the truth (the same world drawn at the full size with no upscaler) where the dot is.
// The dot moves 0.25 world units (about 4 output pixels) a frame over the moving stripes, with no motion vector of its own.
double dot_error(Gfx& g, bool handMask, bool* maskInput) {
    const int frames = 24;
    auto world_at = [&](StripeScene& s, Entity dot, int f) {
        s.state(float(f));
        s.w.get<Transform>(dot)->position.x = -6.0f + 0.25f * float(f);
    };
    Image truth, base;
    {
        Own o(g);
        REQUIRE_MESSAGE(o.ok, o.error);
        StripeScene s;
        const Entity dot = add_reactive_dot(s.w, 0.0f);
        world_at(s, dot, frames);
        truth = o.draw(s.w, 3);
        s.w.set_active(dot, false);
        base = o.draw(s.w, 3);
    }
    Own o(g);
    REQUIRE_MESSAGE(o.ok, o.error);
    StripeScene s;
    const Entity dot = add_reactive_dot(s.w, 0.0f);
    o.upscale(0.5f);
    RendererTestAccess::mfx_no_reactive(o.r, !handMask);
    for (int f = 1; f <= frames; ++f) {
        world_at(s, dot, f);
        o.frame(s.w);
    }
    CHECK_FALSE(RendererTestAccess::mfx_failed(o.r));
    CHECK(RendererTestAccess::mfx_encoded(o.r) == frames);
    CHECK(RendererTestAccess::mfx_reactive_frames(o.r) ==
          (handMask && RendererTestAccess::mfx_reactive_enabled(o.r) ? frames : 0));
    *maskInput = RendererTestAccess::mfx_reactive_enabled(o.r);
    const Image img = o.capture();
    double sum = 0;
    int n = 0;
    for (int y = 0; y < img.height; ++y)
        for (int x = 0; x < img.width; ++x)
            if (std::fabs(truth.pixel(x, y).r - base.pixel(x, y).r) > 0.15f) {  // where the dot is
                sum += std::fabs(double(img.pixel(x, y).r) - double(truth.pixel(x, y).r));
                ++n;
            }
    REQUIRE(n > 100);
    return sum / n;
}

}  // namespace

TEST_CASE(
    "metalfx renderer: a reactive additive sprite moving over moving stripes is drawn at once with the mask handed to "
    "MetalFX") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    if (!mfx_here("reactive dot")) return;
    bool maskInput = false;
    const double with = dot_error(g, true, &maskInput);
    const double without = dot_error(g, false, &maskInput);
    MESSAGE("mean error inside the dot's footprint: with the mask " << round4(with) << ", without " << round4(without));
    if (!maskInput) return;  // an OS older than macOS 14.4 / iOS 17.4 has no mask input
    CHECK(without > 0.04);   // without the mask MetalFX keeps stripes of the history inside the sprite
    CHECK(with < 0.5 * without);
}

TEST_CASE("metalfx renderer: the reactive mask is handed to the scaler in the frames that have one, and only in those "
          "(any Metal "
          "GPU)") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    if (!metal_here("reactive plumbing")) return;
    Own own(g);
    REQUIRE_MESSAGE(own.ok, own.error);
    StripeScene s;
    RendererTestAccess::mfx_force_support(own.r, true, true);
    RendererTestAccess::mfx_scaler_hooks(own.r, true,
                                         false);  // the scaler draws nothing: what is handed over is what is checked
    own.upscale(0.5f);
    own.frame(s.w, 3);
    REQUIRE(RendererTestAccess::mfx_encoded(own.r) == 3);
    CHECK(RendererTestAccess::mfx_reactive_frames(own.r) ==
          0);  // nothing asked for a mask: none exists, none is handed
    const Entity dot = add_reactive_dot(s.w, -2.0f);
    own.frame(s.w, 3);
    CHECK_FALSE(RendererTestAccess::mfx_failed(own.r));
    CHECK(RendererTestAccess::mfx_encoded(own.r) == 6);
    if (!RendererTestAccess::mfx_reactive_enabled(own.r)) {
        MESSAGE("this OS has no MetalFX reactive mask (macOS 14.4 or iOS 17.4): the scaler is made without the input");
        CHECK(RendererTestAccess::mfx_reactive_frames(own.r) == 0);
        return;
    }
    CHECK(RendererTestAccess::mfx_reactive_frames(own.r) == 3);
    RendererTestAccess::mfx_no_reactive(own.r, true);
    own.frame(s.w, 2);
    CHECK(RendererTestAccess::mfx_reactive_frames(own.r) == 3);
    RendererTestAccess::mfx_no_reactive(own.r, false);
    own.frame(s.w, 2);
    CHECK(RendererTestAccess::mfx_reactive_frames(own.r) == 5);
    s.w.set_active(dot, false);  // the sprite is gone: so is the mask
    own.frame(s.w, 2);
    CHECK(RendererTestAccess::mfx_reactive_frames(own.r) == 5);
    CHECK(RendererTestAccess::mfx_generation(own.r) == 1);  // the first mask did not make the scaler again
    CHECK_FALSE(RendererTestAccess::mfx_failed(own.r));
}

TEST_CASE("metalfx renderer: a MetalFX command buffer that fails releases the passes behind it, and the renderer falls "
          "back with "
          "one warning (any Metal GPU)") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    if (!metal_here("failing command buffer")) return;
    Own own(g);
    REQUIRE_MESSAGE(own.ok, own.error);
    StripeScene s;
    clear_recent_logs();
    RendererTestAccess::mfx_force_support(own.r, true, true);
    // The command buffer of the scaler ends as a failed one does: the handler reports the error and the buffer does not signal.
    RendererTestAccess::mfx_scaler_hooks(own.r, true, true);
    own.upscale(0.5f);
    own.frame(s.w);
    REQUIRE(RendererTestAccess::mfx_encoded(own.r) == 1);
    // The passes after the scaler wait for the event only the completion handler raises: a handler that did not would stall the queue
    // for ever, so this wait is limited and the test fails (and lets the queue go on) instead of hanging.
    REQUIRE_MESSAGE(RendererTestAccess::mfx_wait_signalled(own.r, 10000),
                    "the completion handler of the failed MetalFX buffer did not raise the event");
    // The error comes back from Metal's thread: some frame after it sees it, at its start. Bounded by the clock, never by a frame count.
    const auto start = std::chrono::steady_clock::now();
    while (!RendererTestAccess::mfx_failed(own.r) &&
           std::chrono::steady_clock::now() - start < std::chrono::seconds(30))
        own.frame(s.w);
    REQUIRE(RendererTestAccess::mfx_failed(own.r));
    own.frame(s.w, 3);
    CHECK(warnings_with("MetalFX failed") == 1);  // once, not a line a frame
    CHECK(warnings_with("command buffer finished with an error") == 1);
    CHECK(RendererTestAccess::mfx_images(own.r) == 0);
    CHECK(own.r.upscaler_caps().metalfx == false);
    CHECK(RendererTestAccess::upscale_impl(own.r) == int(UpscaleImpl::Temporal));
    const std::vector<float> lit = linear_plane(own.capture());  // the frames still draw, the queue is not stalled
    CHECK(*std::max_element(lit.begin(), lit.end()) > 0.5f);
}
#endif
