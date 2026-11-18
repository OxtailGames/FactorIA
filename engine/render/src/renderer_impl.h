// Private: the state of one Renderer (Renderer::Impl) and the small helpers its translation units share.
// renderer.cpp (setup, cameras, the public API, render()), renderer_targets.cpp (images, views, readback, post filter),
// renderer_draw.cpp (plan_view_job, plan_job, the frame graph) and renderer_present.cpp (present, capture) each implement part of Impl.
#pragma once

#include "fa/render/renderer.h"
#include "fa/scene/camera_geometry.h"
#include "fa/scene/camera_query.h"
#include "fa/scene/bones2d.h"
#include "fa/scene/lod.h"

#include <algorithm>
#include <chrono>
#include <cmath>
#include <cstdlib>
#include <cstring>
#include <set>

#include "fa/core/fs.h"
#include "font_internal.h"
#include "fa/core/strings.h"
#include "fa/core/load_trace.h"
#include "fa/core/asset_manifest.h"
#include "fa/core/log.h"
#include "fa/core/profiler.h"
#include "fa/platform/sokol_logging.h"
#include "fa/scene/text_fit.h"
#include "fa/scene/ui_rect.h"
#include "bloom.h"
#include "hdr_encode.h"
#include "postprocess.h"
#include "render_features.h"
#include "shaders/colorfilter.glsl.h"
#include "frame.h"
#include "mesh_batch.h"
#include "render_scene.h"
#include "font_set.h"
#include "frame_graph.h"
#include "render_internal.h"
#include "render_jobs.h"
#include "shader_cache.h"
#include "transient_targets.h"
#include "shaders/blit.glsl.h"
#include "shaders/light.glsl.h"
#include "shaders/mesh.glsl.h"
#include "shaders/quad.glsl.h"
#include "shaders/sky.glsl.h"

namespace fa {

// The renderer's private code calls the render:: helpers (Gpu, Frame, jobs...) without a prefix.
using namespace render;

// ---------------------------------------------------------------------------
// Renderer::Impl
// ---------------------------------------------------------------------------
struct Renderer::Impl {
    RendererDesc desc;
    bool initialized = false;
    bool inFrame = false;
    bool anyFrameRendered = false;
    int targetW = 0, targetH = 0;  // logical (design) size: what layouts, cameras and Text are measured in
    float renderScale = 1.0f;      // GPU images are targetW*renderScale wide (Renderer::set_render_scale)
    int physW = 0, physH = 0;      // size of the GPU images
    Gpu gpu;
    GpuTimer gpuTimer;
    // Renderer::warm_step: the groups of pipelines to make before the first game frame, built on the first call.
    std::vector<std::function<void()>> warmGroups;
    std::size_t warmNext = 0;
    bool warmBuilt = false;
    std::size_t warmPipelines = 0;
    double warmMs = 0;
    bool adopted = false;  // the graphics context was opened by open_context: this renderer closes it
    std::unique_ptr<Assets> assets;
    std::unique_ptr<Fonts> fonts;
    GradientRamps ramps;     // the baked colour rows of Shape2D gradients with stops or an easing (gradient_ramp.h)
    float textScale = 1.0f;  // Renderer::set_text_scale
    float uiScale = 1.0f;    // Renderer::set_ui_scale

