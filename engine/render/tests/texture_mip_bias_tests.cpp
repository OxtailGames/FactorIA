// M76-P4b: the texture LOD bias of the temporal passes (Renderer::Impl::mip_bias in src/renderer.cpp, fa_mip_bias in
// shaders/mesh_common.glsl, docs/UPSCALING.md "Texture mip bias"). The value the renderer gives a camera is checked through
// RendererTestAccess::last_mip_bias; the effect on the picture with a 1-texel checker on a plane seen at a grazing angle: the checker has all
// its contrast at mip 0 and is grey from mip 1 on, so a finer level shows as more contrast far away. Tests stay 10x away from every cap
// and compare contrast ratios, not exact pixels (they run on every backend).
#include "fa/core/engine_version.h"
#include "test_util.h"

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <filesystem>
#include <fstream>
#include <iterator>
#include <limits>
#include <string>

#include "postprocess.h"
#include "render_internal.h"
#include "renderer_test_access.h"
#include "fa/core/fs.h"
#include "fa/core/image.h"
#include "fa/render/dynamic_resolution.h"
#include "fa/render/upscaler.h"

using namespace fa;
using namespace fa::test;
using render::UpscalerMode;
using render::UpscalerSettings;

namespace {

constexpr int kOutW = 320, kOutH = 180;

struct Own {
    Gfx& g;
    Renderer r;
    bool ok = false;
    std::string error;
    explicit Own(Gfx& gx) : g(gx) {
        RendererDesc d;
        d.designWidth = kOutW;
        d.designHeight = kOutH;
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
    Image draw(World& w, int n) {
        frame(w, n);
        Image img;
        std::string err;
        const bool captured = r.capture(img, &err);
        INFO("capture error: " << err);
        REQUIRE(captured);
        return img;
    }
    void upscale(float scale, UpscalerMode mode = UpscalerMode::Temporal) {
        r.set_render_scale(scale);
        r.set_upscale_stage(true);
        UpscalerSettings u;
        u.mode = mode;
        r.set_upscaler(u);
    }
    float bias() {
        const std::vector<float> all = RendererTestAccess::last_mip_bias(r);
        REQUIRE(all.size() == 1);
        return all[0];
    }
};

int phys(int out, float scale) { return std::max(1, int(std::lround(double(out) * double(scale)))); }
double ratio_bias(float scale) { return std::log2(double(phys(kOutW, scale)) / double(kOutW)); }

// A texel-wide checker (mip 0 is black and white, every mip above it is the grey average) on a long plane seen from just above it.
Image texel_checker() {
    Image img;
    img.width = img.height = 128;
    img.rgba.resize(std::size_t(img.width) * std::size_t(img.height) * 4);
    for (int y = 0; y < img.height; ++y)
        for (int x = 0; x < img.width; ++x) {
            const std::uint8_t v = ((x + y) % 2 == 0) ? 255 : 0;
            std::uint8_t* p = &img.rgba[(std::size_t(y) * std::size_t(img.width) + std::size_t(x)) * 4];
            p[0] = p[1] = p[2] = v;
            p[3] = 255;
        }
    return img;
}

struct Ground {
    World w;
    Entity cam = kNullEntity, plane = kNullEntity;
    Ground() {
        REQUIRE(save_png(texel_checker(), "assets/mip_bias_checker.png").ok());
        cam = make(w, "cam", {0, 1.0f, 0});
        auto& c = w.add<Camera>(cam);
        c.projection = Projection::Perspective;
        c.fov = 60.0f;
        c.clearColor = Color{0, 0, 0, 1};
        w.settings().skyColor = w.settings().horizonColor = Color{0, 0, 0, 1};
        plane = make(w, "ground", {0, 0, -60});
        w.get<Transform>(plane)->scale = {60.0f, 1.0f, 120.0f};
        auto& m = w.add<MeshRenderer>(plane);
        m.mesh = "plane";
        m.texture = "assets/mip_bias_checker.png";
        m.color = Color::white();
        m.unlit = true;
        m.uvScale = {60.0f, 120.0f};
    }
    PostProcess& post() { return camera_post(w, cam); }
    void taa(float offset) {
        post().temporalAAEnabled = true;
        post().temporalAAMipBias = offset;
    }
};

// The mean distance of the grey of the lower half of the picture (the ground) from the mean grey of the checker: how much of the checker's
// contrast the picture keeps. Mip 1 and above are flat grey, so it falls with the level that is read.
double contrast(const Image& img) {
    double sum = 0;
    int n = 0;
    for (int y = img.height / 2 + 4; y < img.height; ++y)
        for (int x = 0; x < img.width; ++x) {
            sum += std::fabs(double(img.pixel(x, y).r) - 0.5);
            ++n;
        }
    return n > 0 ? sum / n : 0.0;
}

}  // namespace

TEST_CASE("mip bias: the temporal upscaler gives log2(render / output) plus the offset, TAA alone the offset, "
          "everything else 0") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    Own own(g);
    REQUIRE_MESSAGE(own.ok, own.error);
    Ground s;

