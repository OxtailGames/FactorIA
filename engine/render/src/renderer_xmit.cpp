#include "renderer_xmit.h"

#include <algorithm>
#include <cmath>

#include "fa/core/log.h"

#include "shader_cache.h"
#include "shaders/xmit.glsl.h"

namespace fa::render {

namespace {

constexpr std::size_t kMaxShapes = 16;

std::uint64_t shape_key(int w, int h, sg_pixel_format fmt) {
    return (std::uint64_t(std::uint32_t(w)) << 40) ^ (std::uint64_t(std::uint32_t(h)) << 16) ^ std::uint64_t(fmt);
}

TransientDesc desc_of(int w, int h, sg_pixel_format fmt, const char* label) {
    TransientDesc d;
    d.width = w;
    d.height = h;
    d.format = TargetFormat{fmt, SG_PIXELFORMAT_NONE, 1};
    d.label = label;
    return d;
}

// One full-screen triangle into the rectangle (x, row, w, h) of the pass's target, in image rows. `src`: the source rectangle (image rows) of
// the image `view` (`imgW` x `imgH`), `reduce`: 4-tap reduction instead of the copy.
void draw_rect(Gpu& gpu, sg_view view, int imgW, int imgH, int sx, int sy, int sw, int sh, bool reduce, int x, int row,
               int w, int h) {
    sg_apply_viewport(x, row, w, h, !gpu.is_gl());
    sg_apply_scissor_rect(x, row, w, h, !gpu.is_gl());
    sg_bindings b{};
    b.vertex_buffers[0] = gpu.fullscreen_triangle();
    b.views[VIEW_xmit_tex_src] = view;
    b.samplers[SMP_xmit_smp_lin] = gpu.sampler(SamplerKind::LinearClamp);
    sg_apply_bindings(&b);
    xmit_xmit_vs_params_t vu{};
    vu.flip[0] = gpu.is_gl() ? 1.0f : 0.0f;
    sg_range vr{&vu, sizeof(vu)};
    sg_apply_uniforms(UB_xmit_xmit_vs_params, &vr);
    xmit_xmit_params_t fu{};
    fu.src[0] = float(sx);
    fu.src[1] = float(sy);
    fu.src[2] = float(sw);
    fu.src[3] = float(sh);
    fu.info[0] = float(imgW);
    fu.info[1] = float(imgH);
    fu.info[2] = reduce ? 1.0f : 0.0f;
    sg_range fr{&fu, sizeof(fu)};
    sg_apply_uniforms(UB_xmit_xmit_params, &fr);
    sg_draw(0, 3, 1);
}

}  // namespace

XmitLayout xmit_layout(int w, int h) {
    XmitLayout l;
    if (w < 1 || h < 1) return l;
    int levels = 1;
    for (int m = std::min(w, h); m >= 2 && levels < kXmitMaxLevels; m >>= 1) ++levels;
    l.levels = levels;
    int stackY = 0;
    for (int k = 0; k < levels; ++k) {
        XmitLayout::Level& v = l.level[k];
        v.w = std::max(w >> k, 1);
        v.h = std::max(h >> k, 1);
        if (k == 0) {
            v.x = 0;
            v.y = 0;
        } else {
            v.x = w;
            v.y = stackY;
            stackY += v.h;
        }
    }
    l.atlasW = w + (levels > 1 ? l.level[1].w : 0);
    l.atlasH = std::max(h, stackY);
    return l;
}

bool Xmit::ready() {
    if (state_ != 0) return state_ > 0;
    shader_ = make_shader(xmit_copy_shader_desc(sg_query_backend()), "xmit_copy");
    if (sg_query_shader_state(shader_) != SG_RESOURCESTATE_VALID) {
        if (shader_.id) sg_destroy_shader(shader_);
        shader_ = {};
        state_ = -1;
        FA_ERROR("render", "Transmission (glass, liquids) is drawn without refraction: its copy shader failed to "
                           "compile for this graphics "
                           "backend (see the sokol log lines above). Transmissive meshes are blended plainly. Hint: "
                           "update the graphics "
                           "driver (Mesa: try LIBGL_ALWAYS_SOFTWARE=1).");
        return false;
    }
    state_ = 1;
    return true;
}

sg_pipeline Xmit::pipeline(const TargetFormat& format) {
    for (const PipelineEntry& e : pipelines_)
        if (e.format == format) return e.pipeline;  // an id of 0 = the GPU refused this format (said once, below)
    if (state_ <= 0) return {};
    sg_pipeline_desc d{};
    d.shader = shader_;
    d.layout.attrs[0].format = SG_VERTEXFORMAT_FLOAT2;  // `pos`
    d.depth.compare = SG_COMPAREFUNC_ALWAYS;
    d.depth.write_enabled = false;
    d.depth.pixel_format = format.depth;
    d.colors[0].pixel_format = format.color;
    d.sample_count = format.samples;
    d.face_winding = SG_FACEWINDING_CCW;
    d.label = "xmit-copy";
    sg_pipeline p = sg_make_pipeline(&d);
    if (sg_query_pipeline_state(p) != SG_RESOURCESTATE_VALID) {
        FA_ERROR("render",
                 "Transmission: failed to create the copy pipeline for this render target format; transmissive meshes "
                 "are blended plainly without refraction. Hint: see the sokol log lines above.");
        if (p.id) sg_destroy_pipeline(p);
        p = {};  // remembered as failed: no second attempt, no second message, and build() gives the picture up
    }
    pipelines_.push_back({format, p});
    return p;
}

bool Xmit::can_make(TransientTargets& targets, Gpu& gpu, int w, int h) {
    const XmitLayout lay = xmit_layout(w, h);
    if (lay.levels < 1) return false;
    if (!ready()) return false;
    const sg_pixel_format fmt = gpu.scene_format();
    const std::uint64_t key = shape_key(w, h, fmt);
    if (std::find(failed_.begin(), failed_.end(), key) != failed_.end()) return false;
    if (std::find(probed_.begin(), probed_.end(), key) != probed_.end()) return true;
    std::uint64_t held[kXmitMaxLevels + 1]{};
    int n = 0;
    held[n] = targets.pool.acquire(desc_of(lay.atlasW, lay.atlasH, fmt, "transmission-atlas"));
    bool ok = held[n] != 0;
    ++n;
    for (int k = 1; ok && k < lay.levels; ++k) {
        held[n] = targets.pool.acquire(desc_of(lay.level[k].w, lay.level[k].h, fmt, "transmission-level"));
        ok = held[n] != 0;
        ++n;
    }
    for (int i = 0; i < n; ++i)
        if (held[i]) targets.pool.release(held[i]);
    if (!ok) {
        if (failed_.size() >= kMaxShapes) failed_.erase(failed_.begin());
        failed_.push_back(key);
        if (!warnedTargets_) {
            warnedTargets_ = true;
            FA_ERROR("render",
                     "Transmission: cannot create the refraction images for a {}x{} camera; transmissive meshes are "
                     "blended plainly "
                     "without refraction. Hint: lower the render scale or the window size.",
                     w, h);
        }
        return false;
    }
    if (probed_.size() >= kMaxShapes) probed_.erase(probed_.begin());
    probed_.push_back(key);
    return true;
}

bool Xmit::build(TransientTargets& targets, Gpu& gpu, const Target& game, int x, int row, int w, int h,
                 XmitImages& out) {
    out = XmitImages{};
    const XmitLayout lay = xmit_layout(w, h);
    if (lay.levels < 1 || !ready() || !game.texView.id) return false;
    const sg_pixel_format fmt = gpu.scene_format();
    out.atlas = targets.pool.acquire(desc_of(lay.atlasW, lay.atlasH, fmt, "transmission-atlas"));
    bool ok = out.atlas != 0;
    for (int k = 1; ok && k < lay.levels; ++k) {
        out.reduced[k] = targets.pool.acquire(desc_of(lay.level[k].w, lay.level[k].h, fmt, "transmission-level"));
        ok = out.reduced[k] != 0;
    }
    const Target* atlas = ok ? targets.get(out.atlas) : nullptr;
    ok = ok && atlas && atlas->texView.id;
    const Target* red[kXmitMaxLevels]{};
    for (int k = 1; ok && k < lay.levels; ++k) {
        red[k] = targets.get(out.reduced[k]);
        ok = red[k] && red[k]->texView.id;
    }
    if (!ok) {
        finish(targets, out);
        return false;
    }
    // A format the GPU makes no copy pipeline for gives the whole copy up (the draws are then blended plainly).
    bool pipelinesOk = pipeline(pass_into(*atlas, "xmit-atlas").format).id != 0;
    for (int k = 1; pipelinesOk && k < lay.levels; ++k)
        pipelinesOk = pipeline(pass_into(*red[k], "xmit-reduce").format).id != 0;
    if (!pipelinesOk) {
        finish(targets, out);
        return false;
    }
    // The reductions: level k from level k-1 (level 1 from the picture's rectangle), each into its own image.
    for (int k = 1; k < lay.levels; ++k) {
        PassDesc pd = pass_into(*red[k], "xmit-reduce");
        pd.colorLoad = SG_LOADACTION_DONTCARE;  // every pixel is drawn
        pd.colorStore = SG_STOREACTION_STORE;
        Gpu::begin_pass(pd);
        sg_apply_pipeline(pipeline(pd.format));
        if (k == 1)
            draw_rect(gpu, game.texView, game.w, game.h, x, row, w, h, true, 0, 0, lay.level[1].w, lay.level[1].h);
        else
            draw_rect(gpu, red[k - 1]->texView, red[k - 1]->w, red[k - 1]->h, 0, 0, lay.level[k - 1].w,
                      lay.level[k - 1].h, true, 0, 0, lay.level[k].w, lay.level[k].h);
        Gpu::end_pass();
    }
    // The atlas: every level into its rectangle; what no level covers is black.
    PassDesc ap = pass_into(*atlas, "xmit-atlas");
    ap.colorLoad = SG_LOADACTION_CLEAR;
    ap.clearColor = {0.0f, 0.0f, 0.0f, 0.0f};
    ap.colorStore = SG_STOREACTION_STORE;
    Gpu::begin_pass(ap);
    sg_apply_pipeline(pipeline(ap.format));
    for (int k = 0; k < lay.levels; ++k) {
        const XmitLayout::Level& v = lay.level[k];
        if (k == 0)
            draw_rect(gpu, game.texView, game.w, game.h, x, row, w, h, false, v.x, v.y, v.w, v.h);
        else
            draw_rect(gpu, red[k]->texView, red[k]->w, red[k]->h, 0, 0, v.w, v.h, false, v.x, v.y, v.w, v.h);
    }
    Gpu::end_pass();
    out.atlasView = atlas->texView;
    out.levels = lay.levels;
    return true;
}

void Xmit::finish(TransientTargets& targets, XmitImages& images) {
    if (images.atlas) targets.pool.release(images.atlas);
    for (std::uint64_t& h : images.reduced)
        if (h) targets.pool.release(h);
    images = XmitImages{};
}

void Xmit::forget_targets() {
    failed_.clear();
    probed_.clear();
    warnedTargets_ = false;
}

void Xmit::release() {
    for (PipelineEntry& e : pipelines_)
        if (e.pipeline.id) sg_destroy_pipeline(e.pipeline);
    pipelines_.clear();
    if (shader_.id) sg_destroy_shader(shader_);
    shader_ = {};
    state_ = 0;
    failed_.clear();
    probed_.clear();
    warnedTargets_ = false;
}

}  // namespace fa::render
