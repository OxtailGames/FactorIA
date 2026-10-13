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
// "MouseLeft", "MouseRight", "MouseMiddle", "Touch" (any finger down),
// "GamepadA/B/X/Y", "GamepadStart", "GamepadDpadLeft"... (reserved; gamepad
// support is on the roadmap).
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
    void on_touch_begin(std::uint64_t id, Vec2 designPos);
    void on_touch_move(std::uint64_t id, Vec2 designPos);
    void on_touch_end(std::uint64_t id);
    void on_text(std::uint32_t codepoint);
    void release_all();  // focus lost

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

    // -------- actions
    // Replaces all actions from the project's "input.actions" JSON object.
    // Returns problems (unknown binding names, with suggestions).
    std::vector<std::string> set_actions(const Json& actions);
    void bind(std::string_view action, std::string_view binding);
    std::vector<std::string> action_names() const;
    bool has_action(std::string_view action) const;
    bool action_down(std::string_view action) const;
    bool action_pressed(std::string_view action) const;
    bool action_released(std::string_view action) const;
    // -1..1 from two actions: axis("move_left", "move_right").
    float axis(std::string_view negative, std::string_view positive) const;
    // Normalized 2D vector from four actions (left, right, down, up); +Y up.
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
        enum class Kind : std::uint8_t { Key, Mouse, Touch, Gamepad } kind = Kind::Key;
        Key key = Key::Unknown;
        MouseButton mouse = MouseButton::Left;
    };
    bool binding_down(const Binding& b) const;
    bool binding_was_down(const Binding& b) const;

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
    std::u32string text_;
    std::unordered_map<std::string, std::vector<Binding>> actions_;
    // Action overrides: only `true` entries are stored (setting false erases and
    // hands control back to the bindings).
    std::unordered_map<std::string, bool> overrides_, prevOverrides_;
    std::unordered_map<std::string, bool> overridePressedEdge_, overrideReleasedEdge_;
};

}  // namespace fa
