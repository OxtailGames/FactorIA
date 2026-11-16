// Where a UI widget (Panel, Button, Toggle, Slider, TextField, ScrollList) is on the screen: the ONE definition behind
// layout, hit-testing, clipping (fa_ui), drawing (fa_render) and editor picking (bounds.h). Screen space: design pixels,
// origin top-left, +Y down.
//
// Rotation and scale (since 0.30.0): the Transform of a widget, and of every entity above it, rotates (rotation.z, degrees,
// positive = clockwise on the screen, the way a screen-space Text turns) and scales (scale.x, scale.y) what is drawn and hit
// around that entity's own origin: its position plus its anchor point, which is where its pivot sits. Three things follow:
//  * Space. Layout works in LAYOUT SPACE: the plane where every position is the sum of the local positions up the parents and no
//    rotation or scale is applied. ui_layout_rect is a widget's rectangle there, in its own frame (before its own rotation and
//    scale): what the widget draws into, what its own layout, Slider track and TextField caret use.
//  * What a parent's layout sees. The slot stays where it is when a child rotates (it turns in place around its pivot, like CSS
//    `transform`, Unity's RectTransform.rotation and Godot's Control.rotation); a child's scale grows or shrinks the slot
//    (ui_footprint_rect), so a row makes room for a child at scale 2 (CSS `zoom`; Unity and Godot leave the slot alone).
//  * What is drawn and hit. ui_transform maps layout space to the screen; ui_quad is the widget's oriented rectangle there
//    and ui_rect its bounding box. A ScrollList's scissor is always that bounding box (a scissor cannot turn): a rotated
//    ScrollList warns once, but a pointer outside its turned rectangle still hits nothing.
// An unrotated, unscaled tree takes the same path as before: nothing changes bit for bit.
//
// Where a laid-out child is (since 0.30.0): a Panel or ScrollList places a child by the LAYOUT OFFSET, World::ui_layout_offset,
// not by writing Transform.position. The position of a widget in layout space (what "the sum of the local positions" below
// means) is Transform.position + that offset, so Transform.position of a laid-out child is the author's own nudge from its slot:
// 0 = exactly in the slot (a mirrored child, ui_mirrored, nudges the other way, like every position there). The offset is added
// where the position is, before any rotation and scale of the chain, and world_matrix of the child already contains it.
//
// The interface scale (World::ui_scale(), `ui.scale`, k): a screen-space widget is authored and laid out in UI UNITS, a
// virtual screen of designSize / k with the safe insets divided by k, and drawn k times as big. So k multiplies its size,
// offset, padding, spacing, margins and font size, but not the anchor point: a widget anchored to the bottom-right corner
// stays in that corner. ui_rect, ui_screen_rect and every drawn pixel are in screen pixels (UI units * k);
// ui_layout_rect is in UI units and is what layout, ScrollList and Slider arithmetic read.
#pragma once

#include <array>
#include <optional>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

#include "fa/core/math.h"
#include "fa/scene/components.h"
#include "fa/scene/world.h"

