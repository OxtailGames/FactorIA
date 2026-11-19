// M71-C1: the final-pass effects on the GPU (post.glsl: colour grading and the LUT, vignette, lens distortion, chromatic
// aberration, sharpen, film grain), each compared with the CPU form of the same maths (src/post_fx.h) on a picture drawn
// without the effect, with the off state pixel-identical to a frame without a stack, and a golden per effect. The tests of
// the CPU maths and of the .cube parser are in postfx_tests.cpp.
#include "test_util.h"

#include <algorithm>
#include <cmath>
#include <cstdio>
#include <fstream>
#include <functional>
#include <string>
#include <vector>

#include "frame_graph.h"
#include "post_fx.h"
#include "render_internal.h"
#include "renderer_test_access.h"

#include "fa/render/cube_lut.h"

using namespace fa;
using namespace fa::test;
using fa::render::PostFx;

namespace {

constexpr float kStep = 1.0f / 255.0f;

// A picture with something for every effect: flat areas of several colours, a white and a dark vertical stripe (edges for
// the lens, the aberration and the sharpen), over a bluish grey. Pixel (px, py) is the world position (px - 160, 90 - py).
struct FxChart {
    World world;
    Entity cam;
    explicit FxChart(bool linear = false, float bg = 0.35f) {
        if (linear) world.settings().colorSpace = ColorSpace::Linear;
        cam = make(world, "cam");
        world.add<Camera>(cam).clearColor = Color{bg * 0.9f, bg, bg * 1.2f, 1};
        patch({-90, 40}, {50, 40}, Color{0.85f, 0.25f, 0.15f, 1});
        patch({-30, 40}, {50, 40}, Color{0.2f, 0.7f, 0.25f, 1});
        patch({30, 40}, {50, 40}, Color{0.2f, 0.3f, 0.85f, 1});
        patch({-60, -40}, {80, 40}, Color{0.95f, 0.9f, 0.7f, 1});
        patch({60, -40}, {60, 60}, Color{0.12f, 0.1f, 0.14f, 1});
        patch({20, 0}, {10, 170}, Color{1, 1, 1, 1});
        patch({-110, 0}, {8, 170}, Color{0.1f, 0.1f, 0.1f, 1});
    }
    void patch(Vec2 at, Vec2 size, Color c) {
        Entity e = make(world, "patch", {at.x, at.y, 0});
        auto& s = world.add<Shape2D>(e);
        s.shape = ShapeType::Rectangle;
        s.size = size;
        s.color = c;
    }
    PostProcess& post() {
        PostProcess* p = world.get<PostProcess>(cam);
        return p ? *p : world.add<PostProcess>(cam);
    }
};

std::vector<std::string> order_of(Gfx& g) {
    const render::FrameGraph* graph = render::renderer_frame_graph(g.renderer);
    REQUIRE(graph != nullptr);
    return graph->order_names();
}

PostFx fx_of(const PostProcess& p, std::uint64_t frame = 0) {
    render::PostStack s;
    s.fx = p;
    s.sources = 1;
    auto on = [&](bool b, PostEffect e) {
        if (b) s.mask |= 1u << int(e);
    };
    on(p.lensDistortionEnabled, PostEffect::LensDistortion);
    on(p.chromaticAberrationEnabled, PostEffect::ChromaticAberration);
    on(p.colorGradingEnabled, PostEffect::ColorGrading);
    on(p.vignetteEnabled, PostEffect::Vignette);
    on(p.sharpenEnabled, PostEffect::Sharpen);
    on(p.filmGrainEnabled, PostEffect::FilmGrain);
    on(p.outlineEnabled, PostEffect::Outline);
    on(p.pixelateEnabled, PostEffect::Pixelate);
    on(p.posterizeEnabled, PostEffect::Posterize);
    return render::make_post_fx(s, frame);
}

Vec3 texel(const Image& im, int x, int y) {
    const Color c = im.pixel(std::clamp(x, 0, im.width - 1), std::clamp(y, 0, im.height - 1));
    return {c.r, c.g, c.b};
}
// The bilinear sample of the picture at uv (top-left origin); black beyond its edges.
Vec3 bilinear(const Image& im, Vec2 uv) {
    if (uv.x < 0.0f || uv.y < 0.0f || uv.x > 1.0f || uv.y > 1.0f) return {0, 0, 0};
    const float fx = uv.x * float(im.width) - 0.5f, fy = uv.y * float(im.height) - 0.5f;
    const int x0 = int(std::floor(fx)), y0 = int(std::floor(fy));
    const float tx = fx - float(x0), ty = fy - float(y0);
    const Vec3 a = lerp(texel(im, x0, y0), texel(im, x0 + 1, y0), tx);
    const Vec3 b = lerp(texel(im, x0, y0 + 1), texel(im, x0 + 1, y0 + 1), tx);
    return lerp(a, b, ty);
}
Vec2 uv_of(const Image& im, int x, int y) {
    return {(float(x) + 0.5f) / float(im.width), (float(y) + 0.5f) / float(im.height)};
}
Vec3 clamp01(Vec3 c) { return {saturate(c.x), saturate(c.y), saturate(c.z)}; }

struct Diff {
    double mean = 0.0;
    float max = 0.0f;
};
// How far `got` is from `want(x, y)` (rgb of every pixel).
Diff compare(const Image& got, const std::function<Vec3(int, int)>& want) {
    Diff d;
    double sum = 0.0;
    for (int y = 0; y < got.height; ++y)
        for (int x = 0; x < got.width; ++x) {
            const Vec3 g = texel(got, x, y), w = want(x, y);
            for (int i = 0; i < 3; ++i) {
                const float e = std::fabs(g[i] - w[i]);
                sum += e;
                d.max = std::max(d.max, e);
            }
        }
    d.mean = sum / (double(got.width) * double(got.height) * 3.0);
    return d;
}

// The frame without any effect (the reference) and with the post-processing `setup` applies.
template <class Setup>
Image shoot(Gfx& g, bool linear, Setup setup) {
    FxChart s(linear);
    setup(s.post());
    return g.draw(s.world);
}
Image reference(Gfx& g, bool linear = false) {
    FxChart s(linear);
    return g.draw(s.world);
}

std::string write_cube(Gfx& g, const std::string& name, int n, const std::function<Vec3(Vec3)>& f) {
    std::string t = "TITLE \"test table\"\nLUT_3D_SIZE " + std::to_string(n) + "\n";
    const float m = float(n - 1);
    char row[96];
    for (int b = 0; b < n; ++b)
        for (int gr = 0; gr < n; ++gr)
            for (int r = 0; r < n; ++r) {
                const Vec3 o = f({float(r) / m, float(gr) / m, float(b) / m});
                std::snprintf(row, sizeof row, "%.6f %.6f %.6f\n", double(o.x), double(o.y), double(o.z));
                t += row;
            }
    const std::filesystem::path p = g.projectDir / "assets" / name;
    std::ofstream(p, std::ios::binary) << t;
    return "assets/" + name;
}
Vec3 mixer(Vec3 c) { return {1.0f - c.z, c.y * c.y, c.x}; }

}  // namespace

