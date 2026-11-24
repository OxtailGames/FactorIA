// M76-P3b: the spatial upscaler (shaders/upscale_spatial.glsl, src/render_upscale_spatial.cpp, Renderer::Impl::spatial_upscale). Headless, on
// the test GPU, with a renderer of its own (like upscale_tests.cpp). Every claim is a ratio or a bound measured against the plain stretch of
// the same scene, with margins, never a golden image: the filters differ by a few levels between GPUs.
#include "test_util.h"

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <string>
#include <utility>
#include <vector>

#include "frame_graph.h"
#include "render_upscale.h"
#include "renderer_test_access.h"

using namespace fa;
using namespace fa::test;

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
    Image draw(World& w) {
        r.begin_frame();
        r.render_world(w, 1.0f / 60.0f);
        r.end_frame();
        g.gpu.end_frame();
        Image img;
        std::string err;
        const bool captured = r.capture(img, &err);
        INFO("capture error: " << err);
        REQUIRE(captured);
        return img;
    }
    int drawn_passes(const char* name) {
        const render::FrameGraph* graph = render::renderer_frame_graph(r);
        REQUIRE(graph != nullptr);
        int n = 0;
        const std::string tail = std::string("/") + name;
        for (const std::string& s : graph->order_names())
            if (s == name || (s.size() > tail.size() && s.compare(s.size() - tail.size(), tail.size(), tail) == 0)) ++n;
        return n;
    }
    // The stage at scale `scale` with `mode` and `sharpness`, as the runtime sets it.
    void setup(float scale, render::UpscalerMode mode, float sharpness = 0.5f,
               render::UpscalerQuality q = render::UpscalerQuality::Native) {
        render::UpscalerSettings s;
        s.mode = mode;
        s.sharpness = sharpness;
        s.quality = q;
        r.set_upscaler(s);
        r.set_render_scale(scale);
        r.set_upscale_stage(true);
    }
};

constexpr float kBg = 0.15f, kFg = 0.85f;

// A gray picture with a rotated rectangle (a hard diagonal edge) in the left half and thin vertical bars (text-like strokes) in the right.
struct Pattern {
    World w;
    Pattern() {
        Entity cam = make(w, "cam");
        w.add<Camera>(cam).clearColor = Color(kBg, kBg, kBg, 1);
        Entity box = make(w, "box", {-80, 0, 0});
        w.get<Transform>(box)->rotation = {0, 0, 27};
        auto& s = w.add<Shape2D>(box);
        s.size = {110, 90};
        s.color = Color(kFg, kFg, kFg, 1);
        for (int i = 0; i < 5; ++i) {
            Entity bar = make(w, "bar", {40.0f + 14.0f * float(i), 0, 0});
            auto& b = w.add<Shape2D>(bar);
            b.size = {3, 70};
            b.color = Color(kFg, kFg, kFg, 1);
        }
    }
};

// How wide an edge is: the pixels in the 10..90 % band of the picture's own range per crossing of the middle (horizontal runs).
struct EdgeStat {
    double width = 0.0;  // pixels in the band per crossing
    int crossings = 0;
    float overshoot = 0.0f;  // how far any pixel goes past [kBg, kFg], in 0..1
};
EdgeStat edge_stat(const Image& img, int x0, int x1, float lo = kBg, float hi = kFg) {
    EdgeStat s;
    const float lo10 = lo + 0.1f * (hi - lo), hi90 = lo + 0.9f * (hi - lo), mid = 0.5f * (lo + hi);
    long band = 0;
    for (int y = 0; y < img.height; ++y)
        for (int x = x0; x < x1; ++x) {
            const float v = img.pixel(x, y).r;
            if (v > lo10 && v < hi90) ++band;
            if (x + 1 < x1) {
                const float n = img.pixel(x + 1, y).r;
                if ((v < mid) != (n < mid)) ++s.crossings;
            }
            s.overshoot = std::max({s.overshoot, v - hi, lo - v});
        }
    s.width = s.crossings > 0 ? double(band) / double(s.crossings) : 0.0;
    return s;
}

