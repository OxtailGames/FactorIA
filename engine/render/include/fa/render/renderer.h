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

#include <functional>
#include <memory>
#include <string>
#include <string_view>
#include <vector>

#include "fa/core/image.h"
#include "fa/core/json.h"
#include "fa/core/math.h"
#include "fa/platform/app.h"
#include "fa/scene/world.h"

namespace fa {

class Renderer;
namespace render {
class Gpu;
Gpu* renderer_gpu(Renderer& r);  // the renderer's GPU objects, for the render tests (engine/render/src/render_internal.h)
}  // namespace render

enum class ScaleMode : std::int32_t {
    Fit,      // keep aspect, letterbox (default)
    Stretch,  // fill the window, distort
    Expand,   // keep aspect, grow the visible area on the long axis (game target resized to match)
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

// SHA-256 of the mesh template files (engine/render/shaders/*_common.glsl) this renderer was built with: a material twin
// made from another template is refused. The tooling writes the same value into every twin.
std::string mesh_template_hash();

struct RendererDesc {
    int designWidth = 1280;
    int designHeight = 720;
    int sampleCount = 1;       // MSAA of the game target (1 = off)
    bool headless = false;     // no swapchain; present() must not be called
};

struct RenderStats {
    int drawCalls = 0;
    int sprites = 0;
    int shapes = 0;
    int textGlyphs = 0;
    int particles = 0;
    int meshes = 0;          // MeshRenderer entities drawn in the main pass (instances)
    int meshesCulled = 0;    // MeshRenderer entities outside the camera frustum: not drawn in the main pass
    int meshBatches = 0;     // instanced batches drawn (meshes with the same mesh, textures and material values share one)
    int triangles = 0;
    int lights = 0;          // lights sent to the shader (at most 32)
    int lightsDropped = 0;   // lights over the limit that were left out (the least relevant ones)
    int materials = 0;       // distinct custom materials (MeshRenderer.material) drawn with their own shaders
    std::vector<std::string> materialFallbacks;  // materials drawn with the unlit magenta error material because they failed to build (see asset_report)
    double cpuMs = 0.0;
    Json to_json() const;
};

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

class Renderer {
public:
    Renderer();
    ~Renderer();
    Renderer(const Renderer&) = delete;
    Renderer& operator=(const Renderer&) = delete;

    // Calls sg_setup() with `env`. Returns false + message on failure.
    bool init(const RendererDesc& desc, const GfxEnvironment& env, std::string* error);
    void shutdown();
    bool initialized() const;

    // Resize the game target (e.g. Expand scale mode, editor viewport).
    void set_target_size(int width, int height);
    // Render scale: the game target's GPU images are target size * scale (1.5 on 1280x720 = 1920x1080) while layouts,
    // cameras, the HUD and the visible area stay in design units, so the frame is the same, drawn sharper (like a
    // fullscreen window). capture() returns the scaled image. Clamped to kMinRenderScale..kMaxRenderScale (NaN = 1).
    // Recreates the targets: draw again before capturing.
    static constexpr float kMinRenderScale = 0.25f;
    static constexpr float kMaxRenderScale = 4.0f;
    void set_render_scale(float scale);
    int target_width() const;
    int target_height() const;

    void begin_frame();
    // Call after an sg_commit() the renderer did not do itself (the editor commits once per UI frame): the next
    // begin_frame() may then reuse the frame's transient vertex buffers. Without it extra draws get fresh buffers.
    void note_commit();

    // --- Simulation / drawing split --------------------------------------------------------------
    // update() advances everything time-based that lives in the renderer: SpriteAnimator frames and
    // ParticleEmitter simulation (spawning, integration, autoDestroy -> world.destroy). It never draws and
    // needs no begin_frame(). render_world() only DRAWS the current state: the image depends solely on the
    // world + renderer state, so skipping render_world() on some frames (headless fast-forward) yields the
    // same image as drawing every frame, provided update() ran every frame.
    // Contract: call update(world, dt) once per simulated frame, then optionally render_world(). Code that
    // only calls render_world(world, dt) keeps working: if update() was not called since the previous draw,
    // render_world() calls it with `dt` itself.
    void update(World& world, float dt);
    // Draws the world (cameras, sprites, shapes, tilemaps, text, particles, meshes, lights, debug draw).
    void render_world(World& world, float dt);