// ---- free when off ----

TEST_CASE("post fx: effects switched on with their neutral values draw no pass and the frame is pixel-identical") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    const Image ref = reference(g);
    CHECK(order_of(g) == std::vector<std::string>{"camera:0/game"});
    const Image off = shoot(g, false, [](PostProcess& p) {
        p.colorGradingEnabled = true;  // neutral: nothing set
        p.colorGradingLutContribution = 0.0f;
        p.vignetteEnabled = true;
        p.vignetteIntensity = 0.0f;
        p.chromaticAberrationEnabled = true;
        p.chromaticAberrationIntensity = 0.0f;
        p.lensDistortionEnabled = true;
        p.lensDistortionIntensity = 0.0f;
        p.sharpenEnabled = true;
        p.sharpenIntensity = 0.0f;
        p.filmGrainEnabled = true;
        p.filmGrainIntensity = 0.0f;
        p.pixelateEnabled = true;  // a block of one design pixel
        p.pixelateSize = 1.0f;
        p.posterizeEnabled = true;  // 256 levels: every 8-bit value is one
        p.posterizeLevels = 256;
        p.outlineEnabled = true;  // no line
        p.outlineWidth = 0.0f;
    });
    CHECK(order_of(g) == std::vector<std::string>{"camera:0/game"});
    CHECK(off.rgba == ref.rgba);
    // A sprite outline without opacity makes no coverage image either; neither does a depth one a prepass.
    const Image noAlpha = shoot(g, false, [](PostProcess& p) {
        p.outlineEnabled = true;
        p.outlineMode = OutlineMode::Sprite;
        p.outlineColor = Color{1, 0, 1, 0.0f};
        p.outlineWidth = 3.0f;
    });
    CHECK(order_of(g) == std::vector<std::string>{"camera:0/game"});
    CHECK(noAlpha.rgba == ref.rgba);
    // A LUT named but contributing 0 is off too (the file is not even read).
    const Image lut0 = shoot(g, false, [](PostProcess& p) {
        p.colorGradingEnabled = true;
        p.colorGradingLut = "assets/never_read.cube";
        p.colorGradingLutContribution = 0.0f;
    });
    CHECK(lut0.rgba == ref.rgba);
    // And one effect on is the final pass, once.
    shoot(g, false, [](PostProcess& p) {
        p.vignetteEnabled = true;
        p.vignetteIntensity = 0.5f;
    });
    CHECK(order_of(g) == std::vector<std::string>{"camera:0/game", "camera:0/post"});
}

// ---- colour grading ----

