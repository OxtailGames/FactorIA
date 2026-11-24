// M76.3: the MetalFX wrapper (src/metalfx.h). Needs the Metal backend on an OS and a GPU that have MetalFX: elsewhere the support
// answer is checked and the rest is skipped with the reason (a CI VM with a paravirtual GPU has none).
#include "test_util.h"

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <cstring>
#include <string>
#include <vector>

#include "metalfx.h"
#include "render_internal.h"
#include "shaders/blit.glsl.h"

using namespace fa;
using namespace fa::test;
namespace mfx = fa::render::metalfx;

// The helpers below are used by the Metal tests only: off Metal they would be unused functions (a warning, an error with
// FA_WARNINGS_AS_ERRORS).
#if defined(SOKOL_METAL)
namespace {

// True when this host can run a scaler of `kind`; else says why in the test output.
bool can_run(mfx::Kind kind) {
    const mfx::Support s = mfx::support();
    const bool ok = kind == mfx::Kind::Spatial ? s.spatial : s.temporal;
    if (!ok) MESSAGE("MetalFX is not available here, the test is skipped: " << s.reason);
    return ok;
}

sg_image make_data_image(int w, int h, sg_pixel_format format, const void* data, std::size_t bytes, const char* label) {
    sg_image_desc d{};
    d.type = SG_IMAGETYPE_2D;
    d.width = w;
    d.height = h;
    d.num_mipmaps = 1;
    d.pixel_format = format;
    d.data.mip_levels[0] = {data, bytes};
    d.label = label;
    return sg_make_image(&d);
}

struct Output {
    sg_image image{};
    sg_view view{};
};
// What MetalFX writes: a storage and render-target image, with the texture view the passes after it read.
Output make_output(int w, int h, sg_pixel_format format) {
    Output o;
    sg_image_desc d{};
    d.type = SG_IMAGETYPE_2D;
    d.width = w;
    d.height = h;
    d.num_mipmaps = 1;
    d.pixel_format = format;
    d.usage.storage_image = true;
    d.usage.color_attachment = true;  // MetalFX writes it as a render target (spatial) and a storage image (temporal)
    d.label = "metalfx-test-output";
    o.image = sg_make_image(&d);
    sg_view_desc vd{};
    vd.texture.image = o.image;
    vd.label = "metalfx-test-output-view";
    o.view = sg_make_view(&vd);
    return o;
}
void destroy_output(Output& o) {
    if (o.view.id) sg_destroy_view(o.view);
    if (o.image.id) sg_destroy_image(o.image);
    o = Output{};
}

// The scene the spatial tests upscale, as a function of a point of the unit square: a smooth ramp with a soft disc (no hard
// edges, so a bilinear reference is a fair comparison).
float scene(float u, float v) {
    const float ramp = 0.15f + 0.5f * u + 0.2f * v;
    const float dx = u - 0.5f, dy = v - 0.5f;
    const float disc = std::exp(-(dx * dx + dy * dy) * 18.0f) * 0.25f;
    return std::clamp(ramp + disc, 0.0f, 1.0f);
}

// RGBA8 pixels of the scene sampled at (x + 0.5 + jx, y + 0.5 + jy) of a w x h grid, grey (the same value in r, g, b).
std::vector<std::uint8_t> scene_pixels(int w, int h, float jx, float jy) {
    std::vector<std::uint8_t> px(std::size_t(w) * h * 4);
    for (int y = 0; y < h; ++y)
        for (int x = 0; x < w; ++x) {
            const float v = scene((float(x) + 0.5f + jx) / float(w), (float(y) + 0.5f + jy) / float(h));
            const std::uint8_t b = std::uint8_t(std::lround(v * 255.0f));
            std::uint8_t* p = &px[(std::size_t(y) * w + x) * 4];
            p[0] = p[1] = p[2] = b;
            p[3] = 255;
        }
    return px;
}

// The mean absolute difference (0..1) of the red channel of two RGBA8 images of the same size, over the pixels that are at least
// `border` away from every edge (a scaler treats the edge in its own way).
double mean_diff(const std::vector<std::uint8_t>& a, const std::vector<std::uint8_t>& b, int w, int h, int border) {
    double sum = 0.0;
    int n = 0;
    for (int y = border; y < h - border; ++y)
        for (int x = border; x < w - border; ++x) {
            const std::size_t i = (std::size_t(y) * w + x) * 4;
            sum += std::abs(double(a[i]) - double(b[i])) / 255.0;
            ++n;
        }
    return n ? sum / n : 0.0;
}

// The input image scaled up by a bilinear filter (texel centres, edges clamped): the plain upscale a spatial scaler is compared with.
std::vector<std::uint8_t> bilinear_up(const std::vector<std::uint8_t>& in, int inW, int inH, int outW, int outH) {
    std::vector<std::uint8_t> out(std::size_t(outW) * outH * 4, 255);
    auto at = [&](int x, int y) {
        x = std::clamp(x, 0, inW - 1);
        y = std::clamp(y, 0, inH - 1);
        return float(in[(std::size_t(y) * inW + x) * 4]);
    };
    for (int y = 0; y < outH; ++y)
        for (int x = 0; x < outW; ++x) {
            const float fx = (float(x) + 0.5f) * float(inW) / float(outW) - 0.5f;
            const float fy = (float(y) + 0.5f) * float(inH) / float(outH) - 0.5f;
            const int x0 = int(std::floor(fx)), y0 = int(std::floor(fy));
            const float tx = fx - float(x0), ty = fy - float(y0);
            const float top = at(x0, y0) * (1.0f - tx) + at(x0 + 1, y0) * tx;
            const float bottom = at(x0, y0 + 1) * (1.0f - tx) + at(x0 + 1, y0 + 1) * tx;
            const std::uint8_t v = std::uint8_t(std::lround(top * (1.0f - ty) + bottom * ty));
            std::uint8_t* p = &out[(std::size_t(y) * outW + x) * 4];
            p[0] = p[1] = p[2] = v;
        }
    return out;
}

// A read back goes through a command buffer of its own: the frame's sokol buffer must be submitted first (Scaler::encode leaves one open
// for the passes after it), or the read back waits behind it for ever.
bool read_back(sg_image image, int w, int h, std::vector<std::uint8_t>& out, std::string* error) {
    sg_commit();
    return render::readback_rgba8(image, w, h, out, error);
}

}  // namespace
#endif

