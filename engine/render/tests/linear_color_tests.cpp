// SceneSettings.colorSpace "linear" (M71-B1): the colours the author picks are converted, the colour textures are read as sRGB, the
// scene target holds linear light and the picture is encoded on its way to the screen. A gamma scene is untouched.
// Every case that draws in a linear scene uses its own Renderer (on the open device), so the shared one of gfx() keeps its colour
// space for the cases after it.
#include "test_util.h"

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <cstdlib>
#include <memory>
#include <string>
#include <tuple>

#include "color_space.h"
#include "render_internal.h"

using namespace fa;
using namespace fa::test;

namespace {

struct Own {
    Renderer r;
    bool ok = false;
    std::string error;
    explicit Own(Gfx& g, const char* sceneFormat = nullptr) {
        EnvGuard hook("FA_SCENE_FORMAT", sceneFormat);  // read by Gpu::init, only while this renderer starts
        RendererDesc d;
        d.designWidth = 320;
        d.designHeight = 180;
        d.sampleCount = std::getenv("FA_TEST_SAMPLES") ? std::atoi(std::getenv("FA_TEST_SAMPLES")) : 1;
        d.headless = true;
        d.adoptContext = true;
        ok = r.init(d, g.gpu.environment(), &error);
    }
    ~Own() { r.shutdown(); }
    Own(const Own&) = delete;
    Own& operator=(const Own&) = delete;
    render::Gpu& gpu() { return *render::renderer_gpu(r); }
    Image draw(Gfx& g, World& w) {
        r.begin_frame();
        r.render_world(w, 0.0f);
        r.end_frame();
        g.gpu.end_frame();
        Image img;
        std::string err;
        REQUIRE_MESSAGE(r.capture(img, &err), err);
        return img;
    }
};

void linear(World& w, bool on = true) { w.settings().colorSpace = on ? ColorSpace::Linear : ColorSpace::Gamma; }

Entity camera(World& w, Color clear = Color::black()) {
    Entity cam = make(w, "cam");
    w.add<Camera>(cam).clearColor = clear;
    return cam;
}

Entity rect(World& w, Vec3 pos, Color color, Vec2 size = {40, 40}) {
    Entity e = make(w, "rect", pos);
    auto& sh = w.add<Shape2D>(e);
    sh.shape = ShapeType::Rectangle;
    sh.size = size;
    sh.color = color;
    return e;
}

void save(const Image& img, const char* path) { REQUIRE(save_png(img, path).ok()); }

Image solid(int w, int h, std::uint8_t v) {
    Image img;
    img.width = w;
    img.height = h;
    img.rgba.assign(std::size_t(w) * std::size_t(h) * 4, v);
    for (std::size_t i = 3; i < img.rgba.size(); i += 4) img.rgba[i] = 255;
    return img;
}

// A 256 x 1 ramp: texel i holds the grey i.
Image ramp() {
    Image img = solid(256, 1, 0);
    for (int i = 0; i < 256; ++i)
        for (int c = 0; c < 3; ++c) img.rgba[std::size_t(i) * 4 + std::size_t(c)] = std::uint8_t(i);
    return img;
}

// The pixel (x, y) of the 320 x 180 picture of the default camera shows the world point (x - 160, 90 - y).
Color at(const Image& img, float wx, float wy) { return img.pixel(int(160 + wx), int(90 - wy)); }

double worst_error(const Image& a, const Image& b) {
    REQUIRE(a.width == b.width);
    REQUIRE(a.height == b.height);
    double worst = 0;
    for (int y = 0; y < a.height; ++y)
        for (int x = 0; x < a.width; ++x) {
            const Color p = a.pixel(x, y), q = b.pixel(x, y);
            worst = std::max(
                {worst, double(std::fabs(p.r - q.r)), double(std::fabs(p.g - q.g)), double(std::fabs(p.b - q.b))});
        }
    return worst;
}

bool same_bytes(const Image& a, const Image& b) {
    return a.width == b.width && a.height == b.height && a.rgba == b.rgba;
}

void add_camera3d(World& w, Vec3 pos, Vec3 lookAt) {
    Entity cam = make(w, "cam", pos);
    auto& c = w.add<Camera>(cam);
    c.projection = Projection::Perspective;
    c.fov = 60;
    const Vec3 f = normalize(lookAt - pos);
    w.get<Transform>(cam)->rotation = {degrees(std::asin(f.y)), degrees(std::atan2(-f.x, -f.z)), 0};
}

Entity add_mesh(World& w, const char* mesh, Vec3 pos, Color color, Vec3 scale = {1, 1, 1}) {
    Entity e = make(w, mesh, pos);
    w.get<Transform>(e)->scale = scale;
    auto& m = w.add<MeshRenderer>(e);
    m.mesh = mesh;
    m.color = color;
    return e;
}

Entity add_light3d(World& w, LightType type, Vec3 pos, Vec3 rot, float intensity, Color c = Color::white()) {
    Entity e = make(w, "light", pos);
    w.get<Transform>(e)->rotation = rot;
    auto& l = w.add<Light>(e);
    l.type = type;
    l.intensity = intensity;
    l.color = c;
    l.range = 12;
    return e;
}

void primitives_3d(World& w) {
    add_camera3d(w, {0, 3, 7}, {0, 0.5f, 0});
    w.settings().ambientLight = Color{0.15f, 0.15f, 0.2f, 1};
    add_mesh(w, "plane", {0, -0.5f, 0}, Color::hex(0x808890), {12, 1, 12});
    add_mesh(w, "cube", {-3.2f, 0, 0}, Color::hex(0xe04040));
    add_mesh(w, "sphere", {-1.6f, 0, 0}, Color::hex(0x40c040));
    add_mesh(w, "cylinder", {0, 0, 0}, Color::hex(0x4060e0));
    add_mesh(w, "capsule", {1.6f, 0.5f, 0}, Color::hex(0xe0c040));
    add_mesh(w, "cone", {3.2f, 0, 0}, Color::hex(0xc040e0));
    add_light3d(w, LightType::Directional, {0, 5, 0}, {-50, 30, 0}, 0.9f);
    add_light3d(w, LightType::Point, {0, 2, 3}, {0, 0, 0}, 1.2f, Color::hex(0xffa040));
}

}  // namespace

