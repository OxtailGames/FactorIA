// M73-P3a-2: the environment from an HDRI (SceneSettings.environmentMap; include/fa/render/hdri.h, src/renderer_hdri.h,
// shaders/hdri.glsl). The first half needs no GPU: what a file may be, what the GPU gets of it and where a direction looks into the
// picture. The second half draws: the background, the orientation and the rotation, the colour spaces, the key that decides when the
// environment is baked, a file that cannot be used, hot reload, and a golden of two spheres lit by a tiny deterministic picture.
#include "test_util.h"

#include <algorithm>
#include <cmath>
#include <mutex>
#include <string>
#include <vector>

#include "fa/core/image_float.h"
#include "fa/render/hdri.h"
#include "renderer_env.h"  // kEnvPasses

using namespace fa;
using namespace fa::test;
using namespace fa::render;

namespace {

// A .hdr of w x h pixels: `color(x, y)` in linear light.
template <class F>
std::vector<std::uint8_t> hdr_bytes(int w, int h, F color) {
    ImageF img = ImageF::create(w, h, 3).value();
    for (int y = 0; y < h; ++y)
        for (int x = 0; x < w; ++x) {
            const Vec3 c = color(x, y);
            float* p = img.at(x, y);
            p[0] = c.x;
            p[1] = c.y;
            p[2] = c.z;
        }
    return encode_hdr(img);
}

// The header of a w x h .hdr with no pixels: all the checks of a file are made from it.
std::vector<std::uint8_t> hdr_header(int w, int h) {
    const std::string s =
        "#?RADIANCE\nFORMAT=32-bit_rle_rgbe\n\n-Y " + std::to_string(h) + " +X " + std::to_string(w) + "\n";
    return std::vector<std::uint8_t>(s.begin(), s.end());
}

float half_to_float(std::uint16_t h) {
    const int e = (h >> 10) & 31, m = h & 1023;
    const float s = (h & 0x8000) ? -1.0f : 1.0f;
    if (e == 0) return s * std::ldexp(float(m), -24);
    return s * std::ldexp(1.0f + float(m) / 1024.0f, e - 15);
}

bool contains(const std::string& s, const char* needle) { return s.find(needle) != std::string::npos; }

}  // namespace

TEST_CASE("hdri: only an equirectangular picture is read, and every other layout is named with the way out") {
    CHECK(hdri_layout_problem(2048, 1024, "sky.hdr").empty());
    CHECK(hdri_layout_problem(16, 8, "sky.hdr").empty());
    CHECK(hdri_layout_problem(1999, 1000, "sky.hdr").empty());  // an exporter that rounded an odd height
    const std::string probe = hdri_layout_problem(1024, 1024, "ball.hdr");
    CHECK(contains(probe, "light probe"));
    CHECK(contains(probe, "ball.hdr"));
    CHECK(contains(probe, "equirectangular"));
    CHECK(contains(hdri_layout_problem(1024, 768, "x.hdr"), "cube cross"));
    CHECK(contains(hdri_layout_problem(768, 1024, "x.hdr"), "cube cross"));
    CHECK(contains(hdri_layout_problem(6144, 1024, "x.hdr"), "six cube faces"));
    CHECK(contains(hdri_layout_problem(1024, 6144, "x.hdr"), "six cube faces"));
    const std::string odd = hdri_layout_problem(1500, 1000, "x.hdr");
    CHECK(contains(odd, "1500 x 1000"));
    CHECK(contains(odd, "Hint"));
    CHECK(contains(hdri_layout_problem(4, 2, "tiny.hdr"), "smaller"));
}

