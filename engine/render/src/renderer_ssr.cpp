#include "renderer_ssr.h"

#include <algorithm>
#include <cmath>
#include <memory>

#include "fa/core/log.h"

#include "postprocess.h"
#include "postprocess_resolve.h"
#include "fullscreen_gpu.h"
#include "rt_effect.h"
#include "shader_cache.h"
#include "gpu/sokol_shaders.h"
#include "shaders/ssr.glsl.h"

namespace fa::render {

namespace {

float finite_or(float v, float fallback) { return std::isfinite(v) ? v : fallback; }

constexpr std::size_t kMaxFailed = 16;

// The camera's rectangle of the picture in pixels.
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

// One full-screen triangle with `prog` into the pass `pd`. `tc`, `tp`: the colour and prepass images (the copy binds only the first).
// `tr`: the ray traced reflections' image (or any image: the shader reads it only when the uniform block says so).
// `fu`: the program's uniform block (null: none). `part`: the rectangle of the destination the pass covers (null: all of it).
// False (nothing drawn) when the target of the pass is gone.
bool draw_fullscreen(gpu::CommandList& list, Ssr& fx, Gpu& gpu, Ssr::Prog prog, const PassDesc& pd, gpu::View tc,
                     gpu::View tp, gpu::View tr, gpu::View td, gpu::View tk, gpu::View tm, const void* fu,
                     std::size_t fuSize, const Rect* part) {
    if (!pd.color.id) return false;
    const gpu::Pipeline pipe = fx.pipeline(prog, pd.format);  // made before the pass opens
    list.begin_pass(pd);
    if (part) {
        list.set_viewport(part->x, part->y, part->w, part->h, true);
        list.set_scissor(part->x, part->y, part->w, part->h, true);
    }
    list.set_pipeline(pipe);
    gpu::Bindings b;
    b.vertexBuffers[0] = gpu.fullscreen_triangle();
    b.views[0] = tc;
    if (prog == Ssr::Prog::Trace) {
        b.views[1] = tp;
        b.views[2] = tr;
        b.views[3] = td;
        b.views[4] = tk;
        b.views[5] = tm;
        b.samplers[1] = gpu.sampler(SamplerKind::Nearest);
    }
    b.samplers[0] = gpu.sampler(SamplerKind::LinearClamp);
    list.set_bindings(b);
    float flip[4] = {gpu.is_gl() ? 1.0f : 0.0f, 0.0f, 0.0f, 0.0f};
    list.set_uniforms(UB_ssr_ssr_vs_params, gpu::Range{flip, sizeof(flip)});
    if (fu) list.set_uniforms(UB_ssr_ssr_params, gpu::Range{fu, fuSize});
    list.draw(0, 3, 1);
    list.end_pass();
    return true;
}

}  // namespace

bool ssr_active(const PostStack& stack) {
    return stack.has(PostEffect::Ssr) && finite_or(stack.fx.ssrIntensity, 0.5f) >= 0.002f;
}

SsrPlan make_ssr_plan(const CameraInfo& cam, const PostStack& stack) {
    SsrPlan p;
    if (!ssr_active(stack)) return p;
    const PostProcess& f = stack.fx;
    p.intensity = std::clamp(finite_or(f.ssrIntensity, 0.5f), 0.0f, 1.0f);
    p.maxDistance = std::clamp(finite_or(f.ssrMaxDistance, 50.0f), 1.0f, 1000.0f);
    p.thickness = std::clamp(finite_or(f.ssrThickness, 0.3f), 0.01f, 10.0f);
    p.steps = std::clamp(int(std::clamp(finite_or(float(f.ssrSteps), 32.0f), -1000.0f, 1000.0f)), 8, 128);
    const Mat4& P = cam.proj;
    const float terms[8] = {P.at(0, 0), P.at(1, 1), P.at(2, 0), P.at(2, 1),
                            P.at(3, 0), P.at(3, 1), P.at(2, 3), P.at(3, 3)};
    bool finite = std::fabs(terms[0]) > 1e-12f && std::fabs(terms[1]) > 1e-12f;
    for (int i = 0; i < 8; ++i) {
        finite = finite && std::isfinite(terms[i]);
        p.proj[i] = terms[i];
    }
    p.enabled = finite;
    return p;
}

SsrPlan make_ssr_rt_plan(const CameraInfo& cam) {
    SsrPlan p;
    const Mat4& P = cam.proj;
    const float terms[8] = {P.at(0, 0), P.at(1, 1), P.at(2, 0), P.at(2, 1),
                            P.at(3, 0), P.at(3, 1), P.at(2, 3), P.at(3, 3)};
    bool finite = std::fabs(terms[0]) > 1e-12f && std::fabs(terms[1]) > 1e-12f;
    for (int i = 0; i < 8; ++i) {
        finite = finite && std::isfinite(terms[i]);
        p.proj[i] = terms[i];
    }
    p.enabled = finite;
    p.rt = true;
    return p;
}

bool Ssr::ready(Gpu& gpu) {
    if (state_ != 0) return state_ > 0;
    device_ = &gpu.device();
    gpu::Device& dev = *device_;
    shaders_[int(Prog::Trace)] = make_shader(dev, gpu::generated_shader_desc(dev, ssr_trace_shader_desc), "ssr_trace");
    shaders_[int(Prog::Copy)] = make_shader(dev, gpu::generated_shader_desc(dev, ssr_copy_shader_desc), "ssr_copy");
    bool ok = true;
    for (gpu::Shader sh : shaders_) ok = ok && dev.state(sh) == gpu::ResourceState::Valid;
    if (!ok) {
        for (gpu::Shader& sh : shaders_) {
            if (sh.id) dev.destroy_shader(sh);
            sh = {};
        }
        state_ = -1;
        FA_ERROR("render", "Screen-space reflections are unavailable: their shaders failed to compile for this "
                           "graphics backend (see the sokol log "
                           "lines above). The game renders without them. Hint: update the graphics driver (Mesa: try "
                           "LIBGL_ALWAYS_SOFTWARE=1) or "
                           "turn ssrEnabled off.");
        return false;
    }
    state_ = 1;
    return true;
}

gpu::Pipeline Ssr::pipeline(Prog prog, const TargetFormat& format) {
    for (const PipelineEntry& e : pipelines_)
        if (e.prog == prog && e.format == format) return e.pipeline;
    if (state_ <= 0 || !device_) return {};
    const char* label = prog == Prog::Trace ? "ssr-trace" : "ssr-copy";
    // `pos`, location 0 in every program.
    const gpu::Pipeline p = make_triangle_pipeline(*device_, shaders_[int(prog)], format, label);
    if (device_->state(p) != gpu::ResourceState::Valid) FA_ERROR("render", "failed to create pipeline '{}'", label);
    pipelines_.push_back({prog, format, p});
    return p;
}

void Ssr::forget_targets() {
    failed_.clear();
    probed_.clear();
    warnedTargets_ = false;
}

void Ssr::release() {
    if (device_) {
        for (PipelineEntry& e : pipelines_)
            if (e.pipeline.id) device_->destroy_pipeline(e.pipeline);
        for (gpu::Shader& sh : shaders_)
            if (sh.id) device_->destroy_shader(sh);
    }
    pipelines_.clear();
    for (gpu::Shader& sh : shaders_) sh = {};
    state_ = 0;
    failed_.clear();
    probed_.clear();
    warnedTargets_ = false;
    device_ = nullptr;
}

// The pass callbacks capture the uniform block by value, which is alignas(16): MSVC warns (C4324, an error under /WX) that each closure is
// padded, which is what alignas asks for.
#if defined(_MSC_VER)
#pragma warning(push)
#pragma warning(disable : 4324)
#endif
int Ssr::add_passes(FrameGraph& graph, TransientTargets& targets, Gpu& gpu, const SsrPlan& plan, const PostRect& rectIn,
                    int picW, int picH, ResourceId game, gpu::View srcTex, const BloomTarget& dst,
                    const PrepassRef& prepass, int* drawCalls, const std::string& job, const RtEffectImage* rtImage,
                    ResourceId rtRes, const SsrRtGlossy* glossyIn) {
    if (!plan.any() || !prepass.valid()) return 0;
    const Rect rect = rect_of(rectIn, picW, picH);
    if (rect.w < 1 || rect.h < 1) return 0;
    if (!ready(gpu)) return 0;
    const gpu::PixelFormat fmt = gpu.scene_format();
    const int rw = rect.w, rh = rect.h;
    const std::uint64_t shapeKey = (std::uint64_t(rw) << 40) ^ (std::uint64_t(rh) << 16) ^ std::uint64_t(fmt);

    // The scratch image of the picture's format. Make sure the GPU can have it, so a failure is one warning here and not a pass that cannot run
    // halfway through the frame. The pool keeps what it made.
    TransientDesc sd;
    sd.width = rw;
    sd.height = rh;
    sd.format = TargetFormat{fmt, gpu::PixelFormat::None, 1};
    sd.label = job + "/ssr-scratch";
    if (std::find(failed_.begin(), failed_.end(), shapeKey) != failed_.end()) return 0;
    if (std::find(probed_.begin(), probed_.end(), shapeKey) == probed_.end()) {  // once per shape, not every frame
        const std::uint64_t h = targets.pool.acquire(sd);
        if (h == 0) {
            if (failed_.size() >= kMaxFailed) failed_.erase(failed_.begin());
            failed_.push_back(shapeKey);
            if (!warnedTargets_) {
                warnedTargets_ = true;
                FA_ERROR("render",
                         "Screen-space reflections: cannot create the intermediate image for a {}x{} camera; they are "
                         "skipped. Hint: turn "
                         "ssrEnabled off, or lower the render scale.",
                         rw, rh);
            }
            return 0;
        }
        targets.pool.release(h);
        if (probed_.size() >= kMaxFailed) probed_.erase(probed_.begin());
        probed_.push_back(shapeKey);
    }

    const ResourceId scratch = graph.create_transient(sd);
    int declared = 0;
    TransientTargets* tt = &targets;
    auto add = [&](const char* name, std::vector<ResourceId> reads, std::vector<ResourceId> writes, auto&& fn) {
        GraphPass gp;
        gp.name = job + "/" + name;
        gp.reads = std::move(reads);
        gp.writes = std::move(writes);
        gp.execute = std::forward<decltype(fn)>(fn);
        graph.add_pass(std::move(gp));
        ++declared;
    };
    Gpu* g = &gpu;
    Ssr* self = this;
    const ResourceId pre = prepass.res;
    const PrepassRef prepassRef = prepass;
    const PostRectUv ruv = post_rect_uv(rectIn, picW, picH);

    ssr_ssr_params_t u{};
    u.a[0] = gpu.is_gl() ? 1.0f : 0.0f;
    u.a[1] = float(rw);
    u.a[2] = float(rh);
    u.a[3] = float(plan.steps);
    u.rc[0] = ruv.x;
    u.rc[1] = ruv.y;
    u.rc[2] = ruv.w;
    u.rc[3] = ruv.h;
    u.b[0] = plan.intensity;
    u.b[1] = plan.maxDistance;
    u.b[2] = plan.thickness;
    for (int i = 0; i < 4; ++i) u.pa[i] = plan.proj[i];
    for (int i = 0; i < 4; ++i) u.pb[i] = plan.proj[4 + i];
    const SsrRtGlossy glossy = glossyIn ? *glossyIn : SsrRtGlossy{};
    u.g[0] = glossy.sharp;
    u.g[1] = glossy.fadeStart;
    u.g[2] = glossy.limit;

    const TargetFormat dstFormat{fmt, gpu::PixelFormat::None, dst.samples};
    auto scratchReady = std::make_shared<bool>(false);  // the copy runs only after a trace that did

    std::vector<ResourceId> traceReads{game, pre};
    if (rtImage && rtRes.valid()) traceReads.push_back(rtRes);
    if (rtImage && rtRes.valid() && glossyIn) {  // the denoiser's results and the roughness: ordered before the trace pass
        if (glossy.color.valid() && glossy.coverage.valid()) {
            traceReads.push_back(glossy.color);
            traceReads.push_back(glossy.coverage);
        }
        if (glossy.material.valid()) traceReads.push_back(glossy.material);
    }
    add("ssr-trace", std::move(traceReads), {scratch}, [=](const PassContext& c) {
        const Target* pt = prepassRef.target(c);
        const Target* st = tt->get(c.handle(scratch));
        if (!pt || !st || !srcTex.id) return;
        PassDesc pd = pass_into(*st, "ssr-trace");
        pd.colorLoad = gpu::LoadAction::DontCare;  // every texel is drawn
        // The traced image is read only where the kernel ran this frame (the scene had a TLAS); otherwise the shader's flag is 0 and the view is a
        // placeholder (a sampler pair is always bound).
        ssr_ssr_params_t uu = u;
        const bool rtOn = rtImage && rtImage->ran && rtImage->texture.id;
        if (!rtOn && u.b[0] <= 0.0f) return;  // nothing to draw: the scratch is not made, the copy does not run
        // The denoised glossy images are used when both exist (the denoiser ran); else the raw image serves every traced pixel (mode 1).
        const Target* dt = glossy.color.valid() && glossy.targets ? glossy.targets->get(c.handle(glossy.color)) : nullptr;
        const Target* kt =
            glossy.coverage.valid() && glossy.targets ? glossy.targets->get(c.handle(glossy.coverage)) : nullptr;
        const Target* mt =
            glossy.material.valid() && glossy.targets ? glossy.targets->get(c.handle(glossy.material)) : nullptr;
        const bool denoised = rtOn && dt && kt && dt->texView.id && kt->texView.id;
        uu.b[3] = !rtOn ? 0.0f : (denoised ? 2.0f : 1.0f);
        uu.g[3] = rtOn && mt && mt->texView.id ? 1.0f : 0.0f;
        const gpu::View rawView = rtOn ? rtImage->texture : pt->texView;
        if (!draw_fullscreen(pass_list(c, *g), *self, *g, Prog::Trace, pd, srcTex, pt->texView, rawView,
                             denoised ? dt->texView : rawView, denoised ? kt->texView : rawView,
                             uu.g[3] > 0.5f ? mt->texView : rawView, &uu, sizeof(uu), nullptr))
            return;
        *scratchReady = true;
        ++*drawCalls;
    });
    add("ssr-copy", {scratch, game}, {game}, [=](const PassContext& c) {
        if (!*scratchReady) return;
        const Target* st = tt->get(c.handle(scratch));
        if (!st) return;
        PassDesc pd;
        pd.label = "ssr-copy";
        pd.color = dst.att;
        pd.resolve = dst.resolve;  // id 0 when the pass does not resolve
        pd.format = dstFormat;
        pd.colorLoad = rect.whole && dst.samples <= 1 ? gpu::LoadAction::DontCare : gpu::LoadAction::Load;
        pd.colorStore = gpu::StoreAction::Store;
        if (draw_fullscreen(pass_list(c, *g), *self, *g, Prog::Copy, pd, st->texView, gpu::View{}, gpu::View{}, gpu::View{},
                            gpu::View{}, gpu::View{}, nullptr, 0, rect.whole ? nullptr : &rect))
            ++*drawCalls;
    });
    return declared;
}
#if defined(_MSC_VER)
#pragma warning(pop)
#endif

}  // namespace fa::render
