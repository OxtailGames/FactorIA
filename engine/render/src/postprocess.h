// The post-processing stack of a frame (M71): what the renderer draws from the PostStack of the camera that drives post, and the passes
// that are not the bloom's chain. Design:
//
//   PostPlan          the stack as the passes read it: sanitised numbers, nothing of the components (make_post_plan)
//   AutoExposure      PostProcess.exposureMode auto: two passes measure the frame and adapt a stored EV on the GPU (no readback)
//   run_post_pass     the final pass (post.glsl): the lens, exposure, tonemap, the output encode, the display-space effects of
//                     post_fx.h (grade, vignette, sharpen, outline, pixelate, posterize, grain), a dither, the colour filter, fused
//
// A frame without a PostProcess has an empty plan: no pass is declared and no target is
// made. The renderer declares the passes in build_graph (renderer_draw.cpp) in this order: bloom (bloom.h) -> automatic exposure ->
// the final pass -> (the HUD, drawn over the final picture in display space) -> the colour filter when the HUD went in between.
// Every camera job has its own PostPlan, prepass, coverage image and AutoExposure (M71-C3a): its final pass draws into the camera's
// rectangle of the picture (PostRect), the effects run in camera-local coordinates and the prepass and the coverage image have the size
// of that rectangle. Bloom and the colour filter stay one per frame, from the camera that draws first (PostProcess bloom and colorFilter).
#pragma once

#include <cstdint>
#include <string>

#include "bloom.h"
#include "frame_graph.h"
#include "render_internal.h"
#include "hdr_encode.h"
#include "post_fx.h"
#include "renderer_ssr.h"
#include "renderer_custom_post.h"
#include "renderer_dof.h"
#include "renderer_fog.h"
#include "renderer_taa.h"
#include "renderer_volumetric.h"
#include "subsurface.h"
#include "transient_targets.h"

