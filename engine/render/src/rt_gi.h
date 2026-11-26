// Private: the realtime GI probes updated by rays (M79-P4a, docs/design/ARCHITECTURE_RT_GI.md), the `gi probes` mode of render.rayTracing. One
// inline-ray-query compute kernel (rt_gi, rt_kernels.h) updates a bounded number of the probes of the RealtimeGI grids each frame: it traces
// a few dozen rays from each probe, shades what they hit (rt_hit.hlsli, plus the light the grid's own probes give at the hit: the multi-bounce)
// and writes the new estimate of each probe's block (the SH row, the depth map, the meta texel of gi.h) into an RGBA16F image the size of the
// atlas's band, with the weight of the temporal hysteresis in alpha. The renderer then blends that image into the atlas with one draw a probe
// (ProbeGpu::blit_gi), so the lit shader reads the grids exactly as it does when the raster captures fill them.
//
// This file holds what the kernel and its pass need: the constants block, the CPU twin of the kernel's ray set (the tests trace the same rays),
// the pass and the band image. What decides WHICH probes are updated (gi_pick, the grids, the budget) is renderer_gi.cpp.
#pragma once

#include <cstdint>
#include <memory>
#include <mutex>
#include <string>
#include <string_view>
#include <vector>

#include "fa/core/math.h"
#include "frame_graph.h"
#include "gpu/device.h"
#include "render_internal.h"
#include "rt_effect.h"

namespace fa::render {

class RtScene;

// The most probes one dispatch updates (the constants block holds one float4 for each); a frame's budget, all grids together, is
// kGiRtMaxFrameProbes and equal to it.
inline constexpr int kRtGiMaxJobs = 64;
inline constexpr int kGiRtMaxFrameProbes = kRtGiMaxJobs;
// RealtimeGI.raysPerProbe: the default and the limits of the component (a value outside is clamped when the grid is laid out).
inline constexpr int kGiRtDefaultRays = 64, kGiRtMinRays = 16, kGiRtMaxRays = 256;
// RealtimeGI.rtProbesPerFrame: the probes of the grid updated in a frame by rays.
inline constexpr int kGiRtDefaultProbesPerFrame = 16, kGiRtMinProbesPerFrame = 1;

// The constants block of the kernel at uniform slot RtEffectBindings::kUniformParams: 70 float4, 1120 bytes, the same struct as rt_gi.hlsl and
// rt_gi.metal between the lines `// BEGIN RtGiParams` and `// END RtGiParams` (a test compares the field names with these).
struct RtGiParams {
    float grid0[4];  // xyz: the origin of probe (0, 0, 0); w: the spacing
    float grid1[4];  // x, y, z: the probe counts per axis; w: their product
    float grid2[4];  // x: the grid's first block; y: the blocks per band row (kGiBlocksPerRow); z: maxDistance; w: intensity
    float grid3[4];  // x: bounce; y: backfaceTolerance; z: 1 when the kernel adds the grid's own light at a hit; w: the rays' start (nearPlane)
    std::uint32_t frame[4];  // x: the gi frame; y: the seed of the frame; z: rays per probe; w: probes in this dispatch (<= kRtGiMaxJobs)
    float flags[4];  // x: +1 when the hardware's front face is the mesh's front face, -1 when it is the back face; yzw: 0
    // per probe: x: its index in the grid; y: the blend weight (1 replaces the block); z, w: the block's first texel in the band image
    float probe[kRtGiMaxJobs][4];
};
static_assert(sizeof(RtGiParams) == (6 + kRtGiMaxJobs) * 16, "RtGiParams is 70 float4 (the HLSL and MSL structs say the same)");
inline constexpr std::string_view kRtGiParamNames[] = {"grid0", "grid1", "grid2", "grid3", "frame", "flags", "probe"};

// What the kernel's `flags.x` holds: +1 when the hardware's front-face flag of a hit is set for a triangle that faces the ray's origin with
// the mesh's own (counter-clockwise) winding, -1 when it is the other way round. MEASURED on Metal (rt_gi_metal_tests.cpp: a probe in the
// open reads no back faces, one inside a box reads them) where the flag is set for the counter-clockwise side: +1. D3D12 and Vulkan are
// NOT measured here: their documented default is "clockwise as seen from the ray origin", so -1. A wrong sign only counts the front faces
// as back faces (the probe's backFrac, which the lit shader uses to discard probes inside walls), it cannot crash.
inline constexpr float rt_gi_front_sense(gpu::Backend backend) { return backend == gpu::Backend::Metal ? 1.0f : -1.0f; }

// ---- the kernel's ray set, on the CPU (the tests trace the same rays; the arithmetic is the kernel's, up to the GPU's sin, cos and pow) ----------
std::uint32_t rt_gi_pcg(std::uint32_t v);
// The unit quaternion (x, y, z, w) that rotates the probe's ray set in the update with this seed: the same for the same seed and probe.
void rt_gi_rotation(std::uint32_t seed, std::uint32_t probe, float q[4]);
// Ray `i` of `n` of the spherical Fibonacci set, before the rotation, then rotated by `q`.
Vec3 rt_gi_fibonacci(std::uint32_t i, std::uint32_t n);
Vec3 rt_gi_rotate(const float q[4], Vec3 v);
Vec3 rt_gi_direction(const float q[4], std::uint32_t i, std::uint32_t n);

// One grid's share of a frame: the constants of one dispatch.
struct RtGiDispatch {
    RtGiParams params{};
};

// The ShaderDesc of the kernel is rt_effect_shader_desc with the "rt_gi" row of the spec table (rt_effect.cpp).

// What one frame asks the kernel to do.
struct RtGiRequest {
    std::string pass;  // the pass's name (`gi-probes`)
    std::string after;       // the pass that builds the TLAS (`<job>/rt-accel`)
    gpu::View atlas{};       // the probe atlas, as a texture the kernel reads (the multi-bounce)
    std::vector<RtGiDispatch> dispatches;
    RtHitParams hit{};
    RtScene* scene = nullptr;
    std::uint64_t frameSerial = 0;
    int* drawCalls = nullptr;
};

// The image the kernel writes: the band of the atlas (kProbeAtlasSize x kGiBandHeight), RGBA16F.
struct RtGiImage {
    gpu::Image image{};
    gpu::View storage{};  // what the kernel writes through
    gpu::View texture{};  // what the blit into the atlas samples
    bool ran = false;     // the pass ran this frame (it does not when the scene has no TLAS yet or the driver refused the pipeline)
    std::uint64_t lastUsed = 0;
};

class RtGiProbes {
public:
    RtGiProbes() = default;
    RtGiProbes(const RtGiProbes&) = delete;
    RtGiProbes& operator=(const RtGiProbes&) = delete;

