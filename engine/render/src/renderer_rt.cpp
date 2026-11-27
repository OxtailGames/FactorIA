// The renderer's side of the ray tracing scene (M79 P1s): the setting, and the start of a frame that turns the scene on or off.
// The scene itself is rt_scene.h; docs/design/ARCHITECTURE_RT_SCENE.md.
#include "gpu/sokol_shaders.h"
#include "renderer_impl.h"
#include "rt_skin.h"
#include "shader_cache.h"
#include "shaders/rt_skin.glsl.h"

namespace fa {

// rt_skin.h names the slots of the kernel; the generated header has the numbers the program really has.
static_assert(render::kRtSkinViewVertices == VIEW_rt_skin_rt_skin_vertices_buf);
static_assert(render::kRtSkinViewInfluences == VIEW_rt_skin_rt_skin_influences_buf);
static_assert(render::kRtSkinViewPalette == VIEW_rt_skin_rt_skin_palette_buf);
static_assert(render::kRtSkinViewOut == VIEW_rt_skin_rt_skin_out_buf);
static_assert(render::kRtSkinUniformParams == UB_rt_skin_rt_skin_params);
static_assert(sizeof(rt_skin_rt_skin_params_t) == 4 * sizeof(std::int32_t));

gpu::Pipeline Renderer::Impl::rt_skin_pipeline() {
    if (!gpu.has_device() || !gpu.device().features().compute || rtSkinShaderState < 0) return {};
    if (rtSkinShaderState == 0) {
        rtSkinShader = render::make_shader(
            gpu.device(), gpu::generated_shader_desc(gpu.device(), rt_skin_rt_skin_shader_desc), "rt_skin_rt_skin");
        rtSkinShaderState = rtSkinShader.id && gpu.device().state(rtSkinShader) == gpu::ResourceState::Valid ? 1 : -1;
        if (rtSkinShaderState < 0) {
            if (rtSkinShader.id) gpu.destroy_shader(rtSkinShader);
            rtSkinShader = {};
            return {};
        }
    }
    const gpu::Pipeline pip = gpu.compute_pipeline(rtSkinShader);
    if (gpu.device().state(pip) != gpu::ResourceState::Valid) {
        rtSkinShaderState = -1;
        return {};
    }
    return pip;
}

void Renderer::Impl::rt_release_skin_shader() {
    if (rtSkinShader.id && gpu.has_device()) gpu.destroy_shader(rtSkinShader);
    rtSkinShader = {};
    rtSkinShaderState = 0;
}

void Renderer::set_ray_tracing(const render::RayTracingSettings& settings) {
    if (!impl_) return;
    impl_->rtRequested = settings;
    // The graphics preset only caps what the project asked for (QualityLimits::rt*): never turns an effect on.
    impl_->rtSettings = impl_->qualityOn ? render::apply_quality_to_ray_tracing(settings, impl_->quality) : settings;
}

void Renderer::set_path_tracer(const render::PathTracerSettings& settings) {
    if (impl_) impl_->ptSettings = settings;
}

const render::PathTracerSettings& Renderer::path_tracer() const {
    static const render::PathTracerSettings none;
    return impl_ ? impl_->ptSettings : none;
}

render::PathTracerStatus Renderer::path_tracer_status() const {
    if (!impl_) return {};
    render::PathTracerStatus s = impl_->ptState.status;
    // Only the path tracer's own pass (a shadow kernel that failed is not its business); what the kernel or the image could not be made with
    // (add_pass refused) is in the status already.
    if (!impl_->ptSettings.enabled)
        s.failure.clear();
    else if (std::string f = impl_->rtEffects.failure_of("pathtrace"); !f.empty())
        s.failure = std::move(f);
    return s;
}

std::string Renderer::ray_tracing_failure() const { return impl_ ? impl_->rtEffects.failure() : std::string(); }

void Renderer::ray_tracing_local_shadows(int& candidates, int& traced) const {
    candidates = impl_ ? impl_->rtLocalCandidatesShown.load() : 0;
    traced = impl_ ? impl_->rtLocalTracedShown.load() : 0;
}

render::RtGiStatus Renderer::ray_tracing_gi_status() const {
    if (!impl_) return {};
    std::lock_guard<std::mutex> lock(impl_->rtGiStatusMutex);
    return impl_->rtGiStatus;
}

render::RtGiPixelStatus Renderer::ray_tracing_gi_pixel_status() const {
    if (!impl_) return {};
    std::lock_guard<std::mutex> lock(impl_->rtGiStatusMutex);
    return impl_->rtGiPixelStatus;
}

render::RtDenoiserStatus Renderer::ray_tracing_denoiser_status() const {
    if (!impl_) return {};
    std::lock_guard<std::mutex> lock(impl_->rtGiStatusMutex);
    return impl_->rtDenoiserStatus;
}

const render::RayTracingSettings& Renderer::ray_tracing() const {
    static const render::RayTracingSettings none;
    return impl_ ? impl_->rtSettings : none;
}

// Start of Renderer::begin_frame (before sokol's frame begins, next to hiz_submit): the scene follows the setting and the device, and the
// compaction answers of the frames before arrive. With ray tracing off every line below is a compare and a return.
void Renderer::Impl::rt_begin_frame() {
    rtShadowDraws = {};
    giPixelDraws = {};
    rtAccelPass.clear();
    rtGiHitValid = false;
    rtGiPixelFrame = {};
    rrSignalsFrame = {};
    rrSignalsDeclared = false;
    rrDrewFrame = false;
    rrWouldTake = false;
    rtReflectFrameImg = nullptr;
    upscaleReflectImg = nullptr;
    upscaleReflectRes = ResourceId{};
    rtLocalCandidatesShown = rtLocalFrame.candidates;
    rtLocalTracedShown = rtLocalFrame.traced;
    rtLocalFrame = {};
    // The path tracer asks for the scene as the effects do (it is its own setting, render.pathTracer): either on is enough.
    const bool wantsScene = render::rt_any_effect(rtSettings) || ptSettings.enabled;
    const bool wanted = wantsScene && gpu.has_device();
    bool on = false;
    if (wanted) {
        std::string why;
        if (gpu.device().ray_tracing_status(&why)) {
            on = true;
        } else if (!rtWarnedUnsupported) {
            rtWarnedUnsupported = true;
            FA_WARN("render",
                    "Ray tracing is on (render.rayTracing or render.pathTracer) but this device cannot trace rays "
                    "({}). Nothing is traced "
                    "and nothing is "
                    "built: the frame is the one it would be with ray tracing off. Hint: `factoria call "
                    "render.ray_tracing` and "
                    "`render.supports raytracing` say what this device lacks; set render.rayTracing.enabled to false "
                    "to silence this.",
                    why.empty() ? std::string("(the device gave no reason)") : why);
        }
    }
    if (!wanted) {
        rtWarnedUnsupported = false;  // turned off: a later turn-on says it again
        rtWarnedEffect = false;
        rtWarnedReflect = rtWarnedReflectGbuffer = false;
        rtWarnedAo = false;
        rtWarnedLocal = false;
        rtWarnedTranslucency = false;
    }
    if (!wanted || rtSettings.gi != render::RtGi::PerPixel) rtWarnedGiPixel = false;
    if (!wanted || !ptSettings.enabled) {
        rtWarnedPathTrace = false;
        ptState.clear();  // off (or nothing traces here): the accumulation starts over when it is turned on
    }
    rtScene.set_track_changes(ptSettings.enabled);
    ptState.purge(frameSerial + 1);  // the cameras that drew no path traced frame for two frames
    // The effects' own shaders and images exist only while ray tracing is on and traces here (rt_effect.h): free when off.
    if (!on) {
        rtLocalSlots.clear();
        if (gpu.has_device() && !rtEffects.empty()) rtEffects.release(gpu);
        if (gpu.has_device() && !rtGi.empty()) rtGi.release(gpu);
        if (gpu.has_device() && (rtDenoiser.shaders_made() || rtDenoiser.history_image_count() > 0))
            rtDenoiser.release();
    } else {
        rtEffects.sweep(gpu, frameSerial + 1);
        render::sweep_rt_local_slots(rtLocalSlots, frameSerial + 1);  // a camera that is gone keeps no slots
        if (rtSettings.gi != render::RtGi::Probes && gpu.has_device() && !rtGi.empty())
            rtGi.release(gpu);
        else
            rtGi.sweep(gpu,
                       frameSerial + 1);   // the band image and the kernel go when no frame used them for two frames
        rtDenoiser.sweep(postSerial + 1);  // a signal no camera asked for in the frame before frees its history
    }
    // Mesh buffers carry the usage a build reads only while the scene is on (Assets::set_accel_input reloads the meshes made before).
    if (assets) assets->set_accel_input(on);
    if (!rtScene.configure(on ? &gpu.device() : nullptr, on, std::uint32_t(std::max(1, rtSettings.maxInstances))))
        return;
    if (!rtScene.skinKernel) rtScene.skinKernel = [this] { return rt_skin_pipeline(); };
    rtScene.begin_frame(desc.headless, [this] {
        if (!gpu.committed()) {
            gpu.commit_frame();
            gpu.note_commit();
        }
    });
}

// After the frame graph ran (Renderer::render, next to probes_finish): did the per-pixel GI light the main camera's surfaces this frame? A pass that was
// declared and did not run is counted: a reason it declared (the driver refused the kernel) falls back to the probe and ambient term at once, a pass
// with none (the traced scene had no instance yet) gets kGiRtMissFrames frames; the term then holds for kGiRtRetryFrames frames before the next try.
void Renderer::Impl::rt_gi_pixel_finish() {
    render::RtGiPixelStatus st;
    st.wanted = rtSettings.enabled && rtSettings.gi == render::RtGi::PerPixel;
    if (!st.wanted) {  // turned off (and on again later): the next try starts clean
        rtGiPixelMisses = 0;
        rtGiPixelFallbackUntil = 0;
        rtGiPixelFallbackReason.clear();
    } else if (rtGiPixelFrame.declared) {
        if (rtGiPixelFrame.img && rtGiPixelFrame.img->ran) {
            rtGiPixelMisses = 0;
            st.active = rtGiPixelFrame.bound;
            if (!st.active)  // traced, but no pass could read the image: the surfaces keep the probe and ambient light
                st.reason = "the traced image was not bound to the lit meshes (the denoiser did not make its image and "
                            "this device cannot "
                            "filter a 32-bit float image): the surfaces use the probe and ambient light";
        } else {
            const std::string why = rtEffects.failure_of("gipixel");
            st.reason = why.empty() ? "the traced scene was not ready this frame (it has no instance yet)" : why;
            if (!why.empty() || ++rtGiPixelMisses >= kGiRtMissFrames) {
                rtGiPixelFallbackUntil = frameSerial + std::uint64_t(kGiRtRetryFrames);
                rtGiPixelFallbackReason = st.reason +
                                          " (the probe and ambient light is used; the rays are tried again in " +
                                          std::to_string(kGiRtRetryFrames) + " frames)";
                rtGiPixelMisses = 0;
            }
        }
    } else {
        st.reason = !rtGiPixelFrame.why.empty()            ? rtGiPixelFrame.why
                    : frameSerial < rtGiPixelFallbackUntil ? rtGiPixelFallbackReason
                                                           : std::string("no camera drew the scene this frame");
    }
    // Who denoised the signals of this frame (M79-P4b-2). A frame whose Ray Reconstruction decision was "take" and that DLSS then drew with Super
    // Resolution (the evaluation was refused) shows the noisy signals once: the status says the engine denoises (it will, from the next frame) and why.
    render::RtDenoiserStatus ds;
    // What the frame traced: the status tells "off" for a signal no camera traced (a camera with no prepass, a device that refused the kernel).
    ds.settled = true;
    ds.reflectionsTraced = rtReflectFrameImg && rtReflectFrameImg->ran;
    ds.giTraced = rtGiPixelFrame.declared && rtGiPixelFrame.img && rtGiPixelFrame.img->ran;
    if (rrSignalsDeclared) {
        const bool drew = rrDrewFrame;
        // Ray Reconstruction only "took" a signal the frame traced: a kernel that did not run (no prepass, a refused pipeline) has nothing to denoise.
        ds.reflectionsRr = rrSignalsFrame.reflections && drew && ds.reflectionsTraced;
        ds.giRr = rrSignalsFrame.gi && drew && ds.giTraced;
        if (!drew && (rrSignalsFrame.reflections || rrSignalsFrame.gi))
            ds.reason =
                "DLSS Ray Reconstruction did not draw the frame the signals were left to it for (" +
                (rrFailed ? (rrFailedWhy.empty() ? std::string("no reason given") : rrFailedWhy)
                          : std::string("the frame was drawn without it, which the decision did not expect")) +
                "): they were drawn noisy once and the engine's denoiser takes them from the next frame" +
                (rrFailed ? std::string(", for the rest of this run (Ray Reconstruction stays off until the game is "
                                        "started again)")
                          : "; they go back to Ray Reconstruction after " + std::to_string(render::kRrRecoverFrames) +
                                " frames in a row in which it draws again") +
                ".";
        else
            ds.reason = rrSignalsFrame.why;
        // The hit distance guide is optional: a program that did not compile only leaves it out (the reflections are still denoised by Ray Reconstruction).
        if (ds.reflectionsRr && rrPrep.hit_failed())
            ds.reason +=
                std::string(ds.reason.empty() ? "" : "; ") +
                "the reflections' hit distance guide is left out (its shader did not compile on this device), so "
                "Ray Reconstruction denoises the reflections without it";
    }
    // A frame whose signals were left to Ray Reconstruction and that it did not draw (the decision looked at what it could, the frame had another
    // answer) is not tried again at once: the engine's denoiser keeps the signals, from a reset history, until the decision and DLSS have agreed
    // for kRrRecoverFrames frames in a row (rr_recovery_step). A frame DLSS refused for good (rrFailed) never recovers: rr_refusal keeps refusing.
    if (rrSignalsDeclared && (rrSignalsFrame.reflections || rrSignalsFrame.gi) && !rrDrewFrame) {
        rrSignalsLost = true;
        rrAgreeFrames = 0;
    } else if (rrSignalsLost && render::rr_recovery_step(rrAgreeFrames, rrWouldTake, rrDrewFrame)) {
        rrSignalsLost = false;
    }
    std::lock_guard<std::mutex> lock(rtGiStatusMutex);
    rtGiPixelStatus = std::move(st);
    rtDenoiserStatus = std::move(ds);
}

}  // namespace fa