    // The temporal upscaler at half size, a camera without the effect: the effect's default offset (-0.5).
    own.upscale(0.5f);
    own.frame(s.w, 2);
    REQUIRE(own.r.effective_upscaler_mode() == UpscalerMode::Temporal);
    CHECK(own.bias() == doctest::Approx(-1.5f).epsilon(0.001));
    CHECK(own.bias() == doctest::Approx(float(ratio_bias(0.5f) - 0.5)).epsilon(0.001));

    // The camera's own offset, with the effect on (-2 is the sharpest the field allows, 0 the pure ratio).
    s.taa(-1.0f);
    own.frame(s.w, 2);
    CHECK(own.bias() == doctest::Approx(-2.0f).epsilon(0.001));
    s.taa(0.0f);
    own.frame(s.w);
    CHECK(own.bias() == doctest::Approx(-1.0f).epsilon(0.001));
    s.taa(-2.0f);
    own.frame(s.w);
    CHECK(own.bias() == doctest::Approx(-3.0f).epsilon(0.001));
    s.post().temporalAAMipBias =
        std::numeric_limits<float>::quiet_NaN();  // never reaches the shader: the default offset
    own.frame(s.w);
    CHECK(own.bias() == doctest::Approx(-1.5f).epsilon(0.001));
    s.post().temporalAAMipBias = -50.0f;  // clamped to the field's -2, and the sum never goes under -4
    own.frame(s.w);
    CHECK(own.bias() == doctest::Approx(-3.0f).epsilon(0.001));

    // Native size: the upscaler's own resolve is not drawn, the ratio is 0; its offset is the camera's.
    own.upscale(1.0f);
    s.taa(-0.5f);
    own.frame(s.w, 2);
    CHECK(own.bias() == doctest::Approx(-0.5f).epsilon(0.001));

    // Off: stretch draws no jitter and no bias, at any scale, whatever the field says.
    own.upscale(0.5f, UpscalerMode::Stretch);
    s.taa(-2.0f);
    s.post().temporalAAEnabled = false;
    own.frame(s.w, 2);
    CHECK(own.bias() == 0.0f);
    own.upscale(1.0f, UpscalerMode::Stretch);
    own.frame(s.w, 2);
    CHECK(own.bias() == 0.0f);
}

TEST_CASE(
    "mip bias: the temporal antialiasing alone at the output size takes the offset, and nothing without the effect") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    Own own(g);
    REQUIRE_MESSAGE(own.ok, own.error);
    Ground s;
    own.frame(s.w, 2);
    CHECK(own.bias() == 0.0f);  // no effect: no jitter
    s.taa(-0.5f);
    own.frame(s.w, 2);
    CHECK(own.bias() == doctest::Approx(-0.5f).epsilon(0.001));
    s.taa(-1.25f);
    own.frame(s.w);
    CHECK(own.bias() == doctest::Approx(-1.25f).epsilon(0.001));
    s.taa(0.0f);
    own.frame(s.w);
    CHECK(own.bias() == 0.0f);
    s.post().temporalAAEnabled = false;
    own.frame(s.w);
    CHECK(own.bias() == 0.0f);

    // A jitter a test forces is not a temporal pass: no bias.
    RendererTestAccess::force_jitter(own.r, 8);
    own.frame(s.w);
    CHECK(own.bias() == 0.0f);
    RendererTestAccess::force_jitter(own.r, 0);
}

