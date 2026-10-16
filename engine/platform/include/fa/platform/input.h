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
// Unknown names are rejected by set_actions with a "did you mean" hint.
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

// The kind of device that produced input last (Input::last_device()), for showing the matching button prompts.
enum class InputDevice : std::uint8_t { Keyboard, Mouse, Gamepad, Touch };
const char* input_device_name(InputDevice d);  // "keyboard", "mouse", "gamepad", "touch"

struct Touch {
    std::uint64_t id = 0;
    Vec2 position;  // design-resolution pixels
    bool pressedThisFrame = false;
};

class Input {
public:
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
    // Test isolation (and nothing else): bindings back to the project's, cursor visible and unlocked, on-screen keyboard
    // hidden, last device the keyboard, every pad generic.
    void reset_options();
    // Focus lost or a test reset: releases everything (keys, mouse, touches, pad buttons and axes) and disconnects every
    // pad. A windowed run reconnects the pads that are really there on the next poll_gamepads().
    void release_all();

    // -------- raw queries
    bool key_down(Key k) const;
    bool key_pressed(Key k) const;   // went down this frame
    bool key_released(Key k) const;  // went up this frame
    bool mouse_down(MouseButton b) const;
    bool mouse_pressed(MouseButton b) const;
    bool mouse_released(MouseButton b) const;
    Vec2 mouse_position() const { return mouse_; }
    Vec2 mouse_delta() const { return mouseDelta_; }
    float mouse_wheel() const { return wheel_; }
    const std::vector<Touch>& touches() const { return touches_; }
    const std::u32string& text_input() const { return text_; }  // typed characters this frame
    std::string text_utf8() const;  // the same, as UTF-8

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
    // this frame, or "" when none did: what a "press a key to rebind" screen waits for. Pad sticks and triggers count
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
    std::vector<std::string> action_names() const;
    bool has_action(std::string_view action) const;
    // An action is down when its value() reaches kActionDownThreshold. Keys, mouse buttons, touch and pad buttons
    // have value 0 or 1, so for them this is just "held"; only the analog bindings (sticks, triggers) are in between.
    static constexpr float kActionDownThreshold = 0.5f;
    bool action_down(std::string_view action) const;
    bool action_pressed(std::string_view action) const;   // became down this frame (analog too)
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

    // Virtual action state (tests/AI): down=true forces the action down (in
    // addition to real bindings) until set back to false, which releases it
    // (the real bindings apply again). Produces pressed/released edges; a
    // press+release between two begin_frame() calls still yields both edges.
    void set_action_override(std::string_view action, bool down);
    void clear_action_overrides();

    // Debug snapshot: keys down, mouse, touches, actions down.
    Json snapshot() const;

private:
    struct Binding {
        enum class Kind : std::uint8_t { Key, Mouse, Touch, PadButton, PadAxis } kind = Kind::Key;
        Key key = Key::Unknown;
        MouseButton mouse = MouseButton::Left;
        GamepadButton button = GamepadButton::A;
        GamepadAxis axis = GamepadAxis::LeftX;  // PadAxis: the axis and the direction (+1/-1) that counts
        int sign = 1;
    };
    struct Pad {
        bool connected = false;
        GamepadType type = GamepadType::Generic;
        std::array<bool, size_t(GamepadButton::Count)> buttons{}, prevButtons{}, pressedEdge{}, releasedEdge{};
        std::array<float, size_t(GamepadAxis::Count)> axes{}, prevAxes{};
    };
    static bool parse_binding(std::string_view name, Binding& out);
    float binding_value(const Binding& b, bool previous) const;  // previous: as of the last begin_frame()
    float pad_axis(const Pad& pad, GamepadAxis a, bool previous) const;
    // The bindings listed for one action in `actions` (a JSON array or string), appending problems; `candidates` are the
    // names for "did you mean".
    std::vector<Binding> parse_binding_list(const std::string& action, const Json& list,
                                            const std::vector<std::string>& candidates,
                                            std::vector<std::string>& problems) const;
    static std::string binding_name(const Binding& b);  // canonical spelling, the inverse of parse_binding

    std::array<bool, size_t(Key::Count)> keys_{};
    std::array<bool, size_t(Key::Count)> prevKeys_{};
    std::array<bool, size_t(Key::Count)> keyPressedEdge_{};   // went down at least once since begin_frame
    std::array<bool, size_t(Key::Count)> keyReleasedEdge_{};  // went up at least once since begin_frame
    std::array<bool, size_t(MouseButton::Count)> mouse_buttons_{};
    std::array<bool, size_t(MouseButton::Count)> prevMouse_{};
    std::array<bool, size_t(MouseButton::Count)> mousePressedEdge_{};
    std::array<bool, size_t(MouseButton::Count)> mouseReleasedEdge_{};
    Vec2 mouse_{}, mouseDelta_{};
    float wheel_ = 0.0f;
    std::vector<Touch> touches_;
    bool touchDown_ = false, prevTouchDown_ = false;
    bool touchPressedEdge_ = false, touchReleasedEdge_ = false;
    bool primaryTouchDown_ = false;  // the first finger is down and mirrored onto the mouse
    std::uint64_t primaryTouchId_ = 0;
    std::u32string text_;
    std::array<Pad, kMaxGamepads> pads_;
    float deadzone_ = 0.2f;
    InputDevice lastDevice_ = InputDevice::Keyboard;
    bool mouseVisible_ = true, mouseLocked_ = false, keyboardShown_ = false;
    Json projectActions_;  // what the last set_actions() was given (reset_bindings)
    std::unordered_map<std::string, std::vector<Binding>> actions_;
    // Action overrides: only `true` entries are stored (setting false erases and
    // hands control back to the bindings).
    std::unordered_map<std::string, bool> overrides_, prevOverrides_;
    std::unordered_map<std::string, bool> overridePressedEdge_, overrideReleasedEdge_;
};

}  // namespace fa
