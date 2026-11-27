// M79-P1n: the renderer's own spatio-temporal denoiser (src/rt_denoise.cpp, shaders/rt_denoise.glsl) on the host GPU path. The passes run
// on small synthetic inputs (a flat plane at a known depth, noise of a known variance), so every number a test compares has a known
// right answer: the signal's truth. The thresholds are explained next to each check; they run on every backend (Metal, D3D11, GL on
// llvmpipe), with images of 16-bit floats.
#include "test_util.h"

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <cstring>
#include <memory>
#include <string>
#include <vector>

#include "frame_graph.h"
#include "render_internal.h"
#include "rt_denoise.h"
#include "transient_targets.h"

using namespace fa;
using namespace fa::test;
using render::DenoiseCamera;
using render::DenoiseDebug;
using render::DenoiseKind;
using render::DenoisePlan;
using render::DenoiseReset;
using render::DenoiseSignal;

namespace {

constexpr int kW = 64, kH = 48;

// Noise that depends on nothing but its three numbers: the same frame always has the same picture.
float rnd(std::uint32_t a, std::uint32_t b, std::uint32_t c) {
    std::uint32_t h = a * 0x9E3779B1u ^ (b + 0x7F4A7C15u) * 0x85EBCA6Bu ^ (c + 0x165667B1u) * 0xC2B2AE35u;
    h ^= h >> 15;
    h *= 0x2C1B3C6Du;
    h ^= h >> 12;
    h *= 0x297A2D39u;
    h ^= h >> 15;
    return float(h >> 8) * (1.0f / 16777216.0f);
}

struct Tex {
    gpu::Image image{};
    gpu::View view{};
    int w = 0, h = 0;
    std::vector<float>
        rows;  // what the image holds, as the backend wants it (written again every frame: a write-transient image lives one)
};

struct Frame {
    std::vector<float> color;  // the denoised image, RGBA, top row first
    std::vector<float> debug;  // the debug view, when asked
    render::DenoiseOutput out;
    Json graph;  // the compiled graph of the frame (passes with the names of what they read and write)
    int drawCalls = 0;
    bool read = false;
};

// One GPU of its own with the pool and the denoiser of a test.
struct Rig {
    render::Gpu gpu;
    std::unique_ptr<render::TransientTargets> pool;
    render::RtDenoiser dn;
    std::vector<Tex> textures;
    bool ok = false;
    std::string error;

    Rig() {
        ok = gpu.init(1, &error);
        if (ok) pool = std::make_unique<render::TransientTargets>(gpu.device());
    }
    ~Rig() {
        if (!ok) return;
        dn.release();
        pool.reset();
        for (Tex& t : textures) {
            gpu.device().destroy_view(t.view);
            gpu.device().destroy_image(t.image);
        }
        gpu.shutdown();
    }
    Rig(const Rig&) = delete;
    Rig& operator=(const Rig&) = delete;

    // An RGBA32F image of `w` x `h` the test rewrites every frame.
    size_t make_tex(int w, int h) {
        gpu::ImageDesc d{};
        d.usage.writeTransient = true;
        d.width = w;
        d.height = h;
        d.pixelFormat = gpu::PixelFormat::Rgba32F;
        d.label = "rtd-test";
        Tex t;
        t.w = w;
        t.h = h;
        t.image = gpu.device().make_image(d);
        gpu::ViewDesc vd{};
        vd.texture.image = t.image;
        vd.label = "rtd-test";
        t.view = gpu.device().make_view(vd);
        textures.push_back(t);
        return textures.size() - 1;
    }
    // `rgba`: w*h*4 floats, the picture's top row first (an OpenGL render target keeps its rows bottom-up: reversed here).
    void upload(size_t i, const std::vector<float>& rgba) {
        const Tex& t = textures[i];
        std::vector<float> rows(rgba.size());
        const size_t stride = size_t(t.w) * 4;
        for (int y = 0; y < t.h; ++y) {
            const int src = gpu.is_gl() ? t.h - 1 - y : y;
            std::copy(rgba.begin() + size_t(src) * stride, rgba.begin() + size_t(src + 1) * stride,
                      rows.begin() + size_t(y) * stride);
        }
        textures[i].rows = std::move(rows);
    }
    // Writes every image the test gave, once per frame (one begin_transient_writes opens the frame's writes).
    void write_all() {
        gpu.begin_transient_writes();
        for (const Tex& t : textures) {
            if (t.rows.empty()) continue;
            gpu::ImageWrite wr{};
            wr.data = gpu::Range{t.rows.data(), t.rows.size() * sizeof(float)};
            wr.dst.image = t.image;
            wr.size.width = t.w;
            wr.size.height = t.h;
            gpu.commands().write_image(wr);
        }
    }

    std::vector<float> read(const render::Target& t, int w, int h) {
        std::vector<float> px;
        const auto r = gpu.device().read_image_rgba16f(t.texture_image(), w, h, px);
        return r.ok() ? px : std::vector<float>{};
    }

    // Declares the signal in a graph of its own, runs it and reads the denoised image (and the debug picture).
    Frame run(const DenoiseCamera& cam, const DenoiseSignal& sig, size_t noisy, size_t prepass, int w, int h,
              int velocity = -1, int roughness = -1) {
        Frame f;
        pool->pool.begin_frame();
        write_all();
        render::FrameGraph graph;
        render::DenoiseInputs in;
        in.noisy.view = textures[noisy].view;
        in.prepass.view = textures[prepass].view;
        if (velocity >= 0) in.velocity.view = textures[size_t(velocity)].view;
        if (roughness >= 0) in.roughness.view = textures[size_t(roughness)].view;
        in.width = w;
        in.height = h;
        f.out = dn.add_passes(graph, *pool, gpu, cam, sig, in, &f.drawCalls, "rig");
        render::Target cap, capDbg;
        render::TransientTargets* tt = pool.get();
        if (f.out.valid) {
            render::GraphPass rp;
            rp.name = "rig/capture";
            rp.reads = {f.out.res};
            if (f.out.debug.valid()) rp.reads.push_back(f.out.debug);
            rp.sideEffect = true;
            const render::DenoiseOutput out = f.out;
            rp.execute = [&cap, &capDbg, out, tt](const render::PassContext& c) {
                if (const render::Target* t = out.target(c, *tt)) cap = *t;
                if (out.debug.valid())
                    if (const render::Target* t = out.debug_target(c, *tt)) capDbg = *t;
            };
            graph.add_pass(std::move(rp));
        }
        const auto compiled = graph.compile();
        REQUIRE_MESSAGE(compiled.ok(), (compiled.ok() ? std::string() : compiled.error().message));
        f.graph = graph.to_json();
        const auto ran = graph.execute(pool->pool, &gpu.commands());
        REQUIRE_MESSAGE(ran.ok(), (ran.ok() ? std::string() : ran.error().message));
        gpu.commit_frame();
        if (f.out.valid) {
            f.color = read(cap, w, h);
            if (f.out.debug.valid()) f.debug = read(capDbg, w, h);
            f.read = f.color.size() == size_t(w) * size_t(h) * 4;
        }
        return f;
    }
};

DenoiseCamera make_camera(int w, int h, std::uint64_t serial, bool prevValid = true) {
    DenoiseCamera c;
    const Mat4 P = Mat4::perspective(90.0f, float(w) / float(h), 0.1f, 100.0f, true);
    const float terms[8] = {P.at(0, 0), P.at(1, 1), P.at(2, 0), P.at(2, 1),
                            P.at(3, 0), P.at(3, 1), P.at(2, 3), P.at(3, 3)};
    for (int i = 0; i < 8; ++i) c.proj[i] = terms[i];
    c.halfX = 1.0f / std::fabs(P.at(0, 0));
    c.halfY = 1.0f / std::fabs(P.at(1, 1));
    c.prevFromView = P;  // the view is the identity and the camera does not move
    c.prevValid = prevValid;
    c.camKey = 7;
    c.serial = serial;
    c.sceneKey = 1;
    return c;
}

// A prepass of the whole picture: `depth(x, y)` (a value <= 0: no mesh there) and the octahedral normal `oct(x, y)`.
template <class D, class N>
std::vector<float> make_prepass(int w, int h, D depth, N oct) {
    std::vector<float> px(size_t(w) * size_t(h) * 4);
    for (int y = 0; y < h; ++y)
        for (int x = 0; x < w; ++x) {
            float* p = &px[(size_t(y) * size_t(w) + size_t(x)) * 4];
            const float d = depth(x, y);
            const auto e = oct(x, y);
            p[0] = d > 0 ? d : 60000.0f;
            p[1] = d > 0 ? e.first : 0.0f;
            p[2] = d > 0 ? e.second : 0.0f;
            p[3] = d > 0 ? 1.0f : 0.0f;
        }
    return px;
}
std::pair<float, float> facing(int, int) { return {0.0f, 0.0f}; }  // the octahedral code of the normal (0, 0, 1)

// The mean absolute error of channel `ch` over [x0, x1) x [y0, y1) against `truth(x, y)`.
template <class T>
double mae(const std::vector<float>& img, int w, int x0, int y0, int x1, int y1, int ch, T truth) {
    double sum = 0;
    int n = 0;
    for (int y = y0; y < y1; ++y)
        for (int x = x0; x < x1; ++x) {
            sum += std::fabs(double(img[(size_t(y) * size_t(w) + size_t(x)) * 4 + size_t(ch)]) - double(truth(x, y)));
            ++n;
        }
    return n ? sum / n : 0.0;
}
float at(const std::vector<float>& img, int w, int x, int y, int ch = 0) {
    return img[(size_t(y) * size_t(w) + size_t(x)) * 4 + size_t(ch)];
}

// The noisy picture of a one-channel signal: 1 with the probability truth(x, y), else 0 (variance truth * (1 - truth)).
template <class T>
std::vector<float> bernoulli(int w, int h, std::uint32_t frame, T truth) {
    std::vector<float> px(size_t(w) * size_t(h) * 4, 0.0f);
    for (int y = 0; y < h; ++y)
        for (int x = 0; x < w; ++x) {
            const float v = rnd(frame, std::uint32_t(x), std::uint32_t(y)) < truth(x, y) ? 1.0f : 0.0f;
            float* p = &px[(size_t(y) * size_t(w) + size_t(x)) * 4];
            p[0] = p[1] = p[2] = v;
            p[3] = 1.0f;
        }
    return px;
}

DenoiseSignal visibility() {
    DenoiseSignal s;
    s.kind = DenoiseKind::Visibility;
    s.id = 1;
    return s;
}

}  // namespace