TEST_CASE("colour grading: white balance, lift, gamma, gain, contrast, saturation and hue match the CPU, in a gamma "
          "and a linear scene") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    struct Case {
        const char* name;
        std::function<void(PostProcess&)> set;
    };
    const Case cases[] = {
        {"warm", [](PostProcess& p) { p.colorGradingTemperature = 60.0f; }},
        {"cool magenta",
         [](PostProcess& p) {
             p.colorGradingTemperature = -40.0f;
             p.colorGradingTint = 50.0f;
         }},
        {"lift", [](PostProcess& p) { p.colorGradingLift = Color{0.1f, 0.0f, 0.15f, 1}; }},
        {"gamma", [](PostProcess& p) { p.colorGradingGamma = Color{1.6f, 1.0f, 0.7f, 1}; }},
        {"gain", [](PostProcess& p) { p.colorGradingGain = Color{1.2f, 0.9f, 0.6f, 1}; }},
        {"contrast", [](PostProcess& p) { p.colorGradingContrast = 1.5f; }},
        {"saturation 0", [](PostProcess& p) { p.colorGradingSaturation = 0.0f; }},
        {"saturation 1.8", [](PostProcess& p) { p.colorGradingSaturation = 1.8f; }},
        {"hue 90", [](PostProcess& p) { p.colorGradingHueShift = 90.0f; }},
        {"everything",
         [](PostProcess& p) {
             p.colorGradingTemperature = 20.0f;
             p.colorGradingLift = Color{0.03f, 0.03f, 0.05f, 1};
             p.colorGradingGamma = Color{1.2f, 1.2f, 1.2f, 1};
             p.colorGradingGain = Color{1.1f, 1.0f, 0.95f, 1};
             p.colorGradingContrast = 1.2f;
             p.colorGradingSaturation = 1.3f;
             p.colorGradingHueShift = -25.0f;
         }},
    };
    for (const bool linear : {false, true}) {
        const Image ref = reference(g, linear);
        for (const Case& c : cases) {
            INFO(c.name << (linear ? " (linear scene)" : " (gamma scene)"));
            const Image got = shoot(g, linear, [&](PostProcess& p) {
                p.colorGradingEnabled = true;
                c.set(p);
            });
            CHECK(order_of(g) == std::vector<std::string>{"camera:0/game", "camera:0/post"});
            PostProcess p;
            p.colorGradingEnabled = true;
            c.set(p);
            const PostFx fx = fx_of(p);
            REQUIRE(fx.grade);
            const Diff d =
                compare(got, [&](int x, int y) { return clamp01(render::grade_color(fx, texel(ref, x, y))); });
            CHECK(d.mean < 0.004);
            CHECK(d.max < 0.03f);
            CHECK(got.rgba != ref.rgba);
        }
    }
    // The golden: a warm, saturated grade.
    const Image warm = shoot(g, false, [](PostProcess& p) {
        p.colorGradingEnabled = true;
        p.colorGradingTemperature = 35.0f;
        p.colorGradingSaturation = 1.4f;
        p.colorGradingContrast = 1.15f;
        p.colorGradingLift = Color{0.02f, 0.0f, 0.04f, 1};
    });
    expect_golden(warm, "post_fx_grade");
}

TEST_CASE(
    "colour grading: a .cube LUT of 16, 32 and 64 entries matches the CPU table, and the contribution blends it") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    const Image ref = reference(g);
    for (const int n : {16, 32, 64}) {
        INFO("LUT size " << n);
        const std::string path = write_cube(g, "mixer" + std::to_string(n) + ".cube", n, mixer);
        const Result<CubeLut> table = parse_cube_lut(
            [&] {
                std::ifstream in(g.projectDir / "assets" / ("mixer" + std::to_string(n) + ".cube"), std::ios::binary);
                return std::string(std::istreambuf_iterator<char>(in), {});
            }(),
            path);
        REQUIRE(table.ok());
        for (const float contribution : {1.0f, 0.5f}) {
            INFO("contribution " << contribution);
            const Image got = shoot(g, false, [&](PostProcess& p) {
                p.colorGradingEnabled = true;
                p.colorGradingLut = path;
                p.colorGradingLutContribution = contribution;
            });
            const Diff d = compare(got, [&](int x, int y) {
                return clamp01(render::apply_lut(table.value(), contribution, texel(ref, x, y)));
            });
            CHECK(d.mean < 0.004);
            CHECK(d.max < 0.03f);
            CHECK(got.rgba != ref.rgba);
            if (n == 32 && contribution == 1.0f) expect_golden(got, "post_fx_lut");
        }
    }
    // The grade comes first, the table sees its result.
    const std::string path = "assets/mixer16.cube";
    const Result<CubeLut> t16 = parse_cube_lut(
        [&] {
            std::ifstream in(g.projectDir / "assets" / "mixer16.cube", std::ios::binary);
            return std::string(std::istreambuf_iterator<char>(in), {});
        }(),
        path);
    REQUIRE(t16.ok());
    PostProcess both;
    both.colorGradingEnabled = true;
    both.colorGradingSaturation = 0.5f;
    both.colorGradingLut = path;
    const PostFx fx = fx_of(both);
    const Image got = shoot(g, false, [&](PostProcess& p) { p = both; });
    const Diff d = compare(got, [&](int x, int y) {
        return clamp01(render::apply_lut(t16.value(), 1.0f, render::grade_color(fx, texel(ref, x, y))));
    });
    CHECK(d.mean < 0.004);
    CHECK(d.max < 0.03f);
}

TEST_CASE("colour grading: a LUT that is missing or malformed is skipped with one logged error, the rest is drawn") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    const Image ref = reference(g);
    {
        std::ofstream(g.projectDir / "assets" / "broken.cube", std::ios::binary) << "LUT_3D_SIZE 2\n0 0 0\n1 0 oops\n";
    }
    for (const char* path : {"assets/not_there.cube", "assets/broken.cube"}) {
        INFO(path);
        const Image only = shoot(g, false, [&](PostProcess& p) {
            p.colorGradingEnabled = true;
            p.colorGradingLut = path;
        });
        CHECK(only.rgba == ref.rgba);  // nothing else on: no pass at all
        const Image withGrade = shoot(g, false, [&](PostProcess& p) {
            p.colorGradingEnabled = true;
            p.colorGradingLut = path;
            p.colorGradingSaturation = 0.0f;
        });
        const Image gradeOnly = shoot(g, false, [&](PostProcess& p) {
            p.colorGradingEnabled = true;
            p.colorGradingSaturation = 0.0f;
        });
        CHECK(withGrade.rgba == gradeOnly.rgba);
    }
}