// The darkest and the lightest value of a picture (what the pattern's two colours come out as after the colour space of the test GPU).
std::pair<float, float> range_of(const Image& img) {
    float lo = 1e9f, hi = -1e9f;
    for (int y = 0; y < img.height; ++y)
        for (int x = 0; x < img.width; ++x) {
            lo = std::min(lo, img.pixel(x, y).r);
            hi = std::max(hi, img.pixel(x, y).r);
        }
    return {lo, hi};
}

double mean_abs_err(const Image& a, const Image& b) {
    REQUIRE(a.width == b.width);
    REQUIRE(a.height == b.height);
    double sum = 0.0;
    for (int y = 0; y < a.height; ++y)
        for (int x = 0; x < a.width; ++x) sum += std::abs(a.pixel(x, y).r - b.pixel(x, y).r);
    return sum / double(a.width * a.height);
}

// The sum of the squared horizontal differences: the steeper the edges, the bigger.
double gradient_energy(const Image& img) {
    double e = 0.0;
    for (int y = 0; y < img.height; ++y)
        for (int x = 0; x + 1 < img.width; ++x) {
            const double d = img.pixel(x + 1, y).r - img.pixel(x, y).r;
            e += d * d;
        }
    return e;
}

int max_diff(const Image& a, const Image& b) {
    REQUIRE(a.width == b.width);
    REQUIRE(a.height == b.height);
    int worst = 0;
    for (int y = 0; y < a.height; ++y)
        for (int x = 0; x < a.width; ++x) {
            const Color p = a.pixel(x, y), q = b.pixel(x, y);
            for (const float d : {p.r - q.r, p.g - q.g, p.b - q.b, p.a - q.a})
                worst = std::max(worst, int(std::abs(d) * 255.0f + 0.5f));
        }
    return worst;
}

}  // namespace

// A gray picture with a rotated rectangle whose edge is blurred (Shape2D.softness): something a sharpen has to work on.
struct SoftPattern {
    World w;
    SoftPattern() {
        Entity cam = make(w, "cam");
        w.add<Camera>(cam).clearColor = Color(kBg, kBg, kBg, 1);
        Entity box = make(w, "box", {0, 0, 0});
        w.get<Transform>(box)->rotation = {0, 0, 20};
        auto& s = w.add<Shape2D>(box);
        s.size = {160, 90};
        s.softness = 10.0f;
        s.color = Color(kFg, kFg, kFg, 1);
    }
};

TEST_CASE("spatial upscaler: at 0.5 a diagonal edge and thin strokes are sharper than the bilinear stretch, with no "
          "ringing") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    Own own(g);
    REQUIRE_MESSAGE(own.ok, own.error);
    Pattern p;
    const Image truth = own.draw(p.w);  // scale 1: what both try to reach
    REQUIRE(truth.width == 320);
    const auto [lo, hi] = range_of(truth);
    REQUIRE(hi - lo > 0.5f);

    own.setup(0.5f, render::UpscalerMode::Stretch);
    const Image bil = own.draw(p.w);
    CHECK(bil.width == 320);
    CHECK(own.drawn_passes("upscale") == 1);
    const int bilCalls = own.r.stats(false).drawCalls;
    own.setup(0.5f, render::UpscalerMode::Spatial, 0.5f);
    CHECK(own.r.effective_upscaler_mode() == render::UpscalerMode::Spatial);
    const Image sp = own.draw(p.w);
    CHECK(sp.width == 320);
    CHECK(sp.height == 180);
    CHECK(own.drawn_passes("upscale") == 1);
    CHECK(own.r.stats(false).drawCalls == bilCalls + 1);  // the edge pass and the sharpen instead of the one copy

    // The width of the edge, in pixels, per crossing of the middle value: the diagonal of the box (left) and the bars (right).
    const EdgeStat dBil = edge_stat(bil, 0, 150, lo, hi), dSp = edge_stat(sp, 0, 150, lo, hi);
    const EdgeStat sBil = edge_stat(bil, 150, 320, lo, hi), sSp = edge_stat(sp, 150, 320, lo, hi);
    REQUIRE(dBil.crossings > 100);
    REQUIRE(sBil.crossings > 300);
    CHECK(dBil.width > 2.0);  // the bilinear stretch is soft (about 3.5 pixels), the check is about the pattern too
    CHECK(dSp.width < 0.6 * dBil.width);
    CHECK(sSp.width < 0.6 * sBil.width);
    // Closer to the picture drawn at full size than the bilinear stretch is.
    CHECK(mean_abs_err(sp, truth) < 0.85 * mean_abs_err(bil, truth));
    // No ringing: nothing goes past the two values of the pattern (the filter is clamped to the range of the texels it reads).
    CHECK(dSp.overshoot < 0.01f);
    CHECK(sSp.overshoot < 0.01f);
    // The strokes keep their contrast: the bars' own columns are as light as the picture's lightest value, not the blurred peak.
    float peak = 0.0f;
    for (int x = 150; x < 320; ++x) peak = std::max(peak, sp.pixel(x, 90).r);
    CHECK(peak > hi - 0.03f);
}

