// M76.3: the MetalFX wrapper (src/metalfx.h). Needs the Metal backend on an OS and a GPU that have MetalFX: elsewhere the support
// answer is checked and the rest is skipped with the reason (a CI VM with a paravirtual GPU has none).
#include "test_util.h"

#include <algorithm>
#include <chrono>
#include <memory>
#include <cmath>
#include <cstdint>
#include <cstring>
#include <string>
#include <thread>
#include <vector>

#include "gpu/device.h"
#include "gpu/sokol_device.h"
#include "metalfx.h"
#include "render_internal.h"
#include "shaders/blit.glsl.h"

using namespace fa;
using namespace fa::test;
namespace mfx = fa::render::metalfx;

namespace {

// The gpu::Device of a test: a SokolDevice that adopts the sokol context the test's renderer (or Gpu) opened, like the renderer's own
// device does. One per test case (DeviceScope); the MetalFX wrapper and every image of these tests go through it.
gpu::Device*& device_slot() {
    static gpu::Device* slot = nullptr;
    return slot;
}
gpu::Device& dev() { return *device_slot(); }

struct DeviceScope {
    std::unique_ptr<gpu::Device> device;
    DeviceScope() {
        auto made = gpu::make_device(gpu::built_sokol_backend());
        if (!made.ok()) FAIL(made.error().to_string());
        device = std::move(made).value();
        device_slot() = device.get();
    }
    ~DeviceScope() { device_slot() = nullptr; }
    DeviceScope(const DeviceScope&) = delete;
    DeviceScope& operator=(const DeviceScope&) = delete;
};

}  // namespace

// The helpers below are used by the Metal tests only: off Metal they would be unused functions (a warning, an error with
// FA_WARNINGS_AS_ERRORS).
#if defined(SOKOL_METAL)
namespace {

// True when this host can run a scaler of `kind`; else says why in the test output.
bool can_run(mfx::Kind kind) {
    const mfx::Support s = mfx::support(dev().native().device);
    const bool ok = kind == mfx::Kind::Spatial ? s.spatial : s.temporal;
    if (!ok) MESSAGE("MetalFX is not available here, the test is skipped: " << s.reason);
    return ok;
}

gpu::Image make_data_image(int w, int h, gpu::PixelFormat format, const void* data, std::size_t bytes,
                           const char* label) {
    gpu::ImageDesc d{};
    d.type = gpu::ImageType::Tex2d;
    d.width = w;
    d.height = h;
    d.numMipmaps = 1;
    d.pixelFormat = format;
    d.data.mipLevels[0] = {data, bytes};
    d.label = label;
    return dev().make_image(d);
}

struct Output {
    gpu::Image image{};
    gpu::View view{};
};
// What MetalFX writes: a storage and render-target image, with the texture view the passes after it read.
Output make_output(int w, int h, gpu::PixelFormat format) {
    Output o;
    gpu::ImageDesc d{};
    d.type = gpu::ImageType::Tex2d;
    d.width = w;
    d.height = h;
    d.numMipmaps = 1;
    d.pixelFormat = format;
    d.usage.storageImage = true;
    d.usage.colorAttachment = true;  // MetalFX writes it as a render target (spatial) and a storage image (temporal)
    d.label = "metalfx-test-output";
    o.image = dev().make_image(d);
    gpu::ViewDesc vd{};
    vd.texture.image = o.image;
    vd.label = "metalfx-test-output-view";
    o.view = dev().make_view(vd);
    return o;
}
void destroy_output(Output& o) {
    if (o.view.valid()) dev().destroy_view(o.view);
    if (o.image.valid()) dev().destroy_image(o.image);
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
bool read_back(gpu::Image image, int w, int h, std::vector<std::uint8_t>& out, std::string* error) {
    dev().commit();
    const Result<void> r = dev().read_image_rgba8(image, w, h, out);
    if (!r.ok() && error) *error = r.error().to_string();
    return r.ok();
}
// The same for an RGBA16F image, as floats.
bool read_back_f16(gpu::Image image, int w, int h, std::vector<float>& out, std::string* error) {
    dev().commit();
    const Result<void> r = dev().read_image_rgba16f(image, w, h, out);
    if (!r.ok() && error) *error = r.error().to_string();
    return r.ok();
}

}  // namespace
#endif

TEST_CASE("metalfx: the support answer says what is missing") {
    REQUIRE(gfx().ok);  // the Metal device exists
    DeviceScope scope;
    const mfx::Support s = mfx::support(dev().native().device);
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
    CHECK(!scaler.configure(dev(), d, &error));
    CHECK(error.find("MetalFX") != std::string::npos);
    CHECK(!scaler.valid());
    CHECK(!scaler.encode(dev(), mfx::Frame{}, &error));
#endif
}

#if defined(SOKOL_METAL)

TEST_CASE("metalfx: a scaler is refused with a reason before MetalFX is asked") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    DeviceScope scope;
    mfx::Scaler scaler;
    std::string error;
    mfx::Desc d;
    d.inputWidth = 32;
    d.inputHeight = 32;
    d.outputWidth = 16;  // smaller than the input
    d.outputHeight = 16;
    CHECK(!scaler.configure(dev(), d, &error));
    CHECK(error.find("smaller than the input") != std::string::npos);
    d.outputWidth = d.outputHeight = 0;
    CHECK(!scaler.configure(dev(), d, &error));
    CHECK(error.find("at least 1x1") != std::string::npos);
    d.inputWidth = d.inputHeight = 8;
    d.outputWidth = d.outputHeight = 16;
    d.colorFormat = gpu::PixelFormat::Bc1Rgba;
    CHECK(!scaler.configure(dev(), d, &error));
    CHECK(error.find("one of") != std::string::npos);
    CHECK(!scaler.valid());
    CHECK(!scaler.encode(dev(), mfx::Frame{}, &error));
    CHECK(error.find("configure") != std::string::npos);
}