namespace fa::render {

// The LUT strip the final pass binds (Assets::lut): the view and the layout of its slices.
struct LutInfo {
    sg_view view{};
    int size = 0, cols = 0, rows = 0;
};

// A camera's rectangle of the picture in physical pixels, top-left origin. w <= 0 (the default) means the whole picture: the pass then
// runs exactly as it did before cameras had a rectangle.
struct PostRect {
    int x = 0, y = 0, w = 0, h = 0;
    // True when this is the whole picture of `picW` x `picH`.
    bool whole(int picW, int picH) const { return w <= 0 || h <= 0 || (x == 0 && y == 0 && w == picW && h == picH); }
    bool operator==(const PostRect& o) const { return x == o.x && y == o.y && w == o.w && h == o.h; }
};

// A camera's rectangle as fractions of the picture: x, y = the corner, w, h = the size.
struct PostRectUv {
    float x = 0.0f, y = 0.0f, w = 1.0f, h = 1.0f;
};
// The rectangle in top-left uv (the shader's camera-local screen space maps into it). Without a rectangle, or without the picture's size: all of it.
PostRectUv post_rect_uv(const PostRect& rect, int picW, int picH);
// The same rectangle in the uv of the image of a backend whose render targets have their origin at the bottom (`gl`): what a pass that reads
// the picture without the shader's flip_v (the exposure measure) needs. Metal and D3D11: the same as post_rect_uv.
PostRectUv post_rect_uv_native(const PostRect& rect, int picW, int picH, bool gl);
// What post.glsl src_uv computes: the uv of the picture's image that the pixel at camera-local top-left uv `s` reads, for a pass over `rect`
// (`w` x `h` = the rectangle's size in pixels, the half-texel clamp keeps the read inside the camera's own pixels).
Vec2 post_source_uv(Vec2 s, const PostRect& rect, int picW, int picH, bool gl, int w, int h);

// The prepass of a camera (renderer_draw.cpp, "prepass"): the depth and normals of the opaque meshes in one float image, for the effects that read
// them. A pass that does declares `res` in its reads (a transient: the graph orders it after the prepass and keeps it alive) and takes the
// image with target(). Colour r = linear view depth in world units (far-plane value 60000 where nothing was drawn), gb = the view-space
// normal, octahedral-encoded (see mesh_common.glsl, prepass_fs), a = 1 where a mesh was drawn, 0 elsewhere. Never multisampled. The image
// has the size of the camera's rectangle (PostPlan::rect, whole = the picture's size), so the final pass of that camera reads it by its
// camera-local pixel (PostPlan::rect).
struct PrepassRef {
    ResourceId res;
    const TransientTargets* targets = nullptr;
    bool valid() const { return res.valid() && targets != nullptr; }
    // The image inside a pass that has `res` in its reads; null when the pass did not declare it or the target is gone.
    const Target* target(const PassContext& c) const { return valid() ? targets->get(c.handle(res)) : nullptr; }
    static constexpr float kFarDepth = 60000.0f;
};

// The velocity image of a camera (M76; the contract of "Motion vectors and jitter (M76)" in docs/design/ARCHITECTURE_RENDERING_TEMPORAL.md). The
// depth prepass writes it as its second attachment when PostPlan::needsVelocity (request_velocity()); PostPlan::velocity is invalid when
// nothing asked or the prepass did not run. What the meshes, instances, terrain, foliage and impostors write is the motion of the object; the
// skinned meshes (of up to 64 joints, the engine maximum) and custom vertex() materials write it too (M76-P1b); a skin of more than 64 joints holds kNone. The alpha-tested cutout quads of the world (sprites, shapes, tiles, text) write their translation in a
// pass after the prepass (M76-P1d, "quad-velocity"); a blended or additive quad and a particle write none (they are in PostPlan::reactive). RG16F at the render resolution of the camera's rectangle
// (the size of the prepass). rg = uvPrev - uvCurr: where the surface drawn at this pixel was on the previous frame's image minus where it is
// now, in uv units (0..1 over the camera's rectangle, y down), computed from the UNJITTERED matrices (the jitter of the two frames is not part
// of a motion; the resolve adds it back with PostPlan::jitterNdc / prevJitterNdc). A pixel no object wrote holds kNone in both channels: the
// resolve then reprojects with the camera alone, from the depth of the prepass and PostPlan::prevViewProj. A pass reads a value only when
// it is finite and |value| < kValidLimit; the writer clamps a real motion to +-kMaxMotion.
struct VelocityRef : PrepassRef {
    static constexpr float kNone = 1024.0f;       // "no object wrote here" (exact in half float)
    static constexpr float kValidLimit = 512.0f;  // below it a value is a motion, from it up it is the sentinel
    static constexpr float kMaxMotion = 4.0f;     // a real motion is clamped to this many images
    static bool is_none(float v) { return !(v < kValidLimit && v > -kValidLimit); }  // also true for NaN
};

// The ambient occlusion of a camera (PostProcess.ssao*, drawn by renderer_ssao.h) after clamping to the supported ranges.
struct SsaoSettings {
    bool enabled = false;    // false: no pass (also for an intensity or a radius of 0)
    int quality = 1;         // SsaoQuality as an int: 0 low, 1 medium, 2 high, 3 ultra
    float intensity = 1.0f;  // 0..4
    float radius = 0.5f;     // world units
    bool view = false;       // the debug view ao: the occlusion is painted over the picture instead of darkening it
};
// What the stack asks for: enabled when the stack switches the effect on with an intensity and a radius above 0.
SsaoSettings ssao_from_stack(const PostStack& stack);
// The settings of the debug view ao: the stack's own when it has the effect on, else the defaults of the component; `view` set.
SsaoSettings ssao_debug_settings(const SsaoSettings& own);

// The stages of the final pass (post.glsl) in the order it runs them, for the cuts a custom pass at a display-referred
// place makes (post_custom.h, post_slot_is_ldr): the place after stage `i` is PostSlot(int(PostSlot::AfterTonemap) +
// i). A stage that has nothing to do for the plan is not active; the pass is cut only where a custom pass sits, and a
// frame without one runs every stage in one pass.
enum PostStage : int {
    kStageScene =
        0,        // the lens, the aberration, the transient screen warps; the exposure, the tonemap and the sRGB encode
    kStageGrade,  // the colour grading and its LUT
    kStageVignette,
    kStageSharpen,
    kStageOutline,
    kStagePosterize,
    kStageGrain,
    kStageTail,  // the flash / fade, the dither and the colour filter: always the last, and the one that writes the destination
    kPostStageCount
};

// Which stages one pass of the final pass runs: first..last.
struct PostSlice {
    int first = kStageScene, last = kStageTail;
    bool has(int stage) const { return stage >= first && stage <= last; }
    bool whole() const { return first == kStageScene && last == kStageTail; }
    bool tail() const { return last == kStageTail; }
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
    int colorFilter = 0;  // PostProcess.colorFilterMode as an int, 0 none .. 5 tritanopia
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
    // M76: this camera asks for the velocity image (VelocityRef). The prepass then writes the motion vectors into a second attachment (the
    // frame does it when the GPU can make the image: `velocity` below is valid for the passes after the prepass, invalid otherwise).
    // Whoever needs it calls request_velocity(): make_post_plan sets needsVelocity (without pinning it) for an effect that reads it
    // (post_effect_needs_velocity), the renderer calls it for the debug view "motionVectors" and the test hook; a later effect or upscaler that is drawn adds itself to that table.
    // The velocity image needs the prepass but not the depth or normals it holds: a consumer that reads them asks for those itself.
    bool needsVelocity = false;
    // Set by request_velocity(): something other than the temporal antialiasing wants it (the object motion blur, the debug view, the test
    // hook, the temporal upscaler). make_post_plan sets needsVelocity alone for the temporal antialiasing, so that a frame that cannot resolve
    // it (a capture) can take the request back (renderer_draw.cpp, plan_job) without taking the others'.
    bool velocityPinned = false;
    void request_velocity() { needsVelocity = velocityPinned = true; }
    // M76-P1d: the reactive mask (`reactive` below) is wanted too: the temporal passes (TemporalAA, the temporal upscaler) call it next to
    // request_velocity(); the debug view and the test hook ask for the velocity alone.
    bool needsReactive = false;
    void request_reactive() { needsReactive = true; }
    std::uint32_t readMask =
        0;  // the effects (PostEffect bits) whose prepass bits those are: the frame drops the sun shafts' when no sun shows
    PrepassRef prepass;
    // The ambient occlusion (renderer_ssao.h): declared before the bloom, over this camera's rectangle, when `enabled` and the prepass was
    // made. Its prepass bits are in needsDepth / needsNormals.
    SsaoSettings ssao;
    // The sprite outline's image (renderer_draw.cpp, "sprite-coverage"): an RGBA8 image of the picture's size, a = how much of the pixel the
    // 2D world drew (alpha blending accumulates it), cleared to 0. Made only when fx.outline_sprite(); valid for the passes after it.
    PrepassRef coverage;
    // The camera's rectangle of the picture (whole: the camera covers all of it). The final pass draws into it, the prepass and the
    // coverage image have its size.
    PostRect rect;
    // The scene is linear (what make_post_plan was given): kept to settle `linear` again when skip_outline() takes an effect away.
    bool sceneLinear = false;
    // The camera's view-projection of the frame before this one (motion blur reprojects with it); valid only when that frame drew the same
    // camera (`prevValid`), so a cut or a new camera never blurs.
    Mat4 prevViewProj;
    bool prevValid = false;
    // M76, the jitter of the temporal passes (fa/scene/jitter.h). All unjittered / zero while the camera does not jitter (today always).
    // jitterPx: the sub-pixel shift this frame's picture was drawn with, in render pixels (x right, y down); jitterNdc: the same as an offset
    // of clip x / w and y / w. prevJitterPx / prevJitterNdc: the shift of the frame `prevViewProj` belongs to (valid with prevValid).
    // prevJitteredViewProj: that frame's viewProj WITH its jitter, what its history image was drawn with.
    Vec2 jitterPx{0, 0}, jitterNdc{0, 0};
    Vec2 prevJitterPx{0, 0}, prevJitterNdc{0, 0};
    Mat4 prevJitteredViewProj;
    // The camera's velocity image (VelocityRef), valid for the passes after the pass that writes it; invalid when none does.
    VelocityRef velocity;
    // The camera's reactive mask (M76-P1d, R8 at the size of the prepass, 0..1): where the 2D quads of the world that are not an opaque surface
    // (blended particles, the quads flagged reactive) are, so the temporal resolve trusts the current frame there (taa_resolve lowers the
    // weight of its history by it). Invalid when nothing asked, the GPU cannot make the image or no quad is reactive in the frame.
    PrepassRef reactive;
    // Screen-space reflections of this camera (renderer_ssr.h): drawn on the scene colour before the exposure and the bloom; empty when off.
    SsrPlan ssr;
    // Depth of field and motion blur of this camera (renderer_dof.h): drawn on the scene colour before bloom; empty when neither is on.
    SceneFxPlan sceneFx;
    // Temporal antialiasing of this camera (renderer_taa.h): drawn after the sun shafts, before depth of field; off (taa.on false) when the stack has
    // no TemporalAA, the frame is not one of the game's or the renderer cannot draw it.
    TaaPlan taa;
    // Distance and height fog and sun shafts of this camera (renderer_fog.h): drawn on the scene colour before depth of field; empty when neither is on.
    FogFxPlan fogFx;
    // The volumetric fog of this camera (renderer_volumetric.h): the march is declared in the camera's own job (it reads the shadow atlas of that job), the apply pass
    // with the stack after the main pass; `volImage` is the march image between them. Off (vol.on false) when the camera draws no volumetric fog.
    VolPlan vol;
    ResourceId volImage;
    // The subsurface scattering of this camera (renderer_subsurface.h): the sss-draw pass is declared in the camera's own job, the blur and add passes
    // with the stack after the main pass; `sssLight` and `sssParams` are the images between them. Off (sss.on false) when no mesh scatters or the
    // camera cannot draw it.
    SssPlan sss;
    ResourceId sssLight, sssParams;
    // The custom post passes of this camera (renderer_custom_post.h): the materials of PostProcess.customPasses that
    // built, each at its position in the stack. Empty when none. Their prepass bits are set by plan_job (needsDepth /
    // needsNormals) when one reads the depth.
    CustomPostPlan custom;
    // Some custom pass sits at a display-referred place (custom.any_ldr()): the final pass runs, cut in pieces there
    // (PostSlice), even when the stack has nothing else for it, and a linear scene is converted by it.
    bool customLdr = false;

