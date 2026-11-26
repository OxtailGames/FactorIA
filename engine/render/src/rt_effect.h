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
#include <functional>
#include <map>
#include <memory>
#include <mutex>
#include <set>
#include <string>
#include <string_view>
#include <vector>

#include "fa/core/math.h"
#include "fa/render/raytracing.h"
#include "fa/scene/camera_geometry.h"

#include "frame_graph.h"
#include "gpu/device.h"
#include "postprocess.h"
#include "render_internal.h"
#include "rt_kernels.h"
#include "transient_targets.h"

namespace fa::render {

class RtScene;
struct RtEffectImage;

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

// The second constants block of the kernels that shade what a ray hits (rt_hit.hlsli, rt_hit.msli: the same struct between `// BEGIN RtHitParams` and
// `// END RtHitParams`): 6 float4, 96 bytes, set at uniform slot RtEffectBindings::kUniformHit by a request that carries it (RtEffectRequest::hit).
struct RtHitParams {
    float sunDir[4];  // xyz: the unit vector from a surface toward the sun; w: 0
    float
        sunColor[4];   // xyz: the sun's radiance (colour * intensity, scene colour space; 0 = no sun that lights); w: 0
    float ambient[4];  // xyz: SceneSettings.ambientLight (the scene's colour space); w: 0
    float sky[4];  // xyz: SceneSettings.skyColor; w: 1 when the scene's environment is a texture the kernel cannot read
    float horizon[4];  // xyz: SceneSettings.horizonColor; w: 0
    // x: the shadow ray's offset along the normal in metres, y: more of it per metre of the ray's length, z: the shadow ray's TMax, w: the
    // differential rays' offset as a fraction of the hit distance.
    float limits[4];
};
static_assert(sizeof(RtHitParams) == 6 * 16, "RtHitParams is 6 float4 (rt_hit.hlsli and rt_hit.msli say the same)");
inline constexpr std::string_view kRtHitParamNames[] = {"sunDir", "sunColor", "ambient", "sky", "horizon", "limits"};

// The third constants block, of the path tracer (rt_pathtrace.hlsl / .metal, between `// BEGIN RtLightParams` and `// END RtLightParams`): the
// point and spot lights it samples, 33 float4, 528 bytes, at uniform slot RtEffectBindings::kUniformLights by a request that carries it
// (RtEffectKernelSpec::usesLights). `count` is the number of the first lights that are filled (0 .. kRtMaxLights).
inline constexpr int kRtMaxLights = 8;
struct RtLightParams {
    std::uint32_t count[4];  // x: the number of lights
    float pos[kRtMaxLights][4];    // xyz: the position (the renderer's space), w: the range
    float color[kRtMaxLights][4];  // rgb: colour * intensity, w: the type (1 point, 2 spot; an area light is a point light at its centre)
    float dir[kRtMaxLights][4];    // xyz: a spot's axis, w: cos(outer angle)
    float extra[kRtMaxLights][4];  // x: cos(inner angle) of a spot (above 1.5: the lit pass's default fade)
};
static_assert(sizeof(RtLightParams) == 33 * 16, "RtLightParams is 33 float4 (rt_pathtrace.hlsl and .metal say the same)");
inline constexpr std::string_view kRtLightParamNames[] = {"count", "pos", "color", "dir", "extra"};
// M79-P2a-3: the lights the local shadow kernel (rt_shadow_local) traces. At most kRtLocalMaxLights per frame: the three visibilities share one
// image (r, g, b), one denoiser signal and the three bytes of one float of the lit pass's image (docs/design/ARCHITECTURE_RT_SHADOWS.md).
inline constexpr int kRtLocalMaxLights = kRtLocalShadowMaxLights;  // raytracing.h
// What the kernel needs of one light (5 float4, 80 bytes; rt_shadow_local.hlsl / .metal have the same struct between `// BEGIN RtLocalLight` and
// `// END RtLocalLight`). Kinds: 1 point, 2 spot, 3 rectangle, 4 disc, 5 tube.
struct RtLocalLight {
    float posReach
        [4];  // xyz: the light's position; w: how far it reaches (its range plus an area light's radius), the pixels past it are lit
    float axisCos[4];  // xyz: a spot's axis / an area light's front (unit); w: a spot's cos(half angle) (-2 = no cone)
    float kind
        [4];  // x: the kind above; y: the tangent of the cone of rays of a point or spot light (0 = one ray to the centre); z: the
    // factor on an area light's half sizes (Light.shadowSoftness; 0 = hard); w: 0
    float right[4];  // xyz: an area light's first axis times its half size (a tube: along its length); w: 0
    float up
        [4];  // xyz: the second axis times its half size (a disc: the same as `right`; a tube: its half thickness); w: 0
};
// The constants block of rt_shadow_local at uniform slot RtEffectBindings::kUniformHit: 16 float4, 256 bytes (the header, then the lights).
struct RtLocalParams {
    float header
        [4];  // x: how many lights are traced (0 .. kRtLocalMaxLights); y: the ray's pull back from the light, a fraction of its length
    RtLocalLight lights[kRtLocalMaxLights];
};
static_assert(sizeof(RtLocalLight) == 5 * 16 && sizeof(RtLocalParams) == 16 * 16,
              "RtLocalParams is 16 float4 (rt_shadow_local.hlsl and .metal say the same)");
inline constexpr std::string_view kRtLocalLightNames[] = {"posReach", "axisCos", "kind", "right", "up"};

// The binding numbers of every effect kernel in each backend's own numbering (the contract the .hlsl and .metal files repeat in their header
// comments). A kernel declares only the resources it reads; the numbers never change. The view slots are the engine's slots (Bindings::views).
struct RtEffectBindings {
    // Bindings::views: 0 the output (storage image), 1 the prepass, 2 the scene's records (storage buffer), 3 and 4 the G-buffer, 5 the second
    // input image of a kernel that has one (M79-P2a-2: the denoiser's output for rt_shadow_pack).
    static constexpr int kViewOut = 0, kViewPrepass = 1, kViewRecords = 2, kViewAlbedo = 3, kViewMaterial = 4,
                         kViewAux = 5;
    static constexpr int kUniformParams = 0;  // set_uniforms(0, RtEffectParams)
    static constexpr int kUniformHit =
        1;  // set_uniforms(1, RtHitParams): the kernels that use rt_hit.hlsli (RtEffectKernelSpec::usesHit)
    static constexpr int kUniformLights =
        2;  // set_uniforms(2, RtLightParams): b2 / binding 8 / buffer(4) (RtEffectKernelSpec::usesLights)
    static constexpr int kSampler =
        0;  // Bindings::samplers: the nearest sampler Sokol wants beside the texture views (rt_effect_needs_sampler)
    // HLSL registers (D3D12): t0 TLAS, u0 out, b0 params, t1 prepass, t2 records, t3 albedo, t4 material, t5 aux.
    // Vulkan bindings (set 0): 0 TLAS, 1 out, 2 params, 3 prepass, 4 records, 5 albedo, 6 material, 7 aux.
    // Metal: buffer(0) TLAS, texture(0) out, buffer(1) params, texture(1) prepass, buffer(8) records (Sokol: storage buffers are 8 .. 23),
    // texture(2) albedo, texture(3) material, texture(4) aux.
    // The hit constants (usesHit): b1 / binding 7 / buffer(3). Vulkan binding 7 is the aux image of a kernel with usesAux and the hit constants of
    // one with usesHit: no kernel has both (add_pass refuses a spec that does).
    // The numbers of the sun shadow's own constants (RtEffectParams::user0, user1) are in rt_shadow_params below.
};

// What a kernel of the table declares beyond the common three (the output, the constants, the prepass).
struct RtEffectKernelSpec {
    std::string_view kernel;   // the name in rt_kernels.h
    bool usesRecords = false;  // the scene's RtInstanceRecord buffer (t2 / binding 4 / buffer(8))
    bool usesGbuffer =
        false;  // the thin G-buffer's albedo and material images (t3, t4 / bindings 5, 6 / texture(2), texture(3))
    bool usesHit =
        false;  // the kernel shades what its rays hit (rt_hit.hlsli): RtHitParams at b1 / binding 7 / buffer(3); it needs usesRecords
    bool usesTlas =
        true;  // the TLAS (t0 / binding 0 / buffer(0)); false: a kernel that only moves pixels, no ray query
    bool usesAux =
        false;  // RtEffectRequest::aux as the second input image (t5 / binding 7 / texture(4)); not with usesHit
    bool usesLocal =
        false;  // RtEffectRequest::local (RtLocalParams) at b1 / binding 7 / buffer(3), like usesHit; not with usesHit or usesAux
    // M79-P5a (the path tracer): the kernel reads the image it writes (a running mean over the frames: the output is a read and write storage
    // image, which needs a device that reads RGBA32F storage images) and the RtLightParams block of the request.
    bool readsOut = false;
    bool usesLights = false;
};

// The numbers the renderer gives the sun shadow kernel in RtEffectParams::user0 (and the tests too: one place, so a test traces with what the
// engine does): the normal offset in metres, more of it per metre of view depth (a pixel covers more world far away), TMin, TMax (the ray's
// reach; the scene's size is far below it).
inline constexpr float kRtShadowUser0[4] = {0.02f, 0.002f, 0.0f, 10000.0f};
// user1.y of rt_shadow: 0 = the hard layout (depth, visibility), 1 = the soft one (visibility, depth) that the denoiser reads.
inline constexpr float kRtShadowLayoutHard = 0.0f, kRtShadowLayoutSoft = 1.0f;
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

// What a pass does after RtEffectRequest::prepare: Dispatch the kernel, Hold the image as it is (it counts as drawn: `ran` is true) or Skip
// (`ran` stays false, nothing is drawn from it this frame).
enum class RtPrepare { Dispatch, Hold, Skip };

// What one effect of one camera needs this frame.
struct RtEffectRequest {
    std::string kernel;         // "rt_shadow"
    std::string effect;         // "shadows": names the pass (`<job>/rt-<effect>`), the image and the resource
    std::string job;            // the camera's job (JobPlan::name): with `effect` it keys the output image
    std::string after;          // the pass that builds the TLAS (`<job>/rt-accel`); empty = no explicit order
    int width = 0, height = 0;  // the output's size: the prepass's
    PrepassRef prepass;         // required, unless `srcImage` takes its place
    // A kernel that reads the image another effect wrote (rt_shadow_pack) gives it here instead of a prepass: its view is bound at kViewPrepass,
    // `srcRes` (RtEffectOutput::res of that effect) is read by the pass and the image's size is the output's. The pass does not run (and its output's
    // `ran` stays false) while the image's `ran` is false.
    const RtEffectImage* srcImage = nullptr;
    ResourceId srcRes;
    PrepassRef aux;  // required when the kernel uses the aux image: any transient (the denoiser's output)
    // ... or the image of another effect (M79-P2a-3: the local shadows' trace image the pack kernel reads when it is not denoised), with its resource.
    // Like `srcImage`, the pass does not run while that image's `ran` is false.
    const RtEffectImage* auxImage = nullptr;
    ResourceId auxRes;
    PrepassRef gbufferAlbedo, gbufferMaterial;  // required when the kernel uses the G-buffer
    const CameraGeometry* camera = nullptr;
    bool zeroToOne = false;
    std::uint64_t frameSerial = 0;
    int raysPerPixel = 1;
    float lightDir[3] = {0, 1, 0};  // toward the light
    float user0[4] = {}, user1[4] = {};
    RtHitParams hit{};  // set at kUniformHit when the kernel's spec has usesHit
    RtLightParams lights{};  // set at kUniformLights when the kernel's spec has usesLights
    // What the pass does with its image this frame, decided when the pass runs (the TLAS and the prepass are known to be there): the path tracer
    // counts its samples here (rt_pathtrace.h). It may change the constants (`params`: the sample counters) and says what to do. Called on the
    // thread that runs the graph, once per pass that runs, after the checks that could skip the pass and before the dispatch.
    std::function<RtPrepare(RtEffectParams& params, const RtEffectImage& image)> prepare;
    RtHitParams hit{};      // set at kUniformHit when the kernel's spec has usesHit
    RtLocalParams local{};  // set at kUniformHit when the kernel's spec has usesLocal
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
    std::uint64_t serial = 0;  // the same while this image lives: a made-again image has another (the path tracer's accumulation starts over)
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