TEST_CASE("metalfx: the support answer says what is missing") {
    REQUIRE(gfx().ok);  // the Metal device exists
    const mfx::Support s = mfx::support();
    if (s.spatial && s.temporal) {
        CHECK(s.reason.empty());
    } else {
        // A teaching message: what is missing here and what to do instead.
        CHECK(!s.reason.empty());
        CHECK(s.reason.find("upscaler") != std::string::npos);
        MESSAGE("MetalFX is not available here: " << s.reason);
    }
#if !defined(SOKOL_METAL)
    CHECK(!s.spatial);
    CHECK(!s.temporal);
    mfx::Scaler scaler;
    std::string error;
    mfx::Desc d;
    d.inputWidth = d.inputHeight = 8;
    d.outputWidth = d.outputHeight = 16;
    CHECK(!scaler.configure(d, &error));
    CHECK(error.find("MetalFX") != std::string::npos);
    CHECK(!scaler.valid());
    CHECK(!scaler.encode(mfx::Frame{}, &error));
#endif
}

#if defined(SOKOL_METAL)

TEST_CASE("metalfx: a scaler is refused with a reason before MetalFX is asked") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    mfx::Scaler scaler;
    std::string error;
    mfx::Desc d;
    d.inputWidth = 32;
    d.inputHeight = 32;
    d.outputWidth = 16;  // smaller than the input
    d.outputHeight = 16;
    CHECK(!scaler.configure(d, &error));
    CHECK(error.find("smaller than the input") != std::string::npos);
    d.outputWidth = d.outputHeight = 0;
    CHECK(!scaler.configure(d, &error));
    CHECK(error.find("at least 1x1") != std::string::npos);
    d.inputWidth = d.inputHeight = 8;
    d.outputWidth = d.outputHeight = 16;
    d.colorFormat = SG_PIXELFORMAT_BC1_RGBA;
    CHECK(!scaler.configure(d, &error));
    CHECK(error.find("one of") != std::string::npos);
    CHECK(!scaler.valid());
    CHECK(!scaler.encode(mfx::Frame{}, &error));
    CHECK(error.find("configure") != std::string::npos);
}

