// The GPU side of the 2D GI field (gi2d.h): the shaders and pipelines, the persistent images of each field slot and the frame-graph passes
// that fill them. docs/design/ARCHITECTURE_RENDERING_GI2D.md says what each image holds.
#include "gi2d.h"

#include <algorithm>
#include <cmath>
#include <format>

#include "fa/core/log.h"

#include "frame_graph.h"
#include "shader_cache.h"
#include "shaders/gi2d.glsl.h"

namespace fa::render {

namespace {

// One static_assert per slot: a chain of `a == 1 && b == 1` reads as a redundant expression to clang-tidy once the
// macros expand.
static_assert(UB_gi2d_gi2d_vs_params == 0, "the gi2d draw program uniform slots");
static_assert(UB_gi2d_gi2d_fs_params == 1, "the gi2d draw program uniform slots");
static_assert(UB_gi2d_gi2d_full_vs_params == 0, "the gi2d full-screen programs' uniform slots");
static_assert(UB_gi2d_gi2d_seed_params == 1, "the gi2d full-screen programs' uniform slots");
static_assert(UB_gi2d_gi2d_jfa_params == 1, "the gi2d full-screen programs' uniform slots");
static_assert(VIEW_gi2d_tex == 0, "the gi2d programs' view and sampler slots");
static_assert(SMP_gi2d_smp == 0, "the gi2d programs' view and sampler slots");
static_assert(UB_gi2d_gi2d_seed_emit_params == 1, "the cascade programs' uniform slots");
static_assert(UB_gi2d_gi2d_cascade_params == 1, "the cascade programs' uniform slots");
static_assert(UB_gi2d_gi2d_irradiance_params == 1, "the cascade programs' uniform slots");
static_assert(VIEW_gi2d_c_occ_dist == 0, "the cascade program's view and sampler slots");
static_assert(VIEW_gi2d_c_emit_dist == 1, "the cascade program's view and sampler slots");
static_assert(VIEW_gi2d_c_emission == 2, "the cascade program's view and sampler slots");
static_assert(VIEW_gi2d_c_albedo == 3, "the cascade program's view and sampler slots");
static_assert(VIEW_gi2d_c_upper == 4, "the cascade program's view and sampler slots");
static_assert(VIEW_gi2d_c_hist == 5, "the cascade program's view and sampler slots");
static_assert(SMP_gi2d_c_near == 0, "the cascade program's view and sampler slots");
static_assert(SMP_gi2d_c_lin == 1, "the cascade program's view and sampler slots");
static_assert(VIEW_gi2d_r_cascade == 0, "the irradiance program's view and sampler slots");
static_assert(VIEW_gi2d_r_occ_dist == 1, "the irradiance program's view and sampler slots");
static_assert(VIEW_gi2d_r_emit_dist == 2, "the irradiance program's view and sampler slots");
static_assert(SMP_gi2d_r_near == 0, "the irradiance program's view and sampler slots");

constexpr gpu::PixelFormat kFormat = gpu::PixelFormat::Rgba16F;

TargetFormat field_format() { return TargetFormat{kFormat, gpu::PixelFormat::None, 1}; }

void apply_vec4(gpu::CommandList& list, int slot, float a, float b, float c, float d) {
    const float v[4] = {a, b, c, d};
    list.set_uniforms(slot, gpu::Range{v, sizeof(v)});
}

// One full-screen triangle with `prog` (seed or a jump-flooding step) into the pass `pd`, reading `src`.
void draw_fullscreen(Gi2dSystem& sys, Gpu& gpu, Gi2dSystem::Prog prog, const PassDesc& pd, gpu::View src,
                     const float fs[4], int* drawCalls) {
    if (!pd.color.id || !src.id) return;
    gpu::CommandList& list = gpu.commands();
    list.begin_pass(pd);
    list.set_pipeline(sys.pipeline(prog, pd.format));
    gpu::Bindings b;
    b.vertexBuffers[0] = gpu.fullscreen_triangle();
    b.views[0] = src;
    b.samplers[0] = gpu.sampler(SamplerKind::Nearest);
    list.set_bindings(b);
    apply_vec4(list, 0, gpu.is_gl() ? 1.0f : 0.0f, 0.0f, 0.0f, 0.0f);
    apply_vec4(list, 1, fs[0], fs[1], fs[2], fs[3]);
    list.draw(0, 3, 1);
    list.end_pass();
    if (drawCalls) ++*drawCalls;
}

// One radiance cascade into `pd`: reads the two distance fields, the emission, the occluders, the cascade above and the history.
struct CascadeViews {
    gpu::View occDist, emitDist, emission, albedo, upper, hist;
};
void draw_cascade(Gi2dSystem& sys, Gpu& gpu, const PassDesc& pd, const CascadeViews& v, const float p[4][4],
                  int* drawCalls) {
    if (!pd.color.id) return;
    gpu::CommandList& list = gpu.commands();
    list.begin_pass(pd);
    list.set_pipeline(sys.pipeline(Gi2dSystem::Prog::Cascade, pd.format));
    gpu::Bindings b;
    b.vertexBuffers[0] = gpu.fullscreen_triangle();
    b.views[VIEW_gi2d_c_occ_dist] = v.occDist;
    b.views[VIEW_gi2d_c_emit_dist] = v.emitDist;
    b.views[VIEW_gi2d_c_emission] = v.emission;
    b.views[VIEW_gi2d_c_albedo] = v.albedo;
    b.views[VIEW_gi2d_c_upper] = v.upper;
    b.views[VIEW_gi2d_c_hist] = v.hist;
    b.samplers[SMP_gi2d_c_near] = gpu.sampler(SamplerKind::Nearest);
    b.samplers[SMP_gi2d_c_lin] = gpu.sampler(SamplerKind::LinearClamp);
    list.set_bindings(b);
    apply_vec4(list, 0, gpu.is_gl() ? 1.0f : 0.0f, 0.0f, 0.0f, 0.0f);
    list.set_uniforms(UB_gi2d_gi2d_cascade_params, gpu::Range{p, sizeof(float) * 16});
    list.draw(0, 3, 1);
    list.end_pass();
    if (drawCalls) ++*drawCalls;
}

// The irradiance image: the rays of every probe of cascade 0 averaged.
void draw_irradiance(Gi2dSystem& sys, Gpu& gpu, const PassDesc& pd, gpu::View cascade0, gpu::View occDist,
                     gpu::View emitDist, const float fs[4], int* drawCalls) {
    if (!pd.color.id) return;
    gpu::CommandList& list = gpu.commands();
    list.begin_pass(pd);
    list.set_pipeline(sys.pipeline(Gi2dSystem::Prog::Irradiance, pd.format));
    gpu::Bindings b;
    b.vertexBuffers[0] = gpu.fullscreen_triangle();
    b.views[VIEW_gi2d_r_cascade] = cascade0;
    b.views[VIEW_gi2d_r_occ_dist] = occDist;
    b.views[VIEW_gi2d_r_emit_dist] = emitDist;
    b.samplers[SMP_gi2d_r_near] = gpu.sampler(SamplerKind::Nearest);
    list.set_bindings(b);
    apply_vec4(list, 0, gpu.is_gl() ? 1.0f : 0.0f, 0.0f, 0.0f, 0.0f);
    apply_vec4(list, UB_gi2d_gi2d_irradiance_params, fs[0], fs[1], fs[2], fs[3]);
    list.draw(0, 3, 1);
    list.end_pass();
    if (drawCalls) ++*drawCalls;
}

void destroy_images(gpu::Device* device, Gi2dField& f) {
    if (device) {  // no image was made before the first acquire
        destroy_target(*device, f.emission);
        destroy_target(*device, f.occluder);
        destroy_target(*device, f.distance);
        destroy_target(*device, f.irradiance[0]);
        destroy_target(*device, f.irradiance[1]);
    }
    f.irrValid = false;
}

// Clears `t` to zero and draws the gather's triangles into it, one draw call per batch.
void draw_list(Gi2dSystem& sys, Gpu& gpu, const Target& t, const char* label, Gi2dSystem::Prog prog, gpu::View white,
               const std::vector<GiVertex>& verts, const std::vector<GiBatch>& batches, int* drawCalls) {
    PassDesc pd = pass_into(t, label);
    pd.colorLoad = gpu::LoadAction::Clear;
    pd.clearColor = {0, 0, 0, 0};
    pd.colorStore = gpu::StoreAction::Store;
    gpu::CommandList& list = gpu.commands();
    // The vertices are written before the pass opens: acquire_transient's Metal pacing copy cannot run inside one (the pass is on this
    // list, so Gpu::in_pass() does not know it).
    const bool anyDraw = !verts.empty() && !batches.empty();
    gpu::Buffer buf{};
    if (anyDraw) {
        buf = gpu.acquire_transient(verts.size() * sizeof(GiVertex));
        gpu::BufferWrite wd;
        wd.data = gpu::Range{verts.data(), verts.size() * sizeof(GiVertex)};
        wd.buffer = buf;
        list.write_buffer(wd);
    }
    list.begin_pass(pd);
    if (anyDraw) {
        list.set_pipeline(sys.pipeline(prog, pd.format));
        apply_vec4(list, 0, 2.0f / float(t.w), 2.0f / float(t.h), gpu.is_gl() ? 1.0f : -1.0f, 0.0f);
        for (const GiBatch& batch : batches) {
            if (batch.count == 0) continue;
            gpu::Bindings b;
            b.vertexBuffers[0] = buf;
            b.views[0] = batch.tex ? gpu::from_sg(batch.tex->gpu_view()) : white;
            b.samplers[0] = gpu.sampler(batch.sampler);
            list.set_bindings(b);
            apply_vec4(list, 1, float(batch.mode), batch.threshold, float(batch.fix), 0.0f);
            list.draw(int(batch.first), int(batch.count), 1);
            if (drawCalls) ++*drawCalls;
        }
    }
    list.end_pass();
}

double rounded(double v, double scale) { return std::round(v * scale) / scale; }

}  // namespace

bool Gi2dSystem::float_targets_ok(const gpu::Device& device) {
    const gpu::PixelFormatCaps half = device.pixel_format_caps(gpu::PixelFormat::Rgba16F);
    return half.render && half.blend && half.filter;
}

bool Gi2dSystem::float_targets_ok() {
    Gpu* g = Gpu::active();
    return g && g->has_device() && float_targets_ok(g->device());
}

std::string Gi2dSystem::unsupported_message(const std::string& backend) {
    return std::format("2D global illumination needs RGBA16F render targets that blend and filter, and the graphics "
                       "backend {} has none, so "
                       "GlobalIllumination2D is ignored and no light is bounced. Hint: ask "
                       "renderer.supports(\"2dGlobalIllumination\") before "
                       "relying on it; a game that needs the look on every device lights its scene with Light2D and "
                       "Sprite.emissive instead.",
                       backend);
}

void Gi2dSystem::begin_frame(bool keep) {
    if (!keep) {
        lastSettings = Gi2dSettings{};
        if (!giAsked_) reset_warnings();  // a scene without GI (or a new scene) warns again when it turns on
        giAsked_ = false;
    }
    for (auto& s : slots_)
        if (s) s->used = keep;
}

Gi2dField* Gi2dSystem::acquire(int n, const Gi2dGeometry& g, const Gi2dCascadePlan& cp) {
    return acquire(device_ ? *device_ : Gpu::active_device(), n, g, cp);
}

Gi2dField* Gi2dSystem::acquire(gpu::Device& device, int n, const Gi2dGeometry& g, const Gi2dCascadePlan& cp) {
    if (n < 0 || n >= kGi2dMaxFields || !g.valid || !cp.ok) return nullptr;
    std::unique_ptr<Gi2dField>& slot = slots_[std::size_t(n)];
    if (!slot) slot = std::make_unique<Gi2dField>();
    Gi2dField& f = *slot;
    f.used = true;
    f.valid = false;
    f.passes = 0;
    if (!f.emission.color.id || f.emission.w != g.width || f.emission.h != g.height || f.irradiance[0].w != cp.gridW ||
        f.irradiance[0].h != cp.gridH) {
        // A new size: the images are made again and the bounce starts from nothing (no history is kept across sizes).
        destroy_images(device_, f);
        device_ = &device;
        TargetDesc d;
        d.width = g.width;
        d.height = g.height;
        d.colorFormat = kFormat;
        d.label = "gi2d-emission";
        f.emission = make_target(device, d);
        d.label = "gi2d-occluder";
        f.occluder = make_target(device, d);
        d.label = "gi2d-distance";
        f.distance = make_target(device, d);
        d.width = cp.gridW;
        d.height = cp.gridH;
        d.label = "gi2d-irradiance-a";
        f.irradiance[0] = make_target(device, d);
        d.label = "gi2d-irradiance-b";
        f.irradiance[1] = make_target(device, d);
        if (!f.emission.valid(device) || !f.occluder.valid(device) || !f.distance.valid(device) ||
            !f.irradiance[0].valid(device) || !f.irradiance[1].valid(device)) {
            destroy_images(device_, f);
            f.used = false;
            if (!warnedTargets_) {
                warnedTargets_ = true;
                FA_ERROR("render",
                         "2D global illumination: the GPU could not make the {}x{} RGBA16F images of the field, so "
                         "this camera gets no "
                         "global illumination. Hint: lower GlobalIllumination2D.resolutionScale or range.",
                         g.width, g.height);
            }
            return nullptr;
        }
        f.irrCur = 0;
    }
    f.geom = g;
    f.cascade = cp;
    return &f;
}

void Gi2dSystem::free_unused() {
    for (auto& s : slots_) {
        if (!s || s->used) continue;
        destroy_images(device_, *s);
        s.reset();
    }
}

void Gi2dSystem::shift(double dx, double dy) {
    for (auto& s : slots_) {
        if (!s) continue;
        // Every position of the fields is local: the same world square has the coordinates minus the offset. Both the images' geometry and
        // the history's stay on the same texels, so the next frame finds the shift between them as before the rebase (0 for a still camera).
        s->geom.originX -= dx;
        s->geom.originY -= dy;
        s->histOriginX -= dx;
        s->histOriginY -= dy;
    }
    ++shifts_;
}

void Gi2dSystem::free_images() {
    for (auto& s : slots_) {
        if (!s) continue;
        destroy_images(device_, *s);
        s.reset();
    }
    warnedTargets_ = false;
    reset_warnings();
}

void Gi2dSystem::release() {
    free_images();
    if (device_) {  // nothing was made before a device was given
        for (PipelineEntry& e : pipelines_)
            if (e.pipeline.id) device_->destroy_pipeline(e.pipeline);
        for (gpu::Shader& s : shaders_) {
            if (s.id) device_->destroy_shader(s);
            s = {};
        }
    }
    pipelines_.clear();
    state_ = 0;
}

bool Gi2dSystem::ready(gpu::Device& device) {
    if (state_ != 0) return state_ > 0;
    device_ = &device;
    shaders_[0] = make_shader(device, gpu::generated_shader_desc(gi2d_draw_shader_desc), "gi2d_draw");
    shaders_[1] = make_shader(device, gpu::generated_shader_desc(gi2d_seed_shader_desc), "gi2d_seed");
    shaders_[2] = make_shader(device, gpu::generated_shader_desc(gi2d_jfa_shader_desc), "gi2d_jfa");
    shaders_[3] = make_shader(device, gpu::generated_shader_desc(gi2d_seed_emit_shader_desc), "gi2d_seed_emit");
    shaders_[4] = make_shader(device, gpu::generated_shader_desc(gi2d_cascade_shader_desc), "gi2d_cascade");
    shaders_[5] = make_shader(device, gpu::generated_shader_desc(gi2d_irradiance_shader_desc), "gi2d_irradiance");
    bool ok = true;
    for (gpu::Shader s : shaders_) ok = ok && device.state(s) == gpu::ResourceState::Valid;
    if (!ok) {
        for (gpu::Shader& s : shaders_) {
            if (s.id) device.destroy_shader(s);
            s = {};
        }
        state_ = -1;
        FA_ERROR("render", "2D global illumination is unavailable: its shaders failed to compile for this graphics "
                           "backend (see the sokol log "
                           "lines above). The game renders without it. Hint: update the graphics driver (Mesa: try "
                           "LIBGL_ALWAYS_SOFTWARE=1) or "
                           "remove GlobalIllumination2D.");
        return false;
    }
    state_ = 1;
    return true;
}

gpu::Pipeline Gi2dSystem::pipeline(Prog prog, const TargetFormat& format) {
    for (const PipelineEntry& e : pipelines_)
        if (e.prog == prog && e.format == format) return e.pipeline;
    if (state_ <= 0 || !device_) return {};
    const gpu::TargetFormat target = format;
    gpu::PipelineDesc d;
    const bool draw = prog == Prog::DrawAdd || prog == Prog::DrawReplace;
    static constexpr int kShaderOf[] = {0, 0, 1, 2, 3, 4, 5};  // by Prog
    d.shader = shaders_[kShaderOf[int(prog)]];
    d.layout.attrs[0].format = gpu::VertexFormat::Float2;
    if (draw) {
        d.layout.attrs[1].format = gpu::VertexFormat::Float2;
        d.layout.attrs[2].format = gpu::VertexFormat::Float4;
        static_assert(sizeof(GiVertex) == 32, "the vertex layout of the gi2d draw program");
        d.layout.buffers[0].stride = int(sizeof(GiVertex));
    }
    d.depth.compare = gpu::CompareFunc::Always;
    d.depth.writeEnabled = false;
    d.depth.pixelFormat = target.depth;
    d.colors[0].pixelFormat = target.color;
    if (prog == Prog::DrawAdd) {
        d.colors[0].blend.enabled = true;
        d.colors[0].blend.srcFactorRgb = gpu::BlendFactor::One;
        d.colors[0].blend.dstFactorRgb = gpu::BlendFactor::One;
        d.colors[0].blend.srcFactorAlpha = gpu::BlendFactor::One;
        d.colors[0].blend.dstFactorAlpha = gpu::BlendFactor::One;
    }
    d.sampleCount = target.samples;
    d.cullMode = gpu::CullMode::None;  // the field's y flips on some backends, which turns every winding
    static constexpr const char* kLabels[] = {"gi2d-emission",  "gi2d-occluder", "gi2d-seed",      "gi2d-jfa",
                                              "gi2d-seed-emit", "gi2d-cascade",  "gi2d-irradiance"};
    d.label = kLabels[int(prog)];
    const gpu::Pipeline p = device_->make_pipeline(d);
    if (device_->state(p) != gpu::ResourceState::Valid) FA_ERROR("render", "failed to create pipeline '{}'", d.label);
    pipelines_.push_back({prog, format, p});
    return p;
}

// The pass callbacks capture a few floats and pointers by value; nothing here is over-aligned.
int Gi2dSystem::add_passes(FrameGraph& graph, TransientTargets& targets, Gpu& gpu, Gi2dJobPlan& plan,
                           const std::string& name, int* drawCalls) {
    Gi2dField* f = plan.field;
    if (!f || !plan.gather || !ready(gpu.device())) return 0;
    const int w = f->geom.width, h = f->geom.height;
    // Every image of the jump flooding is its own transient (the pool reuses the memory of the ones that are dead by then).
    TransientDesc td;
    td.width = w;
    td.height = h;
    td.format = field_format();
    auto named = [&](TransientDesc d, std::string label) {
        d.label = std::move(label);
        return d;
    };
    auto imp = [&](const Target& t, const char* what) {
        TransientDesc d;
        d.width = t.w;
        d.height = t.h;
        d.format = field_format();
        d.label = std::string(what);
        return graph.import_target(name + "/" + what, t.color.id, d);
    };
    plan.emission = imp(f->emission, "gi2d-emission");
    plan.occluder = imp(f->occluder, "gi2d-occluder");
    plan.distance = imp(f->distance, "gi2d-distance");

    int declared = 0;
    auto add = [&](const char* pass, std::vector<ResourceId> reads, std::vector<ResourceId> writes, auto&& fn) {
        GraphPass gp;
        gp.name = name + "/" + pass;
        gp.reads = std::move(reads);
        gp.writes = std::move(writes);
        gp.execute = std::forward<decltype(fn)>(fn);
        graph.add_pass(std::move(gp));
        ++declared;
    };
    Gi2dSystem* self = this;
    Gpu* g = &gpu;
    TransientTargets* tt = &targets;
    const std::shared_ptr<Gi2dGather> gather = plan.gather;
    const gpu::View white = plan.white;

    add("gi-emission", {}, {plan.emission}, [=](const PassContext&) {
        draw_list(*self, *g, f->emission, "gi2d-emission", Prog::DrawAdd, white, gather->emitVerts, gather->emitBatches,
                  drawCalls);
    });
    add("gi-occluders", {}, {plan.occluder}, [=](const PassContext&) {
        draw_list(*self, *g, f->occluder, "gi2d-occluder", Prog::DrawReplace, white, gather->occVerts,
                  gather->occBatches, drawCalls);
    });

    // Jump flooding with one extra step of 1 first (1+JFA): the steps run from the largest power of two below the field's size down to 1.
    std::vector<int> steps{1};
    {
        int p = 1;
        const int n = std::max(w, h);
        while (p * 2 < n) p *= 2;
        for (int s = p; s >= 1; s /= 2) steps.push_back(s);
    }
    const float size[2] = {float(w), float(h)};
    // One chain: `seedProg` turns the image `sourceTarget` (resource `source`) into seeds, the steps flood them and the last one writes
    // `finalRes` (the nearest seed of every texel and its distance), into `finalTarget` when that is a persistent image and into a transient
    // of the graph otherwise. `tag` names the passes ("gi" for the occluders, "gi-emit" for the emitters).
    auto flood = [&](const char* tag, Prog seedProg, ResourceId source, const Target* sourceTarget, ResourceId finalRes,
                     Target* finalTarget) {
        ResourceId prev = graph.create_transient(named(td, std::format("{}/{}-seed", name, tag)));
        const ResourceId seedRes = prev;
        add(std::format("{}-seed", tag).c_str(), {source}, {seedRes}, [=](const PassContext& c) {
            const Target* out = tt->get(c.handle(seedRes));
            if (!out) return;
            PassDesc pd = pass_into(*out, "gi2d-seed");
            pd.colorLoad = gpu::LoadAction::DontCare;
            const float fs[4] = {size[0], size[1], 0.0f, 0.0f};
            draw_fullscreen(*self, *g, seedProg, pd, sourceTarget->texView, fs, drawCalls);
        });
        for (std::size_t i = 0; i < steps.size(); ++i) {
            const bool last = i + 1 == steps.size();
            const ResourceId in = prev;
            const ResourceId out =
                last ? finalRes : graph.create_transient(named(td, std::format("{}/{}-jfa-{}", name, tag, i)));
            const float fs[4] = {size[0], size[1], float(steps[i]), last ? 1.0f : 0.0f};
            const std::string pass = last ? std::string(tag) + "-distance" : std::format("{}-jfa-{}", tag, steps[i]);
            add(pass.c_str(), {in}, {out}, [=](const PassContext& c) {
                const Target* src = tt->get(c.handle(in));
                if (!src) return;
                const Target* dst = last && finalTarget ? finalTarget : tt->get(c.handle(out));
                if (!dst) return;
                PassDesc pd = pass_into(*dst, "gi2d-jfa");
                pd.colorLoad = gpu::LoadAction::DontCare;
                draw_fullscreen(*self, *g, Prog::Jfa, pd, src->texView, fs, drawCalls);
                if (last && finalTarget == &f->distance) f->valid = true;
            });
            prev = out;
        }
    };
    flood("gi", Prog::Seed, plan.occluder, &f->occluder, plan.distance, &f->distance);

    // ---- The radiance cascades (gi2d.glsl, fs_cascade) ----
    const Gi2dCascadePlan& cp = f->cascade;
    if (cp.ok && cp.cascades > 0) {
        // The nearest emitter: the same chain over the emission image, into a transient the cascades read.
        const ResourceId emitDist = graph.create_transient(named(td, name + "/gi2d-emit-distance"));
        flood("gi-emit", Prog::SeedEmit, plan.emission, &f->emission, emitDist, nullptr);

        // The bounce is capped (kGi2dMaxBounceGain), so the loop gain of a closed room (history -> blocker -> history) stays under 1.
        const float bounce = std::min(f->settings.bounce, kGi2dMaxBounceGain);
        const int wr = f->irrCur ^ 1;  // written by this frame; the other one is last frame's (the bounce's history)
        const int hr = f->irrCur;
        Target* irrW = &f->irradiance[wr];
        Target* irrH = &f->irradiance[hr];
        plan.irradiance = imp(*irrW, "gi2d-irradiance");
        const ResourceId histRes = imp(*irrH, "gi2d-irradiance-history");
        plan.irradianceView = irrW->texView;
        plan.intensity = f->settings.intensity;
        plan.xf[0] = float(1.0 / (f->geom.texel * double(w)));
        plan.xf[1] = float(1.0 / (f->geom.texel * double(h)));
        plan.xf[2] = float(-f->geom.originX / (f->geom.texel * double(w)));
        plan.xf[3] = float(-f->geom.originY / (f->geom.texel * double(h)));
        // The history is last frame's irradiance, valid when it was made for the same texel size and the camera has moved by less than the
        // field (the field's origin is snapped to whole texels, so the shift is a whole number of them).
        const double shiftX = (f->geom.originX - f->histOriginX) / f->geom.texel;
        const double shiftY = (f->geom.originY - f->histOriginY) / f->geom.texel;
        // A history made for another job (a camera went away and another took its slot) is not this camera's light either.
        const bool histOk = bounce > 0.0f && f->irrValid && f->histTexel == f->geom.texel && f->histJob == name &&
                            f->histCamera == f->camera && std::fabs(shiftX) < double(w) &&
                            std::fabs(shiftY) < double(h);
        const float shift[2] = {float(std::round(shiftX)), float(std::round(shiftY))};
        const bool prime = bounce > 0.0f && !histOk;
        f->primed = prime;
        const int base = declared;
        const int spacing0 = cp.spacing0, nsteps = cp.steps, ncas = cp.cascades;
        const std::string jobName = name;
        double ends[kGi2dMaxCascades + 1] = {};
        for (int i = 0; i <= kGi2dMaxCascades; ++i)
            ends[i] = cp.interval_end(i - 1);  // ends[i] = the start of cascade i

        // One chain of cascades into the irradiance image `outRes` / `outT`, from the top down, each merging the one above it. A ray that hits
        // an occluder reads the light that reached it last frame from `histT` (resource `histIn`), shifted by `sh` texels, when `useHist`.
        // `commit`: the last pass records that the image holds a finished frame (the next frame's history).
        auto chain = [&](const char* tag, ResourceId outRes, Target* outT, ResourceId histIn, const Target* histT,
                         bool useHist, const float sh[2], bool commit) {
            ResourceId upper;
            for (int i = ncas - 1; i >= 0; --i) {
                const ResourceId res =
                    graph.create_transient(named(td, std::format("{}/gi2d-{}-cascade-{}", name, tag, i)));
                std::vector<ResourceId> reads{plan.distance, emitDist, plan.emission, plan.occluder};
                if (upper.valid()) reads.push_back(upper);
                if (useHist) reads.push_back(histIn);
                float params[4][4] = {
                    {float(w), float(h), float(w), float(h)},
                    {float(spacing0 << i), float(ends[i]), float(ends[i + 1]), i == ncas - 1 ? 1.0f : 0.0f},
                    {bounce, useHist ? 1.0f : 0.0f, sh[0], sh[1]},
                    {float(nsteps), 0.0f, 0.0f, 0.0f}};
                const ResourceId up = upper;
                const std::string pass = std::format("{}-cascade-{}", tag, i);
                add(pass.c_str(), std::move(reads), {res}, [=](const PassContext& c) {
                    const Target* out = tt->get(c.handle(res));
                    const Target* ed = tt->get(c.handle(emitDist));
                    if (!out || !ed) return;
                    const Target* upT = up.valid() ? tt->get(c.handle(up)) : nullptr;
                    CascadeViews v;
                    v.occDist = f->distance.texView;
                    v.emitDist = ed->texView;
                    v.emission = f->emission.texView;
                    v.albedo = f->occluder.texView;
                    v.upper = upT ? upT->texView : f->emission.texView;  // the top cascade never reads it
                    v.hist = useHist && histT ? histT->texView : f->emission.texView;
                    PassDesc pd = pass_into(*out, "gi2d-cascade");
                    pd.colorLoad = gpu::LoadAction::DontCare;
                    draw_cascade(*self, *g, pd, v, params, drawCalls);
                });
                upper = res;
            }
            const ResourceId cascade0 = upper;
            const float irrParams[4] = {float(spacing0), float(w), float(h), 0.0f};
            const std::string pass = std::format("{}-irradiance", tag);
            add(pass.c_str(), {cascade0, plan.distance, emitDist}, {outRes}, [=](const PassContext& c) {
                const Target* c0 = tt->get(c.handle(cascade0));
                const Target* ed = tt->get(c.handle(emitDist));
                if (!c0 || !ed) return;
                PassDesc pd = pass_into(*outT, "gi2d-irradiance");
                pd.colorLoad = gpu::LoadAction::DontCare;
                draw_irradiance(*self, *g, pd, c0->texView, f->distance.texView, ed->texView, irrParams, drawCalls);
                if (commit) {
                    f->irrCur = outT == &f->irradiance[0] ? 0 : 1;
                    f->irrValid = true;
                    f->histTexel = f->geom.texel;
                    f->histOriginX = f->geom.originX;
                    f->histOriginY = f->geom.originY;
                    f->histJob = jobName;
                    f->histCamera = f->camera;
                }
            });
        };
        const float noShift[2] = {0.0f, 0.0f};
        if (prime) chain("gi-prime", histRes, irrH, ResourceId{}, nullptr, false, noShift, false);
        chain("gi", plan.irradiance, irrW, histRes, irrH, bounce > 0.0f, prime ? noShift : shift, true);
        plan.cascadePasses = declared - base;
    }
    f->passes = declared;
    return declared;
}

Gi2dField* Gi2dSystem::find(const std::string& job) {
    for (auto& s : slots_)
        if (s && s->valid && (job.empty() || s->job == job)) return s.get();
    return nullptr;
}

Json Gi2dSystem::report(const std::string& backend) const {
    Json out = Json::object();
    const bool supported = float_targets_ok();
    out["enabled"] = lastSettings.on;
    out["supported"] = supported;
    if (!supported) out["message"] = unsupported_message(backend);
    out["fieldLimit"] = kGi2dMaxFields;
    out["maxSize"] = kGi2dMaxSize;
    out["format"] = "RGBA16F";
    if (lastSettings.on) {
        Json s = Json::object();
        s["quality"] = lastSettings.quality == GI2DQuality::Low    ? "low"
                       : lastSettings.quality == GI2DQuality::High ? "high"
                                                                   : "medium";
        s["intensity"] = rounded(lastSettings.intensity, 1000.0);
        s["bounce"] = rounded(lastSettings.bounce, 1000.0);
        s["range"] = rounded(lastSettings.range, 1000.0);
        s["resolutionScale"] = rounded(lastSettings.resolutionScale, 1000.0);
        out["settings"] = std::move(s);
    }
    Json fields = Json::array();
    std::uint64_t total = 0;
    for (std::size_t i = 0; i < slots_.size(); ++i) {
        const Gi2dField* f = slots_[i].get();
        if (!f || !f->used) continue;
        Json o = Json::object();
        o["slot"] = int(i);
        o["job"] = f->job;
        o["ready"] = f->valid;
        o["width"] = f->geom.width;
        o["height"] = f->geom.height;
        o["texelSize"] = rounded(f->geom.texel, 1.0e6);
        Json r = Json::object();
        r["x"] = rounded(f->geom.originX, 1000.0);
        r["y"] = rounded(f->geom.originY, 1000.0);
        r["width"] = rounded(f->geom.world_w(), 1000.0);
        r["height"] = rounded(f->geom.world_h(), 1000.0);
        o["worldRect"] = std::move(r);
        o["capped"] = f->geom.capped;
        o["bytes"] = double(
            f->cascade.persistentBytes);  // the images that stay: the field's three and the two irradiance images
        o["passes"] = f->passes;
        Json cas = Json::object();
        cas["cascades"] = f->cascade.cascades;
        cas["probeSpacing"] = f->cascade.spacing0;
        cas["raysPerProbe"] = f->cascade.rays0;
        cas["steps"] = f->cascade.steps;
        cas["reachTexels"] = rounded(f->cascade.reach, 1.0);
        cas["irradianceWidth"] = f->cascade.gridW;
        cas["irradianceHeight"] = f->cascade.gridH;
        cas["primed"] = f->primed;
        o["cascades"] = std::move(cas);
        Json e = Json::object();
        e["sprites"] = f->stats.emissiveSprites;
        e["tiles"] = f->stats.emissiveTiles;
        e["lights"] = f->stats.lights;
        o["emitters"] = std::move(e);
        Json c = Json::object();
        c["solidTiles"] = f->stats.solidTiles;
        c["boxes"] = f->stats.boxes;
        c["polygons"] = f->stats.polygons;
        c["spriteAlpha"] = f->stats.spriteCasters;
        c["skipped"] = f->stats.skippedCasters;
        o["occluders"] = std::move(c);
        o["dropped"] = f->stats.dropped;
        total += f->cascade.persistentBytes;
        fields.push_back(std::move(o));
    }
    out["fields"] = std::move(fields);
    out["bytes"] = double(total);
    return out;
}

bool gi2d_read(const Target& t, bool isGl, std::vector<float>& out, std::string* error) {
    if (!t.color.id || t.w <= 0 || t.h <= 0) {
        if (error) *error = "the field image does not exist";
        return false;
    }
    if (!readback_rgba16f(gpu::to_sg(t.color), t.w, t.h, out, error)) return false;
    // readback_rgba16f returns the picture top row first: on OpenGL that is the highest texture row, elsewhere the lowest. The field's
    // contract is "texture row 0 first" on every backend.
    if (isGl) {
        const std::size_t stride = std::size_t(t.w) * 4;
        for (int y = 0; y < t.h / 2; ++y)
            std::swap_ranges(out.begin() + std::ptrdiff_t(std::size_t(y) * stride),
                             out.begin() + std::ptrdiff_t(std::size_t(y + 1) * stride),
                             out.begin() + std::ptrdiff_t(std::size_t(t.h - 1 - y) * stride));
    }
    return true;
}

}  // namespace fa::render
