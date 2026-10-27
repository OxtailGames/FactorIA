// Input state + named actions.
//
// Games should read ACTIONS ("jump", "move_left") rather than raw keys; the
// project maps actions to bindings in factoria.json:
//   "input": { "actions": {
//       "jump":       ["Space", "W", "Up", "GamepadA"],
//       "move_left":  ["A", "Left"],
//       "fire":       ["MouseLeft", "Touch"]
//   } }
// Binding names: key names from key_name() ("A".."Z", "0".."9", "Space",
// "Enter", "Escape", "Left", "Right", "Up", "Down", "LeftShift", "F1"...),
// "MouseLeft", "MouseRight", "MouseMiddle", "Touch" (any finger down), and gamepad bindings, which match ANY
// connected pad:
//   buttons    "Gamepad" + a GamepadButton name: GamepadA/B/X/Y, GamepadStart, GamepadBack, GamepadGuide,
//              GamepadDpadLeft/Right/Up/Down, GamepadLeftShoulder/RightShoulder, GamepadLeftThumb/RightThumb
//   half axes  GamepadLeftStickLeft/Right/Up/Down, GamepadRightStickLeft/Right/Up/Down, GamepadLeftTrigger,
//              GamepadRightTrigger: ANALOG, see action_value()
// Modifier chords: modifiers joined to a binding with "+", "Ctrl+Z", "Shift+MouseLeft", "Ctrl+Shift+S", "Alt+Touch". The
// modifiers are Ctrl, Shift, Alt and Super (Cmd / the Windows key), each naming EITHER side's key; written in this order
// when printed back ("Ctrl+Alt+Shift+Super+X"). "Shift" alone is a binding too (either Shift key). A chord is down while its
// modifiers are held and its input is down. When one action binds Z and another Ctrl+Z, the chord wins: Z does not fire
// while Ctrl is held (and so on for any binding whose modifiers are a subset of a held chord's). Chords combine with keys,
// mouse buttons and Touch, not with gamepad bindings.
// Unknown names are rejected by set_actions with a "did you mean" hint.
//
// PLAYERS (local multiplayer): the actions above answer to every device. For games where two to four people share the
// machine, a player (0..kMaxPlayers-1) is given a device (a gamepad, and/or a key scheme: a set of keys such as the left
// half of the keyboard) with use_player_device() and then reads the SAME actions through player_action_*(): its pad
// bindings read only its pad, its key bindings only the keys of its scheme. Each player can rebind on its own.
//
// Coordinates: mouse/touch positions are in DESIGN-RESOLUTION screen pixels,
// origin top-left, +Y down (same as screen-space UI). The runtime converts
// from window pixels (letterboxing/scaling).
//
// Injection (tests, headless runs, AI agents) goes through the same functions
// as real events, so games cannot tell the difference.
#pragma once

#include <array>
#include <cstdint>
#include <map>
#include <span>
#include <string>
#include <string_view>
#include <unordered_map>
#include <vector>

#include "fa/core/json.h"
#include "fa/core/math.h"

