// Private: the state of one Renderer (Renderer::Impl) and the small helpers its translation units share.
// renderer.cpp (setup, cameras, the public API, render()), renderer_targets.cpp (images, views, readback, post filter),
// renderer_draw.cpp (draw_view_job, draw_job) and renderer_present.cpp (present, capture) each implement part of Impl.
#pragma once

#include "fa/render/renderer.h"
#include "fa/scene/camera_geometry.h"
#include "fa/scene/camera_query.h"
#include "fa/scene/bones2d.h"
#include "fa/scene/lod.h"

#include <algorithm>
#include <chrono>
#include <cmath>
#include <cstdlib>
#include <cstring>
#include <set>

#include "fa/core/fs.h"
#include "font_internal.h"
#include "fa/core/strings.h"
#include "fa/core/load_trace.h"
#include "fa/core/asset_manifest.h"
#include "fa/core/log.h"
#include "fa/core/profiler.h"
#include "fa/platform/sokol_logging.h"
#include "fa/scene/text_fit.h"
#include "fa/scene/ui_rect.h"
#include "bloom.h"
#include "shaders/colorfilter.glsl.h"
#include "frame.h"
#include "mesh_batch.h"
#include "font_set.h"
#include "render_internal.h"
#include "render_jobs.h"
#include "shader_cache.h"
#include "shaders/blit.glsl.h"
#include "shaders/light.glsl.h"
#include "shaders/mesh.glsl.h"
#include "shaders/quad.glsl.h"
#include "shaders/sky.glsl.h"

namespace fa {

// The renderer's private code calls the render:: helpers (Gpu, Frame, jobs...) without a prefix.
using namespace render;

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
    // Renderer::warm_step: the groups of pipelines to make before the first game frame, built on the first call.
    std::vector<std::function<void()>> warmGroups;
    std::size_t warmNext = 0;
    bool warmBuilt = false;
    std::size_t warmPipelines = 0;
    double warmMs = 0;
    bool adopted = false;  // the graphics context was opened by open_context: this renderer closes it
    std::unique_ptr<Assets> assets;
    std::unique_ptr<Fonts> fonts;
    GradientRamps ramps;     // the baked colour rows of Shape2D gradients with stops or an easing (gradient_ramp.h)
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
    std::string
        warnedViewport;  // the last "bad Camera.viewport" problem logged (a viewport a script sets live is clamped)
    bool warnedCameras = false;        // the "more cameras than the limit" warning, once per scene
    bool warnedLights2d = false;       // the "more Light2D in view than the budget" warning, once per scene
    bool warnedShadows2d = false;      // the "more shadow casters than the budget" warning, once per scene
    bool warnedSpriteMesh = false;     // the "too many mesh cells" warning, once per scene
    bool warnedGradientStops = false;  // the "malformed gradientStops" warning, once per scene
    std::string lights2dScene;         // the scene path warnedLights2d and warnedShadows2d belong to
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

    // The image a CameraView shows (ui2d.cpp, draw_camera_view): the camera is drawn into it before the frame's own jobs. One per
    // widget, made when a gather asks for it with a size and kept while the widget keeps asking; the ones nobody asked for in a
    // frame are freed at its end. Made like the game target (same sample count, same formats), because the pipelines are.
    struct ViewTarget {
        sg_image color{}, resolve{}, depth{};
        sg_view colorAtt{}, resolveAtt{}, depthAtt{}, texView{};
        int w = 0, h = 0;
        bool used = false;   // asked for since the last release_unused_views()
        TextureAsset asset;  // what the UI quad samples: the resolved image, w x h
        // A Camera.renderTarget texture on a backend that stores render targets bottom-up (GL): the picture copied the right way
        // up into `flip`, which `asset` then samples, so a mesh, a Sprite or a Panel reads it like any file texture.
        bool flipCopy = false;
        sg_image flip{};
        sg_view flipAtt{}, flipTex{};
    };
    std::unordered_map<std::uint64_t, std::unique_ptr<ViewTarget>> viewTargets;
    bool viewWarned = false;
    TextureAsset* view_image(std::uint64_t key, int w, int h, bool renderTarget = false);
    void release_view(ViewTarget& t);
    void release_unused_views();
    void draw_view_job(World& world, Frame& fr, ViewTarget& target);

    // ---- Camera.renderTarget (docs/RENDERING.md, "Render targets") ----
    struct TargetCam {
        Entity entity;
        std::string name;
        int w = 1, h = 1;
        std::uint64_t key = 0;
        int depth = 0;
        TextureAsset* asset = nullptr;
    };
    std::vector<TargetCam> targetCams;                  // this frame's: active, valid, one per name, in creation order
    std::unordered_map<std::string, int> targetByName;  // name -> index into targetCams
    std::unordered_map<const TextureAsset*, int> targetByAsset;
    std::string
        targetSelf;  // the name of the target being gathered or drawn: its own texture is the checker (sentinel)
    TextureAsset selfSentinel;  // what texture("target:<self>") answers meanwhile: the checker, its handles are shared
    std::set<std::string> targetWarned;
    void collect_targets(World& world);
    void warn_target_once(const std::string& key, const std::string& message, const std::string& hint);
    TextureAsset* resolve_target(const std::string& name);
    void flip_copy(ViewTarget& t);

