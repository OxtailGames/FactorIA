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

bool SssFx::gpu_supported(gpu::Device& device) {
    const gpu::PixelFormatCaps f = device.pixel_format_caps(gpu::PixelFormat::Rgba16F);
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

bool SssFx::ready(Gpu& gpu, Prog prog) {
    int& st = state_[int(prog)];
    if (st != 0) return st > 0;
    gpu::Device& device = gpu.device();
    device_ = &device;
    gpu::Shader s{};
    switch (prog) {
        case Prog::BlurH:
            s = make_shader(device, gpu::generated_shader_desc(subsurface_blur_h_shader_desc), "subsurface_blur_h");
            break;
        case Prog::BlurV:
            s = make_shader(device, gpu::generated_shader_desc(subsurface_blur_v_shader_desc), "subsurface_blur_v");
            break;
        default:
            s = make_shader(device, gpu::generated_shader_desc(subsurface_add_shader_desc), "subsurface_add");
            break;
    }
    if (device.state(s) != gpu::ResourceState::Valid) {
        if (s.id) device.destroy_shader(s);
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

gpu::Pipeline SssFx::pipeline(Gpu& gpu, Prog prog, const TargetFormat& format, bool subtract) {
    for (const PipelineEntry& e : pipelines_)
        if (e.prog == prog && e.subtract == subtract && e.format == format) return e.pipeline;
    if (state_[int(prog)] <= 0) return {};
    gpu::Device& device = gpu.device();
    gpu::PipelineDesc d;
    d.shader = shaders_[int(prog)];
    d.layout.attrs[0].format = gpu::VertexFormat::Float2;  // `pos`, location 0 in every program
    d.depth.compare = gpu::CompareFunc::Always;
    d.depth.writeEnabled = false;
    d.depth.pixelFormat = gpu::from_sg(format.depth);
    d.colors[0].pixelFormat = gpu::from_sg(format.color);
    d.sampleCount = format.samples;
    d.faceWinding = gpu::FaceWinding::Ccw;
    if (prog == Prog::Add) {
        // picture + light (or picture - light): the fragment's rgb is the magnitude of the change; the alpha of the picture is kept.
        d.colors[0].blend.enabled = true;
        d.colors[0].blend.opRgb = subtract ? gpu::BlendOp::ReverseSubtract : gpu::BlendOp::Add;
        d.colors[0].blend.srcFactorRgb = gpu::BlendFactor::One;
        d.colors[0].blend.dstFactorRgb = gpu::BlendFactor::One;
        d.colors[0].blend.srcFactorAlpha = gpu::BlendFactor::Zero;
        d.colors[0].blend.dstFactorAlpha = gpu::BlendFactor::One;
    }
    d.label = prog == Prog::BlurH ? "sss-blur-h" : prog == Prog::BlurV ? "sss-blur-v" : "sss-add";
    const gpu::Pipeline p = device.make_pipeline(d);
    if (device.state(p) != gpu::ResourceState::Valid) FA_ERROR("render", "failed to create pipeline '{}'", d.label);
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
        if (e.pipeline.id && device_) device_->destroy_pipeline(e.pipeline);
    pipelines_.clear();
    for (gpu::Shader& s : shaders_) {
        if (s.id && device_) device_->destroy_shader(s);
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
    if (!gpu_supported(gpu.device())) {
        if (!warnedGpu_) {
            warnedGpu_ = true;
            FA_WARN("render",
                    "Subsurface scattering needs RGBA16F render targets and this GPU has none: the meshes draw "
                    "without it. Hint: render.supports {{\"feature\": \"subsurface\"}} tells which GPUs draw it.");
        }
        return false;
    }
    if (!gpu.sss_ready() || !ready(gpu, Prog::BlurH) || !ready(gpu, Prog::BlurV) || !ready(gpu, Prog::Add))
        return false;
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
    if (!plan.on || !a.valid() || !b.valid() || !ready(gpu, Prog::BlurH) || !ready(gpu, Prog::BlurV) ||
        !ready(gpu, Prog::Add))
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
            gpu::CommandList& list = c.commands() ? *c.commands() : g->commands();
            gpu::Swapchain swapchain;
            list.begin_pass(gpu::from_render(pd, swapchain));
            list.set_pipeline(self->pipeline(*g, Prog::BlurH, pd.format));
            gpu::Bindings bind;
            bind.vertexBuffers[0] = g->fullscreen_triangle();
            bind.views[VIEW_subsurface_tex_a] = gpu::from_sg(at->texView);
            bind.views[VIEW_subsurface_tex_b] = gpu::from_sg(bt->texView);
            bind.samplers[SMP_subsurface_smp_pt] = g->sampler(SamplerKind::Nearest);
            list.set_bindings(bind);
            const float flip[4] = {gl, 0.0f, 0.0f, 0.0f};
            list.set_uniforms(UB_subsurface_sss_vs_params, gpu::Range{flip, sizeof(flip)});
            list.set_uniforms(UB_subsurface_sss_params, gpu::Range{&params, sizeof(params)});
            list.draw(0, 3, 1);
            list.end_pass();
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
            gpu::CommandList& list = c.commands() ? *c.commands() : g->commands();
            gpu::Swapchain swapchain;
            list.begin_pass(gpu::from_render(pd, swapchain));
            list.set_pipeline(self->pipeline(*g, Prog::BlurV, pd.format));
            gpu::Bindings bind;
            bind.vertexBuffers[0] = g->fullscreen_triangle();
            bind.views[VIEW_subsurface_tex_aa] = gpu::from_sg(at->texView);
            bind.views[VIEW_subsurface_tex_ab] = gpu::from_sg(bt->texView);
            bind.views[VIEW_subsurface_tex_ah] = gpu::from_sg(ht->texView);
            bind.samplers[SMP_subsurface_smp_ap] = g->sampler(SamplerKind::Nearest);
            list.set_bindings(bind);
            const float flip[4] = {gl, 0.0f, 0.0f, 0.0f};
            list.set_uniforms(UB_subsurface_sss_vs_params, gpu::Range{flip, sizeof(flip)});
            list.set_uniforms(UB_subsurface_sss_params, gpu::Range{&params, sizeof(params)});
            list.draw(0, 3, 1);
            list.end_pass();
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
            gpu::CommandList& list = c.commands() ? *c.commands() : g->commands();
            gpu::Swapchain swapchain;
            list.begin_pass(gpu::from_render(pd, swapchain));
            if (!whole) {
                list.set_viewport(rx, ry, rw, rh, true);
                list.set_scissor(rx, ry, rw, rh, true);
            }
            for (int part = 0; part < 2; ++part) {
                list.set_pipeline(self->pipeline(*g, Prog::Add, pd.format, part == 1));
                gpu::Bindings bind;
                bind.vertexBuffers[0] = g->fullscreen_triangle();
                bind.views[VIEW_subsurface_tex_dv] = gpu::from_sg(vt->texView);
                bind.samplers[SMP_subsurface_smp_dv] = g->sampler(SamplerKind::Nearest);
                list.set_bindings(bind);
                const float flip[4] = {gl, 0.0f, 0.0f, 0.0f};
                list.set_uniforms(UB_subsurface_sss_vs_params, gpu::Range{flip, sizeof(flip)});
                subsurface_sss_add_params_t au{};
                au.m[0] = float(part);
                au.m[2] = float(rw);
                au.m[3] = float(rh);
                list.set_uniforms(UB_subsurface_sss_add_params, gpu::Range{&au, sizeof(au)});
                list.draw(0, 3, 1);
                if (drawCalls) ++*drawCalls;
            }
            list.end_pass();
        };
        graph.add_pass(std::move(gp));
    }
    return 3;
}

#if defined(_MSC_VER)
#pragma warning(pop)
#endif

}  // namespace fa::render