namespace fa {

enum class Key : std::uint16_t {
    Unknown = 0,
    A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, R, S, T, U, V, W, X, Y, Z,
    Num0, Num1, Num2, Num3, Num4, Num5, Num6, Num7, Num8, Num9,
    Space, Enter, Escape, Tab, Backspace, Insert, Delete,
    Left, Right, Up, Down, PageUp, PageDown, Home, End,
    LeftShift, RightShift, LeftControl, RightControl, LeftAlt, RightAlt, LeftSuper, RightSuper,
    F1, F2, F3, F4, F5, F6, F7, F8, F9, F10, F11, F12,
    Minus, Equal, LeftBracket, RightBracket, Backslash, Semicolon, Apostrophe, Comma, Period, Slash, GraveAccent,
    Count
};
const char* key_name(Key k);               // "A", "Num1" is named "1", "Space"...
Key key_from_name(std::string_view name);  // case-insensitive; Unknown if invalid

// Modifier keys as a bit mask: each bit stands for the keys of both sides.
namespace modifier {
inline constexpr std::uint8_t Shift = 1, Ctrl = 2, Alt = 4, Super = 8;
}
// "Ctrl" / "Control", "Shift", "Alt", "Super" / "Cmd" / "Command" / "Win" (case-insensitive) to its bit; 0 when `name` is no
// modifier. A key name such as "LeftShift" is not one: it names one side.
std::uint8_t modifier_from_name(std::string_view name);
const char* modifier_name(std::uint8_t bit);  // "Ctrl"; "" if `bit` is not exactly one modifier
Key modifier_key(std::uint8_t bit, bool right = false);  // the key of one side (Key::Unknown if `bit` is not one modifier)

enum class MouseButton : std::uint8_t { Left, Right, Middle, Count };

// Gamepads: up to kMaxGamepads pads, indexed from 0, with an Xbox-style layout (A bottom, B right, X left, Y top).
inline constexpr int kMaxGamepads = 4;
enum class GamepadButton : std::uint8_t {
    A, B, X, Y, Start, Back, Guide, DpadLeft, DpadRight, DpadUp, DpadDown, LeftShoulder, RightShoulder, LeftThumb,
    RightThumb,  // the thumbs are the stick clicks
    Count
};
// Sticks run -1..1 with +Y UP (like world space, unlike the screen); triggers run 0..1.
enum class GamepadAxis : std::uint8_t { LeftX, LeftY, RightX, RightY, LeftTrigger, RightTrigger, Count };
const char* gamepad_button_name(GamepadButton b);  // "A", "DpadLeft"...
const char* gamepad_axis_name(GamepadAxis a);      // "LeftX", "RightTrigger"...
// Case-insensitive. Return false (and leave `out` alone) for an unknown name.
bool gamepad_button_from_name(std::string_view name, GamepadButton& out);
bool gamepad_axis_from_name(std::string_view name, GamepadAxis& out);
std::vector<std::string> gamepad_button_names();
std::vector<std::string> gamepad_axis_names();

// The family a pad belongs to, which decides the button names a player sees (Input::button_name): the same A button is
// "A" on an Xbox pad and "Cross" on a PlayStation pad. The buttons themselves are always the Xbox-style positions above.
enum class GamepadType : std::uint8_t { Generic, Xbox, PlayStation, Nintendo, SteamDeck };
const char* gamepad_type_name(GamepadType t);  // "generic", "xbox", "playstation", "nintendo", "steamdeck"
bool gamepad_type_from_name(std::string_view name, GamepadType& out);  // case-insensitive; false (out alone) if unknown
std::vector<std::string> gamepad_type_names();
// What a platform backend calls with what the OS tells about a pad: the USB vendor id (0 = unknown; Microsoft 0x045e,
// Sony 0x054c, Nintendo 0x057e, Valve 0x28de) and the device name ("Wireless Controller", "DualSense", "Xbox One"...).
// The vendor decides; the name is the fallback; anything else is Generic.
GamepadType gamepad_type_from_ids(std::uint16_t vendorId, std::string_view name);

// What a pad is, as far as the platform can tell. `id` is stable across plugging: the same physical pad gives the same id
// every time (see make_gamepad_id), which a game uses to remember who held it; the slot (0..3) is only where it sits now.
struct GamepadInfo {
    std::string id;     // "045e:028e:Xbox 360 Controller#<serial>": vendor, product, name and the serial/GUID/path when the OS has one
    std::string name;   // what the OS calls the pad ("Wireless Controller"); "Gamepad" when it did not say
    std::uint16_t vendor = 0, product = 0;  // USB ids, 0 = unknown
    GamepadType type = GamepadType::Generic;
    bool operator==(const GamepadInfo&) const = default;
};
// The id of a pad: lower-case hex vendor and product, then the name, then "#" and `unique` (a serial number, GUID, device
// path or index the platform has; "" for none). Two pads of one model without a `unique` share an id: they then take the
// slots in plugging order.
std::string make_gamepad_id(std::uint16_t vendor, std::uint16_t product, std::string_view name, std::string_view unique);
// A pad that came or went: what game.on("gamepadConnected" / "gamepadDisconnected") hands to scripts.
struct GamepadEvent {
    bool connected = false;
    int slot = 0;
    GamepadInfo info;
};

// What a local player reads (Input::use_player_device): a gamepad, a key scheme, both or neither.
inline constexpr int kMaxPlayers = kMaxGamepads;
struct PlayerDevice {
    int pad = -1;       // gamepad slot 0..kMaxGamepads-1, or -1 for none (ignored when padId is set)
    std::string padId;  // the stable id of a pad (GamepadInfo::id): follows the pad to another slot; "" for none
    std::string keys;   // key scheme name ("all", "left", "right" or the project's); "" for no keyboard
    bool operator==(const PlayerDevice&) const = default;
};

// The kind of device that produced input last (Input::last_device()), for showing the matching button prompts.
enum class InputDevice : std::uint8_t { Keyboard, Mouse, Gamepad, Touch };
const char* input_device_name(InputDevice d);  // "keyboard", "mouse", "gamepad", "touch"

struct Touch {
    std::uint64_t id = 0;
    Vec2 position;  // design-resolution pixels
    bool pressedThisFrame = false;
};

// Told about every event the feed below receives, BEFORE it changes the state: what the input recorder (fa/runtime/input_recorder.h)
// writes a replay from. Only the events a caller feeds are reported: the mouse a touch drives and the pad disconnects of
// release_all() are consequences, not events, and are not (the replay reproduces them from the touch / release_all).
class InputObserver {
public:
    virtual ~InputObserver() = default;
    virtual void observe_key(Key, bool) {}
    virtual void observe_mouse_move(Vec2) {}
    virtual void observe_mouse_button(MouseButton, bool) {}
    virtual void observe_touch_begin(std::uint64_t /*id*/, Vec2) {}
    virtual void observe_touch_move(std::uint64_t /*id*/, Vec2) {}
    virtual void observe_touch_end(std::uint64_t /*id*/) {}
    virtual void observe_gamepad_connected(int, bool) {}
    virtual void observe_gamepad_button(int, GamepadButton, bool) {}
    virtual void observe_gamepad_axis(int, GamepadAxis, float) {}
    virtual void observe_back() {}
    virtual void observe_release_all() {}
};

class Input {
public:
    Input();  // the built-in key schemes
    // Frame lifecycle: pressed/released edges and per-frame deltas (mouse delta,
    // wheel, typed text) accumulate from the event feed and stay valid until the
    // next begin_frame(). Call it ONCE PER FRAME AFTER the game has consumed the
    // input (end of the frame), so events arriving before the next frame's
    // update are not wiped. fa::run_app() does NOT call it for you.
    void begin_frame();