    // Declares the pass in `graph` (after req.after), making the kernel and the band image on the first call. false, with `why`: the device
    // has no code for the kernel or refused it, cannot write RGBA16F from a compute shader, or the request is incomplete.
    bool add_pass(FrameGraph& graph, Gpu& gpu, const RtGiRequest& req, std::string* why);
    // The band image of the pass of this frame; its `ran` says whether the kernel wrote it (valid after run_frame_graph).
    const RtGiImage* image() const { return image_.get(); }
    // Frees the image and the kernel no frame used since `serial - 2`.
    void sweep(Gpu& gpu, std::uint64_t serial);
    void release(Gpu& gpu);
    // Why the pass did not run when its turn came (the driver refused the pipeline): empty while it runs.
    std::string failure() const;
    bool empty() const { return !image_ && state_ == 0 && !recordsView_.id; }

private:
    gpu::View records_view(Gpu& gpu, gpu::Buffer records);
    void note_failure(const std::string& why);
    void free_resources(Gpu& gpu);
    gpu::Shader shader_{};
    int state_ = 0;  // 0 not made, 1 made, -1 refused (kept, so it is not tried again)
    std::string why_;
    std::unique_ptr<RtGiImage> image_;
    gpu::Buffer recordsBuffer_{};
    gpu::View recordsView_{};
    mutable std::mutex failureMutex_;
    std::string failure_;
    bool warned_ = false;
};

}  // namespace fa::render