    // The game target (make_target): gameTarget.colorAtt / resolveAtt / depthAtt are what the passes draw into, gameTarget.texView what
    // bloom, the colour filter and present() sample; gameTarget.resolveColorAtt (MSAA) is the resolved image as a colour
    // attachment, which bloom composites into.
    Target gameTarget;
    Bloom bloom;  // Camera.bloom post-process (its levels are transients of the frame graph, see bloom.h)
    // Camera.colorFilter: the filtered copy of the finished frame. A pass cannot read what it writes, so the filter
    // draws into this second image (made on first use) and present(), capture() and the editor viewport show it
    // while `filterActive` (the last frame was filtered).
    Target filterTarget;
    bool filterActive = false;
    // The post-processing stack (postprocess.h). hudTarget is the game-like image the final pass writes when screen-space items are drawn
    // over it in display space (made on first use: a frame without exposure, tonemap or linear colour never makes it); the HUD draws into
    // it with the game target's formats and sample count, so the pipelines of the game fit. hudActive: the last frame's picture is in it
    // (when filterActive is false). finalEncoded: the last frame's final pass already made display values (sRGB-encoded, extended above 1
    // for an HDR output), so the captures copy them as they are and present() only decodes them for an HDR swapchain.
    AutoExposure autoExposure;
    Target hudTarget;
    bool hudActive = false;
    bool finalEncoded = false;
    // The depth and normal prepass (renderer_draw.cpp, plan_job and prepass_pass). `debugView` shows it (Renderer::set_debug_view),
    // `forceEffects` pretends the stack has those effects (tests). prevViewProj: the view-projection each camera drew its last frame
    // with, for the effects that reproject (PostPlan::prevViewProj); an entry the camera did not refresh in the frame before is dropped.
    DebugView debugView = DebugView::None;
    std::uint32_t forceEffects = 0;
    struct PrevCamera {
        Mat4 viewProj;
        std::uint64_t frame = 0;  // the frameSerial it was drawn in
    };
    std::unordered_map<std::uint64_t, PrevCamera> prevViewProj;  // by Entity::bits() of the camera
    bool prepassSplitWarned = false;  // one warning when a split frame has no prepass for a depth effect
    bool prepassWarned = false;       // one warning when the prepass cannot be made
    bool coverageWarned = false;      // one warning when a sprite outline has no coverage image to read
    // The HDR display output (hdr_encode.h; docs/RENDERING.md, "HDR output"). outputInfo: the last answer of update_output()
    // (window thread; a renderer that never asks, a headless one, stays in the standard range). frameOutput: what the frame
    // is drawn for, taken from it when the frame starts (so the final pass and present() of a frame agree on the headroom).
    // frameAboveWhite: the last frame's final pass wrote values above paper white (the HDR tonemap, no colour filter after
    // it), so present() lets them through up to frameOutput.headroom. forcedOutput: renderer_force_output (tests).
    HdrOutputInfo outputInfo;
    HdrRequest outputRequest;  // what update_output() asked the last time, changed in place (it runs every frame)
    bool outputRequestMade = false;
    bool outputForced = false;
    HdrOutputInfo forcedOutput;
    render::OutputTarget frameOutput;
    bool frameAboveWhite = false;
    bool backendKnown = false;
    render::FeatureBackend backend =
        render::FeatureBackend::Headless;  // sg_query_backend(), asked once (update_output)
    const HdrOutputInfo& output() const { return outputForced ? forcedOutput : outputInfo; }
    // The images the final pass writes hold values above 1 (RGBA16F; R11G11B10 scenes keep their display picture in RGBA8, see
    // Gpu::display_format): an HDR output can go above paper white.
    bool float_display() const { return gpu.display_format() == SG_PIXELFORMAT_RGBA16F; }
    // The fragment uniforms of present(): the encode for the output the window has now (output()), the light let through up to
    // the frame's headroom when its final pass went above white.
    blit_blit_fs_params_t present_params() const;
    // Tests (renderer_final_floats / renderer_present_floats): the finished picture as floats, copied as it is (`present`
    // false) or through present()'s encode, read back from an RGBA16F image of physW x physH.
    bool read_floats(bool present, std::vector<float>& out, std::string* error);
    Target floatTarget;               // the RGBA16F image read_floats draws into (tests only; freed with the targets)
    bool shadowTargetFailed = false;  // the shadow map could not be made: no shadows until a resize
    Target shadowTarget;  // the shadow map: R32F colour + depth (shadowTarget.texView is what the mesh programs sample)
    static constexpr int kShadowSize = 2048;

