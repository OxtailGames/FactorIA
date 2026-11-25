// Renderer's frame-generation API (renderer.h, "frame generation"; render_framegen.h): the setting, its status and readout, and the two passes
// of the output stage that feed a provider (the hudless copy and the dispatch).
#include <array>
#include <cmath>

#include "fa/core/log.h"

#include "fullscreen_gpu.h"
#include "renderer_impl.h"

namespace fa {

namespace {

double round3(double v) { return std::round(v * 1000.0) / 1000.0; }

const render::FrameGenSettings& no_frame_generation() {
    static const render::FrameGenSettings off;
    return off;
}

constexpr render::FrameGenSlot kProviderSlots[3] = {render::FrameGenSlot::Dlss, render::FrameGenSlot::Fsr,
                                                    render::FrameGenSlot::Xess};

}  // namespace

void Renderer::Impl::set_framegen_env(render::FeatureEnv& env) {
    std::array<render::VendorProbe, 3> answers;
    std::size_t i = 0;
    for (const render::FrameGenSlot s : kProviderSlots) {
        const std::string why = framegen.provider_reason(s);
        answers[i].available = why.empty();
        answers[i].reason = why;
        ++i;
    }
    render::set_framegen_env(env, answers);
}

void Renderer::set_frame_generation(const render::FrameGenSettings& settings) {
    if (!initialized()) return;
    impl_->framegen.set_settings(settings);
    impl_->sync_reflex_for_framegen();
    impl_->sync_framegen_latency();
}

void Renderer::Impl::sync_reflex_for_framegen() { latency.require_reflex(framegen.requires_reflex()); }

const render::FrameGenSettings& Renderer::frame_generation() const {
    return initialized() ? impl_->framegen.settings() : no_frame_generation();
}

render::FrameGenSlot Renderer::effective_frame_generation() const {
    return initialized() ? impl_->framegen.provider() : render::FrameGenSlot::None;
}

Json Renderer::frame_generation_status() {
    Json j = Json::object();
    const render::FrameGenSettings s = frame_generation();
    j["mode"] = std::string(render::frame_gen_mode_name(s.mode));
    j["minBaseFps"] = s.minBaseFps;
    Json modes = Json::object();
    std::string provider = "none", state = "off", reason;
    if (initialized()) {
        render::FrameGenController& fc = impl_->framegen;
        provider = std::string(render::frame_gen_slot_name(fc.provider()));
        state = std::string(render::frame_gen_state_name(fc.state()));
        reason = fc.reason();
        for (const render::FrameGenSlot slot : kProviderSlots) {
            const std::string why = fc.provider_reason(slot);
            Json m = Json::object();
            m["available"] = why.empty();
            m["reason"] = why;
            m["setupId"] = std::string(render::framegen_slot_setup_id(slot));
            modes[std::string(render::frame_gen_slot_name(slot))] = std::move(m);
        }
    }
    j["provider"] = provider;
    j["state"] = state;
    j["reason"] = reason;
    j["modes"] = std::move(modes);
    return j;
}

Json Renderer::frame_generation_report() {
    Json j = Json::object();
    if (!initialized()) return j;
    const render::FrameGenReport r = impl_->framegen.report();
    j["provider"] = std::string(render::frame_gen_slot_name(r.provider));
    j["state"] = std::string(render::frame_gen_state_name(r.state));
    j["generating"] = r.generating;
    j["baseFps"] = round3(r.baseFps);
    j["presentedFps"] = round3(r.presentedFps);
    j["renderedFrames"] = r.renderedFrames;
    j["generatedFrames"] = r.generatedFrames;
    j["reason"] = r.reason;
    return j;
}

// A copy of the output picture before the screen-space items are drawn over it (the "hudless" image the provider generates from): the items go
// into the same image, so this pass runs between the upscale and "hud-over-upscale". With the colour filter on (`grade`) the copy is drawn
// through the same filter pass the picture shown goes through, so both images the provider gets are graded alike.
void Renderer::Impl::framegen_hudless_copy(const PassContext& c, const PostPlan* grade) {
    outputPassLog.push_back(render::kPassFrameGenHudless);
    if (!hudlessTarget.valid(gpu.device()) || !outTarget.valid(gpu.device())) return;
    if (grade) {
        post_pass(*grade, false, grade->colorFilter, false, outTarget.texView, assets->white()->view, gpu::View{},
                  hudlessTarget, "framegen-hudless", false);
        return;
    }
    PassDesc p = pass_into(hudlessTarget, "framegen-hudless");
    p.colorLoad = gpu::LoadAction::DontCare;  // every pixel is drawn
    p.colorStore = gpu::StoreAction::Store;
    gpu::CommandList& list = pass_list(c, gpu);
    list.begin_pass(p);
    list.set_pipeline(gpu.blit_keep_pipeline(p.format));
    gpu::Bindings b;
    b.vertexBuffers[0] = gpu.fullscreen_triangle();
    b.views[VIEW_blit_tex] = outTarget.texView;
    b.samplers[SMP_blit_smp] = gpu.sampler(SamplerKind::Nearest);  // same size: a copy
    list.set_bindings(b);
    blit_blit_vs_params_t u{};
    u.flip[0] = gpu.is_gl() ? 1.0f : 0.0f;  // between two render targets the storage layout is kept
    list.set_uniforms(UB_blit_blit_vs_params, gpu::Range{&u, sizeof(u)});
    blit_blit_fs_params_t fu{};  // encode 0: copied as it is
    list.set_uniforms(UB_blit_blit_fs_params, gpu::Range{&fu, sizeof(fu)});
    list.draw(0, 3, 1);
    list.end_pass();
    ++stats.drawCalls;
}

// The provider's frame: the pictures of the output stage, the depth and the motion of the temporal upscaler (made by its preparation pass when the
// upscaler did not make them this frame: the engine's own temporal upscaler does not need them), the camera and the jitter.
void Renderer::Impl::framegen_pass(const render::FrameGenPassPlan& plan, bool filtered, const PassContext& c) {
    outputPassLog.push_back(render::kPassFrameGen);
    if (!plan.dispatch || !framegen.wants_dispatch() || !gpu.has_device()) return;
    const Target& src = scene_target();
    const Target& shown = filtered ? outFilterTarget : outTarget;  // the image the swapchain shows
    if (!shown.valid(gpu.device()) || !src.valid(gpu.device())) return;
    if (plan.copyHudless && !hudlessTarget.valid(gpu.device())) {
        framegen.note_skipped("the picture before the screen-space items could not be copied.");
        return;
    }
    // The depth the provider reads: the reversed infinite one when it asks for it (the upscaler's own pass may have made the other kind).
    const bool reversed = framegen.wants_reversed_depth();
    const float reversedNear = reversed ? fgCamera.nearPlane : 0.0f;
    if (prepSerial != upscaleTaa.serial || prepReversed != reversed) {
        if (!assets || !assets->white() || !mfxPrep.ready(gpu.device())) {
            framegen.note_skipped("the depth and motion preparation shader did not compile.");
            return;
        }
        render::UpscaleInput in;
        in.renderW = src.w;
        in.renderH = src.h;
        if (!run_upscale_prep(in, c, upscalePrepass.target(c), upscaleVelocity.target(c), upscaleTaa.prevValid,
                              reversedNear)) {
            framegen.note_skipped("the depth and motion images of the render size could not be made.");
            return;
        }
    }
    render::FrameGenFrame f;
    f.device = &gpu.device();
    f.list = &pass_list(c, gpu);
    f.hudless = plan.copyHudless ? hudlessTarget.texture_image() : shown.texture_image();
    f.presented = shown.texture_image();
    f.hudDrawn = plan.copyHudless;
    f.depth = mfxDepth.color;
    f.motion = mfxMotion.color;
    f.colorFormat = shown.format.color;
    f.renderW = src.w;
    f.renderH = src.h;
    f.outW = shown.w;
    f.outH = shown.h;
    for (int i = 0; i < 8; ++i) f.proj[i] = upscaleTaa.proj[i];
    f.prevFromView = upscaleTaa.prevFromView;
    f.jitterX = upscaleTaa.jitterPx.x;
    f.jitterY = upscaleTaa.jitterPx.y;
    const float p11 = upscaleTaa.proj[1];
    f.cameraPerspective = fgCamera.perspective;
    f.cameraFovY = fgCamera.perspective && p11 > 1e-4f ? 2.0f * std::atan(1.0f / p11)
                                                       : 1.0f;  // an orthographic lens: a nominal one
    f.cameraNear = fgCamera.perspective ? fgCamera.nearPlane : -1000.0f;
    f.cameraFar = fgCamera.perspective ? fgCamera.farPlane : 1000.0f;
    f.cameraPosition = fgCamera.position;
    f.cameraRight = fgCamera.right;
    f.cameraUp = fgCamera.up;
    f.cameraForward = fgCamera.forward;
    f.viewFromWorld = fgCamera.view;
    f.depthReversed = reversed;
    f.depthInfinite = reversed;
    f.exposure = 1.0f;
    f.outputEncode = frameOutput.encode;
    f.hdrHeadroom = frameOutput.headroom;
    f.paperWhiteNits = frameOutput.paperWhiteNits;
    f.frameTimeMs = frameDt * 1000.0f;
    f.frameId = upscaleTaa.serial;
    f.reset = !upscaleTaa.prevValid;
    if (framegen.dispatch(f)) {
        ++stats.drawCalls;  // the provider's own pass
    } else {
        sync_framegen_latency();  // a provider that failed for good (XeSS) is stopped: XeLL need not run for it any more
    }
}

// Intel XeSS frame generation cannot run without XeLL (it is told XeLL's context before it makes the swapchain): while it is the provider
// that runs, the latency controller runs XeLL whatever render.latency says.
void Renderer::Impl::sync_framegen_latency() {
    latency.require_driver(framegen.provider() == render::FrameGenSlot::Xess ? render::LatencyDriver::Xell
                                                                             : render::LatencyDriver::None);
}

}  // namespace fa
