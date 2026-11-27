// Test accessors of the renderer (never a public header: engine code and games do not call them). A test that has to
// look inside the renderer (its GPU objects, the frame graph of the last frame, the counts of its pools, the history
// images of the custom post passes) includes this header and calls the free functions below; they go through
// RendererTestAccess, the one friend of Renderer, so Impl stays closed. RendererTestAccess is defined in renderer.cpp.
#pragma once

#include <cstdint>
#include <functional>
#include <string>
#include <vector>

#include "fa/platform/hdr_output.h"
#include "fa/render/probe.h"
#include "fa/render/renderer.h"
#include "gpu/types.h"

namespace fa {
namespace render {

class Gpu;
class FrameGraph;
class RtScene;
class RtEffects;
class RtGiProbes;
class RtDenoiser;

// The targets the frame graph's transients are made of (target_pool.h's TargetPoolStats).
struct TransientPoolStats {
    int live = 0, inUse = 0, created = 0, reused = 0, destroyed = 0;
};
// The ring of images that hold the shadow rows of the 2D lights: how many it holds now and how many images were made
// since the renderer was, and how many sprite contours of ShadowCaster2D were extracted from alpha (shadow2d.h).
struct ShadowRowsStats {
    int slots = 0, uploads = 0, contours = 0;
};

// How many times the physical sky drew its tables (renderer_sky_phys.h): the air's, the picture's view and the environment's.
struct SkyBuilds {
    int air = 0, view = 0, envView = 0;
};

// One slot of the 2D GI field (gi2d.h) as the last frame left it.
struct Gi2dFieldInfo {
    bool exists = false, ready = false;
    int width = 0, height = 0, passes = 0, emitters = 0, occluders = 0;
    double texel = 0.0, originX = 0.0, originY = 0.0;
    // The cascades (M74-P3b): their count, cascade 0's probe spacing, the irradiance image's size, whether it holds a finished frame (the
    // next frame's history) and whether the last frame ran the priming chain (the bounce had no history).
    int cascades = 0, probeSpacing = 0, irradianceWidth = 0, irradianceHeight = 0;
    bool irradianceReady = false, history = false, primed = false;
};

// The images of the upscale stage that live at the output size (M76 POL-UPSCALE): outTarget (the picture the screen-space items are drawn
// over), its depth image, outFilterTarget (the colour filter after the items) and the spatial upscaler's target.
struct OutputTargetsInfo {
    bool out = false, outDepth = false, filter = false, spatial = false;
    int outW = 0, outH = 0, outSamples = 0;
};

}  // namespace render

struct RendererTestAccess {
    static render::Gpu* gpu(Renderer& r);
    static const render::FrameGraph* frame_graph(Renderer& r);
    static render::TransientPoolStats transient_stats(Renderer& r);
    static render::ShadowRowsStats shadow_rows_stats(Renderer& r);
    static int post_history_images(Renderer& r);
    // M75.4b: the rebases the renderer followed, whether it is registered as an origin observer of `world`, and the rebases its 2D GI
    // fields followed.
    static std::uint64_t origin_shifts(Renderer& r);
    static bool origin_watched(Renderer& r, const World* world);
    static std::uint64_t gi2d_shifts(Renderer& r);
    // M75.2b: the depth reduce passes run so far, and the cameras that keep a depth pyramid.
    static int hiz_reduces(Renderer& r);
    // M79 P1s: the ray tracing scene (rt_scene.h); null before init.
    static render::RtScene* rt_scene(Renderer& r);
    // M79-P2a-1: the shaders and images of the ray traced effects (rt_effect.h); null before init.
    static render::RtEffects* rt_effects(Renderer& r);
    // M79-P4a: the GI probes updated by rays (rt_gi.h); null before init.
    static render::RtGiProbes* rt_gi(Renderer& r);
    // M79 POLISH-RA: the "the kernel reads the atlas" flag (RtGiParams::grid3[2]) of each dispatch the last frame planned for the probes.
    static std::vector<float>
    gi_rt_bounce_flags(Renderer& r);  // empty until gi_log_rt_bounce(r, true) was called before the frame
    static void gi_log_rt_bounce(Renderer& r, bool on);
    // M79 POLISH-RA: the cameras the path tracer keeps an accumulation state for (PathTraceState::jobs).
    static std::size_t path_trace_jobs(Renderer& r);
    // M79 POLISH-last-A: sets the refusal the next frame's plan reads for one camera's path tracer pass (PathTraceJobState::failure; the frame's own
    // declaration of a pass that is accepted clears it again). False when the camera has no accumulation state.
    static bool path_trace_set_failure(Renderer& r, const std::string& job, const std::string& why);
    // M79-P2a-2: the draws of the last frame that read the sun's shadow from the ray traced image, and those that took min(image, cascades).
    struct RtShadowDraws {
        int mask = 0, withCascades = 0, local = 0;
    };
    static RtShadowDraws rt_shadow_draws(Renderer& r);
    // M79-P4b-1: the opaque draws of the last frame that read the per-pixel GI image (`on`) and those drawn with it bound that kept the probes (`off`).
    struct GiPixelDraws {
        int on = 0, off = 0;
    };
    static GiPixelDraws rt_gi_pixel_draws(Renderer& r);
    static render::RtDenoiser* rt_denoiser(Renderer& r);  // the soft sun shadow's denoiser; null before init
    static std::string rt_effect_failure(Renderer& r);    // RtEffects::failure()
    static int hiz_cameras(Renderer& r);
    // The view-projection the renderer keeps of `camera`'s last frame (what motion blur reprojects from); false when it keeps none.
    static bool prev_view_proj(Renderer& r, Entity camera, Mat4& out);
    // M76: the jittered view-projection and the jitter in render pixels the renderer keeps of `camera`'s last frame (what the temporal
    // passes resolve their history with); false when it keeps none.
    static bool prev_jittered(Renderer& r, Entity camera, Mat4& jittered, Vec2& jitterPx);
    // M76: jitter every camera with `phases` (0 = back to the rule: only a stack with TemporalAA on that the renderer draws), so a test
    // or the pass that turns TemporalAA on can run the jitter before the effect is drawn.
    static void force_jitter(Renderer& r, int phases);
    // M76: every camera asks for the velocity image (as the effects that read it will), and the frame keeps a copy of the last camera's.
    // read_velocity gives that copy after a frame: `out` = w * h * 4 floats (RGBA, top row first), rg = uvPrev - uvCurr or 1024. False + `error`
    // when no frame drew one (the GPU makes no RG16F image, or no opaque mesh was drawn).
    static void force_velocity(Renderer& r, bool on);
    // Whether the last job the renderer planned (a frame's camera or a capture) asked for the velocity image (PostPlan::needsVelocity).
    static bool last_job_needs_velocity(Renderer& r);
    // M78: whether the images of the DLSS Ray Reconstruction guides (the normal and roughness, the albedos, the depth) exist now.
    static bool rr_guide_images(Renderer& r);
    // M79-P4b-2: whether the hit distance guide of the ray traced reflections (the R32F image made while they go to Ray Reconstruction) exists now, and the
    // DenoiseSignal ids the engine's denoiser gives the per-pixel GI and the reflections (RtDenoiser::last_reset asks by camera and signal).
    static bool rr_hit_image(Renderer& r);
    static std::uint32_t rt_gi_pixel_signal_id();
    static std::uint32_t rt_reflect_signal_id();
    // M79-P0c: makes the programs of the Ray Reconstruction guides (the normal and depth pass and the albedo pass that reads the thin G-buffer) on this
    // GPU and says whether both pipelines are valid, with the formats the renderer draws them with. No NVIDIA GPU or DLSS needed.
    static bool rr_guide_programs(Renderer& r);
    // M79-P0c, the thin G-buffer: every camera asks for it (as DLSS Ray Reconstruction and the debug views albedo and material do), and the frame keeps
    // a copy of the last camera's two images. read_gbuffer(0 = albedo, 1 = material) gives that copy after a frame: `out` = w * h * 4 floats
    // (RGBA, top row first, the RGBA8 values as 0..1). False + `error` when no frame drew one (the GPU makes no such image, or no opaque mesh).
    static void force_gbuffer(Renderer& r, bool on);
    static bool read_gbuffer(Renderer& r, int which, std::vector<float>& out, int& w, int& h, std::string* error);
    // With several cameras in a frame the probe holds the last one's images; this names the only camera whose images it copies (a null entity: every camera again).
    static void probe_camera(Renderer& r, Entity camera);
    // M76-P1c: behave as a GPU that cannot render to RG16F (Gpu::velocity_ready() false): no velocity image, no previous-model work, one warning.
    static void force_no_velocity_target(Renderer& r, bool on);
    // M76-P1d: behave as a GPU that cannot sample RGBA32F in the vertex stage (the previous joint palettes cannot be read: skinned draws write the
    // sentinel, one warning), and as one whose palette image holds only `rows` rows of 1024 texels (a skinned draw takes 192 texels).
    static void force_no_palette_sampling(Renderer& r, bool on);
    static void set_palette_row_cap(Renderer& r, int rows);
    static bool read_velocity(Renderer& r, std::vector<float>& out, int& w, int& h, std::string* error);
    // M76-P1d: the same for the reactive mask of the last camera (the first channel of each texel holds the mask, 0..1).
    static bool read_reactive(Renderer& r, std::vector<float>& out, int& w, int& h, std::string* error);
    // M76: what the cameras of the last frame were jittered by, in render pixels (CameraInfo::jitterPx), in draw order.
    static std::vector<Vec2> last_jitter(Renderer& r);
    // M76-P4b: the texture LOD bias of the cameras of the last frame (CameraInfo::mipBias), in draw order.
    static std::vector<float> last_mip_bias(Renderer& r);
    static int ldr_cut_format(Renderer& r);
    // M76-P2: the temporal antialiasing (renderer_taa.h): the history images alive, whether `camera`'s last resolve blended with its history,
    // how often a history was started, the format of the histories (sg_pixel_format as an int), whether the renderer gave the effect up, and
    // 8-bit histories as a GPU without half-float targets has.
    static int taa_images(Renderer& r);
    static bool taa_used_history(Renderer& r, Entity camera);
    static int taa_resets(Renderer& r);
    static int taa_format(Renderer& r);
    static bool taa_unavailable(Renderer& r);
    static bool
    taa_upscale_unavailable(Renderer& r);  // the upscaler's history was refused (the cameras' flag is taa_unavailable)
    static void taa_set_budget(Renderer& r,
                               std::uint64_t bytes);  // the bytes the TAA histories may take together (0: the default)
    static void taa_force_rgba8(Renderer& r, bool force);
    // M76 POL-LAST-B: the frames in a row without the stage after which its images are freed.
    static int output_idle_frames();
    // M76 POL-UPSCALE: which of the output-size images the renderer holds now (valid, with their depth).
    static render::OutputTargetsInfo output_targets(Renderer& r);
    // M76-P4: the temporal upscaler: the jitter phases the last frame asked of its camera (0: the frame was not jittered for it), the
    // implementation the last frame's upscale stage used (render::UpscaleImpl as an int), and whether its last resolve blended with the history.
    static int upscale_phases(Renderer& r);
    static int upscale_impl(Renderer& r);
    static bool upscale_used_history(Renderer& r);
    // M78-P1: the vendor upscalers: vendor_failed: provider `index` (0 dlss, 1 xess, 2 fsr) refused a frame and is off for the run.
    static bool vendor_failed(Renderer& r, int index);
    // M78-P5a: frame generation. output_passes: the passes of the output stage the last frame ran, in order (upscale, framegen-hudless,
    // hud-over-upscale, framegen); hudless_target_alive: the picture-before-the-items copy exists.
    static std::vector<std::string> output_passes(Renderer& r);
    static bool hudless_target_alive(Renderer& r);
    // The images the provider is handed with the colour filter on: the filtered picture the swapchain shows (the output of "output-color-filter") and
    // the copy before the items; read_hudless reads the copy back as RGBA8 display values (false when there is none).
    static gpu::Image filtered_output_image(Renderer& r);
    static gpu::Image hudless_image(Renderer& r);
    static bool read_hudless(Renderer& r, std::vector<std::uint8_t>& rgba, int& w, int& h);
    // A headless test renderer has no window swapchain for a provider's hook: this tells the controller the device was made with the hooks (what a
    // windowed renderer with RendererDesc::frameGeneration is told), so a fake provider can start. Call it before set_frame_generation.
    static void framegen_assume_hooked(Renderer& r);
    // M76-P5b: MetalFX. mfx_failed: the renderer gave it up (creation or a frame failed); mfx_encoded: frames the scaler encoded since it was
    // made; mfx_generation: scalers made; mfx_reset: the last MetalFX temporal frame reset the scaler's history. Hooks: the next scaler
    // creation fails, and the sign of the jitter and of the motion handed to MetalFX (-1 flips it, to show the sign matters).
    static bool mfx_failed(Renderer& r);
    static int mfx_encoded(Renderer& r);
    static int mfx_generation(Renderer& r);
    static bool mfx_reset(Renderer& r);
    static void mfx_force_create_failure(Renderer& r, bool fail);
    static void mfx_signs(Renderer& r, float jitterSign, float motionSign);
    // M76-P5c: mfx_force_support: what the renderer believes the GPU's MetalFX can do (spatial, temporal), whatever it really can, so the
    // fallback runs on a Metal GPU that has no MetalFX; mfx_prep_only: a MetalFX frame draws its preparation pass and then the temporal
    // upscaler, without asking MetalFX anything; mfx_images: how many of the preparation images (depth, motion) are alive; mfx_last_wrote:
    // the last frame's MetalFX temporal scaler drew; mfx_read_prep: the preparation pass at pixel (x, y) of the render picture, read back
    // as out = {depth, motion x, motion y} (false + error when the images are not there).
    static void mfx_force_support(Renderer& r, bool spatial, bool temporal);
    static void mfx_prep_only(Renderer& r, bool only);
    // M76 POL-METALFX: the reactive mask of MetalFX. mfx_reactive_enabled: the scaler was made with the mask input (false before the
    // first MetalFX frame, and on an OS older than macOS 14.4 / iOS 17.4); mfx_reactive_frames: the frames that handed it a mask;
    // mfx_no_reactive: hand none (the contrast of a test). mfx_scaler_hooks: the scaler's test hooks (metalfx.h, Scaler::TestHooks: the
    // frames are encoded without any MetalFX work, and/or their command buffers end as failed ones); mfx_wait_signalled: the GPU raised the
    // event of the last MetalFX frame within `timeoutMs` (false: a buffer that never released the passes after it).
    static bool mfx_reactive_enabled(Renderer& r);
    static int mfx_reactive_frames(Renderer& r);
    static void mfx_no_reactive(Renderer& r, bool none);
    static void mfx_scaler_hooks(Renderer& r, bool emptyBuffers, bool failBuffers);
    static bool mfx_wait_signalled(Renderer& r, int timeoutMs);
    static int mfx_images(Renderer& r);
    static bool mfx_last_wrote(Renderer& r);
    static bool mfx_read_prep(Renderer& r, int x, int y, float out[3], std::string* error);
    static void set_post_history_budget(Renderer& r, std::uint64_t bytes);
    static void refuse_post_history(Renderer& r, bool refuse);
    static int post_history_attempts(Renderer& r);
    static void force_post_effects(Renderer& r, std::uint32_t effects);
    static void force_output(Renderer& r, const HdrOutputInfo* info);
    static void last_cluster_info(Renderer& r, float out[4]);
    static bool read_floats(Renderer& r, bool present, std::vector<float>& out, std::string* error);
    static void set_before_frame_graph(Renderer& r, std::function<void()> hook);
    static void inject_gpu_frame_ms(Renderer& r, double ms);
    static render::SkyBuilds sky_builds(Renderer& r);
    static std::uint64_t decal_atlas_bytes(Renderer& r);
    static bool read_probe_atlas(Renderer& r, int x, int y, int w, int h, std::vector<float>& out, std::string* error);
    static bool probe_tile(Renderer& r, std::uint64_t id, render::ProbeTile& out);
    static void probe_force_rgba8(bool force);
    static bool probe_tile_valid(Renderer& r, std::uint64_t id);
    static int probe_volume_count(Renderer& r);
    // The 2D GI field (gi2d.h): image `which` (0 emission, 1 occluders, 2 distance, 3 irradiance) of slot `slot` as floats, RGBA, row 0 = the smallest world y;
    // what the slot holds; how many slots keep images.
    static bool gi2d_read(Renderer& r, int slot, int which, std::vector<float>& out, std::string* error);
    static render::Gi2dFieldInfo gi2d_info(Renderer& r, int slot);
    static int gi2d_slots_in_use(Renderer& r);
};

namespace render {

// The renderer's GPU objects (engine/render/src/render_internal.h); null before init.
inline Gpu* renderer_gpu(Renderer& r) { return RendererTestAccess::gpu(r); }
// The frame graph of the last frame the renderer drew (frame_graph.h; every job of the frame is in it, its passes named
// "<job>/<pass>"); null before init.
inline const FrameGraph* renderer_frame_graph(Renderer& r) { return RendererTestAccess::frame_graph(r); }
inline TransientPoolStats renderer_transient_stats(Renderer& r) { return RendererTestAccess::transient_stats(r); }
inline ShadowRowsStats renderer_shadow_rows_stats(Renderer& r) { return RendererTestAccess::shadow_rows_stats(r); }
inline SkyBuilds renderer_sky_builds(Renderer& r) { return RendererTestAccess::sky_builds(r); }
// The bytes of the decal atlas alone (texture_bytes() adds them to the textures and the ramps).
inline std::uint64_t renderer_decal_atlas_bytes(Renderer& r) { return RendererTestAccess::decal_atlas_bytes(r); }
// The images the post passes that read their own output of the frame before (fa_history) hold now.
inline int renderer_post_history_images(Renderer& r) { return RendererTestAccess::post_history_images(r); }
// The pixel format (sg_pixel_format as an int) of the images the final pass goes through when display-referred custom
// passes cut it, or 0 while none exists.
inline int renderer_ldr_cut_format(Renderer& r) { return RendererTestAccess::ldr_cut_format(r); }
// Tests of the history images (renderer_custom_post.h): the budget in bytes (0 = the default); the GPU refusing them (a
// slot it refused is not asked again every frame); and how many slots were asked of the GPU since the renderer was
// made.
inline void renderer_set_post_history_budget(Renderer& r, std::uint64_t bytes) {
    RendererTestAccess::set_post_history_budget(r, bytes);
}
inline void renderer_refuse_post_history(Renderer& r, bool refuse) {
    RendererTestAccess::refuse_post_history(r, refuse);
}
inline int renderer_post_history_attempts(Renderer& r) { return RendererTestAccess::post_history_attempts(r); }
// Draws the depth and normal prepass as if the camera's stack switched on the effects of `effects` (a mask like
// PostStack::mask, bit i = PostEffect(i); 0 = as the stack says).
inline void renderer_force_post_effects(Renderer& r, std::uint32_t effects) {
    RendererTestAccess::force_post_effects(r, effects);
}
// The HDR output: the next frames are drawn and presented as if update_output() had answered `info` (null: back to what
// it answers), for the render tests of the encodes without an HDR display.
// fa_cl_info of the last job the renderer drew: x is the first texel of the cluster table or -1 when the view has no
// clusters, y the depth slices, z the directional lights, w the clusters.
inline void renderer_last_cluster_info(Renderer& r, float out[4]) { RendererTestAccess::last_cluster_info(r, out); }
inline void renderer_force_output(Renderer& r, const HdrOutputInfo* info) { RendererTestAccess::force_output(r, info); }
// The last frame's finished picture as floats (RGBA, top row first): as the final target holds it (`present` false), or
// through present()'s encode for the output (scRGB, PQ, EDR or sRGB values). False with `error` where the GPU cannot
// draw or read back an RGBA16F image.
inline bool renderer_gi2d_read(Renderer& r, int slot, int which, std::vector<float>& out, std::string* error) {
    return RendererTestAccess::gi2d_read(r, slot, which, out, error);
}
inline Gi2dFieldInfo renderer_gi2d_info(Renderer& r, int slot) { return RendererTestAccess::gi2d_info(r, slot); }
inline int renderer_gi2d_slots_in_use(Renderer& r) { return RendererTestAccess::gi2d_slots_in_use(r); }
inline bool renderer_read_floats(Renderer& r, bool present, std::vector<float>& out, std::string* error) {
    return RendererTestAccess::read_floats(r, present, out, error);
}
// `hook` runs once per frame after everything is gathered and before the passes run (empty = none): the place to
// destroy a resource the gathered frame refers to. Clear it before the Renderer is used by another test.
inline void renderer_set_before_frame_graph(Renderer& r, std::function<void()> hook) {
    RendererTestAccess::set_before_frame_graph(r, std::move(hook));
}

// A GPU frame time the next poll of the timer answers as if the timer had resolved it (the profiler's
// take_gpu_ms() and the dynamic resolution's take_gpu_frame_ms() each get it once).
inline void renderer_inject_gpu_frame_ms(Renderer& r, double ms) { RendererTestAccess::inject_gpu_frame_ms(r, ms); }

// The probe atlas (renderer_probes.h): a rectangle of its texels as RGBA floats, top row first (RGBA8 atlas: bytes / 255); the tile of a probe
// (`id`: the entity's bits; render::kProbeSkyId for the sky's entry); and the next probe GPU objects as an RGBA8 GPU would make them (call before
// the first probe is drawn, undo with false).
inline bool renderer_read_probe_atlas(Renderer& r, int x, int y, int w, int h, std::vector<float>& out,
                                      std::string* error) {
    return RendererTestAccess::read_probe_atlas(r, x, y, w, h, out, error);
}
inline bool renderer_probe_tile(Renderer& r, std::uint64_t id, ProbeTile& out) {
    return RendererTestAccess::probe_tile(r, id, out);
}
inline void renderer_probe_force_rgba8(bool force) { RendererTestAccess::probe_force_rgba8(force); }
// Whether the tile of probe `id` holds its picture (false while it is empty: moved, evicted, the atlas made again), and how many probe boxes
// the last frame built for the meshes.
inline bool renderer_probe_tile_valid(Renderer& r, std::uint64_t id) {
    return RendererTestAccess::probe_tile_valid(r, id);
}
inline int renderer_probe_volume_count(Renderer& r) { return RendererTestAccess::probe_volume_count(r); }

}  // namespace render
}  // namespace fa
