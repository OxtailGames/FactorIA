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
//     = top-right corner of the item 20px inside the screen corner; with Expand the target grows so HUDs stay on the edges.
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
#include "fa/scene/rich_text.h"
#include "fa/scene/text_fit.h"
#include "fa/scene/world.h"

namespace fa {

class Renderer;
class Compute;
namespace render {
class Gpu;
class FrameGraph;
// Test accessors. A test that has to look inside the renderer (its GPU objects, the frame graph of the last frame, the
// counts of its pools) does it through a free function declared here and made a friend of Renderer, not by opening
// Impl up: the tests of a game's code see nothing of the renderer's private headers, and the accessors are not part of
// the API reference. A new one is for a test only; engine code never calls one.
Gpu* renderer_gpu(
    Renderer& r);  // the renderer's GPU objects, for the render tests (engine/render/src/render_internal.h)
// The frame graph of the last frame the renderer drew (engine/render/src/frame_graph.h; every job of the frame is in
// it, its passes named "<job>/<pass>"), for the render tests; null before init.
const FrameGraph* renderer_frame_graph(Renderer& r);
// The targets the frame graph's transients are made of (target_pool.h's TargetPoolStats), for the render tests.
struct TransientPoolStats {
    int live = 0, inUse = 0, created = 0, reused = 0, destroyed = 0;
};
TransientPoolStats renderer_transient_stats(Renderer& r);
// The ring of images that hold the shadow rows of the 2D lights: how many it holds now and how many images were made
// since the renderer was, for the render tests.
struct ShadowRowsStats {
    int slots = 0, uploads = 0;
};
ShadowRowsStats renderer_shadow_rows_stats(Renderer& r);
// Draws the depth and normal prepass as if the camera's stack switched on the effects of `effects` (a mask like PostStack::mask, bit i =
// PostEffect(i); 0 = as the stack says), for the tests of the prepass: no effect that reads it is drawn yet.
void renderer_force_post_effects(Renderer& r, std::uint32_t effects);
// The HDR output: the next frames are drawn and presented as if update_output() had answered `info` (null: back to what it
// answers), for the render tests of the encodes without an HDR display.
void renderer_force_output(Renderer& r, const HdrOutputInfo* info);
// The last frame's finished picture as floats (RGBA, top row first): as the final target holds it (`present` false), or
// through present()'s encode for the output (scRGB, PQ, EDR or sRGB values). False with `error` where the GPU cannot draw or
// read back an RGBA16F image.
bool renderer_read_floats(Renderer& r, bool present, std::vector<float>& out, std::string* error);
}  // namespace render

// What the renderer shows instead of the game picture, to check the depth and normal prepass and the ambient occlusion
// (Renderer::set_debug_view). Ao paints the occlusion as a grey over the picture, drawn with the camera's own settings or the defaults.
enum class DebugView : std::uint8_t { None, Depth, Normals, Ao };

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
// MeshRenderer's surface (the default), Sprite = the 2D quad path (Sprite, Shape2D, Tilemap, Text, particles, UI images),
// Sky, Post = a pass of the post-processing stack, Compute. Each kind has its own template files and its own template hash.
enum class MaterialKind { Mesh, Sprite, Sky, Post, Compute };
// "mesh", "sprite", "sky", "post", "compute", in the order of MaterialKind.
const std::vector<std::string>& material_kind_names();
const char* material_kind_name(MaterialKind kind);
std::optional<MaterialKind> material_kind_from_name(std::string_view name);

// SHA-256 of the template files of `kind` (engine/render/shaders/*_common.glsl, one list per kind in
// engine/render/CMakeLists.txt) this renderer was built with: a material twin made from another template is refused. The
// tooling writes the same value into every twin of that kind. "" for a kind without a template yet (Compute).
std::string material_template_hash(MaterialKind kind);
// material_template_hash(MaterialKind::Mesh).
std::string mesh_template_hash();

struct RendererDesc {
    int designWidth = 1280;
    int designHeight = 720;
    int sampleCount = 1;    // MSAA of the game target (1 = off)
    bool headless = false;  // no swapchain; present() must not be called
    // The graphics context was opened before the renderer by Renderer::open_context (the player does, so it can present its
    // first frame before it reads any game file): init() uses it instead of calling sg_setup(), and shutdown() closes it.
    // Ignored (a normal init) when no context is open.
    bool adoptContext = false;
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
    int triangles = 0;
    int shadowCasters =
        0;          // MeshRenderer entities drawn into the shadow map (castShadows, inside the shadow light's volume)
    int views = 0;  // CameraViews drawn this frame (each one renders its camera into an image first)
    int renderTargets =
        0;  // cameras with Camera.renderTarget drawn into their texture this frame (before the cameras that show them)
    int lights = 0;           // 3D lights sent to the shader (at most 32); Light2D is counted in lights2d
    int lightsDropped = 0;    // 3D lights over the limit that were left out (the least relevant ones)
    int lights2d = 0;         // Light2D lights shading the 2D visuals (at most 256)
    int lights2dDropped = 0;  // Light2D lights left out: off-view ones, then the ones over the 256 of the budget
    int lights2dShadowed =
        0;  // of lights2d, the point lights whose castShadows is in effect (a Tilemap with occludesLight; at most 32)
    int materials = 0;  // distinct custom materials (MeshRenderer or Sprite material) drawn with their own shaders
    std::vector<std::string>
        materialFallbacks;  // materials drawn as the magenta error material (mesh) or magenta quads (sprite) because they failed to build (see asset_report); a sky material that failed (or is not a sky one) draws the built-in sky gradient instead, not magenta
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