TEST_CASE("denoise: a noisy visibility converges to its truth and the first frame already beats the raw noise") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    Rig rig;
    REQUIRE_MESSAGE(rig.ok, rig.error);
    const size_t noisy = rig.make_tex(kW, kH), pre = rig.make_tex(kW, kH);
    // A flat plane facing the camera, 5 units away; the right quarter is sky (no mesh): it must come out as it went in.
    rig.upload(pre, make_prepass(kW, kH, [](int x, int) { return x < 48 ? 5.0f : 0.0f; }, facing));
    const auto truth = [](int, int) { return 0.3f; };
    const DenoiseSignal sig = visibility();
    double firstError = 0, lastError = 0, rawError = 0;
    Frame last;
    for (int f = 1; f <= 24; ++f) {
        const std::vector<float> in = bernoulli(kW, kH, std::uint32_t(f), truth);
        rig.upload(noisy, in);
        last = rig.run(make_camera(kW, kH, std::uint64_t(f)), sig, noisy, pre, kW, kH);
        REQUIRE(last.out.valid);
        REQUIRE(last.read);
        if (f == 1) {
            CHECK(last.out.reset == DenoiseReset::Fresh);
            firstError = mae(last.color, kW, 4, 4, 44, 44, 0, truth);
            rawError = mae(in, kW, 4, 4, 44, 44, 0, truth);
        } else {
            CHECK(last.out.reset == DenoiseReset::None);
        }
    }
    lastError = mae(last.color, kW, 4, 4, 44, 44, 0, truth);
    INFO("raw " << rawError << ", first frame " << firstError << ", after 24 frames " << lastError);
    // A Bernoulli(0.3) sample is 0.3 off in expectation (2 * 0.3 * 0.7 = 0.42 mean absolute error). The temporal mean of 24 frames alone has a
    // standard deviation of sqrt(0.21 / 24) = 0.094 (mean absolute error 0.075); the filter on top takes it well under half of that.
    CHECK(rawError > 0.38);
    CHECK(firstError < 0.10);  // measured 0.047 on Metal: five spatial iterations of a single frame
    CHECK(lastError < 0.025);  // measured 0.013
    // The three colour channels carry the same value, the sky passes through untouched.
    CHECK(at(last.color, kW, 20, 20, 0) == doctest::Approx(at(last.color, kW, 20, 20, 2)).epsilon(1e-3));
    for (int y = 4; y < 44; ++y)
        for (int x = 52; x < 60; ++x) {
            const float v = at(last.color, kW, x, y, 0);
            const float raw = rnd(24, std::uint32_t(x), std::uint32_t(y)) < 0.3f ? 1.0f : 0.0f;
            REQUIRE(v == doctest::Approx(raw).epsilon(1e-3));
        }
    CHECK(rig.dn.last_used_history(7, 1));
    CHECK(rig.dn.resets() == 1);
}

TEST_CASE("denoise: a diffuse radiance of three channels converges and keeps its colour") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    Rig rig;
    REQUIRE_MESSAGE(rig.ok, rig.error);
    const size_t noisy = rig.make_tex(kW, kH), pre = rig.make_tex(kW, kH);
    rig.upload(pre, make_prepass(kW, kH, [](int, int) { return 4.0f; }, facing));
    DenoiseSignal sig;
    sig.kind = DenoiseKind::Diffuse;
    const float truthRgb[3] = {0.8f, 0.4f, 0.1f};
    Frame last;
    for (int f = 1; f <= 20; ++f) {
        std::vector<float> in(size_t(kW) * kH * 4, 1.0f);
        for (int y = 0; y < kH; ++y)
            for (int x = 0; x < kW; ++x)
                for (int c = 0; c < 3;
                     ++c)  // uniform in [0, 2 * truth]: the mean is the truth, the deviation truth / sqrt(3)
                    in[(size_t(y) * kW + size_t(x)) * 4 + size_t(c)] =
                        2.0f * truthRgb[c] *
                        rnd(std::uint32_t(f) * 3 + std::uint32_t(c), std::uint32_t(x), std::uint32_t(y));
        rig.upload(noisy, in);
        last = rig.run(make_camera(kW, kH, std::uint64_t(f)), sig, noisy, pre, kW, kH);
        REQUIRE(last.read);
    }
    for (int c = 0; c < 3; ++c) {
        const double e = mae(last.color, kW, 4, 4, 60, 44, c, [&](int, int) { return truthRgb[c]; });
        INFO("channel " << c << " error " << e);
        // The raw error of a channel is truth * 0.5 (mean absolute deviation of a uniform [0, 2t]); the result is under a tenth of that.
        CHECK(e < 0.05 * 0.5 * truthRgb[c] + 0.003);  // measured 0.004, 0.003, 0.0007
    }
}

TEST_CASE("denoise: the filter does not blur across a depth edge or a normal edge") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    for (int variant = 0; variant < 2; ++variant) {
        INFO((variant == 0 ? "depth edge" : "normal edge"));
        Rig rig;
        REQUIRE_MESSAGE(rig.ok, rig.error);
        const size_t noisy = rig.make_tex(kW, kH), pre = rig.make_tex(kW, kH);
        // Two surfaces side by side with different truths: 0.1 on the left, 0.9 on the right. One is 5 units away, the other 12 (a depth
        // edge) or the same 5 but turned 45 degrees (a normal edge).
        if (variant == 0)
            rig.upload(pre, make_prepass(kW, kH, [](int x, int) { return x < 32 ? 5.0f : 12.0f; }, facing));
        else
            rig.upload(
                pre, make_prepass(
                         kW, kH, [](int, int) { return 5.0f; },
                         [](int x, int) { return x < 32 ? std::make_pair(0.0f, 0.0f) : std::make_pair(0.5f, 0.0f); }));
        const auto truth = [](int x, int) { return x < 32 ? 0.1f : 0.9f; };
        DenoiseSignal sig = visibility();
        Frame last;
        for (int f = 1; f <= 12; ++f) {
            rig.upload(noisy, bernoulli(kW, kH, std::uint32_t(f), truth));
            last = rig.run(make_camera(kW, kH, std::uint64_t(f)), sig, noisy, pre, kW, kH);
            REQUIRE(last.read);
        }
        // Next to the edge, on both sides, the value is still its own side's: within 0.06 of the truth (across the edge it would be 0.5).
        const double left = mae(last.color, kW, 28, 8, 32, 40, 0, truth),
                     right = mae(last.color, kW, 32, 8, 36, 40, 0, truth);
        INFO("left of the edge " << left << ", right " << right);
        CHECK(left < 0.06);  // measured 0.018
        CHECK(right < 0.06);
        CHECK(mae(last.color, kW, 4, 8, 24, 40, 0, truth) < 0.05);
        CHECK(mae(last.color, kW, 40, 8, 60, 40, 0, truth) < 0.05);
    }
}