TEST_CASE(
    "metalfx: the spatial scaler at 2x gives the picture a bilinear upscale gives, and a resize makes a new scaler") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    DeviceScope scope;
    if (!can_run(mfx::Kind::Spatial)) return;
    const int inW = 48, inH = 32, outW = 96, outH = 64;
    const std::vector<std::uint8_t> in = scene_pixels(inW, inH, 0.0f, 0.0f);
    const std::vector<std::uint8_t> reference =
        scene_pixels(outW, outH, 0.0f, 0.0f);  // the scene itself, at the output size
    gpu::Image color = make_data_image(inW, inH, gpu::PixelFormat::Rgba8, in.data(), in.size(), "metalfx-test-color");
    Output out = make_output(outW, outH, gpu::PixelFormat::Rgba8);
    REQUIRE(dev().state(color) == gpu::ResourceState::Valid);
    REQUIRE(dev().state(out.image) == gpu::ResourceState::Valid);

    mfx::Scaler scaler;
    std::string error;
    mfx::Desc d;
    d.kind = mfx::Kind::Spatial;
    d.inputWidth = inW;
    d.inputHeight = inH;
    d.outputWidth = outW;
    d.outputHeight = outH;
    d.colorFormat = d.outputFormat = gpu::PixelFormat::Rgba8;
    d.colorSpace = mfx::ColorSpace::Perceptual;
    REQUIRE_MESSAGE(scaler.configure(dev(), d, &error), error);
    CHECK(scaler.generation() == 1);
    CHECK(scaler.configure(dev(), d, &error));  // the same desc keeps the scaler
    CHECK(scaler.generation() == 1);

    mfx::Frame f;
    f.color = color;
    f.output = out.image;
    REQUIRE_MESSAGE(scaler.encode(dev(), f, &error), error);
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
    CHECK(!scaler.encode(dev(), bad, &error));
    CHECK(error.find("configure again") != std::string::npos);
    CHECK(scaler.encoded() == 1);
    // A colour image that is not an image.
    bad = f;
    bad.color = gpu::Image{};
    CHECK(!scaler.encode(dev(), bad, &error));
    CHECK(error.find("not a valid image") != std::string::npos);
    // An output that is not a storage image (MetalFX could not write it).
    gpu::Image plain =
        make_data_image(outW, outH, gpu::PixelFormat::Rgba8, reference.data(), reference.size(), "metalfx-test-plain");
    bad = f;
    bad.output = plain;
    CHECK(!scaler.encode(dev(), bad, &error));
    CHECK(error.find("usage.storage_image") != std::string::npos);
    dev().destroy_image(plain);

    // A resize: another size makes another scaler; the old frame no longer fits it.
    const int in2W = 24, in2H = 16;
    const std::vector<std::uint8_t> in2 = scene_pixels(in2W, in2H, 0.0f, 0.0f);
    gpu::Image color2 =
        make_data_image(in2W, in2H, gpu::PixelFormat::Rgba8, in2.data(), in2.size(), "metalfx-test-color2");
    d.inputWidth = in2W;
    d.inputHeight = in2H;
    REQUIRE_MESSAGE(scaler.configure(dev(), d, &error), error);
    CHECK(scaler.generation() == 2);
    CHECK(scaler.encoded() == 0);
    CHECK(!scaler.encode(dev(), f, &error));  // the 48x32 colour against a 24x16 scaler
    f.color = color2;
    REQUIRE_MESSAGE(scaler.encode(dev(), f, &error), error);
    REQUIRE_MESSAGE(read_back(out.image, outW, outH, got, &error), error);
    const double err2 = mean_diff(got, reference, outW, outH, 4);
    CHECK_MESSAGE(err2 < 0.03, "mean error of the 4x spatial upscale: " << std::round(err2 * 10000.0) / 10000.0);

    scaler.release();
    CHECK(!scaler.valid());
    dev().destroy_image(color2);
    dev().destroy_image(color);
    destroy_output(out);
    dev().commit();
}

