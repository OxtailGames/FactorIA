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

static_assert(UB_gi2d_gi2d_vs_params == 0 && UB_gi2d_gi2d_fs_params == 1, "the gi2d draw program uniform slots");
static_assert(UB_gi2d_gi2d_full_vs_params == 0 && UB_gi2d_gi2d_seed_params == 1 && UB_gi2d_gi2d_jfa_params == 1,
              "the gi2d full-screen programs' uniform slots");
static_assert(VIEW_gi2d_tex == 0 && SMP_gi2d_smp == 0, "the gi2d programs' view and sampler slots");

constexpr sg_pixel_format kFormat = SG_PIXELFORMAT_RGBA16F;

TargetFormat field_format() { return TargetFormat{kFormat, SG_PIXELFORMAT_NONE, 1}; }

void apply_vec4(int slot, float a, float b, float c, float d) {
    const float v[4] = {a, b, c, d};
    const sg_range r{v, sizeof(v)};
    sg_apply_uniforms(slot, &r);
}

// One full-screen triangle with `prog` (seed or a jump-flooding step) into the pass `pd`, reading `src`.
void draw_fullscreen(Gi2dSystem& sys, Gpu& gpu, Gi2dSystem::Prog prog, const PassDesc& pd, sg_view src,
                     const float fs[4], int* drawCalls) {
    if (!pd.color.id || !src.id) return;
    Gpu::begin_pass(pd);
    sg_apply_pipeline(sys.pipeline(prog, pd.format));
    sg_bindings b{};
    b.vertex_buffers[0] = gpu.fullscreen_triangle();
    b.views[0] = src;
    b.samplers[0] = gpu.sampler(SamplerKind::Nearest);
    sg_apply_bindings(&b);
    apply_vec4(0, gpu.is_gl() ? 1.0f : 0.0f, 0.0f, 0.0f, 0.0f);
    apply_vec4(1, fs[0], fs[1], fs[2], fs[3]);
    sg_draw(0, 3, 1);
    Gpu::end_pass();
    if (drawCalls) ++*drawCalls;
}

// Clears `t` to zero and draws the gather's triangles into it, one draw call per batch.
void draw_list(Gi2dSystem& sys, Gpu& gpu, const Target& t, const char* label, Gi2dSystem::Prog prog, sg_view white,
               const std::vector<GiVertex>& verts, const std::vector<GiBatch>& batches, int* drawCalls) {
    PassDesc pd = pass_into(t, label);
    pd.colorLoad = SG_LOADACTION_CLEAR;
    pd.clearColor = {0, 0, 0, 0};
    pd.colorStore = SG_STOREACTION_STORE;
    Gpu::begin_pass(pd);
    if (!verts.empty() && !batches.empty()) {
        const sg_buffer buf = gpu.acquire_transient(verts.size() * sizeof(GiVertex));
        sg_write_buffer_desc wd{};
        wd.src.data = {verts.data(), verts.size() * sizeof(GiVertex)};
        wd.dst.buffer = buf;
        sg_write_buffer_transient(&wd);
        sg_apply_pipeline(sys.pipeline(prog, pd.format));
        apply_vec4(0, 2.0f / float(t.w), 2.0f / float(t.h), gpu.is_gl() ? 1.0f : -1.0f, 0.0f);
        for (const GiBatch& batch : batches) {
            if (batch.count == 0) continue;
            sg_bindings b{};
            b.vertex_buffers[0] = buf;
            b.views[0] = batch.tex ? batch.tex->gpu_view() : white;
            b.samplers[0] = gpu.sampler(batch.sampler);
            sg_apply_bindings(&b);
            apply_vec4(1, float(batch.mode), batch.threshold, float(batch.fix), 0.0f);
            sg_draw(int(batch.first), int(batch.count), 1);
            if (drawCalls) ++*drawCalls;
        }
    }
    Gpu::end_pass();
}

double rounded(double v, double scale) { return std::round(v * scale) / scale; }

}  // namespace