TEST_CASE("denoise: a pixel that shows another surface starts a new history (disocclusion)") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    Rig rig;
    REQUIRE_MESSAGE(rig.ok, rig.error);
    const size_t noisy = rig.make_tex(kW, kH), pre = rig.make_tex(kW, kH), pre2 = rig.make_tex(kW, kH);
    rig.upload(pre, make_prepass(kW, kH, [](int, int) { return 5.0f; }, facing));
    // From frame 11 on, a closer object (depth 3) covers a block of the picture.
    const auto block = [](int x, int y) { return x >= 24 && x < 40 && y >= 16 && y < 32; };
    rig.upload(pre2, make_prepass(kW, kH, [&](int x, int y) { return block(x, y) ? 3.0f : 5.0f; }, facing));
    DenoiseSignal sig = visibility();
    sig.debug = DenoiseDebug::HistoryLength;
    const auto truth = [&](int x, int y) { return block(x, y) ? 0.8f : 0.2f; };
    Frame last;
    for (int f = 1; f <= 14; ++f) {
        rig.upload(noisy,
                   bernoulli(kW, kH, std::uint32_t(f), [&](int x, int y) { return f > 10 ? truth(x, y) : 0.2f; }));
        last = rig.run(make_camera(kW, kH, std::uint64_t(f)), sig, noisy, f > 10 ? pre2 : pre, kW, kH);
        REQUIRE(last.read);
        REQUIRE(last.debug.size() == last.color.size());
        if (f == 10) {
            CHECK(at(last.debug, kW, 30, 20) ==
                  doctest::Approx(10.0f / 32.0f).epsilon(0.02));  // the history length 10 of 32
        }
        if (f == 11) {
            // The block is new: its history length is 1 (1 / 32), the rest went on to 11.
            CHECK(at(last.debug, kW, 30, 20) == doctest::Approx(1.0f / 32.0f).epsilon(0.05));
            CHECK(at(last.debug, kW, 8, 8) == doctest::Approx(11.0f / 32.0f).epsilon(0.02));
        }
    }
    // After three more frames the block has a history of 4 frames, its own, and its colour is its own truth (0.8), not the 0.2 it replaced.
    CHECK(at(last.debug, kW, 30, 20) == doctest::Approx(4.0f / 32.0f).epsilon(0.05));
    const double inBlock = mae(last.color, kW, 26, 18, 38, 30, 0, [](int, int) { return 0.8f; });
    INFO("error inside the new block " << inBlock);
    CHECK(inBlock < 0.08);  // measured 0.025
    CHECK(mae(last.color, kW, 4, 4, 20, 12, 0, [](int, int) { return 0.2f; }) < 0.06);
}

TEST_CASE(
    "denoise: the history is dropped on a cut, a resize, an origin shift, another scene, a gap and a settings change") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    Rig rig;
    REQUIRE_MESSAGE(rig.ok, rig.error);
    const int w = 16, h = 16, w2 = 20;
    const size_t noisy = rig.make_tex(w, h), pre = rig.make_tex(w, h), noisy2 = rig.make_tex(w2, h),
                 pre2 = rig.make_tex(w2, h);
    rig.upload(pre, make_prepass(w, h, [](int, int) { return 5.0f; }, facing));
    rig.upload(pre2, make_prepass(w2, h, [](int, int) { return 5.0f; }, facing));
    DenoiseSignal sig = visibility();
    sig.debug = DenoiseDebug::HistoryLength;
    int frame = 0;
    auto step = [&](std::uint64_t serial, bool prevValid, std::uint64_t shifts, std::uint64_t scene,
                    const DenoiseSignal& s, bool resized = false) {
        ++frame;
        DenoiseCamera c = make_camera(resized ? w2 : w, h, serial, prevValid);
        c.originShifts = shifts;
        c.sceneKey = scene;
        const int ww = resized ? w2 : w;
        rig.upload(resized ? noisy2 : noisy, bernoulli(ww, h, std::uint32_t(frame), [](int, int) { return 0.5f; }));
        return rig.run(c, s, resized ? noisy2 : noisy, resized ? pre2 : pre, ww, h);
    };
    auto length = [&](const Frame& f, int ww) { return at(f.debug, ww, 8, 8) * 32.0f; };
    Frame f = step(1, true, 0, 1, sig);
    CHECK(f.out.reset == DenoiseReset::Fresh);
    CHECK(length(f, w) == doctest::Approx(1.0f).epsilon(0.03));
    f = step(2, true, 0, 1, sig);
    CHECK(f.out.reset == DenoiseReset::None);
    CHECK(length(f, w) == doctest::Approx(2.0f).epsilon(0.03));
    f = step(3, true, 1, 1, sig);  // the floating origin moved
    CHECK(f.out.reset == DenoiseReset::Origin);
    CHECK(length(f, w) == doctest::Approx(1.0f).epsilon(0.03));
    f = step(4, true, 1, 1, sig);
    CHECK(f.out.reset == DenoiseReset::None);
    f = step(5, false, 1, 1, sig);  // a camera cut
    CHECK(f.out.reset == DenoiseReset::Cut);
    CHECK(length(f, w) == doctest::Approx(1.0f).epsilon(0.03));
    f = step(6, true, 1, 1, sig);
    CHECK(f.out.reset == DenoiseReset::None);
    f = step(7, true, 1, 2, sig);  // another scene
    CHECK(f.out.reset == DenoiseReset::Scene);
    f = step(8, true, 1, 2, sig);
    CHECK(f.out.reset == DenoiseReset::None);
    f = step(10, true, 1, 2, sig);  // a frame the signal did not run in
    CHECK(f.out.reset == DenoiseReset::Gap);
    f = step(11, true, 1, 2, sig);
    CHECK(f.out.reset == DenoiseReset::None);
    DenoiseSignal other = sig;
    other.settings.maxHistory = 16.0f;
    f = step(12, true, 1, 2, other);  // another setting: the numbers the history holds mean something else
    CHECK(f.out.reset == DenoiseReset::Settings);
    f = step(13, true, 1, 2, other);
    CHECK(f.out.reset == DenoiseReset::None);
    DenoiseSignal fewer = other;
    fewer.settings.iterations = 3;  // the iterations only change the filter: the history holds
    fewer.debug = DenoiseDebug::Variance;
    f = step(14, true, 1, 2, fewer);
    CHECK(f.out.reset == DenoiseReset::None);
    f = step(15, true, 1, 2, other, true);  // the image has another size
    CHECK(f.out.reset == DenoiseReset::Resize);
    CHECK(length(f, w2) == doctest::Approx(2.0f).epsilon(0.03));  // 1 of a maximum of 16, shown against 32
    f = step(16, true, 1, 2, other, true);
    CHECK(f.out.reset == DenoiseReset::None);
    CHECK(rig.dn.resets() == 7);  // the first frame, then the six above
}

TEST_CASE("denoise: the same inputs give the same output bytes") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    std::vector<float> runs[2];
    for (int run = 0; run < 2; ++run) {
        Rig rig;
        REQUIRE_MESSAGE(rig.ok, rig.error);
        const size_t noisy = rig.make_tex(kW, kH), pre = rig.make_tex(kW, kH);
        rig.upload(pre, make_prepass(kW, kH, [](int x, int) { return x < 32 ? 5.0f : 9.0f; }, facing));
        DenoiseSignal sig;
        sig.kind = DenoiseKind::Specular;
        sig.id = 3;
        for (int f = 1; f <= 6; ++f) {
            std::vector<float> in(size_t(kW) * kH * 4, 0.0f);
            for (int y = 0; y < kH; ++y)
                for (int x = 0; x < kW; ++x) {
                    float* p = &in[(size_t(y) * kW + size_t(x)) * 4];
                    for (int c = 0; c < 3; ++c)
                        p[c] = 2.0f * rnd(std::uint32_t(f * 3 + c), std::uint32_t(x), std::uint32_t(y));
                    p[3] = 4.0f;
                }
            rig.upload(noisy, in);
            const Frame fr = rig.run(make_camera(kW, kH, std::uint64_t(f)), sig, noisy, pre, kW, kH);
            REQUIRE(fr.read);
            if (f == 6) runs[run] = fr.color;
        }
    }
    REQUIRE(runs[0].size() == size_t(kW) * kH * 4);
    CHECK(std::memcmp(runs[0].data(), runs[1].data(), runs[0].size() * sizeof(float)) == 0);
}

