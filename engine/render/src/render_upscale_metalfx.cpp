#include "render_upscale_metalfx.h"

#include "fa/core/log.h"

#include "shader_cache.h"
#include "shaders/upscale_mfx.glsl.h"

namespace fa::render {

#if defined(SOKOL_METAL)

bool MetalFxPrep::ready() {
    if (state_ != 0) return state_ > 0;
    shader_ = make_shader(upscale_mfx_mfx_shader_desc(sg_query_backend()), "upscale_mfx");
    if (sg_query_shader_state(shader_) != SG_RESOURCESTATE_VALID) {
        if (shader_.id) sg_destroy_shader(shader_);
        shader_ = {};
        state_ = -1;
        FA_ERROR("render",
                 "The MetalFX input preparation shader failed to compile (see the sokol log lines above); MetalFX is not used, the "
                 "temporal TAA upscaler draws instead. Hint: set render.upscaler mode to \"temporal\".");
        return false;
    }
    state_ = 1;
    return true;
}

sg_pipeline MetalFxPrep::pipeline(const TargetFormat& format) {
    for (const Entry& e : pipelines_)
        if (e.format == format) return e.pipeline;
    if (state_ <= 0) return {};
    sg_pipeline_desc d{};
    d.shader = shader_;
    d.layout.attrs[0].format = SG_VERTEXFORMAT_FLOAT2;  // `pos`
    d.depth.compare = SG_COMPAREFUNC_ALWAYS;
    d.depth.write_enabled = false;
    d.depth.pixel_format = format.depth;
    d.color_count = 2;
    d.colors[0].pixel_format = format.color;
    d.colors[1].pixel_format = format.color1;
    d.sample_count = format.samples;
    d.face_winding = SG_FACEWINDING_CCW;
    d.label = "upscale-metalfx-prep";
    const sg_pipeline p = sg_make_pipeline(&d);
    if (sg_query_pipeline_state(p) != SG_RESOURCESTATE_VALID) FA_ERROR("render", "failed to create pipeline '{}'", d.label);
    pipelines_.push_back({format, p});
    return p;
}

void MetalFxPrep::release() {
    for (Entry& e : pipelines_)
        if (e.pipeline.id) sg_destroy_pipeline(e.pipeline);
    pipelines_.clear();
    if (shader_.id) sg_destroy_shader(shader_);
    shader_ = {};
    state_ = 0;
}

#else

bool MetalFxPrep::ready() { return false; }
sg_pipeline MetalFxPrep::pipeline(const TargetFormat&) { return {}; }
void MetalFxPrep::release() {}

#endif

}  // namespace fa::render
