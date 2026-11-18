#include "renderer_ssao.h"

#include <algorithm>
#include <cmath>

#include "fa/core/log.h"

#include "postprocess_resolve.h"
#include "shaders/ssao.glsl.h"

namespace fa::render {

namespace {

float finite_or(float v, float fallback) { return std::isfinite(v) ? v : fallback; }

template <class T>
void apply_uniforms(int slot, const T& u) {
    sg_range r{&u, sizeof(T)};
    sg_apply_uniforms(slot, &r);
}

constexpr float kMaxIntensity = 4.0f;
constexpr float kMinRadius = 0.001f, kMaxRadius = 1000.0f;
// The visibility is raised to intensity * kPower: intensity 1 is a soft but clear contact shadow in a crease.
constexpr float kPower = 1.5f;
// A neighbour is on the same surface for the blur when it is within this fraction of the depth of the centre's plane.
constexpr float kPlaneTolerance = 0.01f;
// A gamma scene holds sRGB-encoded values (about a 2.2 power): the colour is multiplied by visibility^(1 / 2.2) so that the linear result
// is the one of a linear scene.
constexpr float kGamma = 2.2f;

// One full-screen-triangle pass of the occlusion (the search and the blur) into a transient the pass draws every texel of.
template <class U>
void run_pass(Gpu& gpu, const Target& dst, SsaoStage stage, sg_view pre, sg_view ao, const U& fs, int fsSlot,
              const char* label) {
    PassDesc p = pass_into(dst, label);
    p.colorLoad = SG_LOADACTION_DONTCARE;
    p.colorStore = SG_STOREACTION_STORE;
    gpu.begin_pass(p);
    sg_apply_pipeline(gpu.ssao_pipeline(stage, p.format));
    sg_bindings b{};
    b.vertex_buffers[0] = gpu.fullscreen_triangle();
    b.views[VIEW_ssao_pre_tex] = pre;
    b.views[VIEW_ssao_ao_tex] = ao.id ? ao : pre;  // the search has no occlusion image yet (its program ignores the slot)
    b.samplers[SMP_ssao_smp] = gpu.sampler(SamplerKind::Nearest);
    sg_apply_bindings(&b);
    ssao_ssao_vs_params_t vu{};
    vu.flip[0] = gpu.is_gl() ? 1.0f : 0.0f;
    apply_uniforms(UB_ssao_ssao_vs_params, vu);
    apply_uniforms(fsSlot, fs);
    sg_draw(0, 3, 1);
    gpu.end_pass();
}

}  // namespace

SsaoQualityInfo ssao_quality_info(int quality) {
    switch (std::clamp(quality, 0, 3)) {
        case 0: return {true, 2, 3};
        case 1: return {true, 3, 5};
        case 2: return {false, 3, 6};
        default: return {false, 5, 8};
    }
}

SsaoSettings ssao_from_stack(const PostStack& stack) {
    SsaoSettings s;
    if (!stack.has(PostEffect::Ssao)) return s;
    const PostProcess& f = stack.fx;
    s.quality = std::clamp(int(f.ssaoQuality), 0, 3);
    s.intensity = std::clamp(finite_or(f.ssaoIntensity, 1.0f), 0.0f, kMaxIntensity);
    s.radius = std::clamp(finite_or(f.ssaoRadius, 0.5f), 0.0f, kMaxRadius);
    s.enabled = s.intensity > 0.0f && s.radius >= kMinRadius;
    return s;
}

SsaoSettings ssao_debug_settings(const SsaoSettings& own) {
    SsaoSettings s = own;
    if (!own.enabled) {
        const PostProcess defaults;
        s.quality = int(defaults.ssaoQuality);
        s.intensity = defaults.ssaoIntensity;
        s.radius = defaults.ssaoRadius;
    }
    s.enabled = true;
    s.view = true;
    return s;
}

SsaoCamera ssao_camera(const CameraGeometry& cam) {
    SsaoCamera c;
    const float p00 = std::fabs(cam.proj.at(0, 0)), p11 = std::fabs(cam.proj.at(1, 1));
    c.halfX = p00 > 1e-9f ? 1.0f / p00 : 1.0f;
    c.halfY = p11 > 1e-9f ? 1.0f / p11 : 1.0f;
    c.ortho = !cam.perspective;
    return c;
}

// The pass callbacks capture the shader's uniform blocks by value, which are alignas(16): MSVC warns (C4324, an error under /WX) that
// each closure is padded, which is what alignas asks for.
#if defined(_MSC_VER)
#pragma warning(push)
#pragma warning(disable : 4324)
#endif
int Ssao::add_passes(FrameGraph& graph, TransientTargets& targets, Gpu& gpu, const SsaoSettings& s,
                     const SsaoCamera& cam, const PrepassRef& prepass, const PostRect& rect, int picW, int picH,
                     ResourceId game, const SsaoTarget& dst, bool linear, int* drawCalls, const std::string& job) {
    if (!s.enabled || !prepass.valid() || picW < 1 || picH < 1) return 0;
    const bool partial = !rect.whole(picW, picH);
    const int w = partial ? rect.w : picW, h = partial ? rect.h : picH;  // the prepass has the size of the camera's rectangle
    if (w < 1 || h < 1) return 0;
    // RGBA16F targets that blend and filter (what `render.supports` asks for): without them the effect is not drawn.
    const sg_pixelformat_info fmtInfo = sg_query_pixelformat(SG_PIXELFORMAT_RGBA16F);
    if (!(fmtInfo.render && fmtInfo.blend && fmtInfo.filter)) {
        if (!warned_) {
            warned_ = true;
            FA_WARN("render",
                    "PostProcess.ssaoEnabled needs RGBA16F render targets and this GPU has none that blend: the ambient "
                    "occlusion is not drawn. Hint: set ssaoEnabled to false.");
        }
        return 0;
    }
    if (std::find(failed_.begin(), failed_.end(), Shape{w, h}) != failed_.end()) return 0;  // not tried again every frame
    if (!gpu.ssao_ready()) return 0;

    const SsaoQualityInfo q = ssao_quality_info(s.quality);
    const int scale = q.half ? 2 : 1;
    const int aw = (w + scale - 1) / scale, ah = (h + scale - 1) / scale;
    TransientDesc d;
    d.width = aw;
    d.height = ah;
    d.format = TargetFormat{SG_PIXELFORMAT_RGBA16F, SG_PIXELFORMAT_NONE, 1};
    d.label = "ssao-a";
    TransientDesc d2 = d;
    d2.label = "ssao-b";
    // Make sure the GPU can have both at once (the worst case), so that a failure is one warning here and not a pass that cannot
    // run halfway through the frame. The pool keeps what it made.
    {
        const std::uint64_t ha = targets.pool.acquire(d);
        const std::uint64_t hb = ha ? targets.pool.acquire(d2) : 0;
        if (ha) targets.pool.release(ha);
        if (hb) targets.pool.release(hb);
        if (!ha || !hb) {
            if (failed_.size() >= kMaxFailed) failed_.erase(failed_.begin());
            failed_.push_back(Shape{w, h});
            if (!warned_) {
                warned_ = true;
                FA_ERROR("render",
                         "PostProcess.ssaoEnabled: cannot create the {}x{} occlusion targets, so the ambient occlusion is "
                         "not drawn. Hint: lower the window size or the render scale, or ssaoQuality.",
                         aw, ah);
            }
            return 0;
        }
    }
    d.label = job + "/ssao-a";
    d2.label = job + "/ssao-b";
    const ResourceId a = graph.create_transient(d), b = graph.create_transient(d2);
    const ResourceId pre = prepass.res;
    TransientTargets* tt = &targets;
    Gpu* g = &gpu;
    const PrepassRef pp = prepass;
    int declared = 0;
    auto add = [&](const std::string& name, std::vector<ResourceId> reads, std::vector<ResourceId> writes, auto&& fn) {
        GraphPass p;
        p.name = job.empty() ? name : job + "/" + name;
        p.reads = std::move(reads);
        p.writes = std::move(writes);
        p.execute = std::forward<decltype(fn)>(fn);
        graph.add_pass(std::move(p));
        ++declared;
    };

    const float sizes[4] = {float(aw), float(ah), float(w), float(h)};
    const float cam4[4] = {cam.halfX, cam.halfY, cam.ortho ? 1.0f : 0.0f, gpu.is_gl() ? 1.0f : 0.0f};
    // 1. the horizon search: prepass -> A
    {
        ssao_ssao_ao_params_t u{};
        std::copy(cam4, cam4 + 4, u.cam);
        u.p[0] = std::clamp(s.radius, kMinRadius, kMaxRadius);
        u.p[1] = float(q.slices);
        u.p[2] = float(q.steps);
        std::copy(sizes, sizes + 4, u.sz);
        u.q[0] = float(scale);
        add("ssao-ao", {pre}, {a}, [=](const PassContext& c) {
            const Target* t = tt->get(c.handle(a));
            const Target* pt = pp.target(c);
            if (!t || !pt) return;
            run_pass(*g, *t, SsaoStage::Ao, pt->texView, sg_view{}, u, UB_ssao_ssao_ao_params, "ssao-ao");
            ++*drawCalls;
        });
    }
    // 2. the bilateral blur: A -> B (horizontal), B -> A (vertical)
    for (int pass = 0; pass < 2; ++pass) {
        ssao_ssao_blur_params_t u{};
        u.dir[0] = pass == 0 ? 1.0f : 0.0f;
        u.dir[1] = pass == 0 ? 0.0f : 1.0f;
        std::copy(sizes, sizes + 4, u.sz);
        u.q[0] = float(scale);
        u.q[1] = kPlaneTolerance;
        std::copy(cam4, cam4 + 4, u.cam);
        const ResourceId from = pass == 0 ? a : b, to = pass == 0 ? b : a;
        const char* name = pass == 0 ? "ssao-blur-h" : "ssao-blur-v";
        add(name, {from, pre}, {to}, [=](const PassContext& c) {
            const Target* src = tt->get(c.handle(from));
            const Target* t = tt->get(c.handle(to));
            const Target* pt = pp.target(c);
            if (!src || !t || !pt) return;
            run_pass(*g, *t, SsaoStage::Blur, pt->texView, src->texView, u, UB_ssao_ssao_blur_params, name);
            ++*drawCalls;
        });
    }
    // 3. the darkening of the game image (or, for the debug view, the occlusion as a grey) over the camera's rectangle
    {
        ssao_ssao_apply_params_t u{};
        // intensity * kPower; a gamma scene holds encoded values, so its colour gets the 2.2th root of that (not the debug view, which
        // shows the occlusion itself)
        u.a[0] = s.intensity * kPower * (linear || s.view ? 1.0f : 1.0f / kGamma);
        u.a[1] = float(scale);
        u.a[2] = kPlaneTolerance;
        std::copy(sizes, sizes + 4, u.sz);
        std::copy(cam4, cam4 + 4, u.cam);
        const bool view = s.view;
        const char* name = view ? "ssao-view" : "ssao-apply";
        const SsaoTarget out = dst;
        const PostRect r = rect;
        add(name, {a, pre, game}, {game}, [=](const PassContext& c) {
            const Target* src = tt->get(c.handle(a));
            const Target* pt = pp.target(c);
            if (!src || !pt) return;
            PassDesc p;
            p.label = name;
            p.color = out.att;
            p.resolve = out.resolve;
            p.format = TargetFormat{g->scene_format(), SG_PIXELFORMAT_NONE, out.samples};
            p.colorLoad = SG_LOADACTION_LOAD;  // the picture the main passes drew
            p.colorStore = SG_STOREACTION_STORE;
            g->begin_pass(p);
            sg_apply_pipeline(g->ssao_pipeline(view ? SsaoStage::View : SsaoStage::Apply, p.format));
            if (partial) {  // the triangle covers the camera's rectangle only: uv runs 0..1 across it
                sg_apply_viewport(r.x, r.y, r.w, r.h, true);
                sg_apply_scissor_rect(r.x, r.y, r.w, r.h, true);
            }
            sg_bindings bind{};
            bind.vertex_buffers[0] = g->fullscreen_triangle();
            bind.views[VIEW_ssao_pre_tex] = pt->texView;
            bind.views[VIEW_ssao_ao_tex] = src->texView;
            bind.samplers[SMP_ssao_smp] = g->sampler(SamplerKind::Nearest);
            sg_apply_bindings(&bind);
            ssao_ssao_vs_params_t vu{};
            vu.flip[0] = g->is_gl() ? 1.0f : 0.0f;
            apply_uniforms(UB_ssao_ssao_vs_params, vu);
            apply_uniforms(UB_ssao_ssao_apply_params, u);
            sg_draw(0, 3, 1);
            g->end_pass();
            ++*drawCalls;
        });
    }
    return declared;
}
#if defined(_MSC_VER)
#pragma warning(pop)
#endif

}  // namespace fa::render
