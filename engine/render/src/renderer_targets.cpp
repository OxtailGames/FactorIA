// Renderer::Impl, part 2: the game target, the CameraView and Camera.renderTarget images, the 2D light buffer and
// shadow targets, the colour filter and the RGBA8 readback.
#include "renderer_impl.h"

namespace fa::render {

bool Target::valid() const {
    if (!color.id) return false;
    for (sg_image i : {color, resolve, depth})
        if (i.id && sg_query_image_state(i) != SG_RESOURCESTATE_VALID) return false;
    for (sg_view v : {colorAtt, resolveAtt, resolveColorAtt, depthAtt, texView})
        if (v.id && sg_query_view_state(v) != SG_RESOURCESTATE_VALID) return false;
    // A view the description asked for that the GPU did not even create (a full pool) is as bad as a failed one.
    return colorAtt.id && (!expectTexture || texView.id) && (!expectDepth || (depth.id && depthAtt.id)) &&
           (samples <= 1 || (resolve.id && resolveAtt.id));
}

Target make_target(const TargetDesc& d) {
    Target t;
    t.w = d.width;
    t.h = d.height;
    t.samples = std::max(1, d.samples);
    t.format = TargetFormat{d.colorFormat, d.depthFormat, t.samples};
    t.expectTexture = d.texture;
    t.expectDepth = d.depthFormat != SG_PIXELFORMAT_NONE;
    const std::string base = d.label ? d.label : "target";
    const std::string colorLabel = base + "-color", colorAttLabel = base + "-color-att",
                      resolveLabel = base + "-resolve", resolveColorLabel = base + "-resolve-color-att",
                      textureLabel = base + "-texture", depthLabel = base + "-depth";
    const bool msaa = t.samples > 1;
    if (d.colorFormat != SG_PIXELFORMAT_NONE) {
        sg_image_desc cd{};
        cd.usage.color_attachment = true;
        cd.width = d.width;
        cd.height = d.height;
        cd.pixel_format = d.colorFormat;
        cd.sample_count = t.samples;
        cd.label = colorLabel.c_str();
        t.color = make_image(cd);
        sg_view_desc cv{};
        cv.color_attachment.image = t.color;
        cv.label = colorAttLabel.c_str();
        t.colorAtt = sg_make_view(&cv);
        if (msaa) {
            sg_image_desc rd{};
            rd.usage.resolve_attachment = true;
            rd.usage.color_attachment = d.resolveAsColor;
            rd.width = d.width;
            rd.height = d.height;
            rd.pixel_format = d.colorFormat;
            rd.sample_count = 1;
            rd.label = resolveLabel.c_str();
            t.resolve = make_image(rd);
            sg_view_desc rv{};
            rv.resolve_attachment.image = t.resolve;
            rv.label = resolveLabel.c_str();
            t.resolveAtt = sg_make_view(&rv);
            if (d.resolveAsColor) {
                sg_view_desc rc{};
                rc.color_attachment.image = t.resolve;
                rc.label = resolveColorLabel.c_str();
                t.resolveColorAtt = sg_make_view(&rc);
            }
        }
        if (d.texture) {
            sg_view_desc tv{};
            tv.texture.image = t.texture_image();
            tv.label = textureLabel.c_str();
            t.texView = sg_make_view(&tv);
        }
    }
    if (d.depthFormat != SG_PIXELFORMAT_NONE) {
        sg_image_desc dd{};
        dd.usage.depth_stencil_attachment = true;
        dd.width = d.width;
        dd.height = d.height;
        dd.pixel_format = d.depthFormat;
        dd.sample_count = t.samples;
        dd.label = depthLabel.c_str();
        t.depth = make_image(dd);
        sg_view_desc dv{};
        dv.depth_stencil_attachment.image = t.depth;
        dv.label = depthLabel.c_str();
        t.depthAtt = sg_make_view(&dv);
    }
    return t;
}

void destroy_target(Target& t) {
    for (sg_view* v : {&t.colorAtt, &t.resolveAtt, &t.resolveColorAtt, &t.depthAtt, &t.texView}) {
        if (v->id) sg_destroy_view(*v);
        *v = {};
    }
    for (sg_image* i : {&t.color, &t.resolve, &t.depth}) {
        if (i->id) sg_destroy_image(*i);
        *i = {};
    }
    t = Target{};
}

PassDesc pass_into(const Target& t, const char* label) {
    PassDesc p;
    p.label = label;
    p.color = t.colorAtt;
    if (t.samples > 1) p.resolve = t.resolveAtt;
    p.depth = t.depthAtt;
    p.format = t.format;
    return p;
}

}  // namespace fa::render