TEST_CASE("hdri: a header is checked before any pixel is read, with the file's name and the fix") {
    const auto h2k = hdr_header(2048, 1024);
    const auto ok = hdri_check(h2k.data(), h2k.size(), "sky.hdr");
    REQUIRE(ok);
    CHECK(ok->width == 2048);
    CHECK(ok->gpuWidth == 2048);
    CHECK(ok->gpuHeight == 1024);
    CHECK_FALSE(ok->shrunk());
    // RGBA16F, 8 bytes a texel, and the mip chain adds a third.
    CHECK(ok->gpuBytes > 2048u * 1024u * 8u);
    CHECK(ok->gpuBytes < 2048u * 1024u * 8u * 4u / 3u + 64u);

    // A panorama wider than the GPU gets is shrunk to 4096 x 2048 when it is loaded.
    const auto h8k = hdr_header(8192, 4096);
    const auto big = hdri_check(h8k.data(), h8k.size(), "big.hdr");
    if (hdri_decode_pixel_budget() >= 8192u * 4096u) {
        REQUIRE(big);
        CHECK(big->shrunk());
        CHECK(big->gpuWidth == kHdriMaxWidth);
        CHECK(big->gpuHeight == kHdriMaxWidth / 2);
        const auto h6k = hdr_header(6000, 3000);
        const auto mid = hdri_check(h6k.data(), h6k.size(), "mid.hdr");
        REQUIRE(mid);
        CHECK(mid->gpuWidth == kHdriMaxWidth);
        CHECK(mid->gpuHeight == kHdriMaxWidth / 2);
        // More pixels than the decoder takes: refused from the header, naming the size.
        const auto huge = hdr_header(12000, 6000);
        const auto r = hdri_check(huge.data(), huge.size(), "huge.hdr");
        REQUIRE_FALSE(r);
        CHECK(contains(r.error().message, "huge.hdr"));
        CHECK(contains(r.error().message, "12000 x 6000"));
        CHECK_FALSE(r.error().hint.empty());
    }

    // The layout, the header and the file's name are in the error.
    const auto cross = hdr_header(1024, 768);
    const auto c = hdri_check(cross.data(), cross.size(), "cross.hdr");
    REQUIRE_FALSE(c);
    CHECK(contains(c.error().message, "cross.hdr"));
    CHECK(contains(c.error().message, "cube cross"));
    const std::string text = "not a radiance file at all, but long enough to have a header";
    const std::vector<std::uint8_t> junk(text.begin(), text.end());
    const auto j = hdri_check(junk.data(), junk.size(), "junk.hdr");
    REQUIRE_FALSE(j);
    CHECK(contains(j.error().message, "junk.hdr"));
}

TEST_CASE("hdri: what the GPU gets: half floats with a mip chain, NaN and negatives gone, a huge sun kept in colour") {
    // 16 x 8: a sky of 0.5, a texel with a NaN-free sun of 1e6 (orange), a negative one.
    const auto bytes = hdr_bytes(16, 8, [](int x, int y) {
        if (x == 3 && y == 2) return Vec3{1.0e6f, 5.0e5f, 0.0f};
        if (x == 5 && y == 2) return Vec3{-4.0f, -4.0f, -4.0f};
        return Vec3{0.5f, 0.25f, 0.125f};
    });
    const auto img = hdri_from_bytes(bytes.data(), bytes.size(), "t.hdr");
    REQUIRE(img);
    CHECK(img->width == 16);
    CHECK(img->height == 8);
    REQUIRE(img->mips.size() == 5);  // 16x8, 8x4, 4x2, 2x1, 1x1
    CHECK(img->mips[0].size() == 16u * 8u * 4u);
    CHECK(img->mips[1].size() == 8u * 4u * 4u);
    CHECK(img->mips[4].size() == 4u);
    auto px = [&](int x, int y) {
        const std::uint16_t* t = &img->mips[0][(std::size_t(y) * 16 + std::size_t(x)) * 4];
        return Vec3{half_to_float(t[0]), half_to_float(t[1]), half_to_float(t[2])};
    };
    CHECK(px(0, 0).x == doctest::Approx(0.5f).epsilon(0.01));
    CHECK(px(0, 0).y == doctest::Approx(0.25f).epsilon(0.01));
    // The sun is scaled to the largest value with its colour kept (red twice green): never infinity.
    const Vec3 sun = px(3, 2);
    CHECK(sun.x == doctest::Approx(kHdriMaxValue).epsilon(0.002));
    CHECK(sun.y / sun.x == doctest::Approx(0.5f).epsilon(0.02));
    CHECK(sun.z == 0.0f);
    CHECK(std::isfinite(sun.x));
    CHECK(px(5, 2).x == 0.0f);  // negative = 0
    // Alpha is 1; the last mip is the average of the picture (all finite and not above the largest value).
    CHECK(half_to_float(img->mips[0][3]) == 1.0f);
    const std::uint16_t* last = img->mips[4].data();
    CHECK(half_to_float(last[0]) > 0.4f);
    CHECK(half_to_float(last[0]) <= kHdriMaxValue);
    // The same file gives the same texels, bit for bit.
    const auto again = hdri_from_bytes(bytes.data(), bytes.size(), "t.hdr");
    REQUIRE(again);
    CHECK(again->mips == img->mips);
    CHECK(img->bytes() == (16u * 8u + 8u * 4u + 4u * 2u + 2u + 1u) * 8u);
}

