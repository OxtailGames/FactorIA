// Renderer: draws a World (2D + 3D) into an offscreen "game target" at the
// design resolution, then (windowed only) presents it letterboxed to the
// window. Because the game always renders offscreen, screenshots, golden
// tests, the editor viewport and headless runs all see exactly the same image.
//
// Coordinate / anchoring semantics (Sprite, Shape2D, Text, identical in both spaces):
//   * pivot is VISUAL: (0,0) = bottom-left of the item's box, (1,1) = top-right, (0.5,0.5) = center, in
//     world space AND screen space (screen +Y is down, but pivot [0,1] is still the visual top-left). The
//     pivot point of the item is placed at the entity position. Defaults: Sprite/Shape2D [0.5,0.5], Text [0,1].
//   * Shape2D pivot applies to the bounding boxes of every shape but line (circle: square of side size.x). A triangle
//     (apex at the top-middle of its box) has its centroid at pivot [0.5, 1/3]: use that to spin it without wobble.
//   * Screen space: position is in design pixels from the TOP-LEFT, +Y down, drawn after the world.
//     `anchor` shifts the position by anchor * target size, e.g. anchor [1,0], pivot [1,1], position [-20,20]
//     = top-right corner of the item 20px inside the screen corner; with Expand the target grows so HUDs stay on the
//     edges.
//   * Blend: Alpha, Additive (dst + src*a), Multiply (dst * mix(1, src, a)); items sort by layer as usual and
//     batches split where the blend changes.
//
// Frame:
//   renderer.begin_frame();
//   renderer.render_world(world, dt);   // cameras, sprites, shapes, tilemaps, text,
//                                       // particles, meshes, lights, debug draw
//   renderer.end_frame();               // finishes the offscreen pass
//   renderer.present(swapchain, fbW, fbH);  // windowed only; editor skips this
//   sg_commit() is done by end_frame()/present() as appropriate.
#pragma once

#include <cstdint>
#include <functional>
#include <memory>
#include <optional>
#include <string>
#include <string_view>
#include <vector>

#include "fa/core/background_io.h"
#include "fa/core/image.h"
#include "fa/core/json.h"
#include "fa/core/math.h"
#include "fa/platform/app.h"
#include "fa/platform/hdr_output.h"
#include "fa/render/gpu_info.h"
#include "fa/render/graphics_preset.h"
#include "fa/render/ui_painter.h"
#include "fa/render/framegen.h"
#include "fa/render/latency.h"
#include "fa/render/raytracing.h"
#include "fa/render/upscaler.h"
#include "fa/scene/rich_text.h"
#include "fa/scene/text_fit.h"
#include "fa/scene/world.h"

