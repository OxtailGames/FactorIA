// Renderer: draws a World (2D + 3D) into an offscreen "game target" at the
// design resolution, then (windowed only) presents it letterboxed to the
// window. Because the game always renders offscreen, screenshots, golden
// tests, the editor viewport and headless runs all see exactly the same image.
//
// Frame:
//   renderer.begin_frame();
//   renderer.render_world(world, dt);   // cameras, sprites, shapes, tilemaps, text,
//                                       // particles, meshes, lights, debug draw
//   renderer.end_frame();               // finishes the offscreen pass
//   renderer.present(swapchain, fbW, fbH);  // windowed only; editor skips this
//   sg_commit() is done by end_frame()/present() as appropriate.
#pragma once

#include <memory>
#include <string>
#include <string_view>

#include "fa/core/image.h"
#include "fa/core/json.h"
#include "fa/core/math.h"
#include "fa/platform/app.h"
#include "fa/scene/world.h"

namespace fa {

enum class ScaleMode : std::int32_t {
    Fit,      // keep aspect, letterbox (default)
    Stretch,  // fill the window, distort
    Expand,   // keep aspect, grow the visible area on the long axis (game target resized to match)
    PixelPerfect  // integer scaling only, letterbox
};

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
    int meshes = 0;
    int triangles = 0;
    int lights = 0;
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
    int target_width() const;
    int target_height() const;

    void begin_frame();
    void render_world(World& world, float dt);
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
    void reload_asset(std::string_view path);  // hot reload
    void clear_asset_cache();
    Json asset_report() const;  // loaded assets + failures (missing files with hints)

    struct Impl;

private:
    std::unique_ptr<Impl> impl_;
};

}  // namespace fa