TEST_CASE("hdri: where a direction looks into the picture, and what a rotation does") {
    float u = 0, v = 0;
    hdri_uv(0, 0, -1, 0, u, v);  // looking along -Z: the middle of the picture
    CHECK(u == doctest::Approx(0.5f));
    CHECK(v == doctest::Approx(0.5f));
    hdri_uv(1, 0, 0, 0, u, v);  // +X is on the right of that
    CHECK(u == doctest::Approx(0.75f));
    hdri_uv(-1, 0, 0, 0, u, v);
    CHECK(u == doctest::Approx(0.25f));
    hdri_uv(0, 0, 1, 0, u, v);  // behind: the seam
    CHECK((std::fabs(u) < 1e-5f || std::fabs(u - 1.0f) < 1e-5f));
    hdri_uv(0, 1, 0, 0, u, v);  // up is the top row
    CHECK(v == doctest::Approx(0.0f));
    hdri_uv(0, -1, 0, 0, u, v);
    CHECK(v == doctest::Approx(1.0f));
    hdri_uv(0, 3, -4, 0, u, v);  // not normalised: 36.87 degrees up
    CHECK(v == doctest::Approx(0.5f - 0.6435011f / 3.14159265f).epsilon(1e-4));
    // A rotation of 90 turns the environment counter-clockwise seen from above: what was at +X is now at -Z.
    hdri_uv(0, 0, -1, 90, u, v);
    CHECK(u == doctest::Approx(0.75f));
    hdri_uv(1, 0, 0, 90, u, v);  // and what was at +X is now behind
    CHECK((std::fabs(u) < 1e-4f || std::fabs(u - 1.0f) < 1e-4f));
    hdri_uv(0, 0, -1, 180, u, v);
    CHECK((std::fabs(u) < 1e-4f || std::fabs(u - 1.0f) < 1e-4f));  // the seam
    hdri_uv(0, 0, -1, -90, u, v);
    CHECK(u == doctest::Approx(0.25f));
    hdri_uv(0, 0, 0, 0, u, v);  // no direction: the middle
    CHECK(u == 0.5f);
    CHECK(v == 0.5f);
}

// ---- the GPU half ----

