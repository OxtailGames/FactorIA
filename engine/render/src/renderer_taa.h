// Temporal antialiasing (PostEffect::TemporalAA, PostProcess.temporalAA*; M76-P2): the resolve of the jittered picture with the frames before.
// The camera draws the meshes (and the sky) with a sub-pixel jitter (fa/scene/jitter.h, CameraGeometry::apply_jitter); this pass blends that
// picture with its own result of the frame before, reprojected to where the surfaces were, so the samples of many frames land in one pixel.
//
//   taa-resolve   picture + prepass + velocity + history -> the next history image (rgb = the colour, a = the linear depth of its pixel)
//   taa-output    history -> the camera's rectangle of the picture, sharpened (PostProcess.temporalAASharpen)
//
// Where it sits: in the post stack at the TemporalAA slot: after the sun shafts (and the custom passes "before:depthOfField" that follow them),
// before depth of field, motion blur, bloom and the final pass, at the render resolution, on every backend (two full-screen fragment passes;
// never a compute shader). With the effect off nothing of this exists: no pass, no image, no jitter.
//
// The history is two images per camera (RGBA16F, ping-pong; RGBA8 without the depth where the GPU cannot render to half floats), the size of the
// camera's rectangle, owned here and freed when the camera stops asking for a frame. It is dropped (the next frame shows its own picture alone,
// jittered, and starts a new history) on: a cut (the camera of the frame before is not the camera of this one: PostPlan::prevValid), a resize or
// a change of the render scale (the images have another size), a floating-origin shift, a frame the effect did not run for the camera (it was
// off, or the camera drew no picture), another scene (a load or a reload), a camera whose stack lost the effect. docs/UPSCALING.md and
// docs/design/ARCHITECTURE_RENDERING_TEMPORAL.md ("Motion vectors and jitter (M76)") say the same.
//
// The resolve is written to be shared (taa_shared.glsl): the temporal upscaler of M76-P4 calls TaaFx::resolve with the picture at the render
// resolution and the history at the output resolution (TaaResolveInput::inW/inH, outW/outH).
#pragma once

#include <cstdint>
#include <map>
#include <memory>
#include <string>
#include <vector>

#include "fa/core/math.h"
#include "fa/scene/camera_geometry.h"

#include "bloom.h"
#include "frame_graph.h"
#include "render_internal.h"
#include "transient_targets.h"

