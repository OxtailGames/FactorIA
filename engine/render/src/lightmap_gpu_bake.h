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

// How one atlas is cut into dispatches (counts only, never time). A dispatch traces `batch` texels for `sampleChunk` gather samples
// each, and the first dispatch of a batch also traces the direct light (lights x shadowSamples rays per texel): its work in "ray units"
// (`ray units` = one ray query and its shading) is at most kBakeDispatchWork whatever the lights and the shadow samples, so no dispatch
// comes near the 2 seconds after which Windows resets a GPU. `batch` is a multiple of 1024 (whole rows of the output image) from 1024 up
// and any count below that (one partial row), down to one texel. Fails (a teaching error, "bake on the CPU") when ONE texel needs more
// than the budget: so many lights times shadow samples that the direct light of a single texel cannot be one dispatch.
inline constexpr std::uint64_t kBakeDispatchWork = std::uint64_t(1) << 23;
inline constexpr std::uint32_t kBakeMaxBatchTexels = 16384;
struct BakeDispatchPlan {
    std::uint64_t batch = 0;        // texels per dispatch (>= 1)
    std::uint64_t sampleChunk = 0;  // gather samples per dispatch (>= 1)
};
Result<BakeDispatchPlan> plan_bake_dispatches(std::uint64_t texels, std::uint64_t lights, std::uint32_t shadowSamples,
                                              std::uint32_t bounces, std::uint32_t samples);

// The shader description of rt_bake for `backend` (an empty one when the kernel has no code for it).
gpu::ShaderDesc lightmap_bake_shader_desc(gpu::Backend backend);

}  // namespace fa::render
