// Depth of field and camera motion blur (PostProcess.depthOfField*, PostProcess.motionBlur*; M71-D2): two effects that work on the
// scene colour BEFORE bloom and the final pass (they blur light, not the encoded picture) and read the prepass of their camera.
//
//   dof-down        picture + prepass -> 1/2 res: the 2x2 block and its signed circle of confusion (shaders/dof.glsl)
//   dof-gather      1/2 res -> 1/2 res: the disc blur (near field in front, far field behind)
//   dof-composite   picture + prepass + blur -> a scratch image of the camera's size
//   motion-blur     picture (or the scratch) + prepass -> the scratch (or the camera's rectangle of the picture): the camera's own motion
//                   (PostProcess.motionBlurMode "camera", or no velocity image), shaders/motion_blur.glsl
//   motion-velocity, motion-tile-x, motion-tile-y, motion-blur   the per-object blur (mode "object" with a velocity image): the velocity
//                   image + prepass -> V (blur vector and depth), V -> the longest vector of every block (two passes), then the gather
//                   picture + V + blocks -> the scratch (or the picture), shaders/motion_object.glsl
//   dof-copy / motion-copy  the scratch -> the camera's rectangle of the picture
//
// A pass cannot read what it writes, so the effects draw into one scratch transient (the picture's format, the camera's size) and the last of
// them draws back into the camera's rectangle. Every camera has its own passes and its own focus: a split screen blurs each rectangle on its
// own. The autofocus is state of the renderer (SceneFx::plan): the focus distance of each camera, moved toward its target by the engine clock.
//
// SceneFx owns its shaders and pipelines (created on first use, destroyed by release()), so a game that never turns an effect on compiles
// nothing. Pure CPU parts (the plan, the focus smoothing) need no GPU and are tested without one.
#pragma once

#include <cstdint>
#include <string>
#include <unordered_map>
#include <vector>

#include "fa/core/math.h"
#include "fa/scene/camera_geometry.h"
#include "fa/scene/world.h"

#include "bloom.h"
#include "frame_graph.h"
#include "render_internal.h"
#include "transient_targets.h"

namespace fa::render {

struct PostStack;
struct PostRect;
struct PrepassRef;
struct VelocityRef;

// What a camera's passes draw: the stack's numbers after clamping, the focus of this frame, the matrices of the movement. Empty (any() false) when
// neither effect is on.
struct SceneFxPlan {
    bool dof = false;
    float focus = 10.0f;     // focus distance of this frame in world units (the autofocus already applied)
    float halfRange = 2.5f;  // half of the sharp band around `focus`
    float nearRamp = 10.0f;  // world units over which the blur in front of the band grows to its largest
    float farRamp = 10.0f;   // the same behind it
    float nearPx = 0.0f;     // largest blur in front, in physical pixels (design pixels * the render scale)
    float farPx = 0.0f;      // largest blur behind
    bool bokeh = true;
    bool motion = false;
    float shutter = 0.5f;  // the part of the screen movement that is blurred
    int motionTaps = 8;    // most taps along the movement
    // The per-object blur (PostProcess.motionBlurMode "object"): the velocity image gives the movement of every pixel. add_passes draws it
    // only when the camera has a velocity image and the shaders built; else the camera-only blur above.
    bool objects = false;
    float maxRadiusPx =
        24.0f;  // how far a pixel's blur reaches on each side, physical pixels (1 .. 128); the longest streak is twice it
    // The matrices of the movement: a view-space position of this frame -> the clip position it had in the frame before
    // (previous view-projection * inverse view), and the projection's terms the shader needs (see motion_blur.glsl).
    Mat4 prevFromView;
    float proj[8]{};  // P00, P11, P02, P12, P03, P13, P32, P33

    bool any() const { return dof || motion; }
};

// The focus of the next frame: `current` moved toward `target` by 1 - exp(-speed * dt), so it depends on the engine clock only (never on the
// speed of the CPU). A speed of 0 or less stays where it is, a non-finite input leaves `current`.
float smooth_focus(float current, float target, float speed, float dt);

// The number of taps of the gather for a blur radius of `radiusHalfPx` pixels of the half-resolution image: a count that depends on the settings
// only (8 .. 64).
int dof_gather_taps(float radiusHalfPx);

class SceneFx {
public:
    SceneFx() = default;
    SceneFx(const SceneFx&) = delete;
    SceneFx& operator=(const SceneFx&) = delete;

