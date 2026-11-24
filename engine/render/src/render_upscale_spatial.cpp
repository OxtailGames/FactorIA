#include "render_upscale_spatial.h"

#include <algorithm>

#include "fa/core/log.h"

#include "shader_cache.h"
#include "shaders/upscale_spatial.glsl.h"

namespace fa::render {

bool SpatialUpscaler::ready() {
    if (state_ != 0) return state_ > 0;
    const sg_backend backend = sg_query_backend();
    shaders_[int(Prog::Edge)] = make_shader(upscale_spatial_spatial_edge_shader_desc(backend), "upscale_spatial_edge");
    shaders_[int(Prog::Sharpen)] =
        make_shader(upscale_spatial_spatial_sharpen_shader_desc(backend), "upscale_spatial_sharpen");
    bool ok = true;
    for (const sg_shader s : shaders_) ok = ok && sg_query_shader_state(s) == SG_RESOURCESTATE_VALID;
    if (!ok) {
        for (sg_shader& s : shaders_) {
            if (s.id) sg_destroy_shader(s);
            s = {};
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

sg_pipeline SpatialUpscaler::pipeline(Prog prog, const TargetFormat& format) {
    for (const Entry& e : pipelines_)
        if (e.prog == prog && e.format == format) return e.pipeline;
    if (state_ <= 0) return {};
    sg_pipeline_desc d{};
    d.shader = shaders_[int(prog)];
    d.layout.attrs[0].format = SG_VERTEXFORMAT_FLOAT2;  // `pos`, location 0 in both programs
    d.depth.compare = SG_COMPAREFUNC_ALWAYS;
    d.depth.write_enabled = false;
    d.depth.pixel_format = format.depth;
    d.colors[0].pixel_format = format.color;
    d.sample_count = format.samples;
    d.face_winding = SG_FACEWINDING_CCW;
    d.label = prog == Prog::Edge ? "upscale-spatial-edge" : "upscale-spatial-sharpen";
    const sg_pipeline p = sg_make_pipeline(&d);
    if (sg_query_pipeline_state(p) != SG_RESOURCESTATE_VALID)
        FA_ERROR("render", "failed to create pipeline '{}'", d.label);
    pipelines_.push_back({prog, format, p});
    return p;
}

void SpatialUpscaler::release() {
    for (Entry& e : pipelines_)
        if (e.pipeline.id) sg_destroy_pipeline(e.pipeline);
    pipelines_.clear();
    for (sg_shader& s : shaders_) {
        if (s.id) sg_destroy_shader(s);
        s = {};
    }
    state_ = 0;
}

float SpatialUpscaler::sharpen_weight(float sharpness) { return std::clamp(sharpness, 0.0f, 1.0f) * 0.18f; }

}  // namespace fa::render
