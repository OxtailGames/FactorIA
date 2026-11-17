// The post-processing stack of a frame (M71): what the renderer draws from the PostStack of the camera that drives post, and the passes
// that are not the bloom's chain. Design:
//
//   PostPlan          the stack as the passes read it: sanitised numbers, nothing of the components (make_post_plan)
//   AutoExposure      PostProcess.exposureMode auto: two passes measure the frame and adapt a stored EV on the GPU (no readback)
//   run_post_pass     the final pass (post.glsl): exposure, tonemap, the output encode with a dither, the colour filter, fused
//
// A frame without a PostProcess and without Camera.bloom / Camera.colorFilter has an empty plan: no pass is declared and no target is
// made. The renderer declares the passes in build_graph (renderer_draw.cpp) in this order: bloom (bloom.h) -> automatic exposure ->
// the final pass -> (the HUD, drawn over the final picture in display space) -> the colour filter when the HUD went in between.
// The stack of one camera is all that is read today (the camera that draws first); a stack per camera job slots in by giving each
// job its own PostPlan and AutoExposure.
#pragma once

#include <cstdint>
#include <string>

#include "bloom.h"
#include "frame_graph.h"
#include "render_internal.h"
#include "transient_targets.h"

namespace fa::render {

// How the final picture is encoded for the display. Only the sRGB transfer function of an 8-bit display exists today; the values the HDR
// displays will need (scRGB, PQ) are added here and in post.glsl (uniform `p.z`) without touching the passes around it.
enum class OutputEncode : std::uint8_t { Sdr };

struct PostPlan {
    BloomSettings bloom;  // bloom.enabled = false: no bloom
    bool exposure = false;
    bool autoExposure = false;  // exposureMode auto: the exposure follows the picture
    float exposureEv = 0.0f;    // manual: the exposure in stops; auto: the compensation added to the measured one
    float minEv = -4.0f, maxEv = 4.0f;
    float adaptationSpeed = 2.0f;  // per second
    bool tonemap = false;
    int tonemapMode = 0;  // TonemapMode as an int: 0 none (a clip), 1 neutral, 2 aces, 3 agx, 4 reinhard
    int colorFilter = 0;  // Camera.colorFilter / PostProcess.colorFilterMode as an int, 0 none .. 5 tritanopia
    bool linear = false;  // SceneSettings.colorSpace linear: the game target holds linear light, the final pass encodes it
    OutputEncode output = OutputEncode::Sdr;

    // True when the final pass converts the picture (exposure, tonemap, or the encode of a linear scene): the pass is then `post`. A
    // frame that only has a colour filter is the plain filter pass; one that only has bloom has none.
    bool convert() const { return exposure || tonemap || linear; }
    bool any() const { return bloom.enabled || convert() || colorFilter != 0; }
};

// The plan of a camera (CameraInfo::postStack, null without one, and the bloom / colorFilter derived from it). `linear`: SceneSettings.colorSpace.
PostPlan make_post_plan(const CameraInfo& cam, bool linear);

// Camera.bloom* / PostProcess bloom fields -> supported ranges (sanitize_bloom for the stack): the knee and the dirt intensity too.
BloomSettings bloom_from_stack(const PostStack& stack);

// What the final pass draws (post.glsl): `convert` runs exposure, tonemap and the encode (the plan's), `filter` the colour filter
// (0 none; the picture is clamped for it); `expo` is the adapted-exposure image (the 1x1 of AutoExposure) or any 1x1 image when the
// exposure is not automatic. `pass` is the PassDesc of the destination (the caller sets its load and store actions); the pass draws
// one full-screen triangle and ends. `w` x `h`: the size of the destination in pixels (the dither pattern).
void run_post_pass(Gpu& gpu, const PostPlan& plan, bool convert, int filter, bool autoExposure, const PassDesc& pass,
                   sg_view src, sg_view expo, int w, int h);

// PostProcess.exposureMode auto. The adapted EV lives in a 1x1 RGBA16F target (two of them, taking turns: a pass cannot read what it
// writes); `exposure-luma` reduces the finished game image to 32x32 log-luminances and `exposure-adapt` moves the stored EV toward the
// one that brings the average to 18% grey, by 1 - exp(-speed * dt), clamped to [minEv, maxEv]. Nothing reads the GPU back, nothing
// depends on the CPU speed: the same frames (and dt) give the same exposure on every run. Needs float render targets (the GPU's
// scene format RGBA16F); without, the exposure stays manual (one logged warning).
class AutoExposure {
public:
    AutoExposure() = default;
    AutoExposure(const AutoExposure&) = delete;
    AutoExposure& operator=(const AutoExposure&) = delete;

    // Declares the two passes after the ones that draw `game` (the finished frame, texture view `srcTex`). Returns the resource that
    // holds the adapted EV (the final pass must read it), or an invalid one when the exposure cannot be automatic here. `serial` is
    // the frame's number: when the frame before did not declare these passes (the exposure was off, or the targets are new) the
    // measured exposure is taken at once, not approached. `dt` is the engine's frame time.
    ResourceId add_passes(FrameGraph& graph, TransientTargets& targets, Gpu& gpu, const PostPlan& plan, ResourceId game,
                          sg_view srcTex, float dt, std::uint64_t serial, int* drawCalls, const std::string& job);

    // The 1x1 image with the EV the last executed `exposure-adapt` wrote (what the final pass samples).
    sg_view ev_view() const { return ev_[cur_].texView; }
    // Destroys the targets and forgets the adaptation (the next frame measures again). Call while the graphics context is open.
    void release();

private:
    bool ensure_targets(Gpu& gpu);
    Target ev_[2];
    int cur_ = 0;  // the index of the target that holds the EV
    bool fresh_ = true;
    bool failed_ = false;
    bool warned_ = false;
    std::uint64_t lastSerial_ = 0;
    bool declaredBefore_ = false;
};

}  // namespace fa::render
