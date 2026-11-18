// M71-C1: the CPU side of the final-pass effects (src/post_fx.h, include/fa/render/cube_lut.h): the sanitised numbers a stack makes, the
// grading, vignette, lens, sharpen and grain maths the GPU is compared with (postfx_render_tests.cpp), and the .cube importer. No GPU.
#include <doctest.h>

#include <algorithm>
#include <cmath>
#include <format>
#include <limits>
#include <set>
#include <string>

#include "fa/render/cube_lut.h"
#include "post_fx.h"

using namespace fa;
using namespace fa::render;

namespace {

PostStack stack_with(PostEffect e) {
    PostStack s;
    s.mask |= 1u << int(e);
    s.sources = 1;
    return s;
}

// An identity table of `n` entries per side, as the text of a .cube file.
std::string identity_cube(int n, const char* title = "identity") {
    std::string t =
        std::format("# made by a test\nTITLE \"{}\"\nLUT_3D_SIZE {}\nDOMAIN_MIN 0 0 0\nDOMAIN_MAX 1 1 1\n", title, n);
    t.reserve(std::size_t(n) * n * n * 24 + 128);
    const float m = float(n - 1);
    for (int b = 0; b < n; ++b)
        for (int g = 0; g < n; ++g)
            for (int r = 0; r < n; ++r)
                t += std::format("{:.6f} {:.6f} {:.6f}\n", float(r) / m, float(g) / m, float(b) / m);
    return t;
}

bool near_v(Vec3 a, Vec3 b, float tol) {
    return std::fabs(a.x - b.x) <= tol && std::fabs(a.y - b.y) <= tol && std::fabs(a.z - b.z) <= tol;
}
float luma(Vec3 c) { return c.x * 0.2126f + c.y * 0.7152f + c.z * 0.0722f; }

}  // namespace

// ---- make_post_fx ----

TEST_CASE("post fx: a stack without these effects, or with them at their neutral values, draws none") {
    CHECK_FALSE(make_post_fx(PostStack{}, 5).any());
    // Switched on but neutral: nothing to draw, so the final pass is not made for them.
    PostStack s;
    s.mask |= 1u << int(PostEffect::ColorGrading);
    s.mask |= 1u << int(PostEffect::LensDistortion);
    s.mask |= 1u << int(PostEffect::Vignette);
    s.fx = postprocess_neutral();
    s.fx.lensDistortionIntensity = 0.0f;
    s.fx.vignetteIntensity = 0.0f;
    CHECK_FALSE(make_post_fx(s, 5).any());
    // The numbers of an effect that is not switched on are ignored.
    PostStack off;
    off.fx.vignetteIntensity = 1.0f;
    off.fx.filmGrainIntensity = 1.0f;
    CHECK_FALSE(make_post_fx(off, 0).any());
}

TEST_CASE("post fx: every number is clamped to its documented range and NaN falls back to neutral") {
    const float nan = std::numeric_limits<float>::quiet_NaN();
    PostStack g = stack_with(PostEffect::ColorGrading);
    g.fx.colorGradingContrast = 99.0f;
    g.fx.colorGradingSaturation = nan;
    g.fx.colorGradingGain = Color{-5, 100, nan, 1};
    g.fx.colorGradingHueShift = 720.0f;
    PostFx f = make_post_fx(g, 0);
    CHECK(f.grade);
    CHECK(f.contrast == doctest::Approx(3.0f));
    CHECK(f.saturation == doctest::Approx(1.0f));
    CHECK(f.gain.x == doctest::Approx(0.0f));
    CHECK(f.gain.y == doctest::Approx(8.0f));
    CHECK(f.gain.z == doctest::Approx(1.0f));
    CHECK(std::isfinite(f.hueA));

    PostStack v = stack_with(PostEffect::Vignette);
    v.fx.vignetteIntensity = 3.0f;
    v.fx.vignetteCenter = Vec2{nan, -4.0f};
    f = make_post_fx(v, 0);
    CHECK(f.vignette);
    CHECK(f.vignetteIntensity == doctest::Approx(1.0f));
    CHECK(f.vignetteCenter.x == doctest::Approx(0.5f));
    CHECK(f.vignetteCenter.y == doctest::Approx(0.0f));

    PostStack n = stack_with(PostEffect::FilmGrain);
    n.fx.filmGrainSize = 100.0f;
    f = make_post_fx(n, 0);
    CHECK(f.grainSize == doctest::Approx(4.0f));
}

