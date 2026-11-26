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
                  UB_rt_denoise_rtd_atrous_params == 1 && UB_rt_denoise_rtd_debug_params == 1,
              "the denoise fragment uniform slots");
static_assert(VIEW_rt_denoise_tex_n == 0 && VIEW_rt_denoise_tex_p == 1 && VIEW_rt_denoise_tex_v == 2 &&
                  VIEW_rt_denoise_tex_hc == 3 && VIEW_rt_denoise_tex_hm == 4 && VIEW_rt_denoise_tex_hg == 5 &&
                  VIEW_rt_denoise_tex_c == 6 && VIEW_rt_denoise_tex_r == 7,
              "the denoise view slots");
static_assert(SMP_rt_denoise_smp_pt == 0, "the denoise sampler slot");

constexpr gpu::PixelFormat kColorFormat = gpu::PixelFormat::Rgba16F;
constexpr float kMinNormalDot =
    0.9f;  // the cosine between two normals below which the temporal pass and the variance estimate see two surfaces

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
std::uint64_t config_key(DenoiseKind kind, const DenoiseSettings& s) {
    std::uint64_t h = 1469598103934665603ull;
    h = mix_hash(h, std::uint64_t(kind));
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
    p.signalPasses = 1 + p.settings.iterations + (dbg ? 1 : 0);
    p.guidePasses = 1;
    p.transients = 1 + std::min(p.settings.iterations - 1, 2) + (dbg ? 1 : 0);
    p.historyImages = 4;
    p.hitDistance = signal.kind == DenoiseKind::Specular || signal.kind == DenoiseKind::Coverage;
    p.configKey = config_key(signal.kind, p.settings);
    p.historyBytes = sat_add(image_bytes(width, height, 8, 2), image_bytes(width, height, momentsF32 ? 16 : 8, 2));
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
    for (gpu::Shader sh : shaders_) ok = ok && dev.state(sh) == gpu::ResourceState::Valid;
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

gpu::Pipeline RtDenoiser::pipeline(Prog prog, const TargetFormat& format) {
    for (const PipelineEntry& e : pipelines_)
        if (e.prog == prog && e.format == format) return e.pipeline;
    if (state_ <= 0 || !device_) return {};
    static const char* const kLabels[int(Prog::Count)] = {"rtd-guide", "rtd-temporal", "rtd-atrous", "rtd-debug"};
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
    }
    s.w = s.h = 0;
    s.last = -1;
    s.wrote = false;
    s.frameSerial = 0;
    s.frameGraph = nullptr;
}

std::uint64_t RtDenoiser::guide_bytes_of(const GuideSlot& g) { return g.w > 0 ? image_bytes(g.w, g.h, 8, 2) : 0; }

