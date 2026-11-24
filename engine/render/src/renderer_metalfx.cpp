// Renderer: the MetalFX upscale (M76-P5b), the "metalfx" implementation of the upscale stage (render_upscale.h). Apple's temporal scaler takes
// the jittered picture at the render resolution, a 0..1 depth and a motion image; its spatial scaler takes the picture alone. The wrapper is
// metalfx.h; docs/design/ARCHITECTURE_RENDERING_POST.md ("MetalFX (M76)") and docs/UPSCALING.md say the same.
#include "render_upscale.h"

#include <algorithm>
#include <cmath>
#include <string>

#include "fa/core/log.h"

#include "renderer_impl.h"

#include "shaders/upscale_mfx.glsl.h"

namespace fa {

using render::UpscaleImpl;
using render::UpscaleInput;

// What this GPU can do, asked once (a class lookup and two device questions).
const render::metalfx::Support& Renderer::Impl::metalfx_support() {
    if (!mfxSupportKnown) {
        mfxSupport = render::metalfx::support();
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
    mfxLastWrote = false;
    return false;
}

// An image of the MetalFX preparation pass: `format` at w x h, a colour attachment that is also sampled.
bool Renderer::Impl::ensure_mfx_target(Target& t, const char* label, sg_pixel_format format, int w, int h) {
    if (t.color.id && (t.w != w || t.h != h || t.format.color != format)) destroy_target(t);
    if (t.color.id) return true;
    TargetDesc d;
    d.label = label;
    d.width = w;
    d.height = h;
    d.colorFormat = format;
    t = make_target(d);
    if (!t.valid()) {
        destroy_target(t);
        return false;
    }
    return true;
}

// The "metalfx" implementation into `out`: false (nothing drawn, `out` untouched) when this frame cannot use it, and a failure of the GPU or
// of MetalFX also sets mfxFailed (one warning, metalfx_fail). A jittered frame with the temporal scaler needs the depth prepass of its camera
// (a frame that drew no mesh has none: everything is sky then) and reads the velocity when there is one.
bool Renderer::Impl::metalfx_upscale(const UpscaleInput& in, const Target& src, Target& out, const PassContext& c) {
    using render::metalfx::Kind;
    if (mfxFailed || !sg_isvalid() || !render::metalfx::on_metal() || !out.valid() || !src.valid()) return false;
    const render::metalfx::Support& support = metalfx_support();
    const bool temporalKind = temporalFrame && mfxFrame && upscaleTaa.on && support.temporal;
    if (temporalFrame && !temporalKind)
        return false;  // a jittered frame without a plan: the next implementation draws it
    if (!temporalKind && !support.spatial)
        return false;  // a GPU with the temporal scaler only: the next implementation draws this frame
    if (temporalKind && (!assets || !assets->white())) return false;
    if (temporalKind && !mfxPrep.ready()) return metalfx_fail("the input preparation shader did not compile.");

    render::metalfx::Desc d;
    d.kind = temporalKind ? Kind::Temporal : Kind::Spatial;
    d.inputWidth = in.renderW;
    d.inputHeight = in.renderH;
    d.outputWidth = in.outW;
    d.outputHeight = in.outH;
    d.colorFormat = src.format.color;
    d.outputFormat = out.format.color;
    // Spatial: linear light above 1 in a float scene, linear light in a smaller one, else display values.
    d.colorSpace = !in.linear                                   ? render::metalfx::ColorSpace::Perceptual
                   : src.format.color == SG_PIXELFORMAT_RGBA16F ? render::metalfx::ColorSpace::Hdr
                                                                : render::metalfx::ColorSpace::Linear;
    d.depthFormat = SG_PIXELFORMAT_R32F;
    d.motionFormat = SG_PIXELFORMAT_RG16F;
    d.autoExposure = false;  // the scene colour is exposed before the stage: pre-exposure 1
    std::string error;
    if (mfxForceCreateFail) return metalfx_fail("MetalFX creation was refused (test hook).");
    if (!mfxScaler.configure(d, &error)) return metalfx_fail(error);

    render::metalfx::Frame f;
    f.color = src.texture_image();
    f.output = out.color;
    if (temporalKind) {
        const Target* prepass = upscalePrepass.target(c);
        const Target* velocity = upscaleVelocity.target(c);
        if (prepass && (prepass->w != in.renderW || prepass->h != in.renderH))
            prepass = nullptr;  // not the picture's size: every pixel is sky
        if (velocity && (velocity->w != in.renderW || velocity->h != in.renderH)) velocity = nullptr;
        if (!ensure_mfx_target(mfxDepth, "mfx-depth", SG_PIXELFORMAT_R32F, in.renderW, in.renderH) ||
            !ensure_mfx_target(mfxMotion, "mfx-motion", SG_PIXELFORMAT_RG16F, in.renderW, in.renderH))
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
        p.colorLoad = SG_LOADACTION_DONTCARE;  // every pixel of both images is drawn
        p.colorStore = SG_STOREACTION_STORE;
        gpu.begin_pass(p);
        sg_apply_pipeline(mfxPrep.pipeline(p.format));
        sg_bindings b{};
        b.vertex_buffers[0] = gpu.fullscreen_triangle();
        b.views[VIEW_upscale_mfx_tex_p] = prepass ? prepass->texView : assets->white()->view;
        b.views[VIEW_upscale_mfx_tex_v] = velocity ? velocity->texView : assets->white()->view;
        b.samplers[SMP_upscale_mfx_smp_pt] = gpu.sampler(SamplerKind::Nearest);
        sg_apply_bindings(&b);
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
        apply_uniforms(UB_upscale_mfx_mfx_params, u);
        sg_draw(0, 3, 1);
        gpu.end_pass();
        ++stats.drawCalls;

        f.depth = mfxDepth.color;
        f.motion = mfxMotion.color;
        // The picture was drawn moved by the jitter (right and down); the motion image is in UV units, MetalFX scales it to render pixels.
        f.jitterX = upscaleTaa.jitterPx.x * mfxJitterSign;
        f.jitterY = upscaleTaa.jitterPx.y * mfxJitterSign;
        f.motionScaleX = float(in.renderW);
        f.motionScaleY = float(in.renderH);
        f.reset = !histValid;
        mfxLastReset = f.reset || mfxScaler.encoded() == 0;
        mfxLastSerial = upscaleTaa.serial;
        mfxLastScene = upscaleTaa.sceneKey;
        mfxLastShifts = upscaleTaa.originShifts;
        mfxLastConfig = config;
    }
    // Encode splits the frame (sg_commit): the passes recorded so far, which wrote the picture, go first.
    if (!mfxScaler.encode(f, &error)) return metalfx_fail(error);
    mfxLastWrote = temporalKind;
    ++stats.drawCalls;  // the scaler's own pass
    return true;
}

}  // namespace fa
