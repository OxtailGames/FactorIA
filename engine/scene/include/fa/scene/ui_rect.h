// Where a UI widget (Panel, Button, Toggle, Slider, TextField, ScrollList) is on the screen: the ONE definition behind
// layout, hit-testing, clipping (fa_ui), drawing (fa_render) and editor picking (bounds.h). Screen space: design pixels,
// origin top-left, +Y down. ponytail: rotation and scale of UI entities are ignored; only the world translation counts.
#pragma once

#include <optional>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

#include "fa/core/math.h"
#include "fa/scene/components.h"
#include "fa/scene/world.h"

namespace fa {

enum class UiKind : std::int32_t { None, Panel, Button, Toggle, Slider, TextField, ScrollList, TouchStick, TouchButton, Captions };
const char* ui_kind_name(UiKind k);  // "Panel", "Button"... ("" for None)

// The widget component of `e` (the first of Button, Toggle, Slider, TextField, ScrollList, Panel, TouchStick,
// TouchButton, Captions), None if it has none.
UiKind ui_kind(const World& w, Entity e);
// Its shared geometry and background, nullptr if `e` is no widget.
const UiBox* ui_box(const World& w, Entity e);
// Button, Toggle, Slider and TextField can be focused, hovered and clicked; Panel and ScrollList cannot.
inline bool ui_is_control(UiKind k) { return k == UiKind::Button || k == UiKind::Toggle || k == UiKind::Slider || k == UiKind::TextField; }
// The interactive part (font, colours, focused / hovered / pressed) of such a widget; nullptr for any other entity.
const UiControl* ui_control(const World& w, Entity e);

// The screen point an anchor names, in design pixels: {anchor.x * W, anchor.y * H} with designSize = {W, H}, or, when
// `safeArea` is true, the same fractions of the safe rectangle (the screen minus `insets`): anchor [0, 0] is its top-left
// corner, [1, 1] its bottom-right. The ONE definition behind drawing, layout, hit-testing and editor picking.
Vec2 anchor_point(Vec2 anchor, bool safeArea, Vec2 designSize, const EdgeInsets& insets);

// A "device profile" for tests and AI agents: the insets of a typical notched phone, as fractions of the design size.
// Names: "none", "phone-portrait" (notch at the top, home indicator at the bottom), "phone-landscape" (notch on a side,
// home indicator at the bottom). false (out alone) for any other name.
bool safe_area_profile(std::string_view name, Vec2 designSize, EdgeInsets& out);
const std::vector<std::string>& safe_area_profile_names();

// The widget's rectangle: x, y = top-left, +Y down, from the world translation T of the entity:
//   {T.x + A.x - pivot.x * size.x,  T.y + A.y - (1 - pivot.y) * size.y,  size.x, size.y}
// with A = anchor_point(anchor, safeArea, designSize, w.safe_insets()) and designSize = {W, H} (the renderer's target
// size). nullopt when `e` is no widget.
std::optional<Rect> ui_rect(const World& w, Entity e, Vec2 designSize);

// The intersection of the rectangles of every ScrollList ANCESTOR of `e` (not `e` itself): what is drawn and hit-tested
// of `e`. nullopt when it has none. The result may be empty (w or h <= 0) when the rectangles do not overlap.
std::optional<Rect> ui_clip_rect(const World& w, Entity e, Vec2 designSize);

// Intersection of two rectangles; w and h are 0 when they do not overlap.
Rect ui_intersect(const Rect& a, const Rect& b);

// Horizontal extent {left, right} of a Slider's track inside its rectangle `r`: after an 8 px margin the label takes 35% of
// the rest (when not empty), the track the next 50% (85% without a label) and the value text the last 15%. Both the
// drawing and the mouse use it, so the knob is always under the pointer.
// With Slider.labelAbove (and a label) the label does not take the 35%: the track gets the 85% of an unlabelled slider.
std::pair<float, float> ui_slider_track(const Slider& s, const Rect& r);

// True when the Slider's label is drawn above the track (labelAbove and a non-empty label).
inline bool ui_slider_label_above(const Slider& s) { return s.labelAbove && !s.label.empty(); }
// Height of the row with the track, knob and value when the label is above; the label gets the rest on top.
constexpr float kUiSliderRowHeight = 28.0f;
// Vertical middle of the track / knob / value row inside the Slider's rectangle `r`: the middle of r, or of its bottom
// kUiSliderRowHeight pixels when the label is above.
float ui_slider_mid_y(const Slider& s, const Rect& r);

// The text a Slider draws at its right for `value`: "60%" for a 0..1 range, else the number with up to two decimals.
std::string ui_slider_value_text(const Slider& s, float value);

}  // namespace fa
