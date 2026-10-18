// Per-frame CPU state shared by the gather passes (2D, particles, debug, 3D).
#pragma once

#include "render_internal.h"

namespace fa::render {

struct Frame {
    CameraInfo cam;
    int targetW = 0, targetH = 0;
    float dt = 0;
    QuadList world, screen, debugWorld, debugScreen;
    std::vector<Vertex2D> debugLines;  // GL line list (perspective cameras)
    RenderStats* stats = nullptr;
    Assets* assets = nullptr;
    Fonts* fonts = nullptr;
    float textScale = 1.0f;  // Renderer::set_text_scale: multiplies the font size of screen-space Text and UI labels
    bool white_used = false;
    // Lit 2D visuals (Sprite.lit, Tilemap.lit): the lights of this frame (gather_2d) and the base light.
    std::vector<Light2DData> lights2d;
    Color ambient2d{0.25f, 0.25f, 0.3f, 1.0f};
};

// Emits the 4 vertices of an axis-aligned local rectangle (y up) transformed by `m`.
// flipY: local y is negated first (screen space is y down).
struct QuadEmitter {
    QuadList& list;
    Mat4 m;
    bool flipY = false;
    std::uint32_t color = 0xFFFFFFFFu;
    float mode = 0, aux = 0;

    Vec3 xf(float x, float y, float z = 0) const { return m.transform_point({x, flipY ? -y : y, z}); }
    // Local rectangle [x0,x1] x [y0,y1] with uv rect (u0,v0 = top-left).
    void rect(float x0, float y0, float x1, float y1, float u0, float v0, float u1, float v1) const;
    // The same rectangle with a uv per corner, in the order top-left, bottom-left, bottom-right, top-right (a turned tile).
    void rect_uv(float x0, float y0, float x1, float y1, const Vec2 (&uv)[4]) const;
};

// advance = true steps SpriteAnimator time by f.dt; false only (re)applies the current frame to
// Sprite.region (idempotent, used by the draw pass).
void update_animators(World& world, Frame& f, bool advance);
// Writes Parallax.offset of every Parallax component for a camera at `camPos` (world xy). Called by Renderer::update and
// at the start of gather_2d, so entity.bounds() is right in headless runs too.
void update_parallax(World& world, Vec2 camPos);
void gather_2d(World& world, Frame& f);
// Panel, Button, Toggle, Slider, TextField and ScrollList (ui2d.cpp): screen space, after gather_2d.
void gather_ui(World& world, Frame& f);
// The scissor rectangle of a screen-space item of entity `e`: the ScrollLists around it (`clip` stays empty, w = 0,
// when there are none). False when they clip it away entirely, so there is nothing to draw.
bool screen_clip(const World& world, Entity e, const Frame& f, Rect& clip);
// Particle simulation (no drawing): spawns the initial burst, continuous emission, queued emit_burst()
// requests, integrates, kills, and destroys finished autoDestroy emitters. `assets` is unused by the sim.
void update_particles(World& world, float dt);
// Queues `count` particles for the emitter on entity bits `e`; spawned by the next update/gather.
void queue_particle_burst(std::uint64_t entityBits, int count);
// Spawns queued bursts (dt = 0, no integration) so they are visible in the frame being drawn.
void flush_particle_bursts(World& world);
void gather_particles(World& world, Frame& f);  // draw only
void clear_particles();
void gather_debug(DebugDrawData& dd, Frame& f);

// Helpers
bool entity_active(const World& w, Entity e);
float matrix_scale_x(const Mat4& m);

}  // namespace fa::render
