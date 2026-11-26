#include "render_upscale_rr.h"

#include "fa/core/log.h"

#include "fullscreen_gpu.h"
#include "shader_cache.h"
#include "gpu/sokol_shaders.h"
#include "shaders/upscale_rr.glsl.h"

namespace fa::render {

bool RrGuidesPrep::ready(gpu::Device& dev) {
    if (state_ != 0) return state_ > 0;
    device_ = &dev;
    shader_ = make_shader(dev, gpu::generated_shader_desc(dev, upscale_rr_rr_shader_desc), "upscale_rr");
    albedoShader_ =
        make_shader(dev, gpu::generated_shader_desc(dev, upscale_rr_rr_albedo_shader_desc), "upscale_rr_albedo");
    hitShader_ = make_shader(dev, gpu::generated_shader_desc(dev, upscale_rr_rr_hit_shader_desc), "upscale_rr_hit");
    if (dev.state(shader_) != gpu::ResourceState::Valid || dev.state(albedoShader_) != gpu::ResourceState::Valid ||
        dev.state(hitShader_) != gpu::ResourceState::Valid) {
        if (shader_.id) dev.destroy_shader(shader_);
        if (albedoShader_.id) dev.destroy_shader(albedoShader_);
        if (hitShader_.id) dev.destroy_shader(hitShader_);
        shader_ = {};
        albedoShader_ = {};
        hitShader_ = {};
        state_ = -1;
        FA_ERROR("render", "The DLSS Ray Reconstruction guides shader failed to compile (see the sokol log lines "
                           "above); DLSS draws with Super "
                           "Resolution instead. Hint: set render.upscaler rayReconstruction to false to silence this.");
        return false;
    }
    state_ = 1;
    return true;
}

gpu::Pipeline RrGuidesPrep::pipeline(const TargetFormat& format) {
    for (const Entry& e : pipelines_)
        if (e.format == format) return e.pipeline;
    if (state_ <= 0 || !device_) return {};
    // `pos`; two colour targets (the normal with the roughness, and the depth): make_triangle_pipeline takes both from `format`.
    const gpu::Pipeline p = make_triangle_pipeline(*device_, shader_, format, "upscale-rr-guides");
    if (device_->state(p) != gpu::ResourceState::Valid)
        FA_ERROR("render", "failed to create pipeline 'upscale-rr-guides'");
    pipelines_.push_back({format, p});
    return p;
}

gpu::Pipeline RrGuidesPrep::albedo_pipeline(const TargetFormat& format) {
    for (const Entry& e : albedoPipelines_)
        if (e.format == format) return e.pipeline;
    if (state_ <= 0 || !device_) return {};
    const gpu::Pipeline p = make_triangle_pipeline(*device_, albedoShader_, format, "upscale-rr-albedo");
    if (device_->state(p) != gpu::ResourceState::Valid)
        FA_ERROR("render", "failed to create pipeline 'upscale-rr-albedo'");
    albedoPipelines_.push_back({format, p});
    return p;
}

gpu::Pipeline RrGuidesPrep::hit_pipeline(const TargetFormat& format) {
    for (const Entry& e : hitPipelines_)
        if (e.format == format) return e.pipeline;
    if (state_ <= 0 || !device_) return {};
    const gpu::Pipeline p = make_triangle_pipeline(*device_, hitShader_, format, "upscale-rr-hit");
    if (device_->state(p) != gpu::ResourceState::Valid)
        FA_ERROR("render", "failed to create pipeline 'upscale-rr-hit'");
    hitPipelines_.push_back({format, p});
    return p;
}

void RrGuidesPrep::release() {
    if (device_) {
        for (Entry& e : pipelines_)
            if (e.pipeline.id) device_->destroy_pipeline(e.pipeline);
        for (Entry& e : albedoPipelines_)
            if (e.pipeline.id) device_->destroy_pipeline(e.pipeline);
        for (Entry& e : hitPipelines_)
            if (e.pipeline.id) device_->destroy_pipeline(e.pipeline);
        if (shader_.id) device_->destroy_shader(shader_);
        if (albedoShader_.id) device_->destroy_shader(albedoShader_);
        if (hitShader_.id) device_->destroy_shader(hitShader_);
    }
    pipelines_.clear();
    albedoPipelines_.clear();
    hitPipelines_.clear();
    shader_ = {};
    albedoShader_ = {};
    hitShader_ = {};
    state_ = 0;
    device_ = nullptr;
}

}  // namespace fa::render