    // -------- event feed (platform layer, tests, injection)
    void on_key(Key key, bool down);
    void on_mouse_move(Vec2 designPos);
    void on_mouse_button(MouseButton b, bool down);
    void on_mouse_wheel(float dy);
    // Raw movement while the mouse is locked (set_mouse_locked): the pointer position stays frozen, only this arrives.
    // Added to mouse_delta(); units are the device's, not design pixels.
    void on_mouse_delta(Vec2 delta);
    // Touches are a feed of their own (touches(), the "Touch" binding). The FIRST finger also drives the mouse like a
    // device does: begin moves the mouse there and presses MouseLeft, moves follow it, and when it lifts MouseLeft is
    // released at its last position. Other fingers do not touch the mouse, and a finger that lands after the first one
    // lifted becomes the new mouse finger. Every feed (the window, game.touch in tests) gets this, because it lives here.
    void on_touch_begin(std::uint64_t id, Vec2 designPos);
    void on_touch_move(std::uint64_t id, Vec2 designPos);
    void on_touch_end(std::uint64_t id);
    void on_text(std::uint32_t codepoint);
    // The player asked to paste (an edge until the next begin_frame()). A key press of V while Ctrl (or Cmd) is held asks by
    // itself; a platform where the browser decides when a paste happens (the web) turns that off with
    // set_paste_from_events(true) and calls on_paste() from its paste event instead.
    void on_paste() { pasteEdge_ = true; }
    void set_paste_from_events(bool fromEvents) { pasteFromEvents_ = fromEvents; }
    // The system Back button or gesture (Android). An edge: back_pressed() is true until the next begin_frame(). Scripts
    // get it as input.onBack; when none of their handlers consumes it, the runtime asks the game to quit (what Back did
    // before there was an event). Tests and replays call it too.
    void on_back() {
        if (InputObserver* o = tap()) o->observe_back();
        backEdge_ = true;
    }
    // Gamepads (index 0..kMaxGamepads-1; out-of-range indices are ignored). A button or axis event also marks the pad
    // connected. Disconnecting releases its buttons (with release edges) and zeroes its axes. Axis values are clamped
    // (sticks -1..1 with +Y up, triggers 0..1). The platform's poll_gamepads() feeds these; tests and replays call them.
    void on_gamepad_connected(int index, bool connected);
    void on_gamepad_button(int index, GamepadButton button, bool down);
    void on_gamepad_axis(int index, GamepadAxis axis, float value);
    // The family of pad `index` (Xbox, PlayStation...), told by the platform backend when it finds the pad (from its
    // vendor id and name, see gamepad_type_from_ids) and by tests. Survives release_all() and a disconnect, so a pad that
    // comes back keeps its type. Out-of-range indices are ignored.
    void set_gamepad_type(int index, GamepadType type);
    // Who pad `index` is (id, name, ids, type): a backend calls it BEFORE on_gamepad_connected(index, true) (and again every
    // poll, which changes nothing while it is the same), so the "gamepadConnected" event carries it. Out-of-range ignored.
    // The info survives a disconnect, like the type. An empty id becomes make_gamepad_id(0, 0, name, "slot N").
    void set_gamepad_info(int index, GamepadInfo info);
    const GamepadInfo& gamepad_info(int index) const;  // a default (empty) info for an out-of-range index
    // The slot a pad should take: the one it had the last time it was connected when that one is free, else the first
    // free one; -1 when every slot is taken. `occupied[i]` says whether the backend has a pad in slot i (fewer entries than
    // kMaxGamepads: the rest are free). Backends that choose their own slots (Apple, web, Android) ask this when a pad
    // appears; the memory is of the last 16 ids and ends with reset_options().
    int choose_gamepad_slot(std::string_view id, std::span<const bool> occupied) const;
    // The pads that were plugged in or out since the last call, oldest first (at most 64 are kept). A pad is announced once
    // per real plug: the disconnect release_all() does when the window loses the focus is not one, and the pad coming
    // back after it is not a new connection. The script host calls this once a frame.
    std::vector<GamepadEvent> take_gamepad_events();
    // Test isolation (and nothing else): bindings back to the project's, cursor visible and unlocked, on-screen keyboard
    // hidden, last device the keyboard, every pad generic, no pending Back press, no recorded vibration.
    void reset_options();
    // Focus lost or a test reset: releases everything (keys, mouse, touches, pad buttons and axes) and disconnects every
    // pad. A windowed run reconnects the pads that are really there on the next poll_gamepads().
    void release_all();

