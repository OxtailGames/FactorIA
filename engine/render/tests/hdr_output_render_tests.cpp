// M71: the HDR display output on the GPU, without an HDR display: the tests force what update_output() would answer
// (render::renderer_force_output) and read the picture back as floats, as the final target holds it (post.glsl's tonemap above
// paper white) and as present() encodes it (blit.glsl: scRGB, HDR10 PQ, EDR extended linear sRGB). The expected values come from
// src/hdr_encode.h, the same maths on the CPU. A GPU that cannot draw or read back an RGBA16F image skips them with a message.
#include "test_util.h"

#include <algorithm>
#include <cmath>
#include <string>
#include <vector>

#include "hdr_encode.h"
#include "render_internal.h"

using namespace fa;
using namespace fa::test;

namespace {

float srgb_to_linear(float c) {
    c = std::max(c, 0.0f);
    return c <= 0.04045f ? c / 12.92f : std::pow((c + 0.055f) / 1.055f, 2.4f);
}
float linear_to_srgb(float c) {
    c = std::max(c, 0.0f);
    return c <= 0.0031308f ? c * 12.92f : 1.055f * std::pow(c, 1.0f / 2.4f) - 0.055f;
}

HdrOutputInfo forced(HdrEncoding e, float headroom, float paperWhite = 200.0f) {
    HdrOutputInfo i;
    i.requested = true;
    i.active = e != HdrEncoding::Sdr;
    i.encoding = e;
    i.headroom = headroom;
    i.paperWhiteNits = paperWhite;
    return i;
}

// A flat colour over the whole picture and, optionally, a white HUD box at (20..60, 10..30).
struct Flat {
    World world;
    Entity cam;
    explicit Flat(float v, bool hud = false) {
        cam = make(world, "cam");
        world.add<Camera>(cam).clearColor = Color{v, v, v, 1};
        if (hud) {
            Entity box = make(world, "hud-box", {20, 10, 0});
            auto& b = world.add<Shape2D>(box);
            b.shape = ShapeType::Rectangle;
            b.size = {40, 20};
            b.color = Color::white();
            b.space = RenderSpace::Screen;
            b.pivot = {0, 1};
        }
    }
    PostProcess& post() {
        PostProcess* p = world.get<PostProcess>(cam);
        return p ? *p : world.add<PostProcess>(cam);
    }
};

struct Floats {
    std::vector<float> px;
    int w = 0;
    float at(int x, int y, int c) const {
        return px[(std::size_t(y) * std::size_t(w) + std::size_t(x)) * 4 + std::size_t(c)];
    }
};

// The renderer of the test binary, its output forced for the life of the object and set back after.
struct Forced {
    Gfx& g;
    Forced(Gfx& gx, const HdrOutputInfo& info) : g(gx) { render::renderer_force_output(g.renderer, &info); }
    ~Forced() { render::renderer_force_output(g.renderer, nullptr); }
    Forced(const Forced&) = delete;
    Forced& operator=(const Forced&) = delete;
};

// Whether this GPU holds the display picture in floats and can read RGBA16F back; the message says why not.
bool float_path(Gfx& g) {
    Flat warm(0.5f);  // a frame, so there is a picture to read back
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

// The last frame as floats; `shot` is its capture (the size of the picture).
Floats read(Gfx& g, const Image& shot, bool present) {
    Floats f;
    std::string err;
    const bool ok = render::renderer_read_floats(g.renderer, present, f.px, &err);
    INFO("read-back error: " << err);
    REQUIRE(ok);
    f.w = shot.width;
    REQUIRE(f.px.size() == std::size_t(shot.width) * std::size_t(shot.height) * 4);
    return f;
}

constexpr float kStep = 1.0f / 255.0f;

}  // namespace

TEST_CASE("hdr output: the final pass tonemaps above paper white up to the headroom, as hdr_encode.h computes") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    if (!float_path(g)) return;
    const TonemapMode modes[] = {TonemapMode::None, TonemapMode::Neutral, TonemapMode::Aces, TonemapMode::Agx,
                                 TonemapMode::Reinhard};
    constexpr float H = 4.0f;
    Forced f(g, forced(HdrEncoding::Edr, H));
    for (int m = 0; m < 5; ++m) {
        for (float ev : {-1.0f, 0.0f, 2.0f, 4.0f}) {
            CAPTURE(m);
            CAPTURE(ev);
            Flat s(1.0f);
            s.post().exposureEnabled = true;
            s.post().exposureEv = ev;
            s.post().tonemapEnabled = true;
            s.post().tonemapMode = modes[m];
            const Image shot = g.draw(s.world);
            const Floats fin = read(g, shot, false);
            const float light = std::exp2(ev);  // a gamma scene: clear colour 1.0 is linear 1.0
            const float expected = linear_to_srgb(render::tonemap_hdr({light, light, light}, m, H)[0]);
            const float got = fin.at(160, 90, 0);
            // The dither (one 8-bit step) and half precision.
            CHECK(std::fabs(got - expected) <= kStep + 0.002f * expected);
            CHECK(std::fabs(fin.at(160, 90, 1) - got) <= 2 * kStep);
            if (ev >= 2.0f) CHECK(got > 1.0f);  // above paper white
            CHECK(got <= linear_to_srgb(H) + kStep);
        }
    }
}