namespace fa {

class Renderer;
class Compute;
struct ProbeSet;  // fa/scene/light_probes.h
// Test accessors (GPU objects, the frame graph, pool counts, history images) live in
// engine/render/src/renderer_test_access.h: the one friend below opens Impl for the render tests; the public API has no
// test hooks.
struct RendererTestAccess;

// What the renderer shows instead of the game picture, to check the depth and normal prepass and the ambient occlusion
// (Renderer::set_debug_view). Ao paints the occlusion as a grey over the picture, drawn with the camera's own settings or the defaults.
// Occlusion (M75.2) draws the Occluder boxes green and the boxes of the meshes the occlusion culling left out red, as wire boxes over the picture of
// the NEXT frame, with a line of counts (the depth buffer itself is Renderer::occlusion_report's `save`). With the depth pyramid
// (M75.2b) it also draws a coarse mip of it in the top left corner (nearer = brighter, black = a cell that shows no mesh somewhere).
// MotionVectors (M76) paints the per-pixel motion vectors the prepass writes (direction as hue, magnitude as brightness, grey where no mesh
// wrote one), over the picture, with the prepass drawn only for it.
// Albedo and Material (M79-P0c) paint the thin G-buffer's two images, which the renderer draws only while something asks for them: the albedo
// (linear colour), and the roughness as red and the metalness as green; black where no opaque mesh was drawn.
enum class DebugView : std::uint8_t { None, Depth, Normals, Ao, Cascades, Occlusion, MotionVectors, Albedo, Material };

enum class ScaleMode : std::int32_t {
    Fit,          // keep aspect, letterbox (default)
    Stretch,      // fill the window, distort
    Expand,       // keep aspect, grow the visible area on the long axis (game target resized to match)
    PixelPerfect  // integer scaling only, letterbox
};

// The range of Renderer::set_text_scale (the player's "text size" option): half size to triple size.
inline constexpr float kMinTextScale = 0.5f;
inline constexpr float kMaxTextScale = 3.0f;

// Compiles the material `materialPath` (project-relative *.material.json) for one shader dialect ("hlsl5", "glsl430",
// "glsl300es", "metal_macos", "metal_ios", "metal_sim") and returns its `factoria.shader/1` twin
// (docs/design/CUSTOM_SHADERS.md). The tooling's compile_material, handed to the renderer by `factoria` and the editor
// (EngineConfig::shaderCompiler); an exported player has none and reads the twins `<material>.<slang>.shader` instead.
// On failure the error message lists every compile error ("shaders/x.surface.glsl:7:5: error: ...").
using ShaderCompiler = std::function<Result<Json>(const std::string& materialPath, const std::string& slang)>;

// What a custom material is for (the "kind" of *.material.json, docs/design/CUSTOM_SHADERS.md "Kinds (M72)"): Mesh = a
// MeshRenderer's surface (the default), Sprite = the 2D quad path (Sprite, Shape2D, Tilemap, Text, particles, UI
// images), Sky, Post = a pass of the post-processing stack, Compute. Each kind has its own template files and its own
// template hash.
enum class MaterialKind { Mesh, Sprite, Sky, Post, Compute };
// "mesh", "sprite", "sky", "post", "compute", in the order of MaterialKind.
const std::vector<std::string>& material_kind_names();
const char* material_kind_name(MaterialKind kind);
std::optional<MaterialKind> material_kind_from_name(std::string_view name);

// SHA-256 of the template files of `kind` (engine/render/shaders/*_common.glsl, one list per kind in
// engine/render/CMakeLists.txt) this renderer was built with: a material twin made from another template is refused.
// The tooling writes the same value into every twin of that kind. "" for a kind without a template yet (Compute).
std::string material_template_hash(MaterialKind kind);
// material_template_hash(MaterialKind::Mesh).
std::string mesh_template_hash();
// The template hash of a mesh material in "full" mode (mesh_common.glsl and mesh_full_common.glsl): the value of its
// twins' "template".
std::string mesh_full_template_hash();

// The GPU backend a renderer draws through (RendererDesc::backend). Default = the sokol backend this binary was built
// with (OpenGL on Linux, Direct3D 11 on Windows, Metal on Apple, GLES3 on Android, WebGL2 on the web), which presents
// into the window sokol_app made. D3d12 (Windows) and Vulkan (Linux, Windows, Android; macOS through MoltenVK in a build
// with the tests) are the engine's own backends: offscreen (RendererDesc::headless) or into a window through a swapchain
// of their own on the native window RendererDesc::nativeWindow hands over (the runtime claims it from the platform:
// fa/platform/app.h, app_claim_native_window). init() fails with a teaching error where they are not built, there is no
// such GPU or the window cannot take their swapchain; the runtime then falls back to Default in process
// (docs/RENDERING.md, "Choosing the GPU backend"). Recording draws on no GPU at all (it validates and records every
// call: tests).
enum class GpuBackend : std::uint8_t { Default, Gl, Gles3, WebGl2, D3d11, Metal, D3d12, Vulkan, Recording };

// The name of a backend as a project's `render.backend` and the FA_GPU_BACKEND variable write it: "auto" (Default), "gl",
// "gles3", "webgl2", "d3d11", "metal", "d3d12", "vulkan" ("recording" for GpuBackend::Recording, which no setting accepts).
const char* gpu_backend_name(GpuBackend backend);
// The inverse of gpu_backend_name for the names a game may ask for ("auto" and the seven GPU backends; "recording" is not
// one); nullopt for anything else (the caller reports it with gpu_backend_names()).
std::optional<GpuBackend> parse_gpu_backend_name(std::string_view name);
// The names parse_gpu_backend_name accepts besides "auto": every GPU backend, whether this binary has it or not.
std::vector<std::string> gpu_backend_names();
// Whether this binary can make a device of `backend` (Default: always): the sokol backend it was built with, D3D12 on
// Windows, Vulkan where FA_RENDER_VULKAN is on. True does not promise a GPU or a window path.
bool gpu_backend_available(GpuBackend backend);
// Whether `backend` runs on the sokol context (Default and the five sokol backends) and presents into the platform's
// swapchain. False for D3d12, Vulkan and Recording: they make a device of their own, and a window renderer of D3d12 or
// Vulkan needs the native window (RendererDesc::nativeWindow) to make its own swapchain on.
bool gpu_backend_on_context(GpuBackend backend);

// The window a renderer of D3d12 or Vulkan makes its swapchain on, as the platform hands it over
// (fa/platform/app.h, app_claim_native_window: the render module includes no platform header). Ignored by the sokol
// backends (sokol_app made the window's swapchain) and by a headless renderer.
struct NativeWindowHandle {
    // HWND (Windows), the X11 Window as an integer in the pointer (Linux), ANativeWindow* (Android), CAMetalLayer*
    // (macOS: Vulkan on MoltenVK). Null: no window (init() of a D3d12 or Vulkan window renderer fails and says so).
    const void* window = nullptr;
    const void* display = nullptr;  // the X11 Display* (Linux); null elsewhere
    int width = 0;                  // the framebuffer size in pixels; 0 = the window's own size
    int height = 0;
};

struct RendererDesc {
    int designWidth = 1280;
    int designHeight = 720;
    int sampleCount = 1;    // MSAA of the game target (1 = off)
    bool headless = false;  // no swapchain; present() must not be called
    // The graphics context was opened before the renderer by Renderer::open_context (the player does, so it can present its
    // first frame before it reads any game file): init() uses it instead of calling sg_setup(), and shutdown() leaves it open
    // (close_context() closes it). Ignored (a normal init) when no context is open. A context that is open when init() runs
    // is never closed by shutdown(), with this flag or without it.
    bool adoptContext = false;
    // The GPU backend (GpuBackend). A sokol one (Default, or the one this binary was built with) runs on the sokol
    // context as above; any other sokol backend is an init() error. D3d12, Vulkan and Recording make a device of their
    // own and never open, adopt or close the sokol context; without `headless`, D3d12 and Vulkan make their swapchain
    // on `nativeWindow` (init() fails with the device's reason when it is null or the window refuses it; Recording has
    // no window path and always fails there).
    GpuBackend backend = GpuBackend::Default;
    // M77-P10d (factoria.json render.asyncCompute / render.multiThreadRecording; docs/RENDERING.md): what the frame may use
    // where the device has it (D3D12, and Vulkan with a compute queue of its own; the sokol backends have neither and
    // record the frame as before). asyncCompute: the depth pyramid's reduce (SceneSettings.occlusionMode gpu) runs on the
    // compute queue, next to the graphics passes after it. multiThreadRecording: the shadow views are recorded into
    // command lists of their own on the job threads. The picture is the same either way; false keeps that work on the
    // graphics queue / the render thread (to compare, or to rule a driver out). startup_report() says which is in use.
    bool asyncCompute = true;
    bool multiThreadRecording = true;
    NativeWindowHandle nativeWindow;  // D3d12 and Vulkan without `headless`: the window to make the swapchain on
    // D3d12 and Vulkan without `headless`: the present mode of their swapchain (true: FIFO / sync interval 1). The
    // sokol backends follow the platform's (app_set_vsync).
    bool vsync = true;
    // M78 (factoria.json render.frameGeneration; docs/FRAME_GENERATION.md): the game asks for frame generation, so the providers' device hooks are
    // handed to the device this renderer makes (gpu::DeviceInit::hooks; never registered for the process, so another renderer's device does not
    // see them). They take part in making the swapchain, which cannot be changed later. False: the mode can be
    // set at run time, but a provider never starts and the reason says to restart with the setting on. Only D3d12 and Vulkan in a window use it.
    bool frameGeneration = false;
    // The mode the game asked for (render.frameGeneration.mode; the renderer's frame generation settings can change it later, a provider that
    // makes the swapchain cannot): each provider's hook decides from it whether it takes part (an FSR swapchain under mode "dlss" would be wrong).
    render::FrameGenMode frameGenerationMode = render::FrameGenMode::Auto;
    // M78 (factoria.json render.upscaler.rayReconstruction): the game asks for DLSS Ray Reconstruction, so NVIDIA Streamline is told to load
    // its plugin (sl.dlss_d) before the Direct3D 12 or Vulkan device is made. False: the setting can still be set at run time, but the plugin
    // is not loaded and render.supports "dlssRayReconstruction" says to restart with the project setting on (a game that never uses it is not
    // asked for the plugin's load time and memory).
    bool rayReconstruction = false;
    // The project asked for Ray Reconstruction (the flag is true) but starts in a mode that never draws with DLSS, so `rayReconstruction` is
    // false: the answer of render.supports says to set render.upscaler.mode to "dlss" or "auto" and restart, not to set the flag.
    bool rayReconstructionNeedsMode = false;
};

// What one drawn frame cost. With several cameras (Camera.viewport) every number adds up over the cameras: drawCalls, sprites,
// triangles... count what each camera drew, so a sprite in view of two cameras counts twice, and lights, lights2d,
// lights2dDropped and lights2dShadowed are the lights each camera used, added up (a light two cameras reach counts twice).
// The cameras of CameraViews count like any other camera (one more pass each, in `views`).
struct RenderStats {
    int drawCalls = 0;
    int sprites = 0;
    int shapes = 0;
    int textGlyphs = 0;
    int glyphAtlasSize = 0;  // side of the glyph atlas in pixels (1024, 2048 or 4096; it grows when full, then clears)
    int glyphAtlasResets =
        0;  // times the glyph atlas was made, grew or cleared (1 at the start); a frame that met one is gathered again
    int particles = 0;
    int meshes = 0;        // MeshRenderer entities drawn in the main pass (instances)
    int meshesCulled = 0;  // MeshRenderer entities outside the camera frustum: not drawn in the main pass
    int meshBatches = 0;  // instanced batches drawn (meshes with the same mesh, textures and material values share one)
    int triangles =
        0;  // triangles of the main pass draw calls, per pass drawn: a part a full-shader material draws in 3 passes counts 3 times
    int shadowCasters =
        0;          // MeshRenderer entities drawn into the shadow map (castShadows, inside the shadow light's volume)
    int views = 0;  // CameraViews drawn this frame (each one renders its camera into an image first)
    int renderTargets =
        0;  // cameras with Camera.renderTarget drawn into their texture this frame (before the cameras that show them)
    int lights =
        0;  // 3D lights in the light tables of the frame's views (at most 1024 per view, 32 directional); Light2D is counted in lights2d
    int lightsDropped = 0;  // 3D lights over those limits that were left out (the least relevant ones)
    int lightsCulled =
        0;  // point, spot and area lights whose range is outside the camera's view: not in the table, they light nothing drawn
    // Clustered lighting (M73.1), summed over the views of the frame: the grid is about 64 px tiles by 24 depth slices.
    int lightClusters = 0;        // clusters of the grids built (a view with local lights builds one)
    int lightClusterEntries = 0;  // light indices in the lists of those clusters (at most 524288 per view)
    int lightClusterClipped =
        0;  // entries left out because a cluster already had 128 lights or the view 524288 entries: a hint to lower the ranges
    int lightMaxPerCluster =
        0;  // the longest list of a cluster (the most lights any one fragment loops over, besides the directional ones)
    // Volumetric fog (M73.5), summed over the cameras of the frame.
    int volumetricCameras = 0;        // cameras that drew the volumetric fog (SceneSettings.volumetricFog)
    int volumetricLights = 0;         // lights (Light.volumetric above 0) whose shafts those cameras drew
    int volumetricLightsDropped = 0;  // lights with volumetric above 0 left out: more than volumetricQuality allows
    // Contact shadows (M73.2c): lights (Light.contactShadowLength above 0, with SceneSettings.contactShadows on) whose ray the meshes of the
    // frame march against the depth prepass; 0 when no camera could make the prepass.
    int contactShadowLights = 0;
    // Transmission (M73-P6b): visible transmissive mesh instances of the frame (glass, liquids; MeshRenderer.transmission), the copies of the
    // opaque picture made for them (one per camera with such a draw; 0 means no copy was made: bit-identical to a frame without the feature),
    // and the cameras whose transmissive meshes were blended plainly, with no refraction, because the copy could not be made.
    int transmissiveMeshes = 0;
    int transmissionCopies = 0;
    int transmissionPlain = 0;
    // Copies of the picture made for Water2D, DistortionZone2D and sprite materials that call fa_scene_color() (M74.4), summed over the cameras of
    // the frame; 0 when nothing reads the picture drawn so far: such a frame makes no copy and holds no image.
    int sceneCopies = 0;
    // Big worlds (M75, docs/BIG_WORLDS.md), summed over the cameras of the frame. Each is zero while its feature is not in use
    // (no Occluder, no Terrain, no Foliage...) (game.render_stats, perf.measure and the budgets of perf.check read them).
    int occluders =
        0;  // M75.2: Occluder entities rasterised into the occlusion depth buffer (0 with no enabled Occluder)
    int occlusionTests =
        0;  // M75.2: meshes tested against that buffer, or against the depth pyramid (occlusionMode gpu, M75.2b)
    int meshesOccluded =
        0;  // M75.2: of meshesCulled, the MeshRenderer entities proved hidden behind occluders or the pyramid (still drawn into shadow maps)
    int portalsVisited =
        0;  // M75.2: distinct open OcclusionPortals the camera's walk went through, summed over the cameras (0 with no enabled OcclusionArea)
    int meshesCulledByArea =
        0;  // M75.2: meshes left out of the main pass because no chain of open portals leads to their area (also in meshesCulled)
    int lodCrossFades =
        0;  // M75.1: meshes drawn in the main view as one level of a dithered LOD cross-fade, summed over the cameras (a fading
            // entity counts 2; probe and GI captures do not count)
    int hlodProxies =
        0;  // M75 P1d: HLOD proxy meshes drawn in the main view (LodGroup.hlodProxy past hlodThreshold, one fading out counts too;
    // and, P1e, the proxy of a streamed cell that is not loaded)
    int impostors =
        0;  // M75-P1c: cards of MeshRenderer.impostor drawn in the main pass (not in `meshes`; a fading card counts)
    int terrainTiles = 0;      // M75.5: Terrain tiles drawn in the main pass (after the LOD selection and the culling)
    int terrainTriangles = 0;  // M75.5: triangles of those tiles (also in `triangles`; the tiles are not in `meshes`)
    int foliageInstances = 0;  // M75.6: Foliage instances drawn (after the density, the fade and the culling)
    int foliageInstancesCulled =
        0;  // M75.6: Foliage instances left out by the frustum, the occlusion or the fade distance
    // Subsurface scattering (M73.5), summed over the cameras of the frame.
    int subsurfaceCameras =
        0;  // cameras that scattered the light of MeshRenderer.subsurface (0 when none could: no prepass, no RGBA16F)
    int subsurfaceDraws =
        0;  // draw calls of the scattering meshes (the sss pass; the main pass draws them too, those are in drawCalls)
    // Projected decals (M73.5b), summed over the views of the frame.
    int decals = 0;  // Decal entities drawn: in a view's decal table, at most 256 per view
    int decalsDropped =
        0;  // Decals in view that were left out: over the 256 of the view, or their albedo texture could not be used
    int decalClusterClipped =
        0;  // decal-list entries lost to the 32 decals per cluster or the 131072 entries per view: 0 is normal
    int lights2d = 0;         // Light2D lights shading the 2D visuals (at most 256)
    int lights2dDropped = 0;  // Light2D lights left out: off-view ones, then the ones over the 256 of the budget
    int lights2dShadowed =
        0;  // of lights2d, the point lights whose castShadows is in effect (a Tilemap with occludesLight; at most 32)
    int materials = 0;  // distinct custom materials (MeshRenderer or Sprite material) drawn with their own shaders
    // How many times a 2D item's material was looked up in full this frame (path normalized, params packed and hashed):
    // once per distinct material and set of materialParams values, however many components, quads or particles use it;
    // the other asks are answered from a per-frame cache and not counted (a set of values counts as distinct when its
    // keys come in another order too: {"a":1,"b":2} and {"b":2,"a":1} are looked up once each). The cache is also
    // dropped when the camera being gathered changes (a material texture "target:<own>" is the checker for the camera
    // that renders into it), so a frame with render targets counts the lookup once for each camera. Also in
    // game.render_stats.
    int materialResolves = 0;
    // Materials drawn as the magenta error material (mesh) or magenta quads (sprite) because they failed to build (see
    // asset_report). A sky material that failed (or is not a sky one) draws the built-in sky gradient instead, not
    // magenta. A post material of PostProcess.customPasses that did not build, is not a "post" material or cannot be
    // drawn is here too, and its pass is skipped (the picture is drawn without it).
    std::vector<std::string> materialFallbacks;
    // How many times, since the renderer was made, the 3D scene it builds (one per frame, and one per capture_world of an
    // entity's subtree) had more distinct meshes, textures, materials or pipelines than a sort key holds, so its opaque meshes
    // were sorted by the slower comparator instead. The picture is the same; 0 is normal. Unlike the other counters this one is
    // NOT per frame: it only grows.
    int sortKeyFallbacks = 0;
    double cpuMs = 0.0;
    // Where the frame's time went, per pass of the frame graph and per job (see render.frame_graph). Both are empty before the
    // first frame. A job is `target:<name>`, `view:<n>`, `camera:<i>`, `screen` or `capture`, and a pass is named
    // `<job>/<pass>`. Wall-clock and GPU numbers: measurements only, never part of the simulation, and not in to_json().
    struct PassTime {
        std::string name;  // "<job>/<pass>", as in the frame graph's `order`
        std::string job;   // the part of `name` before the last '/'
        // CPU milliseconds the pass's callback took to record its GPU commands (wall clock).
        double cpuMs = 0.0;
        // GPU milliseconds of that pass in a recent frame (a frame or a few before this one: the timer queries arrive late and
        // are never waited for), taken from the newest finished measurement of a pass with this name; -1 when there is none
        // (the backend has no timer queries, the profiler is off, the answer has not arrived, or the frame had more passes than
        // the timer measures).
        double gpuMs = -1.0;
    };
    struct JobTime {
        std::string job;
        int passes = 0;       // passes of the job that ran (culled ones are not counted)
        double cpuMs = 0.0;   // sum of the cpuMs of its passes
        double gpuMs = -1.0;  // sum of the gpuMs of its passes; -1 when none of them has one
    };
    std::vector<PassTime> passes;  // the passes that ran, in execution order (culled passes are not listed)
    std::vector<JobTime> jobs;     // one per job, in the order the first pass of each ran
    Json to_json() const;
};

// Whether a pass of the frame graph belongs to the post-processing: its name (`<job>/<pass>` or the part after the last '/') is
// `post`, or starts with `bloom-`, `exposure-`, `ssao`, `dof`, `ssr`, `motion`, `fog`, `shafts`, `radial` or `taa`. The `prepass`
// and `sprite-coverage` passes are not counted: they also serve the 3D picture, and they feed the effects that need them.
bool is_post_pass(std::string_view passName);

// What the post-processing passes of one frame cost: the passes of `st` that is_post_pass() accepts, and their sum. `gpuMs` is the
// sum of the passes that have a GPU time, -1 when none has one (no timer on this backend, the profiler off, or no answer yet:
// never a 0 that would look like a measurement). Effects folded into the single `post` pass are not timed one by one.
struct PostPassTimes {
    std::vector<RenderStats::PassTime> passes;
    double cpuMs = 0.0;
    double gpuMs = -1.0;
};
PostPassTimes post_pass_times(const RenderStats& st);

// Immediate-mode debug drawing (cleared after each render). World space unless
// stated; drawn on top of the scene. Scripts reach it via `debug.line(...)`.
class DebugDraw {
public:
    void line(Vec3 a, Vec3 b, Color c = Color::white(), float thickness = 1.0f);
    void rect(Rect r, Color c = Color::white(), bool filled = false);
    void circle(Vec2 center, float radius, Color c = Color::white(), bool filled = false);
    void box(Vec3 center, Vec3 size, Color c = Color::white());  // 3D wire box
    void sphere(Vec3 center, float radius, Color c = Color::white());
    void text(Vec2 screenPos, std::string_view text, Color c = Color::white(), float size = 16.0f);  // screen space
    void clear();
    struct Impl;
    Impl* impl() { return impl_.get(); }
    DebugDraw();
    ~DebugDraw();

private:
    std::unique_ptr<Impl> impl_;
};

// Draws the bones (Bone2D) of the entity `root` and everything under it (every bone of the world when `root` is the null entity)
// into `draw` for one frame: a thin kite from each bone's origin to its tip (scene/bones2d.h, bone_kite), and a small circle at
// its origin. The editor's bone overlay and `debug.bones()` both call it. Returns the number of bones drawn.
int debug_draw_bones(DebugDraw& draw, const World& world, Entity root, Color color = Color{0.2f, 0.9f, 1.0f, 1.0f});

class Renderer {
public:
    Renderer();
    ~Renderer();
    Renderer(const Renderer&) = delete;
    Renderer& operator=(const Renderer&) = delete;

