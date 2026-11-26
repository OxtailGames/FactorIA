// Private: the shared pass of the ray traced effects (M79-P2a-1; docs/design/ARCHITECTURE_RT_EFFECTS.md). Hard shadows are the first effect on it,
// the ambient occlusion (P2b), the reflections (P3a) and the translucency (P3b) are the next: each is one inline-ray-query compute kernel of the
// rt kernel table (rt_kernels.h) that reads the camera's prepass and writes one image, and the scaffold below does the rest the same way for all:
//
//   * one compute pass in the frame graph, declared after the scene's `rt-accel` pass (the TLAS is built before it traces) and after the camera's
//     prepass (and G-buffer, when the kernel asks for it);
//   * the bindings every kernel shares (the fixed contract of RtEffectBindings below): the TLAS, the output image, the constants block
//     (RtEffectParams: the camera as rays, the frame serial, the seed, the rays per pixel), the prepass, optionally the record buffer of the scene
//     and the G-buffer's two images;
//   * the output image (one per effect and camera, RGBA32F, the size of the prepass), made on the first frame the effect runs and freed when it
//     stops (sweep) or ray tracing goes off (release); the kernel's shader and pipeline likewise.
//
// What is free when nothing asks: no shader, no pipeline, no image and no pass exist until `add_pass` is called, which the renderer does only for
// an effect that is on, on a device that traces, in the job that collected the scene. A device that cannot trace never gets here (the renderer
// says so once in rt_begin_frame and draws the raster frame).
#pragma once

#include <cstdint>
#include <map>
#include <memory>
#include <string>
#include <string_view>
#include <vector>

#include "fa/core/math.h"
#include "fa/scene/camera_geometry.h"

#include "frame_graph.h"
#include "gpu/device.h"
#include "postprocess.h"
#include "render_internal.h"
#include "rt_kernels.h"
#include "transient_targets.h"

