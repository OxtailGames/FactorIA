// The input preparation of the MetalFX temporal scaler (shaders/upscale_mfx.glsl, M76-P5b): one fragment pass at the render resolution that
// turns the depth prepass and the velocity image into the 0..1 depth and the motion image MetalFX reads. Created on first use. Metal only
// (MetalFX is): on every other backend ready() says false and draws nothing. Private to fa_render; Renderer::Impl::metalfx_upscale draws with it.
#pragma once

#include <vector>

#include "gpu/device.h"
#include "gpu_types.h"

namespace fa::render {

class MetalFxPrep {
public:
    // Makes the program on the first call. False (and one logged error, once) when it does not compile; false without a message on a
    // backend that is not Metal.
    bool ready(gpu::Device& device);
    // The pipeline for a pass that writes `format` (colour 0 = the depth, colour 1 = the motion); invalid when not ready().
    gpu::Pipeline pipeline(const TargetFormat& format);
    // Destroys everything made; ready() makes it again.
    void release();

private:
    // Used on Metal only (the other backends build the stubs of the .cpp): marked so clang's -Wunused-private-field stays quiet there.
    [[maybe_unused]] gpu::Device* device_ = nullptr;  // the device of the first ready()
    [[maybe_unused]] gpu::Shader shader_{};
    [[maybe_unused]] int state_ = 0;  // 0 = not tried, 1 = ready, -1 = failed
    struct Entry {
        TargetFormat format;
        gpu::Pipeline pipeline;
    };
    [[maybe_unused]] std::vector<Entry> pipelines_;
};

}  // namespace fa::render