    // -------- raw queries
    bool key_down(Key k) const;
    // Which modifiers are held, as modifier:: bits (either side's key counts).
    std::uint8_t modifiers_down() const;
    // One modifier (a modifier:: bit), either side's key: held, went down this frame, went up this frame.
    bool modifier_down(std::uint8_t bit) const { return (modifiers_down() & bit) != 0; }
    bool modifier_pressed(std::uint8_t bit) const;
    bool modifier_released(std::uint8_t bit) const;
    bool key_pressed(Key k) const;   // went down this frame
    bool key_released(Key k) const;  // went up this frame
    bool mouse_down(MouseButton b) const;
    bool mouse_pressed(MouseButton b) const;
    bool mouse_released(MouseButton b) const;
    Vec2 mouse_position() const { return mouse_; }
    Vec2 mouse_delta() const { return mouseDelta_; }
    float mouse_wheel() const { return wheel_; }
    // The UI used this frame's wheel (it scrolled a ScrollList): mouse_wheel() reads 0 from now on, until the next frame.
    void consume_mouse_wheel() { wheel_ = 0.0f; }
    const std::vector<Touch>& touches() const { return touches_; }
    const std::u32string& text_input() const { return text_; }  // typed characters this frame
    std::string text_utf8() const;  // the same, as UTF-8
    bool paste_pressed() const;  // Ctrl+V / Cmd+V (or a paste event) went down this frame
    bool copy_pressed() const;   // Ctrl+C / Cmd+C went down this frame
    bool command_chord_down() const;  // Ctrl or Cmd (either side) is held
    bool back_pressed() const { return backEdge_; }  // Back arrived since the last begin_frame()

    // -------- gamepad queries (index outside 0..kMaxGamepads-1: not connected, nothing down, axes 0)
    bool gamepad_connected(int index) const;
    bool gamepad_down(int index, GamepadButton b) const;
    bool gamepad_pressed(int index, GamepadButton b) const;   // went down this frame
    bool gamepad_released(int index, GamepadButton b) const;  // went up this frame
    // The axis as the bindings see it: sticks pass a RADIAL deadzone (the pair of axes is measured together, so a
    // diagonal does not lose its other component), triggers a linear one; what is left is rescaled to the full range.
    float gamepad_axis(int index, GamepadAxis a) const;
    float gamepad_raw_axis(int index, GamepadAxis a) const;  // as the device (or a test) reported it
    // Deadzone for the sticks and triggers, 0..0.95 (default 0.2; factoria.json "input.deadzone"). Real sticks drift
    // and rest off-centre, so a game may expose it as a calibration option.
    void set_gamepad_deadzone(float deadzone);
    float gamepad_deadzone() const { return deadzone_; }
    // The family of a CONNECTED pad (Generic when it is not connected or the index is out of range).
    GamepadType gamepad_type(int index) const;

    // -------- last input (for button prompts and "press a key" screens)
    // The device that produced input last: a key going down, a mouse move/button/wheel, a pad button press or a stick
    // pushed past the deadzone, a finger. A finger counts as touch (not as the mouse it also drives). Keyboard at start.
    InputDevice last_device() const { return lastDevice_; }
    // The binding name ("Space", "MouseLeft", "Touch", "GamepadA", "GamepadLeftStickUp"...) of an input that went down
    // this frame, or "" when none did: what a "press a key to rebind" screen waits for. With modifiers held it is the chord
    // ("Ctrl+Z", "Shift+MouseLeft"). A modifier key pressed on its own is reported when it is RELEASED (by its key name,
    // "LeftShift"), so that pressing Ctrl on the way to Ctrl+Z does not end the wait; a modifier that something else was
    // pressed with is never reported alone. Pad sticks and triggers count
    // when they cross action_value 0.5 (kActionDownThreshold). If several went down in the same frame the first of this
    // order is reported: keys, touch, mouse buttons, pad buttons, pad sticks and triggers. Like every edge it is valid
    // until the next begin_frame().
    std::string last_pressed() const;

    // -------- cursor and on-screen keyboard (the REQUESTED state; the windowed runtime applies it to the window, headless
    // runs only record it so tests can check it)
    // Mouse cursor visible (default true). Hiding is independent of locking.
    bool mouse_visible() const { return mouseVisible_; }
    void set_mouse_visible(bool visible) { mouseVisible_ = visible; }
    // Mouse locked: the pointer is hidden and held in the window, and only mouse_delta() moves (on_mouse_delta). The OS
    // may unlock it on its own (window loses focus); the windowed runtime locks it again when focus comes back.
    bool mouse_locked() const { return mouseLocked_; }
    void set_mouse_locked(bool locked) { mouseLocked_ = locked; }
    // On-screen keyboard wanted (phones and tablets; desktop ignores it). Default false.
    bool keyboard_shown() const { return keyboardShown_; }
    void set_keyboard_shown(bool shown) { keyboardShown_ = shown; }
    // The platform shows its own keyboard for the focused TextField (a native plugin took it: docs/EXTENDING.md, "Native
    // plugins"), so the game's on-screen keyboard stays closed. Set by the UI; scripts read it as input.platformKeyboard.
    bool platform_keyboard() const { return platformKeyboard_; }
    void set_platform_keyboard(bool shown) { platformKeyboard_ = shown; }

    // -------- vibration (the REQUESTED pulses, in seconds, oldest first; the windowed runtime plays them on a phone and
    // clears the list, headless runs and tests keep them so they can check what the game asked for)
    void vibrate(float seconds);
    const std::vector<float>& vibrations() const { return vibrations_; }
    void clear_vibrations() { vibrations_.clear(); }