namespace fa::render {

class RtScene;

// The constants block of every effect kernel: 25 float4, 400 bytes, the same struct in rt_*.hlsl and rt_*.metal between the lines `// BEGIN
// RtEffectParams` and `// END RtEffectParams` (a test compares the field names with these). A kernel reads the fields it needs.
struct RtEffectParams {
    float camera[4];         // xyz: the camera's position (the renderer's space); w: 1 for an orthographic camera
    float lightDir[4];       // xyz: the unit vector from a surface toward the light (the sun's); w: 0
    float image[4];          // xy: the size of the output image in pixels; zw: 1 / size
    std::uint32_t frame[4];  // x: the frame serial; y: the seed of the frame; z: rays per pixel; w: 0
    // The camera the prepass was drawn with (jittered): the world position of pixel (x, y) with ndc = (2 (x + 0.5) / w - 1, 1 - 2 (y + 0.5) / h)
    // and d the linear view depth is rayO0 + ndc.x rayOX + ndc.y rayOY + (rayD0 + ndc.x rayDX + ndc.y rayDY) d. The directions are scaled so
    // that their component along the camera's forward axis is 1, so d (the prepass's r) multiplies them as it is.
    float rayO0[4], rayOX[4], rayOY[4], rayD0[4], rayDX[4], rayDY[4];
    // The same for the camera without the temporal jitter (what history and reprojection use).
    float uRayO0[4], uRayOX[4], uRayOY[4], uRayD0[4], uRayDX[4], uRayDY[4];
    float viewRight[4], viewUp[4],
        viewBack[4];  // xyz: the camera's axes; a view-space normal (x, y, z) is right x + up y + back z
    float viewProj0[4], viewProj1[4], viewProj2[4], viewProj3[4];  // the rows of the unjittered view-projection matrix
    float user0[4], user1[4];                                      // the effect's own numbers
};
static_assert(sizeof(RtEffectParams) == 25 * 16, "RtEffectParams is 25 float4 (the HLSL and MSL structs say the same)");
static_assert(alignof(RtEffectParams) == 4);

// The field names of RtEffectParams in order, one per float4 (a test reads the HLSL and the MSL struct and compares).
inline constexpr std::string_view kRtEffectParamNames[] = {
    "camera",   "lightDir",  "image",     "frame",     "rayO0",     "rayOX",  "rayOY",  "rayD0",     "rayDX",
    "rayDY",    "uRayO0",    "uRayOX",    "uRayOY",    "uRayD0",    "uRayDX", "uRayDY", "viewRight", "viewUp",
    "viewBack", "viewProj0", "viewProj1", "viewProj2", "viewProj3", "user0",  "user1"};
static_assert(sizeof(kRtEffectParamNames) / sizeof(kRtEffectParamNames[0]) == 25);

// The binding numbers of every effect kernel in each backend's own numbering (the contract the .hlsl and .metal files repeat in their header
// comments). A kernel declares only the resources it reads; the numbers never change. The view slots are the engine's slots (Bindings::views).
struct RtEffectBindings {
    // Bindings::views: 0 the output (storage image), 1 the prepass, 2 the scene's records (storage buffer), 3 and 4 the G-buffer.
    static constexpr int kViewOut = 0, kViewPrepass = 1, kViewRecords = 2, kViewAlbedo = 3, kViewMaterial = 4;
    static constexpr int kUniformParams = 0;  // set_uniforms(0, RtEffectParams)
    static constexpr int kSampler =
        0;  // Bindings::samplers: the nearest sampler Sokol wants beside the texture views (rt_effect_needs_sampler)
    // HLSL registers (D3D12): t0 TLAS, u0 out, b0 params, t1 prepass, t2 records, t3 albedo, t4 material.
    // Vulkan bindings (set 0): 0 TLAS, 1 out, 2 params, 3 prepass, 4 records, 5 albedo, 6 material.
    // Metal: buffer(0) TLAS, texture(0) out, buffer(1) params, texture(1) prepass, buffer(2) records, texture(2) albedo, texture(3) material.
};

// What a kernel of the table declares beyond the common four (the TLAS, the output, the constants, the prepass).
struct RtEffectKernelSpec {
    std::string_view kernel;   // the name in rt_kernels.h
    bool usesRecords = false;  // the scene's RtInstanceRecord buffer (t2 / binding 4 / buffer(2))
    bool usesGbuffer =
        false;  // the thin G-buffer's albedo and material images (t3, t4 / bindings 5, 6 / texture(2), texture(3))
};
// The specs of the kernels the renderer runs as effects (every kernel except the probe of the tests).
const RtEffectKernelSpec* find_rt_effect_spec(std::string_view kernel);

// The ShaderDesc of one effect kernel for `backend`: the blob the backend takes (DXIL on D3D12, SPIR-V on Vulkan, the MSL text on Metal and on
// the recording device) and the reflection of the contract above. Pure: no device is touched. Empty `computeFunc` (compute() false) when the
// kernel has no blob for the backend.
gpu::ShaderDesc rt_effect_shader_desc(const rt_kernels::RtKernel& kernel, const RtEffectKernelSpec& spec,
                                      gpu::Backend backend);

// True for the backends whose shader description pairs each texture view with a sampler slot (kSampler): Metal, through Sokol, which refuses a
// texture view no texture-sampler pair names even when the kernel reads it with `read`, and the recording device that stands for it. D3D12 and
// Vulkan have no sampler in the kernel and are bound without one.
bool rt_effect_needs_sampler(gpu::Backend backend);

// Fills the camera fields of `p` (camera, image, rays, view axes, viewProj rows) from `cam` for an image of w x h pixels. `zeroToOne`: the depth
// range of the camera's matrices (CameraTarget::zeroToOne, Gpu::depth_zero_to_one()). A pixel's world position is rebuilt from the prepass's
// linear depth with the formula of RtEffectParams, which is exact for a perspective and for an orthographic camera, jittered or not.
void fill_rt_effect_camera(RtEffectParams& p, const CameraGeometry& cam, int w, int h, bool zeroToOne);

// The seed of a frame: a hash of the frame serial (no wall clock, no rand: the same serial gives the same seed on every machine).
std::uint32_t rt_effect_seed(std::uint64_t frameSerial);

// What one effect of one camera needs this frame.
struct RtEffectRequest {
    std::string kernel;         // "rt_shadow"
    std::string effect;         // "shadows": names the pass (`<job>/rt-<effect>`), the image and the resource
    std::string job;            // the camera's job (JobPlan::name): with `effect` it keys the output image
    std::string after;          // the pass that builds the TLAS (`<job>/rt-accel`); empty = no explicit order
    int width = 0, height = 0;  // the output's size: the prepass's
    PrepassRef prepass;         // required
    PrepassRef gbufferAlbedo, gbufferMaterial;  // required when the kernel uses the G-buffer
    const CameraGeometry* camera = nullptr;
    bool zeroToOne = false;
    std::uint64_t frameSerial = 0;
    int raysPerPixel = 1;
    float lightDir[3] = {0, 1, 0};  // toward the light
    float user0[4] = {}, user1[4] = {};
    RtScene* scene = nullptr;
    int* drawCalls = nullptr;  // each dispatch adds one when it runs (may be null)
};

// The output of an effect: the image the kernel wrote this frame. `ran` is false until the pass ran and again when it could not (no TLAS: the
// scene has no mesh; the prepass image is gone), so a consumer reads it only when `ran` is true at the time it draws.
struct RtEffectImage {
    gpu::Image image{};
    gpu::View storage{};  // what the kernel writes through
    gpu::View texture{};  // what the lit pass and the denoiser sample
    int width = 0, height = 0;
    bool ran = false;
    std::uint64_t lastUsed = 0;
};

struct RtEffectOutput {
    bool valid = false;  // the pass is declared
    std::string why;     // not valid: the reason, one sentence
    ResourceId res;      // the imported resource of the image: list it in the reads of a pass that samples it
    const RtEffectImage* out = nullptr;  // stays alive until sweep() or release() frees it
};

class RtEffects {
public:
    RtEffects() = default;
    RtEffects(const RtEffects&) = delete;
    RtEffects& operator=(const RtEffects&) = delete;