TEST_CASE("metalfx: the temporal scaler with a jitter and no motion converges on the scene at the output size") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    DeviceScope scope;
    if (!can_run(mfx::Kind::Temporal)) return;
    const int inW = 48, inH = 32, outW = 96, outH = 64;
    const std::vector<std::uint8_t> reference = scene_pixels(outW, outH, 0.0f, 0.0f);
    const std::vector<std::uint16_t> noMotion(std::size_t(inW) * inH * 2, 0);  // RG16F zero
    const std::vector<float> depth(std::size_t(inW) * inH, 0.5f);
    gpu::Image motion =
        make_data_image(inW, inH, gpu::PixelFormat::Rg16F, noMotion.data(), noMotion.size() * 2, "metalfx-test-motion");
    gpu::Image depthImg =
        make_data_image(inW, inH, gpu::PixelFormat::R32F, depth.data(), depth.size() * 4, "metalfx-test-depth");
    Output out = make_output(outW, outH, gpu::PixelFormat::Rgba8);
    REQUIRE(dev().state(motion) == gpu::ResourceState::Valid);
    REQUIRE(dev().state(depthImg) == gpu::ResourceState::Valid);

    mfx::Scaler scaler;
    std::string error;
    mfx::Desc d;
    d.kind = mfx::Kind::Temporal;
    d.inputWidth = inW;
    d.inputHeight = inH;
    d.outputWidth = outW;
    d.outputHeight = outH;
    d.colorFormat = d.outputFormat = gpu::PixelFormat::Rgba8;
    d.depthFormat = gpu::PixelFormat::R32F;
    d.motionFormat = gpu::PixelFormat::Rg16F;
    d.autoExposure = false;
    REQUIRE_MESSAGE(scaler.configure(dev(), d, &error), error);

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
            gpu::Image color =
                make_data_image(inW, inH, gpu::PixelFormat::Rgba8, in.data(), in.size(), "metalfx-test-color");
            REQUIRE(dev().state(color) == gpu::ResourceState::Valid);
            mfx::Frame f;
            f.color = color;
            f.depth = depthImg;
            f.motion = motion;
            f.output = out.image;
            f.jitterX = s * jx;
            f.jitterY = s * jy;
            f.reset = frame == 0;
            REQUIRE_MESSAGE(scaler.encode(dev(), f, &error), error);
            std::vector<std::uint8_t> got;
            REQUIRE_MESSAGE(read_back(out.image, outW, outH, got, &error), error);
            const double e = mean_diff(got, reference, outW, outH, 4);
            if (frame == 0) first = e;
            if (frame == 15) err[run] = e;
            dev().destroy_image(color);
        }
        MESSAGE(std::string(run == 0 ? "documented jitter sign" : "opposite jitter sign")
                << ": mean error of the first frame " << std::round(first * 10000.0) / 10000.0 << ", after 16 frames "
                << std::round(err[run] * 10000.0) / 10000.0);
        CHECK(scaler.encoded() == 16 * (run + 1));
    }
    CHECK_MESSAGE(err[0] < 0.02, "the converged temporal output is far from the scene: " << err[0]);

    destroy_output(out);
    dev().destroy_image(depthImg);
    dev().destroy_image(motion);
    dev().commit();
}

