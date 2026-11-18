// The post-processing stack of a frame (M71): what the renderer draws from the PostStack of the camera that drives post, and the passes
// that are not the bloom's chain. Design:
//
//   PostPlan          the stack as the passes read it: sanitised numbers, nothing of the components (make_post_plan)
//   AutoExposure      PostProcess.exposureMode auto: two passes measure the frame and adapt a stored EV on the GPU (no readback)
//   run_post_pass     the final pass (post.glsl): the lens, exposure, tonemap, the output encode, the display-space effects of
//                     post_fx.h (grade, vignette, sharpen, grain), a dither, the colour filter, fused
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
#include "hdr_encode.h"
#include "post_fx.h"
#include "transient_targets.h"

namespace fa::render {

// The LUT strip the final pass binds (Assets::lut): the view and the layout of its slices.
struct LutInfo {
    sg_view view{};
    int size = 0, cols = 0, rows = 0;
};

// The prepass of the frame (renderer_draw.cpp, "prepass"): the depth and normals of the opaque meshes in one float image, for the effects that read
// them. A pass that does declares `res` in its reads (a transient: the graph orders it after the prepass and keeps it alive) and takes the
// image with target(). Colour r = linear view depth in world units (far-plane value 60000 where nothing was drawn), gb = the view-space
// normal, octahedral-encoded (see mesh_common.glsl, prepass_fs), a = 1 where a mesh was drawn, 0 elsewhere. Never multisampled.
struct PrepassRef {
    ResourceId res;
    const TransientTargets* targets = nullptr;
    bool valid() const { return res.valid() && targets != nullptr; }
    // The image inside a pass that has `res` in its reads; null when the pass did not declare it or the target is gone.
    const Target* target(const PassContext& c) const { return valid() ? targets->get(c.handle(res)) : nullptr; }
    static constexpr float kFarDepth = 60000.0f;
};

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
    bool linear =
        false;  // a linear scene that has exposure, a tonemap, an effect or a colour filter: the target holds linear light,
                // the final pass encodes it
    PostFx fx;  // the display-space effects and the lens (post_fx.h); empty when none is on
    std::string
        lut;  // fx.lut: the project path of the .cube file (the renderer looks it up and clears fx.lut when it cannot)
    LutInfo lutInfo;  // what the renderer found for `lut`
    // What the effects the renderer draws read from the prepass (post_effect_needs_depth / _normals of postprocess_resolve.h). The frame
    // draws the prepass when one is true (renderer_draw.cpp, plan_job); `prepass` is then valid for the passes after it.
    bool needsDepth = false, needsNormals = false;
    PrepassRef prepass;
    // The camera's view-projection of the frame before this one (motion blur reprojects with it); valid only when that frame drew the same
    // camera (`prevValid`), so a cut or a new camera never blurs.
    Mat4 prevViewProj;
    bool prevValid = false;

    // True when the final pass converts the picture (exposure, tonemap, or the encode of a linear scene): `post` runs steps 1 to 4.
    bool convert() const { return exposure || tonemap || linear; }
    // True when the final pass runs: a conversion or an effect. A frame that only has a colour filter is the plain filter pass; one
    // that only has bloom has none.
    bool final_pass() const { return convert() || fx.any(); }
    bool any() const { return bloom.enabled || final_pass() || colorFilter != 0; }
};

// The plan of a camera (CameraInfo::postStack, null without one, and the bloom / colorFilter derived from it). `linear`: SceneSettings.colorSpace.
// `forceEffects` (tests and the debug view): effects whose prepass inputs are needed as if the stack switched them on, a mask like
// PostStack::mask. needsDepth / needsNormals come from the effects the renderer draws (post_drawn_mask) among the stack's, and these.
// `frame`: World::frame(), the seed of an animated film grain (the renderer passes it; tests leave 0).
PostPlan make_post_plan(const CameraInfo& cam, bool linear, std::uint32_t forceEffects = 0, std::uint64_t frame = 0);

// Camera.bloom* / PostProcess bloom fields -> supported ranges (sanitize_bloom for the stack): the knee and the dirt intensity too.
BloomSettings bloom_from_stack(const PostStack& stack);

// What the final pass draws (post.glsl): `convert` is true for the final pass itself (not the colour-filter-only pass): it runs the
// plan's exposure, tonemap and encode (when plan.convert()) and plan.fx, `filter` the colour filter
// (0 none; the picture is clamped for it); `expo` is the adapted-exposure image (the 1x1 of AutoExposure) or any 1x1 image when the
// exposure is not automatic; `white`: any 1x1 white image (bound as the LUT when the plan has none). `pass` is the PassDesc of the destination (the caller sets its load and store actions); the pass draws
// one full-screen triangle and ends. `w` x `h`: the size of the destination in pixels (the dither pattern). `output`: what the frame is
// drawn for (hdr_encode.h); an HDR output with headroom runs the tonemap above paper white (tonemap_hdr), the rest the SDR one.
void run_post_pass(Gpu& gpu, const PostPlan& plan, bool convert, int filter, bool autoExposure, const PassDesc& pass,
                   sg_view src, sg_view expo, sg_view white, int w, int h, const OutputTarget& output = {});

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
