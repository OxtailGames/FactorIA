// Game UI behaviour: layout of Panel / ScrollList children, focus and keyboard / gamepad / mouse navigation, widget
// values and the `ui.*` events. The components are in scene/components.h, their geometry in scene/ui_rect.h and their
// drawing in fa_render; this module is the part that reads Input and changes the world.
//
// One frame (the runtime calls update() right before scripts.update):
//   layout -> focus rules (lost focus, autoFocus) -> keys / pad (navigation, submit, cancel, text) -> pointer
//   (hover, press, drag, wheel; the pointer is the mouse or set_pointer()) -> the runtime flags of the widgets (focused / hovered / pressed / caret).
// Events go into world.events().game with the widget as source and `{id, ...}` as data: ui.click, ui.change {value},
// ui.submit {value}, ui.focus, ui.cancel {id|null}, ui.dragStart / ui.dragOver / ui.drop / ui.dragCancel (drag.cpp). Scripts get them through world.on / Behaviour.onEvent / ui.on.
//
// The ui_* actions it reads (ui_up, ui_down, ui_left, ui_right, ui_submit, ui_cancel) are installed with default
// bindings by the runtime unless factoria.json defines an action of the same name (ui_with_default_actions()).
#pragma once

#include <array>
#include <optional>
#include <vector>
#include <functional>
#include <string>
#include <unordered_map>
#include <unordered_set>

#include "fa/core/i18n.h"
#include "fa/core/json.h"
#include "fa/core/math.h"
#include "fa/platform/clipboard.h"
#include "fa/platform/input.h"
#include "fa/scene/bounds.h"
#include "fa/scene/ui_rect.h"
#include "fa/scene/ui_tooltip.h"
#include "fa/scene/world.h"

