#include "fa/render/renderer.h"

#include <algorithm>
#include <chrono>
#include <cmath>
#include <cstring>

#include "fa/core/fs.h"
#include "fa/core/log.h"
#include "fa/core/profiler.h"
#include "fa/platform/sokol_logging.h"
#include "fa/scene/text_fit.h"
#include "fa/scene/ui_rect.h"
#include "bloom.h"
#include "shaders/colorfilter.glsl.h"
#include "frame.h"
#include "mesh_batch.h"
#include "render_internal.h"

#include "shaders/blit.glsl.h"
#include "shaders/light.glsl.h"
#include "shaders/mesh.glsl.h"
#include "shaders/quad.glsl.h"
#include "shaders/sky.glsl.h"

namespace fa {

using namespace render;

// ---------------------------------------------------------------------------
// RenderStats / DebugDraw
// ---------------------------------------------------------------------------
Json RenderStats::to_json() const {
    return Json{{"drawCalls", drawCalls}, {"sprites", sprites}, {"shapes", shapes}, {"textGlyphs", textGlyphs},
                {"particles", particles}, {"meshes", meshes}, {"meshesCulled", meshesCulled}, {"meshBatches", meshBatches},
                {"triangles", triangles}, {"shadowCasters", shadowCasters}, {"lights", lights}, {"lightsDropped", lightsDropped},
                {"lights2d", lights2d}, {"lights2dDropped", lights2dDropped}, {"lights2dShadowed", lights2dShadowed},
                {"materials", materials}, {"materialFallbacks", materialFallbacks},
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
    int targetW = 0, targetH = 0;  // logical (design) size: what layouts, cameras and Text are measured in
    float renderScale = 1.0f;      // GPU images are targetW*renderScale wide (Renderer::set_render_scale)
    int physW = 0, physH = 0;      // size of the GPU images
    Gpu gpu;
    GpuTimer gpuTimer;
    std::unique_ptr<Assets> assets;
    std::unique_ptr<Fonts> fonts;
    float textScale = 1.0f;  // Renderer::set_text_scale
    float uiScale = 1.0f;    // Renderer::set_ui_scale

    sg_image colorImg{}, resolveImg{}, depthImg{};
    sg_view colorAtt{}, resolveAtt{}, depthAtt{}, texView{};
    sg_view resolveColorAtt{};  // MSAA only: the resolved image as a color attachment (bloom composites into it)
    Bloom bloom;                // Camera.bloom post-process (intermediate targets are created on first use)
    // Camera.colorFilter: the filtered copy of the finished frame. A pass cannot read what it writes, so the filter
    // draws into this second image (made on first use) and present(), capture() and the editor viewport show it
    // while `filterActive` (the last frame was filtered).
    sg_image filterImg{};
    sg_view filterAtt{}, filterTex{};
    bool filterActive = false;
    sg_image shadowColor{}, shadowDepth{};
    sg_view shadowColorAtt{}, shadowDepthAtt{}, shadowTexView{};
    static constexpr int kShadowSize = 2048;

    DebugDraw debug;
    RenderStats stats;
    // The rendering cameras of the last update()/draw in draw order (never empty after the first one: a world without a camera
    // gets one default camera). [0] is "the" camera: the lowest depth.
    std::vector<CameraInfo> lastCams;
    bool warnedNoLight = false;
    std::string warnedViewport;       // the last "bad Camera.viewport" problem logged (a viewport a script sets live is clamped)
    bool warnedCameras = false;       // the "more cameras than the limit" warning, once per scene
    bool warnedLights2d = false;      // the "more Light2D in view than the budget" warning, once per scene
    bool warnedShadows2d = false;     // the "more shadow casters than the budget" warning, once per scene
    std::string lights2dScene;        // the scene path warnedLights2d and warnedShadows2d belong to
    // The 2D light buffer (light.glsl): the point lights of the frame added up, read by the lit visuals. Made when a frame
    // needs it, at lightScale of the target's size; kept while the size and the format stay.
    sg_image lightImg{};
    sg_view lightAtt{}, lightTexView{};
    int lightW = 0, lightH = 0;
    sg_pixel_format lightImgFormat = SG_PIXELFORMAT_NONE;
    bool lightTargetFailed = false;
    // The shadow rows of the lights with castShadows (light2d.cpp) as an image: an image is reused while its rows stay the
    // same, a new one replaces the oldest of the ring.
    ShadowCache shadowCache;
    // A ring: every camera of a frame may need its own rows, and an image a recorded draw reads is not destroyed within the
    // frame (kMaxCameras + 1 images).
    static constexpr int kShadowRowsRing = 9;
    sg_image shadowRowsImg[kShadowRowsRing]{};
    sg_view shadowRowsView[kShadowRowsRing]{};
    std::uint64_t shadowRowsKey[kShadowRowsRing]{};
    int shadowRowsCurrent = 0;
    bool updated = false;  // update() ran since the last draw
    ScaleMode scaleMode = ScaleMode::Fit;
    std::vector<Vertex2D> stream;

    void create_targets(int w, int h);
    void destroy_targets();
    int apply_color_filter(int mode);
    sg_image final_image() const { return filterActive ? filterImg : (gpu.sample_count() > 1 ? resolveImg : colorImg); }
    sg_view final_view() const { return filterActive ? filterTex : texView; }
    void create_shadow_targets();
    bool ensure_light_target(float scale);
    sg_view upload_shadow_rows(const Frame& fr);
    void destroy_light_resources();
    CameraInfo build_camera(World& world, Entity entity);
    std::vector<CameraInfo> collect_cameras(World& world);
    const CameraInfo& camera_for(Entity camera, const Vec2* screenPoint) const;
    struct JobPlan {
        bool first = false;  // the first pass of the frame: it clears the whole target when its camera clears
        bool last = false;   // the last job of the frame: it runs the post effects (bloom, the HUD over it, the colour filter)
        const CameraInfo* post = nullptr;  // the camera whose bloom, bloomScreenSpace and colorFilter the frame gets (the first)
    };
    void render(World& world, float dt);
    void draw_job(World& world, Frame& fr, const JobPlan& plan);
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

// The palette of glTF skin `skin` (a part is drawn with its own skin's); skin 0 when the animator has none for it.
const std::vector<Mat4>& palette_of(const Animator& a, int skin) {
    return skin > 0 && std::size_t(skin) < a.skinPalettes.size() ? a.skinPalettes[std::size_t(skin)] : a.palette;
}

// The joint palette as the shaders read it: kMaxSkinJoints skinning matrices of 3 rows (a vec4 each); unused joints are the
// identity (fa_skin of mesh_common.glsl, shared by the mesh and shadow programs).
mesh_fa_skin_t pack_palette(const std::vector<Mat4>& palette) {
    mesh_fa_skin_t u{};
    for (int j = 0; j < kMaxSkinJoints; ++j) {
        const Mat4 m = std::size_t(j) < palette.size() ? palette[std::size_t(j)] : Mat4::identity();
        for (int r = 0; r < 3; ++r)
            for (int c = 0; c < 4; ++c) u.fa_joint_rows[j * 3 + r][c] = m.at(c, r);
    }
    return u;
}

}  // namespace

void Renderer::Impl::create_targets(int w, int h) {
    destroy_targets();
    targetW = std::max(1, w);
    targetH = std::max(1, h);
    physW = std::max(1, int(std::lround(double(targetW) * renderScale)));
    physH = std::max(1, int(std::lround(double(targetH) * renderScale)));
    int samples = gpu.sample_count();
    sg_image_desc cd{};
    cd.usage.color_attachment = true;
    cd.width = physW; cd.height = physH;
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
        rd.width = physW; rd.height = physH;
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
    dd.width = physW; dd.height = physH;
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
    for (sg_view* v : {&colorAtt, &resolveAtt, &resolveColorAtt, &depthAtt, &texView}) {
        if (v->id) sg_destroy_view(*v);
        *v = {};
    }
    for (sg_image* i : {&colorImg, &resolveImg, &depthImg}) {
        if (i->id) sg_destroy_image(*i);
        *i = {};
    }
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
    if (sg_query_image_state(lightImg) != SG_RESOURCESTATE_VALID || sg_query_view_state(lightAtt) != SG_RESOURCESTATE_VALID ||
        sg_query_view_state(lightTexView) != SG_RESOURCESTATE_VALID) {
        FA_ERROR("render", "Cannot create the {}x{} 2D light buffer; lit visuals are shaded per pixel by the first {} lights only",
                 w, h, kDirectLights2D);
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
        d.pixel_format = SG_PIXELFORMAT_RGBA8;
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
        if (sg_query_image_state(filterImg) != SG_RESOURCESTATE_VALID || sg_query_view_state(filterAtt) != SG_RESOURCESTATE_VALID ||
            sg_query_view_state(filterTex) != SG_RESOURCESTATE_VALID) {
            FA_ERROR("render", "Camera.colorFilter: cannot create the {}x{} target; the game is drawn without the filter", physW, physH);
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

// The viewport a camera is drawn with: a valid Camera.viewport as it is, an invalid one (a script can set any value live; the
// scene loader refuses it in a file) clamped into the screen, or the whole screen when it has no size. Logs the problem once.
static Rect sanitize_viewport(const Rect& v, std::string& warned) {
    const std::string problem = camera_viewport_problem(v);
    if (problem.empty()) {
        const float x = std::clamp(v.x, 0.0f, 1.0f), y = std::clamp(v.y, 0.0f, 1.0f);
        return Rect{x, y, std::min(v.w, 1.0f - x), std::min(v.h, 1.0f - y)};
    }
    if (warned != problem) {
        warned = problem;
        FA_WARN("render", "{}: the camera is drawn with the nearest valid rectangle. Hint: viewport is [x, y, width, height] as "
                "fractions of the screen with [0, 0] the top-left corner, e.g. [0, 0, 0.5, 1] for the left half", problem);
    }
    if (!std::isfinite(v.x) || !std::isfinite(v.y) || !std::isfinite(v.w) || !std::isfinite(v.h) || v.w <= 0.0f || v.h <= 0.0f)
        return Rect{0, 0, 1, 1};
    const float x = std::clamp(v.x, 0.0f, 0.999f), y = std::clamp(v.y, 0.0f, 0.999f);
    return Rect{x, y, std::min(v.w, 1.0f - x), std::min(v.h, 1.0f - y)};
}

CameraInfo Renderer::Impl::build_camera(World& world, Entity best) {
    CameraInfo ci;
    const bool z01 = gpu.depth_zero_to_one();
    Camera cam;  // defaults when no camera exists
    Mat4 camWorld;
    if (best) {
        cam = *world.get<Camera>(best);
        camWorld = world.world_matrix(best);
        ci.fromEntity = true;
        ci.entity = best;
        ci.depth = cam.depth;
        ci.viewport = sanitize_viewport(cam.viewport, warnedViewport);
    }
    // The view is drawn into the viewport: its aspect and its height in design pixels are the rectangle's.
    const float viewW = float(targetW) * ci.viewport.w, viewH = float(targetH) * ci.viewport.h;
    const float aspect = viewW / std::max(viewH, 1.0f);
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
    ci.colorFilter = std::clamp(int(cam.colorFilter), 0, 5);
    ci.bloom = sanitize_bloom(cam.bloom, cam.bloomThreshold, cam.bloomIntensity, cam.bloomRadius, cam.bloomScreenSpace);
    if (cam.projection == Projection::Perspective) {
        ci.perspective = true;
        ci.fov = cam.fov;
        ci.proj = Mat4::perspective(cam.fov, aspect, std::max(1e-3f, cam.nearPlane), std::max(cam.farPlane, cam.nearPlane + 0.01f), z01);
        ci.pixelsPerUnit = 1.0f;
    } else {
        float halfH = cam.orthoSize > 0 ? cam.orthoSize : viewH * 0.5f;
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
        ci.pixelsPerUnit = viewH / (2.0f * halfH);
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

// Every active camera with primary = true, ascending Camera.depth (equal depths keep the order of creation); a world without
// one gets a default camera.
std::vector<CameraInfo> Renderer::Impl::collect_cameras(World& world) {
    struct Found { Entity e; int depth; };
    std::vector<Found> found;
    world.each<Camera>([&](Entity e, Camera& c) {
        if (c.primary && world.active_in_hierarchy(e)) found.push_back({e, c.depth});
    });
    std::stable_sort(found.begin(), found.end(), [](const Found& a, const Found& b) { return a.depth < b.depth; });
    constexpr std::size_t kMaxCameras = 8;
    if (found.size() > kMaxCameras) {
        if (!warnedCameras) {
            warnedCameras = true;
            FA_WARN("render", "{} cameras are active (primary) but a frame draws at most {}: the ones with the highest depth are "
                    "left out. Hint: set primary to false on the cameras you do not need, e.g. when a split screen ends",
                    found.size(), kMaxCameras);
        }
        found.resize(kMaxCameras);
    }
    std::vector<CameraInfo> out;
    for (const Found& f : found) out.push_back(build_camera(world, f.e));
    if (out.empty()) out.push_back(build_camera(world, kNullEntity));
    return out;
}

// The camera a query uses: `camera` when it is a rendering camera; else (a screen point given) the topmost camera whose
// viewport contains the point; else the first. `lastCams` is never empty after the first update().
const CameraInfo& Renderer::Impl::camera_for(Entity camera, const Vec2* screenPoint) const {
    static const CameraInfo kNone{};
    if (lastCams.empty()) return kNone;
    if (camera)
        for (const CameraInfo& c : lastCams)
            if (c.entity == camera) return c;
    if (screenPoint && lastCams.size() > 1 && targetW > 0 && targetH > 0) {
        const float nx = screenPoint->x / float(targetW), ny = screenPoint->y / float(targetH);
        for (std::size_t i = lastCams.size(); i-- > 0;) {
            const Rect& v = lastCams[i].viewport;
            if (nx >= v.x && nx < v.x + v.w && ny >= v.y && ny < v.y + v.h) return lastCams[i];
        }
    }
    return lastCams.front();
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
    sd.shader_pool_size = 256;  // 11 built-in shaders, up to 4 per custom material
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
    im.assets->set_shader_compiler(shaderCompiler_);
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
    if (im.initialized) {
        clear_particles();
        im.fonts.reset();
        im.assets.reset();
        im.destroy_targets();
        im.destroy_light_resources();
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
void Renderer::set_render_scale(float scale) {
    if (!initialized()) return;
    if (!(scale >= kMinRenderScale)) scale = 1.0f;
    scale = std::min(scale, kMaxRenderScale);
    if (scale == impl_->renderScale) return;
    impl_->renderScale = scale;
    impl_->create_targets(impl_->targetW, impl_->targetH);
}
const char* Renderer::backend_name() {
    switch (sg_query_backend()) {
        case SG_BACKEND_GLCORE: return "glcore";
        case SG_BACKEND_GLES3: return "gles3";
        case SG_BACKEND_D3D11: return "d3d11";
        case SG_BACKEND_METAL_IOS:
        case SG_BACKEND_METAL_MACOS:
        case SG_BACKEND_METAL_SIMULATOR: return "metal";
        case SG_BACKEND_WGPU: return "wgpu";
        case SG_BACKEND_VULKAN: return "vulkan";
        default: return "dummy";
    }
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
    return impl_->final_image().id;
}
std::uint32_t Renderer::game_target_view_id() const { return impl_ ? impl_->final_view().id : 0; }

void Renderer::reload_asset(std::string_view path) {
    if (impl_ && impl_->assets) impl_->assets->reload(std::string(path));
}
void Renderer::set_shader_compiler(ShaderCompiler compiler) {
    shaderCompiler_ = std::move(compiler);
    if (impl_ && impl_->assets) impl_->assets->set_shader_compiler(shaderCompiler_);
}
std::string Renderer::shader_dialect() const { return initialized() ? backend_dialect(sg_query_backend()) : std::string(); }
void Renderer::clear_asset_cache() {
    if (!impl_ || !impl_->assets) return;
    clear_particles();
    impl_->fonts->clear();
    impl_->assets->clear();
}
std::uint64_t Renderer::texture_bytes() const { return impl_ && impl_->assets ? impl_->assets->texture_bytes() : 0; }

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
    if (impl_ && Profiler::on()) impl_->gpuTimer.poll(out);
}

Json Renderer::asset_report() const {
    if (!impl_ || !impl_->assets) return Json::object();
    Json j = impl_->assets->report();
    j["fonts"] = impl_->fonts->report();
    return j;
}

// ---- camera helpers ----
Vec2 Renderer::world_to_screen(Vec3 p, Entity camera) const {
    if (!impl_) return {};
    const CameraInfo& cam = impl_->camera_for(camera, nullptr);
    Vec4 c = cam.viewProj * Vec4{p, 1.0f};
    float w = std::fabs(c.w) > 1e-8f ? c.w : 1e-8f;
    float nx = c.x / w, ny = c.y / w;
    const Rect& v = cam.viewport;  // ndc -1..1 spans the viewport, not the whole target
    return {(v.x + (nx * 0.5f + 0.5f) * v.w) * float(impl_->targetW), (v.y + (1.0f - (ny * 0.5f + 0.5f)) * v.h) * float(impl_->targetH)};
}

void Renderer::screen_ray(Vec2 s, Vec3& origin, Vec3& dir, Entity camera) const {
    origin = {}; dir = kForward;
    if (!impl_) return;
    const CameraInfo& c = impl_->camera_for(camera, &s);
    const Rect& v = c.viewport;
    float nx = ((s.x / float(impl_->targetW) - v.x) / v.w) * 2.0f - 1.0f;
    float ny = 1.0f - ((s.y / float(impl_->targetH) - v.y) / v.h) * 2.0f;
    float nearZ = impl_->gpu.depth_zero_to_one() ? 0.0f : -1.0f;
    Vec3 a = c.invViewProj.transform_point({nx, ny, nearZ});
    Vec3 b = c.invViewProj.transform_point({nx, ny, 1.0f});
    origin = a;
    dir = normalize(b - a);
    if (c.perspective) origin = c.position;
}

Vec3 Renderer::screen_to_world(Vec2 s, float depth, Entity camera) const {
    Vec3 o, d;
    screen_ray(s, o, d, camera);
    if (!impl_) return o;
    if (impl_->camera_for(camera, &s).perspective) return o + d * depth;
    if (std::fabs(d.z) < 1e-6f) return {o.x, o.y, depth};
    float t = (depth - o.z) / d.z;
    return o + d * t;
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
render::Gpu* render::renderer_gpu(Renderer& r) { return r.impl_ ? &r.impl_->gpu : nullptr; }

void Renderer::update(World& world, float dt) {
    if (!initialized()) return;
    Impl& im = *impl_;
    Frame fr;
    fr.dt = dt;
    fr.assets = im.assets.get();
    fr.fonts = im.fonts.get();
    fr.textScale = im.textScale;
    fr.uiScale = ui_scale_clamped(world.ui_scale());
    update_animators(world, fr, true);
    update_particles(world, dt);
    // Camera queries (world_to_screen, screen_to_world, screen_ray, camera_at) must not depend on drawing:
    // the runtime skips drawing in headless/test runs, so refresh the camera here as well.
    im.lastCams = im.collect_cameras(world);
    update_parallax(world, im.lastCams.front().position.xy());  // entity.bounds() of a parallax layer follows the camera in headless runs too
    im.updated = true;
}

void Renderer::emit_burst(Entity e, int count) {
    if (!initialized() || !e) return;
    queue_particle_burst(e.bits(), count);
}

void Renderer::set_scale_mode(ScaleMode mode) {
    if (impl_) impl_->scaleMode = mode;
}

Vec2 Renderer::measure_text(std::string_view text, float fontSize, std::string_view font, float maxWidth, RenderSpace space,
                            TextStyle style) const {
    if (!initialized() || text.empty() || fontSize <= 0.0f) return {0, 0};
    Text t;
    t.markup = style.markup;
    t.bold = style.bold;
    t.text = std::string(text);
    t.font = std::string(font);
    t.fontSize = fontSize;
    t.maxWidth = maxWidth;
    // The very layout of Text drawing at entity scale 1 (and of UI labels in screen space). Screen-space text is drawn at the
    // interface scale (ui.scale), rasterized k times as large, so it is measured at that raster size too (the result is in
    // UI units, not multiplied by k).
    const bool screen = space == RenderSpace::Screen;
    return impl_->fonts->layout(t, screen ? fontSize * impl_->textScale : fontSize, screen ? impl_->uiScale : 1.0f).size;
}

Vec2 Renderer::measure_text(const Text& text) const {
    if (!initialized() || text.text.empty() || text.fontSize <= 0.0f) return {0, 0};
    const bool screen = text.space == RenderSpace::Screen;
    const TextExtent extent = [this, screen](const std::string& s, const std::string& font, float px, float wrap, TextStyle style) {
        Text t;
        t.text = s;
        t.font = font;
        t.maxWidth = wrap;
        t.markup = style.markup;
        t.bold = style.bold;
        return impl_->fonts->layout(t, px, screen ? impl_->uiScale : 1.0f).size;  // px is final: no text scale
    };
    return fit_text(text_fit_spec(text), text.text, text.font, textScale_, extent).size;
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
    if (!impl_->inFrame) begin_frame();
    if (!impl_->updated) update(world, dt);  // backward compatible: callers that only use render_world
    impl_->updated = false;
    impl_->render(world, dt);
}

// One frame: the cameras drawn in depth order (each into its viewport rectangle: its own culling, 2D lights, 3D lights, clear)
// and then, when the cameras do not fill the screen together with a single full-screen camera, the screen-space items
// (Sprite/Shape2D/Text/ParticleEmitter with space "screen", UI, debug text) once over the whole screen. A game with one
// camera and no viewport is one job that draws all of it in one pass, as before. Bloom and Camera.colorFilter act once over
// the finished frame, with the settings of the first camera.
void Renderer::Impl::render(World& world, float dt) {
    auto t0 = std::chrono::steady_clock::now();
    if (Profiler::on()) gpuTimer.begin();
    stats = RenderStats{};
    anyFrameRendered = true;

    lastCams = collect_cameras(world);
    ++shadowCache.tick;  // one per drawn frame, not per camera: every camera of this frame keeps the rows it reads
    if (world.scene_path() != lights2dScene) {
        lights2dScene = world.scene_path();
        warnedLights2d = false;
        warnedShadows2d = false;
        warnedCameras = false;
    }

    struct JobSpec { CameraInfo cam; bool world = true, screen = true; };
    std::vector<JobSpec> specs;
    const bool split = !(lastCams.size() == 1 && lastCams.front().fullViewport());
    if (!split) {
        specs.push_back({lastCams.front(), true, true});
    } else {
        for (const CameraInfo& c : lastCams) specs.push_back({c, true, false});
        specs.push_back({lastCams.front(), false, true});
    }

    flush_particle_bursts(world);
    std::vector<Frame> frames(specs.size());
    for (std::size_t i = 0; i < specs.size(); ++i) {
        Frame& fr = frames[i];
        fr.cam = specs[i].cam;
        fr.wantWorld = specs[i].world;
        fr.wantScreen = specs[i].screen;
        fr.targetW = targetW;
        fr.targetH = targetH;
        fr.dt = dt;
        fr.stats = &stats;
        fr.assets = assets.get();
        fr.fonts = fonts.get();
        fr.textScale = textScale;
        fr.uiScale = ui_scale_clamped(world.ui_scale());
        fr.renderScale = renderScale;
        fr.warnedLights2d = &warnedLights2d;
        fr.warnedShadows2d = &warnedShadows2d;
        fr.shadowCache = &shadowCache;
        update_animators(world, fr, false);
        gather_2d(world, fr);
        if (fr.wantScreen) gather_ui(world, fr);
        gather_particles(world, fr);
        gather_debug(*debug.impl(), fr);
    }
    // After every gather: the glyph atlas may be remade by a sync, which no job of this frame has recorded a draw with yet.
    fonts->sync();
    // The screen-space job of a split frame is dropped when it has nothing to draw (a pass less).
    if (split && frames.back().screen.empty() && frames.back().debugScreen.empty()) {
        frames.pop_back();
        specs.pop_back();
    }

    const CameraInfo post = specs.front().cam;
    for (std::size_t i = 0; i < frames.size(); ++i) {
        JobPlan plan;
        plan.first = i == 0;
        plan.last = i + 1 == frames.size();
        plan.post = &post;
        draw_job(world, frames[i], plan);
    }

    debug.clear();
    gpuTimer.end();  // closes the query begun above even if the profiler was switched off meanwhile
    auto t1 = std::chrono::steady_clock::now();
    stats.cpuMs = std::chrono::duration<double, std::milli>(t1 - t0).count();
}

// Draws one job of the frame into the game target: the pass(es) of one camera's world (and, for the single full-screen
// camera, the screen-space items too), or the screen-space pass of a split frame. The last job also runs the post effects.
void Renderer::Impl::draw_job(World& world, Frame& fr, const JobPlan& plan) {
    const CameraInfo& post = *plan.post;
    const bool hudAfterBloom = post.bloom.enabled && post.bloom.intensity > 0.0f && !post.bloom.screenSpace;
    // The pixels (of the GPU images, `scale` times the design size) of a fraction of the target. The edges are rounded, not
    // the sizes, so neighbouring viewports meet without a gap or an overlap.
    struct Px { int x = 0, y = 0, w = 0, h = 0; };
    auto px_rect = [](const Rect& v, int W, int H) {
        const int x0 = std::clamp(int(std::lround(double(v.x) * W)), 0, W), y0 = std::clamp(int(std::lround(double(v.y) * H)), 0, H);
        const int x1 = std::clamp(int(std::lround(double(v.x + v.w) * W)), x0, W), y1 = std::clamp(int(std::lround(double(v.y + v.h) * H)), y0, H);
        return Px{x0, y0, x1 - x0, y1 - y0};
    };
    const Px fullPx{0, 0, physW, physH};
    const Px camPx = fr.wantWorld ? px_rect(fr.cam.viewport, physW, physH) : fullPx;
    const bool partial = fr.wantWorld && !fr.cam.fullViewport();
    auto apply_view = [](const Px& r) {
        sg_apply_viewport(r.x, r.y, r.w, r.h, true);
        sg_apply_scissor_rect(r.x, r.y, r.w, r.h, true);
    };
    // A camera that clears and is not the first one (or the only one) cannot use a load action (it clears the whole target,
    // not its rectangle): a colour quad over its viewport does it.
    const bool clearByQuad = fr.wantWorld && fr.cam.clear && partial && !plan.first;
    const bool clearByLoad = fr.wantWorld && fr.cam.clear && (plan.first || !partial);

    // ---- 3D gather ----
    const bool z01 = gpu.depth_zero_to_one();
    std::vector<MeshItem> opaque, blended;
    std::vector<LightData> lights;
    int shadowLight = -1;
    Vec3 lightDirForShadow{0, -1, 0};
    if (fr.wantWorld) world.each<MeshRenderer>([&](Entity e, MeshRenderer& mr) {
        if (!world.active_in_hierarchy(e)) return;
        MeshItem mi;
        mi.mesh = assets->mesh(mr.mesh);
        mi.model = world.world_matrix(e);
        mi.mr = &mr;
        mi.tex = mr.texture.empty() ? nullptr : assets->texture(mr.texture);
        mi.material = mr.material.empty() ? nullptr : assets->material(mr.material);
        if (mi.material && mr.materialParams.is_object() && !mr.materialParams.empty())
            mi.paramsHash = std::hash<std::string>{}(mr.materialParams.dump());
        if (mr.materialColors.is_object() && !mr.materialColors.empty())
            mi.colorsHash = std::hash<std::string>{}(mr.materialColors.dump());
        mi.normalTex = mr.normalMap.empty() ? nullptr : assets->texture(mr.normalMap);
        mi.dist = length(mi.model.translation() - fr.cam.position);
        mi.bmin = mi.mesh->bmin;
        mi.bmax = mi.mesh->bmax;
        // A skinned model with a computed pose is drawn deformed by the Animator's palette (before its first fixed step the
        // palette is empty and the model shows in bind pose).
        const Animator* anim = world.get<Animator>(e);
        if (anim && !anim->palette.empty()) {
            for (auto& p : mi.mesh->parts)
                if (p.skinVb.id) mi.anim = anim;
            if (mi.anim) {  // the box of every skinned part carried by the joints of its own skin, joined with the rest
                bool first = true;
                for (auto& p : mi.mesh->parts) {
                    Vec3 lo = p.bmin, hi = p.bmax;
                    if (p.skinVb.id) skinned_bounds(palette_of(*anim, p.skin), p.bmin, p.bmax, lo, hi);
                    mi.bmin = first ? lo : min(mi.bmin, lo);
                    mi.bmax = first ? hi : max(mi.bmax, hi);
                    first = false;
                }
            }
        }
        mi.visible = box_in_frustum(fr.cam.viewProj, z01, mi.bmin, mi.bmax, mi.model);
        // The alphaMode of a material decides (blend = drawn far to near with the blended meshes; opaque and clip are not),
        // whatever Color.a or the glTF material say.
        bool anyBlend = mr.color.a < 0.999f;
        for (auto& p : mi.mesh->parts) anyBlend = anyBlend || p.blended;
        if (mi.material) anyBlend = mi.material->alphaMode == "blend";
        (anyBlend ? blended : opaque).push_back(mi);
    });
    std::stable_sort(blended.begin(), blended.end(), [](const MeshItem& a, const MeshItem& b) { return a.dist > b.dist; });
    if (fr.wantWorld) world.each<Light>([&](Entity e, Light& l) {
        if (!world.active_in_hierarchy(e)) return;
        Mat4 m = world.world_matrix(e);
        LightData ld;
        Vec3 col{l.color.r * l.intensity, l.color.g * l.intensity, l.color.b * l.intensity};
        const float brightness = std::max({col.x, col.y, col.z});
        if (l.type == LightType::Directional) {
            Vec3 d = normalize(m.transform_dir(kForward));
            ld.pos = Vec4{-d, 0.0f};
            ld.color = Vec4{col, 0.0f};
            ld.dir = Vec4{d, 1.0f};
            ld.rank = 1;
            ld.score = brightness;
            if (shadowLight < 0 && l.castShadows) { lightDirForShadow = d; shadowLight = 0; ld.rank = 0; }
        } else {
            Vec3 d = normalize(m.transform_dir(kForward));
            ld.pos = Vec4{m.translation(), l.range};
            ld.color = Vec4{col, l.type == LightType::Point ? 1.0f : 2.0f};
            ld.dir = Vec4{d, std::cos(radians(l.spotAngle))};
            // Relevance to the camera: bright and close first (the light's own range scales the fall-off).
            const float r2 = std::max(l.range * l.range, 1e-4f);
            ld.score = brightness * r2 / (r2 + length_sq(m.translation() - fr.cam.position));
        }
        lights.push_back(ld);
    });
    // The shadow caster in slot 0, then the other directional lights, then point and spot lights by relevance; what the
    // shader's arrays cannot hold is left out.
    stats.lightsDropped += select_lights(lights, size_t(kMaxLights));
    stats.lights += int(lights.size());
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

    // ---- cull, then group into instanced batches ----
    // A mesh outside the camera frustum is not drawn in the main pass but can still cast a shadow into view, so it stays
    // in the shadow pass (when it is inside the light's volume); an item that does neither is dropped here.
    for (auto* list : {&opaque, &blended}) {
        for (auto& mi : *list) {
            if (!mi.visible) ++stats.meshesCulled;
            mi.casts = doShadows && mi.mr->castShadows &&
                       box_in_frustum(lightVP, z01, mi.bmin, mi.bmax, mi.model);
            if (mi.casts) ++stats.shadowCasters;
        }
        list->erase(std::remove_if(list->begin(), list->end(), [](const MeshItem& m) { return !m.visible && !m.casts; }),
                    list->end());
    }
    std::vector<MeshBatch> opaqueBatches, blendedBatches;
    std::vector<Mat4> mainMats, shadowMats;
    build_batches(opaque, true, opaqueBatches, mainMats, shadowMats);
    build_batches(blended, false, blendedBatches, mainMats, shadowMats);

    // ---- flatten quads into one vertex stream ----
    struct Group { std::vector<QuadBatch> batches; };
    Group gClear, gWorld, gDebugWorld, gScreen, gDebugScreen;
    stream.clear();
    if (clearByQuad) {
        // The camera's clear colour over its viewport: one opaque quad over the unit square, which the viewport maps to the
        // camera's rectangle (see the draw below).
        QuadList clearList;
        clearList.begin_item(0, 0, assets->white(), SamplerKind::Nearest);
        clearList.set_opaque();
        QuadEmitter em{clearList, Mat4::identity(), false, pack_color(fr.cam.clearColor), kModeTextured, 0};
        em.rect(0, 0, 1, 1, 0, 0, 1, 1);
        clearList.end_item();
        clearList.flatten(stream, gClear.batches);
    }
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

    Mat4 screenProj = Mat4::ortho(0, float(targetW), float(targetH), 0, -1000.0f, 1000.0f, z01);

    // ---- instance data: one model matrix per drawn mesh, written before any pass binds the buffers ----
    static_assert(sizeof(Mat4) == kMeshInstanceBytes, "an instance is one Mat4");
    auto upload_instances = [&](const std::vector<Mat4>& mats) {
        if (mats.empty()) return sg_buffer{};
        const std::size_t bytes = mats.size() * kMeshInstanceBytes;
        sg_buffer buf = gpu.acquire_transient(bytes);
        sg_write_buffer_desc wd{};
        wd.src.data = {mats.data(), bytes};
        wd.dst.buffer = buf;
        sg_write_buffer_transient(&wd);
        return buf;
    };
    const sg_buffer mainInst = upload_instances(mainMats);
    const sg_buffer shadowInst = upload_instances(shadowMats);

    // ---- how a mesh part is drawn: shared by the main pass and the shadow pass of alphaMode "clip" materials ----
    const SceneSettings& ss = world.settings();
    TextureAsset* white = assets->white();
    mesh_fa_lights_t lightUniforms{};
    for (std::size_t i = 0; i < lights.size(); ++i) {
        for (int c = 0; c < 4; ++c) {
            lightUniforms.fa_light_pos[i][c] = lights[i].pos[c];
            lightUniforms.fa_light_color[i][c] = lights[i].color[c];
            lightUniforms.fa_light_dir[i][c] = lights[i].dir[c];
        }
    }
    mesh_fa_mesh_vs_params_t vuScene{};
    copy_mat(vuScene.fa_view_proj, fr.cam.viewProj);
    copy_mat(vuScene.fa_light_vp, lightVP);
    vuScene.fa_time[0] = float(world.time());
    mesh_fa_mesh_fs_params_t fuScene{};
    fuScene.fa_camera_pos[0] = fr.cam.position.x; fuScene.fa_camera_pos[1] = fr.cam.position.y; fuScene.fa_camera_pos[2] = fr.cam.position.z;
    fuScene.fa_ambient[0] = ss.ambientLight.r; fuScene.fa_ambient[1] = ss.ambientLight.g; fuScene.fa_ambient[2] = ss.ambientLight.b;
    fuScene.fa_fog[0] = ss.fogColor.r; fuScene.fa_fog[1] = ss.fogColor.g; fuScene.fa_fog[2] = ss.fogColor.b; fuScene.fa_fog[3] = ss.fogDensity;
    fuScene.fa_counts[0] = float(lights.size());
    fuScene.fa_counts[1] = 1.0f / float(kShadowSize);
    fuScene.fa_counts[2] = gpu.is_gl() ? 1.0f : 0.0f;
    fuScene.fa_env_sky[0] = ss.skyColor.r; fuScene.fa_env_sky[1] = ss.skyColor.g; fuScene.fa_env_sky[2] = ss.skyColor.b;
    fuScene.fa_env_horizon[0] = ss.horizonColor.r; fuScene.fa_env_horizon[1] = ss.horizonColor.g; fuScene.fa_env_horizon[2] = ss.horizonColor.b;
    fuScene.fa_pbr[3] = 0.0015f;
    fuScene.fa_time[0] = float(world.time());

    // What one part of an item is drawn with. A material that built uses its own programs; one that failed uses the engine's
    // programs as the error material (unlit magenta, white textures, no emission).
    struct PartDraw {
        MaterialAsset* mat = nullptr;
        bool error = false;
        TextureAsset *tex = nullptr, *normal = nullptr, *mr = nullptr, *occlusion = nullptr, *emissive = nullptr;
    };
    auto part_draw = [&](const MeshItem& mi, const SubMesh& part) {
        PartDraw d;
        d.error = mi.material && !mi.material->ok;
        d.mat = mi.material && mi.material->ok ? mi.material : nullptr;
        d.tex = d.error ? white : mi.tex ? mi.tex : (part.texture ? part.texture : white);
        d.normal = d.error ? nullptr : (mi.normalTex ? mi.normalTex : part.normalTex);
        d.mr = d.error || !part.mrTex ? white : part.mrTex;
        d.occlusion = d.error || !part.occlusionTex ? white : part.occlusionTex;
        d.emissive = d.error || !part.emissiveTex ? white : part.emissiveTex;
        return d;
    };
    // The glTF base color factor of a part, or the MeshRenderer.materialColors entry for its material name.
    auto part_base_color = [](const MeshRenderer& mr, const SubMesh& part) {
        if (!part.materialName.empty() && mr.materialColors.is_object()) {
            auto it = mr.materialColors.find(part.materialName);
            if (it != mr.materialColors.end() && it->is_array() && it->size() >= 3 && it->size() <= 4) {
                float v[4] = {1, 1, 1, 1};
                for (std::size_t i = 0; i < it->size(); ++i) {
                    if (!(*it)[i].is_number()) return part.baseColor;  // validate reports it; the part keeps its own colour
                    v[i] = (*it)[i].get<float>();
                }
                return Color{v[0], v[1], v[2], v[3]};
            }
        }
        return part.baseColor;
    };
    // The fragment parameters (fa_mesh_fs_params) of one part.
    auto fill_fs = [&](const MeshItem& mi, const SubMesh& part, const PartDraw& d) {
        const MeshRenderer& mr = *mi.mr;
        mesh_fa_mesh_fs_params_t fu = fuScene;
        const bool unlit = mr.unlit || d.error || (d.mat && d.mat->lighting == "unlit");
        if (!d.error) { fu.fa_emissive[0] = mr.emissive.r; fu.fa_emissive[1] = mr.emissive.g; fu.fa_emissive[2] = mr.emissive.b; }
        fu.fa_emissive[3] = unlit ? 1.0f : 0.0f;
        fu.fa_pbr[2] = (doShadows && mr.receiveShadows) ? 1.0f : 0.0f;
        const Color base = d.error ? Color{1, 0, 1, 1} : mr.color * part_base_color(mr, part);
        fu.fa_base_color[0] = base.r; fu.fa_base_color[1] = base.g; fu.fa_base_color[2] = base.b; fu.fa_base_color[3] = base.a;
        // glTF materials bring their own metallic/roughness; primitives use the MeshRenderer's.
        fu.fa_pbr[0] = part.hasPbr ? saturate(part.metallic) : saturate(mr.metallic);
        fu.fa_pbr[1] = part.hasPbr ? saturate(part.roughness) : saturate(mr.roughness);
        if (!d.error) { fu.fa_model_emissive[0] = part.emissiveFactor.r; fu.fa_model_emissive[1] = part.emissiveFactor.g; fu.fa_model_emissive[2] = part.emissiveFactor.b; }
        fu.fa_maps[0] = mi.normalTex ? mr.normalScale : part.normalScale;
        fu.fa_maps[1] = part.occlusionStrength;
        fu.fa_maps[2] = d.normal ? 1.0f : 0.0f;
        return fu;
    };
    // The packed params and textures of a custom material for one batch (its overrides are the same for every item).
    struct MaterialInputs {
        float params[kMaxMaterialParams][4];
        TextureAsset* textures[kMaxMaterialTextures]{};
    };
    auto material_inputs = [&](const MeshItem& mi, MaterialAsset* mat, MaterialInputs& in) {
        pack_material_params(*mat, mi.mr->materialParams, in.params);
        for (std::size_t i = 0; i < mat->textures.size(); ++i) in.textures[i] = material_texture(*mat, int(i), mi.mr->materialParams, *assets);
    };
    // Bindings of a custom program: the engine's textures and the material's, only the slots the program declares (sokol
    // rejects a binding the shader does not have). `shadowPass`: the shadow map is being drawn, so it is not sampled.
    auto bind_textures = [&](sg_bindings& b, const PartDraw& d, const MaterialProgram* prog, const MaterialInputs& in, bool shadowPass) {
        b.views[VIEW_mesh_fa_tex] = d.tex->gpu_view();
        b.views[VIEW_mesh_fa_shadow_tex] = (doShadows && !shadowPass) ? shadowTexView : white->view;
        b.views[VIEW_mesh_fa_normal_tex] = (d.normal ? d.normal : white)->gpu_view();
        b.views[VIEW_mesh_fa_mr_tex] = d.mr->gpu_view();
        b.views[VIEW_mesh_fa_occlusion_tex] = d.occlusion->gpu_view();
        b.views[VIEW_mesh_fa_emissive_tex] = d.emissive->gpu_view();
        b.samplers[SMP_mesh_fa_smp] = gpu.sampler(SamplerKind::LinearRepeat);
        b.samplers[SMP_mesh_fa_shadow_smp] = gpu.sampler(SamplerKind::Nearest);
        if (!prog) return;
        if (d.mat)
            for (std::size_t i = 0; i < d.mat->textures.size(); ++i) {
                b.views[kMaterialFirstView + int(i)] = in.textures[i]->gpu_view();
                b.samplers[kMaterialFirstSampler + int(i)] = gpu.sampler(d.mat->textures[i].sampler);
            }
        for (int i = 0; i < SG_MAX_VIEW_BINDSLOTS; ++i)
            if (!((prog->viewMask >> i) & 1u)) b.views[i] = {};
        for (int i = 0; i < SG_MAX_SAMPLER_BINDSLOTS; ++i)
            if (!((prog->samplerMask >> i) & 1u)) b.samplers[i] = {};
    };
    // The material's params (fa_material_vs, fa_material), when the program declares them.
    auto apply_material_params = [&](const MaterialProgram& prog, const MaterialInputs& in) {
        for (int slot : {kMaterialUbVertex, kMaterialUbFragment}) {
            if (!prog.has_ub(slot)) continue;
            sg_range r{in.params, std::min<std::size_t>(prog.ubSize[slot], sizeof(in.params))};
            sg_apply_uniforms(slot, &r);
        }
    };
    auto declares = [](const MaterialProgram* prog, int ub) { return !prog || prog->has_ub(ub); };

    // ---- 2D light buffer ----
    // Lit visuals without a normal map read the point lights added up in a light buffer instead of looping over them per
    // pixel, so the number of lights costs only the pixels the lights cover. The pass runs when the world group has such
    // a visual, a point light exists and the camera is orthographic (a perspective camera has no screen-space map of the
    // 2D plane); else flat visuals use the loop over the first kDirectLights2D lights (litMode 0) or, with no point light,
    // just the ambient and directional lights (litMode 2). Visuals with a normal map always use the loop (the direction of
    // each light matters), and the screen-space groups too.
    int litMode = 0;
    sg_view shadowRowsTex{};
    {
        bool anyFlatLit = false;
        for (const QuadBatch& qb : gWorld.batches) anyFlatLit = anyFlatLit || (qb.lit && !qb.normal);
        int points = 0;
        for (const Light2DData& l : fr.lights2d) points += l.pos[3] >= 0.0f ? 1 : 0;
        shadowRowsTex = upload_shadow_rows(fr);
        float lightScale = ss.lightScale;
        lightScale = std::isfinite(lightScale) ? std::clamp(lightScale, 0.25f, 1.0f) : 1.0f;
        if (anyFlatLit && !fr.cam.perspective && gpu.light_format() != SG_PIXELFORMAT_NONE) {
            if (points == 0) litMode = 2;
            else if (gpu.light_ready() && ensure_light_target(lightScale)) litMode = 1;
        }
        if (litMode == 1) {
            std::vector<LightVertex> lv;
            lv.reserve(std::size_t(points) * 4);
            static const float kCorner[4][2] = {{-1, -1}, {1, -1}, {1, 1}, {-1, 1}};
            for (const Light2DData& l : fr.lights2d) {
                if (l.pos[3] < 0.0f) continue;
                for (const auto& c : kCorner) {
                    LightVertex v{};
                    v.corner[0] = c[0];
                    v.corner[1] = c[1];
                    std::memcpy(v.pos, l.pos, sizeof(float) * 4);
                    std::memcpy(v.color, l.color, sizeof(float) * 4);
                    v.shadow[0] = l.extra[0] >= 0.0f && fr.shadowRows > 0 ? (l.extra[0] + 0.5f) / float(fr.shadowRows) : -1.0f;
                    lv.push_back(v);
                }
            }
            static_assert(kMaxLights2D <= kMaxQuadsPerDraw, "every light of a frame is drawn by one draw call");
            sg_buffer lb = gpu.acquire_transient(lv.size() * sizeof(LightVertex));
            sg_write_buffer_desc wd{};
            wd.src.data = {lv.data(), lv.size() * sizeof(LightVertex)};
            wd.dst.buffer = lb;
            sg_write_buffer_transient(&wd);

            sg_pass lp{};
            lp.action.colors[0].load_action = SG_LOADACTION_CLEAR;
            lp.action.colors[0].clear_value = {0, 0, 0, 0};
            lp.action.colors[0].store_action = SG_STOREACTION_STORE;
            lp.attachments.colors[0] = lightAtt;
            lp.label = "light-buffer";
            sg_begin_pass(&lp);
            // The lights of this camera go to its rectangle of the buffer; the lit visuals of the camera read nothing else.
            if (partial) apply_view(px_rect(fr.cam.viewport, lightW, lightH));
            sg_apply_pipeline(gpu.light_pipeline());
            sg_bindings b{};
            b.vertex_buffers[0] = lb;
            b.index_buffer = gpu.quad_index_buffer();
            b.views[VIEW_light_shadow_tex] = shadowRowsTex.id ? shadowRowsTex : assets->white()->view;
            b.samplers[SMP_light_shadow_smp] = gpu.sampler(SamplerKind::Nearest);
            sg_apply_bindings(&b);
            light_light_vs_params_t vu{};
            copy_mat(vu.view_proj, fr.cam.viewProj);
            apply_uniforms(UB_light_light_vs_params, vu);
            light_light_fs_params_t fu{};
            fu.range[0] = 1.0f / gpu.light_range();
            apply_uniforms(UB_light_light_fs_params, fu);
            sg_draw(0, int(lv.size() / 4) * 6, 1);
            sg_end_pass();
            ++stats.drawCalls;
        }
    }

    // ---- shadow pass ----
    // Meshes cast with the engine's depth-only programs, except materials with their own shadow programs (vertex() moves the
    // shadow, alphaMode "clip" cuts holes into it).
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
        mesh_fa_mesh_vs_params_t u = vuScene;  // the shadow programs read fa_light_vp (fa_view_proj is unused)
        for (int pass = 0; pass < 2; ++pass) {
            const std::vector<MeshBatch>& batches = pass == 0 ? opaqueBatches : blendedBatches;
            const std::vector<MeshItem>& items = pass == 0 ? opaque : blended;
            for (const MeshBatch& batch : batches) {
                if (batch.shadowCount == 0) continue;
                const MeshItem& rep = items[batch.rep];
                u.fa_uv_scale[0] = rep.mr->uvScale.x; u.fa_uv_scale[1] = rep.mr->uvScale.y;
                MaterialAsset* mat = rep.material && rep.material->ok ? rep.material : nullptr;
                MaterialInputs inputs{};
                if (mat && (mat->programs[kProgShadow].shader.id || mat->programs[kProgShadowSkin].shader.id)) material_inputs(rep, mat, inputs);
                for (auto& p : rep.mesh->parts) {
                    const bool skinned = rep.anim && p.skinVb.id;
                    const MaterialProgram* prog = mat ? &mat->programs[skinned ? kProgShadowSkin : kProgShadow] : nullptr;
                    if (prog && !prog->shader.id) prog = nullptr;
                    sg_apply_pipeline(prog ? gpu.shadow_pipeline(skinned, prog->shader, true) : gpu.shadow_pipeline(skinned));
                    sg_bindings b{};
                    b.vertex_buffers[0] = p.vb;
                    b.vertex_buffers[1] = shadowInst;
                    b.vertex_buffer_offsets[1] = int(batch.shadowFirst * kMeshInstanceBytes);
                    if (skinned) b.vertex_buffers[2] = p.skinVb;
                    b.index_buffer = p.ib;
                    const PartDraw pd = part_draw(rep, p);
                    if (prog) bind_textures(b, pd, prog, inputs, true);
                    sg_apply_bindings(&b);
                    apply_uniforms(UB_mesh_fa_mesh_vs_params, u);
                    if (skinned && declares(prog, UB_mesh_fa_skin)) apply_uniforms(UB_mesh_fa_skin, pack_palette(palette_of(*rep.anim, p.skin)));
                    if (prog) {
                        if (prog->has_ub(UB_mesh_fa_mesh_fs_params)) apply_uniforms(UB_mesh_fa_mesh_fs_params, fill_fs(rep, p, pd));
                        if (prog->has_ub(UB_mesh_fa_lights)) apply_uniforms(UB_mesh_fa_lights, lightUniforms);
                        apply_material_params(*prog, inputs);
                    }
                    sg_draw(0, p.indexCount, int(batch.shadowCount));
                    ++stats.drawCalls;
                }
            }
        }
        sg_end_pass();
    }

    // quad groups
    auto draw_group = [&](const std::vector<QuadBatch>& batches, const Mat4& vp, bool depthTest, const Px& base, int flatMode = 0) {
        if (batches.empty()) return;
        quad_vs_params_t u{};
        copy_mat(u.view_proj, vp);
        Rect scissor;  // the clip applied now (w <= 0: `base`, the whole target or the camera's viewport); a ScrollList's content is cut at its rectangle
        auto apply_clip = [&](const Rect& c) {
            if (c == scissor) return;
            scissor = c;
            if (c.w <= 0) { sg_apply_scissor_rect(base.x, base.y, base.w, base.h, true); return; }
            Rect r = c;
            const float k = renderScale;
            const int x0 = std::clamp(int(std::lround(r.x * k)), 0, physW), y0 = std::clamp(int(std::lround(r.y * k)), 0, physH);
            const int x1 = std::clamp(int(std::lround((r.x + r.w) * k)), x0, physW), y1 = std::clamp(int(std::lround((r.y + r.h) * k)), y0, physH);
            sg_apply_scissor_rect(x0, y0, x1 - x0, y1 - y0, true);
        };
        // fragment uniforms of the 2D lights: the same for every lit batch except the normal map's uv transform
        quad_quad_fs_params_t unlit{};
        quad_quad_fs_params_t litUniforms{};
        litUniforms.lit[0] = float(std::min<std::size_t>(fr.lights2d.size(), std::size_t(kDirectLights2D)));
        litUniforms.lit[2] = float(flatMode);
        litUniforms.ambient[0] = fr.ambient2d.r; litUniforms.ambient[1] = fr.ambient2d.g; litUniforms.ambient[2] = fr.ambient2d.b;
        // A flat visual gets every directional light in full (it faces them head on): they join the ambient light.
        litUniforms.flat_ambient[0] = fr.ambient2d.r; litUniforms.flat_ambient[1] = fr.ambient2d.g; litUniforms.flat_ambient[2] = fr.ambient2d.b;
        for (const Light2DData& l : fr.lights2d) {
            if (l.pos[3] >= 0.0f) continue;
            for (int c = 0; c < 3; ++c) litUniforms.flat_ambient[c] += l.color[c];
        }
        litUniforms.light_map[0] = 1.0f / float(std::max(1, physW));
        litUniforms.light_map[1] = 1.0f / float(std::max(1, physH));
        litUniforms.light_map[2] = gpu.light_range();
        for (std::size_t i = 0; i < fr.lights2d.size() && i < std::size_t(kDirectLights2D); ++i) {
            std::memcpy(litUniforms.light_pos[i], fr.lights2d[i].pos, sizeof(float) * 4);
            std::memcpy(litUniforms.light_color[i], fr.lights2d[i].color, sizeof(float) * 4);
            const float row = fr.lights2d[i].extra[0];
            litUniforms.light_shadow_v[i][0] = row >= 0.0f && fr.shadowRows > 0 ? (row + 0.5f) / float(fr.shadowRows) : -1.0f;
        }
        const sg_view lightTexBound = flatMode == 1 ? lightTexView : assets->white()->view;
        const sg_view shadowTexBound = shadowRowsTex.id ? shadowRowsTex : assets->white()->view;
        for (const QuadBatch& qb : batches) {
            apply_clip(qb.clip);
            sg_apply_pipeline(gpu.quad_pipeline(depthTest, false, qb.blend, qb.plain, qb.opaque));
            apply_uniforms(UB_quad_vs_params, u);
            if (qb.lit) {
                litUniforms.lit[1] = qb.normal ? 1.0f : 0.0f;
                if (qb.normal) normal_uv_transform(*qb.tex, *qb.normal, litUniforms.normal_uv);
                apply_uniforms(UB_quad_quad_fs_params, litUniforms);
            } else if (!qb.plain) {  // quad_plain declares no fragment uniforms
                apply_uniforms(UB_quad_quad_fs_params, unlit);
            }
            std::uint32_t done = 0;
            while (done < qb.quadCount) {
                std::uint32_t n = std::min<std::uint32_t>(qb.quadCount - done, kMaxQuadsPerDraw);
                sg_bindings b{};
                b.vertex_buffers[0] = vbuf;
                b.vertex_buffer_offsets[0] = int((qb.firstQuad + done) * 4 * sizeof(Vertex2D));
                b.index_buffer = gpu.quad_index_buffer();
                b.views[VIEW_quad_tex] = qb.tex->gpu_view();
                b.views[VIEW_quad_normal_tex] = (qb.lit && qb.normal ? qb.normal : assets->white())->gpu_view();
                b.views[VIEW_quad_light_tex] = lightTexBound;
                b.views[VIEW_quad_shadow_tex] = shadowTexBound;
                b.samplers[SMP_quad_smp] = gpu.sampler(qb.smp);
                b.samplers[SMP_quad_light_smp] = gpu.sampler(SamplerKind::LinearClamp);
                b.samplers[SMP_quad_shadow_smp] = gpu.sampler(SamplerKind::Nearest);
                sg_apply_bindings(&b);
                sg_draw(0, int(n * 6), 1);
                ++stats.drawCalls;
                done += n;
            }
        }
        apply_clip(Rect{});
    };
    // ---- main pass ----
    // Camera.bloomScreenSpace = false: the frame is split in two passes. This one draws the world, the bloom then
    // glows it, and a second pass (below) draws the screen-space groups (HUD) on top, so the HUD never glows.
    // With MSAA the multisampled image must survive every pass but the last one (STORE): the next pass loads it, and with
    // the HUD over the bloom the bloom adds its glow to it, the HUD pass loads it again, so the HUD is multisampled too and
    // the final resolve contains everything.
    const bool msaa = gpu.sample_count() > 1;
    // Does this job begin a pass? The screen-space job of a frame whose HUD goes over the bloom draws after it instead.
    const bool mainPass = fr.wantWorld || !hudAfterBloom;
    const bool drawHudInPass = fr.wantScreen && !hudAfterBloom;
    if (mainPass) {
    sg_pass mp{};
    mp.action.colors[0].load_action = clearByLoad ? SG_LOADACTION_CLEAR : SG_LOADACTION_LOAD;
    mp.action.colors[0].clear_value = {fr.cam.clearColor.r, fr.cam.clearColor.g, fr.cam.clearColor.b, fr.cam.clearColor.a};
    mp.action.colors[0].store_action = (msaa && plan.last && !hudAfterBloom) ? SG_STOREACTION_DONTCARE : SG_STOREACTION_STORE;
    mp.action.depth.load_action = SG_LOADACTION_CLEAR;
    mp.action.depth.clear_value = 1.0f;
    mp.action.stencil.load_action = SG_LOADACTION_CLEAR;
    mp.attachments.colors[0] = colorAtt;
    if (gpu.sample_count() > 1) mp.attachments.resolves[0] = resolveAtt;
    mp.attachments.depth_stencil = depthAtt;
    mp.label = fr.wantWorld ? "game" : "game-hud";
    sg_begin_pass(&mp);
    if (partial) apply_view(camPx);

    // clear of a camera that shares the target with others
    if (clearByQuad) draw_group(gClear.batches, Mat4::ortho(0, 1, 1, 0, -1.0f, 1.0f, z01), false, camPx);

    // sky
    if (fr.wantWorld && fr.cam.perspective && fr.cam.clear) {
        sg_apply_pipeline(gpu.sky_pipeline());
        sg_bindings b{};
        b.vertex_buffers[0] = gpu.fullscreen_triangle();
        sg_apply_bindings(&b);
        sky_sky_vs_params_t vu{};
        copy_mat(vu.inv_view_proj, fr.cam.invViewProj);
        vu.cam_pos[0] = fr.cam.position.x; vu.cam_pos[1] = fr.cam.position.y; vu.cam_pos[2] = fr.cam.position.z;
        apply_uniforms(UB_sky_sky_vs_params, vu);
        sky_sky_fs_params_t fu{};
        fu.sky_color[0] = ss.skyColor.r; fu.sky_color[1] = ss.skyColor.g; fu.sky_color[2] = ss.skyColor.b; fu.sky_color[3] = 1;
        fu.horizon_color[0] = ss.horizonColor.r; fu.horizon_color[1] = ss.horizonColor.g; fu.horizon_color[2] = ss.horizonColor.b; fu.horizon_color[3] = 1;
        apply_uniforms(UB_sky_sky_fs_params, fu);
        sg_draw(0, 3, 1);
        ++stats.drawCalls;
    }

    // meshes: one instanced draw per part of every batch
    std::vector<const MaterialAsset*> materialsDrawn;
    auto draw_meshes = [&](const std::vector<MeshBatch>& batches, const std::vector<MeshItem>& items, bool isBlend) {
        mesh_fa_mesh_vs_params_t vu = vuScene;
        for (const MeshBatch& batch : batches) {
            if (batch.mainCount == 0) continue;
            const MeshItem& mi = items[batch.rep];
            const MeshRenderer& mr = *mi.mr;
            vu.fa_uv_scale[0] = mr.uvScale.x; vu.fa_uv_scale[1] = mr.uvScale.y;
            MaterialInputs inputs{};
            if (mi.material && mi.material->ok) {
                material_inputs(mi, mi.material, inputs);
                if (std::find(materialsDrawn.begin(), materialsDrawn.end(), mi.material) == materialsDrawn.end()) materialsDrawn.push_back(mi.material);
            } else if (mi.material && std::find(stats.materialFallbacks.begin(), stats.materialFallbacks.end(), mi.material->path) == stats.materialFallbacks.end()) {
                stats.materialFallbacks.push_back(mi.material->path);
            }
            for (auto& part : mi.mesh->parts) {
                const bool skinned = mi.anim && part.skinVb.id;
                const PartDraw pd = part_draw(mi, part);
                const MaterialProgram* prog = pd.mat ? &pd.mat->programs[skinned ? kProgMeshSkin : kProgMesh] : nullptr;
                sg_apply_pipeline(gpu.mesh_pipeline(isBlend, part.doubleSided || (pd.mat && pd.mat->doubleSided), skinned, prog ? prog->shader : sg_shader{}));
                sg_bindings b{};
                b.vertex_buffers[0] = part.vb;
                b.vertex_buffers[1] = mainInst;
                b.vertex_buffer_offsets[1] = int(batch.mainFirst * kMeshInstanceBytes);
                if (skinned) b.vertex_buffers[2] = part.skinVb;
                b.index_buffer = part.ib;
                bind_textures(b, pd, prog, inputs, false);
                sg_apply_bindings(&b);
                apply_uniforms(UB_mesh_fa_mesh_vs_params, vu);
                if (skinned && declares(prog, UB_mesh_fa_skin)) apply_uniforms(UB_mesh_fa_skin, pack_palette(palette_of(*mi.anim, part.skin)));
                apply_uniforms(UB_mesh_fa_mesh_fs_params, fill_fs(mi, part, pd));
                apply_uniforms(UB_mesh_fa_lights, lightUniforms);
                if (prog) apply_material_params(*prog, inputs);
                sg_draw(0, part.indexCount, int(batch.mainCount));
                ++stats.drawCalls;
                stats.triangles += part.indexCount / 3 * int(batch.mainCount);
            }
            stats.meshes += int(batch.mainCount);
            ++stats.meshBatches;
        }
    };
    draw_meshes(opaqueBatches, opaque, false);
    draw_meshes(blendedBatches, blended, true);
    stats.materials += int(materialsDrawn.size());

    draw_group(gWorld.batches, fr.cam.viewProj, fr.cam.perspective, camPx, litMode);
    draw_group(gDebugWorld.batches, fr.cam.viewProj, false, camPx);
    if (!fr.debugLines.empty()) {
        sg_apply_pipeline(gpu.quad_pipeline(false, true));
        quad_vs_params_t u{};
        copy_mat(u.view_proj, fr.cam.viewProj);
        apply_uniforms(UB_quad_vs_params, u);
        quad_quad_fs_params_t unlit{};
        apply_uniforms(UB_quad_quad_fs_params, unlit);
        sg_bindings b{};
        b.vertex_buffers[0] = vbuf;
        b.vertex_buffer_offsets[0] = int(lineFirst * sizeof(Vertex2D));
        b.views[VIEW_quad_tex] = assets->white()->view;
        b.views[VIEW_quad_normal_tex] = assets->white()->view;
        b.views[VIEW_quad_light_tex] = assets->white()->view;
        b.views[VIEW_quad_shadow_tex] = assets->white()->view;
        b.samplers[SMP_quad_smp] = gpu.sampler(SamplerKind::Nearest);
        b.samplers[SMP_quad_light_smp] = gpu.sampler(SamplerKind::LinearClamp);
        b.samplers[SMP_quad_shadow_smp] = gpu.sampler(SamplerKind::Nearest);
        sg_apply_bindings(&b);
        sg_draw(0, int(fr.debugLines.size()), 1);
        ++stats.drawCalls;
    }
    if (drawHudInPass) {
        draw_group(gScreen.batches, screenProj, false, fullPx);
        draw_group(gDebugScreen.batches, screenProj, false, fullPx);
    }

    sg_end_pass();
    }  // mainPass

    if (!plan.last) return;

    // ---- post-process: bloom adds its glow into the game target ----
    if (post.bloom.enabled) {
        BloomTarget dst;
        if (hudAfterBloom && msaa) {
            // Glow into the multisampled image (resolved again at the end of the composite pass) so the HUD pass below
            // can load it. Reads the already resolved image of the main pass.
            dst = BloomTarget{colorAtt, resolveAtt, gpu.sample_count()};
        } else {
            // The finished frame: the resolved image when MSAA is on (the main pass already resolved into it).
            dst = BloomTarget{msaa ? resolveColorAtt : colorAtt, sg_view{}, 1};
        }
        stats.drawCalls += bloom.apply(gpu, post.bloom, physW, physH, texView, dst);
    }

    // ---- HUD pass (Camera.bloomScreenSpace = false): screen-space groups over the glowing frame ----
    if (hudAfterBloom && fr.wantScreen && (!gScreen.batches.empty() || !gDebugScreen.batches.empty())) {
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
        draw_group(gScreen.batches, screenProj, false, fullPx);
        draw_group(gDebugScreen.batches, screenProj, false, fullPx);
        sg_end_pass();
    }

    // ---- last post-process: Camera.colorFilter (costs nothing with "none") ----
    filterActive = false;
    if (post.colorFilter != 0) stats.drawCalls += apply_color_filter(post.colorFilter);
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
    b.views[VIEW_blit_tex] = im.final_view();
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
    sg_image img = im.final_image();
    std::vector<std::uint8_t> px;
    if (!readback_rgba8(img, im.physW, im.physH, px, error)) return false;
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

}  // namespace fa