namespace {

// Errors logged while alive.
struct Errors {
    struct Lines {
        std::mutex mu;
        std::vector<std::string> lines;
    };
    std::shared_ptr<Lines> shared = std::make_shared<Lines>();
    int id;
    Errors()
        : id(add_log_sink([l = shared](const LogEntry& e) {
              if (e.level != LogLevel::Error) return;
              std::lock_guard<std::mutex> lk(l->mu);
              l->lines.push_back(e.message);
          })) {}
    ~Errors() { remove_log_sink(id); }
    Errors(const Errors&) = delete;
    Errors& operator=(const Errors&) = delete;
    std::vector<std::string> lines() const {
        std::lock_guard<std::mutex> lk(shared->mu);
        return shared->lines;
    }
    int count(const char* needle) const {
        int n = 0;
        for (const std::string& l : lines()) n += contains(l, needle) ? 1 : 0;
        return n;
    }
};

void write_file(const std::string& path, const std::vector<std::uint8_t>& bytes) {
    REQUIRE(fs::write_bytes(path, bytes.data(), bytes.size()));
}

// A world with a camera at the origin that looks along -Z, no light and no ambient: only the environment lights anything.
struct EnvScene {
    World w;
    Entity cam;
    EnvScene() {
        cam = make(w, "cam", {0, 0, 0});
        auto& c = w.add<Camera>(cam);
        c.projection = Projection::Perspective;
        c.fov = 60;
        w.settings().ambientLight = Color{0, 0, 0, 1};
        w.settings().skyColor = Color{0.9f, 0.1f, 0.9f, 1};  // magenta: the gradient is easy to tell
        w.settings().horizonColor = Color{0.9f, 0.1f, 0.9f, 1};
    }
    Entity mesh(Vec3 pos, float scale, float metallic, float roughness, Color c = Color::white()) {
        Entity e = make(w, "sphere", pos);
        w.get<Transform>(e)->scale = {scale, scale, scale};
        auto& m = w.add<MeshRenderer>(e);
        m.mesh = "sphere";
        m.color = c;
        m.metallic = metallic;
        m.roughness = roughness;
        return e;
    }
};

// Left half of the picture (looking along -Z, the left of the screen) red, right half green.
std::vector<std::uint8_t> red_green() {
    return hdr_bytes(16, 8, [](int x, int) { return x < 8 ? Vec3{0.4f, 0.05f, 0.05f} : Vec3{0.05f, 0.4f, 0.05f}; });
}

// A sky with a sun: blue above, brown below, an orange sun of 2000 at (11, 1).
std::vector<std::uint8_t> sky_sun() {
    return hdr_bytes(16, 8, [](int x, int y) {
        if (x == 11 && y == 1) return Vec3{2000.0f, 1400.0f, 800.0f};
        return y < 4 ? Vec3{0.15f, 0.35f, 0.9f} : Vec3{0.25f, 0.18f, 0.1f};
    });
}

bool supported(Gfx& g) { return g.renderer.supports("environmentMap"); }

}  // namespace

TEST_CASE("environment map: the picture is the background, turned the way the rotation says") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    if (!supported(g)) {
        MESSAGE("environmentMap is not supported on this GPU: not run");
        return;
    }
    write_file("assets/hdri_rg.hdr", red_green());
    EnvScene s;
    s.w.settings().environmentMap = "assets/hdri_rg.hdr";
    Image img = g.render(s.w);
    const int w = img.width, h = img.height;
    // Looking along -Z: the left of the screen is the left of the picture (red), the right of it +X (green).
    CHECK(img.pixel(w / 4, h / 2).r > img.pixel(w / 4, h / 2).g + 0.2f);
    CHECK(img.pixel(3 * w / 4, h / 2).g > img.pixel(3 * w / 4, h / 2).r + 0.2f);
    s.w.settings().environmentRotation = 180.0f;  // turned half way round: the other way
    img = g.render(s.w);
    CHECK(img.pixel(w / 4, h / 2).g > img.pixel(w / 4, h / 2).r + 0.2f);
    CHECK(img.pixel(3 * w / 4, h / 2).r > img.pixel(3 * w / 4, h / 2).g + 0.2f);
    // A quarter turn puts the seam of the two colours in the middle of the screen's left side: both halves are one colour.
    s.w.settings().environmentRotation = 0.0f;
    // With environmentBackground off the picture is not drawn: the gradient is (magenta), the picture still lights.
    s.w.settings().environmentBackground = false;
    img = g.render(s.w);
    const Color sky = img.pixel(w / 2, 8);
    CHECK(sky.r > 0.5f);
    CHECK(sky.b > 0.5f);
    CHECK(sky.g < 0.4f);
}