    // Calls sg_setup() with `env` (unless a context is already open: the renderer then uses it and never closes it). Returns false + message on failure.
    bool init(const RendererDesc& desc, const GfxEnvironment& env, std::string* error);
    void shutdown();
    bool initialized() const;
    // The description init() was given (a default one before). What the engine decided from the project, for tests and tools to check.
    const RendererDesc& desc() const;

    // --- Start-up (docs/PERFORMANCE.md, "Startup"; docs/design/ARCHITECTURE_RENDERING.md "Start-up order and the shader cache") ----------------------------------
    // A window player opens the graphics context FIRST (open_context), presents one cleared frame (present_clear) and only
    // then starts the engine, which reads the game's files and makes the renderer (init with desc.adoptContext). Nothing here
    // changes what a game draws: the first game frame is the same whether or not these ran.
    // sg_setup() with the same limits init() uses. False + message when the device is not usable. False when a context is open.
    static bool open_context(const GfxEnvironment& env, std::string* error);
    static bool context_open();
    // sg_shutdown() when a context is open and no renderer owns it (a start that failed before the renderer existed, or the
    // end of a player). A renderer whose init() found the context open leaves it open in shutdown(): whoever opened it closes it.
    static void close_context();
    // The end of a frame of a client that draws into the window itself (the editor): presents what the passes drew. False when
    // no context is open. A game's Renderer::present() commits on its own.
    static bool commit_context();
    // One frame that clears the swapchain to `color` (default black, the letterbox colour) and commits it. No renderer
    // needed; also fine while one exists (the commit is noted). False when no context is open (nothing is drawn). The
    // player's error screen uses it with red.
    static bool present_clear(const GfxSwapchain& swapchain, Color color = Color{0, 0, 0, 1});
    // A pass into the window for a client that draws into it itself (the editor's ImGui): clears the swapchain to
    // `clear`, and the caller draws and calls end_window_pass(). Needs an open context (sg_isvalid); no renderer.
    // present_clear is these two and a commit. Not for the game's picture: present() draws that.
    static void begin_window_pass(const GfxSwapchain& swapchain, Color clear);
    static void end_window_pass();
    // Makes, a few at a time, the pipelines the first game frame would otherwise compile in the middle of drawing: the
    // present blit and the sprite pipelines, plus the mesh, sky and shadow ones when `world` has a MeshRenderer. One call
    // makes one group (about a frame's worth of driver work on Metal and D3D11). Returns how many groups are left (0 = done,
    // and every later call returns 0 at once). A frame drawn before the groups are done makes any missing pipeline on the spot,
    // exactly as before: pictures never depend on this. Not for a headless renderer (returns 0).
    int warm_step(const GfxSwapchain& swapchain, World& world);
    // {backend, cache, programs, createMs, cache counters (D3D11), pipelinesWarmed, pipelines, pipelineHits,
    // pipelinesMade, pipelinesEvicted, warmMs, groupsLeft, asyncCompute, multiThreadRecording}: what the start-up spent on
    // shader programs and pipelines (the `loading.startup.gpu` object of play.report), and whether the frame uses the
    // compute queue and the job threads (RendererDesc allows it and the device has the feature).
    Json startup_report() const;

