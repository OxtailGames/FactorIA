// M71: the post-processing stack on the GPU (src/postprocess.h, post.glsl, exposure.glsl): the passes a frame declares (none when
// nothing is on), the final pass (exposure, tonemap, the encode with a dither, the colour filter), the automatic exposure, the HUD drawn
// over the final picture, the volumes, and the Camera.bloom* / Camera.colorFilter fields standing in for a PostProcess.
#include "test_util.h"

#include <algorithm>
#include <cmath>
#include <string>
#include <vector>

#include "frame_graph.h"
#include "render_internal.h"

using namespace fa;
using namespace fa::test;

namespace {

float to_linear(float c) { return c <= 0.04045f ? c / 12.92f : std::pow((c + 0.055f) / 1.055f, 2.4f); }
float to_srgb(float c) {
    c = std::clamp(c, 0.0f, 1.0f);
    return c <= 0.0031308f ? c * 12.92f : 1.055f * std::pow(c, 1.0f / 2.4f) - 0.055f;
}
constexpr float kStep = 1.0f / 255.0f;

// A row of grey swatches of 0.25 .. 8 (a float scene format holds what several additive layers add up to) over a row of orange ones,
// on black. The swatch i of a row is at pixel x = 60 + 40 * i, grey at y = 60, orange at y = 120.
struct RampScene {
    World world;
    Entity cam;
    static constexpr int kSwatches = 6;
    explicit RampScene() {
        cam = make(world, "cam");
        world.add<Camera>(cam).clearColor = Color{0, 0, 0, 1};
        const float level[kSwatches] = {0.25f, 0.5f, 1.0f, 2.0f, 4.0f, 8.0f};
        for (int i = 0; i < kSwatches; ++i) {
            const float x = -100.0f + 40.0f * float(i);
            const int layers = level[i] <= 1.0f ? 1 : int(level[i]);
            const float v = level[i] <= 1.0f ? level[i] : 1.0f;
            for (int row = 0; row < 2; ++row)
                for (int l = 0; l < layers; ++l) {
                    Entity e = make(world, "swatch", {x, row == 0 ? 30.0f : -30.0f, 0});
                    auto& s = world.add<Shape2D>(e);
                    s.shape = ShapeType::Rectangle;
                    s.size = {40, 40};
                    s.color = row == 0 ? Color{v, v, v, 1} : Color{v, v * 0.5f, v * 0.1f, 1};
                    s.blend = BlendMode::Additive;
                }
        }
    }
    PostProcess& post() {
        PostProcess* p = world.get<PostProcess>(cam);
        return p ? *p : world.add<PostProcess>(cam);
    }
    static Color grey(const Image& img, int i) { return img.pixel(60 + 40 * i, 60); }
    static Color orange(const Image& img, int i) { return img.pixel(60 + 40 * i, 120); }
};

// A flat colour over the whole picture (the camera's clear colour) and, optionally, a screen-space box: the HUD.
struct FlatScene {
    World world;
    Entity cam;
    explicit FlatScene(float v, bool hud = false, Color hudColor = Color::white()) {
        cam = make(world, "cam");
        world.add<Camera>(cam).clearColor = Color{v, v, v, 1};
        if (hud) {
            Entity box = make(world, "hud-box", {20, 10, 0});
            auto& b = world.add<Shape2D>(box);
            b.shape = ShapeType::Rectangle;
            b.size = {40, 20};
            b.color = hudColor;
            b.space = RenderSpace::Screen;
            b.pivot = {0, 1};
        }
    }
    void clear(float v) { world.get<Camera>(cam)->clearColor = Color{v, v, v, 1}; }
    PostProcess& post() {
        PostProcess* p = world.get<PostProcess>(cam);
        return p ? *p : world.add<PostProcess>(cam);
    }
};

// A second renderer on the test GPU (the first one stays as it is), with multisampling.
struct OwnRenderer {
    Gfx& g;
    Renderer r;
    bool ok = false;
    std::string error;
    OwnRenderer(Gfx& gx, int samples) : g(gx) {
        RendererDesc d;
        d.designWidth = 320;
        d.designHeight = 180;
        d.sampleCount = samples;
        d.headless = true;
        d.adoptContext = true;
        ok = r.init(d, g.gpu.environment(), &error);
    }
    ~OwnRenderer() { r.shutdown(); }
    Image draw(World& w, float dt = 0.0f) {
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
};

std::vector<std::string> order_of(Gfx& g) {
    const render::FrameGraph* graph = render::renderer_frame_graph(g.renderer);
    REQUIRE(graph != nullptr);
    return graph->order_names();
}
int index_of(const std::vector<std::string>& names, const std::string& name) {
    const auto it = std::find(names.begin(), names.end(), name);
    return it == names.end() ? -1 : int(it - names.begin());
}
int count_prefix(const std::vector<std::string>& names, const std::string& prefix) {
    int n = 0;
    for (const std::string& s : names)
        if (s.rfind(prefix, 0) == 0) ++n;
    return n;
}
int resource_count(Gfx& g, const char* kind) {
    int n = 0;
    for (const Json& r : render::renderer_frame_graph(g.renderer)->to_json()["resources"])
        if (r["kind"].get<std::string>() == kind) ++n;
    return n;
}
bool near_value(float a, float b, float tol) { return std::fabs(a - b) <= tol; }

const char* const kTonemapNames[] = {"none", "neutral", "aces", "agx", "reinhard"};

void enable_tonemap(PostProcess& p, TonemapMode m) {
    p.tonemapEnabled = true;
    p.tonemapMode = m;
}

}  // namespace

// ---- the passes of a frame ----

TEST_CASE("post stack: a world without a stack declares no pass and no target") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    FlatScene s(0.4f, true);
    g.render(s.world);
    CHECK(order_of(g) == std::vector<std::string>{"camera:0/game"});
    CHECK(resource_count(g, "transient") == 0);
    CHECK_FALSE(g.renderer.stats().passes.empty());

