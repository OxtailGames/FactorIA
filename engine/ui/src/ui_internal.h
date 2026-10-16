// Private helpers shared by layout.cpp and ui.cpp.
#pragma once

#include <optional>

#include "fa/ui/ui.h"

namespace fa::ui_detail {

// The UiControl part of a Button / Toggle / Slider / TextField (nullptr for anything else).
inline UiControl* control_of(World& w, Entity e) {
    if (Button* b = w.get<Button>(e)) return b;
    if (Toggle* t = w.get<Toggle>(e)) return t;
    if (Slider* s = w.get<Slider>(e)) return s;
    if (TextField* f = w.get<TextField>(e)) return f;
    return nullptr;
}
inline const UiControl* control_of(const World& w, Entity e) { return control_of(const_cast<World&>(w), e); }

// Where an entity is on the screen for layout: a widget's rectangle, else the box around its screen-space Text / Sprite /
// Shape2D footprints (text measured through `measure`). nullopt for an entity with neither.
std::optional<Rect> screen_rect(const World& w, Entity e, Vec2 designSize, const VisualMeasure& measure);

}  // namespace fa::ui_detail
