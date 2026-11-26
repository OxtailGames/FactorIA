// The renderer's side of the ray tracing scene (M79 P1s): the setting, and the start of a frame that turns the scene on or off.
// The scene itself is rt_scene.h; docs/design/ARCHITECTURE_RT_SCENE.md.
#include "renderer_impl.h"

namespace fa {

void Renderer::set_ray_tracing(const render::RayTracingSettings& settings) {
    if (impl_) impl_->rtSettings = settings;
}

const render::RayTracingSettings& Renderer::ray_tracing() const {
    static const render::RayTracingSettings none;
    return impl_ ? impl_->rtSettings : none;
}

// Start of Renderer::begin_frame (before sokol's frame begins, next to hiz_submit): the scene follows the setting and the device, and the
// compaction answers of the frames before arrive. With ray tracing off every line below is a compare and a return.
void Renderer::Impl::rt_begin_frame() {
    const bool wanted = render::rt_any_effect(rtSettings) && gpu.has_device();
    bool on = false;
    if (wanted) {
        std::string why;
        if (gpu.device().ray_tracing_status(&why)) {
            on = true;
        } else if (!rtWarnedUnsupported) {
            rtWarnedUnsupported = true;
            FA_WARN("render",
                    "Ray tracing is on (render.rayTracing) but this device cannot trace rays ({}). Nothing is traced "
                    "and nothing is "
                    "built: the frame is the one it would be with ray tracing off. Hint: `factoria call "
                    "render.ray_tracing` and "
                    "`render.supports raytracing` say what this device lacks; set render.rayTracing.enabled to false "
                    "to silence this.",
                    why.empty() ? std::string("(the device gave no reason)") : why);
        }
    }
    if (!wanted) rtWarnedUnsupported = false;  // turned off: a later turn-on says it again
    // Mesh buffers carry the usage a build reads only while the scene is on (Assets::set_accel_input reloads the meshes made before).
    if (assets) assets->set_accel_input(on);
    if (!rtScene.configure(on ? &gpu.device() : nullptr, on, std::uint32_t(std::max(1, rtSettings.maxInstances))))
        return;
    rtScene.begin_frame(desc.headless, [this] {
        if (!gpu.committed()) {
            gpu.commit_frame();
            gpu.note_commit();
        }
    });
}

}  // namespace fa
