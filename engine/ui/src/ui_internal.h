// Private helpers shared by layout.cpp and ui.cpp.
#pragma once

#include <optional>

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

}  // namespace fa::ui_detail
