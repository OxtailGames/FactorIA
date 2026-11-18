// Ambient occlusion (PostProcess.ssaoEnabled, the first effect of the stack): GTAO from the depth and normal prepass of a camera
// (postprocess.h, PrepassRef), drawn as passes of the frame graph over the camera's rectangle of the game image, before the bloom:
//
//   ssao-ao        the horizon search at half (low, medium) or full (high, ultra) resolution (shaders/ssao.glsl)
//   ssao-blur-h    bilateral blur, weighted by the depth, two passes of five taps: the fixed 4x4 pattern of the search averages out
//   ssao-blur-v
//   ssao-apply     the visibility raised to a power (intensity), multiplied into the game image in place (a blend with DST_COLOR),
//                  so every pass after it (bloom, the final pass) sees the darkened picture. With the debug view `ao`, `ssao-view`
//                  writes the occlusion as a grey over the picture instead.
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

// Where the darkening goes: `att` is a colour attachment of the game image (the resolved image of an MSAA target, or, when the interface is
// drawn over the glow afterwards, the multisampled one with `resolve` its resolve attachment and `samples` its sample count).
struct SsaoTarget {
    sg_view att{};
    sg_view resolve{};
    int samples = 1;
};

class Ssao {
public:
    Ssao() = default;
    Ssao(const Ssao&) = delete;
    Ssao& operator=(const Ssao&) = delete;

    // Declares the passes of one camera, named "<job>/ssao-...", after the passes that draw the game image `game` (and the camera's
    // prepass, `prepass`, which they read). `rect` is the camera's rectangle of the picture of `picW` x `picH`. `linear`: the scene
    // holds linear light (a gamma scene is darkened by the power that gives the same linear result). Returns the number of passes
    // declared, 0 when the effect is skipped (not enabled, no prepass, the GPU cannot make the targets or the shaders: logged once).
    // The targets are transients of the graph; each pass adds one to *drawCalls when it runs.
    int add_passes(FrameGraph& graph, TransientTargets& targets, Gpu& gpu, const SsaoSettings& s, const SsaoCamera& cam,
                   const PrepassRef& prepass, const PostRect& rect, int picW, int picH, ResourceId game,
                   const SsaoTarget& dst, bool linear, int* drawCalls, const std::string& job);

    // Forgets the shapes whose targets could not be made (the game target was resized or recreated).
    void release() { failed_.clear(); }

private:
    bool warned_ = false;
    struct Shape {
        int w = 0, h = 0;
        bool operator==(const Shape& o) const { return w == o.w && h == o.h; }
    };
    static constexpr std::size_t kMaxFailed = 16;  // the oldest go
    std::vector<Shape> failed_;
};

}  // namespace fa::render
