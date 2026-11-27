// Screen-space reflections (PostProcess.ssr*, M71-D3a): shiny surfaces mirror what is on the screen. It works on the scene colour BEFORE
// the exposure, depth of field, bloom and the final pass, after the ambient occlusion and before the fog, and reads the prepass of its
// camera (depth and normals, postprocess.h PrepassRef). Two passes per camera:
//
//   ssr-trace   picture + prepass -> a scratch image of the camera's size: the picture with the reflection mixed in (shaders/ssr.glsl)
//   ssr-copy    the scratch -> the camera's rectangle of the picture
//
// A pass cannot read what it writes, hence the scratch. Every camera has its own passes: a split screen traces each rectangle on its own, and
// a ray never leaves its camera's rectangle. A frame without the effect (or with ssrIntensity 0) declares no pass, makes no image and builds no
// shader. The reflectivity of every surface is the fresnel term of the angle between its normal and the view, scaled by ssrIntensity
// (shaders/ssr.glsl, docs/RENDERING_EFFECTS.md). It does not read the thin G-buffer's roughness and metalness images (M79-P0c, docs/design/
// ARCHITECTURE_RENDERING_GBUFFER.md): the look of the effect is the same whether or not something else asked for them.
//
// Ssr owns its shaders and pipelines (created on first use, destroyed by release()). The plan is pure CPU and needs no GPU.
#pragma once

#include <cstdint>
#include <string>
#include <vector>

#include "bloom.h"
#include "frame_graph.h"
#include "render_internal.h"
#include "transient_targets.h"

namespace fa::render {

struct PostStack;
struct PostRect;
struct PrepassRef;
struct RtEffectImage;

// What a camera's passes draw: the stack's numbers after clamping, the terms of the camera's projection. Empty (any() false) when the effect
// is off, has no intensity, or the camera's matrix cannot be used.
struct SsrPlan {
    bool enabled = false;
    float intensity = 0.0f;     // 0 .. 1
    float maxDistance = 50.0f;  // world units
    float thickness = 0.3f;     // world units
    int steps = 32;             // 8 .. 128
    // The projection's terms the shader needs: P00, P11, P02, P12, P03, P13, P32, P33 (see ssr.glsl).
    float proj[8]{};

    // M79-P3a-1: the camera's ray traced reflections (rt_reflect.hlsl) are composited by these passes (the traced pixels take the kernel's image, the
    // others the march). A plan made by make_ssr_rt_plan has intensity 0 (the stack has no screen-space reflections: only the traced pixels change).
    bool rt = false;

    bool any() const { return enabled; }
};

// True when the stack switches the effect on with an intensity that draws something (so it needs the prepass).
bool ssr_active(const PostStack& stack);

// The plan of a camera (`cam.proj`: its projection); the numbers are clamped to their ranges (a NaN takes the default), see PostProcess.ssr*.
SsrPlan make_ssr_plan(const CameraInfo& cam, const PostStack& stack);

// The plan of a camera whose stack has no screen-space reflections but whose reflections are ray traced: intensity 0 (the march draws nothing), the
// projection's terms; empty when the camera's matrix cannot be used. `rt` is set.
SsrPlan make_ssr_rt_plan(const CameraInfo& cam);

// M79-P3a-2: what the composite of the ray traced reflections reads besides the kernel's raw image (shaders/ssr.glsl): the denoiser's results for the
// glossy pixels (both invalid: not denoised, the raw image serves every traced pixel), the G-buffer's roughness (invalid: every pixel reads as sharp)
// and the roughness limits. The resources are transients of the frame graph (the trace pass lists the valid ones in its reads).
// The roughness range of the traced reflections: under kRtReflectSharp one mirror ray per pixel, undenoised (the P3a-1 path); from there to
// kRtReflectLimit glossy rays (GGX visible normals) denoised; the traced share fades out between kRtReflectFade and kRtReflectLimit, where the
// screen-space march and the probes take over (their blur matches a rough lobe better than a few noisy rays, and the rays cost the most there).
constexpr float kRtReflectSharp = 0.25f, kRtReflectFade = 0.5f, kRtReflectLimit = 0.65f;
struct SsrRtGlossy {
    ResourceId color,
        coverage;  // the denoised radiance (rgb premultiplied by the coverage) and the denoised coverage (r)
    const TransientTargets* targets = nullptr;
    ResourceId material;            // r = roughness (a transient of `targets`)
    float sharp = kRtReflectSharp;  // under it: the raw mirror ray
    float fadeStart =
        kRtReflectFade;  // from it to `limit` the traced reflection fades into the screen-space march and the probes
    float limit = kRtReflectLimit;  // the roughest traced pixel
};

class Ssr {
public:
    Ssr() = default;
    Ssr(const Ssr&) = delete;
    Ssr& operator=(const Ssr&) = delete;

    // Declares the passes of one camera in `graph`: after the passes that draw `game` (the imported resource of the picture, texture view
    // `srcTex`), before bloom and the effects that follow the reflections in the stack. `rect`: the camera's rectangle of the picture (picW x
    // picH); `prepass`: its prepass (invalid: nothing is drawn); `dst`: where the result goes, as the bloom's (BloomTarget). Each pass adds one
    // to *drawCalls when it runs. `rtImage` (with `rtRes`, its imported resource) is the ray traced reflections of the camera (rt_effect.h, the
    // size of the prepass); when it is given and `ran` when the trace pass executes, the pixels the kernel traced take it (shaders/ssr.glsl); with
    // no image the passes are the ones of the screen-space reflections alone. Returns the number of passes declared (0: nothing is drawn: no effect, no prepass, shaders or targets the GPU
    // cannot make; logged once).
    int add_passes(FrameGraph& graph, TransientTargets& targets, Gpu& gpu, const SsrPlan& plan, const PostRect& rect,
                   int picW, int picH, ResourceId game, gpu::View srcTex, const BloomTarget& dst,
                   const PrepassRef& prepass, int* drawCalls, const std::string& job,
                   const RtEffectImage* rtImage = nullptr, ResourceId rtRes = {}, const SsrRtGlossy* glossy = nullptr);

    // Destroys the shaders and the pipelines; call while the graphics context is open.
    void release();
    // Forgets that creating the scratch image failed (the game target was resized or recreated).
    void forget_targets();

    enum class Prog { Trace, Copy, Count };
    bool ready(Gpu& gpu);
    gpu::Pipeline pipeline(Prog prog, const TargetFormat& format);

private:
    struct PipelineEntry {
        Prog prog;
        TargetFormat format;
        gpu::Pipeline pipeline;
    };
    gpu::Device* device_ =
        nullptr;  // the device of the first ready(): the shaders and pipelines are made and destroyed on it
    gpu::Shader shaders_[int(Prog::Count)]{};
    std::vector<PipelineEntry> pipelines_;
    int state_ = 0;  // 0 = shaders not made yet, 1 = ready, -1 = failed (logged)
    bool warnedTargets_ = false;
    std::vector<std::uint64_t> failed_;  // shapes whose scratch image could not be made (not tried again every frame)
    std::vector<std::uint64_t>
        probed_;  // shapes whose scratch image was made once (the GPU can have it): not probed every frame
};

}  // namespace fa::render
