// Screen-space reflections (PostProcess.ssr*, M71-D3a): shiny surfaces mirror what is on the screen. It works on the scene colour BEFORE
// the exposure, depth of field, bloom and the final pass, after the ambient occlusion and before the fog, and reads the prepass of its
// camera (depth and normals, postprocess.h PrepassRef). Two passes per camera:
//
//   ssr-trace   picture + prepass -> a scratch image of the camera's size: the picture with the reflection mixed in (shaders/ssr.glsl)
//   ssr-copy    the scratch -> the camera's rectangle of the picture
//
// A pass cannot read what it writes, hence the scratch. Every camera has its own passes: a split screen traces each rectangle on its own, and
// a ray never leaves its camera's rectangle. A frame without the effect (or with ssrIntensity 0) declares no pass, makes no image and builds no
// shader. There is no roughness or metalness image, so the reflectivity of every surface is the fresnel term of the angle between its normal
// and the view, scaled by ssrIntensity (shaders/ssr.glsl, docs/RENDERING_EFFECTS.md).
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

    bool any() const { return enabled; }
};

// True when the stack switches the effect on with an intensity that draws something (so it needs the prepass).
bool ssr_active(const PostStack& stack);

// The plan of a camera (`cam.proj`: its projection); the numbers are clamped to their ranges (a NaN takes the default), see PostProcess.ssr*.
SsrPlan make_ssr_plan(const CameraInfo& cam, const PostStack& stack);

class Ssr {
public:
    Ssr() = default;
    Ssr(const Ssr&) = delete;
    Ssr& operator=(const Ssr&) = delete;

    // Declares the passes of one camera in `graph`: after the passes that draw `game` (the imported resource of the picture, texture view
    // `srcTex`), before bloom and the effects that follow the reflections in the stack. `rect`: the camera's rectangle of the picture (picW x
    // picH); `prepass`: its prepass (invalid: nothing is drawn); `dst`: where the result goes, as the bloom's (BloomTarget). Each pass adds one
    // to *drawCalls when it runs. Returns the number of passes declared (0: nothing is drawn: no effect, no prepass, shaders or targets the GPU
    // cannot make; logged once).
    int add_passes(FrameGraph& graph, TransientTargets& targets, Gpu& gpu, const SsrPlan& plan, const PostRect& rect,
                   int picW, int picH, ResourceId game, sg_view srcTex, const BloomTarget& dst,
                   const PrepassRef& prepass, int* drawCalls, const std::string& job);

    // Destroys the shaders and the pipelines; call while the graphics context is open.
    void release();
    // Forgets that creating the scratch image failed (the game target was resized or recreated).
    void forget_targets();

    enum class Prog { Trace, Copy, Count };
    bool ready();
    sg_pipeline pipeline(Prog prog, const TargetFormat& format);

private:
    struct PipelineEntry {
        Prog prog;
        TargetFormat format;
        sg_pipeline pipeline;
    };
    sg_shader shaders_[int(Prog::Count)]{};
    std::vector<PipelineEntry> pipelines_;
    int state_ = 0;  // 0 = shaders not made yet, 1 = ready, -1 = failed (logged)
    bool warnedTargets_ = false;
    std::vector<std::uint64_t> failed_;  // shapes whose scratch image could not be made (not tried again every frame)
    std::vector<std::uint64_t>
        probed_;  // shapes whose scratch image was made once (the GPU can have it): not probed every frame
};

}  // namespace fa::render