    // A PostProcess whose effects are all off changes nothing: the same passes, the same picture.
    const Image plain = g.render(s.world);
    s.post();
    const Image withComponent = g.render(s.world);
    CHECK(order_of(g) == std::vector<std::string>{"camera:0/game"});
    CHECK(resource_count(g, "transient") == 0);
    CHECK(withComponent.rgba == plain.rgba);
}

TEST_CASE("post stack: bloom alone is the bloom chain and nothing after it") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    FlatScene s(0.1f);
    PostProcess& p = s.post();
    p.bloomEnabled = true;
    g.render(s.world);
    const std::vector<std::string> order = order_of(g);
    CHECK(order.front() == "camera:0/game");
    CHECK(order.back() == "camera:0/bloom-composite");
    CHECK(index_of(order, "camera:0/post") == -1);
    CHECK(index_of(order, "camera:0/color-filter") == -1);
    CHECK(count_prefix(order, "camera:0/exposure") == 0);
}

TEST_CASE("post stack: the full stack is bloom, exposure, the final pass, the HUD, the colour filter") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    FlatScene s(0.3f, true);
    PostProcess& p = s.post();
    p.bloomEnabled = true;
    p.exposureEnabled = true;
    p.exposureMode = ExposureMode::Auto;
    enable_tonemap(p, TonemapMode::Aces);
    p.colorFilterEnabled = true;
    p.colorFilterMode = ColorFilter::Greyscale;
    g.render(s.world, 1.0f / 60.0f);
    const std::vector<std::string> order = order_of(g);
    const int bright = index_of(order, "camera:0/bloom-bright"), composite = index_of(order, "camera:0/bloom-composite");
    const int luma = index_of(order, "camera:0/exposure-luma"), adapt = index_of(order, "camera:0/exposure-adapt");
    const int post = index_of(order, "camera:0/post"), hud = index_of(order, "camera:0/hud-over-post");
    const int filter = index_of(order, "camera:0/color-filter");
    CHECK(index_of(order, "camera:0/game") == 0);
    CHECK(bright > 0);
    CHECK(composite > bright);
    CHECK(luma > composite);
    CHECK(adapt > luma);
    CHECK(post > adapt);
    CHECK(hud > post);
    CHECK(filter > hud);
    CHECK(int(order.size()) == filter + 1);  // the colour filter is the last pass of the frame
    // Each pass that ran is in RenderStats::passes, in the same order.
    const RenderStats st = g.renderer.stats();
    REQUIRE(st.passes.size() == order.size());
    for (std::size_t i = 0; i < order.size(); ++i) CHECK(st.passes[i].name == order[i]);

    // Without screen-space items nothing is drawn between the final pass and the filter: the filter is fused into the final pass.
    FlatScene noHud(0.3f);
    PostProcess& q = noHud.post();
    q.exposureEnabled = true;
    enable_tonemap(q, TonemapMode::Aces);
    q.colorFilterEnabled = true;
    q.colorFilterMode = ColorFilter::Greyscale;
    g.render(noHud.world);
    CHECK(order_of(g) == std::vector<std::string>{"camera:0/game", "camera:0/post"});
}