TEST_CASE("mip bias: it follows the render scale, window.renderScale steps and the dynamic resolution controller") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    Own own(g);
    REQUIRE_MESSAGE(own.ok, own.error);
    Ground s;
    own.upscale(1.0f);
    s.taa(-0.5f);
    float last = 1.0f;
    for (float scale : {0.75f, 0.625f, 0.5f, 0.25f, 0.5f, 0.75f, 1.0f}) {
        own.r.set_render_scale(scale);
        own.frame(s.w);
        const double expected = std::max(-4.0, ratio_bias(scale) - 0.5);
        INFO("scale " << scale);
        CHECK(own.bias() == doctest::Approx(float(expected)).epsilon(0.001));
        last = own.bias();
    }
    CHECK(last == doctest::Approx(-0.5f).epsilon(0.001));

    // The controller steps down under load (every step is a new drawn scale over the base one) and the bias goes with each step.
    render::DynamicResolutionSettings ds;
    ds.enabled = true;
    ds.targetMs = 16.7;
    ds.minScale = 0.5f;
    ds.maxScale = 1.0f;
    render::DynamicResolutionController c;
    c.configure(ds);
    own.upscale(1.0f);
    int steps = 0;
    float firstBias = 0.0f, lowestBias = 0.0f;
    for (int i = 0; i < 60 * 40 && steps < 4; ++i) {
        if (c.update(40.0 * double(c.scale()), 1000.0 / 60.0, 16.7, true)) {
            own.r.set_render_scale(c.scale(), 1.0f);
            own.frame(s.w);
            const double expected = ratio_bias(own.r.render_scale()) - 0.5;
            CHECK(own.bias() == doctest::Approx(float(expected)).epsilon(0.001));
            if (steps == 0) firstBias = own.bias();
            lowestBias = own.bias();
            ++steps;
        }
    }
    REQUIRE(steps >= 2);
    CHECK(firstBias < -0.5f);
    CHECK(lowestBias < firstBias);
}

// A cube that fills the picture and paints the bias the frame gave it (materials/mipbias.material.json: grey = -fa_mip_bias / 4), against a
// plain cube of that grey drawn by a renderer with no temporal pass: the value the shader read is the one the renderer computed.
// The fixture materials of tests/data/materials copied into the test project, only the one of this file (its twins get this build's engine
// version; the template hash stays, so a change of the template without regenerating the twins fails loudly).
void install_mipbias_material() {
    namespace sfs = std::filesystem;
    const sfs::path src = sfs::path(FA_RENDER_DATA_DIR) / "materials";
    for (const auto& e : sfs::recursive_directory_iterator(src)) {
        if (!e.is_regular_file() || e.path().filename().generic_string().find("mipbias") != 0) continue;
        std::ifstream in(e.path(), std::ios::binary);
        std::string bytes((std::istreambuf_iterator<char>(in)), std::istreambuf_iterator<char>());
        if (e.path().extension() == ".shader") {
            Json twin = Json::parse(bytes);
            twin["engine"] = FA_ENGINE_VERSION;
            bytes = twin.dump();
        }
        REQUIRE(fs::write_bytes(sfs::relative(e.path(), src).generic_string(), bytes.data(), bytes.size()).ok());
    }
}

struct Paint {
    World w;
    Entity cam = kNullEntity, wall = kNullEntity;
    explicit Paint(const char* material, Color color = Color::white()) {
        cam = make(w, "cam", {0, 0, 10});
        auto& c = w.add<Camera>(cam);
        c.projection = Projection::Perspective;
        c.fov = 60.0f;
        c.clearColor = Color{0, 0, 0, 1};
        w.settings().skyColor = w.settings().horizonColor = Color{0, 0, 0, 1};
        wall = make(w, "wall", {0, 0, 0});
        w.get<Transform>(wall)->scale = {60.0f, 40.0f, 1.0f};
        auto& m = w.add<MeshRenderer>(wall);
        m.mesh = "cube";
        m.color = color;
        m.unlit = true;
        m.material = material;
    }
    PostProcess& post() { return camera_post(w, cam); }
};

float grey_of(const Image& img) { return img.pixel(kOutW / 2, kOutH / 2).r; }

