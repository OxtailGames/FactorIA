// The guides of DLSS Ray Reconstruction (shaders/upscale_rr.glsl, M78-P4c): one fragment pass at the render resolution that turns the depth
// prepass into the world-space normal with a roughness (colour 0) and a diffuse albedo (colour 1). Created on first use, only when the setting
// asks for Ray Reconstruction. Every backend has the shader. Private to fa_render; Renderer::run_rr_guides draws with it.
#pragma once

#include <vector>

#include "gpu/device.h"
#include "gpu_types.h"

namespace fa::render {

class RrGuidesPrep {
public:
    // Makes the program on the first call. False (and one logged error, once) when it does not compile.
    bool ready(gpu::Device& device);
    // The pipeline for a pass that writes `format` (colour 0 = normal and roughness, colour 1 = diffuse albedo); invalid when not ready().
    gpu::Pipeline pipeline(const TargetFormat& format);
    // Destroys everything made; ready() makes it again.
    void release();

private:
    gpu::Device* device_ = nullptr;  // the device of the first ready()
    gpu::Shader shader_{};
    int state_ = 0;  // 0 = not tried, 1 = ready, -1 = failed
    struct Entry {
        TargetFormat format;
        gpu::Pipeline pipeline;
    };
    std::vector<Entry> pipelines_;
};

}  // namespace fa::render
