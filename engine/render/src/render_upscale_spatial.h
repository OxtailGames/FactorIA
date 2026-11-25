// The spatial upscaler's shaders and pipelines (shaders/upscale_spatial.glsl, M76-P3b): the edge-adaptive upsample and the
// contrast-adaptive sharpen. Created on first use, like the bloom and colour filter programs, so a game that never turns the mode on
// compiles nothing. Private to fa_render; Renderer::Impl::spatial_upscale draws with it.
#pragma once

#include <vector>

#include "gpu/device.h"
#include "gpu_types.h"

namespace fa::render {

class SpatialUpscaler {
public:
    enum class Prog : int { Edge, Sharpen };

    // Makes the two programs on the first call. False (and one logged error, once) when this backend cannot compile them.
    bool ready(gpu::Device& device);
    // The pipeline of `prog` for a pass that writes `format`; an invalid one when not ready().
    gpu::Pipeline pipeline(Prog prog, const TargetFormat& format);
    // Destroys everything made; ready() makes it again.
    void release();

    // The strongest negative weight of the sharpen for a sharpness setting 0..1 (0 = the pass is a copy).
    static float sharpen_weight(float sharpness);

private:
    gpu::Device* device_ = nullptr;  // the device of the first ready(): everything is made and destroyed on it
    gpu::Shader shaders_[2]{};
    int state_ = 0;  // 0 = not tried, 1 = ready, -1 = failed
    struct Entry {
        Prog prog;
        TargetFormat format;
        gpu::Pipeline pipeline;
    };
    std::vector<Entry> pipelines_;
};

}  // namespace fa::render