    DebugDraw debug;
    RenderStats stats;
    // The rendering cameras of the last update()/draw in draw order (never empty after the first one: a world without a camera
    // gets one default camera). [0] is "the" camera: the lowest depth.
    std::vector<CameraInfo> lastCams;
    // The same cameras seen from their REAL pose, filled only while render interpolation blends a camera (it or an ancestor): scripts, picking and UI
    // hit tests ask these (camera_for), so an answer never depends on alpha. Empty = lastCams.
    std::vector<CameraInfo> logicCams;
    bool warnedNoLight = false;
    std::string
        warnedViewport;  // the last "bad Camera.viewport" problem logged (a viewport a script sets live is clamped)
    bool postBypass = false;     // Renderer::set_post_bypass: draw without any post-processing stack (the editor's A/B)
    bool warnedCameras = false;  // the "more cameras than the limit" warning, once per scene
    bool warnedLights2d = false;       // the "more Light2D in view than the budget" warning, once per scene
    bool warnedShadows2d = false;      // the "more shadow casters than the budget" warning, once per scene
    bool warnedSpriteMesh = false;     // the "too many mesh cells" warning, once per scene
    bool warnedGradientStops = false;  // the "malformed gradientStops" warning, once per scene
    std::string lights2dScene;         // the scene path warnedLights2d and warnedShadows2d belong to
    // The 2D light buffer (light.glsl): the point lights of the frame added up, read by the lit visuals. Made when a frame
    // needs it, at lightScale of the target's size; kept while the size and the format stay.
    Target lightTarget;
    int lightW = 0, lightH = 0;
    sg_pixel_format lightImgFormat = SG_PIXELFORMAT_NONE;
    bool lightTargetFailed = false;
    // The shadow rows of the lights with castShadows (light2d.cpp) as an image: an image is reused while its rows stay the
    // same, a new one replaces the oldest of the ring.
    ShadowCache shadowCache;
    // The jobs of a frame are all planned (their rows uploaded) before the first one draws, so an image a job planned with
    // must live to the end of the frame: a slot returned (a hit or a new image) in the frame number `usedFrame` is never
    // the one a later upload replaces in that frame. Otherwise the oldest slot is replaced; when every slot was used in
    // this frame the ring grows by one. begin_frame_graph() trims it back (the oldest go first) to the most slots one frame
    // used in the last kShadowTrimWindow frames, and never below kShadowRowsRing: a scene with more stable keys than the
    // ring (12 render targets with their own shadows) keeps them all, and uploads nothing in a still frame.
    static constexpr std::size_t kShadowRowsRing = 9;
    static constexpr int kShadowTrimWindow =
        60;  // frames; a count, not a time, so the result does not depend on the CPU
    std::size_t shadowRowsKeep = kShadowRowsRing;  // the ring is trimmed to this many slots
    std::size_t shadowRowsPeak = 0;                // the most slots one frame of the current window used
    int shadowRowsWindow = 0;                      // frames of the current window
    std::uint64_t shadowRowUploads = 0;            // images made since the renderer was (a test counts them)
    struct ShadowRowsSlot {
        sg_image img{};
        sg_view view{};
        std::uint64_t key = 0;
        std::uint64_t usedFrame = 0;
    };
    std::vector<ShadowRowsSlot> shadowRowsRing;
    std::uint64_t frameSerial =
        0;  // counts the frame graphs begun (begin_frame_graph); never 0 while a frame is planned
    void trim_shadow_rows();
    bool updated = false;  // update() ran since the last draw
    ScaleMode scaleMode = ScaleMode::Fit;
    std::vector<Vertex2D> stream;

    // The image a CameraView shows (ui2d.cpp, draw_camera_view): the camera is drawn into it before the frame's own jobs. One per
    // widget, made when a gather asks for it with a size and kept while the widget keeps asking; the ones nobody asked for in a
    // frame are freed at its end. Made like the game target (same sample count, same formats), because the pipelines are.
    struct ViewTarget {
        Target main;  // the colour (and resolve, depth) the camera draws into; main.texView is what the widget samples
        int w = 0, h = 0;
        bool used = false;   // asked for since the last release_unused_views()
        TextureAsset asset;  // what the UI quad samples: the resolved image, w x h
        // A Camera.renderTarget texture on a backend that stores render targets bottom-up (GL): the picture copied the right way
        // up into `flip`, which `asset` then samples, so a mesh, a Sprite or a Panel reads it like any file texture.
        bool flipCopy = false;
        Target flip;  // the flipped copy: flip.colorAtt is drawn into, flip.texView sampled
    };
    std::unordered_map<std::uint64_t, std::unique_ptr<ViewTarget>> viewTargets;
    bool viewWarned = false;
    TextureAsset* view_image(std::uint64_t key, int w, int h, bool renderTarget = false);
    void release_view(ViewTarget& t);
    void release_unused_views();

    // ---- Camera.renderTarget (docs/RENDERING.md, "Render targets") ----
    struct TargetCam {
        Entity entity;
        std::string name;
        int w = 1, h = 1;
        std::uint64_t key = 0;
        int depth = 0;
        TextureAsset* asset = nullptr;
    };
    std::vector<TargetCam> targetCams;                  // this frame's: active, valid, one per name, in creation order
    std::unordered_map<std::string, int> targetByName;  // name -> index into targetCams
    std::unordered_map<const TextureAsset*, int> targetByAsset;
    std::string
        targetSelf;  // the name of the target being gathered or drawn: its own texture is the checker (sentinel)
    TextureAsset selfSentinel;  // what texture("target:<self>") answers meanwhile: the checker, its handles are shared
    std::set<std::string> targetWarned;
    void collect_targets(World& world);
    void warn_target_once(const std::string& key, const std::string& message, const std::string& hint);
    TextureAsset* resolve_target(const std::string& name);
    void flip_copy(ViewTarget& t);

