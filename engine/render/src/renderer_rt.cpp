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
    if (impl_) impl_->rtSettings = settings;
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
    s.failure = impl_->ptSettings.enabled ? impl_->rtEffects.failure() : std::string();
    return s;
}

std::string Renderer::ray_tracing_failure() const { return impl_ ? impl_->rtEffects.failure() : std::string(); }

const render::RayTracingSettings& Renderer::ray_tracing() const {
    static const render::RayTracingSettings none;
    return impl_ ? impl_->rtSettings : none;
}

// Start of Renderer::begin_frame (before sokol's frame begins, next to hiz_submit): the scene follows the setting and the device, and the
// compaction answers of the frames before arrive. With ray tracing off every line below is a compare and a return.
void Renderer::Impl::rt_begin_frame() {
    rtShadowDraws = {};
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
                    "Ray tracing is on (render.rayTracing or render.pathTracer) but this device cannot trace rays ({}). Nothing is traced "
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
        rtWarnedTranslucency = false;
    }
    if (!wanted || !ptSettings.enabled) {
        rtWarnedPathTrace = false;
        ptState.clear();  // off (or nothing traces here): the accumulation starts over when it is turned on
    }
    rtScene.set_track_changes(ptSettings.enabled);
    // The effects' own shaders and images exist only while ray tracing is on and traces here (rt_effect.h): free when off.
    if (!on) {
        if (gpu.has_device() && !rtEffects.empty()) rtEffects.release(gpu);
        if (gpu.has_device() && (rtDenoiser.shaders_made() || rtDenoiser.history_image_count() > 0))
            rtDenoiser.release();
    } else {
        rtEffects.sweep(gpu, frameSerial + 1);
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

}  // namespace fa
