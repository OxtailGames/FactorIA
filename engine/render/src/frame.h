// Per-frame CPU state shared by the gather passes (2D, particles, debug, 3D).
#pragma once

#include "fa/scene/text_fit.h"
#include "render_internal.h"

namespace fa::render {

// The shadow rows computed for lights, kept while a light, its radius and the solid tiles around it stay the same: a light
// that does not move casts the same shadow every frame, so only a moving or newly lit one pays for its rays (light2d.cpp).
// The key is a hash of everything a row is computed from.
struct ShadowCache {
    struct Entry {
        std::vector<std::uint8_t> row;  // kShadowAngles RGBA8 texels
        std::uint64_t used = 0;         // the tick of the last frame that read it
    };
    std::unordered_map<std::uint64_t, Entry> rows;
    std::uint64_t tick = 0;  // one per drawn frame (the renderer counts it): a row not used this frame may be dropped
};

struct Frame {
    CameraInfo cam;
    // What this frame gathers: one camera's world (a view into its viewport) and/or the screen-space items drawn once over the
    // whole screen after every camera (Sprite/Shape2D/Text/ParticleEmitter with space "screen", UI, debug text). A game with
    // one camera and the whole screen as its viewport gathers both in one frame.
    bool wantWorld = true, wantScreen = true;
    int targetW = 0, targetH = 0;
    float dt = 0;
    QuadList world, screen, debugWorld, debugScreen;
    std::vector<Vertex2D> debugLines;  // GL line list (perspective cameras)
    RenderStats* stats = nullptr;
    Assets* assets = nullptr;
    Fonts* fonts = nullptr;
    float renderScale = 1.0f;  // Renderer::set_render_scale: glyphs are rasterized this many times larger (sharp text)
    float textScale = 1.0f;  // Renderer::set_text_scale: multiplies the font size of screen-space Text and UI labels
    float uiScale = 1.0f;    // World::ui_scale() of this frame: screen-space UI is drawn this many times as big (ui_rect.h)
    bool white_used = false;
    // Lit 2D visuals (Sprite.lit, Tilemap.lit): the lights of this frame (gather_2d) and the base light.
    std::vector<Light2DData> lights2d;
    Color ambient2d{0.25f, 0.25f, 0.3f, 1.0f};
    bool* warnedLights2d = nullptr;  // set once gather_2d warned that more than kMaxLights2D lights are in view (per scene)
    bool* warnedShadows2d = nullptr; // set once gather_2d warned that more than kMaxShadowLights2D lights cast shadows (per scene)
    // The shadow rows of the point lights with castShadows (light2d.cpp): shadowRows rows of kShadowAngles RGBA8 texels,
    // row r for the light whose Light2DData::extra[0] is r. Empty when no light casts a shadow this frame.
    std::vector<std::uint8_t> shadowData;
    int shadowRows = 0;
    std::uint64_t shadowKey = 0;     // identifies the content of shadowData: equal keys, equal bytes (0 = no rows)
    ShadowCache* shadowCache = nullptr;  // the renderer's rows kept across frames; null = none kept
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

// Draws a text layout (text_draw.cpp): all its glyphs as one item of the glyph atlas whatever their colours and weights
// (`color` is the text's; a run colour of a rich text replaces its RGB and keeps its alpha), then the pictures of a rich text,
// one item per texture. `m` places the layout's local units (y up; `screen` flips y as QuadEmitter does).
// `visible` >= 0 draws only the glyphs and pictures of the first `visible` grapheme clusters (Text.visibleCharacters): the layout
// is the whole text's, so nothing moves while a line reveals. Returns the number of glyphs drawn (pictures not counted).
int emit_text(QuadList& list, const Mat4& m, bool screen, const TextLayout& lay, Color color, Fonts& fonts, Assets& assets, int layer,
              float secondary, const Rect& clip, int visible = -1);

// advance = true steps SpriteAnimator time by f.dt; false only (re)applies the current frame to
// Sprite.region (idempotent, used by the draw pass).
void update_animators(World& world, Frame& f, bool advance);
// Writes Parallax.offset of every Parallax component for a camera at `camPos` (world xy). Called by Renderer::update and
// at the start of gather_2d, so entity.bounds() is right in headless runs too.
void update_parallax(World& world, Vec2 camPos);
void gather_2d(World& world, Frame& f);
// Gives the point lights of f.lights2d that ask for shadows (extra[1]) a row of f.shadowData when a Tilemap with
// occludesLight is in the scene, at most kMaxShadowLights2D (the ones ranked first); sets extra[0] to the row and counts
// them in the stats. light2d.cpp.
void assign_shadow_rows(World& world, Frame& f);
// Panel, Button, Toggle, Slider, TextField and ScrollList (ui2d.cpp): screen space, after gather_2d.
void gather_ui(World& world, Frame& f);
// The scissor rectangle of a screen-space item of entity `e`: the ScrollLists around it (`clip` stays empty, w = 0,
// when there are none). False when they clip it away entirely, so there is nothing to draw.
bool screen_clip(const World& world, Entity e, const Frame& f, Rect& clip);

// The renderer's text layout as a TextExtent for fit_text (text_fit.h): size of text at a final font size `px`, so a fit
// decided here is the one `Renderer::measure_text(Text)` and `ui.overflowed` decide.
// `ppu`: the raster size per unit the text is drawn at, relative to 1 (screen-space text: f.uiScale; world-space: 1).
TextExtent frame_text_extent(Frame& f, float ppu = 1.0f);
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