    // -------- on-screen gamepad (the TouchStick and TouchButton components; fa_ui sets the controls every frame)
    // A TouchControl is a region of the screen that takes the fingers landing in it for the TOUCH PAD: a virtual pad the
    // action bindings read like any connected pad (GamepadA, GamepadLeftStickRight...), so a game reads the same actions
    // on a phone as with a real pad. The touch pad has no number: gamepad_connected/down/axis(index) never see it and it
    // does not make last_device() a gamepad (a finger is touch). A finger a control takes stays out of touches(), the
    // "Touch" binding and the mouse until it lifts, so a game's own touch or mouse handling never sees the stick.
    struct TouchControl {
        std::uint64_t id = 0;  // stable from frame to frame (fa_ui uses the entity), so a held finger stays on its control
        Rect rect;             // design pixels, top-left origin, +Y down
        bool stick = false;    // true: a stick, false: a button
        bool rightStick = false;                  // stick: drives the right stick instead of the left one
        GamepadButton button = GamepadButton::A;  // button: the pad button it holds down
        // State, written by Input:
        bool down = false;     // a finger is on it
        Vec2 value;            // stick: the finger's offset from the centre over the radius (half the shorter side),
                               // length <= 1, +Y up; the stick axes take it raw, so the deadzone applies like on a pad
        std::uint64_t finger = 0;
    };
    // Replaces the controls; when two overlap, the LATER one takes the finger. A control that keeps its id keeps its finger
    // and state; a held control that is gone releases its button or stick (its finger is ignored until it lifts).
    void set_touch_controls(std::vector<TouchControl> controls);
    const std::vector<TouchControl>& touch_controls() const { return touchControls_; }
    // What the player uses before any input arrives: the runtime says Touch on a phone or tablet, so touch-only on-screen
    // controls are drawn from the first frame.
    void set_last_device(InputDevice device) { lastDevice_ = device; }

    // -------- actions
    // Replaces all actions from the project's "input.actions" JSON object (and remembers that object: reset_bindings).
    // Returns problems (unknown binding names, with suggestions).
    std::vector<std::string> set_actions(const Json& actions);
    // Rebinding (options menus): replaces the bindings of an EXISTING action. All-or-nothing: returns the problems
    // (unknown action, with the list of actions; unknown binding names, with "did you mean") and changes nothing if
    // there are any. An empty list unbinds the action. Bindings may repeat across actions; keeping them unique is the
    // game's choice.
    std::vector<std::string> rebind(std::string_view action, const std::vector<std::string>& bindings);
    // The bindings of an action as canonical names ("Space", "GamepadA"...), in order; empty for an unknown action.
    std::vector<std::string> bindings(std::string_view action) const;
    // Back to what the last set_actions() gave (the project's factoria.json plus the engine's default actions): one
    // action, or every action when `action` is empty. An action that set_actions() did not declare (made by bind()) loses
    // its bindings. Returns problems (unknown action).
    std::vector<std::string> reset_bindings(std::string_view action = {});
    // The label a player sees for a binding or an action ("Space", "Left Click", "Cross", "ZL"): keys by name, pad
    // buttons by the family of `pad` (an Xbox pad's A is "A", a PlayStation pad's is "Cross", a Nintendo pad's bottom
    // button is "B" because Nintendo names buttons by letter, not by position). An action gives the label of its first
    // binding for last_device(): a pad binding when the last device was a gamepad, else the first keyboard, mouse or
    // touch binding; the first binding of any kind when it has none of that. "" for an unbound action or an unknown name.
    std::string button_name(std::string_view bindingOrAction, int pad = 0) const;
    // The same label for one binding name and a pad family; "" if `binding` is not a binding name.
    static std::string binding_label(std::string_view binding, GamepadType type);
    void bind(std::string_view action, std::string_view binding);
    // Binding names, shared with factoria.json validation: true if `name` is a binding (case-insensitive), and every
    // canonical spelling (keys, mouse buttons, "Touch", gamepad buttons and half axes) for "did you mean" hints.
    static bool is_binding_name(std::string_view name);
    static std::vector<std::string> binding_names();
    // Why `name` is not a binding, as a sentence that says what is wrong and what to write instead: an unknown modifier or
    // input in a chord ("Cntrl+Z": unknown modifier, did you mean Ctrl), a malformed chord ("Ctrl+"), a modifier on a
    // gamepad binding, or, for a plain name, the usual "did you mean" with the closest binding names.
    static std::string binding_problem(std::string_view name);
    std::vector<std::string> action_names() const;
    bool has_action(std::string_view action) const;
    // An action is down when its value() reaches kActionDownThreshold. Keys, mouse buttons, touch and pad buttons
    // have value 0 or 1, so for them this is just "held"; only the analog bindings (sticks, triggers) are in between.
    static constexpr float kActionDownThreshold = 0.5f;
    bool action_down(std::string_view action) const;
    bool action_pressed(std::string_view action) const;   // became down this frame (analog too)
    // A reader handled this frame's press of `action`: from now until the next begin_frame() the press reads as gone, for
    // that action and for every other action that shares one of its bindings (Escape is "pause" and "ui_cancel": the UI
    // consumes ui_cancel when a widget handles it, so the pause handler that reads "pause" later sees nothing). Only the
    // press edge (action_pressed) is taken away; action_down and action_value keep reading the held input. Applies to
    // the global actions, not to player_action_*. An unknown action is ignored.
    void consume_action(std::string_view action);
    // Text input mode: while a TextField (or a script's on-screen keyboard, set_script_text_input) has the focus, the
    // typed keys belong to the text. An action bound to a printable key (letters, digits, Space, punctuation, alone or
    // with Shift; not Enter, Escape, arrows, F keys or a Ctrl/Alt/Super chord) reads as up for that binding: action_down,
    // action_pressed, action_released and action_value ignore it. The UI sets the first flag from the focus each frame;
    // a script sets the second one.
    void set_ui_text_input(bool on) { uiTextInput_ = on; }
    void set_script_text_input(bool on) { scriptTextInput_ = on; }
    bool text_input_mode() const { return uiTextInput_ || scriptTextInput_; }
    bool action_released(std::string_view action) const;
    // 0..1: the maximum over the action's bindings. Keys, mouse, touch and pad buttons give 0 or 1; a half-axis binding
    // such as GamepadLeftStickRight gives the stick's push in that direction after the deadzone (0 at rest, 1 at full
    // tilt); a trigger gives its pull after the deadzone. A binding matches ANY connected pad. An override gives 1.
    float action_value(std::string_view action) const;
    // -1..1 from two actions: action_value(positive) - action_value(negative). Keys give exactly -1, 0 or 1.
    float axis(std::string_view negative, std::string_view positive) const;
    // 2D vector from four actions (left, right, down, up); +Y up. Normalized only when its length exceeds 1, so a
    // half-tilted stick gives a short vector and two held keys a unit diagonal.
    Vec2 vector(std::string_view left, std::string_view right, std::string_view down, std::string_view up) const;

