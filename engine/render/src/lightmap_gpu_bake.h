// Private to fa_render and its tests: a GPU lightmap tracer on a device the caller made (a RecordingDevice with ray tracing, say), and the
// shader description of the kernel (a test checks the contract). The public entry is fa/render/lightmap_gpu_bake.h.
#pragma once

#include <memory>

#include "fa/render/lightmap_gpu_bake.h"
#include "gpu/device.h"

namespace fa::render {

// The bindings of rt_bake (rt_bake.hlsl lists the registers): the view slots and the uniform block slot.
struct LightmapBakeBindings {
    static constexpr int kViewOut = 0;     // the storage image the kernel writes
    static constexpr int kViewScene = 1;   // the lights and the casters (storage buffer)
    static constexpr int kViewTexels = 2;  // the texels of the dispatch (storage buffer)
    static constexpr int kViewSky = 3;     // the pixels of the sky image (storage buffer)
    static constexpr int kUniformParams = 0;
};

// A tracer on `device` (which outlives it and is used on the calling thread only). Fails, saying why, when the device cannot trace rays or
// the kernel has no code for its backend.
Result<std::unique_ptr<LightmapGpuTracer>> make_lightmap_gpu_tracer_on(gpu::Device& device);

// The shader description of rt_bake for `backend` (an empty one when the kernel has no code for it).
gpu::ShaderDesc lightmap_bake_shader_desc(gpu::Backend backend);

}  // namespace fa::render