TEST_CASE("post stack: a linear scene always has the final pass, a gamma one only when something is on") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    FlatScene s(0.4f, true);
    s.world.settings().colorSpace = ColorSpace::Gamma;
    g.render(s.world);
    CHECK(order_of(g) == std::vector<std::string>{"camera:0/game"});
    s.world.settings().colorSpace = ColorSpace::Linear;
    const Image linear = g.render(s.world);
    CHECK(order_of(g) == std::vector<std::string>{"camera:0/game", "camera:0/post", "camera:0/hud-over-post"});
    CHECK(linear.pixel(160, 150).a == doctest::Approx(1.0f));
    s.world.settings().colorSpace = ColorSpace::Gamma;
    g.render(s.world);
    CHECK(order_of(g) == std::vector<std::string>{"camera:0/game"});  // back to nothing: no residue
}

// ---- the final pass ----

TEST_CASE("tonemap: every mode keeps a grey ramp grey and rising, and has a golden") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    const TonemapMode modes[] = {TonemapMode::None, TonemapMode::Neutral, TonemapMode::Aces, TonemapMode::Agx,
                                 TonemapMode::Reinhard};
    Image first;
    for (int m = 0; m < 5; ++m) {
        INFO("tonemap " << kTonemapNames[m]);
        RampScene s;
        enable_tonemap(s.post(), modes[m]);
        const Image img = g.render(s.world);
        REQUIRE(order_of(g) == std::vector<std::string>{"camera:0/game", "camera:0/post"});
        float prev = -1.0f;
        for (int i = 0; i < RampScene::kSwatches; ++i) {
            const Color c = RampScene::grey(img, i);
            CHECK(near_value(c.r, c.g, 6 * kStep));
            CHECK(near_value(c.g, c.b, 6 * kStep));
            CHECK(c.r >= prev - 2 * kStep);
            prev = c.r;
        }
        // The curves differ from each other and from the clip.
        if (m == 0) {
            first = img;
        } else {
            CHECK_FALSE(img.rgba == first.rgba);
        }
        // A tonemap brings the swatch of 1.0 below the white the clip gives it.
        if (modes[m] != TonemapMode::None) CHECK(RampScene::grey(img, 2).r < 1.0f - 4 * kStep);
        expect_golden(img, std::string("post_tonemap_") + kTonemapNames[m]);
    }
}