TEST_CASE("color space: the sRGB transfer functions of the CPU round-trip and match the known values") {
    using namespace fa::render;
    CHECK(srgb_to_linear(0.0f) == 0.0f);
    CHECK(srgb_to_linear(1.0f) == doctest::Approx(1.0f));
    CHECK(srgb_to_linear(0.5f) == doctest::Approx(0.214041f).epsilon(1e-4));
    CHECK(linear_to_srgb(0.5f) == doctest::Approx(0.735357f).epsilon(1e-4));
    CHECK(srgb_to_linear(0.02f) == doctest::Approx(0.02f / 12.92f));  // the linear toe
    for (int i = 0; i <= 255; ++i)
        CHECK(linear_to_srgb(srgb_to_linear(float(i) / 255.0f)) == doctest::Approx(float(i) / 255.0f).epsilon(1e-3));
    CHECK(srgb_to_linear(-1.0f) == 0.0f);          // below black is black
    CHECK(srgb_to_linear(std::nanf("")) == 0.0f);  // a NaN from a script never reaches the GPU
    CHECK(srgb_to_linear(4.0f) > 4.0f);            // light above white keeps its meaning
    const Color c = srgb_to_linear(Color{0.5f, 0.5f, 0.5f, 0.25f});
    CHECK(c.a == 0.25f);  // coverage is not light
    CHECK(to_scene(Color{0.5f, 0.5f, 0.5f, 1}, false).r == 0.5f);
}

