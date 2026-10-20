// Game UI behaviour: layout of Panel / ScrollList children, focus and keyboard / gamepad / mouse navigation, widget
// values and the `ui.*` events. The components are in scene/components.h, their geometry in scene/ui_rect.h and their
// drawing in fa_render; this module is the part that reads Input and changes the world.
//
// One frame (the runtime calls update() right before scripts.update):
//   layout -> focus rules (lost focus, autoFocus) -> keys / pad (navigation, submit, cancel, text) -> pointer
//   (hover, press, drag, wheel) -> the runtime flags of the widgets (focused / hovered / pressed / caret).
// Events go into world.events().game with the widget as source and `{id, ...}` as data: ui.click, ui.change {value},
// ui.submit {value}, ui.focus, ui.cancel {id|null}. Scripts get them through world.on / Behaviour.onEvent / ui.on.
//
// The ui_* actions it reads (ui_up, ui_down, ui_left, ui_right, ui_submit, ui_cancel) are installed with default
// bindings by the runtime unless factoria.json defines an action of the same name (ui_with_default_actions()).
#pragma once

#include <array>
#include <unordered_map>
#include <unordered_set>

#include "fa/core/json.h"
#include "fa/core/math.h"
#include "fa/platform/input.h"
#include "fa/scene/bounds.h"
#include "fa/scene/ui_rect.h"
#include "fa/scene/world.h"

namespace fa {

// `actions` (factoria.json input.actions, may be null) plus the default bindings of the ui_* actions that it does not
// define itself.
Json ui_with_default_actions(const Json& actions);

// Where `e` is on the screen, in design pixels (x, y = top-left, +Y down, the safe area included): a widget's rectangle, else
// the box around its screen-space Text / Sprite / Shape2D (text sized through `measure`). nullopt for any other entity.
std::optional<Rect> ui_screen_rect(const World& world, Entity e, Vec2 designSize, const VisualMeasure& measure = {});

class UiSystem {
public:
    // Every frame, before scripts.update: lays out containers, then updates hover / press / focus / values from `input`
    // and pushes ui.* events. `dt` is REAL (unscaled) seconds: the UI works while time.scale is 0. `designSize` is the
    // renderer's target size (anchors are relative to it). It also hands the rectangles of the active TouchStick and
    // TouchButton widgets to input.set_touch_controls (fingers landing before the next frame hit what is drawn now) and
    // writes their runtime fields (value, pressed, shown) back from the touch pad.
    void update(World& world, Input& input, Vec2 designSize, float dt, const VisualMeasure& measure);

    // Lays out Panel (layout != none) and ScrollList children only. update() calls it first; the runtime calls it again
    // right before drawing so changes a script made during the frame are drawn in place. `warn` false (ui.layout() from a
    // script, which is still changing the menu) skips the "fit panel larger than the screen" warning: the frame's own
    // layout logs it if the final menu is still too big.
    void layout(World& world, Vec2 designSize, const VisualMeasure& measure, bool warn = true);

    Entity focused() const { return focus_; }
    // Gives focus to `e` (kNullEntity clears it) and emits ui.focus. Returns false, and changes nothing, when `e` cannot
    // take focus: not alive, not a Button / Toggle / Slider / TextField, inactive or not interactable.
    bool set_focus(World& world, Entity e);
    Entity hovered() const { return hover_; }

    // The ui.state command: {focused, hovered, widgets: [{id, kind, rect: [x, y, w, h], focused, hovered, pressed,
    // interactable, visible, value?, text?}]} in reading order (top, then left). `visible` is false when a ScrollList
    // clips the widget away entirely, or for a TouchStick / TouchButton that is not shown.
    // Screen-space Text entities follow the widgets, as {id, kind: "Text", rect, text, ...}; `measure` sizes their rect.
    Json state(const World& world, Vec2 designSize, const VisualMeasure& measure = {}) const;

    // Scene load: no focus, no hover, no press.
    void reset();

private:
    // Auto-repeat of a held direction / key: fires on the press, then after 0.4 s and every 0.1 s (real time).
    struct Repeat {
        bool held = false;
        float time = 0.0f, next = 0.0f;
        bool tick(bool pressed, bool down, float dt);
    };

    // autoSize: the design size of a widget and the size the UI wrote last (a different current size is a new design size).
    struct AutoSizeMemo {
        Vec2 design, applied;
    };
    std::unordered_map<u64, AutoSizeMemo> autoSizes_;
    std::unordered_set<u64> warnedFit_;  // fit panels already reported as larger than the screen

    Entity focus_, hover_, press_;
    bool scrollToFocus_ = false;  // the focus changed: the next layout scrolls the focused widget into view
    float clock_ = 0.0f;          // the UI's own unscaled clock (caret blink)
    float caretStart_ = 0.0f;     // clock_ at the last edit or focus change: the caret is visible then
    std::array<Repeat, 4> nav_;   // up, down, left, right
    Repeat backspace_;
};

}  // namespace fa