TEST_CASE("hdr output: present() encodes the picture for scRGB, HDR10 (PQ) and EDR, and SDR stays within white") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    if (!float_path(g)) return;
    struct Case {
        HdrEncoding e;
        render::OutputEncode enc;
    };
    const Case cases[] = {{HdrEncoding::Edr, render::OutputEncode::EdrLinear},
                          {HdrEncoding::ScRgb, render::OutputEncode::ScRgb},
                          {HdrEncoding::Hdr10, render::OutputEncode::Hdr10},
                          {HdrEncoding::Sdr, render::OutputEncode::Sdr}};
    constexpr float H = 5.0f, kPaperWhite = 240.0f;
    for (const Case& c : cases) {
        CAPTURE(int(c.e));
        Forced f(g, forced(c.e, H, kPaperWhite));
        Flat s(1.0f);
        s.post().exposureEnabled = true;
        s.post().exposureEv = 3.0f;
        s.post().tonemapEnabled = true;
        s.post().tonemapMode = TonemapMode::Neutral;
        const Image shot = g.draw(s.world);
        const Floats fin = read(g, shot, false);
        const Floats out = read(g, shot, true);
        // What present() must write for the pixel the final pass wrote.
        const float shown = fin.at(160, 90, 0);
        const float light = std::clamp(srgb_to_linear(shown), 0.0f, c.e == HdrEncoding::Sdr ? 1.0f : H);
        const float expected = render::encode_output(c.enc, {light, light, light}, kPaperWhite)[0];
        CHECK(out.at(160, 90, 0) == doctest::Approx(expected).epsilon(0.004));
        CHECK(out.at(160, 90, 3) == doctest::Approx(1.0f));
        if (c.e == HdrEncoding::Sdr) {
            CHECK(shown <= 1.0f + kStep);  // the SDR tonemap: the final pass never went above white
        } else {
            CHECK(light > 1.0f);  // the HDR tonemap went above paper white
        }
        if (c.e == HdrEncoding::ScRgb) CHECK(out.at(160, 90, 0) > kPaperWhite / 80.0f);
        if (c.e == HdrEncoding::Hdr10) CHECK(out.at(160, 90, 0) > render::pq_from_nits(kPaperWhite));
    }
}

TEST_CASE(
    "hdr output: the HUD stays at paper white over an HDR picture, and a colour filter keeps the frame within it") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    if (!float_path(g)) return;
    Forced f(g, forced(HdrEncoding::Edr, 4.0f));
    Flat s(1.0f, true);
    s.post().exposureEnabled = true;
    s.post().exposureEv = 3.0f;
    s.post().tonemapEnabled = true;
    s.post().tonemapMode = TonemapMode::Agx;
    const Image shot = g.draw(s.world);
    const Floats out = read(g, shot, true);  // EDR: linear light, 1.0 = paper white
    CHECK(out.at(40, 20, 0) == doctest::Approx(1.0f).epsilon(0.01));
    CHECK(out.at(40, 20, 1) == doctest::Approx(1.0f).epsilon(0.01));
    CHECK(out.at(160, 150, 0) > 1.5f);

    s.post().colorFilterEnabled = true;
    s.post().colorFilterMode = ColorFilter::Greyscale;
    const Floats filtered = read(g, g.draw(s.world), true);
    CHECK(filtered.at(160, 150, 0) <= 1.0f + 0.002f);
    CHECK(filtered.at(160, 150, 0) > 0.5f);
}

TEST_CASE("hdr output: a frame without the final pass, or drawn before the switch, is presented within paper white") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    if (!float_path(g)) return;
    {
        // No PostProcess: nothing decides what goes above white, so nothing does (a float scene can hold 4.0 here).
        Forced f(g, forced(HdrEncoding::ScRgb, 5.0f));
        Flat s(4.0f);
        const Floats out = read(g, g.draw(s.world), true);
        CHECK(out.at(160, 90, 0) == doctest::Approx(200.0f / 80.0f).epsilon(0.004));  // paper white in scRGB
    }
    // Drawn for the standard range, then the window switched to EDR before present(): the SDR picture, at paper white.
    Flat s(1.0f);
    s.post().exposureEnabled = true;
    s.post().exposureEv = 3.0f;
    s.post().tonemapEnabled = true;
    s.post().tonemapMode = TonemapMode::Reinhard;
    const Image shot = g.draw(s.world);
    const Floats sdr = read(g, shot, false);
    Forced f(g, forced(HdrEncoding::Edr, 4.0f));
    const Floats out = read(g, shot, true);
    CHECK(out.at(160, 90, 0) == doctest::Approx(srgb_to_linear(sdr.at(160, 90, 0))).epsilon(0.004));
    CHECK(out.at(160, 90, 0) <= 1.0f + 0.002f);
}