    // -------- players (local multiplayer: one device each; the actions above keep answering to every device)
    // A player reads the project's actions (the same names) through its own device: gamepad bindings only on its pad, key
    // bindings only on the keys of its scheme. Mouse and touch bindings belong to the one shared pointer, so players do not
    // read them (the global actions do). A player with no device reads nothing. An out-of-range player reads nothing and
    // ignores changes; the functions that report problems return them as text (empty = fine).
    //
    // Key schemes: "all" (every key), "left" and "right" (the two halves of the keyboard; key_scheme_keys lists them) are
    // built in; the project adds its own in factoria.json "input.schemes". A scheme is a set of keys and may give the keys of
    // some actions of its own; for the other actions a player's default key bindings are the project's key bindings that
    // belong to the scheme.
    // set_key_schemes() takes "input.schemes", e.g. { "arrows": { "extends": "right", "keys": ["Enter"], "actions":
    // { "jump": ["Enter"] } } }: `extends` (a built-in scheme) and `keys` add to the set, the keys of `actions` too, and a bare
    // array is {"keys": [...]}. It replaces the project's schemes; call it AFTER set_actions (the actions a scheme names must
    // exist). Returns problems with "did you mean".
    std::vector<std::string> set_key_schemes(const Json& schemes);
    std::vector<std::string> key_scheme_names() const;                      // built-in ones first, then the project's, sorted
    std::vector<std::string> key_scheme_keys(std::string_view name) const;  // canonical key names in Key order; empty if unknown
    // Gives a player its device. The pad is a slot (pad >= 0) or the stable id of a pad (padId: the player follows that pad
    // when it comes back in another slot, and reads nothing while it is unplugged); `keys` names a scheme. An empty field is
    // "none". Returns problems (slot out of range, unknown scheme with "did you mean", pad and padId together) and changes
    // nothing when there are any. What the player rebound stays with the player, not with the device.
    std::vector<std::string> use_player_device(int player, const PlayerDevice& device);
    const PlayerDevice& player_device(int player) const;  // an empty device for an out-of-range player
    int player_pad(int player) const;                     // the slot it reads now; -1: none, or its padId pad is unplugged
    // The actions every player has: the project's (action_names() without the ones bind() added). For any other name every
    // read below gives false / 0.
    bool has_player_action(std::string_view action) const;
    float player_action_value(int player, std::string_view action) const;  // like action_value, from the player's device only
    bool player_action_down(int player, std::string_view action) const;
    bool player_action_pressed(int player, std::string_view action) const;
    bool player_action_released(int player, std::string_view action) const;
    float player_axis(int player, std::string_view negative, std::string_view positive) const;
    Vec2 player_vector(int player, std::string_view left, std::string_view right, std::string_view down,
                       std::string_view up) const;
    // The bindings of a player's action are two lists, "keys" and "pad". `family` "keys" or "pad" gives that list (what the
    // player would use on such a device, also when it has none now), "" gives the lists of the devices it has now, keys
    // first. The defaults come from the project (see above); what the player rebound replaces them. Keys outside the
    // player's scheme are not listed (they do not count either).
    std::vector<std::string> player_bindings(int player, std::string_view action, std::string_view family = {}) const;
    // Replaces one family's list of an action for this player. `family` is "keys" or "pad", or "" to take it from the
    // names (they must all be of one family; an empty list with no family unbinds both). All or nothing: problems for an
    // unknown action or binding (with "did you mean"), a mouse or touch binding, a key outside the player's scheme (outside
    // "all" while the player has no keys device), a name of the other family than `family`.
    std::vector<std::string> player_rebind(int player, std::string_view action, const std::vector<std::string>& bindings,
                                           std::string_view family = {});
    // Back to the defaults: one action, or every action when `action` is empty.
    std::vector<std::string> player_reset(int player, std::string_view action = {});
    // Like last_pressed() but only on the player's own device: the keys of its scheme, its pad's buttons and sticks.
    std::string player_last_pressed(int player) const;
    // What the player rebound, for a game to save: { "keys": { "jump": ["Space"] }, "pad": { "jump": ["GamepadB"] } }, only
    // the actions that differ from the defaults ({} when nothing). player_import replaces the rebinds with such an object (the
    // device is not part of it); an entry that is no longer valid (an action the project dropped, a bad name) is skipped and
    // reported, the rest applies.
    Json player_export(int player) const;
    std::vector<std::string> player_import(int player, const Json& data);

