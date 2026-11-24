#include "renderer_hdri.h"

#include <cstring>

#include "fa/core/log.h"

#include "shader_cache.h"
#include "gpu/sokol_shaders.h"
#include "shaders/hdri.glsl.h"

namespace fa::render {

bool HdriSky::ready(Gpu& gpu) {
    if (state_ != 0) return state_ > 0;
    gpu::Device& device = gpu.device();
    device_ = &device;
    gpu::SamplerDesc sd;
    sd.minFilter = gpu::Filter::Linear;
    sd.magFilter = gpu::Filter::Linear;
    sd.mipmapFilter = gpu::Filter::Linear;
    sd.wrapU = gpu::Wrap::Repeat;  // the panorama wraps around: no seam where atan jumps
    sd.wrapV = gpu::Wrap::ClampToEdge;
    sd.label = "hdri-sampler";
    shader_ = make_shader(device, gpu::generated_shader_desc(device, hdri_hdri_shader_desc), "hdri");
    sampler_ = device.make_sampler(sd);
    if (device.state(shader_) != gpu::ResourceState::Valid || device.state(sampler_) != gpu::ResourceState::Valid) {
        release();
        state_ = -1;
        FA_ERROR(
            "render",
            "SceneSettings.environmentMap cannot be drawn: the HDRI shader could not be made for this graphics backend "
            "(see the sokol log lines above). The scene keeps its sky material or gradient. Hint: update the graphics "
            "driver (Mesa: try LIBGL_ALWAYS_SOFTWARE=1).");
        return false;
    }
    state_ = 1;
    return true;
}

void HdriSky::draw(Gpu& gpu, const HdriAsset& hdri, float rotationDegrees, float gain, bool gamma,
                   const float* invViewProj, const float camPos[3], const TargetFormat* format) {
    if (state_ <= 0 || !hdri.view.id) return;
    gpu::CommandList& list = gpu.commands();  // the pass being drawn is open on it
    list.set_pipeline(format ? gpu.sky_pipeline(*format, shader_) : gpu.sky_pipeline(shader_));
    gpu::Bindings b;
    b.vertexBuffers[0] = gpu.fullscreen_triangle();
    b.views[VIEW_hdri_hdri_tex] = hdri.view;
    b.samplers[SMP_hdri_hdri_smp] = sampler_;
    list.set_bindings(b);
    hdri_hdri_vs_params_t vu{};
    std::memcpy(vu.inv_view_proj, invViewProj, sizeof(vu.inv_view_proj));
    for (int i = 0; i < 3; ++i) vu.cam_pos[i] = camPos[i];
    list.set_uniforms(UB_hdri_hdri_vs_params, gpu::Range{&vu, sizeof(vu)});
    hdri_hdri_fs_params_t fu{};
    fu.p[0] = rotationDegrees * 0.017453292519943295f;
    fu.p[1] = gain;
    fu.p[2] = gamma ? 1.0f : 0.0f;
    fu.p[3] = float(hdri.width);
    list.set_uniforms(UB_hdri_hdri_fs_params, gpu::Range{&fu, sizeof(fu)});
    list.draw(0, 3, 1);
}

void HdriSky::release() {
    if (device_) {
        if (shader_.id) device_->destroy_shader(shader_);
        if (sampler_.id) device_->destroy_sampler(sampler_);
    }
    shader_ = {};
    sampler_ = {};
    state_ = 0;
}

}  // namespace fa::render