    // Resize the game target (e.g. Expand scale mode, editor viewport).
    void set_target_size(int width, int height);
    // Render scale: the game target's GPU images are target size * scale (1.5 on 1280x720 = 1920x1080) while layouts,
    // cameras, the HUD and the visible area stay in design units, so the frame is the same, drawn sharper (like a
    // fullscreen window). capture() returns the scaled image. Clamped to kMinRenderScale..kMaxRenderScale (NaN = 1).
    // Recreates the targets: draw again before capturing.
    static constexpr float kMinRenderScale = 0.25f;
    static constexpr float kMaxRenderScale = 4.0f;
    // `baseScale` (0: the same as `scale`) is the part of `scale` that does not come from the dynamic resolution (the
    // player's scale times the upscaler's quality): the temporal upscaler's history is bound to it, not to the size,
    // so a step of the dynamic resolution (a different `scale` with the same `baseScale`) keeps the history and any
    // other change of the render size starts it again.
    void set_render_scale(float scale, float baseScale = 0.0f);
    // GPU frame times for the dynamic resolution (docs/UPSCALING.md): while on, and where gpu_timing_supported()
    // (D3D11 and OpenGL), every drawn frame is timed with a timer query even with the profiler off. take_gpu_frame_ms
    // appends the milliseconds of the frames whose result arrived since the last call (a few frames late, never
    // waited for) and clears them; nothing while off. Measurement only. The profiler's take_gpu_ms() and this list
    // each see every result (they do not take each other's). Needs an initialized renderer (before init() the call
    // does nothing: ask again after it).
    void set_gpu_frame_timing(bool on);
    void take_gpu_frame_ms(std::vector<double>& out);
    // The player's render scale (window.renderScale, and the upscalers of M76): with `on` and a render scale below 1 the picture is
    // drawn at the lower resolution, brought back to the design size by the upscale stage, and the screen-space items (HUD, UI,
    // debug text) are drawn over it at the design size, so text stays sharp, unless the post stack would have changed them (a bloom
    // with PostProcess.bloomScreenSpace true makes them glow): then they stay in the smaller picture and are scaled up with it, as
    // without the stage. capture() returns the design-size picture, HUD included. Off (the default), set_render_scale only changes the size of every image and of the captures (a screenshot "scale"),
    // as before. Costs memory (one image of the design size) only while it applies; recreates no render target.
    void set_upscale_stage(bool on);
    bool upscale_stage() const;
    // The engine-wide upscaler setting (fa/render/upscaler.h, M76): what the upscale stage draws with. The mode that really draws
    // is effective_upscaler_mode(): the setting's mode where this backend can draw it, and "stretch" for pixel art (ScaleMode::PixelPerfect,
    // set_scale_mode) so its hard edges stay. With "spatial" the stage also runs at render scale 1 when the sharpness is above 0 (the
    // sharpen alone); with "stretch" it never does. The render scale itself is not derived here: the caller sets it (Engine does:
    // docs/UPSCALING.md, "The render scale").
    void set_upscaler(const render::UpscalerSettings& settings);
    const render::UpscalerSettings& upscaler() const;
    // The quality layer of the graphics presets (fa/render/graphics_preset.h, docs/UPSCALING.md "Graphics presets"): limits the renderer applies
    // to what the scene, its cameras' PostProcess and its lights ask for, from the next frame on. The default (QualityLimits{}) limits nothing.
    // Nothing of the scene is changed, so setting the default again brings the game's own look back unchanged; the simulation never reads it.
    void set_quality(const render::QualityLimits& limits);
    const render::QualityLimits& quality() const;
    // The colour space the game target is in now (the last drawn world's SceneSettings.colorSpace; Gamma before the first frame). A caller
    // that draws a world of its own (the GPU benchmark) gives it this one, so the draw does not make the game's targets again.
    ColorSpace color_space() const;
    // `preset` as this GPU draws it: its table of limits and upscaler with every knob the GPU cannot honour lowered or switched off, and the
    // reason of each (render.supports' status). Changes nothing; needs no frame.
    render::QualityResolved resolve_graphics_preset(render::GraphicsPreset preset) const;
    // The engine-wide low-latency setting (fa/render/latency.h, M78; docs/LATENCY.md). The path that runs is effective_latency(): the mode's
    // SDK where it is usable, else the engine's own pacing (a renderer that presents to a window), else none. Needs an initialised renderer (before init() the
    // calls do nothing; the engine sets it right after init). Off (the default) costs nothing: the calls below return at the first branch.
    void set_latency(const render::LatencySettings& settings);
    const render::LatencySettings& latency() const;
    render::LatencyDriver effective_latency() const;
    // What the setting is and why: {"mode", "boost", "driver", "reason" (why the mode runs another path, or ""), "modes": {name: {"available",
    // "reason"}} for reflex, antilag2 and xell}. Asks each SDK once.
    Json latency_status();
    // The frame's markers (src/render_latency.h). The engine calls latency_frame_begin once per frame before it samples the player's input
    // (it sleeps there, when the path paces: `refreshHz` is the display's refresh rate while the loop runs at it, else 0), and
    // latency_mark for InputSample and SimulationEnd; the renderer marks the rest itself (begin_frame, present).
    void latency_frame_begin(double refreshHz);
    void latency_mark(render::LatencyMarker marker);
    // Input to the end of the present call of the last frame measured, in ms, once; negative when no frame was measured since the last call.
    double take_latency_ms();
    // The readout: {"driver", "lastMs", "avgMs", "p95Ms", "maxMs", "samples", "vendor"} (vendor: the SDK's own report, or null).
    Json latency_report();
    // The engine-wide frame-generation setting (fa/render/framegen.h, M78; docs/FRAME_GENERATION.md). The provider that runs is
    // effective_frame_generation(): the mode's SDK when it is usable here, else none (the reason is in frame_generation_status). Whether it
    // generates this frame is the controller's: it needs the temporal upscaler's frame and a base frame rate of at least minBaseFps. Needs an
    // initialised renderer (before init() the calls do nothing). Off (the default) costs nothing.
    void set_frame_generation(const render::FrameGenSettings& settings);
    // The ray tracing setting (fa/render/raytracing.h, M79; docs/RAY_TRACING.md). With an effect on and a device that can trace, the renderer
    // keeps the scene's acceleration structures (a BLAS per mesh, a TLAS every frame; docs/design/ARCHITECTURE_RT_SCENE.md); off, or on a device
    // that cannot, it makes no buffer and does no work (a device that cannot says why once in the log). Applied at the start of the next frame.
    void set_ray_tracing(const render::RayTracingSettings& settings);
    // What the frames trace: the setting above under the graphics preset's caps (QualityLimits::rtShadows..., set_quality), which never turn an
    // effect on. The same as the setting while no preset caps it.
    const render::RayTracingSettings& ray_tracing() const;
    // Why an effect that is on is drawing its raster version this frame although the device traces (a kernel the driver rejected, a prepass
    // that does not match the output): one line per effect, empty when every effect that is on runs. Thread-safe.
    std::string ray_tracing_failure() const;
    // The path tracer (M79-P5a, fa/render/raytracing.h PathTracerSettings; docs/design/ARCHITECTURE_RT_PATHTRACER.md): a progressive reference picture
    // of the main camera in place of the raster's lit colour. Applied at the start of the next frame; off (the default) it costs nothing. It turns the
    // scene's acceleration structures on by itself. path_tracer_status() is what the last drawn frame did (the accumulated samples, why it restarted,
    // why it could not run); call it from the thread that draws.
    void set_path_tracer(const render::PathTracerSettings& settings);
    const render::PathTracerSettings& path_tracer() const;
    render::PathTracerStatus path_tracer_status() const;
    // M79-P2a-3: the point, spot and area lights of the last whole frame: how many asked for a shadow (`candidates`, the lights the shadow maps were
    // planned for) and how many of them the rays shadowed (`traced`, at most the cap `render::kRtLocalShadowMaxLights` (raytracing.h); the rest kept their maps).
    // 0 and 0 while ray tracing is off, no camera traced them or the device refused the kernel. Thread-safe.
    void ray_tracing_local_shadows(int& candidates, int& traced) const;
    // M79-P4a: the realtime GI probes updated by rays, as of the last whole frame (RtGiStatus). Thread-safe.
    render::RtGiStatus ray_tracing_gi_status() const;
    // M79-P4b-1: the per-pixel ray traced GI (gi "perPixel"), as of the last whole frame (RtGiPixelStatus). Thread-safe.
    render::RtGiPixelStatus ray_tracing_gi_pixel_status() const;
    // M79-P4b-2: whether DLSS Ray Reconstruction denoised the ray traced reflections and the per-pixel GI in the last whole frame (RtDenoiserStatus).
    // Thread-safe.
    render::RtDenoiserStatus ray_tracing_denoiser_status() const;
    const render::FrameGenSettings& frame_generation() const;
    render::FrameGenSlot effective_frame_generation() const;
    // What the setting is and why: {"mode", "minBaseFps", "provider", "state" (off, refused, measuring, paused, active), "reason", "modes": {name:
    // {"available", "reason"}} for dlss, fsr and xess}. Asks each SDK once.
    Json frame_generation_status();
    // The readout: {"provider", "state", "generating", "baseFps", "presentedFps", "renderedFrames", "generatedFrames", "reason"} (the rates over
    // the last 30 rendered frames; "reason" says why nothing runs or why generation is paused).
    Json frame_generation_report();
    render::UpscalerCaps upscaler_caps() const;  // what this backend and display can draw (the input of the next line)
    render::UpscalerMode
    effective_upscaler_mode() const;  // the mode that draws now; "stretch" while the renderer is not initialised
    float render_scale() const;       // the scale set by set_render_scale (1 before)
    // The graphics backend in use: "metal", "d3d11", "glcore", "gles3", "dummy", or "unknown" for a sokol backend the
    // engine never builds (what game.device.gpuBackend reports).
    static const char* backend_name();
    // The backend of the device this renderer draws on (never Default: the sokol backend it runs is named); Default
    // before init() and after shutdown(). Unlike backend_name() it says "d3d12" or "vulkan" for the engine's own backends.
    GpuBackend device_backend() const;
    // The GPU this renderer draws on, as its device's graphics API describes it (the adapter's name, vendor, memory;
    // fa/render/gpu_info.h), with `backend` = backend_name(). Before init() or after shutdown(): backend "none" and
    // nothing else. Call it on the thread that draws (OpenGL answers for the context current there).
    render::GpuInfo gpu_info();
    // The compute side of the renderer (storage buffers, dispatches of "kind": "compute" materials; available() says
    // whether this backend can). Usable once init() succeeded; its buffers end with shutdown().
    Compute& compute() { return *compute_; }
    int target_width() const;
    int target_height() const;

