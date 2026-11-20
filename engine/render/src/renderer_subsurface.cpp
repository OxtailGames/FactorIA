#include "renderer_subsurface.h"

#include <algorithm>
#include <cstring>

#include "fa/core/log.h"

#include "postprocess.h"
#include "shader_cache.h"
#include "shaders/subsurface.glsl.h"

namespace fa::render {

namespace {

constexpr std::size_t kMaxFailed = 16;

// The pass callbacks capture uniform blocks by value, which are alignas(16): MSVC warns (C4324, an error under /WX) that each closure is
// padded, which is what alignas asks for.
#if defined(_MSC_VER)
#pragma warning(push)
#pragma warning(disable : 4324)
#endif

static_assert(UB_subsurface_sss_vs_params == 0, "the subsurface vertex shader uses uniform slot 0");
static_assert(UB_subsurface_sss_params == 1, "the blur's parameters are uniform slot 1");
static_assert(UB_subsurface_sss_add_params == 1, "the add's parameters are uniform slot 1");
static_assert(VIEW_subsurface_tex_a == 0 && VIEW_subsurface_tex_aa == 0, "the blurs read the light at view 0");
static_assert(VIEW_subsurface_tex_b == 1 && VIEW_subsurface_tex_ab == 1, "the blurs read the radius at view 1");
static_assert(VIEW_subsurface_tex_ah == 2, "the vertical blur reads the horizontal one at view 2");
static_assert(VIEW_subsurface_tex_dv == 0, "the add reads the change at view 0");

subsurface_sss_params_t blur_params(const SssPlan& plan) {
    subsurface_sss_params_t u{};
    u.a[0] = plan.focalPx;
    u.a[1] = plan.ortho ? 1.0f : 0.0f;
    u.a[2] = float(plan.rectW);
    u.a[3] = float(plan.rectH);
    u.b[0] = kSssMaxRadiusPx;
    for (int i = 0; i < kSssGaussians; ++i) {
        u.g[i][0] = kSssGauss[i].weight;
        u.g[i][1] = kSssGauss[i].sigma;
    }
    for (int k = 0; k <= kSssTaps; ++k) u.cell[k >> 2][k & 3] = kSssCell[k];
    return u;
}

}  // namespace

bool SssFx::gpu_supported() {
    const sg_pixelformat_info f = sg_query_pixelformat(SG_PIXELFORMAT_RGBA16F);
    return f.render && f.sample && f.blend;
}

TransientDesc SssFx::light_desc(const SssPlan& plan, const std::string& job) {
    TransientDesc d;
    d.width = plan.rectW;
    d.height = plan.rectH;
    d.format = TargetFormat{SG_PIXELFORMAT_RGBA16F, SG_PIXELFORMAT_DEPTH, 1};
    d.label = job + "/sss-light";
    return d;
}

TransientDesc SssFx::params_desc(const SssPlan& plan, const std::string& job) {
    TransientDesc d;
    d.width = plan.rectW;
    d.height = plan.rectH;
    d.format = TargetFormat{SG_PIXELFORMAT_RGBA16F, SG_PIXELFORMAT_NONE, 1};
    d.label = job + "/sss-image";
    return d;
}

bool SssFx::ready(Prog prog) {
    int& st = state_[int(prog)];
    if (st != 0) return st > 0;
    const sg_backend backend = sg_query_backend();
    sg_shader s{};
    switch (prog) {
        case Prog::BlurH: s = make_shader(subsurface_blur_h_shader_desc(backend), "subsurface_blur_h"); break;
        case Prog::BlurV: s = make_shader(subsurface_blur_v_shader_desc(backend), "subsurface_blur_v"); break;
        default: s = make_shader(subsurface_add_shader_desc(backend), "subsurface_add"); break;
    }
    if (sg_query_shader_state(s) != SG_RESOURCESTATE_VALID) {
        if (s.id) sg_destroy_shader(s);
        st = -1;
        FA_ERROR("render",
                 "Subsurface scattering is unavailable: the shader of its blur failed to compile for this graphics "
                 "backend (see the sokol log lines above). The meshes draw without it. Hint: update the graphics "
                 "driver (Mesa: try LIBGL_ALWAYS_SOFTWARE=1) or set MeshRenderer.subsurface to 0.");
        return false;
    }
    shaders_[int(prog)] = s;
    st = 1;
    return true;
}

sg_pipeline SssFx::pipeline(Prog prog, const TargetFormat& format, bool subtract) {
    for (const PipelineEntry& e : pipelines_)
        if (e.prog == prog && e.subtract == subtract && e.format == format) return e.pipeline;
    if (state_[int(prog)] <= 0) return {};
    sg_pipeline_desc d{};
    d.shader = shaders_[int(prog)];
    d.layout.attrs[0].format = SG_VERTEXFORMAT_FLOAT2;  // `pos`, location 0 in every program
    d.depth.compare = SG_COMPAREFUNC_ALWAYS;
    d.depth.write_enabled = false;
    d.depth.pixel_format = format.depth;
    d.colors[0].pixel_format = format.color;
    d.sample_count = format.samples;
    d.face_winding = SG_FACEWINDING_CCW;
    if (prog == Prog::Add) {
        // picture + light (or picture - light): the fragment's rgb is the magnitude of the change; the alpha of the picture is kept.
        d.colors[0].blend.enabled = true;
        d.colors[0].blend.op_rgb = subtract ? SG_BLENDOP_REVERSE_SUBTRACT : SG_BLENDOP_ADD;
        d.colors[0].blend.src_factor_rgb = SG_BLENDFACTOR_ONE;
        d.colors[0].blend.dst_factor_rgb = SG_BLENDFACTOR_ONE;
        d.colors[0].blend.src_factor_alpha = SG_BLENDFACTOR_ZERO;
        d.colors[0].blend.dst_factor_alpha = SG_BLENDFACTOR_ONE;
    }
    d.label = prog == Prog::BlurH ? "sss-blur-h" : prog == Prog::BlurV ? "sss-blur-v" : "sss-add";
    const sg_pipeline p = sg_make_pipeline(&d);
    if (sg_query_pipeline_state(p) != SG_RESOURCESTATE_VALID)
        FA_ERROR("render", "failed to create pipeline '{}'", d.label);
    pipelines_.push_back({prog, subtract, format, p});
    return p;
}

void SssFx::forget_targets() {
    failed_.clear();
    probed_.clear();
    warnedTargets_ = false;
}

void SssFx::release() {
    for (PipelineEntry& e : pipelines_)
        if (e.pipeline.id) sg_destroy_pipeline(e.pipeline);
    pipelines_.clear();
    for (sg_shader& s : shaders_) {
        if (s.id) sg_destroy_shader(s);
        s = {};
    }
    for (int& s : state_) s = 0;
    failed_.clear();
    probed_.clear();
    warnedTargets_ = false;
    warnedGpu_ = false;
}

bool SssFx::can_draw(TransientTargets& targets, Gpu& gpu, const SssPlan& plan) {
    if (!plan.on) return false;
    if (!gpu_supported()) {
        if (!warnedGpu_) {
            warnedGpu_ = true;
            FA_WARN("render",
                    "Subsurface scattering needs RGBA16F render targets and this GPU has none: the meshes draw "
                    "without it. Hint: render.supports {{\"feature\": \"subsurface\"}} tells which GPUs draw it.");
        }
        return false;
    }
    if (!gpu.sss_ready() || !ready(Prog::BlurH) || !ready(Prog::BlurV) || !ready(Prog::Add)) return false;
    const std::uint64_t key = (std::uint64_t(std::uint32_t(plan.rectW)) << 32) | std::uint32_t(plan.rectH);
    if (std::find(failed_.begin(), failed_.end(), key) != failed_.end()) return false;
    if (std::find(probed_.begin(), probed_.end(), key) != probed_.end()) return true;
    // Made now (and given back to the pool) so that a GPU that refuses an image is one warning here, not a pass that cannot run.
    const std::uint64_t ha = targets.pool.acquire(light_desc(plan, "sss"));
    const std::uint64_t hb = ha ? targets.pool.acquire(params_desc(plan, "sss")) : 0;
    const bool ok = ha != 0 && hb != 0;
    if (hb) targets.pool.release(hb);
    if (ha) targets.pool.release(ha);
    if (!ok) {
        if (failed_.size() >= kMaxFailed) failed_.erase(failed_.begin());
        failed_.push_back(key);
        if (!warnedTargets_) {
            warnedTargets_ = true;
            FA_ERROR("render",
                     "Subsurface scattering: cannot create the {}x{} images it draws into; the meshes draw without it. "
                     "Hint: lower the render scale.",
                     plan.rectW, plan.rectH);
        }
        return false;
    }
    if (probed_.size() >= kMaxFailed) probed_.erase(probed_.begin());
    probed_.push_back(key);
    return true;
}

int SssFx::add_passes(FrameGraph& graph, TransientTargets& targets, Gpu& gpu, const SssPlan& plan, ResourceId a,
                      ResourceId b, const PostRect& rect, int picW, int picH, ResourceId game, const BloomTarget& dst,
                      int* drawCalls, const std::string& job) {
    if (!plan.on || !a.valid() || !b.valid() || !ready(Prog::BlurH) || !ready(Prog::BlurV) || !ready(Prog::Add))
        return 0;
    const bool whole = rect.whole(picW, picH);
    const int rx = whole ? 0 : rect.x, ry = whole ? 0 : rect.y;
    const int rw = whole ? picW : rect.w, rh = whole ? picH : rect.h;
    if (rw < 1 || rh < 1 || rw != plan.rectW || rh != plan.rectH) return 0;
    const ResourceId h = graph.create_transient(params_desc(plan, job + "/h"));
    const ResourceId v = graph.create_transient(params_desc(plan, job + "/v"));
    TransientTargets* tt = &targets;
    Gpu* g = &gpu;
    SssFx* self = this;
    const subsurface_sss_params_t params = blur_params(plan);
    const float gl = gpu.is_gl() ? 1.0f : 0.0f;

    // The blur along x.
    {
        GraphPass gp;
        gp.name = job + "/sss-blur-h";
        gp.reads = {a, b};
        gp.writes = {h};
        gp.execute = [=](const PassContext& c) {
            const Target* at = tt->get(c.handle(a));
            const Target* bt = tt->get(c.handle(b));
            const Target* ht = tt->get(c.handle(h));
            if (!at || !bt || !ht || !at->texView.id || !bt->texView.id) return;
            PassDesc pd = pass_into(*ht, "sss-blur-h");
            pd.colorLoad = SG_LOADACTION_DONTCARE;
            Gpu::begin_pass(pd);
            sg_apply_pipeline(self->pipeline(Prog::BlurH, pd.format));
            sg_bindings bind{};
            bind.vertex_buffers[0] = g->fullscreen_triangle();
            bind.views[VIEW_subsurface_tex_a] = at->texView;
            bind.views[VIEW_subsurface_tex_b] = bt->texView;
            bind.samplers[SMP_subsurface_smp_pt] = g->sampler(SamplerKind::Nearest);
            sg_apply_bindings(&bind);
            float flip[4] = {gl, 0.0f, 0.0f, 0.0f};
            sg_range vr{flip, sizeof(flip)};
            sg_apply_uniforms(UB_subsurface_sss_vs_params, &vr);
            sg_range pr{&params, sizeof(params)};
            sg_apply_uniforms(UB_subsurface_sss_params, &pr);
            sg_draw(0, 3, 1);
            Gpu::end_pass();
            if (drawCalls) ++*drawCalls;
        };
        graph.add_pass(std::move(gp));
    }
    // The blur along y, and the change it makes.
    {
        GraphPass gp;
        gp.name = job + "/sss-blur-v";
        gp.reads = {h, a, b};
        gp.writes = {v};
        gp.execute = [=](const PassContext& c) {
            const Target* at = tt->get(c.handle(a));
            const Target* bt = tt->get(c.handle(b));
            const Target* ht = tt->get(c.handle(h));
            const Target* vt = tt->get(c.handle(v));
            if (!at || !bt || !ht || !vt || !at->texView.id || !bt->texView.id || !ht->texView.id) return;
            PassDesc pd = pass_into(*vt, "sss-blur-v");
            pd.colorLoad = SG_LOADACTION_DONTCARE;
            Gpu::begin_pass(pd);
            sg_apply_pipeline(self->pipeline(Prog::BlurV, pd.format));
            sg_bindings bind{};
            bind.vertex_buffers[0] = g->fullscreen_triangle();
            bind.views[VIEW_subsurface_tex_aa] = at->texView;
            bind.views[VIEW_subsurface_tex_ab] = bt->texView;
            bind.views[VIEW_subsurface_tex_ah] = ht->texView;
            bind.samplers[SMP_subsurface_smp_ap] = g->sampler(SamplerKind::Nearest);
            sg_apply_bindings(&bind);
            float flip[4] = {gl, 0.0f, 0.0f, 0.0f};
            sg_range vr{flip, sizeof(flip)};
            sg_apply_uniforms(UB_subsurface_sss_vs_params, &vr);
            sg_range pr{&params, sizeof(params)};
            sg_apply_uniforms(UB_subsurface_sss_params, &pr);
            sg_draw(0, 3, 1);
            Gpu::end_pass();
            if (drawCalls) ++*drawCalls;
        };
        graph.add_pass(std::move(gp));
    }
    // The change over the picture: two draws of one pass, the light to add and then the light to take away.
    {
        GraphPass gp;
        gp.name = job + "/sss-add";
        gp.reads = {v, game};
        gp.writes = {game};
        const TargetFormat dstFormat{gpu.scene_format(), SG_PIXELFORMAT_NONE, dst.samples};
        gp.execute = [=](const PassContext& c) {
            const Target* vt = tt->get(c.handle(v));
            if (!vt || !vt->texView.id || !dst.att.id) return;
            PassDesc pd;
            pd.label = "sss-add";
            pd.color = dst.att;
            pd.resolve = dst.resolve;  // id 0 when the pass does not resolve
            pd.format = dstFormat;
            pd.colorLoad = SG_LOADACTION_LOAD;
            pd.colorStore = SG_STOREACTION_STORE;
            Gpu::begin_pass(pd);
            if (!whole) {
                sg_apply_viewport(rx, ry, rw, rh, true);
                sg_apply_scissor_rect(rx, ry, rw, rh, true);
            }
            for (int part = 0; part < 2; ++part) {
                sg_apply_pipeline(self->pipeline(Prog::Add, pd.format, part == 1));
                sg_bindings bind{};
                bind.vertex_buffers[0] = g->fullscreen_triangle();
                bind.views[VIEW_subsurface_tex_dv] = vt->texView;
                bind.samplers[SMP_subsurface_smp_dv] = g->sampler(SamplerKind::Nearest);
                sg_apply_bindings(&bind);
                float flip[4] = {gl, 0.0f, 0.0f, 0.0f};
                sg_range vr{flip, sizeof(flip)};
                sg_apply_uniforms(UB_subsurface_sss_vs_params, &vr);
                subsurface_sss_add_params_t au{};
                au.m[0] = float(part);
                au.m[2] = float(rw);
                au.m[3] = float(rh);
                sg_range ar{&au, sizeof(au)};
                sg_apply_uniforms(UB_subsurface_sss_add_params, &ar);
                sg_draw(0, 3, 1);
                if (drawCalls) ++*drawCalls;
            }
            Gpu::end_pass();
        };
        graph.add_pass(std::move(gp));
    }
    return 3;
}

#if defined(_MSC_VER)
#pragma warning(pop)
#endif

}  // namespace fa::render