TEST_CASE("color space: a tint, a colour texture and a half-transparent shape come out as picked, and blend in linear "
          "light") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    save(solid(16, 16, 128), "assets/lin_grey128.png");
    auto build = [&](bool lin) {
        auto w = std::make_unique<World>();
        camera(*w);
        linear(*w, lin);
        rect(*w, {-100, 0, 0}, Color{0.5f, 0.5f, 0.5f, 1});  // an authored mid-grey
        rect(*w, {-40, 0, 0}, Color{1, 1, 1, 0.5f});         // 50% white over black
        Entity e = make(*w, "sprite", {20, 0, 0});
        auto& sp = w->add<Sprite>(e);
        sp.texture = "assets/lin_grey128.png";  // a grey 128 texture
        sp.size = {40, 40};
        sp.pixelArt = true;
        return w;
    };
    Own gamma(g), lin(g);
    REQUIRE_MESSAGE(gamma.ok, gamma.error);
    REQUIRE_MESSAGE(lin.ok, lin.error);
    auto wg = build(false), wl = build(true);
    const Image a = gamma.draw(g, *wg), b = lin.draw(g, *wl);
    // Picked colours and textures keep their look in both colour spaces ...
    for (const Image* img : {&a, &b}) {
        CHECK(at(*img, -100, 0).r == doctest::Approx(0.5f).epsilon(0.03));
        CHECK(at(*img, 20, 0).r == doctest::Approx(128.0f / 255.0f).epsilon(0.03));
    }
    // ... while the blending of a half-transparent white over black is the difference: 0.5 on the sRGB values, half the light
    // (0.5 linear, which the display shows as 0.735) in a linear scene.
    CHECK(at(a, -40, 0).r == doctest::Approx(0.5f).epsilon(0.03));
    CHECK(at(b, -40, 0).r == doctest::Approx(0.7354f).epsilon(0.03));
    CHECK(at(b, -40, 0).a == doctest::Approx(1.0f));
}

TEST_CASE("color space: a lit 2D scene in linear light (golden) differs from the gamma one, an unlit shape keeps its "
          "colour") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    auto build = [&](bool lin) {
        auto w = std::make_unique<World>();
        camera(*w);
        linear(*w, lin);
        w->settings().ambientLight = Color{0.15f, 0.15f, 0.2f, 1};
        const ShapeType kinds[5] = {ShapeType::Rectangle, ShapeType::Circle, ShapeType::Triangle, ShapeType::Star,
                                    ShapeType::Line};
        for (int row = 0; row < 2; ++row)
            for (int i = 0; i < 5; ++i) {
                Entity e = make(*w, "shape", {-112.0f + 56.0f * float(i), row == 0 ? 36.0f : -36.0f, 0});
                auto& sh = w->add<Shape2D>(e);
                sh.shape = kinds[i];
                sh.size = kinds[i] == ShapeType::Line ? Vec2{40, 40} : Vec2{44, 44};
                sh.color = Color{0.9f, 0.6f, 0.3f, 1};
                sh.filled = i != 1 || row == 1;
                sh.thickness = 6;
                sh.lit = row == 0;
            }
        Entity lamp = make(*w, "lamp", {-60, 36, 0});
        auto& l = w->add<Light2D>(lamp);
        l.color = Color{1.0f, 0.85f, 0.6f, 1};
        l.radius = 200;
        l.intensity = 1.0f;
        return w;
    };
    Own gamma(g), lin(g);
    REQUIRE_MESSAGE(gamma.ok, gamma.error);
    REQUIRE_MESSAGE(lin.ok, lin.error);
    auto wg = build(false), wl = build(true);
    const Image a = gamma.draw(g, *wg), b = lin.draw(g, *wl);
    // The unlit row is the picked colour either way (its round trip through linear light is exact within a rounding step).
    const Color unlit{0.9f, 0.6f, 0.3f, 1};
    CHECK(std::fabs(at(b, -112, -36).r - unlit.r) < 0.03f);
    CHECK(std::fabs(at(b, -112, -36).g - unlit.g) < 0.03f);
    CHECK(std::fabs(at(b, -112, -36).b - unlit.b) < 0.03f);
    // The lit one is shaded, and the star out of the lamp's reach sees only the ambient light: 0.15 as picked, 0.0196 in linear
    // light, shown as 0.15 again after the encode, times the colour (0.9 -> 0.787 linear): the multiplication happens in linear light.
    CHECK(at(b, -112, 36).r > 0.2f);
    const Color star = at(b, 112, 36);
    const float amb = render::srgb_to_linear(0.15f), tint = render::srgb_to_linear(0.9f);
    CHECK(star.r == doctest::Approx(render::linear_to_srgb(amb * tint)).epsilon(0.08));
    CHECK(worst_error(a, b) > 0.03);  // not the same picture
    if (lin.gpu().scene_format() == SG_PIXELFORMAT_RGBA16F || lin.gpu().scene_format() == SG_PIXELFORMAT_SRGB8A8)
        expect_golden(b, "2d_lit_shapes_linear");
}