    void begin_frame();
    // Call after an sg_commit() the renderer did not do itself (the editor commits once per UI frame): the next
    // begin_frame() may then reuse the frame's transient vertex buffers. Without it extra draws get fresh buffers.
    void note_commit();

    // --- Simulation / drawing split --------------------------------------------------------------
    // Nothing time-based lives in the renderer: SpriteAnimator frames (fa::update_sprite_animators) and ParticleEmitter
    // simulation (World::particles(), a ParticleStore) are stepped by the runtime in the fixed simulation step, with or without a
    // renderer, and render_world() only DRAWS what the world holds: the image depends solely on the world + renderer state.
    // update() refreshes what queries need without drawing (the cameras, so world_to_screen and entity.bounds() are right in a run
    // that skips drawing, and the Parallax offsets); it needs no begin_frame().
    // Parallax rule (the same without a renderer): the offset the world keeps is the one for the FIRST camera (the one that comes
    // first in render order, which a script's camera queries default to). While a frame is drawn each camera draws the layers
    // shifted for itself (several cameras, a render target, a CameraView), and the first camera's offset is put back when it ends.
    // Contract: call update(world) once per frame, then optionally render_world(). Code that only calls render_world(world, dt)
    // keeps working: if update() was not called since the previous draw, render_world() calls it itself.
    void update(World& world);
    // Draws the world (cameras, sprites, shapes, tilemaps, text, particles, meshes, lights, debug draw).
    void render_world(World& world, float dt);

    // Size {width, height} in design/world units of `text` laid out at `fontSize` with the same code as Text
    // rendering (shaping, fallback fonts, right-to-left text, wrapping at maxWidth > 0, line height). font "" =
    // built-in font. `space` is where the text would be drawn: screen-space Text and UI labels (RenderSpace::Screen)
    // are scaled by the text scale, world-space Text is not.
    // `style`: Text.markup (tags are not characters, an icon is a picture as tall as the line) and Text.bold.
    Vec2 measure_text(std::string_view text, float fontSize, std::string_view font = {}, float maxWidth = 0,
                      RenderSpace space = RenderSpace::World, TextStyle style = {}) const;
    // Size of a Text component as it is drawn: like measure_text above, with the Text's maxTextScale cap and autoShrink
    // (maxWidth x maxHeight box) applied at the current text scale (text_fit.h). What layout, bounds and ui.rectOf use.
    Vec2 measure_text(const Text& text) const;

    // ---- Text -------------------------------------------------------------------------------------------------
    // Fonts to fall back on, in order, for the characters a Text's own font lacks. The chain of every Text is: its
    // `font` ("" = the built-in DejaVu Sans), then these fonts (project paths of .ttf files, or "builtin:pixel"), then
    // the built-in DejaVu Sans last. Each character is drawn with the first font of the chain that has a glyph for it;
    // a combining mark or joiner stays with its base character's font. A fallback font is only loaded when some text
    // needs it. Takes effect on the next layout (also for Text already on screen); a font that fails to load is
    // skipped (the failure is logged once and listed in asset_report()). Characters no font of the chain has draw as
    // nothing, with one warning per Text font naming them. May be called before init() (it is kept).
    void set_fallback_fonts(std::vector<std::string> fonts);
    const std::vector<std::string>& fallback_fonts() const { return fallbackFonts_; }
    // The project's "text" section (rich_text.h): the colours, icons and bold faces of Text.markup and Text.bold. Takes
    // effect on the next layout. May be called before init() (it is kept).
    void set_rich_text_style(RichTextStyle style);
    const RichTextStyle& rich_text_style() const { return richStyle_; }
    // The player's "text size" option: multiplies the font size of screen-space Text (space = Screen) and of the labels
    // of UI widgets (Button, Toggle, Slider, TextField), and the measurements of those (measure_text with
    // RenderSpace::Screen, entity.bounds()). World-space Text is part of the world and is not scaled; neither is debug
    // text. Clamped to kMinTextScale..kMaxTextScale (NaN = 1). The renderer does not save it: the game stores the option.
    // May be called before init().
    void set_text_scale(float scale);
    float text_scale() const { return textScale_; }
    // The interface scale ui.scale (ui_rect.h): screen-space UI is laid out in UI units and drawn this many times as big.
    // The renderer only needs it to measure screen-space text at the size it is drawn (measure_text); the drawing itself
    // reads World::ui_scale(). Clamped to kMinUiScale..kMaxUiScale (NaN = 1). Set by Engine::set_ui_scale; may be called before init().
    void set_ui_scale(float scale);
    float ui_scale() const { return uiScale_; }