TEST_CASE("spatial upscaler: sharpness 0 to 1 sharpens monotonically and never rings") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    Own own(g);
    REQUIRE_MESSAGE(own.ok, own.error);
    SoftPattern soft;
    Pattern hard;
    const auto [lo, hi] = range_of(own.draw(soft.w));
    double last = 0.0;
    std::vector<double> widths;
    for (const float sharpness : {0.0f, 0.25f, 0.5f, 0.75f, 1.0f}) {
        CAPTURE(sharpness);
        own.setup(0.5f, render::UpscalerMode::Spatial, sharpness);
        const Image img = own.draw(soft.w);
        const double energy = gradient_energy(img);
        CHECK(energy > last * 1.03);  // steeper at every step (about 10 % to 15 % in practice)
        last = energy;
        widths.push_back(edge_stat(img, 0, 320, lo, hi).width);
        const Image h = own.draw(hard.w);
        CHECK(edge_stat(h, 0, 320, lo, hi).overshoot < 0.01f);
        CHECK(edge_stat(img, 0, 320, lo, hi).overshoot < 0.01f);
    }
    for (std::size_t i = 1; i < widths.size(); ++i) CHECK(widths[i] <= widths[i - 1] + 0.05);
    CHECK(widths.back() < 0.9 * widths.front());  // the soft edge is narrower at 1 than at 0
}

TEST_CASE("spatial upscaler: at scale 1 it is the sharpen alone, and nothing at sharpness 0") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    Own own(g);
    REQUIRE_MESSAGE(own.ok, own.error);
    SoftPattern soft;
    const Image plain = own.draw(soft.w);
    own.setup(1.0f, render::UpscalerMode::Spatial, 0.0f);
    const Image off = own.draw(soft.w);
    CHECK(own.drawn_passes("upscale") == 0);
    CHECK(max_diff(off, plain) == 0);
    own.setup(1.0f, render::UpscalerMode::Spatial, 1.0f);
    const Image sharp = own.draw(soft.w);
    CHECK(own.drawn_passes("upscale") == 1);
    CHECK(sharp.width == 320);
    CHECK(sharp.height == 180);
    CHECK(gradient_energy(sharp) > 1.03 * gradient_energy(plain));
    CHECK(max_diff(sharp, plain) > 2);
    // Stretch at scale 1 stays off.
    own.setup(1.0f, render::UpscalerMode::Stretch, 1.0f);
    const Image stretch = own.draw(soft.w);
    CHECK(own.drawn_passes("upscale") == 0);
    CHECK(max_diff(stretch, plain) == 0);
}