TEST_CASE("color space: a lit 3D scene in linear light (golden) differs from the gamma one") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    Own gamma(g), lin(g);
    REQUIRE_MESSAGE(gamma.ok, gamma.error);
    REQUIRE_MESSAGE(lin.ok, lin.error);
    World wg, wl;
    primitives_3d(wg);
    primitives_3d(wl);
    linear(wl);
    const Image a = gamma.draw(g, wg), b = lin.draw(g, wl);
    CHECK(lin.gpu().linear());
    CHECK_FALSE(gamma.gpu().linear());
    CHECK(worst_error(a, b) > 0.05);
    CHECK(b.pixel(160, 2).b > 0.3f);  // the sky is still a sky
    if (lin.gpu().scene_format() == SG_PIXELFORMAT_RGBA16F || lin.gpu().scene_format() == SG_PIXELFORMAT_SRGB8A8)
        expect_golden(b, "3d_primitives_linear");
}

TEST_CASE("color space: an unlit mesh and the clear colour keep their picked colour in a linear scene") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    Own lin(g);
    REQUIRE_MESSAGE(lin.ok, lin.error);
    World w;
    linear(w);
    add_camera3d(w, {0, 0, 4}, {0, 0, 0});
    w.settings().skyColor = Color{0.25f, 0.5f, 0.75f, 1};
    w.settings().horizonColor = Color{0.25f, 0.5f, 0.75f, 1};
    Entity cube = add_mesh(w, "cube", {0, 0, 0}, Color{0.5f, 0.5f, 0.5f, 1});
    w.get<MeshRenderer>(cube)->unlit = true;
    const Image img = lin.draw(g, w);
    const Color c = img.pixel(160, 90);
    CHECK(c.r == doctest::Approx(0.5f).epsilon(0.03));
    CHECK(c.g == doctest::Approx(0.5f).epsilon(0.03));
    const Color sky = img.pixel(3, 3);  // the sky is an authored colour too
    CHECK(sky.r == doctest::Approx(0.25f).epsilon(0.05));
    CHECK(sky.g == doctest::Approx(0.5f).epsilon(0.05));
    CHECK(sky.b == doctest::Approx(0.75f).epsilon(0.05));
}

TEST_CASE("color space: a gradient on the 8-bit scene target keeps the ramp, and the float one agrees") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    save(ramp(), "assets/lin_ramp.png");
    auto build = [&]() {
        auto w = std::make_unique<World>();
        camera(*w);
        linear(*w);
        Entity e = make(*w, "ramp", {0, 0, 0});
        auto& sp = w->add<Sprite>(e);
        sp.texture = "assets/lin_ramp.png";
        sp.size = {256, 40};
        sp.pixelArt = true;  // one texel per picture pixel: pixel 32 + i shows texel i
        return w;
    };
    Own eight(g, "rgba8");  // the linear chain without the float formats: SRGB8A8, else plain RGBA8
    Own best(g);
    REQUIRE_MESSAGE(eight.ok, eight.error);
    REQUIRE_MESSAGE(best.ok, best.error);
    auto w8 = build(), wb = build();
    const Image img8 = eight.draw(g, *w8), imgBest = best.draw(g, *wb);
    CHECK_FALSE(eight.r.hdr_scene());
    const sg_pixel_format f8 = eight.gpu().scene_format();
    CHECK((f8 == SG_PIXELFORMAT_SRGB8A8 || f8 == SG_PIXELFORMAT_RGBA8));
    INFO("the 8-bit scene format is " << std::string(render::pixel_format_name(f8)));
    double prev = -1;
    for (int i = 0; i < 256; i += 5) {  // never darker than the pixel before it
        const double v = img8.pixel(32 + i, 90).r;
        CHECK(v >= prev - 0.004);
        prev = v;
    }
    if (f8 == SG_PIXELFORMAT_SRGB8A8) {
        // The GPU encodes what is written and decodes what is read: the darks keep their precision and the ramp comes out as it went in.
        for (int i : {3, 8, 16, 32, 64, 100, 128, 200, 250}) {
            CAPTURE(i);
            CHECK(img8.pixel(32 + i, 90).r == doctest::Approx(float(i) / 255.0f).epsilon(0.02));
            CHECK(imgBest.pixel(32 + i, 90).r == doctest::Approx(float(i) / 255.0f).epsilon(0.02));
        }
        expect_golden(img8, "2d_linear_gradient_srgb8");
    } else {
        // Plain RGBA8 holds linear light in 8 bits: the darks band, the lights are right.
        CHECK(img8.pixel(32 + 200, 90).r == doctest::Approx(200.0f / 255.0f).epsilon(0.03));
        MESSAGE("this GPU has no sRGB render target: the linear scene is plain RGBA8 and bands in the darks");
    }
}