TEST_CASE("exposure: manual EV scales the linear light and the output is sRGB-encoded") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    for (float ev : {-1.0f, 0.0f, 1.0f, 2.0f}) {
        INFO("EV " << ev);
        FlatScene s(0.5f);
        PostProcess& p = s.post();
        p.exposureEnabled = true;
        p.exposureEv = ev;
        const Image img = g.render(s.world);
        const float expected = to_srgb(to_linear(128.0f / 255.0f) * std::exp2(ev));
        CHECK(near_value(img.pixel(160, 90).r, expected, 3 * kStep));
        CHECK(near_value(img.pixel(160, 90).g, expected, 3 * kStep));
        CHECK(img.pixel(160, 90).a == doctest::Approx(1.0f));
    }
    RampScene s;
    s.post().exposureEnabled = true;
    s.post().exposureEv = 1.0f;
    expect_golden(g.render(s.world), "post_exposure_plus1");
}

TEST_CASE("final pass: the output is dithered by one 8-bit step, and the same every frame") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    FlatScene s(0.5f);
    s.post().exposureEnabled = true;
    const Image a = g.render(s.world);
    const Image b = g.render(s.world);
    CHECK(a.rgba == b.rgba);  // a static pattern: a run is reproducible
    int lo = 255, hi = 0;
    for (int y = 0; y < a.height; ++y)
        for (int x = 0; x < a.width; ++x) {
            const int v = a.rgba[(std::size_t(y) * std::size_t(a.width) + std::size_t(x)) * 4];
            lo = std::min(lo, v);
            hi = std::max(hi, v);
        }
    CHECK(hi - lo <= 1);  // never more than one step of noise
}

TEST_CASE("final pass: the HUD is drawn over the result in display space, and the colour filter covers it") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    FlatScene s(1.0f, true, Color{1, 0, 0, 1});
    enable_tonemap(s.post(), TonemapMode::Reinhard);
    const Image img = g.render(s.world);
    CHECK(order_of(g) == std::vector<std::string>{"camera:0/game", "camera:0/post", "camera:0/hud-over-post"});
    // Reinhard maps the white of the world to 0.5 linear, which is 0.735 encoded; the HUD keeps its own red untouched.
    CHECK(near_value(img.pixel(160, 150).r, to_srgb(0.5f), 3 * kStep));
    const Color hud = img.pixel(40, 20);
    CHECK(near_value(hud.r, 1.0f, 2 * kStep));
    CHECK(near_value(hud.g, 0.0f, 2 * kStep));

    s.post().colorFilterEnabled = true;
    s.post().colorFilterMode = ColorFilter::Greyscale;
    const Image grey = g.render(s.world);
    CHECK(order_of(g).back() == "camera:0/color-filter");
    const Color hudGrey = grey.pixel(40, 20);
    CHECK(near_value(hudGrey.r, hudGrey.g, 2 * kStep));
    CHECK(near_value(hudGrey.g, hudGrey.b, 2 * kStep));
    CHECK(hudGrey.r > 0.3f);  // the luminance of red, not black
}

TEST_CASE("final pass: with multisampling the HUD goes over the final picture the same way") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    if (!sg_query_pixelformat(SG_PIXELFORMAT_RGBA8).msaa) return;  // no multisampling on this GPU
    OwnRenderer own(g, 4);
    REQUIRE_MESSAGE(own.ok, own.error);
    FlatScene s(1.0f, true, Color{0, 1, 0, 1});
    enable_tonemap(s.post(), TonemapMode::Reinhard);
    s.post().bloomEnabled = true;
    const Image img = own.draw(s.world);
    const render::FrameGraph* graph = render::renderer_frame_graph(own.r);
    REQUIRE(graph != nullptr);
    CHECK(index_of(graph->order_names(), "camera:0/hud-over-post") > index_of(graph->order_names(), "camera:0/post"));
    CHECK(img.pixel(160, 150).r >= to_srgb(0.5f) - 4 * kStep);  // the glow of the bloom only adds to it
    CHECK(near_value(img.pixel(40, 20).g, 1.0f, 2 * kStep));
    CHECK(near_value(img.pixel(40, 20).r, 0.0f, 2 * kStep));
}

// ---- automatic exposure ----