TEST_CASE("spatial upscaler: the quality presets draw at the expected sizes, scaled by the player's scale and floored "
          "at 0.25") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    Own own(g);
    REQUIRE_MESSAGE(own.ok, own.error);
    Pattern p;
    struct Case {
        float windowScale;
        render::UpscalerQuality quality;
        int w, h;  // the size the game is drawn at (the image of a capture without the stage)
    };
    const Case cases[] = {
        {1.0f, render::UpscalerQuality::Native, 320, 180},
        {1.0f, render::UpscalerQuality::Quality, 213, 120},
        {1.0f, render::UpscalerQuality::Balanced, 188, 106},
        {1.0f, render::UpscalerQuality::Performance, 160, 90},
        {1.0f, render::UpscalerQuality::UltraPerformance, 107, 60},
        {0.5f, render::UpscalerQuality::Performance, 80, 45},       // 0.25: the floor itself
        {0.5f, render::UpscalerQuality::UltraPerformance, 80, 45},  // 0.167 would be below the floor
    };
    for (const Case& c : cases) {
        CAPTURE(c.windowScale);
        CAPTURE(render::upscaler_quality_name(c.quality));
        const render::UpscaleScalePlan plan = render::plan_upscale_scale(
            c.windowScale, c.quality, render::UpscalerMode::Spatial, Renderer::kMinRenderScale);
        render::UpscalerSettings s;
        s.mode = render::UpscalerMode::Spatial;
        s.quality = c.quality;
        own.r.set_upscaler(s);
        own.r.set_upscale_stage(false);  // the image of a capture is then the size the game is drawn at
        own.r.set_render_scale(plan.scale);
        const Image drawn = own.draw(p.w);
        CHECK(drawn.width == c.w);
        CHECK(drawn.height == c.h);
        // And with the stage the same game is brought to the design size.
        own.r.set_upscale_stage(plan.stage);
        const Image out = own.draw(p.w);
        CHECK(out.width == 320);
        CHECK(out.height == 180);
        CHECK(own.drawn_passes("upscale") == (plan.stage ? 1 : 0));
    }
}

TEST_CASE("spatial upscaler: stretch is the same picture whatever the quality or the sharpness say, and pixel art "
          "stays nearest") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    Own own(g);
    REQUIRE_MESSAGE(own.ok, own.error);
    Pattern p;
    // Stretch at 0.5: the settings of quality and sharpness do not touch the picture (the scale is the caller's).
    own.r.set_render_scale(0.5f);
    own.r.set_upscale_stage(true);
    const Image base = own.draw(p.w);  // the default settings
    REQUIRE(own.drawn_passes("upscale") == 1);
    render::UpscalerSettings s;
    s.sharpness = 1.0f;
    s.quality = render::UpscalerQuality::Performance;
    own.r.set_upscaler(s);
    CHECK(own.r.effective_upscaler_mode() == render::UpscalerMode::Stretch);
    CHECK(max_diff(own.draw(p.w), base) == 0);
    // The same with the spatial mode in the settings but pixel art: effective mode stretch, Nearest, the same picture as stretch.
    own.r.set_scale_mode(ScaleMode::PixelPerfect);
    s.mode = render::UpscalerMode::Stretch;
    own.r.set_upscaler(s);
    const Image nearestStretch = own.draw(p.w);
    s.mode = render::UpscalerMode::Spatial;
    own.r.set_upscaler(s);
    CHECK(own.r.effective_upscaler_mode() == render::UpscalerMode::Stretch);
    const int calls = own.r.stats(false).drawCalls;
    const Image nearestSpatial = own.draw(p.w);
    CHECK(own.r.stats(false).drawCalls == calls);
    CHECK(max_diff(nearestSpatial, nearestStretch) == 0);
    // Hard pixels: 2x2 blocks of one value (the edge of the box is on the half size grid).
    for (int y = 0; y < 180; y += 2)
        for (int x = 0; x < 320; x += 2) {
            const float a = nearestSpatial.pixel(x, y).r;
            REQUIRE(std::abs(a - nearestSpatial.pixel(x + 1, y).r) < 0.005f);
            REQUIRE(std::abs(a - nearestSpatial.pixel(x, y + 1).r) < 0.005f);
        }
    // And at scale 1 pixel art draws nothing: no stage even for the spatial mode with a sharpness.
    own.r.set_render_scale(1.0f);
    const Image one = own.draw(p.w);
    CHECK(own.drawn_passes("upscale") == 0);
    CHECK(one.width == 320);
}