TEST_CASE("environment map: a gamma scene and a linear scene show the same picture, and the intensity multiplies it") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    if (!supported(g)) {
        MESSAGE("environmentMap is not supported on this GPU: not run");
        return;
    }
    write_file("assets/hdri_dim.hdr", hdr_bytes(16, 8, [](int, int) { return Vec3{0.1f, 0.1f, 0.1f}; }));
    EnvScene gamma;
    gamma.w.settings().environmentMap = "assets/hdri_dim.hdr";
    const Image a = g.render(gamma.w);
    const float encoded = linear_to_srgb(0.1f);
    CHECK(std::fabs(a.pixel(160, 90).r - encoded) < 0.02f);
    EnvScene lin;
    lin.w.settings().environmentMap = "assets/hdri_dim.hdr";
    lin.w.settings().colorSpace = ColorSpace::Linear;
    const Image b = g.render(lin.w);
    CHECK(std::fabs(b.pixel(160, 90).r - a.pixel(160, 90).r) < 0.02f);
    gamma.w.settings().environmentIntensity = 2.0f;
    const Image c = g.render(gamma.w);
    CHECK(std::fabs(c.pixel(160, 90).r - 2.0f * encoded) < 0.03f);
    gamma.w.settings().environmentIntensity = 0.0f;
    CHECK(g.render(gamma.w).pixel(160, 90).r < 0.01f);
}

TEST_CASE(
    "environment map: the environment is baked when the map, the rotation or the intensity change, and only then") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    if (!supported(g)) {
        MESSAGE("environmentMap is not supported on this GPU: not run");
        return;
    }
    write_file("assets/hdri_key.hdr", sky_sun());
    EnvScene s;
    s.mesh({0, 0, -4}, 2.0f, 1.0f, 0.2f);
    s.w.settings().environmentMap = "assets/hdri_key.hdr";
    auto calls = [&]() { return g.renderer.stats().drawCalls; };
    g.render(s.w);
    const int firstCalls = calls();
    g.render(s.w);
    const int idle = calls();
    CHECK(firstCalls >= idle + kEnvPasses);  // the first frame baked
    g.render(s.w);
    CHECK(calls() == idle);  // a map that did not change is not baked again
    s.w.advance_clock(50.0);
    g.render(s.w);
    CHECK(calls() == idle);  // the clock does not matter to it
    s.w.settings().environmentRotation = 30.0f;
    g.render(s.w);
    CHECK(calls() == idle + kEnvPasses);
    g.render(s.w);
    CHECK(calls() == idle);
    s.w.settings().environmentIntensity = 1.5f;
    g.render(s.w);
    CHECK(calls() == idle + kEnvPasses);
    g.render(s.w);
    CHECK(calls() == idle);
    // The background alone does not rebake: it is the picture the bake already has.
    s.w.settings().environmentBackground = false;
    g.render(s.w);
    CHECK(calls() == idle);
    // Another file is another environment.
    write_file("assets/hdri_key2.hdr", red_green());
    s.w.settings().environmentMap = "assets/hdri_key2.hdr";
    g.render(s.w);
    CHECK(calls() == idle + kEnvPasses);
    // Without a map the sky of the scene is back (the gradient here: nothing is baked for it).
    s.w.settings().environmentMap = "";
    g.render(s.w);
    CHECK(calls() == idle);
}

TEST_CASE("environment map: a file that is replaced is loaded again and the environment is baked again") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    if (!supported(g)) {
        MESSAGE("environmentMap is not supported on this GPU: not run");
        return;
    }
    write_file("assets/hdri_reload.hdr", red_green());
    EnvScene s;
    s.w.settings().environmentMap = "assets/hdri_reload.hdr";
    Image img = g.render(s.w);
    g.render(s.w);
    const int idle = g.renderer.stats().drawCalls;
    CHECK(img.pixel(80, 90).r > img.pixel(80, 90).g);
    write_file("assets/hdri_reload.hdr", hdr_bytes(16, 8, [](int x, int) {
                   return x < 8 ? Vec3{0.05f, 0.4f, 0.05f} : Vec3{0.4f, 0.05f, 0.05f};
               }));
    g.renderer.reload_asset("assets/hdri_reload.hdr");
    img = g.render(s.w);
    CHECK(img.pixel(80, 90).g > img.pixel(80, 90).r);
    CHECK(g.renderer.stats().drawCalls == idle + kEnvPasses);
}