    // `settle`: also try the next format of the chain when this one is refused (the first creation does it anyway).
    void create_targets(int w, int h, bool settle = false);
    // Follows SceneSettings.colorSpace of `world`: the scene's format may change with it (Gpu::set_linear).
    void sync_color_space(const World& world);
    void make_game_targets();  // the images and views of the game target, at physW x physH in gpu.scene_format()
    void destroy_targets();
    // The final images of the post-processing stack: filterTarget (what the final pass or the colour filter writes; made by
    // ensure_filter_target) and hudTarget (ensure_hud_target). False, with one logged error, when the GPU cannot make them: the
    // frame is then drawn without the stack.
    bool ensure_filter_target();
    bool ensure_hud_target();
    // One full-screen pass of post.glsl: `src` (a texture view of the finished picture) through the plan's final pass (`finalPass`: conversion and effects) and the
    // colour filter `filter` into `dst`; `expo` is the adapted exposure or a dummy image. `keepMsaa`: an MSAA destination keeps its
    // multisampled image (a pass that draws over it follows).
    // `aux`: the image the outline reads (PostPlan::outline_source of the frame), or a null view when there is none.
    void post_pass(const PostPlan& pp, bool finalPass, int filter, bool autoExposure, sg_view src, sg_view expo,
                   sg_view aux, Target& dst, const char* label, bool keepMsaa);
    // The 8-bit picture of a game or view image (top row first). In a float scene format the image is first drawn into an
    // RGBA8 copy (clamped at white, as the screen shows it), because the per-backend readbacks read RGBA8 only.
    bool read_rgba8(sg_image image, sg_view view, int w, int h, std::vector<std::uint8_t>& out, std::string* error,
                    bool premultiplied = false, bool displayValues = false);
    Target readbackTarget;  // the RGBA8 copy read_rgba8 makes, kept for the next capture of the same size
    void free_read_image();
    // True when the images and views of the game target were made (create_targets) and the GPU accepted them.
    bool game_targets_valid() const;
    int readW = 0, readH = 0;
    // The image of the finished frame: the final pass's (or the colour filter's) picture when the last frame had one, else the game target.
    const Target& final_target() const { return filterActive ? filterTarget : hudActive ? hudTarget : gameTarget; }
    sg_image final_image() const { return final_target().texture_image(); }
    sg_view final_view() const { return final_target().texView; }
    // The picture the editor viewport shows (Renderer::game_target_view_id): the finished game image in a gamma scene; in a linear one,
    // when the editor asked for it (Renderer::set_editor_view), the 8-bit encoded copy update_editor_copy() makes after each frame
    // (an empty handle until the first one exists). The final pass's picture is shown as it is, except when it went above paper white
    // (an HDR output; the editor's window never switches, but a viewport that can show extended values would show them brighter
    // than the SDR present() does): then the 8-bit copy clamps it to [0, 1].
    sg_image display_image() const;
    sg_view display_view() const;
    bool editorView =
        false;  // set_editor_view(true): make the 8-bit copy of a linear scene (or of a picture above white)
    Target
        editorTarget;  // the copy: RGBA8, only while the editor asked and it is needed (see editor_copy_wanted); freed when not
    // The viewport shows the copy: a linear scene not yet encoded by the final pass (the copy encodes it), or a final pass picture
    // that went above paper white (the copy clamps it).
    bool editor_copy_wanted() const;
    void update_editor_copy();
    bool create_shadow_targets();
    bool ensure_light_target(float scale);
    sg_view upload_shadow_rows(const Frame& fr);
    void destroy_light_resources();
    // `view` (a CameraView's rectangle in design pixels) makes the camera fill an image of that size instead of its viewport.
    CameraInfo build_camera(World& world, Entity entity, const Vec2* viewSize = nullptr, bool renderTarget = false,
                            bool blended = true);
    std::vector<CameraInfo> collect_cameras(World& world, bool blended = true);
    void refresh_logic_cameras(World& world);
    Vec2 logic_camera_xy() const;  // the first camera's real position: lastCams, or logicCams while a camera is blended
    const CameraInfo& camera_for(Entity camera, const Vec2* screenPoint) const;
    // The 3D world of the frame, gathered once by render() (capture_world: scoped to its subject) before any job and read by the
    // gather_meshes of every camera, render target and CameraView.
    RenderScene renderScene;
    struct JobPlan {
        // The job's name in the frame graph: its passes are "<name>/<pass>" ("camera:0", "screen" for the screen-space job of a
        // split frame, "target:<name>", "view:<n>", "capture").
        std::string name;
        // The keys (view_image) of the images of other jobs this job's visuals sample (a Sprite, a mesh or a UI that shows
        // "target:<name>", a CameraView): the job reads them in the graph, after the jobs that drew them.
        std::vector<std::uint64_t> shows;
        ResourceId image;    // a view job: the imported image it draws into (set by plan_view_job)
        bool first = false;  // the first pass of the frame: it clears the whole target when its camera clears
        bool last =
            false;  // the last job of the frame: it runs the post effects (bloom, the HUD over it, the colour filter)
        bool view =
            false;  // a CameraView's image: no post effects, never partial, resolved at once, 2D lights read per pixel
        const CameraInfo* post =
            nullptr;  // the camera whose bloom, bloomScreenSpace and colorFilter the frame gets (the first)
    };
    void render(World& world, float dt);
    void setup_frame(Frame& fr, World& world, float dt);
    // Declares the passes of one job in the frame graph (the CPU phases below run now; the GPU work runs in
    // run_frame_graph()). The job keeps its state in a DrawContext that lives until then.
    void plan_job(World& world, Frame& fr, const JobPlan& plan);
    // Declares the passes of a CameraView's, a render target's (or capture_world's) camera in the frame graph, drawing into the
    // view's image: plan_job with the image in the place of the game target. `key` is the view's key (view_image). Call
    // between begin_frame_graph() and run_frame_graph().
    void plan_view_job(World& world, Frame& fr, ViewTarget& target, std::uint64_t key, JobPlan plan);

