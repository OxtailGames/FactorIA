#include "material_cost.h"
#include "renderer_impl.h"
#include "renderer_test_access.h"
#include "fa/render/compute.h"
#include "scene2d.h"
#include "quality.h"
#include "render_features.h"
#include "render_scene.h"
#include "fa/scene/jitter.h"

#include <cstdlib>
#include <cstring>
#include <map>

namespace fa {

// ---------------------------------------------------------------------------
// RenderStats / DebugDraw
// ---------------------------------------------------------------------------
Json RenderStats::to_json() const {
    return Json{{"drawCalls", drawCalls},
                {"sprites", sprites},
                {"shapes", shapes},
                {"textGlyphs", textGlyphs},
                {"particles", particles},
                {"meshes", meshes},
                {"meshesCulled", meshesCulled},
                {"meshBatches", meshBatches},
                {"triangles", triangles},
                {"views", views},
                {"renderTargets", renderTargets},
                {"shadowCasters", shadowCasters},
                {"lights", lights},
                {"lightsDropped", lightsDropped},
                {"lightsCulled", lightsCulled},
                {"lightClusters", lightClusters},
                {"lightClusterEntries", lightClusterEntries},
                {"lightClusterClipped", lightClusterClipped},
                {"lightMaxPerCluster", lightMaxPerCluster},
                {"volumetricCameras", volumetricCameras},
                {"volumetricLights", volumetricLights},
                {"volumetricLightsDropped", volumetricLightsDropped},
                {"contactShadowLights", contactShadowLights},
                {"subsurfaceCameras", subsurfaceCameras},
                {"subsurfaceDraws", subsurfaceDraws},
                {"decals", decals},
                {"decalsDropped", decalsDropped},
                {"decalClusterClipped", decalClusterClipped},
                {"lights2d", lights2d},
                {"lights2dDropped", lights2dDropped},
                {"lights2dShadowed", lights2dShadowed},
                {"sceneCopies", sceneCopies},
                {"occluders", occluders},
                {"occlusionTests", occlusionTests},
                {"meshesOccluded", meshesOccluded},
                {"portalsVisited", portalsVisited},
                {"meshesCulledByArea", meshesCulledByArea},
                {"lodCrossFades", lodCrossFades},
                {"hlodProxies", hlodProxies},
                {"impostors", impostors},
                {"terrainTiles", terrainTiles},
                {"terrainTriangles", terrainTriangles},
                {"foliageInstances", foliageInstances},
                {"foliageInstancesCulled", foliageInstancesCulled},
                {"materials", materials},
                {"materialFallbacks", materialFallbacks},
                {"materialResolves", materialResolves},
                {"sortKeyFallbacks", sortKeyFallbacks},
                {"cpuMs", std::round(cpuMs * 1000.0) / 1000.0}};
}

DebugDraw::DebugDraw() : impl_(std::make_unique<Impl>()) {}
DebugDraw::~DebugDraw() = default;

void DebugDraw::line(Vec3 a, Vec3 b, Color c, float thickness) { impl_->lines.push_back({a, b, c, thickness}); }
void DebugDraw::rect(Rect r, Color c, bool filled) { impl_->rects.push_back({r, c, filled}); }
void DebugDraw::circle(Vec2 center, float radius, Color c, bool filled) {
    impl_->circles.push_back({center, radius, c, filled});
}
void DebugDraw::box(Vec3 center, Vec3 size, Color c) {
    Vec3 h = size * 0.5f;
    Vec3 p[8];
    for (int i = 0; i < 8; ++i) p[i] = center + Vec3{(i & 1) ? h.x : -h.x, (i & 2) ? h.y : -h.y, (i & 4) ? h.z : -h.z};
    static const int e[12][2] = {{0, 1}, {2, 3}, {4, 5}, {6, 7}, {0, 2}, {1, 3},
                                 {4, 6}, {5, 7}, {0, 4}, {1, 5}, {2, 6}, {3, 7}};
    for (auto& ed : e) line(p[ed[0]], p[ed[1]], c);
}
void DebugDraw::sphere(Vec3 center, float radius, Color c) {
    const int seg = 32;
    for (int axis = 0; axis < 3; ++axis) {
        for (int i = 0; i < seg; ++i) {
            float a0 = float(i) / seg * kTau, a1 = float(i + 1) / seg * kTau;
            auto pt = [&](float a) {
                float x = std::cos(a) * radius, y = std::sin(a) * radius;
                return axis == 0   ? Vec3{center.x, center.y + x, center.z + y}
                       : axis == 1 ? Vec3{center.x + x, center.y, center.z + y}
                                   : Vec3{center.x + x, center.y + y, center.z};
            };
            line(pt(a0), pt(a1), c);
        }
    }
}
void DebugDraw::text(Vec2 screenPos, std::string_view text, Color c, float size) {
    impl_->texts.push_back({screenPos, std::string(text), c, size});
}
void DebugDraw::clear() {
    impl_->lines.clear();
    impl_->rects.clear();
    impl_->circles.clear();
    impl_->texts.clear();
}

// The jitter phases of a camera (M76): 0 = the camera is not jittered. Jittered: its stack has TemporalAA on, the renderer draws that effect
// (post_drawn_mask), the camera is one of the game's frame (`mainFrameCamera`: a CameraView, a render-target camera and a capture draw
// no post stack, so nothing would resolve their jitter) and the TAA passes can run (shaders compiled, histories fit); or a test / pass
// forced it (jitterForce).
int Renderer::Impl::jitter_phases(const CameraInfo& ci, bool mainFrameCamera) {
    // M76-P4: the temporal upscaler jitters the frame's one camera by the sequence render() chose for the upscale ratio, whatever its stack.
    if (temporalPhases > 0 && mainFrameCamera) return std::min(temporalPhases, kJitterPhasesMax);
    if (jitterForce > 0) return std::clamp(jitterForce, 1, kJitterPhasesMax);
    const bool on = mainFrameCamera && ci.postStack && ci.postStack->has(PostEffect::TemporalAA) &&
                    ((post_drawn_mask() >> int(PostEffect::TemporalAA)) & 1u) != 0 && taa.ready() && !taa.unavailable();
    return on ? kJitterPhasesDefault : 0;
}

CameraInfo Renderer::Impl::build_camera(World& world, Entity best, const Vec2* viewSize, bool renderTarget,
                                        bool blended) {
    CameraTarget target;
    target.width = targetW;
    target.height = targetH;
    target.designWidth = desc.designWidth;
    target.designHeight = desc.designHeight;
    target.expand = scaleMode == ScaleMode::Expand;
    target.zeroToOne = gpu.depth_zero_to_one();
    CameraInfo ci;
    static_cast<CameraGeometry&>(ci) =
        camera_geometry(world, best, target, warnedViewport, viewSize, renderTarget, blended);
    Camera cam;  // defaults when no camera exists
    if (best) {
        cam = *world.get<Camera>(best);
        ci.studio = cam.lighting == CameraLighting::Studio;
        ci.areaCulling = cam.areaCulling;
        ci.studioIntensity = std::isfinite(cam.studioIntensity) ? std::clamp(cam.studioIntensity, 0.0f, 8.0f) : 1.0f;
    }
    ci.clearColor = cam.clearColor;
    ci.clear = cam.clear || viewSize != nullptr;
    // The editor's A/B switch (set_post_bypass): the picture as the scene draws it, with no stack, to compare it with the stack on.
    if (!postBypass && world.any<PostProcess>()) {
        auto stack = std::make_shared<PostStack>(resolve_post_stack(world, ci));
        if (qualityOn)
            apply_quality_limits(
                *stack, quality);  // the graphics preset: what the cameras may draw (the components are untouched)
        for (const Error& err : stack->customErrors)
            if (warnedCustomPass.insert(err.message).second) FA_WARN("render", "{} Hint: {}", err.message, err.hint);
        ci.bloom = bloom_from_stack(*stack);
        ci.colorFilter = stack->has(PostEffect::ColorFilter) ? std::clamp(int(stack->fx.colorFilterMode), 0, 5) : 0;
        if (stack->any()) ci.postStack = std::move(stack);
    }
    // The sub-pixel jitter of the temporal passes, on the DRAWN matrices only (CameraGeometry::apply_jitter): the frame index is the count of
    // the game's frames, so a run draws the same jitter on every machine. The size is the camera's image in render pixels.
    if (const int phases = jitter_phases(ci, viewSize == nullptr); phases > 0) {
        const float wPx = viewSize ? viewSize->x : float(physW) * ci.viewport.w;
        const float hPx = viewSize ? viewSize->y : float(physH) * ci.viewport.h;
        ci.apply_jitter(jitter_offset_pixels(postSerial, phases), wPx, hPx);
    }
    // The transient screen effects (shockwave, flash, fade ...) of this camera: not part of the stack, they work with the editor's A/B
    // switch on too (it compares the stack, not the game's own effects). The camera's own and those of every camera; a camera that
    // draws into a texture (a minimap, a mirror) only has the ones aimed at it, so a fade of the game does not black it out.
    for (const ScreenFx& e : world.feel().screenFx.live)
        if (best && e.camera == best)
            ci.screenFx.push_back(e);
        else if (!e.camera && !renderTarget)
            ci.screenFx.push_back(e);
    return ci;
}

// Every active camera with primary = true, ascending Camera.depth (equal depths keep the order of creation); a world without
// one gets a default camera.
std::vector<CameraInfo> Renderer::Impl::collect_cameras(World& world, bool blended) {
    std::size_t total = 0;
    const std::vector<Entity> found = rendering_cameras(world, &total);
    if (total > found.size() && !warnedCameras) {
        warnedCameras = true;
        FA_WARN("render",
                "{} cameras are active (primary) but a frame draws at most {}: the ones with the highest depth are "
                "left out. Hint: set primary to false on the cameras you do not need, e.g. when a split screen ends",
                total, found.size());
    }
    std::vector<CameraInfo> out;
    for (const Entity e : found) out.push_back(build_camera(world, e, nullptr, false, blended));
    if (out.empty()) out.push_back(build_camera(world, kNullEntity, nullptr, false, blended));
    return out;
}

// The real-pose cameras queries use while render interpolation blends a camera; none (queries use lastCams) otherwise. A camera is
// blended when it or an ancestor has a blended pose; when none is (the poses are other entities'), lastCams already is the real
// view and a second collect_cameras would repeat it.
void Renderer::Impl::refresh_logic_cameras(World& world) {
    logicCams.clear();
    const InterpState& ip = world.interp();
    if (ip.poseCount == 0) return;
    bool blended = false;
    for (const CameraInfo& c : lastCams) {
        for (Entity e = c.entity; !blended && !e.is_null(); e = world.parent(e)) blended = ip.pose_of(e) != nullptr;
        if (blended) break;
    }
    if (blended) logicCams = collect_cameras(world, false);
}

// Where the first camera is for scripts: its real pose (what Parallax.offset, and so entity.bounds() of a layer, follows).
Vec2 Renderer::Impl::logic_camera_xy() const {
    return (logicCams.empty() ? lastCams : logicCams).front().position.xy();
}

// The camera a query uses: `camera` when it is a rendering camera; else (a screen point given) the topmost camera whose
// viewport contains the point; else the first. `lastCams` is never empty after the first update().
const CameraInfo& Renderer::Impl::camera_for(Entity camera, const Vec2* screenPoint) const {
    static const CameraInfo kNone{};
    // Render interpolation: queries answer from the real pose of the cameras, drawing from the blended one (logicCams is empty
    // while no camera is blended).
    const CameraInfo* c = pick_camera(logicCams.empty() ? lastCams : logicCams, camera, screenPoint,
                                      Vec2{float(targetW), float(targetH)});
    return c ? *c : kNone;
}

// ---------------------------------------------------------------------------
// Renderer
// ---------------------------------------------------------------------------
// The sokol_gfx setup both open_context() and init() use: one place for the pool sizes.
sg_desc make_sg_desc(const GfxEnvironment& env) {
    sg_desc sd{};
    sd.environment = env.get();
    sd.logger.func = fa_sokol_log_func;
    sd.buffer_pool_size = 2048;
    sd.image_pool_size = 1024;
    sd.view_pool_size = 4096;
    sd.sampler_pool_size = 64;
    sd.shader_pool_size = 384;  // about 15 built-in shaders, up to 12 per custom material
    sd.pipeline_pool_size = 256;
    sd.uniform_buffer_size = 16 * 1024 * 1024;
    return sd;
}

Renderer::Renderer() : compute_(std::make_unique<Compute>()) {}
Renderer::~Renderer() { shutdown(); }

bool Renderer::initialized() const { return impl_ && impl_->initialized; }

bool Renderer::open_context(const GfxEnvironment& env, std::string* error) {
    if (sg_isvalid()) {
        if (error) *error = "a graphics context is already open";
        return false;
    }
    sg_desc sd = make_sg_desc(env);
    sg_setup(&sd);
    if (!sg_isvalid()) {
        if (error) *error = "sg_setup failed: the graphics device is not usable (see the 'sg' log lines).";
        return false;
    }
    return true;
}

bool Renderer::context_open() { return sg_isvalid(); }

void Renderer::close_context() {
    if (sg_isvalid()) sg_shutdown();
}

void Renderer::begin_window_pass(const GfxSwapchain& swapchain, Color clear) {
    const sg_swapchain& sc = swapchain.get();
    PassDesc pass = PassDesc::for_swapchain(sc);
    pass.label = "window";
    pass.colorLoad = SG_LOADACTION_CLEAR;
    pass.clearColor = {clear.r, clear.g, clear.b, clear.a};
    pass.colorStore = SG_STOREACTION_STORE;
    pass.depthLoad = SG_LOADACTION_CLEAR;  // what sokol did for the pass it was given (SG_LOADACTION_DEFAULT is CLEAR)
    pass.stencilLoad = SG_LOADACTION_CLEAR;
    Gpu::begin_pass(pass);
}

void Renderer::end_window_pass() { Gpu::end_pass(); }

bool Renderer::present_clear(const GfxSwapchain& swapchain, Color color) {
    if (!sg_isvalid()) return false;
    begin_window_pass(swapchain, color);
    end_window_pass();
    sg_commit();
    return true;
}

int Renderer::warm_step(const GfxSwapchain& swapchain, World& world) {
    if (!initialized() || impl_->desc.headless) return 0;
    Impl& im = *impl_;
    if (!im.warmBuilt) {
        im.warmBuilt = true;
        Gpu* gpu = &im.gpu;
        const TargetFormat presentFormat = PassDesc::for_swapchain(swapchain.get()).format;
        // Group order = what the first frames of a game need first. Every pipeline is keyed deterministically in Gpu, so a
        // frame that needs one before its group ran makes it itself, the same pipeline.
        im.warmGroups.push_back([gpu, presentFormat] { gpu->blit_pipeline(presentFormat); });
        // A game that asks for HDR on a backend that has it: the copy into the RGBA16F swapchain (scRGB, EDR) is made before the
        // window switches to it, not on the frame it does. D3D11 also falls back to the 10-bit swapchain (HDR10) where the driver
        // refuses scRGB: that copy is made too (without multisampling: a 10-bit swapchain has no multisampled image, so such a
        // window never takes it).
        const render::FeatureBackend backend = render::feature_env_from_sokol().backend;
        if (world.settings().hdrOutput == HdrOutput::Auto &&
            (backend == render::FeatureBackend::Metal || backend == render::FeatureBackend::D3d11)) {
            const TargetFormat hdrFormat{SG_PIXELFORMAT_RGBA16F, presentFormat.depth, presentFormat.samples};
            im.warmGroups.push_back([gpu, hdrFormat] { gpu->blit_pipeline(hdrFormat); });
            if (backend == render::FeatureBackend::D3d11 && presentFormat.samples <= 1) {
                const TargetFormat hdr10Format{SG_PIXELFORMAT_RGB10A2, presentFormat.depth, presentFormat.samples};
                im.warmGroups.push_back([gpu, hdr10Format] { gpu->blit_pipeline(hdr10Format); });
            }
        }
        im.warmGroups.push_back([gpu] {
            gpu->quad_pipeline(false, false, BlendMode::Alpha);
            gpu->quad_pipeline(false, false, BlendMode::Alpha, true);
            gpu->quad_pipeline(false, false, BlendMode::Alpha, true, true);
        });
        im.warmGroups.push_back([gpu] {
            gpu->quad_pipeline(false, false, BlendMode::Additive);
            gpu->quad_pipeline(false, false, BlendMode::Multiply);
            gpu->quad_pipeline(false, true, BlendMode::Alpha);
        });
        // The first screenshot (a float scene is read back through blit_keep) must not build its pipeline on the main thread.
        // The format is read when the group runs: the targets may still fall back to RGBA8, which needs no such copy.
        im.warmGroups.push_back([gpu] {
            if (gpu->scene_format() != SG_PIXELFORMAT_RGBA8) gpu->blit_keep_pipeline();
        });
        // The shaders and pipelines of Water2D and DistortionZone2D (a sprite material that calls fa_scene_color() makes them on its first
        // draw): only where the scene has one of them, so a scene without pays no compile.
        if (world.any<Water2D>() || world.any<DistortionZone2D>()) {
            Impl* impl = &im;
            im.warmGroups.push_back([impl] {
                if (impl->game_targets_valid())
                    impl->waterFx.warm(impl->gpu, pass_into(impl->gameTarget, "warm").format);
            });
        }
        bool meshes = false;
        world.each<MeshRenderer>([&](Entity, MeshRenderer&) { meshes = true; });
        if (meshes) {
            const bool shadows = gpu->shadows_supported();
            // The skinned programs (the mesh fragment shader again, ~100 KB of GLSL) only where a mesh can be drawn
            // skinned: an entity with an Animator. One added later makes them on its first draw.
            bool animated = false;
            world.each<Animator>([&](Entity, Animator&) { animated = true; });
            im.warmGroups.push_back([gpu] {
                gpu->mesh_pipeline(false, false);
                gpu->mesh_pipeline(false, true);
            });
            im.warmGroups.push_back([gpu] {
                gpu->mesh_pipeline(true, false);
                gpu->mesh_pipeline(true, true);
                gpu->mesh_pipeline(true, false, false, {}, {}, true);
                gpu->quad_pipeline(true, false, BlendMode::Alpha);
            });
            im.warmGroups.push_back([gpu, animated] {
                gpu->sky_pipeline();
                if (animated) gpu->mesh_pipeline(false, false, true);
            });
            if (shadows) {
                im.warmGroups.push_back([gpu, animated] {
                    gpu->shadow_pipeline(false);
                    if (animated) gpu->shadow_pipeline(true);
                });
            }
            // The prepass with the velocity image (M76): its pipelines have two colour attachments, so they are not the ones of a camera
            // that only reads the depth. Only where a PostProcess asks for temporal antialiasing, the effect that reads it; the engine's
            // programs of a mesh drawn as it is (one sided and double sided, skinned where an entity has an Animator).
            bool temporal = false;
            world.each<PostProcess>([&](Entity, PostProcess& p) { temporal = temporal || p.temporalAAEnabled; });
            if (temporal) {
                im.warmGroups.push_back([gpu, animated] {
                    if (!gpu->velocity_ready()) return;
                    const TargetFormat f = gpu->prepass_target_format(true);
                    for (const bool doubleSided : {false, true}) {
                        gpu->prepass_pipeline(f, doubleSided, false, {}, {});
                        if (animated) gpu->prepass_pipeline(f, doubleSided, true, {}, {});
                    }
                });
            }
        }
    }
    if (im.warmNext >= im.warmGroups.size()) return 0;
    // As many groups as fit in about 8 ms of this window frame (at least one): where a pipeline costs a few ms (GL, GLES, WebGL
    // link in the driver) a group per frame would add ~100 ms of black frames, where it costs microseconds (Metal) the whole
    // warm-up fits in one frame. The budget decides only HOW MANY frames the warm-up takes, never what it makes: the groups
    // run in the same order and every pipeline is keyed in Gpu, so pictures and game state do not depend on it. It is wall time
    // of the window host, outside the simulation (no game frame runs meanwhile).
    constexpr double kFrameBudgetMs = 8.0;
    const auto t0 = std::chrono::steady_clock::now();
    const std::size_t before = im.gpu.pipeline_count();
    do {
        im.gpu.set_warming(true);  // the warm-up's pipelines are never evicted (Gpu::set_warming)
        im.warmGroups[im.warmNext++]();
        im.gpu.set_warming(false);
    } while (im.warmNext < im.warmGroups.size() &&
             std::chrono::duration<double, std::milli>(std::chrono::steady_clock::now() - t0).count() < kFrameBudgetMs);
    im.warmPipelines += im.gpu.pipeline_count() - before;
    im.warmMs += std::chrono::duration<double, std::milli>(std::chrono::steady_clock::now() - t0).count();
    return int(im.warmGroups.size() - im.warmNext);
}

Json Renderer::startup_report() const {
    Json j = shader_build_stats().to_json(backend_name());
    j["cache"] = shader_cache_mode();
    if (impl_) {
        j["pipelinesWarmed"] = int(impl_->warmPipelines);
        j["pipelines"] = int(impl_->gpu.pipeline_count());
        j["pipelineHits"] = std::int64_t(impl_->gpu.pipeline_hits());
        j["pipelinesMade"] = std::int64_t(impl_->gpu.pipelines_made());
        j["pipelinesEvicted"] = std::int64_t(impl_->gpu.pipelines_evicted());
        j["warmMs"] = std::round(impl_->warmMs * 10.0) / 10.0;
        j["groupsLeft"] = int(impl_->warmGroups.size() - std::min(impl_->warmNext, impl_->warmGroups.size()));
    }
    return j;
}

bool Renderer::init(const RendererDesc& desc, const GfxEnvironment& env, std::string* error) {
    if (initialized()) return true;
    impl_ = std::make_unique<Impl>();
    Impl& im = *impl_;
    im.desc = desc;
    if (const char* dv = std::getenv("FA_RENDER_DEBUG_VIEW"))
        im.debugView = std::strcmp(dv, "depth") == 0           ? DebugView::Depth
                       : std::strcmp(dv, "normals") == 0       ? DebugView::Normals
                       : std::strcmp(dv, "ao") == 0            ? DebugView::Ao
                       : std::strcmp(dv, "cascades") == 0      ? DebugView::Cascades
                       : std::strcmp(dv, "occlusion") == 0     ? DebugView::Occlusion
                       : std::strcmp(dv, "motionVectors") == 0 ? DebugView::MotionVectors
                                                               : DebugView::None;
    im.adopted = desc.adoptContext && sg_isvalid();
    if (!im.adopted) {
        sg_desc sd = make_sg_desc(env);
        sg_setup(&sd);
    }
    if (!sg_isvalid()) {
        if (error) *error = "sg_setup failed: the graphics device is not usable (see the 'sg' log lines).";
        impl_.reset();
        return false;
    }
    int samples = std::max(1, desc.sampleCount);
    if (samples > 1 && !sg_query_pixelformat(SG_PIXELFORMAT_RGBA8).msaa) {
        FA_WARN("render", "MSAA is not supported by this device; falling back to sampleCount 1");
        samples = 1;
    }
    std::string gerr;
    if (!im.gpu.init(samples, &gerr)) {
        if (error) *error = gerr;
        if (!im.adopted) sg_shutdown();
        impl_.reset();
        return false;
    }
    im.assets = std::make_unique<Assets>(im.gpu);
    compute_->attach(&im.gpu, im.assets.get());
    im.compute = compute_.get();
    im.assets->set_shader_compiler(shaderCompiler_);
    Impl* impl = &im;
    im.assets->set_target_resolver([impl](const std::string& name) { return impl->resolve_target(name); });
    im.fonts = std::make_unique<Fonts>(im.gpu, *im.assets);
    im.fonts->set_fallback_fonts(fallbackFonts_);
    im.fonts->set_rich_style(richStyle_);
    im.textScale = textScale_;
    im.uiScale = uiScale_;
    im.create_targets(desc.designWidth, desc.designHeight);
    im.initialized = true;
    return true;
}

void Renderer::shutdown() {
    if (!impl_) return;
    Impl& im = *impl_;
    im.unwatch_world();
    if (im.initialized) {
        compute_->detach();  // its storage buffers and views, while the context is open
        // Work recorded since the last frame (a dispatch, the clearing pass of a new storage image) that no frame ever
        // submitted: Metal waits for the completion of every frame it began at sg_shutdown, so an uncommitted one would
        // wait forever. Precondition: no pass is open (shutdown is never called between begin_frame and the frame's
        // end): sg_commit inside a pass is invalid in sokol.
        FA_ASSERT(!Gpu::in_pass(), "Renderer::shutdown while a pass is open");
        if (!im.gpu.committed()) {
            sg_commit();
            im.gpu.note_commit();
        }
        im.fonts.reset();
        im.ssr.release();
        im.xmit.release();
        im.waterFx.release();
        im.skyEnv.release();
        im.probes_release();
        im.hiz_release();
        im.physSky.release();
        im.hdriSky.release();
        im.sceneFx.release();
        im.taa.release();
        im.spatial.release();
        im.gi2d.release();
        im.fogFx.release();
        im.volFx.release();
        im.sssFx.release();
        im.ramps.destroy();
        im.terrains.destroy();
        im.impostors.destroy();
        im.foliage.destroy();
        im.assets.reset();
        destroy_target(
            im.velocityProbe);  // the test copy of the velocity image (RendererTestAccess::read_velocity), if a test made one
        im.destroy_targets();
        im.transients.reset();  // its pool destroys the targets it still holds: the context is still open
        im.destroy_light_resources();
        im.lightAtlas.destroy();  // its images are destroyed with the context still open
        im.destroy_decal_atlas();
        destroy_target(im.shadowTarget);
        im.free_retired_shadow_targets();
        im.gpu.shutdown();
        if (!im.adopted)
            sg_shutdown();  // an adopted context stays open for close_context(): the player may still present
    }
    impl_.reset();
}

void Renderer::set_target_size(int width, int height) {
    if (!initialized()) return;
    if (width == impl_->targetW && height == impl_->targetH) return;
    impl_->shadowTargetFailed = false;  // a shadow map that could not be made is tried again after a resize
    impl_->create_targets(width, height);
}
void Renderer::set_render_scale(float scale) {
    if (!initialized()) return;
    if (!(scale >= kMinRenderScale)) scale = 1.0f;
    scale = std::min(scale, kMaxRenderScale);
    if (scale == impl_->renderScale) return;
    impl_->renderScale = scale;
    impl_->shadowTargetFailed = false;
    impl_->create_targets(impl_->targetW, impl_->targetH);
}
void Renderer::set_upscale_stage(bool on) {
    if (!initialized() || impl_->upscaleStage == on) return;
    impl_->upscaleStage = on;
    impl_->free_output_targets();
}
bool Renderer::upscale_stage() const { return impl_ && impl_->upscaleStage; }
void Renderer::set_upscaler(const render::UpscalerSettings& settings) { impl_->upscaler = settings; }
const render::UpscalerSettings& Renderer::upscaler() const { return impl_->upscaler; }
void Renderer::set_quality(const render::QualityLimits& limits) {
    impl_->quality = limits;
    impl_->qualityOn = limits != render::QualityLimits{};
}
const render::QualityLimits& Renderer::quality() const { return impl_->quality; }
render::QualityResolved Renderer::resolve_graphics_preset(render::GraphicsPreset preset) const {
    render::FeatureEnv env;  // headless (no GPU) until the renderer has one
    if (initialized()) env = render::feature_env_from_sokol();
    return render::resolve_quality(preset, env);
}
render::UpscalerCaps Renderer::upscaler_caps() const { return impl_ ? impl_->upscaler_caps() : render::UpscalerCaps{}; }
render::UpscalerMode Renderer::effective_upscaler_mode() const {
    return impl_ ? impl_->effective_upscaler_mode() : render::UpscalerMode::Stretch;
}
float Renderer::render_scale() const { return impl_ ? impl_->renderScale : 1.0f; }
const char* Renderer::backend_name() {
    switch (sg_query_backend()) {
        case SG_BACKEND_GLCORE: return "glcore";
        case SG_BACKEND_GLES3: return "gles3";
        case SG_BACKEND_D3D11: return "d3d11";
        case SG_BACKEND_METAL_IOS:
        case SG_BACKEND_METAL_MACOS:
        case SG_BACKEND_METAL_SIMULATOR: return "metal";
        case SG_BACKEND_DUMMY: return "dummy";
        default: return "unknown";  // wgpu / vulkan: the engine never builds those sokol backends
    }
}
int Renderer::target_width() const { return impl_ ? impl_->targetW : 0; }
int Renderer::target_height() const { return impl_ ? impl_->targetH : 0; }

void Renderer::begin_frame() {
    if (!initialized()) return;
    impl_->inFrame = true;
    impl_
        ->hiz_submit();  // before sokol's frame begins: the copy of the last depth pyramid is queued after the frame that made it
    impl_->gpu.begin_frame();
}

void Renderer::note_commit() {
    if (initialized()) impl_->gpu.note_commit();
}

DebugDraw& Renderer::debug() {
    static DebugDraw dummy;
    return impl_ ? impl_->debug : dummy;
}
bool is_post_pass(std::string_view passName) {
    const std::size_t slash = passName.rfind('/');
    const std::string_view n = slash == std::string_view::npos ? passName : passName.substr(slash + 1);
    if (n == "post" || n == "post-base" || n.substr(0, 9) == "post-part")
        return true;  // a camera's final pass (or a piece of it, cut by a custom pass), and the pass under the cameras' rectangles
    // A pass is an effect's when its name is the effect's or `<effect>-<what>`; "fogbank" or "taaa" are not.
    for (std::string_view effect : {"bloom", "exposure", "ssao", "dof", "ssr", "motion", "fog", "shafts", "radial",
                                    "taa", "color-filter", "custom"})
        if (n == effect ||
            (n.size() > effect.size() && n.substr(0, effect.size()) == effect && n[effect.size()] == '-'))
            return true;
    return false;
}

PostPassTimes post_pass_times(const RenderStats& st) {
    PostPassTimes out;
    for (const RenderStats::PassTime& p : st.passes) {
        if (!is_post_pass(p.name)) continue;
        out.cpuMs += p.cpuMs;
        if (p.gpuMs >= 0.0) out.gpuMs = std::max(out.gpuMs, 0.0) + p.gpuMs;
        out.passes.push_back(p);
    }
    return out;
}

RenderStats Renderer::stats(bool passTimes) const {
    if (!impl_) return RenderStats{};
    RenderStats s = impl_->stats;
    if (impl_->assets) s.materialResolves = int(impl_->assets->material_resolves());
    if (passTimes && impl_->passTimesPending) impl_->pass_times(s.passes, s.jobs);
    return s;
}
std::uint32_t Renderer::game_target_image_id() const { return impl_ ? impl_->display_image().id : 0; }
std::uint32_t Renderer::game_target_view_id() const { return impl_ ? impl_->display_view().id : 0; }
void Renderer::set_editor_view(bool on) {
    if (!impl_) return;
    impl_->editorView = on;
    if (!on) destroy_target(impl_->editorTarget);
}
bool Renderer::hdr_scene() const { return impl_ && impl_->gpu.scene_is_float(); }

void Renderer::reload_asset(std::string_view path) {
    if (impl_ && impl_->assets) impl_->assets->reload(std::string(path));
    if (impl_) impl_->lightAtlas.invalidate(fs::normalize(path));  // a cookie or an IES profile of the light atlas
    invalidate_sprite_outlines(path);  // a SpriteSkin outline traced from the old picture is stale
}
void Renderer::set_shader_compiler(ShaderCompiler compiler) {
    shaderCompiler_ = std::move(compiler);
    if (impl_ && impl_->assets) impl_->assets->set_shader_compiler(shaderCompiler_);
}
std::string Renderer::shader_dialect() const {
    return initialized() ? backend_dialect(sg_query_backend()) : std::string();
}
void Renderer::clear_asset_cache() {
    if (!impl_ || !impl_->assets) return;
    impl_->fonts->clear();
    impl_->instanceParams.clear();       // it points at materials the cache below frees
    impl_->lightAtlas.invalidate_all();  // the project changed: cookies and profiles are read again
    impl_->assets->clear();
}
Renderer::TerrainUploads Renderer::terrain_uploads() const {
    TerrainUploads out;
    if (impl_) {
        out.whole = impl_->terrains.uploads();
        out.rects = impl_->terrains.rect_uploads();
        out.arrays = impl_->terrains.layer_builds();
        out.splatRects = impl_->terrains.splat_rect_uploads();
        out.layerLoads = impl_->terrains.layer_loads();
        out.holesWhole = impl_->terrains.holes_uploads();
        out.holesRects = impl_->terrains.holes_rect_uploads();
    }
    return out;
}

bool Renderer::terrain_loading() const { return impl_ && impl_->terrains.loading(); }
void Renderer::wait_terrain_loaded() {
    if (impl_) impl_->terrains.wait_loaded();
}

bool Renderer::foliage_loading() const { return impl_ && impl_->foliage.loading(); }
void Renderer::wait_foliage_loaded() {
    if (impl_) impl_->foliage.wait_loaded();
}
std::uint64_t Renderer::foliage_loads() const { return impl_ ? impl_->foliage.loads() : 0; }

std::uint64_t Renderer::texture_bytes() const {
    return impl_ && impl_->assets ? impl_->assets->texture_bytes() + impl_->ramps.bytes() + impl_->terrains.bytes() +
                                        impl_->foliage.bytes() + impl_->decalAtlas.bytes
                                  : 0;
}

bool Renderer::gpu_timing_supported(std::string* reason) const {
    if (!impl_) {
        if (reason) *reason = "the renderer is not initialized";
        return false;
    }
    const bool ok = impl_->gpuTimer.supported();
    if (!ok && reason) *reason = impl_->gpuTimer.reason();
    return ok;
}

void Renderer::take_gpu_ms(std::vector<double>& out) {
    if (!impl_ || !Profiler::on()) return;
    impl_->gpuTimer.poll(impl_->gpuFrames);  // render() polls too: what it read waits in gpuFrames for this call
    out.insert(out.end(), impl_->gpuFrames.begin(), impl_->gpuFrames.end());
    impl_->gpuFrames.clear();
}

bool Renderer::supports(std::string_view feature) const {
    if (!initialized()) return false;
    const int index = render::find_feature(feature);
    if (index < 0) return false;
    render::FeatureEnv env = render::feature_env_from_sokol();
    render::set_hdr_env(env, app_hdr_output().display);
    return render::feature_supported(env, index);
}
std::vector<std::string> Renderer::feature_names() { return fa::render::feature_names(); }
Json Renderer::supports_report() const {
    if (!initialized()) return Json::object();
    render::FeatureEnv env = render::feature_env_from_sokol();
    render::set_hdr_env(env, app_hdr_output().display);
    return render::feature_report(env, backend_name());
}

const ProbeSet* Renderer::light_probes(World& world) {
    if (!initialized() || !impl_->assets || world.settings().lightmaps.empty()) return nullptr;
    const LightmapSetAsset* set = impl_->assets->lightmaps(world.settings().lightmaps);
    return set && set->probes.size() > 0 ? &set->probes : nullptr;
}

namespace {
const double kRoundTo = 1000.0;
double rounded(double v) { return std::round(v * kRoundTo) / kRoundTo; }
Json vec3_json(Vec3 v) { return Json::array({rounded(v.x), rounded(v.y), rounded(v.z)}); }
}  // namespace

Json Renderer::light_probes_report(World& world, Entity entity) {
    Json j = Json::object();
    j["lightmaps"] = world.settings().lightmaps;
    const ProbeSet* set = light_probes(world);
    j["baked"] = set != nullptr && set->baked();
    j["probes"] = set ? int(set->size()) : 0;
    j["invalid"] = set ? int(set->invalid_count()) : 0;
    Json groups = Json::array();
    // What the scene's LightProbeGroups ask for now, to tell a baked group that was edited since (stale) from one still as baked.
    ProbeSet scene;
    const bool sceneKnown = set && static_cast<bool>(collect_probe_groups(world, scene));
    if (set)
        for (const ProbeGroup& g : set->groups) {
            int bad = 0;
            for (int i = 0; i < g.count; ++i)
                if (set->baked() && !set->valid[std::size_t(g.first + i)]) ++bad;
            Json item = Json::object({{"id", g.id},
                                      {"kind", g.kind == ProbeGroupKind::Grid ? "grid" : "points"},
                                      {"count", g.count},
                                      {"invalid", bad}});
            if (sceneKnown) item["stale"] = find_same_probe_group(scene, *set, g) == nullptr;
            groups.push_back(std::move(item));
        }
    j["groups"] = std::move(groups);
    if (sceneKnown) {
        // Groups of the scene the file does not hold (added or edited since the bake): they are not lit by probes until the next bake.
        Json unbaked = Json::array();
        for (const ProbeGroup& g : scene.groups)
            if (!find_same_probe_group(*set, scene, g)) unbaked.push_back(g.id);
        j["unbaked"] = std::move(unbaked);
    }
    if (entity == kNullEntity) return j;
    Json e =
        Json::object({{"id", world.id_of(entity)},
                      {"name", world.get<EntityInfo>(entity) ? world.get<EntityInfo>(entity)->name : std::string()}});
    const MeshRenderer* mr = world.get<MeshRenderer>(entity);
    if (!mr) {
        e["source"] = "none";
        e["note"] = "The entity has no MeshRenderer: only meshes receive light probes.";
        j["entity"] = std::move(e);
        return j;
    }
    Assets& assets = *impl_->assets;
    MeshAsset* mesh = assets.mesh(mr->mesh);
    const Animator* anim = nullptr;
    Vec3 bmin{0, 0, 0}, bmax{0, 0, 0};
    mesh_cull_bounds(*mesh, world.get<Animator>(entity), bmin, bmax, anim);
    const Mat4 model = world.drawn_matrix(entity);
    const Vec3 at = probe_point(world, *mr, model, bmin, bmax);
    e["position"] = vec3_json(at);
    MaterialAsset* material = mr->material.empty() ? nullptr : assets.material(mr->material);
    if (material && material->ok && material->kind != MaterialKind::Mesh) material = nullptr;
    const LightmapSetAsset* lightmaps =
        world.settings().lightmaps.empty() ? nullptr : assets.lightmaps(world.settings().lightmaps);
    const bool materialReads =
        !material || (material->ok && !material->full && material->buffers.empty() && material->uv1);
    LightmapUse lm;
    if (lightmaps && mr->receiveGI && mr->lightmapScale > 0.0f && materialReads && !anim) {
        static const std::string kCube = "cube";  // not a std::string made for every entity of every frame
        assets.lightmap_use(*lightmaps, world.id_of(entity), *mesh, mr->mesh.empty() ? kCube : mr->mesh, lm);
    }
    const bool eligible = set && set->baked() && mr->receiveGI && !mr->unlit && !lm.mesh &&
                          (!material || (material->ok && !material->full && material->buffers.empty()));
    ProbeLight light;
    if (eligible) light = probe_light_at(*set, at);
    e["source"] = lm.mesh ? "lightmap" : (eligible && light.coverage > 0.0f ? "probes" : "sky");
    e["coverage"] = rounded(light.coverage);
    e["probesUsed"] = light.probesUsed;
    if (eligible && light.coverage > 0.0f) {
        Json sh = Json::array();
        for (const Vec3& c : light.sh.c) sh.push_back(vec3_json(c));
        e["sh"] = std::move(sh);
        // The diffuse light (irradiance / pi) it gets from the six axis directions: what the probes add to a surface facing that way.
        Json amb = Json::object();
        const std::pair<const char*, Vec3> dirs[] = {{"up", {0, 1, 0}},    {"down", {0, -1, 0}},  {"east", {1, 0, 0}},
                                                     {"west", {-1, 0, 0}}, {"north", {0, 0, -1}}, {"south", {0, 0, 1}}};
        for (const auto& [name, d] : dirs) amb[name] = vec3_json(sh_irradiance(light.sh, d));
        e["ambient"] = std::move(amb);
    } else if (!lm.mesh) {
        e["note"] = !mr->receiveGI
                        ? "MeshRenderer.receiveGI is false."
                        : (!set ? "The scene has no baked light probes (lightmap.bake with a LightProbeGroup)."
                                : "No probe reaches the mesh: it keeps the sky's ambient.");
    }
    j["entity"] = std::move(e);
    return j;
}

void Renderer::update_output(const SceneSettings& settings, const std::string& blocked) {
    if (!initialized()) return;
    Impl& im = *impl_;
    if (!im.backendKnown) {  // the backend never changes once the context is open: asked once, not every frame
        im.backend = render::feature_env_from_sokol().backend;
        im.backendKnown = true;
    }
    // Called every frame: the request is kept and changed only where a value differs (a string is compared, never assigned, when it
    // is the same), so a game that does not want HDR (the common case) builds no string here and the platform answers "unchanged".
    const bool want = settings.hdrOutput == HdrOutput::Auto;
    HdrRequest& request = im.outputRequest;
    if (!im.outputRequestMade) {
        request = render::hdr_request(im.backend, want, settings.paperWhiteNits);
        im.outputRequestMade = true;
        // The window's switch belongs to the process, not to this renderer: a second renderer starts from what the window
        // shows, since the platform answers "unchanged" (and fills nothing) while the request is the one of its last update.
        im.outputInfo = app_hdr_output();
    }
    request.want = want;
    request.paperWhiteNits = settings.paperWhiteNits;
    if (request.blocked != blocked) request.blocked = blocked;
    // What the status adds while an HDR encoding is on and the picture still stays within paper white (the last frame's); nothing
    // is on when HDR is not wanted.
    const char* note = "";
    if (want) {
        if (!im.float_display())
            note = im.gpu.scene_format() == SG_PIXELFORMAT_RG11B10F
                       ? "the scene is in R11G11B10, which holds the final picture in 8 bits, so it stays within paper "
                         "white"
                       : "this GPU draws the picture in 8 bits, so it stays within paper white";
        else if (!im.frameAboveWhite)
            note = "the picture stays within paper white: only the tonemap of a PostProcess (exposure or tonemap, "
                   "no colour filter) goes above it";
    }
    if (request.activeNote != note) request.activeNote = note;
    app_update_hdr_output(request, im.outputInfo);
}

HdrOutputInfo Renderer::output_info() const { return app_hdr_output(); }

void Renderer::set_post_bypass(bool bypass) {
    if (impl_) impl_->postBypass = bypass;
}
bool Renderer::post_bypass() const { return impl_ && impl_->postBypass; }

Json Renderer::frame_graph_report() const {
    if (!impl_ || !(impl_->anyFrameRendered || impl_->graphFromCapture)) return Json();
    Impl& I = *impl_;
    auto r3 = [](double v) { return std::round(v * 1000.0) / 1000.0; };
    std::vector<RenderStats::PassTime> passes;
    std::vector<RenderStats::JobTime> jobs;
    I.pass_times(passes, jobs);
    Json out = Json::object();
    out["source"] = I.graphFromCapture ? "capture" : "frame";
    out["backend"] = backend_name();
    out["graph"] = I.graph.to_json();
    Json passList = Json::array();
    bool anyGpu = false;
    for (const RenderStats::PassTime& p : passes) {
        anyGpu = anyGpu || p.gpuMs >= 0.0;
        passList.push_back(
            Json::object({{"name", p.name}, {"job", p.job}, {"cpuMs", r3(p.cpuMs)}, {"gpuMs", r3(p.gpuMs)}}));
    }
    out["passTimes"] = std::move(passList);
    Json jobList = Json::array();
    for (const RenderStats::JobTime& j : jobs)
        jobList.push_back(
            Json::object({{"job", j.job}, {"passes", j.passes}, {"cpuMs", r3(j.cpuMs)}, {"gpuMs", r3(j.gpuMs)}}));
    out["jobTimes"] = std::move(jobList);
    Json gpu = Json::object();
    std::string why;
    const bool supported = I.gpuTimer.supported();
    const bool measuring = supported && Profiler::on();
    if (!supported)
        why = I.gpuTimer.reason();
    else if (!measuring)
        why =
            "the profiler is off and the GPU timers only run while it is on (perf.profile, play.report's profile, the "
            "editor's Profiler panel; render.frame_graph switches it on for its own call when profileFrames is above "
            "0)";
    else if (!anyGpu)
        why = "no GPU time has come back yet: timer queries are read a few frames late, so draw a few more frames with "
              "the profiler on (render.frame_graph's profileFrames: up to 60)";
    gpu["supported"] = supported;
    gpu["measuring"] = measuring;
    gpu["reason"] = why.empty() ? Json(nullptr) : Json(why);
    gpu["maxTimedPasses"] = GpuTimer::kMaxTimedPasses;
    out["gpu"] = std::move(gpu);
    // The post-processing passes on their own: each with its times and their sum. A GPU time that does not exist is null with the
    // reason ("unavailable"), never 0. The effects folded into the `post` pass share its time: they are not timed one by one.
    {
        RenderStats st;
        st.passes = passes;
        const PostPassTimes post = post_pass_times(st);
        Json pl = Json::array();
        for (const RenderStats::PassTime& p : post.passes)
            pl.push_back(Json::object({{"name", p.name},
                                       {"job", p.job},
                                       {"cpuMs", r3(p.cpuMs)},
                                       {"gpuMs", p.gpuMs >= 0.0 ? Json(r3(p.gpuMs)) : Json(nullptr)}}));
        std::size_t timed = 0;
        for (const RenderStats::PassTime& p : post.passes) timed += p.gpuMs >= 0.0 ? 1 : 0;
        Json pp = Json::object();
        pp["passes"] = std::move(pl);
        pp["gpuPassesTimed"] = timed;
        // A total over only some of the passes is a lower bound, never the whole cost: say so.
        pp["gpuPartial"] = timed > 0 && timed < post.passes.size();
        pp["cpuMs"] = r3(post.cpuMs);
        pp["gpuMs"] = post.gpuMs >= 0.0 ? Json(r3(post.gpuMs)) : Json(nullptr);
        pp["gpuStatus"] = post.gpuMs >= 0.0 ? "measured" : "unavailable";
        pp["gpuReason"] = post.gpuMs >= 0.0     ? Json(nullptr)
                          : post.passes.empty() ? Json("this frame has no post-processing pass")
                          : !why.empty()        ? Json(why)
                                                : Json("the GPU timer has no answer for these passes yet");
        pp["note"] = "The sum of the passes named bloom-*, exposure-*, post and the other effect passes (prepass and "
                     "sprite-coverage "
                     "are not counted). Effects folded into the single `post` pass (vignette, grain, grading, sharpen, "
                     "outline, ...) "
                     "have no time of their own: `post` is their total.";
        out["postProcess"] = std::move(pp);
    }
    return out;
}

Json Renderer::asset_report() const {
    if (!impl_ || !impl_->assets) return Json::object();
    Json j = impl_->assets->report();
    j["fonts"] = impl_->fonts->report();
    return j;
}

Json Renderer::material_cost(const MeshRenderer& mr) {
    if (!impl_ || !impl_->assets) return Json::object();
    const render::MeshAsset* mesh = mr.mesh.empty() ? nullptr : impl_->assets->mesh(mr.mesh);
    const render::MaterialAsset* material = mr.material.empty() ? nullptr : impl_->assets->material(mr.material);
    if (material && !material->ok) material = nullptr;
    return render::material_cost_report(mr, mesh, material, impl_->physW, impl_->physH);
}

// ---- camera helpers ----
Vec2 Renderer::world_to_screen(Vec3 p, Entity camera) const {
    if (!impl_) return {};
    return impl_->camera_for(camera, nullptr).world_to_screen(p, Vec2{float(impl_->targetW), float(impl_->targetH)});
}

void Renderer::screen_ray(Vec2 s, Vec3& origin, Vec3& dir, Entity camera) const {
    origin = {};
    dir = kForward;
    if (!impl_) return;
    impl_->camera_for(camera, &s).screen_ray(s, Vec2{float(impl_->targetW), float(impl_->targetH)}, origin, dir);
}

Vec3 Renderer::screen_to_world(Vec2 s, float depth, Entity camera) const {
    if (!impl_) {
        Vec3 o, d;
        screen_ray(s, o, d, camera);
        return o;
    }
    return impl_->camera_for(camera, &s).screen_to_world(s, Vec2{float(impl_->targetW), float(impl_->targetH)}, depth);
}

std::vector<Entity> Renderer::cameras() const {
    std::vector<Entity> out;
    if (impl_)
        for (const CameraInfo& c : impl_->lastCams)
            if (c.entity) out.push_back(c.entity);
    return out;
}

Entity Renderer::camera_at(Vec2 screenPos) const {
    return impl_ ? impl_->camera_for(kNullEntity, &screenPos).entity : kNullEntity;
}

std::optional<Renderer::RenderTargetView> Renderer::render_target_view(World& world, const std::string& name) const {
    if (!impl_ || name.empty()) return std::nullopt;
    Entity found;
    world.each<Camera>([&](Entity e, Camera& c) {
        if (found || c.renderTarget != name || !entity_active(world, e)) return;
        Camera probe = c;
        probe.renderTargetSize =
            Vec2{1, 1};  // a size that is off is clamped when drawn, not a reason to skip the camera
        if (camera_render_target_problem(probe).empty()) found = e;
    });
    if (!found) return std::nullopt;
    RenderTargetView v;
    v.camera = found;
    camera_render_target_pixels(*world.get<Camera>(found), v.width, v.height);
    const Vec2 size{float(v.width), float(v.height)};
    const CameraInfo ci = impl_->build_camera(world, found, &size, true);
    const Mat4 viewProj = ci.viewProj;
    v.to_pixels = [viewProj, size](Vec3 p) {
        const Vec4 c = viewProj * Vec4{p, 1.0f};
        const float w = std::fabs(c.w) > 1e-8f ? c.w : 1e-8f;
        return Vec2{(c.x / w * 0.5f + 0.5f) * size.x, (1.0f - (c.y / w * 0.5f + 0.5f)) * size.y};
    };
    return v;
}

Vec2 Renderer::framebuffer_to_design(Vec2 fb, int fbW, int fbH, ScaleMode mode) const {
    int tw = impl_ ? impl_->targetW : fbW, th = impl_ ? impl_->targetH : fbH;
    Viewport vp = compute_viewport(mode, fbW, fbH, tw, th);
    if (vp.w <= 0 || vp.h <= 0) return fb;
    return {(fb.x - vp.x) / vp.w * float(tw), (fb.y - vp.y) / vp.h * float(th)};
}

Vec2 Renderer::design_to_framebuffer(Vec2 d, int fbW, int fbH, ScaleMode mode) const {
    int tw = impl_ ? impl_->targetW : fbW, th = impl_ ? impl_->targetH : fbH;
    Viewport vp = compute_viewport(mode, fbW, fbH, tw, th);
    if (vp.w <= 0 || vp.h <= 0 || tw <= 0 || th <= 0) return d;
    return {vp.x + d.x / float(tw) * vp.w, vp.y + d.y / float(th) * vp.h};
}

// ---------------------------------------------------------------------------
// render_world
// ---------------------------------------------------------------------------
render::Gpu* RendererTestAccess::gpu(Renderer& r) { return r.impl_ ? &r.impl_->gpu : nullptr; }
const render::FrameGraph* RendererTestAccess::frame_graph(Renderer& r) { return r.impl_ ? &r.impl_->graph : nullptr; }
render::TransientPoolStats RendererTestAccess::transient_stats(Renderer& r) {
    render::TransientPoolStats out;
    if (r.impl_ && r.impl_->transients) {
        const TargetPoolStats s = r.impl_->transients->pool.stats();
        out = {s.live, s.inUse, s.created, s.reused, s.destroyed};
    }
    return out;
}

void RendererTestAccess::force_output(Renderer& r, const HdrOutputInfo* info) {
    if (!r.impl_) return;
    r.impl_->outputForced = info != nullptr;
    r.impl_->forcedOutput = info ? *info : HdrOutputInfo{};
}

void RendererTestAccess::last_cluster_info(Renderer& r, float out[4]) {
    for (int c = 0; c < 4; ++c) out[c] = r.impl_ ? r.impl_->lastClusterInfo[c] : 0.0f;
}

bool RendererTestAccess::read_floats(Renderer& r, bool present, std::vector<float>& out, std::string* error) {
    if (!r.initialized()) {
        if (error) *error = "Renderer is not initialized";
        return false;
    }
    return r.impl_->read_floats(present, out, error);
}

render::ShadowRowsStats RendererTestAccess::shadow_rows_stats(Renderer& r) {
    render::ShadowRowsStats out;
    if (r.impl_)
        out = {int(r.impl_->shadowRowsRing.size()), int(r.impl_->shadowRowUploads),
               int(r.impl_->shadowCache.contours.contoursMade)};
    return out;
}

void RendererTestAccess::force_post_effects(Renderer& r, std::uint32_t effects) {
    if (r.impl_) r.impl_->forceEffects = effects;
}

void Renderer::set_debug_view(DebugView view) {
    if (impl_) impl_->debugView = view;
}

DebugView Renderer::debug_view() const { return impl_ ? impl_->debugView : DebugView::None; }

void Renderer::reset_post_history(std::uint64_t camera) {
    if (impl_) impl_->customPost.reset_history(camera);
}

std::uint64_t RendererTestAccess::decal_atlas_bytes(Renderer& r) { return r.impl_ ? r.impl_->decalAtlas.bytes : 0; }

render::SkyBuilds RendererTestAccess::sky_builds(Renderer& r) {
    if (!r.impl_) return {};
    return {r.impl_->physSky.air_builds(), r.impl_->physSky.view_builds(0), r.impl_->physSky.view_builds(1)};
}
int RendererTestAccess::hiz_reduces(Renderer& r) { return r.impl_ ? r.impl_->hizReduces : 0; }
int RendererTestAccess::hiz_cameras(Renderer& r) { return r.impl_ ? int(r.impl_->hizCams.size()) : 0; }
std::uint64_t RendererTestAccess::origin_shifts(Renderer& r) { return r.impl_ ? r.impl_->originShifts : 0; }
bool RendererTestAccess::origin_watched(Renderer& r, const World* world) {
    return r.impl_ && r.impl_->originWorld == world && r.impl_->originObserver != 0;
}
std::uint64_t RendererTestAccess::gi2d_shifts(Renderer& r) { return r.impl_ ? r.impl_->gi2d.shifts() : 0; }
bool RendererTestAccess::prev_view_proj(Renderer& r, Entity camera, Mat4& out) {
    if (!r.impl_) return false;
    const auto it = r.impl_->prevViewProj.find(camera.bits());
    if (it == r.impl_->prevViewProj.end()) return false;
    out = it->second.viewProj;
    return true;
}
bool RendererTestAccess::prev_jittered(Renderer& r, Entity camera, Mat4& jittered, Vec2& jitterPx) {
    if (!r.impl_) return false;
    const auto it = r.impl_->prevViewProj.find(camera.bits());
    if (it == r.impl_->prevViewProj.end()) return false;
    jittered = it->second.jittered;
    jitterPx = it->second.jitterPx;
    return true;
}
void RendererTestAccess::force_velocity(Renderer& r, bool on) {
    if (!r.impl_) return;
    r.impl_->forceVelocity = on;
    if (!on) render::destroy_target(r.impl_->velocityProbe);
}
void RendererTestAccess::force_no_velocity_target(Renderer& r, bool on) {
    if (r.impl_) r.impl_->noVelocityTarget = on;
}
bool RendererTestAccess::read_velocity(Renderer& r, std::vector<float>& out, int& w, int& h, std::string* error) {
    if (!r.initialized()) {
        if (error) *error = "Renderer is not initialized";
        return false;
    }
    return r.impl_->read_velocity(out, w, h, error);
}
void RendererTestAccess::force_jitter(Renderer& r, int phases) {
    if (r.impl_) r.impl_->jitterForce = std::max(phases, 0);
}
std::vector<Vec2> RendererTestAccess::last_jitter(Renderer& r) {
    std::vector<Vec2> out;
    if (r.impl_)
        for (const CameraInfo& c : r.impl_->lastCams) out.push_back(c.jitterPx);
    return out;
}
int RendererTestAccess::post_history_images(Renderer& r) {
    return r.impl_ ? r.impl_->customPost.history_image_count() : 0;
}

void RendererTestAccess::set_post_history_budget(Renderer& r, std::uint64_t bytes) {
    if (r.impl_) r.impl_->customPost.set_history_budget(bytes);
}
void RendererTestAccess::refuse_post_history(Renderer& r, bool refuse) {
    if (r.impl_) r.impl_->customPost.set_history_refused(refuse);
}
int RendererTestAccess::post_history_attempts(Renderer& r) {
    return r.impl_ ? r.impl_->customPost.history_attempts() : 0;
}

void RendererTestAccess::set_before_frame_graph(Renderer& r, std::function<void()> hook) {
    if (r.impl_) r.impl_->beforeFrameGraph = std::move(hook);
}

int RendererTestAccess::taa_images(Renderer& r) { return r.impl_ ? r.impl_->taa.history_image_count() : 0; }
bool RendererTestAccess::taa_used_history(Renderer& r, Entity camera) {
    return r.impl_ && r.impl_->taa.last_used_history(camera.bits());
}
int RendererTestAccess::taa_resets(Renderer& r) { return r.impl_ ? r.impl_->taa.resets() : 0; }
int RendererTestAccess::upscale_phases(Renderer& r) { return r.impl_ ? r.impl_->temporalPhases : 0; }
int RendererTestAccess::upscale_impl(Renderer& r) { return r.impl_ ? int(r.impl_->upscaleImpl) : 0; }
bool RendererTestAccess::upscale_used_history(Renderer& r) {
    return r.impl_ && r.impl_->taa.last_used_history(render::kUpscaleCamKey);
}
int RendererTestAccess::taa_format(Renderer& r) { return r.impl_ ? int(r.impl_->taa.history_format()) : 0; }
bool RendererTestAccess::taa_unavailable(Renderer& r) { return r.impl_ && r.impl_->taa.unavailable(); }
void RendererTestAccess::taa_force_rgba8(Renderer& r, bool force) {
    if (r.impl_) r.impl_->taa.force_rgba8(force);
}

int RendererTestAccess::ldr_cut_format(Renderer& r) {
    return r.impl_ && r.impl_->ldrMid[0].valid() ? int(r.impl_->ldrMid[0].format.color) : 0;
}

void Renderer::update(World& world) {
    if (!initialized()) return;
    Impl& im = *impl_;
    im.watch_world(world);  // before the cameras: a rebase between two frames has already moved them
    // Camera queries (world_to_screen, screen_to_world, screen_ray, camera_at) must not depend on drawing: a frame the runtime
    // does not draw (OnDemand, a test that steps without drawing) still refreshes the cameras here.
    im.lastCams = im.collect_cameras(world);
    im.refresh_logic_cameras(world);
    // entity.bounds() of a parallax layer follows the camera whether or not the frame is drawn (its real pose, not the blended one).
    update_parallax(world, im.logic_camera_xy());
    im.updated = true;
}

void Renderer::set_scale_mode(ScaleMode mode) {
    if (impl_) impl_->scaleMode = mode;
}

// The measuring of a run with no renderer is the same code (fa/render/text_measure.h, font_set.h): shaping and sizes come from the
// GPU-free FontSet, so a text is the same size drawn or not. Measuring does not rasterize glyphs into the atlas.
Vec2 Renderer::measure_text(std::string_view text, float fontSize, std::string_view font, float maxWidth,
                            RenderSpace space, TextStyle style) const {
    if (!initialized()) return {0, 0};
    return render::measure_plain_text(impl_->fonts->set(), text, fontSize, font, maxWidth, space, style,
                                      impl_->textScale, impl_->uiScale);
}

Vec2 Renderer::measure_text(const Text& text) const {
    if (!initialized()) return {0, 0};
    return render::measure_text_component(impl_->fonts->set(), text, textScale_, impl_->uiScale);
}

void Renderer::set_fallback_fonts(std::vector<std::string> fonts) {
    fallbackFonts_ = std::move(fonts);
    if (impl_ && impl_->fonts) impl_->fonts->set_fallback_fonts(fallbackFonts_);
}

void Renderer::set_ui_scale(float scale) {
    uiScale_ = std::isfinite(scale) ? std::clamp(scale, kMinUiScale, kMaxUiScale) : 1.0f;
    if (impl_) impl_->uiScale = uiScale_;
}

void Renderer::set_rich_text_style(RichTextStyle style) {
    richStyle_ = std::move(style);
    if (impl_ && impl_->fonts) impl_->fonts->set_rich_style(richStyle_);
}

void Renderer::set_text_scale(float scale) {
    textScale_ = std::isfinite(scale) ? std::clamp(scale, kMinTextScale, kMaxTextScale) : 1.0f;
    if (impl_) impl_->textScale = textScale_;
}

void Renderer::render_world(World& world, float dt) {
    if (!initialized()) return;
    impl_->watch_world(world);
    if (!impl_->inFrame) begin_frame();
    if (!impl_->updated) update(world);  // backward compatible: callers that only use render_world
    impl_->updated = false;
    impl_->render(world, dt);
}

// What every gather of a frame needs from the renderer: the sizes, the caches, the warning flags.
void Renderer::Impl::setup_frame(Frame& fr, World& world, float dt) {
    fr.targetW = targetW;
    fr.targetH = targetH;
    fr.dt = dt;
    fr.time = float(world.time());
    fr.stats = &stats;
    fr.assets = assets.get();
    fr.compute = compute;
    fr.fonts = fonts.get();
    fr.textScale = textScale;
    fr.uiScale = ui_scale_clamped(world.ui_scale());
    fr.renderScale = renderScale;
    fr.screenScale =
        hudAtOutput ? 1.0f
                    : renderScale;  // 1: the screen-space items go over the upscaled picture (render_world decided)
    fr.linear = gpu.linear();
    fr.warnedLights2d = &warnedLights2d;
    fr.warnedSpriteMesh = &warnedSpriteMesh;
    fr.warnedGradientStops = &warnedGradientStops;
    fr.shadowCache = &shadowCache;
    fr.ramps = &ramps;
    fr.viewFlipV = gpu.is_gl();
    fr.viewImage = [this](std::uint64_t key, int w, int h) { return view_image(key, w, h); };
    fr.mask = CameraMask::of(world, fr.cam.entity);  // fr.cam is set before this
}

// One frame: the cameras drawn in depth order (each into its viewport rectangle: its own culling, 2D lights, 3D lights, clear)
// and then, when the cameras do not fill the screen together with a single full-screen camera, the screen-space items
// (Sprite/Shape2D/Text/ParticleEmitter with space "screen", UI, debug text) once over the whole screen. A game with one
// camera and no viewport is one job that draws all of it in one pass, as before. Bloom and PostProcess.colorFilter act once over
// the finished frame, with the settings of the first camera.
void Renderer::Impl::render(World& world, float dt) {
    sync_color_space(world);  // before anything is gathered or drawn: the scene's format and the colours depend on it
    // What this frame is drawn for: the window's output as update_output() last answered (the final pass's tonemap and
    // present() read it).
    frameOutput = render::select_output(output(), float_display());
    frameAboveWhite = false;
    auto t0 = std::chrono::steady_clock::now();
    if (Profiler::on()) {
        // Answers of earlier frames are read now (never waited for): the passes of this frame report them as their GPU time.
        gpuTimer.poll(gpuFrames);
        constexpr std::size_t kKeepGpuFrames = 256;  // nobody called take_gpu_ms(): keep the newest
        if (gpuFrames.size() > kKeepGpuFrames)
            gpuFrames.erase(gpuFrames.begin(), gpuFrames.end() - std::ptrdiff_t(kKeepGpuFrames));
        gpuTimer.begin();
    } else {
        // Nothing is measured now: what an earlier run of the profiler left would show as the GPU time of this frame's
        // passes, and in take_gpu_ms(), the next time it is switched on.
        gpuTimer.forget();
        gpuFrames.clear();
    }
    stats = RenderStats{};
    lodFades.begin_frame(&world, world.scene_generation());
    materialsCounted.clear();
    anyFrameRendered = true;
    transient_targets().pool.begin_frame();  // the bloom levels of the frame graphs below come from this pool

    assets->set_mesh_store(&world.meshes());  // before any camera asks for a "mesh:N" id
    // M76-P4: the temporal upscaler jitters the camera by the number of phases the upscale ratio asks for (the cameras are built with it) and
    // resolves it into the output image; it works on a frame of ONE full-viewport camera (several cameras or a split screen are drawn with
    // the spatial upscaler: each would need a history of its rectangle). The frame is decided here, before the cameras are built: the
    // cameras are collected with the jitter the last frame's count says (none after a several-camera frame), and collected again when
    // this frame's count says otherwise (a change of camera count, not every frame).
    temporalPhases = 0;
    temporalFrame = false;
    upscaleTaa = TaaPlan{};
    upscaleImpl = render::UpscaleImpl::Stretch;
    int wantedPhases = 0;
    if (upscale_active()) {
        render::UpscalerCaps oneCamera = upscaler_caps();
        oneCamera.multiCamera = false;
        if (render::effective_upscaler_mode(upscaler, oneCamera) == render::UpscalerMode::Temporal)
            wantedPhases = render::upscale_jitter_phases(physW, physH, targetW, targetH);
    }
    temporalPhases = temporalBlocked ? 0 : wantedPhases;
    lastCams = collect_cameras(world);
    const bool oneFullCamera = lastCams.size() == 1 && lastCams.front().fullViewport();
    if (wantedPhases > 0 && temporalPhases != (oneFullCamera ? wantedPhases : 0)) {
        temporalPhases = oneFullCamera ? wantedPhases : 0;
        lastCams = collect_cameras(world);
    }
    temporalBlocked = !oneFullCamera;
    if (temporalPhases > 0) {
        temporalFrame = true;
        upscaleImpl = render::UpscaleImpl::Temporal;
    }
    refresh_logic_cameras(world);
    occlusionPrev = std::move(
        occlusionShown);  // the debug view of the occlusion draws the frame before's boxes (gather_meshes fills this one)
    occlusionShown = {};
    occlusion_overlay();
    hiz_begin_frame(world);      // the mode, and the pictures of a world that is gone
    portalGather.valid = false;  // the rooms and doors are gathered again by the first camera of this frame
    hizPrev = std::move(hizShown);
    hizShown = {};
    hiz_overlay();
    assets->set_drawing(true);
    set_target_self({});
    collect_targets(
        world);          // before any gather: the textures "target:<name>" exist when a Sprite or a mesh asks for them
    ++shadowCache.tick;  // one per drawn frame, not per camera: every camera of this frame keeps the rows it reads
    assets->begin_material_frame();  // the sets of values 2D items use with a material (Assets::sprite_material)
    ramps.begin_frame();
    if (world.scene_path() != lights2dScene) {
        lights2dScene = world.scene_path();
        warnedLights2d = false;
        warnedCookies2d = false;
        warnedLightBuffers2d = false;
        sceneCapWarned = false;  // the picture-copy warnings (water2d.h) may show again in the new scene
        sceneCopyWarned = false;
        reset_warnings(shadowCache.contours);  // the 2D shadow warnings may show again in the new scene
        warnedSpriteMesh = false;
        warnedGradientStops = false;
        warnedCameras = false;
        warnedCustomPass.clear();
    }

    struct JobSpec {
        CameraInfo cam;
        bool world = true, screen = true;
    };
    std::vector<JobSpec> specs;
    const bool split = !(lastCams.size() == 1 && lastCams.front().fullViewport());
    if (!split) {
        specs.push_back({lastCams.front(), true, true});
    } else {
        for (const CameraInfo& c : lastCams) specs.push_back({c, true, false});
        specs.push_back({lastCams.front(), false, true});
    }

    // The upscale stage (M76-P3a) draws the screen-space items over the upscaled picture, at the output size, when no pass after them in the
    // old order (renderer_draw.cpp, build_graph) would have changed their pixels. The glyphs are rasterized for the size they are drawn at,
    // so this is decided before the gather. The bloom is the only effect that reaches items drawn in the game image (bloomScreenSpace): the
    // effects that put them over the bloom (bloomScreenSpace false, the scene-colour effects) or over the final pass leave them alone.
    // The scene-colour effects are not known here, so a glowing HUD stays in the game image whatever the camera's other effects are.
    hudAtOutput = false;
    if (upscale_active() && !lastCams.empty()) {
        const CameraInfo& fc = lastCams.front();
        const bool linearScene = world.settings().colorSpace == ColorSpace::Linear;
        bool anyFinal = false;
        for (const JobSpec& sp : specs)
            anyFinal =
                anyFinal ||
                (sp.world &&
                 make_post_plan(sp.cam, linearScene, forceEffects, world.frame(), renderScale, &fc).final_pass());
        const bool glows = fc.bloom.enabled && fc.bloom.intensity > 0.0f && fc.bloom.screenSpace && !anyFinal;
        hudAtOutput =
            !glows && (!anyFinal || ensure_filter_target()) &&
            ensure_output_target(outTarget, "output", anyFinal ? gpu.display_format() : gameTarget.format.color, true);
    }

    std::vector<Frame> frames(specs.size());
    std::vector<Frame> targetFrames;        // one per Camera.renderTarget, in targetCams order
    std::vector<std::set<int>> targetDeps;  // targetDeps[i]: the targets that the frame of target i shows
    // The CameraViews of the frame (collected by the UI gather of the frames): each one's camera drawn into its own image first.
    std::vector<std::pair<std::uint64_t, Frame>> viewFrames;
    // The glyph atlas can be cleared halfway through a gather (it is full): the texts gathered before that hold UVs of the
    // old atlas. Gather once more then, so no text of the frame is drawn from a cleared atlas (it fits after a clear).
    for (int attempt = 0; attempt < 2; ++attempt) {
        const unsigned atlasEpoch = fonts->atlas_epoch();
        auto setup = [&](Frame& fr) { setup_frame(fr, world, dt); };
        // The camera-independent part of the 2D gather is done by the first camera that draws an entity and copied by the others
        // (scene2d.h). It keeps pointers to the quad lists of the Frames it gathered, so those vectors must not reallocate.
        Scene2D scene2d;
        // One frame, no render target, no CameraView (the UI gather would add a destination after the first gather): nothing
        // is shared, so Scene2D keeps no per-entity tables.
        scene2d.set_single_destination(specs.size() == 1 && targetCams.empty() && !world.any<CameraView>());
        targetFrames.clear();
        targetFrames.reserve(targetCams.size());
        for (std::size_t i = 0; i < specs.size(); ++i) {
            frames[i] = Frame{};
            Frame& fr = frames[i];
            fr.cam = specs[i].cam;
            fr.wantWorld = specs[i].world;
            fr.wantScreen = specs[i].screen;
            setup(fr);
            // Once per rendered frame: it writes what each animator's `frame` says into Sprite.region, the same for every camera.
            if (attempt == 0 && i == 0) apply_sprite_frames(world, fr);
            scene2d.gather(world, fr);
            if (fr.wantScreen) gather_ui(world, fr);
            scene2d.gather_particles(world, fr);
            gather_debug(*debug.impl(), fr);
        }
        // One job per CameraView the UI met: a world gather of its camera at the size of its rectangle.
        // One job per render target: a world gather of its camera at the size of its texture. Its own texture is the checker meanwhile.
        for (const TargetCam& tc : targetCams) {
            // Scene2D keeps pointers into fr.world: the vector must not reallocate (reserved above).
            FA_ASSERT(targetFrames.size() < targetFrames.capacity(),
                      "targetFrames would reallocate under Scene2D's donors");
            Frame& fr = targetFrames.emplace_back();
            set_target_self(tc.name);
            const Vec2 size{float(tc.w), float(tc.h)};
            fr.cam = build_camera(world, tc.entity, &size, true);
            fr.wantWorld = true;
            fr.wantScreen = false;
            setup(fr);
            fr.targetW = tc.w;
            fr.targetH = tc.h;
            fr.renderScale = fr.screenScale = 1.0f;
            scene2d.gather(world, fr);
            if (fr.cam.studio) {
                fr.lights2d.clear();
                fr.ambient2d = Color{1, 1, 1, 1};
                fr.shadowData.clear();
                fr.shadowRows = 0;
                fr.shadowKey = 0;
            }
            scene2d.gather_particles(world, fr);
            set_target_self({});
        }
        viewFrames.clear();
        std::size_t viewCount = 0;
        for (const Frame& main : frames) viewCount += main.views.size();
        viewFrames.reserve(viewCount);
        for (const Frame& main : frames)
            for (const ViewRequest& rq : main.views) {
                bool seen = false;
                for (const auto& v : viewFrames) seen = seen || v.first == rq.key;
                if (seen) continue;
                // Scene2D keeps pointers into fr.world: the vector must not reallocate (reserved above).
                FA_ASSERT(viewFrames.size() < viewFrames.capacity(),
                          "viewFrames would reallocate under Scene2D's donors");
                Frame& fr = viewFrames.emplace_back(rq.key, Frame{}).second;
                fr.cam = build_camera(world, rq.camera, &rq.size);
                fr.wantWorld = true;
                fr.wantScreen = false;
                setup(fr);
                fr.targetW = rq.pxW;
                fr.targetH = rq.pxH;
                fr.renderScale = fr.screenScale = rq.size.x > 0.0f ? float(rq.pxW) / rq.size.x : 1.0f;
                scene2d.gather(world, fr);
                if (fr.cam
                        .studio) {  // the scene's 2D lights do not reach a studio camera: lit sprites show at full brightness
                    fr.lights2d.clear();
                    fr.ambient2d = Color{1, 1, 1, 1};
                    fr.shadowData.clear();
                    fr.shadowRows = 0;
                    fr.shadowKey = 0;
                }
                scene2d.gather_particles(world, fr);
            }
        if (fonts->atlas_epoch() == atlasEpoch) break;
    }
    // gather_2d shifted the Parallax layers for each camera it drew (from the blended pose); what the world keeps is the shift for
    // the first camera's REAL pose (the one Renderer::update and a run with no renderer use, so Parallax.offset and bounds() do not
    // depend on the interpolation alpha), whatever cameras or render targets the frame had.
    update_parallax(world, logic_camera_xy());
    // After every gather: the glyph atlas may be remade by a sync, which no job of this frame has recorded a draw with yet.
    fonts->sync();
    ramps.sync();
    stats.glyphAtlasSize = fonts->atlas_size();
    stats.glyphAtlasResets = int(fonts->atlas_epoch());
    // The screen-space job of a split frame is dropped when it has nothing to draw (a pass less).
    if (split && frames.back().screen.empty() && frames.back().debugScreen.empty()) {
        frames.pop_back();
        specs.pop_back();
    }

    // The 3D world of the frame, gathered once for every camera, render target and CameraView (render_scene.h): after the
    // targets exist (a mesh may show one) and the 2D gathers (nothing they do changes a MeshRenderer, so the scene's pointers
    // into the world stay good), before any job. The MeshRenderers that show a render target (texture, normalMap or a texture
    // parameter of the material) are listed from it: who shows what is known from the meshes in view of each camera, below.
    // The scene lists the targets of a mesh only when some camera renders into one.
    probes_build_volumes(
        world);  // the boxes the meshes pick their reflection probes from (the probes captured in earlier frames)
    renderScene.build(world, *assets, kNullEntity, !targetCams.empty(), &probeVolumes);
    probes_note_picks();
    struct MeshRef {
        Entity e;
        const MeshAsset* mesh = nullptr;
        Mat4 model;
        std::vector<int> targets;
    };
    std::vector<MeshRef> meshRefs;
    if (!targetCams.empty()) {
        for (const SceneMesh& sm : renderScene.meshes()) {
            MeshRef ref{sm.entity, sm.mesh, sm.model, {}};
            for (const std::string& name : sm.targets) {
                auto it = targetByName.find(name);
                if (it != targetByName.end() &&
                    std::find(ref.targets.begin(), ref.targets.end(), it->second) == ref.targets.end())
                    ref.targets.push_back(it->second);
            }
            if (!ref.targets.empty()) meshRefs.push_back(std::move(ref));
        }
    }
    // The jobs of the frame are the passes of one frame graph (frame_graph.h), declared in the order they run: the render targets,
    // each after the targets it shows (the frame's own jobs and the CameraViews sample their textures), then the CameraViews, then
    // the cameras. The jobs that show an image of another job read it in the graph (JobPlan::shows).
    // Who shows what: the Sprites, Texts and UI quads of a frame and the meshes in its view whose texture is "target:<name>".
    std::vector<std::set<int>> mainShows(frames.size()), viewShows(viewFrames.size());
    if (!targetCams.empty()) {
        const bool z01 = gpu.depth_zero_to_one();
        const int n = int(targetFrames.size());
        targetDeps.assign(std::size_t(n), {});
        // `cull`: a Sprite or Text that is not in the camera's view draws nothing, so it does not count as shown (gather_2d keeps
        // every quad: the GPU clips them). The quads of the screen-space lists are not in the camera's space: all count.
        auto scan_quads = [&](const Frame& fr, const QuadList& list, bool cull, std::set<int>& into, bool& self) {
            for (const QuadItem& it : list.items) {
                bool relevant = false;
                for (const TextureAsset* t : {it.tex, it.normal})
                    relevant = relevant || (t && (t == &selfSentinel || targetByAsset.count(t)));
                if (!relevant) continue;
                if (cull) {
                    Vec3 lo{1e30f, 1e30f, 1e30f}, hi{-1e30f, -1e30f, -1e30f};
                    for (std::uint32_t v = it.firstVert; v < it.firstVert + it.quadCount * 4; ++v) {
                        const Vertex2D& q = list.raw[v];
                        lo = Vec3{std::min(lo.x, q.x), std::min(lo.y, q.y), std::min(lo.z, q.z)};
                        hi = Vec3{std::max(hi.x, q.x), std::max(hi.y, q.y), std::max(hi.z, q.z)};
                    }
                    if (!box_in_frustum(fr.cam.viewProj, z01, lo, hi, Mat4::identity())) continue;
                }
                for (const TextureAsset* t : {it.tex, it.normal}) {
                    if (!t) continue;
                    if (t == &selfSentinel)
                        self = true;
                    else if (auto f = targetByAsset.find(t); f != targetByAsset.end())
                        into.insert(f->second);
                }
            }
        };
        // The targets `fr` shows, in `into` (its own target, `own`, only sets `self`: it draws the checker).
        auto scan_frame = [&](const Frame& fr, int own, std::set<int>& into) {
            bool self = false;
            if (fr.wantWorld) {
                scan_quads(fr, fr.world, true, into, self);
                for (const MeshRef& ref : meshRefs) {
                    if (!fr.mask.draws(world, ref.e)) continue;  // a mesh this camera does not draw shows nothing to it
                    if (!box_in_frustum(fr.cam.viewProj, z01, ref.mesh->bmin, ref.mesh->bmax, ref.model)) continue;
                    for (int t : ref.targets) {
                        if (t == own)
                            self = true;
                        else
                            into.insert(t);
                    }
                }
            }
            if (fr.wantScreen) scan_quads(fr, fr.screen, false, into, self);
            return self;
        };
        for (int i = 0; i < n; ++i) {
            const TargetCam& tc = targetCams[std::size_t(i)];
            if (scan_frame(targetFrames[std::size_t(i)], i, targetDeps[std::size_t(i)]))
                warn_target_once(
                    "self:" + tc.name,
                    "Camera '" + world.id_of(tc.entity) + "' renders into target '" + tc.name +
                        "' and its own view shows \"target:" + tc.name +
                        "\" (a Sprite, a Panel or a MeshRenderer in front of it): a pass cannot read the image it is "
                        "drawing into, so "
                        "that surface is drawn as the missing-texture checker",
                    "Move the entity that shows the target out of this camera's view (the camera sees everything in "
                    "its frustum), "
                    "or give the picture to another camera: two targets can show each other, each one frame late.");
        }
        for (std::size_t i = 0; i < frames.size(); ++i) scan_frame(frames[i], -1, mainShows[i]);
        for (std::size_t i = 0; i < viewFrames.size(); ++i) scan_frame(viewFrames[i].second, -1, viewShows[i]);
    }
    // The order of the render targets: one node per target in a small frame graph, after the targets it shows, declared by depth
    // (Camera.depth, then creation order); compile() runs the declared-first node among those that are ready. A loop (A shows B,
    // B shows A) does not fail: the node declared first goes first and shows the other's picture of the previous frame (one
    // frame late), the same way every frame (CyclePolicy::Break).
    std::vector<int>& targetOrder = orderScratch.order;
    targetOrder.clear();
    if (!targetFrames.empty()) {
        const int n = int(targetFrames.size());
        std::vector<int>& byDepth = orderScratch.byDepth;
        byDepth.clear();
        for (int i = 0; i < n; ++i) byDepth.push_back(i);
        std::stable_sort(byDepth.begin(), byDepth.end(), [&](int a, int b) {
            return targetCams[std::size_t(a)].depth < targetCams[std::size_t(b)].depth;
        });
        // Kept between frames (clear() keeps the capacity of its vectors): the graph's vectors are not allocated again each frame,
        // though the pass names and the `after` lists still are.
        FrameGraph& jobs = orderScratch.graph;
        jobs.clear();
        jobs.set_cycle_policy(CyclePolicy::Break);
        std::vector<std::pair<std::string, int>>& byName = orderScratch.byName;
        byName.clear();
        for (int i : byDepth) {
            GraphPass p;
            p.name = "target:" + targetCams[std::size_t(i)].name;
            for (int d : targetDeps[std::size_t(i)]) p.after.push_back("target:" + targetCams[std::size_t(d)].name);
            p.sideEffect = true;  // never culled: it has no outputs
            byName.emplace_back(p.name, i);
            jobs.add_pass(std::move(p));
        }
        auto index_of = [&](const std::string& name) {
            for (const auto& [n2, i] : byName)
                if (n2 == name) return i;
            return byDepth.front();  // cannot happen: every name of the order was declared above
        };
        if (jobs.compile().ok()) {
            for (const std::string& name : jobs.order_names()) targetOrder.push_back(index_of(name));
            for (const CycleBreak& cb : jobs.cycle_breaks()) {
                auto quote = [&](const std::string& passName) {
                    return "'" + passName.substr(std::string("target:").size()) + "'";
                };
                // "'A'", "'A' and 'B'", "'A', 'B' and 'C'"
                auto join = [](const std::vector<std::string>& names) {
                    std::string out;
                    for (std::size_t k = 0; k < names.size(); ++k)
                        out += (k == 0 ? "" : k + 1 == names.size() ? " and " : ", ") + names[k];
                    return out;
                };
                std::vector<std::string> others, all;
                for (const std::string& w : cb.waitedFor) others.push_back(quote(w));
                const std::string first = quote(cb.pass);
                all.push_back(first);
                all.insert(all.end(), others.begin(), others.end());
                const std::string waited = join(others);
                if (targetWarned.insert("cycle:" + first + "<-" + waited).second)
                    FA_WARN(
                        "render",
                        "The render targets {} show each other, so {} is drawn first and shows the picture "
                        "{} had in the previous frame (one frame late). Hint: that is fine for a mirror of a mirror; "
                        "to avoid the lag, break the loop so a target only shows targets drawn before it",
                        join(all), first, waited);
            }
        } else {
            targetOrder = byDepth;  // cannot happen (unique names, every `after` is a target): draw by depth
        }
    }

    begin_frame_graph();
    auto keys_of = [&](const std::set<int>& targets) {
        std::vector<std::uint64_t> keys;
        for (int t : targets) keys.push_back(targetCams[std::size_t(t)].key);
        return keys;
    };
    for (int i : targetOrder) {
        const TargetCam& tc = targetCams[std::size_t(i)];
        auto it = viewTargets.find(tc.key);
        if (it == viewTargets.end() || !it->second->main.color.id) continue;
        JobPlan plan;
        plan.name = "target:" + tc.name;
        plan.shows = keys_of(targetDeps[std::size_t(i)]);
        set_target_self(tc.name);
        plan_view_job(world, targetFrames[std::size_t(i)], *it->second, tc.key, plan);
        set_target_self({});
        ++stats.renderTargets;
    }

    // The CameraViews next: the frame's own jobs sample their images.
    for (std::size_t i = 0; i < viewFrames.size(); ++i) {
        auto& [key, vf] = viewFrames[i];
        auto it = viewTargets.find(key);
        if (it == viewTargets.end() || !it->second->main.color.id) continue;
        JobPlan plan;
        plan.name = "view:" + std::to_string(i);
        plan.shows = keys_of(viewShows[i]);
        plan_view_job(world, vf, *it->second, key, plan);
    }
    stats.views = int(viewFrames.size());

    const CameraInfo post = specs.front().cam;
    for (std::size_t i = 0; i < frames.size(); ++i) {
        JobPlan plan;
        plan.name = frames[i].wantWorld ? "camera:" + std::to_string(i) : "screen";
        plan.first = i == 0;
        plan.last = i + 1 == frames.size();
        plan.post = &post;
        plan.shows = keys_of(mainShows[i]);
        for (const ViewRequest& rq : frames[i].views) plan.shows.push_back(rq.key);
        plan_job(world, frames[i], plan);
    }
    probes_plan(
        world);  // after the cameras: a probe's faces do not take the sky's bake pass from the picture being drawn
    run_frame_graph();
    probes_finish();  // before release_unused_views(): the faces' images are read here
    update_editor_copy();
    graphFromCapture = false;
    passTimesPending = true;  // stats() and the frame graph report build them from the graph when asked for
    stats.sortKeyFallbacks = int(std::min<std::uint64_t>(renderScene.sort_key_fallbacks(), 0x7fffffffu));

    renderScene.reset();  // it points into the world, which the game may change before the next frame
    lodFades.end_frame();
    release_unused_views();
    assets->set_drawing(false);
    debug.clear();
    gpuTimer.end();  // closes the query begun above even if the profiler was switched off meanwhile
    auto t1 = std::chrono::steady_clock::now();
    stats.cpuMs = std::chrono::duration<double, std::milli>(t1 - t0).count();
}

void Renderer::end_frame() {
    if (!initialized()) return;
    if (impl_->desc.headless) {
        sg_commit();
        impl_->gpu.note_commit();
    }
    impl_->inFrame = false;
}

std::string Renderer::create_runtime_texture(const Image& img, std::string* error) {
    if (!initialized() || !impl_->assets) {
        if (error) *error = "Renderer is not initialized";
        return {};
    }
    constexpr int kMaxSide = 4096;
    if (img.empty() || img.width > kMaxSide || img.height > kMaxSide ||
        img.rgba.size() != std::size_t(img.width) * std::size_t(img.height) * 4) {
        if (error) *error = "a run-time texture must be between 1 x 1 and 4096 x 4096 pixels";
        return {};
    }
    return impl_->assets->make_runtime_texture(img);
}

bool Renderer::destroy_runtime_texture(const std::string& id) {
    return impl_ && impl_->assets && impl_->assets->destroy_runtime_texture(id);
}

// ---------------------------------------------------------------------------
// Background loading (renderer.h, "Background loading")
// ---------------------------------------------------------------------------
namespace {

bool is_background_texture_ext(const std::string& ext) {
    static const char* const kExt[] = {".png", ".jpg", ".jpeg", ".bmp", ".tga", ".gif", ".ktx2"};
    for (const char* e : kExt)
        if (ext == e) return true;
    return false;
}

IoResult background_failure(std::string message, std::string hint = {}) {
    IoResult r;
    r.error = std::move(message);
    r.hint = std::move(hint);
    return r;
}

// The file is made warm first (fs::warm): when its decode fails, the load on first use reads the same bytes from memory
// (and reports the same error) instead of the disk; the background loader drops it again once the asset is adopted.
Result<IoFile> background_read(const std::string& path) {
    if (auto w = fs::warm(path); !w) return w.error();
    auto view = fs::read_view(path);
    if (!view) return view.error();
    return IoFile{path, std::move(*view)};
}

}  // namespace

Renderer::BackgroundKind Renderer::background_kind(std::string_view path) {
    const std::string ext = to_lower(fs::extension(path));
    if (is_background_texture_ext(ext)) return BackgroundKind::Texture;
    if (ext == ".gltf" || ext == ".glb") return BackgroundKind::Model;
    if (ext == ".ttf" || ext == ".otf") return BackgroundKind::Font;
    return BackgroundKind::None;
}

bool Renderer::background_cached(std::string_view pathIn, BackgroundKind kind) const {
    if (!impl_ || !impl_->assets) return true;  // nothing to prepare for: no renderer
    const std::string path(pathIn);
    switch (kind) {
        case BackgroundKind::Texture: {
            const assets::PackedTexture packed = assets::packed_texture(path);
            return impl_->assets->has_texture(packed.atlas.empty() ? path : packed.atlas);
        }
        case BackgroundKind::Model: return impl_->assets->has_mesh(path);
        case BackgroundKind::Font: return impl_->fonts->has_face(path);
        case BackgroundKind::None: return true;
    }
    return true;
}

Renderer::BackgroundWork Renderer::background_work(std::string_view pathIn, BackgroundKind kind) const {
    const std::string path(pathIn);
    BackgroundWork w;
    switch (kind) {
        case BackgroundKind::Texture: {
            const sg_pixel_format format = impl_ ? render::ktx2_target_format() : SG_PIXELFORMAT_RGBA8;
            // The colour space the texture will be made for (asked here, on the calling thread, not in the worker).
            const bool srgbMips = impl_ && impl_->gpu.texture_format(SG_PIXELFORMAT_RGBA8) != SG_PIXELFORMAT_RGBA8;
            w.read = [path]() -> Result<IoFile> {
                // As Assets::load_texture: an export packed it into an atlas (read the atlas), or made a KTX2 twin.
                const assets::PackedTexture packed = assets::packed_texture(path);
                const std::string key = packed.atlas.empty() ? path : packed.atlas;
                const std::string twin =
                    fs::extension(key) == kTextureTwinExtension ? key : key + kTextureTwinExtension;
                return background_read(fs::exists(twin) ? twin : key);
            };
            w.decode = [path, format, srgbMips](IoFile& f) {
                const assets::PackedTexture packed = assets::packed_texture(path);
                const std::string key = packed.atlas.empty() ? path : packed.atlas;
                auto p = render::decode_texture_file(key, f.path, f.view.data(), f.view.size(), format, srgbMips);
                if (!p) return background_failure(p.error().message, p.error().hint);
                IoResult r;
                r.ok = true;
                r.value = std::make_shared<PreparedTexture>(std::move(*p));
                return r;
            };
            break;
        }
        case BackgroundKind::Model:
            w.read = [path] { return background_read(path); };
            w.decode = [path](IoFile& f) {
                AssetLoadScope trace("mesh",
                                     path);  // the decode time (the read was the IO thread's); free without a trace
                trace.set_bytes(f.view.size());
                auto p = std::make_shared<PreparedMesh>();
                std::string error;
                if (!render::decode_gltf(path, f.view.data(), f.view.size(), *p, error))
                    return background_failure("mesh " + error);
                IoResult r;
                r.ok = true;
                r.value = std::move(p);
                return r;
            };
            break;
        case BackgroundKind::Font:
            w.read = [path]() -> Result<IoFile> { return IoFile{path, {}}; };  // the face reads its file itself
            w.decode = [path](IoFile&) {
                auto face = std::make_shared<std::unique_ptr<render::FontFace>>(render::load_font_face(path));
                IoResult r;
                r.ok =
                    true;  // a face that failed is kept as one: a load on first use keeps it too (and reports it once)
                r.bytes = (*face)->size;
                r.value = std::move(face);
                return r;
            };
            break;
        case BackgroundKind::None: break;
    }
    return w;
}

std::uint64_t Renderer::adopt_background(std::string_view pathIn, BackgroundKind kind, IoResult& result) {
    if (!impl_ || !impl_->assets || !result.ok || !result.value) return 0;
    const std::string path(pathIn);
    switch (kind) {
        case BackgroundKind::Texture:
            return impl_->assets->adopt_texture(*std::static_pointer_cast<PreparedTexture>(result.value),
                                                std::move(result.files));
        case BackgroundKind::Model:
            return impl_->assets->adopt_mesh(path, *std::static_pointer_cast<PreparedMesh>(result.value),
                                             std::move(result.files));
        case BackgroundKind::Font: {  // the face moves into the cache (a FontFace is not copyable)
            auto holder = std::static_pointer_cast<std::unique_ptr<render::FontFace>>(result.value);
            impl_->fonts->adopt(std::move(*holder), std::move(result.files));
            return 0;
        }
        case BackgroundKind::None: break;
    }
    return 0;
}

}  // namespace fa