TEST_CASE("denoise: a firefly is clamped and a NaN does not spread") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    for (int clamp = 0; clamp < 2; ++clamp) {
        Rig rig;
        REQUIRE_MESSAGE(rig.ok, rig.error);
        const size_t noisy = rig.make_tex(kW, kH), pre = rig.make_tex(kW, kH);
        rig.upload(pre, make_prepass(kW, kH, [](int, int) { return 4.0f; }, facing));
        std::vector<float> in(size_t(kW) * kH * 4, 0.5f);
        for (size_t i = 3; i < in.size(); i += 4) in[i] = 1.0f;
        in[(size_t(24) * kW + 30) * 4] = 1000.0f;  // a firefly
        in[(size_t(24) * kW + 30) * 4 + 1] = 1000.0f;
        in[(size_t(24) * kW + 30) * 4 + 2] = 1000.0f;
        in[(size_t(10) * kW + 10) * 4] = std::nanf("");  // a NaN
        rig.upload(noisy, in);
        DenoiseSignal sig;
        sig.kind = DenoiseKind::Diffuse;
        sig.settings.fireflyClamp = clamp ? 8.0f : 0.0f;
        const Frame f = rig.run(make_camera(kW, kH, 1), sig, noisy, pre, kW, kH);
        REQUIRE(f.read);
        float mx = 0;
        bool finite = true;
        for (size_t i = 0; i < f.color.size(); ++i) {
            if (!std::isfinite(f.color[i])) finite = false;
            if (i % 4 != 3) mx = std::max(mx, f.color[i]);
        }
        INFO("clamp " << clamp << ": the brightest value is " << mx);
        CHECK(finite);
        if (clamp)
            CHECK(mx < 6.0f);  // 8 times the neighbours' mean (0.5) is 4; the filter only lowers that
        else
            CHECK(mx > 6.0f);
    }
}

TEST_CASE("denoise: a specular signal follows the lobe: a mirror keeps its image, a rough surface is filtered") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    double err[2] = {0, 0};
    for (int rough = 0; rough < 2; ++rough) {
        Rig rig;
        REQUIRE_MESSAGE(rig.ok, rig.error);
        const size_t noisy = rig.make_tex(kW, kH), pre = rig.make_tex(kW, kH), rr = rig.make_tex(kW, kH);
        rig.upload(pre, make_prepass(kW, kH, [](int, int) { return 4.0f; }, facing));
        std::vector<float> rv(size_t(kW) * kH * 4, rough ? 1.0f : 0.0f);
        rig.upload(rr, rv);
        DenoiseSignal sig;
        sig.kind = DenoiseKind::Specular;
        sig.id = 2;
        Frame last;
        for (int f = 1; f <= 6; ++f) {
            std::vector<float> in(size_t(kW) * kH * 4, 0.0f);
            for (int y = 0; y < kH; ++y)
                for (int x = 0; x < kW; ++x) {
                    float* p = &in[(size_t(y) * kW + size_t(x)) * 4];
                    for (int c = 0; c < 3; ++c)
                        p[c] = 1.0f * rnd(std::uint32_t(f * 3 + c), std::uint32_t(x), std::uint32_t(y));  // mean 0.5
                    p[3] = 6.0f;  // the reflected surface is 6 units behind
                }
            rig.upload(noisy, in);
            last = rig.run(make_camera(kW, kH, std::uint64_t(f)), sig, noisy, pre, kW, kH, -1, int(rr));
            REQUIRE(last.read);
        }
        err[rough] = mae(last.color, kW, 4, 4, 60, 44, 0, [](int, int) { return 0.5f; });
    }
    INFO("mirror " << err[0] << ", rough " << err[1]);
    // The mirror is accumulated over time only (6 frames of a uniform [0, 1]: mean absolute error about 0.06); the rough surface is filtered in
    // space as well, so it is far closer to the mean. The mirror's lobe has no width: the spatial filter must not have touched it.
    CHECK(err[0] > 0.06);          // measured 0.09 (the mean of 6 frames: 0.289 / sqrt(6) * 0.8)
    CHECK(err[1] < 0.1 * err[0]);  // measured 0.002
}

TEST_CASE("denoise: nothing exists until a signal asks, a disabled signal is free and drops its history") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    Rig rig;
    REQUIRE_MESSAGE(rig.ok, rig.error);
    const size_t noisy = rig.make_tex(kW, kH), pre = rig.make_tex(kW, kH);
    rig.upload(pre, make_prepass(kW, kH, [](int, int) { return 5.0f; }, facing));
    rig.upload(noisy, bernoulli(kW, kH, 1, [](int, int) { return 0.5f; }));
    CHECK_FALSE(rig.dn.shaders_made());
    CHECK(rig.dn.pipeline_count() == 0);
    CHECK(rig.dn.history_image_count() == 0);

    // A disabled signal (a vendor denoiser has it): no pass, no shader, no image.
    {
        DenoiseSignal off = visibility();
        off.enabled = false;
        render::FrameGraph graph;
        render::DenoiseInputs in;
        in.noisy.view = rig.textures[noisy].view;
        in.prepass.view = rig.textures[pre].view;
        in.width = kW;
        in.height = kH;
        const render::DenoiseOutput o =
            rig.dn.add_passes(graph, *rig.pool, rig.gpu, make_camera(kW, kH, 1), off, in, nullptr, "rig");
        CHECK_FALSE(o.valid);
        REQUIRE(graph.compile().ok());
        CHECK(graph.order_names().empty());
        CHECK_FALSE(rig.dn.shaders_made());
        CHECK(rig.dn.history_image_count() == 0);
    }
    // One signal: the camera's guide pass, the temporal pass and the five iterations; two guide images and four of the signal.
    DenoiseSignal a = visibility();
    a.id = 1;
    Frame fa = rig.run(make_camera(kW, kH, 1), a, noisy, pre, kW, kH);
    REQUIRE(fa.out.valid);
    CHECK(fa.out.passes == 1 + 1 + 5);
    CHECK(fa.drawCalls == 1 + 1 + 5);
    CHECK(rig.dn.shaders_made());
    CHECK(rig.dn.history_image_count() == 2 + 4);
    // A second signal of the same camera shares the guide pass and the guide images.
    DenoiseSignal b = visibility();
    b.id = 2;
    b.kind = DenoiseKind::Occlusion;
    b.settings.iterations = 3;
    Frame fb = rig.run(make_camera(kW, kH, 2), b, noisy, pre, kW, kH);
    REQUIRE(fb.out.valid);
    CHECK(fb.out.passes == 1 + 1 + 3);
    CHECK(rig.dn.history_image_count() == 2 + 4 + 4);
    // Switching a signal off frees its images at once; the other keeps its own and the camera's.
    DenoiseSignal bOff = b;
    bOff.enabled = false;
    Frame fo = rig.run(make_camera(kW, kH, 3), bOff, noisy, pre, kW, kH);
    CHECK_FALSE(fo.out.valid);
    CHECK(rig.dn.history_image_count() == 2 + 4);
    // A camera that stops asking is swept.
    rig.dn.sweep(10);
    CHECK(rig.dn.history_image_count() == 0);
    // A history that does not fit the budget is refused with a reason, and nothing stays allocated.
    rig.dn.set_budget(1000);
    Frame fr = rig.run(make_camera(kW, kH, 11), a, noisy, pre, kW, kH);
    CHECK_FALSE(fr.out.valid);
    CHECK(fr.out.why.find("budget") != std::string::npos);
    // The refusal teaches: the budget, what the signal wanted and what is in use, in MiB.
    CHECK(fr.out.why.find("MiB wanted") != std::string::npos);
    CHECK(fr.out.why.find("MiB in use") != std::string::npos);
    CHECK(rig.dn.history_image_count() == 0);
    CHECK(rig.dn.refused());
}