TEST_CASE("colour grading: a .cube file that is half written when it is found is read again on the next frame, not an "
          "error") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    const Image ref = reference(g);
    const std::string path = write_cube(g, "m71_half.cube", 16, mixer);
    const std::filesystem::path file = g.projectDir / "assets" / "m71_half.cube";
    std::string full;
    {
        std::ifstream in(file, std::ios::binary);
        full.assign(std::istreambuf_iterator<char>(in), {});
    }
    std::ofstream(file, std::ios::binary | std::ios::trunc)
        << full.substr(0, full.size() / 2);  // the editor is still writing
    auto draw = [&] {
        return shoot(g, false, [&](PostProcess& p) {
            p.colorGradingEnabled = true;
            p.colorGradingLut = path;
        });
    };
    const Image first = draw();  // the table does not parse: this frame has no LUT, and no error is recorded yet
    CHECK(first.rgba == ref.rgba);
    std::ofstream(file, std::ios::binary | std::ios::trunc) << full;  // the write finished
    const Image second = draw();
    CHECK(second.rgba != ref.rgba);  // the table is applied
}

TEST_CASE("colour grading: a .cube file that stays malformed is an error after the retry frame, not before") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    const std::filesystem::path file = g.projectDir / "assets" / "m71_bad.cube";
    std::ofstream(file, std::ios::binary | std::ios::trunc) << "LUT_3D_SIZE 16\n0.1 0.2\n";
    auto failed = [&] {
        const Json report = g.renderer.asset_report();
        for (const Json& f : report["failures"])
            if (f["path"] == "assets/m71_bad.cube") return true;
        return false;
    };
    auto draw = [&] {
        shoot(g, false, [&](PostProcess& p) {
            p.colorGradingEnabled = true;
            p.colorGradingLut = "assets/m71_bad.cube";
        });
    };
    draw();
    CHECK_FALSE(failed());  // the first failure is a warning: the file may still be being written
    draw();
    CHECK(failed());
    draw();  // and it stays one record, not read again
    CHECK(failed());
}

// ---- vignette, lens, aberration, sharpen, grain ----

TEST_CASE("vignette: the corners go to the vignette colour as the CPU computes, in a gamma and a linear scene") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    for (const bool linear : {false, true}) {
        const Image ref = reference(g, linear);
        struct Case {
            float intensity, smooth, round;
            Vec2 center;
            Color color;
        };
        const Case cases[] = {{0.6f, 0.5f, 1.0f, {0.5f, 0.5f}, Color{0, 0, 0, 1}},
                              {1.0f, 0.2f, 0.0f, {0.5f, 0.5f}, Color{0, 0, 0, 1}},
                              {0.8f, 0.8f, 0.5f, {0.3f, 0.6f}, Color{0.4f, 0.0f, 0.1f, 1}}};
        for (const Case& c : cases) {
            INFO("intensity " << c.intensity << " smoothness " << c.smooth << " roundness " << c.round
                              << (linear ? " (linear scene)" : " (gamma scene)"));
            auto set = [&](PostProcess& p) {
                p.vignetteEnabled = true;
                p.vignetteIntensity = c.intensity;
                p.vignetteSmoothness = c.smooth;
                p.vignetteRoundness = c.round;
                p.vignetteCenter = c.center;
                p.vignetteColor = c.color;
            };
            const Image got = shoot(g, linear, set);
            PostProcess p;
            set(p);
            const PostFx fx = fx_of(p);
            const float aspect = float(ref.width) / float(ref.height);
            const Diff d = compare(got, [&](int x, int y) {
                const float a = render::vignette_amount(fx, uv_of(ref, x, y), aspect);
                return lerp(texel(ref, x, y), fx.vignetteColor, a);
            });
            CHECK(d.mean < 0.004);
            CHECK(d.max < 0.03f);
        }
    }
    const Image gold = shoot(g, false, [](PostProcess& p) {
        p.vignetteEnabled = true;
        p.vignetteIntensity = 0.75f;
        p.vignetteSmoothness = 0.6f;
    });
    expect_golden(gold, "post_fx_vignette");
}

TEST_CASE("lens distortion: barrel, pincushion, scale and an off-centre axis sample the picture where the CPU says, "
          "black outside") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    const Image ref = reference(g);
    const float aspect = float(ref.width) / float(ref.height);
    struct Case {
        const char* name;
        float intensity, scale;
        Vec2 center;
    };
    const Case cases[] = {{"barrel", 0.8f, 1.0f, {0.5f, 0.5f}},
                          {"pincushion", -0.8f, 1.0f, {0.5f, 0.5f}},
                          {"barrel zoomed in", 0.8f, 1.3f, {0.5f, 0.5f}},
                          {"off-centre axis", 1.0f, 1.0f, {0.3f, 0.65f}}};
    for (const Case& c : cases) {
        INFO(c.name);
        auto set = [&](PostProcess& p) {
            p.lensDistortionEnabled = true;
            p.lensDistortionIntensity = c.intensity;
            p.lensDistortionScale = c.scale;
            p.lensDistortionCenter = c.center;
        };
        const Image got = shoot(g, false, set);
        PostProcess p;
        set(p);
        const PostFx fx = fx_of(p);
        const Diff d = compare(
            got, [&](int x, int y) { return bilinear(ref, render::lens_source(fx, uv_of(ref, x, y), aspect)); });
        CHECK(d.mean < 0.006);
        if (std::string(c.name) == "barrel") {
            expect_golden(got, "post_fx_lens_barrel");
            // The corner leaves the picture: black there (documented), the middle is untouched.
            CHECK(got.pixel(0, 0).r < kStep);
            CHECK(got.pixel(0, 0).g < kStep);
            CHECK(texel(got, 160, 90).x == doctest::Approx(texel(ref, 160, 90).x).epsilon(0.01));
        }
        if (std::string(c.name) == "pincushion") expect_golden(got, "post_fx_lens_pincushion");
    }
}