TEST_CASE(
    "metalfx: the spatial scaler at 2x gives the picture a bilinear upscale gives, and a resize makes a new scaler") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    if (!can_run(mfx::Kind::Spatial)) return;
    const int inW = 48, inH = 32, outW = 96, outH = 64;
    const std::vector<std::uint8_t> in = scene_pixels(inW, inH, 0.0f, 0.0f);
    const std::vector<std::uint8_t> reference =
        scene_pixels(outW, outH, 0.0f, 0.0f);  // the scene itself, at the output size
    sg_image color = make_data_image(inW, inH, SG_PIXELFORMAT_RGBA8, in.data(), in.size(), "metalfx-test-color");
    Output out = make_output(outW, outH, SG_PIXELFORMAT_RGBA8);
    REQUIRE(sg_query_image_state(color) == SG_RESOURCESTATE_VALID);
    REQUIRE(sg_query_image_state(out.image) == SG_RESOURCESTATE_VALID);

    mfx::Scaler scaler;
    std::string error;
    mfx::Desc d;
    d.kind = mfx::Kind::Spatial;
    d.inputWidth = inW;
    d.inputHeight = inH;
    d.outputWidth = outW;
    d.outputHeight = outH;
    d.colorFormat = d.outputFormat = SG_PIXELFORMAT_RGBA8;
    d.colorSpace = mfx::ColorSpace::Perceptual;
    REQUIRE_MESSAGE(scaler.configure(d, &error), error);
    CHECK(scaler.generation() == 1);
    CHECK(scaler.configure(d, &error));  // the same desc keeps the scaler
    CHECK(scaler.generation() == 1);

    mfx::Frame f;
    f.color = color;
    f.output = out.image;
    REQUIRE_MESSAGE(scaler.encode(f, &error), error);
    CHECK(scaler.encoded() == 1);
    std::vector<std::uint8_t> got;
    REQUIRE_MESSAGE(read_back(out.image, outW, outH, got, &error), error);
    const double err = mean_diff(got, reference, outW, outH, 4);
    const double errBilinear = mean_diff(got, bilinear_up(in, inW, inH, outW, outH), outW, outH, 4);
    // The picture a bilinear upscale gives and the scene itself sampled at the output size, within what MetalFX changes (it sharpens;
    // 0.004 on the OS this was written on, 5x of room for others); a blank, shifted or half-written output is far over.
    CHECK_MESSAGE(err < 0.02,
                  "mean error of the spatial upscale against the scene: " << std::round(err * 10000.0) / 10000.0);
    CHECK_MESSAGE(errBilinear < 0.02, "mean error of the spatial upscale against a bilinear one: "
                                          << std::round(errBilinear * 10000.0) / 10000.0);

    // An image of the wrong size is refused before any work is done, and says what to do.
    mfx::Frame bad = f;
    bad.color = out.image;
    CHECK(!scaler.encode(bad, &error));
    CHECK(error.find("configure again") != std::string::npos);
    CHECK(scaler.encoded() == 1);
    // A colour image that is not an image.
    bad = f;
    bad.color = sg_image{};
    CHECK(!scaler.encode(bad, &error));
    CHECK(error.find("not a valid image") != std::string::npos);
    // An output that is not a storage image (MetalFX could not write it).
    sg_image plain =
        make_data_image(outW, outH, SG_PIXELFORMAT_RGBA8, reference.data(), reference.size(), "metalfx-test-plain");
    bad = f;
    bad.output = plain;
    CHECK(!scaler.encode(bad, &error));
    CHECK(error.find("usage.storage_image") != std::string::npos);
    sg_destroy_image(plain);

    // A resize: another size makes another scaler; the old frame no longer fits it.
    const int in2W = 24, in2H = 16;
    const std::vector<std::uint8_t> in2 = scene_pixels(in2W, in2H, 0.0f, 0.0f);
    sg_image color2 = make_data_image(in2W, in2H, SG_PIXELFORMAT_RGBA8, in2.data(), in2.size(), "metalfx-test-color2");
    d.inputWidth = in2W;
    d.inputHeight = in2H;
    REQUIRE_MESSAGE(scaler.configure(d, &error), error);
    CHECK(scaler.generation() == 2);
    CHECK(scaler.encoded() == 0);
    CHECK(!scaler.encode(f, &error));  // the 48x32 colour against a 24x16 scaler
    f.color = color2;
    REQUIRE_MESSAGE(scaler.encode(f, &error), error);
    REQUIRE_MESSAGE(read_back(out.image, outW, outH, got, &error), error);
    const double err2 = mean_diff(got, reference, outW, outH, 4);
    CHECK_MESSAGE(err2 < 0.03, "mean error of the 4x spatial upscale: " << std::round(err2 * 10000.0) / 10000.0);

    scaler.release();
    CHECK(!scaler.valid());
    sg_destroy_image(color2);
    sg_destroy_image(color);
    destroy_output(out);
    sg_commit();
}