TEST_CASE("denoise: the signal declared twice for one camera in a graph is refused, not duplicated") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    Rig rig;
    REQUIRE_MESSAGE(rig.ok, rig.error);
    const size_t noisy = rig.make_tex(kW, kH), pre = rig.make_tex(kW, kH);
    rig.upload(pre, make_prepass(kW, kH, [](int, int) { return 5.0f; }, facing));
    rig.upload(noisy, bernoulli(kW, kH, 1, [](int, int) { return 0.5f; }));
    render::FrameGraph graph;
    render::DenoiseInputs in;
    in.noisy.view = rig.textures[noisy].view;
    in.prepass.view = rig.textures[pre].view;
    in.width = kW;
    in.height = kH;
    const DenoiseSignal s = visibility();
    const render::DenoiseOutput o1 =
        rig.dn.add_passes(graph, *rig.pool, rig.gpu, make_camera(kW, kH, 1), s, in, nullptr, "rig");
    const render::DenoiseOutput o2 =
        rig.dn.add_passes(graph, *rig.pool, rig.gpu, make_camera(kW, kH, 1), s, in, nullptr, "rig");
    CHECK(o1.valid);
    CHECK_FALSE(o2.valid);
    CHECK(o2.why.find("already") != std::string::npos);
    CHECK(graph.compile().ok());
}

TEST_CASE(
    "denoise: the variance view is dark on a clean signal and bright on a noisy one, the length view counts frames") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    double meanDbg[2] = {0, 0};
    for (int noisyRun = 0; noisyRun < 2; ++noisyRun) {
        Rig rig;
        REQUIRE_MESSAGE(rig.ok, rig.error);
        const size_t noisy = rig.make_tex(kW, kH), pre = rig.make_tex(kW, kH);
        rig.upload(pre, make_prepass(kW, kH, [](int, int) { return 5.0f; }, facing));
        DenoiseSignal sig = visibility();
        sig.debug = DenoiseDebug::Variance;
        Frame last;
        for (int f = 1; f <= 8; ++f) {
            rig.upload(noisy, bernoulli(kW, kH, std::uint32_t(f), [&](int, int) { return noisyRun ? 0.5f : 1.0f; }));
            last = rig.run(make_camera(kW, kH, std::uint64_t(f)), sig, noisy, pre, kW, kH);
            REQUIRE(last.read);
            REQUIRE(last.debug.size() == last.color.size());
        }
        double sum = 0;
        for (int y = 8; y < 40; ++y)
            for (int x = 8; x < 56; ++x) sum += at(last.debug, kW, x, y);
        meanDbg[noisyRun] = sum / (32.0 * 48.0);
    }
    INFO("variance view: clean " << meanDbg[0] << ", noisy " << meanDbg[1]);
    CHECK(meanDbg[0] < 0.01);
    CHECK(meanDbg[1] > 0.05);
}

TEST_CASE(
    "denoise: a radiance in physical units (noise of a thousand and more) leaves every output and debug value finite") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    // The luminance deviation of this noise (uniform [0, 4000]: 1150) is far over what a 16-bit float holds as a variance (65504): the
    // variance is clamped where it is written, so no filter weight of 0 times an infinity makes a NaN that grows with every iteration.
    for (int variant = 0; variant < 4; ++variant) {
        const bool specular = variant & 1, f16 = variant & 2;
        const std::string label =
            std::string(specular ? "specular" : "diffuse") + ", moments " + (f16 ? "16-bit" : "32-bit");
        INFO(label);
        Rig rig;
        REQUIRE_MESSAGE(rig.ok, rig.error);
        if (f16) rig.dn.force_moments_f16(true);
        const size_t noisy = rig.make_tex(kW, kH), pre = rig.make_tex(kW, kH);
        rig.upload(pre, make_prepass(kW, kH, [](int x, int) { return x < 32 ? 5.0f : 9.0f; }, facing));
        DenoiseSignal sig;
        sig.kind = specular ? DenoiseKind::Specular : DenoiseKind::Diffuse;
        sig.settings.fireflyClamp =
            0.0f;  // the clamp is relative to the neighbours: it does not bound a noisy radiance
        sig.settings.normalPower =
            256.0f;  // a weight that underflows to exactly 0 for a neighbour that is not facing the pixel
        sig.debug = DenoiseDebug::Variance;
        Frame last;
        float mx = 0.0f, mean = 0.0f;
        for (int f = 1; f <= 10;
             ++f) {  // 10 frames: the variance and the weights it feeds settle, and a NaN that grows would show
            std::vector<float> in(size_t(kW) * kH * 4, 0.0f);
            for (int y = 0; y < kH; ++y)
                for (int x = 0; x < kW; ++x) {
                    float* p = &in[(size_t(y) * kW + size_t(x)) * 4];
                    for (int c = 0; c < 3; ++c)
                        p[c] = 4000.0f * rnd(std::uint32_t(f * 3 + c), std::uint32_t(x), std::uint32_t(y));
                    p[3] = specular ? 3.0f : 1.0f;
                }
            rig.upload(noisy, in);
            last = rig.run(make_camera(kW, kH, std::uint64_t(f)), sig, noisy, pre, kW, kH);
            REQUIRE(last.read);
            REQUIRE(last.debug.size() == last.color.size());
        }
        size_t bad = 0;
        for (size_t i = 0; i < last.color.size(); ++i) {
            if (!std::isfinite(last.color[i]) || !std::isfinite(last.debug[i])) ++bad;
            if (i % 4 != 3 && std::isfinite(last.color[i])) {
                mx = std::max(mx, last.color[i]);
                mean += last.color[i];
            }
        }
        mean /= float(last.color.size() / 4 * 3);
        MESSAGE("noise 0..4000, " << label << ": non finite " << bad << ", brightest " << mx << ", mean " << mean);
        CHECK(bad == 0);
        CHECK(mx < 4000.0f * 1.001f);  // an average of samples cannot exceed the brightest sample
        CHECK(mean == doctest::Approx(2000.0f).epsilon(0.1));
    }
}

TEST_CASE("denoise: two signals of one camera with the same name do not collide in the graph") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    Rig rig;
    REQUIRE_MESSAGE(rig.ok, rig.error);
    const size_t noisy = rig.make_tex(kW, kH), pre = rig.make_tex(kW, kH);
    rig.upload(pre, make_prepass(kW, kH, [](int, int) { return 5.0f; }, facing));
    rig.upload(noisy, bernoulli(kW, kH, 1, [](int, int) { return 0.5f; }));
    render::FrameGraph graph;
    render::DenoiseInputs in;
    in.noisy.view = rig.textures[noisy].view;
    in.prepass.view = rig.textures[pre].view;
    in.width = kW;
    in.height = kH;
    DenoiseSignal a = visibility(), b = visibility();
    a.name = b.name = "shadow";
    a.id = 1;
    b.id = 2;
    const render::DenoiseOutput o1 =
        rig.dn.add_passes(graph, *rig.pool, rig.gpu, make_camera(kW, kH, 1), a, in, nullptr, "rig");
    const render::DenoiseOutput o2 =
        rig.dn.add_passes(graph, *rig.pool, rig.gpu, make_camera(kW, kH, 1), b, in, nullptr, "rig");
    CHECK(o1.valid);
    CHECK(o2.valid);
    const auto compiled = graph.compile();
    CHECK_MESSAGE(compiled.ok(), (compiled.ok() ? std::string() : compiled.error().message));
}

TEST_CASE("denoise: a coverage signal reads the hit distance of the specular image and converges to the share of rays "
          "that hit") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    Rig rig;
    REQUIRE_MESSAGE(rig.ok, rig.error);
    const size_t noisy = rig.make_tex(kW, kH), pre = rig.make_tex(kW, kH), rr = rig.make_tex(kW, kH);
    rig.upload(pre, make_prepass(kW, kH, [](int, int) { return 4.0f; }, facing));
    rig.upload(rr, std::vector<float>(size_t(kW) * kH * 4, 0.4f));
    DenoiseSignal sig;
    sig.kind = DenoiseKind::Coverage;
    sig.id = 4;
    Frame last;
    for (int f = 1; f <= 8; ++f) {
        std::vector<float> in(size_t(kW) * kH * 4, 0.0f);
        for (int y = 0; y < kH; ++y)
            for (int x = 0; x < kW; ++x) {
                float* p = &in[(size_t(y) * kW + size_t(x)) * 4];
                const bool hit = rnd(std::uint32_t(f), std::uint32_t(x), std::uint32_t(y)) < 0.5f;
                p[0] = hit ? 0.7f : 0.0f;   // the colour does not matter to the coverage
                p[3] = hit ? 6.0f : -1.0f;  // a hit distance, or a miss
            }
        rig.upload(noisy, in);
        last = rig.run(make_camera(kW, kH, std::uint64_t(f)), sig, noisy, pre, kW, kH, -1, int(rr));
        REQUIRE(last.read);
    }
    const double err = mae(last.color, kW, 4, 4, 60, 44, 0, [](int, int) { return 0.5f; });
    INFO("mean absolute error of the coverage " << err);
    CHECK(err < 0.2);  // the raw signal is 0 or 1: its error is 0.5
    // The output is a coverage: in 0 .. 1 and the same in the three channels.
    for (int y = 4; y < 44; ++y)
        for (int x = 4; x < 60; ++x) {
            CHECK(at(last.color, kW, x, y, 0) >= -0.01f);
            CHECK(at(last.color, kW, x, y, 0) <= 1.01f);
            CHECK(at(last.color, kW, x, y, 0) == doctest::Approx(at(last.color, kW, x, y, 2)).epsilon(0.02));
        }
}