TEST_CASE(
    "chromatic aberration: red and blue are read further out and in, green stays, the centre column is untouched") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    const Image ref = reference(g);
    for (const float intensity : {0.5f, 1.0f}) {
        INFO("intensity " << intensity);
        const Image got = shoot(g, false, [&](PostProcess& p) {
            p.chromaticAberrationEnabled = true;
            p.chromaticAberrationIntensity = intensity;
        });
        const float amount = intensity * render::kAberrationStrength;
        const Diff d = compare(got, [&](int x, int y) {
            const Vec2 uv = uv_of(ref, x, y);
            const Vec2 off{(uv.x - 0.5f) * amount, (uv.y - 0.5f) * amount};
            const Vec3 gr = bilinear(ref, uv);
            const Vec3 r = bilinear(ref, {saturate(uv.x + off.x), saturate(uv.y + off.y)});
            const Vec3 b = bilinear(ref, {saturate(uv.x - off.x), saturate(uv.y - off.y)});
            return Vec3{r.x, gr.y, b.z};
        });
        CHECK(d.mean < 0.004);
        // Green is not moved anywhere.
        double greenErr = 0.0;
        for (int y = 0; y < got.height; ++y)
            for (int x = 0; x < got.width; ++x) greenErr += std::fabs(texel(got, x, y).y - texel(ref, x, y).y);
        CHECK(greenErr / (got.width * got.height) < 0.002);
        if (intensity == 1.0f) expect_golden(got, "post_fx_aberration");
    }
    // At the stripe at the right edge the red and blue fringes differ from the original; in the middle there is none.
    const Image full = shoot(g, false, [](PostProcess& p) {
        p.chromaticAberrationEnabled = true;
        p.chromaticAberrationIntensity = 1.0f;
    });
    const Vec3 mid = texel(full, 160, 90), midRef = texel(ref, 160, 90);
    CHECK(std::fabs(mid.x - midRef.x) < 2.0f * kStep);
    CHECK(std::fabs(mid.z - midRef.z) < 2.0f * kStep);
}

TEST_CASE("sharpen: edges gain contrast as the CPU computes, flat areas and black or white edges are kept") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    const Image ref = reference(g);
    for (const float intensity : {0.5f, 1.5f}) {
        INFO("intensity " << intensity);
        const Image got = shoot(g, false, [&](PostProcess& p) {
            p.sharpenEnabled = true;
            p.sharpenIntensity = intensity;
        });
        PostProcess p;
        p.sharpenEnabled = true;
        p.sharpenIntensity = intensity;
        const PostFx fx = fx_of(p);
        const Diff d = compare(got, [&](int x, int y) {
            return render::sharpen_color(fx, texel(ref, x, y), texel(ref, x, y - 1), texel(ref, x, y + 1),
                                         texel(ref, x - 1, y), texel(ref, x + 1, y));
        });
        CHECK(d.mean < 0.004);
        CHECK(d.max < 0.03f);
        CHECK(got.rgba != ref.rgba);
        if (intensity == 1.5f) expect_golden(got, "post_fx_sharpen");
    }
    // A flat patch (inside the red one) is not touched.
    const Image one = shoot(g, false, [](PostProcess& p) {
        p.sharpenEnabled = true;
        p.sharpenIntensity = 1.0f;
    });
    const Vec3 flat = texel(one, 160 - 90, 90 - 40), flatRef = texel(ref, 160 - 90, 90 - 40);
    CHECK(std::fabs(flat.x - flatRef.x) < 2.0f * kStep);
}

TEST_CASE("film grain: the GPU adds the CPU's noise (any size and response), and a run is reproducible") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    const Image ref = reference(g);
    struct Case {
        float intensity, size, response;
    };
    const Case cases[] = {{0.5f, 1.0f, 0.8f}, {1.0f, 2.0f, 0.0f}, {0.8f, 3.0f, 1.0f}};
    for (const Case& c : cases) {
        INFO("intensity " << c.intensity << " size " << c.size << " response " << c.response);
        auto set = [&](PostProcess& p) {
            p.filmGrainEnabled = true;
            p.filmGrainIntensity = c.intensity;
            p.filmGrainSize = c.size;
            p.filmGrainLuminanceResponse = c.response;
            p.filmGrainAnimated = false;
        };
        const Image got = shoot(g, false, set);
        PostProcess p;
        set(p);
        const PostFx fx = fx_of(p);
        const Diff d =
            compare(got, [&](int x, int y) { return clamp01(render::grain_color(fx, texel(ref, x, y), x, y)); });
        CHECK(d.mean < 0.004);
        CHECK(d.max < 0.03f);
        CHECK(got.rgba != ref.rgba);
        if (c.size == 1.0f) expect_golden(got, "post_fx_grain");
    }
}

