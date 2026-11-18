#include "renderer_ssr.h"

#include <algorithm>
#include <cmath>
#include <memory>

#include "fa/core/log.h"

#include "postprocess.h"
#include "postprocess_resolve.h"
#include "shader_cache.h"
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
// `fu`: the program's uniform block (null: none). `part`: the rectangle of the destination the pass covers (null: all of it).
void draw_fullscreen(Ssr& fx, Gpu& gpu, Ssr::Prog prog, const PassDesc& pd, sg_view tc, sg_view tp, const void* fu, std::size_t fuSize,
                     const Rect* part) {
    if (!pd.color.id) return;  // the target of the pass is gone
    Gpu::begin_pass(pd);
    if (part) {
        sg_apply_viewport(part->x, part->y, part->w, part->h, true);
        sg_apply_scissor_rect(part->x, part->y, part->w, part->h, true);
    }
    sg_apply_pipeline(fx.pipeline(prog, pd.format));
    sg_bindings b{};
    b.vertex_buffers[0] = gpu.fullscreen_triangle();
    b.views[0] = tc;
    if (prog == Ssr::Prog::Trace) {
        b.views[1] = tp;
        b.samplers[1] = gpu.sampler(SamplerKind::Nearest);
    }
    b.samplers[0] = gpu.sampler(SamplerKind::LinearClamp);
    sg_apply_bindings(&b);
    float flip[4] = {gpu.is_gl() ? 1.0f : 0.0f, 0.0f, 0.0f, 0.0f};
    sg_range vr{flip, sizeof(flip)};
    sg_apply_uniforms(UB_ssr_ssr_vs_params, &vr);
    if (fu) {
        sg_range fr{fu, fuSize};
        sg_apply_uniforms(UB_ssr_ssr_params, &fr);
    }
    sg_draw(0, 3, 1);
    Gpu::end_pass();
}

}  // namespace

bool ssr_active(const PostStack& stack) {
    return stack.has(PostEffect::Ssr) && finite_or(stack.fx.ssrIntensity, 1.0f) >= 0.002f;
}

SsrPlan make_ssr_plan(const CameraInfo& cam, const PostStack& stack) {
    SsrPlan p;
    if (!ssr_active(stack)) return p;
    const PostProcess& f = stack.fx;
    p.intensity = std::clamp(finite_or(f.ssrIntensity, 1.0f), 0.0f, 1.0f);
    p.maxDistance = std::clamp(finite_or(f.ssrMaxDistance, 50.0f), 1.0f, 1000.0f);
    p.thickness = std::clamp(finite_or(f.ssrThickness, 0.3f), 0.01f, 10.0f);
    p.steps = std::clamp(int(std::clamp(finite_or(float(f.ssrSteps), 32.0f), -1000.0f, 1000.0f)), 8, 128);
    const Mat4& P = cam.proj;
    const float terms[8] = {P.at(0, 0), P.at(1, 1), P.at(2, 0), P.at(2, 1), P.at(3, 0), P.at(3, 1), P.at(2, 3), P.at(3, 3)};
    bool finite = std::fabs(terms[0]) > 1e-12f && std::fabs(terms[1]) > 1e-12f;
    for (int i = 0; i < 8; ++i) {
        finite = finite && std::isfinite(terms[i]);
        p.proj[i] = terms[i];
    }
    p.enabled = finite;
    return p;
}

bool Ssr::ready() {
    if (state_ != 0) return state_ > 0;
    const sg_backend backend = sg_query_backend();
    shaders_[int(Prog::Trace)] = make_shader(ssr_trace_shader_desc(backend), "ssr_trace");
    shaders_[int(Prog::Copy)] = make_shader(ssr_copy_shader_desc(backend), "ssr_copy");
    bool ok = true;
    for (sg_shader s : shaders_) ok = ok && sg_query_shader_state(s) == SG_RESOURCESTATE_VALID;
    if (!ok) {
        for (sg_shader& s : shaders_) {
            if (s.id) sg_destroy_shader(s);
            s = {};
        }
        state_ = -1;
        FA_ERROR("render",
                 "Screen-space reflections are unavailable: their shaders failed to compile for this graphics backend (see the sokol log "
                 "lines above). The game renders without them. Hint: update the graphics driver (Mesa: try LIBGL_ALWAYS_SOFTWARE=1) or "
                 "turn ssrEnabled off.");
        return false;
    }
    state_ = 1;
    return true;
}