    // Virtual action state (tests/AI): down=true forces the action down (in
    // addition to real bindings) until set back to false, which releases it
    // (the real bindings apply again). Produces pressed/released edges; a
    // press+release between two begin_frame() calls still yields both edges.
    void set_action_override(std::string_view action, bool down);
    void clear_action_overrides();

    // Debug snapshot: keys down, mouse, touches, actions down.
    Json snapshot() const;

    // One observer at a time (nullptr = none): the runtime's recorder. Not owned.
    void set_observer(InputObserver* observer) { observer_ = observer; }

private:
    InputObserver* tap() const { return observerDepth_ == 0 ? observer_ : nullptr; }
    struct ObserverMute {  // events fed by another event (a touch's mouse) are not reported on their own
        explicit ObserverMute(Input& in) : in_(in) { ++in_.observerDepth_; }
        ~ObserverMute() { --in_.observerDepth_; }
        Input& in_;
    };
    InputObserver* observer_ = nullptr;
    int observerDepth_ = 0;
    struct Binding {
        // Mod: a modifier by itself ("Shift": either Shift key); `modBit` says which one.
        enum class Kind : std::uint8_t { Key, Mouse, Touch, PadButton, PadAxis, Mod } kind = Kind::Key;
        std::uint8_t mods = 0;    // modifier:: bits that must be held too (a chord); 0 for a plain binding
        std::uint8_t modBit = 0;  // Kind::Mod: the modifier
        Key key = Key::Unknown;
        MouseButton mouse = MouseButton::Left;
        GamepadButton button = GamepadButton::A;
        GamepadAxis axis = GamepadAxis::LeftX;  // PadAxis: the axis and the direction (+1/-1) that counts
        int sign = 1;
    };
    struct Pad {
        bool connected = false;
        GamepadType type = GamepadType::Generic;
        GamepadInfo info;
        bool announced = false;  // a "connected" event went out and no "disconnected" one since
        std::array<bool, size_t(GamepadButton::Count)> buttons{}, prevButtons{}, pressedEdge{}, releasedEdge{};
        std::array<float, size_t(GamepadAxis::Count)> axes{}, prevAxes{};
    };
    static bool parse_binding(std::string_view name, Binding& out);
    static bool parse_single_binding(std::string_view name, Binding& out);  // no modifiers
    void mark_modifiers_used();
    // Which devices a read looks at: the global actions see everything, a player its own pad and key scheme.
    using KeySet = std::array<bool, size_t(Key::Count)>;
    struct View {
        bool anyPad = false;             // every pad, the touch pad included
        int pad = -1;                    // else this slot (-1: no pad)
        bool pointer = false;            // mouse buttons and touch
        bool keyboard = false;           // keys
        const KeySet* keySet = nullptr;  // keyboard: only these keys (nullptr: all of them)
        int player = -1;                 // the player this view belongs to (-1: the global actions)
    };
    std::uint8_t mods_held(bool previous, const View& view) const;  // modifier:: bits down, through the view's keys
    // The binding as the keys and buttons say, chord modifiers included, ignoring whether a longer chord shadows it.
    float binding_raw(const Binding& b, bool previous, const View& view) const;
    // A chord bound by another action (or this one) with MORE modifiers than `b`, on the same input, and held: `b` is silent.
    bool shadowed(const Binding& b, bool previous, const View& view) const;
    // The edge of one binding's main input (a key, a mouse button, touch or a modifier), not looking at its modifiers.
    bool main_edge(const Binding& b, const View& view, bool released) const;
    std::string chord_prefix(const View& view) const;
    std::string lone_modifier_release(const View& view) const;
    static bool same_input(const Binding& a, const Binding& b);
    static bool is_key_family(const Binding& b) { return b.kind == Binding::Kind::Key || b.kind == Binding::Kind::Mod; }
    static bool in_key_set(const Binding& b, const KeySet& set);  // the keys (and modifiers' keys) of `b` are all in `set`
    float binding_value_in(const Binding& b, bool previous, const View& view) const;
    bool was_down_in(const std::vector<Binding>& list, const View& view) const;             // down as of the last begin_frame()
    bool edge_in(const std::vector<Binding>& list, const View& view, bool released) const;  // went down (or up) this frame
    float binding_value(const Binding& b, bool previous) const;  // previous: as of the last begin_frame()
    float pad_axis(const Pad& pad, GamepadAxis a, bool previous) const;
    void release_pad(int index);     // connected = false, buttons released, axes zeroed; no event
    void mark_connected(int index);  // connected = true; announces the pad when it was not
    // The bindings listed for one action in `actions` (a JSON array or string), appending problems; `candidates` are the
    // names for "did you mean".
    using ActionTable = std::unordered_map<std::string, std::vector<Binding>>;
    struct KeyScheme {
        KeySet keys{};
        ActionTable actions;  // the scheme's own bindings for some actions
        bool builtin = false;
    };
    struct PlayerState {
        PlayerDevice device;
        ActionTable keysOverride, padOverride;  // what the player rebound, per family
    };
    enum class Family : std::uint8_t { Keys, Pad };
    static bool parse_family(std::string_view name, Family& out);
    void rebuild_player_defaults();  // padDefaults_ and keyDefaults_ from the project's actions and the schemes
    View player_view(int player) const;
    // The list that applies to one family of a player's action: the rebind, else the default (nullptr: no such action).
    const std::vector<Binding>* player_list(int player, Family family, const std::string& action) const;
    std::vector<Binding> parse_binding_list(const std::string& action, const Json& list,
                                            const std::vector<std::string>& candidates,
                                            std::vector<std::string>& problems) const;
    static std::string binding_name(const Binding& b);  // canonical spelling, the inverse of parse_binding
    TouchControl* touch_control_of(std::uint64_t finger);  // the control holding `finger`, nullptr when none
    void update_touch_pad();                               // the touch pad's buttons and axes from the held controls