TEST_CASE("film grain: the same frame gives the same picture on every run, the next frame another, and a still grain "
          "never changes") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    auto frame = [&](bool animated, int advance) {
        FxChart s;
        PostProcess& p = s.post();
        p.filmGrainEnabled = true;
        p.filmGrainIntensity = 0.6f;
        p.filmGrainAnimated = animated;
        for (int i = 0; i < advance; ++i) s.world.advance_clock(1.0 / 60.0);
        return g.draw(s.world);
    };
    const Image a = frame(true, 0), b = frame(true, 0), next = frame(true, 1), later = frame(true, 5);
    CHECK(a.rgba == b.rgba);  // a fresh run of the same frame number: the same bytes
    CHECK(a.rgba != next.rgba);
    CHECK(next.rgba != later.rgba);
    // The pattern of frame n is the CPU's: the seed is the engine's frame counter, never a clock.
    {
        const Image ref = reference(g);
        PostProcess p;
        p.filmGrainEnabled = true;
        p.filmGrainIntensity = 0.6f;
        const PostFx fx = fx_of(p, 5);
        const Diff d =
            compare(later, [&](int x, int y) { return clamp01(render::grain_color(fx, texel(ref, x, y), x, y)); });
        CHECK(d.mean < 0.004);
    }
    const Image still0 = frame(false, 0), still9 = frame(false, 9);
    CHECK(still0.rgba == still9.rgba);
    CHECK(still0.rgba != next.rgba);  // (frame 0 of an animated grain is the still one: the seed is 0)
}

// ---- HDR output ----

namespace {
// Whether this GPU holds the display picture in floats and can read RGBA16F back (hdr_output_render_tests.cpp).
bool float_path(Gfx& g) {
    FxChart warm;
    g.draw(warm.world);
    render::Gpu* gpu = render::renderer_gpu(g.renderer);
    const sg_pixel_format f = gpu ? gpu->display_format() : SG_PIXELFORMAT_NONE;
    if (f != SG_PIXELFORMAT_RGBA16F && f != SG_PIXELFORMAT_RG11B10F) {
        MESSAGE("skipped: this GPU holds the picture in 8 bits (nothing above paper white can be stored)");
        return false;
    }
    std::vector<float> px;
    std::string err;
    if (!render::renderer_read_floats(g.renderer, false, px, &err)) {
        MESSAGE("skipped: no RGBA16F read-back on this GPU: " << err);
        return false;
    }
    return true;
}
struct Floats {
    std::vector<float> px;
    int w = 0;
    Vec3 at(int x, int y) const {
        const std::size_t i = (std::size_t(y) * std::size_t(w) + std::size_t(x)) * 4;
        return {px[i], px[i + 1], px[i + 2]};
    }
};
Floats read(Gfx& g, const Image& shot) {
    Floats f;
    std::string err;
    const bool ok = render::renderer_read_floats(g.renderer, false, f.px, &err);
    INFO("read-back error: " << err);
    REQUIRE(ok);
    f.w = shot.width;
    return f;
}
}  // namespace

TEST_CASE(
    "hdr output: the grade keeps what is above white and the vignette darkens the HDR picture as it does the SDR one") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    if (!float_path(g)) return;
    HdrOutputInfo info;
    info.requested = true;
    info.active = true;
    info.encoding = HdrEncoding::Edr;
    info.headroom = 6.0f;
    info.paperWhiteNits = 200.0f;
    render::renderer_force_output(g.renderer, &info);
    struct Reset {
        Gfx& g;
        ~Reset() { render::renderer_force_output(g.renderer, nullptr); }
    } reset{g};
    auto draw = [&](const std::function<void(PostProcess&)>& set) {
        FxChart s(false, 0.9f);
        PostProcess& p = s.post();
        p.exposureEnabled = true;
        p.exposureEv = 2.0f;  // the bright patches go well above paper white
        set(p);
        const Image shot = g.draw(s.world);
        return read(g, shot);
    };
    const Floats base = draw([](PostProcess&) {});
    // Somewhere on the chart the picture is above 1 (else the test proves nothing).
    int above = 0;
    for (int y = 0; y < 180; y += 6)
        for (int x = 0; x < 320; x += 6)
            if (base.at(x, y).x > 1.05f) ++above;
    REQUIRE(above > 50);

    PostProcess gp;
    gp.colorGradingEnabled = true;
    gp.colorGradingContrast = 1.3f;
    gp.colorGradingTemperature = 30.0f;
    gp.colorGradingGain = Color{1.1f, 1.0f, 0.9f, 1};
    const PostFx fx = fx_of(gp);
    const Floats graded = draw([&](PostProcess& p) {
        p.colorGradingEnabled = true;
        p.colorGradingContrast = 1.3f;
        p.colorGradingTemperature = 30.0f;
        p.colorGradingGain = Color{1.1f, 1.0f, 0.9f, 1};
    });
    int checked = 0;
    for (int y = 3; y < 180; y += 9)
        for (int x = 3; x < 320; x += 9) {
            const Vec3 want = render::grade_color(fx, base.at(x, y));
            const Vec3 got = graded.at(x, y);
            for (int i = 0; i < 3; ++i) CHECK(std::fabs(got[i] - want[i]) <= 0.01f + 0.01f * want[i]);
            if (want.x > 1.05f) {
                CHECK(got.x > 1.05f);  // not clipped at white
                ++checked;
            }
        }
    CHECK(checked > 20);

    PostProcess vp;
    vp.vignetteEnabled = true;
    vp.vignetteIntensity = 0.7f;
    const PostFx vfx = fx_of(vp);
    const Floats vig = draw([&](PostProcess& p) {
        p.vignetteEnabled = true;
        p.vignetteIntensity = 0.7f;
    });
    for (int y = 4; y < 180; y += 16)
        for (int x = 4; x < 320; x += 16) {
            const float a =
                render::vignette_amount(vfx, {(float(x) + 0.5f) / 320.0f, (float(y) + 0.5f) / 180.0f}, 320.0f / 180.0f);
            const Vec3 c = base.at(x, y), got = vig.at(x, y);
            for (int i = 0; i < 3; ++i) CHECK(std::fabs(got[i] - c[i] * (1.0f - a)) <= 0.01f + 0.01f * c[i]);
        }
}