    // Immediately spawns `count` particles at the ParticleEmitter on `e` (works with emitting = false; the
    // particles appear in the next draw, positioned at the emitter's transform). Safe to call before the
    // emitter's first update. No-op when the entity has no (active) ParticleEmitter.
    void emit_burst(Entity e, int count);

    // Size {width, height} in design/world units of `text` laid out at `fontSize` with the same code as Text
    // rendering (shaping, fallback fonts, right-to-left text, wrapping at maxWidth > 0, line height). font "" =
    // built-in font. `space` is where the text would be drawn: screen-space Text and UI labels (RenderSpace::Screen)
    // are scaled by the text scale, world-space Text is not.
    Vec2 measure_text(std::string_view text, float fontSize, std::string_view font = {}, float maxWidth = 0,
                      RenderSpace space = RenderSpace::World) const;
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
    // The player's "text size" option: multiplies the font size of screen-space Text (space = Screen) and of the labels
    // of UI widgets (Button, Toggle, Slider, TextField), and the measurements of those (measure_text with
    // RenderSpace::Screen, entity.bounds()). World-space Text is part of the world and is not scaled; neither is debug
    // text. Clamped to kMinTextScale..kMaxTextScale (NaN = 1). The renderer does not save it: the game stores the option.
    // May be called before init().
    void set_text_scale(float scale);
    float text_scale() const { return textScale_; }

    // Expand support: with ScaleMode::Expand the orthographic camera keeps the design height fixed (or the
    // design width when the target is taller than the design aspect). present() also records its mode.
    void set_scale_mode(ScaleMode mode);
    void end_frame();
    // Windowed: blit the game target into the swapchain with the scale mode.
    void present(const GfxSwapchain& swapchain, int framebufferWidth, int framebufferHeight, ScaleMode mode);
    // Letterbox mapping used by present(): framebuffer pixel -> design pixel.
    Vec2 framebuffer_to_design(Vec2 fbPos, int framebufferWidth, int framebufferHeight, ScaleMode mode) const;

    // Read back the last finished game target (RGBA8, top row first).
    bool capture(Image& out, std::string* error = nullptr);

    // Camera helpers for the current world/primary camera (valid after render_world).
    Vec2 world_to_screen(Vec3 worldPos) const;     // design pixels, top-left origin
    Vec3 screen_to_world(Vec2 screenPos, float depth = 0.0f) const;  // 2D: z = depth; 3D: point on ray at distance depth
    void screen_ray(Vec2 screenPos, Vec3& origin, Vec3& dir) const;

    DebugDraw& debug();
    RenderStats stats() const;  // of the last frame

    // Native handle of the game target color image (sg_image id) for the editor viewport.
    std::uint32_t game_target_image_id() const;
    std::uint32_t game_target_view_id() const;  // texture view (sg_view id) for sampling

    // Asset cache control (textures, meshes, fonts are loaded on first use by path).
    void reload_asset(std::string_view path);  // hot reload (a .material.json, or a snippet a material uses, rebuilds it)
    // Custom materials (MeshRenderer.material): how a material without a twin is compiled. Empty = read twins only.
    void set_shader_compiler(ShaderCompiler compiler);
    // The shader dialect of this renderer's backend (see ShaderCompiler); "" before init().
    std::string shader_dialect() const;
    void clear_asset_cache();
    Json asset_report() const;  // loaded assets + failures (missing files with hints)
    std::uint64_t texture_bytes() const;  // GPU memory of the loaded textures

    // GPU time of drawing the world. While the profiler is on (fa/core/profiler.h; docs/PERFORMANCE.md) every drawn frame is
    // timed with a timer query where the backend has them (D3D11, desktop OpenGL); the answers arrive a few frames late and
    // are never waited for. take_gpu_ms() appends the milliseconds of the frames whose answer is ready. When
    // gpu_timing_supported() is false `reason` says why (Metal, GLES3 and WebGL2 have no timer queries here).
    // Measurement only: not part of the simulation.
    bool gpu_timing_supported(std::string* reason = nullptr) const;
    void take_gpu_ms(std::vector<double>& out);

    struct Impl;

private:
    friend render::Gpu* render::renderer_gpu(Renderer& r);
    std::unique_ptr<Impl> impl_;
    std::vector<std::string> fallbackFonts_;
    float textScale_ = 1.0f;
    ShaderCompiler shaderCompiler_;
};

}  // namespace fa