    void create_targets(int w, int h);
    void make_game_targets();  // the images and views of the game target, at physW x physH in gpu.scene_format()
    void destroy_targets();
    int apply_color_filter(int mode);
    // The 8-bit picture of a game or view image (top row first). In a float scene format the image is first drawn into an
    // RGBA8 copy (clamped at white, as the screen shows it), because the per-backend readbacks read RGBA8 only.
    bool read_rgba8(sg_image image, sg_view view, int w, int h, std::vector<std::uint8_t>& out, std::string* error);
    sg_image readImg{};  // the RGBA8 copy read_rgba8 makes, kept for the next capture of the same size
    void free_read_image();
    // True when the images and views of the game target were made (create_targets) and the GPU accepted them.
    bool game_targets_valid() const;
    sg_view readAtt{};
    int readW = 0, readH = 0;
    sg_image final_image() const { return filterActive ? filterImg : (gpu.sample_count() > 1 ? resolveImg : colorImg); }
    sg_view final_view() const { return filterActive ? filterTex : texView; }
    void create_shadow_targets();
    bool ensure_light_target(float scale);
    sg_view upload_shadow_rows(const Frame& fr);
    void destroy_light_resources();
    // `view` (a CameraView's rectangle in design pixels) makes the camera fill an image of that size instead of its viewport.
    CameraInfo build_camera(World& world, Entity entity, const Vec2* viewSize = nullptr, bool renderTarget = false);
    std::vector<CameraInfo> collect_cameras(World& world);
    const CameraInfo& camera_for(Entity camera, const Vec2* screenPoint) const;
    struct JobPlan {
        bool first = false;  // the first pass of the frame: it clears the whole target when its camera clears
        bool last =
            false;  // the last job of the frame: it runs the post effects (bloom, the HUD over it, the colour filter)
        bool view =
            false;  // a CameraView's image: no post effects, never partial, resolved at once, 2D lights read per pixel
        const CameraInfo* post =
            nullptr;  // the camera whose bloom, bloomScreenSpace and colorFilter the frame gets (the first)
    };
    void render(World& world, float dt);
    void setup_frame(Frame& fr, World& world, float dt);
    void draw_job(World& world, Frame& fr, const JobPlan& plan);

    // The phases of draw_job (renderer_draw.cpp), each reading and writing the DrawContext of the job; the comment of each
    // names its reads and writes.
    struct Px;
    struct PartDraw;
    struct MaterialInputs;
    struct DrawContext;
    void gather_meshes(DrawContext& c);
    void collect_lights(DrawContext& c);
    void shadow_bounds(DrawContext& c);
    void cull_and_batch(DrawContext& c);
    void build_quad_stream(DrawContext& c);
    void upload_instances(DrawContext& c);
    void scene_uniforms(DrawContext& c);
    PartDraw part_draw(DrawContext& c, const MeshItem& mi, const SubMesh& part);
    mesh_fa_mesh_fs_params_t fill_fs(DrawContext& c, const MeshItem& mi, const SubMesh& part, const PartDraw& d);
    void material_inputs(const MeshItem& mi, MaterialAsset* mat, MaterialInputs& in);
    void bind_textures(DrawContext& c, sg_bindings& b, const PartDraw& d, const MaterialProgram* prog,
                       const MaterialInputs& in, bool shadowPass);
    void light_pass(DrawContext& c);
    void shadow_pass(DrawContext& c);
    void draw_group(DrawContext& c, const std::vector<QuadBatch>& batches, const Mat4& vp, bool depthTest,
                    const Px& base, int flatMode = 0);
    void main_pass(DrawContext& c);
    void bloom_pass(DrawContext& c);
    void hud_pass(DrawContext& c);
    void post_passes(DrawContext& c);
};

struct Viewport {
    float x, y, w, h, scale;
};

inline Viewport compute_viewport(ScaleMode mode, int fbW, int fbH, int tw, int th) {
    if (fbW <= 0 || fbH <= 0 || tw <= 0 || th <= 0) return {0, 0, float(fbW), float(fbH), 1.0f};
    const float fw = float(fbW), fh = float(fbH), tfw = float(tw), tfh = float(th);
    switch (mode) {
        case ScaleMode::Stretch: return {0, 0, fw, fh, fw / tfw};
        case ScaleMode::PixelPerfect: {
            float s = std::floor(std::min(fw / tfw, fh / tfh));
            if (s < 1.0f) s = std::min(fw / tfw, fh / tfh);
            float w = tfw * s, h = tfh * s;
            return {std::floor((fw - w) * 0.5f), std::floor((fh - h) * 0.5f), w, h, s};
        }
        case ScaleMode::Expand:
        case ScaleMode::Fit:
        default: {
            float s = std::min(fw / tfw, fh / tfh);
            float w = tfw * s, h = tfh * s;
            return {std::floor((fw - w) * 0.5f), std::floor((fh - h) * 0.5f), w, h, s};
        }
    }
}

template <class T>
void apply_uniforms(int slot, const T& u) {
    sg_range r{&u, sizeof(T)};
    sg_apply_uniforms(slot, &r);
}

}  // namespace fa