TEST_CASE(
    "color space: R11G11B10 is the float scene target when RGBA16F is not available, and draws the same picture") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    const sg_pixelformat_info packed = sg_query_pixelformat(SG_PIXELFORMAT_RG11B10F);
    const bool isGl = sg_query_backend() == SG_BACKEND_GLCORE || sg_query_backend() == SG_BACKEND_GLES3;
    const bool expected = packed.render && packed.filter && (packed.blend || isGl);
    Own gamma(g, "r11g11b10");
    Own packedRenderer(g, "r11g11b10");
    REQUIRE_MESSAGE(packedRenderer.ok, packedRenderer.error);
    // A gamma scene never uses it (it has no alpha and a 6-bit mantissa); a linear one does when the GPU has it.
    World wg;
    camera(wg);
    rect(wg, {0, 0, 0}, Color{0.5f, 0.5f, 0.5f, 1});
    gamma.draw(g, wg);
    CHECK(gamma.gpu().scene_format() != SG_PIXELFORMAT_RG11B10F);
    World w;
    camera(w);
    linear(w);
    rect(w, {-60, 0, 0}, Color{0.5f, 0.5f, 0.5f, 1});
    rect(w, {0, 0, 0}, Color{1, 1, 1, 0.5f});
    rect(w, {60, 0, 0}, Color{0.9f, 0.6f, 0.3f, 1});
    const Image img = packedRenderer.draw(g, w);
    CHECK((packedRenderer.gpu().scene_format() == SG_PIXELFORMAT_RG11B10F) == expected);
    if (expected) {
        CHECK(packedRenderer.r.hdr_scene());  // a float target: values above white reach the post pass
        CHECK_FALSE(packedRenderer.gpu().scene_has_alpha());
    } else {
        MESSAGE("this GPU cannot render to R11G11B10 with blending: the selection is checked as 'not used'");
    }
    // Whatever the format, the picture is the one of the best format within the precision of the target.
    Own best(g);
    REQUIRE_MESSAGE(best.ok, best.error);
    World wb;
    camera(wb);
    linear(wb);
    rect(wb, {-60, 0, 0}, Color{0.5f, 0.5f, 0.5f, 1});
    rect(wb, {0, 0, 0}, Color{1, 1, 1, 0.5f});
    rect(wb, {60, 0, 0}, Color{0.9f, 0.6f, 0.3f, 1});
    CHECK(worst_error(img, best.draw(g, wb)) < 0.04);
    CHECK(at(img, 0, 0).r == doctest::Approx(0.7354f).epsilon(0.04));
}

