// Where a UI widget (Panel, Button, Toggle, Slider, TextField, ScrollList) is on the screen: the ONE definition behind
// layout, hit-testing, clipping (fa_ui), drawing (fa_render) and editor picking (bounds.h). Screen space: design pixels,
// origin top-left, +Y down. ponytail: rotation and scale of UI entities are ignored; only the world translation counts.
#pragma once

#include <optional>
#include <utility>

#include "fa/core/math.h"
#include "fa/scene/components.h"
#include "fa/scene/world.h"

namespace fa {

enum class UiKind : std::int32_t { None, Panel, Button, Toggle, Slider, TextField, ScrollList };
const char* ui_kind_name(UiKind k);  // "Panel", "Button"... ("" for None)

// The widget component of `e` (the first of Panel, Button, Toggle, Slider, TextField, ScrollList), None if it has none.
UiKind ui_kind(const World& w, Entity e);
// Its shared geometry and background, nullptr if `e` is no widget.
const UiBox* ui_box(const World& w, Entity e);
// Button, Toggle, Slider and TextField can be focused, hovered and clicked; Panel and ScrollList cannot.
inline bool ui_is_control(UiKind k) { return k == UiKind::Button || k == UiKind::Toggle || k == UiKind::Slider || k == UiKind::TextField; }

// The widget's rectangle: x, y = top-left, +Y down, from the world translation T of the entity:
//   {T.x + anchor.x * W - pivot.x * size.x,  T.y + anchor.y * H - (1 - pivot.y) * size.y,  size.x, size.y}
// with designSize = {W, H} (the renderer's target size). nullopt when `e` is no widget.
std::optional<Rect> ui_rect(const World& w, Entity e, Vec2 designSize);

// The intersection of the rectangles of every ScrollList ANCESTOR of `e` (not `e` itself): what is drawn and hit-tested
// of `e`. nullopt when it has none. The result may be empty (w or h <= 0) when the rectangles do not overlap.
std::optional<Rect> ui_clip_rect(const World& w, Entity e, Vec2 designSize);

// Intersection of two rectangles; w and h are 0 when they do not overlap.
Rect ui_intersect(const Rect& a, const Rect& b);

// Horizontal extent {left, right} of a Slider's track inside its rectangle `r`: after an 8 px margin the label takes 35% of
// the rest (when not empty), the track the next 50% (85% without a label) and the value text the last 15%. Both the
// drawing and the mouse use it, so the knob is always under the pointer.
std::pair<float, float> ui_slider_track(const Slider& s, const Rect& r);

}  // namespace fa
