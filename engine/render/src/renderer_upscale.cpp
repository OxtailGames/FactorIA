// Renderer: the upscale stage (render_upscale.h) and the output-resolution images the screen-space items are drawn into after it.
#include "render_upscale.h"

#include <algorithm>
#include <cmath>

#include "fa/scene/jitter.h"

#include "renderer_impl.h"

#include "fullscreen_gpu.h"

#include "render_features.h"
#include "shaders/upscale_spatial.glsl.h"

namespace fa::render {

UpscaleImpl select_upscale_impl(std::string_view mode, bool* known) {
    const bool understood = mode == "stretch" || mode == "spatial" || mode == "temporal" || mode == "metalfx";
    if (known) *known = understood;
    if (mode == "temporal") return UpscaleImpl::Temporal;
    if (mode == "metalfx") return UpscaleImpl::MetalFx;
    return mode == "spatial" ? UpscaleImpl::Spatial : UpscaleImpl::Stretch;
}

int upscale_jitter_phases(int renderW, int renderH, int outW, int outH) {
    const double rw = std::max(renderW, 1), rh = std::max(renderH, 1);
    const double ow = std::max(outW, 1), oh = std::max(outH, 1);
    const double phases = std::ceil(double(kJitterPhasesDefault) * (ow * oh) / (rw * rh) - 1e-6);
    return int(std::clamp(phases, 1.0, double(kJitterPhasesMax)));
}

const char* upscale_impl_name(UpscaleImpl impl) {
    switch (impl) {
        case UpscaleImpl::Stretch: return "stretch";
        case UpscaleImpl::Temporal: return "temporal";
        case UpscaleImpl::MetalFx: return "metalfx";
        case UpscaleImpl::Spatial: return "spatial";
    }
    return "stretch";
}

}  // namespace fa::render