TEST_CASE("color space: colour textures are made sRGB in a linear scene, with the shader as the fall-back, data "
          "textures stay as they were") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    save(solid(8, 8, 100), "assets/lin_tex_a.png");
    save(solid(8, 8, 150), "assets/lin_tex_b.png");
    const sg_pixelformat_info srgb = sg_query_pixelformat(SG_PIXELFORMAT_SRGB8A8);
    const bool gpuDecodes = srgb.sample && srgb.filter;
    Own r(g);
    REQUIRE_MESSAGE(r.ok, r.error);
    auto texture_format = [&](const char* path) {
        const Json report = r.r.asset_report();  // kept alive for the loop
        for (const Json& t : report["textures"])
            if (t["path"] == path) return t["format"].get<std::string>();
        return std::string("missing");
    };
    // The format a texture is made in now, for the colour spaces: (gamma, RGBA8) and (linear, SRGB8A8 when the GPU decodes it).
    CHECK(r.gpu().texture_format(SG_PIXELFORMAT_RGBA8) == SG_PIXELFORMAT_RGBA8);  // a gamma scene
    r.gpu().set_linear(true);
    CHECK(r.gpu().texture_format(SG_PIXELFORMAT_RGBA8) == (gpuDecodes ? SG_PIXELFORMAT_SRGB8A8 : SG_PIXELFORMAT_RGBA8));
    CHECK(r.gpu().texture_format(SG_PIXELFORMAT_RG11B10F) == SG_PIXELFORMAT_RG11B10F);  // nothing else is converted
    r.gpu().set_linear(false);

    // A texture first used by a gamma scene is RGBA8 (data and colour alike); one first used by a linear scene is SRGB8A8.
    auto sprite_world = [&](bool lin, const char* path) {
        auto w = std::make_unique<World>();
        camera(*w);
        linear(*w, lin);
        Entity e = make(*w, "s", {0, 0, 0});
        auto& sp = w->add<Sprite>(e);
        sp.texture = path;
        sp.size = {40, 40};
        sp.pixelArt = true;
        return w;
    };
    auto wa = sprite_world(false, "assets/lin_tex_a.png");
    const Image a1 = r.draw(g, *wa);
    CHECK(texture_format("assets/lin_tex_a.png") == "RGBA8");
    auto wb = sprite_world(true, "assets/lin_tex_b.png");
    const Image b1 = r.draw(g, *wb);
    CHECK(texture_format("assets/lin_tex_b.png") == std::string(gpuDecodes ? "SRGB8A8" : "RGBA8"));
    // One asset, both colour spaces: the format it was made in does not decide how it looks.
    linear(*wa);  // the gamma-made texture is now drawn by a linear scene: the shader decodes it
    const Image a2 = r.draw(g, *wa);
    linear(*wb, false);  // the sRGB-made one by a gamma scene: the shader encodes what the GPU decoded
    const Image b2 = r.draw(g, *wb);
    CHECK(texture_format("assets/lin_tex_a.png") == "RGBA8");  // not made again
    CHECK(texture_format("assets/lin_tex_b.png") == std::string(gpuDecodes ? "SRGB8A8" : "RGBA8"));
    CHECK(at(a1, 0, 0).r == doctest::Approx(100.0f / 255.0f).epsilon(0.03));
    CHECK(at(a2, 0, 0).r == doctest::Approx(100.0f / 255.0f).epsilon(0.03));
    CHECK(at(b1, 0, 0).r == doctest::Approx(150.0f / 255.0f).epsilon(0.03));
    CHECK(at(b2, 0, 0).r == doctest::Approx(150.0f / 255.0f).epsilon(0.03));
}

TEST_CASE("color space: switching it at run time keeps the textures and does not leak GPU images; gamma comes back "
          "byte for byte") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    save(solid(16, 16, 90), "assets/lin_switch.png");
    Own r(g);
    REQUIRE_MESSAGE(r.ok, r.error);
    World w;
    primitives_3d(w);
    Entity s = make(w, "sprite", {0, 0, 0});
    auto& sp = w.add<Sprite>(s);
    sp.texture = "assets/lin_switch.png";
    sp.size = {20, 20};
    const Image first = r.draw(g, w);
    const bool wasEnabled = sg_stats_enabled();
    sg_enable_stats();
    auto live_images = [] {
        const sg_total_resource_stats t = sg_query_stats().total.images;
        return std::int64_t(t.inited) - std::int64_t(t.uninited);
    };
    auto cycle = [&] {
        linear(w);
        const Image lin = r.draw(g, w);
        linear(w, false);
        const Image back = r.draw(g, w);
        return std::make_pair(lin, back);
    };
    cycle();  // the first round makes whatever the other colour space needs (pipelines, the sRGB images, the targets)
    const std::int64_t images = live_images();
    const std::uint64_t texBytes = r.r.texture_bytes();
    const std::size_t textures = r.r.asset_report()["textures"].size();
    Image lin, back;
    for (int i = 0; i < 4; ++i) std::tie(lin, back) = cycle();
    CHECK(live_images() == images);          // no image made and kept, none made twice
    CHECK(r.r.texture_bytes() == texBytes);  // the textures are not made again
    CHECK(r.r.asset_report()["textures"].size() == textures);
    CHECK(same_bytes(first, back));         // gamma after linear is exactly gamma before it
    CHECK(worst_error(first, lin) > 0.03);  // and linear is another picture
    if (!wasEnabled) sg_disable_stats();
}