    // Calls sg_setup() with `env` (unless desc.adoptContext and a context is open). Returns false + message on failure.
    bool init(const RendererDesc& desc, const GfxEnvironment& env, std::string* error);
    void shutdown();
    bool initialized() const;

    // --- Start-up (docs/PERFORMANCE.md, "Startup"; docs/design/ARCHITECTURE_RENDERING.md "Start-up order and the shader cache") ----------------------------------
    // A window player opens the graphics context FIRST (open_context), presents one cleared frame (present_clear) and only
    // then starts the engine, which reads the game's files and makes the renderer (init with desc.adoptContext). Nothing here
    // changes what a game draws: the first game frame is the same whether or not these ran.
    // sg_setup() with the same limits init() uses. False + message when the device is not usable. False when a context is open.
    static bool open_context(const GfxEnvironment& env, std::string* error);
    static bool context_open();
    // sg_shutdown() when a context is open and no renderer owns it (a start that failed before the renderer existed). A
    // renderer that adopted the context closes it in shutdown().
    static void close_context();
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
    // pipelinesMade, pipelinesEvicted, warmMs, groupsLeft}: what the start-up spent on shader programs and pipelines
    // (the `loading.startup.gpu` object of play.report).
    Json startup_report() const;

    // Resize the game target (e.g. Expand scale mode, editor viewport).
    void set_target_size(int width, int height);
    // Render scale: the game target's GPU images are target size * scale (1.5 on 1280x720 = 1920x1080) while layouts,
    // cameras, the HUD and the visible area stay in design units, so the frame is the same, drawn sharper (like a
    // fullscreen window). capture() returns the scaled image. Clamped to kMinRenderScale..kMaxRenderScale (NaN = 1).
    // Recreates the targets: draw again before capturing.
    static constexpr float kMinRenderScale = 0.25f;
    static constexpr float kMaxRenderScale = 4.0f;
    void set_render_scale(float scale);
    // The graphics backend in use: "metal", "d3d11", "glcore", "gles3", "dummy", or "unknown" for a sokol backend the
    // engine never builds (what game.device.gpuBackend reports).
    static const char* backend_name();
    // The compute side of the renderer (storage buffers, dispatches of "kind": "compute" materials; available() says whether
    // this backend can). Usable once init() succeeded; its buffers end with shutdown().
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

    // Native handle of the picture the editor viewport shows (sg_image id) and a texture view of it for sampling (sg_view id): the
    // finished game image (after the colour filter) in a gamma scene. In a linear scene that image holds linear light, which would be
    // too dark on screen: once set_editor_view(true) was called these are an 8-bit copy encoded to sRGB, made after each frame and
    // freed when the scene goes back to gamma (0 until the first frame of a linear scene made it). The same copy clamps a picture
    // above paper white (an HDR output's final pass) to the standard range. Without set_editor_view they are the game image as it is.
    std::uint32_t game_target_image_id() const;
    std::uint32_t game_target_view_id() const;
    // Asks for the encoded copy above (the editor calls it once). Costs one full-screen copy per frame of a linear scene, so a game
    // never asks. false frees the copy.
    void set_editor_view(bool on);
    // True when the game target holds colours above white (a 16-bit float format): MeshRenderer.emissiveStrength above 1 then
    // reaches Camera.bloom with its full strength. False on a GPU that cannot render to RGBA16F with blending, filtering and the
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
    Json asset_report() const;            // loaded assets + failures (missing files with hints)
    std::uint64_t texture_bytes() const;  // GPU memory of the loaded textures

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

    // Whether this renderer can do `feature` on the backend and GPU it runs on: a capability of the GPU ("floatTargets",
    // "r11g11b10", "sampledDepth", "computeShaders"), an engine feature ("linearColor", "hdrOutput") or a post effect (the
    // names of kPostEffectOrder: "bloom", "tonemap", ...). False for a name that is not in feature_names(), before init(), on the
    // headless (dummy) backend, and for what the engine does not draw (no effect is left out today;
    // linearColor is drawn on every GPU): it never claims what the renderer cannot do. "hdrOutput" is true when the display
    // the window showed its last frame on can show HDR in an encoding the renderer writes (EDR on Metal, scRGB or HDR10 on
    // D3D11), whatever the scene's hdrOutput setting. `render.supports` answers the same with the reason.
    bool supports(std::string_view feature) const;
    // Every name supports() knows, in a fixed order.
    static std::vector<std::string> feature_names();
    // The answer of the `render.supports` command: {backend, backendLabel, features: [{name, kind, supported, status, doc,
    // backends}]}. Empty object before init().
    Json supports_report() const;

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
    // stack (no PostProcess, no deprecated Camera.bloom* or colorFilter), without touching any data; false (the default) draws
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

    struct Impl;

private:
    friend render::Gpu* render::renderer_gpu(Renderer& r);
    friend void render::renderer_force_post_effects(Renderer& r, std::uint32_t effects);
    friend const render::FrameGraph* render::renderer_frame_graph(Renderer& r);
    friend render::TransientPoolStats render::renderer_transient_stats(Renderer& r);
    friend render::ShadowRowsStats render::renderer_shadow_rows_stats(Renderer& r);
    friend void render::renderer_force_output(Renderer& r, const HdrOutputInfo* info);
    friend bool render::renderer_read_floats(Renderer& r, bool present, std::vector<float>& out, std::string* error);
    std::unique_ptr<Impl> impl_;
    std::unique_ptr<Compute> compute_;  // storage buffers and dispatches of compute materials (fa/render/compute.h)
    std::vector<std::string> fallbackFonts_;
    RichTextStyle richStyle_;
    float textScale_ = 1.0f;
    float uiScale_ = 1.0f;
    ShaderCompiler shaderCompiler_;
};

}  // namespace fa