    // Why an effect that was declared did not run when its pass came (the driver refused the pipeline, the prepass changed size...): the first
    // reason of the frames so far that was not cleared by a later run of the same effect, or empty. Each reason is also a warning, once.
    std::string failure() const;

    // Tests and the debug output.
    int image_count() const { return int(images_.size()); }
    int kernel_count() const { return int(kernels_.size()); }
    bool empty() const { return images_.empty() && kernels_.empty() && recordsView_.id == 0; }

private:
    struct Kernel {
        gpu::Shader shader{};
        int state = 0;  // 0 not made, 1 made, -1 refused
        std::string why;
        std::uint64_t lastUsed =
            0;  // the frame serial of the last request: a kernel nothing asks for any more is freed with its image
    };
    Kernel* kernel_for(Gpu& gpu, const rt_kernels::RtKernel& k, const RtEffectKernelSpec& spec, std::string* why);
    gpu::View records_view(Gpu& gpu, gpu::Buffer records);

    void note_failure(const std::string& key,
                      const std::string& why);  // the effect could not run: warns once per reason
    void clear_failure(const std::string& key);

    mutable std::mutex failureMutex_;
    std::map<std::string, std::string> failures_;  // by "<job>/<effect>": what stopped the pass the last time it came
    std::set<std::string> warned_;                 // key + reason, said once
    std::map<std::string, Kernel> kernels_;
    std::map<std::string, std::unique_ptr<RtEffectImage>> images_;  // by "<job>/<effect>"
    std::uint64_t imageSerial_ = 0;
    gpu::Buffer recordsBuffer_{};  // the buffer recordsView_ is a view of (the scene reallocates it when it grows)
    gpu::View recordsView_{};
};

}  // namespace fa::render
