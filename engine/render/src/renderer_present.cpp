// Renderer: present() and the captures of the finished frame.
#include "renderer_impl.h"

namespace fa {

void Renderer::present(const GfxSwapchain& swapchain, int fbW, int fbH, ScaleMode mode) {
    if (!initialized()) return;
    Impl& im = *impl_;
    const sg_swapchain& sc = swapchain.get();
    im.scaleMode = mode;
    Viewport vp = compute_viewport(mode, fbW, fbH, im.targetW, im.targetH);
    PassDesc pass = PassDesc::for_swapchain(sc);
    pass.label = "present";
    pass.colorLoad = SG_LOADACTION_CLEAR;  // the letterbox bars
    pass.clearColor = {0, 0, 0, 1};
    pass.colorStore = SG_STOREACTION_STORE;
    pass.depthLoad = SG_LOADACTION_CLEAR;  // what sokol did for the pass it was given (SG_LOADACTION_DEFAULT is CLEAR)
    pass.stencilLoad = SG_LOADACTION_CLEAR;
    im.gpu.begin_pass(pass);
    sg_apply_viewportf(vp.x, vp.y, vp.w, vp.h, true);
    sg_apply_pipeline(im.gpu.blit_pipeline(pass.format));
    sg_bindings b{};
    b.vertex_buffers[0] = im.gpu.fullscreen_triangle();
    b.views[VIEW_blit_tex] = im.final_view();
    bool integer = mode == ScaleMode::PixelPerfect || std::fabs(vp.scale - std::round(vp.scale)) < 1e-3f;
    b.samplers[SMP_blit_smp] = im.gpu.sampler(integer ? SamplerKind::Nearest : SamplerKind::Linear);
    sg_apply_bindings(&b);
    blit_blit_vs_params_t u{};
    u.flip[0] = im.gpu.is_gl() ? 1.0f : 0.0f;
    apply_uniforms(UB_blit_blit_vs_params, u);
    sg_draw(0, 3, 1);
    im.gpu.end_pass();
    sg_commit();
    im.gpu.note_commit();
    im.inFrame = false;
}

bool Renderer::capture(Image& out, std::string* error) {
    if (!initialized()) {
        if (error) *error = "Renderer is not initialized";
        return false;
    }
    Impl& im = *impl_;
    // A read-back waits for the GPU. On Metal sokol's command buffer of the frame is already queued but only submitted by
    // sg_commit(): a read-back behind it waits forever. The editor commits once per UI frame, after the game is drawn, so a
    // screenshot taken in between (the toolbar button, a Play mark, game.screenshot) submits the game's work itself. Always
    // outside a pass: the game pass is closed when drawing returns.
    if (!im.gpu.committed()) {
        sg_commit();
        im.gpu.note_commit();
    }
    sg_image img = im.final_image();
    std::vector<std::uint8_t> px;
    if (!im.read_rgba8(img, im.final_view(), im.physW, im.physH, px, error)) return false;
    out.width = im.physW;
    out.height = im.physH;
    out.rgba = std::move(px);
    return true;
}

bool Renderer::capture_fitted(Image& out, int width, int height, bool stretch, std::string* error) {
    if (width < 1 || height < 1) {
        if (error) *error = "capture: the size must be at least 1 x 1";
        return false;
    }
    Image full;
    if (!capture(full, error)) return false;
    out = stretch ? resize_image(full, width, height) : cover_image(full, width, height);
    return true;
}

bool Renderer::capture_world(World& world, const WorldCapture& spec, Image& out, std::string* error) {
    auto fail = [&](std::string message) {
        if (error) *error = std::move(message);
        return false;
    };
    if (!initialized()) return fail("Renderer is not initialized");
    Impl& im = *impl_;
    const Rect& r = spec.rect;
    if (!std::isfinite(r.x) || !std::isfinite(r.y) || !std::isfinite(r.w) || !std::isfinite(r.h) || !(r.w > 0.0f) ||
        !(r.h > 0.0f))
        return fail(
            "the rectangle [" + std::to_string(r.x) + ", " + std::to_string(r.y) + ", " + std::to_string(r.w) + ", " +
            std::to_string(r.h) +
            "] is empty or not a number. Pass [x, y, width, height] in world units with a positive width and height");
    if (!std::isfinite(spec.scale) || !(spec.scale > 0.0f))
        return fail("scale must be a number above 0 (pixels per world unit), but got " + std::to_string(spec.scale));
    const double pw = std::ceil(double(r.w) * double(spec.scale) - 1e-4),
                 ph = std::ceil(double(r.h) * double(spec.scale) - 1e-4);
    if (pw > kMaxWorldCaptureSide || ph > kMaxWorldCaptureSide)
        return fail("the picture would be " + std::to_string(std::llround(pw)) + " x " +
                    std::to_string(std::llround(ph)) + " pixels (" + std::to_string(r.w) + " x " + std::to_string(r.h) +
                    " world units at scale " + std::to_string(spec.scale) + "), more than the " +
                    std::to_string(kMaxWorldCaptureSide) +
                    " a side a texture may have. Use a smaller scale or a smaller rectangle");
    const int w = std::max(1, int(pw)), h = std::max(1, int(ph));

    // The camera: orthographic, centred on the rect, showing exactly w x h pixels at `scale` pixels per unit.
    CameraInfo ci;
    const float cx = r.x + r.w * 0.5f, cy = r.y + r.h * 0.5f;
    ci.halfW = float(w) / (2.0f * spec.scale);
    ci.halfH = float(h) / (2.0f * spec.scale);
    ci.pixelsPerUnit = spec.scale;
    ci.position = Vec3{cx, cy, 0.0f};
    ci.view = Mat4::identity();
    ci.view.at(3, 0) = -cx;
    ci.view.at(3, 1) = -cy;
    ci.proj = Mat4::ortho(-ci.halfW, ci.halfW, -ci.halfH, ci.halfH, -1000.0f, 1000.0f, im.gpu.depth_zero_to_one());
    ci.viewProj = ci.proj * ci.view;
    ci.invViewProj = ci.viewProj.inverse();
    ci.visible = Rect{cx - ci.halfW, cy - ci.halfH, ci.halfW * 2.0f, ci.halfH * 2.0f};
    ci.clear = true;
    ci.clearColor = Color{0, 0, 0, 0};

    const RenderStats savedStats = im.stats;
    im.targetSelf.clear();
    im.ramps.begin_frame();
    Frame fr;
    for (int attempt = 0; attempt < 2; ++attempt) {
        const unsigned atlasEpoch = im.fonts->atlas_epoch();
        fr = Frame{};
        fr.cam = ci;
        fr.wantWorld = true;
        fr.wantScreen = false;
        fr.scopeRoot = spec.subject;
        im.setup_frame(fr, world, 0.0f);
        fr.targetW = w;
        fr.targetH = h;
        fr.renderScale = spec.scale;
        apply_sprite_frames(world, fr);
        gather_2d(world, fr);
        gather_particles(world, fr);
        if (im.fonts->atlas_epoch() == atlasEpoch) break;  // else the atlas was remade halfway: gather again
    }
    // gather_2d shifted the layers for the capture's own camera: put back the shift for the scene's first camera. A renderer that
    // has not drawn or updated yet has no cameras collected, so look them up (collect_cameras always returns at least one).
    {
        std::vector<CameraInfo> fresh;
        if (im.lastCams.empty()) fresh = im.collect_cameras(world);
        const std::vector<CameraInfo>& sceneCams = im.lastCams.empty() ? fresh : im.lastCams;
        if (!sceneCams.empty()) update_parallax(world, sceneCams.front().position.xy());
    }
    im.fonts->sync();
    im.ramps.sync();

    constexpr std::uint64_t kKey =
        1ull << 62;  // not a CameraView widget (entity bits) and not a render target (bit 63)
    TextureAsset* tex = im.view_image(kKey, w, h);
    if (!tex)
        return fail("the " + std::to_string(w) + " x " + std::to_string(h) +
                    " image could not be created (out of GPU memory?)");
    im.gpu.begin_frame();
    im.transient_targets().pool.begin_frame();
    // One job in a frame graph of its own; gather_meshes builds the scene of fr.scopeRoot (the subject).
    im.begin_frame_graph();
    Impl::JobPlan plan;
    plan.name = "capture";
    im.plan_view_job(world, fr, *im.viewTargets[kKey], kKey, plan);
    im.run_frame_graph();
    im.renderScene.reset();
    // Read-back waits for the GPU, and on Metal the work is only submitted by sg_commit (see capture()).
    sg_commit();
    im.gpu.note_commit();
    const Impl::ViewTarget& vt = *im.viewTargets[kKey];
    std::vector<std::uint8_t> px;
    std::string readError;
    const bool ok = im.read_rgba8(vt.asset.image, vt.asset.view, w, h, px, &readError);
    im.release_view(*im.viewTargets[kKey]);
    im.viewTargets.erase(kKey);
    // The RGBA8 copy of a big picture (a 4K capture is 64 MB) is not worth keeping: only the game target's size is asked for again.
    if (im.readW != im.physW || im.readH != im.physH) im.free_read_image();
    im.stats = savedStats;
    if (!ok) return fail("reading the picture back from the GPU failed: " + readError);
    // The pass blended onto a transparent background, so the colour is premultiplied by alpha; texture fields expect straight alpha.
    for (std::size_t i = 0; i + 3 < px.size(); i += 4) {
        const unsigned a = px[i + 3];
        if (a == 0 || a == 255) continue;
        for (int c = 0; c < 3; ++c)
            px[i + std::size_t(c)] =
                std::uint8_t(std::min(255u, (unsigned(px[i + std::size_t(c)]) * 255u + a / 2) / a));
    }
    out.width = w;
    out.height = h;
    out.rgba = std::move(px);
    return true;
}

}  // namespace fa
