// Ambient occlusion (PostProcess.ssaoEnabled, the first effect of the stack): GTAO from the depth and normal prepass of a camera
// (postprocess.h, PrepassRef). Three passes of the frame graph make the occlusion image BEFORE the camera's main pass (they read only the
// prepass):
//
//   ssao-ao        the horizon search at half (low, medium) or full (high, ultra) resolution (shaders/ssao.glsl)
//   ssao-blur-h    bilateral blur, weighted by the depth, two passes of five taps: the fixed 4x4 pattern of the search averages out
//   ssao-blur-v
//
// and the main pass draws the apply (draw_apply) inside itself, after the sky and the opaque meshes and before the blended meshes and the
// quads of the world: the visibility raised to a power (intensity), multiplied into the game image in place (a blend with DST_COLOR). The
// pixels drawn after it (glass, sprites, particles, 3D text, the HUD) are not darkened, and every pass after the main pass (bloom, the
// final pass) sees the darkened picture. With the debug view `ao` the same draw writes the occlusion as a grey instead.
//
// Nothing is random and nothing depends on the frame number: the same scene gives the same picture on every run. A camera without the
// effect, with an intensity or a radius of 0, or without an opaque mesh, declares none of it and makes no target.
#pragma once

#include <cstddef>
#include <cstdint>
#include <string>
#include <vector>

#include "fa/scene/camera_geometry.h"

#include "frame_graph.h"
#include "postprocess.h"
#include "render_internal.h"
#include "transient_targets.h"

namespace fa::render {

// What a quality level costs (PostProcess.ssaoQuality).
struct SsaoQualityInfo {
    bool half;   // the horizon search runs at half the size of the camera's rectangle
    int slices;  // directions in screen space
    int steps;   // samples per direction and side
};
SsaoQualityInfo ssao_quality_info(int quality);

// The camera's projection as the shader needs it: what a unit of normalised device coordinates is in view space at depth 1 (a
// perspective camera) or at any depth (an orthographic one).
struct SsaoCamera {
    float halfX = 1.0f, halfY = 1.0f;
    bool ortho = false;
};
SsaoCamera ssao_camera(const CameraGeometry& cam);

// What the main pass draws once the passes of add_passes are declared: the numbers of the apply and the images it reads (resources of the
// graph, which the main pass lists in its reads).
struct SsaoApply {
    bool valid = false;
    ResourceId ao;       // the occlusion image (the output of ssao-blur-v)
    ResourceId prepass;  // the camera's prepass
    float power = 1.0f;  // the visibility is raised to it
    float scale = 1.0f;  // prepass pixels per texel of the occlusion image (1 or 2)
    float sz[4]{};       // xy = size of the occlusion image, zw = size of the prepass image
    float cam[4]{};      // SsaoCamera and the flip of OpenGL, as shaders/ssao.glsl reads it
    bool view = false;   // the debug view: the occlusion as a grey
};

class Ssao {
public:
    Ssao() = default;
    Ssao(const Ssao&) = delete;
    Ssao& operator=(const Ssao&) = delete;

    // Declares the passes of one camera, named "<job>/ssao-...", after the camera's prepass `prepass`, which they read, and before its main
    // pass. `rect` is the camera's rectangle of the picture of `picW` x `picH`. `linear`: the scene holds linear light (a gamma scene is
    // darkened by the power that gives the same linear result). Returns the number of passes declared, 0 when the effect is skipped (not
    // enabled, no prepass, the GPU cannot make the targets or the shaders: logged once); `*apply` says what the main pass draws then
    // (valid only when passes were declared). The targets are transients of the graph; each pass adds one to *drawCalls when it runs.
    int add_passes(FrameGraph& graph, TransientTargets& targets, Gpu& gpu, const SsaoSettings& s, const SsaoCamera& cam,
                   const PrepassRef& prepass, const PostRect& rect, int picW, int picH, bool linear, int* drawCalls,
                   const std::string& job, SsaoApply* apply);

    // The apply, drawn inside the pass being drawn whose target has `format`: one full-screen triangle over its viewport (the caller has set
    // the viewport and the scissor to the camera's rectangle), reading the occlusion image `ao` and the prepass `pre`.
    static void draw_apply(gpu::CommandList& list, Gpu& gpu, const SsaoApply& apply, gpu::View ao, gpu::View pre,
                           const TargetFormat& format);
    // The same on the Gpu's own frame list (gpu.commands()). TRANSITIONAL (M77-P4a/P5): the main pass still opens its pass with
    // Gpu::begin_pass, which records on that list.
    static void draw_apply(Gpu& gpu, const SsaoApply& apply, gpu::View ao, gpu::View pre, const TargetFormat& format);

    // Forgets the shapes whose targets could not be made (the game target was resized or recreated).
    void release() {
        failed_.clear();
        probed_.clear();
    }

private:
    bool warned_ = false;
    struct Shape {
        int w = 0, h = 0;
        bool operator==(const Shape& o) const { return w == o.w && h == o.h; }
    };
    static constexpr std::size_t kMaxFailed = 16;  // the oldest go
    std::vector<Shape> failed_;
    std::vector<Shape>
        probed_;  // shapes whose targets were made once (the GPU can have them): not probed again every frame
};

}  // namespace fa::render