namespace fa {

using render::UpscaleImpl;
using render::UpscaleInput;

// What this backend and the game's display allow: the spatial upscaler runs on every GPU backend (the row of render.supports), pixel
// art (ScaleMode::PixelPerfect) keeps its hard edges. The temporal upscaler (M76-P4) is the TAA resolve: it needs the TAA shaders (compiled
// here the first time a temporal, metalfx or auto setting asks, as the cameras do) and histories that fit, and it works on a frame of one
// full-viewport camera (`multiCamera`, what the last frame had). MetalFX (M76-P5b) is the Metal backend on an OS and a GPU that have its
// scalers (metalfx.h, asked once), until one of its frames fails here.
render::UpscalerCaps Renderer::Impl::upscaler_caps() {
    if (spatialSupported < 0) {
        const int row = render::find_feature("spatialUpscaler");
        spatialSupported = row >= 0 && gpu.has_device() &&
                                   render::feature_supported(render::feature_env_from_device(gpu.device()), row)
                               ? 1
                               : 0;
    }
    render::UpscalerCaps caps;
    caps.pixelArt = scaleMode == ScaleMode::PixelPerfect;
    caps.spatial = spatialSupported > 0;
    if (gpu.has_device() &&
        (upscaler.mode == render::UpscalerMode::Temporal || upscaler.mode == render::UpscalerMode::Auto ||
         upscaler.mode == render::UpscalerMode::MetalFx))
        caps.temporal = taa.ready() && !taa.upscale_unavailable();
    caps.multiCamera = temporalBlocked;
    if (gpu.has_device() && render::metalfx::on_metal(gpu.device()) && !mfxFailed) {
        const render::metalfx::Support& ms = metalfx_support();
        caps.metalfx = ms.spatial || ms.temporal;
        caps.metalfxTemporal = ms.temporal;
    } else {
        caps.metalfx = false;
        caps.metalfxTemporal = false;  // no MetalFX at all, so no temporal one either (the default says true)
    }
    // An explicit "metalfx" the GPU cannot run says why, once (the effective mode then is the next best, as render.upscaler reports).
    if (upscaler.mode == render::UpscalerMode::MetalFx && !caps.metalfx && !mfxWarnedUnavailable && !mfxFailed &&
        gpu.has_device()) {
        mfxWarnedUnavailable = true;
        FA_WARN("render",
                "render.upscaler mode \"metalfx\" is not available: {} The temporal upscaler is used instead, then the "
                "spatial one.",
                metalfx_support().reason.empty() ? std::string("MetalFX is not available on this GPU.")
                                                 : metalfx_support().reason);
    }
    return caps;
}

render::UpscalerMode Renderer::Impl::effective_upscaler_mode() {
    return render::effective_upscaler_mode(upscaler, upscaler_caps());
}

// The stage runs when the game is drawn below the output size, and at the output size too when the spatial mode has a sharpen to do
// (sharpness above 0): then it is that one pass and nothing else. Spatial with sharpness 0 at scale 1, and stretch, draw nothing.
bool Renderer::Impl::upscale_active() {
    if (!upscaleStage || physW <= 0 || physH <= 0) return false;
    if (physW < targetW || physH < targetH) return true;
    return physW == targetW && physH == targetH && upscaler.sharpness > 0.0f &&
           effective_upscaler_mode() == render::UpscalerMode::Spatial;
}

// Makes (or keeps) an image of the output size with `colorFormat`; `withDepth` adds the depth image the screen-space items need.
// False (and one logged error) when the GPU cannot make it: the frame is then shown at the render resolution.
bool Renderer::Impl::ensure_output_target(Target& t, const char* label, gpu::PixelFormat colorFormat, bool withDepth) {
    // MetalFX writes the output image (outTarget only): it needs storage usage next to the attachment (a frame that wants it, once made, keeps it).
    const bool isOut = &t == &outTarget;
    const bool wantStorage = isOut && outStorage;
    if (t.color.id && (t.w != targetW || t.h != targetH || t.format.color != colorFormat ||
                       (withDepth && !t.depth.id) || (wantStorage && !outHasStorage)))
        destroy_target(gpu.device(), t);
    if (t.color.id) return true;
    TargetDesc d;
    d.label = label;
    d.width = targetW;
    d.height = targetH;
    d.colorFormat = colorFormat;
    d.depthFormat = withDepth ? kSceneDepthFormat : gpu::PixelFormat::None;
    d.storage = wantStorage;
    t = make_target(gpu.device(), d);
    if (isOut) outHasStorage = wantStorage;
    if (!t.valid(gpu.device())) {
        FA_ERROR("render",
                 "Upscale stage: cannot create the {}x{} output image ({}); the game is shown at its render resolution "
                 "({}x{}) instead, with the HUD and the UI drawn into it. Hint: lower the window size or set the "
                 "render scale to 1",
                 targetW, targetH, label, physW, physH);
        destroy_target(gpu.device(), t);
        return false;
    }
    return true;
}

// The depth image is made only for a frame that has items to draw (`depth`), and kept after it: a frame without them neither asks for it
// nor drops it (ensure_output_target keeps a target that has one), so a HUD that comes and goes does not churn the image.
bool Renderer::Impl::ensure_hud_output(bool display, bool filter, bool depth) {
    if (display && !ensure_filter_target()) return false;
    if (filter && !ensure_output_target(outFilterTarget, "output-filtered", gpu.display_format(), false)) return false;
    return ensure_output_target(outTarget, "output", display ? gpu.display_format() : gameTarget.format.color, depth);
}

void Renderer::Impl::free_output_targets() {
    if (gpu.has_device()) {
        destroy_target(gpu.device(), spatialTarget);
        destroy_target(gpu.device(), outTarget);
        destroy_target(gpu.device(), outFilterTarget);
    }
    free_mfx_images();
    mfxScaler.release();
    outHasStorage = false;
    outActive = false;
    outFilterActive = false;
}

// The "stretch" implementation: a copy of the picture into the output image through a Linear sampler (Nearest for pixel art).
// Nothing is converted: the output image has the format of the input, so linear light stays linear and display values stay
// display values, and present() encodes it as it would have the render-resolution picture.
void Renderer::Impl::stretch_upscale(const UpscaleInput& in, Target& out, const PassContext& c) {
    PassDesc p = pass_into(out, "upscale-stretch");
    p.colorLoad = gpu::LoadAction::DontCare;  // every pixel is drawn
    p.colorStore = gpu::StoreAction::Store;
    gpu::CommandList& list = pass_list(c, gpu);
    list.begin_pass(p);
    list.set_pipeline(gpu.blit_keep_pipeline(p.format));
    gpu::Bindings b;
    b.vertexBuffers[0] = gpu.fullscreen_triangle();
    b.views[VIEW_blit_tex] = in.color;
    b.samplers[SMP_blit_smp] = gpu.sampler(in.pixelArt ? SamplerKind::Nearest : SamplerKind::Linear);
    list.set_bindings(b);
    // A copy between two render targets: the storage layout is kept, so flip is 1 on OpenGL (bottom-up).
    blit_blit_vs_params_t u{};
    u.flip[0] = gpu.is_gl() ? 1.0f : 0.0f;
    list.set_uniforms(UB_blit_blit_vs_params, gpu::Range{&u, sizeof(u)});
    blit_blit_fs_params_t fu{};  // encode 0: copied as it is
    list.set_uniforms(UB_blit_blit_fs_params, gpu::Range{&fu, sizeof(fu)});
    list.draw(0, 3, 1);
    list.end_pass();
    ++stats.drawCalls;
}

// The "temporal" implementation (M76-P4): the TAA resolve of the jittered picture at the render resolution into a history of the output
// resolution, sharpened into `out` (TaaFx::upscale). The depth of the camera's prepass and the velocity are read when the frame has
// them. False (nothing drawn): the plan is off or the history cannot be made; the caller then stretches.
bool Renderer::Impl::temporal_upscale(const UpscaleInput& in, Target& out, const PassContext& c) {
    if (!upscaleTaa.on || !assets || !assets->white()) return false;
    render::TaaResolveInput r;
    r.color = in.color;
    r.dummy = assets->white()->view;
    if (const Target* t = upscalePrepass.target(c)) r.depth = t->texView;
    if (const Target* t = upscaleVelocity.target(c)) r.velocity = t->texView;
    if (const Target* t = upscaleReactive.target(c)) r.reactive = t->texView;
    r.inW = in.renderW;
    r.inH = in.renderH;
    // What the history is bound to besides the camera: the render scale WITHOUT the dynamic resolution's factor (the player's scale and the
    // quality; a change of either drops it) and the quality. Not the render size: a step of the dynamic resolution changes that every few
    // seconds and the resolve takes the size of each frame (inSize), so the history lives on across it. A change of the output size makes
    // another history by itself (TaaFx::slot_for). The jitter phases follow the size, so a step also changes the length of the sequence.
    // The key is two fields of a number: bits 20..39 the base scale in thousandths (20 bits hold up to 1048, far above the 0.25..4 a scale
    // can have, so a clamp is never reached) and bits 0..7 the quality; the other bits are 0. It is only compared for equality.
    const std::uint64_t config =
        (std::uint64_t(std::clamp(std::lround(double(renderBaseScale) * 1000.0), 0L, 0xFFFFFL)) & 0xFFFFF) << 20 |
        (std::uint64_t(int(upscaler.quality)) & 0xFF);
    if (!taa.upscale(gpu, upscaleTaa, r, config, out)) return false;
    stats.drawCalls += 2;  // the resolve and the sharpened copy
    return true;
}

// The image between the two passes of the spatial upscaler: the output size, no depth, the format of the output image. False (and one
// logged error) when the GPU cannot make it: the sharpen is then left out of that frame.
bool Renderer::Impl::ensure_spatial_target(gpu::PixelFormat colorFormat) {
    if (spatialTarget.color.id &&
        (spatialTarget.w != targetW || spatialTarget.h != targetH || spatialTarget.format.color != colorFormat))
        destroy_target(gpu.device(), spatialTarget);
    if (spatialTarget.color.id) return true;
    TargetDesc d;
    d.label = "upscale-spatial";
    d.width = targetW;
    d.height = targetH;
    d.colorFormat = colorFormat;
    d.depthFormat = gpu::PixelFormat::None;
    spatialTarget = make_target(gpu.device(), d);
    if (!spatialTarget.valid(gpu.device())) {
        FA_ERROR(
            "render",
            "Spatial upscaler: cannot create the {}x{} image between its passes; the frame is scaled up without the "
            "sharpen. Hint: lower the window size or set render.upscaler sharpness to 0",
            targetW, targetH);
        destroy_target(gpu.device(), spatialTarget);
        return false;
    }
    return true;
}

// The "spatial" implementation (shaders/upscale_spatial.glsl): the edge-adaptive upsample into `out` (or into spatialTarget when the
// sharpen follows) and the contrast-adaptive sharpen into `out`. Each is skipped when it has nothing to do: at the output size only
// the sharpen runs, with a sharpness of 0 only the upsample. Every pass reads texels with texelFetch, so the sampler is Nearest.
void Renderer::Impl::spatial_upscale(const UpscaleInput& in, Target& out, const PassContext& c) {
    const bool resize = in.renderW != in.outW || in.renderH != in.outH;
    float weight = render::SpatialUpscaler::sharpen_weight(in.sharpness);
    if (!spatial.ready(gpu.device()) || (!resize && weight <= 0.0f)) {
        stretch_upscale(in, out, c);  // the shaders did not compile (logged once), or nothing to do: the plain copy
        return;
    }
    const bool both = resize && weight > 0.0f;
    if (both && !ensure_spatial_target(out.format.color)) weight = 0.0f;
    const bool sharpen = weight > 0.0f;
    const gpu::View mid = both && sharpen ? spatialTarget.texView : gpu::View{};
    auto run = [&](render::SpatialUpscaler::Prog prog, const char* label, gpu::View src, int srcW, int srcH,
                   Target& dst) {
        PassDesc p = pass_into(dst, label);
        p.colorLoad = gpu::LoadAction::DontCare;  // every pixel is drawn
        p.colorStore = gpu::StoreAction::Store;
        gpu::CommandList& list = pass_list(c, gpu);
        list.begin_pass(p);
        list.set_pipeline(spatial.pipeline(prog, p.format));
        gpu::Bindings b;
        b.vertexBuffers[0] = gpu.fullscreen_triangle();
        b.views[VIEW_upscale_spatial_tex] = src;
        b.samplers[SMP_upscale_spatial_smp] = gpu.sampler(SamplerKind::Nearest);
        list.set_bindings(b);
        upscale_spatial_spatial_vs_params_t vu{};
        vu.flip[0] =
            gpu.is_gl() ? 1.0f : 0.0f;  // both passes read and write render targets: the storage layout is kept
        list.set_uniforms(UB_upscale_spatial_spatial_vs_params, gpu::Range{&vu, sizeof(vu)});
        if (prog == render::SpatialUpscaler::Prog::Edge) {
            upscale_spatial_upscale_edge_params_t u{};
            u.src[0] = float(srcW);
            u.src[1] = float(srcH);
            u.src[2] = in.linear ? 1.0f : 0.0f;
            list.set_uniforms(UB_upscale_spatial_upscale_edge_params, gpu::Range{&u, sizeof(u)});
        } else {
            upscale_spatial_upscale_sharpen_params_t u{};
            u.src[0] = float(srcW);
            u.src[1] = float(srcH);
            u.src[2] = in.linear ? 1.0f : 0.0f;
            u.src[3] = weight;
            list.set_uniforms(UB_upscale_spatial_upscale_sharpen_params, gpu::Range{&u, sizeof(u)});
        }
        list.draw(0, 3, 1);
        list.end_pass();
        ++stats.drawCalls;
    };
    if (resize)
        run(render::SpatialUpscaler::Prog::Edge, "upscale-spatial-edge", in.color, in.renderW, in.renderH,
            sharpen ? spatialTarget : out);
    if (sharpen)
        run(render::SpatialUpscaler::Prog::Sharpen, "upscale-spatial-sharpen", resize ? mid : in.color,
            resize ? in.outW : in.renderW, resize ? in.outH : in.renderH, out);
}

// The upscale pass: the picture of the render resolution (scene_target()) into `out`. The implementation follows the effective upscaler mode and the frame (Temporal only on a frame the renderer jittered).
void Renderer::Impl::run_upscale(Target& out, const PassContext& c) {
    const Target& src = scene_target();
    UpscaleInput in;
    in.color = src.texView;
    in.renderW = src.w;
    in.renderH = src.h;
    in.outW = out.w;
    in.outH = out.h;
    in.frameIndex = postSerial;
    in.pixelArt = scaleMode == ScaleMode::PixelPerfect;
    in.linear = gpu.linear() && !finalEncoded;  // linear light (display values after a final pass)
    in.sharpness = upscaler.sharpness;
    // The implementation follows the effective mode (pixel art is stretch there): the one place that decides it. Temporal draws on the
    // frame render() jittered for it (temporalFrame); a temporal mode on a frame that was not (the stage came up between the two) and a
    // temporal picture that cannot be made fall to the spatial upscaler, as the effective mode does.
    const render::UpscalerMode mode = effective_upscaler_mode();
    if (temporalFrame)
        upscaleImpl = mfxFrame && !mfxFailed ? UpscaleImpl::MetalFx : UpscaleImpl::Temporal;
    else if (mode == render::UpscalerMode::Stretch)
        upscaleImpl = UpscaleImpl::Stretch;
    else
        upscaleImpl = mode == render::UpscalerMode::MetalFx ? UpscaleImpl::MetalFx : UpscaleImpl::Spatial;
    if (temporalFrame) {
        in.jitter[0] = upscaleTaa.jitterPx.x;
        in.jitter[1] = upscaleTaa.jitterPx.y;
    }
    // MetalFX first (its temporal scaler on a jittered frame, its spatial one on the others); a frame it cannot draw falls to the temporal
    // upscaler when the frame is jittered, then to the spatial one, as the effective mode lists them.
    if (upscaleImpl == UpscaleImpl::MetalFx && !metalfx_upscale(in, src, out, c))
        upscaleImpl = temporalFrame ? UpscaleImpl::Temporal : UpscaleImpl::Spatial;
    if (mode != render::UpscalerMode::MetalFx)
        free_mfx_images();  // another mode: the two images of its preparation pass are not kept
    if (upscaleImpl == UpscaleImpl::Temporal && !temporal_upscale(in, out, c))
        upscaleImpl = UpscaleImpl::Spatial;  // no history to make: this frame is upscaled spatially
    switch (upscaleImpl) {
        case UpscaleImpl::Stretch: stretch_upscale(in, out, c); break;
        case UpscaleImpl::Spatial: spatial_upscale(in, out, c); break;
        case UpscaleImpl::Temporal:
        case UpscaleImpl::MetalFx: break;  // drawn above
    }
    outActive = true;
}

}  // namespace fa