sg_pipeline Ssr::pipeline(Prog prog, const TargetFormat& format) {
    for (const PipelineEntry& e : pipelines_)
        if (e.prog == prog && e.format == format) return e.pipeline;
    if (state_ <= 0) return {};
    sg_pipeline_desc d{};
    d.shader = shaders_[int(prog)];
    d.layout.attrs[0].format = SG_VERTEXFORMAT_FLOAT2;  // `pos`, location 0 in every program
    d.depth.compare = SG_COMPAREFUNC_ALWAYS;
    d.depth.write_enabled = false;
    d.depth.pixel_format = format.depth;
    d.colors[0].pixel_format = format.color;
    d.sample_count = format.samples;
    d.face_winding = SG_FACEWINDING_CCW;
    d.label = prog == Prog::Trace ? "ssr-trace" : "ssr-copy";
    const sg_pipeline p = sg_make_pipeline(&d);
    if (sg_query_pipeline_state(p) != SG_RESOURCESTATE_VALID) FA_ERROR("render", "failed to create pipeline '{}'", d.label);
    pipelines_.push_back({prog, format, p});
    return p;
}

void Ssr::forget_targets() {
    failed_.clear();
    warnedTargets_ = false;
}

void Ssr::release() {
    for (PipelineEntry& e : pipelines_)
        if (e.pipeline.id) sg_destroy_pipeline(e.pipeline);
    pipelines_.clear();
    for (sg_shader& s : shaders_) {
        if (s.id) sg_destroy_shader(s);
        s = {};
    }
    state_ = 0;
    failed_.clear();
    warnedTargets_ = false;
}

// The pass callbacks capture the uniform block by value, which is alignas(16): MSVC warns (C4324, an error under /WX) that each closure is
// padded, which is what alignas asks for.
#if defined(_MSC_VER)
#pragma warning(push)
#pragma warning(disable : 4324)
#endif
int Ssr::add_passes(FrameGraph& graph, TransientTargets& targets, Gpu& gpu, const SsrPlan& plan, const PostRect& rectIn, int picW,
                    int picH, ResourceId game, sg_view srcTex, const BloomTarget& dst, const PrepassRef& prepass, int* drawCalls,
                    const std::string& job) {
    if (!plan.any() || !prepass.valid()) return 0;
    const Rect rect = rect_of(rectIn, picW, picH);
    if (rect.w < 1 || rect.h < 1) return 0;
    if (!ready()) return 0;
    const sg_pixel_format fmt = gpu.scene_format();
    const int rw = rect.w, rh = rect.h;
    const std::uint64_t shapeKey = (std::uint64_t(rw) << 40) ^ (std::uint64_t(rh) << 16) ^ std::uint64_t(fmt);

    // The scratch image of the picture's format. Make sure the GPU can have it, so a failure is one warning here and not a pass that cannot run
    // halfway through the frame. The pool keeps what it made.
    TransientDesc sd;
    sd.width = rw;
    sd.height = rh;
    sd.format = TargetFormat{fmt, SG_PIXELFORMAT_NONE, 1};
    sd.label = job + "/ssr-scratch";
    if (std::find(failed_.begin(), failed_.end(), shapeKey) != failed_.end()) return 0;
    {
        const std::uint64_t h = targets.pool.acquire(sd);
        if (h == 0) {
            if (failed_.size() >= kMaxFailed) failed_.erase(failed_.begin());
            failed_.push_back(shapeKey);
            if (!warnedTargets_) {
                warnedTargets_ = true;
                FA_ERROR("render",
                         "Screen-space reflections: cannot create the intermediate image for a {}x{} camera; they are skipped. Hint: turn "
                         "ssrEnabled off, or lower the render scale.",
                         rw, rh);
            }
            return 0;
        }
        targets.pool.release(h);
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

    const TargetFormat dstFormat{fmt, SG_PIXELFORMAT_NONE, dst.samples};
    auto scratchReady = std::make_shared<bool>(false);  // the copy runs only after a trace that did

    add("ssr-trace", {game, pre}, {scratch}, [=](const PassContext& c) {
        const Target* pt = prepassRef.target(c);
        const Target* st = tt->get(c.handle(scratch));
        if (!pt || !st || !srcTex.id) return;
        PassDesc pd = pass_into(*st, "ssr-trace");
        pd.colorLoad = SG_LOADACTION_DONTCARE;  // every texel is drawn
        draw_fullscreen(*self, *g, Prog::Trace, pd, srcTex, pt->texView, &u, sizeof(u), nullptr);
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
        pd.colorLoad = rect.whole && dst.samples <= 1 ? SG_LOADACTION_DONTCARE : SG_LOADACTION_LOAD;
        pd.colorStore = SG_STOREACTION_STORE;
        draw_fullscreen(*self, *g, Prog::Copy, pd, st->texView, sg_view{}, nullptr, 0, rect.whole ? nullptr : &rect);
        ++*drawCalls;
    });
    return declared;
}
#if defined(_MSC_VER)
#pragma warning(pop)
#endif

}  // namespace fa::render
