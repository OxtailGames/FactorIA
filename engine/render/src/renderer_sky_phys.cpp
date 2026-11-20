#include "renderer_sky_phys.h"

#include <cstring>

#include "fa/core/log.h"

#include "shader_cache.h"
#include "shaders/sky_physical.glsl.h"

namespace fa::render {

namespace {

bool usable(sg_pixel_format f) {
    const sg_pixelformat_info i = sg_query_pixelformat(f);
    return i.sample && i.filter && i.render;
}
bool valid(sg_image i) { return i.id && sg_query_image_state(i) == SG_RESOURCESTATE_VALID; }
bool valid(sg_view v) { return v.id && sg_query_view_state(v) == SG_RESOURCESTATE_VALID; }

sg_image make_table(int w, int h, sg_pixel_format format, const char* label) {
    sg_image_desc d{};
    d.usage.color_attachment = true;
    d.width = w;
    d.height = h;
    d.pixel_format = format;
    d.label = label;
    return make_image(d);
}
sg_view texture_view(sg_image image, const char* label) {
    sg_view_desc v{};
    v.texture.image = image;
    v.label = label;
    return sg_make_view(&v);
}
sg_view attachment_view(sg_image image, const char* label) {
    sg_view_desc v{};
    v.color_attachment.image = image;
    v.label = label;
    return sg_make_view(&v);
}
void destroy(sg_view& v) {
    if (v.id) sg_destroy_view(v);
    v = {};
}
void destroy(sg_image& i) {
    if (i.id) sg_destroy_image(i);
    i = {};
}

}  // namespace

bool PhysicalSky::ready(Gpu&) {
    if (state_ != 0) return state_ > 0;
    // The tables hold optical depths (up to about 20) and radiances: they need a float format that renders and filters.
    format_ = usable(SG_PIXELFORMAT_RGBA16F) ? SG_PIXELFORMAT_RGBA16F : SG_PIXELFORMAT_NONE;
    bool ok = format_ != SG_PIXELFORMAT_NONE;
    if (ok) {
        const sg_backend backend = sg_query_backend();
        shaders_[Transmittance] = make_shader(skyphys_transmittance_shader_desc(backend), "sky_transmittance");
        shaders_[MultiScatter] = make_shader(skyphys_multiscatter_shader_desc(backend), "sky_multiscatter");
        shaders_[SkyView] = make_shader(skyphys_skyview_shader_desc(backend), "sky_view");
        shaders_[Sky] = make_shader(skyphys_sky_shader_desc(backend), "sky_physical");
        for (sg_shader s : shaders_) ok = ok && sg_query_shader_state(s) == SG_RESOURCESTATE_VALID;
    }
    if (ok) {
        sg_sampler_desc sd{};
        sd.min_filter = SG_FILTER_LINEAR;
        sd.mag_filter = SG_FILTER_LINEAR;
        sd.mipmap_filter = SG_FILTER_NEAREST;
        sd.wrap_u = sd.wrap_v = SG_WRAP_CLAMP_TO_EDGE;
        sd.label = "sky-tables";
        sampler_ = sg_make_sampler(&sd);
        trImage_ = make_table(kSkyTransmittanceW, kSkyTransmittanceH, format_, "sky-transmittance");
        msImage_ = make_table(kSkyMultiScatterSize, kSkyMultiScatterSize, format_, "sky-multiscatter");
        view_[0] = make_table(kSkyViewW, kSkyViewH, format_, "sky-view");
        view_[1] = make_table(kSkyViewW, kSkyViewH, format_, "sky-view-env");
        ok = ok && valid(trImage_) && valid(msImage_) && valid(view_[0]) && valid(view_[1]);
        if (ok) {
            trTex_ = texture_view(trImage_, "sky-transmittance");
            trAtt_ = attachment_view(trImage_, "sky-transmittance");
            msTex_ = texture_view(msImage_, "sky-multiscatter");
            msAtt_ = attachment_view(msImage_, "sky-multiscatter");
            for (int i = 0; i < 2; ++i) {
                viewTex_[i] = texture_view(view_[i], "sky-view");
                viewAtt_[i] = attachment_view(view_[i], "sky-view");
                ok = ok && valid(viewTex_[i]) && valid(viewAtt_[i]);
            }
            ok = ok && valid(trTex_) && valid(trAtt_) && valid(msTex_) && valid(msAtt_);
        }
    }
    if (ok) {
        for (int p = 0; p < Sky; ++p) {
            sg_pipeline_desc d{};
            d.shader = shaders_[p];
            d.layout.attrs[0].format = SG_VERTEXFORMAT_FLOAT2;  // `pos`, location 0 in every program
            d.depth.compare = SG_COMPAREFUNC_ALWAYS;
            d.depth.write_enabled = false;
            d.depth.pixel_format = SG_PIXELFORMAT_NONE;
            d.colors[0].pixel_format = format_;
            d.sample_count = 1;
            d.face_winding = SG_FACEWINDING_CCW;
            d.label = p == Transmittance ? "sky-transmittance" : p == MultiScatter ? "sky-multiscatter" : "sky-view";
            lutPipelines_[p] = sg_make_pipeline(&d);
            ok = ok && sg_query_pipeline_state(lutPipelines_[p]) == SG_RESOURCESTATE_VALID;
        }
    }
    if (!ok) {
        release();
        state_ = -1;
        FA_ERROR("render", "SceneSettings.skyModel \"physical\" is not available on this graphics backend: the sky tables "
                           "(RGBA16F render targets that filter) or their shaders could not be made (see the sokol log lines "
                           "above), so the gradient sky is drawn. Hint: render.supports {{\"feature\": \"physicalSky\"}} tells "
                           "a script before it sets the model; update the graphics driver (Mesa: try LIBGL_ALWAYS_SOFTWARE=1).");
        return false;
    }
    state_ = 1;
    return true;
}

void PhysicalSky::pass(Gpu& gpu, Prog prog, sg_view target, const char* label, const PhysicalSkyState& st, int* drawCalls) {
    PassDesc pd;
    pd.label = label;
    pd.color = target;
    pd.format = TargetFormat{format_, SG_PIXELFORMAT_NONE, 1};
    pd.colorLoad = SG_LOADACTION_DONTCARE;  // every texel is drawn
    pd.colorStore = SG_STOREACTION_STORE;
    Gpu::begin_pass(pd);
    sg_apply_pipeline(lutPipelines_[prog]);
    sg_bindings b{};
    b.vertex_buffers[0] = gpu.fullscreen_triangle();
    b.samplers[SMP_skyphys_sky_smp] = sampler_;
    if (prog == MultiScatter) {
        b.views[VIEW_skyphys_sky_tr_tex] = trTex_;
    } else if (prog == SkyView) {
        b.views[VIEW_skyphys_sky_tr_tex] = trTex_;
        b.views[VIEW_skyphys_sky_ms_tex] = msTex_;
    }
    sg_apply_bindings(&b);
    skyphys_sky_params_t fu{};
    const SkyShaderParams p = sky_shader_params(st, false);
    static_assert(sizeof(fu.q) == sizeof(p.v), "the shader's block and the CPU's packing are the same size");
    std::memcpy(fu.q, p.v, sizeof(fu.q));
    sg_range r{&fu, sizeof(fu)};
    sg_apply_uniforms(UB_skyphys_sky_params, &r);
    sg_draw(0, 3, 1);
    Gpu::end_pass();
    if (drawCalls) ++*drawCalls;
}

void PhysicalSky::update_air(Gpu& gpu, const PhysicalSkyState& st, int* drawCalls) {
    const std::uint64_t key = sky_air_key(st.s);
    if (airDrawn_ && airKey_ == key) return;
    pass(gpu, Transmittance, trAtt_, "sky-transmittance", st, drawCalls);
    pass(gpu, MultiScatter, msAtt_, "sky-multiscatter", st, drawCalls);
    airKey_ = key;
    airDrawn_ = true;
    ++airBuilds_;
    viewDrawn_[0] = viewDrawn_[1] = false;  // the views were drawn from the old air
}

void PhysicalSky::update(Gpu& gpu, int slot, const PhysicalSkyState& st, int* drawCalls) {
    if (state_ <= 0) return;
    slot &= 1;
    update_air(gpu, st, drawCalls);
    const std::uint64_t key = sky_view_key(st.s, st.sunDir[1]);
    if (viewDrawn_[slot] && viewKey_[slot] == key) return;
    pass(gpu, SkyView, viewAtt_[slot], slot ? "sky-view-env" : "sky-view", st, drawCalls);
    viewKey_[slot] = key;
    viewDrawn_[slot] = true;
    ++viewBuilds_[slot];
}

void PhysicalSky::draw(Gpu& gpu, int slot, const PhysicalSkyState& st, bool sunDisc, const float* invViewProj,
                       const float camPos[3], const TargetFormat* format) {
    if (state_ <= 0) return;
    slot &= 1;
    sg_apply_pipeline(format ? gpu.sky_pipeline(*format, shaders_[Sky]) : gpu.sky_pipeline(shaders_[Sky]));
    sg_bindings b{};
    b.vertex_buffers[0] = gpu.fullscreen_triangle();
    b.views[VIEW_skyphys_sky_tr_tex] = trTex_;
    b.views[VIEW_skyphys_sky_ms_tex] = msTex_;
    b.views[VIEW_skyphys_sky_sv_tex] = viewTex_[slot];
    b.samplers[SMP_skyphys_sky_smp] = sampler_;
    sg_apply_bindings(&b);
    skyphys_sky_vs_params_t vu{};
    std::memcpy(vu.inv_view_proj, invViewProj, sizeof(vu.inv_view_proj));
    for (int i = 0; i < 3; ++i) vu.cam_pos[i] = camPos[i];
    sg_range vr{&vu, sizeof(vu)};
    sg_apply_uniforms(UB_skyphys_sky_vs_params, &vr);
    skyphys_sky_params_t fu{};
    const SkyShaderParams p = sky_shader_params(st, sunDisc);
    std::memcpy(fu.q, p.v, sizeof(fu.q));
    sg_range fr{&fu, sizeof(fu)};
    sg_apply_uniforms(UB_skyphys_sky_params, &fr);
    sg_draw(0, 3, 1);
}

void PhysicalSky::release() {
    for (sg_pipeline& p : lutPipelines_) {
        if (p.id) sg_destroy_pipeline(p);
        p = {};
    }
    for (sg_shader& s : shaders_) {
        if (s.id) sg_destroy_shader(s);
        s = {};
    }
    destroy(trAtt_);
    destroy(trTex_);
    destroy(trImage_);
    destroy(msAtt_);
    destroy(msTex_);
    destroy(msImage_);
    for (int i = 0; i < 2; ++i) {
        destroy(viewAtt_[i]);
        destroy(viewTex_[i]);
        destroy(view_[i]);
        viewDrawn_[i] = false;
    }
    if (sampler_.id) sg_destroy_sampler(sampler_);
    sampler_ = {};
    airDrawn_ = false;
    state_ = 0;
}

}  // namespace fa::render