TEST_CASE(
    "denoise: a reflection follows the virtual position behind the mirror, not the surface, when the camera moves") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    constexpr float kStep = 0.5f;  // the camera moves along x by this much per frame
    constexpr float kPeriod = 5.0f;
    const float halfX = 1.0f / std::fabs(Mat4::perspective(90.0f, float(kW) / float(kH), 0.1f, 100.0f, true).at(0, 0));
    const float halfY = 1.0f / std::fabs(Mat4::perspective(90.0f, float(kW) / float(kH), 0.1f, 100.0f, true).at(1, 1));
    double err[2] = {0, 0};
    for (int mode = 0; mode < 2; ++mode) {
        // mode 0: the true hit distance of the pattern (12 units behind the surface); mode 1: a hit distance of nothing, so the history is
        // looked for where the surface was (what the denoiser did before the virtual motion).
        const float hit = mode == 0 ? 12.0f : 0.0001f;
        Rig rig;
        REQUIRE_MESSAGE(rig.ok, rig.error);
        const size_t noisy = rig.make_tex(kW, kH), pre = rig.make_tex(kW, kH), rr = rig.make_tex(kW, kH);
        rig.upload(pre, make_prepass(kW, kH, [](int, int) { return 4.0f; }, facing));
        rig.upload(rr, std::vector<float>(size_t(kW) * kH * 4, 0.0f));  // a mirror: the filter leaves the image alone
        DenoiseSignal sig;
        sig.kind = DenoiseKind::Specular;
        sig.id = 3;
        Frame last;
        std::vector<float> truth;
        for (int f = 1; f <= 8; ++f) {
            std::vector<float> in(size_t(kW) * kH * 4, 0.0f);
            for (int y = 0; y < kH; ++y)
                for (int x = 0; x < kW; ++x) {
                    const float nx = (float(x) + 0.5f) / float(kW) * 2.0f - 1.0f,
                                ny = 1.0f - (float(y) + 0.5f) / float(kH) * 2.0f;
                    const float d = 4.0f;
                    const Vec3 vp{nx * halfX * d, ny * halfY * d, -d};
                    const float len = std::sqrt(vp.x * vp.x + vp.y * vp.y + vp.z * vp.z);
                    const float worldX =
                        kStep * float(f) +
                        vp.x * (len + 12.0f) / len;  // the pattern is 12 units behind the surface, in the world
                    const float v = 0.5f + 0.4f * std::sin(6.2831853f * worldX / kPeriod);
                    float* p = &in[(size_t(y) * kW + size_t(x)) * 4];
                    p[0] = p[1] = p[2] = v;
                    p[3] = hit;
                }
            truth = in;
            rig.upload(noisy, in);
            DenoiseCamera cam = make_camera(kW, kH, std::uint64_t(f));
            cam.prevFromView = cam.prevFromView *
                               Mat4::translate({kStep, 0.0f, 0.0f});  // the camera was kStep to the left a frame ago
            last = rig.run(cam, sig, noisy, pre, kW, kH, -1, int(rr));
            REQUIRE(last.read);
        }
        err[mode] = mae(last.color, kW, 12, 8, 52, 40, 0, [&](int x, int y) { return at(truth, kW, x, y, 0); });
    }
    INFO("virtual " << err[0] << ", surface " << err[1]);
    CHECK(err[0] < 0.1);
    CHECK(err[0] < 0.5 * err[1]);
}

// M79 POLISH-denoise: the a-trous passes read the camera's guide of this frame (depth and world normal in one image) and not the prepass
// (the octahedral normal of every tap decoded again in every iteration): the guide pass writes the image they all read.
TEST_CASE("denoise: every filter iteration reads the guide image the guide pass writes") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    Rig rig;
    REQUIRE_MESSAGE(rig.ok, rig.error);
    const size_t noisy = rig.make_tex(kW, kH), pre = rig.make_tex(kW, kH);
    rig.upload(pre, make_prepass(kW, kH, [](int, int) { return 5.0f; }, facing));
    rig.upload(noisy, bernoulli(kW, kH, 1, [](int, int) { return 0.3f; }));
    const Frame f = rig.run(make_camera(kW, kH, 1), visibility(), noisy, pre, kW, kH);
    REQUIRE(f.out.valid);
    std::string guideOut;
    const Json& passes = f.graph["passes"];
    for (size_t i = 0; i < passes.size(); ++i) {
        const Json& p = passes[i];
        if (p["name"].get<std::string>().find("denoise-guide") != std::string::npos && p["writes"].size() == 1)
            guideOut = p["writes"][0].get<std::string>();
    }
    REQUIRE_FALSE(guideOut.empty());
    int atrous = 0, readGuide = 0, temporal = 0, temporalReadsGuide = 0;
    for (size_t i = 0; i < passes.size(); ++i) {
        const Json& p = passes[i];
        const std::string name = p["name"].get<std::string>();
        const bool isAtrous = name.find("-atrous") != std::string::npos;
        const bool isTemporal = name.find("-temporal") != std::string::npos;
        if (!isAtrous && !isTemporal) continue;
        (isAtrous ? atrous : temporal)++;
        for (size_t k = 0; k < p["reads"].size(); ++k) {
            const std::string r = p["reads"][k].get<std::string>();
            if (r == guideOut) ++(isAtrous ? readGuide : temporalReadsGuide);
        }
    }
    CHECK(atrous == 5);
    CHECK(readGuide == 5);
    // The temporal pass reads the guide too (its depth and world normal): the depth it tests the history with and the normal it gathers by.
    CHECK(temporal == 1);
    CHECK(temporalReadsGuide == 1);
}

// M79 POLISH-denoise: the first iteration never skips a calm pixel (only the later ones do), so a pixel whose own history has not seen the
// signal yet (a Bernoulli signal that was 0 every frame so far: its variance is exactly 0) still takes it from its neighbours. (That the later
// iterations leave a calm pixel alone is the test "a faint pattern ..." below.)
TEST_CASE("denoise: a pixel whose history saw only zeros still takes the signal from its neighbours (the first "
          "iteration never skips)") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    Rig rig;
    REQUIRE_MESSAGE(rig.ok, rig.error);
    const size_t noisy = rig.make_tex(kW, kH), pre = rig.make_tex(kW, kH);
    rig.upload(pre, make_prepass(kW, kH, [](int, int) { return 5.0f; }, facing));
    const auto truth = [](int x, int) { return x < 32 ? 0.5f : 0.1f; };
    Frame last;
    for (int f = 1; f <= 8; ++f) {
        std::vector<float> in = bernoulli(kW, kH, std::uint32_t(f), [](int, int) { return 0.1f; });
        for (int y = 0; y < kH; ++y)
            for (int x = 0; x < 32; ++x) {
                float* p = &in[(size_t(y) * kW + size_t(x)) * 4];
                p[0] = p[1] = p[2] = 0.5f;  // the left half has no noise at all
            }
        rig.upload(noisy, in);
        last = rig.run(make_camera(kW, kH, std::uint64_t(f)), visibility(), noisy, pre, kW, kH);
        REQUIRE(last.read);
    }
    double leftWorst = 0;
    for (int y = 4; y < 44; ++y)
        for (int x = 4; x < 26; ++x) leftWorst = std::max(leftWorst, std::fabs(double(at(last.color, kW, x, y)) - 0.5));
    // After 8 frames a pixel of the right half has seen only zeros with the probability 0.9^8 = 43%: left alone it would stay 0.
    int dark = 0, total = 0;
    for (int y = 4; y < 44; ++y)
        for (int x = 38; x < 60; ++x, ++total)
            if (at(last.color, kW, x, y) < 0.02f) ++dark;
    const double right = mae(last.color, kW, 38, 4, 60, 44, 0, truth);
    INFO("left worst " << leftWorst << ", right: " << dark << " of " << total << " still dark, error " << right);
    CHECK(leftWorst < 0.002);
    CHECK(dark < total / 20);
    CHECK(right < 0.06);
}