namespace fa::render {

struct PostStack;
struct PostRect;
struct PrepassRef;
struct VelocityRef;

// What a camera's TAA does this frame: the stack's numbers after clamping, the matrices that reproject, what decides whether the history of the
// frame before still holds. `on` false: nothing is drawn.
struct TaaPlan {
    bool on = false;
    float gamma = 1.0f;          // temporalAAVarianceGamma, 0.5 .. 2
    float feedback = 0.9f;       // temporalAAFeedback, 0.5 .. 0.98
    float sharpen = 0.25f;       // temporalAASharpen, 0 .. 1
    float reactiveScale = 1.0f;  // temporalAAReactiveScale, 0 .. 4
    Vec2 jitterPx{0, 0};         // the jitter this frame's picture was drawn with, in render pixels (x right, y down)
    bool prevValid =
        false;  // the camera drew the frame before and no cut happened since: its history can be reprojected
    Mat4
        prevFromView;  // a view-space position of this frame -> the clip position it had on the frame before (unjittered)
    float proj[8]{};                 // P00, P11, P02, P12, P03, P13, P32, P33 of the unjittered projection
    std::uint64_t camKey = 0;        // the camera's entity (its history is keyed by it)
    std::uint64_t serial = 0;        // the game frame (Renderer::Impl::postSerial)
    std::uint64_t sceneKey = 0;      // the scene's identity: another one drops the history
    std::uint64_t originShifts = 0;  // the floating-origin rebases so far: another number drops the history
};

// The plan of one camera: `on` when the stack has TemporalAA, the frame is one of the game's (`gameFrame`: a capture of the world between two
// of them is not jittered and neither reads nor writes a history) and the renderer can draw it (`available`: the shaders compiled and the
// histories fit). Pure CPU: tested without a GPU. A number that is not finite takes the default of the field.
TaaPlan make_taa_plan(const CameraInfo& cam, const PostStack& stack, bool gameFrame, bool available,
                      std::uint64_t camKey, std::uint64_t serial, std::uint64_t sceneKey, std::uint64_t originShifts,
                      const Mat4& prevViewProj, bool prevValid);

// The history key of the temporal upscaler (M76-P4): one history for the frame, at the output resolution, in the same TaaFx as the cameras'
// (no entity has this id).
inline constexpr std::uint64_t kUpscaleCamKey = ~std::uint64_t(0);

// The plan of the temporal upscaler for the frame's one camera: the numbers of the camera's stack when it has TemporalAA (feedback,
// variance gamma, reactive scale, sharpen), else the defaults of PostProcess (`stack` may be null: no post stack). `sharpness` is
// UpscalerSettings::sharpness (0..1, 0.5 = the stack's own sharpen): the output sharpen is temporalAASharpen * sharpness / 0.5, clamped to 0..1.
// `camKey` is kUpscaleCamKey. Pure CPU.
TaaPlan make_upscale_taa_plan(const CameraInfo& cam, const PostStack* stack, bool gameFrame, bool available,
                              float sharpness, std::uint64_t serial, std::uint64_t sceneKey, std::uint64_t originShifts,
                              const Mat4& prevViewProj, bool prevValid);

// What one resolve pass reads (the temporal upscaler fills the same). A null view is not bound; `dummy` stands in for it (any texture view).
struct TaaResolveInput {
    sg_view color{};  // the picture of this frame, jittered
    sg_view
        depth{};  // the prepass of the camera (r = linear depth, a = coverage), the size of `color`; null: the depth is taken as far away
    sg_view
        velocity{};  // PostPlan::velocity (rg = uvPrev - uvCurr, unjittered), the size of `color`; null: the camera's own movement only
    sg_view reactive{};  // the reactive mask (r, 0..1, the size of `color`); null: no mask
    sg_view
        history{};  // the resolved image of the frame before, the size of the output; null (with historyValid false): none
    sg_view dummy{};         // bound in place of a view that is null
    int inW = 1, inH = 1;    // the size of `color` in pixels (the camera's rectangle)
    int outW = 1, outH = 1;  // the size of the history and of the image the pass draws
    float rect[4] = {
        0, 0, 1, 1};  // the camera's rectangle of `color` as fractions of that image: x, y, w, h (0 0 1 1: all of it)
    Vec2 jitterPx{0, 0};
    bool historyValid = false;     // `history` holds the frame before (a cut, a resize, ... clear it)
    bool historyHasDepth = false;  // the alpha of `history` is the linear depth (RGBA16F history)
    float gamma = 1.0f, feedback = 0.9f, reactiveScale = 1.0f;
    Mat4 prevFromView;
    float proj[8]{};
};

class TaaFx {
public:
    TaaFx() = default;
    TaaFx(const TaaFx&) = delete;
    TaaFx& operator=(const TaaFx&) = delete;

    // Declares the passes of one camera in `graph`: after the passes that draw `game` (the imported resource of the picture, texture view
    // `srcTex`) and before depth of field. `rect`: the camera's rectangle of the picture (picW x picH); `prepass`, `velocity`, `reactive`:
    // its images (invalid: not read); `dst`: where the result goes, as the bloom's (BloomTarget); `dummy`: any texture view. Each pass adds
    // one to *drawCalls when it runs. Returns the number of passes declared (0: nothing is drawn: the history cannot be made or the shaders
    // failed; logged once, and unavailable() is true from then on, so the cameras are not jittered for a pass that never resolves them).
    int add_passes(FrameGraph& graph, Gpu& gpu, const TaaPlan& plan, const PostRect& rect, int picW, int picH,
                   ResourceId game, sg_view srcTex, const BloomTarget& dst, const PrepassRef& prepass,
                   const VelocityRef& velocity, const PrepassRef& reactive, sg_view dummy, int* drawCalls,
                   const std::string& job);

    // The resolve pass of `in`, drawn into the whole of `into` (the history image of the frame, `outW` x `outH`): the entry the temporal upscaler
    // shares. False (nothing drawn) when the target is gone or the program is not ready.
    bool resolve(Gpu& gpu, const PassDesc& into, const TaaResolveInput& in);

    // The temporal upscaler (M76-P4): resolves `in` (the jittered picture at the render resolution, inW x inH; the history is at outW x outH)
    // with the history kept under kUpscaleCamKey and draws the sharpened result into the whole of `out`. The fields of `in` that the plan
    // knows (jitter, gamma, feedback, matrices) are taken from `plan`; `history` and `historyValid` are set here. The history restarts (the
    // frame shows its own picture alone) when it is not the one of the frame before (PostPlan rules: a cut, another scene, a floating-origin
    // shift, no frame in between), when the image size changed, or when `configKey` (the render size and the quality) differs from the last
    // frame's. False (nothing drawn: `out` is untouched) when the shaders or the history are not available; the caller then stretches.
    bool upscale(Gpu& gpu, const TaaPlan& plan, TaaResolveInput in, std::uint64_t configKey, Target& out);

