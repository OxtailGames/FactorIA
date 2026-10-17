#include "fa/render/renderer.h"

#include <algorithm>
#include <chrono>
#include <cmath>
#include <cstring>

#include "fa/core/fs.h"
#include "fa/core/log.h"
#include "fa/platform/sokol_logging.h"
#include "bloom.h"
#include "frame.h"
#include "render_internal.h"

#include "shaders/blit.glsl.h"
#include "shaders/mesh.glsl.h"
#include "shaders/quad.glsl.h"
#include "shaders/shadow.glsl.h"
#include "shaders/sky.glsl.h"

namespace fa {

using namespace render;

// ---------------------------------------------------------------------------
// RenderStats / DebugDraw
// ---------------------------------------------------------------------------
Json RenderStats::to_json() const {
    return Json{{"drawCalls", drawCalls}, {"sprites", sprites}, {"shapes", shapes}, {"textGlyphs", textGlyphs},
                {"particles", particles}, {"meshes", meshes}, {"triangles", triangles}, {"lights", lights},
                {"cpuMs", std::round(cpuMs * 1000.0) / 1000.0}};
}

DebugDraw::DebugDraw() : impl_(std::make_unique<Impl>()) {}
DebugDraw::~DebugDraw() = default;

void DebugDraw::line(Vec3 a, Vec3 b, Color c, float thickness) { impl_->lines.push_back({a, b, c, thickness}); }
void DebugDraw::rect(Rect r, Color c, bool filled) { impl_->rects.push_back({r, c, filled}); }
void DebugDraw::circle(Vec2 center, float radius, Color c, bool filled) { impl_->circles.push_back({center, radius, c, filled}); }
void DebugDraw::box(Vec3 center, Vec3 size, Color c) {
    Vec3 h = size * 0.5f;
    Vec3 p[8];
    for (int i = 0; i < 8; ++i) p[i] = center + Vec3{(i & 1) ? h.x : -h.x, (i & 2) ? h.y : -h.y, (i & 4) ? h.z : -h.z};
    static const int e[12][2] = {{0, 1}, {2, 3}, {4, 5}, {6, 7}, {0, 2}, {1, 3}, {4, 6}, {5, 7}, {0, 4}, {1, 5}, {2, 6}, {3, 7}};
    for (auto& ed : e) line(p[ed[0]], p[ed[1]], c);
}
void DebugDraw::sphere(Vec3 center, float radius, Color c) {
    const int seg = 32;
    for (int axis = 0; axis < 3; ++axis) {
        for (int i = 0; i < seg; ++i) {
            float a0 = float(i) / seg * kTau, a1 = float(i + 1) / seg * kTau;
            auto pt = [&](float a) {
                float x = std::cos(a) * radius, y = std::sin(a) * radius;
                return axis == 0 ? Vec3{center.x, center.y + x, center.z + y}
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

// ---------------------------------------------------------------------------
// Renderer::Impl
// ---------------------------------------------------------------------------
struct Renderer::Impl {
    RendererDesc desc;
    bool initialized = false;
    bool inFrame = false;
    bool anyFrameRendered = false;
    int targetW = 0, targetH = 0;
    Gpu gpu;
    std::unique_ptr<Assets> assets;
    std::unique_ptr<Fonts> fonts;
    float textScale = 1.0f;  // Renderer::set_text_scale

    sg_image colorImg{}, resolveImg{}, depthImg{};
    sg_view colorAtt{}, resolveAtt{}, depthAtt{}, texView{};
    sg_view resolveColorAtt{};  // MSAA only: the resolved image as a color attachment (bloom composites into it)
    Bloom bloom;                // Camera.bloom post-process (intermediate targets are created on first use)
    sg_image shadowColor{}, shadowDepth{};
    sg_view shadowColorAtt{}, shadowDepthAtt{}, shadowTexView{};
    static constexpr int kShadowSize = 2048;

    DebugDraw debug;
    RenderStats stats;
    CameraInfo lastCam;
    bool warnedNoLight = false;
    bool updated = false;  // update() ran since the last draw
    ScaleMode scaleMode = ScaleMode::Fit;
    std::vector<Vertex2D> stream;

    void create_targets(int w, int h);
    void destroy_targets();
    void create_shadow_targets();
    CameraInfo build_camera(World& world);
    void render(World& world, float dt);
};

namespace {

struct Viewport { float x, y, w, h, scale; };

Viewport compute_viewport(ScaleMode mode, int fbW, int fbH, int tw, int th) {
    if (fbW <= 0 || fbH <= 0 || tw <= 0 || th <= 0) return {0, 0, float(fbW), float(fbH), 1.0f};
    switch (mode) {
        case ScaleMode::Stretch:
            return {0, 0, float(fbW), float(fbH), float(fbW) / float(tw)};
        case ScaleMode::PixelPerfect: {
            float s = std::floor(std::min(float(fbW) / tw, float(fbH) / th));
            if (s < 1.0f) s = std::min(float(fbW) / tw, float(fbH) / th);
            float w = tw * s, h = th * s;
            return {std::floor((fbW - w) * 0.5f), std::floor((fbH - h) * 0.5f), w, h, s};
        }
        case ScaleMode::Expand:
        case ScaleMode::Fit:
        default: {
            float s = std::min(float(fbW) / tw, float(fbH) / th);
            float w = tw * s, h = th * s;
            return {std::floor((fbW - w) * 0.5f), std::floor((fbH - h) * 0.5f), w, h, s};
        }
    }
}

template <class T>
void apply_uniforms(int slot, const T& u) {
    sg_range r{&u, sizeof(T)};
    sg_apply_uniforms(slot, &r);
}

void copy_mat(float* dst, const Mat4& m) { std::memcpy(dst, m.m, sizeof(float) * 16); }

struct MeshInstance {
    MeshAsset* mesh;
    Mat4 model;
    const MeshRenderer* mr;
    TextureAsset* overrideTex;
    float dist;
};

struct LightData {
    Vec4 pos, color, dir;
    int rank = 2;  // 0 = shadow-casting directional, 1 = directional, 2 = point/spot
};

}  // namespace

void Renderer::Impl::create_targets(int w, int h) {
    destroy_targets();
    targetW = std::max(1, w);
    targetH = std::max(1, h);
    int samples = gpu.sample_count();
    sg_image_desc cd{};
    cd.usage.color_attachment = true;
    cd.width = targetW; cd.height = targetH;
    cd.pixel_format = SG_PIXELFORMAT_RGBA8;
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
        rd.width = targetW; rd.height = targetH;
        rd.pixel_format = SG_PIXELFORMAT_RGBA8;
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
    dd.width = targetW; dd.height = targetH;
    dd.pixel_format = SG_PIXELFORMAT_DEPTH_STENCIL;
    dd.sample_count = samples;
    dd.label = "game-depth";
    depthImg = make_image(dd);
    sg_view_desc dv{};
    dv.depth_stencil_attachment.image = depthImg;
    depthAtt = sg_make_view(&dv);
}

void Renderer::Impl::destroy_targets() {
    bloom.release();
    for (sg_view* v : {&colorAtt, &resolveAtt, &resolveColorAtt, &depthAtt, &texView}) {
        if (v->id) sg_destroy_view(*v);
        *v = {};
    }
    for (sg_image* i : {&colorImg, &resolveImg, &depthImg}) {
        if (i->id) sg_destroy_image(*i);
        *i = {};
    }
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

CameraInfo Renderer::Impl::build_camera(World& world) {
    CameraInfo ci;
    Entity best = kNullEntity;
    int bestDepth = 0;
    world.each<Camera>([&](Entity e, Camera& c) {
        if (!c.primary || !world.active_in_hierarchy(e)) return;
        if (!best || c.depth < bestDepth) { best = e; bestDepth = c.depth; }
    });
    const bool z01 = gpu.depth_zero_to_one();
    float aspect = float(targetW) / float(targetH);
    Camera cam;  // defaults when no camera exists
    Mat4 camWorld;
    if (best) {
        cam = *world.get<Camera>(best);
        camWorld = world.world_matrix(best);
        ci.fromEntity = true;
    }
    // Remove scale from the camera's world matrix: view = R^T * T^-1.
    Vec3 t = camWorld.translation();
    Vec3 x = normalize(Vec3{camWorld.at(0, 0), camWorld.at(0, 1), camWorld.at(0, 2)});
    Vec3 y = normalize(Vec3{camWorld.at(1, 0), camWorld.at(1, 1), camWorld.at(1, 2)});
    Vec3 z = normalize(Vec3{camWorld.at(2, 0), camWorld.at(2, 1), camWorld.at(2, 2)});
    Mat4 view;
    view.at(0, 0) = x.x; view.at(1, 0) = x.y; view.at(2, 0) = x.z;
    view.at(0, 1) = y.x; view.at(1, 1) = y.y; view.at(2, 1) = y.z;
    view.at(0, 2) = z.x; view.at(1, 2) = z.y; view.at(2, 2) = z.z;
    view.at(3, 0) = -dot(x, t); view.at(3, 1) = -dot(y, t); view.at(3, 2) = -dot(z, t);
    ci.view = view;
    ci.position = t;
    ci.right = x; ci.up = y; ci.forward = -z;
    ci.clearColor = cam.clearColor;
    ci.clear = cam.clear;
    ci.bloom = sanitize_bloom(cam.bloom, cam.bloomThreshold, cam.bloomIntensity, cam.bloomRadius, cam.bloomScreenSpace);
    if (cam.projection == Projection::Perspective) {
        ci.perspective = true;
        ci.fov = cam.fov;
        ci.proj = Mat4::perspective(cam.fov, aspect, std::max(1e-3f, cam.nearPlane), std::max(cam.farPlane, cam.nearPlane + 0.01f), z01);
        ci.pixelsPerUnit = 1.0f;
    } else {
        float halfH = cam.orthoSize > 0 ? cam.orthoSize : float(targetH) * 0.5f;
        float halfW = halfH * aspect;
        if (scaleMode == ScaleMode::Expand && cam.orthoSize > 0) {
            // Expand: the design height (landscape-ish targets) or design width (taller targets) stays fixed;
            // the other axis grows with the window aspect.
            float designAspect = float(desc.designWidth) / float(std::max(1, desc.designHeight));
            if (aspect < designAspect) {
                halfW = cam.orthoSize * designAspect;
                halfH = halfW / aspect;
            }
        }
        ci.halfH = halfH; ci.halfW = halfW;
        ci.pixelsPerUnit = float(targetH) / (2.0f * halfH);
        ci.proj = Mat4::ortho(-halfW, halfW, -halfH, halfH, -1000.0f, 1000.0f, z01);
        ci.visible = Rect{t.x - halfW, t.y - halfH, halfW * 2, halfH * 2};
        // Rotated 2D cameras: use a conservative (circumscribed) rectangle for culling.
        float rad = std::sqrt(halfW * halfW + halfH * halfH);
        if (std::fabs(x.y) > 1e-3f) ci.visible = Rect{t.x - rad, t.y - rad, rad * 2, rad * 2};
    }
    ci.viewProj = ci.proj * ci.view;
    ci.invViewProj = ci.viewProj.inverse();
    return ci;
}

// ---------------------------------------------------------------------------
// Renderer
// ---------------------------------------------------------------------------
Renderer::Renderer() = default;
Renderer::~Renderer() { shutdown(); }

bool Renderer::initialized() const { return impl_ && impl_->initialized; }

bool Renderer::init(const RendererDesc& desc, const GfxEnvironment& env, std::string* error) {
    if (initialized()) return true;
    impl_ = std::make_unique<Impl>();
    Impl& im = *impl_;
    im.desc = desc;
    sg_desc sd{};
    sd.environment = env.get();
    sd.logger.func = fa_sokol_log_func;
    sd.buffer_pool_size = 2048;
    sd.image_pool_size = 1024;
    sd.view_pool_size = 4096;
    sd.sampler_pool_size = 64;
    sd.shader_pool_size = 32;
    sd.pipeline_pool_size = 256;
    sd.uniform_buffer_size = 16 * 1024 * 1024;
    sg_setup(&sd);
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
        sg_shutdown();
        impl_.reset();
        return false;
    }
    im.assets = std::make_unique<Assets>(im.gpu);
    im.fonts = std::make_unique<Fonts>(im.gpu, *im.assets);
    im.fonts->set_fallback_fonts(fallbackFonts_);
    im.textScale = textScale_;
    im.create_targets(desc.designWidth, desc.designHeight);
    im.initialized = true;
    return true;
}

void Renderer::shutdown() {
    if (!impl_) return;
    Impl& im = *impl_;
    if (im.initialized) {
        clear_particles();
        im.fonts.reset();
        im.assets.reset();
        im.destroy_targets();
        for (sg_view* v : {&im.shadowColorAtt, &im.shadowDepthAtt, &im.shadowTexView}) if (v->id) sg_destroy_view(*v);
        for (sg_image* i : {&im.shadowColor, &im.shadowDepth}) if (i->id) sg_destroy_image(*i);
        im.gpu.shutdown();
        sg_shutdown();
    }
    impl_.reset();
}

void Renderer::set_target_size(int width, int height) {
    if (!initialized()) return;
    if (width == impl_->targetW && height == impl_->targetH) return;
    impl_->create_targets(width, height);
}
int Renderer::target_width() const { return impl_ ? impl_->targetW : 0; }
int Renderer::target_height() const { return impl_ ? impl_->targetH : 0; }

void Renderer::begin_frame() {
    if (!initialized()) return;
    impl_->inFrame = true;
    impl_->gpu.begin_frame();
}

void Renderer::note_commit() {
    if (initialized()) impl_->gpu.note_commit();
}

DebugDraw& Renderer::debug() {
    static DebugDraw dummy;
    return impl_ ? impl_->debug : dummy;
}
RenderStats Renderer::stats() const { return impl_ ? impl_->stats : RenderStats{}; }
std::uint32_t Renderer::game_target_image_id() const {
    if (!impl_) return 0;
    return (impl_->gpu.sample_count() > 1 ? impl_->resolveImg : impl_->colorImg).id;
}
std::uint32_t Renderer::game_target_view_id() const { return impl_ ? impl_->texView.id : 0; }

void Renderer::reload_asset(std::string_view path) {
    if (impl_ && impl_->assets) impl_->assets->reload(std::string(path));
}
void Renderer::clear_asset_cache() {
    if (!impl_ || !impl_->assets) return;
    clear_particles();
    impl_->fonts->clear();
    impl_->assets->clear();
}
Json Renderer::asset_report() const {
    if (!impl_ || !impl_->assets) return Json::object();
    Json j = impl_->assets->report();
    j["fonts"] = impl_->fonts->report();
    return j;
}

// ---- camera helpers ----
Vec2 Renderer::world_to_screen(Vec3 p) const {
    if (!impl_) return {};
    Vec4 c = impl_->lastCam.viewProj * Vec4{p, 1.0f};
    float w = std::fabs(c.w) > 1e-8f ? c.w : 1e-8f;
    float nx = c.x / w, ny = c.y / w;
    return {(nx * 0.5f + 0.5f) * float(impl_->targetW), (1.0f - (ny * 0.5f + 0.5f)) * float(impl_->targetH)};
}

void Renderer::screen_ray(Vec2 s, Vec3& origin, Vec3& dir) const {
    origin = {}; dir = kForward;
    if (!impl_) return;
    const CameraInfo& c = impl_->lastCam;
    float nx = s.x / float(impl_->targetW) * 2.0f - 1.0f;
    float ny = 1.0f - s.y / float(impl_->targetH) * 2.0f;
    float nearZ = impl_->gpu.depth_zero_to_one() ? 0.0f : -1.0f;
    Vec3 a = c.invViewProj.transform_point({nx, ny, nearZ});
    Vec3 b = c.invViewProj.transform_point({nx, ny, 1.0f});
    origin = a;
    dir = normalize(b - a);
    if (c.perspective) origin = c.position;
}

Vec3 Renderer::screen_to_world(Vec2 s, float depth) const {
    Vec3 o, d;
    screen_ray(s, o, d);
    if (!impl_) return o;
    if (impl_->lastCam.perspective) return o + d * depth;
    if (std::fabs(d.z) < 1e-6f) return {o.x, o.y, depth};
    float t = (depth - o.z) / d.z;
    return o + d * t;
}

Vec2 Renderer::framebuffer_to_design(Vec2 fb, int fbW, int fbH, ScaleMode mode) const {
    int tw = impl_ ? impl_->targetW : fbW, th = impl_ ? impl_->targetH : fbH;
    Viewport vp = compute_viewport(mode, fbW, fbH, tw, th);
    if (vp.w <= 0 || vp.h <= 0) return fb;
    return {(fb.x - vp.x) / vp.w * float(tw), (fb.y - vp.y) / vp.h * float(th)};
}

// ---------------------------------------------------------------------------
// render_world
// ---------------------------------------------------------------------------
void Renderer::update(World& world, float dt) {
    if (!initialized()) return;
    Impl& im = *impl_;
    Frame fr;
    fr.dt = dt;
    fr.assets = im.assets.get();
    fr.fonts = im.fonts.get();
    fr.textScale = im.textScale;
    update_animators(world, fr, true);
    update_particles(world, dt);
    // Camera queries (world_to_screen, screen_to_world, screen_ray) must not depend on drawing:
    // the runtime skips drawing in headless/test runs, so refresh the camera here as well.
    im.lastCam = im.build_camera(world);
    im.updated = true;
}

void Renderer::emit_burst(Entity e, int count) {
    if (!initialized() || !e) return;
    queue_particle_burst(e.bits(), count);
}

void Renderer::set_scale_mode(ScaleMode mode) {
    if (impl_) impl_->scaleMode = mode;
}

Vec2 Renderer::measure_text(std::string_view text, float fontSize, std::string_view font, float maxWidth, RenderSpace space) const {
    if (!initialized() || text.empty() || fontSize <= 0.0f) return {0, 0};
    Text t;
    t.text = std::string(text);
    t.font = std::string(font);
    t.fontSize = fontSize;
    t.maxWidth = maxWidth;
    // The very layout of Text drawing at entity scale 1 (and of UI labels in screen space).
    return impl_->fonts->layout(t, space == RenderSpace::Screen ? fontSize * impl_->textScale : fontSize, 1.0f).size;
}

void Renderer::set_fallback_fonts(std::vector<std::string> fonts) {
    fallbackFonts_ = std::move(fonts);
    if (impl_ && impl_->fonts) impl_->fonts->set_fallback_fonts(fallbackFonts_);
}

void Renderer::set_text_scale(float scale) {
    textScale_ = std::isfinite(scale) ? std::clamp(scale, kMinTextScale, kMaxTextScale) : 1.0f;
    if (impl_) impl_->textScale = textScale_;
}

void Renderer::render_world(World& world, float dt) {
    if (!initialized()) return;
    if (!impl_->inFrame) begin_frame();
    if (!impl_->updated) update(world, dt);  // backward compatible: callers that only use render_world
    impl_->updated = false;
    impl_->render(world, dt);
}

void Renderer::Impl::render(World& world, float dt) {
    auto t0 = std::chrono::steady_clock::now();
    stats = RenderStats{};
    anyFrameRendered = true;

    Frame fr;
    fr.cam = build_camera(world);
    lastCam = fr.cam;
    fr.targetW = targetW;
    fr.targetH = targetH;
    fr.dt = dt;
    fr.stats = &stats;
    fr.assets = assets.get();
    fr.fonts = fonts.get();
    fr.textScale = textScale;

    flush_particle_bursts(world);
    update_animators(world, fr, false);
    gather_2d(world, fr);
    gather_ui(world, fr);
    gather_particles(world, fr);
    gather_debug(*debug.impl(), fr);
    fonts->sync();

    // ---- 3D gather ----
    std::vector<MeshInstance> opaque, blended;
    std::vector<LightData> lights;
    int shadowLight = -1;
    Vec3 lightDirForShadow{0, -1, 0};
    world.each<MeshRenderer>([&](Entity e, MeshRenderer& mr) {
        if (!world.active_in_hierarchy(e)) return;
        MeshAsset* ma = assets->mesh(mr.mesh);
        MeshInstance mi{ma, world.world_matrix(e), &mr, mr.texture.empty() ? nullptr : assets->texture(mr.texture), 0};
        mi.dist = length(mi.model.translation() - fr.cam.position);
        bool anyBlend = mr.color.a < 0.999f;
        for (auto& p : ma->parts) anyBlend = anyBlend || p.blended;
        (anyBlend ? blended : opaque).push_back(mi);
    });
    std::sort(blended.begin(), blended.end(), [](const MeshInstance& a, const MeshInstance& b) { return a.dist > b.dist; });
    world.each<Light>([&](Entity e, Light& l) {
        if (!world.active_in_hierarchy(e)) return;
        Mat4 m = world.world_matrix(e);
        LightData ld;
        Vec3 col{l.color.r * l.intensity, l.color.g * l.intensity, l.color.b * l.intensity};
        if (l.type == LightType::Directional) {
            Vec3 d = normalize(m.transform_dir(kForward));
            ld.pos = Vec4{-d, 0.0f};
            ld.color = Vec4{col, 0.0f};
            ld.dir = Vec4{d, 1.0f};
            ld.rank = 1;
            if (shadowLight < 0 && l.castShadows) { lightDirForShadow = d; shadowLight = 0; ld.rank = 0; }
        } else {
            Vec3 d = normalize(m.transform_dir(kForward));
            ld.pos = Vec4{m.translation(), l.range};
            ld.color = Vec4{col, l.type == LightType::Point ? 1.0f : 2.0f};
            ld.dir = Vec4{d, std::cos(radians(l.spotAngle))};
        }
        lights.push_back(ld);
    });
    // directional lights first; the shadow caster in slot 0
    std::stable_sort(lights.begin(), lights.end(), [](const LightData& a, const LightData& b) { return a.rank < b.rank; });
    if (lights.size() > size_t(kMaxLights)) lights.resize(kMaxLights);
    stats.lights = int(lights.size());
    bool haveShadowCaster = shadowLight >= 0 && !lights.empty() && lights[0].rank == 0;
    if (!opaque.empty() && lights.empty() && !warnedNoLight) {
        warnedNoLight = true;
        FA_WARN("render", "the scene has MeshRenderer entities but no Light entity: meshes only receive ambient light "
                          "(SceneSettings.ambientLight). Add an entity with a Light component (type Directional) or set MeshRenderer.unlit.");
    }

    // ---- shadow bounds ----
    Mat4 lightVP;
    bool doShadows = false;
    if (haveShadowCaster) {
        Vec3 bmin{1e30f, 1e30f, 1e30f}, bmax{-1e30f, -1e30f, -1e30f};
        bool any = false;
        for (auto* list : {&opaque, &blended}) {
            for (auto& mi : *list) {
                if (!mi.mr->castShadows) continue;
                for (auto& p : mi.mesh->parts) {
                    for (int c = 0; c < 8; ++c) {
                        Vec3 corner{(c & 1) ? p.bmax.x : p.bmin.x, (c & 2) ? p.bmax.y : p.bmin.y, (c & 4) ? p.bmax.z : p.bmin.z};
                        Vec3 w = mi.model.transform_point(corner);
                        bmin = min(bmin, w); bmax = max(bmax, w);
                        any = true;
                    }
                }
            }
        }
        if (any && gpu.shadows_supported()) {
            create_shadow_targets();
            Vec3 center = (bmin + bmax) * 0.5f;
            float radius = std::max(0.5f, length(bmax - bmin) * 0.5f);
            Vec3 up = std::fabs(lightDirForShadow.y) > 0.99f ? Vec3{0, 0, 1} : Vec3{0, 1, 0};
            Mat4 lv = Mat4::look_at(center - lightDirForShadow * (radius * 2.0f), center, up);
            Mat4 lp = Mat4::ortho(-radius, radius, -radius, radius, 0.1f, radius * 4.0f, gpu.depth_zero_to_one());
            lightVP = lp * lv;
            doShadows = true;
        }
    }

    // ---- flatten quads into one vertex stream ----
    struct Group { std::vector<QuadBatch> batches; };
    Group gWorld, gDebugWorld, gScreen, gDebugScreen;
    stream.clear();
    fr.world.flatten(stream, gWorld.batches);
    fr.debugWorld.flatten(stream, gDebugWorld.batches);
    fr.screen.flatten(stream, gScreen.batches);
    fr.debugScreen.flatten(stream, gDebugScreen.batches);
    std::size_t lineFirst = stream.size();
    stream.insert(stream.end(), fr.debugLines.begin(), fr.debugLines.end());

    sg_buffer vbuf{};
    if (!stream.empty()) {
        vbuf = gpu.acquire_transient(stream.size() * sizeof(Vertex2D));
        sg_write_buffer_desc wd{};
        wd.src.data = {stream.data(), stream.size() * sizeof(Vertex2D)};
        wd.dst.buffer = vbuf;
        sg_write_buffer_transient(&wd);
    }

    const bool z01 = gpu.depth_zero_to_one();
    Mat4 screenProj = Mat4::ortho(0, float(targetW), float(targetH), 0, -1000.0f, 1000.0f, z01);

    // ---- shadow pass ----
    if (doShadows) {
        sg_pass sp{};
        sp.action.colors[0].load_action = SG_LOADACTION_CLEAR;
        sp.action.colors[0].clear_value = {1, 1, 1, 1};
        sp.action.depth.load_action = SG_LOADACTION_CLEAR;
        sp.action.depth.clear_value = 1.0f;
        sp.attachments.colors[0] = shadowColorAtt;
        sp.attachments.depth_stencil = shadowDepthAtt;
        sp.label = "shadow";
        sg_begin_pass(&sp);
        sg_apply_pipeline(gpu.shadow_pipeline());
        for (auto* list : {&opaque, &blended}) {
            for (auto& mi : *list) {
                if (!mi.mr->castShadows) continue;
                shadow_shadow_vs_params_t u{};
                copy_mat(u.mvp, lightVP * mi.model);
                for (auto& p : mi.mesh->parts) {
                    sg_bindings b{};
                    b.vertex_buffers[0] = p.vb;
                    b.index_buffer = p.ib;
                    sg_apply_bindings(&b);
                    apply_uniforms(UB_shadow_shadow_vs_params, u);
                    sg_draw(0, p.indexCount, 1);
                    ++stats.drawCalls;
                }
            }
        }
        sg_end_pass();
    }

    // ---- main pass ----
    // Camera.bloomScreenSpace = false: the frame is split in two passes. This one draws the world, the bloom then
    // glows it, and a second pass (below) draws the screen-space groups (HUD) on top, so the HUD never glows.
    // With MSAA the multisampled image must survive the first pass (STORE): the bloom adds its glow to it and the
    // HUD pass loads it again, so the HUD is multisampled too and the final resolve contains everything.
    const bool msaa = gpu.sample_count() > 1;
    const bool hudAfterBloom = fr.cam.bloom.enabled && fr.cam.bloom.intensity > 0.0f && !fr.cam.bloom.screenSpace;
    sg_pass mp{};
    mp.action.colors[0].load_action = fr.cam.clear ? SG_LOADACTION_CLEAR : SG_LOADACTION_LOAD;
    mp.action.colors[0].clear_value = {fr.cam.clearColor.r, fr.cam.clearColor.g, fr.cam.clearColor.b, fr.cam.clearColor.a};
    mp.action.colors[0].store_action = (msaa && !hudAfterBloom) ? SG_STOREACTION_DONTCARE : SG_STOREACTION_STORE;
    mp.action.depth.load_action = SG_LOADACTION_CLEAR;
    mp.action.depth.clear_value = 1.0f;
    mp.action.stencil.load_action = SG_LOADACTION_CLEAR;
    mp.attachments.colors[0] = colorAtt;
    if (gpu.sample_count() > 1) mp.attachments.resolves[0] = resolveAtt;
    mp.attachments.depth_stencil = depthAtt;
    mp.label = "game";
    sg_begin_pass(&mp);

    // sky
    if (fr.cam.perspective && fr.cam.clear) {
        sg_apply_pipeline(gpu.sky_pipeline());
        sg_bindings b{};
        b.vertex_buffers[0] = gpu.fullscreen_triangle();
        sg_apply_bindings(&b);
        sky_sky_vs_params_t vu{};
        copy_mat(vu.inv_view_proj, fr.cam.invViewProj);
        vu.cam_pos[0] = fr.cam.position.x; vu.cam_pos[1] = fr.cam.position.y; vu.cam_pos[2] = fr.cam.position.z;
        apply_uniforms(UB_sky_sky_vs_params, vu);
        sky_sky_fs_params_t fu{};
        const SceneSettings& ss = world.settings();
        fu.sky_color[0] = ss.skyColor.r; fu.sky_color[1] = ss.skyColor.g; fu.sky_color[2] = ss.skyColor.b; fu.sky_color[3] = 1;
        fu.horizon_color[0] = ss.horizonColor.r; fu.horizon_color[1] = ss.horizonColor.g; fu.horizon_color[2] = ss.horizonColor.b; fu.horizon_color[3] = 1;
        apply_uniforms(UB_sky_sky_fs_params, fu);
        sg_draw(0, 3, 1);
        ++stats.drawCalls;
    }

    // meshes
    auto draw_meshes = [&](std::vector<MeshInstance>& list, bool isBlend) {
        const SceneSettings& ss = world.settings();
        for (auto& mi : list) {
            Mat4 mvp = fr.cam.viewProj * mi.model;
            mesh_mesh_vs_params_t vu{};
            copy_mat(vu.mvp, mvp);
            copy_mat(vu.model, mi.model);
            copy_mat(vu.normal_mat, mi.model.inverse().transposed());
            copy_mat(vu.light_vp, lightVP);
            vu.uv_scale[0] = mi.mr->uvScale.x; vu.uv_scale[1] = mi.mr->uvScale.y;
            mesh_mesh_fs_params_t fu{};
            fu.camera_pos[0] = fr.cam.position.x; fu.camera_pos[1] = fr.cam.position.y; fu.camera_pos[2] = fr.cam.position.z;
            fu.ambient[0] = ss.ambientLight.r; fu.ambient[1] = ss.ambientLight.g; fu.ambient[2] = ss.ambientLight.b;
            fu.emissive[0] = mi.mr->emissive.r; fu.emissive[1] = mi.mr->emissive.g; fu.emissive[2] = mi.mr->emissive.b;
            fu.emissive[3] = mi.mr->unlit ? 1.0f : 0.0f;
            fu.material[0] = saturate(mi.mr->metallic);
            fu.material[1] = saturate(mi.mr->roughness);
            fu.material[2] = (doShadows && mi.mr->receiveShadows) ? 1.0f : 0.0f;
            fu.material[3] = 0.0015f;
            fu.fog[0] = ss.fogColor.r; fu.fog[1] = ss.fogColor.g; fu.fog[2] = ss.fogColor.b; fu.fog[3] = ss.fogDensity;
            fu.counts[0] = float(lights.size());
            fu.counts[1] = 1.0f / float(kShadowSize);
            fu.counts[2] = gpu.is_gl() ? 1.0f : 0.0f;
            for (std::size_t i = 0; i < lights.size(); ++i) {
                for (int c = 0; c < 4; ++c) {
                    fu.light_pos[i][c] = lights[i].pos[c];
                    fu.light_color[i][c] = lights[i].color[c];
                    fu.light_dir[i][c] = lights[i].dir[c];
                }
            }
            for (auto& part : mi.mesh->parts) {
                sg_apply_pipeline(gpu.mesh_pipeline(isBlend, part.doubleSided));
                TextureAsset* tex = mi.overrideTex ? mi.overrideTex : (part.texture ? part.texture : assets->white());
                sg_bindings b{};
                b.vertex_buffers[0] = part.vb;
                b.index_buffer = part.ib;
                b.views[VIEW_mesh_tex] = tex->gpu_view();
                b.samplers[SMP_mesh_smp] = gpu.sampler(SamplerKind::LinearRepeat);
                b.views[VIEW_mesh_shadow_tex] = doShadows ? shadowTexView : assets->white()->view;
                b.samplers[SMP_mesh_shadow_smp] = gpu.sampler(SamplerKind::Nearest);
                sg_apply_bindings(&b);
                apply_uniforms(UB_mesh_mesh_vs_params, vu);
                Color base = mi.mr->color * part.baseColor;
                fu.base_color[0] = base.r; fu.base_color[1] = base.g; fu.base_color[2] = base.b; fu.base_color[3] = base.a;
                apply_uniforms(UB_mesh_mesh_fs_params, fu);
                sg_draw(0, part.indexCount, 1);
                ++stats.drawCalls;
                stats.triangles += part.indexCount / 3;
            }
            ++stats.meshes;
        }
    };
    draw_meshes(opaque, false);
    draw_meshes(blended, true);

    // quad groups
    auto draw_group = [&](const std::vector<QuadBatch>& batches, const Mat4& vp, bool depthTest) {
        if (batches.empty()) return;
        quad_vs_params_t u{};
        copy_mat(u.view_proj, vp);
        Rect scissor;  // the clip applied now (w <= 0: the whole target); a ScrollList's content is cut at its rectangle
        auto apply_clip = [&](const Rect& c) {
            if (c == scissor) return;
            scissor = c;
            Rect r = c.w > 0 ? c : Rect{0, 0, float(targetW), float(targetH)};
            const int x0 = std::clamp(int(std::lround(r.x)), 0, targetW), y0 = std::clamp(int(std::lround(r.y)), 0, targetH);
            const int x1 = std::clamp(int(std::lround(r.x + r.w)), x0, targetW), y1 = std::clamp(int(std::lround(r.y + r.h)), y0, targetH);
            sg_apply_scissor_rect(x0, y0, x1 - x0, y1 - y0, true);
        };
        for (const QuadBatch& qb : batches) {
            apply_clip(qb.clip);
            sg_apply_pipeline(gpu.quad_pipeline(depthTest, false, qb.blend));
            apply_uniforms(UB_quad_vs_params, u);
            std::uint32_t done = 0;
            while (done < qb.quadCount) {
                std::uint32_t n = std::min<std::uint32_t>(qb.quadCount - done, kMaxQuadsPerDraw);
                sg_bindings b{};
                b.vertex_buffers[0] = vbuf;
                b.vertex_buffer_offsets[0] = int((qb.firstQuad + done) * 4 * sizeof(Vertex2D));
                b.index_buffer = gpu.quad_index_buffer();
                b.views[VIEW_quad_tex] = qb.tex->gpu_view();
                b.samplers[SMP_quad_smp] = gpu.sampler(qb.smp);
                sg_apply_bindings(&b);
                sg_draw(0, int(n * 6), 1);
                ++stats.drawCalls;
                done += n;
            }
        }
        apply_clip(Rect{});
    };
    draw_group(gWorld.batches, fr.cam.viewProj, fr.cam.perspective);
    draw_group(gDebugWorld.batches, fr.cam.viewProj, false);
    if (!fr.debugLines.empty()) {
        sg_apply_pipeline(gpu.quad_pipeline(false, true));
        quad_vs_params_t u{};
        copy_mat(u.view_proj, fr.cam.viewProj);
        apply_uniforms(UB_quad_vs_params, u);
        sg_bindings b{};
        b.vertex_buffers[0] = vbuf;
        b.vertex_buffer_offsets[0] = int(lineFirst * sizeof(Vertex2D));
        b.views[VIEW_quad_tex] = assets->white()->view;
        b.samplers[SMP_quad_smp] = gpu.sampler(SamplerKind::Nearest);
        sg_apply_bindings(&b);
        sg_draw(0, int(fr.debugLines.size()), 1);
        ++stats.drawCalls;
    }
    if (!hudAfterBloom) {
        draw_group(gScreen.batches, screenProj, false);
        draw_group(gDebugScreen.batches, screenProj, false);
    }

    sg_end_pass();

    // ---- post-process: bloom adds its glow into the game target ----
    if (fr.cam.bloom.enabled) {
        BloomTarget dst;
        if (hudAfterBloom && msaa) {
            // Glow into the multisampled image (resolved again at the end of the composite pass) so the HUD pass below
            // can load it. Reads the already resolved image of the main pass.
            dst = BloomTarget{colorAtt, resolveAtt, gpu.sample_count()};
        } else {
            // The finished frame: the resolved image when MSAA is on (the main pass already resolved into it).
            dst = BloomTarget{msaa ? resolveColorAtt : colorAtt, sg_view{}, 1};
        }
        stats.drawCalls += bloom.apply(gpu, fr.cam.bloom, targetW, targetH, texView, dst);
    }

    // ---- HUD pass (Camera.bloomScreenSpace = false): screen-space groups over the glowing frame ----
    if (hudAfterBloom && (!gScreen.batches.empty() || !gDebugScreen.batches.empty())) {
        sg_pass hp{};
        hp.action.colors[0].load_action = SG_LOADACTION_LOAD;  // keep the world and its glow
        hp.action.colors[0].store_action = msaa ? SG_STOREACTION_DONTCARE : SG_STOREACTION_STORE;
        hp.action.depth.load_action = SG_LOADACTION_CLEAR;
        hp.action.depth.clear_value = 1.0f;
        hp.action.stencil.load_action = SG_LOADACTION_CLEAR;
        hp.attachments.colors[0] = colorAtt;
        if (msaa) hp.attachments.resolves[0] = resolveAtt;
        hp.attachments.depth_stencil = depthAtt;
        hp.label = "game-hud";
        sg_begin_pass(&hp);
        draw_group(gScreen.batches, screenProj, false);
        draw_group(gDebugScreen.batches, screenProj, false);
        sg_end_pass();
    }

    debug.clear();
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

void Renderer::present(const GfxSwapchain& swapchain, int fbW, int fbH, ScaleMode mode) {
    if (!initialized()) return;
    Impl& im = *impl_;
    const sg_swapchain& sc = swapchain.get();
    im.scaleMode = mode;
    Viewport vp = compute_viewport(mode, fbW, fbH, im.targetW, im.targetH);
    sg_pass pass{};
    pass.action.colors[0].load_action = SG_LOADACTION_CLEAR;
    pass.action.colors[0].clear_value = {0, 0, 0, 1};
    pass.swapchain = sc;
    pass.label = "present";
    sg_begin_pass(&pass);
    sg_apply_viewportf(vp.x, vp.y, vp.w, vp.h, true);
    sg_apply_pipeline(im.gpu.blit_pipeline(sc.color_format, sc.depth_format, sc.sample_count > 0 ? sc.sample_count : 1));
    sg_bindings b{};
    b.vertex_buffers[0] = im.gpu.fullscreen_triangle();
    b.views[VIEW_blit_tex] = im.texView;
    bool integer = mode == ScaleMode::PixelPerfect || std::fabs(vp.scale - std::round(vp.scale)) < 1e-3f;
    b.samplers[SMP_blit_smp] = im.gpu.sampler(integer ? SamplerKind::Nearest : SamplerKind::Linear);
    sg_apply_bindings(&b);
    blit_blit_vs_params_t u{};
    u.flip[0] = im.gpu.is_gl() ? 1.0f : 0.0f;
    apply_uniforms(UB_blit_blit_vs_params, u);
    sg_draw(0, 3, 1);
    sg_end_pass();
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
    sg_image img = im.gpu.sample_count() > 1 ? im.resolveImg : im.colorImg;
    std::vector<std::uint8_t> px;
    if (!readback_rgba8(img, im.targetW, im.targetH, px, error)) return false;
    out.width = im.targetW;
    out.height = im.targetH;
    out.rgba = std::move(px);
    return true;
}

}  // namespace fa