namespace fa {

// `actions` (factoria.json input.actions, may be null) plus the default bindings of the ui_* actions that it does not
// define itself.
Json ui_with_default_actions(const Json& actions);

// Where `e` is on the screen, in design pixels (x, y = top-left, +Y down, the safe area and the interface scale ui.scale
// included): a widget's rectangle, else the box around its screen-space Text / Sprite / Shape2D (text sized through
// `measure`). nullopt for any other entity.
std::optional<Rect> ui_screen_rect(const World& world, Entity e, Vec2 designSize, const VisualMeasure& measure = {});

// The topmost visible widget at the screen point `p` (design pixels), or kNullEntity: every active entity with a UiBox
// counts, the interactable controls (Button, Toggle, Slider, TextField, also the ones with interactable false) and the
// ones that only hold things (Panel, ScrollList, a TouchStick / TouchButton that is shown, Video). Left out: what a
// ScrollList clips away at `p`, a Panel with a fully transparent colour and no texture (it draws nothing), a Captions
// line, an inactive entity and a box with no area. Topmost is the highest `layer`, and among equal layers the entity made
// last, as for the hover. Reads the rectangles the last layout wrote.
// `ignore` (and its descendants) is not looked at: the drag image that follows the pointer.
Entity ui_widget_at(const World& world, Vec2 designSize, Vec2 p, Entity ignore = kNullEntity);
// The modal Panel that scopes the input right now: the active Panel with `modal` and the highest layer (the later entity on a
// tie), or kNullEntity. ui_widget_at() and the UiSystem treat only it and its descendants as reachable while there is one.
Entity ui_modal_panel(const World& world);


// A TextField the player focused or left with a gamepad, for the platform's own keyboard (the runtime hands it to a native
// plugin: fa_plugin.h, FaTextInput). `rect` is in design pixels; the runtime converts it to window pixels.
struct TextInputRequest {
    bool focused = true;   // true: took the focus (or the pad's submit button was pressed on it again); false: lost it
    Rect rect;             // the field's rectangle, design pixels (empty when the field is gone)
    std::string text;
    std::int32_t maxLength = 0;
    bool multiline = false, password = false;  // no TextField has either yet
};
// Returns true when the platform shows its own keyboard for the field. For a request with `focused` false it is ignored.
using TextInputHandler = std::function<bool(const TextInputRequest&)>;

// ---- tooltips (docs/MENUS.md, "Tooltips") ------------------------------------------------------------------------------
// What a tooltip says, after the keys are translated: an optional title and the body lines (a line may have its own colour).
struct UiTooltipText {
    struct Line {
        std::string text;
        std::optional<Color> color;
    };
    std::string title;
    std::vector<Line> lines;
    bool empty() const { return title.empty() && lines.empty(); }
};

// Reads the `tooltip` content of a widget or of ui.showTooltip: a string, or {title, lines: [text | {text, color}], args}. Each
// text is a locale key when `i18n` is on and has it (placeholders from `args`), else it is shown as written. nullopt, and `error`
// says why, for any other shape; an empty result (nothing to say) is a value with empty().
std::optional<UiTooltipText> ui_tooltip_text(const Json& content, const I18n* i18n, std::string* error = nullptr);

// The size of a tooltip box in UI units for `text` in `style`: lines wrap at style.maxWidth, the padding is added. `measure`
// sizes the lines (approx_text_size when it has no textSize).
Vec2 ui_tooltip_size(const UiTooltipText& text, const UiTooltipStyle& style, const VisualMeasure& measure);

// Where the box of `size` goes when the pointer is at `pointer`, all in screen PIXELS: below and to the right, `gap` away, flipped to
// the left of the pointer and/or above it when it would cross `screen`, then pushed back inside (4 px margin) when it still
// does not fit. A box larger than the screen is placed at the margin and keeps hanging over the right / bottom edge.
Vec2 ui_tooltip_place(Vec2 pointer, Vec2 size, Vec2 screen, float gap);

// Builds the view of `text` for a pointer at `pointer` (screen pixels): measures, places and positions each line, in UI units
// (`k` = the interface scale). shown is true unless `text` is empty.
UiTooltipView ui_tooltip_layout(const UiTooltipText& text, const UiTooltipStyle& style, const VisualMeasure& measure, Vec2 pointer,
                                Vec2 screenPx, float k);

// Script hooks for the tooltips that are functions (ui.setTooltip / ui.setWorldTooltip). Both return the content (null = none).
struct UiTooltipHooks {
    std::function<Json(Entity)> widget;  // asked for a widget registered with set_script_tooltip
    std::function<Json(Vec2)> world;     // asked with the pointer when it rests on no widget, if set_world_tooltip(true)
};

// ---- drag and drop (docs/MENUS.md, "Drag and drop") -------------------------------------------------------------------------
// What `draggable` of a widget says: the payload the drag carries and the pixels the pointer must travel after the press.
struct UiDragSpec {
    Json payload;
    float slop = 6.0f;
};
// Reads UiBox.draggable: null / false = nullopt with no error (not draggable); true = defaults; {payload, slop}. nullopt with `error`
// set for any other shape.
std::optional<UiDragSpec> ui_drag_spec(const Json& draggable, std::string* error = nullptr);

// Whether a widget (or the world) takes a drop: Script asks a function through UiDropHooks.
enum class UiDropMode : std::int32_t { None, Accept, Reject, Script };
// `drag` is {id: source id, payload, x, y}.
struct UiDropHooks {
    std::function<bool(Entity target, const Json& drag)> widget;
    std::function<bool(const Json& drag)> world;
};

class UiSystem {
public:
    // Every frame, before scripts.update: lays out containers, then updates hover / press / focus / values from `input`
    // and pushes ui.* events. `dt` is REAL (unscaled) seconds: the UI works while time.scale is 0. `designSize` is the
    // renderer's target size (anchors are relative to it). It also hands the rectangles of the active TouchStick and
    // TouchButton widgets to input.set_touch_controls (fingers landing before the next frame hit what is drawn now) and
    // writes their runtime fields (value, pressed, shown) back from the touch pad.
    void update(World& world, Input& input, Vec2 designSize, float dt, const VisualMeasure& measure);

    // Lays out Panel (layout != none) and ScrollList children only, in UI units (ui_rect.h: the world's ui_scale()), and holds a
    // Panel between its minSize and maxSize. update() calls it first; the runtime calls it again
    // right before drawing so changes a script made during the frame are drawn in place. `warn` false (ui.layout() from a
    // script, which is still changing the menu) skips the "fit panel larger than the screen" warning: the frame's own
    // layout logs it if the final menu is still too big.
    void layout(World& world, Vec2 designSize, const VisualMeasure& measure, bool warn = true);

    // The clipboard a focused TextField pastes from (Ctrl+V / Cmd+V) and copies to (Ctrl+C / Cmd+C). The Engine sets it;
    // without one the keys do nothing.
    void set_clipboard(Clipboard* clipboard) { clipboard_ = clipboard; }