TEST_CASE("environment map: a file that cannot be used is one error, and the scene looks as without a map") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    if (!supported(g)) {
        MESSAGE("environmentMap is not supported on this GPU: not run");
        return;
    }
    EnvScene plain;
    plain.mesh({0, 0, -4}, 2.0f, 0.0f, 0.5f, Color{0.8f, 0.8f, 0.8f, 1});
    const Image reference = g.render(plain.w);
    write_file("assets/hdri_ball.hdr", hdr_bytes(16, 16, [](int, int) { return Vec3{1, 1, 1}; }));
    for (const char* file : {"assets/hdri_missing.hdr", "assets/hdri_ball.hdr"}) {
        CAPTURE(file);
        Errors errors;
        EnvScene s;
        s.mesh({0, 0, -4}, 2.0f, 0.0f, 0.5f, Color{0.8f, 0.8f, 0.8f, 1});
        s.w.settings().environmentMap = file;
        const Image img = g.render(s.w);
        g.render(s.w);
        g.render(s.w);
        CHECK(errors.count("environment map") == 1);  // once, not every frame
        if (std::string(file) == "assets/hdri_ball.hdr") {
            bool named = false;
            for (const std::string& l : errors.lines())
                named = named || (contains(l, "equirectangular") && contains(l, "light probe") && contains(l, "Hint"));
            CHECK(named);
        }
        CHECK(diff_images(img, reference, 0.0f).maxError == 0.0);
    }
}

TEST_CASE("environment map: a sun at the largest value times a big intensity is never infinity, in the background or "
          "in the mirror") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    if (!supported(g)) {
        MESSAGE("environmentMap is not supported on this GPU: not run");
        return;
    }
    // Every texel is 60000 (the largest the file keeps): times 4 it is over the 65504 of a half float, which is infinity in the cubes and in an
    // RGBA16F scene target, and NaN after the tone mapping. The brightest channel is limited with the colour kept, so the picture stays white.
    write_file("assets/hdri_sun.hdr", hdr_bytes(16, 8, [](int, int) { return Vec3{1.0e6f, 1.0e6f, 1.0e6f}; }));
    // The picture is darkened by 2^-17 on its way to the screen: a value that is 65000 (the limit) or 60000 (intensity 1, no limit) comes out
    // a mid grey, while an infinity would stay infinity, white, whatever a GPU does with it on the way.
    auto shot = [&](float intensity) {
        EnvScene s;
        s.mesh({0, 0, -4}, 2.0f, 1.0f, 0.05f);  // a mirror
        auto& post = s.w.add<PostProcess>(s.cam);
        post.tonemapEnabled = true;
        post.tonemapMode = TonemapMode::Neutral;
        post.exposureEnabled = true;
        post.exposureMode = ExposureMode::Manual;
        post.exposureEv = -17.0f;
        s.w.settings().colorSpace = ColorSpace::Linear;
        s.w.settings().environmentMap = "assets/hdri_sun.hdr";
        s.w.settings().environmentIntensity = intensity;
        return g.render(s.w);
    };
    const Image reference = shot(1.0f), big = shot(4.0f);
    const int cx = big.width / 2 - 14, cy = big.height / 2 - 14;
    for (const auto& at : {std::pair<int, int>{4, 4}, std::pair<int, int>{cx, cy}}) {
        CAPTURE(at.first);
        const Color a = reference.pixel(at.first, at.second), b = big.pixel(at.first, at.second);
        CHECK(a.r < 0.97f);  // the reference is a grey, not white: the test can tell
        CHECK(std::fabs(a.r - b.r) < 0.06f);
        CHECK(std::fabs(a.g - b.g) < 0.06f);
        CHECK(std::fabs(a.b - b.b) < 0.06f);
    }
}