TEST_CASE("color space: a gamma scene is drawn exactly as before (no conversion reaches a shader)") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    // The goldens of every other case are the proof in general; this one pins the flags: the shared renderer, in a gamma scene, makes
    // no sRGB texture and an RGBA8 or RGBA16F scene target, whatever the GPU can do.
    World w;
    camera(w);
    rect(w, {0, 0, 0}, Color{0.5f, 0.25f, 0.75f, 0.5f});
    const Image img = g.draw(w);
    render::Gpu& gpu = *render::renderer_gpu(g.renderer);
    CHECK_FALSE(gpu.linear());
    CHECK((gpu.scene_format() == SG_PIXELFORMAT_RGBA16F || gpu.scene_format() == SG_PIXELFORMAT_RGBA8));
    CHECK(gpu.texture_format(SG_PIXELFORMAT_RGBA8) == SG_PIXELFORMAT_RGBA8);
    // 50% of (0.5, 0.25, 0.75) over black, on the sRGB values.
    CHECK(at(img, 0, 0).r == doctest::Approx(0.25f).epsilon(0.03));
    CHECK(at(img, 0, 0).g == doctest::Approx(0.125f).epsilon(0.03));
    CHECK(at(img, 0, 0).b == doctest::Approx(0.375f).epsilon(0.03));
}

TEST_CASE(
    "color space: the image the editor viewport reads is encoded in a linear scene and unchanged in a gamma one") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    World w;
    camera(w);
    rect(w, {0, 0, 0}, Color{0.5f, 0.5f, 0.5f, 1},
         {400, 300});  // fills the picture: the middle pixel is the whole picture
    // The middle pixel (red byte) of the image behind game_target_image_id(), the one ImGui shows. Only an 8-bit image can be read back.
    auto viewed = [](Own& o) {
        const std::uint32_t id = o.r.game_target_image_id();
        REQUIRE(id != 0);
        CHECK(o.r.game_target_view_id() != 0);
        sg_image image{};
        image.id = id;
        std::vector<std::uint8_t> px;
        std::string err;
        const int tw = o.r.target_width(), th = o.r.target_height();
        REQUIRE_MESSAGE(render::readback_rgba8(image, tw, th, px, &err), err);
        return int(px[(std::size_t(th / 2) * std::size_t(tw) + std::size_t(tw / 2)) * 4]);
    };
    auto shot_byte = [](const Image& img) { return int(std::lround(img.pixel(160, 90).r * 255.0f)); };
    auto live_images = [] {
        const sg_total_resource_stats t = sg_query_stats().total.images;
        return std::int64_t(t.inited) - std::int64_t(t.uninited);
    };
    const bool wasEnabled = sg_stats_enabled();
    sg_enable_stats();

    SUBCASE("an 8-bit scene: gamma reads the game image itself, linear reads the encoded copy, gamma again frees it") {
        Own r(g, "rgba8");
        REQUIRE_MESSAGE(r.ok, r.error);
        r.r.set_editor_view(true);
        const Image gammaShot = r.draw(g, w);
        const int gammaByte = viewed(r);
        CHECK(gammaByte == shot_byte(gammaShot));
        linear(w);
        r.draw(g, w);  // the first round makes whatever the other colour space needs
        linear(w, false);
        r.draw(g, w);
        const std::int64_t images = live_images();
        const std::uint32_t gammaId = r.r.game_target_image_id();  // gamma: the game image itself, no copy was made

        linear(w);
        const Image linShot = r.draw(g, w);
        CHECK(r.r.game_target_image_id() != gammaId);
        const int linByte = viewed(r);
        CHECK(std::abs(linByte - shot_byte(linShot)) <= 1);
        CHECK(linByte >= 126);  // the colour as picked

        linear(w, false);
        r.draw(g, w);
        CHECK(viewed(r) == gammaByte);
        CHECK(live_images() == images);  // the copy is gone, nothing else was made
        // set_editor_view(false) frees the copy in a linear scene too (a game never makes it).
        linear(w);
        r.draw(g, w);
        const std::int64_t withCopy = live_images();
        r.r.set_editor_view(false);
        CHECK(live_images() == withCopy - 1);  // the copy's one image
        r.draw(g, w);
        CHECK(live_images() == withCopy - 1);  // and it is not made again
    }
    SUBCASE(
        "the float scene: the game image holds linear light (too dark to show), the viewport reads the encoded copy") {
        Own r(g);
        REQUIRE_MESSAGE(r.ok, r.error);
        r.r.set_editor_view(true);
        linear(w);
        const Image linShot = r.draw(g, w);
        const int linByte = viewed(r);  // an RGBA8 copy: it can be read back, the float game image cannot
        CHECK(std::abs(linByte - shot_byte(linShot)) <= 1);
        CHECK(linByte >= 126);
    }
    if (!wasEnabled) sg_disable_stats();
}