TEST_CASE("post fx: a LUT is flagged only with a path and a contribution above 0") {
    PostStack s = stack_with(PostEffect::ColorGrading);
    CHECK_FALSE(make_post_fx(s, 0).lut);
    s.fx.colorGradingLut = "assets/grade.cube";
    s.fx.colorGradingLutContribution = 0.0f;
    CHECK_FALSE(make_post_fx(s, 0).lut);
    s.fx.colorGradingLutContribution = 0.5f;
    const PostFx f = make_post_fx(s, 0);
    CHECK(f.lut);
    CHECK(f.any());
    CHECK((f.mask() & kFxLut) != 0);
    CHECK(f.lutContribution == doctest::Approx(0.5f));
}

// ---- grading ----

TEST_CASE("grading: neutral values change nothing, and nothing clips above white") {
    const PostFx neutral;
    for (const Vec3 c : {Vec3{0, 0, 0}, Vec3{0.25f, 0.5f, 0.75f}, Vec3{4.0f, 2.0f, 0.5f}})
        CHECK(near_v(grade_color(neutral, c), c, 1e-5f));
    // Gain 1.5 scales a value above white too.
    PostFx f;
    f.gain = {1.5f, 1.5f, 1.5f};
    CHECK(near_v(grade_color(f, {2.0f, 1.0f, 0.5f}), {3.0f, 1.5f, 0.75f}, 1e-5f));
    // Saturation 0 is the luminance; contrast 2 about mid grey; the part above white stays.
    PostFx s;
    s.saturation = 0.0f;
    const Vec3 grey = grade_color(s, {1.0f, 0.0f, 0.0f});
    CHECK(near_v(grey, {0.2126f, 0.2126f, 0.2126f}, 1e-4f));
    PostFx k;
    k.contrast = 2.0f;
    CHECK(near_v(grade_color(k, {0.75f, 0.5f, 0.25f}), {1.0f, 0.5f, 0.0f}, 1e-5f));
    CHECK(grade_color(k, {3.0f, 3.0f, 3.0f}).x == doctest::Approx(5.5f));
}

TEST_CASE("grading: lift lifts the shadows only, gamma moves the midtones, white balance keeps the luminance") {
    PostFx l;
    l.lift = {0.2f, 0.2f, 0.2f};
    CHECK(near_v(grade_color(l, {0, 0, 0}), {0.2f, 0.2f, 0.2f}, 1e-5f));
    CHECK(near_v(grade_color(l, {1, 1, 1}), {1, 1, 1}, 1e-5f));
    CHECK(near_v(grade_color(l, {2, 2, 2}), {2, 2, 2}, 1e-5f));
    PostFx g;
    g.invGamma = {0.5f, 0.5f, 0.5f};  // PostProcess.colorGradingGamma 2
    CHECK(near_v(grade_color(g, {0.25f, 0.25f, 0.25f}), {0.5f, 0.5f, 0.5f}, 1e-5f));
    CHECK(near_v(grade_color(g, {1, 1, 1}), {1, 1, 1}, 1e-5f));

    PostStack warm = stack_with(PostEffect::ColorGrading);
    warm.fx.colorGradingTemperature = 60.0f;
    const PostFx w = make_post_fx(warm, 0);
    CHECK(w.grade);
    CHECK(w.whiteBalance.x > 1.0f);
    CHECK(w.whiteBalance.z < 1.0f);
    CHECK(luma(w.whiteBalance) == doctest::Approx(1.0f).epsilon(1e-4));
    const Vec3 out = grade_color(w, {0.5f, 0.5f, 0.5f});
    CHECK(out.x > out.z);
    PostStack cool = warm;
    cool.fx.colorGradingTemperature = -60.0f;
    const PostFx c = make_post_fx(cool, 0);
    CHECK(c.whiteBalance.x < 1.0f);
    CHECK(c.whiteBalance.z > 1.0f);
}

