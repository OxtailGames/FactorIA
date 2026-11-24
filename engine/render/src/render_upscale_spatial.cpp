#include "render_upscale_spatial.h"

#include <algorithm>

#include "fa/core/log.h"

#include "fullscreen_gpu.h"
#include "shader_cache.h"
#include "shaders/upscale_spatial.glsl.h"

namespace fa::render {

bool SpatialUpscaler::ready(gpu::Device& dev) {
    if (state_ != 0) return state_ > 0;
    device_ = &dev;
    shaders_[int(Prog::Edge)] =
        make_shader(dev, gpu::generated_shader_desc(upscale_spatial_spatial_edge_shader_desc), "upscale_spatial_edge");
    shaders_[int(Prog::Sharpen)] = make_shader(
        dev, gpu::generated_shader_desc(upscale_spatial_spatial_sharpen_shader_desc), "upscale_spatial_sharpen");
    bool ok = true;
    for (const gpu::Shader sh : shaders_) ok = ok && dev.state(sh) == gpu::ResourceState::Valid;
    if (!ok) {
        for (gpu::Shader& sh : shaders_) {
            if (sh.id) dev.destroy_shader(sh);
            sh = {};
        }
        state_ = -1;
        FA_ERROR(
            "render",
            "The spatial upscaler is unavailable: its shaders failed to compile for this graphics backend (see the "
            "sokol "
            "log lines above). The picture is scaled with the plain stretch instead. Hint: update the graphics driver "
            "(Mesa: try LIBGL_ALWAYS_SOFTWARE=1) or set render.upscaler mode to \"stretch\".");
        return false;
    }
    state_ = 1;
    return true;
}

gpu::Pipeline SpatialUpscaler::pipeline(Prog prog, const TargetFormat& format) {
    for (const Entry& e : pipelines_)
        if (e.prog == prog && e.format == format) return e.pipeline;
    if (state_ <= 0 || !device_) return {};
    const char* label = prog == Prog::Edge ? "upscale-spatial-edge" : "upscale-spatial-sharpen";
    // `pos`, location 0 in both programs.
    const gpu::Pipeline p = make_triangle_pipeline(*device_, shaders_[int(prog)], format, label);
    if (device_->state(p) != gpu::ResourceState::Valid) FA_ERROR("render", "failed to create pipeline '{}'", label);
    pipelines_.push_back({prog, format, p});
    return p;
}

void SpatialUpscaler::release() {
    if (device_) {
        for (Entry& e : pipelines_)
            if (e.pipeline.id) device_->destroy_pipeline(e.pipeline);
        for (gpu::Shader& sh : shaders_)
            if (sh.id) device_->destroy_shader(sh);
    }
    pipelines_.clear();
    for (gpu::Shader& sh : shaders_) sh = {};
    state_ = 0;
}

float SpatialUpscaler::sharpen_weight(float sharpness) { return std::clamp(sharpness, 0.0f, 1.0f) * 0.18f; }

}  // namespace fa::render