// M79 POLISH-denoise-2: the iterations after the first leave a pixel whose estimate is already calm (a standard deviation under kCalmSd of
// 0.25 + its luminance) bit for bit as it is. Two filters of 2 and 5 iterations see the same noise: a faint pattern far from any strong noise
// must come out identical, the strong noise must be smoothed further by the longer one.
TEST_CASE("denoise: a faint pattern is left as it is by the later iterations, a strong one is smoothed by them") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    std::vector<float> out[2];
    for (int run = 0; run < 2; ++run) {
        Rig rig;
        REQUIRE_MESSAGE(rig.ok, rig.error);
        const size_t noisy = rig.make_tex(kW, kH), pre = rig.make_tex(kW, kH);
        rig.upload(pre, make_prepass(kW, kH, [](int, int) { return 5.0f; }, facing));
        DenoiseSignal sig = visibility();
        sig.settings.iterations = run == 0 ? 2 : 5;
        Frame last;
        for (int f = 1; f <= 12; ++f) {
            std::vector<float> in(size_t(kW) * kH * 4, 1.0f);
            for (int y = 0; y < kH; ++y)
                for (int x = 0; x < kW; ++x) {
                    const float n = rnd(std::uint32_t(f), std::uint32_t(x), std::uint32_t(y));
                    // x < 24: 0.5 +- 0.001. x >= 32: 0 or 1 with the probability 0.5. The 8 columns between keep the two apart.
                    const float v = x < 24 ? 0.5f + 0.002f * (n - 0.5f) : (n < 0.5f ? 1.0f : 0.0f);
                    float* p = &in[(size_t(y) * kW + size_t(x)) * 4];
                    p[0] = p[1] = p[2] = v;
                }
            rig.upload(noisy, in);
            last = rig.run(make_camera(kW, kH, std::uint64_t(f)), sig, noisy, pre, kW, kH);
            REQUIRE(last.read);
        }
        out[run] = last.color;
    }
    int faintDiffers = 0;
    double strongDiff = 0;
    for (int y = 4; y < 44; ++y) {
        for (int x = 4; x < 20; ++x)
            for (int c = 0; c < 3; ++c)
                if (at(out[0], kW, x, y, c) != at(out[1], kW, x, y, c)) ++faintDiffers;
        for (int x = 40; x < 60; ++x)
            strongDiff += std::fabs(double(at(out[0], kW, x, y)) - double(at(out[1], kW, x, y)));
    }
    strongDiff /= 40.0 * 20.0;
    INFO("faint pixels that differ " << faintDiffers << ", strong region mean difference " << strongDiff);
    CHECK(faintDiffers == 0);
    CHECK(strongDiff > 0.005);
}

// M79 POLISH-denoise-2: a reflection pixel the caller does not read (a roughness outside [roughMin, roughMax]) is not filtered: it comes out as
// the sample, and it does not feed its neighbours. A pixel the kernel did not trace (alpha exactly 0) is skipped the same way.
TEST_CASE(
    "denoise: a specular pixel outside the roughness window passes through, one inside is filtered, and a skipped one "
    "does not bleed into its neighbours") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    Rig rig;
    REQUIRE_MESSAGE(rig.ok, rig.error);
    const size_t noisy = rig.make_tex(kW, kH), pre = rig.make_tex(kW, kH), rr = rig.make_tex(kW, kH);
    rig.upload(pre, make_prepass(kW, kH, [](int, int) { return 4.0f; }, facing));
    std::vector<float> rv(size_t(kW) * kH * 4, 0.4f);
    for (int y = 0; y < kH; ++y)
        for (int x = 0; x < 32; ++x) rv[(size_t(y) * kW + size_t(x)) * 4] = 0.1f;  // the left half: a sharp mirror
    rig.upload(rr, rv);
    DenoiseSignal sig;
    sig.kind = DenoiseKind::Specular;
    sig.id = 2;
    sig.roughMin = 0.25f;
    sig.roughMax = 0.65f;
    sig.settings.fireflyClamp = 0.0f;  // the sample itself is compared
    Frame last;
    std::vector<float> in;
    for (int f = 1; f <= 6; ++f) {
        in.assign(size_t(kW) * kH * 4, 0.0f);
        for (int y = 0; y < kH; ++y)
            for (int x = 0; x < kW; ++x) {
                float* p = &in[(size_t(y) * kW + size_t(x)) * 4];
                const bool untraced = y >= 40;  // the bottom rows: no ray was traced, the kernel left alpha at 0
                for (int c = 0; c < 3; ++c)
                    p[c] = untraced ? 50.0f : rnd(std::uint32_t(f * 3 + c), std::uint32_t(x), std::uint32_t(y));
                p[3] = untraced ? 0.0f : 6.0f;
            }
        rig.upload(noisy, in);
        last = rig.run(make_camera(kW, kH, std::uint64_t(f)), sig, noisy, pre, kW, kH, -1, int(rr));
        REQUIRE(last.read);
    }
    // Sharp pixels and untraced ones: the sample, to the half-float's rounding.
    double worst = 0;
    for (int y = 0; y < kH; ++y)
        for (int x = 0; x < kW; ++x) {
            if (x < 32 || y >= 40)
                for (int c = 0; c < 3; ++c)
                    worst =
                        std::max(worst, std::fabs(double(at(last.color, kW, x, y, c)) - double(at(in, kW, x, y, c))) /
                                            std::max(1.0, double(at(in, kW, x, y, c))));
        }
    // The filtered half: close to the mean 0.5 although the untraced rows (50) are next to it.
    const double filtered = mae(last.color, kW, 36, 4, 60, 40, 0, [](int, int) { return 0.5f; });
    const double nearSkipped = mae(last.color, kW, 36, 34, 60, 40, 0, [](int, int) { return 0.5f; });
    INFO("worst difference of a skipped pixel " << worst << ", filtered error " << filtered
                                                << ", next to the skipped rows " << nearSkipped);
    CHECK(worst < 2e-3);
    CHECK(filtered < 0.04);     // the raw sample's error is 0.25, measured 0.008
    CHECK(nearSkipped < 0.05);  // the untraced rows hold 50: a neighbour that bled in would be far off
}

// M79 POLISH-denoise-2: the lobe limit applies to the coverage of a reflection as it does to the reflection itself (a mirror's coverage is the
// raw rays of the frames accumulated, a rough surface's is filtered like its image).
TEST_CASE("denoise: the coverage of a mirror keeps its sharpness, the coverage of a rough surface is filtered") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    double err[2] = {0, 0};
    for (int rough = 0; rough < 2; ++rough) {
        Rig rig;
        REQUIRE_MESSAGE(rig.ok, rig.error);
        const size_t noisy = rig.make_tex(kW, kH), pre = rig.make_tex(kW, kH), rr = rig.make_tex(kW, kH);
        rig.upload(pre, make_prepass(kW, kH, [](int, int) { return 4.0f; }, facing));
        rig.upload(rr, std::vector<float>(size_t(kW) * kH * 4, rough ? 1.0f : 0.0f));
        DenoiseSignal sig;
        sig.kind = DenoiseKind::Coverage;
        sig.id = 4;
        Frame last;
        for (int f = 1; f <= 6; ++f) {
            std::vector<float> in(size_t(kW) * kH * 4, 0.0f);
            for (int y = 0; y < kH; ++y)
                for (int x = 0; x < kW; ++x) {
                    float* p = &in[(size_t(y) * kW + size_t(x)) * 4];
                    const bool hit = rnd(std::uint32_t(f), std::uint32_t(x), std::uint32_t(y)) < 0.5f;
                    p[0] = hit ? 0.7f : 0.0f;
                    p[3] = hit ? 6.0f : -1.0f;
                }
            rig.upload(noisy, in);
            last = rig.run(make_camera(kW, kH, std::uint64_t(f)), sig, noisy, pre, kW, kH, -1, int(rr));
            REQUIRE(last.read);
        }
        err[rough] = mae(last.color, kW, 4, 4, 60, 44, 0, [](int, int) { return 0.5f; });
    }
    INFO("mirror " << err[0] << ", rough " << err[1]);
    CHECK(err[0] > 0.08);  // 6 frames of a Bernoulli(0.5): about 0.16 left
    CHECK(err[1] < 0.5 * err[0]);
}