TEST_CASE("grading: the hue shift turns red into green at 120 degrees, keeps greys, and a full turn is the identity") {
    PostStack s = stack_with(PostEffect::ColorGrading);
    s.fx.colorGradingHueShift = 120.0f;
    PostFx f = make_post_fx(s, 0);
    CHECK(near_v(grade_color(f, {1, 0, 0}), {0, 1, 0}, 1e-4f));
    CHECK(near_v(grade_color(f, {0, 1, 0}), {0, 0, 1}, 1e-4f));
    CHECK(near_v(grade_color(f, {0.4f, 0.4f, 0.4f}), {0.4f, 0.4f, 0.4f}, 1e-4f));
    s.fx.colorGradingHueShift = 180.0f;
    f = make_post_fx(s, 0);
    const Vec3 a = grade_color(f, {0.8f, 0.3f, 0.1f});
    s.fx.colorGradingHueShift = -180.0f;
    const Vec3 b = grade_color(make_post_fx(s, 0), {0.8f, 0.3f, 0.1f});
    CHECK(near_v(a, b, 1e-4f));
    CHECK(luma(a) > 0.0f);
}

TEST_CASE("grading: the LUT adds what the table changes and keeps the part above white") {
    const Result<CubeLut> id = parse_cube_lut(identity_cube(16), "id.cube");
    REQUIRE(id.ok());
    CHECK(near_v(apply_lut(id.value(), 1.0f, {0.3f, 0.6f, 0.9f}), {0.3f, 0.6f, 0.9f}, 1e-4f));
    CHECK(near_v(apply_lut(id.value(), 1.0f, {3.0f, 2.0f, 0.5f}), {3.0f, 2.0f, 0.5f}, 1e-4f));
    // An inverting table: contribution 1 inverts what is up to white, 0.5 lands on grey, 0 leaves it.
    std::string inv = "LUT_3D_SIZE 2\n";
    for (int b = 0; b < 2; ++b)
        for (int g = 0; g < 2; ++g)
            for (int r = 0; r < 2; ++r) inv += std::format("{} {} {}\n", 1 - r, 1 - g, 1 - b);
    const Result<CubeLut> t = parse_cube_lut(inv, "inv.cube");
    REQUIRE(t.ok());
    CHECK(near_v(apply_lut(t.value(), 1.0f, {1.0f, 0.0f, 0.25f}), {0.0f, 1.0f, 0.75f}, 1e-5f));
    CHECK(near_v(apply_lut(t.value(), 0.5f, {1.0f, 0.0f, 0.5f}), {0.5f, 0.5f, 0.5f}, 1e-5f));
    CHECK(near_v(apply_lut(t.value(), 0.0f, {1.0f, 0.0f, 0.5f}), {1.0f, 0.0f, 0.5f}, 1e-6f));
    CHECK(apply_lut(t.value(), 1.0f, {2.0f, 0.0f, 0.0f}).x ==
          doctest::Approx(1.0f));  // 2 -> table(1) = 0, plus the 1 above white
}

// ---- vignette, lens, sharpen, grain ----

TEST_CASE("vignette: nothing at the centre, the full intensity at a corner, a different centre moves it") {
    PostStack s = stack_with(PostEffect::Vignette);
    s.fx.vignetteIntensity = 0.6f;
    s.fx.vignetteRoundness = 0.0f;
    s.fx.vignetteSmoothness = 0.2f;
    PostFx f = make_post_fx(s, 0);
    const float aspect = 16.0f / 9.0f;
    CHECK(vignette_amount(f, {0.5f, 0.5f}, aspect) == doctest::Approx(0.0f));
    CHECK(vignette_amount(f, {0.0f, 0.0f}, aspect) == doctest::Approx(0.6f));
    CHECK(vignette_amount(f, {1.0f, 1.0f}, aspect) == doctest::Approx(0.6f));
    float prev = -1.0f;
    for (float x = 0.5f; x >= 0.0f; x -= 0.1f) {  // darker toward the corner
        const float v = vignette_amount(f, {x, x}, aspect);
        CHECK(v >= prev - 1e-6f);
        prev = v;
    }
    s.fx.vignetteCenter = Vec2{0.0f, 0.0f};
    f = make_post_fx(s, 0);
    CHECK(vignette_amount(f, {0.0f, 0.0f}, aspect) == doctest::Approx(0.0f));
    CHECK(vignette_amount(f, {1.0f, 1.0f}, aspect) == doctest::Approx(0.6f));
}

