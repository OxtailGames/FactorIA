// The GPU lightmap bake (M79, docs/design/ARCHITECTURE_BAKING.md "The GPU bake"): the path tracer of the CPU baker
// (fa/scene/lightmap_bake.h) as a compute kernel with inline ray queries, a FAST PREVIEW next to the CPU baker, which stays the bit-exact
// reference. A LightmapGpuTracer is a BakeTexelTracer: bake_lightmap(scene, settings, progress, &tracer) lets it trace the texels and does the
// rest (the atlases, the denoise, the gutter, the budgets, the progress and the cancel) as ever.
//
// The tracer builds an acceleration structure of the bake's OWN scene (the triangles that cast a shadow, not the renderer's), runs the kernel
// engine/render/shaders/rt/rt_bake.{hlsl,metal} in batches whose size depends on the counts only, and reads the sums back. It draws the same
// random numbers as the CPU (the same integer hash, the same sample sequences), so the image is the CPU's up to float rounding: the maths
// uses the GPU's sin, cos and ray-triangle test, and a path whose rounding flips (a Russian roulette draw at the threshold) differs. The
// result is repeatable on one GPU and driver, and can differ in the last bits on another.
//
// The device: Windows D3D12, then Vulkan; Linux and Android Vulkan; macOS Metal (the sokol context; a Mac process that already has a window or
// game context cannot lend it to a bake thread, so there the tracer says so (open_needs_helper_process) and the caller runs the bake in a
// helper process that has none, or on the CPU).
#pragma once

#include <memory>
#include <string>

#include "fa/core/types.h"
#include "fa/scene/lightmap_bake.h"

namespace fa::render {

class LightmapGpuTracer : public BakeTexelTracer {
public:
    struct Impl;
    explicit LightmapGpuTracer(std::unique_ptr<Impl> impl);
    ~LightmapGpuTracer() override;
    LightmapGpuTracer(const LightmapGpuTracer&) = delete;
    LightmapGpuTracer& operator=(const LightmapGpuTracer&) = delete;

    // Opens a GPU that traces rays (a few hundred milliseconds). Create, use and destroy the tracer on ONE thread. The error says why no device
    // can ("D3D12: ...; Vulkan: ...") and the hint what to do: the caller falls back to the CPU baker with it.
    // `allowSoftware` false skips a device that is a CPU rasteriser (WARP, llvmpipe, lavapipe): the "auto" choice of the bake command, which
    // must not run a software ray tracer in place of the CPU baker; `gpu` passes true.
    static Result<std::unique_ptr<LightmapGpuTracer>> open(bool allowSoftware = true);

    // True when open() cannot work in THIS process but a helper process without graphics could: a Mac process that already has a graphics
    // context (the editor, a game, an engine with graphics) cannot give a bake thread the sokol singleton nor open a second one. The caller
    // (the bake job, fa_authoring) then runs the bake in a child `factoria` and gets the same result. False everywhere the devices
    // are independent of the window (D3D12, Vulkan) and in a process with no context. Cheap, any thread.
    static bool open_needs_helper_process();

    // "Metal (Apple)", "D3D12 (NVIDIA)": what the bake ran on.
    const std::string& device_name() const;
    // How many dispatches the tracer ran so far (a test and the logs look at it).
    std::uint64_t dispatches() const;

    Result<void> begin(const BakeTraceScene& scene) override;
    Result<void> trace_atlas(std::uint64_t atlasKey, const std::vector<BakeTraceTexel>& texels,
                             const BakeTraceProgressFn& progress, std::vector<float>& rgb) override;

private:
    std::unique_ptr<Impl> impl_;
};

}  // namespace fa::render
