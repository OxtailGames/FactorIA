#include "renderer_taa.h"

#include <algorithm>
#include <cmath>
#include <limits>

#include "fa/core/log.h"

#include "postprocess.h"
#include "postprocess_resolve.h"
#include "fullscreen_gpu.h"
#include "shader_cache.h"
#include "gpu/sokol_shaders.h"
#include "shaders/taa.glsl.h"

namespace fa::render {

namespace {

float finite_or(float v, float fallback) { return std::isfinite(v) ? v : fallback; }

static_assert(UB_taa_taa_vs_params == 0 && UB_taa_taa_params == 1, "the taa program uniform slots");
static_assert(VIEW_taa_tex_c == 0 && VIEW_taa_tex_p == 1 && VIEW_taa_tex_v == 2 && VIEW_taa_tex_h == 3 &&
                  VIEW_taa_tex_r == 4,
              "the taa resolve view slots");
static_assert(VIEW_taa_tex_o == 5, "the taa output view slot");
static_assert(SMP_taa_smp_lin == 0 && SMP_taa_smp_pt == 1 && SMP_taa_smp_o == 2, "the taa sampler slots");

// What the histories of all the cameras may take: a float image is eight bytes a pixel, two images a camera. A wasm32 build has a quarter.
constexpr std::uint64_t kBudgetBytes = sizeof(void*) >= 8 ? (std::uint64_t(1) << 30) : (std::uint64_t(256) << 20);

// 64-bit and saturated: a huge size cannot wrap around to a small number.
std::uint64_t history_bytes(int w, int h, gpu::PixelFormat format) {
    constexpr std::uint64_t kCap = std::numeric_limits<std::uint64_t>::max() / 4;
    const std::uint64_t perPixel = format == gpu::PixelFormat::Rgba16F ? 8 : 4;
    const std::uint64_t px = std::uint64_t(std::max(w, 0)) * std::uint64_t(std::max(h, 0));  // < 2^62
    if (px > kCap / (2 * perPixel)) return kCap;
    return 2 * perPixel * px;
}

struct Rect {
    int x = 0, y = 0, w = 0, h = 0;
    bool whole = true;
};
Rect rect_of(const PostRect& r, int picW, int picH) {
    Rect o;
    o.whole = r.whole(picW, picH);
    o.x = o.whole ? 0 : r.x;
    o.y = o.whole ? 0 : r.y;
    o.w = o.whole ? picW : r.w;
    o.h = o.whole ? picH : r.h;
    return o;
}

}  // namespace

namespace {

// The plan of `cam` with the numbers of `f` (clamped); the callers decide whether there is one.
TaaPlan build_taa_plan(const CameraInfo& cam, const PostProcess& f, std::uint64_t camKey, std::uint64_t serial,
                       std::uint64_t sceneKey, std::uint64_t originShifts, const Mat4& prevViewProj, bool prevValid) {
    TaaPlan p;
    p.gamma = std::clamp(finite_or(f.temporalAAVarianceGamma, 1.0f), 0.5f, 2.0f);
    p.feedback = std::clamp(finite_or(f.temporalAAFeedback, 0.9f), 0.5f, 0.98f);
    p.sharpen = std::clamp(finite_or(f.temporalAASharpen, 0.25f), 0.0f, 1.0f);
    p.reactiveScale = std::clamp(finite_or(f.temporalAAReactiveScale, 1.0f), 0.0f, 4.0f);
    p.jitterPx = cam.jitterPx;
    p.camKey = camKey;
    p.serial = serial;
    p.sceneKey = sceneKey;
    p.originShifts = originShifts;
    const Mat4& P = cam.proj;
    const float terms[8] = {P.at(0, 0), P.at(1, 1), P.at(2, 0), P.at(2, 1),
                            P.at(3, 0), P.at(3, 1), P.at(2, 3), P.at(3, 3)};
    bool finite = std::fabs(P.at(0, 0)) > 1e-12f && std::fabs(P.at(1, 1)) > 1e-12f;
    for (float t : terms) finite = finite && std::isfinite(t);
    for (int i = 0; i < 8; ++i) p.proj[i] = terms[i];
    p.on = true;
    if (prevValid && finite) {
        // A view-space position of this frame -> the clip position of the frame before. (viewProj)^-1 * proj = view^-1, whatever the depth
        // range of the matrices (a backend's), which only the z row of the clip position sees.
        p.prevFromView = prevViewProj * cam.view.inverse();
        for (int i = 0; i < 16; ++i) finite = finite && std::isfinite(p.prevFromView.m[i]);
        p.prevValid = finite;  // a matrix that is not usable: the camera starts a new history (a cut)
    }
    return p;
}

}  // namespace

TaaPlan make_taa_plan(const CameraInfo& cam, const PostStack& stack, bool gameFrame, bool available,
                      std::uint64_t camKey, std::uint64_t serial, std::uint64_t sceneKey, std::uint64_t originShifts,
                      const Mat4& prevViewProj, bool prevValid) {
    if (!gameFrame || !available || !stack.has(PostEffect::TemporalAA)) return TaaPlan{};
    return build_taa_plan(cam, stack.fx, camKey, serial, sceneKey, originShifts, prevViewProj, prevValid);
}

TaaPlan make_upscale_taa_plan(const CameraInfo& cam, const PostStack* stack, bool gameFrame, bool available,
                              float sharpness, std::uint64_t serial, std::uint64_t sceneKey, std::uint64_t originShifts,
                              const Mat4& prevViewProj, bool prevValid) {
    if (!gameFrame || !available) return TaaPlan{};
    static const PostProcess kDefaults;
    const PostProcess& f = stack && stack->has(PostEffect::TemporalAA) ? stack->fx : kDefaults;
    TaaPlan p = build_taa_plan(cam, f, kUpscaleCamKey, serial, sceneKey, originShifts, prevViewProj, prevValid);
    p.sharpen = std::clamp(p.sharpen * finite_or(sharpness, 0.5f) / 0.5f, 0.0f, 1.0f);
    return p;
}

bool TaaFx::ready(gpu::Device& dev) {
    if (state_ != 0) return state_ > 0;
    device_ = &dev;
    shaders_[int(Prog::Resolve)] =
        make_shader(dev, gpu::generated_shader_desc(dev, taa_taa_shader_desc), "taa_resolve");
    shaders_[int(Prog::Out)] = make_shader(dev, gpu::generated_shader_desc(dev, taa_out_shader_desc), "taa_out");
    bool ok = true;
    for (gpu::Shader sh : shaders_) ok = ok && dev.state(sh) == gpu::ResourceState::Valid;
    if (!ok) {
        for (gpu::Shader& sh : shaders_) {
            if (sh.id) dev.destroy_shader(sh);
            sh = {};
        }
        state_ = -1;
        FA_ERROR("render", "Temporal antialiasing is unavailable: its shaders failed to compile for this graphics "
                           "backend (see the sokol log "
                           "lines above). The game renders without it and without the camera jitter. Hint: update the "
                           "graphics driver (Mesa: try "
                           "LIBGL_ALWAYS_SOFTWARE=1) or turn temporalAAEnabled off.");
        return false;
    }
    state_ = 1;
    return true;
}

gpu::Pipeline TaaFx::pipeline(Prog prog, const TargetFormat& format) {
    for (const PipelineEntry& e : pipelines_)
        if (e.prog == prog && e.format == format) return e.pipeline;
    if (state_ <= 0 || !device_) return {};
    const char* label = prog == Prog::Resolve ? "taa-resolve" : "taa-output";
    // `pos`, location 0. The output pass writes the colour of the picture and leaves its alpha (coverage) as the passes before made it.
    const gpu::Pipeline p = make_triangle_pipeline(*device_, shaders_[int(prog)], format, label, 0,
                                                   prog == Prog::Out ? gpu::ColorMask::Rgb : gpu::ColorMask::Default);
    if (device_->state(p) != gpu::ResourceState::Valid) FA_ERROR("render", "failed to create pipeline '{}'", label);
    pipelines_.push_back({prog, format, p});
    return p;
}

gpu::PixelFormat TaaFx::pick_format() {
    gpu::PixelFormat f = gpu::PixelFormat::Rgba16F;
    const gpu::PixelFormatCaps info = device_->pixel_format_caps(gpu::PixelFormat::Rgba16F);  // after a ready()
    if (forceRgba8_ || !(info.render && info.sample && info.filter)) {
        f = gpu::PixelFormat::Rgba8;
        if (!warnedFormat_) {
            warnedFormat_ = true;
            FA_INFO("render",
                    "Temporal antialiasing: this GPU cannot render to half-float images, so the history is 8 bits per "
                    "channel "
                    "(colours above 1 are clipped in it and the depth that rejects a surface that was uncovered is not "
                    "kept: more "
                    "ghosting behind moving objects). Hint: nothing to do; a GPU with half-float targets keeps both.");
        }
    }
    format_ = f;
    return f;
}

void TaaFx::force_rgba8(bool force) {
    forceRgba8_ = force;
    reset();
}

void TaaFx::destroy(Slot& s) {
    if (device_)
        for (Target& t : s.img) destroy_target(*device_, t);
    s.wrote = false;
    s.last = -1;
}

std::shared_ptr<TaaFx::Slot> TaaFx::slot_for(std::uint64_t camKey, int w, int h, gpu::PixelFormat format,
                                             const std::string& job) {
    std::shared_ptr<Slot> slot;
    if (const auto it = slots_.find(camKey); it != slots_.end()) slot = it->second;
    if (slot && slot->w == w && slot->h == h && slot->format == format && slot->img[0].valid(*device_) &&
        slot->img[1].valid(*device_))
        return slot;
    // The budget counts every other camera's images (this one is made again).
    std::uint64_t used = 0;
    for (const auto& e : slots_)
        if (e.second != slot)
            used = std::min<std::uint64_t>(used + history_bytes(e.second->w, e.second->h, e.second->format),
                                           kBudgetBytes + 1);
    const std::uint64_t wanted = history_bytes(w, h, format);
    if (!slot) slot = std::make_shared<Slot>();
    destroy(*slot);
    const std::uint64_t budget = budgetOverride_ ? budgetOverride_ : kBudgetBytes;
    bool ok = used + wanted <= budget;
    for (int i = 0; i < 2 && ok; ++i) {
        TargetDesc d;
        d.label = i == 0 ? "taa-history-0" : "taa-history-1";
        d.width = w;
        d.height = h;
        d.colorFormat = format;
        slot->img[i] = make_target(*device_, d);
        ok = slot->img[i].valid(*device_);
    }
    if (!ok) {
        destroy(*slot);
        slots_.erase(camKey);
        if (camKey == kUpscaleCamKey) {
            upscaleRefused_ = true;
            FA_ERROR(
                "render",
                "Temporal upscaler: it needs a history of {}x{} (the output size) and the renderer cannot hold it (the "
                "histories take at most {} MB, or the GPU refused the images). The game is upscaled with the spatial "
                "upscaler instead. Hint: lower the window size, or set render.upscaler mode to \"spatial\".",
                w, h, budget >> 20);
        } else {
            refused_ = true;
            FA_ERROR("render",
                     "Temporal antialiasing: camera '{}' needs a history of {}x{} and the renderer cannot hold it (the "
                     "histories take at most {} MB, or the GPU refused the images). The game renders without it and "
                     "without the camera jitter. Hint: lower the render scale or turn temporalAAEnabled off.",
                     job, w, h, budget >> 20);
        }
        return nullptr;
    }
    slot->w = w;
    slot->h = h;
    slot->format = format;
    slots_[camKey] = slot;
    return slot;
}

void TaaFx::sweep(std::uint64_t serial) {
    for (auto it = slots_.begin(); it != slots_.end();) {
        // A camera that did not resolve on the frame before has no history that could be used again: freed now, made again when it asks.
        if (it->second->planned + 1 < serial) {
            destroy(*it->second);
            it = slots_.erase(it);
        } else {
            ++it;
        }
    }
}

void TaaFx::reset(std::uint64_t camKey) {
    for (auto& e : slots_)
        if (camKey == 0 || e.first == camKey) e.second->wrote = false;
}

int TaaFx::history_image_count() const {
    int n = 0;
    if (!device_) return 0;
    for (const auto& e : slots_)
        for (const Target& t : e.second->img)
            if (t.valid(*device_)) ++n;
    return n;
}

bool TaaFx::last_used_history(std::uint64_t camKey) const {
    const auto it = slots_.find(camKey);
    return it != slots_.end() && it->second->usedHistory;
}

void TaaFx::forget_targets(bool keepUpscale) {
    for (auto it = slots_.begin(); it != slots_.end();) {
        if (keepUpscale && it->first == kUpscaleCamKey) {
            ++it;
            continue;
        }
        destroy(*it->second);
        it = slots_.erase(it);
    }
    refused_ = false;
    upscaleRefused_ = false;
}

void TaaFx::release() {
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
    warnedFormat_ = false;
    device_ = nullptr;
}

namespace {

template <class T>
void apply_params(gpu::CommandList& list, const T& u) {
    list.set_uniforms(UB_taa_taa_params, gpu::Range{&u, sizeof(T)});
}

}  // namespace

bool TaaFx::resolve(gpu::CommandList& list, Gpu& gpu, const PassDesc& pd, const TaaResolveInput& in) {
    if (!pd.color.id || !in.color.id || !in.dummy.id || !ready(gpu.device())) return false;
    const gpu::Pipeline pipe = pipeline(Prog::Resolve, pd.format);  // made before the pass opens
    list.begin_pass(pd);
    list.set_pipeline(pipe);
    gpu::Bindings b;
    b.vertexBuffers[0] = gpu.fullscreen_triangle();
    b.views[VIEW_taa_tex_c] = in.color;
    b.views[VIEW_taa_tex_p] = in.depth.id ? in.depth : in.dummy;
    b.views[VIEW_taa_tex_v] = in.velocity.id ? in.velocity : in.dummy;
    b.views[VIEW_taa_tex_h] = in.history.id && in.historyValid ? in.history : in.dummy;
    b.views[VIEW_taa_tex_r] = in.reactive.id ? in.reactive : in.dummy;
    b.samplers[SMP_taa_smp_lin] = gpu.sampler(SamplerKind::LinearClamp);
    b.samplers[SMP_taa_smp_pt] = gpu.sampler(SamplerKind::Nearest);
    list.set_bindings(b);
    const float flip[4] = {gpu.is_gl() ? 1.0f : 0.0f, 0.0f, 0.0f, 0.0f};
    list.set_uniforms(UB_taa_taa_vs_params, gpu::Range{flip, sizeof(flip)});
    taa_taa_params_t u{};
    u.a[0] = flip[0];
    u.a[1] = float(in.inW);
    u.a[2] = float(in.inH);
    u.hs[0] = float(in.outW);
    u.hs[1] = float(in.outH);
    u.hs[2] = in.historyValid && in.history.id ? 1.0f : 0.0f;
    for (int i = 0; i < 4; ++i) u.rc[i] = in.rect[i];
    u.j[0] = in.jitterPx.x;
    u.j[1] = in.jitterPx.y;
    u.g[0] = in.gamma;
    u.g[1] = in.feedback;
    u.g[3] = in.reactiveScale;
    u.f[0] = in.depth.id ? 1.0f : 0.0f;
    u.f[1] = in.velocity.id ? 1.0f : 0.0f;
    u.f[2] = in.reactive.id ? 1.0f : 0.0f;
    u.f[3] = in.historyHasDepth ? 1.0f : 0.0f;
    for (int i = 0; i < 4; ++i) u.pa[i] = in.proj[i];
    for (int i = 0; i < 4; ++i) u.pb[i] = in.proj[4 + i];
    for (int i = 0; i < 16; ++i) u.m[i] = in.prevFromView.m[i];
    apply_params(list, u);
    list.draw(0, 3, 1);
    list.end_pass();
    return true;
}

bool TaaFx::output(gpu::CommandList& list, Gpu& gpu, const PassDesc& pd, gpu::View history, int w, int h, float sharpen,
                   const int* part) {
    if (!pd.color.id || !history.id || !ready(gpu.device())) return false;
    const gpu::Pipeline pipe = pipeline(Prog::Out, pd.format);  // made before the pass opens
    list.begin_pass(pd);
    if (part) {
        list.set_viewport(part[0], part[1], part[2], part[3], true);
        list.set_scissor(part[0], part[1], part[2], part[3], true);
    }
    list.set_pipeline(pipe);
    gpu::Bindings b;
    b.vertexBuffers[0] = gpu.fullscreen_triangle();
    b.views[VIEW_taa_tex_o] = history;
    b.samplers[SMP_taa_smp_o] = gpu.sampler(SamplerKind::LinearClamp);
    list.set_bindings(b);
    const float flip[4] = {gpu.is_gl() ? 1.0f : 0.0f, 0.0f, 0.0f, 0.0f};
    list.set_uniforms(UB_taa_taa_vs_params, gpu::Range{flip, sizeof(flip)});
    taa_taa_params_t u{};
    u.a[0] = flip[0];
    u.hs[0] = float(w);
    u.hs[1] = float(h);
    u.g[2] = sharpen;
    apply_params(list, u);
    list.draw(0, 3, 1);
    list.end_pass();
    return true;
}

bool TaaFx::reserve_upscale(gpu::Device& device, int outW, int outH, std::uint64_t serial) {
    if (outW < 1 || outH < 1 || !ready(device) || upscaleRefused_) return false;
    const std::shared_ptr<Slot> slot = slot_for(kUpscaleCamKey, outW, outH, pick_format(), "upscale");
    if (!slot) return false;
    // A history made now counts as planned in the frame that is about to be drawn: a sweep between this call and the resolve (the frame's end
    // when no job resolved) must not free what was just reserved. `serial` is the postSerial of the frame before; the resolve sets its own.
    slot->planned = std::max(slot->planned, serial);
    return true;
}

bool TaaFx::upscale(gpu::CommandList& list, Gpu& gpu, const TaaPlan& plan, TaaResolveInput in, std::uint64_t configKey,
                    Target& out) {
    if (!plan.on || !in.color.id || !in.dummy.id || !ready(gpu.device()) || !out.valid(gpu.device()) || upscaleRefused_)
        return false;
    in.outW = out.w;
    in.outH = out.h;
    const gpu::PixelFormat hf = pick_format();
    const std::shared_ptr<Slot> slot = slot_for(plan.camKey, in.outW, in.outH, hf, "upscale");
    if (!slot) return false;
    // The history holds the frame before when the upscaler resolved it, nothing that changes what the images mean happened since (a cut, a
    // scene, a floating-origin shift, another render size or quality) and the images are the ones just made or kept.
    const bool histValid = slot->wrote && (slot->last == 0 || slot->last == 1) && slot->serial + 1 == plan.serial &&
                           slot->sceneKey == plan.sceneKey && slot->originShifts == plan.originShifts &&
                           slot->configKey == configKey && plan.prevValid;
    if (!histValid) ++resets_;
    slot->planned = plan.serial;
    const int readIdx = histValid ? slot->last : -1;
    const int writeIdx = slot->last == 0 ? 1 : 0;
    in.jitterPx = plan.jitterPx;
    in.gamma = plan.gamma;
    in.feedback = plan.feedback;
    in.reactiveScale = plan.reactiveScale;
    in.prevFromView = plan.prevFromView;
    for (int i = 0; i < 8; ++i) in.proj[i] = plan.proj[i];
    in.historyHasDepth = hf == gpu::PixelFormat::Rgba16F;
    in.historyValid = readIdx >= 0;
    in.history = readIdx >= 0 ? slot->img[readIdx].texView : gpu::View{};
    PassDesc pd = pass_into(slot->img[writeIdx], "upscale-resolve");
    pd.colorLoad = gpu::LoadAction::DontCare;
    if (!resolve(list, gpu, pd, in)) return false;
    slot->last = writeIdx;
    slot->wrote = true;
    slot->serial = plan.serial;
    slot->sceneKey = plan.sceneKey;
    slot->originShifts = plan.originShifts;
    slot->configKey = configKey;
    slot->usedHistory = histValid;
    // The sharpened history into the output image. The pipeline leaves the alpha alone, so the image is cleared to opaque first.
    PassDesc od = pass_into(out, "upscale-output");
    od.colorLoad = gpu::LoadAction::Clear;
    od.clearColor = gpu::Color{0.0f, 0.0f, 0.0f, 1.0f};
    od.colorStore = gpu::StoreAction::Store;
    return output(list, gpu, od, slot->img[writeIdx].texView, in.outW, in.outH, plan.sharpen, nullptr);
}

int TaaFx::add_passes(FrameGraph& graph, Gpu& gpu, const TaaPlan& plan, const PostRect& rectIn, int picW, int picH,
                      ResourceId game, gpu::View srcTex, const BloomTarget& dst, const PrepassRef& prepass,
                      const VelocityRef& velocity, const PrepassRef& reactive, gpu::View dummy, int* drawCalls,
                      const std::string& job) {
    if (!plan.on || !srcTex.id || !dummy.id) return 0;
    const Rect rect = rect_of(rectIn, picW, picH);
    if (rect.w < 1 || rect.h < 1) return 0;
    if (!ready(gpu.device()) || refused_) return 0;
    const gpu::PixelFormat hf = pick_format();
    const std::shared_ptr<Slot> slot = slot_for(plan.camKey, rect.w, rect.h, hf, job);
    if (!slot) return 0;

    // The history holds the frame before when this camera resolved it, nothing that changes what the images mean happened since (a cut, a
    // scene, a floating-origin shift: the matrices do not cover them) and the images are the ones just made or kept.
    const bool histValid = slot->wrote && (slot->last == 0 || slot->last == 1) && slot->serial + 1 == plan.serial &&
                           slot->sceneKey == plan.sceneKey && slot->originShifts == plan.originShifts && plan.prevValid;
    if (!histValid) ++resets_;
    slot->planned = plan.serial;
    const int readIdx = histValid ? slot->last : -1;
    const int writeIdx = slot->last == 0 ? 1 : 0;

    TransientDesc td;
    td.width = rect.w;
    td.height = rect.h;
    td.format = TargetFormat{hf, gpu::PixelFormat::None, 1};
    td.label = job + "/taa-history-out";
    const ResourceId outRes = graph.import_target(td.label, slot->img[writeIdx].color.id, td);
    ResourceId inRes;
    if (readIdx >= 0) {
        td.label = job + "/taa-history-in";
        inRes = graph.import_target(td.label, slot->img[readIdx].color.id, td);
    }

    int declared = 0;
    auto add = [&](const char* name, std::vector<ResourceId> reads, std::vector<ResourceId> writes, auto&& fn) {
        GraphPass gp;
        gp.name = job + "/" + name;
        gp.reads = std::move(reads);
        gp.writes = std::move(writes);
        gp.execute = std::forward<decltype(fn)>(fn);
        graph.add_pass(std::move(gp));
        ++declared;
    };
    TaaFx* self = this;
    Gpu* g = &gpu;
    const PrepassRef pre = prepass;
    const VelocityRef vel = velocity;
    const PrepassRef react = reactive;
    const PostRectUv ruv = post_rect_uv(rectIn, picW, picH);
    const bool historyDepth = hf == gpu::PixelFormat::Rgba16F;
    TaaResolveInput base;
    base.color = srcTex;
    base.dummy = dummy;
    base.inW = base.outW = rect.w;
    base.inH = base.outH = rect.h;
    base.rect[0] = ruv.x;
    base.rect[1] = ruv.y;
    base.rect[2] = ruv.w;
    base.rect[3] = ruv.h;
    base.jitterPx = plan.jitterPx;
    base.historyValid = histValid;
    base.historyHasDepth = historyDepth;
    base.gamma = plan.gamma;
    base.feedback = plan.feedback;
    base.reactiveScale = plan.reactiveScale;
    base.prevFromView = plan.prevFromView;
    for (int i = 0; i < 8; ++i) base.proj[i] = plan.proj[i];
    const std::uint64_t serial = plan.serial, sceneKey = plan.sceneKey, shifts = plan.originShifts;

    std::vector<ResourceId> reads{game};
    if (pre.valid()) reads.push_back(pre.res);
    if (vel.valid()) reads.push_back(vel.res);
    if (react.valid()) reads.push_back(react.res);
    if (inRes.valid()) reads.push_back(inRes);
    add("taa-resolve", std::move(reads), {outRes}, [=](const PassContext& c) {
        TaaResolveInput in = base;
        if (const Target* t = pre.target(c)) in.depth = t->texView;
        if (const Target* t = vel.target(c)) in.velocity = t->texView;
        if (const Target* t = react.target(c)) in.reactive = t->texView;
        if (readIdx >= 0) in.history = slot->img[readIdx].texView;
        PassDesc pd = pass_into(slot->img[writeIdx], "taa-resolve");
        pd.colorLoad = gpu::LoadAction::DontCare;
        if (!self->resolve(pass_list(c, *g), *g, pd, in)) return;
        slot->last = writeIdx;
        slot->wrote = true;
        slot->serial = serial;
        slot->sceneKey = sceneKey;
        slot->originShifts = shifts;
        slot->usedHistory = in.historyValid && in.history.id;
        ++*drawCalls;
    });

    // The result into the camera's rectangle of the picture, sharpened. The picture's own alpha stays (the pipeline writes red, green and blue).
    const TargetFormat dstFormat{gpu.scene_format(), gpu::PixelFormat::None, dst.samples};
    const float sharpen = plan.sharpen;
    add("taa-output", {outRes, game}, {game}, [=](const PassContext& c) {
        if (!slot->wrote || slot->serial != serial || slot->last != writeIdx) return;  // the resolve did not run
        PassDesc pd;
        pd.label = "taa-output";
        pd.color = dst.att;
        pd.resolve = dst.resolve;  // id 0 when the pass does not resolve
        pd.format = dstFormat;
        pd.colorLoad = gpu::LoadAction::Load;
        pd.colorStore = gpu::StoreAction::Store;
        const int part[4] = {rect.x, rect.y, rect.w, rect.h};
        if (self->output(pass_list(c, *g), *g, pd, slot->img[writeIdx].texView, rect.w, rect.h, sharpen,
                         rect.whole ? nullptr : part))
            ++*drawCalls;
    });
    return declared;
}

}  // namespace fa::render