    // ---- The frame graph: one per render() (and per capture_world) ----
    // begin_frame_graph() empties it, every job adds its passes (plan_job, plan_view_job) in the order the jobs must
    // run, run_frame_graph() compiles and executes them and drops what the pass callbacks captured. The images that jobs
    // draw into and others sample are imported resources (`jobImages`), so a job that shows one reads it.
    struct JobImage {
        ResourceId drawn, shown;  // `shown` is the flipped copy when the backend needs one, else the same as `drawn`
    };
    void begin_frame_graph();
    void run_frame_graph();
    // The time of every pass that ran in the graph (graph.stats(), in order) and of every job (the passes whose name starts
    // with the same `<job>/`), with the GPU time of the newest finished measurement of each pass name (-1 without one, and
    // always while the profiler is off: the GPU timer only runs with it).
    void pass_times(std::vector<RenderStats::PassTime>& passes, std::vector<RenderStats::JobTime>& jobs) const;
    // `stats.passes` and `jobs` are not built each frame: while this is true the frame graph still holds the passes of the last
    // render(), and Renderer::stats() builds them from it. Whoever replaces the graph (capture_world) calls settle_pass_times().
    bool passTimesPending = false;
    void settle_pass_times() {
        if (!passTimesPending) return;
        pass_times(stats.passes, stats.jobs);
        passTimesPending = false;
    }
    // GPU frame times the timer resolved while the renderer polled it for pass times, kept for take_gpu_ms().
    std::vector<double> gpuFrames;
    bool passHooksSet = false;      // begin_frame_graph() gave the graph its pass hooks
    bool graphFromCapture = false;  // the graph holds the last capture_world's frame, not the last render()'s
    std::unordered_map<std::uint64_t, JobImage> jobImages;
    // The targets the jobs of the frame share, one resource each (imported when the first job that uses it is declared).
    ResourceId sharedGame, sharedLight, sharedShadow;
    std::vector<std::shared_ptr<void>> jobContexts;  // the DrawContext of every job, alive until run_frame_graph() ends
    // What a job's passes read from the renderer when they run: the swapped-in image of a view job (plan_view_job).
    struct JobEnv {
        int targetW = 0, targetH = 0, physW = 0, physH = 0;
        sg_view colorAtt{}, resolveAtt{}, depthAtt{};
    };
    JobEnv job_env() const;
    void set_job_env(const JobEnv& env);

