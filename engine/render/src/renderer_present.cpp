// Renderer: present() and the captures of the finished frame.
#include "renderer_impl.h"

#include "gpu/sokol_context.h"

namespace fa {

blit_blit_fs_params_t Renderer::Impl::present_params() const {
    blit_blit_fs_params_t fu{};
    // A linear scene without the final pass holds linear light: the copy encodes it (sRGB) or reads it as it is (HDR). After the
    // final pass the picture holds sRGB-encoded display values (extended past 1 when it went above paper white).
    fu.encode[0] = gpu.linear() && !finalEncoded ? 1.0f : 0.0f;
    // The encode for the swapchain the window has NOW (update_output() may have switched it after the frame was drawn).
    const render::OutputTarget now = render::select_output(output(), float_display());
    fu.hdr[0] = float(int(now.encode));
    fu.hdr[1] = frameAboveWhite ? std::clamp(frameOutput.headroom, 1.0f, render::kMaxHeadroom) : 1.0f;
    fu.hdr[2] = now.paperWhiteNits / 80.0f;
    fu.hdr[3] = now.paperWhiteNits / 10000.0f;
    return fu;
}

bool Renderer::Impl::read_floats(bool present, std::vector<float>& out, std::string* error) {
    if (!gpu.committed()) {  // see Renderer::capture(): the frame's work must be submitted before a read-back waits for it
        gpu.commit_frame();
        gpu.note_commit();
    }
    const gpu::PixelFormatCaps half = gpu.device().pixel_format_caps(gpu::PixelFormat::Rgba16F);
    if (!half.render) {
        if (error) *error = "this GPU cannot draw into an RGBA16F image";
        return false;
    }
    const int fw = final_w(),
              fh = final_h();  // the finished picture's size (the output size while the upscale stage ran)
    if (floatTarget.color.id && (floatTarget.w != fw || floatTarget.h != fh)) destroy_target(gpu.device(), floatTarget);
    if (!floatTarget.color.id) {
        TargetDesc d;
        d.label = "readback-rgba16f";
        d.width = fw;
        d.height = fh;
        d.colorFormat = gpu::PixelFormat::Rgba16F;
        floatTarget = make_target(gpu.device(), d);
        if (!floatTarget.valid(gpu.device())) {
            destroy_target(gpu.device(), floatTarget);
            if (error) *error = std::format("the {}x{} RGBA16F image for the read-back could not be created", fw, fh);
            return false;
        }
    }
    PassDesc p = pass_into(floatTarget, "readback-rgba16f");
    p.colorLoad = gpu::LoadAction::DontCare;  // every pixel is drawn
    p.colorStore = gpu::StoreAction::Store;
    gpu::CommandList& list = gpu.commands();
    list.begin_pass(p);
    list.set_pipeline(present ? gpu.blit_pipeline(p.format) : gpu.blit_keep_pipeline(p.format));
    gpu::Bindings b;
    b.vertexBuffers[0] = gpu.fullscreen_triangle();
    b.views[VIEW_blit_tex] = final_view();
    b.samplers[SMP_blit_smp] = gpu.sampler(SamplerKind::Nearest);
    list.set_bindings(b);
    blit_blit_vs_params_t u{};
    u.flip[0] = gpu.is_gl() ? 1.0f : 0.0f;  // as read_rgba8: the per-backend read-back turns GL's rows top-down
    list.set_uniforms(UB_blit_blit_vs_params, gpu::Range{&u, sizeof(u)});
    const blit_blit_fs_params_t fu = present ? present_params() : blit_blit_fs_params_t{};
    list.set_uniforms(UB_blit_blit_fs_params, gpu::Range{&fu, sizeof(fu)});
    list.draw(0, 3, 1);
    list.end_pass();
    gpu.commit_frame();
    gpu.note_commit();
    return render::result_ok(gpu.device().read_image_rgba16f(floatTarget.color, fw, fh, out), error);
}

void Renderer::present(const GfxSwapchain& swapchain, int fbW, int fbH, ScaleMode mode) {
    if (!initialized()) return;
    Impl& im = *impl_;
    gpu::Device& device = im.gpu.device();
    // A window that came back (Renderer::set_native_window), or a swapchain the device lost: made again on the window,
    // at this frame's size. Without one there is no image to draw into: the frame ends here, not shown.
    if (im.windowManaged && !device.has_swapchain()) {
        if (im.windowDesc.nativeWindow && !im.windowRemakeFailed) {
            gpu::SwapchainDesc sd = im.windowDesc;
            sd.width = std::max(0, fbW);
            sd.height = std::max(0, fbH);
            if (auto made = device.create_swapchain(sd); !made) {
                FA_ERROR("render", "Renderer::present: the window's swapchain could not be made again: {}",
                         made.error().to_string());
                im.windowRemakeFailed = true;  // said once; the next window tries again
            } else {
                im.swapW = sd.width;
                im.swapH = sd.height;
                im.resizeFailed = false;
                im.presentFailed = false;
                im.framegen.set_swapchain(render::FrameGenSwapchain{device.backend(), sd.width, sd.height, sd.vsync});
                FA_INFO("render", "Renderer::present: the window's swapchain was made again ({}x{})", sd.width,
                        sd.height);
            }
        }
        if (!device.has_swapchain()) {
            im.gpu.commit_frame();
            im.gpu.note_commit();
            im.inFrame = false;
            return;
        }
    }
    // A new framebuffer size resizes the swapchain before the next acquire (gpu/device.h, "the window: swapchain and
    // present"): D3D12 resizes its own buffers, the sokol devices only record it (sokol_app resized the window's).
    if (device.has_swapchain() && fbW > 0 && fbH > 0 && (fbW != im.swapW || fbH != im.swapH)) {
        if (auto resized = device.resize_swapchain(fbW, fbH); !resized) {
            if (!im.resizeFailed) FA_ERROR("render", "Renderer::present: {}", resized.error().to_string());
            im.resizeFailed = true;  // said once; the size is not stored, so the next frame tries again
        } else {
            im.resizeFailed = false;
            im.swapW = fbW;
            im.swapH = fbH;
            im.framegen.set_swapchain(render::FrameGenSwapchain{device.backend(), fbW, fbH, im.windowDesc.vsync});
        }
    }
    // The frame's work is done and what follows only waits: the acquire blocks on the display (D3D12 waits for the swapchain's frame-latency
    // object), so PresentStart is marked before it, or the engine's own pacing and the SDK would count that wait as work.
    im.latency.mark(render::LatencyMarker::PresentStart);
    // The image of the window to draw into: on the sokol devices the frame's surface as sokol_app gave it.
    auto acquired = device.acquire_swapchain(gpu::swapchain_of(swapchain));
    if (!acquired) {
        if (!im.presentFailed) FA_ERROR("render", "Renderer::present: {}", acquired.error().to_string());
        im.presentFailed = true;  // said once
        im.inFrame = false;
        return;
    }
    const gpu::Swapchain sc = acquired.value();
    im.scaleMode = mode;
    Viewport vp = compute_viewport(mode, fbW, fbH, im.targetW, im.targetH);
    PassDesc pass = PassDesc::for_swapchain(sc, device.environment_defaults());
    pass.label = "present";
    pass.colorLoad = gpu::LoadAction::Clear;  // the letterbox bars
    pass.clearColor = {0, 0, 0, 1};
    pass.colorStore = gpu::StoreAction::Store;
    pass.depthLoad = gpu::LoadAction::Clear;  // what sokol did for the pass it was given (a default load action clears)
    pass.stencilLoad = gpu::LoadAction::Clear;
    gpu::CommandList& list = im.gpu.commands();
    list.begin_pass(pass);
    list.set_viewport_f(vp.x, vp.y, vp.w, vp.h, true);
    list.set_pipeline(im.gpu.blit_pipeline(pass.format));
    gpu::Bindings b;
    b.vertexBuffers[0] = im.gpu.fullscreen_triangle();
    b.views[VIEW_blit_tex] = im.final_view();
    bool integer = mode == ScaleMode::PixelPerfect || std::fabs(vp.scale - std::round(vp.scale)) < 1e-3f;
    b.samplers[SMP_blit_smp] = im.gpu.sampler(integer ? SamplerKind::Nearest : SamplerKind::Linear);
    list.set_bindings(b);
    blit_blit_vs_params_t u{};
    u.flip[0] = im.gpu.is_gl() ? 1.0f : 0.0f;
    list.set_uniforms(UB_blit_blit_vs_params, gpu::Range{&u, sizeof(u)});
    // The encode for the window's output (hdr_encode.h): sRGB within white, or scRGB, HDR10 (PQ) or EDR linear light.
    const blit_blit_fs_params_t fu = im.present_params();
    list.set_uniforms(UB_blit_blit_fs_params, gpu::Range{&fu, sizeof(fu)});
    list.draw(0, 3, 1);
    list.end_pass();
    im.gpu.commit_frame();
    im.gpu.note_commit();
    im.latency.mark(render::LatencyMarker::RenderSubmitEnd);
    if (auto shown = device.present(); !shown) {
        if (!im.presentFailed) FA_ERROR("render", "Renderer::present: {}", shown.error().to_string());
        im.presentFailed = true;
    }
    im.latency.mark(render::LatencyMarker::PresentEnd);
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
        im.gpu.commit_frame();
        im.gpu.note_commit();
    }
    // 8 bits: a frame drawn for an HDR output (the HDR tonemap, values above paper white) is clipped at white here, not drawn again
    // with the SDR curve (docs/RENDERING.md, "What goes above white").
    gpu::Image img = im.final_image();
    std::vector<std::uint8_t> px;
    const int w = im.final_w(), h = im.final_h();  // the output size when the upscale stage ran, else the render size
    if (!im.read_rgba8(img, im.final_view(), w, h, px, error, false, im.finalEncoded)) return false;
    out.width = w;
    out.height = h;
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
    im.watch_world_if_free(world);  // a capture before the first frame still follows the world's floating origin
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
    ci.drawProj = ci.proj;  // never jittered (M76)
    ci.drawViewProj = ci.viewProj;
    ci.drawInvViewProj = ci.invViewProj;
    ci.visible = Rect{cx - ci.halfW, cy - ci.halfH, ci.halfW * 2.0f, ci.halfH * 2.0f};
    ci.clear = true;
    ci.clearColor = Color{0, 0, 0, 0};
    ci.areaCulling = false;  // a picture of a rectangle of the world (seen from outside): every room in it is drawn
    return im.capture_view(world, std::move(ci), w, h, spec.scale, spec.subject, 1, false, 0, true, out, error);
}

