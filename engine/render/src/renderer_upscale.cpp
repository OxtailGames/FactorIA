// Renderer: the upscale stage (render_upscale.h) and the output-resolution images the screen-space items are drawn into after it.
#include "render_upscale.h"

#include "renderer_impl.h"

namespace fa::render {

UpscaleImpl select_upscale_impl(std::string_view mode, bool* known) {
    const bool understood = mode == "stretch";
    if (known) *known = understood;
    return UpscaleImpl::Stretch;
}

const char* upscale_impl_name(UpscaleImpl impl) {
    switch (impl) {
        case UpscaleImpl::Stretch: return "stretch";
    }
    return "stretch";
}

}  // namespace fa::render

namespace fa {

using render::UpscaleImpl;
using render::UpscaleInput;

bool Renderer::Impl::upscale_active() const {
    return upscaleStage && physW > 0 && physH > 0 && (physW < targetW || physH < targetH);
}

// Makes (or keeps) an image of the output size with `colorFormat`; `withDepth` adds the depth image the screen-space items need.
// False (and one logged error) when the GPU cannot make it: the frame is then shown at the render resolution.
bool Renderer::Impl::ensure_output_target(Target& t, const char* label, sg_pixel_format colorFormat, bool withDepth) {
    if (t.color.id && (t.w != targetW || t.h != targetH || t.format.color != colorFormat || (withDepth && !t.depth.id)))
        destroy_target(t);
    if (t.color.id) return true;
    TargetDesc d;
    d.label = label;
    d.width = targetW;
    d.height = targetH;
    d.colorFormat = colorFormat;
    d.depthFormat = withDepth ? kSceneDepthFormat : SG_PIXELFORMAT_NONE;
    t = make_target(d);
    if (!t.valid()) {
        FA_ERROR("render",
                 "Upscale stage: cannot create the {}x{} output image ({}); the game is shown at its render resolution "
                 "({}x{}) instead, with the HUD and the UI drawn into it. Hint: lower the window size or set the "
                 "render scale to 1",
                 targetW, targetH, label, physW, physH);
        destroy_target(t);
        return false;
    }
    return true;
}

void Renderer::Impl::free_output_targets() {
    destroy_target(outTarget);
    destroy_target(outFilterTarget);
    outActive = false;
    outFilterActive = false;
}

// The "stretch" implementation: a copy of the picture into the output image through a Linear sampler (Nearest for pixel art).
// Nothing is converted: the output image has the format of the input, so linear light stays linear and display values stay
// display values, and present() encodes it as it would have the render-resolution picture.
void Renderer::Impl::stretch_upscale(const UpscaleInput& in, Target& out) {
    PassDesc p = pass_into(out, "upscale-stretch");
    p.colorLoad = SG_LOADACTION_DONTCARE;  // every pixel is drawn
    p.colorStore = SG_STOREACTION_STORE;
    gpu.begin_pass(p);
    sg_apply_pipeline(gpu.blit_keep_pipeline(p.format));
    sg_bindings b{};
    b.vertex_buffers[0] = gpu.fullscreen_triangle();
    b.views[VIEW_blit_tex] = in.color;
    b.samplers[SMP_blit_smp] = gpu.sampler(in.pixelArt ? SamplerKind::Nearest : SamplerKind::Linear);
    sg_apply_bindings(&b);
    blit_blit_vs_params_t u{};  // flip stays 0: the output image is stored like the game image
    apply_uniforms(UB_blit_blit_vs_params, u);
    blit_blit_fs_params_t fu{};  // encode 0: copied as it is
    apply_uniforms(UB_blit_blit_fs_params, fu);
    sg_draw(0, 3, 1);
    gpu.end_pass();
    ++stats.drawCalls;
}

// The upscale pass: the picture of the render resolution (scene_target()) into `out`. The implementation is chosen by upscaleImpl.
void Renderer::Impl::run_upscale(Target& out) {
    const Target& src = scene_target();
    UpscaleInput in;
    in.color = src.texView;
    in.renderW = src.w;
    in.renderH = src.h;
    in.outW = out.w;
    in.outH = out.h;
    in.frameIndex = postSerial;
    in.pixelArt = scaleMode == ScaleMode::PixelPerfect;
    switch (upscaleImpl) {
        case UpscaleImpl::Stretch: stretch_upscale(in, out); break;
    }
    outActive = true;
}

}  // namespace fa