TEST_CASE("metalfx: a pass that writes the input and a pass that reads the output in the same frame see this frame's "
          "pictures") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    DeviceScope scope;
    if (!can_run(mfx::Kind::Spatial)) return;
    render::Gpu gpu;
    std::string error;
    REQUIRE_MESSAGE(gpu.init(1, &error), error);
    const int inW = 16, inH = 16, outW = 32, outH = 32, frames = 12;

    render::TargetDesc td;
    td.label = "metalfx-test-input";
    td.width = inW;
    td.height = inH;
    td.colorFormat = gpu::PixelFormat::Rgba8;
    render::Target input = render::make_target(gpu.device(), td);
    REQUIRE(input.valid(gpu.device()));
    Output out = make_output(outW, outH, gpu::PixelFormat::Rgba8);
    REQUIRE(dev().state(out.image) == gpu::ResourceState::Valid);
    REQUIRE(dev().state(out.view) == gpu::ResourceState::Valid);
    std::vector<render::Target> shown(frames);
    for (int i = 0; i < frames; ++i) {
        render::TargetDesc sd;
        sd.label = "metalfx-test-shown";
        sd.width = outW;
        sd.height = outH;
        sd.colorFormat = gpu::PixelFormat::Rgba8;
        sd.texture = false;
        shown[std::size_t(i)] = render::make_target(gpu.device(), sd);
        REQUIRE(shown[std::size_t(i)].valid(gpu.device()));
    }

    mfx::Scaler scaler;
    mfx::Desc d;
    d.inputWidth = inW;
    d.inputHeight = inH;
    d.outputWidth = outW;
    d.outputHeight = outH;
    d.colorFormat = d.outputFormat = gpu::PixelFormat::Rgba8;
    d.colorSpace = mfx::ColorSpace::Perceptual;
    REQUIRE_MESSAGE(scaler.configure(dev(), d, &error), error);

    // Every frame: a pass writes a grey of its own into the input, MetalFX scales it, a later pass copies the scaled image. The
    // frames are queued without waiting for the GPU (only the read-back at the end waits), so a scaler that ran behind the passes
    // that follow it, or ahead of the ones before it, shows the grey of the frame before or after: the greys are 8% apart.
    std::vector<float> grey(static_cast<std::size_t>(frames), 0.0f);
    for (int i = 0; i < frames; ++i) grey[std::size_t(i)] = 0.08f + 0.07f * float(i);
    for (int i = 0; i < frames; ++i) {
        gpu::CommandList& list = gpu.commands();
        render::PassDesc p = render::pass_into(input, "metalfx-test-write-input");
        p.colorLoad = gpu::LoadAction::Clear;
        p.clearColor = {grey[std::size_t(i)], grey[std::size_t(i)], grey[std::size_t(i)], 1.0f};
        p.colorStore = gpu::StoreAction::Store;
        list.begin_pass(p);
        list.end_pass();

        mfx::Frame f;
        f.color = input.texture_image();
        f.output = out.image;
        REQUIRE_MESSAGE(scaler.encode(dev(), f, &error), error);

        render::PassDesc q = render::pass_into(shown[std::size_t(i)], "metalfx-test-read-output");
        q.colorLoad = gpu::LoadAction::DontCare;
        q.colorStore = gpu::StoreAction::Store;
        list.begin_pass(q);
        list.set_pipeline(gpu.blit_keep_pipeline(q.format));
        gpu::Bindings b{};
        b.vertexBuffers[0] = gpu.fullscreen_triangle();
        b.views[VIEW_blit_tex] = out.view;
        b.samplers[SMP_blit_smp] = gpu.sampler(render::SamplerKind::Nearest);
        list.set_bindings(b);
        blit_blit_vs_params_t vu{};
        vu.flip[0] = 0.0f;
        list.set_uniforms(UB_blit_blit_vs_params, gpu::Range{&vu, sizeof(vu)});
        blit_blit_fs_params_t fu{};
        list.set_uniforms(UB_blit_blit_fs_params, gpu::Range{&fu, sizeof(fu)});
        list.draw(0, 3, 1);
        list.end_pass();
    }
    dev().commit();
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

    for (render::Target& t : shown) render::destroy_target(gpu.device(), t);
    destroy_output(out);
    render::destroy_target(gpu.device(), input);
    dev().commit();
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
    gpu::Image depthImg =
        make_data_image(inW, inH, gpu::PixelFormat::R32F, depth.data(), depth.size() * 4, "metalfx-test-depth");
    REQUIRE(dev().state(depthImg) == gpu::ResourceState::Valid);
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
        gpu::Image motion =
            make_data_image(inW, inH, gpu::PixelFormat::Rg16F, mv.data(), mv.size() * 2, "metalfx-test-motion");
        REQUIRE(dev().state(motion) == gpu::ResourceState::Valid);
        Output out = make_output(outW, outH, gpu::PixelFormat::Rgba16F);
        mfx::Scaler scaler;
        std::string error;
        mfx::Desc d;
        d.kind = mfx::Kind::Temporal;
        d.inputWidth = inW;
        d.inputHeight = inH;
        d.outputWidth = outW;
        d.outputHeight = outH;
        d.colorFormat = d.outputFormat = gpu::PixelFormat::Rgba16F;
        d.depthFormat = gpu::PixelFormat::R32F;
        d.motionFormat = gpu::PixelFormat::Rg16F;
        d.autoExposure = false;
        REQUIRE_MESSAGE(scaler.configure(dev(), d, &error), error);
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
            gpu::Image color =
                make_data_image(inW, inH, gpu::PixelFormat::Rgba16F, in.data(), in.size() * 2, "metalfx-test-color");
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
            REQUIRE_MESSAGE(scaler.encode(dev(), f, &error), error);
            std::vector<std::uint8_t> got;
            {
                std::vector<float> gf;
                REQUIRE_MESSAGE(read_back_f16(out.image, outW, outH, gf, &error),
                                error);  // commits first (see read_back)
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
            dev().destroy_image(color);
        }
        err[run] = last;
        destroy_output(out);
        dev().destroy_image(motion);
    }
    dev().destroy_image(depthImg);
    dev().commit();
}
}  // namespace