    // Expand support: with ScaleMode::Expand the orthographic camera keeps the design height fixed (or the
    // design width when the target is taller than the design aspect). present() also records its mode.
    void set_scale_mode(ScaleMode mode);
    void end_frame();
    // Windowed: blit the game target into the swapchain with the scale mode.
    void present(const GfxSwapchain& swapchain, int framebufferWidth, int framebufferHeight, ScaleMode mode);
    // D3D12 and Vulkan on a window that comes and goes (Android: app_set_native_window_listener), on the render thread
    // between frames. Null: the window is going, so the swapchain is destroyed now (the device waits for its images);
    // present() then only ends the frame. A window: the swapchain is made on it by the next present(), at the
    // framebuffer size it is given (a failure is logged once, and the frames are not shown until the next window). A
    // swapchain the device destroyed itself (Vulkan: VK_ERROR_SURFACE_LOST_KHR) is made again the same way on the window
    // it had. Nothing on the sokol backends (sokol_app owns their swapchain) or headless.
    void set_native_window(const void* window);
    // Letterbox mapping used by present(): framebuffer pixel -> design pixel.
    Vec2 framebuffer_to_design(Vec2 fbPos, int framebufferWidth, int framebufferHeight, ScaleMode mode) const;
    // The same mapping the other way: design pixel -> framebuffer (window) pixel.
    Vec2 design_to_framebuffer(Vec2 designPos, int framebufferWidth, int framebufferHeight, ScaleMode mode) const;

    // Read back the last finished game target (RGBA8, top row first).
    bool capture(Image& out, std::string* error = nullptr);
    // capture() resampled to width x height (both >= 1): the whole frame squeezed into that aspect when `stretch`, else
    // the middle part with that aspect ratio (cover_image: nothing is distorted, the long side loses its edges). The
    // same size as the target gives exactly the pixels of capture(), so of a screenshot of the same frame.
    bool capture_fitted(Image& out, int width, int height, bool stretch, std::string* error = nullptr);

    // ---- Off-screen capture of the world (render.captureTexture with an entity or a rect) ---------------------------------
    // A rectangle of the world, or an entity's subtree, drawn at an exact pixel scale into its own image and read back: no frame
    // has to be drawn first, the main camera and the window size do not matter, and what is hidden, covered or off screen is drawn
    // all the same.
    struct WorldCapture {
        // World xy, +Y up. The image is ceil(rect * scale) pixels, the camera shows exactly that many (so the view may be less than a pixel
        // larger than the rect, never smaller).
        Rect rect{};
        float scale = 1.0f;  // pixels per world unit
        // Null: everything in the rect is drawn. An entity: only it and its descendants (the world-space Sprite, Shape2D, Text, Tilemap,
        // ParticleEmitter and MeshRenderer of the subtree), whether they are active or not; the lights of the scene still light them.
        Entity subject = kNullEntity;
    };
    // The biggest side of a world capture, in pixels (a run-time texture cannot be bigger).
    static constexpr int kMaxWorldCaptureSide = 4096;
    // Draws `spec` with an orthographic camera centred on the rect and answers its pixels (row 0 = top). The background is transparent
    // (alpha 0); soft edges keep their colour (straight alpha). Screen-space items (UI, HUD) are not part of the world and are not
    // drawn. A Sprite or a mesh that shows "target:<name>" shows that target's last picture. False + *error (a sentence that says what
    // to change) when the rect is empty, the scale is not positive or the image would pass kMaxWorldCaptureSide. Does not change
    // stats() or the picture of the frame.
    bool capture_world(World& world, const WorldCapture& spec, Image& out, std::string* error = nullptr);

    // ---- Off-screen capture through a camera, with its custom post passes (the editor's preview of a post material)
    // -------------
    struct CameraCapture {
        Entity camera = kNullEntity;  // a Camera entity of the world (primary or not: it is the one asked for)
        int width = 0, height = 0;    // pixels, 1 .. kMaxWorldCaptureSide
        // How many frames are drawn, 1 .. kMaxCaptureFrames; only the last is read back. A frame matters when a pass of
        // the camera's stack calls fa_history: it reads what the frame before drew (the first one starts clean,
        // fa_history_valid false), so a trail or a feedback has built up in the picture that comes back. A camera whose
        // stack has no custom pass draws one frame whatever this says.
        int frames = 1;
    };
    static constexpr int kMaxCaptureFrames = 8;
    // Draws what `spec.camera` sees (its 3D and 2D world, its clear colour, showTags and hideTags) into a width x
    // height image and answers its pixels (row 0 = top, straight alpha), with the custom passes of the camera's
    // PostProcess (PostProcess.customPasses of the camera and of the volumes it is in, each at its `position`; fa_depth
    // and fa_normal get the camera's prepass) run over it. No other effect of the stack is drawn (no bloom, tonemap,
    // ...): the picture is the scene as the camera draws it plus those passes. Like capture_world it needs no frame
    // drawn first and changes neither stats() nor the picture of the frame; the histories of the camera's passes
    // (fa_history) belong to the capture, start clean at every call and are freed when it ends, so the same world gives
    // the same picture. The alpha is what the picture holds (the camera's clear has alpha 1, a pass writes its own):
    // straight, never un-premultiplied. False and *error when the entity is not a Camera of the world, the size is not
    // 1 .. kMaxWorldCaptureSide, or frames is outside its range.
    bool capture_camera(World& world, const CameraCapture& spec, Image& out, std::string* error = nullptr);

    // ---- Run-time textures ------------------------------------------------------------------------------------------
    // A texture made from pixels at run time (render.captureTexture, render.textureFromPNG in scripts). Returns its id,
    // "runtime:N" (N counts from 1, never reused): put it in Sprite.texture (or any other texture field) like an asset
    // path. The texture lives until destroy_runtime_texture; clear_asset_cache() keeps it. "" + *error when the renderer is
    // not initialized or the image is empty / bigger than 4096 px.
    std::string create_runtime_texture(const Image& img, std::string* error = nullptr);
    // Frees the texture; false when `id` is not a live run-time texture. A Sprite that still names it draws the missing-
    // texture checker (and the failure is listed in asset_report()).
    bool destroy_runtime_texture(const std::string& id);

    // Camera helpers (valid after update() or render_world()). Screen points are design pixels, top-left origin, over the WHOLE
    // screen: with several cameras (Camera.viewport) a point of the screen belongs to the camera whose viewport holds it.
    // `camera` is a rendering camera entity (active, Camera.primary); null or any other entity = the default camera: for a
    // screen point the topmost camera whose viewport contains it (the highest depth, so an inset wins over the view under
    // it; the lowest-depth camera when none does), for a world point the lowest-depth ("primary") camera.
    Vec2 world_to_screen(Vec3 worldPos,
                         Entity camera = kNullEntity) const;  // design pixels inside that camera's viewport
    Vec3 screen_to_world(Vec2 screenPos, float depth = 0.0f,
                         Entity camera = kNullEntity) const;  // 2D: z = depth; 3D: point on ray at distance depth
    void screen_ray(Vec2 screenPos, Vec3& origin, Vec3& dir, Entity camera = kNullEntity) const;
    // The rendering cameras in draw order (ascending Camera.depth): empty when the world has none (a default camera draws).
    std::vector<Entity> cameras() const;
    // The camera a screen point belongs to (see above); null when the world has no camera entity.
    Entity camera_at(Vec2 screenPos) const;

    // A render target seen from outside (Camera.renderTarget): the camera that draws it, its picture's size and where a world point lands
    // on that picture (pixels, top-left origin, the camera's own projection, orthographic or perspective). The pointer reaches the
    // widgets of a page through it. nullopt when no active camera renders into `name` (a duplicate name counts the first). Does not draw.
    struct RenderTargetView {
        Entity camera;
        int width = 0, height = 0;
        std::function<Vec2(Vec3 world)> to_pixels;
    };
    std::optional<RenderTargetView> render_target_view(World& world, const std::string& name) const;