TEST_CASE("metalfx: the temporal scaler with a jitter and no motion converges on the scene at the output size") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    if (!can_run(mfx::Kind::Temporal)) return;
    const int inW = 48, inH = 32, outW = 96, outH = 64;
    const std::vector<std::uint8_t> reference = scene_pixels(outW, outH, 0.0f, 0.0f);
    const std::vector<std::uint16_t> noMotion(std::size_t(inW) * inH * 2, 0);  // RG16F zero
    const std::vector<float> depth(std::size_t(inW) * inH, 0.5f);
    sg_image motion =
        make_data_image(inW, inH, SG_PIXELFORMAT_RG16F, noMotion.data(), noMotion.size() * 2, "metalfx-test-motion");
    sg_image depthImg =
        make_data_image(inW, inH, SG_PIXELFORMAT_R32F, depth.data(), depth.size() * 4, "metalfx-test-depth");
    Output out = make_output(outW, outH, SG_PIXELFORMAT_RGBA8);
    REQUIRE(sg_query_image_state(motion) == SG_RESOURCESTATE_VALID);
    REQUIRE(sg_query_image_state(depthImg) == SG_RESOURCESTATE_VALID);

    mfx::Scaler scaler;
    std::string error;
    mfx::Desc d;
    d.kind = mfx::Kind::Temporal;
    d.inputWidth = inW;
    d.inputHeight = inH;
    d.outputWidth = outW;
    d.outputHeight = outH;
    d.colorFormat = d.outputFormat = SG_PIXELFORMAT_RGBA8;
    d.depthFormat = SG_PIXELFORMAT_R32F;
    d.motionFormat = SG_PIXELFORMAT_RG16F;
    d.autoExposure = false;
    REQUIRE_MESSAGE(scaler.configure(d, &error), error);

    // Halton(2,3) jitter, the sequence the engine's TAA will use, in render pixels (-0.5..0.5), the scene sampled at the jittered
    // point as a jittered projection does.
    auto halton = [](int i, int base) {
        float f = 1.0f, r = 0.0f;
        for (int n = i; n > 0; n /= base) {
            f /= float(base);
            r += f * float(n % base);
        }
        return r;
    };
    // The convention of Frame::jitterX/Y: how far the drawn picture is shifted, in render pixels, right and DOWN (a scene sampled
    // at (x + jx, y + jy) is shifted by (-jx, -jy)). The opposite sign is run too, as the contrast that shows the sign matters.
    double err[2] = {1.0, 1.0};
    for (int run = 0; run < 2; ++run) {
        const float s = run == 0 ? -1.0f : 1.0f;
        double first = 1.0;
        for (int frame = 0; frame < 16; ++frame) {
            const float jx = halton(frame % 8 + 1, 2) - 0.5f, jy = halton(frame % 8 + 1, 3) - 0.5f;
            const std::vector<std::uint8_t> in = scene_pixels(inW, inH, jx, jy);
            sg_image color =
                make_data_image(inW, inH, SG_PIXELFORMAT_RGBA8, in.data(), in.size(), "metalfx-test-color");
            REQUIRE(sg_query_image_state(color) == SG_RESOURCESTATE_VALID);
            mfx::Frame f;
            f.color = color;
            f.depth = depthImg;
            f.motion = motion;
            f.output = out.image;
            f.jitterX = s * jx;
            f.jitterY = s * jy;
            f.reset = frame == 0;
            REQUIRE_MESSAGE(scaler.encode(f, &error), error);
            std::vector<std::uint8_t> got;
            REQUIRE_MESSAGE(read_back(out.image, outW, outH, got, &error), error);
            const double e = mean_diff(got, reference, outW, outH, 4);
            if (frame == 0) first = e;
            if (frame == 15) err[run] = e;
            sg_destroy_image(color);
        }
        MESSAGE(std::string(run == 0 ? "documented jitter sign" : "opposite jitter sign")
                << ": mean error of the first frame " << std::round(first * 10000.0) / 10000.0 << ", after 16 frames "
                << std::round(err[run] * 10000.0) / 10000.0);
        CHECK(scaler.encoded() == 16 * (run + 1));
    }
    CHECK_MESSAGE(err[0] < 0.02, "the converged temporal output is far from the scene: " << err[0]);

    destroy_output(out);
    sg_destroy_image(depthImg);
    sg_destroy_image(motion);
    sg_commit();
}