// ---- a 3D scene ----

namespace {
// A plane with a cube, a sphere and a cone under a sun, seen from above and in front: returns the camera.
Entity build_scene_3d(World& w) {
    Entity cam = make(w, "cam", {0, 3, 7});
    auto& c = w.add<Camera>(cam);
    c.projection = Projection::Perspective;
    c.fov = 60;
    const Vec3 f = normalize(Vec3{0, 0.5f, 0} - Vec3{0, 3, 7});
    w.get<Transform>(cam)->rotation = {degrees(std::asin(f.y)), degrees(std::atan2(-f.x, -f.z)), 0};
    w.settings().ambientLight = Color{0.15f, 0.15f, 0.2f, 1};
    auto mesh = [&](const char* name, Vec3 pos, Color color, Vec3 scale = {1, 1, 1}) {
        Entity e = make(w, name, pos);
        w.get<Transform>(e)->scale = scale;
        auto& m = w.add<MeshRenderer>(e);
        m.mesh = name;
        m.color = color;
    };
    mesh("plane", {0, -0.5f, 0}, Color::hex(0x808890), {12, 1, 12});
    mesh("cube", {-1.6f, 0, 0}, Color::hex(0xe04040));
    mesh("sphere", {0, 0, 0}, Color::hex(0x40c040));
    mesh("cone", {1.6f, 0, 0}, Color::hex(0x4060e0));
    Entity sun = make(w, "sun", {0, 5, 0});
    w.get<Transform>(sun)->rotation = {-50, 30, 0};
    auto& l = w.add<Light>(sun);
    l.type = LightType::Directional;
    l.intensity = 1.0f;
    return cam;
}
}  // namespace

TEST_CASE("post fx: a 3D scene through grade, vignette and sharpen, golden") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    World w;
    const Entity cam = build_scene_3d(w);
    const Image plain = g.render(w);
    PostProcess& p = w.add<PostProcess>(cam);
    p.colorGradingEnabled = true;
    p.colorGradingTemperature = -25.0f;
    p.colorGradingSaturation = 1.25f;
    p.vignetteEnabled = true;
    p.vignetteIntensity = 0.5f;
    p.sharpenEnabled = true;
    p.sharpenIntensity = 0.6f;
    const Image img = g.render(w);
    CHECK(img.rgba != plain.rgba);
    expect_golden(img, "post_fx_3d");
}

// ---- posterize and pixelate (M71-C2) ----

TEST_CASE("posterize: every channel lands on one of the levels, as the CPU computes, in a gamma and a linear scene") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    for (const bool linear : {false, true}) {
        const Image ref = reference(g, linear);
        for (const int levels : {2, 4, 6, 16}) {
            INFO((linear ? "linear" : "gamma") << " scene, levels " << levels);
            const Image got = shoot(g, linear, [&](PostProcess& p) {
                p.posterizeEnabled = true;
                p.posterizeLevels = levels;
            });
            CHECK(order_of(g) == std::vector<std::string>{"camera:0/game", "camera:0/post"});
            PostProcess p;
            p.posterizeEnabled = true;
            p.posterizeLevels = levels;
            const PostFx fx = fx_of(p);
            const float n = float(levels - 1);
            int offLevel = 0, different = 0;
            for (int y = 0; y < got.height; ++y)
                for (int x = 0; x < got.width; ++x) {
                    const Vec3 c = texel(got, x, y);
                    const Vec3 want = render::posterize_color(fx, texel(ref, x, y));
                    for (int i = 0; i < 3; ++i) {
                        const float k = c[i] * n;
                        if (std::fabs(k - std::round(k)) > 0.0025f * n + 0.001f) ++offLevel;
                        if (std::fabs(c[i] - want[i]) > 0.5f / n) ++different;
                    }
                }
            CHECK(offLevel == 0);
            const int total = got.width * got.height * 3;
            CHECK(different < total / 50);
            CHECK(got.rgba != ref.rgba);
            if (!linear && levels == 4) expect_golden(got, "post_fx_posterize");
        }
    }
}

TEST_CASE("pixelate: every pixel of a block shows the colour of the block's centre, blocks cut by the edge included") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    const Image ref = reference(g);
    for (const int block : {4, 7, 16}) {
        INFO("block " << block);
        const Image got = shoot(g, false, [&](PostProcess& p) {
            p.pixelateEnabled = true;
            p.pixelateSize = float(block);
        });
        CHECK(order_of(g) == std::vector<std::string>{"camera:0/game", "camera:0/post"});
        PostProcess p;
        p.pixelateEnabled = true;
        p.pixelateSize = float(block);
        const PostFx fx = fx_of(p);
        const Diff d = compare(got, [&](int x, int y) {
            int sx = x, sy = y;
            render::pixelate_pixel(fx, x, y, ref.width, ref.height, sx, sy);
            return texel(ref, sx, sy);
        });
        CHECK(d.max < 0.012f);
        CHECK(got.rgba != ref.rgba);
        // The block's own pixels are one colour.
        const int bx = (160 / block) * block, by = (90 / block) * block;
        const Vec3 first = texel(got, bx, by);
        for (int y = by; y < std::min(by + block, got.height); ++y)
            for (int x = bx; x < std::min(bx + block, got.width); ++x) {
                const Vec3 c = texel(got, x, y);
                CHECK(std::fabs(c.x - first.x) < 0.012f);
                CHECK(std::fabs(c.y - first.y) < 0.012f);
                CHECK(std::fabs(c.z - first.z) < 0.012f);
            }
        if (block == 7) expect_golden(got, "post_fx_pixelate");
    }
}