TEST_CASE("lens: the centre stays, barrel samples further out, pincushion nearer, scale zooms, the corner can leave "
          "the picture") {
    PostStack s = stack_with(PostEffect::LensDistortion);
    const float aspect = 16.0f / 9.0f;
    s.fx.lensDistortionIntensity = 1.0f;
    PostFx barrel = make_post_fx(s, 0);
    REQUIRE(barrel.lens);
    const Vec2 c = lens_source(barrel, {0.5f, 0.5f}, aspect);
    CHECK(c.x == doctest::Approx(0.5f));
    CHECK(c.y == doctest::Approx(0.5f));
    const Vec2 e = lens_source(barrel, {0.9f, 0.5f}, aspect);
    CHECK(e.x > 0.9f);
    CHECK(e.y == doctest::Approx(0.5f));
    const Vec2 corner = lens_source(barrel, {1.0f, 1.0f}, aspect);
    CHECK(corner.x == doctest::Approx(0.5f + 0.5f * 1.3f));  // outside 0..1: the pass draws black there
    CHECK(corner.y == doctest::Approx(0.5f + 0.5f * 1.3f));
    s.fx.lensDistortionIntensity = -1.0f;
    CHECK(lens_source(make_post_fx(s, 0), {0.9f, 0.5f}, aspect).x < 0.9f);
    s.fx.lensDistortionIntensity = 0.0f;
    s.fx.lensDistortionScale = 2.0f;  // zoomed in: the pixel at 0.9 shows what is at 0.7
    const PostFx zoom = make_post_fx(s, 0);
    REQUIRE(zoom.lens);
    CHECK(lens_source(zoom, {0.9f, 0.5f}, aspect).x == doctest::Approx(0.7f));
    // The axis moves with lensDistortionCenter: that point does not move.
    s.fx.lensDistortionScale = 1.0f;
    s.fx.lensDistortionIntensity = 1.0f;
    s.fx.lensDistortionCenter = Vec2{0.25f, 0.75f};
    const Vec2 p = lens_source(make_post_fx(s, 0), {0.25f, 0.75f}, aspect);
    CHECK(p.x == doctest::Approx(0.25f));
    CHECK(p.y == doctest::Approx(0.75f));
}

TEST_CASE("sharpen: a flat area is kept, an edge gets more contrast, and a pixel already at the limit is not pushed") {
    PostStack s = stack_with(PostEffect::Sharpen);
    s.fx.sharpenIntensity = 1.0f;
    const PostFx f = make_post_fx(s, 0);
    REQUIRE(f.sharpen);
    const Vec3 mid{0.5f, 0.5f, 0.5f}, dark{0.3f, 0.3f, 0.3f};
    CHECK(near_v(sharpen_color(f, mid, mid, mid, mid, mid), mid, 1e-5f));
    CHECK(sharpen_color(f, mid, dark, dark, dark, dark).x > 0.5f);
    CHECK(sharpen_color(f, dark, mid, mid, mid, mid).x < 0.3f);
    const Vec3 white{1, 1, 1}, black{0, 0, 0};
    CHECK(near_v(sharpen_color(f, white, black, black, black, black), white, 1e-5f));
    // A higher intensity pushes further.
    s.fx.sharpenIntensity = 2.0f;
    CHECK(sharpen_color(make_post_fx(s, 0), mid, dark, dark, dark, dark).x >
          sharpen_color(f, mid, dark, dark, dark, dark).x);
}