namespace fa {

// Range of the interface scale; World::ui_scale() and the `ui.scale` setting are clamped / checked against it.
constexpr float kMinUiScale = 0.5f;
constexpr float kMaxUiScale = 3.0f;
// The scale to use for arithmetic: 1 when `k` is not a usable number (NaN, <= 0), else `k` clamped to the range above.
float ui_scale_clamped(float k);

enum class UiKind : std::int32_t {
    None,
    Panel,
    Button,
    Toggle,
    Slider,
    TextField,
    ScrollList,
    TouchStick,
    TouchButton,
    Captions,
    Video,
    Chart,
    CameraView
};
const char* ui_kind_name(UiKind k);  // "Panel", "Button"... ("" for None)

// The widget component of `e` (the first of Button, Toggle, Slider, TextField, ScrollList, Panel, TouchStick,
// TouchButton, Captions, Video, Chart, CameraView), None if it has none.
UiKind ui_kind(const World& w, Entity e);
// Its shared geometry and background, nullptr if `e` is no widget.
const UiBox* ui_box(const World& w, Entity e);
// Whether the UI layout would give `child` a slot if it were a child of `parent`: `parent` is a Panel with a layout (or a
// fallbackLayout) or a ScrollList, and `child` has a size the layout can measure (a widget, or a Text, Sprite or Shape2D in
// screen space). World::set_parent uses it to put a widget moved into a container in its slot.
bool ui_layout_places(const World& w, Entity parent, Entity child);
// Button, Toggle, Slider and TextField can be focused, hovered and clicked; Panel and ScrollList cannot.
inline bool ui_is_control(UiKind k) {
    return k == UiKind::Button || k == UiKind::Toggle || k == UiKind::Slider || k == UiKind::TextField;
}
// The interactive part (font, colours, focused / hovered / pressed) of such a widget; nullptr for any other entity.
const UiControl* ui_control(const World& w, Entity e);

// The screen point an anchor names, in design pixels: {anchor.x * W, anchor.y * H} with designSize = {W, H}, or, when
// `safeArea` is true, the same fractions of the safe rectangle (the screen minus `insets`): anchor [0, 0] is its top-left
// corner, [1, 1] its bottom-right. The ONE definition behind drawing, layout, hit-testing and editor picking.
Vec2 anchor_point(Vec2 anchor, bool safeArea, Vec2 designSize, const EdgeInsets& insets);

// Whether `e` is drawn mirrored left to right (ui.mirrorRtl): the world's ui_mirror() (the project's ui.mirrorRtl in a
// right-to-left language), `e` is a widget or lies below one (a Text, Sprite or Shape2D in a widget), and no widget from `e`
// up to the root has UiBox.mirror false. Mirrored means that anchor.x, pivot.x and position.x flip: the widget is where its
// mirror image about the middle of the screen (of the safe area, with safeArea) would be, with the same size.
bool ui_mirrored(const World& w, Entity e);

// `inner` reflected left to right about the middle of `outer`: where a part of a mirrored widget goes.
inline Rect ui_mirror_in(const Rect& outer, const Rect& inner) {
    return Rect{2.0f * outer.x + outer.w - inner.x - inner.w, inner.y, inner.w, inner.h};
}

// A "device profile" for tests and AI agents: the insets of a typical notched phone, as fractions of the design size.
// Names: "none", "phone-portrait" (notch at the top, home indicator at the bottom), "phone-landscape" (notch on a side,
// home indicator at the bottom). false (out alone) for any other name.
bool safe_area_profile(std::string_view name, Vec2 designSize, EdgeInsets& out);
const std::vector<std::string>& safe_area_profile_names();

// A 2D affine map: x' = a x + c y + tx, y' = b x + d y + ty.
struct UiAffine {
    float a = 1, b = 0, c = 0, d = 1, tx = 0, ty = 0;
    bool is_identity() const { return a == 1 && b == 0 && c == 0 && d == 1 && tx == 0 && ty == 0; }
    Vec2 apply(Vec2 p) const { return {a * p.x + c * p.y + tx, b * p.x + d * p.y + ty}; }
    // The map undone; nullopt when it flattens the plane (a scale of 0).
    std::optional<UiAffine> inverse() const;
    // True when a rectangle stays a rectangle with sides parallel to the axes (no turn, or a quarter turn).
    bool axis_aligned() const;
};

// The widget's rectangle in UI UNITS (the virtual screen of designSize / k, see above): x, y = top-left, +Y down, from the
// world translation T of the entity:
//   {T.x + A.x - pivot.x * size.x,  T.y + A.y - (1 - pivot.y) * size.y,  size.x, size.y}
// with A = anchor_point(anchor, safeArea, designSize / k, w.safe_insets() / k) and designSize = {W, H} (the renderer's
// target size). nullopt when `e` is no widget. At k = 1 it is the same as ui_rect.
std::optional<Rect> ui_layout_rect(const World& w, Entity e, Vec2 designSize);

// The widget's own-frame rectangle in layout space, scaled by k from the screen's origin ({k * x, k * y, k * w, k * h}): what
// ui_rect was before widgets could turn. nullopt when `e` is no widget. With no rotation or scale above `e` it is ui_rect.
std::optional<Rect> ui_own_rect(const World& w, Entity e, Vec2 designSize);

// The rectangle a widget takes in its parent's layout, in UI units: ui_layout_rect scaled about the pivot by the widget's own
// scale (its absolute value) and not turned. Equal to ui_layout_rect at scale 1. nullopt when `e` is no widget.
std::optional<Rect> ui_footprint_rect(const World& w, Entity e, Vec2 designSize);

// What world_matrix(e) is for layout: with no rotation or scale from `e` up, world_matrix(e); else the translation of
// layout space and `e`'s own scale (its own and its parents' rotation, and its parents' scale, left out). Used for the
// footprint of a screen-space Text, Sprite or Shape2D that a layout places.
Mat4 ui_layout_matrix(const World& w, Entity e);

// The translation of `e` in layout space: the sum, from the root down to `e`, of Transform.position + World::ui_layout_offset.
// With no rotation or scale from `e` up it is world_matrix(e).translation(), bit for bit.
Vec3 ui_layout_translation(const World& w, Entity e);

// True when an ANCESTOR of `e` that is a widget (it has a UiBox) rotates or scales. Only then is a screen-space Text, Sprite or
// Shape2D under it drawn through ui_transform (it turns with the widget's card); a plain group above it that scales leaves it
// on the old path, where the group's scale multiplies the child's own offset and the anchor stays where it is.
bool ui_widget_ancestor_turns(const World& w, Entity e);

// The map from layout space to the screen, both in UI units, of everything drawn for `e`: its own scale and rotation about its
// origin, then each ancestor's about its own. Identity when no entity from `e` up has rotation.z or scale.x/.y other than 0 / 1.
UiAffine ui_transform(const World& w, Entity e, Vec2 designSize);

// The widget's rectangle as drawn: its own-frame corners (top-left, top-right, bottom-right, bottom-left) through
// ui_transform, in screen pixels. nullopt when `e` is no widget.
std::optional<std::array<Vec2, 4>> ui_quad(const World& w, Entity e, Vec2 designSize);

// True when the screen point `p` (pixels) is inside the widget's oriented rectangle, borders included. Same as
// ui_rect(w, e, d)->contains(p) when nothing turns; false for a flattened (scale 0) or non-widget `e`.
bool ui_contains(const World& w, Entity e, Vec2 designSize, Vec2 p);

// `p` (screen pixels) in the widget's own frame, in pixels: relative to the same origin as ui_own_rect, so
// `p - ui_own_rect->min()` is the point inside the widget. `p` itself when nothing turns or the map cannot be undone.
Vec2 ui_local_point(const World& w, Entity e, Vec2 designSize, Vec2 p);

// A point of the widget's own frame (screen pixels, the origin of ui_own_rect) as it is drawn, in screen pixels. The inverse of
// ui_local_point.
Vec2 ui_world_point(const World& w, Entity e, Vec2 designSize, Vec2 p);

// The widget's rectangle on the screen, in design pixels: the bounding box of ui_quad (what a click, the clip and the
// navigation look at). With no rotation or scale it is ui_layout_rect scaled by k from the screen's origin
// ({k * x, k * y, k * w, k * h}). nullopt when `e` is no widget.
std::optional<Rect> ui_rect(const World& w, Entity e, Vec2 designSize);

// The screen of the UI units: designSize / k.
Vec2 ui_layout_screen(const World& w, Vec2 designSize);
// The safe insets in UI units (the insets divided by k).
EdgeInsets ui_layout_insets(const World& w);

// The intersection of the screen rectangles (ui_rect: bounding boxes) of every ScrollList ANCESTOR of `e` (not `e` itself): what is
// drawn of `e`. nullopt when it has none. The result may be empty (w or h <= 0) when the rectangles do not overlap.
std::optional<Rect> ui_clip_rect(const World& w, Entity e, Vec2 designSize);

// True when the screen point `p` is inside the oriented rectangle of every ScrollList ANCESTOR of `e` (true when it has none):
// what is hit-tested of `e`. Exact for a turned list, where ui_clip_rect (the scissor) is its bounding box.
bool ui_clip_contains(const World& w, Entity e, Vec2 designSize, Vec2 p);

// Intersection of two rectangles; w and h are 0 when they do not overlap.
Rect ui_intersect(const Rect& a, const Rect& b);

// Horizontal extent {left, right} of a Slider's track inside its rectangle `r` (in UI units, ui_layout_rect; the result is in
// the same units): after an 8 px margin the label takes 35% of
// the rest (when not empty), the track the next 50% (85% without a label) and the value text the last 15%. Both the
// drawing and the mouse use it, so the knob is always under the pointer.
// With Slider.labelAbove (and a label) the label does not take the 35%: the track gets the 85% of an unlabelled slider.
// `mirrored` (ui_mirrored): the same track reflected in `r`, so the label is at the right and the value text at the left; the
// slider's value then grows from the track's right end to its left one (use ui_slider_fraction).
std::pair<float, float> ui_slider_track(const Slider& s, const Rect& r, bool mirrored = false);

// How far along its track a slider is when the pointer is at `x` (UI units), 0 .. 1: from the left end, or from the right end
// of a mirrored track.
float ui_slider_fraction(std::pair<float, float> track, float x, bool mirrored);

// True when the Slider's label is drawn above the track (labelAbove and a non-empty label).
inline bool ui_slider_label_above(const Slider& s) { return s.labelAbove && !s.label.empty(); }
// Height of the row with the track, knob and value when the label is above (UI units); the label gets the rest on top.
constexpr float kUiSliderRowHeight = 28.0f;
// Vertical middle of the track / knob / value row inside the Slider's rectangle `r`: the middle of r, or of its bottom
// kUiSliderRowHeight units when the label is above. `r` and the result are in UI units.
float ui_slider_mid_y(const Slider& s, const Rect& r);

// The text a Slider draws at its right for `value`: its `format` pattern when it has one ({v}, {v:N}, {percent}), else "60%"
// for a 0..1 range, else the number with up to two decimals.
std::string ui_slider_value_text(const Slider& s, float value);

}  // namespace fa
