#include "render_upscale_metalfx.h"

#include "fa/core/log.h"

#include "fullscreen_gpu.h"
#include "shader_cache.h"
#include "gpu/sokol_shaders.h"
#include "shaders/upscale_mfx.glsl.h"

namespace fa::render {

#if defined(SOKOL_METAL)

bool MetalFxPrep::ready(gpu::Device& dev) {
    if (state_ != 0) return state_ > 0;
    device_ = &dev;
    shader_ = make_shader(dev, gpu::generated_shader_desc(dev, upscale_mfx_mfx_shader_desc), "upscale_mfx");
    if (dev.state(shader_) != gpu::ResourceState::Valid) {
        if (shader_.id) dev.destroy_shader(shader_);
        shader_ = {};
        state_ = -1;
        FA_ERROR("render", "The MetalFX input preparation shader failed to compile (see the sokol log lines above); "
                           "MetalFX is not used, the "
                           "temporal TAA upscaler draws instead. Hint: set render.upscaler mode to \"temporal\".");
        return false;
    }
    state_ = 1;
    return true;
}

gpu::Pipeline MetalFxPrep::pipeline(const TargetFormat& format) {
    for (const Entry& e : pipelines_)
        if (e.format == format) return e.pipeline;
    if (state_ <= 0 || !device_) return {};
    // `pos`; two colour targets (the depth and the motion): make_triangle_pipeline takes both from `format`.
    const gpu::Pipeline p = make_triangle_pipeline(*device_, shader_, format, "upscale-metalfx-prep");
    if (device_->state(p) != gpu::ResourceState::Valid)
        FA_ERROR("render", "failed to create pipeline 'upscale-metalfx-prep'");
    pipelines_.push_back({format, p});
    return p;
}

void MetalFxPrep::release() {
    if (device_) {
        for (Entry& e : pipelines_)
            if (e.pipeline.id) device_->destroy_pipeline(e.pipeline);
        if (shader_.id) device_->destroy_shader(shader_);
    }
    pipelines_.clear();
    shader_ = {};
    state_ = 0;
    device_ = nullptr;
}

#else

bool MetalFxPrep::ready(gpu::Device&) { return false; }
gpu::Pipeline MetalFxPrep::pipeline(const TargetFormat&) { return {}; }
void MetalFxPrep::release() {}

#endif

}  // namespace fa::render