// A bright square in the top-left corner of a dark picture (world y is up). A render target is stored bottom-up on OpenGL, so every pass
// that copies one render target into another must flip there (flip of blit.glsl): a pass that does not shows the picture upside down.
namespace {
struct Marker {
    World w;
    Marker() {
        Entity cam = make(w, "cam");
        w.add<Camera>(cam).clearColor = Color(0.1f, 0.1f, 0.1f, 1);
        Entity m = make(w, "marker", {-110, 55, 0});
        auto& s = w.add<Shape2D>(m);
        s.size = {80, 50};
        s.color = Color(0.9f, 0.9f, 0.9f, 1);
    }
};

// Mean red of a block of the picture, as a fraction of its size (so any output size works).
float block_mean(const Image& img, float fx0, float fy0, float fx1, float fy1) {
    const int x0 = int(fx0 * float(img.width)), x1 = int(fx1 * float(img.width));
    const int y0 = int(fy0 * float(img.height)), y1 = int(fy1 * float(img.height));
    double sum = 0.0;
    int n = 0;
    for (int y = y0; y < y1; ++y)
        for (int x = x0; x < x1; ++x) {
            sum += double(img.pixel(x, y).r);
            ++n;
        }
    return n > 0 ? float(sum / n) : 0.0f;
}

// The marker is bright in the top-left block and the other three corners are dark.
void check_marker_top_left(const Image& img, const char* what) {
    INFO(what);
    CHECK(block_mean(img, 0.05f, 0.06f, 0.25f, 0.2f) > 0.6f);
    CHECK(block_mean(img, 0.75f, 0.06f, 0.95f, 0.2f) < 0.3f);  // top-right
    CHECK(block_mean(img, 0.05f, 0.8f, 0.25f, 0.94f) < 0.3f);  // bottom-left
    CHECK(block_mean(img, 0.75f, 0.8f, 0.95f, 0.94f) < 0.3f);  // bottom-right
}
}  // namespace

TEST_CASE("spatial upscaler: the picture keeps its orientation through the stretch and every spatial pass") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    Own own(g);
    REQUIRE_MESSAGE(own.ok, own.error);
    Marker m;
    check_marker_top_left(own.draw(m.w), "without the stage");
    // Stretch at 0.5: one copy between render targets.
    own.setup(0.5f, render::UpscalerMode::Stretch);
    check_marker_top_left(own.draw(m.w), "stretch");
    CHECK(own.drawn_passes("upscale") == 1);
    // Spatial at 0.5 with a sharpness: the edge pass into the intermediate target, then the sharpen pass.
    own.setup(0.5f, render::UpscalerMode::Spatial, 0.8f);
    check_marker_top_left(own.draw(m.w), "spatial, edge and sharpen");
    const int bothCalls = own.r.stats(false).drawCalls;
    // The edge pass alone (sharpness 0).
    own.setup(0.5f, render::UpscalerMode::Spatial, 0.0f);
    check_marker_top_left(own.draw(m.w), "spatial, edge only");
    CHECK(own.r.stats(false).drawCalls == bothCalls - 1);  // the sharpen pass is the one that is missing
    // The sharpen pass alone (scale 1).
    own.setup(1.0f, render::UpscalerMode::Spatial, 1.0f);
    check_marker_top_left(own.draw(m.w), "spatial, sharpen only");
    CHECK(own.drawn_passes("upscale") == 1);
}