    // The platform keyboard (native plugins, plugin API 3). With a handler, a TextField that takes the focus while the last input
    // was a gamepad (or gets the pad's submit button again) is offered to it; when it answers true, input.platformKeyboard()
    // is true until the field loses the focus, and the menu kit's on-screen keyboard stays closed. Without a handler nothing
    // changes. The handler runs inside update() and reset() on the game thread.
    void set_text_input_handler(TextInputHandler handler) { textInput_ = std::move(handler); }
    // Text the platform keyboard returned: replaces the text of the field that took the keyboard if it still has the focus
    // (cut to its maxLength, control characters dropped) and sends ui.change when the text changed. False when no field is
    // waiting for it: the text is dropped.
    bool submit_text(World& world, const std::string& text);

    // A virtual pointer for a gamepad cursor and for tests: from the next update() on, the UI takes the pointer's place
    // and left button from here instead of from the mouse, so hover, press, drag of a Slider, click and the wheel's
    // target work as with the mouse (a click is a `down` that goes true and then false). The real mouse is ignored until
    // clear_pointer(). A scene load clears it.
    void set_pointer(Vec2 position, bool down) {
        pointerOn_ = true;
        pointerPos_ = position;
        pointerDown_ = down;
    }
    void clear_pointer() { pointerOn_ = false; }
    bool has_pointer() const { return pointerOn_; }
    // True when the pointer (the mouse, or the virtual one) is over ui_widget_at() something at the last update().
    bool pointer_over_ui() const { return pointerOverUi_; }
    // True when the wheel of the last update() scrolled a ScrollList under the pointer: Input::mouse_wheel() reads 0 for
    // the rest of that frame, so scripts and the game do not also zoom or scroll with it.
    bool wheel_consumed() const { return wheelConsumed_; }

    Entity focused() const { return focus_; }
    // Gives focus to `e` (kNullEntity clears it, and the focus then stays empty: an open Panel's autoFocus does not take
    // it back until the next ui_up / ui_down / ui_left / ui_right press) and emits ui.focus. Returns false, and changes nothing, when `e` cannot
    // take focus: not alive, not a Button / Toggle / Slider / TextField, inactive or not interactable.
    bool set_focus(World& world, Entity e);
    Entity hovered() const { return hover_; }

    // Sets a Slider as a drag would: focuses it, clamps `value` to [min, max], snaps it to `step`, and sends ui.change when the
    // number changed. Returns the value the slider now has. `e` must be an alive, active, interactable Slider (checked by the
    // ui.set_slider command, which is what tests call).
    float set_slider(World& world, Entity e, float value);

    // The ui.state command: {focused, hovered, uiScale, widgets: [{id, kind, rect: [x, y, w, h], focused, hovered, pressed,
    // interactable, visible, value?, text?, overflowed?}]} in reading order (top, then left). `visible` is false when a ScrollList
    // clips the widget away entirely, or for a TouchStick / TouchButton that is not shown.
    // Screen-space Text entities follow the widgets, as {id, kind: "Text", rect, text, ...}; `measure` sizes their rect.
    Json state(const World& world, Vec2 designSize, const VisualMeasure& measure = {}) const;

    // ---- tooltips. The Engine sets the I18n; update() decides what shows (World::ui_tooltip()).
    void set_i18n(const I18n* i18n) { i18n_ = i18n; }
    void set_tooltip_hooks(UiTooltipHooks hooks) { tooltipHooks_ = std::move(hooks); }
    // `e` has a script function that gives its tooltip (or not any more).
    void set_script_tooltip(Entity e, bool on);
    // A function gives the tooltip for the pointer resting on no widget.
    void set_world_tooltip(bool on) { worldTooltip_ = on; }
    // Shows `content` now, near `at` (screen pixels), whatever the rest timer says; it stays until hide_tooltip(), until the pointer
    // moves more than the slop from where it was, or a scene load. Returns the problem when `content` is not a tooltip.
    Result<void> show_tooltip(World& world, const Json& content, Vec2 at, Vec2 designSize, const VisualMeasure& measure);
    void hide_tooltip(World& world);
    // Seconds of rest still needed before the tooltip under the pointer shows (0 once it shows), for tests.
    float tooltip_wait() const { return tooltipShown_ ? 0.0f : std::max(0.0f, tooltipDelay_ - tooltipRest_); }