namespace fa {

void Renderer::Impl::create_targets(int w, int h, bool settle) {
    destroy_targets();
    targetW = std::max(1, w);
    targetH = std::max(1, h);
    physW = std::max(1, int(std::lround(double(targetW) * renderScale)));
    physH = std::max(1, int(std::lround(double(targetH) * renderScale)));
    make_game_targets();
    // A GPU can list a float format as renderable and still refuse these images: GLES3/WebGL2 with multisampling but without
    // EXT_color_buffer_float, a framebuffer the driver calls incomplete (sokol marks the image or the attachment view
    // FAILED). Then the game is drawn in the next format of the chain (Gpu::init: R11G11B10 or SRGB8A8 in a linear scene, then
    // RGBA8, where everything clamps at white and hdr_scene() says false) rather than not at all. The same check runs on every
    // backend (GL, GLES, D3D11, Metal). FA_SCENE_FORMAT=rgba16f_invalid is a test hook: it makes the check fail on a GPU that
    // never would, to run the fall-back there.
    // Only the FIRST creation in a colour space may change the format (`settle`: the colour space has just been switched), and
    // only when the same size works in the next one: later calls (an Expand-mode resize, a render scale for a big screenshot) can
    // fail for a moment (out of GPU memory), and that must not downgrade the game for good in the middle of it. Then the old
    // behaviour stays: the failure is reported by the capture or the frame that needs the target.
    if (initialized && !settle) return;
    const char* hook = std::getenv("FA_SCENE_FORMAT");
    const bool hookInvalid = hook && std::string(hook) == "rgba16f_invalid";
    auto refused = [&] {
        return !game_targets_valid() || (hookInvalid && gpu.scene_format() == SG_PIXELFORMAT_RGBA16F);
    };
    if (!refused() || gpu.scene_format() == SG_PIXELFORMAT_RGBA8) return;
    const int first = gpu.scene_pick();
    const sg_pixel_format firstFormat = gpu.scene_format();
    while (gpu.next_scene_format()) {
        destroy_targets();
        make_game_targets();
        if (refused()) continue;
        FA_WARN("render", "The GPU cannot make the {}x{} game target in {}{}, but can in {}: the game is drawn in {}{}",
                physW, physH, pixel_format_name(firstFormat), gpu.sample_count() > 1 ? " with multisampling" : "",
                pixel_format_name(gpu.scene_format()), pixel_format_name(gpu.scene_format()),
                gpu.scene_is_float()
                    ? ""
                    : " (colours above white are clamped, Camera.bloom is weaker, hdr_scene() is false)");
        return;
    }
    // Nothing of the chain works: it is not the format; keep the first one and its errors.
    destroy_targets();
    gpu.set_scene_pick(first);
    make_game_targets();
}

// SceneSettings.colorSpace of the world about to be drawn: a change of the scene's format (RGBA8 <-> SRGB8A8; RGBA16F stays)
// makes the game target again; the textures, the pipelines and every other resource are kept (the shaders fix the textures that
// were made for the other colour space, TextureAsset::tex_fix).
void Renderer::Impl::sync_color_space(const World& world) {
    const bool linear = world.settings().colorSpace == ColorSpace::Linear;
    if (linear == gpu.linear()) return;
    if (!linear) destroy_target(editorTarget);  // back in gamma the viewport shows the game image itself
    if (gpu.set_linear(linear)) create_targets(targetW, targetH, true);
}

sg_image Renderer::Impl::display_image() const {
    if (!gpu.linear() || !editorView) return final_image();
    return editorTarget.texture_image();
}

sg_view Renderer::Impl::display_view() const {
    if (!gpu.linear() || !editorView) return final_view();
    return editorTarget.texView;
}

// A linear scene holds linear light: shown as it is, the editor's viewport would be too dark. After the frame is drawn (and the colour
// filter, if any) the finished image is encoded into an RGBA8 copy that ImGui shows. Same orientation as the game image (the viewport
// flips it on GL), not counted in RenderStats::drawCalls. Made only when the editor asked and the scene is linear.
void Renderer::Impl::update_editor_copy() {
    if (!editorView || !gpu.linear() || !game_targets_valid()) {
        destroy_target(editorTarget);
        return;
    }
    if (editorTarget.color.id && (editorTarget.w != physW || editorTarget.h != physH)) destroy_target(editorTarget);
    if (!editorTarget.color.id) {
        TargetDesc d;
        d.label = "editor-view";
        d.width = physW;
        d.height = physH;
        d.colorFormat = SG_PIXELFORMAT_RGBA8;
        editorTarget = make_target(d);
        if (!editorTarget.valid()) {
            destroy_target(editorTarget);  // the viewport shows its "no render target" text; tried again next frame
            return;
        }
    }
    PassDesc p = pass_into(editorTarget, "editor-view");
    p.colorLoad = SG_LOADACTION_DONTCARE;  // every pixel is drawn
    p.colorStore = SG_STOREACTION_STORE;
    gpu.begin_pass(p);
    sg_apply_pipeline(gpu.blit_keep_pipeline(p.format));
    sg_bindings b{};
    b.vertex_buffers[0] = gpu.fullscreen_triangle();
    b.views[VIEW_blit_tex] = final_view();
    b.samplers[SMP_blit_smp] = gpu.sampler(SamplerKind::Nearest);
    sg_apply_bindings(&b);
    blit_blit_vs_params_t u{};  // flip stays 0: the copy is stored like the game image
    apply_uniforms(UB_blit_blit_vs_params, u);
    blit_blit_fs_params_t fu{};
    fu.encode[0] = 1.0f;
    apply_uniforms(UB_blit_blit_fs_params, fu);
    sg_draw(0, 3, 1);
    gpu.end_pass();
}

void Renderer::Impl::make_game_targets() {
    TargetDesc d;
    d.label = "game";
    d.width = physW;
    d.height = physH;
    d.colorFormat = gpu.scene_format();
    d.samples = gpu.sample_count();
    d.resolveAsColor = true;  // Camera.bloom adds its glow to the resolved image
    d.depthFormat = kSceneDepthFormat;
    gameTarget = make_target(d);
}

bool Renderer::Impl::game_targets_valid() const { return gameTarget.valid(); }

void Renderer::Impl::free_read_image() {
    destroy_target(readbackTarget);
    readW = readH = 0;
}

void Renderer::Impl::destroy_targets() {
    for (auto& [key, t] : viewTargets) release_view(*t);
    viewTargets.clear();
    bloom.release();
    if (transients) transients->pool.clear_free();  // the bloom levels are made again, at the new size
    destroy_target(lightTarget);
    lightW = lightH = 0;
    filterActive = false;
    destroy_target(filterTarget);
    destroy_target(editorTarget);
    free_read_image();
    destroy_target(gameTarget);
}

// Makes (or keeps) the image of a CameraView: w x h pixels, drawn into with the game target's formats and sample count.
// Null (and one logged error) when the GPU cannot make it.
TextureAsset* Renderer::Impl::view_image(std::uint64_t key, int w, int h, bool renderTarget) {
    std::unique_ptr<ViewTarget>& slot = viewTargets[key];
    if (!slot) slot = std::make_unique<ViewTarget>();
    ViewTarget& t = *slot;
    t.used = true;
    if (t.main.color.id && t.w == w && t.h == h) return &t.asset;
    release_view(t);
    t.flipCopy = renderTarget && gpu.is_gl();
    TargetDesc d;
    d.label = "view";
    d.width = w;
    d.height = h;
    d.colorFormat = gpu.scene_format();
    d.samples = gpu.sample_count();
    d.depthFormat = kSceneDepthFormat;
    t.main = make_target(d);
    if (!t.main.valid()) {
        if (!viewWarned)
            FA_ERROR("render", "Cannot create the {}x{} image of a CameraView; the widget draws only its background", w,
                     h);
        viewWarned = true;
        release_view(t);
        return nullptr;
    }
    if (t.flipCopy) {
        TargetDesc fd;
        fd.label = "target-flipped";
        fd.width = w;
        fd.height = h;
        fd.colorFormat = gpu.scene_format();
        t.flip = make_target(fd);
        if (!t.flip.valid()) {
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
    t.asset.enc =
        TexEncoding::Scene;  // holds the scene's own values (linear in a linear scene): never converted when sampled
    t.asset.image = t.flipCopy ? t.flip.color : t.main.texture_image();
    t.asset.view = t.flipCopy ? t.flip.texView : t.main.texView;
    t.asset.width = w;
    t.asset.height = h;
    return &t.asset;
}

void Renderer::Impl::release_view(ViewTarget& t) {
    destroy_target(t.main);
    destroy_target(t.flip);
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

// ---- Camera.renderTarget
// -------------------------------------------------------------------------------------------------

void Renderer::Impl::warn_target_once(const std::string& key, const std::string& message, const std::string& hint) {
    if (!targetWarned.insert(key).second) return;
    FA_ERROR("render", "{}. Hint: {}", message, hint);
}

// The active cameras with a Camera.renderTarget: valid, one per name, each with its image (made here, so the textures
// exist before any gather asks for them). The images of the cameras that are gone are freed at the end of the frame.
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

// What texture("target:<name>") answers: the target's live texture; the checker (selfSentinel) for the camera that
// draws that very target (a pass cannot sample the image it writes); null when no camera renders into the name.
TextureAsset* Renderer::Impl::resolve_target(const std::string& name) {
    auto it = targetByName.find(name);
    if (it == targetByName.end()) return nullptr;
    if (name == targetSelf) return &selfSentinel;
    return targetCams[std::size_t(it->second)].asset;
}

// GL stores render targets bottom-up: copy the finished picture the right way up into the image the texture asset
// samples.
void Renderer::Impl::flip_copy(ViewTarget& t) {
    if (!t.flipCopy || !t.flip.color.id || !gpu.colorfilter_ready())
        return;  // the copy draws with the colour filter's shader
    PassDesc p = pass_into(t.flip, "target-flip");
    p.colorLoad = SG_LOADACTION_DONTCARE;  // every pixel is drawn
    p.colorStore = SG_STOREACTION_STORE;
    gpu.begin_pass(p);
    sg_apply_pipeline(gpu.colorfilter_pipeline(p.format));
    sg_bindings b{};
    b.vertex_buffers[0] = gpu.fullscreen_triangle();
    b.views[VIEW_colorfilter_tex] = t.main.texView;
    b.samplers[SMP_colorfilter_smp] = gpu.sampler(SamplerKind::Nearest);
    sg_apply_bindings(&b);
    colorfilter_colorfilter_vs_params_t vu{};
    vu.flip[0] = 0.0f;  // the filter's own flip (1 on GL) reads the target as it is stored; 0 turns it
    apply_uniforms(UB_colorfilter_colorfilter_vs_params, vu);
    colorfilter_colorfilter_params_t fu{};
    fu.p[0] = 0.0f;  // mode 0: a plain copy with the alpha
    apply_uniforms(UB_colorfilter_colorfilter_params, fu);
    sg_draw(0, 3, 1);
    gpu.end_pass();
    ++stats.drawCalls;
}

// Makes (or keeps) the light buffer: `scale` times the size of the game target, in the format the GPU draws lights in.
// False (and one logged error) when it cannot be created: lit visuals then use the per-pixel path.
bool Renderer::Impl::ensure_light_target(float scale) {
    if (lightTargetFailed) return false;
    const int w = std::max(1, int(std::lround(double(physW) * double(scale))));
    const int h = std::max(1, int(std::lround(double(physH) * double(scale))));
    const sg_pixel_format fmt = gpu.light_format();
    if (lightTarget.color.id && lightW == w && lightH == h && lightImgFormat == fmt) return true;
    destroy_target(lightTarget);
    TargetDesc d;
    d.label = "light-buffer";
    d.width = w;
    d.height = h;
    d.colorFormat = fmt;
    lightTarget = make_target(d);
    if (!lightTarget.valid()) {
        FA_ERROR(
            "render",
            "Cannot create the {}x{} 2D light buffer; lit visuals are shaded per pixel by the first {} lights only", w,
            h, kDirectLights2D);
        destroy_target(lightTarget);
        lightTargetFailed = true;
        return false;
    }
    lightW = w;
    lightH = h;
    lightImgFormat = fmt;
    return true;
}

// The image of the frame's shadow rows (Frame::shadowData); an empty view when no light casts a shadow. Immutable: a
// new image is made only when the rows changed (a light moved, a tile was edited), so a still scene uploads nothing.
// The jobs of a frame are planned before any draws, so the image returned stays valid until the frame graph ran: a slot
// used in this frame (frameSerial) is never replaced in it. The result does not depend on timing: a hit is by key, a
// miss replaces the slot with the lowest usedFrame (the first of them), or adds one when all were used this frame.
sg_view Renderer::Impl::upload_shadow_rows(const Frame& fr) {
    if (fr.shadowRows <= 0) return sg_view{};
    for (ShadowRowsSlot& s : shadowRowsRing)
        if (s.view.id && s.key == fr.shadowKey) {
            s.usedFrame = frameSerial;
            return s.view;
        }
    ShadowRowsSlot* victim = nullptr;
    if (shadowRowsRing.size() >= kShadowRowsRing) {
        for (ShadowRowsSlot& s : shadowRowsRing)
            if (s.usedFrame != frameSerial && (!victim || s.usedFrame < victim->usedFrame)) victim = &s;
    }
    if (!victim) {  // room left, or every slot is in use by a job of this frame: one more slot
        shadowRowsRing.emplace_back();
        victim = &shadowRowsRing.back();
    }
    ShadowRowsSlot& slot = *victim;
    if (slot.view.id) sg_destroy_view(slot.view);
    if (slot.img.id) sg_destroy_image(slot.img);
    sg_image_desc d{};
    d.width = kShadowAngles;
    d.height = fr.shadowRows;
    d.pixel_format = SG_PIXELFORMAT_RGBA8;
    d.data.mip_levels[0] = {fr.shadowData.data(), fr.shadowData.size()};
    d.label = "light-shadow-rows";
    slot.img = make_image(d);
    ++shadowRowUploads;
    sg_view_desc tv{};
    tv.texture.image = slot.img;
    tv.label = "light-shadow-rows-tex";
    slot.view = sg_make_view(&tv);
    slot.key = fr.shadowKey;
    slot.usedFrame = frameSerial;
    return slot.view;
}

// Called when a frame starts (nothing planned yet uses a slot; frameSerial is the new frame's, so the last one is
// frameSerial - 1): drops the slots a frame with many jobs added beyond what the scene keeps using, the least recently
// used first, so the memory is bounded again. The ring is kept as large as the most slots one frame used in the last
// kShadowTrimWindow frames (and at least kShadowRowsRing): trimming right back to kShadowRowsRing would upload the images
// beyond it again every frame of a scene with more stable keys than that.
void Renderer::Impl::trim_shadow_rows() {
    std::size_t usedLast = 0;
    for (const ShadowRowsSlot& s : shadowRowsRing)
        if (s.usedFrame + 1 == frameSerial) ++usedLast;
    shadowRowsPeak = std::max(shadowRowsPeak, usedLast);
    shadowRowsKeep = std::max(shadowRowsKeep, std::max(kShadowRowsRing, usedLast));
    if (++shadowRowsWindow >= kShadowTrimWindow) {  // a quiet window: the ring may shrink to what the window needed
        shadowRowsKeep = std::max(kShadowRowsRing, shadowRowsPeak);
        shadowRowsPeak = 0;
        shadowRowsWindow = 0;
    }
    while (shadowRowsRing.size() > shadowRowsKeep) {
        auto oldest = shadowRowsRing.begin();
        for (auto it = shadowRowsRing.begin(); it != shadowRowsRing.end(); ++it)
            if (it->usedFrame < oldest->usedFrame) oldest = it;
        if (oldest->view.id) sg_destroy_view(oldest->view);
        if (oldest->img.id) sg_destroy_image(oldest->img);
        shadowRowsRing.erase(oldest);
    }
}

void Renderer::Impl::destroy_light_resources() {
    for (ShadowRowsSlot& s : shadowRowsRing) {
        if (s.view.id) sg_destroy_view(s.view);
        if (s.img.id) sg_destroy_image(s.img);
    }
    shadowRowsRing.clear();
    shadowRowsKeep = kShadowRowsRing;
    shadowRowsPeak = 0;
    shadowRowsWindow = 0;
}

// Makes (or keeps) the image the colour filter draws into. False (and one logged error) when the GPU cannot make it:
// the game is then drawn without the filter. It is the frame's output while filterActive: present() and capture()
// sample it after the frame graph ran, so it is an imported target of the graph and not a transient of the pool.
bool Renderer::Impl::ensure_filter_target() {
    if (filterTarget.color.id) return true;
    TargetDesc d;
    d.label = "game-filtered";
    d.width = physW;
    d.height = physH;
    d.colorFormat = gpu.scene_format();
    filterTarget = make_target(d);
    if (!filterTarget.valid()) {
        FA_ERROR("render", "Camera.colorFilter: cannot create the {}x{} target; the game is drawn without the filter",
                 physW, physH);
        destroy_target(filterTarget);
        return false;
    }
    return true;
}

// Draws the finished game target through colorfilter.glsl into filterTarget (ensure_filter_target made it).
void Renderer::Impl::color_filter_pass(int mode) {
    PassDesc p = pass_into(filterTarget, "color-filter");
    p.colorLoad = SG_LOADACTION_DONTCARE;  // every pixel is drawn
    p.colorStore = SG_STOREACTION_STORE;
    gpu.begin_pass(p);
    sg_apply_pipeline(gpu.colorfilter_pipeline(p.format));
    sg_bindings b{};
    b.vertex_buffers[0] = gpu.fullscreen_triangle();
    b.views[VIEW_colorfilter_tex] = gameTarget.texView;
    b.samplers[SMP_colorfilter_smp] = gpu.sampler(SamplerKind::Nearest);
    sg_apply_bindings(&b);
    colorfilter_colorfilter_vs_params_t vu{};
    vu.flip[0] = gpu.is_gl() ? 1.0f : 0.0f;
    apply_uniforms(UB_colorfilter_colorfilter_vs_params, vu);
    colorfilter_colorfilter_params_t fu{};
    fu.p[0] = float(mode);
    apply_uniforms(UB_colorfilter_colorfilter_params, fu);
    sg_draw(0, 3, 1);
    gpu.end_pass();
    filterActive = true;
    ++stats.drawCalls;
}

// The 8-bit picture the screen shows. A gamma RGBA8 scene is read as it is. An SRGB8A8 scene holds the encoded bytes already (the GPU
// encoded them when they were drawn), so they are read as they are too, except `premultiplied` (a world capture on a transparent
// background): the colour must be un-premultiplied in linear light, which only the copy below does. Anything else (a float scene,
// a linear scene in plain RGBA8) goes through blit_keep, which encodes linear light to sRGB when the scene is linear.
bool Renderer::Impl::read_rgba8(sg_image image, sg_view view, int w, int h, std::vector<std::uint8_t>& out,
                                std::string* error, bool premultiplied) {
    const sg_pixel_format sf = gpu.scene_format();
    if ((sf == SG_PIXELFORMAT_RGBA8 && !gpu.linear()) || (sf == SG_PIXELFORMAT_SRGB8A8 && !premultiplied))
        return readback_rgba8(image, w, h, out, error);
    if (!readbackTarget.color.id || readW != w || readH != h) {
        free_read_image();
        TargetDesc d;
        d.label = "readback-rgba8";
        d.width = w;
        d.height = h;
        d.colorFormat = SG_PIXELFORMAT_RGBA8;
        d.texture = false;  // only drawn into and read back
        readbackTarget = make_target(d);
        if (!readbackTarget.valid()) {
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
    PassDesc p = pass_into(readbackTarget, "readback-rgba8");
    p.colorLoad = SG_LOADACTION_DONTCARE;  // every pixel is drawn
    p.colorStore = SG_STOREACTION_STORE;
    gpu.begin_pass(p);
    sg_apply_pipeline(gpu.blit_keep_pipeline(p.format));
    sg_bindings b{};
    b.vertex_buffers[0] = gpu.fullscreen_triangle();
    b.views[VIEW_blit_tex] = view;
    b.samplers[SMP_blit_smp] = gpu.sampler(SamplerKind::Nearest);
    sg_apply_bindings(&b);
    blit_blit_vs_params_t u{};
    u.flip[0] = gpu.is_gl() ? 1.0f : 0.0f;
    apply_uniforms(UB_blit_blit_vs_params, u);
    blit_blit_fs_params_t fu{};
    fu.encode[0] = gpu.linear() ? 1.0f : 0.0f;  // linear light -> the sRGB values the screen shows (see present())
    fu.encode[1] = premultiplied ? 1.0f : 0.0f;
    apply_uniforms(UB_blit_blit_fs_params, fu);
    sg_draw(0, 3, 1);
    gpu.end_pass();
    // The read-back waits for the GPU and on Metal only an sg_commit() submits the copy (see Renderer::capture()).
    sg_commit();
    gpu.note_commit();
    return readback_rgba8(readbackTarget.color, w, h, out, error);
}

// Makes (or keeps) the shadow map. False when the GPU cannot make it (or cannot do shadows): the frame is then drawn without
// shadows, with one logged warning, and the creation is not tried again until the game target is resized or rescaled
// (a missing shadow map would otherwise make the frame graph refuse every frame). FA_SHADOW_MAP=invalid is a test hook: it
// makes the creation fail on a GPU that never would.
bool Renderer::Impl::create_shadow_targets() {
    if (shadowTargetFailed || !gpu.shadows_supported()) return false;
    if (shadowTarget.color.id) return true;
    TargetDesc d;
    d.label = "shadow";
    d.width = d.height = kShadowSize;
    d.colorFormat = SG_PIXELFORMAT_R32F;
    d.depthFormat = SG_PIXELFORMAT_DEPTH;
    shadowTarget = make_target(d);
    const char* hook = std::getenv("FA_SHADOW_MAP");
    if (shadowTarget.valid() && !(hook && std::string(hook) == "invalid")) return true;
    destroy_target(shadowTarget);
    shadowTargetFailed = true;
    FA_WARN("render",
            "Cannot create the {}x{} shadow map (R32F colour + depth): the game is drawn without shadows "
            "(Light.castShadows has no effect on this GPU)",
            kShadowSize, kShadowSize);
    return false;
}

}  // namespace fa
