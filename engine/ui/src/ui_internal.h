// Private helpers shared by layout.cpp and ui.cpp.
#pragma once

#include <array>
#include <functional>
#include <optional>
#include <vector>

#include "fa/ui/ui.h"

namespace fa::ui_detail {

// The UiControl part of a Button / Toggle / Slider / TextField (nullptr for anything else).
inline UiControl* control_of(World& w, Entity e) { return const_cast<UiControl*>(ui_control(w, e)); }
inline const UiControl* control_of(const World& w, Entity e) { return ui_control(w, e); }

// Number of ancestors of `e`.
inline int depth_of(const World& w, Entity e) {
    int d = 0;
    for (Entity p = w.parent(e); p; p = w.parent(p)) ++d;
    return d;
}

// Where an entity is on the screen for layout: a widget's rectangle, else the box around its screen-space Text / Sprite /
// Shape2D footprints (text measured through `measure`). nullopt for an entity with neither.
std::optional<Rect> screen_rect(const World& w, Entity e, Vec2 designSize, const VisualMeasure& measure);


// A widget the keyboard, the pad and the pointer can act on: a Button / Toggle / Slider / TextField (kind != None), or an
// Interactable (custom). Rectangles are in screen pixels.
struct Item {
    Entity e;
    UiKind kind = UiKind::None;
    Rect rect;             // custom: the bounding box of `quad`
    int layer = 0;
    bool interactable = true;
    bool inScope = true;   // false: outside the modal Panel that scopes the input (listed as not interactable)
    // Interactable only:
    bool custom = false;
    bool world = false;    // projected through a camera (else in screen space, like a built-in widget)
    std::array<Vec2, 4> quad{};   // the hit area on the screen, a convex quad
    Vec2 trackA{}, trackB{};      // slider: the screen points of the minimum and the maximum end of the track
};

using ProjectFn = UiProjectFn;

// The Interactable entities (active, not also a built-in widget), as items. `modal` scopes them like controls() does. `project` is
// the camera hook (empty: the orthographic maths of the scene's cameras). `pointer`: the pointer position, for the camera choice.
std::vector<Item> interactable_items(const World& w, Vec2 design, const VisualMeasure& measure, Entity modal, const ProjectFn& project,
                                     const Vec2* pointer);
bool item_contains(const Item& it, Vec2 p);

// True when `e` is an Interactable that is not a built-in widget as well (then the built-in wins).
bool is_custom(const World& w, Entity e);

// The value of an Interactable slider for the pointer at `p`: the fraction of the track the pointer's projection onto it covers.
float track_fraction(const Item& it, Vec2 p);

// Snaps `v` into [lo, max(lo, hi)] on the grid `step` from lo (0 = no grid), like a Slider.
float snap_value(float v, float lo, float hi, float step);

}  // namespace fa::ui_detail