TEST_CASE("mip bias: fa_mip_bias reaches the fragment shader of a mesh material with the value of the camera, and 0 "
          "when nothing is accumulated") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    install_mipbias_material();
    // The grey a plain cube of value v has on this backend (the colour space and the encoding are the backend's).
    auto reference = [&](float v) {
        Own own(g);
        REQUIRE_MESSAGE(own.ok, own.error);
        Paint p("", Color{v, v, v, 1});
        return grey_of(own.draw(p.w, 2));
    };
    const float tol = 3.0f / 255.0f;

    Own own(g);
    REQUIRE_MESSAGE(own.ok, own.error);
    Paint s("materials/mipbias.material.json");
    CHECK(grey_of(own.draw(s.w, 2)) == doctest::Approx(reference(0.0f)).epsilon(tol));  // nothing accumulated: 0

    own.upscale(0.5f);  // temporal at half size, the default offset: -1.5
    s.post().temporalAAEnabled = false;
    Image half = own.draw(s.w, 6);
    REQUIRE(own.r.effective_upscaler_mode() == UpscalerMode::Temporal);
    CHECK(own.bias() == doctest::Approx(-1.5f).epsilon(0.001));
    CHECK(grey_of(half) == doctest::Approx(reference(0.375f)).epsilon(tol));

    s.post().temporalAAEnabled = true;   // the camera's own offset
    s.post().temporalAAMipBias = -1.0f;  // -2.0
    CHECK(grey_of(own.draw(s.w, 6)) == doctest::Approx(reference(0.5f)).epsilon(tol));
    own.r.set_render_scale(0.75f);  // -0.415 - 1.0, a render scale step
    CHECK(grey_of(own.draw(s.w, 6)) ==
          doctest::Approx(reference(float(0.25 * -(ratio_bias(0.75f) - 1.0)))).epsilon(tol));

    own.upscale(0.5f, UpscalerMode::Stretch);  // stretch: the effect is off, no bias
    s.post().temporalAAEnabled = false;
    CHECK(grey_of(own.draw(s.w, 3)) == doctest::Approx(reference(0.0f)).epsilon(tol));
}

TEST_CASE("mip bias: a frame with no temporal pass is the same picture bit for bit, whatever the offset says") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    Image plain, withField;
    {
        Own own(g);
        REQUIRE_MESSAGE(own.ok, own.error);
        Ground s;
        plain = own.draw(s.w, 3);
    }
    {
        Own own(g);
        REQUIRE_MESSAGE(own.ok, own.error);
        Ground s;
        s.post().temporalAAMipBias = -2.0f;  // the effect is off: never read
        withField = own.draw(s.w, 3);
    }
    CHECK(plain.rgba == withField.rgba);
    // Stretch at half size and no temporal effect: the same picture with the offset at -2 or at 0 (the upscaler is off, so is the bias).
    Image a, b;
    for (float offset : {-2.0f, 0.0f}) {
        Own own(g);
        REQUIRE_MESSAGE(own.ok, own.error);
        Ground s;
        own.upscale(0.5f, UpscalerMode::Stretch);
        s.post().temporalAAMipBias = offset;
        (offset < 0 ? a : b) = own.draw(s.w, 3);
    }
    CHECK(a.rgba == b.rgba);
}

TEST_CASE("mip bias: the accumulated picture of an inclined plane keeps more of a texel-wide checker with the sharpest "
          "offset") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    // The temporal antialiasing at the output size, 32 frames. The texture is grey from mip 1 on, so the contrast of the picture falls with
    // the level that is read; the bias is a small part of what the resolve does to such a texture, so the margin is small. The temporal
    // upscaler has no such check: the contrast of its picture hardly moved with the offset here (the same to 8 digits at a quarter of the
    // size), so no margin can be asked of it; the cases above hold its exact bias and the value the shader reads.
    auto contrast_of = [&](float offset, float scale) {
        Own own(g);
        REQUIRE_MESSAGE(own.ok, own.error);
        Ground s;
        if (scale < 1.0f) own.upscale(scale);
        s.taa(offset);
        return contrast(own.draw(s.w, 32));
    };
    const double sharp = contrast_of(-2.0f, 1.0f), zero = contrast_of(0.0f, 1.0f);
    INFO("taa: sharp " << sharp << " zero " << zero);
    CHECK(sharp > zero * 1.05);
}