    // Declares the effect's compute pass in `graph` (after the job's `rt-accel` pass and the passes that write the prepass), makes the kernel and
    // the output image on the first call, and returns the output. Not valid, with `why`: the kernel is unknown or has no blob for this device, the
    // device refused the shader, the pipeline or the image, the format cannot be written by a compute shader here, or the request is incomplete.
    RtEffectOutput add_pass(FrameGraph& graph, Gpu& gpu, const RtEffectRequest& req);

    // Frees the images no frame used since `serial - 2` (a camera that stopped asking), and, once no image is left, the kernels (but a kernel the device refused, which is kept so it is not tried again).
    void sweep(Gpu& gpu, std::uint64_t serial);
    // Frees everything (ray tracing went off, the renderer shuts down); the device must be open.
    void release(Gpu& gpu);

    // Tests and the debug output.
    int image_count() const { return int(images_.size()); }
    int kernel_count() const { return int(kernels_.size()); }
    bool empty() const { return images_.empty() && kernels_.empty() && recordsView_.id == 0; }

private:
    struct Kernel {
        gpu::Shader shader{};
        int state = 0;  // 0 not made, 1 made, -1 refused
        std::string why;
    };
    Kernel* kernel_for(Gpu& gpu, const rt_kernels::RtKernel& k, const RtEffectKernelSpec& spec, std::string* why);
    gpu::View records_view(Gpu& gpu, gpu::Buffer records);

    std::map<std::string, Kernel> kernels_;
    std::map<std::string, std::unique_ptr<RtEffectImage>> images_;  // by "<job>/<effect>"
    gpu::Buffer recordsBuffer_{};  // the buffer recordsView_ is a view of (the scene reallocates it when it grows)
    gpu::View recordsView_{};
};

}  // namespace fa::render