TEST_CASE("auto exposure: it follows the picture by 1 - exp(-speed * dt) per frame and converges") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    // Without float render targets the exposure stays manual (a warning is logged): nothing to measure here.
    if (sg_query_pixelformat(SG_PIXELFORMAT_RGBA16F).render == false) return;  // the measure needs float targets
    const float dt = 1.0f / 60.0f, speed = 20.0f, lo = -6.0f, hi = 8.0f;
    FlatScene s(0.1f);
    PostProcess& p = s.post();
    p.exposureEnabled = true;
    p.exposureMode = ExposureMode::Auto;
    p.exposureMinEv = lo;
    p.exposureMaxEv = hi;
    p.exposureAdaptationSpeed = speed;
    auto target_ev = [&](float enc) { return std::clamp(std::log2(0.18f) - std::log2(to_linear(enc)), lo, hi); };
    auto output = [&](float enc, float ev) { return to_srgb(to_linear(enc) * std::exp2(ev)); };

    // The first frame takes the measured exposure at once: a dark picture is brought up to 18% grey.
    const Image first = g.render(s.world, dt);
    CHECK(count_prefix(order_of(g), "camera:0/exposure-") == 2);
    CHECK(near_value(first.pixel(160, 90).r, output(0.1f, target_ev(0.1f)), 5 * kStep));
    CHECK(near_value(first.pixel(160, 90).r, to_srgb(0.18f), 5 * kStep));

    // The picture turns bright: the exposure comes down by the same fraction of the way every frame.
    s.clear(0.8f);
    const float e0 = target_ev(0.1f), t = target_ev(0.8f);
    float previous = 2.0f;
    for (int n = 1; n <= 40; ++n) {
        const Image img = g.render(s.world, dt);
        const float ev = t + (e0 - t) * std::exp(-speed * dt * float(n));
        const float expected = output(0.8f, ev);
        INFO("frame " << n << " ev " << ev);
        CHECK(near_value(img.pixel(160, 90).r, expected, 6 * kStep));
        CHECK(img.pixel(160, 90).r <= previous + 2 * kStep);  // the picture only darkens while the exposure comes down
        previous = img.pixel(160, 90).r;
    }
    CHECK(near_value(previous, to_srgb(0.18f), 5 * kStep));  // converged on 18% grey

    // A frame of no time does not move it, however many there are.
    for (int n = 0; n < 4; ++n) {
        const Image still = g.render(s.world, 0.0f);
        CHECK(near_value(still.pixel(160, 90).r, previous, 3 * kStep));
    }
}

TEST_CASE("auto exposure: min and max EV bound it, and a gap in the effect measures again at once") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    if (sg_query_pixelformat(SG_PIXELFORMAT_RGBA16F).render == false) return;
    FlatScene s(0.1f);
    PostProcess& p = s.post();
    p.exposureEnabled = true;
    p.exposureMode = ExposureMode::Auto;
    p.exposureMinEv = -1.0f;
    p.exposureMaxEv = 1.0f;
    const float dt = 1.0f / 60.0f;
    // A frame without the effect first: what an earlier test adapted to is forgotten.
    p.exposureEnabled = false;
    g.render(s.world, dt);
    p.exposureEnabled = true;
    // The dark picture would need +4.2 stops: it gets the largest one, +1.
    const Image dark = g.render(s.world, dt);
    CHECK(near_value(dark.pixel(160, 90).r, to_srgb(to_linear(0.1f) * 2.0f), 4 * kStep));
    // An exposure that is off for a frame forgets what it adapted to: the next frame takes the measured value at once.
    p.exposureMaxEv = 8.0f;
    p.exposureMinEv = -8.0f;
    s.clear(0.8f);
    p.exposureEnabled = false;
    g.render(s.world, dt);
    p.exposureEnabled = true;
    const Image bright = g.render(s.world, dt);
    CHECK(near_value(bright.pixel(160, 90).r, to_srgb(0.18f), 5 * kStep));
}

// ---- volumes ----