TEST_CASE("metalfx: a pass that writes the input and a pass that reads the output in the same frame see this frame's "
          "pictures") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    if (!can_run(mfx::Kind::Spatial)) return;
    render::Gpu gpu;
    std::string error;
    REQUIRE_MESSAGE(gpu.init(1, &error), error);
    const int inW = 16, inH = 16, outW = 32, outH = 32, frames = 12;

    render::TargetDesc td;
    td.label = "metalfx-test-input";
    td.width = inW;
    td.height = inH;
    td.colorFormat = SG_PIXELFORMAT_RGBA8;
    render::Target input = render::make_target(td);
    REQUIRE(input.valid());
    Output out = make_output(outW, outH, SG_PIXELFORMAT_RGBA8);
    REQUIRE(sg_query_image_state(out.image) == SG_RESOURCESTATE_VALID);
    REQUIRE(sg_query_view_state(out.view) == SG_RESOURCESTATE_VALID);
    std::vector<render::Target> shown(frames);
    for (int i = 0; i < frames; ++i) {
        render::TargetDesc sd;
        sd.label = "metalfx-test-shown";
        sd.width = outW;
        sd.height = outH;
        sd.colorFormat = SG_PIXELFORMAT_RGBA8;
        sd.texture = false;
        shown[std::size_t(i)] = render::make_target(sd);
        REQUIRE(shown[std::size_t(i)].valid());
    }

    mfx::Scaler scaler;
    mfx::Desc d;
    d.inputWidth = inW;
    d.inputHeight = inH;
    d.outputWidth = outW;
    d.outputHeight = outH;
    d.colorFormat = d.outputFormat = SG_PIXELFORMAT_RGBA8;
    d.colorSpace = mfx::ColorSpace::Perceptual;
    REQUIRE_MESSAGE(scaler.configure(d, &error), error);

    // Every frame: a pass writes a grey of its own into the input, MetalFX scales it, a later pass copies the scaled image. The
    // frames are queued without waiting for the GPU (only the read-back at the end waits), so a scaler that ran behind the passes
    // that follow it, or ahead of the ones before it, shows the grey of the frame before or after: the greys are 8% apart.
    std::vector<float> grey(static_cast<std::size_t>(frames), 0.0f);
    for (int i = 0; i < frames; ++i) grey[std::size_t(i)] = 0.08f + 0.07f * float(i);
    for (int i = 0; i < frames; ++i) {
        render::PassDesc p = render::pass_into(input, "metalfx-test-write-input");
        p.colorLoad = SG_LOADACTION_CLEAR;
        p.clearColor = {grey[std::size_t(i)], grey[std::size_t(i)], grey[std::size_t(i)], 1.0f};
        p.colorStore = SG_STOREACTION_STORE;
        gpu.begin_pass(p);
        gpu.end_pass();

        mfx::Frame f;
        f.color = input.texture_image();
        f.output = out.image;
        REQUIRE_MESSAGE(scaler.encode(f, &error), error);

        render::PassDesc q = render::pass_into(shown[std::size_t(i)], "metalfx-test-read-output");
        q.colorLoad = SG_LOADACTION_DONTCARE;
        q.colorStore = SG_STOREACTION_STORE;
        gpu.begin_pass(q);
        sg_apply_pipeline(gpu.blit_keep_pipeline(q.format));
        sg_bindings b{};
        b.vertex_buffers[0] = gpu.fullscreen_triangle();
        b.views[VIEW_blit_tex] = out.view;
        b.samplers[SMP_blit_smp] = gpu.sampler(render::SamplerKind::Nearest);
        sg_apply_bindings(&b);
        blit_blit_vs_params_t vu{};
        vu.flip[0] = 0.0f;
        sg_range vr{&vu, sizeof(vu)};
        sg_apply_uniforms(UB_blit_blit_vs_params, &vr);
        blit_blit_fs_params_t fu{};
        sg_range fr{&fu, sizeof(fu)};
        sg_apply_uniforms(UB_blit_blit_fs_params, &fr);
        sg_draw(0, 3, 1);
        gpu.end_pass();
    }
    sg_commit();
    CHECK(scaler.encoded() == frames);

    int wrong = 0;
    for (int i = 0; i < frames; ++i) {
        std::vector<std::uint8_t> px;
        REQUIRE_MESSAGE(read_back(shown[std::size_t(i)].color, outW, outH, px, &error), error);
        const std::size_t centre = (std::size_t(outH / 2) * outW + outW / 2) * 4;
        const double v = double(px[centre]) / 255.0;
        if (std::abs(v - double(grey[std::size_t(i)])) > 0.03) {
            ++wrong;
            INFO("frame " << i << " expected grey " << grey[std::size_t(i)] << ", the later pass read " << v);
        }
    }
    CHECK_MESSAGE(wrong == 0, wrong << " of " << frames << " frames showed another frame's picture");

    for (render::Target& t : shown) render::destroy_target(t);
    destroy_output(out);
    render::destroy_target(input);
    sg_commit();
    gpu.shutdown();
}