bool Gi2dSystem::float_targets_ok() {
    const sg_pixelformat_info half = sg_query_pixelformat(SG_PIXELFORMAT_RGBA16F);
    return half.render && half.blend && half.filter;
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
    if (!keep) lastSettings = Gi2dSettings{};
    for (auto& s : slots_)
        if (s) s->used = keep;
}

Gi2dField* Gi2dSystem::acquire(int n, const Gi2dGeometry& g) {
    if (n < 0 || n >= kGi2dMaxFields || !g.valid) return nullptr;
    std::unique_ptr<Gi2dField>& slot = slots_[std::size_t(n)];
    if (!slot) slot = std::make_unique<Gi2dField>();
    Gi2dField& f = *slot;
    f.used = true;
    f.valid = false;
    f.passes = 0;
    if (!f.emission.color.id || f.emission.w != g.width || f.emission.h != g.height) {
        destroy_target(f.emission);
        destroy_target(f.occluder);
        destroy_target(f.distance);
        TargetDesc d;
        d.width = g.width;
        d.height = g.height;
        d.colorFormat = kFormat;
        d.label = "gi2d-emission";
        f.emission = make_target(d);
        d.label = "gi2d-occluder";
        f.occluder = make_target(d);
        d.label = "gi2d-distance";
        f.distance = make_target(d);
        if (!f.emission.valid() || !f.occluder.valid() || !f.distance.valid()) {
            destroy_target(f.emission);
            destroy_target(f.occluder);
            destroy_target(f.distance);
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
    }
    f.geom = g;
    return &f;
}

void Gi2dSystem::free_unused() {
    for (auto& s : slots_) {
        if (!s || s->used) continue;
        destroy_target(s->emission);
        destroy_target(s->occluder);
        destroy_target(s->distance);
        s.reset();
    }
}

void Gi2dSystem::free_images() {
    for (auto& s : slots_) {
        if (!s) continue;
        destroy_target(s->emission);
        destroy_target(s->occluder);
        destroy_target(s->distance);
        s.reset();
    }
    warnedTargets_ = false;
}

void Gi2dSystem::release() {
    free_images();
    for (PipelineEntry& e : pipelines_)
        if (e.pipeline.id) sg_destroy_pipeline(e.pipeline);
    pipelines_.clear();
    for (sg_shader& s : shaders_) {
        if (s.id) sg_destroy_shader(s);
        s = {};
    }
    state_ = 0;
}

bool Gi2dSystem::ready() {
    if (state_ != 0) return state_ > 0;
    const sg_backend backend = sg_query_backend();
    shaders_[0] = make_shader(gi2d_draw_shader_desc(backend), "gi2d_draw");
    shaders_[1] = make_shader(gi2d_seed_shader_desc(backend), "gi2d_seed");
    shaders_[2] = make_shader(gi2d_jfa_shader_desc(backend), "gi2d_jfa");
    bool ok = true;
    for (sg_shader s : shaders_) ok = ok && sg_query_shader_state(s) == SG_RESOURCESTATE_VALID;
    if (!ok) {
        for (sg_shader& s : shaders_) {
            if (s.id) sg_destroy_shader(s);
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

sg_pipeline Gi2dSystem::pipeline(Prog prog, const TargetFormat& format) {
    for (const PipelineEntry& e : pipelines_)
        if (e.prog == prog && e.format == format) return e.pipeline;
    if (state_ <= 0) return {};
    sg_pipeline_desc d{};
    const bool draw = prog == Prog::DrawAdd || prog == Prog::DrawReplace;
    d.shader = shaders_[draw ? 0 : prog == Prog::Seed ? 1 : 2];
    d.layout.attrs[0].format = SG_VERTEXFORMAT_FLOAT2;
    if (draw) {
        d.layout.attrs[1].format = SG_VERTEXFORMAT_FLOAT2;
        d.layout.attrs[2].format = SG_VERTEXFORMAT_FLOAT4;
        static_assert(sizeof(GiVertex) == 32, "the vertex layout of the gi2d draw program");
        d.layout.buffers[0].stride = int(sizeof(GiVertex));
    }
    d.depth.compare = SG_COMPAREFUNC_ALWAYS;
    d.depth.write_enabled = false;
    d.depth.pixel_format = format.depth;
    d.colors[0].pixel_format = format.color;
    if (prog == Prog::DrawAdd) {
        d.colors[0].blend.enabled = true;
        d.colors[0].blend.src_factor_rgb = SG_BLENDFACTOR_ONE;
        d.colors[0].blend.dst_factor_rgb = SG_BLENDFACTOR_ONE;
        d.colors[0].blend.src_factor_alpha = SG_BLENDFACTOR_ONE;
        d.colors[0].blend.dst_factor_alpha = SG_BLENDFACTOR_ONE;
    }
    d.sample_count = format.samples;
    d.cull_mode = SG_CULLMODE_NONE;  // the field's y flips on some backends, which turns every winding
    d.label = prog == Prog::DrawAdd       ? "gi2d-emission"
              : prog == Prog::DrawReplace ? "gi2d-occluder"
              : prog == Prog::Seed        ? "gi2d-seed"
                                          : "gi2d-jfa";
    const sg_pipeline p = sg_make_pipeline(&d);
    if (sg_query_pipeline_state(p) != SG_RESOURCESTATE_VALID)
        FA_ERROR("render", "failed to create pipeline '{}'", d.label);
    pipelines_.push_back({prog, format, p});
    return p;
}

// The pass callbacks capture a few floats and pointers by value; nothing here is over-aligned.
int Gi2dSystem::add_passes(FrameGraph& graph, TransientTargets& targets, Gpu& gpu, Gi2dJobPlan& plan,
                           const std::string& name, int* drawCalls) {
    Gi2dField* f = plan.field;
    if (!f || !plan.gather || !ready()) return 0;
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
    const sg_view white = plan.white;

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
    ResourceId prev = graph.create_transient(named(td, name + "/gi2d-seed"));
    const ResourceId seedRes = prev;
    add("gi-seed", {plan.occluder}, {seedRes}, [=](const PassContext& c) {
        const Target* out = tt->get(c.handle(seedRes));
        if (!out) return;
        PassDesc pd = pass_into(*out, "gi2d-seed");
        pd.colorLoad = SG_LOADACTION_DONTCARE;
        const float fs[4] = {size[0], size[1], 0.0f, 0.0f};
        draw_fullscreen(*self, *g, Prog::Seed, pd, f->occluder.texView, fs, drawCalls);
    });
    for (std::size_t i = 0; i < steps.size(); ++i) {
        const bool last = i + 1 == steps.size();
        const ResourceId in = prev;
        const ResourceId out =
            last ? plan.distance : graph.create_transient(named(td, std::format("{}/gi2d-jfa-{}", name, i)));
        const float fs[4] = {size[0], size[1], float(steps[i]), last ? 1.0f : 0.0f};
        const std::string pass = last ? std::string("gi-distance") : std::format("gi-jfa-{}", steps[i]);
        add(pass.c_str(), {in}, {out}, [=](const PassContext& c) {
            const Target* src = tt->get(c.handle(in));
            if (!src) return;
            const Target* dst = last ? &f->distance : tt->get(c.handle(out));
            if (!dst) return;
            PassDesc pd = pass_into(*dst, "gi2d-jfa");
            pd.colorLoad = SG_LOADACTION_DONTCARE;
            draw_fullscreen(*self, *g, Prog::Jfa, pd, src->texView, fs, drawCalls);
            if (last) f->valid = true;
        });
        prev = out;
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
        o["bytes"] =
            double(f->geom.bytes / 5u * 3u);  // the three images that stay; the other two are the frame's transients
        o["passes"] = f->passes;
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
        total += f->geom.bytes / 5u * 3u;
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
    if (!readback_rgba16f(t.color, t.w, t.h, out, error)) return false;
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
