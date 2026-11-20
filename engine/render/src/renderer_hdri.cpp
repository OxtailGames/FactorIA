#include "renderer_hdri.h"

#include <cstring>

#include "fa/core/log.h"

#include "shader_cache.h"
#include "shaders/hdri.glsl.h"

namespace fa::render {

bool HdriSky::ready(Gpu&) {
    if (state_ != 0) return state_ > 0;
    sg_sampler_desc sd{};
    sd.min_filter = SG_FILTER_LINEAR;
    sd.mag_filter = SG_FILTER_LINEAR;
    sd.mipmap_filter = SG_FILTER_LINEAR;
    sd.wrap_u = SG_WRAP_REPEAT;  // the panorama wraps around: no seam where atan jumps
    sd.wrap_v = SG_WRAP_CLAMP_TO_EDGE;
    sd.label = "hdri-sampler";
    shader_ = make_shader(hdri_hdri_shader_desc(sg_query_backend()), "hdri");
    sampler_ = sg_make_sampler(&sd);
    if (sg_query_shader_state(shader_) != SG_RESOURCESTATE_VALID || sg_query_sampler_state(sampler_) != SG_RESOURCESTATE_VALID) {
        release();
        state_ = -1;
        FA_ERROR("render", "SceneSettings.environmentMap cannot be drawn: the HDRI shader could not be made for this graphics backend "
                           "(see the sokol log lines above). The scene keeps its sky material or gradient. Hint: update the graphics "
                           "driver (Mesa: try LIBGL_ALWAYS_SOFTWARE=1).");
        return false;
    }
    state_ = 1;
    return true;
}

void HdriSky::draw(Gpu& gpu, const HdriAsset& hdri, float rotationDegrees, float gain, bool gamma, const float* invViewProj,
                   const float camPos[3], const TargetFormat* format) {
    if (state_ <= 0 || !hdri.view.id) return;
    sg_apply_pipeline(format ? gpu.sky_pipeline(*format, shader_) : gpu.sky_pipeline(shader_));
    sg_bindings b{};
    b.vertex_buffers[0] = gpu.fullscreen_triangle();
    b.views[VIEW_hdri_hdri_tex] = hdri.view;
    b.samplers[SMP_hdri_hdri_smp] = sampler_;
    sg_apply_bindings(&b);
    hdri_hdri_vs_params_t vu{};
    std::memcpy(vu.inv_view_proj, invViewProj, sizeof(vu.inv_view_proj));
    for (int i = 0; i < 3; ++i) vu.cam_pos[i] = camPos[i];
    sg_range vr{&vu, sizeof(vu)};
    sg_apply_uniforms(UB_hdri_hdri_vs_params, &vr);
    hdri_hdri_fs_params_t fu{};
    fu.p[0] = rotationDegrees * 0.017453292519943295f;
    fu.p[1] = gain;
    fu.p[2] = gamma ? 1.0f : 0.0f;
    fu.p[3] = float(hdri.width);
    sg_range fr{&fu, sizeof(fu)};
    sg_apply_uniforms(UB_hdri_hdri_fs_params, &fr);
    sg_draw(0, 3, 1);
}

void HdriSky::release() {
    if (shader_.id) sg_destroy_shader(shader_);
    shader_ = {};
    if (sampler_.id) sg_destroy_sampler(sampler_);
    sampler_ = {};
    state_ = 0;
}

}  // namespace fa::render