    // True from the first failure (shader that did not compile, history of a camera the GPU or the budget refused) to release() or the
    // next forget_targets(): a camera then draws without TAA and without the jitter. ready() compiles the shaders on its first call (the
    // renderer calls it before it jitters a camera).
    bool unavailable() const { return state_ < 0 || refused_; }
    // The same for the temporal upscaler (M76-P4): a history of the output size that was refused stops the upscaler only, not the
    // cameras that antialias themselves (they have their own, smaller, histories and their own flag).
    bool upscale_unavailable() const { return state_ < 0 || upscaleRefused_; }
    bool ready();

    // Makes (or keeps) the upscaler's history for an output of outW x outH now, before the frame is jittered for it: false when the budget or
    // the GPU refuse it (logged once, upscale_unavailable() is then true), so the frame is drawn without the jitter and goes through the
    // spatial upscaler instead of being drawn jittered and never resolved. `serial`: the renderer's postSerial before this frame counts. Cheap when the history exists.
    bool reserve_upscale(int outW, int outH, std::uint64_t serial);
    // Tests: the bytes the histories of all the cameras and of the upscaler may take together (0: the default, 1 GB; 256 MB on wasm32).
    void set_budget(std::uint64_t bytes) { budgetOverride_ = bytes; }

    // Frees the history of every camera that did not run a resolve in the frame before `serial` (a camera with another stack, a closed window).
    void sweep(std::uint64_t serial);
    // Drops what a camera accumulated: its next frame shows its own picture (0: every camera). Nothing calls it today: the history restarts by
    // itself when the plan says it does not hold (a cut, a scene, a shift of the origin, a size); it is the hook for a caller that knows better.
    void reset(std::uint64_t camKey = 0);
    // Tests and the debug output: the history images alive, whether the last frame of `camKey` blended with its history (false: it started
    // a new one), how often a history was started, and the format the histories use.
    int history_image_count() const;
    bool last_used_history(std::uint64_t camKey) const;
    int resets() const { return resets_; }
    sg_pixel_format history_format() const { return format_; }
    // Tests: use an 8-bit history as a GPU without half-float targets does.
    void force_rgba8(bool force);

    // Destroys the shaders, the pipelines and the histories; call while the graphics context is open.
    void release();
    // The GPU lost its targets or the window was resized: the histories go (they are made again for the new size).
    // Frees the histories (a new render size makes the images again). `keepUpscale` leaves the temporal upscaler's: it is at the output size and
    // a step of the dynamic resolution (the render size only) does not change what it holds.
    void forget_targets(bool keepUpscale = false);

    enum class Prog { Resolve, Out, Count };
    sg_pipeline pipeline(Prog prog, const TargetFormat& format);

private:
    struct PipelineEntry {
        Prog prog;
        TargetFormat format;
        sg_pipeline pipeline;
    };
    struct Slot {
        Target img[2];
        int w = 0, h = 0;
        sg_pixel_format format = SG_PIXELFORMAT_NONE;
        int last = -1;              // the image the last resolve wrote (-1: none yet)
        bool wrote = false;         // img[last] holds a finished frame
        std::uint64_t serial = 0;   // the frame it was written in
        std::uint64_t planned = 0;  // the last frame that asked for it
        std::uint64_t sceneKey = 0;
        std::uint64_t originShifts = 0;
        std::uint64_t configKey = 0;  // the temporal upscaler's render size and quality of the frame in img[last]
        bool usedHistory = false;     // the last resolve blended with the history
    };
    sg_shader shaders_[int(Prog::Count)]{};
    std::vector<PipelineEntry> pipelines_;
    int state_ = 0;                // 0 = shaders not made yet, 1 = ready, -1 = failed (logged)
    bool refused_ = false;         // a camera's history was refused (budget or GPU)
    bool upscaleRefused_ = false;  // the temporal upscaler's was
    std::uint64_t budgetOverride_ = 0;
    bool forceRgba8_ = false;
    bool warnedFormat_ = false;
    int resets_ = 0;
    sg_pixel_format format_ = SG_PIXELFORMAT_NONE;
    std::map<std::uint64_t, std::shared_ptr<Slot>> slots_;

    sg_pixel_format pick_format();
    std::shared_ptr<Slot> slot_for(std::uint64_t camKey, int w, int h, sg_pixel_format format, const std::string& job);
    void destroy(Slot& s);
    bool output(Gpu& gpu, const PassDesc& pd, sg_view history, int w, int h, float sharpen, const int* part);
};

}  // namespace fa::render
