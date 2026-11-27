#include "rt_denoise.h"

#include <algorithm>
#include <cmath>
#include <cstring>
#include <limits>

#include "fa/core/log.h"

#include "fullscreen_gpu.h"
#include "gpu/sokol_shaders.h"
#include "shader_cache.h"
#include "shaders/rt_denoise.glsl.h"

namespace fa::render {

namespace {

static_assert(UB_rt_denoise_rtd_vs_params == 0, "the denoise vertex uniform slot");
static_assert(UB_rt_denoise_rtd_guide_params == 1 && UB_rt_denoise_rtd_temporal_params == 1 &&
                  UB_rt_denoise_rtd_atrous_params == 1 && UB_rt_denoise_rtd_debug_params == 1 &&
                  UB_rt_denoise_rtd_guide_half_params == 1 && UB_rt_denoise_rtd_down_params == 1 &&
                  UB_rt_denoise_rtd_up_params == 1,
              "the denoise fragment uniform slots");
static_assert(VIEW_rt_denoise_tex_n == 0 && VIEW_rt_denoise_tex_p == 1 && VIEW_rt_denoise_tex_v == 2 &&
                  VIEW_rt_denoise_tex_hc == 3 && VIEW_rt_denoise_tex_hm == 4 && VIEW_rt_denoise_tex_hg == 5 &&
                  VIEW_rt_denoise_tex_c == 6 && VIEW_rt_denoise_tex_r == 7 && VIEW_rt_denoise_tex_g == 1 &&
                  VIEW_rt_denoise_tex_gh == 2,
              "the denoise view slots");
static_assert(SMP_rt_denoise_smp_pt == 0, "the denoise sampler slot");

constexpr gpu::PixelFormat kColorFormat = gpu::PixelFormat::Rgba16F;
// The a-trous filter is a 3x3 [1 2 1] except in the second iteration, a 5x5 B3 spline (the steps from kWideFrom on are 4, 8 and 16 pixels:
// the taps are far apart, the spline's outer ring adds little). From kCalmFrom on (the input of those iterations is already filtered, its
// variance is a neighbourhood's, not one pixel's) a pixel whose standard deviation is under kCalmSd of its own brightness (+ 0.25) is
// left as it is: less than one level of an 8-bit picture. The first iteration never skips: a pixel whose own history has no spread yet
// (a Bernoulli signal that was 0 every frame so far) still takes its value from the neighbours.
constexpr int kWideFrom = 2;
constexpr int kCalmFrom = 1;
constexpr float kCalmSd = 0.003f;
constexpr float kMinNormalDot =
    0.9f;  // the cosine between two normals below which the temporal pass and the variance estimate see two surfaces
// The half size chain: the `down` pass takes a pixel of a 2x2 block into the block's mean when its depth is within this many times the depth
// tolerance of the half guide's (two pixels of a slanted floor are further apart than two of a wall).
constexpr float kDownDepthScale = 2.0f;

// What the histories of all the cameras may take together. A wasm32 build has a quarter.
constexpr std::uint64_t kBudgetBytes = sizeof(void*) >= 8 ? (std::uint64_t(1) << 30) : (std::uint64_t(256) << 20);
constexpr std::uint64_t kCap = std::numeric_limits<std::uint64_t>::max() / 4;

float finite_or(float v, float fallback) { return std::isfinite(v) ? v : fallback; }
float clamped(float v, float lo, float hi, float fallback) { return std::clamp(finite_or(v, fallback), lo, hi); }

// 64-bit and saturated: a huge size cannot wrap around to a small number.
std::uint64_t image_bytes(int w, int h, std::uint64_t perPixel, std::uint64_t images) {
    const std::uint64_t px = std::uint64_t(std::max(w, 0)) * std::uint64_t(std::max(h, 0));  // < 2^62
    if (perPixel == 0 || images == 0) return 0;
    if (px > kCap / (perPixel * images)) return kCap;
    return px * perPixel * images;
}
std::uint64_t sat_add(std::uint64_t a, std::uint64_t b) { return std::min<std::uint64_t>(a + b, kCap); }

std::uint64_t mix_hash(std::uint64_t h, std::uint64_t v) {
    h ^= v;
    return h * 1099511628211ull;
}
std::uint64_t float_bits(float f) {
    std::uint32_t u = 0;
    std::memcpy(&u, &f, sizeof(u));
    return u;
}

// The key of what a history means: the kind and every setting that changes the numbers it holds (the iterations only change what the
// filter does with them, the debug view nothing).
std::uint64_t config_key(DenoiseKind kind, const DenoiseSettings& s, bool halfRes, float roughMin, float roughMax) {
    std::uint64_t h = 1469598103934665603ull;
    h = mix_hash(h, std::uint64_t(kind));
    h = mix_hash(h, halfRes ? 1 : 0);  // the history of another size is another history
    h = mix_hash(
        h, float_bits(roughMin));  // a pixel outside the window has no history length: a new window is a new history
    h = mix_hash(h, float_bits(roughMax));
    h = mix_hash(h, float_bits(s.maxHistory));
    h = mix_hash(h, float_bits(s.fireflyClamp));
    h = mix_hash(h, float_bits(s.depthTolerance));
    return h;
}

const char* kind_label(DenoiseKind k) { return denoise_kind_name(k); }

}  // namespace

const char* denoise_kind_name(DenoiseKind k) {
    switch (k) {
        case DenoiseKind::Visibility: return "visibility";
        case DenoiseKind::Occlusion: return "occlusion";
        case DenoiseKind::Diffuse: return "diffuse";
        case DenoiseKind::Specular: return "specular";
        case DenoiseKind::Coverage: return "coverage";
    }
    return "diffuse";
}

int denoise_channels(DenoiseKind k) {
    return k == DenoiseKind::Visibility || k == DenoiseKind::Occlusion || k == DenoiseKind::Coverage ? 1 : 3;
}

const char* denoise_reset_name(DenoiseReset r) {
    switch (r) {
        case DenoiseReset::None: return "none";
        case DenoiseReset::Fresh: return "fresh";
        case DenoiseReset::Resize: return "resize";
        case DenoiseReset::Gap: return "gap";
        case DenoiseReset::Scene: return "scene";
        case DenoiseReset::Origin: return "origin";
        case DenoiseReset::Settings: return "settings";
        case DenoiseReset::Cut: return "cut";
    }
    return "none";
}

DenoiseSettings sanitize_denoise_settings(const DenoiseSettings& in) {
    const DenoiseSettings d;
    DenoiseSettings s;
    s.iterations = std::clamp(in.iterations, 2, 6);
    s.maxHistory = clamped(in.maxHistory, 1.0f, 255.0f, d.maxHistory);
    s.fireflyClamp = clamped(in.fireflyClamp, 0.0f, 64.0f, d.fireflyClamp);
    s.depthTolerance = clamped(in.depthTolerance, 0.001f, 0.5f, d.depthTolerance);
    s.normalPower = clamped(in.normalPower, 1.0f, 256.0f, d.normalPower);
    s.lumaSigma = clamped(in.lumaSigma, 0.5f, 16.0f, d.lumaSigma);
    s.roughness = clamped(in.roughness, 0.0f, 1.0f, d.roughness);
    return s;
}

DenoiseCamera make_denoise_camera(const CameraInfo& cam, std::uint64_t camKey, std::uint64_t serial,
                                  std::uint64_t sceneKey, std::uint64_t originShifts, const Mat4& prevViewProj,
                                  bool prevValid) {
    DenoiseCamera c;
    c.view = cam.view;
    c.camKey = camKey;
    c.serial = serial;
    c.sceneKey = sceneKey;
    c.originShifts = originShifts;
    const Mat4& P = cam.proj;
    const float terms[8] = {P.at(0, 0), P.at(1, 1), P.at(2, 0), P.at(2, 1),
                            P.at(3, 0), P.at(3, 1), P.at(2, 3), P.at(3, 3)};
    bool finite = std::fabs(P.at(0, 0)) > 1e-12f && std::fabs(P.at(1, 1)) > 1e-12f;
    for (float t : terms) finite = finite && std::isfinite(t);
    for (int i = 0; i < 8; ++i) c.proj[i] = terms[i];
    const float p00 = std::fabs(P.at(0, 0)), p11 = std::fabs(P.at(1, 1));
    c.halfX = p00 > 1e-9f ? 1.0f / p00 : 1.0f;
    c.halfY = p11 > 1e-9f ? 1.0f / p11 : 1.0f;
    c.ortho = !cam.perspective;
    if (prevValid && finite) {
        // A view-space position of this frame -> the clip position of the frame before (the same as the TAA's plan).
        c.prevFromView = prevViewProj * cam.view.inverse();
        for (int i = 0; i < 16; ++i) finite = finite && std::isfinite(c.prevFromView.m[i]);
        c.prevValid = finite;  // a matrix that is not usable: a cut
    }
    return c;
}

DenoiseReset denoise_reset_reason(const DenoiseHistoryState& s, const DenoiseCamera& cam, int width, int height,
                                  std::uint64_t configKey) {
    if (!s.wrote) return DenoiseReset::Fresh;
    if (s.width != width || s.height != height) return DenoiseReset::Resize;
    if (s.serial + 1 != cam.serial) return DenoiseReset::Gap;
    if (s.sceneKey != cam.sceneKey) return DenoiseReset::Scene;
    if (s.originShifts != cam.originShifts) return DenoiseReset::Origin;
    if (s.configKey != configKey) return DenoiseReset::Settings;
    if (!cam.prevValid) return DenoiseReset::Cut;
    return DenoiseReset::None;
}

DenoisePlan make_denoise_plan(const DenoiseSignal& signal, int width, int height, bool momentsF32) {
    DenoisePlan p;
    if (!signal.enabled || width < 1 || height < 1) return p;
    p.on = true;
    p.kind = signal.kind;
    p.channels = denoise_channels(signal.kind);
    p.settings = sanitize_denoise_settings(signal.settings);
    if (p.channels == 1) p.settings.fireflyClamp = 0.0f;  // a visibility or an occlusion is bounded: nothing to clamp
    p.width = width;
    p.height = height;
    const bool dbg = signal.debug != DenoiseDebug::None;
    p.halfRes = signal.halfRes && (signal.kind == DenoiseKind::Occlusion || signal.kind == DenoiseKind::Diffuse);
    p.hitDistance = signal.kind == DenoiseKind::Specular || signal.kind == DenoiseKind::Coverage;
    // The roughness window of a reflection kind: two numbers in 0 .. 1, the least not above the most.
    p.roughMin = p.hitDistance ? clamped(signal.roughMin, 0.0f, 1.0f, 0.0f) : 0.0f;
    p.roughMax = p.hitDistance ? clamped(signal.roughMax, p.roughMin, 1.0f, 1.0f) : 1.0f;
    if (p.halfRes)
        p.settings.iterations = std::max(2, p.settings.iterations - 1);  // a step of 2 pixels covers what two steps did
    p.chainWidth = p.halfRes ? (width + 1) / 2 : width;
    p.chainHeight = p.halfRes ? (height + 1) / 2 : height;
    p.signalPasses = 1 + p.settings.iterations + (dbg ? 1 : 0) + (p.halfRes ? 3 : 0);
    p.guidePasses = 1;
    // The accumulation and up to two a-trous buffers; a half size signal adds the down image and the full size result.
    p.transients = 1 + std::min(p.settings.iterations - 1, 2) + (dbg ? 1 : 0) + (p.halfRes ? 2 : 0);
    p.historyImages = p.halfRes ? 6 : 4;
    p.configKey = config_key(signal.kind, p.settings, p.halfRes, p.roughMin, p.roughMax);
    p.historyBytes = sat_add(image_bytes(p.chainWidth, p.chainHeight, 8, 2),
                             image_bytes(p.chainWidth, p.chainHeight, momentsF32 ? 16 : 8, 2));
    if (p.halfRes)
        p.historyBytes =
            sat_add(p.historyBytes, image_bytes(p.chainWidth, p.chainHeight, 8, 2));  // its own guide history
    p.guideBytes = image_bytes(width, height, 8, 2);
    return p;
}

// ------------------------------------------------------------------------------------------------------------------------------------

bool RtDenoiser::ready(gpu::Device& dev) {
    if (state_ != 0) return state_ > 0;
    device_ = &dev;
    shaders_[int(Prog::Guide)] =
        make_shader(dev, gpu::generated_shader_desc(dev, rt_denoise_guide_shader_desc), "rt_denoise_guide");
    shaders_[int(Prog::Temporal)] =
        make_shader(dev, gpu::generated_shader_desc(dev, rt_denoise_temporal_shader_desc), "rt_denoise_temporal");
    shaders_[int(Prog::Atrous)] =
        make_shader(dev, gpu::generated_shader_desc(dev, rt_denoise_atrous_shader_desc), "rt_denoise_atrous");
    shaders_[int(Prog::Debug)] =
        make_shader(dev, gpu::generated_shader_desc(dev, rt_denoise_debug_shader_desc), "rt_denoise_debug");
    bool ok = true;
    for (int i = 0; i < int(Prog::Count);
         ++i)  // the half size programs are made when a half size signal asks (half_ready)
        if (i != int(Prog::GuideHalf) && i != int(Prog::Down) && i != int(Prog::Up))
            ok = ok && dev.state(shaders_[i]) == gpu::ResourceState::Valid;
    const gpu::PixelFormatCaps f16 = dev.pixel_format_caps(kColorFormat);
    if (ok && !(f16.render && f16.sample)) {
        ok = false;
        FA_ERROR("render", "The ray tracing denoiser is unavailable: this GPU cannot render to half-float images. "
                           "Hint: nothing to do; "
                           "the signals are shown without denoising.");
    } else if (!ok) {
        FA_ERROR(
            "render",
            "The ray tracing denoiser is unavailable: its shaders failed to compile for this graphics backend (see the "
            "sokol log lines above). The signals are shown without denoising. Hint: update the graphics driver (Mesa: "
            "try "
            "LIBGL_ALWAYS_SOFTWARE=1).");
    }
    if (!ok) {
        for (gpu::Shader& sh : shaders_) {
            if (sh.id) dev.destroy_shader(sh);
            sh = {};
        }
        state_ = -1;
        return false;
    }
    state_ = 1;
    return true;
}

// The three programs of a half size chain, made when the first half size signal asks: a backend that cannot compile them (only Metal has
// them for now) still denoises every signal at full size.
bool RtDenoiser::half_ready(gpu::Device& dev) {
    if (halfState_ != 0) return halfState_ > 0;
    if (state_ <= 0) return false;
    shaders_[int(Prog::GuideHalf)] =
        make_shader(dev, gpu::generated_shader_desc(dev, rt_denoise_guidehalf_shader_desc), "rt_denoise_guidehalf");
    shaders_[int(Prog::Down)] =
        make_shader(dev, gpu::generated_shader_desc(dev, rt_denoise_down_shader_desc), "rt_denoise_down");
    shaders_[int(Prog::Up)] =
        make_shader(dev, gpu::generated_shader_desc(dev, rt_denoise_up_shader_desc), "rt_denoise_up");
    bool ok = true;
    for (Prog p : {Prog::GuideHalf, Prog::Down, Prog::Up})
        ok = ok && dev.state(shaders_[int(p)]) == gpu::ResourceState::Valid;
    if (!ok) {
        for (Prog p : {Prog::GuideHalf, Prog::Down, Prog::Up}) {
            gpu::Shader& sh = shaders_[int(p)];
            if (sh.id) dev.destroy_shader(sh);
            sh = {};
        }
        FA_WARN("render",
                "The ray tracing denoiser's half resolution shaders failed to compile for this graphics backend (see "
                "the log lines above): the signals that ask for half resolution (the AO, the per-pixel GI) are "
                "denoised at full resolution, which costs more. Hint: update the graphics driver.");
    }
    halfState_ = ok ? 1 : -1;
    return ok;
}

gpu::Pipeline RtDenoiser::pipeline(Prog prog, const TargetFormat& format) {
    for (const PipelineEntry& e : pipelines_)
        if (e.prog == prog && e.format == format) return e.pipeline;
    if (state_ <= 0 || !device_) return {};
    static const char* const kLabels[int(Prog::Count)] = {"rtd-guide",    "rtd-guide-half", "rtd-down", "rtd-up",
                                                          "rtd-temporal", "rtd-atrous",     "rtd-debug"};
    const gpu::Pipeline p = make_triangle_pipeline(*device_, shaders_[int(prog)], format, kLabels[int(prog)], 0);
    if (device_->state(p) != gpu::ResourceState::Valid)
        FA_ERROR("render", "failed to create pipeline '{}'", kLabels[int(prog)]);
    pipelines_.push_back({prog, format, p});
    return p;
}

void RtDenoiser::force_moments_f16(bool force) {
    forceF16_ = force;
    reset();
}

void RtDenoiser::destroy(GuideSlot& g) {
    if (device_)
        for (Target& t : g.img) destroy_target(*device_, t);
    g.w = g.h = 0;
    g.last = -1;
    g.wrote = false;
    g.frameSerial = 0;
    g.frameGraph = nullptr;
}

void RtDenoiser::destroy(SignalSlot& s) {
    if (device_) {
        for (Target& t : s.col) destroy_target(*device_, t);
        for (Target& t : s.mom) destroy_target(*device_, t);
        for (Target& t : s.hg) destroy_target(*device_, t);
    }
    s.halfGuide = false;
    s.w = s.h = 0;
    s.last = -1;
    s.wrote = false;
    s.frameSerial = 0;
    s.frameGraph = nullptr;
    s.guideSerial = 0;
}

std::uint64_t RtDenoiser::guide_bytes_of(const GuideSlot& g) { return g.w > 0 ? image_bytes(g.w, g.h, 8, 2) : 0; }

std::uint64_t RtDenoiser::signal_bytes_of(const SignalSlot& s) {
    if (s.w <= 0) return 0;
    const std::uint64_t mom = s.momFormat == gpu::PixelFormat::Rgba32F ? 16 : 8;
    const std::uint64_t own = sat_add(image_bytes(s.w, s.h, 8, 2), image_bytes(s.w, s.h, mom, 2));
    return s.halfGuide ? sat_add(own, image_bytes(s.w, s.h, 8, 2)) : own;
}

std::uint64_t RtDenoiser::used_bytes(const GuideSlot* exceptGuide, const SignalSlot* exceptSignal) const {
    std::uint64_t used = 0;
    for (const auto& c : cams_) {
        if (&c.second->guide != exceptGuide) used = sat_add(used, guide_bytes_of(c.second->guide));
        for (const auto& s : c.second->signals)
            if (s.second.get() != exceptSignal) used = sat_add(used, signal_bytes_of(*s.second));
    }
    return used;
}

void RtDenoiser::sweep(std::uint64_t serial) {
    for (auto cit = cams_.begin(); cit != cams_.end();) {
        CamSlot& c = *cit->second;
        for (auto it = c.signals.begin(); it != c.signals.end();) {
            // A signal that did not run on the frame before has no history that could be used again: freed now, made again when it asks.
            if (it->second->planned + 1 < serial) {
                destroy(*it->second);
                it = c.signals.erase(it);
            } else {
                ++it;
            }
        }
        if (c.guide.planned + 1 < serial) destroy(c.guide);
        if (c.signals.empty() && c.guide.w == 0)
            cit = cams_.erase(cit);
        else
            ++cit;
    }
}

void RtDenoiser::reset(std::uint64_t camKey) {
    for (auto& c : cams_) {
        if (camKey != 0 && c.first != camKey) continue;
        c.second->guide.wrote = false;
        for (auto& s : c.second->signals) s.second->wrote = false;
    }
}

void RtDenoiser::drop_signal(std::uint64_t camKey, std::uint32_t signalId) {
    const auto it = cams_.find(camKey);
    if (it == cams_.end()) return;
    const auto sit = it->second->signals.find(signalId);
    if (sit == it->second->signals.end()) return;
    destroy(*sit->second);
    it->second->signals.erase(sit);
    if (it->second->signals.empty()) {  // no signal left: the guide history has no reader
        destroy(it->second->guide);
        cams_.erase(it);
    }
}

int RtDenoiser::history_image_count() const {
    int n = 0;
    if (!device_) return 0;
    for (const auto& c : cams_) {
        for (const Target& t : c.second->guide.img)
            if (t.valid(*device_)) ++n;
        for (const auto& s : c.second->signals) {
            for (const Target& t : s.second->col)
                if (t.valid(*device_)) ++n;
            for (const Target& t : s.second->mom)
                if (t.valid(*device_)) ++n;
            for (const Target& t : s.second->hg)
                if (t.valid(*device_)) ++n;
        }
    }
    return n;
}

DenoiseReset RtDenoiser::last_reset(std::uint64_t camKey, std::uint32_t signalId) const {
    const auto it = cams_.find(camKey);
    if (it == cams_.end()) return DenoiseReset::Fresh;
    const auto sit = it->second->signals.find(signalId);
    return sit == it->second->signals.end() ? DenoiseReset::Fresh : sit->second->lastReset;
}

bool RtDenoiser::last_used_history(std::uint64_t camKey, std::uint32_t signalId) const {
    const auto it = cams_.find(camKey);
    if (it == cams_.end()) return false;
    const auto sit = it->second->signals.find(signalId);
    return sit != it->second->signals.end() && sit->second->usedHistory;
}

void RtDenoiser::forget_targets() {
    for (auto& c : cams_) {
        for (auto& s : c.second->signals) destroy(*s.second);
        destroy(c.second->guide);
    }
    cams_.clear();
    refused_ = false;
}

void RtDenoiser::release() {
    if (device_) {
        for (PipelineEntry& e : pipelines_)
            if (e.pipeline.id) device_->destroy_pipeline(e.pipeline);
        for (gpu::Shader& sh : shaders_)
            if (sh.id) device_->destroy_shader(sh);
    }
    pipelines_.clear();
    for (gpu::Shader& sh : shaders_) sh = {};
    state_ = 0;
    halfState_ = 0;
    forget_targets();
    device_ = nullptr;
}

bool RtDenoiser::draw(gpu::CommandList& list, Gpu& gpu, Prog prog, const PassDesc& pd, const DrawArgs& args) {
    if (!pd.color.id) return false;
    const gpu::Pipeline pipe = pipeline(prog, pd.format);  // made before the pass opens
    if (!pipe.id) return false;
    list.begin_pass(pd);
    list.set_pipeline(pipe);
    gpu::Bindings b;
    b.vertexBuffers[0] = gpu.fullscreen_triangle();
    for (int i = 0; i < 8; ++i) b.views[i] = args.views[i];
    b.samplers[SMP_rt_denoise_smp_pt] = gpu.sampler(SamplerKind::Nearest);
    list.set_bindings(b);
    const float flip[4] = {gpu.is_gl() ? 1.0f : 0.0f, 0.0f, 0.0f, 0.0f};
    list.set_uniforms(UB_rt_denoise_rtd_vs_params, gpu::Range{flip, sizeof(flip)});
    list.set_uniforms(args.paramSlot, gpu::Range{args.params, args.paramBytes});
    list.draw(0, 3, 1);
    list.end_pass();
    return true;
}

namespace {

void set4(float (&dst)[4], float a, float b, float c, float d) {
    dst[0] = a;
    dst[1] = b;
    dst[2] = c;
    dst[3] = d;
}

// The rows of the view matrix's rotation as the shader wants them: what a view-space x, y and z become in the world.
void world_columns(const Mat4& view, float (&wx)[4], float (&wy)[4], float (&wz)[4]) {
    set4(wx, view.at(0, 0), view.at(0, 1), view.at(0, 2), 0.0f);
    set4(wy, view.at(1, 0), view.at(1, 1), view.at(1, 2), 0.0f);
    set4(wz, view.at(2, 0), view.at(2, 1), view.at(2, 2), 0.0f);
}

}  // namespace

// The pass callbacks capture the shader's uniform blocks by value, which are alignas(16): MSVC warns (C4324, an error under /WX) that
// each closure is padded, which is what alignas asks for.
#if defined(_MSC_VER)
#pragma warning(push)
#pragma warning(disable : 4324)
#endif
DenoiseOutput RtDenoiser::add_passes(FrameGraph& graph, TransientTargets& targets, Gpu& gpu, const DenoiseCamera& cam,
                                     const DenoiseSignal& signal, const DenoiseInputs& in, int* drawCalls,
                                     const std::string& job) {
    DenoiseOutput out;
    auto fail = [&](const std::string& why) {
        out.valid = false;
        out.why = why;
        return out;
    };
    if (!signal.enabled) {
        drop_signal(cam.camKey, signal.id);  // a vendor denoiser has the signal: nothing of ours is kept
        return fail("the signal is disabled");
    }
    if (in.width < 1 || in.height < 1) return fail("the image has no size");
    if (!in.noisy.valid() || !in.prepass.valid()) return fail("the noisy image and the prepass are needed");
    if (state_ < 0 || !ready(gpu.device())) return fail("the denoiser's shaders did not compile");

    const int w = in.width, h = in.height;
    const gpu::PixelFormatCaps f32 = device_->pixel_format_caps(gpu::PixelFormat::Rgba32F);
    const bool momentsF32 = !forceF16_ && f32.render && f32.sample;
    const gpu::PixelFormat momFormat = momentsF32 ? gpu::PixelFormat::Rgba32F : gpu::PixelFormat::Rgba16F;
    // A half size signal runs at full size on a backend that did not compile the half size programs (said once, by half_ready).
    DenoiseSignal asked = signal;
    if (asked.halfRes && !half_ready(*device_)) asked.halfRes = false;
    const DenoisePlan plan = make_denoise_plan(asked, w, h, momentsF32);
    if (!plan.on) return fail("nothing to do");
    const DenoiseSettings& st = plan.settings;
    const bool half = plan.halfRes;
    const int cw = plan.chainWidth,
              ch = plan.chainHeight;  // the size of the temporal and a-trous passes and of the history

    std::shared_ptr<CamSlot>& camp = cams_[cam.camKey];
    if (!camp) camp = std::make_shared<CamSlot>();
    CamSlot& cs = *camp;
    GuideSlot& g = cs.guide;
    std::shared_ptr<SignalSlot>& sigp = cs.signals[signal.id];
    if (!sigp) sigp = std::make_shared<SignalSlot>();
    const std::shared_ptr<SignalSlot> sig = sigp;
    auto cleanup_empty = [&]() {
        // A slot made for this call that holds nothing: not kept.
        if (!sig->w) cs.signals.erase(signal.id);
        if (cs.signals.empty() && g.w == 0) cams_.erase(cam.camKey);
    };
    if (sig->frameSerial == cam.serial && sig->frameGraph == &graph)
        return fail("the signal was already declared for this camera in this graph");

    // What an image of another size is told as: a resize (the images are made again below, which clears their state).
    const bool resizedGuide = g.wrote && (g.w != w || g.h != h);
    const bool resizedSignal = sig->wrote && (sig->w != cw || sig->h != ch);

    // The images: made now when they do not exist or have another size; the budget counts every other history (64-bit, saturated).
    const bool needGuide = !(g.w == w && g.h == h && g.img[0].valid(*device_) && g.img[1].valid(*device_));
    const bool needSignal =
        !(sig->w == cw && sig->h == ch && sig->momFormat == momFormat && sig->halfGuide == half &&
          sig->col[0].valid(*device_) && sig->col[1].valid(*device_) && sig->mom[0].valid(*device_) &&
          sig->mom[1].valid(*device_) && (!half || (sig->hg[0].valid(*device_) && sig->hg[1].valid(*device_))));
    if (needGuide || needSignal) {
        const std::uint64_t budget = budgetOverride_ ? budgetOverride_ : kBudgetBytes;
        const std::uint64_t used = used_bytes(needGuide ? &g : nullptr, needSignal ? sig.get() : nullptr);
        const std::uint64_t wanted = sat_add(needGuide ? plan.guideBytes : 0, needSignal ? plan.historyBytes : 0);
        if (sat_add(used, wanted) > budget) {
            const std::uint64_t wantedMib = (wanted >> 20) + ((wanted & ((std::uint64_t(1) << 20) - 1)) ? 1 : 0);
            if (!refused_) {
                refused_ = true;
                FA_ERROR("render",
                         "Ray tracing denoiser: signal '{}' of camera '{}' needs {} MiB of history images ({}x{}) and "
                         "the renderer may hold {} MiB of them in all ({} MiB are in use by the other signals and "
                         "cameras). The signal is shown without denoising. Hint: lower the render scale or the window "
                         "size, or turn off a ray traced effect that is denoised (every one keeps its own images; "
                         "docs/design/ARCHITECTURE_DENOISE.md, \"Memory\").",
                         signal.name.empty() ? kind_label(signal.kind) : signal.name, job, wantedMib, w, h,
                         budget >> 20, used >> 20);
            }
            cleanup_empty();
            return fail("the history images do not fit the budget of " + std::to_string(budget >> 20) + " MiB (" +
                        std::to_string(wantedMib) + " MiB wanted, " + std::to_string(used >> 20) + " MiB in use)");
        }
        bool ok = true;
        if (needGuide) {
            destroy(g);
            for (int i = 0; i < 2 && ok; ++i) {
                TargetDesc d;
                d.label = i == 0 ? "rtd-guide-0" : "rtd-guide-1";
                d.width = w;
                d.height = h;
                d.colorFormat = kColorFormat;
                g.img[i] = make_target(*device_, d);
                ok = g.img[i].valid(*device_);
            }
            if (ok) {
                g.w = w;
                g.h = h;
            } else {
                destroy(g);
            }
        }
        if (needSignal && ok) {
            destroy(*sig);
            for (int i = 0; i < 2 && ok; ++i) {
                TargetDesc d;
                d.label = i == 0 ? "rtd-color-0" : "rtd-color-1";
                d.width = cw;
                d.height = ch;
                d.colorFormat = kColorFormat;
                sig->col[i] = make_target(*device_, d);
                d.label = i == 0 ? "rtd-moments-0" : "rtd-moments-1";
                d.colorFormat = momFormat;
                sig->mom[i] = make_target(*device_, d);
                ok = sig->col[i].valid(*device_) && sig->mom[i].valid(*device_);
                if (ok && half) {
                    d.label = i == 0 ? "rtd-hguide-0" : "rtd-hguide-1";
                    d.colorFormat = kColorFormat;
                    sig->hg[i] = make_target(*device_, d);
                    ok = sig->hg[i].valid(*device_);
                }
            }
            if (ok) {
                sig->w = cw;
                sig->h = ch;
                sig->momFormat = momFormat;
                sig->halfGuide = half;
            } else {
                destroy(*sig);
            }
        }
        if (!ok) {
            if (!refused_) {
                refused_ = true;
                FA_ERROR("render",
                         "Ray tracing denoiser: the GPU refused the history images of {}x{}. The signal is shown "
                         "without denoising. "
                         "Hint: lower the render scale or the window size.",
                         w, h);
            }
            cleanup_empty();
            return fail("the GPU refused the history images");
        }
    }

    // The camera's guide history (the first signal of the camera in this graph decides for all of them and declares the pass).
    const bool declareGuide = !(g.frameSerial == cam.serial && g.frameGraph == &graph);
    if (declareGuide) {
        DenoiseHistoryState gs;
        gs.wrote = g.wrote && (g.last == 0 || g.last == 1);
        gs.width = g.w;
        gs.height = g.h;
        gs.serial = g.serial;
        gs.sceneKey = g.sceneKey;
        gs.originShifts = g.originShifts;
        g.frameReason = denoise_reset_reason(gs, cam, w, h, 0);
        if (resizedGuide && g.frameReason == DenoiseReset::Fresh) g.frameReason = DenoiseReset::Resize;
        g.frameValid = g.frameReason == DenoiseReset::None;
        g.frameRead = g.frameValid ? g.last : -1;
        g.frameWrite = g.last == 0 ? 1 : 0;
        g.frameSerial = cam.serial;
        g.frameGraph = &graph;
    }
    g.planned = cam.serial;

    DenoiseHistoryState ss;
    ss.wrote = sig->wrote && (sig->last == 0 || sig->last == 1);
    ss.width = sig->w;
    ss.height = sig->h;
    ss.serial = sig->serial;
    ss.sceneKey = sig->sceneKey;
    ss.originShifts = sig->originShifts;
    ss.configKey = sig->configKey;
    DenoiseReset reason = denoise_reset_reason(ss, cam, cw, ch, plan.configKey);
    if (reason == DenoiseReset::Fresh && resizedSignal) reason = DenoiseReset::Resize;
    // The camera's full guide of the frame before is the history of a full size signal; a half size one keeps its own.
    if (reason == DenoiseReset::None && !half && !g.frameValid)
        reason = g.frameReason;  // the guides of the frame before are gone
    const bool histValid = reason == DenoiseReset::None;
    if (!histValid) ++resets_;
    sig->planned = cam.serial;
    sig->frameSerial = cam.serial;
    sig->frameGraph = &graph;
    sig->lastReset = reason;
    out.reset = reason;
    const int readIdx = histValid ? sig->last : -1;
    const int writeIdx = sig->last == 0 ? 1 : 0;
    const int guideRead = g.frameRead, guideWrite = g.frameWrite;

    // The graph's view of the images.
    const std::string sname = (signal.name.empty() ? std::string(kind_label(signal.kind)) : signal.name) + "-" +
                              std::to_string(signal.id);  // the id keeps two signals of one name apart
    const std::string base = (job.empty() ? std::string() : job + "/") + "denoise-" + sname;
    auto desc_at = [&](const std::string& label, gpu::PixelFormat f, int dw, int dh) {
        TransientDesc td;
        td.width = dw;
        td.height = dh;
        td.format = TargetFormat{f, gpu::PixelFormat::None, 1};
        td.label = label;
        return td;
    };
    auto desc_of = [&](const std::string& label, gpu::PixelFormat f) { return desc_at(label, f, w, h); };
    auto chain_desc = [&](const std::string& label, gpu::PixelFormat f) { return desc_at(label, f, cw, ch); };
    const ResourceId colOut = graph.import_target(base + "/history-out", sig->col[writeIdx].color.id,
                                                  chain_desc(base + "/history-out", kColorFormat));
    const ResourceId momOut = graph.import_target(base + "/moments-out", sig->mom[writeIdx].color.id,
                                                  chain_desc(base + "/moments-out", momFormat));
    ResourceId colIn, momIn, guideIn, hgOut, hgIn;
    if (histValid) {
        colIn = graph.import_target(base + "/history-in", sig->col[readIdx].color.id,
                                    chain_desc(base + "/history-in", kColorFormat));
        momIn = graph.import_target(base + "/moments-in", sig->mom[readIdx].color.id,
                                    chain_desc(base + "/moments-in", momFormat));
        if (half)
            hgIn = graph.import_target(base + "/hguide-in", sig->hg[readIdx].color.id,
                                       chain_desc(base + "/hguide-in", kColorFormat));
        else
            guideIn = graph.import_target(base + "/guide-in", g.img[guideRead].color.id,
                                          desc_of(base + "/guide-in", kColorFormat));
    }
    if (half)
        hgOut = graph.import_target(base + "/hguide-out", sig->hg[writeIdx].color.id,
                                    chain_desc(base + "/hguide-out", kColorFormat));
    const ResourceId accum = graph.create_transient(chain_desc(base + "/accumulated", kColorFormat));
    ResourceId bufA, bufB;
    bufA = graph.create_transient(chain_desc(base + "/filter-a", kColorFormat));
    if (st.iterations >= 3) bufB = graph.create_transient(chain_desc(base + "/filter-b", kColorFormat));
    const ResourceId downRes = half ? graph.create_transient(chain_desc(base + "/down", kColorFormat)) : ResourceId{};

    int declared = 0;
    auto add = [&](const std::string& name, std::vector<ResourceId> reads, std::vector<ResourceId> writes, auto&& fn) {
        GraphPass gp;
        gp.name = name;
        gp.reads = std::move(reads);
        gp.writes = std::move(writes);
        gp.execute = std::forward<decltype(fn)>(fn);
        graph.add_pass(std::move(gp));
        ++declared;
    };
    auto push_if = [](std::vector<ResourceId>& v, const DenoiseImage& im) {
        if (im.res.valid()) v.push_back(im.res);  // a persistent view with a resource (an imported image) orders too
    };

    RtDenoiser* self = this;
    Gpu* gp = &gpu;
    TransientTargets* tt = &targets;
    const std::shared_ptr<CamSlot> camHold = camp;
    const DenoiseImage noisy = in.noisy, prepass = in.prepass, velocity = in.velocity, roughness = in.roughness;
    const std::uint64_t serial = cam.serial, sceneKey = cam.sceneKey, shifts = cam.originShifts, cfg = plan.configKey;
    const float glFlip = gpu.is_gl() ? 1.0f : 0.0f;
    const float fw = float(w), fh = float(h), fcw = float(cw), fch = float(ch);
    const bool useRough = roughness.valid() && plan.hitDistance;

    // 0. the guide of the camera: depth and world normal. The next frame's disocclusion test reads it as the history and every pass of this
    // frame reads it instead of decoding the prepass's octahedral normal.
    if (declareGuide) {
        rt_denoise_rtd_guide_params_t gu{};
        world_columns(cam.view, gu.wx, gu.wy, gu.wz);
        std::vector<ResourceId> reads;
        push_if(reads, prepass);
        const ResourceId guideOut = graph.import_target(
            (job.empty() ? std::string() : job + "/") + "denoise-guide-out", g.img[guideWrite].color.id,
            desc_of((job.empty() ? std::string() : job + "/") + "denoise-guide-out", kColorFormat));
        g.frameRes = guideOut;
        add((job.empty() ? std::string() : job + "/") + "denoise-guide", std::move(reads), {guideOut},
            [=](const PassContext& c) {
                const gpu::View pre = prepass.get(c);
                if (!pre.id) return;
                PassDesc pd = pass_into(camHold->guide.img[guideWrite], "rtd-guide");
                pd.colorLoad = gpu::LoadAction::DontCare;
                DrawArgs a;
                a.views[VIEW_rt_denoise_tex_p] = pre;
                a.params = &gu;
                a.paramBytes = sizeof(gu);
                a.paramSlot = UB_rt_denoise_rtd_guide_params;
                if (!self->draw(pass_list(c, *gp), *gp, Prog::Guide, pd, a)) return;
                GuideSlot& gs = camHold->guide;
                gs.last = guideWrite;
                gs.wrote = true;
                gs.serial = serial;
                gs.sceneKey = sceneKey;
                gs.originShifts = shifts;
                if (drawCalls) ++*drawCalls;
            });
    }
    const ResourceId guideRes = g.frameRes;

    // The camera's guide of THIS frame, or null when the pass that writes it did not run (the pass is skipped when the prepass is gone, and
    // the passes that read the guide would read what the frame before left there).
    auto guide_now = [camHold, guideWrite, serial]() -> const Target* {
        const GuideSlot& gs = camHold->guide;
        return gs.wrote && gs.serial == serial && gs.last == guideWrite ? &gs.img[guideWrite] : nullptr;
    };

    // 0b. half size: the signal's own guide (the nearest drawn pixel of every 2x2 block), then the noisy signal's mean over the pixels of the
    // block that show that surface.
    if (half) {
        rt_denoise_rtd_guide_half_params_t gu{};
        set4(gu.a, glFlip, fcw, fch, 0.0f);
        set4(gu.b, fw, fh, 0.0f, 0.0f);
        add(base + "-guide-half", {guideRes}, {hgOut}, [=](const PassContext& c) {
            const Target* full = guide_now();
            SignalSlot& s = *sig;
            if (!full || !full->texView.id) return;
            PassDesc pd = pass_into(s.hg[writeIdx], "rtd-guide-half");
            pd.colorLoad = gpu::LoadAction::DontCare;
            DrawArgs a;
            a.views[VIEW_rt_denoise_tex_g] = full->texView;
            a.params = &gu;
            a.paramBytes = sizeof(gu);
            a.paramSlot = UB_rt_denoise_rtd_guide_half_params;
            if (!self->draw(pass_list(c, *gp), *gp, Prog::GuideHalf, pd, a)) return;
            s.guideSerial = serial;
            if (drawCalls) ++*drawCalls;
        });

        rt_denoise_rtd_down_params_t du{};
        set4(du.a, glFlip, fcw, fch, 0.0f);
        set4(du.b, fw, fh, std::min(st.depthTolerance * kDownDepthScale, 1.0f), kMinNormalDot);
        set4(du.s, float(plan.channels), 0.0f, 0.0f, 0.0f);
        std::vector<ResourceId> reads{guideRes, hgOut};
        push_if(reads, noisy);
        add(base + "-down", std::move(reads), {downRes}, [=](const PassContext& c) {
            const Target* full = guide_now();
            const Target* dst = tt->get(c.handle(downRes));
            const gpu::View nz = noisy.get(c);
            SignalSlot& s = *sig;
            if (!full || !dst || !nz.id || s.guideSerial != serial) return;
            DrawArgs a;
            a.views[VIEW_rt_denoise_tex_n] = nz;
            a.views[VIEW_rt_denoise_tex_g] = full->texView;
            a.views[VIEW_rt_denoise_tex_gh] = s.hg[writeIdx].texView;
            a.params = &du;
            a.paramBytes = sizeof(du);
            a.paramSlot = UB_rt_denoise_rtd_down_params;
            PassDesc pd = pass_into(*dst, "rtd-down");
            pd.colorLoad = gpu::LoadAction::DontCare;
            if (!self->draw(pass_list(c, *gp), *gp, Prog::Down, pd, a)) return;
            if (drawCalls) ++*drawCalls;
        });
    }

    // The guide the temporal and a-trous passes read at the chain's size: the camera's, or the half size signal's own.
    const ResourceId chainGuideRes = half ? hgOut : guideRes;
    auto chain_guide = [sig, half, writeIdx, guide_now, serial]() -> const Target* {
        if (!half) return guide_now();
        return sig->guideSerial == serial ? &sig->hg[writeIdx] : nullptr;
    };

    // 1. the temporal accumulation: noisy + guides + history -> the accumulated colour (T) and the moments (the history)
    {
        rt_denoise_rtd_temporal_params_t u{};
        set4(u.a, glFlip, fcw, fch, histValid ? 1.0f : 0.0f);
        set4(u.s, float(plan.channels), float(int(plan.kind)), st.maxHistory,
             plan.channels == 1 ? 0.0f : st.fireflyClamp);
        set4(u.f, velocity.valid() ? 1.0f : 0.0f, st.depthTolerance, kMinNormalDot, plan.hitDistance ? 1.0f : 0.0f);
        set4(u.pa, cam.proj[0], cam.proj[1], cam.proj[2], cam.proj[3]);
        set4(u.pb, cam.proj[4], cam.proj[5], cam.proj[6], cam.proj[7]);
        for (int i = 0; i < 16; ++i) u.m[i] = cam.prevFromView.m[i];
        world_columns(cam.view, u.wx, u.wy, u.wz);
        set4(u.sv, st.depthTolerance, kMinNormalDot, 0.0f, 0.0f);
        set4(u.rr, plan.roughMin, plan.roughMax, useRough ? 1.0f : 0.0f, 0.0f);
        set4(u.hf, half ? 1.0f : 0.0f, fw, fh, 0.0f);
        std::vector<ResourceId> reads{chainGuideRes};
        if (half) {
            reads.push_back(downRes);
            reads.push_back(guideRes);  // the full guide: the velocity texel of a block is the one the half guide took
        } else {
            push_if(reads, noisy);
        }
        push_if(reads, velocity);
        if (useRough) push_if(reads, roughness);
        if (histValid) {
            reads.push_back(colIn);
            reads.push_back(momIn);
            reads.push_back(half ? hgIn : guideIn);
        }
        const TargetFormat tf{kColorFormat, gpu::PixelFormat::None, 1, momFormat};
        add(base + "-temporal", std::move(reads), {accum, momOut}, [=](const PassContext& c) {
            const Target* t = tt->get(c.handle(accum));
            const gpu::View nz =
                half ? (tt->get(c.handle(downRes)) ? tt->get(c.handle(downRes))->texView : gpu::View{}) : noisy.get(c);
            const Target* gnow = chain_guide();
            if (!t || !nz.id || !gnow || !gnow->texView.id) return;
            SignalSlot& s = *sig;
            DrawArgs a;
            a.views[VIEW_rt_denoise_tex_n] = nz;
            a.views[VIEW_rt_denoise_tex_g] = gnow->texView;
            const gpu::View vel = velocity.valid() ? velocity.get(c) : gpu::View{};
            a.views[VIEW_rt_denoise_tex_v] = vel.id ? vel : gnow->texView;
            a.views[VIEW_rt_denoise_tex_hc] = readIdx >= 0 ? s.col[readIdx].texView : gnow->texView;
            a.views[VIEW_rt_denoise_tex_hm] = readIdx >= 0 ? s.mom[readIdx].texView : gnow->texView;
            const Target* hgt = readIdx < 0 ? nullptr : (half ? &s.hg[readIdx] : &camHold->guide.img[guideRead]);
            a.views[VIEW_rt_denoise_tex_hg] = hgt && (half || guideRead >= 0) ? hgt->texView : gnow->texView;
            const gpu::View rough = useRough ? roughness.get(c) : gpu::View{};
            a.views[VIEW_rt_denoise_tex_r] = rough.id ? rough : gnow->texView;
            const Target* fullGuide = half ? guide_now() : nullptr;
            if (half && (!fullGuide || !fullGuide->texView.id)) return;
            a.views[VIEW_rt_denoise_tex_c] = fullGuide ? fullGuide->texView : gnow->texView;
            a.params = &u;
            a.paramBytes = sizeof(u);
            a.paramSlot = UB_rt_denoise_rtd_temporal_params;
            PassDesc pd = pass_into(*t, "rtd-temporal");
            pd.format = tf;
            pd.color1 = s.mom[writeIdx].colorAtt;
            pd.colorLoad = gpu::LoadAction::DontCare;
            pd.colorStore = gpu::StoreAction::Store;
            if (!self->draw(pass_list(c, *gp), *gp, Prog::Temporal, pd, a)) return;
            s.temporalSerial = serial;
            s.usedHistory = readIdx >= 0;
            if (drawCalls) ++*drawCalls;
        });
    }

    // 2. the a-trous iterations. The first one's result is the history (the filter of step 1); the last one's is what the caller gets
    // (a half size signal's goes through the upsample first).
    ResourceId src = accum, last = accum;
    for (int it = 0; it < st.iterations; ++it) {
        rt_denoise_rtd_atrous_params_t u{};
        set4(u.a, glFlip, fcw, fch, float(1 << it));
        set4(u.s, float(plan.channels), float(int(plan.kind)), st.depthTolerance, st.normalPower);
        set4(u.f, st.lumaSigma, useRough ? 1.0f : 0.0f, st.roughness, (it >= 1 && it < kWideFrom) ? 2.0f : 1.0f);
        set4(u.cam, cam.halfX, cam.halfY, cam.ortho ? 1.0f : 0.0f, it >= kCalmFrom ? kCalmSd : 0.0f);
        world_columns(cam.view, u.wx, u.wy, u.wz);
        const ResourceId dst = it == 0 ? colOut : (it % 2 == 1 ? bufA : bufB);
        std::vector<ResourceId> reads{src, momOut,
                                      chainGuideRes};  // the guide of this frame: depth and world normal of every tap
        if (useRough) push_if(reads, roughness);
        const bool dstIsHistory = it == 0, srcIsHistory = it == 1;
        const ResourceId from = src;
        add(base + "-atrous" + std::to_string(it), std::move(reads), {dst}, [=](const PassContext& c) {
            SignalSlot& s = *sig;
            const Target* gnow =
                chain_guide();  // null when the guide pass did not run this frame: nothing is read stale
            const Target* srcT = srcIsHistory ? &s.col[writeIdx] : tt->get(c.handle(from));
            const Target* dstT = dstIsHistory ? &s.col[writeIdx] : tt->get(c.handle(dst));
            if (!gnow || !gnow->texView.id || !srcT || !dstT || !srcT->texView.id) return;
            DrawArgs a;
            a.views[VIEW_rt_denoise_tex_c] = srcT->texView;
            a.views[VIEW_rt_denoise_tex_g] = gnow->texView;
            a.views[VIEW_rt_denoise_tex_hm] = s.mom[writeIdx].texView;
            const gpu::View rough = useRough ? roughness.get(c) : gpu::View{};
            a.views[VIEW_rt_denoise_tex_r] = rough.id ? rough : gnow->texView;
            a.params = &u;
            a.paramBytes = sizeof(u);
            a.paramSlot = UB_rt_denoise_rtd_atrous_params;
            PassDesc pd = pass_into(*dstT, "rtd-atrous");
            pd.colorLoad = gpu::LoadAction::DontCare;
            if (!self->draw(pass_list(c, *gp), *gp, Prog::Atrous, pd, a)) return;
            if (dstIsHistory &&
                s.temporalSerial == serial) {  // the history of the next frame: this frame's colour and moments
                s.last = writeIdx;
                s.wrote = true;
                s.serial = serial;
                s.sceneKey = sceneKey;
                s.originShifts = shifts;
                s.configKey = cfg;
            }
            if (drawCalls) ++*drawCalls;
        });
        src = dst;
        last = dst;
    }

    // 2b. half size: the joint bilateral upsample to the camera's size, steered by the camera's full guide against the half guide.
    if (half) {
        const ResourceId chainLast = last;
        const ResourceId upRes = graph.create_transient(desc_of(base + "/up", kColorFormat));
        rt_denoise_rtd_up_params_t uu{};
        set4(uu.a, glFlip, fw, fh, 0.0f);
        set4(uu.b, fcw, fch, st.depthTolerance, st.normalPower);
        set4(uu.s, float(plan.channels), 0.0f, 0.0f, 0.0f);
        set4(uu.cam, cam.halfX, cam.halfY, cam.ortho ? 1.0f : 0.0f, 0.0f);
        world_columns(cam.view, uu.wx, uu.wy, uu.wz);
        std::vector<ResourceId> reads{chainLast, guideRes, hgOut};
        push_if(reads, noisy);
        add(base + "-up", std::move(reads), {upRes}, [=](const PassContext& c) {
            const Target* full = guide_now();
            const Target* halfT = tt->get(c.handle(chainLast));
            const Target* dst = tt->get(c.handle(upRes));
            const gpu::View nz = noisy.get(c);
            SignalSlot& s = *sig;
            if (!full || !halfT || !dst || !nz.id || !halfT->texView.id || s.guideSerial != serial) return;
            DrawArgs a;
            a.views[VIEW_rt_denoise_tex_n] = nz;
            a.views[VIEW_rt_denoise_tex_g] = full->texView;
            a.views[VIEW_rt_denoise_tex_gh] = s.hg[writeIdx].texView;
            a.views[VIEW_rt_denoise_tex_c] = halfT->texView;
            a.params = &uu;
            a.paramBytes = sizeof(uu);
            a.paramSlot = UB_rt_denoise_rtd_up_params;
            PassDesc pd = pass_into(*dst, "rtd-up");
            pd.colorLoad = gpu::LoadAction::DontCare;
            if (!self->draw(pass_list(c, *gp), *gp, Prog::Up, pd, a)) return;
            if (drawCalls) ++*drawCalls;
        });
        last = upRes;
    }
    out.res = last;

    // 3. the debug view: the history length or the standard deviation of the estimate as a grey picture.
    if (signal.debug != DenoiseDebug::None) {
        const ResourceId dbg = graph.create_transient(desc_of(base + "/debug", kColorFormat));
        rt_denoise_rtd_debug_params_t u{};
        set4(u.a, signal.debug == DenoiseDebug::HistoryLength ? 1.0f : 2.0f, 0.0f, 0.0f, 0.0f);
        set4(u.s, st.maxHistory, 0.0f, 0.0f, 0.0f);
        add(base + "-debug", {last, momOut}, {dbg}, [=](const PassContext& c) {
            const Target* from = tt->get(c.handle(last));
            const Target* to = tt->get(c.handle(dbg));
            if (!from || !to) return;
            DrawArgs a;
            a.views[VIEW_rt_denoise_tex_c] = from->texView;
            a.views[VIEW_rt_denoise_tex_hm] = sig->mom[writeIdx].texView;
            a.params = &u;
            a.paramBytes = sizeof(u);
            a.paramSlot = UB_rt_denoise_rtd_debug_params;
            PassDesc pd = pass_into(*to, "rtd-debug");
            pd.colorLoad = gpu::LoadAction::DontCare;
            if (!self->draw(pass_list(c, *gp), *gp, Prog::Debug, pd, a)) return;
            if (drawCalls) ++*drawCalls;
        });
        out.debug = dbg;
    }
    out.valid = true;
    out.width = w;
    out.height = h;
    out.passes = declared;
    return out;
}
#if defined(_MSC_VER)
#pragma warning(pop)
#endif

}  // namespace fa::render
