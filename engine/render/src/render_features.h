// What the renderer can do on the backend and GPU it runs on (Renderer::supports, the `render.supports` command): one table of named
// features, each with the backends it can ever run on, what it needs from the GPU, and whether the engine implements it yet. The table
// and the decision are pure (a FeatureEnv in, an answer out) so a test can ask "what would D3D11 say"; only feature_env_from_device() asks the GPU.
//
// Names: the capabilities of the GPU the M71 pipeline relies on (floatTargets, r11g11b10, sampledDepth, computeShaders), the engine
// features built on them (linearColor, hdrOutput) and one entry per post effect (the names of kPostEffectOrder, fa/scene/postprocess.h).
// An effect or feature the engine does not draw answers false with the status "planned (<milestone>)" (the `planned` field of its row; the
// effects are all drawn today, the lighting rows of M73 are planned "M73" until their package lands; clusteredLights landed in M73.1a), so `supports` never claims what the
// renderer cannot do.
#pragma once

#include <array>
#include <cstdint>
#include <functional>
#include <string>
#include <string_view>
#include <vector>

#include "fa/core/json.h"
#include "fa/platform/hdr_output.h"
#include "gpu/device.h"
#include "render_upscale_vendor.h"

namespace fa::render {

// The rows of the per-backend table. Headless is the backend without a GPU (sokol's dummy backend: nothing is drawn); a headless run
// with Mesa/EGL is a GL or GLES3 backend like any other and answers as one.
enum class FeatureBackend { Gl, Gles3, WebGl2, D3d11, Metal, Headless };
inline constexpr int kFeatureBackendCount = 6;
// "GL", "GLES3", "WebGL2", "D3D11", "Metal", "Headless": the column names of the documentation table.
const char* feature_backend_label(FeatureBackend b);

// What the GPU reported (gpu::Device::pixel_format_caps / features / limits), plus the backend.
struct FeatureEnv {
    FeatureBackend backend = FeatureBackend::Headless;
    bool halfTargets = false;   // RGBA16F renders, blends and filters
    bool r11g11b10 = false;     // RG11B10F renders and filters
    bool sampledDepth = false;  // a depth buffer can be sampled as a texture by a later pass
    bool compute = false;       // storage buffers and compute shaders
    bool float32 = false;  // R32F and RGBA32F render and can be sampled (the shadow atlas of M73.2 is an R32F target)
    // hdrOutput: whether the window can show HDR now (the display the window is on offers an encoding the renderer writes), and
    // why not. Renderer::supports fills both with set_hdr_env() from the display of the last frame; a FeatureEnv made by hand
    // without them answers "the display has not been asked yet".
    bool hdrOutput = false;
    std::string hdrWhy;
    // The sizes the GPU reports (sg_query_limits; 0 = not asked, a FeatureEnv made by hand): the largest 2D texture side, the most layers of
    // a texture array and the largest side of a texture array. The Terrain needs them (a heightmap must fit the first, its layers the others).
    int maxTextureSize = 0;
    int maxArrayLayers = 0;
    int maxArrayTextureSize = 0;
    // metalfx: Apple's upscalers can run here (the Metal backend, an OS and a GPU that have them), and why not (metalfx::support()). Asked by
    // feature_env_from_device on Metal only; a FeatureEnv made by hand says no.
    bool metalfx = false;
    std::string metalfxWhy;
    // The vendor upscalers dlss, xess and fsr (M78): what each provider answered for this GPU (render_upscale_vendor.h), and whether it was
    // asked at all. Renderer::supports asks (feature_env_from_device does not: it would read the disk for the libraries each time); an
    // env made by hand says "not asked".
    std::array<VendorProbe, kVendorUpscalerCount> vendorUpscalers;
    bool vendorAsked = false;
    // The "dlssRayReconstruction" row (M78-P4c): what DlssProvider::probe_ray_reconstruction answered (the machine of "dlss" plus the Ray
    // Reconstruction plugin, and the renderer's guides), asked with the others.
    VendorProbe dlssRayReconstruction;
    // The low-latency providers reflex, antilag2 and xell (M78, render_latency.h): what each answered for this GPU, and whether they were asked.
    std::array<VendorProbe, 3> latency;
    bool latencyAsked = false;
    // The frame-generation providers dlss, fsr and xess (M78, render_framegen.h): what each answered for this GPU, and whether they were asked.
    std::array<VendorProbe, 3> framegen;
    bool framegenAsked = false;
};
// Puts the providers' answers (index 0 dlss, 1 xess, 2 fsr) and DLSS's Ray Reconstruction answer into `env`.
void set_vendor_upscalers_env(FeatureEnv& env, const std::array<VendorProbe, kVendorUpscalerCount>& answers,
                              const VendorProbe& rayReconstruction = {});
// Puts the low-latency providers' answers (index 0 reflex, 1 antilag2, 2 xell) into `env`.
void set_latency_env(FeatureEnv& env, const std::array<VendorProbe, 3>& answers);
// Puts the frame-generation providers' answers (index 0 dlss, 1 fsr, 2 xess) into `env`.
void set_framegen_env(FeatureEnv& env, const std::array<VendorProbe, 3>& answers);

// The HDR encodings the present pass writes on `b` (hdr_encoding_bit; the encodes are in hdr_encode.h): EDR on Metal (extended
// linear sRGB), scRGB and HDR10 on D3D11. Every other backend: none (GL, GLES3 and WebGL2 have no HDR swapchain in sokol).
unsigned hdr_encodable(FeatureBackend b);
// What the renderer asks app_update_hdr_output() for on backend `b` (Metal: an extended LINEAR sRGB swapchain, what the present
// pass writes).
HdrRequest hdr_request(FeatureBackend b, bool want, float paperWhiteNits);
// Fills env.hdrOutput / env.hdrWhy from `display`, the scene's hdrOutput setting aside (supports answers whether the window could
// show HDR, not whether the scene asks for it).
void set_hdr_env(FeatureEnv& env, const HdrDisplay& display);

// The effects of kPostEffectOrder the renderer draws today, as a mask (bit i = PostEffect(i)): what `supports` answers true for (when the GPU
// has what the effect needs) and what the prepass is made for (postprocess.cpp). A stack that switches on an effect outside it draws
// nothing for that effect.
std::uint32_t post_drawn_mask();

enum class FeatureKind { Capability, Engine, Effect };

struct FeatureDef {
    const char* name;
    FeatureKind kind;
    unsigned backends;  // bit (1 << FeatureBackend) of every backend the feature can ever run on
    const char*
        needs;  // "": nothing; "half", "r11g11b10", "depth", "compute", "float32", "half+depth", "metalfx": what the GPU must also report
    const char*
        planned;  // nullptr: the engine draws/does it; else the milestone it is planned in ("M71"), and it answers false
    const char* doc;  // one sentence: what it is and what it costs
};

// Every feature, in a fixed order: capabilities, engine features, then the effects in the canonical order of kPostEffectOrder.
const std::vector<FeatureDef>& feature_table();
// The names of feature_table(), in its order.
std::vector<std::string> feature_names();

// Index into feature_table() of `name`, -1 when unknown.
int find_feature(std::string_view name);

// Whether feature `index` of the table works under `env`; when it does not, `why` (when given) says why in one sentence that names the
// backend or the missing GPU capability, or "planned (<milestone>)" for a feature the engine does not draw.
bool feature_supported(const FeatureEnv& env, int index, std::string* why = nullptr);

// The row of a device backend: D3D12 and Vulkan answer Headless until they get their own rows (M77.2, M77.3).
FeatureBackend feature_backend_of(gpu::Backend backend);

// The environment of a backend from what its GPU reports: `caps` answers per pixel format; `metalDevice` (the id<MTLDevice>
// of Device::native().device; null = not asked) asks the MetalFX framework on Metal. The hdr fields stay unasked (set_hdr_env).
FeatureEnv feature_env_from_queries(gpu::Backend backend, const gpu::Limits& limits, bool compute,
                                    const std::function<gpu::PixelFormatCaps(gpu::PixelFormat)>& caps,
                                    const void* metalDevice);

// The environment of `device`: its backend, pixel formats, features and limits.
FeatureEnv feature_env_from_device(const gpu::Device& device);

// The answer of render.supports for every feature under `env`:
// {backend, backendLabel, features: [{name, kind, supported, status, doc, backends: {GL, GLES3, WebGL2, D3D11, Metal, Headless}}]}.
// `status` is "supported", "planned (<milestone>)" or why it is not supported here.
Json feature_report(const FeatureEnv& env, const char* backendName);

}  // namespace fa::render
