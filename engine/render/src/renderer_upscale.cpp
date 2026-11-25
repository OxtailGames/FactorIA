// Renderer: the upscale stage (render_upscale.h) and the output-resolution images the screen-space items are drawn into after it.
#include "render_upscale.h"

#include <algorithm>
#include <cmath>

#include "fa/scene/jitter.h"

#include "renderer_impl.h"

#include "fullscreen_gpu.h"

#include "render_features.h"
#include "render_upscale_vendor.h"
#include "shaders/upscale_rr.glsl.h"
#include "shaders/upscale_spatial.glsl.h"

namespace fa::render {

UpscaleImpl select_upscale_impl(std::string_view mode, bool* known) {
    const bool understood = mode == "stretch" || mode == "spatial" || mode == "temporal" || mode == "metalfx" ||
                            mode == "dlss" || mode == "xess" || mode == "fsr";
    if (known) *known = understood;
    if (mode == "temporal") return UpscaleImpl::Temporal;
    if (mode == "metalfx") return UpscaleImpl::MetalFx;
    if (mode == "dlss") return UpscaleImpl::Dlss;
    if (mode == "xess") return UpscaleImpl::Xess;
    if (mode == "fsr") return UpscaleImpl::Fsr;
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
        case UpscaleImpl::Dlss: return "dlss";
        case UpscaleImpl::Xess: return "xess";
        case UpscaleImpl::Fsr: return "fsr";
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
// scalers (metalfx.h, asked once), until one of its frames fails here. The vendor SDKs (M78, render_upscale_vendor.h) are asked when the
// setting wants one (that mode, or "auto" on a GPU of that maker), once, and are off for the rest of the run after a failed frame.
render::UpscalerCaps Renderer::Impl::upscaler_caps() {
    // Asked once, with a device: without one the answer (no) is not kept, so a renderer that gets its device later asks again.
    if (spatialSupported < 0 && gpu.has_device()) {
        const int row = render::find_feature("spatialUpscaler");
        spatialSupported =
            row >= 0 && render::feature_supported(render::feature_env_from_device(gpu.device()), row) ? 1 : 0;
    }
    render::UpscalerCaps caps;
    caps.pixelArt = scaleMode == ScaleMode::PixelPerfect;
    caps.spatial = spatialSupported > 0;
    if (gpu.has_device() &&
        (upscaler.mode == render::UpscalerMode::Temporal || upscaler.mode == render::UpscalerMode::Auto ||
         upscaler.mode == render::UpscalerMode::MetalFx || render::vendor_upscaler_index(upscaler.mode) >= 0))
        caps.temporal = taa.ready(gpu.device()) && !taa.upscale_unavailable();
    caps.multiCamera = temporalBlocked;
    if (gpu.has_device() && render::metalfx::on_metal(gpu.device()) && !mfxFailed) {
        const render::metalfx::Support& ms = metalfx_support();
        caps.metalfx = ms.spatial || ms.temporal;
        caps.metalfxTemporal = ms.temporal;
    } else {
        caps.metalfx = false;
        caps.metalfxTemporal = false;  // no MetalFX at all, so no temporal one either (the default says true)
    }
    if (gpu.has_device()) {
        caps.gpuVendor = render::gpu_vendor_of(gpu.device());
        const int own = caps.gpuVendor == render::GpuVendor::Nvidia  ? 0
                        : caps.gpuVendor == render::GpuVendor::Intel ? 1
                        : caps.gpuVendor == render::GpuVendor::Amd   ? 2
                                                                     : -1;
        for (int i = 0; i < render::kVendorUpscalerCount; ++i) {
            const bool wanted = render::vendor_upscaler_index(upscaler.mode) == i ||
                                (upscaler.mode == render::UpscalerMode::Auto && own == i);
            if (!wanted) continue;
            const bool usable = vendor_probe(i).available && !vendorFailed[i];
            (i == 0 ? caps.dlss : i == 1 ? caps.xess : caps.fsr) = usable;
            // An explicit vendor mode its SDK cannot run says why, once (the effective mode then is the next best, as render.upscaler reports).
            if (!usable && !vendorFailed[i] && !vendorWarnedUnavailable[i] &&
                upscaler.mode == render::vendor_upscaler_mode(i)) {
                vendorWarnedUnavailable[i] = true;
                FA_WARN(
                    "render",
                    "render.upscaler mode \"{}\" is not available: {} The temporal upscaler is used instead, then the "
                    "spatial one.",
                    render::vendor_provider(i).mode(), vendorProbe[i].reason);
            }
        }
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
    rrPrep.release();
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
    if (!taa.upscale(pass_list(c, gpu), gpu, upscaleTaa, r, config, out)) return false;
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

// What provider `index` answered for this GPU, asked once. Needs a device.
const render::VendorProbe& Renderer::Impl::vendor_probe(int index) {
    if (!vendorProbed[index]) {
        vendorProbe[index] = render::vendor_provider(index).probe(render::vendor_env_of(gpu.device()));
        vendorProbed[index] = true;
    }
    return vendorProbe[index];
}

// What DLSS answered for Ray Reconstruction on this GPU (Streamline's Ray Reconstruction plugin included), asked once. Needs a device.
const render::VendorProbe& Renderer::Impl::rr_probe() {
    if (!rrProbed) {
        rrProbe = render::vendor_provider(0).probe_ray_reconstruction(render::vendor_env_of(gpu.device()));
        rrProbed = true;
    }
    return rrProbe;
}

// The providers' answers for render.supports: a provider that refused a frame is off, with that reason.
void Renderer::Impl::set_vendor_env(render::FeatureEnv& env) {
    std::array<render::VendorProbe, render::kVendorUpscalerCount> answers;
    for (int i = 0; i < render::kVendorUpscalerCount; ++i) {
        answers[std::size_t(i)] = vendor_probe(i);
        if (vendorFailed[i]) {
            answers[std::size_t(i)].available = false;
            answers[std::size_t(i)].reason = std::string(render::vendor_provider(i).name()) +
                                             " failed a frame earlier in this run (" + vendorFailedWhy[i] +
                                             "); the temporal upscaler draws instead.";
        }
    }
    // Ray Reconstruction: the machine's answer; off after a frame DLSS refused with it, or when DLSS itself is off. The linear frame it needs
    // is a property of the renderer's pipeline (gpu.linear()), not of the machine: it is said here too.
    render::VendorProbe rr = rr_probe();
    if (rr.available && !gpu.linear()) {
        rr.available = false;
        rr.reason = "DLSS Ray Reconstruction needs the picture in linear HDR light, and this renderer works in display "
                    "values (the sRGB "
                    "framebuffer is not available on this device).";
    }
    if (rr.available && rrFailed) {
        rr.available = false;
        rr.reason =
            "DLSS Ray Reconstruction failed earlier in this run (" + rrFailedWhy + "); Super Resolution draws instead.";
    }
    if (rr.available && !answers[0].available) {
        rr.available = false;
        rr.reason = answers[0].reason;
    }
    render::set_vendor_upscalers_env(env, answers, rr);
}

// A vendor SDK failed on this machine (a frame its provider refused): from now on every frame is drawn without it, with one warning that
// says what happened. The rule of MetalFX (metalfx_fail): fail once, stay off. Returns false so the caller can `return vendor_fail(...)`.
bool Renderer::Impl::vendor_fail(int index, const std::string& why) {
    if (index >= 0 && index < render::kVendorUpscalerCount && !vendorFailed[index]) {
        vendorFailed[index] = true;
        vendorFailedWhy[index] = why;
        FA_WARN("render",
                "{} failed: {} The upscaler continues with the temporal TAA upscaler (the spatial one on a frame that "
                "cannot use it) for "
                "the rest of this run. Hint: set render.upscaler mode to \"temporal\" to silence this.",
                render::vendor_provider(index).name(), why.empty() ? std::string("the provider gave no reason.") : why);
    }
    return false;
}

// The guides pass of DLSS Ray Reconstruction (shaders/upscale_rr.glsl): from the depth prepass, the world normal with a roughness and the
// hardware depth of the camera's projection (Ray Reconstruction is told that projection, so it cannot read the prepass's d / (d + 1)), and
// a cleared image for each albedo. The renderer is a forward renderer with no material G-buffer, so the roughness and the two albedos are
// constants (docs/UPSCALING_VENDORS.md, "DLSS Ray Reconstruction"). A null `prepass` means every pixel is sky. False when the four images
// cannot be made. The caller made sure rrPrep is ready.
bool Renderer::Impl::run_rr_guides(const UpscaleInput& in, const PassContext& c, const Target* prepass) {
    if (!ensure_mfx_target(rrNormal, "rr-normal-roughness", gpu::PixelFormat::Rgba16F, in.renderW, in.renderH) ||
        !ensure_mfx_target(rrDiffuse, "rr-diffuse-albedo", gpu::PixelFormat::Rgba8, in.renderW, in.renderH) ||
        !ensure_mfx_target(rrSpecular, "rr-specular-albedo", gpu::PixelFormat::Rgba8, in.renderW, in.renderH) ||
        !ensure_mfx_target(rrDepth, "rr-depth", gpu::PixelFormat::R32F, in.renderW, in.renderH))
        return false;
    constexpr float kRoughness = 0.5f, kDiffuseAlbedo = 0.5f, kSpecularAlbedo = 0.04f;
    gpu::CommandList& list = pass_list(c, gpu);
    {
        PassDesc p = pass_into(rrNormal, "upscale-rr-guides");
        p.color1 = rrDepth.colorAtt;
        p.format.color1 = rrDepth.format.color;
        p.colorLoad = gpu::LoadAction::DontCare;  // every pixel of both images is drawn
        p.colorStore = gpu::StoreAction::Store;
        const gpu::Pipeline pipeline = rrPrep.pipeline(p.format);  // before the pass: nothing is made inside one
        list.begin_pass(p);
        list.set_pipeline(pipeline);
        gpu::Bindings b;
        b.vertexBuffers[0] = gpu.fullscreen_triangle();
        b.views[VIEW_upscale_rr_tex_p] = prepass ? prepass->texView : assets->white()->view;
        b.samplers[SMP_upscale_rr_smp_pt] = gpu.sampler(SamplerKind::Nearest);
        list.set_bindings(b);
        upscale_rr_rr_params_t u{};
        const Vec3 back = upscaleTaa.forward * -1.0f;
        u.right[0] = upscaleTaa.right.x;
        u.right[1] = upscaleTaa.right.y;
        u.right[2] = upscaleTaa.right.z;
        u.right[3] = kRoughness;
        u.up[0] = upscaleTaa.up.x;
        u.up[1] = upscaleTaa.up.y;
        u.up[2] = upscaleTaa.up.z;
        u.back[0] = back.x;
        u.back[1] = back.y;
        u.back[2] = back.z;
        u.back[3] = prepass ? 1.0f : 0.0f;
        render::rr_depth_terms(upscaleTaa.projection, u.zrow);  // the unjittered projection the provider is told too
        list.set_uniforms(UB_upscale_rr_rr_params, gpu::Range{&u, sizeof(u)});
        list.draw(0, 3, 1);
        list.end_pass();
        ++stats.drawCalls;
    }
    // The two albedos are constants (the renderer has no material G-buffer): a clear pass each.
    for (int i = 0; i < 2; ++i) {
        const float v = i == 0 ? kDiffuseAlbedo : kSpecularAlbedo;
        PassDesc p = pass_into(i == 0 ? rrDiffuse : rrSpecular, i == 0 ? "upscale-rr-diffuse" : "upscale-rr-specular");
        p.colorLoad = gpu::LoadAction::Clear;
        p.clearColor = gpu::Color{v, v, v, 1.0f};
        p.colorStore = gpu::StoreAction::Store;
        list.begin_pass(p);
        list.end_pass();
        ++stats.drawCalls;
    }
    return true;
}

void Renderer::Impl::free_rr_images() {
    if (!gpu.has_device()) return;
    destroy_target(gpu.device(), rrNormal);
    destroy_target(gpu.device(), rrDiffuse);
    destroy_target(gpu.device(), rrSpecular);
    destroy_target(gpu.device(), rrDepth);
}

// The vendor implementation into `out` (M78): the provider of `impl` is given the frame's images and the pass's command list. False
// (nothing drawn, `out` untouched) when the provider is off or this frame has nothing for it, and a provider that refuses a frame is off for
// good (vendor_fail). Fills the depth, velocity and reactive views of `in` (what the frame has, at the picture's size).
bool Renderer::Impl::vendor_upscale(UpscaleImpl impl, UpscaleInput& in, const Target& src, Target& out,
                                    const PassContext& c) {
    const int index = render::vendor_impl_index(impl);
    if (index < 0 || vendorFailed[index] || !gpu.has_device() || !out.valid(gpu.device()) || !src.valid(gpu.device()))
        return false;
    const Target* prepass = upscalePrepass.target(c);
    const Target* velocity = upscaleVelocity.target(c);
    const Target* reactive = upscaleReactive.target(c);
    // Only what is the picture's size (and, for the reactive mask, the format the temporal passes write) goes to the SDK.
    if (prepass && (prepass->w != in.renderW || prepass->h != in.renderH)) prepass = nullptr;
    if (velocity && (velocity->w != in.renderW || velocity->h != in.renderH)) velocity = nullptr;
    if (reactive &&
        (reactive->w != in.renderW || reactive->h != in.renderH || reactive->format.color != Gpu::reactive_format()))
        reactive = nullptr;
    // The SDKs read a 0..1 depth and a motion image in UV units, not the prepass's world-unit depth and the velocity's "none" sentinel: the
    // preparation pass MetalFX uses makes them (a frame without a prepass is all sky, without a velocity every motion is the camera's).
    if (!upscaleTaa.on || !assets || !assets->white()) return false;
    if (!mfxPrep.ready(gpu.device())) return vendor_fail(index, "the input preparation shader did not compile.");
    std::uint64_t config = 0;
    const bool histValid = scaler_history_valid(in, config);
    render::VendorUpscaler& provider = render::vendor_provider(index);
    in.cameraNear = 0.1f;  // any near plane serves: the provider is told the one the reversed depth is made with
    in.dynamicResolution = renderScale != renderBaseScale;
    if (!run_upscale_prep(in, c, prepass, velocity, histValid, provider.wants_reversed_depth() ? in.cameraNear : 0.0f))
        return vendor_fail(index, "the depth and motion images of the render size could not be made.");
    scaler_history_note(config);
    // What an SDK asks besides the images: the sizes it was made for, the quality, the engine clock, the camera's lens.
    in.quality = upscaler.quality;
    in.maxRenderW = std::max(in.renderW, int(std::lround(double(in.outW) * double(renderBaseScale))));
    in.maxRenderH = std::max(in.renderH, int(std::lround(double(in.outH) * double(renderBaseScale))));
    in.frameTimeMs = frameDt * 1000.0f;
    const float p11 = upscaleTaa.proj[1];
    in.cameraFovY =
        p11 > 1e-4f ? 2.0f * std::atan(1.0f / p11) : 1.0f;  // an orthographic lens has no field of view: a nominal one
    in.depth = mfxDepth.texView;
    in.velocity = mfxMotion.texView;
    in.reactive = reactive ? reactive->texView : gpu::View{};
    in.exposure = 1.0f;  // the scene is exposed before the stage
    in.resetHistory = !histValid;
    // The camera the frame was drawn with (DLSS Ray Reconstruction is told its matrices).
    render::UpscaleCamera& cam = in.camera;
    cam.valid = true;
    cam.perspective = upscaleTaa.perspective;
    std::copy(upscaleTaa.view.m, upscaleTaa.view.m + 16, cam.view);
    std::copy(upscaleTaa.projection.m, upscaleTaa.projection.m + 16, cam.proj);
    std::copy(upscaleTaa.prevFromView.m, upscaleTaa.prevFromView.m + 16, cam.prevFromView);
    cam.prevValid = histValid;
    const Vec3 axes[4] = {upscaleTaa.position, upscaleTaa.right, upscaleTaa.up, upscaleTaa.forward};
    float* const dest[4] = {cam.position, cam.right, cam.up, cam.forward};
    for (int i = 0; i < 4; ++i) {
        dest[i][0] = axes[i].x;
        dest[i][1] = axes[i].y;
        dest[i][2] = axes[i].z;
    }
    cam.nearPlane = upscaleTaa.nearPlane;
    cam.farPlane = upscaleTaa.farPlane;
    // DLSS Ray Reconstruction (M78-P4c): when the setting asks for it, this frame can use it and the guides are made. Else the frame is
    // drawn with Super Resolution, the reason said once; a machine that refuses it, or a frame it refused, stays off.
    in.rayReconstruction = false;
    if (index == 0 && upscaler.rayReconstruction) {
        std::string why;
        bool permanent =
            false;  // the reason belongs to the machine or to a refused frame: the setting stays unusable for this run
        if (rrFailed) {
            why = rrFailedWhy;
        } else if (!rr_probe().available) {
            why = rr_probe().reason;
            permanent = true;
        } else if (!in.linear) {
            why = "the frame is not in linear HDR light (the picture is display values: a final pass or a "
                  "display-referred pipeline), "
                  "and Ray Reconstruction reads linear colour";
        } else if (in.dynamicResolution) {
            why = "the dynamic resolution is changing the render size, which Ray Reconstruction does not support";
        } else if (!upscaleTaa.perspective) {
            why = "the camera is orthographic, and Ray Reconstruction needs a perspective one";
        } else if (!rrPrep.ready(gpu.device())) {
            why = "the guides shader did not compile";
            rrFailed = true;
            rrFailedWhy = why;
        } else if (!run_rr_guides(in, c, prepass)) {
            why = "the guide images of the render size could not be made";
            rrFailed = true;
            rrFailedWhy = why;
        } else {
            in.rayReconstruction = true;
        }
        if (!in.rayReconstruction) {
            bool& warned = permanent ? rrWarnedUnavailable : rrWarnedFrame;
            if (!warned) {
                warned = true;
                FA_WARN(
                    "render",
                    "DLSS Ray Reconstruction is not used: {}. Super Resolution draws instead. Hint: render.supports "
                    "\"dlssRayReconstruction\" says what this machine can do; set render.upscaler rayReconstruction to "
                    "false to silence "
                    "this.",
                    why);
            }
        }
    }
    if (!in.rayReconstruction) free_rr_images();
    render::VendorFrame f;
    f.device = &gpu.device();
    f.list = &pass_list(c, gpu);
    f.color = src.texture_image();
    f.depth = mfxDepth.color;
    f.velocity = mfxMotion.color;
    f.reactive = reactive ? reactive->texture_image() : gpu::Image{};
    f.output = out.color;
    f.colorFormat = src.format.color;
    f.outputFormat = out.format.color;
    if (in.rayReconstruction) {
        f.normalRoughness = rrNormal.color;
        f.diffuseAlbedo = rrDiffuse.color;
        f.specularAlbedo = rrSpecular.color;
        f.rrDepth = rrDepth.color;
        in.normalRoughness = rrNormal.texView;
        in.diffuseAlbedo = rrDiffuse.texView;
        in.specularAlbedo = rrSpecular.texView;
        in.rrDepth = rrDepth.texView;
    }
    mfxLastWrote = false;  // until the provider has drawn: a frame it refuses leaves no history behind
    if (!provider.upscale(in, f)) return vendor_fail(index, f.error);
    mfxLastWrote = true;
    if (index == 0) rrLastUsed = f.usedRayReconstruction;
    if (in.rayReconstruction && !f.usedRayReconstruction) {
        // DLSS drew the frame with Super Resolution: Ray Reconstruction is off for the rest of the run (fail once, stay off).
        rrFailed = true;
        rrFailedWhy =
            f.rayReconstructionFallback.empty() ? std::string("DLSS gave no reason") : f.rayReconstructionFallback;
        rrWarnedFrame = true;
        FA_WARN("render",
                "DLSS Ray Reconstruction is not used: {} Super Resolution draws instead for the rest of this run. "
                "Hint: set "
                "render.upscaler rayReconstruction to false to silence this.",
                rrFailedWhy);
        free_rr_images();
    }
    ++stats.drawCalls;  // the provider's own pass
    return true;
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
    const int vendorIndex = render::vendor_impl_index(vendorFrameImpl);
    if (temporalFrame)
        upscaleImpl = vendorIndex >= 0 && !vendorFailed[vendorIndex] ? vendorFrameImpl
                      : mfxFrame && !mfxFailed                       ? UpscaleImpl::MetalFx
                                                                     : UpscaleImpl::Temporal;
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
    // A vendor SDK (M78) draws the jittered frame through its provider; a frame it cannot draw (and its failure for good) falls to the
    // temporal upscaler, which the jittered frame suits, then to the spatial one.
    if (render::vendor_impl_index(upscaleImpl) >= 0 && !vendor_upscale(upscaleImpl, in, src, out, c))
        upscaleImpl = temporalFrame ? UpscaleImpl::Temporal : UpscaleImpl::Spatial;
    if (mode != render::UpscalerMode::MetalFx && render::vendor_impl_index(vendorFrameImpl) < 0)
        free_mfx_images();  // another mode: the two images of its preparation pass are not kept (the vendor SDKs use them too)
    if (upscaleImpl == UpscaleImpl::Temporal && !temporal_upscale(in, out, c))
        upscaleImpl = UpscaleImpl::Spatial;  // no history to make: this frame is upscaled spatially
    switch (upscaleImpl) {
        case UpscaleImpl::Stretch: stretch_upscale(in, out, c); break;
        case UpscaleImpl::Spatial: spatial_upscale(in, out, c); break;
        case UpscaleImpl::Temporal:
        case UpscaleImpl::MetalFx:
        case UpscaleImpl::Dlss:
        case UpscaleImpl::Xess:
        case UpscaleImpl::Fsr: break;  // drawn above
    }
    outActive = true;
}

}  // namespace fa