TEST_CASE("film grain: the same frame and pixel give the same noise, another frame another one, a cell of size 2 is "
          "one value") {
    PostStack s = stack_with(PostEffect::FilmGrain);
    s.fx.filmGrainIntensity = 0.5f;
    s.fx.filmGrainSize = 1.0f;
    s.fx.filmGrainAnimated = true;
    const PostFx a = make_post_fx(s, 7), a2 = make_post_fx(s, 7), b = make_post_fx(s, 8);
    int differ = 0;
    double sum = 0.0;
    for (int y = 0; y < 64; ++y)
        for (int x = 0; x < 64; ++x) {
            const float n = grain_noise(x, y, a);
            CHECK(n == grain_noise(x, y, a2));
            CHECK(n >= -1.0f);
            CHECK(n <= 1.0f);
            sum += n;
            if (n != grain_noise(x, y, b)) ++differ;
        }
    CHECK(differ > 64 * 64 * 9 / 10);          // another frame: a new pattern
    CHECK(std::fabs(sum / (64 * 64)) < 0.03);  // no bias
    // Not animated: the frame does not matter.
    s.fx.filmGrainAnimated = false;
    const PostFx st1 = make_post_fx(s, 1), st2 = make_post_fx(s, 999);
    CHECK(grain_noise(3, 4, st1) == grain_noise(3, 4, st2));
    // Size 2: the four pixels of a cell share a value, the next cell has another.
    s.fx.filmGrainSize = 2.0f;
    const PostFx big = make_post_fx(s, 0);
    CHECK(grain_noise(0, 0, big) == grain_noise(1, 0, big));
    CHECK(grain_noise(0, 0, big) == grain_noise(1, 1, big));
    int cells = 0;
    for (int x = 2; x < 40; x += 2)
        if (grain_noise(x, 0, big) != grain_noise(0, 0, big)) ++cells;
    CHECK(cells > 15);
}

TEST_CASE("film grain: the luminance response weakens it in black and white and the intensity bounds it") {
    PostStack s = stack_with(PostEffect::FilmGrain);
    s.fx.filmGrainIntensity = 1.0f;
    s.fx.filmGrainLuminanceResponse = 1.0f;
    const PostFx f = make_post_fx(s, 3);
    float darkMax = 0, midMax = 0;
    for (int x = 0; x < 64; ++x) {
        darkMax = std::max(darkMax, std::fabs(grain_color(f, {0, 0, 0}, x, 0).x));
        midMax = std::max(midMax, std::fabs(grain_color(f, {0.5f, 0.5f, 0.5f}, x, 0).x - 0.5f));
    }
    CHECK(darkMax == doctest::Approx(0.0f));
    CHECK(midMax > 0.05f);
    CHECK(midMax <= kGrainStrength + 1e-5f);
    s.fx.filmGrainLuminanceResponse = 0.0f;
    float blackMax = 0;
    for (int x = 0; x < 64; ++x) blackMax = std::max(blackMax, grain_color(make_post_fx(s, 3), {0, 0, 0}, x, 0).x);
    CHECK(blackMax > 0.05f);  // the same grain everywhere (never below 0)
}

// ---- the .cube importer ----

TEST_CASE("cube: tables of 16, 32 and 64 entries parse, sample as the identity, and lay out as a strip") {
    for (const int n : {16, 32, 64}) {
        CAPTURE(n);
        const Result<CubeLut> r = parse_cube_lut(identity_cube(n, "my grade"), "grade.cube");
        REQUIRE(r.ok());
        const CubeLut& lut = r.value();
        CHECK(lut.size == n);
        CHECK(lut.title == "my grade");
        CHECK(lut.rgb.size() == std::size_t(n) * n * n * 3);
        CHECK(near_v(lut.sample({0.37f, 0.62f, 0.11f}), {0.37f, 0.62f, 0.11f}, 1e-4f));
        CHECK(near_v(lut.at(n - 1, 0, 0), {1, 0, 0}, 1e-6f));  // red varies fastest
        CHECK(near_v(lut.at(0, n - 1, 0), {0, 1, 0}, 1e-6f));
        CHECK(near_v(lut.at(0, 0, n - 1), {0, 0, 1}, 1e-6f));
        const CubeLutStrip strip = cube_lut_strip(lut);
        CHECK(strip.size == n);
        CHECK(strip.cols * strip.rows >= n);
        CHECK(strip.rgba.size() == std::size_t(strip.width()) * std::size_t(strip.height()) * 4);
        // The slice of blue index b sits at (b % cols, b / cols); its pixel (r, g) holds the entry (r, g, b).
        const int b = n - 1, er = n / 2, eg = n / 3;
        const int px = (b % strip.cols) * n + er, py = (b / strip.cols) * n + eg;
        const std::size_t at = (std::size_t(py) * std::size_t(strip.width()) + std::size_t(px)) * 4;
        CHECK(int(strip.rgba[at + 2]) == 255);
        CHECK(int(strip.rgba[at + 3]) == 255);
        CHECK(std::abs(int(strip.rgba[at]) - int(std::lround(float(er) / float(n - 1) * 255.0f))) <= 1);
    }
}