TEST_CASE("volumes: a camera moving into a box volume blends the effect in, golden") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    World w;
    Entity cam = make(w, "cam");
    w.add<Camera>(cam).clearColor = Color{0.5f, 0.5f, 0.5f, 1};
    Entity vol = make(w, "volume");
    {
        auto& p = w.add<PostProcess>(vol);
        p.shape = PostShape::Box;
        p.size = {100, 100, 100};
        p.blendDistance = 100.0f;
        p.exposureEnabled = true;
        p.exposureEv = 2.0f;
    }
    // The box ends at x = -50: the camera starts 150 away (no influence), then 50 away (half), then inside (full).
    const float xs[3] = {-200.0f, -100.0f, 0.0f};
    const float influence[3] = {0.0f, 0.5f, 1.0f};
    Image strip;
    for (int i = 0; i < 3; ++i) {
        w.get<Transform>(cam)->position.x = xs[i];
        const Image img = g.render(w);
        const bool post = index_of(order_of(g), "camera:0/post") >= 0;
        CHECK(post == (influence[i] > 0.0f));  // outside the volume nothing is declared
        const float expected = influence[i] > 0.0f ? to_srgb(to_linear(128.0f / 255.0f) * std::exp2(2.0f * influence[i]))
                                                   : 128.0f / 255.0f;
        INFO("camera x " << xs[i]);
        CHECK(near_value(img.pixel(160, 90).r, expected, 3 * kStep));
        if (strip.empty()) {
            strip = img;
        } else {
            for (int y = 0; y < img.height; ++y)
                for (int x = img.width * i / 3; x < img.width * (i + 1) / 3; ++x)
                    for (int c = 0; c < 4; ++c)
                        strip.rgba[(std::size_t(y) * std::size_t(img.width) + std::size_t(x)) * 4 + std::size_t(c)] =
                            img.rgba[(std::size_t(y) * std::size_t(img.width) + std::size_t(x)) * 4 + std::size_t(c)];
        }
    }
    expect_golden(strip, "post_volume_blend");
}

// ---- Camera.bloom* and Camera.colorFilter (deprecated) ----

TEST_CASE("deprecated Camera.bloom and Camera.colorFilter draw what the same PostProcess draws") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    auto scene = [](World& w) {
        Entity cam = make(w, "cam");
        w.add<Camera>(cam).clearColor = Color{0.02f, 0.02f, 0.04f, 1};
        Entity neon = make(w, "neon", {-30, 10, 0});
        auto& s = w.add<Shape2D>(neon);
        s.shape = ShapeType::Rectangle;
        s.size = {50, 30};
        s.color = Color{1.0f, 0.2f, 0.8f, 1};
        s.blend = BlendMode::Additive;
        return cam;
    };
    World legacy, modern;
    const Entity lc = scene(legacy), mc = scene(modern);
    {
        Camera& c = *legacy.get<Camera>(lc);
        c.bloom = true;
        c.bloomThreshold = 0.6f;
        c.bloomIntensity = 1.5f;
        c.bloomRadius = 14.0f;
        c.colorFilter = ColorFilter::Deuteranopia;
        PostProcess& p = modern.add<PostProcess>(mc);
        p.bloomEnabled = true;
        p.bloomThreshold = 0.6f;
        p.bloomIntensity = 1.5f;
        p.bloomRadius = 14.0f;
        p.bloomKnee = 0.0f;
        p.colorFilterEnabled = true;
        p.colorFilterMode = ColorFilter::Deuteranopia;
    }
    const Image a = g.render(legacy);
    const std::vector<std::string> legacyOrder = order_of(g);
    const Image b = g.render(modern);
    CHECK(order_of(g) == legacyOrder);
    CHECK(index_of(legacyOrder, "camera:0/bloom-composite") > 0);
    CHECK(legacyOrder.back() == "camera:0/color-filter");
    CHECK(a.rgba == b.rgba);

    // A camera with a PostProcess of its own is the PostProcess's: the legacy fields stop counting.
    modern.get<Camera>(mc)->bloom = true;
    modern.get<Camera>(mc)->colorFilter = ColorFilter::Greyscale;
    modern.get<PostProcess>(mc)->colorFilterMode = ColorFilter::Deuteranopia;
    const Image c = g.render(modern);
    CHECK(c.rgba == b.rgba);
}