TEST_CASE(
    "metalfx: the temporal scaler follows a moving pattern when the motion points from the pixel to where it was") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    DeviceScope scope;
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
    DeviceScope scope;
    if (!can_run(mfx::Kind::Temporal)) return;
    double err[3] = {1, 1, 1};
    moving_pattern_errors(true, err);
    MESSAGE("vertical motion, mean error after 24 frames: motion = where the pixel was "
            << std::round(err[0] * 10000.0) / 10000.0 << ", opposite " << std::round(err[1] * 10000.0) / 10000.0
            << ", none " << std::round(err[2] * 10000.0) / 10000.0);
    CHECK(err[0] < 0.8 * err[1]);
    CHECK(err[0] < 0.8 * err[2]);
}

namespace {

// A temporal scaler's desc for the 48x32 -> 96x64 RGBA8 frames of the tests below.
mfx::Desc small_temporal_desc(bool reactiveMask) {
    mfx::Desc d;
    d.kind = mfx::Kind::Temporal;
    d.inputWidth = 48;
    d.inputHeight = 32;
    d.outputWidth = 96;
    d.outputHeight = 64;
    d.colorFormat = d.outputFormat = gpu::PixelFormat::Rgba8;
    d.depthFormat = gpu::PixelFormat::R32F;
    d.motionFormat = gpu::PixelFormat::Rg16F;
    d.autoExposure = false;
    d.reactiveMask = reactiveMask;
    return d;
}

// The images of one temporal frame of 48x32 that do not change from frame to frame (no motion, a flat depth, a reactive mask of one value).
struct SmallFrameImages {
    gpu::Image depth{}, motion{}, reactive{}, reactiveWrongSize{};
    explicit SmallFrameImages(std::uint8_t reactiveValue) {
        const int w = 48, h = 32;
        const std::vector<std::uint16_t> noMotion(std::size_t(w) * h * 2, 0);
        const std::vector<float> flat(std::size_t(w) * h, 0.5f);
        const std::vector<std::uint8_t> mask(std::size_t(w) * h, reactiveValue);
        const std::vector<std::uint8_t> small(std::size_t(w / 2) * (h / 2), reactiveValue);
        depth = make_data_image(w, h, gpu::PixelFormat::R32F, flat.data(), flat.size() * 4, "metalfx-test-depth");
        motion =
            make_data_image(w, h, gpu::PixelFormat::Rg16F, noMotion.data(), noMotion.size() * 2, "metalfx-test-motion");
        reactive = make_data_image(w, h, gpu::PixelFormat::R8, mask.data(), mask.size(), "metalfx-test-reactive");
        reactiveWrongSize = make_data_image(w / 2, h / 2, gpu::PixelFormat::R8, small.data(), small.size(),
                                            "metalfx-test-reactive-small");
    }
    ~SmallFrameImages() {
        dev().destroy_image(depth);
        dev().destroy_image(motion);
        dev().destroy_image(reactive);
        dev().destroy_image(reactiveWrongSize);
    }
    SmallFrameImages(const SmallFrameImages&) = delete;
    SmallFrameImages& operator=(const SmallFrameImages&) = delete;
};

// Thin vertical stripes (a period of 2.6 input pixels: detail one frame cannot carry, that the history of a jittered sequence does) that
// jump half a period to the right in the last frame, with no motion told: what the history holds is wrong there. The mean error of the
// last picture against the stripes at their new place, for a frame whose reactive mask is `maskValue` (0..255; -1: the frame hands
// none). `reactiveDesc`: the scaler is made with the mask input.
double changed_scene_error(bool reactiveDesc, int maskValue) {
    const int inW = 48, inH = 32, outW = 96, outH = 64;
    const float period = 2.6f;
    auto stripes = [&](float px, float phase) {
        return std::sin((px - phase) * (6.2831853f / period)) > 0.0f ? 242 : 13;
    };
    SmallFrameImages images(std::uint8_t(std::max(maskValue, 0)));
    Output out = make_output(outW, outH, gpu::PixelFormat::Rgba8);
    mfx::Scaler scaler;
    std::string error;
    REQUIRE_MESSAGE(scaler.configure(dev(), small_temporal_desc(reactiveDesc), &error), error);
    auto halton = [](int i, int base) {
        float f = 1.0f, r = 0.0f;
        for (int n = i; n > 0; n /= base) {
            f /= float(base);
            r += f * float(n % base);
        }
        return r;
    };
    const int converge = 14;
    const float jump = period * 0.5f;
    double result = 1.0;
    for (int frame = 0; frame <= converge; ++frame) {
        const bool last = frame == converge;
        const float phase = last ? jump : 0.0f;
        const float jx = halton(frame % 8 + 1, 2) - 0.5f, jy = halton(frame % 8 + 1, 3) - 0.5f;
        std::vector<std::uint8_t> in(std::size_t(inW) * inH * 4, 255);
        for (int y = 0; y < inH; ++y)
            for (int x = 0; x < inW; ++x) {
                const std::uint8_t v = std::uint8_t(stripes(float(x) + 0.5f + jx, phase));
                std::uint8_t* q = &in[(std::size_t(y) * inW + x) * 4];
                q[0] = q[1] = q[2] = v;
            }
        gpu::Image color =
            make_data_image(inW, inH, gpu::PixelFormat::Rgba8, in.data(), in.size(), "metalfx-test-color");
        mfx::Frame f;
        f.color = color;
        f.depth = images.depth;
        f.motion = images.motion;
        f.output = out.image;
        f.jitterX = -jx;
        f.jitterY = -jy;
        f.reset = frame == 0;
        if (last && maskValue >= 0) f.reactive = images.reactive;
        REQUIRE_MESSAGE(scaler.encode(dev(), f, &error), error);
        if (last) {
            std::vector<std::uint8_t> got;
            REQUIRE_MESSAGE(read_back(out.image, outW, outH, got, &error), error);
            std::vector<std::uint8_t> truth(std::size_t(outW) * outH * 4, 255);
            for (int y = 0; y < outH; ++y)
                for (int x = 0; x < outW; ++x) {
                    const float px = (float(x) + 0.5f) * float(inW) / float(outW);
                    std::uint8_t* q = &truth[(std::size_t(y) * outW + x) * 4];
                    q[0] = q[1] = q[2] = std::uint8_t(stripes(px, phase));
                }
            result = mean_diff(got, truth, outW, outH, 4);
            CHECK(scaler.reactive_encoded() == (maskValue >= 0 && scaler.reactive_mask() ? 1 : 0));
        } else {
            dev().commit();
        }
        dev().destroy_image(color);
    }
    destroy_output(out);
    dev().commit();
    return result;
}

}  // namespace

