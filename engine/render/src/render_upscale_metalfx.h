// The input preparation of the temporal scalers (shaders/upscale_mfx.glsl, M76-P5b, M78): one fragment pass at the render resolution that
// turns the depth prepass and the velocity image into the 0..1 depth and the motion image MetalFX and the vendor SDKs (XeSS...) read.
// Created on first use. Every backend has the shader. Private to
// fa_render; Renderer::run_upscale_prep draws with it.
#pragma once

#include <vector>

#include "gpu/device.h"
#include "gpu_types.h"

namespace fa::render {

class MetalFxPrep {
public:
    // Makes the program on the first call. False (and one logged error, once) when it does not compile; the shader is compiled for every
    // backend (on OpenGL the prep runs too, though no vendor SDK reads it there).
    bool ready(gpu::Device& device);
    // The pipeline for a pass that writes `format` (colour 0 = the depth, colour 1 = the motion); invalid when not ready().
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