namespace {
// A stripe pattern (vertical stripes moving to the right, or horizontal stripes moving down) that MetalFX's temporal scaler follows with a
// motion image of sign +1 (where the pixel was), -1 and 0; err[run] is the mean error against the pattern after the last frame.
void moving_pattern_errors(bool vertical, double err[3]) {
    const int inW = 160, inH = 90, outW = 320, outH = 180, frames = 24;
    const float shift = 0.8f;  // render pixels the pattern moves (to the right, or down) every frame
    // A pattern with detail a single frame does not carry (about 2.6 render pixels a period): only the history, aligned by the motion, does.
    auto pattern = [&](float px, float py, float t) {
        const float along = vertical ? py : px;
        return std::sin((along - shift * t) * (6.2831853f / 2.6f)) > 0.0f ? 0.95f : 0.05f;
    };
    auto halton = [](int i, int base) {
        float f = 1.0f, r = 0.0f;
        for (int n = i; n > 0; n /= base) {
            f /= float(base);
            r += f * float(n % base);
        }
        return r;
    };
    const std::vector<std::uint16_t> unused(1);
    std::vector<float> depth(std::size_t(inW) * inH, 0.5f);
    for (std::size_t k = 0; k < depth.size(); ++k)
        depth[k] =
            (vertical ? k / std::size_t(inW) < std::size_t(inH) / 2 : (k % std::size_t(inW)) < std::size_t(inW) / 2)
                ? 0.5f
                : 1.0f;
    sg_image depthImg =
        make_data_image(inW, inH, SG_PIXELFORMAT_R32F, depth.data(), depth.size() * 4, "metalfx-test-depth");
    REQUIRE(sg_query_image_state(depthImg) == SG_RESOURCESTATE_VALID);
    auto half = [](float f) {  // float -> IEEE half (normal numbers and zero are enough here)
        if (f == 0.0f) return std::uint16_t(0);
        std::uint32_t b;
        std::memcpy(&b, &f, 4);
        const std::uint32_t sign = (b >> 16) & 0x8000u;
        const int e = int((b >> 23) & 0xFF) - 127 + 15;
        return std::uint16_t(sign | (std::uint32_t(e) << 10) | ((b >> 13) & 0x3FF));
    };
    for (int run = 0; run < 3; ++run) {
        const float sgn = run == 0 ? 1.0f : run == 1 ? -1.0f : 0.0f;
        // Where this pixel's surface was on the frame before, in pictures: `shift` pixels to the left (x = -shift / inW), or above
        // (y = -shift / inH, the picture's y runs down).
        const float mx = vertical ? 0.0f : -sgn * shift / float(inW);
        const float my = vertical ? -sgn * shift / float(inH) : 0.0f;
        std::vector<std::uint16_t> mv(std::size_t(inW) * inH * 2);
        for (std::size_t i = 0; i < std::size_t(inW) * inH; ++i) {
            mv[i * 2] = half(mx);
            mv[i * 2 + 1] = half(my);
        }
        sg_image motion =
            make_data_image(inW, inH, SG_PIXELFORMAT_RG16F, mv.data(), mv.size() * 2, "metalfx-test-motion");
        REQUIRE(sg_query_image_state(motion) == SG_RESOURCESTATE_VALID);
        Output out = make_output(outW, outH, SG_PIXELFORMAT_RGBA16F);
        mfx::Scaler scaler;
        std::string error;
        mfx::Desc d;
        d.kind = mfx::Kind::Temporal;
        d.inputWidth = inW;
        d.inputHeight = inH;
        d.outputWidth = outW;
        d.outputHeight = outH;
        d.colorFormat = d.outputFormat = SG_PIXELFORMAT_RGBA16F;
        d.depthFormat = SG_PIXELFORMAT_R32F;
        d.motionFormat = SG_PIXELFORMAT_RG16F;
        d.autoExposure = false;
        REQUIRE_MESSAGE(scaler.configure(d, &error), error);
        double last = 1.0;
        for (int frame = 0; frame < frames; ++frame) {
            const float jx = halton(frame % 32 + 1, 2) - 0.5f, jy = halton(frame % 32 + 1, 3) - 0.5f;
            std::vector<std::uint16_t> in(std::size_t(inW) * inH * 4);
            for (int y = 0; y < inH; ++y)
                for (int x = 0; x < inW; ++x) {
                    const std::uint16_t b = half(pattern(float(x) + 0.5f + jx, float(y) + 0.5f + jy, float(frame)));
                    std::uint16_t* p = &in[(std::size_t(y) * inW + x) * 4];
                    p[0] = p[1] = p[2] = b;
                    p[3] = half(1.0f);
                }
            sg_image color =
                make_data_image(inW, inH, SG_PIXELFORMAT_RGBA16F, in.data(), in.size() * 2, "metalfx-test-color");
            mfx::Frame f;
            f.color = color;
            f.depth = depthImg;
            f.motion = motion;
            f.output = out.image;
            f.jitterX = -jx;
            f.jitterY = -jy;
            f.motionScaleX = float(inW);
            f.motionScaleY = float(inH);
            f.reset = frame == 0;
            REQUIRE_MESSAGE(scaler.encode(f, &error), error);
            std::vector<std::uint8_t> got;
            {
                std::vector<float> gf;
                sg_commit();  // the read back's own command buffer must not queue behind the open sokol one (see read_back)
                REQUIRE_MESSAGE(render::readback_rgba16f(out.image, outW, outH, gf, &error), error);
                got.resize(gf.size());
                for (std::size_t k = 0; k < gf.size(); ++k)
                    got[k] = std::uint8_t(std::lround(std::clamp(gf[k], 0.0f, 1.0f) * 255.0f));
            }
            if (frame == frames - 1) {
                std::vector<std::uint8_t> truth(std::size_t(outW) * outH * 4);
                for (int y = 0; y < outH; ++y)
                    for (int x = 0; x < outW; ++x) {
                        const float px = (float(x) + 0.5f) * float(inW) / float(outW);
                        const float py = (float(y) + 0.5f) * float(inH) / float(outH);
                        const std::uint8_t b = std::uint8_t(std::lround(pattern(px, py, float(frame)) * 255.0f));
                        std::uint8_t* p = &truth[(std::size_t(y) * outW + x) * 4];
                        p[0] = p[1] = p[2] = b;
                        p[3] = 255;
                    }
                last = mean_diff(got, truth, outW, outH, 6);
            }
            sg_destroy_image(color);
        }
        err[run] = last;
        destroy_output(out);
        sg_destroy_image(motion);
    }
    sg_destroy_image(depthImg);
    sg_commit();
}
}  // namespace