    DebugDraw& debug();
    // Of the last frame. `passTimes` false leaves RenderStats::passes and jobs empty: they are built from the frame graph only
    // when asked for (about 40 strings), so a caller that reads the counters of every frame passes false.
    RenderStats stats(bool passTimes = true) const;

    // The picture the editor viewport shows, as the ids UiPainter and the editor's ImGui take (UiTexture::image is the memory, ::view
    // what a UiDrawCommand names; both 0 until there is one): the finished game image (after the colour filter) in a gamma scene. In a linear scene that image holds linear light, which would be
    // too dark on screen: once set_editor_view(true) was called these are an 8-bit copy encoded to sRGB, made after each frame and
    // freed when the scene goes back to gamma (0 until the first frame of a linear scene made it). The same copy clamps a picture
    // above paper white (an HDR output's final pass) to the standard range. Without set_editor_view they are the game image as it is.
    render::UiTexture game_target_texture() const;
    // Asks for the encoded copy above (the editor calls it once). Costs one full-screen copy per frame of a linear scene, so a game
    // never asks. false frees the copy.
    void set_editor_view(bool on);
    // True when the game target holds colours above white (a 16-bit float format): MeshRenderer.emissiveStrength above 1 then
    // reaches the bloom with its full strength. False on a GPU that cannot render to RGBA16F with blending, filtering and the
    // requested multisampling (or with FA_SCENE_FORMAT=rgba8), or that lists it but cannot make the game target's images in it
    // (the renderer then rebuilds them in RGBA8 when the targets are first created): everything clamps at white, bloom included.
    // Reports the format the game target really has; only that target falls back, so it stays true when a CameraView, a bloom
    // level or the colour filter image cannot be made in RGBA16F (they log their own warning). The screen and screenshots show
    // 8 bits either way.
    bool hdr_scene() const;

    // Asset cache control (textures, meshes, fonts are loaded on first use by path).
    void
    reload_asset(std::string_view path);  // hot reload (a .material.json, or a snippet a material uses, rebuilds it)
    // Custom materials (MeshRenderer.material): how a material without a twin is compiled. Empty = read twins only.
    void set_shader_compiler(ShaderCompiler compiler);
    // The shader dialect of this renderer's backend (see ShaderCompiler); "" before init().
    std::string shader_dialect() const;
    void clear_asset_cache();
    Json asset_report() const;  // loaded assets + failures (missing files with hints)
    // What the material of a MeshRenderer costs the renderer: the extra passes of its features (a transmissive mesh copies the opaque
    // picture, a full-shader material draws once per pass), its phase and the features that only add fragment work; the command
    // render.material_cost and the Inspector's cost view show this report (material_cost.h). Loads the mesh and the material when they are
    // not loaded yet; {} before init().
    Json material_cost(const MeshRenderer& mr);
    std::uint64_t texture_bytes() const;  // GPU memory of the loaded textures
    // What the Terrain textures cost the GPU work since the renderer started (a test looks at them; not a stat of the picture): the height
    // textures sent whole, the rectangles of them a sculpt re-sent, the layer and control arrays built, the sub-rectangles of the splat maps
    // a repaint re-sent (`splatRects`) and the layer decoding jobs started (`layerLoads`).
    struct TerrainUploads {
        std::uint64_t whole = 0, rects = 0, arrays = 0, splatRects = 0, layerLoads = 0, holesWhole = 0, holesRects = 0;
    };
    TerrainUploads terrain_uploads() const;
    // The Terrain layer pictures (albedo and normal arrays) are decoded off the main thread, like the Foliage files: a terrain draws its
    // layers neutral (or with the pictures it had, for a reload) until the frame after the decode adopts them. A test or a capture that
    // needs them in the picture waits here, then renders once more.
    bool terrain_loading() const;
    void wait_terrain_loaded();
    // The Foliage instances files (M75.6): they are read off the main thread, and a frame draws what is ready. A test or a capture that needs
    // them in the picture waits here, then renders once more (that frame adopts them).
    bool foliage_loading() const;
    void wait_foliage_loaded();
    std::uint64_t foliage_loads() const;  // files read since the renderer was made

    // Background loading (scene.preload, assets.preload, scene.load {async: true}; docs/PERFORMANCE.md, "Background
    // loading"). The renderer prepares the files it draws from off the main thread: an IoQueue item reads the file and a
    // job decodes it (background_work), then the main thread uploads it into the caches (adopt_background) under the
    // frame's upload budget. The asset is then what a load on first use would have made, and its first use reads nothing.
    // None: a file the renderer does not prepare (a glTF .bin buffer, a video): it is only read ahead (fs::warm).
    enum class BackgroundKind { None, Texture, Model, Font };
    static BackgroundKind background_kind(std::string_view path);  // by extension: textures, .gltf/.glb, .ttf/.otf
    // `path` (normalized, project-relative) is in the cache already, loaded or failed: there is nothing to prepare.
    bool background_cached(std::string_view path, BackgroundKind kind) const;
    struct BackgroundWork {
        IoRead read;      // any thread: reads the file (a texture's KTX2 twin or atlas when the export made one)
        IoDecode decode;  // any thread: decodes it (pixels, transcoded KTX2 levels, vertices, a font face)
    };
    // Main thread (it reads the GPU's compressed format). The work touches no renderer state, so it may outlive the renderer.
    BackgroundWork background_work(std::string_view path, BackgroundKind kind) const;
    // Main thread: uploads a finished item of background_work into the caches and returns the GPU bytes it uploaded (0 for
    // a font, and when the asset was loaded on first use meanwhile: the prepared copy is dropped). A failed item is left
    // to the load on first use, which reports it as it always does.
    std::uint64_t adopt_background(std::string_view path, BackgroundKind kind, IoResult& result);

    // GPU time of drawing the world. While the profiler is on (fa/core/profiler.h; docs/PERFORMANCE.md) every drawn frame is
    // timed with a timer query where the backend has them (D3D11, desktop OpenGL); the answers arrive a few frames late and
    // are never waited for. take_gpu_ms() appends the milliseconds of the frames whose answer is ready. When
    // gpu_timing_supported() is false `reason` says why (Metal, GLES3 and WebGL2 have no timer queries here).
    // Measurement only: not part of the simulation.
    bool gpu_timing_supported(std::string* reason = nullptr) const;
    void take_gpu_ms(std::vector<double>& out);

    // The frame graph of the last frame this renderer drew and what each pass cost (the `render.frame_graph` command's
    // result; the fields are described there): {source, backend, graph: FrameGraph::to_json(), passTimes: [{name, job, cpuMs,
    // gpuMs}], jobTimes: [{job, passes, cpuMs, gpuMs}], gpu: {supported, measuring, reason, maxTimedPasses}}. `source` is "frame"
    // for a frame of render() and "capture" when the last graph was the one of a Renderer::capture_world. Null Json before
    // the first frame.
    // gpuMs is -1 where there is no measurement (gpu_timing_supported(), and the profiler must be on). Measurement only.
    Json frame_graph_report() const;