TEST_CASE("environment map: the same picture bakes to the same lighting every time") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    if (!supported(g)) {
        MESSAGE("environmentMap is not supported on this GPU: not run");
        return;
    }
    write_file("assets/hdri_det.hdr", sky_sun());
    EnvScene s;
    s.mesh({-1.5f, 0, -5}, 2.0f, 1.0f, 0.3f);
    s.mesh({1.5f, 0, -5}, 2.0f, 0.0f, 0.9f, Color{0.8f, 0.8f, 0.8f, 1});
    s.w.settings().environmentMap = "assets/hdri_det.hdr";
    const Image first = g.render(s.w);
    s.w.settings().environmentRotation = 45.0f;  // a different bake in between
    const Image other = g.render(s.w);
    s.w.settings().environmentRotation = 0.0f;
    const Image second = g.render(s.w);
    CHECK(diff_images(first, second, 0.0f).maxError == 0.0);
    CHECK(diff_images(first, other, 0.0f).maxError > 0.0);
}

TEST_CASE(
    "environment map: the sky material draws the background, the picture lights, and the map lights over the sky") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    if (!supported(g)) {
        MESSAGE("environmentMap is not supported on this GPU: not run");
        return;
    }
    write_file("assets/hdri_prec.hdr", red_green());
    Errors errors;
    {
        // A skyMaterial that is set keeps the background (here a material that does not exist: the gradient shows, not the picture).
        EnvScene s;
        s.w.settings().environmentMap = "assets/hdri_prec.hdr";
        s.w.settings().skyMaterial = "materials/not-there.material.json";
        const Image img = g.render(s.w);
        const Color sky = img.pixel(img.width / 2, 8);
        CHECK(sky.g < 0.4f);
        CHECK(sky.r > 0.5f);
    }
    {
        // The picture lights the meshes even then: a white sphere is green on the side that faces the green half.
        EnvScene s;
        s.mesh({0, 0, -4}, 2.5f, 0.0f, 0.9f);
        s.w.settings().environmentMap = "assets/hdri_prec.hdr";
        s.w.settings().environmentBackground = false;
        const Image img = g.render(s.w);
        const int cx = img.width / 2, cy = img.height / 2;
        const Color left = img.pixel(cx - 22, cy), right = img.pixel(cx + 22, cy);
        CHECK(left.r > left.g);
        CHECK(right.g > right.r);
    }
}

TEST_CASE("environment map: the pictures: two spheres lit by a picture with a sun") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    if (!supported(g)) {
        MESSAGE("environmentMap is not supported on this GPU: not run");
        return;
    }
    write_file("assets/hdri_spheres.hdr", sky_sun());
    EnvScene s;
    s.w.get<Transform>(s.cam)->position = {0, 0.3f, 0};
    s.mesh({-1.4f, 0, -4}, 2.2f, 1.0f, 0.1f);                             // a mirror: shows the picture
    s.mesh({1.4f, 0, -4}, 2.2f, 0.0f, 0.8f, Color{0.9f, 0.9f, 0.9f, 1});  // rough white: the irradiance
    s.w.settings().environmentMap = "assets/hdri_spheres.hdr";
    s.w.settings().environmentRotation = 20.0f;
    const Image img = g.render(s.w);
    GoldenLimits wide = golden_limits(0.008);
    wide.maxDifferingShare = 0.2;
    expect_golden(img, "3d_hdri_spheres", wide);
    // The mirror shows the blue sky above and the brown ground below; the rough one is lit by the sky (blue above).
    const int cy = img.height / 2;
    const int mx = img.width / 2 - int(0.35f * img.width / 2.0f);
    const Color up = img.pixel(mx, cy - 22), down = img.pixel(mx, cy + 22);
    CHECK(up.b > up.r);
    CHECK(down.r > down.b);
}