TEST_CASE(
    "metalfx: a reactive mask given with the frame reaches the temporal scaler and makes it drop its history there") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    DeviceScope scope;
    if (!can_run(mfx::Kind::Temporal)) return;
    {
        mfx::Scaler probe;
        std::string error;
        REQUIRE_MESSAGE(probe.configure(dev(), small_temporal_desc(true), &error), error);
        if (!probe.reactive_mask()) {
            MESSAGE("this OS has no MetalFX reactive mask (it needs macOS 14.4 or iOS 17.4): the scaler is made "
                    "without it, the test is "
                    "skipped");
            return;
        }
    }
    // The scene moves 6 pixels in the last frame and no motion says so: what the history holds there is wrong. A mask of 1 tells MetalFX
    // to ignore the history at those pixels; without a mask it blends the old picture in.
    const double none = changed_scene_error(true, -1);
    const double zero = changed_scene_error(true, 0);
    const double full = changed_scene_error(true, 255);
    const double noInput = changed_scene_error(false, -1);
    MESSAGE("mean error of the frame after a jump of the scene: no mask "
            << std::round(none * 10000.0) / 10000.0 << ", mask 0 " << std::round(zero * 10000.0) / 10000.0
            << ", mask 1 " << std::round(full * 10000.0) / 10000.0 << ", scaler made without the mask input "
            << std::round(noInput * 10000.0) / 10000.0);
    CHECK(full < 0.7 * zero);
    CHECK(full < 0.7 * none);
    // A scaler with the input but a frame without a mask draws as a scaler made without the input (it is made with it from the start,
    // so that the first mask of a game does not make it again): the same picture within what MetalFX changes from run to run.
    CHECK(std::fabs(none - noInput) < 0.002);
    CHECK(std::fabs(zero - none) < 0.002);
}

