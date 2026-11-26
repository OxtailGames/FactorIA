// The guides of DLSS Ray Reconstruction (shaders/upscale_rr.glsl, M78-P4c): one fragment pass at the render resolution that turns the depth
// prepass into the world-space normal with a roughness (colour 0) and the hardware depth of the camera's projection (colour 1), and, since M79-P0c,
// a second one that turns the thin G-buffer's albedo and metalness into the diffuse albedo (colour 0) and the specular albedo (colour 1). Created
// on first use, only when the setting asks for Ray Reconstruction. Every backend has the shaders. Private to fa_render; Renderer::run_rr_guides
// draws with it.
#pragma once

#include <vector>

#include "fa/core/math.h"
#include "gpu/device.h"
#include "gpu_types.h"

namespace fa::render {

// The depth terms of a projection that the guides shader (rr_params.zrow) turns a view distance into the hardware depth with: P22, P23, P32
// and P33 (column-major, m[column * 4 + row]); clip z = P22 * z + P23 and clip w = P32 * z + P33 for a view-space z.
inline void rr_depth_terms(const Mat4& proj, float out[4]) {
    out[0] = proj.m[10];
    out[1] = proj.m[14];
    out[2] = proj.m[11];
    out[3] = proj.m[15];
}
// What the shader writes for a surface `distance` in front of the camera (the prepass's linear view depth): clip z / clip w, 1 for the sky
// (`drawn` false) and where the clip w is zero. Kept next to the shader's formula; the tests compare it with the projection's own product.
inline float rr_hardware_depth(const float terms[4], float distance, bool drawn) {
    const float z = -distance;
    const float w = terms[2] * z + terms[3];
    if (!drawn || (w < 1e-12f && w > -1e-12f)) return 1.0f;
    return (terms[0] * z + terms[1]) / w;
}

class RrGuidesPrep {
public:
    // Makes the program on the first call. False (and one logged error, once) when it does not compile.
    bool ready(gpu::Device& device);
    // The pipeline for a pass that writes `format` (colour 0 = normal and roughness, colour 1 = the hardware depth); invalid when not ready().
    gpu::Pipeline pipeline(const TargetFormat& format);
    // The same for the albedo pass (rr_albedo: colour 0 = the diffuse albedo, colour 1 = the specular albedo).
    gpu::Pipeline albedo_pipeline(const TargetFormat& format);
    // Destroys everything made; ready() makes it again.
    void release();

private:
    gpu::Device* device_ = nullptr;  // the device of the first ready()
    gpu::Shader shader_{}, albedoShader_{};
    int state_ = 0;  // 0 = not tried, 1 = ready, -1 = failed
    struct Entry {
        TargetFormat format;
        gpu::Pipeline pipeline;
    };
    std::vector<Entry> pipelines_, albedoPipelines_;
};

}  // namespace fa::render