namespace {
DenoiseSignal half_occlusion() {
    DenoiseSignal s;
    s.kind = DenoiseKind::Occlusion;
    s.id = 5;
    s.halfRes = true;
    return s;
}
// How many passes of `graph` have `part` in their name.
int count_passes(const Json& graph, const char* part) {
    int n = 0;
    const Json& passes = graph["passes"];
    for (size_t i = 0; i < passes.size(); ++i)
        if (passes[i]["name"].get<std::string>().find(part) != std::string::npos) ++n;
    return n;
}
}  // namespace

// M79 POLISH-denoise-2: an occlusion or a diffuse signal may run on half the width and height (DenoiseSignal::halfRes): the half guide, the
// block mean of the signal, the temporal pass and the filter at half size (one iteration fewer), the guided upsample. 63 x 47: odd sizes.
TEST_CASE("denoise: a half size occlusion declares its own chain and converges to its truth") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    constexpr int w = 63, h = 47;
    Rig rig;
    REQUIRE_MESSAGE(rig.ok, rig.error);
    const size_t noisy = rig.make_tex(w, h), pre = rig.make_tex(w, h);
    // The right part (x >= 50) is sky: it must come out as it went in.
    rig.upload(pre, make_prepass(w, h, [](int x, int) { return x < 50 ? 5.0f : 0.0f; }, facing));
    const auto truth = [](int, int) { return 0.3f; };
    const DenoiseSignal sig = half_occlusion();
    Frame first, last;
    double firstError = 0, rawError = 0;
    std::vector<float> lastIn;
    for (int f = 1; f <= 24; ++f) {
        lastIn = bernoulli(w, h, std::uint32_t(f), truth);
        rig.upload(noisy, lastIn);
        last = rig.run(make_camera(w, h, std::uint64_t(f)), sig, noisy, pre, w, h);
        REQUIRE(last.out.valid);
        REQUIRE(last.read);
        CHECK(last.out.width == w);
        CHECK(last.out.height == h);
        if (f == 1) {
            first = last;
            CHECK(last.out.reset == DenoiseReset::Fresh);
            firstError = mae(last.color, w, 4, 4, 44, 43, 0, truth);
            rawError = mae(lastIn, w, 4, 4, 44, 43, 0, truth);
            // guide, half guide, down, temporal, 5 - 1 iterations, up
            CHECK(last.out.passes == 1 + 1 + 1 + 1 + 4 + 1);
            CHECK(count_passes(last.graph, "-guide-half") == 1);
            CHECK(count_passes(last.graph, "-down") == 1);
            CHECK(count_passes(last.graph, "-temporal") == 1);
            CHECK(count_passes(last.graph, "-atrous") == 4);
            CHECK(count_passes(last.graph, "-up") == 1);
        } else {
            CHECK(last.out.reset == DenoiseReset::None);
            CHECK(count_passes(last.graph, "-guide-half") == 1);
        }
    }
    const double lastError = mae(last.color, w, 4, 4, 44, 43, 0, truth);
    INFO("raw " << rawError << ", first frame " << firstError << ", after 24 frames " << lastError);
    CHECK(rawError > 0.38);
    CHECK(firstError < 0.05);  // measured 0.013 on Metal: the block mean of four samples, then the filter
    CHECK(lastError < 0.012);  // measured 0.004
    // The sky passes through untouched.
    for (int y = 4; y < 43; ++y)
        for (int x = 54; x < 62; ++x)
            REQUIRE(at(last.color, w, x, y, 0) == doctest::Approx(at(lastIn, w, x, y, 0)).epsilon(1e-3));
    // The memory is a chain of half the size (and the half guide's own history), the camera's guide the full size.
    const DenoisePlan plan = render::make_denoise_plan(sig, w, h, true);
    CHECK(plan.chainWidth == 32);
    CHECK(plan.chainHeight == 24);
    CHECK(rig.dn.history_image_count() == 2 + 4 + 2);  // the camera's guide pair, the signal's, the half guide's
}

// M79 POLISH-denoise-2: the upsample is guided by depth and normal: a depth edge on an odd column (inside a 2 x 2 block) keeps the two
// surfaces apart, and the pixels that do not agree with the half-size block take their own sample.
TEST_CASE("denoise: a half size signal does not blur across a depth edge inside a block") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    constexpr int w = 64, h = 48;
    Rig rig;
    REQUIRE_MESSAGE(rig.ok, rig.error);
    const size_t noisy = rig.make_tex(w, h), pre = rig.make_tex(w, h);
    rig.upload(pre, make_prepass(w, h, [](int x, int) { return x < 33 ? 3.0f : 6.0f; }, facing));
    const auto truth = [](int x, int) { return x < 33 ? 0.2f : 0.8f; };
    Frame last;
    for (int f = 1; f <= 20; ++f) {
        rig.upload(noisy, bernoulli(w, h, std::uint32_t(f), truth));
        last = rig.run(make_camera(w, h, std::uint64_t(f)), half_occlusion(), noisy, pre, w, h);
        REQUIRE(last.read);
    }
    const double left = mae(last.color, w, 4, 4, 29, 44, 0, truth);
    const double right = mae(last.color, w, 37, 4, 60, 44, 0, truth);
    // The two columns of the edge: a pixel of one surface in a block that shows the other.
    const double edgeL = mae(last.color, w, 32, 4, 33, 44, 0, truth);
    const double edgeR = mae(last.color, w, 33, 4, 34, 44, 0, truth);
    INFO("left " << left << ", right " << right << ", the edge columns " << edgeL << " and " << edgeR);
    CHECK(left < 0.02);   // measured 0.004
    CHECK(right < 0.02);  // measured 0.002
    // Blurred across the edge a column would be 0.3 off (the other surface's mean); kept apart it is about as good as the others (measured 0.005).
    CHECK(edgeL < 0.06);
    CHECK(edgeR < 0.06);
}

TEST_CASE("denoise: a half size diffuse signal keeps its colours and a kind that cannot run at half size ignores the "
          "request") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    Rig rig;
    REQUIRE_MESSAGE(rig.ok, rig.error);
    const size_t noisy = rig.make_tex(kW, kH), pre = rig.make_tex(kW, kH);
    rig.upload(pre, make_prepass(kW, kH, [](int, int) { return 4.0f; }, facing));
    DenoiseSignal sig;
    sig.kind = DenoiseKind::Diffuse;
    sig.halfRes = true;
    const float truthRgb[3] = {0.8f, 0.4f, 0.1f};
    Frame last;
    for (int f = 1; f <= 20; ++f) {
        std::vector<float> in(size_t(kW) * kH * 4, 1.0f);
        for (int y = 0; y < kH; ++y)
            for (int x = 0; x < kW; ++x)
                for (int c = 0; c < 3; ++c)
                    in[(size_t(y) * kW + size_t(x)) * 4 + size_t(c)] =
                        2.0f * truthRgb[c] *
                        rnd(std::uint32_t(f) * 3 + std::uint32_t(c), std::uint32_t(x), std::uint32_t(y));
        rig.upload(noisy, in);
        last = rig.run(make_camera(kW, kH, std::uint64_t(f)), sig, noisy, pre, kW, kH);
        REQUIRE(last.read);
    }
    for (int c = 0; c < 3; ++c) {
        const double e = mae(last.color, kW, 4, 4, 60, 44, c, [&](int, int) { return truthRgb[c]; });
        INFO("channel " << c << " error " << e);
        CHECK(e < 0.015);  // measured 0.004
    }
    // A specular signal asking for half size runs at full size.
    Rig rig2;
    REQUIRE_MESSAGE(rig2.ok, rig2.error);
    const size_t n2 = rig2.make_tex(kW, kH), p2 = rig2.make_tex(kW, kH);
    rig2.upload(p2, make_prepass(kW, kH, [](int, int) { return 4.0f; }, facing));
    std::vector<float> in(size_t(kW) * kH * 4, 0.5f);
    for (size_t i = 3; i < in.size(); i += 4) in[i] = 6.0f;
    rig2.upload(n2, in);
    DenoiseSignal spec;
    spec.kind = DenoiseKind::Specular;
    spec.halfRes = true;
    const Frame f2 = rig2.run(make_camera(kW, kH, 1), spec, n2, p2, kW, kH);
    REQUIRE(f2.out.valid);
    CHECK(count_passes(f2.graph, "-guide-half") == 0);
    CHECK(count_passes(f2.graph, "-up") == 0);
    CHECK(count_passes(f2.graph, "-atrous") == 5);
}