namespace {
// A 30x30 grey box of `level` on black, bloom with a threshold of 0.6. The glow is read 4 pixels outside the box.
struct GlowScene {
    World world;
    Entity cam;
    explicit GlowScene(float level, float knee, const std::string& dirt = std::string(), float dirtIntensity = 1.0f) {
        cam = make(world, "cam");
        world.add<Camera>(cam).clearColor = Color{0, 0, 0, 1};
        Entity e = make(world, "box", {0, 0, 0});
        auto& s = world.add<Shape2D>(e);
        s.shape = ShapeType::Rectangle;
        s.size = {30, 30};
        s.color = Color{level, level, level, 1};
        auto& p = world.add<PostProcess>(cam);
        p.bloomEnabled = true;
        p.bloomThreshold = 0.6f;
        p.bloomIntensity = 4.0f;
        p.bloomRadius = 10.0f;
        p.bloomKnee = knee;
        p.bloomLensDirt = dirt;
        p.bloomLensDirtIntensity = dirtIntensity;
    }
    static float glow(const Image& img) { return img.pixel(160 + 15 + 4, 90).r; }
};

std::string write_dirt(const char* name, std::uint8_t v) {
    Image img;
    img.width = img.height = 4;
    img.rgba.assign(std::size_t(4) * 4 * 4, v);
    for (std::size_t i = 3; i < img.rgba.size(); i += 4) img.rgba[i] = 255;
    const std::string path = std::string("assets/") + name;
    REQUIRE(save_png(img, path).ok());
    return path;
}
}  // namespace

TEST_CASE("bloom knee: a soft knee glows from a source at the threshold, the hard start does not") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    GlowScene hard(0.6f, 0.0f), soft(0.6f, 1.0f);  // a box exactly at the threshold
    const float h = GlowScene::glow(g.render(hard.world)), s = GlowScene::glow(g.render(soft.world));
    CHECK(h < kStep);
    CHECK(s > h + 2 * kStep);
}

TEST_CASE("bloom lens dirt: a bright dirt texture strengthens the glow, a black one and an intensity of 0 change nothing") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    const std::string white = write_dirt("m71_dirt_white.png", 255), black = write_dirt("m71_dirt_black.png", 0);
    GlowScene none(1.0f, 0.0f), lit(1.0f, 0.0f, white, 2.0f), dark(1.0f, 0.0f, black, 2.0f), off(1.0f, 0.0f, white, 0.0f);
    const float base = GlowScene::glow(g.render(none.world));
    CHECK(base > 4 * kStep);
    CHECK(GlowScene::glow(g.render(lit.world)) > base + 4 * kStep);
    CHECK(near_value(GlowScene::glow(g.render(dark.world)), base, kStep));
    CHECK(near_value(GlowScene::glow(g.render(off.world)), base, kStep));
}

TEST_CASE("bloom threshold above 1: light brighter than the threshold glows and dimmer light does not (float scene)") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    if (!sg_query_pixelformat(SG_PIXELFORMAT_RGBA16F).render) return;
    auto glow_of = [&](float threshold) {
        GlowScene s(1.0f, 0.0f);                        // a white box ...
        Entity e = make(s.world, "second", {0, 0, 0});  // ... and the same one again on top, additively: 2.0 in all
        auto& sh = s.world.add<Shape2D>(e);
        sh.shape = ShapeType::Rectangle;
        sh.size = {30, 30};
        sh.color = Color{1, 1, 1, 1};
        sh.blend = BlendMode::Additive;
        s.world.get<PostProcess>(s.cam)->bloomThreshold = threshold;
        return GlowScene::glow(g.render(s.world));
    };
    CHECK(glow_of(1.5f) > 4 * kStep);
    CHECK(glow_of(3.0f) < kStep);
}