    // The phases of draw_job (renderer_draw.cpp), each reading and writing the DrawContext of the job; the comment of each
    // names its reads and writes.
    struct Px;
    struct PartDraw;
    struct MaterialInputs;
    struct DrawContext;
    void gather_meshes(DrawContext& ctx);
    void collect_lights(DrawContext& ctx);
    void shadow_bounds(DrawContext& ctx);
    void cull_and_batch(DrawContext& ctx);
    void build_quad_stream(DrawContext& ctx);
    void upload_instances(DrawContext& ctx);
    void scene_uniforms(DrawContext& ctx);
    PartDraw part_draw(DrawContext& ctx, const MeshItem& mi, const SubMesh& part);
    mesh_fa_mesh_fs_params_t fill_fs(DrawContext& ctx, const MeshItem& mi, const SubMesh& part, const PartDraw& d);
    void material_inputs(const MeshItem& mi, MaterialAsset* mat, MaterialInputs& in);
    void bind_textures(DrawContext& ctx, sg_bindings& b, const PartDraw& d, const MaterialProgram* prog,
                       const MaterialInputs& in, bool shadowPass);
    void light_plan(DrawContext& ctx);
    void light_pass(DrawContext& ctx);
    void shadow_pass(DrawContext& ctx);
    // The depth and normal prepass (M71): plan_prepass decides whether the job has one, prepass_pass draws it into `t` (a transient of
    // the graph), prepass_view_pass paints it over the game image (Renderer::set_debug_view).
    bool plan_prepass(DrawContext& ctx);
    void prepass_pass(DrawContext& ctx, const Target& t);
    // The outline's image (M71-C2): plan_outline settles it after plan_prepass (a depth outline needs the prepass, a sprite outline a
    // coverage image of the 2D world; without it the effect is dropped from the plan), coverage_pass draws the 2D world's alpha into `t`.
    void plan_outline(DrawContext& ctx);
    void coverage_pass(DrawContext& ctx, const Target& t);
    void prepass_view_pass(DrawContext& ctx, const Target& t);
    void draw_group(DrawContext& ctx, const std::vector<QuadBatch>& batches, const Mat4& vp, bool depthTest,
                    const Px& base, int flatMode = 0, const TargetFormat* format = nullptr);
    void main_pass(DrawContext& ctx);
    void hud_pass(DrawContext& ctx, const Target& into, const char* label);
    // Declares the job's passes in `graph` (plan_job).
    void build_graph(DrawContext& ctx);

    // The frame graph of the last frame (every job of it: the cameras, the CameraViews and the render targets) and the pool of the
    // targets its transients are made of (the bloom levels). Both are made on first use.
    FrameGraph graph;
    std::unique_ptr<TransientTargets> transients;
    bool warnedGraph = false;  // a graph that could not be compiled or run is logged once
    std::vector<std::string>
        frameJobs;  // the jobs planned in the frame graph being built (the log of a graph error names them)
    // What render() uses to order the render targets, kept from frame to frame so that a frame with targets allocates
    // nothing for it: a small graph of one node per target, and its work vectors.
    struct TargetOrderScratch {
        FrameGraph graph;
        std::vector<int> order, byDepth;
        std::vector<std::pair<std::string, int>> byName;
    } orderScratch;
    TransientTargets& transient_targets() {
        if (!transients) transients = std::make_unique<TransientTargets>();
        return *transients;
    }
};

struct Viewport {
    float x, y, w, h, scale;
};

inline Viewport compute_viewport(ScaleMode mode, int fbW, int fbH, int tw, int th) {
    if (fbW <= 0 || fbH <= 0 || tw <= 0 || th <= 0) return {0, 0, float(fbW), float(fbH), 1.0f};
    const float fw = float(fbW), fh = float(fbH), tfw = float(tw), tfh = float(th);
    switch (mode) {
        case ScaleMode::Stretch: return {0, 0, fw, fh, fw / tfw};
        case ScaleMode::PixelPerfect: {
            float s = std::floor(std::min(fw / tfw, fh / tfh));
            if (s < 1.0f) s = std::min(fw / tfw, fh / tfh);
            float w = tfw * s, h = tfh * s;
            return {std::floor((fw - w) * 0.5f), std::floor((fh - h) * 0.5f), w, h, s};
        }
        case ScaleMode::Expand:
        case ScaleMode::Fit:
        default: {
            float s = std::min(fw / tfw, fh / tfh);
            float w = tfw * s, h = tfh * s;
            return {std::floor((fw - w) * 0.5f), std::floor((fh - h) * 0.5f), w, h, s};
        }
    }
}

template <class T>
void apply_uniforms(int slot, const T& u) {
    sg_range r{&u, sizeof(T)};
    sg_apply_uniforms(slot, &r);
}

}  // namespace fa
