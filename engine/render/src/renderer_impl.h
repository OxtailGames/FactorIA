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
#include <unordered_set>

#include "fa/core/fs.h"
#include "font_internal.h"
#include "fa/core/strings.h"
#include "fa/core/load_trace.h"
#include "fa/core/asset_manifest.h"
#include "fa/core/log.h"
#include "fa/core/profiler.h"
#include "fa/scene/text_fit.h"
#include "fa/scene/ui_rect.h"
#include "bloom.h"
#include "command_capture.h"
#include "decal_atlas.h"
#include "light_clusters.h"
#include "portal_graph.h"
#include "renderer_env.h"
#include "renderer_lod.h"
#include "renderer_foliage.h"
#include "renderer_impostor.h"
#include "renderer_terrain.h"
#include "renderer_probes.h"
#include "renderer_ssr.h"
#include "renderer_xmit.h"
#include "water2d.h"
#include "renderer_dof.h"
#include "renderer_fog.h"
#include "renderer_volumetric.h"
#include "renderer_subsurface.h"
#include "renderer_custom_post.h"
#include "hdr_encode.h"
#include "postprocess.h"
#include "render_features.h"
#include "gpu/sokol_shaders.h"  // before the generated shader headers
#include "shaders/colorfilter.glsl.h"
#include "frame.h"
#include "mesh_batch.h"
#include "hiz.h"
#include "occlusion.h"
#include "render_scene.h"
#include "renderer_ssao.h"
#include "font_set.h"
#include "frame_graph.h"
#include "gi2d.h"
#include "light_atlas.h"
#include "render_internal.h"
#include "render_upscale.h"
#include "render_upscale_metalfx.h"
#include "render_upscale_rr.h"
#include "render_upscale_spatial.h"
#include "render_framegen.h"
#include "render_latency.h"
#include "render_upscale_vendor.h"
#include "metalfx.h"
#include "render_jobs.h"
#include "shader_cache.h"
#include "transient_targets.h"
#include "shaders/blit.glsl.h"
#include "shaders/light.glsl.h"
#include "shaders/mesh.glsl.h"
#include "shaders/quad.glsl.h"
#include "renderer_hdri.h"
#include "renderer_sky_phys.h"
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
    // set_render_scale is making the targets again for a step of the dynamic resolution (the base scale is the same):
    // destroy_targets keeps what does not depend on the render size (the cameras' adapted exposure, the temporal
    // upscaler's history and the upscale stage's images at the output size; not MetalFX's, made for the input) and
    // the slots of the CameraView and render-target images (view_image makes an image again only when its pixel size
    // changes: a CameraView's size follows renderScale, so a step makes it again at its next draw; a render target's
    // has its own size and survives) and frees the rest.
    bool scaleStepOnly = false;
    float renderBaseScale =
        1.0f;  // renderScale without the dynamic resolution's factor: what the temporal history is bound to
    bool gpuFrameWanted = false;  // Renderer::set_gpu_frame_timing: time every frame for the dynamic resolution
    bool dynResSeen =
        false;  // the render scale has moved under renderBaseScale at least once (kept: the SDKs' contexts keep their flags)
    std::vector<double> gpuFrameMs;  // the GPU frame times it has not taken yet
    int physW = 0, physH = 0;        // size of the GPU images
    Gpu gpu;
    GpuTimer gpuTimer;
    // Renderer::warm_step: the groups of pipelines to make before the first game frame, built on the first call.
    std::vector<std::function<void()>> warmGroups;
    std::size_t warmNext = 0;
    bool warmBuilt = false;
    std::size_t warmPipelines = 0;
    double warmMs = 0;
    bool adopted = false;        // the graphics context was open before init: shutdown() leaves it to whoever opened it
    bool presentFailed = false;  // present() could not acquire or present the window's image (logged once)
    // The framebuffer size present() last gave Device::resize_swapchain (0 = none yet): a new size resizes the
    // swapchain before the next acquire.
    int swapW = 0, swapH = 0;
    bool resizeFailed = false;  // resize_swapchain failed (logged once)
    // What init made the window's swapchain with (D3D12, Vulkan): present() makes it again from this when it is gone
    // (Renderer::set_native_window; a swapchain the device lost). nativeWindow null: no window to make it on now.
    gpu::SwapchainDesc windowDesc;
    bool windowManaged = false;       // init made the device's own swapchain on a native window (D3D12, Vulkan)
    bool windowRemakeFailed = false;  // create_swapchain on the window's new surface failed (logged once per window)
    std::unique_ptr<Assets> assets;
    Compute* compute =
        nullptr;  // the renderer's Compute (set at init): the buffers a mesh material with "buffers" reads
    std::unique_ptr<Fonts> fonts;
    ImpostorRenderer impostors;  // the impostor atlases, card and program (renderer_impostor.h)
    TerrainRenderer terrains;    // the Terrain components' height textures, patch and program (renderer_terrain.h)
    FoliageRenderer foliage;     // the Foliage components: instances file, chunks and items (renderer_foliage.h)
    GradientRamps ramps;         // the baked colour rows of Shape2D gradients with stops or an easing (gradient_ramp.h)
    float textScale = 1.0f;      // Renderer::set_text_scale
    float uiScale = 1.0f;        // Renderer::set_ui_scale

    // The game target (make_target): gameTarget.colorAtt / resolveAtt / depthAtt are what the passes draw into, gameTarget.texView what
    // bloom, the colour filter and present() sample; gameTarget.resolveColorAtt (MSAA) is the resolved image as a colour
    // attachment, which bloom composites into.
    Target gameTarget;
    PhysicalSky physSky;  // the physical sky's tables and programs (renderer_sky_phys.h)
    HdriSky hdriSky;      // the program that draws SceneSettings.environmentMap (renderer_hdri.h)
    Environment
        skyEnv;  // the baked sky that lights the meshes (renderer_env.h; used only with SceneSettings.skyMaterial)
    ProbeSystem
        probes;  // the reflection probes: their atlas, captures and baked pages (renderer_probes.h, renderer_probes.cpp)
    Ssr ssr;     // screen-space reflections (renderer_ssr.h): its shaders and pipelines
    Xmit xmit;   // the opaque picture the transmissive meshes look through (renderer_xmit.h): its shader and pipelines
    WaterFx
        waterFx;  // the copy of the picture and the shaders of Water2D, DistortionZone2D and fa_scene_color (water2d.h)
    Ssao ssao;    // PostProcess.ssao*: the ambient occlusion passes of each camera (renderer_ssao.h)
    SceneFx
        sceneFx;  // depth of field and motion blur (renderer_dof.h): its shaders, pipelines and the autofocus of each camera
    TaaFx taa;  // temporal antialiasing (renderer_taa.h): its shaders, pipelines and the history of each camera
    Gi2dSystem
        gi2d;  // the 2D GI field of each 2D camera (gi2d.h): its shaders, pipelines and the images of the field slots
    FogFx fogFx;         // distance and height fog and sun shafts (renderer_fog.h): its shaders and pipelines
    VolumetricFx volFx;  // SceneSettings.volumetricFog (renderer_volumetric.h): its shaders and pipelines
    SssFx sssFx;         // MeshRenderer.subsurface (renderer_subsurface.h): the blur and add shaders and pipelines
    CustomPost
        customPost;  // the passes of PostProcess.customPasses (renderer_custom_post.h): the intermediate images it probed
    Bloom bloom;     // PostProcess bloom post-process (its levels are transients of the frame graph, see bloom.h)
    // PostProcess.colorFilter: the filtered copy of the finished frame. A pass cannot read what it writes, so the filter
    // draws into this second image (made on first use) and present(), capture() and the editor viewport show it
    // while `filterActive` (the last frame was filtered).
    Target filterTarget;
    bool filterActive = false;
    // The two images the final pass goes through when a custom pass sits between its stages (PostSlice, post_custom.h's
    // display-referred places): the piece before a cut writes one, the passes of the cut work on it, the piece after
    // reads it and writes the other one (or the destination). Made on first use at the size of the picture, in
    // Gpu::ldr_cut_format (the display format; a float one with an HDR output, which keeps what is above white); a
    // frame without such a pass never makes them.
    Target ldrMid[2];
    bool ldrWarned = false;  // making them failed: said once
    // They are made when a frame needs them (one for a single cut, two for more) and freed after kLdrIdleFrames frames
    // without use.
    static constexpr int kLdrIdleFrames = 120;
    std::uint64_t ldrUsedFrame = ~std::uint64_t(0);  // the frameSerial of the last frame that asked for them
    int ldrIdle = 0;                                 // frames since
    // The post-processing stack (postprocess.h). hudTarget is the game-like image the final pass writes when screen-space items are drawn
    // over it in display space (made on first use: a frame without exposure, tonemap or linear colour never makes it); the HUD draws into
    // it with the game target's formats and sample count, so the pipelines of the game fit. hudActive: the last frame's picture is in it
    // (when filterActive is false). finalEncoded: the last frame's final pass already made display values (sRGB-encoded, extended above 1
    // for an HDR output), so the captures copy them as they are and present() only decodes them for an HDR swapchain.
    // One AutoExposure per camera (by Entity::bits(): its adapted EV follows the camera, not its place in the frame), made when a camera
    // first asks for one and released when it has not asked for two frames.
    struct ExposureSlot {
        std::unique_ptr<AutoExposure> exposure;
        std::uint64_t frame = 0;  // the frameSerial it was last used in
    };
    std::unordered_map<std::uint64_t, ExposureSlot> autoExposures;
    // The camera jobs of the frame that carry a post-processing plan (plan_job, in drawing order): the last job declares their final
    // passes together (build_graph). The contexts live in jobContexts.
    struct DrawContext;
    std::vector<DrawContext*> postCams;
    Target hudTarget;
    bool hudActive = false;
    bool finalEncoded = false;
    // The upscale stage (M76-P3a, render_upscale.h, renderer_upscale.cpp). upscaleStage: Renderer::set_upscale_stage (the player's
    // render scale). While upscale_active() the finished picture of the render resolution is copied by the chosen implementation
    // into outTarget (targetW x targetH, the format of the picture), the screen-space items are drawn over it there, and the colour
    // filter, when it has to reach them, goes on into outFilterTarget. outActive / outFilterActive: the last frame's picture is in
    // them (they come first in final_target()). Both are made when a frame needs them and freed with the targets.
    bool upscaleStage = false;
    bool hudAtOutput =
        false;  // this frame's screen-space items are drawn over the upscaled picture (decided in render_world)
    render::UpscaleImpl upscaleImpl = render::UpscaleImpl::Stretch;
    Target outTarget, outFilterTarget;
    bool outActive = false, outFilterActive = false;
    // Consecutive frames the stage was inactive while its images existed (render_world): they are freed at kOutputIdleFrames, so a dynamic
    // resolution or a render scale that crosses 1 every few frames does not make and free them again and again.
    static constexpr int kOutputIdleFrames = 60;
    int outputIdleFrames = 0;
    // The spatial upscaler (M76-P3b, render_upscale_spatial.h): its programs, and the upsampled picture between its two passes (made
    // only when both run: a render scale below 1 and a sharpness above 0).
    render::SpatialUpscaler spatial;
    Target spatialTarget;
    int spatialSupported = -1;  // the "spatialUpscaler" row of this backend, asked once (-1 = not yet)
    render::UpscalerCaps
    upscaler_caps();  // not const: the first temporal, metalfx or auto setting compiles the TAA shaders (caps.temporal)
    render::UpscalerMode effective_upscaler_mode();
    bool upscale_active();
    // M76-P4, the temporal upscaler (renderer_upscale.cpp). temporalPhases: the jitter sequence render() asks the cameras for this
    // frame (0: none); temporalFrame: this frame's picture is jittered for the upscaler and resolved by it (plan_job: `upscaleTaa` is
    // the plan, and the camera's own TemporalAA is not drawn); both are set by render() before the cameras are built.
    // temporalBlocked: the last frame had no single full-viewport camera (UpscalerCaps::multiCamera), so the effective mode is
    // spatial until one has.
    bool temporalBlocked = false;
    int temporalPhases = 0;
    bool temporalFrame = false;
    TaaPlan upscaleTaa;
    PrepassRef upscalePrepass;
    VelocityRef upscaleVelocity;
    PrepassRef upscaleGbufAlbedo,
        upscaleGbufMaterial;  // the thin G-buffer of that camera while DLSS Ray Reconstruction asks for it (M79-P0c); invalid: none
    PrepassRef upscaleReactive;  // the reactive mask of the camera the upscaler resolves (M76-P1d); invalid: none
    bool temporal_upscale(const render::UpscaleInput& in, Target& out, const PassContext& c);
    // M76-P5b, MetalFX (renderer_metalfx.cpp). mfxFrame: this frame's jittered picture goes to MetalFX's temporal scaler (render() decides it
    // with temporalFrame). The scaler and the preparation pass (the 0..1 depth and the UV motion it reads, made at the render resolution
    // from the prepass and the velocity); mfxFailed: MetalFX failed once here (creation or mid-frame): every frame after draws with the
    // temporal TAA upscaler, then the spatial one, and the caps say metalfx = false. mfxSupport: what the GPU can do, asked once
    // (mfxSupportKnown). mfxWarnedUnavailable: the one warning of an explicit "metalfx" the GPU cannot run. mfxLast*: what the scaler's
    // history was drawn for (the reset rule is TaaFx::upscale's). outStorage: the output image also needs storage usage (MetalFX writes it).
    bool mfxFrame = false;
    bool mfxFailed = false;
    bool mfxSupportKnown = false;
    bool mfxWarnedUnavailable = false;
    bool outStorage = false;
    bool outHasStorage = false;
    render::metalfx::Support mfxSupport;
    render::metalfx::Scaler mfxScaler;
    render::MetalFxPrep mfxPrep;
    Target mfxDepth, mfxMotion;
    std::uint64_t mfxLastSerial = 0, mfxLastScene = 0, mfxLastShifts = 0, mfxLastConfig = 0;
    bool mfxLastWrote = false;
    bool mfxLastReset = false;  // the last MetalFX temporal frame reset the scaler's history (tests)
    // Test hooks (RendererTestAccess): the next scaler creation fails; the preparation pass alone; the sign of the jitter and of the motion handed to MetalFX.
    // mfxPrepOnly: a jittered frame draws the preparation pass (mfxDepth, mfxMotion) and then falls to the temporal upscaler without asking
    // MetalFX for anything, so the pass can be read back on a GPU that has no MetalFX.
    bool mfxForceCreateFail = false;
    bool mfxPrepOnly = false;
    // Test hook: the reactive mask is not handed to MetalFX (the frames without one are the contrast).
    bool mfxNoReactive = false;
    // M78, the vendor SDKs (render_upscale_vendor.h; renderer_upscale.cpp). vendorFrameImpl: the vendor implementation this frame's jittered
    // picture goes to (Stretch: none; render() decides it with temporalFrame). vendorProbe[i]: what provider i answered for this GPU, asked
    // once (vendorProbed[i]). vendorFailed[i]: provider i refused a frame: every frame after draws with the temporal upscaler, and the caps
    // say it is not available. vendorWarnedUnavailable[i]: the one warning of an explicit mode its SDK cannot run.
    render::UpscaleImpl vendorFrameImpl = render::UpscaleImpl::Stretch;
    render::VendorProbe vendorProbe[render::kVendorUpscalerCount];
    bool vendorProbed[render::kVendorUpscalerCount] = {};
    bool vendorFailed[render::kVendorUpscalerCount] = {};
    bool vendorWarnedUnavailable[render::kVendorUpscalerCount] = {};
    bool vendor_upscale(render::UpscaleImpl impl, render::UpscaleInput& in, const Target& src, Target& out,
                        const PassContext& c);
    bool vendor_fail(int index, const std::string& why);
    const render::VendorProbe& vendor_probe(int index);  // asked once; a provider that failed a frame says so
    void set_vendor_env(render::FeatureEnv& env);        // render.supports: the three providers' answers
    std::string vendorFailedWhy[render::kVendorUpscalerCount];
    // M78-P4c, DLSS Ray Reconstruction (renderer_upscale.cpp, render_upscale_rr.h). rrPrep draws the guides the denoiser-upscaler reads
    // (rrNormal: the world normal and the roughness, rrDiffuse and rrSpecular: the albedos) at the render resolution. They are kept while
    // the setting is on and the render size holds; turning it off, a refusal, another upscaler drawing or a new render size gives them
    // back (free_rr_images). rrProbe: what the provider answered for this GPU, asked
    // once (rrProbed). rrFailed: a frame was refused (or the machine cannot run it): every frame after draws with Super Resolution, and
    // render.supports says why (rrFailedWhy). rrWarned*: the one warning of a frame that cannot use it (not linear, dynamic resolution) and
    // of an unavailable setting. rrLastUsed: the last DLSS frame was drawn with Ray Reconstruction (tests).
    render::RrGuidesPrep rrPrep;
    Target rrNormal, rrDiffuse, rrSpecular, rrDepth;
    render::VendorProbe rrProbe;
    bool rrProbed = false;
    bool rrFailed = false;
    std::string rrFailedWhy;
    bool rrWarnedUnavailable = false, rrWarnedFrame = false;
    bool rrLastUsed = false;
    const render::VendorProbe& rr_probe();  // asked once; a refused frame says so
    bool run_rr_guides(const render::UpscaleInput& in, const PassContext& c, const Target* prepass,
                       const Target* gbAlbedo, const Target* gbMaterial);
    void free_rr_images();
    // M78, low latency (render_latency.h; renderer_latency.cpp): the setting, the SDK or pacing that runs it and the markers. Attached to the device
    // at init and detached before the device goes.
    render::LatencyController latency;
    void set_latency_env(render::FeatureEnv& env);  // render.supports: the three low-latency providers' answers
    // M78, frame generation (render_framegen.h; renderer_framegen.cpp): the setting, the provider that runs it and the readout. Attached to the
    // device at init (with `frameGenHooked`: RendererDesc::frameGeneration) and detached before the device goes. hudlessTarget: the output
    // picture before the screen-space items (a copy, made only on a frame the provider is given, when the items are drawn into outTarget);
    // prepSerial: the game frame whose depth and motion images mfxDepth / mfxMotion hold.
    render::FrameGenController framegen;
    Target hudlessTarget;
    int hudlessIdleFrames = 0;  // frames in a row the copy was not needed: it is freed at kOutputIdleFrames
    std::uint64_t prepSerial = ~std::uint64_t(0);
    bool prepReversed =
        false;  // ... and whether they were made with the reversed infinite depth (the provider that wants it, run_upscale_prep)
    // The camera of the frame the temporal upscaler is made for, as frame generation tells it to its provider.
    struct FrameGenCamera {
        bool perspective = true;
        float nearPlane = 0.1f, farPlane = 1000.0f;
        Vec3 position{0, 0, 0}, right{1, 0, 0}, up{0, 1, 0}, forward{0, 0, -1};
        Mat4 view;
    };
    FrameGenCamera fgCamera;
    std::vector<const char*>
        outputPassLog;  // the output passes run by the last frame, in order (tests: RendererTestAccess::output_passes)
    // The running frame-generation provider's required low-latency SDK (DLSS: Reflex, XeSS: XeLL) => the latency controller runs it
    // (FrameGenProvider::requires_reflex, the XeSS slot; LatencyController::require_driver).
    void sync_framegen_latency();
    void set_framegen_env(render::FeatureEnv& env);  // render.supports: the three frame-generation providers' answers
    // outTarget into hudlessTarget: a copy, or (`grade` set) drawn through the colour filter, as the picture shown is.
    void framegen_hudless_copy(const PassContext& c, const PostPlan* grade);
    // The provider's dispatch; `filtered`: the picture shown is outFilterTarget (the colour filter ran), else outTarget.
    void framegen_pass(const render::FrameGenPassPlan& plan, bool filtered, const PassContext& c);
    float mfxJitterSign = 1.0f, mfxMotionSign = 1.0f;
    void free_mfx_images();
    const render::metalfx::Support& metalfx_support();
    bool metalfx_upscale(const render::UpscaleInput& in, const Target& src, Target& out, const PassContext& c);
    bool metalfx_fail(const std::string& why);
    bool ensure_mfx_target(Target& t, const char* label, gpu::PixelFormat format, int w, int h);
    // The preparation pass and the history rule MetalFX and the vendor SDKs share (renderer_metalfx.cpp): run_upscale_prep draws mfxDepth and
    // mfxMotion; scaler_history_valid says whether the history of the frame before still holds (and gives the key scaler_history_note stores).
    // `reversedNear` > 0 makes the depth image the reversed infinite depth reversedNear / distance (VendorUpscaler::wants_reversed_depth).
    bool run_upscale_prep(const render::UpscaleInput& in, const PassContext& c, const Target* prepass,
                          const Target* velocity, bool histValid, float reversedNear = 0.0f);
    bool scaler_history_valid(const render::UpscaleInput& in, std::uint64_t& config) const;
    void scaler_history_note(std::uint64_t config);
    bool ensure_output_target(Target& t, const char* label, gpu::PixelFormat colorFormat, bool withDepth);
    // The images the screen-space items need at the output size: outTarget in the format the picture has there (`display`: after a final
    // pass, so display values; else the scene format), with the depth the items are drawn with when `depth`; the render-resolution
    // filterTarget a final pass writes into (display); outFilterTarget when the colour filter runs after the items (`filter`).
    bool ensure_hud_output(bool display, bool filter, bool depth);
    // render_world's decision (hudAtOutput) for the cameras of `lastCams` that draw a pixel, the same ones plan_job plans.
    bool decide_hud_at_output(World& world);  // renderer_draw.cpp
    void free_output_targets();
    void run_upscale(Target& out, const PassContext& c);
    void stretch_upscale(const render::UpscaleInput& in, Target& out, const PassContext& c);
    void spatial_upscale(const render::UpscaleInput& in, Target& out, const PassContext& c);
    bool ensure_spatial_target(gpu::PixelFormat colorFormat);
    // The depth and normal prepass (renderer_draw.cpp, plan_job and prepass_pass). `debugView` shows it (Renderer::set_debug_view),
    // `forceEffects` pretends the stack has those effects (tests). prevViewProj: the view-projection each camera drew its last frame
    // with, for the effects that reproject (PostPlan::prevViewProj); an entry the camera did not refresh in the frame before is dropped.
    DebugView debugView = DebugView::None;
    std::uint32_t forceEffects = 0;
    // M76 motion vectors (renderer_draw.cpp, fill_prev_models): `forceVelocity` (RendererTestAccess::force_velocity) asks every camera for
    // the velocity image. `prevModels` is what the renderer keeps of each drawn entity from one game frame to the next, only for cameras
    // that ask: its model matrix of the frame before (`prev`) and of the last frame it was drawn (`cur`), with the postSerial of that
    // frame. An entity not drawn in the frame before, or new, has prev = cur: no motion of its own. origin_shifted moves both.
    bool forceVelocity = false;
    // PostPlan::needsVelocity of the last job plan_job planned (RendererTestAccess::last_job_needs_velocity): what the job asked for, before
    // the GPU is asked whether it can make the image.
    bool lastJobNeedsVelocity = false;
    // RendererTestAccess::probe_camera: the entity bits of the only camera whose velocity and reactive images the probes copy (probeCameraOnly false = every camera, the last wins; the first entity's bits are 0).
    std::uint64_t probeCamera = 0;
    bool probeCameraOnly = false;
    // RendererTestAccess::read_velocity: while forceVelocity is on, a pass copies the velocity image of the last camera into this RGBA16F
    // image (rg = the vector as it is, prepass_view.glsl mode 4), which a test reads back after the frame.
    Target velocityProbe;
    // The same for the reactive mask (R8; the copy holds r in the first channel): RendererTestAccess::read_reactive.
    Target reactiveProbe;
    // `mode`: prepass_view.glsl's mode of the copy: 4 the velocity's two channels (the default), 7 the four channels as they are.
    void velocity_probe_pass(DrawContext& ctx, const Target& src, Target& probe, const char* label, float mode = 4.0f);
    // M79-P0c, the thin G-buffer (renderer_draw.cpp, plan_prepass and gbuffer_pass; docs/design/ARCHITECTURE_RENDERING_GBUFFER.md): `forceGbuffer`
    // (RendererTestAccess::force_gbuffer) asks every camera for the two images and keeps a copy of the last camera's in gbufferProbe (RGBA16F,
    // the four channels as they are), which read_gbuffer gives back. gbufferWarned: the one warning of images the GPU refused.
    bool forceGbuffer = false;
    bool gbufferWarned = false;
    Target gbufferProbe[2];
    bool read_gbuffer(int which, std::vector<float>& out, int& w, int& h, std::string* error);
    void gbuffer_pass(DrawContext& ctx, const Target& albedo, const Target& material, const Target& pre);
    bool read_velocity(std::vector<float>& out, int& w, int& h, std::string* error);
    bool read_reactive(std::vector<float>& out, int& w, int& h, std::string* error);
    struct PrevModel {
        Mat4 prev, cur;
        std::uint64_t frame = 0;
    };
    std::unordered_map<std::uint64_t, PrevModel> prevModels;  // by Entity::bits()
    std::uint64_t prevModelsPruned = ~std::uint64_t(0);       // the postSerial prevModels was last swept in
    // The joint palettes of a skinned entity (M76-P1b), one per skin of its Animator, of the last frame it was drawn (`cur`) and the one
    // before (`prev`), at most kMaxSkinJoints joints each. Same keys and life as prevModels.
    // A palette is in model space, so an origin shift (renderer_origin.cpp) leaves it as it is.
    struct PrevPalette {
        std::vector<std::vector<Mat4>> prev, cur;
        std::uint64_t frame = 0;
    };
    std::unordered_map<std::uint64_t, PrevPalette> prevPalettes;  // by Entity::bits()
    // The matrix of the 2D items that move (M76-P1d, QuadItem::motionKey) in the world, of the last frame they were drawn (`cur`) and the one
    // before (`prev`), with the postSerial of that frame; same keys and life as prevModels. origin_shifted moves both.
    struct PrevQuadOrigin {
        Mat4 prev, cur;
        std::uint64_t frame = 0;
    };
    std::unordered_map<std::uint64_t, PrevQuadOrigin> prevQuadOrigins;  // by Entity::bits()
    std::uint64_t prevQuadsPruned = ~std::uint64_t(0);  // the postSerial prevQuadOrigins was last swept in
    std::vector<float>
        quadMotionStream;  // build_quad_stream: the per-vertex motion of `stream` (vertex buffer 1 of the quad motion programs)
    std::vector<float>
        prevPalTexels;  // upload_prev_palettes' CPU copy of the palette image (the capacity stays from frame to frame)
    // The game time (World::time, seconds) of the last frame that kept the histories (`clockCur`, the postSerial `clockFrame`) and of the one
    // before (`clockPrev`): what a material's vertex() sees as fa_time.x in the second run of the motion vectors.
    float clockPrev = 0.0f, clockCur = 0.0f;
    std::uint64_t clockFrame = ~std::uint64_t(0);
    bool warnedNoVelocity = false;  // one warning for a GPU with no RG16F render target
    bool warnedPrevPalette =
        false;  // one warning for skinned draws that got no previous palette (upload_prev_palettes)
    // Tests (RendererTestAccess::force_no_velocity_target): behave as a GPU that cannot render to RG16F.
    bool noVelocityTarget = false;
    // Tests (RendererTestAccess::force_no_palette_sampling / set_palette_row_cap): behave as a GPU that cannot sample RGBA32F in the vertex stage,
    // and as one whose palette image holds only `paletteRowCap` rows (kPrevPaletteMaxRows: the real limit, 5461 skinned draws).
    bool noPaletteSampling = false;
    int paletteRowCap = kPrevPaletteMaxRows;
    void fill_prev_models(DrawContext& ctx);
    void fill_quad_motion(DrawContext& ctx);
    void keep_prev_palette(const MeshItem& mi);
    const std::vector<Mat4>& prev_palette(const DrawContext& ctx, const MeshItem& mi, int skin) const;
    void upload_prev_palettes(DrawContext& ctx);
    // Tests (renderer_test_access.h): called once per frame when everything is gathered and the passes are about to
    // run, so a test can change the world's resources (destroy a compute buffer) between the gather and the draw.
    std::function<void()> beforeFrameGraph;
    struct PrevCamera {
        Mat4 viewProj;
        std::uint64_t frame = 0;  // the postSerial it was drawn in
        std::uint64_t worldFrame =
            0;        // world.frame() when it was drawn: a jump back or far ahead is a cut (a scene load, a seek)
        Mat4 before;  // what a second job of the same camera in the same frame reprojects from (`hadBefore`)
        bool hadBefore = false;
        int jobs = 0;  // how many jobs of this camera came before in the frame (the custom passes' histories)
        // M76: what the camera DREW with last frame (viewProj above is the unjittered one, the matrix every reprojection of the
        // effects uses): the viewProj with the sub-pixel jitter and the jitter in render pixels (0 when the camera did not jitter),
        // and the same two for `before`. The temporal antialiasing and upscaler resolve the history with them.
        Mat4 jittered;
        Vec2 jitterPx{0, 0};
        Mat4 beforeJittered;
        Vec2 beforeJitterPx{0, 0};
    };
    // M76: the sub-pixel jitter (fa/scene/jitter.h). A camera is jittered when its stack has TemporalAA on AND the renderer draws that
    // effect (render_features.cpp effect_drawn), is a camera of the game's frame (not a CameraView, a render target or a capture) and the TAA passes can run (TaaFx::unavailable); `jitterForce` (RendererTestAccess::
    // force_jitter) jitters every camera with that many phases (0 = off) so the tests, and the passes that turn the effect on, can run
    // before the effect is drawn.
    int jitterForce = 0;
    float frameDt =
        0.0f;  // the dt of the frame being rendered (seconds, the engine clock): the vendor upscalers' frame time
    UpscalerSettings
        upscaler;  // Renderer::set_upscaler: the mode, quality and sharpness the upscale stage draws with (M76)
    QualityLimits quality;   // Renderer::set_quality: the graphics preset's limits on what the scene asks for (M76)
    bool qualityOn = false;  // quality != QualityLimits{}: the frame pays nothing while it is off
    // Compiles the TAA shaders the first time a camera asks for the effect (a camera must not jitter for a pass that cannot run).
    int jitter_phases(const CameraInfo& ci, bool mainFrameCamera);
    // The texture LOD bias of a camera that jitters (M76-P4b): 0 when `phases` is 0 or a test forced the jitter.
    float mip_bias(const CameraInfo& ci, bool mainFrameCamera, int phases) const;
    std::unordered_map<std::uint64_t, PrevCamera> prevViewProj;  // by Entity::bits() of the camera
    // M75.4b, the floating origin (renderer_origin.cpp; docs/BIG_WORLDS_STREAMING.md "Floating origin"). The renderer watches the world it was last
    // given (update / render_world call watch_world every frame: one pointer compare when nothing changed) and, when the world rebases,
    // moves what it keeps in world space across frames by the same offset: the cameras the motion vectors reproject from, the 2D GI
    // field's geometry and history, the realtime GI's anchors, the occlusion debug boxes. Everything else is rebuilt from the world each
    // frame (the cameras, the occluders, the terrain selection, the shadow rows) or snaps in absolute space (the cascades, the 2D GI
    // field). The callback runs on the main thread between frames, when no render job exists.
    World* originWorld = nullptr;  // the world the observer is registered in (null: none)
    std::weak_ptr<const void>
        originWorldAlive;            // expires when that world is destroyed: then the observer is gone with it
    int originObserver = 0;          // World::on_origin_shifted's id
    std::uint64_t originShifts = 0;  // rebases followed since the renderer was made (RendererTestAccess)
    void watch_world(World& world);
    void watch_world_if_free(World& world);  // captures: watches `world` only when no other live world is watched
    void unwatch_world();
    void origin_shifted(World& world, const DVec3& offset);
    bool fogMissingWarned = false;  // one warning when a planned fog could not be drawn
    bool sceneCopyWarned = false;   // one warning per scene when the image of a scene copy could not be made
    bool sceneCapWarned =
        false;  // one warning per scene when a camera has more runs of scene-reading draws than kMaxSceneCopies
    bool prepassWarned = false;   // one warning when the prepass cannot be made
    bool coverageWarned = false;  // one warning when a sprite outline has no coverage image to read
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
    bool float_display() const { return gpu.display_format() == gpu::PixelFormat::Rgba16F; }
    // The fragment uniforms of present(): the encode for the output the window has now (output()), the light let through up to
    // the frame's headroom when its final pass went above white.
    blit_blit_fs_params_t present_params() const;
    // Tests (renderer_final_floats / renderer_present_floats): the finished picture as floats, copied as it is (`present`
    // false) or through present()'s encode, read back from an RGBA16F image of physW x physH.
    bool read_floats(bool present, std::vector<float>& out, std::string* error);
    Target floatTarget;               // the RGBA16F image read_floats draws into (tests only; freed with the targets)
    bool shadowTargetFailed = false;  // the shadow map could not be made: no shadows until a resize
    // The shadow atlas (shadow_cascades.h): R32F colour + depth (shadowTarget.texView is what the mesh programs sample). It grows to the
    // part of the atlas a frame uses and never shrinks while the renderer lives. A target a later job of the frame outgrew is kept in
    // shadowRetired (the earlier jobs of the same frame still draw into it) and freed when the next frame's graph begins.
    Target shadowTarget;
    std::vector<Target> shadowRetired;
    static constexpr std::uint64_t kShadowAtlasMaxBytes = 512ull << 20;  // the most the atlas may take (R32F + depth)
    bool warnedNoFloat32 = false;  // the "no shadows without float32 targets" warning, once

    DebugDraw debug;
    RenderStats stats;
    // The custom materials already counted in stats.materials this frame (a material drawn by two cameras or two passes
    // counts once).
    std::vector<const MaterialAsset*> materialsCounted;
    void count_material(const MaterialAsset* m) {
        if (std::find(materialsCounted.begin(), materialsCounted.end(), m) != materialsCounted.end()) return;
        materialsCounted.push_back(m);
        ++stats.materials;
    }
    // The rendering cameras of the last update()/draw in draw order (never empty after the first one: a world without a camera
    // gets one default camera). [0] is "the" camera: the lowest depth.
    std::vector<CameraInfo> lastCams;
    // The same cameras seen from their REAL pose, filled only while render interpolation blends a camera (it or an ancestor): scripts, picking and UI
    // hit tests ask these (camera_for), so an answer never depends on alpha. Empty = lastCams.
    std::vector<CameraInfo> logicCams;
    bool warnedNoLight = false;
    bool warnedLightsDropped = false;   // one warning when a view has more lights than it can light
    bool warnedClusterClipped = false;  // one warning when a cluster or view list ran over its limit
    bool warnedDirectionalIes = false;  // one warning each for a Light.ies on a directional light,
    bool warnedAreaCookie = false;      // a Light.cookie on an area light
    bool warnedAreaIes = false;         // and a Light.ies on an area light (none of them uses it)
    // M75.2, occlusion culling on the CPU (renderer_occlusion.cpp): the depth buffer of the last camera job that had occluders (every job
    // rasterises its own), the caps, and what the report and the debug view show.
    render::OcclusionBuffer occlusion;
    render::OcclusionLimits occlusionLimits;  // the defaults; a test lowers them to reach a cap
    bool warnedOccluderCap = false, warnedOcclusionFrameCap = false;
    std::set<std::uint64_t>
        warnedOccluders;  // entities whose Occluder was reported (no mesh, unreadable mesh): once each
    // Occluder.mesh names that could not be read, with the error and the frameSerial of the failure: not read from disk again
    // every frame, but tried again after kOccluderRetryFrames frames (a file that appears later, a fixed path, a reloaded project).
    struct OccluderMeshFailure {
        std::string error;
        std::uint64_t frame = 0;
    };
    static constexpr std::uint64_t kOccluderRetryFrames = 600;
    std::map<std::string, OccluderMeshFailure> occluderMeshErrors;
    struct OcclusionShown {
        struct Box {
            std::array<Vec3, 8> corners;  // world space; bit 0 = x, 1 = y, 2 = z of the corner
            bool culled = false;          // false: an Occluder; true: a mesh the culling left out
        };
        bool valid = false;
        std::string camera;
        int occluders = 0, tests = 0, occluded = 0, coveredCells = 0, sourceTriangles = 0;
        std::vector<Box> boxes;  // only while the debug view is on
    };
    OcclusionShown occlusionShown;  // this frame (cleared when it begins)
    OcclusionShown occlusionPrev;   // the frame before: what the debug view draws
    // True when it rasterised an occlusion buffer for this camera (`occlusion` holds it), false when nothing was tested.
    bool occlude_meshes(World& world, Frame& fr, bool z01, std::vector<MeshItem>& meshes);
    // M75.2, areas and portals (renderer_portals.cpp): (entity, what) pairs already warned about (what: an unknown areaId, or a code).
    std::set<std::pair<std::uint64_t, std::int64_t>> warnedPortalEntities;
    void portal_cull_meshes(World& world, Frame& fr, std::vector<MeshItem>& meshes);
    // The OcclusionArea and OcclusionPortal boxes of the frame, gathered once and shared by its cameras (the same world, the same
    // scope subtree); render() and every capture drop it, since the world may have changed between them.
    struct PortalGather {
        bool valid = false;
        const World* world = nullptr;
        std::uint64_t scope = 0;
        std::vector<render::PortalAreaBox> areas;
        std::vector<render::PortalBox> portals;
        std::vector<std::string> ids;  // the distinct area ids as text, for the did-you-mean
    } portalGather;
    void gather_portal_boxes(World& world, Entity scopeRoot, PortalGather& into);
    void occlusion_overlay();
    // M75.2b, occlusion culling on the GPU with a hierarchical depth image (renderer_hiz.cpp, hiz.h). One HizCamera per camera that
    // is culled this way: the storage buffer its reduce pass fills, the ring that reads it back, the poses and the pyramid.
    struct HizCamera {
        struct Flight {              // a copy of the cells that was asked for and has not been taken yet
            gpu::ReadTicket ticket;  // the read of the cells, polled by hiz_submit
            render::HizPose pose;
            int w = 0, h = 0;
            std::uint64_t frame = 0, worldFrame = 0;
        };
        std::uint64_t key = 0;
        int w = 0, h = 0;               // cells of `cells` (the aspect of the camera's rectangle)
        gpu::Device* device = nullptr;  // the device the buffer lives on (the renderer's, which outlives the camera)
        gpu::Buffer cells{};
        gpu::View cellsView{};
        std::vector<Flight> flights;  // oldest first
        bool reduced = false;         // a reduce pass wrote `cells` and no copy of it was asked for yet
        Flight reducedInfo;           // its pose, size and frame
        render::HizPyramid pyramid;   // the newest picture that came back
        render::HizPose pose;         // the camera of that picture
        std::uint64_t pyramidFrame = 0, pyramidWorldFrame = 0;
        std::uint64_t usedFrame = 0;  // the frameSerial of the last frame this camera was culled or reduced in
        std::string name;
        HizCamera() = default;
        HizCamera(const HizCamera&) = delete;
        HizCamera& operator=(const HizCamera&) = delete;
        ~HizCamera();
    };
    std::map<std::uint64_t, std::unique_ptr<HizCamera>> hizCams;  // by camera entity bits
    gpu::Shader hizShader{};
    int hizShaderState = 0;  // 0 not tried, 1 made, -1 refused
    int hizSupport = 0;      // 0 not asked, 1 yes, -1 no
    std::string hizWhy;      // why not
    bool hizOn = false;      // the mode of this frame's world resolved to the pyramid
    bool warnedHizMode = false, warnedHizCameras = false;
    const World* hizWorld = nullptr;
    std::string hizScene;
    // What `render.occlusion` and the debug view say about the GPU culling of a frame (summed over the cameras culled this way).
    struct HizShown {
        bool valid = false;
        std::string camera;  // the last camera culled this way
        int cameras = 0, usable = 0, tests = 0, hidden = 0;
        int cells = 0, cellsDown = 0, levels = 0, coveredCells = 0;
        int ageFrames = -1;            // frames between the newest picture and this one (-1: none yet)
        std::string why;               // the reason the last camera drew without culling, when it did
        std::array<int, 8> reasons{};  // the tests by HizTestInfo::Why
        int greyLevel = -1, greyW = 0, greyH = 0;
        std::vector<std::uint8_t> grey;  // a coarse level of the pyramid, for the debug view (only while it is on)
        std::vector<OcclusionShown::Box> boxes;
    };
    HizShown hizShown, hizPrev;
    bool warnedHizRead = false;
    bool warnedHizPipeline = false;
    bool warnedShadowRecord = false;  // the parallel shadow recording failed once (logged once)
    int hizReduces = 0;               // reduce passes run since the renderer was made (tests)
    // The mode of the world's SceneSettings against what this GPU can do; one warning when `gpu` was asked for and cannot be had.
    bool hiz_resolve(World& world);
    // Start of Renderer::begin_frame (before sokol's frame begins): ask for the copy of every reduce of the frame before and take the
    // copies that came back.
    void hiz_submit();
    // Frame start of render(): the world, the mode, the cameras not drawn any more.
    void hiz_begin_frame(World& world);
    void hiz_release();
    void hiz_shift(const Vec3& off);
    static render::HizPose hiz_pose_of(const CameraInfo& cam);
    // gather_meshes: the camera's meshes tested against its pyramid. Returns the camera's HizCamera (null when the camera is not culled
    // this way: past the cap, so the Occluders cull it).
    // Only the cameras that draw the game's picture call it: a view job (capture_camera, a CameraView) has no pyramid, because
    // hiz_submit only runs when a frame begins and a capture's reduce could never come back within it.
    HizCamera* hiz_cull(World& world, Frame& fr, std::vector<MeshItem>& meshes);
    // The reduce pass of one job: the compute pass that fills the camera's cells from its prepass image. With
    // Gpu::async_compute() it runs on the compute queue (M77-P10d): the graphics queue waits for it before the first pass that
    // declares `prepassHandle` (the prepass's pool target), or at the frame's end.
    void hiz_reduce_pass(gpu::CommandList& cmd, HizCamera& hc, const Target& prepass, const render::HizPose& pose,
                         std::uint64_t worldFrame, std::uint64_t prepassHandle = 0);
    void hiz_overlay();
    std::string hizModeName = "cpu";  // SceneSettings.occlusionMode of the last frame's world
    // The "gpu" object of Renderer::occlusion_report: what the depth pyramid did in the last frame; `level` of the pyramid is saved to
    // `savePath` (a .png) when one is given.
    Json hiz_report(std::string_view savePath, int level);
    // The light atlas (light_atlas.h; view 25): the LTC tables, the cookies and the IES profiles, made at the first light that needs them.
    LightAtlas lightAtlas;
    // M73.5b, the projected decals (renderer_decals.cpp). A Decal of the view: its world matrix and the component (valid until the
    // frame's jobs have run, like a MeshItem's MeshRenderer).
    struct DecalItem {
        Mat4 world;
        const Decal* decal = nullptr;
    };
    // The atlas of the decal textures: one RGBA8 image with mips (view 27), rebuilt when a decal names a texture it does not hold, when a
    // texture is reloaded (Assets::reload_generation) or when the scene's colour space changes; known = every path the build was asked for
    // (a texture that failed or did not fit is not asked for again until then). A replaced image is kept in decalRetired until the next
    // frame's graph begins (an earlier job of the same frame may still draw with it).
    struct DecalAtlasState {
        gpu::Image image{};
        gpu::View view{};
        render::DecalAtlasLayout layout;
        std::set<std::string> known;
        std::uint64_t generation = 0;
        int colorMode = 0;
        bool built = false;
        std::uint64_t bytes = 0;
    };
    DecalAtlasState decalAtlas;
    std::vector<std::pair<gpu::Image, gpu::View>> decalRetired;
    bool warnedDecalAtlas = false, warnedDecalCap = false, warnedDecalClipped = false, warnedDecalPaths = false;
    std::set<std::string> warnedDecalTextures;  // the textures reported as unreadable or left out (once each)
    // Makes sure the atlas holds `paths` (every texture of every Decal of the world); false when decals cannot be drawn with textures.
    bool ensure_decal_atlas(const std::vector<std::string>& paths, bool linear);
    // The records of the decals of a view, in drawing order, and their boxes; a decal whose albedo is not in the atlas is skipped.
    // `skipped` counts the decals left out for a missing albedo.
    void make_decal_records(const std::vector<DecalItem>& items, bool linear, render::DecalPack& pack,
                            std::vector<render::DecalBox>& boxes, int& skipped);
    static std::string decal_path_key(const std::string& path);
    void free_retired_decal_atlases();
    void destroy_decal_atlas();
    // The image a mesh program reads at view 27: the atlas, or the white image while there is none.
    gpu::View decal_view_or(gpu::View fallback) const { return decalAtlas.view.id ? decalAtlas.view : fallback; }
    void collect_decals(DrawContext& ctx);
    bool warnedShadowBudget =
        false;  // one warning when point or spot lights lost their shadow to the atlas or view budget
    // SceneSettings.skyMaterial: the last material that could not draw the sky and was reported (one log line per
    // material).
    std::string warnedSkyMaterial;
    // The sprite materials whose batches were skipped because their instanced layout changed after a hot reload (one
    // log line each).
    std::unordered_set<std::string> warnedSpriteInstLayout;
    MaterialAsset* sky_material(const SceneSettings& ss);
    std::string
        warnedViewport;  // the last "bad Camera.viewport" problem logged (a viewport a script sets live is clamped)
    std::unordered_set<std::string>
        warnedCustomPass;        // the problems of PostProcess.customPasses entries already logged (once per scene)
    bool postBypass = false;     // Renderer::set_post_bypass: draw without any post-processing stack (the editor's A/B)
    bool warnedCameras = false;  // the "more cameras than the limit" warning, once per scene
    bool warnedLights2d = false;        // the "more Light2D in view than the budget" warning, once per scene
    bool warnedSpriteMesh = false;      // the "too many mesh cells" warning, once per scene
    bool warnedGradientStops = false;   // the "malformed gradientStops" warning, once per scene
    bool warnedCookies2d = false;       // the "more cookies than the atlas holds" warning, once per scene (M74)
    bool warnedLightBuffers2d = false;  // the "more light layer sets than light buffers" warning, once per scene (M74)
    std::string lights2dScene;          // the scene path the 2D warnings of this renderer belong to
    // The 2D light buffer (light.glsl): the point lights of the frame added up, read by the lit visuals. Made when a frame
    // needs it, at lightScale of the target's size; kept while the size and the format stay.
    Target lightTarget;
    // M74 light layers: the buffers of the other sets of lights (docs/rendering/RENDERING_2D_EMISSION.md); made only for a frame whose
    // receivers reach more than one set. lightBuffers = how many exist (>= 1 once the first was made).
    Target extraLightTargets[kMaxLightBuffers2D - 1];
    int lightBuffers = 0;
    const Target& light_buffer(int i) const {
        return i <= 0 ? lightTarget : extraLightTargets[std::min(i, kMaxLightBuffers2D - 1) - 1];
    }
    // The cookie atlas (M74, Light2D.cookie): the cookies of the frame copied into cells of one image (light_cookie.glsl).
    Target cookieTarget;
    bool cookieTargetFailed = false;
    // What the atlas holds now: the target, the textures' reload generation and, per cell, the GPU view and the region the cell was copied from
    // (cookie_pass copies only when this differs from the frame's cells; empty = the atlas holds nothing).
    std::vector<std::uint64_t> cookieStamp;
    int lightW = 0, lightH = 0;
    gpu::PixelFormat lightImgFormat = gpu::PixelFormat::None;
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
        gpu::Image img{};
        gpu::View view{};
        std::uint64_t key = 0;
        std::uint64_t usedFrame = 0;
    };
    std::vector<ShadowRowsSlot> shadowRowsRing;
    std::uint64_t frameSerial =
        0;  // counts the frame graphs begun (begin_frame_graph); never 0 while a frame is planned
    // The frames of the game's pictures (begin_frame_graph(true)): what the auto exposure counts, so a capture_world between two
    // frames does not make the exposure jump to the measured value.
    std::uint64_t postSerial = 0;
    bool framePost = true;  // the frame being planned is one of the game's (false in capture_world)
    void trim_shadow_rows();
    bool updated = false;  // update() ran since the last draw
    ScaleMode scaleMode = ScaleMode::Fit;
    std::vector<Vertex2D> stream;
    std::vector<float>
        instStream;  // the instanced values of the sprite-material batches of `stream`, per vertex (QuadBatch::instFirst)

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
    bool viewAlphaWarned = false;  // one warning that R11G11B10 images have no alpha (view_image)
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
    // Sets (or, with an empty name, clears) targetSelf. The per-frame material cache holds textures resolved under the
    // old value (a material whose params name "target:X" gets the checker only for X's own camera), so it is dropped.
    void set_target_self(const std::string& name);
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
    bool ensure_ldr_targets(int count);  // the first `count` of ldrMid
    void release_idle_ldr_targets();
    // One full-screen pass of post.glsl: `src` (a texture view of the finished picture) through the plan's final pass (`finalPass`: conversion and effects) and the
    // colour filter `filter` into `dst`; `expo` is the adapted exposure or a dummy image. `keepMsaa`: an MSAA destination keeps its
    // multisampled image (a pass that draws over it follows). `rect`: the camera's rectangle of `dst` (whole by default; see
    // run_post_pass); `load`: keep what `dst` holds outside the rectangle (the pass before it drew there) instead of drawing every pixel.
    // `aux`: the image the outline reads (PostPlan::outline_source of the frame), or a null view when there is none.
    void post_pass(const PostPlan& pp, bool finalPass, int filter, bool autoExposure, gpu::View src, gpu::View expo,
                   gpu::View aux, Target& dst, const char* label, bool keepMsaa, const PostRect& rect = {},
                   bool load = false, const PostSlice& slice = {});
    // The 8-bit picture of a game or view image (top row first). In a float scene format the image is first drawn into an
    // RGBA8 copy (clamped at white, as the screen shows it), because the per-backend readbacks read RGBA8 only.
    bool read_rgba8(gpu::Image image, gpu::View view, int w, int h, std::vector<std::uint8_t>& out, std::string* error,
                    bool premultiplied = false, bool displayValues = false);
    Target readbackTarget;  // the RGBA8 copy read_rgba8 makes, kept for the next capture of the same size
    void free_read_image();
    // True when the images and views of the game target were made (create_targets) and the GPU accepted them.
    bool game_targets_valid() const;
    int readW = 0, readH = 0;
    // The image of the finished frame: the final pass's (or the colour filter's) picture when the last frame had one, else the game target.
    // The picture of the render resolution (what the upscale stage reads), else the image of the output size the stage made.
    const Target& scene_target() const { return filterActive ? filterTarget : hudActive ? hudTarget : gameTarget; }
    const Target& final_target() const {
        return outFilterActive ? outFilterTarget : outActive ? outTarget : scene_target();
    }
    int final_w() const { return final_target().w > 0 ? final_target().w : physW; }  // the size of the finished picture
    int final_h() const { return final_target().h > 0 ? final_target().h : physH; }
    gpu::Image final_image() const { return final_target().texture_image(); }
    gpu::View final_view() const { return final_target().texView; }
    // The picture the editor viewport shows (Renderer::game_target_texture): the finished game image in a gamma scene; in a linear one,
    // when the editor asked for it (Renderer::set_editor_view), the 8-bit encoded copy update_editor_copy() makes after each frame
    // (an empty handle until the first one exists). The final pass's picture is shown as it is, except when it went above paper white
    // (an HDR output; the editor's window never switches, but a viewport that can show extended values would show them brighter
    // than the SDR present() does): then the 8-bit copy clamps it to [0, 1].
    gpu::Image display_image() const;
    gpu::View display_view() const;
    bool editorView =
        false;  // set_editor_view(true): make the 8-bit copy of a linear scene (or of a picture above white)
    Target
        editorTarget;  // the copy: RGBA8, only while the editor asked and it is needed (see editor_copy_wanted); freed when not
    // The viewport shows the copy: a linear scene not yet encoded by the final pass (the copy encodes it), or a final pass picture
    // that went above paper white (the copy clamps it).
    bool editor_copy_wanted() const;
    void update_editor_copy();
    bool create_shadow_targets(int width, int height);
    void free_retired_shadow_targets();
    bool ensure_light_target(float scale, int buffers = 1);
    // M74 (renderer_lights2d.cpp): gives the cookies of the frame their cells (Light2DData::cookieCell, warns once past the atlas) and
    // returns the textures by cell; empty when no light has one or the atlas cannot be made.
    std::vector<TextureAsset*> plan_cookies(Frame& fr);
    void cookie_pass(const std::vector<TextureAsset*>& cells);
    bool ensure_cookie_target();
    gpu::View upload_shadow_rows(const Frame& fr);
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
    LodFades lodFades;  // the levels of detail the cameras picked and the cross-fades running (renderer_lod.h)
    InstanceParamCache instanceParams;  // the packed per-instance material params of each entity (mesh_batch.h)
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
        // A view job of Renderer::capture_camera: the custom passes of the camera's PostProcess (fr.cam.postStack) run
        // over its picture, and no other effect of the stack. `target` is the view's own target (its resolved image is
        // read and written); `history` tells the passes that keep a history which frame of the capture this is.
        bool customPost = false;
        const Target* target = nullptr;
        CustomHistoryFrame history;
        // A face of a realtime GI capture (renderer_gi.cpp): the job also draws the depth prepass of its camera twice (the front faces, the back
        // faces) and the "gi-distance" pass turns both into the distance picture `gi->distIndex` of the probe system. `gi->drawn` tells
        // whether it did (a face with no opaque mesh has no picture: every ray of it is maxDistance long).
        GiFacePlan* gi = nullptr;
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
    // The reflection probes (renderer_probes.cpp). probes_plan() runs after the cameras' jobs and before run_frame_graph(): it keeps the
    // atlas tiles of the probes in the world, draws the faces of the realtime captures as view jobs ("probe:<n>") and decides the uploads.
    // probes_finish() runs after run_frame_graph(): it copies the faces into the scratch cubes, filters the completed captures into the
    // atlas, uploads the baked pages and writes the sky's entry.
    void probes_plan(World& world);
    void probes_finish();
    // The boxes of this frame's probes that hold a capture (probe_select.h), built once per frame before the scene's meshes pick theirs
    // (gather_meshes); kept for fill_fs, which looks the picked probes' tiles up through them. Empty = every mesh reflects the sky.
    std::vector<ProbeVolume> probeVolumes;
    void probes_build_volumes(World& world);
    // The reflection picks of the main scene's meshes that reach a probe (entity bits, pick), kept after the scene is reset: what
    // Renderer::probe_mesh_report (render.probes with `entity`) answers from. Filled by probes_note_picks() right after the scene is built.
    std::vector<std::pair<std::uint64_t, ProbePick>> meshPicks;
    void probes_note_picks();
    // The mesh whose picks probes_note_picks keeps (render.probes with `entity`); 0 = none.
    std::uint64_t meshPickWatch = 0;
    // Writes the sky's entry of the atlas from the baked environment cube when it is not there yet or is out of date (the tail of the
    // "sky-env" pass, and probes_plan for an atlas that was just made).
    void probes_write_sky();
    // The reflection part of the fragment parameters of one draw: the atlas, the sky's tile and the (up to two) probes the mesh reflects.
    void fill_probe_fs(const DrawContext& ctx, const MeshItem& mi, bool lit, mesh_fa_mesh_fs_params_t& fu);
    // The realtime GI grids (renderer_gi.cpp), a part of the same frame: gi_plan() runs inside probes_plan() once the atlas exists (it has the
    // band of probe blocks), gi_finish() inside probes_finish(). gi_collect() reads the RealtimeGI components (cheap when there are none).
    void gi_collect(World& world);
    // The records of the ready grids the meshes of this frame read (probes_build_volumes calls it): GiSystem::records, upload_lights packs them.
    void gi_build_records(World& world);
    void gi_plan(World& world, bool atlasRemade);
    void gi_finish();
    void gi_release();
    // The Frame of capture face `face` of `rp` seen from `position`: a 90 degree camera into an image of `resolution` squared.
    void probe_face_frame(Frame& fr, World& world, const ReflectionProbe& rp, Vec3 position, int face, int resolution);
    void
    probes_release();  // the atlas, the scratch cubes and the programs (shutdown, and when the world has no probe left)
    bool probe_sync_capture(World& world, Entity probe, Renderer::ProbePage& out, std::string* error);
    bool probe_read_atlas(int x, int y, int w, int h, std::vector<float>& out, std::string* error);
    // The drawing of Renderer::capture_world and capture_camera: `frames` frames (the passes that keep a history see
    // the frame before it) of the world seen by `ci` into an image of w x h pixels, read back into `out` (straight
    // alpha). `withCustom`: the camera's custom passes are drawn, over `historyCamera`'s history, which the frames
    // start again and which is freed at the end. `premultiplied`: the colour in the picture is premultiplied by its
    // alpha and is made straight (capture_world); false leaves it as drawn. `scale`, `subject`: see
    // Renderer::WorldCapture.
    bool capture_view(World& world, CameraInfo ci, int w, int h, float scale, Entity subject, int frames,
                      bool withCustom, std::uint64_t historyCamera, bool premultiplied, Image& out, std::string* error);
    std::uint64_t captureSerial =
        0;  // the frames of captures that keep a history: a history is valid when its frame came right before

    // ---- The frame graph: one per render() (and per capture_world) ----
    // begin_frame_graph() empties it, every job adds its passes (plan_job, plan_view_job) in the order the jobs must
    // run, run_frame_graph() compiles and executes them and drops what the pass callbacks captured. The images that jobs
    // draw into and others sample are imported resources (`jobImages`), so a job that shows one reads it.
    struct JobImage {
        ResourceId drawn, shown;  // `shown` is the flipped copy when the backend needs one, else the same as `drawn`
    };
    // `countPost` false for a frame that is not the game's picture (capture_world): it does not count as a frame for the auto exposure.
    void begin_frame_graph(bool countPost = true);
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
    std::vector<double>
        testGpuFrames;  // GPU frame times a test injected; poll_gpu_frames hands them out as the timer's
    void
    poll_gpu_frames();  // reads the timer's answers into gpuFrames and, while the dynamic resolution asks, gpuFrameMs
    bool passHooksSet = false;      // begin_frame_graph() gave the graph its pass hooks
    bool graphFromCapture = false;  // the graph holds the last capture_world's frame, not the last render()'s
    std::unordered_map<std::uint64_t, JobImage> jobImages;
    // The targets the jobs of the frame share, one resource each (imported when the first job that uses it is declared).
    ResourceId sharedGame, sharedLight, sharedShadow, sharedEnv, sharedSkyLut, sharedCookie;
    // The physical sky (SceneSettings.skyModel): its tables are drawn by the first job of a frame that shows the sky
    // ("sky-view" pass); the later jobs read them.
    std::uint64_t skyLutFrame = ~std::uint64_t(0);
    // The sky environment of the frame (plan_env): the first job that wants one decides which sky is baked
    // (envFrameKey) and whether the "sky-env" pass is declared; a later job of the frame with another key falls back to
    // the analytic gradient.
    std::uint64_t envFrame = 0;  // the frameSerial it was decided for
    std::uint64_t envFrameKey = 0;
    bool envFrameOk = false;
    // The first job decided the key above from a render target, CameraView or capture (JobPlan::view), not from a
    // camera of the picture: the first such camera of the picture takes the decision over (plan_env), and the jobs that
    // used the first key (envJobs) go back to the gradient.
    bool envFrameView = false;
    std::vector<DrawContext*> envJobs;               // the jobs of this frame that sample the baked environment
    std::vector<std::shared_ptr<void>> jobContexts;  // the DrawContext of every job, alive until run_frame_graph() ends
    // What a job's passes read from the renderer when they run: the swapped-in image of a view job (plan_view_job).
    struct JobEnv {
        int targetW = 0, targetH = 0, physW = 0, physH = 0;
        gpu::View colorAtt{}, resolveAtt{}, depthAtt{};
    };
    JobEnv job_env() const;
    void set_job_env(const JobEnv& env);

    // The phases of draw_job (renderer_draw.cpp), each reading and writing the DrawContext of the job; the comment of each
    // names its reads and writes.
    struct Px;
    struct PartDraw;
    struct MaterialInputs;
    void gather_meshes(DrawContext& ctx);
    void collect_lights(DrawContext& ctx);
    void shadow_bounds(DrawContext& ctx);
    void cull_and_batch(DrawContext& ctx);
    void plan_transmission(DrawContext& ctx);
    void build_quad_stream(DrawContext& ctx);
    void upload_instances(DrawContext& ctx);
    void scene_uniforms(DrawContext& ctx);
    void upload_lights(DrawContext& ctx);
    // fa_cl_info (what the shader reads of the clusters) of the last job's scene uniforms, for the render tests.
    float lastClusterInfo[4] = {-1.0f, 0.0f, 0.0f, 0.0f};
    // The sky environment of the job (SceneSettings.skyMaterial): sets ctx.envActive / envBake / envKey and the flag of
    // fuScene.
    void plan_env(DrawContext& ctx);
    PartDraw part_draw(DrawContext& ctx, const MeshItem& mi, const SubMesh& part);
    // Reports once per material and mesh that `part` lacks the channel `what` ("uv1" / "color1") the material declares.
    void note_missing_channel(const MeshItem& mi, const SubMesh& part, const char* what);
    // `blended`: a part of the blended meshes, which fog themselves with the camera's stack fog (DrawContext::fuBlend).
    mesh_fa_mesh_fs_params_t fill_fs(DrawContext& ctx, const MeshItem& mi, const SubMesh& part, const PartDraw& d,
                                     bool blended = false);
    void material_inputs(const MeshItem& mi, MaterialAsset* mat, MaterialInputs& in);
    void bind_textures(DrawContext& ctx, gpu::Bindings& b, const PartDraw& d, const MaterialProgram* prog,
                       const MaterialInputs& in, bool shadowPass, bool opaquePhase = false);
    void light_plan(DrawContext& ctx);
    // The 2D GI field of a 2D camera job (GlobalIllumination2D, gi2d.h): its slot, size and gather; nothing when the scene has none or the GPU cannot.
    void gi2d_plan(DrawContext& ctx);
    void light_pass(DrawContext& ctx);
    void shadow_pass(DrawContext& ctx);
    // The draws of the shadow views [viewFirst, viewEnd) into `cl` (inside the shadow pass). shadow_pass records them on the
    // frame's list, or, with Gpu::parallel_recording(), captures groups of views and replays each group into a list of its own
    // on the job threads (M77-P10d). The captures are kept across frames (their memory).
    void shadow_views(DrawContext& ctx, gpu::CommandList& cl, int viewFirst, int viewEnd);
    std::vector<std::unique_ptr<render::CommandCapture>> shadowCaptures;
    // The depth and normal prepass (M71): plan_prepass decides whether the job has one, prepass_pass draws it into `t` (a transient of
    // the graph), prepass_view_pass paints it over the game image (Renderer::set_debug_view).
    bool plan_prepass(DrawContext& ctx);
    // M76-P1d: the motion vectors and the reactive mask of the 2D quads of the world. plan_quad_motion decides after plan_prepass whether the
    // job draws the "quad-velocity" pass (over the prepass's velocity image, or an image of its own when the job has no prepass) and the
    // "quad-reactive" pass (an R8 image, PostPlan::reactive); quad_motion_pass draws one of them over the batches of ctx.gWorld.
    // `depth`: the prepass (the quads behind a mesh are left out), null when the job has none.
    void plan_quad_motion(DrawContext& ctx);
    void quad_motion_pass(DrawContext& ctx, const Target& t, bool reactive, const Target* depth, bool clear);
    // `backFaces`: draws the back faces only (the realtime GI's distance pictures).
    // `velocity`: the second attachment of the pass (VelocityRef's image), null for a pass that does not write the motion vectors.
    void prepass_pass(DrawContext& ctx, const Target& t, bool backFaces = false, const Target* velocity = nullptr);
    // M73.5: the meshes that scatter again with the sss program of the mesh shader, into `a` (diffuse light + depth) and `b` (radius + strength);
    // `pre` is the prepass the shader's visibility test reads.
    void sss_draw_pass(DrawContext& ctx, const Target& a, const Target& b, const Target& pre);
    // The outline's image (M71-C2): plan_outline settles it after plan_prepass (a depth outline needs the prepass, a sprite outline a
    // coverage image of the 2D world; without it the effect is dropped from the plan), coverage_pass draws the 2D world's alpha into `t`.
    void plan_outline(DrawContext& ctx);
    void coverage_pass(DrawContext& ctx, const Target& t);
    void prepass_view_pass(DrawContext& ctx, const Target& t);
    void draw_group(DrawContext& ctx, const std::vector<QuadBatch>& batches, const Mat4& vp, bool depthTest,
                    const Px& base, int flatMode = 0, const TargetFormat* format = nullptr,
                    const FogFxPlan* fog = nullptr, int passW = 0, int passH = 0);
    void main_pass(DrawContext& ctx, const PassContext& pc);
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
        if (!transients) transients = std::make_unique<TransientTargets>(gpu.device());
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

// Sets the uniform block `slot` of the pipeline set last on `list` to `u`.
template <class T>
void apply_uniforms(gpu::CommandList& list, int slot, const T& u) {
    list.set_uniforms(slot, gpu::Range{&u, sizeof(T)});
}

}  // namespace fa