    // The plan of the camera `camKey` (Entity::bits()) for frame `serial`: reads the stack's numbers, moves the camera's focus toward the
    // autofocus target (its view depth, in `cam.view`; none, a destroyed entity or a target behind the camera: the stack's focus distance) and
    // takes the matrices of the movement from `prevViewProj` when `prevValid` (the frame before drew this camera; else no motion blur: the first
    // frame and a cut never blur). `designScale`: physical pixels per design pixel. `dt`: the engine's frame time. Forgets the focus of cameras
    // that did not ask for two frames.
    SceneFxPlan plan(World& world, const CameraInfo& cam, const PostStack& stack, std::uint64_t camKey,
                     std::uint64_t serial, float dt, float designScale, const Mat4& prevViewProj, bool prevValid);

    // Declares the passes of one camera in `graph`: after the passes that draw `game` (the imported resource of the picture, texture view
    // `srcTex`), before bloom. `rect`: the camera's rectangle of the picture (picW x picH); `prepass`: its prepass (invalid: nothing is drawn,
    // the effects need the depth); `dst`: where the result goes, as the bloom's (BloomTarget). Each pass adds one to *drawCalls when it runs.
    // `velocity`: the velocity image of the camera (PostPlan::velocity; invalid when none was drawn: the blur is the camera-only one).
    // Returns the number of passes declared (0: nothing is drawn: no effect, no prepass, shaders or targets the GPU cannot make; logged once).
    int add_passes(FrameGraph& graph, TransientTargets& targets, Gpu& gpu, const SceneFxPlan& plan,
                   const PostRect& rect, int picW, int picH, ResourceId game, sg_view srcTex, const BloomTarget& dst,
                   const PrepassRef& prepass, const VelocityRef& velocity, int* drawCalls, const std::string& job);

    // One full-screen copy of `src` (a texture view of the picture's format) into the pass `pd`; when `part` is not
    // null only into that rectangle (x, y, w, h in pixels of the destination: a camera's rectangle of the picture). The
    // copy of a custom post chain (renderer_custom_post.h) uses it. False (nothing drawn) when the target of the pass
    // is gone or the copy program is not ready.
    bool copy_into(Gpu& gpu, const PassDesc& pd, sg_view src, const int* part);

    // The focus distance the camera `camKey` has now (a NaN when it has none): what the tests and the debug output read.
    float focus_of(std::uint64_t camKey) const;

    // Destroys the shaders and the pipelines; call while the graphics context is open.
    void release();
    // Forgets that creating the intermediate targets failed (the game target was resized or recreated).
    void forget_targets();

    // The programs, and their pipelines for a target format (made on the first use; null when the program cannot be made). Used by the passes.
    enum class Prog { Down, Gather, Composite, Copy, Motion, ObjVel, ObjTile, ObjGather, Count };
    bool ready();
    // The three programs of the per-object blur, made on its first use (a game that only has the camera blur never compiles them); false
    // when they could not be made (logged once: the blur is then the camera-only one).
    bool ready_objects();
    sg_pipeline pipeline(Prog prog, const TargetFormat& format);

private:
    struct PipelineEntry {
        Prog prog;
        TargetFormat format;
        sg_pipeline pipeline;
    };
    sg_shader shaders_[int(Prog::Count)]{};
    std::vector<PipelineEntry> pipelines_;
    int state_ = 0;     // 0 = shaders not made yet, 1 = ready, -1 = failed (logged)
    int objState_ = 0;  // the same for the per-object blur's programs
    struct Focus {
        float distance = 10.0f;
        std::uint64_t frame = 0;
    };
    std::unordered_map<std::uint64_t, Focus> focus_;
    bool warnedTargets_ = false;
    // Sizes whose intermediate targets could not be made (not tried again every frame).
    std::vector<std::uint64_t> failed_;
    // Sizes whose intermediate targets were made once: the pool is not probed again every frame.
    std::vector<std::uint64_t> probed_;
};

}  // namespace fa::render