// The histories of a capture are kept under the camera's bits with this bit set: the game's cameras (their bits alone,
// and bit 0 would be "every history" to reset_history) never share a history with a capture of a camera of another
// world, or of the same one.
static constexpr std::uint64_t kCaptureHistoryBit = 1ull << 62;

bool Renderer::capture_camera(World& world, const CameraCapture& spec, Image& out, std::string* error) {
    auto fail = [&](std::string message) {
        if (error) *error = std::move(message);
        return false;
    };
    if (!initialized()) return fail("Renderer is not initialized");
    Impl& im = *impl_;
    im.watch_world_if_free(world);
    if (!world.alive(spec.camera) || !world.get<Camera>(spec.camera))
        return fail("the entity is not a Camera of this world: pass an entity that has a Camera component");
    if (spec.width < 1 || spec.height < 1 || spec.width > kMaxWorldCaptureSide || spec.height > kMaxWorldCaptureSide)
        return fail("the picture would be " + std::to_string(spec.width) + " x " + std::to_string(spec.height) +
                    " pixels; each side must be between 1 and " + std::to_string(kMaxWorldCaptureSide));
    if (spec.frames < 1 || spec.frames > kMaxCaptureFrames)
        return fail("frames must be between 1 and " + std::to_string(kMaxCaptureFrames) + ", but got " +
                    std::to_string(spec.frames));
    // The camera as a render target draws it (it fills the image whatever its viewport says), with its stack even when
    // the editor's A/B switch (set_post_bypass) has the game's off: this picture is what the stack does.
    const Vec2 size{float(spec.width), float(spec.height)};
    const bool bypass = im.postBypass;
    im.postBypass = false;
    CameraInfo ci = im.build_camera(world, spec.camera, &size, true);
    im.postBypass = bypass;
    const bool custom = ci.postStack && ci.postStack->has_custom();
    return im.capture_view(world, std::move(ci), spec.width, spec.height, 1.0f, kNullEntity, custom ? spec.frames : 1,
                           custom, kCaptureHistoryBit | spec.camera.bits(), false, out, error);
}