TEST_CASE("cube: the odd sizes 17, 33 and 65 and the CRLF line ends of a Windows export parse too") {
    for (const int n : {17, 33, 65}) {
        const Result<CubeLut> r = parse_cube_lut(identity_cube(n), "x.cube");
        CHECK(r.ok());
    }
    std::string crlf = identity_cube(16);
    std::string out;
    for (const char ch : crlf) {
        if (ch == '\n') out += '\r';
        out += ch;
    }
    const Result<CubeLut> r = parse_cube_lut("\xEF\xBB\xBF" + out, "crlf.cube");  // with a byte order mark too
    REQUIRE(r.ok());
    CHECK(r.value().size == 16);
}

TEST_CASE("cube: a malformed file is an error that names the file and the line, and says how to fix it") {
    auto fails = [](const std::string& text, const char* where, const char* what) {
        INFO("text: " << text.substr(0, 60));
        const Result<CubeLut> r = parse_cube_lut(text, "bad.cube");
        REQUIRE_FALSE(r.ok());
        const std::string msg = r.error().message;
        CAPTURE(msg);
        CHECK(msg.find(where) != std::string::npos);
        CHECK(msg.find(what) != std::string::npos);
        CHECK_FALSE(r.error().hint.empty());
        return r.error();
    };
    fails("TITLE \"x\"\nLUT_1D_SIZE 16\n", "bad.cube:2:", "1D");
    fails("LUT_3D_SIZE 2\n0 0 0\n1 0 0\n0 oops 0\n", "bad.cube:4:", "three numbers");
    fails("LUT_3D_SIZE 2\n0 0\n", "bad.cube:2:", "three numbers");
    fails("LUT_3D_SIZE 1\n0 0 0\n", "bad.cube:1:", "LUT_3D_SIZE");
    fails("LUT_3D_SIZE 99\n", "bad.cube:1:", "LUT_3D_SIZE");
    fails("0 0 0\nLUT_3D_SIZE 2\n", "bad.cube:1:", "before LUT_3D_SIZE");
    fails("# only a comment\n", "bad.cube", "LUT_3D_SIZE");
    fails("LUT_3D_SIZE 2\nDOMAIN_MAX 2 2 2\n", "bad.cube:2:", "DOMAIN_MAX");
    fails("LUT_3D_SIZE 2\n0 0 0\n1 0 0\n", "bad.cube", "colour rows");  // 2 of 8
    const Error typo = fails("LUT_3D_SIZ 2\n", "bad.cube:1:", "unknown keyword");
    CHECK(typo.hint.find("LUT_3D_SIZE") != std::string::npos);  // did you mean
    std::string tooMany = "LUT_3D_SIZE 2\n";
    for (int i = 0; i < 9; ++i) tooMany += "0 0 0\n";
    fails(tooMany, "bad.cube:10:", "more colour rows");
}

TEST_CASE("cube: numbers are read the same in every locale (a decimal point, never a comma)") {
    std::string t = "LUT_3D_SIZE 2\n";
    for (int i = 0; i < 8; ++i) t += "0.5 1e-1 -0.25\n";
    const Result<CubeLut> r = parse_cube_lut(t, "n.cube");
    REQUIRE(r.ok());
    CHECK(r.value().at(1, 1, 1).x == doctest::Approx(0.5f));
    CHECK(r.value().at(1, 1, 1).y == doctest::Approx(0.1f));
    CHECK(r.value().at(1, 1, 1).z == doctest::Approx(-0.25f));  // kept as written; the strip clamps
    const CubeLutStrip strip = cube_lut_strip(r.value());
    CHECK(int(strip.rgba[2]) == 0);
}
