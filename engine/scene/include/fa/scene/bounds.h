// Where the 2D visuals of an entity are and how big they are: the ONE definition behind `entity.bounds()` in scripts and
// behind the editor's picking and selection outline, so what a script measures is exactly what the editor outlines.
//
// The geometry follows what the renderer draws (render/scene2d.cpp):
//   * Tilemap  tilemap_size() x tileSize; the entity origin is the map's TOP-LEFT corner, local x right, local y DOWN. An
//              isometric map: the box around all its diamonds (tilemap_local_bounds), from the TOP corner of the map.
//   * Sprite   `size` (0 = the region, else the texture, else 32 x 32; a SpriteAnimator divides the texture into its
//              frames), placed by `pivot` (0,0 = bottom-left).
//   * Shape2D  the size box placed by `pivot`. A Circle is its bounding square of side size.x; a Line is the stroked
//              segment from the origin to `size`; a Diamond has its tips on the middles of the size box;
//              a Polygon or Star is measured by its size box too.
//   * Text     the laid-out text box placed by `pivot` (default 0,1 = top-left).
// Everything is a convex quad in the entity's LOCAL space (y up, before the world matrix: rotation, scale and parents
// are applied by the caller).
#pragma once

#include <array>
#include <cstdint>
#include <functional>
#include <optional>
#include <string>
#include <vector>

#include "fa/core/math.h"
#include "fa/scene/components.h"
#include "fa/scene/world.h"

namespace fa {

// What the scene module cannot know by itself (it has no files and no fonts). Both are optional.
struct VisualMeasure {
    // Pixel size of a texture file as the renderer sees it (32 x 32 for a missing or unreadable file). Empty: 32 x 32 for all.
    std::function<Vec2(const std::string& path)> textureSize;
    // Size {w, h} of `text` laid out like the renderer does, with the player's text size (ui.textScale), the Text's
    // maxTextScale cap and its autoShrink already applied (the renderer's Renderer::measure_text(Text), or
    // approx_text_size(Text, textScale) without a renderer). Empty: approx_text_size(). Screen-space text is measured in UI
    // UNITS (ui_rect.h): at the interface scale k it is drawn k times as big, so the measure is for fontSize, not fontSize * k.
    std::function<Vec2(const Text& text)> textSize;
    // The player's text size option (ui.textScale) at the moment of the measurement. UI code that fits labels itself
    // (text_fit.h) reads it; textSize already includes it for a Text.
    float textScale = 1.0f;
};

// Size of a text without a renderer (headless): 0.6 em per character and 1.2 em per line, wrapping at maxWidth (> 0).
// With `markup` (Text.markup) the tags are not characters and an icon counts as two.
Vec2 approx_text_size(const std::string& text, float fontSize, float maxWidth, bool markup = false);
// The same for a Text entity's component: screen-space text at the player's text size `textScale`, the maxTextScale cap and
// autoShrink applied (text_fit.h), so a headless run measures like a rendered one.
Vec2 approx_text_size(const Text& text, float textScale);

// One drawn thing of an entity.
struct VisualFootprint {
    const char* component = "";                  // "Tilemap", "Sprite", "Shape2D", "Text" or a UI widget ("Button", "Panel"...)
    RenderSpace space = RenderSpace::World;      // Screen: design pixels, origin top-left, local y flipped (see below)
    std::int32_t layer = 0;                      // the component's draw layer
    Vec2 anchor{0, 0};                           // Screen space only: the component's anchor (fraction of the design size)
    bool safeArea = false;                       // Screen space only: the anchor is relative to the safe area (anchor_point)
    // The drawn box in local space (y up), as 4 corners around the quad: what to outline and to hit-test. For a Diamond it is
    // the size box the tips touch; for a Line the stroked segment; for a Circle its bounding square.
    std::array<Vec2, 4> box{};
    // The points whose bounding rectangle in the world is the entity.bounds() rectangle. Equal to `box` except for a Diamond,
    // whose tips are the middles of the box edges (so a diamond turned by 45 degrees has a smaller rectangle than its box).
    std::array<Vec2, 4> hull{};
};

// Every visual of `e`, in the order Tilemap, Sprite, Shape2D, Text, UI widget (screen space, see ui_rect.h), screen-space ones included (`space`) unless
// `includeScreenSpace` is false. Empty when the entity draws nothing (an empty map, a zero-length line, empty text).
// `active` and colour alpha are ignored.
//
// Screen space: the renderer draws these with local y negated and the translation moved by the anchor point, so a
// point (lx, ly) of the box lands at world_matrix * (lx, -ly) + anchor_point(anchor, safeArea, designSize, insets)
// (ui_rect.h; plain anchor * designSize without safeArea). Callers that need that do it themselves. With an interface scale k
// (World::ui_scale()) the box and the matrix are in UI units: on the screen the point lands at
// k * world_matrix * (lx, -ly) + anchor_point(...), the anchor point not scaled (ui_layout_screen / ui_layout_insets give
// the same point in UI units, which is what layout uses).
std::vector<VisualFootprint> visual_footprints(const World& w, Entity e, const VisualMeasure& measure = {},
                                               bool includeScreenSpace = true);

// The world matrix the WORLD-SPACE visuals of `e` are drawn with: world_matrix(e) moved by Parallax.offset (the shift the
// renderer applied for the camera this frame; zero without a Parallax). Use it, not world_matrix, to place visual_footprints
// in the world. A Parallax with repeatX / repeatY is measured at its base copy.
Mat4 visual_world_matrix(const World& w, Entity e);

// The world-space axis-aligned rectangle (x, y = the minimum corner, +Y up) around the world-space visuals of `e`
// after the entity's world matrix (rotation, scale, parents). nullopt when there are none. Screen-space visuals are
// skipped. This is `entity.bounds()`.
std::optional<Rect> entity_world_rect(const World& w, Entity e, const VisualMeasure& measure = {});

// True when `p` lies inside the convex quad (either winding), borders included.
bool point_in_quad(Vec2 p, const std::array<Vec2, 4>& quad);

}  // namespace fa