    // Settles `customLdr` from `custom` (after the passes that built are known) and the conversion a linear scene needs
    // for them.
    void settle_custom() {
        customLdr = custom.any_ldr();
        linear = sceneLinear && (exposure || tonemap || colorFilter != 0 || fx.any() || customLdr);
    }
    // The display-referred custom passes cannot be drawn (the images the pieces go through could not be made, or the
    // final pass is off).
    void drop_custom_ldr() {
        custom.drop_ldr();
        settle_custom();
    }

    // The outline cannot be drawn this frame (its image is not made: no opaque mesh, an unsupported GPU, no memory for the image): the effect is dropped, and with it the conversion that only it asked for.
    void skip_outline() {
        fx.outline = false;
        linear = sceneLinear && (exposure || tonemap || colorFilter != 0 || fx.any() || customLdr);
    }
    // The image the outline reads this frame (the prepass in depth mode, the coverage in sprite mode); invalid when there is no outline.
    const PrepassRef& outline_source() const { return fx.outline_sprite() ? coverage : prepass; }

    // True when the final pass converts the picture (exposure, tonemap, or the encode of a linear scene): `post` runs steps 1 to 4.
    bool convert() const { return exposure || tonemap || linear; }
    // True when the final pass runs: a conversion or an effect. A frame that only has a colour filter is the plain filter pass; one
    // that only has bloom has none.
    bool final_pass() const { return convert() || fx.any() || customLdr; }
    // True when the stage has something to do in the final pass (the cuts are made only where a stage after the last
    // cut is active).
    bool stage_active(int stage) const {
        switch (stage) {
            case kStageScene:
                return convert() || fx.pixelate || fx.lens || fx.aberration || fx.ringCount > 0 || fx.hazeCount > 0 ||
                       fx.radialBlur;
            case kStageGrade: return fx.grade || fx.lut;
            case kStageVignette: return fx.vignette;
            case kStageSharpen: return fx.sharpen;
            case kStageOutline: return fx.outline;
            case kStagePosterize: return fx.posterize;
            case kStageGrain: return fx.grain;
            default: return true;  // the tail
        }
    }
    // The stages after which the final pass is cut for the custom passes (bit `stage`): the ones that have a pass at
    // their place and an active stage since the last cut. Places with nothing drawn between them share one cut.
    // build_graph draws one piece per cut and plan_job counts them to know how many images the pieces need.
    std::uint32_t ldr_cuts() const {
        std::uint32_t cuts = 0;
        int from = kStageScene;
        for (int i = kStageScene; i < kStageTail; ++i) {
            if (!custom.any_in(PostSlot(int(PostSlot::AfterTonemap) + i))) continue;
            bool active = false;
            for (int st = from; st <= i; ++st) active = active || stage_active(st);
            if (!active) continue;
            cuts |= 1u << i;
            from = i + 1;
        }
        return cuts;
    }
    bool any() const { return bloom.enabled || final_pass() || colorFilter != 0; }
};

// The plan of a camera (CameraInfo::postStack, null without one, and the bloom / colorFilter derived from it). `linear`: SceneSettings.colorSpace.
// `forceEffects` (tests and the debug view): effects whose prepass inputs are needed as if the stack switched them on, a mask like
// PostStack::mask. needsDepth / needsNormals come from the effects the renderer draws (post_drawn_mask) among the stack's, and these.
// `frame`: World::frame(), the seed of an animated film grain (the renderer passes it; tests leave 0). `designScale`: physical pixels per
// design pixel (the render scale), the unit of the outline width and the pixelate block (post_fx.h).
// The outline reads the prepass only in depth mode (and when its width and opacity are above 0): a sprite outline, and one that draws
// nothing, never turn the prepass on.
// `frameCam`: the camera whose bloom and colour filter the frame gets (the one that draws first; null: `cam` itself). They act once over
// the frame, so the plan of every other camera carries the same two values.
PostPlan make_post_plan(const CameraInfo& cam, bool linear, std::uint32_t forceEffects = 0, std::uint64_t frame = 0,
                        float designScale = 1.0f, const CameraInfo* frameCam = nullptr);

// PostProcess bloom fields -> supported ranges (sanitize_bloom for the stack): the knee and the dirt intensity too.
BloomSettings bloom_from_stack(const PostStack& stack);

// What the final pass draws (post.glsl): `convert` is true for the final pass itself (not the colour-filter-only pass): it runs the
// plan's exposure, tonemap and encode (when plan.convert()) and plan.fx, `filter` the colour filter
// (0 none; the picture is clamped for it); `expo` is the adapted-exposure image (the 1x1 of AutoExposure) or any 1x1 image when the
// exposure is not automatic; `white`: any 1x1 white image (bound as the LUT when the plan has none, and as the outline's image when it
// is off); `aux`: the image the outline reads (plan.outline_source() of this frame, null view = none: the outline is not drawn). `pass` is the PassDesc of the destination (the caller sets its load and store actions); the pass draws
// one full-screen triangle and ends. `w` x `h`: the size of the destination in pixels. `output`: what the frame is
// drawn for (hdr_encode.h); an HDR output with headroom runs the tonemap above paper white (tonemap_hdr), the rest the SDR one.
// `rect`: the camera's rectangle of the destination (and of `src`, which has the destination's size): the pass draws only there (a
// viewport and a scissor) and every effect works in camera-local pixels (the lens, the vignette, the pixelate grid, the grain and the
// dither start at the rectangle's corner); `aux` has the rectangle's size. Whole (the default): the pass is the one of a camera that
// covers the picture.
// `slice`: the stages this pass runs (the default: all of them, the one fused pass). A piece that does not hold the
// first stage reads a picture that is already converted and encoded (the one before it wrote), the tail piece alone
// runs the colour filter, and only a piece with the stage runs what the stage does (the outline reads `aux` in its
// piece only). The pixelate, which moves the position every effect reads, is in every piece.
void run_post_pass(Gpu& gpu, const PostPlan& plan, bool convert, int filter, bool autoExposure, const PassDesc& pass,
                   sg_view src, sg_view expo, sg_view white, sg_view aux, int w, int h, const OutputTarget& output = {},
                   const PostRect& rect = {}, const PostSlice& slice = {});

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
    // `plan.rect` is the part of the picture that is measured (a camera's), `picW` x `picH` the size of the picture.
    ResourceId add_passes(FrameGraph& graph, TransientTargets& targets, Gpu& gpu, const PostPlan& plan, ResourceId game,
                          sg_view srcTex, float dt, std::uint64_t serial, int* drawCalls, const std::string& job,
                          int picW = 0, int picH = 0);

    // The 1x1 image with the EV the last executed `exposure-adapt` wrote (what the final pass samples).
    sg_view ev_view() const { return ev_[cur_].texView; }
    // Destroys the targets and forgets the adaptation (the next frame measures again). Call while the graphics context is open.
    void release();

private:
    bool ensure_targets(Gpu& gpu);
    void warn_luma_missing();  // the measuring target could not be made after the first check: a warning, once
    Target ev_[2];
    gpu::Device* device_ = nullptr;  // the device ev_ was made on (ensure_targets), to destroy it on
    int cur_ = 0;                    // the index of the target that holds the EV
    bool fresh_ = true;
    // A failed attempt to make a target: no new one before this frame (`serial` of add_passes), then it tries again.
    static constexpr std::uint64_t kRetryFrames = 300;
    std::uint64_t retryAt_ = 0;
    bool lumaChecked_ = false;  // the 32x32 measuring target was made once (add_passes)
    bool warned_ = false;
    bool warnedLuma_ = false;  // the measuring target was missing when the pass ran (add_passes): said once
    std::uint64_t lastSerial_ = 0;
    bool declaredBefore_ = false;
};

}  // namespace fa::render