    // Reflection probes (ReflectionProbe; include/fa/render/probe.h, docs/design/ARCHITECTURE_PROBES.md). The renderer captures the realtime
    // probes a few faces a frame, uploads the baked ones, and keeps every probe's tile in one atlas image that the lit meshes sample
    // (M73-P3c; the sky is entry 0 of it).
    // The report of the `render.probes` command: {atlas: {size, format, tiles, usedTexels, reservedTexels, ...}, sky: {...}, faceBudget,
    // probes: [{entity, mode, state, tile, captures, lastFrame, ...}]}. Empty object before init() and while no probe exists.
    Json probe_report() const;
    // What `mesh` reflected in the last frame: {probes: [{entity, share}], sky}; the shares (0..1, in steps of 1/32) of the probes and of the
    // sky add up to 1. A mesh no probe reaches (or one that was not drawn) reflects the sky: {probes: [], sky: 1}. Empty object before init().
    Json probe_mesh_report(Entity mesh) const;
    // Makes the renderer keep the probe picks of `mesh` (and only of it) from the next frame on, which probe_mesh_report reads. True when it
    // already did, so the last frame's picks are there; false when the caller should draw one more frame first. kNullEntity stops
    // the watch (and frees the picks).
    bool probe_watch_mesh(Entity mesh);
    // The realtime GI's grids (RealtimeGI; include/fa/render/gi.h, docs/design/ARCHITECTURE_PROBES.md, "Realtime GI: the data side"): the report of
    // the `render.gi_grid` command: {frame, captures, capturesPerFrame, atlas, grids: [{entity, state, probes, progress, bytes, invalidProbes,
    // ...}]}. It reads the probes' meta texels back from the GPU (a command, never the frame). Empty object before init() and while no grid exists.
    Json gi_report();
    // The 2D global illumination field of the last frame (GlobalIllumination2D; docs/design/ARCHITECTURE_RENDERING_GI2D.md): the report of the
    // `render.gi2d_field` command {enabled, supported, settings, fields: [{slot, job, ready, width, height, texelSize, worldRect, ...}]}. With a
    // `savePrefix` (a UTF-8 path without extension) the three images of the field of `job` (empty: the first one that is ready) are also written
    // as <prefix>-emission.png, <prefix>-occluders.png and <prefix>-distance.png and the report lists them in "files"; a failure is in "error".
    // Reads the GPU back (a command, never the frame). Empty object before init().
    Json gi2d_field(std::string_view savePrefix = {}, std::string_view job = {});
    // The occlusion culling of the last frame (Occluder; docs/BIG_WORLDS_LOD.md, "Occlusion"): the report of the `render.occlusion` command
    // {supported, debugView, active, limits, camera, width, height, occluders, triangles, coveredCells, tests, hidden}. `active` is false
    // (and the rest left out) when no camera of the last frame had an enabled Occluder. With `savePath` (a UTF-8 path of a .png) the
    // depth buffer of the last camera that had occluders is written as a grey picture (black = no occluder; the nearer, the brighter) and
    // listed in "file"; a failure is in "error". A CPU read: no GPU involved. Empty object before init(). "gpu" holds what the depth pyramid
    // did (mode, supported, active, camera, width, height, levels, coveredCells, ageFrames, tests, hidden, testResults, ...); with no
    // Occluder buffer `savePath` writes the pyramid's mip `level` there instead (0 = 256 cells across).
    Json occlusion_report(std::string_view savePath = {}, int level = 0);
    // How far the grid of the RealtimeGI `grid` is, from the renderer's own counters (no GPU read-back, so the editor may call it every frame):
    // `known` is false before the grid was drawn or while it is not valid. Probes are captured in index order the first time, so the probes
    // below `captured` have a picture (exact unless a capture failed and is being retried).
    struct GiProgress {
        bool known = false;
        int captured = 0, count = 0;
    };
    GiProgress gi_progress(Entity grid) const;
    // Asks for the probe's next capture as soon as the budget allows (an `onDemand` probe captures only then). False when it is not a
    // realtime probe of this renderer.
    bool probe_refresh(Entity probe);
    // The most faces of realtime probes drawn in a frame, in all (1..12; default 2: a probe is complete every three frames).
    void probe_set_budget(int faces);
    // A synchronous capture of one probe, for probe.bake and tests: the six faces drawn at once into an image of their own (the atlas of
    // the realtime probes is not touched), filtered like a realtime capture. `page` is the tile without its SH row (probe.h,
    // probe_page_width x probe_page_height texels, RGB linear light, row 0 first), `sh` the nine coefficients. `intensity` is not applied
    // (the component's intensity is a gain of the reader). Needs a half-float atlas; false with `error` otherwise.
    struct ProbePage {
        int resolution = 0;
        int width = 0, height = 0;  // probe_page_width x probe_page_height
        std::vector<float> rgb;     // width * height * 3, linear light, row 0 = the top row
        float sh[9][3]{};
    };
    bool probe_capture(World& world, Entity probe, ProbePage& out, std::string* error = nullptr);

    // Whether this renderer can do `feature` on the backend and GPU it runs on: a capability of the GPU ("floatTargets",
    // "r11g11b10", "sampledDepth", "computeShaders", "float32Targets"), an engine feature ("linearColor", "hdrOutput", and the
    // lighting rows of M73 such as "cascadedShadows", planned until their package lands; "clusteredLights" is drawn) or a post effect (the
    // names of kPostEffectOrder: "bloom", "tonemap", ...). False for a name that is not in feature_names(), before init(), on the
    // headless (dummy) backend, and for what the engine does not draw (the lighting rows of M73 not yet landed;
    // linearColor is drawn on every GPU): it never claims what the renderer cannot do. "hdrOutput" is true when the display
    // the window showed its last frame on can show HDR in an encoding the renderer writes (EDR on Metal, scRGB or HDR10 on
    // D3D11), whatever the scene's hdrOutput setting. `render.supports` answers the same with the reason.
    bool supports(std::string_view feature) const;
    // Every name supports() knows, in a fixed order.
    static std::vector<std::string> feature_names();
    // The answer of the `render.supports` command: {backend, backendLabel, features: [{name, kind, supported, status, doc,
    // backends}]}. Empty object before init().
    Json supports_report() const;

    // The baked light probes of the scene's lightmap manifest (SceneSettings.lightmaps, M73.4d), loaded on first use and kept until the files change; null
    // when the scene has no manifest, it lists no probes or the file did not load (asset_report lists the failure). Valid until the next frame.
    const ProbeSet* light_probes(World& world);
    // The answer of the `render.light_probes` command: {lightmaps, baked, probes, invalid, groups: [{id, kind, count, invalid}]} and, for
    // `entity` (kNullEntity: none), {entity: {id, name, source: "probes" | "lightmap" | "sky", position, coverage, probesUsed, sh, ambient}}: what
    // that MeshRenderer receives, by the rules of the frame. Needs init().
    Json light_probes_report(World& world, Entity entity);

    // HDR display output (fa/platform/hdr_output.h; docs/RENDERING.md, "HDR output"). Once per frame before present(), on the
    // window's thread: asks the display the window is on and switches the window's swapchain to an HDR format when
    // `settings.hdrOutput` is auto, the display can show HDR and the renderer writes that encoding (EDR on Metal, scRGB or
    // HDR10 on D3D11), or back to the standard range. Non-empty `blocked`: never switch, and say this (the editor, whose window
    // shows its own UI). Nothing before init(). The next frames are drawn for the answer: the tonemap of a PostProcess goes
    // above paper white up to the output's headroom, and present() encodes the picture for the swapchain (docs/RENDERING.md).
    // The HUD and a frame without the final pass stay at paper white.
    void update_output(const SceneSettings& settings, const std::string& blocked = {});
    // What the window shows now (the `render.output` command): the last answer of update_output(), any thread.
    HdrOutputInfo output_info() const;

    // The editor's A/B switch of the Post-processing panel: true draws every following frame as if no camera had a post-processing
    // stack (no PostProcess), without touching any data; false (the default) draws
    // them. Not saved and not part of a scene: a game never sets it. Takes effect on the next frame. While it is on it applies to every
    // capture too (game.screenshot, render.inspect, what an AI asks to see), not only to the window.
    void set_post_bypass(bool bypass);
    bool post_bypass() const;

    // The depth or the normals the prepass drew (docs/RENDERING.md, "Depth and normals"), as a picture over the 3D meshes of the frame: depth in
    // greys (near is light, 10 / (10 + distance) of the camera), normals as the view-space direction mapped to colours (x, y, z -> r, g, b)
    // and black where no opaque mesh is. Needs a perspective or orthographic 3D camera that draws opaque meshes; any other frame, a GPU
    // without float render targets and a frame that is split between cameras draw the game normally. A debugging aid: it does not change
    // what a screenshot of the scene shows unless it is on. Ao shows the ambient occlusion alone, per camera, even in a split screen. The
    // environment variable FA_RENDER_DEBUG_VIEW=depth|normals|ao sets it when
    // the renderer starts. Main thread.
    void set_debug_view(DebugView view);
    DebugView debug_view() const;

    // Forgets what the custom post passes that read their own output of the frame before (fa_history,
    // docs/shaders/SHADERS_POST.md, "History") kept: from the next frame their history is not valid (fa_history_valid
    // is false, fa_history(uv) gives the picture), so a trail or an echo starts again. `camera`: the Entity::bits() of
    // one camera; 0 = every camera. A game calls it at a camera cut or a scene change the renderer cannot see. Main
    // thread; nothing happens without a renderer.
    void reset_post_history(std::uint64_t camera = 0);

    struct Impl;

private:
    friend struct RendererTestAccess;    // tests (src/renderer_test_access.h)
    friend struct RendererDeviceAccess;  // the renderer's GPU device for fa_render's own code (src/render_internal.h)
    std::unique_ptr<Impl> impl_;
    std::unique_ptr<Compute> compute_;  // storage buffers and dispatches of compute materials (fa/render/compute.h)
    std::vector<std::string> fallbackFonts_;
    RichTextStyle richStyle_;
    float textScale_ = 1.0f;
    float uiScale_ = 1.0f;
    ShaderCompiler shaderCompiler_;
};

}  // namespace fa