TEST_CASE("metalfx: the reactive mask is handed over only when the frame has one, the scaler takes one and it fits "
          "(any Metal GPU)") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    DeviceScope scope;
    if (!mfx::on_metal(dev())) {
        MESSAGE("not the Metal backend, the test is skipped");
        return;
    }
    // The scaler draws nothing (no MetalFX needed): what is checked is what the wrapper hands over and refuses.
    mfx::Scaler::TestHooks hooks;
    hooks.emptyBuffers = true;
    SmallFrameImages images(255);
    std::vector<std::uint8_t> px(std::size_t(48) * 32 * 4, 128);
    gpu::Image color = make_data_image(48, 32, gpu::PixelFormat::Rgba8, px.data(), px.size(), "metalfx-test-color");
    Output out = make_output(96, 64, gpu::PixelFormat::Rgba8);
    mfx::Frame f;
    f.color = color;
    f.depth = images.depth;
    f.motion = images.motion;
    f.output = out.image;
    std::string error;

    mfx::Scaler without;
    without.set_test_hooks(hooks);
    REQUIRE_MESSAGE(without.configure(dev(), small_temporal_desc(false), &error), error);
    CHECK_FALSE(without.reactive_mask());
    f.reactive = images.reactive;
    REQUIRE_MESSAGE(without.encode(dev(), f, &error), error);  // a scaler without the input leaves a mask alone
    CHECK(without.reactive_encoded() == 0);

    mfx::Scaler scaler;
    scaler.set_test_hooks(hooks);
    REQUIRE_MESSAGE(scaler.configure(dev(), small_temporal_desc(true), &error), error);
    if (!scaler.reactive_mask()) {
        MESSAGE("this OS has no MetalFX reactive mask (it needs macOS 14.4 or iOS 17.4): the scaler is made without it "
                "and ignores "
                "the mask");
        f.reactive = images.reactive;
        REQUIRE_MESSAGE(scaler.encode(dev(), f, &error), error);
        CHECK(scaler.reactive_encoded() == 0);
    } else {
        f.reactive = gpu::Image{};
        REQUIRE_MESSAGE(scaler.encode(dev(), f, &error), error);  // no mask in this frame
        CHECK(scaler.reactive_encoded() == 0);
        f.reactive = images.reactive;
        REQUIRE_MESSAGE(scaler.encode(dev(), f, &error), error);
        REQUIRE_MESSAGE(scaler.encode(dev(), f, &error), error);
        CHECK(scaler.reactive_encoded() == 2);
        CHECK(scaler.encoded() == 3);
        f.reactive = images.reactiveWrongSize;  // a mask of another size is refused, and no work is done
        CHECK_FALSE(scaler.encode(dev(), f, &error));
        CHECK(error.find("Frame.reactive") != std::string::npos);
        CHECK(scaler.encoded() == 3);
        f.reactive = color;  // an RGBA8 image is not an R8 mask
        CHECK_FALSE(scaler.encode(dev(), f, &error));
        CHECK(error.find("Frame.reactive") != std::string::npos);
        CHECK(scaler.reactive_encoded() == 2);
    }
    CHECK(scaler.test_wait_signalled(10000));  // every buffer was released
    scaler.release();
    without.release();
    destroy_output(out);
    dev().destroy_image(color);
    dev().commit();
}