TEST_CASE("pixelate and posterize: both together, the blocks stay on the levels") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    const Image got = shoot(g, false, [](PostProcess& p) {
        p.pixelateEnabled = true;
        p.pixelateSize = 8.0f;
        p.posterizeEnabled = true;
        p.posterizeLevels = 5;
    });
    for (int y = 0; y < got.height; y += 3)
        for (int x = 0; x < got.width; x += 3) {
            const Vec3 c = texel(got, x, y);
            for (int i = 0; i < 3; ++i) {
                const float k = c[i] * 4.0f;
                CHECK(std::fabs(k - std::round(k)) < 0.02f);
            }
        }
    // A 3x3 block at the middle of the picture is one colour.
    const Vec3 a = texel(got, 160, 90), b = texel(got, 163, 93);
    CHECK(std::fabs(a.x - b.x) < 0.01f);
}

// ---- the outline (M71-C2) ----

namespace {
bool is_magenta(const Vec3& c) { return c.x > 0.9f && c.y < 0.1f && c.z > 0.9f; }
bool same_as(const Vec3& a, const Vec3& b, float tol = 0.012f) {
    return std::fabs(a.x - b.x) < tol && std::fabs(a.y - b.y) < tol && std::fabs(a.z - b.z) < tol;
}
}  // namespace

TEST_CASE("outline (sprite): a line of the given width outside the border of the sprites, nothing inside or far away") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    const Image ref = reference(g);
    const Image got = shoot(g, false, [](PostProcess& p) {
        p.outlineEnabled = true;
        p.outlineMode = OutlineMode::Sprite;
        p.outlineColor = Color{1, 0, 1, 1};
        p.outlineWidth = 3.0f;
        p.outlineAlphaThreshold = 0.5f;
    });
    const std::vector<std::string> order = order_of(g);
    CHECK(order.size() == 3);
    CHECK(std::count(order.begin(), order.end(), std::string("camera:0/sprite-coverage")) == 1);
    CHECK(std::count(order.begin(), order.end(), std::string("camera:0/post")) == 1);
    CHECK(std::count(order.begin(), order.end(), std::string("camera:0/prepass")) == 0);
    // The red patch covers pixels 45..94 of row 50, the green one 105..154: the gap between them is 95..104.
    for (const int x : {95, 96, 97, 102, 103, 104}) {
        INFO("pixel " << x);
        CHECK(is_magenta(texel(got, x, 50)));
    }
    for (const int x : {99, 100}) {
        INFO("pixel " << x);
        CHECK(same_as(texel(got, x, 50), texel(ref, x, 50)));
    }
    // Inside the patches and away from every sprite the picture is the one without the stack.
    for (const Vec2 p :
         {Vec2{60, 50}, Vec2{80, 40}, Vec2{120, 50}, Vec2{140, 60}, Vec2{300, 10}, Vec2{250, 170}, Vec2{10, 90}}) {
        INFO("pixel " << p.x << ", " << p.y);
        CHECK(same_as(texel(got, int(p.x), int(p.y)), texel(ref, int(p.x), int(p.y))));
    }
    // The line is as wide as asked: the left side of the red patch (the dark stripe starts one pixel inside it).
    int run = 0;
    for (int x = 44; x >= 30; --x) {
        if (!is_magenta(texel(got, x, 50))) break;
        ++run;
    }
    CHECK(run >= 2);
    CHECK(run <= 4);
    expect_golden(got, "post_fx_outline_sprite");
}

TEST_CASE("outline (sprite): the alpha threshold decides how solid a sprite must be to get a line") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    auto draw = [&](float threshold) {
        World w;
        Entity cam = make(w, "cam");
        w.add<Camera>(cam).clearColor = Color{0.1f, 0.1f, 0.1f, 1};
        Entity e = make(w, "ghost", {0, 0, 0});
        auto& s = w.add<Shape2D>(e);
        s.shape = ShapeType::Rectangle;
        s.size = {40, 40};
        s.color = Color{0.8f, 0.8f, 0.2f, 0.3f};
        PostProcess& p = w.add<PostProcess>(cam);
        p.outlineEnabled = true;
        p.outlineMode = OutlineMode::Sprite;
        p.outlineColor = Color{1, 0, 1, 1};
        p.outlineWidth = 2.0f;
        p.outlineAlphaThreshold = threshold;
        return g.draw(w);
    };
    // The square covers pixels 140..179 of row 90; the pixel just left of it is outside.
    CHECK_FALSE(is_magenta(texel(draw(0.5f), 139, 90)));
    CHECK(is_magenta(texel(draw(0.2f), 139, 90)));
}

TEST_CASE("outline (depth): a 3D scene with a black line, golden") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    World w;
    const Entity cam = build_scene_3d(w);
    const Image plain = g.render(w);
    PostProcess& p = w.add<PostProcess>(cam);
    p.outlineEnabled = true;
    p.outlineMode = OutlineMode::Depth;
    p.outlineColor = Color{0.05f, 0.05f, 0.1f, 1};
    p.outlineWidth = 2.0f;
    const Image img = g.render(w);
    const std::vector<std::string> order = order_of(g);
    CHECK(std::count(order.begin(), order.end(), std::string("camera:0/prepass")) == 1);
    CHECK(img.rgba != plain.rgba);
    expect_golden(img, "post_fx_outline_depth");
}