    // ---- drag and drop. update() starts a drag when the pointer moves past the slop of a draggable widget it pressed, emits
    // ui.dragStart / ui.dragOver / ui.drop / ui.dragCancel (data: {id: source, payload, x, y, target: id | null, accepts}, and
    // `reason` on a cancel) and swallows the click. A target is the nearest widget at or above the one under the pointer that
    // has a rule from set_drop_target(); a widget with none refuses, the world (nothing under the pointer) accepts unless
    // set_drop_target(kNullEntity, ...) says otherwise.
    void set_drop_hooks(UiDropHooks hooks) { dropHooks_ = std::move(hooks); }
    void set_drop_target(Entity e, UiDropMode mode);
    // The widget that follows the pointer while dragging (its centre under the pointer; it is ignored by hit-testing). kNullEntity = none.
    void set_drag_image(Entity e) { dragImage_ = e; }
    bool dragging() const { return drag_.active; }
    // null when no drag; else {id, payload, from: [x, y], x, y, target: id | null, accepts}.
    Json drag_json(const World& world) const;
    // Ends the drag with ui.dragCancel {reason} (no-op when none).
    void cancel_drag(World& world, const char* reason = "cancel");

    // Charts. update() finds the topmost widget under the pointer; when it is a Chart, the sample under the pointer (chart.h) is
    // written to Chart.hoverIndex / hoverSeries and the game event ui.chartHover {id, index, series, value} is sent each time the
    // chart or the sample changes; {index: -1, series: -1} (no value) when the pointer leaves the chart or the chart goes away.

    // Scene load: no focus, no hover, no press, no tooltip, no drag.
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
    bool focusCleared_ = false;   // set_focus(null) was called: autoFocus waits for a navigation press
    bool pointerOn_ = false, pointerDown_ = false, pointerPrevDown_ = false, pointerOverUi_ = false, wheelConsumed_ = false;
    Vec2 pointerPos_{};
    TextInputHandler textInput_;
    Clipboard* clipboard_ = nullptr;
    Entity platformField_;  // the TextField the platform keyboard was taken for (kNullEntity = none)
    Entity askedField_;     // the TextField the handler was asked about since it got the focus
    void release_platform_keyboard(const World* world);
    bool keyboardRaised_ = false;  // the UI asked for the phone's keyboard (a TextField has focus, last input not a pad)
    bool scrollToFocus_ = false;  // the focus changed: the next layout scrolls the focused widget into view
    float clock_ = 0.0f;          // the UI's own unscaled clock (caret blink)
    float caretStart_ = 0.0f;     // clock_ at the last edit or focus change: the caret is visible then
    std::array<Repeat, 4> nav_;   // up, down, left, right
    Repeat backspace_;

    // Chart hover: the chart and sample the pointer was over at the last update (ui.chartHover is sent when it changes).
    void update_chart_hover(World& world, Vec2 designSize, Vec2 mouse);
    Entity chartHover_;
    std::int32_t chartHoverSeries_ = -1, chartHoverIndex_ = -1;

    // drag and drop (drag.cpp)
    struct DragState {
        bool active = false;
        Entity source;
        std::string sourceId;
        Json payload;
        Vec2 from{}, pos{};
        Entity target;
        bool accepts = false;
        bool started = false;  // dragStart not sent yet
    };
    void update_drag(World& world, Vec2 designSize, Vec2 mouse, bool down, bool pressed, bool released, const VisualMeasure& measure,
                     bool navCancel);
    void drag_emit(World& world, const char* name, const char* reason = nullptr);
    DragState drag_;
    Entity dragCand_;   // a draggable widget the pointer pressed and has not yet moved far enough
    Vec2 dragCandFrom_{};
    UiDropHooks dropHooks_;
    std::unordered_map<u64, UiDropMode> dropRules_;
    UiDropMode worldDrop_ = UiDropMode::Accept;
    Entity dragImage_;
    Vec2 lastDragPos_{};
    u64 lastDragTarget_ = 0;
    bool lastDragAccepts_ = false;

    // tooltips (tooltip.cpp)
    void update_tooltip(World& world, const Input& input, Vec2 designSize, float dt, const VisualMeasure& measure, Vec2 pointer,
                        bool pointerDown);
    Vec2 lastPointer_{};  // where the pointer was at the last update()
    Vec2 manualAt_{};     // where show_tooltip() was asked to put the tooltip
    const I18n* i18n_ = nullptr;
    UiTooltipHooks tooltipHooks_;
    std::unordered_set<u64> scriptTooltips_;
    bool worldTooltip_ = false;
    float tooltipRest_ = 0.0f, tooltipDelay_ = 0.5f;
    bool tooltipShown_ = false, tooltipManual_ = false;
    Vec2 tooltipAnchor_{};
    u64 tooltipTarget_ = 0;  // the widget bits the timer runs for (0 = the world)
    Json tooltipManualContent_;
    std::string tooltipWarned_;  // the last bad-tooltip warning, so one that stays on screen is logged once
};

}  // namespace fa