bool Renderer::Impl::capture_view(World& world, CameraInfo ci, int w, int h, float scale, Entity subject, int frames,
                                  bool withCustom, std::uint64_t historyCamera, bool premultiplied, Image& out,
                                  std::string* error) {
    auto fail = [&](std::string message) {
        if (error) *error = std::move(message);
        return false;
    };
    sync_color_space(world);  // the picture is made in the world's colour space
    portalGather.valid =
        false;  // the world may have changed since the frame: the capture gathers its rooms again, and drops them

    settle_pass_times();  // the capture replaces the frame graph that the last frame's pass times are read from
    const RenderStats savedStats = stats;
    // What render.occlusion and the debug views report is the frame's, not the capture's (the capture's culling adds to them).
    const HizShown savedHizShown = hizShown;
    const OcclusionShown savedOcclusionShown = occlusionShown;
    const std::vector<const MaterialAsset*> savedMaterialsCounted = materialsCounted;
    const std::uint32_t savedMaterialResolves = assets->material_resolves();
    auto restore = [&]() {
        stats = savedStats;
        hizShown = savedHizShown;
        occlusionShown = savedOcclusionShown;
        materialsCounted = savedMaterialsCounted;
        assets->set_material_resolves(savedMaterialResolves);
        assets->drop_material_cache();  // the capture's lookups are not the next frame's
    };
    set_target_self({});
    // The passes that keep a history start clean, so the same world always gives the same picture.
    if (withCustom) customPost.reset_history(historyCamera);
    constexpr std::uint64_t kKey =
        1ull << 62;  // not a CameraView widget (entity bits) and not a render target (bit 63)
    // The one way out of the capture, whether it failed or finished: the stats are put back, the capture's image is
    // dropped, and its history slots are freed by key now (they are not the game's to pay for until they idle out).
    auto cleanup = [&]() {
        restore();
        viewTargets.erase(kKey);
        if (withCustom) customPost.release_history_of(historyCamera);
        portalGather.valid = false;
    };
    for (int frame = 0; frame < frames; ++frame) {
        ramps.begin_frame();
        Frame fr;
        for (int attempt = 0; attempt < 2; ++attempt) {
            const unsigned atlasEpoch = fonts->atlas_epoch();
            fr = Frame{};
            fr.cam = ci;
            fr.wantWorld = true;
            fr.wantScreen = false;
            fr.scopeRoot = subject;
            setup_frame(fr, world, 0.0f);
            fr.targetW = w;
            fr.targetH = h;
            fr.renderScale = fr.screenScale = scale;
            apply_sprite_frames(world, fr);
            assets->drop_material_cache();  // this world's components are not the ones the last frame asked about
            gather_2d(world, fr);
            gather_particles(world, fr);
            if (fonts->atlas_epoch() == atlasEpoch) break;  // else the atlas was remade halfway: gather again
        }
        // gather_2d shifted the layers for the capture's own camera: put back the shift for the scene's first camera
        // (its real pose). A renderer that has not drawn or updated yet has no cameras collected, so look them up
        // (collect_cameras always returns at least one).
        if (lastCams.empty())
            update_parallax(world, collect_cameras(world, false).front().position.xy());
        else
            update_parallax(world, logic_camera_xy());
        fonts->sync();
        ramps.sync(gpu.device());

        TextureAsset* tex = view_image(kKey, w, h);
        if (!tex) {
            cleanup();
            return fail("the " + std::to_string(w) + " x " + std::to_string(h) +
                        " image could not be created (out of GPU memory?)");
        }
        gpu.begin_frame();
        transient_targets().pool.begin_frame();
        // One job in a frame graph of its own; gather_meshes builds the scene of fr.scopeRoot (the subject).
        begin_frame_graph(false);
        JobPlan plan;
        plan.name = "capture";
        plan.customPost = withCustom;
        if (plan.customPost) {
            // A history is valid when the frame before it was drawn right before, by this capture: the serial counts
            // every frame of every capture, the first frame of a capture has none before it.
            plan.history.camera = historyCamera;
            plan.history.serial = ++captureSerial;
            plan.history.frame = frameSerial;
            plan.history.continuous = frame > 0;
            plan.history.game = true;
        }
        plan_view_job(world, fr, *viewTargets[kKey], kKey, plan);
        run_frame_graph();
        graphFromCapture = true;  // the graph the frame-graph report shows is this one until the next render()
        renderScene.reset();
        // Read-back waits for the GPU, and on Metal the work is only submitted by sg_commit (see capture()).
        gpu.commit_frame();
        gpu.note_commit();
    }
    const ViewTarget& vt = *viewTargets[kKey];
    std::vector<std::uint8_t> px;
    std::string readError;
    const bool ok = read_rgba8(vt.asset.image, vt.asset.view, w, h, px, &readError, true);
    release_view(*viewTargets[kKey]);
    // The RGBA8 copy of a big picture (a 4K capture is 64 MB) is not worth keeping: only the game target's size is asked for again.
    if (readW != final_w() || readH != final_h()) free_read_image();
    cleanup();
    if (!ok) return fail("reading the picture back from the GPU failed: " + readError);
    // capture_world blended onto a transparent background, so the colour is premultiplied by alpha; texture fields
    // expect straight alpha. capture_camera's picture is not (the camera's clear has alpha 1 and a custom pass writes
    // the alpha it means): left as drawn.
    for (std::size_t i = 0; premultiplied && i + 3 < px.size(); i += 4) {
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
