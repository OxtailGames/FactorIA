// Distance and height fog and sun shafts (PostProcess.fog*, PostProcess.sunShafts*; M71-D3b): two effects that work on the scene colour
// BEFORE the exposure, depth of field and bloom (they belong to the lighting of the scene) and read the prepass of their camera.
//
//   fog             prepass -> the camera's rectangle of the picture: fogColor * f blended over it (src + dst * (1 - f)); reads no colour.
//                   A full-screen draw INSIDE the main pass (draw_fog), after the opaque meshes and the sky and before the blended meshes
//                   and the quads of the world: those fog themselves (the forward fog of mesh_common.glsl and quad.glsl takes the same
//                   numbers), so a particle or a glass pane is fogged by its own distance, not by the opaque mesh behind it.
//   shafts-rays     picture + prepass -> 1/2 res (one channel): the radial scattering toward the sun's screen position (shaders/sun_shafts.glsl)
//   shafts-add      the rays x tint -> added onto the camera's rectangle of the picture
//
// Neither effect needs a scratch copy of the picture: the fog is an alpha blend and the shafts are additive. Every camera has its own plan and
// its own draws, so a split screen fogs each rectangle on its own. A camera whose fog is drawn does not also draw the forward fog of
// SceneSettings.fogColor / fogDensity on its opaque meshes (renderer_draw.cpp, scene_uniforms): the two never add up.
//
// FogFx owns its shaders and pipelines (created on first use, destroyed by release()), so a game that never turns an effect on compiles
// nothing. The plan is pure CPU (no GPU, tested without one).
#pragma once

#include <cstdint>
#include <string>
#include <vector>

#include "fa/core/math.h"
#include "fa/scene/camera_geometry.h"
#include "fa/scene/postprocess.h"

#include "bloom.h"
#include "frame_graph.h"
#include "render_internal.h"
#include "transient_targets.h"

namespace fa::render {

struct PostStack;
struct PostRect;
struct PrepassRef;

// What a camera's passes draw: the stack's numbers after clamping, in the camera's own numbers (its projection, its axes). Empty (any()
// false) when neither effect has anything to draw.
struct FogFxPlan {
    // ---- fog ----
    bool fog = false;
    float color[3]{0.5f, 0.6f, 0.7f};  // in the scene's colour space (a linear scene: linear light)
    float density = 0.0f;  // the distance fog's thickness (exponential squared, the law of SceneSettings.fogDensity)
    float start = 0.0f;    // world units from the camera before the fog begins
    float heightDensity = 0.0f;
    float heightBase = 0.0f;
    float heightFalloff = 0.1f;
    bool ortho = false;
    float proj[8]{};          // P00, P11, P02, P12, P03, P13, P32, P33 (see motion_blur.glsl)
    Vec3 eye{0, 0, 0};        // the camera's world position
    float axisY[3]{0, 1, 0};  // right.y, up.y, forward.y
    Vec3 forward{0, 0, -1};   // the camera's forward axis (the forward fog of an orthographic camera measures along it)
    // ---- sun shafts ----
    bool shafts = false;
    float sunUv[2]{0.5f, 0.5f};  // the sun's place in the camera's rectangle (top-left uv; may lie outside 0..1)
    float intensity = 0.0f;      // sunShaftsIntensity * the fade of the sun's place
    float threshold = 0.8f;
    float reach = 0.5f;                // the longest ray, in screen heights
    float tint[3]{1.0f, 0.95f, 0.8f};  // in the scene's colour space
    bool linearScene = false;

    bool any() const { return fog || shafts; }
};

// Does the stack's fog draw anything: the effect is on and has a density (distance or height)? A volume that blends it in from nothing starts
// with none.
bool fog_has_effect(const PostStack& stack);
// Do the stack's sun shafts draw anything: the effect is on, with an intensity and a length?
bool shafts_has_effect(const PostStack& stack);

// Where the sun is on the screen of a perspective camera: `towardSun` is the unit direction from the scene to the sun (the opposite of the
// directional light's forward). `uv` receives the place in the camera's rectangle (top-left uv, y down; it may lie outside 0..1) and `fade`
// 0 .. 1: 0 when the sun is behind the camera or far off the screen, 1 on the screen and in front. False (nothing written) for an
// orthographic camera (a sun at infinity has no place there) or a direction that is not finite.
bool sun_screen_position(const CameraGeometry& cam, Vec3 towardSun, Vec2* uv, float* fade);

// The plan of one camera. `linear`: the scene computes in linear light. `towardSun`: the direction to the sun (null: the scene has no
// directional light, or the camera lights by its studio rig: no shafts).
FogFxPlan make_fog_plan(const CameraGeometry& cam, const PostStack& stack, bool linear, const Vec3* towardSun);

class FogFx {
public:
    FogFx() = default;
    FogFx(const FogFx&) = delete;
    FogFx& operator=(const FogFx&) = delete;

    // Declares the passes of the sun shafts of one camera in `graph` (the fog is draw_fog, in the main pass). `game` is the imported resource
    // of the picture (texture view `srcTex`), `rect` the camera's rectangle of it (picW x picH), `dst` where the passes draw (as the bloom's
    // BloomTarget), `prepass` the camera's prepass (invalid: nothing is drawn). Each pass adds one to *drawCalls when it runs. Returns the
    // number of passes declared (0: nothing is drawn: no shafts, no prepass, shaders or targets the GPU cannot make; logged once).
    int add_passes(FrameGraph& graph, TransientTargets& targets, Gpu& gpu, const FogFxPlan& plan, const PostRect& rect,
                   int picW, int picH, ResourceId game, sg_view srcTex, const BloomTarget& dst,
                   const PrepassRef& prepass, int* drawCalls, const std::string& job);

    // Draws the fog of `plan` over the pass being drawn, whose target has `format` (the game image, multisampled or not): one full-screen
    // triangle that reads the prepass `prepassTex`. The caller has set the viewport and the scissor to the camera's rectangle. False (nothing
    // drawn) when the program cannot be made.
    bool draw_fog(Gpu& gpu, const FogFxPlan& plan, sg_view prepassTex, const TargetFormat& format);

    // Destroys the shaders and the pipelines; call while the graphics context is open.
    void release();
    // Forgets that creating the intermediate targets failed (the game target was resized or recreated).
    void forget_targets();

    enum class Prog { Fog, Rays, Add, Count };
    // The program, made on the first use (false: it cannot be made; logged once), and its pipeline for a target format.
    bool ready(Prog prog);
    sg_pipeline pipeline(Prog prog, const TargetFormat& format);

private:
    struct PipelineEntry {
        Prog prog;
        TargetFormat format;
        sg_pipeline pipeline;
    };
    sg_shader shaders_[int(Prog::Count)]{};
    int state_[int(Prog::Count)]{};  // 0 = not made yet, 1 = ready, -1 = failed (logged)
    std::vector<PipelineEntry> pipelines_;
    bool warnedTargets_ = false;
    std::vector<std::uint64_t> failed_;  // sizes whose half-resolution image could not be made
    std::vector<std::uint64_t> probed_;  // sizes whose image was made once: the pool is not probed again every frame
};

}  // namespace fa::render