TEST_CASE(
    "metalfx: the temporal scaler follows a moving pattern when the motion points from the pixel to where it was") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    if (!can_run(mfx::Kind::Temporal)) return;
    double err[3] = {1, 1, 1};
    moving_pattern_errors(false, err);
    MESSAGE("horizontal motion, mean error after 24 frames: motion = where the pixel was "
            << std::round(err[0] * 10000.0) / 10000.0 << ", opposite " << std::round(err[1] * 10000.0) / 10000.0
            << ", none " << std::round(err[2] * 10000.0) / 10000.0);
    // The convention the renderer hands MetalFX (docs/UPSCALING.md): the right sign is clearly the best one.
    CHECK(err[0] < 0.8 * err[1]);
    CHECK(err[0] < 0.8 * err[2]);
}

TEST_CASE("metalfx: the same in y: horizontal stripes moving down, the motion image's y runs down like the picture's") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    if (!can_run(mfx::Kind::Temporal)) return;
    double err[3] = {1, 1, 1};
    moving_pattern_errors(true, err);
    MESSAGE("vertical motion, mean error after 24 frames: motion = where the pixel was "
            << std::round(err[0] * 10000.0) / 10000.0 << ", opposite " << std::round(err[1] * 10000.0) / 10000.0
            << ", none " << std::round(err[2] * 10000.0) / 10000.0);
    CHECK(err[0] < 0.8 * err[1]);
    CHECK(err[0] < 0.8 * err[2]);
}

#else

TEST_CASE("metalfx: the Metal tests") { MESSAGE("MetalFX exists on the Metal backend only: this build skips them"); }

#endif