    std::array<bool, size_t(Key::Count)> keys_{};
    std::array<bool, size_t(Key::Count)> prevKeys_{};
    std::array<bool, size_t(Key::Count)> keyPressedEdge_{};   // went down at least once since begin_frame
    std::array<bool, size_t(Key::Count)> keyReleasedEdge_{};  // went up at least once since begin_frame
    std::array<bool, size_t(Key::Count)> modKeyUsed_{};  // a held modifier key that something else was pressed with
    std::array<bool, size_t(MouseButton::Count)> mouse_buttons_{};
    std::array<bool, size_t(MouseButton::Count)> prevMouse_{};
    std::array<bool, size_t(MouseButton::Count)> mousePressedEdge_{};
    std::array<bool, size_t(MouseButton::Count)> mouseReleasedEdge_{};
    Vec2 mouse_{}, mouseDelta_{};
    float wheel_ = 0.0f;
    bool uiTextInput_ = false, scriptTextInput_ = false;
    std::vector<std::string> consumedActions_;  // consume_action() of this frame
    std::vector<Binding> consumedBindings_;     // their pressed bindings: another action on the same input is consumed too
    bool binding_consumed(const Binding& b) const;
    bool binding_typed(const Binding& b) const;  // a printable key that text input mode takes
    // The bindings of a list that can be read now: not the typed ones and, for a press, not the consumed ones.
    std::vector<Binding> readable(const std::vector<Binding>& list, bool forPress) const;
    std::vector<Touch> touches_;
    bool touchDown_ = false, prevTouchDown_ = false;
    bool touchPressedEdge_ = false, touchReleasedEdge_ = false;
    bool primaryTouchDown_ = false;  // the first finger is down and mirrored onto the mouse
    std::uint64_t primaryTouchId_ = 0;
    std::u32string text_;
    // The numbered pads, then the touch pad (pads_[kMaxGamepads]): the bindings loop over all of them, the numbered
    // queries stop before it.
    std::array<Pad, kMaxGamepads + 1> pads_;
    std::vector<GamepadEvent> padEvents_;
    std::vector<std::pair<std::string, int>> padSlotMemory_;  // id -> the slot it last held, newest last
    std::vector<TouchControl> touchControls_;
    float deadzone_ = 0.2f;
    InputDevice lastDevice_ = InputDevice::Keyboard;
    bool mouseVisible_ = true, mouseLocked_ = false, keyboardShown_ = false, platformKeyboard_ = false;
    bool backEdge_ = false;
    bool pasteEdge_ = false;
    bool pasteFromEvents_ = false;  // paste comes from on_paste() only, not from the V key
    std::vector<float> vibrations_;
    Json projectActions_;  // what the last set_actions() was given (reset_bindings)
    std::map<std::string, KeyScheme> schemes_;        // the built-in schemes and the project's
    ActionTable padDefaults_;                         // per action: the project's pad bindings
    std::map<std::string, ActionTable> keyDefaults_;  // per scheme, per action: the default key bindings
    std::array<PlayerState, kMaxPlayers> players_;
    std::unordered_map<std::string, std::vector<Binding>> actions_;
    // Action overrides: only `true` entries are stored (setting false erases and
    // hands control back to the bindings).
    std::unordered_map<std::string, bool> overrides_, prevOverrides_;
    std::unordered_map<std::string, bool> overridePressedEdge_, overrideReleasedEdge_;
};

}  // namespace fa