TEST_CASE(
    "metalfx: a command buffer that fails still releases the passes behind it, and the failure is reported (any Metal "
    "GPU)") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    DeviceScope scope;
    if (!mfx::on_metal(dev())) {
        MESSAGE("not the Metal backend, the test is skipped");
        return;
    }
    // The scaler's buffer is made to end as a failed one does: its completion handler reports an error and the buffer does not signal the
    // event itself. The sokol buffer of the passes after the scaler waits for that event: if the handler did not raise it, the GPU would
    // stall for ever, so every wait here has a limit and the test fails (and lets the queue go on) instead of hanging.
    SmallFrameImages images(0);
    std::vector<std::uint8_t> px(std::size_t(48) * 32 * 4, 128);
    gpu::Image color = make_data_image(48, 32, gpu::PixelFormat::Rgba8, px.data(), px.size(), "metalfx-test-color");
    Output out = make_output(96, 64, gpu::PixelFormat::Rgba8);
    mfx::Frame f;
    f.color = color;
    f.depth = images.depth;
    f.motion = images.motion;
    f.output = out.image;
    std::string error;
    auto wait_failed = [](mfx::Scaler& s,
                          std::string* why) {  // the flag is set on Metal's thread, a moment after the event
        for (int i = 0; i < 5000; ++i) {
            if (s.command_failed(why)) return true;
            std::this_thread::sleep_for(std::chrono::milliseconds(1));
        }
        return false;
    };

    // The control: a buffer that works signals, and reports nothing.
    {
        mfx::Scaler::TestHooks h;
        h.emptyBuffers = true;
        mfx::Scaler ok;
        ok.set_test_hooks(h);
        REQUIRE_MESSAGE(ok.configure(dev(), small_temporal_desc(false), &error), error);
        REQUIRE_MESSAGE(ok.encode(dev(), f, &error), error);
        CHECK(ok.test_wait_signalled(10000));
        std::this_thread::sleep_for(std::chrono::milliseconds(20));
        CHECK_FALSE(ok.command_failed(nullptr));
        dev().commit();
    }

    mfx::Scaler::TestHooks h;
    h.emptyBuffers = true;
    h.failBuffers = true;
    mfx::Scaler scaler;
    scaler.set_test_hooks(h);
    REQUIRE_MESSAGE(scaler.configure(dev(), small_temporal_desc(false), &error), error);
    for (int round = 0; round < 3; ++round) {  // the queue goes on after a failure: later frames are released too
        REQUIRE_MESSAGE(scaler.encode(dev(), f, &error), error);
        REQUIRE_MESSAGE(scaler.test_wait_signalled(10000),
                        "the failed buffer's completion handler did not raise the event (round "
                            << round << "): the passes behind it would wait for ever");
        std::string why;
        REQUIRE_MESSAGE(wait_failed(scaler, &why), "the failure was not reported (round " << round << ")");
        CHECK(why.find("test hook") != std::string::npos);
        // The sokol buffer behind the scaler runs: a read back of the output goes through the queue after it.
        std::vector<std::uint8_t> got;
        REQUIRE_MESSAGE(read_back(out.image, 96, 64, got, &error), error);
        CHECK(got.size() == std::size_t(96) * 64 * 4);
    }
    scaler.release();
    CHECK_FALSE(scaler.command_failed(nullptr));  // a new scaler starts clear
    destroy_output(out);
    dev().destroy_image(color);
    dev().commit();
}

#else

TEST_CASE("metalfx: the Metal tests") { MESSAGE("MetalFX exists on the Metal backend only: this build skips them"); }

#endif
