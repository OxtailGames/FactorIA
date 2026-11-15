// Renderer::Impl, part 2: the game target, the CameraView and Camera.renderTarget images, the 2D light buffer and shadow
// targets, the colour filter and the RGBA8 readback.
#include "renderer_impl.h"

namespace fa {

void Renderer::Impl::create_targets(int w, int h) {
    destroy_targets();
    targetW = std::max(1, w);
    targetH = std::max(1, h);
    physW = std::max(1, int(std::lround(double(targetW) * renderScale)));
    physH = std::max(1, int(std::lround(double(targetH) * renderScale)));
    make_game_targets();
    // A GPU can list RGBA16F as renderable and still refuse these images: GLES3/WebGL2 with multisampling but without
    // EXT_color_buffer_float, a framebuffer the driver calls incomplete (sokol marks the image or the attachment view FAILED).
    // Then the game is drawn in RGBA8 (everything clamps at white, hdr_scene() says false) rather than not at all. The same
    // check runs on every backend (GL, GLES, D3D11, Metal). FA_SCENE_FORMAT=rgba16f_invalid is a test hook: it makes the
    // check fail on a GPU that never would, to run the fall-back there.
    // Only the FIRST creation may change the format, and only when the same size works in RGBA8: later calls (an Expand-mode
    // resize, a render scale for a big screenshot) can fail for a moment (out of GPU memory), and that must neither downgrade
    // the game for good nor drop the pipelines in the middle of it. Then the old behaviour stays: the failure is reported by
    // the capture or the frame that needs the target.
    if (!initialized && gpu.scene_format() == SG_PIXELFORMAT_RGBA16F) {
        const char* hook = std::getenv("FA_SCENE_FORMAT");
        if (!game_targets_valid() || (hook && std::string(hook) == "rgba16f_invalid")) {
            destroy_targets();
            gpu.set_scene_format(SG_PIXELFORMAT_RGBA8);
            make_game_targets();
            if (game_targets_valid()) {
                gpu.drop_pipelines();
                FA_WARN("render",
                        "The GPU cannot make the {}x{} game target in RGBA16F{}, but can in RGBA8: the game is drawn "
                        "in RGBA8 "
                        "(colours above white are clamped, Camera.bloom is weaker, hdr_scene() is false)",
                        physW, physH, gpu.sample_count() > 1 ? " with multisampling" : "");
            } else {  // RGBA8 fails too: it is not the format; keep the float one and its errors
                destroy_targets();
                gpu.set_scene_format(SG_PIXELFORMAT_RGBA16F);
                make_game_targets();
            }
        }
    }
}

void Renderer::Impl::make_game_targets() {
    int samples = gpu.sample_count();
    sg_image_desc cd{};
    cd.usage.color_attachment = true;
    cd.width = physW;
    cd.height = physH;
    cd.pixel_format = gpu.scene_format();
    cd.sample_count = samples;
    cd.label = "game-color";
    colorImg = make_image(cd);
    sg_view_desc cv{};
    cv.color_attachment.image = colorImg;
    cv.label = "game-color-att";
    colorAtt = sg_make_view(&cv);
    if (samples > 1) {
        sg_image_desc rd{};
        rd.usage.resolve_attachment = true;
        rd.usage.color_attachment = true;  // Camera.bloom adds its glow to the resolved image
        rd.width = physW;
        rd.height = physH;
        rd.pixel_format = gpu.scene_format();
        rd.sample_count = 1;
        rd.label = "game-resolve";
        resolveImg = make_image(rd);
        sg_view_desc rv{};
        rv.resolve_attachment.image = resolveImg;
        resolveAtt = sg_make_view(&rv);
        sg_view_desc rc{};
        rc.color_attachment.image = resolveImg;
        rc.label = "game-resolve-color-att";
        resolveColorAtt = sg_make_view(&rc);
    }
    sg_view_desc tv{};
    tv.texture.image = samples > 1 ? resolveImg : colorImg;
    tv.label = "game-texture";
    texView = sg_make_view(&tv);
    sg_image_desc dd{};
    dd.usage.depth_stencil_attachment = true;
    dd.width = physW;
    dd.height = physH;
    dd.pixel_format = SG_PIXELFORMAT_DEPTH_STENCIL;
    dd.sample_count = samples;
    dd.label = "game-depth";
    depthImg = make_image(dd);
    sg_view_desc dv{};
    dv.depth_stencil_attachment.image = depthImg;
    depthAtt = sg_make_view(&dv);
}

bool Renderer::Impl::game_targets_valid() const {
    for (sg_image i : {colorImg, resolveImg, depthImg})
        if (i.id && sg_query_image_state(i) != SG_RESOURCESTATE_VALID) return false;
    for (sg_view v : {colorAtt, resolveAtt, resolveColorAtt, depthAtt, texView})
        if (v.id && sg_query_view_state(v) != SG_RESOURCESTATE_VALID) return false;
    return colorImg.id != 0 && texView.id != 0;
}

void Renderer::Impl::free_read_image() {
    if (readAtt.id) sg_destroy_view(readAtt);
    readAtt = {};
    if (readImg.id) sg_destroy_image(readImg);
    readImg = {};
    readW = readH = 0;
}

void Renderer::Impl::destroy_targets() {
    for (auto& [key, t] : viewTargets) release_view(*t);
    viewTargets.clear();
    bloom.release();
    for (sg_view* v : {&lightAtt, &lightTexView}) {
        if (v->id) sg_destroy_view(*v);
        *v = {};
    }
    if (lightImg.id) sg_destroy_image(lightImg);
    lightImg = {};
    lightW = lightH = 0;
    filterActive = false;
    for (sg_view* v : {&filterAtt, &filterTex}) {
        if (v->id) sg_destroy_view(*v);
        *v = {};
    }
    if (filterImg.id) sg_destroy_image(filterImg);
    filterImg = {};
    free_read_image();
    for (sg_view* v : {&colorAtt, &resolveAtt, &resolveColorAtt, &depthAtt, &texView}) {
        if (v->id) sg_destroy_view(*v);
        *v = {};
    }
    for (sg_image* i : {&colorImg, &resolveImg, &depthImg}) {
        if (i->id) sg_destroy_image(*i);
        *i = {};
    }
}

// Makes (or keeps) the image of a CameraView: w x h pixels, drawn into with the game target's formats and sample count.
// Null (and one logged error) when the GPU cannot make it.
TextureAsset* Renderer::Impl::view_image(std::uint64_t key, int w, int h, bool renderTarget) {
    std::unique_ptr<ViewTarget>& slot = viewTargets[key];
    if (!slot) slot = std::make_unique<ViewTarget>();
    ViewTarget& t = *slot;
    t.used = true;
    if (t.color.id && t.w == w && t.h == h) return &t.asset;
    release_view(t);
    t.flipCopy = renderTarget && gpu.is_gl();
    const int samples = gpu.sample_count();
    sg_image_desc cd{};
    cd.usage.color_attachment = true;
    cd.width = w;
    cd.height = h;
    cd.pixel_format = gpu.scene_format();
    cd.sample_count = samples;
    cd.label = "view-color";
    t.color = make_image(cd);
    sg_view_desc cv{};
    cv.color_attachment.image = t.color;
    cv.label = "view-color-att";
    t.colorAtt = sg_make_view(&cv);
    if (samples > 1) {
        sg_image_desc rd{};
        rd.usage.resolve_attachment = true;
        rd.width = w;
        rd.height = h;
        rd.pixel_format = gpu.scene_format();
        rd.sample_count = 1;
        rd.label = "view-resolve";
        t.resolve = make_image(rd);
        sg_view_desc rv{};
        rv.resolve_attachment.image = t.resolve;
        t.resolveAtt = sg_make_view(&rv);
    }
    sg_view_desc tv{};
    tv.texture.image = samples > 1 ? t.resolve : t.color;
    tv.label = "view-texture";
    t.texView = sg_make_view(&tv);
    sg_image_desc dd{};
    dd.usage.depth_stencil_attachment = true;
    dd.width = w;
    dd.height = h;
    dd.pixel_format = SG_PIXELFORMAT_DEPTH_STENCIL;
    dd.sample_count = samples;
    dd.label = "view-depth";
    t.depth = make_image(dd);
    sg_view_desc dv{};
    dv.depth_stencil_attachment.image = t.depth;
    t.depthAtt = sg_make_view(&dv);
    const bool ok = sg_query_image_state(t.color) == SG_RESOURCESTATE_VALID &&
                    sg_query_image_state(t.depth) == SG_RESOURCESTATE_VALID &&
                    sg_query_view_state(t.texView) == SG_RESOURCESTATE_VALID &&
                    sg_query_view_state(t.colorAtt) == SG_RESOURCESTATE_VALID;
    if (!ok) {
        if (!viewWarned)
            FA_ERROR("render", "Cannot create the {}x{} image of a CameraView; the widget draws only its background", w,
                     h);
        viewWarned = true;
        release_view(t);
        return nullptr;
    }
    if (t.flipCopy) {
        sg_image_desc fd{};
        fd.usage.color_attachment = true;
        fd.width = w;
        fd.height = h;
        fd.pixel_format = gpu.scene_format();
        fd.sample_count = 1;
        fd.label = "target-flipped";
        t.flip = make_image(fd);
        sg_view_desc fa{};
        fa.color_attachment.image = t.flip;
        t.flipAtt = sg_make_view(&fa);
        sg_view_desc ft{};
        ft.texture.image = t.flip;
        t.flipTex = sg_make_view(&ft);
        if (sg_query_image_state(t.flip) != SG_RESOURCESTATE_VALID ||
            sg_query_view_state(t.flipAtt) != SG_RESOURCESTATE_VALID ||
            sg_query_view_state(t.flipTex) != SG_RESOURCESTATE_VALID) {
            if (!viewWarned) FA_ERROR("render", "Cannot create the {}x{} image of a render target", w, h);
            viewWarned = true;
            release_view(t);
            return nullptr;
        }
    }
    t.w = w;
    t.h = h;
    t.asset = TextureAsset{};
    t.asset.path = renderTarget ? "target" : "view";
    t.asset.image = t.flipCopy ? t.flip : (samples > 1 ? t.resolve : t.color);
    t.asset.view = t.flipCopy ? t.flipTex : t.texView;
    t.asset.width = w;
    t.asset.height = h;
    return &t.asset;
}

void Renderer::Impl::release_view(ViewTarget& t) {
    for (sg_view* v : {&t.colorAtt, &t.resolveAtt, &t.depthAtt, &t.texView, &t.flipAtt, &t.flipTex}) {
        if (v->id) sg_destroy_view(*v);
        *v = {};
    }
    for (sg_image* i : {&t.color, &t.resolve, &t.depth, &t.flip}) {
        if (i->id) sg_destroy_image(*i);
        *i = {};
    }
    t.w = t.h = 0;
    t.asset = TextureAsset{};
}

// Frees the images no CameraView asked for in this frame (the widget is gone, hidden or shows no camera any more).
void Renderer::Impl::release_unused_views() {
    for (auto it = viewTargets.begin(); it != viewTargets.end();) {
        if (it->second->used) {
            it->second->used = false;
            ++it;
        } else {
            release_view(*it->second);
            it = viewTargets.erase(it);
        }
    }
}

// ---- Camera.renderTarget -------------------------------------------------------------------------------------------------

void Renderer::Impl::warn_target_once(const std::string& key, const std::string& message, const std::string& hint) {
    if (!targetWarned.insert(key).second) return;
    FA_ERROR("render", "{}. Hint: {}", message, hint);
}

// The active cameras with a Camera.renderTarget: valid, one per name, each with its image (made here, so the textures exist
// before any gather asks for them). The images of the cameras that are gone are freed at the end of the frame.
void Renderer::Impl::collect_targets(World& world) {
    targetCams.clear();
    targetByName.clear();
    targetByAsset.clear();
    if (selfSentinel.path.empty()) {  // the checker under another address: a camera that shows its own target gets this
        selfSentinel = *assets->placeholder();
        selfSentinel.path = "target-self";
    }
    world.each<Camera>([&](Entity e, Camera& c) {
        if (c.renderTarget.empty() || !entity_active(world, e)) return;
        const std::string who = "Camera '" + world.id_of(e) + "'";
        Camera probe = c;
        probe.renderTargetSize = Vec2{1, 1};
        if (const std::string problem = camera_render_target_problem(probe); !problem.empty()) {
            warn_target_once(
                "name:" + std::to_string(e.bits()) + c.renderTarget, who + ": " + problem + "; the camera is not drawn",
                "Camera.renderTarget is a short name of letters, digits, '_', '-' and '.' (up to 64 characters).");
            return;
        }
        if (targetByName.count(c.renderTarget)) {
            const TargetCam& first = targetCams[std::size_t(targetByName[c.renderTarget])];
            warn_target_once("dup:" + c.renderTarget,
                             who + " renders into target '" + c.renderTarget + "', which Camera '" +
                                 world.id_of(first.entity) + "' already renders into; this camera is not drawn",
                             "Give every render-target camera its own renderTarget name, or deactivate one of them.");
            return;
        }
        int w = 1, h = 1;
        bool clamped = false;
        camera_render_target_pixels(c, w, h, &clamped);
        if (clamped) {
            const Vec2 sz = c.renderTargetSize;
            warn_target_once("size:" + std::to_string(e.bits()) + std::to_string(w) + "x" + std::to_string(h),
                             who + ": Camera.renderTargetSize is [" + std::to_string(sz.x) + ", " +
                                 std::to_string(sz.y) + "], the texture is made " + std::to_string(w) + " x " +
                                 std::to_string(h),
                             "renderTargetSize is [width, height] in pixels, each 1..4096.");
        }
        const std::uint64_t key =
            (1ull << 63) | std::uint64_t(std::hash<std::string>{}(c.renderTarget) & 0x7fffffffffffffffull);
        TextureAsset* asset = view_image(key, w, h, true);
        if (!asset) return;
        targetByName[c.renderTarget] = int(targetCams.size());
        targetByAsset[asset] = int(targetCams.size());
        targetCams.push_back(TargetCam{e, c.renderTarget, w, h, key, c.depth, asset});
    });
}

// What texture("target:<name>") answers: the target's live texture; the checker (selfSentinel) for the camera that draws that very
// target (a pass cannot sample the image it writes); null when no camera renders into the name.
TextureAsset* Renderer::Impl::resolve_target(const std::string& name) {
    auto it = targetByName.find(name);
    if (it == targetByName.end()) return nullptr;
    if (name == targetSelf) return &selfSentinel;
    return targetCams[std::size_t(it->second)].asset;
}

// GL stores render targets bottom-up: copy the finished picture the right way up into the image the texture asset samples.
void Renderer::Impl::flip_copy(ViewTarget& t) {
    if (!t.flipCopy || !t.flip.id || !gpu.colorfilter_ready())
        return;  // the copy draws with the colour filter's shader
    sg_pass p{};
    p.action.colors[0].load_action = SG_LOADACTION_DONTCARE;
    p.action.colors[0].store_action = SG_STOREACTION_STORE;
    p.attachments.colors[0] = t.flipAtt;
    p.label = "target-flip";
    sg_begin_pass(&p);
    sg_apply_pipeline(gpu.colorfilter_pipeline());
    sg_bindings b{};
    b.vertex_buffers[0] = gpu.fullscreen_triangle();
    b.views[VIEW_colorfilter_tex] = t.texView;
    b.samplers[SMP_colorfilter_smp] = gpu.sampler(SamplerKind::Nearest);
    sg_apply_bindings(&b);
    colorfilter_colorfilter_vs_params_t vu{};
    vu.flip[0] = 0.0f;  // the filter's own flip (1 on GL) reads the target as it is stored; 0 turns it
    apply_uniforms(UB_colorfilter_colorfilter_vs_params, vu);
    colorfilter_colorfilter_params_t fu{};
    fu.p[0] = 0.0f;  // mode 0: a plain copy with the alpha
    apply_uniforms(UB_colorfilter_colorfilter_params, fu);
    sg_draw(0, 3, 1);
    sg_end_pass();
    ++stats.drawCalls;
}

// Makes (or keeps) the light buffer: `scale` times the size of the game target, in the format the GPU draws lights in.
// False (and one logged error) when it cannot be created: lit visuals then use the per-pixel path.
bool Renderer::Impl::ensure_light_target(float scale) {
    if (lightTargetFailed) return false;
    const int w = std::max(1, int(std::lround(double(physW) * double(scale))));
    const int h = std::max(1, int(std::lround(double(physH) * double(scale))));
    const sg_pixel_format fmt = gpu.light_format();
    if (lightImg.id && lightW == w && lightH == h && lightImgFormat == fmt) return true;
    for (sg_view* v : {&lightAtt, &lightTexView}) {
        if (v->id) sg_destroy_view(*v);
        *v = {};
    }
    if (lightImg.id) sg_destroy_image(lightImg);
    lightImg = {};
    sg_image_desc d{};
    d.usage.color_attachment = true;
    d.width = w;
    d.height = h;
    d.pixel_format = fmt;
    d.sample_count = 1;
    d.label = "light-buffer";
    lightImg = make_image(d);
    sg_view_desc av{};
    av.color_attachment.image = lightImg;
    av.label = "light-buffer-att";
    lightAtt = sg_make_view(&av);
    sg_view_desc tv{};
    tv.texture.image = lightImg;
    tv.label = "light-buffer-tex";
    lightTexView = sg_make_view(&tv);
    if (sg_query_image_state(lightImg) != SG_RESOURCESTATE_VALID ||
        sg_query_view_state(lightAtt) != SG_RESOURCESTATE_VALID ||
        sg_query_view_state(lightTexView) != SG_RESOURCESTATE_VALID) {
        FA_ERROR(
            "render",
            "Cannot create the {}x{} 2D light buffer; lit visuals are shaded per pixel by the first {} lights only", w,
            h, kDirectLights2D);
        for (sg_view* v : {&lightAtt, &lightTexView}) {
            if (v->id) sg_destroy_view(*v);
            *v = {};
        }
        if (lightImg.id) sg_destroy_image(lightImg);
        lightImg = {};
        lightTargetFailed = true;
        return false;
    }
    lightW = w;
    lightH = h;
    lightImgFormat = fmt;
    return true;
}

// The image of the frame's shadow rows (Frame::shadowData); an empty view when no light casts a shadow. Immutable: a new
// image is made only when the rows changed (a light moved, a tile was edited), so a still scene uploads nothing.
sg_view Renderer::Impl::upload_shadow_rows(const Frame& fr) {
    if (fr.shadowRows <= 0) return sg_view{};
    for (int i = 0; i < kShadowRowsRing; ++i)
        if (shadowRowsView[i].id && shadowRowsKey[i] == fr.shadowKey) return shadowRowsView[i];
    const int slot = (shadowRowsCurrent + 1) % kShadowRowsRing;
    if (shadowRowsView[slot].id) sg_destroy_view(shadowRowsView[slot]);
    if (shadowRowsImg[slot].id) sg_destroy_image(shadowRowsImg[slot]);
    sg_image_desc d{};
    d.width = kShadowAngles;
    d.height = fr.shadowRows;
    d.pixel_format = SG_PIXELFORMAT_RGBA8;
    d.data.mip_levels[0] = {fr.shadowData.data(), fr.shadowData.size()};
    d.label = "light-shadow-rows";
    shadowRowsImg[slot] = make_image(d);
    sg_view_desc tv{};
    tv.texture.image = shadowRowsImg[slot];
    tv.label = "light-shadow-rows-tex";
    shadowRowsView[slot] = sg_make_view(&tv);
    shadowRowsKey[slot] = fr.shadowKey;
    shadowRowsCurrent = slot;
    return shadowRowsView[slot];
}

void Renderer::Impl::destroy_light_resources() {
    for (int i = 0; i < kShadowRowsRing; ++i) {
        if (shadowRowsView[i].id) sg_destroy_view(shadowRowsView[i]);
        if (shadowRowsImg[i].id) sg_destroy_image(shadowRowsImg[i]);
        shadowRowsView[i] = {};
        shadowRowsImg[i] = {};
        shadowRowsKey[i] = 0;
    }
}

// Draws the finished game target through colorfilter.glsl into filterImg. Returns the draw calls issued (0 when the
// filter was skipped: the shader or the image could not be created, which is logged once).
int Renderer::Impl::apply_color_filter(int mode) {
    if (!gpu.colorfilter_ready()) return 0;
    if (!filterImg.id) {
        sg_image_desc d{};
        d.usage.color_attachment = true;
        d.width = physW;
        d.height = physH;
        d.pixel_format = gpu.scene_format();
        d.sample_count = 1;
        d.label = "game-filtered";
        filterImg = make_image(d);
        sg_view_desc av{};
        av.color_attachment.image = filterImg;
        av.label = "game-filtered-att";
        filterAtt = sg_make_view(&av);
        sg_view_desc tv{};
        tv.texture.image = filterImg;
        tv.label = "game-filtered-tex";
        filterTex = sg_make_view(&tv);
        if (sg_query_image_state(filterImg) != SG_RESOURCESTATE_VALID ||
            sg_query_view_state(filterAtt) != SG_RESOURCESTATE_VALID ||
            sg_query_view_state(filterTex) != SG_RESOURCESTATE_VALID) {
            FA_ERROR("render",
                     "Camera.colorFilter: cannot create the {}x{} target; the game is drawn without the filter", physW,
                     physH);
            for (sg_view* v : {&filterAtt, &filterTex}) {
                if (v->id) sg_destroy_view(*v);
                *v = {};
            }
            sg_destroy_image(filterImg);
            filterImg = {};
            return 0;
        }
    }
    sg_pass p{};
    p.action.colors[0].load_action = SG_LOADACTION_DONTCARE;
    p.action.colors[0].store_action = SG_STOREACTION_STORE;
    p.attachments.colors[0] = filterAtt;
    p.label = "color-filter";
    sg_begin_pass(&p);
    sg_apply_pipeline(gpu.colorfilter_pipeline());
    sg_bindings b{};
    b.vertex_buffers[0] = gpu.fullscreen_triangle();
    b.views[VIEW_colorfilter_tex] = texView;
    b.samplers[SMP_colorfilter_smp] = gpu.sampler(SamplerKind::Nearest);
    sg_apply_bindings(&b);
    colorfilter_colorfilter_vs_params_t vu{};
    vu.flip[0] = gpu.is_gl() ? 1.0f : 0.0f;
    apply_uniforms(UB_colorfilter_colorfilter_vs_params, vu);
    colorfilter_colorfilter_params_t fu{};
    fu.p[0] = float(mode);
    apply_uniforms(UB_colorfilter_colorfilter_params, fu);
    sg_draw(0, 3, 1);
    sg_end_pass();
    filterActive = true;
    return 1;
}

bool Renderer::Impl::read_rgba8(sg_image image, sg_view view, int w, int h, std::vector<std::uint8_t>& out,
                                std::string* error) {
    if (gpu.scene_format() == SG_PIXELFORMAT_RGBA8) return readback_rgba8(image, w, h, out, error);
    if (!readImg.id || readW != w || readH != h) {
        free_read_image();
        sg_image_desc d{};
        d.usage.color_attachment = true;
        d.width = w;
        d.height = h;
        d.pixel_format = SG_PIXELFORMAT_RGBA8;
        d.sample_count = 1;
        d.label = "readback-rgba8";
        readImg = make_image(d);
        sg_view_desc av{};
        av.color_attachment.image = readImg;
        av.label = "readback-rgba8-att";
        readAtt = sg_make_view(&av);
        if (sg_query_image_state(readImg) != SG_RESOURCESTATE_VALID ||
            sg_query_view_state(readAtt) != SG_RESOURCESTATE_VALID) {
            if (error)
                *error = std::format("the {}x{} image for reading the frame back as 8-bit colour could not be created "
                                     "(out of GPU memory?)",
                                     w, h);
            free_read_image();
            return false;
        }
        readW = w;
        readH = h;
    }
    sg_pass p{};
    p.action.colors[0].load_action = SG_LOADACTION_DONTCARE;
    p.action.colors[0].store_action = SG_STOREACTION_STORE;
    p.attachments.colors[0] = readAtt;
    p.label = "readback-rgba8";
    sg_begin_pass(&p);
    sg_apply_pipeline(gpu.blit_keep_pipeline());
    sg_bindings b{};
    b.vertex_buffers[0] = gpu.fullscreen_triangle();
    b.views[VIEW_blit_tex] = view;
    b.samplers[SMP_blit_smp] = gpu.sampler(SamplerKind::Nearest);
    sg_apply_bindings(&b);
    blit_blit_vs_params_t u{};
    u.flip[0] = gpu.is_gl() ? 1.0f : 0.0f;
    apply_uniforms(UB_blit_blit_vs_params, u);
    sg_draw(0, 3, 1);
    sg_end_pass();
    // The read-back waits for the GPU and on Metal only an sg_commit() submits the copy (see Renderer::capture()).
    sg_commit();
    gpu.note_commit();
    return readback_rgba8(readImg, w, h, out, error);
}

void Renderer::Impl::create_shadow_targets() {
    if (shadowColor.id || !gpu.shadows_supported()) return;
    sg_image_desc cd{};
    cd.usage.color_attachment = true;
    cd.width = cd.height = kShadowSize;
    cd.pixel_format = SG_PIXELFORMAT_R32F;
    cd.label = "shadow-color";
    shadowColor = make_image(cd);
    sg_image_desc dd{};
    dd.usage.depth_stencil_attachment = true;
    dd.width = dd.height = kShadowSize;
    dd.pixel_format = SG_PIXELFORMAT_DEPTH;
    dd.label = "shadow-depth";
    shadowDepth = make_image(dd);
    sg_view_desc v{};
    v.color_attachment.image = shadowColor;
    shadowColorAtt = sg_make_view(&v);
    v = {};
    v.depth_stencil_attachment.image = shadowDepth;
    shadowDepthAtt = sg_make_view(&v);
    v = {};
    v.texture.image = shadowColor;
    shadowTexView = sg_make_view(&v);
}

}  // namespace fa
