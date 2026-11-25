// Renderer: the MetalFX upscale (M76-P5b), the "metalfx" implementation of the upscale stage (render_upscale.h). Apple's temporal scaler takes
// the jittered picture at the render resolution, a 0..1 depth and a motion image; its spatial scaler takes the picture alone. The wrapper is
// metalfx.h; docs/design/ARCHITECTURE_RENDERING_POST.md ("MetalFX (M76)") and docs/UPSCALING.md say the same.
#include "render_upscale.h"

#include <algorithm>
#include <cmath>
#include <string>

#include "fa/core/log.h"

#include "fullscreen_gpu.h"
#include "renderer_impl.h"

#include "shaders/upscale_mfx.glsl.h"

namespace fa {

using render::UpscaleImpl;
using render::UpscaleInput;

// What this GPU can do, asked once (a class lookup and two device questions).
const render::metalfx::Support& Renderer::Impl::metalfx_support() {
    if (!mfxSupportKnown) {
        mfxSupport = render::metalfx::support(gpu.device().native().device);
        mfxSupportKnown = true;
    }
    return mfxSupport;
}

// MetalFX failed on this machine (a scaler it could not make, a frame it refused): from now on every frame is drawn without it, with one
// warning that says what happened and what draws instead. Returns false so the caller can `return metalfx_fail(...)`.
bool Renderer::Impl::metalfx_fail(const std::string& why) {
    if (!mfxFailed) {
        FA_WARN("render",
                "MetalFX failed: {} The upscaler continues with the temporal TAA upscaler (the spatial one on a frame "
                "that cannot "
                "use it) for the rest of this run. Hint: set render.upscaler mode to \"temporal\" to silence this.",
                why);
    }
    mfxFailed = true;
    mfxScaler.release();
    free_mfx_images();
    return false;
}

// The depth and motion images of the preparation pass are made at the render resolution only while MetalFX draws; a failure of MetalFX and
// a frame of another upscaler give them back.
void Renderer::Impl::free_mfx_images() {
    if (mfxDepth.color.id) destroy_target(gpu.device(), mfxDepth);
    if (mfxMotion.color.id) destroy_target(gpu.device(), mfxMotion);
    mfxLastWrote = false;
}

// An image of the MetalFX preparation pass: `format` at w x h, a colour attachment that is also sampled.
bool Renderer::Impl::ensure_mfx_target(Target& t, const char* label, gpu::PixelFormat format, int w, int h) {
    if (t.color.id && (t.w != w || t.h != h || t.format.color != format)) destroy_target(gpu.device(), t);
    if (t.color.id) return true;
    TargetDesc d;
    d.label = label;
    d.width = w;
    d.height = h;
    d.colorFormat = format;
    t = make_target(gpu.device(), d);
    if (!t.valid(gpu.device())) {
        destroy_target(gpu.device(), t);
        return false;
    }
    return true;
}

// The "metalfx" implementation into `out`: false (nothing drawn, `out` untouched) when this frame cannot use it, and a failure of the GPU or
// of MetalFX also sets mfxFailed (one warning, metalfx_fail). A jittered frame with the temporal scaler needs the depth prepass of its camera
// (a frame that drew no mesh has none: everything is sky then) and reads the velocity when there is one.
bool Renderer::Impl::metalfx_upscale(const UpscaleInput& in, const Target& src, Target& out, const PassContext& c) {
    using render::metalfx::Kind;
    if (mfxFailed || !gpu.has_device() || !render::metalfx::on_metal(gpu.device()) || !out.valid(gpu.device()) ||
        !src.valid(gpu.device()))
        return false;
    // A command buffer of an earlier frame came back with an error (it finishes on another thread): MetalFX is given up from this frame on.
    std::string commandError;
    if (mfxScaler.command_failed(&commandError))
        return metalfx_fail("a MetalFX command buffer finished with an error: " + commandError + ".");
    const render::metalfx::Support& support = metalfx_support();
    const bool temporalKind = temporalFrame && mfxFrame && upscaleTaa.on && support.temporal;
    if (temporalFrame && !temporalKind)
        return false;  // a jittered frame without a plan: the next implementation draws it
    if (!temporalKind && !support.spatial)
        return false;  // a GPU with the temporal scaler only: the next implementation draws this frame
    if (temporalKind && (!assets || !assets->white())) return false;
    if (temporalKind && !mfxPrep.ready(gpu.device()))
        return metalfx_fail("the input preparation shader did not compile.");

    render::metalfx::Desc d;
    d.kind = temporalKind ? Kind::Temporal : Kind::Spatial;
    d.inputWidth = in.renderW;
    d.inputHeight = in.renderH;
    d.outputWidth = in.outW;
    d.outputHeight = in.outH;
    d.colorFormat = src.format.color;
    d.outputFormat = out.format.color;
    // Spatial: linear light above 1 in a float scene, linear light in a smaller one, else display values.
    d.colorSpace = !in.linear                                      ? render::metalfx::ColorSpace::Perceptual
                   : src.format.color == gpu::PixelFormat::Rgba16F ? render::metalfx::ColorSpace::Hdr
                                                                   : render::metalfx::ColorSpace::Linear;
    d.depthFormat = gpu::PixelFormat::R32F;
    d.motionFormat = gpu::PixelFormat::Rg16F;
    d.autoExposure = false;  // the scene colour is exposed before the stage: pre-exposure 1
    // The scaler takes the reactive mask from the start (on an OS that has the input) instead of being made again when the first
    // mask appears: a new scaler pays its synchronous start-up and drops the history, in the very frame a particle shows up, and a
    // frame without a mask draws as a scaler made without the input (metalfx_tests checks that). Costs nothing else.
    d.reactiveMask = temporalKind;
    std::string error;
    if (mfxForceCreateFail) return metalfx_fail("MetalFX creation was refused (test hook).");

    render::metalfx::Frame f;
    f.color = src.texture_image();
    f.output = out.color;
    if (temporalKind) {
        const Target* prepass = upscalePrepass.target(c);
        const Target* velocity = upscaleVelocity.target(c);
        if (prepass && (prepass->w != in.renderW || prepass->h != in.renderH))
            prepass = nullptr;  // not the picture's size: every pixel is sky
        if (velocity && (velocity->w != in.renderW || velocity->h != in.renderH)) velocity = nullptr;
        // The reactive mask is a transient of this frame (the pass that draws it ran before this one, and exists only when an item asked):
        // it goes to MetalFX when it is the picture's size and the format the scaler reads, else this frame has none.
        const Target* reactive = upscaleReactive.target(c);
        if (reactive && (reactive->w != in.renderW || reactive->h != in.renderH ||
                         reactive->format.color != Gpu::reactive_format()))
            reactive = nullptr;
        if (reactive && !mfxNoReactive) f.reactive = reactive->texture_image();
        if (!ensure_mfx_target(mfxDepth, "mfx-depth", gpu::PixelFormat::R32F, in.renderW, in.renderH) ||
            !ensure_mfx_target(mfxMotion, "mfx-motion", gpu::PixelFormat::Rg16F, in.renderW, in.renderH))
            return metalfx_fail("the depth and motion images of the render size could not be made.");

        // The history starts again on the events of the temporal upscaler (TaaFx::upscale): a cut (no camera of the frame before), a frame
        // MetalFX did not draw in between, another scene, a floating-origin shift, another render size or quality. A new scaler resets itself
        // (its first encode), which covers a change of size, format or kind.
        const std::uint64_t config = (std::uint64_t(std::max(in.renderW, 0)) & 0xFFFFF) << 40 |
                                     (std::uint64_t(std::max(in.renderH, 0)) & 0xFFFFF) << 20 |
                                     (std::uint64_t(int(upscaler.quality)) & 0xFF);
        const bool histValid = mfxLastWrote && mfxLastSerial + 1 == upscaleTaa.serial &&
                               mfxLastScene == upscaleTaa.sceneKey && mfxLastShifts == upscaleTaa.originShifts &&
                               mfxLastConfig == config && upscaleTaa.prevValid;

        PassDesc p = pass_into(mfxDepth, "upscale-metalfx-prep");
        p.color1 = mfxMotion.colorAtt;
        p.format.color1 = mfxMotion.format.color;
        p.colorLoad = gpu::LoadAction::DontCare;  // every pixel of both images is drawn
        p.colorStore = gpu::StoreAction::Store;
        const gpu::Pipeline prepPipeline = mfxPrep.pipeline(p.format);  // before the pass: nothing is made inside one
        gpu::CommandList& list = pass_list(c, gpu);
        list.begin_pass(p);
        list.set_pipeline(prepPipeline);
        gpu::Bindings b;
        b.vertexBuffers[0] = gpu.fullscreen_triangle();
        b.views[VIEW_upscale_mfx_tex_p] = prepass ? prepass->texView : assets->white()->view;
        b.views[VIEW_upscale_mfx_tex_v] = velocity ? velocity->texView : assets->white()->view;
        b.samplers[SMP_upscale_mfx_smp_pt] = gpu.sampler(SamplerKind::Nearest);
        list.set_bindings(b);
        upscale_mfx_mfx_params_t u{};
        u.s[0] = float(in.renderW);
        u.s[1] = float(in.renderH);
        u.s[2] = velocity ? 1.0f : 0.0f;
        u.s[3] = mfxMotionSign;
        u.j[0] = upscaleTaa.jitterPx.x;
        u.j[1] = upscaleTaa.jitterPx.y;
        u.j[2] = histValid ? 1.0f : 0.0f;
        u.j[3] = prepass ? 1.0f : 0.0f;
        for (int i = 0; i < 4; ++i) u.pa[i] = upscaleTaa.proj[i];
        for (int i = 0; i < 4; ++i) u.pb[i] = upscaleTaa.proj[4 + i];
        for (int i = 0; i < 16; ++i) u.m[i] = upscaleTaa.prevFromView.m[i];
        list.set_uniforms(UB_upscale_mfx_mfx_params, gpu::Range{&u, sizeof(u)});
        list.draw(0, 3, 1);
        list.end_pass();
        ++stats.drawCalls;

        f.depth = mfxDepth.color;
        f.motion = mfxMotion.color;
        // The picture was drawn moved by the jitter (right and down); the motion image is in UV units, MetalFX scales it to render pixels.
        f.jitterX = upscaleTaa.jitterPx.x * mfxJitterSign;
        f.jitterY = upscaleTaa.jitterPx.y * mfxJitterSign;
        f.motionScaleX = float(in.renderW);
        f.motionScaleY = float(in.renderH);
        f.reset = !histValid;
        mfxLastSerial = upscaleTaa.serial;
        mfxLastScene = upscaleTaa.sceneKey;
        mfxLastShifts = upscaleTaa.originShifts;
        mfxLastConfig = config;
    }
    if (mfxPrepOnly) return false;  // test hook: the preparation pass is drawn and read, MetalFX is not asked
    // After the preparation pass: a scaler MetalFX cannot make costs one preparation pass, once (the failure is for good).
    if (!mfxScaler.configure(gpu.device(), d, &error)) return metalfx_fail(error);
    // a scaler made just now starts its history; the spatial one has none
    mfxLastReset = temporalKind && (f.reset || mfxScaler.encoded() == 0);
    // Encode splits the frame (a commit of the device): the passes recorded so far, which wrote the picture, go first.
    if (!mfxScaler.encode(gpu.device(), f, &error)) return metalfx_fail(error);
    gpu.note_work();  // encode left the device's buffer for the passes after it open and uncommitted: a read back must commit it first
    mfxLastWrote = temporalKind;
    ++stats.drawCalls;  // the scaler's own pass
    return true;
}

}  // namespace fa
