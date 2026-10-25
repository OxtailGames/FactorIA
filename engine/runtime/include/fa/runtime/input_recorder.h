// Records the input a game receives, in the input replay format (`factoria run --headless --input`, game.input):
//   {"frames": {"<n>": {"keys": {"Space": true}, "mouse": {"position": [x, y], "left": true},
//                       "gamepad": [{"index": 0, "buttons": {"A": true}, "axes": {"LeftX": 0.5}}],
//                       "touch": [{"id": 1, "position": [x, y], "down": true}], "back": true, "clipboard": "text"}},
//    "timing": [[dt, steps], ...], "date": "2026-10-23"}
// Frame numbers are relative to the start of the recording; an entry is applied BEFORE that frame runs, which is what the
// events received between two frames mean. Each frame's dt and fixed-step count go to "timing", so the replay runs the same
// frames (exact even when the window ran slower or faster than the fixed rate).
//
// The Engine owns one (Engine::start_input_recording / stop_input_recording, the `input.record` command) and installs it as
// the Input observer: every key, mouse, touch, gamepad and Back event the game receives, from a window, a test, a script
// (game.input) or a replay, lands here. Nothing is recorded while it is stopped. No ImGui, no Engine: tests feed it directly.
// Not recorded (the replay format has no field for them): mouse wheel, locked-mouse movement, typed text. Clipboard reads are.
#pragma once

#include <array>
#include <bitset>
#include <cstdint>
#include <set>
#include <string>

#include "fa/core/json.h"
#include "fa/core/math.h"
#include "fa/platform/input.h"

namespace fa {

class InputRecorder final : public InputObserver {
public:
    // Frames of the observer events and of clipboard_read() come from `*counter` (the engine's frame index).
    void set_frame_source(const std::uint64_t* counter) { source_ = counter; }
    // Starts (or restarts) recording at `startFrame`: everything recorded before is dropped.
    void start(std::uint64_t startFrame);
    // Stops listening; input() keeps what was recorded until the next start().
    void stop() { active_ = false; }
    bool recording() const { return active_; }
    std::uint64_t start_frame() const { return start_; }
    // Frames recorded so far (the length of "timing").
    std::size_t frame_count() const { return timing_.size(); }

    // -------- explicit-frame API (what the observer callbacks call)
    void key(std::uint64_t frame, Key k, bool down);
    void mouse_position(std::uint64_t frame, Vec2 p);
    void mouse_button(std::uint64_t frame, MouseButton b, bool down);
    // One gamepad event, in order with the others of its frame. Repeats of a state the pad already has are dropped (a
    // platform poll feeds the same axis values every frame).
    void gamepad_connected(std::uint64_t frame, int index, bool connected);
    void gamepad_button(std::uint64_t frame, int index, GamepadButton b, bool down);
    void gamepad_axis(std::uint64_t frame, int index, GamepadAxis a, float value);
    void touch_begin(std::uint64_t frame, std::uint64_t id, Vec2 p);
    void touch_move(std::uint64_t frame, std::uint64_t id, Vec2 p);
    void touch_end(std::uint64_t frame, std::uint64_t id);
    void back(std::uint64_t frame);
    // What a clipboard read returned during `frame` ("clipboard" of the replay entry): the replay puts that text on the
    // clipboard before the frame, so a paste plays back the same. The first read of a frame wins (a later one may be a
    // text the game wrote).
    void clipboard(std::uint64_t frame, const std::string& text);
    // Everything held is let go (focus lost, Pause, Input::release_all): keys, mouse buttons, fingers, pads.
    void release_all(std::uint64_t frame);
    // After the engine ran up to frame `frameEnd` (exclusive): the last frame took `dt` and ran `steps` fixed steps.
    // Frames before it that were not reported were engine.step(1) calls (Step button, game.step): [fixedDt, 1].
    void timing(std::uint64_t frameEnd, double dt, int steps, double fixedDt);
    // The calendar date the recording plays on (game.today()): "date", "time" and "utcOffsetMinutes" of the replay, so the
    // replay sees the same day (a daily seed, a calendar event). Not set = the file has neither.
    void set_date(const std::string& iso, int utcOffsetMinutes, const std::string& time = "");
    // The replay recorded so far.
    Json input() const;

    // -------- InputObserver (active only while recording)
    void observe_key(Key k, bool down) override;
    void observe_mouse_move(Vec2 p) override;
    void observe_mouse_button(MouseButton b, bool down) override;
    void observe_touch_begin(std::uint64_t id, Vec2 p) override;
    void observe_touch_move(std::uint64_t id, Vec2 p) override;
    void observe_touch_end(std::uint64_t id) override;
    void observe_gamepad_connected(int index, bool connected) override;
    void observe_gamepad_button(int index, GamepadButton b, bool down) override;
    void observe_gamepad_axis(int index, GamepadAxis a, float value) override;
    void observe_back() override;
    void observe_release_all() override;
    // A clipboard read of the running game, in the current frame.
    void clipboard_read(const std::string& text);

private:
    struct Pad {
        bool connected = false;
        std::bitset<std::size_t(GamepadButton::Count)> buttons;
        std::array<float, std::size_t(GamepadAxis::Count)> axes{};
    };
    Json& entry(std::uint64_t frame);
    std::uint64_t now() const { return source_ ? *source_ : start_; }
    static const char* button_name(MouseButton b);
    void pad_event(std::uint64_t frame, int index, const char* group, const char* name, Json value);

    const std::uint64_t* source_ = nullptr;
    bool active_ = false;
    std::string date_, time_;
    int utcOffsetMinutes_ = 0;
    std::uint64_t start_ = 0;
    Json frames_ = Json::object();
    Json timing_ = Json::array();
    std::set<Key> keys_;
    std::set<MouseButton> buttons_;
    std::set<std::uint64_t> fingers_;
    std::array<Pad, kMaxGamepads> pads_;
};

}  // namespace fa