std::uint64_t RtDenoiser::signal_bytes_of(const SignalSlot& s) {
    if (s.w <= 0) return 0;
    const std::uint64_t mom = s.momFormat == gpu::PixelFormat::Rgba32F ? 16 : 8;
    return sat_add(image_bytes(s.w, s.h, 8, 2), image_bytes(s.w, s.h, mom, 2));
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
    auto fail = [&](const char* why) {
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
    const DenoisePlan plan = make_denoise_plan(signal, w, h, momentsF32);
    if (!plan.on) return fail("nothing to do");
    const DenoiseSettings& st = plan.settings;

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
    const bool resizedSignal = sig->wrote && (sig->w != w || sig->h != h);

    // The images: made now when they do not exist or have another size; the budget counts every other history (64-bit, saturated).
    const bool needGuide = !(g.w == w && g.h == h && g.img[0].valid(*device_) && g.img[1].valid(*device_));
    const bool needSignal =
        !(sig->w == w && sig->h == h && sig->momFormat == momFormat && sig->col[0].valid(*device_) &&
          sig->col[1].valid(*device_) && sig->mom[0].valid(*device_) && sig->mom[1].valid(*device_));
    if (needGuide || needSignal) {
        const std::uint64_t budget = budgetOverride_ ? budgetOverride_ : kBudgetBytes;
        const std::uint64_t used = used_bytes(needGuide ? &g : nullptr, needSignal ? sig.get() : nullptr);
        const std::uint64_t wanted = sat_add(needGuide ? plan.guideBytes : 0, needSignal ? plan.historyBytes : 0);
        if (sat_add(used, wanted) > budget) {
            if (!refused_) {
                refused_ = true;
                FA_ERROR("render",
                         "Ray tracing denoiser: signal '{}' of camera '{}' needs history images of {}x{} and the "
                         "renderer cannot hold "
                         "them (the histories take at most {} MB). The signal is shown without denoising. Hint: lower "
                         "the render scale "
                         "or the window size.",
                         signal.name.empty() ? kind_label(signal.kind) : signal.name, job, w, h, budget >> 20);
            }
            cleanup_empty();
            return fail("the history images do not fit the budget");
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
                d.width = w;
                d.height = h;
                d.colorFormat = kColorFormat;
                sig->col[i] = make_target(*device_, d);
                d.label = i == 0 ? "rtd-moments-0" : "rtd-moments-1";
                d.colorFormat = momFormat;
                sig->mom[i] = make_target(*device_, d);
                ok = sig->col[i].valid(*device_) && sig->mom[i].valid(*device_);
            }
            if (ok) {
                sig->w = w;
                sig->h = h;
                sig->momFormat = momFormat;
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
    DenoiseReset reason = denoise_reset_reason(ss, cam, w, h, plan.configKey);
    if (reason == DenoiseReset::Fresh && resizedSignal) reason = DenoiseReset::Resize;
    if (reason == DenoiseReset::None && !g.frameValid)
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
    auto desc_of = [&](const std::string& label, gpu::PixelFormat f) {
        TransientDesc td;
        td.width = w;
        td.height = h;
        td.format = TargetFormat{f, gpu::PixelFormat::None, 1};
        td.label = label;
        return td;
    };
    const ResourceId colOut = graph.import_target(base + "/history-out", sig->col[writeIdx].color.id,
                                                  desc_of(base + "/history-out", kColorFormat));
    const ResourceId momOut = graph.import_target(base + "/moments-out", sig->mom[writeIdx].color.id,
                                                  desc_of(base + "/moments-out", momFormat));
    ResourceId colIn, momIn, guideIn;
    if (histValid) {
        colIn = graph.import_target(base + "/history-in", sig->col[readIdx].color.id,
                                    desc_of(base + "/history-in", kColorFormat));
        momIn = graph.import_target(base + "/moments-in", sig->mom[readIdx].color.id,
                                    desc_of(base + "/moments-in", momFormat));
        guideIn = graph.import_target(base + "/guide-in", g.img[guideRead].color.id,
                                      desc_of(base + "/guide-in", kColorFormat));
    }
    const ResourceId accum = graph.create_transient(desc_of(base + "/accumulated", kColorFormat));
    ResourceId bufA, bufB;
    bufA = graph.create_transient(desc_of(base + "/filter-a", kColorFormat));
    if (st.iterations >= 3) bufB = graph.create_transient(desc_of(base + "/filter-b", kColorFormat));

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
    const float fw = float(w), fh = float(h);

    // 0. the guide history of the camera: depth and world normal for the next frame's disocclusion test.
    if (declareGuide) {
        rt_denoise_rtd_guide_params_t gu{};
        world_columns(cam.view, gu.wx, gu.wy, gu.wz);
        std::vector<ResourceId> reads;
        push_if(reads, prepass);
        const ResourceId guideOut = graph.import_target(
            (job.empty() ? std::string() : job + "/") + "denoise-guide-out", g.img[guideWrite].color.id,
            desc_of((job.empty() ? std::string() : job + "/") + "denoise-guide-out", kColorFormat));
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

    // 1. the temporal accumulation: noisy + guides + history -> the accumulated colour (T) and the moments (the history)
    {
        rt_denoise_rtd_temporal_params_t u{};
        set4(u.a, glFlip, fw, fh, histValid ? 1.0f : 0.0f);
        set4(u.s, float(plan.channels), float(int(plan.kind)), st.maxHistory,
             plan.channels == 1 ? 0.0f : st.fireflyClamp);
        set4(u.f, velocity.valid() ? 1.0f : 0.0f, st.depthTolerance, kMinNormalDot, plan.hitDistance ? 1.0f : 0.0f);
        set4(u.pa, cam.proj[0], cam.proj[1], cam.proj[2], cam.proj[3]);
        set4(u.pb, cam.proj[4], cam.proj[5], cam.proj[6], cam.proj[7]);
        for (int i = 0; i < 16; ++i) u.m[i] = cam.prevFromView.m[i];
        world_columns(cam.view, u.wx, u.wy, u.wz);
        set4(u.sv, st.depthTolerance, kMinNormalDot, 0.0f, 0.0f);
        std::vector<ResourceId> reads;
        push_if(reads, noisy);
        push_if(reads, prepass);
        push_if(reads, velocity);
        if (histValid) {
            reads.push_back(colIn);
            reads.push_back(momIn);
            reads.push_back(guideIn);
        }
        const TargetFormat tf{kColorFormat, gpu::PixelFormat::None, 1, momFormat};
        add(base + "-temporal", std::move(reads), {accum, momOut}, [=](const PassContext& c) {
            const Target* t = tt->get(c.handle(accum));
            const gpu::View nz = noisy.get(c), pre = prepass.get(c);
            if (!t || !nz.id || !pre.id) return;
            SignalSlot& s = *sig;
            DrawArgs a;
            a.views[VIEW_rt_denoise_tex_n] = nz;
            a.views[VIEW_rt_denoise_tex_p] = pre;
            const gpu::View vel = velocity.valid() ? velocity.get(c) : gpu::View{};
            a.views[VIEW_rt_denoise_tex_v] = vel.id ? vel : pre;
            a.views[VIEW_rt_denoise_tex_hc] = readIdx >= 0 ? s.col[readIdx].texView : pre;
            a.views[VIEW_rt_denoise_tex_hm] = readIdx >= 0 ? s.mom[readIdx].texView : pre;
            a.views[VIEW_rt_denoise_tex_hg] =
                readIdx >= 0 && guideRead >= 0 ? camHold->guide.img[guideRead].texView : pre;
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

    // 2. the a-trous iterations. The first one's result is the history (the filter of step 1); the last one's is what the caller gets.
    ResourceId src = accum, last = accum;
    for (int it = 0; it < st.iterations; ++it) {
        rt_denoise_rtd_atrous_params_t u{};
        set4(u.a, glFlip, fw, fh, float(1 << it));
        set4(u.s, float(plan.channels), float(int(plan.kind)), st.depthTolerance, st.normalPower);
        set4(u.f, st.lumaSigma, roughness.valid() ? 1.0f : 0.0f, st.roughness, 0.0f);
        set4(u.cam, cam.halfX, cam.halfY, cam.ortho ? 1.0f : 0.0f, 0.0f);
        const ResourceId dst = it == 0 ? colOut : (it % 2 == 1 ? bufA : bufB);
        std::vector<ResourceId> reads{src, momOut};
        push_if(reads, prepass);
        push_if(reads, roughness);
        const bool dstIsHistory = it == 0, srcIsHistory = it == 1;
        const ResourceId from = src;
        add(base + "-atrous" + std::to_string(it), std::move(reads), {dst}, [=](const PassContext& c) {
            const gpu::View pre = prepass.get(c);
            SignalSlot& s = *sig;
            const Target* srcT = srcIsHistory ? &s.col[writeIdx] : tt->get(c.handle(from));
            const Target* dstT = dstIsHistory ? &s.col[writeIdx] : tt->get(c.handle(dst));
            if (!pre.id || !srcT || !dstT || !srcT->texView.id) return;
            DrawArgs a;
            a.views[VIEW_rt_denoise_tex_c] = srcT->texView;
            a.views[VIEW_rt_denoise_tex_p] = pre;
            a.views[VIEW_rt_denoise_tex_hm] = s.mom[writeIdx].texView;
            const gpu::View rough = roughness.valid() ? roughness.get(c) : gpu::View{};
            a.views[VIEW_rt_denoise_tex_r] = rough.id ? rough : pre;
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
